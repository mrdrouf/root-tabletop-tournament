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
import json, os, re, subprocess, sys
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
    """Four and five boards, AT THE SEAT COORDINATES.

    The count was the only thing asserted; the stub records each spawn as "name@x,z" and the test
    parsed the coordinates out and threw them away, so it passed with every board at the origin or
    all five stacked on one seat. The positions are the point -- a board's position IS its seat.
    """
    for arg, n in (("nil", 4), ("'fivePlayerSetup'", 5)):
        rt = fresh(src)
        rt.execute("REC.spawned={} pcall(function() setupFactionBoards(nil,nil,%s) end) FLUSH(10)" % arg)
        got = [str(rt.eval("REC.spawned")[i]) for i in range(1, len(rt.eval("REC.spawned")) + 1)]
        assert len(got) == n, "%d seats: spawned %d boards (%s)" % (n, len(got), got)

        at = sorted(tuple(round(float(v)) for v in e.split("@")[1].split(",")) for e in got)
        want = sorted((round(float(rt.eval("RTT_POS[%d][1]" % p))),
                       round(float(rt.eval("RTT_POS[%d][2]" % p))))
                      for p in (int(rt.eval("RTT_LAYOUT[%d]" % n)[i]) for i in range(1, n + 1)))
        assert at == want, "%d seats: boards at %s, the seats are at %s" % (n, at, want)
        assert len(set(at)) == n, "%d seats: two boards landed on one spot: %s" % (n, at)


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
    """The two halves, per the maintainer's 2026-09-06 spec.

      numpad 0, hovering ANY warrior       -> home to ITS OWN supply, yours or an opponent's
      numpad 0, hovering the wood          -> home to Wood Supply, by the same rule
      numpad 0, hovering NOTHING           -> nothing. It does not spawn any more.
      numpad 1                             -> one warrior out of YOUR supply, at your pointer,
                                              whatever the pointer happens to be over

    Putting a piece back does not depend on who pressed the key: the piece decides where it belongs.
    Only TAKING one needs to know who you are. An ownership check on the send-home half lasted a few
    hours on 2026-09-07 and was removed again -- "so it s not broken when it s wrong about who is who".
    """
    rt = fresh(src)
    rt.execute("""
      Global.setVar("RTT_SEAT_COLOR", JSON.encode({ ["Lord of the Hundreds"] = "Red" }))
      PUT, TOOK = {}, 0
      local function mkbag(name)
        local b = MKOBJ(name, {0,1,0}, {})
        b.__n = 3
        b.getQuantity = function() return b.__n end
        b.putObject = function(o) PUT[name] = (PUT[name] or 0) + 1 end
        b.takeObject = function(p)
          TOOK = TOOK + 1
          local o = MKOBJ("Hundreds Warrior", p.position, {})
          if p.callback_function then p.callback_function(o) end
        end
        return b
      end
      MINEBAG  = mkbag("Hundreds Supply")
      THEIRBAG = mkbag("Eyrie Supply")
      WOODBAG  = mkbag("Wood Supply")
      MINE   = MKOBJ("Hundreds Warrior", {5,1,5}, {})
      THEIRS = MKOBJ("Eyrie Warrior", {6,1,6}, {})
      WOOD   = MKOBJ("Wood", {7,1,7}, {})
    """)
    put = lambda: {k: rt.eval("PUT")[k] for k in rt.eval("PUT").keys()}

    rt.execute('HOVER["Red"] = MINE   rttGizmoHome("Red")')
    assert put() == {"Hundreds Supply": 1}, put()
    rt.execute('HOVER["Red"] = THEIRS rttGizmoHome("Red")')
    assert put() == {"Hundreds Supply": 1, "Eyrie Supply": 1}, \
        "an opponent's warrior must go to ITS supply, not the presser's: %s" % put()
    # the wood is the MARQUISE's, so only a Marquise player can send it back -- same rule as above
    rt.execute('Global.setVar("RTT_SEAT_COLOR", JSON.encode({ ["Marquise de Cat"] = "Red" }))')
    rt.execute('HOVER["Red"] = WOOD   rttGizmoHome("Red")')
    assert put().get("Wood Supply") == 1, "the Marquise's wood did not go back to Wood Supply: %s" % put()
    rt.execute('Global.setVar("RTT_SEAT_COLOR", JSON.encode({ ["Lord of the Hundreds"] = "Red" }))')

    # hovering NOTHING no longer spawns
    rt.execute('HOVER["Red"] = nil  rttGizmoHome("Red")')
    assert rt.eval("TOOK") == 0, "numpad 0 spawned a warrior -- it must only send pieces home now"

    # numpad 1 takes, and does NOT care what the pointer is over
    rt.execute('POINTER["Red"] = {x = 20, y = 1, z = -30} HOVER["Red"] = MINE rttGizmoTake("Red")')
    assert rt.eval("TOOK") == 1, "numpad 1 did not take a warrior while hovering one"
    landed = rt.eval("""function()
      local hit = nil
      for _, o in ipairs(getAllObjects()) do
        if (o.getName() or '') == 'Hundreds Warrior' and o.__smoothFast ~= nil then hit = o end
      end
      if hit == nil then return 'none' end
      return string.format('%.1f,%.1f,%s', hit.__pos.x, hit.__pos.z, tostring(hit.__smoothFast))
    end""")()
    assert landed == "20.0,-30.0,true", \
        "the warrior should arrive at the pointer by a FAST smooth move; got %s" % landed


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
    """TWO keys now, at the maintainer's request (2026-09-06): numpad 0 SENDS HOME, numpad 1 TAKES.

    Numpad 0 no longer spawns anything -- hovering nothing does nothing at all -- and numpad 1 does
    what 0 used to do when hovering nothing, without caring what the pointer is over.

    TTS scripting buttons are numbered 1..10 with 10 being numpad 0, the convention the original
    Ginso's Gizmo used. A PC user configures nothing; the two named hotkeys are registered UNBOUND for
    machines with no numpad, where the top-row 0 is a different key (and needs Shift on a French Mac).
    """
    rt = fresh(src)
    rt.execute("HOME, TAKE = 0, 0")
    rt.execute("rttGizmoHome = function(c) HOME = HOME + 1 end")
    rt.execute("rttGizmoTake = function(c) TAKE = TAKE + 1 end")
    for idx in (2, 3, 5, 9):
        rt.execute("HOME, TAKE = 0, 0  onScriptingButtonDown(%d, 'Red')" % idx)
        assert rt.eval("HOME") == 0 and rt.eval("TAKE") == 0, "button %d should do nothing" % idx
    rt.execute("HOME, TAKE = 0, 0  onScriptingButtonDown(10, 'Red')")
    assert rt.eval("HOME") == 1 and rt.eval("TAKE") == 0, "numpad 0 must SEND HOME, not take"
    rt.execute("HOME, TAKE = 0, 0  onScriptingButtonDown(1, 'Red')")
    assert rt.eval("TAKE") == 1 and rt.eval("HOME") == 0, "numpad 1 must TAKE a warrior"

    assert 'addHotkey("Gizmo: send the hovered piece home"' in src, "the send-home hotkey is gone"
    assert 'addHotkey("Gizmo: take a warrior from your supply"' in src, "the take hotkey is gone"


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
        owners = json.loads(rt.eval('GVGET("RTT_SEAT_PLAYER")') or "{}")
        for i in range(n):
            seat_color = rt.eval("RTT_SEATS[%d].color" % (i + 1))
            assert seat_color is not None, "%d seats: seat %d has no colour at all" % (n, i + 1)
            got = pub.get(facs[i])
            assert got == seat_color, (
                "%d seats: seat %d's faction %s published %r but that seat's colour is %r"
                % (n, i + 1, facs[i], got, seat_color))

            # AND THE HUMAN. Everything above compares the published mirror against the mod's OWN seat
            # record -- two outputs of the same code, so a mapping that is merely self-consistent
            # passes. This is the check the docstring promised and did not make: the colour a faction
            # is published under must be held by the person the record says owns that seat.
            person = rt.eval("Player[%r].steam_name" % seat_color)
            seated = rt.eval("Player[%r].seated" % seat_color)
            assert seated is True, (
                "%d seats: %s is published under %s, which nobody is sitting in"
                % (n, facs[i], seat_color))
            assert owners.get(facs[i]) == person, (
                "%d seats: %s is published under %s (held by %r) but owned by %r"
                % (n, facs[i], seat_color, person, owners.get(facs[i])))
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


def t_seat_colour_is_the_turn_order(src):
    """A seat's colour IS its turn-order number, and the player is recoloured into it.

    The maintainer, 2026-09-06: "Force color of seat to be color of turn card order. That means that
    when player are seated they change color; only affects the draft since that s the only time turn
    card order are dealt." So whoever is dealt "Player 1" is Red, "Player 2" Yellow, and so on.

    This REVERSES his 2026-09-05 rule ("players join the game, they can pick their color, this should
    never be forced"), and the reason that rule existed still holds everywhere else: in TTS the hand
    and the cards in it belong to the COLOUR. Forcing one is safe HERE and only here, because seating
    runs before a single card is dealt, so every hand is empty at that moment.

    The swap case is the one that actually bites: two players holding each other's target colours
    cannot both change directly, because each target is still occupied. Hence the park-in-Grey pass.
    """
    SETUP = ["Red", "Yellow", "Orange", "Teal", "Green"]
    # H1 joined as Yellow and must become Red; H2 joined as Red and must become Yellow -- a direct
    # swap, which fails outright without the two-phase park.
    joined = ["Yellow", "Red", "White", "Pink"]
    names = ["H1", "H2", "H3", "H4"]
    rt = fresh(src)
    _seat_ranked(rt, joined, names)

    for n, nm in enumerate(names, start=1):
        want = SETUP[n - 1]
        assert rt.eval("Player['%s'].steam_name" % want) == nm, \
            "seat %d should be %s (%s); %s holds it instead" % (
                n, want, nm, rt.eval("Player['%s'].steam_name" % want))
        assert rt.eval("Player['%s'].seated" % want) is True, "%s is not seated in %s" % (nm, want)
        assert rt.eval("RTT_SEATS[%d].color" % n) == want, \
            "seat %d records %r, not its turn colour %r" % (n, rt.eval("RTT_SEATS[%d].color" % n), want)
        assert rt.eval("RTT_SEATS[%d].owner" % n) == nm, "seat %d lost its owner" % n

    # nobody is left parked in the spectator seat by the two-phase swap
    for nm in names:
        assert rt.eval("Player['Grey'].steam_name") != nm, "%s was left in Grey" % nm

    # the hand follows the FORCED colour to that seat -- otherwise a player is recoloured into a seat
    # whose hand is still out at the table edge, which is worse than not forcing at all
    for n in range(1, len(names) + 1):
        want = SETUP[n - 1]
        hx = rt.eval("Player['%s'].getHandTransform(1).position.x" % want)
        hz = rt.eval("Player['%s'].getHandTransform(1).position.z" % want)
        sx = rt.eval("RTT_SEATS[%d].hand.pos[1]" % n)
        sz = rt.eval("RTT_SEATS[%d].hand.pos[3]" % n)
        assert abs(hx - sx) < 0.01 and abs(hz - sz) < 0.01, \
            "seat %d: %s's hand is at (%.1f,%.1f), its seat is at (%.1f,%.1f)" % (n, want, hx, hz, sx, sz)

    # and the turn system runs on those same colours, in seat order
    assert list((rt.eval("Turns.order") or {}).values()) == SETUP[:len(names)], \
        "turn order is not the forced colours: %s" % list((rt.eval("Turns.order") or {}).values())


def t_turn_order_is_clockwise_from_bottom_right(src):
    """Turn order is read off the table, not out of a list.

    The maintainer: "turn order is decided clockwise by the position from the first player who's the
    closest to the bottom right corner". Bottom-right is +x/-z, which is RTT_POS[1] = (52,-46).
    It used to be RTT_SETUP_COLORS[1..n] -- a fixed list that also forced the going-round order, and
    RTT_LAYOUT[6] is not even clockwise ({1,2,5,6,4,3} where clockwise is {1,5,2,4,6,3}).
    """
    import math
    # READ FROM THE MOD, NOT FROM A COPY. These used to be Python literals inside the test, so the
    # expected order and the actual order were both computed from the test's own idea of the layout:
    # a change that made the mod's seat geometry non-clockwise would have passed unchanged.
    def lua_pos(rt):
        return {i: (rt.eval("RTT_POS[%d][1]" % i), rt.eval("RTT_POS[%d][2]" % i)) for i in range(1, 7)}
    def lua_layout(rt, n):
        m = rt.eval("RTT_LAYOUT[%d]" % n)
        return [int(m[i]) for i in range(1, n + 1)]
    probe = fresh(src)
    POS = lua_pos(probe)
    LAYOUT = {n: lua_layout(probe, n) for n in (2, 3, 4, 5)}
    assert POS[1] == (52, -46), "RTT_POS[1] is no longer the bottom-right corner: %s" % (POS[1],)
    a0 = math.atan2(POS[1][1], POS[1][0])
    for n in (2, 3, 4, 5):
        joined = ["Purple", "Blue", "White", "Pink", "Green"][:n]
        names = ["H%d" % i for i in range(1, n + 1)]
        rt = fresh(src)
        _seat_ranked(rt, joined, names)
        # seat i sits at spot LAYOUT[n][i]; clockwise = decreasing angle from the bottom-right corner
        # Seat i now WEARS RTT_SETUP_COLORS[i] (the turn-card colour), so the expected order is that
        # list read off the table geometrically -- the derivation is still the geometry, not the list.
        SETUP = ["Red", "Yellow", "Orange", "Teal", "Green", "Brown"]
        want = [SETUP[i] for i in sorted(
            range(n), key=lambda i: (a0 - math.atan2(*reversed(POS[LAYOUT[n][i]]))) % (2 * math.pi))]
        got = list((rt.eval("Turns.order") or {}).values())
        assert got == want, "%d seats: turn order %s, clockwise from bottom-right is %s" % (n, got, want)
        # LAYOUT is built so that seat index order IS clockwise order; if that ever stops being true
        # the colours would no longer state the turn order, which is the whole point of forcing them.
        assert got == SETUP[:n], "%d seats: colour no longer states turn order: %s" % (n, got)


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
    # The seats wear their turn-order colours, not the colours the players joined in.
    for i, (c, f) in enumerate(zip(["Red", "Yellow", "Orange", "Teal"], facs)):
        assert rt2.eval("RTT_SEATS[%d].color" % (i + 1)) == c, "seat %d lost its colour" % (i + 1)
        assert rt2.eval("RTT_SEATS[%d].faction" % (i + 1)) == f, "seat %d lost its faction" % (i + 1)
    # the gizmo works again straight after the reload, which is the point of persisting it
    assert rt2.eval("rttSeatFaction('Orange')") == "Woodland Alliance"
    pub = json.loads(rt2.eval('GVGET("RTT_SEAT_COLOR")') or "{}")
    assert pub.get("Riverfolk Company") == "Teal", "the mirror was not re-published on load"


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
    for f, c in zip(facs, ["Red", "Yellow", "Orange", "Teal"]):
        assert seats[f]["color"] == c, "%s pushed as %s, its seat's turn colour is %s" % (f, seats[f]["color"], c)
        assert seats[f]["owner"] != "", "%s pushed with no owner" % f
    # and the pushed order IS the turn order, clockwise from the bottom-right
    pushed_order = [e["color"] for e in rec["seats"]]
    assert pushed_order == list((rt.eval("Turns.order") or {}).values()), \
        "the pushed order %s is not the turn order %s" % (pushed_order, list((rt.eval("Turns.order") or {}).values()))


def t_gizmo_never_reaches_into_someone_elses_supply(src):
    """Taking must never quietly act on the wrong faction; SENDING HOME must never guess.

    A Vagabond seat has no warriors at all, so rttFactionPieceNames returns nothing for it. The take
    half used to fall through to a geometric search of the whole table and hand the player the NEAREST
    supply -- an opponent's -- with no message. It reports why instead.

    The send-home half takes the opposite rule, at the maintainer's request: a piece it cannot place
    is left alone SILENTLY. A hireling warband or a card is not the gizmo's business and a message
    every time would be noise.
    """
    rt = fresh(src)
    rt.execute("""
      TOOK = 0
      local function mkbag(name, x, z)
        local b = MKOBJ(name, {x,1,z}, {})
        b.__n = 3
        b.getQuantity = function() return b.__n end
        b.putObject = function(o) PUTN = (PUTN or 0) + 1 end
        b.takeObject = function(p) TOOK = TOOK + 1 end
        return b
      end
      mkbag("Eyrie Supply", -52, -46)
      mkbag("Marquise Supply", 52, 46)
      Global.setVar("RTT_SEAT_COLOR", JSON.encode({ ["Ranger"] = "Red" }))
      Player["Red"].getHandTransform = function() return { position = {x=-52,y=0,z=-64} } end
      SAID, PUTN = {}, 0
    """)
    rt.execute('HOVER["Red"] = nil rttGizmoTake("Red")')
    assert rt.eval("TOOK") == 0, "a Vagabond seat pulled a warrior out of somebody else's supply"
    said = [str(x) for x in (rt.eval("SAID") or {}).values()]
    assert said and "Ranger" in said[0], "taking failed without naming the faction: %r" % said

    # send-home on something it cannot place: silent, and nothing moves
    rt.execute("""SAID = {}
                  HIRE = MKOBJ("Advocate Warrior", {3,1,3}, {})
                  HOVER["Red"] = HIRE
                  rttGizmoHome("Red")""")
    assert not [str(x) for x in (rt.eval("SAID") or {}).values()], \
        "send-home spoke about a piece it cannot place; the maintainer asked for silence"
    assert rt.eval("PUTN") == 0, "send-home put an unknown piece into a bag"
    at = rt.eval("function() return string.format('%.1f,%.1f', HIRE.__pos.x, HIRE.__pos.z) end")()
    assert at == "3.0,3.0", "send-home moved a piece it does not know: now at %s" % at


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

    The Drillbit Duchy bot carried the same object (GUID 78c688), deliberately NOT locked, and this
    used to assert that too. EVERYTHING['Official Bots'] was removed on 2026-09-06 -- 497 KB of
    blueprint for eight bots with no button, no lookup and no spawn path, exactly as this docstring
    already said ("Official Bots appears in no live code path"). The bot half of the assertion went
    with the data; the live Duchy half is the one that protects behaviour.
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


