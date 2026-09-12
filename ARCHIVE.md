# RTT Game Archive — recording a game and shipping it to the archive host

**Status:** spec, 2026-09-12. This file is the CONTRACT. The Lua recorder, the PHP endpoint and the
local fetcher are written against it independently and must not disagree.

The mod records what happens on the table during a game and, when the maintainer presses EXPORT on
the box score, POSTs one JSON document to a server he controls. A local tool pulls those documents
down, validates them and files them into a corpus the solver can train on.

`tools/ARCHIVE_GUIDE.md` is the runbook that goes with this contract: how to deploy the pieces,
where the keys live, what to check when a game does not arrive. Anything operational belongs there,
not here.

---

## 0. Why it is shaped this way

Three constraints, each measured or paid for already:

1. **Nothing may run on a heartbeat.** `MULTIPLAYER_SYNC.md` non-negotiable #2. The recorder arms a
   single one-shot timer when something moves and lets it die when the queue drains. An idle table
   runs no timer at all.
2. **The recorder never writes to an object.** No `setLock`, no `addTag`, no `setColorTint`, no
   spawn, no move. Object writes are replicated to every client and are what broke v1.154. Reads are
   not replicated, so this adds zero bytes to TTS's client sync.
3. **The event stream does not have to be complete.** A full board read costs ~5 ms (measured, see
   `root_engine/docs/PERCEPTION_SPEC.md` §3.1a) and a Root turn takes minutes, so a **keyframe at
   every turn change** is free. Events give ordering and latency; keyframes give truth. A missed
   drag, an undo, a scripted move — all corrected at the next keyframe.

And one consequence of shipping a public mod: **the shipped save is public, so anything baked into
it is public.** `dist/Root_Tournament_Edition.json` is committed to GitHub. There is therefore no
such thing as a secret write key. The ingest endpoint is defended server-side (shape validation,
size cap, rate limit, quarantine) and the *read* side has a real secret that never enters the repo.

---

## 1. Where the code lives

| Piece | File | Notes |
|---|---|---|
| Recorder + uploader | `gen/src/observer.lua` (NEW) | becomes the save's **Global** script |
| Injection | `gen/assemble.py` | fills `@@GLOBAL_LUA@@` in `save.json`'s top-level `LuaScript` |
| Trigger | `gen/src/logic.lua`, inside `RTT_BOXSCORE_JSON` | two one-line `Global.call` hooks |
| Save refresh | `tools/update_saves.py` | must also refresh the top-level Global script |
| Server | `website/rtt/ingest.php`, `website/rtt/admin.php` | Bluehost, Apache + PHP |
| Deploy | `website/upload_rtt.sh` | same convention as the other `upload_*.sh` |
| Fetcher | `../root_games/fetch.py` | new folder, sibling of `root_engine` |

