"""Fronts back on their plots. Reads what `MATRI_FRONTS=<file> python tools/bake_godot.py` wrote ("pull": for each
house whose front line stands ahead of its plot, the line the plot really has there, and whether the old line ran
into the roadway) and sets in calles.json the fronts of the ones in the roadway -- and of the neighbours that shared
an end with one of them, so that the row stays flush. Houses with porch, fill or clear keep theirs (their numbers are
metres along the old front). Run the bake and this again until nothing moves, then bake.

  python tools/casas/frentes_al_solar.py <fronts.json> [<calles.json>]      (Sistemas, 25 November 2026)
"""
import json, math, os, sys
here = os.path.dirname(os.path.abspath(__file__))
path = sys.argv[2] if len(sys.argv) > 2 else os.path.join(here, 'calles.json')
pull = json.load(open(sys.argv[1]))['pull']
d = json.load(open(path, encoding='utf-8'))
ok = lambda n: n in d and not ('porch' in d[n] or 'fill' in d[n] or 'clear' in d[n])
cand = {n: v for n, v in pull.items() if ok(n)}
dist = lambda p, q: math.hypot(p[0] - q[0], p[1] - q[1])
ends = [(n, k, hd['front'][k]) for n, hd in d.items() for k in (0, 1)]
cell = {}
for n, k, p in ends: cell.setdefault((round(p[0] / 2), round(p[1] / 2)), []).append((n, k, p))
joints = []                                  # (house, end, neighbour, its end): two fronts that meet
for n in cand:
    for k in (0, 1):
        p = d[n]['front'][k]
        for cx in (-1, 0, 1):
            for cz in (-1, 0, 1):
                for m, kk, q in cell.get((round(p[0] / 2) + cx, round(p[1] / 2) + cz), []):
                    if m != n and dist(p, q) < 0.25: joints.append((n, k, m, kk))
move = {n for n, v in cand.items() if v[4]}
while True:                                  # a neighbour follows where that closes the joint
    more = set()
    for n, k, m, kk in joints:
        if m in move and n not in move:
            gone = dist(cand[m][kk], d[n]['front'][k])
            if gone > 0.2 and dist(cand[m][kk], cand[n][k]) < gone - 0.1: more.add(n)
    if not more: break
    move |= more
steps = sorted(((round(dist(cand[n][k], d[m]['front'][kk]), 2), n, m) for n, k, m, kk in joints if n in move and m not in move), reverse=True)
followers = sorted(n for n in move if not cand[n][4])
for n in move: d[n]['front'] = [cand[n][0], cand[n][1]]
open(path, 'w', encoding='utf-8', newline='').write(json.dumps(d, ensure_ascii=False, indent=1))
print('fronts moved back to their plots: %d (%d of them following a neighbour)' % (len(move), len(followers)), '| not in calles.json or with porch/fill/clear:', sorted(n for n, v in pull.items() if v[4] and not ok(n)))
print('joints left open by more than 0.3 m:', [s for s in steps if s[0] > 0.3])
for n in sorted(move): print('  %s  %.2f m at its left end, %.2f m at its right%s' % (n, cand[n][2], cand[n][3], '' if cand[n][4] else '  (follows)'))
