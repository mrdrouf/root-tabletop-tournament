"""
assemble.py — the RTT generator.

Builds the finished self-contained save from owned source in gen/src/:
    save.json    -- the object layout / blueprint (with an @@BOARD_LUA@@ placeholder)
    content.lua  -- Root's object DATA
    logic.lua    -- OUR code (setup, draft, seating, factions, maps, box score)
There is no external base and no patch pipeline; the finished save is assembled from scratch.

    python gen/assemble.py            # -> gen/build/Root_Tabletop_Tournament.json
    python gen/assemble.py --verify   # also assert it matches dist/ (the reference) structurally
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "src")
OUT_DIR = os.path.join(HERE, "build")
OUT = os.path.join(OUT_DIR, "Root_Tabletop_Tournament.json")
REFERENCE = os.path.join(os.path.dirname(HERE), "dist", "Root_Tabletop_Tournament.json")


def _set_board_lua(objs, lua):
    for o in objs:
        if o.get("LuaScript") == "@@BOARD_LUA@@":
            o["LuaScript"] = lua
        _set_board_lua(o.get("ContainedObjects", []) or [], lua)


def _board_lua():
    """The board Lua = Root's object DATA (content.lua) + OUR CODE (logic.lua)."""
    content = os.path.join(SRC, "content.lua")
    logic = os.path.join(SRC, "logic.lua")
    return open(content, encoding="utf-8").read() + open(logic, encoding="utf-8").read()


# Functions that spawn objects but legitimately do not tag them for faction teardown.
# Everything else that calls takeObject/spawnObjectJSON MUST tag (addTag/setTags) or track
# (RTT_SPAWNED), or a new game cannot clear what it left behind. This check exists because that class
# of bug is invisible by construction -- the teardown code looks correct while an untagged spawn simply
# never appears to it -- and it shipped four separate times (pond, Lizard Wizard, Marquise cats,
# Alliance supporters), each found only when the maintainer reported it in TTS.
UNTAGGED_SPAWN_OK = {
    "makeFaction",                  # delegates to rttPlaceFaction, which tags in rttSpawnFaction's callback
    "makeTool",                     # tools are meant to persist across games, not be torn down
    "rttDealOrderCards",            # deals from the order deck, whose GUID rttDealOrder puts in RTT_SPAWNED
    "spawnDraftFaction",            # base-mod leftovers; candidates for removal in the cleanup
    "spawnTournamentDraftFaction",
    "rttSpawnHootDraft",           # a reference aid like the other tools: survives a new game
    "rttRemoveFrogsFromDeck",       # takes frog cards OUT of the deck and destructs them on arrival
}


def check_spawn_tagging(logic):
    """Fail the build if a function spawns objects without tagging or tracking them."""
    fns = [(m.group(1), m.start()) for m in re.finditer(r"^function\s+([A-Za-z_][\w]*)\s*\(", logic, re.M)]
    fns.append(("<eof>", len(logic)))
    bad = []
    for i in range(len(fns) - 1):
        name, a = fns[i]
        body = logic[a:fns[i + 1][1]]
        if not re.search(r"\b(takeObject|spawnObjectJSON)\s*\(", body):
            continue
        if re.search(r"addTag\s*\(|setTags\s*\(|RTT_SPAWNED\[", body):
            continue
        if name in UNTAGGED_SPAWN_OK:
            continue
        bad.append(name)
    if bad:
        raise SystemExit(
            "[gen] UNTAGGED SPAWN: %s spawn object(s) without addTag/setTags/RTT_SPAWNED.\n"
            "      A new game clears by tag, so anything untagged survives into the next game.\n"
            "      Tag it (usually addTag(\"RTT Faction\")), or add it to UNTAGGED_SPAWN_OK in\n"
            "      gen/assemble.py with a reason." % ", ".join(sorted(bad)))


def _in_comment(src, pos):
    """True if `pos` sits after a `--` on its own line -- i.e. inside a Lua line comment.

    The checks below scan the board script as text, and this file is heavily commented: a comment
    that QUOTES the bad call it is warning about would otherwise trip the very check it documents.
    """
    line_start = src.rfind("\n", 0, pos) + 1
    dash = src.find("--", line_start)
    return dash != -1 and dash < pos


# Ids that are built at runtime, or belong to an object whose XML this check cannot see. Keep this
# list empty if you can: every entry is a place the check has been told to look away.
UI_ID_OK = set()


