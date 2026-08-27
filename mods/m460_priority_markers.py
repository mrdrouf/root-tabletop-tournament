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

-- Marsh number tokens (priority order, skip-excluded-and-renumber).
--
-- The 15 Marsh clearings have a FIXED priority RANK (RTT_MARSH_RANK, world x,y,z, rank 1
-- first — recorded by Adrien, cross-checked against m440's suit positions). Exactly 3 are
-- inactive each game: the flooded sides in 4-player, the town-landmark clearings in
-- 5-player. Both mods export the 3 inactive clearing CENTRES as RTT_MARSH_EXCLUDED (world
-- x,z). We walk the ranks; an excluded clearing gets NO token and does NOT consume a
-- number — every ACTIVE clearing takes the next consecutive number 1..12 in rank order.
-- So the numbers stay consecutive across the 12 active clearings and "shift up" past any
-- excluded clearing, exactly per Adrien's rule.
--
-- RTT_MARSH_NUMJSON[n] is a full number-token JSON with number n's art baked in; we spawn
-- it at the clearing's centre, upright (rotY 180, uniform so every number reads the same
-- way), locked, tagged "Map Object" so the next map build clears it.
RTT_MARSH_RANK = {
  { -13.504, 11.739,   5.340 },   -- 1  pair A.up  (Adrien: "the current 2 should be 1")
  { -23.584, 11.719,  19.613 },   -- 2  FIX7
  {  -2.042, 11.719,  21.443 },   -- 3  FIX8
  {   5.947, 11.717,  20.588 },   -- 4  pair C.up
  {  16.941, 11.719,  11.653 },   -- 5  FIX6
  {  -0.718, 11.719,  -0.272 },   -- 6  FIX4
  {   6.024, 11.719,   2.893 },   -- 7  FIX5
  {  17.342, 11.695,   0.101 },   -- 8  pair B.up
  { -17.795, 11.742,  -5.680 },   -- 9  pair A.down
  {   3.811, 11.711,  -8.597 },   -- 10 pair B.down
  { -17.962, 11.719, -13.523 },   -- 11 FIX2
  { -11.094, 11.719, -16.054 },   -- 12 FIX1
  {   3.512, 11.710, -14.611 },   -- 13 pair C.down
  {  21.347, 11.684, -16.915 },   -- 14 FIX0
  {  22.784, 11.719, -11.850 },   -- 15 FIX3
}

function rttSpawnMarshNumbers()
  for _, o in ipairs(RTT_PRIO_PIECES or {}) do
    if o ~= nil then pcall(function() o.destruct() end) end
  end
  RTT_PRIO_PIECES = {}
  local excl = RTT_MARSH_EXCLUDED or {}
  local n = 0
  for _, cl in ipairs(RTT_MARSH_RANK) do
    local isEx = false
    for _, e in ipairs(excl) do
      local dx, dz = cl[1] - e[1], cl[3] - e[2]
      if dx * dx + dz * dz < 4.0 then isEx = true break end   -- within 2u = this clearing
    end
    if not isEx then
      n = n + 1
      local j = RTT_MARSH_NUMJSON[n]
      if j ~= nil then
        local ob = spawnObjectJSON({
          json = j,
          position = { cl[1], cl[2] + 0.10, cl[3] },
          rotation = { 0, 180, 0 },
          callback_function = function(o)
            o.setLock(true)
            o.addTag("Map Object")
          end
        })
        RTT_PRIO_PIECES[#RTT_PRIO_PIECES + 1] = ob
      end
    end
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
        # frames(2) lands right after makeMap's synchronous body (removeMapItems +
        # spawn loop) so the markers appear WITH the map, not a beat later. They lock
        # at their exact Y regardless of when the board finishes loading.
        hooks += ('\n  if id == "%s" then Wait.frames(function() rttSpawnPriority(%s) end, 2) end'
                  % (map_id, var))

    # Marsh: build one number-token blob per number 1..12 (the recorded tokens carry the
    # number art in their ImageURL; the last 10 hex of the URL identify the number). We keep
    # the FIRST blob seen for each number as its template; rttSpawnMarshNumbers positions it.
    # frames(3) lands just after m440/m500 populated RTT_MARSH_EXCLUDED (the 3 inactive
    # clearing centres — floods in 4p, town landmarks in 5p).
    marsh_blobs = json.load(open(os.path.join(here, MARSH_FILE), encoding="utf-8"))
    tail_to_num = {
        "1C24318F94": 1, "72D8CCFF74": 2, "879513DBA4": 3, "B7BAE69223": 4,
        "E3B097D915": 5, "DBCF32B159": 6, "6202A69044": 7, "68BFCDB7BE": 8,
        "C3CA075A3D": 9, "AB9749D814": 10, "AB5AAE216C": 11, "FD58E42814": 12,
    }
    by_num = {}
    for b in marsh_blobs:
        ob = json.loads(b)
        url = (ob.get("CustomImage", {}) or {}).get("ImageURL", "").rstrip("/")
        num = tail_to_num.get(url[-10:])
        if num is not None and num not in by_num:
            by_num[num] = b
    missing = [n for n in range(1, 13) if n not in by_num]
    if missing:
        raise framework.BuildError("Marsh number token(s) missing art for: %r" % missing)
    lua += "\nRTT_MARSH_NUMJSON = {\n%s\n}\n" % ",\n".join(
        "[%d] = [==[%s]==]" % (n, by_num[n]) for n in range(1, 13))
    hooks += ('\n  if id == "%s" then Wait.frames(function() rttSpawnMarshNumbers() end, 3) end'
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
