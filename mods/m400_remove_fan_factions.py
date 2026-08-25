"""
m400 — remove every Fan Faction (73 of them).

The tournament only drafts official factions, and the Fan Factions are the sole
source of the flaky Google-Drive / imgur / dropbox art (the "load twice" for spawned
content). Remove their EVERYTHING['Fan Factions'] data and any menu button for each.
Dynamic: finds the names in the current text so it stays correct as the base changes.
"""
import re

from . import framework

NAME = "remove all Fan Factions (unused in tournament; flaky-host art)"


# kept: components still referenced by a (dead but statically-present) Doomed-Vagabond
# code path — removing them would dangle setupFaction() calls.
KEEP = {"Doomed Vagabond Dice", "Doomed Vagabond Layout"}


def apply(text):
    names = sorted(set(re.findall(r"EVERYTHING\['Fan Factions'\]\['([^']+)'\]", text)) - KEEP,
                   key=len, reverse=True)  # longer first so substrings don't shadow
    removed = 0
    for name in names:
        try:
            text = framework.remove_everything_entry(text, "Fan Factions", name)
            removed += 1
        except framework.BuildError:
            pass
        text, _ = framework.remove_xml_buttons(text, name)
    if removed:
        print("       [fan] removed %d fan factions" % removed)
    return text
