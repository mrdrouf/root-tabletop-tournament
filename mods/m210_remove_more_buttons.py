"""
m210 — remove the fan map/deck "more" nav buttons.

The standard maps screen and decks screen each have a "more >" button that pages
to the fan map / fan deck screens, which are now empty (fan maps and decks were
removed). Remove those nav buttons (forward "more" and the dead back buttons on
the emptied pages). The fan FACTION nav (fan1..fan4) is left alone — fan factions
are still present.
"""

from . import framework

NAME = "remove the 'more' nav buttons that page to the emptied fan map/deck screens"

# map paging: maps1(back) maps2/maps3(more);  deck paging: decks1(back) decks2(more)
NAV_ONCLICKS = ["maps1", "maps2", "maps3", "decks1", "decks2"]


def apply(text):
    total = 0
    for oc in NAV_ONCLICKS:
        text, n = framework.remove_xml_buttons_by_onclick(text, oc)
        total += n
    if total == 0:
        raise framework.BuildError("no fan map/deck nav buttons found to remove")
    return text
