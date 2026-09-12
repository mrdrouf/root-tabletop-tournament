-- RTT GAME ARCHIVE -- the recorder and uploader. THIS FILE IS THE SAVE'S GLOBAL SCRIPT.
--
-- It watches a game being played and, when the maintainer presses EXPORT on the box score, POSTs one
-- JSON document to a server he controls. `ARCHIVE.md` is the contract and this file is its §4; the
-- PHP endpoint and the local fetcher are written against the same document and must not disagree
-- with it. A local tool pulls those documents down and files them into the corpus the solver trains
-- on -- so what leaves this table is training data, and everything below is about making that cost
-- the table nothing and reveal nothing it should not.
--
-- The Global slot held 320 bytes of TTS's commented-out template before this. Living here rather
-- than in `logic.lua` means a fault in the recorder cannot take the board's 869 KB script down with
-- it, and the diff against the shipped save is purely additive.
--
-- ---------------------------------------------------------------------------------------------
-- THE THREE CONSTRAINTS, each already paid for somewhere in this repo
--
-- 1. NOTHING RUNS ON A HEARTBEAT. `MULTIPLAYER_SYNC.md` non-negotiable #2, in the maintainer's own
--    acceptance criteria: "Nothing may run on a permanent heartbeat -- the sweep is a small number
--    of one-shots after setup, plus the button. A 1 s resync loop would be constant network churn
--    and repeated physics wake for no benefit." The last attempt at background work in this mod was
--    reverted whole over exactly this. So there is ONE `Wait.time` in this file, it is armed only on
--    the empty->non-empty transition of the pending queue, and it is never re-armed when the queue
--    drains. AN IDLE TABLE HAS ZERO LIVE TIMERS. That invariant is restated at `obsArmFlush`, which
--    is the only place a timer is created, and it is the first thing to check if this file is ever
--    accused of costing someone frames.
--
-- 2. THE RECORDER NEVER WRITES TO AN OBJECT. No `setLock`, no `addTag`, no `setColorTint`, no
--    `setPosition`, no spawn, no destruct -- grep this file: there is not one object write in it.
--    Object writes replicate to every client, and a distant client that drops one incremental
--    message never gets it back; that is the v1.154 bug MULTIPLAYER_SYNC.md was written to diagnose.
--    READS ARE NOT REPLICATED, so a recorder built only out of reads adds literally zero bytes to
--    TTS's client sync and cannot break anybody's table.
--
-- 3. THE EVENT STREAM DOES NOT HAVE TO BE COMPLETE. A full board read costs ~5 ms (measured,
--    `root_engine/docs/PERCEPTION_SPEC.md` §3.1a) and a Root turn takes minutes, so a KEYFRAME AT
--    EVERY TURN CHANGE is free. Events give ordering and latency; keyframes give truth. A missed
--    drag, an undo, a scripted move, a reload -- all corrected at the next keyframe. Nothing in here
--    needs to be clever, because nothing in here needs to be complete.
--
-- ---------------------------------------------------------------------------------------------
-- AND IT SHIPS OFF. `OBS_ENABLED` is false. The rule this mod adopted after v1.154: anything TTS can
-- see that the test harness cannot must ship behind a constant, defaulted off, and be proven on one
-- real game before it is turned on for everybody. The harness has no WebRequest, no Steam ids and no
-- second client, so the parts of this file that matter most are the parts it cannot test -- which is
-- the definition of the class of change that has burned this project before.
--
-- ---------------------------------------------------------------------------------------------
-- THE MEASUREMENTS THAT DICTATE THE CODE (PERCEPTION_SPEC.md §3.1a, 156-object table):
--     getAllObjects  ~0 ms      getPosition / getRotation / getTags  1-2 ms for ALL objects
--     JSON.encode of 156 rows  39 ms, 9012 chars      table.concat of the same  1 ms, 4642 chars
-- 39 ms is a dropped frame on the game's main thread. Reads are cheap; ENCODING is the entire
-- problem. So every row in this file is built as a STRING at the moment it is recorded -- one
-- `string.format` spread over the minutes of a game -- and the document is `table.concat`-ed once,
-- on the button press. `JSON.encode` never sees a row of game data, and the box score's own JSON is
-- pasted through VERBATIM rather than decoded and re-encoded. `root_engine/tts/live.lua` reached
-- this shape first and its header carries the same numbers.
--
-- ---------------------------------------------------------------------------------------------
-- FOUR TRAPS IN THIS INTERPRETER, each of which has already cost this project days:
--
--   * GLOBALS PERSIST between script executions, and `local FULL = FULL or false` SHADOWS the global
--     so clearing it at the end clears only the local. Nothing in this file reads a caller-set flag
--     into a same-named local; where it reads a global RTT publishes (RTT_SEAT_RECORD and friends)
--     it reads the global directly, at call time, and never binds a local of that name.
--   * `local a, b, c` INSIDE A LOOP does not reliably rebind in this interpreter -- values leaked
--     between iterations and pieces arrived carrying another piece's coordinates. One `local` per
--     line, everywhere, exactly as `live.lua` does it.
--   * A PERSISTED CACHE OUTLIVES AN EDIT to the script that wrote it. TTS wipes globals on load, so
--     the usual form of this trap cannot bite here -- but `onSave` state is written into the save
--     file and handed back to `onLoad`, so a log written by an OLDER observer.lua comes back into a
--     NEWER one in the older shape. `OBS_STATE_VER` versions it and discards a mismatch.
--   * `Player` IS USERDATA, NOT A TABLE. `type(player) == "table"` is false in TTS and true in the
--     test stub, which is how `makeMap`'s five-player guard stayed broken through three reports with
--     a green test suite. Nothing here type-checks a player; it reads the field it wants in a pcall.
--
-- Every object call is wrapped in `pcall`, like the rest of this codebase: a handle that
-- `getAllObjects` returned a moment ago can be dead by the time it is asked, which surfaces as
-- "Object reference not set to an instance of an object" and takes the rest of the function with it.

---------------------------------------------------------------------------- the constants --

-- OFF. See the header. Flipping this to `true` in the source arms it for a build; the maintainer can
-- also arm it on a LIVE table from the host's Execute Lua Code box (`OBS_ENABLED = true`) because
-- these are globals rather than file-locals and every handler re-reads the flag on each call. That
-- is the whole point of the gate: one real game, watched, before anybody else's table runs it.
OBS_ENABLED = false

-- THE ENDPOINT IS A CONSTANT, for the same reason the Root Database's URL is one in the box score:
-- a settable URL in an object strangers load off a save is an exfiltration field. There is no write
-- key and there must never be one -- the shipped save is public (dist/ is on GitHub), so anything
-- baked in is public. ARCHIVE.md §0: the ingest endpoint is defended server-side and the READ side
-- is what holds a secret.
--
-- The `www.` host is deliberate, not decoration. It is the host the site's own pages link, and a
-- host that redirects is not a detail on a POST: a 301 can be replayed as a GET with the body
-- dropped, which would look exactly like a silent server failure. Name the canonical host.
-- AND IT IS STORED ENCODED, ASSEMBLED AT RUNTIME. THIS IS IDENTITY SEPARATION, NOT SECURITY.
--
-- This repo is published on GitHub under the pseudonym "mrdrouf". The archive host's domain is the
-- maintainer's REAL NAME, and `dist/Root_Tournament_Edition.json` is committed with this script
-- baked into its top-level LuaScript -- so a plaintext URL in this file is a plaintext URL in a
-- public repo, and code search is very good at surnames. Encoded, a search for his name finds
-- nothing in this project. THAT IS THE ENTIRE PURPOSE, and it is the only thing this buys.
--
-- It is not a secret and it defends nothing. There is no write key and there must never be one (see
-- above); ingest.php is defended server-side. Anyone who reads this file can decode the table below
-- in a minute, and that is DELIBERATE -- a future maintainer has to be able to change the URL, so
-- the scheme is a byte table and an offset and nothing cleverer. Two ways to get this wrong:
--   * DO NOT "clean it up" back into a string literal. The plaintext is the whole problem.
--   * DO NOT treat it as a control that protects anything. It protects a pseudonym, not a server,
--     and nothing downstream may be built on the idea that this URL is hidden from anybody.
--
-- TO CHANGE THE URL, regenerate the table with this one-liner -- run it in a scratch directory and
-- NOT in this repo, so the plaintext is never written into a file here:
--   lua -e 'local u="<the new URL>" local t={} for i=1,#u do t[i]=u:byte(i)+41 end print(table.concat(t,", "))'
-- Each number is one ASCII byte of the URL plus OBS_EP_OFFSET, in order. Nothing else is done to it.
local OBS_EP_OFFSET = 41
local OBS_EP_BYTES = {
  145, 157, 157, 153, 156, 99, 88, 88, 160, 160, 160, 87, 138, 141, 155, 146, 142, 151, 141,
  138, 159, 142, 155, 151, 138, 156, 87, 140, 152, 150, 88, 155, 157, 157, 88, 146, 151, 144,
  142, 156, 157, 87, 153, 145, 153
}

