"""
m440 — Marsh Map flooded-clearing random setup.

The Marsh map has three double-sided flood markers. Each marker floods a
DIFFERENT clearing depending on whether it is placed "up" or "down", and the
side is chosen randomly at the start of the match.

makeMap("Marsh Map") already spawns the three markers in a supply row along the
top edge of the board. We identify each marker by its unique tile artwork and,
after the map finishes spawning, flip each one to a random up/down side and
slide it onto the corresponding clearing.

The two candidate clearings (and the rotZ that shows the correct face) for each
marker were measured from the reference setup Adrien laid out — for every marker
he placed one copy on its up-clearing and one on its down-clearing, so the exact
world transforms are known:

    marker  art tail   UP  (rotZ 0)              DOWN (rotZ 180)
    A       53E4E9F1   (-11.38,  7.15)           (-20.93, -2.72)
    B       C5C35E37   ( 15.91,  3.73)           (  7.20, -7.21)
    C       B37C9A48   (  7.70, 16.86)           (  0.88, -16.92)

makeMap positions objects deterministically from their move_to data, so these
absolute world X/Z are stable across spawns; the marker keeps its own board-
surface Y. up/down = rotZ 0/180 (rotY stays 180), matching the reference copies.
"""
from . import framework

NAME = "Marsh Map: randomise the 3 flooded clearings (up/down) on spawn"

# up = {x, z, rotZ}, down = {x, z, rotZ}
FLOOD_LUA = r"""
RTT_MARSH_FLOODS = {
  { tag = "B080D64101E3F465A4247D895622221D53E4E9F1", up = { -11.38, 7.15, 0 }, down = { -20.93, -2.72, 180 } },
  { tag = "5B5554398541EE4C6F0FED30E31DE2BFC5C35E37", up = { 15.91, 3.73, 0 }, down = { 7.20, -7.21, 180 } },
  { tag = "D1E2F18AA1FC25927FDB31D9CBA79B5CB37C9A48", up = { 7.70, 16.86, 0 }, down = { 0.88, -16.92, 180 } },
}

function rttFindTile(tag)
  for _, o in ipairs(getAllObjects()) do
    if o.name == "Custom_Tile" then
      local co = o.getCustomObject()
      if co and co.image and string.find(co.image, tag, 1, true) then return o end
    end
  end
  return nil
end

function rttFloodMarsh(tries)
  tries = tries or 0
  if tries == 0 then
    -- seed HERE (not in makeMap): the base shuffle()/shuffleMaps re-seed with
    -- os.time() during makeMap, which would otherwise clobber our RNG. Seeding at
    -- the first flood pass (1.4s later) runs after all that, so up/down is truly random.
    RTT_MARSH_N = (RTT_MARSH_N or 0) + 1
    math.randomseed(os.time() + RTT_MARSH_N * 7919)
    for k = 1, 10 do math.random() end
  end
  RTT_MARSH_DONE = RTT_MARSH_DONE or {}
  local remaining = 0
  for _, f in ipairs(RTT_MARSH_FLOODS) do
    if not RTT_MARSH_DONE[f.tag] then
      local o = rttFindTile(f.tag)
      if o ~= nil then
        local s = f.down
        if math.random(2) == 1 then s = f.up end
        local y = o.getPosition().y
        o.setLock(false)
        o.setPosition({ s[1], y, s[2] })          -- placed directly, no slide
        o.setRotation({ 0, 180, s[3] })
        o.setLock(true)                            -- lock so it can't be nudged
        RTT_MARSH_DONE[f.tag] = true
      else
        remaining = remaining + 1
      end
    end
  end
  if remaining > 0 and tries < 40 then             -- keep looking until all 3 spawn
    Wait.time(function() rttFloodMarsh(tries + 1) end, 0.4)
  else
    broadcastToAll("Marsh: flooded clearings placed (randomised up/down).", { 0.6, 0.8, 1 })
  end
end

"""

# Hook the makeMap DEFINITION so ANY Marsh spawn (the "Marsh Map" map button OR the
# "5 Players" button, both of which call makeMap(...,"Marsh Map")) triggers the flood
# randomiser — not just the 5-player path.
HOOK = (
    '\n  if id == "Marsh Map" then\n'
    '    RTT_MARSH_DONE = {}\n'
    '    Wait.time(function() rttFloodMarsh(0) end, 1.4)\n'
    '  end'
)


def apply(text):
    sig = "function makeMap(player,value,id)"
    if text.count(sig) != 1:
        raise framework.BuildError("makeMap anchor not unique")
    # 1) inject the flood table + helpers just before makeMap()
    text = text.replace(sig, framework.esc(FLOOD_LUA) + sig, 1)
    # 2) run the randomiser at the top of makeMap when the Marsh map is spawned
    text = text.replace(sig, sig + framework.esc(HOOK), 1)
    return text
