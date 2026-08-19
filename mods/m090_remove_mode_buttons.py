"""
m090 — remove the Weird Root, Super Auto Smash Up, and Advanced Setup modes.

These are entry-point buttons into subsystems that are entangled with kept code:
  - slugSetupButton (Weird Root) -> slugSetup(), and the button id is later reused
    by the draft flow (setAttribute onclick=addraftMessageReminder).
  - MashUp (makeMashUp) shares Weird Root's Roster/Guide objects.
  - Advanced Setup -> the Adset draft system, whose toggle groups are also driven
    by the clockwork-bot setup path.
  - The Law of Slug is a Weird Root rules card (also auto-spawned by now-removed
    fan maps).

So we remove them from the MENU (button-only). The modes become unreachable; their
now-dead data and handlers are left in place rather than risk surgery on the
shared setup/bot/draft code. (A deeper, full removal is possible later.)
"""

from . import framework

NAME = "remove Weird Root, Super Auto Smash Up, and Advanced Setup from the menu"

MODE_BUTTONS = [
    "slugSetupButton",   # Weird Root
    "MashUp",            # Super Auto Smash Up
    "Advanced Setup",
    "The Law of Slug",   # Weird Root rules card
]


def apply(text):
    for name in MODE_BUTTONS:
        text, n = framework.remove_xml_buttons(text, name)
        if n == 0:
            raise framework.BuildError("no button found for mode %r" % name)
    return text
