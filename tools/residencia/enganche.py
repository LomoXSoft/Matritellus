"""What the old people's home of the Cristo del Prado adds to the bake (tools/bake_godot.py), after the hermitage's own
edits (tools/cristoprado/enganche.py): with the home built by hand too (godot/scripts/residencia.gd), nothing of
Catastro's building 4587301 is raised -- the hermitage and the home are both hand-built --, the home's outlines go
into the blocks, and the map gets its key ("residencia").

    python tools/residencia/enganche.py ensayo OUT.json      the bake with these edits made in memory -> OUT.json (the game's map untouched)
    python tools/residencia/enganche.py aplicar              write them into tools/bake_godot.py (then bake: python tools/bake_godot.py)
"""
import io, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')

NORTH = [(302.77, 434.61), (311.78, 433.23), (318.89, 452.64), (319.3, 454.3), (298.0, 453.0), (297.25, 452.76)]
SOUTH = [(298.0, 453.0), (319.3, 454.3), (320.57, 459.55), (329.48, 496.30), (329.81, 497.64), (328.53, 500.19), (328.20, 500.84), (320.77, 497.43),
         (309.42, 484.58), (308.49, 485.50), (309.20, 483.59), (305.63, 482.28), (299.14, 453.33)]
ROUND = [(318.61, 502.34), (304.80, 495.44), (308.49, 485.50), (309.42, 484.58), (310.42, 483.77), (311.52, 483.12), (312.72, 482.65), (313.97, 482.38),
         (315.24, 482.30), (316.52, 482.42), (318.11, 482.86), (319.27, 483.42), (320.32, 484.15), (321.24, 485.04), (322.03, 486.05), (322.64, 487.18),
         (323.06, 488.38), (323.30, 489.64), (323.34, 490.92), (323.17, 492.19), (322.81, 493.42), (322.27, 494.57), (321.55, 495.63), (320.77, 497.43),
         (328.20, 500.84), (326.0, 505.21), (318.93, 501.69)]
WING = [(303.46, 494.77), (286.53, 487.99), (287.06, 486.25), (292.80, 467.37), (300.96, 470.38), (297.64, 479.34), (305.63, 482.28), (309.20, 483.59),
        (308.49, 485.50), (304.80, 495.44)]

BAKE_EDITS = [
    ("""if not (os.path.exists(_cristoprado_gd) and 'const READY := true' in open(_cristoprado_gd, encoding='utf-8').read()):      # (not built yet: Catastro's building stays whole)
    CRISTOPRADO_RC, cristoprado, cristoprado_zone = None, {}, Polygon()
""", """if not (os.path.exists(_cristoprado_gd) and 'const READY := true' in open(_cristoprado_gd, encoding='utf-8').read()):      # (not built yet: Catastro's building stays whole)
    CRISTOPRADO_RC, cristoprado, cristoprado_zone = None, {}, Polygon()
# ...and the old people's home beside it, the rest of that building (godot/scripts/residencia.gd; the user, 21 November
# 2026: "the rest of the apple"): with it built too, nothing of Catastro's building is raised.
RESIDENCIA_RC = '4587301VJ5648N'
residencia_built = [Polygon(%r), Polygon(%r), Polygon(%r), Polygon(%r)]
residencia = {'o': [312.0, 465.0]}
_residencia_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'residencia.gd')
if not (cristoprado and os.path.exists(_residencia_gd) and 'const READY := true' in open(_residencia_gd, encoding='utf-8').read()):      # (not built yet: the home stays as Catastro's block)
    RESIDENCIA_RC, residencia, residencia_built = None, {}, []
""" % (NORTH, SOUTH, ROUND, WING)),
    ("""    if bid == CRISTOPRADO_RC:               # (the hermitage of the Cristo del Prado: what of the parcel is the hermitage goes, the home stays)
""", """    if bid == RESIDENCIA_RC: continue        # (the home of the Cristo del Prado built by hand as well: nothing of the parcel is raised)
    if bid == CRISTOPRADO_RC:               # (the hermitage of the Cristo del Prado: what of the parcel is the hermitage goes, the home stays)
"""),
    ("""if cristoprado: block_list.append(cristoprado_built)    # (the hermitage of the Cristo del Prado, likewise)
""", """if cristoprado: block_list.append(cristoprado_built)    # (the hermitage of the Cristo del Prado, likewise)
if residencia: block_list.extend(residencia_built)    # (and the old people's home beside it)
"""),
    ("""'cristoprado': cristoprado, """, """'cristoprado': cristoprado, 'residencia': residencia, """),
]


def ensayo(out):
    src = io.open(os.path.join(ROOT, 'tools', 'bake_godot.py'), encoding='utf-8').read()
    for a, b in BAKE_EDITS:
        assert src.count(a) == 1, a[:70]
        src = src.replace(a, b)
    a = "path = os.path.join(HERE, '..', 'godot', 'data', 'map.json')"
    assert src.count(a) == 1
    src = src.replace(a, 'path = %r' % os.path.abspath(out))
    bake = os.path.abspath(os.path.join(ROOT, 'tools', 'bake_godot.py'))
    g = {'__name__': '__main__', '__file__': bake}
    exec(compile(src, bake, 'exec'), g)


def aplicar():
    p = os.path.join(ROOT, 'tools', 'bake_godot.py')
    s = io.open(p, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in s else '\n'
    s = s.replace('\r\n', '\n')
    for a, b in BAKE_EDITS:
        assert s.count(a) == 1, a[:70]
        s = s.replace(a, b)
    io.open(p, 'w', encoding='utf-8', newline='').write(s.replace('\n', nl))
    print("tools/bake_godot.py: the old people's home of the Cristo del Prado added")


if __name__ == '__main__':
    if sys.argv[1] == 'ensayo':
        ensayo(sys.argv[2])
    elif sys.argv[1] == 'aplicar':
        aplicar()
