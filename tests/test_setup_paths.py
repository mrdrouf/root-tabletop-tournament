#!/usr/bin/env python3
"""Regression tests for the two setup paths.

The mod has two ways to start a game -- the ranked draft (rttSetup) and the manual
4/5-board picker (setupFactionBoards) -- and historically they drifted apart: the
teardown tag list, the run-state reset, the busy release, the hand-1 ordering and
the turn system were each fixed in one path and forgotten in the other. These tests
drive BOTH paths against a stubbed TTS and assert they agree.

    python3 tests/test_setup_paths.py            # the built dist/
    python3 tests/test_setup_paths.py --old      # the build in git main, to see the bugs

Needs lupa (pip install lupa). The stub is tests/tts_stub.lua.
"""
import json, os, subprocess, sys
import lupa

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
BOARD = "bab7e1"                       # the setup board carries the whole script


def board_lua(raw):
    d = json.loads(raw)
    def walk(objs):
        for o in objs:
            yield o
            for c in (o.get("ContainedObjects") or []): yield from walk([c])
    return [o for o in walk(d["ObjectStates"]) if o.get("GUID") == BOARD][0]["LuaScript"]


def fresh(src):
    rt = lupa.LuaRuntime(unpack_returned_tuples=True)
    rt.execute(open(os.path.join(HERE, "tts_stub.lua"), encoding="utf-8").read())
    rt.execute(src.replace("!=", "~="))            # TTS accepts != ; Lua 5.5 does not
    rt.execute("if onLoad then pcall(function() onLoad('') end) end FLUSH(6)")
    return rt


# ----------------------------------------------------------------- the cases --
def t_manual_turn_order(src):
    """The manual path must configure the TTS turn system in seat order.

    It no longer switches it ON by itself. Setting boards out is not the start of a game -- the
    maintainer, 2026-09-05: "the turn order should get started only when a player is seated, now it
    also starts when I select 4 player setup". The order is written at setup, and the first player to
    sit down starts it with that order already in place.
    """
    for arg, n, want in (("nil", 4, ["Red", "Yellow", "Orange", "Teal"]),
                         ("'fivePlayerSetup'", 5, ["Red", "Yellow", "Orange", "Teal", "Green"])):
        rt = fresh(src)
        rt.execute("pcall(function() setupFactionBoards(nil,nil,%s) end) FLUSH(10)" % arg)
        order = list((rt.eval("Turns.order") or {}).values())
        assert order == want, "%d seats: order %s, wanted %s" % (n, order, want)
        assert rt.eval("Turns.enable") is False, "%d seats: turns started with nobody seated" % n
        assert rt.eval("Turns.skip_empty_hands") is False, "%d seats: would skip empty seats" % n

        rt.execute("SEAT('Red') onPlayerChangeColor('Red')")
        assert rt.eval("Turns.enable") is True, "%d seats: sitting down did not start turns" % n
        assert list(rt.eval("Turns.order").values()) == want, "%d seats: order lost on seating" % n
        assert rt.eval("Turns.turn_color") == "Red", "%d seats: seat 1 does not start" % n


def t_boards_spawn(src):
    """Four and five boards, at the seat coordinates."""
    for arg, n in (("nil", 4), ("'fivePlayerSetup'", 5)):
        rt = fresh(src)
        rt.execute("REC.spawned={} pcall(function() setupFactionBoards(nil,nil,%s) end) FLUSH(10)" % arg)
        got = [rt.eval("REC.spawned")[i] for i in range(1, len(rt.eval("REC.spawned")) + 1)]
        assert len(got) == n, "%d seats: spawned %d boards (%s)" % (n, len(got), got)


def t_new_game_resets_state(src):
    """A new game must clear everything the previous one accumulated."""
    rt = fresh(src)
    rt.execute("SEAT('Red','MrDrouf') math.randomseed(3)")
    rt.execute("pcall(function() rttSetup(nil,nil,'rttRankedBtn') end) FLUSH(20)")
    rt.execute("""RTT_VP_PLACED = 9
                  RTT_FAC_TAKEN['Marquise de Cat'] = true
                  RTT_TRACK = 'stale'
                  RTT_CAP_SPAWNED = RTT_CAP_SPAWNED or {}
                  RTT_CAP_SPAWNED['Ronin'] = true
                  Global.setVar('RTT_SEAT_COLOR', '{"Marquise de Cat":"Pink"}')""")
    before = rt.eval("RTT_RUN_ID")
    rt.execute("pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(10)")
    assert rt.eval("RTT_RUN_ID") > before,                  "RTT_RUN_ID not bumped (stale callbacks survive)"
    assert rt.eval("RTT_VP_PLACED") == 0,                   "RTT_VP_PLACED survived the new game"
    assert not rt.eval("RTT_FAC_TAKEN['Marquise de Cat']"), "taken-factions survived the new game"
    assert rt.eval("RTT_TRACK") is None,                    "cached score track survived the new game"
    assert not rt.eval("(RTT_CAP_SPAWNED or {})['Ronin']"), "RTT_CAP_SPAWNED survived: a captain seen in one game stays 'spawned' in the next"
    assert rt.eval("GVGET('RTT_SEAT_COLOR')") == "{}",      "RTT_SEAT_COLOR survived the new game"


def t_ranked_objects_cleared_by_manual(src):
    """Starting a manual game after a ranked draft must not leave the draft cards out."""
    rt = fresh(src)
    rt.execute("SEAT('Red','MrDrouf') math.randomseed(11)")
    rt.execute("pcall(function() rttSetup(nil,nil,'rttRankedBtn') end) FLUSH(24)")
    n = rt.eval("#RTT_SPAWNED")
    assert n > 0, "the ranked draft tracked no objects -- test is not exercising anything"
    rt.execute("LEAKED={} for _,g in ipairs(RTT_SPAWNED) do LEAKED[#LEAKED+1]=g end")
    rt.execute("pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(12)")
    alive = rt.eval("(function() local k=0 for _,g in ipairs(LEAKED) do if getObjectFromGUID(g) then k=k+1 end end return k end)()")
    assert alive == 0, "%d/%d ranked-draft objects still on the table after a manual setup" % (alive, n)


def t_supporters_take_the_seat_explicitly(src):
    """The supporters zone must follow the seat it is GIVEN, not whatever hand 1 currently is."""
    rt = fresh(src)
    rt.execute("SEAT('Red','MrDrouf')")
    assert rt.eval("RTT_SUPPORTERS_EXPLICIT == true"), "spawnSupportersHand does not take an explicit seat"
    # hand 1 parked far away: only the explicit argument may influence the result
    rt.execute("Player['Red'].setHandTransform({position={-999,10.62,-999},rotation={0,77,0},scale={16,6,4}},1)")
    rt.execute("pcall(function() spawnSupportersHand('Red', {position={52,10.62,-46},rotation={0,0,0}}) end) FLUSH(4)")
    got = rt.eval("HANDOF('Red',2)")
    # the same seat, read from hand 1 the old way, must land in the same place
    rt.execute("Player['Red'].setHandTransform({position={52,10.62,-46},rotation={0,0,0},scale={16,6,4}},1)")
    rt.execute("pcall(function() spawnSupportersHand('Red') end) FLUSH(4)")
    ref = rt.eval("HANDOF('Red',2)")
    assert abs(got["x"] - ref["x"]) < 1e-6 and abs(got["z"] - ref["z"]) < 1e-6, \
        "explicit seat gave %.3f,%.3f but the seat is at %.3f,%.3f" % (got["x"], got["z"], ref["x"], ref["z"])


def t_seat_hand_array_shape(src):
    """RTT_SEAT_HAND stores rot as a plain array; the named shape must agree with it."""
    rt = fresh(src)
    rt.execute("pcall(function() spawnSupportersHand('Red', {position={-52,10.62,64}, rotation={0,180,0}}) end)")
    arr = rt.eval("HANDOF('Red',2)")
    rt.execute("pcall(function() spawnSupportersHand('Red', {position={x=-52,y=10.62,z=64}, rotation={x=0,y=180,z=0}}) end)")
    named = rt.eval("HANDOF('Red',2)")
    assert abs(arr["x"] - named["x"]) < 1e-6 and abs(arr["z"] - named["z"]) < 1e-6, \
        "array rot %.3f,%.3f != named rot %.3f,%.3f" % (arr["x"], arr["z"], named["x"], named["z"])


DECK_LUA = """SHARED = MKDECK((function() local t={}
    for i=1,40 do t[#t+1]={desc='fox',nick='Ambush'} end
    for i=1,%d do t[#t+1]={desc='Frog',nick='Militias'} end
    return t end)())"""

def _frogs(rt):
    return rt.eval("(function() local n=0 for _,c in ipairs(SHARED.__cards) do "
                   "if c.description=='Frog' then n=n+1 end end return n end)()")


def t_main_deck_survives_frogs(src):
    """The shared deck must still be found after the frogs have been merged into it."""
    # one fresh table per case: decks are found by scanning everything on it, so leaving an
    # earlier fixture lying around would just return that one
    rt = fresh(src)
    rt.execute(DECK_LUA % 0)
    assert rt.eval("rttFindMainDeck() == SHARED"), "shared deck not found even with no frog cards"

    rt = fresh(src)
    rt.execute(DECK_LUA % 14)
    assert rt.eval("rttFindMainDeck() == SHARED"), \
        "a deck CONTAINING frog cards is the shared deck after the merge, but was rejected"

    # a deck that is ENTIRELY frog cards is the frogs' own and must never be mistaken for the shared one
    rt = fresh(src)
    rt.execute("ONLYFROG = MKDECK((function() local t={} for i=1,30 do t[i]={desc='Frog'} end return t end)())")
    assert rt.eval("rttFindMainDeck()") is None, "an all-frog deck was taken for the shared deck"


def t_supporters_draw_with_frogs_in_deck(src):
    """The Alliance must still draw its three supporters when the frogs are in play."""
    for n_frog in (0, 14):
        rt = fresh(src)
        rt.execute("SEAT('Red','MrDrouf')")
        rt.execute(DECK_LUA % n_frog)
        rt.execute("""RTT_ALLY_SUP_DONE = {}
                      BEFORE = {x=-75, z=-75}
                      Player['Red'].setHandTransform({position={40,12.56,-37},rotation={0,0,0},scale={12,5.4,5.5}},2)
                      REC.spawned = {}""")
        rt.execute("pcall(function() rttDealAllianceSupporters('Red', BEFORE, 12) end) FLUSH(30)")
        took = [v for v in rt.eval("REC.spawned").values() if str(v).startswith("take:")]
        assert len(took) == 3, "%d frog cards in the deck: drew %d supporters, wanted 3" % (n_frog, len(took))


