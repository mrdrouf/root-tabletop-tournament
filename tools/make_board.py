#!/usr/bin/env python3
"""Take the Lost Souls box off the Lizard Cult board, keep the lizard, and mend the art behind it.

Maintainer, 2026-09-08: "remove the lost souls art on the faction board for the lost soul cards
since they all go on the lizard wizard"; then "you also can keep the lizard he looks nice and can
stay. just put him a little bit below"; then, on two attempts that rebuilt the background,
"we can perceive a seam and the art does not connect", and finally the one that settled it:

    "you drew random stuff, these are supposed to be like small trees as you can see all over the
     board art. what you did is just scrambled mess"

    python3 tools/make_board.py

Writes assets/labels/lizard_board_v<N>_<md5>.png and prints the URL for gen/src/content.lua.

WHAT THE BACKGROUND ACTUALLY IS, and why that settles the method.

It is not a texture. It is a scatter of small drawn trees -- a stem with paired curling branches --
and a tree is a thing, not a pattern. Three versions were built that treated it as texture: quilting
strips of it, sowing whole motifs at a matching density, and bridging stems with motif pieces masked
to the shape of the hole. All three failed the same way and for the same reason. Once you cut a tree
to fit a hole you are no longer drawing a tree, you are scattering pieces of one, and no amount of
matching the tone or the density makes litter read as woodland.

So nothing here invents background. The box is lifted off and the drawing UNDERNEATH IT IS CARRIED
ACROSS THE GAP, along whichever axis the gap is narrower: a stem crossing the border is continued
downward, the border's own vertical bars are continued sideways, and plain ground stays plain
ground because both sides of it are plain ground. Every tree the box interrupted is finished in its
own hand, in its own place, because it is its own pixels that finish it.

Continuation only carries so far -- across a border or a line of text it is exact, across the 341px
the lizard used to cover it is a smear of nothing -- so past `near` it hands over to a flat ground
field interpolated from the surrounding board. The part of that region which stays visible once the
lizard moves down is well inside the honest range.
"""
import hashlib
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
SRC = os.path.join(REPO, "assets", "src_art")
OUT = os.path.join(REPO, "assets", "labels")
CDN = "https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/assets/labels/%s"

VERSION = 2
BOX = (1225, 700, 1655, 1300)   # generous bounds round the printed Lost Souls box
BG_THRESH = 22                  # L1 distance to the background palette that still counts as green
MASK_THRESH = 14                # ...and the tighter one used to find the artwork
LIZARD_DROP = 70                # "just put him a little bit below"
SEED = 4


def toimg(m):
    return Image.fromarray((m * 255).astype(np.uint8))


def dilate(m, k):
    return np.asarray(toimg(m).filter(ImageFilter.MaxFilter(2 * k + 1))) > 127


def erode(m, k):
    return np.asarray(toimg(m).filter(ImageFilter.MinFilter(2 * k + 1))) > 127


def soft(m, feather=1.6):
    return np.asarray(toimg(m).filter(ImageFilter.GaussianBlur(feather))).astype(np.float32) / 255.0


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


def _box1d(x, r, axis):
    n = x.shape[axis]
    pad = [(0, 0)] * x.ndim
    pad[axis] = (r + 1, r)
    c = np.cumsum(np.pad(x, pad, mode="edge"), axis=axis)
    lo = np.take(c, np.arange(0, n), axis=axis)
    hi = np.take(c, np.arange(2 * r + 1, n + 2 * r + 1), axis=axis)
    return (hi - lo) / (2 * r + 1)


def blur(x, r, passes=3):
    """A Gaussian in all but name, and it works on floats, which PIL's filter will not."""
    for _ in range(passes):
        x = _box1d(_box1d(x, r, 0), r, 1)
    return x


