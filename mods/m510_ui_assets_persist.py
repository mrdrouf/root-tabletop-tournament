"""
m510 — keep the 3 custom UI icons registered through onLoad's asset rebuild.

THE root cause of the "art appears then disappears / only shows on the 2nd load" bug
(found Aug 27 2026 via a 4-agent workflow): bab7e1's `onLoad` rebuilds its custom-UI-asset
table from a HARDCODED Lua `assets` list (base assets only, starting at "WWDraftTool") and,
~100 frames (~2 s) after load, calls `self.UI.setCustomAssets(assets)`. `setCustomAssets`
REPLACES the entire table — it does not merge — so it drops the RankedArt / ThemeArt /
FivePlayerArt entries that m480/m240 added to the saved `CustomUIAssets` JSON. The icons
render from the saved assets on load, then blank white a beat later when this fires.

Fix: add the three entries to that hardcoded Lua table so the rebuild re-registers them.
The buttons reference the assets by NAME (icon="RankedArt" …), and setCustomAssets resolves
by name, so a present entry = the icon shows and stays.
"""
from . import framework

NAME = "persist Ranked/Theme/5-player icons through onLoad's setCustomAssets rebuild"

# the first entry of the hardcoded onLoad `assets` table (unique in bab7e1's live Lua)
WWDRAFT = ('        {name = "WWDraftTool", url = "https://steamusercontent-a.akamaihd.net/'
           'ugc/1862809540303472326/2081F779AB2B2A6FA9D15696F6920FE2067BC4C6/"},')

# our three icons (same Steam-hosted RGBA URLs m480/m240 register in CustomUIAssets)
ICONS = (
    '        {name = "ThemeArt", url = "https://steamusercontent-a.akamaihd.net/ugc/16316853328531788856/FE0894D6BBC40E7876FE4A683368A61FC1B35547/"},\n'
    '        {name = "RankedArt", url = "https://steamusercontent-a.akamaihd.net/ugc/17736006513028835727/23F7EB2248073953C65D1AAD44636708E9E2DFE1/"},\n'
    '        {name = "FivePlayerArt", url = "https://steamusercontent-a.akamaihd.net/ugc/13228007358041271497/D7F3C16E093B57844CA249AAEEF2D59C0219B76D/"},\n'
)


def apply(text):
    anchor = framework.esc(WWDRAFT)
    n = text.count(anchor)
    if n != 1:
        raise framework.BuildError("onLoad WWDraftTool assets anchor not unique: %d" % n)
    return text.replace(anchor, framework.esc(ICONS) + anchor, 1)