def t_new_game_removes_frog_cards(src):
    """The deck outlives teardown, so last game's frog cards must be pulled back out."""
    rt = fresh(src)
    rt.execute(DECK_LUA % 14)
    assert _frogs(rt) == 14, "fixture is wrong"
    rt.execute("pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(30)")
    assert _frogs(rt) == 0, "%d frog cards survived into the next game" % _frogs(rt)
    assert rt.eval("#SHARED.__cards") == 40, "removal took non-frog cards too (deck is %d)" % rt.eval("#SHARED.__cards")


CAP_DECK_HASH = "FA78C0F952724D77A33BECEC0651802808037E95"


def _knaves_deck_spawns(rt, drafted):
    rt.execute("SEAT('Red','MrDrouf')")
    rt.execute("RTT_DRAFT_FACTIONS = %s" % ("{'Knaves of the Deepwood'}" if drafted else "{}"))
    rt.execute("""
      DECKS = 0
      local orig = spawnObjectJSON
      spawnObjectJSON = function(p)
        if p and p.json and string.find(p.json, "%s", 1, true) then DECKS = DECKS + 1 end
        return orig(p)
      end
      pcall(function() rttSpawnFaction('Knaves of the Deepwood', 52, -46, false, 'Standard', nil) end)
    """ % CAP_DECK_HASH)
    return rt.eval("DECKS")


def t_captain_deck_without_a_draft(src):
    """No draft: the Knaves keep their own captain deck. Ranked: the draft supplies it instead."""
    assert _knaves_deck_spawns(fresh(src), drafted=False) == 1, \
        "picking the Knaves manually left no captain deck on the board"
    assert _knaves_deck_spawns(fresh(src), drafted=True) == 0, \
        "a ranked draft deals the captains, so the board copy would be a duplicate"


# ---- player-tester reports, 2026-09-04 ---------------------------------------
def _dg_pos(rt):
    if not rt.eval('find_object_by_gm_note("Dragon God") ~= nil'):
        return None
    v = rt.eval('find_object_by_gm_note("Dragon God").getPosition()')
    return [round(float(v[k]), 3) for k in ("x", "y", "z")]


def t_dragon_god_without_a_deck(src):
    """Picking the lizards must put the discard blocker out, deck on the table or not.

    It used to reach the table only through the Lizard Wizard BUTTON, and that button was removed --
    so the Lost Souls board spawned with nothing blocking the discard.
    """
    rt = fresh(src)
    rt.execute("rttLizardSetup() FLUSH(8)")
    at = _dg_pos(rt)
    assert at is not None, "the lizards spawned with no Dragon God on the discard"
    spot = [round(float(rt.eval("rttDragonGodSpot()")[i]), 3) for i in (1, 2, 3)]
    assert at == spot, "rttDragonGodSpot() %s is not where makeSpecial puts the blocker %s" % (spot, at)


def t_dragon_god_reseated_by_a_later_deck(src):
    """A deck chosen AFTER the lizards drops a fresh discard pile; the blocker goes back on top."""
    rt = fresh(src)
    rt.execute("rttLizardSetup() FLUSH(8)")
    spot = _dg_pos(rt)
    rt.execute('find_object_by_gm_note("Dragon God").setPosition({0,3,0})')
    assert _dg_pos(rt) != spot
    rt.execute('makeDeck(nil, nil, "Standard Deck") FLUSH(8)')
    assert _dg_pos(rt) == spot, "a later deck left the Dragon God stranded at %s" % (_dg_pos(rt),)


def t_rats_moods_wait_for_their_board(src):
    """The mood cards must not be spawned in the same instant as the board they land on.

    They were, so they were already falling before the board had a collider -- and the mood the rats
    start with, which spawns dead centre on the printed manager, went through it.
    """
    rt = fresh(src)
    rt.execute("REC.spawned = {} rttSpawnFaction('Lord of the Hundreds', 52, -46, false, 'Standard')")
    during = [v for v in rt.eval("REC.spawned").values()]
    rt.execute("FLUSH(8)")
    after = [v for v in rt.eval("REC.spawned").values()]
    mood = lambda xs: [x for x in xs if x.startswith("Stubborn")]
    assert not mood(during), "the starting mood spawned in the same pass as its board"
    assert mood(after), "the starting mood never spawned at all"


def t_frog_enclaves_match_the_suit_circle(src):
    """Every enclave is sized to the suit marker's circle, and all twelve move together.

    The circle is the marker's suit lobe: 1.8408 world units across, from the largest circle inscribed
    in the lobe (texture hole-filled first, so the white glyph does not cap it) scaled by the markers'
    own 1.30. The enclave art fills 97.2% of its tile, so the tile wants 1.8938 -> scale 0.8343
    against a 2.27-unit Custom_Tile. That last constant is the one thing not measured from the mod, so
    if the token reads visibly wrong in TTS this scale is the single number to move.
    """
    rt = fresh(src)
    d = rt.eval('EVERYTHING["Standard"]["Lilypad Diaspora"]["data"]')
    scales = []
    for i in range(1, len(d) + 1):
        j = json.loads(d[i].json)
        if j.get("Nickname") == "Enclave":
            scales.append(round(j["Transform"]["scaleX"], 6))
    assert len(scales) == 12, "expected 12 enclaves, found %d" % len(scales)
    assert len(set(scales)) == 1, "enclaves came out at mixed sizes: %s" % sorted(set(scales))
    assert abs(scales[0] - 0.8343) < 1e-6, "enclave scale %s is not the measured circle" % scales[0]
    assert scales[0] > 0.703911364, "the enclave is back to its original, smaller size"


def t_enclave_targets_the_suit_marker(src):
    """A dropped enclave must aim at the suit marker's symbol circle, not the marker's origin.

    The target is the LOBE centre, model-local z 0.3599 -- not the suit glyph at 0.4447, which sits
    off-centre in the lobe and would miss by 0.11 world units. Facing comes from the marker's OWN
    rotation, which already points at its clearing centre: fitted over all 68 well-matched markers on
    the six maps the offset is +0.03 deg, concentration 0.9944. Copying it is exact per clearing;
    deriving the bearing from RTT_CLEARING_CENTRES instead carried that table's ~1u error, which is
    what read as tilted.
    """
    rt = fresh(src)
    d = rt.eval('EVERYTHING["Standard"]["Lilypad Diaspora"]["data"]')
    got = 0
    for i in range(1, len(d) + 1):
        j = json.loads(d[i].json)
        if j.get("Nickname") != "Enclave":
            continue
        ls = j["LuaScript"]
        assert "function onDrop" in ls, "an enclave has no onDrop handler"
        assert 'getObjectsWithTag("Clearing Marker")' in ls, "an enclave does not look for suit markers"
        assert "z = 0.3599" in ls, "an enclave is not aimed at the lobe centre"
        assert "FROG_FACING" in ls, "an enclave has no facing"
        assert "bestMarker.getRotation()" in ls, "an enclave is not taking the marker's rotation"
        assert "atan" not in ls, "an enclave computes a bearing again instead of copying"
        got += 1
    assert got == 12, "expected 12 scripted enclaves, found %d" % got


def t_enclaves_do_not_snap(src):
    """An enclave must sit where it is dropped.

    The only snap points in play belong to the MAP -- a ~1.49-unit lattice of warrior/building slots,
    139 of them -- so a dropped enclave jumped to the nearest slot instead of the clearing's printed
    centre. Turning the map's snaps off for every other piece was not an option, and the clearing
    centres the mod knows are only calibrated to ~1 unit, which is over half an enclave. So the token
    opts out of snapping instead, which 219 other objects in this mod already do.
    """
    rt = fresh(src)
    d = rt.eval('EVERYTHING["Standard"]["Lilypad Diaspora"]["data"]')
    flags = []
    for i in range(1, len(d) + 1):
        j = json.loads(d[i].json)
        if j.get("Nickname") == "Enclave":
            flags.append((j.get("Grid"), j.get("Snap")))
    assert len(flags) == 12, "expected 12 enclaves, found %d" % len(flags)
    assert set(flags) == {(False, False)}, "some enclaves still snap: %s" % sorted(set(flags))


def t_turn_order_reapplies_on_seating(src):
    """Re-apply the seat order when someone sits down -- and at no other time.

    Maintainer: readjust each time a player gets seated, but do not force it all the time, so a manual
    reorder is possible. rttEnableTurns already ran once per setup and nothing ever touched Turns
    again, so the "do not force" half was free; this adds the seating half without stealing the turn.
    """
    rt = fresh(src)
    rt.execute("onPlayerChangeColor('Green')")
    assert rt.eval("Turns.enable") is False, "a seat change before any setup must do nothing"

    # setting boards out is not the start of a game: the order is written, but nothing starts
    rt.execute("rttEnableTurns(4)")
    assert list(rt.eval("Turns.order").values()) == ["Red", "Yellow", "Orange", "Teal"]
    assert rt.eval("Turns.enable") is False, "turns started with nobody seated"

    # the first player to sit down starts it, with the order already in place
    rt.execute("SEAT('Red')")
    rt.execute("onPlayerChangeColor('Red')")
    assert rt.eval("Turns.enable") is True, "sitting down did not start the turn system"
    assert list(rt.eval("Turns.order").values()) == ["Red", "Yellow", "Orange", "Teal"]

    rt.execute("Turns.turn_color = 'Orange'")
    rt.execute("onPlayerChangeColor('Teal')")
    assert rt.eval("Turns.turn_color") == "Orange", "seating someone handed the turn back to seat 1"
    assert list(rt.eval("Turns.order").values()) == ["Red", "Yellow", "Orange", "Teal"]

    rt.execute("Turns.order = {'Teal','Red'}")
    rt.execute("FLUSH(8)")
    assert list(rt.eval("Turns.order").values()) == ["Teal", "Red"], "a manual reorder was overwritten"

    # a seat change that changes nothing is a no-op: TTS chimes every time turns are switched on
    rt = fresh(src)
    rt.execute("SEAT('Red') rttEnableTurns(4)")
    rt.execute("Turns.turn_color = 'Orange'")
    rt.execute("onPlayerChangeColor('Red')")
    assert rt.eval("Turns.turn_color") == "Orange", "a no-op seat change disturbed the turn"

    # ...but a NEW GAME must always restart at seat 1, even mid-game with turns already running
    rt.execute("Turns.turn_color = 'Teal'")
    rt.execute("rttEnableTurns(4)")
    assert rt.eval("Turns.turn_color") == "Red", "a new game did not restart at seat 1"

    # turns LATCH: somebody standing up must not switch the system off or reset the turn
    rt.execute("Turns.turn_color = 'Yellow'")
    rt.execute("Player['Red'].seated = false onPlayerChangeColor('Red')")
    assert rt.eval("Turns.enable") is True, "standing up switched the turn system off"
    assert rt.eval("Turns.turn_color") == "Yellow", "standing up reset the turn"


