"""
m500 — the 5-player Marsh ranked draft (the 5-player art button).

Same as the ranked (owl) draft, but: the map is forced to Marsh (Player 1 only picks a
deck), and the Marsh board spawns in a 5-player layout — NO flooding, all 15 clearings
active. Three random clearings get the three town landmarks (Rabbit-Town / Foxburrow /
Mousehold) standing up (with their rules cards) instead of a suit marker; the other 12 get
the 12 suit markers. Clearing-number markers go on the 12 suit clearings only (the 3
landmark clearings get no number — reusing m460's "drop the token on the RTT_MARSH_FLOODED
positions" path, which m500 repurposes to the 3 landmark positions).

Wiring:
  * the 5-player art button (m240) -> rttFivePStart -> rttSetup + RTT_5P_MARSH = true
  * rttSetup resets RTT_5P_MARSH = false, so the owl button stays the normal ranked draft
  * the pick flow pre-sets the map to Marsh and, on P1's deck pick, spawns Marsh + starts
    the faction draft (no P2 map/deck pick)
  * makeMap's Marsh branch uses rttMarshPlan5P (no floods) when RTT_5P_MARSH
  * a makeMap Marsh hook places the 3 town landmarks after the board settles
"""
from . import framework

NAME = "5-player Marsh ranked draft + towns-on-clearings"

MAKEMAP_SIG = "function makeMap(player,value,id)"

LUA = r"""
-- ===== RTT 5-player Marsh draft =====
RTT_5P_MARSH = RTT_5P_MARSH or false

function rttFivePStart(player, value, id)
  rttSetup(player, value, id)   -- resets RTT_5P_MARSH=false at its start; we set it after
  RTT_5P_MARSH = true
end

-- 5-player Marsh plan: no flooding; all 15 clearings active; 3 random -> town landmarks,
-- the other 12 -> the 12 suit markers. Reuses m440's RTT_MARSH_SUIT9 / RTT_MARSH data.
function rttMarshPlan5P(objects)
  RTT_MARSH_N = (RTT_MARSH_N or 0) + 1
  math.randomseed(os.time() + RTT_MARSH_N * 7919)
  for k = 1, 10 do math.random() end

  local floodIx, ruinIx, suitIx = {}, {}, {}
  for idx, v in ipairs(objects) do
    local j = v.json
    if string.find(j, "53E4E9F1", 1, true) or string.find(j, "C5C35E37", 1, true)
       or string.find(j, "B37C9A48", 1, true) then floodIx[#floodIx + 1] = idx
    elseif string.find(j, "RUIN", 1, true) then ruinIx[#ruinIx + 1] = idx
    elseif string.find(j, "Clearing Marker", 1, true) then suitIx[#suitIx + 1] = idx
    end
  end

  -- 15 clearing suit positions = 9 fixed + both sides of the 3 pairs
  local clearings = {}
  for _, p in ipairs(RTT_MARSH_SUIT9) do clearings[#clearings + 1] = { p[1], p[2], p[3], p[4] } end
  for _, m in ipairs(RTT_MARSH) do
    local u, d = m.up.suit, m.down.suit
    clearings[#clearings + 1] = { u[1], u[2], u[3], u[4] }
    clearings[#clearings + 1] = { d[1], d[2], d[3], d[4] }
  end
  rttShuffleList(clearings)

  -- first 3 -> town landmarks; the rest -> suits
  local towns = { "Rabbit-Town", "Foxburrow", "Mousehold" }
  rttShuffleList(towns)
  RTT_MARSH_LANDMARKS = {}
  RTT_MARSH_FLOODED = {}    -- the 3 "no-number" clearings (m460 drops their number tokens)
  for i = 1, 3 do
    local c = clearings[i]
    RTT_MARSH_LANDMARKS[i] = { x = c[1], z = c[3], name = towns[i] }
    RTT_MARSH_FLOODED[i] = { c[1], c[3] }
  end

  local ov = {}
  -- 12 suit markers onto clearings 4..15
  for i, idx in ipairs(suitIx) do
    local c = clearings[3 + i]
    if c ~= nil then ov[idx] = { world = { c[1], c[2], c[3] }, rot = { 0, c[4], 0 } } end
  end
  -- no flooding: send the 3 flood tiles below the table
  for _, idx in ipairs(floodIx) do
    ov[idx] = { world = { 0, -50, 0 }, rot = nil }
  end
  -- ruins: 2 fixed + the pair ruin spots (best-effort onto valid clearings)
  local ruinSlots = {}
  for _, p in ipairs(RTT_MARSH_RUIN_FIXED) do ruinSlots[#ruinSlots + 1] = { p[1], p[2], p[3] } end
  for _, m in ipairs(RTT_MARSH) do
    if m.up.ruin ~= nil then ruinSlots[#ruinSlots + 1] = m.up.ruin end
    if m.down.ruin ~= nil then ruinSlots[#ruinSlots + 1] = m.down.ruin end
  end
  rttShuffleList(ruinSlots)
  for i, idx in ipairs(ruinIx) do
    local p = ruinSlots[i]
    if p ~= nil then ov[idx] = { world = { p[1], p[2], p[3] }, rot = nil } end
  end
  return ov
end

-- the 3 town rules cards go in a row at the map's lower-left (confirm/nudge in TTS)
RTT_MARSH_CARD_ROW = { { -29.3, 11.58, -20.0 }, { -29.3, 11.58, -13.5 }, { -29.3, 11.58, -7.0 } }

-- spawn each town standing on its clearing + its rules card in the lower-left row, all
-- DIRECTLY at their final transforms (rttSpawnLandmarkAt, from m490) so they appear in
-- place and settle onto the board — no slide/rotate.
function rttMarshLandmarks()
  if not RTT_5P_MARSH then return end
  local ci = 0
  for _, lm in ipairs(RTT_MARSH_LANDMARKS or {}) do
    ci = ci + 1
    local si = ci
    if si > 3 then si = 3 end
    local slot = RTT_MARSH_CARD_ROW[si]
    rttSpawnLandmarkAt(lm.name, lm.x, 11.66, lm.z, slot[1], slot[2], slot[3])
  end
end

-- Mountain: the Tower is never used (a landmark replaces it), so spawn it BELOW the table
-- from frame one instead of spawning it on the board and destroying it (no visible flash).
-- rttMountainLandmark still destroys the (hidden) tower via its "Tower" tag afterwards.
function rttMountainHideTower(objects)
  local ov = {}
  for idx, v in ipairs(objects) do
    if string.find(v.json, "\"Tower\"", 1, true) ~= nil then
      ov[idx] = { world = { 0, -60, 0 }, rot = nil }
    end
  end
  return ov
end
"""