def palette_of(img, regions, share=0.0004):
    """The green background's own colours, sampled from margins the box never touched.

    KEEP ONLY THE GREENS. The margins run up to the board's printed edge, so the raw sample picks up
    its dark outline -- (23,19,10), (33,36,6) and friends -- and once those are in the palette, every
    dark pixel on the board counts as background. That is not academic: the Outcast panel's dark
    lower border then passed as "clean ground" and dragged the interpolated ground colour ten levels
    darker than the board it had to meet, which is exactly the seam the maintainer could see along
    the top edge.
    """
    px = np.concatenate([img[a:b, c:d].reshape(-1, 3) for a, b, c, d in regions])
    cols, cnt = np.unique(px, axis=0, return_counts=True)
    keep = cnt >= len(px) * share
    green = (cols[:, 1].astype(int) - cols[:, 2].astype(int) >= 45) & (cols[:, 1] >= 110)
    return cols[keep & green]


def components(m):
    lab = np.zeros(m.shape, np.int32)
    cur = 0
    info = {}
    H, W = m.shape
    for sy in range(H):
        for sx in np.where(m[sy] & (lab[sy] == 0))[0]:
            if lab[sy, sx]:
                continue
            cur += 1
            st = [(sy, sx)]
            lab[sy, sx] = cur
            a = b = sx
            c = e = sy
            n = 0
            while st:
                y, x = st.pop()
                n += 1
                a, b = min(a, x), max(b, x)
                c, e = min(c, y), max(e, y)
                for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                    if 0 <= ny < H and 0 <= nx < W and m[ny, nx] and not lab[ny, nx]:
                        lab[ny, nx] = cur
                        st.append((ny, nx))
            info[cur] = (n, a, b, c, e)
    return lab, info


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
    A = np.asarray(im)
    seed = None
    for yy in range(40, A.shape[0] - 40):
        xs = np.where(A[yy, 30:-30] == 255)[0]
        if len(xs):
            seed = (30 + int(xs[0]), yy)
            break
    ImageDraw.floodfill(im, seed, 128)
    return dilate(~(np.asarray(im) == 128), 5)


def sample(F, gy, gx, step, H, W):
    """Bilinear lookup of a coarse field at its OWN coordinates.

    Not PIL's resize with a box: that stretches the whole grid across the whole image, which put the
    panel's ground colour where the field held some other part of the board. It is a quiet failure --
    the result is still a smooth plausible field, just the wrong one -- and it is what actually made
    the rebuilt ground meet the board ten levels too dark along the top edge.
    """
    gi = np.clip((np.arange(H) - gy[0]) / step, 0, len(gy) - 1)
    gj = np.clip((np.arange(W) - gx[0]) / step, 0, len(gx) - 1)
    i0 = np.floor(gi).astype(int); i1 = np.minimum(i0 + 1, len(gy) - 1); wy = (gi - i0)[:, None, None]
    j0 = np.floor(gj).astype(int); j1 = np.minimum(j0 + 1, len(gx) - 1); wx = (gj - j0)[None, :, None]
    return ((F[np.ix_(i0, j0)] * (1 - wy) + F[np.ix_(i1, j0)] * wy) * (1 - wx)
            + (F[np.ix_(i0, j1)] * (1 - wy) + F[np.ix_(i1, j1)] * wy) * wx)