def t_vagabond_is_published_as_a_faction(src):
    """A Vagabond is picked as a CHARACTER but named as a FACTION everywhere downstream.

    Its score marker is "Vagabond VP", never "Tinker VP", so with the character name the marker was
    never tagged and never reached the score track. The seat was published under "Tinker" too, which
    matches nothing on the box score's roster, so the faction did not appear on the sheet at all.
    Both reports, 2026-09-05, one cause.
    """
    rt = fresh(src)
    for char in ("Tinker", "Ranger", "Vagrant", "Adventurer", "Arbiter", "Harrier",
                 "Ronin", "Scoundrel", "Thief", "Gladiator", "Cheat", "Jailor"):
        assert rt.eval("rttFactionKey([[%s]])" % char) == "Vagabond", char
        assert rt.eval("rttVPName([[%s]])" % char) == "Vagabond VP", char
    # the shared kit spawns under its own blueprint names and must not invent a third identity
    for extra in ("Vagabond Layout", "Vagabond Dice and VP"):
        assert rt.eval("rttVPName([[%s]])" % extra) == "Vagabond VP", extra
    # and nothing else moves
    assert rt.eval("rttVPName([[Knaves of the Deepwood]])") == "Knaves VP"
    assert rt.eval("rttVPName([[Marquise de Cat]])") == "Marquise VP"
    assert rt.eval("rttVPName([[Lord of the Hundreds]])") == "Rats VP"
    assert rt.eval("rttFactionKey([[Marquise de Cat]])") == "Marquise de Cat"


def t_gizmo_warrior_to_and_from_supply(src):
    """The gizmo, per the maintainer's spec (2026-09-05).

      hovering ANY warrior -> home to ITS OWN supply, yours or an opponent's
      hovering nothing     -> one comes out of YOUR supply, at your pointer
      empty supply         -> nothing
      no hand zone at all  -> nothing to pull from, but putting one back still works

    Putting a warrior back does not depend on who pressed the key: the piece decides where it
    belongs. Only pulling one out needs to know who you are, which comes from where you are seated.
    """
    rt = fresh(src)
    rt.execute("""
      Global.setVar("RTT_SEAT_COLOR", JSON.encode({ ["Lord of the Hundreds"] = "Red" }))
      PUT, TOOK, TAGGED = {}, 0, 0
      local function mkbag(name)
        local b = MKOBJ(name, {0,1,0}, {})
        b.__n = 3
        b.getQuantity = function() return b.__n end
        b.putObject = function(o) PUT[name] = (PUT[name] or 0) + 1 end
        b.takeObject = function(p)
          TOOK = TOOK + 1
          ROT = p.rotation
          local o = MKOBJ("Hundreds Warrior", p.position, {})
          if p.callback_function then p.callback_function(o) end
          if o.hasTag("RTT Faction") then TAGGED = TAGGED + 1 end
        end
        return b
      end
      MINEBAG  = mkbag("Hundreds Supply")
      THEIRBAG = mkbag("Eyrie Supply")
      MINE   = MKOBJ("Hundreds Warrior", {5,1,5}, {})
      THEIRS = MKOBJ("Eyrie Warrior", {6,1,6}, {})
    """)
    put = lambda: {k: rt.eval("PUT")[k] for k in rt.eval("PUT").keys()}

    rt.execute('HOVER["Red"] = MINE  rttGizmoWarrior("Red")')
    assert put() == {"Hundreds Supply": 1}, put()

    rt.execute('HOVER["Red"] = THEIRS  rttGizmoWarrior("Red")')
    assert put() == {"Hundreds Supply": 1, "Eyrie Supply": 1}, \
        "an enemy warrior must go home to ITS supply: %s" % put()
    assert rt.eval("TOOK") == 0, "hovering a warrior must never pull one out"

    rt.execute('HOVER["Red"] = nil  rttGizmoWarrior("Red")')
    assert rt.eval("TOOK") == 1, "hovering nothing did not take one from your supply"
    assert rt.eval("TAGGED") == 1, "the warrior taken out was not tagged, so a new game keeps it"
    rot = rt.eval("ROT")
    assert rot is not None, "no rotation was given, so it keeps whatever pose it had in the bag"
    assert rot[1] == 0 and rot[3] == 0, "the warrior must come out standing up, got %s" % (
        [rot[i] for i in (1, 2, 3)],)

    rt.execute('MINEBAG.__n = 0  rttGizmoWarrior("Red")')
    assert rt.eval("TOOK") == 1, "an empty supply must do nothing"

    # a colour with no hand zone cannot be placed at all, so there is nothing to pull from.
    # (A colour that HAS one does now find its nearest supply -- that is the point of the fallback.)
    rt.execute('MINEBAG.__n = 5')
    rt.execute('Player["Teal"].getHandTransform = function() return nil end')
    rt.execute('HOVER["Teal"] = nil  rttGizmoWarrior("Teal")')
    assert rt.eval("TOOK") == 1, "a colour with no hand zone must do nothing"

    # ...but sending a piece home never needed a seat
    rt.execute('HOVER["Teal"] = THEIRS  rttGizmoWarrior("Teal")')
    assert put()["Eyrie Supply"] == 2, "putting back must not depend on the presser's seat"


def t_gizmo_finds_your_supply_without_the_published_map(src):
    """RTT_SEAT_COLOR is a runtime Global and does NOT survive a save and reload.

    A resumed game therefore has factions on the table and an empty map, which is what the maintainer
    hit: "it says no faction seated in your color yet ... I am seated and have a faction". Your
    supply is then the faction supply bag nearest your own hand zone -- no publication required.
    """
    rt = fresh(src)
    rt.execute("""
      TOOK, LAST = 0, nil
      local function mkbag(name, x, z)
        local b = MKOBJ(name, {x,1,z}, {})
        b.__n = 3
        b.getQuantity = function() return b.__n end
        b.putObject = function(o) end
        b.takeObject = function(p)
          TOOK = TOOK + 1 LAST = name
          if p.callback_function then p.callback_function(MKOBJ("W", p.position, {})) end
        end
        return b
      end
      mkbag("Hundreds Supply", 52, -46)
      mkbag("Eyrie Supply",   -52,  46)
      SEAT("Red")   Player["Red"].getHandTransform   = function() return { position = {x=52,y=0,z=-46} } end
      SEAT("Green") Player["Green"].getHandTransform = function() return { position = {x=-52,y=0,z=46} } end
    """)
    assert rt.eval('Global.getVar("RTT_SEAT_COLOR")') in (None, ""), "the fixture must start unpublished"

    rt.execute('HOVER["Red"] = nil rttGizmoWarrior("Red")')
    assert rt.eval("LAST") == "Hundreds Supply", "Red got %s" % rt.eval("LAST")
    rt.execute('HOVER["Green"] = nil rttGizmoWarrior("Green")')
    assert rt.eval("LAST") == "Eyrie Supply", "Green got %s" % rt.eval("LAST")
    assert rt.eval("TOOK") == 2

    # when the map IS published it wins, since it is authoritative rather than geometric
    rt.execute('Global.setVar("RTT_SEAT_COLOR", JSON.encode({ ["Eyrie Dynasties"] = "Red" }))')
    rt.execute('HOVER["Red"] = nil rttGizmoWarrior("Red")')
    assert rt.eval("LAST") == "Eyrie Supply", "the published map should win, got %s" % rt.eval("LAST")


def t_gizmo_reads_every_faction_from_its_blueprint(src):
    """Supply and warrior names come out of the blueprints, so no hand-kept table can rot."""
    rt = fresh(src)
    want = {
        "Marquise de Cat": ("Marquise Supply", "Cat Warrior"),
        "Woodland Alliance": ("Alliance Supply", "Alliance Warrior"),
        "The Lizard Cult": ("Lizard Supply", "Lizard Cult Warrior"),
        "Lord of the Hundreds": ("Hundreds Supply", "Hundreds Warrior"),
        "Keepers in Iron": ("Keeper Supply", "Keeper Warrior"),
        "Knaves of the Deepwood": ("Knaves Supply", "Knaves Warrior"),
    }
    for fac, (sup, war) in want.items():
        got = rt.eval("{rttFactionPieceNames([[%s]])}" % fac)
        assert (got[1], got[2]) == (sup, war), "%s -> %s/%s" % (fac, got[1], got[2])

    # and the reverse map every warrior is sent home by
    m = rt.eval("rttWarriorSupplyMap()")
    got = {k: m[k] for k in m.keys()}
    for _, (sup, war) in want.items():
        assert got.get(war) == sup, "%s should go home to %s, got %s" % (war, sup, got.get(war))


def t_ui_objects_clear_their_xml_before_being_destroyed(src):
    """Deleting an object that still has XML UI attached can break TTS colour selection.

    Community-reported engine bug: after such a delete the server hands out only Grey, and a colour
    you have LEFT cannot be retaken, while the hand zones still look fine. The maintainer hit exactly
    that -- "I changed color to another seat and then I'm not able to go back". This mod deletes
    XmlUI objects constantly: every manual selector board on a pick, every ranked selector, the box
    score on each respawn. They all clear the UI first and destroy a frame later.
    """
    rt = fresh(src)
    assert rt.eval("rttDestroyUI") is not None, "the helper is gone"

    rt.execute("""
      CLEARED, KILLED = 0, 0
      local o = MKOBJ("victim", {0,1,0}, {})
      o.UI = { setXml = function() CLEARED = CLEARED + 1 end }
      o.destruct = function() KILLED = KILLED + 1 end
      rttDestroyUI(o)
    """)
    assert rt.eval("CLEARED") == 1, "the UI was not cleared"
    assert rt.eval("KILLED") == 0, "it was destroyed in the same frame as the clear"
    rt.execute("FLUSH(4)")
    assert rt.eval("KILLED") == 1, "it was never actually destroyed"

    # and every destroy of a UI-bearing object goes through it
    for site in ('getObjectsWithTag(t)', 'getObjectsWithTag(RTT_SELECTOR_TAG)',
                 'getObjectsWithTag(RTT_BOXSCORE_TAG)'):
        line = [l for l in src.splitlines() if site in l and "destr" in l.lower()]
        assert line and "rttDestroyUI" in line[0], "%s still calls destruct directly: %s" % (site, line)


def t_gizmo_default_key_is_numpad_zero(src):
    """NUMPAD 0 stays the default, as it always was; the named hotkey is only for machines without one.

    TTS scripting buttons are numbered 1..10 with 10 being numpad 0 -- the convention the original
    Ginso's Gizmo used, and the one this inherited. A PC user needs to configure nothing. The extra
    hotkey is registered UNBOUND, so it only matters on a laptop with no numpad, where the top-row 0
    is a different key entirely (and on a French Mac layout needs Shift as well).
    """
    rt = fresh(src)
    rt.execute("FIRED = 0  rttGizmoWarrior = function(c) FIRED = FIRED + 1 end")
    for idx in (1, 2, 5, 9):
        rt.execute("FIRED = 0  onScriptingButtonDown(%d, 'Red')" % idx)
        assert rt.eval("FIRED") == 0, "scripting button %d should do nothing" % idx
    rt.execute("FIRED = 0  onScriptingButtonDown(10, 'Red')")
    assert rt.eval("FIRED") == 1, "numpad 0 no longer triggers the gizmo"

    # and the fallback exists, without stealing a key from anyone
    assert 'addHotkey("Gizmo: warrior to / from your supply"' in src, "the named hotkey is gone"


