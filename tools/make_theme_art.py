#!/usr/bin/env python3
"""Cut the Adventurer off his card, for the Theme button's artwork.

Maintainer, 2026-09-09: "theme this month is marsh 5 person draft; can you also use the vagabond
adventurer art for the theme button and don t forget to adjust the background of the button" --
and, when asked how much of him to take: "Adventurer Vagabond head only." Then, seeing the head on
its own beside the rest of the board: "for the theme button logo, keep part of the body of the
adventurer like the draft art button" -- the 4-Player Draft button, which is an owl cropped at the
chest with its arms in frame. So he keeps his staff, his shield, his cloak and the gourd at his neck,
and the picture stops at the chest.

The Theme button's art used to be a fox vagabond's head on a flat dark ground, lifted out of the base
mod. Two things have to match that, or the button stops looking like the rest of the board:

THE GROUND. The card's own background is a pale lilac wall of crosses; dropped on the button it would
read as a card sitting on the board rather than as a portrait. So the owl is CUT OUT and laid on the
same dark green-grey the fox sat on -- that is what "don't forget to adjust the background" means.

THE FRAME. tools/relabel.py scales a square button's art to fit and centres it, so the art's own
proportions decide how big he lands. The button's art area is landscape and a portrait is not, so the
window is chosen wider than he is and he stands in the middle of it with the ground either side --
the same shape the fox had, and near enough the 4-Player Draft owl's to sit beside it.

    python3 tools/make_theme_art.py

Reads assets/src_art/vagabond_adventurer.png (the Adventurer card as Steam serves it) and writes
assets/src_art/theme_adventurer.png, which tools/relabel.py turns into the button.
"""
import os
import sys
from collections import deque

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
SRC = os.path.join(REPO, "assets", "src_art", "vagabond_adventurer.png")
OUT = os.path.join(REPO, "assets", "src_art", "theme_adventurer.png")

# THE PICTURE ITSELF, on the 589x800 card: this window IS the framing. Its sides fall just outside him
# (the shield reaches x 178, the cloak x 420) so there is a little ground either side; its bottom cuts
# him at the chest, just under the gourd; and its top sits a hair above his tufts, where only the
# staff crosses it.
#
# ITS SHAPE IS THE BUTTON'S. relabel.py fits the art to a 292x208 area and takes the smaller of the two
# ratios, so a tall picture is scaled by its height and lands narrow with the button showing either
# side. At 319x247 the two ratios are near enough equal that he arrives as big as the area allows --
# which is what makes him read at the same weight as the 4-Player Draft owl beside him. Taking another
# 20 rows off the top would only find more empty ground above his head.
WINDOW = (174, 168, 450, 415)          # left, top, right, bottom

# THE CARD'S GROUND. It is flat and unsaturated, and it comes in two tempers: the lilac and grey of
# the wall (neutral, sat under 26) and a warmer grey along the card's right edge (sat about 41), which
# a single threshold either misses or takes the owl's cream with. Two rules, one for each, keyed on
# warmth: the ground is never more than 40 redder than it is blue, and the owl's feathers always are.
GROUND_SAT = 26
GROUND_MEAN = 120
WARM_MEAN = 150
WARM_RB = 40
WARM_SAT = 45
SEAL = 2                               # closes the drawn outlines before the ground is flooded

# HE IS ONE ISLAND with his staff, his shield and his cloak, because they all touch -- which is why
# the head-only version had to cut them off him by hand, at a column, a row and a colour. Keeping the
# body means keeping the island, so all of that is gone and the flood is the whole of it.
SEED = (102, 187)                      # a point on his face, in window coordinates

TRIM = 1                               # px of the mask's own edge to drop: the card's pale ground
                                       # bleeds one pixel into the antialiased outline, and left on
                                       # it draws a white rim all round the head against the dark
FEATHER = 0.7                          # and the edge is then softened, so it is not a cut-out

GROUND = (0x49, 0x51, 0x4b)            # THE BUTTON'S OWN COLOUR, not the fox art's ground, which was
                                       # two counts off it: rttThemeBtn is drawn "#49514b", so keying
                                       # the art to that leaves no rectangle around him at all


def m2i(m):
    return Image.fromarray((m * 255).astype(np.uint8))


def dilate(m, k):
    return np.asarray(m2i(m).filter(ImageFilter.MaxFilter(2 * k + 1))) > 127


def erode(m, k):
    return np.asarray(m2i(m).filter(ImageFilter.MinFilter(2 * k + 1))) > 127


def flood(mask, seed):
    """Everything reachable from `seed` through True cells of `mask`, four-connected."""
    h, w = mask.shape
    seen = np.zeros((h, w), bool)
    y0, x0 = seed
    if not mask[y0, x0]:
        return seen
    seen[y0, x0] = True
    q = deque([(y0, x0)])
    while q:
        y, x = q.popleft()
        for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
            if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
                seen[ny, nx] = True
                q.append((ny, nx))
    return seen


def fill_holes(m):
    """m with its enclosed pockets closed -- the ground rules poke a few in the crown's bluish wash."""
    h, w = m.shape
    pad = np.ones((h + 2, w + 2), bool)
    pad[1:-1, 1:-1] = ~m
    return ~flood(pad, (0, 0))[1:-1, 1:-1]


def figure_mask(win):
    """The Adventurer, as an alpha over the window: everything the card's ground does not reach."""
    a = win.astype(int)
    mx, mn = a.max(2), a.min(2)
    mean = a.mean(2)
    warmth = a[..., 0] - a[..., 2]
    sat = np.where(mx == 0, 0, (mx - mn) * 255 // np.maximum(mx, 1))

    ground = ((sat < GROUND_SAT) & (mean > GROUND_MEAN)) | \
             ((mean > WARM_MEAN) & (warmth < WARM_RB) & (sat < WARM_SAT))
    owl = fill_holes(flood(erode(dilate(~ground, SEAL), SEAL), SEED))

    owl = fill_holes(flood(erode(owl, TRIM), SEED))
    return np.asarray(m2i(owl).filter(ImageFilter.GaussianBlur(FEATHER))).astype(float) / 255.0


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
