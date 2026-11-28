"""Bakes the Godot map: streets/land use from OpenStreetMap + real building footprints from the Spanish Catastro.

  python tools/bake_godot.py        ->  godot/data/map.json

Inputs (both in tools/):
  madridejos_osm.json                 Overpass export (ODbL, (c) OpenStreetMap contributors)
  catastro/A.ES.SDGC.BU.45088.zip     INSPIRE Buildings for Madridejos ((c) Dirección General del Catastro)
  ign/mdt05_utm.npz                   the 5 m elevation model (MDT05, (c) Instituto Geográfico Nacional, CC BY 4.0; tools/fetch_mdt.py)
Needs: pip install shapely numpy
"""
import json, math, os, random, re, zipfile, zlib
import numpy as np
import shapely
from shapely.geometry import Polygon, LineString, Point
from shapely.geometry.polygon import orient
from shapely.ops import unary_union
from shapely.strtree import STRtree

random.seed(7)
HERE = os.path.dirname(os.path.abspath(__file__))
LAT0, LON0 = 39.4690, -3.5335
KX = math.cos(math.radians(LAT0)) * 111320.0
KZ = 110574.0
BOUNDS = (-1950, 2200, -1900, 1900)   # xmin, xmax, zmin, zmax in metres
FLOOR_H = 3.1

def proj(la, lo): return ((lo - LON0) * KX, -(la - LAT0) * KZ)
def inside(x, z, pad=0): return BOUNDS[0] - pad <= x <= BOUNDS[1] + pad and BOUNDS[2] - pad <= z <= BOUNDS[3] + pad
def r1(v): return round(float(v), 1)
def r2(v): return round(float(v), 2)

def utm30_to_local(e, n):
    """ETRS89 / UTM zone 30N (EPSG:25830) -> the game's local metres. Vectorised."""
    a, f, k0 = 6378137.0, 1 / 298.257222101, 0.9996
    e2 = f * (2 - f); ep2 = e2 / (1 - e2)
    m = n / k0
    mu = m / (a * (1 - e2 / 4 - 3 * e2 ** 2 / 64 - 5 * e2 ** 3 / 256))
    e1 = (1 - math.sqrt(1 - e2)) / (1 + math.sqrt(1 - e2))
    p1 = (mu + (3 * e1 / 2 - 27 * e1 ** 3 / 32) * np.sin(2 * mu) + (21 * e1 ** 2 / 16 - 55 * e1 ** 4 / 32) * np.sin(4 * mu)
          + (151 * e1 ** 3 / 96) * np.sin(6 * mu) + (1097 * e1 ** 4 / 512) * np.sin(8 * mu))
    s, c, t = np.sin(p1), np.cos(p1), np.tan(p1)
    n1 = a / np.sqrt(1 - e2 * s * s); t1 = t * t; c1 = ep2 * c * c
    rr = a * (1 - e2) / (1 - e2 * s * s) ** 1.5
    d = (e - 500000.0) / (n1 * k0)
    lat = p1 - (n1 * t / rr) * (d ** 2 / 2 - (5 + 3 * t1 + 10 * c1 - 4 * c1 ** 2 - 9 * ep2) * d ** 4 / 24
                                + (61 + 90 * t1 + 298 * c1 + 45 * t1 ** 2 - 252 * ep2 - 3 * c1 ** 2) * d ** 6 / 720)
    lon = math.radians(-3.0) + (d - (1 + 2 * t1 + c1) * d ** 3 / 6 + (5 - 2 * c1 + 28 * t1 - 3 * c1 ** 2 + 8 * ep2 + 24 * t1 ** 2) * d ** 5 / 120) / c
    return (np.degrees(lon) - LON0) * KX, -(np.degrees(lat) - LAT0) * KZ

# ====================== OpenStreetMap: streets, land use, POIs ======================
osm = json.load(open(os.path.join(HERE, 'madridejos_osm.json'), encoding='utf-8'))
els = osm['elements']
onodes = {e['id']: e for e in els if e['type'] == 'node'}
ways = [e for e in els if e['type'] == 'way']
WIDTH = {'motorway': 14, 'motorway_link': 8, 'primary': 11, 'secondary': 10, 'secondary_link': 8, 'tertiary': 9,
         'residential': 7.5, 'unclassified': 7.5, 'living_street': 7, 'service': 5, 'track': 4, 'path': 2.5, 'footway': 2.5, 'pedestrian': 6}
KIND = {'track': 1, 'path': 2, 'footway': 2, 'pedestrian': 2}   # 0 asphalt, 1 dirt, 2 footpath
# Ways of the map's source that are not there: their points are still numbered (so no other street's change), but they
# make no street. The aisle drawn through the middle of the MasAhorro's car park, across its double row of bays (the
# orthophoto and Street View: its two lanes run either side of that row; Pretil and Sistemas, 17 November 2026).
DROP_WAYS = {1304199745}

nid, npts, roads = {}, [], []
def node_index(i):
    if i not in nid:
        nid[i] = len(npts); npts.append(proj(onodes[i]['lat'], onodes[i]['lon']))
    return nid[i]
# One-way streets as the map's source has them (the user, 16 November 2026: the traffic was being put right street by
# street): "ow": 1 on a street that is driven only in the order of its points. OSM's oneway=-1 is turned round so that
# it reads the same; a roundabout is one way unless it says otherwise. Footpaths and tracks never are.
def one_way(t, h):
    if KIND.get(h, 0) != 0 or t.get('oneway') == 'no': return 0
    if t.get('oneway') in ('yes', 'true', '1'): return 1
    if t.get('oneway') == '-1': return -1
    return 1 if t.get('junction') in ('roundabout', 'circular') else 0
for w in ways:
    t = w.get('tags', {}); h = t.get('highway')
    if h not in WIDTH: continue
    if w['id'] in DROP_WAYS:
        for i in w['nodes']:
            if inside(*proj(onodes[i]['lat'], onodes[i]['lon'])): node_index(i)
        continue
    ow = one_way(t, h)
    run = []
    for i in w['nodes'] + [None]:
        if i is not None and inside(*proj(onodes[i]['lat'], onodes[i]['lon'])):
            run.append(node_index(i)); continue
        if len(run) > 1:
            roads.append({'w': WIDTH[h], 'k': KIND.get(h, 0), 'h': h, 'n': t.get('name', ''), 'p': run[::-1] if ow < 0 else run})
            if ow: roads[-1]['ow'] = 1
        run = []
print('one way (OpenStreetMap): %d stretches' % sum(1 for r in roads if r.get('ow')))
# Streets the map's source names wrongly or not at all, by where they run (their two ends, within a few metres).
# The two parallel streets of the UA-20 development (user, 12 November 2026): Segadores is the southern one.
# (Corrected the same evening: I had them the wrong way round. z runs SOUTH, so the street at z -377..-463 is the southern
# one: Segadores. The houses' own names in the code -- segadores_N, labradores_N -- were given before this and stay crossed.)
# The two streets of the 2006 development between the top of the Cristo del Humilladero and the Avenida de la
# Constitución, which the map's source calls "Avenida de la Constitución" (Catastro, Google Maps; the user, 27 November
# 2026): the Calle Sueños, from the avenue west to the Humilladero, and the Calle Ilusión, the L from the Sueños south and
# then east to the avenue. And the Calle de Santa Margarita, the row back to back with the Sueños, which the map's
# source calls "Calle de la Virgen del Sagrario" (Catastro: CL SANTA MARGARITA; Google Maps: Calle Sta. Margarita).
RENAME = [((-796.2, -377.4), (-908.5, -462.8), 'Calle de los Segadores'), ((-769.6, -418.3), (-860.1, -487.0), 'Calle de los Labradores'), ((-10.0, -660.0), (-122.0, -690.0), 'Calle Sueños'), ((-57.0, -672.0), (3.0, -612.0), 'Calle Ilusión'), ((-6.0, -707.0), (-104.0, -733.0), 'Calle de Santa Margarita')]
for (ax, az), (bx, bz), name in RENAME:
    hit = [r for r in roads if min(math.dist(npts[r['p'][0]], (ax, az)) + math.dist(npts[r['p'][-1]], (bx, bz)), math.dist(npts[r['p'][0]], (bx, bz)) + math.dist(npts[r['p'][-1]], (ax, az))) < 8.0]
    for r in hit: r['n'] = name
# Streets the map's source draws metres off where they run, redrawn through the given points (the first and last move
# the street's own end points; a shared end only slides along the street it joins). The Calle Rollo, the dead-end lane
# off the Calle del Rollo: drawn ~5 m east of itself, through the house at its mouth (orthophoto, Catastro, Street View;
# Texturas, 23 November 2026). New middle points are numbered after every other, so no other street's numbers change.
RESHAPE = [('Calle Rollo', (-510.0, 122.0), (-520.0, 86.0), [(-517.0, 124.0), (-518.0, 108.0), (-520.0, 95.0), (-523.0, 86.0), (-524.3, 79.0)])]
for name, a, b, pts in RESHAPE:
    for r in roads:
        if r['n'] != name or len(r['p']) < 2: continue
        e0, e1 = r['p'][0], r['p'][-1]
        if math.dist(npts[e0], a) < 4.0 and math.dist(npts[e1], b) < 4.0: na, nb = e0, e1
        elif math.dist(npts[e1], a) < 4.0 and math.dist(npts[e0], b) < 4.0: na, nb = e1, e0
        else: continue
        npts[na], npts[nb] = pts[0], pts[-1]
        mid = []
        for q in pts[1:-1]:
            mid.append(len(npts)); npts.append(q)
        r['p'] = [na] + mid + [nb] if e0 == na else [nb] + mid[::-1] + [na]
        print('reshaped: %s through %d points' % (name, len(pts)))
    print('street renamed: %s (%d stretch%s)' % (name, len(hit), '' if len(hit) == 1 else 'es'))
# Streets that are pedestrian and paved in setts from a given node on, though the map's source has them for cars: the
# Calle Real from its crossroads with Colón and La Palma down to the end, among the shops (Street View, November 2024;
# the user, 15 November 2026: "es zona peatonal y el suelo está empedrado"). That stretch becomes a footpath (k 2: no
# traffic, no asphalt, no kerbs; empedrado.gd lays the setts) but keeps a car street's corridor, so no house moves.
PAVED = [('Calle Real', (-70.1, -59.6))]          # the street, and the node from which (away from its north end) it is paved
for name, at in PAVED:
    for r in [r for r in roads if r['n'] == name and r['k'] == 0]:
        ps = [npts[i] for i in r['p']]
        j = min(range(len(ps)), key=lambda q: math.dist(ps[q], at))
        if math.dist(ps[j], at) > 3.0 or j in (0, len(ps) - 1): continue
        a, b = r['p'][:j + 1], r['p'][j:]
        za = sum(npts[i][1] for i in a) / len(a); zb = sum(npts[i][1] for i in b) / len(b)
        paved, rest = (b, a) if zb > za else (a, b)              # (the paved part is the southern one)
        r['p'] = rest
        roads.append({'w': r['w'], 'k': 2, 'h': 'pedestrian', 'n': name, 'p': paved, 'paved': 1})
        print('paved and closed to traffic: %s, %d nodes' % (name, len(paved)))
# ...and stretches paved between two nodes (the parts of the street whose middle lies between them, east to west): the
# Calle del Salvador from where it leaves the street at its west end to past no. 19, setts down the middle and brick at
# the sides like the Calle Real (Street View 2013, 2020 and November 2024; the user, 15 November 2026: "Si es peatonal
# empedrada, se hace así"); the asphalt starts by no. 23
PAVED_SPANS = [('Calle del Salvador', (-140.1, 2.1), (10.8, 22.2))]
for name, at0, at1 in PAVED_SPANS:
    x0, x1 = min(at0[0], at1[0]), max(at0[0], at1[0])
    for r in [r for r in roads if r['n'] == name and r['k'] == 0]:
        cuts = sorted({j for j, i in enumerate(r['p']) if 0 < j < len(r['p']) - 1 and min(math.dist(npts[i], at0), math.dist(npts[i], at1)) < 3.0})
        pieces, s = [], 0
        for j in cuts + [len(r['p']) - 1]:
            pieces.append(r['p'][s:j + 1]); s = j
        keep = []
        for piece in pieces:
            cx = sum(npts[i][0] for i in piece) / len(piece)
            if x0 <= cx <= x1:
                roads.append({'w': r['w'], 'k': 2, 'h': 'pedestrian', 'n': name, 'p': piece, 'paved': 1})
                print('paved and closed to traffic: %s, %d nodes' % (name, len(piece)))
            else:
                keep.append(piece)
        if len(keep) == len(pieces): continue
        r['p'] = keep[0] if keep else []
        for piece in keep[1:]:
            roads.append(dict(r, p=piece))
roads[:] = [r for r in roads if len(r['p']) > 1]
# ...and lanes paved in grey concrete pavers from wall to wall: the narrow west end of the Calle de Santo Domingo, past
# its crossroads by no. 14 (Street View, November 2024). Cars do use it, but it is too narrow for the game's traffic
# (the user, 15 November 2026: "Ponle adoquín" and then "Aunque en la realidad circulen coches puede ser un problema
# para el juego. Mejor cortar el tráfico ahí"), so it becomes a footpath as wide as a street (k 2: no traffic, no parked
# cars) with the corridor of a car street (no house moves); "paved": 2 has empedrado.gd lay the grey pavers.
PAVED_LANES = [('Calle de Santo Domingo', (-374.9, 38.3))]    # the street, and the node from which (westwards) it is paved
for name, at in PAVED_LANES:
    for r in [r for r in roads if r['n'] == name and r['k'] == 0 and not r.get('paved')]:
        ps = [npts[i] for i in r['p']]
        j = min(range(len(ps)), key=lambda q: math.dist(ps[q], at))
        if math.dist(ps[j], at) > 3.0: continue
        a, b = r['p'][:j + 1], r['p'][j:]
        xa = sum(npts[i][0] for i in a) / len(a); xb = sum(npts[i][0] for i in b) / len(b)
        paved, rest = (a, b) if xa < xb else (b, a)              # (the paved part is the western one)
        if len(paved) < 2: continue
        if len(rest) > 1:
            r['p'] = rest
            roads.append(dict(r, p=paved, k=2, h='pedestrian', paved=2))
        else:
            r.update(k=2, h='pedestrian', paved=2)
        print('paved in grey pavers and closed to traffic: %s, %d nodes' % (name, len(paved)))
# ...and the alley of the Cafetería Rize, off the Avenida de Juan Carlos I (godot/scripts/rize.gd; the user, 21 November
# 2026: "la cafetería rice con todo su callejón incluido"): an unnamed service road in OSM, paved in grey setts from
# wall to wall (Street View, November 2024), with the café's tables in it. A footpath closed to traffic like the lane
# above ("paved": 2), but with a service road's narrow corridor ("narrow": no house moves; the alley is 4 m wide).
PAVED_ALLEYS = [((-200.0, 87.0), (-194.0, 116.0))]      # an unnamed road, by its two ends
for a_, b_ in PAVED_ALLEYS:
    for r in roads:
        if r['n'] or r['k'] != 0 or r.get('paved'): continue
        ps = [npts[i] for i in r['p']]
        if min(math.dist(ps[0], a_), math.dist(ps[-1], a_)) < 3.0 and min(math.dist(ps[0], b_), math.dist(ps[-1], b_)) < 3.0:
            r.update(k=2, h='pedestrian', paved=2, narrow=1)
            r.pop('ow', None)
            print('alley paved in grey pavers and closed to traffic: %d nodes' % len(ps))
# ...and the Travesía del Clavel, the alley between the Calle de San Rafael and the Calle del Clavel (godot/scripts/
# travesia.gd; the user, 21 November 2026: "que sea peatonal"): a walk for people on foot raised over both streets. A
# footpath closed to traffic that travesia.gd floors itself ("paved": 5), with a car street's corridor: no house moves.
_travesia_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'travesia.gd')
TRAVESIA = os.path.exists(_travesia_gd) and 'const READY := true' in open(_travesia_gd, encoding='utf-8').read()
if TRAVESIA:
    for r in roads:
        if r['n'] == 'Travesía del Clavel' and r['k'] == 0:
            r.update(k=2, h='pedestrian', paved=5)
            r.pop('ow', None)
            print('the Travesía del Clavel: a raised walk, closed to traffic (%d nodes)' % len(r['p']))
# ...and streets paved like the Calle Real -- setts down the middle, brick along the houses, all at one level -- that cars
# still drive: the Calle de las Monjas from its south end to its crossroads with Santiago Apóstol, by the convent of
# Santa Ana (Street View, November 2024; the user, 15 November 2026: "La calle está empedrada pero no es peatonal").
# The stretch stays a car street (k 0: traffic, parked cars, the same corridor, no house moves); "paved": 3 has
# empedrado.gd lay the brick and the setts over its pavements and its asphalt.
PAVED_STREETS = [('Calle de las Monjas', (-488.4, -81.3), (-523.5, 36.4))]    # the street, the node where its paving ends, and the end it is paved to
for name, at, end in PAVED_STREETS:
    for r in [r for r in roads if r['n'] == name and r['k'] == 0 and not r.get('paved')]:
        ps = [npts[i] for i in r['p']]
        j = min(range(len(ps)), key=lambda q: math.dist(ps[q], at))
        if math.dist(ps[j], at) > 3.0: continue
        a, b = r['p'][:j + 1], r['p'][j:]
        da = min(math.dist(npts[i], end) for i in a); db = min(math.dist(npts[i], end) for i in b)
        paved, rest = (a, b) if da < db else (b, a)
        if len(paved) < 2 or min(da, db) > 3.0: continue
        if len(rest) > 1:
            r['p'] = rest
            roads.append(dict(r, p=paved, paved=3))
        else:
            r['paved'] = 3
        print('paved, open to traffic: %s, %d nodes' % (name, len(paved)))
