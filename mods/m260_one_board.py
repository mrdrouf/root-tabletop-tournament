"""
m260 — one-board layout: Setups + Maps + Decks on a single screen.

Since so much was removed, there's no need for separate Setups / Maps&Decks pages.
Make the Setups screen also show the maps and decks:
  - setup() now also activates mapButtonsStandard + decksButtonsStandard
  - the "Maps/Decks" nav button is removed (it's redundant)
Layout (rows, left to right):
  - Setups   (top,    y=55): the 6 setup buttons
  - Maps     (middle, y=15): the 6 official maps in one line
  - Decks    (bottom, y=-30): the 3 official decks
Setups + maps are shrunk to width 30 so six fit on a line.

First pass — the Tools page stays its own tab (115 buttons). Review spacing in TTS.
"""

from . import framework

NAME = "one-board layout: Setups + Maps + Decks together"

SETUP_ROW = [  # 6 setup buttons across the top
    ("Vagabond Cards", "-75 55 -20"), ("Landmarks", "-45 55 -20"),
    ("Clearing Priorities", "-15 55 -20"), ("Setup All", "15 55 -20"),
    ("fivePlayerSetup", "45 55 -20"), ("rttSetup", "75 55 -20"),
]
MAP_ROW = [  # 6 official maps in one line
    ("Summer Map", "-75 15 -20"), ("Lake Map", "-45 15 -20"),
    ("Marsh Map", "-15 15 -20"), ("Winter Map", "15 15 -20"),
    ("Mountain Map", "45 15 -20"), ("Gorge Map", "75 15 -20"),
]
DECK_ROW = [  # 3 official decks along the bottom
    ("Standard Deck", "-40 -35 -20"), ("Exiles and Partisans Deck", "0 -35 -20"),
    ("Squires and Disciples Deck", "40 -35 -20"),
]


def apply(text):
    # setup() also shows maps + decks (anchor/new escaped for the raw JSON)
    anchor_lua = 'self.UI.setAttribute("setupButtons", "active", "True")'
    new_lua = (anchor_lua
               + '\n  self.UI.setAttribute("mapButtonsStandard", "active", "True")'
               + '\n  self.UI.setAttribute("decksButtonsStandard", "active", "True")')
    text = framework.replace_unique(text, framework.esc(anchor_lua), framework.esc(new_lua))

    for bid, pos in SETUP_ROW:
        text, n = framework.set_button_position_in_group(text, "setupButtons", bid, pos)
        if n == 0:
            raise framework.BuildError("setup button not found: %r" % bid)
    # shrink setups + maps to width/height 30 so six fit on a line
    for bid, _ in SETUP_ROW + MAP_ROW:
        text, _ = framework.set_button_attr(text, bid, "width", "30")
        text, _ = framework.set_button_attr(text, bid, "height", "30")
    for bid, pos in MAP_ROW:
        text, n = framework.set_button_position_in_group(text, "mapButtonsStandard", bid, pos)
        if n == 0:
            raise framework.BuildError("map not found in mapButtonsStandard: %r" % bid)
    for bid, pos in DECK_ROW:
        text, n = framework.set_button_position_in_group(text, "decksButtonsStandard", bid, pos)
        if n == 0:
            raise framework.BuildError("deck not found: %r" % bid)

    # remove the now-redundant Maps/Decks nav
    for nav in ("mapsButtonMain", "mapsButton"):
        text, _ = framework.remove_xml_buttons(text, nav)
    return text
