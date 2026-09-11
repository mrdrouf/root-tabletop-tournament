#!/usr/bin/env python3
"""Cut Luminari's digits into single-glyph images, so LIVE numbers can be set in the mod's own face.

Maintainer, 2026-09-11: "and please use the same font as well force the luminari or whatefer the name
everywhere". Told that only baked, fixed text can be Luminari: "thats fine for only fixed text. but
cant you resolve that issue it looks very had hoc problem."

    python3 tools/make_digits.py

IT IS AD HOC, AND THIS IS THE WAY OUT. TTS cannot be given a font: `UI.setCustomAssets` takes images
only (every one of the 1,838 CustomUIAssets in his Saves is Type 0, and the box score script says so
in as many words), so anything the mod TYPES at runtime -- the round number, the clock -- comes out in
TTS's default face while every baked label beside it is Luminari. The two sit inches apart on the same
panel.

A number is not arbitrary text, though: it is eleven shapes. Baked one per glyph they are images, so
they can be set at runtime like any other image, and the panel's live numbers come out in the same
face as everything printed on it.

WHITE ON TRANSPARENCY, NOT INK. A TTS <Image> carries a `color`, which multiplies -- so one white set
tints to the panel's ink normally and to white when the clock goes red, which is exactly the two
colours readout() already switches between. Baking them in ink would need a second set and would put
the alarm colour in the art, where it could not follow a change.

ONE CELL FOR EVERY DIGIT, because the clock must not move. Luminari's digits are proportional -- 60
units wide for a 1 against 94 for a 0 -- so a clock built from tight glyphs would visibly shuffle
every time a 1 ticked past. Each digit is therefore centred in a cell as wide as the widest of them,
which is what a scoreboard does anyway. The colon keeps its own narrow cell; giving it the digit cell
put a hole either side of it.

ONE BASELINE. They do not share one naturally -- the 6 rises 10px above its neighbours and the 9 drops
6px below -- so all eleven are drawn at a common origin and cropped to a common band, and any glyph
can then be laid beside any other without measuring.

Writes assets/labels/lum_<glyph>_<md5>.png and prints the Lua table for the panel.
"""
import hashlib
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
OUT = os.path.join(REPO, "assets", "labels")
CDN = "https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/assets/labels/%s"

LUM = "/System/Library/Fonts/Supplemental/Luminari.ttf"

GLYPHS = "0123456789:"
NAMES = {":": "colon"}                 # ':' is not a filename

# BAKED BIG, USED SMALL. The panel draws its numbers about 50 UI pixels tall; rendering at 160 and
# letting TTS scale down keeps the edges clean at any size the panel is later given.
SIZE = 160
PAD = 6                                # breathing room inside the cell, so neighbours never touch


def glyph_box(d, f):
    """The common band every glyph is drawn into: one baseline, one height, one digit width."""
    tops, bots, advs = [], [], []
    for ch in GLYPHS:
        x0, y0, x1, y1 = d.textbbox((0, 0), ch, font=f)
        tops.append(y0)
        bots.append(y1)
        if ch.isdigit():
            advs.append(x1 - x0)
        # a glyph that starts left of the origin would be clipped by a naive crop
        assert x0 >= -4, "%s starts at x=%d" % (ch, x0)
    return min(tops) - PAD, max(bots) + PAD, max(advs) + 2 * PAD


def render(ch, f, top, bottom, cell):
    """One glyph, white on transparency, centred in its cell on the common baseline."""
    h = bottom - top
    x0, _, x1, _ = ImageDraw.Draw(Image.new("L", (1, 1))).textbbox((0, 0), ch, font=f)
    w = cell if ch.isdigit() else (x1 - x0) + 2 * PAD
    im = Image.new("RGBA", (w, h), (255, 255, 255, 0))
    # drawn at the SAME y for every glyph (textbbox is measured from the ascender, so a common draw
    # origin IS a common baseline) and centred horizontally on its own ink
    ImageDraw.Draw(im).text((w / 2 - (x1 - x0) / 2 - x0, -top), ch,
                            font=f, fill=(255, 255, 255, 255))
    return im


def main():
    if not os.path.exists(LUM):
        sys.exit("missing %s" % LUM)
    f = ImageFont.truetype(LUM, SIZE)
    d = ImageDraw.Draw(Image.new("L", (1, 1)))
    top, bottom, cell = glyph_box(d, f)
    print("  common band: y %d..%d (%dpx tall), digit cell %dpx wide"
          % (top, bottom, bottom - top, cell))

    rows = []
    for ch in GLYPHS:
        im = render(ch, f, top, bottom, cell)
        stem = "lum_%s" % NAMES.get(ch, ch)
        tmp = os.path.join(OUT, "_tmp_%s.png" % stem)
        im.save(tmp)
        digest = hashlib.md5(open(tmp, "rb").read()).hexdigest()[:8]
        final = "%s_%s.png" % (stem, digest)
        os.replace(tmp, os.path.join(OUT, final))
        # drop any earlier build of the same glyph, so the folder holds one of each
        for old in os.listdir(OUT):
            if old.startswith(stem + "_") and old != final:
                os.remove(os.path.join(OUT, old))
        rows.append((ch, final, im.size))

    print()
    for ch, final, size in rows:
        print("   %-3s %-30s %dx%d" % (repr(ch), final, size[0], size[1]))

    print("\n  the Lua table, for RTT_TURN_PANEL_JSON:\n")
    print("RTT_LUM_DIGITS = {")
    for ch, final, _ in rows:
        key = NAMES.get(ch, ch)
        print('  ["%s"] = "%s",' % (key, CDN % final))
    print("}")


if __name__ == "__main__":
    main()
