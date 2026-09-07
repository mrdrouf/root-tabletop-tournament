# RTT — every button on the setup board

The setup board is the object nicknamed **Faction Selection** (GUID `bab7e1`). Its buttons are declared
in its `XmlUI` (`gen/src/save.json`) and every `onclick` resolves to a function in `gen/src/logic.lua`.

Layout, top to bottom:

```
[ROOT logo]                                                                    y =  76.5 [x]
        [4-Player Setup] [4-Player Draft] [Theme]                              y =  51.5
[Summer] [Lake] [Marsh] [Winter] [Mountain] [Gorge]                            y =  16.5
                 [Standard] [Exiles] [Squires]                                 y = -23.5
[Faction Sel][Bat Bungler][Mob Lobber][Koffin Keeper][Faction Cards][Landmarks] y = -55
[5P Setup][5P Draft][5-Players Marsh][Turn Panel][    ][Credits]               y = -78
                                                         [Clear All]           y = -88.5
```

Every row sits half an option button (8.5) lower than it used to, so the top row clears the ROOT logo.

---

## Start a game

These are **destructive** — they clear the current game, and the map with it. Each asks first: one click turns the
button red and reads *"This will reset all factions."*, a second click within 3 seconds goes ahead, and
it reverts on its own if you leave it. **If there is nothing to wipe, there is no prompt** — the button
just runs. Clicks are ignored while a setup is still loading (they are dropped, never queued).

| Button | Handler | What it does |
|--------|---------|--------------|
| **4-Player Setup** | `rttArmFour` → `setupFactionBoards` | Spawns four manual faction-selector boards, one per seat. No draft, no seating, no turn order — you pick each faction yourself. Also spawns five boards when invoked with `fivePlayerSetup`. |
| **4-Player Draft** | `rttArmRanked` → `rttSetup` | The full ranked draft: random seat + turn order per player, a light selector board per seat, colour/hand/turn-order card dealt, then the faction draft. Pool is 1 Militant + others. |
| **Theme** | `rttArmTheme` → `rttTheme` | This month's RTM theme, currently the 5-player Marsh ranked draft (delegates to `rttFivePStart`). |
| **5-Player Draft** | `rttArmMarsh5P` → `rttFivePStart` | 5-player Marsh ranked draft: Marsh map, 6-card draft. |
| **5-Player Setup** | `rttArmFiveSetup` → `setupFivePlayerBoards` | Five manual selector boards and nothing else -- the 5-player counterpart of 4-Player Setup. |

**5-Players Marsh** (`rttArmMarsh5PMap` → `rttPlaceMarsh5P`) places *only* the 5-player Marsh board —
no draft, no seating. It IS destructive: it goes through `rttPlaceMap` → `makeMap` → `removeMapItems`
like any other map placement, so it prompts when a map is already down. This page used to claim the
opposite, which is how it stayed the one destructive button with no warning.

**What the prompt says depends on what is at stake.** A setup button clears the factions *and*, since
a new game re-places the map (`rttRefreshMap`), the map. With factions on the table it reads *"This
will reset all factions."*; with only a map down it reads *"This will reset the current map."* instead,
rather than promising to reset factions that are not there.

## Maps

**Summer · Lake · Marsh · Winter · Mountain · Gorge** — all `makeMap`. Each clears the previous map
(everything tagged `Map Object`), spawns the board, and runs its hooks: fixed clearing-priority markers;
Marsh number tokens and flood randomisation; the Mountain central landmark and tower removal; the
Battle Mat; and any VP markers still waiting for a score track.

## Decks

**Standard · Exiles & Partisans · Squires & Disciples** — all `makeDeck`.

This page used to claim "the small-count variant loads automatically in a 1–2 player game". It did
not, and could not: `makeDeck` branches on `ends_with(id, "2")`, but no button id ends in `2` and
nothing anywhere builds one, so `Standard Deck 2` and its siblings had no path to load. That inherited
base-mod data was removed on 2026-09-06 (165 KB). The branch is harmless and stays, in case the
variant is ever wired up on purpose.

## Tools

