"""
m570 — bake the 3 staging Marquise (cat) warriors into the blueprint.

The 3 warriors that sit below the buildings by the faction board are seat-relative, so bake
their move_to (like m300) and they spawn there directly — no runtime reposition (removed from
rttMarquiseCats in m490). The 12 cats that go on the clearings stay runtime (map-relative), but
are taken straight from the supply bag onto the clearing centres, so they too never appear
anywhere else first.

move_to recovered from Adrien's save (board 52c93d, selector R180), verified the m300 way.
"""
from . import framework

NAME = "Marquise opening: bake the 3 staging warriors (direct spawn)"

CAT, FACTION = "Standard", "Marquise de Cat"

REPOSITION = {
    "c33f73": (-2.753, 0.370, 5.719),
    "53c125": (-1.491, 0.370, 5.719),
    "bdfa65": (-0.229, 0.370, 5.720),
}


def apply(text):
    h, j = framework.everything_entry_span(text, CAT, FACTION)
    entry = text[h:j]
    for guid, xyz in REPOSITION.items():
        entry = framework.set_data_move_to(entry, guid, xyz)
    return text[:h] + entry + text[j:]
