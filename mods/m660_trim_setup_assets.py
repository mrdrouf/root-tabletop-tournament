"""
m660 — trim bab7e1's CustomUIAssets to only the icons its XmlUI actually references.

Cold-load root cause (multi-agent investigation): TTS resolves an object's XmlUI CustomAsset
references ONCE at instantiation and never re-composites as downloads finish. bab7e1 carries 541
CustomUIAssets -- far over TTS's ~75-100 UI-composite threshold -- so on a cold process its button
group paints blank (the board TILE renders because CustomImage uses a different pipeline). Its XmlUI
only references ~147 of the 541 assets; the other ~394 are dead weight left from the base menu.

Filtering CustomUIAssets to the referenced set is FULLY ART-SAFE (drops only entries no button uses)
and cuts the asset-resolution work back under the threshold. CONFIRMED IN-GAME (2026-08-29): with the
count at 147 the setup buttons render immediately on a cold load -- no respawn, no 2nd load. This is
the cold-load fix. (The heavier light-launcher rework designed alongside it was not needed.)

Runs LAST so m470's lightweight selectors (built from bab7e1's full CustomUIAssets earlier) keep
their icons. Surgical: only bab7e1's CustomUIAssets array is rewritten; the 4.5 MB LuaScript is not.
"""
import json
import re

from . import framework

NAME = "trim bab7e1 CustomUIAssets to the icons its XmlUI uses (cold-load render)"


def apply(text):
    start, end = framework._object_span(text, "bab7e1")
    obj = json.loads(text[start:end])
    xml = obj.get("XmlUI") or ""
    refs = set(re.findall(r'(?:icon|image)\s*=\s*"([^"]+)"', xml))
    assets = obj.get("CustomUIAssets") or []
    kept = [a for a in assets if a.get("Name") in refs]
    if len(kept) < 50 or len(kept) >= len(assets):
        raise framework.BuildError(
            "m660 trim sanity failed: kept %d of %d (refs=%d)" % (len(kept), len(assets), len(refs)))
    obj["CustomUIAssets"] = kept
    new = json.dumps(obj, ensure_ascii=False, separators=(",", ":"))
    return text[:start] + new + text[end:]
