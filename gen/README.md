# RTT generator (`gen/`) — the source of truth

The mod is **built from this code**, not from the base game + patches. Everything it needs is owned here.

    python gen/assemble.py            # -> gen/build/Root_Tabletop_Tournament.json  (the finished save)
    python gen/assemble.py --verify   # assert byte-identity to the identity reference

## Source (`gen/src/`)
- **`content.lua`** — Root's object DATA (the 12 factions, 6 maps, decks, landmarks, tools we use). ~84%.
- **`logic.lua`**   — OUR CODE: the setup board, draft & seating, faction setup, maps, box score, plus
  the RTT constants/tables. This is the file you edit. ~16%.
- `save.json` — the scene/table/hand-zones + save metadata (the board's Lua is injected at assemble).
- `board.lua` — the identity original (bloat+dead still in), kept only for `--verify`.

## How it was cleaned (`gen/clean.py`, `tools/lua_chunker.py`)
Started from the working mod, then **omitted** (never emitted) 109 dead functions + unused data
(bots/hirelings/fan-factions/scenarios/adset) — 19.3% smaller — behind layered safety: reachability
across every object's Lua, self-consistency, the build's dangling-ref oracle, a category-init guard,
and a no-dynamic-dispatch check. Nothing is "removed from a base"; junk is simply not there.

## Legacy
The old `base/` + `mods/` + `build.py` pipeline is kept for history/reference. It is no longer the
build path — edits go in `gen/src/logic.lua` (or `content.lua`), then `python gen/assemble.py`.
