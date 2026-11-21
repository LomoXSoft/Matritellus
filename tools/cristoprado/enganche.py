"""What the hermitage of the Cristo del Prado adds to the bake (tools/bake_godot.py).

Catastro has the hermitage and the old people's home beside it ("en la misma manzana") as one building, 4587301VJ5648N:
its nave is a piece of part 4, the tall crossing is part 3 and the body at the east end is part 1. Those are not raised:
cristoprado.gd builds them. The rest of the parcel (the home: parts 2, 5 and 6, the rest of part 4) stays as it is.
The hermitage's outline goes into the blocks (the map's drawing, the streets' room). The map gets its key
("cristoprado": the nave's south-west corner and the way of its south wall). The bake plants no trees on the pavement
along its south side, on the little square before its front or by the calvario in the park: cristoprado.gd plants its own.

    python tools/cristoprado/enganche.py ensayo OUT.json      the bake with these edits made in memory -> OUT.json (the game's map untouched)
    python tools/cristoprado/enganche.py aplicar              write them into tools/bake_godot.py (then bake: python tools/bake_godot.py)
"""
import io, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')

BUILT = [(318.61, 502.34), (303.46, 494.77), (299.14, 503.37), (314.29, 510.95), (313.94, 511.64), (323.82, 516.57), (324.73, 514.75),
         (332.28, 518.52), (335.2, 512.71), (333.21, 511.71), (333.74, 506.57), (331.63, 501.74), (328.53, 500.19), (326.0, 505.21), (318.93, 501.69)]
ZONE_A = [(288.41, 487.94), (278.79, 507.17), (327.98, 531.78), (337.6, 512.55)]       # (the pavement along the south side and the little square, in the hermitage's frame x -16.5..38.5, z -9..12.5)
ZONE_B = [(336.48, 502.49), (331.78, 511.88), (336.7, 514.34), (341.4, 504.95)]        # (the railed strip by the Calle del Cristo, at the east end)
CALVARIO = (268.1, 495.8)                                                              # (the three crosses in the park, from Street View w1 and w2)

BAKE_EDITS = [
    ("""if not (os.path.exists(_cristobal_gd) and 'const READY := true' in open(_cristobal_gd, encoding='utf-8').read()):      # (not built yet: Catastro's building stays)
    CRISTOBAL_RC, cristobal = None, {}
""", """if not (os.path.exists(_cristobal_gd) and 'const READY := true' in open(_cristobal_gd, encoding='utf-8').read()):      # (not built yet: Catastro's building stays)
    CRISTOBAL_RC, cristobal = None, {}
# The hermitage of the Cristo del Prado, on the Paseo del Cristo (godot/scripts/cristoprado.gd; the user, 21 November
# 2026; referencias/cristoprado/): Catastro has it and the old people's home beside it as one building -- the hermitage's
# parts (its nave, a piece of part 4; the crossing, part 3; the east body, part 1) are not raised, the home's stay.
CRISTOPRADO_RC = '4587301VJ5648N'
cristoprado_built = Polygon(%r)
cristoprado_zone = unary_union([Polygon(%r), Polygon(%r), Point(%r).buffer(3.5)])
cristoprado = {'o': [299.14, 503.37], 'u': [0.894309, 0.44745]}
_cristoprado_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'cristoprado.gd')
if not (os.path.exists(_cristoprado_gd) and 'const READY := true' in open(_cristoprado_gd, encoding='utf-8').read()):      # (not built yet: Catastro's building stays whole)
    CRISTOPRADO_RC, cristoprado, cristoprado_zone = None, {}, Polygon()
""" % (BUILT, ZONE_A, ZONE_B, CALVARIO)),
    ("""    hand = house_of(bid, floors)
""", """    if bid == CRISTOPRADO_RC:               # (the hermitage of the Cristo del Prado: what of the parcel is the hermitage goes, the home stays)
        p = p.difference(cristoprado_built.buffer(0.05, join_style=2)).buffer(-0.2, join_style=2).buffer(0.2, join_style=2)
        if p.is_empty or p.area < 5: continue
    hand = house_of(bid, floors)
"""),
    ("""if cristobal: block_list.append(cristobal_built)    # (the little hermitage of San Cristóbal, likewise)
""", """if cristobal: block_list.append(cristobal_built)    # (the little hermitage of San Cristóbal, likewise)
if cristoprado: block_list.append(cristoprado_built)    # (the hermitage of the Cristo del Prado, likewise)
"""),
    ("""'cristobal': cristobal, """, """'cristobal': cristobal, 'cristoprado': cristoprado, """),
    ("""trees = [t for t in trees if not sebastian_zone.contains(Point(t[0], t[1]))]   # ...and the park of San Sebastián and round its hermitage (sebastian.gd plants its own)
""", """trees = [t for t in trees if not sebastian_zone.contains(Point(t[0], t[1]))]   # ...and the park of San Sebastián and round its hermitage (sebastian.gd plants its own)
trees = [t for t in trees if not cristoprado_zone.contains(Point(t[0], t[1]))]   # ...and round the hermitage of the Cristo del Prado (cristoprado.gd plants its own)
"""),
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
    print('tools/bake_godot.py: the hermitage of the Cristo del Prado added')


if __name__ == '__main__':
    if sys.argv[1] == 'ensayo':
        ensayo(sys.argv[2])
    elif sys.argv[1] == 'aplicar':
        aplicar()
