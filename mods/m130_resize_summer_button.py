"""
m130 — resize the Summer Map selector button.

The Summer Map button on the selector board was height="20" while every other map
button is height="40". Set it to 40 so it matches the others. (Its position is a
separate concern handled by the menu-compaction step.)
"""

from . import framework

NAME = "resize the Summer Map selector button to match the other map buttons"


def apply(text):
    text, n = framework.set_button_attr(text, "Summer Map", "height", "40")
    if n == 0:
        raise framework.BuildError("no Summer Map button found to resize")
    return text
