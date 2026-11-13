"""Gathers what is publicly known about one house, to build it by hand: its Catastro record (year, use, surfaces), the
footprint of each of its parts in the game's metres, which of its walls give on to a street, the level of the ground,
the official aerial photo with the footprint drawn on it, and Catastro's own photo of the front where there is one.

    python tools/house_data.py CL ALEMANIA 7            (as tools/locate.py: CL calle, AV avenida, PZ plaza...)
    python tools/house_data.py 4294305VJ5649S           (or straight from the cadastral reference)

Writes tools/casas/<reference>/: datos.json, aerea.jpg (+ aerea_plano.png with the parts and their walls numbered) and
fachada.jpg. Prints a summary.
"""
import io, json, math, os, re, sys, urllib.parse, urllib.request, zipfile
import numpy as np
from shapely.geometry import Polygon, LineString, Point
from shapely.geometry.polygon import orient

HERE = os.path.dirname(os.path.abspath(__file__))
LAT0, LON0 = 39.4690, -3.5335
KX = math.cos(math.radians(LAT0)) * 111320.0
KZ = 110574.0
UA = {'User-Agent': 'map-tool/1.0'}
OVC = 'https://ovc.catastro.meh.es/ovcservweb/OVCSWLocalizacionRC/'

def get(url, binary=False):
    data = urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=90).read()
    return data if binary else data.decode('utf8', 'replace')

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

def reference(args):
    if len(args) == 1:
        return args[0][:14]
    xml = get(OVC + 'OVCCallejero.asmx/Consulta_DNPLOC?' + urllib.parse.urlencode(dict(Provincia='TOLEDO', Municipio='MADRIDEJOS', Sigla=args[0],
              Calle=' '.join(args[1:-1]), Numero=args[-1], Bloque='', Escalera='', Planta='', Puerta='')))
    m = re.search(r'<pc1>([^<]*)</pc1>\s*<pc2>([^<]*)</pc2>', xml)
    if not m:
        sys.exit('Catastro does not know that address: ' + re.sub(r'\s+', ' ', xml)[:300])
    return m.group(1) + m.group(2)

def record(rc):
    """what Catastro says of the property: address, use, year, surfaces, and each built unit"""
    xml = get(OVC + 'OVCCallejero.asmx/Consulta_DNPRC?' + urllib.parse.urlencode(dict(Provincia='', Municipio='', RC=rc)))
    def one(tag):
        m = re.search(r'<%s>([^<]*)</%s>' % (tag, tag), xml)
        return m.group(1).strip() if m else ''
    units = []
    for u in re.findall(r'<cons>(.*?)</cons>', xml, re.S):
        g = lambda tag: (re.search(r'<%s>([^<]*)</%s>' % (tag, tag), u) or [None, ''])[1]
        units.append({'use': g('lcd'), 'floor': g('pt'), 'door': g('pu'), 'm2': g('stl')})
    return {'address': one('ldt'), 'use': one('luso'), 'built_m2': one('sfc'), 'year': one('ant'), 'units': units, 'properties': len(re.findall(r'<rc>', xml))}

def parts_of(rc):
    zf = zipfile.ZipFile(os.path.join(HERE, 'catastro', 'A.ES.SDGC.BU.45088.zip'))
    gml = zf.read([n for n in zf.namelist() if n.endswith('.buildingpart.gml')][0]).decode('utf8')
    out = []
    for m in re.finditer(r'<bu-ext2d:BuildingPart gml:id="ES\.SDGC\.BU\.(%s[^"]*)">(.*?)</bu-ext2d:BuildingPart>' % rc, gml, re.S):
        up = re.search(r'numberOfFloorsAboveGround>(\d+)<', m.group(2)); down = re.search(r'numberOfFloorsBelowGround>(\d+)<', m.group(2))
        for ring in re.findall(r'<gml:exterior>.*?<gml:posList[^>]*>([^<]+)</gml:posList>', m.group(2), re.S):
            v = np.array(ring.split(), dtype=float).reshape(-1, 2)
            x, z = utm30_to_local(v[:, 0], v[:, 1])
            p = orient(Polygon(np.column_stack([x, z])).buffer(0), 1.0)
            out.append({'id': m.group(1), 'floors': int(up.group(1)) if up else 0, 'below': int(down.group(1)) if down else 0, 'poly': p})
    return out

