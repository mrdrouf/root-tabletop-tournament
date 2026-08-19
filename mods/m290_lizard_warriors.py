"""
m290 — Lizard Cult opening warrior placement.

You arranged the Lizard warriors in the current save (TS_AutoSave_4): a pack of
four and a pack of three next to the supply, and two warriors sitting in the
acolyte box. This bakes that arrangement into the Lizard faction setup data so it
spawns that way every game.

How the coordinates were derived: the Lizard board (guid 6a1fe4) has
move_to (-4.159154, 0.099868, -5.017212) in the faction data and spawns at world
(-47.841, 11.560, 51.017). The SELECTOR frame is rotated 180 about Y (the board's
world rotY reads 0 only because the board's own data rotation cancels it) — proven
by the data's internal geometry: the supply sits at local z=+6.26 but its save
world z is BELOW the board's, i.e. world-z runs opposite to local-z. So

    selectorPos = board_world - R180*board_move_to = (-52.0, 11.46, 46.0)
    move_to     = R180 * (save_world - selectorPos)       (R180: negate x and z)

Sanity-checked: the packs land at local z ~ +6 (right next to the supply's +6.26)
and the acolytes at local z ~ -5 (on the board), matching where you placed them.
(An earlier version used identity and mirrored them to the opposite side.)

The 7 warriors already loose in the data become the two packs; two fresh clones
(ac0201, ac0202) are added for the acolyte box. All edits are scoped to
EVERYTHING['Standard']['The Lizard Cult'] so the Logical Lizards / BBP Cogwheel
bot copies that share these warrior GUIDs are untouched.

Warrior count is kept at the rules-legal 25: the 2 acolytes are added as clones,
and 2 warriors (b00d64, bd1433 — the two you actually pulled in your save) are
removed from the supply bag. Net: 9 loose (4-pack + 3-pack + 2 acolytes) + 16 in
the bag = 25.
"""

from . import framework

NAME = "Lizard opening warriors: 4-pack + 3-pack + 2 in the acolyte box"

CAT, FACTION = "Standard", "The Lizard Cult"

# guid -> move_to  (the 7 loose warriors, repositioned into the two packs, R180)
REPOSITION = {
    # pack of four (next to the supply, local z ~ +5.6/+6.3)
    "71f2cc": (-10.350, 0.784, 6.271),
    "ea0d22": (-11.671, 0.784, 6.271),
    "d16eca": (-10.350, 0.784, 5.602),
    "c318dc": (-11.671, 0.784, 5.602),
    # pack of three (x = -7.96, just left of the four)
    "42ca2a": (-7.963, 0.784, 6.561),
    "0dea3d": (-7.963, 0.784, 5.893),
    "6d86d9": (-7.963, 0.784, 5.224),
}

# (src_guid, new_guid, move_to) — two warriors in the acolyte box (on the board,
# local z ~ -5; slightly raised, y 0.883)
CLONES = [
    ("71f2cc", "ac0201", (-6.018, 0.883, -4.648)),
    ("71f2cc", "ac0202", (-6.018, 0.883, -5.316)),
]

# two warriors to pull OUT of the supply bag so the 2 added acolytes don't push the
# total past the rules-legal 25 (Lizard Cult has 25 warriors).
BAG_REMOVE = ["b00d64", "bd1433"]


def apply(text):
    h, j = framework.everything_entry_span(text, CAT, FACTION)
    entry = text[h:j]
    for guid, xyz in REPOSITION.items():
        entry = framework.set_data_move_to(entry, guid, xyz)
    for src, new, xyz in CLONES:
        entry = framework.clone_data_entry(entry, src, new, xyz)
    for guid in BAG_REMOVE:
        entry, _ = framework.remove_escaped_object(entry, guid)
    return text[:h] + entry + text[j:]
