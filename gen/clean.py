"""
clean.py — compute the SAFE subtraction for the generator: which board Lua chunks (dead functions +
unused/bloat data categories) can be omitted, proven so, and emit the cleaned board Lua.

Safety, layered:
  1. Liveness across the WHOLE mod: a board function is LIVE if reachable (BFS over the board's own
     call graph) from any entry point -- onLoad, any XmlUI onclick, or any name string-dispatched --
     where the reference corpus is EVERY object's LuaScript + XmlUI (catches cross-object c.call).
  2. Bloat data category dropped only if it is read nowhere in the LIVE corpus.
  3. Self-consistency: after removing the exclusion set, assert NO kept text (board kept chunks +
     the rest of the corpus) contains any excluded function name or excluded category -- i.e. nothing
     kept can reference anything dropped. Iterate (un-exclude anything still referenced) to a fixpoint.

Writes gen/src/board.clean.lua and prints the report. Nothing is applied to the build here.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
from tools.lua_chunker import chunk, classify  # noqa: E402

DIST = os.path.join(os.path.dirname(HERE), "dist", "Root_Tabletop_Tournament.json")
# categories RTT keeps; everything else is bloat we never emit (dropped only if proven unreferenced)
KEEP_CATS = {"Standard", "Maps", "Decks", "Landmarks", "Tools"}


def _corpus(objs, out):
    for o in objs:
        out.append(o.get("LuaScript") or "")
        out.append((o.get("XmlUI") or "").replace('\\"', '"'))
        _corpus(o.get("ContainedObjects", []) or [], out)


def main():
    d = json.load(open(DIST, encoding="utf-8"))

    def find(objs, g):
        for o in objs:
            if o.get("GUID") == g:
                return o
            r = find(o.get("ContainedObjects", []) or [], g)
            if r:
                return r
    board = find(d["ObjectStates"], "bab7e1")
    lua = board["LuaScript"]
    chunks, depth = chunk(lua)
    assert depth == 0 and "".join(chunks) == lua, "chunker mismatch"

    # corpus = every object's lua+xml, but replace the board's own lua with '' (we scan chunks instead)
    corpus_parts = []
    _corpus(d["ObjectStates"], corpus_parts)
    corpus_ex_board = "".join(p for p in corpus_parts if p is not lua)  # everything except the board lua

    # function name -> chunk index; build board call-graph words
    func_idx = {}
    for i, ch in enumerate(chunks):
        k, name = classify(ch)
        if k == "function":
            func_idx.setdefault(name, i)
    fnames = set(func_idx)
    word = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
    chunk_words = [set(word.findall(ch)) for ch in chunks]

    # roots: onLoad, onclick targets anywhere, names string-dispatched anywhere in the corpus
    corpus_all = corpus_ex_board + lua
    roots = {"onLoad"}
    roots |= {m for m in re.findall(r'onclick="([^"]+)"', corpus_all.replace('\\"', '"')) if m in fnames}
    for f in fnames:
        if ('"%s"' % f in corpus_all) or ("'%s'" % f in corpus_all):
            roots.add(f)
    roots &= fnames
    # BFS liveness through board function references
    live, stack = set(), list(roots)
    while stack:
        f = stack.pop()
        if f in live:
            continue
        live.add(f)
        for g in chunk_words[func_idx[f]] & fnames:
            if g not in live:
                stack.append(g)
    dead = fnames - live

    # candidate bloat categories = data cats not in KEEP_CATS
    cats = set()
    for ch in chunks:
        k, name = classify(ch)
        if k == "data":
            cats.add(name.split("/")[0])
    bloat = {c for c in cats if c not in KEEP_CATS and c != "?"}

    # any data block referenced (e.g. by setupFaction('cat','name')) must be kept even if its
    # category is bloat -- the build's own dangling-ref check is the oracle for that below.
    force_keep = set()

    # build the initial exclusion chunk set: dead-function chunks + bloat-category data chunks
    def excluded_chunk(i):
        k, name = classify(chunks[i])
        if k == "function" and name in dead:
            return True
        if k == "data":
            if "/" not in name:
                return False                           # unparseable / master EVERYTHING={} init -> keep
            cat, sub = name.split("/", 1)
            if cat in bloat:
                if name in force_keep:
                    return False                       # explicitly-kept block (referenced)
                # keep the category's `= {}` initializer if ANY of its blocks is kept, else
                # `EVERYTHING['cat']['x'] = ...` indexes a nil table and crashes at load
                if sub == "<init>" and cat in {k.split("/")[0] for k in force_keep}:
                    return False
                return True
        return False

    # self-consistency fixpoint: nothing kept may reference an excluded name/category
    while True:
        excl = {i for i in range(len(chunks)) if excluded_chunk(i)}
        kept_text = corpus_ex_board + "".join(chunks[i] for i in range(len(chunks)) if i not in excl)
        changed = False
        # any dead function still referenced by kept text -> resurrect (mark live)
        for f in list(dead):
            if re.search(r"(?<![A-Za-z0-9_])" + re.escape(f) + r"(?![A-Za-z0-9_])", kept_text):
                dead.discard(f); live.add(f); changed = True
        # any bloat category still read by kept text -> keep it
        for c in list(bloat):
            if ("EVERYTHING['%s']" % c) in kept_text:
                bloat.discard(c); changed = True
        if not changed:
            break

    # dangling-ref fixpoint: assemble a trial dist, run the build's own dangling-ref check, and KEEP
    # any data block it reports missing (referenced via setupFaction/makeFaction/button string args
    # that a plain text scan can't see). Iterate until the build is clean of NEW dangling refs.
    sys.path.insert(0, os.path.join(os.path.dirname(HERE), "mods"))
    import build as _B  # mods/build.py
    save = json.load(open(DIST, encoding="utf-8"))
    ref_dangling = set(_B.verify_no_dangling_refs(json.dumps(save)))

    def find2(objs, g):
        for o in objs:
            if o.get("GUID") == g:
                return o
            r = find2(o.get("ContainedObjects", []) or [], g)
            if r:
                return r
    for _ in range(20):
        excl = {i for i in range(len(chunks)) if excluded_chunk(i)}
        clean = "".join(chunks[i] for i in range(len(chunks)) if i not in excl)
        find2(save["ObjectStates"], "bab7e1")["LuaScript"] = clean
        new = set(_B.verify_no_dangling_refs(json.dumps(save))) - ref_dangling
        added = False
        for ref in new:
            m = re.search(r"\('([^']+)','((?:[^'\\]|\\.)*)'\)", ref)
            if m:
                key = "%s/%s" % (m.group(1), m.group(2))
                if key not in force_keep:
                    force_keep.add(key); added = True
        if not added:
            break

    excl = {i for i in range(len(chunks)) if excluded_chunk(i)}
    clean = "".join(chunks[i] for i in range(len(chunks)) if i not in excl)
    open(os.path.join(HERE, "src", "board.clean.lua"), "w", encoding="utf-8", newline="").write(clean)
    if force_keep:
        print("kept (referenced) despite bloat category:", sorted(force_keep))

    print("board functions: %d | live: %d | dead(dropped): %d" % (len(fnames), len(live), len(dead)))
    print("bloat categories dropped:", sorted(bloat), "| kept cats:", sorted(cats & (KEEP_CATS | {"Official Bots"})))
    print("chunks dropped: %d / %d" % (len(excl), len(chunks)))
    print("board Lua: %d -> %d chars  (%.1f%% smaller)" % (len(lua), len(clean), 100 * (1 - len(clean) / len(lua))))
    # final safety assertion
    kept_text = corpus_ex_board + clean
    for f in dead:
        assert not re.search(r"(?<![A-Za-z0-9_])" + re.escape(f) + r"(?![A-Za-z0-9_])", kept_text), f
    # INIT guard: every category that still has an EVERYTHING['cat']['x']=... assignment MUST keep
    # its EVERYTHING['cat'] = {} initializer, else the assignment indexes a nil table (load crash).
    for cat in set(re.findall(r"EVERYTHING\['([^']+)'\]\['", clean)):
        assert ("EVERYTHING['%s'] = {}" % cat) in clean, "MISSING INIT for '%s' (would crash at load)" % cat
    print("SAFETY OK: no kept code references any dropped function/category; every category init kept")


if __name__ == "__main__":
    main()
