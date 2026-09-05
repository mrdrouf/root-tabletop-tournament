# RTT Work Queue

Single source of truth for outstanding tasks. Nothing is "done" until it's built, committed, and
the maintainer has confirmed it in TTS. Keep this file live: add every new request here the moment it lands,
tick items only when committed, and re-open anything the maintainer reports still broken.

## Standing rule: work on MAIN
From 2026-09-04 the working branch is **main**, not rtt-live ("we should be working in the main
branch"). main and rtt-live were fast-forwarded to the same commit; rtt-live is left pointing there so
any sync script still aimed at it keeps working, but it is no longer where work lands. Build, commit and
push on main; the public README download link points at main, so a build is only really shipped once
main has it.

## Standing rule: update the maintainer's SAVES, not just the build

A TTS save carries a COPY of every object's script. Dropping a fresh build into the Saves folder only
helps a game started from scratch: open a saved game, or let TTS autosave and resume, and the old
script comes back with it. On 2026-09-05 this bit for real -- 27 of 28 saves were stale, and he spent
a round reporting a box-score fix as broken while his save was silently reverting it.

So after every build, run BOTH:

    cp dist/Root_Tabletop_Tournament.json ~/Library/Tabletop\ Simulator/Saves/
    python3 tools/update_saves.py

update_saves.py rewrites only three fields on two objects (board bab7e1's LuaScript/XmlUI/
CustomUIAssets, and any "Root Box Score" LuaScript), so table state and every LuaScriptState -- the
gizmo config, the box score's recorded game -- survive untouched. Originals are backed up outside the
Saves folder, last two sets kept.

SCOPE: `Root_Tabletop_Tournament.json` ONLY. The maintainer said so plainly after a first pass
rewrote 26 files and a second still swept the autosaves. His saves are his. `--all` exists for a
sweep he explicitly asks for; it is never the default. NOTE the consequence, which is his to manage,
not something to route around: resuming from an autosave still restores the script stored in it.

## Seat identity is wrong (tester report, 2026-09-05) -- NOTHING FIXED YET

Zaandaa, mid-tournament: "it's assuming player 4 is player 3 since they were able to spawn p3
warriors with 0", "the box score skipped or omitted a number", "it tracked things weirdly".

ROOT CAUSE, confirmed by 4/4 independent verifiers. There are two different numberings:
  RTT_POS          -- SIX FIXED SPOTS on the table, numbered by where they are
  RTT_SETUP_COLORS -- PLAYER NUMBER -> colour (P1 Red, P2 Yellow, P3 Orange, P4 Teal, ...)
  RTT_LAYOUT       -- player number -> spot, so seating runs counterclockwise
rttSeatPlayers (logic.lua:3379) colours a player by PLAYER NUMBER. rttPlaceFaction
(logic.lua:4095-4099) works out the same player's colour by finding the nearest SPOT and then
indexing the colour table with the SPOT number. It never undoes RTT_LAYOUT. So the note published in
Global RTT_SEAT_COLOR is wrong wherever RTT_LAYOUT is not the identity: right at 1 and 3 players,
wrong at 2 (1 of 2), 4 (2 of 4 -- P3 and P4 swapped), 5 (3 of 5) and 6 (4 of 6).
The gizmo (rttSeatFaction, logic.lua:5909) and the box score (refreshSeats, boxscore.lua:893-904)
both read that note. The box score treats it as authoritative and marks the colour used, so its own
geometry cannot repair it.

CORRECTION to an earlier comment: logic.lua:4086 says "Hence the isDraft guard", but there is no
isDraft check on the seatColor block at 4092-4110. The manual path publishes too.

DO NOT FIX BY INVERTING RTT_LAYOUT. Verified to break the manual path: rttPlaceFaction has no seat
count to invert with (RTT_ORDER is only built by the draft, and rttResetRunState clears neither
RTT_ORDER nor RTT_DN), and RTT_LAYOUT[5] is not self-inverse so editing the table itself would move
physical seating at 5 and 6 players.

Two decisions, to be taken with the maintainer BEFORE any code changes:
- [ ] BUG: make the published colour match the seat's real colour. Small.
- [ ] DESIGN: stop re-reading a volatile Global every 6s. RTT pushes the seat list to the sheet once
      (it is tagged "RTT BoxScore", so the channel already exists); the sheet stores it in S, which
      onSave persists, so it survives save/load; geometry stays only for non-RTT tables; add a way to
      correct a row's colour by hand (today there is none).
- [ ] DESIGN, raised by the maintainer 2026-09-05: should the ranked draft force colours at all?
      Today it kicks everyone to Grey and recolours by player number (logic.lua:3380, inherited from
      the base mod's placePlayer). "players join the game, they can pick their color, this should
      never be forced". Not forcing would delete this whole bug class, but turn order stops being
      readable from colour (Red = first player) and rttEnableTurns builds its order from
      RTT_SETUP_COLORS[1..n], so that has to change too. The manual path already does not force.

### Also confirmed by the same audit (each verified by an adversarial second pass)

GAME-BREAKING
- [ ] Two Vagabonds collapse onto one key. rttFactionKey maps every Vagabond character to "Vagabond",
      so RTT_SEAT_POS/COLOR/PLAYER keep only the second one and the box score shows ONE Vagabond row.
      The other player has no score line at all; both "Vagabond VP" markers read into that one row.
      (logic.lua:4077)
- [ ] Gizmo hands a Vagabond player an ENEMY supply. rttSeatFaction returns the collapsed key
      "Vagabond", which is not a blueprint key, so no supply resolves and a neighbour's warrior pops
      out instead -- silently, because the code only warns when the bag is nil. (logic.lua:6012)
- [ ] Box score round column is derived from a live divisor (#S.rows), so a row appearing or
      disappearing mid-game retroactively re-maps every future lock: a whole column comes out blank
      or two rounds show the same numbers. STRONG CANDIDATE for "it skipped a number".
      (boxscore.lua:1813)
- [ ] A turn pass by a colour with no row records nothing AND does not advance S.turns, so every
      other row's columns drift one to the left for the rest of the game. (boxscore.lua:1852)

MAJOR
- [ ] Save/reload wipes RTT_SEAT_COLOR and the sheet silently re-colours every row with the geometric
      guess that note exists to replace -- rows get tinted White/Pink, nobody is sitting in them, and
      turn attribution follows the wrong row. (boxscore.lua:893)
- [ ] The "Faction Select" tool publishes every faction it places as "Red" (its board spawns
      equidistant between spots 1 and 3), so several factions claim Red and rttSeatFaction picks an
      arbitrary pairs() winner -- a different one from press to press. (logic.lua:1824)
- [ ] Only 10 round columns are rendered and S.cols never grows, so every lock from round 11 is
      invisible on the sheet (it is still in the export). (boxscore.lua:2413)
- [ ] EDIT's round-number button resets the within-round position to zero, shifting half the table by
      a full round. (boxscore.lua:2200)
- [ ] Exported turn_order is the geometric row index, so on the manual setup path it records where a
      player sat, not the order they played. (boxscore.lua:1201)
- [ ] A Vagabond seat has no supply, so the gizmo pulls from a neighbour's bag with no warning.
      (logic.lua:6012)
- [ ] On the manual path the gizmo matches the player's JOINED colour against SEAT colours, so anyone
      who happens to have joined as Red/Yellow/Orange/Teal gets another seat's supply.
      (logic.lua:5918)

MINOR / COSMETIC
- [ ] At six seats the sheet's angle sort gives row order 1,3,2,5,4,6, disagreeing with RTT_LAYOUT[6];
      four of six exported turn_orders are wrong. (boxscore.lua:1010)
- [ ] Hovering a hireling warband makes the gizmo do nothing, silently -- it does not fall through to
      the spawn branch. (logic.lua:6043)
- [ ] The manual board table diverges from RTT_POS at index 6: (52,46) duplicated, (0,46) missing.
      Unreachable today (manual only asks for 4 or 5). (logic.lua:1772)
- [ ] pinFirstSeat's comment documents a 4-seat-only invariant and calls POSITION indices seat
      numbers -- the reason the six-seat divergence above stayed invisible. (boxscore.lua:1054)

REFUTED by the verify pass, recorded so they are not re-found: "manual setup never applies
RTT_LAYOUT so its turn order zig-zags" and "manual END TURN advances by row index".

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
Read an old module with `git show legacy/mods-history:mods/m300_duchy_warriors.py`. That tag (and every
`legacy/*` / `discarded/*` tag) is **LOCAL-ONLY**: removed from GitHub on 2026-09-05 because the old
history carried the maintainer's real identity; rewritten locally so every commit is MrDrouf. Never
push tags -- `.git/hooks/pre-push` blocks them and any commit carrying the real name. The build is three
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

**Fault 2 struck again on 2026-09-04, twice in one evening.** Everything built for the box score's
seat colours and the TTS turn order lived in `rttSeatPlayers`, which ONLY the ranked draft calls -- so
on the manual 4-board path (`RTT Manual Selector`) there were no seat colours and no turn order at all,
and the maintainer, who tests on that path, saw uncoloured rows and TTS's own ten-colour default order.
Fixed by extracting `rttEnableTurns()` and calling it from both paths, and by dropping the `isDraft`
gate on the seat-colour publish. That is now the FOURTH thing these two paths have disagreed about
(teardown tags, run-state reset, busy release, hand-1 ordering) plus this one. Until they share a single
setup function, assume any new setup behaviour is missing from one of them.

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

## OPEN — from the Zaandaa play-test discussion (2026-09-05)

Nothing below is implemented. The maintainer asked to be consulted before each change.

### Bugs

- [ ] **Old seat-number cards survive into a new draft.** Zaandaa: "old seat number cards remain if
      you start a new draft". The teardown clears by tag (RTT_TEARDOWN_TAGS); these are evidently
      untagged or spawned outside it. Same class as every other teardown miss this repo has had.
- [ ] **The burrow is not locked when it spawns.** Zaandaa locks it by hand for other players every
      game. Lock it at spawn, like the landmarks and the mood manager already are.

### Setup and placement

- [ ] **Camera states: use Zaandaa's.** He plays host and streams, so his are the useful defaults.
      The file is `~/Downloads/cs` (3882 bytes, 10 states). Checked against the build: 9 of the 10
      differ, so this is a real change, not a no-op. Applying means replacing the top-level
      `CameraStates` array in the save.
- [ ] **Turn counter and timer: bottom-right, slightly bigger.** Zaandaa: put them to the right of
      the board's bottom-right corner -- the space under the battle mat is otherwise unused and is
      the easiest place to reach on screen. NOT the box score, which he says is too much there.
      POSITIONS RECOVERED, ready to bake -- the maintainer placed them and saved as TS_Save_27
      (2026-09-05 15:24); read out of that save and compared against what the mod ships:

          RTT_TIMER_POS    { 17.3624, 11.6669, -26.3142 }  ->  { 29.480, 11.667, -17.145 }
          RTT_COUNTER_POS  { 22.9297, 11.5240, -25.1741 }  ->  { 29.633, 11.515, -20.856 }

      Rotations are unchanged: the clock stays upright at { 90, 359.98, 0 } and the counter flat at
      { 0, 0, 0 }. Both objects have a BLANK Nickname, so find them by Name -- "Digital_Clock" and
      "Counter" -- not by nickname. Still to decide: Zaandaa also asked for them slightly BIGGER,
      and no scale was changed in that save, so the size is a separate call.
- [ ] **Crow plots should spawn in the hidden zone.** They do not today because the zone's position
      was unsettled. The maintainer has since placed the hidden zone (rttCrowsHiddenZone) and asked
      Zaandaa whether that spot is good -- if yes, spawn the plots directly into it.
- [ ] **Swap the Knaves captains object with the crafted improvements object.** Zaandaa: crafts sit
      immediately right of every other faction board, so the captains break the pattern. The
      maintainer's counter: you move the captain card to the active captain slot, so left felt
      natural. UNRESOLVED between them -- ask before moving.
- [ ] **Remove the Advanced Setup card** that spawns with the crafted improvements. The maintainer
      asked, Zaandaa said remove.

### Buttons and real estate

- [ ] **Spawn the Vagabond cards with Faction Cards, and drop the Vagabond Cards button.** Zaandaa:
      selecting a Vagabond manually already gives you the meeples, so the separate button is
      redundant, and Faction Cards then serves general manual drafting. Frees a slot on the board.
- [ ] **Per-faction DRAW ONE buttons, and DRAW POND when the frogs are in.** Zaandaa: old Woodland
      Tournament mods had a draw button beside each faction board. It avoids high-ping draws from
      hands and stops accidental overdraws (pressing 11). The maintainer has this on his own list.
- [ ] **Per-faction VP +1 / -1 buttons, echoing to the chat console.** Same source: the old mods
      printed each score change to the console, which doubles as a game log.
- [ ] **A one-shot DEAL FIVE button beside the deck when it spawns.** Temporary, removes itself.

### Gizmo (the maintainer will iterate; ask before changing behaviour)

- [ ] **Make the warrior pull snappier.** Zaandaa: the current smooth take is slow. Options he
      raised: place instantly; a second press removes the one just placed; or place on top of
      whatever it collides with. The maintainer deliberately wanted the visible travel from the
      supply so players see where it came from -- so this is a taste call, not a bug.
- [ ] **Extend the gizmo to mobs, strongholds and the rest of the tokens/buildings.** Zaandaa asked
      for it; both agreed the mechanism is an assigned return location per object, and the
      maintainer's proposal is to use each piece's own spawn position from the faction setup. That
      is already known per faction, so it is a table of piece-name -> seat-local spawn offset.
- [ ] **Separate buttons for the gizmo's actions.** Zaandaa thinks distinct buttons beat one key;
      the maintainer said it is early. Open.

### Housekeeping the maintainer flagged

- [ ] **Fan-made content still referenced in the built save.** 22 distinct fan names survive,
      including live asset links: Infected (42 references), Roamer (10), Advocate (9), Farmer
      Warrior (9), Arachnid Association (6), Necropossums, Croakers Coven, Spinners of Mercy,
      Woodland Revolution, Old Man Tinker, Order of the Forest, Snow Kingdom, Marquistador, Dove
      Corps, BCPii, Noxious Battery, Klacar's Volcano Island. Mostly remnants of roster lists.
      CAREFUL: Bat Bungler, Mob Lobber, Koffin Keeper and Salty Old Stan are IN USE -- the
      maintainer said so explicitly -- so this is a per-name audit, not a sweep.
- [ ] **Conversational prompts left in code comments.** 16 comments quote the maintainer directly
      ("maintainer: ...", "he asked for ..."). They carry real rationale and should not just be
      deleted, but they should read as technical notes rather than as a transcript.

- [x] ~~Suits are not randomised~~ — WRONG, TWICE, both times asserted without reading the code
      that does the work. The verified record: **every map randomises its clearing suits.** The five
      printed-suit maps go through `shuffleMaps`, which shuffles the "Clearing Marker" objects across
      their recorded positions and rotations. **Marsh** is excluded from that only because it
      randomises its own inside `rttMarshPlan` -- "SUITS: all 12 clearings randomised (4 of each
      colour) across 9 fixed + 3 dry" -- which has to be separate, since which clearings exist
      depends on the flood. Measured over 200 Marsh builds: 4/4/4 every time, positions taking
      different suits between builds. The Mountain was the only map that dealt nothing, and it is
      fixed. Nothing to do.

- [ ] **Delete the repeat-shuffle loops in shuffleMaps (ask first — behaviour-neutral).**
      `for i=1,30 do ruins = shuffle(ruins) end` and `i=1,10 do clearingMarkers = shuffle(...) end`.
      Repeating a shuffle does not make it more random: shuffle() is a correct Fisher-Yates, so ONE
      pass is already a uniform permutation and the other 29 (and 9) are wasted work. The marker line
      is also missing its `for`, so it parses as `i = 1, 10` plus a bare do-block -- it happens to run
      once, which is the right number, and leaks a global `i`. The fix is to call shuffle once on both
      lines and drop the loops, not to add the missing `for`: that would make the marker line match a
      neighbour that is itself wrong. No game outcome changes either way.

### From this session, still unverified

- [ ] **Rules audit against root_engine.** The Mountain bug was game-breaking and was found only
      because the maintainer asked. root_engine/rules + maps_data is an authoritative corpus
      (maps_appendix.md, HOUSE_RULES.md with the group's own variants, maps_data/*.json with per-map
      clearing data). Everything this mod places automatically should be checked against it: faction
      piece counts and starting positions, the Marsh flood and its number tokens, clearing priority
      markers per map, the Marquise's 12-vs-15 cats, Winter relics, Corvid plots, Eyrie viziers,
      Knaves captains, deck composition. Note HOUSE_RULES holds the group's OWN variants -- the
      Mountain centre is one -- so the engine's defaults are not automatically what this group plays.

## BLOCKED — need more info from the maintainer

(nothing blocked)

## AWAITING A TEST AT THE TABLE

- [ ] **Seat colour cannot be re-taken after leaving it.** Reported 2026-09-05: "I was in that
      color, then I changed color to another seat, and then I'm not able to go back". Nothing in
      this mod destroys or reassigns a hand zone -- it only ever MOVES them -- so the cause is not
      ours. It matches a community-reported TTS bug: deleting an object that still has XML UI
      attached leaves the server unable to hand out colours, arrivals get only Grey, and a colour
      that has been left cannot be retaken, while the hand zones still look fine. This mod deletes
      XmlUI objects constantly (every manual selector board on a pick, every ranked selector, the box
      score on each respawn, everything cleared by tag at a new game), so it would trigger it far
      more than most.
      MITIGATION SHIPPED, NOT VERIFIED: rttDestroyUI clears an object's XML and destroys it a frame
      later, applied at every such site including the selector's own X button. Nothing available here
      can inspect TTS's colour state, so this needs the maintainer: pick factions, change seats a few
      times, and see whether the colour he left becomes available again. If it still happens, the
      next suspect is the box score, which rebuilds its XML every 1.2s.
