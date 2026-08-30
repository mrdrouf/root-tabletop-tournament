# Root Tabletop Tournament (RTT)

A tournament build of Root for Tabletop Simulator: a streamlined ranked / theme / 5‑player draft
pipeline, per‑map clearing‑priority markers, faction pieces baked to their final positions, and a
clean fast‑loading save. It is **self‑contained** — everything needed to build and play it lives in
this repo. There is no external mod to subscribe to and nothing to strip at load; the code assembles
the finished save from scratch.

---

## Install (players) — one file

The finished mod is a single self‑contained save:

> **`dist/Root_Tabletop_Tournament.json`**

Drop that one file into your Tabletop Simulator **Saves** folder (no subfolder):

- **Windows:** `C:\Users\<you>\Documents\My Games\Tabletop Simulator\Saves\`
- **macOS:** `~/Library/Tabletop Simulator/Saves/`
- **Linux:** `~/.local/share/Tabletop Simulator/Saves/`

Then in TTS: **Games → Save & Load → “Root Tabletop Tournament”**, and load it fresh (don’t “Continue”).
All art is streamed from remote hosts, so nothing else needs to ship with it. (`dist/Root_Tabletop_Tournament.png`
is an optional save‑list thumbnail.)

---

## The buttons (setup board)

Only the live tournament controls are on the board; the base game’s dead menu subsystems have been
removed entirely.

### Start a game (top row)
| Button | What it does |
|--------|--------------|
| **Ranked** (owl) | Ranked draft: players join → random turn order → a light per‑seat board spawns for each player → each seat gets its colour, hand and the turn‑order card matching its number → faction draft in reverse turn order. Pool = 1 Militant + 4 others. |
| **Theme** (fox) | Same flow, but the pool is 1 Militant + all Insurgents. |
| **Marsh 5P** (5‑player art) | The 5‑player Marsh ranked draft: Marsh map with all 15 clearings, 3 town landmarks + 12 suit markers, 6‑card draft. |
| **Marsh 5P map** (Marsh icon) | Places **only** the 5‑player Marsh board — no draft, no seating (for manual setup). |

### Maps
**Summer**, **Lake**, **Marsh**, **Winter**, **Mountain**, **Gorge**. Each clears the previous map,
spawns the board, and runs its per‑map hooks: fixed clearing‑priority markers; Marsh number tokens +
flood randomisation; the Mountain central landmark + tower removal; and, via the draft, the Battle Mat.

### Decks
**Standard**, **Exiles & Partisans**, **Squires & Disciples** — spawns the chosen deck (the small‑count
variant is used automatically in a 1–2 player game).

### Tools row
**Faction Select** (opens the 12‑faction + Knaves tile picker for manual setup) · **Battle Mat** ·
**Lizard Wizard** · **Clearing Markers** · **Clearing Priorities** · **Vagabond Cards** ·
**Landmarks** · **Mini‑Mood Manager** (Rats/Hundreds mood) · **Mob Lobber**.

### During a draft
Each player gets a light selector board showing the drafted faction icons; the first click takes that
faction — the board despawns, the faction’s pieces spawn at that seat, and the other boards refresh.

---

## What RTT changes vs. plain Root

- **Setup flow:** ranked / theme / 5‑player Marsh draft instead of the base menus.
- **Per‑map clearing‑priority markers** placed in a fixed, locked layout on map spawn.
- **Faction pieces baked to final positions** in the blueprint (no runtime spawn‑then‑move).
- **RNG fixed** (proper Fisher–Yates, seeded once at load — the base reseeded every iteration, making
  ruins and Marsh floods deterministic‑per‑second).
- **Fast cold load** — the setup board’s UI asset table was trimmed to what it uses, so the buttons
  render on the first load instead of needing a second load.
- **Marsh 5‑player mode**, plus a pile of duplicate‑id / overlapping‑button cleanups.

---

## Building (maintainers)

The mod is generated from this repo — see **[`gen/README.md`](gen/README.md)**:

```
python gen/assemble.py     # -> gen/build/Root_Tabletop_Tournament.json (then copy to dist/ + Saves)
```

Source of truth is `gen/src/`: **`save.json`** (the object layout) + **`content.lua`** (Root’s object
data) + **`logic.lua`** (our code — setup, draft, seating, factions, maps, box score). The generator
owns everything and assembles the finished save from scratch; nothing is inherited‑then‑removed.
