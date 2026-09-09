#!/usr/bin/env python3
"""Render the schematic mark: the four birds at their table, reduced to a flat emblem.

The maintainer, 2026-09-09: "can you now make a schematic version of it like low details as a logo
for example nice design" -- and, immediately after, "its for something else another place." So this
is NOT the mod's art. It writes nothing that tools/make_logo.py owns and nothing that ships inside
the save; it is a standalone badge for use elsewhere, and the mod icon is left alone.

The picture comes from the image model like the rest (see tools/make_logo.py for the how and the
why). What it will NOT do reliably is hold a flat colour: asked for three flat colours it returned
twenty-four thousand, because an image model paints an edge rather than filling a region, and a
schematic emblem lives or dies on exactly that. So the generated mark is only the DRAWING here.
Flatness is imposed afterwards, and imposed absolutely:

  * every opaque pixel is snapped to the nearest of the palette colours;
  * the alpha is thresholded to a hard in-or-out, killing the speckled halo the model leaves round
    every silhouette. A soft edge is what made the first attempt look grubby -- a logo wants a crisp
    boundary, and at small sizes a fringe is a smudge.

That flattening applies to the MASTER, at the size the model drew it, and mark_master.png is exactly
flat, with a hard edge. The size ladder below it is then resampled from that master and IS
antialiased, deliberately: a downscale of flat art wants smooth edges, exactly as rasterising a vector
logo at 64px does. Type is antialiased for the same reason. An earlier version of this script
flattened first and resized afterwards and then claimed the outputs were three colours; they were two
thousand, because the resize put every intermediate tone back. Flatten last, or not at all.

Run from the repo root:  python3 tools/make_mark.py
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_icon import FONT, draw_tracked                       # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "src_art", "logo_mark.png")
OUTDIR = os.path.join(ROOT, "assets", "mark")

# THE SCENE HAS TO SURVIVE THE SIMPLIFICATION. A first attempt cut the birds down to four heraldic
# heads floating over a bar -- clean, and useless: "too design, we need to still see the birds playing
# root" (2026-09-09). The emblem now holds the whole scene, four birds seated round the table with the
# board between them, drawn flat rather than drawn simple. Four colours carry it: ink, cream, the
# orange of the table, and a teal for the board's forest.
INK = (38, 26, 18)
ORANGE = (222, 105, 32)
CREAM = (245, 224, 196)
TEAL = (20, 66, 52)                     # the board's forest
PALETTE = (INK, CREAM, ORANGE, TEAL)

ALPHA_CUT = 128          # in or out, no fringe
INNER = 0.86             # of the outer radius: inside the double ring, where type may go
SIZES = (1024, 512, 256, 128, 64)


def flatten(img, palette=PALETTE):
    """Snap to `palette` and harden the edge, so the art is genuinely flat rather than nearly.

    The palette is an argument because callers do not all want the same one: tools/make_lockup.py adds
    a gold and a highlight for the coin, and snapping those to the nearest of THIS palette turned a
    polished coin back into a flat orange disc.
    """
    # int32, NOT int16: a squared RGB distance reaches 3 * 255**2 = 195075 and int16 stops at 32767,
    # so the sum wrapped negative and argmin below returned the FARTHEST colour instead of the
    # nearest. It inverted the whole emblem -- cream became ink and ink became cream -- and it did it
    # silently, because a consistently wrong answer still looks like a palette.
    a = np.asarray(img.convert("RGBA")).astype(np.int32)
    rgb, alpha = a[:, :, :3], a[:, :, 3]

    solid = alpha >= ALPHA_CUT
    pal = np.array(palette, np.int32)
    # nearest palette entry per pixel, by squared distance
    d = ((rgb[:, :, None, :] - pal[None, None, :, :]) ** 2).sum(axis=3)
    idx = d.argmin(axis=2)

    out = np.zeros_like(a, dtype=np.uint8)
    out[:, :, :3] = pal[idx]
    out[:, :, 3] = np.where(solid, 255, 0)
    # a transparent pixel keeps a colour underneath it; make it the ink so any stray resampling
    # later bleeds towards the mark's own colour instead of towards white
    out[~solid, :3] = INK
    return Image.fromarray(out)


def ring(mark):
    """Find the badge's centre and radius from its ALPHA, not from its colours.

    The type has to sit inside a circle, and the circle is drawn rather than specified -- the model's
    rings come back slightly elliptical and never quite where they were asked for. An earlier version
    hunted for orange pixels to locate the ring, which worked only while the ring happened to BE
    orange; the moment the emblem came back with a dark ring over an orange table it found the table
    instead. The opaque region IS the disc, whatever it is painted, so the alpha is the honest source.
    """
    a = np.asarray(mark.convert("RGBA"))
    ys, xs = np.nonzero(a[:, :, 3] > 128)
    cx, cy = (xs.min() + xs.max()) / 2, (ys.min() + ys.max()) / 2
    r = min(xs.max() - xs.min(), ys.max() - ys.min()) / 2
    return cx, cy, r


def fit(draw, text, room, cap):
    """Largest size of FONT whose ink fits `room` wide and `cap` tall."""
    size = int(cap * 2)
    while size > 8:
        f = ImageFont.truetype(FONT, size)
        b = draw.textbbox((0, 0), text, font=f, anchor="lt")
        if (b[2] - b[0]) <= room and (b[3] - b[1]) <= cap:
            return f
        size -= 1
    return ImageFont.truetype(FONT, 8)


def table_floor(mark, cx, cy, r_in):
    """The y below which the badge is empty: the lowest row the picture reaches.

    Placing the type at a fraction of the radius put ROOT straight through the table -- a ratio cannot
    know where the drawing stopped. Nor can walking DOWN from the middle and taking the first clear
    row: the table's near edge is a curve, so there are clear rows above its lowest point and the
    scan stopped in one of them, leaving ROOT sitting on the rim. Scanning UP from just inside the
    ring finds the last row that still has anything in it, which is the real floor.

    Everything OUTSIDE the inner circle is excluded first, by radius. A rectangular centre band could
    not do it: the ring's own lower arc cuts through any band wide enough to be useful, so the scan
    found the ring on its very first row and reported the floor as the bottom of the badge.
    """
    a = np.asarray(mark.convert("RGBA")).astype(np.int32)
    h, w = a.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    inside = ((xx - cx) ** 2 + (yy - cy) ** 2) <= (r_in * 0.95) ** 2

    content = np.abs(a[:, :, :3] - np.array(CREAM, np.int32)).max(axis=2) >= 40
    content &= a[:, :, 3] >= ALPHA_CUT
    content &= inside

    rows = np.nonzero(content.sum(axis=1) > w * 0.01)[0]
    rows = rows[rows > cy]
    return float(rows.max()) if len(rows) else cy + r_in * 0.35


def letter(mark, title="ROOT", sub=None):
    """Set the wordmark into the empty band the emblem leaves below the table.

    The band runs from where the picture stops to the inside of the ring, both MEASURED off the
    drawing rather than assumed, and each line is sized to the CHORD of the ring at its own height, so
    neither can poke through the ring however the drawing shifts.
    """
    out = mark.copy()
    d = ImageDraw.Draw(out)
    cx, cy, r = ring(out)
    # ring() measures the OUTER edge of the badge. Type has to clear the double ring itself, so every
    # width below is taken against this smaller circle -- without it the subtitle ran straight out
    # through the rings on both sides, because a chord of the outer circle is wider than the room
    # actually available inside the inner one.
    r_in = r * INNER
    top = table_floor(out, cx, cy, r_in) + r * 0.035     # clear of the table's near edge
    bottom = cy + r_in * 0.97
    room = max(bottom - top, r * 0.3)

    def chord(y, keep=0.90):
        dy = y - cy
        return 2.0 * (max(r_in * r_in - dy * dy, 1.0) ** 0.5) * keep

    # ONE LINE BY DEFAULT. The picture fills so much of the circle that the band under it is only
    # about a tenth of the badge, and two lines in there left "TABLETOP TOURNAMENT" at twenty pixels
    # -- unreadable at full size, gone entirely by 256. A badge carries the name, not the whole
    # lockup; the subtitle lives on the plaque in tools/make_logo.py, where there is room for it.
    if sub:
        y1 = top + room * 0.30
        y2 = top + room * 0.84
        f1 = fit(d, title, chord(y1), room * 0.42)
        f2 = fit(d, sub, chord(y2), room * 0.22)
    else:
        y1 = top + room * 0.52
        f1 = fit(d, title, chord(y1), room * 0.70)

    b = d.textbbox((0, 0), title, font=f1, anchor="ls")
    d.text((cx, y1 - (b[1] + b[3]) / 2), title, font=f1, fill=INK + (255,), anchor="ms")
    if sub:
        target = min(chord(y2), d.textlength(title, font=f1) * 1.45)
        b = d.textbbox((0, 0), sub, font=f2, anchor="ls")
        draw_tracked(d, cx, y2 - (b[1] + b[3]) / 2, sub, f2, INK + (255,), target)
    return out


def on_cream(mark):
    bg = Image.new("RGBA", mark.size, CREAM + (255,))
    bg.alpha_composite(mark)
    return bg.convert("RGB")


def ladder(mark, path):
    """One strip showing the mark at every size it will be used at, because that is the real test."""
    tiles = [mark.resize((s, s), Image.LANCZOS) for s in SIZES]
    pad = 24
    w = sum(t.width for t in tiles) + pad * (len(tiles) + 1)
    strip = Image.new("RGB", (w, SIZES[0] + pad * 2), CREAM)
    x = pad
    for t in tiles:
        strip.paste(t, (x, pad + (SIZES[0] - t.height) // 2), t)
        x += t.width + pad
    strip.save(path)


def main():
    if not os.path.exists(SRC):
        sys.exit("missing source: %s" % SRC)
    os.makedirs(OUTDIR, exist_ok=True)

    mark = flatten(Image.open(SRC))
    before = len(np.unique(np.asarray(Image.open(SRC).convert("RGB")).reshape(-1, 3), axis=0))
    after = len(np.unique(np.asarray(mark.convert("RGB")).reshape(-1, 3), axis=0))

    badge = letter(mark)                     # the same emblem with the name set into its lower half

    written = []
    for tag, img in (("mark", mark), ("badge", badge)):
        p = os.path.join(OUTDIR, "%s_master.png" % tag)      # flat, hard-edged, native size
        img.save(p)
        written.append(os.path.relpath(p, ROOT))
        for s in SIZES:
            p = os.path.join(OUTDIR, "%s_%d.png" % (tag, s))
            img.resize((s, s), Image.LANCZOS).save(p)
            written.append(os.path.relpath(p, ROOT))
        p = os.path.join(OUTDIR, "%s_cream.png" % tag)
        on_cream(img).save(p)
        written.append(os.path.relpath(p, ROOT))
        p = os.path.join(OUTDIR, "%s_sizes.png" % tag)
        ladder(img, p)
        written.append(os.path.relpath(p, ROOT))

    print("colours: %d -> %d" % (before, after))
    print("wrote " + ", ".join(written))


if __name__ == "__main__":
    main()
