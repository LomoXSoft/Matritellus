"""The Silo del Tío Anaranjao (the real Silo del Tío Colorao, C. San Agustín 9; the user, 21 November 2026): every
building and part Catastro has in its block, from the town's INSPIRE file, in the game's metres; and a plan of them over
the orthophoto (tools/ign/silo.jpg) with the game's streets, and where the 360 photos of the tour stand (TOUR.json of
tools/silo/tour360.py, if given).

    python tools/silo/manzana.py [OUT.png] [partes=RC,RC] [tour=TOUR.json]
"""
import json, math, os, re, sys, zipfile
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')
sys.path.insert(0, os.path.join(HERE, '..'))
from house_data import utm30_to_local

AREA = (492.0, 284.0, 552.0, 336.0)        # (the rectangle on the map: x0, z0, x1, z1)

zf = zipfile.ZipFile(os.path.join(ROOT, 'tools', 'catastro', 'A.ES.SDGC.BU.45088.zip'))
def read(suffix):
    return zf.read([n for n in zf.namelist() if n.endswith(suffix)][0]).decode('utf-8')

def area(v):
    x, z = v[:, 0], v[:, 1]
    return 0.5 * abs(np.dot(x, np.roll(z, 1)) - np.dot(z, np.roll(x, 1)))

if __name__ == '__main__':
    use, year = {}, {}
    for m in re.finditer(r'<bu-ext2d:Building gml:id="ES\.SDGC\.BU\.([^"]+)">(.*?)</bu-ext2d:Building>', read('.building.gml'), re.S):
        if True:
            u = re.search(r'<bu-ext2d:currentUse>([^<]*)<', m.group(2)); y = re.search(r'<bu-core2d:beginning>(\d{4})', m.group(2))
            use[m.group(1)] = u.group(1) if u else ''; year[m.group(1)] = y.group(1) if y else ''
    parts = []
    for m in re.finditer(r'<bu-ext2d:BuildingPart gml:id="ES\.SDGC\.BU\.([^"]+)">(.*?)</bu-ext2d:BuildingPart>', read('.buildingpart.gml'), re.S):
        fl = re.search(r'numberOfFloorsAboveGround>(\d+)<', m.group(2)); fb = re.search(r'numberOfFloorsBelowGround>(\d+)<', m.group(2))
        for ring in re.findall(r'<gml:exterior>.*?<gml:posList[^>]*>([^<]+)</gml:posList>', m.group(2), re.S):
            v = np.array(ring.split(), dtype=float).reshape(-1, 2)
            x, z = utm30_to_local(v[:, 0], v[:, 1])
            if not (AREA[0] < x.mean() < AREA[2] and AREA[1] < z.mean() < AREA[3]):
                continue
            parts.append((m.group(1), int(fl.group(1)) if fl else 0, int(fb.group(1)) if fb else 0, np.stack([x, z], 1)))
    byrc = {}
    for pid, f, b, v in parts:
        byrc.setdefault(pid[:14], []).append((pid, f, b, v))
    for rc in sorted(byrc):
        tot = sum(area(v) for _, f, _, v in byrc[rc] if f > 0)
        c = np.concatenate([v for _, _, _, v in byrc[rc]]).mean(0)
        print('%s  %-12s %s  %6.0f m2 above  centre (%.1f, %.1f)  parts: %s' % (rc, use.get(rc, ''), year.get(rc, ''), tot, c[0], c[1],
              ', '.join('%s %d/%d %.0f' % (p.split('_')[-1], f, b, area(v)) for p, f, b, v in byrc[rc])))
    want = [a[7:].split(',') for a in sys.argv[1:] if a.startswith('partes=')]
    for pid, f, b, v in parts:
        if want and any(pid.startswith(w) for w in want[0]):
            print(pid, '%d/%d' % (f, b), ' '.join('(%.2f, %.2f)' % (p[0], p[1]) for p in v))
    tour = ([a[5:] for a in sys.argv[1:] if a.startswith('tour=')] or [''])[0]
    sys.argv = [a for a in sys.argv if not a.startswith(('partes=', 'tour='))]
    if len(sys.argv) > 1:
        from PIL import Image, ImageDraw, ImageFont
        allv = np.concatenate([v for _, _, _, v in parts])
        x0, z0 = allv.min(0) - 6.0; x1, z1 = allv.max(0) + 6.0
        k = 16.0
        W, H = int((x1 - x0) * k), int((z1 - z0) * k)
        P = lambda p: ((p[0] - x0) * k, (p[1] - z0) * k)
        im = Image.new('RGB', (W, H), (250, 250, 247))
        ign = os.path.join(ROOT, 'tools', 'ign', 'silo.json')
        if os.path.exists(ign):                    # the orthophoto under it, if fetched
            j = json.load(open(ign)); src = Image.open(ign[:-5] + '.jpg').convert('RGB'); s = 1.0 / j['mpp']
            im = src.transform((W, H), Image.AFFINE, (1 / k * s, 0, (x0 - j['x0']) * s, 0, 1 / k * s, (z0 - j['z0']) * s), resample=Image.BICUBIC)
        d = ImageDraw.Draw(im, 'RGBA')
        f = ImageFont.truetype('arial.ttf', 12)
        m = json.load(open(os.path.join(ROOT, 'godot', 'data', 'map.json'), encoding='utf-8'))
        nodes = m['nodes']
        for r in m['roads']:
            pts = [(nodes[2 * i], nodes[2 * i + 1]) for i in r['p']]
            d.line([P(p) for p in pts], fill=(220, 40, 40, 255), width=2)
        for h in m['houses']:
            for pc in h.get('pieces', []):
                rg = pc.get('ring', [])
                if len(rg) >= 6:
                    q = [P((rg[i], rg[i + 1])) for i in range(0, len(rg), 2)]
                    if all(-50 < a < W + 50 and -50 < b < H + 50 for a, b in q):
                        d.line(q + q[:1], fill=(40, 120, 230, 200), width=1)
            o = h['o']
            if x0 < o[0] < x1 and z0 < o[1] < z1:
                d.text(P(o), h['id'], fill=(20, 60, 160, 255), font=f)
        cols = [(255, 140, 0), (0, 160, 80), (160, 0, 200), (0, 150, 200), (200, 0, 80), (120, 90, 0)]
        for i, rc in enumerate(sorted(byrc)):
            c = cols[i % len(cols)]
            for pid, fl, b, v in byrc[rc]:
                q = [P(p) for p in v]
                d.polygon(q, outline=c + (255,), fill=c + (50,))
            cc = np.concatenate([v for _, _, _, v in byrc[rc]]).mean(0)
            d.text(P(cc), rc[5:7], fill=(0, 0, 0, 255), font=f)
        for gx in range(int(x0 // 5 * 5), int(x1) + 1, 5):
            d.text(P((gx, z0 + 2)), str(gx), fill=(0, 0, 0, 255), font=f)
        for gz in range(int(z0 // 5 * 5), int(z1) + 1, 5):
            d.text(P((x0 + 1, gz)), str(gz), fill=(0, 0, 0, 255), font=f)
        if tour:
            for pid, v in json.load(open(tour)).items():
                x, y = P((v['x'], v['z']))
                d.ellipse([x - 3, y - 3, x + 3, y + 3], fill=(255, 255, 0, 255), outline=(0, 0, 0, 255))
        im.save(sys.argv[1])
        print(sys.argv[1], im.size)
