"""Houses whose openings do not fit the height of their floor (windows that stand out above the wall or the roof).
Reads the short descriptions of casas_calles.gd the way casas.gd's _unpack does (the front and the "lado" and "quiebro"
lines) and the heights of the baked map.

    python tools/casas/plantas_altas.py [margin in m] [--json out.json]

`margin` (0.0 by default): how far an opening may reach above its floor before the house is listed; a negative one
lists the openings that come within that much of the top too. Boards, patches and the side walls' plain rows of
windows are not looked at: casas.gd keeps them under the wall's top itself (25 Nov 2026). For each house the worst floor is printed:
    (excess, id, height, floors, list, floor, kind, reach, floor height, top floor?)"""
import json, re, sys
P = 'X:/MatritellusGPT/'
USUAL = {'win': [1.1, 1.0, 1.2], 'bal': [1.1, 2.2], 'door': [1.1, 2.3], 'gar': [2.8, 2.6], 'shop': [3.0, 2.6], 'arc': [1.6, 0.1, 2.4]}


def unpack(a):
    spec = {'eaves': a[0], 'floors': []}
    for line in a[1:]:
        into = 'floors'
        if line.startswith('lado '):
            into = 'flank'; line = line[5:].strip(); spec.setdefault('flank', [])
        if line.startswith('quiebro '):
            into = 'turn'; line = line[8:].strip(); spec.setdefault('turn', [])
        if line == 'ciego':
            spec['blind'] = True; continue
        if line == '=':
            spec[into].append(spec[into][-1]); continue
        if line.startswith(('tol=', 'trim=')):
            continue
        segs = line.split('|')
        f = {'open': []}
        for tok in segs[0].split():
            k, _, v = tok.partition('=')
            if k in ('fly', 'h'):
                try: f[k] = float(v)
                except ValueError: pass
        for seg in segs[1:]:
            t = seg.split()
            if not t: continue
            kind = t[0]
            words = [x for x in t[1:] if '=' not in x]
            opts = dict(x.split('=', 1) for x in t[1:] if '=' in x)
            if kind == 'ter':
                if len(words) > 3 and words[3] != '-1': f['canopy'] = True
            elif kind in USUAL and words:
                sizes = list(USUAL[kind])
                for k in range(min(len(sizes), len(words) - 1)):
                    try: sizes[k] = float(words[k + 1])
                    except ValueError: sizes[k] = 0.0
                for at in words[0].split(','):
                    f['open'].append([kind, at] + sizes + [opts])
        spec[into].append(f)
    return spec


def reach(op):
    if op[0] in ('win', 'arc'): return op[3] + op[4]
    if op[0] == 'bal': return 0.04 + op[3]
    return op[3]


def scan():
    m = json.load(open(P + 'godot/data/map.json', encoding='utf-8'))
    H = {h['id']: h for h in m['houses']}
    src = open(P + 'godot/scripts/casas_calles.gd', encoding='utf-8').read()
    rows = []
    for mm in re.finditer(r'^\t"([a-z0-9_]+)": \[(.*?)\],?\s*(?:#.*)?$', src, re.M):
        i = mm.group(1)
        if i not in H: continue
        lines = re.findall(r'"((?:[^"\\]|\\.)*)"', mm.group(2))
        if len(lines) < 2 or lines[0] == 'obra': continue
        spec = unpack(lines)
        n = len(spec['floors'])
        if n == 0: continue
        top = H[i].get('h', 6.2)
        gh = top if n == 1 else spec['floors'][0].get('h', 3.0)
        for lst in ('floors', 'flank', 'turn'):
            for k, f in enumerate(spec.get(lst, [])[:n]):
                fh = gh if k == 0 else (top - gh) / (n - 1)
                best = None
                for op in f['open']:
                    r = reach(op)
                    if best is None or r > best[0]: best = (r, op[0])
                if f.get('canopy') and (best is None or 2.35 > best[0]): best = (2.35, 'ter')
                if best: rows.append((round(best[0] - fh, 2), i, top, n, lst, k + 1, best[1], round(best[0], 2), round(fh, 2), k == n - 1))
    return rows


if __name__ == '__main__':
    a = [x for x in sys.argv[1:] if not x.startswith('--') and not x.endswith('.json')]
    lim = float(a[0]) if a else 0.0
    rows = scan()
    worst = {}
    for r in rows:
        if r[0] > lim and (r[1] not in worst or r[0] > worst[r[1]][0]): worst[r[1]] = r
    out = sorted(worst.values(), reverse=True)
    print(len(out), 'houses with an opening that reaches more than', lim, 'm above its floor')
    for r in out: print(r)
    if '--json' in sys.argv:
        json.dump(rows, open(sys.argv[sys.argv.index('--json') + 1], 'w'))
