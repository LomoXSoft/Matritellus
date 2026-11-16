"""The orthophoto round the MasAhorro turned into the place's own frame (as masahorro.gd): the front runs left-right
along the top of its car park, north up, east to the right (it is a view from above, not a mirror), with a grid of
1 m (lines every 5 m labelled in x along the front from its north-east corner, z out of it), and the game's streets over it.

    python tools/masahorro/marco.py OUT.jpg [x0,z0,x1,z1] [px_per_m]       (frame metres; default the whole place)
"""
import json, math, os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')
sys.path.insert(0, HERE)
from plano import O, U, N, spot

if __name__ == '__main__':
    out = sys.argv[1]
    x0, z0, x1, z1 = tuple(map(float, sys.argv[2].split(','))) if len(sys.argv) > 2 else (-12.0, -64.0, 42.0, 82.0)
    k = float(sys.argv[3]) if len(sys.argv) > 3 else 10.0
    j = json.load(open(os.path.join(HERE, '..', 'ign', 'masahorro.json')))
    src = Image.open(os.path.join(HERE, '..', 'ign', 'masahorro.jpg')).convert('RGB')
    s = 1.0 / j['mpp']
    W, H = int((x1 - x0) * k), int((z1 - z0) * k)
    # pixel (i, j): x = x1 - i / k (x grows to the left: east is on the right), z = z1 - j / k (out of the front is up)
    # map point = O + U x + N z ; source pixel = (p - (x0, z0)_photo) * s
    a = (-U[0] / k * s, -N[0] / k * s, (O[0] + U[0] * x1 + N[0] * z1 - j['x0']) * s)
    b = (-U[1] / k * s, -N[1] / k * s, (O[1] + U[1] * x1 + N[1] * z1 - j['z0']) * s)
    im = src.transform((W, H), Image.AFFINE, a + b, resample=Image.BICUBIC)
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype('arial.ttf', 13)
    P = lambda x, z: ((x1 - x) * k, (z1 - z) * k)
    for x in range(int(math.ceil(x0)), int(x1) + 1):
        c = (255, 255, 0) if x % 5 == 0 else (255, 255, 255)
        if x % 5 == 0 or k >= 15:
            d.line([P(x, z0), P(x, z1)], fill=c, width=1)
        if x % 5 == 0:
            d.text((P(x, z1)[0] + 2, 2), str(x), fill=c, font=f)
    for z in range(int(math.ceil(z0)), int(z1) + 1):
        c = (255, 255, 0) if z % 5 == 0 else (255, 255, 255)
        if z % 5 == 0 or k >= 15:
            d.line([P(x0, z), P(x1, z)], fill=c, width=1)
        if z % 5 == 0:
            d.text((2, P(x0, z)[1] + 2), str(z), fill=c, font=f)
    # the game's streets (centre lines and edges), in the frame
    m = json.load(open(os.path.join(ROOT, 'godot', 'data', 'map.json'), encoding='utf-8'))
    nodes = m['nodes']
    def fr(p):
        r = (p[0] - O[0], p[1] - O[1])
        return (r[0] * U[0] + r[1] * U[1], r[0] * N[0] + r[1] * N[1])
    for r in m['roads']:
        pts = [fr((nodes[2 * i], nodes[2 * i + 1])) for i in r['p']]
        hw = r.get('w', 6) / 2.0
        col = (255, 60, 60) if r.get('k', 0) == 0 else (60, 160, 255)
        d.line([P(*p) for p in pts], fill=col, width=1)
        for p, q in zip(pts, pts[1:]):
            L = math.dist(p, q)
            if L < 0.01:
                continue
            n = (-(q[1] - p[1]) / L * hw, (q[0] - p[0]) / L * hw)
            for sg in (1, -1):
                d.line([P(p[0] + sg * n[0], p[1] + sg * n[1]), P(q[0] + sg * n[0], q[1] + sg * n[1])], fill=col, width=1)
    im.save(out, quality=90)
    print(out, im.size)
