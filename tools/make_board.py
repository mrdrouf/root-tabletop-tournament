#!/usr/bin/env python3
"""Take the Lost Souls box off the Lizard Cult board, keep the lizard, and put the ground back.

Maintainer, 2026-09-08: "remove the lost souls art on the faction board for the lost soul cards
since they all go on the lizard wizard make sure its top notch craft and impossible to see something
has been removed", and then, on seeing the first attempt: "good but we can see your fixes. you could
just copy paste some of the motifs on the rest of the board. you also can keep the lizard he looks
nice and can stay. just put him a little bit below".

So what comes off is the white box, its title and its subtitle -- the invitation to pile cards on a
space this mod never uses, because the Lizard Wizard is the tracker and every spent card goes there.
The lizard himself stays, moved down into the space the box used to take.

    python3 tools/make_board.py

Writes assets/labels/lizard_board_v<N>_<md5>.png and prints the URL for gen/src/content.lua.

HOW THE GROUND IS REBUILT, and why it is done this way.

The box sits on the board's green vine background, so removing it means putting that background back.
The first version tried to SYNTHESISE the vine -- quilting strips of it out of the board, and out of
the manifest side of the board, matched on tone and on vine density. It was close and it was still
visible, because a vine is a drawing, not a texture: cut it into blocks and the stems come back as
loose leaf tips, and every block carries its source's tone, which redraws the shape you removed.

The maintainer's suggestion is better and is what this does. Ground and vine are separated:

  THE GROUND is flat colour and grain, with no structure to reproduce. Its colour is interpolated
  across the panel from the background around it, which needs no source material at all; its grain
  is the high-frequency residual of clean patches, tiled -- invisible because grain is zero-mean and
  has no large-scale shape. Nothing is quilted, so there are no blocks to see.

  THE VINES go back on as WHOLE MOTIFS lifted from elsewhere on the board -- complete stems with
  their leaves, never cut -- sown in columns at the pitch that reproduces the surrounding density.

The whole panel rectangle is rebuilt, not just the box's own pixels: patching around the surviving
background leaves a seam exactly where the border was, and that seam is the one thing guaranteed to
read as a repair.
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
PITCH = 122                     # column spacing that reproduces the surrounding vine density
GAP = 85
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
    px = np.concatenate([img[a:b, c:d].reshape(-1, 3) for a, b, c, d in regions])
    cols, cnt = np.unique(px, axis=0, return_counts=True)
    return cols[cnt >= len(px) * share]


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
    ground = clean & ~dilate(is_vine(front), 6) & ~dilate(need, 10)
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
    fy = np.clip((np.arange(H) - gy[0]) / step, 0, len(gy) - 1)
    fx = np.clip((np.arange(W) - gx[0]) / step, 0, len(gx) - 1)
    base = np.stack([np.asarray(Image.fromarray(F[..., c], "F").resize(
        (W, H), Image.BILINEAR, box=(fx[0], fy[0], fx[-1], fy[-1]))) for c in range(3)], axis=2)

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
            if rng.random() < 0.5:
                t = t[:, ::-1]
            if rng.random() < 0.5:
                t = t[::-1, :]
            tiled[y2:y2 + G, x2:x2 + G] = t

    out = front.copy()
    out[need] = np.clip(base + tiled, 0, 255).astype(np.uint8)[need]
    return out


def motif_library(front, pal):
    """Whole vines, cut from the board itself, never a fragment of one."""
    clean = bg_dist(front, pal) < BG_THRESH
    lab, info = components(erode(dilate(is_vine(front) & clean, 2), 1))
    out = []
    for c, (n, a, b, cc, e) in info.items():
        if n < 400 or (e - cc) < 90 or (b - a) > 150 or (b - a) * (e - cc) > 90000:
            continue
        out.append(((a, b, cc, e), lab[cc:e + 1, a:b + 1] == c))
    return out


def clean_motifs(front, motifs, max_foreign=0.01):
    """Keep only motifs that are pure vine.

    Some components pick up a neighbour's ink -- a berry off the header band, a fleck of red -- and
    sown into open ground those read as specks of a different drawing. The vine is yellow-green, so
    green at least matches red in nearly all of its pixels; the foreign ink is what does not.
    """
    out = []
    for bb, m in motifs:
        a, b, c, e = bb
        px = front[c:e + 1, a:b + 1][m].astype(int)
        if (px[:, 0] > px[:, 1] + 15).mean() <= max_foreign:
            out.append((bb, m))
    return out


def sow(canvas, front, motifs, panel, rng, pitch=PITCH, jitter=13, gap=GAP):
    """Sow whole motifs in columns, the way the board's own vines run.

    Dropping each one wherever the ground is emptiest sounds right and clumps -- the first few land
    together and the rest chase the hole they leave. The printed pattern is columns of stems about a
    pitch apart running the full height, so that is what gets sown: jittered, mirrored at random.
    They are sown across the whole panel including where the lizard will stand, because he is
    composited afterwards and the board's own vines run behind him too.
    """
    X0, X1, Y0, Y1 = panel
    n = 0
    x = X0 + int(rng.integers(6, 26))
    while x < X1 - 20:
        y = Y0 - int(rng.integers(0, 70))
        while y < Y1 - 10:
            bb, m = motifs[rng.integers(len(motifs))]
            a, b, c, e = bb
            h, w = e - c + 1, b - a + 1
            dx = int(np.clip(x + rng.integers(-jitter, jitter + 1), X0 - w // 3, X1 - 1))
            ys0, ys1 = max(Y0, y), min(Y1, y + h)
            xs0, xs1 = max(X0, dx), min(X1, dx + w)
            if ys1 - ys0 > 24 and xs1 - xs0 > 10:
                sy0, sx0 = ys0 - y, xs0 - dx
                src = front[c + sy0:c + sy0 + (ys1 - ys0), a + sx0:a + sx0 + (xs1 - xs0)].astype(np.float32)
                al = soft(m[sy0:sy0 + (ys1 - ys0), sx0:sx0 + (xs1 - xs0)])[..., None]
                if rng.random() < 0.5:
                    src, al = src[:, ::-1], al[:, ::-1]
                reg = canvas[ys0:ys1, xs0:xs1].astype(np.float32)
                canvas[ys0:ys1, xs0:xs1] = np.clip(reg * (1 - al) + src * al, 0, 255).astype(np.uint8)
                n += 1
            y = y + h + int(rng.integers(-gap // 2, gap))
        x += pitch + int(rng.integers(-8, 9))
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

    out = smooth_ground(front, rect, pal, rng)
    motifs = clean_motifs(front, motif_library(front, pal))
    n = sow(out, front, motifs, (X0, X1, Y0, Y1), rng)

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
    print("   %d motifs sown; vine density %.2f%% against %.2f%% around it"
          % (n, 100 * is_vine(out)[rect].mean(), 100 * td))

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
