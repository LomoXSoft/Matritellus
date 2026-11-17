"""The fairground and market ("Recinto ferial y mercadillo"; the user, 17 November 2026) from above: the orthophoto
(tools/ign/ferial.jpg, PNOA) at a good scale with a grid of the map's metres (x east, z south; yellow every 5 m, numbers
every 10), the game's streets (centre red, edges pink), its areas (green) and houses (blue), and the points given.

    python tools/ferial/plano.py OUT.jpg [x0,z0,x1,z1] [px_per_m] [x,z;x,z;...]
"""
import json, math, os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')

if __name__ == '__main__':
    out = sys.argv[1]
    x0, z0, x1, z1 = tuple(map(float, sys.argv[2].split(','))) if len(sys.argv) > 2 else (0.0, 540.0, 240.0, 770.0)
    k = float(sys.argv[3]) if len(sys.argv) > 3 else 6.0
    marks = [tuple(map(float, q.split(','))) for q in sys.argv[4].split(';')] if len(sys.argv) > 4 and sys.argv[4] else []
    j = json.load(open(os.path.join(ROOT, 'tools', 'ign', 'ferial.json')))
    src = Image.open(os.path.join(ROOT, 'tools', 'ign', 'ferial.jpg')).convert('RGB')
    s = 1.0 / j['mpp']
    W, H = int((x1 - x0) * k), int((z1 - z0) * k)
    im = src.transform((W, H), Image.AFFINE, (1 / k * s, 0, (x0 - j['x0']) * s, 0, 1 / k * s, (z0 - j['z0']) * s), resample=Image.BICUBIC)
    d = ImageDraw.Draw(im, 'RGBA')
    f = ImageFont.truetype('arial.ttf', 12)
    P = lambda p: ((p[0] - x0) * k, (p[1] - z0) * k)
    for gx in range(int(math.ceil(x0)), int(x1) + 1):
        if gx % 5 == 0:
            d.line([P((gx, z0)), P((gx, z1))], fill=(255, 255, 0, 200 if gx % 10 == 0 else 90), width=1)
            if gx % 10 == 0:
                d.text((P((gx, z0))[0] + 2, 2), str(gx), fill=(255, 255, 0, 255), font=f)
    for gz in range(int(math.ceil(z0)), int(z1) + 1):
        if gz % 5 == 0:
            d.line([P((x0, gz)), P((x1, gz))], fill=(255, 255, 0, 200 if gz % 10 == 0 else 90), width=1)
            if gz % 10 == 0:
                d.text((2, P((x0, gz))[1] + 2), str(gz), fill=(255, 255, 0, 255), font=f)
    m = json.load(open(os.path.join(ROOT, 'godot', 'data', 'map.json'), encoding='utf-8'))
    nodes = m['nodes']
    for a in m['areas']:
        p = a['p']
        q = [P((p[i], p[i + 1])) for i in range(0, len(p), 2)]
        if len(q) > 2:
            d.line(q + q[:1], fill=(60, 220, 60, 200), width=1)
    for r in m['roads']:
        pts = [(nodes[2 * i], nodes[2 * i + 1]) for i in r['p']]
        d.line([P(p) for p in pts], fill=(255, 40, 40, 255), width=2)
        hw = r.get('w', 6) / 2.0
        for p, q in zip(pts, pts[1:]):
            L = math.dist(p, q)
            if L > 0.01:
                n = (-(q[1] - p[1]) / L * hw, (q[0] - p[0]) / L * hw)
                for sg in (1, -1):
                    d.line([P((p[0] + sg * n[0], p[1] + sg * n[1])), P((q[0] + sg * n[0], q[1] + sg * n[1]))], fill=(255, 140, 140, 160), width=1)
        for i in r['p']:
            c = P((nodes[2 * i], nodes[2 * i + 1]))
            d.ellipse([c[0] - 2, c[1] - 2, c[0] + 2, c[1] + 2], fill=(255, 40, 40, 255))
    for h in m['houses']:
        for pc in h.get('pieces', []):
            rg = pc.get('ring', [])
            if len(rg) >= 6:
                q = [P((rg[i], rg[i + 1])) for i in range(0, len(rg), 2)]
                if all(-50 < a < W + 50 and -50 < b < H + 50 for a, b in q):
                    d.line(q + q[:1], fill=(60, 120, 255, 180), width=1)
    for c in marks:
        p = P(c)
        d.ellipse([p[0] - 4, p[1] - 4, p[0] + 4, p[1] + 4], outline=(0, 255, 255, 255), width=2)
    im.save(out, quality=90)
    print(out, im.size)
