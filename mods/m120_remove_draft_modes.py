"""
m120 — remove the GSG tournament draft and the advanced draft ("AD draft").

Both are entry-point buttons into large draft subsystems (their own toggle groups,
roster flows, and functions), entangled with kept setup code — so, as with the
other modes, we remove them from the MENU (button-only):
  - "Tournament"  (onclick=tournamentSetup)  — the GSG tournament draft
  - "adDraft"     (onclick=draftBoard)        — the advanced draft / advanced setup

The "Advanced Setup" tool card button was already removed in m090; this removes
the advanced-DRAFT entry as well.
"""

from . import framework

NAME = "remove GSG tournament draft + advanced draft (AD draft) from the menu"

MODE_BUTTONS = [
    "Tournament",   # GSG tournament draft
    "adDraft",      # advanced draft ("AD draft") / advanced setup
]


def apply(text):
    for name in MODE_BUTTONS:
        text, n = framework.remove_xml_buttons(text, name)
        if n == 0:
            raise framework.BuildError("no button found for %r" % name)
    return text
