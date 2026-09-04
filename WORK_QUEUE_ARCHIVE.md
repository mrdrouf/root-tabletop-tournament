# RTT work queue — archive

Completed items, moved out of `WORK_QUEUE.md` so the live queue only shows what is still open.
Kept because several entries record *why* something is the way it is, and the root causes behind
bugs that took several attempts — that context is easy to lose and expensive to rediscover.

# RTT Work Queue
## Note for future sessions: the `m###` labels are HISTORY, not files
## Golden rule (the maintainer, repeated + hardened)
## STRUCTURAL — the pattern behind most of today's bugs (2026-09-04)
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
## Box score COPY — status recovered from the 2026-09-02 session log (added 2026-09-03)
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

# RTT Work Queue
## Note for future sessions: the `m###` labels are HISTORY, not files
## Golden rule (the maintainer, repeated + hardened)
## STRUCTURAL — the pattern behind most of today's bugs (2026-09-04)
## OPEN — new batch (2026-09-04)
- [x] **Timer + counter spawn with every map** (DONE 2026-09-04, VERIFY). Maintainer: "every time we
      spawn a map, same as the battle mat, these two objects are spawned at the same time, always with
      the map". Recovered from his save TS_Save_22: a Digital_Clock at (17.362, 11.667, -26.314) and a
      Counter at (22.930, 11.524, -25.174), bottom right of the map. Both baked as RTT_TIMER_JSON /
      RTT_COUNTER_JSON with the Transform zeroed and the GUID stripped -- position comes from the spawn
      call and TTS assigns a fresh guid -- and both tagged "Map Object" like the battle mat, so
      removeMapItems() replaces them with each new map instead of stacking copies. Spawned from makeMap,
      so every map button and every draft path gets them.

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

# RTT Work Queue
## Standing rule: this file only shows OPEN work
## Note for future sessions: the `m###` labels are HISTORY, not files
## Golden rule (the maintainer, repeated + hardened)
## STRUCTURAL — the pattern behind most of today's bugs (2026-09-04)
## BLOCKED — need more info from the maintainer
## OPEN — new batch (2026-09-04)
## OPEN — new batch (2026-09-03, from in-TTS testing)
- [x] **Knaves: the captain deck no longer spawns on the board** (DONE 2026-09-04, VERIFY). The
      blueprint's 12-card deck (guid 59530d, CardIDs 73400-73411) is skipped by rttSpawnFaction's Knaves
      filter, matched on the deck's face texture -- the same identifier rttDraftKnavesCaptains uses.
      Safe because the draft spawns its OWN copy of that deck below the table, deals 4 and destroys it,
      reading the blueprint data directly, so skipping the on-board spawn cannot affect it. The board
      copy was a pure duplicate. Original note: -- they are drafted, so the
      board-spawned copies are duplicates. (Maintainer, 2026-09-04.) rttSpawnFaction already skips the
      12 "Captain - <name>" meeples and the item supply for this faction; the CARDS need the same
      treatment. Check what rttSpawnCaptainsFor / rttPoolCaptains put out versus what the blueprint
      spawns, so the draft keeps working.

# RTT Work Queue
## Standing rule: this file only shows OPEN work
## Note for future sessions: the `m###` labels are HISTORY, not files
## Golden rule (the maintainer, repeated + hardened)
## STRUCTURAL — the pattern behind most of today's bugs (2026-09-04)
## BLOCKED — need more info from the maintainer
## OPEN — new batch (2026-09-04)
- [x] **Box score under TTS's Alt zoom** (FIXED 2026-09-04, VERIFY). I had recorded this as undiagnosed
      twice. The answer is a TTS field I had not looked for: `AltLookAngle` is the orientation an object
      is presented at when Alt-zoomed, and it is INDEPENDENT of the object's rotation on the table. That
      is the bit I had wrong -- I thought it was unfixable because the sheet must stay at rotY 270 to
      read correctly lying flat from the maintainer's seat, but the zoom view is a separate setting, so
      both can be right at once.
      The box-score blob did not carry the field at all (null), and no object in the mod sets it
      non-zero, so there was no precedent to copy. Set to { x = 0, y = 180, z = 0 } -- a 180 turn in the
      plane of the sheet, exactly the "upside down" reported.
      VERIFIED it survives a rebake: rebake_into_rtt.py preserves the object envelope and replaces only
      LuaScript, so regenerating the box score from root_boxscore will not drop it.
      IF IT LANDS SIDEWAYS the axis is right and the value is not -- try y = 90 or y = 270. If it is
      completely unchanged, TTS ignores the field for this object type and this should be re-opened.

