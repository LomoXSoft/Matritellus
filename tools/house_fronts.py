"""From what tools/house_data.py has gathered (tools/casas/<reference>/datos.json), works out each house's front on a
street: its two ends as you face it, its length, and which of its parts stand on it -- the lines to paste into HOUSES
in bake_godot.py.

    python tools/house_fronts.py "Calle de Alemania" REF REF ...
"""
import json, math, os, sys
from shapely.geometry import Polygon, Point, LineString
from shapely.ops import unary_union

HERE = os.path.dirname(os.path.abspath(__file__))

def main():
    street = sys.argv[1]
    game = json.load(open(os.path.join(HERE, '..', 'godot', 'data', 'map.json'), encoding='utf8'))
    N = game['nodes']
    lines = [LineString([(N[i * 2], N[i * 2 + 1]) for i in r['p']]) for r in game['roads'] if r['n'] == street and len(r['p']) > 1]
    line = max(lines, key=lambda l: l.length)
    for rc in sys.argv[2:]:
        d = json.load(open(os.path.join(HERE, 'casas', rc, 'datos.json'), encoding='utf8'))
        parts = [p for p in d['parts'] if p['floors'] >= 1]
        # the parts that stand on the street, and how many storeys the tallest of them has
        on = [p for p in parts if any(w['street'] == street and w['len'] > 1.0 for w in p['walls'])]
        if not on:
            print('# %s: nothing of it stands on %s' % (rc, street)); continue
        top = max(p['floors'] for p in on)
        pts, outs = [], []
        for p in on:
            if p['floors'] < top and len(on) > 1 and sum(w['len'] for w in p['walls'] if w['street'] == street) < 2.5: continue
            for w in p['walls']:
                if w['street'] != street or w['len'] < 0.6: continue
                mid = Point((w['a'][0] + w['b'][0]) / 2, (w['a'][1] + w['b'][1]) / 2)
                s = line.project(mid); a = line.interpolate(max(0, s - 1)); b = line.interpolate(min(line.length, s + 1))
                sd = ((b.x - a.x) / a.distance(b), (b.y - a.y) / a.distance(b))
                wd = ((w['b'][0] - w['a'][0]) / w['len'], (w['b'][1] - w['a'][1]) / w['len'])
                if abs(wd[0] * sd[0] + wd[1] * sd[1]) < 0.8: continue               # a side wall that happens to look at the street
                if line.distance(mid) > 11: continue
                # (another part of the same house in front of it? then it is not the front)
                probe = Point(mid.x + w['out'][0] * 1.0, mid.y + w['out'][1] * 1.0)
                if any(Polygon(q['ring']).contains(probe) for q in parts): continue
                pts += [tuple(w['a']), tuple(w['b'])]; outs.append(w['out'])
        if not pts:
            print('# %s: no wall of it faces %s' % (rc, street)); continue
        ox, oz = sum(o[0] for o in outs) / len(outs), sum(o[1] for o in outs) / len(outs)
        ux, uz = oz, -ox                                    # along the front, to the right as you face it (out = (-uz, ux))
        pts.sort(key=lambda q: q[0] * ux + q[1] * uz)
        left, right = pts[0], pts[-1]
        ln = math.dist(left, right)
        floors = sorted(set(p['floors'] for p in parts))
        areas = {f: round(sum(p['area'] for p in parts if p['floors'] == f)) for f in floors}
        bulge = max(abs((q[0] - left[0]) * -(right[1] - left[1]) / ln + (q[1] - left[1]) * (right[0] - left[0]) / ln) for q in pts)
        print("    '%s': {'rc': '%s', 'floors': %d, 'front': ((%.2f, %.2f), (%.2f, %.2f))},   # %.2f m, %s, parts m2 by storeys %s, front off the line by %.2f m  | %s"
              % (rc[:7], rc, top, left[0], left[1], right[0], right[1], ln, d['record']['address'][:22], areas, bulge, d['record']['year']))

if __name__ == '__main__':
    main()
