"""
m250 — RTT automated setup (the Hoot draft).

Reads the "Hoot Draft" saved object, embeds its Militant / Insurgent / Player-Order
cards into the mod, and injects an `rttSetup()` draft:

  1. draw 1 random Militant faction card,
  2. shuffle the remaining 5 Militant + all 6 Insurgent together,
  3. draw 4 more -> a 5-card draft,
  4. deal the animation: the 5 cards stack at the leftmost slot, then fly one by
     one to the rightmost..leftmost slots and flip face-up,
  5. deal the 4 Player-Order cards to the seated (coloured) players.

Slots are the 5 positions you placed the Militant cards at (x=63.4, z -11.9..12.0).
Adds an "RTT Setup" button to the Setups screen (plain-text label for now).

v1 — cards are spawned individually (robust, no deck-merge juggling). A card-flip
SOUND needs a hosted audio asset, which isn't wired yet. Verify/tune in TTS.
"""

import json
import os

from . import framework

NAME = "RTT automated setup (Hoot draft) + button"

HOOT = os.path.expanduser(
    "~/Documents/My Games/Tabletop Simulator/Saves/Saved Objects/Hoot Draft.json")

MILITANT_GUID, INSURGENT_GUID, ORDER_GUID = "403b02", "9957df", "375d27"

RTT_BUTTON = (
    '<Button id="rttSetup" onclick="rttSetup" text="RTT Setup" '
    'position="55 5 -20" width="40" height="40" fontSize="7" color="#2c231a"/>'
)


def _standalone_card(card, deck_customdeck):
    """Give a card its own CustomDeck (only the sheet its CardID needs) so it can
    be spawned on its own, and return compact JSON."""
    c = dict(card)
    sheet = str(card["CardID"] // 100)
    if deck_customdeck.get(sheet):
        c["CustomDeck"] = {sheet: deck_customdeck[sheet]}
    return json.dumps(c, separators=(",", ":"))


def apply(text):
    if not os.path.exists(HOOT):
        raise framework.BuildError("Hoot Draft saved object not found at %s" % HOOT)
    hoot = json.load(open(HOOT, encoding="utf-8"))
    decks = {d.get("GUID"): d for d in hoot["ObjectStates"]}
    mil, ins, order = decks[MILITANT_GUID], decks[INSURGENT_GUID], decks[ORDER_GUID]

    def card_table(deck):
        cd = deck.get("CustomDeck") or {}
        out = {}
        for c in deck["ContainedObjects"]:
            out[c["CardID"]] = _standalone_card(c, cd)
        return out

    mil_cards = card_table(mil)
    ins_cards = card_table(ins)
    order_json = json.dumps(order, separators=(",", ":"))

    # ---- build the Lua block ----
    def lua_card_map(cards):
        return "{" + ",".join("[%d]=[==[%s]==]" % (cid, j) for cid, j in cards.items()) + "}"

    lua = """
RTT_MIL_CARDS = %s
RTT_INS_CARDS = %s
RTT_ORDER_JSON = [==[%s]==]
RTT_MILITANT = {%s}
RTT_INSURGENT = {%s}
RTT_SLOTS = {{63.9,11.6,-14},{63.9,11.6,-7},{63.9,11.6,0},{63.9,11.6,7},{63.9,11.6,14}}
RTT_SPAWNED = {}

function rttShuffle(t)
  for i=#t,2,-1 do local j=math.random(i) t[i],t[j]=t[j],t[i] end
  return t
end

function rttSetup(player, value, id)
  for _,g in ipairs(RTT_SPAWNED) do local o=getObjectFromGUID(g) if o then o.destruct() end end
  RTT_SPAWNED = {}
  RTT_N = (RTT_N or 0) + 1
  math.randomseed(os.time() + RTT_N * 7919)
  for _=1,6 do math.random() end
  local mil = {}
  for _,c in ipairs(RTT_MILITANT) do mil[#mil+1]=c end
  rttShuffle(mil)
  local first = mil[1]
  local pool = {}
  for i=2,#mil do pool[#pool+1]=mil[i] end
  for _,c in ipairs(RTT_INSURGENT) do pool[#pool+1]=c end
  rttShuffle(pool)
  local draft = {first, pool[1], pool[2], pool[3], pool[4]}
  local jsons = {}
  for _,cid in ipairs(draft) do
    jsons[#jsons+1] = RTT_MIL_CARDS[cid] or RTT_INS_CARDS[cid]
  end
  rttDealAll(jsons, 1, {})
end

-- Deal each card from a face-down deck on the left to its slot, ONE AT A TIME so
-- two cards are never at the same spot (which makes TTS merge them into a deck).
-- Once all 5 are placed face-down, flip them one by one. Orientation rotY=270
-- matches the cards you placed.
-- The cards all appear at the rightmost (last) slot like a face-down deck; card i
-- slides to slot i (so card #jsons stays at the rightmost), one at a time so they
-- never overlap and merge. Once all are down, flip them all at once.
function rttDealAll(jsons, i, cards)
  if i > #jsons then
    Wait.time(function() rttFlipAll(cards) end, 0.6)
    return
  end
  local R = RTT_SLOTS[#jsons]   -- rightmost = the "deck" spot
  spawnObjectJSON({
    json = jsons[i],
    position = {R[1], R[2] + 2, R[3]},
    rotation = {0, 270, 180},
    callback_function = function(o)
      o.setLock(false)
      RTT_SPAWNED[#RTT_SPAWNED+1] = o.getGUID()
      cards[i] = o
      local s = RTT_SLOTS[i]
      o.setPositionSmooth({s[1], s[2], s[3]}, false, false)
      Wait.time(function() rttDealAll(jsons, i+1, cards) end, 0.7)
    end
  })
end

function rttFlipAll(cards)
  for _,c in ipairs(cards) do
    if c ~= nil then c.setRotationSmooth({0, 270, 0}, false, false) end
  end
  Wait.time(rttDealOrder, 0.8)
end

function rttDealOrder()
  spawnObjectJSON({
    json = RTT_ORDER_JSON,
    position = {63.4, 4, -30},
    callback_function = function(ord)
      RTT_SPAWNED[#RTT_SPAWNED+1] = ord.getGUID()
      Wait.time(function()
        if ord ~= nil and ord.shuffle then ord.shuffle() end
        Wait.time(function()
          local seated = {}
          for _,p in ipairs(Player.getPlayers()) do
            if p.seated and p.color ~= "Grey" and p.color ~= "Black" then seated[#seated+1]=p end
          end
          for _,p in ipairs(seated) do
            if ord ~= nil and ord.deal then ord.deal(1, p.color) end
          end
        end, 0.6)
      end, 0.5)
    end
  })
end
""" % (
        lua_card_map(mil_cards),
        lua_card_map(ins_cards),
        order_json,
        ",".join(str(c["CardID"]) for c in mil["ContainedObjects"]),
        ",".join(str(c["CardID"]) for c in ins["ContainedObjects"]),
    )

    # inject the block just before makeFaction()
    anchor = "function makeFaction(player,value,id)"
    if text.count(anchor) != 1:
        raise framework.BuildError("makeFaction anchor not unique")
    i = text.index(anchor)
    text = text[:i] + framework.esc(lua + "\n") + text[i:]

    # add the button
    text = framework.add_button_to_group(text, "setupButtons", RTT_BUTTON)
    return text
