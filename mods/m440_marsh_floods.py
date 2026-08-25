"""
m440 — Marsh Map randomised setup, spawned directly in place.

Every Marsh build, makeMap computes a random plan (rttMarshPlan) BEFORE the spawn
loop and overrides each piece's move_to + rotation, so pieces appear in their final
randomised spots (no spawn-at-side-then-move):
  * each of the 3 flood markers floods a random up/down clearing;
  * the 2 spare ruins + 3 spare suit markers go to the dry (non-flooded) clearings;
  * ruin ITEMS (4) and ALL 12 clearing suits (4 of each colour) are randomised across
    the 12 active clearings, with a correct Fisher-Yates (rttShuffleList) — never the
    base shuffle() (which re-seeds os.time() every loop; see rtt-rng-bug).

CRUCIAL: pieces are spawned UNLOCKED and locked only AFTER they settle (a delayed
pass). Locking them in the spawn callback froze them mid-drop, so they ended up
inside / under the board (missing floods/suits). The board's own pieces are unlocked
and settle onto the surface; we do the same, then lock 3s later.

Removal is tag-independent and in-flight-safe: every override piece's handle is
recorded synchronously and the previous build's handles are destructed up front (the
base tag path alone misses still-loading tiles on a re-press).

Positions measured from Adrien's Marsh Reference save; flood entries found by their
unique tile artwork, ruins by nickname RUIN, suits by the "Clearing Marker" tag.
"""
from . import framework

NAME = "Marsh Map: randomise floods + ruins + suits, spawn in place, lock after settle"

FLOOD_LUA = r"""
-- the 9 always-present Marsh clearings (move_to x, z, rotY); the other 3 active
-- clearings are the dry sides of markers A/B/C.
RTT_MARSH_SUIT9 = {
  { 21.35, -16.92, 75 }, { -11.09, -16.05, 225 }, { -17.96, -13.52, 30 },
  { 22.78, -11.85, 165 }, { -0.72, -0.27, 75 }, { 6.02, 2.89, 135 },
  { 16.94, 11.65, 240 }, { -23.58, 19.61, 300 }, { -2.04, 21.44, 30 },
}
RTT_MARSH = {
  { key = "A", tag = "53E4E9F1",
    up   = { fx = -11.38, fz = 7.15,  fr = 0,   sx = -13.504, sz = 5.340,  sr = 225 },
    down = { fx = -20.93, fz = -2.72, fr = 180, sx = -17.795, sz = -5.680, sr = 135 } },
  { key = "B", tag = "C5C35E37",
    up   = { fx = 15.91, fz = 3.73,  fr = 0,   sx = 17.342, sz = 0.101,  sr = 165, rx = 14.323, rz = 3.736 },
    down = { fx = 7.20,  fz = -7.21, fr = 180, sx = 3.811,  sz = -8.597, sr = 240, rx = 6.153,  rz = -6.705 } },
  { key = "C", tag = "B37C9A48",
    up   = { fx = 7.70, fz = 16.86,  fr = 0,   sx = 5.947, sz = 20.588, sr = 345, rx = 8.081, rz = 15.388 },
    down = { fx = 0.88, fz = -16.92, fr = 180, sx = 3.512, sz = -14.611, sr = 45, rx = 0.461, rz = -19.318 } },
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
    local fi = floodIx[m.key]
    if fi ~= nil then
      ov[fi] = { mt = { flooded.fx, objects[fi].move_to[2], flooded.fz }, rot = { 0, 180, flooded.fr } }
    end
    drySuits[#drySuits + 1] = { dry.sx, dry.sz, dry.sr }
    if dry.rx ~= nil then dryRuins[#dryRuins + 1] = { dry.rx, dry.rz } end
  end

  -- RUINS: 2 fixed slots (entries at x>-20) + 2 dry slots; shuffle across the 4 entries
  local ruinSlots = {}
  for _, idx in ipairs(ruinIx) do
    if objects[idx].move_to[1] > -20 then
      ruinSlots[#ruinSlots + 1] = { objects[idx].move_to[1], objects[idx].move_to[3] }
    end
  end
  for _, p in ipairs(dryRuins) do ruinSlots[#ruinSlots + 1] = p end
  rttShuffleList(ruinSlots)
  for i, idx in ipairs(ruinIx) do
    local p = ruinSlots[i]
    if p ~= nil then ov[idx] = { mt = { p[1], objects[idx].move_to[2], p[2] }, rot = nil } end
  end

  -- SUITS: all 12 clearings randomised (4 of each colour) across 9 fixed + 3 dry
  local suitTargets = {}
  for _, p in ipairs(RTT_MARSH_SUIT9) do suitTargets[#suitTargets + 1] = { p[1], p[2], p[3] } end
  for _, p in ipairs(drySuits) do suitTargets[#suitTargets + 1] = p end
  rttShuffleList(suitTargets)
  for i, idx in ipairs(suitIx) do
    local t = suitTargets[i]
    if t ~= nil then ov[idx] = { mt = { t[1], objects[idx].move_to[2], t[2] }, rot = { 0, t[3], 0 } } end
  end

  -- lock everything only AFTER it has settled onto the board (spawned unlocked)
  Wait.time(function()
    for _, o in ipairs(RTT_MARSH_PIECES) do
      if o ~= nil then pcall(function() o.setLock(true) end) end
    end
  end, 3)

  return ov
end

"""


