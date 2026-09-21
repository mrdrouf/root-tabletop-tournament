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

    cp dist/Root_Tournament_Edition.json ~/Library/Tabletop\ Simulator/Saves/
    python3 tools/update_saves.py

update_saves.py rewrites only three fields on two objects (board bab7e1's LuaScript/XmlUI/
CustomUIAssets, and any "Root Box Score" LuaScript), so table state and every LuaScriptState -- the
gizmo config, the box score's recorded game -- survive untouched. Originals are backed up outside the
Saves folder, last two sets kept.

SCOPE: `Root_Tournament_Edition.json` ONLY. The maintainer said so plainly after a first pass
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


## From Zaandaa's solo test, 2026-09-17 evening (built v1.433-1.436, not yet confirmed in TTS)

Diagnosed first, then the maintainer said "fix all the other things as well". One commit each.

- [x] **Cats spawn on the bare table after Clear All.** v1.434 (7d773ca). `clearAll()` destroys the map (it keeps
      only hand zones, Table Pieces, landmarks and three named fixtures) and calls
      `rttResetRunState()`, which never touches `RTT_CURRENT_MAP`. `rttMarquiseCats` reads that
      name and looks the clearing centres up in `RTT_CLEARING_CENTRES[mapId]` -- fixed world
      coordinates -- so twelve cats drop where the last map's clearings were. It never asks whether
      a map object exists (`rttFindMapObject` does exactly that and is unused here). The same stale
      name feeds `rttFixMarshVariant`, the "would leave a different map behind" warning and
      `rttBadgerRelics`. It is also saved into the board's state (`map`), so it survives a reload.
      FIX SHAPE: Clear All forgets the map (`RTT_CURRENT_MAP = nil`, `RTT_MARSH_5P_BUILT = false`),
      and the cats refuse to go out when `rttFindMapObject()` is nil (retry, then say so).