MARSH_LM_HOOK = ('\n  if id == "Marsh Map" and RTT_5P_MARSH then'
                 ' Wait.time(function() rttMarshLandmarks() end, 1.4) end')

# --- injection anchors (edit the compiled Lua produced by earlier mods) ---
# rttSetup start: reset the 5-player flag AND wipe any boards from a prior launch (the
# selector clones + every drafted faction piece), so relaunching starts clean.
SETUP_ANCHOR = "function rttSetup(player, value, id)\n"
SETUP_RESET = ('function rttSetup(player, value, id)\n'
               '  RTT_5P_MARSH = false\n'
               '  for _, o in ipairs(getObjectsWithTag("RTT Selector")) do pcall(function() o.destruct() end) end\n'
               '  for _, o in ipairs(getObjectsWithTag("RTT Faction")) do pcall(function() o.destruct() end) end\n')

# solo test path deals to 4 virtual players; a 5-player launch needs 5 boards
SOLO_OLD = ("for _,c in ipairs({'Red','Yellow','Teal','Orange'}) do "
            "RTT_ORDER[#RTT_ORDER+1] = {color=c, name=nm} end")
SOLO_NEW = ("for _,c in ipairs(RTT_5P_MARSH and {'Red','Yellow','Teal','Orange','Green'} "
            "or {'Red','Yellow','Teal','Orange'}) do RTT_ORDER[#RTT_ORDER+1] = {color=c, name=nm} end")

# tag every drafted faction piece so a relaunch can wipe them (see SETUP_RESET)
FACTION_TAG_OLD = "  local function cb(o)\n    if flip then o.setRotation("
FACTION_TAG_NEW = "  local function cb(o)\n    o.addTag(\"RTT Faction\")\n    if flip then o.setRotation("

PLAN_OLD = "RTT_OV = rttMarshPlan(objects)"
PLAN_NEW = "if RTT_5P_MARSH then RTT_OV = rttMarshPlan5P(objects) else RTT_OV = rttMarshPlan(objects) end"

