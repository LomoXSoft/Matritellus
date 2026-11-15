"""A plan of the old bridge's stretch of the Arroyuelo Medio in the bridge's own frame (x across the bed to the right,
z along it downwards: the Calle del Santo at the top, the crossroads at the bottom), over an aerial photograph, with
what the game has there (blocks, hand-built fronts, street centre lines) and, if given, a design drawn on top.

    python tools/puente/plano.py AERIAL(no extension, in tools/ign) OUT.jpg [design.json] [--box x0 z0 x1 z1] [--ppm 20]

design.json: {"polys": [{"pts": [[x, z], ...], "col": [r, g, b], "w": 2}], "marks": [{"at": [x, z], "text": "..."}]}
"""
import json, math, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
O = (-149.45, -261.31)
U = (0.443, 0.896)
A = (0.896, -0.443)

args = sys.argv[1:]
box = (-18.0, -60.0, 18.0, 30.0)
ppm = 20.0
if '--box' in args:
    i = args.index('--box'); box = tuple(float(v) for v in args[i + 1:i + 5]); del args[i:i + 5]
if '--ppm' in args:
    i = args.index('--ppm'); ppm = float(args[i + 1]); del args[i:i + 2]
src, out = args[0], args[1]
design = json.load(open(args[2], encoding='utf8')) if len(args) > 2 else {}
meta = json.load(open(src + '.json'))
im = np.asarray(Image.open(src + '.jpg').convert('RGB'))
W, H = int((box[2] - box[0]) * ppm), int((box[3] - box[1]) * ppm)
fx = box[0] + (np.arange(W) + 0.5) / ppm
fz = box[1] + (np.arange(H) + 0.5) / ppm
FX, FZ = np.meshgrid(fx, fz)
MX = O[0] + A[0] * FX + U[0] * FZ
MZ = O[1] + A[1] * FX + U[1] * FZ
px = np.clip(((MX - meta['x0']) / meta['mpp']).astype(int), 0, im.shape[1] - 1)
py = np.clip(((MZ - meta['z0']) / meta['mpp']).astype(int), 0, im.shape[0] - 1)
pic = Image.fromarray(im[py, px])
d = ImageDraw.Draw(pic)
try:
    font = ImageFont.truetype('arial.ttf', 12)
except Exception:
    font = ImageFont.load_default()


def local(wx, wz):
    dx, dz = wx - O[0], wz - O[1]
    return dx * A[0] + dz * A[1], dx * U[0] + dz * U[1]


def P(x, z):
    return ((x - box[0]) * ppm, (z - box[1]) * ppm)


for v in range(int(math.ceil(box[0] / 2)) * 2, int(box[2]) + 1, 2):
    d.line([P(v, box[1]), P(v, box[3])], fill=(255, 255, 0) if v % 10 == 0 else (120, 120, 60), width=1)
    d.text((P(v, box[1])[0] + 2, 2), str(v), fill=(255, 255, 0), font=font)
for v in range(int(math.ceil(box[1] / 2)) * 2, int(box[3]) + 1, 2):
    d.line([P(box[0], v), P(box[2], v)], fill=(255, 255, 0) if v % 10 == 0 else (120, 120, 60), width=1)
    d.text((2, P(0, v)[1] + 1), str(v), fill=(255, 255, 0), font=font)
m = json.load(open(os.path.join(HERE, '..', '..', 'godot', 'data', 'map.json'), encoding='utf8'))
for o in m['outlines']:
    pts = [local(o[i], o[i + 1]) for i in range(0, len(o), 2)]
    if any(box[0] - 5 < x < box[2] + 5 and box[1] - 5 < z < box[3] + 5 for x, z in pts):
        d.line([P(*q) for q in pts + pts[:1]], fill=(255, 60, 60), width=2)
for h in m.get('houses', []):
    a = local(*h['o']); b = local(h['o'][0] + h['u'][0] * h['len'], h['o'][1] + h['u'][1] * h['len'])
    if box[0] - 5 < a[0] < box[2] + 5 and box[1] - 5 < a[1] < box[3] + 5:
        d.line([P(*a), P(*b)], fill=(80, 255, 80), width=3)
        d.text(P((a[0] + b[0]) / 2 + 0.3, (a[1] + b[1]) / 2), h['id'], fill=(80, 255, 80), font=font)
N = m['nodes']
for r in m['roads']:
    pts = [local(N[2 * i], N[2 * i + 1]) for i in r['p']]
    if any(box[0] - 20 < x < box[2] + 20 and box[1] - 20 < z < box[3] + 20 for x, z in pts):
        d.line([P(*q) for q in pts], fill=(80, 200, 255), width=1)
for poly in design.get('polys', []):
    pts = [P(*q) for q in poly['pts']]
    d.line(pts + (pts[:1] if poly.get('closed', True) else []), fill=tuple(poly.get('col', (255, 255, 255))), width=poly.get('w', 2))
for mk in design.get('marks', []):
    q = P(*mk['at'])
    d.ellipse([q[0] - 3, q[1] - 3, q[0] + 3, q[1] + 3], outline=(255, 255, 255))
    d.text((q[0] + 5, q[1] - 6), mk.get('text', ''), fill=(255, 255, 255), font=font)
pic.save(out, quality=90)
print(out, pic.size)
