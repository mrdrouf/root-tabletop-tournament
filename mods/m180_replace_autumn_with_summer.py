"""
m180 — replace the Autumn map with Summer.

The Autumn map is the classic board with FIXED printed clearing suits (no clearing
markers). The Summer map is the same board layout but ships with 12 clearing
markers, so suits can be randomised. The group randomises clearing suits, so the
fixed-suit Autumn map is removed and the random-clearing Summer map stays.

- remove the Autumn Map (selector button + EVERYTHING['Maps'] data)
- redirect randomDraftMap: the roll that picked "Autumn Map" now picks "Summer Map"

NOTE: whether the Summer map should also adopt the Autumn *board art* (vs its own)
is still open — see the report. This step does the functional replacement.
"""

from . import framework

NAME = "replace the Autumn map with Summer (remove Autumn, random-draft picks Summer)"


def apply(text):
    text = framework.remove_item(text, "Maps", "Autumn Map")
    text = framework.replace_unique(
        text,
        'draftMap(player,value,\\"Autumn Map\\")',
        'draftMap(player,value,\\"Summer Map\\")',
    )
    return text
