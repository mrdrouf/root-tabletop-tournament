# RTT — every button on the setup board

The setup board is the object nicknamed **Faction Selection** (GUID `bab7e1`). Its buttons are declared
in its `XmlUI` (`gen/src/save.json`) and every `onclick` resolves to a function in `gen/src/logic.lua`.

Layout, top to bottom:

```
[ROOT logo]                                by MrDrouf, Ehss & slugfacekillah
              [4 Players] [Ranked] [Theme]                                     y =  60
[Summer] [Lake] [Marsh] [Winter] [Mountain] [Gorge]                            y =  25
                 [Standard] [Exiles] [Squires]                                 y = -12
[Faction Select][Battle Mat][Koffin Keeper][Box Score][Clearing Mk][Vagabond]  y = -38
[Lizard Wizard][Mini-Mood][Mob Lobber][Landmarks][5-Player Ranked][Marsh 5P]   y = -56
[Mole Monger]                                                                  y = -74
                                                            [info bar]         y = -85
```

---

## Start a game

These four are **destructive** — they clear the current game. Each asks first: one click turns the
button red and reads *"This will reset all factions."*, a second click within 3 seconds goes ahead, and
it reverts on its own if you leave it. **If there is nothing to wipe, there is no prompt** — the button
just runs. Clicks are ignored while a setup is still loading (they are dropped, never queued).

| Button | Handler | What it does |
|--------|---------|--------------|
| **4 Players** | `rttArmFour` → `setupFactionBoards` | Spawns four manual faction-selector boards, one per seat. No draft, no seating, no turn order — you pick each faction yourself. Also spawns five boards when invoked with `fivePlayerSetup`. |
| **Ranked** | `rttArmRanked` → `rttSetup` | The full ranked draft: random seat + turn order per player, a light selector board per seat, colour/hand/turn-order card dealt, then the faction draft. Pool is 1 Militant + others. |
| **Theme** | `rttArmTheme` → `rttTheme` | This month's RTM theme, currently the 5-player Marsh ranked draft (delegates to `rttFivePStart`). |
| **5-Player Ranked** | `rttArmMarsh5P` → `rttFivePStart` | 5-player Marsh ranked draft: Marsh map, 6-card draft. |

**Marsh 5 Players** (`rttPlaceMarsh5P`) places *only* the 5-player Marsh board — no draft, no seating.
It is not destructive, so it does not prompt.

## Maps

**Summer · Lake · Marsh · Winter · Mountain · Gorge** — all `makeMap`. Each clears the previous map
(everything tagged `Map Object`), spawns the board, and runs its hooks: fixed clearing-priority markers;
Marsh number tokens and flood randomisation; the Mountain central landmark and tower removal; the
Battle Mat; and any VP markers still waiting for a score track.

## Decks

**Standard · Exiles & Partisans · Squires & Disciples** — all `makeDeck`. The small-count variant loads
automatically in a 1–2 player game.

## Tools

| Button | Handler | What it does |
|--------|---------|--------------|
| **Faction Select** | `makeFactionSelector` | Spawns one manual selector board (the 12-faction + Knaves picker). |
| **Battle Mat** | `makeBattleMat` | Toggles the battle mat. Tagged `Map Object`, so placing a map replaces it rather than stacking a second one. |
| **Koffin Keeper** | `makeTool` | Spawns the Koffin Keeper. |
| **Box Score** | `rttSpawnBoxScore` | Spawns the live box score sheet (destroys any previous one first). |
| **Clearing Markers** | `makeTool` | The clearing-marker set. |
| **Vagabond Cards** | `makeTool` | The Vagabond character cards. |
| **Lizard Wizard** | `makeLizardWizard` | The Lizard Wizard plus its blocker. |
| **Mini-Mood Manager** | `makeTool` | Rats / Lord of the Hundreds mood tracker. |
| **Mob Lobber** | `makeTool` | The Mob Lobber. |
| **Landmarks** | `makeTool` | The landmark pieces. |
| **Mole Monger** | `makeTool` | Spawns the Mole Monger. |

**Ginso's Gizmo has no button.** It is always active with no object on the table — its script is part of
the board, so **NUMPAD 0** returns a hovered component to its supply and **NUMPAD 1** reassigns that
component's destination, in every game, with nothing to spawn or toggle.

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
