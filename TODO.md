# Root Tabletop Tournament — to-do

Ordered backlog of requested work not yet built. Newest big items at the bottom.

## In progress
- **Lizard warrior placement** — bake 2 warriors in the acolyte box + a pack of 4
  and a pack of 3 next to the Lizard supply, using coordinates read from the
  current save (the "fourth layer" Lizard setup). World→move_to conversion.
- **Underground Duchy warrior placement** — same idea, arrangement read from the
  current save.

## Big item — full RTT draft flow (spec captured 2026-08-19)
After `rttSetup` deals the 5-card draft, run a guided snake draft:

1. **Per-player boards.** Every seated player gets their wooden faction board, but
   empty — nothing placed on it yet.
2. **Map/deck pick (player order, snake).** The draft-order cards decide sequence.
   - **Player 1** sees ONLY the pick options (no faction options on the board yet):
     the **6 maps + 3 decks** laid out as a **3×3 square, all buttons the same
     size**, looking clean/centered. P1 clicks a map OR a deck.
   - When P1 picks, that map/deck is placed on the table. Then **Player 2** picks
     what category is left:
       - If P1 picked a **map** → P2 chooses a **deck** (3 deck options centered on
         P2's board).
       - If P1 picked a **deck** → P2 chooses a **map** (6 maps in a **3×2** grid on
         P2's board).
3. **Faction pick (reverse order).** Once map+deck are set, factions are dealt in
   reverse seat order: **Player 4 first**, then Player 3, then 2, then 1. Each sees
   the **12 official factions** (Vagabond + Knaves are meshed into one option, as on
   the current board) and picks one; picked factions are removed for the next
   player. (P1 picks last.)
4. **VP markers pre-placed.** Put every faction's victory-point marker up on the
   board's score track at `zero_point_tracker` (NOT next to the faction boards), so
   the game is ready to score. Place them exactly where the **`root_boxscore`** tool
   (a.k.a. `root_but_score`, in another folder here) can detect them — READ that
   tool's code first to match its expected marker positions.
5. **Auto-spawn box score.** When the map + deck have been picked, spawn the
   `root_boxscore` tool centered **just below the five draft cards**; that is its
   permanent spot for the game. **Lock** it to the board.

## Blocked
- **Setup-button art (4-player / 5-player / RTT):** user pasted a top-down setup
  screenshot to use as the button image, but Claude can't host images. Needs a URL
  (Steam Workshop image or other host) before it can be wired into the assets table.
