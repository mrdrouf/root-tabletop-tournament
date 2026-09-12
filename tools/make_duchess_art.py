#!/usr/bin/env python3
"""Cut the Duchess of Mud off her card, for the 5-Player Draft button.

Maintainer, 2026-09-12: "replace the art of the 5 player draft with the figure of the duchess of mud
card. apply the same you did than for the 3 player draft button."

    python3 tools/make_duchess_art.py

The 5-player button wore a picture of the Marsh, which was the map that draft used to force. It does
not force one any more, so the art was describing something the button had stopped doing -- and the
Duchess is the better answer anyway: she is a figure, like the militant frog on the 3-Player button
and the Adventurer on the Theme button, rather than a piece of board.

THE SAME TREATMENT AS THE FROG: cut out, on TRANSPARENCY, so tools/relabel.py trims her by her own
alpha bbox (art_alpha_topband) and lays her straight on the button. A background pixel that survives
the cut then shows as itself rather than blending into the button's colour, which is what makes a bad
cut visible instead of merely present.

SHE IS FLOODED OUT, NOT TRACED. The frog needed 153 hand-placed points because he is drawn in the same
olive as the ground he stands on. The Duchess is not: she sits against a red and orange checkerboard,
and almost all of her -- grey head, grey robe, blue sash, the grey-blue sheet she is reading -- is
either neutral or cool. So the ground can be keyed and flooded, the way the Adventurer's wall and the
otter's river are.

WARM *AND* DARK, though, and the second half is what took the tries. Her hands and snout are pink, and
pink is warm: keyed on warmth alone the flood went straight up her arms and ate them. But the
checkerboard is a mid-dark red -- around 80 to 90 mean -- where her skin is 200, so brightness tells
them apart even though colour does not.

SEEDED FROM THE SIDES, not the corners or the top. Her head is cut off by the card's own border, so she
touches the top edge of the picture: a flood seeded along the top row walks in through her scalp. The
checkerboard runs the full height of both sides, so that is where the flood starts.

AND THE BOTTOM IS CLOSED. The window stops at the desk's top edge -- she is taken from the desk up, as
the frog is taken from the hip up -- and that crop leaves her silhouette open at the bottom, so the
flood would climb into her from underneath. Cropping above the desk rather than through her is what
avoids needing to close it by hand.

Reads assets/src_art/duchess_card.png (the minister card as the Duchy's board carries it) and writes
assets/src_art/duchess_mud.png as RGBA.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
sys.path.insert(0, HERE)
from make_theme_art import m2i, dilate, erode, flood, fill_holes          # noqa: E402

SRC = os.path.join(REPO, "assets", "src_art", "duchess_card.png")
OUT = os.path.join(REPO, "assets", "src_art", "duchess_mud.png")

# THE PICTURE, on the 361x311 card: inside the printed border on three sides, and stopping at the
# desk's top edge. The desk is a flat cream band from y 184 down to the title, and everything below
# that line is furniture rather than her.
WINDOW = (12, 12, 349, 184)

WARM = 42          # red-over-green: the checkerboard is +52 to +66, her head is 0, her robe is cool
DARK = 185         # ...and it is never bright: the squares are 80-90 mean, her skin is 200
SEAL = 3           # closes the drawn outlines before the ground is flooded

SPECK = 1          # opened by this, to shed the single pixels the key leaves in her shading
FEATHER = 0.7      # and the edge is softened, so she is not a cut-out against the button
MARGIN = 3


def figure(win):
    """The Duchess, as a mask over the window: everything the checkerboard cannot reach."""
    a = win.astype(int)
    ground = ((a[..., 0] - a[..., 1]) > WARM) & (a.mean(2) < DARK)
    ground = erode(dilate(ground, SEAL), SEAL)

    h, w = ground.shape
    seen = np.zeros((h, w), bool)
    for y in range(0, h, 4):                       # both full-height sides, which are all checkerboard
        for x in (0, w - 1):
            if ground[y, x] and not seen[y, x]:
                seen |= flood(ground, (y, x))

    her = fill_holes(~seen)
    her = fill_holes(dilate(erode(her, SPECK), SPECK))
    return her


def main():
    if not os.path.exists(SRC):
        sys.exit("missing %s -- it is the 'Duchess' asset off the Duchy's ministers board" % SRC)
    card = np.asarray(Image.open(SRC).convert("RGB"))
    x0, y0, x1, y1 = WINDOW
    win = card[y0:y1, x0:x1]

    mask = figure(win)
    box = Image.fromarray((mask * 255).astype(np.uint8)).getbbox()
    if box is None:
        sys.exit("the cut found nothing; the key or the window is wrong")
    bx0, by0, bx1, by1 = (max(0, box[0] - MARGIN), max(0, box[1] - MARGIN),
                          min(win.shape[1], box[2] + MARGIN), min(win.shape[0], box[3] + MARGIN))

    soft = Image.fromarray((mask * 255).astype(np.uint8)).crop((bx0, by0, bx1, by1)) \
                .filter(ImageFilter.GaussianBlur(FEATHER))
    rgb = Image.fromarray(win.astype(np.uint8)).crop((bx0, by0, bx1, by1))
    Image.merge("RGBA", (*rgb.split(), soft)).save(OUT)

    op = (np.asarray(soft) > 127).mean()
    print("  the Duchess of Mud, desk up: %dx%d on alpha, %.0f%% of the frame is her"
          % (bx1 - bx0, by1 - by0, 100 * op))
    print("  -> %s" % os.path.relpath(OUT, REPO))


if __name__ == "__main__":
    main()
