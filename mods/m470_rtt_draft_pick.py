"""
m470 — RTT draft on LIGHTWEIGHT per-player selector boards + P1/P2 map+deck pick.

Adrien's key requirement: do NOT clone the giant menu board (its LuaScript is ~4.3 MB
of map/faction/tool data + 538 UI assets) — cloning it 4x is what lags the game and
makes the button art flash then go white. Instead we spawn a tiny purpose-built
Custom_Tile: the same wood texture, ONLY the map/deck pick UI, a ~1 KB relay script,
and ONLY the ~9 map/deck icons it needs. Fast to spawn, no lag, no white flash.

The central menu board (GUID bab7e1) stays the untouched COORDINATOR: it holds turn
order + all draft state and drives each selector's UI (cross-object UI.setAttribute).
Each selector's buttons RELAY clicks back to the coordinator (own Lua context).

Phase 0-2: capture RTT_ORDER (solo test => a full 4-board layout the one tester drives),
spawn the selectors, Player 1 picks a map OR deck on their own board, the chosen
category switches off, Player 2 picks the leftover on theirs. Faction draft (phase 3)
reuses these same lightweight boards.
"""
import json

from . import framework

NAME = "RTT draft: lightweight per-player selector boards + P1/P2 map+deck pick"

MAKEMAP_SIG = "function makeMap(player,value,id)"

# m250's rttDealOrder deal loop -> also capture RTT_ORDER + start the pick.
OLD_DEAL = (
    "          for _,p in ipairs(seated) do\n"
    "            if ord ~= nil and ord.deal then ord.deal(1, p.color) end\n"
    "          end"
)
NEW_DEAL = (
    "          RTT_ORDER = {}\n"
    "          for _,p in ipairs(seated) do RTT_ORDER[#RTT_ORDER+1] = {color=p.color, name=p.steam_name} end\n"
    "          for i=#RTT_ORDER,2,-1 do local j=math.random(i) RTT_ORDER[i],RTT_ORDER[j]=RTT_ORDER[j],RTT_ORDER[i] end\n"
    "          -- deal one order card to each ACTUAL seated player FIRST (before any solo\n"
    "          -- re-map), so the real players get their card in hand.\n"
    "          for _,e in ipairs(RTT_ORDER) do\n"
    "            if ord ~= nil and ord.deal then ord.deal(1, e.color) end\n"
    "          end\n"
    "          RTT_SOLO = (#RTT_ORDER <= 1)\n"
    "          if RTT_SOLO then\n"
    "            local nm = RTT_ORDER[1] and RTT_ORDER[1].name or ''\n"
    "            RTT_ORDER = {}\n"
    "            for _,c in ipairs({'Red','Yellow','Teal','Orange'}) do RTT_ORDER[#RTT_ORDER+1] = {color=c, name=nm} end\n"
    "          end\n"
    "          Wait.time(function() rttBeginPick() end, 1.2)"
)

# ---- the lightweight selector's OWN tiny script: just relay clicks to the coordinator
RELAY_LUA = (
    'RTT_COORD_GUID = "bab7e1"\n'
    'function rttPickRelay(player, value, id)\n'
    '  local c = getObjectFromGUID(RTT_COORD_GUID)\n'
    '  if c ~= nil then c.call("rttCoordPick", { color = player.color, id = id }) end\n'
    'end\n'
    'function rttFacRelay(player, value, id)\n'
    '  local c = getObjectFromGUID(RTT_COORD_GUID)\n'
    '  if c ~= nil then c.call("rttCoordFaction", { color = player.color, id = id }) end\n'
    'end'
)

