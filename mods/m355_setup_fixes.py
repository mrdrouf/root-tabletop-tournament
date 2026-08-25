"""
m355 — apply the requested setup changes (runs just before m350 applies the layout).

 - Remove the 4-player (Setup All) and 5-player (fivePlayerSetup) options; only the
   RTT draft stays up top.
 - Swap the three square references (Vagabond Cards, Landmarks, Clearing Priorities)
   to aspect-corrected 2:1 icons so they don't stretch in the half-tiles. Vagabond
   Cards also loses its baked "VB Cards for Drafting" text (cropped to the fan).
"""
from . import framework

NAME = "remove 4p/5p setup; aspect-fit the square references"

REPO_RAW = "https://raw.githubusercontent.com/mrdrouf/root-tabletop-tournament/main"
# button id -> (asset name, png in assets/icons_fit/)
FIT = [
    ("Vagabond Cards", "vbcardsFit", "vbcards.png"),
    ("Landmarks", "landmarksFit", "landmarks.png"),
    ("Clearing Priorities", "clearingFit", "clearing.png"),
]


def apply(text):
    for bid in ("Setup All", "fivePlayerSetup"):
        text, n = framework.remove_xml_buttons(text, bid)
        if n == 0:
            raise framework.BuildError("setup button to remove not found: %r" % bid)
    # References -> plain TEXT rectangle buttons. The original 1:1 icons look wrong in
    # the row (square/stretched) and custom fit-icons blank in TTS; a text label is
    # reliable, always visible, and keeps the half-tile rectangle shape.
    text = framework.replace_unique(text, 'icon =\\"Vagabond Cards\\"', 'text=\\"Vagabond Cards\\"')
    text = framework.replace_unique(text, 'icon =\\"Landmarks\\"', 'text=\\"Landmarks\\"')
    text = text.replace('icon=\\"Clearing Priorities Big\\"', 'text=\\"Clearing Priorities\\"')
    for bid in ("Vagabond Cards", "Landmarks", "Clearing Priorities"):
        text, _ = framework.set_button_attr(text, bid, "fontSize", "6")
    return text
