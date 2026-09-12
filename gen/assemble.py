"""
assemble.py — the RTT generator.

Builds the finished self-contained save from owned source in gen/src/:
    save.json    -- the object layout / blueprint (@@BOARD_LUA@@ and @@GLOBAL_LUA@@ placeholders)
    content.lua  -- Root's object DATA
    logic.lua    -- OUR code (setup, draft, seating, factions, maps, box score)
    observer.lua -- the game recorder, which becomes the save's top-level GLOBAL script
There is no external base and no patch pipeline; the finished save is assembled from scratch.

    python gen/assemble.py            # -> gen/build/Root_Tournament_Edition.json
    python gen/assemble.py --verify   # also assert it matches dist/ (the reference) structurally
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "src")
OUT_DIR = os.path.join(HERE, "build")
OUT = os.path.join(OUT_DIR, "Root_Tournament_Edition.json")
REFERENCE = os.path.join(os.path.dirname(HERE), "dist", "Root_Tournament_Edition.json")


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


def _set_global_lua(save, lua):
    """Fill the save's TOP-LEVEL LuaScript -- the table's Global script -- with the recorder.

    Top level only, deliberately: this is a flat assignment rather than the recursive walk
    _set_board_lua does, because "the Global script" is one field on the save document and an object
    that happened to carry the same placeholder string would be a different thing entirely.

    A missing placeholder is fatal rather than a no-op. The recorder is invisible when it is absent
    -- the table looks identical, every game plays normally, and the only symptom is that no game is
    ever archived -- so a save.json that lost @@GLOBAL_LUA@@ must stop the build, not ship quietly.
    """
    if save.get("LuaScript") != "@@GLOBAL_LUA@@":
        raise SystemExit(
            "[gen] NO @@GLOBAL_LUA@@ IN save.json: the save's top-level LuaScript is %.40r.\n"
            "      That field is where the recorder goes (ARCHIVE.md section 1). Restore the placeholder;\n"
            "      note save.json is CRLF and must be edited in BINARY mode." % (save.get("LuaScript"),))
    save["LuaScript"] = lua


def _global_lua():
    """The Global Lua = the archive recorder (observer.lua), alone.

    It is kept out of the board script on purpose (ARCHIVE.md section 1): a fault in the recorder cannot
    then take the board's 869 KB script down with it, and the mod's diff stays purely additive.
    """
    observer = os.path.join(SRC, "observer.lua")
    if not os.path.exists(observer):
        raise SystemExit(
            "[gen] MISSING gen/src/observer.lua: it is the save's Global script (ARCHIVE.md section 1).\n"
            "      Building without it would ship a save whose Global is the literal string\n"
            "      \"@@GLOBAL_LUA@@\" -- a syntax error on every client at load -- or, worse, an empty\n"
            "      Global that swallows logic.lua's Global.call(\"rttArchiveGame\") hooks in silence.")
    return open(observer, encoding="utf-8").read()


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
    # THE PUMP, NOT A SPAWN SITE. It hands over specs its caller built, callback and all, so the tag
    # lives in the caller's own callback_function -- where this check reads it, in the caller.
    "rttSpawnStaggered",
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

    The table's Global script was TTS's default stub -- an empty onLoad and an empty onUpdate -- for
    this repo's whole history, so neither name was ever defined. It now holds observer.lua, which is
    why build() fills @@GLOBAL_LUA@@ BEFORE calling this: `glob` below has to be the recorder's real
    source, or the archive hooks logic.lua adds (`Global.call("rttArchiveGame", ...)`, ARCHIVE.md
    section 2) would be reported missing against a placeholder string.
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


# Calls that WRITE to an object. The recorder may not contain one, at all, ever.
#
# ARCHIVE.md section 0 constraint 2 is the entire reason the recorder is safe to run during a live
# game: object writes are replicated by TTS to every client, reads are not. A recorder that only reads
# adds zero bytes to the client sync. One that writes is the shape of the bug that broke v1.154, and
# it would do it on a heartbeat's worth of objects at every turn change -- on the host, in the middle
# of somebody's turn, in a mod other people host.
#
# The trailing \w* catches the smooth/variant spellings too, so setPositionSmooth and setRotationSmooth
# cannot slip past the plain names.
OBSERVER_WRITES = ("setLock", "addTag", "removeTag", "setColorTint", "setPosition", "setRotation",
                   "setScale", "spawnObjectJSON", "destruct", "takeObject")


def check_observer_reads_only(observer):
    """Fail the build if gen/src/observer.lua writes to an object.

    This is a BUILD failure and not a test for the same reason check_ui_ids is: the test stub records
    a setLock as cheerfully as it records a getPosition, so a write is green in the suite and only
    shows up as desync at a real table with real players -- which is the one place this project cannot
    afford to find it. Shipping the violation is what does the damage, so the build is where it stops.

    Deliberately dumb: a plain text scan for the call names, tolerating only a Lua LINE comment (via
    _in_comment, same as check_calls), because observer.lua is expected to explain at length WHY it
    never writes and will therefore name these calls in prose. A `--[[ ]]` block comment quoting one
    still trips this -- write that note as line comments instead. A banned name inside a STRING trips
    it too, and that is also on purpose: the check stays a flat rule with no parser to be wrong.
    """
    bad = []
    for m in re.finditer(r"\b((?:%s)\w*)\s*\(" % "|".join(OBSERVER_WRITES), observer):
        if _in_comment(observer, m.start()):
            continue
        # report the line: observer.lua is one long file of handlers and "setLock" alone would send
        # the reader hunting for it
        bad.append("%s (line %d)" % (m.group(1), observer.count("\n", 0, m.start()) + 1))
    if bad:
        raise SystemExit(
            "[gen] OBSERVER WRITES TO AN OBJECT: %s\n"
            "      The recorder READS ONLY (ARCHIVE.md section 0, constraint 2). Object writes are\n"
            "      replicated to every client and are what broke v1.154; reads are not replicated,\n"
            "      which is why recording during a live game costs the table nothing. Get the same\n"
            "      result from a read, or keep the state in the recorder's own log."
            % ", ".join(bad))              # source order, not sorted: read them top-down like the file


def build():
    save = json.load(open(os.path.join(SRC, "save.json"), encoding="utf-8"))
    logic = open(os.path.join(SRC, "logic.lua"), encoding="utf-8").read()
    global_lua = _global_lua()
    check_observer_reads_only(global_lua)
    # Before the checks, not after: check_calls resolves logic.lua's Global.call(...) targets against
    # the save's top-level LuaScript, and it can only do that once the real recorder is sitting there.
    _set_global_lua(save, global_lua)
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
