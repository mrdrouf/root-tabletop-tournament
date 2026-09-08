#!/usr/bin/env python3
"""Render the credits page.

There was no generator for this: the panel was composed by hand once and then drifted. Everything on
it now comes from one layout table, so a name or a thumbnail can be added without anything else
moving.

WHAT WAS WRONG WITH THE OLD ONE, and what each fix here is answering (maintainer, 2026-09-07: "do a
torough design study of the credit page to make it look nicer; remove the on discord thingy to save
space, space out the images horizontally more so they don t crop on each others etc"):

  * captions ran into each other. "The Bat Bungler | Koffin Keeper | Lizard Wizard" touched, and
    "Faction Selector" and "Mini-Mood Manager" overlapped outright, because each caption was drawn
    under its thumbnail at a fixed size with no idea how wide the next one was. Every item now owns a
    COLUMN of fixed width and its caption is shrunk to fit that column, so two captions cannot meet;
  * "on discord" appeared three times and the Ehss/slugfacekillah credit appeared twice, once in the
    header and again as a row label. Both are gone;
  * the four groups were stacked one per row, each with a left-hand label, so a group of one item left
    four fifths of the row empty and the page ran out of vertical space while wasting horizontal. The
    three small groups now sit SIDE BY SIDE in one band, which is what buys the room to make
    everything else bigger;
  * the left labels were three different sizes and weights. Group headings are one style, centred over
    the items they credit.

The thumbnails are cropped out of the previous panel -- they exist nowhere else in the repo -- and the
parchment behind them is rebuilt by inpainting the old page, so the ground and its vignette are the
real ones rather than a flat fill.

Run from the repo root:  python3 tools/make_credits.py
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "labels", "credits_panel_v7_883e709b.png")
OUT = os.path.join(ROOT, "assets", "labels", "credits_panel_v9.png")
LUM = "/System/Library/Fonts/Supplemental/Luminari.ttf"

INK = (26, 20, 12)
SOFT = (92, 70, 44)          # the group headings, a step back from the titles
# THE PAGE IS TALLER THAN THE ART IT CAME FROM.
#
# The back button sat at y -78 on the board, which is the SAME row as 5-Player Setup, 5-Player Draft,
# 5-Players Marsh and the Credits button itself -- and the page only reached y -84, so the button hung
# off its bottom edge and landed among them. Maintainer, 2026-09-07: "the back button clashes with
# things written put it lower."
#
# There is nowhere lower to put it while the page ends where it does: below that row the board has
# only about ten units before it runs out. So the page grows downwards instead, from 152 units to 168,
# far enough to cover the row -- the board's buttons are behind it -- and the last 240 rows of the art
# are left empty for the button to sit on.
HEIGHT = 1708                    # 2400 x 1708 is 236 x 168 on the board
BUTTON_STRIP = 380               # rows kept clear at the foot of the page
FRAME = (100, 130, 2300, HEIGHT - BUTTON_STRIP)

# Where each thumbnail sits in the OLD page. Found by connected components on "not parchment", then
# widened by PAD so no crop clips its own art; the Lizard Wizard is two cards and reads as two blobs.
PAD = 6
THUMBS = {
    "The Bat Bungler":    (908, 574, 1008, 705),
    "Koffin Keeper":      (1169, 574, 1272, 705),
    "Lizard Wizard":      (1400, 574, 1564, 705),
    "Mob Lobber":         (1682, 574, 1806, 705),
    "Mole Monger":        (1924, 574, 2089, 705),
    "Faction Selector":   (877, 780, 1041, 909),
    "Mini-Mood Manager":  (1167, 780, 1277, 909),
    "Battle Mat":         (890, 982, 1027, 1113),
    "Ginso's Gizmo":      (906, 1186, 1010, 1317),
}

TITLE = "Root Tabletop Tournament"
SUBTITLE = "a revamp by MrDrouf & Claude"
BASED = ["based on Root - Ultimate Collection",
         "by Ehss #7883 and slugfacekillah #4920"]

# One band of five, then three small groups side by side. The second band is what stops a group of
# one item owning a whole row.
BAND_A = ("made by Nevakanezah",
          ["The Bat Bungler", "Koffin Keeper", "Lizard Wizard", "Mob Lobber", "Mole Monger"])
BAND_B = [("made by Ehss and slugfacekillah", ["Faction Selector", "Mini-Mood Manager"]),
          ("made by JustinInExile", ["Battle Mat"]),
          ("made by Ginso", ["Ginso's Gizmo"])]

THUMB_SCALE = 1.30          # the old art at 1:1 left the page half empty


def font(px):
    return ImageFont.truetype(LUM, px)


def fit(draw, text, px, width):
    """The largest size at or below `px` whose `text` fits `width`."""
    while px > 8 and draw.textlength(text, font=font(px)) > width:
        px -= 1
    return font(px)


# A patch of the old page that holds nothing but parchment -- the largest clean rectangle on it,
# found by scanning for a region whose every pixel is within a hair of the ground colour.
CLEAN_PATCH = (1360, 750, 1960, 1050)


def clean_plate(src):
    """The printed border of the old page, stretched to the new height, with fresh parchment inside.

    Inpainting the old page was tried first and is the wrong tool here: masking the ink and filling
    from its surroundings works for a strip a few rows tall (the Root plaque's subtitle band) but not
    for a page that is four fifths type and artwork -- there is not enough clean ground left to fill
    FROM, and the titles came back as ghosts behind the new ones.

    Tiling real parchment cannot ghost. The patch is mirrored at each step so its edges always meet
    their own reflection and no seam can appear, and a light blur takes the last of the repetition out
    of the grain.

    The border is nine-sliced vertically -- top kept, bottom kept, middle stretched. Its long edges are
    near-vertical torn lines, so stretching the middle of them is invisible; stretching the CORNERS
    would not be, which is why they are carried across untouched.
    """
    TOP, BOT = 760, 300
    frame = Image.new("RGB", (src.width, HEIGHT))
    frame.paste(src.crop((0, 0, src.width, TOP)), (0, 0))
    frame.paste(src.crop((0, src.height - BOT, src.width, src.height)), (0, HEIGHT - BOT))
    middle = src.crop((0, TOP, src.width, src.height - BOT))
    frame.paste(middle.resize((src.width, HEIGHT - BOT - TOP), Image.LANCZOS), (0, TOP))

    x0, y0, x1, y1 = 100, 130, 2300, HEIGHT - 130
    patch = src.crop(CLEAN_PATCH).convert("RGB")
    pw, ph = patch.size
    tile = Image.new("RGB", (pw * 2, ph * 2))
    tile.paste(patch, (0, 0))
    tile.paste(patch.transpose(Image.FLIP_LEFT_RIGHT), (pw, 0))
    tile.paste(patch.transpose(Image.FLIP_TOP_BOTTOM), (0, ph))
    tile.paste(patch.transpose(Image.ROTATE_180), (pw, ph))

    ground = Image.new("RGB", (x1 - x0, y1 - y0))
    for gy in range(0, ground.height, tile.height):
        for gx in range(0, ground.width, tile.width):
            ground.paste(tile, (gx, gy))
    ground = ground.filter(ImageFilter.GaussianBlur(1.1))
    frame.paste(ground, (x0, y0))
    return frame


def thumbnails(src):
    out = {}
    for name, (a, b, c, d) in THUMBS.items():
        im = src.crop((a - PAD, b - PAD, c + PAD, d + PAD)).convert("RGB")
        w = round(im.width * THUMB_SCALE)
        h = round(im.height * THUMB_SCALE)
        out[name] = im.resize((w, h), Image.LANCZOS)
    return out


def paste_thumb(page, im, cx, bottom):
    """Drop a thumbnail centred on cx with its feet on `bottom`, blended into the parchment.

    The crop carries a rectangle of the old page's parchment with it. Both grounds are the same
    parchment, so a soft edge is all it takes for the join to disappear.
    """
    x, y = round(cx - im.width / 2), round(bottom - im.height)
    m = Image.new("L", im.size, 255)
    ImageDraw.Draw(m).rectangle([0, 0, im.width - 1, im.height - 1], outline=0, width=5)
    page.paste(im, (x, y), m.filter(ImageFilter.GaussianBlur(3)))


def main():
    if not os.path.exists(SRC):
        sys.exit("missing %s" % SRC)
    src = Image.open(SRC).convert("RGB")
    page = clean_plate(src)
    thumbs = thumbnails(src)
    d = ImageDraw.Draw(page)
    x0, y0, x1, y1 = FRAME
    W = x1 - x0
    mid = (x0 + x1) / 2

    # ---- title block -----------------------------------------------------------------------------
    y = y0 + 40
    f = fit(d, TITLE, 132, W * 0.82)
    d.text((mid, y), TITLE, font=f, fill=INK, anchor="ma"); y += f.size + 22
    f = fit(d, SUBTITLE, 74, W * 0.6)
    d.text((mid, y), SUBTITLE, font=f, fill=INK, anchor="ma"); y += f.size + 26
    for line in BASED:
        f = fit(d, line, 52, W * 0.66)
        d.text((mid, y), line, font=f, fill=SOFT, anchor="ma"); y += f.size + 10

    # a rule under the titles, inset from the border so it reads as a divider and not a second frame
    y += 34
    d.line([(x0 + 90, y), (x1 - 90, y)], fill=SOFT, width=3)

    # ---- the bands -------------------------------------------------------------------------------
    # Everything below is measured from the space that is left, so changing the title block or the
    # thumbnail scale re-flows the page instead of running off the bottom of it.
    HEAD, CAP = 54, 42
    rest = y1 - (y + 40)
    GAP = 78            # between the bands; the first version left 18 and the headings
                        # of the second band sat under the captions of the first
    band_a_h = (rest - GAP) * 0.50
    band_b_h = rest - GAP - band_a_h

    def band(items, top, height, left, width, heading):
        f = fit(d, heading, HEAD, width * 0.94)
        d.text((left + width / 2, top), heading, font=f, fill=SOFT, anchor="ma")
        cell = width / len(items)
        art_top = top + f.size + 20
        art_bottom = top + height - CAP - 16
        for i, name in enumerate(items):
            cx = left + cell * (i + 0.5)
            paste_thumb(page, thumbs[name], cx, art_bottom)
            cf = fit(d, name, CAP, cell * 0.88)      # its own column: two captions cannot meet
            d.text((cx, art_bottom + 14), name, font=cf, fill=INK, anchor="ma")

    band(BAND_A[1], y + 46, band_a_h, x0, W, BAND_A[0])

    # the three small groups share the second band, weighted by how many items each has
    b_top = y + 46 + band_a_h + GAP
    total = sum(len(items) for _, items in BAND_B)
    cursor = x0
    for heading, items in BAND_B:
        share = W * (len(items) + 0.9) / (total + 0.9 * len(BAND_B))
        band(items, b_top, band_b_h, cursor, share, heading)
        cursor += share

    page.save(OUT)
    print("wrote %s (%dx%d)" % (OUT, page.width, page.height))


if __name__ == "__main__":
    main()
