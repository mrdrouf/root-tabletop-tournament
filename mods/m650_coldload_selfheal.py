"""
m650 — cold-load self-heal: repaint bab7e1's setup UI a few seconds after load so the
brand-new (uncached) personal-upload icons appear on the FIRST session, without a manual
2nd load. Additive only: it appends two Wait.time repaints after the setup branch's
Turns.order line (which sits after `assets` is built). Deletes nothing; runs only in the
setup (!= "Faction Board") branch, so runtime clones (solo Faction Board, seat selectors)
are never touched.

Pairs with the m640 revert (base onLoad setCustomAssets call restored). `assets` is the
global onLoad table (m510 already rides ThemeArt/RankedArt/FivePlayerArt at its head, m540
repoints FivePlayerArt's URL), so re-registering it + re-applying the saved XmlUI forces a
repaint with the now-downloaded textures. 6s/14s are heuristics — tune on a real cold launch.
"""
from . import framework

NAME = "cold-load self-heal: delayed setup-UI repaint (no manual 2nd load)"

# raw-escaped Turns.order line inside the setup branch (unique; count == 1)
ANCHOR = ('Turns.order =   {' + framework.QT + 'Red' + framework.QT + ',' +
          framework.QT + 'Yellow' + framework.QT + ',' +
          framework.QT + 'Orange' + framework.QT + ',' +
          framework.QT + 'Teal' + framework.QT + ',' +
          framework.QT + 'Green' + framework.QT + ',' +
          framework.QT + 'Brown' + framework.QT + '}')

# literal Lua appended right after the anchor (esc() handles JSON-escaping)
SELFHEAL = (
    "\n    Wait.time(function()"
    " if self ~= nil and self.UI ~= nil then"
    " self.UI.setCustomAssets(assets);"
    " self.UI.setXml(self.UI.getXml(), assets) end end, 6)"
    "\n    Wait.time(function()"
    " if self ~= nil and self.UI ~= nil then"
    " self.UI.setXml(self.UI.getXml(), assets) end end, 14)"
)


def apply(text):
    n = text.count(ANCHOR)
    if n != 1:
        raise framework.BuildError("m650 Turns.order anchor not unique: %d" % n)
    return text.replace(ANCHOR, ANCHOR + framework.esc(SELFHEAL), 1)
