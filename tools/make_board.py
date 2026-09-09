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
PITCH = 95                     # column spacing that matches the board's own scatter of trees
TOP = 686                       # the ground starts just under the Outcast panel

# GROWING THE OUTCAST PANEL. Maintainer: "increase the size of the parchment box with the decals so
# you create space to put the numbers below the boxes with the outcase. make sure you do it right and
# respect the art." The three printed slots end at y 664 and the panel ends at 682 -- eighteen rows,
# nowhere near enough for a numeral -- which is why the Lost Souls counts had no home and were
# printing over the suit icons.
PANEL_X = (1218, 1646)          # the panel plus its inked border, with a margin
PANEL_STRIP = (650, 689)        # the torn bottom edge: the left corner's zigzag flourish, the ink
                                # line, and a couple of rows past it. Moved down whole rather than
                                # redrawn -- it is hand-drawn and has a notch in the middle.
PANEL_STRIP_INNER = 666         # ...but the INTERIOR of that strip starts lower. The flourish sits
                                # at rows 656-668 and the three printed slots end at 664, so one
                                # strip top cannot serve both: taking the interior from 650 carried
                                # the bottom bar of all three thorn frames down the panel with it.
PANEL_GROW = 80                 # rows added; puts the panel's floor at 762, ~90 clear below the slots
PARCH_ROWS = ((443, 457), (501, 512), (666, 674), (370, 377))   # clean parchment, no text or slots
BORDER_ROWS = (590, 654)        # where the side borders are a plain line, above the flourish
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
    # OVERLAPPING TILES, CROSS-FADED. Butted together they show: neighbouring patches carry
    # different grain even after each is zero-meaned, and the join draws a faint 48px lattice over
    # the whole repair -- invisible at board scale, plain the moment you zoom in. Half-overlapped
    # and weighted by a raised cosine, the lattice has nowhere to form.
    win1 = np.hanning(G + 2)[1:-1]
    wsep = np.outer(win1, win1)[..., None] + 1e-6
    acc = np.zeros_like(resid)
    wsum = np.zeros(resid.shape[:2], np.float32)[..., None]
    for yy in range(Y0 - G, Y1 + G, G // 2):
        for xx in range(X0 - G, X1 + G, G // 2):
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
            acc[y2:y2 + G, x2:x2 + G] += t * wsep
            wsum[y2:y2 + G, x2:x2 + G] += wsep
    tiled = acc / np.maximum(wsum, 1e-6)

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
    """Trees off the other face -- and the test for a usable one is not "is it a whole component".

    Maintainer: "the mistake you do is that you have put trees that are cut on the top because they
    appear on the carboard at the top so they are cropped by design but you think it s a full tree
    while its actually a cropped one."

    Exactly right, and it is why every earlier library was poison: a tree clipped by the board's edge
    or running under a panel is still ONE connected component, so it passes every test for
    completeness while being a cut tree. There is in fact no uncropped tree anywhere on either face --
    the pattern fills the board, so every instance runs off something.

    What decides a tree here is its SIDES. Those must stand clear in bare background over its whole
    height, because that is the edge a planted tree shows. Its top and bottom may be cropped; the
    planting is what has to put those cuts somewhere a cut belongs.
    """
    lab, info = components(erode(dilate(is_vine(mapped) & bclean, 2), 1))
    H, W = bclean.shape
    out = []
    for c, (n, a, b, cc, e) in info.items():
        h, w = e - cc + 1, b - a + 1
        if n < 300 or h < 60 or h > 460 or w > 200:
            continue
        if a - 10 < 0 or b + 11 > W:
            continue
        m = lab[cc:e + 1, a:b + 1] == c
        if not bclean[cc:e + 1, a - 9:a].all() or not bclean[cc:e + 1, b + 1:b + 10].all():
            continue                                   # a neighbour or a panel edge is touching it
        px = mapped[cc:e + 1, a:b + 1][dilate(m, 2)].astype(int)
        if (px[:, 0] > px[:, 1] + 15).mean() > 0.003:
            continue
        if ((px[:, 0] < 120) & (px[:, 1] < 130)).mean() > 0.003:
            continue
        tip = cc - 14 >= 0 and bclean[cc - 14:cc, max(0, a - 6):b + 7].all()
        out.append(((a, b, cc, e), m, tip))
    return out


def stem_x(m):
    """Where the stem runs inside a tree -- its densest column."""
    return int(np.argmax(m.sum(axis=0)))


def plant(canvas, mapped, trees, region, clean, rng, pitch=PITCH, jitter=14, overlap=34, tries=16):
    """Grow a stem down each column, tree on tree, with their stems lined up.

    In a tall stretch of open board the pattern is not a scatter of little trees -- look at either
    margin -- it is long stems running the whole height, branch pairs all the way up, cropped only
    where the board itself ends. So that is what gets built: trees stacked with their stems aligned
    and overlapped, which puts every join inside a continuous line and leaves only two cut ends per
    column, one under the panel above and one off the bottom edge of the board.

    A tree with a tapering tip may finish a column in the open; one cropped at the top may not, so it
    is only used where its top will be covered.
    """
    ys, xs = np.where(region)
    X0, X1, Y0, Y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    tips = [t for t in trees if t[2]] or trees
    n = 0
    x = X0 + int(rng.integers(12, 44))
    while x < X1 - 24:
        y = Y0 - int(rng.integers(10, 60))
        first = True
        while y < Y1:
            pool = trees if first else (tips if rng.random() < 0.45 else trees)
            placed = False
            for _ in range(tries):
                bb, m, tip = pool[rng.integers(len(pool))]
                a, b, c, e = bb
                h, w = e - c + 1, b - a + 1
                flip = rng.random() < 0.5
                sx = (w - 1 - stem_x(m)) if flip else stem_x(m)
                dx = int(x + rng.integers(-jitter, jitter + 1) - sx)
                dy = int(y)
                ys0, ys1 = max(0, dy), min(canvas.shape[0], dy + h)
                xs0, xs1 = max(0, dx), min(canvas.shape[1], dx + w)
                if ys1 - ys0 <= 24 or xs1 - xs0 <= 8:
                    break
                sub = m[ys0 - dy:ys1 - dy, xs0 - dx:xs1 - dx]
                if flip:
                    sub = sub[:, ::-1]
                spill = sub & ~region[ys0:ys1, xs0:xs1]
                if (spill & clean[ys0:ys1, xs0:xs1]).any():
                    continue                          # would be cut in open green
                src = mapped[c + (ys0 - dy):c + (ys1 - dy), a + (xs0 - dx):a + (xs1 - dx)].astype(np.float32)
                al = soft(m[ys0 - dy:ys1 - dy, xs0 - dx:xs1 - dx])
                if flip:
                    src, al = src[:, ::-1], al[:, ::-1]
                al = (al * region[ys0:ys1, xs0:xs1])[..., None]
                reg = canvas[ys0:ys1, xs0:xs1].astype(np.float32)
                canvas[ys0:ys1, xs0:xs1] = np.clip(reg * (1 - al) + src * al, 0, 255).astype(np.uint8)
                n += 1
                placed = True
                break
            if not placed:
                break
            y = dy + h - int(rng.integers(overlap // 2, overlap))
            first = False
        x += pitch + int(rng.integers(-12, 13))
    return n


def grow_panel(front, rng):
    """Make the Outcast panel taller, by moving its bottom edge down and extending its sides.

    The edge is not redrawn. It is lifted whole -- flourish, notch, ink and all -- and set down
    lower, and the band it vacates is filled with the panel's own plain side border and its own
    clean parchment. So every stroke in the result is a stroke the artist drew, in the hand they
    drew it; the panel is simply longer.
    """
    x0, x1 = PANEL_X
    a, b = PANEL_STRIP
    n = PANEL_GROW
    ai = PANEL_STRIP_INNER
    out = front.copy()
    out[a + n:b + n, x0:1246] = front[a:b, x0:1246]          # left border, with its flourish
    out[a + n:b + n, 1618:x1] = front[a:b, 1618:x1]          # right border
    out[ai + n:b + n, 1246:1618] = front[ai:b, 1246:1618]    # interior, from below the slots
    par = np.concatenate([np.arange(p, q + 1) for p, q in PARCH_ROWS])
    bor = np.arange(*BORDER_ROWS)
    for i, y in enumerate(range(a, a + n)):
        yb = bor[i % len(bor)]
        out[y, x0:1246] = front[yb, x0:1246]
        out[y, 1618:x1] = front[yb, 1618:x1]
    for i, y in enumerate(range(ai, ai + n)):
        out[y, 1246:1618] = front[par[rng.integers(len(par))], 1246:1618]
    return out


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
    # LEFT TO THE PANEL'S OWN INK, not to a line two pixels off the box. The green runs on past the
    # box to x 1211-1221 where the Gardens panel's border stops it, so a region starting at 1223 cut
    # through open ground: its edge could not be planted across without cutting a tree, which left a
    # bare gutter along it -- the seam that survived. Masking by (clean | art) means the boundary
    # becomes the panel's ink wherever the panel is there, which is an edge a tree may sit against.
    region[TOP:front.shape[0], 1150:front.shape[1]] = True
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

    # THE REFERENCE IS THE BOARD'S OWN MARGINS, not a ring round the region. Once the region grew to
    # the board's edges the ring was reduced to slivers between panels, which are vine-dense, and it
    # read 12.6% where the open board reads 9. Margins are big, open, and never move.
    ref = np.zeros(front.shape[:2], bool)
    ref[300:1240, 8:52] = True          # left margin
    ref[300:1240, 1656:1688] = True     # right margin
    ref[1274:1308, 60:1620] = True      # bottom margin
    td = is_vine(front)[clean & ref].mean()
    # measured on the GROUND ONLY -- the lizard's own pale greens answer to the same test as a vine
    lizfoot = np.zeros(front.shape[:2], bool)
    lizfoot[nc - 12:nc + h + 12, la - 12:la + w + 12] = True
    ground_only = region & ~lizfoot
    print("   vine %.2f%% against %.2f%% on the board around it"
          % (100 * is_vine(out)[ground_only].mean(), 100 * td))

    changed = (out != front).any(axis=-1)
    assert not (changed & ~region).any(), "the rebuild touched ground it was not given"

    # ...and finally the panel grows downward over the ground just laid, making room for the counts
    before = out.copy()
    out = grow_panel(out, rng)
    ch = (out != before).any(axis=-1)
    ys2, xs2 = np.where(ch)
    assert ys2.min() >= PANEL_STRIP[0] and ys2.max() <= PANEL_STRIP[1] + PANEL_GROW, \
        "growing the panel touched rows outside its own strip"
    assert xs2.min() >= PANEL_X[0] and xs2.max() < PANEL_X[1], \
        "growing the panel touched columns outside the panel"
    print("   Outcast panel grown %d rows; its floor is now y %d" % (PANEL_GROW, 682 + PANEL_GROW))

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
