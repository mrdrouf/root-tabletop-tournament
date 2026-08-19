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


# --- removal helpers (operate on the raw JSON text) --------------------------
#
# In the raw workshop JSON the Lua/XML live inside JSON string values, so a Lua
# newline is the two characters backslash-n ("\\n" in Python) and an XML quote is
# backslash-quote ("\\\"" in Python). The anchors below account for that.

def remove_everything_entry(text, category, name):
    """Delete the whole `EVERYTHING['category']['name'] = { ... }` data block
    from the main script. Bounds it from its header to the next top-level
    EVERYTHING header (or the #include close marker)."""
    header = "\\n" + "EVERYTHING['%s']['%s'] =" % (category, name)
    i = text.find(header)
    if i == -1:
        raise BuildError("EVERYTHING entry not found: %s / %s" % (category, name))
    j = text.find("\\nEVERYTHING['", i + len(header))
    if j == -1:
        j = text.find("\\n----#include", i + len(header))
    if j == -1:
        raise BuildError("could not bound entry: %s / %s" % (category, name))
    return text[:i] + text[j:]


def remove_xml_buttons(text, item_id):
    """Delete every `<Button ... id="item_id" ... />` element from the XmlUI.
    Returns (new_text, count_removed)."""
    anchor = 'id=\\"%s\\"' % item_id           # id=\"Battle Dice\" in the raw file
    count = 0
    while True:
        k = text.find(anchor)
        if k == -1:
            break
        start = text.rfind("<Button", 0, k)
        end = text.find("/>", k)
        if start == -1 or end == -1:
            raise BuildError("malformed <Button> around id=%r" % item_id)
        text = text[:start] + text[end + 2:]
        count += 1
    return text, count


def remove_lua_function(text, funcname):
    """Delete a top-level `function funcname(...) ... end` block — a function
    declared at column 0 whose closing `end` is also at column 0 (inner block
    `end`s are indented, so they are skipped)."""
    start = "\\nfunction %s(" % funcname
    i = text.find(start)
    if i == -1:
        raise BuildError("lua function not found: %s" % funcname)
    j = text.find("\\nend\\n", i + len(start))
    if j == -1:
        raise BuildError("could not find closing end of function: %s" % funcname)
    return text[:i] + text[j + len("\\nend"):]


def remove_lua_line(text, needle):
    """Remove the single line that contains `needle` (given as a raw / JSON-
    escaped substring). Bounds the line by its surrounding \\n markers."""
    k = text.find(needle)
    if k == -1:
        raise BuildError("line needle not found: %r" % needle)
    start = text.rfind("\\n", 0, k)
    end = text.find("\\n", k)
    if start == -1 or end == -1:
        raise BuildError("could not bound line for: %r" % needle)
    return text[:start] + text[end:]


def remove_item(text, category, name, *, require_button=True):
    """Remove a menu item completely: its XML button(s) and its EVERYTHING data
    block. Returns text. Raises if the data block is missing; if require_button
    and no button was found, raises too (guards against a silent no-op)."""
    text, n = remove_xml_buttons(text, name)
    if require_button and n == 0:
        raise BuildError("no XML button found for %r" % name)
    return remove_everything_entry(text, category, name)
