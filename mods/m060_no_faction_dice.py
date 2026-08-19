"""
m060 — no dice spawned with any faction.

setupFaction spawns each faction's objects from EVERYTHING[category][name]['data'].
We filter out every Custom_Dice object before spawning, for ALL factions (this is
the general form of the m010 Marquise-only example). Battle dice therefore never
appear on the table when a faction is set up.
"""

from . import framework

NAME = "no dice spawned with any faction"


def apply(text):
    lua = '''
    do
      local filtered = {}
      for _,v in ipairs(objects) do
        if not string.find(v.json, '"Name": "Custom_Dice"', 1, true) then filtered[#filtered+1] = v end
      end
      objects = filtered
    end'''
    return framework.splice_into_setup_faction(text, lua)
