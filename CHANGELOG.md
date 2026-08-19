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

## Gameplay: no faction dice — 2026-08-19
`m060_no_faction_dice` — generalises the m010 example: setupFaction now filters
out every Custom_Dice object before spawning, for all factions, so battle dice no
longer appear on the table with any faction.

## Cleanup: manuals + dead buttons — 2026-08-19
`m070_remove_manuals` — removed the rules manuals (Learning to Play, The Law of
Root, The Law of Rootbotics, Better Bot Project manual): all buttons (makeTool /
makeRules) + `EVERYTHING['Tools']` data. `m080_remove_dead_buttons` — removed the
3 orphan buttons that lead to nothing (Klacar's Volcano Island Map ×2, Slug's
Magic Bag, Fifty Fifty Draft). Extended `remove_xml_buttons` to single-quoted id
attributes and added `makeRules` to the verifier.

## Cleanup: remove mode buttons — 2026-08-19
`m090_remove_mode_buttons` — removed Weird Root (slugSetupButton), Super Auto
Smash Up (MashUp), Advanced Setup, and The Law of Slug from the menu (button-only).
These are entry points into subsystems entangled with kept code (the slug button
id is reused by the draft flow; Adset toggle groups drive clockwork-bot setup), so
their data/handlers are left unreachable rather than risk surgery on shared setup
code. A deeper full removal remains possible.

## Setup + more cleanup — 2026-08-19
- `m100_four_selectors` — standard setup spawns 4 faction selectors, not 6
  (`for i = 1, 6 do` → `for i = 1, 4 do` in setupFactionBoards).
- `m110_remove_fandmarks` — removed Fandmarks (fan landmarks): button + Tools data.
- `m120_remove_draft_modes` — removed the GSG tournament draft ("Tournament") and
  the advanced draft / advanced setup ("adDraft") from the menu (button-only;
  both are large entangled draft subsystems).
- `m130_resize_summer_button` — resized the Summer Map selector button from
  height 20 to 40 to match the other map buttons.
Added `framework.replace_unique` and `framework.set_button_attr`.

## Remove table objects — 2026-08-19
- `m140_remove_master_pdf` — removed the Master Instructions PDF (Custom_PDF,
  GUID b85bd2) from the far side of the table.
- `m150_remove_title_model` — REVERTED. GUID 4ee1f2 turned out to be the TABLE,
  not a title; removing it deleted the table surface. The mod was removed and the
  "root community" title is still to be located.
Added `framework.remove_top_level_object` (brace-matching, string-aware).

## Gameplay: Bats assemblies face-down — 2026-08-19
`m160_bats_assemblies_facedown` — the Twilight Council setup placed one of its 6
"Assembly" tiles apart and face-up (GUID 930914, rotZ 180) — "set up and ready".
Flipped it face-down (rotZ 0) so all six assemblies are face-down and none is
revealed. Added `framework.set_embedded_field`.

## Setup button + Autumn→Summer — 2026-08-19
- `m170_resize_setup_button` — "Setup All" (the standard-setup button) resized
  from height 20 to 40 to match the other option buttons.
- `m180_replace_autumn_with_summer` — removed the fixed-suit Autumn map (button +
  data) and pointed randomDraftMap's Autumn roll at the Summer map (which ships
  with 12 clearing markers for randomised suits). Open: whether Summer should also
  adopt the Autumn board art.

## Menu: compact Setups, drop empty Tools nav — 2026-08-19
`m190_compact_setup_menu` — after the removals the "Tools" left-nav page is empty
("leads to nothing"), so its nav buttons (toolsButtonMain, toolsButton) are
removed; the remaining rule tools already sit on the Setups page. Packed the 5
Setups buttons (Vagabond Cards, Hirelings, Landmarks, Clearing Priorities, Setup
All) into a tight top grid. Added `framework.set_button_position_in_group`
(group-scoped so same-named buttons on other screens aren't moved). Best-effort
layout — verify in TTS.

## Menu polish from screenshot feedback — 2026-08-19
- `m200_summer_autumn_design` — Summer map button now uses Autumn's thumbnail
  icon, 40x40 size, and Autumn's grid slot (it was a plain green placeholder).
- `m210_remove_more_buttons` — removed the "more >" nav buttons paging to the now-
  empty fan map / fan deck screens (maps1/2/3, decks1/2).
- `m220_remove_hirelings` — removed the Hirelings option; m190 reflows the Setups
  grid without it.
- `m230_four_player_corners` — the 4 faction selectors now spawn in the four table
  corners (was 3-on-one-side). Added `framework.remove_xml_buttons_by_onclick`.

## 5-player setup + assembly placement — 2026-08-19
- `m240_five_player_setup` — setupFactionBoards now spawns 4 or 5 selectors by
  button id; added a "5 Players" setup button next to Setup All (placeholder art).
  Added `framework.add_button_to_group`.
- `m160` updated — the flipped Bats assembly is also moved into the row with the
  other five (posX -53.27, posZ -53.54) so it sits on the board, not out front.

## RTT automated setup (Hoot draft) — 2026-08-19
`m250_rtt_setup` — reads the "Hoot Draft" saved object, embeds its Militant (6) /
Insurgent (6) faction cards and the Player-Order deck (4), and injects `rttSetup()`
+ an "RTT Setup" button. On click: draw 1 random Militant, shuffle the rest with
all Insurgent, draw 4 -> a 5-card draft; the cards stack at the leftmost slot then
fly one-by-one to the 5 slots (x=63.4, z -11.9..12.0, the positions you placed the
Militant cards) and flip face-up; then deal the 4 Player-Order cards to the seated
coloured players. Cards spawned individually (no deck-merge juggling). v1 — needs
TTS testing/tuning; a card-flip sound needs a hosted audio asset.

## Fixes — 2026-08-19
- **Restored the Tools nav** (m190): an earlier version removed the "Tools" nav
  button on a buggy reading that the Tools page was empty. It actually has 115
  buttons (Battle Mat, Lizard Wizard, Mini-Mood Manager, Bat Bungler, Koffin
  Keeper, Robot Die, Clearing Markers, …). Nothing was deleted — it was hidden;
  the nav is back so the page is reachable again.
- **RTT draft fixed** (m250): cards were spawning on top of each other (TTS merged
  them into one deck) at the wrong height. Now each card spawns one at a time at
  Y≈11.7 and flies to its slot before the next spawns.
- **5-player 5th seat** (m230): moved to the near-middle side; board rotation is
  now decided by the seat's side, not its index (which put seat 5 on the wrong side).

## One-board layout (first pass) — 2026-08-19
`m260_one_board` — Setups screen now also shows the maps and decks (setup() also
activates mapButtonsStandard + decksButtonsStandard). Setups in a top row, the 6
official maps in one middle line, the 3 decks along the bottom; setups+maps shrunk
to width 30 to fit six per line; the redundant "Maps/Decks" nav removed. Tools stay
their own tab. First pass — review spacing in TTS.

Each later step appends one or more modifications under `mods/` and an entry here.
