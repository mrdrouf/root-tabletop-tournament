"""
m280 — truly one page: Setups + Maps + Decks + Rules/Tools, no tabs.

m260 put setups/maps/decks on the Setups screen but left Tools as its own tab.
The user wants the rules/tools on the same page too, with no tab switching, the
setups + maps a little larger, and the deck size kept. The tools block ("rules
and tools") should stay as it is and keep taking ~half the space.

The Tools page is 9 buttons in group `tools1` (a scattered block at X -25..95,
Y -65..5 — the lower-right ~half). Keeping decks at full size AND leaving room for
three full-width rows means the tools block has to sit in the lower half, so we
translate `tools1` straight down by 20 as a rigid unit — every tool keeps its own
size and relative position, the block just moves as one piece.

Final single-page layout (coord space X -90..117, Y -85..85):
  - Setups row : Y=70, six buttons, enlarged to 34x30
  - Maps row   : Y=38, six maps,    enlarged to 34x30
  - Decks row  : Y= 8, three decks, kept at 40x40
  - Tools block: its own arrangement, shifted to Y -85..-15 (the bottom half)

Everything is made active by default so it all shows on load, and the redundant
Setups/Tools tabs are removed. Best-effort blind layout — fine-tune in TTS.
"""

from . import framework

NAME = "one page: setups + maps + decks + tools, no tabs"

SETUP_ROW = [
    ("Vagabond Cards", "-75 70 -20"), ("Landmarks", "-45 70 -20"),
    ("Clearing Priorities", "-15 70 -20"), ("Setup All", "15 70 -20"),
    ("fivePlayerSetup", "45 70 -20"), ("rttSetup", "75 70 -20"),
]
MAP_ROW = [
    ("Summer Map", "-75 38 -20"), ("Lake Map", "-45 38 -20"),
    ("Marsh Map", "-15 38 -20"), ("Winter Map", "15 38 -20"),
    ("Mountain Map", "45 38 -20"), ("Gorge Map", "75 38 -20"),
]
DECK_ROW = [
    ("Standard Deck", "-40 8 -20"), ("Exiles and Partisans Deck", "0 8 -20"),
    ("Squires and Disciples Deck", "40 8 -20"),
]


def apply(text):
    # 1. setup() also reveals the tools groups (belt-and-suspenders alongside the
    #    default-active flags below).
    anchor = 'self.UI.setAttribute("decksButtonsStandard", "active", "True")'
    new = (anchor
           + '\n  self.UI.setAttribute("toolsButtons", "active", "True")'
           + '\n  self.UI.setAttribute("tools1", "active", "True")')
    text = framework.replace_unique(text, framework.esc(anchor), framework.esc(new))

    # 2. everything visible on load (no tab needed to reveal maps/decks/tools)
    for gid in ("mapButtonsStandard", "decksButtonsStandard", "toolsButtons", "tools1"):
        text = framework.set_toggle_group_active(text, gid, "True")

    # 3. setups row — reposition + enlarge
    for bid, pos in SETUP_ROW:
        text, n = framework.set_button_position_in_group(text, "setupButtons", bid, pos)
        if n == 0:
            raise framework.BuildError("setup button not found: %r" % bid)
    for bid, _ in SETUP_ROW + MAP_ROW:
        text, _ = framework.set_button_attr(text, bid, "width", "34")
        text, _ = framework.set_button_attr(text, bid, "height", "30")

    # 4. maps row — reposition (already enlarged above)
    for bid, pos in MAP_ROW:
        text, n = framework.set_button_position_in_group(text, "mapButtonsStandard", bid, pos)
        if n == 0:
            raise framework.BuildError("map not found: %r" % bid)

    # 5. decks row — reposition, size kept (40x40)
    for bid, pos in DECK_ROW:
        text, n = framework.set_button_position_in_group(text, "decksButtonsStandard", bid, pos)
        if n == 0:
            raise framework.BuildError("deck not found: %r" % bid)

    # 6. tools block — rigid translate down into the bottom half
    text, n = framework.shift_group_buttons_y(text, "tools1", -20)
    if n == 0:
        raise framework.BuildError("no tools1 buttons shifted")

    # 7. drop the now-redundant shared Setups/Tools tabs (everything is one page)
    for nav in ("setupButtonMain", "toolsButtonMain"):
        text, _ = framework.remove_xml_buttons(text, nav)
    return text