| Button | Handler | What it does |
|--------|---------|--------------|
| **Faction Select** | `makeFactionSelector` | Spawns one manual selector board. Page 1 holds the eleven whole factions plus a **Vagabond & Knaves** button; that button opens the base mod's combined page — the twelve Vagabond characters *and* Knaves of the Deepwood. Only the MANUAL boards have that page: the ranked draft deals from `RTT_SELECTOR_JSON`, which has no Vagabond UI at all. |
| **Koffin Keeper** | `makeTool` | Spawns the Koffin Keeper. |
| **Box Score** | `rttSpawnBoxScore` | Spawns the live box score sheet (destroys any previous one first). |
| **Clearing Markers** | `makeTool` | The clearing-marker set. |
| **Lizard Wizard** | `makeLizardWizard` | The Lizard Wizard plus its blocker. |
| **Mob Lobber** | `makeTool` | The Mob Lobber. |
| **Landmarks** | `makeTool` | The landmark pieces. |
| **Bat Bungler** | `makeTool` | Spawns the Bat Bungler (Nevakanezah content, like the Mob Lobber). Sits in the slot the Mole Monger used to hold. |

**The Vagabond Cards button is gone** (2026-09-05). Its twelve character cards now spawn with
**Faction Cards**, in a second row behind the captains deck at (50.225, 28.681) -- the maintainer's own
spot, from his save 'faction'; picking a Vagabond manually already brings that character's own meeple
and card, so the tool's 21 spare meeples were duplicates. Credits moved up into the freed slot at x=57, so the two empty slots are now the two rightmost of the
SECOND tool row (x=57 and x=95, y=-78) -- the maintainer asked for the gaps to sit there.

**Turn Panel** (`rttToggleTurnPanel`) swaps the clock and counter for a single parchment panel that
shows the ROUND (read from the box score, so the two counters cannot drift) and a clock for the turn in
progress, plus START TURN 1 and a DEAL 5 CARDS button that removes itself once used. Pressing it again
puts the clock and counter back. It is an OPTION while the panel is still being shaped -- the maintainer,
2026-09-07: "make an option button for that so while we work on it the rest can keep being functional."

**Ginso's Gizmo has no button.** It is always active with no object on the table — its script is part
of the board, so it works in every game with nothing to spawn or toggle.

**NUMPAD 0** is the key, as it always has been. Hovering a warrior — anyone's — sends it home to that
faction's own supply. Hovering nothing takes one warrior out of YOUR supply, standing up, at your
pointer; which supply is yours comes from where you are seated. An empty supply does nothing.

That is a TTS *scripting button*, which is numpad-bound, so **on a laptop with no numpad** (a MacBook,
where the top-row 0 is a different key and needs Shift on a French layout) bind the named hotkey
**"Gizmo: warrior to / from your supply"** in *Options → Game Keys*. It is registered unbound, so on a
machine with a numpad there is nothing to configure.

---

## Things worth knowing

- **The credit** (top right) is a rendered image, not live text. TTS draws UI text into a
  fixed-resolution texture, so small type is unavoidably blurry; an image is not.
- **What a new game clears**: everything tagged `RTT Selector`, `RTT Manual Selector`, `RTT Faction` or
  `RTT Pond`, plus the run state and the per-colour supporters hand zones. Map and deck objects belong
  to the map/deck buttons and are cleared by those instead.
- **The markup is inconsistent** and it matters when grepping: most buttons use `onclick`, but
  *Summer Map* uses `onClick`, and *Landmarks* has a space (`onclick ="makeTool"`). Any tooling that
  scans the XmlUI must allow for all three forms.
- **The Battle Mat and the Mini-Mood Manager no longer have buttons.** Both are spawned automatically:
  the battle mat with the map, and the box score alongside it. The Mini-Mood Manager spawns with the rats.
- **Two buttons are not tools**: `x` (`deleteThis`, top right) removes the setup board itself, and
  **Clear All** (`clearAll`) wipes the table.
- **The Mole Monger has no button.** It spawns with the Underground Duchy, beside that seat.
- **Every label is generated by `tools/relabel.py`.** One table describes each button's artwork,
  caption and geometry; run it to re-render, re-publish (content-hashed, because jsDelivr caches by
  URL) and rewrite `gen/src/save.json`. A caption too wide is CONDENSED to 0.80 before it is set any
  smaller — that is the only reason long names like "Squires & Disciples" can grow at all.
- **Button art carries its own caption**, so renaming a button means new art. The asset NAMES are
  historical: `RankedArt` now reads "4-Player Draft", `FourBoardsArt` reads "4-Player Setup", and
  `FivePlayerArt` reads "5-Player Draft".
- **Credits** (`rttShowCredits`) replaces the menu with a rendered parchment page listing every
  contributor, and **Back** (`rttHideCredits`) returns. The page is an IMAGE, not UI text: TTS renders
  UI text into a fixed-resolution texture, so small type is blurry -- the same reason the old corner
  credit was an image. The board itself no longer carries a baked credit.
