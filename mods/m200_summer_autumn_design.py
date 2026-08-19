"""
m200 — give the Summer map button Autumn's design.

The Summer button was a plain placeholder (icon "Summer Map", height 20, stuck in
the small "extra maps" column at x=95) while every other map is a 40x40 thumbnail
in the grid. Autumn (removed) had the good thumbnail. So Summer inherits Autumn's
look:
- icon "Summer Map" -> "Autumn Map" (both Summer buttons)
- height 20 -> 40
- move the main-menu Summer button into Autumn's now-empty grid slot (-25, 45)
"""

from . import framework

NAME = "give the Summer map button Autumn's design (icon, size, grid slot)"


def apply(text):
    marker = 'icon =\\"Summer Map\\"'
    if marker not in text:
        raise framework.BuildError("Summer Map icon attribute not found")
    text = text.replace(marker, 'icon =\\"Autumn Map\\"')
    text, _ = framework.set_button_attr(text, "Summer Map", "height", "40")
    text, m = framework.set_button_position_in_group(
        text, "mapButtonsStandard", "Summer Map", "-25 45 -20")
    if m == 0:
        raise framework.BuildError("Summer Map not found in mapButtonsStandard")
    return text
