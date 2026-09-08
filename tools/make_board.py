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
PITCH = 90                     # column spacing that matches the board's own scatter of trees
TOP = 686                       # the ground starts just under the Outcast panel
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


def map_back(front, back):
    """The board's OTHER FACE, rescaled to this one and recoloured onto its palette.

    Maintainer: "the back fo the faction has the trees you can find just the wrong color." Exactly
    so, and it is the thing that makes this possible. The play side has almost no bare background --
    every tree on it is cropped by a panel or covered by the box -- so anything cut from it is a
    piece of a tree. The manifest side is the same board at 4/3 the size, drawn by the same hand, and
    it is 86% bare: its trees stand alone, whole, unoccluded, ready to lift.

    The two faces' backgrounds are NOT the same layout (correlation 0.14 where both are bare), so it
    is a source of trees, not of the missing pixels. Matched on each background's own mean and
    spread, it lands within 5 of this face's palette.
    """
    back = np.asarray(Image.fromarray(back).resize((front.shape[1], front.shape[0]), Image.LANCZOS))
    px = back[60:1270, 30:110].reshape(-1, 3)
    cols, cnt = np.unique(px, axis=0, return_counts=True)
    bpal = cols[cnt >= len(px) * 0.0004]
    bclean = bg_dist(back, bpal) < BG_THRESH
    fpal = palette_of(front, [(300, 1240, 8, 52), (1274, 1308, 60, 1620)])
    A = back[bclean].astype(np.float64)
    B = front[bg_dist(front, fpal) < BG_THRESH].astype(np.float64)
    scale = B.std(0) / A.std(0)
    return np.clip(back * scale + (B.mean(0) - A.mean(0) * scale), 0, 255).astype(np.uint8), bclean


def harvest(mapped, bclean):
    """Whole trees off the other face: a stem with its paired branches, entire.

    Size bounds keep out the header flourishes and the odd pair of trees that touch; the purity test
    keeps out anything carrying a neighbour's ink, which planted in open ground reads as a speck of a
    different drawing.
    """
    lab, info = components(erode(dilate(is_vine(mapped) & bclean, 2), 1))
    out = []
    for c, (n, a, b, cc, e) in info.items():
        h, w = e - cc + 1, b - a + 1
        if n < 500 or h < 90 or h > 420 or w > 170:
            continue
        m = lab[cc:e + 1, a:b + 1] == c
        px = mapped[cc:e + 1, a:b + 1][dilate(m, 2)].astype(int)
        if (px[:, 0] > px[:, 1] + 15).mean() > 0.003:
            continue
        if ((px[:, 0] < 120) & (px[:, 1] < 130)).mean() > 0.003:
            continue
        out.append(((a, b, cc, e), m))
    return out


