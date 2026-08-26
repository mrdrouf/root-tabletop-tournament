"""
m480 — replace the "RTT DRAFT" text button with two image buttons: Ranked + Theme.

Adrien composited the owl ("Ranked") and fox ("Theme") art and uploaded them to his
TTS Steam Cloud; the URLs below are the resulting steamusercontent links (recovered +
content-verified from the local Mods/Images cache). UI-button icons only render from
Steam-hosted URLs, so these must be steamusercontent (not our jsDelivr/GitHub assets).

  * Ranked (owl)  -> onclick rttSetup  (starts the ranked draft — same as the old button)
  * Theme  (fox)  -> onclick rttTheme  (placeholder until Adrien says what Theme does)

Two buttons, side by side, on the top line of the setup screen.
"""
import json
import os

from . import framework

NAME = "RTT setup: Ranked (owl) + Theme (fox) image buttons on the top line"

RANKED_URL = "https://steamusercontent-a.akamaihd.net/ugc/16567688693709882664/AE51F3B4977DA19D27182286AC65854B2F284FE7/"
THEME_URL = "https://steamusercontent-a.akamaihd.net/ugc/10888766596693367672/E05EBC26AA0D8A1F55E6D861EF1E3D01CC07C803/"

THEME_LUA = r"""
function rttTheme(player, value, id)
  -- Theme mode: action TBD (placeholder until Adrien specifies what Theme does).
end
"""

RANKED_BTN = ('<Button id="rttRankedBtn" onclick="rttSetup" icon="RankedButton" '
              'position="-22 58 -20" width="36" height="44"/>')
THEME_BTN = ('<Button id="rttThemeBtn" onclick="rttTheme" icon="ThemeButton" '
             'position="22 58 -20" width="36" height="44"/>')


def apply(text):
    # register the two Steam-hosted button images as named UI assets
    text = framework.add_custom_ui_asset(text, "RankedButton", RANKED_URL)
    text = framework.add_custom_ui_asset(text, "ThemeButton", THEME_URL)

    # drop the old "RTT DRAFT" text button
    text, n = framework.remove_xml_buttons(text, "rttSetup")
    if n == 0:
        raise framework.BuildError("rttSetup button not found to replace")

    # add the two image buttons on the setup screen's top line
    text = framework.add_button_to_group(text, "setupButtons", RANKED_BTN)
    text = framework.add_button_to_group(text, "setupButtons", THEME_BTN)

    # rttTheme stub
    anchor = "function makeMap(player,value,id)"
    if text.count(anchor) != 1:
        raise framework.BuildError("makeMap anchor not unique")
    text = text.replace(anchor, framework.esc(THEME_LUA) + anchor, 1)
    return text