- [x] **VP panel dies with a C# null when the frogs are picked right after another faction.** v1.435 (44baacf).
      Chat: `[VP Panel - 3e5d6a] Lua Error <vpRefresh>: Object reference not set`. Save
      `frogerror2.json`: Duchy joined 2:57:09, error 2:57:10, Diaspora joined 2:57:11 -- two kits
      in the paced queue at once. `rttFrogsSetup` runs 0.5 s after the kit is queued: it merges the
      frog cards into the main deck (`putObject` destroys the frogs' own deck) and spawns the pond
      in the same call; the pond's callback then `call("vpRefresh")`s EVERY panel, including the
      frogs' own panel, which may still be spawning. `vpRefresh` -> `vpMarker` walks
      `getAllObjects()` and asks each object its name; an object destroyed in that frame (the
      merged frog deck) or a panel not finished spawning (`self.UI`) answers with the C# null that
      pcall does not catch. Every API call in the panel is already inside a pcall, which is itself
      the proof that pcall is not the guard here.
      FIX SHAPE: the board knows the marker (RTT_HOME / the box score row carries its guid) --
      hand the panel its marker's guid or url in the ping instead of letting the panel search the
      whole table; the pond ping skips panels whose `spawning` is true (they refresh themselves at
      10/40/120 frames anyway); and the pond spawns a frame after the deck merge, not in the same
      call. The harness cannot reproduce a C# null, so the proof is a TTS run: badgers then frogs
      within two seconds.
- [x] **Resync does not bring the hand bar back, and a player can see himself unseated while
      everyone else sees him seated.** The reseat hops the player to Grey and straight back (one
      frame). That re-runs the seat assignment, but the bar at the bottom of the screen is drawn
      from the hand ZONE object on that client, and TTS bug 1010 is precisely that the zone's update
      is not delivered to its owner. A colour hop does not re-send the zone object; only a zone
      write (which drops the cards, tried four ways) or a reconnect does. The chat shows one
      "Zaandaa is color Teal" per press and no Grey line, so whether the hop even reaches the
      affected client is unknown -- a Grey-and-back inside two frames may be coalesced on the wire.
      v1.436 held the player in Grey for half a second: "changing colors does not help". ROOT CAUSE
      FOUND, v1.441: the blueprint keeps every seat colour's boxes at the table's long edges and every
      game moved them behind the seats AFTER seating -- the exact move TTS drops on the owner's client.
      THE RULE NOW (rttPlaceSeatHands): a hand box only moves while nobody owns its colour. The draft
      parks everyone in a seat colour, places every seat's hand, then seats; a manual pick hops the
      picker off, places, hops back; Resync does the same as a repair (a real change, then the exact
      box, while the player is off). Hand 2 (Alliance, bats) is left exactly as it was -- v1.441 gave
      every seat a supporters box ("the supporter box spawned on the eyrie faction spawn ??!!"), undone
      in v1.443: "there is never an issue with that alliance box". v1.444: a hand that HOLDS CARDS is
      never hopped, moved or rewritten anywhere ("I could not see the face up of my cards in my hands"
      after another player's Resync), and the sweep never touches the table itself (Table Piece, Flex
      Table Control). v1.445: Resync repairs a hand WITH cards too -- the cards are lifted out face down
      and locked, the box rewritten off-colour, the cards dealt back once the player is home (the hop,
      not the write, is what left his cards faceless: "not able to see any card face even after
      flipping"). Not yet confirmed in TTS.
- [x] **Two colours' hand boxes on one seat -- the "no face however I flip" bug.** v1.448. Maintainer:
      "the issue seem to be that you are spawning then two hand zones!" A colour kept its box wherever
      the last game put it, and the seats change colours between layouts (Teal at pos4 in 5P, Orange in
      4P), so one box lay over another and a card inside two colours' boxes is hidden from both. RULE:
      a seat colour's box is behind its seat this game or at its HOME on the table edge
      (RTT_HAND1_HOME), moved only off-colour; a new game parks the unowned, the draft and a manual pick
      clear their seats (rttEvictStrayHands), Resync clears every seat and says how many it parked.
      v1.449: ONE primitive for every box move (rttMoveHand: cards lifted out, owner stepped off, box
      written, owner back, cards dealt back), so no move is ever refused -- a hand holding cards was
      the last thing that could leave a box behind. Resync leaves hands alone while a setup is seating.
      Harness: 3P -> 5P -> 4P with a card left in a hand, then Resync; never two boxes on a seat.
- [x] **Numpad 1 and 2 do nothing in the deck positions.** v1.445, narrowed in v1.446: pointing inside
      the deck holder's or the pond's footprint (or hovering a deck standing there) and the key is
      quiet; loose cards and a deck elsewhere are fine ("the rest like loose cards is fine"). If yes, the hop reaches them and the bar is
      the zone object (no script lever found short of recreating the zone, which is only safe when
      the hand is empty). If no, the hop is not reaching that client at all.
- [x] **Resync does not heal the crow plots.** v1.433 (ca9a547): the reload pass takes every loose tile and token. The plots are ordinary unlocked tiles inside the
      hidden zone, and the sweep does touch them -- with the lock toggle. A lock toggle is a
      property write: it only helps a client that HAS the object with stale state. A plot the client
      never received (a dropped create in the crow burst: board, zone, then twelve plots) cannot be
      revived by any write, and the reload pass -- the one thing that re-sends a definition -- is
      cards only (`o.tag == "Card"` in `rttResyncCardOK`). So no path ever destroys-and-respawns a
      plot. FIX SHAPE: let the reload pass take the plots too (named "Plot", tagged RTT Faction,
      unlocked, no script, twelve objects), or more generally every loose unlocked faction token.
      Whether the crow player or the others saw the bad plots decides which client dropped them.

## STRUCTURAL -- the three rules from the 2026-09-17 bugs (built v1.437-1.439, not yet confirmed in TTS)

Maintainer: "from these bugs any general rule or other mechanisms to reshape like what happens to the
relics etc" -- then "go ahead all of it". Each rule is one commit and one harness case.

- [x] **Ask the table, never memory.** v1.437 (cd028f7). The map board is tagged `RTT Map`,
      `RTT Map: <name>` and `RTT Map 5P` the frame it is placed; `rttMap()` reads those and nothing
      else, and every reader of the map goes through it (cats, relics, Marsh variant, the map-change
      warning, the under-map refusal, the map lock). `rttFindMapObject`'s fallback to "the object
      with the most snap points" is gone -- it was placing the relics against a faction board or the
      pond when no map was out. An untagged board from an old save is adopted once (>= 40 snap points).
      `RTT_CURRENT_MAP` / `RTT_MARSH_5P_BUILT` are only the saved-state cache now.
- [x] **Find by tag or guid, never by walking names.** v1.438 (1874662). Kits tag every bag
      `RTT Bag: <nickname>`; `rttFindBag` answers by tag with a guarded walk for old saves; the eight
      remaining name walks read through `rttNameOf`, which answers "" for an object that cannot.
- [x] **One list of guid registries.** v1.439 (see git log). `RTT_GUID_REGISTRIES` names every table
      keyed by an object's guid with its shape and whether a new game empties it;
      `rttSwapGuidEverywhere` (after a Resync re-create) and `rttForgetRunGuids` (new game) walk it.
      A registry added to the list is covered by both. Today's reset behaviour is preserved exactly.

STILL BY MEMORY, on purpose: `RTT_PRIO_MAP` (which map's priority markers are out -- rttClearPriority
owns it), `RTT_TRACK` (the score track, re-found by guid and re-detected when gone).

## Knaves stash, 2026-09-18 (built v1.447, confirmed in TTS 2026-09-18: "it works", fourth captain included)

- [x] **Snap points on the fifteen stash cells** of the Knaves rules board, read off the maintainer's
      `items` save (five columns by three rows, board-local RTT_STASH_COL x RTT_STASH_ROW), baked into
      the blueprint; the runtime asks those points to snap rotation too.
- [x] **A captain's two items go by PICK ORDER**, cycling every seven: 2-1/2-2, 3-1/3-2, 4-1/4-2,
      5-1/5-2, 1-1/1-2, 1-3/2-3, 3-3/4-3 (his "3-4" read as 4-3). Column 1 is the player's left, row 1
      the top of the stash; if he counts the other way, flip RTT_STASH_COL or RTT_STASH_ROW.

## Zaandaa's four-player game, 2026-09-18 evening (drop/TS_AutoSave.json; built, not yet confirmed in TTS)

- [x] **"[Global] Lua Error: Object reference not set to an instance of an object", once per touch of
      a piece, all game.** The Global script is the game recorder. Its hand read (`obsHands`) runs
      inside every flush, 0.4 s after every drop, and inside every keyframe; it clamped a hand count
      of ZERO up to one, so a player with no hand zone -- the HOST WATCHING FROM GREY, which is how
      Zaandaa ran this game (four seated, he was not one of them) -- was asked for hand 1, and that is
      `getHandObjects` on a hand that does not exist: the C# null pcall cannot catch, the same one
      RTT_HANDS_PER_SEAT in logic.lua documents. The flush died every time; the error is the same one
      the NOTES entry "spectator joined then I had error ..." describes, from the same cause.
      FIX: a count of zero (or one that cannot be read) is zero hands, and the export's reveal asks
      the count too. The harness stub now MODELS the C# null (`CSHARP_NULL` in tts_stub.lua: Grey and
      Black own no hand zone, a hand index that is not there is recorded in REC.nulls and raised past
      every pcall), so the next guard of this kind is testable; the new case seats a spectator, drops
      a piece and changes turn. Against the old recorder it fails naming the call.
      SECOND PASS, same evening ("make sure this never happens"): the stub now models EVERY C# null
      the mod has met -- a dead handle (method or property), a hand a colour does not own, its
      transform, getCustomObject on a plain object -- as the uncatchable throw it is, and the runner
      fails ANY case that walks into one, under any number of pcalls, naming the call. All 237 cases
      pass with that on, so no path the suite drives touches one. Evidence it was this bug: Zaandaa's
      Steam name is "Zaandaa" in every earlier save; the four seated in this one are Davee_39,
      Starhard_Fishrinse, Requiem and simber1842, so he hosted from Grey or Black, the one condition
      the recorder had never been run under.
      CONFIRMED LIVE the same night, on the old script: Zaandaa left the server, no error; rejoined
      as spectator, error back; switched to Game Master (Black), still there. Fix not yet run in TTS.
      THIRD PASS, v1.454 ("make sure this never happens"): an independent Codex read of every API
      call that can null is in **[`NULL_AUDIT.md`](NULL_AUDIT.md)**. The concrete family -- the
      same handless player pressing DRAW or DRAW POND, picking a faction as Game Master (only Grey
      was refused), numpad 1 from Grey or Black -- is closed by one `rttHasHand(color)` check, in
      words to the player. A selector closed with its own X button no longer leaves a dead handle
      for the menu refresh (`rttLive`, `rttDetachBoard`), and numpad 3 re-finds its piece by GUID
      after its two-frame wait. Four new cases. The rest of the audit (a piece deleted by another
      player inside a sub-second wait) is recorded, not fixed.

- [ ] **A crash after the end of the game (drop/TS_AutoSave_3.json, game 6aada60c54753b8f).** What the
      data shows, all on the OLD script (v1.449/1.450): Duchy reached 30 at 01:38:58, the box score
      logged gameover and archive-win, the recorder's document (115 KB, 1314 events, 24 keyframes,
      reveal 4 hands) reached the server at 01:38:59 and was accepted, and the autosave at 01:39:08
      shows a normal table: 259 objects, turns still on, nothing odd in any script's state. Host was
      simber1842. NOTHING in the save or the archive is later than 01:39:08, so the crash itself is
      not in the evidence. Needed: whose TTS crashed (host or a client), frozen or closed, what was
      done after the win (Clear All, a new setup, EXPORT), any error text.
      SIMBER (the host, Linux build), 2026-09-19 02:00: "about a min or so after the game ended,
      everyone disappeared from the tts lobby and then 15 sec later I was kicked. I believe the error
      said the lobby timed out and I confirmed with the other players that they had also been kicked."
      Nothing in the mod runs a minute after a win: the recorder sent once, one second after it (and
      the server has the document), the box score's second win-send only fires on a dominance change,
      and neither script has a wait longer than a few seconds. A host losing every client and then
      being kicked for a lobby timeout is the host's own connection to Steam dropping. Video to come.

