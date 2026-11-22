"""Heights of the game's ground round the red corner building of the crossroads of the traffic lights (the house
salvador_24 of the map; "Seguros Sopiss"), a metre out from each of its fronts, and what the map knows of the
pavements and houses beside it.   python tools/cruce/alturas.py [map.json]
"""
import json, math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
m = json.load(open(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', 'godot', 'data', 'map.json'), encoding='utf8'))
rel = m['relief']
g, rx0, rz0, nx, nz, H = rel['g'], rel['x0'], rel['z0'], rel['nx'], rel['nz'], rel['h']


def height(x, z):
    fx = min(max((x - rx0) / g, 0), nx - 1.001); fz = min(max((z - rz0) / g, 0), nz - 1.001)
    i, j = int(fx), int(fz); fx -= i; fz -= j
    o = j * nx + i
    a, c = H[o] * 0.01, H[o + nx + 1] * 0.01
    if fx >= fz:
        b = H[o + 1] * 0.01
        return a + fx * (b - a) + fz * (c - b)
    d = H[o + nx] * 0.01
    return a + fz * (d - a) + fx * (c - d)


NW, NE, SE, SW = (92.34, 58.42), (108.32, 62.26), (108.56, 70.77), (103.82, 72.76)

if __name__ == '__main__':
    for name, a, b in (('north (Salvador), from its west end', NW, NE), ('east (avenue), from the north corner', NE, SE), ('south (Cervantes), from the avenue corner', SE, SW)):
        ln = math.hypot(b[0] - a[0], b[1] - a[1]); u = ((b[0] - a[0]) / ln, (b[1] - a[1]) / ln)
        out = (u[1], -u[0])                      # (to the left of a -> b: outwards, going clockwise seen from above with z south)
        print('%s, %.2f m:' % (name, ln))
        for k in range(0, int(ln) + 2, 2):
            s = min(k, ln)
            p = (a[0] + u[0] * s, a[1] + u[1] * s)
            print('   s %5.2f   at the wall %6.2f   1 m out %6.2f   3 m out %6.2f' % (s, height(*p), height(p[0] + out[0], p[1] + out[1]), height(p[0] + out[0] * 3, p[1] + out[1] * 3)))
    for h in m['houses']:
        if h['id'] in ('salvador_24', 'tinf_c7b'):
            print(h['id'], 'base', h['base'], 'h', h['h'], 'o', h['o'], 'u', h['u'], 'len', h['len'])
    print('raised', type(m['raised']).__name__, str(m['raised'])[:200])
    near = [a for a in m['aceras'] if any(abs(p[0] - 104) < 14 and abs(p[1] - 66) < 12 for p in a['pts'])]
    for a in near:
        pts = [p for p in a['pts'] if abs(p[0] - 104) < 14 and abs(p[1] - 66) < 12]
        print('acera', a['street'], a['side'], 'h', a['h'], 'w', a['w'], len(pts), 'pts', [[round(v, 2) for v in p[:5]] for p in pts[:3]])
