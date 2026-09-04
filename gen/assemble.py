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


def build():
    save = json.load(open(os.path.join(SRC, "save.json"), encoding="utf-8"))
    check_spawn_tagging(open(os.path.join(SRC, "logic.lua"), encoding="utf-8").read())
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
