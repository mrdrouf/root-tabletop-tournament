"""
m190 — compact the Setups menu.

Packs the surviving Setups-screen buttons into a tight top grid. (An earlier
version also removed the "Tools" nav button, but that hid the still-full Tools
page of 115 buttons — that removal was reverted.)
"""

from . import framework

NAME = "compact the Setups menu"

# tight grid: options across the top row, Setup All beneath.
# (Hirelings is removed by m220, so it's not placed here.)
LAYOUT = {
    "Vagabond Cards":      "-25 45 -20",
    "Landmarks":           "15 45 -20",
    "Clearing Priorities": "55 45 -20",
    "Setup All":           "-25 5 -20",
}


def apply(text):
    # pack the Setups buttons (scoped to the setupButtons group)
    for bid, pos in LAYOUT.items():
        text, n = framework.set_button_position_in_group(text, "setupButtons", bid, pos)
        if n == 0:
            raise framework.BuildError("Setups button not found: %r" % bid)
    return text