def apply(text):
    sig = "function makeMap(player,value,id)"
    if text.count(sig) != 1:
        raise framework.BuildError("makeMap anchor not unique")
    text = text.replace(sig, framework.esc(FLOOD_LUA) + sig, 1)

    # build the plan + clean out the previous build's tracked pieces (tag-independent,
    # catches still-loading tiles a quick re-press would otherwise strand)
    old1 = "objects = EVERYTHING[\"Maps\"][id]['data']"
    new1 = (old1 + "\n  local RTT_OV = nil\n"
            "  if id == \"Marsh Map\" then\n"
            "    for _,o in ipairs(RTT_MARSH_PIECES or {}) do if o ~= nil then pcall(function() o.destruct() end) end end\n"
            "    RTT_MARSH_PIECES = {}\n"
            "    RTT_OV = rttMarshPlan(objects)\n"
            "  end")
    text = framework.replace_unique(text, framework.esc(old1), framework.esc(new1))

    # per-entry override of move_to / rotation in the spawn loop (rtt_ov = an override piece)
    old2 = "  for _,v in ipairs(objects) do\n    local vec = Vector(v.move_to) * scale"
    new2 = ("  for idx,v in ipairs(objects) do\n"
            "    local rtt_mt = v.move_to\n"
            "    local rtt_rot = nil\n"
            "    local rtt_ov = false\n"
            "    if RTT_OV ~= nil and RTT_OV[idx] ~= nil then rtt_mt = RTT_OV[idx].mt rtt_rot = RTT_OV[idx].rot rtt_ov = true end\n"
            "    local vec = Vector(rtt_mt) * scale")
    text = framework.replace_unique(text, framework.esc(old2), framework.esc(new2))

    # pass rotation; spawn override pieces UNLOCKED so they settle onto the board
    # (they get locked 3s later in rttMarshPlan's delayed pass)
    old3 = ("        json              = v.json,\n"
            "        position          = new_pos,\n"
            "        callback_function = function(spawned_object)\n\n"
            "        if spawned_object.name == \"Bag\" then spawned_object.shuffle() end")
    new3 = ("        json              = v.json,\n"
            "        position          = new_pos,\n"
            "        rotation          = rtt_rot,\n"
            "        callback_function = function(spawned_object)\n\n"
            "        if rtt_ov then spawned_object.setLock(false) end\n"
            "        if spawned_object.name == \"Bag\" then spawned_object.shuffle() end")
    text = framework.replace_unique(text, framework.esc(old3), framework.esc(new3))

    # base bug: table.insert returns nil in Lua 5.2, so setTags(nil) never adds the
    # "Map Object" tag and removeMapItems finds nothing. Use the additive API.
    old4 = 'spawned_object.setTags(table.insert(spawned_object.getTags(),"Map Object"))'
    new4 = 'spawned_object.addTag("Map Object")'
    text = framework.replace_unique(text, framework.esc(old4), framework.esc(new4))

    # record each override piece's handle synchronously; skip the buggy shuffleMaps for Marsh
    old5 = "    })\n  end\n  shuffleMaps(id)"
    new5 = ("    })\n"
            "    if rtt_ov then RTT_MARSH_PIECES[#RTT_MARSH_PIECES + 1] = ob end\n"
            "  end\n  if id ~= \"Marsh Map\" then shuffleMaps(id) end")
    text = framework.replace_unique(text, framework.esc(old5), framework.esc(new5))
    return text
