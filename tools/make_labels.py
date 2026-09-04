#!/usr/bin/env python3
"""Render the mod's button labels in LUMINARI - the font Root itself uses for faction titles
(confirmed against the rats board: "Lord of the Hundreds" matches letter for letter).

Every label is artwork on the left and the name on the right, on the button's own colour. The
artwork is reused from the existing label; only the type is re-set. Run from the repo root.

Luminari is (c) Canada Type and ships with macOS. We RENDER with it, which is ordinary font use;
we never redistribute the .ttf.
"""
import os, sys, statistics
from PIL import Image, ImageDraw, ImageFont

LUM = "/System/Library/Fonts/Supplemental/Luminari.ttf"
CREAM = (237, 224, 192)
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def font(size):
    return ImageFont.truetype(LUM, size)


def fit(draw, text, box_w, start, minsz=8):
    for s in range(start, minsz - 1, -1):
        f = font(s)
        if draw.textlength(text, font=f) <= box_w:
            return f
    return font(minsz)


def crop_inside_frame(im, dark=52):
    """Trim an artwork's own dark frame, which otherwise reads as a seam on a coloured button."""
    im = im.convert("RGB")
    px = im.load()
    W, H = im.size
    l, t, r, b = 0, 0, W - 1, H - 1
    rowdark = lambda y, x0, x1: statistics.mean(sum(px[x, y]) / 3 for x in range(x0, x1 + 1)) < dark
    coldark = lambda x, y0, y1: statistics.mean(sum(px[x, y]) / 3 for y in range(y0, y1 + 1)) < dark
    for _ in range(max(W, H)):
        moved = False
        if l < r and coldark(l, t, b): l += 1; moved = True
        if l < r and coldark(r, t, b): r -= 1; moved = True
        if t < b and rowdark(t, l, r): t += 1; moved = True
        if t < b and rowdark(b, l, r): b -= 1; moved = True
        if not moved:
            break
    return im.crop((l, t, r + 1, b + 1))


def label(out, art, lines, bg, size=(400, 200), art_w=190, start=52):
    """artwork left, name right, on the button's colour"""
    W, H = size
    im = Image.new("RGB", size, bg)
    d = ImageDraw.Draw(im)
    if art is not None:
        a = crop_inside_frame(art)
        sc = min((art_w - 30) / a.width, (H - 30) / a.height)
        a = a.resize((int(a.width * sc), int(a.height * sc)), Image.LANCZOS)
        im.paste(a, ((art_w - a.width) // 2, (H - a.height) // 2))
    f = fit(d, max(lines, key=len), W - art_w - 24, start)
    lh = f.getbbox("Ag")[3] - f.getbbox("Ag")[1]
    gap = int(f.size * 0.30)
    top = (H - (lh * len(lines) + gap * (len(lines) - 1))) / 2
    for i, t in enumerate(lines):
        bb = f.getbbox(t)
        tw = d.textlength(t, font=f)
        d.text((art_w + ((W - art_w) - tw) / 2, top + i * (lh + gap) - bb[1]), t, font=f, fill=CREAM)
    im.save(out)
    return f.size


def banner(out, src, text, band_col, frac=0.773, pad=0.88):
    """a square button: keep the art, replace the caption band"""
    im = Image.open(src).convert("RGB")
    W, H = im.size
    y0 = int(H * frac)
    d = ImageDraw.Draw(im)
    d.rectangle([0, y0, W, H], fill=band_col)
    f = fit(d, text, W * pad, int((H - y0) * 0.72))
    bb = f.getbbox(text)
    tw = d.textlength(text, font=f)
    d.text(((W - tw) / 2, y0 + ((H - y0) - (bb[3] - bb[1])) / 2 - bb[1]), text, font=f, fill=CREAM)
    im.save(out)
    return f.size


# ---------------------------------------------------------------- uniform house style --
# One cream and one size per button SHAPE, so the row reads as a set. Sizes are chosen so the
# on-screen cap height matches across a shape class; only an over-long name is allowed to shrink.
WIDE = (400, 200)      # the 34x17 option buttons
SQUARE = (300, 300)    # the 34x34 map / deck buttons
WIDE_PT, SQUARE_PT = 54, 52
OUTLINE = (18, 12, 7)


def _outlined(d, xy, text, f, fill=CREAM, ring=3):
    x, y = xy
    for ox in range(-ring, ring + 1):
        for oy in range(-ring, ring + 1):
            if ox * ox + oy * oy <= ring * ring and (ox or oy):
                d.text((x + ox, y + oy), text, font=f, fill=OUTLINE)
    d.text((x, y), text, font=f, fill=fill)


def wide_label(out, art, lines, art_w=190, pt=WIDE_PT):
    """artwork left, name right, transparent ground so the button's own colour shows."""
    W, H = WIDE
    im = Image.new("RGBA", WIDE, (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    if art is not None:
        a = art.convert("RGBA")
        sc = min((art_w - 26) / a.width, (H - 26) / a.height)
        a = a.resize((int(a.width * sc), int(a.height * sc)), Image.LANCZOS)
        im.alpha_composite(a, ((art_w - a.width) // 2, (H - a.height) // 2))
    box = W - art_w - 20
    f = font(pt)
    while f.size > 12 and max(d.textlength(t, font=f) for t in lines) > box:
        f = font(f.size - 1)
    lh = f.getbbox("Ag")[3] - f.getbbox("Ag")[1]
    gap = int(f.size * 0.30)
    top = (H - (lh * len(lines) + gap * (len(lines) - 1))) / 2
    for i, t in enumerate(lines):
        bb = f.getbbox(t)
        tw = d.textlength(t, font=f)
        _outlined(d, (art_w + ((W - art_w) - tw) / 2, top + i * (lh + gap) - bb[1]), t, f)
    im.save(out)
    return f.size


def square_label(out, art, text, art_frac=0.76, pt=SQUARE_PT):
    """thumbnail on top, name under it, transparent ground."""
    W, H = SQUARE
    im = Image.new("RGBA", SQUARE, (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    a = art.convert("RGBA")
    ah = int(H * art_frac) - 10
    sc = min((W - 16) / a.width, ah / a.height)
    a = a.resize((int(a.width * sc), int(a.height * sc)), Image.LANCZOS)
    im.alpha_composite(a, ((W - a.width) // 2, 6))
    f = font(pt)
    while f.size > 12 and d.textlength(text, font=f) > W - 16:
        f = font(f.size - 1)
    bb = f.getbbox(text)
    tw = d.textlength(text, font=f)
    band_top = int(H * art_frac)
    _outlined(d, ((W - tw) / 2, band_top + ((H - band_top) - (bb[3] - bb[1])) / 2 - bb[1]), text, f)
    im.save(out)
    return f.size
