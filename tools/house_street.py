"""Puts a whole street of houses into tools/casas/calles.json, for bake_godot.py to take them out of the ordinary
houses and hand them to casas.gd. Each must have been gathered first with tools/house_data.py.

    python tools/house_street.py "Calle Real" real 14:4292708VJ5649S 15:4192008VJ5649S ...
    python tools/house_street.py "" labradores --line=-770,-418;-860,-487 1:...      (a street the map has no name for)

"real" is the prefix of the names (real_14, real_15...); each house is given as number:reference. The front is worked
out as tools/house_fronts.py does. The height of the walls is a guess from the storeys (3.6, 6.4, 9.3, 12.3 m), to be
corrected by hand in calles.json where the photo says otherwise ("h"), as is "floors" (which parts are taken: those
with at least that many storeys).
"""
import json, math, os, sys
from shapely.geometry import Polygon, Point, LineString

HERE = os.path.dirname(os.path.abspath(__file__))
HEIGHT = {1: 3.6, 2: 6.4, 3: 9.3, 4: 12.3, 5: 15.2}

def front_of(d, street, line, others, reach=11.0):
    """`line`: every stretch of the street; `others`: the other streets' lines; `reach`: how far from the middle of the
    street a front may stand (a wide street -- an old stream bed, a square -- needs more than the usual 11 m)"""
    parts = [p for p in d['parts'] if p['floors'] >= 1]
    on = parts
    cands = []
    for p in on:
        for w in p['walls']:
            if w['len'] < 0.6: continue
            mid = Point((w['a'][0] + w['b'][0]) / 2, (w['a'][1] + w['b'][1]) / 2)
            look = Point(mid.x + w['out'][0] * 2.5, mid.y + w['out'][1] * 2.5)
            if line.distance(look) > line.distance(mid) or others.distance(look) < line.distance(look): continue      # it must look at this street, and at no other first
            s = line.project(mid); a = line.interpolate(max(0, s - 1)); b = line.interpolate(min(line.length, s + 1))
            sd = ((b.x - a.x) / a.distance(b), (b.y - a.y) / a.distance(b))
            wd = ((w['b'][0] - w['a'][0]) / w['len'], (w['b'][1] - w['a'][1]) / w['len'])
            if abs(wd[0] * sd[0] + wd[1] * sd[1]) < 0.8 or line.distance(mid) > reach: continue
            probe = Point(mid.x + w['out'][0] * 0.4, mid.y + w['out'][1] * 0.4)       # (a thin strip of the same house in front of it? then it is not the front)
            if any(Polygon(q['ring']).contains(probe) for q in parts): continue
            cands.append((tuple(w['a']), tuple(w['b']), w['out'], p['floors'], w['len']))
    if not cands: return None
    # the front is the longest straight run of those walls (a house on a corner, or with a step in it, has others:
    # casas.gd gives those a plain row of windows)
    best = None
    for seed in cands:
        (ax, az), (bx, bz), l = seed[0], seed[1], seed[4]
        dx, dz = (bx - ax) / l, (bz - az) / l
        off = lambda q: abs((q[0] - ax) * -dz + (q[1] - az) * dx)
        grp = [c for c in cands if off(c[0]) < 0.5 and off(c[1]) < 0.5]
        tot = sum(c[4] for c in grp)
        if best is None or tot > best[0]: best = (tot, grp)
    pts, outs, storeys = [], [], []
    for a_, b_, o_, f_, l_ in best[1]:
        pts += [a_, b_]; outs.append(o_); storeys.append((l_, f_))
    ox, oz = sum(o[0] for o in outs) / len(outs), sum(o[1] for o in outs) / len(outs)
    ux, uz = oz, -ox
    pts.sort(key=lambda q: q[0] * ux + q[1] * uz)
    left, right = pts[0], pts[-1]
    ln = math.dist(left, right)
    by = {}
    for l, f in storeys: by[f] = by.get(f, 0) + l
    main = max(by, key=by.get)                      # the storeys most of the front has
    bulge = max(abs((q[0] - left[0]) * -(right[1] - left[1]) / ln + (q[1] - left[1]) * (right[0] - left[0]) / ln) for q in pts)
    return left, right, ln, main, min(by), bulge

def main():
    street, prefix = sys.argv[1], sys.argv[2]
    game = json.load(open(os.path.join(HERE, '..', 'godot', 'data', 'map.json'), encoding='utf8'))
    N = game['nodes']
    from shapely.ops import unary_union, linemerge
    reach = 11.0
    for a in list(sys.argv):
        if a.startswith('--reach='):
            reach = float(a[8:]); sys.argv.remove(a)
    rows = [(r, LineString([(N[i * 2], N[i * 2 + 1]) for i in r['p']])) for r in game['roads'] if len(r['p']) > 1]
    is_mine = lambda r, l: r['n'] == street
    for a in list(sys.argv):            # --line=x,z;x,z : a street the map has no name for, by where it runs (its two ends, near enough)
        if a.startswith('--line='):
            given = LineString([tuple(float(v) for v in q.split(',')) for q in a[7:].split(';')]); sys.argv.remove(a)
            is_mine = lambda r, l, given=given: l.hausdorff_distance(given) < 6.0
    mine = [l for r, l in rows if is_mine(r, l)]
    line = unary_union(mine)                 # (every stretch of it, in one piece or several)
    others = unary_union([l for r, l in rows if not is_mine(r, l) and r['k'] == 0])
    path = os.path.join(HERE, 'casas', 'calles.json')
    out = json.load(open(path, encoding='utf8')) if os.path.exists(path) else {}
    for item in sys.argv[3:]:
        num, rc = item.split(':')
        name = '%s_%s' % (prefix, num)
        try:
            d = json.load(open(os.path.join(HERE, 'casas', rc, 'datos.json'), encoding='utf8'))
        except FileNotFoundError:
            print('%-9s %s: not gathered yet' % (name, rc)); continue
        fr = front_of(d, street, line, others, reach)
        if fr is None:
            print('%-9s %s: nothing of it stands on %s' % (name, rc, street)); continue
        left, right, ln, storeys, lowest, bulge = fr
        keep = out.get(name, {})
        out[name] = {'rc': rc, 'floors': keep.get('floors', lowest), 'front': [list(left), list(right)], 'h': keep.get('h', HEIGHT.get(storeys, 15.2))}
        photo = os.path.exists(os.path.join(HERE, 'casas', rc, 'fachada.jpg'))
        print('%-9s %s  %5.2f m  %d storeys (lowest on the street %d)  off the line %.2f m  %s  %s' % (name, rc, ln, storeys, lowest, bulge, 'photo' if photo else 'NO PHOTO', d['record']['year']))
    json.dump(out, open(path, 'w', encoding='utf8'), indent=1)
    print('->', path, len(out), 'houses')

if __name__ == '__main__':
    main()
