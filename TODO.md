# Root Tabletop Tournament — to-do

Ordered backlog. Newest big items at the bottom.

## Done & building green
- **Full RTT draft flow** (`m470`): lightweight selectors, map/deck pick, 5-card deal,
  reverse faction draft, board-removed-then-faction spawn, Knaves captains, box score.
- **RGBA Ranked/Theme buttons** (`m480`) — wired to the 150×150 RGBA uploads.
- **5-player setup button art** (`m240`) — top-down `5players.png` (Steam-hosted RGBA).
- **Box score** (`m470`/`_boxscore.json`) — spawns at the maintainer's placed spot
  (-59.09,11.65,-3.15) rotY270, scaled to fill the board rectangle (~1.3× wide, 1.1× tall).
- **Priority markers** all fixed-clearing maps (`m460`) + **Marsh flood-aware** (drop the
  token on each flooded clearing; `m440` exports `RTT_MARSH_FLOODED`).
- **VP markers** (`m470`) — placed on the score-0 column's real snap rows, rotation
  normalised to the track (fixes far-side upside-down).
- **Per-faction setup extras** (`m490`, dispatched after each faction spawns):
  - *Lizard Cult*: spawn the Lizard Wizard tool, remove the Outcast Marker, shift the
    frogs' Pond aside if it's out.
  - *Lilypad Diaspora (frogs)*: shuffle the 14 frog cards into the shared deck; place The
    Pond by the discard (default spot, or shifted when the Lizard's Lost Souls is in play).
  - *Keepers in Iron (badgers)*: draw one relic per forest from the Relics bag onto the
    forest centroid (extras stay in the bag for manual placement).
  - *Twilight Council (bats)*: place one Assembly on the board's first assembly snap and
    arrange 6 warriors as a pack-of-4 + pack-of-2.
  - *Corvid Conspiracy (crows)*: 12 plots (3 of each type) in a clean 4×3 grid on the board.
  - *Mountain map*: never the Tower — roll a d4; 0 → Lost City, else the middle-clearing
    suit's landmark; place the landmark's rules card at the map's lower-left.

## Needs an in-TTS visual pass / a decision from the maintainer
1. **Mountain middle-clearing suit** — I can't find a suit token in the save to read
   (suits look printed), so `rttMiddleSuit()` returns nil and the roll currently always
   yields **Lost City**. Tell me how the middle clearing's suit is encoded (a token image?
   a nickname?) and I'll wire rabbit→Rabbit-Town / fox→Foxburrow / mouse→Mousehold.
2. **Mountain landmark + card positions** — landmark spawns at your Mousehold spot
   (2.46,11.66,6.03); the rules card goes to a best-guess lower-left (-22,-22). Confirm
   or nudge. (Only the Lost City *rules card* exists in the mod — the other three landmark
   cards aren't present; the landmark model still spawns.)
3. **Bats / Crows placement** is relative to the faction board found at the seat — verify
   the assembly/warrior and the 12-plot grid land cleanly at every seat.
4. **VP stacking / orientation, Lizard/frog shuffle, Badger relic spots** — eyeball once.

## Investigating
- **Spawn "zoom flash"** — big items (map/deck/board) flash a zoomed-in wrong-scale
  version for a split second before settling. Re-investigate whether it's the spawn code
  rescaling after spawn (fixable) rather than pure TTS texture streaming.
