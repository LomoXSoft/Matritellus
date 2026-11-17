"""The game's ground round the hermitage of San Sebastián and its park (MapData.height, the same sampling), in the
hermitage's own frame: origin at its front's south-west corner, x along the front (east-south-east), z out of it
(south-south-west). Prints a grid of heights, and those of the spots given.

    python tools/sebastian/alturas.py [x,z ...]
"""
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
m = json.load(open(os.path.join(HERE, '..', '..', 'godot', 'data', 'map.json'), encoding='utf-8'))
r = m['relief']
g, x0, z0, nx, nz = r['g'], r['x0'], r['z0'], r['nx'], r['nz']
h = [v * 0.01 for v in r['h']]                 # (kept in centimetres)
B = (-95.63, -462.01)
U = (0.93637, 0.35102)


def height(px, pz):
    fx = min(max((px - x0) / g, 0.0), nx - 1.001)
    fz = min(max((pz - z0) / g, 0.0), nz - 1.001)
    i, j = int(fx), int(fz)
    fx -= i; fz -= j
    o = j * nx + i
    a, c = h[o], h[o + nx + 1]
    if fx >= fz:
        b = h[o + 1]
        return a + fx * (b - a) + fz * (c - b)
    d = h[o + nx]
    return a + fz * (d - a) + fx * (c - d)


def world(x, z):
    """the frame's (x, z) on the map (+z comes out of the front)"""
    return (B[0] + U[0] * x - U[1] * z, B[1] + U[1] * x + U[0] * z)


if __name__ == '__main__':
    base = height(*world(6.2, 1.0))
    print('ground at the door (6.2, 1.0): %.2f  (all below relative to it)' % base)
    for a in sys.argv[1:]:
        x, z = map(float, a.split(','))
        print('(%6.1f, %6.1f) map %s: %+.2f' % (x, z, tuple(round(v, 1) for v in world(x, z)), height(*world(x, z)) - base))
    if len(sys.argv) == 1:
        xs = list(range(-30, 26, 4))
        print('   z/x ' + ''.join('%6d' % x for x in xs))
        for z in range(-28, 32, 4):
            print('%6d ' % z + ''.join('%+6.2f' % (height(*world(x, z)) - base) for x in xs))
