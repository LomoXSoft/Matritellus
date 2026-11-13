"""Downloads a piece of the official aerial photo of Spain (PNOA máxima actualidad, © Instituto Geográfico Nacional,
CC BY 4.0) for a rectangle given in the game's own metres, so hand-built places can be traced instead of eyeballed.

    python tools/fetch_ortho.py NAME XMIN ZMIN XMAX ZMAX [metres_per_pixel]
      -> tools/ign/NAME.jpg  and  tools/ign/NAME.json  (the rectangle and scale, to map pixels back to metres)

x runs east and z runs south, as everywhere else in the project (see bake_godot.py for the origin).
"""
import json, math, os, sys, urllib.request

LAT0, LON0 = 39.4690, -3.5335
KX = math.cos(math.radians(LAT0)) * 111320.0
KZ = 110574.0
HERE = os.path.dirname(os.path.abspath(__file__))

def fetch(name, x0, z0, x1, z1, mpp=0.25):
    lon0, lon1 = LON0 + x0 / KX, LON0 + x1 / KX
    lat1, lat0 = LAT0 - z0 / KZ, LAT0 - z1 / KZ          # z grows south: z0 is the north edge
    w, h = int(round((x1 - x0) / mpp)), int(round((z1 - z0) / mpp))
    url = ('https://www.ign.es/wms-inspire/pnoa-ma?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&LAYERS=OI.OrthoimageCoverage&STYLES='
           '&CRS=EPSG:4326&BBOX=%.7f,%.7f,%.7f,%.7f&WIDTH=%d&HEIGHT=%d&FORMAT=image/jpeg' % (lat0, lon0, lat1, lon1, w, h))
    out = os.path.join(HERE, 'ign')
    os.makedirs(out, exist_ok=True)
    req = urllib.request.Request(url, headers={'User-Agent': 'map-tool/1.0'})
    data = urllib.request.urlopen(req, timeout=90).read()
    if data[:2] != b'\xff\xd8':
        raise SystemExit('not an image: ' + data[:300].decode('utf8', 'replace'))
    open(os.path.join(out, name + '.jpg'), 'wb').write(data)
    json.dump({'x0': x0, 'z0': z0, 'x1': x1, 'z1': z1, 'mpp': mpp, 'source': 'PNOA © Instituto Geográfico Nacional, CC BY 4.0'},
              open(os.path.join(out, name + '.json'), 'w'))
    print(name, w, 'x', h, 'px,', len(data) // 1024, 'KB')

if __name__ == '__main__':
    a = sys.argv
    fetch(a[1], float(a[2]), float(a[3]), float(a[4]), float(a[5]), float(a[6]) if len(a) > 6 else 0.25)
