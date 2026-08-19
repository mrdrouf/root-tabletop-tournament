"""
m240 — add a 5-player setup button.

setupFactionBoards spawns the faction selectors. Make it spawn 4 or 5 boards
depending on which button called it (the 5-player button passes id
"fivePlayerSetup"), and add that button next to "Setup All" on the Setups screen.

The 5th seat uses the far-middle position already in the seat arrays (0, 46), so
the layout is 2 near corners + 3 across the far side.

ART: this button uses a plain text placeholder ("5 Players"). Real art (a top-down
setup image + a matching-font label) needs to be hosted and its URL supplied — see
the report; same for the 4-player button's new art.
"""

from . import framework

NAME = "add a 5-player setup button (spawns 5 selectors; placeholder art)"

FIVE_BUTTON = (
    '<Button id="fivePlayerSetup" onclick="setupFactionBoards" text="5 Players" '
    'position="15 5 -20" width="40" height="40" fontSize="8" color="#2c231a"/>'
)


def apply(text):
    text = framework.replace_unique(
        text, "function setupFactionBoards()",
        framework.esc(
            'function setupFactionBoards(player, value, id)\n'
            '  local count = 4\n'
            '  if id == "fivePlayerSetup" then count = 5 end'))
    text = framework.replace_unique(text, "for i = 1, 4 do", "for i = 1, count do")
    text = framework.add_button_to_group(text, "setupButtons", FIVE_BUTTON)
    return text
