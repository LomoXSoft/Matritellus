"""Bakes tools/madridejos_osm.json (OpenStreetMap, ODbL) into js/mapdata.js for the old browser prototype.
The Godot game uses tools/bake_godot.py instead.
Run:  python tools/bake_map.py
"""
import json, math, random, os
random.seed(7)
HERE = os.path.dirname(os.path.abspath(__file__))
d = json.load(open(os.path.join(HERE, 'madridejos_osm.json'), encoding='utf-8'))
LAT0, LON0 = 39.4690, -3.5335
KX = math.cos(math.radians(LAT0)) * 111320.0
KZ = 110574.0
def proj(la, lo): return (round((lo - LON0) * KX, 1), round(-(la - LAT0) * KZ, 1))

els = d['elements']
nodes = {e['id']: e for e in els if e['type'] == 'node'}
ways = [e for e in els if e['type'] == 'way']

WIDTH = {'motorway': 14, 'motorway_link': 8, 'primary': 11, 'secondary': 10, 'secondary_link': 8,
         'tertiary': 9, 'residential': 7.5, 'unclassified': 7.5, 'living_street': 7, 'service': 5,
         'track': 4, 'path': 2.5, 'footway': 2.5, 'pedestrian': 6}
KIND = {'track': 1, 'path': 2, 'footway': 2, 'pedestrian': 2}   # 0 asphalt, 1 dirt, 2 paved-foot

BOUNDS = (-1950, 2200, -1900, 1900)   # xmin, xmax, zmin, zmax (metres from the church-ish origin)
def inside(x, z): return BOUNDS[0] <= x <= BOUNDS[1] and BOUNDS[2] <= z <= BOUNDS[3]

# ---------- roads ----------
nid = {}; npts = []
def node_index(osm_id):
    if osm_id not in nid:
        n = nodes[osm_id]; nid[osm_id] = len(npts); npts.append(proj(n['lat'], n['lon']))
    return nid[osm_id]
roads = []
for w in ways:
    t = w.get('tags', {})
    h = t.get('highway')
    if h not in WIDTH: continue
    run = []   # split each way into runs that stay inside the playable area
    for i in w['nodes'] + [None]:
        if i is not None and inside(*proj(nodes[i]['lat'], nodes[i]['lon'])):
            run.append(node_index(i)); continue
        if len(run) > 1:
            roads.append({'w': WIDTH[h], 'k': KIND.get(h, 0), 'h': h, 'n': t.get('name', ''), 'p': run})
        run = []

segs = []  # (x1,z1,x2,z2,halfw,type)
for r in roads:
    for a, b in zip(r['p'], r['p'][1:]):
        (x1, z1), (x2, z2) = npts[a], npts[b]
        segs.append((x1, z1, x2, z2, r['w'] / 2, r['h']))

CELL = 40.0
def cells_for(x0, z0, x1, z1, pad=0):
    for cx in range(int(math.floor((min(x0, x1) - pad) / CELL)), int(math.floor((max(x0, x1) + pad) / CELL)) + 1):
        for cz in range(int(math.floor((min(z0, z1) - pad) / CELL)), int(math.floor((max(z0, z1) + pad) / CELL)) + 1):
            yield (cx, cz)
seg_grid = {}
for i, s in enumerate(segs):
    for c in cells_for(s[0], s[1], s[2], s[3], 8): seg_grid.setdefault(c, []).append(i)

def pt_seg(px, pz, s):
    x1, z1, x2, z2 = s[0], s[1], s[2], s[3]
    dx, dz = x2 - x1, z2 - z1
    L = dx * dx + dz * dz
    t = 0 if L == 0 else max(0, min(1, ((px - x1) * dx + (pz - z1) * dz) / L))
    return math.hypot(px - (x1 + t * dx), pz - (z1 + t * dz))
def road_clear(px, pz, margin):
    for i in seg_grid.get((int(math.floor(px / CELL)), int(math.floor(pz / CELL))), ()):
        s = segs[i]
        if pt_seg(px, pz, s) < s[4] + margin: return False
    return True

def poly_of(w): return [proj(nodes[i]['lat'], nodes[i]['lon']) for i in w['nodes']]
def in_poly(x, z, poly):
    c = False; j = len(poly) - 1
    for i in range(len(poly)):
        xi, zi = poly[i]; xj, zj = poly[j]
        if (zi > z) != (zj > z) and x < (xj - xi) * (z - zi) / (zj - zi) + xi: c = not c
        j = i
    return c
def area(poly):
    n = len(poly)
    return abs(sum(poly[i][0] * poly[(i + 1) % n][1] - poly[(i + 1) % n][0] * poly[i][1] for i in range(n))) / 2

