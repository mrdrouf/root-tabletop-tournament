"""
m490 — per-faction setup extras + the Mountain landmark, on EVERY spawn path.

A single dispatcher (rttFactionExtras) runs the per-faction extras. It is hooked into
BOTH spawn paths so the behaviour holds whether you draft or click the faction selector:
  * the DRAFT path  — rttCoordFaction (m470), ~1.2s after the pieces settle
  * the SELECTOR path — makeFaction (base), right after its setupFaction() call

Per faction:
  * The Lizard Cult  -> spawn the "Lizard Wizard" Tool, remove the unused Outcast Marker,
                        reposition the frogs' Pond if it is already out.
  * Lilypad Diaspora -> shuffle the 14 frog cards into the shared deck; place The Pond by
    (frogs)             the discard (shifted aside when the Lizard's Lost Souls is in play).
  * Keepers in Iron  -> draw one relic per recorded spot (Adrien's corrected per-map
    (badgers)           positions; random type) from the Relics bag; extras stay in the bag.
  * Twilight Council -> (bats) one assembly on the board's first snap + 4-pack/2-pack warriors.
  * Corvid           -> 12 plots (3 of each) in a clean 4x3 grid on the board.
  * Underground Duchy -> (moles) tuck the extra loose warrior into the supply (7 placed, 13 in bag).

Mountain map (fires from makeMap, so the direct map-click works too): read the central
clearing's suit from its "Clearing Marker" token, then remove the Tower + that marker and
stand a landmark there — d4 roll 0 => Lost City, else the suit's landmark (rabbit->Rabbit-
Town, fox->Foxburrow, mouse->Mousehold). The landmark's rules card goes to the map's
lower-left, rules side up.
"""
import json
import os

from . import framework

NAME = "per-faction setup extras (all paths) + Mountain landmark"

# Adrien's staged reference spots (from his TTS save)
# makeSpecialWithTag ADDS a fixed newVec (~ -0.805, +10.010, +2.248) to this input, so this is
# NOT the world position — it's (target_world - newVec). Old value put the Wizard 10u in the air
# (input y 11.562 -> world 21.57 = "frozen in the air"). Target world (-30.437, 11.562, 12.486)
# -> input below. (newVec derived from the pre-fix floating save.)
LIZARD_WIZ_POS = (-29.878, 1.552, 9.915)   # -> world (-30.683, 11.562, 12.163)
LIZARD_WIZ_ROTY = 90                        # the wizard faces this way (Adrien's direction)
LIZARD_OUTCAST_POS = (-29.220, 11.760, 15.020)   # the Outcast Marker's spot, on the wizard
# the frog pond's WORLD resting spot (the central special area) — was wrongly read off
# RTT_LIZ_WIZ, which is now a makeSpecialWithTag INPUT (y 1.55), sending the pond underground.
POND_FROG_POS = (-30.970, 11.562, 21.682)
POND_SHIFT_POS = (-31.217, 11.562, 21.567)

# Mountain landmark: centre-clearing suit snap (where Adrien stood the Lost City), and the
# Lost City rules card's lower-left resting spot + card scale (all from his save).
MTN_LM_POS = (-0.116, 11.66, 0.187)
MTN_CARD_POS = (-29.303, 11.575, -19.899)
MTN_CARD_SCALE = 2.299

# dispatch after each faction spawns — draft path (inside rttCoordFaction, after Knaves)
DISPATCH = ('\n  Wait.time(function() rttFactionExtras(faction, bp.x, bp.z, bp.z > 0) end, 1.2)')
KNAVES_ANCHOR = ('  if faction == "Knaves of the Deepwood" then\n'
                 '    Wait.time(function() rttKnavesCaptains(seat.color) end, 1.0)\n'
                 '  end')

# dispatch after each faction spawns — SELECTOR path (inside makeFaction, after setupFaction)
SELECTOR_ANCHOR = "  setupFaction(category,id,player.color,false)"
SELECTOR_DISPATCH = (
    "  setupFaction(category,id,player.color,false)\n"
    "  do local cp = self.getPosition()\n"
    "    Wait.time(function() rttFactionExtras(id, cp.x, cp.z, cp.z > 0) end, 1.2) end")

