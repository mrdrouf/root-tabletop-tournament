#!/usr/bin/env python3
"""Render the lockup: the four birds hunched over the mod's ROOT sign like a bar.

The maintainer, 2026-09-09: "could you make the logo basically on top of the ROOT big logo that is on
the setup board. don t put it on the setup board yet. but have the birds being just on top of the
logo." So this builds the asset and NOTHING ELSE -- it does not touch the setup board, the mod icon,
the save, or anything tools/make_logo.py owns.

The birds are generated (see tools/make_logo.py for the how) as a wide row of four leaning figures in
the flat style of tools/make_mark.py, and the sign is the re-lettered ROOT plaque that
tools/make_icon.py builds -- imported, not rebuilt, so all three assets carry the same sign.

TWO THINGS THE MODEL DOES THAT HAVE TO BE UNDONE HERE:

  * asked for a transparent background it PAINTED A CHECKERBOARD -- the grey squares an editor shows
    behind transparency, drawn as if they were the picture. So the background is cut away here, by
    flooding in from the border through grey rather than by deleting grey wherever it appears: see
    dekey, which explains what the simpler version broke;
  * it will not hold a flat colour, so the palette is imposed afterwards, as in make_mark.py -- with
    a gold and a highlight added for the coin, and a slate for the bills.

Run from the repo root:  python3 tools/make_lockup.py
"""
import os
import re
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_icon import build_plaque                            # noqa: E402
from make_mark import CREAM, INK, ORANGE, TEAL, flatten       # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# HUNCHED, NOT PERCHED. The first row stood upright on the sign like birds on a wire; the
# maintainer, 2026-09-09: "could you make them hunched over the sign like it s a bar table or
# something." They now lean on it -- shoulders up, heads forward and down, wings folded along
# the top edge -- which is why the row overlaps the sign rather than standing clear of it.
# birds_perched.png is the upright version, still here and one line away.
BIRDS = os.path.join(ROOT, "assets", "src_art", "birds_leaning.png")
OUTDIR = os.path.join(ROOT, "assets", "mark")

PLAQUE_WIDTH = 1600
BIRDS_WIDTH = 0.86        # of the plaque, so the row sits inside the sign's width
PERCH = 8                 # px of the folded wings tucked behind the sign's top edge
SIZES = (1600, 1024, 512, 256)

# THE SETUP BOARD'S EXISTING ROOT SIGN -- what --install replaces, asserted before it writes.
SAVE = os.path.join(ROOT, "gen", "src", "save.json")
# The ORIGINAL geometry, kept as the baseline that "5% smaller" and "a bit lower" are measured from.
# The tag in save.json no longer reads these values -- install() has already rewritten it -- so it is
# matched by pattern instead. See install().
OLD_X, OLD_Y, OLD_W, OLD_H = -87.5, 80, 75, 25

# THE COIN NEEDS METAL IN THE PALETTE. make_mark's four colours have no yellow in them, so snapping
# the woodpecker's polished gold coin to the nearest of them turned it into a flat orange disc --
# indistinguishable from his crest. Gold and a pale highlight are added here, and only here; the
# badge in make_mark.py still uses its own four.
GOLD = (226, 172, 58)
GLINT = (250, 232, 168)
SLATE = (112, 116, 122)                 # the woodpecker's bill, which is grey and not teal
PALETTE = (INK, CREAM, ORANGE, TEAL, GOLD, GLINT, SLATE)

# The checkerboard the model painted instead of leaving the background empty.
KEY_SAT = 26              # at or below this spread between R,G,B a pixel counts as neutral


def dekey(img):
    """Cut the painted checkerboard away and return the birds on real transparency.

    THE KEY FLOODS IN FROM THE BORDER; it does not simply delete every grey pixel. Deleting grey
    globally is what a colour key does and it was wrong twice over: the birds' contours are very dark
    and nearly neutral, so a plain grey key dissolved their outlines, and once that was guarded
    against with a brightness floor the greys that DID survive -- the woodpecker's slate bill, the
    eagle's -- got snapped to the only cool colour in the palette and came out teal. The checkerboard
    is a single region touching the border and the birds' own greys are enclosed inside them, so
    connectivity separates the two cleanly and neither problem arises.
    """
    a = np.asarray(img.convert("RGB")).astype(np.int32)
    grey = (a.max(axis=2) - a.min(axis=2)) <= KEY_SAT

    h, w = grey.shape
    bg = np.zeros((h, w), bool)
    bg[0, :] = grey[0, :]
    bg[-1, :] = grey[-1, :]
    bg[:, 0] = grey[:, 0]
    bg[:, -1] = grey[:, -1]
    while True:                                   # grow the border region through grey only
        prev = bg.sum()
        g = bg.copy()
        g[1:, :] |= bg[:-1, :]
        g[:-1, :] |= bg[1:, :]
        g[:, 1:] |= bg[:, :-1]
        g[:, :-1] |= bg[:, 1:]
        bg = g & grey
        if bg.sum() == prev:
            break

    out = img.convert("RGBA")
    alpha = Image.fromarray(np.where(bg, 0, 255).astype(np.uint8))
    # pull in a pixel so no grey rim survives, then soften what is left of the edge
    alpha = alpha.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.6))
    out.putalpha(alpha)
    return out.crop(out.getbbox())


