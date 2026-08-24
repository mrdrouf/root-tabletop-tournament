"""
Build the interactive board-layout editor (a self-contained HTML artifact).

Extracts every menu element from the built mod, fetches the real button-icon images
+ the board texture and inlines them as data URIs (the artifact CSP blocks remote
images), and writes tools/board_editor.html — a drag/resize/edit canvas the user
drives. It exports a layout JSON that build_from_editor applies back into the mod.
"""
import json, re, os, sys, base64, hashlib, urllib.request, io
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIST = os.path.join(ROOT, "dist", "Root_Tabletop_Tournament.json")
OUT = os.path.join(ROOT, "tools", "board_editor.html")
CACHE = os.path.join(os.environ.get("TEMP", "/tmp"), "rtt_iconcache")
os.makedirs(CACHE, exist_ok=True)
MENU_GUID = "bab7e1"
REPO_RAW = "raw.githubusercontent.com/mrdrouf/root-tabletop-tournament/main/"
GROUPS = ["setupButtons", "mapButtonsStandard", "decksButtonsStandard", "tools1"]
PLAQUES = {"setup4p", "setup5p", "setuprtt"}

d = json.load(open(DIST, encoding="utf-8"))
fs = next(o for o in d["ObjectStates"] if o.get("GUID") == MENU_GUID)
assets = {a["Name"]: a["URL"] for a in fs.get("CustomUIAssets", [])}
board_url = fs["CustomImage"]["ImageURL"]
xml = fs["XmlUI"]

def fetch(url, maxw=None):
    key = os.path.join(CACHE, hashlib.md5(url.encode()).hexdigest() + ".img")
    data = None
    if REPO_RAW in url:
        local = os.path.join(ROOT, url.split(REPO_RAW, 1)[1].replace("/", os.sep))
        if os.path.exists(local):
            data = open(local, "rb").read()
    if data is None and os.path.exists(key):
        data = open(key, "rb").read()
    if data is None:
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            data = urllib.request.urlopen(req, timeout=25).read()
            open(key, "wb").write(data)
        except Exception as e:
            print("  ! fetch failed", url[:60], e); return None
    try:
        im = Image.open(io.BytesIO(data)).convert("RGBA")
    except Exception:
        return None
    if maxw and im.width > maxw:
        im = im.resize((maxw, round(im.height * maxw / im.width)))
    buf = io.BytesIO(); im.save(buf, "PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()

def grp_block(gid):
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

def A(s, k):
    m = re.search(r'%s ?= ?"([^"]*)"' % k, s)
    return m.group(1) if m else None

# ---- collect elements ----
elements, used_assets = [], set()
GROUP_LABEL = {"setupButtons": "Setups", "mapButtonsStandard": "Maps",
               "decksButtonsStandard": "Decks", "tools1": "Tools"}
for gid in GROUPS:
    for m in re.finditer(r'<Button([^>]*?)/>', grp_block(gid)):
        s = m.group(1)
        pos = A(s, "position")
        if not pos:
            continue
        x, y, *_ = [float(v) for v in pos.split()]
        icon, text = A(s, "icon"), A(s, "text")
        bid = A(s, "id") or (A(s, "onclick") or "")
        if icon in PLAQUES:
            kind, label, asset = "plaque", {"setup4p": "4 | PLAYERS", "setup5p": "5 | PLAYERS",
                                            "setuprtt": "RTT | DRAFT"}.get(icon, ""), icon
        elif icon:
            kind, label, asset = "game", icon, icon
        else:
            kind, label, asset = "text", (text or bid), None
        if asset:
            used_assets.add(asset)
        elements.append(dict(id=bid, group=gid, groupLabel=GROUP_LABEL[gid], kind=kind,
                             label=label, x=x, y=y, w=float(A(s, "width") or 20),
                             h=float(A(s, "height") or 20), asset=asset))
# credit image (Main Nav)
cm = re.search(r'<Image id ?= ?"rttCredit"([^>]*?)/>', xml)
if cm:
    s = cm.group(1); pos = A(s, "position"); x, y, *_ = [float(v) for v in pos.split()]
    elements.append(dict(id="rttCredit", group="Main Nav", groupLabel="Credit", kind="credit",
                         label="+ MrDrouf & Claude", x=x, y=y,
                         w=float(A(s, "width") or 52), h=float(A(s, "height") or 10),
                         asset="rttCreditImg"))
    used_assets.add("rttCreditImg")

print("elements:", len(elements), " assets to inline:", len(used_assets))
asset_uris = {}
for name in sorted(used_assets):
    url = assets.get(name)
    if not url:
        continue
    u = fetch(url, maxw=256)
    if u:
        asset_uris[name] = u
board_uri = fetch(board_url, maxw=1100)
print("board texture inlined:", bool(board_uri))

DATA = json.dumps(dict(elements=elements, assets=asset_uris, board=board_uri,
                       bounds=dict(x0=-98, x1=122, y0=-92, y1=92), sx=3.2, sy=3.0),
                  separators=(",", ":"))

HTML = open(os.path.join(ROOT, "tools", "editor_template.html"), encoding="utf-8").read()
HTML = HTML.replace("/*DATA*/null/*DATA*/", DATA)
open(OUT, "w", encoding="utf-8").write(HTML)
print("wrote", OUT, "(%.1f MB)" % (len(HTML) / 1e6))
