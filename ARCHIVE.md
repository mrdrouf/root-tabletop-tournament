# RTT Game Archive — recording a game and shipping it to adriendavernas.com

**Status:** spec, 2026-09-12. This file is the CONTRACT. The Lua recorder, the PHP endpoint and the
local fetcher are written against it independently and must not disagree.

The mod records what happens on the table during a game and, when the maintainer presses EXPORT on
the box score, POSTs one JSON document to a server he controls. A local tool pulls those documents
down, validates them and files them into a corpus the solver can train on.

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
it is public.** `dist/Root_Tabletop_Tournament.json` is committed to GitHub. There is therefore no
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

  // full board at each turn boundary, DELTA-ENCODED against the previous snapshot
  // rows: [guid, x, z, ry, stateId, qty, faceDown]
  "snapshots": [
    {"t": 61.0, "seq": 42, "turn": "Red", "round": 1, "full": 1, "rows": [["79bf39", 3.2, -8.6, 180.0, -1, 1, -1]]},
    {"t": 210.5, "seq": 88, "turn": "Blue", "round": 1, "full": 0, "rows": [["a1b2c3", 9.0, 1.1, 0.0, -1, 1, -1]],
     "gone": ["79bf39"]}
  ]
}
```

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

- **Public information only.** Hand *sizes* may be recorded; hand *contents* never. Face-down cards
  record `faceDown: 1` and their GUID, never their face. No Corvid plots, no Alliance supporters, no
  deck order. `PERCEPTION_SPEC.md` §3.4 — this is the four-line whitelist that separates a study tool
  from a cheat tool.
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

**Visibility.** On a successful send, `broadcastToAll("Game archived.", ...)`. The host pressed a
button and the table is told where the data went. This is not optional.

---

## 5. Server (`adriendavernas.com`)

Bluehost shared hosting: Apache, PHP, home `/home2/adrienda`, web root `~/public_html`.

```
public_html/rtt/ingest.php      POST, public, no secret (see §0)
public_html/rtt/admin.php       GET,  requires ADMIN_KEY — list / fetch / delete
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
  config.json        # {"endpoint": "...", "admin_key": "..."} — GITIGNORED
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
