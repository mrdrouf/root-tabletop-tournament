"""
Generate the menu layout -> tools/user_layout.json.
Rows are stacked top-to-bottom with a single uniform vertical GAP (standardised
line spacing); each row is centred horizontally on X=0 (board centre). Tunable.
"""
import json, os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

GAP = 6.0          # uniform vertical gap between every row
TOP = 82.0         # top edge of the first row

GROUP = {"rttSetup": "setupButtons", "rttCredit": "Main Nav"}
KIND = {"rttCredit": "credit"}   # rttSetup is a plain text button now (custom plaques blank in TTS)
LABEL = {"rttSetup": "RTT | DRAFT", "Summer Map": "Autumn Map",
         "Clearing Priorities": "Clearing Priorities Big",
         "Faction Select": "Faction Selector Tool", "rttCredit": ""}
for g, ids in {
    "mapButtonsStandard": ["Summer Map", "Lake Map", "Marsh Map", "Winter Map", "Mountain Map", "Gorge Map"],
    "decksButtonsStandard": ["Standard Deck", "Exiles and Partisans Deck", "Squires and Disciples Deck"],
    "tools1": ["Faction Select", "Battle Mat", "Ginso's Gizmo", "Clearing Markers", "Swol Birbs",
               "Lizard Wizard", "Mini-Mood Manager", "Mob Lobber"],
    "setupButtons": ["Clearing Priorities", "Vagabond Cards", "Landmarks", "Marsh5P"],
}.items():
    for i in ids:
        GROUP.setdefault(i, g)

# each row: (ids, w, h, spacing) — laid out top to bottom
# RTT plaque, maps and decks all the same size (34) per request
ROWS = [
    (["rttSetup"], 34, 34, 0),
    (["Summer Map", "Lake Map", "Marsh Map", "Winter Map", "Mountain Map", "Gorge Map"], 34, 34, 38),
    (["Standard Deck", "Exiles and Partisans Deck", "Squires and Disciples Deck"], 34, 34, 50),
    (["Faction Select", "Battle Mat", "Ginso's Gizmo", "Clearing Priorities", "Clearing Markers", "Vagabond Cards"], 34, 17, 38),
    (["Lizard Wizard", "Mini-Mood Manager", "Mob Lobber", "Landmarks", "Swol Birbs", "Marsh5P"], 34, 17, 37),
]

els = []
y_top = TOP
for ids, w, h, sp in ROWS:
    cy = y_top - h / 2
    n = len(ids)
    for i, bid in enumerate(ids):
        x = round((i - (n - 1) / 2) * sp, 2)
        els.append(dict(id=bid, group=GROUP[bid], kind=KIND.get(bid, "game"),
                        x=x, y=round(cy, 2), w=w, h=h, label=LABEL.get(bid, bid)))
    y_top = cy - h / 2 - GAP

# references are text buttons now (m355) -> keep the half-tile RECTANGLE shape (34x17)
els.append(dict(id="rttCredit", group="Main Nav", kind="credit", x=-72, y=88, w=52, h=9.9, label=""))
json.dump({"elements": els}, open(os.path.join(ROOT, "tools", "user_layout.json"), "w"), indent=1)
print("wrote %d elements; bottom edge y=%.1f" % (len(els), y_top + GAP))
