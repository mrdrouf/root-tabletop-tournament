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

# small square (300x300) re-uploads — the 1.2MB versions flashed to white in TTS UI
RANKED_URL = "https://steamusercontent-a.akamaihd.net/ugc/10170717684162208036/7455ACC11074D6DB3A1A1F2B82A1201278E17910/"
THEME_URL = "https://steamusercontent-a.akamaihd.net/ugc/11172983172019187774/BA2ECDEF528ACA13DFA424A6D0EBC127BD8A5CBF/"

THEME_LUA = r"""
function rttTheme(player, value, id)
  -- Theme mode: action TBD (placeholder until Adrien specifies what Theme does).
end
"""

RANKED_BTN = ('<Button id="rttRankedBtn" onclick="rttSetup" icon="RankedArt" '
              'position="-20 60 -20" width="34" height="34"/>')   # square, matching the map buttons
THEME_BTN = ('<Button id="rttThemeBtn" onclick="rttTheme" icon="ThemeArt" '
             'position="20 60 -20" width="34" height="34"/>')


def apply(text):
    # register the two Steam-hosted button images as named UI assets
    text = framework.add_custom_ui_asset(text, "RankedArt", RANKED_URL)
    text = framework.add_custom_ui_asset(text, "ThemeArt", THEME_URL)

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