# Mountain: rttPlaceMap's tower-destroy branch (m470) — REMOVE it; makeMap now drives the
# landmark (so both draft and direct-click fire it), and it needs the Tower alive to locate
# the central clearing.
MTN_TOWER_BRANCH = ('  if mapId == "Mountain Map" then\n'
                    '    Wait.time(function() for _, v in ipairs(getObjectsWithTag("Tower")) do v.destruct() end end, 0.8)\n'
                    '  end\n')
# fire the landmark from inside makeMap (covers every path that reaches makeMap)
MAKEMAP_SIG = "function makeMap(player,value,id)"
MAKEMAP_HOOK = ('\n  RTT_CURRENT_MAP = id'
                '\n  if id == "Mountain Map" then Wait.time(function() rttMountainLandmark() end, 1.0) end')


def _extra_lua():
    here = os.path.dirname(__file__)
    forest_uv = open(os.path.join(here, "_forest_uv_lua.txt"), encoding="utf-8").read()
    relic_pos = open(os.path.join(here, "_relic_pos_lua.txt"), encoding="utf-8").read()
    return r"""
-- ===== RTT per-faction setup extras =====
%(forest_uv)s
%(relic_pos)s

RTT_LIZ_WIZ = { %(wx).3f, %(wy).3f, %(wz).3f }
RTT_LIZ_WIZ_ROTY = %(wr)d
RTT_LIZ_OUTCAST = { %(ox).3f, %(oy).3f, %(oz).3f }
RTT_POND_SHIFT = { %(px).3f, %(py).3f, %(pz).3f }
RTT_POND_FROG = { %(fx).3f, %(fy).3f, %(fz).3f }

function rttFactionExtras(faction, cx, cz, flip)
  if faction == "The Lizard Cult" then rttLizardSetup()
  elseif faction == "Lilypad Diaspora" then rttFrogsSetup()
  elseif faction == "Keepers in Iron" then rttBadgerRelics()
  -- Twilight Council (bats) now spawns from the baked blueprint (m560) — no runtime setup
  elseif faction == "Corvid Conspiracy" then rttCrowsPlots(cx, cz, flip)
  elseif faction == "Underground Duchy" then rttDuchyTuck()
  elseif faction == "Knaves of the Deepwood" then rttKnavesSetup(cx, cz, flip)
  elseif faction == "Marquise de Cat" then rttMarquiseCats(cx, cz, flip)
  end
end

-- ---- Marquise de Cat: one warrior in the CENTRE of every clearing -------------------------
-- The 3 staging warriors + buildings + Keep are baked (m570/m550) so they spawn in place. Here
-- we only handle the 12 cats on the map: taken STRAIGHT from the Marquise Supply bag onto each
-- clearing CENTRE, so they appear at their spot directly (no default-then-move).
--
-- RTT_CLEARING_CENTRES[map] = the world (x,z) centre of every clearing, converted from the eyes
-- tile-local geometry (root_engine/eyes + maps_data/*_geometry.json) via the shared map transform
-- (scale 12.97936, rotY 180, origin ~0). 12 clearings on the standard maps; 15 positions on Marsh
-- (9 dry + both sides of the 3 flood pairs), of which the 3 inactive ones are skipped so exactly
-- 12 cats land — matched to RTT_MARSH_EXCLUDED (the inactive clearing centres from m440/m500).
RTT_CLEARING_CENTRES = {
  ["Summer Map"] = {
    {19.93,-17.20},{-18.64,-12.35},{-16.63,16.88},{19.64,14.75},{-2.61,-19.06},{-20.57,0.96},
    {-4.35,12.68},{7.15,17.75},{19.97,-4.46},{3.86,-9.80},{-6.98,-0.73},{9.48,2.60},
  },
  ["Winter Map"] = {
    {18.44,-17.15},{-19.13,-11.93},{-17.29,16.97},{18.21,14.11},{6.15,-15.14},{-5.33,-13.16},
    {-20.40,3.59},{-4.25,10.36},{6.29,16.89},{18.38,-3.32},{6.94,-0.25},{-6.45,-1.36},
  },
  ["Lake Map"] = {
    {-17.60,16.47},{18.05,-14.78},{19.77,14.57},{-20.53,-8.42},{-19.38,3.77},{-9.91,-13.41},
    {2.61,-17.40},{20.76,-0.44},{3.08,17.80},{9.60,-6.61},{-8.23,-0.81},{8.05,7.53},
  },
  ["Mountain Map"] = {
    {19.90,-15.43},{-16.43,-13.40},{-18.52,13.08},{18.60,14.71},{-1.80,-15.93},{-20.73,-0.39},
    {-3.35,16.20},{21.00,3.24},{10.72,-7.35},{0.48,-4.73},{-6.54,5.15},{8.25,7.98},
  },
  ["Gorge Map"] = {
    {18.74,-16.85},{-18.09,-15.82},{-11.08,17.68},{16.82,17.16},{-5.55,-17.38},{-13.78,-6.20},
    {-18.56,4.50},{2.81,15.45},{17.91,5.12},{16.75,-5.69},{0.58,-8.19},{-1.06,5.40},
  },
  ["Marsh Map"] = {
    {19.09,-17.22},{-20.91,-13.56},{-16.19,17.23},{20.63,16.61},{5.29,-17.90},{-7.54,-16.61},
    {-20.53,6.91},{-0.28,16.65},{8.35,12.21},{20.89,2.52},{11.46,-7.53},{-15.31,-3.58},
    {-7.21,7.24},{4.84,0.88},{-2.18,-6.55},
  },
}

function rttMarquiseCats(cx, cz, flip)
  -- resolve the current map (same fallback chain as rttBadgerRelics: clone -> main board bab7e1)
  local mapId = RTT_CURRENT_MAP or (RTT_PICKED or {}).map
  if mapId == nil then
    local mb = getObjectFromGUID("bab7e1")
    if mb ~= nil then
      local ok, mid = pcall(function() return mb.call("rttGetCurrentMap") end)
      if ok and type(mid) == "string" then mapId = mid end
    end
  end
  local centres = RTT_CLEARING_CENTRES[mapId]
  if centres == nil then return end
  local bag = nil
  for _, o in ipairs(getAllObjects()) do
    if (o.getName() or "") == "Marquise Supply" then bag = o break end
  end
  if bag == nil then return end
  local excl = {}
  if mapId == "Marsh Map" then                     -- the 3 inactive clearing centres (bab7e1 global)
    excl = RTT_MARSH_EXCLUDED
    if excl == nil then
      local mb = getObjectFromGUID("bab7e1")
      if mb ~= nil then
        local ok, ex = pcall(function() return mb.call("rttGetMarshExcluded") end)
        if ok and type(ex) == "table" then excl = ex end
      end
    end
    excl = excl or {}
  end
  for _, c in ipairs(centres) do
    local skip = false
    for _, e in ipairs(excl) do                    -- Marsh: skip the 3 inactive clearing centres
      local dx, dz = c[1] - e[1], c[2] - e[2]
      if dx * dx + dz * dz < 20.0 then skip = true break end   -- ~4.5u = same clearing
    end
    if not skip then
      pcall(function() bag.takeObject({ position = { c[1], 12.6, c[2] }, smooth = false }) end)
    end
  end
end

-- ---- Knaves of the Deepwood: draft 4 RANDOM captains, remove the other 8 -----------------
-- The faction spawns a 12-card Captain deck (DeckIDs 73400-73411, shared face sheet
-- FA78C0...037E95) with an EMPTY nickname, so the base rttKnavesCaptains name-match never
-- fires and all 12 just sit there. Adrien wants only 4 random captains kept, laid out in a
-- visible row where the deck spawned; the rest are discarded. Identify the deck by its face
-- sheet (nickname/GMNotes are all blank), scoped to this seat.
-- find the 12-card Captain deck near the seat. Prefer the deck whose face sheet is the Captain
-- sheet (FA78C0...), but fall back to the nearest Deck within 20u of the seat (the Knaves faction
-- has only one deck near its board), so a getData() quirk can't leave all 12 captains in play.
function rttFindKnavesDeck(cx, cz)
  local best, bd, faceBest, faceBd = nil, 1e9, nil, 1e9
  for _, o in ipairs(getAllObjects()) do
    if o.name == "Deck" then
      local p = o.getPosition()
      local d = (p.x - cx) ^ 2 + (p.z - cz) ^ 2
      if d < 400 then
        if d < bd then bd = d; best = o end
        local ok, dt = pcall(function() return o.getData() end)
        if ok and dt ~= nil and dt.CustomDeck ~= nil then
          for _, cd in pairs(dt.CustomDeck) do
            if cd.FaceURL ~= nil and
               string.find(cd.FaceURL, "FA78C0F952724D77A33BECEC0651802808037E95", 1, true) then
              if d < faceBd then faceBd = d; faceBest = o end
              break
            end
          end
        end
      end
    end
  end
  return faceBest or best
end

-- keep polling until the faction spawn has produced the Captain deck, then keep 4 random
function rttKnavesSetup(cx, cz, flip)
  rttKnavesTry(cx, cz, flip, 0)
end

function rttKnavesTry(cx, cz, flip, attempt)
  local deck = rttFindKnavesDeck(cx, cz)
  if deck == nil then
    if attempt < 10 then Wait.time(function() rttKnavesTry(cx, cz, flip, attempt + 1) end, 0.5) end
    return
  end
  pcall(function() deck.shuffle() end)
  Wait.time(function()
    local ok, p = pcall(function() return deck.getPosition() end)
    if not ok or p == nil then return end
    -- lay 4 captains in a face-up row BELOW the knave cards (the deck's drafting spot), toward
    -- the player; keep them locked as faction pieces
    local below = (flip and 1 or -1) * 3.6
    for i = 1, 4 do
      pcall(function()
        deck.takeObject({
          position = { p.x + (i - 2.5) * 2.4, p.y + 0.3, p.z + below },
          rotation = { 0, 180, 0 },
          smooth = false,
          callback_function = function(o)
            o.setLock(true)
            o.addTag("RTT Faction")
          end
        })
      end)
    end
    -- discard the remaining captains (destruct the leftover deck once the takes have settled)
    Wait.time(function() if deck ~= nil then pcall(function() deck.destruct() end) end end, 0.8)
  end, 0.5)
end

-- pick the big faction-board tile that just spawned nearest a seat (cx,cz)
function rttFindSeatBoard(cx, cz)
  local board, bestD = nil, 1e9
  for _, o in ipairs(getAllObjects()) do
    if o.name == "Custom_Tile" then
      local s = o.getScale()
      if s ~= nil and s.x >= 7.5 then
        local p = o.getPosition()
        local d = (p.x - cx) ^ 2 + (p.z - cz) ^ 2
        if d < bestD and d < 900 then bestD = d; board = o end
      end
    end
  end
  return board
end

-- ---- Corvid Conspiracy (crows): 12 plots, 3 of each type, in a clean 4x3 grid --------
RTT_CROW_COLS = { -0.400, -0.577, -0.754, -0.931 }
RTT_CROW_ROWS = { -1.166, -1.353, -1.540 }
-- the 4 starting Corvid warriors, board-local (recorded from Adrien's save): a row by the supply
RTT_CROW_WAR = { { 0.330, -1.157 }, { 0.499, -1.157 }, { 0.668, -1.157 }, { 0.837, -1.157 } }

function rttCrowsPlots(cx, cz, flip)
  local board = rttFindSeatBoard(cx, cz)
  if board == nil then return end
  for _, o in ipairs(getAllObjects()) do
    if (o.getName() or "") == "Plot" then pcall(function() o.destruct() end) end
  end
  -- the base does NOT spawn loose "Plot" objects, so RTT_CROW_PLOTS is the only source: spawn
  -- the 12 plots straight into the 4x3 grid, FACE DOWN (rotZ 180 — the recorded blobs are face
  -- up), in ONE step. Clear any leftover plots from a prior setup first.
  for _, o in ipairs(getAllObjects()) do
    if (o.getName() or "") == "Plot" then pcall(function() o.destruct() end) end
  end
  local ry = board.getRotation().y
  for i, blob in ipairs(RTT_CROW_PLOTS or {}) do
    local idx = i - 1
    local col = math.floor(idx / 3) + 1
    local row = (idx %% 3) + 1
    local w = board.positionToWorld({ RTT_CROW_COLS[col], 0.03, RTT_CROW_ROWS[row] })
    spawnObjectJSON({
      json = blob,
      position = { w.x, w.y + 0.2, w.z },
      rotation = { 0, ry, 180 },            -- face DOWN
      callback_function = function(o) o.setLock(false) end
    })
  end
  -- 4 starting warriors on the seat board (recorded board-local offsets), placed instantly
  local cw = {}
  for _, o in ipairs(getAllObjects()) do
    if (o.getName() or "") == "Corvid Warrior" then cw[#cw + 1] = o end
  end
  for i = 1, math.min(4, #cw) do
    local off = RTT_CROW_WAR[i]
    local w = board.positionToWorld({ off[1], 0.02, off[2] })
    if cw[i].getLock and cw[i].getLock() then cw[i].setLock(false) end
    cw[i].setPosition({ w.x, w.y + 0.5, w.z })
  end
  -- drop the Corvid "Bot Interactions" reference card (CardID 29900) — human tournament, no bots
  for _, o in ipairs(getAllObjects()) do
    if o.name == "Card" or o.name == "CardCustom" then
      local ok, dt = pcall(function() return o.getData() end)
      if ok and dt ~= nil and dt.CardID == 29900 then pcall(function() o.destruct() end) end
    end
  end
end

-- ---- Underground Duchy (moles): 7 placed + the 8th in the supply -----------
-- the data ships 8 loose warriors; tuck outliers into the Duchy Supply bag until 7 remain.
function rttDuchyTuck()
  local bag, warriors = nil, {}
  for _, o in ipairs(getAllObjects()) do
    local nm = o.getName() or ""
    if nm == "Duchy Supply" then bag = o
    elseif nm == "Duchy Warrior" then warriors[#warriors + 1] = o end
  end
  if bag == nil then return end
  while #warriors > 7 do
    local sx, sz = 0, 0
    for _, w in ipairs(warriors) do local p = w.getPosition() sx = sx + p.x sz = sz + p.z end
    sx, sz = sx / #warriors, sz / #warriors
    local oi, od = 1, -1
    for i, w in ipairs(warriors) do
      local p = w.getPosition()
      local d = (p.x - sx) ^ 2 + (p.z - sz) ^ 2
      if d > od then od = d; oi = i end
    end
    pcall(function() bag.putObject(warriors[oi]) end)
    table.remove(warriors, oi)
  end
end

-- ---- Lizard Cult ----------------------------------------------------------
function rttLizardSetup()
  -- keep the Outcast Marker (it belongs ON the Lizard Wizard) — do NOT destruct it.
  makeSpecialWithTag("Tools", "Lizard Wizard",
    RTT_LIZ_WIZ[1], RTT_LIZ_WIZ[2], RTT_LIZ_WIZ[3], "Faction")
  -- makeSpecialWithTag can't set the facing, and the Outcast Marker spawns elsewhere, so orient
  -- the wizard and snap the marker onto it (instant, no slide).
  Wait.time(function()
    for _, o in ipairs(getAllObjects()) do
      local nm = o.getName() or ""
      if nm == "Lizard Wizard" then
        if o.getLock and o.getLock() then o.setLock(false) end
        o.setRotation({ 0, RTT_LIZ_WIZ_ROTY, 0 })
      elseif nm == "Outcast Marker" then
        if o.getLock and o.getLock() then o.setLock(false) end
        o.setPosition({ RTT_LIZ_OUTCAST[1], RTT_LIZ_OUTCAST[2], RTT_LIZ_OUTCAST[3] })
        o.setRotation({ 0, RTT_LIZ_WIZ_ROTY, 0 })
      end
    end
  end, 0.8)
  Wait.time(function() rttRepositionPond() end, 1.0)
end

-- ---- Lilypad Diaspora (frogs) --------------------------------------------
function rttFrogsSetup()
  rttShuffleFrogsIntoDeck()
  Wait.time(function() rttRepositionPond() end, 1.0)
end

function rttRepositionPond()
  local pond = nil
  for _, o in ipairs(getAllObjects()) do
    if (o.getName() or "") == "The Pond" then pond = o break end
  end
  if pond == nil then return end
  local lizard = (RTT_FAC_TAKEN or {})["The Lizard Cult"] == true
  local p = lizard and RTT_POND_SHIFT or RTT_POND_FROG
  if pond.getLock and pond.getLock() then pond.setLock(false) end
  pond.setPosition({ p[1], p[2], p[3] })          -- instant: no visible slide
  pond.setRotation({ 0, 90, 0 })
  Wait.time(function() if pond ~= nil then pond.setLock(true) end end, 0.3)
end

function rttShuffleFrogsIntoDeck()
  local mainDeck, frogObjs = nil, {}
  for _, o in ipairs(getAllObjects()) do
    local nm = o.name
    if nm == "Deck" then
      local cards = o.getObjects() or {}
      local frog, total = 0, #cards
      for _, c in ipairs(cards) do if (c.description or "") == "Frog" then frog = frog + 1 end end
      if total > 0 and frog == total then frogObjs[#frogObjs + 1] = o
      elseif total >= 20 and frog == 0 and mainDeck == nil then mainDeck = o end
    elseif (nm == "Card" or nm == "CardCustom") and (o.getDescription() or "") == "Frog" then
      frogObjs[#frogObjs + 1] = o
    end
  end
  if mainDeck == nil then return end
  for _, f in ipairs(frogObjs) do pcall(function() mainDeck.putObject(f) end) end
  Wait.time(function() if mainDeck ~= nil then pcall(function() mainDeck.shuffle() end) end end, 1.0)
end

-- ---- Keepers in Iron (badgers): relics onto Adrien's recorded per-map spots -----------
function rttFindMapObject()
  local best, bestN = nil, 0
  for _, o in ipairs(getAllObjects()) do
    local ok, sp = pcall(function() return o.getSnapPoints() end)
    if ok and sp and #sp > bestN then best, bestN = o, #sp end
  end
  return best
end

function rttForestWorldCenters(mapId)   -- fallback for maps with no recorded relic spots
  local cents = RTT_FOREST_UV[mapId]
  if cents == nil then return {} end
  local m = rttFindMapObject()
  if m == nil then return {} end
  local b = m.getBounds()
  local a = math.rad(m.getRotation().y)
  local sx, sz = b.size.x, b.size.z
  local out = {}
  for _, uv in ipairs(cents) do
    local lx, lz = uv[1] * sx, uv[2] * sz
    out[#out + 1] = {
      b.center.x + lx * math.cos(a) - lz * math.sin(a),
      b.center.z + lx * math.sin(a) + lz * math.cos(a),
    }
  end
  return out
end

-- the map buttons + makeMap live on the MAIN board (bab7e1); clones (the solo/standard faction
-- selectors) have their own Lua globals, so a clone's RTT_CURRENT_MAP is nil. This getter lets
-- any clone read the main board's current map by GUID.
function rttGetCurrentMap() return RTT_CURRENT_MAP end
function rttGetMarshExcluded() return RTT_MARSH_EXCLUDED end

function rttBadgerRelics()
  -- RTT_PICKED.map is only set by the ranked-draft coordinator; on the solo/standard faction
  -- board it is nil. Fall back to RTT_CURRENT_MAP (this board's last makeMap); and if THIS
  -- object is a selector clone (its own RTT_CURRENT_MAP is nil), read the main board bab7e1.
  local mapId = RTT_CURRENT_MAP or (RTT_PICKED or {}).map
  if mapId == nil then
    local mb = getObjectFromGUID("bab7e1")
    if mb ~= nil then
      local ok, mid = pcall(function() return mb.call("rttGetCurrentMap") end)
      if ok and type(mid) == "string" then mapId = mid end
    end
  end
  if mapId == nil then return end
  local bag = nil
  for _, o in ipairs(getAllObjects()) do
    if o.name == "Bag" and (o.getName() or "") == "Relics" then bag = o break end
  end
  if bag == nil then return end
  pcall(function() bag.shuffle() end)              -- placement is ALWAYS random (per Adrien)
  local targets = {}
  local recorded = RTT_RELIC_POS[mapId]
  if recorded ~= nil then                          -- Adrien's exact per-map spots (map-local)
    local m = rttFindMapObject()
    if m == nil then return end
    for _, lc in ipairs(recorded) do
      local w = m.positionToWorld({ lc[1], 0.05, lc[2] })
      targets[#targets + 1] = { w.x, w.z }
    end
  else
    targets = rttForestWorldCenters(mapId)          -- fallback: forest centroids
  end
  if #targets == 0 then return end
  for _, c in ipairs(targets) do
    pcall(function()
      bag.takeObject({ position = { c[1], 12.0, c[2] }, rotation = { 0, 180, 0 }, smooth = false })
    end)
  end
end

-- ---- Twilight Council (bats) ---------------------------------------------
RTT_BATS_ASM = { -0.032, -0.253 }
RTT_BATS_WAR = {
  { 0.657, -1.241 }, { 0.657, -1.167 }, { 0.797, -1.167 }, { 0.797, -1.241 },  -- pack of 4
  { 0.375, -1.167 }, { 0.375, -1.241 },                                        -- pack of 2
}

function rttBatsSetup(cx, cz, flip)
  local board = rttFindSeatBoard(cx, cz)
  if board == nil then return end
  local asmWorld = board.positionToWorld({ RTT_BATS_ASM[1], 0.254, RTT_BATS_ASM[2] })
  local placed = false
  for _, o in ipairs(getAllObjects()) do
    if (not placed) and (o.getName() or "") == "Assembly" then
      if o.getLock and o.getLock() then o.setLock(false) end
      o.setPosition({ asmWorld.x, asmWorld.y + 0.3, asmWorld.z })   -- instant, no slide
      placed = true
    end
  end
  local warriors = {}
  for _, o in ipairs(getAllObjects()) do
    if (o.getName() or "") == "Council Warrior" then warriors[#warriors + 1] = o end
  end
  for i = 1, math.min(6, #warriors) do
    local off = RTT_BATS_WAR[i]
    local w = board.positionToWorld({ off[1], 0.02, off[2] })
    warriors[i].setPosition({ w.x, w.y + 0.5, w.z })              -- instant, no slide
  end
end

-- ---- Mountain: read the centre-clearing suit, then stand a landmark there ---------------
-- suit textures on the "Clearing Marker" mesh (verified by eye): yellow=rabbit, orange=mouse,
-- red=fox. Matched by the steam UGC handle in the marker's diffuse URL.
RTT_SUIT_TEX = {
  ["1725416554252055237"] = "rabbit",
  ["1725416554252058449"] = "mouse",
  ["1725416554252050523"] = "fox",
}
RTT_SUIT_LM = { rabbit = "Rabbit-Town", fox = "Foxburrow", mouse = "Mousehold" }
RTT_MTN_LM = { %(mx).3f, %(my).3f, %(mz).3f }
RTT_MTN_CARD = { %(kx).3f, %(ky).3f, %(kz).3f }
RTT_MTN_CARD_SCALE = %(ks).3f

function rttMountainLandmark()
  -- the central clearing sits at RTT_MTN_LM (the Tower is now hidden below the table by
  -- rttMountainHideTower, so we don't read its position); its suit marker is the nearest
  -- "Clearing Marker" to that centre.
  local cx, cz = RTT_MTN_LM[1], RTT_MTN_LM[3]
  local marker, md = nil, 1e9
  for _, o in ipairs(getObjectsWithTag("Clearing Marker")) do
    local p = o.getPosition()
    local d = (p.x - cx) ^ 2 + (p.z - cz) ^ 2
    if d < md then md = d; marker = o end
  end
  local suit = nil
  if marker ~= nil then
    local ok, co = pcall(function() return marker.getCustomObject() end)
    local url = (ok and co and (co.diffuse or co.mesh)) or ""
    for handle, s in pairs(RTT_SUIT_TEX) do
      if string.find(url, handle, 1, true) then suit = s break end
    end
  end
  local roll = math.random(0, 3)                   -- 0 => Lost City, else the suit's landmark
  local name = "Lost City"
  if roll ~= 0 and suit ~= nil then name = RTT_SUIT_LM[suit] end
  -- the landmark REPLACES the central suit marker (the Tower is already parked below the
  -- table by rttMountainHideTower, so there is nothing to destroy here — `towers` was an
  -- undefined global and ipairs(nil) crashed the whole function before the landmark spawned)
  if marker ~= nil then pcall(function() marker.destruct() end) end
  rttSpawnLandmarkAt(name, RTT_MTN_LM[1], RTT_MTN_LM[2], RTT_MTN_LM[3],
                     RTT_MTN_CARD[1], RTT_MTN_CARD[2], RTT_MTN_CARD[3],
                     165, 0, RTT_MTN_CARD_SCALE)
end

-- spawn a landmark's model (standing) + its rules card (rules side up) DIRECTLY at their
-- final transforms, so they appear in place and just settle onto the board like the other
-- map pieces — no visible slide/rotate. spawnObjectJSON's position/rotation override the
-- data's baked (flat) transform. EVERYTHING is on this board (self), so it's in scope.
-- mrotY  = standing-model world rotY (Mountain=165; Marsh towns pass the clearing's suit rotY)
-- crotZ  = rules-card rotZ (Mountain=0; Marsh towns pass 180, matching Adrien's saved cards)
-- cscale = rules-card XZ scale, or nil to leave the card at its blueprint scale (Marsh towns)
-- both the model and the card spawn LOCKED (Adrien wants landmarks + their cards fixed).
function rttSpawnLandmarkAt(name, mx, my, mz, cx, cy, cz, mrotY, crotZ, cscale)
  mrotY = mrotY or 165
  crotZ = crotZ or 0
  local lm = EVERYTHING['Landmarks'][name]
  if lm == nil or lm['data'] == nil then return end
  for _, v in ipairs(lm['data']) do
    if string.find(v.json, "CardID", 1, true) ~= nil then
      spawnObjectJSON({
        json = v.json,
        position = { cx, cy, cz },
        rotation = { 0, 180, crotZ },
        callback_function = function(o)
          o.setLock(true)
          o.addTag("Map Object")
          if cscale ~= nil then pcall(function() o.setScale({ cscale, 1.0, cscale }) end) end
        end
      })
    else
      spawnObjectJSON({
        json = v.json,
        position = { mx, my, mz },
        rotation = { 0, mrotY, 0 },                 -- standing signpost, in place
        callback_function = function(o)
          o.setLock(true)
          o.addTag("Map Object")
        end
      })
    end
  end
end
""" % {
    "forest_uv": forest_uv,
    "relic_pos": relic_pos,
    "wx": LIZARD_WIZ_POS[0], "wy": LIZARD_WIZ_POS[1], "wz": LIZARD_WIZ_POS[2],
    "wr": LIZARD_WIZ_ROTY,
    "ox": LIZARD_OUTCAST_POS[0], "oy": LIZARD_OUTCAST_POS[1], "oz": LIZARD_OUTCAST_POS[2],
    "px": POND_SHIFT_POS[0], "py": POND_SHIFT_POS[1], "pz": POND_SHIFT_POS[2],
    "fx": POND_FROG_POS[0], "fy": POND_FROG_POS[1], "fz": POND_FROG_POS[2],
    "mx": MTN_LM_POS[0], "my": MTN_LM_POS[1], "mz": MTN_LM_POS[2],
    "kx": MTN_CARD_POS[0], "ky": MTN_CARD_POS[1], "kz": MTN_CARD_POS[2],
    "ks": MTN_CARD_SCALE,
}


