"""
m570 — Marquise opening warriors, done in the blueprint (no runtime row / no reposition).

The data ships the Marquise with 11 loose Cat Warriors (the visible ROW Adrien kept seeing) + 14
inside the "Marquise Supply" bag (GUID 67bcac) = 25. Adrien's setup is: 3 warriors staged just
below the 3 starting building tokens, 12 (or 15 on 5-player Marsh) out on the clearings, the rest
in the supply. So here we:

  1. MOVE 8 of the 11 loose warriors INTO the supply bag (proper blueprint edit) -> 3 loose + 22
     bagged. rttMarquiseCats (m490) then takes the 12/15 clearing cats STRAIGHT from that bag.
  2. BAKE the 3 remaining loose warriors' move_to just below the 3 starting buildings, so they
     spawn there directly.

The 3 starting buildings sit at selector-local z ~= 7.30, x = -0.037 / -1.559 / -3.082 (Recruiter
7664fa / Workshop 3ab7d6 / Saw Mill 636f8e); the warriors go one row below (z ~= 5.4, same x).

(An earlier m570 baked c33f73/53c125/bdfa65 — but those live INSIDE the bag, so set_data_move_to
was rewriting the nearest preceding move_to, i.e. the SUPPLY BAG's own position. That bug is gone.)
"""
from . import framework

NAME = "Marquise opening: 8 warriors -> supply bag; bake 3 staging warriors below the buildings"

CAT, FACTION = "Standard", "Marquise de Cat"
SUPPLY_BAG = "67bcac"

# 8 of the 11 loose warriors -> into the supply bag
STOW = ["30e595", "56678b", "9859f0", "28cc28", "e8be14", "c9e364", "6ee317", "15fd21"]

# the 3 kept-loose warriors, baked just below the 3 starting buildings (x matches each building)
STAGING = {
    "2afa64": (-0.037, 0.956, 5.400),   # below Recruiter (7664fa)
    "ca9ced": (-1.559, 0.956, 5.400),   # below Workshop  (3ab7d6)
    "e0563d": (-3.082, 0.956, 5.400),   # below Saw Mill  (636f8e)
}


def apply(text):
    # 1) stow the 8 extras inside the supply bag
    text = framework.stow_loose_in_bag(text, CAT, FACTION, STOW, SUPPLY_BAG)
    # 2) bake the 3 staging warriors below the buildings
    h, j = framework.everything_entry_span(text, CAT, FACTION)
    entry = text[h:j]
    for guid, xyz in STAGING.items():
        entry = framework.set_data_move_to(entry, guid, xyz)
    return text[:h] + entry + text[j:]
