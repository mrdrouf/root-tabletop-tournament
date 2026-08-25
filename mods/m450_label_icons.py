"""
m450 — reformatted VB Cards / Landmarks option icons (art left, name right).

The base "Vagabond Cards" and "Landmarks" icons are 1:1 squares with the name
baked across the bottom, so they look squished and redundant in the 2:1 option
boxes. We compose new 2:1 icons matching the Battle Mat style — the original art
on the left with the caption cropped off, and the name on the right set in Root's
own Mason typeface (cream with a black outline) — and repoint the icons at them.

The images live in assets/labels/ and are served via jsDelivr (fresh URLs, so any
stale TTS cache of the old blanked UI images is bypassed). Custom UI images have
been unreliable in TTS before; if either blanks, fall back to an in-XML text label.
"""
from . import framework

NAME = "reformat VB Cards / Landmarks icons (art + Mason name, like Battle Mat)"

BASE = "https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/assets/labels/"


def apply(text):
    text = framework.set_ui_asset_url(text, "Vagabond Cards", BASE + "vagabond_crafting.png")
    text = framework.set_ui_asset_url(text, "Landmarks", BASE + "landmarks_label.png")
    return text
