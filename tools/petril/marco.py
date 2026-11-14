"""The Petril's own frame: origin at the church's south-west corner, +x east along its south front, +z south (out
into the little square).   python marco.py            prints Catastro's corners in it
                           python marco.py w x,z ...  map -> frame      python marco.py l x,z ...  frame -> map"""
import json, math, sys
O = (-108.9, 261.7)
_d = (-99.9 - O[0], 263.6 - O[1]); _n = math.hypot(*_d)
U = (_d[0] / _n, _d[1] / _n)            # +x of the frame on the map
V = (-U[1], U[0])                       # +z of the frame on the map (to the right of U when z runs south: towards the square)
def to_local(p): return ((p[0] - O[0]) * U[0] + (p[1] - O[1]) * U[1], (p[0] - O[0]) * V[0] + (p[1] - O[1]) * V[1])
def to_map(q): return (O[0] + U[0] * q[0] + V[0] * q[1], O[1] + U[1] * q[0] + V[1] * q[1])
if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] in ('w', 'l'):
        for a in sys.argv[2:]:
            p = tuple(map(float, a.split(',')))
            q = to_local(p) if sys.argv[1] == 'w' else to_map(p)
            print('%s -> (%.2f, %.2f)' % (a, q[0], q[1]))
    else:
        print('U', [round(v, 4) for v in U], 'V', [round(v, 4) for v in V], 'turn', round(math.degrees(math.atan2(U[1], U[0])), 2), 'deg')
        P = json.load(open(sys.argv[1] if len(sys.argv) > 1 else 'petril_partes.json'))          # (Catastro's parts, as tools/catastro leaves them)
        for rc in ('4289026VJ5648N', '4289023VJ5648N', '4289024VJ5648N', '4289022VJ5648N'):
            for p in P['parts']:
                if p['rc'] == rc:
                    print(p['id'][-12:], 'floors', p['floors'], ' '.join('(%.1f,%.1f)' % to_local(q) for q in p['ring']))
