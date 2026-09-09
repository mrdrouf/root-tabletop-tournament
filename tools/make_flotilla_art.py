#!/usr/bin/env python3
"""Cut the otter off the Riverfolk Flotilla's hireling card, for the Flotilla Draft button.

Maintainer, 2026-09-09: "create an additional button option that is Flotilla Draft; add the art of the
flotilla for that button", and on which art: the hireling's own printed one.

    python3 tools/make_flotilla_art.py

Same job as the Theme button's Adventurer, so it is the same method and it borrows that tool's
morphology outright rather than keeping a second copy: key the card's ground out, take the island the
character stands on, lay it on the button's own colour so no rectangle shows around him.

What differs is the ground. The Adventurer stands on a flat lilac wall; the otter is up to his waist in
teal water drawn with gold ripples, so the key is WARMTH -- water is far bluer than it is red and every
part of him (fur, cream chest, bandana, the yellow raft) is far redder than it is blue. The ripples are
not water by that test, but they float free of him, so the island test drops them.

Reads the card face as Steam serves it and writes assets/src_art/flotilla_button.png, which
tools/relabel.py turns into the button.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
sys.path.insert(0, HERE)
from make_theme_art import GROUND, m2i, dilate, erode, flood, fill_holes   # noqa: E402

SRC = os.path.join(REPO, "assets", "src_art", "flotilla_hireling_card.png")
OUT = os.path.join(REPO, "assets", "src_art", "flotilla_button.png")

# THE PICTURE, on the 1241x749 card face: he sits in the bottom-right corner. The window is trimmed to
# him top and bottom -- the card has water below his raft and panel above his ears, and neither is
# picture -- which is also what makes relabel.py's fit land him big: at 383x307 it scales by the height
# and he arrives 257 wide on a 292-wide art area, instead of the 209 a squarer window gave.
WINDOW = (836, 391, 1219, 698)         # left, top, right, bottom

WATER_BR = 30                          # blue-over-red: the water is +57 to +86, every part of him is
                                       # negative, and the darkest ink is only +11
WATER_G = 60                           # ...and it is never nearly black, which the outlines are

# THE RULES PANEL IS GROUND TOO, and it cannot be keyed by colour: it is a warm cream and so is his
# bandana, to within a couple of counts. It also cannot be cut off with a straight edge, because his
# ears are drawn OVER it and stand a hundred pixels up inside it -- which is exactly why the first cut
# brought a slab of parchment and the tail of the word "along" down with him.
#
# So it is flooded from its own corner instead: the window's top-left pixel is inside the panel by
# construction, and the flood spreads through everything pale enough to be paper and stops at his
# outline. THE CORNER ITSELF, not a point a few pixels in -- the panel's border is hand-inked and
# wobbles, and (5, 5) landed on a dark stroke of it, which seeds a flood that reaches nothing and
# quietly leaves the whole panel in the picture.
PARCH_SEED = (0, 0)                    # the window's own corner, which is panel
PARCH_MEAN = 190                       # paper is pale...
PARCH_BR = -80                         # ...and warm, but not as warm as his fur

SEAL = 2                               # closes his drawn outline before the ground is flooded
SEED = (196, 215)                      # his face, in window coordinates
TRIM = 2                               # the card bleeds into his antialiased edge; against the pale
                                       # panel one pixel was not enough and left a white rim
FEATHER = 0.7

# HIS VEST IS BLUE AND THE WATER IS TEAL, which is the whole of how the enclosed pockets are told
# apart. The water key takes his vest with it -- it is bluer than it is red, like the river -- so the
# holes it punches have to be filled back in. But filling every enclosed pocket also fills the water
# trapped between his tail, his arm and his shoulder, which comes out as a hard teal wedge on the
# button.
#
# Measured on the four vest pockets and the four water ones: blue minus green is +37 to +50 on the
# vest and -7 to -9 on the water, and the scrap of panel caught by his ear is -50. Nothing sits
# between.
POCKET_BG = 20                         # blue-over-green: above it the pocket is him, below it is not


def figure_mask(win):
    """The otter, as an alpha over the window: everything the card's own ground does not reach."""
    a = win.astype(int)
    warmth = a[..., 2] - a[..., 0]
    water = (warmth > WATER_BR) & (a[..., 1] > WATER_G)
    paper = flood((a.mean(2) > PARCH_MEAN) & (warmth > PARCH_BR), PARCH_SEED)
    him = flood(erode(dilate(~(water | paper), SEAL), SEAL), SEED)
    him = him | (fill_holes(him) & ~him & pockets_of_his(a, fill_holes(him) & ~him))
    him = flood(erode(him, TRIM), SEED)
    him = him | (fill_holes(him) & ~him & pockets_of_his(a, fill_holes(him) & ~him))
    return np.asarray(m2i(him).filter(ImageFilter.GaussianBlur(FEATHER))).astype(float) / 255.0


def pockets_of_his(a, pocket):
    """Of the enclosed pockets, the ones that are part of him rather than trapped water or panel."""
    keep = np.zeros(pocket.shape, bool)
    h, w = pocket.shape
    seen = np.zeros((h, w), bool)
    for sy in range(h):
        for sx in np.where(pocket[sy] & ~seen[sy])[0]:
            if seen[sy, sx]:
                continue
            blob = flood(pocket & ~seen, (sy, sx))
            seen |= blob
            if (a[..., 2][blob].mean() - a[..., 1][blob].mean()) > POCKET_BG:
                keep |= blob
    return keep


def main():
    if not os.path.exists(SRC):
        sys.exit("missing %s" % SRC)
    card = np.asarray(Image.open(SRC).convert("RGB"))
    x0, y0, x1, y1 = WINDOW
    win = card[y0:y1, x0:x1]

    alpha = figure_mask(win)
    ys, xs = np.where(alpha > 0.5)

    ground = np.empty_like(win, dtype=float)
    ground[...] = GROUND
    a = alpha[..., None]
    out = win * a + ground * (1 - a)

    Image.fromarray(out.round().astype(np.uint8)).save(OUT)
    h, w = win.shape[:2]
    print("  %dx%d picture; he fills x %d..%d, y %d..%d of it, on %s"
          % (w, h, xs.min(), xs.max(), ys.min(), ys.max(), GROUND))
    print("  -> %s" % os.path.relpath(OUT, REPO))


if __name__ == "__main__":
    main()
