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

# guid -> move_to (7 loose warriors -> the two packs). Re-recorded from Adrien's latest save.
# NB: setupFaction spawns via self.positionToWorld(move_to), i.e. move_to is SELECTOR-LOCAL and
# is rotated by the selector at spawn. Adrien's save had the selector at R180 (the Duchy board's
# baked rotY is 180 but its world rotY was ~0), so the raw save-minus-selectorPos values had to be
# un-rotated (R180: negate x,z about the board) back into the canonical selector-local frame:
#   move_to = 2*board_move_to - (warrior_world - selectorPos),  board_move_to = (-0.690, ., -4.864)
REPOSITION = {
    # three x-columns next to the supply (Adrien's latest layout, identity-seat save)
    "68944c": (-8.430, 0.595, 5.047),
    "95d9bd": (-8.430, 0.595, 5.701),
    "cbba66": (-5.672, 0.595, 5.047),
    "3bcedc": (-5.672, 0.595, 5.701),
    "4b0679": (-4.292, 0.595, 5.047),
    "1dbd1f": (-4.292, 0.595, 5.701),
    "1ffbdd": (-4.292, 0.595, 6.355),
}


def apply(text):
    h, j = framework.everything_entry_span(text, CAT, FACTION)
    entry = text[h:j]
    for guid, xyz in REPOSITION.items():
        entry = framework.set_data_move_to(entry, guid, xyz)
    return text[:h] + entry + text[j:]
