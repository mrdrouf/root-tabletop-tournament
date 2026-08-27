"""
m440 — Marsh Map randomised setup, spawned at exact measured positions.

Like the base map, every piece is placed at a precise, known resting position — we
just choose which position randomly each build. makeMap computes rttMarshPlan(objects)
before the spawn loop; for each override piece it supplies the EXACT world position
(x, y, z) measured from Adrien's Marsh Reference save, and the loop spawns straight
there (bypassing the base move_to->world height math, which only fits a piece to its
own original spot). The Marsh board is uneven (suits rest ~11.72, ruins ~11.65, floods
11.56–11.79), so each clearing carries its own measured height — no guessing, no drop.

  * each of the 3 flood markers floods a random up/down clearing (rotZ 0/180);
  * the 2 spare ruins + 3 spare suit markers go to the dry (non-flooded) clearings;
  * ruin ITEMS (4) and ALL 12 clearing suits (4 of each colour) are randomised across
    the 12 active clearings via a correct Fisher-Yates (rttShuffleList) — never the
    base shuffle() (which re-seeds os.time() every loop; see rtt-rng-bug).

Pieces are locked in their spawn callback (they spawn already at rest, so locking is
clean). Removal is tag-independent + in-flight-safe: each handle is recorded
synchronously and the previous build's handles destructed up front.

Flood entries found by tile artwork, ruins by nickname RUIN, suits by "Clearing Marker".
"""
from . import framework

NAME = "Marsh Map: randomise floods + ruins + suits at exact measured positions"

