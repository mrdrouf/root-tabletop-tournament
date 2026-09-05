#!/usr/bin/env python3
"""Re-set every button label on the setup board, in Luminari, from the ORIGINAL artwork.

Why this file exists: the labels had been built by a string of one-off scripts, each with its own
margins, so the row never read as a set and nobody could say what size anything was. Everything the
buttons show is now described by the two tables at the bottom and the constants just below -- change
a number here and `python3 tools/relabel.py` re-renders, re-publishes (content-hashed, because
jsDelivr caches by URL) and rewrites gen/src/save.json.

Luminari is (c) Canada Type and ships with macOS. We RENDER with it; the .ttf is never redistributed.
"""
import hashlib, json, math, os, re, shutil, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LUM = "/System/Library/Fonts/Supplemental/Luminari.ttf"
CREAM = (237, 224, 192, 255)
OUTLINE = (18, 12, 7, 255)
RING = 3

# ---------------------------------------------------------------------- house style --
# The button rectangles are 34x34 (maps, decks, the three setup squares) and 36x20 (the option
# buttons), so the canvases match those aspects exactly -- a 400x200 image on a 36x20 button is
# squashed 10% horizontally, which is how the type ended up looking narrow.
SQUARE = (300, 300)
WIDE = (400, 222)

SIDE = 4          # side margin around artwork, both shapes
ART_TOP = 2       # top margin for the square shapes
WIDE_ART_W = 170  # artwork column on an option button (was 150; the art is width-bound, so this
WIDE_ART_PAD = 3  # is the one number that actually makes option-button art bigger)
WIDE_TEXT_PAD = 8

# Start sizes. A name too wide is CONDENSED first and only then set smaller, which is what lets a
# long name like "Squires & Disciples" grow at all. v8 took these to 62/58 at a 0.80 floor and the
# maintainer called every caption too big; these sit between v8 and the 59/46 that came before it.
SQUARE_PT = 56
WIDE_PT = 51
SQUEEZE_FLOOR = 0.88


def font(pt):
    return ImageFont.truetype(LUM, pt)


def fit(lines, box, start, floor=SQUEEZE_FLOOR):
    """-> (font, squeeze). Condense down to `floor` before giving up any point size."""
    pt = start
    while pt > 14:
        f = font(pt)
        w = max(f.getlength(t) for t in lines)
        if w <= box:
            return f, 1.0
        if box / w >= floor:
            return f, box / w
        pt -= 1
    f = font(14)
    w = max(f.getlength(t) for t in lines)
    return f, min(1.0, box / w)


def _outlined(d, xy, text, f):
    x, y = xy
    for ox in range(-RING, RING + 1):
        for oy in range(-RING, RING + 1):
            if ox * ox + oy * oy <= RING * RING and (ox or oy):
                d.text((x + ox, y + oy), text, font=f, fill=OUTLINE)
    d.text((x, y), text, font=f, fill=CREAM)


def put_line(im, text, f, cx, top, squeeze):
    bb = f.getbbox(text)
    w = int(math.ceil(f.getlength(text))) + 2 * RING + 4
    h = (bb[3] - bb[1]) + 2 * RING + 4
    tmp = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    _outlined(ImageDraw.Draw(tmp), (RING + 2, RING + 2 - bb[1]), text, f)
    if squeeze < 1.0:
        tmp = tmp.resize((max(1, int(round(w * squeeze))), h), Image.LANCZOS)
    im.alpha_composite(tmp, (int(round(cx - tmp.width / 2)), int(round(top - RING - 2))))


def text_block(im, lines, box_w, cx, band_top, band_bot, start_pt, drop=0):
    f, sq = fit(lines, box_w, start_pt)
    lh = f.getbbox("Ag")[3] - f.getbbox("Ag")[1]
    gap = int(f.size * 0.24)
    total = lh * len(lines) + gap * (len(lines) - 1)
    top = band_top + (band_bot - band_top - total) / 2 + drop
    for i, t in enumerate(lines):
        bb = f.getbbox(t)
        put_line(im, t, f, cx, top + i * (lh + gap) - bb[1] + (bb[1] - f.getbbox("Ag")[1]) * 0, sq)
    return f.size, round(sq, 3)


