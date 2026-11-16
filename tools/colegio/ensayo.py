"""A rehearsal of the bake: runs tools/bake_godot.py as it is on disk but writes the map somewhere else, so that what a
rebake would change can be seen before the game's own map is touched. Then compares two maps.

    python tools/colegio/ensayo.py bake OUT.json        tools/bake_godot.py -> OUT.json (godot/data/map.json is not touched)
    python tools/colegio/ensayo.py bake OUT.json con    the same, with enganche.py's edits to the bake made in memory first
    python tools/colegio/ensayo.py diff OLD.json NEW.json [x z radius]
        what differs: relief nodes, clr, roads, trees, outlines, walls, roofs, houses, the keys of hand-built places;
        with x z radius, also where the changed things are, and how many lie within that radius of that spot
"""
import io, json, math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
BAKE = os.path.join(HERE, '..', 'bake_godot.py')


def bake(out, with_edits=False):
    src = io.open(BAKE, encoding='utf-8').read()
    if with_edits:
        import enganche
        for a, b in enganche.BAKE_EDITS:
            assert src.count(a) == 1, a[:60]
            src = src.replace(a, b)
    a = "path = os.path.join(HERE, '..', 'godot', 'data', 'map.json')"
    assert src.count(a) == 1
    src = src.replace(a, 'path = %r' % os.path.abspath(out))
    g = {'__name__': '__main__', '__file__': os.path.abspath(BAKE)}
    exec(compile(src, BAKE, 'exec'), g)


def near(p, at, r):
    return at is None or math.hypot(p[0] - at[0], p[1] - at[1]) <= r


def diff(a, b, at=None, r=0.0):
    A = json.load(open(a, encoding='utf-8'))
    B = json.load(open(b, encoding='utf-8'))
    print('keys only in old:', sorted(set(A) - set(B)), '| only in new:', sorted(set(B) - set(A)))
    ra, rb = A['relief'], B['relief']
    if (ra['nx'], ra['nz']) == (rb['nx'], rb['nz']):
        ch = [(i, y - x) for i, (x, y) in enumerate(zip(ra['h'], rb['h'])) if x != y]
        print('relief: %d of %d heights differ' % (len(ch), len(ra['h'])), ('by up to %.2f m' % (max(abs(d) for _, d in ch) / 100.0)) if ch else '')
        for i, d in ch[:12]:
            print('     at (%.0f, %.0f): %+.2f m' % (ra['x0'] + (i % ra['nx']) * ra['g'], ra['z0'] + (i // ra['nx']) * ra['g'], d / 100.0))
    else:
        print('relief: the grid itself differs')
    print('nodes: %d -> %d, %s' % (len(A['nodes']) // 2, len(B['nodes']) // 2, 'the same' if A['nodes'] == B['nodes'] else 'DIFFERENT'))
    if len(A['clr']) == len(B['clr']):
        ch = [(i, A['clr'][i], B['clr'][i]) for i in range(len(A['clr'])) if A['clr'][i] != B['clr'][i]]
        print('clr: %d of %d differ' % (len(ch), len(A['clr'])))
        for i, x, y in ch[:20]:
            print('     node %d at (%.1f, %.1f): %.1f -> %.1f' % (i, B['nodes'][2 * i], B['nodes'][2 * i + 1], x, y))
    else:
        print('clr: %d -> %d values' % (len(A['clr']), len(B['clr'])))
    print('roads: %d -> %d, %s' % (len(A['roads']), len(B['roads']), 'the same' if A['roads'] == B['roads'] else 'DIFFERENT'))
    print('trees: %d -> %d' % (len(A['trees']), len(B['trees'])))
    for k in ('outlines', 'roofs_gable', 'roofs_flat', 'houses', 'aceras', 'raised', 'areas', 'pois', 'towers'):
        la, lb = A.get(k, []), B.get(k, [])
        def norm(v):                              # (an outline is the same whichever corner it starts at)
            if k == 'outlines':
                pts = sorted(zip(v[0::2], v[1::2]))
                return json.dumps([c for q in pts for c in q])
            return json.dumps(v, sort_keys=True)
        sa = {norm(v) for v in la}
        sb = {norm(v) for v in lb}
        gone, new = [json.loads(v) for v in sa - sb], [json.loads(v) for v in sb - sa]
        print('%s: %d -> %d  (%d gone, %d new)' % (k, len(la), len(lb), len(gone), len(new)))
        if k == 'outlines' and at is not None:
            for name, lst in (('gone', gone), ('new', new)):
                mids = [(sum(o[0::2]) / (len(o) // 2), sum(o[1::2]) / (len(o) // 2)) for o in lst]
                print('     %s: %d within %.0f m of (%.0f, %.0f); the others at %s' % (name, sum(1 for p in mids if near(p, at, r)), r, at[0], at[1], [(round(p[0]), round(p[1])) for p in mids if not near(p, at, r)][:8]))
        if k == 'houses':
            for h in gone[:6] + new[:6]:
                print('     ', h.get('id'), h.get('o'), h.get('len'), h.get('h'), h.get('base'))
    wa = sum(len(w) for w in A['walls']) // 7
    wb = sum(len(w) for w in B['walls']) // 7
    print('walls: %d -> %d' % (wa, wb))
    if at is not None:
        def segs(M):
            out = set()
            for style, w in enumerate(M['walls']):
                for i in range(len(w) // 7):
                    out.add((style,) + tuple(w[i * 7:i * 7 + 7]))
            return out
        sa, sb = segs(A), segs(B)
        for name, lst in (('gone', sa - sb), ('new', sb - sa)):
            far = [s for s in lst if not near((s[1], s[2]), at, r)]
            print('     walls %s: %d, of them %d farther than %.0f m%s' % (name, len(lst), len(far), r, (': ' + str([(round(s[1]), round(s[2])) for s in far][:8])) if far else ''))
    for k in sorted(set(A) | set(B)):
        if isinstance(A.get(k, B.get(k)), dict) and k != 'relief' and A.get(k) != B.get(k):
            print('%s: %s -> %s' % (k, json.dumps(A.get(k))[:120], json.dumps(B.get(k))[:120]))


if __name__ == '__main__':
    if sys.argv[1] == 'bake':
        bake(sys.argv[2], len(sys.argv) > 3 and sys.argv[3] == 'con')
    else:
        at = (float(sys.argv[4]), float(sys.argv[5])) if len(sys.argv) > 6 else None
        diff(sys.argv[2], sys.argv[3], at, float(sys.argv[6]) if len(sys.argv) > 6 else 0.0)