-- The assembled value keeps the plain name the rest of this file already knows it by, so nothing
-- downstream changes shape: it reads OBS_ENDPOINT and neither knows nor cares that it was encoded.
-- It stays a GLOBAL assigned once here at load, exactly as the literal was -- so pointing a live
-- table at a test server from the host's Execute Lua Code box (`OBS_ENDPOINT = "https://..."`)
-- still works, and so does arming one with `OBS_ENABLED = true`.
--
-- A BAD BYTE GIVES AN EMPTY STRING RATHER THAN A MANGLED URL, and obsArchive refuses to send to one
-- that does not start with "https://". A half-edited table -- bytes changed without the offset, a
-- number lost to a stray edit -- would otherwise assemble into garbage that WebRequest fails on with
-- response_code 0 and an empty body, which is exactly what a dead network looks like from here and
-- would send somebody to the server to find a fault that is in this file.
local function obsAssembleEndpoint()
  local out = {}
  -- one `local` per line, inside a loop: the rebinding trap from the header
  for i = 1, #OBS_EP_BYTES do
    local b = OBS_EP_BYTES[i] - OBS_EP_OFFSET
    if b < 32 or b > 126 then return "" end
    out[#out + 1] = string.char(b)
  end
  return table.concat(out)
end

OBS_ENDPOINT = obsAssembleEndpoint()

OBS_SCHEMA = "rtt-game/1"

-- ARCHIVE.md §3: the recorder stops appending at 1 MB and sets "truncated". A game is expected to
-- land near 150 KB, so this is the runaway guard, not a working limit. It also bounds what `onSave`
-- writes into the host's save file, which is the other thing an unbounded log would quietly ruin.
OBS_MAX_BYTES = 1048576

-- Long enough that a dropped piece has stopped rolling, short enough that the ordering of two quick
-- moves is never in doubt. Same order as the box score's own poll, and well under the four seconds
-- it takes anyone to make a second move.
OBS_FLUSH_DELAY = 0.4

-- The setup board ("Faction Selection"). It owns the seating, the map and the priority markers, and
-- it answers `rttSeatRecord` / `rttGetCurrentMap` / `rttFindMapObject`. We ask it rather than
-- re-deriving what it already knows.
OBS_BOARD = "bab7e1"

-- ARCHIVE.md §5: ingest.php rejects a payload whose `seats` is not a non-empty array of at most six
-- entries. Root seats at most six, so a table with more colours seated than that is a table with
-- spectators in player colours -- trimmed rather than quarantined.
OBS_MAX_SEATS = 6

-- Bump this whenever the SHAPE of the saved log changes. `onSave` state survives an edit to the
-- script that wrote it, so without the check a newer observer.lua reads an older log's fields and
-- either silently does nothing or dies indexing a nil. Rebuilding costs one keyframe.
--
-- 2: the SEEN section joined it. A log written by a v1 observer has no record of which GUIDs it had
-- already described, which is exactly the fact the spawn filter at `obsFlush` needs on the far side
-- of a reload -- so a v1 log read into this code would do the wrong thing quietly rather than
-- loudly, which is the case this counter exists for.
OBS_STATE_VER = 2

-- THE FLUSH QUEUE IS BOUNDED, because the one thing that empties it is a timer that is allowed to
-- fail. `obsArmFlush` pcalls `Wait.time` -- deliberately, since that is how the rest of this file
-- treats anything the host can refuse -- and on failure it leaves the handle nil and returns. If
-- arming can NEVER succeed, nothing ever drains `OBS.pend` and every drag for the rest of the
-- session adds another table to it. That is not hypothetical: `OBS_FLUSH_DELAY` below is a global
-- precisely so the maintainer can retune it live from the host's Execute Lua Code box, and
-- `Wait.time` throws on a delay that is negative or not a number, so one fat-fingered tune turns a
-- recorder into a memory leak with no symptom until the session ends.
--
-- 2000 is roughly a full game's worth of events arriving inside a single 0.4 s window -- i.e. a
-- number that a table playing Root cannot reach and a broken timer reaches in a minute. Over it the
-- oldest queued entries go, for the same reason `obsTrim` drops the oldest events: the newest are
-- the ones the next keyframe has not already corrected.
OBS_MAX_PEND = 2000

-- HOW LONG A SEND MAY BE "IN FLIGHT" BEFORE A NEW ONE MAY REPLACE IT. `OBS.sending` exists to stop
-- EXPORT and UPLOAD colliding on the wire; it is not a lock on the feature. But it is cleared only
-- by `obsReport`, which is the WebRequest's callback -- so a request whose callback never arrives
-- latches the flag true and every later press of either button finds a send "already in flight" and
-- writes one line to a console nobody is reading. The archive would be dead for the rest of the
-- session with no visible cause, which is the worst failure this file can have.
--
-- 90 seconds is an order of magnitude longer than the box score's own uploads take, so it can never
-- cut a request that is genuinely still running; and the EXPORT-then-UPLOAD sequence the contract
-- describes has a trip to the website for a one-time token in the middle of it, so the second press
-- arrives long after the first send has answered and this never decides anything there. It only
-- unsticks a table that is already stuck. Measured in os.time() seconds rather than os.clock(),
-- because this is wall time and has to mean the same thing after a reload.
OBS_SEND_STALE = 90

------------------------------------------------------------------------------ small helpers --

-- A JSON string, quotes included. Escapes what JSON requires and \uXXXX-escapes everything outside
-- ASCII, which is what the box score's own `asciiOnly` does and for the same measured reason: an
-- observed export carried a raw U+2122 in a player name. Control characters are escaped rather than
-- dropped because the save format at the bottom of this file is newline-delimited -- a raw newline
-- inside a name would split one row into two and corrupt the log on the next reload.
local function obsStr(s)
  local str = tostring(s or "")
  local out = {}
  local i = 1
  local n = #str
  -- declared OUTSIDE the loop and assigned inside it: `local len, cp` on one line inside a loop is
  -- the rebinding trap from the header, and this is the one place in this file that would need it
  local b = 0
  local len = 0
  local cp = 0
  while i <= n do
    b = str:byte(i)
    if b == 34 then
      out[#out + 1] = '\\"'
      i = i + 1
    elseif b == 92 then
      out[#out + 1] = "\\\\"
      i = i + 1
    elseif b < 32 then
      out[#out + 1] = string.format("\\u%04X", b)
      i = i + 1
    elseif b < 128 then
      out[#out + 1] = str:sub(i, i)
      i = i + 1
    else
      if b >= 240 then
        len = 4
        cp = b - 240
      elseif b >= 224 then
        len = 3
        cp = b - 224
      elseif b >= 192 then
        len = 2
        cp = b - 192
      else
        len = 1
        cp = b
      end
      for k = 1, len - 1 do cp = cp * 64 + ((str:byte(i + k) or 0) % 64) end
      if cp < 0x10000 then
        out[#out + 1] = string.format("\\u%04X", cp)
      else
        cp = cp - 0x10000
        out[#out + 1] = string.format("\\u%04X\\u%04X",
          0xD800 + math.floor(cp / 0x400), 0xDC00 + (cp % 0x400))
      end
      i = i + len
    end
  end
  return '"' .. table.concat(out) .. '"'
end

-- One decimal, always, and never a NaN or an inf -- either would be written into the document as a
-- bare token that `json_decode` rejects, and the whole game would land in quarantine over one piece.
-- `n ~= n` is the NaN test; Lua has no isnan.
local function obsNum(v)
  local n = tonumber(v)
  if n == nil or n ~= n or n == math.huge or n == -math.huge then return "0.0" end
  return string.format("%.1f", n)
end

-- The box score's own slug(), narrowed: we only ever slug a map or a faction name here, so the
-- "&"/"and" handling it needs for deck names is not repeated. The AUTHORITATIVE spellings are the
-- ones the box score ships in `boxscore` -- it was written against the Root Database's schema and
-- holds the site's real slugs. This is a convenience for the corpus, not a second source of truth.
local function obsSlug(v)
  local s = tostring(v or ""):lower()
  s = s:gsub("[^%w]+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
  return s
end

-- A cheap 32-bit string hash, used ONLY as a salt inside game_id. Kept multiplicative-small
-- (131 * 2^32 is well inside a double's exact range) because a 32-bit FNV multiply overflows
-- double precision and starts returning the same value for different inputs.
local function obsHash(s)
  local h = 5381
  local str = tostring(s or "")
  for i = 1, #str do h = (h * 131 + str:byte(i)) % 4294967296 end
  return h
end

------------------------------------------------------------------------------------- the log --

-- One table, so a reset is one assignment and there is no way to half-reset it.
--   id       the game_id, or nil while the recorder is inert
--   started  os.time() when it armed          run    RTT_RUN_ID it armed on (the new-game signal)
--   cbase    os.clock() at arm/load           carry  elapsed game seconds from previous sessions
--   seq      monotonic row counter            ev/snap  the rows, already JSON, as strings
--   objs     guid -> static fragment, emitted once per GUID
--   seen     guid -> true for every GUID this log has ever described (see obsStatic)
--   prev     guid -> { x, z, ry, s } from the last keyframe: the delta's baseline
--   pend     the flush queue                  timer  the ONE Wait.time handle, or nil
--   sending  true between the POST and its callback   sentat  os.time() the POST left
OBS = nil

local function obsResetLog()
  -- STOP THE TIMER THIS LOG OWNS BEFORE THROWING THE LOG AWAY. Replacing OBS replaces the handle
  -- with nil, but the one-shot it names is still scheduled -- so the next `obsPush` sees a nil
  -- handle, arms a SECOND timer, and for the next 0.4 s there are two. Worse, the orphan's
  -- `obsFlush` clears `OBS.timer` on entry and so erases the live handle as well, which lets a
  -- third be armed; a table that starts several games in one session can carry a small pile of
  -- them. Each is a one-shot into an empty queue so nothing is corrupted, but "ONE `Wait.time`,
  -- and an idle table has none" is the claim this whole file rests on (MULTIPLAYER_SYNC.md
  -- non-negotiable #2) and a claim that is only usually true is not one. Measured with an
  -- instrumented Wait.time: two live timers after one new-game reset.
  if OBS ~= nil and OBS.timer ~= nil then
    pcall(function() Wait.stop(OBS.timer) end)
  end
  OBS = {
    id = nil, started = 0, run = 0, mod = nil,
    cbase = os.clock(), carry = 0,
    seq = 0, ev = {}, snap = {}, objs = {}, seen = {}, prev = {},
    pend = {}, timer = nil,
    full = true, truncated = false, sending = false, sentat = 0, status = "",
    bev = 0, bobj = 0, bsnap = 0,
  }
end

obsResetLog()

-- Game time, in seconds, one decimal. os.clock() is the only sub-second clock this interpreter has,
-- and it restarts at zero when the game reloads -- so elapsed time is carried across a reload in
-- `carry` and the live part is measured from `cbase`. The gap while the game was CLOSED is
-- deliberately not counted: this is game time, not wall time, and a log whose t jumps by nine hours
-- because somebody resumed the next morning would be worse than one that does not.
--
-- Returns 0 while the recorder is inert, so an event queued a moment before the game armed still
-- gets a legal t rather than a negative one.
local function obsNow()
  if OBS.id == nil then return 0 end
  local t = OBS.carry + (os.clock() - OBS.cbase)
  if t < 0 then return 0 end
  return t
end

-- Over the cap, the OLDEST EVENTS go and every snapshot stays -- ARCHIVE.md §4. Events are the
-- cheap, redundant half: a keyframe re-states the whole board, so losing the first minutes of drag
-- events costs ordering detail, while losing a snapshot costs truth. Dropped in one quarter-of-the-
-- log slice rather than one row at a time because `table.remove(t, 1)` in a loop is quadratic, and
-- the point of this file is to not cost the host a frame.
local function obsTrim()
  if (OBS.bev + OBS.bobj + OBS.bsnap) <= OBS_MAX_BYTES then return end
  OBS.truncated = true
  local drop = math.floor(#OBS.ev / 4)
  if drop < 1 then return end
  local keep = {}
  local bytes = 0
  for i = drop + 1, #OBS.ev do
    keep[#keep + 1] = OBS.ev[i]
    bytes = bytes + #OBS.ev[i]
  end
  OBS.ev = keep
  OBS.bev = bytes
end

-- [t, seq, kind, guid, color, x, z, ry, extra] -- ARCHIVE.md §3. Built here, as a string, once.
local function obsEvent(t, kind, guid, color, x, z, ry, extra)
  OBS.seq = OBS.seq + 1
  local row = "[" .. obsNum(t) .. "," .. OBS.seq .. "," .. obsStr(kind) .. "," .. obsStr(guid or "")
    .. "," .. obsStr(color or "") .. "," .. obsNum(x) .. "," .. obsNum(z) .. "," .. obsNum(ry)
    .. "," .. obsStr(extra or "") .. "]"
  OBS.ev[#OBS.ev + 1] = row
  OBS.bev = OBS.bev + #row
  obsTrim()
end

-- ======================================================================================= --
-- THE HIDDEN-INFORMATION LINE. Read PERCEPTION_SPEC.md §3.4 before touching this function. --
-- ======================================================================================= --
--
-- A Global script running on the host can read EVERY player's hand. A tool that does so WHILE THE
-- GAME IS STILL BEING PLAYED is a cheat tool, and the difference between a study tool and a cheat
-- tool is a whitelist of about four lines. These are those lines.
--
-- THE WHOLE HIDDEN-INFORMATION SURFACE OF THIS FILE IS TWO FUNCTIONS, and `getHandObjects` appears
-- in exactly those two -- so one grep still finds all of it, and a later edit cannot widen it
-- somewhere else without being obvious:
--   * THIS ONE, which runs DURING PLAY -- on every flush and every keyframe -- and takes hand SIZES
--     and GUIDs and nothing else whatever.
--   * `obsReveal`, which runs ONCE, inside the EXPORT press, and takes hand CONTENTS. Its own header
--     carries the maintainer's reasoning and explains why its isolation from the live paths is the
--     whole of the safety argument. Nothing in this function changed when that one was added.
--
-- ARCHIVE.md §3's "Hard rules on content" read "hand sizes may be recorded; hand contents never".
-- As of the maintainer's decision of 2026-09-12 that rule holds everywhere on this side of the
-- EXPORT press and is suspended for `obsReveal` alone; the contract is being updated to say so. It
-- is still the rule HERE, and the reason it is safe there is that it is unbreakable here.
--
-- WHAT IS PUBLIC, AND THEREFORE RECORDED: how many cards a player holds. Everyone at a Root table
-- can see that; ARCHIVE.md §3 says so in as many words ("Hand sizes may be recorded").
--
-- WHAT IS NOT, AND IS THEREFORE NEVER READ HERE: which cards they are. This function takes `#cards`
-- and the GUIDs, and NOTHING else -- no name, no art, no position, no state. The GUIDs are not data
-- that leaves the table: they are subtracted from everything the live paths emit, so a card in a
-- hand gets no static entry, no event row and no snapshot row. §3.4's rule is "never iterate
-- Player.getPlayers() for hands"; this iteration exists to ENFORCE that rule rather than to break
-- it, and it is the only way to know which objects to leave out -- `getAllObjects` returns cards
-- held in hand zones exactly like cards on the table, so without this set they would be recorded in
-- full.
--
-- Cards inside a DECK or a BAG need no such test: `getAllObjects` does not descend into containers,
-- so deck order is never visible to this file at all. Face-down cards and tiles -- Corvid plots,
-- Alliance supporters, a dominance card played face down -- are handled at `obsStatic`: they record
-- that they are face down, their GUID and their position, and never their face.
--
-- Every hand INDEX is walked for the exclusion set, because RTT parks pieces in a second hand zone
-- (`rttSnapshotHand2`) and a card sitting in one would otherwise slip through. Only hand 1 counts
-- towards the reported size: that is the Root hand.
local function obsHands()
  local guids = {}
  local sizes = {}
  pcall(function()
    for _, p in ipairs(Player.getPlayers()) do
      local col = nil
      local nhands = 1
      -- `p` is USERDATA. Read the field you want inside a pcall; never type-check it.
      pcall(function() col = p.color end)
      pcall(function() nhands = p.getHandCount() or 1 end)
      if nhands < 1 then nhands = 1 end
      if nhands > 4 then nhands = 4 end
      for h = 1, nhands do
        local cards = nil
        pcall(function() cards = p.getHandObjects(h) end)
        if cards ~= nil then
          if h == 1 and col ~= nil and col ~= "" then sizes[col] = #cards end
          for k = 1, #cards do
            local g = nil
            pcall(function() g = cards[k].getGUID() end)
            if g ~= nil then guids[g] = true end
          end
        end
      end
    end
  end)
  return guids, sizes
end

-- The static half of an object -- name, type, art tail -- emitted ONCE per GUID and then referenced
-- by GUID for the rest of the game. This is the same split live.lua measured its way to: re-sending
-- a name that cannot change is most of what made a full board encode cost a frame.
--
-- TWO REASONS TO EMIT NOTHING, both of them the whitelist above:
--   * the object is in somebody's hand -- nothing about it is ours to record;
--   * the object is FACE DOWN -- a face-down card still answers getName(), and a face-down Corvid
--     plot is a Tile whose ART IS THE SECRET. Either would put the hidden thing in the payload
--     under a different field name. It is skipped, and picked up later if it is ever turned over,
--     which is the moment it stops being hidden.
local function obsStatic(o, g, hands)
  if OBS.objs[g] ~= nil then return end
  if hands[g] then return end
  -- SEEN, EVEN WHEN NOTHING IS EMITTED. `OBS.objs` cannot answer "has this log met this GUID
  -- before" because the next line is a deliberate refusal to describe a face-down object, so the
  -- draw deck, the discard, every Corvid plot and a dominance card played face down never get an
  -- entry -- and the spawn filter in `obsFlush`, which asks exactly that question to tell a reload's
  -- respawn storm from a genuinely new piece, was reading `OBS.objs` and therefore answering "new"
  -- for every one of them. Reproduced with the harness: save, reload, respawn, and the face-down
  -- card writes a second "spawn" row while the face-up one is correctly suppressed. That is a
  -- training corpus being told pieces appeared at a moment when nothing appeared.
  --
  -- MARKED AFTER THE HAND TEST, NEVER BEFORE IT. A GUID in this set is one the recorder has already
  -- put in a snapshot row, so it is public by construction; a card in somebody's hand is not, and
  -- the rule that nothing about it is ours to keep holds here too.
  OBS.seen[g] = true
  local down = false
  pcall(function() down = (o.is_face_down == true) end)
  if down then return end
  local nm = ""
  local ty = ""
  pcall(function() nm = o.getName() or "" end)
  pcall(function() ty = tostring(o.type or "") end)
  -- The art tail identifies the unnamed cardboard -- item tokens, priority markers, plots -- the way
  -- the box score's own ITEMS table does, and live.lua only pays for getCustomObject when the
  -- nickname is empty, because that is the only case where it tells you anything.
  local art = ""
  if nm == "" then
    pcall(function()
      local co = o.getCustomObject()
      if co ~= nil then
        local u = co.image or co.face or co.diffuse or co.mesh
        if u ~= nil and u ~= "" then art = u:sub(-9, -2) end
      end
    end)
  end
  local frag = '"' .. g .. '":{"n":' .. obsStr(nm) .. ',"t":' .. obsStr(ty)
  if art ~= "" then frag = frag .. ',"a":' .. obsStr(art) end
  frag = frag .. "}"
  OBS.objs[g] = frag
  OBS.bobj = OBS.bobj + #frag
end

------------------------------------------------------------------- RTT's own setup facts --

-- The seat record, from RTT itself rather than re-derived. Three tiers, because the same fact is
-- published three ways and the cheapest reliable one wins:
--
--   1. `rttSeatRecord()` on the board -- the canonical answer, in turn order, with the run id.
--   2. the Global `RTT_SEAT_RECORD` that `rttPublishSeats` writes. THIS SCRIPT IS THE GLOBAL
--      SCRIPT, so the board's `Global.setVar("RTT_SEAT_RECORD", json)` lands as a plain global
--      variable in this very environment. It is a JSON STRING, not a table, and deliberately so:
--      "raw Lua tables do not cross object-script boundaries in TTS" is written into
--      `rttPublishSeats` itself, which is also why tier 1 can come back as nil on some builds and
--      why this tier exists at all. Read the global by its own name and never bind a local of that
--      name -- that is the shadowing trap from the header.
--   3. RTT_SEAT_POS / RTT_SEAT_COLOR, the older mirrors. No ordering and no run id, but a table
--      whose record was cleared still knows where the factions sat.
local function obsSeatRecord()
  local rec = nil
  pcall(function()
    local b = getObjectFromGUID(OBS_BOARD)
    if b == nil then return end
    local r = b.call("rttSeatRecord")
    if type(r) == "table" and type(r.seats) == "table" then rec = r end
  end)
  if rec ~= nil then return rec end
  pcall(function()
    if type(RTT_SEAT_RECORD) == "string" and RTT_SEAT_RECORD ~= "" then
      local d = JSON.decode(RTT_SEAT_RECORD)
      if type(d) == "table" and type(d.seats) == "table" then rec = d end
    end
  end)
  if rec ~= nil then return rec end
  pcall(function()
    if type(RTT_SEAT_POS) ~= "string" or RTT_SEAT_POS == "" then return end
    local pos = JSON.decode(RTT_SEAT_POS)
    if type(pos) ~= "table" then return end
    local col = nil
    pcall(function()
      if type(RTT_SEAT_COLOR) == "string" and RTT_SEAT_COLOR ~= "" then
        col = JSON.decode(RTT_SEAT_COLOR)
      end
    end)
    if type(col) ~= "table" then col = {} end
    local seats = {}
    for key, p in pairs(pos) do
      if type(p) == "table" then
        seats[#seats + 1] = { pos = { p[1], p[2] }, key = key, faction = key,
                              color = col[key] or "", owner = "" }
      end
    end
    if #seats > 0 then rec = { run = nil, seats = seats } end
  end)
  return rec
end

-- WHICH MAP IS ON THE TABLE, from the board. RTT_CURRENT_MAP survives a reload inside the board's
-- own onSave, so this is the one fact about the table that is never guessed. Ids read "Marsh Map",
-- "Winter Map"; the corpus wants "marsh", so the trailing word goes.
local function obsMapName()
  local id = ""
  pcall(function()
    local b = getObjectFromGUID(OBS_BOARD)
    if b ~= nil then
      local m = b.call("rttGetCurrentMap")
      if type(m) == "string" then id = m end
    end
  end)
  if id == "" then return "" end
  return obsSlug((id:gsub("%s+Map$", "")))
end

-- The map board itself. `rttFindMapObject` already answers this and has the audit behind it -- "the
-- map board among the objects TAGGED as map pieces: the one with the most snap points", after a
-- plain scan returned bab7e1 or a faction board and put relics on the wrong board. Ask it first; the
-- fallback below is the same rule run locally, for the case where an object reference does not cross
-- the script boundary (the same boundary that makes rttPublishSeats send JSON strings).
local function obsMapObject()
  local found = nil
  pcall(function()
    local b = getObjectFromGUID(OBS_BOARD)
    if b ~= nil then found = b.call("rttFindMapObject") end
  end)
  if found ~= nil then
    local ok = pcall(function() return found.getGUID() end)
    if ok then return found end
    found = nil
  end
  -- THE WHOLE SCAN IS INSIDE THE PCALL, not just the per-object reads. `getObjectsWithTag` is the
  -- one call in this function that is not already protected, and it runs while the document is being
  -- built -- so a throw here does not cost a map tile, it costs the entire archive, and the only
  -- trace is one console line from rttArchiveGame's outer pcall. Same shape as obsFlush's own
  -- `pcall(function() factions = #getObjectsWithTag(...) end)`.
  local best = nil
  local bestN = 0
  pcall(function()
    for _, o in ipairs(getObjectsWithTag("Map Object")) do
      local sp = nil
      pcall(function() sp = o.getSnapPoints() end)
      if sp ~= nil and #sp > bestN then
        best = o
        bestN = #sp
      end
    end
  end)
  return best
end

-- The map tile's footprint: centre, size, rotation. live.lua ships the same five numbers and says
-- why -- the tile's four corners are unmistakable on screen, which makes them the right thing to
-- calibrate an overlay against, and they are also what lets the fetcher turn a world x/z into a
-- tile-local one without knowing anything about how this table was laid out.
local function obsMapTile()
  local o = obsMapObject()
  if o == nil then return "null" end
  local b = nil
  local ry = 0
  pcall(function() b = o.getBounds() end)
  pcall(function() ry = o.getRotation().y or 0 end)
  if b == nil or b.center == nil or b.size == nil then return "null" end
  return '{"x":' .. obsNum(b.center.x) .. ',"z":' .. obsNum(b.center.z)
    .. ',"sx":' .. obsNum(b.size.x) .. ',"sz":' .. obsNum(b.size.z)
    .. ',"ry":' .. obsNum(ry) .. "}"
end

-- The clearings, read off the LIVE priority markers rather than out of RTT_MARSH_RANK and the five
-- RTT_PRIO_*MAP tables. Simpler, and it always matches what is actually on the table: the Marsh
-- alone has two boards, three clearings are excluded every game and which three depends on the
-- player count, so a table lookup would have to re-derive the flood the map build already resolved.
-- An empty list when nothing is tagged -- no map down yet, or a table this board did not lay out --
-- and never a guess.
--
-- THE ID IS AN ORDINAL, NOT THE PRINTED PRIORITY NUMBER. The number is baked into each token's ART
-- and nothing on the object reports it; the only way to recover it in Lua would be a twelve-entry
-- URL table baked into this script, which would then drift from `logic.lua`'s. It does not matter:
-- ARCHIVE.md §3 says which clearing a piece is in is decided by `root_engine/eyes/geometry.py`,
-- which matches on POSITION, so an id only has to be a stable key for a row. Sorted row-major (z
-- then x, the tolerance that keeps one row together) exactly as live.lua sorts its clearing marks,
-- so the same table produces the same numbering twice.
local function obsClearings()
  -- Wrapped whole, for the reason spelled out at obsMapObject: this runs inside the document build,
  -- and an unprotected throw here loses the game rather than the clearing list.
  local marks = {}
  pcall(function()
    for _, o in ipairs(getObjectsWithTag("RTT Priority")) do
      local p = nil
      pcall(function() p = o.getPosition() end)
      -- THE ART IS THE MARKER'S IDENTITY. Each priority marker's texture is a picture of its number,
      -- and the same twelve textures are used on every map (verified: 12 distinct arts, an identical
      -- set across Autumn, Lake, Mountain, Winter and Gorge). Nothing else on the object says which
      -- clearing it is -- they carry no name, no description and no GMNotes.
      local art = ""
      pcall(function()
        local co = o.getCustomObject()
        local u = (co ~= nil) and (co.image or co.diffuse or co.mesh) or nil
        if type(u) == "string" and u ~= "" then art = u:gsub("/$", ""):match("([^/]+)$") or "" end
      end)
      if p ~= nil then marks[#marks + 1] = { x = p.x, z = p.z, a = art:sub(1, 8) } end
    end
  end)
  -- THE ORDER IS A TIE-BREAK, NOT A MEANING. It used to be the whole answer: the markers were sorted
  -- south-to-north and numbered 1..n, and that index was shipped as the clearing id. It is not any
  -- numbering Root uses -- not the setup-card numbers the engine's maps_data/<map>_geometry.json is
  -- keyed by, and not the priority order the markers themselves show -- so every archived game
  -- carried twelve confident, meaningless ids, and fetch.py's corroboration step could only ever
  -- answer "unconfirmed". Measured against all five maps' geometry: mean residual 16-20 units,
  -- against a clearing radius of about 3.5.
  --
  -- TWO NUMBERINGS EXIST AND THEY ARE NOT THE SAME ONE. RTT's markers are CLEARING PRIORITY, the
  -- tournament tie-break order. The engine's geometry is keyed by the SETUP-CARD numbers. Neither is
  -- wrong and no fixed table converts one to the other, because they are different facts about the
  -- board. So this ships what it actually knows -- which marker, and where it physically is -- and
  -- leaves the translation to the reader, which has the map geometry to do it with.
  table.sort(marks, function(a, b)
    if math.abs(a.z - b.z) > 3 then return a.z < b.z end
    return a.x < b.x
  end)
  local out = {}
  for i, m in ipairs(marks) do
    out[#out + 1] = "[" .. i .. "," .. obsNum(m.x) .. "," .. obsNum(m.z)
      .. ",\"" .. m.a .. "\"]"
  end
  return out
end

-- The mod version, read off the board's own credit line rather than hardcoded here. `bump_version.py`
-- stamps "by MrDrouf v<major>.<minor>" into bab7e1's saved XmlUI on EVERY commit and the pre-push
-- hook refuses a hole in the sequence -- so that string is the one place in the shipped save that is
-- guaranteed current, and a constant in this file would be stale by the next commit. Reading XML is
-- a string fetch, not a UI write; nothing here touches setAttribute, which is the call that throws
-- on an id that does not exist and takes the rest of the function with it.
local function obsModVersion()
  if OBS.mod ~= nil then return OBS.mod end
  local v = ""
  pcall(function()
    local b = getObjectFromGUID(OBS_BOARD)
    if b == nil then return end
    local xml = b.UI.getXml()
    if type(xml) == "string" then v = xml:match("by MrDrouf v([%d%.]+)") or "" end
  end)
  -- ONLY A REAL ANSWER IS CACHED. The board can be absent at the moment of the first call -- it is
  -- still spawning, or somebody deleted it -- and caching "" there would make every export for the
  -- rest of the session report no version, including the ones taken long after the board arrived.
  -- A miss costs one string fetch on the next button press, which is not a price worth paying for.
  if v ~= "" then OBS.mod = v end
  return v
end

-- Who pressed the button. `host` is a field on the Player, not a method, and it is read the same
-- careful way as every other player field.
local function obsHostName()
  local who = ""
  pcall(function()
    for _, p in ipairs(Player.getPlayers()) do
      local isHost = false
      pcall(function() isHost = (p.host == true) end)
      if isHost then
        pcall(function() who = p.steam_name or "" end)
        return
      end
    end
  end)
  return who
end

------------------------------------------------------------------------- arming and resetting --

-- 16 hex, generated ONCE per game, and NOT from math.random -- RTT seeds the generator once per
-- setup (`rttSetup`), so draws taken here are not independent of the draft's and two tables that ran
-- the same setup could mint the same id. The server dedupes on game_id, so a collision would file
-- one game on top of another.
--
-- os.time gives the first eight hex and makes the id sortable; the os.clock millisecond separates
-- two games in one session; the salt is a hash of who is at this table, which is what separates two
-- different hosts starting a game in the same second.
--
-- THE THIRD TERM COUNTS ARMS, not OBS.seq. It used to hash `seed .. OBS.seq`, and OBS.seq is always
-- 0 at this moment -- obsArm is only reached while OBS.id is nil, and obsResetLog zeroes seq -- while
-- the seed is deliberately constant for one table (colours, steam ids, turn order: the same people in
-- the same seats for game two). So the whole id came down to os.time() plus the os.clock()
-- millisecond, and two arms inside one millisecond minted byte-identical ids. The server dedupes on
-- game_id, so that files game two on top of game one and the first game is gone. A counter that only
-- ever goes up cannot collide with itself.
local obsArms = 0

local function obsGameId()
  obsArms = obsArms + 1
  local seed = ""
  pcall(function()
    local parts = {}
    for _, p in ipairs(Player.getPlayers()) do
      local c = ""
      local s = ""
      pcall(function() c = p.color or "" end)
      pcall(function() s = p.steam_id or "" end)
      parts[#parts + 1] = c .. s
    end
    pcall(function() parts[#parts + 1] = table.concat(Turns.order or {}, ",") end)
    seed = table.concat(parts, "|")
  end)
  return string.format("%08x%04x%04x",
    math.floor(os.time()) % 4294967296,
    math.floor(os.clock() * 1000) % 65536,
    obsHash(seed .. "#" .. tostring(obsArms)) % 65536)
end

local function obsArm(why)
  if OBS.id ~= nil then return end
  OBS.id = obsGameId()
  OBS.started = os.time()
  OBS.cbase = os.clock()
  OBS.carry = 0
  OBS.full = true
  -- log(), never print(): print() writes to the IN-GAME CHAT that every player sees, log() to the
  -- host's system console. THE RECORDER IS SILENT AT THE TABLE, FULL STOP -- not merely until the
  -- EXPORT press. Even the result of the send is the host's business alone now; see obsReport.
  log("RTT archive: armed on " .. tostring(why) .. ", game_id " .. OBS.id)
end

-- A NEW GAME IS A NEW RUN ID, and RTT already owns that fact: `rttClearGameObjects` bumps
-- RTT_RUN_ID on every new-game teardown ("invalidates every in-flight setup callback") and
-- `rttSeatRecord` publishes it. Without this, a second game in one session would be appended to the
-- first one's log and archived under the first one's game_id -- which, because the server dedupes on
-- game_id, would overwrite the first game with a mixture of both.
--
-- A CLEARED RECORD IS NOT A NEW GAME. The teardown writes `{}` into RTT_SEAT_RECORD before the new
-- seats exist, so an absent or zero run id says "no answer yet" and must leave the log alone;
-- only a DIFFERENT run id wipes it.
-- THE RUN ID, READ THE CHEAP WAY. obsNewGameCheck runs on EVERY flush (see obsFlush), so what it
-- costs matters: obsSeatRecord() goes through `bab7e1.call("rttSeatRecord")`, which walks the seats
-- and resolves a faction key and a VP name for each -- fine once per export, wrong to pay 2.5 times
-- a second while somebody drags a stack of warriors around.
--
-- RTT_RUN_ID is a plain global on the board (`RTT_RUN_ID = 0` at logic.lua:1725, bumped in
-- rttClearGameObjects), so getVar reads it with no table built and nothing resolved. The seat record
-- stays as the fallback for the one case getVar cannot cover: an older board bake whose global is
-- not reachable that way.
local function obsRunId()
  local run = nil
  pcall(function()
    local b = getObjectFromGUID(OBS_BOARD)
    if b == nil then return end
    run = tonumber(b.getVar("RTT_RUN_ID"))
  end)
  if run ~= nil then return run end
  pcall(function()
    local rec = obsSeatRecord()
    if rec ~= nil then run = tonumber(rec.run) end
  end)
  return run
end

local function obsNewGameCheck()
  local run = obsRunId()
  if run == nil or run == 0 then return end
  if OBS.run == nil or OBS.run == 0 then
    OBS.run = run
    return
  end
  if run ~= OBS.run then
    log("RTT archive: RTT run " .. tostring(OBS.run) .. " -> " .. tostring(run) .. ", new game")
    obsResetLog()
    OBS.run = run
  end
end

------------------------------------------------------------------------------------ the flush --

local obsFlush

-- THE ONLY PLACE A TIMER IS EVER CREATED IN THIS FILE, and the invariant that makes the whole
-- recorder acceptable: ONE one-shot, armed on the empty->non-empty transition of the pending queue,
-- never re-armed when the queue drains. `OBS.timer` IS that transition test -- nil means no timer is
-- pending, so the first event after a quiet spell arms one and every event inside the 0.4 s window
-- rides along with it. AN IDLE TABLE RUNS NO TIMER AT ALL.
--
-- MULTIPLAYER_SYNC.md non-negotiable #2. If you ever find yourself wanting a repeating Wait here,
-- the answer is no: the last attempt at background work in this mod was reverted whole over exactly
-- that, and a keyframe on every turn change already gives truth without one.
local function obsArmFlush()
  if OBS.timer ~= nil then return end
  local ok = pcall(function() OBS.timer = Wait.time(function() obsFlush() end, OBS_FLUSH_DELAY) end)
  if not ok then OBS.timer = nil end
end

-- Every handler's whole job: one pcall'd getGUID, one table insert, one arm. O(1), because these
-- fire on the main thread in the middle of somebody's drag.
local function obsPush(kind, guid, color, extra)
  if not OBS_ENABLED then return end
  if guid == nil or guid == "" then return end
  -- THE ONLY THING THAT EMPTIES THIS QUEUE IS A TIMER THAT IS ALLOWED TO FAIL -- see OBS_MAX_PEND.
  -- The oldest QUARTER goes in one slice rather than one entry per push, for the same measured
  -- reason `obsTrim` slices: `table.remove(t, 1)` inside the handler that runs on every drag is
  -- quadratic, and this runs on the main thread in the middle of somebody's move. Once every 500
  -- pushes it costs one copy; the other 499 cost nothing.
  --
  -- AT LEAST ONE, AND MEASURED OFF THE QUEUE rather than off the constant. OBS_MAX_PEND is a global
  -- the maintainer can retune live like every other constant here, and a quarter of a small enough
  -- setting floors to zero -- which would leave the queue at the cap, copying itself whole on every
  -- single push and still growing. A guard that can be turned into the fault it guards against by a
  -- plausible tuning is not a guard.
  if #OBS.pend >= OBS_MAX_PEND then
    OBS.truncated = true
    local drop = math.floor(#OBS.pend / 4)
    if drop < 1 then drop = 1 end
    local keep = {}
    for i = drop + 1, #OBS.pend do keep[#keep + 1] = OBS.pend[i] end
    OBS.pend = keep
  end
  OBS.pend[#OBS.pend + 1] = { g = guid, k = kind, c = color or "", x = extra or "", t = obsNow() }
  obsArmFlush()
end

function obsFlush()
  OBS.timer = nil
  local q = OBS.pend
  OBS.pend = {}

  -- INERT UNTIL A GAME STARTS. While unarmed the flush does one thing: ask RTT whether a faction has
  -- reached the table. ARCHIVE.md §4 arms on "the first turn change or the first faction spawn,
  -- whichever comes first", and the faction half cannot be tested in the spawn handler itself -- the
  -- tag is added in the spawn's callback_function, which has not run yet when onObjectSpawn fires.
  -- Asking 0.4 s later, on a timer that already exists, costs nothing and needs no second timer.
  -- Everything queued before that moment is setup churn and is dropped with the queue.
  -- ON EVERY FLUSH, NOT ONLY WHILE INERT. This check used to sit inside the `OBS.id == nil` block
  -- below, so once a game was under way the run id was never looked at again and only onPlayerTurn
  -- or the EXPORT press could notice a new game had started. On a table playing without the TTS turn
  -- system -- which this repo's history says is common -- that meant game two's whole setup was
  -- appended to game one's log under game one's id, and the EXPORT press then wiped the lot and sent
  -- a document with one keyframe and no events. It is cheap here precisely because obsRunId is a
  -- getVar and not a seat-record walk.
  obsNewGameCheck()

  if OBS.id == nil then
    local factions = 0
    pcall(function() factions = #getObjectsWithTag("RTT Faction") end)
    if factions == 0 then return end
    obsArm("faction spawn")
  end

  local hands = obsHands()
  local requeue = nil
  for i = 1, #q do
    local e = q[i]
    local o = getObjectFromGUID(e.g)
    if o ~= nil and not hands[e.g] then
      -- A PIECE HELD BY A PLAYER IS MID-DRAG: its position is meaningless and will change again next
      -- frame. Skipped and re-queued ONCE -- `e.rq` is what keeps that from becoming a heartbeat,
      -- because an entry can buy at most one extra 0.4 s and then it is written with whatever it
      -- has. A wrong position written that way is corrected at the next keyframe, which is the whole
      -- reason the keyframes exist.
      local held = ""
      pcall(function() held = o.held_by_color or "" end)
      if held ~= "" and not e.rq then
        e.rq = true
        requeue = requeue or {}
        requeue[#requeue + 1] = e
      else
        -- A SPAWN OF A GUID THIS LOG HAS ALREADY DESCRIBED IS NOT A NEW PIECE. Loading a game
        -- re-creates every object in the save, and RTT's own blueprints carry BAKED GUIDs -- the
        -- spawn payloads keep their GUID field because stripping it throws "Object reference not set
        -- to an instance of an object" -- so a reload can hand this handler several hundred spawns
        -- for pieces that have been on the table all along. Recording those would write "these
        -- pieces appeared" into a training corpus at a moment when nothing appeared, and wrong data
        -- is worse than missing data. The contract does not settle this; the test is made out of the
        -- only memory that survives a reload, and a genuinely new piece has no entry in it. A new
        -- GAME cannot be caught by it: obsResetLog empties the set.
        --
        -- `OBS.seen`, NOT `OBS.objs`. It was the static map, and the static map is exactly the thing
        -- `obsStatic` refuses to write for a FACE-DOWN object -- so the draw deck, the discard, the
        -- Corvid plots and a face-down dominance card were "new" on every single reload and each one
        -- wrote a phantom spawn. `obsStatic` now marks `seen` for everything it is shown that is not
        -- in a hand, whether or not it emits a description, and onSave carries the set across.
        local known = (e.k == "spawn" and OBS.seen[e.g] ~= nil)
        obsStatic(o, e.g, hands)
        local p = nil
        local ry = 0
        pcall(function() p = o.getPosition() end)
        pcall(function() ry = o.getRotation().y or 0 end)
        if p ~= nil and not known then
          obsEvent(e.t, e.k, e.g, e.c, p.x, p.z, ry, e.x)
        end
      end
    end
  end

  if requeue ~= nil then
    for i = 1, #requeue do OBS.pend[#OBS.pend + 1] = requeue[i] end
    obsArmFlush()
  end
end

---------------------------------------------------------------------------------- the keyframe --

-- The whole board at a turn boundary, DELTA-ENCODED against the previous keyframe. Rows are
-- [guid, x, z, ry, stateId, qty, faceDown]; the first keyframe of a game (and the first after a
-- reload, which is the same thing as far as truth is concerned) is full.
--
-- Costed at ~5 ms on a 156-object table and a Root turn runs into minutes, so this is free where it
-- sits and nothing about it needs optimising. What it must NOT do is encode: the rows are strings,
-- built here, and `table.concat`-ed at send time.
local function obsKeyframe(turnColor)
  if OBS.id == nil then return end
  local objs = nil
  pcall(function() objs = getAllObjects() end)
  if objs == nil then return end
  local hands, sizes = obsHands()
  local rows = {}
  local seen = {}
  for i = 1, #objs do
    local o = objs[i]
    local g = nil
    pcall(function() g = o.getGUID() end)
    -- A card in a hand is skipped ENTIRELY -- not even a position. See obsHands: `getAllObjects`
    -- returns hand cards exactly like table cards, and a row per hand card would leak hand size,
    -- ordering and (through the static map) identity.
    if g ~= nil and g ~= "" and not hands[g] then
      -- SEEN, WHATEVER HAPPENS NEXT. `seen` answers "is this object still on the table", and the
      -- difference between that and "did we write a row for it" is what the `gone` list is built
      -- out of -- mark it later and a piece somebody happened to be holding at a turn change would
      -- be reported as destroyed.
      seen[g] = true
      -- A PIECE HELD BY A PLAYER IS MID-DRAG and its position means nothing: it gets no row and its
      -- baseline is left alone, so the next keyframe reports where it actually landed instead of a
      -- move from a point in the air. Same reason live.lua skips a held object, and this is the
      -- moment a host feels any cost most -- they are the one dragging.
      local held = ""
      pcall(function() held = o.held_by_color or "" end)
      local p = nil
      if held == "" then pcall(function() p = o.getPosition() end) end
      if p ~= nil then
        obsStatic(o, g, hands)
        local ry = 0
        pcall(function() ry = o.getRotation().y or 0 end)
        -- stateId: a state-switching object (the Knaves' captains, the Eyrie's leaders) is a
        -- different card in each state and only the id says which.
        local sid = -1
        pcall(function()
          local st = o.getStates()
          if st ~= nil and #st > 0 then sid = o.getStateId() or -1 end
        end)
        -- qty: a deck or a bag is one object standing for many, and how many is public.
        local qty = 1
        pcall(function()
          local n = o.getQuantity()
          if n ~= nil and n > 1 then qty = n end
        end)
        -- faceDown: 1, 0 or -1 for "the question does not apply". Asked of TILES as well as cards,
        -- because a Corvid plot is a Tile and face-down is the whole of its game state.
        local fd = -1
        local ty = ""
        pcall(function() ty = tostring(o.type or "") end)
        if ty == "Card" or ty == "Tile" then
          local down = false
          pcall(function() down = (o.is_face_down == true) end)
          fd = down and 1 or 0
        end
        -- One short string per object, compared rather than re-encoded: on a table where nothing
        -- moved between two turns this is what makes the delta empty. live.lua's trick, same reason.
        local sig = obsNum(p.x) .. "/" .. obsNum(p.z) .. "/" .. obsNum(ry) .. "/" .. sid .. "/"
          .. qty .. "/" .. fd
        local was = OBS.prev[g]
        if OBS.full or was == nil or was.s ~= sig then
          rows[#rows + 1] = "[" .. obsStr(g) .. "," .. obsNum(p.x) .. "," .. obsNum(p.z) .. ","
            .. obsNum(ry) .. "," .. sid .. "," .. qty .. "," .. fd .. "]"
        end
        -- The last known position is kept for every object, changed or not: a piece taken off the
        -- board fires onObjectDestroy, and by the time that handler runs the object cannot be asked
        -- where it was. This is where "gone" gets its coordinates.
        OBS.prev[g] = { s = sig, x = p.x, z = p.z, ry = ry }
      end
    end
  end

  local gone = {}
  for g, _ in pairs(OBS.prev) do
    if not seen[g] then
      gone[#gone + 1] = obsStr(g)
      OBS.prev[g] = nil
    end
  end

  local hs = {}
  for c, n in pairs(sizes) do hs[#hs + 1] = obsStr(c) .. ":" .. n end

  OBS.seq = OBS.seq + 1
  local round = 0
  -- THE ROUND IS THE BOX SCORE'S, not a second count. The turn panel reads it the same way and for
  -- the stated reason -- "the panel displays THIS rather than counting itself, so the two can never
  -- drift apart". Zero when there is no sheet on the table, which is honest; the turn colours in the
  -- log are enough to reconstruct rounds downstream if it comes to that.
  pcall(function()
    for _, s in ipairs(getObjectsWithTag("RTT BoxScore")) do
      local r = s.call("rttRound")
      if tonumber(r) ~= nil then
        round = math.floor(tonumber(r))
        return
      end
    end
  end)

  local snap = '{"t":' .. obsNum(obsNow()) .. ',"seq":' .. OBS.seq
    .. ',"turn":' .. obsStr(turnColor or "") .. ',"round":' .. round
    .. ',"full":' .. (OBS.full and 1 or 0)
    .. ',"rows":[' .. table.concat(rows, ",") .. "]"
  if #gone > 0 then snap = snap .. ',"gone":[' .. table.concat(gone, ",") .. "]" end
  -- Hand SIZES ride on the keyframe. ARCHIVE.md §3 permits them and gives them no row of their own,
  -- and the keyframe is where "the truth at this turn boundary" belongs; it is an optional field, so
  -- a consumer that does not want it ignores it and nothing breaks.
  if #hs > 0 then snap = snap .. ',"hands":{' .. table.concat(hs, ",") .. "}" end
  snap = snap .. "}"

  OBS.snap[#OBS.snap + 1] = snap
  OBS.bsnap = OBS.bsnap + #snap
  OBS.full = false
  obsTrim()
end

--------------------------------------------------------------------------------- the document --

local function obsSeats()
  local rec = obsSeatRecord()
  local who = {}
  pcall(function()
    for _, p in ipairs(Player.getPlayers()) do
      local c = nil
      pcall(function() c = p.color end)
      if c ~= nil and c ~= "" then
        local e = { n = "", i = "" }
        pcall(function() e.n = p.steam_name or "" end)
        pcall(function() e.i = p.steam_id or "" end)
        who[c] = e
      end
    end
  end)

  local out = {}
  if rec ~= nil then
    for i, s in ipairs(rec.seats or {}) do
      if #out < OBS_MAX_SEATS then
        local col = s.color or ""
        local id = who[col] or { n = "", i = "" }
        local pos = s.pos or {}
        out[#out + 1] = '{"seat":' .. i .. ',"color":' .. obsStr(col)
          .. ',"faction":' .. obsStr(obsSlug(s.key or s.faction or ""))
          .. ',"key":' .. obsStr(s.key or s.faction or "")
          -- `owner` is the name RTT recorded when the seat was taken; the live steam_name is what
          -- that colour answers to now. Both go: a player who changed colour mid-game is exactly the
          -- case where they disagree, and neither is wrong.
          .. ',"owner":' .. obsStr(s.owner or "")
          .. ',"steam_name":' .. obsStr(id.n) .. ',"steam_id":' .. obsStr(id.i)
          .. ',"pos":[' .. obsNum(pos[1]) .. "," .. obsNum(pos[2]) .. "]}"
      end
    end
  end

  -- NO SEAT RECORD IS STILL A TABLE OF PEOPLE. ingest.php rejects an empty `seats` outright
  -- (§5), so a movement log from a table that was set up by hand would be quarantined over a field
  -- it could have filled from the seated colours. No faction is claimed, because none is known.
  if #out == 0 then
    pcall(function()
      for _, c in ipairs(getSeatedPlayers()) do
        if #out < OBS_MAX_SEATS then
          local id = who[c] or { n = "", i = "" }
          out[#out + 1] = '{"seat":' .. (#out + 1) .. ',"color":' .. obsStr(c)
            .. ',"faction":"","key":"","owner":' .. obsStr(id.n)
            .. ',"steam_name":' .. obsStr(id.n) .. ',"steam_id":' .. obsStr(id.i)
            .. ',"pos":[0.0,0.0]}'
        end
      end
    end)
  end
  return out
end

-- ========================================================================================= --
-- THE REVEAL -- the ONE place in this file that records hidden information, and it runs only --
-- on the EXPORT press. Read the whitelist block at obsHands before touching it.               --
-- ========================================================================================= --
--
-- THE MAINTAINER, 2026-09-12: "there is no cheating problem since it's at the moment of the export".
-- He is right, and the SHAPE of this code is what makes him right -- so the shape is the whole
-- feature, and the two facts below are the ones a later edit must not quietly undo:
--
--   1. NOTHING HIDDEN IS RECORDED WHILE THE GAME IS BEING PLAYED. The three paths that run during
--      play -- `obsPush`, `obsFlush` and `obsKeyframe` -- are untouched by this section. They still
--      subtract every hand GUID from everything they emit and `obsStatic` still refuses to describe
--      a face-down object. Go and read them: the only hand call they make is `obsHands`, which takes
--      SIZES, and there is not one `getName()` on a hidden thing anywhere in them.
--   2. THIS FUNCTION HAS EXACTLY ONE CALLER: `obsArchive`, which is reached only through
--      `rttArchiveGame`, which is reached only from the box score's EXPORT and UPLOAD buttons. The
--      game is over at that moment, the maintainer has just declared it so, and the document leaves
--      the table immediately.
--
-- THAT SEPARATION IS THE ENTIRE SAFETY ARGUMENT, and it is fragile in one specific way: moving this
-- call into the flush or the keyframe -- or caching what it returns anywhere that outlives the send
-- -- turns the archive into a LIVE ADVISOR without changing a single field name. A running log that
-- contained hands could be read mid-game off the host's console, and worse, `onSave` writes the log
-- into the save file on every autosave, so it would sit on disk while the game was still being
-- played. One line in the wrong place is the whole distance between a study tool and a cheat tool.
-- If a future change wants hands during play, the answer is no.
--
-- Everything is pcall'd, and not decoratively: a player who has left between the scan and the read,
-- a colour that has no hand zone, and an object destroyed mid-loop are all reachable at a real
-- table, and each of them surfaces as "Object reference not set to an instance of an object" and
-- takes the rest of the export with it.
local function obsReveal()
  local parts = {}
  parts[#parts + 1] = '{"at":' .. string.format("%d", math.floor(os.time()))

  -- EVERY SEATED COLOUR, not just the host's. `Player[colour]` is USERDATA like every other player
  -- handle in this file -- read the field you want inside a pcall and never ask what type it is,
  -- which is the trap in the header that survives a green test suite because the stub hands back a
  -- plain table.
  --
  -- A CARD IN A HAND ANSWERS getName() EVEN WHEN IT IS FACE DOWN to everyone else: TTS answers off
  -- the object, not off what the asker is allowed to see. That is what makes this section possible
  -- at all, and it is exactly why nothing during play may call it.
  --
  -- HAND 1 ONLY, because that is the Root hand. RTT parks pieces in a second hand zone
  -- (`rttSnapshotHand2`) and what is in that one is not anybody's hand of cards.
  local hs = {}
  pcall(function()
    for _, c in ipairs(getSeatedPlayers()) do
      local p = nil
      pcall(function() p = Player[c] end)
      if p ~= nil then
        local cards = nil
        pcall(function() cards = p.getHandObjects(1) end)
        if cards ~= nil then
          local names = {}
          for k = 1, #cards do
            local nm = ""
            pcall(function() nm = cards[k].getName() or "" end)
            names[#names + 1] = obsStr(nm)
          end
          hs[#hs + 1] = obsStr(c) .. ":[" .. table.concat(names, ",") .. "]"
        end
      end
    end
  end)
  parts[#parts + 1] = ',"hands":{' .. table.concat(hs, ",") .. "}"

  -- THE FACE-DOWN OBJECTS, NOW NAMED. The keyframes already carry every one of these -- GUID,
  -- position, `faceDown: 1` -- so the ONLY fact this list adds is the name, which is precisely the
  -- fact the keyframes are forbidden to carry. `[guid, name, x, z]`, one row each, the same
  -- arrays-of-arrays shape the rest of the document uses for bulk rows.
  --
  -- CARDS IN HANDS ARE SUBTRACTED HERE TOO, even though this section is allowed to see them:
  -- `getAllObjects` returns a hand card exactly like a table card, so without the exclusion every
  -- face-down card in somebody's hand would appear twice -- once in `hands` above and once here,
  -- carrying the coordinates of a hand zone, which is not a place on the table. One fact, one place.
  --
  -- AN OBJECT WITH NO NAME IS COUNTED, NOT LISTED. Unnamed cardboard -- item tokens, priority
  -- markers, a blank -- would contribute a row that says nothing the keyframe did not already say.
  -- The count is kept because "the reveal saw forty face-down things and could name thirty-one" is
  -- worth knowing downstream, and a short list with no count is indistinguishable from a scan that
  -- half failed.
  local hidden = obsHands()
  local rows = {}
  local unnamed = 0
  pcall(function()
    local objs = getAllObjects()
    if objs == nil then return end
    for i = 1, #objs do
      local o = objs[i]
      local g = nil
      pcall(function() g = o.getGUID() end)
      if g ~= nil and g ~= "" and not hidden[g] then
        local down = false
        pcall(function() down = (o.is_face_down == true) end)
        if down then
          local nm = ""
          pcall(function() nm = o.getName() or "" end)
          if nm == "" then
            unnamed = unnamed + 1
          else
            local p = nil
            pcall(function() p = o.getPosition() end)
            -- A piece somebody is holding at the moment of the press has a meaningless position;
            -- the last keyframe's baseline is the better answer and costs nothing.
            if p == nil then p = OBS.prev[g] or { x = 0, z = 0 } end
            rows[#rows + 1] = "[" .. obsStr(g) .. "," .. obsStr(nm) .. ","
              .. obsNum(p.x) .. "," .. obsNum(p.z) .. "]"
          end
        end
      end
    end
  end)
  parts[#parts + 1] = ',"facedown":[' .. table.concat(rows, ",") .. "]"
  parts[#parts + 1] = ',"unnamed":' .. unnamed .. "}"
  return table.concat(parts)
end

local function obsDocument(box, reveal)
  local d = {}
  local function add(s) d[#d + 1] = s end

  add('{"schema":' .. obsStr(OBS_SCHEMA))
  add(',"game_id":' .. obsStr(OBS.id or ""))
  add(',"mod_version":' .. obsStr(obsModVersion()))
  add(',"started_at":' .. string.format("%d", math.floor(OBS.started or os.time())))
  add(',"sent_at":' .. string.format("%d", math.floor(os.time())))
  add(',"sent_by":' .. obsStr(obsHostName()))

  -- THE BOX SCORE GOES THROUGH VERBATIM. It is already JSON, already matches the Root Database's
  -- schema, and re-encoding it here would cost 39 ms and invent a second answer to what the game
  -- was -- the same reason rdbUpload sends exportJson()'s own string rather than a second encode.
  -- An EMPTY OBJECT rather than null when there is none: ingest.php validates that `boxscore` is an
  -- object, and a table with no box score still has a movement log worth keeping (ARCHIVE.md §4).
  add(',"boxscore":' .. ((box ~= nil and box ~= "") and box or "{}"))

  add(',"setup":{"map":' .. obsStr(obsMapName()))
  -- DECK AND LANDMARKS COME FROM THE BOX SCORE, NOT FROM HERE, and the fields stay in the document
  -- so that no consumer has to special-case their absence. The box score already answers both
  -- properly -- `deckSlug(S.meta.deck)` and `landmarksOnMap()`, which tests each landmark against
  -- the map's own bounds because the Landmarks tool spawns all nine as a supply and presence alone
  -- would report every landmark in the game as in play. RTT itself records neither: `DraftedLandmarks`
  -- is initialised and never written, `makeDeck` keeps no note of which of the three decks it built,
  -- and the pieces carry only the generic "Map Object" tag. Guessing here would produce a second,
  -- disagreeing answer inside the same document -- and one of the few rules this codebase states
  -- outright is that two records of the same game must never be able to disagree.
  add(',"deck":"","landmarks":[]')
  add(',"map_tile":' .. obsMapTile())
  add(',"clearings":[' .. table.concat(obsClearings(), ",") .. "]}")

  add(',"seats":[' .. table.concat(obsSeats(), ",") .. "]")

  local frags = {}
  for _, f in pairs(OBS.objs) do frags[#frags + 1] = f end
  add(',"objects":{' .. table.concat(frags, ",") .. "}")
  add(',"events":[' .. table.concat(OBS.ev, ",") .. "]")
  add(',"snapshots":[' .. table.concat(OBS.snap, ",") .. "]")

  -- THE REVEAL RIDES LAST, AND IS DROPPED BEFORE THE GAME IS. ARCHIVE.md §3 caps the recorder at
  -- OBS_MAX_BYTES and a game is expected near 150 KB, so this can only fire on a document that is
  -- already abnormal -- but a reveal is a few hundred short strings appended to a log that may
  -- already be sitting at the cap, and the movement log is the half the corpus is actually built out
  -- of. So it is measured against what is already in hand and left out if it does not fit, rather
  -- than pushing the document past the limit this recorder promises ingest.php it will stay inside.
  -- The 10 is the length of the `,"reveal":` that would carry it.
  --
  -- `truncated` is deliberately NOT set here. It means "rows were dropped from the log" and every
  -- consumer reads it that way; an absent "reveal" is its own signal, and the console line says why.
  if reveal ~= nil and reveal ~= "" then
    local sofar = 0
    for i = 1, #d do sofar = sofar + #d[i] end
    if (sofar + #reveal + 10) <= OBS_MAX_BYTES then
      add(',"reveal":' .. reveal)
    else
      log("RTT archive: reveal dropped, " .. (sofar + #reveal + 10)
        .. " bytes would pass OBS_MAX_BYTES; the game is sent without it.")
    end
  end

  if OBS.truncated then add(',"truncated":true') end
  add("}")
  return table.concat(d)
end

------------------------------------------------------------------------------------ the upload --

-- The server answers `{"ok":true,"message":"..."}` -- deliberately the same shape the Root Database
-- uses (ARCHIVE.md §5), so this reads exactly like the box score's rdbSay and shows the server's own
-- words rather than inventing worse ones from a status code.
local function obsSay(req)
  local msg = nil
  local ok = false
  pcall(function()
    local body = JSON.decode(req.text or "")
    if type(body) == "table" then
      ok = (body.ok == true)
      if type(body.message) == "string" and body.message ~= "" then msg = body.message end
    end
  end)
  if msg == nil then
    local code = "?"
    local why = ""
    pcall(function() code = tostring(req.response_code) end)
    -- A TRANSPORT failure -- dead host, TLS, timeout -- never reaches the PHP at all: it comes back
    -- with an empty body, response_code 0 and the reason in `error`. Reporting that as "HTTP 0"
    -- would send somebody looking at the server for a fault that is on this side of it.
    pcall(function()
      if req.is_error and req.error ~= nil and req.error ~= "" then why = " " .. tostring(req.error) end
    end)
    msg = ok and ("archived (HTTP " .. code .. ")")
      or ("archive failed (HTTP " .. code .. ")" .. why)
  end
  return ok, msg
end

-- THE TABLE IS NOT TOLD, AND THAT IS THE POINT. Two `broadcastToAll` lines stood here -- one for a
-- success, one for a failure -- under a comment arguing that they were not optional: "the host
-- pressed a button and the table is told where the data went". THE MAINTAINER'S INSTRUCTION OF
-- 2026-09-12 IS THE OPPOSITE, and it is his table. The archive says nothing in chat, ever. Five
-- other people in a tournament game do not need a line about where the host's training corpus went,
-- and the failure line was the worse of the two: it announces a broken endpoint to a room that can
-- do nothing about it, in the middle of the last scoring of the game.
--
-- THE HOST IS NOT LEFT BLIND, which is the half that makes the silence safe. `OBS.status` is still
-- set on every outcome, success and failure alike, and `rttArchiveStatus()` hands it to the box
-- score for its own status line beside INFO -- the same line that already reports the notebook write
-- and the Root Database upload. That line is the HOST'S, not the table's, so a maintainer expecting
-- "archived" can still tell a broken endpoint from a recorder that never armed.
--
-- THE log() LINES STAY for exactly the same reason: log() writes to the host's system console,
-- print() and broadcastToAll write to everyone's chat. There is still no retry -- the log is kept,
-- and pressing UPLOAD sends it again.
local function obsReport(req)
  OBS.sending = false
  local ok, msg = obsSay(req)
  OBS.status = os.date("%H:%M") .. " " .. msg
  local body = ""
  pcall(function() body = tostring(req.text or ""):sub(1, 300) end)
  log("RTT archive: ok=" .. tostring(ok) .. " body=" .. body)
end

local function obsArchive(params)
  if not OBS_ENABLED then
    -- The console, not the chat. This is off for everyone by default, and a line in every stranger's
    -- game about a feature they did not switch on is noise.
    log("RTT archive: OBS_ENABLED is false, nothing sent.")
    return
  end

  -- `params` may be nil, may not be a table, and `params.box` may be nil or "" -- all three are
  -- normal. A game with no box score still archives its movement log.
  local box = ""
  pcall(function()
    if type(params) == "table" and params.box ~= nil then box = tostring(params.box) end
  end)

  obsNewGameCheck()
  -- Pressing EXPORT on a table the recorder never saw arm (it was switched on mid-game, or the game
  -- was set up before the save was loaded) still produces a document: the box score is the valuable
  -- half and it is right there in the caller's hand.
  if OBS.id == nil then obsArm("export") end

  -- A LAST KEYFRAME, on the button press. The contract does not ask for one, but the end-of-game
  -- board is the single most valuable snapshot in the file -- it is the position the scores in the
  -- box score describe -- and it costs the 5 ms of a board read at a moment when the game is over.
  local turn = ""
  pcall(function() turn = Turns.turn_color or "" end)
  pcall(function() obsKeyframe(turn) end)

  -- THE REVEAL, BUILT HERE AND NOWHERE ELSE. This is the moment the maintainer has declared the
  -- game over, and it is the only moment in a whole session at which anything hidden is read --
  -- obsReveal's header says why that isolation is the entire safety argument. Guarded like the
  -- keyframe above it: a reveal that throws must cost the reveal, not the archive.
  local reveal = ""
  pcall(function() reveal = obsReveal() end)

  local body = obsDocument(box, reveal)
  -- 4 MB is ingest.php's hard Content-Length limit (§5); our own cap is 1 MB, so this can only fire
  -- if something has gone wrong upstream, and sending it would burn the rate limit for nothing.
  if #body > 4 * 1048576 then
    OBS.status = "payload too large (" .. #body .. " bytes), not sent"
    log("RTT archive: " .. OBS.status)
    return
  end

  -- THE ASSEMBLED ENDPOINT IS CHECKED BEFORE EVERY SEND. OBS_ENDPOINT is not a literal any more --
  -- it is built at load out of a byte table and an offset (see the constants, and the reason it is
  -- encoded at all) -- so it has a failure mode a literal never had: bytes edited without the
  -- offset, a number lost to a stray keystroke, and the string that comes out is not a URL.
  -- WebRequest.custom would then fail the way a dead host fails, with response_code 0 and an empty
  -- body, and the status line would send the maintainer to look at the server for a fault that is in
  -- this file. Refuse instead, and say which of the two it is. The assembled value is deliberately
  -- NOT logged: the console line would put the host's domain back in plain text.
  if type(OBS_ENDPOINT) ~= "string" or OBS_ENDPOINT:sub(1, 8) ~= "https://" then
    OBS.status = "the endpoint did not assemble, nothing sent"
    log("RTT archive: OBS_ENDPOINT is not an https:// URL (" .. #tostring(OBS_ENDPOINT)
      .. " chars) -- check OBS_EP_BYTES and OBS_EP_OFFSET. Nothing sent.")
    return
  end

  -- BOTH HOOKS FIRE in a normal session (EXPORT, then UPLOAD) and the server dedupes on game_id, so
  -- the second POST replaces the first -- which is wanted, because the second one carries the
  -- finished box score. This guard only stops the two colliding in flight.
  --
  -- AND IT EXPIRES. `sending` is cleared in exactly one place -- `obsReport`, the WebRequest's
  -- callback -- so a request whose callback never arrives latches it true and the archive is dead
  -- for the rest of the session, silently: every later press of EXPORT or UPLOAD finds a send "in
  -- flight" and writes one line to a console nobody is watching. Confirmed against a stubbed
  -- WebRequest that never calls back: five presses, one request. OBS_SEND_STALE is far longer than
  -- an upload takes and far shorter than the trip to the site for a Root Database token, so it
  -- cannot cut a live request off and cannot be reached by the EXPORT-then-UPLOAD sequence the
  -- contract describes -- it only unsticks a table that is already stuck.
  if OBS.sending then
    if (os.time() - (OBS.sentat or 0)) < OBS_SEND_STALE then
      log("RTT archive: a send is already in flight, skipping.")
      return
    end
    log("RTT archive: the previous send never answered, sending again.")
  end
  OBS.sending = true
  OBS.sentat = os.time()

  -- The same WebRequest.custom call the box score already uses for the Root Database, so the
  -- transport is proven in this mod. The pcall is not decoration: rdbUpload found that some TTS
  -- builds cannot send custom headers at all, and that has to read as a message rather than as a
  -- script error inside somebody's EXPORT.
  local sent = pcall(function()
    WebRequest.custom(OBS_ENDPOINT, "POST", true, body,
      { ["Content-Type"] = "application/json" }, obsReport)
  end)
  if not sent then
    OBS.sending = false
    OBS.status = "this TTS build cannot send custom headers"
    log("RTT archive: WebRequest.custom is unavailable")
    return
  end
  log("RTT archive: sending " .. #body .. " bytes, game_id " .. tostring(OBS.id))
end

-- THE ENTRY POINT, called from the box score:
--     pcall(function() Global.call("rttArchiveGame", { box = exportJson() }) end)
-- It is pcall'd at the call site AND guarded here, because the one thing it must never do is throw
-- into `uiExport`: a fault in the archive would then cost the maintainer the notebook write and the
-- Root Database upload, which are the parts of that button anyone actually depends on.
function rttArchiveGame(params)
  local ok, err = pcall(function() obsArchive(params) end)
  if not ok then
    -- A fault after WebRequest.custom was handed the body would otherwise leave `sending` latched
    -- true, and every later press of EXPORT would find a send "already in flight" and do nothing.
    OBS.sending = false
    log("RTT archive: " .. tostring(err))
    return false
  end
  return true
end

-- What the last send said, for anything that wants to show it. Read-only.
function rttArchiveStatus()
  return OBS.status or ""
end

-------------------------------------------------------------------------------- the handlers --

-- Each of these does O(1) work and returns. They fire on the main thread in the middle of somebody
-- else's drag, so the rule is one pcall'd read and an insert -- never a scan, never a decode.
--
-- WHICH KINDS ARE QUEUED AND WHICH ARE WRITTEN ON THE SPOT:
--   drop / spawn / take  are QUEUED. The piece is still settling; where it is 0.4 s later is where
--                        it actually went, and reading it now would record it mid-air.
--   stow / gone          are WRITTEN NOW. The object is about to go into a container or cease to
--                        exist, and at flush time it cannot be asked anything -- `gone` takes the
--                        position the last keyframe remembered for it.

-- THE GATE IS TESTED BEFORE THE OBJECT IS TOUCHED, not inside obsPush after it. These three read a
-- GUID off a live handle, and on a table where the recorder is OFF -- which is every table but the
-- maintainer's, because OBS_ENABLED ships false -- that is a pcall plus a call into C# for nothing.
-- It is not nothing at the moment it matters most: RTT's own setup spawns several hundred objects in
-- a burst, so onObjectSpawn fires several hundred times during the one operation in this mod anybody
-- has ever complained about the speed of. The flag is a global and is re-read here on every call, so
-- arming it mid-game from the host's Execute Lua Code box still works exactly as the header says.
function onObjectDrop(player_color, o)
  if not OBS_ENABLED then return end
  local g = nil
  pcall(function() g = o.getGUID() end)
  obsPush("drop", g, player_color, "")
end

function onObjectSpawn(o)
  if not OBS_ENABLED then return end
  local g = nil
  pcall(function() g = o.getGUID() end)
  -- No colour: a spawn is scripted by definition. ARCHIVE.md §3: "" means nobody caused it.
  obsPush("spawn", g, "", "")
end

function onObjectLeaveContainer(container, o)
  if not OBS_ENABLED then return end
  local g = nil
  local c = ""
  pcall(function() g = o.getGUID() end)
  pcall(function() c = container.getGUID() end)
  obsPush("take", g, "", c)
end

function onObjectEnterContainer(container, o)
  if not OBS_ENABLED or OBS.id == nil then return end
  local g = nil
  local c = ""
  local p = nil
  pcall(function() g = o.getGUID() end)
  pcall(function() c = container.getGUID() end)
  pcall(function() p = o.getPosition() end)
  if g == nil then return end
  if p == nil then p = OBS.prev[g] or { x = 0, z = 0 } end
  obsEvent(obsNow(), "stow", g, "", p.x, p.z, 0, c)
  OBS.prev[g] = nil
end

function onObjectDestroy(o)
  if not OBS_ENABLED or OBS.id == nil then return end
  local g = nil
  pcall(function() g = o.getGUID() end)
  if g == nil or g == "" then return end
  local was = OBS.prev[g] or { x = 0, z = 0, ry = 0 }
  obsEvent(obsNow(), "gone", g, "", was.x, was.z, was.ry, "")
  OBS.prev[g] = nil
end

function onPlayerTurn(player, previous_player)
  if not OBS_ENABLED then return end
  -- `player` is USERDATA. Read `.color` inside a pcall and never ask what type it is: the test stub
  -- hands a plain table here and TTS does not, which is precisely how that mistake survives a green
  -- test suite. `previous_player` is nil on the first turn of a game.
  local to = ""
  local from = ""
  pcall(function() to = player.color or "" end)
  pcall(function() from = previous_player.color or "" end)

  obsNewGameCheck()
  if OBS.id == nil then obsArm("turn change") end

  -- FLUSH FIRST, so every event that is already pending is written with a seq BELOW the keyframe's
  -- and the file reads in the order things happened. The timer is cancelled rather than left to fire
  -- into an empty queue -- and cancelling it here cannot lose anything, because obsFlush re-arms
  -- itself if it re-queues a held piece.
  --
  -- THE TEST IS THE QUEUE, NOT THE HANDLE. They are usually the same thing, and in the one case
  -- where they are not -- `Wait.time` threw, so `obsArmFlush` left the handle nil with entries
  -- already queued -- testing the handle skips the flush and the keyframe is written with those
  -- events still behind it, which is exactly the ordering this block exists to guarantee. Wait.stop
  -- is still only called on a handle that exists.
  if #OBS.pend > 0 or OBS.timer ~= nil then
    if OBS.timer ~= nil then
      pcall(function() Wait.stop(OBS.timer) end)
      OBS.timer = nil
    end
    pcall(function() obsFlush() end)
  end

  obsEvent(obsNow(), "turn", "", from, 0, 0, 0, to)
  pcall(function() obsKeyframe(to) end)
end

----------------------------------------------------------------------------------- persistence --

-- The log survives a reload, because a Root game outlives a TTS session more often than anyone would
-- like and a crash three hours in should not cost the record of it.
--
-- NOT JSON. The rows are already strings; `table.concat`-ing them costs 1 ms where encoding them
-- would cost 39 and this runs on every autosave, not once. The format is live.lua's: a TAG line, the
-- payload, sections joined by a ~~~ line, printable delimiters only. It is safe because obsStr
-- escapes every control character, so no row can contain the newline that separates two of them.
local OBS_SEP = "\n~~~\n"

function onSave()
  local out = ""
  pcall(function()
    if OBS.id == nil then return end
    local head = table.concat({ OBS_STATE_VER, OBS.id, math.floor(OBS.started or 0),
                                string.format("%.1f", obsNow()), OBS.seq, OBS.run or 0,
                                OBS.truncated and 1 or 0 }, "\t")
    local frags = {}
    for _, f in pairs(OBS.objs) do frags[#frags + 1] = f end
    -- ONLY THE GUIDS `OBJ` DOES NOT ALREADY CARRY. `seen` is every GUID this log has described and
    -- `objs` is the subset it could describe in words, so the difference is the face-down pieces --
    -- a handful of decks, plots and a dominance card, six bytes each. Writing the whole set instead
    -- would duplicate a hundred-odd GUIDs in every autosave for nothing.
    local extra = {}
    for g, _ in pairs(OBS.seen) do
      if OBS.objs[g] == nil then extra[#extra + 1] = g end
    end
    out = table.concat({ "HEAD\n" .. head,
                         "OBJ\n" .. table.concat(frags, "\n"),
                         "SEEN\n" .. table.concat(extra, "\n"),
                         "EV\n" .. table.concat(OBS.ev, "\n"),
                         "SNAP\n" .. table.concat(OBS.snap, "\n") }, OBS_SEP)
  end)
  return out
end

function onLoad(state)
  obsResetLog()
  pcall(function()
    if type(state) ~= "string" or state == "" then return end
    local sections = {}
    for part in (state .. OBS_SEP):gmatch("(.-)" .. OBS_SEP) do
      local tag = part:match("^(%u+)\n")
      if tag ~= nil then sections[tag] = part:sub(#tag + 2) end
    end
    if sections.HEAD == nil then return end
    local f = {}
    for v in (sections.HEAD .. "\t"):gmatch("(.-)\t") do f[#f + 1] = v end
    -- THE SAVED SHAPE IS VERSIONED AND A MISMATCH IS THROWN AWAY. onSave state outlives an edit to
    -- the script that wrote it, so a log from an older observer.lua arrives here in the older shape;
    -- reading it would either do nothing silently or die on a nil. One keyframe rebuilds everything
    -- that matters, and the alternative is a bug you cannot see.
    if tonumber(f[1]) ~= OBS_STATE_VER then
      log("RTT archive: saved log is version " .. tostring(f[1]) .. ", discarded.")
      return
    end
    OBS.id = (f[2] ~= "" and f[2] or nil)
    -- A LOG WITH NO GAME_ID IS NOT A LOG. A truncated or hand-edited HEAD leaves `id` nil while the
    -- three sections below happily load, and those orphan rows then sit in the table until the NEXT
    -- game arms and inherits them -- a previous game's events, under the new game's id, in the
    -- corpus. `onSave` would not even write them out again (it returns "" while id is nil), so the
    -- only thing they can do is contaminate. Discarded, and said out loud, for the same reason the
    -- version mismatch above is: one keyframe rebuilds everything that matters.
    if OBS.id == nil then
      log("RTT archive: saved log has no game_id, discarded.")
      obsResetLog()
      return
    end
    OBS.started = tonumber(f[3]) or os.time()
    OBS.carry = tonumber(f[4]) or 0
    OBS.cbase = os.clock()
    OBS.seq = tonumber(f[5]) or 0
    OBS.run = tonumber(f[6]) or 0
    OBS.truncated = (tonumber(f[7]) == 1)
    for line in (sections.OBJ or ""):gmatch("[^\n]+") do
      local g = line:match('^"(%w+)"')
      if g ~= nil then
        OBS.objs[g] = line
        OBS.seen[g] = true
        OBS.bobj = OBS.bobj + #line
      end
    end
    -- The face-down half of `seen`, which OBJ by definition cannot carry. Without this the spawn
    -- filter in obsFlush treats the draw deck and every plot on the table as a piece that has just
    -- appeared, on every reload -- which is the whole reason OBS_STATE_VER went to 2.
    for line in (sections.SEEN or ""):gmatch("[^\n]+") do OBS.seen[line] = true end
    for line in (sections.EV or ""):gmatch("[^\n]+") do
      OBS.ev[#OBS.ev + 1] = line
      OBS.bev = OBS.bev + #line
    end
    for line in (sections.SNAP or ""):gmatch("[^\n]+") do
      OBS.snap[#OBS.snap + 1] = line
      OBS.bsnap = OBS.bsnap + #line
    end
    -- `prev` is deliberately NOT saved. Rebuilding the delta baseline would double the size of the
    -- save state for something one keyframe reconstructs exactly -- so the next keyframe after a
    -- reload is a FULL one, which is also the right answer for a board that may have been edited
    -- while the game was closed. ARCHIVE.md §0: keyframes give truth.
    OBS.full = true
    log("RTT archive: restored game_id " .. tostring(OBS.id) .. ", " .. #OBS.ev .. " events, "
      .. #OBS.snap .. " snapshots.")
  end)
end
