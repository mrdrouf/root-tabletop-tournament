#!/usr/bin/env python3
"""Render the lockup: the four birds perched on top of the mod's ROOT sign.

The maintainer, 2026-09-09: "could you make the logo basically on top of the ROOT big logo that is on
the setup board. don t put it on the setup board yet. but have the birds being just on top of the
logo." So this builds the asset and NOTHING ELSE -- it does not touch the setup board, the mod icon,
the save, or anything tools/make_logo.py owns.

The birds are generated (see tools/make_logo.py for the how) as a wide row of four standing figures in
the flat style of tools/make_mark.py, and the sign is the re-lettered ROOT plaque that
tools/make_icon.py builds -- imported, not rebuilt, so all three assets carry the same sign.

TWO THINGS THE MODEL DOES THAT HAVE TO BE UNDONE HERE:

  * asked for a transparent background it PAINTED A CHECKERBOARD -- the grey squares an editor shows
    behind transparency, drawn as if they were the picture. So the background is keyed out by hand.
    The key is on low saturation AND mid-to-high luminance, not on grey alone: the birds' contour is
    very dark and nearly neutral, and keying every neutral pixel dissolved the outlines with the
    background;
  * it will not hold a flat colour, so the palette is imposed afterwards, as in make_mark.py.

Run from the repo root:  python3 tools/make_lockup.py
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_icon import build_plaque                            # noqa: E402
from make_mark import CREAM, INK, ORANGE, TEAL, flatten       # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BIRDS = os.path.join(ROOT, "assets", "src_art", "birds_perched.png")
OUTDIR = os.path.join(ROOT, "assets", "mark")

PLAQUE_WIDTH = 1600
BIRDS_WIDTH = 0.86        # of the plaque, so the row sits inside the sign's width
PERCH = 10                # px of the birds tucked behind the sign's top edge, so the toes grip it
SIZES = (1600, 1024, 512, 256)

# The checkerboard the model painted instead of leaving the background empty.
KEY_SAT = 26              # at or below this spread between R,G,B a pixel is neutral
KEY_LUM = 105             # ... and only neutral pixels THIS bright are background


def dekey(img):
    """Cut the painted checkerboard away and return the birds on real transparency."""
    a = np.asarray(img.convert("RGB")).astype(np.int32)
    sat = a.max(axis=2) - a.min(axis=2)
    lum = 0.299 * a[:, :, 0] + 0.587 * a[:, :, 1] + 0.114 * a[:, :, 2]
    bg = (sat <= KEY_SAT) & (lum >= KEY_LUM)

    out = img.convert("RGBA")
    alpha = Image.fromarray(np.where(bg, 0, 255).astype(np.uint8))
    # pull in a pixel so no grey rim survives, then soften what is left of the edge
    alpha = alpha.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.6))
    out.putalpha(alpha)
    return out.crop(out.getbbox())


def main():
    for p in (BIRDS,):
        if not os.path.exists(p):
            sys.exit("missing source: %s" % p)
    os.makedirs(OUTDIR, exist_ok=True)

    birds = flatten(dekey(Image.open(BIRDS)))
    plaque = build_plaque(PLAQUE_WIDTH).convert("RGBA")

    bw = round(PLAQUE_WIDTH * BIRDS_WIDTH)
    birds = birds.resize((bw, round(birds.height * bw / birds.width)), Image.LANCZOS)

    canvas = Image.new("RGBA", (PLAQUE_WIDTH, birds.height - PERCH + plaque.height), (0, 0, 0, 0))
    canvas.alpha_composite(birds, ((PLAQUE_WIDTH - bw) // 2, 0))
    canvas.alpha_composite(plaque, (0, birds.height - PERCH))

    written = []
    for s in SIZES:
        r = canvas.resize((s, round(canvas.height * s / canvas.width)), Image.LANCZOS)
        p = os.path.join(OUTDIR, "lockup_%d.png" % s)
        r.save(p)
        written.append(os.path.relpath(p, ROOT))
    bg = Image.new("RGBA", canvas.size, CREAM + (255,))
    bg.alpha_composite(canvas)
    p = os.path.join(OUTDIR, "lockup_cream.png")
    bg.convert("RGB").save(p)
    written.append(os.path.relpath(p, ROOT))
    dark = Image.new("RGBA", canvas.size, (18, 13, 10, 255))
    dark.alpha_composite(canvas)
    p = os.path.join(OUTDIR, "lockup_dark.png")
    dark.convert("RGB").save(p)
    written.append(os.path.relpath(p, ROOT))

    print("lockup %dx%d" % canvas.size)
    print("wrote " + ", ".join(written))


if __name__ == "__main__":
    main()
