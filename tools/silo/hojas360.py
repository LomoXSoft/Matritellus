"""a plan of where the 360 photos stand and sheets of them: python hojas360.py P360_FOLDER OUT_FOLDER"""
import sys, os, json
from PIL import Image, ImageDraw, ImageFont
src, out = sys.argv[1], sys.argv[2]
rows = json.load(open(os.path.join(src, 'nombres.json')))
try: font = ImageFont.truetype('arial.ttf', 16)
except Exception: font = ImageFont.load_default()
x0, z0, k = 509.0, 303.0, 60.0
im = Image.new('RGB', (int(20 * k), int(18 * k)), (250, 250, 248))
d = ImageDraw.Draw(im)
for gx in range(0, 21):
    d.line([(gx * k, 0), (gx * k, im.size[1])], fill=(225, 225, 225)); d.text((gx * k + 2, 2), str(int(x0 + gx)), fill=(150, 150, 150), font=font)
for gz in range(0, 19):
    d.line([(0, gz * k), (im.size[0], gz * k)], fill=(225, 225, 225)); d.text((2, gz * k + 2), str(int(z0 + gz)), fill=(150, 150, 150), font=font)
byid = {v['id']: n for n, v in rows.items()}
P = lambda v: ((v['x'] - x0) * k, (v['z'] - z0) * k)
for n, v in rows.items():
    for l in v['links']:
        if l in byid: d.line([P(v), P(rows[byid[l]])], fill=(160, 190, 230), width=1)
for n, v in rows.items():
    x, y = P(v)
    d.ellipse([x - 5, y - 5, x + 5, y + 5], fill=(200, 60, 40))
    d.text((x + 6, y - 9), n[1:], fill=(20, 20, 20), font=font)
im.save(os.path.join(out, 'plano_360.png'))
names = sorted(rows)
for s in range(0, len(names), 10):
    part = names[s:s + 10]
    w, h = 800, 400
    sh = Image.new('RGB', (2 * w + 6, ((len(part) + 1) // 2) * (h + 24)), (20, 20, 22))
    dd = ImageDraw.Draw(sh)
    for i, n in enumerate(part):
        x, y = (i % 2) * (w + 6), (i // 2) * (h + 24)
        v = rows[n]
        dd.text((x + 4, y + 3), '%s  x %.1f z %.1f  centro mira a %d grados' % (n, v['x'], v['z'], round(v['heading'] or 0)), fill=(240, 240, 240), font=font)
        sh.paste(Image.open(os.path.join(src, n + '.jpg')).convert('RGB').resize((w, h), Image.LANCZOS), (x, y + 24))
    f = os.path.join(out, 'hoja360_%d.jpg' % (s // 10 + 1))
    sh.save(f, quality=85); print(f, sh.size)
