"""
m530 — tighten the standard-setup DECK buttons so their horizontal spacing matches the MAP
buttons above them.

On the setup board the map buttons sit at x = -95,-57,-19,19,57,95 (evenly spaced by 38), but
the three deck buttons sit at x = -50, 0, 50 (spaced by 50 = too wide). Adrien wants the deck
spacing to match the map spacing, so pull the outer two decks in to +/-38 (centre stays at 0).
"""
from . import framework

NAME = "setup board: deck buttons spaced 38 to match the map buttons"


def apply(text):
    text = framework.replace_unique(text,
        framework.esc('position="-50 -15 -20"'), framework.esc('position="-38 -15 -20"'))
    text = framework.replace_unique(text,
        framework.esc('position="50 -15 -20"'), framework.esc('position="38 -15 -20"'))
    return text
