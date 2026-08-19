"""
m320 — clean up the menu: tidy tool grid + fix two button bugs.

From the screenshot the tools were scattered and straddled the baked "TTS Tools by
the ROOT Community" title. A verified design pass produced a single uniform
5-column x 2-row grid seated directly UNDER that baked title (so it reads as the
grid's header), cells 33x14, columns X=-70,-35,0,35,70, rows Y=-60 and Y=-77. The
bottom-LEFT cell is left empty on purpose — the baked credit (and our handwriting
overlay) own that corner — and "More" takes the bottom-right (next-page) corner.

Also fixes, root-caused in the build:
 - Two <Button> share id="Clearing Priorities" (icons "…Big" and "…Small"), so
   m280 drove BOTH to (-15,70) and they z-fought. Keep one (delete the "Small").
 - "5 Players" wrapped to "5 Player / s": it was left at fontSize 8 in a 34-wide
   box. Drop it to 7 (its 9-char neighbour "RTT Setup" already fits at 7).
"""

from . import framework

NAME = "menu cleanup: uniform tool grid + Clearing Priorities / 5 Players fixes"

# tool button id -> (x, y) in the 5x2 grid under the baked title
TOOL_GRID = {
    "Faction Select": (-70, -60), "Battle Mat": (-35, -60),
    "Clearing Markers": (0, -60), "Swol Birbs": (35, -60), "Mob Lobber": (70, -60),
    "Lizard Wizard": (-35, -77), "Ginso's Gizmo": (0, -77),
    "Mini-Mood Manager": (35, -77), "moreTools": (70, -77),
}
CELL_W, CELL_H, CELL_FS = "33", "14", "7"


def apply(text):
    # 1. the "more" button has no id — give it one so it can join the grid
    text = framework.replace_unique(
        text,
        framework.esc('<Button onclick="tools2"'),
        framework.esc('<Button id="moreTools" onclick="tools2"'))

    # 2. drop the duplicate Clearing Priorities (keep the "Big", delete the "Small")
    text, n = framework.remove_xml_element(
        text, "Button", 'icon=\\"Clearing Priorities Small\\"')
    if n != 1:
        raise framework.BuildError("expected 1 Clearing Priorities Small button, got %d" % n)

    # 3. lay out the tool grid — position + uniform size, scoped to tools1
    for bid, (x, y) in TOOL_GRID.items():
        text, np = framework.set_button_position_in_group(
            text, "tools1", bid, "%d %d -20" % (x, y))
        if np == 0:
            raise framework.BuildError("tool not found in tools1: %r" % bid)
        for attr, val in (("width", CELL_W), ("height", CELL_H), ("fontSize", CELL_FS)):
            text, _ = framework.set_button_attr_in_group(text, "tools1", bid, attr, val)

    # 4. "5 Players" fits on one line at fontSize 7 (34-wide box unchanged)
    text, n = framework.set_button_attr(text, "fivePlayerSetup", "fontSize", "7")
    if n == 0:
        raise framework.BuildError("fivePlayerSetup button not found")
    return text
