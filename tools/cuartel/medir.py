"""Where on a front of the Guardia Civil's barracks a pixel of one of capturas.py's pictures is.

    python tools/cuartel/medir.py FOLDER NAME FACE PLANE px,py [px,py ...]        for each: metres along that front, height over the camera's eye
    python tools/cuartel/medir.py FOLDER NAME FACE PLANE fit px,py=x [px,py=x]    where the camera must have stood for those pixels
                                                                                  to be at those metres along the front
    ... cam=along,out before the pixels: the camera's place in that front's frame (from a fit), instead of Google's

FACE: o (the main front, on the avenue: 0 at its north end, running south), n (the north fronts, on the Calle de Víctor
Pradera: 0 at the avenue's corner, running east), s (the south fronts, towards the Calle Nueva: 0 at the east end,
running west). Each as seen from outside, left to right. PLANE: how far out of that front's line the wall looked at
is (0, or negative for what is set back). Pixels are those of the 1024 x 640 pictures; heights are over the camera's eye.
The frame of godot/scripts/cuartel.gd: origin map (46.84, -534.47), x along the main front (south), z out of it (west).
Catastro along the main front: 0-4.9 (set back 1.61), 4.9-15.08, the link 15.08-20.82 (set back 2.02), 20.82-30.62,
30.62-35.63 (set back 1.62). Along the north: 1.61-14.48 the north-west block, 22.07-47.59 the north-east one.
"""
import json, math, os, sys

O0 = (46.84, -534.47)
U0 = (0.165, 0.986)
OUT0 = (-0.986, 0.165)
FACES = {'o': ((0.0, 0.0), 1), 'n': ((0.0, 0.0), 2), 's': ((35.63, -47.6), 3)}
O, U, OUT = O0, U0, OUT0


def face(name):
    """sets the frame of that front: its origin, the way it runs, the way it looks"""
    global O, U, OUT
    (fx, fz), kind = FACES[name]
    o = (O0[0] + U0[0] * fx + OUT0[0] * fz, O0[1] + U0[1] * fx + OUT0[1] * fz)
    if kind == 1:
        O, U, OUT = o, U0, OUT0
    elif kind == 2:                 # runs east (against the main front's out), looks north (against its run)
        O, U, OUT = o, (-OUT0[0], -OUT0[1]), (-U0[0], -U0[1])
    else:                           # runs west, looks south
        O, U, OUT = o, OUT0, U0


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
    face(sys.argv[3])
    plane = float(sys.argv[4])
    args = sys.argv[5:]
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
