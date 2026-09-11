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
import json, math, os, re, subprocess, sys
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

    It does not switch it ON. Setting boards out is not the start of a game -- the maintainer,
    2026-09-05: "the turn order should get started only when a player is seated, now it also starts
    when I select 4 player setup" -- and neither is sitting down, 2026-09-09: "don t enable turns
    until start is pressed." People take their seats, pick factions and lay their boards out long
    before anybody plays.

    So the ORDER is written at setup and re-written on every seat change, and it waits there: START on
    the turn panel is the one thing that turns the system on, and it finds the order already in place.
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
        assert rt.eval("Turns.enable") is False, "%d seats: sitting down started turns" % n
        assert list(rt.eval("Turns.order").values()) == want, "%d seats: order lost on seating" % n

        # and once something has started them -- the panel's START -- the order it finds is that one
        rt.execute("Turns.enable = true onPlayerChangeColor('Red')")
        assert rt.eval("Turns.enable") is True, "%d seats: a re-apply switched a running game off" % n
        assert list(rt.eval("Turns.order").values()) == want, "%d seats: order lost after start" % n
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
        all_spawned = [str(rt.eval("REC.spawned")[i])
                       for i in range(1, len(rt.eval("REC.spawned")) + 1)]
        # THE SHEET AND THE PANEL COME WITH THE GAME NOW, not with the map -- rttNewGame spawns them
        # directly since a setup click stopped re-placing the map. They are not faction boards, and
        # this test is about where the faction boards land.
        got = [e for e in all_spawned if e.startswith("Faction Board@")]
        assert len(got) == n, "%d seats: spawned %d boards (%s)" % (n, len(got), all_spawned)
        for want_one in ("Root Box Score", "Turn Panel"):
            assert any(e.startswith(want_one + "@") for e in all_spawned), \
                "%d seats: a new game did not spawn the %s: %s" % (n, want_one, all_spawned)

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


def slots_from_the_lizard_save():
    """The three Outcast slots, in the Lizard Board's local frame, out of the maintainer's save."""
    saved = json.load(open(os.path.join(REPO, "assets", "src_art", "saves", "lizard.json"),
                           encoding="utf-8"))
    board, marks = None, []
    for o in saved["ObjectStates"]:
        nm = o.get("Nickname") or ""
        if nm == "Lizard Board":
            board = o["Transform"]
        elif nm == "Outcast Marker":
            marks.append(o["Transform"])
    assert board is not None, "the lizard save has no Lizard Board"
    a = math.radians(board["rotY"])
    ca, sa = math.cos(a), math.sin(a)
    local = []
    for m in marks:
        dx, dz = m["posX"] - board["posX"], m["posZ"] - board["posZ"]
        lx = (dx * ca - dz * sa) / board["scaleX"]
        lz = (dx * sa + dz * ca) / board["scaleX"]
        if -1.3 < lx < -0.5 and abs(lz) < 0.3:        # on the board's Outcast panel, not the wizard's
            local.append((lx, lz))
    assert len(local) == 3, "expected 3 tokens on the board's outcast slots, found %d" % len(local)
    local.sort(reverse=True)                          # local -x is image right: mouse, rabbit, fox
    return {"mouse": local[0][0], "rabbit": local[1][0], "fox": local[2][0]}


def t_the_lost_souls_box_is_gone_from_the_board(src):
    """The printed Lost Souls box is off the Lizard board; the lizard stays, lower down.

    Maintainer, 2026-09-08: "remove the lost souls art on the faction board for the lost soul cards
    since they all go on the lizard wizard", and then, seeing the first attempt: "you also can keep
    the lizard he looks nice and can stay. just put him a little bit below". Every spent card goes
    on the Lizard Wizard -- which is why this board's own readout reads the wizard and not this box
    -- so the box was an invitation to pile cards on a space the mod never uses.

    This walks the shipped texture's own pixels. A URL check would pass on a texture that still had
    the box printed on it, and an "is anything dark in the panel" check would fail on the lizard we
    deliberately kept, so each of the three claims is asserted where it actually lives.
    """
    rt = fresh(src)
    d = rt.eval('EVERYTHING["Standard"]["The Lizard Cult"]["data"]')
    url = ls = None
    for i in range(1, len(d) + 1):
        j = json.loads(d[i].json)
        if j.get("Nickname") == "Lizard Board":
            url, ls = j["CustomImage"]["ImageURL"], j["LuaScript"]
    assert url is not None, "there is no Lizard Board in the blueprint"
    assert "steamusercontent" not in url, \
        "the board still points at the original Steam texture, which has the Lost Souls box on it"
    name = url.rsplit("/", 1)[-1]
    art = os.path.join(REPO, "assets", "labels", name)
    assert os.path.exists(art), "the board points at %s, which is not in assets/labels" % name

    try:
        from PIL import Image
    except ImportError:
        return                      # the pixel checks need Pillow; the wiring above still ran

    im = Image.open(art).convert("RGB")
    assert im.size == (1689, 1312), "the board texture is %dx%d, not the board's own size" % im.size
    px = im.load()

    def count(x0, x1, y0, y1, test):
        n = 0
        for y in range(y0, y1, 2):
            for x in range(x0, x1, 2):
                if test(*px[x, y]):
                    n += 1
        return n

    white = lambda r, g, b: r > 235 and g > 235 and b > 225
    dark = lambda r, g, b: r < 105 and g < 105

    # 1. THE BORDER IS GONE. It ran as a white rounded rectangle at x 1233..1644, y 709..1264. Its
    #    top now lies UNDER the grown Outcast panel, so the sides and floor are where to look.
    assert count(1229, 1249, 800, 1200, white) == 0, "the box's left border is still printed"
    assert count(1630, 1650, 800, 1200, white) == 0, "the box's right border is still printed"
    assert count(1250, 1620, 1248, 1268, white) == 0, "the box's bottom border is still printed"

    # 2. THE TITLE AND SUBTITLE ARE GONE. They sat at y 715..815; the panel now covers down to 762,
    #    so what has to be clear of their dark red ink is the band below it.
    assert count(1280, 1600, 770, 815, dark) == 0, "'Lost Souls' or its subtitle is still printed"

    # 3. THE LIZARD STAYED, AND MOVED DOWN. He was drawn at y 854..1194 and is dropped 70px, so the
    #    band he used to occupy at the top is now open ground and he is present lower instead.
    assert count(1300, 1580, 860, 916, dark) == 0, \
        "the lizard is still up at his old height; he should have moved down"
    assert count(1300, 1580, 1000, 1250, dark) > 200, \
        "the lizard is missing from the board; he was meant to stay"

    # 4. THE OUTCAST PANEL GREW, so the Lost Souls counts have somewhere to sit. Maintainer:
    #    "increase the size of the parchment box with the decals so you create space to put the
    #    numbers below the boxes with the outcase." The printed slots end at y 664 and the panel
    #    used to end at 682 -- eighteen rows. Its floor is now 762.
    parch = lambda r, g, b: abs(r - 248) < 26 and abs(g - 228) < 26 and abs(b - 165) < 26
    band = count(1290, 1570, 676, 752, parch)
    total = len(range(676, 752, 2)) * len(range(1290, 1570, 2))
    assert band > 0.97 * total, \
        "the band below the slots is not clean parchment (%d of %d); the panel did not grow" \
        % (band, total)
    assert count(1290, 1570, 776, 800, parch) == 0, \
        "there is still parchment well below the panel's new floor; it grew too far"

    # 5. THE ICONS ARE WHOLE AND THE PARCHMENT IS CLEAN. The patch that lifts the printed frames off
    #    ran cy +/-56, which starts at row 563 where the suit icons end at 565 -- it was shaving
    #    three rows off the mouse, rabbit and fox. And the panel's corner flourish reaches x 1249
    #    where the strip that carries it down stopped at 1246, so its tip stayed behind and sat on
    #    bare parchment as a black dot. Both are measured here rather than eyeballed.
    src = Image.open(os.path.join(REPO, "assets", "src_art", "lizard_board_front.png")).convert("RGB")
    sp = src.load()
    for y in range(500, 569):
        for x in range(1240, 1620, 2):
            assert px[x, y] == sp[x, y], \
                "the suit icon band has been altered at %d,%d; the patch that clears the slots is " \
                "reaching up into the mouse, rabbit and fox" % (x, y)
    assert count(1240, 1620, 640, 700, dark) == 0, \
        "there is stray dark ink on the parchment round the slots"

    # ...and the counts are placed inside that band: below the slots' floor at local z +0.0134 and
    # above the panel's new one at +0.163. The z is NOT negated -- see the board script.
    m = re.search(r"COUNT_Z = ([0-9.]+)", ls)
    assert m, "COUNT_Z is gone from the board script"
    cz = float(m.group(1))
    assert 0.02 < cz < 0.15, "the counts sit at local z %.4f, outside the panel's new clear band" % cz
    assert "position = { -BOARD_SLOT[suit], 0.1, COUNT_Z }" in ls, \
        "the counts are no longer the mirror of the slots in x, or their z got negated again"


def t_the_lizard_board_follows_the_wizard(src):
    """The board's Outcast readout and its three counts come off the Lizard Wizard.

    Maintainer, 2026-09-07: "could you have the outcast on the faction board follow the information on
    the lizard wizard? so have the symbol for the outcast suit and then when it s heated and the
    counter for the number of cards of each suit in the lost souls."

    The wizard is the public tracker: the Outcast Marker sits in one of its three slots and the spent
    cards pile on it. The board's own Outcast panel and Lost Souls box are printed copies of the same
    two things -- and the board's script was casting a physics box at ITS OWN Lost Souls area, which
    is empty in every game the mod sets up, so the three numbers read 0 0 0 for ever. It had no test.

    The wizard is the only source, by the maintainer's choice ("The Wizard, always"): a card on the
    board's own printed box is not counted, and with no wizard out the readout is blank rather than
    wrong.

    BIRDS ARE NOT COUNTED, on purpose. The Outcast is the most common suit of Lost Souls IGNORING
    birds, so a bird count is a number nobody at the table can use -- the fixture below feeds one in
    to prove it does not land anywhere.
    """
    rt = fresh(src)
    d = rt.eval('EVERYTHING["Standard"]["The Lizard Cult"]["data"]')
    ls = None
    for i in range(1, len(d) + 1):
        j = json.loads(d[i].json)
        if j.get("Nickname") == "Lizard Board":
            ls = j["LuaScript"]
    assert ls is not None, "there is no Lizard Board in the blueprint"
    assert "Lizard Wizard" in ls, "the board's script no longer looks for the wizard"

    er = lupa.LuaRuntime(unpack_returned_tuples=True)
    er.execute(open(os.path.join(HERE, "tts_stub.lua"), encoding="utf-8").read())
    er.execute(ls.replace("!=", "~="))
    er.execute("""
      BTN = {}
      self.createButton = function(p) BTN[#BTN] = p.label; BTN[#BTN + 1] = p.label end
      self.editButton = function(p) BTN[p.index] = p.label end
      self.__scale = Vector({ 8.82, 1, 8.82 })
      WIZ = MKOBJ("Lizard Wizard", { 40, 11.6, 5 }, {})
      WIZ.__scale = Vector({ 3.904, 1, 3.904 })
      WIZ.setRotation({ 0, 137, 0 })          -- turned, to prove the read is in the wizard's frame
      MARK = MKOBJ("Outcast Marker", { 0, 0, 0 }, {})
      function putMarker(x, z, down)
        MARK.__pos = WIZ.positionToWorld(Vector({ x, 0.2, z })); MARK.is_face_down = down
      end
      function pile(descs)
        for _, o in ipairs(getAllObjects()) do if o.getName() == "souls" then o.destruct() end end
        local dk = MKOBJ("souls", WIZ.positionToWorld(Vector({ 0.48, 0.2, 0 })), {})
        dk.name = "Deck"
        local objs = {}
        for i, dsc in ipairs(descs) do objs[i] = { description = dsc } end
        dk.getObjects = function() return objs end
      end
      LASTXML = ""
      self.UI.setXml = function(x) LASTXML = tostring(x or "") end
      self.UI.setCustomAssets = function() end
      function decalAt()
        if LASTXML == "" then return "none" end
        -- ALL THREE SLOTS ARE DRAWN NOW, so find the one showing a symbol rather than the white
        -- thorn square. Reading the first Image in the XML would just report the mouse slot.
        for tag in string.gmatch(LASTXML, "<Image.-/>") do
          local img = string.match(tag, 'image="(%a+)"')
          if img == "outcastImg" or img == "hatedImg" then
            local px = tonumber(string.match(tag, 'position="(%-?[%d.]+)'))
            local py = tonumber(string.match(tag, 'position="%-?[%d.]+ (%-?[%d.]+)'))
            local w  = tonumber(string.match(tag, 'width="(%-?[%d.]+)"'))
            return string.format("%.4f|%.4f|%.4f|%s", px, py, w,
                                 img == "hatedImg" and "hated" or "outcast")
          end
        end
        return "none"
      end
      function slotsDrawn()
        local n = 0
        for _ in string.gmatch(LASTXML, "<Image.-/>") do n = n + 1 end
        return n
      end
      function tokensOnTable()
        local n = 0
        for _, o in ipairs(getAllObjects()) do
          if o.getName() == "Outcast Marker" then n = n + 1 end
        end
        return n
      end
      onLoad("")
    """)

    def counts():
        er.execute("updateButtons()")
        b = er.eval("BTN")
        return [str(b[i]) for i in range(3)]

    def decal():
        er.execute("updateButtons()")
        return str(er.eval("decalAt()"))

    # THE BOARD TEXTURE IS THE RULER, not the board script. The printed thorn frames were flood
    # filled on the 1689px art: centres at px 1305.5 / 1431.0 / 1563.5, all at py 619, each 92px
    # across, on a map of 657.4 px per local unit about px (842.2, 655.2). 100 UI px make one local
    # unit, and UI y runs WITH local z -- the canvas is turned 180 degrees against the artwork, so
    # UI y+ is image DOWN. Every number below comes from the picture, not from the script.
    FRAME_Z      = -0.0551        # (619 - 655.2) / 657.4
    FRAME_SIDE   =  0.1399        # 92 / 657.4 -- the printed frame's outer ink
    ICON_BOTTOM  = -0.1372        # the suit icons stop here; the symbol must stay clear of them
    PANEL_BOTTOM =  0.0408        # ...and the Outcast panel's parchment ends here

    def drawn():
        px, py, w, face = decal().split("|")
        return float(px) / 100.0, float(py) / 100.0, float(w) / 100.0, face

    er.execute('pile({"Fox","Fox","Mouse","Bird","Rabbit","Fox","Mouse"})')
    er.execute("putMarker(-0.73, 0.7320, false)")
    assert counts() == ["2", "1", "3"], \
        "mice/rabbits/foxes came out %s from 2 mice, 1 rabbit, 3 foxes and a bird" % counts()

    # THE SYMBOL IS THE TOKEN'S OWN. Maintainer, 2026-09-07: "the symbol is on the token that spawns
    # on the lizard wizard that is used to show the suit outcast." So the board shows a COPY of that
    # token in its own matching printed slot -- same art, and its other face is the Hated Outcast, so
    # hated needs nothing drawn: the copy is flipped like the original.
    #
    # The slots are the board's OWN snap points 5, 6 and 7, under the printed mouse, rabbit and fox.
    # THE SLOTS ARE HIS, NOT MINE. The maintainer put three tokens on the board where the symbol should
    # appear and saved it: "in the save lizard I spawned the lizard faction and put three token with
    # the outcast symbol in the position that the symbol should show." They are read back out of that
    # save here, in the BOARD's own local frame, so the blueprint cannot drift from what he laid out.
    # (They came out on the board's own snap points 5, 6 and 7, which is what I had guessed -- but a
    # guess that happens to be right is still worth replacing with the measurement.)
    SLOT = slots_from_the_lizard_save()
    assert decal() != "none", \
        "nothing is drawn on the board for a fox outcast; the symbol should be UI on its slot"
    x, z, w, face = drawn()
    assert abs(x - SLOT["fox"]) < 0.01 and abs(z - FRAME_Z) < 0.01, \
        "the fox outcast painted the symbol at %.4f,%.4f instead of the fox slot" % (x, z)
    assert face == "outcast", "the hated picture was used for an outcast that is not hated"

    # THE SLOT ITSELF IS UI NOW, not paint on the board. Its white thorn square used to be printed
    # into the texture and the symbol drawn over it, which cannot be made to line up: the texture is
    # placed by a fitted map and the symbol by the UI, and they agree only to about a pixel. All
    # three slots are drawn, always -- the two that are not the Outcast in white -- so the symbol
    # REPLACES the white instead of having to hide it.
    assert int(er.eval("slotsDrawn()")) == 3, \
        "the board drew %s slot images; it should draw all three, every time" % er.eval("slotsDrawn()")
    assert "slotImg" in ls, "the board no longer has a white slot image to draw an empty slot with"

    # IT GOES IN THE SLOT, NOT OVER IT. Maintainer, 2026-09-08, on the first version that drew at
    # all: "good but does not fit well not righ size and position adjust this hard you should be
    # able to find the snap points for reference." It was 0.22 local across -- half again wider than
    # the 0.1399 frame it was supposed to sit inside -- and a whole panel low, so it hung off the
    # bottom of the Outcast box and into the Lost Souls title beneath. Both halves are pinned here.
    # THE SYMBOL AND THE BOARD'S STAMPED OUTLINE ARE ONE MEASUREMENT. The slot is no longer the
    # board's printed thorn frame -- that is painted out -- but this same ring stamped in white at
    # this same size, so the symbol covers its own outline exactly and is drawn at its own weight.
    # If these two drift apart the white reappears all round the symbol, which is what the fattening
    # they replaced was there to hide.
    ring = None
    for line in open(os.path.join(REPO, "tools", "make_board.py"), encoding="utf-8"):
        if line.startswith("RING_LOCAL"):
            ring = float(line.split("=")[1].split()[0])
    assert ring is not None, "make_board.py no longer states RING_LOCAL"
    assert abs(w - ring) < 0.002, \
        "the board stamps its slot at %.4f but the symbol is drawn at %.4f; the white will show" \
        % (ring, w)
    assert w <= FRAME_SIDE, \
        "the symbol (%.4f) is wider than the slot the art allows for (%.4f)" % (w, FRAME_SIDE)
    assert z - w / 2 > ICON_BOTTOM, \
        "the symbol's top edge (%.4f) reaches up into the suit icons (%.4f)" % (z - w / 2, ICON_BOTTOM)
    assert z + w / 2 < PANEL_BOTTOM, \
        "the symbol's bottom edge (%.4f) hangs out of the Outcast panel (%.4f) toward Lost Souls" \
        % (z + w / 2, PANEL_BOTTOM)

    # IT IS PAINTED ON, NOT PUT ON. Maintainer, 2026-09-07: "can you make the symbol be inside the
    # faction board, not another token on token. like it s literally the faction board art." An
    # earlier version cloned the real token onto the slot; setDecals prints the image onto the board
    # itself, so nothing can be picked up off it and there is nothing to clean up.
    assert int(er.eval("tokensOnTable()")) == 1, \
        "showing the outcast added %s Outcast Markers to the table; it should add none" \
        % er.eval("tokensOnTable()")

    er.execute("putMarker(-0.73, 0.0284, true)")
    x, z, w2, face = drawn()
    assert abs(x - SLOT["mouse"]) < 0.01, "a mouse outcast landed at x %.4f" % x
    assert face == "hated", "the Hated Outcast is not showing its own picture"
    # ONE SIZE SERVES BOTH FACES -- the two token arts are drawn slightly differently, and
    # make_outcast.py crops each square about its own drawing so the board needs only one number.
    assert abs(w2 - w) < 1e-6, "the hated face is drawn at %.4f but the outcast at %.4f" % (w2, w)

    er.execute("putMarker(-0.73, 0.3749, false)")
    x, _, _, _ = drawn()
    assert abs(x - SLOT["rabbit"]) < 0.01, "a rabbit outcast landed at x %.4f" % x

    # A MARKER THAT IS NOT IN A SLOT NAMES NO SUIT. It gets picked up and put down constantly, and a
    # board that guessed the nearest slot from across the table would show a suit nobody chose.
    er.execute("putMarker(0.4, 0.0, false)")
    assert decal() == "none", "the marker was off the slots and the board still showed %s" % decal()

    # ...AND NO WIZARD MEANS NO ANSWER, rather than a stale one.
    er.execute("putMarker(-0.73, 0.7320, false)")
    assert decal() != "none", "the fixture is not showing a symbol to begin with"
    er.execute("for _,o in ipairs(getAllObjects()) do "
               "if o.getName() == 'Lizard Wizard' then o.destruct() end end")
    assert counts() == ["0", "0", "0"], "the counts survived the wizard leaving: %s" % counts()
    assert decal() == "none", "the outcast symbol survived the wizard leaving"

    # THE COUNTS SIT UNDER THEIR OWN SUIT. They were at x +0.70 / +0.90 / +1.09 -- the MIRROR of the
    # slots, which on this board is the far side, over the Birdsong/Daylight/Evening column.
    # A BUTTON'S X IS MIRRORED AGAINST THE MODEL'S. The board's snap points and its decals put the
    # Outcast panel at NEGATIVE local x; the buttons on that same panel sit at POSITIVE, because
    # createButton lays out on the face looking down at it and setDecals does not. I "fixed" the
    # counters onto the slot coordinates and put all three over Daylight on the far side of the board.
    # They are derived from the slots by negation now, so the two cannot drift apart again.
    assert "position = { -BOARD_SLOT[suit], 0.1, COUNT_Z }" in ls, \
        "the counters are not the mirror of the slot positions; check createButton's handedness"

    # ONE OUTCAST MARKER IS SPAWNED, NOT TWO. Maintainer, 2026-09-07: "it looks like the lizard wizard
    # is spawning two outcast token instead of only 1." There were two blueprints carrying one: the
    # faction's own and the Lizard Wizard's. The wizard's is the one that belongs -- rttLizardSetup
    # nudges it onto the wizard's slot column -- so the faction's copy went, and with two of them that
    # nudge had been stacking both on the same spot.
    def markers_in(bucket, name):
        entry = rt.eval('EVERYTHING["%s"]["%s"]["data"]' % (bucket, name))
        return sum(1 for i in range(1, len(entry) + 1)
                   if json.loads(entry[i].json).get("Nickname") == "Outcast Marker")
    assert markers_in("Standard", "The Lizard Cult") == 0, \
        "the lizard faction still brings its own Outcast Marker as well as the wizard's"
    assert markers_in("Tools", "Lizard Wizard") == 1, \
        "the wizard should carry exactly one Outcast Marker"


def t_the_credits_page_gives_every_caption_its_own_column(src):
    """No two captions can meet, and "on discord" is gone.

    Maintainer, 2026-09-07: "do a torough design study of the credit page to make it look nicer;
    remove the on discord thingy to save space, space out the images horizontally more so they don t
    crop on each others etc."

    The old page drew each caption under its thumbnail at a fixed size with no idea how wide the next
    one was, so "The Bat Bungler | Koffin Keeper | Lizard Wizard" touched and "Faction Selector" ran
    straight into "Mini-Mood Manager". The fix is structural rather than a nudge: every item owns a
    column of fixed width and its caption is shrunk to fit that column, so overlap is not something
    that can happen and then be tuned out.

    This checks the mechanism rather than the picture -- it re-runs the generator's own measurements
    against its own layout table, so adding a name that is too long fails here rather than on the
    table. The rendered page is checked separately, by eye, which is the part a test cannot do.
    """
    sys.path.insert(0, os.path.join(REPO, "tools"))
    import make_credits as C
    from PIL import Image, ImageDraw

    d = ImageDraw.Draw(Image.new("RGB", (10, 10)))
    x0, _, x1, _ = C.FRAME
    W = x1 - x0

    def check(items, width, where):
        cell = width / len(items)
        for name in items:
            f = C.fit(d, name, C.CAP if hasattr(C, "CAP") else 42, cell * 0.88)
            w = d.textlength(name, font=f)
            assert w <= cell * 0.88 + 1, \
                "%s: %r is %.0f wide in a %.0f column; it would run into its neighbour" \
                % (where, name, w, cell)
            assert f.size >= 20, \
                "%s: %r had to shrink to %dpt to fit its column, which will not read on the table" \
                % (where, name, f.size)

    check(C.BAND_A[1], W, "band A")
    total = sum(len(i) for _, i in C.BAND_B)
    for heading, items in C.BAND_B:
        share = W * (len(items) + 0.9) / (total + 0.9 * len(C.BAND_B))
        check(items, share, heading)

    # EVERY THUMBNAIL IS CREDITED EXACTLY ONCE. A name dropped from a band still has a crop box, so it
    # would vanish from the page silently rather than fail.
    laid = C.BAND_A[1] + [n for _, items in C.BAND_B for n in items]
    assert sorted(laid) == sorted(C.THUMBS), \
        "the layout and the thumbnails disagree: %s" % sorted(set(laid) ^ set(C.THUMBS))
    assert len(laid) == len(set(laid)), "a thumbnail is credited twice: %s" % laid

    # "ON DISCORD" IS GONE. It was on the page three times.
    lines = [C.TITLE, C.SUBTITLE] + C.BASED + [C.BAND_A[0]] + [h for h, _ in C.BAND_B]
    assert not any("discord" in l.lower() for l in lines), \
        "the credits page still says 'on discord': %s" % [l for l in lines if "discord" in l.lower()]

    # AND NO LINE IS PRINTED TWICE. Ehss and slugfacekillah are credited twice on purpose -- once for
    # the mod this is built on and once for two of the tools -- but the old page said it with the SAME
    # sentence in both places, which read as a mistake rather than as two credits.
    assert len(lines) == len(set(lines)), \
        "the same line appears twice on the page: %s" % [l for l in lines if lines.count(l) > 1]

    # AND THE PAGE THE BOARD LOADS IS THE ONE IN THE REPO. This reads the save rather than `src`:
    # CustomUIAssets is a field of the OBJECT, not of the Lua that board_lua() hands these tests.
    saved = json.load(open(os.path.join(REPO, "dist", "Root_Tabletop_Tournament.json"),
                           encoding="utf-8"))
    def board(objs):
        for o in objs:
            if o.get("GUID") == "bab7e1":
                return o
            got = board(o.get("ContainedObjects") or [])
            if got:
                return got
        return None
    assets = {a["Name"]: a["URL"] for a in (board(saved["ObjectStates"]) or {}).get("CustomUIAssets", [])}
    assert "CreditsPanelArt" in assets, "the board no longer references a credits panel"
    name = assets["CreditsPanelArt"].split("/")[-1]
    assert os.path.exists(os.path.join(REPO, "assets", "labels", name)), \
        "the board points at %s, which is not in assets/labels" % name
    assert name.startswith("credits_panel_v"), \
        "the board is not loading a credits panel: %s" % name

    # THE PAGE MUST COVER THE BOARD'S BOTTOM BUTTON ROW, and the back button must sit ON it.
    #
    # The button was at y -78 -- the SAME row as 5-Player Setup, 5-Player Draft, 5-Players Marsh and
    # the Credits button -- while the page only reached y -84, so it hung off the page's edge and
    # landed among them. Maintainer, 2026-09-07: "the back button clashes with things written put it
    # lower." There is nowhere lower to go while the page ends where it did: below that row the board
    # has about ten units left. So the page grew downwards to cover the row, which puts those buttons
    # behind it, and the back button moved down onto the strip the artwork keeps clear.
    xml = (board(saved["ObjectStates"]) or {})["XmlUI"]
    def box(el):
        m = re.search(r'<\w+ id="%s"[^>]*position="(-?[\d.]+) (-?[\d.]+) (-?[\d.]+)"[^>]*height="([\d.]+)"'
                      % el, xml)
        assert m, "no %s on the board" % el
        y, h, z = float(m.group(2)), float(m.group(4)), float(m.group(3))
        return y - h / 2, y + h / 2, z
    page_lo, page_hi, page_z = box("creditsPage")
    btn_lo, btn_hi, btn_z = box("rttCreditsBack")
    row_lo, row_hi, row_z = box("Marsh5PSetup")

    assert page_lo <= row_lo, \
        "the page reaches %.0f and the board's bottom row starts at %.0f; the row shows below it" \
        % (page_lo, row_lo)
    assert btn_z < page_z, "the back button is behind the page"
    assert page_z < row_z, "the page does not cover the board's buttons"
    assert page_lo <= btn_lo and btn_hi <= page_hi, \
        "the back button (%.0f..%.0f) is not inside the page (%.0f..%.0f)" \
        % (btn_lo, btn_hi, page_lo, page_hi)
    assert (btn_lo + btn_hi) / 2 <= -79, \
        "the back button's centre is at %.0f; it used to be -78 and was asked to go lower" \
        % ((btn_lo + btn_hi) / 2)


