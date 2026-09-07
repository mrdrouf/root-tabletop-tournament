# Who is who, and whose turn it is — audit before the refactor

Working document for the seating/turn refactor. Findings only; nothing here is implemented yet.
The goal, in the maintainer's words: "one record that answers which seat, which colour, which person,
which faction" plus whose turn it is — "and you already have the logic in the boxscore."

The sharper target, his words 2026-09-07: **"the major issue is how unstable boxscore is and how it
does not work resiliently with the TTS turn order ... it was broken in many versions."**

---

## 1. The structural answer

**A colour is the only join between TTS's turn system and a box-score row.**

`onPlayerTurn` receives a colour. `rowByColor` (boxscore.lua:675) is a linear scan over `row.color`.
If a row's colour is wrong, absent, or claimed by two rows, the turn is attributed to the wrong row or
to none — and a lock is permanent, because it is what gets exported.

So every identity bug in RTT becomes a scoring bug on the sheet. That is why the two complaints are
one complaint.

And `row.color` is decided by a **five-way** contest (`refreshSeats`, boxscore.lua:1017-1092):

1. the pushed RTT record (`S.rttSeats`), keyed by seat `key`
2. failing that, the Global mirror `RTT_SEAT_COLOR`
3. failing that, a greedy nearest-hand-zone geometric match
4. failing that, `seatedHands()` — live seated players only
5. and the physical faction anchor (`facAnchor`) when the row has no position

Each fallback is individually reasonable. Together they mean the sheet can be confidently wrong.

---

## 2. Concrete defects found (box score side)

- **No epoch on the record.** `run` is published by RTT (logic.lua:3180) and never read. A record
  restored from a save is indistinguishable from a live one.
- **`S.turnHolder` survives a reload.** The duplicate-pass guard (boxscore.lua:2133) is therefore armed
  with a pre-reload colour on the first turn after loading.
- **`S.turnStart` survives as an absolute `os.time`.** The first turn to end after a reload writes a
  `lastTurn` measured from whenever the game was saved. `mmss` does not cap minutes.
- **An empty string erases.** `rttFieldMap` (boxscore.lua:903) drops `""`, and if no seat carries a
  field it returns nil for the WHOLE map — dropping every row at once to the geometric guess. One seat
  publishing `color = ""` is enough.
- **A 12-entry name bridge.** RTT publishes long ids ("Marquise de Cat"); the sheet's rows are short
  ("Marquise"). `RTT_FACTION_ID` (boxscore.lua:1006) bridges exactly 12. A 13th faction, or a rename on
  either side, silently loses that seat's colour, owner and position.
- **Duplicate colours resolve by row order**, first row wins (boxscore.lua:1056); the loser drops to
  geometry with no warning.
- **`row.colorAuto` has no writer.** Read at 1078 and 1086 as "a human set this deliberately"; nothing
  in the file ever sets it false.
- **`RTT_VP_SHORT` is referenced at boxscore.lua:1753 but defined only in RTT's logic.lua** — in the
  sheet's scope it is always nil.
- **`coalitionCandidates` (boxscore.lua:564) does not `baseFac`**, so "Vagabond 2" is offered as a
  coalition partner to "Vagabond".

## 3. What the box score deliberately does NOT trust, and why

Worth preserving — each one is a scar from a real bug:

- **Rows come from VP markers, never from the record.** "the only memory of which factions are present
  should be the vp score markers on the board."
- **Row order is re-derived geometrically**, `atan2(-z, x)`, discarding RTT's turn order.
- **First seat is pinned by geometry, not colour**: "Geometry is authoritative here; colour is not."
- **`lockRow` re-reads the marker** rather than trusting the polled score: "a lock is forever."
- **`onPlayerTurn` distrusts TTS itself** — a duplicate pass "does not merely lock twice, it INVENTS A
  ROUND."
- **`rttHasData` keys on locks/edits/dominance**, not on `S.turns` and not on the live score.

## 4. The round, done right

`roundForRow` / `liveRound` (boxscore.lua:202-226) derive the round per row from `row.lastRound`. The
old `floor(S.turns / #S.rows) + 1` is recorded as the cause of two reported bugs. This is the model the
rest of the system should follow: derive, do not count.

---

## 5. What the tests actually guarantee — and the holes

122 cases across three suites (76 RTT, 24 box-score turn-tracking, 21 box-score adversarial).
Roughly half assert something about seats, colours, players, factions or turn order. Those assertions
are the contract the refactor may not break; they are written out in full in the audit transcript.

