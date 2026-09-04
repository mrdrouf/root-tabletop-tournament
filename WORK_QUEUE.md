# RTT Work Queue

Single source of truth for outstanding tasks. Nothing is "done" until it's built, committed, and
the maintainer has confirmed it in TTS. Keep this file live: add every new request here the moment it lands,
tick items only when committed, and re-open anything the maintainer reports still broken.

## Note for future sessions: the `m###` labels are HISTORY, not files
The `mods/` pipeline was REAL -- `mods/m###_*.py` + `build.py` over a `base/` mod. It is not in the
current history because the repo was RE-ROOTED onto the generator; the old chain survives only as
orphaned objects, now preserved as the tag **`legacy/mods-history`** (177 commits, tip 2026-08-30).
Read an old module with `git show legacy/mods-history:mods/m300_duchy_warriors.py`. The build is three
files -- `gen/src/save.json` (scene/blueprint, with an `@@BOARD_LUA@@` placeholder), `gen/src/content.lua`
(Root's object DATA) and `gen/src/logic.lua` (OUR code, the file you edit); `gen/assemble.py` injects
content+logic into the placeholder. Every `m###` reference in this file, CHANGELOG.md, TODO.md and
README.md names a change that is already BAKED INTO those three files -- do not go looking for a module.

Editing `gen/src/save.json`: it is CRLF. Read/write it in BINARY mode -- a text-mode round-trip in
Python rewrites all 2381 line endings and turns a one-character fix into a 4700-line diff.

## Golden rule (the maintainer, repeated + hardened)
**Fix the BLUEPRINT, never patch at runtime.** No dirty tricks — no spawn-then-move, no
spawn-below-the-table-then-reveal, no runtime tuck. Modify the faction's data so every piece
starts in its final container/position:
  - seat-relative pieces (warriors/buildings by the board): bake move_to (m290/m300/m560/m570).
  - "extra" pieces that belong in supply: MOVE them into the bag's ContainedObjects in the data
    (framework.stow_loose_in_bag) — they spawn inside the bag.
  - map-relative pieces (cats on clearings, The Pond): take from the supply bag / spawn the object
    JSON directly AT the final world spot — never a seat-local default first.

## STRUCTURAL — the pattern behind most of today's bugs (2026-09-04)
The maintainer, after the supporters-hand saga: "this type of bug should give you some insight about
phenomena and problems in the structure of the code." He is right. Nearly every bug fixed today is one
of four structural faults, not an isolated mistake. Fixing these is worth more than fixing instances.

1. **Placement derived from MUTABLE GLOBAL STATE instead of from arguments.**
   `spawnSupportersHand(color)` takes only a colour and reads `Player[color].getHandTransform(1)`. So
   its result depends on WHEN it is called. makeFaction called it before moving hand 1, so the
   supporters hand was built from the player's PREVIOUS seat; the draft path happened to move hand 1
   much earlier, so it worked there. The same shape caused the box score binding rows by hand-zone
   geometry, and my own pin resolving Turns.order[1] through that geometry.
   FIX SHAPE: pass the seat position/rotation in explicitly. A function that is given where the seat is
   cannot be called "too early".

2. **TWO parallel setup paths that must stay in sync and don't share code** (rttSetup vs
   setupFactionBoards). Today alone they diverged on: the teardown tag list, the run-state reset
   (RTT_FAC_TAKEN etc.), the busy-flag release, and the hand-1 ordering above. Each was found separately.
   FIX SHAPE: one `rttNewGame()` and one `rttSpawnFactionAt()` that both paths call.

3. **Non-object state is invisible to teardown.** Teardown destroys objects by tag, but a game also
   leaves: hand-zone transforms (hand 2 stayed wherever the last Alliance put it), Globals
   (RTT_SEAT_POS / RTT_SEAT_COLOR), and module tables (RTT_FAC_TAKEN, RTT_VP_PENDING, RTT_ALLY_SUP_DONE,
   RTT_CAP_SPAWNED). Every one of these had to be remembered by hand, and each forgotten one was a bug.
   FIX SHAPE: a single registry of "things a new game resets", objects and state alike.

4. **Long async chains with no generation token.** ~6-10s of Wait.time/Wait.frames per setup, whose
   callbacks can fire against a later run's state. The busy guard stops a second run STARTING, but a
   chain already in flight is still unguarded.
   FIX SHAPE: rttSetup bumps RTT_RUN_ID; every deferred callback returns early if its captured id is stale.

- [ ] Refactor to (1)+(2)+(3): explicit-argument placement, one shared new-game/spawn path, one reset
      registry. This is the "thorough code cleanup" item made concrete -- do it as the cleanup, not
      separately.
## OPEN — new batch (2026-09-04)

- [x] **Bats keep one die; Rats keep the Mob Die** (DONE 2026-09-04, VERIFY). rttSpawnFaction strips
      every Custom_Dice from a faction spawn, which also removed two dice that ARE faction components.
      Now allowlisted by GUID so the filter cannot catch the wrong one: `dc8eb3` (one of the Twilight
      Council's pair -- its twin 89f44e stays dropped, as asked) and `81f2b2` (the Lord of the Hundreds'
      "Mob Die"). Verified both GUIDs are Custom_Dice inside their own faction blueprints.


- [ ] **Riverfolk: remove the two cards that spawn on both sides of the market.** Maintainer's request,
      2026-09-04. Not yet located in the blueprint -- the Riverfolk entry is at content.lua ~182532 and
      the market cards are not distinguishable by Nickname (the surrounding entries are generic faction
      names), so they will need identifying by CardID / position relative to the market board, the same
      way the Eyrie viziers were found. Then remove them from the faction data (a blueprint fix, not a
      runtime destruct).

- [ ] **Box score reads UPSIDE DOWN under TTS's Alt zoom.** It spawns at rotation {0, 270, 0}
      (rttSpawnBoxScore), which is correct for reading it flat on the table from the maintainer's seat;
      Alt zoom presents it rotated 180 from that. NOT YET DIAGNOSED and I do not have a confident fix:
      TTS's zoom orientation is derived from the object's own transform and is not obviously
      scriptable, so changing the table rotation to please the zoom would break the table reading.
      Investigate whether a different rot combination satisfies both, or whether the sheet's UI can be
      authored 180 off with a compensating transform.

## OPEN — new batch (2026-09-03, from in-TTS testing)

- [ ] **Marsh landmarks must never be ADJACENT** (the maintainer: "important fix", "big update; hard
      to make it work"). `rttMarshPlan5P` shuffles the 15 clearing positions and takes the FIRST 3 as
      town landmarks (gen/src/logic.lua, `rttShuffleList(clearings)` then `for i = 1, 3`), with NO
      adjacency constraint -- so two towns can land next to each other, which the rules forbid.
      THE DATA EXISTS: `root_engine/maps_data/marsh.json` has a clean `adjacency` dict for all 15
      clearings, e.g. "1": [5,10,11] ... "14": [9,10,11,13]. Also `marsh_geometry.json` has
      `clearings_uv`.
      THE HARD PART (why this is a big update): RTT identifies clearings by WORLD COORDINATES
      (RTT_MARSH_SUIT9 + RTT_MARSH up/down pairs), not by clearing NUMBER, so there is no way today to
      ask "is 7 adjacent to 3". Needs a coordinate -> clearing-number mapping, probably by fitting
      RTT's positions against marsh_geometry.json's clearings_uv, then a rejection/backtracking pick
      that draws 3 pairwise non-adjacent clearings. Bake the mapping as a constant; do not compute it
      at runtime. CHECK the 4-player Marsh flood pairs too, and whether other maps place landmarks.
