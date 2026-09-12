#!/usr/bin/env python3
"""Render the mod's logo: the four Eyrie leaders round a table, playing Root, thoroughly unamused.

The maintainer's brief, 2026-09-07: "only the birds leaders around the table ... they could all be
around a table with drinks and cigars. like the classic paintings of dogs playing poker style" -- and,
when the first attempts came back stiff, "codex has a model for generating AI art I suspect you are
not using it ... your attempt are doomed like what I see now."

He was right on both counts. The picture is generated, not assembled. Two earlier versions cut the
leaders out of their printed cards with a flood fill and pasted them behind a drawn table, and they
looked exactly like what they were: four stickers in a row, with hand-drawn glassware that could not
survive being next to Kyle Ferrin's line work. Cutting a bird out of a card cannot give it a posture,
and posture is the whole joke.

So assets/src_art/birds_playing_root.png comes from the image model, via the Codex CLI's built-in
image_gen tool, given the printed leader-card sheet and the real Autumn map as references. The exact
prompt is kept beside it in birds_playing_root.prompt.txt so the picture can be regenerated or nudged
rather than guessed at again:

    codex exec --sandbox workspace-write -i assets/src_art/leaders/eyrie_leaders.png \\
        -i assets/src_art/map_autumn_board.png "$(cat assets/src_art/birds_playing_root.prompt.txt)"

The Codex binary ships inside the VS Code ChatGPT extension rather than on PATH, which is why it looks
absent:  ~/.vscode/extensions/openai.chatgpt-*/bin/macos-aarch64/codex

What is left for this script is the part that should be exact rather than imagined: laying the plaque
over the picture. The plaque is the one tools/make_icon.py builds -- imported, not rebuilt, so the two
can never drift apart.

This script now writes the mod's art everywhere it is seen: assets/icon/logo_*.png, the
assets/icon/mod_icon_*.png that make_icon.py used to own, and dist/Root_Tournament_Edition.png, the
256px thumbnail Tabletop Simulator shows in its save list.

Run from the repo root:  python3 tools/make_logo.py
"""
import os
import sys

from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_icon import build_plaque                            # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCENE = os.path.join(ROOT, "assets", "src_art", "birds_playing_root.png")
OUTDIR = os.path.join(ROOT, "assets", "icon")
THUMB = os.path.join(ROOT, "dist", "Root_Tournament_Edition.png")   # what TTS shows in the save list

SIZE = 1024
# THE PLAQUE SITS ON THE PICTURE, IT DOES NOT SIT UNDER IT. Stacking the two -- a square picture over a
# wide plaque -- meant cropping the picture to a letterbox, and every crop that fits took either the
# lamp off the top or the near edge of the table off the bottom. Both are load-bearing: the lamp is
# the light source the whole scene is lit by, and the near edge is where the cigars and the glasses
# are. Overlaying costs only the ashtray.
# EDGE TO EDGE. Maintainer, 2026-09-09: "make sure that for the thumbnail of the whole mod, the root
# placard uses all the lenght of the square, so increase the size of it in the picture until there is
# nothing left and right left." So the plaque spans the full canvas and has no side margin at all.
PLAQUE_WIDTH = SIZE
PLAQUE_BOTTOM = 12                         # from the foot of the canvas
SCRIM = 150                                # how far the picture is dimmed behind the plaque
# NOTHING IS TRIMMED OFF THE TOP ANY MORE. It was, for one version: a taller plaque buys a bigger
# subtitle and then spends it covering the board, which is the opposite of the point, so the picture
# was lifted by cropping the near-empty black over the lamp. That cost the lamp its shade. The fix
# belonged in the prompt instead, and is there now -- the art is asked for a plain dark foreground
# band across the bottom quarter with nothing in it, which is where the plaque goes. Left at 0 unless
# a future picture arrives without that band.
ANCHOR = 0.20            # where the letterbox crop sits: 0 is the top, 1 the bottom
# A TALLER PLAQUE, BECAUSE THE SUBTITLE HAD RUN OUT OF ROOM. On the mod icon the line is set to the
# height of the band it sits in, and that band is 169 of the plaque's rows; at logo size, over a busy
# picture, it was too small to read. Maintainer, 2026-09-08: "make tabletop tournament size font much
# bigger but making the box I guess longer vertically." 110 extra rows take the type from 160 to 216,
# which is as large as nineteen characters of Luminari get before they overrun the cream field and
# start crowding the plaque's own rules. Asked for more again on 2026-09-08 -- "make tabletop
# tournament font a bit larger again as well" -- and inside the plaque there was none left to give, so
# the whole plaque grew instead, 780 wide to 858, which enlarges ROOT and the subtitle together. Past
# this the only way up is breaking the line in two.
# ASKED FOR 30% MORE ON 2026-09-09, "by making the sign longer horizontally if need be", AND THAT
# MECHANISM CANNOT WORK. The subtitle already spans the whole cream field, so its size in the finished
# picture is (field width / plaque width) * output width -- and splicing columns in grows the field and
# the plaque together, which cancels: 650 extra columns move the line by 2%, while tracking R-O-O-T
# visibly apart. What DID move it is the placard going edge to edge, 858 -> 1024, worth +19%. That is
# the ceiling for one line inside this sign; two lines need a 509-row band to reach only +21%. So the
# widening is set back to 0 and the band is only as tall as the line needs.
# ONE LINE, ELONGATED. The line is width-bound -- nineteen characters fill the cream field at 219pt
# and neither a taller sign nor a longer one moves that. Two lines did move it, at the cost of half
# the square. Then: "no on 1 line. characters can be elongated a bit" (2026-09-09), which is the one
# lever that works without either compromise -- stretch the glyphs on the VERTICAL and the width is
# untouched while the height goes up by the factor. 1.30 is the +30% asked for, and the plaque comes
# out 39% of the square rather than the two-line 47%. See set_one_line_tall().
PLAQUE_EXTRA = 170
PLAQUE_EXTRA_WIDTH = 0
PLAQUE_TYPE_WIDTH = 1.0
PLAQUE_TWO_LINE = False
PLAQUE_ELONGATE = 1.30


