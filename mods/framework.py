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


def set_button_position_in_group(text, group_id, button_id, position):
    """Set position="..." on <Button id="button_id"/> but only inside the given
    <ToggleGroup id="group_id">, so same-named buttons on other screens are not
    touched. Returns (new_text, count)."""
    gstart = text.find('<ToggleGroup id=\\"%s\\"' % group_id)
    if gstart == -1:
        raise BuildError("ToggleGroup %r not found" % group_id)
    gend = text.find('</ToggleGroup>', gstart)
    if gend == -1:
        raise BuildError("unterminated ToggleGroup %r" % group_id)
    block = text[gstart:gend]
    new_block, n = set_button_attr(block, button_id, "position", position)
    return text[:gstart] + new_block + text[gend:], n


def remove_xml_buttons_by_onclick(text, onclick_value):
    """Delete every <Button ... onclick="onclick_value" .../> (handles onclick and
    onClick). For nav buttons that have no id. Returns (new_text, count)."""
    count = 0
    for oc in ("onclick", "onClick"):
        anchor = '%s=\\"%s\\"' % (oc, onclick_value)
        while True:
            k = text.find(anchor)
            if k == -1:
                break
            start = text.rfind("<Button", 0, k)
            end = text.find("/>", k)
            if start == -1 or end == -1 or ">" in text[start:k]:
                raise BuildError("malformed <Button> for %s=%r" % (oc, onclick_value))
            text = text[:start] + text[end + 2:]
            count += 1
    return text, count


def add_button_to_group(text, group_id, button_xml):
    """Insert a <Button.../> (written with normal quotes) just after the opening
    tag of <ToggleGroup id="group_id">. button_xml is JSON-escaped for you."""
    anchor = '<ToggleGroup id=\\"%s\\"' % group_id
    i = text.find(anchor)
    if i == -1:
        raise BuildError("ToggleGroup %r not found" % group_id)
    j = text.find(">", i)
    if j == -1:
        raise BuildError("unterminated <ToggleGroup %r>" % group_id)
    j += 1
    return text[:j] + esc("\n  " + button_xml) + text[j:]


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


QT = '\\"'  # the two raw characters backslash+quote = one JSON-escaped " in the text


def _toggle_group_span(text, gid):
    """Return (start, end) raw indices of <ToggleGroup ...id=gid...> ... </ToggleGroup>,
    matching nested ToggleGroups so the close is the group's own. Tolerates spacing
    variants (id="x" or id = "x")."""
    idx = 0
    while True:
        s = text.find("<ToggleGroup", idx)
        if s == -1:
            raise BuildError("ToggleGroup %r not found" % gid)
        e = text.find(">", s)
        tag = text[s:e + 1]
        if ('id=%s%s%s' % (QT, gid, QT)) in tag or ('id = %s%s%s' % (QT, gid, QT)) in tag:
            break
        idx = e + 1
    depth = 0
    j = s
    while j < len(text):
        o = text.find("<ToggleGroup", j)
        c = text.find("</ToggleGroup>", j)
        if c == -1:
            raise BuildError("unterminated ToggleGroup %r" % gid)
        if o != -1 and o < c:
            depth += 1
            j = o + len("<ToggleGroup")
        else:
            depth -= 1
            j = c + len("</ToggleGroup>")
            if depth == 0:
                return s, j


def set_toggle_group_active(text, gid, value):
    """Set the default active="value" on a <ToggleGroup id=gid ...> opening tag,
    replacing any existing active attribute or adding one."""
    s = text.find("<ToggleGroup")
    idx = 0
    while True:
        s = text.find("<ToggleGroup", idx)
        if s == -1:
            raise BuildError("ToggleGroup %r not found" % gid)
        e = text.find(">", s)
        tag = text[s:e + 1]
        if ('id=%s%s%s' % (QT, gid, QT)) in tag or ('id = %s%s%s' % (QT, gid, QT)) in tag:
            mk = 'active=%s%s%s' % (QT, value, QT)
            if 'active' in tag:
                a = tag.find('active')
                p = tag.find(QT, a)
                q = tag.find(QT, p + len(QT))
                new_tag = tag[:a] + mk + tag[q + len(QT):]
            else:
                new_tag = tag[:-1].rstrip() + ' ' + mk + '>'
            return text[:s] + new_tag + text[e + 1:]
        idx = e + 1


def _fmt_num(x):
    return str(int(x)) if float(x).is_integer() else ("%g" % x)


def shift_group_buttons_y(text, gid, dy):
    """Add `dy` to the Y (2nd) component of every position="x y z" inside the group
    (rigid vertical translation of the whole block). Returns (new_text, count)."""
    s, e = _toggle_group_span(text, gid)
    block = text[s:e]
    count = 0
    k = block.find('position', 0)
    while k != -1:
        p = block.find(QT, k)
        q = block.find(QT, p + len(QT))
        if p == -1 or q == -1:
            break
        nums = block[p + len(QT):q].split()
        if len(nums) == 3:
            nums[1] = _fmt_num(float(nums[1]) + dy)
            newval = ' '.join(nums)
            block = block[:p + len(QT)] + newval + block[q:]
            count += 1
            k = block.find('position', p + len(QT) + len(newval))
        else:
            k = block.find('position', q)
    return text[:s] + block + text[e:], count


