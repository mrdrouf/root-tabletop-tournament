"""
m070 — remove rules manuals.

Learning to Play, The Law of Root, The Law of Rootbotics, and the Better Bot
Project manual. Each is an EVERYTHING['Tools'] entry with one or more buttons
(makeTool and/or makeRules); remove_item deletes all of its buttons and its data.

Note: this removes only the Better Bot Project *manual* (the Tools entry), not
the EVERYTHING['Better Bot Project'] bot factions, which are a separate category.
"""

from . import framework

NAME = "remove rules manuals (Learning to Play, Law of Root, Law of Rootbotics, Better Bot Project)"

MANUALS = [
    "Learning to Play",
    "The Law of Root",
    "The Law of Rootbotics",
    "Better Bot Project",
]


def apply(text):
    for name in MANUALS:
        text = framework.remove_item(text, "Tools", name)
    return text
