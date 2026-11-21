"""A whole front laid flat from several Street View pictures taken along it: the elevation of the wall between two
points of the map, s metres along it from its left end (as seen from the street) and y metres above the street, each
column taken from the camera nearest to it. A grid of 1 m, yellow and numbered every 5 m. The long fronts of the
almazara are 100 m and more: it comes out in rows of `row` metres, one under another.

    python tools/almazara/alzado.py SV_FOLDER AX,AZ BX,BZ OUT.jpg view[:shift[,toward]] [view ...] [ymax=14] [row=60] [k=30] [hc=2.5]

SV_FOLDER holds views.json and the pictures (capturas.py; Google's, not kept in the repository). AX,AZ / BX,BZ: the
front's left and right ends on the map. `shift`: metres that camera is moved along the front, `toward`: towards it
(Google's cameras are often a few metres out: line a corner up with Catastro's first). Things standing out of the wall
come out where their face would meet the wall's plane.
"""
import json, math, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

if __name__ == '__main__':
    folder = sys.argv[1]
    A = tuple(map(float, sys.argv[2].split(','))); B = tuple(map(float, sys.argv[3].split(',')))
    out = sys.argv[4]
    opt = {'ymax': 14.0, 'row': 60.0, 'k': 30.0, 'hc': 2.5}
    names = []
    for a in sys.argv[5:]:
        if '=' in a:
            opt[a.split('=')[0]] = float(a.split('=')[1])
        else:
            names.append(a)
    L = math.dist(A, B)
    u = ((B[0] - A[0]) / L, (B[1] - A[1]) / L)
    into = (u[1], -u[0])                                 # out of the front is (-u.y, u.x) (obra.face): into it, the other way
    views = json.load(open(os.path.join(folder, 'views.json')))
    cams = []
    for arg in names:
        n, _, sh = arg.partition(':')
        sh = [float(q) for q in sh.split(',')] if sh else [0.0]
        v = views[n]
        cx = v['x'] + u[0] * sh[0] + into[0] * (sh[1] if len(sh) > 1 else 0.0)
        cz = v['z'] + u[1] * sh[0] + into[1] * (sh[1] if len(sh) > 1 else 0.0)
        src = np.asarray(Image.open(os.path.join(folder, n + '.jpg')).convert('RGB'))
        h, p = math.radians(v['heading']), math.radians(v['pitch'])
        F = np.array([math.sin(h) * math.cos(p), math.sin(p), -math.cos(h) * math.cos(p)])
        R = np.array([math.cos(h), 0.0, math.sin(h)])
        cams.append({'n': n, 'x': cx, 'z': cz, 's': (cx - A[0]) * u[0] + (cz - A[1]) * u[1], 'd': abs((cx - A[0]) * into[0] + (cz - A[1]) * into[1]),
                     'src': src, 'F': F, 'R': R, 'U': np.cross(R, F), 'f': (src.shape[1] / 2.0) / math.tan(math.radians(v['hfov']) / 2.0)})
        print('%s  s %.1f  %.1f m from the front' % (n, cams[-1]['s'], cams[-1]['d']))
    k, ymax, hc = opt['k'], opt['ymax'], opt['hc']
    ow, oh = int(L * k), int(ymax * k)
    ss = (np.arange(ow) + 0.5) / k
    yy = ymax - (np.arange(oh) + 0.5) / k
    img = np.zeros((oh, ow, 3), np.uint8)
    which = np.argmin(np.abs(ss[:, None] - np.array([c['s'] for c in cams])[None, :]), axis=1)
    for ci, c in enumerate(cams):
        cols = np.where(which == ci)[0]
        if not len(cols):
            continue
        S, Y = np.meshgrid(ss[cols], yy)
        D = np.stack([A[0] + u[0] * S - c['x'], Y - hc, A[1] + u[1] * S - c['z']], -1)
        df = D @ c['F']; dr = D @ c['R']; du = D @ c['U']
        H, W = c['src'].shape[:2]
        ok = df > 0.1
        xi = np.where(ok, W / 2.0 + c['f'] * dr / np.where(ok, df, 1), -1)
        yi = np.where(ok, H / 2.0 - c['f'] * du / np.where(ok, df, 1), -1)
        ok &= (xi >= 0) & (xi < W - 1) & (yi >= 0) & (yi < H - 1)
        part = np.zeros((oh, len(cols), 3), np.uint8)
        part[ok] = c['src'][yi[ok].astype(int), xi[ok].astype(int)]
        img[:, cols] = part
    im = Image.fromarray(img)
    d = ImageDraw.Draw(im)
    fnt = ImageFont.truetype('arial.ttf', 14)
    for sm in range(0, int(L) + 1):
        x = sm * k
        c = (255, 255, 0) if sm % 5 == 0 else (255, 255, 255)
        d.line([(x, 0), (x, oh)], fill=c + (0,), width=1)
        if sm % 5 == 0:
            d.text((x + 2, 2), str(sm), fill=c, font=fnt)
    for ym in range(0, int(ymax) + 1):
        y = (ymax - ym) * k
        c = (255, 255, 0) if ym % 5 == 0 else (255, 255, 255)
        d.line([(0, y), (ow, y)], fill=c, width=1)
    for ci, c in enumerate(cams):                         # where each camera stood, and where its columns end
        d.text((c['s'] * k + 2, oh - 18), c['n'], fill=(0, 255, 255), font=fnt)
    rw = int(opt['row'] * k)
    rows = int(math.ceil(ow / rw))
    sheet = Image.new('RGB', (rw, rows * (oh + 6)), (0, 0, 0))
    for r in range(rows):
        sheet.paste(im.crop((r * rw, 0, min(ow, (r + 1) * rw), oh)), (0, r * (oh + 6)))
    sheet.save(out, quality=90)
    print(out, sheet.size)
