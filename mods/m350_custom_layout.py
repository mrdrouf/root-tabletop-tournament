"""
m350 — apply YOUR layout from the Board Studio editor.

If tools/user_layout.json exists (the JSON you export from the editor and I save
here), this runs last and applies your exact positions and sizes to every piece,
overriding the built-in layout. For plaques and the credit, if you changed the
text it re-renders that art (same filename, so the GitHub-raw URL serves it).

No file -> no-op (the built-in layout stands).
"""
import json
import os
import sys

from . import framework

NAME = "apply user layout from the Board Studio editor"

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LAYOUT = os.path.join(ROOT, "tools", "user_layout.json")
sys.path.insert(0, os.path.join(ROOT, "tools"))

# element id -> (plaque png, default "big|small")
PLAQUE_FILE = {
    "Setup All": ("setup_4p.png", "4|PLAYERS"),
    "fivePlayerSetup": ("setup_5p.png", "5|PLAYERS"),
    "rttSetup": ("setup_rtt.png", "RTT|DRAFT"),
}
CREDIT_DEFAULT = "+ MrDrouf & Claude"
CREDIT_FONT = "mistral"


def apply(text):
    if not os.path.exists(LAYOUT):
        return text
    import render_assets
    layout = json.load(open(LAYOUT, encoding="utf-8"))

    for e in layout["elements"]:
        eid, grp, kind = e["id"], e["group"], e.get("kind")
        pos = "%g %g -20" % (e["x"], e["y"])
        if kind == "credit":
            # the credit is now a <Text> element (custom UI images blank in TTS)
            text, _ = framework.set_xml_attr(text, "Text", eid, "position", pos)
            continue
        # buttons (setups / maps / decks / tools)
        text, n = framework.set_button_position_in_group(text, grp, eid, pos)
        if n == 0:
            raise framework.BuildError("layout: button not found %r in %r" % (eid, grp))
        for attr, val in (("width", "%g" % e["w"]), ("height", "%g" % e["h"])):
            text, _ = framework.set_button_attr_in_group(text, grp, eid, attr, val)
        # re-render a plaque whose text changed
        if kind == "plaque" and eid in PLAQUE_FILE:
            png, default = PLAQUE_FILE[eid]
            label = (e.get("label") or "").replace("\n", "|")
            if label and label != default:
                parts = [p.strip() for p in label.split("|")]
                big = parts[0] if parts else ""
                small = parts[1] if len(parts) > 1 else ""
                render_assets.render_plaque(big, small, os.path.join(ROOT, "assets", "buttons", png))
    return text
