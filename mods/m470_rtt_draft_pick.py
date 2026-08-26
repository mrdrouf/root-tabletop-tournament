"""
m470 — RTT draft, phase 0-2: capture turn order, then the P1/P2 map+deck pick.

After `rttSetup` (m250) deals the 5-card draft + the player-order cards, this:

  * captures the seated players' turn order into `RTT_ORDER` (a shuffle — the
    authoritative order; the physical order-card faces are cosmetic for now, since
    the cards carry no readable ordinal), then opens the pick screen;
  * shows one clean 3x3 grid of text buttons: 6 maps + 3 decks;
  * **Player 1** picks a map OR a deck (free choice); the chosen category's buttons
    switch off, leaving the other category for **Player 2**, who picks the leftover.
  * Each pick is gated to that seat's colour and places the piece via the base
    primitives `makeMap` (+ battle mat, Mountain Tower removal) and `makeDeck`
    (2-player decks get the " 2" variant, as the base does).

When both are picked the screen closes and it announces the faction draft is next —
that's phase 3 (reverse-order draft off the 5 dealt cards), wired in a later mod.

Decisions locked 2026-08-26 (see TODO.md): free+leftover map/deck; draft from the 5
dealt cards; single reverse pass. Buttons are TEXT (custom UI icons blank in TTS).
"""
from . import framework

NAME = "RTT draft: turn-order capture + P1/P2 map+deck pick"

MAKEMAP_SIG = "function makeMap(player,value,id)"

# the exact deal loop injected by m250's rttDealOrder — we replace it to also
# capture RTT_ORDER and kick off the pick screen.
OLD_DEAL = (
    "          for _,p in ipairs(seated) do\n"
    "            if ord ~= nil and ord.deal then ord.deal(1, p.color) end\n"
    "          end"
)
NEW_DEAL = (
    "          RTT_ORDER = {}\n"
    "          for _,p in ipairs(seated) do RTT_ORDER[#RTT_ORDER+1] = {color=p.color, name=p.steam_name} end\n"
    "          for i=#RTT_ORDER,2,-1 do local j=math.random(i) RTT_ORDER[i],RTT_ORDER[j]=RTT_ORDER[j],RTT_ORDER[i] end\n"
    "          for _,e in ipairs(RTT_ORDER) do\n"
    "            if ord ~= nil and ord.deal then ord.deal(1, e.color) end\n"
    "          end\n"
    "          Wait.time(function() rttBeginPick() end, 1.2)"
)

LUA = r"""
-- ===== RTT map/deck pick (P1 free choice, P2 leftover) =====
RTT_ORDER = RTT_ORDER or {}
RTT_PICKED = { map = nil, deck = nil }
RTT_PICK_STAGE = 0   -- 0 idle, 1 = first picker (P1), 2 = leftover (P2)

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

function rttPickSetButtons(ids, on)
  for _, b in ipairs(ids) do self.UI.setAttribute(b, "active", on and "true" or "false") end
end

function rttBeginPick()
  RTT_PICKED = { map = nil, deck = nil }
  if #RTT_ORDER < 1 then broadcastToAll("Seat at least one player before the RTT draft.") return end
  RTT_PICK_STAGE = 1
  allButtonsOff()
  self.UI.setAttribute("Main Nav", "active", "False")
  rttPickSetButtons(RTT_MAP_BTNS, true)
  rttPickSetButtons(RTT_DECK_BTNS, true)
  self.UI.setAttribute("rttPickMapDeck", "active", "true")
  self.UI.setAttribute("rttPickTitle", "text", "Player 1 (" .. RTT_ORDER[1].color .. "): pick a MAP or a DECK")
  broadcastToColor("You are Player 1 - pick a map OR a deck.", RTT_ORDER[1].color)
  broadcastToAll("Player 1 (" .. RTT_ORDER[1].color .. ") picks a map or a deck.")
end

function rttPlaceMap(mapId)
  makeMap("", "", mapId)
  Wait.time(function()
    makeSpecialWithTag("Tools", "Battle Mat", 33.17, 1.55, 9.21, "Map Object")
    if mapId == "Mountain Map" then
      for _, v in ipairs(getObjectsWithTag("Tower")) do v.destruct() end
    end
  end, 0.6)
end

function rttPlaceDeck(deckId)
  local id = deckId
  if #RTT_ORDER <= 2 then id = id .. " 2" end
  makeDeck("", "", id)
end

function rttPickFinish()
  RTT_PICK_STAGE = 0
  self.UI.setAttribute("rttPickMapDeck", "active", "false")
  broadcastToAll("Map: " .. tostring(RTT_PICKED.map) .. "  |  Deck: " .. tostring(RTT_PICKED.deck)
    .. ".  Faction draft (reverse order, P" .. #RTT_ORDER .. " first) is next.")
  -- Phase 3 (reverse-order faction draft off the 5 dealt cards) hooks in here.
end

function rttPickChoose(player, value, id)
  local def = RTT_PICK_DEFS[id]
  if def == nil or RTT_PICK_STAGE == 0 then return end

  local seat
  if RTT_PICK_STAGE == 1 then seat = RTT_ORDER[1] else seat = RTT_ORDER[2] or RTT_ORDER[1] end
  if player.color ~= seat.color then
    broadcastToColor("It is Player " .. RTT_PICK_STAGE .. " (" .. seat.color .. ")'s pick.", player.color)
    return
  end

  if RTT_PICK_STAGE == 1 then
    if def.kind == "map" then
      RTT_PICKED.map = def.id
      rttPlaceMap(def.id)
      rttPickSetButtons(RTT_MAP_BTNS, false)     -- map taken -> leftover = decks
    else
      RTT_PICKED.deck = def.id
      rttPlaceDeck(def.id)
      rttPickSetButtons(RTT_DECK_BTNS, false)    -- deck taken -> leftover = maps
    end
    broadcastToAll("Player 1 chose " .. def.label .. ".")
    RTT_PICK_STAGE = 2
    local seat2 = RTT_ORDER[2] or RTT_ORDER[1]
    local leftover = (RTT_PICKED.map == nil) and "MAP" or "DECK"
    self.UI.setAttribute("rttPickTitle", "text", "Player 2 (" .. seat2.color .. "): pick the " .. leftover)
    broadcastToColor("You are Player 2 - pick the " .. leftover .. ".", seat2.color)
    broadcastToAll("Player 2 (" .. seat2.color .. ") picks the " .. leftover .. ".")
    return
  end

  -- stage 2: P2 takes whichever category is left (buttons are already filtered)
  if RTT_PICKED.map == nil and def.kind ~= "map" then return end
  if RTT_PICKED.deck == nil and def.kind ~= "deck" then return end
  if def.kind == "map" then RTT_PICKED.map = def.id rttPlaceMap(def.id)
  else RTT_PICKED.deck = def.id rttPlaceDeck(def.id) end
  broadcastToAll("Player 2 chose " .. def.label .. ".")
  rttPickFinish()
end

"""

