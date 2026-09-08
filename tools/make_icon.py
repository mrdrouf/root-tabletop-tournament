#!/usr/bin/env python3
"""Render the mod's icon: the Root Ultimate Collection plaque, re-lettered, over the real setup board.

The maintainer's brief, 2026-09-07: "start from the art of the original root ultimate mod. replace the
writing of ultimate collection by tabletop tournament. replace the old version of the setup board on
the image by the new setup board. replace the background with just black instead."

THREE SOURCES, ALL REAL:
  * the plaque comes out of the original Workshop thumbnail at 1:1, so the illuminated R-O-O-T tiles
    (fox, rabbit, mouse, bird -- the four base factions, in their four colours) are the actual art and
    not a redrawing. Only the subtitle band is repainted;
  * the board is tools/preview_menu.py's render of THIS build's setup board -- the real button art at
    its real XmlUI coordinates -- so the icon cannot drift from what the mod looks like;
  * the type is New Rocker, the closest face in the repo to the original's subtitle (matched against
    every font in tools/preview/fonts: same weight, same angular wedge serifs).

Run from the repo root:  python3 tools/preview_menu.py && python3 tools/make_icon.py
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops, ImageEnhance

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIGINAL = os.path.expanduser("~/Library/Tabletop Simulator/Mods/Workshop/2516434159.png")
BOARD = os.path.join(ROOT, "tools", "menu_preview.png")
FONT = os.path.join(ROOT, "tools", "preview", "fonts", "newrocker.ttf")
OUTDIR = os.path.join(ROOT, "assets", "icon")

# THE PLAQUE, MEASURED OFF THE ORIGINAL, in its own 256px pixels so the crop is 1:1.
#
# THE CROP STOPS AT THE SALMON RULE. Taking the dark outer frame with it brought the leafy background
# along at the corners -- the frame is only two or three pixels and the foliage behind it is dark
# enough to pass for it. The frame is redrawn below instead, in its own sampled colour, which also
# makes it crisp at any size rather than an upscaled smudge.
PLAQUE = (22, 158, 233, 232)          # the field, salmon rule included: 211 x 74
FIELD_X = (3, 207)                    # cream inside that rule, relative to the crop
SUBTITLE_Y = (46, 70)                 # the band "Ultimate Collection" sits in
CLEAN_Y = (3, 7)                      # clean cream rows, used to mix the fill that replaces it
BASELINE = 69                         # where the subtitle sits, relative to the crop
CAP = 21                              # its cap height
FRAME = (41, 35, 13)                  # the plaque's own dark border, sampled
FRAME_PX = 3                          # its width, in the original's pixels

INK = (26, 20, 12)
SUBTITLE = "Tabletop Tournament"

# THE COMPOSITION. Board and plaque share one width so the two read as a single stack rather than two
# pictures that happen to be above each other.
# BIG. Next to the original the first attempt read timid: its plaque runs almost the full width of the
# frame and the board fills what is left, and a polite margin all round loses exactly the presence
# that makes the thing recognisable at the size a mod icon is actually seen at.
SIZE = 512
MARGIN = 24
GAP = 14
BOTTOM = 20


def field_fill(plaque):
    """The cream to paint over the old subtitle, mixed from the plaque's own clean rows."""
    px = plaque.load()
    xs = range(FIELD_X[0], FIELD_X[1] + 1)
    n, r, g, b = 0, 0, 0, 0
    for y in range(*CLEAN_Y):
        for x in xs:
            c = px[x, y]; r += c[0]; g += c[1]; b += c[2]; n += 1
    return (r // n, g // n, b // n)


def build_plaque(width):
    """The original plaque with its subtitle band repainted and its frame redrawn, scaled to `width`."""
    src = Image.open(ORIGINAL).convert("RGB")
    inner = src.crop(PLAQUE)
    # ERASE AT 1:1, LETTER AT FULL SIZE. The fill has to be upscaled with everything around it or the
    # patch reads as a flat rectangle in a field that has grain; the type does not, so it goes on after.
    fill = field_fill(inner)
    ImageDraw.Draw(inner).rectangle([FIELD_X[0], SUBTITLE_Y[0], FIELD_X[1], SUBTITLE_Y[1]], fill=fill)

    border = round(FRAME_PX * width / (inner.width + FRAME_PX * 2))
    iw = width - border * 2
    k = iw / inner.width
    inner = inner.resize((iw, round(inner.height * k)), Image.LANCZOS)
    # THE LETTERS GET THEIR BITE BACK. Any upscale softens ink edges, and the R-O-O-T tiles are the one
    # thing in the icon that has to stay crisp -- they are the logo. Applied before the type is drawn,
    # so the new line is not sharpened twice.
    inner = inner.filter(ImageFilter.UnsharpMask(radius=1.6, percent=115, threshold=2))
    # ...AND THEIR COLOUR. The four tiles are the four base factions in their four colours, and the
    # upscale flattens them towards the parchment; a touch of contrast and saturation puts them back
    # where the original has them. Measured against a side-by-side, not guessed.
    inner = ImageEnhance.Contrast(inner).enhance(1.10)
    inner = ImageEnhance.Color(inner).enhance(1.12)

    d = ImageDraw.Draw(inner)
    x0, x1 = round(FIELD_X[0] * k), round(FIELD_X[1] * k)
    # SIZED TO THE CAP HEIGHT THE ORIGINAL USED, then pulled in if the longer word runs wide, so the
    # new line sits in the band exactly as the old one did rather than merely fitting inside it.
    size = max(8, round(CAP * k * 1.35))
    while size > 8:
        f = ImageFont.truetype(FONT, size)
        b = f.getbbox("T")
        if (b[3] - b[1]) <= round(CAP * k) and d.textlength(SUBTITLE, font=f) <= (x1 - x0) * 0.94:
            break
        size -= 1
    d.text(((x0 + x1) / 2, round(BASELINE * k)), SUBTITLE, font=f, fill=INK, anchor="ms")

    plaque = Image.new("RGB", (inner.width + border * 2, inner.height + border * 2), FRAME)
    plaque.paste(inner, (border, border))
    return plaque


def lift(img, radius=10, spread=6, alpha=110):
    """A soft shadow and a warm hairline, so a picture does not bleed into the black ground."""
    pad = radius + spread + 4
    out = Image.new("RGBA", (img.width + pad * 2, img.height + pad * 2), (0, 0, 0, 0))
    sh = Image.new("RGBA", out.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).rectangle([pad - spread // 2, pad - spread // 2 + 3,
                                  pad + img.width + spread // 2, pad + img.height + spread // 2 + 3],
                                 fill=(0, 0, 0, alpha))
    out.alpha_composite(sh.filter(ImageFilter.GaussianBlur(radius)))
    out.paste(img.convert("RGB"), (pad, pad))
    ImageDraw.Draw(out).rectangle([pad - 1, pad - 1, pad + img.width, pad + img.height],
                                  outline=(150, 122, 82, 255), width=1)
    return out, pad


def content_box(img):
    """Trim the empty table around the board render, so the board itself fills its share of the icon."""
    px = img.convert("RGB").load()
    ground = px[2, 2]
    def blank(line):
        return all(all(abs(px[x, y][i] - ground[i]) < 14 for i in range(3)) for x, y in line)
    top, bot = 0, img.height - 1
    while top < bot and blank([(x, top) for x in range(0, img.width, 5)]):
        top += 1
    while bot > top and blank([(x, bot) for x in range(0, img.width, 5)]):
        bot -= 1
    left, right = 0, img.width - 1
    while left < right and blank([(left, y) for y in range(top, bot, 5)]):
        left += 1
    while right > left and blank([(right, y) for y in range(top, bot, 5)]):
        right -= 1
    pad = 5
    return (max(0, left - pad), max(0, top - pad),
            min(img.width, right + pad + 1), min(img.height, bot + pad + 1))


def main():
    for p in (ORIGINAL, BOARD, FONT):
        if not os.path.exists(p):
            sys.exit("missing source: %s\n(run tools/preview_menu.py first for the board render)" % p)
    os.makedirs(OUTDIR, exist_ok=True)

    width = SIZE - MARGIN * 2
    plaque = build_plaque(width)

    board = Image.open(BOARD).convert("RGB")
    board = board.crop(content_box(board))
    board = board.resize((width, round(board.height * width / board.width)), Image.LANCZOS)

    canvas = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
    p_img, p_pad = lift(plaque, radius=12, spread=8, alpha=130)
    b_img, b_pad = lift(board, radius=14, spread=10, alpha=140)

    plaque_top = SIZE - BOTTOM - plaque.height
    board_h = plaque_top - GAP - MARGIN // 2
    if board.height > board_h:                     # keep the board inside its share, width follows
        board = board.resize((round(board.width * board_h / board.height), board_h), Image.LANCZOS)
        b_img, b_pad = lift(board, radius=14, spread=10, alpha=140)
    board_top = plaque_top - GAP - board.height

    canvas.paste(b_img, ((SIZE - b_img.width) // 2, board_top - b_pad), b_img)
    canvas.paste(p_img, ((SIZE - p_img.width) // 2, plaque_top - p_pad), p_img)

    big = os.path.join(OUTDIR, "mod_icon_512.png")
    small = os.path.join(OUTDIR, "mod_icon_256.png")
    canvas.save(big)
    canvas.resize((256, 256), Image.LANCZOS).save(small)
    print("wrote %s and %s" % (big, small))


if __name__ == "__main__":
    main()
