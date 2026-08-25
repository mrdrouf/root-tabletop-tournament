"""
m410 — add a "Marsh 5P" option box (the 12th box in the bottom grid).

An option for the Marsh map with five players. There is no separate 5-player Marsh
map data in the mod (Root maps are the same board regardless of player count), so
this spawns the normal Marsh board via a small wrapper; the 5-player specifics can
hook into the RTT draft flow later. Text button (reliable), positioned by the layout.
"""
from . import framework

NAME = "add a Marsh 5P option box"

FUNC = (
    '\nfunction rttMarsh5P()\n'
    '  makeMap(nil, nil, "Marsh Map")\n'
    '  broadcastToAll("Marsh map - 5-player option", {0.9,0.85,0.6})\n'
    'end\n\n'
)
BUTTON = ('<Button id="Marsh5P" onclick="rttMarsh5P" text="5 Players" '
          'position="0 -73 -20" width="34" height="17" fontSize="7" color="#9b8551"/>')


def apply(text):
    anchor = "function makeMap(player,value,id)"
    if text.count(anchor) != 1:
        raise framework.BuildError("makeMap anchor not unique")
    text = text.replace(anchor, framework.esc(FUNC) + anchor, 1)
    text = framework.add_button_to_group(text, "setupButtons", BUTTON)
    return text
