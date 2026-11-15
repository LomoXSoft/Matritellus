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

nid, npts, roads = {}, [], []
def node_index(i):
    if i not in nid:
        nid[i] = len(npts); npts.append(proj(onodes[i]['lat'], onodes[i]['lon']))
    return nid[i]
for w in ways:
    t = w.get('tags', {}); h = t.get('highway')
    if h not in WIDTH: continue
    run = []
    for i in w['nodes'] + [None]:
        if i is not None and inside(*proj(onodes[i]['lat'], onodes[i]['lon'])):
            run.append(node_index(i)); continue
        if len(run) > 1: roads.append({'w': WIDTH[h], 'k': KIND.get(h, 0), 'h': h, 'n': t.get('name', ''), 'p': run})
        run = []
# Streets the map's source names wrongly or not at all, by where they run (their two ends, within a few metres).
# The two parallel streets of the UA-20 development (user, 12 November 2026): Segadores is the southern one.
# (Corrected the same evening: I had them the wrong way round. z runs SOUTH, so the street at z -377..-463 is the southern
# one: Segadores. The houses' own names in the code -- segadores_N, labradores_N -- were given before this and stay crossed.)
RENAME = [((-796.2, -377.4), (-908.5, -462.8), 'Calle de los Segadores'), ((-769.6, -418.3), (-860.1, -487.0), 'Calle de los Labradores')]
for (ax, az), (bx, bz), name in RENAME:
    hit = [r for r in roads if min(math.dist(npts[r['p'][0]], (ax, az)) + math.dist(npts[r['p'][-1]], (bx, bz)), math.dist(npts[r['p'][0]], (bx, bz)) + math.dist(npts[r['p'][-1]], (ax, az))) < 8.0]
    for r in hit: r['n'] = name
    print('street renamed: %s (%d stretch%s)' % (name, len(hit), '' if len(hit) == 1 else 'es'))
def poly_of(w): return [proj(onodes[i]['lat'], onodes[i]['lon']) for i in w['nodes']]

# the corridor every street is guaranteed to keep free of buildings (centre lines drift a little from reality)
def corridor_half(r): return 1.0 if r['k'] == 2 else 1.5 if r['k'] == 1 else 1.9 if r['h'] == 'service' else 2.4
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
def house_of(bid, floors):
    for name, hd in HOUSES.items():
        if hd['rc'] == bid and (floors == hd['only'] if 'only' in hd else floors >= hd['floors']): return name
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
    hand = house_of(bid, floors)
    if hand:                                # (it stays a part: it is still a block to bump into, a roof on the map, a neighbour that hides walls; only its own walls and roof are not drawn)
        hd = HOUSES[hand]
        if 'porch' in hd:
            o_, u_, n_, _ln = house_frame(hd)
            a0, a1, deep = hd['porch']
            at_ = lambda s, d: (o_[0] + u_[0] * s + n_[0] * d, o_[1] + u_[1] * s + n_[1] * d)
            p = p.difference(Polygon([at_(a0, 1.0), at_(a1, 1.0), at_(a1, -deep), at_(a0, -deep)]))
        hand_groups.setdefault(hand, [bid, floors, []])[2].append(p)
        continue
    look = look_of(pid, floors)
    if look:                                # (the parts of one house that share a look and a height become one piece: one front, not two halves)
        look_groups.setdefault((bid, look['look'], min(floors, 5)), [look, []])[1].append(p)
        continue
    for g in (p.geoms if p.geom_type == 'MultiPolygon' else [p]):
        add_part(g, bid, floors)
for name, hd in HOUSES.items():           # the ones that are not in Catastro at all: a box behind their front, as deep as they say
    if hd['rc'] is None:
        o_, u_, n_, ln_ = house_frame(hd)
        at_ = lambda s, d: (o_[0] + u_[0] * s + n_[0] * d, o_[1] + u_[1] * s + n_[1] * d)
        hand_groups[name] = ['HAND_' + name, hd['floors'], [Polygon([at_(0, 0), at_(ln_, 0), at_(ln_, -hd['deep']), at_(0, -hd['deep'])])]]
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
for gdef, mouth in zip(garages, garage_mouths):       # the garages: the bay and its forecourt
    n = gdef['n']; terrace(frame_rect(gdef['m'], (n[1], -n[0]), n, -gdef['left'] - 3, gdef['right'] + 3, -gdef['d'] - 2, 13))
for cx_, cz_, rad in ((195.6, 84.4, 10.0), (-99.8, -82.9, 9.0), (1800.0, -1350.0, 45.0)):      # V.I.P.'s front, Henry's, and the set of V.I.P.'s inside
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
block_tree = STRtree([Polygon(g.exterior) for g in blocks])
block_list = [Polygon(g.exterior) for g in blocks]
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
       'walls': walls, 'roofs_gable': roofs_gable, 'roofs_flat': roofs_flat, 'outlines': outlines, 'towers': towers, 'townhall': townhall, 'coop': coop, 'garages': garages, 'church': church, 'salud': salud, 'petril': petril, 'raised': [{'line': [list(q) for q in st['line']], 'h0': st['h0'], 'h1': st['h1']} for st in RAISED],
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
