# Root Tabletop Tournament (RTT)

A tournament-oriented fork of the **Root – Ultimate Collection** Tabletop
Simulator mod, built as an ordered **sequence of modifications** on top of an
untouched base — not as a hand-edited copy of the mod's 12.9 MB save file.

**The initial build is an exact copy of the base**, rebranded as *Root Tabletop
Tournament*. It is the anchor point from which every later change is layered.
(Release/version numbers are tracked outside this repo.)

## Why it is built this way

The base mod is a single ~12.9 MB JSON save whose logic is one 11.4 MB Lua script
on the object nicknamed *Faction Selection*. Hand-editing that blob is unworkable
and produces no meaningful git diffs — this is essentially what stranded the
original mod's maintainers. So here the **source of truth is the base plus a list
of small modification steps**, and `build.py` compiles them into the installable
mod. You diff and review the *steps*, never the blob.

One caveat carried over from the base: it contains **2 Unity AssetBundles** (a
decorative table border). AssetBundles are the one component that needs the Unity
Editor + TTS SDK to change; everything else — all Lua, cards, boards, pieces,
UI — is editable here with no compile step. The border is cosmetic, so this does
not constrain gameplay modifications.

## Layout

```
root_tabletop_tournament/
  build.py              base + ordered mods -> dist/ + install to TTS Saves
  base.lock             pinned base version + hash (committed; no mod content)
  mods/
    framework.py        splice/rename helpers (write literal Lua, auto-escaped)
    registry.py         MODS = the ordered, enabled modification list
    m000_identity.py    rename to Root Tabletop Tournament (no gameplay change)
    m010_no_marquise_dice.py   worked EXAMPLE (disabled) of a spawn tweak
  dist/                 build output (gitignored)
  base/                 optional pinned copy of the base mod (gitignored — IP)
```

The base mod is **not committed** (it is Leder Games + the original authors' IP).
`build.py` reads it from the local TTS cache
(`~/Documents/My Games/Tabletop Simulator/Mods/Workshop/2516434159.json`), so the
repo contains only our own work and is safe to keep private.

## Build

```
python build.py
```

This reads the base, applies every enabled mod in order, re-validates the result
as JSON, writes `dist/Root_Tabletop_Tournament.json`, and installs a loadable
copy into the TTS Saves folder.

## Load / test in TTS

**Games → Save & Load →** load **“Root Tabletop Tournament”** (load fresh;
don't continue an already-open game).

## Adding the next modification

1. Create `mods/mNNN_short_name.py`:

   ```python
   from . import framework

   NAME = "what this step does"

   def apply(text):
       # literal Lua; framework escapes it for you
       return framework.splice_into_setup_faction(text, '''
           -- your Lua here
       ''')
   ```

2. Import it in `mods/registry.py` and append it to `MODS` in the right order.
3. `python build.py` and test in TTS.

Helpers in `framework.py`: `rename_save`, `set_gamemode`,
`splice_after_unique(text, anchor, lua)`, and
`splice_into_setup_faction(text, lua)` (the standard Faction-Selector spawn path,
`makeFaction → setupFaction`). Each raises `BuildError` if its anchor is missing
or ambiguous, so a broken step fails the build instead of silently doing nothing.

## Base version

Mods are written against base **v13.3**, pinned in `base.lock`. If the upstream
mod updates, `build.py` warns that anchors may have shifted; re-verify affected
steps against the new base.

## Sharing / IP

This repository contains only our build tooling — **no mod content** — so it is
safe to be public. What must **not** be redistributed publicly is the *compiled
mod* (the `dist/` save, or a Workshop upload): that carries Leder Games' Root IP
and the original authors' work. Keep those within your group / tournament and seek
the original authors' blessing + credit before any public release. `build.py`
reads the base from your local TTS cache, and `dist/` and `base/` are gitignored,
so none of that content ever lands in git. See `CHANGELOG.md` for provenance.
