# Root Tabletop Tournament — Modification log

Provenance: forked from **Root – Ultimate Collection** (Steam Workshop
`2516434159`), base version **v13.3**, pinned in `base.lock`. Release/version
numbers are tracked separately, outside this repo; this file just records the
ordered modification sequence.

## Initial — 2026-08-19
Exact copy of the base mod, rebranded as Root Tabletop Tournament. No gameplay
changes.

- `m000_identity` — SaveName → "Root Tabletop Tournament"; GameMode →
  "Root Tabletop Tournament".

## Cleanup: remove standalone tools — 2026-08-19
`m020_remove_tools` — removed 12 optional menu tools (each: XML button +
`EVERYTHING['Tools']` data), plus the now-dead `makeSideTables` and
`makeNuancedQuestDeck` handlers: Battle Dice, Supply Knight, Nuanced Quest Deck,
Quest Freshener, Craftable Items ("the items"), Clockwork Upgrade Cards,
Hirelings Noir, Mighty Multi-State Warriors, Mighty Multi-State Ruins, Alliance
Multi-State Warriors, Action Deck, Side Tables ("extra chairs"). Added
`framework` removal helpers (`remove_item`, `remove_xml_buttons`,
`remove_everything_entry`, `remove_lua_function`) and a dangling-reference
verifier in `build.py` that fails the build if a removed item is still referenced.

## Cleanup: remove fan maps — 2026-08-19
`m030_remove_fan_maps` — kept the 7 official maps (Autumn, Lake, Marsh, Summer,
Winter, Mountain, Gorge); removed the 21 fan maps (button + `EVERYTHING['Maps']`
data) and the dead bot-setup line that swapped drafted map #7 to the Deep Woods
bots map. `randomDraftMap` already draws only from the kept maps.

## Cleanup: remove fan decks — 2026-08-19
`m040_remove_fan_decks` — kept the 3 official deck families (Standard/Base,
Exiles & Partisans, Squires & Disciples) + shared support cards. Fully removed
6 fan deck families (Dawn and Dusk, Upstarts and Renegades, Sorcery of the
Enchanted Woods, Crafty Tactics, Offensive, 60 Card Master — button + both data
piles). Dark Deck removed from the menu (button only) — it is coupled into
makeDeck, which also drives the kept decks, so its data is left unreachable
rather than risk surgery on core deck logic.

## Cleanup: remove scenarios — 2026-08-19
`m050_remove_scenarios` — removed all 6 scenarios (button + `EVERYTHING['Scenarios']`
data): Trick or Treat!, The Tavern, Haunted Woodland, Riverfolk Markers, Double
Entente, The Chaos Contraptions; the `makeHauntedWoodland` handler; and the
"Scenarios" menu label. Added `framework.remove_xml_element` with an inside-the-
element safety guard (the verifier caught it deleting Tools/Fan-Faction entries
when a marker also appeared in the Lua asset table — now impossible).

Each later step appends one or more modifications under `mods/` and an entry here.
