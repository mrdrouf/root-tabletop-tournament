"""
m490 — per-faction setup extras, dispatched after each drafted faction spawns.

Hooks a single dispatcher (rttFactionExtras) into the draft's rttCoordFaction (m470),
called ~1.2s after a faction's pieces settle. Per faction:

  * The Lizard Cult   -> spawn the "Lizard Wizard" Tool (its option drops the Lost Souls
                         discard by the card decks), remove the unused Outcast Marker,
                         and reposition the frogs' Pond if it is already out.
  * Lilypad Diaspora  -> shuffle the 14 frog cards (Description "Frog", CardID 74000-13)
    (frogs)              into the shared deck, and place The Pond next to the discard —
                         shifted aside when the Lizard's Lost Souls is also in play.
  * Keepers in Iron   -> scatter the relics into the map's forests (one per forest at the
    (badgers)            forest's clearing-centroid; extra relics stay put for the player).
  * Twilight Council  -> (bats) filled in once the board's assembly snap is confirmed.
    (bats)

Forest centres come from root_engine's per-map geometry (mean of each forest's clearing
UVs), converted to world at runtime through the live map tile's bounds + Y-rotation.
"""
import json
import os

from . import framework

NAME = "per-faction setup extras (Lizard/frogs/Badgers) after the draft spawn"

# Adrien's staged reference spots (from his TTS save): the Lizard Wizard / Lost Souls
# sits here; the frogs' Pond sits here too when Lizard is absent, or shifts aside when
# both are in play so the two discards never overlap.
LIZARD_WIZ_POS = (-31.325, 11.562, 12.278)
POND_SHIFT_POS = (-31.217, 11.562, 21.567)

DISPATCH = ('\n  Wait.time(function() rttFactionExtras(faction, bp.x, bp.z, bp.z > 0) end, 1.2)')

# Mountain: the base rttPlaceMap just destroys the Tower; replace that with the landmark
# roll (0->Lost City, else the suit landmark) placed on the mountain-top clearing.
MTN_TOWER_ANCHOR = ('  if mapId == "Mountain Map" then\n'
                    '    Wait.time(function() for _, v in ipairs(getObjectsWithTag("Tower")) do v.destruct() end end, 0.8)\n'
                    '  end')
MTN_TOWER_NEW = ('  if mapId == "Mountain Map" then\n'
                 '    Wait.time(function() rttMountainLandmark() end, 0.8)\n'
                 '  end')

# Adrien's placed Mousehold spot = the mountain-top clearing where the landmark goes.
MTN_LM_POS = (2.46, 11.66, 6.03)
# map lower-left corner (best guess — confirm in TTS) for the landmark's rules card.
MTN_CARD_POS = (-22.0, 11.70, -22.0)

KNAVES_ANCHOR = ('  if faction == "Knaves of the Deepwood" then\n'
                 '    Wait.time(function() rttKnavesCaptains(seat.color) end, 1.0)\n'
                 '  end')


