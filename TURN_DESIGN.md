# Whose turn is it — a design, not a patch

The maintainer, 2026-09-07: *"a code that is robust and so the design of it is solid and not fragile
and dependent on many things that can break when there is lag"*, and *"the most buggy thing is how TTS
turn order interacts with the boxscore"*.

This is the design argument. Nothing here is implemented.

---

## 1. What is already solid, and should not be touched

Two facts are **physical**. They survive lag, reloads, colour changes and disconnects, because they
are objects on a table rather than state in a script:

- **Which factions are playing** — a row exists because a `"<faction> VP"` marker is on the table.
- **What everyone has scored** — a marker's position on the printed track.

The mod already works this way and it is the reason scores are reliable. The rule is the maintainer's
own: *"the only memory of which factions are present should be the vp score markers on the board."*

## 2. The one fragile join

**A colour is the only link between TTS's turn system and a row.** `onPlayerTurn` hands over a colour;
`rowByColor` scans `row.color`. Everything downstream rests on that one field being right.

And `row.color` is not a fact, it is a **continuous derivation** from five sources in priority order:
the pushed record, the Global mirror, a greedy nearest-hand-zone match, the live seated list, and the
faction's physical anchor. It is recomputed **every fifth poll, about every six seconds, for the whole
game**.

That is the glass castle. Not the number of sources — the fact that a derived answer is recomputed
forever, so anything that perturbs the inputs (a moved hand zone, a colour change, a late push, a
missing anchor during a spawn) can silently rewrite who is who mid-game.

## 3. Three changes, each removing a class of failure

### 3.1 Bind once, on an event. Then it is data.

Identity changes at exactly two moments: a faction is placed, and the record is pushed. Both are
events. Between them nothing about who-is-who can have changed.

- Bind on those events only.
- Once a row is bound from a **record**, never re-derive it. A poll that cannot match anything is not
  evidence that anything changed.
- Keep the geometric guess for one job only: a table RTT never set up, or the moments before the first
  push. It is a first guess, not a correction.
- A wrong binding is fixed **by hand** — the maintainer: *"mistakes can also be corrected manually."*

Removes: mid-game rebinding, rows re-tinted to colours nobody occupies, and my own run-change clearing.

### 3.2 A lock is keyed by (row, round), so writing it twice is harmless

Today a duplicate turn event is caught by a **stateful guard** — `S.turnHolder`, plus a test for
whether the pass "would invent a round". If that guard is ever wrong, a round is invented permanently.
TTS delivers duplicates and late events as a matter of course, so the guard is load-bearing.

A lock is already stored as `row.locks[round]`. Make that the whole contract:

- Recording a turn writes `row.locks[round] = score`.
- Writing the same (row, round) twice writes the same cell twice. **A duplicate is a no-op by
  construction, not by detection.**

Removes: the `turnHolder` guard, the invented round, and — see below — the START one-shot.

### 3.3 The round advances on a WRAP, not on a repeat

Today the round advances when *a row that already locked this round locks again*. That is why a
duplicate event invents a round: the same signal means both "the table came round" and "TTS repeated
itself".

The table has come round when the turn moves **backwards** through `Turns.order` — from a later seat
to an earlier one. That is observable from the two colours in the event and nothing else.

- Immune to duplicates: the same from→to gives the same answer.
- Immune to skipped seats: any backward step is a wrap, however many seats were jumped. The
  maintainer: *"detecting who's turn it is when turn is skipped should be fairly simple."*
- Immune to a row joining mid-game, and to a seat that never takes a turn — the two independent
  mechanisms behind the worst bug in this history, the round-as-division.
- In manual END TURN mode the rule is the same, read on row order.

### 3.4 What falls out: START needs no suppression

START moves the turn to seat 1. That fires a pass, and the sheet locks the outgoing row at whatever it
reads — the phantom turn at 0 VP.

With 3.2 and 3.3 that phantom writes `(seat 1, round 1) = 0`. When seat 1 really finishes, it writes
`(seat 1, round 1) = <real score>` — **the same cell, corrected**. No flag, no ordering, no race.

`RTT_SKIP_LOCK` cost five fixes in one day and was still leaving itself armed this morning. It stops
existing.

## 4. What this removes

| Gone | Why it existed |
|---|---|
| Continuous re-derivation of `row.color` | to correct a guess that should never have been re-made |
| `S.turnHolder` and the stale-pass guard | to detect duplicate events |
| `RTT_SKIP_LOCK` and its arming rules | to suppress START's phantom pass |
| Round-advance-on-repeat | conflated "came round" with "TTS repeated itself" |
| My run-change colour clearing | to undo a binding that should not have persisted |

