#!/usr/bin/env python3
"""Render the mod's icon: the Root plaque, re-lettered, over the real setup board, on black.

The maintainer's brief, 2026-09-07: "start from the art of the original root ultimate mod. replace the
writing of ultimate collection by tabletop tournament. replace the old version of the setup board on
the image by the new setup board. replace the background with just black instead."

BOTH SOURCES ARE REAL, AND BOTH ARE BIGGER THAN THE OUTPUT, which is the whole reason this looks like
artwork instead of a blow-up:

  * assets/src_art/root_plaque.png -- the Root sign at 2488px, so the illuminated R-O-O-T tiles (fox,
    rabbit, mouse, bird, in the four base faction colours) are DOWNscaled into the icon. The first
    version cropped them out of a 256px Workshop thumbnail and upscaled, and no amount of sharpening
    hides that;
  * assets/src_art/board_screenshot.png -- a real screenshot of the table. tools/preview_menu.py
    composites button art at its XmlUI coordinates, which is right for checking a layout and much too
    coarse for artwork. Maintainer: "here is a real screenshot of the board instead of your ugly made
    up thing."

The subtitle is replaced, not overpainted: its ink is masked and filled from the parchment around it,
so the corner flourishes and the salmon rule survive untouched -- and so do the R-O-O-T letterforms,
which a rectangular erase took the bottom serifs off. Maintainer: "preserve the Root sign you are
chopping it with your text below." The new line is set in Luminari, the font the mod itself uses, at
the cap height and on the baseline the old one had.

THIS IS NO LONGER THE MOD'S ICON. 2026-09-08: the icon became the four Eyrie leaders round a table,
and tools/make_logo.py builds it. What survives here, and what make_logo.py imports, is build_plaque()
-- the re-lettered Root sign both designs stand on, kept in one place so they cannot drift apart.
Running this script now writes assets/icon/old_board_icon.png, not mod_icon_*.png; it would otherwise
quietly undo the mod's art every time anyone ran it.

Run from the repo root:  python3 tools/make_icon.py
"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLAQUE_SRC = os.path.join(ROOT, "assets", "src_art", "root_plaque.png")
BOARD_SRC = os.path.join(ROOT, "assets", "src_art", "board_screenshot.png")
FONT = "/System/Library/Fonts/Supplemental/Luminari.ttf"
OUTDIR = os.path.join(ROOT, "assets", "icon")

# THE PLAQUE, MEASURED OFF ITS OWN PIXELS. The crop stops at the outside of the salmon rule: beyond it
# is the board's wood, which is uneven and reads as dirt against black. Maintainer: "you should
# probably clean up the background on the sides though for a clean one." The border below replaces it.
PLAQUE = (22, 21, 2466, 780)          # 2444 x 759
FIELD = (60, 2384)                    # cream between the rules, relative to the crop
# THE OLD LINE IS NOT ERASED, THE BAND IS REBUILT. Masking its ink left a ghost -- the maintainer,
# 2026-09-07: "the background of your text tabletop tournament is too different than the background of
# the root symbol" -- because the antialiased halo of a letter reaches almost to the parchment and no
# threshold catches all of it. So the whole band between the corner flourishes is replaced with real
# parchment, interpolated from the clean rows directly above and below it. That keeps the horizontal
# grain and the vignette exactly, and nothing survives to show through.
BAND = (590, 750)                     # the old subtitle, ascender to descender
ABOVE = (578, 589)                    # clean parchment under the letters, which end at 574
BELOW = (722, 745)                    # clean parchment over the bottom rule, which starts at 751
FLOUR = (130, 2320)                   # inside the corner flourishes: they reach 106 and 2338
# THE TYPE FILLS THE PLAQUE. Set to the old line's cap height it looked lost -- "A Game of Woodland
# Might and Right" is thirty-four characters and "Tabletop Tournament" is nineteen, so the same cap
# height leaves a third of the plaque empty. Maintainer: "the tabletop tournament text now is too
# small." It is sized to the width now and centred in the band instead.
# HEIGHT IS WHAT CAPS IT, NOT WIDTH. Nineteen characters of Luminari reach the width limit at about
# size 205, but the band between the logo and the rule stops them at 165 -- so sizing to the width
# alone silently leaves the line at two-thirds of the plaque. It takes every row the art leaves free
# (the letters end at 574, the rule starts at 751) and then TRACKS OUT to fill the width, which makes
# the line long without distorting a single glyph. Maintainer, 2026-09-07: "can you work on making
# tabletop tournament larger?"
TYPE_WIDTH = 0.90                     # of the cream field, reached with tracking
TYPE_BAND = (578, 747)                # every row between the logo and the bottom rule
FRAME = (46, 33, 20)                  # a clean dark edge in place of the board's wood
FRAME_PX = 14                         # its width, in the plaque's own pixels

INK = (24, 18, 11)
# THE MOD'S NAME, AS THE PLAQUE SPELLS IT. The sign's own R-O-O-T tiles are the first word, so the
# line under them carries the rest: "Root: Tournament Edition" reads off the finished plaque without
# the subtitle having to repeat "Root". Renamed 2026-09-12 at the maintainer's word -- "the title of
# the mod should be Root: Tournament Edition" -- from "Tabletop Tournament", which the comments above
# still quote because they record how the fitting was measured, and it was measured on that string.
# Eighteen characters against nineteen, so nothing about the fit changes.
SUBTITLE = "Tournament Edition"

# THE COMPOSITION. Next to the original the first attempt read timid: its plaque runs almost the full
# width of the frame, and a polite margin all round loses the presence that makes a mod icon legible
# at the size it is actually seen.
SIZE = 512
MARGIN = 24
GAP = 14
BOTTOM = 20


def rebuild_band(img):
    """Replace the old subtitle's band with parchment interpolated from the rows around it.

    Not a flat rectangle of cream: the field is not flat. It has a vignette that darkens towards the
    rule and a tone that drifts along its length, and a flat patch reads instantly as a patch. So the
    fill is a cross-fade between the clean strip above and the clean strip below.

    PER-COLUMN MEDIAN, NOT A STRETCH. Stretching those strips dragged whatever ink they still held --
    the tails of the R-O-O-T tiles -- down through the whole band as a row of specks. A median over
    each strip's rows throws a stray dark pixel away and keeps the tone, which is all that is wanted
    from it.
    """
    x0, x1 = FLOUR
    a = np.asarray(img).astype(float)
    top = np.median(a[ABOVE[0]:ABOVE[1], x0:x1], axis=0)      # one RGB per column
    bot = np.median(a[BELOW[0]:BELOW[1], x0:x1], axis=0)
    h = BAND[1] - BAND[0]
    t = np.linspace(0.0, 1.0, h)[:, None, None]
    fill = Image.fromarray((top[None] * (1 - t) + bot[None] * t).round().astype("uint8"))
    fill = fill.filter(ImageFilter.GaussianBlur(1.0))

    # FEATHER THE SIDES ONLY. Feathering all four edges let the top of the band show through at half
    # opacity -- and the top of the band is exactly where the old line's ascenders are, so they came
    # back as a row of specks above the new text. Top and bottom need no feather at all: the fill's
    # profiles are taken from the rows immediately beyond them, so it meets the parchment in its own
    # tone. Only the left and right run into the corner flourishes and have to fade.
    mask = Image.new("L", fill.size, 255)
    ramp = 14
    mpx = mask.load()
    for x in range(ramp):
        v = round(255 * x / ramp)
        for y in range(fill.height):
            mpx[x, y] = v
            mpx[fill.width - 1 - x, y] = v
    out = img.copy()
    out.paste(Image.composite(fill, img.crop((x0, BAND[0], x1, BAND[1])), mask), (x0, BAND[0]))
    return out


def draw_tracked(d, cx, baseline, text, font, fill, target):
    """Draw `text` centred on `cx`, letter-spaced so it spans `target` -- never stretched.

    Widening glyphs to fill a plaque is the obvious move and the wrong one: it makes a face that was
    drawn look like a face that was scaled. Tracking is what a sign painter would do, and it is what
    the Root plaque's own subtitle does.
    """
    natural = d.textlength(text, font=font)
    gaps = max(1, len(text) - 1)
    extra = max(0.0, (target - natural) / gaps)
    x = cx - (natural + extra * gaps) / 2
    for ch in text:
        d.text((x, baseline), ch, font=font, fill=fill, anchor="ls")
        x += d.textlength(ch, font=font) + extra


def taller(inner, extra, at=630, grain=34):
    """Splice `extra` rows of parchment into the plaque, so the subtitle can be set bigger.

    Tracking the line out to the width and giving it every row between the logo and the rule still
    caps it at the height of that band, and the band is only 169 rows. Past that the plaque itself
    has to grow. Maintainer, 2026-09-08: "make tabletop tournament size font much bigger but making
    the box I guess longer vertically."

    WHERE THE CUT GOES IS THE WHOLE TRICK. Row 630 is the one place a full-width slice of this plaque
    is nothing but border rule, parchment, border rule: the illuminated letters stop at 574, the
    bottom rule starts at 751, and the corner flourishes -- measurably -- begin at 658, so anything
    spliced below that would stretch a flourish into a smear. The inserted rows are the 34 above the
    cut, mirrored and stacked, which keeps the grain at its own scale instead of blurring it the way
    resizing a block would.
    """
    block = inner.crop((0, at - grain, inner.width, at))
    flip = block.transpose(Image.FLIP_TOP_BOTTOM)
    filler = Image.new("RGB", (inner.width, extra))
    y = 0
    while y < extra:
        filler.paste(flip if (y // grain) % 2 == 0 else block, (0, y))
        y += grain
    out = Image.new("RGB", (inner.width, inner.height + extra))
    out.paste(inner.crop((0, 0, inner.width, at)), (0, 0))
    out.paste(filler, (0, at))
    out.paste(inner.crop((0, at, inner.width, inner.height)), (0, at + extra))
    return out


LETTER_GAPS = (694, 1241, 1800)       # the clear columns between R-O, O-O and O-T


def wider(inner, extra, grain=12):
    """Splice `extra` columns of parchment into the plaque, so the subtitle can be set wider.

    Maintainer, 2026-09-09: "make 'Tabletop Tournament' 30% bigger by making the sign longer
    horizontally if need be." The line is width-bound -- it has been ever since the band was made
    taller -- so past this point the only way to enlarge it is to give it more room sideways.

    THE COLUMNS GO BETWEEN THE LETTERS, split evenly across the three gaps in R-O-O-T, which tracks
    the illuminated tiles apart the way a sign painter would rather than opening one ugly hole. The
    two remaining clear runs -- the margins at 21..48 and 2364..2420 -- are deliberately NOT used:
    they lie inside the corner flourishes, which reach 106 and 2338, so splicing there would stretch a
    flourish sideways. Leaving them alone also means the plaque's own left and right margins come out
    unchanged, so the block of letters stays as centred as it started.

    THE INSERTED COLUMN IS SYNTHESISED, NOT COPIED. Mirror-tiling the real columns beside the gap --
    the trick taller() uses on rows -- put a row of stray dots beside the R: the gaps are clear of the
    LETTERS, which is the band those positions were measured in, but they are not clear of the small
    decorative marks that sit below the letterforms, and tiling copied those sideways. Instead each
    gap contributes ONE column built from the per-row MEDIAN of the columns around it. A median over
    twenty-odd columns of mostly-parchment throws any decoration away and keeps the tone, so the top
    and bottom rules continue at their own colour, the vignette continues at its own, and nothing is
    duplicated. Replicating that single column is right for this art because the parchment's grain
    runs horizontally: every row keeps its own value.
    """
    if extra <= 0:
        return inner
    per = [extra // len(LETTER_GAPS)] * len(LETTER_GAPS)
    for i in range(extra - sum(per)):
        per[i] += 1

    out = inner
    shift = 0
    for gap, n in zip(LETTER_GAPS, per):
        at = gap + shift
        sample = np.asarray(out.crop((at - grain, 0, at + grain, out.height))).astype(float)
        col = np.median(sample, axis=1).round().astype("uint8")        # one RGB per row
        filler = Image.fromarray(np.repeat(col[:, None, :], n, axis=1))
        grown = Image.new("RGB", (out.width + n, out.height))
        grown.paste(out.crop((0, 0, at, out.height)), (0, 0))
        grown.paste(filler, (at, 0))
        grown.paste(out.crop((at, 0, out.width, out.height)), (at + n, 0))
        out = grown
        shift += n
    return out


def set_one_line_tall(inner, band, field, type_width, elong):
    """Set the subtitle on ONE line, ELONGATED, so it can grow without more characters per line.

    Maintainer, 2026-09-09: "no on 1 line. characters can be elongated a bit." That settles what
    nothing else could. The line is width-bound -- nineteen characters of Luminari fill the cream
    field at 219pt and no amount of extra height or extra sign length moves it -- so the only way to
    make it TALLER while keeping it one line is to stop insisting the glyphs keep their drawn
    proportions. Elongating them vertically buys the height directly: the width is unchanged, the
    height goes up by `elong`.

    This is a deliberate reversal of the rule in draw_tracked, and worth being clear about. That rule
    is about WIDENING -- stretching glyphs sideways to fill a plaque, which reads as a scaled face and
    is what tracking exists to avoid. Elongating is the other axis, it is a condensed face rather than
    a stretched one, and it is a normal thing for a sign painter to do when a line has to fill a deep
    band. It is done here on instruction, not by default.

    The type is rendered at elong x the size and then COMPRESSED horizontally back to the target
    width, rather than drawn small and stretched up: the glyphs are rasterised at the larger size, so
    the verticals keep their weight instead of being smeared.
    """
    room = band[1] - band[0]
    target = (field[1] - field[0]) * type_width

    probe = ImageDraw.Draw(Image.new("RGB", (8, 8)))
    size = int(room * 2 * elong)
    while size > 8:
        f = ImageFont.truetype(FONT, size)
        b = probe.textbbox((0, 0), SUBTITLE, font=f, anchor="lt")
        if probe.textlength(SUBTITLE, font=f) <= target * elong and (b[3] - b[1]) <= room * elong:
            break
        size -= 1

    f = ImageFont.truetype(FONT, size)
    b = probe.textbbox((0, 0), SUBTITLE, font=f, anchor="ls")
    ink_h = b[3] - b[1]
    wide = round(target * elong)
    layer = Image.new("RGBA", (wide + size, ink_h + size), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    draw_tracked(ld, layer.width / 2, size / 2 - b[1], SUBTITLE, f, INK + (255,), target * elong)
    layer = layer.crop(layer.getbbox())
    layer = layer.resize((max(1, round(layer.width / elong)), layer.height), Image.LANCZOS)

    inner.paste(layer, (round((field[0] + field[1]) / 2 - layer.width / 2),
                        round((band[0] + band[1]) / 2 - layer.height / 2)), layer)
    return size


def frame_and_scale(inner, width):
    """Shrink the plaque to `width` and give it the clean dark edge that replaces the board's wood."""
    border = max(1, round(FRAME_PX * width / (inner.width + FRAME_PX * 2)))
    iw = width - border * 2
    inner = inner.resize((iw, round(inner.height * iw / inner.width)), Image.LANCZOS)
    plaque = Image.new("RGB", (inner.width + border * 2, inner.height + border * 2), FRAME)
    plaque.paste(inner, (border, border))
    return plaque


