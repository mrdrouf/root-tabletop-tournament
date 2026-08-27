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
  -- Theme = ranked draft, but the pool is 1 mandatory Militant + ALL Insurgents (no extra
  -- Militants). Everything else (deal, pick, faction phase) is identical to ranked.
  RTT_THEME = true
  rttSetup(player, value, id)
end
"""

# in rttSetup, skip adding the leftover Militants to the pool when Theme is active (leaving
# 1 Militant `first` + all Insurgents), then clear the flag.
THEME_POOL_OLD = "for i=2,#mil do pool[#pool+1]=mil[i] end"
THEME_POOL_NEW = "if not RTT_THEME then for i=2,#mil do pool[#pool+1]=mil[i] end end RTT_THEME = nil"

# CRITICAL: a TTS Button's `color` MULTIPLIES the icon sprite (it is a tint, not a
# backdrop). Every working faction icon uses a BRIGHT tint (Marquise #d77435, Lizard
# #e8e138, …) because those icons are light silhouettes. Our owl/fox art is a full-colour
# opaque image, so it must be tinted WHITE (#ffffff = neutral) or it renders as-is.
# The old dark tints (#030310 / #474F4B) multiplied the art down to near-black = invisible
# — THAT was the two-day "art doesn't appear" bug, not the RGB/RGBA or the URL.
# now that the icons load (m510), the Button color shows as the frame/rounded-corners
# behind the icon (like the map buttons) — set it to each art's dominant/edge colour so the
# frame blends with the art instead of a white box.
# x=-19/19 = the two central map-button columns directly below, so Ranked sits exactly above
# the map button under it (was -20/20, off by 1 = the "not perfectly aligned" report).
RANKED_BTN = ('<Button id="rttRankedBtn" onclick="rttSetup" icon="RankedArt" color="#030411" '
              'position="-19 60 -20" width="34" height="34"/>')   # square, matching the map buttons
THEME_BTN = ('<Button id="rttThemeBtn" onclick="rttTheme" icon="ThemeArt" color="#49514b" '
             'position="19 60 -20" width="34" height="34"/>')


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

    # rttTheme
    anchor = "function makeMap(player,value,id)"
    if text.count(anchor) != 1:
        raise framework.BuildError("makeMap anchor not unique")
    text = text.replace(anchor, framework.esc(THEME_LUA) + anchor, 1)

    # Theme pool = insurgents only (+ the 1 mandatory Militant already chosen as `first`)
    text = framework.replace_unique(text,
        framework.esc(THEME_POOL_OLD), framework.esc(THEME_POOL_NEW))
    return text
