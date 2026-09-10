#!/usr/bin/env python3
"""Take the militant frog off the Lilypad Diaspora's board art, for the 3-Player Draft button.

Maintainer, 2026-09-10: "The art for this should be the pissed off frog that represents the militant
side of frogs on the frog faction board", and when the first cut used the wrong one: "I did not mean
the enclave token for the militant but the actual frog character that is on the frog faction board
art."

    python3 tools/make_frog_art.py

He is the right-hand of the two frogs in the board's illustration -- brow down, mouth turned, hunched
in dungarees and a bandolier, where the one beside him is upright and grinning.

A PLAIN CROP, NOT A CUT-OUT, and that is a decision rather than laziness. He is drawn in the same
olive as the ground he stands on -- his head reads (165,152,60) against a ground of (156,146,71) to
(188,181,91) -- so no colour key can separate them; and the white keyline that would have served as a
boundary instead is broken along a third of his outline, so a flood leaks straight through it into
him. The lily pads he stands among are the faction's own art and read as frogs at button size, which
is what the 4-Player Draft button does with its photograph.

Reads assets/src_art/frog_board.png (the board face as Steam serves it) and writes
assets/src_art/frog_militant.png, which tools/relabel.py turns into the button.
"""
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
SRC = os.path.join(REPO, "assets", "src_art", "frog_board.png")
OUT = os.path.join(REPO, "assets", "src_art", "frog_militant.png")

# Measured on the 2205x1701 board face: he stands x 1560..2080, y 1020..1650. The window is wider than
# he is so the button's art area is filled rather than left with a narrow strip -- at 760x675 the fit
# is height-bound and he lands 234 wide on a 292-wide area, which is the weight of the buttons beside
# him.
WINDOW = (1440, 990, 2200, 1665)       # left, top, right, bottom


def main():
    if not os.path.exists(SRC):
        sys.exit("missing %s" % SRC)
    board = Image.open(SRC).convert("RGB")
    im = board.crop(WINDOW)
    im.save(OUT)
    print("  the militant frog, %dx%d off the board's own art" % im.size)
    print("  -> %s" % os.path.relpath(OUT, REPO))


if __name__ == "__main__":
    main()