- [x] **The frogs' DRAW dealt a card that ended on the discard, face up to the frogs only.** Simber:
      "Twice, when frogs hit the button to draw a card, the card drew into the discard ... the card
      was face down to other players and face up to frogs even while hovering over the discard."
      The archive shows both (00:10:35 Root Tea, 01:30:55 Mouse-in-a-Sack): the card leaves the draw
      deck and 0.4 s later sits on the discard slot turned the holder's way, and Orange pulls it back
      out by hand seconds later. CAUSE: the deck holder's once-a-second sweep sends any non-frog card
      it finds at the pond to the discard, and only the frogs' hand lies past the pond, so only their
      deals ever crossed it in the air. The discard sweep already skipped a card that is moving, held
      or not at rest; the pond sweep did not. Fixed in the holder blueprint (content.lua, v1.457): the
      pond sweep takes the same settled test. Harness case fails against the old holder. Not yet
      confirmed in TTS.
- [x] **The box score's three captains do not follow a change of mind.** Maintainer, 2026-09-19:
      "the captain auto detection does not change the three captains if the player changes his mind
      and spawns another captain." The sheet counted captain MEEPLES near the Knaves' supply; a
      captain is spawned once and never taken back, so after a swap four stood there, more than the
      three the row allows, and the count refused to update. v1.458: the board rebuilds its slot
      table on every pass of the detector and publishes the CARDS in the slots (`RTT_CAPTAINS`,
      cleared by a new game); the sheet reads that first and only counts meeples for a board that
      publishes nothing. Not yet confirmed in TTS.
