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
    Handles both double-quoted (JSON-escaped) and single-quoted id attributes.
    Returns (new_text, count_removed)."""
    count = 0
    for anchor in ('id=\\"%s\\"' % item_id, "id='%s'" % item_id):
        while True:
            k = text.find(anchor)
            if k == -1:
                break
            start = text.rfind("<Button", 0, k)
            end = text.find("/>", k)
            if start == -1 or end == -1 or ">" in text[start:k]:
                raise BuildError("malformed / mismatched <Button> around id=%r" % item_id)
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


def remove_xml_element(text, tag, marker):
    """Remove every self-closing `<tag ... />` element that contains `marker`
    (a raw / JSON-escaped substring, e.g. an id or image value). Returns
    (new_text, count)."""
    open_tag = "<" + tag
    count = 0
    while True:
        k = text.find(marker)
        if k == -1:
            break
        start = text.rfind(open_tag, 0, k)
        end = text.find("/>", k)
        if start == -1 or end == -1:
            raise BuildError("malformed <%s> around %r" % (tag, marker))
        # safety: the marker must really sit inside this <tag ...> — i.e. no
        # element boundary between the open tag and the marker. This prevents a
        # marker that also appears in Lua (e.g. an asset name) from walking back
        # to an unrelated <tag> and deleting a huge span.
        if ">" in text[start:k]:
            raise BuildError("marker %r is not inside a <%s> element" % (marker, tag))
        text = text[:start] + text[end + 2:]
        count += 1
    return text, count


def replace_unique(text, old, new):
    """Replace `old` with `new`, requiring exactly one occurrence (guards against
    editing the wrong / multiple sites)."""
    n = text.count(old)
    if n != 1:
        raise BuildError("expected exactly 1 occurrence of %r, found %d" % (old, n))
    return text.replace(old, new, 1)


def set_button_attr(text, item_id, attr, new_val):
    """Set attr="new_val" on every <Button ... id="item_id" .../>. Returns
    (new_text, count)."""
    count = 0
    i = 0
    a = '%s=\\"' % attr                         # e.g. height=\"
    while True:
        k = text.find('id=\\"%s\\"' % item_id, i)
        if k == -1:
            break
        start = text.rfind("<Button", 0, k)
        end = text.find("/>", k) + 2
        if start == -1 or end == 1:
            raise BuildError("malformed <Button> around id=%r" % item_id)
        seg = text[start:end]
        p = seg.find(a)
        if p != -1:
            q = seg.find('\\"', p + len(a))     # closing \"
            if q != -1:
                seg = seg[:p] + a + new_val + seg[q:]
                text = text[:start] + seg + text[end:]
                end = start + len(seg)
                count += 1
        i = end
    return text, count


def set_embedded_field(text, guid, field, value):
    """Set the first numeric `"field": <n>` after the given GUID inside an embedded
    object (its json blob lives in a Lua [[...]] string, so its quotes are escaped
    as \\"). Returns (new_text, count). Used e.g. to flip a card's rotZ."""
    anchor = '\\"GUID\\": \\"%s\\"' % guid
    i = text.find(anchor)
    if i == -1:
        raise BuildError("embedded object %s not found" % guid)
    key = '\\"%s\\":' % field
    r = text.find(key, i)
    if r == -1:
        raise BuildError("field %r not found for object %s" % (field, guid))
    r2 = r + len(key)
    while r2 < len(text) and text[r2] == ' ':
        r2 += 1
    e = r2
    while e < len(text) and text[e] not in ',}':
        e += 1
    return text[:r2] + str(value) + text[e:], 1


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


def remove_top_level_object(text, guid):
    """Remove a top-level ObjectStates object by its GUID. Finds the object's
    opening brace via the unique real-quoted "GUID": "<guid>" anchor (the embedded
    copies inside data blobs use escaped \\"GUID\\", so they don't match), then
    brace-matches to the closing brace respecting JSON string literals, and drops
    one adjacent comma so the array stays valid."""
    anchor = '"GUID": "%s"' % guid
    if text.count(anchor) != 1:
        raise BuildError("top-level GUID %s not uniquely found (%d)" % (guid, text.count(anchor)))
    a = text.find(anchor)
    start = text.rfind("{", 0, a)
    if start == -1:
        raise BuildError("no opening brace for GUID %s" % guid)
    depth = 0
    j = start
    n = len(text)
    in_str = False
    while j < n:
        c = text[j]
        if in_str:
            if c == '\\':
                j += 2
                continue
            if c == '"':
                in_str = False
        elif c == '"':
            in_str = True
        elif c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                j += 1
                break
        j += 1
    if depth != 0:
        raise BuildError("unbalanced braces matching GUID %s" % guid)
    end = j
    k = end
    while k < n and text[k] in ' \t\r\n':
        k += 1
    if k < n and text[k] == ',':          # drop trailing comma
        end = k + 1
    else:                                  # or a leading comma
        m = start - 1
        while m >= 0 and text[m] in ' \t\r\n':
            m -= 1
        if m >= 0 and text[m] == ',':
            start = m
    return text[:start] + text[end:]


def remove_item(text, category, name, *, require_button=True):
    """Remove a menu item completely: its XML button(s) and its EVERYTHING data
    block. Returns text. Raises if the data block is missing; if require_button
    and no button was found, raises too (guards against a silent no-op)."""
    text, n = remove_xml_buttons(text, name)
    if require_button and n == 0:
        raise BuildError("no XML button found for %r" % name)
    return remove_everything_entry(text, category, name)
