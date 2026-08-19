"""
m290 — Lizard Cult opening warrior placement.

You arranged the Lizard warriors in the current save (TS_AutoSave_4): a pack of
four and a pack of three next to the supply, and two warriors sitting in the
acolyte box. This bakes that arrangement into the Lizard faction setup data so it
spawns that way every game.

How the coordinates were derived: the Lizard board (guid 6a1fe4) has
move_to (-4.159154, 0.099868, -5.017212) in the faction data and spawns at world
(-47.841, 11.560, 51.017) with rotY 0 (identity). So the faction selector origin
is  selectorPos = board_world - board_move_to = (-43.682, 11.460, 56.034)  and,
since the mapping is a pure 1:1 translation (verified: the warrior template's
move_to Y 0.783 -> world Y 12.243 matches the save exactly), each warrior's
move_to = its save world - selectorPos.

The 7 warriors already loose in the data become the two packs; two fresh clones
(ac0201, ac0202) are added for the acolyte box. All edits are scoped to
EVERYTHING['Standard']['The Lizard Cult'] so the Logical Lizards / BBP Cogwheel
bot copies that share these warrior GUIDs are untouched.

NB: this puts 9 warriors on the board (2 more than the 7 that ship loose); the
supply bag still holds its 18, so the table shows 27 Lizard warriors vs the
component max of 25. That mirrors your save exactly — say the word to instead pull
the two acolytes out of the supply bag to keep the count at 25.
"""

from . import framework

NAME = "Lizard opening warriors: 4-pack + 3-pack + 2 in the acolyte box"

CAT, FACTION = "Standard", "The Lizard Cult"

# guid -> move_to  (the 7 loose warriors, repositioned into the two packs)
REPOSITION = {
    # pack of four (x = 2.03 / 3.35, z = -16.31 / -15.64)
    "71f2cc": (2.0318, 0.7839, -16.3052),
    "ea0d22": (3.3528, 0.7839, -16.3052),
    "d16eca": (2.0318, 0.7839, -15.6362),
    "c318dc": (3.3528, 0.7839, -15.6362),
    # pack of three (x = -0.36, z = -16.60 / -15.93 / -15.26)
    "42ca2a": (-0.3552, 0.7839, -16.5952),
    "0dea3d": (-0.3552, 0.7839, -15.9272),
    "6d86d9": (-0.3552, 0.7839, -15.2582),
}

# (src_guid, new_guid, move_to) — two warriors in the acolyte box (z near -5, the
# board side; slightly raised, y 0.883)
CLONES = [
    ("71f2cc", "ac0201", (-2.3002, 0.8829, -5.3862)),
    ("71f2cc", "ac0202", (-2.3002, 0.8829, -4.7182)),
]


def apply(text):
    h, j = framework.everything_entry_span(text, CAT, FACTION)
    entry = text[h:j]
    for guid, xyz in REPOSITION.items():
        entry = framework.set_data_move_to(entry, guid, xyz)
    for src, new, xyz in CLONES:
        entry = framework.clone_data_entry(entry, src, new, xyz)
    return text[:h] + entry + text[j:]
