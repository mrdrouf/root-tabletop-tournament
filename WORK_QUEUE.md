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
- [x] **Generation token (structural fault 4)** (DONE 2026-09-04, VERIFY). RTT_RUN_ID is bumped by
      rttClearGameObjects, which both setup paths call. The 15 scheduling calls in the setup chain
      (rttSpawnDeck / rttSlideOut / rttFlipAll / rttDealOrder / rttBeginPick / rttSeatPlayers /
      rttDealOrderCards / rttStartFactionDraft) now go through rttAfter / rttAfterFrames, which capture
      the id at schedule time and do nothing if the game has moved on. Same argument order as
      Wait.time / Wait.frames on purpose, so converting a call site is a rename and nothing else.
      The busy guard stops a second run STARTING; this stops an in-flight chain from acting on a run
      that no longer exists.
- [x] **Build-time untagged-spawn check (structural fault 3)** (DONE 2026-09-04). gen/assemble.py now
      fails the build if any function calls takeObject/spawnObjectJSON without addTag/setTags/
      RTT_SPAWNED, with an explicit UNTAGGED_SPAWN_OK allowlist (makeFaction, makeTool,
      rttDealOrderCards and two base-mod leftovers, each with a reason). Proven by stripping the
      Marquise cats' tag: the build stops. This class shipped FOUR times (pond, Lizard Wizard, cats,
      supporters) and was invisible by construction -- the teardown reads correctly while an untagged
      spawn simply never appears to it.

## OPEN — new batch (2026-09-04)

