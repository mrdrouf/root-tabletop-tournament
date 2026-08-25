"""
m445 — remove the landmarks the Marsh map spawns.

The Marsh Map data spawns 3 landmark models (Mousehold, Rabbit-town, Foxburrow, at
z~24) and their 3 reference cards (z~28.5). The RTT tournament doesn't use them, so
drop those 6 data entries. They occupy a clean region of the board (x 4..16, z 23..29)
with nothing else there, so we remove every Marsh data entry whose move_to falls in it.
"""
from . import framework


NAME = "remove Marsh map landmarks (Mousehold / Rabbit-town / Foxburrow + cards)"


def apply(text):
    start = text.find("EVERYTHING['Maps']['Marsh Map']")
    if start == -1:
        raise framework.BuildError("Marsh Map data not found")
    end = text.find("EVERYTHING['", start + 40)
    if end == -1:
        raise framework.BuildError("could not bound Marsh Map data")
    block = text[start:end]

    dstart = block.find("data={")
    if dstart == -1:
        raise framework.BuildError("Marsh Map data list not found")

    # split into {move_to={...}...]==]} entries
    entries = []
    pos = block.find("{move_to={", dstart)
    first = pos
    while pos != -1:
        e = block.find("]]}", pos)
        if e == -1:
            raise framework.BuildError("unterminated Marsh entry")
        e += len("]]}")
        coords = block[pos + len("{move_to={"):block.find("}", pos)]
        parts = [p.strip() for p in coords.split(",")]
        x, z = float(parts[0]), float(parts[2])
        entries.append((block[pos:e], x, z))
        pos = block.find("{move_to={", e)

    def is_landmark(x, z):
        return 4.0 <= x <= 16.0 and 23.0 <= z <= 29.0

    kept = [t for (t, x, z) in entries if not is_landmark(x, z)]
    removed = len(entries) - len(kept)
    if removed != 6:
        raise framework.BuildError("expected to remove 6 landmark entries, matched %d" % removed)

    last_e = block.rfind("]]}") + len("]]}")
    prefix = block[:first]
    suffix = block[last_e:]
    newblock = prefix + ", ".join(kept) + suffix
    return text[:start] + newblock + text[end:]
