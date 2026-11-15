"""An aerial photograph (tools/plaza/aerea_wmts.py) with a grid in the game's metres and, if given, Catastro's building
parts (tools/molino/catastro.py) drawn on it.

    python tools/molino/plano.py AERIAL(no extension) OUT.jpg [x0 z0 x1 z1] [--parts parts.json] [--scale 2] [--grid 5]
"""
import json, sys
from PIL import Image, ImageDraw, ImageFont

args = sys.argv[1:]
opt = {}
for key in ('--parts', '--scale', '--grid'):
    if key in args:
        i = args.index(key)
        opt[key] = args[i + 1]
        del args[i:i + 2]
src, out = args[0], args[1]
meta = json.load(open(src + '.json'))
im = Image.open(src + '.jpg').convert('RGB')
mpp = meta['mpp']
x0, z0, x1, z1 = (float(v) for v in args[2:6]) if len(args) >= 6 else (meta['x0'], meta['z0'], meta['x1'], meta['z1'])
im = im.crop((int((x0 - meta['x0']) / mpp), int((z0 - meta['z0']) / mpp), int((x1 - meta['x0']) / mpp), int((z1 - meta['z0']) / mpp)))
k = float(opt.get('--scale', 1))
if k != 1:
    im = im.resize((int(im.size[0] * k), int(im.size[1] * k)), Image.LANCZOS)
ppm = k / mpp
d = ImageDraw.Draw(im)
try:
    font = ImageFont.truetype('arial.ttf', 13)
except Exception:
    font = ImageFont.load_default()
step = float(opt.get('--grid', 5))
import math
gx = math.ceil(x0 / step) * step
while gx < x1:
    X = (gx - x0) * ppm
    d.line([(X, 0), (X, im.size[1])], fill=(255, 255, 0) if gx % (step * 2) == 0 else (255, 255, 140), width=1)
    if gx % (step * 2) == 0:
        d.text((X + 2, 2), '%g' % gx, fill=(255, 255, 0), font=font)
    gx += step
gz = math.ceil(z0 / step) * step
while gz < z1:
    Y = (gz - z0) * ppm
    d.line([(0, Y), (im.size[0], Y)], fill=(255, 255, 0) if gz % (step * 2) == 0 else (255, 255, 140), width=1)
    if gz % (step * 2) == 0:
        d.text((2, Y + 2), '%g' % gz, fill=(255, 255, 0), font=font)
    gz += step
if '--parts' in opt:
    for p in json.load(open(opt['--parts']))['parts']:
        ring = [((x - x0) * ppm, (z - z0) * ppm) for x, z in p['ring']]
        d.line(ring + [ring[0]], fill=(255, 60, 60), width=2)
        cx = sum(q[0] for q in ring) / len(ring); cz = sum(q[1] for q in ring) / len(ring)
        d.text((cx - 10, cz - 6), '%s:%d' % (p['id'].split('_part')[-1], p['floors']), fill=(255, 255, 255), font=font)
im.save(out, quality=92)
print(out, im.size)
