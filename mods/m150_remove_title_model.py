"""
m150 — remove the central title / branding model.

Best-guess: the unnamed, locked Custom_Model (GUID 4ee1f2) sits dead-centre of the
table (0, 1.1, 0) at scale 4.2 — the "Root community TTS tool" title/branding
piece. Removing it clears the centre so the options/board can sit together.

If this turns out to be the wrong object, revert just this one step (its own
commit).
"""

from . import framework

NAME = "remove the central title / branding model (verify: GUID 4ee1f2)"


def apply(text):
    return framework.remove_top_level_object(text, "4ee1f2")
