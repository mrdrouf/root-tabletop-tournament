#!/usr/bin/env python3
"""Take the Lost Souls box off the Lizard Cult board, and put the background back behind it.

Maintainer, 2026-09-08: "remove the lost souls art on the faction board for the lost soul cards
since they all go on the lizard wizard make sure its top notch craft and impossible to see something
has been removed." The board's printed Lost Souls box is dead space in this mod -- the Lizard Wizard
is the public tracker and every spent card goes there, which is also why the board's own readout
reads the wizard rather than this box.

    python3 tools/make_board.py

Writes assets/labels/lizard_board_v<N>_<md5>.png and prints the URL for gen/src/content.lua.

WHAT MAKES THIS HARD, and why the obvious routes do not work:

The box is not painted onto a blank area. The green vine background runs behind it, so removing it
means rebuilding 430x597 of that pattern -- long vertical stems with V-shaped leaf pairs, hand drawn
and irregular. Three things all have to match, and missing any one of them is visible:

  TONE.    The board's green is not even; region means run from (132,142,62) to (192,205,72).
  DENSITY. This panel's background is a SPARSER cut of the vine than the board at large -- about 7%
           vine against 16% -- so filling from the board generally comes back overgrown.
  STRUCTURE. The stems run unbroken for hundreds of pixels. Square-block texture synthesis chops
           them into a field of loose leaf tips: right density, wrong drawing.

The play side cannot supply it. Every fully clean strip of its own background is 24px wide and there
are six distinct ones, so any fill built from them repeats visibly. The MANIFEST SIDE can: it is the
same board exported at 4/3 the size, the same vine drawn by the same hand, and 86% bare background.
Rescaled to the play side's pixels and put through a per-channel map fitted on the two faces' own
background distributions, it yields tens of thousands of full-height strips across ~100 distinct
columns at this panel's tone and density.

Two further things that each cost a rebuild to learn:

  The two faces do NOT share a background layout (correlation 0.14 where both are bare), so the back
  cannot simply be lifted into place -- it is a source of matching texture, not the missing pixels.

  The fill is seated on the surrounding tone with a correction field solved on a coarse grid and
  relaxed into the middle of the hole. Correcting per strip leaves a step at every strip edge;
  correcting with a normalized blur divides by zero in the middle of a large hole. Both were built
  and both showed.
"""
import hashlib
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
SRC = os.path.join(REPO, "assets", "src_art")
OUT = os.path.join(REPO, "assets", "labels")
CDN = "https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/assets/labels/%s"

VERSION = 1
BOX = (1225, 700, 1655, 1300)      # generous bounds round the printed Lost Souls box
BG_THRESH = 22                     # L1 distance to the background palette that still counts as green
MASK_THRESH = 14                   # ...and the tighter one used to find the artwork
SEED = 5


def toimg(m):
    return Image.fromarray((m * 255).astype(np.uint8))


def dilate(m, k):
    return np.asarray(toimg(m).filter(ImageFilter.MaxFilter(2 * k + 1))) > 127


def erode(m, k):
    return np.asarray(toimg(m).filter(ImageFilter.MinFilter(2 * k + 1))) > 127


def bg_dist(img, pal):
    d = np.full(img.shape[:2], 1e9, np.float32)
    for c in pal:
        np.minimum(d, np.abs(img.astype(np.int16) - c).sum(axis=-1).astype(np.float32), out=d)
    return d


def is_vine(img):
    """The pale stroke, against the darker base green."""
    return (img[..., 0].astype(int) > 185) & (img[..., 1].astype(int) > 198)


def sat(x):
    s = np.zeros((x.shape[0] + 1, x.shape[1] + 1), np.float64)
    s[1:, 1:] = np.cumsum(np.cumsum(x.astype(np.float64), 0), 1)
    return s


def win(s, ys, xs, h, w):
    return s[ys + h, xs + w] - s[ys, xs + w] - s[ys + h, xs] + s[ys, xs]


def palette_of(img, regions, share=0.0004):
    px = np.concatenate([img[a:b, c:d].reshape(-1, 3) for a, b, c, d in regions])
    cols, cnt = np.unique(px, axis=0, return_counts=True)
    return cols[cnt >= len(px) * share]


def artwork_mask(front, pal):
    """Everything inside BOX that is not background: the border, the two lines of text, the lizard.

    The border is a closed ring, so filling holes from outside swallows the whole panel; the
    interior background is flooded separately from its own seed to keep it.
    """
    x0, y0, x1, y1 = BOX
    d = bg_dist(front[y0:y1, x0:x1], pal)
    closed = erode(dilate(d > MASK_THRESH, 4), 4)
    im = toimg(~closed).convert("L")
    ImageDraw.floodfill(im, (0, 0), 128)
    seed = None
    A = np.asarray(im)
    for yy in range(40, A.shape[0] - 40):
        xs = np.where(A[yy, 30:-30] == 255)[0]
        if len(xs):
            seed = (30 + int(xs[0]), yy)
            break
    ImageDraw.floodfill(im, seed, 128)
    return dilate(~(np.asarray(im) == 128), 5)


