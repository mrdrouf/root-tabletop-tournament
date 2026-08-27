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

# hide the whole nav group on the solo board only; frame 15 > configureFactionBoard's frame 10
NAV_HIDE = ('\n  Wait.frames(function() pcall(function() '
            'board1.UI.setAttribute("Main Nav Personal", "active", "False") end) end, 15)')

# direct Knaves tile, at the "Vabond Choices" grid slot (95 45 -20)
KNAVES_TILE = ('<Button onclick="makeFaction" onMouseEnter="infoOfficialContent" '
               'onMouseExit="clearInfo" category="Standard" id="Knaves of the Deepwood" '
               'position="95 45 -20" width="40" height="40" fontSize="8" '
               'icon="Knaves of the Deepwood" color="gray"/>')


def apply(text):
    # 1. hide the nav bar on the solo Faction Board (anchor unique to makeFactionSelector)
    text = framework.splice_after_unique(text, "board1.locked = false", NAV_HIDE)

    # 2. replace the "Vabond Choices" submenu tile with a direct Knaves faction tile
    text, n = framework.remove_xml_buttons_by_onclick(text, "vagabondChoices")
    if n != 1:
        raise framework.BuildError("expected exactly 1 'Vabond Choices' button, found %d" % n)
    text = framework.add_button_to_group(text, "standardButtons", KNAVES_TILE)
    return text