# The fairground and market ("Recinto ferial y mercadillo", godot/scripts/ferial.gd; the user, 17 November 2026: "El
# recinto ferial sin líneas de tráfico. Y tampoco deben circular coches por ahí"): its unnamed roads -- the three paths
# and their loop, the roundabout of the fountain, the road from it to the east, the way in from the north, the lane by
# the market's square -- become footpaths as wide as streets (k 2: no traffic, no parked cars, no lines) with a car
# street's corridor (no house moves); "paved": 4 has ferial.gd lay their asphalt. The street to its north (by the
# pergola) and the road to its east stay streets for cars.
FERIAL_ZONE = Polygon([(110, 585), (165, 551), (196, 551), (196, 600), (190, 625), (160, 720), (85, 720), (85, 640), (110, 600)])
def _half_point(r):
    ps = [npts[i] for i in r['p']]
    L = sum(math.dist(a, b) for a, b in zip(ps, ps[1:]))
    t = L / 2.0
    for a, b in zip(ps, ps[1:]):
        d = math.dist(a, b)
        if d >= t and d > 0:
            return Point(a[0] + (b[0] - a[0]) * t / d, a[1] + (b[1] - a[1]) * t / d)
        t -= d
    return Point(ps[-1])
_closed = 0
for r in roads:
    if r['k'] == 0 and not r.get('n') and r['h'] == 'unclassified' and not r.get('paved') and FERIAL_ZONE.contains(_half_point(r)):
        r.update(k=2, h='pedestrian', paved=4)
        r.pop('ow', None)
        _closed += 1
print('the fairground: %d roads closed to traffic' % _closed)
ferial_park = Polygon([(176, 476), (156, 530), (210, 549), (230, 496)]).buffer(1.0)      # the park north of it, by the Paseo del Cristo: the map plants no trees there (ferial.gd plants its own)
def poly_of(w): return [proj(onodes[i]['lat'], onodes[i]['lon']) for i in w['nodes']]

# the corridor every street is guaranteed to keep free of buildings (centre lines drift a little from reality)
def corridor_half(r): return (1.9 if r.get('narrow') else 2.4) if r.get('paved') else 1.0 if r['k'] == 2 else 1.5 if r['k'] == 1 else 1.9 if r['h'] == 'service' else 2.4
corridor = unary_union([LineString([npts[i] for i in r['p']]).buffer(corridor_half(r), quad_segs=3) for r in roads])
road_lines = [LineString([npts[i] for i in r['p']]) for r in roads]
road_tree = STRtree(road_lines)
def road_dist(x, z):
    i = road_tree.nearest(Point(x, z)); return road_lines[i].distance(Point(x, z)), roads[i]

# ====================== Catastro: building parts ======================
zf = zipfile.ZipFile(os.path.join(HERE, 'catastro', 'A.ES.SDGC.BU.45088.zip'))
def read(suffix):
    name = [n for n in zf.namelist() if n.endswith(suffix)][0]
    return zf.read(name).decode('utf-8')
use_of, year_of = {}, {}
for m in re.finditer(r'<bu-ext2d:Building gml:id="ES\.SDGC\.BU\.([^"]+)">(.*?)</bu-ext2d:Building>', read('.building.gml'), re.S):
    u = re.search(r'<bu-ext2d:currentUse>([^<]*)<', m.group(2)); y = re.search(r'<bu-core2d:beginning>(\d{4})', m.group(2))
    use_of[m.group(1)] = u.group(1) if u else ''; year_of[m.group(1)] = int(y.group(1)) if y else 0
raw = []   # (building part id, floors, ring as Nx2 array in UTM)
for m in re.finditer(r'<bu-ext2d:BuildingPart gml:id="ES\.SDGC\.BU\.([^"]+)">(.*?)</bu-ext2d:BuildingPart>', read('.buildingpart.gml'), re.S):
    fl = re.search(r'numberOfFloorsAboveGround>(\d+)<', m.group(2))
    floors = int(fl.group(1)) if fl else 0
    if floors < 1: continue                       # yards, pools, basements only
    for ring in re.findall(r'<gml:exterior>.*?<gml:posList[^>]*>([^<]+)</gml:posList>', m.group(2), re.S):
        v = np.array(ring.split(), dtype=float).reshape(-1, 2)
        if len(v) >= 4: raw.append((m.group(1), floors, v))

# OSM tells us which footprints are churches / named public buildings
churches, named = [], []
for w in ways:
    t = w.get('tags', {})
    if 'building' not in t or len(w['nodes']) < 4: continue
    p = Polygon(poly_of(w)).buffer(0)
    if t.get('amenity') == 'place_of_worship' or t['building'] in ('church', 'chapel', 'cathedral'): churches.append(p)
    elif t.get('name') or t.get('amenity') in ('townhall', 'school', 'police'): named.append(p)
church_u, named_u = unary_union(churches), unary_union(named)

# The town hall gets a hand-built model in the game (godot/scripts/plaza.gd): find its footprint, keep the generic
# Catastro parts out of it, and describe the square in the building's own frame (u along the facade, n towards the plaza).
townhall = {}
th_zone = None
for w in ways:
    if w.get('tags', {}).get('amenity') == 'townhall' and len(w['nodes']) > 3:
        pl = poly_of(w); best = None
        for a, b in zip(pl, pl[1:]):
            L = math.hypot(b[0] - a[0], b[1] - a[1])
            if best is None or L > best[0]: best = (L, a, b)
        L, a, b = best
        ux, uz = (b[0] - a[0]) / L, (b[1] - a[1]) / L
        nx, nz = -uz, ux
        c = Polygon(pl).centroid
        mx, mz = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
        if (c.x - mx) * nx + (c.y - mz) * nz > 0:          # the long edge found is the front: n must point away from the building
            ux, uz, nx, nz = -ux, -uz, -nx, -nz
        depth = max(abs((q[0] - mx) * nx + (q[1] - mz) * nz) for q in pl)
        townhall = {'m': [r2(mx), r2(mz)], 'u': [round(ux, 4), round(uz, 4)], 'len': r2(L), 'depth': r2(depth)}
        th_zone = Polygon(pl).buffer(1.0)
def plaza_local(x, z):
    mx, mz = townhall['m']; ux, uz = townhall['u']
    return (x - mx) * ux + (z - mz) * uz, (x - mx) * -uz + (z - mz) * ux
# the square itself (the park polygon in front of the town hall): its trees, paving and furniture are placed by hand
plaza_zone = None
for w in ways:
    t = w.get('tags', {})
    if townhall and t.get('leisure') == 'park' and 'Ayuntamiento' in t.get('name', '') and len(w['nodes']) > 3:
        pl = poly_of(w)
        plaza_zone = Polygon(pl).buffer(2.0)
        townhall['park'] = [[r2(v) for v in plaza_local(x, z)] for x, z in pl[:-1]]
def plaza_keeps_clear(x, z):
    if not townhall: return False
    u, n = plaza_local(x, z)
    if abs(u) < townhall['len'] / 2 + 3 and -townhall['depth'] - 2 < n < 3: return True
    return plaza_zone is not None and plaza_zone.contains(Point(x, z))

# The parish church of the Divino Salvador is hand-built too (godot/scripts/iglesia.gd), from the user's walk round it
# and the aerial photo. Its frame, read off the Catastro footprint: the origin is the south-west corner of the nave,
# u runs east along the south wall, the nave lies to the north of that line (wid), and the tower stands in the
# north-west corner (tower: from s, to s, from d, to d, with d measured SOUTH of the south wall, so negative).
CHURCH = {'o': (3.5, 69.07), 'u': (0.9876, 0.157), 'len': 58.5, 'wid': 27.4, 'tower': (-1.5, 5.5, -28.35, -22.65)}
church = {}
church_zone = None
church_poly = None
for w in ways:
    if 'Divino Salvador' in w.get('tags', {}).get('name', '') and w.get('tags', {}).get('building') and len(w['nodes']) > 3:
        church_zone = Polygon(poly_of(w)).buffer(1.5)
        ux, uz = CHURCH['u']; ox, oz = CHURCH['o']
        def church_at(s, d, ox=ox, oz=oz, ux=ux, uz=uz): return (ox + ux * s - uz * d, oz + uz * s + ux * d)      # d: metres south of the south wall
        ts0, ts1, td0, td1 = CHURCH['tower']
        church_poly = Polygon([church_at(0, 0), church_at(CHURCH['len'], 0), church_at(CHURCH['len'], -CHURCH['wid']), church_at(0, -CHURCH['wid'])]).union(
            Polygon([church_at(ts0, td0), church_at(ts1, td0), church_at(ts1, td1), church_at(ts0, td1)]))
        church = {'o': [r2(ox), r2(oz)], 'u': [round(ux, 4), round(uz, 4)], 'len': CHURCH['len'], 'wid': CHURCH['wid'], 'tower': list(CHURCH['tower'])}

# The health centre (godot/scripts/salud.gd), hand-built from the user's street photos: Catastro's parts of its parcel
# are not drawn; its own frame has its origin at the south-west corner (Callejón Pando and the square), u runs east
# along the Callejón Pando and the building lies to the north of that line.
SALUD_RC = '4590037VJ5649S'
SALUD = {'o': (194.1, 158.0), 'u': (0.958, 0.288)}
def salud_at(s, t, o=SALUD['o'], u=SALUD['u']): return (o[0] + u[0] * s + u[1] * t, o[1] + u[1] * s - u[0] * t)      # t: metres north of the south wall
salud_poly = unary_union([Polygon([salud_at(*q) for q in ring]) for ring in (
    [(-0.7, 0), (35.8, 0), (35.8, 24.6), (23.6, 24.6), (23.6, 28.6), (4, 28.6), (4, 24.6), (-0.7, 24.6)],
    [(35.8, 3.5), (48.3, 3.5), (48.3, 4.8), (64.4, 4.8), (64.4, 13), (35.8, 13)])])
salud = {'o': list(SALUD['o']), 'u': list(SALUD['u'])}

# The Petril: the old convent of San Francisco, its church and the little raised square in front of them, at the
# corner of the Calle de las Cruces and the Calle de San Francisco (godot/scripts/petril.gd; the user, 14 November
# 2026, with street photos kept in referencias/petril/). Catastro's parts of its two parcels stay what they are for
# everybody else -- a block to bump into, a neighbour that hides walls, a roof on the map -- but nothing is drawn for
# them: petril.gd builds the lot. Each part: how high its walls stand (None: not even a block -- the porch of the
# church, which people walk under). Its own frame: the origin is the south-west corner of the church (San Francisco
# and the square), u runs east along the church's south front, and the square lies to the south of that line.
PETRIL_PARTS = {'4289026VJ5648N': {'part1': 11.6, 'part3': 14.2, 'part2': 3.4, 'part4': None},      # the church: nave, head, the lean-to by the head, the porch
                '4289023VJ5648N': {'part1': 7.3}}                                                    # the convent
PETRIL = {'o': (-108.9, 261.7), 'u': (0.9784, 0.2066)}
def petril_at(s, t, o=PETRIL['o'], u=PETRIL['u']): return (o[0] + u[0] * s - u[1] * t, o[1] + u[1] * s + u[0] * t)      # t: metres south of the church's front
# nothing of the town's own grows or stands in the square, on its retaining wall or at the foot of it
petril_zone = Polygon([petril_at(-4.5, -30.0), petril_at(35.5, -27.0), petril_at(34.0, 27.5), petril_at(16.0, 25.5), petril_at(-6.5, 21.0)])
petril = {'o': list(PETRIL['o']), 'u': list(PETRIL['u'])}
petril_parts = []
_petril_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'petril.gd')
if not (os.path.exists(_petril_gd) and 'const READY := true' in open(_petril_gd, encoding='utf-8').read()):      # (not built yet: the convent stays an ordinary building)
    PETRIL_PARTS, petril, petril_zone = {}, {}, Polygon()

# The windmill and its yard on the Calle de Dulcinea del Toboso (godot/scripts/molino.gd; the user, 15 November 2026;
# referencias/molino_tio_gerardo/). Catastro's parts of its parcel are not raised at all -- one of them, a circle, is
# the mill drawn eleven metres from where it stands -- and molino.gd builds the lot on a level terrace. Its frame: the
# middle of the mill, u east along the north wall of its corral. Nothing of the town's own grows inside its walls.
MOLINO_RC = '3998402VJ5639N'
MOLINO = {'o': (-278.0, -729.1), 'u': (0.96823, 0.25006)}
def molino_at(s, t, o=MOLINO['o'], u=MOLINO['u']): return (o[0] + u[0] * s - u[1] * t, o[1] + u[1] * s + u[0] * t)      # t: metres south of the mill
molino_zone = Polygon([molino_at(*q) for q in ((-13.2, -26.2), (2.5, -30.5), (9.5, -18.0), (13.9, -8.0), (14.0, 30.0), (-10.9, 30.0))])
molino = {'o': list(MOLINO['o']), 'u': list(MOLINO['u'])}
_molino_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'molino.gd')
if not (os.path.exists(_molino_gd) and 'const READY := true' in open(_molino_gd, encoding='utf-8').read()):      # (not built yet: the plot stays ordinary buildings)
    MOLINO_RC, molino, molino_zone = None, {}, Polygon()

# The old bullring between the Calle de la Prensa, San Agustín and Vista Alegre (godot/scripts/toros.gd; the user, 15
# November 2026; referencias/plaza_toros/): Catastro's round part is not raised -- toros.gd builds the ring, in its two
# states, and the lot in front of it, on a level terrace. Its frame: the middle of the ring, the map's own axes.
TOROS_RC = '4786002VJ5648N'
TOROS = {'o': (476.3, 548.5)}
toros_zone = Polygon([(TOROS['o'][0] + x, TOROS['o'][1] + z) for x, z in ((-19.6, -28.0), (-42.5, 27.4), (18.5, 65.8), (47.1, -14.5), (23.9, -13.8), (0.0, -28.6), (-21.1, -17.7))])
toros = {'o': list(TOROS['o'])}
_toros_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'toros.gd')
if not (os.path.exists(_toros_gd) and 'const READY := true' in open(_toros_gd, encoding='utf-8').read()):      # (not built yet: Catastro's block stays)
    TOROS_RC, toros, toros_zone = None, {}, Polygon()

# The nursery school of the Calle del Palo (godot/scripts/calasanz.gd; the user, 15 November 2026;
# referencias/escuela_calasanz/): Catastro's part is not raised -- calasanz.gd builds the house, its yard and its
# railings, on a level terrace. Its frame: the north-west corner of its front, x along the front, z out of it.
CALASANZ_RC = '4194305VJ5649S'
CALASANZ = {'o': (-109.41, -217.17), 'u': (0.6862, 0.7273)}
calasanz_zone = Polygon([(CALASANZ['o'][0] + CALASANZ['u'][0] * x - CALASANZ['u'][1] * z, CALASANZ['o'][1] + CALASANZ['u'][1] * x + CALASANZ['u'][0] * z) for x, z in ((-8.5, 4.3), (38.3, 4.3), (28.8, -17.6), (-11.3, -8.4))])
calasanz = {'o': list(CALASANZ['o']), 'u': list(CALASANZ['u'])}
_calasanz_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'calasanz.gd')
if not (os.path.exists(_calasanz_gd) and 'const READY := true' in open(_calasanz_gd, encoding='utf-8').read()):      # (not built yet: Catastro's block stays)
    CALASANZ_RC, calasanz, calasanz_zone = None, {}, Polygon()
# The hermitage of the Caridad, its square, the park of the fountain and the nursery (godot/scripts/caridad.gd; the user,
# 15 November 2026; referencias/ermita_caridad/): Catastro's parts of the island are not raised -- caridad.gd builds the
# hermitage, the body at its corner and the nursery -- and neither is the two-storey house Catastro still has where the
# park's fountain is; the map's trees there go too. The ground is NOT levelled: it falls 7 m across the island and a
# terrace would move four streets by metres; caridad.gd lays the square as a floor over the ground instead.
CARIDAD_RCS = {'3890801VJ5639S', '3890802VJ5639S', '3890803VJ5639S', '3790101VJ5639S'}
CARIDAD = {'o': (-489.5, 141.2), 'u': (0.9984, -0.0564)}
caridad_zone = Polygon([(CARIDAD['o'][0] + CARIDAD['u'][0] * x - CARIDAD['u'][1] * z, CARIDAD['o'][1] + CARIDAD['u'][1] * x + CARIDAD['u'][0] * z)
                        for x, z in ((-40.0, -9.0), (-2.0, -21.0), (19.0, -25.0), (43.0, -32.0), (51.5, -10.0), (57.0, 9.0), (0.0, 17.5), (-26.0, 20.5), (-38.0, 12.0))])
caridad = {'o': list(CARIDAD['o']), 'u': list(CARIDAD['u'])}
_caridad_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'caridad.gd')
if not (os.path.exists(_caridad_gd) and 'const READY := true' in open(_caridad_gd, encoding='utf-8').read()):      # (not built yet: Catastro's blocks stay)
    CARIDAD_RCS, caridad, caridad_zone = set(), {}, Polygon()
# The convent of Santa Ana, on the corner of the Calle de las Monjas and the Calle de Santiago Apóstol
# (godot/scripts/santaana.gd; the user, 15 November 2026; referencias/convento_santa_ana/): Catastro's parts of it are
# not raised -- santaana.gd builds the convent, its tower and its church, cut back to the game's Calle de Santiago
# Apóstol, which runs three metres south of the real one -- and the map plants no trees in it. The ground is not levelled.
SANTAANA_RC = '3792701VJ5639S'
SANTAANA = {'o': (-501.6, -33.6), 'u': (0.2425, -0.9701)}
santaana_zone = Polygon([(SANTAANA['o'][0] + SANTAANA['u'][0] * x - SANTAANA['u'][1] * z, SANTAANA['o'][1] + SANTAANA['u'][1] * x + SANTAANA['u'][0] * z)
                         for x, z in ((-0.5, 1.0), (46.5, 0.5), (43.5, -13.0), (38.8, -41.0), (37.4, -50.2), (8.4, -50.2), (2.8, -37.0), (-0.5, -9.5))])
