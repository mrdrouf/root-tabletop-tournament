# RTT generator (`gen/`) — the source of truth

The mod is **built from this code**, not from the base game + patches. Everything it needs is owned here.

    python gen/assemble.py            # -> gen/build/Root_Tournament_Edition.json  (the finished save)
    python gen/assemble.py --verify   # also assert it matches dist/ (the shipped reference)

## Source (`gen/src/`)
- **`save.json`** — the scene: table, hand zones, object layout / blueprint, save metadata. Two Lua
  scripts are injected at assemble time: the setup board's (`@@BOARD_LUA@@`) and the save's own
  top-level Global script (`@@GLOBAL_LUA@@`).
- **`content.lua`** — Root's object DATA (the 12 factions, 6 maps, decks, landmarks, tools we use).
- **`logic.lua`** — OUR CODE: the setup board, draft & seating, faction setup, maps, box score, plus
  the RTT constants/tables. **This is the file you edit.**
- **`observer.lua`** — the game archive: records what moves and POSTs one document when EXPORT is
  pressed. It is the **Global** script, not part of the board's, deliberately — they are separate
  script environments in TTS, so a fault here cannot take `logic.lua` down with it. Ships inert
  (`OBS_ENABLED = false`). See **[`../ARCHIVE.md`](../ARCHIVE.md)**.

## Build
`assemble.py` reads `save.json`, injects `content.lua + logic.lua` as the board Lua and
`observer.lua` as the Global script, and writes the finished self-contained save to `gen/build/`
(copy it to `dist/` and your TTS `Saves/` to play).
There is no external base and no patch pipeline — the whole save is assembled from scratch, so GitHub
holds both the finished one-file product (`dist/`) and everything needed to rebuild it.

`tools/lua_chunker.py` is a helper that validates the board Lua is balanced (used when editing).