- [x] **A card dropped on the frog pond flips face up, like the discard.** Maintainer, 2026-09-19:
      "on the frog pond the card should also flip face up like the normal discard." v1.458: the pond
      is a drop spot of the deck holder -- turned face up and snapped onto the pile; a dominance card
      is not launched at the track from there. Not yet confirmed in TTS.
- [x] **The captain detector stops at START.** Maintainer, 2026-09-19: "Captain detector (every
      card's position) should stop after the game has started so we clicked on start." It polled
      every 1.5 s for the whole game (every card's position, ~310 API calls a pass). v1.459: the
      turn panel's START tells the board (`rttGameStarted`), the detector returns without re-arming,
      the list published by then stands, and a new game arms it again. Not yet confirmed in TTS.

## Script load during play, measured 2026-09-19 (the "is it laggy" question)

Per-call cost from the recorder's own measurement in TTS (156 objects x 3 reads in 1-2 ms, ~3 us a
call). Nothing on the table runs every frame; nothing hooks pick-up, so a dragged piece costs no
script time until it is dropped.

| runs during play | period | calls a burst | ms a burst (measured / x10) |
|---|---|---|---|
| box score poll (every object's name, dominance scan, 4 markers) | 4 s safety net + on events, as of v1.462 (was 1.2 s) | ~850 | 2.6 / 26 |
| captain detector (until START, as of v1.459) | 1.5 s | ~310 | 1 / 10 |
| turn panel tick (round + clock, 2 UI writes) | 0.25 s | ~5 | 0.3 |
| deck holder sweep (3 physics casts) | 1 s | ~10 | 0.5 |
| map lock, prisoner check, Steam tick | 1-3 s | ~10 | 0.03 |
| recorder, per drop (0.4 s later) | on a drop | ~40 | 0.12 / 1.2 |
| recorder, keyframe | once a turn | ~1850 | 5.5 / 55 |

About 5 ms of script a second in all, the recorder ~2% of it. Not the cause of sluggish dragging.
Where to cut, if it is ever needed, biggest first (none done):
- [x] Box score reads on EVENTS, v1.462. Maintainer: "could the box score poll happen only when a vp
      marker is moved and dropped or vp button is pressed?" -- "yes go ahead you can make the security
      poll every 4 seconds". A dropped marker or card, a turn change, an arriving marker, a colour
      change, the panel's +1/-1 and the board's own marker moves (rttTellSheet, after rttPlaceVP and
      rttTagMap) each arm one read 0.3 s on ("a bit slow to update when moving the vp markers") and
      once more a second later; a second event while one is pending arms nothing. The 4-second poll
      is the safety net. Also v1.462: the Resync message is one line ("make the resynch message
      shorter and to the point"): "Resync done: N objects; M cards; ..." and only what happened.
      Not yet confirmed in TTS.
- [ ] Turn panel: tick once a second, and flash the alarm by recolouring (setAttribute) instead of
      rebuilding the whole panel XML every 0.75 s on every client -- the one script behaviour that
      can make CLIENTS stutter for a whole long turn.
- [ ] Box score UI: at most one rebuild every 2 s (a 15 KB XML rebuild on every client on each
      score change).
- [ ] Deck holder sweep: every 2 s, or only for a few seconds after a card is dropped.
- [ ] Map lock and prisoner timers: every 3-5 s instead of every second.
- [ ] The clean test of the recorder: `OBS_ENABLED = false` in the Global script for one game.

- [x] **Two rabbit Ambush cards in one game, nobody cloned one.** Maintainer, 2026-09-20. No
      function clones a card during play -- the two archived games of the 19th show not one card
      spawned after START -- but cards LEAK BETWEEN GAMES on one table, and the maintainer's own
      autosave of the 19th shows the shape of it: "Assimilators" twice inside the main deck under ONE
      guid. Two roads, both closed in v1.460:
      (1) A frog card carries no tag (not "RTT Faction", never "Deck Object"), so one dealt into a
      hand or left on the table survived the new game's teardown, and the next frog game's merge,
      which sweeps every loose frog card into the deck, put it in beside the fresh kit's copy of
      itself. The removal that runs on every new game took the deck's frog cards by guid, which pulls
      one of two twins and leaves the other. NOW: the new game also destroys every frog card in a
      hand or on the table and every all-frog pile, and the deck's frog cards go by index, top down.
      (2) The Standard and Exiles & Partisans deck blueprints tagged only the deck, not the 54 cards
      (Squires & Disciples and Dark tag both), so a card dealt from them survived the next deck pick
      (makeDeck destroys "Deck Object" only) and came back beside the new deck's copy -- the road to
      two rabbit Ambushes with either of those decks. NOW: every card of every shared deck is tagged
      in the blueprint. Two cases, both failing on the old build.
      MAINTAINER: "no there was no other game before. secure resynch." So for his game the two
      roads above are out and the Resync card pass is the one left: it respawned a snapshotted card
      it could not find by guid -- and the guid read the instant after reload() can be the one TTS
      re-rolls a frame later -- or within 0.05 of its old spot, which a card settling on a pile
      fails; and a card dropped onto a deck during the half-second pass was "lost" the same way.
      v1.461: the pass keeps the handle reload() hands back. Alive, it IS the card, wherever it went;
      dead, the card went where somebody put it and is never put back. Only a reload that answered
      nothing at all can still be respawned, and then only by guid, spot and nobody dragging. One
      case, two ways, both duplicating on the old build. His other two sightings fit the same
      cause: "a card that seemed to be floating above the discard pile and a card fell through the
      table" is what physics does with two cards spawned into one spot -- one pushed up, one down.
      AND A CENSUS ("the resynch needs to check the cards and make sure there are no extra cards for
      each deck on the table after respawning the cards"; "be careful as decks have some cards in
      duplicates naturally"): ten frames after every Resync the board counts every card of the
      shared decks and the frogs' cards by CARD ID -- natural twins are two ids, and no deck
      blueprint lists one id twice, which the harness holds -- and destroys loose copies beyond the
      first, sparing hands; a twin inside a deck is reported for a hand to sort out. Faction kit
      cards (three Faithful Retainers) are not judged. Not yet confirmed in TTS.
- [x] **"Resynch changed my seat for some reason. I am alone with several factions picked by me.
      Careful with that."** Maintainer, 2026-09-20, on v1.461. The reseat steps the player off to
      Grey and straight back, and two things happened in between: TTS may move the turn off a colour
      with nobody in it, and the board's own colour-change handler re-applied the turn order reading
      that moved turn as the one to keep -- with several factions all his, the turn (and the panel,
      and the box score's row) landed on another of them. v1.463: the reseat marks itself
      (RTT_RESEATING) so the handler stays out of its hops, and puts the turn back to what it was
      before the press once the player is home (rttRestoreTurn). One case. Not yet confirmed in TTS.
      "STILL CHANGED MY SEAT" (v1.463) -- the real road, closed in v1.464: the manual pick placed
      the PICKER's hand box on every pick (makeFaction, rttPlaceHandsAround with the picker's colour),
      so one person picking several factions had his box follow his last pick, while rttPlaceFaction,
      refused a second seat in his colour, gave that seat a free colour and kept his colour on seat 1.
      Resync repairs a box to the RECORD, so it put his box back on seat 1 every time. The pick now
      places the seat's own colour's box once the pick is recorded -- the picker's only when the seat
      is his -- so the record and the boxes agree and Resync has nothing to move. One case, failing on
      the old build with the picker's box on seat 2. Not yet confirmed in TTS.
- [x] **An off-turn point before a faction's turn shows in the current round at once, and comes off
      if reverted.** Maintainer, 2026-09-20: "if a faction wins a point in a round but not on their
      turn and they have not taken their turn yet you need to update their score for the score of
      that turn ... even though they have not taken their turn in that round ... now if the player
      reverts that score and goes back to the same score that he had in previous round then you need
      to remove that score and that turn to what it was before". Before, the sheet only amended a
      box the faction's own turn had already written. v1.465 (amendRound): a faction yet to play
      gets the round's cell written PROVISIONALLY (row.prov) the moment its marker moves off-turn,
      updated in place on further changes, and emptied again if the marker returns to where the last
      round left it; its own turn then writes the cell for real and counts as one turn. The existing
      case carries the new rule and fails on the old build. Not yet confirmed in TTS.
- [x] **A relic snapped to the enclave snap on a suit marker.** Maintainer, 2026-09-20: "that snap
      should work only for enclaves." Each map token's blueprint carries one snap point per suit
      marker, turned the marker's way (at the end of its lattice; Gorge at the start; Marsh has three
      more for the five-player variant), and TTS lets any object take an untagged snap point; a
      tagged one takes only objects that share a tag. v1.466: those points are tagged "Enclave" in
      the six map blueprints (12, 12, 12, 12, 12, 15) and the twelve enclave tiles carry "Enclave"
      too; relics and everything else pass them by. Enclaves are still placed by their own script.
      One static case. Not yet confirmed in TTS.
- [x] **Resync with a card held by the mouse: "the hand stops acting like a hand, the cards start
      floating a bit then they behave ... like a deck of cards ... they consistently fall to the
      table after a while."** Maintainer, 2026-09-21. The hand repair steps a player off their colour
      and TTS will not do that for a player holding an object; run anyway, the repair took a hand
      apart -- his autosave of 12:50 (a build before v1.463) shows a five-card deck, face up, on the
      table surface inside his hand zone. THE RULE, his words: "if any player is holding something,
      create a message saying that everyone needs to drop everything they're holding with their
      mouse. Be precise so it is no confusion with holding in the hand ... and then do not proceed."
      v1.470: Resync checks first; if anyone holds a piece with the mouse it does not run and says
      so in one line, naming them and saying cards in the hand are fine. Everything the attempts of
      v1.467-1.469 had added around this (the skip, the checked deal-back, the step check, the
      forced drop) is removed; the code is back to v1.466 plus this gate. One case. Not yet confirmed
      in TTS.
- [x] **Numpad 4: hold it on a selection to set where those pieces go home.** Maintainer,
      2026-09-21: "select a bunch of tokens, for example enclaves ... press numpad 4 for, let's say,
      one second, this would redefine the default position of where this token goes back when I
      press zero ... take all of the warriors out of the supply, select them all, press numpad 4 ...
      and numpad 2 would pick the enclaves from that position as well." v1.471: held for the full
      second (RTT_KEY4_HOLD, like numpad 2's choosing), every selected piece's spot becomes its home:
      numpad 0 sends it back exactly there, numpad 2 finds pieces standing on those spots as it finds
      any home row; with nothing selected the hovered piece alone; a short press does nothing; a
      word says how many were set. Saved with the board (home4) so a reload keeps them; a new game
      forgets them with every other home. One case. Not yet confirmed in TTS.
      "NUMPAD 1 NEEDS TO FIND WARRIORS even if they are not in the supply but in their new home set
      with numpad 4." v1.473: numpad 1 looks at your faction's set homes first and hands out a
      warrior standing on one (a locked prisoner is skipped), and only then opens the bag -- the
      order numpad 2 already uses for a row and a bag. Numpad 0 on such a warrior already went back to
      the set spot. One more case. Not yet confirmed in TTS.
      "SOMETIMES YOU SEND BACK MORE WARRIORS THAN THE NEW HOME POSITIONS CAN ALLOW and do not split
      properly between the possible positions when some are still in the supply" -- "allow only 1 new
      zone per tokens/type of warrior with numpad 4, if I numpad 4 after numpad 4 then you forget the
      previous numpad 4 positions." The first build keyed a set home to the PIECE: a warrior went to
      its own spot even with another already standing on it, and a fresh warrior out of the bag had
      no set home at all. v1.475: the set spots are a ROW keyed by the piece's NAME (RTT_HOME_SET
      [name]), one row per kind, replaced whole by the next numpad 4 on that kind. Numpad 0 fills the
      free spots of that row first, one piece per spot, and the rest go where they always went (a
      warrior into its bag, a token to its old row); numpad 1 and 2 take from that row before a bag.
      A save from the first build is converted on load. Three cases. Not yet confirmed in TTS.
- [x] **A one-page player guide to the things that are not obvious.** Maintainer, 2026-09-21: "Create
      a tiny nice design looking pdf to explain the functions of the mod that are not obvious so the
      numpad and other things from boxscore." guide/RTT_Guide.pdf, built from guide/RTT_Guide.html by
      tools/make_guide.py (Edge headless; Metamorphous for headings as the nearest free face to the
      board's Luminari, Sorts Mill Goudy for text, the mod's parchment). Numpad 0-4 and the named
      hotkeys, the box score, the VP panel, the draft, the turn panel, the deck holder, Resync and the
      setup board's habits. Linked from the README. The footer carries a month, not a build number,
      because the commit hook bumps VERSION on every commit. First cut was two pages -- "lot of
      unnecessary fluff in the document" -- so it is one page now, one line per item, no asides.
- [ ] **"All the clearing markers seemed to be unlocked."** Simber, same game. In the autosave taken
      ten seconds after the win all twelve priority markers are LOCKED, and the map too. Resync's
      lock mode unlocks each object for one frame and locks it again, so nothing stays unlocked by
      design. Unknown when he saw it; the video may show. Not started.
- [x] **Numpad 0 says "That piece is locked ..." even for a piece it would never move.** Maintainer:
      "If the object would be unaffected, the error/advice shouldn't show." Then, 2026-09-20: "I told
      you already to remove that message." v1.463: the message is gone; a locked piece is left alone
      in silence.
- [ ] **Box score: auto-detect the three captains picked when the Knaves are in.** Maintainer: "add
      the autodetec of the 3 captains picked in boxscore with knaves faction."
- [ ] **A dominance card spent into the Lost Souls stays there until discarded** (the rules), and
      **frog cards in the discard or the Lost Souls go back to the pond**, the reverse of what is done
      for normal cards. From the NOTES entry; not started.
- [ ] **Numpad 0 worked once on a badger, then not on other badgers, which ended up locked.** From
      the NOTES entry; not investigated.

## NOTES DO NOT TOUCH

there are also some Homeland assets we don't have yet like the Gladiator meeple and the assembly and acclaim tokens (both sides each) are outdated
Ultimate mod doesn't use the actual assets for those

what actions to automate like produce wood and recruit.

sometimes seat assignement does nt work player can see it s hand but not below on the screen; leave and rejoin the game fixes it; old bug that happens in orginal mod as well

is march flooded clearing properly randomised? got the same map twice in two consecutive games

spectator joined then I had error lua object reference not set on an instace of an object every time a player touched an object as player 1.

left clic on a warrior then hold left clic on that warrior then right click to grab warriors draws cards; completely insane bug; also happens only in some middle clearing;

status on the hand not appearing below screen? 


wait according to the rules a dominance card spent in the lost souls stays in the lost souls until it is discarded!!!! also move frog cars in the discard or the lost souls back to the pond as you do in reverse for normal cards.

also investigate: a player used 0 once successfully then it didn't work on other badgers
other badgers ended up locked when using it


Minor thing: this shows up even for things that should not return anywhere with numpad 0. If the object would be unaffected, the error/advice shouldn't show. 

error: That piece is locked, so numpad 0 leaves it alone. Unlock it (L) and try again. 

Aslo add the autodetec of the 3 captains picked in boxscore with knaves faction.
