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


def build():
    save = json.load(open(os.path.join(SRC, "save.json"), encoding="utf-8"))
    # prefer the CLEAN board Lua (bloat + dead code omitted, gen/clean.py) once it exists; the
    # identity board.lua stays as the reproducibility reference for --verify.
    clean = os.path.join(SRC, "board.clean.lua")
    src_lua = clean if ("--identity" not in sys.argv and os.path.exists(clean)) else os.path.join(SRC, "board.lua")
    board_lua = open(src_lua, encoding="utf-8").read()
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
