"""
Generate a centred, evenly-spaced, ~20% larger layout -> tools/user_layout.json.
Board centre is X=0; every row is laid out symmetric about it. Tunable and re-runnable.
"""
import json, os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def row(ids, y, w, h, spacing, kind_map, group_map, label_map):
    n = len(ids)
    out = []
    for i, bid in enumerate(ids):
        x = round((i - (n - 1) / 2) * spacing, 2)
        out.append(dict(id=bid, group=group_map[bid], kind=kind_map.get(bid, "game"),
                        x=x, y=y, w=w, h=h, label=label_map.get(bid, bid)))
    return out

GROUP = {}
KIND = {"rttSetup": "plaque", "rttCredit": "credit"}
LABEL = {"rttSetup": "RTT | DRAFT", "Summer Map": "Autumn Map",
         "Clearing Priorities": "Clearing Priorities Big",
         "Faction Select": "Faction Selector Tool", "rttCredit": ""}
for g, ids in {
    "setupButtons": ["rttSetup", "Vagabond Cards", "Clearing Priorities", "Landmarks"],
    "mapButtonsStandard": ["Summer Map", "Lake Map", "Marsh Map", "Winter Map", "Mountain Map", "Gorge Map"],
    "decksButtonsStandard": ["Standard Deck", "Exiles and Partisans Deck", "Squires and Disciples Deck"],
    "tools1": ["Faction Select", "Battle Mat", "Ginso's Gizmo", "Clearing Markers", "Swol Birbs",
               "Lizard Wizard", "Mini-Mood Manager", "Mob Lobber"],
}.items():
    for i in ids:
        GROUP[i] = g
GROUP["rttCredit"] = "Main Nav"

els = []
# RTT plaque, centred top (42 = 35 * 1.2)
els += [dict(id="rttSetup", group="setupButtons", kind="plaque", x=0, y=60, w=42, h=42, label="RTT | DRAFT")]
# maps: 6, square, 36 (30*1.2), spacing 36, centred
els += row(["Summer Map", "Lake Map", "Marsh Map", "Winter Map", "Mountain Map", "Gorge Map"],
           y=22, w=36, h=36, spacing=36, kind_map=KIND, group_map=GROUP, label_map=LABEL)
# decks: 3, square, 42, spacing 48, centred (middle deck at x=0)
els += row(["Standard Deck", "Exiles and Partisans Deck", "Squires and Disciples Deck"],
           y=-20, w=42, h=42, spacing=48, kind_map=KIND, group_map=GROUP, label_map=LABEL)
# bottom grid: tools + references, 2:1 half-tiles 36x18 (30x15 *1.2)
els += row(["Faction Select", "Battle Mat", "Ginso's Gizmo", "Clearing Priorities", "Clearing Markers", "Vagabond Cards"],
           y=-52, w=36, h=18, spacing=37, kind_map=KIND, group_map=GROUP, label_map=LABEL)
els += row(["Lizard Wizard", "Mini-Mood Manager", "Mob Lobber", "Landmarks", "Swol Birbs"],
           y=-73, w=36, h=18, spacing=37, kind_map=KIND, group_map=GROUP, label_map=LABEL)
# credit: top-left scrawl (kept small, off to the side)
els += [dict(id="rttCredit", group="Main Nav", kind="credit", x=-70, y=84, w=52, h=9.9, label="")]

json.dump({"elements": els}, open(os.path.join(ROOT, "tools", "user_layout.json"), "w"), indent=1)
print("wrote %d elements" % len(els))
