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
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
OUT = os.path.join(REPO, "assets", "labels")
SRC_DIR = os.path.join(REPO, "assets", "src_art")
CDN = "https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/assets/labels/%s"

LUM = "/System/Library/Fonts/Supplemental/Luminari.ttf"
SRC = "knaves_captains_src.png"   # v8 as it shipped, kept as source: the title is lifted off it
VERSION = 9
WORD = "Captains"

# The title sits inside the board's inked border, above the first card slot. Measured on v8: its ink
# runs x 86..653, y 103..190, on parchment that is bare from y 45 to 95 and again from 215 to 260.
BAND = (55, 95, 685, 215)       # what gets lifted off: left, top, right, bottom
PARCH_ROWS = (218, 258)         # bare parchment to lift it off with
INK = (38, 30, 22)              # the title's own colour, unchanged
CAP_HEIGHT = 87                 # what the old lettering measured, so the board's balance is kept


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

    tmp = os.path.join(OUT, "_tmp_captains.png")
    im.save(tmp)
    digest = hashlib.md5(open(tmp, "rb").read()).hexdigest()[:8]
    final = "knaves_captains_v%d_%s.png" % (VERSION, digest)
    os.replace(tmp, os.path.join(OUT, final))
    print("   set in Luminari at %dpt (cap height %dpx)" % (size, cb[3] - cb[1]))
    print(CDN % final)


if __name__ == "__main__":
    main()
