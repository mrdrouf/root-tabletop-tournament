#!/usr/bin/env python3
"""Reset the Knaves' Captains board title into the mod's own font.

Maintainer, 2026-09-09: "not all fonts are the same for example Captains on the captain board of
the knaves."

The board is the real Crafted Improvements art cropped to its top three card slots, with its printed
title painted over and "Captains" written in its place. That lettering was set apart from every other
label in the mod: tools/make_labels.py renders all of them in LUMINARI, and this one was mixed caps
at a heavier weight -- close enough to look deliberate and wrong enough to notice next to the rest.

    python3 tools/make_captains.py

Reads assets/src_art/knaves_captains_src.png, lifts the old title off under parchment taken from the
board's own empty rows, sets the word again in Luminari, and writes the next version. Prints the URL
for RTT_CAPTAIN_BOARD_JSON in gen/src/logic.lua.
"""
import hashlib
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
OUT = os.path.join(REPO, "assets", "labels")
SRC_DIR = os.path.join(REPO, "assets", "src_art")
CDN = "https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/assets/labels/%s"

LUM = "/System/Library/Fonts/Supplemental/Luminari.ttf"
SRC = "knaves_captains_src.png"   # v8 as it shipped, kept as source: the title is lifted off it
VERSION = 10
WORD = "Captains"

# The title sits inside the board's inked border, above the first card slot. Measured on v8: its ink
# runs x 86..653, y 103..190, on parchment that is bare from y 45 to 95 and again from 215 to 260.
BAND = (55, 95, 685, 215)       # what gets lifted off: left, top, right, bottom
PARCH_ROWS = (218, 258)         # bare parchment to lift it off with
INK = (38, 30, 22)              # the title's own colour, unchanged
CAP_HEIGHT = 87                 # what the old lettering measured, so the board's balance is kept

# THE CARD BACK, GHOSTED INTO THE EMPTY SLOTS. Maintainer, 2026-09-09: "The card improvement board
# has, inside of the card snap slots, the art of the back of the card in a slightly transparent
# setting, lightly inside the board. It looks quite nice. I want you to study this and try to do the
# same for the captain's board ... you need to extract the art from the background of the card
# though."
#
# So it is the DRAWING that goes in -- the cloak, the acorn shield and the flute -- not the card,
# whose own background is a wall of orange wood planks that would fill the slot and read as a card
# left face down rather than as a mark on the board.
BACK = "knaves_captain_back.png"
SLOTS = ((103, 276, 637, 1033), (103, 1067, 637, 1824), (103, 1858, 637, 2615))
GHOST = 0.13                    # how strongly it shows: a mark on the board, not a card in the slot
WOOD_WARMTH = 28                # red-over-blue that tells the plank background from the drawing
SEAL = 3                        # closes the gaps in the drawn outlines before the background is
                                # flooded; without it the flood leaks through a break in the flute's
                                # own line and eats its body, leaving the keys floating
STRAY_ROWS = 47                 # grain above the cloak that survives the seal, and is not the art


