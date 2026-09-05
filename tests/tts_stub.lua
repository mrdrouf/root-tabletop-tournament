-- Minimal TTS surface, instrumented so the harness can observe what a setup path DID.
REC = { destroyed = {}, spawned = {}, hands = {}, globals = {}, turns = {}, calls = {} }
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
  function o.getPosition() return o.__pos end
  function o.setPosition(p) o.__pos = vec(p) end
  function o.getRotation() return o.__rot end
  function o.setRotation(r) o.__rot = vec(r) end
  function o.getScale() return o.__scale end
  function o.setScale(s) o.__scale = vec(s) end
  function o.addTag(t) o.__tags[#o.__tags+1] = t end
  function o.hasTag(t) for _,x in ipairs(o.__tags) do if x == t then return true end end return false end
  function o.getTags() return o.__tags end
  function o.setTags(t) o.__tags = t or {} end
  function o.getLock() return o.__locked == true end
  function o.destruct() if not o.__dead then o.__dead = true; note(REC.destroyed, o.__name.."|"..table.concat(o.__tags,",")) end end
  o.__bounds = {size = vec{2.5, 0.3, 3.5}, center = vec{0,0,0}}
  function o.getBounds() return o.__bounds end
  function o.setPositionSmooth(p) o.__pos = vec(p); note(REC.hands, string.format("move:%s->%.2f,%.2f", o.__name, o.__pos.x, o.__pos.z)) end
  function o.setLock(v) o.__locked = (v == true) end function o.setColorTint() end function o.shuffle() end
  function o.randomize() end function o.reload() return o end function o.clone(p) return MKOBJ(o.__name, (p or {}).position, o.__tags) end
  function o.takeObject(p) local t = MKOBJ((p or {}).guid or "taken", (p or {}).position, {})
      if p and p.callback_function then p.callback_function(t) end return t end
  function o.putObject(x) return x end
  function o.getObjects() return {} end
  function o.positionToWorld(v) return vec(v) end
  function o.positionToLocal(v) return vec(v) end
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
  local n = j:match('"Nickname":%s*"([^"]*)"') or j:match('"Name":%s*"([^"]*)"') or "?"
  local o = MKOBJ(n, (p or {}).position, {})
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
local SEATED = {}
for i, c in ipairs(COLORS) do
  HANDS[c] = { [1] = {position = vec{-75, 12, -75 + i}, rotation = vec{0,0,0}, scale = vec{10,5,5}},
               [2] = {position = vec{-75, 12, -75 + i}, rotation = vec{0,0,0}, scale = vec{10,5,5}} }
  Player[c] = {
    color = c, seated = false, steam_name = "P_"..c,
    getHoverObject = function() return HOVER[c] end,
    getPointerPosition = function() return POINTER[c] or {x=0,y=1,z=0} end,
    getHandTransform = function(n) return HANDS[c][n or 1] end,
    setHandTransform = function(t, n)
      n = n or 1
      HANDS[c][n] = {position = vec(t.position), rotation = vec(t.rotation), scale = vec(t.scale or {1,1,1})}
      note(REC.hands, string.format("%s#%d -> %.2f,%.2f ry=%.1f", c, n, HANDS[c][n].position.x, HANDS[c][n].position.z, HANDS[c][n].rotation.y))
    end,
    changeColor = function(nc) end, getHandCount = function() return 2 end,
    getHandObjects = function() return {} end, print = function() end, broadcast = function() end,
  }
end
function Player.getPlayers() local r = {} for _, c in ipairs(COLORS) do if Player[c].seated then r[#r+1] = Player[c] end end return r end
function Player.getSpectators() return {} end
function SEAT(c, name) Player[c].seated = true; if name then Player[c].steam_name = name end end
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
self.getTable = function() return nil end
self.setTable = function() end
self.UI = {setXml=function() end, setAttribute=function() end, getAttribute=function() return "" end,
           setXmlTable=function() end, getXmlTable=function() return {} end, show=function() end, hide=function() end}

function printToAll() end function printToColor() end function broadcastToAll() end
function broadcastToColor() end function log() end function logStyle() end
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