# RTT Work Queue
## Standing rule: work on MAIN
## Standing rule: this file only shows OPEN work
## Note for future sessions: the `m###` labels are HISTORY, not files
## Golden rule (the maintainer, repeated + hardened)
## STRUCTURAL — the pattern behind most of today's bugs (2026-09-04)
- [x] Refactor to (1)+(2)+(3): explicit-argument placement, one shared new-game/spawn path, one reset
      registry. Done 2026-09-04 on branch `refactor/placement`: `rttNewGame(seats)` is the single
      new-game entry point for both paths, `rttResetRunState()` is the one list of non-object state,
      teardown absorbed the GUID-tracked draft objects, and `spawnSupportersHand(color, hand1)` takes
      the seat explicitly (`rttSupportersTransform` is a pure function of it). Guarded by
      `tests/test_setup_paths.py` -- 6 cases, 3 of which fail against pre-refactor main.
      Found and fixed three live bugs on the way: RTT_CAP_SPAWNED survived a new game, a manual setup
      after a ranked draft left all 5 faction cards on the table, and the supporters zone could still
      be built from a stale hand 1. NOT YET CONFIRMED IN TTS by the maintainer.
## BLOCKED — need more info from the maintainer

# RTT Work Queue
## Standing rule: work on MAIN
## Standing rule: this file only shows OPEN work
## Note for future sessions: the `m###` labels are HISTORY, not files
## Golden rule (the maintainer, repeated + hardened)
## STRUCTURAL — the pattern behind most of today's bugs (2026-09-04)
## OPEN — reported 2026-09-04
- [x] **Allow more than one copy of a faction.** DECIDED 2026-09-04: keep the gate. The maintainer
      asked to remove it, then on seeing the evidence: "ok then you can keep the gate that prevents
      twice the same faction". Measured with a duplicate spawn: the second copy silently overwrote the
      first's entries -- `RTT_SEAT_COLOR` Red->Teal and `RTT_SEAT_PLAYER` MrDrouf->Ehs -- and left two
      objects both named "Marquise VP". State is keyed by faction NAME on both sides of the box-score
      protocol, so duplicates would need a per-copy identity through the mod AND root_boxscore.

## BLOCKED — need more info from the maintainer

# RTT Work Queue
## Standing rule: work on MAIN
## Standing rule: this file only shows OPEN work
## Note for future sessions: the `m###` labels are HISTORY, not files
## Golden rule (the maintainer, repeated + hardened)
## STRUCTURAL — the pattern behind most of today's bugs (2026-09-04)
## OPEN — reported 2026-09-04
- [x] **Supporters fail to draft when frog cards are on top of the deck.** Fixed 2026-09-04. Root
      cause: `rttDealAllianceSupporters` looked for a deck with `#cards >= 20 and frog == 0`, but
      `rttShuffleFrogsIntoDeck` merges the 14 frog cards INTO that very deck when the Lilypad Diaspora
      is picked -- so from then on no deck matched, `deck == nil`, and the draw returned silently.
      The right test is "not ENTIRELY frog cards" (an all-frog deck is the frogs' own). Extracted
      `rttFindMainDeck()` / `rttFrogCount()` so the two call sites cannot drift apart again.
      Measured: old build draws 0 supporters with frogs in the deck, 3 after the fix.

- [x] **Removing the frog faction must also remove the frog cards from the deck.** Fixed 2026-09-04.
      The deck is tagged `Deck Object`, which teardown deliberately never sweeps, so frog cards merged
      in by one game were still there in the next. `rttRemoveFrogsFromDeck()` now runs from
      `rttNewGame`, pulling them out one at a time and destroying them; the frogs re-add their own from
      the faction blueprint if picked again. Measured: 14 frog cards survived a new game before, 0 now,
      and the 40 non-frog cards are untouched.

- [x] **Show the supporters card travelling from the top of the deck.** Done 2026-09-04: the draw uses
      `smooth = true` (and `takeObject` with no index already takes the TOP card), with 0.6s between
      cards so each flight is visible instead of the card simply appearing on the stack.

## BLOCKED — need more info from the maintainer

# RTT Work Queue
## Standing rule: work on MAIN
## Standing rule: this file only shows OPEN work
## Note for future sessions: the `m###` labels are HISTORY, not files
## Golden rule (the maintainer, repeated + hardened)
## STRUCTURAL — the pattern behind most of today's bugs (2026-09-04)
## OPEN — reported 2026-09-04 (second batch)
- [x] **Knaves captains must spawn even without a draft.** Fixed 2026-09-04, CORRECTED after the
      maintainer clarified: "the ranked function worked fine. What I want is that when I don't do the
      ranked or theme button that drafts the captain cards, the deck of all captains still spawns on
      the faction board." rttSpawnFaction skipped the blueprint's 12-card captain deck UNCONDITIONALLY,
      on the reasoning that rttDraftKnavesCaptains supplies the captains -- true only during a
      ranked/theme draft. On a manual pick nothing drafted them, so there was no captain deck anywhere.
      The skip is now gated on rttCaptainsAreDrafted(), so ranked is untouched and a manual pick keeps
      the faction's own deck on the board. (An earlier attempt dealt four random captains instead --
      wrong, reverted.)
