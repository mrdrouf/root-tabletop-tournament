# Root Tabletop Tournament — to-do

Ordered backlog. Newest big items at the bottom.

## Done (recent)
- **Lizard / Duchy warrior placement** — DONE (`m290`/`m300`).
- **Errata pipeline** — DONE (`m310`).
- **Full RTT draft flow** — DONE (`m470`, building green): lightweight per-player
  selector boards (no menu-board clone → no lag); P1 picks map OR deck, P2 picks the
  leftover; 5 cards dealt one-by-one to each seated player from the chosen deck;
  reverse-order (P4→P1) faction draft off the 5 drafted factions on each own board;
  board removed then faction spawned (no dice; warriors baked in); Woodland supporters;
  Knaves → 4 random Captains; VP marker placed on score-track column 0 (stacked).
- **Box score integrated + auto-spawned** — DONE (`m470`): embedded `_boxscore.json`,
  spawns locked at (63.9, 11.6, -32) when the faction draft starts. *(position pending
  Adrien's visual OK.)*
- **Priority markers, all fixed-clearing maps** — DONE (`m460`): Summer/Autumn, Lake,
  Mountain, Winter, Gorge auto-place their locked 12-marker layout on map spawn;
  "Priority Marker" hover nickname blanked.
- **Board texture credit removed** — DONE (`m360`, v3): baked "Board by …" credit gone,
  fake-3D vignette border preserved (0.0 diff).

## Blocked on Adrien (need a Steam Cloud upload or an in-TTS confirmation)

1. **Ranked (owl) + Theme (fox) button art** — the two composites are FINAL and correct
   (`assets/images/ranked_button.png`, `theme_button.png`, 150×150 **RGBA**). The URLs
   `m480` currently points at are the *old 300×300 **RGB*** uploads — RGB is exactly why
   the icon renders white. Fix = Adrien uploads the two RGBA PNGs via TTS Cloud Manager;
   Claude then recovers the Steam URLs by SHA1 and wires them into `m480`.
   (RGBA sha1: ranked `23F7EB22…`, theme `FE0894D6…`.)

2. **Marsh (spoken "March") flood-aware priority numbering** — 15 tokens recorded in
   `_priority_marsh_raw.json`. Measurement is solid (each of the 6 flood-candidate
   clearings has a unique nearest token, 3–4u), BUT the 15→12 rule Adrien intends does
   not match the simple "each flood pair shares one number" model — simulating "drop the
   token under each flood tile" leaves some numbers doubled and some missing. **Need
   Adrien to explain the rule** (which token is the alternate for which, and what the
   flood outcome does to each). Question posed to Adrien.

3. **4-player / 5-player setup-button art** — still a text placeholder ("5 Players",
   `m240`). Needs a top-down board screenshot from Adrien + a Steam upload.

4. **Selector title font** — "Pick a MAP or a DECK" / "Pick the MAP/DECK" already render
   in one consistent UI font. Matching the *map-label (Mason)* font needs a hosted TTF
   as a UI font asset (same Steam-hosting blocker + fiddly). Optional — confirm if wanted.

5. **In-TTS visual verification** — VP-marker stacking order in column 0 (spec: zero,
   then above, then below, then further up), Knaves→4 Captains, box-score placement.
   Needs Adrien to run one game and eyeball.
