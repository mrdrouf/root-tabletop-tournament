# RTT Work Queue

Single source of truth for outstanding tasks. Nothing is "done" until it's built, committed, and
Adrien has confirmed it in TTS. Keep this file live: add every new request here the moment it lands,
tick items only when committed, and re-open anything Adrien reports still broken.

## Golden rule (Adrien, repeated)
**Never spawn the old/default version of a piece and then move it.** Spawn the FINAL version directly
— bake seat-relative pieces into the blueprint (m290/m300/m560/m570 pattern), take map-relative
pieces straight from the supply bag to their target, or spawn hidden (below table) and reveal in one
setPosition. No default-then-adjust, ever.

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
- [ ] **Marsh 5-player map button**: add a MAP button "Marsh 5 players" (2-line label, same design as
      the other map buttons, image left + text right) alongside the existing Marsh (4p). It REPLACES
      the "Swole Birds" option. Needs an uploaded left-image asset.
- [ ] **Mountain landmark direct spawn**: still spawns the suit marker first, then drops the landmark
      on it. Spawn the landmark directly — no default-then-move step.
- [ ] **Landmark explanation cards — flip**: they currently show the SETUP face; flip so the RULES
      face is up.

### Carried over
- [ ] **Duchy "moles" tuck**: 8th warrior spawns visible then is tucked into supply → bake it below
      the table + tuck that exact warrior by GUID (in progress this commit).

## DONE (this session, pending Adrien's confirmation in TTS)
- [x] Bats (Twilight Council): 6 warriors + 6 assemblies baked into blueprint (m560); rttBatsSetup removed.
- [x] Marquise: 3 staging warriors baked (m570); removed from rttMarquiseCats.
- [x] Cats: 12 placed on true clearing CENTRES per map (RTT_CLEARING_CENTRES, from eyes geometry),
      taken straight from the supply bag; Marsh skips its 3 inactive clearings.
- [x] The Pond: spawns below the table (m580), revealed at its no-lizard world spot in one setPosition.
- [x] Marsh number tokens: deliberate token positions + skip-and-renumber (m460).
- [x] Marquise Keep enlarged (m550); Lizard wizard direction + Outcast marker (m490).
