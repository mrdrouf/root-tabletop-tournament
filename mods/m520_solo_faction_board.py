"""
m520 — the SOLO faction board (spawned by the "Faction Select" tool button, which clones
the menu board into "Faction Board" at (54.81,11.56,0) via makeFactionSelector).

Adrien wants that board stripped to ONLY the twelve factions: no bots, no fan-faction
setup, no setups/rules, no tools, and no "get factions" nav. On the clone, configureFactionBoard
already hides everything except two groups — `Main Nav Personal` (the bots/fan/setups/tools/
"Core Factions" nav bar) and `standardButtons` (the 12 faction tiles). So:

  1. Hide `Main Nav Personal` on the solo board ONLY (scoped inside makeFactionSelector, NOT
     configureFactionBoard, so the 4-6-seat standard selectors keep their nav). This leaves
     just the 12 tiles + the close-X.
  2. Make the tiles be twelve DIRECT factions: the 4th standard tile is "Vabond Choices"
     (onclick=vagabondChoices), a submenu opener — not a faction. Replace it with a direct
     "Knaves of the Deepwood" tile (the tournament's 12th faction, which otherwise lives one
     click deep inside that submenu). The submenu's own Knaves button already uses
     onclick="makeFaction" id="Knaves of the Deepwood", so a direct tile sets up identically.

The per-faction setup EXTRAS (badgers/warriors/bats/crows/Knaves) already fire on this path:
makeFaction -> setupFaction is the SELECTOR path m490 hooks with rttFactionExtras. The one gap
(Keepers relics needing RTT_PICKED.map) is fixed in m490 via the RTT_CURRENT_MAP fallback.
"""
from . import framework

NAME = "solo faction board: strip to the 12 factions (hide nav, Knaves as a direct tile)"

# Spawn the clone BELOW the table, strip it while hidden, then raise it — so it appears
# ALREADY stripped (no visible "full board then nav removed" adjustment). frame 14 > frame 10
# (configureFactionBoard), so the nav is turned off and the board revealed in one hidden pass.
HIDDEN_POS = ("board1.setPosition({54.81,-60,0})")
FINAL_POS = ("board1.setPosition({54.81,11.56,0})")
# while the board is still hidden: strip the nav, spread the 12 tiles wider + centred into the
# space the nav used to occupy, then reveal. All done before the board is visible (no adjust).
_SPREAD = ("local _sp = {"
           '{"Marquise de Cat","-90 45 -20"},{"Eyrie Dynasties","-30 45 -20"},'
           '{"Woodland Alliance","30 45 -20"},{"Knaves of the Deepwood","90 45 -20"},'
           '{"The Lizard Cult","-90 -5 -20"},{"Riverfolk Company","-30 -5 -20"},'
           '{"Underground Duchy","30 -5 -20"},{"Corvid Conspiracy","90 -5 -20"},'
           '{"Lord of the Hundreds","-90 -55 -20"},{"Keepers in Iron","-30 -55 -20"},'
           '{"Twilight Council","30 -55 -20"},{"Lilypad Diaspora","90 -55 -20"}} '
           "for _, e in ipairs(_sp) do pcall(function() board1.UI.setAttribute(e[1], \"position\", e[2]) end) end")
REVEAL = ('\n  Wait.frames(function() '
          'pcall(function() board1.UI.setAttribute("Main Nav Personal", "active", "False") end) '
          + _SPREAD +
          ' board1.setPosition({54.81,11.56,0}) end, 14)')

# direct Knaves tile, at the "Vabond Choices" grid slot (95 45 -20)
KNAVES_TILE = ('<Button onclick="makeFaction" onMouseEnter="infoOfficialContent" '
               'onMouseExit="clearInfo" category="Standard" id="Knaves of the Deepwood" '
               'position="95 45 -20" width="40" height="40" fontSize="8" '
               'icon="Knaves of the Deepwood" color="gray"/>')


def apply(text):
    # 1. spawn the solo Faction Board hidden below the table
    text = framework.replace_unique(text, framework.esc(FINAL_POS), framework.esc(HIDDEN_POS))
    # 2. strip the nav + raise it (already configured) in one hidden pass — no visible flash
    text = framework.splice_after_unique(text, "board1.locked = false", REVEAL)

    # 3. replace the "Vabond Choices" submenu tile with a direct Knaves faction tile
    text, n = framework.remove_xml_buttons_by_onclick(text, "vagabondChoices")
    if n != 1:
        raise framework.BuildError("expected exactly 1 'Vabond Choices' button, found %d" % n)
    text = framework.add_button_to_group(text, "standardButtons", KNAVES_TILE)
    return text
