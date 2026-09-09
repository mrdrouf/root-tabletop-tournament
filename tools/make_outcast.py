#!/usr/bin/env python3
"""Cut the two Outcast token faces out of their yellow tile, for the Lizard Board's own face.

The Lizard Board draws the Outcast symbol into the printed slot under whichever suit the Lizard
Wizard's marker is sitting on. The picture it draws is the TOKEN'S OWN ART -- maintainer, 2026-09-07:
"the symbol is on the token that spawns on the lizard wizard that is used to show the suit outcast."

Two things this has to get right, both of which the hand-made first pass got wrong:

KEY THE YELLOW BY UNMIXING, NOT BY THRESHOLD. The art is one flat ink colour laid on one flat yellow;
every pixel between them is a blend of the two. Solving each pixel for its blend fraction recovers a
real alpha -- the grain and the antialiased edges come out as partial alpha over a flat ink -- where a
binary key leaves a hard yellow-tinged fringe. That fringe is what "the background is still off" was.

CROP TO THE ART, SYMMETRICALLY, AND SQUARE. The tile carries a scatter of 1-11px specks outside the
drawing (a stray 3px one near the Marker's bottom-left corner). A naive bounding box catches them, so
the first pass cropped to 232x236 and 233x226 -- two different aspect ratios, neither centred on the
drawing. Drawn into one square UI box those come out stretched by different amounts and off-centre in
the slot. Dropping components under MIN_BLOB and then cropping symmetrically about the drawing's own
centre gives a square whose edges ARE the drawing's edges, so the board can size it by one number and
trust that the symbol is centred in its slot.

    python3 tools/make_outcast.py

Writes assets/labels/outcast_v<N>_<md5>.png and outcast_hated_v<N>_<md5>.png, and prints the URLs and
the ring size for gen/src/content.lua.
"""
import hashlib
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
SRC = os.path.join(REPO, "assets", "src_art")
OUT = os.path.join(REPO, "assets", "labels")
CDN = "https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/assets/labels/%s"

BG = np.array([222, 213, 49], float)      # the token tile's flat yellow
MIN_BLOB = 200                            # px; the drawing's parts are 6k+, the dust is 1-11
VERSION = 6                               # bump when the art changes, so the CDN filename changes

# THE SYMBOL IS DRAWN AT ITS OWN WEIGHT. It used to be fattened by 2px, because the board's printed
# thorn frame is a heavier stroke than the token's and white kept peeking out from under it --
# maintainer, 2026-09-08: "the white is a bit larger maybe make the symbol a tiny bit fater so it
# fits over it."
#
# That is no longer the board's shape. Maintainer, 2026-09-09: "instead of trying to fill the white
# space with the decal you could redo the white shape on the board so you fill it perfectly and so
# erase the white drawing by painting with the background color ... it also allows you to make the
# decal not so fat as it is now and its normal thinness." tools/make_board.py now paints the printed
# frames out and stamps THIS DRAWING back in white, at the size the board will draw it. The symbol
# covers its own outline exactly, so there is nothing left to thicken it against.
DILATE = 0                                # none: the board no longer has anything to cover up
RING_LOCAL = 0.1388                       # the printed frame's own width, in board-local units

FACES = [
    # name,               source file,            ink colour
    ("outcast",           "outcast_marker.png",   np.array([134, 131, 129], float)),
    ("outcast_hated",     "outcast_hated.png",    np.array([215,  70,  41], float)),
]


def unmix(rgb, ink):
    """Alpha of a flat `ink` over the flat `BG`, per pixel, least squares along the BG->ink line."""
    d = ink - BG
    a = ((rgb - BG) @ d) / (d @ d)
    return np.clip(a, 0.0, 1.0)


