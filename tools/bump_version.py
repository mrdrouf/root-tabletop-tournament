#!/usr/bin/env python3
"""Raise the mod's version, stamp it on the setup board, and rebuild.

TWO NUMBERS, `<major>.<minor>` -- the maintainer, 2026-09-07: "one is the big version number and the
other one are for all small aesthetic things. when a big funcitonnality is changed then you increase
the number."

    major   a real change in what the mod DOES. Bumped on purpose, never automatically:
                python3 tools/bump_version.py --major
            That only arms it; the next commit lands on <major+1>.0.
    minor   everything else -- a fix, a colour, a nudge. Every commit, without exception.

THE MINOR NEVER SKIPS. "this number cannot be skipped its very important to keep track of versions to
keep track of buggs" -- a version has to name exactly one build, so a bug report names exactly one
build. The pre-commit hook bumps it on every commit, and the pre-push hook walks the commits being
pushed and refuses the push if the sequence has a hole (--check-sequence).

There is ONE version and it belongs to the mod. The box score ships inside it and has none of its own.

The line reads "by MrDrouf v<major>.<minor>" in bab7e1's saved XmlUI, in the board's top right
corner. That is safe as a static element because the board only ever calls setAttribute on elements
that already exist; it never rewrites its own XML.
"""
import json
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERSION_FILE = os.path.join(REPO, "VERSION")
SAVE = os.path.join(REPO, "gen", "src", "save.json")
BOARD = "bab7e1"
# Armed by --major, consumed by the next bump. It lives in .git/ because it is a note to the very
# next commit and nothing else -- it must never travel to anyone or survive a clone.
MAJOR_FLAG = os.path.join(REPO, ".git", "rtt_major_pending")

CREAM = "#F9E6BB"          # the mod's one cream
# The credit line is NOT in it. Cream on the board's pale wood shouted, so it went to the mod's ink
# at 78% alpha -- and that went too far the other way: "write the by MrDrouf in black now it's too
# unreadable" (2026-09-07). Solid black, no alpha. It is small enough at 4.8 to stay quiet without
# being faint; if it needs toning down again, do it with FONT, not with transparency.
INK = "#000000"

# Hard into the top right, opposite the logo. The board's UI reaches about x 124 and y 93 (the close
# button spans to 124.5, the Root logo tops out at 92.5), and the panel scales about its CENTRE.
#
# WHY THE PANEL. Object XmlUI is rendered once and then magnified onto the object, and this board is
# scale 15.5, so type set at its final size comes out soft. Drawing it large inside a panel scaled
# down by SHRINK gives 1/SHRINK times the pixels for the same footprint -- the same trick the turn
# panel uses. Effective size on the board is FONT * SHRINK.
#
# The line is right-ALIGNED, so it grows leftwards as the number gets longer and its right edge stays
# at 120 however many digits it carries.
SHRINK = 0.2
FONT = 24                      # 24 * 0.2 = 4.8 on the board
ELEMENT = ('<Panel id="rttVersion" position="90 87 -20" width="300" height="70" '
           'scale="%s %s 1" color="#00000000" raycastTarget="false">'
           '<Text text="by MrDrouf v%%s" fontSize="%d" color="%s" alignment="MiddleRight"/>'
           '</Panel>') % (SHRINK, SHRINK, FONT, INK)
PATTERN = re.compile(r'<Panel id="rttVersion".*?</Panel>', re.S)


def parse(text):
    """'1.6' -> (1, 6). A bare '6' is read as 1.6, so the count carries over from the old scheme."""
    text = (text or "").strip()
    if not text:
        return 1, 0
    if "." not in text:
        return 1, int(text)
    major, minor = text.split(".", 1)
    return int(major), int(minor)


def read_version(path=VERSION_FILE):
    if not os.path.exists(path):
        return 1, 0
    return parse(open(path, encoding="utf-8").read())


def stamp(label):
    """Write the line onto the board. Replaces it if it is there, inserts it if it is not."""
    doc = json.loads(open(SAVE, "rb").read().decode("utf-8"))
    board = next(o for o in doc["ObjectStates"] if o.get("GUID") == BOARD)
    xml = board["XmlUI"]
    line = ELEMENT % label
    if PATTERN.search(xml):
        xml = PATTERN.sub(line, xml, count=1)
    else:
        i = xml.index('<Image id="rootLogo"')
        xml = xml[:i] + line + "\n" + xml[i:]
    board["XmlUI"] = xml
    out = json.dumps(doc, indent=2, ensure_ascii=False).replace("\n", "\r\n")
    open(SAVE, "wb").write(out.encode("utf-8"))


def build():
    subprocess.run([sys.executable, os.path.join(REPO, "gen", "assemble.py")],
                   check=True, capture_output=True)
    built = os.path.join(REPO, "gen", "build", "Root_Tabletop_Tournament.json")
    dist = os.path.join(REPO, "dist", "Root_Tabletop_Tournament.json")
    open(dist, "wb").write(open(built, "rb").read())


def version_at(rev):
    """The version recorded by one commit, or None if it carried no VERSION file."""
    r = subprocess.run(["git", "-C", REPO, "show", "%s:VERSION" % rev], capture_output=True)
    if r.returncode != 0:
        return None
    return parse(r.stdout.decode("utf-8", errors="replace"))


def check_sequence(rng):
    """Refuse a range whose minor numbers have a hole. Returns a complaint, or ''."""
    out = subprocess.run(["git", "-C", REPO, "rev-list", "--reverse", "--no-merges", rng],
                         capture_output=True)
    if out.returncode != 0:
        return ""                                  # unknown range: let the push through
    shas = out.stdout.decode().split()
    prev = None
    for sha in shas:
        cur = version_at(sha)
        if cur is None:                            # predates versioning
            continue
        if prev is not None:
            ok = (cur[0] == prev[0] and cur[1] == prev[1] + 1) or \
                 (cur[0] == prev[0] + 1 and cur[1] == 0)
            if not ok:
                return ("v%d.%d -> v%d.%d at %s: the minor must go up by exactly one, or the major "
                        "by one and the minor back to 0." % (prev[0], prev[1], cur[0], cur[1], sha[:9]))
        prev = cur
    return ""


def main():
    argv = sys.argv[1:]

    if "--check-sequence" in argv:
        rng = argv[argv.index("--check-sequence") + 1]
        complaint = check_sequence(rng)
        if complaint:
            print("version sequence has a hole: %s" % complaint, file=sys.stderr)
            return 1
        return 0

    major, minor = read_version()

    if "--major" in argv:
        open(MAJOR_FLAG, "w", encoding="utf-8").write("1\n")
        print("[version] armed: the next commit lands on v%d.0" % (major + 1))
        return 0

    if "--current" in argv:
        print("%d.%d" % (major, minor))
        return 0

    if "--restamp" not in argv:
        if os.path.exists(MAJOR_FLAG):
            major, minor = major + 1, 0
            os.remove(MAJOR_FLAG)
        else:
            minor += 1

    label = "%d.%d" % (major, minor)
    open(VERSION_FILE, "w", encoding="utf-8").write(label + "\n")
    stamp(label)
    build()
    if "--quiet" not in argv:
        print("[version] v%s stamped on the board and built" % label)
    return 0


if __name__ == "__main__":
    sys.exit(main())
