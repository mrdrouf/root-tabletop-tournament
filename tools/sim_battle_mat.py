#!/usr/bin/env python3
"""Monte-Carlo the battle mat's randomness, driving the BUILT blueprint's own functions.

    python3 tools/sim_battle_mat.py

Run it after any change to the mat's roll. Maintainer, 2026-09-27: "simulate to make sure you did not
fuck the randomness" -- the roll was rewritten many times over that day and the harness cases check
shape (every die thrown, every die spun, nothing repositioned), not distribution.

WHAT THIS PROVES. Every input the mat hands the physics engine is unbiased:
  - randomRotation() covers the whole sphere and never returns NaN (it has a real typo in it --
    `if t2 < -1.0 then ts = -1.0 end`, assigning to `ts` instead of `t2` -- so asin() could in
    principle be handed an out-of-range value; 200k draws say it is not, but that is why it is checked);
  - the die itself is unbiased BY CONSTRUCTION: twelve faces, three each of 0/1/2/3, so any uniform
    orientation gives a uniform face;
  - the push across the mat is always inward, never further out than the old fixed drop spot, and its
    direction covers every sector;
  - the drop angle is uniform and the two dice are always on opposite sides of the centre;
  - the tumble is symmetric about zero and uses its whole range;
  - and displayResults announces the faces the dice actually show, for all 64 combinations of two faces
    and a hit value -- which is where a bias would be visible to a player even if the dice were fair.

WHAT IT CANNOT PROVE. TTS's physics. In the harness randomize() picks a face; in game it turns the die
at random and throws it, and the engine settles it. So check 2 is really "the die's faces are evenly
distributed", not "TTS rolls fairly" -- nothing outside TTS can answer the second.

THREE TRAPS, all of which this script fell into first time round, so do not undo them:
  - rotation_values is built INSIDE click_roll, so it is nil until a roll has happened;
  - two fresh lupa runtimes produce the IDENTICAL random sequence, so re-creating one mid-sample
    re-draws the same numbers and multiplies any chi-square by the number of runtimes;
  - a "#" after a face in the announcement marks a die that met the hit value. It is part of the format.
"""
import sys, math, collections, statistics
sys.path.insert(0, "tests")
import test_setup_paths as T

src = T.board_lua(open("dist/Root_Tournament_Edition.json", encoding="utf-8").read())
rt = T._mat_runtime(src)
fails = []
def check(ok, label, detail=""):
    print("  %-4s %s%s" % ("OK" if ok else "FAIL", label, ("   " + detail) if detail else ""))
    if not ok: fails.append(label)

def chi2_uniform(counts, n_cats, total):
    exp = total / n_cats
    return sum((c - exp) ** 2 / exp for c in counts)

N = 200000
print("=== 1. randomRotation(): the orientation every clone is given ===")
rt.execute("""
  ROT = {}
  NAN = 0
  for i = 1, %d do
    local r = randomRotation()
    for _, v in ipairs(r) do
      if v ~= v then NAN = NAN + 1 end          -- NaN is the only value not equal to itself
    end
    ROT[i] = r
  end
""" % N)
check(rt.eval("NAN") == 0, "no NaN in %d rotations" % N, "NaN components: %d" % rt.eval("NAN"))
# each euler component should cover its range and average near its centre
comp = {0: [], 1: [], 2: []}
rows = rt.eval("ROT")
for i in range(1, N + 1, 37):                      # every 37th, enough for the shape
    r = rows[i]
    for c in range(3): comp[c].append(r[c + 1])
for c, name in ((0, "x (asin, -90..90)"), (1, "y (atan2, -180..180)"), (2, "z (atan2, -180..180)")):
    v = comp[c]
    check(min(v) < -60 and max(v) > 60, "rotation %s covers its range" % name,
          "min %.1f max %.1f mean %.1f" % (min(v), max(v), statistics.fmean(v)))

print("\n=== 2. randomize(): the face a die lands on ===")
rt.execute("pcall(function() click_roll(nil, 'Red') end)")   # click_roll builds rotation_values
assert rt.eval("type(rotation_values)") == "table", "rotation_values is still nil"
rt.execute("""
  D = MKOBJ('', {0,0,0}, {})
  D.setRotationValues(rotation_values)
  FACES = {0,0,0,0}
  for i = 1, %d do
    D.randomize()
    local v = D.getRotationValue()
    FACES[v + 1] = FACES[v + 1] + 1
  end
""" % N)
faces = [rt.eval("FACES")[i] for i in range(1, 5)]
x2 = chi2_uniform(faces, 4, N)
check(all(abs(f - N / 4) < N * 0.01 for f in faces) and x2 < 16.3,
      "faces 0-3 uniform over %d rolls" % N,
      "counts %s  chi2=%.2f (p=.001 -> 16.27)" % (faces, x2))

