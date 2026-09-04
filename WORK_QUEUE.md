# RTT Work Queue

Single source of truth for outstanding tasks. Nothing is "done" until it's built, committed, and
the maintainer has confirmed it in TTS. Keep this file live: add every new request here the moment it lands,
tick items only when committed, and re-open anything the maintainer reports still broken.

## Standing rule: this file only shows OPEN work
The maintainer, 2026-09-04: "the work should always be cleaned up, and anything that is done needs to go
in the archive so the work is always clean". Tick an item, then run `python3 tools/queue_archive.py`
before committing -- it moves every `- [x]` into WORK_QUEUE_ARCHIVE.md and drops any section left empty.
The archive is kept rather than deleted because several entries record WHY something is the way it is,
and the root causes of bugs that took more than one attempt.

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
## BLOCKED — need more info from the maintainer

- [ ] **Moles / rats: tools on the side of their board.** The Underground Duchy and the Lord of the
      Hundreds should get their tools placed beside their faction board. BLOCKED: need to know WHICH
      tools (the Duchy has crowns/tunnels, the rats have the Mob Die and the Mini-Mood Manager -- the
      latter already spawns at his saved spot), and WHERE "the side" is. Fastest unblock, the same way
      the Knaves and rats positions were recovered: place them where you want them, save under a real
      name, and say the name -- the positions get read out of the save and baked seat-local.

- [ ] **Gizmo: a variant that also places warriors.** NOTE the first half is already done -- since
      2026-09-04 the Gizmo has no button and no object at all: its script is part of the setup board, so
      NUMPAD 0 (return a hovered component to its supply) and NUMPAD 1 (reassign a destination) work in
      every game with nothing to spawn or toggle. It cannot be turned off.
      BLOCKED on the remaining half: what should the warrior-placing variant DO? Which key, how many
      warriors, taken from where, placed where -- and is it a second behaviour alongside NUMPAD 0 or a
      replacement for it?

## OPEN — new batch (2026-09-04)

- [ ] **Box score reads UPSIDE DOWN under TTS's Alt zoom.** It spawns at rotation {0, 270, 0}
      (rttSpawnBoxScore), which is correct for reading it flat on the table from the maintainer's seat;
      Alt zoom presents it rotated 180 from that. NOT YET DIAGNOSED and I do not have a confident fix:
      TTS's zoom orientation is derived from the object's own transform and is not obviously
      scriptable, so changing the table rotation to please the zoom would break the table reading.
      Investigate whether a different rot combination satisfies both, or whether the sheet's UI can be
      authored 180 off with a compensating transform.

## OPEN — new batch (2026-09-03, from in-TTS testing)

- [ ] **Knaves: do NOT spawn the captain cards that appear on the board** -- they are drafted, so the
      board-spawned copies are duplicates. (Maintainer, 2026-09-04.) rttSpawnFaction already skips the
      12 "Captain - <name>" meeples and the item supply for this faction; the CARDS need the same
      treatment. Check what rttSpawnCaptainsFor / rttPoolCaptains put out versus what the blueprint
      spawns, so the draft keeps working.
