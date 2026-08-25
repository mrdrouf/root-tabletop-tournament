"""
m431 — remove the base mod's always-visible top-level buttons.

The "Root - Ultimate Collection" setup board carries ~39 buttons declared at the
XML top level (inside NO ToggleGroup), so nothing ever hides them: the Clockwork
bot factions, the Better-Bot-Project meeples, a second copy of several reference
tools (Clearing Priorities, Riverfolk/Corvid Interaction, Robot Die, Faction
Select ...) and the fan-content selectors. They render on top of / around the
curated tournament menu — the source of the long-standing "withered / mess /
misaligned" look, and (via duplicate ids) why grouped options like Clearing
Priorities and Faction Select were dropped by TTS.

None of them are used by the RTT tournament (factions are drafted by rttSetup and
placed via the corner faction selectors), so we delete every top-level button and
keep only the board-management controls. Grouped buttons — every item of our menu,
and the human faction picker — sit inside ToggleGroups and are untouched.

Runs after m350/m430 so it operates on the final laid-out board.
"""
from . import framework

NAME = "remove base top-level bot/fan/reference buttons (declutter the board)"

BOARD_GUID = "bab7e1"
KEEP = {"xButton", "Clear All"}   # the close-X and the board reset


def apply(text):
    text, removed = framework.remove_toplevel_ui_buttons(text, BOARD_GUID, KEEP)
    if len(removed) < 25:
        raise framework.BuildError(
            "expected to remove ~35 top-level buttons, only removed %d: %s"
            % (len(removed), removed))
    # our menu buttons live in ToggleGroups — make sure none were caught
    for must in ('id=\\"RTTClearingPriorities\\"', 'id=\\"Vagabond Cards\\"',
                 'id=\\"Landmarks\\"', 'id=\\"Battle Mat\\"', 'id=\\"Faction Select\\"',
                 'id=\\"Summer Map\\"', 'id=\\"Standard Deck\\"', 'id=\\"rttSetup\\"'):
        if must not in text:
            raise framework.BuildError("declutter removed a menu button: %s" % must)
    return text
