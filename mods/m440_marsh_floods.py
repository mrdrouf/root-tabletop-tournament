"""
m440 — Marsh Map randomised setup: flooded clearings, ruins, and suit markers.

The Marsh map has three double-sided flood markers. Each marker floods one of two
candidate clearings, chosen at random. The clearing each marker does NOT flood (its
"dry" side) is a real clearing that needs a suit, and for markers B and C also a ruin.

makeMap("Marsh Map") spawns everything in staging areas: the 3 flood markers in a
supply row, 2 spare ruins parked top-left (x=-24.6), and 3 spare suit markers parked
top-right (z>=25). This mod, running after the map finishes spawning, does the whole
setup deterministically-correctly:

  1. randomly flood each marker's up/down side; place the marker there, locked.
  2. place the 2 spare ruins on markers B/C's dry clearings; place the 3 spare suits
     on markers A/B/C's dry clearings.
  3. re-randomise the ruin ITEMS (all 4 ruins) and the suits (all 12 clearing markers)
     with a CORRECT Fisher-Yates — NOT the base mod's shuffle(), which re-seeds
     os.time() every iteration and is deterministic per second (see rtt-rng-bug).
  4. lock everything so nothing gets nudged.

Positions were measured from Adrien's Marsh Reference save. Flood markers are found
by their unique tile artwork; ruins/suits by their "Ruin"/"Clearing Marker" tags
(the flood markers carry neither, only "Map Object", so the lists stay clean).
up/down face = rotZ 0/180 (rotY stays 180).
"""
from . import framework

NAME = "Marsh Map: randomise floods + ruins + suits on the non-flooded clearings"

# fx/fz/fr = flood-marker spot (+rotZ) when this side is FLOODED;
# sx/sz/sr = suit-marker spot (+rotY) on this side when it is DRY;
# rx/rz    = ruin spot on this side when it is DRY (markers B and C only).
FLOOD_LUA = r"""
RTT_MARSH = {
  { tag = "B080D64101E3F465A4247D895622221D53E4E9F1",
    up   = { fx = -11.38, fz = 7.15,  fr = 0,   sx = -13.504, sz = 5.340,  sr = 225 },
    down = { fx = -20.93, fz = -2.72, fr = 180, sx = -17.795, sz = -5.680, sr = 135 } },
  { tag = "5B5554398541EE4C6F0FED30E31DE2BFC5C35E37",
    up   = { fx = 15.91, fz = 3.73,  fr = 0,   sx = 17.342, sz = 0.101,  sr = 165, rx = 14.323, rz = 3.736 },
    down = { fx = 7.20,  fz = -7.21, fr = 180, sx = 3.811,  sz = -8.597, sr = 240, rx = 6.153,  rz = -6.705 } },
  { tag = "D1E2F18AA1FC25927FDB31D9CBA79B5CB37C9A48",
    up   = { fx = 7.70, fz = 16.86,  fr = 0,   sx = 5.947, sz = 20.588, sr = 345, rx = 8.081, rz = 15.388 },
    down = { fx = 0.88, fz = -16.92, fr = 180, sx = 3.512, sz = -14.611, sr = 45, rx = 0.461, rz = -19.318 } },
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

-- correct single-pass Fisher-Yates; NO os.time re-seed (that is the base shuffle() bug)
function rttShuffleList(t)
  for i = #t, 2, -1 do
    local j = math.random(i)
    t[i], t[j] = t[j], t[i]
  end
end

function rttPlace(o, x, z, rx, ry, rz)
  local y = o.getPosition().y
  o.setLock(false)
  o.setPosition({ x, y, z })
  o.setRotation({ rx, ry, rz })
  o.setLock(true)
end

function rttMarshSetup(tries)
  tries = tries or 0
  local floods = {}
  local allFound = true
  for _, m in ipairs(RTT_MARSH) do
    floods[m.tag] = rttFindTile(m.tag)
    if floods[m.tag] == nil then allFound = false end
  end
  local ruins = getObjectsWithTag("Ruin")
  local suits = getObjectsWithTag("Clearing Marker")
  if (not allFound) or ruins == nil or #ruins < 4 or suits == nil or #suits < 12 then
    if tries < 40 then Wait.time(function() rttMarshSetup(tries + 1) end, 0.4) end
    return
  end

  -- seed once, here (after makeMap/shuffleMaps have finished re-seeding os.time())
  RTT_MARSH_N = (RTT_MARSH_N or 0) + 1
  math.randomseed(os.time() + RTT_MARSH_N * 7919)
  for k = 1, 10 do math.random() end

  -- 1) flood a random side of each marker; collect the DRY-side suit/ruin targets
  local suitTargets = {}
  local ruinTargets = {}
  for _, m in ipairs(RTT_MARSH) do
    local flooded, dry
    if math.random(2) == 1 then flooded = m.up; dry = m.down else flooded = m.down; dry = m.up end
    rttPlace(floods[m.tag], flooded.fx, flooded.fz, 0, 180, flooded.fr)
    suitTargets[#suitTargets + 1] = { dry.sx, dry.sz, 0, dry.sr, 0 }
    if dry.rx ~= nil then ruinTargets[#ruinTargets + 1] = { dry.rx, dry.rz, 0, 180, 0 } end
  end

  -- 2+3) SUITS: 9 real clearings (read current non-supply markers) + 3 dry ones;
  --       shuffle all 12 markers across those 12 slots => suits truly randomised.
  local suitSlots = {}
  for _, s in ipairs(suits) do
    local p = s.getPosition()
    if p.z < 23 then                       -- the 3 spare suits are parked at z>=25
      local r = s.getRotation()
      suitSlots[#suitSlots + 1] = { p.x, p.z, r.x, r.y, r.z }
    end
  end
  for _, t in ipairs(suitTargets) do suitSlots[#suitSlots + 1] = t end
  rttShuffleList(suits)
  for i, s in ipairs(suits) do
    local t = suitSlots[i]
    if t ~= nil then rttPlace(s, t[1], t[2], t[3], t[4], t[5]) end
  end

  -- RUINS: 2 fixed clearings (read current non-supply ruins) + 2 dry ones;
  --        shuffle all 4 => ruin ITEMS truly randomised.
  local ruinSlots = {}
  for _, r in ipairs(ruins) do
    local p = r.getPosition()
    if p.x > -20 then                       -- the 2 spare ruins are parked at x=-24.6
      ruinSlots[#ruinSlots + 1] = { p.x, p.z, 0, 180, 0 }
    end
  end
  for _, t in ipairs(ruinTargets) do ruinSlots[#ruinSlots + 1] = t end
  rttShuffleList(ruins)
  for i, r in ipairs(ruins) do
    local t = ruinSlots[i]
    if t ~= nil then rttPlace(r, t[1], t[2], t[3], t[4], t[5]) end
  end

  broadcastToAll("Marsh: floods, ruins and suits placed and randomised.", { 0.6, 0.8, 1 })
end

"""

# Hook the makeMap DEFINITION so ANY Marsh spawn (the "Marsh Map" map button OR the
# "5 Players" button, both of which call makeMap(...,"Marsh Map")) runs the setup.
HOOK = (
    '\n  if id == "Marsh Map" then\n'
    '    Wait.time(function() rttMarshSetup(0) end, 1.4)\n'
    '  end'
)


def apply(text):
    sig = "function makeMap(player,value,id)"
    if text.count(sig) != 1:
        raise framework.BuildError("makeMap anchor not unique")
    text = text.replace(sig, framework.esc(FLOOD_LUA) + sig, 1)
    text = text.replace(sig, sig + framework.esc(HOOK), 1)
    return text
