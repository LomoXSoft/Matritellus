"""A Street View picture laid flat on a front: the elevation of the wall between two points of the map, s metres along
it from its left end (as seen from the street) and y metres above the street, with a grid of 1 m (yellow every 5 m),
read straight off the picture through its camera (heading, pitch, field of view, 2.5 m above the street).

    python tools/merkocarry/alzado.py SV_FOLDER view AX,AZ BX,BZ OUT.jpg [s0,s1] [ymax] [shift] [px_per_m]

AX,AZ / BX,BZ: the front's left and right ends on the map (comun.FRONTS); `shift`: metres the camera is moved along
the front (Google's cameras are often a few metres out along a street: line the corners up with Catastro's).
Things standing out of the wall (a canopy, a sign) come out where their face would meet the wall's plane.
"""
import json, math, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

if __name__ == '__main__':
    folder, name = sys.argv[1], sys.argv[2]
    A = tuple(map(float, sys.argv[3].split(','))); B = tuple(map(float, sys.argv[4].split(',')))
    out = sys.argv[5]
    L = math.dist(A, B)
    s0, s1 = tuple(map(float, sys.argv[6].split(','))) if len(sys.argv) > 6 else (-3.0, L + 3.0)
    ymax = float(sys.argv[7]) if len(sys.argv) > 7 else 10.0
    sh = sys.argv[8].split(',') if len(sys.argv) > 8 else ['0']
    shift = float(sh[0])                                 # along the front, and (the second) towards it
    toward = float(sh[1]) if len(sh) > 1 else 0.0
    k = float(sys.argv[9]) if len(sys.argv) > 9 else 40.0
    v = json.load(open(os.path.join(folder, 'views.json')))[name]
    src = np.asarray(Image.open(os.path.join(folder, name + '.jpg')).convert('RGB'))
    H, W = src.shape[:2]
    u = ((B[0] - A[0]) / L, (B[1] - A[1]) / L)
    into = (u[1], -u[0])                                 # out of the front is (-u.y, u.x) (obra.face): into it, the other way
    cx = v['x'] + u[0] * shift + into[0] * toward
    cz = v['z'] + u[1] * shift + into[1] * toward
    hc = 2.5
    h, p = math.radians(v['heading']), math.radians(v['pitch'])
    F = np.array([math.sin(h) * math.cos(p), math.sin(p), -math.cos(h) * math.cos(p)])
    R = np.array([math.cos(h), 0.0, math.sin(h)])
    U = np.cross(R, F)
    f = (W / 2.0) / math.tan(math.radians(v['hfov']) / 2.0)
    ow, oh = int((s1 - s0) * k), int(ymax * k)
    ss = s0 + (np.arange(ow) + 0.5) / k
    yy = ymax - (np.arange(oh) + 0.5) / k
    S, Y = np.meshgrid(ss, yy)
    Px = A[0] + u[0] * S - cx; Pz = A[1] + u[1] * S - cz; Py = Y - hc
    D = np.stack([Px, Py, Pz], -1)
    df = D @ F; dr = D @ R; du = D @ U
    ok = df > 0.1
    xi = np.where(ok, W / 2.0 + f * dr / np.where(ok, df, 1), -1)
    yi = np.where(ok, H / 2.0 - f * du / np.where(ok, df, 1), -1)
    ok &= (xi >= 0) & (xi < W - 1) & (yi >= 0) & (yi < H - 1)
    img = np.zeros((oh, ow, 3), np.uint8)
    img[ok] = src[yi[ok].astype(int), xi[ok].astype(int)]
    im = Image.fromarray(img)
    d = ImageDraw.Draw(im)
    fnt = ImageFont.truetype('arial.ttf', 14)
    for sm in range(int(math.ceil(s0)), int(s1) + 1):
        x = (sm - s0) * k
        c = (255, 255, 0) if sm % 5 == 0 else (255, 255, 255)
        d.line([(x, 0), (x, oh)], fill=c, width=1)
        if sm % 5 == 0:
            d.text((x + 2, 2), str(sm), fill=c, font=fnt)
    for ym in range(0, int(ymax) + 1):
        y = (ymax - ym) * k
        c = (255, 255, 0) if ym % 5 == 0 else (255, 255, 255)
        d.line([(0, y), (ow, y)], fill=c, width=1)
        d.text((2, y - 16), str(ym), fill=c, font=fnt)
    for sm in (0.0, L):                                  # Catastro's ends
        x = (sm - s0) * k
        d.line([(x, 0), (x, oh)], fill=(255, 0, 255), width=2)
    d.text((4, oh - 20), '%s  shift %.1f, %.1f  (front %.2f m)' % (name, shift, toward, L), fill=(0, 255, 255), font=fnt)
    im.save(out, quality=88)
    print(out, im.size)