SUBTITLE_LINES = ("Tournament", "Edition")
TWO_LINE_TRACK = 1.04      # a letterspace, not a justification: see set_two_line


def set_two_line(d, band, field, type_width, lead=0.12):
    """Size and place the subtitle on TWO lines, both at one point size and one width.

    ONE LINE CANNOT BE MADE BIGGER, whatever is done to the sign, and that is worth stating plainly
    because two obvious levers were tried and neither works. The line already spans the whole cream
    field, so its size in the finished picture is (field / plaque) * output width. Splice the plaque
    WIDER and the field and the plaque grow together, which cancels -- 650 columns moved it 2%. Splice
    it TALLER and nothing happens at all: the binding constraint is width, so extra rows are simply
    empty parchment. The only way past the ceiling is fewer characters per line: nineteen of them fill
    the field at 219pt, but "Tournament" alone fills it at 383pt, so two lines are worth +147% before
    any compromise. Maintainer, 2026-09-09: "Tabletop Tournament still too small. increase the height
    of the root sign if needs be" -- which is precisely the room two lines need.

    Both lines take the SAME point size and only a HAIR of tracking. Justifying them both to the
    field's full width -- the way the single line is justified -- stretched "Tabletop" into
    "T a b l e t o p": eight characters cannot reach a width nineteen were sized for without absurd
    gaps. So the size is chosen so the LONGER line fills the field naturally, and each line is then
    tracked only 4% past its own width, which is a letterspace rather than a justification.
    """
    room = band[1] - band[0]
    target = (field[1] - field[0]) * type_width
    lead_of = lambda sz: sz * lead

    size = int(room)
    while size > 8:
        f = ImageFont.truetype(FONT, size)
        inks = [d.textbbox((0, 0), t, font=f, anchor="ls") for t in SUBTITLE_LINES]
        widest = max(d.textlength(t, font=f) for t in SUBTITLE_LINES) * TWO_LINE_TRACK
        stack = sum(b[3] - b[1] for b in inks) + lead_of(size)
        if widest <= target and stack <= room:
            break
        size -= 1

    f = ImageFont.truetype(FONT, size)
    inks = [d.textbbox((0, 0), t, font=f, anchor="ls") for t in SUBTITLE_LINES]
    heights = [b[3] - b[1] for b in inks]
    stack = sum(heights) + lead_of(size)
    y = (band[0] + band[1]) / 2 - stack / 2          # ink top of the first line
    cx = (field[0] + field[1]) / 2
    for t, b, h in zip(SUBTITLE_LINES, inks, heights):
        baseline = y - b[1]                          # b[1] is the ink top, relative to the baseline
        own = d.textlength(t, font=f) * TWO_LINE_TRACK
        draw_tracked(d, cx, baseline, t, f, INK, min(own, target))
        y += h + lead_of(size)
    return size


