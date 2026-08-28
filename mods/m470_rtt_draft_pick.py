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
import os

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
    "          -- joined players keep THEIR chosen colours; assign a RANDOM turn order.\n"
    "          local plist = {}\n"
    "          for _,p in ipairs(seated) do plist[#plist+1] = {color=p.color, name=p.steam_name} end\n"
    "          for i=#plist,2,-1 do local j=math.random(i) plist[i],plist[j]=plist[j],plist[i] end\n"
    "          -- N FIXED seats = draft size (RTT_DN-1), independent of how many humans joined\n"
    "          -- (this is what fixes 'only 2 boards with 2 players').\n"
    "          local _N = (RTT_DN or 5) - 1\n"
    "          RTT_ORDER = {}\n"
    "          for i=1,_N do RTT_ORDER[i] = plist[i] or {color=nil, name=''} end\n"
    "          RTT_ORDER_DECK = (ord ~= nil) and ord.getGUID() or nil   -- rttSeatAndDeal deals from it\n"
    "          Wait.time(function() rttBeginPick() end, 1.0)"
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
    '  if c ~= nil then c.call("rttCoordFaction", { color = player.color, id = id, board = self.getGUID() }) end\n'
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
    '<Text id="rttFacTitle" text="" position="0 64 -20" width="260" height="26" fontSize="20" color="#f3e9cf"/>'
    '<Button id="rttFac1" onclick="rttFacRelay" position="-46 30 -20" width="42" height="42"/>'
    '<Button id="rttFac2" onclick="rttFacRelay" position="0 30 -20" width="42" height="42"/>'
    '<Button id="rttFac3" onclick="rttFacRelay" position="46 30 -20" width="42" height="42"/>'
    '<Button id="rttFac4" onclick="rttFacRelay" position="-46 -18 -20" width="42" height="42"/>'
    '<Button id="rttFac5" onclick="rttFacRelay" position="0 -18 -20" width="42" height="42"/>'
    '<Button id="rttFac6" onclick="rttFacRelay" position="46 -18 -20" width="42" height="42"/>'
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
RTT_BOXSCORE_JSON = [====[%s]====]
RTT_BOXSCORE_TAG = "RTT BoxScore"

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

-- hand transform for each board position (base handPositions/handRotations, by x,z sign): the
-- player's hand sits just behind their board (z=±64 behind the board at z=±46).
RTT_SEAT_HAND = {
  { pos = { 52, 14.62, -64 }, rot = { 0, 0, 0 } },     -- pos1 (52,-46)
  { pos = { -52, 14.62, -64 }, rot = { 0, 0, 0 } },    -- pos2 (-52,-46)
  { pos = { 52, 14.62, 64 }, rot = { 0, 180, 0 } },    -- pos3 (52,46)
  { pos = { -52, 14.62, 64 }, rot = { 0, 180, 0 } },   -- pos4 (-52,46)
  { pos = { 0, 14.62, -64 }, rot = { 0, 0, 0 } },      -- pos5 (0,-46)
  { pos = { 0, 14.62, 64 }, rot = { 0, 180, 0 } },     -- pos6 (0,46)
}
RTT_SEATS = {}          -- [seat] = { board=obj, color=<colour|nil>, pos={x,z}, hand=<RTT_SEAT_HAND entry> }
RTT_BOARD_SEAT = {}     -- [board guid] = seat index

-- ==== seat-by-turn-order-card tables (RTT seating restore) ==================
RTT_SETUP_COLORS   = { "Red", "Yellow", "Orange", "Teal", "Green", "Brown" }   -- base setupColors: seat N -> colour N
RTT_HAND_SCALE     = { 20, 6, 4 }                                              -- base handScale (RTT had dropped it)
RTT_CARDID_FOR_N   = { 800, 801, 802, 805, 806 }                              -- seat N -> "Player N" order-card CardID
RTT_ORDER_CARD_NUM = { [800]=1, [801]=2, [802]=3, [805]=4, [806]=5 }           -- inverse: order-card CardID -> its number

