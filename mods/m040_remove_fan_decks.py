"""
m040 — remove fan decks.

Keep the 3 official deck families (Standard/Base, Exiles & Partisans, Squires &
Disciples) plus the shared support cards (Refill Card, Dominance Track Card).

Fan decks are removed fully: the "X Deck" button + both the "X Deck" and
"X Deck 2" data piles. makeDeck is generic for these (spawns Refill + Dominance +
the deck by id), so once the button is gone there is no literal caller left.

The Dark Deck is a special case: makeDeck has dedicated Dark-Deck branches that
reference the Dark data, and makeDeck also drives the kept decks — so instead of
risky surgery on makeDeck we remove only the Dark Deck's menu BUTTON. It vanishes
from the menu; its now-unreachable data and handling remain, harmlessly.
"""

from . import framework

NAME = "remove fan decks (keep the 3 official deck families)"

# fully removed: "X Deck" (button + data) and "X Deck 2" (data only, no button)
REMOVE_FULL = [
    "Dawn and Dusk Deck", "Dawn and Dusk Deck 2",
    "Upstarts and Renegades Deck", "Upstarts and Renegades Deck 2",
    "Sorcery of the Enchanted Woods Deck", "Sorcery of the Enchanted Woods Deck 2",
    "Crafty Tactics Deck", "Crafty Tactics Deck 2",
    "Offensive Deck", "Offensive Deck 2",
    "60 Card Master Deck", "60 Card Master Deck 2",
]

BUTTON_ONLY = ["Dark Deck"]  # coupled into makeDeck; drop from menu, keep data


def apply(text):
    for name in REMOVE_FULL:
        has_button = not name.endswith(" 2")   # only the base "X Deck" has a button
        text = framework.remove_item(text, "Decks", name, require_button=has_button)
    for name in BUTTON_ONLY:
        text, n = framework.remove_xml_buttons(text, name)
        if n == 0:
            raise framework.BuildError("no button found for %r" % name)
    return text