def t_mountain_deals_a_legal_board(src):
    """The Mountain prints no suits: it DEALS twelve, and the centre's suit picks what stands there.

    root_engine maps_data/mountain.json -- "the Mountain deals its 12 suit markers at setup" -- and
    HOUSE_RULES M1_mountain_centre -- "which town is set at setup by clearing 10's DEALT suit ...
    fox -> Foxburrow, rabbit -> Rabbittown, mouse -> Mousehold".

    One board in four takes the Lost City instead (maintainer, 2026-09-05). That does NOT leave the
    centre unsuited: the Lost City counts as all three suits.

    What this replaced drew one of four landmarks at random. The eleven markers were already being
    shuffled by shuffleMaps, but shuffling only permutes positions -- the eleven are a fixed multiset
    of 4 fox / 4 rabbit / 3 mouse, so the missing suit was ALWAYS mouse and only Mousehold was legal.
    Dealing swaps which suit stands in each slot, so the centre's suit can vary at all.
    """
    rt = fresh(src)
    towns, lost, n = set(), 0, 400
    for _ in range(n):
        ov = rt.eval("rttMountainPlan(EVERYTHING['Maps']['Mountain Map']['data'])")
        suits, skipped = {}, 0
        for k in ov.keys():
            e = ov[k]
            if e.skip:
                skipped += 1
                continue
            for name, dif in (("fox", "BF0F13D6"), ("rabbit", "195F0F3D"), ("mouse", "AF3D10F2")):
                if dif in e.json:
                    suits[name] = suits.get(name, 0) + 1
        assert skipped == 1, "the Tower must be skipped exactly once, got %d" % skipped
        assert sorted(suits.values()) == [3, 4, 4], "the eleven markers are wrong: %s" % suits

        centre = rt.eval("RTT_MTN_CENTRE_SUIT")
        assert centre in ("fox", "rabbit", "mouse"), centre
        if rt.eval("RTT_MTN_CENTRE_LOST"):
            lost += 1                       # wild centre: the markers stay 4/4/3
        else:
            suits[centre] = suits.get(centre, 0) + 1
            assert sorted(suits.values()) == [4, 4, 4], "a town must complete 4/4/4: %s" % suits
            towns.add(centre)
    assert towns == {"fox", "rabbit", "mouse"}, "the centre town never varied: %s" % towns
    assert 0.15 < lost / n < 0.35, "Lost City came up %.0f%% of the time, expected ~25%%" % (100*lost/n)


def t_published_colour_matches_the_seated_player(src):
    """THE invariant: the colour published for the faction at seat i is the colour of the PLAYER at seat i.

    Reported from a live tournament, 2026-09-05: "it's assuming player 4 is player 3 since they were
    able to spawn p3 warriors with 0". Two different numberings exist -- RTT_POS numbers the six board
    SPOTS, RTT_SETUP_COLORS is indexed by PLAYER NUMBER -- and RTT_LAYOUT maps one to the other so the
    seating runs counterclockwise. rttSeatPlayers colours a player by PLAYER NUMBER; rttPlaceFaction
    worked the same player's colour out from the nearest SPOT and indexed the colour table with that,
    never undoing RTT_LAYOUT. So the published note was wrong wherever the layout is not the identity:
    right at 1 and 3 players, wrong at 2, 4, 5 and 6. At four players P3 and P4 held each other's
    colour, which is exactly what the tester saw.

    The gizmo (rttSeatFaction) and the box score (refreshSeats) both read that note, and the box score
    treats it as authoritative and marks the colour used, so its own geometry cannot repair it.

    This asserts the invariant directly, at every seat count, so no future change can reintroduce a
    mapping that is merely self-consistent rather than correct.
    """
    for n in (2, 3, 4, 5, 6):
        rt = fresh(src)
        names = ["H%d" % i for i in range(1, n + 1)]
        # Seat the humans in colours that are deliberately NOT the seat-colour list, so a test that
        # passes cannot be passing because the two happen to coincide.
        joined = ["Purple", "Blue", "White", "Pink", "Green", "Brown"][:n]
        for c, nm in zip(joined, names):
            rt.execute("SEAT('%s','%s')" % (c, nm))
        rt.execute("RTT_ORDER = {} " + " ".join(
            "RTT_ORDER[%d] = {color='%s', name='%s'}" % (i + 1, joined[i], names[i]) for i in range(n)))
        rt.execute("rttSpawnSelectors() FLUSH(6) pcall(function() rttSeatPlayers() end) FLUSH(30)")

        facs = ["Marquise de Cat", "Eyrie Dynasties", "Woodland Alliance", "Riverfolk Company",
                "The Lizard Cult", "Corvid Conspiracy"][:n]
        for i in range(n):
            rt.execute("""local s = RTT_SEATS[%d]
                          pcall(function()
                            rttPlaceFaction('%s', s.pos[1], s.pos[2], s.pos[2] > 0, s.color,
                                            true, nil, nil, s.color, nil)
                          end) FLUSH(4)""" % (i + 1, facs[i]))

        pub = json.loads(rt.eval('GVGET("RTT_SEAT_COLOR")') or "{}")
        for i in range(n):
            seat_color = rt.eval("RTT_SEATS[%d].color" % (i + 1))
            assert seat_color is not None, "%d seats: seat %d has no colour at all" % (n, i + 1)
            got = pub.get(facs[i])
            assert got == seat_color, (
                "%d seats: seat %d's faction %s published %r but that seat's player is %r"
                % (n, i + 1, facs[i], got, seat_color))
        # and no two factions may claim the same colour -- rttSeatFaction resolves a duplicate with an
        # arbitrary pairs() winner, so a collision is a silently wrong gizmo.
        vals = [pub.get(f) for f in facs]
        assert len(set(vals)) == len(vals), "%d seats: two factions share a colour %s" % (n, vals)


def _seat_ranked(rt, joined, names):
    """Drive the ranked path's seating with humans already holding `joined` colours."""
    for c, nm in zip(joined, names):
        rt.execute("SEAT('%s','%s')" % (c, nm))
    rt.execute("RTT_ORDER = {} " + " ".join(
        "RTT_ORDER[%d] = {color='%s', name='%s'}" % (i + 1, joined[i], names[i])
        for i in range(len(joined))))
    rt.execute("rttSpawnSelectors() FLUSH(6) pcall(function() rttSeatPlayers() end) FLUSH(30)")


def t_nobody_is_recoloured(src):
    """The draft assigns a SEAT, never a colour.

    The maintainer, 2026-09-05: "players join the game, they can pick their color, this should never
    be forced". It used to copy the base mod's placePlayer -- kick the whole table to Grey, then
    changeColor everyone into RTT_SETUP_COLORS[seat]. In TTS the hand, the cards in it and the slot in
    Turns.order all belong to the COLOUR, so forcing one takes a player's hand away and hands it to
    whoever gets that colour next.
    """
    joined = ["Purple", "Blue", "White", "Pink"]
    names = ["H1", "H2", "H3", "H4"]
    rt = fresh(src)
    _seat_ranked(rt, joined, names)
    for c, nm in zip(joined, names):
        assert rt.eval("Player['%s'].seated" % c) is True, "%s (%s) was moved out of their colour" % (nm, c)
        assert rt.eval("Player['%s'].steam_name" % c) == nm, "%s no longer holds %s" % (nm, c)
    assert len(list((rt.eval("REC.colors") or {}).values())) == 0, \
        "somebody was recoloured: %s" % list((rt.eval("REC.colors") or {}).values())
    # and each seat wears its own player's colour
    for i, c in enumerate(joined):
        assert rt.eval("RTT_SEATS[%d].color" % (i + 1)) == c, \
            "seat %d took %r, not its player's %r" % (i + 1, rt.eval("RTT_SEATS[%d].color" % (i + 1)), c)


def t_turn_order_is_clockwise_from_bottom_right(src):
    """Turn order is read off the table, not out of a list.

    The maintainer: "turn order is decided clockwise by the position from the first player who's the
    closest to the bottom right corner". Bottom-right is +x/-z, which is RTT_POS[1] = (52,-46).
    It used to be RTT_SETUP_COLORS[1..n] -- a fixed list that also forced the going-round order, and
    RTT_LAYOUT[6] is not even clockwise ({1,2,5,6,4,3} where clockwise is {1,5,2,4,6,3}).
    """
    import math
    POS = {1: (52, -46), 2: (-52, -46), 3: (52, 46), 4: (-52, 46), 5: (0, -46), 6: (0, 46)}
    LAYOUT = {2: [1, 3], 3: [1, 2, 3], 4: [1, 2, 4, 3], 5: [1, 5, 2, 4, 3]}
    a0 = math.atan2(POS[1][1], POS[1][0])
    for n in (2, 3, 4, 5):
        joined = ["Purple", "Blue", "White", "Pink", "Green"][:n]
        names = ["H%d" % i for i in range(1, n + 1)]
        rt = fresh(src)
        _seat_ranked(rt, joined, names)
        # seat i sits at spot LAYOUT[n][i]; clockwise = decreasing angle from the bottom-right corner
        want = [joined[i] for i in sorted(
            range(n), key=lambda i: (a0 - math.atan2(*reversed(POS[LAYOUT[n][i]]))) % (2 * math.pi))]
        got = list((rt.eval("Turns.order") or {}).values())
        assert got == want, "%d seats: turn order %s, clockwise from bottom-right is %s" % (n, got, want)


def t_seat_record_survives_a_reload(src):
    """A TTS Global is wiped on load; the board's own onSave state is not.

    Without this a resumed game came back with factions on the table and no idea who sat where: the
    gizmo said "no faction seated in your color yet" and the box score fell back to guessing rows from
    hand-zone geometry. The maintainer asked for memory that survives a crash.
    """
    rt = fresh(src)
    _seat_ranked(rt, ["Purple", "Blue", "White", "Pink"], ["H1", "H2", "H3", "H4"])
    facs = ["Marquise de Cat", "Eyrie Dynasties", "Woodland Alliance", "Riverfolk Company"]
    for i, f in enumerate(facs):
        rt.execute("""local s = RTT_SEATS[%d]
                      pcall(function() rttPlaceFaction('%s', s.pos[1], s.pos[2], s.pos[2] > 0,
                            s.color, true, nil, nil, s.color, nil) end) FLUSH(4)""" % (i + 1, f))
    saved = rt.eval("onSave()")
    assert saved and saved != "", "onSave produced nothing"

    rt2 = fresh(src)                                   # a fresh table: Globals are gone, as on reload
    assert rt2.eval('Global.getVar("RTT_SEAT_COLOR")') in (None, "", "{}")
    rt2.execute("onLoad(%s) FLUSH(6)" % json.dumps(saved))
    for i, (c, f) in enumerate(zip(["Purple", "Blue", "White", "Pink"], facs)):
        assert rt2.eval("RTT_SEATS[%d].color" % (i + 1)) == c, "seat %d lost its colour" % (i + 1)
        assert rt2.eval("RTT_SEATS[%d].faction" % (i + 1)) == f, "seat %d lost its faction" % (i + 1)
    # the gizmo works again straight after the reload, which is the point of persisting it
    assert rt2.eval("rttSeatFaction('White')") == "Woodland Alliance"
    pub = json.loads(rt2.eval('GVGET("RTT_SEAT_COLOR")') or "{}")
    assert pub.get("Riverfolk Company") == "Pink", "the mirror was not re-published on load"


