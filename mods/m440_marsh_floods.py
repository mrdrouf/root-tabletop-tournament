"""
m440 — Marsh Map randomised setup, done DIRECTLY inside the map spawn.

Every time the Marsh map is built, makeMap now computes a random plan FIRST and
spawns each piece straight into its final position (no spawn-at-the-side-then-move,
no post-processing search). This kills the "sometimes only 2 flood markers" race and
makes everything appear in place immediately, locked.

The plan (rttMarshPlan), computed before the spawn loop:
  * each of the 3 flood markers randomly floods its up or down clearing -> the marker
    spawns on the flooded clearing (rotZ 0/180), locked;
  * the 2 spare ruins (parked x=-24.6) and 3 spare suit markers (parked z>=23) spawn on
    the DRY (non-flooded) clearings of markers B/C (ruins) and A/B/C (suits);
  * ruin ITEMS are randomised by shuffling the 4 ruin entries across their 4 target
    slots; ALL 12 clearing suits (4 of each colour) are randomised across the 12 active
    clearings (9 fixed + the 3 dry candidates) — with a correct single-pass Fisher-Yates
    (rttShuffleList), NOT the base shuffle() (which re-seeds os.time() per iteration; see
    rtt-rng-bug).

makeMap spawns objects at position = f(move_to); we override move_to (and rotation)
per entry, so f still applies. Non-Marsh maps are untouched (RTT_OV stays nil). For
Marsh we skip shuffleMaps (its ruin/clearing shuffle is what we're replacing; nothing
else in it applies to Marsh — no City/Clearing-N/Shuffleable objects).

Positions measured from Adrien's Marsh Reference save; flood entries found by their
unique tile artwork, ruins by nickname RUIN, suits by the "Clearing Marker" tag.
"""
from . import framework

NAME = "Marsh Map: spawn floods + ruins + suits directly in randomised positions"

FLOOD_LUA = r"""
-- the 9 always-present Marsh clearings (move_to x, z, rotY) that are never flood
-- candidates; the other 3 active clearings are the dry sides of markers A/B/C.
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

-- correct single-pass Fisher-Yates; NO os.time re-seed (that is the base shuffle() bug)
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

  -- SUITS: ALL 12 clearings are always randomised (4 of each colour). Distribute the
  -- 12 suit markers across the 12 active clearings = 9 fixed + the 3 dry candidates.
  local suitTargets = {}
  for _, p in ipairs(RTT_MARSH_SUIT9) do suitTargets[#suitTargets + 1] = { p[1], p[2], p[3] } end
  for _, p in ipairs(drySuits) do suitTargets[#suitTargets + 1] = p end
  rttShuffleList(suitTargets)
  for i, idx in ipairs(suitIx) do
    local t = suitTargets[i]
    if t ~= nil then ov[idx] = { mt = { t[1], objects[idx].move_to[2], t[2] }, rot = { 0, t[3], 0 } } end
  end

  broadcastToAll("Marsh: flooded clearings, ruins and suits randomised.", { 0.6, 0.8, 1 })
  return ov
end

"""


def apply(text):
    sig = "function makeMap(player,value,id)"
    if text.count(sig) != 1:
        raise framework.BuildError("makeMap anchor not unique")
    text = text.replace(sig, framework.esc(FLOOD_LUA) + sig, 1)

    # 1) build the plan once, right after the map data is loaded
    old1 = "objects = EVERYTHING[\"Maps\"][id]['data']"
    new1 = old1 + "\n  local RTT_OV = nil\n  if id == \"Marsh Map\" then RTT_OV = rttMarshPlan(objects) end"
    text = framework.replace_unique(text, framework.esc(old1), framework.esc(new1))

    # 2) per-entry override of move_to / rotation / lock in the spawn loop
    old2 = "  for _,v in ipairs(objects) do\n    local vec = Vector(v.move_to) * scale"
    new2 = ("  for idx,v in ipairs(objects) do\n"
            "    local rtt_mt = v.move_to\n"
            "    local rtt_rot = nil\n"
            "    local rtt_lock = false\n"
            "    if RTT_OV ~= nil and RTT_OV[idx] ~= nil then rtt_mt = RTT_OV[idx].mt rtt_rot = RTT_OV[idx].rot rtt_lock = true end\n"
            "    local vec = Vector(rtt_mt) * scale")
    text = framework.replace_unique(text, framework.esc(old2), framework.esc(new2))

    # 3) pass the rotation to the spawn, and lock the piece in its callback
    old3 = ("        json              = v.json,\n"
            "        position          = new_pos,\n"
            "        callback_function = function(spawned_object)\n\n"
            "        if spawned_object.name == \"Bag\" then spawned_object.shuffle() end")
    new3 = ("        json              = v.json,\n"
            "        position          = new_pos,\n"
            "        rotation          = rtt_rot,\n"
            "        callback_function = function(spawned_object)\n\n"
            "        if rtt_lock then spawned_object.setLock(true) end\n"
            "        if spawned_object.name == \"Bag\" then spawned_object.shuffle() end")
    text = framework.replace_unique(text, framework.esc(old3), framework.esc(new3))

    # 4) Marsh does its own randomisation above, so skip the buggy shuffleMaps for it
    old4 = "  shuffleMaps(id)\nend"
    new4 = "  if id ~= \"Marsh Map\" then shuffleMaps(id) end\nend"
    text = framework.replace_unique(text, framework.esc(old4), framework.esc(new4))
    return text
