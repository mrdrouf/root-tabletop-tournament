"""
m080 — remove dead menu buttons that lead to nothing.

These buttons call a spawn handler with an id that has no EVERYTHING data entry,
so clicking them does nothing (they were the 3 pre-existing orphans the verifier
flagged in the base): Klacar's Volcano Island Map (two buttons: makeMap +
draftMap), Slug's Magic Bag, and Fifty Fifty Draft. Button-only removal — there
is no data to remove.
"""

from . import framework

NAME = "remove dead menu buttons (Klacar's Volcano Island, and the others that lead to nothing)"

DEAD_BUTTONS = [
    "Klacar's Volcano Island Map",
    "Slug's Magic Bag",
    "Fifty Fifty Draft",
]


def apply(text):
    for name in DEAD_BUTTONS:
        text, n = framework.remove_xml_buttons(text, name)
        if n == 0:
            raise framework.BuildError("no dead button found for %r" % name)
    return text
