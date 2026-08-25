"""
m380 — keep the per-player faction selectors clean.

makeFactionSelector / setupFactionBoards CLONE the main menu board, so the clones
inherit our one-page defaults (maps + decks + tools all active — m280). The base's
`configureFactionBoard` turns Main Nav / setupButtons off on a clone but never the
map/deck/tool groups, so they leaked onto the faction selectors ("mishmashed").
Turn them off there too, so a faction selector shows only the faction grid.
"""
from . import framework

NAME = "faction selector clones: turn off maps/decks/tools (no mishmash)"

ANCHOR = 'board.UI.setAttribute("setupButtons", "active", "False")'
ADD = "".join(
    '\n  board.UI.setAttribute("%s", "active", "False")' % g
    for g in ("mapButtonsStandard", "decksButtonsStandard", "toolsButtons", "tools1"))


def apply(text):
    return framework.replace_unique(text, framework.esc(ANCHOR), framework.esc(ANCHOR + ADD))
