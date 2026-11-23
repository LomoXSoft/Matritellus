"""The mountains on the horizon (the user, 23 Nov 2026: "unas texturas o algo de fondo en la lejanía para que se viesen
las montañas en el horizonte como en algunos puntos del pueblo"): the IGN's 200 m elevation model (MDT200, EPSG:4258,
(c) Instituto Geográfico Nacional, CC BY 4.0) for 100 km round Madridejos, written into godot/data/sierras.json for
godot/scripts/sierras.gd, which draws from it the outline of the Sierra de Madridejos, the Montes de Toledo and the rest
as seen from wherever the camera is.

    python tools/sierras.py      ->  tools/ign/mdt200_ll.asc (the download, kept)  +  godot/data/sierras.json

On top of the ridges, the landmarks seen from the town (the user, 23 Nov 2026: "que se vea el castillo de consuegra y
los molinos"): the Castillo de la Muela and the twelve windmills of the Cerro Calderico, where OpenStreetMap has them
(an Overpass query, kept in tools/ign/consuegra_osm.json), as "hitos": [kind, x, z] in the game's metres.

A lat/long grid is used because the game's own map is a straight scaling of lat/long (bake_godot.py proj), so its rows
and columns are the game's own axes. The heights go in as half floats (1 m steps above 1024 m, finer below), base64.
"""
import base64, io, json, math, os, subprocess
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
LAT0, LON0 = 39.4690, -3.5335                     # the map's origin (bake_godot.py)
KX = math.cos(math.radians(LAT0)) * 111320.0
KZ = 110574.0
DLAT, DLON = 0.45, 0.58                           # ~50 km each way
URL = ('https://servicios.idee.es/wcs-inspire/mdt?SERVICE=WCS&VERSION=2.0.1&REQUEST=GetCoverage&COVERAGEID=Elevacion4258_200'
       '&SUBSET=lat(%.4f,%.4f)&SUBSET=long(%.4f,%.4f)&FORMAT=application/asc' % (LAT0 - DLAT, LAT0 + DLAT, LON0 - DLON, LON0 + DLON))

OVERPASS = ('[out:json];(nwr["man_made"="windmill"](39.43,-3.64,39.48,-3.58);'
            'nwr["historic"="castle"](39.43,-3.64,39.48,-3.58););out center tags;')

def landmarks():
    cache = os.path.join(HERE, 'ign', 'consuegra_osm.json')
    if not os.path.exists(cache):
        subprocess.run(['curl', '-sS', '-A', 'map-tool/1.0', '--data-urlencode', 'data=' + OVERPASS,
                        'https://overpass-api.de/api/interpreter', '-o', cache], check=True)
    out = []
    for e in json.load(open(cache, encoding='utf-8'))['elements']:
        c = e.get('center', e)
        t = e.get('tags', {})
        kind = 'molino' if t.get('man_made') == 'windmill' else ('castillo' if t.get('historic') == 'castle' and 'man_made' not in t else '')   # (not the Prior's palace tower down in Consuegra)
        if kind:
            out.append([kind, round((c['lon'] - LON0) * KX, 1), round(-(c['lat'] - LAT0) * KZ, 1)])
    return out

def main():
    cache = os.path.join(HERE, 'ign', 'mdt200_ll.asc')
    if not os.path.exists(cache):
        raw = subprocess.run(['curl', '-sS', '-A', 'map-tool/1.0', URL], check=True, capture_output=True).stdout
        open(cache, 'wb').write(raw)
    raw = open(cache, 'rb').read()
    text = raw[raw.index(b'ncols'):].decode('ascii', 'replace').split('\n')
    head = {}
    k = 0
    while text[k].split() and text[k].split()[0][0].isalpha():
        a, b = text[k].split()[:2]; head[a.lower()] = float(b); k += 1
    z = np.loadtxt(io.StringIO('\n'.join(text[k:k + int(head['nrows'])]))).astype('float32')   # row 0 = north
    rows, cols = z.shape
    lon0 = head['xllcorner']; lon1 = lon0 + cols * head['dx']
    lat0 = head['yllcorner']; lat1 = lat0 + rows * head['dy']
    out = {
        'source': 'MDT200 (c) Instituto Geografico Nacional, CC BY 4.0',
        'w': cols, 'h': rows,
        # the game's local metres of the grid's west, north, east and south edges (x east, z south)
        'x0': round((lon0 - LON0) * KX, 1), 'z0': round(-(lat1 - LAT0) * KZ, 1),
        'x1': round((lon1 - LON0) * KX, 1), 'z1': round(-(lat0 - LAT0) * KZ, 1),
        'hitos': landmarks(),
        'hm': base64.b64encode(z.astype('<f2').tobytes()).decode('ascii'),
    }
    path = os.path.join(HERE, '..', 'godot', 'data', 'sierras.json')
    json.dump(out, open(path, 'w', encoding='utf-8', newline='\n'))
    print('sierras.json', z.shape, 'from %.0f to %.0f m' % (z.min(), z.max()), '%.0f KB' % (os.path.getsize(path) / 1024))

if __name__ == '__main__':
    main()
