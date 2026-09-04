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


- [x] **Riverfolk: the two decks flanking the market removed** (DONE 2026-09-04, VERIFY). Maintainer
      confirmed these were the ones: the 3-card deck on the left (aafc2c, board-local x -19.46) and the
      8-card deck on the right (2a85cc, x +16.85), either side of the market tile at x -1.34. Both
      entries deleted from EVERYTHING['Standard']['Riverfolk Company'] -- 27 entries left, 0 decks.
      The same GUIDs survive in EVERYTHING['Official Bots']['Riverfolk Robots'], which is a different
      faction and deliberately untouched.

- [x] **Knaves: crafted board, Advanced Setup card and captains board repositioned** (DONE 2026-09-04,
      VERIFY). Recovered from his save "knaves" (TS_Save_21), seat 2, near row.
      Crafted improvement board eb37e6: move_to z -4.6847 -> -4.2552 (x -19.800 -> -19.7606).
      Advanced Setup card e88b64: move_to z -4.6847 -> **-1.3593** -- it had moved 3.3 units up the
      board, the only large change of the three. Both live in the Knaves blueprint only, so no other
      faction's crafted board is affected.
      Captains board: solved from where he left it relative to the Knaves RULES board (the anchor
      rttSpawnCaptainsFor actually uses), giving RTT_CAP_OFF_X -15.844 -> -15.6676 and
      RTT_CAP_OFF_Z -4.801 -> -4.5206.

- [x] **Mini-Mood Manager spawns with the rats; its button removed** (DONE 2026-09-04, VERIFY).
      Layout recovered from his save "rats" (TS_Save_19): the tool is 9 objects (board tile + 8 mood
      cards), stored as seat-local offsets in the tool's own blueprint order so it mirrors for a
      far-side seat. Dispatched from rttFactionExtras for Lord of the Hundreds, tagged RTT Faction so
      teardown clears it. Button deleted from the setup board.


- [ ] **Box score reads UPSIDE DOWN under TTS's Alt zoom.** It spawns at rotation {0, 270, 0}
      (rttSpawnBoxScore), which is correct for reading it flat on the table from the maintainer's seat;
      Alt zoom presents it rotated 180 from that. NOT YET DIAGNOSED and I do not have a confident fix:
      TTS's zoom orientation is derived from the object's own transform and is not obviously
      scriptable, so changing the table rotation to please the zoom would break the table reading.
      Investigate whether a different rot combination satisfies both, or whether the sheet's UI can be
      authored 180 off with a compensating transform.

## OPEN — new batch (2026-09-03, from in-TTS testing)

- [x] **Marsh: suit-driven towns, never adjacent, uniform** (DONE 2026-09-04, VERIFY). The maintainer's
      rule: the Marsh has 15 clearings, FIVE of each suit, and the box has 12 markers, FOUR of each,
      because exactly one clearing per suit becomes that suit's TOWN. So: shuffle the 15 clearings and
      deal 5 fox / 5 rabbit / 5 mouse; take one clearing of each suit as its town (Foxburrow on a fox
      clearing, Rabbit-Town on a rabbit one, Mousehold on a mouse one); the only constraint is that no
      two towns are adjacent; the other 12 keep their drafted suit and take a marker OF THAT SUIT --
      which lands exactly on the 4/4/4 the map has.
      My first version was WRONG in a way the maintainer spotted: it chose three arbitrary clearings as
      towns and dropped the 12 markers on whatever was left, so a town could sit on a clearing of the
      wrong suit and the suits were not 5/5/5.
      Marker suits are read from their mesh textures (RTT_SUIT_TEX) -- identified by downloading the
      three textures and looking at them: fox face on red, rabbit ears on yellow, mouse on orange.
      The town draw is EXACTLY UNIFORM: only 5x5x5 = 125 candidate triples, so the legal ones are
      enumerated and one is drawn at random, rather than picking suit-by-suit (which biases, since an
      early pick changes what is legal later).
      PROVEN over 200,000 simulated setups: 0 adjacent towns, 0 towns on a wrong-suit clearing,
      leftovers always 4/4/4, zero reshuffles needed. (Per-clearing town frequency spreads 32k-46k
      around 40k -- that is inherent to uniformity over valid CONFIGURATIONS: a clearing with fewer
      neighbours belongs to more legal triples. Rejection sampling gives the identical distribution.)

- [x] **Battle mat on every map; its button removed** (DONE 2026-09-04, VERIFY). It only ever spawned
      from the draft's rttPlaceMap, so the map BUTTONS (which call makeMap directly) never got one.
      Moved into makeMap; still tagged "Map Object" so removeMapItems clears the previous one and there
      is never a second. Button deleted.

- [ ] **Knaves: do NOT spawn the captain cards that appear on the board** -- they are drafted, so the
      board-spawned copies are duplicates. (Maintainer, 2026-09-04.) rttSpawnFaction already skips the
      12 "Captain - <name>" meeples and the item supply for this faction; the CARDS need the same
      treatment. Check what rttSpawnCaptainsFor / rttPoolCaptains put out versus what the blueprint
      spawns, so the draft keeps working.
