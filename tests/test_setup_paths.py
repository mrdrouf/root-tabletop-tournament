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


CASES = [
    ("manual path drives the turn system",   t_manual_turn_order),
    ("manual path spawns 4 / 5 boards",      t_boards_spawn),
    ("a new game resets run state",          t_new_game_resets_state),
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
    ("gizmo default key is numpad 0",         t_gizmo_default_key_is_numpad_zero),
    ("gizmo: warrior to/from supply",         t_gizmo_warrior_to_and_from_supply),
    ("gizmo reads every blueprint",           t_gizmo_reads_every_faction_from_its_blueprint),
    ("gizmo works without the seat map",      t_gizmo_finds_your_supply_without_the_published_map),
    ("UI cleared before destroy",             t_ui_objects_clear_their_xml_before_being_destroyed),
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
