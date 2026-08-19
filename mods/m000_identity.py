"""
m000 — identity / branding.

The initial build of Root Tabletop Tournament is an exact copy of the base mod
with only its name changed, so it is unmistakable in the TTS load list and is the
anchor point for every later modification. No gameplay is touched.
"""

from . import framework

NAME = "identity - brand base as Root Tabletop Tournament"

SAVE_NAME = "Root Tabletop Tournament"
GAME_MODE = "Root Tabletop Tournament"


def apply(text):
    text = framework.rename_save(text, SAVE_NAME)
    text = framework.set_gamemode(text, GAME_MODE)
    return text