# ---- the lightweight selector's OWN XmlUI: only the 3x3 map/deck pick grid
_SZ = 'width="34" height="34" fontSize="8"'
PICK_XML = (
    '<ToggleGroup id="rttPickMapDeck" active="false">'
    '<Text id="rttPickTitle" text="" position="0 60 -20" width="240" height="14" fontSize="11" color="#f3e9cf"/>'
    '<Button id="rttPickMap1" onclick="rttPickRelay" icon="Autumn Map"   color="#4b4d35" position="-40 34 -20" ' + _SZ + '/>'
    '<Button id="rttPickMap2" onclick="rttPickRelay" icon="Winter Map"   color="#6b8a8f" position="0 34 -20" ' + _SZ + '/>'
    '<Button id="rttPickMap3" onclick="rttPickRelay" icon="Lake Map"     color="#42a0c2" position="40 34 -20" ' + _SZ + '/>'
    '<Button id="rttPickMap4" onclick="rttPickRelay" icon="Marsh Map"    color="#9b8551" position="-40 -2 -20" ' + _SZ + '/>'
    '<Button id="rttPickMap5" onclick="rttPickRelay" icon="Mountain Map" color="#764a52" position="0 -2 -20" ' + _SZ + '/>'
    '<Button id="rttPickMap6" onclick="rttPickRelay" icon="Gorge Map"    color="#61746b" position="40 -2 -20" ' + _SZ + '/>'
    '<Button id="rttPickDeck1" onclick="rttPickRelay" icon="Standard Deck"              color="#8d7f81" position="-40 -38 -20" ' + _SZ + '/>'
    '<Button id="rttPickDeck2" onclick="rttPickRelay" icon="Exiles and Partisans Deck"  color="#378f90" position="0 -38 -20" ' + _SZ + '/>'
    '<Button id="rttPickDeck3" onclick="rttPickRelay" icon="Squires and Disciples Deck" color="#AB6894" position="40 -38 -20" ' + _SZ + '/>'
    '</ToggleGroup>'
    # the faction selector (phase 3): 5 buttons, icons set by the coordinator to the
    # available drafted factions; only shown on the current player's board in reverse order.
    '<ToggleGroup id="rttFactions" active="false">'
    '<Text id="rttFacTitle" text="Pick your faction" position="0 62 -20" width="240" height="14" fontSize="11" color="#f3e9cf"/>'
    '<Button id="rttFac1" onclick="rttFacRelay" position="-46 30 -20" width="42" height="42"/>'
    '<Button id="rttFac2" onclick="rttFacRelay" position="0 30 -20" width="42" height="42"/>'
    '<Button id="rttFac3" onclick="rttFacRelay" position="46 30 -20" width="42" height="42"/>'
    '<Button id="rttFac4" onclick="rttFacRelay" position="-23 -18 -20" width="42" height="42"/>'
    '<Button id="rttFac5" onclick="rttFacRelay" position="23 -18 -20" width="42" height="42"/>'
    '</ToggleGroup>'
)

# only the icons the selector actually uses (map/deck for the pick + faction icons for
# the draft) — ~21 of the 538 the menu board carries.
SELECTOR_ASSET_NAMES = {
    "Autumn Map", "Winter Map", "Lake Map", "Marsh Map", "Mountain Map", "Gorge Map",
    "Standard Deck", "Exiles and Partisans Deck", "Squires and Disciples Deck",
    "Marquise de Cat", "Eyrie Dynasties", "Woodland Alliance", "The Lizard Cult",
    "Riverfolk Company", "Underground Duchy", "Corvid Conspiracy", "Lord of the Hundreds",
    "Keepers in Iron", "Twilight Council", "Lilypad Diaspora", "Knaves of the Deepwood",
}