# what santaana.gd builds on it, as one outline (its front, the church cut back to the street, the north range, the garden's
# wall): it draws its own walls and tells the map its own outlines, but the streets beside it are only as wide as it leaves them
santaana_built = Polygon([(SANTAANA['o'][0] + SANTAANA['u'][0] * x - SANTAANA['u'][1] * z, SANTAANA['o'][1] + SANTAANA['u'][1] * x + SANTAANA['u'][0] * z)
                          for x, z in ((0, 0), (28.48, 0), (28.5, -3.0), (36.44, -4.23), (36.92, -1.15), (45.59, -2.5), (43.38, -13.0), (38.65, -40.1), (37.25, -49.5),
                                       (9.0, -49.5), (7.5, -36.9), (4.1, -36.7), (3.4, -18.9), (7.4, -18.9), (7.4, -9.0), (0, -9.0))])
santaana = {'o': list(SANTAANA['o']), 'u': list(SANTAANA['u'])}
_santaana_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'santaana.gd')
if not (os.path.exists(_santaana_gd) and 'const READY := true' in open(_santaana_gd, encoding='utf-8').read()):      # (not built yet: Catastro's block stays)
    SANTAANA_RC, santaana, santaana_zone = None, {}, Polygon()
# The old school of the Avenida de Juan Carlos I, between the Calle del Peso and the Calle de Santa Clara
# (godot/scripts/colegio.gd; the user, 16 November 2026; referencias/colegio_viejo/): Catastro's parts of it are not
# raised -- colegio.gd builds the school and its two towers -- and the map plants no trees in it or in its court.
# The ground is not levelled: colegio.gd lays the court as a floor of its own over it, behind its fence.
COLEGIO_RC = '3891715VJ5639S'
COLEGIO = {'o': (-427.35, 121.61), 'u': (0.9706, -0.2407)}
def _col(pts): return Polygon([(COLEGIO['o'][0] + COLEGIO['u'][0] * x - COLEGIO['u'][1] * z, COLEGIO['o'][1] + COLEGIO['u'][1] * x + COLEGIO['u'][0] * z) for x, z in pts])
colegio_zone = _col(((-0.8, -22.5), (41.2, -22.5), (41.2, 6.0), (38.0, 22.5), (35.5, 24.0), (-0.5, 20.0)))
# what colegio.gd builds on it, as one outline: the streets beside it are only as wide as it leaves them
colegio_built = _col(((0, 0), (40.35, 0), (40.35, -21.7), (32.64, -21.7), (32.64, -20.5), (12.2, -20.5), (12.2, -13.3), (0, -13.3)))
colegio = {'o': list(COLEGIO['o']), 'u': list(COLEGIO['u'])}
_colegio_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'colegio.gd')
if not (os.path.exists(_colegio_gd) and 'const READY := true' in open(_colegio_gd, encoding='utf-8').read()):      # (not built yet: Catastro's block stays)
    COLEGIO_RC, colegio, colegio_zone = None, {}, Polygon()
# The Guardia Civil's barracks of the Avenida de la Constitución, at the corner of the Calle de Víctor Pradera -- the
# Tricornios' in the game (godot/scripts/cuartel.gd; the user, 16 November 2026; referencias/cuartel_tricornios/):
# Catastro's parts of it are not raised -- cuartel.gd builds its four blocks -- and the map plants no trees in it, in
# the apron before it or in its yard. The ground is not levelled.
CUARTEL_RC = '4397001VJ5649N'
CUARTEL = {'o': (46.84, -534.47), 'u': (0.165, 0.986)}
def _cua(pts): return Polygon([(CUARTEL['o'][0] + CUARTEL['u'][0] * x - CUARTEL['u'][1] * z, CUARTEL['o'][1] + CUARTEL['u'][1] * x + CUARTEL['u'][0] * z) for x, z in pts])
cuartel_zone = _cua(((-2.5, 9.5), (37.5, 9.0), (40.5, -1.0), (56.0, -31.0), (47.0, -31.0), (39.5, -35.0), (38.5, -38.6), (36.0, -38.6), (36.0, -48.2), (-2.5, -48.2)))
# what cuartel.gd builds on it, as one outline (its court is shut): the streets beside it are only as wide as it leaves them
cuartel_built = _cua(((0, -1.61), (4.9, -1.61), (4.9, 0), (30.62, 0), (30.62, -1.62), (35.63, -1.62), (35.65, -37.9), (22.0, -37.9), (22.0, -43.6), (13.45, -43.6), (13.45, -47.59), (0, -47.59)))
cuartel = {'o': list(CUARTEL['o']), 'u': list(CUARTEL['u'])}
_cuartel_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'cuartel.gd')
if not (os.path.exists(_cuartel_gd) and 'const READY := true' in open(_cuartel_gd, encoding='utf-8').read()):      # (not built yet: Catastro's block stays)
    CUARTEL_RC, cuartel, cuartel_zone = None, {}, Polygon()
# The supermarket by the old Madrid-Cádiz road, "Mercamona" in the game (godot/scripts/mercamona.gd; the user, 15 November
# 2026; referencias/mercamona/): Catastro's parts of it and of the little old house north of it are not raised --
# mercamona.gd builds them -- and the map plants no trees there. Its car park lies a whole floor below the shop and runs in
# under its east half: the ground is dug for it (`pit`, with the terraces below).
MERCAMONA_RCS = {'5187002VJ5658N', '5187001VJ5658N'}
MERCAMONA = {'o': (905.0, 306.1), 'u': (-0.1838, 0.983)}
def _mm(pts): return Polygon([(MERCAMONA['o'][0] + MERCAMONA['u'][0] * x - MERCAMONA['u'][1] * z, MERCAMONA['o'][1] + MERCAMONA['u'][1] * x + MERCAMONA['u'][0] * z) for x, z in pts])
mercamona_zone = _mm(((-22, 16), (88, 16), (88, -112), (36, -112), (27, -98), (0, -46), (-22, -46)))
mercamona_pit = _mm(((4.5, -13.5), (4.5, -41.5), (2.0, -44.0), (28.0, -98.0), (38.0, -112.0), (76.0, -112.0), (76.0, -13.5)))      # the car park and the east half of the shop
mercamona_built = _mm(((0, 0), (51.7, 0), (51.7, -4.7), (74, -4.7), (74, 0), (84.4, 0), (85, -13.1), (79, -13.1), (79, -39), (2.9, -39), (0.9, -34.5), (-1.6, -28.9),
                       (-4.3, -23.0), (-5.4, -21.0), (-5.4, -14.3), (0, -14.2), (0, -11.5))).union(_mm(((-19.3, -10.9), (-5.9, -10.9), (-5.9, 2.5), (-19.3, 2.5))))      # the shop with its taller block (cut back to the game's street), and the old house
mercamona = {'o': list(MERCAMONA['o']), 'u': list(MERCAMONA['u'])}
_mercamona_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'mercamona.gd')
if not (os.path.exists(_mercamona_gd) and 'const READY := true' in open(_mercamona_gd, encoding='utf-8').read()):      # (not built yet: Catastro's blocks stay)
    MERCAMONA_RCS, mercamona, mercamona_zone = set(), {}, Polygon()
# The supermarket of the Calle de las Viñas at the corner of the Calle de la Noria, "MasAhorro" in the game
# (godot/scripts/masahorro.gd; the user, 17 November 2026; referencias/masahorro/): Catastro's block is not raised --
# masahorro.gd builds the shop, 1.5 m nearer the Noria than Catastro has it, with its plant room behind -- and the map
# plants no trees on it or in its car park. The ground is not levelled: its car park is laid over it.
MASAHORRO_RC = '4286902VJ5648N'
MASAHORRO = {'o': (55.3, 517.0), 'u': (-0.94735, -0.32034)}
def _mah(pts): return Polygon([(MASAHORRO['o'][0] + MASAHORRO['u'][0] * x - MASAHORRO['u'][1] * z, MASAHORRO['o'][1] + MASAHORRO['u'][1] * x + MASAHORRO['u'][0] * z) for x, z in pts])
masahorro_zone = _mah(((-4.3, 4.0), (-0.5, 4.0), (-0.5, -60.0), (29.8, -60.0), (29.8, 0.0), (33.0, 0.0), (33.0, 78.0), (-4.3, 78.0)))
# what masahorro.gd builds on it, as one outline (the shop and its plant room): the streets beside it are only as wide as it leaves them
masahorro_built = _mah(((-0.25, 0.0), (29.5, 0.0), (29.5, -59.0), (18.5, -59.0), (18.5, -54.0), (0.0, -54.0)))
masahorro = {'o': list(MASAHORRO['o']), 'u': list(MASAHORRO['u'])}
_masahorro_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'masahorro.gd')
if not (os.path.exists(_masahorro_gd) and 'const READY := true' in open(_masahorro_gd, encoding='utf-8').read()):      # (not built yet: Catastro's block stays)
    MASAHORRO_RC, masahorro, masahorro_zone = None, {}, Polygon()
# The Dia of the Calle del Teniente Infante, "Noche" in the game (godot/scripts/noche.gd; the user, 17 November 2026;
# referencias/noche/): Catastro's block is not raised -- noche.gd builds the house of three floors with the shop in it
# and the shop's hall behind, on Catastro's own outlines (so the street beside it stays as wide as it was).
NOCHE_RC = '4290005VJ5649S'
NOCHE = {'o': (-10.62, 99.01), 'u': (-0.98945, 0.14483)}
noche_built = Polygon([(-10.62, 99.01), (-10.24, 103.61), (-9.92, 107.52), (-9.69, 110.38), (-9.43, 113.56), (-9.04, 118.26), (-17.35, 118.88), (-17.45, 117.68),
                       (-17.48, 114.24), (-18.33, 114.31), (-18.88, 108.81), (-17.96, 108.79), (-18.11, 105.32), (-18.34, 100.14)]).union(
              Polygon([(-9.04, 118.26), (-8.82, 121.05), (-7.54, 120.85), (-6.66, 130.36), (-6.47, 132.45), (-7.89, 132.52), (-11.93, 132.53), (-13.06, 143.35),
                       (-19.53, 143.34), (-19.97, 143.34), (-19.79, 132.35), (-19.74, 129.33), (-19.48, 129.34), (-16.41, 129.39), (-17.35, 118.88)]))
noche = {'o': list(NOCHE['o']), 'u': list(NOCHE['u'])}
_noche_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'noche.gd')
if not (os.path.exists(_noche_gd) and 'const READY := true' in open(_noche_gd, encoding='utf-8').read()):      # (not built yet: Catastro's block stays)
    NOCHE_RC, noche = None, {}
# The Merkocash of the Calle de Santa Ana, "Merkocarry" in the game (godot/scripts/merkocarry.gd; the user, 17 November
# 2026; referencias/merkocarry/): Catastro's block of the shop is not raised -- merkocarry.gd builds it on Catastro's
# outline, but for its corner on the Cristo (cut back to the game's street) and the lane into its car park -- and the map
# plants no trees on it, its lane or its car park (down to Magallanes). The ground is not levelled: the car park is laid
# over it. The nave of the Mayordomía beside it (4790711) is not the shop's and stays as it is.
MERKOCARRY_RCS = {'4790703VJ5649S', '4790711VJ5649S'}      # the shop, and the Mayordomía's nave beside it on the Cristo (mayordomia.gd, built from merkocarry.gd; the user: "es otro edificio distinto")
merkocarry_built = Polygon([(445.71, 154.61), (461.41, 158.56), (459.82, 162.30), (452.57, 179.38), (467.48, 182.94), (445.05, 222.26), (438.05, 218.29),
                            (439.06, 216.44), (434.85, 214.50), (432.70, 219.09), (420.36, 213.47), (421.43, 204.23), (401.59, 199.05), (411.41, 179.03), (432.01, 184.40)])
merkocarry_park = Polygon([(417.45, 216.05), (420.36, 213.47), (432.70, 219.09), (445.05, 222.26), (428.40, 251.45), (421.19, 254.57), (404.31, 252.57)])     # (its walls narrow the streets too)
merkocarry_nave = Polygon([(415.47, 169.97), (436.26, 175.17), (432.02, 184.41), (411.41, 179.03)])      # (its front a metre back from Catastro's, as the shop's corner)
merkocarry_zone = unary_union([merkocarry_built, merkocarry_park, merkocarry_nave, Polygon([(401.59, 199.05), (421.43, 204.23), (420.36, 213.47), (417.45, 216.05), (398.07, 206.23)])]).buffer(0.5)
merkocarry = {'o': [453.56, 156.59], 'nave': True}
_merkocarry_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'merkocarry.gd')
if not (os.path.exists(_merkocarry_gd) and 'const READY := true' in open(_merkocarry_gd, encoding='utf-8').read()):      # (not built yet: Catastro's block stays)
    MERKOCARRY_RCS, merkocarry, merkocarry_zone = set(), {}, Polygon()
# The post office of the Calle de Zaragoza, number 1, by the Plaza del Ayuntamiento (godot/scripts/correos.gd; the user,
# 17 November 2026; referencias/correos/): Catastro's block of it is not raised -- correos.gd builds it on Catastro's
# outline -- and Texturas's house of it (zaragoza_b608) goes with it.
CORREOS_RC = '4193608VJ5649S'
correos_built = Polygon([(-133.85, -89.18), (-132.11, -88.29), (-127.86, -86.1), (-122.17, -83.17), (-130.12, -66.22), (-134.86, -68.43), (-133.34, -72.06),
                         (-138.91, -74.57), (-141.54, -75.8), (-139.59, -79.88), (-138.37, -79.17), (-138.02, -79.99), (-135.91, -79.42), (-134.68, -83.84),
                         (-133.11, -83.5), (-132.86, -84.73), (-135.83, -85.25), (-137.0, -85.53), (-135.11, -89.83)])
correos = {'o': [-126.15, -74.7]}
_correos_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'correos.gd')
if not (os.path.exists(_correos_gd) and 'const READY := true' in open(_correos_gd, encoding='utf-8').read()):      # (not built yet: Catastro's block stays)
    CORREOS_RC, correos = None, {}
# The block of the Casa Grande, the public library and the school of music and dance, between the Calle de los
# Arcos, the Calle de Argentina and the Callejón Pando (godot/scripts/cultura.gd; the user, 17 November 2026;
# referencias/cultura/): Catastro's parcel of it (nine parts) is not raised -- cultura.gd builds the three of them, and
# the music school where Catastro has nothing, as the photographs show it -- and Texturas's house of its front on the
# Arcos (arcos_7) goes with it.
CULTURA_RC = '4590001VJ5649S'
cultura_built = Polygon([(118.4, 109.21), (142.44, 113.95), (147.93, 115.54), (160.62, 119.22), (168.34, 121.45), (174.23, 123.16), (175.76, 123.6), (175.24, 136.64), (174.13, 136.91), (174.53, 138.74), (174.66, 139.58), (174.84, 141.12), (174.95, 142.51), (174.95, 144.23), (174.88, 145.6), (174.65, 147.35), (174.29, 149.2), (173.84, 150.82), (173.46, 152.05), (167.22, 150.1), (159.48, 147.68), (157.7, 147.13), (147.46, 145.08), (117.22, 139.04)])
cultura = {'o': [118.40, 109.21]}
_cultura_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'cultura.gd')
if not (os.path.exists(_cultura_gd) and 'const READY := true' in open(_cultura_gd, encoding='utf-8').read()):      # (not built yet: Catastro's block stays)
    CULTURA_RC, cultura = None, {}
# The hermitage of San Sebastián and the park round it, between the Calle del Santo, its loop and the Calle del
# Descanso (godot/scripts/sebastian.gd; the user, 18 November 2026; referencias/sebastian/): Catastro's parcel of the
# hermitage (three parts) is not raised -- sebastian.gd builds it, its porch, its little chapel and its terrace by the
# street -- and the map plants no trees in the park or round the hermitage (sebastian.gd plants its own). The ground
# is NOT levelled: the front is laid over it, the porch and the round square are level, with steps.
SEBASTIAN_RC = '4297712VJ5649N'
sebastian_built = Polygon([(-91.96, -460.6), (-95.63, -462.01), (-86.07, -486.7), (-66.51, -479.88), (-68.25, -477.37), (-69.93, -474.95), (-75.98, -477.64), (-84.8, -457.95)]).union(Polygon([(-91.96, -460.6), (-94.23, -454.75), (-89.95, -453.1), (-88.34, -457.24), (-87.69, -459.02)]))
sebastian_chapel = Polygon([(-75.96, -464.82), (-79.61, -466.68), (-76.85, -472.09), (-76.13, -471.72), (-75.47, -472.98), (-73.26, -471.85), (-73.91, -470.59), (-73.2, -470.22)])
sebastian_zone = Polygon([(-124.3, -475.3), (-126.7, -470.7), (-132.8, -459.3), (-138.2, -449.2), (-137.9, -447.2), (-137.0, -444.6), (-135.9, -443.1), (-124.9, -435.4), (-108.2, -423.9), (-106.3, -424.2), (-103.1, -424.4), (-101.4, -424.6), (-91.9, -439.0), (-90.0, -442.0), (-81.3, -456.7), (-87.7, -459.0), (-90.0, -453.1), (-94.2, -454.7), (-92.0, -460.6), (-95.7, -462.0), (-94.1, -465.9), (-122.8, -475.8)]).buffer(1.0).union(sebastian_built.buffer(7.0))
sebastian = {'o': [-95.63, -462.01], 'u': [0.93637, 0.35102]}
_sebastian_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'sebastian.gd')
if not (os.path.exists(_sebastian_gd) and 'const READY := true' in open(_sebastian_gd, encoding='utf-8').read()):      # (not built yet: Catastro's block stays)
    SEBASTIAN_RC, sebastian, sebastian_zone = None, {}, Polygon()
