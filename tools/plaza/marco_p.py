"""The Plaza del Ayuntamiento's own frame (MapData.townhall): the origin is the middle of the town hall's front,
+u runs along it (towards the Calle de Zaragoza), +n points out of it into the square.
    python marco_p.py w x,z ...   map -> frame        python marco_p.py l u,n ...   frame -> map"""
import sys
M = (-162.26, -72.25)
U = (0.9049, 0.4256)
N = (-U[1], U[0])
def to_local(p): return ((p[0] - M[0]) * U[0] + (p[1] - M[1]) * U[1], (p[0] - M[0]) * N[0] + (p[1] - M[1]) * N[1])
def to_map(q): return (M[0] + U[0] * q[0] + N[0] * q[1], M[1] + U[1] * q[0] + N[1] * q[1])
if __name__ == '__main__':
    for a in sys.argv[2:]:
        p = tuple(map(float, a.split(',')))
        q = to_local(p) if sys.argv[1] == 'w' else to_map(p)
        print('%s -> (%.2f, %.2f)' % (a, q[0], q[1]))