def t_manual_pick_binds_the_pickers_own_colour(src):
    """On the manual paths nobody is seated, so the seat is worth the colour of whoever picked it.

    And one person setting out several boards -- a solo tester -- must not bind every faction to that
    one colour: the later seats take a free colour instead, so no two factions ever share one (the
    gizmo cannot tell them apart if they do).
    """
    rt = fresh(src)
    rt.execute("SEAT('Purple','H1') SEAT('Blue','H2')")
    rt.execute("pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(10)")
    # two different people pick on two different boards
    rt.execute("""pcall(function() rttPlaceFaction('Marquise de Cat', 52, -46, false, 'Purple',
                        false, nil, nil, 'Purple', nil) end) FLUSH(4)""")
    rt.execute("""pcall(function() rttPlaceFaction('Eyrie Dynasties', -52, -46, false, 'Blue',
                        false, nil, nil, 'Blue', nil) end) FLUSH(4)""")
    pub = json.loads(rt.eval('GVGET("RTT_SEAT_COLOR")') or "{}")
    assert pub.get("Marquise de Cat") == "Purple", "picker's colour not bound: %s" % pub
    assert pub.get("Eyrie Dynasties") == "Blue", "picker's colour not bound: %s" % pub
    # the same person now sets out two more; they must NOT both become Purple
    rt.execute("""pcall(function() rttPlaceFaction('Woodland Alliance', 52, 46, true, 'Purple',
                        false, nil, nil, 'Purple', nil) end) FLUSH(4)""")
    rt.execute("""pcall(function() rttPlaceFaction('Riverfolk Company', -52, 46, true, 'Purple',
                        false, nil, nil, 'Purple', nil) end) FLUSH(4)""")
    pub = json.loads(rt.eval('GVGET("RTT_SEAT_COLOR")') or "{}")
    vals = [pub.get(f) for f in ("Marquise de Cat", "Eyrie Dynasties",
                                 "Woodland Alliance", "Riverfolk Company")]
    assert None not in vals, "a faction went unpublished: %s" % pub
    assert len(set(vals)) == 4, "two factions share a colour: %s" % vals
    assert pub["Marquise de Cat"] == "Purple", "the first picker lost their own colour"


def t_the_seat_record_is_pushed_to_the_sheet(src):
    """The record does not just get published, it is PUSHED at the box score.

    The sheet used to re-read three TTS Globals every six seconds and treat the colour one as
    authoritative -- and Globals are wiped on load, so a resumed game silently fell back to guessing
    rows from hand-zone geometry. RTT knows the exact moment seating and faction placement happen, so
    it hands the record over instead. It must go as a JSON STRING: raw Lua tables do not cross
    object-script boundaries in TTS.
    """
    rt = fresh(src)
    rt.execute("""
      PUSHED = {}
      local fake = { call = function(fn, arg) PUSHED[#PUSHED+1] = { fn = fn, arg = arg } end,
                     getGUID = function() return "sheet1" end }
      local _gowt = getObjectsWithTag
      getObjectsWithTag = function(t)
        if t == RTT_BOXSCORE_TAG then return { fake } end
        return _gowt(t)
      end
    """)
    _seat_ranked(rt, ["Purple", "Blue", "White", "Pink"], ["H1", "H2", "H3", "H4"])
    facs = ["Marquise de Cat", "Eyrie Dynasties", "Woodland Alliance", "Riverfolk Company"]
    for i, f in enumerate(facs):
        rt.execute("""local s = RTT_SEATS[%d]
                      pcall(function() rttPlaceFaction('%s', s.pos[1], s.pos[2], s.pos[2] > 0,
                            s.color, true, nil, nil, s.color, nil) end) FLUSH(4)""" % (i + 1, f))
    n = rt.eval("#PUSHED")
    assert n and n > 0, "the sheet was never pushed to"
    last = rt.eval("PUSHED[#PUSHED]")
    assert last["fn"] == "rttSeatPush", "pushed to %r" % last["fn"]
    arg = last["arg"]
    assert isinstance(arg, str), "pushed a %s -- raw Lua tables do not cross object boundaries" % type(arg).__name__
    rec = json.loads(arg)
    seats = {e["faction"]: e for e in rec["seats"] if e.get("faction")}
    for f, c in zip(facs, ["Purple", "Blue", "White", "Pink"]):
        assert seats[f]["color"] == c, "%s pushed as %s, its player is %s" % (f, seats[f]["color"], c)
        assert seats[f]["owner"] != "", "%s pushed with no owner" % f
    # and the pushed order IS the turn order, clockwise from the bottom-right
    pushed_order = [e["color"] for e in rec["seats"]]
    assert pushed_order == list((rt.eval("Turns.order") or {}).values()), \
        "the pushed order %s is not the turn order %s" % (pushed_order, list((rt.eval("Turns.order") or {}).values()))


def t_gizmo_never_reaches_into_someone_elses_supply(src):
    """Every gizmo failure must SAY something, never quietly act on the wrong faction.

    A Vagabond seat has no warriors at all, so rttFactionPieceNames returns nothing for it. The code
    then fell through to a geometric search of the whole table and handed the player the NEAREST
    warrior supply -- an opponent's -- with no message: their bag silently lost a piece and an extra
    warrior appeared on the board. The hirelings hit the mirror image of this: "Advocate Warrior"
    ends in "Warrior" but has no supply bag in any blueprint, so hovering one returned in silence and
    the key just looked broken.
    """
    rt = fresh(src)
    rt.execute("""
      TOOK = 0
      local function mkbag(name, x, z)
        local b = MKOBJ(name, {x,1,z}, {})
        b.__n = 3
        b.getQuantity = function() return b.__n end
        b.putObject = function(o) end
        b.takeObject = function(p) TOOK = TOOK + 1 end
        return b
      end
      mkbag("Eyrie Supply", -52, -46)
      mkbag("Marquise Supply", 52, 46)
      -- Red plays the Ranger: a Vagabond, so no supply of their own anywhere on the table
      Global.setVar("RTT_SEAT_COLOR", JSON.encode({ ["Ranger"] = "Red" }))
      Player["Red"].getHandTransform = function() return { position = {x=-52,y=0,z=-64} } end
      SAID = {}
    """)
    rt.execute('HOVER["Red"] = nil rttGizmoWarrior("Red")')
    assert rt.eval("TOOK") == 0, "a Vagabond seat pulled a warrior out of somebody else's supply"
    said = [str(x) for x in (rt.eval("SAID") or {}).values()]
    assert said, "it failed silently -- the player is told nothing"
    assert "Ranger" in said[0], "the message does not name the faction: %r" % said[0]

    # a hireling warband: named "... Warrior" but in nobody's supply map
    rt.execute("""SAID = {}
                  HIRE = MKOBJ("Advocate Warrior", {0,1,0}, {})
                  HOVER["Red"] = HIRE
                  rttGizmoWarrior("Red")""")
    said = [str(x) for x in (rt.eval("SAID") or {}).values()]
    assert said, "hovering a hireling warband did nothing and said nothing"
    assert "Advocate Warrior" in said[0], "the message does not name the piece: %r" % said[0]
    assert rt.eval("TOOK") == 0, "hovering a hireling pulled a warrior out of a supply"


def t_one_seat_holds_one_faction(src):
    """The manual Faction Select board is NOT destroyed when you pick on it.

    So several factions can be placed from the same spot. Matching a seat on position alone would let
    the second overwrite the first and lose a whole seat -- and with it that faction's colour, owner
    and turn slot.
    """
    rt = fresh(src)
    rt.execute("SEAT('Purple','H1')")
    rt.execute("pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(10)")
    for fac in ("Marquise de Cat", "Eyrie Dynasties", "Woodland Alliance"):
        rt.execute("""pcall(function() rttPlaceFaction('%s', 54.81, 0, false, 'Purple',
                            false, nil, nil, 'Purple', nil) end) FLUSH(4)""" % fac)
    pub = json.loads(rt.eval('GVGET("RTT_SEAT_COLOR")') or "{}")
    for fac in ("Marquise de Cat", "Eyrie Dynasties", "Woodland Alliance"):
        assert fac in pub, "%s was overwritten by a later pick on the same board: %s" % (fac, pub)
    vals = [pub[f] for f in ("Marquise de Cat", "Eyrie Dynasties", "Woodland Alliance")]
    assert len(set(vals)) == 3, "three factions from one board share a colour: %s" % vals


def t_a_vagabond_is_published_under_its_faction_name(src):
    """A Vagabond is picked as a CHARACTER but known downstream as a FACTION.

    Its score marker is "Vagabond VP", never "Ranger VP", so the box score's row is "Vagabond" and a
    seat published under "Ranger" matches nothing on the sheet -- the faction simply does not appear.
    The seat record therefore carries BOTH: `faction` (the blueprint name, which the gizmo needs to
    find the supply) and `key` (rttFactionKey, which is what the mirrors are keyed by).
    """
    for char in ("Ranger", "Tinker", "Thief", "Arbiter"):
        rt = fresh(src)
        rt.execute("SEAT('Purple','H1')")
        rt.execute("pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(10)")
        rt.execute("""pcall(function() rttPlaceFaction('%s', 52, -46, false, 'Purple',
                            false, nil, nil, 'Purple', nil) end) FLUSH(4)""" % char)
        pub = json.loads(rt.eval('GVGET("RTT_SEAT_COLOR")') or "{}")
        assert pub.get("Vagabond") == "Purple", \
            "%s published as %s -- the box score looks for 'Vagabond'" % (char, list(pub))
        assert char not in pub, "%s published under its character name too: %s" % (char, list(pub))
        rec = json.loads(rt.eval('GVGET("RTT_SEAT_RECORD")') or "{}")
        seat = [e for e in rec["seats"] if e.get("key") == "Vagabond"][0]
        assert seat["faction"] == char, \
            "the record lost the character name the gizmo needs: %s" % seat
        # and the gizmo still resolves the CHARACTER, not the collapsed key
        assert rt.eval("rttSeatFaction('Purple')") == char