### 5.1 The blocker: neither stub has a turn engine

`Turns` is a plain recording table in both harnesses. **Nothing ever advances `turn_color`, and nothing
ever fires a turn event.** Every RTT-side test that mentions turn order is asserting on a value the
test itself wrote.

So the exact thing the maintainer reports breaking — "it does not work resiliently with the TTS turn
order" — currently **cannot be tested at all on the RTT side**. The box score's suites drive
`onPlayerTurn` by hand, which is closer, but they too never run a real cycle.

A turn engine in the stub is therefore the first piece of work, not a detail of it. Without it the
adversarial battery can only re-assert what the tests already assume.

### 5.2 The divergence that will bite this refactor specifically

`test_setup_paths.py:2232` — a real userdata Player exists as a fixture and is used by **exactly one
of 76 cases**. The other 75 drive clicks with a Lua table, which TTS never produces.

> "The stub's own Player entries are Lua tables, so every click test in this file has been exercising
> a kind of player that TTS never produces -- and that hid a bug for three rounds of 'fixed'."

Any `type(x) == "table"` test introduced by the refactor passes the whole suite and fails at the table.

### 5.3 The box-score stub is where the RTT stub was before it was fixed

- `changeColor` is a **no-op** — the precise thing the RTT stub's own comment says made "every
  assertion about who sits where an assertion about nothing".
- `Player[c].seated` is **true for every colour**, occupied or not. The current code only reads
  `seated` off `getPlayers()`, so it survives; a refactor that reads `Player[c].seated` passes the
  suite and is wrong in TTS.
- The two box-score suites **disagree about where the seats are**: `test_turn_tracking` uses a fixed
  10-entry hand table, `test_adversarial` overrides `Player` wholesale with the real RTT coordinates.

### 5.4 Weak tests — would still pass if the behaviour were inverted

- **`t_the_gizmo_follows_the_faction_you_last_picked`** (mine, today): writes `RTT_LAST_PICK` directly
  and never calls `rttPlaceFaction`, so nothing verifies that picking a faction actually records it.
  The docstring also claims reload survival and numpad 0 behaviour that the test never exercises.
- **`t_turn_order_is_clockwise_from_bottom_right`**: the geometry is a Python literal inside the test.
  `RTT_POS` and `RTT_LAYOUT` appear in no assertion in the file. A refactor that made the mod's seat
  geometry non-clockwise would pass this unchanged.
- **`t_published_colour_matches_the_seated_player`**: despite its name, it compares the published
  mirror against the mod's own seat record. Nothing ties a seat to a human. The human-to-colour link
  is pinned only on the ranked path, by one other test.
- **`t_boards_spawn`**: docstring says "at the seat coordinates"; the coordinates are parsed and
  discarded. Passes with every board at the origin.
- **A spectator's turn** (box score): only the turn counter is checked, not the locks. A spectator's
  turn writing a lock somewhere would pass.
- **The five parameterised box-score cases** check locks as a SUM, so "one lock per faction" and "four
  locks on one row" are indistinguishable.
- **~8 assertions test source text**, not behaviour — they break on a rename and pass if the behaviour
  returns under another name.

### 5.5 The gap that matters most for the refactor

**No test asserts that `RTT_SEATS` itself is cleared by a new game or by Clear All.** Both tests check
only that the published mirror becomes `"{}"`. A refactor that centralises everything into one record
and forgets to clear the array passes both.

---

## 6. The history: what actually broke, and how often

Mined from 592 commits across both repos, the changelog, the archive and the postmortem comments.

### 6.1 LIVE DEFECT — START eats player 1's first turn

Confirmed by driving the real `boxscore.lua` through the harness, not by reading it:

    CONTROL (no arming):  Marquise locks ['1'] -> ['1','1']   # a pass locks
    ARMED, no pass:       Marquise locks ['1'] -> ['1']       # SWALLOWED
    ARMED, reset, pass:   locks []                            # still swallowed

The panel arms `rttSuppressNextLock` **unconditionally**, then assigns `Turns.turn_color` **only if it
differs**. When START is pressed and it is already seat 1's turn — the ordinary case, because
`rttEnableTurns` has just set `turn_color` to seat 1 — no pass fires, so nothing consumes the flag.
It is cleared in exactly one place, inside `onPlayerTurn`, and `rttResetAndStart` does not clear it.

