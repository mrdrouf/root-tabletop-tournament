# RTT Work Queue

Single source of truth for outstanding tasks. Nothing is "done" until it's built, committed, and
the maintainer has confirmed it in TTS. Keep this file live: add every new request here the moment it lands,
tick items only when committed, and re-open anything the maintainer reports still broken.

## Note for future sessions: the `m###` labels are HISTORY, not files
There is no `gen/mods/` directory and there never has been one in git history. The build is three
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

## OPEN — new batch (2026-08-29)
- [x] **Battle mat** (DONE, VERIFY): the live flow was already single-spawn -- rttPlaceMap spawns the
      mat tagged "Map Object" and makeMap's removeMapItems() destroys that tag before each placement.
      The real duplication vector was the **Battle Mat TOOL button**: makeBattleMat -> makeSpecial
      spawned it UNTAGGED, so it survived removeMapItems and the next map placement stacked a second
      mat on it. FIX: makeSpecial takes an optional trailing `tag` argument (nil for every other
      caller, so Lizard Wizard etc. are unchanged) and makeBattleMat passes "Map Object".
      toggleSpecial still gives the tool button its click-to-remove. One mat from any path now.
      Dead paths rttCoordPick / rttShowPick still to be REMOVED in the cleanup (see below).
- [ ] **Duchy (moles) tunnel position**: the maintainer moved the TUNNEL when the Duchy spawns and saved it.
      Recover the new tunnel move_to from his recent save (board-frame reproject) + bake into the Duchy
      blueprint so it spawns there every time, from any faction board / setup.
      UNBLOCKED 2026-09-03: the session now runs on the maintainer's Mac, so his TTS Saves folder is
      readable directly (~/Library/Tabletop Simulator/Saves/). Candidate sources: TS_AutoSave*.json.
      NEED: the maintainer to confirm WHICH save has the moved tunnel before anything is reprojected.
- [ ] **Thorough code cleanup** (workflow wbindjqke running): drop obsolete/dead code + bloat, no
      duplication (shared helpers), fix bugs/typos/robustness, well-written. Implement from the plan,
      verify build each step, conservative (proven-dead only).
- [ ] **Easy-install folder** in the GitHub repo: a clear folder with exactly what a new user drops
      into their TTS Saves folder to use the mod. (Deliverable after cleanup.)
- [ ] **Thorough README**: explains the exact function of EVERY button + install + what it changes vs base.
- [x] **Faction buttons alignment -- Knaves offset** (DONE, VERIFY): it is the Faction Select tool's
      `standardButtons` group in the setup board XmlUI (gen/src/save.json), NOT the draft selectors'
      rttFac grid. Columns are x = -25 / 15 / 55 / 95 (40 apart); every other column-4 button sits at
      95 -- **Knaves alone sat at 90**. Fixed to 95, so the group is an exact 3x4 grid.
      STILL OPEN (design call, needs the maintainer): the grid as a whole is centred on x=35, not 0,
      and row 1 is Marquise/Eyrie/Woodland + Knaves alone in column 4 -- so Knaves still reads as
      tacked onto the end of a short row even when perfectly on-grid. Say if you want the grid
      recentred and/or Knaves moved down beside the other base factions.
- [ ] **NEW OBJECT — Knaves captain board** (AFTER the list + cleanup; design carefully, pre-plan so we
      don't iterate): a new object styled EXACTLY like the crafted-improvement board next to each faction
      board, placed to the RIGHT of the current crafted-improvement board, ONLY for Knaves. Holds the 3
      captain cards VERTICALLY with snap areas + elegant labelled areas for Captain 1/2/3, NO overlap,
      enough space. Root design style + the usual font. Base it on the crafted-improvement design, larger.

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
