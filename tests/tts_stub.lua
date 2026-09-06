-- Minimal TTS surface, instrumented so the harness can observe what a setup path DID.
REC = { destroyed = {}, spawned = {}, hands = {}, globals = {}, turns = {}, calls = {}, colors = {} }
local function note(t, v) t[#t+1] = v end

Wait = {}
local Q = {}
function Wait.time(f, s)   note(Q, {f=f, at=(s or 0)}) return #Q end
function Wait.frames(f, n) note(Q, {f=f, at=(n or 1)/60}) return #Q end
function Wait.condition(f) note(Q, {f=f, at=0}) return #Q end
function Wait.stop() end
function FLUSH(rounds)
  for _ = 1, (rounds or 12) do
    local batch = Q; Q = {}
    table.sort(batch, function(a,b) return a.at < b.at end)
    for _, e in ipairs(batch) do pcall(e.f) end
    if #Q == 0 then break end
  end
end

-- FLUSH with a CLOCK: run only what is due within `secs`, leaving longer waits pending.
-- FLUSH has no clock at all -- it fires every callback whatever its delay -- so anything that depends
-- on a window could not be tested: the wipe confirmation's 3s auto-revert went off between the arm
-- click and the commit click, and the button was never still armed when the second click arrived.
function FLUSH_UNTIL(secs, rounds)
  for _ = 1, (rounds or 12) do
    local due, later = {}, {}
    for _, e in ipairs(Q) do
      if (e.at or 0) <= secs then due[#due+1] = e else later[#later+1] = e end
    end
    if #due == 0 then Q = later break end
    Q = later
    table.sort(due, function(a,b) return a.at < b.at end)
    for _, e in ipairs(due) do pcall(e.f) end
  end
end

local function vec(t, y2, z2)
  if type(t) == 'number' then t = {t, y2 or 0, z2 or 0} end
  t = t or {}
  local v = {x = t.x or t[1] or 0, y = t.y or t[2] or 0, z = t.z or t[3] or 0}
  v[1],v[2],v[3] = v.x,v.y,v.z
  function v:rotateOver(axis, deg)
    local r = math.rad(deg)
    if axis == "y" then
      local x,z = self.x, self.z
      self.x = x*math.cos(r) + z*math.sin(r)
      self.z = -x*math.sin(r) + z*math.cos(r)
      self[1],self[3] = self.x,self.z
    end
    return self
  end
  setmetatable(v, {__add = function(a,b) return vec{a.x+(b.x or b[1] or 0), a.y+(b.y or b[2] or 0), a.z+(b.z or b[3] or 0)} end,
                   __mul = function(a,b)
                     if type(b) == "table" then return vec{a.x*(b.x or b[1]), a.y*(b.y or b[2]), a.z*(b.z or b[3])} end
                     return vec{a.x*b, a.y*b, a.z*b} end})
  return v
end
Vector = vec

-- objects -------------------------------------------------------------------
local NEXT = 0
local LIVE = {}
function MKOBJ(name, pos, tags)
  NEXT = NEXT + 1
  local g = string.format("o%04d", NEXT)
  local o = {__guid = g, __name = name or "", __tags = tags or {}, __pos = vec(pos), __dead = false,
             __rot = vec{0,0,0}, __scale = vec{1,1,1}, use_snap_points = false, held_by_color = nil}
  function o.getGUID() return o.__guid end
  function o.getName() return o.__name end
  function o.setName(n) o.__name = n end
  -- COPIES, not the live tables. TTS returns a fresh Vector from each of these, and callers rely
  -- on that: makeSpecial does `local scale = self.getScale(); scale.x = 1/scale.x`, which with a
  -- live table silently INVERTED the setup board's real scale -- and then again on the next call,
  -- so every spawn after the first landed somewhere different. Invisible while the stub's scale
  -- was 1 (1/1 == 1); it only surfaced once the stub carried the board's real 15.5.
  function o.getPosition() return vec(o.__pos) end
  function o.setPosition(p) o.__pos = vec(p) end
  function o.getRotation() return vec(o.__rot) end
  function o.setRotation(r) o.__rot = vec(r) end
  function o.getScale() return vec(o.__scale) end
  function o.setScale(s) o.__scale = vec(s) end
  function o.addTag(t) o.__tags[#o.__tags+1] = t end
  function o.hasTag(t) for _,x in ipairs(o.__tags) do if x == t then return true end end return false end
  function o.getTags() return o.__tags end
  function o.setTags(t) o.__tags = t or {} end
  function o.getLock() return o.__locked == true end
  function o.destruct() if not o.__dead then o.__dead = true; note(REC.destroyed, o.__name.."|"..table.concat(o.__tags,",")) end end
  o.__bounds = {size = vec{2.5, 0.3, 3.5}, center = vec{0,0,0}}
  function o.getBounds() return o.__bounds end
  -- the `fast` flag is recorded: TTS's third argument is the only speed control there is, and the
  -- gizmo's warrior pull turns on it.
  function o.setPositionSmooth(p, collide, fast)
    o.__pos = vec(p); o.__smoothFast = (fast == true)
    note(REC.hands, string.format("move:%s->%.2f,%.2f%s", o.__name, o.__pos.x, o.__pos.z, fast and " fast" or ""))
  end
  function o.setLock(v) o.__locked = (v == true) end function o.setColorTint() end function o.shuffle() end
  function o.randomize() end function o.reload() return o end function o.clone(p) return MKOBJ(o.__name, (p or {}).position, o.__tags) end
  function o.takeObject(p) local t = MKOBJ((p or {}).guid or "taken", (p or {}).position, {})
      if p and p.callback_function then p.callback_function(t) end return t end
  function o.putObject(x) return x end
  function o.getObjects() return {} end
  -- A REAL transform: scale, then rotate about Y, then translate. These returned the local vector
  -- UNCHANGED, so every world position derived from a board -- the crow plots, the crow hidden zone,
  -- the Knaves captains board -- came out as raw board-local numbers and no test could check where
  -- anything actually lands. Only Y rotation is modelled; nothing in this mod tilts a board.
  function o.positionToWorld(v)
    local l = vec(v)
    local sx, sy, sz = o.__scale.x, o.__scale.y, o.__scale.z
    local a = math.rad(o.__rot.y or 0)
    local ca, sa = math.cos(a), math.sin(a)
    local x, y, z = l.x * sx, l.y * sy, l.z * sz
    return vec{ o.__pos.x + x * ca + z * sa, o.__pos.y + y, o.__pos.z - x * sa + z * ca }
  end
  function o.positionToLocal(v)
    local w = vec(v)
    local dx, dy, dz = w.x - o.__pos.x, w.y - o.__pos.y, w.z - o.__pos.z
    local a = math.rad(o.__rot.y or 0)
    local ca, sa = math.cos(a), math.sin(a)
    local x, z = dx * ca - dz * sa, dx * sa + dz * ca
    return vec{ x / (o.__scale.x ~= 0 and o.__scale.x or 1),
                dy / (o.__scale.y ~= 0 and o.__scale.y or 1),
                z / (o.__scale.z ~= 0 and o.__scale.z or 1) }
  end
  function o.getSnapPoints() return {} end
  function o.call() end function o.setVar() end function o.getVar() end
  function o.setTable() end function o.getTable() end
  function o.createButton() end function o.clearButtons() end
  function o.setSnapPoints() end function o.getQuantity() return 1 end
  function o.getStateId() return 1 end function o.setState(s) return o end
  function o.deal() end function o.flip() end function o.setDescription() end
  function o.getDescription() return "" end function o.getCustomObject() return {} end
  function o.setCustomObject() end function o.getLuaScript() return "" end
  function o.setLuaScript() end function o.getGMNotes() return "" end
  function o.setGMNotes() end function o.getValue() return 0 end function o.setValue() end
  o.UI = {setXml=function() end, setAttribute=function() end, getAttribute=function() return "" end,
          setXmlTable=function() end, getXmlTable=function() return {} end, show=function() end, hide=function() end}
  LIVE[g] = o
  return o
end
function getObjectFromGUID(g) local o = LIVE[g]; if o and not o.__dead then return o end return nil end
function getObjectsWithTag(t)
  local r = {}
  for _, o in pairs(LIVE) do if not o.__dead and o.hasTag(t) then r[#r+1] = o end end
  return r
end
-- the gizmo asks who you are hovering and where you are pointing
HOVER = {}
POINTER = {}
function getAllObjects() local r = {} for _,o in pairs(LIVE) do if not o.__dead then r[#r+1] = o end end return r end
getObjects = getAllObjects
function spawnObjectJSON(p)
  local j = (p or {}).json or ""
  -- An EMPTY nickname is no nickname. TTS shows such an object by its Name, and several blueprints
  -- ship that way (the Digital_Clock and the Counter both do) -- but "" is TRUTHY in Lua, so the
  -- `or` chain stopped at it and every one of them came out named "", invisible to any test.
  local n = j:match('"Nickname":%s*"([^"]*)"')
  if n == nil or n == "" then n = j:match('"Name":%s*"([^"]*)"') end
  if n == nil or n == "" then n = "?" end
  local o = MKOBJ(n, (p or {}).position, {})
  -- The spawn ROTATION and SCALE, which the stub used to drop on the floor -- so no test could tell a
  -- tile spawned face up from one spawned face down, which is exactly what the crow plots turn on.
  -- Transform from the BLUEPRINT first, then let the spawn call override it. A faction piece is
  -- spawned with a position only -- its scale and rotation live in its own json -- so reading the
  -- blueprint is what makes positionToWorld give a real answer for boards like the crow rules board
  -- (scale 8.82) that everything else is positioned against.
  local sx = tonumber(j:match('"scaleX":%s*([-%d.eE]+)'))
  local sy = tonumber(j:match('"scaleY":%s*([-%d.eE]+)'))
  local sz = tonumber(j:match('"scaleZ":%s*([-%d.eE]+)'))
  if sx and sy and sz then o.__scale = vec{sx, sy, sz} end
  local ry = tonumber(j:match('"rotY":%s*([-%d.eE]+)'))
  if ry then o.__rot = vec{0, ry, 0} end
  if p and p.rotation then o.__rot = vec(p.rotation) end
  if p and p.scale then o.__scale = vec(p.scale) end
  note(REC.spawned, string.format("%s@%.1f,%.1f", n, o.__pos.x, o.__pos.z))
  if p and p.callback_function then p.callback_function(o) end
  return o
end
function spawnObject(p)
  local o = MKOBJ((p or {}).type or "obj", (p or {}).position, {})
  if p and p.callback_function then p.callback_function(o) end
  return o
end

-- A deck whose contents the mod can inspect and draw from. `specs` is a list of {desc}, top first.
function MKDECK(specs)
  local o = MKOBJ("Deck", {0, 2, 0}, {"Deck Object"})
  o.name = "Deck"
  o.__cards = {}
  for i, sp in ipairs(specs) do
    o.__cards[i] = { guid = string.format("c%03d", i), description = sp.desc or "", nickname = sp.nick or "card" }
  end
  function o.getObjects() return o.__cards end
  function o.getQuantity() return #o.__cards end
  function o.putObject(other)
    local n = #o.__cards
    if other.__cards then
      for _, c in ipairs(other.__cards) do n = n + 1; o.__cards[n] = c end
      other.__cards = {}
    else
      o.__cards[n + 1] = { guid = other.getGUID(), description = "Frog", nickname = other.getName() }
    end
    other.destruct()
    return o
  end
  function o.takeObject(p)
    p = p or {}
    local idx = 1                                    -- no guid given: the TOP card
    if p.guid then
      for i, c in ipairs(o.__cards) do if c.guid == p.guid then idx = i break end end
    end
    local c = table.remove(o.__cards, idx)
    if c == nil then return nil end
    local t = MKOBJ(c.nickname, p.position, {})
    t.name = "Card"
    t.__desc = c.description
    t.getDescription = function() return c.description end
    t.is_face_down = false
    note(REC.spawned, "take:" .. (c.description ~= "" and c.description or c.nickname))
    if p.callback_function then p.callback_function(t) end
    return t
  end
  return o
end

-- players -------------------------------------------------------------------
local HANDS = {}
local COLORS = {"Red","Yellow","Orange","Teal","Green","Brown","Blue","Purple","Pink","White","Grey","Black"}
Player = {}

-- A ROSTER, not one fixed object per colour. The stub used to keep a single Player[c] table per
-- colour with changeColor as a NO-OP, so every assertion about who sits where was really an assertion
-- about nothing -- and it could not represent the one state the seating code actually relies on:
-- kickPlayersFromSeats parks EVERY player in Grey at once, and TTS lets many players share Grey.
-- Colour is now a property of a person, so a person can move between colours and Grey can hold a
-- crowd. Hand transforms stay keyed by COLOUR, because in TTS they belong to the colour, not the
-- person, and exist whether or not anybody is sitting in it.
local ROSTER = {}                       -- { {name=..., color=...}, ... }, one entry per human

local function holder(c)                -- the person currently in colour c, or nil
  for _, e in ipairs(ROSTER) do if e.color == c then return e end end
  return nil
end

-- ONE STABLE table per colour, refreshed in place rather than rebuilt. Tests monkey-patch these
-- (Player["Red"].getHandTransform = ...), so handing back a fresh table on every index silently threw
-- the patch away. Identity is per COLOUR because that is what TTS hands you: Player["Red"] is the
-- Red SEAT, and who is sitting in it is a property that changes.
local VIEW = {}

local function refresh(c)
  local v, e = VIEW[c], holder(c)
  v.seated     = e ~= nil
  v.steam_name = e and e.name or ("P_" .. c)
  return v
end

for _, c in ipairs(COLORS) do
  HANDS[c] = { [1] = {position = vec{-75, 12, -75 + _}, rotation = vec{0,0,0}, scale = vec{10,5,5}},
               [2] = {position = vec{-75, 12, -75 + _}, rotation = vec{0,0,0}, scale = vec{10,5,5}} }
  VIEW[c] = {
    color = c, seated = false, steam_name = "P_" .. c,
    getHoverObject = function() return HOVER[c] end,
    getPointerPosition = function() return POINTER[c] or {x=0,y=1,z=0} end,
    getHandTransform = function(n) return HANDS[c][n or 1] end,
    setHandTransform = function(t, n)
      n = n or 1
      HANDS[c][n] = {position = vec(t.position), rotation = vec(t.rotation), scale = vec(t.scale or {1,1,1})}
      note(REC.hands, string.format("%s#%d -> %.2f,%.2f ry=%.1f", c, n, HANDS[c][n].position.x, HANDS[c][n].position.z, HANDS[c][n].rotation.y))
    end,
    -- REAL. TTS moves the PERSON to the other colour, and the ref you were holding now names a seat
    -- that person has left -- exactly the staleness rttSeatPlayers documents ("refs are stale after
    -- the colour change"), which is why it re-reads getPlayers() after the kick. Grey and Black are
    -- shared, so parking a crowd there is allowed; every other colour seats exactly one person.
    changeColor = function(nc)
      local e = holder(c)
      if e == nil or nc == nil or nc == c then return end
      if holder(nc) ~= nil and nc ~= "Grey" and nc ~= "Black" then return end   -- TTS refuses a taken seat
      note(REC.colors, c .. " -> " .. nc)
      e.color = nc
    end,
    getHandCount = function() return 2 end,
    getHandObjects = function() return {} end, print = function() end, broadcast = function() end,
  }
end

setmetatable(Player, { __index = function(_, c)
  if type(c) ~= "string" or VIEW[c] == nil then return nil end
  return refresh(c)
end })

-- getPlayers hands back ONE ENTRY PER PERSON, not per colour. Grey is shared -- kickPlayersFromSeats
-- parks the whole table there at once -- so returning the colour view would have collapsed everybody
-- in Grey into whoever happened to hold it first, and the re-seat loop would have seated one person
-- N times. Each proxy carries its own person (colour, name) and inherits the COLOUR's methods, so a
-- test that patched Player["Red"].getHandTransform still sees its patch through the proxy.
function Player.getPlayers()
  local r = {}
  for _, e in ipairs(ROSTER) do
    r[#r+1] = setmetatable({
      color = e.color, seated = true, steam_name = e.name,
      changeColor = function(nc)
        if nc == nil or nc == e.color then return end
        if holder(nc) ~= nil and nc ~= "Grey" and nc ~= "Black" then return end
        note(REC.colors, e.color .. " -> " .. nc)
        e.color = nc
      end,
    }, { __index = function(_, k) return VIEW[e.color][k] end })
  end
  return r
end
function Player.getSpectators() return {} end

function SEAT(c, name)
  local e = holder(c)
  if e then e.name = name or e.name return end
  ROSTER[#ROSTER+1] = { name = name or ("P_" .. c), color = c }
end
function HANDOF(c, n) local h = HANDS[c][n]; return {x = h.position.x, z = h.position.z, ry = h.rotation.y} end

-- globals -------------------------------------------------------------------
local GV = {}
Global = {
  setVar = function(k, v) GV[k] = v; note(REC.globals, k) end,
  getVar = function(k) return GV[k] end,
  setTable = function(k, v) GV[k] = v end,
  getTable = function(k) return GV[k] end,
  call = function(n, a) note(REC.calls, n) end,
}
function GVGET(k) return GV[k] end

Turns = setmetatable({}, {__newindex = function(t, k, v) rawset(t, k, v); note(REC.turns, tostring(k).."="..tostring(v)) end})

self = MKOBJ("Faction Selection", {0, 1, 0}, {})
-- The REAL setup board is scale 15.5 (gen/src/save.json, guid bab7e1), and rttSpawnFaction
-- multiplies every piece's move_to by (1/self.scale) * 15.5 -- which cancels to 1:1 only at
-- that scale. Left at 1, the stub placed every faction piece 15.5x too far out, so any test
-- measuring where a board or a token lands was measuring a number the game never produces.
self.__scale = vec{15.5, 1.0, 15.5}
self.getTable = function() return nil end
self.setTable = function() end
-- setAttribute RECORDS. It was a no-op, so nothing could check that arming a button actually swaps
-- its art and colour -- which is the whole visible half of the wipe confirmation.
UIATTR = {}
self.UI = {setXml=function() end,
           setAttribute=function(id, k, v) UIATTR[tostring(id).."."..tostring(k)] = v end,
           getAttribute=function() return "" end,
           setXmlTable=function() end, getXmlTable=function() return {} end, show=function() end, hide=function() end}

function printToAll() end function printToColor() end function broadcastToAll() end
-- recorded, because "the gizmo said why instead of silently acting on the wrong faction" is now
-- something the tests have to be able to check.
SAID = {}
function broadcastToColor(msg, color) SAID[#SAID+1] = tostring(color) .. ': ' .. tostring(msg) end
function log() end function logStyle() end
function startLuaCoroutine(o, f) if _G[f] then _G[f]() end return 1 end
function getSeatedPlayers() local r = {} for _,c in ipairs(COLORS) do if Player[c].seated then r[#r+1]=c end end return r end
function destroyObject(o) if o and o.destruct then o.destruct() end end
function copy(o) return o end
UI = {setAttribute=function() end, getAttribute=function() return "" end, setXml=function() end,
      show=function() end, hide=function() end, setValue=function() end, getValue=function() return "" end}
Notes = {setNotebookTabs=function() end, getNotebookTabs=function() return {} end, setNotes=function() end, getNotes=function() return "" end}
Lighting = {} Physics = {cast=function() return {} end} Backgrounds = {} Turns.enable = false
Color = setmetatable({fromString = function(s) return {r=0,g=0,b=0} end}, {__call = function(_, ...) return {...} end})

-- A real enough JSON: the mod round-trips RTT_SEAT_POS/_COLOR/_PLAYER through it,
-- so a stub that returns nil would hide exactly the bugs we are testing for.
JSON = {}
local function esc(s) return (s:gsub('[%c"\\]', function(c)
  if c == '"' then return '\\"' elseif c == '\\' then return '\\\\' else return string.format('\\u%04x', c:byte()) end end)) end
function JSON.encode(v)
  local t = type(v)
  if t == "nil" then return "null" end
  if t == "number" then return (v % 1 == 0) and string.format("%d", v) or tostring(v) end
  if t == "boolean" then return tostring(v) end
  if t == "string" then return '"'..esc(v)..'"' end
  local isArr, n = true, 0
  for k in pairs(v) do n = n + 1; if type(k) ~= "number" then isArr = false end end
  if n == 0 then return "{}" end
  local out = {}
  if isArr then
    for i = 1, n do out[#out+1] = JSON.encode(v[i]) end
    return "["..table.concat(out, ",").."]"
  end
  local keys = {}
  for k in pairs(v) do keys[#keys+1] = tostring(k) end
  table.sort(keys)
  for _, k in ipairs(keys) do out[#out+1] = '"'..esc(k)..'":'..JSON.encode(v[k] ~= nil and v[k] or v[tonumber(k)]) end
  return "{"..table.concat(out, ",").."}"
end
local function skipws(s, i) local _, j = s:find("^[ \t\r\n]*", i); return (j or i-1) + 1 end
local parse
local function pstr(s, i)
  local out, i = {}, i + 1
  while i <= #s do
    local c = s:sub(i,i)
    if c == '"' then return table.concat(out), i + 1 end
    if c == '\\' then
      local n = s:sub(i+1,i+1)
      if n == 'u' then out[#out+1] = string.char(tonumber(s:sub(i+2,i+5), 16) % 256); i = i + 6
      else out[#out+1] = (n == 'n' and '\n') or (n == 't' and '\t') or n; i = i + 2 end
    else out[#out+1] = c; i = i + 1 end
  end
  return table.concat(out), i
end
parse = function(s, i)
  i = skipws(s, i)
  local c = s:sub(i,i)
  if c == '"' then return pstr(s, i) end
  if c == '{' then
    local o = {}; i = skipws(s, i+1)
    if s:sub(i,i) == '}' then return o, i+1 end
    while true do
      local k, v
      k, i = pstr(s, skipws(s, i))
      i = skipws(s, i); i = i + 1                      -- ':'
      v, i = parse(s, i); o[k] = v
      i = skipws(s, i)
      if s:sub(i,i) == ',' then i = i + 1 else return o, i + 1 end
    end
  end
  if c == '[' then
    local a = {}; i = skipws(s, i+1)
    if s:sub(i,i) == ']' then return a, i+1 end
    while true do
      local v; v, i = parse(s, i); a[#a+1] = v
      i = skipws(s, i)
      if s:sub(i,i) == ',' then i = i + 1 else return a, i + 1 end
    end
  end
  if s:sub(i, i+3) == "true"  then return true,  i+4 end
  if s:sub(i, i+4) == "false" then return false, i+5 end
  if s:sub(i, i+3) == "null"  then return nil,   i+4 end
  local num = s:match("^%-?%d+%.?%d*[eE]?[%+%-]?%d*", i)
  if num then return tonumber(num), i + #num end
  return nil, i + 1
end
function JSON.decode(s) if type(s) ~= "string" or s == "" then return nil end
  local ok, v = pcall(function() local r = parse(s, 1) return r end); if ok then return v end return nil end
