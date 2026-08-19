"""
m050 — remove all scenarios.

Removes the 6 scenario buttons + their EVERYTHING['Scenarios'] data, the
`makeHauntedWoodland` handler (the one scenario with its own handler, which
spawned the Haunted Woodland scenario), and the "Scenarios" menu section label.
The generic `makeScenario` handler is left in place (harmless, now unreachable).
"""

from . import framework

NAME = "remove all scenarios + the scenario menu section"

SCENARIOS = [
    "Trick or Treat!",
    "The Tavern",
    "Haunted Woodland",
    "Riverfolk Markers",
    "Double Entente",
    "The Chaos Contraptions",
]


def apply(text):
    for name in SCENARIOS:
        text = framework.remove_item(text, "Scenarios", name)
    text = framework.remove_lua_function(text, "makeHauntedWoodland")
    # XML-specific marker: 'image = "Scenarios Tag"' only matches the <Image> menu
    # label, not the Lua asset registration (which uses name = "Scenarios Tag").
    text, _ = framework.remove_xml_element(text, "Image", 'image = \\"Scenarios Tag\\"')
    return text
