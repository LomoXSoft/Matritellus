"""The aerial photo turned into the square's own frame (u along the town hall's front, n out into the square), with a
grid in metres and, optionally, outlines drawn on it.
    python tools/plaza/aerea_marco.py u0 n0 u1 n1 px_per_m out.jpg [outlines.json] [--src plaza_wmts] [--step S]
(--src: which picture of tools/ign/ to use; another year's, fetched with historico.py, for instance)
outlines.json: {"name": {"pts": [[u, n], ...], "col": [r, g, b], "closed": true}, ...}"""
import json, sys, os
import numpy as np
from PIL import Image, ImageDraw, ImageFont
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import marco_p as marco
a = []; src = 'plaza_wmts'; step = 0.0
_i = 1
while _i < len(sys.argv):
    if sys.argv[_i] == '--src': src = sys.argv[_i + 1]; _i += 2
    elif sys.argv[_i] == '--step': step = float(sys.argv[_i + 1]); _i += 2
    else: a.append(sys.argv[_i]); _i += 1
u0, n0, u1, n1, ppm = map(float, a[0:5]); out = a[5]
IGN = os.path.join(HERE, '..', 'ign')          # where the aerial photographs are kept (tools/ign/<src>.jpg and .json)
J = json.load(open(os.path.join(IGN, src + '.json'))); A = np.asarray(Image.open(os.path.join(IGN, src + '.jpg')).convert('RGB')).astype(np.float32)
w, h = int((u1 - u0) * ppm), int((n1 - n0) * ppm)
lu = u0 + (np.arange(w) + 0.5) / ppm; ln = n0 + (np.arange(h) + 0.5) / ppm
LU, LN = np.meshgrid(lu, ln)
MX = marco.M[0] + marco.U[0] * LU + marco.N[0] * LN; MZ = marco.M[1] + marco.U[1] * LU + marco.N[1] * LN
PX = (MX - J['x0']) / J['mpp'] - 0.5; PY = (MZ - J['z0']) / J['mpp'] - 0.5
i0 = np.clip(np.floor(PX).astype(int), 0, A.shape[1] - 2); j0 = np.clip(np.floor(PY).astype(int), 0, A.shape[0] - 2)
fx = np.clip(PX - i0, 0, 1)[..., None]; fy = np.clip(PY - j0, 0, 1)[..., None]
img = A[j0, i0] * (1 - fx) * (1 - fy) + A[j0, i0 + 1] * fx * (1 - fy) + A[j0 + 1, i0] * (1 - fx) * fy + A[j0 + 1, i0 + 1] * fx * fy
im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)); d = ImageDraw.Draw(im)
try: font = ImageFont.truetype('arial.ttf', 12)
except Exception: font = ImageFont.load_default()
px = lambda q: ((q[0] - u0) * ppm, (q[1] - n0) * ppm)
if len(a) > 6:
    for name, o in json.load(open(a[6])).items():
        pts = [px(q) for q in o['pts']]
        if o.get('closed', True): pts = pts + [pts[0]]
        d.line(pts, fill=tuple(o.get('col', [255, 255, 0])), width=2)
        d.text((pts[0][0] + 3, pts[0][1] + 3), name, fill=tuple(o.get('col', [255, 255, 0])), font=font)
if step <= 0: step = 10 if (u1 - u0) > 60 else 5 if (u1 - u0) > 30 else 2 if (u1 - u0) > 12 else 1
g = u0 - (u0 % step) + (step if u0 % step else 0)
while g <= u1:
    d.line([px((g, n0)), px((g, n1))], fill=(255, 255, 255), width=1); d.text(px((g + 0.1 * step / 5, n0 + 0.1)), '%g' % g, fill=(255, 255, 0), font=font)
    g += step
g = n0 - (n0 % step) + (step if n0 % step else 0)
while g <= n1:
    d.line([px((u0, g)), px((u1, g))], fill=(255, 255, 255), width=1); d.text(px((u0 + 0.1, g + 0.1 * step / 5)), '%g' % g, fill=(255, 255, 0), font=font)
    g += step
im.save(out, quality=93); print(out, im.size)
