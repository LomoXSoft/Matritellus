"""The orthophoto round the MasAhorro (tools/ign/masahorro.jpg) with the game's map drawn over it: the streets (centre
line and edges), the outlines of the buildings, and optionally points and polygons of the place's own frame, to see
how far the photo and the map agree and where what is built stands.

    python tools/masahorro/plano.py OUT.jpg [x0,z0,x1,z1] [scale]
"""
import json, math, os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')
IGN = os.path.join(HERE, '..', 'ign')

# the place's frame (as masahorro.gd): origin at the north-east corner of the shop, x along the front to the north-west
O = (55.3, 517.0)         # (Catastro's corner is 53.45, 518.01: the shop stands about 1.5 m nearer the Noria and 1 m north)
U = (-0.94735, -0.32034)
N = (-U[1], U[0])         # out of the front (north)


def spot(x, z):
    return (O[0] + U[0] * x + N[0] * z, O[1] + U[1] * x + N[1] * z)


EXTRA = []                # polygons in the frame: (points, colour)

if __name__ == '__main__':
    out = sys.argv[1]
    box = tuple(map(float, sys.argv[2].split(','))) if len(sys.argv) > 2 else (-20.0, 420.0, 110.0, 600.0)
    k = float(sys.argv[3]) if len(sys.argv) > 3 else 6.0
    j = json.load(open(os.path.join(IGN, 'masahorro.json')))
    im = Image.open(os.path.join(IGN, 'masahorro.jpg')).convert('RGB')
    s = 1.0 / j['mpp']
    x0, z0, x1, z1 = box
    im = im.crop((int((x0 - j['x0']) * s), int((z0 - j['z0']) * s), int((x1 - j['x0']) * s), int((z1 - j['z0']) * s)))
    im = im.resize((int((x1 - x0) * k), int((z1 - z0) * k)))
    d = ImageDraw.Draw(im)
    P = lambda p: ((p[0] - x0) * k, (p[1] - z0) * k)
    m = json.load(open(os.path.join(ROOT, 'godot', 'data', 'map.json'), encoding='utf-8'))
    nodes = m['nodes']
    for r in m['roads']:
        pts = [(nodes[2 * i], nodes[2 * i + 1]) for i in r['p']]
        hw = r.get('w', 6) / 2.0
        col = (255, 60, 60) if r.get('k', 0) == 0 else (60, 160, 255)
        d.line([P(p) for p in pts], fill=col, width=2)
        for a, b in zip(pts, pts[1:]):
            L = math.dist(a, b)
            if L < 0.01:
                continue
            n = (-(b[1] - a[1]) / L * hw, (b[0] - a[0]) / L * hw)
            for sg in (1, -1):
                d.line([P((a[0] + sg * n[0], a[1] + sg * n[1])), P((b[0] + sg * n[0], b[1] + sg * n[1]))], fill=col, width=1)
    for o in m['outlines']:
        pts = list(zip(o[0::2], o[1::2]))
        d.line([P(p) for p in pts + pts[:1]], fill=(255, 255, 0), width=1)
    for pts, col in EXTRA:
        q = [P(spot(*p)) for p in pts]
        d.line(q + q[:1], fill=col, width=2)
    f = ImageFont.truetype('arial.ttf', 14)
    for x in range(int(x0 // 10 * 10), int(x1) + 1, 10):
        d.text(((x - x0) * k + 2, 2), str(x), fill=(255, 255, 255), font=f)
    for z in range(int(z0 // 10 * 10), int(z1) + 1, 10):
        d.text((2, (z - z0) * k + 2), str(z), fill=(255, 255, 255), font=f)
    im.save(out, quality=88)
    print(out, im.size)
