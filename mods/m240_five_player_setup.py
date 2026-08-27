"""
m240 — add a 5-player setup button.

setupFactionBoards spawns the faction selectors. Make it spawn 4 or 5 boards
depending on which button called it (the 5-player button passes id
"fivePlayerSetup"), and add that button next to "Setup All" on the Setups screen.

The 5th seat uses the far-middle position already in the seat arrays (0, 46), so
the layout is 2 near corners + 3 across the far side.

ART: Adrien's top-down 5-player setup image (assets/images/5players.png, 850x1000 RGBA)
uploaded to his TTS Steam Cloud; URL recovered from the Mods/Images cache by SHA1. UI
icons only render from Steam-hosted RGBA, which this is.
"""

from . import framework

NAME = "add a 5-player setup button (spawns 5 selectors; top-down art)"

# Steam-hosted RGBA (D7F3C16E… = SHA1 of assets/images/5players.png, portrait 850x1000)
FIVE_URL = "https://steamusercontent-a.akamaihd.net/ugc/13228007358041271497/D7F3C16E093B57844CA249AAEEF2D59C0219B76D/"

# portrait art (aspect ~0.85): keep the button a touch taller than wide so it isn't squished
FIVE_BUTTON = (
    '<Button id="fivePlayerSetup" onclick="setupFactionBoards" icon="FivePlayerArt" '
    'color="#00000000" position="15 5 -20" width="40" height="47"/>'
)


def apply(text):
    text = framework.add_custom_ui_asset(text, "FivePlayerArt", FIVE_URL)
    text = framework.replace_unique(
        text, "function setupFactionBoards()",
        framework.esc(
            'function setupFactionBoards(player, value, id)\n'
            '  local count = 4\n'
            '  if id == "fivePlayerSetup" then count = 5 end'))
    text = framework.replace_unique(text, "for i = 1, 4 do", "for i = 1, count do")
    text = framework.add_button_to_group(text, "setupButtons", FIVE_BUTTON)
    return text
