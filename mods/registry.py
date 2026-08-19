"""
The modification sequence.

MODS is the ordered list of modifications build.py applies on top of the base
mod. Order matters. To add the next step in the sequence:

    1. create mods/mNNN_short_name.py with NAME and apply(text)
    2. import it below
    3. append it to MODS in the position it should run

The enabled list below is just the identity/branding step, so the build is an
exact copy of the base mod under the Root Tabletop Tournament name.
"""

from . import m000_identity
from . import m020_remove_tools
from . import m030_remove_fan_maps
from . import m040_remove_fan_decks

# Ready-made examples — uncomment to begin layering real modifications:
# from . import m010_no_marquise_dice

MODS = [
    m000_identity,
    # m010_no_marquise_dice,
    m020_remove_tools,
    m030_remove_fan_maps,
    m040_remove_fan_decks,
]
