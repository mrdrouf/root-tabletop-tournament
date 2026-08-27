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
    "Lake Map": "_priority_lake.json",
    "Mountain Map": "_priority_mountain.json",
    "Winter Map": "_priority_winter.json",
    "Gorge Map": "_priority_gorge.json",
}

# Marsh is special: 15 tokens are recorded (9 always-dry clearings + both sides of the
# 3 flood pairs). Per Adrien's rule "wherever there is a suit marker, there is a number
# token" — the flooded clearings have no suit, so their token is removed. m440 exports
# RTT_MARSH_FLOODED (the 3 flooded world positions); we drop the token nearest each.
MARSH_MAP_ID = "Marsh Map"
MARSH_FILE = "_priority_marsh.json"

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

-- Marsh: spawn all 15 recorded tokens, then remove the token that sits on each flooded
-- clearing (no suit there). RTT_MARSH_FLOODED (set by m440's rttMarshPlan) holds the 3
-- flooded world (x,z). Each flood position has a unique nearest token (~3-4u; the next
-- nearest is 8u+), so the nearest-token deletion is exact — 12 numbered clearings remain.
function rttSpawnPriorityMarsh(jsons)
  for _, o in ipairs(RTT_PRIO_PIECES or {}) do
    if o ~= nil then pcall(function() o.destruct() end) end
  end
  RTT_PRIO_PIECES = {}
  local spawned = {}
  for _, j in ipairs(jsons) do
    local ob = spawnObjectJSON({
      json = j,
      callback_function = function(o)
        o.setLock(true)
        o.addTag("Map Object")
      end
    })
    RTT_PRIO_PIECES[#RTT_PRIO_PIECES + 1] = ob
    spawned[#spawned + 1] = ob
  end
  local flooded = RTT_MARSH_FLOODED or {}
  Wait.time(function()
    for _, fp in ipairs(flooded) do
      local bi, bd = nil, 1e9
      for i, o in ipairs(spawned) do
        if o ~= nil then
          local ok, p = pcall(function() return o.getPosition() end)
          if ok and p ~= nil then
            local dx, dz = p.x - fp[1], p.z - fp[2]
            local d = dx * dx + dz * dz
            if d < bd then bd = d; bi = i end
          end
        end
      end
      if bi ~= nil and bd < 36 then          -- within 6u => this clearing's own token
        pcall(function() spawned[bi].destruct() end)
        spawned[bi] = nil
      end
    end
  end, 0.6)
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
        # frames(2) lands right after makeMap's synchronous body (removeMapItems +
        # spawn loop) so the markers appear WITH the map, not a beat later. They lock
        # at their exact Y regardless of when the board finishes loading.
        hooks += ('\n  if id == "%s" then Wait.frames(function() rttSpawnPriority(%s) end, 2) end'
                  % (map_id, var))

    # Marsh: same timing, but the flood-aware spawner (drops the flooded-clearing tokens).
    # frames(3) lands just after m440's Marsh spawn loop has populated RTT_MARSH_FLOODED.
    marsh_blobs = json.load(open(os.path.join(here, MARSH_FILE), encoding="utf-8"))
    lua += "\nRTT_PRIO_MARSH = {\n%s\n}\n" % ",\n".join("[==[%s]==]" % b for b in marsh_blobs)
    hooks += ('\n  if id == "%s" then Wait.frames(function() rttSpawnPriorityMarsh(RTT_PRIO_MARSH) end, 3) end'
              % MARSH_MAP_ID)

    sig = "function makeMap(player,value,id)"
    if text.count(sig) != 1:
        raise framework.BuildError("makeMap anchor not unique")
    text = text.replace(sig, framework.esc(lua) + sig, 1)
    text = text.replace(sig, sig + framework.esc(hooks), 1)

    # blank the "Priority Marker" nickname on the Clearing-Priorities TOOL markers too
    # (EVERYTHING["Tools"]["Priority Markers"]), so the ones Adrien places via the option
    # show no hover tooltip either. All 43 are Nickname data — no Lua compares the name.
    old_nick = framework.esc('"Nickname": "Priority Marker"')
    new_nick = framework.esc('"Nickname": ""')
    n = text.count(old_nick)
    if n == 0:
        raise framework.BuildError("tool Priority Marker nicknames not found")
    text = text.replace(old_nick, new_nick)
    return text