**Player 1's first turn of the game is silently never recorded.** That is the "missing round" shape the
maintainer keeps reporting. The existing test covers only "a refused pass consumes it", never "no pass
happens at all".

### 6.2 What has been fixed more than once

| Failure | Attempts |
|---|---|
| START / turn-pointer interaction | **5 in one day**; two mutually-redundant fixes still coexist |
| Fixes never reaching the table (rebake / install) | **5**; twice the same fix was reported broken twice |
| "Is there a game here?" (`rttHasData`) | **4**, including one retracted claim about a test |
| Row pruning | **3** |
| Which colour a row belongs to | **3+** |
| `rttEnableTurns` semantics | **4** |
| The first-seat pin | **3** |
| The round counter | **3** |
| A local declared after its first use (crash) | **3-4** |
| Forcing player colours | **2, in opposite directions, 24h apart** |
| Manual vs ranked path divergence | **5, self-counted in a commit message** |

### 6.3 Assumptions about the TTS turn system that had to be walked back

Nineteen in total. The expensive ones:

- **Assigning `turn_color` to the colour it already holds still fires `onPlayerTurn`.** The single
  costliest wrong assumption in the file.
- `turn_color` does nothing at all while `Turns.enable` is false — the hotseat case.
- Reading `turn_color` back does not return what you just wrote.
- `onPlayerTurn` is an event that "arrives when it likes", can arrive twice, and can arrive late.
- `Turns.enable` ships **false**, and a player standing up switches it off again.
- TTS **bursts through colours** when the turn system is toggled.
- `getHandTransform()` returns a position for all ten colours, seated or not.
- Globals are wiped on load; raw Lua tables do not cross object-script boundaries; a `pcall`'d
  `obj.call` on a missing function fails **silently**; a spawned object keeps its spawn-time script
  for ever.

### 6.4 Process failures that matter as much as the code

- **The panel's own script has never been executed by any test**, by admission. Every START fix rests
  on unexecuted code.
- **Turn-system changes have shipped inside commits that describe only a colour change** — one such
  commit also carried a deliberately mutated `roundForRow` into the bake, which had to be undone the
  next day. An audit that trusts commit subjects misses them.
- Five separate occasions where a correct fix never reached the table at all.

### 6.5 Still open

- The `followTurns()` pin still carries the construct that once put the pointer on seat 2.
- Exported `turn_order` is the row index; it is correct only because two different pieces of geometry
  happen to agree today.
- Six-seat row order versus seat numbering is unverified in either direction.
- Two adversarial fixes from 2026-09-07 have never been seen at the table.

---

## 7. The RTT side: seventeen places the truth is kept

`RTT_SEATS`, `RTT_BOARD_SEAT`, `RTT_CLONES`, `RTT_ORDER`, `RTT_LAST_PICK`, `RTT_TURN_SEATS`, `RTT_DN`,
four Globals, the box score's own `S.rttSeats` + `S.rows[]`, TTS `Turns.*`, TTS hand-1 transforms,
`RTT_HAND2_PARKED`, TTS `Player[]`, `RTT_LAID[].who`, five `_G` leftovers, and `RTT_HOME`.

Sixteen documented pairs can disagree. The ones that are live defects today:

### 7.1 Two vagabonds collapse into one after a reload — CONFIRMED IN CODE
`onSave` (logic.lua:12) persists `pos, color, faction, owner, hand` — **not `key`, not `vagN`**.
On reload `rttSeatRecord` recomputes `key = rttFactionKey(faction)`, which returns `"Vagabond"` for
*every* vagabond. Both seats then publish under one key, the last write wins, and the second vagabond
loses its colour, owner and position — while its VP marker on the table is still "Vagabond 2 VP".

### 7.2 A hole in the seat array truncates every read
`onSave` skips seats whose `pos` is nil, producing non-contiguous `i`; `onLoad` restores at
`RTT_SEATS[e.i]`. **Eight later `ipairs(RTT_SEATS)` loops stop at the first hole** — turn order, the
published record, the free-colour search, the vagabond ordinal, `rttSeatFaction`.

### 7.3 `RTT_TURN_SEATS` survives a new game
`rttResetRunState` clears `RTT_SEATS` but not `RTT_TURN_SEATS`. During the ranked draft's ~10s of
animation, one colour change calls `rttEnableTurns(5)` against an EMPTY seat list, so the order falls
back to the static `Red…Green` literal and `rttPublishSeats` publishes `{}` — which the box score
caches.

