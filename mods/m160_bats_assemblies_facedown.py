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
    text, _ = framework.set_embedded_field(text, "930914", "rotZ", "0")
    return text