# ---- the coordinator's logic (runs on the menu board). %s = the selector object JSON.
COORD_LUA = r"""
-- ===== RTT lightweight per-player selectors + P1/P2 map/deck pick =====
RTT_SELECTOR_TAG = "RTT Selector"
RTT_ORDER = RTT_ORDER or {}
RTT_CLONES = {}
RTT_PICKED = { map = nil, deck = nil }
RTT_PICK_STAGE = 0
RTT_SOLO = false
RTT_SELECTOR_JSON = [===[%s]===]

RTT_PICK_DEFS = {
  rttPickMap1  = { kind = "map",  id = "Summer Map",   label = "Autumn" },
  rttPickMap2  = { kind = "map",  id = "Winter Map",   label = "Winter" },
  rttPickMap3  = { kind = "map",  id = "Lake Map",     label = "Lake" },
  rttPickMap4  = { kind = "map",  id = "Marsh Map",    label = "Marsh" },
  rttPickMap5  = { kind = "map",  id = "Mountain Map", label = "Mountain" },
  rttPickMap6  = { kind = "map",  id = "Gorge Map",    label = "Gorge" },
  rttPickDeck1 = { kind = "deck", id = "Standard Deck",              label = "Standard" },
  rttPickDeck2 = { kind = "deck", id = "Exiles and Partisans Deck",  label = "Exiles & Partisans" },
  rttPickDeck3 = { kind = "deck", id = "Squires and Disciples Deck", label = "Squires & Disciples" },
}
RTT_MAP_BTNS  = { "rttPickMap1", "rttPickMap2", "rttPickMap3", "rttPickMap4", "rttPickMap5", "rttPickMap6" }
RTT_DECK_BTNS = { "rttPickDeck1", "rttPickDeck2", "rttPickDeck3" }
-- the six board positions (from the old 6-board spawner)
RTT_POS = { { 52, -46 }, { -52, -46 }, { 52, 46 }, { -52, 46 }, { 0, -46 }, { 0, 46 } }
-- counterclockwise seating: P4 sits across from P1 (pos3 vs pos1), P3 across from P2
-- (pos4 vs pos2). RTT_POS: 1=(52,-46) 2=(-52,-46) 3=(52,46) 4=(-52,46).
RTT_LAYOUT = {
  [1] = { 1 }, [2] = { 1, 3 }, [3] = { 1, 2, 3 },
  [4] = { 1, 2, 4, 3 }, [5] = { 1, 2, 5, 4, 3 }, [6] = { 1, 2, 5, 6, 4, 3 },
}

function rttSpawnSelectors()
  for _, o in ipairs(getObjectsWithTag(RTT_SELECTOR_TAG)) do o.destruct() end
  RTT_CLONES = {}
  local n = #RTT_ORDER
  local layout = RTT_LAYOUT[n] or RTT_LAYOUT[4]
  for i, e in ipairs(RTT_ORDER) do
    local p = RTT_POS[layout[i] or i] or RTT_POS[1]
    local board = spawnObjectJSON({
      json = RTT_SELECTOR_JSON,
      position = { p[1], 11.56, p[2] },
      rotation = { 0, (p[2] > 0) and 180 or 0, 0 },
      callback_function = function(o) o.setLock(true) o.addTag(RTT_SELECTOR_TAG) end
    })
    RTT_CLONES[e.color] = board
  end
end

function rttBeginPick()
  if #RTT_ORDER < 1 then return end
  RTT_PICKED = { map = nil, deck = nil }
  RTT_PICK_STAGE = 1
  rttSpawnSelectors()          -- the central menu board is NEVER touched
  Wait.frames(function() rttShowPick(1) end, 40)
end

function rttShowPick(stage)
  local seat = (stage == 1) and RTT_ORDER[1] or (RTT_ORDER[2] or RTT_ORDER[1])
  local clone = RTT_CLONES[seat.color]
  if clone == nil then return end
  clone.UI.setAttribute("rttPickMapDeck", "active", "true")
  for _, b in ipairs(RTT_MAP_BTNS)  do clone.UI.setAttribute(b, "active", (RTT_PICKED.map  == nil) and "true" or "false") end
  for _, b in ipairs(RTT_DECK_BTNS) do clone.UI.setAttribute(b, "active", (RTT_PICKED.deck == nil) and "true" or "false") end
  local what = (stage == 1) and "Pick a MAP or a DECK" or ("Pick the " .. ((RTT_PICKED.map == nil) and "MAP" or "DECK"))
  clone.UI.setAttribute("rttPickTitle", "text", what)
end

function rttPlaceMap(mapId)
  makeMap("", "", mapId)
  Wait.frames(function() makeSpecialWithTag("Tools", "Battle Mat", 33.17, 1.55, 9.21, "Map Object") end, 2)
  if mapId == "Mountain Map" then
    Wait.time(function() for _, v in ipairs(getObjectsWithTag("Tower")) do v.destruct() end end, 0.8)
  end
end

function rttPlaceDeck(deckId)
  local id = deckId
  if #RTT_ORDER <= 2 then id = id .. " 2" end
  makeDeck("", "", id)
end

-- runs on the COORDINATOR (relayed from a selector)
function rttCoordPick(args)
  local def = RTT_PICK_DEFS[args.id]
  if def == nil or RTT_PICK_STAGE == 0 then return end
  local seat = (RTT_PICK_STAGE == 1) and RTT_ORDER[1] or (RTT_ORDER[2] or RTT_ORDER[1])
  if (not RTT_SOLO) and args.color ~= seat.color then return end
  local clone = RTT_CLONES[seat.color]

  if RTT_PICK_STAGE == 1 then
    if def.kind == "map" then RTT_PICKED.map = def.id rttPlaceMap(def.id)
    else RTT_PICKED.deck = def.id rttPlaceDeck(def.id) end
    if clone ~= nil then clone.UI.setAttribute("rttPickMapDeck", "active", "false") end
    RTT_PICK_STAGE = 2
    rttShowPick(2)
    return
  end

  if RTT_PICKED.map == nil and def.kind ~= "map" then return end
  if RTT_PICKED.deck == nil and def.kind ~= "deck" then return end
  if def.kind == "map" then RTT_PICKED.map = def.id rttPlaceMap(def.id)
  else RTT_PICKED.deck = def.id rttPlaceDeck(def.id) end
  if clone ~= nil then clone.UI.setAttribute("rttPickMapDeck", "active", "false") end
  RTT_PICK_STAGE = 0
  rttStartFactionDraft()
end

-- ===== phase 3: reverse-order faction draft off the 5 dealt cards =====
RTT_FAC_STAGE = 0
RTT_FAC_TAKEN = {}
RTT_FAC_CURRENT = {}

function rttStartFactionDraft()
  RTT_FAC_TAKEN = {}
  RTT_VP_PLACED = 0
  _G['Roster'] = {}
  for i = 1, #RTT_ORDER do _G['Roster'][i] = RTT_ORDER[i].name or "" end
  if _G['vagabondAlreadySpawned'] == nil then _G['vagabondAlreadySpawned'] = false end
  Wait.time(function() rttDealHands() end, 0.6)     -- 5 cards to each player from the picked deck
  RTT_FAC_STAGE = #RTT_ORDER                        -- reverse order: last seat drafts first
  Wait.frames(function() rttShowFactions() end, 40)
end

function rttDealHands()
  local d = nil
  for _, p in ipairs(getObjectsWithTag("Deck Object")) do
    if p.name == "Deck" then d = p end
  end
  if d == nil then return end
  local seated = {}
  for _, p in ipairs(Player.getPlayers()) do
    if p.seated and p.color ~= "Grey" and p.color ~= "Black" then seated[#seated + 1] = p.color end
  end
  if #seated == 0 then return end        -- real players only; never deal into the void
  rttDealOne(d, seated, 1, 1)            -- one card at a time, around the table
end

function rttDealOne(d, seated, card, who)
  if card > 5 then return end
  if who > #seated then rttDealOne(d, seated, card + 1, 1) return end
  if d ~= nil and d.deal then d.deal(1, seated[who]) end
  Wait.time(function() rttDealOne(d, seated, card, who + 1) end, 0.15)
end

function rttShowFactions()
  if RTT_FAC_STAGE < 1 then return end
  local seat = RTT_ORDER[RTT_FAC_STAGE]
  local clone = RTT_CLONES[seat.color]
  if clone == nil then return end
  RTT_FAC_CURRENT = {}
  for _, f in ipairs(RTT_DRAFT_FACTIONS or {}) do
    if f ~= nil and not RTT_FAC_TAKEN[f] then RTT_FAC_CURRENT[#RTT_FAC_CURRENT + 1] = f end
  end
  clone.UI.setAttribute("rttPickMapDeck", "active", "false")
  clone.UI.setAttribute("rttFactions", "active", "true")
  for i = 1, 5 do
    local f = RTT_FAC_CURRENT[i]
    if f ~= nil then
      clone.UI.setAttribute("rttFac" .. i, "icon", f)
      clone.UI.setAttribute("rttFac" .. i, "active", "true")
    else
      clone.UI.setAttribute("rttFac" .. i, "active", "false")
    end
  end
end

function rttCoordFaction(args)
  if RTT_FAC_STAGE < 1 then return end
  local seat = RTT_ORDER[RTT_FAC_STAGE]
  if (not RTT_SOLO) and args.color ~= seat.color then return end
  local idx = tonumber(string.sub(args.id, -1))
  local faction = RTT_FAC_CURRENT[idx]
  if faction == nil or RTT_FAC_TAKEN[faction] then return end
  RTT_FAC_TAKEN[faction] = true
  local clone = RTT_CLONES[seat.color]
  if clone ~= nil then clone.UI.setAttribute("rttFactions", "active", "false") end
  -- remove the board FIRST (so it doesn't visibly linger), THEN spawn the faction there
  local bp = (clone ~= nil) and clone.getPosition() or Vector(0, 11.56, 0)
  RTT_CLONES[seat.color] = nil
  if clone ~= nil then clone.destruct() end
  rttSpawnFaction(faction, bp.x, bp.z, bp.z > 0)     -- no dice; warriors baked in the data
  RTT_VP_PLACED = (RTT_VP_PLACED or 0) + 1           -- put this faction's VP marker on score 0
  local vpN, vpF = RTT_VP_PLACED, faction
  Wait.time(function() rttPlaceVP(vpF, vpN) end, 1.2)   -- after the pieces (VP marker) settle
  if faction == "Woodland Alliance" then spawnSupportersHand(seat.color) end
  if faction == "Knaves of the Deepwood" then
    Wait.time(function() rttKnavesCaptains(seat.color) end, 1.0)
  end
  RTT_FAC_STAGE = RTT_FAC_STAGE - 1
  if RTT_FAC_STAGE >= 1 then
    Wait.frames(function() rttShowFactions() end, 20)
  end
end

-- spawn a faction's pieces at (cx,cz), WITHOUT dice (m060). Warrior placements (m290
-- Lizard, m300 Duchy) are baked into the faction data, so they come along. flip rotates
-- the setup 180 for a far-side (z>0) seat. Mirrors tournamentSpawnDraftFaction's math.
function rttSpawnFaction(faction, cx, cz, flip)
  local objects = {}
  for _, v in ipairs(EVERYTHING['Standard'][faction]['data']) do
    if not string.find(v.json, '"Name": "Custom_Dice"', 1, true) then objects[#objects + 1] = v end
  end
  local scale = self.getScale()
  scale.x = 1 / scale.x
  scale.z = 1 / scale.z
  local function cb(o)
    if flip then o.setRotation({ o.getRotation().x, o.getRotation().y + 180, o.getRotation().z }) end
    if o.hasTag("Ruin Set") then o.destroy() end
    if o.hasTag("Shuffleable") then o.shuffle() o.shuffle() end
  end
  for _, v in ipairs(objects) do
    local vec = Vector(v.move_to) * scale
    if flip then vec = vec * Vector(-15.5, 1, -15.5) else vec = vec * Vector(15.5, 1, 15.5) end
    local new_pos = Vector(cx, 11.56, cz) + vec
    new_pos.y = new_pos.y - 0.1
    spawnObjectJSON({ json = v.json, position = new_pos, callback_function = cb })
  end
end

-- Knaves: draw 4 random Captains from the Knave board's captain deck (best-effort by name)
function rttKnavesCaptains(color)
  for _, o in ipairs(getAllObjects()) do
    local nm = o.getName() or ""
    if o.name == "Deck" and (string.find(nm, "Captain", 1, true) or string.find(nm, "Knave", 1, true)) then
      o.shuffle()
      o.deal(4, color)
      return
    end
  end
end

-- ===== RTT: move drafted-faction VP markers onto the map score track (col 0) =====
-- Ports the box-score tool's proven track detection + geometry.
RTT_TRACK          = RTT_TRACK or nil
RTT_SCORE0_AT_MIN  = false              -- score 0 sits at the track's LOCAL MAX (base-mod convention)
RTT_VP_PLACED      = RTT_VP_PLACED or 0

RTT_VP_SHORT = {
  ["Marquise de Cat"]        = "Marquise",
  ["Eyrie Dynasties"]        = "Eyrie",
  ["Woodland Alliance"]      = "Alliance",
  ["The Lizard Cult"]        = "Lizard",
  ["Riverfolk Company"]      = "Riverfolk",
  ["Underground Duchy"]      = "Duchy",
  ["Corvid Conspiracy"]      = "Crows",
  ["Lord of the Hundreds"]   = "Rats",
  ["Keepers in Iron"]        = "Badgers",
  ["Twilight Council"]       = "Council",
  ["Lilypad Diaspora"]       = "Diaspora",
  ["Knaves of the Deepwood"] = "Knaves",
}

function rttDetectTrackOn(obj)
  local ok, sp = pcall(function() return obj.getSnapPoints() end)
  if not ok or sp == nil or #sp < 40 then return nil end
  local bandsFound = {}
  for _, axis in ipairs({ "x", "z" }) do
    local other = (axis == "x") and "z" or "x"
    local pts = {}
    for _, s in ipairs(sp) do table.insert(pts, { a = s.position[axis], b = s.position[other] }) end
    table.sort(pts, function(p, q) return p.b < q.b end)
    local bands, cur = {}, {}
    for _, p in ipairs(pts) do
      if #cur > 0 and (p.b - cur[#cur].b) > 0.03 then table.insert(bands, cur); cur = {} end
      table.insert(cur, p)
    end
    if #cur > 0 then table.insert(bands, cur) end
    for _, band in ipairs(bands) do
      if #band >= 25 then
        local xs = {}
        for _, p in ipairs(band) do table.insert(xs, p.a) end
        table.sort(xs)
        local diffs = {}
        for i = 2, #xs do table.insert(diffs, xs[i] - xs[i - 1]) end
        table.sort(diffs)
        local s = diffs[math.ceil(#diffs / 2)]
        local even = s and s > 0.01
        if even then
          for _, d in ipairs(diffs) do
            local mrep = math.floor(d / s + 0.5)
            if mrep < 1 or mrep > 2 or math.abs(d - mrep * s) > 0.25 * s then even = false end
          end
        end
        if even then
          local n = math.floor((xs[#xs] - xs[1]) / s + 0.5) + 1
          if n >= 28 and n <= 60 and #xs >= 0.85 * n then
            table.insert(bandsFound, { axis = axis, other = other, a0 = xs[1], s = s, n = n, b = band[1].b })
          end
        end
      end
    end
  end
  if #bandsFound == 0 then return nil end
  local best = nil
  for _, band in ipairs(bandsFound) do
    if best == nil then
      best = { axis = band.axis, other = band.other, a0 = band.a0, s = band.s, n = band.n, rows = { band.b } }
    elseif band.axis == best.axis
      and math.abs(band.s - best.s) < 0.1 * best.s
      and math.abs(band.a0 - best.a0) < 0.5 * best.s then
      table.insert(best.rows, band.b)
      if band.n > best.n then best.n = band.n end
    end
  end
  table.sort(best.rows)
  best.pts = {}
  local bmin, bmax = best.rows[1] - 0.05, best.rows[#best.rows] + 0.05
  for _, s2 in ipairs(sp) do
    local a = (best.axis == "x") and s2.position.x or s2.position.z
    local b = (best.axis == "x") and s2.position.z or s2.position.x
    if b >= bmin and b <= bmax then table.insert(best.pts, { a = a, b = b }) end
  end
  best.guid = obj.getGUID()
  return best
end

function rttFindScoreTrack()
  if RTT_TRACK ~= nil then
    local o = getObjectFromGUID(RTT_TRACK.guid)
    if o ~= nil then return o end
    RTT_TRACK = nil
  end
  local best, bestSnaps = nil, 0
  for _, o in ipairs(getAllObjects()) do
    local ok, sp = pcall(function() return o.getSnapPoints() end)
    if ok and sp and #sp >= 40 and #sp > bestSnaps then
      local t = rttDetectTrackOn(o)
      if t then best, bestSnaps = t, #sp end
    end
  end
  RTT_TRACK = best
  if best == nil then return nil end
  return getObjectFromGUID(best.guid)
end

function rttZeroColumnSlots()
  if rttFindScoreTrack() == nil then return {} end
  local t = RTT_TRACK
  local cellIdx = RTT_SCORE0_AT_MIN and 0 or (t.n - 1)
  local cellA   = t.a0 + cellIdx * t.s
  local mid     = t.rows[math.ceil(#t.rows / 2)]
  local slots = {}
  for _, p in ipairs(t.pts or {}) do
    if math.abs(p.a - cellA) < 0.45 * t.s then slots[#slots + 1] = { a = p.a, b = p.b } end
  end
  table.sort(slots, function(p, q) return math.abs(p.b - mid) < math.abs(q.b - mid) end)
  local step = 0.11
  if #t.rows >= 2 then step = (t.rows[#t.rows] - t.rows[1]) / (#t.rows - 1) end
  for _, b in ipairs({ mid - 2 * step, mid + 2 * step, mid - 3 * step, mid + 3 * step }) do
    slots[#slots + 1] = { a = cellA, b = b }
  end
  return slots
end

function rttSlotWorld(slot)
  if RTT_TRACK == nil or slot == nil then return nil end
  local map = getObjectFromGUID(RTT_TRACK.guid)
  if map == nil then return nil end
  local lp = { x = 0, y = 2.0, z = 0 }
  lp[RTT_TRACK.axis]  = slot.a
  lp[RTT_TRACK.other] = slot.b
  return map.positionToWorld(lp)
end

function rttFindVPMarker(faction)
  local short = RTT_VP_SHORT[faction] or faction
  local want  = short .. " VP"
  local held  = nil
  for _, o in ipairs(getAllObjects()) do
    if o ~= nil and (o.getName() or "") == want then
      if o.held_by_color == nil then return o end
      held = held or o
    end
  end
  return held
end

function rttPlaceVP(faction, n)
  if faction == nil then return false end
  if rttFindScoreTrack() == nil then return false end
  local m = rttFindVPMarker(faction)
  if m == nil then return false end
  local slots = rttZeroColumnSlots()
  if #slots == 0 then return false end
  local idx = math.max(1, math.min(#slots, n or 1))
  local wp  = rttSlotWorld(slots[idx])
  if wp == nil then return false end
  if m.getLock and m.getLock() then m.setLock(false) end
  m.setPositionSmooth({ wp.x, wp.y + 0.12, wp.z }, false, true)
  return true
end

"""


