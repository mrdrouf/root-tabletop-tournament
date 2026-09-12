#!/usr/bin/env python3
"""Push the current build's scripts into the maintainer's existing TTS saves.

Why this exists: a TTS save carries a COPY of every object's script inside it. Rebuilding the mod and
dropping it in the Saves folder only helps a game started FRESH -- open any saved game, or let TTS
autosave and resume, and the old script comes straight back with it. On 2026-09-05, 27 of 28 saves
carried a stale board, and the maintainer had been testing a box-score fix that his save was quietly
reverting.

Only script and UI fields are replaced, so everything else in the save -- table state, piece
positions, and crucially every LuaScriptState (the gizmo's config, the box score's recorded game, and
now the archive recorder's own log) -- is left exactly as it was:

    the save itself     LuaScript  -- the table's Global script, i.e. the archive recorder
    board bab7e1        LuaScript, XmlUI, CustomUIAssets
    "Root Box Score"    LuaScript
    "Turn Panel"        LuaScript
    table surface 4ee1f2 CustomUIAssets

SCOPE: the base RTT save ONLY -- Root_Tournament_Edition.json. Nothing else, by instruction
(2026-09-05, after a first pass rewrote 26 files and a second still covered the autosaves). Autosaves
and named saves are the maintainer's, not this script's. --all is kept for the rare case where he
asks for a sweep, and it is never the default.

Run from the repo root, after a build:  python3 tools/update_saves.py [--dry-run] [--all]
"""
import glob, json, os, re, shutil, sys, time

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUILT = os.path.join(REPO, "dist", "Root_Tournament_Edition.json")
SAVES = os.path.expanduser("~/Library/Tabletop Simulator/Saves")
# NOT inside Saves/: TTS scans that folder, and it must not find our copies
BACKUPS = os.path.expanduser("~/Library/Tabletop Simulator/RTT_save_backups")
KEEP_SETS = 2
BASE_SAVE = "Root_Tournament_Edition.json"   # the only save this touches by default
BOARD = "bab7e1"
# The table surface carries nothing but a list of URLs: the art of the two faction selectors, which
# are spawned mid-game and would otherwise be asking for their icons for the first time at the moment
# TTS draws them -- too late, and the board comes up with no buttons. Its own mesh and transform are
# never touched here; only that list.
SURFACE = "4ee1f2"
BOXSCORE = "Root Box Score"
PANEL    = "Turn Panel"      # spawned from RTT_TURN_PANEL_JSON, same problem as the sheet


def walk(o):
    if isinstance(o, dict):
        yield o
        for v in o.values(): yield from walk(v)
    elif isinstance(o, list):
        for v in o: yield from walk(v)


def read(path):
    return json.loads(open(path, encoding="utf-8", errors="surrogateescape").read())


def current_sources():
    """The Global script, the board, and the box score -- which is NOT a top-level object in the build.

    The mod carries the sheet as a Lua long-bracket string, RTT_BOXSCORE_JSON, and spawns it on
    demand. Looking for a "Root Box Score" object in the build finds nothing, so the first version of
    this script silently updated no box scores at all while reporting success, because the
    "is it current?" check was skipped whenever the source was missing.
    """
    doc = read(BUILT)
    # The table's Global script (gen/src/observer.lua, ARCHIVE.md section 1). It is a field on the save
    # document itself, not on any object, so it is read here by name rather than found by walk().
    # Empty is fatal: writing "" over a save's Global would delete the recorder from the maintainer's
    # own save, which is the exact damage this script exists to undo, only in reverse.
    # NOT `glob`: that is the module imported at the top of this file, and naming a local after it
    # shadowed it -- glob.glob() two functions down then raised "'str' object has no attribute
    # 'glob'" and the script could not deploy at all.
    global_lua = doc.get("LuaScript")
    if not global_lua:
        raise RuntimeError("no top-level LuaScript (Global script) in the build")
    board = next(o for o in walk(doc) if o.get("GUID") == BOARD)
    surface = next((o for o in walk(doc) if o.get("GUID") == SURFACE), None)
    if surface is None or not surface.get("CustomUIAssets"):
        raise RuntimeError("no pre-fetch asset list on the table surface %s in the build" % SURFACE)
    box = next((o for o in walk(doc) if o.get("Nickname") == BOXSCORE), None)
    if box is None:
        m = re.search(r"^RTT_BOXSCORE_JSON = \[====\[(.*?)\]====\]$", board["LuaScript"], re.M | re.S)
        if m:
            box = json.loads(m.group(1))
    if box is None:
        raise RuntimeError("no box score in the build: neither an object nor RTT_BOXSCORE_JSON")
    # THE TURN PANEL HAS THE SAME PROBLEM, and it cost two rounds of "none of the two bugs have been
    # resolved" on 2026-09-07: the panel is spawned from RTT_TURN_PANEL_JSON, so one already sitting on
    # a table keeps whatever script it spawned with, for ever. Rebuilding never reached it -- exactly
    # as it never reached the box score before that case was handled.
    panel = next((o for o in walk(doc) if o.get("Nickname") == PANEL), None)
    if panel is None:
        m = re.search(r"^RTT_TURN_PANEL_JSON = \[====\[(.*?)\]====\]$", board["LuaScript"], re.M | re.S)
        if m:
            panel = json.loads(m.group(1))
    if panel is None:
        raise RuntimeError("no turn panel in the build: neither an object nor RTT_TURN_PANEL_JSON")
    return global_lua, board, box, panel, surface


