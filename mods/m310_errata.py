"""
m310 — apply errata from the `errata/` folder.

Card text in TTS is baked into the card-face image (a CustomDeck FaceURL), so an
"erratum" is just corrected face art living at a new URL. Each save you drop into
`errata/` is a corrected object whose cards keep their original CardIDs (and thus
their sheet number and grid positions) but point at a new FaceURL.

This mod scans every `errata/*.json`, and for each CustomDeck sheet it finds, it
looks up that sheet's CURRENT FaceURL in the base and globally repoints it to the
errata URL. Because the CardIDs / grid layout are unchanged, the swap lines up
card-for-card — every copy of those cards (loose, in decks, in draft piles) shows
the corrected text at once. Sheets whose art already matches are skipped.

To add an erratum later: drop the corrected object's save into `errata/` and
rebuild. No code change needed.

Current contents:
  - Decks HL Errata.json — corrected E&P/S&D face sheets (74, 76)
  - Lost City.json       — Lost City landmark card (already matches base = no-op)
"""

import glob
import json
import os

NAME = "apply errata (repoint base cards to corrected face art)"

ERRATA_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "errata")


def _iter_customdecks(obj):
    """Yield every CustomDeck dict in an object, including nested contained ones."""
    if isinstance(obj, dict):
        cd = obj.get("CustomDeck")
        if isinstance(cd, dict):
            yield cd
        for co in obj.get("ContainedObjects") or []:
            yield from _iter_customdecks(co)


def apply(text):
    if not os.path.isdir(ERRATA_DIR):
        return text

    # sheet number -> corrected FaceURL (first one wins if repeated)
    new_faces = {}
    for path in sorted(glob.glob(os.path.join(ERRATA_DIR, "*.json"))):
        data = json.load(open(path, encoding="utf-8"))
        for o in data.get("ObjectStates", []):
            for cd in _iter_customdecks(o):
                for sheet, info in cd.items():
                    face = (info or {}).get("FaceURL")
                    if face:
                        new_faces.setdefault(str(sheet), face)

    applied = []
    for sheet, new_face in new_faces.items():
        tok = '\\"%s\\": {\\"FaceURL\\": \\"' % sheet
        k = text.find(tok)
        if k == -1:
            continue  # this sheet isn't in the base mod
        s = k + len(tok)
        e = text.find('\\"', s)
        old_face = text[s:e]
        if old_face and old_face != new_face:
            n = text.count(old_face)
            text = text.replace(old_face, new_face)
            applied.append((sheet, n))

    if applied:
        print("       [errata] " + ", ".join("sheet %s (%d refs)" % (s, n) for s, n in applied))
    return text
