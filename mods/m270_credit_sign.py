"""
m270 — the "someone scribbled their name on it" credit.

The board art carries a baked credit, "Board by Ehss & slugfacekillah", in the
bottom-left corner. It's part of the texture, not an element, so we can't edit it.
Instead we lay a little TTS <Text> over the board next to it — deliberately
crooked, off-colour and cramped, as if a kid grabbed a marker and added his own
name to the thing:  "+ MrDrouf & Claude".

It lives in the always-on "Main Nav" group so it shows on every menu page. The
position is an estimate of where the baked credit sits (coord space Y -85..85,
X -90..117); nudge `SIGN` if it doesn't land right next to it in TTS.
"""

from . import framework

NAME = "childish hand-added credit: + MrDrouf & Claude"

# tilted, bold, crammed in at a slight angle in a crayon-blue — looks hand-added,
# not typeset. &amp; is the XML escape for &.
SIGN = (
    '<Text id="rttCredit" text="+ MrDrouf &amp; Claude" '
    'position="-40 -80 -22" rotation="0 0 -8" '
    'width="150" height="24" fontSize="16" fontStyle="Bold" color="#4f6fe0"/>'
)


def apply(text):
    return framework.add_button_to_group(text, "Main Nav", SIGN)
