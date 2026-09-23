#!/usr/bin/env python3
"""Take the seam off the setup board's buttons: the art's own rectangle blends into the button.

Maintainer, 2026-09-23, with a screenshot of the Theme and Mountain buttons: "all the buttons still
have seams visible between the button itself and the art used." A label is artwork over a caption on
transparency, and the artwork is a rectangular crop of a picture with its own background. Even when
that background is the button's exact colour (Theme's is #49514b, and so is its button) the rectangle
shows, because TTS shades its button sprite and paints the icon flat over it.

So the rectangle has to go, two ways:

  * A picture on a FLAT ground (the owl on grey-green) has the ground keyed out: from the rectangle's
    edge inward, every pixel within TOL of the edge colour and connected to the edge becomes
    transparent, so the button's own shading shows around the figure. Only the connected ground goes;
    the same colour inside the figure stays.
  * A picture that IS the rectangle (a map, a deck, a photo) cannot be keyed, so its edge is feathered
    over FEATHER px into transparency. No hard line, and the picture keeps its whole face.

Silhouettes (the faction heads, already on alpha) are left alone: they have no rectangle.

    python tools/deseam.py --preview out.png     # a contact sheet of every board label, before/after
    python tools/deseam.py --write               # new hashed files, save.json URLs, old files removed

tools/relabel.py calls deseam() on every artwork it composes, so a re-render on the Mac keeps this.
"""
import argparse
import hashlib
import json
import os
import re
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SAVE = os.path.join(ROOT, "gen", "src", "save.json")
BOARD = "bab7e1"
CDN = "https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/assets/"

TOL = 24          # colour distance (max channel) that still counts as the ground
FEATHER = 9       # px of edge fade for a picture that cannot be keyed
RECT_FILL = 0.78  # an art box this full is a rectangle, not a silhouette
KEY_MAX = 0.70    # a key that would take more than this of the box is not a ground: feather instead
# WHICH TREATMENT, BY NAME. Keying is only right for an illustration on a flat ground -- the owl --
# and a picture whose face is the point (the Faction Cards card) keeps its edge. Everything else
# that is a rectangle is feathered. Decided by name rather than measured: the preview of 2026-09-23
# showed a measured rule keying the snow off the Winter map and about to flood the card's white face.
KEY = {"ThemeArt", "FlotillaArt"}                 # an illustration on a flat ground in the button's colour
SKIP = {"FactionCardsArt", "Riverfolk Company"}   # the card is the picture; the otter is a silhouette that fills its box


def _art_box(a, square):
    """The opaque box of the artwork: the top band of a square label, the left half of a wide one."""
    h, w = a.shape[:2]
    band = a[: int(h * 0.62)] if square else a[:, : int(w * 0.5)]
    op = band[..., 3] > 40
    if not op.any():
        return None
    ys, xs = np.where(op)
    return int(ys.min()), int(ys.max()) + 1, int(xs.min()), int(xs.max()) + 1


def _flood(near, seed):
    """Grow `seed` through `near` (4-connected) until nothing changes."""
    cur = seed & near
    while True:
        grown = cur.copy()
        grown[1:] |= cur[:-1]
        grown[:-1] |= cur[1:]
        grown[:, 1:] |= cur[:, :-1]
        grown[:, :-1] |= cur[:, 1:]
        grown &= near
        if (grown == cur).all():
            return cur
        cur = grown


def deseam(im, name=""):
    """Return (image, what) -- what is 'key', 'feather' or 'none'."""
    im = im.convert("RGBA")
    if name in SKIP:
        return im, "none"
    a = np.asarray(im).astype(np.int16)
    h, w = a.shape[:2]
    box = _art_box(a, square=(h >= w))
    if box is None:
        return im, "none"
    t, b, l, r = box
    rect = a[t:b, l:r]
    alpha = rect[..., 3]
    fill = (alpha > 40).mean()
    if fill < RECT_FILL:
        return im, "none"                        # a silhouette: nothing to take off
    edge = np.zeros(alpha.shape, bool)
    edge[0], edge[-1], edge[:, 0], edge[:, -1] = True, True, True, True
    edge &= alpha > 40
    colours = rect[..., :3][edge]
    med = np.median(colours, axis=0)
    out = a.copy()
    if name in KEY:
        near = (np.abs(rect[..., :3] - med).max(2) <= TOL) & (alpha > 40)
        ground = _flood(near, edge)
        if ground.mean() <= KEY_MAX and ground.mean() > 0.02:
            sub = out[t:b, l:r]
            sub[..., 3] = np.where(ground, 0, sub[..., 3])
            # a one-pixel soft edge where the ground met the figure
            soft = np.zeros(alpha.shape, bool)
            soft[1:] |= ground[:-1]; soft[:-1] |= ground[1:]
            soft[:, 1:] |= ground[:, :-1]; soft[:, :-1] |= ground[:, 1:]
            soft &= ~ground
            sub[..., 3] = np.where(soft, (sub[..., 3] * 0.55).astype(np.int16), sub[..., 3])
            out[t:b, l:r] = sub
            return Image.fromarray(out.astype(np.uint8), "RGBA"), "key"
    # feather the rectangle's edge into the button
    yy, xx = np.mgrid[0:b - t, 0:r - l]
    dist = np.minimum(np.minimum(yy, (b - t - 1) - yy), np.minimum(xx, (r - l - 1) - xx)) + 1
    ramp = np.clip(dist / float(FEATHER), 0, 1)
    sub = out[t:b, l:r]
    sub[..., 3] = (sub[..., 3] * ramp).astype(np.int16)
    out[t:b, l:r] = sub
    return Image.fromarray(out.astype(np.uint8), "RGBA"), "feather"


