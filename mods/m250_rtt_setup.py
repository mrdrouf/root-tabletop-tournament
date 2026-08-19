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
RTT_SLOTS = {{63.4,11.7,-11.9},{63.4,11.7,-5.8},{63.4,11.7,-0.1},{63.4,11.7,6.1},{63.4,11.7,12.0}}
RTT_SPAWNED = {}

function rttShuffle(t)
  for i=#t,2,-1 do local j=math.random(i) t[i],t[j]=t[j],t[i] end
  return t
end

function rttSetup(player, value, id)
  for _,g in ipairs(RTT_SPAWNED) do local o=getObjectFromGUID(g) if o then o.destruct() end end
  RTT_SPAWNED = {}
  math.randomseed(os.time()); math.random(); math.random(); math.random()
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
  rttDealCard(jsons, 1)
end

-- deal one card at a time: spawn it above the leftmost slot, fly it to its slot
-- (rightmost first) and flip it face-up, then spawn the next. Spawning one at a
-- time and moving each away avoids TTS merging them into a single deck.
function rttDealCard(jsons, i)
  if i > #jsons then
    Wait.time(rttDealOrder, 0.8)
    return
  end
  local L = RTT_SLOTS[1]
  local slotIdx = #jsons - i + 1
  spawnObjectJSON({
    json = jsons[i],
    position = {L[1], L[2] + 3, L[3]},
    rotation = {0, 180, 180},
    callback_function = function(o)
      o.setLock(false)
      RTT_SPAWNED[#RTT_SPAWNED+1] = o.getGUID()
      local s = RTT_SLOTS[slotIdx]
      o.setPositionSmooth({s[1], s[2], s[3]}, false, false)
      Wait.time(function()
        o.setRotationSmooth({0, 180, 0}, false, false)
        Wait.time(function() rttDealCard(jsons, i + 1) end, 0.6)
      end, 0.7)
    end
  })
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
