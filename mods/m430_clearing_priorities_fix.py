"""
m430 — make the Clearing Priorities option actually appear.

Root cause (found by parsing the board XmlUI): the base mod carries THREE buttons
that all share id="Clearing Priorities" —

  * two always-on, top-level (no ToggleGroup) buttons at (15,-55) and (55,-55), and
  * the one inside our setupButtons group at (19,-46.5) that our layout positions.

In TTS/Unity a duplicated element id makes one of the colliding controls fail to
render / receive clicks, so our grouped button never showed. On top of that a
top-level "Riverfolk Interaction" button sits at (25,-45) — right on our Clearing
Priorities slot — with a transparent background, overlapping it further.

Fix:
  1. give OUR setupButtons Clearing Priorities a unique id (RTTClearingPriorities)
     and route its click through a tiny wrapper so makeTool still gets the real
     "Clearing Priorities" tool name (makeTool indexes EVERYTHING["Tools"][id]);
  2. delete the two stray top-level "Clearing Priorities" buttons and the
     overlapping "Riverfolk Interaction" button (their onclick=makeTool handler
     stays, so nothing dangles).

Runs AFTER m350_custom_layout, which positions the button while it is still
id="Clearing Priorities".
"""
from . import framework

NAME = "fix duplicate-id Clearing Priorities (unique id + wrapper, drop strays)"

WRAPPER = (
    '\nfunction rttMakeClearing()\n'
    '  makeTool(nil, nil, "Clearing Priorities")\n'
    'end\n\n'
)


def apply(text):
    # 0) the base ships this button wrapped in an XML comment (so it never rendered).
    #    strip the comment so it becomes live.
    text, _ = framework.uncomment_button_in_group(text, "setupButtons", "Clearing Priorities")

    # 1) re-point our button's click to the wrapper (still id="Clearing Priorities")
    text, n = framework.set_button_attr_in_group(
        text, "setupButtons", "Clearing Priorities", "onclick", "rttMakeClearing")
    if n != 1:
        raise framework.BuildError("setupButtons Clearing Priorities onclick not set (%d)" % n)

    # 2) rename its id so it no longer collides with the base's top-level copies
    text, n = framework.set_button_attr_in_group(
        text, "setupButtons", "Clearing Priorities", "id", "RTTClearingPriorities")
    if n != 1:
        raise framework.BuildError("setupButtons Clearing Priorities id not renamed (%d)" % n)

    # 3) the only "Clearing Priorities" ids left are the two stray top-level ones — drop them
    text, n = framework.remove_xml_buttons(text, "Clearing Priorities")
    if n != 2:
        raise framework.BuildError("expected 2 stray Clearing Priorities buttons, removed %d" % n)

    # 4) drop the top-level Riverfolk Interaction button that overlaps the CP slot
    text, n = framework.remove_xml_buttons(text, "Riverfolk Interaction")
    if n != 1:
        raise framework.BuildError("expected 1 Riverfolk Interaction button, removed %d" % n)

    # 5) add the wrapper Lua just before makeTool()
    anchor = "function makeTool(player,value,id)"
    if text.count(anchor) != 1:
        raise framework.BuildError("makeTool anchor not unique")
    text = text.replace(anchor, framework.esc(WRAPPER) + anchor, 1)
    return text