# The little hermitage of San Cristóbal, built by the town's people, on the Calle de Ortega y Gasset by the old road
# (godot/scripts/cristobal.gd; the user, 17 November 2026; referencias/cristobal/): Catastro's building of it is not
# raised -- cristobal.gd builds it, its little yard and its walls.
CRISTOBAL_RC = '4602021VJ5740S'
cristobal_built = Polygon([(429.23, -981.43), (427.48, -984.81), (430.69, -986.48), (432.56, -983.16)])
cristobal = {'o': [429.23, -981.43], 'u': [0.8875, -0.4610]}
_cristobal_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'cristobal.gd')
if not (os.path.exists(_cristobal_gd) and 'const READY := true' in open(_cristobal_gd, encoding='utf-8').read()):      # (not built yet: Catastro's building stays)
    CRISTOBAL_RC, cristobal = None, {}
# The oil mill of the road to Villacañas, "González de la Ruz" in the game (godot/scripts/almazara.gd; the user, 21
# November 2026; referencias/almazara/): Catastro's buildings of it are not raised -- almazara.gd builds them, and the
# tall nave beside them on the road, which Catastro has not got -- and the map plants no trees on its plot nor on the
# verge before it (almazara.gd plants its own pines). No relief or road change.
ALMAZARA_RC = '4699012VJ5649N'
def _alm(s, d): return (264.27 + 0.7340 * s - 0.6792 * d, -523.36 - 0.6792 * s - 0.7340 * d)      # s along its front on the road, d into the plot
almazara_built = [
    Polygon([(264.27, -523.36), (275.24, -533.51), (227.29, -556.58), (218.76, -545.09)]),      # the old nave, from the road to the Triunfo (its end a metre back from Catastro's: the street's corridor)
    Polygon([(227.29, -556.58), (238.73, -573.00), (244.48, -581.42), (251.33, -578.17), (233.53, -553.77)]),      # the block of two floors and the low old stretch on the Triunfo
    Polygon([(240.50, -550.38), (260.29, -577.48), (254.11, -581.97), (233.53, -553.77)]),      # the offices on the yard
    Polygon([(260.29, -577.48), (278.47, -564.22), (287.61, -576.74), (269.43, -590.00)]),      # the reception nave
    Polygon([(244.48, -581.42), (269.73, -615.42), (279.33, -637.50), (302.76, -633.48), (298.58, -612.00), (280.41, -581.98), (269.43, -590.00), (251.33, -578.17)]),      # the naves along the Triunfo
    Polygon([(301.70, -609.29), (326.5, -603.5), (333.2, -628.5), (336.4, -640.5), (322.53, -644.79), (319.55, -630.61), (302.76, -633.48)]),      # the big nave behind the tall one
    Polygon([_alm(97.5, 0.0), _alm(165.0, 0.0), (336.4, -640.5), (326.5, -603.5)]),             # the tall nave on the road (not in Catastro)
    Polygon([_alm(89.0, 0.0), _alm(97.5, 0.0), _alm(98.9, 10.0), _alm(89.0, 10.0)]),            # the small building beside it
    Polygon([_alm(26.5, 0.0), _alm(89.0, 0.0), _alm(89.0, 0.3), _alm(26.5, 0.3)]),              # the long wall on the road
    Polygon([_alm(61.0, 1.6), _alm(86.0, 1.6), _alm(86.0, 10.0), _alm(61.0, 10.0)]),            # the low works behind it
]
almazara_zone = unary_union([p.buffer(0) for p in almazara_built] + [Polygon([_alm(-1.0, -9.0), _alm(168.0, -9.0), _alm(168.0, 12.0), _alm(-1.0, 12.0)]),
    Polygon([(275.24, -533.51), _alm(89.0, 10.0), (326.5, -603.5), (301.70, -609.29), (298.58, -612.00), (280.41, -581.98), (287.61, -576.74), (278.47, -564.22), (260.29, -577.48), (240.50, -550.38)]).buffer(0)]).buffer(0.5)
almazara = {'o': [264.27, -523.36], 'u': [0.7340, -0.6792]}
_almazara_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'almazara.gd')
if not (os.path.exists(_almazara_gd) and 'const READY := true' in open(_almazara_gd, encoding='utf-8').read()):      # (not built yet: Catastro's sheds stay)
    ALMAZARA_RC, almazara, almazara_built, almazara_zone = None, {}, [], Polygon()
# The Cafetería Rize and its alley, off the Avenida de Juan Carlos I (godot/scripts/rize.gd; the user, 21 November 2026;
# referencias/rice/): Catastro's café (4091010, a shop of one floor) and the little garage opposite it (4091028) are not
# raised -- rize.gd builds them, and the old wall with the green door that closes the alley's end, which Catastro has
# not got. (The alley itself: PAVED_ALLEYS, above.)
RIZE_RCS = {'4091010VJ5649S', '4091028VJ5649S'}
rize_built = [
    Polygon([(-196.82, 85.25), (-189.41, 84.91), (-179.58, 83.80), (-179.26, 98.75), (-184.38, 99.06), (-195.03, 99.70)]),      # the café
    Polygon([(-203.05, 85.53), (-201.61, 90.97), (-208.50, 91.51), (-208.56, 85.78)]),                                           # the garage with the emblem
    Polygon([(-203.05, 85.53), (-196.82, 85.25), (-196.84, 84.85), (-203.07, 85.13)]),                                           # the end wall
]
rize = {'o': [-196.82, 85.25]}
_rize_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'rize.gd')
if not (os.path.exists(_rize_gd) and 'const READY := true' in open(_rize_gd, encoding='utf-8').read()):      # (not built yet: Catastro's buildings stay)
    RIZE_RCS, rize, rize_built = set(), {}, []
# The dance hall of the old Madrid-Cádiz road, 140 m south of the Mercamona (godot/scripts/cuevas.gd; the user, 25
# November 2026; referencias/cuevas/): Catastro's building of it (the hall, the bar, the sheds behind) is not raised --
# cuevas.gd builds it in two states, worn and restored, with its summer terrace and its car shelter, which Catastro has
# not got -- and the map plants no trees on its plot nor on the pavement before it. No relief or road change.
CUEVAS_RC = '5187003VJ5658N'
def _cue(x, z): return (898.35 - 0.23202 * x - 0.97272 * z, 399.28 + 0.97272 * x - 0.23202 * z)      # x along its front from north to south, z out of it towards the road
cuevas_built = [
    Polygon([_cue(4.2, 0.0), _cue(38.7, 0.0), _cue(38.7, 5.0), _cue(43.2, 5.0), _cue(43.2, 0.7), _cue(69.6, 0.7), _cue(69.6, -26.0), _cue(41.6, -26.0), _cue(41.6, -23.2), _cue(4.2, -23.2)]).buffer(0),      # the hall, the bar and the terrace
    Polygon([_cue(8.77, -35.29), _cue(32.48, -30.88), _cue(33.6, -23.2), _cue(41.6, -23.2), _cue(41.26, -26.76), _cue(49.99, -26.48), _cue(49.11, -33.28), _cue(10.55, -42.37)]).buffer(0),      # the sheds behind
]
cuevas_zone = Polygon([_cue(-14.0, 9.0), _cue(105.0, 9.0), _cue(105.0, -44.0), _cue(-14.0, -44.0)]).buffer(0.5)
cuevas = {'o': [898.35, 399.28], 'u': [-0.23202, 0.97272]}
_cuevas_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'cuevas.gd')
if not (os.path.exists(_cuevas_gd) and 'const READY := true' in open(_cuevas_gd, encoding='utf-8').read()):      # (not built yet: Catastro's building stays)
    CUEVAS_RC, cuevas, cuevas_built, cuevas_zone = None, {}, [], Polygon()
# The Travesía del Clavel (above; referencias/travesia_clavel/): Catastro has the row on its west side as a strip (part 2
# of 4494604) drawn 1.4 to 5 m short of the alley -- the aerial photo has its front 7 m from the east row's all the way.
# That strip is not raised: travesia.gd builds the row where it stands, and the white house on the corner of the Calle
# del Clavel beside it. (Part 1 of that parcel, on the Clavel, stays.) Its frame: s along the east row's front from
# its corner on San Rafael, t west of it.
TRAVESIA_RC = '4494604VJ5649S'
_tv_o, _tv_u = (140.56, -160.80), (0.19084, -0.98162)
def _tv(s, t): return (_tv_o[0] + _tv_u[0] * s + _tv_u[1] * t, _tv_o[1] + _tv_u[1] * s - _tv_u[0] * t)
travesia_zone = Polygon([_tv(-3.0, 6.0), _tv(50.0, 6.0), _tv(50.0, 24.0), _tv(-3.0, 24.0)])      # (where Catastro's strip is)
travesia_built = [Polygon([_tv(0.95, 7.0), _tv(52.9, 7.0), _tv(52.9, 16.5), _tv(0.95, 13.4)]),                               # the west row
                  Polygon([_tv(52.9, 7.0), _tv(63.2, 7.0), _tv(63.6, 12.4), _tv(52.9, 12.4)])]                               # the white house
travesia = {'o': list(_tv_o), 'u': list(_tv_u)}
if not TRAVESIA:      # (not built yet: Catastro's strip stays)
    TRAVESIA_RC, travesia, travesia_built = None, {}, []
# The hermitage of the Cristo del Prado, on the Paseo del Cristo (godot/scripts/cristoprado.gd; the user, 21 November
# 2026; referencias/cristoprado/): Catastro has it and the old people's home beside it as one building -- the hermitage's
# parts (its nave, a piece of part 4; the crossing, part 3; the east body, part 1) are not raised, the home's stay.
CRISTOPRADO_RC = '4587301VJ5648N'
cristoprado_built = Polygon([(318.61, 502.34), (303.46, 494.77), (299.14, 503.37), (314.29, 510.95), (313.94, 511.64), (323.82, 516.57), (324.73, 514.75), (332.28, 518.52), (335.2, 512.71), (333.21, 511.71), (333.74, 506.57), (331.63, 501.74), (328.53, 500.19), (326.0, 505.21), (318.93, 501.69)])
cristoprado_zone = unary_union([Polygon([(288.41, 487.94), (278.79, 507.17), (327.98, 531.78), (337.6, 512.55)]), Polygon([(336.48, 502.49), (331.78, 511.88), (336.7, 514.34), (341.4, 504.95)]), Point((268.1, 495.8)).buffer(3.5)])
cristoprado = {'o': [299.14, 503.37], 'u': [0.894309, 0.44745]}
_cristoprado_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'cristoprado.gd')
if not (os.path.exists(_cristoprado_gd) and 'const READY := true' in open(_cristoprado_gd, encoding='utf-8').read()):      # (not built yet: Catastro's building stays whole)
    CRISTOPRADO_RC, cristoprado, cristoprado_zone = None, {}, Polygon()
# ...and the old people's home beside it, the rest of that building (godot/scripts/residencia.gd; the user, 21 November
# 2026: "the rest of the apple"): with it built too, nothing of Catastro's building is raised.
RESIDENCIA_RC = '4587301VJ5648N'
residencia_built = [Polygon([(302.77, 434.61), (311.78, 433.23), (318.89, 452.64), (319.3, 454.3), (298.0, 453.0), (297.25, 452.76)]), Polygon([(298.0, 453.0), (319.3, 454.3), (320.57, 459.55), (329.48, 496.3), (329.81, 497.64), (328.53, 500.19), (328.2, 500.84), (320.77, 497.43), (309.42, 484.58), (308.49, 485.5), (309.2, 483.59), (305.63, 482.28), (299.14, 453.33)]), Polygon([(318.61, 502.34), (304.8, 495.44), (308.49, 485.5), (309.42, 484.58), (310.42, 483.77), (311.52, 483.12), (312.72, 482.65), (313.97, 482.38), (315.24, 482.3), (316.52, 482.42), (318.11, 482.86), (319.27, 483.42), (320.32, 484.15), (321.24, 485.04), (322.03, 486.05), (322.64, 487.18), (323.06, 488.38), (323.3, 489.64), (323.34, 490.92), (323.17, 492.19), (322.81, 493.42), (322.27, 494.57), (321.55, 495.63), (320.77, 497.43), (328.2, 500.84), (326.0, 505.21), (318.93, 501.69)]), Polygon([(303.46, 494.77), (286.53, 487.99), (287.06, 486.25), (292.8, 467.37), (300.96, 470.38), (297.64, 479.34), (305.63, 482.28), (309.2, 483.59), (308.49, 485.5), (304.8, 495.44)])]
residencia = {'o': [312.0, 465.0]}
_residencia_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'residencia.gd')
if not (cristoprado and os.path.exists(_residencia_gd) and 'const READY := true' in open(_residencia_gd, encoding='utf-8').read()):      # (not built yet: the home stays as Catastro's block)
    RESIDENCIA_RC, residencia, residencia_built = None, {}, []
# The cooperative on the Avenida de la Constitución is hand-built as well (godot/scripts/coop.gd), from street photos.
# Its frame: the origin is on the centre line of the avenue at the south end of the compound, u runs north along
# the avenue and the compound lies to the east of it. Catastro parts and generic trees are kept out of that rectangle.
coop = {}
best = None
for r in roads:
    if 'Constituci' not in r['n']: continue
    for i, j in zip(r['p'], r['p'][1:]):
        a, b = npts[i], npts[j]; L = math.hypot(b[0] - a[0], b[1] - a[1])
        if best is None or L > best[0]: best = (L, a, b)
if best:
    L, a, b = best
    if b[1] > a[1]: a, b = b, a                       # a = south end, b = north end
    ux, uz = (b[0] - a[0]) / L, (b[1] - a[1]) / L
    t = (-1128.0 - a[1]) / uz                         # the south corner of the compound
    coop = {'o': [r2(a[0] + ux * t), r2(a[1] + uz * t)], 'u': [round(ux, 4), round(uz, 4)], 'len': 146.0, 'depth': 152.0, 'gate': 114.0}
def coop_local(x, z):
    ox, oz = coop['o']; ux, uz = coop['u']
    return (x - ox) * ux + (z - oz) * uz, (x - ox) * -uz + (z - oz) * ux        # (along the avenue, into the compound)
def coop_keeps_clear(x, z, near=8.0):
    if not coop: return False
    s_, d_ = coop_local(x, z)
    return -42 < s_ < coop['len'] + 12 and near < d_ < coop['depth'] and (s_ > -9 or d_ < 10)

# Garages are hand-built too (godot/scripts/garage.gd), and you drive into them: a bay is cut out of whatever Catastro
# has standing there. a-b is the stretch of real facade the front is laid over (as it comes out of this bake), street a
# point out in the road, door how far along the front the doorway is from its middle, w and d the bay (w 0: the whole front).
GARAGES = [
    {'id': 'valdeacero', 'a': (143.57, 472.07), 'b': (149.05, 474.08), 'street': (151.3, 461.2), 'door': 0.0, 'w': 0.0, 'd': 9.0},
    {'id': 'errejota', 'a': (248.44, -506.1), 'b': (260.92, -524.97), 'street': (275.0, -518.0), 'door': 0.0, 'w': 8.4, 'd': 12.0},
    {'id': 'xandro', 'a': (373.21, -594.13), 'b': (391.87, -610.94), 'street': (360.0, -615.0), 'door': 7.2, 'w': 8.4, 'd': 12.0},
    {'id': 'df', 'a': (72.42, -45.29), 'b': (90.73, -38.89), 'street': (82.0, -36.0), 'door': 1.6, 'w': 8.4, 'd': 11.0, 'strip': 1.6},
]
garages, garage_bays, garage_mouths = [], [], []
for gd in GARAGES:
    (ax, az), (bx, bz) = gd['a'], gd['b']
    L = math.hypot(bx - ax, bz - az)
    nx, nz = -(bz - az) / L, (bx - ax) / L
    mx, mz = (ax + bx) / 2, (az + bz) / 2
    if (gd['street'][0] - mx) * nx + (gd['street'][1] - mz) * nz < 0: nx, nz = -nx, -nz
    ux, uz = nz, -nx                                   # to the right of somebody looking at the front from the street
    w = gd['w'] or L; d = gd['d']
    cx, cz = mx + ux * gd['door'], mz + uz * gd['door']
    def at(s, o, cx=cx, cz=cz, ux=ux, uz=uz, nx=nx, nz=nz): return (cx + ux * s + nx * o, cz + uz * s + nz * o)
    bay = Polygon([at(-w / 2, 0.3), at(w / 2, 0.3), at(w / 2, -d), at(-w / 2, -d)])
    if gd.get('strip'):                                # ...and whatever Catastro has stuck on the front of the building goes too
        s0, s1 = sorted(((ax - cx) * ux + (az - cz) * uz, (bx - cx) * ux + (bz - cz) * uz))
        bay = bay.union(Polygon([at(s0, 0.08), at(s1, 0.08), at(s1, gd['strip']), at(s0, gd['strip'])]))
    garage_bays.append(bay)
    garage_mouths.append(Polygon([at(-w / 2 - 2, 0), at(w / 2 + 2, 0), at(w / 2 + 2, 12), at(-w / 2 - 2, 12)]))
    sa, sb = (ax - cx) * ux + (az - cz) * uz, (bx - cx) * ux + (bz - cz) * uz
    garages.append({'id': gd['id'], 'm': [r2(cx), r2(cz)], 'n': [round(nx, 4), round(nz, 4)], 'w': r2(w), 'd': r2(d),
                    'left': r2(-min(sa, sb)), 'right': r2(max(sa, sb))})

# Blocks of flats that stand out and get a facade of their own (style 6, world.gd): bare red brick, white roller
# blinds, a flat roof. By cadastral reference.
BRICK_BLOCKS = {'4292301VJ5649S'}       # Calle del Palo 24