def _extra_lua():
    forest_uv = open(os.path.join(os.path.dirname(__file__), "_forest_uv_lua.txt"),
                     encoding="utf-8").read()
    return r"""
-- ===== RTT per-faction setup extras =====
%(forest_uv)s

RTT_LIZ_WIZ = { %(wx).3f, %(wy).3f, %(wz).3f }
RTT_POND_SHIFT = { %(px).3f, %(py).3f, %(pz).3f }

function rttFactionExtras(faction, cx, cz, flip)
  if faction == "The Lizard Cult" then rttLizardSetup()
  elseif faction == "Lilypad Diaspora" then rttFrogsSetup()
  elseif faction == "Keepers in Iron" then rttBadgerRelics()
  elseif faction == "Twilight Council" then rttBatsSetup(cx, cz, flip)
  elseif faction == "Corvid Conspiracy" then rttCrowsPlots(cx, cz, flip)
  end
end

-- ---- Corvid Conspiracy (crows): 12 plots, 3 of each type, in a clean 4x3 grid --------
-- Adrien could not align them by hand; RTT_CROW_PLOTS holds his 12 (grouped 3-per-type)
-- and we lay them out on board-local columns/rows (measured from his setup), removing the
-- base spawn's loose plots first.
RTT_CROW_COLS = { -0.400, -0.577, -0.754, -0.931 }   -- one column per plot type
RTT_CROW_ROWS = { -1.166, -1.353, -1.540 }           -- 3 rows

function rttCrowsPlots(cx, cz, flip)
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

-- ---- Lizard Cult ----------------------------------------------------------
function rttLizardSetup()
  makeSpecialWithTag("Tools", "Lizard Wizard",
    RTT_LIZ_WIZ[1], RTT_LIZ_WIZ[2], RTT_LIZ_WIZ[3], "Faction")
  Wait.time(function()
    for _, o in ipairs(getAllObjects()) do
      if (o.getName() or "") == "Outcast Marker" then pcall(function() o.destruct() end) end
    end
  end, 0.8)
  Wait.time(function() rttRepositionPond() end, 1.0)   -- slide the Pond aside if it is out
end

-- ---- Lilypad Diaspora (frogs) --------------------------------------------
function rttFrogsSetup()
  rttShuffleFrogsIntoDeck()
  Wait.time(function() rttRepositionPond() end, 1.0)
end

-- Pond default = the Lost-Souls spot; when the Lizard is also drafted, shift it aside so
-- the frog Pond and the Lizard's Lost Souls discard do not collide by the card decks.
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

-- gather every frog card (Description "Frog") + the frog deck, merge into the shared
-- clearing deck, and shuffle. Identified by content, not GUID (draft spawns are fresh).
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

-- ---- Keepers in Iron (badgers): relics into forests -----------------------
-- the live map tile is the biggest snap-point object; convert each forest's centroid UV
-- to world via the tile's bounds (full width/depth) and Y-rotation, then drop a relic.
function rttFindMapObject()
  local best, bestN = nil, 0
  for _, o in ipairs(getAllObjects()) do
    local ok, sp = pcall(function() return o.getSnapPoints() end)
    if ok and sp and #sp > bestN then best, bestN = o, #sp end
  end
  return best
end

function rttForestWorldCenters(mapId)
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

-- the 12 relics live in a Bag named "Relics"; draw one per forest onto its centre (the
-- bag randomises the type), leaving the extra relics in the bag for the player to place.
function rttBadgerRelics()
  local mapId = (RTT_PICKED or {}).map
  if mapId == nil then return end
  local centers = rttForestWorldCenters(mapId)
  if #centers == 0 then return end
  local bag = nil
  for _, o in ipairs(getAllObjects()) do
    if o.name == "Bag" and (o.getName() or "") == "Relics" then bag = o break end
  end
  if bag == nil then return end
  pcall(function() bag.shuffle() end)
  local y = 12.0
  for _, c in ipairs(centers) do
    pcall(function()
      bag.takeObject({ position = { c[1], y, c[2] }, rotation = { 0, 180, 0 }, smooth = true })
    end)
  end
end

-- ---- Twilight Council (bats) ---------------------------------------------
-- board-local offsets (world delta / board scale 9.035): assembly first snap, and the
-- "pack of 4 + pack of 2" warrior arrangement, measured from Adrien's setup.
RTT_BATS_ASM = { -0.032, -0.253 }
RTT_BATS_WAR = {
  { 0.354, -1.204 }, { 0.354, -1.278 }, { 0.494, -1.204 }, { 0.494, -1.278 },  -- pack of 4
  { 0.064, -1.208 }, { 0.064, -1.281 },                                        -- pack of 2
}

function rttBatsSetup(cx, cz, flip)
  -- the Council board is the big faction tile that just spawned nearest the seat
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
  if board == nil then return end
  -- put ONE assembly on the board's first assembly snap
  local asmWorld = board.positionToWorld({ RTT_BATS_ASM[1], 0.254, RTT_BATS_ASM[2] })
  local placed = false
  for _, o in ipairs(getAllObjects()) do
    if (not placed) and (o.getName() or "") == "Assembly" then
      if o.getLock and o.getLock() then o.setLock(false) end
      o.setPositionSmooth({ asmWorld.x, asmWorld.y + 0.3, asmWorld.z }, false, true)
      placed = true
    end
  end
  -- arrange 6 Council Warriors as pack-of-4 + pack-of-2 just south of the board
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

-- ---- Mountain: landmark roll on the mountain-top clearing ------------------
RTT_MTN_LM = { %(mx).3f, %(my).3f, %(mz).3f }
RTT_MTN_CARD = { %(cx).3f, %(cy).3f, %(cz2).3f }

function rttMountainLandmark()
  for _, v in ipairs(getObjectsWithTag("Tower")) do pcall(function() v.destruct() end) end
  local roll = math.random(0, 3)                 -- 0..3; 0 => Lost City, else suit landmark
  local name = "Lost City"
  if roll ~= 0 then
    local suit = rttMiddleSuit()
    if suit == "rabbit" then name = "Rabbit-Town"
    elseif suit == "fox" then name = "Foxburrow"
    elseif suit == "mouse" then name = "Mousehold" end
    -- suit unknown -> stays "Lost City" (safe fallback; wire rttMiddleSuit once suit
    -- encoding is confirmed)
  end
  makeSpecialWithTag("Landmarks", name, RTT_MTN_LM[1], RTT_MTN_LM[2], RTT_MTN_LM[3], "Map Object")
  Wait.time(function() rttPlaceLandmarkCard() end, 1.2)
end

-- best-effort: no reliable suit token in the save, so return nil for now (Lost City).
function rttMiddleSuit()
  return nil
end

-- the landmark's rules card spawns beside the landmark; slide it to the map's lower-left
-- with the rules side up (rotZ 0 shows the rules face on the Lost City card).
function rttPlaceLandmarkCard()
  local best, bd = nil, 1e9
  for _, o in ipairs(getAllObjects()) do
    local n = o.name
    if n == "Card" or n == "CardCustom" then
      local p = o.getPosition()
      local d = (p.x - RTT_MTN_LM[1]) ^ 2 + (p.z - RTT_MTN_LM[3]) ^ 2
      if d < bd and d < 100 then bd = d; best = o end
    end
  end
  if best == nil then return end
  if best.getLock and best.getLock() then best.setLock(false) end
  best.setPositionSmooth({ RTT_MTN_CARD[1], RTT_MTN_CARD[2], RTT_MTN_CARD[3] }, false, true)
  best.setRotationSmooth({ 0, 180, 0 }, false, true)     -- rotZ 0 => rules side up
end
""" % {
    "forest_uv": forest_uv,
    "wx": LIZARD_WIZ_POS[0], "wy": LIZARD_WIZ_POS[1], "wz": LIZARD_WIZ_POS[2],
    "px": POND_SHIFT_POS[0], "py": POND_SHIFT_POS[1], "pz": POND_SHIFT_POS[2],
    "mx": MTN_LM_POS[0], "my": MTN_LM_POS[1], "mz": MTN_LM_POS[2],
    "cx": MTN_CARD_POS[0], "cy": MTN_CARD_POS[1], "cz2": MTN_CARD_POS[2],
}


