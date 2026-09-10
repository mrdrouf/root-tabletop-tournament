#!/usr/bin/env python3
"""Cut the militant frog off the Lilypad Diaspora's faction board, for the 3-Player Draft button.

Maintainer, 2026-09-10: "The art for this should be the pissed off frog that represents the militant
side of frogs on the frog faction board."

    python3 tools/make_frog_art.py

The board prints its two enclave tokens side by side in the Enclaves column -- the peaceful frog, all
curls and closed eyes, and under it the militant one with its brows down. That second token is the
picture, and it is a printed CIRCLE on flat parchment, which makes this the easiest cut of the three
button arts: no keying, no flooding, no island. A disc of the measured radius about the measured
centre IS the token, and everything outside it is page.

Reads assets/src_art/frog_board.png (the board face as Steam serves it) and writes
assets/src_art/frog_militant.png, which tools/relabel.py turns into the button.
"""
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
SRC = os.path.join(REPO, "assets", "src_art", "frog_board.png")
OUT = os.path.join(REPO, "assets", "src_art", "frog_militant.png")

# Measured on the 2205x1701 board face: the militant enclave is the LOWER of the two tokens.
CENTRE = (971, 790)
RADIUS = 79
MARGIN = 6                             # a little page around it, so the disc is not cropped flush
FEATHER = 1.2                          # the printed rim is soft; a hard disc edge reads as a sticker

# THE BUTTON'S OWN COLOUR, as with the Theme and Riverboat arts: the character sits on the ground the
# button is drawn in, so nothing reads as a rectangle around it. rtt3PBtn is drawn "#33422b".
GROUND = (0x33, 0x42, 0x2b)


def main():
    if not os.path.exists(SRC):
        sys.exit("missing %s" % SRC)
    board = np.asarray(Image.open(SRC).convert("RGB")).astype(float)
    cx, cy = CENTRE
    r = RADIUS + MARGIN
    win = board[cy - r:cy + r, cx - r:cx + r]

    yy, xx = np.mgrid[0:win.shape[0], 0:win.shape[1]]
    d = np.sqrt((xx - r + 0.5) ** 2 + (yy - r + 0.5) ** 2)
    alpha = np.clip((RADIUS - d) / FEATHER + 0.5, 0.0, 1.0)

    ground = np.empty_like(win)
    ground[...] = GROUND
    out = win * alpha[..., None] + ground * (1 - alpha[..., None])

    Image.fromarray(out.round().astype(np.uint8)).save(OUT)
    print("  the militant enclave, r %d about (%d, %d), on %s" % (RADIUS, cx, cy, GROUND))
    print("  -> %s" % os.path.relpath(OUT, REPO))


if __name__ == "__main__":
    main()
