"""
m140 — remove the Master Instructions PDF.

The "Master Instructions" Custom_PDF (GUID b85bd2) is a top-level object sitting
on the far side of the table. Remove it from ObjectStates. (A separate embedded
copy inside a data blob is left alone; only the physical table object is removed.)
"""

from . import framework

NAME = "remove the Master Instructions PDF (far side of the table)"


def apply(text):
    return framework.remove_top_level_object(text, "b85bd2")
