#!/usr/bin/env python3
"""Cut the Adventurer's head off his card, for the Theme button's artwork.

Maintainer, 2026-09-09: "theme this month is marsh 5 person draft; can you also use the vagabond
adventurer art for the theme button and don t forget to adjust the background of the button" --
and, when asked how much of him to take: "Adventurer Vagabond head only."

The Theme button's art used to be a fox vagabond's head on a flat dark ground, lifted out of the base
mod. Two things have to match that, or the button stops looking like the rest of the board:

THE GROUND. The card's own background is a pale lilac wall of crosses; dropped on the button it would
read as a card sitting on the board rather than as a portrait. So the owl is CUT OUT and laid on the
same dark green-grey the fox sat on -- that is what "don't forget to adjust the background" means.

THE FRAME. tools/relabel.py scales a square button's art to fit and centres it, so the art's own
proportions decide how big the head lands. The fox came with his shoulders and filled his frame; the
owl is a head and nothing else, so the frame is cut tight around him instead -- which is what makes
relabel.py blow him up to the same weight on the button as the six map buttons next to it.

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

# The head, roughly, on the 589x800 card: everything below is measured inside this window.
WINDOW = (165, 140, 435, 375)          # left, top, right, bottom

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

# WHAT IS NOT THE HEAD. The owl is one island with his staff, his shield and his cloak, because they
# all touch. The staff runs down the left at x < 81 with its own inked edge; the cloak is the only
# cool colour in the window; and the chin's outline is the last thing above y = 199.
STAFF_X = 81
CHIN_Y = 199
CLOAK_RB = 5                           # blue-grey: barely redder than blue...
CLOAK_MEAN = 175                       # ...and darker than the bluish wash on the crown
SEED = (120, 170)                      # a point on the face, in window coordinates

TRIM = 1                               # px of the mask's own edge to drop: the card's pale ground
                                       # bleeds one pixel into the antialiased outline, and left on
                                       # it draws a white rim all round the head against the dark
FEATHER = 0.7                          # and the edge is then softened, so it is not a cut-out

GROUND = (0x49, 0x51, 0x4b)            # THE BUTTON'S OWN COLOUR, not the fox art's ground, which was
                                       # two counts off it: rttThemeBtn is drawn "#49514b", so keying
                                       # the art to that leaves no rectangle around the head at all
FRAME_W, FRAME_H = 250, 196            # tight to the head, so relabel.py scales it up to fill the
FOOT = 4                               # button the way the fox's head and shoulders used to


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


def head_mask(win):
    """The Adventurer's head, alone, as an alpha over the window."""
    a = win.astype(int)
    mx, mn = a.max(2), a.min(2)
    mean = a.mean(2)
    warmth = a[..., 0] - a[..., 2]
    sat = np.where(mx == 0, 0, (mx - mn) * 255 // np.maximum(mx, 1))

    ground = ((sat < GROUND_SAT) & (mean > GROUND_MEAN)) | \
             ((mean > WARM_MEAN) & (warmth < WARM_RB) & (sat < WARM_SAT))
    owl = fill_holes(flood(erode(dilate(~ground, SEAL), SEAL), SEED))

    head = owl.copy()
    head[:, :STAFF_X] = False
    head[CHIN_Y:, :] = False
    head &= ~((warmth < CLOAK_RB) & (mean < CLOAK_MEAN))
    head = fill_holes(flood(head, SEED))
    head = fill_holes(flood(erode(head, TRIM), SEED))
    return np.asarray(m2i(head).filter(ImageFilter.GaussianBlur(FEATHER))).astype(float) / 255.0


def main():
    if not os.path.exists(SRC):
        sys.exit("missing %s" % SRC)
    card = np.asarray(Image.open(SRC).convert("RGB"))
    x0, y0, x1, y1 = WINDOW
    win = card[y0:y1, x0:x1]

    alpha = head_mask(win)
    ys, xs = np.where(alpha > 0.5)
    hx0, hx1, hy0, hy1 = xs.min(), xs.max(), ys.min(), ys.max()

    out = np.zeros((FRAME_H, FRAME_W, 3), float)
    out[...] = GROUND
    # centred across, standing FOOT off the bottom: the head is the whole picture, so where it sits
    # in the frame is the whole composition
    dx = (FRAME_W - (hx1 - hx0 + 1)) // 2 - hx0
    dy = FRAME_H - FOOT - (hy1 + 1)
    for y in range(win.shape[0]):
        ty = y + dy
        if not (0 <= ty < FRAME_H):
            continue
        for x in range(win.shape[1]):
            tx = x + dx
            if 0 <= tx < FRAME_W and alpha[y, x] > 0:
                f = alpha[y, x]
                out[ty, tx] = win[y, x] * f + out[ty, tx] * (1 - f)

    Image.fromarray(out.round().astype(np.uint8)).save(OUT)
    print("  head %dx%d cut from the card, framed %dx%d on %s"
          % (hx1 - hx0 + 1, hy1 - hy0 + 1, FRAME_W, FRAME_H, GROUND))
    print("  -> %s" % os.path.relpath(OUT, REPO))


if __name__ == "__main__":
    main()
