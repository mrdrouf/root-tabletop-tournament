# Root Tabletop Tournament — changelog

Forked from Root – Ultimate Collection (Steam Workshop `2516434159`), base v13.3.
One line per change, oldest first. The build number is in `VERSION`, shows in the
setup board's top right corner, and goes up on every commit.

## 2026-08-19
- Rebranded the save and game mode as Root Tabletop Tournament.
- Removed 12 standalone menu tools and their dead handlers.
- Removed 21 fan maps; kept the 7 official ones.
- Removed 6 fan deck families; kept Base, Exiles & Partisans, Squires & Disciples.
- Removed all 6 scenarios.
- Faction setup no longer spawns battle dice.
- Removed the rules manuals and 3 buttons that led nowhere.
- Removed Weird Root, Super Auto Smash Up, Advanced Setup and Law of Slug from the menu.
- Standard setup spawns 4 selectors, not 6.
- Removed Fandmarks, the GSG tournament draft and the advanced draft.
- Removed the Master Instructions PDF.
- Bats: all six assemblies face down, the odd one moved into the row.
- Autumn map replaced by Summer, which randomises its clearing suits.
- Menu compacted onto one page; empty nav tabs removed.
- Selectors spawn in the four table corners; the 5th seat sits near-middle.
- 5-player setup button added.
- RTT draft: 1 random Militant + 4 from the rest, dealt to five slots, flipped together.
- Lizard and Duchy opening warriors baked in from the maintainer's save.
- Errata pipeline: drop a corrected card save in `errata/` and its face art is repointed.
- Hand-written "+ MrDrouf & Claude" credit added beside the baked board credit.

## 2026-08-20
- `tools/preview_menu.py` renders the menu to a PNG, so layout is judged without TTS.
- Setup actions became wooden plaques; rows re-spaced to fill the board.
- Fixed mirrored Lizard and Duchy warriors — the rotation was applied backwards.

## 2026-08-25
- Clean board art: the baked artist credit painted out, banner and stray labels removed.

## 2026-08-26
- Marsh: map objects were never tagged, so they were never cleared between games.
- Marsh: pieces spawn at their exact measured positions, settling before they lock.
- Marsh: spawned landmarks removed; flood heights corrected.
- Draft moved onto per-player selector boards, cloned from the setup board.
- Draft deals from the full faction deck and leaves the rest on the table.
- Clearing-priority markers auto-place with the Summer, Autumn, Lake and Mountain maps.
- Board texture v3: credit removed without eating the border, wood grain intact.
- Selector boards made lightweight — the 4.3 MB clone is gone.

## 2026-08-27
- Mountain landmark detects the middle clearing's suit and spawns in place.
- 5-player Marsh draft: towns on clearings, five boards, fifth turn-order card.
- Faction setups baked into the blueprint — no more spawn-then-move.
- Marquise Keep enlarged; cats stand on true clearing centres.
- Duchy tunnels, crow plots and the frog pond fixed to spawn where they belong.
- Box score locked to the maintainer's rectangle, fixed 4/5-player format.
- Button icons redone in Book Antiqua and wired to the uploaded art.
- Fixed white icons: `onLoad`'s `setCustomAssets` was stomping the setup UI.

## 2026-08-28
- Replaced the base `shuffle()`, which reseeded from `os.time()` 101 times a call.
- Seating restored to the base pattern: seat on the turn-order card, by card number.
- Order deck stays on the table; the draft no longer deals starting hands.
- Knaves captains unlocked and laid in a line; the source deck stays hidden.
- Crow warriors and supply baked in; the hidden zone follows the board's side.
- Marsh 5-player button replaced Swol Birbs and took its slot.

## 2026-08-29
- Cold load fixed: the setup board carried 541 UI assets, over TTS's limit, so its
  buttons painted blank on a first load. Trimmed to the 147 it actually uses.
- Repo made self-contained: `gen/` owns the whole mod, no external base.