def t_two_vagabonds_get_one_marker_each(src):
    """Root allows two vagabonds, and the kit ships the pair of markers that makes them tellable apart.

    "Vagabond Dice and VP" spawns exactly two Custom_Tiles, both nicknamed "Vagabond VP": 068b0a is
    black and plain, 765187 is white and carries the nine TTS player colours as STATES. Both used to
    spawn for every vagabond, so one left an orphan on the table and two put out four -- and because a
    box-score row IS its marker's name, both players collapsed onto ONE row with the second showing no
    score at all.

    White is taken first on purpose: renaming only ever touches the BLACK tile, and the white one
    carries its nickname ten times over (itself plus nine states), so renaming that one would have to
    hit all ten or it would rename itself back the moment somebody switched colour.

    Maintainer, 2026-09-05: "vagabonds comes with two vp markers to handle two vagabonds, one white
    one black, so that might be part of the solution."
    """
    rt = fresh(src)
    rt.execute("SEAT('Purple','H1') SEAT('Blue','H2')")
    rt.execute("pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(10)")
    for char, x, z, col in (("Ranger", 52, -46, "Purple"), ("Thief", -52, -46, "Blue")):
        rt.execute("""pcall(function() rttPlaceFaction('%s', %d, %d, false, '%s',
                            false, nil, nil, '%s', nil) end) FLUSH(4)""" % (char, x, z, col, col))
        rt.execute("""pcall(function()
              local si = rttSeatAt(%d, %d, false, '%s')
              local seat = si and RTT_SEATS[si] or nil
              local n = (seat and seat.vagN) or 1
              rttSpawnFaction('Vagabond Dice and VP', %d, %d, false, 'Standard', 0,
                { vpKeep = RTT_VAGABOND_VP[RTT_VAGABOND_VP_ORDER[n] or 'White'],
                  vpName = rttVPName(rttVagabondKey(n)) })
            end) FLUSH(6)""" % (x, z, char, x, z))

    # the kit really does hold eleven identically-named markers -- pinned, because the whole filter
    # exists to stop all eleven going out, and a blueprint change that dropped them would make the
    # rest of this test pass for the wrong reason
    n_tiles = rt.eval('''function()
      local n = 0
      for _, v in ipairs(EVERYTHING['Standard']['Vagabond Dice and VP']['data']) do
        if v.json:find('"Nickname": "Vagabond VP"', 1, true) then n = n + 1 end
      end
      return n
    end''')()
    assert n_tiles == 2, (
        "the kit should spawn exactly TWO tiles named 'Vagabond VP' -- 068b0a black and 765187 white "
        "-- but has %s" % n_tiles)
    assert rt.eval("RTT_VAGABOND_VP.White") == "765187", "the white marker moved"
    assert rt.eval("RTT_VAGABOND_VP.Black") == "068b0a", "the black marker moved"

    counts = {}
    for line in (rt.eval("REC.spawned") or {}).values():
        nm = str(line).split("@")[0]
        if "Vagabond" in nm and nm.endswith("VP"):
            counts[nm] = counts.get(nm, 0) + 1
    assert counts == {"Vagabond VP": 1, "Vagabond 2 VP": 1}, \
        "two vagabonds should put out exactly one marker each, got %s" % counts

    # the seats are keyed apart, which is what gives the sheet two rows
    keys = [rt.eval("RTT_SEATS[%d].key" % i) for i in (1, 2)]
    assert keys == ["Vagabond", "Vagabond 2"], "seat keys %s" % keys
    pub = json.loads(rt.eval('GVGET("RTT_SEAT_COLOR")') or "{}")
    assert pub == {"Vagabond": "Purple", "Vagabond 2": "Blue"}, pub
    # and the record still carries each seat's CHARACTER, which is what names the variant column
    rec = json.loads(rt.eval('GVGET("RTT_SEAT_RECORD")') or "{}")
    chars = sorted(e["faction"] for e in rec["seats"] if e.get("key", "").startswith("Vagabond"))
    assert chars == ["Ranger", "Thief"], "the record lost the characters: %s" % chars


def t_order_cards_do_not_survive_a_new_game(src):
    """Zaandaa: "old seat number cards remain if you start a new draft".

    A new game clears the table two ways: by TAG, and by RTT_SPAWNED, a list of guids it spawned. The
    turn-order DECK was on that list, so the deck died -- but rttDealOrderCards TAKES the cards OUT of
    it into players' hands, and a card taken from a deck is its own object with its own guid, on no
    list and carrying no tag at all (verified: the blueprint had zero "Tags" entries). So the deck went
    and everybody kept holding last game's seat number.

    The tag is baked into the CARDS, not just the deck, because that is what makes it hold: a card
    keeps its own tags when it leaves the deck, so the sweep finds it in a hand, on the table, or as
    the leftover nobody was dealt.
    """
    import re as _re
    # 1. every object in both order decks carries the tag
    for name, want_cards in (("RTT_ORDER_JSON_4", 4), ("RTT_ORDER_JSON_5", 5)):
        head = name + " = [==["
        i = src.index(head); start = i + len(head); end = src.index("]==]", start)
        d = json.loads(src[start:end])
        assert "RTT Order Card" in (d.get("Tags") or []), "%s: the deck itself is untagged" % name
        cards = d.get("ContainedObjects") or []
        assert len(cards) == want_cards, "%s holds %d cards, expected %d" % (name, len(cards), want_cards)
        for c in cards:
            assert "RTT Order Card" in (c.get("Tags") or []), \
                "%s: card %s (CardID %s) is untagged -- it would survive a new game" \
                % (name, c.get("GUID"), c.get("CardID"))

    # 2. the tag is actually swept
    rt = fresh(src)
    tags = list((rt.eval("RTT_TEARDOWN_TAGS") or {}).values())
    assert "RTT Order Card" in tags, "the tag is baked but never swept: %s" % tags

    # 3. and an object carrying it really is destroyed by a new game, on BOTH setup paths
    for start_game in ("setupFactionBoards(nil,nil,nil)", "rttSetup(nil,nil,'rttRankedBtn')"):
        rt = fresh(src)
        rt.execute("SEAT('Purple','H1') math.randomseed(5)")
        rt.execute('OLDCARD = MKOBJ("Player 3", {10,1,10}, {"RTT Order Card"})')
        assert rt.eval("OLDCARD.__dead") is not True
        rt.execute("pcall(function() %s end) FLUSH(24)" % start_game)
        assert rt.eval("OLDCARD.__dead") is True, \
            "a seat-number card survived %s" % start_game.split("(")[0]


def t_the_duchy_burrow_spawns_locked(src):
    """Zaandaa re-locked the Duchy's burrow by hand for everybody, every game.

    The Burrow is the Underground Duchy's off-map tunnel board -- it never moves during play, but it
    shipped with "Locked": false, so it could be dragged out of place by accident. Locked in the
    BLUEPRINT rather than with a setLock(true) in the spawn callback, which is the golden rule and is
    also safer here: every faction piece is spawned straight at its final position by
    spawnObjectJSON, so there is no window in which it is loose.

    Locking the tile does not stop warriors being placed on it -- the landmarks work the same way.

    The Drillbit Duchy bot carries the same object (GUID 78c688) and is deliberately NOT locked: the
    maintainer chose to leave the bot data exactly as the base mod ships it. Nothing spawns it anyway
    -- "Official Bots" appears in no live code path -- so this is asserted to keep the choice explicit
    rather than to protect behaviour.
    """
    rt = fresh(src)
    probe = rt.eval("""function(cat, name)
      for _, v in ipairs(EVERYTHING[cat][name]['data']) do
        if v.json:find('"Nickname":"The Burrow"', 1, true)
           or v.json:find('"Nickname": "The Burrow"', 1, true) then
          return (v.json:match('"GUID":%s*"([0-9a-f]+)"') or '?')
            .. '/' .. tostring(v.json:match('"Locked":%s*(%a+)'))
        end
      end
      return 'not found'
    end""")
    assert probe("Standard", "Underground Duchy") == "78c688/true", \
        "the Duchy's burrow is %s -- it will be draggable again" % probe("Standard", "Underground Duchy")
    assert probe("Official Bots", "Drillbit Duchy") == "78c688/false", \
        "the bot's burrow was changed; the maintainer asked for the live Duchy only"


def t_camera_states_are_the_hosts(src):
    """The number-key camera views are Zaandaa's, because he hosts and streams.

    His are steeper and closer than the ones the mod shipped -- the seat views go from a 50-56 degree
    oblique at distance ~48 to 73-79 degrees at ~53-60, which reads better on a stream and makes
    clearings easier to pick out. 9 of the 10 differed; state 0 was already identical.

    Unlike everything else in this suite this reads the SAVE, not the board script: CameraStates is a
    top-level field of the save file, nothing to do with the Lua. It is checked against `cs`, the
    fragment Zaandaa supplied, so regenerating gen/src/save.json from a stale table cannot quietly put
    the old views back.

    NOTE for the maintainer: tools/update_saves.py rewrites only the board's script/XmlUI/assets, so
    this does NOT reach a resumed autosave. A game started fresh from the shipped save gets it.
    """
    frag = open(os.path.join(REPO, "cs"), encoding="utf-8").read().strip().rstrip(",")
    want = json.loads("{" + frag + "}")["CameraStates"]
    for path in ("dist/Root_Tabletop_Tournament.json", "gen/src/save.json"):
        got = json.load(open(os.path.join(REPO, path), encoding="utf-8")).get("CameraStates")
        assert got is not None, "%s has no CameraStates at all" % path
        assert len(got) == 10, "%s has %d camera states, expected 10" % (path, len(got))
        assert json.dumps(got, sort_keys=True) == json.dumps(want, sort_keys=True), \
            "%s does not carry the host's camera states" % path


def t_timer_and_counter_sit_bottom_right(src):
    """Zaandaa: put the turn timer and counter to the right of the board's bottom-right corner.

    The space under the battle mat is otherwise unused and is the easiest place to reach on screen --
    and explicitly NOT the box score there, which he says is too much. The maintainer placed them by
    hand and saved as TS_Save_27; these are those coordinates.

    He also resized the COUNTER while he was there, 1.25 -> 1.55, and left the CLOCK alone. Both are
    asserted, because "the clock is still 1.107" is the decision, not an omission.

    Both objects ship with a BLANK Nickname, so they are found by Name -- "Digital_Clock" and
    "Counter" -- never by nickname.
    """
    rt = fresh(src)
    want = {"Digital_Clock": (29.4800, -17.1446), "Counter": (29.6331, -20.8561)}
    for k, (x, z) in want.items():
        got = rt.eval("RTT_%s_POS" % ("TIMER" if k == "Digital_Clock" else "COUNTER"))
        gx, gz = got[1], got[3]
        assert abs(gx - x) < 1e-3 and abs(gz - z) < 1e-3, \
            "%s is at (%.4f, %.4f), the maintainer placed it at (%.4f, %.4f)" % (k, gx, gz, x, z)

    # scales, straight out of the blueprint blobs
    for key, want_scale in (("RTT_COUNTER_JSON", 1.55), ("RTT_TIMER_JSON", 1.107143)):
        head = key + " = [==["
        i = src.index(head); j = src.index("]==]", i)
        t = json.loads(src[i + len(head):j])["Transform"]
        assert abs(t["scaleX"] - want_scale) < 1e-4, \
            "%s scaleX is %.6f, expected %.6f" % (key, t["scaleX"], want_scale)

    # and they really do come out with the map, tagged so the next map replaces them
    rt.execute("pcall(function() makeMap('', '', 'Summer Map') end) FLUSH(40)")
    spawned = [str(x) for x in (rt.eval("REC.spawned") or {}).values()]
    for k, (x, z) in want.items():
        hit = [l for l in spawned if l.startswith(k + "@")]
        assert hit, "%s did not spawn with the map (spawned: %s)" % (k, spawned[:6])
        at = hit[-1].split("@")[1]
        assert at == "%.1f,%.1f" % (x, z), "%s spawned at %s, expected %.1f,%.1f" % (k, at, x, z)