# Houses whose fronts are drawn after the real ones (fachadas.gd paints each look; world.gd hangs on them what paint
# cannot give: bays, balconies). By cadastral reference of the building, or of one of its parts ('..._part5'); the
# value is the look, or {floors: look} where a building's low and tall parts differ. A look may name another for its
# short walls ('short': (look, shorter than these metres)) and ask for a flat roof.
# The first are Calle de Alemania's, from the video in referencias/calle-alemania (walked from the Avenida end to no. 7).
LOOKS = {
    '4394004VJ5649S': 'ale_vieja',
    '4394010VJ5649S': {1: 'ale_vieja', 2: 'ale_esquina'},
}
LOOK_NAMES = ['ale_vieja', 'ale_esquina']      # facade style 7 + its place here
N_STYLES = 7 + len(LOOK_NAMES)

# Houses built by hand, one by one (godot/scripts/casas.gd), from what tools/house_data.py gathers about them: Catastro's
# record and footprint, its photo of the front, the aerial photo. Here: which parts of the building it replaces (those
# with at least `floors` storeys; sheds at the back stay ordinary), the two ends of its front as you face it (left,
# right), how high its walls are, and what is cut out of the block so that you can walk in under it (a porch: from..to
# along the front, how deep).
HOUSES = {
    # the communications tower between the Calle de la Cruz and the Calle de la Virgen de Gracia (casas.gd, _central):
    # the whole of its plot; its front is its long wall on the Calle de la Cruz
    'central': {'rc': '4490401VJ5649S', 'floors': 1, 'front': ((231.5, 196.9), (201.9, 188.1)), 'h': 12.6},
    # Calle de Alemania, odd side (as you face them their right is up the street, towards the Avenida)
    'alemania_19': {'rc': '4395608VJ5649N', 'floors': 2, 'front': ((67.84, -297.49), (69.35, -304.55)), 'h': 6.2},
    'alemania_17': {'rc': '4395609VJ5649N', 'floors': 2, 'front': ((67.24, -295.66), (67.84, -297.49)), 'h': 6.2},
    'alemania_15': {'rc': '4395610VJ5649N', 'floors': 2, 'front': ((65.09, -289.10), (67.24, -295.66)), 'h': 6.2},
    'alemania_13': {'rc': '4395611VJ5649N', 'floors': 2, 'front': ((60.74, -275.83), (65.09, -289.10)), 'h': 6.0},
    'alemania_11': {'rc': '4395612VJ5649N', 'floors': 3, 'front': ((57.77, -266.76), (60.74, -275.83)), 'h': 9.2},
    'alemania_nave': {'rc': '4395613VJ5649N', 'only': 1, 'front': ((55.13, -258.68), (57.77, -266.76)), 'h': 3.7},
    'alemania_tapia': {'rc': '4395613VJ5649N', 'floors': 2, 'front': ((50.31, -243.98), (55.13, -258.68)), 'h': 5.8},
    'alemania_9': {'rc': '4294319VJ5649S', 'floors': 1, 'front': ((42.79, -225.46), (47.49, -235.88)), 'h': 6.3},
    'alemania_7': {'rc': '4294305VJ5649S', 'floors': 2, 'front': ((39.17, -215.34), (42.79, -225.46)), 'h': 6.2, 'porch': (7.75, 10.3, 1.3)},
    'alemania_5': {'rc': None, 'floors': 1, 'front': ((35.55, -205.27), (39.17, -215.34)), 'h': 3.5, 'deep': 7.0},      # the house you inherit: a bare plot in Catastro
    'alemania_3': {'rc': '4294307VJ5649S', 'floors': 2, 'front': ((31.04, -192.71), (35.55, -205.27)), 'h': 6.4},
    'alemania_1': {'rc': '4294308VJ5649S', 'floors': 2, 'front': ((23.15, -170.74), (30.84, -192.15)), 'h': 6.4},
    # Calle Real, from the square: nos. 1 to 10 (there is no no. 2). The street of the shops.
    'real_1': {'rc': '4191011VJ5649S', 'floors': 2, 'front': ((-90.34, 88.52), (-90.04, 76.47)), 'h': 6.6},
    'real_3': {'rc': '4191010VJ5649S', 'floors': 2, 'front': ((-90.04, 76.47), (-89.82, 67.70)), 'h': 6.7},
    'real_5': {'rc': '4191009VJ5649S', 'floors': 2, 'front': ((-89.80, 67.16), (-89.54, 57.02)), 'h': 6.5},
    'real_7': {'rc': '4191007VJ5649S', 'floors': 2, 'front': ((-89.10, 50.60), (-88.00, 34.86)), 'h': 8.9},
    'real_9': {'rc': '4191006VJ5649S', 'floors': 3, 'front': ((-88.00, 34.86), (-86.77, 17.01)), 'h': 9.3},
    'real_4': {'rc': '4291715VJ5649S', 'floors': 2, 'front': ((-84.93, 73.46), (-84.87, 84.52)), 'h': 7.0},
    'real_6': {'rc': '4291716VJ5649S', 'floors': 3, 'front': ((-84.84, 60.32), (-84.93, 73.46)), 'h': 9.5},
    'real_8': {'rc': '4291717VJ5649S', 'floors': 3, 'front': ((-82.04, 20.10), (-84.84, 60.32)), 'h': 9.6},
    'real_10': {'rc': '4291703VJ5649S', 'floors': 2, 'front': ((-81.13, 7.25), (-82.04, 20.10)), 'h': 6.4},
    # ...and the even side (their left is up the street)
    'alemania_bloque': {'rc': '4394001VJ5649S', 'floors': 4, 'front': ((75.46, -290.96), (68.38, -267.75)), 'h': 12.4},
    'alemania_c65': {'rc': '4394002VJ5649S', 'floors': 1, 'front': ((68.38, -267.75), (65.73, -259.09)), 'h': 6.2},
    'alemania_c63': {'rc': '4394003VJ5649S', 'floors': 3, 'front': ((65.73, -259.09), (64.14, -255.67)), 'h': 8.6},
    'alemania_t10': {'rc': '4393101VJ5649S', 'floors': 2, 'front': ((53.12, -228.34), (51.71, -224.72)), 'h': 6.2},
    'alemania_16': {'rc': '4393130VJ5649S', 'floors': 2, 'front': ((51.71, -224.72), (47.77, -214.51)), 'h': 6.3},
    'alemania_14': {'rc': '4393128VJ5649S', 'floors': 2, 'front': ((47.62, -214.09), (45.31, -208.14)), 'h': 6.6},
    'alemania_12': {'rc': '4393127VJ5649S', 'floors': 1, 'front': ((45.31, -208.14), (42.95, -202.01)), 'h': 3.6},
    'alemania_10': {'rc': '4393126VJ5649S', 'floors': 2, 'front': ((42.95, -202.01), (38.54, -190.60)), 'h': 6.3},
    'alemania_8': {'rc': '4393133VJ5649S', 'floors': 2, 'front': ((38.54, -190.60), (36.30, -184.78)), 'h': 6.4},
    'alemania_6': {'rc': '4393125VJ5649S', 'floors': 1, 'front': ((36.30, -184.78), (34.08, -179.02)), 'h': 4.2},
    'alemania_4': {'rc': '4393124VJ5649S', 'floors': 1, 'front': ((34.08, -179.02), (32.61, -175.24)), 'h': 5.6},
    'alemania_m11': {'rc': '4393123VJ5649S', 'floors': 2, 'front': ((32.61, -175.24), (26.01, -158.13)), 'h': 6.4},
}
# Whole streets come from tools/casas/calles.json, written by tools/house_street.py out of what house_data.py gathered
# (the same fields: reference, storeys, the two ends of the front, the height of the walls).
_calles = os.path.join(HERE, 'casas', 'calles.json')
if os.path.exists(_calles):
    for name, hd in json.load(open(_calles, encoding='utf-8')).items():
        if name not in HOUSES:
            hd['front'] = (tuple(hd['front'][0]), tuple(hd['front'][1]))
            HOUSES[name] = hd
# "strip": <m> on a house: the lower parts of its plot that lie within that many metres of its front line (thin strips
# Catastro draws along a front: an overhang, a step) are dropped instead of standing as little houses against the front
STRIP_RC = {hd['rc']: name for name, hd in HOUSES.items() if hd.get('strip') and hd.get('rc')}
# "shift": [dx, dz] on a house: every part of its plot moved that far on the map before anything else is done with it,
# where Catastro draws a whole row metres away from where it stands (the south half of the Calle de las Terradas, 8 m
# too far south against the orthophoto and Street View; Texturas, 23 November 2026)
SHIFT_RC = {hd['rc']: tuple(hd['shift']) for name, hd in HOUSES.items() if hd.get('shift') and hd.get('rc')}
# "with": [<reference>, ...] on a house: other plots it takes in whole, where one building stands on several and
# Catastro has one inside another's front (Calle de Roma 8 wraps round no. 10): one front, not two laid over each other
def house_of(bid, floors, p=None):
    for name, hd in HOUSES.items():
        if (hd['rc'] == bid or bid in hd.get('with', ())) and (floors == hd['only'] if 'only' in hd else floors >= hd['floors']):
            if p is not None and 'reach' in hd and LineString(hd['front']).distance(p) > hd['reach']:
                continue                    # (out of this one's reach: a through plot's other front may be another entry's)
            return name
    return None
def house_frame(hd):
    (lx, lz), (rx, rz) = hd['front']
    ln = math.hypot(rx - lx, rz - lz)
    ux, uz = (rx - lx) / ln, (rz - lz) / ln
    return (lx, lz), (ux, uz), (-uz, ux), ln          # left end, along the front to the right, out into the street, length

def look_of(pid, floors):
    v = LOOKS.get(pid, LOOKS.get(pid.split('_')[0]))
    if isinstance(v, dict) and 'look' not in v: v = v.get(floors, v.get(max(v)) if floors > max(v) else None)
    if v is None: return None
    return v if isinstance(v, dict) else {'look': v}

parts = []   # dicts: poly, h, floors, style, tint, roofc, bid (and look, for the houses drawn after the real ones)
look_groups = {}
hand_groups = {}
def add_part(g, bid, floors, look=None, hand=None):
    if g.geom_type != 'Polygon' or g.area < 5: return
    g = orient(Polygon(g.exterior).simplify(0.5 if look else 0.3 if hand else 0.25), 1.0)
    if g.is_empty or g.area < 5 or not g.is_valid: return
    crc = zlib.crc32(bid.encode())
    use = use_of.get(bid, '')
    c = g.representative_point()
    if th_zone is not None and th_zone.contains(c): return      # the town hall is modelled by hand
    if plaza_zone is not None and plaza_zone.contains(c): return      # ...and so is all that stands in its square (Catastro has the fountain as a round building)
    if church_zone is not None and church_zone.contains(c): return      # ...and the parish church
    if coop_keeps_clear(c.x, c.y): return                        # ...and so is the cooperative
    if bid == SALUD_RC: return                                   # ...and the health centre
    if bid == MOLINO_RC: return                                  # ...and the windmill with its yard
    if bid == TOROS_RC: return                                   # ...and the old bullring
    if bid == CALASANZ_RC: return                                # ...and the nursery school of the Calle del Palo
    if bid in CARIDAD_RCS: return                                # ...and the hermitage of the Caridad, its nursery, and the house that is not there
    if bid == SANTAANA_RC: return                                # ...and the convent of Santa Ana
    if bid == COLEGIO_RC: return                                 # ...and the old school of the Avenida de Juan Carlos I
    if bid == CUARTEL_RC: return                                 # ...and the Guardia Civil's barracks
    if bid in MERCAMONA_RCS: return                              # ...and the supermarket by the old road, and the old house beside it
    if bid == MASAHORRO_RC: return                               # ...and the supermarket of the Calle de las Viñas
    if bid == NOCHE_RC: return                                   # ...and the little supermarket of the Calle del Teniente Infante
    if bid in MERKOCARRY_RCS: return                             # ...and the supermarket of the Calle de Santa Ana, and the Mayordomía's nave
    if bid == CORREOS_RC: return                                 # ...and the post office of the Calle de Zaragoza
    if bid == CULTURA_RC: return                                 # ...and the block of the Casa Grande, the library and the music school
    if bid == SEBASTIAN_RC: return                               # ...and the hermitage of San Sebastián
    if bid == CRISTOBAL_RC: return                               # ...and the little hermitage of San Cristóbal
    if bid == ALMAZARA_RC: return                                # ...and the oil mill of the road to Villacañas
    if bid in RIZE_RCS: return                                   # ...and the Cafetería Rize and the garage opposite it in its alley
    if bid == CUEVAS_RC: return                                  # ...and the dance hall of the old road
    if bid == TRAVESIA_RC and travesia_zone.contains(c): return  # ...and the west row of the Travesía del Clavel
    floors_c = min(floors, 5)
    if look: style, h = 7 + LOOK_NAMES.index(look['look']), floors_c * FLOOR_H + 0.5
    elif church_u.contains(c): style, h = 5, max(12.0, floors_c * 4.0)
    elif named_u.contains(c) or use == '4_3_publicServices': style, h = 5, floors_c * 3.6 + 0.8
    elif use in ('2_agriculture', '3_industrial'): style, h = 4, max(5.5, floors_c * 3.4)
    else: style, h = crc % 4, floors_c * FLOOR_H + 0.5 + ((crc >> 8) % 7) * 0.08
    if bid in BRICK_BLOCKS and floors_c >= 3: style, h = 6, floors_c * 3.0 + 0.9      # (its low outbuildings stay ordinary)
    if hand: h = HOUSES[hand]['h']
    parts.append({'poly': g, 'h': h, 'floors': floors_c, 'style': style, 'tint': (crc >> 4) % 9, 'roofc': (crc >> 12) % 5, 'bid': bid, 'look': look, 'hand': hand})

for pid, floors, v in raw:
    bid = pid.split('_')[0]
    x, z = utm30_to_local(v[:, 0], v[:, 1])
    if not inside(x.mean(), z.mean()): continue
    p = Polygon(np.column_stack([x, z])).buffer(0)
    if p.is_empty: continue
    if bid in SHIFT_RC: p = shapely.affinity.translate(p, *SHIFT_RC[bid])
    if p.intersects(corridor): p = p.difference(corridor)
    for gi, bay in enumerate(garage_bays):
        if p.intersects(bay):
            was = p.area
            p = p.difference(bay).buffer(-0.3, join_style=2).buffer(0.3, join_style=2)      # (no slivers left standing)
            print('garage', GARAGES[gi]['id'], 'cuts part', bid, 'floors', floors, 'area %.0f -> %.0f' % (was, p.area))
    if bid in PETRIL_PARTS:                 # (the Petril: solid, but built by petril.gd)
        ph = PETRIL_PARTS[bid].get(pid.split('_')[-1])
        if ph is not None: petril_parts.append((bid, floors, p, ph))
        continue
    if bid == RESIDENCIA_RC: continue        # (the home of the Cristo del Prado built by hand as well: nothing of the parcel is raised)
    if bid == CRISTOPRADO_RC:               # (the hermitage of the Cristo del Prado: what of the parcel is the hermitage goes, the home stays)
        p = p.difference(cristoprado_built.buffer(0.05, join_style=2)).buffer(-0.2, join_style=2).buffer(0.2, join_style=2)
        if p.is_empty or p.area < 5: continue
    hand = house_of(bid, floors, p)
    if hand and 'reach' in HOUSES[hand] and LineString(HOUSES[hand]['front']).distance(p) > HOUSES[hand]['reach']:
        hand = None                         # ("reach": <m> -- a block of a deep plot farther than that behind the front stays an ordinary part:
                                            #  up the hill at the back, it would lift the floor of the whole house; Travesía del Santo 8)
    if hand is None and bid in STRIP_RC:    # (a strip stuck on the front of a hand-built house: see "strip")
        sd_ = HOUSES[STRIP_RC[bid]]
        o_, u_, n_, ln_ = house_frame(sd_)
        q_ = p.representative_point()
        s_ = (q_.x - o_[0]) * u_[0] + (q_.y - o_[1]) * u_[1]
        d_ = (q_.x - o_[0]) * n_[0] + (q_.y - o_[1]) * n_[1]
        if -0.5 < s_ < ln_ + 0.5 and abs(d_) < sd_['strip']:
            continue
    if hand:                                # (it stays a part: it is still a block to bump into, a roof on the map, a neighbour that hides walls; only its own walls and roof are not drawn)
        hd = HOUSES[hand]
        if 'porch' in hd:
            o_, u_, n_, _ln = house_frame(hd)
            a0, a1, deep = hd['porch']
            at_ = lambda s, d: (o_[0] + u_[0] * s + n_[0] * d, o_[1] + u_[1] * s + n_[1] * d)
            p = p.difference(Polygon([at_(a0, 1.0), at_(a1, 1.0), at_(a1, -deep), at_(a0, -deep)]))
        if 'clear' in hd:                   # "clear": <m> -- what of the plot lies in front of its front, this far out, goes
            o_, u_, n_, ln_ = house_frame(hd)     # (where the map's street runs over the real fronts: the house stands at the kerb)
            at_ = lambda s, d: (o_[0] + u_[0] * s + n_[0] * d, o_[1] + u_[1] * s + n_[1] * d)
            p = p.difference(Polygon([at_(-1.0, hd['clear']), at_(ln_ + 1.0, hd['clear']), at_(ln_ + 1.0, 0.0), at_(-1.0, 0.0)]))
        hand_groups.setdefault(hand, [bid, floors, []])[2].append(p)
        continue
    look = look_of(pid, floors)
    if look:                                # (the parts of one house that share a look and a height become one piece: one front, not two halves)
        look_groups.setdefault((bid, look['look'], min(floors, 5)), [look, []])[1].append(p)
        continue
    for g in (p.geoms if p.geom_type == 'MultiPolygon' else [p]):
        add_part(g, bid, floors)