def keep_real_ink(alpha):
    """Drop the specks: keep only connected components of MIN_BLOB pixels or more."""
    solid = alpha > 0.35
    h, w = solid.shape
    seen = np.zeros((h, w), bool)
    keep = np.zeros((h, w), bool)
    for sy in range(h):
        for sx in range(w):
            if not solid[sy, sx] or seen[sy, sx]:
                continue
            stack, blob = [(sy, sx)], []
            seen[sy, sx] = True
            while stack:
                y, x = stack.pop()
                blob.append((y, x))
                for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                    if 0 <= ny < h and 0 <= nx < w and solid[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        stack.append((ny, nx))
            if len(blob) >= MIN_BLOB:
                for y, x in blob:
                    keep[y, x] = True
    return keep


def build(name, src_file, ink):
    src = os.path.join(SRC, src_file)
    rgb = np.asarray(Image.open(src).convert("RGB")).astype(float)
    alpha = unmix(rgb, ink)

    keep = keep_real_ink(alpha)
    dropped = int((alpha > 0.35).sum() - keep.sum())
    # a speck's own antialiasing goes with it; only ink attached to a real blob survives
    grown = keep.copy()
    for _ in range(2):
        g = grown.copy()
        g[1:, :] |= grown[:-1, :]
        g[:-1, :] |= grown[1:, :]
        g[:, 1:] |= grown[:, :-1]
        g[:, :-1] |= grown[:, 1:]
        grown = g
    alpha = np.where(grown, alpha, 0.0)

    if DILATE > 0:
        from PIL import ImageFilter
        grey = Image.fromarray(np.round(alpha * 255).astype(np.uint8), "L")
        grey = grey.filter(ImageFilter.MaxFilter(2 * DILATE + 1))
        alpha = np.asarray(grey).astype(float) / 255.0

    ys, xs = np.where(alpha > 0.35)
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    cx, cy = (x0 + x1) / 2.0, (y0 + y1) / 2.0
    half = max(x1 - x0 + 1, y1 - y0 + 1) / 2.0
    # symmetric about the drawing's centre: the crop's edges are the drawing's edges, so the board
    # can place it by its centre and size it by one number
    left, top = int(round(cx - half)), int(round(cy - half))
    side = int(round(2 * half))

    canvas = np.zeros((side, side, 4), np.uint8)
    canvas[..., 0], canvas[..., 1], canvas[..., 2] = [int(round(c)) for c in ink]
    sub = np.zeros((side, side), float)
    for yy in range(side):
        for xx in range(side):
            sy, sx = top + yy, left + xx
            if 0 <= sy < alpha.shape[0] and 0 <= sx < alpha.shape[1]:
                sub[yy, xx] = alpha[sy, sx]
    canvas[..., 3] = np.round(sub * 255).astype(np.uint8)

    im = Image.fromarray(canvas, "RGBA")
    blob = os.path.join(OUT, "_tmp_%s.png" % name)
    im.save(blob)
    digest = hashlib.md5(open(blob, "rb").read()).hexdigest()[:8]
    final = "%s_v%d_%s.png" % (name, VERSION, digest)
    os.replace(blob, os.path.join(OUT, final))

    ring = side - 2 * DILATE              # the drawing's own width, before it was fattened
    ui = RING_LOCAL * side / ring * 100.0  # ...so the ORIGINAL stroke still lands on the frame
    print("%-14s %s -> %dx%d  (ring %d + %d dilate; dropped %d px of dust)"
          % (name, src_file, side, side, ring, DILATE, dropped))
    print("               %s" % (CDN % final))
    print("               UI_SIZE %.2f" % ui)
    return final, side


def main():
    if not os.path.isdir(OUT):
        os.makedirs(OUT)
    for name, src_file, ink in FACES:
        if not os.path.exists(os.path.join(SRC, src_file)):
            sys.exit("missing source art: assets/src_art/%s" % src_file)
        build(name, src_file, ink)
    print()
    print("UI_SIZE above is RING_LOCAL grown by the dilation margin, so the ring's own centreline")
    print("still lands on the printed frame while its strokes overhang it by DILATE.")


if __name__ == "__main__":
    main()
