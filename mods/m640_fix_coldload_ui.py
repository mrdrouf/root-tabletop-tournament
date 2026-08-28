"""
m640 — fix the cold-load "setup board shows nothing until you load twice" bug.

Root cause (diagnosed + verified): the setup board (bab7e1) onLoad calls
`self.UI.setCustomAssets(assets)` inside `Wait.frames(..., 100)`. That call is
100% redundant -- the board's SAVED CustomUIAssets already carries all 541 icons
with identical names AND URLs (verified byte-for-byte, incl. ThemeArt/RankedArt/
FivePlayerArt), so TTS renders the static setupButtons XmlUI from them on its own.

On a COLD (uncached) session the frame-100 call fires long before the 541 Steam
assets have downloaded; setCustomAssets REPLACES the live asset table with one whose
URLs are all still unresolved and forces a re-resolve, blanking the just-rendered
buttons -- and TTS does not re-render that object UI as the downloads finish, so it
stays blank for the whole first session. A 2nd (warm) load resolves instantly => the
"load twice" symptom. Removing the call leaves TTS's own progressive render of the
saved assets intact (m510 recorded exactly that: icons render, then blank when the
call fires). m510 becomes a harmless no-op (its 3 table entries just go unused).

Only the real onLoad call is touched: it is single-escaped (\\n) and unique; the two
other setCustomAssets uses live in embedded objects (double-escaped, \\r\\n) and are
left alone.
"""

from . import framework

NAME = "drop onLoad's redundant setCustomAssets (blanks the whole setup UI on a cold load)"

OLD_LUA = (
    "Wait.frames(\n"
    "      function()\n"
    "        self.UI.setCustomAssets(assets)\n"
    "      end,\n"
    "     100\n"
    "    )"
)

NEW_LUA = (
    "-- RTT m640: onLoad setCustomAssets removed (cold-load blank fix). The saved\n"
    "    -- CustomUIAssets already carries all 541 icons (identical names + URLs), so the\n"
    "    -- setup UI renders from them directly; this frame-100 table-replace fired before\n"
    "    -- the Steam assets finished downloading on a cold cache and blanked the buttons\n"
    "    -- with no re-render (only a 2nd/warm load recovered)."
)


def apply(text):
    return framework.replace_unique(text, framework.esc(OLD_LUA), framework.esc(NEW_LUA))
