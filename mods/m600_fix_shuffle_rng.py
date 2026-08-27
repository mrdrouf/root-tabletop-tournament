"""
m600 — replace the base shuffle() with a clean single-pass Fisher-Yates (THE randomness fix).

The stock shuffle() is broken: it loops 101 times and calls `math.randomseed(os.time())` on EVERY
iteration, plus once more on the next frame. os.time() is whole SECONDS, so within any one second
every reseed is identical -> the shuffle is deterministic-per-second, AND it leaves the GLOBAL RNG
reseeded to os.time() afterwards. shuffleMaps() calls shuffle() right before the Mountain landmark
is chosen, so the suit markers AND the landmark repeat within the same second (see rtt-rng-bug).

The replacement seeds NOTHING (the RNG is seeded once at load, m490) and just does one correct
Fisher-Yates on the advancing stream, so every call is independent and uniform.
"""
from . import framework

NAME = "Fix base shuffle(): one clean Fisher-Yates, no os.time reseed (true randomness)"

START = "function shuffle( t )"

NEW_LUA = (
    "function shuffle( t )\n"
    "  if type(t) ~= \"table\" then return false end\n"
    "  for i = #t, 2, -1 do\n"
    "    local j = math.random( i )\n"
    "    t[i], t[j] = t[j], t[i]\n"
    "  end\n"
    "  return t\nend"
)


def apply(text):
    i = text.find(START)
    if i == -1:
        raise framework.BuildError("base shuffle() not found")
    # the function's closing end is the first COLUMN-0 \nend after the signature (inner ends are
    # indented, so '\nend' with no spaces only matches the real function close).
    e = text.find("\\nend", i)
    if e == -1:
        raise framework.BuildError("shuffle() closing end not found")
    old = text[i:e + len("\\nend")]
    if "math.randomseed" not in old or "os.time" not in old:
        raise framework.BuildError("shuffle() span looks wrong (no os.time reseed inside)")
    if text.count(old) != 1:
        raise framework.BuildError("shuffle() span not unique")
    return text.replace(old, framework.esc(NEW_LUA), 1)