# ------------------------------------------------------------------------ artwork --
def trim(im):
    im = im.convert("RGBA")
    bb = im.getchannel("A").getbbox()
    return im.crop(bb) if bb else im


def drop_frame(im, dark=52):
    """Trim an artwork's own dark frame, which reads as a seam on a coloured button."""
    rgb = im.convert("RGB"); px = rgb.load(); W, H = rgb.size
    l, t, r, b = 0, 0, W - 1, H - 1
    row = lambda y, x0, x1: sum(sum(px[x, y]) / 3 for x in range(x0, x1 + 1)) / (x1 - x0 + 1) < dark
    col = lambda x, y0, y1: sum(sum(px[x, y]) / 3 for y in range(y0, y1 + 1)) / (y1 - y0 + 1) < dark
    for _ in range(max(W, H)):
        moved = False
        if l < r and col(l, t, b): l += 1; moved = True
        if l < r and col(r, t, b): r -= 1; moved = True
        if t < b and row(t, l, r): t += 1; moved = True
        if t < b and row(b, l, r): b -= 1; moved = True
        if not moved: break
    return im.crop((l, t, r + 1, b + 1))


def art_topband(path, frac=0.773):
    """The base mod's own square labels are art over a caption band; keep the art."""
    im = Image.open(os.path.join(ROOT, path)).convert("RGBA")
    return drop_frame(im.crop((0, 0, im.width, int(im.height * frac))))


def art_alpha_topband(path, frac):
    """Same as art_topband but the source is already on alpha -- trim by alpha, never by darkness
    (drop_frame reads transparent as black and eats dark artwork such as the landmark tiles)."""
    im = Image.open(os.path.join(ROOT, path)).convert("RGBA")
    return trim(im.crop((0, 0, im.width, int(im.height * frac))))