def t_the_turn_panel_is_the_only_clock(src):
    """The panel is simply what the table has -- no option, no way back to the old clock.

    It shipped as an option, with a button that swapped it for the digital clock and counter while it
    was still being shaped. That is finished: "remove the button turn panel" (2026-09-07). The button,
    rttToggleTurnPanel and rttSpawnOldClock are all gone, and nothing must quietly bring them back.
    """
    rt = fresh(src)
    rt.execute("pcall(function() makeMap('', '', 'Summer Map') end) FLUSH(60)")
    spawned = [str(x) for x in (rt.eval("REC.spawned") or {}).values()]
    assert any(l.startswith("Turn Panel@") for l in spawned), \
        "the turn panel did not come with the map (spawned: %s)" % spawned[:8]
    for name in ("Digital_Clock", "Counter"):
        assert not any(l.startswith(name + "@") for l in spawned), \
            "%s spawned with the map; the panel is the default now" % name

    # the toggle and its button are gone, art included
    for gone in ("function rttToggleTurnPanel", "function rttSpawnOldClock"):
        assert gone not in src, "%s is back; the panel is the only clock now" % gone
    x = json.load(open(os.path.join(REPO, "dist/Root_Tabletop_Tournament.json"),
                       encoding="utf-8"))["ObjectStates"]
    def walk(objs):
        for o in objs:
            yield o
            for c in (o.get("ContainedObjects") or []): yield from walk([c])
    board = [o for o in walk(x) if o.get("GUID") == "bab7e1"][0]
    assert "rttToggleTurnPanel" not in board["XmlUI"], "a button still calls the toggle"
    assert not any(a["Name"] == "TurnPanelLabel" for a in board["CustomUIAssets"]), \
        "the removed button's label art is still registered"

    # and the panel object itself is sound
    head = "RTT_TURN_PANEL_JSON = [====["
    i = src.index(head); j = src.index("]====]", i)
    blob = json.loads(src[i + len(head):j])
    assert blob["Nickname"] == "Turn Panel"
    assert blob["Locked"] is True
    for fn in ("panelStart", "panelDeal", "rttResetAndStart", "rttHasData", "rttRound"):
        assert fn in blob["LuaScript"], "the panel script never mentions %s" % fn

    # EVERY FUNCTION THE PANEL CALLS ON THE SHEET MUST EXIST IN THE BUILD. The panel reaches the box
    # score with obj.call(name) inside a pcall, so a missing function fails SILENTLY -- the button just
    # does nothing. That is exactly what happened on 2026-09-07: rttSuppressNextLock was added to
    # boxscore.lua but rebake_into_rtt.py was never run, so the mod shipped without it and the
    # maintainer reported "none of the two bugs have been resolved". The old check only asserted the
    # panel NAMED the function, which was true and useless.
    called = sorted(set(re.findall(r's\.call\("([A-Za-z_][A-Za-z0-9_]*)"', blob["LuaScript"])))
    assert called, "the panel calls nothing on the sheet; this check has stopped checking"
    built = open(os.path.join(REPO, "dist/Root_Tabletop_Tournament.json"),
                 encoding="utf-8", errors="surrogateescape").read()
    for fn in called:
        assert ("function " + fn) in built, (
            "the panel calls %s on the box score, but no such function is in the built save --"
            " root_boxscore was edited without re-running rebake_into_rtt.py" % fn)

    # IT IS RENDERED THE WAY THE BOX SCORE IS: a plain slab carrying an object XmlUI, sized to the UI.
    # Maintainer, 2026-09-07, on the createButton version: "position of numbers inside box, position of
    # buttons inside the swuares, all is still off, needs more precision". Hand-placed widgets over a
    # baked picture cannot be aligned from outside the game -- a layout engine needs no measuring.
    lua = blob["LuaScript"]
    assert blob["Name"] == "BlockSquare", "the panel should be a slab, not a tile: %s" % blob["Name"]
    assert "self.UI.setXml" in lua, "the panel does not render an XmlUI"
    assert "self.createButton(" not in lua, \
        "the panel is back to createButton; that is what could never be aligned"
    assert "VerticalLayout" in lua and "HorizontalLayout" in lua, "no layout elements"
    assert "self.setScale" in lua, "the slab is not sized to its UI (the box score's PX_PER_UNIT rule)"
    assert "setCustomAssets" in lua, "the crafted-border frame is not registered as a UI image"
    # The readout fields use the crafted CARD's own ground (#F9E6BB, measured off the real texture),
    # not the box score's ledger tone -- a design study pointed out the panel was wearing the wrong
    # palette for the object it is imitating. The interactive tones stay the box score's, so the hover
    # and press states match the rest of the mod.
    for hexc in ("#F9E6BB", "#C9A05C", "#E4C88E", "#26170B", "#7E4A1E"):
        assert hexc in lua, "the panel does not use palette entry %s" % hexc

    # the captains board's 3D sides are black like the crafted board's own
    ch = "RTT_CAPTAIN_BOARD_JSON = [==["
    ci = src.index(ch); cj = src.index("]==]", ci)
    cap = json.loads(src[ci + len(ch):cj])
    assert cap["ColorDiffuse"] == {"r": 0.0, "g": 0.0, "b": 0.0}, \
        "the captains board's sides are not black: %s" % cap["ColorDiffuse"]


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
    assert n == 6, "Faction Cards lays %s entries, expected 6 (five decks + the vagabond card)" % n
    # its spot is the maintainer's own, from his save 'faction' (TS_Save_30): a SECOND ROW behind the
    # captains deck, not a fifth along the first row, which is where I had guessed it.
    # TWO entries share the vagabond row now -- the 12-card deck and the single faction card -- so
    # match on the card COUNT, not on z alone
    def entry_at(n_cards):
        return rt.eval("""function(want)
          for _, e in ipairs(RTT_HOOT) do
            local n = 0
            for _ in e.json:gmatch('"CardID":%s*%d+') do n = n + 1 end
            if n == want and math.abs(e.pos[3] - 28.681) < 0.01 then
              return string.format('%.3f,%.3f', e.pos[1], e.pos[3])
            end
          end
          return 'missing'
        end""")(n_cards)
    at = entry_at(12)
    assert at == "50.225,28.681", "the vagabond deck is at %s; his save has 50.225,28.681" % at

    # the VAGABOND FACTION card (CardID 303), to the right of the character deck and in line with the
    # first 6-card faction deck below it. It is on the same sheet as the other faction cards but is in
    # neither 6-card deck, so Faction Cards used to lay out every faction EXCEPT the vagabond.
    card = entry_at(1)
    assert card == "58.220,28.681", "the vagabond faction card is at %s, expected 58.220,28.681" % card
    has303 = rt.eval("""function()
      for _, e in ipairs(RTT_HOOT) do
        if e.json:find('"CardID": 303', 1, true) or e.json:find('"CardID":303', 1, true) then
          return true
        end
      end
      return false
    end""")()
    assert has303 is True, "CardID 303 is not in RTT_HOOT at all"

    # it is the CHARACTER deck: twelve cards, the vagabond CardIDs. Matched by count as well as z,
    # because the vagabond faction card now shares that row.
    ok = rt.eval("""function()
      for _, e in ipairs(RTT_HOOT) do
        local n = 0
        for _ in e.json:gmatch('"CardID"') do n = n + 1 end
        if n == 12 and math.abs(e.pos[3] - 28.681) < 0.01 then return n end
      end
      return -1
    end""")()
    assert ok == 12, "no twelve-card deck on the vagabond row (got %s)" % ok

    # and the button is gone, with its art
    rt.execute("XML = ''")
    assert 'id="Vagabond Cards"' not in src, "the makeTool button is still declared"
    assert '{name = "Vagabond Cards"' not in src, "the button art is still registered"