# ---------- buildings (OSM footprints -> oriented boxes) ----------
def obb(poly):
    best = None
    for i in range(len(poly) - 1):
        ex, ez = poly[i + 1][0] - poly[i][0], poly[i + 1][1] - poly[i][1]
        L = math.hypot(ex, ez)
        if L < 0.5: continue
        ux, uz = ex / L, ez / L
        us = [p[0] * ux + p[1] * uz for p in poly]; vs = [-p[0] * uz + p[1] * ux for p in poly]
        w, dd = max(us) - min(us), max(vs) - min(vs)
        if best is None or w * dd < best[0]:
            cu, cv = (max(us) + min(us)) / 2, (max(vs) + min(vs)) / 2
            best = (w * dd, cu * ux - cv * uz, cu * uz + cv * ux, w, dd, math.atan2(uz, ux))
    return best
boxes = []   # [cx, cz, w, d, rot, h, kind]  kind: 0 house 1 landmark 2 church 3 industrial
def corners(b):
    cx, cz, w, dd, rot = b[:5]; c, s = math.cos(rot), math.sin(rot)
    return [(cx + c * a * w / 2 - s * e * dd / 2, cz + s * a * w / 2 + c * e * dd / 2) for a, e in ((1, 1), (1, -1), (-1, -1), (-1, 1))]
def sat(b1, b2):
    c1, c2 = corners(b1), corners(b2)
    for b in (b1, b2):
        for ang in (b[4], b[4] + math.pi / 2):
            ax, az = math.cos(ang), math.sin(ang)
            p1 = [x * ax + z * az for x, z in c1]; p2 = [x * ax + z * az for x, z in c2]
            if max(p1) < min(p2) or max(p2) < min(p1): return False
    return True
box_grid = {}
def add_box(b):
    i = len(boxes); boxes.append(b)
    r = math.hypot(b[2], b[3]) / 2
    for c in cells_for(b[0] - r, b[1] - r, b[0] + r, b[1] + r): box_grid.setdefault(c, []).append(i)
def box_free(b):
    r = math.hypot(b[2], b[3]) / 2
    seen = set()
    for c in cells_for(b[0] - r, b[1] - r, b[0] + r, b[1] + r):
        for i in box_grid.get(c, ()):
            if i in seen: continue
            seen.add(i)
            if sat(b, boxes[i]): return False
    return True

for w in ways:
    t = w.get('tags', {})
    if 'building' not in t: continue
    poly = poly_of(w)
    if len(poly) < 4: continue
    o = obb(poly)
    if not o or o[3] < 3 or o[4] < 3: continue
    _, cx, cz, bw, bd, rot = o
    fill = area(poly) / (bw * bd)
    if fill < 0.6:  # L/U shaped: shrink so the box does not swallow the street
        k = math.sqrt(max(fill, 0.35) / 0.8); bw *= k; bd *= k
    # footprints are rarely rectangles: shrink the box until it stays off every street (or drop it)
    def off_street(bx):
        cs = corners(bx)
        for (x1, z1), (x2, z2) in zip(cs, cs[1:] + cs[:1]):
            n = max(2, int(math.hypot(x2 - x1, z2 - z1) / 3))
            for i in range(n):
                if not road_clear(x1 + (x2 - x1) * i / n, z1 + (z2 - z1) * i / n, 2.0): return False
        return road_clear(bx[0], bx[1], 2.0)
    for _ in range(14):
        if off_street([cx, cz, bw, bd, rot]): break
        bw *= 0.88; bd *= 0.88
    else: continue
    if bw < 3.5 or bd < 3.5: continue
    kind, h = 0, 6.0
    b = t['building']; am = t.get('amenity', '')
    if b in ('church', 'chapel', 'cathedral') or am == 'place_of_worship': kind, h = 2, 13
    elif b in ('industrial', 'warehouse', 'retail', 'commercial', 'farm_auxiliary', 'barn') or bw * bd > 900: kind, h = 3, 7.5
    elif t.get('name') or am: kind, h = 1, 9
    if 'building:levels' in t:
        try: h = max(h, 3.2 * float(t['building:levels']))
        except ValueError: pass
    add_box([round(cx, 1), round(cz, 1), round(bw, 1), round(bd, 1), round(rot, 3), h, kind])

# ---------- parks / fields ----------
areas = []   # {'k': kind, 'p': [x,z,...]}  0 park 1 pitch 2 vineyard 3 orchard 4 farmland 5 water
trees = []   # [x, z, type]  0 round tree 1 olive 2 cypress
no_house = []
for w in ways:
    t = w.get('tags', {})
    if 'highway' in t or 'building' in t: continue
    lu, le = t.get('landuse'), t.get('leisure')
    k = None
    if le in ('park', 'garden', 'playground', 'recreation_ground') or lu in ('grass', 'recreation_ground', 'meadow'): k = 0
    elif le in ('pitch', 'sports_centre'): k = 1
    elif le == 'swimming_pool': k = 5
    elif lu == 'vineyard': k = 2
    elif lu == 'orchard': k = 3
    elif lu == 'farmland': k = 4
    if k is None or w['nodes'][0] != w['nodes'][-1]: continue
    poly = poly_of(w)
    if len(poly) < 4 or not all(inside(*p) for p in poly): continue
    areas.append({'k': k, 'p': [c for p in poly[:-1] for c in p]})
    if k in (0, 1, 5): no_house.append(poly)
    if k in (0, 3):
        step = 13 if k == 0 else 11
        xs = [p[0] for p in poly]; zs = [p[1] for p in poly]
        x = min(xs)
        while x < max(xs):
            z = min(zs)
            while z < max(zs):
                px, pz = x + random.uniform(-2.5, 2.5), z + random.uniform(-2.5, 2.5)
                if in_poly(px, pz, poly) and road_clear(px, pz, 3) and box_free([px, pz, 4, 4, 0]):
                    trees.append([round(px, 1), round(pz, 1), 0 if k == 0 else 1])
                z += step
            x += step