def art_crop_aspect(path, aspect, cut_top=0):
    """Centre-crop a photo to a given w/h so it fills the button the way the old label did."""
    im = Image.open(os.path.join(ROOT, path)).convert("RGBA")
    if cut_top:
        im = im.crop((0, cut_top, im.width, im.height))
    w, h = im.size
    if w / h > aspect: w2, h2 = int(h * aspect), h
    else:              w2, h2 = w, int(w / aspect)
    return im.crop(((w - w2) // 2, (h - h2) // 2, (w - w2) // 2 + w2, (h - h2) // 2 + h2))


def art_from_label(fname):
    """Lift the artwork out of a label PNG (already isolated on alpha), for the few buttons whose
    art was composed by hand and exists nowhere else.

    The filename is PINNED, never read back out of save.json: these labels put the art in the first
    152px, so lifting from whatever the board points at right now would re-crop the art this script
    itself just widened, and it would lose a few pixels on every run.
    """
    im = Image.open(os.path.join(ROOT, "assets/labels", fname)).convert("RGBA")
    return trim(im.crop((0, 0, 152, im.height)))


# ------------------------------------------------------------------------- shapes --
def square_label(out, art, lines, art_bot_frac, drop=0, pt=SQUARE_PT):
    W, H = SQUARE
    im = Image.new("RGBA", SQUARE, (0, 0, 0, 0))
    bot = int(H * art_bot_frac)
    if art is not None:
        a = trim(art)
        sc = min((W - 2 * SIDE) / a.width, (bot - ART_TOP) / a.height)
        a = a.resize((max(1, int(a.width * sc)), max(1, int(a.height * sc))), Image.LANCZOS)
        im.alpha_composite(a, ((W - a.width) // 2, ART_TOP))
        art_px = a.size
    else:
        art_px = (0, 0)
    sz = text_block(im, lines, W - 2 * SIDE, W / 2, bot, H, pt, drop)
    im.save(out)
    return art_px, sz


def wide_label(out, art, lines, pt=WIDE_PT):
    W, H = WIDE
    im = Image.new("RGBA", WIDE, (0, 0, 0, 0))
    if art is not None:
        a = trim(art)
        sc = min((WIDE_ART_W - 2 * WIDE_ART_PAD) / a.width, (H - 2 * WIDE_ART_PAD) / a.height)
        a = a.resize((max(1, int(a.width * sc)), max(1, int(a.height * sc))), Image.LANCZOS)
        im.alpha_composite(a, ((WIDE_ART_W - a.width) // 2, (H - a.height) // 2))
        art_px, x0 = a.size, WIDE_ART_W
    else:
        art_px, x0 = (0, 0), 0
    sz = text_block(im, lines, W - x0 - WIDE_TEXT_PAD, x0 + (W - x0) / 2, 0, H, pt)
    im.save(out)
    return art_px, sz


# ------------------------------------------------------------------------ publish --
def publish(local):
    h = hashlib.md5(open(local, "rb").read()).hexdigest()[:8]
    d, fn = os.path.split(local)
    stem, ext = os.path.splitext(fn)
    stem = re.sub(r"_[0-9a-f]{8}$", "", stem)
    out = os.path.join(d, "%s_%s%s" % (stem, h, ext))
    if out != local:
        shutil.copy2(local, out)
    rel = out.split("assets/", 1)[1]
    return out, "https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/assets/" + rel


# --------------------------------------------------------------------- the tables --
# (asset name, output stem, caption lines, artwork)
# art_bot_frac is where the artwork stops and the caption band starts; `drop` pushes the caption
# further down inside that band, which is what "write the name a little lower" means.
SQUARES = [
    ("Autumn Map",   "map_autumn_v9",   ["Autumn"],   lambda: art_topband("assets/src_art/map_autumn.png"),   0.79, 0),
    ("Winter Map",   "map_winter_v9",   ["Winter"],   lambda: art_topband("assets/src_art/map_winter.png"),   0.79, 0),
    ("Lake Map",     "map_lake_v9",     ["Lake"],     lambda: art_topband("assets/src_art/map_lake.png"),     0.79, 0),
    ("Mountain Map", "map_mountain_v9", ["Mountain"], lambda: art_topband("assets/src_art/map_mountain.png"), 0.79, 0),
    ("Marsh Map",    "map_marsh_v9",    ["Marsh"],    lambda: art_topband("assets/src_art/map_marsh.png"),    0.79, 0),
    ("Gorge Map",    "map_gorge_v9",    ["Gorge"],    lambda: art_topband("assets/src_art/map_gorge.png"),    0.79, 0),

    ("Standard Deck",              "deck_base_v9",    ["Base Deck"],           lambda: art_topband("assets/src_art/deck_base.png"),    0.755, 6),
    ("Exiles and Partisans Deck",  "deck_exiles_v9",  ["Exiles & Partisans"],  lambda: art_topband("assets/src_art/deck_exiles.png"),  0.755, 6),
    ("Squires and Disciples Deck", "deck_squires_v9", ["Squires & Disciples"], lambda: art_topband("assets/src_art/deck_squires.png"), 0.755, 6),

    ("ThemeArt",      "theme_art_v9",          ["Theme"],          lambda: art_topband("assets/src_art/theme.png"),                 0.735, 8),
    ("RankedArt",     "four_player_draft_v9",  ["4-Player Draft"], lambda: art_crop_aspect("assets/images/ranked.png", 1.33, 210),       0.735, 8),
    ("FourBoardsArt", "four_player_setup_v9",  ["4-Player Setup"], lambda: art_crop_aspect("assets/images/4players.png", 1.33),     0.735, 8),
]

WIDES = [
    # The Faction Selector art is a picture of the selector board AS IT IS NOW -- twelve tiles with
    # Vagabond & Knaves in the top-right slot. The old label showed the superseded layout.
    ("Faction Selector Tool", "faction_selector_v9", ["Faction", "Selector"],
     lambda: Image.open(os.path.join(ROOT, "assets/src_art/faction_selector_new.png")).convert("RGBA")),
    ("Bat Bungler",        "bat_bungler_v9",         ["The Bat", "Bungler"],  lambda: art_from_label("bat_bungler_lum_9d1318f6.png")),
    ("Mob Lobber",         "mob_lobber_v9",          ["Mob", "Lobber"],       lambda: art_from_label("mob_lobber_lum_8c60b59e.png")),
    ("Koffin Keeper",      "koffin_keeper_v9",       ["Koffin", "Keeper"],    lambda: art_from_label("koffin_keeper_lum_e1358cfd.png")),
    ("Vagabond Cards",     "vagabond_cards_v9",      ["Vagabond", "Cards"],   lambda: trim(Image.open(os.path.join(ROOT, "assets/icons_fit/vbcards.png")).convert("RGBA"))),
    ("Landmarks",          "landmarks_v9",           ["Landmarks"],           lambda: art_alpha_topband("assets/icons_fit/landmarks.png", 0.70)),
    ("FivePlayerSetupArt", "five_player_setup_v9",   ["5-Player", "Setup"],   lambda: art_crop_aspect("assets/images/5players.png", 0.853)),
    ("FivePlayerArt",      "five_player_draft_v9",   ["5-Player", "Draft"],   lambda: art_crop_aspect("assets/images/5players.png", 0.853)),
    ("Marsh5PLabel",       "five_players_marsh_v9",  ["5-Players", "Marsh"],  lambda: art_topband("assets/upload/map_marsh.png")),
    ("FactionCardsArt",    "faction_cards_v9",       ["Faction", "Cards"],    lambda: art_from_label("faction_cards_label_v4_34723094.png")),
    ("CreditsBtnArt",      "credits_button_v9",      ["Credits"],             lambda: None),
]

SAVE = os.path.join(ROOT, "gen/src/save.json")
BOARD = "bab7e1"


def board_of(doc):
    def walk(o):
        if isinstance(o, dict):
            if o.get("GUID") == BOARD: yield o
            for v in o.values(): yield from walk(v)
        elif isinstance(o, list):
            for v in o: yield from walk(v)
    return next(walk(doc))


raw = open(SAVE, "rb").read().decode("utf-8")
CURRENT = {a["Name"]: a["URL"] for a in board_of(json.loads(raw))["CustomUIAssets"]}


def main(write):
    outdir = os.path.join(ROOT, "assets/labels")
    urls, report = {}, []
    for name, stem, lines, mkart, frac, drop in SQUARES:
        p = os.path.join(outdir, stem + ".png")
        art, sz = square_label(p, mkart(), lines, frac, drop)
        f, u = publish(p); urls[name] = u
        report.append(("SQ", name, art, sz, os.path.basename(f)))
    for name, stem, lines, mkart in WIDES:
        p = os.path.join(outdir, stem + ".png")
        art, sz = wide_label(p, mkart(), lines)
        f, u = publish(p); urls[name] = u
        report.append(("WD", name, art, sz, os.path.basename(f)))
    for kind, name, art, sz, fn in report:
        print("  %s %-28s art=%-9s pt=%-3s squeeze=%-5s %s" % (kind, name, "%dx%d" % art, sz[0], sz[1], fn))
    if write:
        doc = json.loads(raw)
        b = board_of(doc)
        for a in b["CustomUIAssets"]:
            if a["Name"] in urls:
                a["URL"] = urls[a["Name"]]
        # rewrite by surgical URL substitution so the CRLF file is not reflowed
        out = raw
        for a in board_of(json.loads(raw))["CustomUIAssets"]:
            if a["Name"] in urls and a["URL"]:
                assert out.count(a["URL"]) >= 1, a["Name"]
                out = out.replace(a["URL"], urls[a["Name"]])
        open(SAVE, "wb").write(out.encode("utf-8"))
        print("  save.json rewritten (%d urls)" % len(urls))
    return urls


if __name__ == "__main__":
    main("--write" in sys.argv)
