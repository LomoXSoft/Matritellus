"""Where things on the MasAhorro's front stand, from the bearings read on rumbos.py's pictures: each bearing from a
camera meets the front's line (Catastro's, from its north-east corner towards the north-west one) at a distance s
along it. Two or more cameras for each thing; the spread says how good it is.

    python tools/masahorro/frente.py
"""
import math

NE = (53.45, 518.01)
NW = (25.99, 508.72)
L = math.dist(NE, NW)
U = ((NW[0] - NE[0]) / L, (NW[1] - NE[1]) / L)

CAMS = {'vc': (70.91, 430.39), 'vb': (61.32, 427.92), 'nc': (74.81, 481.97), 'ne': (68.30, 500.61)}
# thing: {camera: bearing}
READ = {
    'NE corner (front face)': {'vc': 190.5, 'vb': 183.0},
    'canopy, east end': {'vc': 195.2, 'vb': 189.3, 'nc': 222.96, 'ne': 245.4},
    'glass, east end': {'vc': 196.3, 'vb': 190.1, 'nc': 225.1, 'ne': 248.1},
    'logo, east end': {'vc': 196.4, 'vb': 189.5, 'nc': 225.2, 'ne': 248.4},
    'logo, west end': {'vc': 203.9, 'vb': 196.9, 'nc': 237.6, 'ne': 261.3},
    'glass, west end': {'vc': 207.0, 'vb': 199.9, 'nc': 243.2, 'ne': 266.6},
    'yellow pilaster, west end': {'nc': 246.1, 'ne': 267.2},
    'canopy, west end': {'vc': 210.3, 'vb': 203.5, 'nc': 247.1, 'ne': 269.6},
    'NW corner (yellow ends)': {'vc': 210.5, 'vb': 203.9},
    'grey gate, west end': {'vc': 212.2, 'vb': 205.7, 'nc': 247.8},
}


OUT = (U[1], -U[0])          # out of the front (north)


def meet(cam, b, dn=0.0, turn=0.0):
    """s along the front where the ray from cam at bearing b (+ turn, the camera's own error) crosses it, with the
    front's line moved dn metres out"""
    d = (math.sin(math.radians(b + turn)), -math.cos(math.radians(b + turn)))
    o = (NE[0] + OUT[0] * dn, NE[1] + OUT[1] * dn)
    det = d[0] * (-U[1]) - d[1] * (-U[0])
    rx, rz = o[0] - cam[0], o[1] - cam[1]
    s = (d[0] * rz - d[1] * rx) / det
    return s


def spread(dn, turns):
    e = 0.0
    for what, bs in READ.items():
        ss = [meet(CAMS[c], b, dn, turns.get(c, 0.0)) for c, b in bs.items()]
        if len(ss) > 1:
            m = sum(ss) / len(ss)
            e += sum((s - m) ** 2 for s in ss)
    return e


if __name__ == '__main__':
    print('front: %.2f m' % L)
    # Google's cameras: each may be turned a little (its heading) and the front may stand off Catastro's line
    best = None
    for dn10 in range(-20, 61, 2):
        dn = dn10 / 10.0
        turns = {c: 0.0 for c in CAMS}
        for _ in range(6):
            for c in CAMS:
                if c == 'vc':
                    continue                   # one camera holds the bearings
                turns[c] = min((t / 10.0 for t in range(-60, 61)), key=lambda t: spread(dn, dict(turns, **{c: t})))
        e = spread(dn, turns)
        if best is None or e < best[0]:
            best = (e, dn, dict(turns))
    e, dn, turns = best
    print('best: front %.1f m out of Catastro\'s line, cameras turned %s, spread %.2f' % (dn, turns, e))
    for what, bs in READ.items():
        ss = {c: meet(CAMS[c], b, dn, turns.get(c, 0.0)) for c, b in bs.items()}
        print('%-26s ' % what + '  '.join('%s %6.2f' % (c, s) for c, s in ss.items()) + '   mean %6.2f' % (sum(ss.values()) / len(ss)))
