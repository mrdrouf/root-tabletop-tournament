# Root Tabletop Tournament — to-do

**`WORK_QUEUE.md` is the live queue.** Every open task, every new request and every
"still broken" report lives there. This file holds only the longer-lived design
questions that need a decision or an in-TTS eyeball from the maintainer, plus a
short orientation for whoever picks the project up next.

---

## Orientation (read this before touching anything)

- The build is **three files**: `gen/src/save.json` (scene/blueprint, **CRLF** — always
  read/write it in binary, a text-mode round-trip rewrites all 2381 line endings),
  `gen/src/content.lua` (Root's object DATA) and `gen/src/logic.lua` (**our code — the
  file you edit**). `gen/assemble.py` splices content+logic into the `@@BOARD_LUA@@`
  placeholder. `python3 gen/assemble.py --verify` must stay clean.
- `logic.lua` is **not** the Global script. It is the LuaScript of the **setup board
  object** (`bab7e1`, "Faction Selection"). The mod's Global script is an empty stub.
- Every `m###` in the docs is a **historical label, not a file**. The old `mods/` +
  `build.py` pipeline is real but unreachable; it is preserved as the tag
  `legacy/mods-history` (177 commits). Read an old module with
  `git show legacy/mods-history:mods/m300_duchy_warriors.py`. **The `legacy/*` and
  `discarded/*` tags are LOCAL-ONLY**: they were removed from GitHub on 2026-09-05 because
  that history carried the maintainer's real identity (since rewritten locally so every
  commit is MrDrouf). Never push tags; the `.git/hooks/pre-push` guard blocks them and any
  commit that carries the real name.
- The **box score** lives in the sibling repo `root_boxscore` and is baked into
  `logic.lua` by `root_boxscore/rebake_into_rtt.py`. **Never hand-edit
  `RTT_BOXSCORE_JSON`** — edit `boxscore.lua` and rebake.
- **TTS XmlUI traps, both learned the hard way:** an unsupported attribute makes TTS
  drop the whole element silently (`outline` did this to the credit), and **named XML
  entities can blank a panel — use numeric ones** (`&#38;` `&#183;` `&#8211;`), which
  is why the credit was invisible for weeks.
- Validate before shipping: `tools/lua_chunker.py` (delimiter balance),
  `pip3 install luaparser` then parse the assembled script (normalise TTS's `!=` to
  `~=` first), and `tools/preview_menu.py` to *see* the board without loading TTS.

---

## Needs a decision or an in-TTS eyeball

1. **Mountain middle-clearing suit** — `rttMiddleSuit()` returns nil because no suit
   token could be found in the save (suits look printed), so the Mountain landmark roll
   always yields **Lost City**. Tell me how the middle clearing's suit is encoded (token
   image? nickname?) and rabbit→Rabbit-Town / fox→Foxburrow / mouse→Mousehold gets wired.
2. **Mountain landmark + rules-card positions** — the landmark spawns at the Mousehold
   spot (2.46, 11.66, 6.03); the rules card goes to a best-guess lower-left (−22, −22).
   Confirm or nudge. Only the Lost City *rules card* exists in the mod; the other three
   landmark cards do not, though the landmark models spawn.
3. **Faction-select grid centring** — the 3×4 grid is centred on x=35, not 0, and row 1
   is Marquise/Eyrie/Woodland with Knaves alone in column 4. Knaves is now on-grid at
   x=95, but it still reads as tacked onto the end of a short row. Recentre the grid, or
   move Knaves down beside the other base factions?
4. **README: brief or thorough?** A full every-button README existed and was deliberately
   replaced by the current brief one. Recover the old text with
   `git show legacy/mods-history:README.md` if the thorough version is wanted back.
5. **VP stacking / orientation, Lizard-frog shuffle, Badger relic spots** — eyeball once.

## Investigating

- **Spawn "zoom flash"** — big items (map/deck/board) flash a zoomed-in wrong-scale
  version for a split second before settling. Re-check whether the spawn code rescales
  after spawn (fixable) rather than it being pure TTS texture streaming.