def t_frog_enclaves_match_the_suit_circle(src):
    """Every enclave is sized to the suit marker's circle, and all twelve move together.

    The circle is the marker's suit lobe: 1.8408 world units across, from the largest circle inscribed
    in the lobe (texture hole-filled first, so the white glyph does not cap it) scaled by the markers'
    own 1.30. The enclave art fills 97.2% of its tile, so the tile wants 1.8938 -> scale 0.8343
    against a 2.27-unit Custom_Tile. That last constant is the one thing not measured from the mod, so
    this scale was always going to be the single number to move if the token read wrong on the table.

    IT WAS MOVED. Maintainer, 2026-09-07: "you can also reduce the size of enclaves by 10%" -- 0.8343
    x 0.90 = 0.75087, a token that sits inside the circle rather than filling it to the rim. The
    measurement above is kept because it is still what the number is derived FROM; what changed is the
    deliberate margin against it.
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
    assert abs(scales[0] - 0.75087) < 1e-6, \
        "enclave scale %s is not 0.90 of the measured circle (0.8343)" % scales[0]
    assert scales[0] > 0.703911364, "the enclave is back to its original, smaller size"
    # Y IS THICKNESS, NOT FOOTPRINT, on a Custom_Tile -- a "10% smaller" that scaled it too would
    # have thinned every token and shown up as z-fighting against the marker underneath.
    ys = set()
    for i in range(1, len(d) + 1):
        j = json.loads(d[i].json)
        if j.get("Nickname") == "Enclave":
            ys.add(round(j["Transform"]["scaleY"], 6))
    assert ys == {1.0}, "an enclave's thickness was rescaled with its footprint: %s" % sorted(ys)


def peaceful_offset_from_the_snap_save():
    """The side spot, in a marker's own local frame, read out of the maintainer's "snap" save.

    He placed one sympathy token on one fox suit marker to show where the peaceful enclave should sit.
    This finds that token and its marker, and converts the gap between the token and the marker's LOBE
    centre into marker-local units -- the same frame the blueprint's SIDE_LOCAL is written in, and the
    same transform positionToWorld applies (rotate about Y, scale, translate).
    """
    saved = json.load(open(os.path.join(REPO, "assets", "src_art", "saves", "snap.json"),
                           encoding="utf-8"))
    marks, token = [], None
    for o in saved["ObjectStates"]:
        t = o["Transform"]
        if "Clearing Marker" in (o.get("Tags") or []):
            marks.append(t)
        elif "sympath" in (o.get("Nickname") or "").lower():
            # the one he put ON THE MAP; the rest are still stacked in the supply
            if token is None or abs(t["posX"]) + abs(t["posZ"]) < abs(token["posX"]) + abs(token["posZ"]):
                token = t
    assert token is not None and marks, "the snap save has no sympathy token or no markers"
    mk = min(marks, key=lambda m: (m["posX"] - token["posX"]) ** 2 + (m["posZ"] - token["posZ"]) ** 2)
    a = math.radians(mk["rotY"])
    ca, sa = math.cos(a), math.sin(a)
    dx, dz = token["posX"] - mk["posX"], token["posZ"] - mk["posZ"]
    lx = (dx * ca - dz * sa) / mk["scaleX"]
    lz = (dx * sa + dz * ca) / mk["scaleX"]
    return (round(lx - 0.0056, 4), round(lz - 0.3599, 4))          # relative to the lobe centre


def t_enclave_targets_the_suit_marker(src):
    """A dropped enclave aims at the suit marker -- ON the symbol when militant, beside it when not.

    The target is the LOBE centre, model-local z 0.3599 -- not the suit glyph at 0.4447, which sits
    off-centre in the lobe and would miss by 0.11 world units. Facing comes from the marker's OWN
    rotation, which already points at its clearing centre: fitted over all 68 well-matched markers on
    the six maps the offset is +0.03 deg, concentration 0.9944. Copying it is exact per clearing;
    deriving the bearing from RTT_CLEARING_CENTRES instead carried that table's ~1u error, which is
    what read as tilted.

    AND WHICH SIDE IS UP DECIDES WHERE. Maintainer, 2026-09-07: "when it s militant in the center of
    the suit marker, but when not militant the snap should be on the side of the suit marker at the
    edge of it so it does not hide the suit symbol ... the position of the snap would change when one
    flips the enclave."

    is_face_down TRUE IS THE MILITANT SIDE: the blueprint's ImageURL is "Diaspora_TokenPeaceful" and
    all twelve spawn at rotZ 0, so a fresh token shows the peaceful face. Pinned here rather than read
    back out of the script's own constant, because reading it from the script is exactly how an
    inversion passes unnoticed -- as one did, briefly, on a misreading of "the center snap still flips
    it to peaceful while it should be militant". The token really was being FLIPPED there: the
    placement set rotation { 0, y, 0 } and Z is the flip axis, so every landing levelled it face-up.
    That is the last assertion in this test, and it is the one that would have caught it.
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
        got += 1
        if got > 1:
            continue

        # AND RUN IT. This used to assert on substrings of the script -- "z = 0.3599", "FROG_FACING",
        # no "atan" -- and never execute a line of it, so the behaviour it describes had no coverage
        # at all: any rewrite that kept the words and changed the maths would have passed.
        er = lupa.LuaRuntime(unpack_returned_tuples=True)
        er.execute(open(os.path.join(HERE, "tts_stub.lua"), encoding="utf-8").read())
        er.execute(ls.replace("!=", "~="))
        er.execute("""
          MARKER = MKOBJ("Clearing Marker", { 10, 11.6, -4 }, { "Clearing Marker" })
          MARKER.setRotation({ 0, 137, 0 })
          -- the lobe centre is model-local z 0.3599; positionToWorld carries the marker's own turn
          MARKER.__scale = Vector({ 1, 1, 1 })
          self.__pos = Vector({ 10.6, 12, -4.5 })
          self.__rot = Vector({ 0, 0, 0 })
        """)
        want = er.eval("MARKER.positionToWorld(Vector({ 0.0056, 0.0174, 0.3599 }))")

        # MILITANT: dead on the lobe centre, covering the symbol.
        er.execute("self.__pos = Vector({ 10.6, 12, -4.5 }) self.is_face_down = true")
        er.execute("pcall(function() onDrop('Red') end) FLUSH(20)")
        p = er.eval("self.getPosition()")
        r = er.eval("self.getRotation()")
        assert abs(p.x - want.x) < 0.05 and abs(p.z - want.z) < 0.05, (
            "a militant enclave landed at %.3f,%.3f; the marker's lobe centre is %.3f,%.3f"
            % (p.x, p.z, want.x, want.z))
        # the facing is the MARKER's, plus the blueprint's own offset -- copied, never recomputed
        off = er.eval("FROG_FACING") or 0
        assert abs(((r.y - (137 + off)) + 180) % 360 - 180) < 0.5, (
            "a dropped enclave faces %.1f; the marker faces 137 and the offset is %s" % (r.y, off))

        # PEACEFUL: the spot the maintainer laid out by hand. All twelve spawn this way up.
        #
        # MEASURED, NOT CHOSEN. "check the save 'snap' I put 1 sympathy token on the map on 1 fox suit
        # marker to show you the position I want for the side snap." His save is read here and the
        # offset derived from it, so the constants in the blueprint cannot drift from what he placed --
        # two earlier guesses at this (0.769, then 1.00, both sideways only) are what it replaces.
        want_side = peaceful_offset_from_the_snap_save()
        er.execute("self.__pos = Vector({ 10.6, 12, -4.5 }) self.is_face_down = false")
        er.execute("pcall(function() onDrop('Red') end) FLUSH(20)")
        q = er.eval("self.getPosition()")
        target = er.eval("MARKER.positionToWorld(Vector({ %.6f, 0.0174, %.6f }))"
                         % (0.0056 + want_side[0], 0.3599 + want_side[1]))
        assert abs(q.x - target.x) < 0.05 and abs(q.z - target.z) < 0.05, (
            "a peaceful enclave landed at %.3f,%.3f; the save puts it at %.3f,%.3f"
            % (q.x, q.z, target.x, target.z))
        # ...and that is genuinely off the symbol, without leaving the marker behind
        off_lobe = ((q.x - want.x) ** 2 + (q.z - want.z) ** 2) ** 0.5
        assert 1.0 < off_lobe < 2.5, \
            "the side spot is %.3f from the lobe centre, which is not beside it" % off_lobe

        # ...AND IT SITS AT AN ANGLE THERE, on top of the marker's own facing and only here.
        # Maintainer, 2026-09-07: "the side snap rotate the enclave counterclockwise by 20 degrees."
        # TTS turns clockwise on a rising Y, so counterclockwise is negative.
        rq = er.eval("self.getRotation()")
        tilt = ((rq.y - (137 + off)) + 180) % 360 - 180
        assert abs(tilt + 20) < 0.5, \
            "the peaceful enclave is tilted %.1f from the marker's facing, not -20" % tilt

        # FLIPPING IT MOVES IT. This is the half that was missing: a flip in place never calls onDrop,
        # so a token turned peaceful stayed sitting on the symbol it was meant to uncover. Maintainer,
        # 2026-09-07: "most importantly flipping the enclave when it is on one of the two snaps needs
        # to change its position." onRotate fires as the animation starts, while is_face_down still
        # reads the old face, so the token re-places itself once the flip has landed.
        # ...AND IT MOVES WITH THE TURN, not after it. Maintainer, 2026-09-07: "is it possible that
        # the enclave move from 1 snap to the other during the flip not after landing?" onRotate fires
        # as the animation STARTS, and the token glides across from there, so the move reads as part of
        # the flip rather than a jump once it has settled.
        #
        # At that moment is_face_down still reads the OLD face -- so the glide works out the new one as
        # its opposite, which is why it is left alone here rather than set before the call.
        er.execute("self.resting = false")
        er.execute("pcall(function() onRotate(0, 0, 'Red', 0, 180) end)")
        turning = er.eval("self.getPosition()")
        assert ((turning.x - want.x) ** 2 + (turning.z - want.z) ** 2) ** 0.5 < 0.05, \
            "the token had not started moving when the flip began; it should glide across with it"
        # AND THE TURN GOES WITH IT. Maintainer, 2026-09-07: "the rotation though happens only after it
        # lands not during the flip." The angle has to be corrected here, in the same instant as the
        # move -- a settle pass that fixes it afterwards is a visible second step.
        mid = ((er.eval("self.getRotation()").y - (137 + off)) + 180) % 360 - 180
        assert abs(mid) < 0.5, \
            "the token was still tilted %.1f when the flip began; the turn should ride along" % mid
        # AND THE FLIP ITSELF STILL HAPPENS. Any rotation issued now races TTS's own flip animation,
        # so the target has to be the orientation the token should END in -- turned AND flipped. A
        # RELATIVE turn was tried here and replaced the flip with a Y-only move, so the token stopped
        # flipping at all: "it does not flip anymore when we flip it you broke something".
        # is_face_down is NOT set before this: the script has to drive the flip, not be told about it.
        midz = er.eval("self.getRotation()").z % 360
        assert 90 < midz < 270, \
            "the flip did not happen: Z is %.0f, so the token turned but never flipped" % midz
        # AND IT CROSSES ABOVE THE BOARD, not through it. The glide used to run at resting height,
        # which is ON the marker, so on its way between the spots it ploughed through the marker's own
        # relief -- "during the flip it goes a bit under the marker and conflicts with the map".
        rest_y = 12.0
        assert er.eval("self.getPosition()").y > rest_y + 0.2, \
            "the token crossed at %.3f, level with the board it is sitting on" \
            % er.eval("self.getPosition()").y
        # BOTH ANIMATIONS RUN FAST. `fast` is TTS's only speed control for a scripted move -- there is
        # no duration to set -- and both take it, so the glide and the turn stay in step.
        # Maintainer, 2026-09-07: "makes the flip animation 30% faster".
        assert er.eval("self.__smoothFast") is True, "the glide is not using TTS's fast setting"
        assert er.eval("self.__rotFast") is True, "the turn is not using TTS's fast setting"

        # ...AND THE LANDING HEIGHT IS PHYSICS', NOT OURS. The first version put the token back at the
        # height it lifted from, which is wrong for the same reason the lift is needed: the two spots
        # are at DIFFERENT heights, the lobe being raised. A token carrying its side-spot height to the
        # centre lands inside the marker -- "on militant it lands too low on some markers". Here TTS
        # settles it higher than it started, and the placement must leave that alone.
        er.execute("self.__pos = Vector({ self.getPosition().x, %.3f, self.getPosition().z })"
                   % (rest_y + 0.17))
        er.execute("self.is_face_down = true self.resting = true FLUSH_UNTIL(8.0, 4)")
        assert abs(er.eval("self.getPosition()").y - (rest_y + 0.17)) < 1e-6, \
            "the placement forced the height to %.3f; it should keep the %.3f the token settled at" \
            % (er.eval("self.getPosition()").y, rest_y + 0.17)
        back = er.eval("self.getPosition()")
        assert abs(back.x - want.x) < 0.05 and abs(back.z - want.z) < 0.05, (
            "flipping to militant left the token at %.3f,%.3f instead of the lobe centre"
            % (back.x, back.z))
        er.execute("self.resting = false")
        er.execute("pcall(function() onRotate(0, 180, 'Red', 0, 0) end)")
        assert abs(er.eval("self.getPosition()").x - back.x) > 0.5, \
            "the token stayed on the centre when the flip to peaceful began"
        mid = ((er.eval("self.getRotation()").y - (137 + off)) + 180) % 360 - 180
        assert abs(mid + 20) < 0.5, \
            "the token was at %.1f when the flip to peaceful began; it should already be turning" % mid
        midz = er.eval("self.getRotation()").z % 360
        assert midz < 90 or midz > 270, \
            "the flip back did not happen: Z is %.0f" % midz
        er.execute("self.is_face_down = false self.resting = true FLUSH_UNTIL(8.0, 4)")
        side = er.eval("self.getPosition()")
        assert ((side.x - want.x) ** 2 + (side.z - want.z) ** 2) ** 0.5 > 0.5, \
            "flipping to peaceful left the token on the symbol"

        # A SPIN IS NOT A FLIP. onRotate fires for both, and re-placing on a spin would undo a player
        # turning the token by hand.
        er.execute("self.__pos = Vector({ side.x + 0.4, 12, side.z })" .replace("side.x", str(side.x)).replace("side.z", str(side.z)))
        er.execute("pcall(function() onRotate(90, 180, 'Red', 0, 180) end) FLUSH_UNTIL(1.0, 4)")
        spun = er.eval("self.getPosition()")
        assert abs(spun.x - (side.x + 0.4)) < 1e-6, \
            "a spin re-placed the token; only a change of FLIP should"

        # AND THE CATCH AREA IS NOT THE WHOLE CLEARING. 4.0 pulled a token onto a marker from most of
        # a clearing away -- "the snaps are too large like it attaches the enclave from such a large
        # area a bit too much"; 3.0 is the maintainer's own number. Dropped well clear of that, the
        # enclave must stay where it was let go. HOME_GUID is cleared first: a token remembers the
        # marker it was on, and this is a fresh token dropped in open ground.
        # 12.95 is 2.71 from the lobe: inside the 3.0 this used to be, outside the 2.55 it is now, so
        # this pins the SIZE of the catch area rather than merely that it has one.
        er.execute("HOME_GUID = nil self.__pos = Vector({ 12.95, 12, -4.267 }) self.is_face_down = true")
        er.execute("pcall(function() onDrop('Red') end) FLUSH(20)")
        far = er.eval("self.getPosition()")
        assert abs(far.x - 12.95) < 1e-6, (
            "an enclave dropped %.2f from the lobe was still pulled onto it"
            % ((12.95 - want.x) ** 2 + (-4.267 - want.z) ** 2) ** 0.5)

        # ...but inside it, it is taken. Without this the check above would pass on a reach of zero.
        er.execute("HOME_GUID = nil self.__pos = Vector({ 12.4, 12, -4.5 })")
        er.execute("pcall(function() onDrop('Red') end) FLUSH(20)")
        near = er.eval("self.getPosition()")
        assert abs(near.x - want.x) < 0.05, (
            "an enclave dropped %.2f from the lobe was not taken by it"
            % ((12.4 - want.x) ** 2 + (-4.5 - want.z) ** 2) ** 0.5)

        # AND THE SIDE SPOT IS STILL INSIDE IT. This is the floor under REACH: a peaceful token sits
        # 1.67 world units out, and it has to find its own marker from there when it is flipped back.
        # Shrink the catch area past that and a flip strands the token where it stands.
        er.execute("HOME_GUID = nil self.__pos = Vector({ %.4f, 12, %.4f }) self.is_face_down = true"
                   % (side.x, side.z))
        er.execute("pcall(function() onDrop('Red') end) FLUSH(20)")
        from_side = er.eval("self.getPosition()")
        assert abs(from_side.x - want.x) < 0.05 and abs(from_side.z - want.z) < 0.05, (
            "a token at the side spot could not find its marker; REACH is under the %.2f it sits out"
            % ((side.x - want.x) ** 2 + (side.z - want.z) ** 2) ** 0.5)

        # PLACING A TOKEN MUST NOT UN-FLIP IT. Z is the flip axis, and the placement used to set
        # rotation to { 0, y, 0 }: a token flipped to militant went to the centre and was turned
        # straight back to peaceful. Maintainer, 2026-09-07: "when I flip it to militant it goes to the
        # side snap and flips back to peaceful. so completely wrong."
        for face_down, z in ((True, 180), (False, 0)):
            er.execute("HOME_GUID = nil self.__pos = Vector({ 10.6, 12, -4.5 })")
            er.execute("self.__rot = Vector({ 0, 0, %d }) self.is_face_down = %s"
                       % (z, "true" if face_down else "false"))
            er.execute("pcall(function() onDrop('Red') end) FLUSH(20)")
            rz = er.eval("self.getRotation()").z
            assert abs(((rz - z) + 180) % 360 - 180) < 1.0, (
                "placing a token whose flip was %d left it at %.1f; only Y belongs to the placement"
                % (z, rz))

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

    # NOR DOES SITTING DOWN. Maintainer, 2026-09-09: "don t enable turns until start is pressed."
    # The order is written and waits; START on the turn panel is the only thing that switches it on.
    rt.execute("SEAT('Red')")
    rt.execute("onPlayerChangeColor('Red')")
    assert rt.eval("Turns.enable") is False, "sitting down started the turn system"
    assert list(rt.eval("Turns.order").values()) == ["Red", "Yellow", "Orange", "Teal"]

    # once START has, the re-apply keeps it on and does not steal the turn
    rt.execute("Turns.enable = true")
    rt.execute("Turns.turn_color = 'Orange'")
    rt.execute("onPlayerChangeColor('Teal')")
    assert rt.eval("Turns.turn_color") == "Orange", "seating someone handed the turn back to seat 1"
    assert list(rt.eval("Turns.order").values()) == ["Red", "Yellow", "Orange", "Teal"]

    rt.execute("Turns.order = {'Teal','Red'}")
    rt.execute("FLUSH(8)")
    assert list(rt.eval("Turns.order").values()) == ["Teal", "Red"], "a manual reorder was overwritten"

    # a seat change that changes nothing is a no-op: TTS chimes every time turns are switched on.
    # START stands in for the panel here -- TTS does not let turn_color stick while the system is off,
    # so there is no turn to disturb until something has begun.
    rt = fresh(src)
    rt.execute("SEAT('Red') rttEnableTurns(4) Turns.enable = true")
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
    for site in ('getObjectsWithTag(t)', 'getObjectsWithTag(RTT_SELECTOR_TAG)'):
        line = [l for l in src.splitlines() if site in l and "destr" in l.lower()]
        assert line and "rttDestroyUI" in line[0], "%s still calls destruct directly: %s" % (site, line)

    # THE BOX SCORE IS NOT TORN DOWN AT ALL any more, which is stronger than tearing it down politely.
    # It is the one object on the table people type into, and it carries the recorded game in its own
    # state -- so a colour that cannot be retaken is not even the worst thing a stray destroy costs.
    torn = [l.strip() for l in src.splitlines()
            if "RTT_BOXSCORE_TAG" in l and ("destruct" in l or "rttDestroyUI" in l)]
    assert not torn, "something still tears down the box score: %s" % torn


def t_gizmo_default_key_is_numpad_zero(src):
    """TWO keys now, at the maintainer's request (2026-09-06): numpad 0 SENDS HOME, numpad 1 TAKES.

    Numpad 0 no longer spawns anything -- hovering nothing does nothing at all -- and numpad 1 does
    what 0 used to do when hovering nothing, without caring what the pointer is over.

    TTS scripting buttons are numbered 1..10 with 10 being numpad 0, the convention the original
    Ginso's Gizmo used. A PC user configures nothing; the two named hotkeys are registered UNBOUND for
    machines with no numpad, where the top-row 0 is a different key (and needs Shift on a French Mac).
    """
    # Maintainer, 2026-09-09: "move current numpad 2 option to numpad 3. then create new numpad 2
    # option." So marking a knave's prisoner moved up to 3, and 2 became the token key.
    KEYS = ((10, "HOME"), (1, "TAKE"), (3, "MARK"))
    COUNTERS = "HOME, TAKE, MARK, TOKEN"

    def wired():
        rt = fresh(src)
        rt.execute("%s = 0, 0, 0, 0" % COUNTERS)
        rt.execute("rttGizmoHome = function(c) HOME = HOME + 1 end")
        rt.execute("rttGizmoTake = function(c) TAKE = TAKE + 1 end")
        rt.execute("rttGizmoMark = function(c) MARK = MARK + 1 end")
        rt.execute("rttGizmoToken = function(c) TOKEN = TOKEN + 1 end")
        return rt

    def counts(rt):
        return {n: rt.eval(n) for n in ("HOME", "TAKE", "MARK", "TOKEN")}

    for idx, which in KEYS:
        rt = wired()
        rt.execute("%s = 0, 0, 0, 0  onScriptingButtonDown(%d, 'Red')" % (COUNTERS, idx))
        got = counts(rt)
        assert got[which] == 1 and sum(got.values()) == 1, \
            "scripting button %d fired %s" % (idx, {k: v for k, v in got.items() if v})

    # NUMPAD 2 ACTS ON RELEASE, not on the press: the press starts the two-second hold that chooses
    # a kind, and only a press SHORTER than that hands one over.
    rt = wired()
    rt.execute("%s = 0, 0, 0, 0  onScriptingButtonDown(2, 'Red')" % COUNTERS)
    assert sum(counts(rt).values()) == 0, "numpad 2 handed a token over on the way down"
    rt.execute("onScriptingButtonUp(2, 'Red')")
    got = counts(rt)
    assert got["TOKEN"] == 1 and sum(got.values()) == 1, \
        "releasing numpad 2 fired %s" % {k: v for k, v in got.items() if v}

    for idx in (4, 5, 6, 7, 8, 9):
        rt = wired()
        rt.execute("%s = 0, 0, 0, 0  onScriptingButtonDown(%d, 'Red')" % (COUNTERS, idx))
        assert sum(counts(rt).values()) == 0, "button %d should do nothing" % idx

    # AND THE NAMED HOTKEYS, which are what the maintainer actually uses -- a MacBook has no numpad.
    # These were asserted as SOURCE TEXT, and addHotkey did not even exist in the harness: onLoad
    # calls it inside a pcall, so registration failed silently and nothing reached the handler.
    # TTS MATCHES A BINDING BY LABEL, not by handler, so renaming one drops whatever key was bound to
    # it in Game Keys. All three were renamed on 2026-09-09 to the maintainer's own wording for the
    # keys -- he asked for it, and it costs a one-time rebind of the three he had set.
    LABELS = (("Move back to supply/initial position", "HOME"),
              ("Move a warrior from own supply to cursor", "TAKE"),
              ("Set warrior as a knave prisoner", "MARK"))
    for label, which in LABELS:
        rt = wired()
        rt.execute("%s = 0, 0, 0, 0" % COUNTERS)
        assert rt.eval("PRESS(%r, 'Red')" % label) is True, "no hotkey registered as %r" % label
        got = counts(rt)
        assert got[which] == 1 and sum(got.values()) == 1, \
            "hotkey %r fired %s" % (label, {k: v for k, v in got.items() if v})

    # THE TOKEN HOTKEY IS HELD, exactly like numpad 2. addHotkey takes a triggerOnKeyUp flag and
    # hands the callback an isKeyUp, so the same press-and-hold works without a numpad -- tap to take
    # one, hold to choose the kind. There was briefly a SECOND hotkey for choosing, on the belief
    # that a named key could not be held. It can, and one gesture on both keyboards is the point.
    TOK = "Move any token to cursor; set type by holding numpad 2 for 2 seconds"
    rt = wired()
    assert rt.eval("HOTKEY_HOLDS(%r)" % TOK) is True, \
        "the token hotkey is not registered to fire on key up, so it cannot be held"
    # ...and its label has to SAY so. The hold is the only way to set the key up, an unset key is
    # silent by design, and nothing else in the game would tell a player how.
    assert "holding" in TOK and "2 seconds" in TOK, \
        "the token key's label no longer explains how to set its type"
    assert rt.eval("PRESS(%r, 'Red')" % TOK) is True, "no hotkey registered as %r" % TOK
    assert sum(counts(rt).values()) == 0, "the token hotkey handed one over on the way down"
    rt.eval("PRESS(%r, 'Red', true)" % TOK)
    got = counts(rt)
    assert got["TOKEN"] == 1 and sum(got.values()) == 1, \
        "releasing the token hotkey fired %s" % {k: v for k, v in got.items() if v}


def t_numpad_zero_leaves_locked_pieces_alone(src):
    """Numpad 0 does nothing to a piece that is locked -- a prisoner included.

    Maintainer, 2026-09-09: "ok let s change the rule; numpad 0 does nothing on anything that is
    locked." That replaced the rule of an hour before, that numpad 0 should free a prisoner and carry
    it home; a prisoner is locked, so it falls under this and numpad 0 no longer touches one. Freeing
    it stays numpad 3's job, the key that made it.

    A lock is a player saying this piece stays put, and one key that respects that everywhere beats a
    key with an exception in it.
    """
    rt = fresh(src)
    rt.execute("""
      RTT_HOME = {}
      RTT_HOME['w1'] = { n='Marquise Warrior', f='Marquise de Cat', p={ 7.0,0.2,-46.0}, r={0,0,0} }
      W = MKOBJ('Marquise Warrior', { 30, 1, 30 }, {})
      Global.setVar("RTT_SEAT_COLOR", JSON.encode({ ["Marquise de Cat"] = "Red" }))
      HOVER['Red'] = W
      onScriptingButtonDown(3, 'Red')      -- numpad 3: make it a prisoner
      FLUSH()
    """)
    assert rt.eval("W.__locked") is True, "numpad 3 did not lock the prisoner"

    rt.execute("onScriptingButtonDown(10, 'Red') FLUSH()")
    assert rt.eval("W.__locked") is True, "numpad 0 unlocked a prisoner; locked pieces are its no"
    assert rt.eval("W.__glow") is not None, "numpad 0 put a prisoner's light out"
    assert rt.eval("RTT_LAID[W.getGUID()]") is not None, "numpad 0 took a prisoner off the record"
    assert abs(float(rt.eval("W.__pos.x")) - 30.0) < 0.01, \
        "numpad 0 moved a prisoner to %.2f; it should not have moved at all" % rt.eval("W.__pos.x")

    # ...and numpad 3, the key that made it, still frees it.
    rt.execute("onScriptingButtonDown(3, 'Red') FLUSH()")
    assert rt.eval("W.__locked") is False, "numpad 3 no longer frees the prisoner it made"
    assert rt.eval("RTT_LAID[W.getGUID()]") is None, "numpad 3 left the freed prisoner on the record"

    # ANY lock, not only a prisoner's: a piece the player locked by hand is equally untouchable.
    rt.execute("""
      L = MKOBJ('Marquise Warrior', { 31, 1, 31 }, {})
      L.setLock(true)
      HOVER['Red'] = L
      onScriptingButtonDown(10, 'Red')
      FLUSH()
    """)
    assert abs(float(rt.eval("L.__pos.x")) - 31.0) < 0.01, \
        "numpad 0 sent a hand-locked warrior home; a lock is a lock"

    # ...while an unlocked one still goes home, which is the whole point of the key.
    rt.execute("""
      V = MKOBJ('Marquise Warrior', { 32, 1, 32 }, {})
      HOVER['Red'] = V
      onScriptingButtonDown(10, 'Red')
      FLUSH()
    """)
    assert abs(float(rt.eval("V.__pos.x")) - 7.0) < 0.01, \
        "an ordinary warrior no longer goes home; it went to %.2f" % rt.eval("V.__pos.x")


