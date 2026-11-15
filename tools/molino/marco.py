"""The mill's own frame: from the middle of the mill, x along the north wall of the corral (east, a little south: the
whole place is turned 14.5 degrees clockwise from the map), z towards the corral (south, a little west). Heights are
from the floor of the yard.

    python tools/molino/marco.py w x,z ...     spots of the map -> in the frame
    python tools/molino/marco.py l x,z ...     spots in the frame -> on the map
"""
import sys
M = (-278.0, -729.1)
U = (0.96823, 0.25006)
N = (-U[1], U[0])
def to_local(p): return ((p[0] - M[0]) * U[0] + (p[1] - M[1]) * U[1], (p[0] - M[0]) * N[0] + (p[1] - M[1]) * N[1])
def to_map(q): return (M[0] + U[0] * q[0] + N[0] * q[1], M[1] + U[1] * q[0] + N[1] * q[1])
if __name__ == '__main__':
    for a in sys.argv[2:]:
        p = tuple(map(float, a.split(',')))
        q = to_local(p) if sys.argv[1] == 'w' else to_map(p)
        print('%s -> (%.2f, %.2f)' % (a, q[0], q[1]))