### 7.4 The dead literal from the very first turn bug is still there
`onLoad` line 280 assigns `Turns.order = {"Red",...,"Brown"}` unconditionally on every load, AFTER the
seat record has been restored and published. The commit that first switched the turn system on
identified this exact line as the one that never worked; it was never removed.

### 7.5 Two defects in what shipped today
- **`RTT_LAST_PICK` is keyed by colour and never invalidated.** It survives a reload and a new game's
  teardown is its only reset. Alice picks the Marquise as Red and leaves; Bob joins and takes Red;
  Bob's numpad 1 hands him Marquise warriors.
- **It is overwritten even when the seat did NOT take that colour.** One person setting out several
  boards — the documented case the colour-clash guard exists for — leaves the gizmo pointing at the
  last faction they clicked while every other record says otherwise.

### 7.6 `seat.owner` is written once and never updated
Nothing refreshes it on a disconnect or a colour change, and the box score **prefers** it over the
live seated name. A game finished by Bob in Alice's seat is credited to Alice.

### 7.7 `rttFreeSeatColor` can hand out a colour the sheet cannot match
It picks from the ten TTS colours; the box score's own colour pass and `RTT_SETUP_COLORS` use six. An
unclaimed seat can take Blue, Purple, Pink or White and never bind to a row.

---

## 8. The design

**One record, one writer per fact, everything else reads.**

    RTT_SEATS[n] = {          -- n is the seat NUMBER, contiguous, 1..seats
      pos    = {x, z},        -- where the board stands: the seat's identity
      hand   = {pos, rot},    -- the hand transform that belongs to this seat
      color  = "Red",         -- the colour this seat plays
      faction= "Ranger",      -- what was picked (a vagabond's CHARACTER)
      key    = "Vagabond 2",  -- what everything downstream names it -- PERSISTED, never recomputed
      vagN   = 2,             -- PERSISTED
      owner  = "steam name",  -- refreshed, not written once
      board  = <obj|nil>,     -- live only
    }

Rules:

1. **Every fact has exactly one writer.** No caller assigns `seat.color` directly.
2. **`key` and `vagN` persist.** They are never recomputed from `faction`.
3. **The array is contiguous.** One helper compacts it; no consumer may meet a hole.
4. **The published record is a pure projection** of the array plus an epoch (`run`), and the box score
   **checks the epoch** — today it ignores it, so a record restored from an old save is accepted as live.
5. **Turn order is derived from the record only.** The static colour list stops being a fallback: with
   no seats there is no order, rather than a fabricated one.
6. **The record carries the sheet's short row name**, killing the hand-maintained 12-entry bridge.
7. **`owner` is refreshed** from the live occupant of the seat's colour, every publish.
8. **The gizmo asks the record**, not a side table. `RTT_LAST_PICK` disappears into `seat.faction`.

## 9. Order of work

1. **The live defects above**, one commit each, each with a test that fails on today's build.
2. **A turn engine in the stub** — without it none of this is testable (§5.1).
3. **The refactor**, against the invariants in §5 as the contract.
4. **The adversarial battery**, targeting §6.2's recurrence list and §6.3's walked-back assumptions.

---

## 10. Findings that did NOT hold up

Every item was re-checked against the code before being fixed. Three did not survive that:

- **`rttFreeSeatColor` handing out a colour the sheet cannot match.** `RTT_ALL_COLORS` already begins
  with exactly the six seating colours, in the same order, so walking all ten reached them first
  anyway. The change made the rule explicit and altered no behaviour; the test is a guard, not proof
  of a fix.
- **`RTT_DN` never cleared.** It is never cleared, but both entry points write it before anything
  reads it: `rttSetup` sets it synchronously and the box score does not spawn until several frames
  later, and the manual path sets it in `rttNewGame`. No stale value can be read. Left alone.
- **Six-seat row order unverified.** Six seats cannot occur: five players draft SIX cards
  (`RTT_DRAFT_N = 6`) and the seat count is `RTT_DN - 1`, so five is the maximum, and the manual path
  asks for 4 or 5. `RTT_LAYOUT[6]` is unreachable. Pinned with a trip-wire test instead: it fails the
  moment six seats become reachable, and says why the layout must be reordered first.

Recording these matters as much as the fixes. An audit finding is a hypothesis, and three of nineteen
were wrong.
