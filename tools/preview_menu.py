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
SX, SY = 3.0, 3.0
X0, X1, Y0, Y1 = -112, 112, -92, 92        # symmetric about X=0 (the board centre)
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
    # "TOP" = everything outside every ToggleGroup (rootLogo, info, xButton live there)
    if gid == "TOP":
        out, j = [], 0
        while True:
            o = xml.find('<ToggleGroup', j)
            if o == -1:
                out.append(xml[j:]); break
            out.append(xml[j:o])
            depth, k = 0, o
            while k < len(xml):
                oo = xml.find('<ToggleGroup', k); cc = xml.find('</ToggleGroup>', k)
                if cc == -1: break
                if oo != -1 and oo < cc: depth += 1; k = oo + 12
                else:
                    depth -= 1; k = cc + 14
                    if depth == 0: break
            j = k
        return "".join(out)
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
                        color=g("color"), tag=tag,
                        fontSize=float(g("fontSize") or 0) or None))
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

# ---- render ---- (use the real board texture so centering is judged against the wood)
_board_local = os.path.join(ROOT, "assets", "board", "board_clean.png")
if os.path.exists(_board_local):
    img = Image.open(_board_local).convert("RGBA").resize((W, H))
else:
    img = Image.new("RGBA", (W, H), (95, 66, 41, 255))
dr = ImageDraw.Draw(img)
_FONT_CANDIDATES = [
    r"C:\Windows\Fonts\arialbd.ttf",
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "/System/Library/Fonts/Supplemental/Arial.ttf",
    "/System/Library/Fonts/Helvetica.ttc",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
]
def font(sz):
    for _p in _FONT_CANDIDATES:
        try: return ImageFont.truetype(_p, max(1, int(sz)))
        except Exception: pass
    return ImageFont.load_default()

def draw_btn(b):
    l, t, r, bot = box(b)
    if b.get("color") and b.get("tag") != "Text":
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
        # XmlUI fontSize is in board units -> px via the SY scale. <Text> uses its own colour.
        import html as _html
        txt = _html.unescape(b["text"])          # TTS renders &amp;/&#183; -- show the real glyphs
        fs = b.get("fontSize") or 11
        col = hexc(b["color"]) + (255,) if b.get("color") else (235, 225, 195, 255)
        dr.text(((l + r) / 2, (t + bot) / 2), txt, anchor="mm",
                fill=col, font=font(fs * SY))
    if DEBUG:
        dr.rectangle([l, t, r, bot], outline=(255, 255, 255, 40))   # slot outline

total = 0
for gid in GROUPS:
    blk = group_block(gid)
    btns = parse(blk, "Button") + parse(blk, "Image") + parse(blk, "Text")
    for b in btns:
        draw_btn(b); total += 1

# (baked title/credit removed from the texture; ROOT logo + credit are real elements)
if DEBUG:
    marker = lambda x, y, w, h: dr.rectangle(box(dict(x=x, y=y, w=w, h=h)),
                                             outline=(255, 210, 120, 200), width=2)
    marker(-2, -45, 120, 10); marker(-70, -82, 34, 12)
    bl = box(dict(x=-88, y=85, w=0, h=0))[0:2]; br = box(dict(x=92, y=-85, w=0, h=0))[0:2]
    dr.rectangle([bl[0], bl[1], br[0], br[1]], outline=(255, 255, 255, 90), width=1)

img.convert("RGB").save(OUT)
print("rendered %d elements -> %s (%dx%d)" % (total, OUT, W, H))
