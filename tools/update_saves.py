#!/usr/bin/env python3
"""Push the current build's scripts into the maintainer's existing TTS saves.

Why this exists: a TTS save carries a COPY of every object's script inside it. Rebuilding the mod and
dropping it in the Saves folder only helps a game started FRESH -- open any saved game, or let TTS
autosave and resume, and the old script comes straight back with it. On 2026-09-05, 27 of 28 saves
carried a stale board, and the maintainer had been testing a box-score fix that his save was quietly
reverting.

Only three fields are replaced, on two objects, so everything else in the save -- table state, piece
positions, and crucially every LuaScriptState (the gizmo's config, the box score's recorded game) --
is left exactly as it was:

    board bab7e1        LuaScript, XmlUI, CustomUIAssets
    "Root Box Score"    LuaScript

Run from the repo root, after a build:  python3 tools/update_saves.py [--dry-run]
"""
import glob, json, os, re, shutil, sys, time

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUILT = os.path.join(REPO, "dist", "Root_Tabletop_Tournament.json")
SAVES = os.path.expanduser("~/Library/Tabletop Simulator/Saves")
# NOT inside Saves/: TTS scans that folder, and it must not find our copies
BACKUPS = os.path.expanduser("~/Library/Tabletop Simulator/RTT_save_backups")
KEEP_SETS = 2
BOARD = "bab7e1"
BOXSCORE = "Root Box Score"


def walk(o):
    if isinstance(o, dict):
        yield o
        for v in o.values(): yield from walk(v)
    elif isinstance(o, list):
        for v in o: yield from walk(v)


def read(path):
    return json.loads(open(path, encoding="utf-8", errors="surrogateescape").read())


def current_sources():
    """The board, and the box score -- which is NOT a top-level object in the build.

    The mod carries the sheet as a Lua long-bracket string, RTT_BOXSCORE_JSON, and spawns it on
    demand. Looking for a "Root Box Score" object in the build finds nothing, so the first version of
    this script silently updated no box scores at all while reporting success, because the
    "is it current?" check was skipped whenever the source was missing.
    """
    doc = read(BUILT)
    board = next(o for o in walk(doc) if o.get("GUID") == BOARD)
    box = next((o for o in walk(doc) if o.get("Nickname") == BOXSCORE), None)
    if box is None:
        m = re.search(r"^RTT_BOXSCORE_JSON = \[====\[(.*?)\]====\]$", board["LuaScript"], re.M | re.S)
        if m:
            box = json.loads(m.group(1))
    if box is None:
        raise RuntimeError("no box score in the build: neither an object nor RTT_BOXSCORE_JSON")
    return board, box


def update_doc(doc, board, box):
    """-> list of what changed. Only ever writes the three script/UI fields."""
    changed = []
    for o in walk(doc):
        if o.get("GUID") == BOARD:
            for k in ("LuaScript", "XmlUI", "CustomUIAssets"):
                if k in board and o.get(k) != board[k]:
                    o[k] = json.loads(json.dumps(board[k]))
                    changed.append("board." + k)
        elif box is not None and o.get("Nickname") == BOXSCORE:
            if o.get("LuaScript") != box["LuaScript"]:
                o["LuaScript"] = box["LuaScript"]
                changed.append("boxscore.LuaScript")
    return changed


def prune_backups():
    sets = sorted(glob.glob(os.path.join(BACKUPS, "*")))
    for old in sets[:-KEEP_SETS]:
        shutil.rmtree(old, ignore_errors=True)


def main():
    dry = "--dry-run" in sys.argv
    board, box = current_sources()
    print("built board script: %d chars; box score: %s"
          % (len(board["LuaScript"]), "%d chars" % len(box["LuaScript"]) if box else "not in build"))

    stamp = time.strftime("%Y%m%d-%H%M%S")
    bdir = os.path.join(BACKUPS, stamp)
    touched = skipped = 0

    for path in sorted(glob.glob(os.path.join(SAVES, "*.json")), key=os.path.getmtime, reverse=True):
        name = os.path.basename(path)
        if name == "SaveFileInfos.json":
            continue
        try:
            doc = read(path)
        except Exception as e:
            print("  %-30s UNREADABLE (%s)" % (name, str(e)[:50]))
            continue
        if not any(o.get("GUID") == BOARD or o.get("Nickname") == BOXSCORE for o in walk(doc)):
            continue
        changed = update_doc(doc, board, box)
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

    print("\n%s %d save(s); %d already current" % ("would update" if dry else "updated", touched, skipped))
    if touched and not dry:
        print("backup of the originals: %s" % bdir)
        prune_backups()


if __name__ == "__main__":
    main()