def main():
    fast = '--fast' in sys.argv                    # (no aerial photo: for doing a whole street at once)
    if fast: sys.argv.remove('--fast')
    rc = reference(sys.argv[1:])
    out_dir = os.path.join(HERE, 'casas', rc)
    os.makedirs(out_dir, exist_ok=True)
    rec = record(rc)
    parts = parts_of(rc)
    game = json.load(open(os.path.join(HERE, '..', 'godot', 'data', 'map.json'), encoding='utf8'))
    N = game['nodes']
    roads = [(r['n'], r['w'], LineString([(N[i * 2], N[i * 2 + 1]) for i in r['p']])) for r in game['roads'] if len(r['p']) > 1]
    rel = game['relief']
    RH = np.array(rel['h'], dtype=float).reshape(rel['nz'], rel['nx']) / 100.0
    def ground(x, z):
        fx, fz = (x - rel['x0']) / rel['g'], (z - rel['z0']) / rel['g']
        ix, iz = int(np.clip(fx, 0, rel['nx'] - 2)), int(np.clip(fz, 0, rel['nz'] - 2))
        tx, tz = fx - ix, fz - iz
        return float(RH[iz, ix] * (1 - tx) * (1 - tz) + RH[iz, ix + 1] * tx * (1 - tz) + RH[iz + 1, ix] * (1 - tx) * tz + RH[iz + 1, ix + 1] * tx * tz)
    print('%s  |  %s  |  %s, built %s, %s m2 built, %d units' % (rc, rec['address'], rec['use'], rec['year'], rec['built_m2'], len(rec['units'])))
    for u in rec['units']:
        print('   unit: %-22s floor %-3s %s m2' % (u['use'], u['floor'], u['m2']))
    data = {'rc': rc, 'record': rec, 'parts': []}
    allp = None
    for p in parts:
        g = p['poly']
        allp = g if allp is None else allp.union(g)
        ring = [(round(x, 2), round(z, 2)) for x, z in list(g.exterior.coords)[:-1]]
        walls = []
        for k in range(len(ring)):
            a, b = ring[k], ring[(k + 1) % len(ring)]
            ln = math.dist(a, b)
            if ln < 0.3: continue
            mx, mz = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
            nx, nz = (b[1] - a[1]) / ln, -(b[0] - a[0]) / ln             # outwards (the ring is counter-clockwise)
            probe = Point(mx + nx * 2.5, mz + nz * 2.5)
            name, width, line = min(roads, key=lambda r: r[2].distance(probe))
            d = line.distance(probe)
            walls.append({'a': a, 'b': b, 'len': round(ln, 2), 'out': (round(nx, 3), round(nz, 3)), 'street': name if d < width / 2 + 5 else '', 'to_centre': round(line.distance(Point(mx, mz)), 2)})
        gs = [ground(x, z) for x, z in ring]
        data['parts'].append({'id': p['id'], 'floors': p['floors'], 'below': p['below'], 'area': round(g.area, 1), 'ring': ring, 'walls': walls, 'ground': [round(min(gs), 2), round(max(gs), 2)]})
        print(' part %-24s floors %d (+%d below)  %5.1f m2  ground %.2f..%.2f' % (p['id'], p['floors'], p['below'], g.area, min(gs), max(gs)))
        for i, w in enumerate(walls):
            if w['street']:
                print('     wall %d: %5.2f m on %s, %.2f m from its centre line, from %s to %s' % (i, w['len'], w['street'], w['to_centre'], w['a'], w['b']))
    if allp is None:
        sys.exit('no building parts with that reference in the Catastro file')
    # the aerial photo, and the same with the parts drawn on it
    x0, z0, x1, z1 = allp.bounds
    pad, mpp = 9.0, 0.08
    x0, z0, x1, z1 = x0 - pad, z0 - pad, x1 + pad, z1 + pad
    w, h = int(round((x1 - x0) / mpp)), int(round((z1 - z0) / mpp))
    url = ('https://www.ign.es/wms-inspire/pnoa-ma?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&LAYERS=OI.OrthoimageCoverage&STYLES='
           '&CRS=EPSG:4326&BBOX=%.7f,%.7f,%.7f,%.7f&WIDTH=%d&HEIGHT=%d&FORMAT=image/jpeg' % (LAT0 - z1 / KZ, LON0 + x0 / KX, LAT0 - z0 / KZ, LON0 + x1 / KX, w, h))
    try:
        if fast: raise RuntimeError('skipped (--fast)')
        open(os.path.join(out_dir, 'aerea.jpg'), 'wb').write(get(url, True))
        from PIL import Image, ImageDraw
        im = Image.open(os.path.join(out_dir, 'aerea.jpg')).convert('RGB')
        d = ImageDraw.Draw(im)
        px = lambda q: ((q[0] - x0) / mpp, (q[1] - z0) / mpp)
        for i, p in enumerate(data['parts']):
            col = [(255, 220, 0), (0, 230, 255), (255, 90, 200), (120, 255, 120)][i % 4]
            pts = [px(q) for q in p['ring']]
            d.line(pts + [pts[0]], fill=col, width=2)
            c = Polygon(p['ring']).representative_point()
            d.text(px((c.x, c.y)), '%s\n%d fl' % (p['id'][15:], p['floors']), fill=col)
            for k, wl in enumerate(p['walls']):
                if wl['street']:
                    m = px(((wl['a'][0] + wl['b'][0]) / 2 + wl['out'][0] * 1.2, (wl['a'][1] + wl['b'][1]) / 2 + wl['out'][1] * 1.2))
                    d.text(m, str(k), fill=(255, 255, 255))
        for gx in range(int(math.ceil(x0 / 5) * 5), int(x1) + 1, 5):
            d.line([px((gx, z0)), px((gx, z1))], fill=(255, 255, 255, 60), width=1); d.text(px((gx + 0.2, z0 + 0.2)), str(gx), fill=(255, 255, 255))
        for gz in range(int(math.ceil(z0 / 5) * 5), int(z1) + 1, 5):
            d.line([px((x0, gz)), px((x1, gz))], fill=(255, 255, 255, 60), width=1); d.text(px((x0 + 0.2, gz + 0.2)), str(gz), fill=(255, 255, 255))
        im.save(os.path.join(out_dir, 'aerea_plano.png'))
        data['aerial'] = {'x0': x0, 'z0': z0, 'mpp': mpp, 'credit': 'PNOA, (c) Instituto Geografico Nacional, CC BY 4.0'}
        print(' aerial photo %d x %d px at %.2f m/px' % (w, h, mpp))
    except Exception as e:
        print(' no aerial photo:', e)
    # Catastro's own photo of the front (not every property has one)
    try:
        jpg = get('https://ovc.catastro.meh.es/OVCServWeb/OVCWcfLibres/OVCFotoFachada.svc/RecuperarFotoFachadaGet?ReferenciaCatastral=' + rc, True)
        if jpg[:2] == b'\xff\xd8' and len(jpg) > 4000:
            open(os.path.join(out_dir, 'fachada.jpg'), 'wb').write(jpg)
            print(' Catastro photo of the front: %d kB' % (len(jpg) // 1024))
        else:
            print(' Catastro has no photo of the front (%d bytes came back)' % len(jpg))
    except Exception as e:
        print(' no Catastro photo of the front:', e)
    json.dump(data, open(os.path.join(out_dir, 'datos.json'), 'w', encoding='utf8'), ensure_ascii=False, indent=1)
    print(' ->', out_dir)

if __name__ == '__main__':
    main()