def everything_entry_span(text, category, name):
    """Return (start, end) of the `EVERYTHING['category']['name'] = ... ` data
    block, bounded by the next EVERYTHING assignment header. Use it to SCOPE
    GUID-based edits to one faction (warrior objects are shared by bot copies)."""
    head = "EVERYTHING['%s']['%s'] =" % (category, name)
    h = text.find(head)
    if h == -1:
        raise BuildError("EVERYTHING entry not found: %s / %s" % (category, name))
    m = re.compile(r"EVERYTHING\['[^']+'\]\['[^']+'\] ?=").search(text, h + len(head))
    return h, (m.start() if m else len(text))


def set_data_move_to(text, guid, xyz):
    """Set the `move_to={ x, y, z }` of the data entry whose embedded object has
    this GUID. Requires the GUID field to appear exactly once in `text` — pass a
    span-scoped slice (see everything_entry_span) so bot copies aren't hit."""
    anchor = '\\"GUID\\": \\"%s\\"' % guid
    if text.count(anchor) != 1:
        raise BuildError("GUID %s not unique in scope (%d)" % (guid, text.count(anchor)))
    gp = text.find(anchor)
    ms = text.rfind('move_to={', 0, gp)
    if ms == -1:
        raise BuildError("no move_to before GUID %s" % guid)
    me = text.find('}', ms)
    new = 'move_to={ %.4f, %.4f, %.4f }' % (xyz[0], xyz[1], xyz[2])
    return text[:ms] + new + text[me + 1:]


def clone_data_entry(text, src_guid, new_guid, xyz):
    """Duplicate the `{move_to={...}, json=[[ {..} ]]}` data entry whose object GUID
    is src_guid, give the copy new_guid and move_to xyz, and insert it right after
    the original. Requires src_guid unique in `text` (scope it first)."""
    anchor = '\\"GUID\\": \\"%s\\"' % src_guid
    if text.count(anchor) != 1:
        raise BuildError("src GUID %s not unique in scope (%d)" % (src_guid, text.count(anchor)))
    gp = text.find(anchor)
    start = text.rfind('{move_to={', 0, gp)
    end = text.find(']]}', gp)
    if start == -1 or end == -1:
        raise BuildError("cannot bound data entry for %s" % src_guid)
    end += 3
    entry = text[start:end]
    entry = entry.replace('\\"GUID\\": \\"%s\\"' % src_guid,
                          '\\"GUID\\": \\"%s\\"' % new_guid, 1)
    ms = entry.find('move_to={')
    me = entry.find('}', ms)
    entry = entry[:ms] + 'move_to={ %.4f, %.4f, %.4f }' % (xyz[0], xyz[1], xyz[2]) + entry[me + 1:]
    return text[:end] + ',' + entry + text[end:]


def remove_escaped_object(text, guid):
    """Remove the embedded object `{...}` whose escaped GUID field is `guid`, plus one
    adjacent comma, from `text` (e.g. one warrior out of a bag's ContainedObjects).
    Brace-matches naively (these piece objects carry no braces inside string values);
    the caller / build's JSON re-parse catches any imbalance. Requires the GUID field
    unique in `text` (scope it). Returns (new_text, removed_object_text)."""
    anchor = '\\"GUID\\": \\"%s\\"' % guid
    if text.count(anchor) != 1:
        raise BuildError("GUID %s not unique in scope (%d)" % (guid, text.count(anchor)))
    gp = text.find(anchor)
    start = text.rfind('{', 0, gp)
    if start == -1:
        raise BuildError("no opening brace before GUID %s" % guid)
    depth = 0
    i = start
    n = len(text)
    while i < n:
        c = text[i]
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                i += 1
                break
        i += 1
    if depth != 0:
        raise BuildError("unbalanced braces for object %s" % guid)
    end = i
    obj = text[start:end]
    if ']]' in obj:
        raise BuildError("object %s contains ']]' — unsafe to re-embed" % guid)
    # drop one adjacent comma so the array stays valid
    k = end
    while k < n and text[k] in ' \t\r\n':
        k += 1
    if k < n and text[k] == ',':
        end = k + 1
    else:
        m = start - 1
        while m >= 0 and text[m] in ' \t\r\n':
            m -= 1
        if m >= 0 and text[m] == ',':
            start = m
    return text[:start] + text[end:], obj


def remove_item(text, category, name, *, require_button=True):
    """Remove a menu item completely: its XML button(s) and its EVERYTHING data
    block. Returns text. Raises if the data block is missing; if require_button
    and no button was found, raises too (guards against a silent no-op)."""
    text, n = remove_xml_buttons(text, name)
    if require_button and n == 0:
        raise BuildError("no XML button found for %r" % name)
    return remove_everything_entry(text, category, name)
