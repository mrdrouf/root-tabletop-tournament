"""
m365 — give the setup/faction board real 3D thickness.

The board (bab7e1) is a flat Custom_Tile (Thickness 0.1). Verified byte-identical
between the base mod and our dist (same scale 15.5x1x15.5, same thickness, same
type; zero 3D models removed) — so nothing we did flattened it; it was never a 3D
model in the base. To make it read as an actual 3D wooden board (Adrien's ask), bump
the tile Thickness so the menu board AND its spawned selector-board clones get visible
depth and edges. Tune the value if it's too much / too little.
"""
from . import framework

NAME = "give the setup/faction board real 3D thickness (0.1 -> 0.5)"


def apply(text):
    start, end = framework._object_span(text, "bab7e1")
    block = text[start:end]
    old = '"Thickness": 0.1'
    if block.count(old) != 1:
        raise framework.BuildError("board Thickness 0.1 not found uniquely in bab7e1")
    block = block.replace(old, '"Thickness": 0.5', 1)
    return text[:start] + block + text[end:]
