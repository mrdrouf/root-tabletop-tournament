"""
m590 — remove the Mountain map's CENTRAL clearing marker from the data.

The Mountain landmark sits in the central clearing. The old flow let that clearing's suit "Clearing
Marker" spawn with the map (visible ~1s), read it, then destruct+replace it with the landmark — a
default-then-replace flash. Instead we drop the central marker (GUID 1b3b99, move_to ~(-0.175,0.179))
from EVERYTHING['Maps']['Mountain Map'] at build time, so only 11 markers ever spawn and the landmark
appears alone at RTT_MTN_LM (rttMountainLandmark no longer reads/destroys a marker). shuffleMaps is
count-safe (it shuffles whatever markers exist among their own positions), so 11-among-11 is fine.
"""
from . import framework

NAME = "Mountain: drop the central clearing marker (landmark spawns directly, no flash)"

CENTRAL_MARKER = "1b3b99"


def apply(text):
    return framework.remove_loose_piece(text, "Maps", "Mountain Map", CENTRAL_MARKER)