Five mechanisms, four of them defensive. The conditions that must hold for one turn to be recorded
correctly drop from ten to four: the turn system is running, the ending colour has a row, the row's
marker is readable, and the game is not over.

## 5. What it does NOT do

- It does not touch how scores are read. That part is physical and works.
- It does not force anything: no recolouring, no reassignment, no automatic correction of a binding.
- It does not add automation. It is strictly less machinery than there is now.

## 6. Risks, honestly

- **The wrap rule assumes `Turns.order` is meaningful.** If the order is empty or the colours are not
  in it, there is no wrap to detect and the round would stall. Needs a fallback, and the fallback must
  not be the old division.
- **Overwriting a lock in the same round** is what makes START self-heal, but it also means a genuine
  correction and a duplicate look alike. That is the intended trade — the maintainer asked for manual
  correction to be possible — but it is a real change to "a lock is forever".
- **Two rounds without a wrap.** If the turn order is reduced to one seat, every pass is a wrap. Needs
  a guard: a wrap requires at least two distinct seats to have played.
- This touches the most-broken area in the project. It should go in behind the existing 26 adversarial
  cases plus new ones for each rule, and each one should fail on the build before it.

---

## 7. Manual edits: neither overwritten nor sovereign

The maintainer, 2026-09-07: *"if there are manual edits in the boxscore the fragile continuous
detection might conflict in weird instance and overwrite the edits. also do not want to consider edits
to be the law or that it means it cannot be changed again by the code logic. that's like one of the
issues of a fragile design."*

Both failure modes are real, and the sheet currently has **one of each**.

### 7.1 The score cells already do it right

`lockRow` writes `row.locks[r]` and **clears `row.edits[r]`** in the same breath. So a hand-typed cell
stands until that row genuinely finishes that round again, and then the real turn wins.

That is exactly the rule: **the last real event wins, and an edit is not permanent.** No arbitration,
no flag — the code simply does not write except when a turn ends. It is worth naming because it is the
model the rest should follow.

### 7.2 The name and variant fields are sovereign, and should not be

`row.nameAuto` is set `false` the moment a name is typed, and auto-fill then **never touches that row
again, for the life of the game**. `variantAuto` is the same. Type a name into the wrong row, or fix a
name before the record arrives, and the sheet will not correct itself afterwards even when RTT tells
it exactly who is sitting there.

That is "edits are the law" — a sticky flag that quietly grows the number of states a row can be in,
and one that nothing ever clears.

**Better:** the same rule as the cells. Auto-fill writes a name only on an EVENT — a pushed record, a
faction placed — and when it does, it writes. Between events it never touches the field, so a typed
name is safe by construction rather than by flag. If RTT later says something different, that is new
information and it wins.

### 7.3 And one flag that is already dead

`row.colorAuto` is read in three places as "a human set this deliberately" and **is never assigned
anywhere in the file**. There is no per-row colour picker; the protection has no writer. It should go
rather than be completed, because with 3.1 the colour is only written on an event anyway.

### 7.4 The rule, stated once

> The code writes a field **only when something happened** — a turn ended, a record arrived, a faction
> was placed. It never writes on a timer. A human may write any field at any time. Whoever wrote last
> is what the sheet shows, and neither side is permanently privileged.

No `*Auto` flags, no arbitration, no "who owns this cell". The fragility being removed is not the
conflict itself — it is the *state kept to remember the conflict*.

---

## 8. Built, 2026-09-07

All of it, in two passes. Two things the tests caught that the design had wrong:

- **A duplicate of a WRAPPING pass would have advanced the round twice.** The wrap needed to be
  idempotent as well as the lock. The incoming seat settles it: the table has come round only if the
  row about to play has already played this round.
- **A row appearing is not new information about the OTHER rows.** Only a pushed record or a change
  in the seated roster re-fills a name. And a player joining or swapping IS an event -- TTS does not
  announce it, but the sheet can see it, and two adversarial cases were right to insist on it.

The old-save migration also had to learn the round is EAGER now: a save whose every row has locked the
top column is sitting at the START of the next one.

`rttSuppressNextLock` survives as a NO-OP on purpose. A panel already on somebody's table keeps its
spawn-time script for ever and calls it through `obj.call`, which fails silently -- which is how a
whole release cycle of START fixes went missing once already.
