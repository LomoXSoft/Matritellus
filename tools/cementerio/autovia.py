"""The A-4 by the cemetery, for the zone (zonas.gd): its two carriageways and the slip roads where the old Madrid-Cádiz
road meets it, from OpenStreetMap (© OpenStreetMap contributors, ODbL), written into godot/data/autovia.json in the
game's metres.

Luis, 25/11/2026: «hacia el norte/oeste podríamos ver la autovía A4 uniéndose a la carretera, con .PNG de coches y
camiones viajando». In OSM the old road (N-IVa) ends 515 m north of the cemetery's middle, at (465, -2955): a loop takes
you on to the southbound carriageway and a slip road brings the southbound traffic off it to the old road. The A-4 itself
runs by the cemetery's east wall, 45-60 m from it.

The Overpass answer is kept in tools/ign/a4_osm.json (fetched once; it is a download: run this with python -I).

    python -I tools/cementerio/autovia.py      ->  godot/data/autovia.json
"""
import json
import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')
LAT0, LON0 = 39.4690, -3.5335                     # the map's origin (bake_godot.py)
KX = math.cos(math.radians(LAT0)) * 111320.0
KZ = 110574.0
NORTH, SOUTH = -4900.0, -1250.0                   # what is drawn of it: past where the eye reaches from the zone, both ways
JOIN = (462.9, -2955.0)                           # the old road's end on the zone's own line of it (zonas.gd), 2 m off OSM's

WAYS = {'sb': [4335373], 'nb': [33847379], 'entrada': [99358371, 933911461], 'salida': [99358372]}


def to_game(g):
    return [round((g['lon'] - LON0) * KX, 1), round(-(g['lat'] - LAT0) * KZ, 1)]


def main():
    data = json.load(open(os.path.join(ROOT, 'tools', 'ign', 'a4_osm.json'), encoding='utf-8'))
    by_id = {e['id']: e for e in data['elements'] if e.get('type') == 'way'}
    out = {'source': '© OpenStreetMap contributors, ODbL', 'join': list(JOIN)}
    for key, ids in WAYS.items():
        pts = []
        for i in ids:
            for p in (to_game(g) for g in by_id[i]['geometry']):
                if not pts or pts[-1] != p:
                    pts.append(p)
        if key in ('sb', 'nb'):
            pts = [p for p in pts if NORTH <= p[1] <= SOUTH]
        if key == 'entrada':
            pts[0] = list(JOIN)
        if key == 'salida':
            pts[-1] = list(JOIN)
        out[key] = pts
        print(key, len(pts), pts[0], pts[-1])
    json.dump(out, open(os.path.join(ROOT, 'godot', 'data', 'autovia.json'), 'w', encoding='utf-8'), separators=(',', ':'))


if __name__ == '__main__':
    main()
