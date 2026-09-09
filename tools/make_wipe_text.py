#!/usr/bin/env python3
"""Render a button's ARMED warning -- the red state's lettering -- to match the ones already shipped.

A destructive button on the setup board asks before it acts: the first click turns it red and swaps
its art for a line of text, and a second click within three seconds goes ahead. Those warnings are
pictures, not UI text (assets/buttons/wipe_confirm_*.png), and the script that made them is not in the
repo -- so a new button had no way to ask in the same voice.

    python3 tools/make_wipe_text.py

The recipe is read back off the shipped art rather than guessed: Luminari, white with a heavy black
stroke, on transparency, two lines centred in the button's own 272x136. Running this prints how
closely it reproduces `wipe_confirm_wide`, which is the check that the recipe is still right -- if
that drifts, the new warning has stopped matching the old ones and the numbers below are why.

Writes assets/buttons/<stem>_<md5>.png and prints the URL for the CustomUIAssets entry in
gen/src/save.json.
"""
import hashlib
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
OUT = os.path.join(REPO, "assets", "buttons")
CDN = "https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/assets/buttons/%s"

LUM = "/System/Library/Fonts/Supplemental/Luminari.ttf"
WIDE = (272, 136)                # the wide button's art, measured on wipe_confirm_wide
INK_W = 245                      # how much of that width the longest line fills, measured the same way
PITCH = 55                       # baseline-to-baseline, measured the same way
STROKE = 5                       # the black outline; the shipped art is 3x more outline than fill

# name, output stem, the two lines
JOBS = [
    # The new one. Maintainer, 2026-09-09, asking for a Clear All button: "add a warning This clears
    # everything."
    ("ClearAllConfirmArt", "wipe_confirm_clear", ["This clears", "everything."]),
]

# What the check renders: the wide warning exactly as it ships, so the recipe can be compared with it.
REFERENCE = ("wipe_confirm_wide_8020706a.png", ["This will reset", "all factions."])


def render(lines, size=WIDE, ink_w=INK_W, pitch=PITCH, stroke=STROKE):
    """The lines in Luminari, white on a black outline, centred on transparency."""
    im = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # SIZED ON THE LONGEST LINE, so a longer warning gets smaller rather than running off the button.
    pt = 8
    while pt < 200:
        f = ImageFont.truetype(LUM, pt + 1)
        w = max(d.textbbox((0, 0), t, font=f, stroke_width=stroke)[2]
                - d.textbbox((0, 0), t, font=f, stroke_width=stroke)[0] for t in lines)
        if w > ink_w:
            break
        pt += 1
    f = ImageFont.truetype(LUM, pt)
    for i, t in enumerate(lines):
        bb = d.textbbox((0, 0), t, font=f, stroke_width=stroke)
        d.text((size[0] / 2 - (bb[2] - bb[0]) / 2 - bb[0], i * pitch - bb[1] + stroke),
               t, font=f, fill=(255, 255, 255, 255), stroke_width=stroke, stroke_fill=(0, 0, 0, 255))
    # CENTRED ON THE INK ITSELF, not on a line box. The shipped warning's ink sits dead centre in the
    # button (x 13..257 and y 21..115 of 272x136, both centres within a pixel of the middle), which a
    # font's own metrics do not give you: ascent, descent and the stroke all pad the box differently
    # for each pair of lines. Drawing first and moving what actually landed hits it every time.
    a = np.asarray(im)
    ys, xs = np.where(a[..., 3] > 40)
    im = im.transform(size, Image.AFFINE,
                      (1, 0, (xs.min() + xs.max() + 1) / 2 - size[0] / 2,
                       0, 1, (ys.min() + ys.max() + 1) / 2 - size[1] / 2),
                      resample=Image.NEAREST)
    return im, pt


def shape(im):
    """Where the ink is, and how much of it is outline -- the numbers the check compares."""
    a = np.asarray(im.convert("RGBA"))
    al = a[..., 3] > 40
    if not al.any():
        return None
    ys, xs = np.where(al)
    white = ((a[..., :3] > 200).all(2) & al).sum()
    black = ((a[..., :3] < 60).all(2) & al).sum()
    return (xs.min(), xs.max(), ys.min(), ys.max(), int(white), int(black))


def check():
    """Render the shipped warning's own text and report how close the recipe lands to it."""
    path = os.path.join(OUT, REFERENCE[0])
    if not os.path.exists(path):
        print("  (no reference art on disk; recipe unchecked)")
        return
    theirs = shape(Image.open(path))
    mine = shape(render(REFERENCE[1])[0])
    print("  recipe check against %s" % REFERENCE[0])
    for label, i in (("ink left", 0), ("ink right", 1), ("ink top", 2), ("ink bottom", 3)):
        print("     %-10s shipped %4d   this recipe %4d   (%+d)" % (label, theirs[i], mine[i],
                                                                    mine[i] - theirs[i]))
    print("     %-10s shipped %4d/%4d  this recipe %4d/%4d  (white/black px)"
          % ("weight", theirs[4], theirs[5], mine[4], mine[5]))


def main():
    if not os.path.exists(LUM):
        sys.exit("missing %s" % LUM)
    check()
    print()
    for name, stem, lines in JOBS:
        im, pt = render(lines)
        tmp = os.path.join(OUT, "_tmp_%s.png" % stem)
        im.save(tmp)
        digest = hashlib.md5(open(tmp, "rb").read()).hexdigest()[:8]
        final = "%s_%s.png" % (stem, digest)
        os.replace(tmp, os.path.join(OUT, final))
        print("  %-22s %s at %dpt -> %s" % (name, "/".join(lines), pt, final))
        print("     %s" % (CDN % final))


if __name__ == "__main__":
    main()