def t_crow_plots_spawn_inside_the_hidden_zone(src):
    """The crows' 12 plots go INSIDE their hidden zone, face up.

    They used to lie face DOWN on the crow board's own 4x3 grid, so the crow player could not read
    their own plots without picking each one up in front of everybody. The zone beside the board is
    already fogged to that player's colour, so face UP inside it they read at a glance while opponents
    see a blank block. Face down in a zone would gain nothing -- a face-down tile is unreadable to its
    owner too.

    Positions are derived from the zone rather than written down separately, so if the zone is moved
    (the maintainer has asked Zaandaa whether the spot is right) only RTT_CROW_HZ_LX/_LZ change and the
    plots follow on the next spawn.

    Absolute coordinates here are stub artifacts -- its positionToWorld does not apply the board's
    transform -- so this asserts the RELATIVE geometry, which is what the change is about.
    """
    rt = fresh(src)
    rt.execute("SEAT('Purple','H1') pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(10)")
    rt.execute("""pcall(function() rttPlaceFaction('Corvid Conspiracy', 52, -46, false, 'Purple',
                        false, nil, nil, 'Purple', nil) end) FLUSH(40)""")
    got = rt.eval("""function()
      local zone, plots = nil, {}
      for _, o in ipairs(getAllObjects()) do
        local n = o.getName() or ''
        if n == 'Plot' then plots[#plots+1] = o
        elseif n:find('FogOfWar') then zone = o end
      end
      if zone == nil then return 'NO ZONE' end
      local t = { string.format('%d|%f|%f|%f|%f', #plots, zone.__pos.x, zone.__pos.z,
                                zone.__scale.x, zone.__scale.z) }
      for _, p in ipairs(plots) do
        t[#t+1] = string.format('%f|%f|%f', p.__pos.x - zone.__pos.x, p.__pos.z - zone.__pos.z, p.__rot.z)
      end
      return table.concat(t, ';')
    end""")()
    assert got != "NO ZONE", "the crows spawned no hidden zone at all"
    rows = got.split(";")
    n, zx, zz, sx, sz = rows[0].split("|")
    assert int(n) == 12, "expected 12 plots, got %s" % n
    half_x, half_z = float(sx) / 2, float(sz) / 2

    offs = []
    for r in rows[1:]:
        dx, dz, rotz = (float(v) for v in r.split("|"))
        assert abs(dx) < half_x and abs(dz) < half_z, \
            "a plot sits OUTSIDE the hidden zone: offset (%.2f, %.2f) against half-extents (%.2f, %.2f)" \
            % (dx, dz, half_x, half_z)
        assert abs(rotz) < 1 or abs(rotz - 360) < 1, \
            "a plot spawned face DOWN (rotZ %.0f) -- inside a zone that hides it from its own owner" % rotz
        # 1dp: the board transform carries float noise, so -2.401 and -2.399 are the same column
        offs.append((round(dx, 1), round(dz, 1)))

    assert len(set(offs)) == 12, "plots are stacked on each other: %d distinct spots" % len(set(offs))
    assert len(set(x for x, _ in offs)) == 4 and len(set(z for _, z in offs)) == 3, \
        "the layout is not the 4x3 grid: %s" % sorted(set(offs))


def dx_caps_expected(dx):
    return dx - (-15.7569)


def t_crafted_board_sits_the_same_side_for_every_faction(src):
    """Zaandaa: crafts sit immediately right of every other faction board, so the Knaves broke it.

    Measured across all twelve before moving anything: the crafted-improvements board is at
    dx +15.7 to +16.3 from its own rules board on ELEVEN factions, and the Knaves were the single
    exception at -15.6 -- the captains board held the standard spot and crafted was mirrored away.
    Swapped at the maintainer's call, each keeping the distance he had tuned rather than snapping to
    the modal +15.84.

    The captains offsets are READ OUT of the maintainer's save 'knaves' (TS_Save_29), which he took
    after the swap and the recentre and then nudged closer: dx -15.7569, dz +4.4790.

    The overlap check below covers TILES only. An earlier version compared every object by its
    `scale`, decided the captains board sat 0.88 inside the Knaves supply bag, and moved it to 17.5 to
    "clear" it -- but `scale` is not a footprint for a Custom_Model_Bag, whose mesh is far smaller
    than its scale number. The collision never existed; his own save has them at exactly this spacing.
    """
    rt = fresh(src)
    rt.execute("SEAT('Purple','H1') pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(10)")
    rt.execute("""pcall(function() rttPlaceFaction('Knaves of the Deepwood', 52, -46, false, 'Purple',
                        false, nil, nil, 'Purple', nil) end) FLUSH(60)""")
    got = rt.eval("""function()
      local t = {}
      for _, o in ipairs(getAllObjects()) do
        local n = tostring(o.getName())
        if o.__scale and o.__scale.x and o.__scale.x > 2
           and n ~= 'Faction Board' and n ~= 'Faction Selection' then
          t[#t+1] = n .. '|' .. o.__pos.x .. '|' .. o.__pos.z .. '|' .. o.__scale.x .. '|' .. o.__scale.z
        end
      end
      return table.concat(t, ';')
    end""")
    items = []
    for r in got().split(";"):
        if not r: continue
        n, x, z, sx, sz = r.split("|")
        items.append((n, float(x), float(z), float(sx), float(sz)))

    rules = [i for i in items if abs(i[3] - 8.82) < 0.05]
    craft = [i for i in items if abs(i[3] - 9.52) < 0.05]
    caps  = [i for i in items if i[0] == "Knaves Captains"]
    assert rules and craft and caps, "could not find all three boards: %s" % [(i[0], i[3]) for i in items]

    # the BOARD ITSELF, moved right twice on the maintainer's instruction: -4.14 -> -2.98 -> -1.82,
    # +1.16 each time, the whole assembly together so the internal layout never changes. It now sits
    # between the cluster (-2.95..-3.29) and Keepers in Iron (-1.69).
    board_dx = rules[0][1] - 52
    assert abs(board_dx - (-1.82)) < 0.05, \
        "the Knaves board is at dx %+.2f, the maintainer put it at -1.82" % board_dx
    assert abs(dx_caps_expected(caps[0][1] - rules[0][1])) < 0.05, \
        "the captains board is at dx %+.4f from the board; his save has -15.7569" % (caps[0][1] - rules[0][1])

    dx_craft = craft[0][1] - rules[0][1]
    dx_caps  = caps[0][1] - rules[0][1]
    assert dx_craft > 12, \
        "the crafted board is at dx %+.2f from the rules board -- every other faction has it at +15.8" % dx_craft
    assert dx_caps < -12, "the captains board should be on the mirror side, it is at dx %+.2f" % dx_caps

    # and nothing the swap moved landed on anything else. The Advanced Setup card RIDES on the
    # crafted board, so that pair is expected; everything else must be clear.
    # TILES only -- boards. `scale` is a fair footprint for a flat Custom_Tile and is NOT one for a
    # Custom_Model_Bag or a stack of cards, which is what made the earlier version of this test invent
    # a collision that the maintainer's own save disproves.
    BOARD_W = (8.82, 9.04, 9.11, 9.52, 13.25)
    boards = [i for i in items if any(abs(i[3] - w) < 0.05 for w in BOARD_W)]
    def overlaps(a, b):
        return abs(a[1] - b[1]) < (a[3] + b[3]) / 2 and abs(a[2] - b[2]) < (a[4] + b[4]) / 2
    bad = [(a[0], round(a[3], 2), b[0], round(b[3], 2))
           for i, a in enumerate(boards) for b in boards[i + 1:] if overlaps(a, b)]
    assert not bad, "two BOARDS overlap at the Knaves seat: %s" % bad


def t_no_setup_card_rides_on_the_crafted_board(src):
    """Zaandaa asked for the Advanced Setup card to go; the maintainer agreed.

    Every faction laid ONE card beside its crafted-improvements board -- CardIDs 400, 401, 402, 404,
    405, 407, 408, 409, 410 on a shared 6x2 sheet, plus 73000 / 73200 / 73300 on their own. Identified
    by ARTWORK, not by name: the cards carry blank nicknames and blank descriptions, and that shared
    sheet is the one the "Advanced Setup" tool uses for its faction cards.

    Asserted per faction, so a card creeping back into one blueprint cannot hide behind the other
    eleven -- and asserted on the BLUEPRINT rather than on a spawn, because that is where it lived.
    """
    GONE = {"Marquise de Cat": 400, "Eyrie Dynasties": 401, "Woodland Alliance": 402,
            "Riverfolk Company": 404, "The Lizard Cult": 405, "Underground Duchy": 407,
            "Corvid Conspiracy": 408, "Lord of the Hundreds": 409, "Keepers in Iron": 410,
            "Twilight Council": 73000, "Lilypad Diaspora": 73200, "Knaves of the Deepwood": 73300}
    rt = fresh(src)
    for fac, cid in GONE.items():
        n = rt.eval("""function(f, cid)
          local n = 0
          for _, v in ipairs(EVERYTHING['Standard'][f]['data']) do
            if v.json:find('"CardID": ' .. cid, 1, true)
               or v.json:find('"CardID":' .. cid, 1, true) then n = n + 1 end
          end
          return n
        end""")(fac, cid)
        assert n == 0, "%s still carries the setup card (CardID %s) on its crafted board" % (fac, cid)

    # and the crafted board itself is still there -- the removal must not have taken the board with it
    for fac in GONE:
        has = rt.eval("""function(f)
          for _, v in ipairs(EVERYTHING['Standard'][f]['data']) do
            if v.json:find('D0737E5D33E99FD553C8253', 1, true) then return true end
          end
          return false
        end""")(fac)
        assert has is True, "%s lost its crafted-improvements board" % fac


