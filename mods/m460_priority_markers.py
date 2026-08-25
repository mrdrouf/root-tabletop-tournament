"""
m460 — auto-place the clearing-priority markers per map (fixed layout).

Adrien positions the 12 priority markers on a map's clearings once; we record their
exact objects (with positions) and re-spawn that same locked layout every time the
map is built. Each map keeps its own recorded set in mods/_priority_<map>.json.

On the map's spawn, rttSpawnPriority destructs the previous set (tag-independent) and
spawns the recorded markers at their exact saved positions, locked, tagged "Map Object"
so a later map build clears them. To add another map: place the 12 markers on it, then
save mods/_priority_<key>.json (a JSON array of the marker objects) and add it to MAPS.
"""
import json
import os

from . import framework

NAME = "auto-place fixed clearing-priority markers (Summer/Autumn map)"

# map id  ->  data file (a JSON array of marker object blobs, positions baked in)
MAPS = {
    "Summer Map": "_priority_summer.json",
}

SPAWNER = r"""
RTT_PRIO_PIECES = RTT_PRIO_PIECES or {}

function rttSpawnPriority(jsons)
  for _, o in ipairs(RTT_PRIO_PIECES or {}) do
    if o ~= nil then pcall(function() o.destruct() end) end
  end
  RTT_PRIO_PIECES = {}
  for _, j in ipairs(jsons) do
    local ob = spawnObjectJSON({
      json = j,
      callback_function = function(o)
        o.setLock(true)
        o.addTag("Map Object")
      end
    })
    RTT_PRIO_PIECES[#RTT_PRIO_PIECES + 1] = ob
  end
end
"""


def apply(text):
    here = os.path.dirname(__file__)
    lua = SPAWNER
    hooks = ""
    for map_id, fname in MAPS.items():
        blobs = json.load(open(os.path.join(here, fname), encoding="utf-8"))
        var = "RTT_PRIO_" + "".join(c for c in map_id if c.isalnum()).upper()
        lua += "\n%s = {\n%s\n}\n" % (var, ",\n".join("[==[%s]==]" % b for b in blobs))
        hooks += ('\n  if id == "%s" then Wait.time(function() rttSpawnPriority(%s) end, 0.6) end'
                  % (map_id, var))

    sig = "function makeMap(player,value,id)"
    if text.count(sig) != 1:
        raise framework.BuildError("makeMap anchor not unique")
    text = text.replace(sig, framework.esc(lua) + sig, 1)
    text = text.replace(sig, sig + framework.esc(hooks), 1)
    return text
