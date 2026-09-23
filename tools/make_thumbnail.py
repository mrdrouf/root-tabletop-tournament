#!/usr/bin/env python3
"""The save-list thumbnail: the mod's name plaque alone, on black.

Maintainer, 2026-09-23: "replace the birds in the thumbnail. just black. no AI art just the name."
The plaque is the one tools/make_logo.py lays under its picture, cut straight out of
assets/icon/logo_1024.png rather than rebuilt -- build_plaque needs Luminari, which is not on every
machine, and the rendered plaque already exists. So this cannot drift from the logo's lettering, and
it needs no font.

Writes dist/Root_Tournament_Edition.png (what Tabletop Simulator shows in the save list) and, when
the Windows Saves folder is there, the same file beside the base save.

    python tools/make_thumbnail.py
"""
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
LOGO = os.path.join(ROOT, "assets", "icon", "logo_1024.png")
THUMB = os.path.join(ROOT, "dist", "Root_Tournament_Edition.png")
SAVES = os.path.join(os.path.expanduser("~"), "Documents", "My Games", "Tabletop Simulator", "Saves")
SIZE = 1024
BLACK = (0, 0, 0)


def plaque_box(img):
    """Where the plaque is in the logo: the parchment rows, grown by the frame around them."""
    a = np.asarray(img.convert("RGB")).astype(int)
    parchment = (a[..., 0] > 200) & (a[..., 1] > 180) & (a[..., 2] > 140)
    rows = np.where(parchment.sum(1) > 200)[0]
    top, bottom = int(rows.min()), int(rows.max())
    # the frame: a band of near-black directly above and below the parchment, a dozen pixels
    frame = 12
    return (0, max(0, top - frame), img.width, min(img.height, bottom + frame + 1))


def main():
    if not os.path.exists(LOGO):
        sys.exit("missing %s (run tools/make_logo.py first)" % LOGO)
    logo = Image.open(LOGO).convert("RGB")
    box = plaque_box(logo)
    plaque = logo.crop(box)
    canvas = Image.new("RGB", (SIZE, SIZE), BLACK)
    canvas.paste(plaque, (0, (SIZE - plaque.height) // 2))
    at256 = canvas.resize((256, 256), Image.LANCZOS)
    at256.save(THUMB)
    written = [os.path.relpath(THUMB, ROOT)]
    beside = os.path.join(SAVES, "Root_Tournament_Edition.png")
    if os.path.isdir(SAVES):
        at256.save(beside)
        written.append(beside)
    print("plaque rows %d..%d of the logo; wrote %s" % (box[1], box[3], ", ".join(written)))


if __name__ == "__main__":
    main()
