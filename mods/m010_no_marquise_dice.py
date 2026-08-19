"""
m010 — EXAMPLE modification (disabled in v1).

Removes the Marquise de Cat's two battle dice from the standard Faction-Selector
setup, by filtering the spawn list before anything is placed. This is the proven
pattern for a per-faction spawn tweak; it is kept here as a worked example of how
a step in the modification sequence is written. It is NOT enabled in v1 (see
registry.py) so v1 remains an exact copy of the base.
"""

from . import framework

NAME = "example - remove Marquise battle dice at setup"


def apply(text):
    lua = '''
    if name == "Marquise de Cat" then
      local filtered = {}
      for _,v in ipairs(objects) do
        if not string.find(v.json, '"Name": "Custom_Dice"', 1, true) then filtered[#filtered+1] = v end
      end
      objects = filtered
    end'''
    return framework.splice_into_setup_faction(text, lua)
