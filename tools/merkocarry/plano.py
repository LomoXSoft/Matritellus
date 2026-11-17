"""The Merkocarry from above: the orthophoto (tools/ign/merkocarry.jpg, PNOA) at a good scale with a grid of the map's
metres (x east, z south; yellow every 5 m), Catastro's outline of the shop (the union of its parts, magenta), the
outline merkocarry.gd builds on (`BUILT` below, cyan, if given), the game's streets (red) and its houses (blue).

    python tools/merkocarry/plano.py OUT.jpg [x0,z0,x1,z1] [px_per_m]
Prints the union's corners.
"""
import json, math, os, re, sys, zipfile
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from shapely.geometry import Polygon
from shapely.ops import unary_union

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.environ.get('MATRITELLUS', os.path.join(HERE, '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
sys.path.insert(0, HERE)
from house_data import utm30_to_local
from comun import game_map

def parts(prefix):
    zf = zipfile.ZipFile(os.path.join(ROOT, 'tools', 'catastro', 'A.ES.SDGC.BU.45088.zip'))
    gml = zf.read([n for n in zf.namelist() if n.endswith('.buildingpart.gml')][0]).decode('utf-8')
    out = []
    for m in re.finditer(r'<bu-ext2d:BuildingPart gml:id="ES\.SDGC\.BU\.([^"]+)">(.*?)</bu-ext2d:BuildingPart>', gml, re.S):
        if m.group(1).startswith(prefix):
            for ring in re.findall(r'<gml:exterior>.*?<gml:posList[^>]*>([^<]+)</gml:posList>', m.group(2), re.S):
                v = np.array(ring.split(), dtype=float).reshape(-1, 2)
                x, z = utm30_to_local(v[:, 0], v[:, 1])
                out.append(Polygon(list(zip(x, z))))
    return out

if __name__ == '__main__':
    out = sys.argv[1]
    x0, z0, x1, z1 = tuple(map(float, sys.argv[2].split(','))) if len(sys.argv) > 2 else (390.0, 145.0, 475.0, 265.0)
    k = float(sys.argv[3]) if len(sys.argv) > 3 else 9.0
    shop = unary_union([p.buffer(0.05) for p in parts('4790703')]).buffer(-0.05)
    shop = shop.simplify(0.15)
    print('shop: %.0f m2' % shop.area)
    for g in (shop.geoms if shop.geom_type == 'MultiPolygon' else [shop]):
        print(' '.join('(%.2f, %.2f)' % c for c in g.exterior.coords))
    j = json.load(open(os.path.join(ROOT, 'tools', 'ign', 'merkocarry.json')))
    src = Image.open(os.path.join(ROOT, 'tools', 'ign', 'merkocarry.jpg')).convert('RGB')
    s = 1.0 / j['mpp']
    W, H = int((x1 - x0) * k), int((z1 - z0) * k)
    im = src.transform((W, H), Image.AFFINE, (1 / k * s, 0, (x0 - j['x0']) * s, 0, 1 / k * s, (z0 - j['z0']) * s), resample=Image.BICUBIC)
    d = ImageDraw.Draw(im, 'RGBA')
    f = ImageFont.truetype('arial.ttf', 12)
    P = lambda p: ((p[0] - x0) * k, (p[1] - z0) * k)
    for gx in range(int(math.ceil(x0)), int(x1) + 1):
        if k >= 15 and gx % 5:
            d.line([P((gx, z0)), P((gx, z1))], fill=(255, 255, 255, 70), width=1)
        if gx % 5 == 0:
            d.line([P((gx, z0)), P((gx, z1))], fill=(255, 255, 0, 110) if gx % 10 else (255, 255, 0, 200), width=1)
            if gx % 10 == 0:
                d.text((P((gx, z0))[0] + 2, 2), str(gx), fill=(255, 255, 0, 255), font=f)
    for gz in range(int(math.ceil(z0)), int(z1) + 1):
        if k >= 15 and gz % 5:
            d.line([P((x0, gz)), P((x1, gz))], fill=(255, 255, 255, 70), width=1)
        if gz % 5 == 0:
            d.line([P((x0, gz)), P((x1, gz))], fill=(255, 255, 0, 110) if gz % 10 else (255, 255, 0, 200), width=1)
            if gz % 10 == 0:
                d.text((2, P((x0, gz))[1] + 2), str(gz), fill=(255, 255, 0, 255), font=f)
    m = game_map()
    nodes = m['nodes']
    for r in m['roads']:
        pts = [(nodes[2 * i], nodes[2 * i + 1]) for i in r['p']]
        d.line([P(p) for p in pts], fill=(255, 40, 40, 255), width=2)
        hw = r.get('w', 6) / 2.0
        for p, q in zip(pts, pts[1:]):
            L = math.dist(p, q)
            if L > 0.01:
                n = (-(q[1] - p[1]) / L * hw, (q[0] - p[0]) / L * hw)
                for sg in (1, -1):
                    d.line([P((p[0] + sg * n[0], p[1] + sg * n[1])), P((q[0] + sg * n[0], q[1] + sg * n[1]))], fill=(255, 120, 120, 160), width=1)
    for g in (shop.geoms if shop.geom_type == 'MultiPolygon' else [shop]):
        d.line([P(c) for c in g.exterior.coords], fill=(255, 0, 255, 255), width=2)
    try:
        from merkocarry_plan import BUILT
        for poly in BUILT:
            q = [P(c) for c in poly]
            d.line(q + q[:1], fill=(0, 255, 255, 255), width=2)
    except ImportError:
        pass
    im.save(out, quality=90)
    print(out, im.size)
