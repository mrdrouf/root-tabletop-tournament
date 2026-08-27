"""
m580 — spawn the Lilypad "The Pond" hidden, so it never flashes at its blueprint spot.

The Pond is MAP-relative (a fixed world spot near the clearings), so it can't be baked to a
seat-local move_to — it has to be positioned at runtime. To avoid the spawn-at-default-then-move
flash, bake its blueprint move_to BELOW the table (y -60); it spawns hidden, and rttRepositionPond
(m490) reveals it at its world spot in one instant setPosition. No visible adjustment.
"""
from . import framework

NAME = "Lilypad: spawn The Pond below the table (revealed in place, no flash)"

CAT, FACTION = "Standard", "Lilypad Diaspora"
POND_GUID = "347917"
HIDDEN = (-18.634, -60.0, -7.623)   # blueprint x,z kept; y dropped below the table


def apply(text):
    h, j = framework.everything_entry_span(text, CAT, FACTION)
    entry = text[h:j]
    entry = framework.set_data_move_to(entry, POND_GUID, HIDDEN)
    return text[:h] + entry + text[j:]
