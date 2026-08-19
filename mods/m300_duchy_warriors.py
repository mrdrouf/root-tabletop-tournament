"""
m300 — Underground Duchy opening warrior placement.

Same idea as m290 (Lizard), reading your arrangement from the current save. The
Duchy you set up as a pack of two + a pack of five warriors next to the supply.

The Duchy selector frame is IDENTITY (unlike the Lizard, which is R180) — proven
the same way, by the data's internal geometry: the Duchy supply sits at local
z=+5.5 and its save world z runs the SAME direction as local, so no flip. The
Duchy board (guid 919e94, data move_to -0.690/0.100/-4.864) spawns at world
(-52.690, 11.560, -50.864). So

    selectorPos = board_world - board_move_to = (-52.0, 11.46, -46.0)
    move_to     = save_world - selectorPos            (identity)

Sanity-checked: all seven land at local z ~ +8 to +9, right in the supply's
warrior cluster (supply local z=+5.5, default warriors +5.4..+10.2), matching your
save. (An earlier version used R180 and mirrored them to the opposite side.)

Seven of the eight loose warriors are repositioned into the two packs. Edits are
scoped to EVERYTHING['Standard']['Underground Duchy'] so bot copies aren't touched.

NB: the data ships eight loose warriors; your save has seven placed, so the eighth
(guid c444dc) is left where it sits near the supply. Say the word if you want it
tucked away too.
"""

from . import framework

NAME = "Underground Duchy opening warriors: pack of 2 + pack of 5"

CAT, FACTION = "Standard", "Underground Duchy"

# guid -> move_to (7 loose warriors -> the two packs, identity transform)
REPOSITION = {
    # pack of two (x ~ -8.5, next to the supply)
    "68944c": (-8.489, 0.595, 8.582),
    "95d9bd": (-8.473, 0.595, 7.925),
    # pack of five (x ~ -6.0 and -4.6, adjacent)
    "cbba66": (-6.015, 0.595, 8.645),
    "3bcedc": (-6.015, 0.595, 7.991),
    "4b0679": (-6.015, 0.595, 9.299),
    "1dbd1f": (-4.636, 0.595, 7.991),
    "1ffbdd": (-4.636, 0.595, 8.645),
}


def apply(text):
    h, j = framework.everything_entry_span(text, CAT, FACTION)
    entry = text[h:j]
    for guid, xyz in REPOSITION.items():
        entry = framework.set_data_move_to(entry, guid, xyz)
    return text[:h] + entry + text[j:]
