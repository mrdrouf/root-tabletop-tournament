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
-- five landing slots, centred on z=0; slot 5 (z=14) is the LEFT end.
RTT_SLOTS = {{63.9,11.6,-14},{63.9,11.6,-7},{63.9,11.6,0},{63.9,11.6,7},{63.9,11.6,14}}
-- the draft deck sits past the LEFT-most slot (z=14) with a ~10-unit gap: left of
-- the cards, but not stranded far out.
RTT_DECK = {63.9,11.6,24}
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
  -- the 5 dealt (Militant first); the rest stay as the deck so EVERY faction card is
  -- on the table. The full random order is fixed here, up front.
  local draft = {first, pool[1], pool[2], pool[3], pool[4]}
  -- ONLY the 5 drafted cards are put on the table (no leftover faction deck). The
  -- draft empties these as factions are placed in the faction phase.
  RTT_NLEFT = 0
  local jsons = {}
  for _,cid in ipairs(draft) do jsons[#jsons+1] = RTT_MIL_CARDS[cid] or RTT_INS_CARDS[cid] end
  rttSpawnDeck(jsons, 1, {})
end

-- 1) a real face-down DECK resting ON the table at RTT_DECK: cards spawn in a tight
--    stack at table height (y offsets are tiny) and are locked so it sits like a deck.
function rttSpawnDeck(jsons, i, cards)
  if i > #jsons then
    Wait.time(function() rttSlideOut(cards, 1) end, 0.9)   -- let the deck sit, then deal
    return
  end
  spawnObjectJSON({
    json = jsons[i],
    position = {RTT_DECK[1], RTT_DECK[2] + 0.05 * i, RTT_DECK[3]},
    rotation = {0, 270, 180},
    callback_function = function(o)
      o.setLock(true)
      RTT_SPAWNED[#RTT_SPAWNED+1] = o.getGUID()
      cards[i] = o
      Wait.time(function() rttSpawnDeck(jsons, i+1, cards) end, 0.1)
    end
  })
end

-- 2) deal from the deck: each card flies up in a small ARC (raised mid-point) to its
--    slot. Card 1 (always the Militant) lands LEFT-most, each later card one right.
function rttSlideOut(cards, k)
  if k > 5 then                                        -- deal only the top 5; leave the deck
    Wait.time(function() rttFlipAll(cards, 1) end, 0.6)
    return
  end
  local c = cards[RTT_NLEFT + k]                        -- the k-th draft card (top of the deck)
  if c ~= nil then
    c.setLock(false)
    local s = RTT_SLOTS[6 - k]                          -- k=1 (Militant) -> LEFT-most slot
    local mid = {s[1], s[2] + 4, (RTT_DECK[3] + s[3]) / 2}   -- lift over -> arc
    c.setPositionSmooth(mid, false, false)
    Wait.time(function()
      if c ~= nil then c.setPositionSmooth({s[1], s[2], s[3]}, false, true) end
    end, 0.35)
  end
  Wait.time(function() rttSlideOut(cards, k+1) end, 0.6)
end

-- 3) flip face-up with the REAL flip mechanism (a natural flip, not a rotate that
--    clips through the table), one card at a time so they all flip the same way.
function rttFlipAll(cards, k)
  if k > 5 then                                        -- only the 5 dealt cards flip up
    for i = 1, RTT_NLEFT do                            -- unlock the leftover deck so it's movable
      if cards[i] ~= nil then cards[i].setLock(false) end
    end
    Wait.time(rttDealOrder, 1.0)
    return
  end
  local c = cards[RTT_NLEFT + k]
  if c ~= nil then c.flip() end
  Wait.time(function() rttFlipAll(cards, k+1) end, 0.12)
end

function rttDealOrder()
  spawnObjectJSON({
    json = RTT_ORDER_JSON,
    position = {63.9, 13, -25},          -- above the table so the leftover deck drops & rests
    rotation = {0, 270, 0},
    callback_function = function(ord)
      ord.setLock(false)                 -- unlock so it isn't left floating
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
