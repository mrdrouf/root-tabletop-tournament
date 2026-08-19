"""
Reusable text-level transforms for building Root Tabletop Tournament (RTT) on
top of the "Root - Ultimate Collection" base mod.

Every modification is a plain function `apply(text: str) -> str` that operates on
the RAW workshop-JSON text. We never re-serialize the 12.9 MB file: edits are
surgical string splices, so the output stays byte-identical to the base except
for exactly what a modification changes. build.py re-validates the whole file as
JSON after all mods run.

Mod authors write literal Lua; `esc()` handles JSON-escaping so you never hand-
write \\n or \\".
"""

import json
import re


class BuildError(Exception):
    """Raised when an anchor cannot be found / is not unique, so a broken build
    fails loudly instead of silently producing a no-op."""


# --- anchors into the mod's main script (object nicknamed "Faction Selection") ---
SETUP_SIG = "function setupFaction(category,name,color,random)"
SETUP_OBJECTS = "objects = EVERYTHING[category][name]['data']"


def esc(lua_snippet):
    """JSON-escape a literal Lua snippet so it can be spliced into a LuaScript
    string value. json.dumps(...)[1:-1] yields the escaped body without the
    surrounding quotes; when TTS decodes the JSON it gets the snippet verbatim."""
    return json.dumps(lua_snippet)[1:-1]


def _replace_field(text, key, new_value):
    pattern = r'("' + re.escape(key) + r'":\s*)"[^"]*"'
    new, n = re.subn(pattern, lambda m: m.group(1) + json.dumps(new_value), text, count=1)
    if n != 1:
        raise BuildError(f'field "{key}" not found exactly once')
    return new


def rename_save(text, new_name):
    """Set the top-level SaveName (what shows in the TTS load list)."""
    return _replace_field(text, "SaveName", new_name)


def set_gamemode(text, new_name):
    """Set the top-level GameMode label."""
    return _replace_field(text, "GameMode", new_name)


def splice_after_unique(text, anchor, lua_snippet):
    """Insert `lua_snippet` (literal Lua) immediately after `anchor`. The anchor
    must appear exactly once and must be escaping-neutral (no ", \\, or newline)."""
    count = text.count(anchor)
    if count != 1:
        raise BuildError(f"anchor not unique ({count}x): {anchor!r}")
    i = text.index(anchor) + len(anchor)
    return text[:i] + esc(lua_snippet) + text[i:]


def splice_into_setup_faction(text, lua_snippet):
    """Insert `lua_snippet` right after the objects-assignment inside
    setupFaction() — the standard Faction-Selector spawn path
    (makeFaction -> setupFaction). Used for per-faction spawn tweaks."""
    if text.count(SETUP_SIG) != 1:
        raise BuildError("setupFaction signature not found exactly once")
    i_sig = text.index(SETUP_SIG)
    i_obj = text.find(SETUP_OBJECTS, i_sig)
    if i_obj == -1:
        raise BuildError("objects-assignment not found inside setupFaction")
    i = i_obj + len(SETUP_OBJECTS)
    return text[:i] + esc(lua_snippet) + text[i:]
