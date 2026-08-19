"""
m330 — consistent plaques for the three setup ACTIONS.

The setups row mixed real icon-thumbnails (Vagabond Cards, Landmarks, Clearing
Priorities) with flat dark text buttons (Standard Setup / 5 Players / RTT Setup) —
the text buttons looked unfinished and broke the row. Give the three setup actions
matching wooden plaques ("4 PLAYERS", "5 PLAYERS", "RTT DRAFT", rendered in
assets/buttons/, hosted via the repo's GitHub raw URL) so the row reads as a
deliberate set. Same hosting trick as the handwriting credit — no font bundle,
just images.
"""

from . import framework

NAME = "setup action plaques: 4 Players / 5 Players / RTT Draft"

REPO_RAW = "https://raw.githubusercontent.com/mrdrouf/root-tabletop-tournament/main"
PLAQUES = [  # (asset name, png, target button id, old text to replace or None if icon)
    ("setup4p", "setup_4p.png", "Setup All", None),
    ("setup5p", "setup_5p.png", "fivePlayerSetup", "5 Players"),
    ("setuprtt", "setup_rtt.png", "rttSetup", "RTT Setup"),
]


def apply(text):
    for name, png, _bid, _old in PLAQUES:
        url = "%s/assets/buttons/%s" % (REPO_RAW, png)
        text = framework.add_custom_ui_asset(text, name, url)

    # Setup All already has icon="SixPack" -> swap it
    text, n = framework.set_button_attr(text, "Setup All", "icon", "setup4p")
    if n == 0:
        raise framework.BuildError("Setup All button not found")

    # the other two are text buttons -> turn text into an icon (drops the text)
    for name, _png, _bid, old in PLAQUES:
        if old is None:
            continue
        text = framework.replace_unique(
            text, framework.esc('text="%s"' % old), framework.esc('icon="%s"' % name))
    return text