def card_art(path):
    """The drawing off the captain card, with its plank background taken away.

    The background is what makes this possible: it is warm all over, it touches every edge, and the
    drawing does not. So the wood is FLOODED FROM THE BORDER and whatever the flood cannot reach is
    the art -- which needs no colour test on the drawing itself, and so keeps the parts of it that
    are the same colour as the wood. The flute is exactly that: its body is as warm as a plank, and
    only its own outline separates them.
    """
    a = np.asarray(Image.open(path).convert("RGB")).astype(int)
    H, W = a.shape[:2]
    wood = (a[..., 0] - a[..., 2] > WOOD_WARMTH) & (a[..., 0] > 45)

    def m2i(m):
        return Image.fromarray((m * 255).astype(np.uint8))

    def dilate(m, k):
        return np.asarray(m2i(m).filter(ImageFilter.MaxFilter(2 * k + 1))) > 127

    def erode(m, k):
        return np.asarray(m2i(m).filter(ImageFilter.MinFilter(2 * k + 1))) > 127

    ink = erode(dilate(~wood, SEAL), SEAL)
    im = m2i(~ink).convert("L")
    for seed in ((0, 0), (W - 1, 0), (0, H - 1), (W - 1, H - 1), (W // 2, 0), (W // 2, H - 1)):
        if im.getpixel(seed) == 255:
            ImageDraw.floodfill(im, seed, 128)
    art = ~(np.asarray(im) == 128)
    art[:STRAY_ROWS] = False

    lab = np.zeros((H, W), np.int32)
    cur, sizes = 0, {}
    for sy in range(H):
        for sx in np.where(art[sy] & (lab[sy] == 0))[0]:
            if lab[sy, sx]:
                continue
            cur += 1
            stack, n = [(sy, sx)], 0
            lab[sy, sx] = cur
            while stack:
                y, x = stack.pop()
                n += 1
                for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                    if 0 <= ny < H and 0 <= nx < W and art[ny, nx] and not lab[ny, nx]:
                        lab[ny, nx] = cur
                        stack.append((ny, nx))
            sizes[cur] = n
    big = [c for c, _ in sorted(sizes.items(), key=lambda kv: -kv[1])[:2]]   # the cloak and the flute
    keep = np.isin(lab, big)
    # OPENED, to shed the grain that is FUSED to the drawing. A few plank lines run down into the top
    # of the cloak, so keeping the largest islands keeps them too -- they came through as hairline
    # ticks standing above it in the slot. Both real shapes are solid masses, so taking two pixels off
    # and putting them back loses nothing of them and everything of a two-pixel line.
    keep = dilate(erode(keep, 2), 2)
    return np.dstack([a.astype(np.uint8), (keep * 255).astype(np.uint8)])


def ghost_slots(im, rgba):
    """Lay the drawing faintly into each empty card slot."""
    for (x0, y0, x1, y1) in SLOTS:
        w, h = x1 - x0, y1 - y0
        card = Image.fromarray(rgba, "RGBA").resize((w, h), Image.LANCZOS)
        c = np.asarray(card).astype(np.float32)
        al = (c[..., 3] / 255.0 * GHOST)[..., None]
        reg = np.asarray(im.crop((x0, y0, x1, y1))).astype(np.float32)
        im.paste(Image.fromarray((reg * (1 - al) + c[..., :3] * al).astype(np.uint8)), (x0, y0))
    return im


def main():
    src = os.path.join(SRC_DIR, SRC)
    if not os.path.exists(src):
        sys.exit("missing %s" % src)
    im = Image.open(src).convert("RGB")
    a = np.asarray(im).copy()

    x0, y0, x1, y1 = BAND
    rows = np.arange(*PARCH_ROWS)
    rng = np.random.default_rng(3)
    for y in range(y0, y1):
        a[y, x0:x1] = a[rows[rng.integers(len(rows))], x0:x1]

    im = Image.fromarray(a)
    d = ImageDraw.Draw(im)
    # MEASURED ON THE CAP, not on the word. The old title had no descender -- it was set in caps --
    # so its 87px is cap height, while Luminari's "Captains" carries a p below the line. Sizing by
    # the word's own box made the letters visibly smaller than the board was drawn for.
    size = 10
    while size < 400:
        f = ImageFont.truetype(LUM, size + 1)
        cb = d.textbbox((0, 0), "C", font=f)
        if cb[3] - cb[1] > CAP_HEIGHT:
            break
        size += 1
    f = ImageFont.truetype(LUM, size)
    cb = d.textbbox((0, 0), "C", font=f)
    bb = d.textbbox((0, 0), WORD, font=f)
    d.text(((x0 + x1) / 2 - (bb[2] - bb[0]) / 2 - bb[0], 103 - cb[1]), WORD, font=f, fill=INK)

    im = ghost_slots(im, card_art(os.path.join(SRC_DIR, BACK)))

    tmp = os.path.join(OUT, "_tmp_captains.png")
    im.save(tmp)
    digest = hashlib.md5(open(tmp, "rb").read()).hexdigest()[:8]
    final = "knaves_captains_v%d_%s.png" % (VERSION, digest)
    os.replace(tmp, os.path.join(OUT, final))
    print("   set in Luminari at %dpt (cap height %dpx)" % (size, cb[3] - cb[1]))
    print(CDN % final)


if __name__ == "__main__":
    main()