- [x] **`rttPoolCaptains` threw on EVERY call, and has been REMOVED.** Found 2026-09-04 while testing
      the captains: `base` was built as a positional `{x,y,z}` array and read back as `base.x`/`base.z`,
      which are nil, so the first arithmetic threw -- and the single call site wraps it in `pcall`, so
      it failed silently. It had therefore never run once in any game, ranked included: the drafted
      captains always stayed at `RTT_KNAVE_CAP` and were never pooled beside the captains board.
      DECISION (maintainer, asked directly): leave ranked exactly as it is. The captains stay at the
      draft spots, and the dead function, its geometry helper and `RTT_CAP_POOL_GAP` were deleted
      rather than repaired. Do not "fix" this back without asking -- the current layout is intended.
- [x] **Keeper relics on Winter.** Fixed 2026-09-04 from the maintainer's "winter" save (TS_Save_23).
      Winter was the ONLY map with no entry in `RTT_RELIC_POS`, so it alone fell through to
      `rttForestWorldCenters` -- forest CENTROIDS, not relic spots (and that fallback rotates with the
      opposite sign to `positionToWorld`, which is the 180 flip he saw). His eight positions are read
      back in the map's local frame (map ec2372, rotY 180, scale 12.979) and baked; round-trip against
      the save is exact to 8e-04 world units. NOTE the fallback's sign bug is still there for any
      future map added without recorded spots.

- [x] **Rats: Mini-Mood Manager spawns with the board, and the duplicate deck is gone.** Fixed
      2026-09-04. It ran from `rttFactionExtras`, which is deferred 0.5s, so it landed visibly after
      the board; it now spawns in the same pass as the faction's own pieces. The duplicate was the
      8-card mood deck baked into the rats blueprint at (2.99,-9.10) -- essentially on top of
      `RTT_MOOD_LOCAL[1]` at (3.02,-9.16) -- removed from `content.lua` (CardIDs 10900-10907; the tool
      ships its own 11300-11307).

## BLOCKED — need more info from the maintainer

# RTT Work Queue
## Standing rule: work on MAIN
## Standing rule: this file only shows OPEN work
## Note for future sessions: the `m###` labels are HISTORY, not files
## Golden rule (the maintainer, repeated + hardened)
## STRUCTURAL — the pattern behind most of today's bugs (2026-09-04)
## OPEN — reported 2026-09-04 (third batch)
- [x] **Captain cards were not wiped on reset.** Fixed 2026-09-04. The captain deck object was tagged
      "RTT Faction" at spawn, but a card DRAWN out of a deck carries its OWN tags, and the 12 cards in
      the blueprint had none -- so any captain taken out survived teardown. "RTT Faction" is now baked
      onto the deck and all 12 cards in `content.lua` (all three identical copies of that deck).