def check_ui_ids(logic, save):
    """Fail the build if the board drives a UI element that does not exist.

    `UI.setAttribute` on an id the target's XML does not declare is a NULL on TTS's side --
    "Lua Error: Object reference not set to an instance of an object" -- and it takes the rest of the
    calling function with it. It cost a week: the map/deck pick was deleted from the selector's
    blueprint on 2026-09-07 and three of the four lines that drove it went with it. The fourth sat at
    the top of rttShowFactions's per-seat loop, so from that day every draft lit ONE seat's board and
    threw before reaching the rest. Maintainer, 2026-09-10: "cannot spawn a second faction after a
    draft."

    Nothing in the test suite could see it -- the stub's UI records whatever you set, so a bogus id is
    a no-op there and green all the way. This is the check that would have caught it, and it is a
    BUILD failure rather than a test because shipping it is what does the damage.
    """
    # the board is the object the assembler just put the script into -- found the same way, so the
    # two can never disagree about which object this is
    def find(objs):
        for o in objs:
            if o.get("LuaScript") == "@@BOARD_LUA@@":
                return o
            got = find(o.get("ContainedObjects", []) or [])
            if got is not None:
                return got
        return None
    board = find(save["ObjectStates"])
    if board is None:
        return                                  # no board in this save: nothing to check
    ids = re.compile(r'\bid\s*=\s*"([^"]+)"')
    own = set(ids.findall(board.get("XmlUI") or ""))
    # the selector boards carry their own XML, embedded in the board script as JSON literals
    spawned = set()
    for m in re.finditer(r'^([A-Z_]+_JSON)\s*=\s*\[===\[(.*?)\]===\]', logic, re.S | re.M):
        try:
            spawned |= set(ids.findall(json.loads(m.group(2)).get("XmlUI") or ""))
        except ValueError:
            continue
    bad = []
    # a literal id, and only a literal: "rttFac" .. i is built at runtime and is not one
    for m in re.finditer(r'\b(\w+)\.UI\.(?:setAttribute|setAttributes|setValue|show|hide)'
                         r'\s*\(\s*"([^"]+)"\s*,', logic):
        var, name = m.group(1), m.group(2)
        if name in UI_ID_OK or _in_comment(logic, m.start()):
            continue
        known = own if var == "self" else (own | spawned)
        if name not in known:
            bad.append("%s.UI...(%r)" % (var, name))
    if bad:
        raise SystemExit(
            "[gen] UI ID NOT IN ANY XML: %s\n"
            "      setAttribute on an id that does not exist is a TTS null and aborts the rest of the\n"
            "      function. Add the element, drop the call, or list the id in UI_ID_OK with a reason."
            % ", ".join(sorted(set(bad))))


# Functions called across a script boundary that this check cannot resolve. Keep it empty if you can.
CALL_TARGET_OK = set()


def check_calls(logic, save):
    """Fail the build if the board calls a function the target script does not define.

    `Global.call("fn")` or `obj.call("fn")` where the target has no such function is the same TTS null
    as a bad UI id -- "Object reference not set to an instance of an object" -- and it aborts the rest
    of the calling function. Two of them shipped in this repo from the day it was created, both
    inherited from the base mod and never ported:

        deleteThis()   Global.call('ImGone', {self})     -- so the board's X button threw and then did
                                                            NOT reach its own self.destruct()
        makeFaction()  Global.call("spawned", {character}) -- `character` is not even assigned; the
                                                            faction spawned and everything after this
                                                            line was skipped

    The table's Global script is TTS's default stub: an empty onLoad and an empty onUpdate. It has
    never defined either name in this repo's history.
    """
    board = None
    stack = list(save.get("ObjectStates") or [])
    while stack:
        o = stack.pop()
        if not isinstance(o, dict):
            continue
        if o.get("LuaScript") == "@@BOARD_LUA@@":
            board = o
            break
        stack.extend([c for c in (o.get("ContainedObjects") or []) if isinstance(c, dict)])
    glob = save.get("LuaScript") or ""

    def defines(src, fn):
        return re.search(r"function\s+" + re.escape(fn) + r"\s*\(", src or "") is not None

    # every script this board can be calling into: its own, and each blueprint it carries
    others = [logic]
    for m in re.finditer(r'^([A-Z_]+_JSON)\s*=\s*\[=*\[(.*?)\]=*\]', logic, re.S | re.M):
        try:
            others.append(json.loads(m.group(2)).get("LuaScript") or "")
        except ValueError:
            continue
    bad = []
    quoted = re.compile(r"""\b(\w+)\.call\s*\(\s*(['"])([^'"]+)\2""")
    for m in quoted.finditer(logic):
        var, fn = m.group(1), m.group(3)
        if fn in CALL_TARGET_OK or _in_comment(logic, m.start()):
            continue
        if var == "Global":
            if not defines(glob, fn):
                bad.append("Global.call(%r) -- the table's Global script has no such function" % fn)
        elif not any(defines(src, fn) for src in others):
            bad.append("%s.call(%r) -- no script in this mod defines it" % (var, fn))
    if bad:
        raise SystemExit(
            "[gen] CALL TARGET MISSING: %s\n"
            "      obj.call/Global.call into a function that does not exist is a TTS null and aborts\n"
            "      the rest of the calling function. Define it, drop the call, or list the name in\n"
            "      CALL_TARGET_OK with a reason." % "; ".join(sorted(set(bad))))


def build():
    save = json.load(open(os.path.join(SRC, "save.json"), encoding="utf-8"))
    logic = open(os.path.join(SRC, "logic.lua"), encoding="utf-8").read()
    check_spawn_tagging(logic)
    check_ui_ids(logic, save)
    check_calls(logic, save)
    board_lua = _board_lua()
    _set_board_lua(save["ObjectStates"], board_lua)
    os.makedirs(OUT_DIR, exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="") as f:
        json.dump(save, f, ensure_ascii=False)
    return save


def main():
    save = build()
    print("[gen] assembled -> %s" % OUT)
    if "--verify" in sys.argv:
        ref = json.load(open(REFERENCE, encoding="utf-8"))
        assert save == ref, "MISMATCH: generator output != dist/ reference"
        print("[gen] VERIFY OK: output structurally identical to dist/ reference")


if __name__ == "__main__":
    main()
