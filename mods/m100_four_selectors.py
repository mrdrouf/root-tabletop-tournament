"""
m100 — standard setup spawns 4 faction selectors, not 6.

setupFactionBoards() clones the faction-selector board `for i = 1, 6 do` at the
six seat positions. Changing the count to 4 spawns four selectors instead of six.
"""

from . import framework

NAME = "standard setup spawns 4 faction selectors, not 6"


def apply(text):
    return framework.replace_unique(text, "for i = 1, 6 do", "for i = 1, 4 do")