# after the Marsh override block, add a Mountain branch that hides the Tower at spawn
MTN_OV_OLD = PLAN_NEW + "\n  end"
MTN_OV_NEW = PLAN_NEW + "\n  end\n  if id == \"Mountain Map\" then RTT_OV = rttMountainHideTower(objects) end"

BEGIN_ANCHOR = "  RTT_PICKED = { map = nil, deck = nil }\n  RTT_PICK_STAGE = 1"
BEGIN_NEW = ("  RTT_PICKED = { map = nil, deck = nil }\n"
             "  if RTT_5P_MARSH then RTT_PICKED.map = \"Marsh Map\" end\n  RTT_PICK_STAGE = 1")

TITLE_OLD = ('  local what = (stage == 1) and "Pick a MAP or a DECK" or '
             '("Pick the " .. ((RTT_PICKED.map == nil) and "MAP" or "DECK"))')
TITLE_NEW = ('  local what\n'
             '  if RTT_5P_MARSH then what = "Pick a DECK"\n'
             '  else what = (stage == 1) and "Pick a MAP or a DECK" or '
             '("Pick the " .. ((RTT_PICKED.map == nil) and "MAP" or "DECK")) end')

COORD_ANCHOR = ('    if clone ~= nil then clone.UI.setAttribute("rttPickMapDeck", "active", "false") end\n'
                '    RTT_PICK_STAGE = 2')
COORD_NEW = ('    if clone ~= nil then clone.UI.setAttribute("rttPickMapDeck", "active", "false") end\n'
             '    if RTT_5P_MARSH then rttPlaceMap("Marsh Map") RTT_PICK_STAGE = 0 rttStartFactionDraft() return end\n'
             '    RTT_PICK_STAGE = 2')


# the VISIBLE "5 Players" button is Marsh5P (the Board-Studio layout dropped the m240
# fivePlayerSetup art button). Repurpose Marsh5P into the 5-player ART button that launches
# the 5-player Marsh draft (FivePlayerArt asset is still registered by m240; onclick ->
# rttFivePStart; #ffffff so the icon tint is neutral).
MARSH5P_OLD = ('<Button id="Marsh5P" onclick="rttMarsh5P" text="5 Players" '
               'position="95 -69.5 -20" width="34" height="17" fontSize="7" color="#9b8551"/>')
# keep Adrien's original half-rectangle shape/spot; just swap in the art + the new handler
MARSH5P_NEW = ('<Button id="Marsh5P" onclick="rttFivePStart" icon="FivePlayerArt" '
               'position="95 -69.5 -20" width="34" height="17" color="#ffffff"/>')


def _sub(text, old, new, label):
    eo = framework.esc(old)
    if text.count(eo) != 1:
        raise framework.BuildError("m500 anchor not unique (%s): %d" % (label, text.count(eo)))
    return text.replace(eo, framework.esc(new), 1)


def apply(text):
    if text.count(MAKEMAP_SIG) != 1:
        raise framework.BuildError("makeMap anchor not unique")
    text = text.replace(MAKEMAP_SIG, framework.esc(LUA) + MAKEMAP_SIG, 1)
    text = text.replace(MAKEMAP_SIG, MAKEMAP_SIG + framework.esc(MARSH_LM_HOOK), 1)

    text = _sub(text, SETUP_ANCHOR, SETUP_RESET, "rttSetup reset")
    text = _sub(text, SOLO_OLD, SOLO_NEW, "solo -> 5 boards")
    text = _sub(text, FACTION_TAG_OLD, FACTION_TAG_NEW, "tag faction pieces")
    text = _sub(text, PLAN_OLD, PLAN_NEW, "marsh plan")
    text = _sub(text, MTN_OV_OLD, MTN_OV_NEW, "mountain hide-tower")
    text = _sub(text, BEGIN_ANCHOR, BEGIN_NEW, "rttBeginPick")
    text = _sub(text, TITLE_OLD, TITLE_NEW, "rttShowPick title")
    text = _sub(text, COORD_ANCHOR, COORD_NEW, "rttCoordPick 5p")
    text = _sub(text, MARSH5P_OLD, MARSH5P_NEW, "Marsh5P button -> 5-player art")
    return text
