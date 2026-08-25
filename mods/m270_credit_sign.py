"""
m270 — the "someone scrawled their name on it" credit, in real handwriting.

The board's baked credit ("Board by Ehss & slugfacekillah", bottom-left) is part
of the texture. We add "+ MrDrouf & Claude" next to it as a hand-added scrawl.

TTS UI text can't use a custom font without a Unity-built TextMeshPro SDF asset
bundle (the `fontStyle` attribute only offers Normal/Bold/Italic). But TTS UI
IMAGES load from any URL — so instead of styled text we render the phrase in a
genuine handwriting font (Windows "Mistral") to a transparent PNG, host it via the
repo's own GitHub raw URL (no manual hosting step — the mod is already pushed
there), register it as a UI image asset on the menu board, and drop it in as an
<Image>. That gives true handwriting, cream-coloured so it reads on the dark wood.

Swap fonts by changing FONT (a matching PNG must exist in assets/credit/); the
image aspect ratio per font is in ASPECT so the overlay isn't stretched.

Position: the bottom-left cell of the tools grid is deliberately left empty for
this corner (see m320); the overlay sits just above the baked credit.
"""

from . import framework

NAME = "hand-added credit: + MrDrouf & Claude (real handwriting image)"

# which handwriting render to use (assets/credit/credit_<FONT>.png), and its w/h aspect
FONT = "mistral"
ASPECT = {
    "mistral": 5.238, "inkfree": 6.853, "segoescript": 7.870,
    "lucida": 7.713, "brush": 5.954,
}

REPO_RAW = "https://raw.githubusercontent.com/mrdrouf/root-tabletop-tournament/main"
ASSET_NAME = "rttCreditImg"

WIDTH = 52  # UI units; height derived from the font's aspect so it isn't stretched


def apply(text):
    # Custom (non-Steam) UI images blank in TTS, so the handwriting IMAGE is disabled;
    # use a small italic TEXT credit that always renders. (Restore the handwriting via
    # a Steam-hosted image once uploaded.)
    txt = ('<Text id="rttCredit" text="+ MrDrouf &amp; Claude" position="-70 84 -22" '
           'rotation="0 0 -6" width="60" height="11" fontSize="7" fontStyle="Italic" '
           'color="#241f18"/>')
    return framework.add_button_to_group(text, "Main Nav", txt)
