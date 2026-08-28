"""
m630 — replace the "Swol Birbs" fan-faction option with the Marsh 5-player button.

Adrien's request: the Marsh 5-players button should take the Swol Birbs slot on the
bottom option row. m500 already moved the Marsh5P button onto that slot (x=57); this
step removes the Swol Birbs button + its EVERYTHING['Tools']['Swol Birbs'] data so
only the Marsh 5p button remains there. (The registered "Swol Birbs" CustomUIAsset is
left unreferenced — harmless.)
"""

from . import framework

NAME = "remove the Swol Birbs fan-faction option (Marsh 5p button took its slot)"


def apply(text):
    return framework.remove_item(text, "Tools", "Swol Birbs")
