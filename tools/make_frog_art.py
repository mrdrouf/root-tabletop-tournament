#!/usr/bin/env python3
"""Take the militant frog off the Lilypad Diaspora's board art, for the 3-Player Draft button.

Maintainer, 2026-09-10: "The art for this should be the pissed off frog that represents the militant
side of frogs on the frog faction board", and when the first cut used the wrong one: "I did not mean
the enclave token for the militant but the actual frog character that is on the frog faction board
art."

    python3 tools/make_frog_art.py

He is the right-hand of the two frogs in the board's illustration -- brow down, mouth turned, hunched
in dungarees and a bandolier, where the one beside him is upright and grinning.

CUT OUT BY A TRACED OUTLINE, because nothing else works on this one. Maintainer, 2026-09-10: "remove
the background of the frog on the 3 player draft. show only from the hip up not the whole body like
the others. can you also make him look the other side do a 180 flip."

He is drawn in the same olive as the ground he stands on -- his head reads (165,152,60) against a
ground of (156,146,71) to (188,181,91) -- so no colour key separates them, and the white keyline that
would have served as a boundary is broken along a third of his outline, so a flood leaks through it
into him. What is left is to say where he is, so OUTLINE below is his silhouette read off the board at
full size, hip up, and the mask is that polygon.

FLIPPED, so he faces the other way, and the picture is trimmed to the outline's own bounds -- the
polygon decides the framing as well as the cut.

Reads assets/src_art/frog_board.png (the board face as Steam serves it) and writes
assets/src_art/frog_militant.png, which tools/relabel.py turns into the button.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
SRC = os.path.join(REPO, "assets", "src_art", "frog_board.png")
OUT = os.path.join(REPO, "assets", "src_art", "frog_militant.png")

# HIS SILHOUETTE, hip up, in the board's own 2205x1701 coordinates: the top of his head, round the back
# of it, out along the arm and the fist, across at the hip, and back up the front of the dungarees to
# the jaw and the snout.
OUTLINE = [(1635, 1050), (1710, 1032), (1860, 1035), (1910, 1055), (1930, 1080), (1945, 1120),
           (1950, 1150), (1990, 1190), (2050, 1250), (2065, 1320), (2060, 1360), (2065, 1420),
           (1990, 1452), (1950, 1470), (1660, 1470), (1655, 1400), (1650, 1320), (1670, 1265),
           (1635, 1215), (1605, 1140), (1608, 1120)]
GROW = 3                               # a hair outside the traced line, so no edge of him is shaved
FEATHER = 1.5                          # and softened, so it is not a cut-out against the button
MARGIN = 8                             # ground kept around him, for the button to breathe

GROUND = (0x33, 0x42, 0x2b)            # rtt3PBtn's own colour, so no rectangle shows around him


def main():
    if not os.path.exists(SRC):
        sys.exit("missing %s" % SRC)
    board = Image.open(SRC).convert("RGB")

    mask = Image.new("L", board.size, 0)
    ImageDraw.Draw(mask).polygon(OUTLINE, fill=255)
    if GROW:
        mask = mask.filter(ImageFilter.MaxFilter(2 * GROW + 1))
    box = mask.getbbox()
    x0, y0, x1, y1 = (box[0] - MARGIN, box[1] - MARGIN, box[2] + MARGIN, box[3] + MARGIN)

    a = np.asarray(board.crop((x0, y0, x1, y1))).astype(float)
    m = np.asarray(mask.crop((x0, y0, x1, y1)).filter(
        ImageFilter.GaussianBlur(FEATHER))).astype(float) / 255.0
    ground = np.empty_like(a)
    ground[...] = GROUND
    out = a * m[..., None] + ground * (1 - m[..., None])

    im = Image.fromarray(out.round().astype(np.uint8)).transpose(Image.FLIP_LEFT_RIGHT)
    im.save(OUT)
    print("  the militant frog, hip up and flipped, %dx%d on %s" % (im.size + (GROUND,)))
    print("  -> %s" % os.path.relpath(OUT, REPO))


if __name__ == "__main__":
    main()
