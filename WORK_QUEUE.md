# RTT Work Queue

Single source of truth for outstanding tasks. Nothing is "done" until it's built, committed, and
Adrien has confirmed it in TTS. Keep this file live: add every new request here the moment it lands,
tick items only when committed, and re-open anything Adrien reports still broken.

## Golden rule (Adrien, repeated + hardened)
**Fix the BLUEPRINT, never patch at runtime.** No dirty tricks — no spawn-then-move, no
spawn-below-the-table-then-reveal, no runtime tuck. Modify the faction's data so every piece
starts in its final container/position:
  - seat-relative pieces (warriors/buildings by the board): bake move_to (m290/m300/m560/m570).
  - "extra" pieces that belong in supply: MOVE them into the bag's ContainedObjects in the data
    (framework.stow_loose_in_bag) — they spawn inside the bag.
  - map-relative pieces (cats on clearings, The Pond): take from the supply bag / spawn the object
    JSON directly AT the final world spot — never a seat-local default first.

## OPEN

### Randomization TIMING / RNG (Adrien: "very dangerous") — DONE
- [x] Seed RNG once at load, advance per call; removed per-click os.time reseeds (rttMarshPlan /
      rttMarshPlan5P). Fast re-clicks now re-randomise instantly (floods).
- [x] Mountain landmark: Wait.frames(2) (fast), self-clears old landmark, advancing RNG.
- [x] Marsh number tokens: rest on the board (RTT_MARSH_TOKEN_Y 11.635), not floating.

### Draft / seating flow — DONE (needs Adrien's TTS test; big change)
- [x] **Remove pick-map / pick-deck**: rttBeginPick skips the pick, spawns boards immediately (Adrien
      places map/deck manually). The 5-player button still auto-places its Marsh map.
- [x] **Fixed board/seat count** = RTT_DN-1 (4 ranked / 5 for 5p Marsh), independent of live players
      (RTT_ORDER is built with N entries; empty seats allowed). Fixes the 2-player bug.
- [x] **Auto-seat on turn-order card**: order deck spawns BELOW the table (never face-up); random turn
      order; rttSeatAndDeal moves each real player's HAND to their seat (keeps their color) and deals
      the card into that hidden hand.
- [x] **Simultaneous faction choice**: rttShowFactions lights EVERY board at once; rttCoordFaction
      resolves by the clicked BOARD (fixed faction slots, no race), first click takes it, refreshes the rest.
- [x] **Knave Captains**: rttDraftKnavesCaptains spawns 4 random captains under the draft cards during
      the draft; removed from the faction-spawn (rttFactionExtras + rttCoordFaction hand-deal).
  NOTE to verify in TTS: seat/hand positions, Knave-captain offset (x 57.9), that cards land hidden,
  and that a real 4-player draft still resolves cleanly.

### Maps / landmarks
- [~] **Marsh 5-player map button** (= "Swole Birds"): button already wired (id `Marsh5P`,
      onclick `rttFivePStart`, drives Marsh-in-5p). Draft label composed:
      `assets/upload/marsh_5p_label.png` (5-player art left + "Marsh / 5 Players" right, label family
      style). NEXT: Adrien uploads it to Steam -> give me the URL -> repoint `FivePlayerArt` (m540
      SWAPS) + set button tint in m500 MARSH5P_NEW. Waiting on Adrien's upload + URL.
- [x] **Mountain landmark direct spawn** (DONE): m590 removes the central clearing marker (1b3b99)
      from the Mountain data at build time (11 markers spawn, shuffleMaps is count-safe);
      rttMountainLandmark no longer reads/destroys a marker — spawns a random landmark directly.
- [x] **Landmark explanation cards — flip** (DONE): m490 Mountain landmark now passes crotZ 180
      (RULES/BackURL face up). Marsh 5p towns already correct.

### Golden-rule cleanup — needs a verified read
- [ ] **Crows warriors**: rttCrowsPlots repositions the 4 Corvid Warriors at runtime (place-then-
      adjust). The plots already spawn face-down directly (fine); the bot card is just removed (fine).
      To bake the 4 warriors (blueprint GUIDs 653be4/8b4f9c/d78475/b66f9e) I need Corvid SET UP in a
      TTS save so I can recover their move_to the verified way (like bats/Marquise) — RTT_CROW_WAR is
      board-local and the spawn frame is ambiguous, so don't bake it blind. **Action: Adrien, set up
      Corvid once + save, then I bake it.**

## DONE (this session, pending Adrien's confirmation in TTS)
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
