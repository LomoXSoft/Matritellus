"""Where on the fronts of the Calle Real (the pharmacy's row) a pixel of one of capturas.py's pictures is.

    python tools/farmacia/medir.py FOLDER NAME px,py [px,py ...]       prints for each: metres along the row, height
    python tools/farmacia/medir.py FOLDER NAME fit px,py=x [px,py=x]   where the camera must have stood for those
                                                                       pixels to be at those metres along the row

Frame (the one of godot/scripts/farmacia.gd): origin at the north end of the brick house's front, map (-61.17, -89.09);
x along the fronts towards the Calle de Colón (the row seen from the street runs left to right); z out into the street;
heights from the pavement. The fronts of the four houses are one straight line (Catastro): the brick house 0-5.33, the
pharmacy 5.33-23.55, the narrow house 23.55-26.5, the chemist's 26.5-32.86 (its corner with Colón).
For the chemist's side on the Calle de Colón (pictures C24_...) pass `colon` as the first word after NAME: x is then
metres along that side from the corner, z out into Colón.
A pixel is taken to be ON the plane of the fronts: balconies and whatever stands proud of the wall read a little off.
"""
import json, math, os, sys

O = (-61.17, -89.09)
U = (-0.1835, 0.9830)
OUT = (-U[1], U[0])                 # into the street
CORNER = (-67.18, -56.80)           # the chemist's corner with the Calle de Colón
UC = (0.887, 0.462)                 # along its side on Colón, away from the corner
OUTC = (-0.462, 0.887)
CAM = 2.5                           # the camera over the street
FIX = {'X24': (0.5, 2.0), 'A24': (0.54, 2.03), 'N24': (0.5, 2.0), 'M24': (0.46, 1.92), 'C24': (0.5, 2.0)}      # panorama -> (dx, dz) on the map: fitted to Catastro's party walls (medir.py ... fit)


def frame(colon):
    return (CORNER, UC, OUTC) if colon else (O, U, OUT)


def local(p, colon=False):
    o, u, out = frame(colon)
    d = (p[0] - o[0], p[1] - o[1])
    return d[0] * u[0] + d[1] * u[1], d[0] * out[0] + d[1] * out[1]


def ray(v, px, py, w=1024, h=640):
    f = (w / 2) / math.tan(math.radians(v['hfov'] / 2))
    a, b = (px - w / 2) / f, (h / 2 - py) / f
    p = math.radians(v['pitch'])
    up, fwd = b * math.cos(p) + math.sin(p), -b * math.sin(p) + math.cos(p)
    hd = math.radians(v['heading'])
    return (fwd * math.sin(hd) + a * math.cos(hd), -fwd * math.cos(hd) + a * math.sin(hd)), up


def at(v, px, py, cam=None, colon=False):
    o, u, out = frame(colon)
    fx, fz = FIX.get(v['pano'], (0.0, 0.0))
    cx, cz = cam if cam else local((v['x'] + fx, v['z'] + fz), colon)
    d, up = ray(v, px, py)
    t = -cz / (d[0] * out[0] + d[1] * out[1])
    return cx + t * (d[0] * u[0] + d[1] * u[1]), CAM + t * up


if __name__ == '__main__':
    views = json.load(open(os.path.join(sys.argv[1], 'views.json')))
    v = views[sys.argv[2]]
    args = sys.argv[3:]
    colon = bool(args) and args[0] == 'colon'
    if colon:
        args = args[1:]
    if args and args[0] == 'fit':
        pts = [(tuple(float(q) for q in a.split('=')[0].split(',')), float(a.split('=')[1])) for a in args[1:]]
        cx0, cz0 = local((v['x'], v['z']), colon)
        best = None
        for i in range(-60, 61):
            for j in range(-50, 51):
                cam = (cx0 + i * 0.05, cz0 + j * 0.05)
                if cam[1] < 1.0:
                    continue
                e = sum((at(v, p[0], p[1], cam, colon)[0] - x) ** 2 for p, x in pts)
                if best is None or e < best[0]:
                    best = (e, cam)
        o, u, out = frame(colon)
        cam = best[1]
        wx = o[0] + u[0] * cam[0] + out[0] * cam[1]
        wz = o[1] + u[1] * cam[0] + out[1] * cam[1]
        print('Google: along %.2f, out %.2f   fitted: along %.2f, out %.2f (rms %.2f m)   FIX (dx, dz) = (%.2f, %.2f)'
              % (cx0, cz0, cam[0], cam[1], math.sqrt(best[0] / len(pts)), wx - v['x'], wz - v['z']))
    else:
        for a in args:
            px, py = (float(q) for q in a.split(','))
            x, y = at(v, px, py, None, colon)
            print('%-12s along %6.2f   height %5.2f' % (a, x, y))