def build_plaque(width, extra_band=0, extra_width=0, type_width=TYPE_WIDTH, two_line=False,
                 elongate=1.0):
    """The plaque with its subtitle replaced and its wood surround swapped for a clean edge.

    `extra_band` grows the parchment under the logo by that many of the plaque's own rows and gives
    every one of them to the type; `extra_width` splices that many columns between the letters and
    gives the type the width as well. Both default to 0, which leaves the plaque exactly as it was.
    """
    src = Image.open(PLAQUE_SRC).convert("RGB")
    inner = src.crop(PLAQUE)
    inner = rebuild_band(inner)
    if extra_band:
        inner = taller(inner, extra_band)
    if extra_width:
        inner = wider(inner, extra_width)

    # SET THE TYPE AT FULL SIZE, THEN SHRINK EVERYTHING TOGETHER. Drawing after the downscale would
    # give the one new element a different kind of edge from the art around it.
    d = ImageDraw.Draw(inner)
    band = (TYPE_BAND[0], TYPE_BAND[1] + extra_band)
    room = band[1] - band[0]
    # the cream field grew by exactly the columns spliced in, so the type's room grows with it
    field = (FIELD[0], FIELD[1] + extra_width)
    target = (field[1] - field[0]) * type_width
    if elongate and elongate != 1.0:
        set_one_line_tall(inner, band, field, type_width, elongate)
        return frame_and_scale(inner, width)
    if two_line:
        set_two_line(d, band, field, type_width)
        return frame_and_scale(inner, width)
    size = room * 2
    while size > 8:
        f = ImageFont.truetype(FONT, size)
        b = d.textbbox((0, 0), SUBTITLE, font=f, anchor="lt")
        if (b[3] - b[1]) <= room and d.textlength(SUBTITLE, font=f) <= target:
            break
        size -= 1
    # centred on its own ink, not on the font's line box -- the descender of the p is the only one in
    # the string, so a line-box centring would push the whole thing visibly high
    b = d.textbbox((0, 0), SUBTITLE, font=f, anchor="ls")
    baseline = (band[0] + band[1]) / 2 - (b[1] + b[3]) / 2
    draw_tracked(d, (field[0] + field[1]) / 2, baseline, SUBTITLE, f, INK, target)

    return frame_and_scale(inner, width)