def apply(text):
    if text.count(MAKEMAP_SIG) != 1:
        raise framework.BuildError("makeMap anchor not unique")
    text = text.replace(MAKEMAP_SIG, framework.esc(_extra_lua()) + MAKEMAP_SIG, 1)

    # the 12 Corvid plot blobs (grouped 3-per-type) — injected separately from the
    # %-formatted extras so their URLs (which contain %) are not treated as format specs.
    plots = json.load(open(os.path.join(os.path.dirname(__file__), "_corvid_plots.json"),
                           encoding="utf-8"))
    crow_lua = "\nRTT_CROW_PLOTS = {\n%s\n}\n" % ",\n".join("[==[%s]==]" % b for b in plots)
    text = text.replace(MAKEMAP_SIG, framework.esc(crow_lua) + MAKEMAP_SIG, 1)

    # fire the Mountain landmark from inside makeMap (draft AND direct map-click)
    text = text.replace(MAKEMAP_SIG, MAKEMAP_SIG + framework.esc(MAKEMAP_HOOK), 1)

    # dispatch the extras on the DRAFT path (after the Knaves hook in rttCoordFaction)
    anchor = framework.esc(KNAVES_ANCHOR)
    if text.count(anchor) != 1:
        raise framework.BuildError("rttCoordFaction Knaves anchor not unique for dispatch")
    text = text.replace(anchor, anchor + framework.esc(DISPATCH), 1)

    # dispatch the extras on the SELECTOR path (after setupFaction() in makeFaction)
    sel_old = framework.esc(SELECTOR_ANCHOR)
    if text.count(sel_old) != 1:
        raise framework.BuildError("setupFaction selector anchor not unique")
    text = text.replace(sel_old, framework.esc(SELECTOR_DISPATCH), 1)

    # remove rttPlaceMap's own Mountain tower-destroy (makeMap now drives the landmark and
    # needs the Tower alive to find the central clearing)
    mtn_old = framework.esc(MTN_TOWER_BRANCH)
    if text.count(mtn_old) != 1:
        raise framework.BuildError("rttPlaceMap Mountain tower-destroy branch not unique")
    text = text.replace(mtn_old, "", 1)
    return text