print("\n=== 3. rollDriftFor(): the push across the mat ===")
rt.execute("""
  INWARD, MAG, ANG = 0, {}, {}
  local c = self.getPosition()
  for i = 1, 20000 do
    local a, r = math.random() * 2 * math.pi, 0.5 + math.random() * 3
    local d = MKOBJ('', { c.x + math.cos(a) * r, c.y, c.z + math.sin(a) * r }, {})
    local hx, hz = rollDriftFor(d)
    local p = d.getPosition()
    local ix, iz = c.x - p.x, c.z - p.z
    if ix * hx + iz * hz > 0 then INWARD = INWARD + 1 end
    MAG[i] = math.sqrt(hx * hx + hz * hz)
    ANG[i] = math.atan2(hz, hx)
  end
""")
check(rt.eval("INWARD") == 20000, "every push has an inward component", "%d/20000" % rt.eval("INWARD"))
mags = [rt.eval("MAG")[i] for i in range(1, 20001)]
drift = rt.eval("rollDrift")
check(max(mags) <= drift * math.sqrt(2) + 1e-9, "push magnitude within rollDrift*sqrt(2)",
      "min %.2f max %.2f (bound %.2f)" % (min(mags), max(mags), drift * math.sqrt(2)))
angs = [rt.eval("ANG")[i] for i in range(1, 20001)]
buckets = collections.Counter(int((a + math.pi) / (2 * math.pi) * 12) % 12 for a in angs)
check(len(buckets) == 12, "push direction spans all 12 sectors", "sectors used: %d" % len(buckets))

print("\n=== 4. the drop spots ===")
angles, radii, opposite, outside = [], [], 0, 0
limit = rt.eval("function() return radialOffset * self.getScale().x end")()
for n in range(4000):
    r2 = T._mat_runtime(src) if n == 0 else r2
    r2.execute("currentDice = {} rollInProgress = nil pcall(function() click_roll(nil, 'Red') end)")
    d = r2.eval("""function()
        local c, o = self.getPosition(), {}
        for i, x in ipairs(currentDice) do
          local q = x.getPosition() o[i] = { dx = q.x - c.x, dz = q.z - c.z }
        end
        return o
    end""")()
    a, b = d[1], d[2]
    if a.dx * b.dx + a.dz * b.dz >= 0: opposite += 1
    for die in (a, b):
        r = math.hypot(die.dx, die.dz)
        radii.append(r)
        if r > limit + 1e-6: outside += 1
    angles.append(math.atan2(a.dz, a.dx))
check(opposite == 0, "the two dice are always on opposite sides", "same-side rolls: %d/4000" % opposite)
check(outside == 0, "no die dropped beyond the old fixed radius", "outside: %d (limit %.3f)" % (outside, limit))
ab = collections.Counter(int((a + math.pi) / (2 * math.pi) * 12) % 12 for a in angles)
x2a = chi2_uniform([ab.get(i, 0) for i in range(12)], 12, len(angles))
check(len(ab) == 12 and x2a < 31.3, "drop angle uniform over 12 sectors",
      "chi2=%.1f (p=.001 -> 31.26)" % x2a)
lo, hi = rt.eval("rollSpreadMin") * limit, limit
check(min(radii) >= lo - 1e-6, "radius never inside rollSpreadMin", "min %.3f (floor %.3f)" % (min(radii), lo))
check(max(radii) > hi * 0.95, "radius reaches the outer edge of the band", "max %.3f of %.3f" % (max(radii), hi))

print("\n=== 5. rerollSpin: the tumble ===")
rt.execute("""
  SP = {}
  local s = rerollSpin
  for i = 1, 60000 do
    SP[i] = (math.random() * 2 - 1) * s
  end
""")
sp = [rt.eval("SP")[i] for i in range(1, 60001)]
spin = rt.eval("rerollSpin")
check(abs(statistics.fmean(sp)) < spin * 0.02, "spin is symmetric about zero",
      "mean %.3f of +-%.1f" % (statistics.fmean(sp), spin))
check(min(sp) < -spin * 0.98 and max(sp) > spin * 0.98, "spin uses its full range",
      "min %.2f max %.2f" % (min(sp), max(sp)))

print("\n=== 6. displayResults(): is the announced result the faces the dice show? ===")
rt.execute("""
  SAID = {}
  function SETFACES(a, b)
    currentDice = {}
    for _, v in ipairs({a, b}) do
      local d = MKOBJ('', {0,0,0}, {})
      d.getRotationValue = function() return v end
      table.insert(currentDice, d)
    end
  end
""")
bad = []
for a in range(4):
    for b in range(4):
        for hv in range(0, 4):
            rt.execute("SAID = {} hitValue = %d SETFACES(%d, %d) displayResults('Red')" % (hv, a, b))
            said = list(rt.eval("SAID").values())[-1]
            plain = said.replace("#", "")     # "#" marks a die that met the hit value
            want_hi, want_lo = max(a, b), min(a, b)
            if "%d and %d" % (want_hi, want_lo) not in plain: bad.append((a, b, hv, said, "numbers"))
            if hv > 0:
                want_hits = (1 if a >= hv else 0) + (1 if b >= hv else 0)
                if ("%d hit" % want_hits) not in said: bad.append((a, b, hv, said, "hits"))
check(not bad, "all 64 face/hit-value combinations announced correctly",
      ("first wrong: %r" % (bad[0],)) if bad else "")

print("\n" + ("SIMULATION FAILED: " + ", ".join(fails) if fails else "ALL CHECKS PASSED"))
sys.exit(1 if fails else 0)