def deseam_file(path, name):
    """For tools/relabel.py: take the seam off a label it has just composed, in place."""
    im, what = deseam(Image.open(path), name)
    if what != "none":
        im.save(path)
    return what


def board_labels():
    """(asset name, colour, local path) for every icon the board's markup shows from our assets."""
    doc = json.loads(open(SAVE, "rb").read().decode("utf-8"))
    board = next(o for o in doc["ObjectStates"] if o.get("GUID") == BOARD)
    xml = board["XmlUI"]
    urls = {a["Name"]: a["URL"] for a in board["CustomUIAssets"]}
    out = []
    for m in re.finditer(r'<Button[^>]*>', xml):
        tag = m.group(0)
        ic = re.search(r'icon\s*=\s*"([^"]+)"', tag)
        co = re.search(r'color="([^"]+)"', tag)
        if not ic:
            continue
        url = urls.get(ic.group(1), "")
        if "@main/assets/" not in url:
            continue
        local = os.path.join(ROOT, "assets", url.split("@main/assets/")[1])
        if os.path.exists(local):
            out.append((ic.group(1), (co.group(1) if co else "#808080")[:7], local, url))
    return out


def hexrgb(s):
    named = {"gray": "808080", "grey": "808080", "white": "ffffff", "black": "000000"}
    s = named.get(s.lower(), s.lstrip("#"))
    if len(s) < 6:
        s = "808080"
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def preview(path):
    labels = board_labels()
    cell, pad = 150, 8
    cols = 6
    rows = (len(labels) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * (2 * cell + 3 * pad), rows * (cell + 2 * pad + 14)), (30, 30, 30))
    d = ImageDraw.Draw(sheet)
    for i, (name, colour, local, _) in enumerate(labels):
        before = Image.open(local).convert("RGBA")
        after, what = deseam(before, name)
        x0 = (i % cols) * (2 * cell + 3 * pad) + pad
        y0 = (i // cols) * (cell + 2 * pad + 14) + pad
        for k, im in enumerate((before, after)):
            tile = Image.new("RGBA", (cell, cell), hexrgb(colour) + (255,))
            im2 = im.resize((cell, cell), Image.LANCZOS)
            tile.alpha_composite(im2)
            sheet.paste(tile.convert("RGB"), (x0 + k * (cell + pad), y0))
        d.text((x0, y0 + cell + 2), "%s  [%s]" % (name[:22], what), fill=(220, 220, 220))
    sheet.save(path)
    print("preview:", path)


def write():
    raw = open(SAVE, "rb").read()
    labels = board_labels()
    changed = 0
    for name, colour, local, url in labels:
        after, what = deseam(Image.open(local), name)
        if what == "none":
            continue
        d, fn = os.path.split(local)
        stem = re.sub(r"_[0-9a-f]{8}$", "", os.path.splitext(fn)[0])
        tmp = os.path.join(d, stem + ".png")
        after.save(tmp)
        h = hashlib.md5(open(tmp, "rb").read()).hexdigest()[:8]
        final = os.path.join(d, "%s_%s.png" % (stem, h))
        os.replace(tmp, final)
        new_url = CDN + final.replace("\\", "/").split("/assets/", 1)[1]
        assert raw.count(url.encode("ascii")) == 1, name
        raw = raw.replace(url.encode("ascii"), new_url.encode("ascii"))
        if os.path.abspath(final) != os.path.abspath(local):
            os.remove(local)
        changed += 1
        print("  %-28s %-8s -> %s" % (name, what, os.path.basename(final)))
    json.loads(raw.decode("utf-8"))
    open(SAVE, "wb").write(raw)
    print("%d label(s) rewritten, save.json URLs updated" % changed)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--preview")
    ap.add_argument("--write", action="store_true")
    args = ap.parse_args()
    if args.preview:
        preview(args.preview)
    if args.write:
        write()
    if not args.preview and not args.write:
        ap.print_help()