for name, hd in HOUSES.items():           # "fill": [[from, to, deep], ...] -- ground behind a front that Catastro leaves out of the plot's
    if hd.get('fill') and name in hand_groups:      # parts (its front drawn metres back from the street, a porch under the floor above): a
        o_, u_, n_, ln_ = house_frame(hd)           # box of the house there, metres along its front and back from it (Calle de las Delicias 3)
        for a0, a1, deep in hd['fill']:
            pts = [(o_[0] + u_[0] * s + n_[0] * d, o_[1] + u_[1] * s + n_[1] * d) for s, d in ((a0, 0.0), (a1, 0.0), (a1, -deep), (a0, -deep))]
            hand_groups[name][2].append(Polygon(pts))
for name, hd in HOUSES.items():           # the ones that are not in Catastro at all: a box behind their front, as deep as they say
    if hd['rc'] is None:
        o_, u_, n_, ln_ = house_frame(hd)
        at_ = lambda s, d: (o_[0] + u_[0] * s + n_[0] * d, o_[1] + u_[1] * s + n_[1] * d)
        hand_groups[name] = ['HAND_' + name, hd['floors'], [Polygon([at_(0, 0), at_(ln_, 0), at_(ln_, -hd['deep']), at_(0, -hd['deep'])])]]
# The body reaches the front. A front is a line of its own (a whole row is laid on one straight line, a corner follows
# its street), and Catastro's plot seldom ends exactly on it. Where the plot stopped short of the line by more than the
# game takes for the front itself (0.6 m: casas.gd, _on_front), the game drew the plot's edge as a second front behind
# the first, which stood loose before it ("fachadas dobles", 25 November 2026). So the plot of a house drawn from its
# spec grows forward to its line wherever it lies less than FRONT_REACH behind it -- what "fill" does by hand -- but
# never over its own porch, another described house, or the roadway of the map's street (FRONT_ROAD from its line: a
# front that runs into it is a front drawn wrong, and tools/casas/frentes_al_solar.py takes it back to its plot in
# calles.json, and its neighbours with it -- MATRI_FRONTS=<file> makes this bake write what that tool reads). Left as they are: the houses whose gap
# is under FRONT_TOL all along; the ones built by a function of their own (terraces behind their gardens); the ones
# with "strip" (a yard wall on the street, the house back behind it) or "grow": 0; and a recess deeper than FRONT_SURE
# that takes only a part of the front (a porch, a stair, a yard: it may be real, and is listed).
FRONT_REACH, FRONT_SURE, FRONT_TOL, FRONT_ROAD = 3.0, 1.9, 0.5, 2.1
_gd = lambda f: open(os.path.join(HERE, '..', 'godot', 'scripts', f), encoding='utf-8').read()
_cc, _cg = _gd('casas_calles.gd'), _gd('casas.gd')
_own_build = set(re.findall(r'"([a-z0-9_]+)":\s*\["obra"\]', _cc)) | (set(re.findall(r'^func _([a-z0-9_]+)\(\) -> void:', _cg, re.M)) & set(HOUSES))
for _t in ('ADOSADOS', 'ROSAS', 'HILERA21'):
    _own_build |= set(re.findall(r'"([a-z0-9_]+)":', re.search(r'^const %s := \{(.*)$' % _t, _cc, re.M).group(1)))
def _sweep(g, vx, vz):
    """every point of g carried along (vx, vz): g, g moved, and what each of its edges sweeps on the way"""
    res = []
    for q in (g.geoms if hasattr(g, 'geoms') else [g]):
        if q.geom_type != 'Polygon' or q.is_empty: continue
        c = list(q.exterior.coords)
        res.append(q); res.append(Polygon([(x + vx, z + vz) for x, z in c]))
        for (ax, az), (bx, bz) in zip(c, c[1:]):
            s = Polygon([(ax, az), (bx, bz), (bx + vx, bz + vz), (ax + vx, az + vz)])
            if s.area > 1e-4: res.append(s.buffer(0))
    return unary_union([q for q in res if q.is_valid and not q.is_empty])
_whole = {name: shapely.make_valid(unary_union([shapely.make_valid(q).buffer(0.2, join_style=2) for q in g[2]]).buffer(-0.2, join_style=2)) for name, g in hand_groups.items()}
_names = list(_whole); _tree = STRtree([_whole[k] for k in _names])
_roadway = unary_union([LineString([npts[i] for i in r['p']]) for r in roads if len(r['p']) > 1]).buffer(FRONT_ROAD)
front_grown, front_left, front_road, front_pull = [], [], [], {}
for name in _names:
    hd = HOUSES[name]
    if name in _own_build or hd['rc'] is None or hd.get('strip') or hd.get('grow') == 0: continue
    o_, u_, n_, ln_ = house_frame(hd)
    at_ = lambda s, d: (o_[0] + u_[0] * s + n_[0] * d, o_[1] + u_[1] * s + n_[1] * d)
    def _gap(reach):
        slab = Polygon([at_(0.0, 0.0), at_(ln_, 0.0), at_(ln_, -reach), at_(0.0, -reach)])
        near = _whole[name].intersection(slab)
        if near.is_empty: return near
        g = shapely.make_valid(_sweep(near, n_[0] * reach, n_[1] * reach)).intersection(slab).difference(_whole[name])
        if 'porch' in hd:
            a0, a1, deep = hd['porch']
            g = g.difference(Polygon([at_(a0, 1.0), at_(a1, 1.0), at_(a1, -deep), at_(a0, -deep)]))
        for j in _tree.query(g):
            if _names[j] != name and _whole[_names[j]].intersects(g): g = g.difference(_whole[_names[j]].buffer(0.05, join_style=2))
        return g
    _run = lambda g, d: g.intersection(LineString([at_(0.0, -d), at_(ln_, -d)])).length
    gap = _gap(FRONT_REACH)
    if gap.is_empty: continue
    if os.environ.get('MATRI_FRONTS') and not ('porch' in hd or 'fill' in hd or 'clear' in hd):
        # the line the plot really has along this front: through the two points of its outline farthest apart along
        # it that leave nothing of the plot more than a hand's breadth ahead of the line, which is then moved out to touch
        near = _whole[name].intersection(Polygon([at_(0.0, 0.0), at_(ln_, 0.0), at_(ln_, -FRONT_SURE), at_(0.0, -FRONT_SURE)]))
        sd = [((x - o_[0]) * u_[0] + (z - o_[1]) * u_[1], (x - o_[0]) * n_[0] + (z - o_[1]) * n_[1])
              for q in (near.geoms if hasattr(near, 'geoms') else [near]) if q.geom_type == 'Polygon' for x, z in q.exterior.coords]
        sd = sorted(set((round(p, 3), round(q, 3)) for p, q in sd))
        best = None
        for i0 in range(len(sd)):
            for i1 in range(len(sd) - 1, i0, -1):
                span = sd[i1][0] - sd[i0][0]
                if span < 0.6 * ln_ or (best and span <= best[0]): break
                k = (sd[i1][1] - sd[i0][1]) / span
                lift = max(d - (sd[i0][1] + k * (p - sd[i0][0])) for p, d in sd)
                if lift <= 0.15: best = (span, sd[i0][1] + lift - k * sd[i0][0], k)
        if best:
            d0 = min(0.0, best[1]); d1 = min(0.0, best[1] + best[2] * ln_)
            if max(-d0, -d1) >= 0.25: front_pull[name] = [[r2(v) for v in at_(0.0, d0)], [r2(v) for v in at_(ln_, d1)], round(-d0, 2), round(-d1, 2), bool(gap.intersects(_roadway) and gap.intersection(_roadway).area >= 0.5)]
    if _run(gap, FRONT_TOL) < 0.3: continue      # (the plot's edge is the front, near enough: as it was)
    far = _run(gap, FRONT_SURE)
    if 0.15 * ln_ < far < 0.85 * ln_:
        gap = _gap(FRONT_SURE); front_left.append((name, round(far, 1), round(ln_, 1)))
        if gap.is_empty or _run(gap, FRONT_TOL) < 0.3: continue
    if gap.intersects(_roadway):
        front_road.append((name, round(gap.intersection(_roadway).area, 1)))
        gap = gap.difference(_roadway)
    pcs = [q for q in (gap.geoms if hasattr(gap, 'geoms') else [gap]) if q.geom_type == 'Polygon' and q.area > 0.02]
    if not pcs: continue
    deep = max(-((x - o_[0]) * n_[0] + (z - o_[1]) * n_[1]) for q in pcs for x, z in q.exterior.coords)
    for q in pcs: hand_groups[name][2].append(q.buffer(0.02, join_style=2))
    front_grown.append((name, round(sum(q.area for q in pcs), 1), round(_run(gap, FRONT_TOL), 1), round(deep, 2)))
print('fronts: %d plots grown to their front line, %.0f m2 (%d by more than 1.6 m)' % (len(front_grown), sum(q[1] for q in front_grown), sum(1 for q in front_grown if q[3] > 1.6)))
print('fronts: a deep recess over a part of the front left alone (review):', ' '.join('%s(%.1f/%.1f)' % q for q in front_left))
print('fronts: the line of the front runs into the roadway, not grown there (review):', ' '.join('%s(%.1f)' % q for q in front_road))
if os.environ.get('MATRI_FRONTS'): json.dump({'grown': front_grown, 'left': front_left, 'road': front_road, 'pull': front_pull}, open(os.environ['MATRI_FRONTS'], 'w'))
for hand, (bid, floors, pieces) in hand_groups.items():
    u = unary_union([q.buffer(0.2, join_style=2) for q in pieces]).buffer(-0.2, join_style=2)
    for g in (u.geoms if u.geom_type == 'MultiPolygon' else [u]):
        add_part(g, bid, floors, None, hand)
for bid, floors, p, ph in petril_parts:
    for g in (p.geoms if p.geom_type == 'MultiPolygon' else [p]):
        g = orient(Polygon(g.exterior).simplify(0.3), 1.0)
        if g.is_empty or g.area < 5 or not g.is_valid: continue
        parts.append({'poly': g, 'h': ph, 'floors': min(floors, 5), 'style': 5, 'tint': 0, 'roofc': 0, 'bid': bid, 'look': None, 'hand': 'petril'})
print('the Petril: %d parts kept solid and left to petril.gd, %.0f m2' % (len(petril_parts), sum(q[2].area for q in petril_parts)))
for (bid, name, floors), (look, pieces) in look_groups.items():
    u = unary_union([q.buffer(0.2, join_style=2) for q in pieces]).buffer(-0.2, join_style=2)
    n0 = len(parts)
    for g in (u.geoms if u.geom_type == 'MultiPolygon' else [u]):
        add_part(g, bid, floors, look)
    print('look', name, bid, 'floors', floors, ': %d parts -> %d pieces, %.0f m2' % (len(pieces), len(parts) - n0, sum(q['poly'].area for q in parts[n0:])))
# ====================== relief ======================
# The real lie of the land, from the IGN's elevation model: smoothed (the model served is stepped to the metre),
# exaggerated so that it is felt at the wheel, with the old stream bed of the Arroyuelo cut a little deeper and a level
# terrace under every hand-built place. Stored as a grid of heights; inside a square the ground is two flat triangles
# split along the diagonal from its (x0, z0) corner to its (x1, z1) corner -- world.gd and map_data.gd do the same.
RELIEF = 2.5          # times the real thing
GRID = 12.0           # metres between heights
SMOOTH = 25.0         # metres of blur
EDGE = 60.0           # the grid runs this far past the map
ARROYO_DEEP, ARROYO_HALF = 2.3, 46.0       # a broad, shallow dip: the banks rise gently past the first row of houses
BLEND = 40.0          # a terrace eases back into the slope over this distance
_d = np.load(os.path.join(HERE, 'ign', 'mdt05_utm.npz'))
dem, dem_x0, dem_y0, dem_cell = _d['z'].astype(float), float(_d['x0']), float(_d['y0']), float(_d['cell'])
def _blur(g, s):
    r = int(s * 3); k = np.exp(-0.5 * (np.arange(-r, r + 1) / s) ** 2); k /= k.sum()
    p = np.pad(g, r, mode='edge')
    p = np.apply_along_axis(lambda v: np.convolve(v, k, mode='valid'), 1, p)
    return np.apply_along_axis(lambda v: np.convolve(v, k, mode='valid'), 0, p)
dem = _blur(dem, SMOOTH / dem_cell)
dem_rows, dem_cols = dem.shape
_E = np.array([dem_x0, dem_x0 + dem_cols * dem_cell, dem_x0, dem_x0 + dem_cols * dem_cell, dem_x0 + dem_cols * dem_cell / 2])
_N = np.array([dem_y0, dem_y0, dem_y0 + dem_rows * dem_cell, dem_y0 + dem_rows * dem_cell, dem_y0 + dem_rows * dem_cell / 2])
_lx, _lz = utm30_to_local(_E, _N)                       # over 7 km the map's metres are a straight-line function of UTM, near enough
_A = np.column_stack([_E, _N, np.ones(5)])
_cx = np.linalg.lstsq(_A, _lx, rcond=None)[0]; _cz = np.linalg.lstsq(_A, _lz, rcond=None)[0]
_inv = np.linalg.inv(np.array([[_cx[0], _cx[1]], [_cz[0], _cz[1]]]))
def dem_at(x, z):
    en = _inv @ np.vstack([(np.asarray(x, float) - _cx[2]).ravel(), (np.asarray(z, float) - _cz[2]).ravel()])
    col = (en[0] - dem_x0) / dem_cell - 0.5; row = (dem_y0 + dem_rows * dem_cell - en[1]) / dem_cell - 0.5
    c0 = np.clip(np.floor(col).astype(int), 0, dem_cols - 2); r0 = np.clip(np.floor(row).astype(int), 0, dem_rows - 2)
    fc = np.clip(col - c0, 0, 1); fr = np.clip(row - r0, 0, 1)
    v = dem[r0, c0] * (1 - fc) * (1 - fr) + dem[r0, c0 + 1] * fc * (1 - fr) + dem[r0 + 1, c0] * (1 - fc) * fr + dem[r0 + 1, c0 + 1] * fc * fr
    return v.reshape(np.shape(x))
rx0, rz0 = BOUNDS[0] - EDGE, BOUNDS[2] - EDGE
rnx = int(math.ceil((BOUNDS[1] + EDGE - rx0) / GRID)) + 1
rnz = int(math.ceil((BOUNDS[3] + EDGE - rz0) / GRID)) + 1
RX, RZ = np.meshgrid(rx0 + np.arange(rnx) * GRID, rz0 + np.arange(rnz) * GRID)
RH = dem_at(RX, RZ) * RELIEF
rpts = shapely.points(RX, RZ)
def hfun(x, z):
    """height of the ground at map points (arrays or numbers), exactly as the game will have it"""
    fx = np.clip((np.asarray(x, float) - rx0) / GRID, 0, rnx - 1.001); fz = np.clip((np.asarray(z, float) - rz0) / GRID, 0, rnz - 1.001)
    i = np.floor(fx).astype(int); j = np.floor(fz).astype(int); fx = fx - i; fz = fz - j
    a, b, c, d = RH[j, i], RH[j, i + 1], RH[j + 1, i + 1], RH[j + 1, i]
    return np.where(fx >= fz, a + fx * (b - a) + fz * (c - b), a + fz * (d - a) + fx * (c - d))
# the Arroyuelo: Alto and Medio come down from the north, meet, and run on south as Medio and Bajo
arroyo = unary_union([LineString([npts[i] for i in r['p']]) for r in roads if 'Arroyuelo' in r['n']])
_da = shapely.distance(rpts, arroyo)
_ends = {}                                              # where the bed starts and where it leaves town it fades out, not ends in a pit
for r in roads:
    if 'Arroyuelo' in r['n']:
        for i in (r['p'][0], r['p'][-1]): _ends[i] = _ends.get(i, 0) + 1
_fade = np.ones_like(RH)
for i, n in _ends.items():
    if n == 1:
        f = np.clip(np.hypot(RX - npts[i][0], RZ - npts[i][1]) / 110.0, 0, 1)
        _fade = np.minimum(_fade, f * f * (3 - 2 * f))
RH -= ARROYO_DEEP * _fade * 0.5 * (1 + np.cos(np.pi * np.clip(_da / ARROYO_HALF, 0, 1)))
if townhall:
    RH -= float(hfun(*townhall['m']))                  # the door of the town hall is height zero
pads = []
pad_list = []       # (polygon, height) of the terraces made so far
def terrace(poly, h=None):
    """levels the ground under a hand-built place (and a little way round it, so no facet of the grid tilts inside it).
    An earlier terrace is never disturbed; one too close to an earlier one to have a level of its own takes that one's."""
    d = shapely.distance(rpts, poly)
    if h is None: h = float(hfun(poly.centroid.x, poly.centroid.y))
    for q, qh in pad_list:
        if poly.distance(q) < 3 * GRID + BLEND * 0.5: h = qh
    keep = np.zeros_like(RH)
    for q, qh in pad_list:
        if qh != h: keep = np.maximum(keep, np.clip(1.0 - (shapely.distance(rpts, q) - 1.5 * GRID) / GRID, 0, 1))
    w = np.clip(1.0 - (d - 1.5 * GRID) / BLEND, 0, 1); w = w * w * (3 - 2 * w) * (1 - keep)
    RH[:] = RH * (1 - w) + h * w
    pads.append(h); pad_list.append((poly, h))
def frame_rect(o, u, n, s0, s1, d0, d1):
    return Polygon([(o[0] + u[0] * s + n[0] * d, o[1] + u[1] * s + n[1] * d) for s, d in ((s0, d0), (s1, d0), (s1, d1), (s0, d1))])
if townhall:        # the square and the town hall (plaza.gd)
    u = townhall['u']; terrace(frame_rect(townhall['m'], u, (-u[1], u[0]), -townhall['len'] / 2 - 8, townhall['len'] / 2 + 8, -townhall['depth'] - 6, 96), 0.0)