def content_box(img, floor=170):
    """Trim the dark surround a screen capture leaves around the board, keeping the board's own frame."""
    px = img.convert("RGB").load()
    def lit(line):
        return sum(1 for x, y in line if sum(px[x, y]) > floor) > len(line) * 0.6
    top, bot = 0, img.height - 1
    while top < bot and not lit([(x, top) for x in range(0, img.width, 5)]):
        top += 1
    while bot > top and not lit([(x, bot) for x in range(0, img.width, 5)]):
        bot -= 1
    left, right = 0, img.width - 1
    while left < right and not lit([(left, y) for y in range(top, bot, 5)]):
        left += 1
    while right > left and not lit([(right, y) for y in range(top, bot, 5)]):
        right -= 1
    return (left, top, right + 1, bot + 1)


def lift(img, radius=12, spread=8, alpha=130):
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


def main():
    for p in (PLAQUE_SRC, BOARD_SRC, FONT):
        if not os.path.exists(p):
            sys.exit("missing source: %s" % p)
    os.makedirs(OUTDIR, exist_ok=True)

    width = SIZE - MARGIN * 2
    plaque = build_plaque(width)

    board = Image.open(BOARD_SRC).convert("RGB")
    board = board.crop(content_box(board))
    board = board.resize((width, round(board.height * width / board.width)), Image.LANCZOS)

    plaque_top = SIZE - BOTTOM - plaque.height
    room = plaque_top - GAP - MARGIN // 2
    if board.height > room:                        # keep the board inside its share, width follows
        board = board.resize((round(board.width * room / board.height), room), Image.LANCZOS)

    canvas = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
    p_img, p_pad = lift(plaque)
    b_img, b_pad = lift(board, radius=14, spread=10, alpha=140)
    canvas.paste(b_img, ((SIZE - b_img.width) // 2, plaque_top - GAP - board.height - b_pad), b_img)
    canvas.paste(p_img, ((SIZE - p_img.width) // 2, plaque_top - p_pad), p_img)

    # NOT mod_icon_*.png ANY MORE -- see the note at the top of this file. Writing them here would
    # silently undo the mod's art the next time anyone ran this script.
    out = os.path.join(OUTDIR, "old_board_icon.png")
    canvas.save(out)
    print("wrote %s (the superseded design; the live icon comes from tools/make_logo.py)" % out)


if __name__ == "__main__":
    main()