def _build_selector_json(text):
    """Build the lightweight selector object from the menu board's texture + the 9
    map/deck icons it needs (parsed from the compiled board object)."""
    start, end = framework._object_span(text, "bab7e1")
    board = json.loads(text[start:end])
    assets = [a for a in (board.get("CustomUIAssets") or []) if a.get("Name") in SELECTOR_ASSET_NAMES]
    if len(assets) < len(SELECTOR_ASSET_NAMES):
        raise framework.BuildError("selector icons missing: found %d/%d"
                                   % (len(assets), len(SELECTOR_ASSET_NAMES)))
    light = {
        "Name": "Custom_Tile",
        "Transform": {"posX": 0.0, "posY": 11.56, "posZ": 0.0,
                      "rotX": 0.0, "rotY": 0.0, "rotZ": 0.0,
                      "scaleX": 15.5, "scaleY": 1.0, "scaleZ": 15.5},
        "Nickname": "", "Description": "", "GMNotes": "",
        "Locked": True, "Grid": False, "Snap": False, "IgnoreFoW": False,
        "CustomImage": board["CustomImage"],
        "LuaScript": RELAY_LUA,
        "XmlUI": PICK_XML,
        "CustomUIAssets": assets,
        "Tags": ["RTT Selector"],
    }
    return json.dumps(light, separators=(",", ":"))


def apply(text):
    if text.count(MAKEMAP_SIG) != 1:
        raise framework.BuildError("makeMap anchor not unique")
    selector_json = _build_selector_json(text)
    if "]===]" in selector_json:
        raise framework.BuildError("selector JSON contains ]===] — bracket clash")
    coord_lua = COORD_LUA % selector_json
    text = text.replace(MAKEMAP_SIG, framework.esc(coord_lua) + MAKEMAP_SIG, 1)
    text = framework.replace_unique(text, framework.esc(OLD_DEAL), framework.esc(NEW_DEAL))
    return text
