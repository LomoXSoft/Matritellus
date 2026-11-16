"""Where on the south front of the old school a pixel of one of capturas.py's pictures is.

    python tools/colegio/medir.py FOLDER NAME PLANE px,py [px,py ...]        for each: metres along the front, height over the camera's eye
    python tools/colegio/medir.py FOLDER NAME PLANE fit px,py=x [px,py=x]    where the camera must have stood for those pixels
                                                                             to be at those metres along the front
    ... cam=along,out before the pixels: the camera's place in the frame (from a fit), instead of Google's

The frame (the one of godot/scripts/colegio.gd): origin at the south-west corner of the west tower, map (-427.35, 121.61);
x along the front towards the Calle de Santa Clara; z out of it, towards the court and the avenue.
PLANE: how far out the wall looked at is: 0 for the towers' fronts, -1.88 for the body between them, or any number.
Pixels are those of the 1024 x 640 pictures. Heights are over the camera's eye (some 2.5 m over its street).
Catastro's corners along the front: 0 and 7.75 (the west tower), 32.88 and 40.35 (the east one).
"""
import json, math, os, sys

O = (-427.35, 121.61)
U = (0.9706, -0.2407)
OUT = (0.2407, 0.9706)


def local(p):
    d = (p[0] - O[0], p[1] - O[1])
    return d[0] * U[0] + d[1] * U[1], d[0] * OUT[0] + d[1] * OUT[1]


def ray(v, px, py, w=1024, h=640):
    f = (w / 2) / math.tan(math.radians(v['hfov'] / 2))
    a, b = (px - w / 2) / f, (h / 2 - py) / f
    p = math.radians(v['pitch'])
    up, fwd = b * math.cos(p) + math.sin(p), -b * math.sin(p) + math.cos(p)
    hd = math.radians(v['heading'])
    return (fwd * math.sin(hd) + a * math.cos(hd), -fwd * math.cos(hd) + a * math.sin(hd)), up


def at(v, px, py, cam, plane):
    d, up = ray(v, px, py)
    t = (plane - cam[1]) / (d[0] * OUT[0] + d[1] * OUT[1])
    return cam[0] + t * (d[0] * U[0] + d[1] * U[1]), t * up


if __name__ == '__main__':
    views = json.load(open(os.path.join(sys.argv[1], 'views.json')))
    v = views[sys.argv[2]]
    plane = float(sys.argv[3])
    args = sys.argv[4:]
    cam0 = local((v['x'], v['z']))
    if args and args[0] == 'fit':
        pts = [(tuple(float(q) for q in a.split('=')[0].split(',')), float(a.split('=')[1])) for a in args[1:]]
        best = None
        for i in range(-100, 101):
            for j in range(-100, 101):
                cam = (cam0[0] + i * 0.05, cam0[1] + j * 0.05)
                e = sum((at(v, p[0], p[1], cam, plane)[0] - x) ** 2 for p, x in pts)
                if best is None or e < best[0]:
                    best = (e, cam)
        print('Google: along %.2f, out %.2f   fitted: along %.2f, out %.2f (rms %.2f m)   cam=%.2f,%.2f'
              % (cam0[0], cam0[1], best[1][0], best[1][1], math.sqrt(best[0] / len(pts)), best[1][0], best[1][1]))
    else:
        cam = cam0
        for a in args:
            if a.startswith('cam='):
                cam = tuple(float(q) for q in a[4:].split(','))
                continue
            px, py = (float(q) for q in a.split(','))
            s, y = at(v, px, py, cam, plane)
            print('%6.0f,%4.0f   along %6.2f   height %6.2f' % (px, py, s, y))
