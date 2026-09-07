#!/usr/bin/env python3
"""Render the plain white disc that numpad 2 draws under a laid-down warrior.

White and untextured on purpose: the tile is tinted to the player's own colour at spawn, so one image
serves every colour. Soft edge because a hard one aliases badly at the size it is drawn.

    python3 tools/make_disc.py        # -> assets/labels/disc_<hash>.png, prints the jsDelivr URL
"""
import hashlib
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "labels")
SIZE = 512
PAD = 16                      # room for the blur, so the edge is not clipped


def main():
    im = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([PAD, PAD, SIZE - PAD, SIZE - PAD], fill=(255, 255, 255, 255))
    im = im.filter(ImageFilter.GaussianBlur(3))
    tmp = os.path.join(OUT, "disc.png")
    im.save(tmp)
    h = hashlib.md5(open(tmp, "rb").read()).hexdigest()[:8]
    final = os.path.join(OUT, "disc_%s.png" % h)
    if not os.path.exists(final):
        os.rename(tmp, final)
    elif os.path.exists(tmp):
        os.remove(tmp)
    print(os.path.relpath(final, ROOT))
    print("https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/assets/labels/disc_%s.png" % h)
    return 0


if __name__ == "__main__":
    sys.exit(main())
