"""
m110 — remove Fandmarks (fan landmarks).

A Tools menu item: remove its button + EVERYTHING['Tools']['Fandmarks'] data.
"""

from . import framework

NAME = "remove Fandmarks (fan landmarks)"


def apply(text):
    return framework.remove_item(text, "Tools", "Fandmarks")
