"""
m470 — RTT draft on per-player selector boards: turn order + P1/P2 map+deck pick.

Adrien's architecture: never touch the central menu board. After `rttSetup` (m250)
deals the 5-card draft + order cards, the central board becomes a hidden COORDINATOR
that spawns one faction-selector board (a clone) in front of every seated player and
drives their UI. Each player interacts only with the board at their seat.

Clone mechanics reused from the base:
  * `self.clone()` + `setName("Faction Board")` — the name makes the clone SKIP the
    heavy `onLoad` (guarded by `if self.getName() != "Faction Board"`), so it spawns
    bare; its persistent CustomUIAssets (map/deck/faction icons) come along, so real
    art renders on it.
  * seat position = `getPosition(color, n)`; rotation by table side (z>0 -> 180).
  * clones each run their OWN Lua context (globals are NOT shared), so their buttons
    RELAY clicks to the coordinator (the one board still named "Faction Selection",
    GUID bab7e1) via getObjectFromGUID(...).call(...). All state lives on the coordinator.

Phase 0-2 here: capture RTT_ORDER, spawn the boards, then Player 1 picks a map OR a
deck (real setup-board art) on their own board; the chosen category switches off and
Player 2 picks the leftover on theirs. Phase 3 (reverse-order faction draft off the 5
dealt cards, revealed board-by-board) reuses these same clones and is wired next.
"""
from . import framework

NAME = "RTT draft: per-player selector boards + P1/P2 map+deck pick"

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
    "          RTT_SOLO = (#RTT_ORDER <= 1)\n"
    "          if RTT_SOLO then\n"
    "            local nm = RTT_ORDER[1] and RTT_ORDER[1].name or ''\n"
    "            RTT_ORDER = {}\n"
    "            for _,c in ipairs({'Red','Yellow','Teal','Orange'}) do RTT_ORDER[#RTT_ORDER+1] = {color=c, name=nm} end\n"
    "          end\n"
    "          for _,e in ipairs(RTT_ORDER) do\n"
    "            if ord ~= nil and ord.deal then ord.deal(1, e.color) end\n"
    "          end\n"
    "          Wait.time(function() rttBeginPick() end, 1.2)"
)

LUA = r"""
-- ===== RTT per-player selector boards + P1/P2 map/deck pick =====
RTT_COORD_GUID = "bab7e1"          -- the central menu board (never touched; only coordinates)
RTT_SELECTOR_TAG = "RTT Selector"
RTT_ORDER = RTT_ORDER or {}
RTT_CLONES = {}                    -- color -> clone board ref (lives on the coordinator)
RTT_PICKED = { map = nil, deck = nil }
RTT_PICK_STAGE = 0                 -- 0 idle, 1 = P1 (free), 2 = P2 (leftover)

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
-- everything to switch off on a fresh selector clone (show nothing until told)
RTT_HIDE_GROUPS = {
  "Main Nav", "Main Nav Personal", "standardButtons", "vagabondButtons", "setupButtons",
  "mapButtonsStandard", "fanMapButtons1", "fanMapButtons2", "decksButtonsStandard", "deckPage2",
  "toolsButtons", "tools1", "tools2", "robotButtons", "robotButtons2", "rttPickMapDeck",
}

function rttConfigSelector(board)
  for _, g in ipairs(RTT_HIDE_GROUPS) do board.UI.setAttribute(g, "active", "False") end
  board.UI.setAttribute("xButton", "active", "False")
end

-- the six board positions from the old 6-board faction-selector spawner
-- (setupFactionBoards): corners first, then the two mid-edges.
RTT_POS = { { 52, -46 }, { -52, -46 }, { 52, 46 }, { -52, 46 }, { 0, -46 }, { 0, 46 } }
-- which of those positions to use for N players, in turn order (P1 first). Two players
-- sit diagonally (1 & 4); four players take all corners.
RTT_LAYOUT = {
  [1] = { 1 }, [2] = { 1, 4 }, [3] = { 1, 2, 4 },
  [4] = { 1, 2, 3, 4 }, [5] = { 1, 2, 3, 4, 5 }, [6] = { 1, 2, 3, 4, 5, 6 },
}

function rttSpawnSelectors()
  for _, o in ipairs(getObjectsWithTag(RTT_SELECTOR_TAG)) do o.destruct() end
  RTT_CLONES = {}
  local n = #RTT_ORDER
  local layout = RTT_LAYOUT[n] or RTT_LAYOUT[4]
  for i, e in ipairs(RTT_ORDER) do
    local p = RTT_POS[layout[i] or i] or RTT_POS[1]
    local board = self.clone({ snap_to_grid = true })
    board.setName("Faction Board")
    board.setPosition({ p[1], 11.56, p[2] })
    board.setLock(true)   -- locked to the table so clicking an option never drags it
    if p[2] > 0 then board.setRotation({ 0, 180, 0 }) else board.setRotation({ 0, 0, 0 }) end
    board.addTag(RTT_SELECTOR_TAG)
    RTT_CLONES[e.color] = board
    Wait.frames(function() rttConfigSelector(board) end, 10)
  end
end

function rttBeginPick()
  if #RTT_ORDER < 1 then return end
  RTT_PICKED = { map = nil, deck = nil }
  RTT_PICK_STAGE = 1
  -- the central menu board is NEVER touched: it keeps all its options.
  rttSpawnSelectors()
  Wait.frames(function() rttShowPick(1) end, 30)
end

function rttShowPick(stage)
  local seat = (stage == 1) and RTT_ORDER[1] or (RTT_ORDER[2] or RTT_ORDER[1])
  local clone = RTT_CLONES[seat.color]
  if clone == nil then return end
  clone.UI.setAttribute("rttPickMapDeck", "active", "true")
  for _, b in ipairs(RTT_MAP_BTNS)  do clone.UI.setAttribute(b, "active", (RTT_PICKED.map  == nil) and "true" or "false") end
  for _, b in ipairs(RTT_DECK_BTNS) do clone.UI.setAttribute(b, "active", (RTT_PICKED.deck == nil) and "true" or "false") end
  -- no player naming (we don't announce whose turn it is): the options simply appear
  -- on the picking player's own board; every other board stays blank.
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

-- runs on the CLONE; forwards the click to the coordinator (own Lua context)
function rttPickRelay(player, value, id)
  local coord = getObjectFromGUID(RTT_COORD_GUID)
  if coord ~= nil then coord.call("rttCoordPick", { color = player.color, id = id }) end
end

-- runs on the COORDINATOR (has RTT_ORDER / RTT_CLONES / RTT_PICKED)
function rttCoordPick(args)
  local def = RTT_PICK_DEFS[args.id]
  if def == nil or RTT_PICK_STAGE == 0 then return end
  local seat = (RTT_PICK_STAGE == 1) and RTT_ORDER[1] or (RTT_ORDER[2] or RTT_ORDER[1])
  -- gate to the seat whose turn it is; in solo test mode the one tester drives every board
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

  -- stage 2: P2 takes the leftover category (buttons already filtered)
  if RTT_PICKED.map == nil and def.kind ~= "map" then return end
  if RTT_PICKED.deck == nil and def.kind ~= "deck" then return end
  if def.kind == "map" then RTT_PICKED.map = def.id rttPlaceMap(def.id)
  else RTT_PICKED.deck = def.id rttPlaceDeck(def.id) end
  if clone ~= nil then clone.UI.setAttribute("rttPickMapDeck", "active", "false") end
  RTT_PICK_STAGE = 0
  -- Phase 3 (reverse-order faction draft off the 5 dealt cards) hooks in here.
end

"""

