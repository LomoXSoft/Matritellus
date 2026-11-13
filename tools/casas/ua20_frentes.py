"""The two parallel streets of the UA-20 development, as the user settled it on 12 November 2026: the southern one is
the Calle de los Segadores (Catastro's "CL B UA-20"; the map's source has no name for it) and the northern one the
Calle de los Labradores (Catastro's "CL C UA-20"; the map's source calls THAT one Segadores, wrongly -- the bake
renames both). Sets their houses' fronts in calles.json where tools/house_street.py's guess does not serve.

  - the 24 terraced houses of 2009 (Labradores 37-48, Segadores 1-23 odd) are all one design, built by
    casas.gd's _adosado: their front is the whole width of the plot, on the line of the garage's door;
  - a new house whose garage stands at the street and whose two floors stand back is two houses to the game:
    <name>g, the low parts ('only': 1), and <name>, the tall ones, on the line of their own wall.

Run it after house_street.py. Prints the table of which side each terraced house has its garage (for casas_calles.gd).
"""
import json, math, os

HERE = os.path.dirname(os.path.abspath(__file__))
path = os.path.join(HERE, 'calles.json')
cal = json.load(open(path, encoding='utf8'))

def frame(hd):
    (lx, lz), (rx, rz) = hd['front']
    ln = math.hypot(rx - lx, rz - lz)
    u = ((rx - lx) / ln, (rz - lz) / ln)
    return (lx, lz), u, (-u[1], u[0])

def spans(name):
    hd = cal[name]
    d = json.load(open(os.path.join(HERE, hd['rc'], 'datos.json'), encoding='utf8'))
    o, u, out = frame(hd)
    rows = []
    for p in d['parts']:
        al = [(q[0] - o[0]) * u[0] + (q[1] - o[1]) * u[1] for q in p['ring']]
        ot = [(q[0] - o[0]) * out[0] + (q[1] - o[1]) * out[1] for q in p['ring']]
        rows.append((p['floors'], min(al), max(al), min(ot), max(ot)))
    return o, u, out, rows

def line(o, u, out, a0, a1, d):
    return [[round(o[0] + u[0] * a0 + out[0] * d, 2), round(o[1] + u[1] * a0 + out[1] * d, 2)],
            [round(o[0] + u[0] * a1 + out[0] * d, 2), round(o[1] + u[1] * a1 + out[1] * d, 2)]]

sides = {}
terraced = ['labradores_%d' % n for n in range(37, 49)] + ['segadores_%d' % n for n in range(1, 24, 2)]
for name in terraced:
    if cal[name].get('whole'):
        continue                                    # (already set: its front is no longer the tool's guess)
    o, u, out, rows = spans(name)
    a0 = min(r[1] for r in rows); a1 = max(r[2] for r in rows); d = max(r[4] for r in rows)
    garage = max((r for r in rows if r[0] == 1), key=lambda r: r[4])
    sides[name] = 'L' if (garage[1] + garage[2]) / 2 < (a0 + a1) / 2 else 'R'
    cal[name] = {'rc': cal[name]['rc'], 'floors': 1, 'front': line(o, u, out, a0, a1, d), 'h': 6.2, 'whole': 1, 'side': sides[name]}
for name in terraced:
    sides[name] = cal[name]['side']

for name in ('labradores_11', 'segadores_6', 'segadores_14'):
    if name + 'g' in cal:
        continue
    o, u, out, rows = spans(name)
    tall = [r for r in rows if r[0] >= 2]
    low_front = max((r for r in rows if r[0] == 1), key=lambda r: r[4])
    rc = cal[name]['rc']
    cal[name + 'g'] = {'rc': rc, 'only': 1, 'front': line(o, u, out, low_front[1], low_front[2], low_front[4]), 'h': 3.1}
    cal[name] = {'rc': rc, 'floors': 2, 'front': line(o, u, out, min(r[1] for r in tall), max(r[2] for r in tall), max(r[4] for r in tall)), 'h': 6.4}

cal['labradores_27']['floors'] = 2
cal['labradores_15']['h'] = 4.8
cal['segadores_20']['h'] = 4.3
cal.pop('labradores_25', None)
json.dump(cal, open(path, 'w', encoding='utf8'), indent=1)
print(len(cal), 'houses in calles.json')
print('const ADOSADOS := {' + ', '.join('"%s": "%s"' % (k, v) for k, v in sides.items()) + '}')
for k in ('labradores_42', 'segadores_9', 'labradores_11', 'labradores_11g', 'segadores_6', 'segadores_6g', 'segadores_14', 'segadores_14g'):
    f = cal[k]['front']
    print(k, 'front %.2f m' % math.dist(f[0], f[1]), {kk: vv for kk, vv in cal[k].items() if kk not in ('front', 'rc')})
