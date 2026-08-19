"""
m270 — the "someone scribbled their name on it" credit.

The board art carries a baked credit, "Board by Ehss & slugfacekillah", in the
bottom-left corner. It's part of the texture, not an element, so we can't edit it.
Instead we lay a little TTS <Text> over the board just above it, as if someone
scrawled their own name onto the thing:  "+ MrDrouf & Claude".

Look: SMALL (fontSize 6, ~a third of the first attempt), dark ink instead of
loud blue, italic + tilted so it reads as hand-added and unprofessional rather
than typeset. NB: TTS has no handwriting font loaded in this mod (no font asset),
so a genuine cursive would need a hosted .ttf; italic+tilt+small is the closest
approximation without one.

It lives in the always-on "Main Nav" group so it shows on every menu page. The
position sits just above/right of the baked credit (baked credit ~X-84, Y-82);
nudge `SIGN` if it doesn't land right next to it in TTS.
"""

from . import framework

NAME = "hand-added credit: + MrDrouf & Claude (small, italic, tilted)"

# small, dark, italic, tilted — a cramped hand-added scrawl, not a banner.
# &amp; is the XML escape for &.
SIGN = (
    '<Text id="rttCredit" text="+ MrDrouf &amp; Claude" '
    'position="-63 -72 -22" rotation="0 0 -8" '
    'width="60" height="11" fontSize="6" fontStyle="Italic" color="#241f18"/>'
)


def apply(text):
    return framework.add_button_to_group(text, "Main Nav", SIGN)