## 2026-09-04
- One new-game path, `rttNewGame`, for both the draft and the manual picker.
- `rttResetRunState` is the single list of state a new game clears.
- Teardown absorbed the draft objects, which only the ranked path used to clear.
- Alliance supporters are dealt again in games with the frogs in the deck.
- Frog cards are pulled back out of the shared deck at each new game.
- Knaves keep their captain deck when picked from a manual selector.
- `rttPoolCaptains` fixed — it read a positional array by field name and always threw.
- Winter relic positions baked in; it was the only map falling back to forest centroids.
- Drawn captain cards are tagged, so they go out with the faction.
- Mini-Mood Manager printed into the rats board art, with its snaps and resize script.
- Mole Monger spawns with the Duchy, on the mole player's own side of the table.
- Corvid warriors moved to the maintainer's recorded positions.
- Fifth Player turn-order card added.
- Credits screen replaces the baked corner credit.
- Wipe warning enlarged.

## 2026-09-05
- Seat identity recorded once, on the event, and persisted through `onSave`.
- Box score seat record and explicit round baked into the mod.
- Gizmo rewritten: numpad 0 sends the hovered piece home, numpad 1 takes a warrior.
- Gizmo reads the supply from the table, not from a runtime global.
- `tools/update_saves.py` pushes the current build into the maintainer's saves.
- Camera states use the host's.

## 2026-09-06
- Landmarks wait for the map board instead of a fixed 1.4s delay.
- Marsh 4-player after 5-player rebuilds the flooded board — the test was on the flag.
- A DRAW button on every faction board (later reverted, pending a design).
- Gizmo home fills the rightmost empty slot of a kind, not the piece's own spot.

## 2026-09-07
- Turn panel replaces the clock and counter: round, per-turn time, START and DEAL 5.
- Turn panel flashes red at 20 minutes; its button swaps back to the old clock.
- Box score records each player's previous turn time and writes DOM WIN on two lines.
- START no longer records a phantom first turn, and only warns once there is data.
- Removed 0.89 MB, 0.3 MB and 94 KB of unreachable blueprint, and 46 MB of assets.
- Removed 445 unused UI assets, 9 dead functions and 3 dead asset entries.
- Seat colour is forced to turn-card order.
- Faction board's art now downloads with the table, so it no longer spawns blank
  on a first load.
- Placement no longer divides by the board's live scale, which is not settled until
  its picture has downloaded — that was the map and items landing all over the place.
- Numpad 0 acts on your own faction's pieces only.
- Numpad 2 lays any warrior down: tipped over, cream, locked; again to undo.
- One cream everywhere: `#F9E6BB`.
- Build number added, cream, top right of the setup board; it bumps on every commit.
- Numpad 3 highlights a piece; numpad 2 draws a disc in the presser's colour under it.
- Turn panel's DEAL 5 becomes PAUSE, then CONTINUE, once the game has started.
- START shuffles the deck once.
- Seat colour, owner and faction now have one writer each, so a reload keeps them.
- The round advances when the table comes round, not when a turn repeats.
- A locked score is keyed by seat and round, so a repeated turn event overwrites it.
- Box score re-reads the seats on a real event, not on a timer, so typed names stay.
- START names the turn pass it causes, so it never records a turn for the outgoing seat.
- A setup button no longer touches the map; only a Marsh needing the other board is rebuilt.
- The box score and turn panel are never destroyed or respawned by a map change or a new game.
- A button warns only about what it will really do.
- Which map is on the table is saved, so a reload can still re-place it.
- New mod icon: the Root sign re-lettered "Tabletop Tournament" in Luminari, a real board screenshot, black ground.
- Numpad 3's highlight is black, so it separates from the warrior and the map instead of matching them.
- Numpad 2 lays a warrior down and outlines it in black; the disc under the piece is withdrawn, and numpad 3 does nothing.
- Every map locks its ruins once placed, not just the Marsh.
- Keepers: the 8 warriors and the Relics bag spawn where the "keepers" save has them, all on one side.
- Badger relics are drawn from a Lua shuffle and placed one per frame, so which relic goes where is genuinely random.
- Marquise cats drop into their clearings from clear air, so they land on ruins and relics instead of shoving them aside.
- Mountain clearing numbers sit where the "mountain" save puts them; eight of the twelve were misplaced.
- Frog dominance is recognised: a VP marker on the Frog card now declares dominance like any other suit.
- DOM WIN is written into the score box on two lines; the button itself is one line again.
- The live score tracker shows the dash during dominance, or the running score under Brazen Demagogue.
- An enclave lands on the suit symbol when militant, and beside it when peaceful, keeping its face up or down.
- Flipping an enclave slides and turns it between the two spots, lifted clear of the board as it crosses.
- Enclaves are 10% smaller.
