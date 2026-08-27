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
LIZARD_WIZ_POS = (-31.325, 11.562, 12.278)
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
MAKEMAP_HOOK = '\n  if id == "Mountain Map" then Wait.time(function() rttMountainLandmark() end, 1.0) end'


def _extra_lua():
    here = os.path.dirname(__file__)
    forest_uv = open(os.path.join(here, "_forest_uv_lua.txt"), encoding="utf-8").read()
    relic_pos = open(os.path.join(here, "_relic_pos_lua.txt"), encoding="utf-8").read()
    return r"""
-- ===== RTT per-faction setup extras =====
%(forest_uv)s
%(relic_pos)s

RTT_LIZ_WIZ = { %(wx).3f, %(wy).3f, %(wz).3f }
RTT_POND_SHIFT = { %(px).3f, %(py).3f, %(pz).3f }

function rttFactionExtras(faction, cx, cz, flip)
  if faction == "The Lizard Cult" then rttLizardSetup()
  elseif faction == "Lilypad Diaspora" then rttFrogsSetup()
  elseif faction == "Keepers in Iron" then rttBadgerRelics()
  elseif faction == "Twilight Council" then rttBatsSetup(cx, cz, flip)
  elseif faction == "Corvid Conspiracy" then rttCrowsPlots(cx, cz, flip)
  elseif faction == "Underground Duchy" then rttDuchyTuck()
  end
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

function rttCrowsPlots(cx, cz, flip)
  local board = rttFindSeatBoard(cx, cz)
  if board == nil then return end
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
      rotation = { 0, ry, 0 },
      callback_function = function(o) o.setLock(false) end
    })
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
  makeSpecialWithTag("Tools", "Lizard Wizard",
    RTT_LIZ_WIZ[1], RTT_LIZ_WIZ[2], RTT_LIZ_WIZ[3], "Faction")
  Wait.time(function()
    for _, o in ipairs(getAllObjects()) do
      if (o.getName() or "") == "Outcast Marker" then pcall(function() o.destruct() end) end
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
  local p = lizard and RTT_POND_SHIFT or RTT_LIZ_WIZ
  if pond.getLock and pond.getLock() then pond.setLock(false) end
  pond.setPositionSmooth({ p[1], p[2], p[3] }, false, true)
  pond.setRotationSmooth({ 0, 90, 0 }, false, true)
  Wait.time(function() if pond ~= nil then pond.setLock(true) end end, 1.0)
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

function rttBadgerRelics()
  local mapId = (RTT_PICKED or {}).map
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
      bag.takeObject({ position = { c[1], 12.0, c[2] }, rotation = { 0, 180, 0 }, smooth = true })
    end)
  end
end

-- ---- Twilight Council (bats) ---------------------------------------------
RTT_BATS_ASM = { -0.032, -0.253 }
RTT_BATS_WAR = {
  { 0.354, -1.204 }, { 0.354, -1.278 }, { 0.494, -1.204 }, { 0.494, -1.278 },  -- pack of 4
  { 0.064, -1.208 }, { 0.064, -1.281 },                                        -- pack of 2
}

function rttBatsSetup(cx, cz, flip)
  local board = rttFindSeatBoard(cx, cz)
  if board == nil then return end
  local asmWorld = board.positionToWorld({ RTT_BATS_ASM[1], 0.254, RTT_BATS_ASM[2] })
  local placed = false
  for _, o in ipairs(getAllObjects()) do
    if (not placed) and (o.getName() or "") == "Assembly" then
      if o.getLock and o.getLock() then o.setLock(false) end
      o.setPositionSmooth({ asmWorld.x, asmWorld.y + 0.3, asmWorld.z }, false, true)
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
    warriors[i].setPositionSmooth({ w.x, w.y + 0.5, w.z }, false, true)
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
  -- the Tower marks the central clearing; its suit marker is the nearest "Clearing Marker"
  local towers = getObjectsWithTag("Tower")
  local cx, cz = RTT_MTN_LM[1], RTT_MTN_LM[3]
  if towers[1] ~= nil then local tp = towers[1].getPosition() cx, cz = tp.x, tp.z end
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
  -- the landmark REPLACES the tower + the central suit marker
  for _, v in ipairs(towers) do pcall(function() v.destruct() end) end
  if marker ~= nil then pcall(function() marker.destruct() end) end
  rttSpawnLandmarkAt(name, RTT_MTN_LM[1], RTT_MTN_LM[2], RTT_MTN_LM[3],
                     RTT_MTN_CARD[1], RTT_MTN_CARD[2], RTT_MTN_CARD[3])
end

-- spawn a landmark's model (standing) + its rules card (rules side up) DIRECTLY at their
-- final transforms, so they appear in place and just settle onto the board like the other
-- map pieces — no visible slide/rotate. spawnObjectJSON's position/rotation override the
-- data's baked (flat) transform. EVERYTHING is on this board (self), so it's in scope.
function rttSpawnLandmarkAt(name, mx, my, mz, cx, cy, cz)
  local lm = EVERYTHING['Landmarks'][name]
  if lm == nil or lm['data'] == nil then return end
  for _, v in ipairs(lm['data']) do
    if string.find(v.json, "CardID", 1, true) ~= nil then
      spawnObjectJSON({
        json = v.json,
        position = { cx, cy, cz },
        rotation = { 0, 180, 0 },                 -- rotZ 0 = rules side up
        callback_function = function(o)
          o.addTag("Map Object")
          pcall(function() o.setScale({ RTT_MTN_CARD_SCALE, 1.0, RTT_MTN_CARD_SCALE }) end)
        end
      })
    else
      spawnObjectJSON({
        json = v.json,
        position = { mx, my, mz },
        rotation = { 0, 165, 0 },                 -- standing signpost, in place
        callback_function = function(o) o.addTag("Map Object") end
      })
    end
  end
end
""" % {
    "forest_uv": forest_uv,
    "relic_pos": relic_pos,
    "wx": LIZARD_WIZ_POS[0], "wy": LIZARD_WIZ_POS[1], "wz": LIZARD_WIZ_POS[2],
    "px": POND_SHIFT_POS[0], "py": POND_SHIFT_POS[1], "pz": POND_SHIFT_POS[2],
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
