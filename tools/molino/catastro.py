"""Catastro's building parts inside a rectangle of the game's map, in the game's metres.

    python tools/molino/catastro.py x0 z0 x1 z1 out.json        (prints each building: reference, use, year, parts, area)
"""
import json, math, os, re, sys, zipfile, urllib.request
import numpy as np
from shapely.geometry import Polygon
from shapely.geometry.polygon import orient
sys.path.insert(0, 'C:/Users/luis_/Matritellus/tools')
ROOT = 'C:/Users/luis_/Matritellus/'
LAT0, LON0 = 39.4690, -3.5335
KX = math.cos(math.radians(LAT0)) * 111320.0
KZ = 110574.0
def utm30_to_local(e, n):
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
BOX = tuple(float(v) for v in sys.argv[1:5])      # x0, z0, x1, z1
OUT = sys.argv[5]
zf = zipfile.ZipFile(ROOT + 'tools/catastro/A.ES.SDGC.BU.45088.zip')
gml = zf.read([n for n in zf.namelist() if n.endswith('.buildingpart.gml')][0]).decode('utf8')
bgml = zf.read([n for n in zf.namelist() if n.endswith('.building.gml')][0]).decode('utf8')
use, year = {}, {}
for m in re.finditer(r'<bu-ext2d:Building gml:id="ES\.SDGC\.BU\.([^"]+)">(.*?)</bu-ext2d:Building>', bgml, re.S):
    u = re.search(r'<bu-ext2d:currentUse>([^<]*)<', m.group(2)); y = re.search(r'<bu-core2d:beginning>(\d{4})', m.group(2))
    use[m.group(1)] = u.group(1) if u else ''; year[m.group(1)] = int(y.group(1)) if y else 0
parts = []
for m in re.finditer(r'<bu-ext2d:BuildingPart gml:id="ES\.SDGC\.BU\.([^"]+)">(.*?)</bu-ext2d:BuildingPart>', gml, re.S):
    up = re.search(r'numberOfFloorsAboveGround>(\d+)<', m.group(2)); down = re.search(r'numberOfFloorsBelowGround>(\d+)<', m.group(2))
    for ring in re.findall(r'<gml:exterior>.*?<gml:posList[^>]*>([^<]+)</gml:posList>', m.group(2), re.S):
        v = np.array(ring.split(), dtype=float).reshape(-1, 2)
        x, z = utm30_to_local(v[:, 0], v[:, 1])
        if not (BOX[0] < x.mean() < BOX[2] and BOX[1] < z.mean() < BOX[3]): continue
        p = orient(Polygon(np.column_stack([x, z])).buffer(0), 1.0)
        if p.is_empty or p.geom_type != 'Polygon': continue
        parts.append({'id': m.group(1), 'rc': m.group(1).split('_')[0], 'floors': int(up.group(1)) if up else 0, 'below': int(down.group(1)) if down else 0,
                      'ring': [(round(a, 2), round(b, 2)) for a, b in list(p.exterior.coords)[:-1]], 'area': round(p.area, 1)})
by = {}
for p in parts: by.setdefault(p['rc'], []).append(p)
for rc, ps in sorted(by.items(), key=lambda kv: -sum(q['area'] for q in kv[1])):
    c = Polygon([q for p in ps for q in p['ring']]).centroid if False else None
    xs = [q[0] for p in ps for q in p['ring']]; zs = [q[1] for p in ps for q in p['ring']]
    print('%s  use %-22s year %d  parts %2d  area %6.0f  x %.0f..%.0f  z %.0f..%.0f' % (rc, use.get(rc, ''), year.get(rc, 0), len(ps), sum(q['area'] for q in ps), min(xs), max(xs), min(zs), max(zs)))
json.dump({'box': BOX, 'parts': parts, 'use': {k: use.get(k, '') for k in by}, 'year': {k: year.get(k, 0) for k in by}}, open(OUT, 'w'), indent=0)
print(len(parts), 'parts of', len(by), 'buildings')