function rttSpawnSelectors()
  for _, o in ipairs(getObjectsWithTag(RTT_SELECTOR_TAG)) do o.destruct() end
  RTT_CLONES = {}
  RTT_SEATS = {}
  RTT_BOARD_SEAT = {}
  local n = #RTT_ORDER                          -- the FIXED N seats (built in rttDealOrder)
  local layout = RTT_LAYOUT[n] or RTT_LAYOUT[4]
  for i = 1, n do
    local pi = layout[i] or i
    local p = RTT_POS[pi] or RTT_POS[1]
    local board = spawnObjectJSON({
      json = RTT_SELECTOR_JSON,
      position = { p[1], 11.56, p[2] },
      rotation = { 0, (p[2] > 0) and 180 or 0, 0 },
      callback_function = function(o) o.setLock(true) o.addTag(RTT_SELECTOR_TAG) end
    })
    RTT_BOARD_SEAT[board.getGUID()] = i
    RTT_SEATS[i] = { board = board, color = nil, pos = p, hand = RTT_SEAT_HAND[pi] }
  end
end

-- Seat by TURN-ORDER CARD, restoring the base placePlayer path (changeColor + base handPositions
-- geometry + base handScale) but TRIGGERED at turn-order time instead of on faction pick. ONE
-- shuffle sets the turn order; each player is seated at the seat matching their card's number and
-- then handed the matching "Player N" card, so it lands in the seated hand (not the off-table reset
-- strip at x=-77.5 that looked like "trash"). Uses the base's exact SAFE sequence: kick everyone to
-- Grey FIRST, then a FRESH getPlayers() loop matched by steam_name -- a pre-kick Player ref is stale
-- after the colour change, which is why capturing refs then kicking would seat nobody.
function rttSeatPlayers()
  local roster = {}                                     -- [N] = steam_name of the player in seat N
  for _, p in ipairs(Player.getPlayers()) do
    if p.seated and p.color ~= "Grey" and p.color ~= "Black" then roster[#roster + 1] = p.steam_name end
  end
  -- ONE randomisation = the turn order. After this, card number == seat (no second shuffle).
  for i = #roster, 2, -1 do local j = math.random(i) roster[i], roster[j] = roster[j], roster[i] end
  pcall(function() kickPlayersFromSeats() end)           -- base: everyone -> Grey (frees the colours; no hand reset)
  local seated = {}                                      -- [N] = seat colour, for the deferred card
  for _, p in ipairs(Player.getPlayers()) do             -- FRESH, post-kick (base pattern): refs are valid
    for N = 1, #roster do
      if p.steam_name == roster[N] then
        local seat = RTT_SEATS[N]
        if seat ~= nil and seat.board ~= nil and seat.hand ~= nil then
          local color = RTT_SETUP_COLORS[N]
          pcall(function() p.changeColor(color) end)     -- base placePlayer op 1: put the player INTO the seat colour
          pcall(function()                               -- base placePlayer op 2: move that colour's hand zone (+ base scale)
            Player[color].setHandTransform(
              { position = seat.hand.pos, rotation = seat.hand.rot, scale = RTT_HAND_SCALE }, 1)
          end)
          seat.color = color
          RTT_CLONES[color] = seat.board
          seated[N] = color
        end
        break
      end
    end
  end
  -- base pattern: seat, ~20-frame settle, THEN deliver the matching order card.
  Wait.frames(function() rttDealOrderCards(seated) end, 20)
end

-- world point just above seat N's hand zone: a card dropped here falls into the owned hand.
function rttSeatHandWorld(N)
  local h = RTT_SEATS[N].hand.pos
  return { h[1], (h[2] or 14.62) + 2, h[3] }
end

-- Give each seated player the "Player N" card that MATCHES their seat, addressed by intrinsic CardID
-- (robust to runtime GUID reassignment), delivered into their hand. Seat colour was forced to
-- RTT_SETUP_COLORS[N] and the card is RTT_CARDID_FOR_N[N], so card number == seat by construction.
function rttDealOrderCards(seated)
  local deck = getObjectFromGUID(RTT_ORDER_DECK or "")
  if deck == nil then return end
  -- map CardID -> contained-card GUID ONCE, up front (guids stay stable as others are taken; the
  -- guid of the last card survives even after the deck collapses to a single Card).
  local guidFor = {}
  local ok, d = pcall(function() return deck.getData() end)
  if ok and d ~= nil then
    if d.ContainedObjects ~= nil then
      for _, c in ipairs(d.ContainedObjects) do guidFor[c.CardID] = c.GUID end
    elseif d.CardID ~= nil then
      guidFor[d.CardID] = deck.getGUID()
    end
  end
  local order = {}
  for N in pairs(seated) do order[#order + 1] = N end
  table.sort(order)
  local function deliver(i)
    if i > #order then return end
    local N     = order[i]
    local color = seated[N]
    local cid   = RTT_CARDID_FOR_N[N]
    local g     = (cid ~= nil) and guidFor[cid] or nil
    if g ~= nil and color ~= nil then
      local hp = rttSeatHandWorld(N)
      local o  = getObjectFromGUID(RTT_ORDER_DECK or "")
      local isDeck = false
      if o ~= nil then
        local ok2, dd = pcall(function() return o.getData() end)
        if ok2 and dd ~= nil and dd.ContainedObjects ~= nil then isDeck = true end
      end
      if isDeck then
        pcall(function()
          o.takeObject({ guid = g, position = hp, rotation = RTT_SEATS[N].hand.rot, smooth = false })
        end)
      else                                               -- deck collapsed: the card is loose now
        local c = getObjectFromGUID(g)
        if c ~= nil then pcall(function() c.setPositionSmooth(hp, false, false) end) end
      end
    end
    Wait.time(function() deliver(i + 1) end, 0.25)       -- one at a time = no deck-busy / collapse race
  end
  deliver(1)
end

function rttBeginPick()
  if #RTT_ORDER < 1 then return end
  RTT_PICKED = { map = nil, deck = nil }
  RTT_PICK_STAGE = 0                             -- map/deck pick REMOVED (Adrien places them manually)
  if RTT_5P_MARSH then rttPlaceMap("Marsh Map") end   -- the 5-player button still auto-places its Marsh map
  rttSpawnSelectors()
  Wait.frames(function() rttSeatPlayers() rttStartFactionDraft() end, 10)
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

-- spawn the Root Box Score sheet at Adrien's placed spot (read from his TTS save),
-- rotated 270 to face the camera, sized to fill the board-design rectangle (scale up
-- ~1.3x wide / ~1.1x tall baked into _boxscore.json), locked to the table.
function rttSpawnBoxScore()
  for _, o in ipairs(getObjectsWithTag(RTT_BOXSCORE_TAG)) do o.destruct() end
  -- tell the box score how many player rows to pre-format for (4 ranked / 5 for 5p Marsh); it reads
  -- this Global each rebuild and grows past it only if more players are added.
  Global.setVar("RTT_BOXSCORE_MIN", (RTT_DN or 5) - 1)
  spawnObjectJSON({
    json = RTT_BOXSCORE_JSON,
    position = { -58.36, 11.652, -0.05 },   -- centre of Adrien's 4-card box-score rectangle
    rotation = { 0, 270, 0 },
    callback_function = function(o) o.addTag(RTT_BOXSCORE_TAG) o.setLock(true) end
  })
end

function rttStartFactionDraft()
  RTT_FAC_TAKEN = {}
  RTT_VP_PLACED = 0
  rttSpawnBoxScore()
  _G['Roster'] = {}
  for i = 1, #RTT_ORDER do _G['Roster'][i] = RTT_ORDER[i].name or "" end
  if _G['vagabondAlreadySpawned'] == nil then _G['vagabondAlreadySpawned'] = false end
  Wait.time(function() rttDealHands() end, 0.6)     -- starting cards to each seated player
  rttDraftKnavesCaptains()                          -- 4 captains under the draft cards (if Knaves drafted)
  Wait.frames(function() rttShowFactions() end, 40) -- light EVERY board at once (simultaneous pick)
end

-- Knaves: if Knaves is one of the drafted factions, spawn its 12-card Captain deck directly under
-- the faction-card row DURING the draft, keep 4 at random, discard the rest. (No longer spawned
-- with the faction board.) The deck blob lives in the Knaves faction data (its FaceURL is unique).
-- the 4 drafted Knave captains, laid FACE UP in a line below the draft cards (Adrien's placed spots)
RTT_KNAVE_CAP = {
  { 53.495, 11.7, -7.992 },
  { 53.495, 11.7, -2.870 },
  { 53.495, 11.7,  2.253 },
  { 53.495, 11.7,  7.375 },
}

function rttDraftKnavesCaptains()
  local has = false
  for _, f in ipairs(RTT_DRAFT_FACTIONS or {}) do
    if f == "Knaves of the Deepwood" then has = true break end
  end
  if not has then return end
  local kd = EVERYTHING['Standard']['Knaves of the Deepwood']
  if kd == nil or kd['data'] == nil then return end
  local blob = nil
  for _, v in ipairs(kd['data']) do
    if string.find(v.json, "FA78C0F952724D77A33BECEC0651802808037E95", 1, true) then blob = v.json break end
  end
  if blob == nil then return end
  spawnObjectJSON({
    json = blob,
    position = { 53.495, -50, 0 },                  -- BELOW the table: only the 4 drafted captains show
    rotation = { 0, 270, 0 },
    callback_function = function(deck)
      deck.setLock(true)
      pcall(function() deck.shuffle() end)
      Wait.time(function()
        if deck == nil then return end
        for i = 1, 4 do
          pcall(function() deck.takeObject({
            position = RTT_KNAVE_CAP[i],
            rotation = { 0, 270, 0 }, smooth = false,        -- face up (captain art), NOT locked
            callback_function = function(o) o.setLock(false) o.addTag("RTT Faction") end }) end)
        end
        Wait.time(function() if deck ~= nil then pcall(function() deck.destruct() end) end end, 0.8)
      end, 0.5)
    end
  })
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

-- light the faction menu on EVERY live board at once (simultaneous pick). Factions keep FIXED
-- button positions (slot i = RTT_DRAFT_FACTIONS[i]); a taken faction's slot just goes inactive, so
-- a click's button index always resolves to the same faction even as others are taken (no race).
function rttShowFactions()
  for _, seat in ipairs(RTT_SEATS or {}) do
    local clone = seat.board
    if clone ~= nil then
      clone.UI.setAttribute("rttPickMapDeck", "active", "false")
      clone.UI.setAttribute("rttFactions", "active", "true")
      for i = 1, 6 do
        local f = (RTT_DRAFT_FACTIONS or {})[i]
        if f ~= nil and not RTT_FAC_TAKEN[f] then
          clone.UI.setAttribute("rttFac" .. i, "icon", f)
          clone.UI.setAttribute("rttFac" .. i, "active", "true")
        else
          clone.UI.setAttribute("rttFac" .. i, "active", "false")
        end
      end
    end
  end
end

-- a player clicked a faction on some board. Resolve by the BOARD they clicked (not by whose turn
-- it is — all boards are live at once). First click on a faction takes it; the board is removed and
-- the faction spawns at that seat; the other boards refresh so the taken faction disappears.
function rttCoordFaction(args)
  local seat = RTT_BOARD_SEAT[args.board or ""]
  if seat == nil then return end
  local s = RTT_SEATS[seat]
  if s == nil or s.board == nil then return end        -- board already drafted
  if s.color ~= nil and args.color ~= s.color then return end   -- only YOUR own seat's board (no seat conflicts)
  local idx = tonumber(string.sub(args.id, -1))
  if idx == nil then return end
  local faction = (RTT_DRAFT_FACTIONS or {})[idx]
  if faction == nil or RTT_FAC_TAKEN[faction] then return end
  RTT_FAC_TAKEN[faction] = true                        -- lock immediately (guards double-clicks)
  local clone = s.board
  local bp = clone.getPosition()
  s.board = nil
  RTT_BOARD_SEAT[clone.getGUID()] = nil
  if s.color ~= nil then RTT_CLONES[s.color] = nil end
  clone.destruct()                                     -- board gone first, then the faction spawns there
  rttSpawnFaction(faction, bp.x, bp.z, bp.z > 0)       -- no dice; warriors baked in the data
  RTT_VP_PLACED = (RTT_VP_PLACED or 0) + 1
  local vpN, vpF = RTT_VP_PLACED, faction
  Wait.time(function() rttPlaceVP(vpF, vpN) end, 1.2)
  if faction == "Woodland Alliance" then spawnSupportersHand(s.color or "Red") end
  Wait.frames(function() rttShowFactions() end, 10)    -- refresh remaining boards
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
  -- the score-0 column's REAL snap rows (Adrien places the VP markers exactly on these).
  local real = {}
  for _, p in ipairs(t.pts or {}) do
    if math.abs(p.a - cellA) < 0.45 * t.s then real[#real + 1] = p.b end
  end
  table.sort(real)
  -- centre-out ladder over the real snaps: zero (centre), then up, then down, then
  -- further up/down (Adrien's requested stack order), extending past the ends by the
  -- exact row spacing only when more factions than snap rows.
  local step = 0.11
  if #real >= 2 then step = (real[#real] - real[1]) / (#real - 1)
  elseif #t.rows >= 2 then step = (t.rows[#t.rows] - t.rows[1]) / (#t.rows - 1) end
  local cidx = 1
  for i = 2, #real do if math.abs(real[i] - mid) < math.abs(real[cidx] - mid) then cidx = i end end
  local order = { real[cidx] }
  local up, dn = cidx + 1, cidx - 1
  while up <= #real or dn >= 1 do
    if up <= #real then order[#order + 1] = real[up]; up = up + 1 end
    if dn >= 1 then order[#order + 1] = real[dn]; dn = dn - 1 end
  end
  local top, bot = real[#real], real[1]
  local ext = { top + step, bot - step, top + 2 * step, bot - 2 * step }
  local slots = {}
  for _, b in ipairs(order) do slots[#slots + 1] = { a = cellA, b = b } end
  for _, b in ipairs(ext) do
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
  -- Orientation fix: VP markers spawn at their faction board, and a far-side (z>0) seat
  -- spawns flipped 180, so its marker lands upside-down on the track. Normalise every
  -- placed marker to the score track's own facing so they all read the same way.
  local trackRy = 0
  local map = getObjectFromGUID(RTT_TRACK.guid)
  if map ~= nil then trackRy = map.getRotation().y end
  m.setRotationSmooth({ 0, trackRy, 0 }, false, true)
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
    boxscore_json = open(os.path.join(os.path.dirname(__file__), "_boxscore.json"), encoding="utf-8").read()
    if "]====]" in boxscore_json:
        raise framework.BuildError("boxscore JSON contains ]====] — bracket clash")
    coord_lua = COORD_LUA % (selector_json, boxscore_json)
    text = text.replace(MAKEMAP_SIG, framework.esc(coord_lua) + MAKEMAP_SIG, 1)
    text = framework.replace_unique(text, framework.esc(OLD_DEAL), framework.esc(NEW_DEAL))
    return text
