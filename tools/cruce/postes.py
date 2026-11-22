"""Where a free-standing thing of the crossroads stands on the map (a traffic light's post, a sign, the mirror), from
Street View pictures (tools/cruce/capturas.py, views.json): the bearings to it from two or more cameras, crossed.

    python tools/cruce/postes.py VIEWS.json view:u,v view:u,v [...]  [cam.VIEWPREFIX=x,z ...] [alto=h]

u, v: the pixel of its foot on the ground in each 1024x640 picture (the scratchpad's rejilla.py draws the grid). With
two or more pictures from different cameras: the point nearest all their rays on the map, how far each ray passes from
it, and where each picture alone would put it (its ray down to the ground, the camera 2.5 m up: rough beyond 10 m).
With `top`, a last argument view:u,v of some higher point of the same thing: how high that point is.

    python tools/cruce/postes.py VIEWS.json x_cs_045:690,400 x_cn_090:210,640 top=x_cn_090:215,520

cam.x_cs=111.2,70.9 moves the camera of every picture whose name starts with x_cs (Google's positions are off by half
a metre or so: check with a corner of a building whose place on the map is known).
"""
import json, math, sys
from mide import ray

if __name__ == '__main__':
    views = json.load(open(sys.argv[1]))
    opt = dict(q.split('=', 1) for q in sys.argv[2:] if '=' in q)
    picks = [q for q in sys.argv[2:] if '=' not in q]
    high = float(opt.get('alto', 2.5))
    moved = {k[4:]: tuple(float(c) for c in v.split(',')) for k, v in opt.items() if k.startswith('cam.')}

    def cam(name):
        best = None
        for k in moved:
            if name.startswith(k) and (best is None or len(k) > len(best)):
                best = k
        return moved[best] if best else (views[name]['x'], views[name]['z'])

    rays = []
    for q in picks:
        n, r = q.split(':')
        u, v = [float(k) for k in r.split(',')]
        d = ray(views[n], u, v)
        ln = math.hypot(d[0], d[2])
        rays.append((n, cam(n), (d[0] / ln, d[2] / ln), d[1] / ln))
    # the point nearest every ray: least squares over the lines
    a11 = a12 = a22 = b1 = b2 = 0.0
    for n, c, d, _ in rays:
        nx, nz = -d[1], d[0]
        a11 += nx * nx; a12 += nx * nz; a22 += nz * nz
        k = nx * c[0] + nz * c[1]
        b1 += nx * k; b2 += nz * k
    det = a11 * a22 - a12 * a12
    p = None
    if len(rays) > 1 and abs(det) > 1e-6:
        p = ((b1 * a22 - b2 * a12) / det, (a11 * b2 - a12 * b1) / det)
        print('at (%.2f, %.2f)' % p)
    for n, c, d, dy in rays:
        alone = '-'
        if dy < -0.01:
            t = high / -dy
            alone = '(%.2f, %.2f) at %.1f m' % (c[0] + d[0] * t, c[1] + d[1] * t, t)
        off = ''
        if p:
            off = 'passes %.2f m from it, %.1f m away; ' % (abs(-d[1] * (p[0] - c[0]) + d[0] * (p[1] - c[1])), (p[0] - c[0]) * d[0] + (p[1] - c[1]) * d[1])
        print('  %-12s %salone: %s' % (n, off, alone))
    if 'top' in opt and (p or len(rays) == 1):
        n, r = opt['top'].split(':')
        u, v = [float(k) for k in r.split(',')]
        d = ray(views[n], u, v)
        c = cam(n)
        if p is None:
            _, c0, d0, dy0 = rays[0]
            t = high / -dy0
            p = (c0[0] + d0[0] * t, c0[1] + d0[1] * t)
        dist = math.hypot(p[0] - c[0], p[1] - c[1])
        print('  top: %.2f m up (seen from %.1f m)' % (high + dist * d[1] / math.hypot(d[0], d[2]), dist))
