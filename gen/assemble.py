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
