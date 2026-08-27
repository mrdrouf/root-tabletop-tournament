"""
m580 — take The Pond out of the frog blueprint and hand its JSON to rttSpawnPond.

The Pond is MAP-relative: Adrien places it at a fixed WORLD spot near the clearings, the same spot
regardless of which seat the frogs occupy. A seat-local blueprint move_to therefore can't express
it — setupFaction would spawn it rotated to the seat, forcing a runtime reposition (the dirty
trick). Instead we REMOVE the pond's data entry from EVERYTHING['Standard']['Lilypad Diaspora'] so
setupFaction never spawns it, and expose its object JSON as the Lua global RTT_POND_JSON. m490's
rttSpawnPond then spawns it directly at its world spot — no default, no reposition, no hiding.
"""
from . import framework

NAME = "Lilypad: remove The Pond from the blueprint, spawn it directly at its world spot"

CAT, FACTION = "Standard", "Lilypad Diaspora"
POND_GUID = "347917"
MAKEMAP_SIG = "function makeMap(player,value,id)"


def apply(text):
    h, j = framework.everything_entry_span(text, CAT, FACTION)
    entry = text[h:j]
    QT = framework.QT
    a = QT + 'GUID' + QT + ': ' + QT + POND_GUID + QT
    if entry.count(a) != 1:
        raise framework.BuildError("pond %s not unique in Lilypad blueprint (%d)" % (POND_GUID, entry.count(a)))
    g = entry.find(a)
    estart = entry.rfind('{move_to={', 0, g)
    eend = entry.find(']]}', g) + 3
    js = entry.find('json=[[', estart) + len('json=[[')
    je = entry.find(']]', js)
    obj = entry[js:je]                    # the pond object, in its file-escaped form
    if ']==]' in obj:
        raise framework.BuildError("pond object contains ']==]' — unsafe to re-embed as a long string")
    # excise the pond data entry + one adjacent comma
    if entry[estart - 1] == ',':
        cs, ce = estart - 1, eend
    elif eend < len(entry) and entry[eend] == ',':
        cs, ce = estart, eend + 1
    else:
        cs, ce = estart, eend
    entry = entry[:cs] + entry[ce:]
    text = text[:h] + entry + text[j:]

    # inject the pond JSON as a Lua global before makeMap. The object is already file-escaped, so
    # it is spliced RAW (not through esc); in the running Lua the [==[...]==] long string then holds
    # real-quoted JSON that spawnObjectJSON can parse.
    if text.count(MAKEMAP_SIG) != 1:
        raise framework.BuildError("makeMap anchor not unique for pond injection")
    inject = framework.esc("\nRTT_POND_JSON = [==[") + obj + framework.esc("]==]\n")
    text = text.replace(MAKEMAP_SIG, inject + MAKEMAP_SIG, 1)
    return text
