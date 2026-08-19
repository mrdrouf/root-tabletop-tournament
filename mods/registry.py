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
from . import m050_remove_scenarios
from . import m060_no_faction_dice
from . import m070_remove_manuals
from . import m080_remove_dead_buttons
from . import m090_remove_mode_buttons
from . import m100_four_selectors
from . import m110_remove_fandmarks
from . import m120_remove_draft_modes
from . import m130_resize_summer_button
from . import m140_remove_master_pdf
from . import m150_remove_title_model

# Ready-made examples — uncomment to begin layering real modifications:
# from . import m010_no_marquise_dice

MODS = [
    m000_identity,
    # m010_no_marquise_dice,
    m020_remove_tools,
    m030_remove_fan_maps,
    m040_remove_fan_decks,
    m050_remove_scenarios,
    m060_no_faction_dice,
    m070_remove_manuals,
    m080_remove_dead_buttons,
    m090_remove_mode_buttons,
    m100_four_selectors,
    m110_remove_fandmarks,
    m120_remove_draft_modes,
    m130_resize_summer_button,
    m140_remove_master_pdf,
    m150_remove_title_model,
]
