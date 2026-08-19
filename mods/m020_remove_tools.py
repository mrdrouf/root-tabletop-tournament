"""
m020 — remove standalone menu tools.

Each of these is an optional tool offered by a button in the Tools menu; we
delete the XML button and its EVERYTHING['Tools'] data block. build.py's
dangling-reference check will fail the build if any of these is still spawned by
kept code (handled case-by-case if so).
"""

from . import framework

NAME = "remove standalone tools (battle dice, quest decks, multi-state props, items, etc.)"

TOOLS = [
    "Battle Dice",
    "Supply Knight",
    "Nuanced Quest Deck",
    "Quest Freshener",
    "Craftable Items",            # "the items"
    "Clockwork Upgrade Cards",    # "clockwork update cards"
    "Hirelings Noir",             # "Harling's Noir"
    "Mighty Multi-State Warriors",
    "Mighty Multi-State Ruins",   # "mighty multistate runes"
    "Alliance Multi-State Warriors",  # "alliance multistate wire"
    "Action Deck",
    "Side Tables",                # "extra chairs" (its button icon is ExtraChairsWhite)
]


def apply(text):
    for name in TOOLS:
        text = framework.remove_item(text, "Tools", name)
    # dead handler functions left behind by the removals above:
    #   makeSideTables      - was the "Side Tables" button handler
    #   makeNuancedQuestDeck - already unused; spawned the Nuanced Quest Deck
    text = framework.remove_lua_function(text, "makeSideTables")
    text = framework.remove_lua_function(text, "makeNuancedQuestDeck")
    return text