def scrim(canvas, box, depth=SCRIM, feather=26):
    """Sink the picture a little behind the plaque, so the plaque reads as lying on it.

    Without this the plaque floats: it is bright parchment on a bright lamplit table, and the eye
    cannot tell which is in front. Darkening a soft-edged band under it settles the question without
    a hard rectangle appearing in the middle of the wood.
    """
    shade = Image.new("L", canvas.size, 0)
    pad = feather * 2
    band = Image.new("L", (box[2] - box[0] + pad * 2, box[3] - box[1] + pad * 2), 0)
    band.paste(depth, (pad, pad, band.width - pad, band.height - pad))
    shade.paste(band, (box[0] - pad, box[1] - pad))
    shade = shade.filter(ImageFilter.GaussianBlur(feather))
    return Image.composite(Image.new("RGB", canvas.size, (10, 7, 5)), canvas, shade)


def main():
    for p in (SCENE,):
        if not os.path.exists(p):
            sys.exit("missing source: %s" % p)
    os.makedirs(OUTDIR, exist_ok=True)

    plaque = build_plaque(PLAQUE_WIDTH, extra_band=PLAQUE_EXTRA, extra_width=PLAQUE_EXTRA_WIDTH,
                          type_width=PLAQUE_TYPE_WIDTH, two_line=PLAQUE_TWO_LINE,
                          elongate=PLAQUE_ELONGATE)

    # THE SIGN NO LONGER SITS ON THE PICTURE, IT SITS BELOW IT. Two lines make the sign nearly half
    # the square, and overlaid that buried the board, the bottles and the ashtray -- the things the
    # picture was rebuilt for. So the scene is FITTED to the room the sign leaves instead of being
    # covered by it: nothing is hidden, the scene is simply smaller. It has to be cropped to that
    # letterbox, and the crop is anchored high (ANCHOR) because the birds and the board are in the
    # upper two thirds while the bottom is bare table.
    room = SIZE - plaque.height - PLAQUE_BOTTOM
    art = Image.open(SCENE).convert("RGB")
    cw = art.width
    ch = min(art.height, round(cw * room / SIZE))
    top = round((art.height - ch) * ANCHOR)
    scene_img = art.crop((0, top, cw, top + ch)).resize((SIZE, room), Image.LANCZOS)

    canvas = Image.new("RGB", (SIZE, SIZE), (10, 7, 5))
    canvas.paste(scene_img, (0, 0))
    x = (SIZE - plaque.width) // 2
    y = SIZE - PLAQUE_BOTTOM - plaque.height
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow.paste((0, 0, 0, 165), (x - 6, y - 10, x + plaque.width + 6, y + plaque.height + 10))
    canvas = Image.alpha_composite(canvas.convert("RGBA"),
                                   shadow.filter(ImageFilter.GaussianBlur(16))).convert("RGB")
    canvas.paste(plaque, (x, y))

    at512 = canvas.resize((512, 512), Image.LANCZOS)
    at256 = canvas.resize((256, 256), Image.LANCZOS)

    # THIS IS THE MOD'S ART NOW, not just a logo beside it. Maintainer, 2026-09-08: "push that as the
    # art of the mod." So the same picture lands in all three places it is seen -- the logo, the icon
    # tools/make_icon.py used to write, and the 256px thumbnail Tabletop Simulator shows in the save
    # list. One script writes all of them, so they cannot fall out of step.
    written = []
    for path, img in ((os.path.join(OUTDIR, "logo_1024.png"), canvas),
                      (os.path.join(OUTDIR, "logo_512.png"), at512),
                      (os.path.join(OUTDIR, "logo_256.png"), at256),
                      (os.path.join(OUTDIR, "mod_icon_512.png"), at512),
                      (os.path.join(OUTDIR, "mod_icon_256.png"), at256),
                      (THUMB, at256)):
        img.save(path)
        written.append(os.path.relpath(path, ROOT))
    print("wrote " + ", ".join(written))


if __name__ == "__main__":
    main()
