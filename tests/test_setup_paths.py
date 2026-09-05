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
    """The manual path must switch the TTS turn system on, in seat order."""
    for arg, n, want in (("nil", 4, ["Red", "Yellow", "Orange", "Teal"]),
                         ("'fivePlayerSetup'", 5, ["Red", "Yellow", "Orange", "Teal", "Green"])):
        rt = fresh(src)
        rt.execute("pcall(function() setupFactionBoards(nil,nil,%s) end) FLUSH(10)" % arg)
        order = list((rt.eval("Turns.order") or {}).values())
        assert rt.eval("Turns.enable") is True, "%d seats: turn system left off" % n
        assert order == want, "%d seats: order %s, wanted %s" % (n, order, want)
        assert rt.eval("Turns.turn_color") == "Red", "%d seats: seat 1 does not start" % n
        assert rt.eval("Turns.skip_empty_hands") is False, "%d seats: would skip empty seats" % n


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


def t_frog_enclaves_are_bigger(src):
    """The maintainer asked for +20% on every enclave; all twelve must move together."""
    rt = fresh(src)
    d = rt.eval('EVERYTHING["Standard"]["Lilypad Diaspora"]["data"]')
    scales = []
    for i in range(1, len(d) + 1):
        j = json.loads(d[i].json)
        if j.get("Nickname") == "Enclave":
            scales.append(round(j["Transform"]["scaleX"], 6))
    assert len(scales) == 12, "expected 12 enclaves, found %d" % len(scales)
    assert len(set(scales)) == 1, "enclaves came out at mixed sizes: %s" % sorted(set(scales))
    assert abs(scales[0] / 0.703911364 - 1.2) < 0.001, \
        "enclave scale %s is not 20%% over the original 0.703911364" % scales[0]


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
    ("frog enclaves are 20% bigger",          t_frog_enclaves_are_bigger),
    ("enclaves sit where they are dropped",   t_enclaves_do_not_snap),
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
