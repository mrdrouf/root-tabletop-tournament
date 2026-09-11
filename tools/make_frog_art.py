#!/usr/bin/env python3
"""Cut the militant frog off the Lilypad Diaspora's board art, for the 3-Player Draft button.

Maintainer, 2026-09-10: "The art for this should be the pissed off frog that represents the militant
side of frogs on the frog faction board", then "remove the background of the frog on the 3 player
draft. show only from the hip up not the whole body like the others. can you also make him look the
other side do a 180 flip."

    python3 tools/make_frog_art.py

He is the right-hand of the two frogs in the board's illustration -- brow down, mouth turned, hunched
in dungarees and a bandolier, where the one beside him is upright and grinning.

CUT BY A TRACED OUTLINE, because nothing else works on this one. He is drawn in the same olive as the
ground he stands on -- his head reads (165,152,60) against a ground of (156,146,71) to (188,181,91) --
so no colour key separates them, and the white keyline that would have served as a boundary is broken
along a third of his silhouette, so a flood leaks through it into him.

THE FIRST TRACE WAS 21 POINTS AND IT SHOWED. Maintainer, 2026-09-10, on the shipped button: "the frog
is not cut properly you hacked part of th his body and there is still background around". Both, and
they are the same fault: a 21-point hull cannot follow a hunched figure, so it cut the corners off him
AND swallowed slabs of lily pad in every concavity. He suggested asking Codex, which was the right
call -- not because the technique is different (it traced a polygon too) but because it traced 153
points where I had traced 21, and then snapped the edge onto the ink.

So: OUTLINE below is his silhouette read off the board at full size, hip up, 153 points, following the
OUTSIDE of the ink including the white keyline, which is part of the drawing. SNAP then walks the mask
edge inward until it meets dark ink on the four runs where a polygon is still loose against a curve.

TRANSPARENT, not laid on the button's colour. This used to composite him onto rtt3PBtn's own green so
that no rectangle showed -- which only works while the mask is right, and hides it when it is not. On
alpha there is nothing to hide: tools/relabel.py trims the art by its ALPHA bbox (art_alpha_topband)
and composites it straight onto the button, so a background pixel that survives the cut is visible as
itself rather than blending into the ground.

FLIPPED, so he faces the other way, and the picture is trimmed to the mask's own bounds.

Reads assets/src_art/frog_board.png (the board face as Steam serves it) and writes
assets/src_art/frog_militant.png as RGBA.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
SRC = os.path.join(REPO, "assets", "src_art", "frog_board.png")
OUT = os.path.join(REPO, "assets", "src_art", "frog_militant.png")

# The picture, on the board's own 2205x1701: hip up, with a little air on every side. OUTLINE below is
# in THIS window's coordinates.
WINDOW = (1555, 1020, 2090, 1520)

OUTLINE = [(158, 499), (158, 484), (159, 470), (162, 459), (146, 453), (133, 446), (122, 434),
           (115, 420), (111, 405), (108, 386), (106, 363), (104, 346), (104, 330), (105, 320),
           (107, 315), (105, 296), (104, 279), (103, 270), (108, 267), (121, 265), (124, 266),
           (127, 257), (131, 250), (130, 244), (116, 236), (103, 227), (91, 215), (82, 202),
           (75, 189), (69, 176), (64, 159), (61, 146), (60, 131), (61, 117), (62, 109),
           (57, 104), (50, 99), (39, 94), (28, 88), (17, 83), (7, 76), (8, 71), (12, 63),
           (15, 60), (20, 65), (23, 70), (33, 77), (43, 86), (52, 94), (59, 103), (65, 106),
           (68, 93), (73, 81), (80, 68), (89, 56), (98, 47), (107, 41), (118, 36), (131, 31),
           (145, 29), (160, 29), (177, 29), (184, 24), (191, 21), (199, 20), (207, 21),
           (215, 25), (222, 31), (231, 28), (239, 25), (246, 20), (253, 17), (258, 14),
           (263, 14), (264, 17), (262, 23), (258, 31), (271, 33), (288, 38), (304, 44),
           (319, 52), (335, 62), (349, 77), (357, 76), (364, 79), (370, 86), (374, 92),
           (376, 98), (374, 104), (379, 108), (385, 107), (391, 109), (398, 115), (401, 123),
           (401, 129), (406, 136), (412, 145), (419, 153), (430, 156), (441, 162), (453, 172),
           (463, 183), (471, 196), (478, 210), (483, 223), (486, 228), (486, 233), (480, 234),
           (488, 244), (497, 256), (506, 270), (514, 282), (521, 294), (523, 301), (522, 311),
           (520, 321), (525, 326), (530, 333), (533, 341), (532, 350), (529, 359), (525, 368),
           (517, 372), (507, 374), (507, 383), (499, 380), (498, 392), (495, 405), (490, 418),
           (483, 432), (482, 437), (485, 448), (486, 457), (483, 465), (479, 470), (472, 474),
           (466, 477), (459, 478), (454, 476), (449, 472), (445, 463), (441, 472), (435, 480),
           (426, 483), (416, 483), (405, 480), (398, 475), (394, 470), (393, 459), (386, 470),
           (378, 478), (371, 481), (372, 499)]

# WHERE A POLYGON IS STILL LOOSE. Four runs where the silhouette curves faster than a straight segment
# can follow, and the drawing has solid dark ink to snap to: down his back (left of the head), down the
# front of the dungarees, the outside of the fist, and under it. Each walks in from the mask's edge
# until it meets ink, and drops everything outside that -- so the cut lands ON the line rather than a
# few pixels of lily pad outside it.
#   (axis, from, to, search-from, search-to, keep)  -- see snap()
SNAP = [("row", 112, 245, -3, 150, "left"),
        ("row", 330, 500, -3, 15, "left"),
        ("row", 375, 477, 440, 510, "right"),
        ("col", 374, 486, 449, 489, "below")]
INK = (105, 105, 95)                   # darker than this on all three channels is the drawn line

# THE STALK IS NOT HIS. Maintainer, 2026-09-11: "remove the little stem pointing out of the frog mount
# it s background in the 3 player draft art." An orange reed lies across the panel and touches the
# corner of his mouth, so the trace took it for part of him -- it came out as a stick poking out of his
# face with nothing holding it up.
#
# Erased as a BAND ALONG THE STALK rather than a box: it meets his keyline at a shallow angle, and any
# rectangle wide enough to reach the far end also bites into his jaw. Inside that band the drawn line
# is protected -- white is his keyline, near-black is his mouth -- but ONLY within ERASE_KEEP_X of him,
# because the stalk has white speckle highlights of its own further out, and protecting those left a
# dotted trail hanging in the air where the stalk had been.
ERASE = [(0, 46), (70, 86), (70, 120), (0, 82)]
ERASE_KEEP_X = 48                      # the keyline only exists this close to him
ERASE_WHITE = 175                      # min channel above this is the drawn keyline
ERASE_DARK = 95                        # max channel below this is the drawn mouth

FEATHER = 1.0                          # the edge softened, so it is not a cut-out against the button
MARGIN = 6                             # kept around him once the mask decides the framing


def snap(a, alpha):
    """Walk the mask edge in to the ink on the runs where the traced polygon is loose."""
    dark = (a[:, :, 0] < INK[0]) & (a[:, :, 1] < INK[1]) & (a[:, :, 2] < INK[2])
    for axis, lo, hi, s0, s1, keep in SNAP:
        for i in range(lo, min(hi, alpha.shape[0] if axis == "row" else alpha.shape[1])):
            if axis == "row":
                on = np.where(alpha[i] > 0)[0]
                if not len(on):
                    continue
                if keep == "left":
                    start = max(0, on[0] + s0)
                    xs = np.where(dark[i, start:start + (s1 - s0 if s1 > s0 else s1)])[0]
                    if len(xs):
                        alpha[i, :start + xs[0]] = 0
                else:
                    xs = np.where(dark[i, s0:s1])[0]
                    if len(xs):
                        alpha[i, s0 + xs[-1] + 1:] = 0
            else:
                ys = np.where(dark[s0:s1, i])[0]
                if len(ys):
                    alpha[s0 + ys[-1] + 1:, i] = 0
    return alpha


def unstem(a, alpha, size):
    """Take the background stalk off his mouth, leaving his own lines where they cross it."""
    pm = Image.new("L", size, 0)
    ImageDraw.Draw(pm).polygon(ERASE, fill=255)
    band = np.asarray(pm) > 127
    h, w = alpha.shape
    near = np.tile(np.arange(w), (h, 1)) >= ERASE_KEEP_X
    mx, mn = a.max(2).astype(int), a.min(2).astype(int)
    keep = ((mn > ERASE_WHITE) | (mx < ERASE_DARK)) & near
    alpha = alpha.copy()
    alpha[band & ~keep] = 0
    return alpha


def main():
    if not os.path.exists(SRC):
        sys.exit("missing %s" % SRC)
    board = Image.open(SRC).convert("RGB")
    win = board.crop(WINDOW)
    a = np.asarray(win)

    m = Image.new("L", win.size, 0)
    ImageDraw.Draw(m).polygon(OUTLINE, fill=255)
    alpha = snap(a, np.asarray(m).copy())
    alpha = unstem(a, alpha, win.size)

    box = Image.fromarray(alpha).getbbox()
    x0, y0, x1, y1 = (max(0, box[0] - MARGIN), max(0, box[1] - MARGIN),
                      min(win.width, box[2] + MARGIN), min(win.height, box[3] + MARGIN))
    soft = Image.fromarray(alpha).crop((x0, y0, x1, y1)).filter(ImageFilter.GaussianBlur(FEATHER))
    im = Image.merge("RGBA", (*win.crop((x0, y0, x1, y1)).split(), soft))
    im = im.transpose(Image.FLIP_LEFT_RIGHT)
    im.save(OUT)

    op = (np.asarray(soft) > 127).mean()
    print("  the militant frog, hip up and flipped: %dx%d on alpha, %.0f%% of the frame is him"
          % (im.size[0], im.size[1], 100 * op))
    print("  -> %s" % os.path.relpath(OUT, REPO))


if __name__ == "__main__":
    main()
