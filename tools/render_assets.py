"""
Render the mod's generated art (setup plaques + handwriting credit) to PNGs in
assets/. Shared by the one-off scripts and by m350 (which regenerates a plaque or
the credit when you change its text in the Board Studio editor).
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTS = r"C:\Windows\Fonts"

CREDIT_FONTS = {  # name -> (file, size)
    "mistral": ("MISTRAL.TTF", 170), "inkfree": ("Inkfree.ttf", 150),
    "segoescript": ("segoesc.ttf", 140), "lucida": ("LHANDW.TTF", 120),
    "brush": ("BRUSHSCI.TTF", 150),
}


def _font(fname, size):
    return ImageFont.truetype(os.path.join(FONTS, fname), size)


def render_plaque(big, small, out_path):
    """A wooden plaque: big line over small line, dark wood + brass border, cream serif."""
    W, H = 400, 360
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    plate = Image.new("RGBA", (W, H)); pd = ImageDraw.Draw(plate)
    for y in range(H):
        f = y / H
        pd.line([(0, y), (W, y)], fill=(int(61 - 23 * f), int(46 - 18 * f), int(30 - 12 * f), 255))
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).rounded_rectangle([6, 6, W - 6, H - 6], radius=34, fill=255)
    img.paste(plate, (0, 0), mask)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([6, 6, W - 6, H - 6], radius=34, outline=(184, 154, 94, 255), width=7)
    d.rounded_rectangle([18, 18, W - 18, H - 18], radius=26, outline=(120, 96, 58, 255), width=3)
    cream = (237, 224, 192, 255)
    fb = _font("georgiab.ttf", 150 if len(big) <= 2 else 96)
    bb = d.textbbox((0, 0), big, font=fb)
    d.text(((W - (bb[2] - bb[0])) / 2 - bb[0], 60), big, font=fb, fill=cream)
    fs = _font("georgiab.ttf", 58)
    sb = d.textbbox((0, 0), small, font=fs)
    d.text(((W - (sb[2] - sb[0])) / 2 - sb[0], 235), small, font=fs, fill=(206, 186, 140, 255))
    img.save(out_path)
    return W / H


def render_credit(text, out_path, font="mistral"):
    """Handwriting phrase, cream, transparent — for the hand-added board credit."""
    fname, size = CREDIT_FONTS.get(font, CREDIT_FONTS["mistral"])
    f = _font(fname, size)
    tmp = ImageDraw.Draw(Image.new("RGBA", (10, 10)))
    bb = tmp.textbbox((0, 0), text, font=f)
    w, h, pad = bb[2] - bb[0], bb[3] - bb[1], 30
    img = Image.new("RGBA", (w + 2 * pad, h + 2 * pad), (0, 0, 0, 0))
    ImageDraw.Draw(img).text((pad - bb[0], pad - bb[1]), text, font=f, fill=(233, 221, 190, 255))
    img.save(out_path)
    return img.width / img.height
