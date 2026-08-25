"""
m390 — remove the "made by / by Chris" hover credits.

161 menu buttons call onMouseEnter="info…" -> setInfo(name), which shows a credit
image over the board. Neuter setInfo so hovering shows nothing (clearInfo still
blanks it). One line, kills all of them.
"""
from . import framework

NAME = "remove hover credit pop-ups (neuter setInfo)"

ANCHOR = 'self.UI.setAttribute("info","image",name)'


def apply(text):
    return framework.replace_unique(
        text, framework.esc(ANCHOR), framework.esc("--[[ hover credit removed ]]"))
