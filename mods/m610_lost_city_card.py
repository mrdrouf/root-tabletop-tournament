"""
m610 — replace the outdated Lost City landmark rules-card art (BackURL) with Adrien's new upload.

The Lost City card shows its RULES face (BackURL) in RTT. Adrien re-drew it and uploaded the PNG to
Steam; swap the old URL for the new one wherever it appears (the card's data blob).
"""
from . import framework

NAME = "Lost City: swap the outdated rules-card art (BackURL)"

OLD = "https://steamusercontent-a.akamaihd.net/ugc/1859433736252751364/0DC4B26C9A4D68D8944E0E6AB84868CA3DFA84D3/"
NEW = "https://steamusercontent-a.akamaihd.net/ugc/11026657163450986659/01C4A12996D5C47049E1BA794CC33AC10F9AF662/"


def apply(text):
    n = text.count(OLD)
    if n == 0:
        raise framework.BuildError("Lost City old BackURL not found")
    return text.replace(OLD, NEW)
