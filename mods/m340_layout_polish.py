"""
m340 — layout polish (final source of truth for the row geometry).

Judged against tools/preview_menu.py renders. Runs last, so it overrides the row
positions/sizes set earlier. Fixes seen in the preview:
 - the 3 decks left the right third of their row empty -> spread them wide and
   enlarge so they balance the 6-wide map row above.
 - the top rows sat high with a dead band above the baked title -> nudge setups /
   maps / decks down so the upper block fills the space more evenly.
"""

from . import framework

# (group, [(button_id, "x y z")]) rows, applied in order; sizes set below
SETUP_ROW = ("setupButtons", [
    ("Vagabond Cards", "-75 66 -20"), ("Landmarks", "-45 66 -20"),
    ("Clearing Priorities", "-15 66 -20"), ("Setup All", "15 66 -20"),
    ("fivePlayerSetup", "45 66 -20"), ("rttSetup", "75 66 -20"),
])
MAP_ROW = ("mapButtonsStandard", [
    ("Summer Map", "-75 30 -20"), ("Lake Map", "-45 30 -20"),
    ("Marsh Map", "-15 30 -20"), ("Winter Map", "15 30 -20"),
    ("Mountain Map", "45 30 -20"), ("Gorge Map", "75 30 -20"),
])
DECK_ROW = ("decksButtonsStandard", [
    ("Standard Deck", "-56 -8 -20"), ("Exiles and Partisans Deck", "0 -8 -20"),
    ("Squires and Disciples Deck", "56 -8 -20"),
])

NAME = "layout polish: spread decks, tighten vertical spacing"


def apply(text):
    for group, row in (SETUP_ROW, MAP_ROW, DECK_ROW):
        for bid, pos in row:
            text, n = framework.set_button_position_in_group(text, group, bid, pos)
            if n == 0:
                raise framework.BuildError("button not found in %s: %r" % (group, bid))
    # decks a touch bigger so three of them fill the row width
    for bid, _ in DECK_ROW[1]:
        for attr, val in (("width", "46"), ("height", "46")):
            text, _ = framework.set_button_attr_in_group(text, "decksButtonsStandard", bid, attr, val)
    return text
