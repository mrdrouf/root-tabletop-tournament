# Missing objects on distant clients — diagnosis and work brief

**Status:** diagnosed 2026-09-10; items 1–4 BUILT the same day, shipped in v1.154. The one thing
still open is which resend primitive actually works — see "What shipped" at the end of this file.

Written as a handoff. Read this whole file before touching `gen/src/logic.lua`; several of the
obvious-looking fixes are wrong for reasons recorded here, and one of them will silently break the
prisoner gizmo if you don't know about it.

---

## The symptom

In a multiplayer game, objects the mod spawns sometimes never appear for **some** players. Reported
by the maintainer 2026-09-10. Four data points, all from him, all load-bearing:

1. It correlates with a **distant / high-latency connection** between host and client.
2. It hits **some clients and not others** in the same game.
3. **Unlock-then-lock** on the missing object makes it appear. So does **logging out and back in**
   once everything has spawned.
4. It happens in the **original Root mod and the Ultimate mod too** — so the root cause is inherited
   or engine-level, not something RTT introduced.

He also reports card-visibility oddities and players seeing each other's hands. **That is a separate
bug — see "Parked" at the bottom. Do not try to fix it as part of this.**

---

## Diagnosis

Script-spawned objects reach clients as **incremental create messages**. A distant client sometimes
drops one, and **nothing ever re-sends it**.

The rejoin fix is what settles this. A rejoin makes the client discard its state and pull a fresh
full snapshot from the host. That it works proves:

- the object **is** correct in the host's authoritative state;
- the **full-snapshot** path is reliable;
- only the **incremental apply** on the client is lossy.

Which rules out — do not go re-investigate these, they are eliminated:

