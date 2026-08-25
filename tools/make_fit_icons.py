"""
Generate aspect-corrected icons so square art isn't stretched in the half-tiles.

- VB Cards: crop off the baked "VB Cards for Drafting" text, keep just the card fan.
- All three references (VB Cards, Landmarks, Clearing Priorities): pad to 2:1 with
  transparent margins so the square art shows centred and undistorted in a 2:1 button.
Also re-renders the RTT plaque square. Outputs land in assets/ and are hosted via
GitHub raw.
"""
import os, io, hashlib, json, urllib.request
from PIL import Image
import render_assets

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = os.path.join(os.environ.get("TEMP", "/tmp"), "rtt_iconcache")
FIT = os.path.join(ROOT, "assets", "icons_fit"); os.makedirs(FIT, exist_ok=True)

d = json.load(open(os.path.join(ROOT, "dist", "Root_Tabletop_Tournament.json"), encoding="utf-8"))
fs = next(o for o in d["ObjectStates"] if o.get("GUID") == "bab7e1")
assets = {a["Name"]: a["URL"] for a in fs.get("CustomUIAssets", [])}

def icon(name):
    url = assets[name]
    p = os.path.join(CACHE, hashlib.md5(url.encode()).hexdigest() + ".img")
    data = open(p, "rb").read() if os.path.exists(p) else \
        urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "M"}), timeout=25).read()
    return Image.open(io.BytesIO(data)).convert("RGBA")

def pad_to(im, aspect):
    iw, ih = im.size
    cw = max(iw, round(ih * aspect)); ch = max(ih, round(cw / aspect))
    canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    canvas.alpha_composite(im, ((cw - iw) // 2, (ch - ih) // 2))
    return canvas

# VB Cards: keep just the fan (top ~62%), drop the text band, then pad to 2:1
vb = icon("Vagabond Cards")
vb = vb.crop((0, 0, vb.width, int(vb.height * 0.62)))
pad_to(vb, 2.0).save(os.path.join(FIT, "vbcards.png")); print("  vbcards.png (cropped fan, 2:1)")

for name, out in [("Landmarks", "landmarks.png"), ("Clearing Priorities Big", "clearing.png")]:
    pad_to(icon(name), 2.0).save(os.path.join(FIT, out)); print("  %s (2:1 padded)" % out)

# RTT plaque, square
render_assets.render_plaque("RTT", "DRAFT", os.path.join(ROOT, "assets", "buttons", "setup_rtt.png"))
print("  setup_rtt.png (square)")