if coop:            # the cooperative and its stretch of avenue (coop.gd)
    u = coop['u']; cpoly = frame_rect(coop['o'], u, (-u[1], u[0]), -44, coop['len'] + 14, -10, coop['depth'] + 4)
    terrace(cpoly, float(RH[shapely.contains(cpoly, rpts)].mean()))
if church:          # the church with its atrium, its little square and the parking along its north wall (iglesia.gd)
    u = church['u']; terrace(frame_rect(church['o'], u, (-u[1], u[0]), -16, church['len'] + 10, -church['wid'] - 16, 16))
terrace(salud_poly.buffer(4.0))      # the health centre (salud.gd)
if molino: terrace(molino_zone.buffer(3.0))      # the windmill and its yard (molino.gd)
if toros: terrace(toros_zone.buffer(3.0))        # the old bullring and its lot (toros.gd)
if calasanz:        # the nursery school and its yard (calasanz.gd). The street falls 3 m along its plot towards the Arroyuelo: it is
    # levelled at the height of the street in front of its gate plus a hand, not at the middle of the plot -- that
    # raised the crossroads of the Arroyuelo, a few metres from its corner, by 2.6 m, and the old stream's bed ran uphill to it.
    _cu = CALASANZ['u']; _cg = (CALASANZ['o'][0] + _cu[0] * 12.0 - _cu[1] * 7.0, CALASANZ['o'][1] + _cu[1] * 12.0 + _cu[0] * 7.0)
    terrace(calasanz_zone.buffer(1.0), float(hfun(*_cg)) + 0.25)
for gdef, mouth in zip(garages, garage_mouths):       # the garages: the bay and its forecourt
    n = gdef['n']; terrace(frame_rect(gdef['m'], (n[1], -n[0]), n, -gdef['left'] - 3, gdef['right'] + 3, -gdef['d'] - 2, 13))
for cx_, cz_, rad in ((195.6, 84.4, 10.0), (-99.8, -82.9, 9.0), (1800.0, -1350.0, 45.0)):      # V.I.P.'s front, Henry's, and the set of V.I.P.'s inside
    # (Henry's terrace stays where the shop first stood, two doors on: it levels the shop's real place too, 16 m off,
    # and moving it there pulled the slope round the crossroads with the Calle Real down by up to 2 m)
    terrace(Point(cx_, cz_).buffer(rad))
SUNK = 2.0          # how far below the town hall's square the Arroyuelo runs past it
if townhall:        # The square is level, but the old stream bed along its west side is not up there with it: the street
    # runs a good two metres lower, past a raised pavement on a stone wall and the white wall of the square (user,
    # 12 November 2026, with photos). The ground is cut down along that stretch; plaza.gd builds what holds the square up.
    u = townhall['u']
    near = frame_rect(townhall['m'], u, (-u[1], u[0]), -townhall['len'] / 2 - 40, townhall['len'] / 2, -townhall['depth'] - 30, 125)
    bed = arroyo.intersection(near)
    _db = shapely.distance(rpts, bed)
    _w = np.clip(1.0 - (_db - 20.0) / 24.0, 0, 1); _w = _w * _w * (3 - 2 * _w)
    _was = RH.copy()
    RH[:] = np.minimum(RH, RH * (1 - _w) + (-SUNK) * _w)
    print('the Arroyuelo past the square: %.0f m of street sunk %.1f m; %d heights lowered, by up to %.2f m' % (bed.length, SUNK, int((_was - RH > 0.01).sum()), float((_was - RH).max())))
    for q, qh in pad_list[1:]:
        if q.distance(bed) < 44: print('  WARNING: that also lowers the terrace round (%.0f, %.0f)' % (q.centroid.x, q.centroid.y))
def pit(poly, h, clear=19.0):
    """digs (or fills) the ground to one level inside a polygon, height by height, with no margin and no blend round it (a
    terrace levels 18 m more and eases out over 40: too much beside a street). The triangles of the grid that straddle its
    edge slope from that level to the ground outside, up to 12 m either way: whatever is built there must hide or use that
    slope (mercamona.gd: under the shop, the ramp down from the gate, the fall of the tarmac from the street). No height
    within `clear` of a street for cars is touched (a triangle reaches 17 m from its corner, a roadway 1.8 m from its
    line): no street changes height or tilts."""
    _cars = unary_union([LineString([npts[i] for i in r['p']]) for r in roads if r['k'] == 0])
    inside = shapely.contains(poly, rpts) & (shapely.distance(rpts, _cars) >= clear)
    was = RH[inside].copy()
    RH[inside] = h
    return int(inside.sum()), (float(np.abs(RH[inside] - was).max()) if inside.any() else 0.0)
if mercamona:       # the supermarket's car park, a floor (3.2 m) below the shop's, which is level with the old road at its doors
    _mu = MERCAMONA['u']; _me = (MERCAMONA['o'][0] + _mu[0] * 10.0 - _mu[1] * 1.5, MERCAMONA['o'][1] + _mu[1] * 10.0 + _mu[0] * 1.5)
    mercamona['low'] = round(float(hfun(*_me)) + 0.05 - 3.2, 2)
    _n, _d = pit(mercamona_pit, mercamona['low'])
    print('Mercamona: its car park dug to %.2f; %d heights changed, by up to %.2f m' % (mercamona['low'], _n, _d))
for p in parts:     # every building stands level: its floor a little above the middle of the ground it covers
    c = np.asarray(p['poly'].exterior.coords)
    hs = hfun(c[:, 0], c[:, 1])
    p['base'] = float(hs.min() + 0.6 * (hs.max() - hs.min()))
    p['range'] = float(hs.max() - hs.min())
_rng = np.array([p['range'] for p in parts]); _ar = np.array([p['poly'].area for p in parts])
print('buildings on a slope: ground under them differs by >0.6 m: %d, >1 m: %d, >1.5 m: %d, >2 m: %d, >3 m: %d (of %d); those >1.5 m cover %.0f m2 on average'
      % ((_rng > 0.6).sum(), (_rng > 1).sum(), (_rng > 1.5).sum(), (_rng > 2).sum(), (_rng > 3).sum(), len(parts), _ar[_rng > 1.5].mean() if (_rng > 1.5).any() else 0))
print('relief %d x %d heights, %.1f to %.1f m | terraces %s' % (rnx, rnz, RH.min(), RH.max(), [round(h, 1) for h in pads]))
_gz, _gx = np.gradient(RH, GRID)
print('slopes (%%): median %.1f, 90%% under %.1f, 99%% under %.1f, steepest %.1f' % tuple(list(np.percentile(np.hypot(_gx, _gz) * 100, [50, 90, 99])) + [float(np.hypot(_gx, _gz).max() * 100)]))

polys = [p['poly'] for p in parts]
tree = STRtree(polys)
heights = np.array([p['base'] + p['h'] for p in parts])

# ---- walls: drop the ones buried inside a neighbour that is at least as tall ----
ex1, ez1, ex2, ez2, eown = [], [], [], [], []
for i, p in enumerate(parts):
    c = np.asarray(p['poly'].exterior.coords)
    for (x1, z1), (x2, z2) in zip(c[:-1], c[1:]):
        if math.hypot(x2 - x1, z2 - z1) < 0.3: continue
        ex1.append(x1); ez1.append(z1); ex2.append(x2); ez2.append(z2); eown.append(i)
ex1, ez1, ex2, ez2, eown = map(np.array, (ex1, ez1, ex2, ez2, eown))
dx, dz = ex2 - ex1, ez2 - ez1; ln = np.hypot(dx, dz)
probe = shapely.points((ex1 + ex2) / 2 + dz / ln * 0.25, (ez1 + ez2) / 2 - dx / ln * 0.25)   # just outside each wall (rings are CCW)
ei, pi = tree.query(probe, predicate='within')
hidden = np.zeros(len(ex1), dtype=bool)
ok = (pi != eown[ei]) & (heights[pi] >= heights[eown[ei]] - 0.25)
hidden[ei[ok]] = True
# Now that we know which walls show: a house takes its level from the street it faces, so that its door meets the
# pavement, whatever the ground does behind. (Then the walls are sorted out again, since the heights have moved.)
_mx, _mz = (ex1 + ex2) / 2 + dz / ln * 2.5, (ez1 + ez2) / 2 - dx / ln * 2.5
_near = road_tree.nearest(shapely.points(_mx, _mz))
_rd = shapely.distance(shapely.points(_mx, _mz), np.array(road_lines, dtype=object)[_near])
_front = (~hidden) & (ln > 2.0) & (_rd < np.array([roads[i]['w'] for i in _near]) / 2 + 5.0)
_by_part = {}
for k in np.nonzero(_front)[0]:
    _by_part.setdefault(int(eown[k]), []).append(k)
_moved = 0
for i, ks in _by_part.items():
    # "base_from": [street, ...] on a house: only its walls on those streets set its level (rro_19, on the corner of the
    # Calle Rollo once that lane was redrawn, took it from a side wall on the lane, uphill, and stood 0.9 m above its door)
    _only = HOUSES.get(parts[i].get('hand') or '', {}).get('base_from')
    if _only:
        ks = [k for k in ks if roads[_near[k]]['n'] in _only] or ks
    xs = np.concatenate([np.linspace(ex1[k], ex2[k], 5) for k in ks]); zs = np.concatenate([np.linspace(ez1[k], ez2[k], 5) for k in ks])
    hs = hfun(xs, zs)
    base = float(hs.min() + 0.9 * (hs.max() - hs.min()))      # near the top of its stretch of street: a door may need a step up to it, but is never dug in
    if abs(base - parts[i]['base']) > 0.05: _moved += 1
    parts[i]['base'] = base
    parts[i]['front_range'] = float(hs.max() - hs.min())
# Where the Arroyuelo Medio is still the bed of the old stream, it runs lower than the houses: a raised pavement on a
# stone wall each side (Street View, Nov 2024; the user's photos, 14 November 2026). The game builds the pavements
# (arroyo.gd); here the houses on that stretch go up to meet them. Each stretch: its centre line and how high the
# pavements stand over the street at its two ends.
RAISED = []      # (tried 2026-11-14 for one stretch and taken out again at the user's word: it looked wrong)
_raised_n = 0
for st in RAISED:
    sl = LineString(st['line'])
    for i, ks in _by_part.items():
        mids = [Point((ex1[k] + ex2[k]) / 2, (ez1[k] + ez2[k]) / 2) for k in ks]
        best = min(mids, key=lambda q: q.distance(sl))
        if best.distance(sl) > 9.0: continue
        s_ = sl.project(best)
        if s_ < 0.5 or s_ > sl.length - 0.5: continue
        parts[i]['base'] += st['h0'] + (st['h1'] - st['h0']) * s_ / sl.length
        _raised_n += 1
print('raised pavements of the Arroyuelo: %d houses lifted to meet them' % _raised_n)
# The old bridge of the Arroyuelo Medio and the stretch of bed it crosses (godot/scripts/puente.gd; the user, 15 November
# 2026; referencias/puente_arroyuelo/, tools/puente/): from the Calle del Santo down to the corner of Matías Pérez the
# street is the bed of the old stream, between two raised pavements; puente.gd builds them and the bridge. Its frame: the
# middle of the bridge, x across the bed towards the row of the even numbers, z down the bed. Here: how high the
# pavements stand (level with the deck from PUENTE_FLAT[0] down; further up, following the bed), and the houses of the
# east row that stood lower raised to the pavement at the upper end of their fronts, so that their doors open on to it.
PUENTE = {'o': (-149.61, -261.23), 'u': (0.443, 0.896)}
PUENTE_RISE = 1.05                                  # the deck over the bed
PUENTE_FLAT = (-14.6, 3.6)
PUENTE_NORTH = ((-40.0, 0.55), (-27.0, 0.55))       # further up the bed: z, how far over it
puente = {}
_puente_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'puente.gd')
if os.path.exists(_puente_gd) and 'const READY := true' in open(_puente_gd, encoding='utf-8').read():
    _po, _pu = PUENTE['o'], PUENTE['u']
    _pa = (_pu[1], -_pu[0])
    def _pw(x, z): return _po[0] + _pa[0] * x + _pu[0] * z, _po[1] + _pa[1] * x + _pu[1] * z
    def _pl(wx, wz): return (wx - _po[0]) * _pa[0] + (wz - _po[1]) * _pa[1], (wx - _po[0]) * _pu[0] + (wz - _po[1]) * _pu[1]
    _ptop = float(hfun(*_pw(0.0, 0.0))) + PUENTE_RISE
    _ppav = [(z, float(hfun(*_pw(0.0, z))) + r) for z, r in PUENTE_NORTH] + [(PUENTE_FLAT[0], _ptop), (PUENTE_FLAT[1], _ptop)]
    _set = {}
    for i, ks in _by_part.items():
        if parts[i].get('hand') and not parts[i]['hand'].startswith('arroyuelo_'): continue      # (a house of another street that only backs on to the bed keeps its own level)
        zs = []
        for k in ks:
            a_, b_ = _pl(ex1[k], ez1[k]), _pl(ex2[k], ez2[k])
            if 3.4 < (a_[0] + b_[0]) / 2 < 8.6 and -38.0 < (a_[1] + b_[1]) / 2 < 10.5 and abs(a_[1] - b_[1]) > abs(a_[0] - b_[0]): zs += [a_[1], b_[1]]
        if zs: _set[i] = float(np.interp(min(zs), [q[0] for q in _ppav], [q[1] for q in _ppav]))
        if i in _set and _set[i] <= parts[i]['base']: del _set[i]       # (a house is only ever raised to the pavement: one that stands higher has its other street to meet)
    for i, lv in list(_set.items()):                # (a house built by hand is one house: all its parts go with its front)
        if parts[i].get('hand'):
            for j, p in enumerate(parts):
                if p.get('hand') == parts[i]['hand']: _set[j] = max(lv, _set.get(j, lv))
    for i, lv in sorted(_set.items()):
        print('the old bridge: %s from %.2f to %.2f' % (parts[i].get('hand') or 'a house of the east row', parts[i]['base'], lv))
        parts[i]['base'] = lv
    puente = {'o': list(_po), 'u': list(_pu), 'top': r2(_ptop), 'pav': [[z, r2(h)] for z, h in _ppav]}
    print('the old bridge: deck at %.2f, pavements %s; %d parts of houses set level with them' % (_ptop, [(z, round(h, 2)) for z, h in _ppav], len(_set)))
# High pavements: where a street's pavements stand well over the road on walls of rubble, as along the Calle del Arroyuelo
# Bajo (Street View, November 2024; the user, 15 November 2026: "Se podría trabajar en las aceras altas y ver cómo
# quedan"). godot/scripts/aceras_altas.gd builds them from what this hands over ('aceras' in map.json): for each stretch,
# points along the middle of the street every metre and a half, the way out to its side, how high its floor is there,
# and the two nodes of the street each point lies between (the game takes the edge of the asphalt from them). Here the
# houses along a stretch go up to its floor, so that their doors open on to it. Each stretch: the street, the side (E,
# W, N or S: where it lies from the middle of the street), where it begins and ends (spots by the street: the stretch
# between where they fall on it), and how high its floor stands over the middle of the road.
ACERAS_ALTAS = [
    ('Calle del Arroyuelo Bajo', 'E', (-252.0, 14.0), (-268.0, 50.0), 0.35),       # nos. 1, 5, 7
    ('Calle del Arroyuelo Bajo', 'E', (-271.0, 56.0), (-276.0, 114.0), 0.7),       # the walled plot (11), 13, 15, 17
    ('Calle del Arroyuelo Bajo', 'E', (-266.0, 140.0), (-268.0, 208.0), 0.45),     # 23 to 37
    ('Calle del Arroyuelo Bajo', 'W', (-262.0, 18.0), (-276.0, 58.0), 0.4),        # 2, the plot of 4, 6, 8
    ('Calle del Arroyuelo Bajo', 'W', (-278.0, 64.0), (-277.0, 120.0), 0.5),       # the offices (10), 14, 16
    ('Calle del Arroyuelo Bajo', 'W', (-266.0, 136.0), (-270.0, 210.0), 0.45),     # 20 to 32
]
aceras = []
_aceras_n = 0
for _name, _side, _a, _b, _h in ACERAS_ALTAS:
    _segs = []                                  # (a, b, node of a, node of b) for every stretch of that street
    for r in roads:
        if r['n'] == _name and r['k'] == 0:
            for j in range(len(r['p']) - 1):
                _segs.append((r['p'][j], r['p'][j + 1]))
    if not _segs: continue
    def _near(q):                               # where a spot falls on the street: (segment, fraction, point)
        best = None
        for ia, ib in _segs:
            (ax, az), (bx, bz) = npts[ia], npts[ib]
            L2 = (bx - ax) ** 2 + (bz - az) ** 2
            f = 0.0 if L2 < 1e-6 else max(0.0, min(1.0, ((q[0] - ax) * (bx - ax) + (q[1] - az) * (bz - az)) / L2))
            p_ = (ax + (bx - ax) * f, az + (bz - az) * f)
            d = math.dist(p_, q)
            if best is None or d < best[0]: best = (d, (ia, ib), f, p_)
        return best
    _ka, _kb = _near(_a), _near(_b)
    from shapely.ops import linemerge as _linemerge
    _line = _linemerge([LineString([npts[ia], npts[ib]]) for ia, ib in _segs])     # (the street as one line)
    if _line.geom_type != 'LineString': _line = min(_line.geoms, key=lambda g: g.distance(Point(_a)))
    _s0, _s1 = sorted((_line.project(Point(_ka[3])), _line.project(Point(_kb[3]))))
    _pts = []
    _n = max(2, int(round((_s1 - _s0) / 1.5)) + 1)
    for k in range(_n):
        s_ = _s0 + (_s1 - _s0) * k / (_n - 1)
        c_ = _line.interpolate(s_)
        _, (ia, ib), f, _p = _near((c_.x, c_.y))
        (ax, az), (bx, bz) = npts[ia], npts[ib]
        t_ = np.array([bx - ax, bz - az]); t_ = t_ / max(1e-6, np.linalg.norm(t_))
        n_ = np.array([-t_[1], t_[0]])
        want = {'E': (1, 0), 'W': (-1, 0), 'N': (0, -1), 'S': (0, 1)}[_side]
        if n_[0] * want[0] + n_[1] * want[1] < 0: n_ = -n_
        top = float(hfun(np.array([_p[0]]), np.array([_p[1]]))[0]) + _h
        _pts.append([r2(_p[0]), r2(_p[1]), r2(float(n_[0])), r2(float(n_[1])), r2(top), int(ia), int(ib), r2(f)])
    aceras.append({'street': _name, 'side': _side, 'h': _h, 'w': float(next(r['w'] for r in roads if r['n'] == _name and r['k'] == 0)), 'pts': _pts})
    # the houses along it: their fronts on this side, between its ends, go up to its floor
    _sl = LineString([(q[0], q[1]) for q in _pts])
    for i, ks in _by_part.items():
        tops = []
        for k in ks:
            m_ = Point((ex1[k] + ex2[k]) / 2, (ez1[k] + ez2[k]) / 2)
            s_ = _sl.project(m_)
            if s_ < 0.3 or s_ > _sl.length - 0.3: continue
            c_ = _sl.interpolate(s_)
            j_ = min(len(_pts) - 2, int(s_ / _sl.length * (len(_pts) - 1)))
            off = (m_.x - c_.x) * _pts[j_][2] + (m_.y - c_.y) * _pts[j_][3]
            if not (1.0 < off < 12.0): continue
            tops.append(np.interp(s_, [_sl.project(Point(q[0], q[1])) for q in _pts], [q[4] for q in _pts]))
        if tops and max(tops) > parts[i]['base']:
            parts[i]['base'] = float(max(tops))
            _aceras_n += 1