- malformed blueprint JSON, or a host-side-only spawn (would survive a rejoin);
- asset/texture download failure (renders a placeholder, and a rejoin wouldn't fix it);
- GUID collisions corrupting **host** state (host state is provably fine).

### Lock state is not the cause

This was the first theory and it is **wrong**. The maintainer's own follow-up killed it: it happens
to unlocked objects too, and to "anything that spawns from a board."

Lock is a **persistence filter, not a cause**. Same drop rate either way — but an unlocked object is
dynamic, so it's in the ongoing transform sync and self-corrects the first time anyone moves it. A
locked object is static forever, so nothing ever re-broadcasts it and the hole is permanent. That's
the whole reason locked ones get reported and unlocked ones don't.

### Why the unlock/lock trick cures it

`setLock` is an authoritative **object-state write**. The host pushes it to every client, and a
client that applies it and finds it has no such object takes the full object state from that message.

So the toggle is really a **"resend this object" primitive that TTS exposes through the lock API**.
Nothing about being locked matters. Any cheap state write would do the same job — which is the basis
for item 2 below.

Two consequences that shape every fix here:

- **You cannot detect the problem.** The host has no idea what a client is missing. The repair must
  be an unconditional blind resend, never a conditional one.
- **It runs entirely on the host.** One sweep repairs every broken client at once. No client-side
  code, no per-player logic.

### Why RTT makes it worse than it needs to be

Every spawn loop fires the whole blueprint in **one frame**, unyielded. I checked all 33
`spawnObjectJSON` sites — not one staggers. Measured payloads:

| Burst (all in ONE frame) | Bytes | Objects |
|---|---|---|
| Lilypad Diaspora | **228,939** | 25 |
| Knaves of the Deepwood | 78,689 | 51 |
| The Lizard Cult | 69,733 | 30 |
| Marquise de Cat | 65,379 | 29 |
| Marsh Map | 61,515 | 32 |

A 5-player setup pushes **~565 KB of object JSON** through a handful of frames. For context, TTS
v14.2 (2026-03-01) shipped a fix for *"a networking issue where packets that were exactly a multiple
of 1 MB could break in transit"* — so TTS demonstrably moves payloads at this scale for spawns and
has had size-dependent failures in that path. v14.0 and v14.1 rewrote the networking layer
immediately before that.

**Free check before building anything: confirm every player is on TTS v14.2 or later.** Anyone still
on 14.0/14.1 is exposed to a known packet bug and no amount of mod-side work will fix them.

---

## This does not violate the Golden Rule

`WORK_QUEUE.md`'s golden rule is **"fix the BLUEPRINT, never patch at runtime — no spawn-then-move."**

That rule is about **placement**: don't fake a piece's final position by spawning it somewhere else
and sliding it. Nothing here is placement. Item 1 still spawns every piece directly at its final
baked transform — it only spreads the calls over more frames. Item 2 is a network delivery
guarantee, and **there is no blueprint-level fix for a dropped packet**; the blueprint was already
correct on the host.

Say this to the maintainer if he asks. It is a real question and it has a real answer.

---

## Work items

### 1. Stagger every spawn loop

Six `spawnObjectJSON` calls per frame instead of the whole blueprint at once.

**Sites** — all 33, but these are the ones that matter by payload:
- [`rttSpawnFaction`](gen/src/logic.lua#L4351) — the loop at 4351–4378. Biggest win.
- [`makeMap`](gen/src/logic.lua#L6387) — the loop at 6387–6411.
- [`rttSpawnPriority`](gen/src/logic.lua#L2989) and [`rttSpawnMarshNumbers`](gen/src/logic.lua#L3044).
- [`rttSpawnLandmarkAt`](gen/src/logic.lua#L5611), [`rttSpawnFlotillaKit`](gen/src/logic.lua#L5727).

**Must preserve, or you will regress things already fixed:**

- **Order.** Go in blueprint index order. The rats' mood cards are deliberately spawned *from the
  rats board's own callback* ([logic.lua:4371](gen/src/logic.lua#L4371)) so the board has a collider
  under them first. Shuffling or parallelising the order breaks that.
- **The callbacks.** `rttSpawnFaction`'s shared `cb` at [4321](gen/src/logic.lua#L4321) records
  `RTT_HOME` and calls `rttAddHomeExtras`; the comment there explains at length why that can only
  happen inside the spawn callback. Don't move it.
- **Downstream `Wait` budgets.** `rttFactionExtras` fires at 0.5 s
  ([4468](gen/src/logic.lua#L4468)) and `rttPlaceVPRetry` at 1.2 s
  ([4474](gen/src/logic.lua#L4474)). Staggering pushes the last piece's callback ~150 ms later,
  which fits — but it eats margin. **Check these, don't assume.** If it's tight, widen them rather
  than lowering the stagger.
- **`RTT_RUN_ID` / `RTT_MAP_GEN`.** A staggered loop is now in flight across frames, so a second
  click can land mid-loop. Use `rttAfterFrames` (the generation-checked wrapper at
  [logic.lua:1657](gen/src/logic.lua#L1657)), **not** bare `Wait.frames`, so an abandoned setup's
  remaining spawns simply don't run. This is exactly the class of bug that wrapper exists for.

**Speed:** 51 objects (Knaves, the worst) at 6/frame = 9 frames = **150 ms** at 60 fps. Lilypad's 25
= 5 frames = 83 ms. Reads as one pop, not a cascade — the simultaneity threshold is around 100 ms and
this is progressive appearance, not motion. **Nothing moves, so there is no jitter of any kind.**

### 2. Automated resync sweep

The actual fix. Since you can't detect what's missing, resend everything.

**Primitive: tag toggle.** The maintainer chose this over the lock toggle, and if it works it's
strictly better — zero physics, zero render change, no transform snapshot, no prisoner guard:

```lua
o.addTag(RTT_RESYNC_TAG)
-- a few frames later
o.removeTag(RTT_RESYNC_TAG)
```

> **⚠ UNVERIFIED — READ THIS.** The lock toggle is *empirically proven* (the maintainer uses it by
> hand). The tag toggle is **not**. There is a real chance TTS never replicates tag changes to
> clients at all, because only host-side Lua ever reads tags — in which case the toggle sends nothing
> and the button does nothing. **You must validate it in a real distant-connection game before
> declaring this done.**

**Build the primitive swappable**, so switching is a one-constant edit and not a rewrite:

```lua
RTT_RESYNC_MODE = "tag"   -- "tag" | "tint" | "lock"
```

Fallback ladder, best-first, if `"tag"` proves inert:

1. **`"tint"`** — nudge one `setColorTint` channel by ~1/255 and restore. Physically inert like the
   tag, and *guaranteed* replicated because it's a render property. **Trap:** the prisoner gizmo
   already owns tint — `RTT_LAID[guid].tint` at [logic.lua:7550](gen/src/logic.lua#L7550), restored
   by [`rttFreePrisoner`](gen/src/logic.lua#L7491). Snapshot and restore exactly, and skip anything
   in `RTT_LAID`.
2. **`"lock"`** — proven, but touches physics. Toggle to the *opposite* value and back
   (re-asserting a value TTS already holds is likely deduped to nothing). Note the asymmetry:
   an **unlocked** object's lock→unlock is completely inert — freezing a resting object and
   unfreezing it disturbs nothing. Only a **locked** object goes dynamic, for 2 frames ≈ 33 ms,
   falling ~0.005 units (a warrior is ~1 unit — sub-pixel). For those, snapshot position+rotation,
   restore exactly, and zero velocity before relocking, so the end state is identical to the start.

**Scope: sweep `getAllObjects()` with exclusions — NOT tags.** I checked all 33 spawn sites and
tag coverage is too inconsistent to build on: 11 have no `addTag` in their immediate callback, some
tag via a shared closure, others take an optional tag parameter callers may not pass. A tag-scoped
sweep would silently miss objects. A full sweep can't.

**Exclusions — every one of these is load-bearing:**

- **Objects held by a player** (`held_by_color ~= nil`). Never touch something in someone's hand.
- **Cards in hands** — build a GUID set from `Player[c].getHandObjects()` and skip them. (Verify
  that API exists in this TTS version before relying on it.)
- **The coordinator board `bab7e1`.** It carries the XML UI, and per
  [logic.lua:1382](gen/src/logic.lua#L1382) messing with a live XML UI has previously left TTS
  unable to hand out player colours until a server restart. Leave it alone.
- **⚠ `RTT_LAID` prisoners, or set an `RTT_RESYNCING` guard.** This one *will* bite you.
  [`rttFreeUnlockedPrisoners`](gen/src/logic.lua#L5446) ticks **every second** and, if a piece in
  `RTT_LAID` is found unlocked, calls [`rttFreePrisoner`](gen/src/logic.lua#L7491) — which stands
  the warrior back up, restores its tint, and **destructs its marker disc**. In `"lock"` mode a
  prisoner is unlocked for 33 ms; if that tick lands in the gap, the gizmo silently undoes itself.
  Guard it even in `"tag"` mode, so mode switches stay safe.
- **The map board** is fine to include — [`rttHoldMapLocked`](gen/src/logic.lua#L5453) re-locks it
  within a second anyway — but it must go through the same snapshot/restore in `"lock"` mode.

**Stagger the sweep too**, ~15 objects/frame. A 350-object table = ~24 frames = **~400 ms**.
Un-staggered it would be the exact same burst problem it exists to fix.

**When it runs:** ~2 s after each spawn burst settles, **and again at ~6 s**. The second pass matters
— it covers a message the *first pass itself* dropped. Idempotent by construction, so extra passes
are harmless.

### 3. "Resync" button on the setup board

Same sweep, manually triggered. It will still happen occasionally, and one person pressing a button
beats the whole table logging out. See `BUTTONS.md` for the layout conventions and where a new
button can go without overlapping.

Debounce it (`RTT_BUSY` / a token) so a player mashing it doesn't stack sweeps.

### 4. Smaller cleanups

- **A frame between teardown and rebuild in `makeMap`.** [Line 6342](gen/src/logic.lua#L6342) calls
  `removeMapItems()` and the loop at 6387 respawns in the *same frame* — and the blueprints share
  baked GUIDs across maps (**25–29 shared between every pair** of the seven maps; 47 duplicated
  GUIDs overall). So the host destroys GUID `79bf39` and creates a new `79bf39` in one frame. Cost
  of the fix: ~16 ms of bare table, and spawned objects already take a frame or more to appear, so
  there is no perceptible gap.
- **Strip the baked `"GUID"` from blueprint JSON at spawn** (`j:gsub('"GUID":%s*"%x+",', '', 1)`),
  so TTS assigns a fresh unique one and collisions are impossible. **Verified safe:** nothing depends
  on baked GUIDs — [4273](gen/src/logic.lua#L4273) and [4301](gen/src/logic.lua#L4301) match against
  the *JSON string* before spawn, and every runtime GUID is captured from `getGUID()` after the fact.
  `bab7e1` is a save-file object, not spawned from a blueprint.
- **Three move-while-locked sites.** Moving a locked object doesn't replicate — the codebase already
  knows this and [`rttLayHelperRow`](gen/src/logic.lua#L6079) does it correctly (unlock → move →
  lock). These don't:
  - [`shuffleMaps`](gen/src/logic.lua#L6508) at 6508–6511 moves and rotates the clearing markers,
    and **72 of the 84** marker blobs carry `Locked:true`. Clients can be looking at the
    *pre-shuffle* suit layout — a silent wrong-board desync, not just a missing piece. Most
    important of the three.
  - [logic.lua:6108](gen/src/logic.lua#L6108) — the Flotilla boat moved with a bare `setPosition`,
    unlike its sibling three lines above.
  - [logic.lua:5618](gen/src/logic.lua#L5618) — `setLock(true)` then `setScale(...)`; the scale is
    applied after the freeze. Reorder.

---

## Non-negotiables

The maintainer asked for these explicitly. Treat them as acceptance criteria:

1. **Low risk of breaking anything.** Every change is additive or a reordering. If a sweep can't
   safely touch an object, skip it — a missed object is a cosmetic bug, a freed prisoner or a
   yanked card is a real one. Wrap object calls in `pcall` like the rest of the file does.
2. **No lag.** Everything is staggered *specifically* so it never spikes a frame. Nothing may run on
   a permanent heartbeat — the sweep is a small number of one-shots after setup, plus the button.
   A 1 s resync loop would be constant network churn and repeated physics wake for no benefit.
3. **No jitter.** Item 1 moves nothing at all. Item 2 in `"tag"` or `"tint"` mode touches no physics
   whatsoever. Only the `"lock"` fallback goes dynamic, for 33 ms and ~0.005 units, with
   snapshot/restore making the end state identical. Proof the pattern is already safe in this mod:
   [`rttLayHelperRow`](gen/src/logic.lua#L6079) does unlock → move → lock on **every map build** and
   the helper row has never been reported as jittery.
4. **Too fast to notice.** Worst case is 150 ms of progressive spawn appearance and a 400 ms sweep
   of pure metadata writes. Neither is perceptible as a sequence.

---

## Testing

The test suite **cannot catch this class of bug** — `tests/tts_stub.lua` has no concept of a client,
let alone a lossy one, and per the memory note it already lies about `Player` being userdata rather
than a table. Green tests mean nothing here.

So:

1. Rebuild — `python gen/assemble.py` — then copy to `dist/` **and** run
   `python3 tools/update_saves.py`. Per the standing rule in `WORK_QUEUE.md`, a save carries its own
   copy of the script and will silently revert your fix otherwise. This has already cost a round of
   false "still broken" reports once.
2. Confirm the existing tests still pass (they won't prove the fix, but they'll catch a regression).
3. **Validate `"tag"` mode in a real game with a genuinely distant client.** Force the bug, press
   the Resync button, see whether the object appears. If it doesn't, flip `RTT_RESYNC_MODE` to
   `"tint"` and repeat. Report which mode actually worked — that answer is worth writing back into
   this file, because it settles an open question about TTS itself.

---

## Parked — do not fix as part of this

**Players seeing each other's hands / card visibility.** This is a *different* failure and none of
the above touches it. Hand zones are **player state, not objects** — the code already says so at
[logic.lua:1700](gen/src/logic.lua#L1700): *"a PERSISTENT per-colour zone, not an object, so tearing
down objects never reset it."*

The suspect is the seating loop at [logic.lua:3625–3652](gen/src/logic.lua#L3625-L3652), which per
player does `changeColor("Grey")` → `changeColor(target)` → `setHandTransform(...)`, back to back,
unverified, for up to six players. [Line 3571](gen/src/logic.lua#L3571) states the invariant that
makes it dangerous: *"In TTS the HAND — and the cards in it — belong to the COLOUR."* A client that
drops the second `changeColor` is wearing the wrong colour and therefore reading the wrong hand zone.
The Grey-parking trick is inherited from the base mod ([line 3626](gen/src/logic.lua#L3626)), which
is why the original has the same symptom.

Likely fix when it's picked up: a verify-and-reapply pass after the seating settles, re-reading each
seated player's `color` and `getHandTransform(1)` against `RTT_SEATS`. Note that
[logic.lua:4884](gen/src/logic.lua#L4884) already records that `setHandTransform` is not instant, so
it needs a settle delay, not an immediate check.

**The maintainer deferred this on 2026-09-10 ("forget the hand thing at the moment"). Don't
freelance it.**

---

## What went wrong (2026-09-10) — read this before re-building any of it

Items 1–4 shipped in v1.154 with a Resync button. The maintainer's game broke twice, and the whole
change set was reverted in v1.156. The board script now matches v1.153 character for character.

### Round one: the GUID strip

Item 4 said to strip the baked `"GUID"` from blueprint JSON at spawn "verified safe". It is not.

> "after doing the 3 player drafts clicking on a faction did nothing"
> `[Faction Selection - bab7e1] Lua Error: Object reference not set to an instance of an object.`

That is TTS's own null. `rttCoordFaction` **destructs the selector board before it spawns the
faction**, so a `spawnObjectJSON` that throws on the first piece takes the board away and puts nothing
back — a click that does nothing.

What had been checked was true and beside the point: the JSON still parses without the field, the
GUID is the first key in all 701 blobs, nothing looks a spawned object up by a baked GUID. **None of
it asks TTS**, and `tests/tts_stub.lua` never parses the JSON at all, so the suite stayed green.

### Round two: it was not only the GUID strip

v1.155 turned the strip off and left the staggering and the sweep in. It was still broken, and worse:

> "now even 4 player is broken and 3 player still broken, it s like only sometimes the button works
> and only can spawn 1 faction"

**Intermittent, and a partial spawn.** That is a different failure from round one, and it points at
items 1 and 2 rather than item 4. The two candidates, neither eliminated:

- **The stagger made `rttSpawnFaction` asynchronous.** It used to finish inside one frame and
  everything downstream could assume the pieces existed. It now returns while ~20 of them are still
  queued, and its continuation goes through `rttAfterFrames`, which silently drops the remainder if
  `RTT_RUN_ID` moves. A faction that spawns its first six pieces and stops is exactly "only can spawn
  1 faction". **Anything that converts a synchronous spawn to an asynchronous one has to be checked
  against every caller that reads the result, not just against the loop it replaces.**
- **The sweep is itself a burst.** It was built to repair dropped messages and it writes state to
  every object on the table — a few hundred — twice, after every spawn, and again on the button. On a
  connection already dropping messages that is more traffic, not less, in the same window as a draft
  where every click has to round-trip. "Only sometimes the button works" is what a flooded client
  looks like.

### What to do differently

1. **One item per build, and the maintainer confirms each in TTS before the next.** All four went out
   together, so when it broke there were four suspects and no way to bisect from here.
2. **Anything TTS can see that the harness cannot must ship behind a constant, defaulted off**, and be
   proven on ONE spawn in a real game. Payload shape, a new API property, a runtime-only field:
   green tests mean nothing for that class of change.
3. **Staggering is not free.** It changes the contract of every function it touches from "the pieces
   exist when this returns" to "they will". Audit every caller first; `rttPlaceFaction`,
   `rttCoordFaction`, `shuffleMaps`, `rttLockRuins` and `rttPlaceVP` all read what the loop spawned.
4. **Measure the sweep's own cost before shipping it.** A repair that sends several hundred object
   writes per spawn may be worse than the drop it repairs. Scope it to what was actually just spawned
   rather than to `getAllObjects()`, or make it manual-only.

The parts that were NOT implicated and are safe to re-land on their own: the frame between a map's
teardown and its rebuild, and the four move-while-locked sites (`shuffleMaps`' ruins and clearing
markers, the Flotilla boat, the landmark card's scale-before-lock). Those change no contract and add
no traffic.