def install(local):
    """Publish the lockup and put it on the setup board in place of the old ROOT sign.

    The maintainer, 2026-09-09: "replace the root log on the setup board with that logo. make it
    similar size but 5% smaller and a bit lower on the board to fit the new designs."

    WHAT WAS THERE: <Image id="rootLogo"> at (-87.5, 80), 75 x 25, pointing at a Steam-hosted copy of
    the ORIGINAL Root sign -- the one that still reads "A Game of Woodland Might and Right". It is
    replaced by this lockup, which carries the mod's own re-lettered sign with the birds over it.

    THE GEOMETRY. 5% smaller means the width: 75 -> 71.25. The height is NOT 5% of 25, because the
    lockup is a different shape -- the birds make it about 1.83:1 where the bare sign was 3:1 -- so
    the height follows from the picture's own aspect, and it comes out taller. That is what "a bit
    lower ... to fit the new designs" is for: there is no room to grow upwards (the version panel sits
    at y=87 and the board ends around 92), so the top edge is pinned roughly where the old sign's top
    was and the whole thing extends downward instead.

    The file is written by SURGICAL SUBSTITUTION on the raw bytes, never by re-dumping the JSON:
    gen/src/save.json is CRLF and reflowing it would rewrite the entire file. tools/relabel.py does
    the same thing for the same reason.
    """
    import hashlib
    import shutil

    art = Image.open(local)
    scale = 0.95
    w = OLD_W * scale
    h = w * art.height / art.width
    top = OLD_Y + OLD_H / 2                       # where the old sign's top edge sat
    y = top - h / 2

    # content-hashed, because jsDelivr caches by URL (the convention in tools/relabel.py)
    digest = hashlib.md5(open(local, "rb").read()).hexdigest()[:8]
    published = os.path.join(ROOT, "assets", "labels", "root_logo_birds_%s.png" % digest)
    shutil.copy2(local, published)
    url = ("https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/assets/labels/"
           "root_logo_birds_%s.png" % digest)

    # MATCHED BY PATTERN, NOT BY ITS CURRENT VALUES, so this can be run again. The first version
    # asserted the tag still read 75 x 25 at (-87.5, 80) -- true exactly once, and false immediately
    # afterwards, so re-installing a corrected picture refused to run. The geometry above is still
    # derived from those originals, which are the baseline "5% smaller" is measured against; only the
    # matching is loose.
    raw = open(SAVE, "rb").read().decode("utf-8")
    tag_re = re.compile(r'<Image id=\\"rootLogo\\"[^>]*?/>')
    tags = tag_re.findall(raw)
    if len(tags) != 1:
        sys.exit("expected exactly one rootLogo Image tag in save.json, found %d" % len(tags))
    new_tag = ('<Image id=\\"rootLogo\\" position=\\"%s %s -20\\" width=\\"%s\\" height=\\"%s\\" '
               'image=\\"Root Logo\\"/>' % (OLD_X, round(y, 2), round(w, 2), round(h, 2)))

    url_re = re.compile(r'("Name":\s*"Root Logo",\s*\n\s*"URL":\s*")([^"]*)(")')
    m = url_re.search(raw)
    if not m:
        sys.exit("could not find the Root Logo asset URL in save.json")

    raw = raw.replace(tags[0], new_tag)
    raw = url_re.sub(lambda mm: mm.group(1) + url + mm.group(3), raw, count=1)
    open(SAVE, "wb").write(raw.encode("utf-8"))
    print("published %s" % os.path.relpath(published, ROOT))
    print("board:   %s x %s at (%s, %s)  [was %s x %s at (%s, %s)]"
          % (round(w, 2), round(h, 2), OLD_X, round(y, 2), OLD_W, OLD_H, OLD_X, OLD_Y))
    print("save.json rewritten -- now rebuild dist:  python3 gen/assemble.py")
    print("NOTE: the URL only resolves once assets/labels/ is pushed to main; jsDelivr reads @main.")


def main():
    for p in (BIRDS,):
        if not os.path.exists(p):
            sys.exit("missing source: %s" % p)
    os.makedirs(OUTDIR, exist_ok=True)

    birds = flatten(dekey(Image.open(BIRDS)), PALETTE)
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
    if "--install" in sys.argv:
        install(os.path.join(OUTDIR, "lockup_1024.png"))


if __name__ == "__main__":
    main()
