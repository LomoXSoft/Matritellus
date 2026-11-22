"""Measures along a front from Street View pictures (tools/cruce/capturas.py, views.json): where a pixel's ray meets
the vertical plane of a front, as metres along it and metres up.

    python tools/cruce/mide.py VIEWS.json FRONT view:u,v [view:u,v ...]  [cam=x,z] [alto=h] [fit=view:u@s,view:u@s]

FRONT: n (the Salvador, from its west end), e (the avenue, from the Salvador's corner), s (the Calle Cervantes, from the
avenue's corner); dn, de: the dental clinic's (the Calle Cervantes from the corner, the Arcos from its south end); en, ew: the white house of Santa Ana 2 (Santa Ana from its east end, the Arcos from the corner); fw, fc, fs: the cream house with the bay window (the avenue from its north end, the corner's cut, Santa Ana from the cut). gs, ge: the house north of the Salvador (the Salvador from its west end, the avenue from the Salvador's corner). cam=: the camera's place on the map, if Google's is off (it is good to a metre or two); fit= finds it
from two pixels whose metres along the front are known (both from that same camera). alto=: the camera's height over
the pavement at the front (2.5 m, a car's).
"""
import json, math, sys

CORNERS = {'n': ((92.34, 58.42), (108.32, 62.26)), 'e': ((108.32, 62.26), (108.56, 70.77)), 's': ((108.56, 70.77), (103.82, 72.76)),
           'dn': ((109.115, 77.683), (96.54, 79.20)), 'de': ((109.06, 86.65), (109.115, 77.683)),
           'en': ((131.66, 73.67), (116.70, 74.14)), 'ew': ((116.70, 74.14), (116.49, 78.83)),
           'fw': ((118.50, 47.62), (117.97, 57.91)), 'fc': ((117.97, 57.91), (120.12, 61.46)), 'fs': ((120.12, 61.46), (129.63, 63.93)),
           'gs': ((88.66, 49.82), (107.84, 56.33)), 'ge': ((107.84, 56.33), (109.16, 43.81))}      # the dental clinic: its north front from the corner, its east front from its south end

def ray(v, u, y, W=1024, H=640):
    f = (W / 2) / math.tan(math.radians(v['hfov'] / 2))
    x, yy, z = (u - W / 2), (H / 2 - y), f                # camera: x right, y up, z forward
    p = math.radians(v['pitch'])
    y2, z2 = yy * math.cos(p) + z * math.sin(p), -yy * math.sin(p) + z * math.cos(p)
    h = math.radians(v['heading'])                       # heading clockwise from north; map: x east, z south
    east = x * math.cos(h) + z2 * math.sin(h)
    north = -x * math.sin(h) + z2 * math.cos(h)
    return east, y2, -north                              # (dx, dy up, dz south)

def meet(cam, d, a, b):
    ux, uz = b[0] - a[0], b[1] - a[1]
    ln = math.hypot(ux, uz); ux, uz = ux / ln, uz / ln
    det = d[0] * (-uz) - (-ux) * d[2]
    t = ((a[0] - cam[0]) * (-uz) - (-ux) * (a[1] - cam[1])) / det
    s = ((cam[0] + t * d[0] - a[0]) * ux + (cam[1] + t * d[2] - a[1]) * uz)
    return s, t

if __name__ == '__main__':
    views = json.load(open(sys.argv[1]))
    a, b = CORNERS[sys.argv[2]]
    opt = dict(q.split('=', 1) for q in sys.argv[3:] if '=' in q)
    picks = [q for q in sys.argv[3:] if '=' not in q]
    cam = tuple(float(q) for q in opt['cam'].split(',')) if 'cam' in opt else None
    high = float(opt.get('alto', 2.5))
    if 'fit' in opt:
        (n1, r1), (n2, r2) = [q.split(':') for q in opt['fit'].split(',')]
        (u1, s1), (u2, s2) = [tuple(float(k) for k in r.split('@')) for r in (r1, r2)]
        ln = math.hypot(b[0] - a[0], b[1] - a[1]); ux, uz = (b[0] - a[0]) / ln, (b[1] - a[1]) / ln
        p1, p2 = (a[0] + ux * s1, a[1] + uz * s1), (a[0] + ux * s2, a[1] + uz * s2)
        d1, d2 = ray(views[n1], u1, 320), ray(views[n2], u2, 320)
        # p1 - t1 d1 = p2 - t2 d2
        det = -d1[0] * d2[2] + d2[0] * d1[2]
        t1 = (-(p1[0] - p2[0]) * d2[2] + d2[0] * (p1[1] - p2[1])) / det
        cam = (p1[0] - t1 * d1[0], p1[1] - t1 * d1[2])
        print('camera fitted at (%.2f, %.2f)' % cam)
    for q in picks:
        n, r = q.split(':')
        u, y = [float(k) for k in r.split(',')]
        c = cam or (views[n]['x'], views[n]['z'])
        d = ray(views[n], u, y)
        s, t = meet(c, d, a, b)
        print('%-10s u %4.0f v %4.0f -> %6.2f m along, %5.2f m up (%.1f m away)' % (n, u, y, s, high + t * d[1], t * math.hypot(d[0], d[2])))