- [x] **Woodland Alliance supporters** (DONE 2026-09-04, VERIFY). Three cards from the top of the shared
      deck into the supporters area on spawn; nothing drawn if there is no deck.
      Three separate faults, all mine, found in sequence:
      (1) I started BUILDING a HandTrigger before checking -- RTT already had `spawnSupportersHand`
          (logic.lua:2308, identical to the base mod's) and already called it. The maintainer was right
          that nothing had been changed on the Alliance board. Reverted.
      (2) `deck.deal(3, color, 2)` does NOT honour the hand index; cards went to an arbitrary spot.
          Replaced with explicit placement onto the hand-2 transform -- dropping a card inside a hand
          volume is what puts it in that hand.
      (3) Intermittent ("sometimes it works, sometimes it bugs"): TWO races. setHandTransform is not
          instant, so reading getHandTransform(2) too early returned the PARKED zone (all ten sit at
          x=-75) and the cards landed there; and three takeObject calls in one frame hit the deck-busy
          race this file already documents at the turn-order deal. Now: capture hand 2's position before
          the move and wait until it actually changes (12 tries at 0.25s), then take one card per 0.25s,
          with RTT_ALLY_SUP_DONE preventing a double deal.
      OWNERSHIP: the hand follows THE PLAYER WHO PICKED, not the seat's colour. One rule at every player
      count -- in a real game the picker IS the seat's player, since rttCoordFaction only lets you pick
      on your own seat; solo that restriction is bypassed, which is why the maintainer could not see
      cards in an area owned by a colour he was not sitting in.



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

- [x] **Box-score row COLOUR/PLAYER binding** (FIXED 2026-09-04, VERIFY). RTT now publishes Global
      `RTT_SEAT_COLOR` (faction -> seat colour) from the DRAFT path only, where the colour is the seat's
      own; the manual path is deliberately excluded because there the colour is just whoever clicked.
      refreshSeats() binds those rows FIRST and marks colour+faction used, so the greedy hand-zone pass
      can only fill in rows RTT knows nothing about. Original diagnosis:
      refreshSeats() assigns each row's colour by matching the faction's supply anchor to the NEAREST
      HAND ZONE, then attaches the seated player's name to whichever row got their colour. RTT knows the
      truth -- rttSeatPlayers forces seat N into RTT_SETUP_COLORS[N] -- but never publishes it: the
      bridge carries only RTT_SEAT_POS (faction -> {x,z}), with no seat number and no colour.
      CONSEQUENCES SEEN: (1) solo, exactly ONE row can carry the player's name -- the maintainer's save
      has `Marquise color=White player='KRT...'` while he was playing another faction; (2) rows come out
      coloured White/Pink, which are not RTT seat colours at all; (3) my first-seat pin originally
      targeted rowByColor(Turns.order[1]) == "Red" and landed on seat 2, because Red was bound to
      Riverfolk by geometry; (4) NOW THAT THE TURN GATE IS UNIFORM, followTurns()'s own
      `S.turns == 0 -> Turns.order[1]` pin has the SAME exposure whenever TTS turns are enabled.
      FIX SHAPE: RTT publishes seat -> colour (and seat -> faction) as a Global alongside RTT_SEAT_POS;
      the box score prefers that over hand-zone geometry and falls back to geometry only outside RTT.



- [x] **Knaves captains duplicated when swapping between slots** (FIXED 2026-09-03, VERIFY). The
      maintainer: swapping cards between captain-board slots spawned the same captain several times;
      returning one to the SAME slot did not.
      ROOT CAUSE: rttCaptainDetect committed per SLOT -- `RTT_CAP_SLOT["slot"..i] ~= best.name` -- so
      dragging a captain from slot 1 to slot 2 made slot 2 see a "different" captain than it had
      committed and spawn it a SECOND time. The old comment documented this as intended behaviour
      ("even one spawned earlier in another slot"); the maintainer's report overrides it.
      FIX: commit by CAPTAIN NAME in a new `RTT_CAP_SPAWNED` set, so a captain spawns AT MOST ONCE per
      game wherever it is dragged; the meeple/item column now follows the slot index (0..2) instead of a
      monotonic counter that drifted on every swap. Plus a HARD CAP of 3 on captain warriors
      (`RTT_CAP_WARRIOR_N`), so a switcheroo bringing in the 4th drafted captain cannot add a 4th
      warrior. Both reset with the rest of the captain state when a board is created.

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

- [x] **Ginso's Gizmo: PORTED, not spawned** (DONE 2026-09-04, VERIFY). Maintainer, after seeing it
      spawn an object: "it should always be there available when spawning the mod, functional but
      without spawning the item". So the object is gone entirely -- no button, no spawn, no
      rttEnsureGizmo -- and its 386-line script is ported into the setup board instead.
      Why that works: onScriptingButtonDown is a TTS event that fires in OBJECT scripts too, and the
      gizmo script has ZERO runtime dependency on its own object (the single `self` in it is inside a
      comment). Its onLoad/onSave became rttGizmoLoad/rttGizmoSave, driven from the board's onLoad and a
      new board onSave so the custom supply/track config still persists. NUMPAD 0/1 now work with
      nothing on the table.

- [x] **Koffin Keeper and Mole Monger re-added** (DONE 2026-09-04, VERIFY). Both objects were still in
      EVERYTHING['Tools']; only their buttons had been dropped. Their art URLs were already in the
      board's own asset table, so they just needed registering as CustomUIAssets. Added on a THIRD tools
      row at y=-74 (x=-95, -57), with the squeeze the maintainer originally asked for: tool buttons
      17 -> 14 tall, rows lifted -46.5/-69.5 -> -38/-56 and the decks row -15 -> -12, which clears the
      info bar at y=-85. Both use makeTool like the other tool buttons. Original note: Both still exist in the
      DATA (content.lua has the Koffin Keeper art URL and a `toggleSpecial` branch at logic.lua:2396;
      Mole Monger appears once in each) but neither has a BUTTON in save.json any more -- the buttons
      were dropped, not the objects. Add them on a NEW THIRD LINE below the existing two option rows.
      Layout work: squeeze all the buttons slightly to make room and move the whole block up a bit.
      Must respect the existing option-button design (the wooden-plaque style, same sizing/idiom).

- [x] **Clicking Ranked / Theme repeatedly + wipe confirmation** (CONFIRMED WORKING by the maintainer
      2026-09-04).
      ROOT CAUSE FOUND (2026-09-03): the setup chain is ~6-10 SECONDS of unguarded async with no
      re-entrancy guard anywhere. rttSetup -> rttSpawnDeck (Wait 0.1s per card) -> rttSlideOut
      (0.9s then 0.6s per card) -> rttFlipAll -> rttDealOrder (1.0s) -> its own 0.5s + 0.6s ->
      rttBeginPick (1.0s) -> Wait.frames 10 -> rttSeatPlayers + rttStartFactionDraft -> rttShowFactions
      (Wait.frames 40). A second click starts a SECOND chain: the new rttSetup destroys the first
      chain's objects, but the first chain's already-scheduled Wait callbacks keep firing against those
      destroyed objects and against the new run's state -- dealing from a dead deck, seating twice,
      stacking selectors.
      FIX SHAPE: (a) a generation token -- rttSetup increments RTT_RUN_ID and every deferred callback
      returns early unless its captured id still matches (TTS Wait handles are not retained anywhere
      today, so cancellation by id is not available without threading them through); plus (b) a busy
      guard so clicks during a run are ignored rather than queued.
      CONFIRMATION (DONE 2026-09-03, VERIFY): maintainer chose "the button asks itself" and specified
      "change the art of the button itself to red with 'Wipe all factions boards?' then after 3 seconds
      if not clicked it turns back to normal". Ranked / Theme / 4-Players / Marsh5P now call rttArm*
      wrappers instead of firing directly. Arming hides that row and reveals `rttWipeConfirm`, one wide
      red plaque (#cf4a3c) reading "Wipe all factions boards?" exactly where the buttons were -- a 34x34
      icon tile cannot show that sentence. A second click commits (rttWipeConfirm disarms FIRST, so a
      double-click cannot start two runs); 3 seconds of silence reverts it via a token-guarded timer.
      Only attributes with existing precedent on this board are used (active/color/text/fontSize/
      position/width/height); textColor has NO precedent and would risk TTS dropping the element.
      Maintainer chose NOT to lock any buttons mid-game -- the confirmation alone is the protection.
      NOTE: it arms on EVERY click, including on an empty table. Say the word if it should skip the
      prompt when there are no faction boards to wipe.
      STILL OPEN: the underlying re-entrancy (generation token) is NOT done yet -- the confirmation makes
      a double-click harder but the async chain is still unguarded.

- [x] **Starting a new game clears every spawned extra** (FIXED 2026-09-04, VERIFY). Root cause was
      not a broken sweep but two objects the sweep could not see: the **Pond** tagged itself "RTT Pond",
      which nothing cleared, and the **Lizard Wizard** was tagged plain **"Faction"** -- one word off
      "RTT Faction" -- so the sweep walked straight past it. Badger relics and crow plots were already
      tagged "RTT Faction" correctly.
      FIX: one shared `rttClearGameObjects()` over RTT_TEARDOWN_TAGS = {RTT Selector, RTT Manual
      Selector, RTT Faction, RTT Pond}, called by BOTH setup paths, which had been maintaining separate
      copies of the same list. Wizard retagged "RTT Faction". Deliberately NOT swept: "Map Object" and
      "RTT Priority" belong to the map, "Deck Object" to the deck.
      VERIFY: pond, wizard, frog cards and badger relics should all be gone on a new game. Original: (broadened 2026-09-03 on the
      maintainer's follow-up). Confirmed leftovers: the **Pond** survives into the next game, the
      **Badger (Keepers in Iron) relics stay on the map**, and the **frog cards** and **Lizard Wizard**
      stay out after switching games via the faction-board setup buttons. Treat this as a GENERAL rule,
      not a list of special cases: everything a faction setup spawns must be torn down when a new game
      starts or when that faction is re-set-up.
      Implementation note: the tear-down should be tag-driven rather than per-object -- most extras are
      spawned by rttFactionExtras and friends (rttSpawnPond / rttFrogsSetup / rttLizardSetup /
      rttBadgerRelics / rttCrowsPlots / rttSpawnCaptainsFor). Give every spawned extra a common tag at
      spawn time and have rttSetup + the faction-board buttons destroy that tag, the way removeMapItems
      already does for "Map Object". Audit rttFactionExtras for anything else that escapes.
      (Related: the RTT_FAC_TAKEN checks at logic.lua:4048/4084.)

- [x] **Woodland Alliance: deal 3 SUPPORTERS face-up on spawn** (SHIPPED 2026-09-04 -- see the
      2026-09-04 batch entry above for the four faults found along the way). Original note: When the Alliance spawns, draw three
      cards from the shared deck and lay them FACE UP in the supporters area.
      POSITIONS RECOVERED from TS_AutoSave (seat 2, board rotY 180) -- capture them before autosaves
      rotate: the supporters area is a Custom_Tile tagged "RTT Faction" at (-64.13, 11.56, -55.40),
      rotY 180, scaleX 7.80. The three cards sat at z = -55.39, x = **-67.39 / -63.91 / -60.46**
      (spacing ~3.47), y = 13.77 / 13.87 / 13.97, rotY 180, **rotZ 0 = face up**. Their midpoint
      (-63.93) is the tile's own x (-64.13), i.e. the row is CENTRED ON THE SUPPORTERS TILE -- so bake
      it as tile-local (-3.47, 0, +3.47) rather than as seat-2 world coordinates, and it works at any
      seat. Cards drawn in that save were False Orders / Travel Gear / Rabbit Laborers, i.e. the top of
      the shared deck. Golden rule: draw and place at the final spot, no spawn-then-move.

- [x] **Eyrie: default vizier-card position updated** (DONE 2026-09-03, VERIFY). My earlier "they do not
      exist" was WRONG and the maintainer was right to push back: the cards have EMPTY nicknames, so a
      nickname search missed them, and the Eyrie only appeared in the autosaves from 23:10 onward.
      Found them by geometry instead: 6 cards tagged "RTT Faction" in the Eyrie quadrant of
      TS_AutoSave_3 -- CardID **22304/22305 are the two Loyal Viziers**; 14003/14102/14201/14300 are the
      four leaders in a 2x2.
      Reprojected with the real spawn transform (flipped seat, z>0: world = -move_to + seat, seat 3 =
      (52,46)); validated against leader 14003, move_to (-12.71,-2.07) -> world (64.71,48.07), matching
      the save exactly. Result: **22305 had NOT moved** (delta 0.000) and 22304 moved -5.804 in x.
      Baked 22304 move_to (-0.924112, 0.214964, 11.616381) -> (-6.728250, 0.214964, 11.632310).

- [x] **Box score STALE faction memory** (SHIPPED 2026-09-04): the poll now prunes any row whose VP
      marker guid no longer resolves, so the markers on the board are the only memory. Original: The maintainer: the ONLY source of truth for
      which factions are present should be the **VP score markers on the board**. Observed: loading a
      previous save added a pile of factions to the sheet; and after resetting and spawning new factions
      the sheet positions VP markers in odd spots as if the previous markers still existed.
      Note S is persisted whole (onSave returns JSON.encode(S), onLoad replaces S), so S.rows survives a
      load and is never reconciled against what is actually on the table. Rows are only ever ADDED
      (addRow when a VP marker becomes readable); nothing prunes a row whose marker is gone.

- [x] **VP markers when the MAP comes AFTER the factions** (SHIPPED 2026-09-04): placement is no longer
      time-boxed -- unplaced markers stay in RTT_VP_PENDING and makeMap finishes them when a track
      appears. Original:
      some factions' markers never land on the track. **CONFIRMED by the maintainer: it is always the
      EARLIEST-placed factions that go missing**, which is exactly the time-box signature. CAUSE: placement is time-boxed,
      not event-driven -- rttPlaceFaction defers with Wait.time(rttPlaceVPRetry(vpF, vpN, 6), 1.2) and
      the retry chain is 6 tries at 0.6s, so it gives up ~4.8s after the faction spawns. If the map (and
      therefore the score track) arrives after that window, the marker is never placed. Fix shape: retry
      until the track EXISTS rather than a fixed count, or re-run placement when a map is spawned.

- [x] **Two of the same faction in one setup** (FIXED 2026-09-04, VERIFY). makeFaction's existing guard
      was per-BOARD (RTT_MANUAL_PICKING[boardGUID]) -- it stopped one board double-firing but not the
      SAME faction being picked from two different boards, which spawned it twice and threw the nil-key
      error, since VP marker / seat map / extras are all keyed by faction name. Added the per-faction
      RTT_FAC_TAKEN guard the draft path has always had, with a broadcast so the click is not silently
      swallowed, and it releases the board so it can still be used for a different faction.
      REQUIRED COMPANION FIX: setupFactionBoards reset none of the run state, so that guard would have
      gone stale across games -- it now resets RTT_VP_PLACED / RTT_FAC_TAKEN / RTT_TRACK /
      RTT_MANUAL_PICKING / RTT_SEAT_POS / RTT_SEAT_COLOR exactly as rttSetup does. Original report:
      `[Faction Selection - bab7e1] Lua Error: Value cannot be null. Parameter name: key`
      The DRAFT path guards this (`RTT_FAC_TAKEN` locks a faction at logic.lua:3481-3482), but the
      MANUAL faction-selector path (`makeFaction` on the bab7e1 board) appears to have no such guard,
      so a second copy of the same faction goes through and something keyed by faction name comes back
      nil. Reproduce, find the nil key, and guard it.

## DONE 2026-09-03 (built, committed, pushed, deployed -- VERIFY IN TTS)
- [x] **Box score: the first turn always belongs to the FIRST SEAT** (the maintainer's request).
      The sheet already had a "first turn is always the first player" rule, but it lives inside
      followTurns(), behind fullTurnCoverage() -> turnsRunning() -> `Turns.enable`. RTT ships the TTS
      turn system OFF and never enables it (`Turns` appears ONCE in the whole board script: a hardcoded
      Turns.order in onLoad), so the sheet is permanently in MANUAL mode and that rule could never run.
      In manual mode S.active starts at 1, but resort() re-pins it to the row OBJECT it was on, and rows
      are appended in the order VP markers become READABLE -- and RTT defers marker placement 1.2s with
      a retry chain, so which faction lands first is a race. The pointer settled on the first faction
      DISCOVERED, differently each game.
      FIX (root_boxscore/boxscore.lua): persisted one-shot latch `S.pinFirst`. While set, every poll
      pins the pointer at the first seat -- rowByColor(Turns.order[1]) when the colour is bound, else
      row 1 (the same row in RTT: seat 1 sits at the minimum clockwise-from-+X angle so it always sorts
      to row 1). A LATCH, not an `S.turns == 0` test, because undo of the first lock and clicking round
      column 1 both return S.turns to 0 mid-game and would re-arm it, and it would fight the EDIT-mode
      row selector. Cleared by the first lockRow / an explicit row pick / undo; re-armed only by uiReset.
- [x] **rebake_into_rtt.py was BROKEN and silently blocking every box-score fix from reaching the mod.**
      It aborted with "minimum RTT row height: expected one source match, found 0" -- the placeholder-row
      fork was merged UPSTREAM into boxscore.lua on 2026-09-02, so 9 of its 13 transforms stopped
      matching. The RTT delta is now exactly FOUR lines (BUILD, BASE_SCALE, showR, ww/wh); the script is
      reduced to those and PROVEN faithful (applying them to the pristine source reproduces the shipped
      bake byte-for-byte). Also fixed its write step -- `Path.write_text(newline=...)` is py3.10+ and
      this Mac builds on system python 3.9, so it would have failed at the write even after repair.
      Added `--check`. RTT bake advanced b02.1318 -> b03.2026.
- [x] **Credit: was OVERLAPPING the ROOT logo.** Box was position x=25 width=170 -> spans -60..110 while
      rootLogo spans -125..-50: a 10-unit overlap. The string measures ~140 units at fontSize 4, not 170.
      Free span right of the logo is -50..112, centre x=31 -> now position x=31, width=150.
      tools/preview_menu.py extended so this is never judged blind again: renders <Text>, renders
      top-level elements (rootLogo/info/xButton live outside every ToggleGroup), uses a real font on
      macOS/Linux (it only ever tried a Windows path), and unescapes XML entities.

## INCIDENT 2026-09-03: a `git reset` dropped 5 commits from rtt-live
The reflog shows `reset: moving to d0438d9` at 19:34:36, discarding the Knaves button fix, the battle-mat
fix, the .gitignore and all the WORK_QUEUE corrections; the remote had been reset to match. All five were
recovered and cherry-picked back (save.json conflicted because the credit and the Knaves button sit on the
same single-line XmlUI string -- resolved by keeping the credit and re-applying Knaves 90->95 on top).
If that reset was deliberate, say so -- it has now been undone.

## Box score COPY — status recovered from the 2026-09-02 session log (added 2026-09-03)
NOT previously in this queue (it should have been). Owned by the OTHER (Fable) session by the
maintainer's own decision -- "I will ask the other session to do it" -- so RTT sessions stay OFF the
box-score source. Recorded here for status only.
- [x] **Baked-in box score (the one RTT auto-spawns)** -- FIXED AND SHIPPING, UNTESTED. RTT_BOXSCORE_JSON
      in gen/src/logic.lua is standalone **b02.1318** (COPY numeric-entity fix), synced by d0438d9. It
      carries all 48 numeric entities and 3 RTT-only overrides, all intentional: BASE_SCALE 3.85->5.4,
      showR pinned (no maxLocks growth), ww/wh fixed to the maintainer's 4-card rectangle.
      WHY IT LOOKED BROKEN: the maintainer's TTS Saves copy was from 08:06 on 2026-09-02, PREDATING
      d0438d9 (08:19). He had never loaded the fix. Deployed 2026-09-03; VERIFY the COPY button now.
- [x] **Standalone box score Saved Object** (FIXED 2026-09-03, VERIFY): was b02.1204 in-game vs b02.1318
      in the repo. ROOT CAUSE confirmed: root_boxscore/build.py's SAVED_OBJECTS was the WINDOWS path only,
      so on macOS `--install` found nothing and said so quietly -- the built fix never reached the game.
      build.py is now platform-aware (Windows path still first) and the sheet is installed and current
      at b03.2026. Its COPY panel should now work.
- [x] ~~Standalone box score Saved Object -- STALE IN-GAME~~ (superseded by the line above)
      Original note kept for context:
      ~/Library/Tabletop Simulator/Saves/Saved Objects/Root Box Score.json is **b02.1204** (45 numeric
      entities, dated Sep 2 07:04). The repo's out/ build is **b02.1318** (48). The fix was built but
      never installed, so its COPY overlay still comes up empty exactly as reported.
      ROOT CAUSE: root_boxscore/build.py installs to the WINDOWS path
      `~/Documents/My Games/Tabletop Simulator/Saves/Saved Objects`, which does not exist on this Mac.
      The real macOS location is `~/Library/Tabletop Simulator/Saves/Saved Objects`. So `--install`
      cannot have been reaching the game. FIX BELONGS TO THE FABLE SESSION (platform-aware path in
      build.py + reinstall). Interim: copy out/Root Box Score.json + .png into the Library path by hand.
      NOTE: root_boxscore has an uncommitted diff to build.py + out/Root Box Score.json that is PURE
      CRLF churn (`git diff --ignore-cr-at-eol` is empty) -- no lost work, but it should be reverted or
      committed so it stops masking real changes.

## OPEN — new batch (2026-08-29)
- [x] **Battle mat** (DONE, VERIFY): the live flow was already single-spawn -- rttPlaceMap spawns the
      mat tagged "Map Object" and makeMap's removeMapItems() destroys that tag before each placement.
      The real duplication vector was the **Battle Mat TOOL button**: makeBattleMat -> makeSpecial
      spawned it UNTAGGED, so it survived removeMapItems and the next map placement stacked a second
      mat on it. FIX: makeSpecial takes an optional trailing `tag` argument (nil for every other
      caller, so Lizard Wizard etc. are unchanged) and makeBattleMat passes "Map Object".
      toggleSpecial still gives the tool button its click-to-remove. One mat from any path now.
      Dead paths rttCoordPick / rttShowPick still to be REMOVED in the cleanup (see below).
- [x] **Duchy (moles) tunnel position** (ALREADY DONE -- item was stale): recovered back on 2026-08-29
      (orphaned commit f1f69e8, now under `legacy/mods-history`) from **TS_AutoSave_4**, identity frame,
      warriors validating at 0.0007: the maintainer had moved tunnel `c8c8a2` to **(-8.499, 0.100, 7.538)**.
      It IS baked into the current blueprint -- `c8c8a2` appears twice in gen/src/content.lua and the
      -8.4990 coordinate is present. Nothing to do; VERIFY in TTS that the tunnel spawns there.
- [x] **Thorough code cleanup** -- SUPERSEDED. Redefined concretely as the STRUCTURAL item at the top
      of this file (explicit-argument placement, one shared new-game/spawn path, one reset registry,
      the run-id token, and a build-time untagged-spawn check). Original wording: drop obsolete/dead code + bloat, no
      duplication (shared helpers), fix bugs/typos/robustness, well-written. Implement from the plan,
      verify build each step, conservative (proven-dead only).
- [x] **Easy-install folder** (ALREADY DONE -- item was stale): settled on 2026-08-29 (orphan a56d9cb) as
      **`dist/` itself** -- it holds the one self-contained .json, the .png thumbnail and HOW_TO_INSTALL.md.
      Re-open only if the maintainer wants a separately-named top-level folder instead.
- [x] **README brief + separate BUTTONS.md** (DONE 2026-09-04): BUTTONS.md written from the live
      XmlUI and verified against the built dist -- every button on the board is documented. Original: (maintainer's choice 2026-09-04) --
      short README stays, every control documented in its own reference file. Original notes: a full every-button README WAS written (orphan a56d9cb), then deliberately
      REPLACED by the current brief one (0d93c1e, 2026-09-02). So this is a standing decision, not an
      omission. Current gaps if the thorough version is wanted back: Ginso's Gizmo and the Box Score
      button are documented nowhere. Recover the old text with
      `git show legacy/mods-history:README.md`. NEED: the maintainer to say brief or thorough.
- [x] **Faction buttons alignment -- Knaves offset** (DONE, VERIFY): it is the Faction Select tool's
      `standardButtons` group in the setup board XmlUI (gen/src/save.json), NOT the draft selectors'
      rttFac grid. Columns are x = -25 / 15 / 55 / 95 (40 apart); every other column-4 button sits at
      95 -- **Knaves alone sat at 90**. Fixed to 95, so the group is an exact 3x4 grid.
      ROOT CAUSE (recovered from the orphaned history): Knaves was deliberately set to 90 on 2026-08-29
      (orphan 65f2859) to match `_SPREAD`, the runtime -90/-30/30/90 layout that the old
      `m520_solo_faction_board` applied to a cloned board. That module did NOT survive the re-root onto
      the generator -- its grid lingers only as `RTT_FACTION_GRID` (gen/src/logic.lua:1701), DEFINED ONCE
      AND NEVER REFERENCED. So Knaves sat on a column that no longer exists while every other tile used
      the static -25/15/55/95 grid. `RTT_FACTION_GRID` is a confirmed dead-code target for the cleanup.
      STILL OPEN (design call, needs the maintainer): the grid as a whole is centred on x=35, not 0,
      and row 1 is Marquise/Eyrie/Woodland + Knaves alone in column 4 -- so Knaves still reads as
      tacked onto the end of a short row even when perfectly on-grid. Say if you want the grid
      recentred and/or Knaves moved down beside the other base factions.
- [x] **NEW OBJECT — Knaves captain board** (ALREADY DONE -- item was stale): built over 13 iterations
      2026-08-29/30 (orphaned chain, tip 21c4812 "Captain board v13: portrait slots at the placed spots,
      anchored to the faction", now under `legacy/mods-history`) and carried forward into the generator.
      Present in the current build as `RTT_CAPTAIN_BOARD_JSON` (gen/src/logic.lua ~3150) -- a Custom_Tile
      with the 3 slot snaps BAKED IN and a locked aspect-correct scale -- spawned by `rttSpawnCaptainsFor`
      anchored to the faction's rules board. Art: assets/labels/knaves_captains_board.png (+ v2/v3).
      Nothing to build; VERIFY in TTS: 3 slots, no overlap, correct side of the crafted board.

## OPEN — active batch (2026-08-28)
- [x] Uploaded assets wired: Marsh 5p label -> FivePlayerArt (button neutral #ffffff); Lost City rules
      card -> new BackURL. Marsh5P button already spawns 5p Marsh via rttFivePStart.
- [x] Turn-order decks: 4-card (standard) / 5-card (5p) by RTT_DN (m250, _order_deck_4/5.json).
- [x] Winter/non-Marsh clearing markers: skip destruct+respawn on same-map re-click (m460).
- [x] Pond (frogs, no lizard): POND_FROG_POS -> (-30.882,11.562,10.661).
- [x] Cats: stand upright (rotation), calibrated centres (eyes was 180-flipped; Gorge = exact cats).
- [x] Seating: hand moved to board by turn order, all players seated (VERIFY in TTS).
- [x] **Crows** (DONE, VERIFY): m620 bakes 4 warriors (3 loose + un-stow the 4th) + the moved supply
      into the blueprint; removed the runtime warrior reposition. Hidden Zone (FogOfWarTrigger) spawned
      on the crow board, recoloured grey->crow player's seat colour (rttCrowsHiddenZone). **Side fixed**:
      board-local offset now (-3.163,-0.404) so positionToWorld rotates it to the RIGHT of the plots for
      ANY seat (board blueprint rotY=180); draft-path ONLY (isDraft flag, not the faction selector); and
      SKIPPED for 5-player seats 1-3 (RTT_SEATS nearest match). VERIFY in TTS: right side on every seat.
- [x] **Box score — FIXED format** (DONE, VERIFY): pinned showR (no column growth) + reserve nMin
      rows (4 ranked / 5 for 5p, via Global RTT_BOXSCORE_MIN set in rttSpawnBoxScore); blank placeholder
      rows fill empty slots, all interactive controls gated `not placeholder`. Grows past nMin for more
      players. No text resize by players/VP.
- [x] **Ruins ("runes") randomise on re-click** (DONE, verified in dist): RTT's Marsh ruins go through
      `rttShuffleList` (clean Fisher-Yates, no reseed); base-map ruins go through the base `shuffle()`
      (fixed by m600). Only 2 `randomseed(os.time())` calls remain and BOTH are top-level load-time seeds
      (m490's + the base script's) — zero per-click reseeds, so every re-click advances the stream = new
      layout. VERIFY in TTS: re-click a map a few times, ruin positions differ each time.
- [x] **Cold-load "setup board loads blank / needs 2nd load"** (SOLVED + confirmed in-game 2026-08-29):
      ROOT CAUSE = the setup board bab7e1 carried **541 CustomUIAssets**, far over TTS's ~75-100
      UI-composite threshold. TTS resolves an object's XmlUI icon refs ONCE at instantiation and never
      re-composites; over that threshold the whole button group paints blank on a cold process (the board
      TILE renders because CustomImage is a separate pipeline -> "tile shows, buttons don't"). FIX = m660
      trims bab7e1's CustomUIAssets to the ~147 its XmlUI actually references (drops 394 unused base-menu
      icons; fully art-safe) -> back under the threshold -> buttons render immediately, cold, first-try.
      Dead ends ruled out along the way (do NOT repeat): setCustomAssets present/absent (m640) is neither
      cause nor cure; setXml/setCustomAssets re-apply never repaints; the board texture (jsDelivr) is fine;
      m650's full-board respawn works but is ~27s (Lua getJSON on the 4.5MB object) so it's disabled.
      Kept: m640 on, m650 OFF, m660 on, custom board on.

## OPEN

### Randomization / RNG (the maintainer: "very dangerous") — DONE + PROVEN
- [x] **ROOT CAUSE fixed**: base shuffle() reseeded math.randomseed(os.time()) 101x/call + next
      frame -> deterministic-per-second, and shuffleMaps() runs it right before the landmark. m600
      replaces it with one clean Fisher-Yates, no reseed. Removed the per-draft reseed (m250) too.
      Now 2 seeds total, both load-time. PROVEN by sim: old = identical for 3 same-second clicks;
      fixed landmark uniform 25% (chi-sq 2.10), floods 50/50 per pair.
- [x] Mountain landmark fast (Wait.frames 2), self-clears; Marsh floods re-randomise instantly.
- [x] Marsh number tokens rest on the board (11.635).

### Seating / hand placement — REWORKED to restore the base (2026-08-28, multi-agent workflow)
- [x] **Seat on turn-order-card by CARD NUMBER** (CONFIRMED WORKING by the maintainer 2026-09-04).
      Original notes: (per the maintainer: "same code, different trigger"): the base
      seated correctly on faction-pick via `placePlayer` (changeColor + setHandTransform into base
      handPositions + handScale). RTT's `rttSeatPlayers` had dropped that: a 2nd shuffle (seat != card),
      a bare setHandTransform (no changeColor/scale, never seated the player), and same-frame `ord.deal`
      that dropped the card on the base `resetHands` strip at x=-77.5 (the "trash"). REWRITTEN (m470) to
      the base's SAFE pattern: capture steam_names, shuffle ONCE = turn order, `kickPlayersFromSeats()`,
      then a FRESH `getPlayers()` loop matched by steam_name -> `changeColor(setupColors[N])` +
      `setHandTransform({seat N hand, scale=handScale})`; after a 20-frame settle, `rttDealOrderCards`
      delivers the matching "Player N" card (by CardID 800/801/802/805/806) INTO the seated hand. Seat N ==
      card N by construction. VERIFY in TTS: each player seated at their card's number, card in hand (not
      the x=-77.5 strip), hand behind their own selector board, at turn-order time (not on faction pick).

### Draft / seating flow — earlier work (superseded by the seating rework above)
- [x] **Remove pick-map / pick-deck**: rttBeginPick skips the pick, spawns boards immediately.
      5-player button still auto-places Marsh.
- [x] **Fixed board/seat count** = RTT_DN-1 -> fixes the 2-player bug.
- [x] **Seating (REVISED per the maintainer's report)**: do NOT move hands / change colour (that caused the
      "hand under the table" + wrong-seat bug). rttSeatPlayers matches each seated player to the board
      at THEIR OWN seat (nearest to where they sit) and deals the turn-order card into their existing
      hand. Order deck stays ON the table (turn order isn't secret). Turn order is random.
- [x] **Restrict**: rttCoordFaction only lets a player pick on their OWN seat's board (no seat conflicts).
- [x] **Simultaneous**: every board lights at once; fixed faction slots (no race).
- [x] **Knave Captains**: unlocked, laid FACE-UP in the maintainer's line (x 53.5, z -8..+7.4); source deck
      spawned below the table so the 8 undrafted captains never show. "Pick your faction" text removed.
  VERIFY in TTS: nearest-seat board matching, restrict, captain line, real 4-player draft resolves.

### Maps / landmarks
- [x] **Marsh 5-player buttons** (DONE): "Swol Birbs" was a *separate* fan-faction tool button at x=57
      (an earlier agent wrongly thought it WAS the Marsh5P button); m630 removed it + its Tool data.
      Now SPLIT into two (m500): x=57 `Marsh5P` (icon FivePlayerArt) -> `rttFivePStart` = full 5p Marsh
      DRAFT; x=95 `Marsh5PMap` (icon "Marsh Map") -> `rttPlaceMarsh5P` = PLACE the 5p Marsh map only
      (sets RTT_5P_MARSH, calls rttPlaceMap, no draft/selectors/seating). VERIFY both in TTS.
- [x] **Mountain landmark direct spawn** (DONE): m590 removes the central clearing marker (1b3b99)
      from the Mountain data at build time (11 markers spawn, shuffleMaps is count-safe);
      rttMountainLandmark no longer reads/destroys a marker — spawns a random landmark directly.
- [x] **Landmark explanation cards — flip** (DONE): m490 Mountain landmark now passes crotZ 180
      (RULES/BackURL face up). Marsh 5p towns already correct.
- [x] **Lost City rules-card art (outdated)** (DONE, verified): m610 swapped the card's outdated RULES
      face (BackURL) to the maintainer's new Steam upload. Verified in dist: new URL `.../11026657163450986659/
      01C4A12996D5C47049E1BA794CC33AC10F9AF662/` present, old `.../1859433736252751364/0DC4B26C.../` gone.

### Golden-rule cleanup — DONE
- [x] **Crows warriors** (DONE): the maintainer set up Corvid + saved; m620 bakes the 4 warriors the verified
      way (3 loose move_to'd 8b4f9c/b66f9e/d78475 + un-stow the 4th 29769e from the supply bag) plus the
      moved supply bag 653be4. Runtime warrior reposition removed from rttCrowsPlots. All 5 GUIDs verified
      present in the dist blueprint.

## DONE (this session, pending the maintainer's confirmation in TTS)
- [x] Bats (Twilight Council): 6 warriors + 6 assemblies baked into blueprint (m560); rttBatsSetup removed.
- [x] **Marquise (proper blueprint fix)**: 8 of the 11 loose warriors MOVED into the supply bag
      (framework.stow_loose_in_bag); 3 staging warriors baked below the 3 starting buildings (z 5.4,
      m570 — nudge if off); cats come from the bag. Total 25 (3 staging + 12/15 map + 10/7 bag).
      Fixed the m570 bug that was corrupting the supply bag's own move_to.
- [x] Cats on clearings: placed on true clearing CENTRES per map (RTT_CLEARING_CENTRES, from eyes
      geometry), from the supply bag. 12 standard / 4p-Marsh (skip 3 flooded); **15 on 5p-Marsh**.
- [x] **Duchy (proper blueprint fix)**: the 8th warrior MOVED into the Duchy Supply bag in the data
      (7 loose + 13 bagged); removed the below-table hack + deleted rttDuchyTuck.
- [x] **The Pond (proper fix)**: REMOVED from the frog blueprint (m580); spawned directly at its
      world spot from RTT_POND_JSON (rttSpawnPond) — no below-table, no reposition.
- [x] Marsh number tokens: deliberate token positions + skip-and-renumber (m460).
- [x] Marquise Keep enlarged (m550); Lizard wizard direction + Outcast marker (m490).
- [x] framework.stow_loose_in_bag: new primitive to move a loose blueprint piece into a bag.
