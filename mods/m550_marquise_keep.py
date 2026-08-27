"""
m550 — bake the larger Marquise Keep.

Adrien enlarged the Keep (blueprint scale 0.3734 -> 0.7485, ~2x). The value 0.373450041 is
unique to the Keep object (GUID 3cb616), so a global swap resizes it in the blueprint (and its
selector-template copies) — the Keep then spawns at its final size directly (no runtime resize).
"""
from . import framework

NAME = "Marquise: bake the enlarged Keep (scale 0.3734 -> 0.7485)"

OLD_SCALE = "0.373450041"
NEW_SCALE = "0.74845"


def apply(text):
    n = text.count(OLD_SCALE)
    if n == 0:
        raise framework.BuildError("m550: Keep scale %s not found" % OLD_SCALE)
    return text.replace(OLD_SCALE, NEW_SCALE)