def map_back(front, back, fpal):
    """The manifest side, rescaled to the play side and recoloured onto its palette.

    Matched on each background's own mean and spread. Anchoring on percentiles instead looks more
    principled and is worse -- the play side's clean background runs down to 112 where the manifest
    side's stops at 224, so the low anchor is fitting two different things.
    """
    back = np.asarray(Image.fromarray(back).resize((front.shape[1], front.shape[0]), Image.LANCZOS))
    bpal = palette_of(back, [(60, 1270, 30, 110)])
    bclean = bg_dist(back, bpal) < BG_THRESH
    fclean = bg_dist(front, fpal) < BG_THRESH
    A = back[bclean].astype(np.float64)
    B = front[fclean].astype(np.float64)
    scale = B.std(0) / A.std(0)
    off = B.mean(0) - A.mean(0) * scale
    mapped = np.clip(back * scale + off, 0, 255).astype(np.uint8)
    return mapped, bclean


def fill(front, mask, target, tgt_d, src_img, src_ok,
         BW=44, SX=38, TOPK=3, ctx=3000, tone_tol=34, dens_tol=0.03):
    """One full-height strip per column band, so stems arrive unbroken.

    Strips are chosen by matching the background that SURVIVES in that band, weighted toward the
    pixels nearest the hole -- those are the ones a stem has to meet. Matching evenly over the whole
    band lets a strip win on empty green far from the seam and still arrive with a stem out of
    nowhere.
    """
    rng = np.random.default_rng(SEED)
    x0, y0, x1, y1 = BOX
    canvas = front.copy()
    unknown = np.zeros(front.shape[:2], bool)
    unknown[y0:y1, x0:x1] = mask
    ys, _ = np.where(unknown)
    Y0, Y1 = ys.min(), ys.max() + 1
    BH = Y1 - Y0

    vine = is_vine(src_img)
    H, W = src_ok.shape
    sA, sV = sat(src_ok), sat(vine)
    sC = [sat(src_img[..., c]) for c in range(3)]
    gy, gx = np.meshgrid(np.arange(H - BH), np.arange(W - BW), indexing="ij")
    n = BH * BW
    ok = win(sA, gy, gx, BH, BW) == n
    ok &= np.abs(win(sV, gy, gx, BH, BW) / n - tgt_d) < dens_tol
    ok &= sum(np.abs(win(sC[c], gy, gx, BH, BW) / n - target[c]) for c in range(3)) < tone_tol
    py, px = np.where(ok)
    print("   %d source strips, %d distinct columns" % (len(py), len(np.unique(px))))
    if len(py) > 9000:
        pick = rng.choice(len(py), 9000, replace=False)
        py, px = py[pick], px[pick]
    src = np.stack([src_img[y:y + BH, x:x + BW] for y, x in zip(py, px)]).astype(np.float32)
    flat = src.reshape(len(src), -1)

    recent = []
    for bx in range(x0 - BW // 2, x1 + BW // 2, SX):
        bx2 = max(0, min(bx, W - BW))
        u = unknown[Y0:Y1, bx2:bx2 + BW]
        if not u.any():
            continue
        k = ~u
        tgt = canvas[Y0:Y1, bx2:bx2 + BW].astype(np.float32)
        pen = np.zeros(len(src), np.float32)
        for j, w in recent:
            pen[j] += w
        if k.sum() >= 40:
            pool = np.where((k & dilate(u, 26)).ravel())[0]
            if len(pool) < 400:
                pool = np.where(k.ravel())[0]
            idx = pool if len(pool) <= ctx else rng.choice(pool, ctx, replace=False)
            cols = np.concatenate([idx * 3, idx * 3 + 1, idx * 3 + 2])
            diff = flat[:, cols] - tgt.reshape(-1)[cols]
            err = np.einsum("ij,ij->i", diff, diff)
            err = err / max(err.min(), 1.0) + pen
            kk = min(TOPK, len(src) - 1)
            best = np.argpartition(err, kk)[:kk + 1]
            j = int(best[rng.integers(len(best))])
        else:
            j = int(rng.integers(len(src)))
        recent.append((j, 8.0))
        recent[:] = [(a, b * 0.5) for a, b in recent[-12:]]
        canvas[Y0:Y1, bx2:bx2 + BW][u] = src[j][u].astype(np.uint8)
        unknown[Y0:Y1, bx2:bx2 + BW] = False
    return canvas


def seat(canvas, original, filled, step=14, w=46, passes=140):
    """Slide the repair onto the surrounding tone with a 2D correction field.

    Anchored wherever a window holds enough of both the surviving background and the new fill;
    nodes with no anchor -- the middle of the hole -- are relaxed in from the ones that have one.
    Measured on BASE GREEN only, so a window holding more vine on one side reads as density rather
    than tone.
    """
    ys, _ = np.where(filled)
    Y0, Y1 = ys.min(), ys.max() + 1
    x0, y0, x1, y1 = BOX
    known = ~filled & ~is_vine(original)
    newly = filled & ~is_vine(canvas)
    H, W = canvas.shape[:2]
    gx = np.arange(x0 - w, x1 + w, step)
    gy = np.arange(Y0 - w, Y1 + w, step)
    D = np.zeros((len(gy), len(gx), 3), np.float32)
    A = np.zeros((len(gy), len(gx)), bool)
    for i, yy in enumerate(gy):
        for j, xx in enumerate(gx):
            a, b = max(0, xx - w), min(W, xx + w + 1)
            c, e = max(0, yy - w), min(H, yy + w + 1)
            kk, nn = known[c:e, a:b], newly[c:e, a:b]
            if kk.sum() < 150 or nn.sum() < 150:
                continue
            D[i, j] = (original[c:e, a:b][kk].astype(np.float32).mean(0)
                       - canvas[c:e, a:b][nn].astype(np.float32).mean(0))
            A[i, j] = True
    if not A.any():
        return canvas
    F, M = D.copy(), A.copy()
    for _ in range(passes):
        acc = np.zeros_like(F)
        cnt = np.zeros(M.shape, np.float32)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            s = np.roll(np.roll(F, dy, 0), dx, 1)
            m = np.roll(np.roll(M, dy, 0), dx, 1)
            acc += s * m[..., None]
            cnt += m
        upd = cnt > 0
        F = np.where(A[..., None], D, np.where(upd[..., None], acc / np.maximum(cnt, 1)[..., None], F))
        M = M | upd
    fy = np.clip((np.arange(H) - gy[0]) / step, 0, len(gy) - 1)
    fx = np.clip((np.arange(W) - gx[0]) / step, 0, len(gx) - 1)
    big = np.stack([np.asarray(Image.fromarray(F[..., c], "F").resize(
        (W, H), Image.BILINEAR, box=(fx[0], fy[0], fx[-1], fy[-1]))) for c in range(3)], axis=2)
    out = canvas.astype(np.float32)
    out[filled] += big[filled]
    return np.clip(out, 0, 255).astype(np.uint8)


def main():
    for f in ("lizard_board_front.png", "lizard_board_back.png"):
        if not os.path.exists(os.path.join(SRC, f)):
            sys.exit("missing source art: assets/src_art/%s" % f)
    front = np.asarray(Image.open(os.path.join(SRC, "lizard_board_front.png")).convert("RGB"))
    back = np.asarray(Image.open(os.path.join(SRC, "lizard_board_back.png")).convert("RGB"))

    # the background palette, from margins the Lost Souls box never touched
    pal = palette_of(front, [(300, 1240, 8, 52), (1274, 1308, 60, 1620)])
    mask = artwork_mask(front, pal)
    x0, y0, x1, y1 = BOX
    unknown = np.zeros(front.shape[:2], bool)
    unknown[y0:y1, x0:x1] = mask

    # what the repair has to look like: the clean green in and immediately around the panel
    clean = bg_dist(front, pal) < BG_THRESH
    ring = np.zeros(front.shape[:2], bool)
    ring[y0 - 70:y1 + 70, x0 - 70:x1 + 70] = True
    ref = clean & ring & ~dilate(unknown, 4)
    target, tgt_d = front[ref].mean(0), is_vine(front)[ref].mean()
    print("   panel texture: tone %s, vine density %.2f%%" % (target.round(1), 100 * tgt_d))

    mapped, bclean = map_back(front, back, pal)
    out = fill(front, mask, target, tgt_d, mapped, bclean)
    out = seat(out, front, unknown)

    # it must differ from the original ONLY where the box was
    changed = (out != front).any(axis=-1)
    assert not (changed & ~unknown).any(), "the repair touched pixels outside the Lost Souls box"
    d = bg_dist(out[y0:y1, x0:x1], pal)
    print("   repaired: %d px, palette distance median %.0f, vine density %.2f%%"
          % (int(unknown.sum()), np.median(d), 100 * is_vine(out)[unknown].mean()))

    if not os.path.isdir(OUT):
        os.makedirs(OUT)
    tmp = os.path.join(OUT, "_tmp_board.png")
    Image.fromarray(out).save(tmp, optimize=True)
    digest = hashlib.md5(open(tmp, "rb").read()).hexdigest()[:8]
    final = "lizard_board_v%d_%s.png" % (VERSION, digest)
    os.replace(tmp, os.path.join(OUT, final))
    print()
    print(CDN % final)


if __name__ == "__main__":
    main()