def t_numpad_two_hands_you_the_token_you_chose(src):
    """Numpad 2 takes a token or building to your cursor; holding it on one chooses which.

    Maintainer, 2026-09-09: "move any building/token to cursor position. to set which type of token
    building, presse numpad 2 for 2 full seconds on a token or building then it will be set to that
    one for that player." Asked what the key should do before anything is chosen, and where the piece
    should come from: "nothing happens and silence", and from its supply, the way numpad 1 works.
    """
    rt = fresh(src)
    rt.execute("""
      rttBagOfMap = function() return {} end       -- this kind lives in a row, not a bag
      RTT_HOME = {}
      RTT_HOME['s1'] = { n='Sympathy', f='Woodland Alliance', p={ 4.0,0.2,-46.0}, r={0,0,0} }
      RTT_HOME['s2'] = { n='Sympathy', f='Woodland Alliance', p={ 6.0,0.2,-46.0}, r={0,0,0} }
      A = MKOBJ('Sympathy', { 4.0, 0.2, -46.0 }, {})
      B = MKOBJ('Sympathy', { 6.0, 0.2, -46.0 }, {})
      POINTER['Red'] = { x = 20, y = 1, z = 20 }
      SAID = 0
      broadcastToColor = function() SAID = SAID + 1 end
    """)

    # 1. NOTHING CHOSEN: a press does nothing at all, and says nothing.
    rt.execute("onScriptingButtonDown(2, 'Red') onScriptingButtonUp(2, 'Red')")
    moved = rt.eval("(A.__pos.x ~= 4.0) or (B.__pos.x ~= 6.0)")
    assert moved is False, "numpad 2 moved a token before anything was chosen"
    assert int(rt.eval("SAID")) == 0, "numpad 2 said something when it should have kept quiet"

    # 2. A SHORT PRESS ON ONE DOES NOT CHOOSE IT -- it has to be held for the full two seconds.
    rt.execute("HOVER['Red'] = A  onScriptingButtonDown(2, 'Red')")
    rt.execute("FLUSH_UNTIL(1)")
    rt.execute("onScriptingButtonUp(2, 'Red')")
    assert rt.eval("RTT_TOKEN_PICK['Red']") is None, \
        "a one-second press chose a kind; it takes two"

    # 3. HELD FOR TWO SECONDS: that kind is now this player's, and the press is spent -- releasing
    #    afterwards must not also hand one over.
    rt.execute("onScriptingButtonDown(2, 'Red')")
    rt.execute("FLUSH_UNTIL(2)")
    assert str(rt.eval("RTT_TOKEN_PICK['Red']")) == "Sympathy", \
        "holding numpad 2 on a Sympathy did not choose it"
    rt.execute("onScriptingButtonUp(2, 'Red')")
    moved = rt.eval("(A.__pos.x ~= 4.0) or (B.__pos.x ~= 6.0)")
    assert moved is False, "the press that chose a kind also handed a token over"

    # 4. NOW A SHORT PRESS TAKES ONE, to the pointer, off the END of the row -- the mirror of numpad
    #    0 filling it from the other end.
    rt.execute("HOVER['Red'] = nil  onScriptingButtonDown(2, 'Red') onScriptingButtonUp(2, 'Red')")
    ax = float(rt.eval("A.__pos.x")); bx = float(rt.eval("B.__pos.x"))
    took = [n for n, x in (("A", ax), ("B", bx)) if abs(x - 20.0) < 0.01]
    assert len(took) == 1, "numpad 2 took %d tokens; it should take one" % len(took)
    assert took[0] == "A", \
        "it took the token at the near end of the row; numpad 0 fills from there, so this empties " \
        "from the far end"

    # 5. AND WARRIORS ARE NOT OFFERED -- that is numpad 1's key.
    assert rt.eval("rttTokenEligible('Marquise Warrior')") is False, \
        "a warrior can be chosen as the token key's kind; numpad 1 already takes those"

    # 6. EVERY PLAYER HAS THEIR OWN, and two of them pressing at once do not cross. The choice, the
    #    press in flight, the broadcast and the pointer are all keyed by colour -- this shows it
    #    rather than trusting the reading. Maintainer, 2026-09-09: "the gizmo numpad 2 setting works
    #    well for each player independtly right?"
    rt.execute("""
      RTT_HOME = {}
      RTT_TOKEN_PICK = {}
      RTT_HOME['s1'] = { n='Sympathy', f='Woodland Alliance', p={ 4.0,0.2,-46.0}, r={0,0,0} }
      RTT_HOME['r1'] = { n='Roost',    f='Eyrie Dynasties',   p={-4.0,0.2,-46.0}, r={0,0,0} }
      S = MKOBJ('Sympathy', { 4.0, 0.2, -46.0 }, {})
      R = MKOBJ('Roost',    {-4.0, 0.2, -46.0 }, {})
      POINTER['Red']  = { x = 20, y = 1, z = 20 }
      POINTER['Blue'] = { x = 30, y = 1, z = 30 }
      -- both hold at once, on different things, and release in the other order
      HOVER['Red'] = S   onScriptingButtonDown(2, 'Red')
      HOVER['Blue'] = R  onScriptingButtonDown(2, 'Blue')
      FLUSH_UNTIL(2)
      onScriptingButtonUp(2, 'Blue')
      onScriptingButtonUp(2, 'Red')
    """)
    assert str(rt.eval("RTT_TOKEN_PICK['Red']")) == "Sympathy", \
        "Red chose a Sympathy and got %s" % rt.eval("RTT_TOKEN_PICK['Red']")
    assert str(rt.eval("RTT_TOKEN_PICK['Blue']")) == "Roost", \
        "Blue chose a Roost and got %s" % rt.eval("RTT_TOKEN_PICK['Blue']")

    # ...and each press then draws that player's own kind, to that player's own pointer.
    rt.execute("""
      HOVER['Red'] = nil  HOVER['Blue'] = nil
      onScriptingButtonDown(2, 'Red')   onScriptingButtonUp(2, 'Red')
      onScriptingButtonDown(2, 'Blue')  onScriptingButtonUp(2, 'Blue')
    """)
    assert abs(float(rt.eval("S.__pos.x")) - 20.0) < 0.01, \
        "Red's press did not bring Red a Sympathy to Red's pointer"
    assert abs(float(rt.eval("R.__pos.x")) - 30.0) < 0.01, \
        "Blue's press did not bring Blue a Roost to Blue's pointer"


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
    # its spot is the maintainer's own, from his save 'faction': a SECOND ROW behind the captains
    # deck, not a fifth along the first row, which is where I had guessed it. He nudged the whole
    # group again on 2026-09-10 -- "use the save called faction for the new position of the faction
    # cards spawned by the option button faction cards" -- and all six moved together, about
    # (+0.26, -0.99), so the layout is his and only the anchor changed.
    # TWO entries share the vagabond row now -- the 12-card deck and the single faction card -- so
    # match on the card COUNT, not on z alone
    def entry_at(n_cards):
        return rt.eval("""function(want)
          for _, e in ipairs(RTT_HOOT) do
            local n = 0
            for _ in e.json:gmatch('"CardID":%s*%d+') do n = n + 1 end
            if n == want and math.abs(e.pos[3] - 27.695) < 0.01 then
              return string.format('%.3f,%.3f', e.pos[1], e.pos[3])
            end
          end
          return 'missing'
        end""")(n_cards)
    at = entry_at(12)
    assert at == "50.484,27.696", "the vagabond deck is at %s; his save has 50.484,27.696" % at

    # the VAGABOND FACTION card (CardID 303), to the right of the character deck and in line with the
    # first 6-card faction deck below it. It is on the same sheet as the other faction cards but is in
    # neither 6-card deck, so Faction Cards used to lay out every faction EXCEPT the vagabond.
    card = entry_at(1)
    assert card == "58.479,27.695", "the vagabond faction card is at %s, expected 58.479,27.695" % card
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
        if n == 12 and math.abs(e.pos[3] - 27.695) < 0.01 then return n end
      end
      return -1
    end""")()
    assert ok == 12, "no twelve-card deck on the vagabond row (got %s)" % ok

    # and the button is gone, with its art
    rt.execute("XML = ''")
    assert 'id="Vagabond Cards"' not in src, "the makeTool button is still declared"
    assert '{name = "Vagabond Cards"' not in src, "the button art is still registered"


def menu_xml(xml):
    """The board's own menu, with the pages that hide behind it taken out.

    Two ToggleGroups sit in the same XmlUI as the menu and are inactive until something opens them --
    the credits parchment and, since 2026-09-10, the More rows. Their buttons carry positions of their
    own, so a scan that reads every Button on the board counts them as extra rows and gets the layout
    wrong. They are cut out here rather than filtered by id, so a button relegated to More later is
    excluded by being IN the page rather than by being named.
    """
    for gid in ("moreButtons", "creditsPanel"):
        while True:
            i = xml.find('<ToggleGroup id="%s"' % gid)
            if i < 0:
                break
            j = xml.find("</ToggleGroup>", i)
            xml = xml[:i] + xml[j + len("</ToggleGroup>"):]
    return xml


def t_the_two_free_button_slots_are_bottom_right(src):
    """Where the spare option slots sit, and who sits where.

    Maintainer, 2026-09-05: "the two empty button option should be in the second row to the right".
    Then 2026-09-07, with the turn panel: "put the credits option button to the bottom right replace
    the position with the faction cards button. the new option button for the new clock/counter should
    be second row to the leftmost."

    So Credits went to the bottom-right slot and Faction Cards took the spot it left in the FIRST row.
    The Turn Panel toggle held x=19 of row two until "remove the button turn panel" (2026-09-07), which
    left two spares; both went on 2026-09-09 -- Clear All Objects to x=19 and Flotilla Draft to x=57 --
    so the board is full, with Credits still anchored at 95.

    A FULL BOARD IS THE ASSERTION NOW. There is nowhere left to put a button without moving one, which
    is the thing worth knowing before the next one is asked for.

    Reads the built save, because this is XmlUI on the board object rather than anything in the Lua.
    """
    x = json.load(open(os.path.join(REPO, "dist/Root_Tabletop_Tournament.json"),
                       encoding="utf-8"))["ObjectStates"]
    def walk(objs):
        for o in objs:
            yield o
            for c in (o.get("ContainedObjects") or []): yield from walk([c])
    xml = menu_xml([o for o in walk(x) if o.get("GUID") == "bab7e1"][0]["XmlUI"])

    import re as _re
    rows = {}
    for m in _re.finditer(r'<Button\b[^>]*>', xml):
        seg = m.group(0)
        # the y's are not whole numbers any more: the rows were spaced evenly on 2026-09-10 and land
        # on 51.5, 19.125, -13.25, -45.625, -78
        pos = _re.search(r'position="(-?[\d.]+) (-?[\d.]+) (-?[\d.]+)"', seg)
        w = _re.search(r'width="(\d+)"', seg)
        i = _re.search(r'id="([^"]*)"', seg)
        if pos and w and w.group(1) == "36":          # the 36x20 option buttons only
            rows.setdefault(float(pos.group(2)), {})[float(pos.group(1))] = i.group(1) if i else "?"
    SLOTS = [-95.0, -57.0, -19.0, 19.0, 57.0, 95.0]
    # THE ROWS ARE SPREAD OUT. Maintainer, 2026-09-10: "space all rows with the same space. do it so
    # you use better the space of the whole board", then "equalize the space between the rows of option
    # button and the deck button to be the same as the space between map and deck". They sit at 62.9, 23.8,
    # -15.3, -47.4, -70, which leaves the same 5.1 between every row above and about half of that
    # between the two option rows at the bottom.
    top, bottom = rows.get(-47.4, {}), rows.get(-70.0, {})
    assert len(top) == 6, "the first tool row has %d of 6 slots filled: %s" % (len(top), sorted(top))
    # AND FULL AGAIN. x=19 came free when the Rowdy Riverboat and Credits moved into the More page on
    # 2026-09-10; Resync took it the same day. There is nowhere left to put a button without moving
    # one, which is the thing worth knowing before the next one is asked for.
    free = [s for s in SLOTS if s not in bottom]
    assert free == [], "the last row has spare slots %s; the board is full" % free
    # THE LAST ROW, in the order he set it on 2026-09-10: "4 player setup, 5 player setup, 5 players
    # marsh, Rowdy Riverboat, Clear all items, credit."
    ORDER = ((-95.0, "rttFourBoardsBtn"), (-57.0, "Marsh5PSetup"), (-19.0, "Marsh5PMap"),
             (19.0, "rttResyncBtn"), (57.0, "rttClearAllBtn"), (95.0, "rttMoreBtn"))
    for x0, bid in ORDER:
        assert bottom.get(x0) == bid, "x=%s of the last row holds %s, not %s" % (x0, bottom.get(x0), bid)
    assert top.get(57) == "Faction Cards", "x=57 of row 1 holds %r, not Faction Cards" % top.get(57)
    # THE BOTTOM-RIGHT SLOT IS THE WAY ON, not a tool. Credits held it until the board ran out of
    # room; it and the Rowdy Riverboat moved into the More page behind it.
    assert bottom.get(95) == "rttMoreBtn", "the bottom-right slot holds %r, not More" % bottom.get(95)
    assert "rttCreditsBtn" not in bottom.values() and "rttFlotillaBtn" not in bottom.values(), \
        "Credits or the Riverboat is still on the main menu: %s" % sorted(bottom.values())


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
        # warnMap, not warn: a map button has no faction wording at all, which is what stops it ever
        # claiming to reset factions it does not touch.
        d = rt.eval("function(k) local e = RTT_WIPE_BTN[k] if e == nil then return 'missing' end "
                    "return tostring(e.map) .. '|' .. tostring(e.warnMap) .. '|' .. tostring(e.warn) end")(m)
        assert d == "%s|WipeConfirmMapArt|nil" % m, "%s has wipe entry %s" % (m, d)
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

    # THE MOLES' TUNNELS FILL A COLUMN OF THREE, one slot each, in order.
    #
    # Two spawn beside the board and the third starts out on the map, so it had no slot of its own
    # and tunnels were excused the fill order entirely -- each went back to where it came from.
    # Maintainer, 2026-09-09: "the spawning point of the tunnel that initially spawns to the left of
    # the moles cardboard should have a different returning point ... above the two other tunnels at
    # the same distance as between the two tunnels. fill the stack of tunnels with the lowest first."
    #
    # The extra slot is checked against the pair it continues rather than written out here, so the
    # spacing cannot drift from the two real spawn positions.
    extra = rt.eval('RTT_HOME_EXTRA["Underground Duchy"]')
    assert extra is not None and len(extra) >= 1, "the moles have no extra return slot"
    ex = extra[1]
    assert ex[1] == "Tunnel", "the moles' extra slot is for %s, not a Tunnel" % ex[1]
    ez, ex_x = ex[2][3], ex[2][1]
    low, high = 5.236, 6.911                      # the two that spawn beside the board
    assert abs(ez - (high + (high - low))) < 0.02, \
        "the third tunnel returns to z %.3f; one step above the pair is %.3f" % (ez, high + high - low)
    assert abs(ex_x - 10.107) < 0.2, \
        "the third slot is at x %.3f, out of the column the other two share" % ex_x

    # ...and three returning tunnels take three DIFFERENT slots, walking the column in order.
    rt.execute("""
      RTT_HOME = {}
      RTT_HOME['t1'] = { n='Tunnel', f='Underground Duchy', p={ 9.97,0.1,-51.24}, r={0,0,0} }
      RTT_HOME['t2'] = { n='Tunnel', f='Underground Duchy', p={10.04,0.1,-52.91}, r={0,0,0} }
      RTT_HOME['t3'] = { n='Tunnel', f='Underground Duchy', p={10.11,0.1,-54.59}, r={0,0,0} }
      Global.setVar("RTT_SEAT_COLOR", JSON.encode({ ["Underground Duchy"] = "Red" }))
      LANDED = {}
      for i = 1, 3 do
        local t = MKOBJ('Tunnel', {40, 5, 40}, {})
        HOVER['Red'] = t
        rttGizmoHome('Red')
        LANDED[i] = t.__pos.z
      end
    """)
    got = [round(float(rt.eval("LANDED[%d]" % i)), 2) for i in (1, 2, 3)]
    assert len(set(got)) == 3, \
        "three tunnels went to %s; each should take its own slot" % got
    assert got == sorted(got), \
        "the column filled in the order %s; it should walk it end to end, lowest first" % got

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

    The RATS were left out of that restore as a "deliberate exception", and were the same mistake:
    2026-09-09, "you moved the stronghold that spawns separately from the others at the spawning of
    the rats faction, but where it is is just the default position where they come back with numpad 0,
    not the starting position." So 1.217 is the row's sixth RETURN slot -- one the whole row shares:
    "that slot is for all the strongholds and these slots are filled rightmost empty first like for
    the other carboard" -- and the piece spawns parked, well clear of the row.

    WHERE it spawns is his, not the base mod's: "look at the save rats it has the position of the
    pieces that should be at spawn." He spawned the rats and moved six pieces by hand -- the sixth
    stronghold to -10.35, the warlord to -6.49, the four warriors 0.42 further left -- and everything
    else in that save matches the blueprint to four decimals, which is what makes those six readable
    as deliberate. The supply stayed where it was.
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

    # and the rats' sixth stronghold, which was the same mistake: parked at -10.35 in the blueprint,
    # returning to 1.217 at the left end of the row
    rt = fresh(src)
    rt.execute("SEAT('Purple','H1') pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(10)")
    rt.execute("RTT_HOME = {} SPAWNED = {}")
    rt.execute("local _s = spawnObjectJSON "
               "spawnObjectJSON = function(p) local o = _s(p) "
               "  local n = o.getName() or '' "
               "  SPAWNED[n] = SPAWNED[n] or {} "
               "  SPAWNED[n][#SPAWNED[n]+1] = o.__pos.x - 52 "
               "  return o end")
    rt.execute("""pcall(function() rttPlaceFaction('Lord of the Hundreds', 52, -46, false, 'Purple',
                        false, nil, nil, 'Purple', nil) end) FLUSH(40)""")
    spawned = sorted(float(v) for v in rt.eval("SPAWNED")["Stronghold"].values())
    assert any(abs(v + 10.35) < 0.1 for v in spawned), \
        "the parked stronghold no longer SPAWNS at -10.35; the blueprint was changed: %s" % spawned
    assert not any(abs(v - 1.217) < 0.05 for v in spawned), \
        "a stronghold still SPAWNS on the row's sixth slot at 1.217: %s" % spawned

    slots = rt.eval("""function()
      local t = {}
      for _, s in ipairs(rttHomeSlots('Stronghold')) do t[#t+1] = string.format('%.3f', s.p[1] - 52) end
      return table.concat(t, ',')
    end""")()
    xs = [float(v) for v in slots.split(",")]
    assert len(xs) == 6, "expected 6 stronghold return slots, got %d: %s" % (len(xs), xs)
    assert not any(abs(v + 10.35) < 0.1 for v in xs), \
        "the parked spot is still a RETURN slot; the row's sixth is 1.217 instead: %s" % xs
    assert abs(min(xs) - 1.217) < 0.05, "the extra return slot is not at 1.217: %s" % xs
    assert xs == sorted(xs, reverse=True), "return slots are not ordered rightmost-first: %s" % xs
    gaps = [round(xs[i] - xs[i + 1], 2) for i in range(5)]
    assert all(abs(g - 1.41) < 0.02 for g in gaps), \
        "the six return slots are not evenly spaced: %s" % gaps


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


def t_a_new_game_leaves_the_map_alone_but_fixes_the_marsh_variant(src):
    """A new game does not touch the map -- except when the Marsh has to swap boards.

    Maintainer, 2026-09-07: "nothing should be reset when clicking on 4 player setup". A new game used
    to re-place whatever map it found; on six of the eight that put the identical board straight back,
    and on the Marsh and the Mountain it quietly re-rolled a board the table had already set up.

    THE ONE EXCEPTION IS NOT A PREFERENCE. The Marsh has two different boards behind one button -- the
    four-player one is flooded, the five-player one has three town landmarks and no flooding -- and a
    game cannot be played on the wrong one. This is the bug that was reported twice: "spawning marsh 4
    players after marsh 5 players still does not span the flooded clearings properly and keep the
    landmarks." So the board is rebuilt when, and only when, the variant no longer fits the game about
    to start, which is what RTT_MARSH_5P_BUILT records.
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

    # AND OTHERWISE THE MAP IS LEFT COMPLETELY ALONE. Eight four-player games in a row on the same
    # Marsh: one flood layout, because none of them has any business re-rolling it. Maintainer,
    # 2026-09-07: "nothing should be reset when clicking on 4 player setup". This assertion used to
    # read the other way round -- a new game deliberately re-rolled the board -- which is what made a
    # setup click destructive enough to need a warning in the first place.
    rt3 = fresh(src)
    for c, n in zip(["Purple", "Blue", "White", "Pink", "Green"], ["H1", "H2", "H3", "H4", "H5"]):
        rt3.execute("SEAT('%s','%s')" % (c, n))
    rt3.execute("pcall(function() makeMap(Player['Purple'],'','Marsh Map') end) FLUSH(200)")
    first = rt3.eval(FLOOD)()
    board0 = rt3.eval(BOARD)()
    seen = {first}
    for _ in range(8):
        two_clicks(rt3, "rttArmRanked", "rttRankedBtn")
        seen.add(rt3.eval(FLOOD)())
    assert seen == {first}, \
        "a new game re-rolled the flooding it was given; the table set that board up: %s" % seen
    assert rt3.eval(BOARD)() == board0, "a new game respawned the board it was told to leave alone"

    # ...and a MAP button is still how you ask for a fresh roll.
    rolls = {first}
    for _ in range(8):
        rt3.execute("pcall(function() makeMap(Player['Purple'],'','Marsh Map') end) FLUSH(200)")
        rolls.add(rt3.eval(FLOOD)())
    assert len(rolls) > 1, "the Marsh button stopped re-rolling the flooding: %s" % rolls


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

    The wording follows what is actually at stake, and so does whether there is a prompt at all: a
    setup button puts the same map straight back, so with only a map down it says nothing.
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

    # EVERY BUTTON WARNS ABOUT WHAT IT WILL ACTUALLY DO -- no more, and no less. `None` means no
    # prompt at all, because nothing would change and the click just runs.
    #
    # A MAP button only ever places a map, so it says map whatever is on the table and can never claim
    # to touch a faction -- but asking for the map that is ALREADY down changes nothing either.
    # A SETUP button clears the factions and leaves the map exactly where it is: with factions down
    # it costs you the factions, with none it costs you nothing at all. Maintainer, 2026-09-07: "If I spawn a map then click on the 4 player
    # setup it warns that this will wipe the map. that is not true. revise your warnings!!" -- and the
    # rule: "if factions would be wiped, warn about faction wipe. if map would be reset, warn about
    # that. it needs to make sense."
    #
    # The Marsh is the counter-case, checked straight after: it re-rolls its layout on every build, so
    # there a setup click IS a map reset. Earlier readings of this table got it wrong in both
    # directions -- "Put back the appropriate warning to the appropriate buttons!" killed a rule that
    # swapped every button's wording by table state, and "This will reset the map BUT ONLY IF IT
    # INDEED DOES!!!" killed the one that replaced it.
    WORDING = (("rttArmMarsh5PMap", "Marsh5PMap",       "WipeConfirmMapArt", "WipeConfirmMapArt"),
               ("rttArmMap",        "Lake Map",         "WipeConfirmMapArt", "WipeConfirmMapArt"),
               ("rttArmMap",        "Summer Map",       None,                None),
               ("rttArmMarsh5P",    "Marsh5P",          None,                "WipeConfirmArt"),
               ("rttArmFiveSetup",  "Marsh5PSetup",     None,                "WipeConfirmArt"),
               ("rttArmFour",       "rttFourBoardsBtn", None,                "WipeConfirmArt"),
               ("rttArmRanked",     "rttRankedBtn",     None,                "WipeConfirmArt"))
    for withFactions in (False, True):
        for fn, bid, mapOnly, withFac in WORDING:
            want = withFac if withFactions else mapOnly
            rt = fresh_seated()
            rt.execute("pcall(function() makeMap(Player['Purple'],'','Summer Map') end) FLUSH(200)")
            if withFactions:
                rt.execute("pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(200)")
            click(rt, fn, bid)
            if want is None:
                assert armed(rt) == "nil", (
                    "%s prompted with factions=%s, but nothing it does would change: Autumn is put "
                    "back exactly as it was" % (bid, withFactions))
                continue
            assert armed(rt) == bid, "%s did not warn (factions on table: %s)" % (bid, withFactions)
            got = icon(rt, bid)
            assert got.startswith(want), (
                "%s shows %s with factions=%s; it should show %s"
                % (bid, got, withFactions, want))

    # THE ONE CASE A SETUP BUTTON REALLY DOES CHANGE THE MAP. The Marsh has two boards behind one
    # button and a four-player game cannot be played on the five-player one, so 4-Player Setup after a
    # 5-Players Marsh rebuilds it -- and has to say so. This is the half that keeps the rule above
    # from collapsing into "setup buttons never mention the map".
    rt = fresh_seated()
    rt.execute("pcall(function() rttPlaceMarsh5P(Player['Purple'],'','Marsh5PMap') end) FLUSH(300)")
    assert rt.eval("RTT_MARSH_5P_BUILT") is True, "the 5-player Marsh board was not recorded as built"
    click(rt, "rttArmFour", "rttFourBoardsBtn")
    assert armed(rt) == "rttFourBoardsBtn", \
        "4-Player Setup on the five-player Marsh did not warn, though it must swap the board"
    assert icon(rt, "rttFourBoardsBtn").startswith("WipeConfirmMapArt"), \
        "the Marsh variant swap warned about factions instead of the map: %s" \
        % icon(rt, "rttFourBoardsBtn")

    # ...and on the FOUR-player Marsh the very same button is silent, because nothing would change.
    rt = fresh_seated()
    rt.execute("pcall(function() makeMap(Player['Purple'],'','Marsh Map') end) FLUSH(300)")
    assert rt.eval("RTT_MARSH_5P_BUILT") is False, "a plain Marsh click recorded a five-player board"
    click(rt, "rttArmFour", "rttFourBoardsBtn")
    assert armed(rt) == "nil", \
        "4-Player Setup warned on a four-player Marsh, which it leaves exactly as it is"

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

    # AND A NEW GAME REPLACES NOTHING AT ALL. Maintainer, 2026-09-07: "box score and turn panel never
    # need to respawn especially when spawning factions or new maps", then "unclear they even need a
    # reset". A new game used to destroy the sheet and build a fresh one; clearing it is START's job
    # on the turn panel, which asks first, and nothing else decides the last game is finished with.
    rt.execute("pcall(function() rttArmRanked(Player['Purple'],'','rttRankedBtn') end) FLUSH_UNTIL(0.5,4)")
    rt.execute("pcall(function() rttArmRanked(Player['Purple'],'','rttRankedBtn') end) FLUSH(200)")
    after = fixtures(rt)
    for n in NAMES:
        assert len(after.get(n, [])) == 1, \
            "a new game left %s copies of the %s" % (len(after.get(n, [])), n)
        assert after[n] == first[n], \
            "%s was rebuilt by a new game; it is furniture, not a game piece (%s -> %s)" \
            % (n, first[n], after[n])


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


def t_numpad_two_lays_a_warrior_down_and_lights_it(src):
    """Down: flat on the board, locked, outlined in black. Up: exactly as it was.

    Maintainer, 2026-09-07: "pressing numpad 2 should put a warrior laying down ... and lock it.
    repressing numpad 2 undoes all of that." How it is MARKED went three ways in a day -- the piece was
    tinted cream, then a translucent disc was drawn under it in the presser's colour, then that was
    withdrawn for the outline: "make the highlight numpad 2 and remove current numpad 2 option".

    So there is one key and one mark. The piece keeps its own paint either way -- repainting it lost
    the faction's colour and read as damage to the piece -- and nothing is spawned on the board, which
    is what a disc was: an object, locked and non-interactable, that only this script could remove.

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
    rt.execute('HOVER["Red"] = MINE rttGizmoMark("Red") '
               'MINE.__bounds = {size = Vector({1, 1, 3}), center = Vector({1, 2.5, 1})} FLUSH(3)')
    rot, locked, pos = state("MINE")
    assert locked is True, "a laid warrior was not locked"
    assert rot == (90.0, 137.0), "it is not lying flat, or laying it down turned it: %s" % (rot,)
    assert pos[1] == 0.03, "it did not settle onto the board, a hair above its foot: y %s" % pos[1]

    # THE PIECE KEEPS ITS OWN COLOUR, faded. It used to keep its paint untouched and be marked by the
    # outline alone; that outline is a thin line and easy to lose on a board of thirty warriors, so
    # since 2026-09-09 the piece fades as well ("maybe add a like fog effect so the color looks like
    # it s fader"). What it must never do is come out a DIFFERENT colour, or forget the one it had --
    # t_a_prisoner_goes_pale covers the fade itself; this covers the piece it is applied to.
    t = rt.eval("MINE.getColorTint()")
    assert (round(t.r, 2), round(t.g, 2), round(t.b, 2)) != (1.0, 1.0, 1.0), \
        "the warrior was not faded: %s" % (t,)
    assert round(t.r, 4) == round(t.g, 4) == round(t.b, 4), \
        "a white warrior came out a colour: %s" % (t,)
    rt.execute('HOVER["Red"] = MINE rttGizmoMark("Red") FLUSH(3)')
    t = rt.eval("MINE.getColorTint()")
    assert (round(t.r, 2), round(t.g, 2), round(t.b, 2)) == (1.0, 1.0, 1.0), \
        "standing it up did not give the warrior its own colour back: %s" % (t,)
    rt.execute('HOVER["Red"] = MINE rttGizmoMark("Red") '
               'MINE.__bounds = {size = Vector({1, 1, 3}), center = Vector({1, 2.5, 1})} FLUSH(3)')
    glow = rt.eval("MINE.__glow")
    assert glow is not None, "numpad 2 did not light the piece"
    # BLACK. TTS fixes the outline's thickness and gives no intensity, so colour is the only thing that
    # can make the mark carry -- and a player colour outlines a warrior already painted in it, on a map
    # printed in the same palette. Maintainer: "make it black highlighted." It was tried in white
    # beside the new fade ("can you do a white highlight now to test instead of the black") and settled
    # the same day: "ok keep black highlight for all not white." Four factions' warriors are flat white
    # already and the fade lifts them further, so a white outline would have had nothing to sit on.
    assert (round(glow.r, 3), round(glow.g, 3), round(glow.b, 3)) == (0.0, 0.0, 0.0), \
        "the outline is not black: %s %s %s" % (glow.r, glow.g, glow.b)
    assert round(rt.eval("RTT_PLAYER_RGB['Red']")[1], 3) != 0.0, \
        "this check proves nothing if Red is already black"

    # NOTHING IS SPAWNED. The disc was an object on the table, and it is gone.
    assert not rt.eval("LASTJSON"), "numpad 2 spawned something: %s" % (rt.eval("LASTJSON") or "")[:160]
    assert rt.eval("#getObjectsWithTag('RTT Laid Disc')") == 0, "a disc was drawn under the piece"

    # a colour change leaves it alone. Trivial for a black outline, but WHO laid it is still pinned at
    # the press, and this is the path that used to follow the person -- in hotseat, where one person
    # holds every colour, changing colour redrew every mark they had made at once.
    rt.execute("SEAT('Yellow', Player['Red'].steam_name) onPlayerChangeColor('Yellow') FLUSH(5)")
    assert rt.eval("MINE.__glow") is not None, "changing colour put the mark out"
    assert rt.eval("RTT_LAID[MINE.getGUID()].who") == "Red", "who laid it is not pinned at the press"

    # and it all comes back
    rt.execute('HOVER["Red"] = MINE rttGizmoMark("Red") FLUSH(3)')
    assert state("MINE") == before, "standing it back up did not restore it: %s" % (state("MINE"),)
    assert rt.eval("MINE.__glow") is None, "the outline outlived the piece being stood up"

    # A DISC FROM AN OLDER GAME STILL COMES UP. It spawned locked and non-interactable, so nothing but
    # this path can remove one, and a save made before the option was withdrawn still holds records
    # naming them. Standing the piece up must still destroy the disc its record names.
    rt.execute("""
      OLDDISC = MKOBJ("", {1,0.1,1}, {"RTT Laid Disc"})
      HOVER["Red"] = MINE
      rttGizmoMark("Red") FLUSH(3)
      RTT_LAID[MINE.getGUID()].disc = OLDDISC.getGUID()
      rttGizmoMark("Red") FLUSH(3)
    """)
    assert rt.eval("#getObjectsWithTag('RTT Laid Disc')") == 0, \
        "a disc recorded by an older save was stranded on the table; nobody can pick one up by hand"

    # the old names still answer, because a hotkey bound before the change calls one of them and a
    # pcall'd call on a missing function fails silently
    for fn in ("rttGizmoLay", "rttGizmoGlow"):
        rt.execute('HOVER["Red"] = THEIRS %s("Red") FLUSH(3)' % fn)
        assert state("THEIRS")[1] is (fn == "rttGizmoLay"), "%s no longer marks a piece" % fn

    # any warrior, not only your own -- and nothing that is not a warrior
    rt.execute('HOVER["Red"] = THEIRS rttGizmoMark("Red") FLUSH(3)')
    assert state("THEIRS")[1] is True, "numpad 2 refused an opponent's warrior"
    rt.execute('HOVER["Red"] = ROOST rttGizmoMark("Red") FLUSH(3)')
    assert state("ROOST")[1] is False, "numpad 2 laid a building down"


def t_the_marsh_numbers_sit_where_his_save_puts_them(src):
    """Every Marsh clearing whose number he moved is where he left it, and the rest are untouched.

    Maintainer, 2026-09-10: "in drop folder I put a marsh json. use the new clearing number positions
    used in that file for all the clearings. forget obviously about the numbers this is only to
    recalibrate slightly the positions used. some clearing have no repositionning clearing markers, for
    these ones do not change anything. carefull what you do."

    The Marsh cannot be checked the way the other maps are. Its numbers are not a fixed list: the flood
    re-rolls on every build, so which clearings get one changes, and the save holds 13 of the 15. What
    is stored is a SPOT PER CLEARING (RTT_MARSH_RANK's last two columns), and the save's tokens have to
    be matched back to those spots before anything can be said about them.

    Matched by nearest, one to one, globally. That is safe here and the numbers say so: every token's
    second-nearest stored spot is 5 to 14 units further away than its first, so no pairing is a close
    call. Six were small corrections of a unit or so; seven were spots that had been plain wrong, up to
    8 units out, which is the same thing that was found on the Mountain. Two clearings -- B.down and
    C.down -- have no token in his save and keep the spots they had.
    """
    import math
    saved = json.load(open(os.path.join(REPO, "assets", "src_art", "saves", "marsh.json"),
                           encoding="utf-8"))
    toks = []
    def walk(o):
        if isinstance(o, dict):
            if "RTT Priority" in (o.get("Tags") or []):
                toks.append((o["Transform"]["posX"], o["Transform"]["posZ"]))
            for k, v in o.items():
                if k in ("ContainedObjects", "ObjectStates", "States"):
                    walk(v)
        elif isinstance(o, list):
            for v in o:
                walk(v)
    walk(saved)
    assert len(toks) == 13, "his save holds %d number tokens, expected 13" % len(toks)

    rt = fresh(src)
    got = rt.eval("""function()
      local t = {}
      for _, r in ipairs(RTT_MARSH_RANK) do
        t[#t+1] = string.format('%.3f;%.3f', r[4], r[5])
      end
      return table.concat(t, '|')
    end""")()
    spots = [tuple(float(v) for v in r.split(";")) for r in got.split("|")]
    assert len(spots) == 15, "the Marsh has %d clearings, expected 15" % len(spots)

    # every token he placed is now a stored spot, to the last decimal
    for x, z in toks:
        near = min(math.hypot(x - sx, z - sz) for sx, sz in spots)
        assert near < 1e-3, \
            "the token at (%.3f, %.3f) is %.3f from any stored spot; his save is the source" % (
                x, z, near)

    # ...and the two clearings he left alone still have theirs
    UNTOUCHED = ((5.948, -3.427), (-0.883, -13.135))          # B.down and C.down
    for sx, sz in UNTOUCHED:
        assert any(abs(a - sx) < 1e-3 and abs(b - sz) < 1e-3 for a, b in spots), \
            "the spot at (%.3f, %.3f) was changed; his save has no marker there" % (sx, sz)

    # NO TWO CLEARINGS SHARE A SPOT. A mis-pairing would show up here rather than as a wrong number:
    # two clearings pointing at one token is exactly what a greedy match gets wrong when it is wrong.
    assert len({(round(x, 2), round(z, 2)) for x, z in spots}) == 15, \
        "two Marsh clearings put their number in the same place"


def t_the_clearing_numbers_sit_where_the_saves_put_them(src):
    """Every clearing number is where the maintainer's own save has it, to the last decimal.

    2026-09-07: "Use the file montain.json in the folder to recalibrate the position of the clearing
    numbers use these ones for mountain map", and then, when I had gone looking in root_engine instead
    of for his save: "you dingus we don t use the official numbering this is the position of the
    clearing numbers use the precise position as provided." Then 2026-09-09, the same again for two
    more maps: "in the drop folder I put two saves for the position of the coffin when it spawns and
    the position of the clearing number for autumn and lake use these." Then 2026-09-10, the last two:
    "the drop folder contains gorge and winter map use them for the calibration of the position of the
    clearing numbers. you can replace all the clearing numbers for these two maps with these ones."

    So this is not a renumbering and not a fit. The mod's numbering is its own, and the save says where
    each of those numbers goes; on the Mountain eight of the twelve were wrong, one of them by 41 units
    -- on the far side of the board. The tokens are matched to the save by their ARTWORK URL, which is
    the only thing that identifies which number a blob carries: the blobs have no nickname and are not
    in numeric order.

    His saves are kept under assets/src_art/saves/ so this can be re-checked rather than trusted.
    """
    CASES = (("mountain.json",  "RTT_PRIO_MOUNTAINMAP", "Mountain"),
             ("autumn.json",    "RTT_PRIO_SUMMERMAP",   "Autumn"),
             ("lakecoffin.json", "RTT_PRIO_LAKEMAP",    "Lake"),
             ("winter.json",    "RTT_PRIO_WINTERMAP",   "Winter"),
             ("gorge.json",     "RTT_PRIO_GORGEMAP",    "Gorge"))
    for fname, table, mapname in CASES:
        saved = json.load(open(os.path.join(REPO, "assets", "src_art", "saves", fname),
                               encoding="utf-8"))
        want = {}
        for o in saved["ObjectStates"]:
            if "RTT Priority" in (o.get("Tags") or []):
                want[(o.get("CustomImage") or {}).get("ImageURL", "")] = o["Transform"]
        assert len(want) == 12, \
            "%s holds %d priority tokens, expected 12" % (fname, len(want))

        i = src.index(table + " = {")
        blobs = re.findall(r"\[==\[(.*?)\]==\]", src[i:src.index("\n}", i)], re.S)
        assert len(blobs) == 12, \
            "the %s ships %d number tokens, expected 12" % (mapname, len(blobs))

        got = {}
        for b in blobs:
            u = re.search(r'"ImageURL":"([^"]+)"', b).group(1)
            m = re.search(r'"posX":([-\d.E]+),"posY":([-\d.E]+),"posZ":([-\d.E]+)', b)
            got[u] = (float(m.group(1)), float(m.group(2)), float(m.group(3)))
        assert set(got) == set(want), \
            "the %s blueprint and the save disagree about which number tokens exist: %s" \
            % (mapname, sorted({u[-14:] for u in set(got) ^ set(want)}))

        for u, (x, y, z) in got.items():
            tr = want[u]
            for axis, mine, theirs in (("x", x, tr["posX"]), ("y", y, tr["posY"]), ("z", z, tr["posZ"])):
                assert abs(mine - theirs) < 1e-4, \
                    "%s number ...%s is %.3f off in %s: blueprint %.4f, save %.4f" \
                    % (mapname, u[-14:], abs(mine - theirs), axis, mine, theirs)

        # THE TWELVE ARE DISTINCT PLACES. A copy-paste that gave two numbers the same transform would
        # satisfy every check above and leave a clearing unnumbered.
        spots = {(round(x, 2), round(z, 2)) for x, _, z in got.values()}
        assert len(spots) == 12, \
            "two %s numbers share a position: %d distinct spots" % (mapname, len(spots))


def t_the_coffin_spawns_where_he_put_it(src):
    """The Koffin Keeper lands on the spot in the "lakecoffin" save, standing the way he left it.

    Maintainer, 2026-09-09: "in the drop folder I put two saves for the position of the coffin when it
    spawns and the position of the clearing number for autumn and lake use these."

    makeTool does not spawn a tool where its blueprint transform says. It reads move_to, turns it
    through a fixed arithmetic -- x becomes z + 53.31, z becomes -x - 1.38, y becomes y + 11.46 -- and
    then its callback adds 90 degrees to the facing. So neither the position nor the rotation in the
    blueprint is the one the piece ends up with, and both have to be worked backwards from where he
    put it. The Keeper is spawned LOCKED, so what the save holds is exactly where it was placed, with
    no settling in between: this can be checked to the last decimal.
    """
    saved = json.load(open(os.path.join(REPO, "assets", "src_art", "saves", "lakecoffin.json"),
                           encoding="utf-8"))
    his = [o for o in saved["ObjectStates"] if (o.get("Nickname") or "") == "Koffin Keeper"]
    assert len(his) == 1, "the save holds %d Koffin Keepers" % len(his)
    want = his[0]["Transform"]

    rt = fresh(src)
    rt.execute("SPAWNED = {} "
               "local _s = spawnObjectJSON "
               "spawnObjectJSON = function(p) local o = _s(p) "
               "  local n = o.getName() or '' "
               "  if n == 'Koffin Keeper' then "
               "    SPAWNED[#SPAWNED+1] = string.format('%.4f/%.4f/%.4f/%.4f', "
               "      o.__pos.x, o.__pos.y, o.__pos.z, o.__rot.y) end "
               "  return o end")
    rt.execute("pcall(function() makeTool(Player['Red'], '', 'Koffin Keeper') end) FLUSH(10)")
    got = list(rt.eval("SPAWNED").values())
    assert len(got) == 1, "the Koffin Keeper button spawned %d pieces" % len(got)
    x, y, z, ry = (float(v) for v in got[0].split("/"))
    for axis, mine, theirs in (("x", x, want["posX"]), ("y", y, want["posY"]), ("z", z, want["posZ"])):
        assert abs(mine - theirs) < 1e-3, \
            "the coffin lands %.3f off in %s: %.4f, his save says %.4f" \
            % (abs(mine - theirs), axis, mine, theirs)
    assert abs(ry % 360 - want["rotY"] % 360) < 0.1, \
        "the coffin faces %.2f; his save has it at %.2f (makeTool adds 90 to the blueprint)" \
        % (ry % 360, want["rotY"] % 360)


def t_a_prisoner_goes_pale(src):
    """Numpad 3 fades the piece toward white and gives its colour back when it stands up.

    Maintainer, 2026-09-09: "for numpad 3, the prisoner option, can you make the color of the piece
    brighter. so each piece keeps its color but becomes much brighter; still with the black tint",
    and on how: "its not the tint it s the color of the piece itself you need to change to lighter
    version of it. if its already white then thats it. maybe add a like fog effect so the color looks
    like it s fader."

    A LIGHTEN, not a value boost. Moving each channel toward white keeps the piece's own colour,
    washes it out like fog, and can never clip -- which also answers "if its already white then thats
    it". Scaling the value up would have brightened the eight factions whose warriors carry a real
    faction colour and done nothing for the crows, the Keepers and the Knaves, which ship at flat
    white with no headroom at all.

    The black outline stays: it is what says "marked", and the fade is what makes it findable across
    a board of thirty warriors.
    """
    rt = fresh(src)
    fade = rt.eval("RTT_PRISONER_FADE")
    assert fade is not None, "there is no prisoner fade; numpad 3 only outlines the piece"
    assert 0 < fade < 1, "the fade is not a fraction of the way to white: %s" % fade

    def faded(c):
        got = rt.eval("function(r,g,b) local f = rttFaded({r=r,g=g,b=b}) "
                      "return string.format('%.4f/%.4f/%.4f', f[1], f[2], f[3]) end")(*c)
        return [float(v) for v in got.split("/")]

    for name, c in (("Eyrie blue", (0.145, 0.457, 0.810)),
                    ("Hundreds red", (0.867, 0.118, 0.212)),
                    ("Council brown", (0.588, 0.294, 0.176))):
        got = faded(c)
        want = [v + (1 - v) * fade for v in c]
        assert max(abs(a - b) for a, b in zip(got, want)) < 1e-3, \
            "%s faded to %s, wanted %s" % (name, got, want)
        assert all(g > v for g, v in zip(got, c)), "%s did not get lighter: %s" % (name, got)
        assert all(g <= 1.0001 for g in got), "%s clipped past white: %s" % (name, got)
        # its own colour, still: the channels keep their order, so the hue is recognisable
        assert sorted(range(3), key=lambda i: got[i]) == sorted(range(3), key=lambda i: c[i]), \
            "%s came out a different colour: %s -> %s" % (name, c, got)

    # AND THE FOUR THAT SHIP AT FLAT WHITE -- the crows, the Keepers, the Knaves and the Infected.
    # Maintainer, 2026-09-09: "you need to do all possible warrior pieces right." Their colour is
    # painted into the model rather than laid over it, so moving white toward white is nothing and
    # those four went down looking exactly as they stood. A tint is a multiplier, so the only lever
    # left is past 1, which overbrightens the model's own paint.
    white = faded((1.0, 1.0, 1.0))
    assert min(white) > 1.0, "a flat-white warrior is not marked at all: %s" % white
    assert len(set(round(v, 6) for v in white)) == 1, "the overbright is not neutral: %s" % white

    # ...AND ONLY WHEN THE WHOLE COLOUR IS THERE. The Marquise's orange is already 1.0 in red, and
    # overbrightening that one channel would turn the piece a different colour.
    cat = faded((1.0, 0.582, 0.260))
    assert cat[0] <= 1.0, "a piece with one maxed channel was overbrightened: %s" % cat

    # every warrior kind this mod ships, and not one of them left unchanged
    WARRIORS = {"Cat": (1.000, 0.582, 0.260), "Eyrie": (0.145, 0.457, 0.810),
                "Alliance": (0.372, 0.793, 0.355), "Lizard Cult": (0.905, 0.898, 0.172),
                "Riverfolk": (0.246, 0.777, 0.817), "Duchy": (0.939, 0.817, 0.695),
                "Corvid": (1.0, 1.0, 1.0), "Hundreds": (0.867, 0.118, 0.212),
                "Keeper": (1.0, 1.0, 1.0), "Council": (0.588, 0.294, 0.176),
                "Diaspora": (0.690, 0.596, 0.016), "Knaves": (1.0, 1.0, 1.0),
                "Infected": (1.0, 1.0, 1.0)}
    for who, c in sorted(WARRIORS.items()):
        got = faded(c)
        assert max(abs(a - b) for a, b in zip(got, c)) > 0.05, \
            "the %s Warrior is not marked: %s -> %s" % (who, c, got)

    # AND ON A REAL PIECE, both halves: pale, and still outlined in black
    rt.execute("W = MKOBJ('Eyrie Warrior', {3, 1, 3}, {}) "
               "W.setColorTint({0.145, 0.457, 0.810}) "
               "HOVER['Red'] = W rttGizmoMark('Red') FLUSH(6)")
    def tint(v):
        got = rt.eval("function(o) local c = o.getColorTint() "
                      "return string.format('%.4f/%.4f/%.4f', c.r, c.g, c.b) end")(rt.eval(v))
        return [float(x) for x in got.split("/")]
    assert tint("W") == faded((0.145, 0.457, 0.810)), \
        "the prisoner was not faded: %s" % tint("W")
    assert rt.eval("function() return W.__glow ~= nil end")() is True, \
        "the prisoner lost its black outline"
    assert rt.eval("function() return W.__locked end")() is True, "the prisoner was not locked"

    # ITS OWN COLOUR COMES BACK, exactly. Un-fading by moving back from white is a division that
    # loses the colour once a channel reaches 1, so what it was is kept in the record instead.
    rt.execute("HOVER['Red'] = W rttGizmoMark('Red') FLUSH(6)")
    assert [round(v, 4) for v in tint("W")] == [0.145, 0.457, 0.810], \
        "standing the prisoner up did not give its colour back: %s" % tint("W")
    assert rt.eval("function() return W.__glow == nil end")() is True, "the outline was left on"

    # AND THE RECORD CARRIES IT, so a reload can still undo the fade -- RTT_LAID is in onSave
    rt.execute("HOVER['Red'] = W rttGizmoMark('Red') FLUSH(6)")
    saved = rt.eval("function() return onSave() end")()
    assert '"tint"' in saved, "the saved record does not carry the piece's colour: %s" % saved[:200]


def t_more_holds_what_the_board_ran_out_of_room_for(src):
    """The last slot swaps the two option rows for two of its own, and leaves the rest of the board.

    Maintainer, 2026-09-10: "the last option button should be called more and spawn two new rows of
    option buttons. the buttons relagated to more is the credit button and the riverboat button", then
    on what it may touch: "the only thing that more should do is spawn a new last two rows of option
    buttons but everything else shhould stay in place", and plainly: "it replaces the two rows of
    option buttons obviously do not add two more."

    So the drafts, the maps and the decks DO NOT MOVE and do not go away -- only the bottom two rows
    change hands. That is the whole of the test: moreButtons on, optionRows off, everything else as it
    was. Its rows use the same six columns as the rows they replace, so anything relegated later drops
    in beside these two, and Back sits in More's own slot -- the same square is the way in and out.
    """
    x = json.load(open(os.path.join(REPO, "dist/Root_Tabletop_Tournament.json"), encoding="utf-8"))
    def walk(objs):
        for o in objs:
            yield o
            for c in (o.get("ContainedObjects") or []):
                yield from walk([c])
    board = [o for o in walk(x["ObjectStates"]) if o.get("GUID") == "bab7e1"][0]
    xml = board["XmlUI"]

    i = xml.find('<ToggleGroup id="moreButtons"')
    assert i >= 0, "there is no More page"
    page = xml[i:xml.find("</ToggleGroup>", i)]
    assert 'active="False"' in page.split(">")[0], "the More page is open by default"

    ids = re.findall(r'<Button id="([^"]*)"', page)
    for bid in ("rttFlotillaBtn", "rttCreditsBtn"):
        assert bid in ids, "%s is not on the More page: %s" % (bid, ids)
    assert "rttMoreBack" in ids, "the More page has no way back: %s" % ids

    # its rows sit on the option columns, so a third button lands beside them rather than anywhere
    COLUMNS = (-95.0, -57.0, -19.0, 19.0, 57.0, 95.0)
    for m in re.finditer(r'<Button id="(rttFlotillaBtn|rttCreditsBtn)"[^>]*position="(-?[\d.]+) ', page):
        assert float(m.group(2)) in COLUMNS, \
            "%s sits at x %s, off the option columns" % (m.group(1), m.group(2))

    # AND IT IS REACHED AND LEFT the way the credits page is
    # ...AND THE ELEVEN BUTTONS IT REPLACES ARE A GROUP OF THEIR OWN, which is what lets it replace
    # them: they used to be spread across setupButtons and tools1, which also hold the top row.
    rows = xml[xml.find('<ToggleGroup id="optionRows"'):]
    rows = rows[:rows.find("</ToggleGroup>")]
    assert 'id="rttMoreBtn"' in rows, "More is not in the group it swaps out"
    for y in ("-47.4", "-70"):
        assert 'position="-95 %s ' % y in rows, "the option row at y %s is not in the group" % y
    assert 'position="19 62.9 ' not in rows, "the top row got swept into the option rows"

    rt = fresh(src)
    rt.execute("UIATTR = {} pcall(function() rttShowMore() end)")
    assert rt.eval("function() return tostring(UIATTR['moreButtons.active']) end")() == "True", \
        "More did not put its rows out"
    assert rt.eval("function() return tostring(UIATTR['optionRows.active']) end")() == "False", \
        "More added two rows instead of replacing the two that were there"
    for group in ("setupButtons", "mapButtonsStandard", "decksButtonsStandard"):
        assert rt.eval("function() return tostring(UIATTR['%s.active']) end" % group)() != "False", \
            "More took %s down with it; everything else should stay in place" % group
    rt.execute("pcall(function() rttHideMore() end)")
    assert rt.eval("function() return tostring(UIATTR['moreButtons.active']) end")() == "False", \
        "Back did not put the More rows away"
    assert rt.eval("function() return tostring(UIATTR['optionRows.active']) end")() == "True", \
        "Back did not bring the option rows back"

    # ...and coming out of CREDITS lands on More, because that is where its button lives now. Credits
    # IS a full page, so this is also the one path that has to put the rest of the board back up.
    rt.execute("UIATTR = {} pcall(function() rttShowCredits() end) pcall(function() rttHideCredits() end)")
    assert rt.eval("function() return tostring(UIATTR['moreButtons.active']) end")() == "True", \
        "leaving the credits page drops you on a menu with no Credits button on it"
    assert rt.eval("function() return tostring(UIATTR['setupButtons.active']) end")() == "True", \
        "leaving the credits page left the drafts and maps off the board"


def t_the_top_row_is_four_drafts_on_the_map_grid(src):
    """Three drafts and the Theme, centred on the map row's own columns, with the rows evenly spaced.

    Maintainer, 2026-09-10: "switch the 4 player setup button with the 5 player draft button ... add a
    4th button to the left of the big buttons on top which is 3 player draft ... since now there are 4
    buttons, the 4 buttons on top should be centered and aligned with the even number of map buttons",
    and "also try to have an equal distance between the rows of every buttons".

    The map row is six buttons at -95, -57, -19, 19, 57, 95, so four centred on that grid are its inner
    four. 4-Player Setup went down to the tool row to make space, which is also why its warning art and
    5-Player Draft's swapped shapes -- the wipe warnings come square and wide, and they follow the
    BUTTON'S shape rather than the button.
    """
    x = json.load(open(os.path.join(REPO, "dist/Root_Tabletop_Tournament.json"), encoding="utf-8"))
    def walk(objs):
        for o in objs:
            yield o
            for c in (o.get("ContainedObjects") or []):
                yield from walk([c])
    board = [o for o in walk(x["ObjectStates"]) if o.get("GUID") == "bab7e1"][0]
    xml = menu_xml(board["XmlUI"])

    got = {}
    for m in re.finditer(r'<Button\b[^>]*>', xml):
        seg = m.group(0)
        pos = re.search(r'position="(-?[\d.]+) (-?[\d.]+) ', seg)
        w = re.search(r'width="([\d.]+)"', seg)
        h = re.search(r'height="([\d.]+)"', seg)
        i = re.search(r'id="([^"]*)"', seg)
        if pos and w and i:
            got[i.group(1)] = (float(pos.group(1)), float(pos.group(2)),
                               "%sx%s" % (w.group(1), h.group(1)))

    TOP = (("rtt3PBtn", -57.0), ("rttRankedBtn", -19.0), ("Marsh5P", 19.0), ("rttThemeBtn", 57.0))
    for bid, x0 in TOP:
        assert bid in got, "%s is not on the board" % bid
        assert got[bid][0] == x0, "%s is at x %s, not %s" % (bid, got[bid][0], x0)
        assert got[bid][1] == 62.9, "%s left the top row: y %s" % (bid, got[bid][1])
        assert got[bid][2] == "34x34", "%s is not a square button: %s" % (bid, got[bid][2])

    # centred on the map row's own columns, which is what "aligned with the map buttons" means
    maps = sorted(v[0] for k, v in got.items() if v[2] == "34x34" and v[1] == got["Summer Map"][1])
    assert maps == [-95.0, -57.0, -19.0, 19.0, 57.0, 95.0], "the map row moved: %s" % maps
    tops = sorted(v[0] for k, v in got.items() if v[1] == 62.9)
    assert tops == [-57.0, -19.0, 19.0, 57.0], "the top row is not the map grid's inner four: %s" % tops
    assert abs(sum(tops)) < 1e-9, "the top row is not centred: %s" % tops

    # 4-PLAYER SETUP WENT DOWN, as an option button
    assert got["rttFourBoardsBtn"][0] == -95.0 and got["rttFourBoardsBtn"][1] == -70.0, \
        "4-Player Setup is at %s, not the last row's left end" % (got["rttFourBoardsBtn"][:2],)
    assert got["rttFourBoardsBtn"][2] == "36x20", "4-Player Setup is not an option button"

    # THE SPACE BETWEEN ROWS IS THE VISIBLE ONE, not the distance between centres, and that is the
    # whole of why this took three passes. The top three rows are 34 tall and the option rows 20, so a
    # single centre spacing leaves a WIDER band under the deck row than between the map rows -- which
    # is what he was looking at: "equalize the space between the rows of option button and the deck
    # button to be the same as the space between map and deck".
    rows = {}
    for bid, (x0, y0, size) in got.items():
        if size in ("34x34", "36x20"):
            rows[y0] = float(size.split("x")[1])
    ys = sorted(rows, reverse=True)
    edge = [round((ys[i] - rows[ys[i]] / 2) - (ys[i + 1] + rows[ys[i + 1]] / 2), 3)
            for i in range(len(ys) - 1)]
    assert len(set(edge[:-1])) == 1, \
        "the rows leave %s between them; the first three should match" % edge[:-1]
    assert edge[0] == 5.1, "the rows leave %s between them, not 5.1" % edge[0]
    assert abs(edge[-1] - edge[0] / 2) < 0.1, \
        "the two option rows leave %s; half of %s is %s" % (edge[-1], edge[0], edge[0] / 2)

    # AND THE ROOT SIGN IS GONE. "remove entirely the root logo and the thing with birds we did."
    assert 'id="rootLogo"' not in xml, "the ROOT sign is still on the board"
    assert "Root Logo" not in json.dumps(board.get("CustomUIAssets") or []), \
        "the ROOT sign's art is still registered"


def t_the_three_player_draft_deals_four_militants_and_no_flotilla(src):
    """Three seats, four militant cards, and no hireling.

    Maintainer, 2026-09-10, asked what the new button runs: "it s 3 players, 4 militant cards, no
    flotilla" -- the Riverboat's own rules without its hireling, which the Riverboat button keeps.
    """
    rt = fresh(src)
    rt.execute("pcall(function() rtt3PStart(nil,nil,nil) end) FLUSH(200)")

    assert rt.eval("RTT_DN") == 4, "it seats %s players, not 3" % rt.eval("RTT_DN")
    facs = list((rt.eval("RTT_DRAFT_FACTIONS") or {}).values())
    assert len(facs) == 4, "it dealt %d faction cards, not 4: %s" % (len(facs), facs)
    MILITANT = {"Marquise de Cat", "Eyrie Dynasties", "Underground Duchy",
                "Lord of the Hundreds", "Keepers in Iron", "Lilypad Diaspora"}
    assert set(facs) <= MILITANT, "an insurgent was dealt: %s" % sorted(set(facs) - MILITANT)

    left = rt.eval("function() return #getObjectsWithTag('RTT Flotilla') end")()
    assert left == 0, "the 3-player draft brought %d Flotilla piece(s) with it" % left


def t_the_riverboat_button_only_puts_the_flotilla_out(src):
    """The Rowdy Riverboat spawns the hireling and touches nothing else.

    Maintainer, 2026-09-10: "the button for the riverboat options should just spawn the flotilla item
    and helper card nothing else", and "be called Rowdy Riverboat".

    It ran a whole draft for four builds -- three players, four militant cards -- and that draft is the
    3-Player Draft button now. What is left is the hireling: its card in the helper row, its boat under
    it, and no faction touched. Which also makes it the one entry in RTT_WIPE_BTN that destroys
    nothing, so it asks nothing and runs on a single click.
    """
    rt = fresh(src)
    rt.execute("pcall(function() rttFlotillaStart(nil,nil,nil) end) FLUSH(60)")
    assert rt.eval("RTT_DN") is None, \
        "the Riverboat button ran a draft: it seated %s" % rt.eval("RTT_DN")
    assert rt.eval("RTT_DRAFT_FACTIONS") is None or len(dict(rt.eval("RTT_DRAFT_FACTIONS"))) == 0, \
        "the Riverboat button dealt faction cards"
    n = rt.eval("function() return #getObjectsWithTag('RTT Flotilla') end")()
    assert n == 2, "it put out %d Flotilla pieces; expected the card and the boat" % n

    # IT NEVER ASKS, because it takes nothing away
    d = rt.eval("RTT_WIPE_BTN['rttFlotillaBtn']")
    assert d["warn"] is None and d["warnMap"] is None, \
        "the Riverboat carries a wipe warning for something it does not destroy"
    assert rt.eval("function() return rttWouldWipe(RTT_WIPE_BTN['rttFlotillaBtn']) end")() is False, \
        "the Riverboat would arm instead of running"

    # THE WHOLE ROW IS BUILT, not one card placed against it. "marsh 4p helper overlaps come on check
    # all maps properly and a be rigorous." Counted off the blueprints, the cards it has to share the
    # row with are not on one line to begin with: Summer and Gorge ship none, Winter/Lake/Mountain one
    # at z -11.85, the Marsh one at -17.94, and the five-player Marsh three towns at -19.135. So every
    # helper card is measured, ordered and set down from a fixed right edge -- nothing can overlap by
    # construction, whatever the map ships.
    rt = fresh(src)
    rt.execute("pcall(function() rttSpawnFlotillaKit() end) FLUSH(20) "
               "FLOT = rttFlotillaCard() "
               "FLOT.__bounds = {size = Vector({6.6, 0.2, 4.0}), center = Vector({0,0,0})}")
    right, gap = rt.eval("RTT_HELPER_RIGHT"), rt.eval("RTT_HELPER_GAP")
    bottom = rt.eval("RTT_HELPER_BOTTOM")

    def row():
        rt.execute("pcall(function() rttPlaceFlotillaCard() end) FLUSH(6)")
        raw = rt.eval("""function()
          local t = {}
          for _, o in ipairs(getObjectsWithTag('RTT Helper')) do
            local b = o.getBounds()
            t[#t+1] = string.format('%.3f;%.3f;%.3f;%.3f;%s', o.__pos.x, b.size.x,
                                    o.__pos.z, b.size.z, tostring(o.hasTag('RTT Flotilla')))
          end
          return table.concat(t, '|')
        end""")()
        out = []
        for r in raw.split("|"):
            x, w, z, d, mine = r.split(";")
            out.append((float(x), float(w), float(z), float(d), mine == "true"))
        out.sort(key=lambda c: -c[0])
        return out

    # every map's worth of helper cards, taken from the blueprints
    CASES = (("Summer / Gorge", []),
             ("Winter / Lake / Mountain", [(-29.22, 5.0, 7.0)]),
             ("Marsh, 4 players", [(-29.35, 5.0, 7.0)]),
             ("Marsh, 5 players", [(-29.35, 5.0, 7.0), (-35.098, 5.5, 7.8),
                                   (-40.156, 5.5, 7.8), (-45.214, 5.5, 7.8)]))
    for label, others in CASES:
        rt.execute("for _, o in ipairs(getObjectsWithTag('RTT Helper')) do "
                   "  if not o.hasTag('RTT Flotilla') then o.destruct() end end FLUSH(2)")
        for i, (x, w, d) in enumerate(others):
            rt.execute("local o = MKOBJ('', {%f, 11.575, -19.135}, {'RTT Helper'}) "
                       "o.__bounds = {size = Vector({%f, 0.2, %f}), center = Vector({0,0,0})}"
                       % (x, w, d))
        cards = row()
        assert len(cards) == len(others) + 1, \
            "%s: %d cards in the row, expected %d" % (label, len(cards), len(others) + 1)

        # NOTHING OVERLAPS, and the gaps are the same one all the way along
        for i in range(len(cards) - 1):
            a_left = cards[i][0] - cards[i][1] / 2
            b_right = cards[i + 1][0] + cards[i + 1][1] / 2
            assert abs((a_left - b_right) - gap) < 1e-3, \
                "%s: cards %d and %d are %.3f apart, not %.2f" % (label, i, i + 1,
                                                                  a_left - b_right, gap)
        # THE ROW STARTS WHERE IT SHOULD, just clear of the board
        assert abs((cards[0][0] + cards[0][1] / 2) - right) < 1e-3, \
            "%s: the row's right edge is %.3f, not %.3f" % (label, cards[0][0] + cards[0][1] / 2, right)
        # EVERY NEAR EDGE ON ONE LINE, whatever shape the card is
        for x, w, z, d, mine in cards:
            assert abs((z - d / 2) - bottom) < 1e-3, \
                "%s: a card's near edge is at %.3f, not %.3f" % (label, z - d / 2, bottom)
        # AND THE FLOTILLA IS LAST, however many are out
        assert cards[-1][4] is True, "%s: the Flotilla is not at the far end" % label

    # AND THE BOAT GOES WITH IT. "the flotilla object does not move with it" -- it had a spot of its
    # own, so the card stepped out along the row and left its pawn back beside the map.
    boat = rt.eval("function() for _, o in ipairs(getObjectsWithTag('RTT Flotilla')) do "
                   "  if not o.hasTag('RTT Helper') then return o.__pos.x end end return 999 end")
    assert abs(boat() - rt.eval("function() return FLOT.__pos.x end")()) < 1e-3, \
        "the boat is at %.3f and its card at %.3f" % (
            boat(), rt.eval("function() return FLOT.__pos.x end")())

    # NOT A CARD AT ALL. Three builds running it came out as a landmark -- a Rabbit-Town, then a
    # Foxburrow twice -- through three different deck numbers, because TTS resolved the art off its own
    # deck registry rather than off the CustomDeck in the blueprint. Nothing about this object needs to
    # be a card: it is never drawn, dealt, shuffled or flipped, it lies locked beside the map and is
    # read. A tile carries its picture as a plain URL, with no deck and no CardID to resolve.
    blob = re.search(r'RTT_FLOTILLA_CARD_JSON = \[====\[(.*?)\]====\]', src, re.S)
    assert blob, "the Flotilla card blueprint is not in the build"
    card = json.loads(blob.group(1))
    assert card["Name"] == "Custom_Tile", \
        "it is a %s again; a deck is what kept coming out as a landmark" % card["Name"]
    assert "CardID" not in card and "CustomDeck" not in card, \
        "it still carries a deck for TTS to resolve"

    # ONE FACE, EVERYTHING ON IT: "use the single flotilla card where everything is on 1 face", and it
    # is the render he confirmed -- "its flotilla_hireling_a7 etc the right helper card art".
    img = card["CustomImage"]
    assert "flotilla_hireling_" in img["ImageURL"], "the tile does not carry the rendered card"
    assert "rules" not in img["ImageURL"] and "action" not in img["ImageURL"], \
        "the tile uses one of the two half-cards: %s" % img["ImageURL"].split("/")[-1]
    assert img["ImageSecondaryURL"] == img["ImageURL"], \
        "its two sides differ; turning it over should change nothing"
    assert img["CustomTile"]["Stretch"] is True, "unstretched, the 1900x1146 card comes out square"

    # AND IT OUTLIVES THE MAP: "once I put the flotilla, it stays there." removeMapItems sweeps
    # everything tagged Map Object except what also carries the fixture tag, which is how the box
    # score and the turn panel survive a map change.
    fn = src[src.index("function rttSpawnFlotillaKit()"):]
    fn = fn[:fn.index("\nend")]
    assert "RTT_FIXTURE_TAG" in fn, "the Flotilla is not a fixture; a new map would erase it"


def t_clear_all_objects_asks_before_it_clears(src):
    """A red button that empties the table, and asks first.

    Maintainer, 2026-09-09: "add a red clear all objects option button; additional button; it can be
    red; add a warning This clears everything."

    clearAll has existed all along -- its button was commented out of the XmlUI. Bringing it back as a
    plain button would have made it the one destructive control on the board with no prompt, so it
    goes through rttArmOrGo like the rest: first click swaps the art for the warning and turns the
    button the armed red, second click within three seconds does it.

    ONE warning, not two. Every other button here has a faction wording and a map wording, because
    what it costs you depends on what is out. This takes both and everything else, so the same
    picture is the true answer in every state -- and the question it asks itself is not "are there
    factions" but "is there anything at all", which is the wipe's own predicate.
    """
    # THE BUTTON IS ON THE BOARD, in the free slot of the second tool row, red before you touch it.
    # Read off the XmlUI, which is a field of the board object rather than anything in its Lua.
    x = json.load(open(os.path.join(REPO, "dist/Root_Tabletop_Tournament.json"),
                       encoding="utf-8"))["ObjectStates"]
    def walk(objs):
        for o in objs:
            yield o
            for c in (o.get("ContainedObjects") or []):
                yield from walk([c])
    xml = [o for o in walk(x) if o.get("GUID") == "bab7e1"][0]["XmlUI"]
    board = re.search(r'<Button id="rttClearAllBtn"[^>]*/>', xml)
    assert board, "the Clear All button is not in the board's XmlUI"
    el = board.group(0)
    for want in ('onclick="rttArmClearAll"', 'icon="ClearAllArt"',
                 'position="57 -70 -20"', 'width="36"', 'height="20"'):
        assert want in el, "the Clear All button is missing %s: %s" % (want, el)
    # and both pictures it needs are registered, or TTS draws a white placeholder over it
    assets = {a["Name"] for a in [o for o in walk(x) if o.get("GUID") == "bab7e1"][0]["CustomUIAssets"]}
    for a in ("ClearAllArt", "ClearAllConfirmArt"):
        assert a in assets, "%s is not a registered UI asset" % a
    colour = re.search(r'color="(#[0-9a-fA-F]{6})"', el).group(1).lower()
    assert colour != "#a83226", \
        "the button rests on the ARMED red, so arming it would look like nothing happened"
    assert int(colour[1:3], 16) > int(colour[3:5], 16) + 40, "the button is not red: %s" % colour

    rt = fresh(src)
    def click():
        rt.execute("pcall(function() rttArmClearAll(Player['Purple'],'','rttClearAllBtn') end) "
                   "FLUSH_UNTIL(0.5,4)")
    def attr(k):
        return rt.eval("function(k) return tostring(UIATTR['rttClearAllBtn.' .. k]) end")(k)

    # A BARE TABLE JUST RUNS. Same rule as every other destructive button: nothing to lose, no prompt.
    rt.execute("REC.destroyed = {}")
    click()
    assert rt.eval("function() return tostring(RTT_ARM and RTT_ARM.id) end")() == "nil", \
        "an empty table armed the button instead of running"

    # WITH SOMETHING ON IT, the first click only asks.
    rt.execute("JUNK = MKOBJ('Cat Warrior', {3, 1, 3}, {'RTT Faction'}) "
               "FURNITURE = MKOBJ('Table Surface', {0, 0, 0}, {'Table Piece'}) "
               "REC.destroyed = {}")
    click()
    assert rt.eval("function() return tostring(RTT_ARM and RTT_ARM.id) end")() == "rttClearAllBtn", \
        "the first click did not arm the button"
    assert attr("icon") == "ClearAllConfirmArt", "the art did not become the warning: %s" % attr("icon")
    assert attr("color") == "#a83226", "the button did not go the armed red: %s" % attr("color")
    assert rt.eval("function() return JUNK.__dead end")() is not True, \
        "the first click cleared the table without asking"

    # THE SECOND CLICK DOES IT -- and leaves the furniture and the board itself alone.
    click()
    assert rt.eval("function() return JUNK.__dead end")() is True, \
        "the second click did not clear the table"
    assert rt.eval("function() return FURNITURE.__dead end")() is not True, \
        "Clear All destroyed a Table Piece"
    assert attr("icon") == "ClearAllArt", "the button did not revert its art"

    # THE QUESTION AND THE WIPE AGREE. rttWouldWipe asks rttClearAllHasWork, which is the same
    # predicate the loop uses -- so the button can never warn about something it would not take, or
    # take something it did not warn about.
    rt.execute("KEEP = {} "
               "KEEP[1] = MKOBJ('Flex Table Control', {0,0,0}, {}) "
               "KEEP[2] = MKOBJ('Faction Selection', {0,0,0}, {}) "
               "KEEP[3] = MKOBJ('A Landmark', {0,0,0}, {'Landmark Object'}) "
               "KEEP[4] = MKOBJ('Table Surface', {0,0,0}, {'Table Piece'})")
    assert rt.eval("rttClearAllHasWork()") is False, \
        "the button would warn about a table holding nothing but furniture"
    rt.execute("MORE = MKOBJ('Eyrie Warrior', {4, 1, 4}, {})")
    assert rt.eval("rttClearAllHasWork()") is True, "the button would clear a piece without warning"


def t_the_round_is_zero_until_start_is_pressed(src):
    """Nothing is round 1 until somebody presses START, and turns do not run before it either.

    Maintainer, 2026-09-09: "the round number should stay at 0 until the game has started; don t
    enable turns until start is pressed."

    Two halves of one rule. Sitting down used to switch the TTS turn system on -- itself a tightening
    of an older rule that started it on 4-Player Setup -- and the sheet reported ROUND 1 from the
    moment it existed. Neither is true of a table people are still laying out: seats get taken,
    factions picked and boards placed long before anyone plays.

    Only the REPORTED round is held at 0. S.round still counts from 1 inside the sheet, because every
    lock, column and undo is keyed on it and none of them may be handed a zero.
    """
    # THE BOARD. A full setup with every seat taken leaves the order written and the system off.
    rt = fresh(src)
    for i, c in enumerate(("Red", "Yellow", "Orange", "Teal")):
        rt.execute("SEAT(%r,'H%d')" % (c, i + 1))
    rt.execute("pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(60)")
    rt.execute("onPlayerChangeColor('Red') FLUSH(20)")
    assert list(rt.eval("Turns.order").values()) == ["Red", "Yellow", "Orange", "Teal"], \
        "the seat order was not written at setup"
    assert rt.eval("Turns.enable") is False, \
        "four players sitting down started the turn system"

    # THE SHEET. Its own script, loaded the way the panel's is.
    sheet = json.loads(re.search(r"RTT_BOXSCORE_JSON = \[====\[(.*?)\]====\]", src, re.S).group(1))
    def sheet_rt(state=None):
        r = lupa.LuaRuntime(unpack_returned_tuples=True)
        r.execute(open(os.path.join(HERE, "tts_stub.lua"), encoding="utf-8").read())
        r.execute(sheet["LuaScript"].replace("!=", "~="))
        if state is not None:
            # a long-bracket literal: the state is JSON, which can never contain ]==]
            r.execute("pcall(function() onLoad([==[%s]==]) end)" % state)
        return r

    r = sheet_rt()
    assert r.eval("rttRound()") == 0, \
        "a fresh sheet reports round %s; it should be 0 until START" % r.eval("rttRound()")
    r.execute("pcall(rttResetAndStart)")
    assert r.eval("rttRound()") == 1, "START did not begin round 1"
    # and a wipe puts it back to nothing
    r.execute("pcall(uiReset)")
    assert r.eval("rttRound()") == 0, "a wiped sheet still reports a round"

    # A SHEET SAVED BEFORE THE FLAG EXISTED. It comes back with no `started`, which would read as a
    # game that has not begun and put a running game back to ROUND 0. A locked cell is a played turn.
    played = json.dumps({"rows": [{"fac": "Marquise", "locks": {"1": 4}, "edits": {}}],
                         "round": 3, "turns": 5, "active": 1})
    r = sheet_rt(played)
    assert r.eval("rttRound()") == 3, \
        "an older save of a game in progress came back at round %s" % r.eval("rttRound()")

    # ...and one that was only ever set up comes back at 0, like any other unstarted sheet
    empty = json.dumps({"rows": [{"fac": "Marquise", "locks": {}, "edits": {}}],
                        "round": 1, "turns": 0, "active": 1})
    assert sheet_rt(empty).eval("rttRound()") == 0, \
        "an older save with no turn played came back as a started game"


def t_unlocking_a_prisoner_clears_the_mark_and_leaves_it_lying(src):
    """Take the lock off a marked warrior by hand and the mark comes off -- but the piece does not move.

    Maintainer, 2026-09-10: "when you unlock a warrior that has received numpad 3 on it, the warrior
    should also loose the tint and highlight as if it had been numpad 3 again on it." Then, 2026-09-11:
    "unlocking a numpad 3 warrior with different tint and highlight should not put it standning just
    readjust the color and highlight."

    The lock is the mark's own doing -- numpad 3 lays the piece down and locks it -- so taking that
    lock off by hand says the mark is over. It does NOT say put the piece back: unlocking is what you
    do when you want to move the piece yourself, and standing it up and teleporting it to where it was
    laid is the mod taking it off you at the moment you reached for it. Pressing numpad 3 again is the
    act that means put it back, and that still does.

    There is no unlock event to hear, which is why this rides the tick the map's own lock already
    needed.
    """
    rt = fresh(src)
    rt.execute("W = MKOBJ('Eyrie Warrior', {3, 1, 3}, {}) W.setColorTint({0.145, 0.457, 0.810}) "
               "HOVER['Red'] = W rttGizmoMark('Red') FLUSH(6)")
    assert rt.eval("function() return W.__locked end")() is True, "the prisoner was not locked"
    assert rt.eval("function() return W.__glow ~= nil end")() is True, "it was not marked"

    rt.execute("W.setLock(false) rttFreeUnlockedPrisoners() FLUSH(6)")
    assert rt.eval("function() return W.__glow == nil end")() is True, \
        "unlocking it left the outline on"
    tint = rt.eval("function() local c = W.getColorTint() "
                   "return string.format('%.3f/%.3f/%.3f', c.r, c.g, c.b) end")()
    assert [round(float(v), 3) for v in tint.split("/")] == [0.145, 0.457, 0.810], \
        "unlocking it did not give the warrior its colour back: %s" % tint
    assert rt.eval("function() return RTT_LAID['" + rt.eval("W.getGUID()") + "'] == nil end")() is True, \
        "the record still holds it as a prisoner"
    # ...AND IT IS STILL LYING DOWN, exactly where it was laid. numpad 3 tips a piece to rot.x 90.
    assert round(rt.eval("function() return W.getRotation().x end")()) == 90, \
        "unlocking stood the warrior back up instead of leaving it where it was"

    # ...WHILE PRESSING THE KEY TWICE STILL PUTS A PIECE BACK. On a FRESH warrior, because a piece
    # left lying by an unlock is upright no longer: marking it again records the pose it is actually
    # in, so "put it back" correctly puts it back to lying. The key's round trip is what is asserted
    # here, and it needs a piece that was standing when the key first found it.
    rt.execute("U = MKOBJ('Cat Warrior', {9, 1, 9}, {}) HOVER['Red'] = U rttGizmoMark('Red') FLUSH(6)")
    assert round(rt.eval("function() return U.getRotation().x end")()) == 90, "the mark did not lay it"
    rt.execute("HOVER['Red'] = U rttGizmoMark('Red') FLUSH(6)")
    assert round(rt.eval("function() return U.getRotation().x end")()) == 0, \
        "numpad 3 a second time left the warrior lying down"

    # a piece that is still locked is left alone, and one that is gone is forgotten
    rt.execute("X = MKOBJ('Cat Warrior', {5, 1, 5}, {}) HOVER['Red'] = X rttGizmoMark('Red') FLUSH(6)")
    rt.execute("rttFreeUnlockedPrisoners() FLUSH(3)")
    assert rt.eval("function() return X.__glow ~= nil end")() is True, \
        "a locked prisoner was freed by the sweep"
    rt.execute("X.destruct() rttFreeUnlockedPrisoners() FLUSH(3)")
    assert rt.eval("function() local n = 0 for _ in pairs(RTT_LAID) do n = n + 1 end return n end")() == 0, \
        "a destroyed prisoner was left in the record"


def t_the_map_cannot_be_left_unlocked(src):
    """Unlock the map and it locks itself again, within the second.

    Maintainer, 2026-09-09: "can you also make sure that a map can never but unlocked?"

    Every map board already SPAWNS locked -- all six blueprints carry Locked:true -- so this is about
    the lock being taken off mid-game, by a right-click or by L over the board. A loose map is dragged
    along by the next piece let go on top of it, and then the clearings, the priority numbers and the
    printed score track the box score reads are somewhere else while everything standing on them is
    not.

    There is no unlock event to answer, so it is a tick. Two things have to hold for a guard that runs
    for the whole session: it must put the lock back, and it must not go hunting the whole table to
    find out where to put it.

    AND IT CANNOT BE TOUCHED AT ALL. Maintainer, 2026-09-10: "could you set all the maps, once spawned
    as un interactable? so it s never possible to fuck them up by mistake. make sure nothing is broken
    though they still get reset and wiped with the other buttons of course."

    The lock alone leaves the right-click menu on the board, so a player can still take the lock off --
    this guard puts it back within the second, but not before a piece has been dragged. `interactable`
    takes the menu away with everything else, so there is nothing to undo. It is a RUNTIME property and
    not one of the flags a save stores, which is why it lives on this tick: this is also the only thing
    that runs after a reload. Scripts are unaffected, so both halves of the maintainer's sentence hold
    at once -- the last clause of this test is the "nothing is broken".
    """
    rt = fresh(src)
    rt.execute("MAP = MKOBJ('', {0, 11.56, 0}, {'Map Object'}) "
               "MAP.__snaps = {} for i = 1, 139 do MAP.__snaps[i] = {position = {0,0,0}} end "
               "MAP.setLock(true) "
               "RUIN = MKOBJ('Ruin', {5, 11.6, 5}, {'Map Object'}) RUIN.setLock(false)")

    rt.execute("MAP.setLock(false) rttHoldMapLocked()")
    assert rt.eval("function() return MAP.getLock() end")() is True, \
        "the map was left unlocked"
    assert rt.eval("function() return MAP.interactable end")() is False, \
        "the map can still be grabbed, so it can still be unlocked by hand"
    # and nothing else on the map is touched: a ruin is locked by rttLockRuins, a warrior never is
    assert rt.eval("function() return RUIN.getLock() end")() is False, \
        "the guard locked something that is not the map board"
    assert rt.eval("function() return RUIN.interactable end")() is True, \
        "the guard froze something that is not the map board"

    # A MAP CHANGE HANDS IT A NEW BOARD. The guid is remembered between ticks so the usual tick is one
    # lookup; if that were never refreshed the guard would go on watching a board that no longer exists.
    rt.execute("MAP.destruct() "
               "MAP2 = MKOBJ('', {0, 11.56, 0}, {'Map Object'}) "
               "MAP2.__snaps = {} for i = 1, 152 do MAP2.__snaps[i] = {position = {0,0,0}} end "
               "MAP2.setLock(false) rttHoldMapLocked()")
    assert rt.eval("function() return MAP2.getLock() end")() is True, \
        "the guard kept watching the old board; the new map was left unlocked"
    assert rt.eval("function() return MAP2.interactable end")() is False, \
        "the guard kept watching the old board; the new map can still be grabbed"

    # ...AND THE BUTTONS STILL TAKE IT. "make sure nothing is broken though they still get reset and
    # wiped with the other buttons of course" -- destruct() does not ask whether a player could have
    # reached the object, so a frozen map goes the same way a loose one did.
    rt.execute("removeMapItems()")
    assert rt.eval("function() return MAP2 == nil or MAP2.__dead end")() is True, \
        "a frozen map survived the wipe"

    # IT IS ACTUALLY RUNNING, and it repeats. A guard nobody arms is a function nobody calls.
    head = src.index("function onLoad(state)")
    body = src[head:src.index("local lastSuccess = 10", head)]
    assert "Wait.time(rttHoldMapLocked, RTT_MAP_LOCK_SECS, -1)" in body, \
        "onLoad does not arm the map-lock guard as a repeating tick"

    # AND IT NEVER SCANS THE TABLE. rttFindMapObject falls back to every object on the table when no
    # tagged piece has snap points -- which is exactly the state between games, so a guard that used it
    # would run that scan once a second forever.
    fn = src[src.index("function rttHoldMapLocked()"):]
    fn = fn[:fn.index("\nend")]
    assert "rttFindMapObject" not in fn and "getAllObjects" not in fn, \
        "the map-lock guard scans the whole table on every tick"


def t_the_cats_are_dropped_clear_of_the_clearing(src):
    """A cat appears in free air above its clearing and falls, standing upright.

    Maintainer, 2026-09-07: "when spawned on the map at the setup of the faction, cats should drop
    from a bit abov so they don t push away things already there but fall on them; but they should
    still stand up straight if there is no obstacles."

    The board's surface is 11.56 and what is already standing in a clearing at setup -- ruins, relics,
    clearing and priority markers -- sits between 11.63 and 11.70. A cat appeared at 12.6, which puts
    the bottom of its collider right about there, and TTS answers an overlap by shoving the two apart.

    Two clear units of air, no more: the rotation stands the cat up, and a piece let go from much
    higher bounces and can land on its side. Physics is not modelled here, so this pins the two things
    that decide the outcome -- the height it starts from and the attitude it starts in.
    """
    BOARD, FURNITURE = 11.56, 11.70          # the surface, and the tallest thing already on it
    rt = fresh(src)
    rt.execute("""
      DROPS = {}
      RTT_CURRENT_MAP = "Summer Map"
      MAP = MKOBJ("Autumn", {0, 11.5, 0}, {"Map Object"})
      MAP.__snaps = {}
      for i = 1, 40 do MAP.__snaps[i] = { position = {0,0,0} } end
      BAG = MKOBJ("Marquise Supply", {-36, 11.4, 44}, {})
      BAG.name = "Bag"
      BAG.takeObject = function(p)
        DROPS[#DROPS + 1] = string.format("%.3f|%s", p.position[2],
          table.concat({p.rotation[1], p.rotation[2], p.rotation[3]}, ","))
        return MKOBJ("Cat Warrior", p.position, {})
      end
      rttMarquiseCats(0, 0, false) FLUSH(20)
    """)
    drops = [str(v) for v in (rt.eval("DROPS") or {}).values()]
    assert len(drops) == 12, "Autumn has 12 clearings; %d cats were placed" % len(drops)

    heights = {float(d.split("|")[0]) for d in drops}
    assert len(heights) == 1, "the cats are dropped from different heights: %s" % sorted(heights)
    y = heights.pop()
    assert y - FURNITURE >= 1.5, \
        ("a cat starts %.2f above the tallest thing in a clearing; that is close enough for TTS to "
         "resolve the overlap by shoving the ruin away" % (y - FURNITURE))
    assert y - BOARD <= 3.0, \
        "a cat is dropped %.2f above the board; from that height it bounces and lands on its side" \
        % (y - BOARD)

    # UPRIGHT ON THE WAY DOWN. It is the attitude it starts in that decides how it lands when the
    # clearing is empty, and nothing rights it afterwards.
    attitudes = {d.split("|")[1] for d in drops}
    assert attitudes == {"0,180,0"}, "the cats are not dropped standing up: %s" % attitudes


def t_the_badger_relics_are_drawn_uniformly(src):
    """Which relic lands on which forest is a real draw, and it does not depend on the bag being shuffled.

    Maintainer, 2026-09-07: "can you check properly that relics positions are well randomized", and
    then "do the best most robust for random ... you can also test it."

    The spots are NOT random and must not be -- they are the map's forests, and every one takes a
    relic. What is random is which of the twelve goes where. That used to be `bag.shuffle()` followed
    by taking the top twelve times in one frame, which asks the engine to have applied a shuffle by
    the time the very next line runs and leaves a test nothing to check.

    SO THE BAG'S SHUFFLE IS DISABLED HERE. The draw has to come out uniform anyway, because the order
    is decided in Lua by rttShuffleList over the bag's contents. On the old code this test collapses to
    a single arrangement, every game, forever.
    """
    N = 200
    rt = fresh(src)
    rt.execute("""
      RTT_CURRENT_MAP = "Summer Map"
      MAP = MKOBJ("Autumn", {0, 11.5, 0}, {"Map Object"})
      MAP.__snaps = {}
      for i = 1, 40 do MAP.__snaps[i] = { position = {0,0,0} } end
      BAG = MKOBJ("Relics", {-36, 11.4, 44}, {})
      BAG.name = "Bag"
      BAG.shuffle = function() end        -- the engine gives us nothing; the draw must not need it
      function __round()
        for _, o in ipairs(getObjectsWithTag("RTT Faction")) do
          if string.sub(o.getGUID(), 1, 5) == "relic" then o.destruct() end
        end
        BAG.__contents = {}
        for i = 1, 12 do BAG.__contents[i] = { guid = string.format("relic%02d", i) } end
        rttBadgerRelics()
      end
      function __drawn()
        local out = {}
        for _, o in ipairs(getObjectsWithTag("RTT Faction")) do
          local g = o.getGUID()
          if string.sub(g, 1, 5) == "relic" then
            local p = o.getPosition()
            out[#out+1] = string.format("%.1f,%.1f=%s", p.x, p.z, g)
          end
        end
        table.sort(out)
        return table.concat(out, ";")
      end
    """)

    per_spot, arrangements = {}, {}
    for k in range(N):
        rt.execute("math.randomseed(%d) __round() FLUSH(40)" % (k * 7919 + 13))
        row = rt.eval("__drawn()")
        arrangements[row] = arrangements.get(row, 0) + 1
        placed = row.split(";")
        assert len(placed) == 7, "Autumn has 7 forest spots; %d relics were placed" % len(placed)
        spots = [e.split("=")[0] for e in placed]
        relics = [e.split("=")[1] for e in placed]
        assert len(set(spots)) == 7, "two relics landed on the same spot: %s" % row
        assert len(set(relics)) == 7, "the same relic was placed twice: %s" % row
        for sp, g in zip(spots, relics):
            per_spot.setdefault(sp, set()).add(g)

    # THE ARRANGEMENT IS NOT FIXED. On the old code, with the engine's shuffle doing nothing, every
    # game dealt relics 1-7 onto the same seven spots in the same order: ONE arrangement, always.
    assert len(arrangements) > N * 0.9, \
        "only %d distinct arrangements in %d games; the draw is barely moving" % (len(arrangements), N)

    # AND EVERY RELIC CAN REACH EVERY SPOT. With 12 relics and 200 games a spot should see all twelve;
    # 9 leaves room for luck without leaving room for a spot that only ever gets three of them.
    for sp, seen in sorted(per_spot.items()):
        assert len(seen) >= 9, \
            "spot %s only ever received %d of the 12 relics: %s" % (sp, len(seen), sorted(seen))

    # ONE PER FRAME. Taking a dozen objects out of one container in a single frame is the hazard the
    # card dealer already spaces around ("one at a time = no deck-busy / collapse race"), and a take
    # that gets dropped leaves a forest with no relic at all.
    rt.execute("__round() FLUSH(1)")
    assert len(rt.eval("__drawn()").split(";")) < 7, \
        "every relic came out in one frame; they are not being spaced"


def t_the_keepers_spawn_where_the_maintainer_put_them(src):
    """The 8 warriors and the Relics bag land where the "keepers" save has them.

    Maintainer, 2026-09-07: "check the save 'keepers' and use that position for the spawning position
    of the 8 initial warriors and relics supply." He had laid them out by hand in TS_Save_35 and the
    blueprint disagreed: four of the eight warriors and the Relics bag sat on the OPPOSITE side of the
    board, around x +13 instead of x -16.

    THE FRAME. rttSpawnFaction turns a blueprint move_to into a world position as
    `seat + move_to` -- and, on the far row, `seat - move_to`, because those boards are rotated 180.
    The save was taken at seat 4, (-52, 46), which is a far-row seat. That reading is not assumed: it
    was calibrated on four pieces the maintainer did NOT move (the three waystations and the Keeper
    Supply), and their x and z round-trip to 0.000.

    So this test states the answer in WORLD coordinates, straight out of the save. If the transform is
    ever changed, or a piece is nudged in the blueprint, the numbers below stop matching the table.
    """
    SEAT_X, SEAT_Z, FLIP = -52.0, 46.0, -1        # seat 4, far row
    BASE_Y = 11.46                                # 11.56 spawn height, less the 0.1 rttSpawnFaction drops

    WARRIORS = {(-34.877, 30.590), (-34.877, 31.330), (-34.877, 33.550), (-34.877, 34.290),
                (-36.545, 30.590), (-36.545, 31.330), (-36.545, 33.550), (-36.545, 34.290)}
    RELICS = (-35.937, 43.808)
    SUPPLY = (-35.880, 40.178)                    # untouched: it already matched, to 0.000

    rt = fresh(src)
    rt.execute("""
    function __keepers()
      local out = {}
      for _, v in ipairs(EVERYTHING['Standard']['Keepers in Iron'].data) do
        local nm = string.match(v.json, '"Nickname"%s*:%s*"([^"]*)"') or ""
        if nm == "Keeper Warrior" or nm == "Relics" or nm == "Keeper Supply" then
          out[#out+1] = string.format("%s|%.6f|%.6f|%.6f", nm, v.move_to[1], v.move_to[2], v.move_to[3])
        end
      end
      return table.concat(out, ";")
    end
    """)
    got = {"Keeper Warrior": set(), "Relics": [], "Keeper Supply": []}
    for e in rt.eval("__keepers()").split(";"):
        nm, mx, my, mz = e.split("|")
        w = (round(SEAT_X + FLIP * float(mx), 3), round(SEAT_Z + FLIP * float(mz), 3))
        if nm == "Keeper Warrior":
            got[nm].add(w)
        else:
            got[nm].append(w)

    assert len(got["Keeper Warrior"]) == 8, \
        "expected 8 warriors on 8 distinct spots, got %d: %s" % (len(got["Keeper Warrior"]),
                                                                 sorted(got["Keeper Warrior"]))
    assert got["Keeper Warrior"] == WARRIORS, \
        "the warriors are not where the save has them: %s" % sorted(got["Keeper Warrior"] ^ WARRIORS)
    assert got["Relics"] == [RELICS], "the Relics bag is at %s, not %s" % (got["Relics"], RELICS)
    assert got["Keeper Supply"] == [SUPPLY], \
        "the Keeper Supply moved; it already matched the save: %s" % got["Keeper Supply"]

    # AND THEY ARE ALL ON ONE SIDE. What was actually wrong was not the exact coordinates -- it was
    # that half the warriors and the bag were across the board from the supply they belong with.
    everything = sorted(got["Keeper Warrior"]) + got["Relics"] + got["Keeper Supply"]
    span = max(x for x, _ in everything) - min(x for x, _ in everything)
    assert span < 3.0, \
        "the Keepers' pieces are spread %.1f units across the board; they belong in one column" % span


def t_every_map_locks_its_ruins(src):
    """A ruin is locked once it has been placed, on every map -- not only the Marsh.

    Maintainer, 2026-09-07: "looks like Marsh is the only map that locks the ruins; the ruins in
    general after being randomize must be locked." He was exactly right, and it was never a per-map
    rule: it is the BLUEPRINTS that disagree. The Marsh's four ruin entries carry Locked:true and the
    other five maps' do not, so whether a game got loose ruins depended on which map you picked. A
    ruin stands in its clearing for the whole game and is only ever moved by accident -- a warrior
    dragged across it takes it along.

    rttLockRuins runs at the end of makeMap rather than inside shuffleMaps, because the Marsh does not
    go through shuffleMaps at all: its ruins are placed by rttMarshPlan's overlay. That makes the end
    of makeMap the one point that sees every map's ruins however they got there.

    NOTE ON THE HARNESS. This could not have been written before: the stub spawned every blueprint
    object untagged and unlocked, so getObjectsWithTag("Ruin") came back empty and shuffleMaps -- the
    function that randomises every map but the Marsh -- had never once been executed by a test.
    """
    PROBE = """
    function __ruins()
      local n, loose = 0, 0
      for _, o in ipairs(getObjectsWithTag("Ruin")) do
        n = n + 1
        if o.getLock() ~= true then loose = loose + 1 end
      end
      return n .. "," .. loose
    end
    """
    for mid in ("Summer Map", "Lake Map", "Marsh Map", "Winter Map", "Mountain Map", "Gorge Map"):
        rt = fresh(src)
        rt.execute(PROBE)
        rt.execute("SEAT('Purple','H1')")
        rt.execute("pcall(function() makeMap(Player['Purple'],'','%s') end) FLUSH(300)" % mid)
        n, loose = (int(v) for v in rt.eval("__ruins()").split(","))
        assert n == 4, "%s placed %d ruins, expected 4" % (mid, n)
        assert loose == 0, "%s left %d of its %d ruins unlocked" % (mid, loose, n)

    # AND THE 5-PLAYER MARSH, which places its ruins through a different plan again (four central
    # clearings only, never the rim) and so could drift from the other seven without anyone noticing.
    rt = fresh(src)
    rt.execute(PROBE)
    rt.execute("SEAT('Purple','H1')")
    rt.execute("pcall(function() rttPlaceMarsh5P(Player['Purple'],'','Marsh5PMap') end) FLUSH(300)")
    n, loose = (int(v) for v in rt.eval("__ruins()").split(","))
    assert n == 4 and loose == 0, "the 5-player Marsh left %d of %d ruins unlocked" % (loose, n)


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

    # THE SHEET CALLS THE MAP WHAT THE BUTTON CALLS IT. RTT dropped the base game's fixed-suit Autumn
    # board and put the Summer one in its place, because that one randomises its clearing suits -- and
    # then labelled the button Autumn. The sheet names a board by reading its artwork, so it was the
    # one place in the mod still saying Summer. Maintainer, 2026-09-09: "when Autumn is picked, it
    # should say Autumn and not Summer (boxscore says summer)."
    #
    # The tail is read off the BOARD THE BUTTON ACTUALLY SPAWNS, not typed in, so this cannot drift
    # apart from the blueprint the way a second copy of a constant does.
    board = src.index("EVERYTHING['Maps']['Summer Map']")
    url = re.search(r'"ImageURL": "([^"]+)"', src[board:board + 4000])
    assert url, "cannot find the Summer Map board's artwork in the build"
    tail = re.sub(r"[^A-Za-z0-9]", "", url.group(1))[-16:]        # the sheet's own urlTail
    names = dict(re.findall(r'\["([0-9A-Za-z]{16})"\] = "([^"]+)"', lua))
    assert names.get(tail) == "Autumn", (
        "the sheet names the board the Autumn button spawns %r; it must say Autumn" % names.get(tail))
    pool = re.search(r'local MAPS = \{([^}]*)\}', lua)
    assert pool and "Summer" not in pool.group(1), \
        "the sheet's map chips still offer Summer: %s" % (pool and pool.group(1))
    assert "Autumn" in pool.group(1), "the sheet's map chips do not offer Autumn: %s" % pool.group(1)


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


    # AND A PAUSED CLOCK DOES NOT FLASH. Maintainer, 2026-09-10: "if pause is hit on the turncounter it
    # should stop flashing red when it s past 20 min." The clock stops when you pause it, so the warning
    # that the turn is running long has nothing left to warn about.
    rt.execute("PANEL_START = CLOCK - 25 * 60 PANEL_PAUSED = nil PANEL_DEMO = nil PANEL_ALARM = false")
    rt.execute("PANEL_TICKS = 0 for i = 1, 8 do panelTick() end")
    ran_hot = rt.eval("PANEL_ALARM")
    rt.execute("PANEL_TICKS = 0 PANEL_ALARM = false for i = 1, 8 do panelTick() end")
    ran_hot = ran_hot or rt.eval("PANEL_ALARM")
    assert ran_hot is True, "a 25-minute turn does not flash at all"
    rt.execute("PANEL_PAUSED = CLOCK PANEL_ALARM = false PANEL_TICKS = 0")
    for _ in range(3):
        rt.execute("for i = 1, 8 do panelTick() end")
        assert rt.eval("PANEL_ALARM") is not True, "a paused clock is still flashing red"

def t_a_warning_describes_what_the_click_really_does(src):
    """A button warns about the thing it is actually going to take away, and about nothing else.

    Maintainer, 2026-09-07: "If I spawn a map then click on the 4 player setup it warns that this will
    wipe the map. that is not true. revise your warnings!!" -- and then the rule: "if factions would be
    wiped, warn about faction wipe. if map would be reset, warn about that. it needs to make sense."

    A setup click does not touch the map at all, so there is nothing to say about it -- except on the
    Marsh, whose two boards are not interchangeable and which is rebuilt when a four-player game
    inherits the five-player one. Three earlier versions of this got it wrong in turn: one counted any
    "Map Object" including the table's own furniture, the next counted a map that was about to be put
    straight back, and the third kept re-rolling a board the table had already set up.
    """
    rt = fresh(src)
    fixture = rt.eval("RTT_FIXTURE_TAG")
    setup = rt.eval("RTT_WIPE_BTN['rttFourBoardsBtn']")
    amap  = rt.eval("RTT_WIPE_BTN['Summer Map']")
    warn, art = rt.eval("rttWouldWipe"), rt.eval("rttWarnArt")

    # a bare table: nothing at all
    assert warn(setup) is False, "warned on an empty table"
    assert warn(amap) is False, "warned on an empty table for a map button"

    # the panel, the box score and the mat -- all tagged Map Object, all survive a rebuild
    rt.execute("""
      for _, n in ipairs({'Turn Panel', 'Root Box Score', 'Battle Mat'}) do
        MKOBJ(n, {0,1,0}, {'Map Object', %r})
      end
    """ % fixture)
    assert warn(setup) is False, "the table's own furniture counted as something to wipe"
    assert warn(amap) is False, "the table's own furniture counted as a map to replace"

    # THE REPORT. A map is down and a setup button is pressed: the same map goes straight back, so
    # there is nothing to warn about and the click must simply run.
    rt.execute("RTT_CURRENT_MAP = 'Summer Map'")
    assert warn(setup) is False, \
        "a setup button warned about a map it is about to put back exactly as it was"
    # ...and the same map asked for again is not a reset either
    assert warn(amap) is False, "asking for the map that is already down warned about resetting it"

    # A DIFFERENT MAP IS a reset, and says so.
    lake = rt.eval("RTT_WIPE_BTN['Lake Map']")
    assert warn(lake) is True, "swapping Autumn for Lake did not warn"
    assert art(lake) == "WipeConfirmMapArt", "a map button changed its wording: %s" % art(lake)

    # NOT EVEN ON THE MAPS THAT RE-ROLL. A setup click no longer re-places the map at all, so the
    # Marsh keeps the flooding the table set up and the Mountain keeps its lost city.
    for mid in ("Marsh Map", "Mountain Map"):
        rt.execute("RTT_CURRENT_MAP = %r RTT_MARSH_5P_BUILT = false" % mid)
        assert warn(setup) is False, \
            "4-Player Setup warned about the %s, which it no longer touches" % mid

    # THE ONE CASE A SETUP BUTTON DOES CHANGE THE MAP: the Marsh's two boards. A four-player game
    # cannot be played on the five-player board, so starting one rebuilds it -- and says so.
    rt.execute("RTT_CURRENT_MAP = 'Marsh Map' RTT_MARSH_5P_BUILT = true")
    assert warn(setup) is True, \
        "4-Player Setup on the FIVE-player Marsh must rebuild the board and warn that it will"
    # startswith, not equality: the same wording ships square and wide, and a button that changes rows
    # takes the other shape with it -- 4-Player Setup went down to the tool row on 2026-09-10. What
    # must not change is WHICH wording it uses.
    assert art(setup).startswith("WipeConfirmMapArt"), \
        "the Marsh variant swap warned about factions instead of the map: %s" % art(setup)
    # ...and the five-player buttons are the mirror image
    five = rt.eval("RTT_WIPE_BTN['Marsh5P']")
    assert warn(five) is False, "5-Player Draft warned about a five-player board it is happy with"
    rt.execute("RTT_MARSH_5P_BUILT = false")
    assert warn(five) is True, "5-Player Draft on the FOUR-player Marsh did not warn"
    assert warn(setup) is False, "4-Player Setup warned about the board it already wants"
    rt.execute("RTT_CURRENT_MAP = 'Summer Map'")

    # A FACTION OUTRANKS EITHER. It is the bigger loss and it is what a setup button is for.
    rt.execute("MKOBJ('Eyrie Warrior', {2,1,2}, {'RTT Faction'})")
    assert warn(setup) is True, "a faction on the table did not warn"
    assert art(setup).startswith("WipeConfirmArt"), \
        "with factions out a setup button must warn about the FACTIONS: %s" % art(setup)

    # ...and a map button STILL must not claim them: it destroys Map Objects only, and a faction
    # warrior is not one. There is no faction wording on a map button at all.
    assert amap["warn"] is None, "a map button carries faction wording it can never honour"
    assert art(lake) == "WipeConfirmMapArt", \
        "a map button claimed to reset factions: %s" % art(lake)

    # EVERY DESTRUCTIVE BUTTON HAS THE WORDING IT NEEDS. A setup button can hit either case, so it
    # needs both; a map button only ever resets a map. An entry missing one would silently arm with no
    # art at all.
    #
    # The Rowdy Riverboat is the exception and carries NEITHER, because it destroys nothing: since
    # 2026-09-10 it only puts the Flotilla out ("the button for the riverboat options should just spawn
    # the flotilla item and helper card nothing else"). It keeps its entry for the icon and the colour,
    # and rttWouldWipe -- which asks after a warn art and a map -- lets it run on one click.
    for bid, d in dict(rt.eval("RTT_WIPE_BTN")).items():
        if d["warn"] is None and d["warnMap"] is None:
            assert d["map"] is None and d["places"] is None, \
                "%s changes the table but asks nothing" % bid
            continue
        assert d["warnMap"] is not None, "%s can change the map but has no map wording" % bid
        if d["fn"] is not None and d["places"] is None:
            assert d["warn"] is not None, "%s clears factions but has no faction wording" % bid


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


def t_start_names_the_pass_it_causes(src):
    """START tells the sheet which colour it is handing the turn to, BEFORE it hands it over.

    Moving the turn pointer IS a pass, so pressing START on anyone but seat 1 makes TTS fire
    onPlayerTurn and the sheet locks the outgoing row -- a completed turn nobody played, in that seat's
    own column. Maintainer, 2026-09-07: "starting game by pressing start on the turncounter when its the
    turn of 4th seat palyer does pass the turn to first seat player and boxcore records that as a turn
    to print and prints the score in the first column of 4th player."

    Two earlier answers both failed. `rttSuppressNextLock` was armed unconditionally and then the turn
    was moved only if the colour differed, so a press on seat 1's turn fired no pass, nothing consumed
    the flag, and it sat armed until it swallowed the first REAL turn -- five START fixes, all missed,
    because the panel's own script had never been executed by a test. Removing the flag and wiping the
    sheet four frames later replaced it with a bet on how fast TTS delivers an event; under lag the
    event lands after the wipe, which is the report above.

    So the pass is refused by NAME. This is the only test that runs the panel's real script, and it
    pins the two things the fix depends on: the announcement happens only when a pass will actually
    follow, and it happens while the pointer is still on the OUTGOING colour -- announcing afterwards
    would be too late, because TTS may deliver the pass first.
    """
    panel = json.loads(re.search(r"RTT_TURN_PANEL_JSON = \[====\[(.*?)\]====\]", src, re.S).group(1))
    rt = lupa.LuaRuntime(unpack_returned_tuples=True)
    rt.execute(open(os.path.join(HERE, "tts_stub.lua"), encoding="utf-8").read())
    rt.execute("CLOCK = 1000 os.time = function() return CLOCK end")
    rt.execute(panel["LuaScript"].replace("!=", "~="))
    rt.execute("""
      CALLS, WHEN, ANNOUNCED = {}, {}, {}
      SHEET = MKOBJ("Root Box Score", {0,1,0}, {"RTT Box Score"})
      SHEET.call = function(fn, arg)
        CALLS[#CALLS+1] = fn
        -- WHERE THE POINTER WAS AT THE MOMENT OF THE CALL, which is what decides whether the
        -- announcement can still beat the pass it is describing.
        WHEN[#WHEN+1] = tostring(Turns.turn_color)
        if fn == "rttStartingTurn" then ANNOUNCED[#ANNOUNCED+1] = tostring(arg and arg.to) end
        if fn == "rttHasData" then return false end
        return true
      end
      sheet = function() return SHEET end
      self.UI.setXml = function() end
      Turns.order = {"Red", "Yellow"}
      Turns.enable = true
    """)

    def press(turn_color):
        rt.execute("CALLS, WHEN, ANNOUNCED = {}, {}, {} Turns.turn_color = %r pcall(panelStart) FLUSH(20)"
                   % turn_color)
        return ([str(v) for v in (rt.eval("CALLS") or {}).values()],
                [str(v) for v in (rt.eval("WHEN") or {}).values()],
                [str(v) for v in (rt.eval("ANNOUNCED") or {}).values()])

    # SEAT 2 HOLDS THE TURN: START will move the pointer, so it must say so first.
    said, when, to = press("Yellow")
    assert "rttSuppressNextLock" not in said, \
        "START armed the old one-shot, which swallowed the first real turn of the game: %s" % said
    assert "rttStartingTurn" in said, \
        "START moved the turn without naming the pass; the sheet will record it: %s" % said
    assert to == ["Red"], "START announced %s instead of the first seat's colour" % to
    assert when[said.index("rttStartingTurn")] == "Yellow", \
        ("START announced the pass AFTER moving the pointer (it read %s); TTS may deliver the pass "
         "before the next line runs, so the sheet would never hear about it in time"
         % when[said.index("rttStartingTurn")])
    assert said.index("rttStartingTurn") < said.index("rttResetAndStart"), \
        "START wiped the sheet before naming the pass: %s" % said
    assert "rttResetAndStart" in said, "START did not reset the sheet: %s" % said

    # SEAT 1 ALREADY HOLDS IT: no pointer move, so no pass -- and therefore nothing to announce.
    # Announcing anyway is precisely the shape of the old bug: a guard left standing with nothing to
    # consume it. The box-score suite proves the sheet survives a stale one; the panel must not make one.
    said, when, to = press("Red")
    assert "rttStartingTurn" not in said, \
        "START announced a pass it never makes, leaving the sheet guarding against nothing: %s" % said
    assert "rttResetAndStart" in said, "START did not reset the sheet: %s" % said
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
    assert rt.eval("Turns.enable") is False, "seating started the turn system"

    # START, which is the panel's job and the only thing that begins a game
    rt.execute("Turns.enable = true Turns.turn_color = 'Red' FLUSH(10)")
    assert rt.eval("Turns.enable") is True, "the turn system did not start"

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
        """Four seats with the game STARTED -- which since 2026-09-09 is a separate act.

        Sitting down writes the order and stops there ("don t enable turns until start is pressed"),
        so a table full of players is not yet a table playing. The last line stands in for START on
        the turn panel, which is what panelStart does.
        """
        rt = fresh(src)
        for i, c in enumerate(("Red", "Yellow", "Orange", "Teal")):
            rt.execute("SEAT(%r,'H%d')" % (c, i + 1))
        rt.execute("pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(60)")
        rt.execute("onPlayerChangeColor('Red') FLUSH(20)")
        rt.execute("Turns.enable = true Turns.turn_color = 'Red' FLUSH(10)")
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
    rt2.execute("onPlayerChangeColor('Red') FLUSH(20) Turns.enable = true Turns.turn_color = 'Red'")
    rt2.execute("FLUSH(10) TURN_EVENTS = {} TURN_ROUND(1) FLUSH(20)")
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


def t_the_drafts_shuffle_is_saved_and_forgotten(src):
    """The one shuffle that decides who sits where must survive a reload and not outlive its game.

    RTT_ORDER is not a duplicate of the seat record -- it is the INPUT that decides which seat each
    person gets, and it is needed in the window between the order cards being dealt and the players
    being seated. Two faults, both from the audit:

      * it was never persisted, so a reload in that window left the draft unfinishable -- rttBeginPick
        returns on an empty order, and rttSeatPlayers has nothing to match a human to a seat with;
      * it was never CLEARED, only overwritten by the next deal, so a manual game started after a
        draft still carried the previous draft's person-to-seat mapping.
    """
    rt = fresh(src)
    rt.execute("""
      RTT_ORDER = { { color = 'Red', name = 'Alice' }, { color = 'Yellow', name = 'Bob' } }
    """)
    saved = rt.eval("onSave()")

    rt2 = fresh(src)
    rt2.execute("pcall(function() onLoad(%s) end) FLUSH(6)" % json.dumps(saved))
    got = [(str(rt2.eval("RTT_ORDER[%d].color" % i)), str(rt2.eval("RTT_ORDER[%d].name" % i)))
           for i in range(1, int(rt2.eval("#RTT_ORDER")) + 1)]
    assert got == [("Red", "Alice"), ("Yellow", "Bob")], \
        "the draft's shuffle did not survive a reload: %s" % got

    # and a new game forgets it, rather than carrying it into the next one
    rt2.execute("rttResetRunState()")
    assert rt2.eval("#RTT_ORDER") == 0, \
        "last game's person-to-seat mapping survived a new game: %s" % rt2.eval("#RTT_ORDER")


def t_six_seats_cannot_happen_while_the_layout_is_not_clockwise(src):
    """A trip-wire, not a fix: RTT_LAYOUT[6] is not clockwise, and nothing can reach it today.

    The audit listed six-seat row order as unverified in either direction. Checking it: five players
    draft SIX cards (RTT_DRAFT_N = 6) and the seat count is RTT_DN - 1, so five is the maximum; the
    manual path asks for 4 or 5. Six seats cannot occur, so the mismatch cannot bite -- and there is
    nothing to fix.

    But if six are ever enabled, it bites immediately. Turn order is derived clockwise from the seat
    POSITIONS, while a seat's colour is RTT_SETUP_COLORS[seat index] and the index comes from
    RTT_LAYOUT. At 2-5 those two orders coincide. RTT_LAYOUT[6] is {1,2,5,6,4,3} where clockwise is
    {1,5,2,4,6,3}, so at six seats a player's colour would stop stating their turn order -- which is
    the whole point of forcing the colours.

    This fails the moment six seats become reachable, and points at the reason.
    """
    import math
    rt = fresh(src)

    # 1. six seats are not reachable
    for arg, want in (("nil", 4), ("'fivePlayerSetup'", 5)):
        r = fresh(src)
        r.execute("pcall(function() setupFactionBoards(nil,nil,%s) end) FLUSH(20)" % arg)
        assert r.eval("RTT_TURN_SEATS") == want, \
            "the manual path asked for %s seats, not %d" % (r.eval("RTT_TURN_SEATS"), want)
    assert int(rt.eval("RTT_DRAFT_N or 0")) in (0, 6), \
        "the draft size changed: %s" % rt.eval("RTT_DRAFT_N")

    # 2. and while that holds, every REACHABLE layout is clockwise, so colour states turn order
    POS = {i: (rt.eval("RTT_POS[%d][1]" % i), rt.eval("RTT_POS[%d][2]" % i)) for i in range(1, 7)}
    a0 = math.atan2(POS[1][1], POS[1][0])
    for n in (2, 3, 4, 5):
        layout = [int(rt.eval("RTT_LAYOUT[%d]" % n)[i]) for i in range(1, n + 1)]
        angles = [(a0 - math.atan2(POS[p][1], POS[p][0])) % (2 * math.pi) for p in layout]
        assert angles == sorted(angles), \
            "%d seats: RTT_LAYOUT is not in clockwise order: %s" % (n, layout)

    # 3. THE TRIP-WIRE. Six is not clockwise; if it ever becomes reachable this must be fixed first.
    layout6 = [int(rt.eval("RTT_LAYOUT[6]")[i]) for i in range(1, 7)]
    angles6 = [(a0 - math.atan2(POS[p][1], POS[p][0])) % (2 * math.pi) for p in layout6]
    assert angles6 != sorted(angles6), (
        "RTT_LAYOUT[6] is clockwise now -- if six seats have been enabled, delete this trip-wire; "
        "if not, someone reordered it and the comment about it should go too")


def t_both_setup_paths_leave_the_same_kind_of_record(src):
    """The two ways to start a game must agree about what a seat record looks like.

    "structural fault 2 for the fifth time" is a real commit message in this repo: the ranked draft
    and the manual picker have disagreed about the teardown tag list, the run-state reset, the busy
    flag, hand-1 ordering and the turn system, each fixed in one path and forgotten in the other. The
    tests drove them separately, so a difference between them was never itself the thing under test.

    This drives BOTH to a finished four-seat table and asserts the same invariants on each -- not that
    they produce identical values (they cannot: the draft forces turn-card colours, the manual path
    takes whatever the picker was wearing) but that every rule the rest of the system relies on holds
    either way.
    """
    def ranked():
        rt = fresh(src)
        joined = ["Purple", "Blue", "White", "Pink"]
        _seat_ranked(rt, joined, ["H1", "H2", "H3", "H4"])
        for i, fac in enumerate(("Marquise de Cat", "Eyrie Dynasties",
                                 "Woodland Alliance", "The Lizard Cult")):
            rt.execute("""local s = RTT_SEATS[%d]
                          pcall(function()
                            rttPlaceFaction(%r, s.pos[1], s.pos[2], s.pos[2] > 0, s.color,
                                            true, nil, nil, s.color, nil)
                          end) FLUSH(60)""" % (i + 1, fac))
        return rt

    def manual():
        rt = fresh(src)
        for i, c in enumerate(("Red", "Yellow", "Orange", "Teal")):
            rt.execute("SEAT(%r,'H%d')" % (c, i + 1))
        rt.execute("pcall(function() setupFactionBoards(nil,nil,nil) end) FLUSH(60)")
        for i, (fac, x, z) in enumerate((("Marquise de Cat", 52, -46), ("Eyrie Dynasties", -52, -46),
                                         ("Woodland Alliance", 52, 46), ("The Lizard Cult", -52, 46))):
            rt.execute("pcall(function() rttPlaceFaction(%r,%f,%f,%s,nil,false,'Standard',0,%r) end) "
                       "FLUSH(60)" % (fac, x, z, "true" if z > 0 else "false",
                                      ("Red", "Yellow", "Orange", "Teal")[i]))
        return rt

    for name, rt in (("ranked", ranked()), ("manual", manual())):
        n = int(rt.eval("#RTT_SEATS"))
        assert n == 4, "%s: %d seats, expected 4" % (name, n)

        seats = [{k: rt.eval("RTT_SEATS[%d].%s" % (i + 1, k)) for k in
                  ("color", "faction", "key", "owner")} for i in range(n)]

        cols = [s["color"] for s in seats]
        assert all(cols), "%s: a seat has no colour: %s" % (name, cols)
        assert len(set(cols)) == n, "%s: two seats share a colour: %s" % (name, cols)
        assert all(s["faction"] for s in seats), "%s: a seat has no faction" % name
        assert all(s["key"] for s in seats), "%s: a seat has no key -- the sheet keys on it" % name

        # the array is contiguous: a hole truncates eight different loops
        assert int(rt.eval("function() local k = 0 for _ in ipairs(RTT_SEATS) do k = k + 1 end return k end")()) == n, \
            "%s: the seat array has a hole in it" % name

        # the published record is a faithful projection of it
        rec = json.loads(rt.eval('GVGET("RTT_SEAT_RECORD")') or "{}")
        assert len(rec.get("seats", [])) == n, \
            "%s: published %d seats of %d" % (name, len(rec.get("seats", [])), n)
        for e in rec["seats"]:
            # NO EMPTY FIELDS. The sheet drops an empty value per seat and falls back to guessing that
            # row's colour from hand-zone geometry -- silently, because an empty string reads as "no
            # answer" rather than as an error. A seat that has a faction has a colour, a key and a row
            # name, or it should not be in the record at all.
            assert e["color"] and e["key"] and e.get("row"), \
                "%s: a published seat is missing a field: %s" % (name, e)
            assert e["faction"], "%s: a published seat has no faction: %s" % (name, e)
        assert sorted(e["color"] for e in rec["seats"]) == sorted(cols), \
            "%s: the record's colours are not the seats': %s vs %s" % (name, rec["seats"], cols)

        # and the turn order is exactly those colours
        order = list((rt.eval("Turns.order") or {}).values())
        assert sorted(order) == sorted(cols), \
            "%s: turn order %s is not the seat colours %s" % (name, order, cols)


def t_a_seat_fact_has_one_writer(src):
    """Each fact about a seat is written in one place, and the setters enforce their own rules.

    This is deliberately a SOURCE-SHAPE test, which the rest of this file avoids -- you cannot execute
    "nobody else assigns this field". The invariant is the point: a seat's colour was assigned in four
    places, each carrying its own copy of the same two rules, and at four players P3 and P4 held each
    other's colour in every game. The owner was written in two, one of which only filled a gap, so a
    seat kept the first name it ever saw and the sheet credited the game to whoever had left.

    The behaviour of each setter is pinned by its own test; this pins that they are the only way in.
    """
    import re as _re
    code = [l for l in src.split("\n")
            if not l.strip().startswith("--") and len(l) < 500]

    LIMITS = {
        "color":   (1, "rttSetSeatColor"),
        "owner":   (1, "rttSetSeatOwner"),
        "faction": (1, "rttPlaceFaction"),
        # key and vagN are two branches of one if/else, in one function -- a vagabond seat and a
        # normal one, decided together at the pick
        "key":     (2, "rttPlaceFaction"),
        "vagN":    (2, "rttPlaceFaction"),
        # one setter, plus the clear when a board is drafted away
        "board":   (2, "rttAttachBoard"),
    }
    for field, (limit, owner_fn) in LIMITS.items():
        hits = [l.strip() for l in code
                if _re.search(r"\b(seat|s)\.%s\s*=\s*[^=]" % field, l)]
        assert len(hits) <= limit, (
            "%s is assigned in %d places, expected at most %d -- it should go through %s:\n  %s"
            % (field, len(hits), limit, owner_fn, "\n  ".join(hits[:4])))

    for fn in ("rttSetSeatColor", "rttSetSeatOwner", "rttPersonIn", "rttAttachBoard"):
        assert ("function %s" % fn) in src, "%s is gone; a fact has lost its one writer" % fn

    # NOT asserted: the number of loops over the player list. Nine exist across the board script and
    # they ask genuinely different questions -- which colours are taken, how many are seated, deal one
    # card to each. Only "who is sitting in THIS colour" was duplicated, and rttPersonIn is now the
    # single answer to it; counting the rest would be a number invented to be met.

    # and the setters really do refuse what they are there to refuse
    rt = fresh(src)
    rt.execute("RTT_SEATS = { { pos = {52,-46}, color = 'Red', owner = 'Alice' }, { pos = {-52,-46} } }")
    assert rt.eval("rttSetSeatColor(RTT_SEATS[2], 'Red')") is None, "a duplicate colour got through"
    assert rt.eval("rttSetSeatOwner(RTT_SEATS[1], '')") == "Alice", "an empty name overwrote a real one"
    assert rt.eval("rttSetSeatOwner(RTT_SEATS[1], 'Bob')") == "Bob", "the owner is not refreshed"


def t_every_seat_gets_its_faction_buttons(src):
    """A draft lights EVERY seat's board, not just the first one it reaches.

    Maintainer, 2026-09-10: "so you now currently still broken cannot spawn a second faction after a
    draft", and before that "it s like only sometimes the button works and only can spawn 1 faction",
    with `[Faction Selection - bab7e1] Lua Error: Object reference not set to an instance of an
    object.` on every load and every pick.

    That is TTS's null for `UI.setAttribute` against an id the object's XML does not declare. The
    map/deck pick was deleted from the selector's blueprint on 2026-09-07 and three of the four lines
    that drove it went with it; the fourth was the FIRST statement in rttShowFactions's per-seat loop.
    So from that day the loop threw on the first seat that had a board and every seat after it kept a
    dark board -- one player could pick, nobody else could, and it read as intermittent because which
    seat you were decided whether you saw it.

    Nothing could see it here either: the stub accepted any id, so the bogus call was a no-op and the
    suite was green for three days. The stub now refuses an id the blueprint does not declare, exactly
    as TTS does, which is what makes this test able to fail.
    """
    rt = fresh(src)
    rt.execute("pcall(function() rttSetup(Player['Red'], '', 'rttRankedBtn') end) FLUSH(200)")

    boards = rt.eval("function() local n = 0 "
                     "for _, s in ipairs(RTT_SEATS or {}) do if s.board ~= nil then n = n + 1 end end "
                     "return n end")()
    assert boards >= 3, "the draft only put %d selector boards out" % boards

    err = rt.eval("function() local ok, e = pcall(function() rttShowFactions() end) "
                  "return ok and '' or tostring(e) end")()
    assert err == "", "rttShowFactions threw: %s" % err[:120]

    # EVERY board, not just the first. This is the assertion the bug broke.
    lit = rt.eval("function() local n = 0 "
                  "for _, s in ipairs(RTT_SEATS or {}) do "
                  "  if s.board ~= nil and s.board.__uiattr['rttFactions.active'] == 'true' then "
                  "    n = n + 1 end end "
                  "return n end")()
    assert lit == boards, "%d of %d seats had their faction buttons lit" % (lit, boards)

    # ...and a pick still leaves the others pickable, which is what he actually reported
    rt.execute("""
      local s = RTT_SEATS[1]
      if s ~= nil and s.board ~= nil then
        pcall(function() rttCoordFaction({ color = s.color or 'Red', id = 'rttFac1',
                                           board = s.board.getGUID() }) end)
      end
      FLUSH(200)""")
    left = rt.eval("function() local n = 0 "
                   "for _, s in ipairs(RTT_SEATS or {}) do "
                   "  if s.board ~= nil and s.board.__uiattr['rttFactions.active'] == 'true' then "
                   "    n = n + 1 end end "
                   "return n end")()
    assert left == boards - 1, \
        "after one pick %d of the remaining %d boards are still lit" % (left, boards - 1)


def t_an_empty_seats_board_can_be_picked_by_anyone(src):
    """Every board answers a click unless a real person is sitting in that seat.

    Maintainer, 2026-09-10: "draft works but then clicking on faction buttons does nothing", and
    before that "it s like only sometimes the button works and only can spawn 1 faction".

    ONE LINE, DOING EXACTLY WHAT IT SAID, against a fact that changed underneath it:

        if s.color ~= nil and args.color ~= s.color then return end   -- only YOUR own seat's board

    rttBindSeatColors gives EVERY seat a colour whether or not a human is in it -- "the colour of the
    human sitting at it, or a free one if nobody is" -- because that colour owns the hand, the cards
    and the turn slot. So `s.color ~= nil` is true for every seat, always, and the guard reduced to
    "only the exact colour of this seat may ever click it". At a table with one person that is ONE
    board and the rest ignore him without a word: not a crash, not an error, nothing.

    What it means to guard is a person taking a pick away from another PERSON, so it asks
    rttPersonIn -- the function written for exactly that question. Both halves are asserted here,
    because dropping the guard entirely would let a player pick out of an occupied seat.
    """
    # ONE HUMAN: every board is his to click, or the draft cannot finish
    rt = fresh(src)
    rt.execute("pcall(function() rttSetup(Player['Red'], '', 'rttRankedBtn') end) FLUSH(200)")
    boards = rt.eval("function() local n = 0 "
                     "for _, s in ipairs(RTT_SEATS or {}) do if s.board ~= nil then n = n + 1 end end "
                     "return n end")()
    assert boards >= 3, "the draft only put %d boards out" % boards
    got = rt.eval("""function()
        local n = 0
        for i, s in ipairs(RTT_SEATS or {}) do
          if s.board ~= nil then
            local before = #getObjectsWithTag('RTT Faction')
            pcall(function() rttCoordFaction({ color = 'Red', id = 'rttFac' .. i,
                                               board = s.board.getGUID() }) end)
            FLUSH(80)
            if #getObjectsWithTag('RTT Faction') > before then n = n + 1 end
          end
        end
        return n
    end""")()
    assert got == boards, \
        "only %d of %d boards answered the one player at the table" % (got, boards)

    # ...AND A SEAT SOMEBODY IS SITTING IN IS STILL THEIRS ALONE.
    #
    # The occupant is seated AFTER the draft, into whatever colour the draft happened to give a seat.
    # Seating first and hoping does not work: the draft assigns seat colours at random, so which seat
    # a given human lands in -- or whether they land in the clicker's own seat -- changes run to run.
    # This test failed about one run in three that way, which is worse than no test at all.
    rt = fresh(src)
    rt.execute("pcall(function() rttSetup(Player['Red'], '', 'rttRankedBtn') end) FLUSH(200)")
    victim = rt.eval("""function()
        for i, s in ipairs(RTT_SEATS or {}) do
          if s.board ~= nil and s.color ~= nil and s.color ~= 'Red' then
            SEAT(s.color)                      -- put a real person in that seat, whatever colour it got
            return i
          end
        end
        return 0
    end""")()
    assert victim > 0, "the draft produced no seat in a colour other than Red"
    refused = rt.eval("""function()
        local s = RTT_SEATS[%d]
        if rttPersonIn(s.color) == nil then return "nobody is actually seated in " .. tostring(s.color) end
        local before = #getObjectsWithTag('RTT Faction')
        pcall(function() rttCoordFaction({ color = 'Red', id = 'rttFac1',
                                           board = s.board.getGUID() }) end)
        FLUSH(80)
        if #getObjectsWithTag('RTT Faction') > before then
          return "Red picked out of " .. tostring(s.color) .. "'s seat"
        end
        return ""
    end""" % victim)()
    assert refused == "", refused


def t_pressing_a_setup_button_twice_touches_nothing_dead(src):
    """A second setup click destroys nothing twice, on any pair of buttons.

    Maintainer, 2026-09-10: "cliking on 4 person draft after 3 person draft spawns this error though",
    with "[Faction Selection - bab7e1] Lua Error: Object reference not set to an instance of an
    object." It was never about the 3-player button: it was EVERY second setup click, by any pair,
    and it had been happening for five days.

    rttClearGameObjects sweeps the teardown TAGS through rttDestroyUI -- which blanks the object's XML
    and defers destruct() by a frame, holding the handle -- and then sweeps RTT_SPAWNED by guid and
    destroys those SYNCHRONOUSLY. The turn-order deck is on both lists: its blueprint carries
    "Tags":["RTT Order Card"] and rttDealOrder records its guid. So it was destroyed now and destroyed
    again a frame later, on a handle that was already dead. Two more lists had the same shape --
    RTT_MARSH_PIECES (nineteen dead handles in one 5-player Marsh rebuild) and RTT_MTN_LM_PIECES.

    Touching a destroyed object is a C# null on TTS's side and pcall does NOT catch it, which is why
    every one of these sites was already wrapped in one.

    Two things had to change in the harness before this could be seen at all, and both are the point:
    a destroyed handle now throws the way TTS does, and a blueprint's OUTER "Tags" is now read from the
    end of the blob rather than the head -- TTS serialises it after "ContainedObjects", so the order
    deck arrived untagged here and the harness only ever destroyed it once.
    """
    SEQUENCES = (
        ("3P then 4P",   "rtt3PStart(Player['Red'],'','rtt3PBtn')",     "rttSetup(Player['Red'],'','rttRankedBtn')"),
        ("4P then 4P",   "rttSetup(Player['Red'],'','rttRankedBtn')",   "rttSetup(Player['Red'],'','rttRankedBtn')"),
        ("5P then 4P",   "rttFivePStart()",                            "rttSetup(Player['Red'],'','rttRankedBtn')"),
        ("4P then 3P",   "rttSetup(Player['Red'],'','rttRankedBtn')",   "rtt3PStart(Player['Red'],'','rtt3PBtn')"),
        ("Marsh twice",  "makeMap('','','Marsh Map')",                  "makeMap('','','Marsh Map')"),
        ("Mountain twice", "makeMap('','','Mountain Map')",             "makeMap('','','Mountain Map')"),
        ("4P Setup twice", "setupFactionBoards(nil,nil,'four')",        "setupFactionBoards(nil,nil,'four')"),
    )
    # pcall is wrapped rather than removed: in TTS this class of error is NOT catchable, so a pcall
    # that "succeeds" in the harness is exactly the false comfort being tested for.
    WRAP = ("NULLS = {} local _p = pcall "
            "pcall = function(f, ...) local ok, e = _p(f, ...) "
            "  if not ok and tostring(e):find('Object reference not set') then "
            "    NULLS[#NULLS+1] = tostring(e) end "
            "  return ok, e end ")
    for label, first, second in SEQUENCES:
        rt = fresh(src)
        rt.execute("%s pcall(function() %s end) FLUSH(250) NULLS = {} "
                   "pcall(function() %s end) FLUSH(250)" % (WRAP, first, second))
        nulls = rt.eval("NULLS")
        nulls = list(dict(nulls).values()) if nulls else []
        assert not nulls, "%s: %d dead handle(s) touched on the second click, first: %s" % (
            label, len(nulls), nulls[0][:150])


def t_the_resync_sweep_resends_everything_it_may_touch(src):
    """One blind pass over the table, skipping the four things it must never touch.

    MULTIPLAYER_SYNC.md: the host cannot detect what a client is missing, so the repair is an
    unconditional blind resend. Unlock-then-lock cures it by hand because setLock is an authoritative
    object-state write -- a client that applies it and finds it has no such object takes the full
    object state from that message. Nothing about being locked matters, so the sweep uses the cheapest
    write there is; the mode is one constant with two proven fallbacks behind it.

    THE EXCLUSIONS ARE THE TEST. A missed object is a cosmetic bug; a freed prisoner or a card yanked
    out of somebody's hand is a real one.
    """
    rt = fresh(src)
    rt.execute("PLAIN = MKOBJ('Warrior', {1, 11.6, 1}, {}) "
               "HELD  = MKOBJ('Held', {2, 11.6, 2}, {}) HELD.held_by_color = 'Red' "
               "JAIL  = MKOBJ('Cat Warrior', {3, 11.6, 3}, {}) JAIL.setLock(true) "
               "RTT_LAID[JAIL.getGUID()] = { rot = {0,0,0}, pos = {3,11.6,3}, who = 'Red' }")
    tag = rt.eval("RTT_RESYNC_TAG")

    ran = rt.eval("function() return rttResyncSweep() end")()
    assert ran is True, "the sweep refused to run on an idle table"
    marked = lambda o: rt.eval("function() return %s.hasTag('%s') end" % (o, tag))()
    assert marked("PLAIN") is True, "the sweep skipped an ordinary object"
    assert marked("HELD") is False, "the sweep reached into a player's hands"
    assert marked("JAIL") is False, "the sweep touched a laid prisoner"
    assert rt.eval("function() return self.hasTag('%s') end" % tag)() is False, \
        "the sweep touched the coordinator board, which carries the live XML UI"

    # AND IT PUTS EVERYTHING BACK. A mark left on is a mark the next sweep will not make.
    rt.execute("FLUSH(20)")
    assert marked("PLAIN") is False, "the resync mark was never taken off again"
    assert rt.eval("RTT_RESYNC_BUSY") is False, "the sweep never released its own busy flag"
    assert rt.eval("RTT_RESYNCING") is False, "the prisoner guard was left armed"

    # THE PRISONER GUARD. rttFreeUnlockedPrisoners ticks every second and stands a prisoner up the
    # moment it finds one unlocked -- and the "lock" fallback unlocks a swept object for two frames.
    rt.execute("RTT_RESYNCING = true JAIL.setLock(false) rttFreeUnlockedPrisoners()")
    assert rt.eval("function() return RTT_LAID[JAIL.getGUID()] ~= nil end")() is True, \
        "the prisoner gizmo undid itself during a sweep"
    rt.execute("RTT_RESYNCING = false rttFreeUnlockedPrisoners()")
    assert rt.eval("function() return RTT_LAID[JAIL.getGUID()] == nil end")() is True, \
        "the guard stayed on after the sweep and the gizmo stopped working"

    # DEBOUNCED, so a player mashing the button cannot stack sweeps on each other
    rt = fresh(src)
    rt.execute("for i = 1, 40 do MKOBJ('P' .. i, {i, 11.6, 0}, {}) end")
    assert rt.eval("function() return rttResyncSweep() end")() is True
    assert rt.eval("function() return rttResyncSweep() end")() is False, \
        "a second sweep started while the first was still running"

    # ...AND NOTHING RUNS BY ITSELF AT ALL. The first version armed a pair of sweeps after every
    # spawn; a sweep writes state to every object on the table, which on a connection already dropping
    # messages is more traffic in the same window as a draft where every click round-trips. Until the
    # primitive is proven to replicate, the button is the only way in and an unpressed build costs
    # nothing.
    assert rt.eval("RTT_RESYNC_AUTO") is not True, \
        "the automatic sweeps are armed again before the primitive has been proven"
    body = src[src.index("function rttResyncArm()"):]
    body = body[:body.index("\nend")]
    assert "-1" not in body, "the resync arm schedules a repeating tick: %s" % body
    assert "RTT_RESYNC_AUTO ~= true then return" in body, \
        "rttResyncArm no longer honours the off switch"



def t_the_resync_button_asks_nothing_and_destroys_nothing(src):
    """A Resync button in the second row, wired straight to the sweep.

    Maintainer, 2026-09-10: "build the resych button in the second row for handling persistent bug."

    It is the manual half of the same repair: the automatic sweeps run after a spawn, and a message
    dropped at a moment nobody spawned anything is only reachable by hand. It destroys nothing, so it
    is not in RTT_WIPE_BTN and carries no warning -- one click and it runs.
    """
    x = json.load(open(os.path.join(REPO, "dist/Root_Tabletop_Tournament.json"), encoding="utf-8"))
    def walk(objs):
        for o in objs:
            yield o
            for c in (o.get("ContainedObjects") or []):
                yield from walk([c])
    board = [o for o in walk(x["ObjectStates"]) if o.get("GUID") == "bab7e1"][0]
    xml = board["XmlUI"]

    m = re.search(r'<Button id="rttResyncBtn"[^>]*>', xml)
    assert m, "there is no Resync button on the board"
    seg = m.group(0)
    assert 'onclick="rttResyncClick"' in seg, "Resync is not wired to the sweep: %s" % seg
    assert 'position="19 -70 ' in seg, "Resync is not in the second option row: %s" % seg
    assert 'icon="ResyncArt"' in seg, "Resync has no label art: %s" % seg
    assets = {a.get("Name"): a.get("URL") for a in (board.get("CustomUIAssets") or [])}
    assert "ResyncArt" in assets, "the board declares no ResyncArt asset"
    assert assets["ResyncArt"].endswith(".png"), assets["ResyncArt"]

    # it sits in the group More swaps out, like every other option button
    rows = xml[xml.find('<ToggleGroup id="optionRows"'):]
    rows = rows[:rows.find("</ToggleGroup>")]
    assert 'id="rttResyncBtn"' in rows, "Resync is outside the option rows"

    # IT NEVER ASKS, because it takes nothing away
    rt = fresh(src)
    assert rt.eval("RTT_WIPE_BTN['rttResyncBtn']") is None, \
        "Resync is registered as a destructive button"
    rt.execute("PLAIN = MKOBJ('Warrior', {1, 11.6, 1}, {}) "
               "pcall(function() rttResyncClick(Player['Red'], '', 'rttResyncBtn') end)")
    assert rt.eval("function() return PLAIN.hasTag(RTT_RESYNC_TAG) end")() is True, \
        "the button did not run a sweep"
    rt.execute("FLUSH(20)")
    assert rt.eval("function() return PLAIN.__dead end")() is False, \
        "the Resync button destroyed something"


def t_a_resync_survives_the_table_changing_under_it(src):
    """The sweep touches no dead handle, however hard the table is churned while it runs.

    A sweep runs over about two dozen frames and a draft destroys objects the whole time it is going
    -- every selector board goes as its seat picks, a map change takes everything on the board. The
    first version held the object handles it collected; this one keeps GUIDS and re-resolves each one
    at the moment it touches it, undo included, so a piece that has gone since the list was built is
    simply not there.

    That distinction is the difference between a repair and a second bug: touching a destroyed object
    is a C# null on TTS's side -- "Object reference not set to an instance of an object" -- which is
    exactly the error the sweep exists to stop people seeing, and which pcall does not catch.

    It also has to leave nothing behind: a resync mark left on an object is a mark the next sweep will
    skip, so the repair would quietly stop working for that piece.
    """
    WRAP = ("NULLS = {} local _p = pcall "
            "pcall = function(f, ...) local ok, e = _p(f, ...) "
            "  if not ok and tostring(e):find('Object reference not set') then "
            "    NULLS[#NULLS+1] = tostring(e) end "
            "  return ok, e end ")
    CASES = (
        ("a full table",
         "pcall(function() rttSetup(Player['Red'],'','rttRankedBtn') end) FLUSH(250) NULLS={} "
         "rttResyncClick(Player['Red'],'','rttResyncBtn') FLUSH(60)"),
        ("a new game starting under it",
         "pcall(function() rttSetup(Player['Red'],'','rttRankedBtn') end) FLUSH(250) NULLS={} "
         "rttResyncClick(Player['Red'],'','rttResyncBtn') "
         "pcall(function() rttSetup(Player['Red'],'','rttRankedBtn') end) FLUSH(250)"),
        ("a map rebuilt under it",
         "pcall(function() makeMap('','','Marsh Map') end) FLUSH(150) NULLS={} "
         "rttResyncClick(Player['Red'],'','rttResyncBtn') "
         "pcall(function() makeMap('','','Gorge Map') end) FLUSH(200)"),
        ("the button mashed ten times",
         "pcall(function() rttSetup(Player['Red'],'','rttRankedBtn') end) FLUSH(250) NULLS={} "
         "for i=1,10 do rttResyncClick(Player['Red'],'','rttResyncBtn') end FLUSH(60)"),
    )
    for label, body in CASES:
        rt = fresh(src)
        rt.execute(WRAP + body)
        nulls = rt.eval("NULLS")
        nulls = list(dict(nulls).values()) if nulls else []
        assert not nulls, "resync with %s touched %d dead handle(s): %s" % (
            label, len(nulls), nulls[0][:140])
        left = rt.eval("function() local n = 0 "
                       "for _, o in ipairs(getAllObjects()) do "
                       "  if o.hasTag(RTT_RESYNC_TAG) then n = n + 1 end end return n end")()
        assert left == 0, "resync with %s left its mark on %d object(s)" % (label, left)


def t_a_faction_spawns_a_few_pieces_at_a_time(src):
    """A faction goes out over several frames, in order, with every piece still arriving.

    Maintainer, 2026-09-10, on which objects go missing for distant clients: "the bug in general
    occurs with the faction spawning exclusiveley not so much the other objects."

    That is the biggest burst in the mod by a long way. A faction used to fire its whole blueprint in
    ONE frame: the Lilypad Diaspora is 229 KB of object JSON in 25 objects (163 KB of it twelve
    Enclaves carrying the same 13,620-byte script), the Knaves are 51 objects, and a 5-player setup
    pushes ~565 KB through a handful of frames. A spawn reaches a client as an incremental create
    message and nothing ever re-sends it.

    Three things have to hold, and each has bitten something here before. ORDER, because the rats'
    mood cards are spawned from the rats board's own callback so the board has a collider under them
    first. TWO BUDGETS, because a count alone waves through a piece that is heavy on its own. And
    EVERY PIECE ARRIVES -- a pump that drops the tail is a far worse bug than the one it fixes.
    """
    rt = fresh(src)
    rt.execute("SEEN = {} local _s = spawnObjectJSON "
               "spawnObjectJSON = function(p) SEEN[#SEEN+1] = p.json return _s(p) end")
    rt.execute("local specs = {} "
               "for i = 1, 20 do specs[i] = { json = '{\"Nickname\":\"p' .. string.format('%02d', i) "
               "  .. '\"}' } end rttSpawnStaggered(specs)")
    per = rt.eval("RTT_SPAWN_PER_FRAME")
    got = lambda: rt.eval("function() return #SEEN end")()
    assert got() == per, "the first frame spawned %d objects, not %d" % (got(), per)
    rt.execute("FLUSH(1)")
    assert got() == 2 * per, "the second frame took it to %d, not %d" % (got(), 2 * per)
    rt.execute("FLUSH(30)")
    assert got() == 20, "%d of 20 objects were ever spawned" % got()
    seen = [rt.eval("function() return SEEN[%d] end" % (i + 1))() for i in range(20)]
    assert all(s.find('"p%02d"' % (i + 1)) >= 0 for i, s in enumerate(seen)), \
        "the pump reordered the blueprint"

    # THE BYTE BUDGET, on pieces too heavy to send six at a time
    rt.execute("SEEN = {} local big = string.rep('x', 30000) local specs = {} "
               "for i = 1, 6 do specs[i] = { json = '{\"j\":\"' .. big .. '\"}' } end "
               "rttSpawnStaggered(specs)")
    assert got() < per, "%d heavy pieces went in one frame; the byte budget did nothing" % got()
    rt.execute("FLUSH(30)")
    assert got() == 6, "the byte-budgeted pump lost pieces: %d of 6" % got()
    # ...but one piece bigger than the whole budget still goes, rather than jamming forever
    rt.execute("SEEN = {} rttSpawnStaggered({ { json = string.rep('x', 200000) } })")
    assert got() == 1, "a piece larger than the byte budget was never spawned"

    # AND A REAL FACTION STILL PUTS DOWN EVERY PIECE IT USED TO
    for faction, least in (("Lilypad Diaspora", 20), ("Knaves of the Deepwood", 12),
                           ("Marquise de Cat", 24)):
        rt = fresh(src)
        rt.execute("pcall(function() rttSpawnFaction(%r, 0, 0, false) end) FLUSH(200)" % faction)
        n = rt.eval("function() return #getObjectsWithTag('RTT Faction') end")()
        assert n >= least, "%s put down %d pieces, expected at least %d" % (faction, n, least)


def t_a_captain_card_lands_upright_in_its_slot(src):
    """The captain board's three slots turn a card square to the board.

    Maintainer, 2026-09-11: "the captain board of the knave needs to rotate the captain card in place
    with the snap", and "if I put a captain card horizontally it stays horizontal instead of rotating
    vertically."

    The board's baked snap points carry a Position and nothing else, so TTS snapped where the card
    landed and left its facing alone. Rotation snapping is asked for per point.

    IT IS ASKED FOR AT SPAWN, NOT BAKED, and that is deliberate: across 2,183 snap points in the
    maintainer's whole Saves folder, TTS itself has only ever written Position and Rotation, so there
    is no evidence the save format carries the flag -- and a key the format ignores would look like a
    fix and do nothing. The Lua field names are known, so the spawn callback uses them.

    ZERO MEANS THE BOARD'S OWN FACING. Snap rotations are local, so a card lands square to the board
    whatever angle the seat put it at, and the slots are portrait -- 0.39 by 0.56 in local units,
    measured off the snap spacing and the board art -- so square to the board is upright.
    """
    rt = fresh(src)
    rt.execute("BOARD = MKOBJ('Knaves Board', {0, 11.6, 0}, {}) "
               "pcall(function() rttSpawnCaptainsFor(BOARD) end) FLUSH(30) "
               "CAP = nil for _, o in ipairs(getAllObjects()) do "
               "  if o.hasTag('RTT Captains') then CAP = o end end")
    assert rt.eval("function() return CAP ~= nil end")(), "no captain board was spawned"
    n = rt.eval("function() return #(CAP.getSnapPoints() or {}) end")()
    assert n == 3, "the captain board has %d slots, expected 3" % n
    bad = rt.eval("""function()
        local out = {}
        for i, s in ipairs(CAP.getSnapPoints() or {}) do
          local r = s.rotation
          local ry = r and (r[2] or r.y) or nil
          if s.rotation_snap ~= true then out[#out+1] = "slot " .. i .. " does not snap rotation" end
          if ry == nil or math.abs(ry) > 0.001 then
            out[#out+1] = "slot " .. i .. " turns a card to " .. tostring(ry) .. ", not square to the board"
          end
        end
        return out
    end""")()
    bad = list(dict(bad).values()) if bad else []
    assert not bad, "; ".join(bad)


def t_no_kit_loses_pieces_to_its_own_callback(src):
    """Every piece a faction kit hands the spawner reaches the table.

    Found while checking something else: rttSpawnFaction('Vagabond Layout') put TWO objects down and
    stopped. The kit was not short -- all 17 entries had a move_to -- and no other kit did it.

    The second piece is the Mighty Multi-State Ruins bag, and it is the only object in the whole
    content file tagged "Ruin Set". The callback destroyed it for being a Ruin Set and then, on the
    very next line, asked it whether it was "Shuffleable" -- which it also is, being the only object
    tagged both. Touching a destroyed object is not a Lua error TTS lets you carry on from; it is the
    C# null, "Object reference not set to an instance of an object", so the callback died there and
    took the other fifteen pieces with it.

    THE INVARIANT IS COUNTED, NOT LISTED, so it cannot go stale as kits change: rttSpawnFaction
    filters its blueprint (dice, drafted captains, ten of the eleven vagabond VP tiles) and hands what
    is left to rttSpawnStaggered. Every spec handed over must arrive. That holds a callback to the one
    rule this bug broke -- do not touch a piece you destroyed -- for every kit, including ones added
    later.
    """
    rt = fresh(src)
    rt.execute("""
      REPORT = {}
      local kits = {}
      for k in pairs(EVERYTHING['Standard']) do kits[#kits+1] = k end
      table.sort(kits)
      for _, kit in ipairs(kits) do
        local want, got = 0, 0
        local _stag, _spawn = rttSpawnStaggered, spawnObjectJSON
        rttSpawnStaggered = function(specs, ...) want = want + #specs return _stag(specs, ...) end
        spawnObjectJSON = function(p) got = got + 1 return _spawn(p) end
        local ok, err = pcall(function() rttSpawnFaction(kit, 0, 0, false) end)
        FLUSH(400)
        rttSpawnStaggered, spawnObjectJSON = _stag, _spawn
        if not ok or got < want then
          REPORT[#REPORT+1] = kit .. ": handed " .. want .. ", spawned " .. got
                              .. (ok and "" or (" -- " .. tostring(err)))
        end
      end
    """)
    n = rt.eval("function() return #REPORT end")()
    bad = [rt.eval("function() return REPORT[%d] end" % (i + 1))() for i in range(n)]
    assert not bad, "; ".join(bad)


def t_the_vagabond_gets_no_advanced_setup_card(src):
    """The Vagabond's crafted board comes out bare, like every other faction's.

    Maintainer, 2026-09-11: "vagabond faction board sitll spawn the advanced setup card on the crafter
    improvement that we removed for all other faction boards."

    It was a nameless Card in the kit -- CardID 406, identified by its own art, which reads "Vagabond /
    ADVANCED SETUP" -- dropped at (17.53, 0.21, -1.37), directly onto the crafted improvements board
    that sits at (17.55, 0.10, -4.27). The kit is the only place a loose Card appears, so the check is
    simply that none does.

    This could not have been checked before: the kit stopped after two pieces, and the card is the
    eighteenth. See t_no_kit_loses_pieces_to_its_own_callback.
    """
    rt = fresh(src)
    rt.execute("""
      SEEN = {}
      local _s = spawnObjectJSON
      spawnObjectJSON = function(p) SEEN[#SEEN+1] = (p.json or '') return _s(p) end
      pcall(function() rttSpawnFaction('Vagabond Layout', 0, 0, false) end)
      FLUSH(400)
      spawnObjectJSON = _s
      -- THE FIRST "Name" IN THE BLUEPRINT IS THE OBJECT'S OWN. Matching it anywhere reached inside
      -- the Quest deck's ContainedObjects and reported one of its 12 quest cards (CardID 11800) as a
      -- loose card on the board.
      CARDS = {}
      for _, j in ipairs(SEEN) do
        if j:match('"Name": "([^"]*)"') == "Card" then
          CARDS[#CARDS+1] = tostring(j:match('"CardID": (%d+)'))
        end
      end
    """)
    # NOT A FIXED NUMBER. The kit no longer carries the eleven relationship markers -- rttRelSync
    # places one as each faction arrives -- so what it spawns is everything else, counted off the
    # blueprint so this cannot go stale. The guard is here only so "no loose card" cannot pass by
    # spawning nothing at all.
    want = rt.eval("""function()
        local n = 0
        for _, v in ipairs(EVERYTHING['Standard']['Vagabond Layout']['data']) do
          local nick = v.json:match('"Nickname": "([^"]*)"')
          if nick == nil or rttRelKit().bp[nick] == nil then n = n + 1 end
        end
        return n
    end""")()
    n = rt.eval("function() return #SEEN end")()
    assert n >= want, "the vagabond kit spawned %d of its %d non-marker pieces" % (n, want)
    c = rt.eval("function() return #CARDS end")()
    got = [rt.eval("function() return CARDS[%d] end" % (i + 1))() for i in range(c)]
    assert not got, "a loose card still lands on the vagabond's crafted board: CardID %s" % ", ".join(got)


def t_relationship_markers_follow_the_factions_in_play(src):
    """The vagabond gets one relationship marker per faction actually playing, as it arrives.

    Maintainer, 2026-09-11: "for the vagabond relationship markers could you spawn only the ones from
    factions in the game that have been selected at the moment they are selected and fill the
    rightmost empty position in order."

    The kit laid all ELEVEN out in a fixed row whatever was on the table, so a three-player game got
    eight markers for factions nobody was playing.

    Three things are checked, because each can break on its own:

    WHO. Only a faction that is seated gets a marker, and a vagabond never does -- the kit ships no
    marker for one, so a second vagabond is a faction the first has nothing to describe.

    WHEN. It works in both directions. A faction picked after the vagabond gets its marker then; a
    vagabond picked after everyone else catches up on all of them at once. Only the second of those
    goes through a different branch, and only this test would notice it stop.

    WHERE. Packed against the right end of the row in arrival order, and on the FAR row the offsets
    are mirrored -- the seat's own 180 turns the row and the player together, so +x in the kit's frame
    is the seated player's right at both rows. Getting that wrong would build the row backwards for
    half the table, which is exactly the class of bug a near-seat-only test misses.
    """
    # THE HOOK KNOWS NOTHING OF THE NEW CODE -- it matches the marker's own nickname, which is a
    # property of the blueprint. That is what lets this same test run against the previous build and
    # fail there for the real reason (all eleven, at once, whoever is playing) rather than erroring
    # on a function that does not exist yet.
    hook = """
      REL = {}
      local _s = spawnObjectJSON
      spawnObjectJSON = function(p)
        local nick = (p.json or ''):match('"Nickname": "([^"]*)"')
        if nick ~= nil and nick:match("Relationship$") then
          local q = p.position
          REL[#REL+1] = string.format("%s|%.3f|%.3f", nick, q.x or q[1], q.z or q[3])
        end
        return _s(p)
      end
    """

    def placed(script):
        rt = fresh(src)
        rt.execute(hook + script)
        n = rt.eval("function() return #REL end")()
        out = []
        for i in range(n):
            nick, x, z = rt.eval("function() return REL[%d] end" % (i + 1))().split("|")
            out.append((nick, float(x), float(z)))
        return out

    # the row's own geometry, read off the BLUEPRINT so it is available on either build
    rt = fresh(src)
    slots = rt.eval("""function()
        local t = {}
        for _, v in ipairs(EVERYTHING['Standard']['Vagabond Layout']['data']) do
          local nick = v.json:match('"Nickname": "([^"]*)"')
          if nick ~= nil and nick:match("Relationship$") then
            t[#t+1] = string.format('%.3f', v.move_to[1])
          end
        end
        return table.concat(t, ',')
    end""")()
    slots = [float(v) for v in slots.split(",")]
    assert len(slots) == 11, "the row has %d slots, expected 11" % len(slots)
    right = sorted(slots)[::-1]

    # THE DEFECT ITSELF, stated as plainly as it can be: a vagabond alone on the table is owed no
    # relationship markers at all, because no other faction is playing yet.
    alone = placed("""
      pcall(function() rttSpawnFaction('Vagabond Layout', 0, -20, false) end) FLUSH(400)
    """)
    assert not alone, \
        "the kit put out %d relationship markers for a table with no other faction on it" % len(alone)

    # WHO and WHERE: a vagabond, then three factions picked one at a time
    got = placed("""
      pcall(function() rttPlaceFaction('Tinker', 0, -20, false, 'White', false) end) FLUSH(300)
      pcall(function() rttPlaceFaction('Marquise de Cat', -20, -20, false, 'Orange', false) end) FLUSH(300)
      pcall(function() rttPlaceFaction('Eyrie Dynasties', 20, -20, false, 'Blue', false) end) FLUSH(300)
      pcall(function() rttPlaceFaction('Keepers in Iron', 40, -20, false, 'Yellow', false) end) FLUSH(300)
    """)
    assert [g[0] for g in got] == ["Marquise Relationship", "Eyrie Relationship",
                                   "Keepers Relationship"], \
        "three factions are playing; the markers placed were %s" % [g[0] for g in got]
    for i, (nick, x, _) in enumerate(got):
        assert abs(x - right[i]) < 0.01, \
            "%s took x=%.3f; the %s empty slot is %.3f" % (nick, x, ["1st", "2nd", "3rd"][i], right[i])

    # WHEN, the other way round: the vagabond arrives last and catches up on both
    late = placed("""
      pcall(function() rttPlaceFaction('Marquise de Cat', -20, -20, false, 'Orange', false) end) FLUSH(300)
      pcall(function() rttPlaceFaction('Eyrie Dynasties', 20, -20, false, 'Blue', false) end) FLUSH(300)
      pcall(function() rttPlaceFaction('Tinker', 0, -20, false, 'White', false) end) FLUSH(300)
    """)
    assert [g[0] for g in late] == ["Marquise Relationship", "Eyrie Relationship"], \
        "a vagabond picked last did not catch up: %s" % [g[0] for g in late]

    # WHERE, on the far row: same slots, mirrored through the seat
    far = placed("""
      pcall(function() rttPlaceFaction('Tinker', 0, 20, true, 'White', false) end) FLUSH(300)
      pcall(function() rttPlaceFaction('Marquise de Cat', -20, -20, false, 'Orange', false) end) FLUSH(300)
    """)
    assert len(far) == 1, "the far-row vagabond got %d markers, expected 1" % len(far)
    assert abs(far[0][1] + right[0]) < 0.01, \
        "the far row did not mirror the row: x=%.3f, expected %.3f" % (far[0][1], -right[0])

    # and a second vagabond is not a faction the first has a marker for
    two = placed("""
      pcall(function() rttPlaceFaction('Tinker', 0, -20, false, 'White', false) end) FLUSH(300)
      pcall(function() rttPlaceFaction('Ranger', 30, -20, false, 'Green', false) end) FLUSH(300)
    """)
    assert not two, "a vagabond was given a relationship marker: %s" % [t[0] for t in two]


def t_the_box_score_builds_its_own_face(src):
    """The sheet's UI builds, and what it builds is well-formed markup.

    THE BOX SCORE HAD NO COVERAGE OF ITS OWN UI AT ALL. It is the largest script in the mod -- 3,965
    lines living as a JSON blob inside gen/src/logic.lua -- and the suite only ever loaded the BOARD
    script, so a runtime error anywhere in rebuildUI would have blanked the entire sheet at the table
    with every test still green. It could not even be driven here until now: onLoad registers
    right-click entries and the stub had no addContextMenuItem, so the script threw before emitting a
    single character of UI.

    This asserts the two things that make the difference between a sheet and a blank slab: that
    onLoad and rebuildUI run without error, and that the XML they produce parses. Malformed markup is
    the specific failure that shows up as an empty object in TTS rather than as an error, because the
    XML is handed to a parser that simply gives up.
    """
    sheet = json.loads(re.search(r"RTT_BOXSCORE_JSON = \[====\[(.*?)\]====\]", src, re.S).group(1))
    rt = lupa.LuaRuntime(unpack_returned_tuples=True)
    rt.execute(open(os.path.join(HERE, "tts_stub.lua"), encoding="utf-8").read())
    rt.execute(sheet["LuaScript"].replace("!=", "~="))
    rt.execute("LASTXML = '' self.UI.setXml = function(x) LASTXML = x end")

    err = rt.eval("function() local ok, e = pcall(function() onLoad('') FLUSH(40) rebuildUI() end) "
                  "if ok then return '' end return tostring(e) end")()
    assert err == "", "the box score script fails while building its UI: %s" % err

    xml = rt.eval("LASTXML") or ""
    assert len(xml) > 2000, "the box score emitted almost no UI: %d characters" % len(xml)

    import xml.etree.ElementTree as ET
    try:
        ET.fromstring("<rtt>" + xml + "</rtt>")
    except ET.ParseError as e:
        # show the neighbourhood of the fault, or the message alone is useless on 15KB of markup
        pos = getattr(e, "position", None)
        where = ""
        if pos:
            flat = ("<rtt>" + xml).split("\n")[pos[0] - 1]
            where = "\n    ...%s..." % flat[max(0, pos[1] - 60):pos[1] + 60]
        raise AssertionError("the box score emits markup TTS cannot parse: %s%s" % (e, where))

    # and it is the box score, not some fallback: its title is there
    assert "B O X" in xml, "the sheet built a UI with no title in it"


def t_a_maps_helper_card_ships_where_the_row_puts_it(src):
    """A map's rules card spawns on the helper row, instead of being dragged onto it afterwards.

    Maintainer, 2026-09-11: "the lake helper card spawns first in a spot and then is adjusted. that is
    against the core rules. spawn immediately as it should be", then "mountain helper card as well".

    Winter, Lake and Mountain all ship the SAME card -- CardID 200, a CardCustom at scale 2.55 -- and
    its blueprint put it at z -11.85. rttLayHelperRow then hauled it seven units to the row, and did it
    four times over, at frames 4, 12, 30 and 60, so the card was visibly seen in the wrong place first.
    That is the spawn-then-move the core rule forbids.

    THE CARD'S BOUNDS ARE MEASURED, NOT GUESSED. The row's arithmetic is x = RTT_HELPER_RIGHT - w/2
    and z = RTT_HELPER_BOTTOM + d/2, so the answer depends on the card's real size, which the stub
    cannot know -- it gives every object the same box. The numbers below were read off a real game in
    the maintainer's Saves, where this exact card had been laid by this exact function: it came to rest
    at x -29.31451, z -19.094593, which is w 5.62902 by d 7.810814. Handing the stub those bounds makes
    the harness reproduce the game's own arithmetic.

    What is asserted is the join between the two: take each map's blueprint move_to, put the card
    there the way makeMap does, run the layout, and require that it does not move.
    """
    rt = fresh(src)
    # the card's world position is its move_to for x and z (makeMap scales by 1/15.5 then by 15.5
    # again, so the two cancel) and move_to.y - 0.1 + 11.56 for height
    rows = rt.eval("""function()
        local out = {}
        for _, id in ipairs({ "Winter Map", "Lake Map", "Mountain Map" }) do
          local kit = EVERYTHING['Maps'] and EVERYTHING['Maps'][id]
          for _, v in ipairs((kit and kit['data']) or {}) do
            if v.json:match('"Name": "Card') ~= nil then
              out[#out+1] = string.format("%s|%.6f|%.6f|%.6f", id, v.move_to[1],
                                          v.move_to[2] - 0.1 + 11.56, v.move_to[3])
            end
          end
        end
        return table.concat(out, ";")
    end""")()
    cards = [r.split("|") for r in rows.split(";") if r]
    assert len(cards) == 3, "expected one card on each of the three maps, found %d" % len(cards)

    W, D = 5.62902, 7.810814          # measured, see the docstring
    for name, x, y, z in cards:
        x, y, z = float(x), float(y), float(z)
        rt.execute("""
          for _, o in ipairs(getAllObjects()) do o.destruct() end
          CARD = MKOBJ('%s rules', {%f, %f, %f}, {'Map Object', 'RTT Helper'})
          CARD.__bounds = { size = { x = %f, y = 0.3, z = %f }, center = {x=0,y=0,z=0} }
          rttLayHelperRow()
        """ % (name, x, y, z, W, D))
        gx = rt.eval("function() return CARD.getPosition().x end")()
        gz = rt.eval("function() return CARD.getPosition().z end")()
        assert abs(gx - x) < 0.01 and abs(gz - z) < 0.01, (
            "%s: the card ships at (%.3f, %.3f) and the row moves it to (%.3f, %.3f)"
            % (name, x, z, gx, gz))


def t_a_landmark_card_spawns_on_the_row(src):
    """A landmark's rules card is spawned into the row, not dropped beside it and pulled in.

    Maintainer, 2026-09-11, having had the maps' own card fixed: "continue the rest as well". The
    landmark card is the other half of the same complaint. A Mountain landmark was spawned at a fixed
    RTT_MTN_CARD = (-29.303, -19.899) and rttLayHelperRow then hauled it six units left; the Marsh's
    three towns were dropped into four slots placed by hand and compacted out of them the same way.

    rttHelperSlot runs the row's own arithmetic before the card exists. What is already standing in the
    row is MEASURED, exactly as the layout measures it -- so on the Mountain the map's own card decides
    where the landmark goes. Only the incoming card's own size is a constant, because it does not exist
    yet to be asked, and that was read off a real game: Mousehold at scale 2.2991 came to rest at
    x -35.40778, which makes it 4.9580 by 7.0407.

    `k` cannot be measured either. The Marsh lays three towns in one loop and a spawn callback has not
    run by the time the next slot is asked for, so without it all three would be given the same place.

    The test asserts the join: spawn each card at the slot it is given, run the layout, and require
    that nothing moves.
    """
    MAP_W, MAP_D = 5.62902, 7.810814        # the maps' rules card, measured (see the sibling test)
    TOWN_W, TOWN_D = 4.9580, 7.0407         # a landmark card, measured

    # ASKED OF WHICHEVER FUNCTION THE BUILD HAS, so this same test runs against the previous one and
    # fails there for the real reason -- the card is put somewhere the row does not agree with --
    # rather than erroring on a name that does not exist yet.
    SHIM = """
      function SPOT(k, name)
        if rttHelperSlot ~= nil then return rttHelperSlot(k) end
        return rttHelperSpot(name)
      end
    """

    def place(rt, var, x, y, z, w, d):
        rt.execute("""
          %s = MKOBJ('%s', {%f, %f, %f}, {'Map Object', 'RTT Helper'})
          %s.__bounds = { size = { x = %f, y = 0.3, z = %f }, center = {x=0,y=0,z=0} }
        """ % (var, var, x, y, z, var, w, d))

    def at(rt, var):
        return [float(v) for v in rt.eval(
            "function() local p = %s.getPosition() return string.format('%%.4f|%%.4f', p.x, p.z) end"
            % var)().split("|")]

    # THE MOUNTAIN: the map's own card is already standing there, so the landmark takes second place
    rt = fresh(src)
    rt.execute(SHIM + "for _, o in ipairs(getAllObjects()) do o.destruct() end")
    place(rt, "MAPC", -29.314510, 11.573603, -19.094593, MAP_W, MAP_D)
    slot = [float(v) for v in rt.eval(
        "function() local s = SPOT(1, 'Mousehold') return string.format('%.4f|%.4f|%.4f', s[1], s[2], s[3]) end"
    )().split("|")]
    # the place a real game put this exact card, which is what the arithmetic has to reproduce
    assert abs(slot[0] + 35.40778) < 0.01 and abs(slot[2] + 19.47969) < 0.01, \
        "a Mountain landmark is spawned at (%.4f, %.4f); a real game has it at (-35.408, -19.480)" \
        % (slot[0], slot[2])
    place(rt, "LMC", slot[0], slot[1], slot[2], TOWN_W, TOWN_D)
    rt.execute("rttLayHelperRow()")
    for var, want in (("MAPC", (-29.3145, -19.0946)), ("LMC", (slot[0], slot[2]))):
        got = at(rt, var)
        assert abs(got[0] - want[0]) < 0.01 and abs(got[1] - want[1]) < 0.01, \
            "%s was moved by the row: spawned at (%.4f, %.4f), laid at (%.4f, %.4f)" \
            % (var, want[0], want[1], got[0], got[1])

    # THE MARSH: three towns in one loop, and no map card ahead of them
    rt = fresh(src)
    rt.execute(SHIM + "for _, o in ipairs(getAllObjects()) do o.destruct() end")
    towns = ["Foxburrow", "Rabbit-Town", "Mousehold"]
    slots = []
    for i in (1, 2, 3):
        slots.append([float(v) for v in rt.eval(
            "function() local s = SPOT(%d, %r) return string.format('%%.4f|%%.4f|%%.4f', s[1], s[2], s[3]) end"
            % (i, towns[i - 1]))().split("|")])
    xs = [s[0] for s in slots]
    assert len(set(round(x, 3) for x in xs)) == 3, \
        "the three towns are given the same slot: %s" % [round(x, 3) for x in xs]
    for i, sl in enumerate(slots, 1):
        place(rt, "T%d" % i, sl[0], sl[1], sl[2], TOWN_W, TOWN_D)
    rt.execute("rttLayHelperRow()")
    for i, sl in enumerate(slots, 1):
        got = at(rt, "T%d" % i)
        assert abs(got[0] - sl[0]) < 0.01 and abs(got[1] - sl[2]) < 0.01, \
            "town %d was moved by the row: spawned at (%.4f, %.4f), laid at (%.4f, %.4f)" \
            % (i, sl[0], sl[2], got[0], got[1])


def t_every_faction_gets_a_vp_panel_above_its_crafted_board(src):
    """One VP panel per faction, standing above that faction's Crafted Improvements board.

    Maintainer, 2026-09-11: "on top of every faction crafted improvement I want you to design a new
    object of the width of the crafted improvment", and on the placement: "yes on top with a space
    between the two sma space as between the other boards", and on the width: "outer edge so both
    tools are aligned".

    THE NUMBERS ARE DERIVED, NOT TUNED. The crafted board is a Type-0 Stretch Custom_Tile, whose world
    size is 2*scale by 2*scale*(imgW/imgH) -- so at scale 9.516764 with 740x1955 art it is 7.204507
    across and 19.033528 deep, identically in all THIRTEEN kits (Knaves included; it is not the
    exception it looks like). The panel is that width at the mod's shared UI density, and it sits half
    the board's depth away, plus the gap, plus half its own.

    Four things are asserted, because each fails on its own:
      WHO  - all thirteen kits that carry a crafted board get exactly one panel, and no other kit does.
      WHERE- the panel's x is the board's x and its z is the board's plus RTT_VP_PANEL_DZ.
      WHAT - the panel carries the seat's box-score ROW NAME, which is what its buttons are keyed on.
      CLEAR- nothing the kit actually spawns lands inside the panel's footprint. This one caught a
             real collision: the Twilight Council's retained battle die dc8eb3 sat dead centre of it,
             the only such object in thirteen kits, because every other kit's dice are filtered out.
    """
    rt = fresh(src)
    rt.execute("""
      PANELS = {}
      local _s = spawnObjectJSON
      spawnObjectJSON = function(p)
        if (p.json or ''):find('"Nickname":"VP Panel"', 1, true) then
          local q = p.position
          PANELS[#PANELS+1] = string.format("%.4f|%.4f|%s", q.x or q[1], q.z or q[3],
                              p.json:match('"LuaScriptState":"([^"]*)"') or '')
        end
        return _s(p)
      end
      REPORT = {}
      local kits = {}
      for k in pairs(EVERYTHING['Standard']) do kits[#kits+1] = k end
      table.sort(kits)
      for _, kit in ipairs(kits) do
        local cx, cz
        for _, v in ipairs(EVERYTHING['Standard'][kit]['data']) do
          if v.json:find('"scaleX": 9.516764', 1, true) and v.json:find('"Name": "Custom_Tile"', 1, true) then
            cx, cz = v.move_to[1], v.move_to[3]
          end
        end
        PANELS = {}
        pcall(function() rttSpawnFaction(kit, 0, -20, false) end) FLUSH(400)
        REPORT[#REPORT+1] = string.format("%s|%s|%s|%s", kit,
          (cx ~= nil) and string.format("%.4f|%.4f", cx, cz) or "none|none",
          #PANELS, PANELS[1] or "")
      end
      DZ = RTT_VP_PANEL_DZ
    """)
    dz = rt.eval("DZ")
    n = rt.eval("function() return #REPORT end")()
    withBoard, withPanel = 0, 0
    for i in range(n):
        parts = rt.eval("function() return REPORT[%d] end" % (i + 1))().split("|")
        kit, cx, cz, count = parts[0], parts[1], parts[2], int(parts[3])
        if cx == "none":
            assert count == 0, "%s has no crafted board but got %d VP panel(s)" % (kit, count)
            continue
        withBoard += 1
        assert count == 1, "%s has a crafted board but got %d VP panel(s)" % (kit, count)
        withPanel += 1
        px, pz, row = float(parts[4]), float(parts[5]), parts[6]
        # the seat used above is (0, -20); a kit's move_to IS its world offset from that centre
        assert abs(px - float(cx)) < 0.001, \
            "%s: the panel is at x %.4f, the crafted board at %.4f" % (kit, px, float(cx))
        assert abs(pz - (-20 + float(cz) + dz)) < 0.001, \
            "%s: the panel is at z %.4f, expected %.4f" % (kit, pz, -20 + float(cz) + dz)
        assert row != "", "%s: the panel was spawned without a row name" % kit
    assert withBoard == 13, "expected 13 kits with a crafted board, found %d" % withBoard
    assert withPanel == 13, "only %d of them got a panel" % withPanel

    # every row name the panels carry must be a row the box score actually has
    roster = set(re.findall(r'"([A-Za-z][A-Za-z ]*)"', re.search(
        r"local ROSTER = \{(.*?)\}",
        json.loads(re.search(r"RTT_BOXSCORE_JSON = \[====\[(.*?)\]====\]", src, re.S).group(1))["LuaScript"],
        re.S).group(1)))
    rows = set()
    for i in range(n):
        parts = rt.eval("function() return REPORT[%d] end" % (i + 1))().split("|")
        if len(parts) > 6 and parts[6]:
            rows.add(parts[6])
    assert rows <= roster, "these panels name rows the box score does not have: %s" % sorted(rows - roster)

    # CLEAR: nothing the kits really spawn may sit inside a panel
    clash = rt.eval("""function()
        local PW, PD = 7.195650, 7.842450
        local bad = {}
        for kit, kitdata in pairs(EVERYTHING['Standard']) do
          local cx, cz
          for _, v in ipairs(kitdata['data']) do
            if v.json:find('"scaleX": 9.516764', 1, true) then cx, cz = v.move_to[1], v.move_to[3] end
          end
          if cx then
            for _, v in ipairs(kitdata['data']) do
              local isDice = v.json:find('"Name": "Custom_Dice"', 1, true) ~= nil
              local kept = false
              if isDice then for g in pairs(RTT_KEEP_DICE) do
                if v.json:find('"GUID": "' .. g .. '"', 1, true) then kept = true end end end
              if (not isDice) or kept then
                if math.abs(v.move_to[1] - cx) < PW/2
                   and math.abs(v.move_to[3] - (cz + RTT_VP_PANEL_DZ)) < PD/2 then
                  bad[#bad+1] = kit .. ": " .. (v.json:match('"GUID":%s*"([^"]+)"') or "?")
                end
              end
            end
          end
        end
        return table.concat(bad, ", ")
    end""")()
    assert clash == "", "these land inside a VP panel: %s" % clash


def t_the_vp_panels_buttons_reach_the_rest_of_the_mod(src):
    """The panel is a dumb relay and the board does the work; every refusal says why.

    The panel carries two frozen names -- its handler `vpRelay` and the board's `rttVPClick` -- and
    nothing else, because a panel is destroyed and respawned with its faction and so is frozen at the
    build the game started on, while the board and the sheet are the two scripts
    tools/update_saves.py can still patch in a save that has already been played.

    BOTH CROSS-OBJECT HOPS ARE PROBED FIRST. `obj.call` into a name the target does not define is TTS's
    C# NullReferenceException, which pcall does NOT catch and which takes the calling function with it.
    So the panel checks the board's RTT_VP_API and the board checks the sheet's RTT_NUDGE_API, and an
    older partner is told about rather than called.

    + and - are a WRAPPER over the sheet's existing `nudge`, never a second implementation: every rule
    it has -- clamped to the track, refused while the marker is held, a free sub-row so markers never
    stack -- is inherited. It answers with a sentence when it refuses, because a player at a faction
    board has no sheet in front of them to see why nothing happened.
    """
    rt = fresh(src)
    assert rt.eval("RTT_VP_API") is True, "the board does not advertise RTT_VP_API for the panel to probe"
    rt.execute("""
      SAID = {} CALLS = {} DEALT = {}
      _G.printToColor = function(msg, c) SAID[#SAID+1] = tostring(msg) end
    """)

    def click(setup, id, row="Diaspora"):
        rt.execute("SAID = {} CALLS = {} DEALT = {} " + setup +
                   " rttVPClick({ color = 'Orange', id = %r, row = %r })" % (id, row))
        return (rt.eval("function() return table.concat(SAID, ' | ') end")(),
                rt.eval("function() return table.concat(CALLS, ' | ') end")(),
                rt.eval("function() return table.concat(DEALT, ' | ') end")())

    # nothing on the table: every button explains itself rather than failing silently
    for id in ("vpPlus", "vpDraw", "vpPond"):
        said, _, _ = click("", id)
        assert said != "", "%s says nothing when there is nothing to act on" % id

    rt.execute("""
      SHEET = MKOBJ('Root Box Score', {0,1,0}, {'RTT BoxScore'})
      SHEET.getVar = function(k) if k == 'RTT_NUDGE_API' then return true end end
      SHEET.call = function(n, a) CALLS[#CALLS+1] = n..'('..tostring(a.row)..','..tostring(a.delta)..')' end
    """)
    for id, delta in (("vpPlus", "1"), ("vpMinus", "-1")):
        said, calls, _ = click("", id)
        assert calls == "rttNudge(Diaspora,%s)" % delta, "%s reached the sheet as %r" % (id, calls)
        assert said == "", "%s complained on a good press: %s" % (id, said)

    # a sheet that refuses is relayed verbatim, not swallowed
    said, _, _ = click("SHEET.call = function() return 'held by someone' end", "vpPlus")
    assert "held" in said, "the sheet's reason was not passed on: %r" % said

    # an older sheet is NOT called -- that call would be the uncatchable null
    said, calls, _ = click("SHEET.getVar = function() return nil end "
                           "SHEET.call = function() CALLS[#CALLS+1] = 'CALLED' end", "vpPlus")
    assert calls == "", "the board called a sheet that does not advertise the entry point"
    assert said != "", "it went quiet instead of saying the sheet is too old"

    # DRAW takes the SHARED deck, and a faction's own deck is not it
    said, _, dealt = click("""
      DECK = MKOBJ('the deck', {0,1,0}, {'Deck Object'})
      DECK.name = 'Deck' DECK.getQuantity = function() return 7 end
      DECK.deal = function(n, c) DEALT[#DEALT+1] = 'deck '..tostring(n)..'->'..tostring(c) end
      FAC = MKOBJ('a faction deck', {9,1,9}, {'RTT Faction'})
      FAC.name = 'Deck' FAC.getQuantity = function() return 40 end
      FAC.deal = function() DEALT[#DEALT+1] = 'WRONG DECK' end
    """, "vpDraw")
    assert dealt == "deck 1->Orange", "DRAW dealt %r" % dealt

    # POND draws the pile sitting on the pond, and says so when there is none
    said, _, dealt = click("""
      POND = MKOBJ('The Pond', {5,1,5}, {'RTT Pond'})
    """, "vpPond")
    assert "empty" in said, "an empty pond said %r" % said
    said, _, dealt = click("""
      PILE = MKOBJ('frog discards', {5.2,1,5.1}, {})
      PILE.name = 'Deck'
      PILE.deal = function(n, c) DEALT[#DEALT+1] = 'pond '..tostring(n)..'->'..tostring(c) end
    """, "vpPond")
    assert dealt == "pond 1->Orange", "POND dealt %r" % dealt


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
    ("a warning says what really happens", t_a_warning_describes_what_the_click_really_does),
    ("gizmo follows your last pick",      t_the_gizmo_follows_the_faction_you_last_picked),
    ("panel flashes past 20 minutes",      t_the_panel_flashes_after_twenty_minutes),
    ("box score builds its own face",  t_the_box_score_builds_its_own_face),
    ("map helper card ships on the row", t_a_maps_helper_card_ships_where_the_row_puts_it),
    ("landmark card spawns on the row", t_a_landmark_card_spawns_on_the_row),
    ("every faction gets a VP panel",  t_every_faction_gets_a_vp_panel_above_its_crafted_board),
    ("VP panel buttons reach the mod", t_the_vp_panels_buttons_reach_the_rest_of_the_mod),
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
    ("lizard board follows the wizard",   t_the_lizard_board_follows_the_wizard),
    ("lost souls box is gone",           t_the_lost_souls_box_is_gone_from_the_board),
    ("credits: a column per caption",     t_the_credits_page_gives_every_caption_its_own_column),
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
    ("new game leaves the map alone",       t_a_new_game_leaves_the_map_alone_but_fixes_the_marsh_variant),
    ("fixtures survive a map change",       t_table_fixtures_survive_a_map_change),
    ("every new-game button leaves 5P",     t_every_new_game_button_leaves_the_five_player_marsh),
    ("5-player buttons warn first",         t_the_five_player_buttons_warn_before_wiping),
    ("a dead handle cannot crash us",       t_a_destroyed_object_cannot_crash_the_map_scan),
    ("map buttons warn before wiping",       t_map_buttons_warn_before_wiping),
    ("numpad 0 leaves locked alone",  t_numpad_zero_leaves_locked_pieces_alone),
    ("numpad 2 hands you your token",  t_numpad_two_hands_you_the_token_you_chose),
    ("gizmo default key is numpad 0",         t_gizmo_default_key_is_numpad_zero),
    ("gizmo: warrior to/from supply",         t_gizmo_warrior_to_and_from_supply),
    ("gizmo reads every blueprint",           t_gizmo_reads_every_faction_from_its_blueprint),
    ("gizmo works without the seat map",      t_gizmo_finds_your_supply_without_the_published_map),
    ("UI cleared before destroy",             t_ui_objects_clear_their_xml_before_being_destroyed),
    ("published colour == seated player",     t_published_colour_matches_the_seated_player),
    ("seat colour is the turn order",        t_seat_colour_is_the_turn_order),
    ("turn order clockwise from BR",         t_turn_order_is_clockwise_from_bottom_right),
    ("six seats cannot happen yet",       t_six_seats_cannot_happen_while_the_layout_is_not_clockwise),
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
    ("a seat fact has one writer",        t_a_seat_fact_has_one_writer),
    ("both paths agree on the record",    t_both_setup_paths_leave_the_same_kind_of_record),
    ("the pick survives a reload",        t_the_faction_pick_survives_a_reload),
    ("the draft shuffle is saved",        t_the_drafts_shuffle_is_saved_and_forgotten),
    ("vagabond published under faction",     t_a_vagabond_is_published_under_its_faction_name),
    ("two vagabonds, one marker each",       t_two_vagabonds_get_one_marker_each),
    ("selector icons load with table",     t_every_selector_icon_is_downloaded_with_the_table),
    ("dragon god goes out with lizards",  t_the_dragon_god_goes_out_with_its_faction),
    ("placement ignores board size",       t_placement_never_asks_the_board_how_big_it_is),
    ("send home asks no permission",      t_send_home_asks_no_permission),
    ("numpad 2 lays and lights a warrior", t_numpad_two_lays_a_warrior_down_and_lights_it),
    ("every map locks its ruins",         t_every_map_locks_its_ruins),
    ("keepers spawn where he put them",   t_the_keepers_spawn_where_the_maintainer_put_them),
    ("badger relics draw uniformly",      t_the_badger_relics_are_drawn_uniformly),
    ("cats drop clear of the clearing",   t_the_cats_are_dropped_clear_of_the_clearing),
    ("clearing numbers match the saves",  t_the_clearing_numbers_sit_where_the_saves_put_them),
    ("marsh numbers match his save",      t_the_marsh_numbers_sit_where_his_save_puts_them),
    ("the coffin spawns where he put it", t_the_coffin_spawns_where_he_put_it),
    ("a map cannot be left unlocked",     t_the_map_cannot_be_left_unlocked),
    ("unlock clears the mark only",       t_unlocking_a_prisoner_clears_the_mark_and_leaves_it_lying),
    ("round is 0 until start",            t_the_round_is_zero_until_start_is_pressed),
    ("clear all asks before it clears",   t_clear_all_objects_asks_before_it_clears),
    ("top row is four drafts",            t_the_top_row_is_four_drafts_on_the_map_grid),
    ("More holds the overflow",           t_more_holds_what_the_board_ran_out_of_room_for),
    ("3P draft: 4 militants, no boat",    t_the_three_player_draft_deals_four_militants_and_no_flotilla),
    ("riverboat only puts it out",        t_the_riverboat_button_only_puts_the_flotilla_out),
    ("a prisoner goes pale",              t_a_prisoner_goes_pale),
    ("board shows the build number",      t_the_board_shows_the_build_number),
    ("panel pauses the clock",            t_the_panel_pauses_the_clock),
    ("start names the pass it causes",    t_start_names_the_pass_it_causes),
    ("every seat's board lights up",      t_every_seat_gets_its_faction_buttons),
    ("an empty seat is pickable",         t_an_empty_seats_board_can_be_picked_by_anyone),
    ("a second click touches nothing dead", t_pressing_a_setup_button_twice_touches_nothing_dead),
    ("resync resends what it may",        t_the_resync_sweep_resends_everything_it_may_touch),
    ("resync button asks nothing",        t_the_resync_button_asks_nothing_and_destroys_nothing),
    ("resync survives churn",             t_a_resync_survives_the_table_changing_under_it),
    ("a faction spawns a few at a time",  t_a_faction_spawns_a_few_pieces_at_a_time),
    ("a captain card lands upright",      t_a_captain_card_lands_upright_in_its_slot),
    ("no kit loses pieces to its cb",   t_no_kit_loses_pieces_to_its_own_callback),
    ("vagabond gets no setup card",     t_the_vagabond_gets_no_advanced_setup_card),
    ("rel markers follow the table",    t_relationship_markers_follow_the_factions_in_play),
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