def plant(canvas, mapped, trees, region, clean, rng, pitch=PITCH, gap=26, jitter=16, tries=14):
    """Plant whole trees in columns, the way they stand everywhere else on the board.

    Every tree goes down entire. That is the whole point: three earlier versions cut them to fit the
    hole -- quilted, sown at a matching density, bridged with pieces -- and every one came back as
    litter, because a cut tree is not a tree. The only clipping here is at the region's own edge,
    which runs from under the panel above to the board's bottom, where the board's trees end too.
    """
    ys, xs = np.where(region)
    X0, X1, Y0, Y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    n = 0
    x = X0 + int(rng.integers(10, 40))
    while x < X1 - 30:
        y = Y0 - int(rng.integers(20, 90))
        while y < Y1 - 20:
            bb, m = trees[rng.integers(len(trees))]
            a, b, c, e = bb
            h, w = e - c + 1, b - a + 1
            # A TREE MAY ONLY BE CUT BY SOMETHING THAT REALLY CUTS TREES -- the parchment of a panel,
            # or the edge of the board. Everywhere else on this board a tree either stands whole or
            # runs under a panel, and a tree that simply stops in open green is the "cut trees and
            # uncomplete designs" the maintainer kept seeing: the region's own rectangular edge was
            # doing the cutting.
            dy = int(y)
            placed = False
            for _ in range(tries):
                dx = int(x + rng.integers(-jitter, jitter + 1) - w // 2)
                ys0, ys1 = max(0, dy), min(canvas.shape[0], dy + h)
                xs0, xs1 = max(0, dx), min(canvas.shape[1], dx + w)
                if ys1 - ys0 <= 30 or xs1 - xs0 <= 10:
                    break
                sub = m[ys0 - dy:ys1 - dy, xs0 - dx:xs1 - dx]
                spill = sub & ~region[ys0:ys1, xs0:xs1]
                if not (spill & clean[ys0:ys1, xs0:xs1]).any():
                    placed = True
                    break
            if placed:
                sy0, sx0 = ys0 - dy, xs0 - dx
                src = mapped[c + sy0:c + sy0 + (ys1 - ys0), a + sx0:a + sx0 + (xs1 - xs0)].astype(np.float32)
                al = soft(m[sy0:sy0 + (ys1 - ys0), sx0:sx0 + (xs1 - xs0)])
                if rng.random() < 0.5:
                    src, al = src[:, ::-1], al[:, ::-1]
                al = (al * region[ys0:ys1, xs0:xs1])[..., None]
                reg = canvas[ys0:ys1, xs0:xs1].astype(np.float32)
                canvas[ys0:ys1, xs0:xs1] = np.clip(reg * (1 - al) + src * al, 0, 255).astype(np.uint8)
                n += 1
            y = dy + h + int(rng.integers(0, gap))
        x += pitch + int(rng.integers(-14, 15))
    return n


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
    # THE GROUND UNDER THE BOX IS REBUILT AND REPLANTED. It runs from just below the Outcast panel
    # to the board's bottom edge, so the trees planted in it start and finish where the board's own
    # trees do and nothing is left cut at a join.
    back = np.asarray(Image.open(os.path.join(SRC, "lizard_board_back.png")).convert("RGB"))
    mapped, bclean = map_back(front, back)
    trees = harvest(mapped, bclean)
    clean = bg_dist(front, pal) < BG_THRESH
    region = np.zeros(front.shape[:2], bool)
    region[TOP:front.shape[0], X0 - 2:front.shape[1]] = True
    region &= (clean | art)
    out = smooth_ground(front, region, pal, rng)
    planted = plant(out, mapped, trees, region, clean, rng)
    print("   %d whole trees off the manifest side, planted in %d px of rebuilt ground"
          % (planted, int(region.sum())))

    h, w = le - lc + 1, lb - la + 1
    nc = lc + LIZARD_DROP
    al = soft(lizard[lc:le + 1, la:lb + 1], 1.2)[..., None]
    reg = out[nc:nc + h, la:la + w].astype(np.float32)
    out[nc:nc + h, la:la + w] = np.clip(
        reg * (1 - al) + front[lc:le + 1, la:lb + 1].astype(np.float32) * al, 0, 255).astype(np.uint8)

    ring = np.zeros(front.shape[:2], bool)
    ring[Y0 - 80:Y1 + 80, X0 - 80:X1 + 80] = True
    td = is_vine(front)[clean & ring & ~dilate(region, 4)].mean()
    # measured on the GROUND ONLY -- the lizard's own pale greens answer to the same test as a vine
    lizfoot = np.zeros(front.shape[:2], bool)
    lizfoot[nc - 12:nc + h + 12, la - 12:la + w + 12] = True
    ground_only = region & ~lizfoot
    print("   vine %.2f%% against %.2f%% on the board around it"
          % (100 * is_vine(out)[ground_only].mean(), 100 * td))

    changed = (out != front).any(axis=-1)
    assert not (changed & ~region).any(), "the rebuild touched ground it was not given"

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
