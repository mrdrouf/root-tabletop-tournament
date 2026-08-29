"""
lua_chunker — split a top-level Lua script (TTS global script) into ordered chunks, one per
top-level statement (function def, EVERYTHING[...] data assignment, local, comment, etc.).

Correctness guarantee: it splits at newlines where block+bracket depth is 0 and we are not
inside a string/comment. So "".join(chunks) == original (byte-identical), and each chunk starts
and ends at depth 0 -> each is a complete statement. Omitting a chunk removes a whole statement.

Used by the generator to own the board's logic/data as modular pieces and reassemble it, dropping
the dead functions + unused (bloat) data categories additively (they are simply never emitted).
"""
import re

_KW_OPEN = {"function", "if", "for", "while", "repeat"}
# compiled + matched at position (no O(n) slicing of the 4.5MB string)
_LONGB = re.compile(r"\[(=*)\[")
_LONGC = re.compile(r"--\[(=*)\[")
_WORD = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")


def chunk(s):
    """Return (chunks, final_depth). final_depth must be 0 for a balanced script."""
    i, n = 0, len(s)
    depth = 0
    await_do = False          # inside a for/while header awaiting its 'do'
    splits = [0]
    while i < n:
        c = s[i]
        # long-bracket string  [=*[ ... ]=*]
        m = _LONGB.match(s, i) if c == '[' else None
        if m:
            close = ']' + m.group(1) + ']'
            j = s.find(close, m.end())
            i = (j + len(close)) if j != -1 else n
            continue
        # comment  (-- line, or --[=*[ long comment)
        if c == '-' and s[i + 1:i + 2] == "-":
            m2 = _LONGC.match(s, i)
            if m2:
                close = ']' + m2.group(1) + ']'
                j = s.find(close, m2.end())
                i = (j + len(close)) if j != -1 else n
            else:
                j = s.find("\n", i)
                i = j if j != -1 else n   # stop at the newline; the \n itself handled below
            continue
        # quoted string
        if c == '"' or c == "'":
            q = c
            i += 1
            while i < n and s[i] != q:
                if s[i] == "\\":
                    i += 1
                i += 1
            i += 1
            continue
        if c in "{[(":
            depth += 1
            i += 1
            continue
        if c in "}])":
            depth -= 1
            i += 1
            continue
        wm = _WORD.match(s, i)
        if wm:
            w = wm.group(0)
            if w in _KW_OPEN:
                depth += 1
                if w in ("for", "while"):
                    await_do = True
            elif w == "do":
                if await_do:
                    await_do = False
                else:
                    depth += 1
            elif w in ("end", "until"):
                depth -= 1
            elif w == "then":
                await_do = False
            i += len(w)
            continue
        if c == "\n":
            if depth == 0:
                splits.append(i + 1)
            i += 1
            continue
        i += 1
    splits.append(n)
    pts = sorted(set(splits))
    chunks = [s[pts[k]:pts[k + 1]] for k in range(len(pts) - 1)]
    return chunks, depth


def classify(ch):
    t = ch.lstrip()
    if t.startswith("function "):
        m = re.match(r"function\s+([A-Za-z0-9_.:]+)", t)
        return ("function", m.group(1) if m else "?")
    if t.startswith("EVERYTHING"):
        # EVERYTHING['cat']['name'] = ...  OR the table init  EVERYTHING['cat'] = {}
        # (name may contain escaped quotes, e.g. Eyrie\'s End)
        m = re.match(r"EVERYTHING\['([^']+)'\](?:\['((?:[^'\\]|\\.)*)'\])?", t)
        if m:
            return ("data", "%s/%s" % (m.group(1), m.group(2) if m.group(2) is not None else "<init>"))
        return ("data", "?")
    if t.startswith("_G"):
        return ("_G", None)
    if t.startswith("local "):
        return ("local", None)
    if t.startswith("--"):
        return ("comment", None)
    if t.strip() == "":
        return ("blank", None)
    return ("other", t[:40].replace("\n", " "))