print('high pavements: %d stretches, %d parts of houses set level with them' % (len(aceras), _aceras_n))
_fr = np.array([p.get('front_range', 0.0) for p in parts])
print('houses that face a street: %d (%d took a new level from it); the street falls >0.6 m along the front of %d, >1 m of %d, >1.5 m of %d' % (len(_by_part), _moved, (_fr > 0.6).sum(), (_fr > 1).sum(), (_fr > 1.5).sum()))
heights = np.array([p['base'] + p['h'] for p in parts])
hidden = np.zeros(len(ex1), dtype=bool)
ok = (pi != eown[ei]) & (heights[pi] >= heights[eown[ei]] - 0.25)
hidden[ei[ok]] = True
walls = [[] for _ in range(N_STYLES)]   # per facade style: x1, z1, x2, z2, height, floors, tint
wall_y = [[] for _ in range(N_STYLES)]  # ...and for each of those walls, the level its building stands at
hand_edges = {}
for k in range(len(ex1)):
    if parts[eown[k]].get('hand'):
        hand_edges.setdefault(int(eown[k]), []).append([r2(ex1[k]), r2(ez1[k]), r2(ex2[k]), r2(ez2[k]), int(hidden[k]), int(_front[k])])
for k in np.nonzero(~hidden)[0]:
    p = parts[eown[k]]
    if p.get('hand'): continue
    st = p['style']
    lk = p.get('look')
    if lk and 'short' in lk and ln[k] < lk['short'][1]: st = 7 + LOOK_NAMES.index(lk['short'][0])      # (its short ends have a front of their own)
    walls[st] += [r2(ex1[k]), r2(ez1[k]), r2(ex2[k]), r2(ez2[k]), r2(p['h']), p['floors'], p['tint']]
    wall_y[st].append(r2(p['base']))
for i, name in enumerate(LOOK_NAMES):
    print('look %-16s %2d walls, %5.1f m of them' % (name, len(wall_y[7 + i]), sum(math.hypot(walls[7 + i][o + 2] - walls[7 + i][o], walls[7 + i][o + 3] - walls[7 + i][o + 1]) for o in range(0, len(walls[7 + i]), 7))))

# ---- roofs: a gable where the part is a decent rectangle, otherwise a flat tiled slab ----
roofs_gable, roofs_flat = [], []
houses = []
for name, hd in HOUSES.items():
    mine = [p for p in parts if p.get('hand') == name]
    if not mine: continue
    o_, u_, n_, ln_ = house_frame(hd)
    pieces = [{'ring': [r2(v) for xy in list(p['poly'].exterior.coords)[:-1] for v in xy], 'edges': hand_edges.get(i, [])} for i, p in enumerate(parts) if p.get('hand') == name]
    houses.append({'id': name, 'o': [r2(o_[0]), r2(o_[1])], 'u': [round(u_[0], 4), round(u_[1], 4)], 'len': r2(ln_), 'h': hd['h'],
                   'base': r2(max(p['base'] for p in mine)), 'pieces': pieces})
    print('house', name, 'front %.2f m, floor at %.2f' % (ln_, houses[-1]['base']), '(%d parts)' % len(mine))
for p in parts:
    if p.get('hand'): continue
    g = p['poly']; rect = g.minimum_rotated_rectangle
    rc = np.asarray(rect.exterior.coords)
    a, b = rc[1] - rc[0], rc[2] - rc[1]
    la, lb = float(np.hypot(*a)), float(np.hypot(*b))
    if p['style'] not in (4, 6) and la > 3 and lb > 3 and g.area / (la * lb) > 0.86 and min(la, lb) < 15:
        long_v = a if la >= lb else b
        roofs_gable.append([r2(rect.centroid.x), r2(rect.centroid.y), r2(max(la, lb)), r2(min(la, lb)), round(math.atan2(long_v[1], long_v[0]), 3), r2(p['base'] + p['h']), p['roofc']])
    else:
        roofs_flat.append([r2(p['base'] + p['h']), p['roofc'] if p['style'] not in (4, 6) else 5] + [r2(v) for xy in list(g.exterior.coords)[:-1] for v in xy])

# ---- collision: outline of every block, as seen from the street ----
blocks = unary_union([p.buffer(0.05) for p in polys])
blocks = [g for g in (blocks.geoms if blocks.geom_type == 'MultiPolygon' else [blocks])]
blocks.append(salud_poly)      # (the health centre, hand-built too)
if church_poly is not None: blocks.append(church_poly)      # (its walls are built by hand; it is still a block to bump into and to draw on the map)
outlines = []
for g in blocks:
    ring = Polygon(g.exterior).simplify(0.3)
    if ring.geom_type == 'Polygon' and ring.area > 3: outlines.append([r2(v) for xy in list(ring.exterior.coords)[:-1] for v in xy])
block_list = [Polygon(g.exterior) for g in blocks]
if santaana: block_list.append(santaana_built)      # (the convent of Santa Ana: not a block of the map's, but it does narrow its streets)
if colegio: block_list.append(colegio_built)        # (the old school, likewise)
if cuartel: block_list.append(cuartel_built)        # (the barracks, likewise)
if mercamona: block_list.append(mercamona_built)    # (the supermarket, likewise)
if masahorro: block_list.append(masahorro_built)    # (the supermarket of the Calle de las Viñas, likewise)
if noche: block_list.append(noche_built)            # (the Noche, likewise)
if merkocarry: block_list.extend([merkocarry_built, merkocarry_park, merkocarry_nave])      # (the Merkocarry and its car park's walls, likewise)
if correos: block_list.append(correos_built)        # (the post office, likewise)
if cultura: block_list.append(cultura_built)        # (the block of the Casa Grande, likewise)
if sebastian: block_list.extend([sebastian_built, sebastian_chapel])      # (the hermitage of San Sebastián and its little chapel, likewise)
if cristobal: block_list.append(cristobal_built)    # (the little hermitage of San Cristóbal, likewise)
if almazara: block_list.extend(almazara_built)      # (the oil mill, its long wall and its tall nave on the road, likewise)
if rize: block_list.extend(rize_built)              # (the Cafetería Rize, the garage opposite and the wall at the alley's end, likewise)
if cuevas: block_list.extend(cuevas_built)          # (the dance hall of the old road, its terrace and its sheds, likewise)
if travesia: block_list.extend(travesia_built)      # (the west row of the Travesía del Clavel and the white house on the Clavel, likewise)
if cristoprado: block_list.append(cristoprado_built)    # (the hermitage of the Cristo del Prado, likewise)
if residencia: block_list.extend(residencia_built)    # (and the old people's home beside it)
block_tree = STRtree(block_list)
def building_dist(x, z):
    i = block_tree.nearest(Point(x, z)); return block_list[i].distance(Point(x, z))
clr = [r1(min(30.0, building_dist(x, z))) for x, z in npts]      # free half-width of the street at each node

# bell tower for the main church
towers = []
for w in ways:
    t = w.get('tags', {})
    if 'Divino Salvador' in t.get('name', '') and len(w['nodes']) > 3 and not church:      # (the hand-built church brings its own tower)
        c = Polygon(poly_of(w)).buffer(0).centroid; towers.append([r1(c.x), r1(c.y)])

# ====================== land use + trees ======================
areas, trees = [], []   # area kinds: 0 park 1 pitch 2 vineyard 3 orchard 4 farmland 5 water; tree kinds: 0 round 1 olive 2 cypress
def tree_ok(x, z, road_margin):
    if plaza_keeps_clear(x, z) or coop_keeps_clear(x, z, 4.0): return False
    d, r = road_dist(x, z)
    return d > r['w'] / 2 + road_margin and building_dist(x, z) > 2.0
for w in ways:
    t = w.get('tags', {})
    if 'highway' in t or 'building' in t or w['nodes'][0] != w['nodes'][-1]: continue
    lu, le = t.get('landuse'), t.get('leisure'); k = None
    if le in ('park', 'garden', 'playground', 'recreation_ground') or lu in ('grass', 'recreation_ground', 'meadow'): k = 0
    elif le in ('pitch', 'sports_centre'): k = 1
    elif le == 'swimming_pool': k = 5
    elif lu == 'vineyard': k = 2
    elif lu == 'orchard': k = 3
    elif lu == 'farmland': k = 4
    if k is None: continue
    pl = poly_of(w)
    if len(pl) < 4 or not all(inside(*q) for q in pl): continue
    areas.append({'k': k, 'p': [r1(v) for q in pl[:-1] for v in q]})
    if k in (0, 3):
        g = Polygon(pl).buffer(0); step = 13 if k == 0 else 11
        x0, z0, x1, z1 = g.bounds; x = x0
        while x < x1:
            z = z0
            while z < z1:
                px, pz = x + random.uniform(-2.5, 2.5), z + random.uniform(-2.5, 2.5)
                if g.contains(Point(px, pz)) and tree_ok(px, pz, 3): trees.append([r1(px), r1(pz), 0 if k == 0 else 1])
                z += step
            x += step
olives = [t for t in trees if t[2] == 1]; others = [t for t in trees if t[2] != 1]
random.shuffle(olives); trees = others + olives[:2600]
for _ in range(2500):   # a few street trees where a street is wide enough to have them
    x, z = random.uniform(-1000, 1000), random.uniform(-1100, 1300)
    d, r = road_dist(x, z)
    if r['k'] == 0 and r['w'] / 2 + 0.8 < d < r['w'] / 2 + 2.5 and building_dist(x, z) > 2.5 and not plaza_keeps_clear(x, z) and not coop_keeps_clear(x, z, 4.0): trees.append([r1(x), r1(z), random.choice([0, 0, 2])])

trees = [t for t in trees if not any(m.contains(Point(t[0], t[1])) for m in garage_mouths)]      # nothing growing in a garage doorway
if church:          # the church plants its own
    u = church['u']; _yard = frame_rect(church['o'], u, (-u[1], u[0]), -13, church['len'] + 6, -church['wid'] - 13, 13)
    trees = [t for t in trees if not _yard.contains(Point(t[0], t[1]))]
_n_trees = len(trees)
trees = [t for t in trees if not petril_zone.contains(Point(t[0], t[1]))]      # the Petril plants its own (a tree and its cypresses)
trees = [t for t in trees if not molino_zone.contains(Point(t[0], t[1]))]      # ...and so does the mill's yard
trees = [t for t in trees if not toros_zone.contains(Point(t[0], t[1]))]       # ...and the bullring's lot
trees = [t for t in trees if not calasanz_zone.buffer(1.5).contains(Point(t[0], t[1]))]      # ...and the school's yard
trees = [t for t in trees if not caridad_zone.contains(Point(t[0], t[1]))]      # ...and the island of the hermitage of the Caridad (caridad.gd plants its own)
trees = [t for t in trees if not santaana_zone.contains(Point(t[0], t[1]))]     # ...and the convent of Santa Ana
trees = [t for t in trees if not colegio_zone.contains(Point(t[0], t[1]))]      # ...and the old school and its court (colegio.gd plants its own)
trees = [t for t in trees if not cuartel_zone.contains(Point(t[0], t[1]))]      # ...and the barracks, its apron and its yard
trees = [t for t in trees if not mercamona_zone.contains(Point(t[0], t[1]))]    # ...and the supermarket, its lawns and its car park
trees = [t for t in trees if not masahorro_zone.contains(Point(t[0], t[1]))]    # ...and the supermarket of the Calle de las Viñas and its car park
trees = [t for t in trees if not merkocarry_zone.contains(Point(t[0], t[1]))]   # ...and the Merkocarry, its lane and its car park
trees = [t for t in trees if not ferial_park.contains(Point(t[0], t[1]))]      # ...and the park of the fairground by the Paseo del Cristo (ferial.gd plants its own)
trees = [t for t in trees if not sebastian_zone.contains(Point(t[0], t[1]))]   # ...and the park of San Sebastián and round its hermitage (sebastian.gd plants its own)
trees = [t for t in trees if not cristoprado_zone.contains(Point(t[0], t[1]))]   # ...and round the hermitage of the Cristo del Prado (cristoprado.gd plants its own)
trees = [t for t in trees if not almazara_zone.contains(Point(t[0], t[1]))]     # ...and the oil mill's plot and the verge before it (almazara.gd plants its own pines)
trees = [t for t in trees if not cuevas_zone.contains(Point(t[0], t[1]))]       # ...and the dance hall's plot and the pavement before it (cuevas.gd plants its own cypresses)
# single trees Street View no longer has: the two before the Red Cross on the earth square of the Av. Juan Carlos I
# (Street View 2024: red barriers and one young tree, which requejo.gd plants; Pretil, 23 November 2026)
NO_TREES = [(-430.7, 173.8), (-417.7, 173.9)]
trees = [t for t in trees if not any(abs(t[0] - x) < 0.6 and abs(t[1] - z) < 0.6 for x, z in NO_TREES)]
print('the Petril: %d of the town\'s trees taken out of it' % (_n_trees - len(trees)))

pois = []
for e in els:
    t = e.get('tags', {})
    if 'name' not in t or 'highway' in t: continue
    if e['type'] == 'node': x, z = proj(e['lat'], e['lon'])
    else:
        pl = poly_of(e); x = sum(q[0] for q in pl) / len(pl); z = sum(q[1] for q in pl) / len(pl)
    pois.append({'n': t['name'], 't': t.get('amenity') or t.get('shop') or t.get('man_made') or t.get('leisure') or t.get('building') or '', 'x': r1(x), 'z': r1(z)})

out = {'bounds': BOUNDS, 'nodes': [r1(v) for q in npts for v in q], 'clr': clr, 'roads': roads, 'areas': areas, 'trees': trees, 'pois': pois,
       'walls': walls, 'roofs_gable': roofs_gable, 'roofs_flat': roofs_flat, 'outlines': outlines, 'towers': towers, 'townhall': townhall, 'coop': coop, 'garages': garages, 'church': church, 'salud': salud, 'petril': petril, 'molino': molino, 'toros': toros, 'puente': puente, 'calasanz': calasanz, 'caridad': caridad, 'santaana': santaana, 'mercamona': mercamona, 'masahorro': masahorro, 'noche': noche, 'merkocarry': merkocarry, 'correos': correos, 'cultura': cultura, 'sebastian': sebastian, 'cristobal': cristobal, 'cristoprado': cristoprado, 'residencia': residencia, 'colegio': colegio, 'cuartel': cuartel, 'almazara': almazara, 'rize': rize, 'cuevas': cuevas, 'travesia': travesia, 'aceras': aceras, 'raised': [{'line': [list(q) for q in st['line']], 'h0': st['h0'], 'h1': st['h1']} for st in RAISED],
       'wall_y': wall_y, 'looks': LOOK_NAMES, 'houses': houses, 'relief': {'g': GRID, 'x0': rx0, 'z0': rz0, 'nx': rnx, 'nz': rnz, 'h': [int(round(v * 100)) for v in RH.ravel()]}}
path = os.path.join(HERE, '..', 'godot', 'data', 'map.json')
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, 'w', encoding='utf-8') as f:
    json.dump(out, f, ensure_ascii=False, separators=(',', ':'))

res_clr = sorted(clr[i] for r in roads if r['h'] == 'residential' for i in r['p'])
print('parts', len(parts), 'of', len(raw), '| walls', sum(len(w) for w in walls) // 7, 'hidden', int(hidden.sum()),
      '| gable roofs', len(roofs_gable), 'flat', len(roofs_flat), '| blocks', len(outlines), 'outline pts', sum(len(o) for o in outlines) // 2)
print('townhall', townhall)
print('coop', coop)
print('trees', len(trees), '| towers', towers, '| bytes', os.path.getsize(path))
print('residential street half-clearance (m): min %.1f  10%% %.1f  median %.1f  90%% %.1f' % (res_clr[0], res_clr[len(res_clr) // 10], res_clr[len(res_clr) // 2], res_clr[len(res_clr) * 9 // 10]))
