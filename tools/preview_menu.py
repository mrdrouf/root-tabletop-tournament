"""
Menu layout previewer — renders the actual TTS menu board to a PNG WITHOUT loading
Tabletop Simulator, by fetching the real button-icon images (they're hosted URLs in
the Faction Selection object's CustomUIAssets) and compositing them at their XmlUI
coordinates and sizes. This is the feedback loop: iterate the layout against a
faithful preview instead of guessing blind.

Usage: python tools/preview_menu.py [group ...]
Default groups are the ones active on the main page.
"""
import json, re, os, sys, hashlib, urllib.request
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIST = os.path.join(ROOT, "dist", "Root_Tabletop_Tournament.json")
CACHE = os.path.join(os.environ.get("TEMP", "/tmp"), "rtt_iconcache")
OUT = os.path.join(ROOT, "tools", "menu_preview.png")
os.makedirs(CACHE, exist_ok=True)

MENU_GUID = "bab7e1"                      # Faction Selection
DEBUG = "--debug" in sys.argv
GROUPS = [a for a in sys.argv[1:] if not a.startswith("--")] or \
    ["setupButtons", "mapButtonsStandard", "decksButtonsStandard", "tools1", "Main Nav"]

# ---- coordinate space -> pixels (calibrated to the board: X ~3.07 px/u, Y ~2.9) ----
SX, SY = 3.2, 3.0
X0, X1, Y0, Y1 = -98, 122, -92, 92
W, H = int((X1 - X0) * SX), int((Y1 - Y0) * SY)

def px(x, y):
    return (x - X0) * SX, (Y1 - y) * SY          # y-up world -> y-down screen

def box(b):
    cx, cy = px(b["x"], b["y"])
    return [cx - b["w"] * SX / 2, cy - b["h"] * SY / 2,
            cx + b["w"] * SX / 2, cy + b["h"] * SY / 2]

def hexc(s, default=(120, 90, 60)):
    if not s or not s.startswith("#"):
        return default
    s = s[1:]
    return tuple(int(s[i:i+2], 16) for i in (0, 2, 4))

# ---- load + parse ----
d = json.load(open(DIST, encoding="utf-8"))
def find(states):
    for o in states:
        if o.get("GUID") == MENU_GUID:
            return o
    return None
fs = find(d["ObjectStates"])
assets = {a["Name"]: a["URL"] for a in fs.get("CustomUIAssets", [])}
xml = fs["XmlUI"]                            # decoded: real quotes

def group_block(gid):
    m = re.search(r'<ToggleGroup id ?= ?"%s"' % re.escape(gid), xml)
    if not m:
        return ""
    i = m.start(); depth = 0; j = i
    while j < len(xml):
        o = xml.find('<ToggleGroup', j); c = xml.find('</ToggleGroup>', j)
        if c == -1:
            break
        if o != -1 and o < c:
            depth += 1; j = o + 12
        else:
            depth -= 1; j = c + 14
            if depth == 0:
                break
    return xml[i:j]

def attrs(s):
    def g(k):
        mm = re.search(r'%s ?= ?"([^"]*)"' % k, s)
        return mm.group(1) if mm else None
    return g

def parse(block, tag):
    out = []
    for m in re.finditer(r'<%s([^>]*?)/>' % tag, block):
        g = attrs(m.group(1))
        pos = g("position")
        if not pos:
            continue
        x, y, *_ = [float(v) for v in pos.split()]
        out.append(dict(id=g("id"), icon=g("icon"), image=g("image"), text=g("text"),
                        x=x, y=y, w=float(g("width") or 20), h=float(g("height") or 20),
                        color=g("color")))
    return out

REPO_RAW = "raw.githubusercontent.com/mrdrouf/root-tabletop-tournament/main/"

def fetch(url):
    # the repo's own assets may not be pushed yet — resolve them to local files
    if REPO_RAW in url:
        local = os.path.join(ROOT, url.split(REPO_RAW, 1)[1].replace("/", os.sep))
        if os.path.exists(local):
            try:
                return Image.open(local).convert("RGBA")
            except Exception:
                pass
    p = os.path.join(CACHE, hashlib.md5(url.encode()).hexdigest() + ".img")
    if not os.path.exists(p):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            open(p, "wb").write(urllib.request.urlopen(req, timeout=20).read())
        except Exception as e:
            print("  ! fetch failed:", url[:60], e); return None
    try:
        return Image.open(p).convert("RGBA")
    except Exception:
        return None

# ---- render ----
img = Image.new("RGBA", (W, H), (95, 66, 41, 255))
dr = ImageDraw.Draw(img)
for gy in range(0, H, 3):                    # faint wood grain
    dr.line([(0, gy), (W, gy)], fill=(88, 61, 38, 60))
def font(sz):
    try: return ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", sz)
    except: return ImageFont.load_default()

def draw_btn(b):
    l, t, r, bot = box(b)
    if b.get("color"):
        dr.rounded_rectangle([l, t, r, bot], radius=6, fill=hexc(b["color"]) + (255,))
    name = b.get("icon") or b.get("image")
    src = None
    if name and name in assets:
        src = fetch(assets[name])
    elif name == "rttCreditImg":
        lp = os.path.join(ROOT, "assets", "credit", "credit_mistral.png")
        src = Image.open(lp).convert("RGBA") if os.path.exists(lp) else None
    if src:
        iw, ih = max(1, int(r - l)), max(1, int(bot - t))
        img.alpha_composite(src.resize((iw, ih)), (int(l), int(t)))
    elif b.get("text"):
        dr.text(((l + r) / 2, (t + bot) / 2), b["text"], anchor="mm",
                fill=(235, 225, 195), font=font(11))
    if DEBUG:
        dr.rectangle([l, t, r, bot], outline=(255, 255, 255, 40))   # slot outline

total = 0
for gid in GROUPS:
    blk = group_block(gid)
    btns = parse(blk, "Button") + parse(blk, "Image")
    for b in btns:
        draw_btn(b); total += 1

# baked art (part of the board texture) — draw subtly so the preview is representative
def baked_text(x, y, txt, size, fill):
    cx, cy = px(x, y)
    dr.text((cx, cy), txt, anchor="mm", fill=fill, font=font(size))
baked_text(-2, -45, "TTS Tools by the ROOT Community", 20, (222, 205, 168, 235))
baked_text(-70, -82, "Board by Ehss\n& slugfacekillah", 11, (150, 128, 96, 255))
baked_text(-68, 78, "ROOT", 30, (210, 190, 150, 120))
if DEBUG:
    marker = lambda x, y, w, h: dr.rectangle(box(dict(x=x, y=y, w=w, h=h)),
                                             outline=(255, 210, 120, 200), width=2)
    marker(-2, -45, 120, 10); marker(-70, -82, 34, 12)
    bl = box(dict(x=-88, y=85, w=0, h=0))[0:2]; br = box(dict(x=92, y=-85, w=0, h=0))[0:2]
    dr.rectangle([bl[0], bl[1], br[0], br[1]], outline=(255, 255, 255, 90), width=1)

img.convert("RGB").save(OUT)
print("rendered %d elements -> %s (%dx%d)" % (total, OUT, W, H))
