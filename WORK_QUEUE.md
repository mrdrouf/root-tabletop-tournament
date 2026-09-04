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

- [ ] **Ginso's Gizmo always active** + preferably a NEW alternative that ALSO places warriors.
      Today it is `toggleTool` on guid 7d5fb5 (logic.lua:2304) -- a toggle, so it can be off.
      NEED from the maintainer: should the existing button become non-toggling, or is the new
      warrior-placing variant the only thing wanted (and what exactly should it place)?

- [ ] **Re-add two removed option objects: Koffin Keeper and Mole Monger.** Both still exist in the
      DATA (content.lua has the Koffin Keeper art URL and a `toggleSpecial` branch at logic.lua:2396;
      Mole Monger appears once in each) but neither has a BUTTON in save.json any more -- the buttons
      were dropped, not the objects. Add them on a NEW THIRD LINE below the existing two option rows.
      Layout work: squeeze all the buttons slightly to make room and move the whole block up a bit.
      Must respect the existing option-button design (the wooden-plaque style, same sizing/idiom).

- [ ] **Clicking Ranked / Theme repeatedly causes various issues.** It should wipe prior state, but a
      destructive wipe needs a CONFIRMATION first. Also consider disabling some buttons mid-game.
      NEED: which buttons the maintainer wants locked once a game is running.

- [ ] **Starting a new game must clear EVERY previously spawned extra** (broadened 2026-09-03 on the
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

- [ ] **Woodland Alliance: deal 3 SUPPORTERS face-up on spawn.** When the Alliance spawns, draw three
      cards from the shared deck and lay them FACE UP in the supporters area.
      POSITIONS RECOVERED from TS_AutoSave (seat 2, board rotY 180) -- capture them before autosaves
      rotate: the supporters area is a Custom_Tile tagged "RTT Faction" at (-64.13, 11.56, -55.40),
      rotY 180, scaleX 7.80. The three cards sat at z = -55.39, x = **-67.39 / -63.91 / -60.46**
      (spacing ~3.47), y = 13.77 / 13.87 / 13.97, rotY 180, **rotZ 0 = face up**. Their midpoint
      (-63.93) is the tile's own x (-64.13), i.e. the row is CENTRED ON THE SUPPORTERS TILE -- so bake
      it as tile-local (-3.47, 0, +3.47) rather than as seat-2 world coordinates, and it works at any
      seat. Cards drawn in that save were False Orders / Travel Gear / Rabbit Laborers, i.e. the top of
      the shared deck. Golden rule: draw and place at the final spot, no spawn-then-move.

- [ ] **Eyrie: update the default vizier-card position** -- BLOCKED, need input. The maintainer moved
      them and saved. But: `vizier` and `decree` appear **ZERO times** in gen/src/content.lua,
      gen/src/logic.lua and gen/src/save.json, and the Eyrie blueprint spawns only Eyrie Warriors (20),
      Roosts (7), Eyrie Supply and Eyrie VP -- no cards. No save on this machine contains an object
      whose nickname matches vizier/visier (checked TS_AutoSave, _2, _3, _5..._8 and the shipped save;
      the last game was Marquise / Riverfolk / Alliance / Duchy, no Eyrie).
      NEED: which save has the Eyrie spawned with the cards where he wants them, and what those cards
      are actually called in the mod (they may come from a deck rather than the faction blueprint).

- [ ] **Two of the same faction in one setup throws a Lua error** (screenshot):
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
- [ ] **Thorough code cleanup** (workflow wbindjqke running): drop obsolete/dead code + bloat, no
      duplication (shared helpers), fix bugs/typos/robustness, well-written. Implement from the plan,
      verify build each step, conservative (proven-dead only).
- [x] **Easy-install folder** (ALREADY DONE -- item was stale): settled on 2026-08-29 (orphan a56d9cb) as
      **`dist/` itself** -- it holds the one self-contained .json, the .png thumbnail and HOW_TO_INSTALL.md.
      Re-open only if the maintainer wants a separately-named top-level folder instead.
- [~] **Thorough README**: a full every-button README WAS written (orphan a56d9cb), then deliberately
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
- [~] **Seat on turn-order-card by CARD NUMBER** (per the maintainer: "same code, different trigger"): the base
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
