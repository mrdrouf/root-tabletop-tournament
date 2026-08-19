"""
m300 — Underground Duchy opening warrior placement.

Same idea as m290 (Lizard), reading your arrangement from the current save. The
Duchy you set up as a pack of two + a pack of five warriors next to the supply.

The Duchy selector sits at a rotated seat, so unlike the Lizard this one is NOT
identity: the Duchy board (guid 919e94, data move_to -0.690/0.100/-4.864) spawns
at world (-52.690, 11.560, -50.864) with rotY 180. So

    selectorPos = board_world - R * board_move_to = (-53.380, 11.460, -55.728)

with R = rotate-180-about-Y (dx,dz -> -dx,-dz). Each warrior's
    move_to = R * (save_world - selectorPos)
and R is its own inverse. (Verified: warrior template move_to Y 0.594 -> world Y
12.055, matches the save, so the mapping is a pure rigid rotation+translation.)

Seven of the eight loose warriors in the data are repositioned into the two packs
(the pack of two at x~7.1, the pack of five at x~3.3-4.6). Edits are scoped to
EVERYTHING['Standard']['Underground Duchy'] so bot copies aren't touched.

NB: the data ships eight loose warriors; your save has seven placed, so the eighth
(guid c444dc) is left where it sits near the supply. Say the word if you want it
tucked away too.
"""

from . import framework

NAME = "Underground Duchy opening warriors: pack of 2 + pack of 5"

CAT, FACTION = "Standard", "Underground Duchy"

# guid -> move_to (7 loose warriors -> the two packs)
REPOSITION = {
    # pack of two (x ~ 7.1)
    "68944c": (7.109, 0.595, -18.310),
    "95d9bd": (7.093, 0.595, -17.653),
    # pack of five (x ~ 4.6 and 3.3, adjacent)
    "cbba66": (4.635, 0.595, -18.373),
    "3bcedc": (4.635, 0.595, -17.719),
    "4b0679": (4.635, 0.595, -19.027),
    "1dbd1f": (3.256, 0.595, -17.719),
    "1ffbdd": (3.256, 0.595, -18.373),
}


def apply(text):
    h, j = framework.everything_entry_span(text, CAT, FACTION)
    entry = text[h:j]
    for guid, xyz in REPOSITION.items():
        entry = framework.set_data_move_to(entry, guid, xyz)
    return text[:h] + entry + text[j:]
