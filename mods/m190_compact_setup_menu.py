"""
m190 — compact the Setups menu; drop the dead Tools nav.

After all the removals, the "Tools" left-nav page (toolsButtons) is empty — it
"leads to nothing" — and the Setups screen has only 5 buttons scattered with big
gaps. So:

- remove the "Tools" nav buttons (toolsButtonMain, toolsButton), which open the
  now-empty Tools page. The remaining rule tools already live on the Setups page.
- pack the 5 Setups buttons into a tight top grid (4 across, Setup All below).

Layout is a best-effort first pass — verify in TTS and nudge as needed.
"""

from . import framework

NAME = "compact the Setups menu and remove the empty Tools nav"

# tight grid: options across the top row, Setup All beneath.
# (Hirelings is removed by m220, so it's not placed here.)
LAYOUT = {
    "Vagabond Cards":      "-25 45 -20",
    "Landmarks":           "15 45 -20",
    "Clearing Priorities": "55 45 -20",
    "Setup All":           "-25 5 -20",
}


def apply(text):
    # the Tools nav opens the now-empty Tools page ("leads to nothing")
    for nav in ("toolsButtonMain", "toolsButton"):
        text, _ = framework.remove_xml_buttons(text, nav)
    # pack the Setups buttons (scoped to the setupButtons group)
    for bid, pos in LAYOUT.items():
        text, n = framework.set_button_position_in_group(text, "setupButtons", bid, pos)
        if n == 0:
            raise framework.BuildError("Setups button not found: %r" % bid)
    return text
