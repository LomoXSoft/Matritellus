"""Heights of the game's ground along the Travesía del Clavel, in the alley's own frame, with the houses of its east row
and where their doors are.   python tools/travesia/alturas.py [map.json]

Frame (travesia.gd's): origin at the south-west corner of the east row's corner house on San Rafael, s north along the
east row's front, t west across the alley (0 at the east row, about 7.2 at the west one).
"""
import json, math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
m = json.load(open(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', 'godot', 'data', 'map.json'), encoding='utf8'))
O = (140.56, -160.80)
END = (152.52, -222.32)
L = math.hypot(END[0] - O[0], END[1] - O[1])
U = ((END[0] - O[0]) / L, (END[1] - O[1]) / L)      # north along the east row
T = (U[1], -U[0])                                   # west across the alley
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


def world(s, t):
    return (O[0] + U[0] * s + T[0] * t, O[1] + U[1] * s + T[1] * t)


def local(x, z):
    return ((x - O[0]) * U[0] + (z - O[1]) * U[1], (x - O[0]) * T[0] + (z - O[1]) * T[1])


if __name__ == '__main__':
    print('U (%.5f, %.5f)  T (%.5f, %.5f)  length %.2f' % (U[0], U[1], T[0], T[1], L))
    print('ground, every 4 m of s, at t = 0, 2, 3.6, 5.5, 7.2:')
    for s in range(-12, 76, 4):
        print('  s %5.1f  ' % s + '  '.join('%6.2f' % height(*world(s, t)) for t in (0.0, 2.0, 3.6, 5.5, 7.2)) + '   (%.1f, %.1f)' % world(s, 3.6))
    print('houses of the alley (door: its s, and the sill = base + 1.4):')
    doors = {'tcl_4': .88, 'tcl_6': .12, 'tcl_8': .88, 'tcl_10': .12, 'tcl_12': .88, 'tcl_14': .12, 'tcl_16': .88, 'tcl_18': .12, 'tcl_20': .88}
    for h in m['houses']:
        if h['id'].startswith('tcl_') or h['id'] in ('rafael_tc2', 'cla_6', 'clavel_11t', 'clavel_9', 'clavel_11', 'clavel_13'):
            o = h['o']; e = (o[0] + h['u'][0] * h['len'], o[1] + h['u'][1] * h['len'])
            line = '  %-11s s %6.2f..%6.2f  t %5.2f..%5.2f  base %.2f  h %.1f' % (h['id'], local(*o)[0], local(*e)[0], local(*o)[1], local(*e)[1], h['base'], h['h'])
            if h['id'] in doors:
                f = doors[h['id']]
                d = (o[0] + h['u'][0] * h['len'] * f, o[1] + h['u'][1] * h['len'] * f)
                line += '   door s %.2f  sill %.2f' % (local(*d)[0], h['base'] + 1.4)
            print(line)
    n = m['nodes']
    for i in (2358, 1027, 2357, 1026, 1111):
        print('  node %d (%.1f, %.1f)  s %.1f t %.1f  ground %.2f' % ((i, n[2 * i], n[2 * i + 1]) + local(n[2 * i], n[2 * i + 1]) + (height(n[2 * i], n[2 * i + 1]),)))