**The Global script is empty boilerplate today** (320 bytes of TTS's commented-out template). Putting
the recorder there rather than in `logic.lua` means a fault in it cannot take the board's 869 KB
script down with it, and the diff is purely additive.

---

## 2. The trigger

`uiExport` in the box score is the moment the maintainer declares the game finished — it writes the
notebook JSON and opens the upload panel. Hook it there, **before** anything token-related, so a game
archives whether or not a Root Database token is ever pasted:

```lua
-- first line of uiExport, and again in rdbUpload
pcall(function() Global.call("rttArchiveGame", { box = exportJson() }) end)
```

Both hooks fire in a normal session (EXPORT, then UPLOAD). The server **dedupes on `game_id`**, so a
second POST replaces the first rather than creating a duplicate — which is wanted: the second one
carries the finished box score.

`rttArchiveGame` must never throw into its caller. It is wrapped in `pcall` at the call site and
guards internally as well.

---

## 3. The payload

One JSON document, POSTed as `Content-Type: application/json`. Arrays-of-arrays for the bulk rows,
because objects-per-row triples the size for no gain.

```jsonc
{
  "schema":       "rtt-game/1",
  "game_id":      "a3f1c09e7b24d5e8",   // 16 hex, generated once per game (see §4)
  "mod_version":  "1.210",
  "started_at":   1757600000,           // os.time() when the recorder armed
  "sent_at":      1757684000,
  "sent_by":      "MrDrouf",            // host's steam_name

  "boxscore":     { /* tournamentPayload() verbatim — already matches the RDB schema */ },

  "setup": {
    "map":        "marsh",
    "deck":       "",        // ALWAYS EMPTY — see below
    "landmarks":  [],        // ALWAYS EMPTY — see below
    "map_tile":   {"x": 0.0, "z": 0.0, "sx": 50.5, "sz": 46.3, "ry": 180.0},
    "clearings":  [[1, -23.6, 19.6], [2, -2.0, 21.4]]   // [id, x, z] — from RTT's own tables
  },

  "seats": [
    {"seat": 1, "color": "Red", "faction": "marquise-de-cat", "key": "Marquise de Cat",
     "steam_name": "...", "steam_id": "...", "pos": [x, z]}
  ],

  // static per-object facts, emitted ONCE per GUID
  "objects": {
    "79bf39": {"n": "Cat Warrior", "t": "Figurine", "a": "4C4E4901"}
  },

  // [t, seq, kind, guid, color, x, z, ry, extra]
  //   t     seconds since started_at, one decimal
  //   kind  "drop" | "spawn" | "gone" | "take" | "stow" | "turn"
  //   color player who caused it, "" if scripted
  //   extra kind-specific: for "turn", the colour whose turn began
  "events": [[12.4, 1, "drop", "79bf39", "Red", 3.2, -8.6, 180.0, ""]],

  // captured ONCE, when EXPORT is pressed — the ONLY hidden information in the document.
  // Nothing above or below this key is hidden. See "Hard rules on content" below before touching it.
  "reveal": {"at": 1757684000,
             "hands": {"Red": ["Ambush!", "Dominance (Fox)"]},
             "facedown": [["a1b2c3", "Corvid Plot: Raid", 9.0, 1.1]],   // [guid, name, x, z]
             "unnamed": 2},

  // full board at each turn boundary, DELTA-ENCODED against the previous snapshot
  // rows: [guid, x, z, ry, stateId, qty, faceDown]
  "snapshots": [
    {"t": 61.0, "seq": 42, "turn": "Red", "round": 1, "full": 1, "rows": [["79bf39", 3.2, -8.6, 180.0, -1, 1, -1]]},
    {"t": 210.5, "seq": 88, "turn": "Blue", "round": 1, "full": 0, "rows": [["a1b2c3", 9.0, 1.1, 0.0, -1, 1, -1]],
     "gone": ["79bf39"]}
  ]
}
```

### Clearing ids: what `setup.clearings` can and cannot tell you

**It does not carry Root clearing numbers, and it cannot be made to.** Measured 2026-09-12, all five
fixed maps, against `root_engine/maps_data/<map>_geometry.json`:

- The recorder's original id was a **south-to-north sort index** — not any numbering Root uses. Mean
  residual against the printed layout: **16–20 units**, versus a clearing radius of ~4. It shipped
  twelve confident, meaningless ids. That is now the row's **fourth** field, the marker's art tail,
  which is its real identity: the twelve priority markers are pictures of the numbers 1–12 and the
  same twelve textures appear on every map. (Read off the art: `5C589936`=1, `A5F4904F`=2,
  `1D520705`=3, `B6E7F63F`=4, `9033BAB1`=5, `344FFF8A`=6, `1C7937D8`=7, `67903445`=8, `B30D2841`=9,
  `76BA556B`=10, `DE6E0673`=11, `2E2A197D`=12.)
- **Even the true priority number is a different numbering from the engine's.** RTT's markers show
  the tournament **clearing-priority** order; `clearings_uv` is keyed by the **setup-card** numbers.
  Fitting one onto the other with the correct labels gives 16–20 unit residuals at arbitrary
  rotations. Neither is wrong; they are different facts, and no fixed table converts them.
- **The markers are also an imprecise reference,** because RTT places each one *beside* its clearing
  so the suit token stays visible. Best unlabelled fit: worst-point error 4.4–5.1 u against a
  tolerance of one radius (~4). So `fit_map` answers `unconfirmed` on most maps, which is why a
  fetched game currently reports `clearings NOT resolved`.

**Do not fix this by loosening `CORROBORATION_TOLERANCE`.** Measured, same run: at the correct
orientation the worst point is 4.4–5.1 u; at 180° it is 7.4 u (Autumn), 7.4 u (Winter), 8.1 u
(Gorge) — a separation of only **1.6×**. A tolerance loose enough to accept the truth would accept a
half-turned board on three of five maps, and `PERCEPTION_SPEC.md` §3.2a already records that a
mirrored board scores the same on every other physical signal. Silently inverting a corpus is the
worst outcome available here.

**The fix, when it is done, is a better reference: the ruins.** Four per map, at known clearings,
printed rather than hand-placed, and asymmetric — `PERCEPTION_SPEC.md` §3.2a calls them "the one
thing on the table that can tell north from south and resolve a 180-degree calibration error". RTT
tags them `Ruin`. That is a recorder change (ship the ruin positions) plus a `fit_map` change, and it
is NOT yet done.

**Nothing is lost in the meantime.** Every event and keyframe carries world x/z, `setup.map_tile`
carries the board's own transform read off the map object, and `raw/` keeps the original bytes
forever — so clearing ids can be back-filled into already-archived games by re-running the cleaner
once the reference improves. `fetch.py` refuses rather than guesses, which is what makes that true.

### Three fields that are not what the example above first said

Each was written loosely here, found by the implementation, and corrected against the code rather
than the other way round. They are recorded because a reader who trusts the sketch will build the
wrong consumer.

- **`setup.deck` is always `""` and `setup.landmarks` is always `[]`.** RTT records neither —
  `DraftedLandmarks` is initialised and never written, and `makeDeck` keeps no note of which deck it
  built — while the **box score already answers both correctly**. Two records of one game must never
  be able to disagree, so the recorder declines rather than guessing. `ingest.php` must not validate
  on them and `fetch.py` reads the deck and the landmarks out of the `boxscore` object.
- **`seats[].faction` is the long slug: `marquise-de-cat`, not `marquise`.** That is the site's own
  vocabulary, from its developer, via the box score's `FACTION_SLUG` table
  (`eyrie-dynasties`, `woodland-alliance`, `lord-of-the-hundreds`, …). Matching the box score is the
  rule; the short form in the sketch was simply wrong.
- **`seats` can legitimately be `[]`**, when EXPORT is pressed at a table with nobody seated.
  `ingest.php` quarantines it, which is correct: the alternative is inventing seats, and the host
  gets an honest "archive failed" instead of a fabricated record.

### Hard rules on content

- **Nothing hidden while the game runs; one reveal at EXPORT.** This rule changed on 2026-09-12,
  and the *shape* of the change is the whole of it — read both halves before touching either.

  **The live stream is public information only.** Every event row and every per-turn keyframe carries
  no hidden information at all. Hand *sizes* may be recorded; hand *contents* never. A face-down card
  records `faceDown: 1` and its GUID, never its face. No Corvid plots, no Alliance supporters, no deck
  order. `PERCEPTION_SPEC.md` §3.4 — the four-line whitelist that separates a study tool from a cheat
  tool — still governs everything written while the game is being played, unchanged.

  **One `reveal` section is captured at the instant EXPORT is pressed, and at no other moment.** It
  carries hand contents and the identities of face-down cards:

  ```jsonc
  "reveal": {
    "at":       1757684000,                    // os.time() at EXPORT — not at arming, not per turn
    "hands":    {"Red": ["Ambush!", "Dominance (Fox)"]},       // colour -> card names, in hand order
    "facedown": [["a1b2c3", "Corvid Plot: Raid", 9.0, 1.1]],   // [guid, name, x, z]
    "unnamed":  2                              // face-down objects whose name read back empty
  }
  ```

  The maintainer's reasoning, in his own words: *"there is no cheating problem since it's at the
  moment of the export."* He is right, and the reason he is right is a property of the log rather than
  a promise about who holds it: **a log that never contains hidden information while the game is
  running cannot be used as a live advisor** — not by the host, not by a spectator handed the
  notebook, not by anyone who pulls the document off the server mid-tournament — because until EXPORT
  there is nothing hidden in it to read. That property is the safeguard. Preserve it. Do not sample
  hands at a keyframe, at game end, or every N turns "since we reveal them anyway": each of those
  turns the running log into an oracle and the sentence above stops being true.

  **The one caveat, stated honestly:** EXPORT pressed in the middle of a game would reveal that
  moment's hands. EXPORT therefore means "the game is over", and nothing enforces that but the person
  pressing the button.

- **No geometry in Lua.** Emit raw world x/z. Which clearing or forest a piece is in is decided by
  `root_engine/eyes/geometry.py`, which owns the tile-local map data. `root_engine/tts/live.lua`
  reached the same conclusion the hard way: *"only the viewer knows where the forests are — send the
  position and let it decide."*
- **Size cap.** The recorder stops appending at `OBS_MAX_BYTES = 1048576` and sets
  `"truncated": true`. A game is expected to land near 150 KB.

---

## 4. Recorder behaviour

**Arming.** The recorder is inert until a game starts. `game_id` is generated on the first turn
change or the first faction spawn, whichever comes first, from `os.time()` plus a counter — **not**
`math.random`, which RTT seeds once per setup.

**Events.** `onObjectDrop`, `onObjectSpawn`, `onObjectDestroy`, `onObjectLeaveContainer`,
`onObjectEnterContainer`, `onPlayerTurn`. Each handler does O(1) work: push a GUID onto a pending
list and, only on the empty→non-empty transition, arm `Wait.time(flush, 0.4)`.

**Flush.** Reads `getPosition`/`getRotation` for pending GUIDs only, appends rows, clears the list.
Does not re-arm. Held objects (`held_by_color ~= ''`) are skipped and re-queued once — a piece
mid-drag has a meaningless position.

**Keyframes.** On `onPlayerTurn`, walk `getAllObjects()` and append a snapshot delta-encoded against
the previous one. First snapshot of a game is `full: 1`.

**Persistence.** `onSave` returns the log so a reload does not lose the game. Capped at
`OBS_MAX_BYTES`; over that, the oldest *events* are dropped but every snapshot is kept.

**Transport.** `WebRequest.custom(url, "POST", true, body, {["Content-Type"]="application/json"}, cb)`
— the same call the box score already uses for the Root Database, so it is proven in this mod. On
failure the recorder keeps the log and writes a one-line status the maintainer can see; it does not
retry on a timer.

**Visibility.** The archive says nothing to the table. The outcome of a send — sent, failed,
quarantined — is written to the box score's own status line beside INFO, which the host is already
reading because he just pressed the button next to it. The `broadcastToAll("Game archived.", ...)`
line that this spec previously called "not optional" was removed on 2026-09-12 at the maintainer's
instruction. It was a decision, not an oversight: do not reinstate it because this paragraph used to
demand it.

What that gives up: the other players are no longer told, in the moment, that a record of their game
left the table. The fact is still visible — the status line is on a panel anyone can open — but it is
no longer announced, and nobody who was not watching the box score will notice.

---

## 5. Server (the archive host)

> **The archive host's hostname is deliberately not written anywhere in this repository — including
> here. Do not "helpfully" put it back.**
>
> This repo is published on GitHub under the pseudonym **mrdrouf**, `dist/Root_Tournament_Edition.json`
> is committed, and the host's domain contains the maintainer's real name. A plaintext URL in the Lua
> is therefore a plaintext URL on GitHub, and a search for his name lands on this project. The real
> value lives in exactly two places: **encoded**, in a constant in `gen/src/observer.lua` that is
> assembled back into a URL at runtime, and in plaintext in the local, **gitignored**
> `root_games/config.json` (§6). Everywhere else — this file, `tools/ARCHIVE_GUIDE.md`, commit
> messages, `website/upload_rtt.sh` — it is "the archive host".
>
> **This is identity separation, not security.** Anyone who wants the hostname can decode that
> constant in a minute, and nothing on the server depends on it staying unknown: `ingest.php` is
> public and takes no write secret at all (§0). The encoding buys exactly one thing — that searching
> GitHub for the maintainer's real name finds nothing. So neither "clean up" the obfuscation into a
> readable string nor mistake it for a control that protects the endpoint; hardening belongs in
> `ingest.php`, where §0 already put it.

Bluehost shared hosting: Apache, PHP, home `/home2/<account>` (the account name is a truncation of
the real name — same rule, keep it out of the repo), web root `~/public_html`.

```
public_html/rtt/ingest.php      POST, public, no secret (see §0)
public_html/rtt/admin.php       GET,  requires ADMIN_KEY — list / get / delete / log
public_html/rtt/.htaccess       deny everything except the two .php files
../rtt_data/                    OUTSIDE public_html — the JSON lives here, unreachable by URL
  ../rtt_data/quarantine/       failed validation, kept for inspection
  ../rtt_data/games/            validated, one file per game_id
```

`ingest.php` must:
- accept POST only, `Content-Length` ≤ 4 MB, reject anything else with 413/405;
- rate-limit by IP (a small file counter — 20 posts/hour is generous);
- `json_decode` and check `schema == "rtt-game/1"`, `game_id` matches `^[0-9a-f]{16}$`, `boxscore`
  is an object, `seats` is a non-empty array of ≤ 6 entries;
- write validated payloads to `../rtt_data/games/<game_id>.json`, atomically (temp + rename);
- write anything that fails to `../rtt_data/quarantine/<ts>-<ip hash>.json`;
- answer `{"ok":true,"message":"..."}` — the same shape the Root Database uses, so the box score's
  existing `rdbSay` reader could consume it unchanged;
- never echo a PHP warning into the response body.

**Bluehost runs mod_security in front of all of this, and it judges the User-Agent.** Measured
2026-09-12 against the live endpoint: `Python-urllib/3.9` and a bare `Mozilla/5.0` are refused with
**HTTP 406 and an HTML body**, before PHP is reached. `curl/*`, an empty agent, `TabletopSimulator`
and every `UnityPlayer/*` string tested are allowed through. So the mod is safe — TTS's `WebRequest`
is Unity's — and `fetch.py` is safe because it sets `User-Agent: root_games/fetch.py`. Any NEW client
must set one too, and a 406 with HTML in the body means this, not a bug in `ingest.php`.

`admin.php` requires `?key=<ADMIN_KEY>` where ADMIN_KEY is a 32-char random string **generated at
deploy time and never committed**. It lives in `../rtt_data/admin_key.txt`, chmod 600, and in a
gitignored local file for the fetcher.

---

## 6. Local fetcher — `../root_games/`

New folder, sibling of `root_engine` and `hoot3_video_analysis`, because the corpus is data shared by
the mod and the solver and owned by neither (`root_engine/FOLDERS.md`'s rule).

```
root_games/
  fetch.py           # pull new games over HTTPS, validate, clean, file them
  config.json        # {"endpoint": "...", "admin_key": "..."} — GITIGNORED; the one plaintext
                     #   copy of the archive host's URL that is allowed to exist (§5)
  config.example.json
  raw/<game_id>.json      # exactly what the server holds, never edited
  games/<game_id>/        # cleaned, one folder per game
    game.json             # normalised record
    events.jsonl          # one event per line, engine-ready
    boxscore.json
  README.md
  .gitignore
```

`fetch.py` talks HTTPS with `urllib` — **no SSH, no password**. It:
- lists remote `game_id`s, downloads only ones not already in `raw/`;
- re-validates the schema locally (never trust the server's validation);
- resolves each event's world x/z to a clearing id *if* the map geometry is available, and leaves it
  null otherwise — it must not guess;
- writes `events.jsonl` in the `Observation` shape `PERCEPTION_SPEC.md` §2 already specifies
  (`t`, `source`, `kind`, `payload`, `confidence`, `evidence`), with `source: "lua"` and
  `confidence: 1.0`, so live-captured games drop straight into the existing corpus;
- is idempotent and safe to re-run.

---

## 7. What this does not do

- **It cannot record a game you joined.** TTS runs Lua on the host only (`LuaGlobal::Init` returns
  early when `IsClient` — measured). It records games hosted on RTT, by anyone, whenever that host
  presses EXPORT. That is the tournament corpus; it is not every game.
- **It does not replace the video reader.** It makes it cheaper: a hosted game now yields exact state
  and screen frames at once, which is free labelled data for the CV path.