def t_vagabond_cards_come_with_faction_cards(src):
    """Zaandaa: the Vagabond Cards button is redundant, so fold its deck into Faction Cards.

    Verified before removing it: every Vagabond character blueprint already carries that character's
    own meeple AND its card, so the tool's 21 meeples were duplicates. Only the twelve-card character
    deck comes along, as a fifth deck continuing the row's 7.95 spacing.
    """
    rt = fresh(src)
    n = rt.eval("#RTT_HOOT")
    assert n == 5, "Faction Cards lays %s decks, expected 5" % n
    # its spot is the maintainer's own, from his save 'faction' (TS_Save_30): a SECOND ROW behind the
    # captains deck, not a fifth along the first row, which is where I had guessed it.
    at = rt.eval("""function()
      for _, e in ipairs(RTT_HOOT) do
        if math.abs(e.pos[3] - 28.681) < 0.01 then
          return string.format('%.3f,%.3f', e.pos[1], e.pos[3])
        end
      end
      return 'missing'
    end""")()
    assert at == "50.225,28.681", "the vagabond deck is at %s; his save has 50.225,28.681" % at

    # it is the CHARACTER deck: twelve cards, the vagabond CardIDs
    ok = rt.eval("""function()
      for _, e in ipairs(RTT_HOOT) do
        if math.abs(e.pos[3] - 28.681) < 0.01 then
          local n = 0
          for _ in e.json:gmatch('"CardID"') do n = n + 1 end
          return n
        end
      end
      return -1
    end""")()
    assert ok == 12, "the fifth deck holds %s cards, expected 12" % ok

    # and the button is gone, with its art
    rt.execute("XML = ''")
    assert 'id="Vagabond Cards"' not in src, "the makeTool button is still declared"
    assert '{name = "Vagabond Cards"' not in src, "the button art is still registered"


def t_the_two_free_button_slots_are_bottom_right(src):
    """Maintainer, 2026-09-05: "the two empty button option should be in the second row to the right".

    Dropping the Vagabond Cards button left a hole mid-row. The tool rows have six slots each at
    x = -95, -57, -19, 19, 57, 95; there are ten buttons for twelve slots, so two are always empty and
    where they sit is a choice. Credits moved up one row -- its x did not change, only its row -- which
    fills the hole and puts both gaps at the right end of the SECOND row.

    Reads the built save, because this is XmlUI on the board object rather than anything in the Lua.
    """
    x = json.load(open(os.path.join(REPO, "dist/Root_Tabletop_Tournament.json"),
                       encoding="utf-8"))["ObjectStates"]
    def walk(objs):
        for o in objs:
            yield o
            for c in (o.get("ContainedObjects") or []): yield from walk([c])
    xml = [o for o in walk(x) if o.get("GUID") == "bab7e1"][0]["XmlUI"]

    import re as _re
    rows = {}
    for m in _re.finditer(r'<Button\b[^>]*>', xml):
        seg = m.group(0)
        pos = _re.search(r'position="(-?\d+) (-?\d+) (-?\d+)"', seg)
        w = _re.search(r'width="(\d+)"', seg)
        i = _re.search(r'id="([^"]*)"', seg)
        if pos and w and w.group(1) == "36":          # the 36x20 option buttons only
            rows.setdefault(int(pos.group(2)), {})[int(pos.group(1))] = i.group(1) if i else "?"
    SLOTS = [-95, -57, -19, 19, 57, 95]
    top, bottom = rows.get(-55, {}), rows.get(-78, {})
    assert len(top) == 6, "the first tool row has %d of 6 slots filled: %s" % (len(top), sorted(top))
    free = [s for s in SLOTS if s not in bottom]
    assert free == [57, 95], "the free slots are at %s, they should be the two rightmost of row 2" % free
    assert top.get(57) == "rttCreditsBtn", "the hole at x=57 is filled by %r" % top.get(57)


def t_captain_warriors_line_up_with_their_captains(src):
    """Maintainer, 2026-09-05: the warrior spawned by the captain board is a bit misaligned.

    The two rows were measured off his save separately and came out with different starts AND
    different steps -- meeples -0.551 step 0.272, warriors -0.510 step 0.250 -- so each warrior sat a
    little to the side of its own captain, by a different amount per column: +0.36 world units under
    the first, +0.17 under the second, -0.03 under the third. Sharing the captain's x fixes all three
    at once; the warrior row keeps its own z.

    Asserted as a shared FORMULA rather than three literals, so a future nudge to the captain row
    carries the warriors with it instead of silently reopening the gap.
    """
    rt = fresh(src)
    got = rt.eval("""function()
      local t = {}
      -- drive the two placement helpers against a stand-in board whose transform is the identity,
      -- so the board-local numbers come straight back out
      local kb = MKOBJ('KB', {0, 0, 0}, {})   -- MKOBJ already defaults scale to 1 and rotation to 0
      RTT_CAP_KNAVE_GUID = kb.getGUID()
      RTT_CAP_MEEPLE_JSON = { X = '{"Nickname": "Captain - X"}' }
      RTT_CAP_WARRIOR_JSON = '{"Nickname": "Knaves Warrior"}'
      RTT_CAP_WARRIOR_N = 0
      for idx = 0, 2 do
        SPAWNED_AT = nil
        rttSpawnCaptainMeeple('X', idx)
        local cx = SPAWNED_AT
        SPAWNED_AT = nil
        rttSpawnCaptainWarrior(idx)
        t[#t+1] = string.format('%.4f|%.4f', cx or -99, SPAWNED_AT or -99)
      end
      return table.concat(t, ';')
    end""")
    rt.execute("""
      local _s = spawnObjectJSON
      spawnObjectJSON = function(p)
        local pos = (p or {}).position
        SPAWNED_AT = pos and (pos.x or pos[1]) or nil
        return _s(p)
      end
    """)
    rows = got().split(";")
    for i, r in enumerate(rows):
        cx, wx = (float(v) for v in r.split("|"))
        assert cx != -99 and wx != -99, "column %d spawned nothing (%s)" % (i, r)
        assert abs(wx - cx) < 1e-6, \
            "column %d: the warrior is at x %.4f under a captain at %.4f" % (i, wx, cx)


CASES = [
    ("manual path drives the turn system",   t_manual_turn_order),
    ("manual path spawns 4 / 5 boards",      t_boards_spawn),
    ("a new game resets run state",          t_new_game_resets_state),
    ("order cards cleared by a new game",    t_order_cards_do_not_survive_a_new_game),
    ("duchy burrow spawns locked",           t_the_duchy_burrow_spawns_locked),
    ("camera states are the host's",         t_camera_states_are_the_hosts),
    ("timer and counter bottom-right",       t_timer_and_counter_sit_bottom_right),
    ("crow plots inside the hidden zone",    t_crow_plots_spawn_inside_the_hidden_zone),
    ("crafted board same side for all",      t_crafted_board_sits_the_same_side_for_every_faction),
    ("no setup card on crafted board",       t_no_setup_card_rides_on_the_crafted_board),
    ("vagabond cards with faction cards",    t_vagabond_cards_come_with_faction_cards),
    ("two free slots are bottom-right",      t_the_two_free_button_slots_are_bottom_right),
    ("captain warriors line up",             t_captain_warriors_line_up_with_their_captains),
    ("manual setup clears ranked objects",   t_ranked_objects_cleared_by_manual),
    ("supporters take the seat explicitly",  t_supporters_take_the_seat_explicitly),
    ("both transform shapes agree",          t_seat_hand_array_shape),
    ("shared deck found with frogs in it",   t_main_deck_survives_frogs),
    ("supporters draw with frogs in play",   t_supporters_draw_with_frogs_in_deck),
    ("a new game removes frog cards",        t_new_game_removes_frog_cards),
    ("captain deck when nothing drafts it",  t_captain_deck_without_a_draft),
    ("lizards bring their discard blocker",   t_dragon_god_without_a_deck),
    ("a later deck re-seats the blocker",     t_dragon_god_reseated_by_a_later_deck),
    ("mood cards wait for the rats board",    t_rats_moods_wait_for_their_board),
    ("enclaves match the suit circle",        t_frog_enclaves_match_the_suit_circle),
    ("enclaves sit where they are dropped",   t_enclaves_do_not_snap),
    ("enclave aims at the suit circle",       t_enclave_targets_the_suit_marker),
    ("turn order re-applies on seating",      t_turn_order_reapplies_on_seating),
    ("vagabond published as a faction",       t_vagabond_is_published_as_a_faction),
    ("mountain deals a legal board",          t_mountain_deals_a_legal_board),
    ("gizmo default key is numpad 0",         t_gizmo_default_key_is_numpad_zero),
    ("gizmo: warrior to/from supply",         t_gizmo_warrior_to_and_from_supply),
    ("gizmo reads every blueprint",           t_gizmo_reads_every_faction_from_its_blueprint),
    ("gizmo works without the seat map",      t_gizmo_finds_your_supply_without_the_published_map),
    ("UI cleared before destroy",             t_ui_objects_clear_their_xml_before_being_destroyed),
    ("published colour == seated player",     t_published_colour_matches_the_seated_player),
    ("nobody is recoloured",                 t_nobody_is_recoloured),
    ("turn order clockwise from BR",         t_turn_order_is_clockwise_from_bottom_right),
    ("seat record survives a reload",        t_seat_record_survives_a_reload),
    ("manual pick binds picker colour",      t_manual_pick_binds_the_pickers_own_colour),
    ("seat record is pushed to sheet",       t_the_seat_record_is_pushed_to_the_sheet),
    ("gizmo never takes another supply",     t_gizmo_never_reaches_into_someone_elses_supply),
    ("one seat holds one faction",           t_one_seat_holds_one_faction),
    ("vagabond published under faction",     t_a_vagabond_is_published_under_its_faction_name),
    ("two vagabonds, one marker each",       t_two_vagabonds_get_one_marker_each),
]


def main():
    old = "--old" in sys.argv
    if old:
        raw = subprocess.run(["git", "-C", REPO, "show", "main:dist/Root_Tabletop_Tournament.json"],
                             capture_output=True, text=True).stdout
        label = "PRE-REFACTOR"
    else:
        raw = open(os.path.join(REPO, "dist", "Root_Tabletop_Tournament.json"), encoding="utf-8").read()
        label = "current"
    src = board_lua(raw)

    failed = []
    for name, fn in CASES:
        try:
            fn(src)
            print("  %-13s %-38s OK" % (label, name))
        except AssertionError as e:
            failed.append(name)
            print("  %-13s %-38s FAIL  %s" % (label, name, e))
        except Exception as e:
            failed.append(name)
            print("  %-13s %-38s ERROR %s" % (label, name, str(e)[:90]))

    if old:
        print("\n(pre-refactor run: failures above are the bugs these tests guard)")
        return 0
    if failed:
        print("\nFAILED: %s" % ", ".join(failed))
        return 1
    print("\nall setup-path cases OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
