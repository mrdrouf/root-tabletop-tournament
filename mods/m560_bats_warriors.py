"""
m560 — bake the Twilight Council (bats) opening layout into the blueprint.

Same mechanism as m290/m300: setupFaction spawns each loose piece at its blueprint move_to
(selector-local, rotated by the seat), so writing the final move_to makes the 6 warriors + 6
assemblies spawn in place DIRECTLY — no runtime rttBatsSetup reposition (removed in m490).

move_to values recovered from Adrien's save (board f443b9, selector ~identity), verified the
same way m300 was (fixed fixtures reproject to 0.0000).
"""
from . import framework

NAME = "Twilight Council opening: bake 6 warriors + 6 assemblies (direct spawn)"

CAT, FACTION = "Standard", "Twilight Council"

REPOSITION = {
    # 6 Council Warriors (3 columns x 2 rows by the supply)
    "aa6795": (-7.969, 0.100, 5.787),
    "74ff79": (-7.970, 0.100, 6.456),
    "22aa64": (-10.517, 0.100, 5.786),
    "342d64": (-10.518, 0.100, 6.454),
    "674295": (-11.782, 0.100, 5.785),
    "fc0da4": (-11.783, 0.100, 6.453),
    # 6 Assemblies in a row across the board face
    "930914": (-4.286, 0.355, -2.470),
    "c4ace3": (-2.395, 0.352, -2.443),
    "589bd7": (-0.468, 0.350, -2.456),
    "f815d4": (1.428, 0.347, -2.449),
    "14d3c9": (3.296, 0.345, -2.444),
    "6dfd09": (5.186, 0.342, -2.450),
}


def apply(text):
    h, j = framework.everything_entry_span(text, CAT, FACTION)
    entry = text[h:j]
    for guid, xyz in REPOSITION.items():
        entry = framework.set_data_move_to(entry, guid, xyz)
    return text[:h] + entry + text[j:]
