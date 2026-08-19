"""
build.py — compile Root Tabletop Tournament.

    base mod  ->  ordered modifications (mods/registry.py)  ->  dist/  +  installed TTS save

The base is the cached "Root - Ultimate Collection" workshop file. It is read
from the local TTS cache (or from ./base/ if you have pinned a copy there) and is
NEVER committed to the repo — the repo holds only our modifications and this
build system. Run:

    python build.py

Nothing existing is overwritten except this project's own output (unique names).
"""

import hashlib
import json
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from mods import registry  # noqa: E402

HOME = os.path.expanduser("~")
TTS = os.path.join(HOME, "Documents", "My Games", "Tabletop Simulator")
SAVES = os.path.join(TTS, "Saves")

WORKSHOP_ID = "2516434159"
CACHE_JSON = os.path.join(TTS, "Mods", "Workshop", WORKSHOP_ID + ".json")
CACHE_PNG = os.path.join(TTS, "Mods", "Workshop", WORKSHOP_ID + ".png")
LOCAL_BASE = os.path.join(HERE, "base", WORKSHOP_ID + ".json")
LOCAL_PNG = os.path.join(HERE, "base", WORKSHOP_ID + ".png")

DIST = os.path.join(HERE, "dist")
OUT_NAME = "Root_Tabletop_Tournament"
EXPECTED_VERSION = "v13.3"
LOCK = os.path.join(HERE, "base.lock")


def _sha(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def read_base():
    path = LOCAL_BASE if os.path.exists(LOCAL_BASE) else CACHE_JSON
    if not os.path.exists(path):
        raise SystemExit(
            "Base mod not found. Subscribe to 'Root - Ultimate Collection' in TTS "
            f"(so it is cached at {CACHE_JSON}), or drop a copy at {LOCAL_BASE}."
        )
    with open(path, "r", encoding="utf-8-sig") as f:
        return f.read(), path


def png_source():
    for p in (LOCAL_PNG, CACHE_PNG):
        if os.path.exists(p):
            return p
    return None


def check_base(raw):
    """Pin the base version+hash on first build; warn if it has drifted since,
    because our anchors are positional and an upstream update can move them."""
    doc = json.loads(raw)
    version = doc.get("VersionNumber")
    digest = _sha(raw)
    if not os.path.exists(LOCK):
        with open(LOCK, "w", encoding="utf-8") as f:
            json.dump({"version": version, "sha256": digest}, f, indent=2)
        print(f"[base] pinned {version} ({digest[:12]})")
    else:
        with open(LOCK, encoding="utf-8") as f:
            lock = json.load(f)
        if lock.get("sha256") != digest:
            print("[base] WARNING: base has changed since it was pinned!")
            print(f"       pinned : {lock.get('version')} {str(lock.get('sha256'))[:12]}")
            print(f"       current: {version} {digest[:12]}")
            print("       Modification anchors may have shifted — verify the build.")
        else:
            print(f"[base] matches pin {version} ({digest[:12]})")
    if version != EXPECTED_VERSION:
        print(f"[base] note: mods were written against {EXPECTED_VERSION}; base reports {version}")


def _faction_selection_script(doc):
    def walk(objs):
        for x in objs:
            if "function setupFaction(category,name,color,random)" in (x.get("LuaScript") or ""):
                return x
            r = walk(x.get("ContainedObjects") or [])
            if r:
                return r
        return None
    return walk(doc["ObjectStates"])


def verify_no_dangling_refs(text):
    """After removals, ensure no remaining UI button or literal spawn call points
    at an EVERYTHING entry that no longer exists. Returns a list of problems."""
    obj = _faction_selection_script(json.loads(text))
    if obj is None:
        raise SystemExit("verify: Faction Selection script not found")
    lua = obj.get("LuaScript") or ""
    xml = obj.get("XmlUI") or ""

    defined = set(re.findall(r"EVERYTHING\['([^']+)'\]\['([^']+)'\] =", lua))
    handler_cat = {"makeTool": "Tools", "makeMap": "Maps",
                   "makeDeck": "Decks", "makeScenario": "Scenarios"}
    problems = []

    for b in re.findall(r"<Button\b[^>]*?/>", xml):
        oc = re.search(r'onclick\s*=\s*"([^"]+)"', b)
        idm = re.search(r'\bid\s*=\s*"([^"]+)"', b)
        if oc and idm and oc.group(1) in handler_cat:
            cat, iid = handler_cat[oc.group(1)], idm.group(1)
            if (cat, iid) not in defined:
                problems.append("button onclick=%s id=%r has no EVERYTHING['%s'][%r]"
                                % (oc.group(1), iid, cat, iid))

    # literal auto-spawn calls in the Lua (variable-driven calls can't be checked)
    for cat, nm in re.findall(r'makeSpecial(?:WithTags?|Card)?\("([^"]+)",\s*"([^"]+)"', lua):
        if (cat, nm) not in defined:
            problems.append("makeSpecial(%r,%r) -> missing entry" % (cat, nm))
    for cat, nm in re.findall(r'setupFaction\("([^"]+)",\s*"([^"]+)"', lua):
        if (cat, nm) not in defined:
            problems.append("setupFaction(%r,%r) -> missing entry" % (cat, nm))
    for nm in re.findall(r'makeTool\([^,]*,[^,]*,\s*"([^"]+)"\)', lua):
        if ("Tools", nm) not in defined:
            problems.append("makeTool(...,%r) -> missing EVERYTHING['Tools'][%r]" % (nm, nm))

    return sorted(set(problems))


def main():
    raw, path = read_base()
    print(f"[base] {len(raw):,} chars <- {path}")
    check_base(raw)

    base_problems = set(verify_no_dangling_refs(raw))
    if base_problems:
        print("[base] %d pre-existing dangling ref(s) in base (ignored)" % len(base_problems))

    text = raw
    for mod in registry.MODS:
        before = text
        text = mod.apply(text)
        tag = "changed" if text != before else "NO-OP"
        print(f"[mod ] {getattr(mod, 'NAME', mod.__name__)} ({tag})")

    json.loads(text)  # fail loudly if any mod produced invalid JSON
    print("[ok  ] output re-parses as valid JSON")

    new_problems = sorted(set(verify_no_dangling_refs(text)) - base_problems)
    if new_problems:
        print("[VERIFY] %d NEW dangling reference(s) introduced by the removals:" % len(new_problems))
        for p in new_problems[:50]:
            print("   -", p)
        raise SystemExit("Build aborted: fix the mod (remove the caller too, or keep that data).")
    print("[ok  ] no new dangling references")

    os.makedirs(DIST, exist_ok=True)
    out_json = os.path.join(DIST, OUT_NAME + ".json")
    with open(out_json, "w", encoding="utf-8", newline="") as f:
        f.write(text)
    png = png_source()
    if png:
        shutil.copy2(png, os.path.join(DIST, OUT_NAME + ".png"))

    shutil.copy2(out_json, os.path.join(SAVES, OUT_NAME + ".json"))
    if png:
        shutil.copy2(png, os.path.join(SAVES, OUT_NAME + ".png"))

    save_name = json.loads(text).get("SaveName")
    print(f"[dist] {out_json}")
    print(f"[save] installed -> {os.path.join(SAVES, OUT_NAME + '.json')}")
    print(f"[done] {len(registry.MODS)} mod(s) applied; SaveName = {save_name!r}")
    print(f"       In TTS: Games -> Save & Load -> {save_name!r}")


if __name__ == "__main__":
    main()
