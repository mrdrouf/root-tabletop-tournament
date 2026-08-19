"""
m030 — remove fan maps.

Keep only the 7 official maps (Autumn, Lake, Marsh, Summer, Winter, Mountain,
Gorge); remove the 21 fan maps (XML button, if any, + EVERYTHING['Maps'] data).
require_button=False because a few map variants (bot / original) have data but no
button of their own. randomDraftMap only draws from the kept official maps, and
no literal draft/makeMap call references a removed map (build.py verifies this).
"""

from . import framework

NAME = "remove fan maps (keep the 7 official maps)"

REMOVE = [
    "Tidal Flats Map",
    "Blighted City Map",
    "Mountainside Map",
    "River Town Map",
    "Taiga Map",
    "Gloom Map",
    "The Deep Woods Map",
    "The Deep Woods Map Bots",
    "The Wastelands Map",
    "Gorge Original Map",
    "Treasure Island Map",
    "Narrows and Islets Map",
    "Australia Map",
    "Tunnel Unraveled Map",
    "Tropics Map",
    "Lost Woodland Map",
    "Legends Map",
    "Urban Map",
    "Inferno Map",
    "Spaceballs Map",
    "Blighted Grove Map",
]


def apply(text):
    for name in REMOVE:
        text = framework.remove_item(text, "Maps", name, require_button=False)
    # bot setup auto-swapped drafted map #7 to the (now-removed) Deep Woods bots map
    text = framework.remove_lua_line(
        text, 'makeMap(player,value,\\"The Deep Woods Map Bots\\")')
    return text