def apply(text):
    sig = "function makeMap(player,value,id)"
    if text.count(sig) != 1:
        raise framework.BuildError("makeMap anchor not unique")
    text = text.replace(sig, framework.esc(_extra_lua()) + sig, 1)

    # the 12 Corvid plot blobs (grouped 3-per-type) — injected separately from the
    # %-formatted extras so their URLs (which contain %) are not treated as format specs.
    plots = json.load(open(os.path.join(os.path.dirname(__file__), "_corvid_plots.json"),
                           encoding="utf-8"))
    crow_lua = "\nRTT_CROW_PLOTS = {\n%s\n}\n" % ",\n".join("[==[%s]==]" % b for b in plots)
    text = text.replace(sig, framework.esc(crow_lua) + sig, 1)

    # dispatch the extras right after the Knaves hook inside rttCoordFaction
    anchor = framework.esc(KNAVES_ANCHOR)
    if text.count(anchor) != 1:
        raise framework.BuildError("rttCoordFaction Knaves anchor not unique for dispatch")
    text = text.replace(anchor, anchor + framework.esc(DISPATCH), 1)

    # Mountain: swap the plain tower-destroy for the landmark roll
    mtn_old = framework.esc(MTN_TOWER_ANCHOR)
    if text.count(mtn_old) != 1:
        raise framework.BuildError("Mountain tower-destroy anchor not unique")
    text = text.replace(mtn_old, framework.esc(MTN_TOWER_NEW), 1)
    return text