FLOOD_LUA = r"""
-- 9 always-present Marsh clearings: world x, y, z, rotY
RTT_MARSH_SUIT9 = {
  { 21.347, 11.684, -16.915, 75 }, { -11.094, 11.719, -16.054, 225 }, { -17.962, 11.719, -13.523, 30 },
  { 22.784, 11.719, -11.850, 165 }, { -0.718, 11.719, -0.272, 75 }, { 6.024, 11.719, 2.893, 135 },
  { 16.941, 11.719, 11.653, 240 }, { -23.584, 11.719, 19.613, 300 }, { -2.042, 11.719, 21.443, 30 },
}
-- 2 fixed ruin clearings: world x, y, z
RTT_MARSH_RUIN_FIXED = { { 4.435, 11.656, 7.056 }, { -4.046, 11.665, -2.435 } }
-- each marker's two candidate clearings, world positions:
--   flood = { x, y, z, rotZ } (where the marker sits when this side floods)
--   suit  = { x, y, z, rotY } (where a suit sits on this side when it is DRY)
--   ruin  = { x, y, z }       (where a ruin sits when DRY; markers B and C only)
RTT_MARSH = {
  { key = "A", tag = "53E4E9F1",
    up   = { flood = { -11.380, 11.720, 7.150, 0 },   suit = { -13.504, 11.739, 5.340, 225 } },
    down = { flood = { -20.930, 11.790, -2.720, 180 }, suit = { -17.795, 11.742, -5.680, 135 } } },
  { key = "B", tag = "C5C35E37",
    up   = { flood = { 15.910, 11.639, 3.730, 0 },   suit = { 17.342, 11.695, 0.101, 165 }, ruin = { 14.323, 11.641, 3.736 } },
    down = { flood = { 7.200, 11.750, -7.210, 180 }, suit = { 3.811, 11.711, -8.597, 240 }, ruin = { 6.153, 11.649, -6.705 } } },
  { key = "C", tag = "B37C9A48",
    up   = { flood = { 7.700, 11.654, 16.860, 0 },   suit = { 5.947, 11.717, 20.588, 345 }, ruin = { 8.081, 11.653, 15.388 } },
    down = { flood = { 0.880, 11.750, -16.920, 180 }, suit = { 3.512, 11.710, -14.611, 45 }, ruin = { 0.461, 11.654, -19.318 } } },
}

-- correct single-pass Fisher-Yates; NO os.time re-seed
function rttShuffleList(t)
  for i = #t, 2, -1 do
    local j = math.random(i)
    t[i], t[j] = t[j], t[i]
  end
end

function rttMarshPlan(objects)
  RTT_MARSH_N = (RTT_MARSH_N or 0) + 1
  math.randomseed(os.time() + RTT_MARSH_N * 7919)
  for k = 1, 10 do math.random() end

  -- world (x,z) of each clearing that floods this build; m460 uses this to drop the
  -- priority-number token on each flooded (submerged, no-suit) clearing.
  RTT_MARSH_FLOODED = {}
  -- world (x,z) of the CLEARING CENTRE (suit position) that is inactive this build. m460's
  -- number logic matches these against RTT_MARSH_RANK to skip the excluded clearings. The
  -- flood MARKER sits ~2.8u off the clearing centre, so this is the suit slot, not the marker.
  RTT_MARSH_EXCLUDED = {}

  local floodIx = {}
  local ruinIx = {}
  local suitIx = {}
  for idx, v in ipairs(objects) do
    local j = v.json
    if     string.find(j, "53E4E9F1", 1, true) then floodIx["A"] = idx
    elseif string.find(j, "C5C35E37", 1, true) then floodIx["B"] = idx
    elseif string.find(j, "B37C9A48", 1, true) then floodIx["C"] = idx
    elseif string.find(j, "RUIN", 1, true) then ruinIx[#ruinIx + 1] = idx
    elseif string.find(j, "Clearing Marker", 1, true) then suitIx[#suitIx + 1] = idx
    end
  end

  local ov = {}
  local drySuits = {}
  local dryRuins = {}
  for _, m in ipairs(RTT_MARSH) do
    local flooded, dry
    if math.random(2) == 1 then flooded = m.up; dry = m.down else flooded = m.down; dry = m.up end
    RTT_MARSH_FLOODED[#RTT_MARSH_FLOODED + 1] = { flooded.flood[1], flooded.flood[3] }
    RTT_MARSH_EXCLUDED[#RTT_MARSH_EXCLUDED + 1] = { flooded.suit[1], flooded.suit[3] }
    local fi = floodIx[m.key]
    if fi ~= nil then
      local f = flooded.flood
      ov[fi] = { world = { f[1], f[2], f[3] }, rot = { 0, 180, f[4] } }
    end
    local s = dry.suit
    drySuits[#drySuits + 1] = { s[1], s[2], s[3], s[4] }
    if dry.ruin ~= nil then
      local r = dry.ruin
      dryRuins[#dryRuins + 1] = { r[1], r[2], r[3] }
    end
  end

  -- RUINS: 2 fixed + 2 dry world slots; shuffle across the 4 ruin entries (items randomised)
  local ruinSlots = {}
  for _, p in ipairs(RTT_MARSH_RUIN_FIXED) do ruinSlots[#ruinSlots + 1] = { p[1], p[2], p[3] } end
  for _, p in ipairs(dryRuins) do ruinSlots[#ruinSlots + 1] = p end
  rttShuffleList(ruinSlots)
  for i, idx in ipairs(ruinIx) do
    local p = ruinSlots[i]
    if p ~= nil then ov[idx] = { world = { p[1], p[2], p[3] }, rot = nil } end
  end

  -- SUITS: all 12 clearings randomised (4 of each colour) across 9 fixed + 3 dry
  local suitTargets = {}
  for _, p in ipairs(RTT_MARSH_SUIT9) do suitTargets[#suitTargets + 1] = { p[1], p[2], p[3], p[4] } end
  for _, p in ipairs(drySuits) do suitTargets[#suitTargets + 1] = p end
  rttShuffleList(suitTargets)
  for i, idx in ipairs(suitIx) do
    local t = suitTargets[i]
    if t ~= nil then ov[idx] = { world = { t[1], t[2], t[3] }, rot = { 0, t[4], 0 } } end
  end

  return ov
end

"""


