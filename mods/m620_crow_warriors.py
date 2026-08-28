"""
m620 — bake the Corvid Conspiracy (crows) opening into the blueprint (no runtime reposition).

Recovered from Adrien's saved Corvid setup (frame validated to ~0.0000 against fixed fixtures; the
Corvid board bcf8d7 selector is IDENTITY, scale 1, so move_to = world - board_world + board_mt):

  * 3 blueprint-loose warriors (8b4f9c, b66f9e, d78475) -> staged in a row, baked move_to.
  * the 4th staged warrior (29769e) was drawn from the supply bag -> un-stowed to a loose entry.
  * the supply bag (653be4) -> Adrien nudged it, baked move_to.

The runtime warrior reposition in rttCrowsPlots (m490) is removed, so the "old crows then new crows"
place-then-adjust is gone.
"""
from . import framework

NAME = "Corvid opening: bake 4 warriors + moved supply (direct spawn)"

CAT, FACTION = "Standard", "Corvid Conspiracy"

# 3 blueprint-loose warriors -> baked staged positions
LOOSE = {
    "8b4f9c": (-9.282, 0.521, 6.301),
    "b66f9e": (-10.773, 0.521, 6.301),
    "d78475": (-13.756, 0.521, 6.301),
}
SUPPLY_BAG = ("653be4", (-5.099, 0.470, 6.771))     # Adrien nudged the Corvid Supply bag
UNSTOW = ("29769e", (-12.265, 0.521, 6.301))        # 4th warrior: pull it out of the bag -> loose


def apply(text):
    h, j = framework.everything_entry_span(text, CAT, FACTION)
    entry = text[h:j]
    for guid, xyz in LOOSE.items():
        entry = framework.set_data_move_to(entry, guid, xyz)
    entry = framework.set_data_move_to(entry, SUPPLY_BAG[0], SUPPLY_BAG[1])
    text = text[:h] + entry + text[j:]
    text = framework.unstow_from_bag(text, CAT, FACTION, UNSTOW[0], UNSTOW[1])
    return text
