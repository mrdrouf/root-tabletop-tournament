"""
m160 — Twilight Council (Bats): no assembly set up and ready; all face-down.

The Twilight Council setup spawns 6 "Assembly" tiles: five sit face-down in a row
on the board (rotZ ~= 0), and one (GUID 930914) is placed apart and face-up
(rotZ ~= 180) — the "set up and ready" assembly. Flip that one face-down (rotZ 0)
so no assembly is revealed and all six are face-down.
"""

from . import framework

NAME = "Twilight Council (Bats): flip the ready assembly face-down (all assemblies face-down)"


def apply(text):
    # flip face-down AND move it into the row with the other 5 assemblies (they sit
    # at posZ -53.54, posY 36.16; extend the row to the next slot at posX -53.27)
    for field, val in (("rotZ", "0"), ("posX", "-53.27"),
                       ("posY", "36.16"), ("posZ", "-53.54")):
        text, _ = framework.set_embedded_field(text, "930914", field, val)
    return text