olives = [t for t in trees if t[2] == 1]; others = [t for t in trees if t[2] != 1]
random.shuffle(olives); trees = others + olives[:2600]

# ---------- procedural houses along the real streets ----------
res_nodes = set()
for r in roads:
    if r['h'] in ('residential', 'living_street'):
        for i in r['p']: res_nodes.add((int(npts[i][0] // 60), int(npts[i][1] // 60)))
def urban(x, z):
    cx, cz = int(x // 60), int(z // 60)
    return any((cx + a, cz + b) in res_nodes for a in (-1, 0, 1) for b in (-1, 0, 1))
n_osm = len(boxes)
for r in roads:
    if r['h'] not in ('residential', 'living_street', 'tertiary', 'secondary', 'unclassified', 'primary'): continue
    carry = random.uniform(2, 6)
    for a, b in zip(r['p'], r['p'][1:]):
        (x1, z1), (x2, z2) = npts[a], npts[b]
        L = math.hypot(x2 - x1, z2 - z1)
        if L < 1: continue
        ux, uz = (x2 - x1) / L, (z2 - z1) / L
        s = carry
        while s < L:
            hw = random.uniform(8, 12)
            px, pz = x1 + ux * s, z1 + uz * s
            if r['h'] in ('residential', 'living_street') or urban(px, pz):
                for side in (1, -1):
                    hd = random.uniform(8, 11)
                    off = r['w'] / 2 + 2.2 + hd / 2
                    cx, cz = px - uz * off * side, pz + ux * off * side
                    bx = [round(cx, 1), round(cz, 1), round(hw - 0.6, 1), round(hd, 1), round(math.atan2(uz, ux), 3),
                          random.choice([4.2, 4.6, 5, 6.8, 7.2, 7.6]), 0]
                    cs = corners(bx)
                    pts = cs + [(cx, cz)] + [((c1[0] + c2[0]) / 2, (c1[1] + c2[1]) / 2) for c1, c2 in zip(cs, cs[1:] + cs[:1])]
                    ok = all(road_clear(qx, qz, 1.2) for qx, qz in pts)
                    if ok and not any(in_poly(cx, cz, p) for p in no_house) and box_free(bx): add_box(bx)
            s += hw
        carry = s - L

# street trees / cypresses sprinkled on free spots in town
for _ in range(900):
    x, z = random.uniform(-900, 900), random.uniform(-1100, 1300)
    if urban(x, z) and road_clear(x, z, 1.5) and box_free([x, z, 3, 3, 0]):
        trees.append([round(x, 1), round(z, 1), random.choice([0, 0, 2])])

# ---------- POIs ----------
pois = []
for e in els:
    t = e.get('tags', {})
    if 'name' not in t or 'highway' in t: continue
    if e['type'] == 'node': x, z = proj(e['lat'], e['lon'])
    else:
        pl = poly_of(e); x = round(sum(p[0] for p in pl) / len(pl), 1); z = round(sum(p[1] for p in pl) / len(pl), 1)
    pois.append({'n': t['name'], 't': t.get('amenity') or t.get('shop') or t.get('man_made') or t.get('leisure') or t.get('building') or '', 'x': x, 'z': z})

out = {'nodes': [c for p in npts for c in p],
       'roads': [{'w': r['w'], 'k': r['k'], 'h': r['h'], 'n': r['n'], 'p': r['p']} for r in roads],
       'bounds': BOUNDS, 'boxes': boxes, 'areas': areas, 'trees': trees, 'pois': pois}
path = os.path.join(HERE, '..', 'js', 'mapdata.js')
with open(path, 'w', encoding='utf-8') as f:
    f.write('// Generated by tools/bake_map.py. Map data (c) OpenStreetMap contributors, ODbL.\nwindow.MAP = ')
    json.dump(out, f, ensure_ascii=False, separators=(',', ':'))
    f.write(';\n')
print('nodes', len(npts), 'roads', len(roads), 'osm boxes', n_osm, 'houses', len(boxes) - n_osm, 'areas', len(areas), 'trees', len(trees), 'pois', len(pois), 'bytes', os.path.getsize(path))
for p in pois:
    if any(k in p['n'] for k in ('Divino', 'Plaza del Ayu', 'Labradores', 'Molino', 'Ayuntamiento de', 'Kiosko', 'Tanatorio')):
        print(p['n'].encode('ascii', 'replace').decode(), p['x'], p['z'])
xs = out['nodes'][0::2]; zs = out['nodes'][1::2]; print('bounds', min(xs), max(xs), min(zs), max(zs))
