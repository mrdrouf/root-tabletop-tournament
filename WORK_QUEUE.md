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

### Draft / seating flow (interrelated — investigating)
- [ ] **Knave Captains**: do NOT spawn the 4 random captains with the faction-selector board. They
      must appear immediately BELOW the drafting cards DURING the draft.
- [ ] **Remove pick-map / pick-deck**: delete the "player 1 picks map/deck, then player 2…" flow
      entirely (Adrien does map/deck manually). Instead a faction-selector board appears for ALL
      players immediately.
- [ ] **Simultaneous faction choice**: ranked & theme draft should deal the factions and let EVERY
      player choose from their own faction board at once — NOT sequential player 4→3→2→1.
- [ ] **Ranked 2-player bug**: with ranked + only 2 players, only 2 faction boards spawn (should be
      the full set regardless of player count). Setup must NOT branch on player count. Adrien can't
      reproduce/observe this himself (needs 2 humans).
- [ ] **Seat on turn-order card**: seat each player the moment they RECEIVE their turn-order card
      (not when they click a faction). Deal the card straight into the seated player's hand (hidden),
      not face-up/open for everyone to see first. Investigate + resolve — flagged important.

### Maps / landmarks
- [ ] **Marsh 5-player map button** (= "Swole Birds"): the button already exists (id `Marsh5P`,
      onclick `rttFivePStart`, already drives Marsh-in-5p) — only art/label changes. Needs a 400×200
      `assets/upload/marsh_5p_label.png` (Marsh art left, "Marsh / 5 Players" right, cream serif),
      then repoint the `FivePlayerArt` URL (m540 SWAPS) + set the button `color="#ffffff"` (m500
      MARSH5P_NEW). Waiting on the image.
- [ ] **Mountain landmark direct spawn**: the landmark model+card ALREADY spawn directly; the flash
      is the central *Clearing Marker* (suit token) spawning visible then being destruct+replaced.
      Fix (clean): drop the central clearing-marker data entry at build time (m445-style filter on
      Mountain), so only 11 markers spawn + shuffle; `rttMountainLandmark` then stops reading a
      marker and just spawns the landmark. (m500 rttMountainHideTower / m490 rttMountainLandmark.)
- [ ] **Landmark explanation cards — flip**: one token — m490:543 `rttSpawnLandmarkAt(... 165, 0 ...)`
      -> `165, 180` (Mountain card to RULES/BackURL face). Marsh 5p towns already pass 180 (correct).

### Draft path — remaining golden-rule cleanups (fold into the draft rework)
- [ ] **Crows plots/warriors**: rttCrowsPlots respawns plots face-down + repositions warriors at
      runtime — convert to blueprint (bake warrior move_to, and set plot facing in the data). Corvid
      wasn't set up when mapped; re-read once it is.
- [ ] **Knave captains**: moving to the draft-card stage anyway (see draft item) — spawn directly.

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