def smooth_ground(front, need, pal, rng, step=12, w=44, passes=200, G=48):
    """Lay the ground as a smooth colour field plus real grain -- no blocks anywhere.

    Quilting flat green from random places still shows: each block carries its own slightly
    different tone and the repair reads as a patchwork. But flat green has no structure to
    reproduce, only a colour and a grain. The colour comes from interpolating the surrounding
    background across the panel and relaxing it into the middle, which needs no source material.
    The grain is lifted from clean patches and tiled; there is no vine-free square big enough to
    take it from in one piece -- the vines are only ~60px apart -- but grain is zero-mean and has no
    large-scale shape, so tiles of it join with nothing to see. All the tone lives in the field.
    """
    clean = bg_dist(front, pal) < BG_THRESH
    # MEASURE THE GROUND THE WAY IT WILL BE JUDGED. Excluding a margin round every vine biases the
    # anchors dark -- the pixels beside a stroke are its lighter antialiasing -- so the field came
    # out about 10 levels below the board it had to meet, and that step WAS the seam the maintainer
    # could see along the top edge. The vine strokes themselves still come out; nothing beside them
    # does.
    # 5, not 10: the board ends only 12 rows below the panel, and a 10px exclusion eats that strip
    # entirely -- leaving the bottom edge with no anchor at all and its ground extrapolated from the
    # top, which the board's own vertical gradient then makes too bright.
    ground = clean & ~is_vine(front) & ~dilate(need, 5)
    H, W = front.shape[:2]
    ys, xs = np.where(need)
    Y0, Y1, X0, X1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1

    gy = np.arange(Y0 - w, Y1 + w, step)
    gx = np.arange(X0 - w, X1 + w, step)
    D = np.zeros((len(gy), len(gx), 3), np.float32)
    A = np.zeros((len(gy), len(gx)), bool)
    for i, yy in enumerate(gy):
        for j, xx in enumerate(gx):
            a, b = max(0, xx - w), min(W, xx + w + 1)
            c, e = max(0, yy - w), min(H, yy + w + 1)
            k = ground[c:e, a:b]
            if k.sum() < 120:
                continue
            D[i, j] = front[c:e, a:b][k].astype(np.float32).mean(0)
            A[i, j] = True
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
        F = np.where(A[..., None], D,
                     np.where(upd[..., None], acc / np.maximum(cnt, 1)[..., None], F))
        M = M | upd
    base = sample(F, gy, gx, step, H, W)

    resid = front.astype(np.float32) - blur(front.astype(np.float32), 5)
    sA = sat(ground)
    gy2, gx2 = np.meshgrid(np.arange(H - G), np.arange(W - G), indexing="ij")
    py, px = np.where(win(sA, gy2, gx2, G, G) == G * G)
    tiled = np.zeros_like(resid)
    for yy in range(Y0 - G, Y1 + G, G):
        for xx in range(X0 - G, X1 + G, G):
            y2, x2 = max(0, min(yy, H - G)), max(0, min(xx, W - G))
            i = rng.integers(len(py))
            t = resid[py[i]:py[i] + G, px[i]:px[i] + G]
            # TAKE THE DC OUT OF EVERY TILE. The residual is measured against a blur that neighbouring
            # vines lift, so a tile cut from vine-free ground carries a systematically NEGATIVE mean --
            # about ten levels of green. Left in, it subtracts that from the field everywhere and the
            # rebuilt ground meets the board ten levels too dark. Grain is supposed to be the part with
            # no tone in it; this makes that true.
            t = t - t.mean(axis=(0, 1))
            if rng.random() < 0.5:
                t = t[:, ::-1]
            if rng.random() < 0.5:
                t = t[::-1, :]
            tiled[y2:y2 + G, x2:x2 + G] = t

    out = front.copy()
    out[need] = np.clip(base + tiled, 0, 255).astype(np.uint8)[need]
    return out


def _fill_axis(img, hole, axis):
    """Nearest valid value on each side along `axis`, and how far away each one is."""
    if axis == 1:
        img, hole = img.transpose(1, 0, 2), hole.T
    n = hole.shape[0]
    idx = np.arange(n)[:, None] * np.ones((1, hole.shape[1]), int)
    prev = np.where(~hole, idx, -1)
    np.maximum.accumulate(prev, axis=0, out=prev)
    nxt = np.where(~hole, idx, n)
    nxt = np.minimum.accumulate(nxt[::-1], axis=0)[::-1]
    p = np.clip(prev, 0, n - 1)
    q = np.clip(nxt, 0, n - 1)
    cols = np.arange(hole.shape[1])[None, :]
    lo, hi = img[p, cols], img[q, cols]
    dlo = np.where(prev < 0, 1e9, idx - prev).astype(np.float32)
    dhi = np.where(nxt >= n, 1e9, nxt - idx).astype(np.float32)
    span = dlo + dhi
    w = (dlo / np.maximum(span, 1))[..., None]
    out = lo * (1 - w) + hi * w
    if axis == 1:
        out, span = out.transpose(1, 0, 2), span.T
    return out, span


