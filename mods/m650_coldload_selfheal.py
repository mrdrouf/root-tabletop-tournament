"""
m650 — cold-load: SIMULATE THE SECOND LOAD (Adrien's suggestion).

On a cold load the setup board's custom-UI icons are not yet on disk, so TTS draws the
buttons blank and never repaints them -- only a manual 2nd load (assets now cached) fixes
it. Re-applying the UI from Lua (setXml / setCustomAssets) does NOT fix it (tried, failed):
the object has to be re-instantiated, which is exactly what a 2nd load does.

So we do that automatically, ONCE: a few seconds after load -- long enough for the small
icon files to finish downloading -- the setup board respawns itself from its own JSON. The
respawned object reads the now-cached assets and renders the buttons, just like the manual
2nd load. Safe because at LOAD (before any draft) nothing else references this board yet.

A Global flag (reset on every real save-load) makes the respawn happen once per load and
stops the respawned board from respawning again (no loop). Pairs with m640 (no frame-100
setCustomAssets), so the respawned board is not re-stomped.
"""
from . import framework

NAME = "cold-load: auto-respawn the setup board once (simulate the 2nd load) so the UI renders"

# raw-escaped Turns.order line inside the setup branch (unique; count == 1)
ANCHOR = ('Turns.order =   {' + framework.QT + 'Red' + framework.QT + ',' +
          framework.QT + 'Yellow' + framework.QT + ',' +
          framework.QT + 'Orange' + framework.QT + ',' +
          framework.QT + 'Teal' + framework.QT + ',' +
          framework.QT + 'Green' + framework.QT + ',' +
          framework.QT + 'Brown' + framework.QT + '}')

# literal Lua appended right after the anchor (esc() handles JSON-escaping)
RESPAWN = (
    "\n    if Global.getVar('RTT_SETUP_REBORN') ~= true then"
    "\n      Wait.time(function()"
    "\n        if self == nil then return end"
    "\n        Global.setVar('RTT_SETUP_REBORN', true)"
    "\n        local _j = self.getJSON()"
    "\n        local _p = self.getPosition()"
    "\n        local _r = self.getRotation()"
    "\n        self.destruct()"
    "\n        spawnObjectJSON({ json = _j, position = _p, rotation = _r })"
    "\n      end, 10)"
    "\n    end"
)


def apply(text):
    n = text.count(ANCHOR)
    if n != 1:
        raise framework.BuildError("m650 Turns.order anchor not unique: %d" % n)
    return text.replace(ANCHOR, ANCHOR + framework.esc(RESPAWN), 1)
