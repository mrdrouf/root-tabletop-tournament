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

### Buttons and real estate

- [ ] **The Lizard Board's three Lost Souls counters print on top of the printed suit icons.**
      Deferred by the maintainer on 2026-09-08 ("we are going to fix that after") -- the outcast
      symbol beside them is done and shipped in 1.84. The buttons pass z = -COUNT_Z and land at
      local z -0.17, which is the middle of the icon band (-0.2171..-0.1380). A button's x IS
      mirrored against the model frame but its z is NOT -- a reflection, not a turn -- so to sit at
      local z Z the button must be given +Z, not -Z. That is the mechanical half.
      The design half is that THERE IS NOWHERE OBVIOUS TO PUT THEM: measured on the board texture,
      the Outcast panel's ink-free horizontal bands are only 8, 15, 12, 9 and 9 px tall, none of
      them enough for a numeral. Three candidates were rendered against the real art and shown to
      the maintainer: (E) a row at the top of the Lost Souls box at local z ~+0.243, each number in
      its own suit's column -- all three counts visible, clear background, and it sits in the box it
      counts; (F) inside the three printed slots, tidiest but the outcast suit's slot is taken by
      the symbol so that count is lost; (G) just under the slots at z ~+0.060, closest to the suit
      icons but cutting across the panel's torn border and the Lost Souls frame. E was recommended.

- [ ] **Per-faction DRAW ONE buttons, and DRAW POND when the frogs are in.** Zaandaa: old Woodland
      Tournament mods had a draw button beside each faction board. It avoids high-ping draws from
      hands and stops accidental overdraws (pressing 11). The maintainer has this on his own list.
- [ ] **Per-faction VP +1 / -1 buttons, echoing to the chat console.** Same source: the old mods
      printed each score change to the console, which doubles as a game log.
- [ ] **A one-shot DEAL FIVE button beside the deck when it spawns.** Temporary, removes itself.



## NOTES DO NOT TOUCH

the lizard has the lizard wizard to keep track publicly of the outcase. it also has an outcast on its faction board. could you have the outcast on the faction board follow the information on the lizard wizard? so have the symbol for the outcast suit and then when it s heated and the counter for the number of cards of each suit in the lost souls

add enclave snap when militant or not

 
can you increase the highlight on numpad 3? make it much more highlighted? and make it black highlighted.