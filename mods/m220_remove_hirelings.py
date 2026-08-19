"""
m220 — remove the Hirelings option.

Removes the Hirelings button + EVERYTHING['Tools']['Hirelings'] data. (The
EVERYTHING['Hirelings'] category of hireling pieces is a separate table and is
left in place, unreferenced, once the button is gone.)
"""

from . import framework

NAME = "remove the Hirelings option"


def apply(text):
    return framework.remove_item(text, "Tools", "Hirelings")
