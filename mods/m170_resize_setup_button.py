"""
m170 — make the standard-setup button the same size as the other options.

"Setup All" (onclick=setupFactionBoards) — the button that runs the standard
setup — was height 20 while the other option buttons on that screen are height 40.
Set it to 40 so it matches.
"""

from . import framework

NAME = "resize the standard-setup button (Setup All) to match the other options"


def apply(text):
    text, n = framework.set_button_attr(text, "Setup All", "height", "40")
    if n == 0:
        raise framework.BuildError("no 'Setup All' button found to resize")
    return text