def mend(front, hole, ground=None, near=60, far=110):
    """Carry the drawing across the gap, along whichever axis the gap is NARROWER.

    This is the whole repair, and it is the one thing that keeps the art connected. A stem crossing
    a horizontal band is continued downward; the border's vertical bars are continued sideways; and
    plain ground stays plain ground, because both sides of it are plain ground. Nothing is invented,
    so nothing can arrive as a fragment -- which is what pasting pieces of trees into hole-shaped
    masks kept producing.

    Choosing the narrower axis matters: the border's left bar is 13px wide and 555px tall, and read
    vertically it would smear over half the panel.
    """
    f = front.astype(np.float32)
    v, sv = _fill_axis(f, hole, 0)
    h, sh = _fill_axis(f, hole, 1)
    span = np.minimum(sv, sh)
    use_v = (sv <= sh)[..., None]
    out = np.where(use_v, v, h)
    if ground is not None:
        # CONTINUATION ONLY CARRIES SO FAR. Across the border or a line of text it is exact; across
        # the 341px the lizard used to cover it is a long smear of nothing. Past `near` the fill
        # hands over to the flat ground, which is what that depth should be anyway -- and the part
        # of it that stays visible after he is moved down is well inside the honest range.
        t = np.clip((span - near) / float(far - near), 0, 1)[..., None]
        out = out * (1 - t) + ground.astype(np.float32) * t
    return np.where(hole[..., None], np.clip(out, 0, 255), f).astype(np.uint8)


def main():
    art_file = os.path.join(SRC, "lizard_board_front.png")
    if not os.path.exists(art_file):
        sys.exit("missing source art: assets/src_art/lizard_board_front.png")
    front = np.asarray(Image.open(art_file).convert("RGB"))
    rng = np.random.default_rng(SEED)

    pal = palette_of(front, [(300, 1240, 8, 52), (1274, 1308, 60, 1620)])
    x0, y0, x1, y1 = BOX
    art = np.zeros(front.shape[:2], bool)
    art[y0:y1, x0:x1] = artwork_mask(front, pal)

    lab, info = components(art)
    liz = max((n, c) for c, (n, a, b, cc, e) in info.items()
              if (b - a) < 400 and (e - cc) < 500)[1]
    _, la, lb, lc, le = info[liz]
    lizard = lab == liz
    print("   lizard: x %d..%d y %d..%d, dropping %dpx" % (la, lb, lc, le, LIZARD_DROP))

    ys, xs = np.where(art)
    X0, X1, Y0, Y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    rect = np.zeros(front.shape[:2], bool)
    rect[Y0:Y1, X0:X1] = True

    # ONLY WHAT THE BOX COVERED IS REBUILT. Replacing the whole panel meant re-inventing vines that
    # were never damaged, and they then had to be lined up with the board by luck. Everything the
    # box did not cover is left exactly as printed.
    ground = smooth_ground(front, art, pal, rng)
    out = mend(front, art, ground=ground)

    h, w = le - lc + 1, lb - la + 1
    nc = lc + LIZARD_DROP
    al = soft(lizard[lc:le + 1, la:lb + 1], 1.2)[..., None]
    reg = out[nc:nc + h, la:la + w].astype(np.float32)
    out[nc:nc + h, la:la + w] = np.clip(
        reg * (1 - al) + front[lc:le + 1, la:lb + 1].astype(np.float32) * al, 0, 255).astype(np.uint8)

    clean = bg_dist(front, pal) < BG_THRESH
    ring = np.zeros(front.shape[:2], bool)
    ring[Y0 - 80:Y1 + 80, X0 - 80:X1 + 80] = True
    td = is_vine(front)[clean & ring & ~dilate(rect, 4)].mean()
    # measured on the GROUND ONLY -- the lizard's own pale greens answer to the same test as a vine
    lizfoot = np.zeros(front.shape[:2], bool)
    lizfoot[nc - 12:nc + h + 12, la - 12:la + w + 12] = True
    ground_only = rect & ~lizfoot
    print("   panel mended; vine %.2f%% against %.2f%% around it"
          % (100 * is_vine(out)[ground_only].mean(), 100 * td))

    changed = (out != front).any(axis=-1)
    assert not (changed & ~rect).any(), "the rebuild touched pixels outside the Lost Souls panel"

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
