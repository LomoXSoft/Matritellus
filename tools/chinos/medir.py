"""Where on a wall of the corner shop between San José and Santo Domingo a pixel of one of capturas.py's pictures is.

    python tools/chinos/medir.py FOLDER NAME WALL px,py [px,py ...]       for each: metres along the wall, height over the camera's ground
    python tools/chinos/medir.py FOLDER NAME WALL fit px,py=s [px,py=s]   where the camera must have stood for those pixels
                                                                          to be at those metres along the wall

WALL: n (the Calle de San José: 0 at the point, 19.77 at the west end), s (Santo Domingo: 0 at the west end, 19.97 at
the point), p (the point: 0 at its south corner, 3.28 at its north one). Each as seen from its street, left to right.
Pixels are those of the 1024 x 640 pictures. A pixel is taken to be ON the wall's plane.
Google's place for a camera is a metre or two out: fit it first to both ends of the wall (Catastro's corners), then
put what it prints in FIX below.
"""
import json, math, os, sys

WALLS = {'n': ((-282.37, 8.19), (-301.65, 3.82)), 's': ((-302.17, 14.32), (-282.40, 11.47)), 'p': ((-282.40, 11.47), (-282.37, 8.19))}
CAM = 2.5                           # the camera over the street
FIX = {}                            # (picture name, wall) -> (along, out): the camera in that wall's frame, fitted


def frame(wall):
    a, b = WALLS[wall]
    ln = math.hypot(b[0] - a[0], b[1] - a[1])
    u = ((b[0] - a[0]) / ln, (b[1] - a[1]) / ln)
    return a, u, (-u[1], u[0]), ln


def local(p, wall):
    o, u, out, _ = frame(wall)
    d = (p[0] - o[0], p[1] - o[1])
    return d[0] * u[0] + d[1] * u[1], d[0] * out[0] + d[1] * out[1]


def ray(v, px, py, w=1024, h=640):
    f = (w / 2) / math.tan(math.radians(v['hfov'] / 2))
    a, b = (px - w / 2) / f, (h / 2 - py) / f
    p = math.radians(v['pitch'])
    up, fwd = b * math.cos(p) + math.sin(p), -b * math.sin(p) + math.cos(p)
    hd = math.radians(v['heading'])
    return (fwd * math.sin(hd) + a * math.cos(hd), -fwd * math.cos(hd) + a * math.sin(hd)), up


def at(v, px, py, wall, cam):
    o, u, out, _ = frame(wall)
    d, up = ray(v, px, py)
    t = -cam[1] / (d[0] * out[0] + d[1] * out[1])
    return cam[0] + t * (d[0] * u[0] + d[1] * u[1]), CAM + t * up


if __name__ == '__main__':
    views = json.load(open(os.path.join(sys.argv[1], 'views.json')))
    name, wall = sys.argv[2], sys.argv[3]
    v = views[name]
    args = sys.argv[4:]
    cam0 = local((v['x'], v['z']), wall)
    if args and args[0] == 'fit':
        pts = [(tuple(float(q) for q in a.split('=')[0].split(',')), float(a.split('=')[1])) for a in args[1:]]
        best = None
        for i in range(-80, 81):
            for j in range(-80, 81):
                cam = (cam0[0] + i * 0.05, cam0[1] + j * 0.05)
                if cam[1] < 0.8:
                    continue
                e = sum((at(v, p[0], p[1], wall, cam)[0] - x) ** 2 for p, x in pts)
                if best is None or e < best[0]:
                    best = (e, cam)
        print("Google: along %.2f, out %.2f   fitted: along %.2f, out %.2f (rms %.2f m)   FIX[('%s', '%s')] = (%.2f, %.2f)"
              % (cam0[0], cam0[1], best[1][0], best[1][1], math.sqrt(best[0] / len(pts)), name, wall, best[1][0], best[1][1]))
    else:
        cam = FIX.get((name, wall), cam0)
        for a in args:
            if a.startswith('cam='):
                cam = tuple(float(q) for q in a[4:].split(','))
                continue
            px, py = (float(q) for q in a.split(','))
            s, y = at(v, px, py, wall, cam)
            print('%6.0f,%4.0f   along %6.2f   height %5.2f' % (px, py, s, y))
