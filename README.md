# Root Tabletop Tournament (RTT)

A tournament build of Root for Tabletop Simulator: one self‑contained save with a streamlined draft
pipeline, random seating, per‑map clearing‑priority markers, faction pieces baked to their final
positions, and per‑faction setup automation. Nothing to subscribe to and nothing to strip at load —
the code assembles the finished save from scratch. All art streams from remote hosts.

---

## Install (players) — one file

> **[`dist/Root_Tabletop_Tournament.json`](https://github.com/mrdrouf/root-tabletop-tournament/blob/main/dist/Root_Tabletop_Tournament.json)**
> · raw: `https://raw.githubusercontent.com/mrdrouf/root-tabletop-tournament/main/dist/Root_Tabletop_Tournament.json`

Drop that one file into your Tabletop Simulator **Saves** folder (no subfolder):

- **Windows:** `C:\Users\<you>\Documents\My Games\Tabletop Simulator\Saves\`
- **macOS:** `~/Library/Tabletop Simulator/Saves/`
- **Linux:** `~/.local/share/Tabletop Simulator/Saves/`

Then **Games → Save & Load → "Root Tabletop Tournament"** and load it fresh (don't "Continue").
(`dist/Root_Tabletop_Tournament.png` is an optional save‑list thumbnail.)

---

## The buttons (setup board)

Only the live tournament controls are on the board; the base game's dead menu subsystems were removed.

### Start a game
| Button | What it does |
|--------|--------------|
| **Ranked** | Ranked draft: players join → **random turn order and random seat** → a light per‑seat board spawns → each seat gets its colour, hand and matching turn‑order card → faction draft. Pool = 1 Militant + others. |
| **Theme** | This month's **RTM monthly theme** — currently the ranked‑draft **5‑player Marsh** setup. |
| **Marsh 5P** | 5‑player Marsh ranked draft: Marsh map (15 clearings, 3 town landmarks + 12 suit markers), 6‑card draft. |
| **Marsh 5P map** | Places **only** the 5‑player Marsh board — no draft, no seating. |

### Maps
**Summer · Lake · Marsh · Winter · Mountain · Gorge.** Each clears the previous map, spawns the board,
and runs its hooks: fixed clearing‑priority markers; Marsh number tokens + flood randomisation; the
Mountain central landmark + tower removal; and, via the draft, the Battle Mat.

### Decks
**Standard · Exiles & Partisans · Squires & Disciples** (the small‑count variant loads automatically in
a 1–2 player game).

### Tools
**Faction Select** (12‑faction + Knaves tile picker for manual setup) · **Battle Mat** · **Lizard
Wizard** · **Clearing Markers** · **Clearing Priorities** · **Vagabond Cards** · **Landmarks** ·
**Mini‑Mood Manager** (Rats/Hundreds) · **Mob Lobber**.

### During a draft
Each player gets a light selector board of the drafted faction icons; the first click takes that
faction — the board despawns, the faction's pieces spawn at that seat, and the others refresh. Starting
a new draft (or switching between the Ranked and manual‑selector paths) first clears any prior boards.

---

## Faction setup automation

- **Corvid** — the hidden‑plot cover (a fog box) spawns per seat at the correct board‑local spot beside
  the Crafted Improvements board, on the player's correct side and closer on the non‑crafted side.
- **Knaves of the Deepwood** — a Captains board spawns with the faction; the draft deals 4 captains and
  the player keeps 3. When a captain lands in a board slot its meeple, its 2 items (into the stash) and
  its warrior spawn automatically; the faction spawns without the loose captains/items/warriors.
- **Vagabond / Lizard / Marsh / solo boards** and other per‑faction extras spawn baked to final
  positions (no runtime spawn‑then‑move).

---

## What RTT changes vs. plain Root

- **Setup flow:** ranked / monthly‑theme / 5‑player Marsh draft instead of the base menus.
- **Random seating:** every player — including a lone tester — gets a random seat and turn order.
- **Per‑map clearing‑priority markers** in a fixed, locked layout on map spawn.
- **Faction pieces baked to final positions** in the blueprint.
- **RNG fixed** (proper Fisher–Yates, seeded once — the base reseeded every iteration, making ruins and
  Marsh floods deterministic‑per‑second).
- **Fast cold load** — the setup board's UI asset table is trimmed to what it uses, so buttons render on
  the first load.
- Live box score, plus many duplicate‑id / overlapping‑button / stale‑global cleanups.

---

## Building (maintainers)

```
python gen/assemble.py     # -> gen/build/Root_Tabletop_Tournament.json (then copy to dist/ + Saves)
```

Source of truth is `gen/src/`: **`save.json`** (object layout) + **`content.lua`** (Root's object data)
+ **`logic.lua`** (setup, draft, seating, factions, maps, box score). See **[`gen/README.md`](gen/README.md)**.
The generator owns everything and assembles the finished save from scratch. `tools/lua_chunker.py`
validates the board Lua is delimiter‑balanced before a build ships.