- [x] **Mini-Mood Manager locked on the rats board.** Done 2026-09-04: entry 1 of the tool (the manager
      BOARD) spawns locked. The eight mood cards stay unlocked -- they have to be movable to be played.

- [x] **Captains drafted before the turn-order cards.** Done 2026-09-04. In `rttFlipAll` the order deck
      was at +1.0s and the captains at +1.6s; now captains at +1.0s and the order deck at +2.2s, which
      clears the ~0.5s the captain deal needs.

- [x] **Corvid warriors repositioned.** Done 2026-09-04 from the maintainer's "corvid" save
      (TS_Save_24). Seat solved from the Corvid Supply offset -- seat (-52,-46), unflipped, error 0.0000
      -- and the four warriors' world positions converted back to seat-local `move_to`. Rebuild
      reproduces his saved positions exactly (0.00e+00). NOTE the blueprint has 4 top-level warriors;
      the other 11 live inside the Corvid Supply bag and were not touched.

## BLOCKED — need more info from the maintainer

# RTT Work Queue
## Standing rule: work on MAIN
## Standing rule: this file only shows OPEN work
## Note for future sessions: the `m###` labels are HISTORY, not files
## Golden rule (the maintainer, repeated + hardened)
## STRUCTURAL — the pattern behind most of today's bugs (2026-09-04)
## OPEN — reported 2026-09-04 (fourth batch)
- [x] **Mole Monger spawns with the Duchy board.** Done 2026-09-04 from the saves "moles" (TS_Save_25,
      Duchy in 4p seat 2) and "moles b" (TS_Save_26, 4p seat 1, plus 5p seat 2). The positions are
      ABSOLUTE table coordinates, not seat-local: the Monger parks along the near edge at either
      `(-26.275, 11.562, -54.530)` [LEFT] or `(32.852, 11.562, -54.521)` [RIGHT], and which one depends
      on where the mole player sits. All five seats he specified fit one rule -- the spot on the
      player's OWN side, which flips for the far row because those seats are rotated 180:
        LEFT  <- (-52,-46) and (52,46)          [4p seats 2 and 4]
        RIGHT <- (52,-46), (-52,46), (0,-46)    [4p seats 1 and 3, 5p seat 2]
      Spawned in the same pass as the faction (like the rats' mood manager), tagged "RTT Faction" so it
      goes out with the faction, and locked -- his own copy in the "moles" save is locked.
      NOTE the centre FAR seat (0,46), reachable only at 6 players, is the one case he did not specify;
      it follows (0,-46) to the RIGHT spot. The Mole Monger BUTTON still exists and still spawns one at
      the old default corner spot, so clicking it after picking the moles gives you a second copy.

## BLOCKED — need more info from the maintainer

# RTT Work Queue
## Standing rule: work on MAIN
## Standing rule: this file only shows OPEN work
## Note for future sessions: the `m###` labels are HISTORY, not files
## Golden rule (the maintainer, repeated + hardened)
## STRUCTURAL — the pattern behind most of today's bugs (2026-09-04)
## OPEN — 2026-09-04
- [x] **Fuse the Mini-Mood Manager into the rats board.** Done 2026-09-04. The manager is now PRINTED
      INTO the rats board art (`assets/board/rats_board_mood.png`, served by jsDelivr from main, same
      as `board_clean_v3.png`), so it is one board, not a tile stacked on one. Only the eight mood
      cards still spawn, and they land on the printed slots.
      How the placement was derived: the manager's own art shows its slot columns at +-234 px for the
      +-3.425 world units of the saved card positions -> 68.0 px per world unit, which also matches the
      row spacing (125 px / 1.845). That pins the TTS tile constant at ~2.006 and puts the panel at
      board-local (-5.993, +4.829) -> paste top-left (870, 677) in the 1598x1240 board image. The
      manager image is 673x542 and needed to be 672x541, so it is a 1:1 paste with no resampling.
      Round-trip back to seat-local reproduces his saved manager position to 0.004 world units.
      A plain rectangular paste showed a seam (its background differs from the board's by 32-49/255),
      so the pink mountain background is masked out by hue and only the parchment panel is composited.
      NOT YET CONFIRMED IN TTS -- iterate on the placement if it reads wrong in game.

## BLOCKED — need more info from the maintainer