# the pick screen: one 3x3 grid using the REAL setup-board art AND each button's exact
# designed background color (icon assets + colors match the menu buttons precisely).
_SZ = 'width="34" height="34" fontSize="8"'   # EXACT original button size (art stays centred)
XML = (
    '\n<ToggleGroup id="rttPickMapDeck" active="false">'
    '\n  <Text id="rttPickTitle" text="" position="0 60 -20" width="240" height="14" fontSize="11" color="#f3e9cf"/>'
    '\n  <Button id="rttPickMap1" onclick="rttPickRelay" icon="Autumn Map"   color="#4b4d35" position="-40 34 -20" ' + _SZ + '/>'
    '\n  <Button id="rttPickMap2" onclick="rttPickRelay" icon="Winter Map"   color="#6b8a8f" position="0 34 -20" ' + _SZ + '/>'
    '\n  <Button id="rttPickMap3" onclick="rttPickRelay" icon="Lake Map"     color="#42a0c2" position="40 34 -20" ' + _SZ + '/>'
    '\n  <Button id="rttPickMap4" onclick="rttPickRelay" icon="Marsh Map"    color="#9b8551" position="-40 -2 -20" ' + _SZ + '/>'
    '\n  <Button id="rttPickMap5" onclick="rttPickRelay" icon="Mountain Map" color="#764a52" position="0 -2 -20" ' + _SZ + '/>'
    '\n  <Button id="rttPickMap6" onclick="rttPickRelay" icon="Gorge Map"    color="#61746b" position="40 -2 -20" ' + _SZ + '/>'
    '\n  <Button id="rttPickDeck1" onclick="rttPickRelay" icon="Standard Deck"              color="#8d7f81" position="-40 -38 -20" ' + _SZ + '/>'
    '\n  <Button id="rttPickDeck2" onclick="rttPickRelay" icon="Exiles and Partisans Deck"  color="#378f90" position="0 -38 -20" ' + _SZ + '/>'
    '\n  <Button id="rttPickDeck3" onclick="rttPickRelay" icon="Squires and Disciples Deck" color="#AB6894" position="40 -38 -20" ' + _SZ + '/>'
    '\n</ToggleGroup>'
)


def apply(text):
    if text.count(MAKEMAP_SIG) != 1:
        raise framework.BuildError("makeMap anchor not unique")
    text = text.replace(MAKEMAP_SIG, framework.esc(LUA) + MAKEMAP_SIG, 1)
    text = framework.replace_unique(text, framework.esc(OLD_DEAL), framework.esc(NEW_DEAL))
    anchor = 'image=\\"Root Logo\\"/>'
    text = framework.replace_unique(text, anchor, anchor + framework.esc(XML))
    return text
