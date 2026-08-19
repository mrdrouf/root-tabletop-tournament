"""
m230 — spawn the 4 faction selectors in the corners.

setupFactionBoards clones the faction-selector board at seat coordinates. With the
count set to 4 (m100) it was using the first four of the 6-seat layout (three on
one side, one on the other). Re-order the first four seats to the four table
corners (near-right, near-left, far-right, far-left) and rotate the two far seats.
"""

from . import framework

NAME = "spawn the 4 faction selectors in the four corners"


def apply(text):
    # seats 1-4 = four corners; seat 5 (x=0) = near-middle side (z=-46).
    text = framework.replace_unique(
        text, "local xs = {52,0,-52,-52,0,52}", "local xs = {52,-52,52,-52,0,52}")
    text = framework.replace_unique(
        text, "local zs = {-46,-46,-46,46,46,46}", "local zs = {-46,-46,46,46,-46,46}")
    # rotate by the seat's side (far side faces the other way), not by index —
    # index-based rotation put seat 5 on the wrong side.
    text = framework.replace_unique(
        text, "if i > 3 then board1.setRotation({0,180,0})",
        "if zs[i] > 0 then board1.setRotation({0,180,0})")
    return text
