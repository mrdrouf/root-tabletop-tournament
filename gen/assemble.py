"""
assemble.py — the RTT generator (identity stage).

Builds the finished self-contained save from owned source in gen/src/ — no external base, no
patch pipeline, nothing removed at runtime. Right now it reassembles the mod exactly (identity
stage, proving the generator owns and reproduces every byte); the board Lua is then split into
clean modules and the bloat/dead code is simply never emitted (subtractive-by-omission).

    python gen/assemble.py            # -> gen/build/Root_Tabletop_Tournament.json
    python gen/assemble.py --verify   # also assert it matches dist/ (the reference) structurally
"""
import json
import os
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
    """The board Lua, from the most-modular source available.
      content.lua + logic.lua   -> Root's object DATA (content) + OUR CODE (logic)   [preferred]
      board.clean.lua           -> the cleaned single file
      board.lua                 -> the identity original (for --identity/--verify)
    """
    content = os.path.join(SRC, "content.lua")
    logic = os.path.join(SRC, "logic.lua")
    clean = os.path.join(SRC, "board.clean.lua")
    identity = "--identity" in sys.argv
    if not identity and os.path.exists(content) and os.path.exists(logic):
        return open(content, encoding="utf-8").read() + open(logic, encoding="utf-8").read()
    if not identity and os.path.exists(clean):
        return open(clean, encoding="utf-8").read()
    return open(os.path.join(SRC, "board.lua"), encoding="utf-8").read()


def build():
    save = json.load(open(os.path.join(SRC, "save.json"), encoding="utf-8"))
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