def t_the_two_free_button_slots_are_bottom_right(src):
    """Where the spare option slots sit, and who sits where.

    Maintainer, 2026-09-05: "the two empty button option should be in the second row to the right".
    Then 2026-09-07, with the turn panel: "put the credits option button to the bottom right replace
    the position with the faction cards button. the new option button for the new clock/counter should
    be second row to the leftmost."

    So Credits went to the bottom-right slot and Faction Cards took the spot it left in the FIRST row.
    The Turn Panel toggle held x=19 of row two until "remove the button turn panel" (2026-09-07); with
    it gone, row two has TWO spare slots, 19 and 57, with Credits still anchored at 95.

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
    assert free == [19, 57], "the free slots are at %s; 19 and 57 of row 2 should be spare" % free
    assert top.get(57) == "Faction Cards", "x=57 of row 1 holds %r, not Faction Cards" % top.get(57)
    assert bottom.get(95) == "rttCreditsBtn", "the bottom-right slot holds %r, not Credits" % bottom.get(95)


def t_captain_warriors_line_up_with_their_captains(src):
    """Maintainer, 2026-09-05: the warrior spawned by the captain board is a bit misaligned.

    The two rows were measured off his save separately and came out with different starts AND
    different steps -- meeples -0.551 step 0.272, warriors -0.510 step 0.250 -- so each warrior sat
    beside its own captain rather than under it, by a different amount per column: +0.36 world units
    under the first, +0.17 under the second, -0.03 under the third.

    Records EVERY spawn, not just the last. rttSpawnCaptainMeeple calls rttSpawnCaptainWarrior
    itself, so the first version of this test -- which kept only the most recent position -- was
    comparing the warrior against the warrior, and passed on the broken code as happily as the fixed.
    """
    rt = fresh(src)
    rt.execute("""
      SPAWNS = {}
      local _s = spawnObjectJSON
      spawnObjectJSON = function(p)
        local j = (p or {}).json or ''
        local pos = (p or {}).position
        local x = pos and (pos.x or pos[1]) or nil
        local what = j:find('Knaves Warrior', 1, true) and 'W' or 'C'
        if x then SPAWNS[#SPAWNS+1] = what .. '|' .. x end
        return _s(p)
      end
      local kb = MKOBJ('KB', {0, 0, 0}, {})   -- identity transform: local numbers come straight back
      RTT_CAP_KNAVE_GUID = kb.getGUID()
      RTT_CAP_MEEPLE_JSON = { X = '{"Nickname": "Captain - X"}' }
      RTT_CAP_WARRIOR_JSON = '{"Nickname": "Knaves Warrior"}'
      RTT_CAP_WARRIOR_N = 0
      for idx = 0, 2 do rttSpawnCaptainMeeple('X', idx) end
    """)
    rows = [str(v) for v in (rt.eval("SPAWNS") or {}).values()]
    caps = [float(r.split("|")[1]) for r in rows if r.startswith("C|")]
    wars = [float(r.split("|")[1]) for r in rows if r.startswith("W|")]
    assert len(caps) == 3, "expected 3 captain meeples, got %d (%s)" % (len(caps), rows)
    assert len(wars) == 3, "expected 3 warriors, got %d (%s)" % (len(wars), rows)
    for i, (c, w) in enumerate(zip(caps, wars)):
        assert abs(w - c) < 1e-6, \
            "column %d: warrior at x %.4f under a captain at %.4f (off by %.3f world units)" \
            % (i, w, c, (w - c) * 8.82)


def t_five_player_marsh_ruins_stay_central(src):
    """Maintainer, 2026-09-06: on 5P Marsh the ruins must spawn only in the central clearings,
    never the ones at the edge -- clearings 6, 7, 9 and 10.

    The planner used to offer SIX slots (2 fixed plus all four pair spots) and deal four ruins across
    them, so two a game landed on the rim. The rim pair is marker C's: C.up is clearing 3 at the top
    edge, C.down is clearing 14 at the bottom. Marker B's pair is 7 and 10, both inland, and the two
    fixed spots are 6 and 9 -- exactly four slots for four ruins.

    NOTE THE NUMBERING. Clearing numbers are RTT_MARSH_RANK's, which is the printed 1-15 order.
    RTT_CLEARING_CENTRES["Marsh Map"] is a DIFFERENT order, and reading clearing numbers off it is how
    this was first mis-read -- so the test pins the four WORLD positions, which are unambiguous.
    """
    WANT = {"4.4,7.1", "-4.0,-2.4", "14.3,3.7", "6.2,-6.7"}     # clearings 6, 9, 7, 10
    RIM  = {"8.1,15.4", "0.5,-19.3"}                            # clearings 3 and 14
    rt = fresh(src)
    seen = set()
    for t in range(120):
        rt.execute("math.randomseed(%d)" % (t + 1))
        out = rt.eval("""function()
          local objs = EVERYTHING['Maps']['Marsh Map']['data']
          local ov = rttMarshPlan5P(objs)
          local t = {}
          for idx, v in ipairs(objs) do
            if v.json:find('RUIN', 1, true) and ov[idx] and ov[idx].world then
              t[#t+1] = string.format('%.1f,%.1f', ov[idx].world[1], ov[idx].world[3])
            end
          end
          table.sort(t) return table.concat(t, ';')
        end""")()
        got = set(out.split(";"))
        assert len(got) == 4, "a deal placed %d distinct ruin positions: %s" % (len(got), sorted(got))
        assert not (got & RIM), "a ruin landed on a rim clearing: %s" % sorted(got & RIM)
        assert got == WANT, "a deal used %s, expected the four central slots" % sorted(got)
        seen |= got
    assert seen == WANT, "over 120 deals the ruins used %s" % sorted(seen)

    # the FLOODING Marsh is deliberately untouched: there only two pair spots are ever dry
    rt.execute("math.randomseed(7)")
    n = rt.eval("""function()
      local objs = EVERYTHING['Maps']['Marsh Map']['data']
      local ov = rttMarshPlan(objs)
      local n = 0
      for idx, v in ipairs(objs) do
        if v.json:find('RUIN', 1, true) and ov[idx] and ov[idx].world then n = n + 1 end
      end
      return n
    end""")()
    assert n == 4, "the flooding Marsh should still place 4 ruins, it placed %s" % n


def t_a_map_click_leaves_five_player_mode(src):
    """Maintainer, 2026-09-06: after 5-Players Marsh, clicking Marsh with 4 players gave no flooded
    clearings and left the landmarks.

    RTT_5P_MARSH is the 5-player Marsh variant's mode flag. It was SET by its two entry points and
    cleared in exactly ONE place -- inside rttSetup, the ranked-draft path -- so a plain map click
    never reset it and rttMarshPlan5P ran instead of rttMarshPlan: no flooding, towns placed.

    The flag did TWO jobs with different lifetimes ("this placement is the 5-player variant" and
    "this game is a 5-player Marsh game"), which is why no single clear point was right for both. A
    human clicking a map button ends the second one, so that is where it clears; the internal path
    (rttPlaceMap -> makeMap("", "", id)) passes no player and keeps it.
    """
    rt = fresh(src)
    rt.execute("SEAT('Red')")

    # the maintainer's sequence
    rt.execute("pcall(function() rttPlaceMarsh5P(nil,nil,'Marsh5PMap') end) FLUSH(40)")
    assert rt.eval("RTT_5P_MARSH") is True, "5-Players Marsh did not enter 5-player mode"
    rt.execute("pcall(function() makeMap(Player['Red'], '', 'Marsh Map') end) FLUSH(40)")
    assert rt.eval("RTT_5P_MARSH") is False, \
        "clicking Marsh left 5-player mode on -- no flooding, and the towns stay"

    # ANY map click clears it, not just Marsh: the flag used to survive across every other map too
    for m in ("Summer Map", "Lake Map", "Winter Map", "Mountain Map", "Gorge Map"):
        rt.execute("pcall(function() rttPlaceMarsh5P(nil,nil,'Marsh5PMap') end) FLUSH(20)")
        assert rt.eval("RTT_5P_MARSH") is True
        rt.execute("pcall(function() makeMap(Player['Red'], '', [[%s]]) end) FLUSH(30)" % m)
        assert rt.eval("RTT_5P_MARSH") is False, "%s did not clear 5-player mode" % m

    # ...and the 5-player path itself must still keep it, or it would break its own map
    rt.execute("pcall(function() rttPlaceMarsh5P(nil,nil,'Marsh5PMap') end) FLUSH(40)")
    assert rt.eval("RTT_5P_MARSH") is True, \
        "the 5-player button cleared its own flag -- it places its map through the same makeMap"


def t_clear_all_resets_run_state(src):
    """Clear All destroyed objects and reset NOTHING, which was the root of three separate bugs.

    It is base-mod code. Found by the 2026-09-06 audit after the maintainer asked whether the sticky
    RTT_5P_MARSH flag pointed at something wider -- it did.

      * RTT_FAC_TAKEN survived, so a faction picked before a Clear All was PERMANENTLY unpickable:
        "Marquise de Cat is already in play." on a completely empty table, forever.
      * RTT_PRIO_MAP survived while its markers were destroyed, so re-clicking the SAME map spawned
        no clearing-priority markers at all -- rttSpawnPriority's same-map guard returned first.
      * the seat record and the published Globals survived, so the gizmo and the box score kept
        answering for a game that no longer existed.

    Clear All now calls rttResetRunState -- the ONE list of everything a new game resets that is not
    an object -- rather than growing its own copy of it.
    """
    rt = fresh(src)
    rt.execute("SEAT('Purple','H1') pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(10)")
    rt.execute("""RTT_FAC_TAKEN['Marquise de Cat'] = true
                  RTT_PRIO_MAP = 'Summer Map'
                  RTT_DRAFT_FACTIONS = {'Knaves of the Deepwood'}
                  Global.setVar('RTT_SEAT_COLOR', '{"Marquise de Cat":"Purple"}')""")
    rt.execute("pcall(function() clearAll() end) FLUSH(8)")
    assert not rt.eval("RTT_FAC_TAKEN['Marquise de Cat']"), \
        "a faction picked before Clear All is still 'already in play' on an empty table"
    assert rt.eval("RTT_PRIO_MAP") is None, \
        "RTT_PRIO_MAP survived Clear All -- the same map re-clicked spawns no priority markers"
    assert rt.eval("#RTT_DRAFT_FACTIONS") == 0, "the last draft's faction list survived Clear All"
    assert rt.eval("GVGET('RTT_SEAT_COLOR')") == "{}", "the published seat map survived Clear All"


def t_destroying_priority_markers_forgets_their_map(src):
    """RTT_PRIO_MAP means "which map's markers are ON THE TABLE", so destroying them ends its life.

    rttSpawnPriority skips re-spawning when the map has not changed -- that is what stops the markers
    flickering on a same-map re-click. Leaving the flag set after the objects are gone turned that
    optimisation into "never spawn them again".
    """
    rt = fresh(src)
    rt.execute("RTT_PRIO_MAP = 'Summer Map' rttClearPriority()")
    assert rt.eval("RTT_PRIO_MAP") is None, "clearing the markers left the flag pointing at their map"
    assert rt.eval("#RTT_PRIO_PIECES") == 0


def t_the_manual_path_records_its_seat_count(src):
    """RTT_DN was written only by the ranked draft, so a manual game inherited the last draft's size.

    5P Draft then 4-Player Setup gave a box score pre-formatted for FIVE rows in a four-player game;
    5P Setup from a cold table gave four rows for five players. It means "cards this draft dealt" =
    seats + 1, which rttSpawnBoxScore republishes as RTT_BOXSCORE_MIN.
    """
    rt = fresh(src)
    rt.execute("RTT_DN = 6")                       # as a 5-player draft would leave it
    rt.execute("pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(10)")
    assert rt.eval("RTT_DN") == 5, "a 4-player manual game reports %s seats+1" % rt.eval("RTT_DN")
    rt.execute("pcall(function() setupFactionBoards(nil,nil,'fivePlayerSetup') end) FLUSH(10)")
    assert rt.eval("RTT_DN") == 6, "a 5-player manual game reports %s seats+1" % rt.eval("RTT_DN")


def t_a_map_click_is_swallowed_while_busy(src):
    """RTT_BUSY was consulted only in rttArmOrGo, so the map buttons ignored it.

    Clicking Marsh during the 5-player draft's 6-10s chain landed that game on the FOUR-player board:
    rttFivePStart sets RTT_5P_MARSH at t=0, but its map is not placed until rttBeginPick seconds
    later, and the stray click cleared the flag in between. The internal path (rttPlaceMap) passes no
    player and is never blocked -- otherwise the draft could not place its own map.
    """
    rt = fresh(src)
    rt.execute("SEAT('Red') RTT_BUSY = true")
    rt.execute("pcall(function() makeMap(Player['Red'], '', 'Summer Map') end) FLUSH(6)")
    assert rt.eval("RTT_CURRENT_MAP") is None, "a human map click ran while a setup was loading"
    rt.execute("pcall(function() rttPlaceMap('Summer Map') end) FLUSH(6)")
    assert rt.eval("RTT_CURRENT_MAP") == "Summer Map", \
        "the busy guard also blocked the INTERNAL path, which would break the draft's own map"


def t_deferred_map_hooks_carry_a_generation(src):
    """A second map click inside a deferred hook's window used to leave two hooks in flight.

    Two 5-Players Marsh clicks 1.4s apart gave TWO of every town landmark. RTT_RUN_ID cannot cover
    this -- it bumps on a new GAME and a map click is not one -- so the map build has its own counter.
    """
    rt = fresh(src)
    rt.execute("SEAT('Red')")
    before = rt.eval("RTT_MAP_GEN")
    rt.execute("pcall(function() makeMap(Player['Red'], '', 'Summer Map') end) FLUSH(4)")
    mid = rt.eval("RTT_MAP_GEN")
    assert mid == before + 1, "a map build did not bump the generation (%s -> %s)" % (before, mid)
    rt.execute("pcall(function() makeMap(Player['Red'], '', 'Lake Map') end) FLUSH(4)")
    assert rt.eval("RTT_MAP_GEN") == mid + 1, "the second build did not bump it again"


def t_a_stale_show_factions_cannot_unlock_the_next_game(src):
    """rttShowFactions clears RTT_BUSY, and a copy left in flight by the PREVIOUS game was clearing
    the NEXT game's latch mid-setup -- so a second destructive click started a second setup on top of
    the first, whose chain then died at its next run-id check.
    """
    # the CALL SITE has to be the guarded one. An earlier version of this test called rttAfterFrames
    # itself, which of course passed on the broken code too -- it was exercising the helper, not
    # rttCoordFaction's scheduling of it.
    i = src.index("function rttCoordFaction(")
    body = src[i:src.index("\nend", i)]
    assert "rttAfterFrames(function() rttShowFactions() end" in body, \
        "rttCoordFaction still schedules rttShowFactions with a bare Wait -- a copy left in flight by " \
        "the previous game will clear the next game's RTT_BUSY mid-setup"
    assert "Wait.frames(function() rttShowFactions() end" not in body, \
        "rttCoordFaction still has an unguarded Wait.frames to rttShowFactions"

    # and the guard really does swallow a stale call
    rt = fresh(src)
    rt.execute("RTT_BUSY = true rttAfterFrames(function() rttShowFactions() end, 10)")
    rt.execute("RTT_RUN_ID = RTT_RUN_ID + 1")      # a new game starts before it fires
    rt.execute("FLUSH(20)")
    assert rt.eval("RTT_BUSY") is True, \
        "a stale rttShowFactions unlocked the next game's buttons while it was still setting up"


def t_map_buttons_warn_before_wiping(src):
    """Maintainer, 2026-09-06: map buttons should warn like the faction buttons -- "This will reset
    the current map."

    They are destructive and used to act on a single click: makeMap clears everything tagged
    "Map Object" -- the map, the battle mat, the priority markers, the timer, the counter, the box
    score -- and on the Marsh re-rolls the flood and the suits.

    Same mechanism as the setup buttons: first click swaps the art to the red warning and starts a 3s
    auto-revert, second click within that window commits, and a clean table is placed with no prompt
    at all.

    The commit carries the CLICKING PLAYER through. makeMap swallows clicks while busy and clears
    RTT_5P_MARSH only for a human click, so committing with nil would have kept 5-player mode alive
    through a map change -- the bug fixed earlier the same day, reintroduced by its own fix.
    """
    MAPS = ["Summer Map", "Lake Map", "Marsh Map", "Winter Map", "Mountain Map", "Gorge Map"]

    # every map button is armed, and they all use the map warning art
    rt = fresh(src)
    for m in MAPS:
        d = rt.eval("function(k) local e = RTT_WIPE_BTN[k] if e == nil then return 'missing' end "
                    "return tostring(e.map) .. '|' .. tostring(e.warn) end")(m)
        assert d == "%s|WipeConfirmMapArt" % m, "%s has wipe entry %s" % (m, d)
    assert 'id="Vagabond Cards"' not in src   # unrelated guard kept from the button sweep

    # a CLEAN table places at once -- the first map of a session must not need two clicks
    rt = fresh(src)
    rt.execute("SEAT('Red')")
    rt.execute("pcall(function() rttArmMap(Player['Red'],'','Summer Map') end) FLUSH(20)")
    assert rt.eval("RTT_CURRENT_MAP") == "Summer Map", "the first map click did not place a map"
    assert rt.eval("RTT_ARM.id") is None, "it armed instead of placing on a clean table"

    # with a map down, the first click ARMS and changes nothing
    rt.execute("pcall(function() rttArmMap(Player['Red'],'','Lake Map') end) FLUSH_UNTIL(0.5)")
    assert rt.eval("RTT_ARM.id") == "Lake Map", "a second map click did not arm"
    assert rt.eval("UIATTR['Lake Map.icon']") == "WipeConfirmMapArt", "the art did not become the warning"
    assert rt.eval("UIATTR['Lake Map.color']") == "#a83226", "the button did not go red"
    assert rt.eval("RTT_CURRENT_MAP") == "Summer Map", "the map changed on the FIRST click"

    # the second click commits
    rt.execute("pcall(function() rttArmMap(Player['Red'],'','Lake Map') end) FLUSH(20)")
    assert rt.eval("RTT_CURRENT_MAP") == "Lake Map", "the second click did not place the map"
    assert rt.eval("RTT_ARM.id") is None, "it stayed armed after committing"

    # left alone, it reverts
    rt.execute("pcall(function() rttArmMap(Player['Red'],'','Gorge Map') end) FLUSH_UNTIL(0.5)")
    assert rt.eval("RTT_ARM.id") == "Gorge Map"
    rt.execute("FLUSH(20)")
    assert rt.eval("RTT_ARM.id") is None, "an armed map button never reverted"
    assert rt.eval("UIATTR['Gorge Map.icon']") == "Gorge Map", "the art did not revert"

    # AND an armed commit is still a human click
    rt = fresh(src)
    rt.execute("SEAT('Red') pcall(function() rttPlaceMarsh5P(nil,nil,'Marsh5PMap') end) FLUSH(30)")
    assert rt.eval("RTT_5P_MARSH") is True
    rt.execute("pcall(function() rttArmMap(Player['Red'],'','Summer Map') end) FLUSH_UNTIL(0.5)")
    rt.execute("pcall(function() rttArmMap(Player['Red'],'','Summer Map') end) FLUSH(20)")
    assert rt.eval("RTT_CURRENT_MAP") == "Summer Map", "the armed commit did not place the map"
    assert rt.eval("RTT_5P_MARSH") is False, \
        "an armed map commit left 5-player mode on -- it must reach makeMap as a HUMAN click"


def t_maps_shuffle_once_and_uniformly(src):
    """shuffleMaps repeated its shuffles, which buys nothing.

    shuffle() is a correct Fisher-Yates, so ONE pass is already a uniform permutation and composing
    thirty of them just gives another uniform permutation -- the ruins line ran 30 passes and 29 were
    wasted work on every map build.

    The clearing-marker line was stranger: `i=1,10 do ... end` with no `for`, which Lua parses as the
    assignment `i = 1, 10` (the 10 discarded) followed by a bare do-block. It shuffled exactly ONCE --
    the right number -- by accident, and leaked a global `i`. Writing it properly was the fix; adding
    the missing `for` was NOT, since that would have turned an accidentally-correct line into a
    genuinely wasteful one to match its neighbour.

    Behaviour is distribution-neutral, not sequence-identical: dropping 29 calls changes how many
    random numbers are drawn, so a given seed yields different specific boards with the same odds.
    """
    # the loops are gone, and the missing `for` was not "restored"
    assert "for i=1,30 do ruins = shuffle(ruins) end" not in src, "the 30x ruins loop is still there"
    assert "i=1,10 do clearingMarkers" not in src, "the malformed marker line is still there"
    assert "for i=1,10 do clearingMarkers" not in src, \
        "the missing `for` was added -- that makes an accidentally-correct line wasteful"
    assert "ruins = shuffle(ruins)" in src and "clearingMarkers = shuffle(clearingMarkers)" in src

    rt = fresh(src)
    # shuffle() itself is uniform: every element reaches position 1 equally often
    got = rt.eval("""function(n)
      math.randomseed(20260906)
      local hits = {}
      for _ = 1, n do
        local t = {}
        for k = 1, 12 do t[k] = k end
        t = shuffle(t)
        hits[t[1]] = (hits[t[1]] or 0) + 1
      end
      local out = {}
      for k = 1, 12 do out[#out+1] = tostring(hits[k] or 0) end
      return table.concat(out, ',')
    end""")(4800)
    counts = [int(v) for v in got.split(",")]
    assert len(counts) == 12 and sum(counts) == 4800
    exp = 4800 / 12
    chi = sum((c - exp) ** 2 / exp for c in counts)
    assert chi < 19.68, "shuffle() is not uniform: chi-square %.2f on 11 df (5%% critical 19.68)" % chi

    # and it really is a permutation, not a partial one
    same = rt.eval("""function()
      local t = {}
      for k = 1, 20 do t[k] = k end
      t = shuffle(t)
      local seen = {}
      for _, v in ipairs(t) do seen[v] = true end
      local n = 0
      for _ in pairs(seen) do n = n + 1 end
      return n
    end""")()
    assert same == 20, "shuffle() lost or duplicated elements (%s of 20 survived)" % same


def t_send_home_fills_the_rightmost_empty_slot(src):
    """Maintainer, 2026-09-06: a returning piece goes to the RIGHTMOST EMPTY slot of its kind, not
    back to its own spot -- roosts, enclaves, strongholds, the moles' buildings.

    Slots come from RTT_HOME, recorded as each piece spawns, so they describe the table that actually
    exists rather than a hand-kept list that could drift from the blueprints.

    DIRECTION IS UNCONFIRMED. Board-local +x is the player's right on one row and their left on the
    other, because faction boards carry rotY ~180 and the far row mirrors it. He is checking at the
    table; this asserts the ORDERING BEHAVIOUR against whatever RTT_HOME_RIGHT_IS_PLUS_X says, so
    flipping that one constant flips the test with it and nothing else has to change.
    """
    rt = fresh(src)
    # six Roost slots in a row, plus the parked odd one far away that he has not specified yet
    rt.execute("""
      RTT_HOME = {}
      local xs = {3.74, 5.34, 6.92, 8.49, 10.12, 11.72}
      for i, x in ipairs(xs) do
        RTT_HOME['r'..i] = { n = 'Roost', f = 'Eyrie Dynasties',
                             p = { x, 0.2, -4.35 }, r = { 0, 0, 0 } }
      end
      RTT_HOME['odd'] = { n = 'Roost', f = 'Eyrie Dynasties', p = { -17.54, 0.1, 5.76 }, r = {0,0,0} }
    """)
    slots = rt.eval("""function()
      local t = {}
      for _, s in ipairs(rttHomeSlots('Roost')) do t[#t+1] = string.format('%.2f', s.p[1]) end
      return table.concat(t, ',')
    end""")()
    xs = [float(v) for v in slots.split(",")]
    assert len(xs) == 6, "the parked outlier was not excluded: %d slots" % len(xs)
    assert -17.54 not in xs, "the parked outlier is in the fill order; he asked for it to be skipped"
    plus = rt.eval("RTT_HOME_RIGHT_IS_PLUS_X")
    want = sorted(xs, reverse=bool(plus))
    assert xs == want, "slots are not ordered right-to-left for RIGHT_IS_PLUS_X=%s: %s" % (plus, xs)

    # a returning Roost takes the first FREE slot, not its own
    rt.execute("""
      OCC = MKOBJ('Roost', {%f, 0.2, -4.35}, {})     -- the preferred slot is already taken
      MOVER = MKOBJ('Roost', {40, 5, 40}, {})
      -- SEATED as the birds: since 2026-09-07 numpad 0 only moves your own faction's pieces, so a
      -- Roost cannot be sent home by nobody.
      Global.setVar("RTT_SEAT_COLOR", JSON.encode({ ["Eyrie Dynasties"] = "Red" }))
      HOVER['Red'] = MOVER
      rttGizmoHome('Red')
    """ % xs[0])
    at = rt.eval("function() return string.format('%.2f', MOVER.__pos.x) end")()
    assert abs(float(at) - xs[1]) < 0.01, \
        "a returning Roost went to %s; the first free slot is %.2f" % (at, xs[1])

    # a Tunnel goes to its OWN spot -- no row to fill
    rt.execute("""
      RTT_HOME = {}
      T = MKOBJ('Tunnel', {40, 5, 40}, {})
      RTT_HOME[T.getGUID()] = { n='Tunnel', f='Underground Duchy', p={10.04,0.1,6.91}, r={0,0,0} }
      RTT_HOME['t2'] = { n='Tunnel', f='Underground Duchy', p={9.97,0.1,5.24}, r={0,0,0} }
      Global.setVar("RTT_SEAT_COLOR", JSON.encode({ ["Underground Duchy"] = "Red" }))
      HOVER['Red'] = T
      rttGizmoHome('Red')
    """)
    at = rt.eval("function() return string.format('%.2f,%.2f', T.__pos.x, T.__pos.z) end")()
    assert at == "10.04,6.91", "a Tunnel should return to its own spot, it went to %s" % at

    # Acclaim fills stack by stack, two per stack, bottom row before top
    rt.execute("""
      RTT_HOME = {}
      local i = 0
      for _, z in ipairs({-4.43, -2.54}) do
        for _, x in ipairs({7.19, 5.26}) do
          for _, y in ipairs({0.3, 0.4}) do
            i = i + 1
            RTT_HOME['a'..i] = { n='Acclaim', f='Knaves of the Deepwood', p={x,y,z}, r={0,0,0} }
          end
        end
      end
      Global.setVar("RTT_SEAT_COLOR", JSON.encode({ ["Knaves of the Deepwood"] = "Red" }))
    """)
    order = rt.eval("""function()
      local t = {}
      for _, s in ipairs(rttHomeSlots('Acclaim')) do
        t[#t+1] = string.format('%.2f/%.2f', s.p[1], s.p[3])
      end
      return table.concat(t, ' ')
    end""")().split()
    assert len(order) == 8, "expected 8 Acclaim slots, got %d" % len(order)
    zs = [p.split("/")[1] for p in order]
    assert zs[:4] == ["-4.43"] * 4 and zs[4:] == ["-2.54"] * 4, \
        "Acclaim did not fill one z-row fully before the other: %s" % order
    assert order[0] == order[1] and order[2] == order[3], \
        "Acclaim did not fill two per stack before moving on: %s" % order
    # AND a stack really fills to two. Maintainer, 2026-09-06: "when two stacks of 2 are empty, you
    # put 1 in the empty stack then the one after you put it in the other empty stack instead of
    # filling all stacks with 2 first." Cause: the two slots of a stack differ only in HEIGHT, by 0.1,
    # and the occupancy test used a fixed 0.6 vertical tolerance -- so the piece in the lower slot made
    # the upper one read as taken. The tolerance is now half the smallest height step.
    first = order[0].split("/")
    rt.execute("LOWER = MKOBJ('Acclaim', {%s, 0.3, %s}, {}) "
               "A = MKOBJ('Acclaim', {40, 5, 40}, {}) "
               "HOVER['Red'] = A rttGizmoHome('Red')" % (first[0], first[1]))
    at = rt.eval("function() return string.format('%.2f/%.2f/%.2f', A.__pos.x, A.__pos.y, A.__pos.z) end")()
    want = "%.2f/0.40/%.2f" % (float(first[0]), float(first[1]))
    assert at == want, \
        "the second acclaim went to %s; it should COMPLETE the first stack at %s" % (at, want)

    # and the rotation follows the SLOT, so a piece never comes home a half-turn out. RTT_HOME is
    # recorded after spawnRy is applied, which is 180 on a far-row seat.
    rt.execute("RTT_HOME = {} "
               "Global.setVar('RTT_SEAT_COLOR', JSON.encode({ ['Eyrie Dynasties'] = 'Red' })) "
               "RTT_HOME['s1'] = { n='Roost', f='Eyrie Dynasties', p={3.0,0.2,-4.35}, r={0,180,0} } "
               "R = MKOBJ('Roost', {40,5,40}, {}) "
               "HOVER['Red'] = R rttGizmoHome('Red')")
    ry = rt.eval("function() return string.format('%.0f', R.__rot.y) end")()
    assert ry == "180", "a returning piece kept its own facing (%s) instead of the slot's 180" % ry



def t_return_slots_are_not_spawn_positions(src):
    """The maintainer gave positions for the gizmo to RETURN pieces to, NOT to change where they spawn.

    His words, after I did change them: "I gave you the position so you know where to return the
    buildings and tokens with gizmo option but did not tell you to change the spawning dispositions !!!
    restore the spawning !!!"

    So the blueprint still parks the odd piece where it always did -- a roost at move_to -17.54 against
    a row at 3.74..11.72 -- and RTT_HOME_EXTRA carries the row position it should RETURN to. This
    asserts BOTH halves, because passing one and failing the other is exactly what happened.

    The rats are the one deliberate exception: he asked for their sixth stronghold to join the row
    outright, so that IS a blueprint change, with the supply, warlord and four warriors shifted 1.4 to
    clear it.
    """
    rt = fresh(src)
    rt.execute("SEAT('Purple','H1') pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(10)")
    rt.execute("RTT_HOME = {} SPAWNED = {}")
    rt.execute("local _s = spawnObjectJSON "
               "spawnObjectJSON = function(p) local o = _s(p) "
               "  local n = o.getName() or '' "
               "  SPAWNED[n] = SPAWNED[n] or {} "
               "  SPAWNED[n][#SPAWNED[n]+1] = o.__pos.x - 52 "
               "  return o end")
    rt.execute("""pcall(function() rttPlaceFaction('Eyrie Dynasties', 52, -46, false, 'Purple',
                        false, nil, nil, 'Purple', nil) end) FLUSH(40)""")
    spawned = sorted(float(v) for v in rt.eval("SPAWNED")["Roost"].values())
    assert any(abs(v + 17.54) < 0.1 for v in spawned), \
        "the parked roost no longer SPAWNS at -17.54; the blueprint was changed: %s" % spawned

    slots = rt.eval("""function()
      local t = {}
      for _, s in ipairs(rttHomeSlots('Roost')) do t[#t+1] = string.format('%.2f', s.p[1] - 52) end
      return table.concat(t, ',')
    end""")()
    xs = [float(v) for v in slots.split(",")]
    assert len(xs) == 7, "expected 7 roost return slots, got %d: %s" % (len(xs), xs)
    assert not any(abs(v + 17.54) < 0.1 for v in xs), \
        "the parked spot is still a RETURN slot; it should be the row position instead: %s" % xs
    assert abs(min(xs) - 2.14) < 0.05, "the extra return slot is not at 2.14: %s" % xs
    assert xs == sorted(xs, reverse=True), "return slots are not ordered rightmost-first: %s" % xs

    # the rats ARE changed, deliberately: six strongholds in one evenly spaced row
    rt = fresh(src)
    rt.execute("SEAT('Purple','H1') pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(10)")
    rt.execute("RTT_HOME = {}")
    rt.execute("""pcall(function() rttPlaceFaction('Lord of the Hundreds', 52, -46, false, 'Purple',
                        false, nil, nil, 'Purple', nil) end) FLUSH(40)""")
    got = rt.eval("""function()
      local t = {}
      for _, h in pairs(RTT_HOME) do
        if h.n == 'Stronghold' then t[#t+1] = h.p[1] - 52 end
      end
      table.sort(t)
      local o = {}
      for _, v in ipairs(t) do o[#o+1] = string.format('%.3f', v) end
      return table.concat(o, ',')
    end""")()
    xs = sorted(float(v) for v in got.split(","))
    assert len(xs) == 6, "expected 6 strongholds, got %d" % len(xs)
    gaps = [round(xs[i + 1] - xs[i], 2) for i in range(5)]
    assert all(abs(g - 1.41) < 0.02 for g in gaps), \
        "the stronghold row is not evenly spaced after the move: %s" % gaps


def t_extra_return_slots_face_the_same_way(src):
    """An extra return slot must face the way the pieces of that name ACTUALLY landed.

    An extra slot has no piece of its own, so it copies the facing from a real one. That copy used to
    run straight after the spawn LOOP -- which only asks for the pieces; their callbacks, the one place
    a real facing is known, run a frame later. So it always read an empty RTT_HOME and fell back to a
    flat 180. The gardens' own blueprint facing is already 180, so that was right by luck on a near-row
    seat -- and a half turn out on every FAR-row one, where spawnRy adds 180 and they land at 0.

    Maintainer, 2026-09-06: "some gardens still return upside down with gizmo 0; I think it s only the
    first ones" -- the first, because the extra slot sorts ahead of the spawned ones, so it is the
    first slot the gizmo fills. And: "its the same for each carboard ... the other gardens rotate
    properly", which is the whole assertion here: extra and spawned must agree.

    Checked on BOTH seats, because the old fallback happened to be right on one of them.
    """
    for cz, flip, where in ((-46, False, "near row"), (46, True, "far row")):
        rt = fresh(src)
        rt.execute("SEAT('Purple','H1') pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(10)")
        rt.execute("RTT_HOME = {}")
        rt.execute("pcall(function() rttPlaceFaction('The Lizard Cult', 52, %d, %s, 'Purple', "
                   "false, nil, nil, 'Purple', nil) end) FLUSH(40)" % (cz, "true" if flip else "false"))
        got = rt.eval("function()\n"
                      "  local t = {}\n"
                      "  for k, h in pairs(RTT_HOME) do\n"
                      "    if string.find(h.n or '', 'Garden', 1, true) then\n"
                      "      local extra = (string.sub(k, 1, 1) == 'x') and 'extra' or 'spawn'\n"
                      "      t[#t+1] = h.n .. '|' .. extra .. '|' .. string.format('%.1f', h.r[2])\n"
                      "    end\n"
                      "  end\n"
                      "  table.sort(t)\n"
                      "  return table.concat(t, ',')\n"
                      "end")()
        assert got, "no garden slots recorded at all on the %s" % where
        spawn, extra = {}, {}
        for row in got.split(","):
            name, kind, ry = row.split("|")
            (extra if kind == "extra" else spawn).setdefault(name, set()).add(float(ry))
        assert extra, "no EXTRA garden return slot was recorded on the %s: %s" % (where, got)
        for name, rys in sorted(extra.items()):
            assert len(rys) == 1, "%s: extra slot has more than one facing: %s" % (name, rys)
            assert name in spawn, "%s: an extra slot but no spawned piece to copy from" % name
            # Physics settles a tile a tenth of a degree either way, so the spawned pieces are only
            # required to AGREE, not to be identical; a half turn is 180 and cannot hide in that.
            got_spawn = sorted(spawn[name])
            assert got_spawn[-1] - got_spawn[0] < 1.0, \
                "%s: the spawned pieces disagree on facing, so the test cannot judge: %s" % (name, got_spawn)
            want, have = got_spawn[0], rys.pop()
            assert abs(((want - have + 180) % 360) - 180) < 1.0, \
                "%s on the %s: the extra return slot faces %.1f but the gardens landed at %.1f -- " \
                "sent home it would be a half turn out" % (name, where, have, want)


def t_marsh_after_5p_marsh_rebuilds_the_4p_board(src):
    """The OUTCOME, not just the flag: after 5-Players Marsh, a plain Marsh click must flood and must
    take the town landmarks away.

    Maintainer, 2026-09-06, reporting it a SECOND time: "spawning marsh 4 players after marsh 5
    players still does not span the flooded clearings properly and keep the landmarks."

    The first fix was real but t_a_map_click_leaves_five_player_mode only asserted RTT_5P_MARSH went
    false. A flag is not a board. This drives it through rttArmMap -- the button the maintainer
    actually presses, which needs TWO clicks since the wipe warning went in -- and then looks at what
    is on the table.

    FLUSH_UNTIL, not FLUSH, between the two clicks: FLUSH fires every pending callback whatever its
    delay, so the arm's own 3-second auto-revert goes off before the second click arrives and the
    commit silently becomes another arm. That cost me a false "the button path does nothing".
    """
    TOWNS = ("Mousehold", "Foxburrow", "Rabbit-Town")
    COUNT = ("function()\n"
             "  local n = 0\n"
             "  for _, o in ipairs(getAllObjects()) do\n"
             "    local nm = o.getName() or ''\n"
             "    if nm == 'Mousehold' or nm == 'Foxburrow' or nm == 'Rabbit-town' then n = n + 1 end\n"
             "  end\n"
             "  return n\n"
             "end")
    for how, drive in (
        ("called directly", "pcall(function() makeMap(Player['Red'], '', 'Marsh Map') end) FLUSH(80)"),
        ("through the button", None),
    ):
        rt = fresh(src)
        rt.execute("SEAT('Red')")
        rt.execute("pcall(function() rttPlaceMarsh5P(nil,nil,'Marsh5PMap') end) FLUSH(80)")
        assert rt.eval("RTT_5P_MARSH") is True, "%s: 5-Players Marsh did not enter 5-player mode" % how
        towns = rt.eval(COUNT)()
        assert towns > 0, "%s: the 5-player Marsh placed no town landmarks, so this proves nothing" % how

        if drive is not None:
            rt.execute(drive)
        else:
            # the real button: first click arms, second commits, and the 3s window must not expire
            rt.execute("pcall(function() rttArmMap(Player['Red'],'','Marsh Map') end) FLUSH_UNTIL(0.5, 4)")
            assert rt.eval("function() return tostring(RTT_ARM and RTT_ARM.id) end")() == "Marsh Map", \
                "the first click did not arm the Marsh button"
            rt.execute("pcall(function() rttArmMap(Player['Red'],'','Marsh Map') end) FLUSH(80)")

        assert rt.eval("RTT_5P_MARSH") is False, "%s: still in 5-player mode" % how
        left = rt.eval(COUNT)()
        assert left == 0, "%s: %d town landmark(s) survived the rebuild" % (how, left)
        # NOT #RTT_MARSH_FLOODED: rttMarshPlan5P fills that table too, with the three TOWNS, so it
        # holds 3 entries under BOTH layouts and can never tell them apart. The flood marker TILES can:
        # the 5-player plan parks them under the table at y -50, the 4-player one floods clearings.
        ys = rt.eval("function()\n"
                     "  local t = {}\n"
                     "  for _, o in ipairs(getAllObjects()) do\n"
                     "    local sc = o.getScale()\n"
                     "    if sc and math.abs(sc.x - 3.70906973) < 0.01 then\n"
                     "      t[#t+1] = string.format('%.1f', o.getPosition().y)\n"
                     "    end\n  end\n  return table.concat(t, ' ')\nend")()
        vals = [float(v) for v in ys.split()]
        assert len(vals) == 3, "%s: expected 3 flood tiles, found %d" % (how, len(vals))
        assert all(v > 0 for v in vals), \
            "%s: flood tiles still under the table at %s -- the 5-player board was built" % (how, vals)


def t_a_new_game_refreshes_the_map_but_keeps_the_board(src):
    """A new game re-rolls what sits ON the map; the board itself stays.

    Maintainer, 2026-09-06: "reset the clearing makers the landmarks everything that goes on the board
    because anyway they are reshuffled, reset the board itself and the clearing numbers only if it is
    another map." Choosing a different map is a map-button click, which is a full rebuild anyway, so
    the only case here is the SAME map and the board always stays.

    The bug that forced this, reported twice: "spawning marsh 4 players after marsh 5 players still
    does not span the flooded clearings properly and keep the landmarks." Starting a 4-player game
    after a 5-player Marsh game left the FIVE-player board on the table -- towns standing, no flooding
    -- because rttSetup cleared the flag but nothing rebuilt the map, the id being unchanged. The
    earlier fix corrected the flag, which in this flow was never the thing that was wrong.
    """
    TOWNS = ("function()\n  local n = 0\n"
             "  for _, o in ipairs(getAllObjects()) do\n"
             "    local nm = o.getName() or ''\n"
             "    if nm == 'Mousehold' or nm == 'Foxburrow' or nm == 'Rabbit-town' then n = n + 1 end\n"
             "  end\n  return n\nend")
    BOARD = "function() local b = rttFindMapObject() return b and b.getGUID() or '' end"
    FLOOD = ("function()\n  local t = {}\n"
             "  for _, f in ipairs(RTT_MARSH_FLOODED or {}) do\n"
             "    t[#t+1] = string.format('%.1f/%.1f', f[1], f[2])\n"
             "  end\n  table.sort(t)\n  return table.concat(t, ' ')\nend")

    def two_clicks(rt, fn, bid):
        rt.execute("pcall(function() %s(Player['Purple'],'','%s') end) FLUSH_UNTIL(0.5,4)" % (fn, bid))
        rt.execute("pcall(function() %s(Player['Purple'],'','%s') end) FLUSH(200)" % (fn, bid))

    rt = fresh(src)
    for c, n in zip(["Purple", "Blue", "White", "Pink", "Green"], ["H1", "H2", "H3", "H4", "H5"]):
        rt.execute("SEAT('%s','%s')" % (c, n))

    # the maintainer's sequence: a 5-player Marsh game, then a 4-player one
    two_clicks(rt, "rttArmMarsh5P", "Marsh5P")
    assert rt.eval(TOWNS)() > 0, "the 5-player Marsh placed no towns, so this proves nothing"
    board5 = rt.eval(BOARD)()
    assert board5 != "", "no map board found -- rttFindMapObject needs snap points"

    two_clicks(rt, "rttArmRanked", "rttRankedBtn")
    assert rt.eval("RTT_5P_MARSH") is False, "the 4-player draft stayed in 5-player mode"
    left = rt.eval(TOWNS)()
    assert left == 0, "%d town landmark(s) survived into the 4-player game" % left
    assert len((rt.eval(FLOOD)() or "").split()) == 3, "the 4-player Marsh is not flooded"
    assert rt.eval(BOARD)() == board5, "the board itself was respawned; it should have been kept"

    # a MAP BUTTON is still a full rebuild -- that is the "another map" case, and the board goes
    rt.execute("pcall(function() makeMap(Player['Purple'],'','Marsh Map') end) FLUSH(200)")
    assert rt.eval(BOARD)() != board5, "the map button no longer rebuilds the board"

    # the 5-player path must still build its OWN board through the same refresh
    rt2 = fresh(src)
    for c, n in zip(["Purple", "Blue", "White", "Pink", "Green"], ["H1", "H2", "H3", "H4", "H5"]):
        rt2.execute("SEAT('%s','%s')" % (c, n))
    two_clicks(rt2, "rttArmMarsh5P", "Marsh5P")
    two_clicks(rt2, "rttArmMarsh5P", "Marsh5P")
    assert rt2.eval(TOWNS)() > 0, "a second 5-player game lost its town landmarks"
    assert rt2.eval("RTT_5P_MARSH") is True, "a second 5-player game left 5-player mode"

    # and the flood is genuinely re-rolled, not inherited: 8 games, more than one layout
    rt3 = fresh(src)
    for c, n in zip(["Purple", "Blue", "White", "Pink", "Green"], ["H1", "H2", "H3", "H4", "H5"]):
        rt3.execute("SEAT('%s','%s')" % (c, n))
    rt3.execute("pcall(function() makeMap(Player['Purple'],'','Marsh Map') end) FLUSH(200)")
    seen = {rt3.eval(FLOOD)()}
    for _ in range(8):
        two_clicks(rt3, "rttArmRanked", "rttRankedBtn")
        seen.add(rt3.eval(FLOOD)())
    assert len(seen) > 1, "every new game got the same flood layout: %s" % seen


class TTSPlayer(object):
    """A player the way TABLETOP SIMULATOR passes one to a button handler: NOT a Lua table.

    lupa hands a plain Python object to Lua as USERDATA, which is what a TTS Player actually is. The
    stub's own Player entries are Lua tables, so every click test in this file has been exercising a
    kind of player that TTS never produces -- and that hid a bug for three rounds of "fixed".
    """
    def __init__(self, color, name="H1"):
        self.color = color
        self.steam_name = name
        self.seated = True


def t_a_button_click_is_recognised_when_the_player_is_userdata(src):
    """makeMap must know a human click even though a TTS Player is userdata, not a table.

    Maintainer, three times, most recently "bug still there when spawning 4 player marsh after 5 player
    marsh", pressing 5-Players Marsh and then Marsh, and seeing the flood tiles missing and the town
    landmarks still standing.

    Both symptoms are one cause: makeMap decided "a human clicked this" with type(player) == "table".
    In TTS a Player is USERDATA, so that was false for every click ever made, RTT_5P_MARSH was never
    cleared, and the Marsh button rebuilt the FIVE-player board -- flood tiles parked under the table
    at y -50, towns placed. The suite stayed green throughout because the stub's Player IS a table, so
    the guard ran in the harness and nowhere else. The lesson is in the assertion below: drive the
    click with something that is not a table.
    """
    rt = fresh(src)
    rt.execute("SEAT('Purple','H1')")
    assert rt.eval("function(p) return type(p) end")(TTSPlayer("Purple")) == "userdata", \
        "this test is pointless unless the player reaches Lua as userdata"

    rt.execute("pcall(function() rttPlaceMarsh5P(nil,nil,'Marsh5PMap') end) FLUSH(200)")
    assert rt.eval("RTT_5P_MARSH") is True, "5-Players Marsh did not enter 5-player mode"

    rt.eval("function(p) pcall(function() makeMap(p, '', 'Marsh Map') end) end")(TTSPlayer("Purple"))
    rt.execute("FLUSH(200)")

    assert rt.eval("RTT_5P_MARSH") is False, \
        "a userdata player was not recognised as a human click, so 5-player mode never cleared"

    # the three flood marker tiles: the 5-player plan parks them under the table at y -50, the
    # 4-player one floods three clearings at about y 11.7. This is the only honest way to tell the
    # two boards apart -- RTT_MARSH_FLOODED holds three entries either way (the 5-player plan puts
    # the TOWNS in it), which is why every earlier assertion on it was blind to this.
    ys = rt.eval("function()\n"
                 "  local t = {}\n"
                 "  for _, o in ipairs(getAllObjects()) do\n"
                 "    local s = o.getScale()\n"
                 "    if s and math.abs(s.x - 3.70906973) < 0.01 then\n"
                 "      t[#t+1] = string.format('%.1f', o.getPosition().y)\n"
                 "    end\n  end\n  return table.concat(t, ' ')\nend")()
    vals = [float(v) for v in ys.split()]
    assert len(vals) == 3, "expected 3 flood marker tiles, found %d" % len(vals)
    assert all(v > 0 for v in vals), \
        "the flood tiles are still under the table at %s -- the FIVE-player board was built" % vals

    towns = rt.eval("function()\n  local n = 0\n"
                    "  for _, o in ipairs(getAllObjects()) do\n"
                    "    local nm = o.getName() or ''\n"
                    "    if nm == 'Mousehold' or nm == 'Foxburrow' or nm == 'Rabbit-town' then n = n + 1 end\n"
                    "  end\n  return n\nend")()
    assert towns == 0, "%d town landmark(s) still standing on the 4-player Marsh" % towns

    # the INTERNAL path must still be invisible: "" has no colour, so it places the 5-player map
    # without clearing the flag out from under itself
    rt2 = fresh(src)
    rt2.execute("SEAT('Purple','H1')")
    rt2.execute("pcall(function() rttPlaceMarsh5P(nil,nil,'Marsh5PMap') end) FLUSH(200)")
    assert rt2.eval("RTT_5P_MARSH") is True, \
        "the internal path cleared the flag it had just set"


def t_every_new_game_button_leaves_the_five_player_marsh(src):
    """EVERY button that starts a game must leave the 5-player Marsh behind -- except the 5-player one.

    rttSetup (the ranked path) has always cleared RTT_5P_MARSH. setupFactionBoards -- the 4-Player
    Setup button -- never did. That was harmless while a new game left the map alone, and became a live
    bug the moment rttNewGame started refreshing it: the refresh goes through the INTERNAL path, which
    deliberately does not clear the flag, so 4-Player Setup rebuilt the FIVE-player board.

    Found by a review agent after the maintainer had reported the Marsh bug three times and I had
    declared it fixed twice. My own tests never composed this pair: they drove makeMap, the map button
    and the ranked draft, and only ever pressed 4-Player Setup on a clean table, where there is nothing
    to get wrong.

    The census below spells the town 'Rabbit-town', with a lower-case t, which is how content.lua
    nicknames it. Spelling it 'Rabbit-Town' -- as three assertions in this file did -- counts 2 towns
    on a board that has 3, so a surviving Rabbit-town was invisible to every one of them.
    """
    TOWNS = ("function()\n  local n = 0\n"
             "  for _, o in ipairs(getAllObjects()) do\n"
             "    local nm = o.getName() or ''\n"
             "    if nm == 'Mousehold' or nm == 'Foxburrow' or nm == 'Rabbit-town' then n = n + 1 end\n"
             "  end\n  return n\nend")
    FLOODY = ("function()\n  local t = {}\n"
              "  for _, o in ipairs(getAllObjects()) do\n"
              "    local sc = o.getScale()\n"
              "    if sc and math.abs(sc.x - 3.70906973) < 0.01 then\n"
              "      t[#t+1] = string.format('%.1f', o.getPosition().y)\n"
              "    end\n  end\n  return table.concat(t, ' ')\nend")

    def two_clicks(rt, fn, bid):
        rt.execute("pcall(function() %s(Player['Purple'],'','%s') end) FLUSH_UNTIL(0.5,4)" % (fn, bid))
        rt.execute("pcall(function() %s(Player['Purple'],'','%s') end) FLUSH(200)" % (fn, bid))

    # (label, arm fn, button id, should the FIVE-player board survive?)
    BUTTONS = (
        ("4-Player Setup", "rttArmFour",      "rttFourBoardsBtn", False),
        ("4-Player Draft", "rttArmRanked",    "rttRankedBtn",     False),
        ("Theme",          "rttArmTheme",     "rttThemeBtn",      True),   # Theme IS the 5-player draft
        ("5P Setup",       "rttArmFiveSetup", "Marsh5PSetup",     True),   # a five-player game keeps it
    )
    for label, fn, bid, keep5p in BUTTONS:
        rt = fresh(src)
        for c, n in zip(["Purple", "Blue", "White", "Pink", "Green"], ["H1", "H2", "H3", "H4", "H5"]):
            rt.execute("SEAT('%s','%s')" % (c, n))
        rt.execute("pcall(function() rttPlaceMarsh5P(nil,nil,'Marsh5PMap') end) FLUSH(200)")
        assert rt.eval("RTT_5P_MARSH") is True, "%s: the 5-player Marsh did not set its flag" % label
        assert rt.eval(TOWNS)() == 3, \
            "%s: the 5-player Marsh should stand 3 towns, found %d" % (label, rt.eval(TOWNS)())

        two_clicks(rt, fn, bid)

        vals = [float(v) for v in (rt.eval(FLOODY)() or "").split()]
        assert len(vals) == 3, "%s: expected 3 flood tiles, found %d" % (label, len(vals))
        towns = rt.eval(TOWNS)()
        if keep5p:
            assert all(v < 0 for v in vals), \
                "%s is a five-player game and should KEEP the 5-player board; flood tiles at %s" % (label, vals)
            assert towns == 3, "%s lost the towns off its own 5-player board" % label
        else:
            assert rt.eval("RTT_5P_MARSH") is False, "%s left 5-player mode on" % label
            assert all(v > 0 for v in vals), \
                "%s: flood tiles still under the table at %s -- it rebuilt the 5-player board" % (label, vals)
            assert towns == 0, "%s: %d town landmark(s) survived into a four-player game" % (label, towns)


def t_the_five_player_buttons_warn_before_wiping(src):
    """The 5-player buttons must warn when they reset factions OR the map.

    Maintainer, 2026-09-06: "the options buttons should also have the warnings when they reset factions
    or maps", naming "the 5 players draft, 5 players marsh, 5 player setup option buttons".

    Two separate holes. 5-Players Marsh had NO wipe entry at all, so it replaced the map on a single
    click with no prompt -- BUTTONS.md even claimed it "is not destructive". And the other two only
    consulted rttWouldWipe's FACTION tags, which was right until rttNewGame started re-placing the map:
    after that, starting a game on a table with a map but no factions destroyed the map silently.

    The wording follows what is actually at stake. A button that clears factions and the map should not
    promise to "reset all factions" when there is not a faction in sight, so with only a map down it
    shows the map warning instead.
    """
    def icon(rt, bid):
        return rt.eval("function(b) return tostring(UIATTR[b .. '.icon']) end")(bid)
    def armed(rt):
        return rt.eval("function() return tostring(RTT_ARM and RTT_ARM.id) end")()
    def fresh_seated():
        rt = fresh(src)
        rt.execute("SEAT('Purple','H1') SEAT('Blue','H2')")
        return rt
    def click(rt, fn, bid):
        rt.execute("pcall(function() %s(Player['Purple'],'','%s') end) FLUSH_UNTIL(0.5,4)" % (fn, bid))

    # nothing on the table: no prompt, the click just runs -- the rule the other buttons already follow
    rt = fresh_seated()
    click(rt, "rttArmMarsh5PMap", "Marsh5PMap")
    assert armed(rt) == "nil", "5-Players Marsh prompted on a clean table"
    assert rt.eval("RTT_5P_MARSH") is True, "5-Players Marsh did not run on a clean table"

    # EVERY BUTTON WARNS ABOUT WHAT IT WILL ACTUALLY DO -- no more, and no less.
    #
    # A MAP button only ever places a map, so it says map whatever is on the table and can never claim
    # to touch a faction. A SETUP button clears the factions AND re-places the map, so which of the two
    # it costs you depends on what is out: with factions down it says factions, with none it says map.
    #
    # Both halves are the maintainer's, a day apart. "Put back the appropriate warning to the
    # appropriate buttons! since some buttons reset the map others the factions" killed the old rule,
    # which swapped EVERY button's wording by table state and read as the faction warning having been
    # deleted. Then: "still have a warning about wiping factions while the only thing I spawned is a
    # map", and "This will reset the map BUT ONLY IF IT INDEED DOES!!! some buttons do not".
    WORDING = (("rttArmMarsh5PMap", "Marsh5PMap",       "WipeConfirmMapArt", "WipeConfirmMapArt"),
               ("rttArmMap",        "Summer Map",       "WipeConfirmMapArt", "WipeConfirmMapArt"),
               ("rttArmMarsh5P",    "Marsh5P",          "WipeConfirmMapArt", "WipeConfirmArt"),
               ("rttArmFiveSetup",  "Marsh5PSetup",     "WipeConfirmMapArt", "WipeConfirmArt"),
               ("rttArmFour",       "rttFourBoardsBtn", "WipeConfirmMapArt", "WipeConfirmArt"),
               ("rttArmRanked",     "rttRankedBtn",     "WipeConfirmMapArt", "WipeConfirmArt"))
    for withFactions in (False, True):
        for fn, bid, mapOnly, withFac in WORDING:
            want = withFac if withFactions else mapOnly
            rt = fresh_seated()
            rt.execute("pcall(function() makeMap(Player['Purple'],'','Summer Map') end) FLUSH(200)")
            if withFactions:
                rt.execute("pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(200)")
            click(rt, fn, bid)
            assert armed(rt) == bid, "%s did not warn (factions on table: %s)" % (bid, withFactions)
            got = icon(rt, bid)
            assert got.startswith(want), (
                "%s shows %s with factions=%s; it should show %s"
                % (bid, got, withFactions, want))

    # and the second click actually commits
    rt = fresh_seated()
    rt.execute("pcall(function() makeMap(Player['Purple'],'','Summer Map') end) FLUSH(200)")
    click(rt, "rttArmMarsh5PMap", "Marsh5PMap")
    rt.execute("pcall(function() rttArmMarsh5PMap(Player['Purple'],'','Marsh5PMap') end) FLUSH(200)")
    assert armed(rt) == "nil", "the commit click left the button armed"
    assert rt.eval("RTT_5P_MARSH") is True, "the commit click did not place the 5-player Marsh"


def t_a_destroyed_object_cannot_crash_the_map_scan(src):
    """A handle that dies mid-scan must not take the board's script down with it.

    Maintainer, 2026-09-06, with a screenshot: "[Faction Selection - bab7e1] Lua Error: Object
    reference not set to an instance of an object." -- once, just after a button press. That message is
    TTS surfacing a .NET NullReferenceException, which is what calling a method on a destroyed object
    gives you.

    rttFindMapObject's fallback called o.getGUID() bare, and getAllObjects hands back a snapshot: any
    entry can be destroyed before the loop reaches it. The fallback only runs when no tagged map piece
    has snap points -- which is precisely a map TEARDOWN, just after removeMapItems, just after a button
    press. rttWhenMapReady then made it hot by polling through exactly that window.

    Two fixes, both checked here: every call on a possibly-dead handle is protected, and the polling
    path uses rttMapBoardTagged, which never walks the whole table at all.
    """
    rt = fresh(src)
    rt.execute("SEAT('Purple','H1')")
    # a handle that behaves like a destroyed TTS object: every method throws
    rt.execute("""
      DEAD = { }
      setmetatable(DEAD, { __index = function() return function()
        error("Object reference not set to an instance of an object.")
      end end })
      local _all = getAllObjects
      getAllObjects = function()
        local t = _all()
        table.insert(t, 1, DEAD)      -- first, so a bare call hits it immediately
        return t
      end
    """)
    # no tagged map piece: this is the teardown window, so the fallback is what runs
    ok = rt.eval("function() local o, e = pcall(function() return rttFindMapObject() end) "
                 "return tostring(o) .. '|' .. tostring(e) end")()
    assert ok.startswith("true"), "rttFindMapObject died on a destroyed handle: %s" % ok

    # and the polling path must not touch the whole-table scan at all
    rt.execute("SAWALL = false local _a = getAllObjects getAllObjects = function() SAWALL = true return _a() end")
    rt.execute("pcall(function() rttWhenMapReady(function() end, 2) end) FLUSH(20)")
    assert rt.eval("SAWALL") is False, \
        "rttWhenMapReady walked every object on the table; it should only look at tagged map pieces"


def t_table_fixtures_survive_a_map_change(src):
    """The battle mat, box score, clock and counter are the same objects whatever map is down.

    Maintainer, 2026-09-06: "when resetting a map for another map no need to reset battle mat boxscore
    clock counter since they are the same objects."

    It cost more than a flicker. rttSpawnBoxScore destructs the old sheet before spawning, and it ran
    on every map build -- so changing map mid-session THREW AWAY the recorded game. The mat, clock and
    counter are tagged "Map Object", so removeMapItems killed those too.

    A NEW GAME still gets a fresh sheet: holding this game is the whole point of the box score, so
    rttNewGame drops it and the map refresh spawns a new one. The other three persist even then --
    nothing about them belongs to a particular game.
    """
    NAMES = ("Battle Mat", "Turn Panel", "Root Box Score")
    Q = ("function()\n  local t = {}\n"
         "  for _, o in ipairs(getAllObjects()) do\n"
         "    local n = o.getName() or ''\n"
         "    for _, w in ipairs({'Battle Mat','Turn Panel','Root Box Score'}) do\n"
         "      if n == w then t[#t+1] = n .. '|' .. o.getGUID() end\n"
         "    end\n  end\n  table.sort(t)\n  return table.concat(t, ';')\nend")

    def fixtures(rt):
        raw = rt.eval(Q)() or ""
        out = {}
        for row in [r for r in raw.split(";") if r]:
            name, guid = row.split("|")
            out.setdefault(name, []).append(guid)
        return out

    rt = fresh(src)
    rt.execute("SEAT('Purple','H1')")
    rt.execute("pcall(function() makeMap(Player['Purple'],'','Summer Map') end) FLUSH(200)")
    first = fixtures(rt)
    for n in NAMES:
        assert len(first.get(n, [])) == 1, "%s: expected exactly 1 after the first map, got %s" % (n, first.get(n))

    for m in ("Marsh Map", "Lake Map", "Winter Map"):
        rt.execute("pcall(function() makeMap(Player['Purple'],'','%s') end) FLUSH(200)" % m)
        now = fixtures(rt)
        for n in NAMES:
            assert len(now.get(n, [])) == 1, \
                "%s: %d copies after switching to %s -- it was respawned, not kept" % (n, len(now.get(n, [])), m)
            assert now[n] == first[n], \
                "%s was destroyed and rebuilt by the %s change (%s -> %s)" % (n, m, first[n], now[n])

    # a new game replaces ONLY the sheet
    rt.execute("pcall(function() rttArmRanked(Player['Purple'],'','rttRankedBtn') end) FLUSH_UNTIL(0.5,4)")
    rt.execute("pcall(function() rttArmRanked(Player['Purple'],'','rttRankedBtn') end) FLUSH(200)")
    after = fixtures(rt)
    assert len(after.get("Root Box Score", [])) == 1, \
        "a new game left %s box score sheets" % len(after.get("Root Box Score", []))
    assert after["Root Box Score"] != first["Root Box Score"], \
        "a new game kept the OLD box score; it would still hold the previous game"
    for n in ("Battle Mat", "Turn Panel"):
        assert after[n] == first[n], "%s was rebuilt by a new game; nothing about it is per-game" % n


def t_send_home_fills_from_the_players_own_right(src):
    """"Rightmost empty slot" means the PLAYER'S right, at every seat.

    Maintainer, 2026-09-06: "it look s like the issue is that you take the absolute direction for left
    or right for the sympathy token but its rightmost for the player looking at his faction board. so
    for seat 1 and 2 its the opposite absolute direction than for seat 3 and 4 with 4 players. this is
    a mistake you do often and should check for the other tokens."

    And the rule it comes from, which is why this test covers four piece types rather than sympathy:
    "everything is always referenced with respect to the vision of the player otherwise instructions
    would change depending on seat which makes no sense."

    rttHomeSlots used ONE sign for the whole table (RTT_HOME_RIGHT_IS_PLUS_X), so the fill ran to the
    player's right on the near row and to their LEFT on the far row. A far-row seat is rotated 180, so
    both axes invert together; the comparator now multiplies by the seat's own sign, which IS that half
    turn.
    """
    CASES = (("Woodland Alliance", "Sympathy"),
             ("Eyrie Dynasties",   "Roost"),
             ("The Lizard Cult",   "Fox Garden"),
             ("Lord of the Hundreds", "Stronghold"))
    for fac, piece in CASES:
        for cz, flip, where in ((-46, False, "near row"), (46, True, "far row")):
            rt = fresh(src)
            rt.execute("SEAT('Purple','H1')")
            rt.execute("RTT_HOME = {}")
            rt.execute("pcall(function() rttPlaceFaction('%s', 52, %d, %s, 'Purple', false, nil, nil, "
                       "'Purple', nil) end) FLUSH(80)" % (fac, cz, "true" if flip else "false"))
            raw = rt.eval("function(n)\n  local t = {}\n"
                          "  for _, s in ipairs(rttHomeSlots(n)) do\n"
                          "    t[#t+1] = string.format('%.2f', s.p[1] - 52)\n"
                          "  end\n  return table.concat(t, ' ')\nend")(piece)
            xs = [float(v) for v in raw.split()] if raw else []
            assert len(xs) >= 3, "%s / %s on the %s: only %d slots, nothing to order" % (
                fac, piece, where, len(xs))
            # the player's right is +x on the near row and -x on the far row, because a far seat is
            # turned around. Either way the FIRST slot filled must be the one furthest to their right.
            if flip:
                bad = [i for i in range(len(xs) - 1) if xs[i] > xs[i + 1] + 0.01]
            else:
                bad = [i for i in range(len(xs) - 1) if xs[i] < xs[i + 1] - 0.01]
            assert not bad, (
                "%s / %s on the %s fills toward the player's LEFT: %s\n"
                "    (on the far row the seat is rotated 180, so their right is -x)"
                % (fac, piece, where, xs))


def t_the_panel_flashes_after_twenty_minutes(src):
    """A turn past twenty minutes tints the panel red, about once a second.

    Maintainer, 2026-09-07: "when a turn gets to 20 mins, have the board background flash red like
    avery second or so as a soft warning that it has been 20 min", and, so it could be looked at
    without waiting: "if I press 3 times deal 5 cards in less than 3 seconds have that warning trigger
    so I can check how it looks."

    THIS IS THE FIRST TEST OF THE PANEL'S OWN SCRIPT. The harness does not execute a spawned object's
    script, so panelTick and panelDeal had no coverage at all -- every earlier panel bug (buttons with
    no click area, the wipe racing the turn event) was found at the table. The script only needs a
    handful of TTS globals, so it runs here against a stub with a clock we control.
    """
    lua = json.loads(src[src.index("RTT_TURN_PANEL_JSON = [====[") + len("RTT_TURN_PANEL_JSON = [====["):
                         src.index("]====]", src.index("RTT_TURN_PANEL_JSON = [====["))])["LuaScript"]
    rt = lupa.LuaRuntime(unpack_returned_tuples=True)
    rt.execute("""
      T = 1000
      os = { time = function() return T end }
      Wait = { time = function() end, frames = function(f) end }
      JSON = { encode = function() return "" end, decode = function() return {} end }
      Turns = { turn_color = "Red", order = {"Red"} }
      UIW = {}
      LASTXML = ""
      self = { UI = { setXml=function(x) LASTXML = x end, setValue=function() end,
                      setCustomAssets=function() end,
                      setAttribute=function(id,k,v) UIW[id.."."..k]=v end },
               setScale=function() end, clearButtons=function() end }
      function getObjectsWithTag() return {} end
      function broadcastToAll() end
      function getAllObjects() return {} end
      Player = { getPlayers = function() return {} end }
    """)
    rt.execute(lua.replace("Wait.time(panelTick, 0.25, -1)", ""))
    g = rt.globals()

    def at(t):
        # The warning is an OVERLAY PANEL emitted into the XML, not a tint. Two earlier versions failed
        # silently -- setAttribute writes an attribute TTS does not re-read, and color= on an <Image> is
        # not honoured at all -- so this asks whether the wash is IN the markup, which is the only thing
        # that can actually appear on screen.
        rt.execute("T = %d" % t)
        g.panelTick()
        # The alarm is a SOLID red panel emitted under the content, so what proves it is the ground
        # colour being in the markup at all. A translucent wash over the top read pink and tinted the
        # type; this replaces the ground instead.
        return ALARM if "#A83226" in (g.LASTXML or "") else NORMAL

    NORMAL, ALARM = "quiet", "washed"
    rt.execute('UIW["pnlwash.active"] = "False"')   # buildUI emits it hidden
    assert at(1000) == NORMAL, "the panel is tinted before any turn has started"
    g.PANEL_START = 1000
    assert at(1060) == NORMAL, "a one-minute turn is already warning"
    assert at(1000 + 19 * 60 + 59) == NORMAL, "it warns at 19:59, before the twenty minutes are up"
    # The beat is counted in TICKS now (two 0.25s ticks = half a second), not off os.time's parity, so
    # sampling once per call shows on-on-off-off rather than strict alternation. What matters is that
    # it changes state repeatedly, and roughly twice as often as the old one-second version.
    seq = [at(1000 + 20 * 60 + k) for k in range(8)]
    assert ALARM in seq and NORMAL in seq, "past twenty minutes it does not flash at all: %s" % seq
    flips = sum(1 for a, b in zip(seq, seq[1:]) if a != b)
    assert flips >= 2, "the flash is too slow: %s (%d changes in 8 samples)" % (seq, flips)

    # A REBUILD MUST NOT BLANK THE READOUTS. Every flash frame re-emits the whole UI, and buildUI used
    # to hardcode the placeholders -- so the round flickered to "-" and the clock to 0:00 twice a
    # second. Maintainer: "the flash makes turn 1 flicker to - symbol for some reason."
    rt.execute('PANEL_RTXT = "7" PANEL_TTXT = "3:21"')
    g.buildUI()
    xml = g.LASTXML or ""
    assert ">7<" in xml, "a rebuild lost the round number: it re-emits the placeholder"
    assert ">3:21<" in xml, "a rebuild lost the clock: it re-emits the placeholder"

    # the demo: three DEAL presses inside three seconds, with no turn running at all
    g.PANEL_START = None
    rt.execute("T = 2000")
    for _ in range(3):
        g.panelDeal()
    assert g.PANEL_DEMO == 2015, "three quick presses did not arm the preview: %s" % g.PANEL_DEMO
    # eight samples, not three: the beat is three ticks now, so a short window can sit in one phase
    demo = [at(2002 + k) for k in range(8)]
    assert ALARM in demo and NORMAL in demo, "the preview does not flash: %s" % demo
    assert at(2020) == NORMAL, "the preview never ends"

    # THE RED GROUND GOES UNDER THE CONTENT, and the type turns white on it. Emitted over the top it
    # was a film that tinted the dark type pink -- maintainer: "make it more red, now it s pinkish ...
    # and have the text appear in white to contrast."
    rt.execute("PANEL_ALARM = true")
    g.buildUI()
    xml = g.LASTXML or ""
    assert "#A83226" in xml, "no red ground in the alarm markup"
    assert xml.index("#A83226") < xml.index("<VerticalLayout"), \
        "the red ground is emitted after the content; it would sit on top of the type"
    assert "#FFFFFF" in xml, "the type does not go white while it warns"
    rt.execute("PANEL_ALARM = false")
    g.buildUI()
    assert "#A83226" not in (g.LASTXML or ""), "the red ground is drawn when nothing is wrong"

    # and the preview drives its own timer, so it survives the periodic tick stopping
    assert "panelFlashStep" in lua, "the preview has no timer of its own"

    # and pressing slowly must NOT arm it
    g.PANEL_DEMO = None
    rt.execute("PANEL_TAPS = {}")
    for k in range(3):
        rt.execute("T = %d" % (3000 + k * 5))
        g.panelDeal()
    assert g.PANEL_DEMO is None, "presses five seconds apart armed the preview"


def t_every_selector_icon_is_downloaded_with_the_table(src):
    """A board we SPAWN must never be the first thing in the mod to ask for its own art.

    Neither faction selector exists in the save: both are built from a blueprint string and spawned
    mid-game. TTS resolves an object's XmlUI icon references ONCE, at the instant the object is
    instantiated, and never re-composites as downloads finish -- the cold-load finding of 2026-08-29
    (WORK_QUEUE_ARCHIVE). An icon that is not already on the player's disk when the board appears is
    an icon that never appears: the board renders its wood and not one button, and only a second load
    of the mod fixes it.

    The twelve faction icons used to be the setup board's own files, so the table fetched them at load
    and the spawned boards found them warm. Re-rendering every setup label in Luminari (74cefe8) moved
    the setup board onto new art and left these blueprints on the old Steam URLs, which nothing else in
    the mod asks for -- and the blank faction board came back for anyone loading the mod for the first
    time. Maintainer, 2026-09-07: "faction board showed no buttons ... it was resolved by reloading the
    mod ... still there for people loading the mod the first time".

    So: every image a spawned board asks for must also be listed on an object that IS in the save.
    """
    save = json.loads(open(os.path.join(REPO, "dist", "Root_Tabletop_Tournament.json"),
                           encoding="utf-8").read())

    def walk(objs):
        for o in objs:
            yield o
            yield from walk(o.get("ContainedObjects") or [])

    # every URL TTS is told about while the table itself loads
    at_load = set()
    for o in walk(save["ObjectStates"]):
        for a in (o.get("CustomUIAssets") or []):
            at_load.add(a.get("URL"))
    for a in (save.get("CustomUIAssets") or []):
        at_load.add(a.get("URL"))

    for var in ("MANUAL_FACTION_SELECTOR_JSON", "RTT_SELECTOR_JSON"):
        m = re.search(re.escape(var) + r" = \[===\[(\{.*?)\]===\]", src, re.S)
        assert m is not None, "%s: blueprint not found" % var
        blueprint = json.loads(m.group(1))
        by_name = {a["Name"]: a["URL"] for a in (blueprint.get("CustomUIAssets") or [])}
        assert by_name, "%s: declares no UI assets -- did the blueprint change shape?" % var

        # EVERY DECLARED ASSET, not only the ones named in the XmlUI. TTS composites an object's UI
        # once at instantiation, and the ranked selector's faction buttons get their icons at RUNTIME
        # through setAttribute -- so its XmlUI names none of them and checking only icon= refs would
        # have covered nothing at all on that board.
        used = set(re.findall(r'(?:icon|image)="([^"]+)"', blueprint.get("XmlUI") or ""))
        for name in sorted(used):
            assert name in by_name, "%s: button icon %r has no asset entry" % (var, name)
        for name in sorted(by_name):
            assert by_name[name] in at_load, (
                "%s: icon %r is only ever requested when the board is SPAWNED, so it is missing on a "
                "cold load and the board comes up with no buttons. List it on the table surface "
                "(4ee1f2) in gen/src/save.json." % (var, name))


def t_placement_never_asks_the_board_how_big_it_is(src):
    """A map must land in the same place whatever the board's size happens to be at that instant.

    Every move_to in content.lua was recorded against a board of scale 15.5, and ten spawn paths turned
    one into a world position with "move_to / self.getScale() * 15.5". That made every placement depend
    on the board's live size -- and the board is a Custom_Tile with WidthScale 0, so TTS works its shape
    out FROM ITS PICTURE, which has to download first. The maintainer can watch it happen: objects come
    up one size and then resize. Anything placed inside that window lands scaled about the world origin,
    which is what "the map and items loaded all over the place" looks like, and why a second load of the
    mod always fixed it (2026-09-07).

    Nothing resizes these boards, so the term was 1 by construction; it is now 1 by definition. This
    drives a map twice with two wildly different board sizes and demands the same answer both times.
    """
    def spawns(board_scale):
        rt = fresh(src)
        rt.execute("self.__scale = Vector({%r, 1.0, %r})" % (board_scale, board_scale))
        rt.execute("REC.spawned = {} pcall(function() makeMap('', '', 'Summer Map') end) FLUSH(30)")
        rec = rt.eval("REC.spawned")
        return [str(rec[i]) for i in range(1, len(rec) + 1)]

    right = spawns(15.5)
    assert right, "the map spawned nothing -- the test is not exercising makeMap"
    for wrong_scale in (1.0, 7.75, 31.0):
        got = spawns(wrong_scale)
        assert got == right, (
            "board scale %s moved the map: %d of %d pieces landed elsewhere, first difference %r vs %r"
            % (wrong_scale, sum(1 for a, b in zip(got, right) if a != b), len(right),
               next((a for a, b in zip(got, right) if a != b), None),
               next((b for a, b in zip(got, right) if a != b), None)))


def t_the_dragon_god_goes_out_with_its_faction(src):
    """The lizards' discard blocker must be cleared by a new game.

    Reported 2026-09-07: "the lizard god called dragon god is not cleared with its faction". Every
    spawn of the blocker went through

        makeSpecial(category, name, x, y, z, rotation, tag)

    whose SEVENTH argument is the teardown tag -- and not one of the three call sites passed one, so
    the object reached the table with no tags at all. RTT_TEARDOWN_TAGS ("RTT Selector", "RTT Manual
    Selector", "RTT Faction", "RTT Pond", "RTT Order Card") therefore never matched it and
    rttClearGameObjects walked straight past, leaving the Dragon God on the discard across every
    game of the session. Salty Old Stan, which replaces it, spawned the same way and leaked too.

    This is fault 3 from the work queue -- something a game leaves behind that teardown cannot see --
    and the tag is what makes it visible.
    """
    COUNT = ("function(nm) local n = 0 for _, o in ipairs(getAllObjects()) do "
             "if (o.getName() or '') == nm then n = n + 1 end end return n end")
    TAGS = ("function(nm) for _, o in ipairs(getAllObjects()) do "
            "if (o.getName() or '') == nm then return table.concat(o.getTags(), ',') end "
            "end return '<absent>' end")

    for spawn, name in (("rttPlaceDragonGod()", "Dragon God"),
                        ("summonLizardBlocker()", "Dragon God"),
                        ("summonSaltyOldStan()", "Salty Old Stan")):
        rt = fresh(src)
        rt.execute("pcall(function() %s end) FLUSH(20)" % spawn)
        assert rt.eval(COUNT)(name) == 1, "%s did not put a %s on the table" % (spawn, name)
        assert "RTT Faction" in (rt.eval(TAGS)(name) or ""), (
            "%s spawned %s tagged %r -- teardown sweeps by tag and cannot see it"
            % (spawn, name, rt.eval(TAGS)(name)))
        rt.execute("pcall(function() rttNewGame(nil) end) FLUSH(40)")
        assert rt.eval(COUNT)(name) == 0, \
            "a new game left the %s from %s on the table" % (name, spawn)

    # an untagged one already out -- an old save, or the Lizard Wizard button -- must be adopted
    rt = fresh(src)
    rt.execute("MKOBJ('Dragon God', {-31.09, 5, 2.31}, {}) FLUSH(4)")
    assert "RTT Faction" not in (rt.eval(TAGS)("Dragon God") or ""), "fixture: it should start untagged"
    rt.execute("pcall(function() rttPlaceDragonGod() end) FLUSH(20)")
    assert "RTT Faction" in (rt.eval(TAGS)("Dragon God") or ""), \
        "a blocker already on the table was repositioned but not adopted, so it leaks one more game"
    rt.execute("pcall(function() rttNewGame(nil) end) FLUSH(40)")
    assert rt.eval(COUNT)("Dragon God") == 0, "the adopted blocker still survived a new game"


def t_send_home_asks_no_permission(src):
    """Numpad 0 puts a piece where the PIECE belongs, whoever pressed the key.

    It had an ownership check for a few hours on 2026-09-07 -- "gizmo 0 should not work on other
    player's warriors and token buildings" -- and it came straight back out the same day: "remove the
    player permission with numpad 0 so it s not broken when it s wrong about who is who". Deciding
    whose piece it is means deciding who YOU are, and when that answer is wrong the key silently does
    nothing, which is worse than the thing the check was preventing.

    So there is no seat lookup on this path at all: an unseated player, a player the mod has mixed up,
    and a player holding four factions at once all get the same behaviour.
    """
    rt = fresh(src)
    rt.execute("""
      PUT = {}
      for _, n in ipairs({'Eyrie Supply', 'Marquise Supply'}) do
        local b = MKOBJ(n, {0,1,0}, {})
        b.putObject = function(o) PUT[#PUT+1] = (o.getName() or '') end
      end
      MINE   = MKOBJ('Eyrie Warrior', {1,1,1}, {})
      THEIRS = MKOBJ('Cat Warrior', {2,1,2}, {})
      SAID = {}
    """)
    put = lambda: [str(x) for x in (rt.eval("PUT") or {}).values()]

    # nobody is seated in any colour at all
    rt.execute('HOVER["Red"] = MINE rttGizmoHome("Red") FLUSH(5)')
    assert put() == ["Eyrie Warrior"], "an unseated player could not send a warrior home: %s" % put()

    rt.execute('HOVER["Red"] = THEIRS rttGizmoHome("Red") FLUSH(5)')
    assert put() == ["Eyrie Warrior", "Cat Warrior"], \
        "the key refused a piece that was not the presser's: %s" % put()

    said = [str(x) for x in (rt.eval("SAID") or {}).values()]
    assert not said, "numpad 0 should stay silent, it said: %s" % said

    # and nothing is left that could start refusing again
    for gone in ("rttPieceFaction", "rttFactionOfMap"):
        assert gone not in src, "%s is back; numpad 0 asks no permission now" % gone


def t_numpad_two_lays_a_warrior_down_and_back_up(src):
    """Down: flat on the board, locked, with a disc under it in the presser's colour. Up: as it was.

    Maintainer, 2026-09-07: "pressing numpad 2 should put a warrior laying down ... and lock it.
    repressing numpad 2 undoes all of that", then "instead of changing the color of the piece have a
    small circly be drawn under the piece, a little bit transparent, and of the color of the player
    doing it". The piece keeps its own paint -- repainting it lost the faction's colour and read as
    damage -- and the marker says WHO put it down, which a tint never could.

    ANY warrior, his call when asked, not only your own.
    """
    rt = fresh(src)
    rt.execute("""
      LASTJSON = nil
      local real = spawnObjectJSON
      spawnObjectJSON = function(p) LASTJSON = p.json return real(p) end
      MINE = MKOBJ("Eyrie Warrior", {1,1,1}, {})
      MINE.setRotation({0, 137, 0})
      MINE.__bounds = {size = Vector({1, 3, 1}), center = Vector({1, 2.5, 1})}
      THEIRS = MKOBJ("Cat Warrior", {2,1,2}, {})
      ROOST  = MKOBJ("Roost", {3,1,3}, {})
    """)

    def state(obj):
        rt.execute("local o = %s R = o.getRotation() L = o.getLock() P = o.getPosition()" % obj)
        r, p = rt.eval("R"), rt.eval("P")
        return (round(r.x, 1), round(r.y, 1)), rt.eval("L"), (round(p.x, 3), round(p.y, 3), round(p.z, 3))

    before = state("MINE")
    assert before == ((0.0, 137.0), False, (1.0, 1.0, 1.0)), before

    # rotating shortens the box without moving it, so the foot rises and the piece must come down
    rt.execute('HOVER["Red"] = MINE rttGizmoLay("Red") '
               'MINE.__bounds = {size = Vector({1, 1, 3}), center = Vector({1, 2.5, 1})} FLUSH(3)')
    rot, locked, pos = state("MINE")
    assert locked is True, "a laid warrior was not locked"
    assert rot == (90.0, 137.0), "it is not lying flat, or laying it down turned it: %s" % (rot,)
    assert pos[1] == 0.03, "it did not settle onto the board, a hair above its foot: y %s" % pos[1]

    # the piece keeps its own colour; the marker carries the presser's
    rt.execute("T = MINE.getColorTint()")
    t = rt.eval("T")
    assert (round(t.r, 2), round(t.g, 2), round(t.b, 2)) == (1.0, 1.0, 1.0), \
        "the warrior was repainted; the disc is what carries the colour now: %s" % (t,)
    disc = rt.eval("LASTJSON") or ""
    red = rt.eval("RTT_PLAYER_RGB['Red']")
    assert '"r":%s' % round(red[1], 3) in disc.replace(" ", ""), \
        "the disc is not in the presser's colour: %s" % disc[:200]
    a = float(re.search(r'"a":([\d.]+)', disc).group(1))
    assert 0 < a <= 0.45, "the disc is not translucent enough: alpha %s" % a
    sc = float(re.search(r'"scaleX":([\d.]+)', disc).group(1))
    assert abs(sc - 1.275) < 0.001, "the disc is not 1.275x the piece's footprint: %s" % sc
    assert rt.eval("#getObjectsWithTag('RTT Laid Disc')") == 1, "no disc was drawn under the piece"

    # PINNED AT THE PRESS. It followed the player for one build; in hotseat, where one person holds
    # every colour, changing colour then moved every disc they had put down at once. "Pin it at the
    # moment of the press" (2026-09-07).
    rt.execute("LASTJSON = nil SEAT('Yellow', Player['Red'].steam_name) "
               "onPlayerChangeColor('Yellow') FLUSH(5)")
    assert not rt.eval("LASTJSON"), "changing colour redrew the disc; it is pinned now"
    assert rt.eval("#getObjectsWithTag('RTT Laid Disc')") == 1, "the disc did not survive a colour change"

    # and it all comes back
    rt.execute('HOVER["Red"] = MINE rttGizmoLay("Red") FLUSH(3)')
    assert state("MINE") == before, "standing it back up did not restore it: %s" % (state("MINE"),)
    assert rt.eval("#getObjectsWithTag('RTT Laid Disc')") == 0, "the disc outlived the piece being up"

    # any warrior, not only your own
    rt.execute('HOVER["Red"] = THEIRS rttGizmoLay("Red") FLUSH(3)')
    assert state("THEIRS")[1] is True, "numpad 2 refused an opponent's warrior"

    # and nothing that is not a warrior
    rt.execute('HOVER["Red"] = ROOST rttGizmoLay("Red") FLUSH(3)')
    assert state("ROOST")[1] is False, "numpad 2 laid a building down"


def t_the_board_shows_the_build_number(src):
    """One version, on the board, in the mod's cream.

    The maintainer, 2026-09-07: "the mod version should be written in cream white at the top right
    corner of the main setup board", and "do not have a boxscore version since now we only work with
    boxscore integrated to the mod" -- so there is exactly one number and it belongs to the mod.

    It is a STATIC element in bab7e1's saved XmlUI, which is safe because the board only ever calls
    setAttribute on elements that are already there; it never rewrites its own XML. VERSION and the
    stamp are kept in step by tools/bump_version.py, which the pre-commit hook runs.
    """
    save = json.loads(open(os.path.join(REPO, "dist", "Root_Tabletop_Tournament.json"),
                           encoding="utf-8").read())
    board = [o for o in save["ObjectStates"] if o.get("GUID") == BOARD][0]
    m = re.search(r'<Panel id="rttVersion".*?</Panel>', board.get("XmlUI") or "", re.S)
    assert m, "the setup board carries no build number"
    el = m.group(0)

    # drawn large inside a shrunk panel: object XmlUI is magnified onto a scale-15.5 board, so type
    # set at its final size comes out soft. Effective size is fontSize * scale.
    shrink = float(re.search(r'scale="([\d.]+) ', el).group(1))
    font = float(re.search(r'fontSize="(\d+)"', el).group(1))
    assert shrink < 0.5, "the version is drawn at its final size; it will render soft: scale %s" % shrink
    assert font * shrink < 6, "the credit line reads too big on the board: %.1f" % (font * shrink)

    # TWO numbers: major for a real change in what the mod does, minor for everything else.
    shown = re.search(r'text="by MrDrouf v(\d+)\.(\d+)"', el)
    assert shown, 'the corner does not read "by MrDrouf v<major>.<minor>": %s' % el
    on_disk = open(os.path.join(REPO, "VERSION"), encoding="utf-8").read().strip()
    assert "%s.%s" % shown.groups() == on_disk, (
        "the board says v%s.%s but VERSION says %s -- run tools/bump_version.py --restamp"
        % (shown.group(1), shown.group(2), on_disk))

    # Black and SOLID. Cream shouted; dark-at-78%-alpha was unreadable. Quiet comes from the size.
    assert 'color="#000000"' in el, "the credit line is not solid black: %s" % el
    # the RIGHT EDGE is what pins it to the corner: the line is right-aligned, so it grows leftwards
    # and the panel's centre moves as the text gets longer. The board's UI reaches about x 124.
    x, y = (float(v) for v in re.search(r'position="([-\d.]+) ([-\d.]+)', el).groups())
    w, h = (float(v) for v in re.search(r'width="([\d.]+)" height="([\d.]+)"', el).groups())
    right, top = x + w * shrink / 2, y + h * shrink / 2
    assert 110 < right < 124, "the line is not pinned to the right edge: %.1f" % right
    assert top > 88, "the line is not hard against the top: %.1f" % top

    # ONE version, and it belongs to the mod. The sheet used to sign itself "made by MrDrouf . <BUILD>"
    # from a build string of its own; the box score ships inside the mod now, so that is gone --
    # the maintainer, 2026-09-07: "remove the boxscore version ... now they are the same".
    sheet = re.search(r'RTT_BOXSCORE_JSON = \[====\[(.*?)\]====\]', src, re.S)
    assert sheet, "the box score blueprint is not in the build"
    lua = json.loads(sheet.group(1))["LuaScript"]
    code = [ln for ln in lua.split("\n") if not ln.strip().startswith("--")]
    assert not [ln for ln in code if "BUILD" in ln], \
        "the box score has a version of its own again: %s" % [ln for ln in code if "BUILD" in ln][:1]
    assert not [ln for ln in code if "MrDrouf" in ln], \
        "the box score signs itself again; the credit belongs on the board: %s" \
        % [ln for ln in code if "MrDrouf" in ln][:1]


def t_the_panel_pauses_the_clock(src):
    """After START, DEAL 5 CARDS becomes the clock control.

    The maintainer, 2026-09-07: "after start game, the button deal 5 cards become pause to pause the
    clock/ then the button becomes continue / then back again to pause to restop." Dealing is a
    once-per-game job, so its half of the row is free the moment the game is running.

    Resuming must not lose the turn's elapsed time: the pause pushes PANEL_START forward by the length
    of the break rather than restarting it, so the clock picks up exactly where it stopped.
    """
    panel = json.loads(re.search(r"RTT_TURN_PANEL_JSON = \[====\[(.*?)\]====\]", src, re.S).group(1))
    rt = lupa.LuaRuntime(unpack_returned_tuples=True)
    rt.execute(open(os.path.join(HERE, "tts_stub.lua"), encoding="utf-8").read())
    rt.execute("CLOCK = 1000 os.time = function() return CLOCK end")
    rt.execute(panel["LuaScript"].replace("!=", "~="))
    rt.execute("LASTXML = '' self.UI.setXml = function(x) LASTXML = x end")

    def label():
        rt.execute("buildUI()")
        m = re.search(r'id="pnlDeal".*?<Text[^>]*>([^<]*)</Text>', rt.eval("LASTXML"), re.S)
        return m.group(1) if m else None

    def shown():
        rt.execute("panelTick()")
        return rt.eval("PANEL_TTXT")

    assert label() == "DEAL 5 CARDS", "before START the button is not the deal: %s" % label()

    # START shuffles the shared deck, once. "pushing start on the clock should shuffle the deck once
    # as a well" -- starting the game is the moment the deck should be random, and nobody should have
    # to remember to do it. A table with no deck out must not make START fail.
    rt.execute("""
      SHUFFLED = 0
      DECK = MKOBJ('Deck', {0,1,0}, {'Deck Object'})
      DECK.getQuantity = function() return 54 end
      DECK.shuffle = function() SHUFFLED = SHUFFLED + 1 end
      Turns = Turns or {}
    """)
    rt.execute("pcall(panelStart) FLUSH(10)")
    assert rt.eval("SHUFFLED") == 1, "START did not shuffle the deck: %s" % rt.eval("SHUFFLED")
    rt.execute("DECK.destruct() pcall(panelStart) FLUSH(10)")   # no deck on the table

    rt.execute("PANEL_START = CLOCK")                 # the game is running
    assert label() == "PAUSE", "after START the button did not become PAUSE: %s" % label()

    rt.execute("CLOCK = 1030")
    assert shown() == "0:30", "the clock did not run: %s" % shown()

    rt.execute("panelPause()")
    assert label() == "CONTINUE", "pausing did not offer CONTINUE: %s" % label()
    rt.execute("CLOCK = 1200")
    assert shown() == "0:30", "the clock kept running while paused: %s" % shown()

    rt.execute("panelPause()")
    assert label() == "PAUSE", "continuing did not offer PAUSE again: %s" % label()
    assert shown() == "0:30", "resuming lost the turn's elapsed time: %s" % shown()
    rt.execute("CLOCK = 1215")
    assert shown() == "0:45", "the clock did not pick up where it stopped: %s" % shown()


def t_no_warning_when_there_is_nothing_to_wipe(src):
    """The confirm appears when something is going to be taken away, and not otherwise.

    Maintainer, 2026-09-07: "a warning of wipe all factions appeared while there was no faction to
    wipe." The test was "is there a Map Object" -- but the battle mat, the box score and the turn panel
    all carry that tag and all SURVIVE a rebuild, because removeMapItems keeps anything tagged as a
    fixture. So a table holding nothing but its own furniture read as a table full of things to lose,
    and every setup button demanded confirmation for a wipe that would remove nothing.

    It now counts what removeMapItems would actually destroy, which is the same test that does the
    destroying.
    """
    rt = fresh(src)
    fixture = rt.eval("RTT_FIXTURE_TAG")

    # a bare table: nothing at all
    assert rt.eval("rttWouldWipe(false)") is False, "warned on an empty table"
    assert rt.eval("rttWouldWipe(true)") is False, "warned on an empty table for a map button"

    # the panel, the box score and the mat -- all tagged Map Object, all survive a rebuild
    rt.execute("""
      for _, n in ipairs({'Turn Panel', 'Root Box Score', 'Battle Mat'}) do
        MKOBJ(n, {0,1,0}, {'Map Object', %r})
      end
    """ % fixture)
    assert rt.eval("rttWouldWipe(false)") is False, \
        "the table's own furniture counted as something to wipe"
    assert rt.eval("rttWouldWipe(true)") is False, \
        "the table's own furniture counted as a map to replace"

    # a real map piece is a real loss
    rt.execute("MAPBIT = MKOBJ('Ruin', {1,1,1}, {'Map Object'})")
    assert rt.eval("rttWouldWipe(false)") is True, "a map on the table did not warn"
    assert rt.eval("rttWouldWipe(true)") is True, "a map on the table did not warn a map button"

    # ...and the WORDING follows what that button is really about to take away. A setup button clears
    # the factions AND re-places the map, so with no factions out the truthful half is the map --
    # "This will reset the map BUT ONLY IF IT INDEED DOES!!! some buttons do not" (2026-09-07).
    setup = rt.eval("RTT_WIPE_BTN['rttFourBoardsBtn']")
    amap  = rt.eval("RTT_WIPE_BTN['Summer Map']")
    assert rt.eval("rttWarnArt")(setup) == "WipeConfirmMapArt", \
        "a setup button says factions when there are none: %s" % rt.eval("rttWarnArt")(setup)
    assert rt.eval("rttWarnArt")(amap) == "WipeConfirmMapArt", "a map button changed its wording"

    # and so is a faction, on its own
    rt.execute("MAPBIT.destruct() MKOBJ('Eyrie Warrior', {2,1,2}, {'RTT Faction'})")
    assert rt.eval("rttWouldWipe(false)") is True, "a faction on the table did not warn"
    assert rt.eval("rttWarnArt")(setup) == "WipeConfirmArt", \
        "with factions out a setup button must warn about the FACTIONS"
    assert rt.eval("rttWarnArt")(amap) == "WipeConfirmMapArt", \
        "a map button must never claim to reset factions -- it does not touch them"


def t_the_gizmo_follows_the_faction_you_last_picked(src):
    """Pick a faction and numpad 1 comes with you -- but only while the seat and the colour are yours.

    Seat colours cannot answer "which faction is mine": your FIRST pick takes your colour and every
    later pick is deliberately handed a free one, so one person can set out several boards without
    every seat becoming theirs. The gizmo therefore keeps its own note.

    Three ways that note was wrong, all found by audit after it shipped:
      - it was keyed by colour and never invalidated, so a colour that changed hands carried the old
        claim: Alice picks the Marquise as Red and leaves, Bob takes Red, Bob draws Marquise warriors;
      - the earlier version of this test wrote the note by hand and never called rttPlaceFaction, so
        nothing verified that picking a faction records anything at all. It does now.

    The note is not a table beside the seats any more. Each seat records which press created it and in
    what order, so "the faction I last picked" is the newest seat I made -- one record answering the
    question, persisted with the seats and cleared with them.
    """
    def table_with_supplies():
        rt = fresh(src)
        rt.execute("""
          TOOK = {}
          for _, n in ipairs({'Marquise Supply', 'Eyrie Supply'}) do
            local b = MKOBJ(n, {0,1,0}, {})
            b.__n = 5
            b.getQuantity = function() return b.__n end
            b.takeObject = function(p) TOOK[#TOOK+1] = n end
            b.putObject = function(o) end
          end
          POINTER['Red'] = {x = 0, y = 1, z = 0}
        """)
        return rt

    def supply(rt):
        rt.execute("BAG = rttMySupplyBag('Red')")
        b = rt.eval("BAG")
        return b and str(b.getName()) or None

    def pick(rt, faction, x, z):
        rt.execute("pcall(function() rttPlaceFaction(%r, %f, %f, false, 'Red', false, 'Standard', 0, 'Red') end) "
                   "FLUSH(120)" % (faction, x, z))

    # A REAL PICK writes the note
    rt = table_with_supplies()
    rt.execute("SEAT('Red','H1')")
    pick(rt, "Marquise de Cat", 52, -46)
    assert rt.eval("rttMyFaction('Red')") == "Marquise de Cat", \
        "picking a faction did not tell the gizmo whose it is: %r" % rt.eval("rttMyFaction('Red')")
    assert supply(rt) == "Marquise Supply", \
        "numpad 1 did not use the picked faction: %s" % supply(rt)

    # SWITCHING to another seat brings it with you
    pick(rt, "Eyrie Dynasties", -52, -46)
    assert supply(rt) == "Eyrie Supply", \
        "numpad 1 stayed on the first faction: %s" % supply(rt)

    # IT SURVIVES A RELOAD
    saved = rt.eval("onSave()")
    rt2 = table_with_supplies()
    rt2.execute("SEAT('Red','H1')")
    rt2.execute("pcall(function() onLoad(%s) end) FLUSH(6)" % json.dumps(saved))
    assert rt2.eval("rttMyFaction('Red')") == "Eyrie Dynasties", \
        "the pick did not survive a reload: %r" % rt2.eval("rttMyFaction('Red')")

    # A COLOUR THAT CHANGES HANDS does not carry the claim.
    # The note and the seat record disagree here on purpose: Alice's second pick was handed a free
    # colour, so the record still says Red = Marquise while the note says Eyrie. That gap is the whole
    # reason the note exists -- and it must belong to Alice, not to the colour she was using.
    rt3 = table_with_supplies()
    rt3.execute("SEAT('Red','Alice')")
    pick(rt3, "Marquise de Cat", 52, -46)
    pick(rt3, "Eyrie Dynasties", -52, -46)
    assert rt3.eval("rttMyFaction('Red')") == "Eyrie Dynasties", "Alice's own last pick was lost"

    rt3.execute("SEAT('Red','Bob') FLUSH(2)")      # same colour, different person
    assert rt3.eval("rttMyFaction('Red')") == "Marquise de Cat", \
        "Bob inherited Alice's last pick instead of falling back to the seat he is actually in: %r" \
        % rt3.eval("rttMyFaction('Red')")

    # A NEW GAME forgets it -- the seats go, and the pick goes with them because it IS a seat field
    rt.execute("rttResetRunState()")
    assert rt.eval("#RTT_SEATS") == 0, "a new game kept last game's seats"
    assert rt.eval("rttMyFaction('Red')") is None, "a new game kept last game's pick"


def t_numpad_three_lights_the_piece_instead(src):
    """Numpad 3 is numpad 2 with a glow instead of a disc.

    Maintainer, 2026-09-07: "a gizmo numpad 3 that does the same but instead of the circle it does a
    highlight. its an option that should exists. another way to emphasiwe the piece on the map." Same
    action either way -- down, locked, press again to undo -- so the two share one path and the record
    remembers WHICH mark was used. A piece marked one way must never be left with the other's leftovers.
    """
    rt = fresh(src)
    rt.execute("""
      W = MKOBJ("Eyrie Warrior", {1,1,1}, {})
      W.__bounds = {size = Vector({1, 3, 1}), center = Vector({1, 2.5, 1})}
    """)

    rt.execute('HOVER["Red"] = W rttGizmoGlow("Red") FLUSH(3)')
    glow = rt.eval("W.__glow")
    assert glow is not None, "numpad 3 did not light the piece"
    red = rt.eval("RTT_PLAYER_RGB['Red']")
    assert round(glow.r, 3) == round(red[1], 3), "the glow is not the presser's colour: %s" % glow.r
    assert rt.eval("W.getLock()") is True, "numpad 3 did not lock the piece"
    assert rt.eval("#getObjectsWithTag('RTT Laid Disc')") == 0, \
        "numpad 3 drew a disc as well; it is the alternative to one, not an addition"

    # pinned at the press, exactly as the disc is
    rt.execute("SEAT('Yellow', Player['Red'].steam_name) onPlayerChangeColor('Yellow') FLUSH(5)")
    assert round(rt.eval("W.__glow").r, 3) == round(red[1], 3), \
        "changing colour repainted the glow; it is pinned at the press"

    # and pressing again puts everything back
    rt.execute('HOVER["Red"] = W rttGizmoGlow("Red") FLUSH(3)')
    assert rt.eval("W.__glow") is None, "the glow outlived the piece being stood up"
    assert rt.eval("W.getLock()") is False, "the piece stayed locked"


def t_start_does_not_arm_a_suppression_it_never_uses(src):
    """START must not leave the sheet's one-shot armed, or it eats the first real turn.

    The panel armed `rttSuppressNextLock` unconditionally and then moved the turn ONLY if the colour
    differed. START is normally pressed when it is already seat 1's turn -- rttEnableTurns has just set
    turn_color to seat 1 -- so no pass fired, nothing consumed the flag, and it sat armed until it
    swallowed the first REAL turn of the game. The flag is cleared in exactly one place, inside
    onPlayerTurn.

    That is the missing round reported over and over, and it survived five separate START fixes because
    the panel's own script has never been executed by a test. This runs it.
    """
    panel = json.loads(re.search(r"RTT_TURN_PANEL_JSON = \[====\[(.*?)\]====\]", src, re.S).group(1))
    rt = lupa.LuaRuntime(unpack_returned_tuples=True)
    rt.execute(open(os.path.join(HERE, "tts_stub.lua"), encoding="utf-8").read())
    rt.execute("CLOCK = 1000 os.time = function() return CLOCK end")
    rt.execute(panel["LuaScript"].replace("!=", "~="))
    rt.execute("""
      CALLS = {}
      SHEET = MKOBJ("Root Box Score", {0,1,0}, {"RTT Box Score"})
      SHEET.call = function(fn)
        CALLS[#CALLS+1] = fn
        if fn == "rttHasData" then return false end
        return true
      end
      sheet = function() return SHEET end
      self.UI.setXml = function() end
      Turns.order = {"Red", "Yellow"}
      Turns.enable = true
    """)

    def press(turn_color):
        rt.execute("CALLS = {} Turns.turn_color = %r pcall(panelStart) FLUSH(20)" % turn_color)
        return [str(v) for v in (rt.eval("CALLS") or {}).values()]

    # ALREADY seat 1's turn: no pass will fire, so nothing may be armed
    said = press("Red")
    assert "rttSuppressNextLock" not in said, (
        "START armed the sheet's one-shot without causing a pass; it will swallow the first real "
        "turn of the game: %s" % said)
    assert "rttResetAndStart" in said, "START did not reset the sheet: %s" % said

    # somebody ELSE holds the turn: a pass is coming, so it must be armed before the turn moves
    said = press("Yellow")
    assert "rttSuppressNextLock" in said, (
        "START moved the turn without arming the one-shot; the pass it causes will be recorded as a "
        "completed turn at 0: %s" % said)
    assert said.index("rttSuppressNextLock") < said.index("rttResetAndStart"), \
        "the one-shot must be armed BEFORE the pass it is meant to swallow: %s" % said
    assert rt.eval("Turns.turn_color") == "Red", "START did not hand the turn to seat 1"


def t_a_reload_keeps_two_vagabonds_apart(src):
    """A saved seat must come back as the same seat -- ordinal included, and with no holes.

    TWO FAULTS IN ONE FUNCTION, both found by audit:

    onSave persisted pos/color/faction/owner/hand and NOT `key` or `vagN`. rttSeatRecord rebuilds a
    missing key with rttFactionKey(faction), which answers "Vagabond" for every vagabond -- so after a
    reload both vagabond seats published under one key, the same Global entry was written twice, and
    the second lost its colour, its owner and its position. Its VP marker was still "Vagabond 2 VP".

    And onSave skips a seat with no position, so the seat NUMBERS it writes can have holes; restoring
    into RTT_SEATS[e.i] reproduced the hole, and eight separate ipairs(RTT_SEATS) loops stop dead at
    the first one -- the turn order, the published record, the free-colour search, the vagabond
    ordinal, rttSeatFaction.
    """
    rt = fresh(src)
    rt.execute("""
      RTT_SEATS = {
        { pos = {  52, -46 }, color = "Red",    faction = "Ranger", key = "Vagabond",   vagN = 1 },
        { pos = { -52, -46 }, color = "Yellow", faction = "Thief",  key = "Vagabond 2", vagN = 2 },
        { pos = {  52,  46 }, color = "Orange", faction = "Marquise de Cat", key = "Marquise de Cat" },
      }
    """)
    saved = rt.eval("onSave()")
    assert saved, "onSave produced nothing"

    rt2 = fresh(src)
    rt2.execute("pcall(function() onLoad(%s) end) FLUSH(6)" % json.dumps(saved))

    keys = [str(v) for v in rt2.eval(
        "function() local t = {} for _, s in ipairs(RTT_SEATS) do t[#t+1] = s.key or '?' end return t end")().values()]
    assert keys == ["Vagabond", "Vagabond 2", "Marquise de Cat"], \
        "the seats' own keys did not survive the reload: %s" % keys

    pub = json.loads(rt2.eval("GVGET('RTT_SEAT_COLOR')"))
    assert pub.get("Vagabond") == "Red" and pub.get("Vagabond 2") == "Yellow", \
        "the two vagabonds collapsed onto one published key: %s" % pub

    # A HOLE MUST NOT SURVIVE EITHER. A seat with no position is dropped by onSave, so the numbers it
    # writes skip one -- and every ipairs over the array would stop there.
    rt3 = fresh(src)
    rt3.execute("""
      RTT_SEATS = {
        { pos = {  52, -46 }, color = "Red",    faction = "Marquise de Cat", key = "Marquise de Cat" },
        { color = "Yellow", faction = "Eyrie Dynasties", key = "Eyrie Dynasties" },   -- no pos: dropped
        { pos = {  52,  46 }, color = "Orange", faction = "The Lizard Cult", key = "The Lizard Cult" },
      }
    """)
    saved3 = rt3.eval("onSave()")
    rt4 = fresh(src)
    rt4.execute("pcall(function() onLoad(%s) end) FLUSH(6)" % json.dumps(saved3))
    n_ipairs = rt4.eval("function() local n = 0 for _ in ipairs(RTT_SEATS) do n = n + 1 end return n end")()
    assert n_ipairs == 2, \
        "ipairs stops at the hole the dropped seat left: reached %s of 2 seats" % n_ipairs
    pub3 = json.loads(rt4.eval("GVGET('RTT_SEAT_COLOR')"))
    assert pub3.get("The Lizard Cult") == "Orange", \
        "the seat after the hole never reached the published record: %s" % pub3


def t_a_new_game_forgets_last_games_seat_count(src):
    """No fabricated turn order may reach the sheet.

    RTT_TURN_SEATS was not cleared by rttResetRunState, so it outlived the seats it counted. On the
    ranked path rttNewGame(nil) deliberately does not set the turn system up -- the real seating does,
    ten seconds later, once the cards have been dealt. In between, the record is empty but the count
    still says 5, so one colour change ran rttEnableTurns(5) against no seats at all: the order fell
    back to the static Red..Green list and rttPublishSeats published {} -- which the box score caches
    and treats as the truth.

    Also covered: the six-colour literal that onLoad assigned on every single load, after the seat
    record had already been restored and published. It is the line the commit that first switched the
    turn system on named as the reason nothing worked.
    """
    assert 'Turns.order =   {"Red","Yellow","Orange","Teal","Green","Brown"}' not in src, \
        "onLoad still overwrites the turn order with a literal on every load"

    rt = fresh(src)
    rt.execute("SEAT('Red','H1') SEAT('Yellow','H2')")
    rt.execute("pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(60)")
    assert rt.eval("RTT_TURN_SEATS") == 4, "the manual path did not record its seat count"

    # a new game must not inherit it
    rt.execute("pcall(rttResetRunState) FLUSH(5)")
    assert rt.eval("RTT_TURN_SEATS") is None, \
        "last game's seat count survived: %s" % rt.eval("RTT_TURN_SEATS")

    # and with no count, a colour change mid-draft cannot rebuild an order out of nothing
    rt.execute("Turns.order = {} Turns.enable = false RTT_SEATS = {}")
    rt.execute("Global.setVar('RTT_SEAT_RECORD', 'sentinel')")
    rt.execute("onPlayerChangeColor('Red') FLUSH(10)")
    order = list((rt.eval("Turns.order") or {}).values())
    assert order == [], "a colour change invented a turn order from an empty record: %s" % order
    assert rt.eval("GVGET('RTT_SEAT_RECORD')") == "sentinel", \
        "an empty seat record was published over the real one"


def t_a_real_turn_cycle_runs_in_seat_order(src):
    """Drive the TTS turn system for real, which no test in this project has ever done.

    `Turns` was a bare recording table in the harness: nothing advanced turn_color and nothing fired an
    event, so every test that mentioned turn order was asserting on a value it had written itself. The
    one thing reported broken version after version -- "how unstable boxscore is and how it does not
    work resiliently with the TTS turn order" -- had never been executed at all.

    The engine reproduces what TTS actually does, including the parts this project learned the hard
    way: the event is delivered late, assigning turn_color the colour it ALREADY holds still fires it,
    and reading turn_color straight back returns the OUTGOING colour.
    """
    rt = fresh(src)
    for i, c in enumerate(("Red", "Yellow", "Orange", "Teal")):
        rt.execute("SEAT(%r,'H%d')" % (c, i + 1))
    rt.execute("pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(60)")
    rt.execute("onPlayerChangeColor('Red') FLUSH(20)")

    order = list(rt.eval("Turns.order").values())
    assert order == ["Red", "Yellow", "Orange", "Teal"], "the seat order is wrong: %s" % order
    assert rt.eval("Turns.enable") is True, "seating did not start the turn system"

    # TWO WHOLE ROUNDS, colour by colour
    rt.execute("TURN_EVENTS = {} TURN_ROUND(2) FLUSH(30)")
    seen = [str(v) for v in rt.eval("TURN_EVENTS").values()]
    assert len(seen) == 8, "two rounds of four seats delivered %d events: %s" % (len(seen), seen)
    assert seen[0].startswith("Yellow<-Red") and seen[3].startswith("Red<-Teal"), \
        "the cycle did not run in seat order: %s" % seen[:4]
    assert rt.eval("Turns.turn_color") == "Red", \
        "two full rounds did not come back to seat 1: %s" % rt.eval("Turns.turn_color")

    # THE EVENT IS LATE. Reading turn_color straight back must give the OUTGOING colour -- this is
    # what made the panel's clock fire twice.
    rt.execute("TURN_LAG = 2 Turns.turn_color = 'Orange'")
    assert rt.eval("Turns.turn_color") == "Red", \
        "turn_color read back as the incoming colour; the real one lands with the event"
    rt.execute("FLUSH(10)")
    assert rt.eval("Turns.turn_color") == "Orange", "the turn never landed"
    rt.execute("TURN_LAG = 0")

    # ASSIGNING THE COLOUR IT ALREADY HOLDS STILL FIRES. The costliest wrong assumption in this
    # project's history, and the reason START recorded a phantom turn.
    rt.execute("TURN_EVENTS = {} Turns.turn_color = 'Orange' FLUSH(10)")
    assert len(rt.eval("TURN_EVENTS")) == 1, \
        "re-assigning the current colour fired no event; TTS fires one"

    # A COLOUR CHANGE MID-GAME MUST NOT REWIND THE TURN
    rt.execute("Turns.turn_color = 'Teal' FLUSH(5) onPlayerChangeColor('Yellow') FLUSH(20)")
    assert rt.eval("Turns.turn_color") == "Teal", \
        "somebody changing colour handed the turn back to seat 1: %s" % rt.eval("Turns.turn_color")

    # AND THE SYSTEM LATCHES ON: standing up must not switch it off
    rt.execute("ROSTER = {} onPlayerChangeColor('Grey') FLUSH(20)")
    assert rt.eval("Turns.enable") is True, "a player leaving switched the turn system off"


def t_the_turn_system_survives_what_players_actually_do(src):
    """The recurrence list, driven for real against the turn engine.

    Every case here is something this project fixed and then broke again, taken from the history
    audit: the turn system switching itself off, the order being rebuilt from a static list, the turn
    rewinding to seat 1, and a stale seat count outliving its seats. Nothing exercised any of it
    before, because the harness had no turn engine.
    """
    def seated_table():
        rt = fresh(src)
        for i, c in enumerate(("Red", "Yellow", "Orange", "Teal")):
            rt.execute("SEAT(%r,'H%d')" % (c, i + 1))
        rt.execute("pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(60)")
        rt.execute("onPlayerChangeColor('Red') FLUSH(20)")
        return rt

    # 1. SOMEBODY STANDS UP MID-GAME. It used to drop Turns.enable and hand the turn back to seat 1,
    #    and switching it on again re-fired TTS's notification.
    rt = seated_table()
    rt.execute("TURN_ROUND(1) FLUSH(20)")
    at = rt.eval("Turns.turn_color")
    rt.execute("ROSTER = {} onPlayerChangeColor('Grey') FLUSH(20)")
    assert rt.eval("Turns.enable") is True, "a player standing up switched the turn system off"
    assert rt.eval("Turns.turn_color") == at, \
        "a player standing up rewound the turn: %s -> %s" % (at, rt.eval("Turns.turn_color"))

    # 2. A LATE JOINER must not rewind the turn either.
    rt = seated_table()
    rt.execute("TURN_SET('Orange') FLUSH(10)")
    rt.execute("SEAT('Green','H5') onPlayerChangeColor('Green') FLUSH(20)")
    assert rt.eval("Turns.turn_color") == "Orange", \
        "somebody joining handed the turn back to seat 1: %s" % rt.eval("Turns.turn_color")

    # 3. EMPTY SEATS STILL TAKE TURNS. skip_empty_hands must stay off, or a solo table stops on the
    #    first unoccupied colour and never comes round.
    assert rt.eval("Turns.skip_empty_hands") is False, \
        "empty seats are being skipped; a solo table would never come round"
    rt2 = fresh(src)
    rt2.execute("SEAT('Red','solo')")
    rt2.execute("pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(60)")
    rt2.execute("onPlayerChangeColor('Red') FLUSH(20) TURN_EVENTS = {} TURN_ROUND(1) FLUSH(20)")
    assert len(rt2.eval("TURN_EVENTS")) == 4, \
        "one seated player could not drive a four-seat round: %s" \
        % [str(v) for v in rt2.eval("TURN_EVENTS").values()]

    # 4. THE ORDER IS THE SEATS, never a static list. Move a board and the order must follow it.
    rt3 = seated_table()
    before = list(rt3.eval("Turns.order").values())
    for fac, x, z in (("Marquise de Cat", 52, -46), ("Eyrie Dynasties", -52, -46)):
        rt3.execute("pcall(function() rttPlaceFaction(%r, %f, %f, false, nil, false, 'Standard', 0, nil) end) "
                    "FLUSH(120)" % (fac, x, z))
    assert rt3.eval("#RTT_SEATS") >= 2, "the picks did not create seats"
    rt3.execute("RTT_SEATS[1].color = 'Pink' pcall(rttPublishSeats) "
                "pcall(function() rttEnableTurns(#RTT_SEATS, Turns.turn_color) end) FLUSH(20)")
    after = list(rt3.eval("Turns.order").values())
    assert "Pink" in after, "the order did not follow the seat record: %s -> %s" % (before, after)
    assert len(set(after)) == len(after), "the order repeated a colour: %s" % after


def t_a_duplicate_or_late_pass_cannot_invent_a_round(src):
    """TTS delivers a pass twice, and late. Neither may add a round to the sheet.

    A re-delivered pass does not merely lock twice -- it INVENTS A ROUND, because lockRow reads "this
    row already locked this round" as proof the table came round. The guard for it shipped on
    2026-09-07 and has never been seen at a table; nothing could drive it, because the harness could
    not deliver a duplicate.
    """
    panel = json.loads(re.search(r"RTT_TURN_PANEL_JSON = \[====\[(.*?)\]====\]", src, re.S).group(1))
    rt = lupa.LuaRuntime(unpack_returned_tuples=True)
    rt.execute(open(os.path.join(HERE, "tts_stub.lua"), encoding="utf-8").read())
    rt.execute("CLOCK = 1000 os.time = function() return CLOCK end")
    rt.execute(panel["LuaScript"].replace("!=", "~="))
    rt.execute("""
      self.UI.setXml = function() end
      SHEET = MKOBJ("Root Box Score", {0,1,0}, {"RTT Box Score"})
      SHEET.call = function(fn) if fn == "rttRound" then return ROUND end return true end
      sheet = function() return SHEET end
      ROUND = 1
      Turns.enable = true
      Turns.order = {"Red","Yellow","Orange","Teal"}
    """)

    # the panel's clock restarts on a turn CHANGE, and must not restart on a repeat of the same one
    rt.execute("TURN_SET('Red') FLUSH(5) panelTick() PANEL_START = CLOCK")
    rt.execute("CLOCK = 1030 TURN_SET('Yellow') FLUSH(5) panelTick()")
    assert rt.eval("PANEL_TTXT") == "0:00", "the clock did not restart on a real turn change"
    rt.execute("CLOCK = 1045 TURN_REDELIVER() FLUSH(5) panelTick()")
    assert rt.eval("PANEL_TTXT") == "0:15", \
        "a re-delivered pass restarted the turn clock: %s" % rt.eval("PANEL_TTXT")


def t_the_record_names_the_row_the_sheet_will_look_up(src):
    """RTT publishes what the SHEET calls each seat, not only what RTT calls it.

    The two names differ -- "Marquise de Cat" here, "Marquise" on the sheet -- and the sheet bridged
    them with a hand-written twelve-entry table of its own. A thirteenth faction, or a rename on
    either side, silently cost that seat its colour, its owner and its position, with no error. We
    already own the map that table duplicates, so we publish the answer.

    A vagabond's row name is its ordinal one -- "Vagabond 2" -- and never the character.
    """
    rt = fresh(src)
    rt.execute("""
      RTT_SEATS = {
        { pos = {  52, -46 }, color = "Red",    faction = "Marquise de Cat", key = "Marquise de Cat" },
        { pos = { -52, -46 }, color = "Yellow", faction = "Lord of the Hundreds", key = "Lord of the Hundreds" },
        { pos = {  52,  46 }, color = "Orange", faction = "Ranger", key = "Vagabond 2", vagN = 2 },
      }
      pcall(rttPublishSeats)
    """)
    rec = json.loads(rt.eval('GVGET("RTT_SEAT_RECORD")'))
    rows = {e["key"]: e.get("row") for e in rec["seats"]}
    assert rows.get("Marquise de Cat") == "Marquise", \
        "the long id was published with no row name: %s" % rows
    assert rows.get("Lord of the Hundreds") == "Rats", \
        "the rats' row name is not the sheet's: %s" % rows
    assert rows.get("Vagabond 2") == "Vagabond 2", \
        "a vagabond's row must be its ordinal name, never the character: %s" % rows
    for e in rec["seats"]:
        assert e.get("row"), "a seat was published with no row name: %s" % e


def t_an_unclaimed_seat_takes_a_colour_the_sheet_knows(src):
    """A free colour must be one the turn order and the sheet can both use.

    The audit read this as a live defect and it was not: RTT_ALL_COLORS already begins with exactly
    the six seating colours, in the same order, so walking all ten reached them first anyway. This
    passes on the build before the change too, and is here as a GUARD rather than as proof of a fix --
    the rule was resting on the order of a list nobody would think to keep, and now it is written down
    in both places.
    """
    rt = fresh(src)
    setup = [str(v) for v in rt.eval("RTT_SETUP_COLORS").values()]
    rt.execute("RTT_SEATS = { { pos = {52,-46}, color = 'Red' } }")
    for _ in range(len(setup) - 1):
        got = rt.eval("rttFreeSeatColor()")
        assert got in setup, "an unclaimed seat was handed %r, which is not a seating colour" % got
        rt.execute("RTT_SEATS[#RTT_SEATS+1] = { pos = {0,0}, color = %r }" % got)

    # only once all six are gone may it reach outside them
    got = rt.eval("rttFreeSeatColor()")
    assert got is not None and got not in setup, \
        "with every seating colour taken it should still find one: %r" % got


def t_one_writer_owns_a_seats_colour(src):
    """No two seats may share a colour, and nothing may reassign one behind the draft's back.

    A seat's colour was assigned in four places -- the draft's seating loop, the empty-seat filler
    beside it, the faction pick, and the gap-filler -- each carrying its own copy of the same two
    rules, and each the site of a bug: at four players P3 and P4 held each other's colour in every
    game, and a manual board placing two factions from one spot let the second silently take the
    first's colour, its owner and its turn slot.

    The colour owns the hand, the cards and the slot in Turns.order, so a duplicate does not merely
    confuse a lookup -- it hands one player another's cards.
    """
    rt = fresh(src)
    rt.execute("""
      RTT_SEATS = {
        { pos = {  52, -46 }, color = "Red" },
        { pos = { -52, -46 } },
        { pos = {  52,  46 } },
      }
    """)
    # a colour another seat already holds is refused
    assert rt.eval("rttSetSeatColor(RTT_SEATS[2], 'Red')") is None, \
        "a second seat was allowed to take a colour already in use"
    assert rt.eval("RTT_SEATS[2].color") is None, "and it wrote it anyway"

    # a free one is taken
    assert rt.eval("rttSetSeatColor(RTT_SEATS[2], 'Yellow')") == "Yellow"

    # a seat that has a colour KEEPS it -- reassigning takes a player's hand away
    assert rt.eval("rttSetSeatColor(RTT_SEATS[2], 'Orange')") == "Yellow", \
        "an occupied seat's colour was quietly reassigned"
    assert rt.eval("RTT_SEATS[2].color") == "Yellow"

    # ...unless the caller means it, which is what the draft does after parking everyone in Grey
    assert rt.eval("rttSetSeatColor(RTT_SEATS[2], 'Orange', true)") == "Orange", \
        "the draft could not reassign a seat it had deliberately freed"

    # AND THE RULE HOLDS THROUGH A REAL SETUP, at every seat count
    for n, arg in ((4, "nil"), (5, "'fivePlayerSetup'")):
        rt2 = fresh(src)
        for i, c in enumerate(("Red", "Yellow", "Orange", "Teal", "Green")[:n]):
            rt2.execute("SEAT(%r,'H%d')" % (c, i + 1))
        rt2.execute("pcall(function() setupFactionBoards(nil,nil,%s) end) FLUSH(60)" % arg)
        for i, (fac, x, z) in enumerate((("Marquise de Cat", 52, -46), ("Eyrie Dynasties", -52, -46),
                                         ("Woodland Alliance", 52, 46), ("The Lizard Cult", -52, 46),
                                         ("Riverfolk Company", 0, -46))[:n]):
            rt2.execute("pcall(function() rttPlaceFaction(%r,%f,%f,false,nil,false,'Standard',0,%r) end) "
                        "FLUSH(120)" % (fac, x, z, ("Red", "Yellow", "Orange", "Teal", "Green")[i]))
        cols = [str(rt2.eval("RTT_SEATS[%d].color" % (i + 1)) or "") for i in range(int(rt2.eval("#RTT_SEATS")))]
        assert all(cols), "%d seats: a seat ended with no colour: %s" % (n, cols)
        assert len(set(cols)) == len(cols), "%d seats: two seats share a colour: %s" % (n, cols)


def t_the_faction_pick_survives_a_reload(src):
    """A save in the middle of the draft must not leave the pick unfinishable.

    Which seat a selector board belongs to lived in two tables beside the seats -- one keyed by board
    guid, one by colour -- each indexing a fact the seat already held in s.board. Neither survived a
    save, and s.board is deliberately not restored because TTS re-creates the objects with new guids.
    So a reload during the faction pick left BOTH empty: the pick handler found no seat and returned,
    the menus were never re-lit, and the draft could not be finished while the record still said the
    game was live.

    A selector board standing at a seat's position IS that seat's board, so the handle is re-attached
    from the table instead of being remembered.
    """
    rt = fresh(src)
    rt.execute("""
      RTT_SEATS = {
        { pos = {  52, -46 }, color = "Red",    hand = { pos = {52,12,-64}, rot = {0,0,0} } },
        { pos = { -52, -46 }, color = "Yellow", hand = { pos = {-52,12,-64}, rot = {0,0,0} } },
      }
      RTT_DRAFT_FACTIONS = { "Marquise de Cat", "Eyrie Dynasties" }
      RTT_FAC_TAKEN = {}
    """)
    saved = rt.eval("onSave()")

    # RELOAD: a fresh board script, the seats restored, the boards back on the table as new objects
    rt2 = fresh(src)
    rt2.execute("pcall(function() onLoad(%s) end) FLUSH(6)" % json.dumps(saved))
    assert rt2.eval("RTT_SEATS[1].board") is None, "the fixture did not reproduce a lost handle"
    rt2.execute("""
      B1 = MKOBJ("", { 52, 11.56, -46 }, { RTT_SELECTOR_TAG })
      B2 = MKOBJ("", { -52, 11.56, -46 }, { RTT_SELECTOR_TAG })
      RTT_DRAFT_FACTIONS = { "Marquise de Cat", "Eyrie Dynasties" }
      RTT_FAC_TAKEN = {}
    """)

    # the board can be matched back to its seat...
    assert rt2.eval("rttSeatOfBoard(B1.getGUID())") == 1, \
        "a selector standing at seat 1 was not recognised as seat 1's board"
    assert rt2.eval("rttSeatOfBoard(B2.getGUID())") == 2

    # ...and the colour lookup finds it again too, which is what re-lights the menus
    rt2.execute("C = rttCloneFor('Yellow')")
    assert rt2.eval("C") is not None, "the seat's board could not be found from its colour"
    assert str(rt2.eval("C.getGUID()")) == str(rt2.eval("B2.getGUID()")), \
        "the wrong board was matched to that seat"

    # and a pick on it now goes through, where before the reload it silently did nothing
    rt2.execute("pcall(function() rttCoordFaction({ color = 'Red', id = 'rttFac1', "
                "board = B1.getGUID() }) end) FLUSH(120)")
    assert rt2.eval("RTT_SEATS[1].faction") == "Marquise de Cat", \
        "the pick did not reach the seat after a reload: %r" % rt2.eval("RTT_SEATS[1].faction")


CASES = [
    ("manual path drives the turn system",   t_manual_turn_order),
    ("manual path spawns 4 / 5 boards",      t_boards_spawn),
    ("a new game resets run state",          t_new_game_resets_state),
    ("Clear All resets run state",           t_clear_all_resets_run_state),
    ("clearing markers forgets the map",     t_destroying_priority_markers_forgets_their_map),
    ("manual path records its seats",        t_the_manual_path_records_its_seat_count),
    ("map click swallowed while busy",       t_a_map_click_is_swallowed_while_busy),
    ("map hooks carry a generation",         t_deferred_map_hooks_carry_a_generation),
    ("stale showFactions cannot unlock",     t_a_stale_show_factions_cannot_unlock_the_next_game),
    ("order cards cleared by a new game",    t_order_cards_do_not_survive_a_new_game),
    ("duchy burrow spawns locked",           t_the_duchy_burrow_spawns_locked),
    ("camera states are the host's",         t_camera_states_are_the_hosts),
    ("turn panel is the only clock",      t_the_turn_panel_is_the_only_clock),
    ("no warning with nothing to wipe",   t_no_warning_when_there_is_nothing_to_wipe),
    ("gizmo follows your last pick",      t_the_gizmo_follows_the_faction_you_last_picked),
    ("panel flashes past 20 minutes",      t_the_panel_flashes_after_twenty_minutes),
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
    ("a real turn cycle runs",            t_a_real_turn_cycle_runs_in_seat_order),
    ("turn system survives players",     t_the_turn_system_survives_what_players_actually_do),
    ("a duplicate pass invents nothing",  t_a_duplicate_or_late_pass_cannot_invent_a_round),
    ("vagabond published as a faction",       t_vagabond_is_published_as_a_faction),
    ("mountain deals a legal board",          t_mountain_deals_a_legal_board),
    ("maps shuffle once, uniformly",         t_maps_shuffle_once_and_uniformly),
    ("5P marsh ruins stay central",          t_five_player_marsh_ruins_stay_central),
    ("a map click leaves 5P mode",           t_a_map_click_leaves_five_player_mode),
    ("marsh 4P rebuilds after 5P",          t_marsh_after_5p_marsh_rebuilds_the_4p_board),
    ("a click is userdata, not a table",    t_a_button_click_is_recognised_when_the_player_is_userdata),
    ("new game refreshes the map",          t_a_new_game_refreshes_the_map_but_keeps_the_board),
    ("fixtures survive a map change",       t_table_fixtures_survive_a_map_change),
    ("every new-game button leaves 5P",     t_every_new_game_button_leaves_the_five_player_marsh),
    ("5-player buttons warn first",         t_the_five_player_buttons_warn_before_wiping),
    ("a dead handle cannot crash us",       t_a_destroyed_object_cannot_crash_the_map_scan),
    ("map buttons warn before wiping",       t_map_buttons_warn_before_wiping),
    ("gizmo default key is numpad 0",         t_gizmo_default_key_is_numpad_zero),
    ("gizmo: warrior to/from supply",         t_gizmo_warrior_to_and_from_supply),
    ("gizmo reads every blueprint",           t_gizmo_reads_every_faction_from_its_blueprint),
    ("gizmo works without the seat map",      t_gizmo_finds_your_supply_without_the_published_map),
    ("UI cleared before destroy",             t_ui_objects_clear_their_xml_before_being_destroyed),
    ("published colour == seated player",     t_published_colour_matches_the_seated_player),
    ("seat colour is the turn order",        t_seat_colour_is_the_turn_order),
    ("turn order clockwise from BR",         t_turn_order_is_clockwise_from_bottom_right),
    ("seat record survives a reload",        t_seat_record_survives_a_reload),
    ("reload keeps vagabonds apart",      t_a_reload_keeps_two_vagabonds_apart),
    ("new game forgets the seat count",   t_a_new_game_forgets_last_games_seat_count),
    ("manual pick binds picker colour",      t_manual_pick_binds_the_pickers_own_colour),
    ("seat record is pushed to sheet",       t_the_seat_record_is_pushed_to_the_sheet),
    ("record names the sheet row",       t_the_record_names_the_row_the_sheet_will_look_up),
    ("a free colour is a seat colour",    t_an_unclaimed_seat_takes_a_colour_the_sheet_knows),
    ("gizmo never takes another supply",     t_gizmo_never_reaches_into_someone_elses_supply),
    ("send home fills rightmost empty",      t_send_home_fills_the_rightmost_empty_slot),
    ("fill runs from the player's right", t_send_home_fills_from_the_players_own_right),
    ("return slots are not spawn spots",     t_return_slots_are_not_spawn_positions),
    ("extra slots face like the rest",       t_extra_return_slots_face_the_same_way),
    ("one seat holds one faction",           t_one_seat_holds_one_faction),
    ("one writer owns seat colour",       t_one_writer_owns_a_seats_colour),
    ("the pick survives a reload",        t_the_faction_pick_survives_a_reload),
    ("vagabond published under faction",     t_a_vagabond_is_published_under_its_faction_name),
    ("two vagabonds, one marker each",       t_two_vagabonds_get_one_marker_each),
    ("selector icons load with table",     t_every_selector_icon_is_downloaded_with_the_table),
    ("dragon god goes out with lizards",  t_the_dragon_god_goes_out_with_its_faction),
    ("placement ignores board size",       t_placement_never_asks_the_board_how_big_it_is),
    ("send home asks no permission",      t_send_home_asks_no_permission),
    ("numpad 2 lays a warrior down",      t_numpad_two_lays_a_warrior_down_and_back_up),
    ("numpad 3 lights the piece",         t_numpad_three_lights_the_piece_instead),
    ("board shows the build number",      t_the_board_shows_the_build_number),
    ("panel pauses the clock",            t_the_panel_pauses_the_clock),
    ("start arms only a real pass",       t_start_does_not_arm_a_suppression_it_never_uses),
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
