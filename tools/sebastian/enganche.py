"""What the hermitage of San Sebastián and its park add to the bake (tools/bake_godot.py): Catastro's parcel of the
hermitage (4297712, three parts) is not raised -- sebastian.gd builds it -- its outline goes into the blocks (the map's
drawing, the streets' room), the map plants no trees in the park, on the hermitage or on its terrace by the street
(sebastian.gd plants its own), and the map gets its key ("sebastian": the front's south-west corner and its way).

    python tools/sebastian/enganche.py ensayo OUT.json      the bake with these edits made in memory -> OUT.json (the game's map untouched)
    python tools/sebastian/enganche.py aplicar              write them into tools/bake_godot.py (then bake: python tools/bake_godot.py)
"""
import io, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')

NAVE = [(-91.96, -460.60), (-95.63, -462.01), (-86.07, -486.70), (-66.51, -479.88), (-68.25, -477.37), (-69.93, -474.95), (-75.98, -477.64), (-84.80, -457.95)]
PORCH = [(-91.96, -460.60), (-94.23, -454.75), (-89.95, -453.10), (-88.34, -457.24), (-87.69, -459.02)]
CHAPEL = [(-75.96, -464.82), (-79.61, -466.68), (-76.85, -472.09), (-76.13, -471.72), (-75.47, -472.98), (-73.26, -471.85), (-73.91, -470.59), (-73.20, -470.22)]
PARK = [(-124.3, -475.3), (-126.7, -470.7), (-132.8, -459.3), (-138.2, -449.2), (-137.9, -447.2), (-137.0, -444.6), (-135.9, -443.1), (-124.9, -435.4),
        (-108.2, -423.9), (-106.3, -424.2), (-103.1, -424.4), (-101.4, -424.6), (-91.9, -439.0), (-90.0, -442.0), (-81.3, -456.7), (-87.7, -459.0),
        (-90.0, -453.1), (-94.2, -454.7), (-92.0, -460.6), (-95.7, -462.0), (-94.1, -465.9), (-122.8, -475.8)]

BAKE_EDITS = [
    ("""if not (os.path.exists(_cultura_gd) and 'const READY := true' in open(_cultura_gd, encoding='utf-8').read()):      # (not built yet: Catastro's block stays)
    CULTURA_RC, cultura = None, {}
""", """if not (os.path.exists(_cultura_gd) and 'const READY := true' in open(_cultura_gd, encoding='utf-8').read()):      # (not built yet: Catastro's block stays)
    CULTURA_RC, cultura = None, {}
# The hermitage of San Sebastián and the park round it, between the Calle del Santo, its loop and the Calle del
# Descanso (godot/scripts/sebastian.gd; the user, 18 November 2026; referencias/sebastian/): Catastro's parcel of the
# hermitage (three parts) is not raised -- sebastian.gd builds it, its porch, its little chapel and its terrace by the
# street -- and the map plants no trees in the park or round the hermitage (sebastian.gd plants its own). The ground
# is NOT levelled: the front is laid over it, the porch and the round square are level, with steps.
SEBASTIAN_RC = '4297712VJ5649N'
sebastian_built = Polygon(%r).union(Polygon(%r))
sebastian_chapel = Polygon(%r)
sebastian_zone = Polygon(%r).buffer(1.0).union(sebastian_built.buffer(7.0))
sebastian = {'o': [-95.63, -462.01], 'u': [0.93637, 0.35102]}
_sebastian_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'sebastian.gd')
if not (os.path.exists(_sebastian_gd) and 'const READY := true' in open(_sebastian_gd, encoding='utf-8').read()):      # (not built yet: Catastro's block stays)
    SEBASTIAN_RC, sebastian, sebastian_zone = None, {}, Polygon()
""" % (NAVE, PORCH, CHAPEL, PARK)),
    ("""    if bid == CULTURA_RC: return                                 # ...and the block of the Casa Grande, the library and the music school
""", """    if bid == CULTURA_RC: return                                 # ...and the block of the Casa Grande, the library and the music school
    if bid == SEBASTIAN_RC: return                               # ...and the hermitage of San Sebastián
"""),
    ("""if cultura: block_list.append(cultura_built)        # (the block of the Casa Grande, likewise)
""", """if cultura: block_list.append(cultura_built)        # (the block of the Casa Grande, likewise)
if sebastian: block_list.extend([sebastian_built, sebastian_chapel])      # (the hermitage of San Sebastián and its little chapel, likewise)
"""),
    ("""trees = [t for t in trees if not ferial_park.contains(Point(t[0], t[1]))]      # ...and the park of the fairground by the Paseo del Cristo (ferial.gd plants its own)
""", """trees = [t for t in trees if not ferial_park.contains(Point(t[0], t[1]))]      # ...and the park of the fairground by the Paseo del Cristo (ferial.gd plants its own)
trees = [t for t in trees if not sebastian_zone.contains(Point(t[0], t[1]))]   # ...and the park of San Sebastián and round its hermitage (sebastian.gd plants its own)
"""),
    ("""'cultura': cultura, """, """'cultura': cultura, 'sebastian': sebastian, """),
]


def ensayo(out):
    sys.path.insert(0, os.path.join(ROOT, 'tools', 'colegio'))
    import ensayo as E
    src = io.open(E.BAKE, encoding='utf-8').read()
    for a, b in BAKE_EDITS:
        assert src.count(a) == 1, a[:70]
        src = src.replace(a, b)
    a = "path = os.path.join(HERE, '..', 'godot', 'data', 'map.json')"
    assert src.count(a) == 1
    src = src.replace(a, 'path = %r' % os.path.abspath(out))
    g = {'__name__': '__main__', '__file__': os.path.abspath(E.BAKE)}
    exec(compile(src, E.BAKE, 'exec'), g)


def aplicar():
    p = os.path.join(ROOT, 'tools', 'bake_godot.py')
    s = io.open(p, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in s else '\n'
    s = s.replace('\r\n', '\n')
    for a, b in BAKE_EDITS:
        assert s.count(a) == 1, a[:70]
        s = s.replace(a, b)
    io.open(p, 'w', encoding='utf-8', newline='').write(s.replace('\n', nl))
    print('tools/bake_godot.py: the hermitage of San Sebastián and its park added')


if __name__ == '__main__':
    if sys.argv[1] == 'ensayo':
        ensayo(sys.argv[2])
    elif sys.argv[1] == 'aplicar':
        aplicar()
