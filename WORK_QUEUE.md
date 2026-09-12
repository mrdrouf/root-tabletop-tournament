# RTT Work Queue

Single source of truth for outstanding tasks. Nothing is "done" until it's built, committed, and
the maintainer has confirmed it in TTS. Keep this file live: add every new request here the moment it lands,
tick items only when committed, and re-open anything the maintainer reports still broken.

## Standing rule: work on MAIN
From 2026-09-04 the working branch is **main**, not rtt-live ("we should be working in the main
branch"). main and rtt-live were fast-forwarded to the same commit; rtt-live is left pointing there so
any sync script still aimed at it keeps working, but it is no longer where work lands. Build, commit and
push on main; the public README download link points at main, so a build is only really shipped once
main has it.

## Standing rule: update the maintainer's SAVES, not just the build

A TTS save carries a COPY of every object's script. Dropping a fresh build into the Saves folder only
helps a game started from scratch: open a saved game, or let TTS autosave and resume, and the old
script comes back with it. On 2026-09-05 this bit for real -- 27 of 28 saves were stale, and he spent
a round reporting a box-score fix as broken while his save was silently reverting it.

So after every build, run BOTH:

    cp dist/Root_Tabletop_Tournament.json ~/Library/Tabletop\ Simulator/Saves/
    python3 tools/update_saves.py

update_saves.py rewrites only three fields on two objects (board bab7e1's LuaScript/XmlUI/
CustomUIAssets, and any "Root Box Score" LuaScript), so table state and every LuaScriptState -- the
gizmo config, the box score's recorded game -- survive untouched. Originals are backed up outside the
Saves folder, last two sets kept.

SCOPE: `Root_Tabletop_Tournament.json` ONLY. The maintainer said so plainly after a first pass
rewrote 26 files and a second still swept the autosaves. His saves are his. `--all` exists for a
sweep he explicitly asks for; it is never the default. NOTE the consequence, which is his to manage,
not something to route around: resuming from an autosave still restores the script stored in it.

## Note for future sessions: the `m###` labels are HISTORY, not files
The `mods/` pipeline was REAL -- `mods/m###_*.py` + `build.py` over a `base/` mod. It is not in the
current history because the repo was RE-ROOTED onto the generator; the old chain survives only as
orphaned objects, now preserved as the tag **`legacy/mods-history`** (177 commits, tip 2026-08-30).
Read an old module with `git show legacy/mods-history:mods/m300_duchy_warriors.py`. That tag (and every
`legacy/*` / `discarded/*` tag) is **LOCAL-ONLY**: removed from GitHub on 2026-09-05 because the old
history carried the maintainer's real identity; rewritten locally so every commit is MrDrouf. Never
push tags -- `.git/hooks/pre-push` blocks them and any commit carrying the real name. The build is three
files -- `gen/src/save.json` (scene/blueprint, with an `@@BOARD_LUA@@` placeholder), `gen/src/content.lua`
(Root's object DATA) and `gen/src/logic.lua` (OUR code, the file you edit); `gen/assemble.py` injects
content+logic into the placeholder. Every `m###` reference in this file, CHANGELOG.md, TODO.md and
README.md names a change that is already BAKED INTO those three files -- do not go looking for a module.

Editing `gen/src/save.json`: it is CRLF. Read/write it in BINARY mode -- a text-mode round-trip in
Python rewrites all 2381 line endings and turns a one-character fix into a 4700-line diff.

## Golden rule (the maintainer, repeated + hardened)
**Fix the BLUEPRINT, never patch at runtime.** No dirty tricks — no spawn-then-move, no
spawn-below-the-table-then-reveal, no runtime tuck. Modify the faction's data so every piece
starts in its final container/position:
  - seat-relative pieces (warriors/buildings by the board): bake move_to (m290/m300/m560/m570).
  - "extra" pieces that belong in supply: MOVE them into the bag's ContainedObjects in the data
    (framework.stow_loose_in_bag) — they spawn inside the bag.
  - map-relative pieces (cats on clearings, The Pond): take from the supply bag / spawn the object
    JSON directly AT the final world spot — never a seat-local default first.

## STRUCTURAL — the pattern behind most of today's bugs (2026-09-04)

**Fault 2 struck again on 2026-09-04, twice in one evening.** Everything built for the box score's
seat colours and the TTS turn order lived in `rttSeatPlayers`, which ONLY the ranked draft calls -- so
on the manual 4-board path (`RTT Manual Selector`) there were no seat colours and no turn order at all,
and the maintainer, who tests on that path, saw uncoloured rows and TTS's own ten-colour default order.
Fixed by extracting `rttEnableTurns()` and calling it from both paths, and by dropping the `isDraft`
gate on the seat-colour publish. That is now the FOURTH thing these two paths have disagreed about
(teardown tags, run-state reset, busy release, hand-1 ordering) plus this one. Until they share a single
setup function, assume any new setup behaviour is missing from one of them.

The maintainer, after the supporters-hand saga: "this type of bug should give you some insight about
phenomena and problems in the structure of the code." He is right. Nearly every bug fixed today is one
of four structural faults, not an isolated mistake. Fixing these is worth more than fixing instances.

1. **Placement derived from MUTABLE GLOBAL STATE instead of from arguments.**
   `spawnSupportersHand(color)` takes only a colour and reads `Player[color].getHandTransform(1)`. So
   its result depends on WHEN it is called. makeFaction called it before moving hand 1, so the
   supporters hand was built from the player's PREVIOUS seat; the draft path happened to move hand 1
   much earlier, so it worked there. The same shape caused the box score binding rows by hand-zone
   geometry, and my own pin resolving Turns.order[1] through that geometry.
   FIX SHAPE: pass the seat position/rotation in explicitly. A function that is given where the seat is
   cannot be called "too early".

2. **TWO parallel setup paths that must stay in sync and don't share code** (rttSetup vs
   setupFactionBoards). Today alone they diverged on: the teardown tag list, the run-state reset
   (RTT_FAC_TAKEN etc.), the busy-flag release, and the hand-1 ordering above. Each was found separately.
   FIX SHAPE: one `rttNewGame()` and one `rttSpawnFactionAt()` that both paths call.

3. **Non-object state is invisible to teardown.** Teardown destroys objects by tag, but a game also
   leaves: hand-zone transforms (hand 2 stayed wherever the last Alliance put it), Globals
   (RTT_SEAT_POS / RTT_SEAT_COLOR), and module tables (RTT_FAC_TAKEN, RTT_VP_PENDING, RTT_ALLY_SUP_DONE,
   RTT_CAP_SPAWNED). Every one of these had to be remembered by hand, and each forgotten one was a bug.
   FIX SHAPE: a single registry of "things a new game resets", objects and state alike.

4. **Long async chains with no generation token.** ~6-10s of Wait.time/Wait.frames per setup, whose
   callbacks can fire against a later run's state. The busy guard stops a second run STARTING, but a
   chain already in flight is still unguarded.
   FIX SHAPE: rttSetup bumps RTT_RUN_ID; every deferred callback returns early if its captured id is stale.

## OPEN — from the Zaandaa play-test discussion (2026-09-05)

Nothing below is implemented. The maintainer asked to be consulted before each change.

### Bugs

- [~] **Objects spawn but some clients never see them (distant connections).** PARTLY BUILT.
      In as of v1.161: the Resync BUTTON and the sweep behind it (manual only -- `RTT_RESYNC_AUTO` is
      false, so nothing sweeps in the background), and all four move-while-locked sites. NOT in:
      spawn staggering (item 1) and the automatic sweeps (part of item 2). The GUID strip (item 4) is
      permanently out -- it breaks every spawn path, see the brief.
      STILL OPEN, and only the maintainer can answer it: does TTS replicate a tag change to clients at
      all? Force the bug, press Resync. If the object does not appear, set `RTT_RESYNC_MODE = "tint"`,
      then `"lock"`. Write the answer into the brief. Original entry:
- [ ] Diagnosed
      2026-09-10. Items 1-4 were built that day (v1.154), BROKE THE MOD TWICE and were reverted in
      full in v1.156 -- nothing from the brief is shipped. Read "What went wrong" at the END of the
      brief before re-building any of it: the diagnosis still stands, but the GUID strip is not safe
      at all, and staggering and the sweep are each still unproven suspects for a second, different
      failure ("only sometimes the button works and only can spawn 1 faction"). One item per build,
      confirmed in TTS, next time. The original brief and
      why it differs from the plan is at the end of
      **[`MULTIPLAYER_SYNC.md`](MULTIPLAYER_SYNC.md)**. ONE THING IS STILL OPEN: nobody knows yet
      whether TTS replicates a tag change to clients at all, so the resend primitive
      (`RTT_RESYNC_MODE`) has to be validated in a real game with a genuinely distant client --
      force the bug, press Resync, and if nothing appears switch the constant to "tint", then
      "lock". Write the answer back into that file. The original brief follows.
      In short: script-spawned objects arrive as incremental create messages, a distant client drops
      one, and nothing re-sends it. Lock state is NOT the cause (it also hits unlocked objects) --
      it is why you notice, since an unlocked object self-corrects the next time it moves and a
      locked one never does. Rejoining fixes it, which proves host state was right all along.
      Plan: (1) stagger every spawn loop to 6/frame -- one Lilypad burst is 229 KB in a single
      frame; (2) an automated resync sweep, tag-toggle primitive, staggered, with a fallback ladder;
      (3) a Resync button; (4) a frame between `removeMapItems` and the rebuild, strip baked GUIDs,
      and three move-while-locked sites. Free first step: confirm every player is on TTS v14.2+.
      NOTE: the hand/card-visibility symptom is a SEPARATE bug and was explicitly deferred.

### Setup and placement

- [x] **The vagabond kit stopped after two pieces.** v1.182. The spawn callback destroyed the Mighty
      Multi-State Ruins bag for being tagged "Ruin Set" and then asked the corpse whether it was
      "Shuffleable" -- it is the only object in the content file with either tag, and it has both.
      TTS's C# null, not a Lua error, so the callback died on the kit's second piece. Nothing could
      test the Vagabond Layout at all while this stood.
- [x] **The vagabond's Advanced Setup card.** v1.182. "vagabond faction board sitll spawn the advanced
      setup card on the crafter improvement that we removed for all other faction boards" -- a
      nameless Card, CardID 406, dropped onto the crafted improvements board. It was the kit's
      eighteenth piece, so it was invisible behind the bug above.
- [x] **Relationship markers follow the table.** v1.183. "spawn only the ones from factions in the game
      that have been selected at the moment they are selected and fill the rightmost empty position in
      order." Placed one at a time by the arrival of the faction they belong to, packed against the
      right end of the row. `RTT_REL_FILL` is the only thing that decides the direction -- set it to
      "left" to pack from the vagabond board's end instead.
- [ ] **Knaves of the Deepwood has no relationship marker.** The kit ships eleven, one per faction, and
      the Knaves are the twelfth. Not a code gap -- there is no marker art to place. Needs a decision
      from the maintainer (draw one, or leave the Knaves without).

- [x] **Resync did nothing at all.** v1.207. Zaandaa: "your tag/untag idea didn't do anything" -- TTS
      does not replicate a tag change to a client that has lost an object, so the button was a no-op
      from v1.154. Mode is `"lock"` now; cards are skipped (locking things in hands is awkward and
      does not fix what cards suffer from), and the map is made interactable for the toggle and put
      back, per Zaandaa's own suggestion. Switching modes also exposed a dead-handle bug in the lock
      branch's put-back, which the harness caught: 22 in one sweep.
- [ ] **Does lock mode actually cure it for a distant client?** Unproven. Needs the real test: force
      the bug in a game with a genuinely distant client, press Resync, say whether the object appears.
      The harness cannot settle it -- the stub has no concept of a client.
- [x] **Cards showing their back.** v1.211. Zaandaa: "sometimes you can't see what cards are, like only
      seeing the back of a card", and "fixing that involves stacking them" -- not lock/unlock.
      Maintainer: "I don t think flip will do anything. make the reload cards with the resynch button."
      The Resync button now runs a second pass that calls `reload()` on every loose table card: the API
      is explicit that it "causes the Object to be deleted and respawned instantly", which is what
      stacking does, without the stack. A lock toggle cannot help here -- the client HAS the card, so
      the write applies normally and the stale bit stays stale; only a create carries the definition
      again. Button only, never automatic, two cards a frame, and every card snapshotted before it is
      touched so a swallowed one is spawned back from its own blueprint. Skipped: hands, held, moving,
      still spawning, scripted, button-carrying, and decks.
- [x] **The draft deal held card OBJECTS for ten seconds.** v1.211, found by the harness on the first
      run of the card pass. `rttSpawnDeck` stored the objects; `rttSlideOut` walks them one every
      0.6 s and `rttFlipAll` flips them at 0.12 s each, so anything that removed a draft card in that
      window -- Clear All, a player deleting one, now a reload -- killed the rest of the deal with a
      C# null. It keeps GUIDs and re-resolves at each step now.
- [ ] **Does the card reload actually cure it for a distant client?** Same unproven step as lock mode
      below, and the same test: force a card to show its back, press Resync, say whether it turns over.
      The harness cannot settle it. If it does NOT work, the next rung is reloading the DECKS too,
      which is a bigger hammer and was deliberately left out.

### Buttons and real estate

- [ ] **Per-faction DRAW ONE buttons, and DRAW POND when the frogs are in.** Zaandaa: old Woodland
      Tournament mods had a draw button beside each faction board. It avoids high-ping draws from
      hands and stops accidental overdraws (pressing 11). The maintainer has this on his own list.
- [ ] **Per-faction VP +1 / -1 buttons, echoing to the chat console.** Same source: the old mods
      printed each score change to the console, which doubles as a game log.


## NOTES DO NOT TOUCH

rotate the 4 player setup art by 90 degrees so it s similar to the 5 player setup art

remove the little stem pointing out of the frog mount it s background in the 3 player draft art