# the pick screen: one 3x3 grid (6 maps + 3 decks) of same-size parchment text
# buttons, centred on the draft area (x cols -5/35/75, matching DraftOptions).
_BTN = 'width="38" height="26" fontSize="8" color="#e3d3a6" textColor="#3d2c15" fontStyle="Bold"'
XML = (
    '\n<ToggleGroup id="rttPickMapDeck" active="false">'
    '\n  <Text id="rttPickTitle" text="" position="35 62 -20" width="240" height="14" fontSize="11" color="#f3e9cf"/>'
    '\n  <Button id="rttPickMap1" onclick="rttPickChoose" text="Autumn"   position="-5 34 -20" ' + _BTN + '/>'
    '\n  <Button id="rttPickMap2" onclick="rttPickChoose" text="Winter"   position="35 34 -20" ' + _BTN + '/>'
    '\n  <Button id="rttPickMap3" onclick="rttPickChoose" text="Lake"     position="75 34 -20" ' + _BTN + '/>'
    '\n  <Button id="rttPickMap4" onclick="rttPickChoose" text="Marsh"    position="-5 4 -20" ' + _BTN + '/>'
    '\n  <Button id="rttPickMap5" onclick="rttPickChoose" text="Mountain" position="35 4 -20" ' + _BTN + '/>'
    '\n  <Button id="rttPickMap6" onclick="rttPickChoose" text="Gorge"    position="75 4 -20" ' + _BTN + '/>'
    '\n  <Button id="rttPickDeck1" onclick="rttPickChoose" text="Standard"            position="-5 -26 -20" ' + _BTN + '/>'
    '\n  <Button id="rttPickDeck2" onclick="rttPickChoose" text="Exiles &amp; Partisans"  position="35 -26 -20" ' + _BTN + '/>'
    '\n  <Button id="rttPickDeck3" onclick="rttPickChoose" text="Squires &amp; Disciples" position="75 -26 -20" ' + _BTN + '/>'
    '\n</ToggleGroup>'
)


def apply(text):
    # 1) inject the Lua before makeMap
    if text.count(MAKEMAP_SIG) != 1:
        raise framework.BuildError("makeMap anchor not unique")
    text = text.replace(MAKEMAP_SIG, framework.esc(LUA) + MAKEMAP_SIG, 1)

    # 2) capture RTT_ORDER + start the pick when the order cards are dealt
    text = framework.replace_unique(text, framework.esc(OLD_DEAL), framework.esc(NEW_DEAL))

    # 3) add the pick screen to the board's XmlUI (after the Root logo image)
    anchor = 'image=\\"Root Logo\\"/>'
    text = framework.replace_unique(text, anchor, anchor + framework.esc(XML))
    return text
