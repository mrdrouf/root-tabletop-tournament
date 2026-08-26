# Root Tabletop Tournament — to-do

Ordered backlog of requested work not yet built. Newest big items at the bottom.

## Done (recent)
- **Lizard warrior placement** — DONE (`m290`): 4-pack + 3-pack by the supply +
  2 in the acolyte box.
- **Underground Duchy warrior placement** — DONE (`m300`): pack of 2 + pack of 5.
- **Errata pipeline** — DONE (`m310`): drop a corrected object into `errata/` and
  the build repoints the matching card sheets to the fixed art.

## Big item — full RTT draft flow (spec captured 2026-08-19)

**Decisions confirmed 2026-08-26 (supersede any conflicting text below):**
- **Faction draft pool = the 5 cards `rttSetup` already dealt** (players+1, militant-first),
  NOT an open pick from all 12. Reverse order, 1 card left over. Selector shows only the 5.
- **Map/deck = free + leftover:** P1 picks a map OR a deck from one combined grid; P2 then
  picks whichever category is left. (Not fixed P1=map/P2=deck.)
- **Direction = single reverse pass** P4→P3→P2→P1 (NOT an actual snake).
- **Build order:** (0) capture turn order into `RTT_ORDER` [prereq for all gating];
  (1-2) map/deck pick; (3) 5-card faction draft; (4) VP markers; (5) box score.
- **Architecture (Adrien 2026-08-26):** NEVER touch the central menu board. The
  central board is a hidden COORDINATOR (GUID bab7e1) that clones one faction-selector
  board in front of each seated player (`getPosition`), and drives each clone's UI.
  Clones run their own Lua context, so their buttons RELAY clicks back to the
  coordinator via getObjectFromGUID(bab7e1).call(...). Map/deck buttons use the REAL
  setup-board icon art (persistent CustomUIAssets survive on clones). The faction
  selector will be the base `standardButtons`, trimmed to the 5 drafted factions with
  no bots/fan/setup/rules, revealed board-by-board in reverse order.
- **Progress:** m470_rtt_draft_pick reworked to the clone architecture — spawns 4
  per-player boards + P1/P2 map+deck pick with real art, coordinated by relay. NEXT =
  phase 3 (reverse-order faction draft off the 5 dealt cards on those same clones:
  restrict standardButtons to 5, reveal P4->P1, setupFaction consumes each clone),
  then phases 4-5 (VP markers + box score). NB: order-card FACES may not read 1..4
  (cards carry no ordinal; RTT_ORDER authoritative, order shown via UI + broadcasts).

After `rttSetup` deals the 5-card draft, run a guided reverse-order draft:

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
   ONLY the **5 drafted factions** (decision 2026-08-26) on their OWN selector board;
   picked factions are removed for the next player. (P1 picks last.) `setupFaction`
   already consumes the clicked board into that faction's setup at the seat.
   - **Knaves special:** if Knaves of the Deepwood is drafted, after its setup draw
     **4 random Captain cards** from the Knave faction board's captain deck (an extra
     line in the faction-place step).
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
- **RTT Draft button = owl art + "ranked":** Adrien pasted a HOOT-owl image (dark
  blue speckled bg, a stray white parchment box top-left to blend into the bg) to use
  as the RTT DRAFT button, with "ranked" written below in the map-button font
  (= Mason, at C:\Windows\Fonts\MasonSer*.ttf). BLOCKED twice over: (1) the pasted
  image isn't saved to disk anywhere Claude can read — need the actual file; (2) a UI
  button icon must be Steam-hosted (non-Steam UI icons blank in TTS), so the finished
  composite has to be uploaded to Steam Workshop for a URL. Plan once unblocked:
  blend the white box into the speckled bg, add "ranked" in Mason below the owl,
  export, host on Steam, wire as the RTT DRAFT button icon.