def update_doc(doc, board, box, panel=None, surface=None, global_lua=None):
    """-> list of what changed. Only ever writes script/UI fields, never a transform or state."""
    changed = []
    # The Global script, on the save document itself. A save made before the recorder existed carries
    # TTS's empty boilerplate there, so resuming it would record nothing and give no sign of it --
    # precisely how a stale board was quietly reverting the box-score fix on 2026-09-05.
    #
    # Top level ONLY, and by name: `walk` would happily hand back an object whose own LuaScript this
    # has no business touching. And LuaScriptState beside it is left alone like every other one --
    # that is the recorder's onSave log, i.e. a game in progress.
    if global_lua is not None and doc.get("LuaScript") != global_lua:
        doc["LuaScript"] = global_lua
        changed.append("global.LuaScript")
    for o in walk(doc):
        if o.get("GUID") == BOARD:
            for k in ("LuaScript", "XmlUI", "CustomUIAssets"):
                if k in board and o.get(k) != board[k]:
                    o[k] = json.loads(json.dumps(board[k]))
                    changed.append("board." + k)
        elif surface is not None and o.get("GUID") == SURFACE:
            if o.get("CustomUIAssets") != surface["CustomUIAssets"]:
                o["CustomUIAssets"] = json.loads(json.dumps(surface["CustomUIAssets"]))
                changed.append("surface.CustomUIAssets")
        elif box is not None and o.get("Nickname") == BOXSCORE:
            if o.get("LuaScript") != box["LuaScript"]:
                o["LuaScript"] = box["LuaScript"]
                changed.append("boxscore.LuaScript")
        elif panel is not None and o.get("Nickname") == PANEL:
            # script ONLY: the maintainer places this panel by hand, so its Transform is his and must
            # survive, and LuaScriptState holds the running clock.
            if o.get("LuaScript") != panel["LuaScript"]:
                o["LuaScript"] = panel["LuaScript"]
                changed.append("panel.LuaScript")
    return changed


def prune_backups():
    sets = sorted(glob.glob(os.path.join(BACKUPS, "*")))
    for old in sets[:-KEEP_SETS]:
        shutil.rmtree(old, ignore_errors=True)


def in_scope(path, every):
    """The base RTT save only, unless --all is passed."""
    return every or os.path.basename(path) == BASE_SAVE


def main():
    dry = "--dry-run" in sys.argv
    every = "--all" in sys.argv
    global_lua, board, box, panel, surface = current_sources()
    print("built board script: %d chars; box score: %s; global: %d chars"
          % (len(board["LuaScript"]), "%d chars" % len(box["LuaScript"]) if box else "not in build",
             len(global_lua)))

    stamp = time.strftime("%Y%m%d-%H%M%S")
    bdir = os.path.join(BACKUPS, stamp)
    touched = skipped = 0

    for path in sorted(glob.glob(os.path.join(SAVES, "*.json")), key=os.path.getmtime, reverse=True):
        name = os.path.basename(path)
        if name == "SaveFileInfos.json":
            continue
        if not in_scope(path, every):
            continue
        try:
            doc = read(path)
        except Exception as e:
            print("  %-30s UNREADABLE (%s)" % (name, str(e)[:50]))
            continue
        if not any(o.get("GUID") == BOARD or o.get("Nickname") == BOXSCORE for o in walk(doc)):
            continue
        changed = update_doc(doc, board, box, panel, surface, global_lua)
        if not changed:
            skipped += 1
            continue
        if dry:
            print("  %-30s would update: %s" % (name, ", ".join(changed)))
            touched += 1
            continue
        body = json.dumps(doc, indent=2, ensure_ascii=False)
        json.loads(body)                       # never write a save we cannot read back
        os.makedirs(bdir, exist_ok=True)
        shutil.copy2(path, os.path.join(bdir, name))
        with open(path, "w", encoding="utf-8", errors="surrogateescape") as fh:
            fh.write(body)
        print("  %-30s updated: %s" % (name, ", ".join(changed)))
        touched += 1

    print("\n%s %d save(s); %d already current%s"
          % ("would update" if dry else "updated", touched, skipped,
             "" if every else "  (%s only; --all for the rest)" % BASE_SAVE))
    if touched and not dry:
        print("backup of the originals: %s" % bdir)
        prune_backups()


if __name__ == "__main__":
    main()