def apply(text):
    sig = "function makeMap(player,value,id)"
    if text.count(sig) != 1:
        raise framework.BuildError("makeMap anchor not unique")
    text = text.replace(sig, framework.esc(FLOOD_LUA) + sig, 1)

    # build the plan + clean out the previous build's tracked pieces (in-flight-safe)
    old1 = "objects = EVERYTHING[\"Maps\"][id]['data']"
    new1 = (old1 + "\n  local RTT_OV = nil\n"
            "  if id == \"Marsh Map\" then\n"
            "    for _,o in ipairs(RTT_MARSH_PIECES or {}) do if o ~= nil then pcall(function() o.destruct() end) end end\n"
            "    RTT_MARSH_PIECES = {}\n"
            "    RTT_OV = rttMarshPlan(objects)\n"
            "  end")
    text = framework.replace_unique(text, framework.esc(old1), framework.esc(new1))

    # spawn loop: override pieces spawn at their EXACT measured world position (no height
    # math); everything else keeps the base move_to->world transform.
    old2 = ("  for _,v in ipairs(objects) do\n"
            "    local vec = Vector(v.move_to) * scale\n"
            "    vec.y = vec.y - 0.1\n\n"
            "    vec = vec * Vector({15.5, 1, 15.5})\n\n"
            "    local new_pos = vec\n"
            "    new_pos.y = new_pos.y+10-8.5+0.05-0.07+10.08\n"
            "    new_pos.x = new_pos.x")
    new2 = ("  for idx,v in ipairs(objects) do\n"
            "    local rtt_rot = nil\n"
            "    local rtt_ov = false\n"
            "    local new_pos\n"
            "    if RTT_OV ~= nil and RTT_OV[idx] ~= nil then\n"
            "      rtt_rot = RTT_OV[idx].rot\n"
            "      rtt_ov = true\n"
            "      new_pos = RTT_OV[idx].world\n"
            "    else\n"
            "      local vec = Vector(v.move_to) * scale\n"
            "      vec.y = vec.y - 0.1\n"
            "      vec = vec * Vector({15.5, 1, 15.5})\n"
            "      new_pos = vec\n"
            "      new_pos.y = new_pos.y+10-8.5+0.05-0.07+10.08\n"
            "    end")
    text = framework.replace_unique(text, framework.esc(old2), framework.esc(new2))

    # pass rotation and lock override pieces (they spawn already at rest)
    old3 = ("        json              = v.json,\n"
            "        position          = new_pos,\n"
            "        callback_function = function(spawned_object)\n\n"
            "        if spawned_object.name == \"Bag\" then spawned_object.shuffle() end")
    new3 = ("        json              = v.json,\n"
            "        position          = new_pos,\n"
            "        rotation          = rtt_rot,\n"
            "        callback_function = function(spawned_object)\n\n"
            "        if rtt_ov then spawned_object.setLock(true) end\n"
            "        if spawned_object.name == \"Bag\" then spawned_object.shuffle() end")
    text = framework.replace_unique(text, framework.esc(old3), framework.esc(new3))

    # base bug: table.insert returns nil, so setTags(nil) never adds the tag; use addTag
    old4 = 'spawned_object.setTags(table.insert(spawned_object.getTags(),"Map Object"))'
    new4 = 'spawned_object.addTag("Map Object")'
    text = framework.replace_unique(text, framework.esc(old4), framework.esc(new4))

    # record each override handle synchronously; skip the buggy shuffleMaps for Marsh
    old5 = "    })\n  end\n  shuffleMaps(id)"
    # guard RTT_MARSH_PIECES: it is only initialised for Marsh, but rtt_ov is now also
    # true on Mountain (m500's tower-hide override), so an unguarded #RTT_MARSH_PIECES
    # was `#nil` on Mountain — it crashed makeMap mid-spawn-loop, dropping every suit
    # marker after the tower. The tower carries the "Map Object" tag anyway, so it is
    # cleaned on the next map build without needing to be tracked here.
    new5 = ("    })\n"
            "    if rtt_ov and RTT_MARSH_PIECES ~= nil then RTT_MARSH_PIECES[#RTT_MARSH_PIECES + 1] = ob end\n"
            "  end\n  if id ~= \"Marsh Map\" then shuffleMaps(id) end")
    text = framework.replace_unique(text, framework.esc(old5), framework.esc(new5))
    return text
