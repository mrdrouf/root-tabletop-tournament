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

# 150x150 RGBA re-uploads. The earlier 300x300 uploads were RGB, and TTS UI icons
# only render from RGBA (RGB is exactly why the icon flashed then went white). These
# URLs were recovered from the Mods/Images cache by content SHA1 after Adrien uploaded
# the RGBA PNGs (ranked 23F7EB22…, theme FE0894D6…).
RANKED_URL = "https://steamusercontent-a.akamaihd.net/ugc/17736006513028835727/23F7EB2248073953C65D1AAD44636708E9E2DFE1/"
THEME_URL = "https://steamusercontent-a.akamaihd.net/ugc/16316853328531788856/FE0894D6BBC40E7876FE4A683368A61FC1B35547/"

THEME_LUA = r"""
function rttTheme(player, value, id)
  -- Theme mode: action TBD (placeholder until Adrien specifies what Theme does).
end
"""

# CRITICAL: a TTS Button's `color` MULTIPLIES the icon sprite (it is a tint, not a
# backdrop). Every working faction icon uses a BRIGHT tint (Marquise #d77435, Lizard
# #e8e138, …) because those icons are light silhouettes. Our owl/fox art is a full-colour
# opaque image, so it must be tinted WHITE (#ffffff = neutral) or it renders as-is.
# The old dark tints (#030310 / #474F4B) multiplied the art down to near-black = invisible
# — THAT was the two-day "art doesn't appear" bug, not the RGB/RGBA or the URL.
RANKED_BTN = ('<Button id="rttRankedBtn" onclick="rttSetup" icon="RankedArt" color="#ffffff" '
              'position="-20 60 -20" width="34" height="34"/>')   # square, matching the map buttons
THEME_BTN = ('<Button id="rttThemeBtn" onclick="rttTheme" icon="ThemeArt" color="#ffffff" '
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
