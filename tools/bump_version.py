#!/usr/bin/env python3
"""Raise the mod's build number, stamp it on the setup board, and rebuild.

There is ONE version and it belongs to the mod. The box score used to be a separate project with its
own life; it ships inside the mod now, so it does not get a number of its own -- the maintainer,
2026-09-07: "do not have a boxscore version since now we only work with boxscore integrated to the
mod."

VERSION is a plain integer that only ever goes up, so two people can tell in one glance whether they
are on the same build. It is written into bab7e1's saved XmlUI as a cream line in the board's top
right corner, opposite the Root logo. The board never rewrites its own XML -- it only ever calls
setAttribute on elements that are already there -- so a static element survives the game.

Run by the pre-commit hook (tools/hooks/pre-commit), so every commit, and therefore every push,
carries a number nobody has seen before. Run it by hand only to repair a stamp.
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
CREAM = "#F9E6BB"          # the mod's one cream
ANCHOR = '<Image id="rootLogo"'

# Top right, opposite the logo. The board's UI runs x -95..117 and y -88..80, so this sits in the
# corner without touching the (inactive) close button at 117.
#
# WHY THE PANEL. Object XmlUI is rendered once and then magnified onto the object, and this board is
# scale 15.5, so type set at its final size comes out soft -- the maintainer, 2026-09-07: "the version
# number is out of focus and too big". Drawing it large inside a panel scaled down by SHRINK gives
# 1/SHRINK times the pixels for the same footprint, which is the same trick the turn panel uses to
# stay crisp. Effective size on the board is FONT * SHRINK; raise FONT and lower SHRINK together for
# a sharper line, change FONT alone to resize it.
SHRINK = 0.2
FONT = 34                      # 34 * 0.2 = 6.8 on the board, against the 12 it replaced
ELEMENT = ('<Panel id="rttVersion" position="94 80 -20" width="220" height="70" '
           'scale="%s %s 1" color="#00000000" raycastTarget="false">'
           '<Text text="v%%d" fontSize="%d" color="%s" alignment="MiddleRight"/>'
           '</Panel>') % (SHRINK, SHRINK, FONT, CREAM)
PATTERN = re.compile(r'<Panel id="rttVersion".*?</Panel>', re.S)


def read_version():
    if not os.path.exists(VERSION_FILE):
        return 0
    return int(open(VERSION_FILE, encoding="utf-8").read().strip() or 0)


def stamp(n):
    """Write v<n> onto the board. Replaces the line if it is there, inserts it if it is not."""
    raw = open(SAVE, "rb").read().decode("utf-8")
    doc = json.loads(raw)
    board = next(o for o in doc["ObjectStates"] if o.get("GUID") == BOARD)
    xml = board["XmlUI"]
    line = ELEMENT % n
    if PATTERN.search(xml):
        xml = PATTERN.sub(line, xml, count=1)
    else:
        i = xml.index(ANCHOR)
        xml = xml[:i] + line + "\n" + xml[i:]
    board["XmlUI"] = xml
    out = json.dumps(doc, indent=2, ensure_ascii=False).replace("\n", "\r\n")
    open(SAVE, "wb").write(out.encode("utf-8"))


def main():
    n = read_version()
    if "--current" in sys.argv:
        print(n)
        return 0
    if "--restamp" not in sys.argv:
        n += 1
    open(VERSION_FILE, "w", encoding="utf-8").write("%d\n" % n)
    stamp(n)
    subprocess.run([sys.executable, os.path.join(REPO, "gen", "assemble.py")],
                   check=True, capture_output=True)
    built = os.path.join(REPO, "gen", "build", "Root_Tabletop_Tournament.json")
    dist = os.path.join(REPO, "dist", "Root_Tabletop_Tournament.json")
    open(dist, "wb").write(open(built, "rb").read())
    if "--quiet" not in sys.argv:
        print("[version] v%d stamped on the board and built" % n)
    return 0


if __name__ == "__main__":
    sys.exit(main())
