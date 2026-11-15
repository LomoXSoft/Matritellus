"""Heights of the game's ground round the old bridge of the Arroyuelo Medio, in the bridge's own frame, and the houses
that stand along the sunk bed with their floor levels.   python tools/puente/alturas.py [map.json]

Frame: origin at the middle of the bridge, x across the bed (towards the east row of houses), z along it (towards
the crossroads with Matías Pérez; the Calle del Santo is at about z = -49).
"""
import json, math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
m = json.load(open(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', 'godot', 'data', 'map.json'), encoding='utf8'))
O = (-149.45, -261.31)   # the middle of the bridge (tools/puente/resecar.py)
U = (0.443, 0.896)          # along the bed, towards the crossroads
A = (0.896, -0.443)         # across it, towards the east row
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


def world(x, z):
    return O[0] + A[0] * x + U[0] * z, O[1] + A[1] * x + U[1] * z


def local(wx, wz):
    dx, dz = wx - O[0], wz - O[1]
    return dx * A[0] + dz * A[1], dx * U[0] + dz * U[1]


if __name__ == '__main__':
    print('ground (m) in the frame; columns: x across = -8 -6 -4.5 -3 0 3 4.5 6 8')
    for z in range(-60, 31, 5):
        print('z %4d  ' % z + ' '.join('%6.2f' % height(*world(x, z)) for x in (-8, -6, -4.5, -3, 0, 3, 4.5, 6, 8)))
    print('houses built by hand near it (id, base, front from..to in the frame):')
    for h in m.get('houses', []):
        o, u = h['o'], h['u']
        a = local(o[0], o[1]); b = local(o[0] + u[0] * h['len'], o[1] + u[1] * h['len'])
        if -70 < (a[1] + b[1]) / 2 < 35 and abs((a[0] + b[0]) / 2) < 22:
            print('  %-16s base %6.2f  h %5.2f  front (%.1f, %.1f) .. (%.1f, %.1f)   ground at its middle %.2f' % (h['id'], h.get('base', 0), h.get('h', 0), a[0], a[1], b[0], b[1], height((o[0] + u[0] * h['len'] / 2), (o[1] + u[1] * h['len'] / 2))))
    print('walls of the generic houses near the bed (style, from..to in the frame, level, height):')
    for st, (ws, ys) in enumerate(zip(m['walls'], m['wall_y'])):
        for k in range(len(ys)):
            x1, z1, x2, z2, h = ws[7 * k:7 * k + 5]
            a, b = local(x1, z1), local(x2, z2)
            mx, mz = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
            if -62 < mz < 26 and abs(mx) < 9 and math.hypot(a[0] - b[0], a[1] - b[1]) > 1.5:
                print('  st %2d  (%6.1f, %6.1f) .. (%6.1f, %6.1f)  level %5.2f  h %4.1f   ground there %5.2f' % (st, a[0], a[1], b[0], b[1], ys[k], h, height((x1 + x2) / 2, (z1 + z2) / 2)))
