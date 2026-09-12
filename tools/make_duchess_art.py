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

# THE PICTURE, on the 361x311 card: the whole of it, stopping at the desk's top edge.
#
# EVERY EDGE IS MEASURED, because guessing at them cost her the top of her head. Maintainer,
# 2026-09-12: "you cut the top of the head of the duchess that s bad keep the entirety of the head."
# The window began at y=12 on the assumption that the border needed clearing, and her crown is at
# y=8 -- the picture's very first row -- so four rows of skull went with the border.
#
# The card is: black edge, a gold band, one dark rule at x=7 / y=7, and then the picture. So the
# interior is x 8..351 and y 8..183, and the desk is the flat cream band from y 184 down to the title.
WINDOW = (8, 8, 352, 184)

WARM = 42          # red-over-green: the checkerboard is +52 to +66, her head is 0, her robe is cool
DARK = 185         # ...and it is never bright: the squares are 80-90 mean, her skin is 200
SEAL = 3           # closes the drawn outlines before the ground is flooded

SPECK = 1          # opened by this, to shed the single pixels the key leaves in her shading
FEATHER = 0.7      # and the edge is softened, so she is not a cut-out against the button
MARGIN = 3

# THE CAP: how much of a shape the card's gold frame cuts off, and what may be put back.
CAP_PROBE = 10     # rows of a clipped shape measured to fit its dome
CAP_MAX = 12       # ...and never invent more than this many rows on top of it
CAP_MIN_W = 8      # a run narrower than this on the first row is a whisker, not a skull
CAP_MIN_ROWS = 2   # a shape missing less than this is left alone; a one-row cap is only a nub


def figure(win):
    """The Duchess, as a mask over the window: everything the checkerboard cannot reach."""
    a = win.astype(int)
    ground = ((a[..., 0] - a[..., 1]) > WARM) & (a.mean(2) < DARK)
    ground = erode(dilate(ground, SEAL), SEAL)

    h, w = ground.shape
    seen = np.zeros((h, w), bool)

    # SEEDED FROM THE SIDES *AND ALONG THE TOP*. Both sides are checkerboard the whole way down, so
    # they were seeded from the start. The top row was not, on the theory that a flood let in there
    # would walk through her scalp -- and that theory is wrong, which is why the maintainer could
    # still see, 2026-09-12, "residual background on top of the middel of her nose". The flood only
    # ever walks through pixels the key calls ground, and her scalp is neutral grey, so it is not
    # ground and the flood cannot enter it. What the top row DOES reach is the one patch of
    # checkerboard the sides cannot: the wedge between the back of her head and the top of her snout,
    # walled in by her on both sides, closed underneath where head meets snout, and open only at the
    # frame. Twenty-four pixels of mustard tile, kept as part of her for want of a seed.
    seeds = [(y, x) for y in range(0, h, 4) for x in (0, w - 1)]
    seeds += [(0, x) for x in range(w)]
    for y, x in seeds:
        if ground[y, x] and not seen[y, x]:
            seen |= flood(ground, (y, x))

    her = fill_holes(~seen)
    her = fill_holes(dilate(erode(her, SPECK), SPECK))
    return her


def runs(row):
    """The row's True stretches, as (first, last) pairs."""
    xs = np.where(row)[0]
    out = []
    if not len(xs):
        return out
    s = p = xs[0]
    for x in xs[1:]:
        if x != p + 1:
            out.append((s, p))
            s = x
        p = x
    out.append((s, p))
    return out


def cap_fit(her, l0, r0):
    """How far above the frame the shape starting at l0..r0 on row 0 goes, and the arc that gets there.

    A dome's half-width near its apex grows as the SQUARE ROOT of the drop below it -- that is just a
    circle, x^2 + y^2 = r^2, read the other way round. So hw^2 is a straight line in y, and the line's
    own root is the apex. Fit it on the rows that survive and read off the rows that did not.
    """
    ls, rs = [l0], [r0]
    for y in range(1, CAP_PROBE):
        cand = [(l, r) for l, r in runs(her[y]) if r >= ls[-1] - 3 and l <= rs[-1] + 3]
        if not cand:
            break
        ls.append(min(c[0] for c in cand))
        rs.append(max(c[1] for c in cand))
    ys = np.arange(len(ls), dtype=float)
    k, c = np.polyfit(ys, ((np.array(rs) - np.array(ls)) / 2.0) ** 2, 1)
    mx, bx = np.polyfit(ys, (np.array(ls) + np.array(rs)) / 2.0, 1)
    return (c / k if k > 0 else 0.0), k, c, mx, bx


def recap(win, her):
    """Put back the tops of the shapes the card's gold frame cuts off.

    Maintainer, 2026-09-12, twice: "you still have the top of the head of the duchess cut in the art."

    HE IS RIGHT AND THE CARD IS THE REASON. The artist drew her head running into the gold frame:
    on the picture's first row her skull is already 48 pixels wide and still widening downward, so
    its apex is printed over -- it is not in this image, nor in any other. The Duchy rules board's
    header carries a different mole (blue neckerchief, no crown), the wiki holds no minister art at
    all, and the board's own Unswayed Ministers box is empty. There is nothing to recover from.

    So the crest is rebuilt rather than found, and only the crest: six rows, off an arc measured from
    the twenty rows of skull the card did keep. Each new row is the first surviving row's OWN pixels
    resampled narrower, which carries its white rim line and its left-to-right grey shading up to the
    apex instead of flooding a flat grey that would read as a patch.

    Her snout is clipped too, but by less than a row and a half, so CAP_MIN_ROWS leaves it: capping it
    would add a pale nub where the notch between head and snout should simply be empty.
    """
    caps = []
    for l0, r0 in runs(her[0]):
        if r0 - l0 + 1 < CAP_MIN_W:
            continue
        miss, k, c, mx, bx = cap_fit(her, l0, r0)
        n = int(min(CAP_MAX, round(miss)))
        if n >= CAP_MIN_ROWS:
            caps.append((l0, r0, n, k, c, mx, bx))
    if not caps:
        return win, her, 0

    n_add = max(cp[2] for cp in caps)
    h, w, _ = win.shape
    win2 = np.zeros((h + n_add, w, 3), np.uint8)
    win2[n_add:] = win
    her2 = np.zeros((h + n_add, w), bool)
    her2[n_add:] = her

    for l0, r0, n, k, c, mx, bx in caps:
        strip = Image.fromarray(win[0:1, l0:r0 + 1])
        for j in range(n):
            y = -(n - j)                                   # window row, negative: above the picture
            hw = np.sqrt(max(0.0, k * y + c))
            wide = int(round(2 * hw))
            if wide < 1:
                continue
            x = max(0, min(w - wide, int(round(mx * y + bx - wide / 2.0))))
            win2[n_add - n + j, x:x + wide] = np.asarray(strip.resize((wide, 1), Image.BILINEAR))[0]
            her2[n_add - n + j, x:x + wide] = True
    return win2, her2, n_add


def main():
    if not os.path.exists(SRC):
        sys.exit("missing %s -- it is the 'Duchess' asset off the Duchy's ministers board" % SRC)
    card = np.asarray(Image.open(SRC).convert("RGB"))
    x0, y0, x1, y1 = WINDOW
    win = card[y0:y1, x0:x1]

    win, mask, capped = recap(win, figure(win))
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
    print("  %d rows of skull rebuilt above the card's frame" % capped)
    print("  -> %s" % os.path.relpath(OUT, REPO))


if __name__ == "__main__":
    main()
