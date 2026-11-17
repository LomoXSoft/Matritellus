"""What the little hermitage of San Cristóbal adds to the bake (tools/bake_godot.py): Catastro's building of it (4602021,
14 m²) is not raised -- cristobal.gd builds it -- its outline goes into the blocks (the map's drawing, the streets'
room), and the map gets its key ("cristobal": the house's south-west corner and the street's way).

    python tools/cristobal/enganche.py ensayo OUT.json      the bake with these edits made in memory -> OUT.json (the game's map untouched)
    python tools/cristobal/enganche.py aplicar              write them into tools/bake_godot.py (then bake: python tools/bake_godot.py)
"""
import io, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')

HOUSE = [(429.23, -981.43), (427.48, -984.81), (430.69, -986.48), (432.56, -983.16)]

BAKE_EDITS = [
    ("""if not (os.path.exists(_sebastian_gd) and 'const READY := true' in open(_sebastian_gd, encoding='utf-8').read()):      # (not built yet: Catastro's block stays)
    SEBASTIAN_RC, sebastian, sebastian_zone = None, {}, Polygon()
""", """if not (os.path.exists(_sebastian_gd) and 'const READY := true' in open(_sebastian_gd, encoding='utf-8').read()):      # (not built yet: Catastro's block stays)
    SEBASTIAN_RC, sebastian, sebastian_zone = None, {}, Polygon()
# The little hermitage of San Cristóbal, built by the town's people, on the Calle de Ortega y Gasset by the old road
# (godot/scripts/cristobal.gd; the user, 17 November 2026; referencias/cristobal/): Catastro's building of it is not
# raised -- cristobal.gd builds it, its little yard and its walls.
CRISTOBAL_RC = '4602021VJ5740S'
cristobal_built = Polygon(%r)
cristobal = {'o': [429.23, -981.43], 'u': [0.8875, -0.4610]}
_cristobal_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'cristobal.gd')
if not (os.path.exists(_cristobal_gd) and 'const READY := true' in open(_cristobal_gd, encoding='utf-8').read()):      # (not built yet: Catastro's building stays)
    CRISTOBAL_RC, cristobal = None, {}
""" % HOUSE),
    ("""    if bid == SEBASTIAN_RC: return                               # ...and the hermitage of San Sebastián
""", """    if bid == SEBASTIAN_RC: return                               # ...and the hermitage of San Sebastián
    if bid == CRISTOBAL_RC: return                               # ...and the little hermitage of San Cristóbal
"""),
    ("""if sebastian: block_list.extend([sebastian_built, sebastian_chapel])      # (the hermitage of San Sebastián and its little chapel, likewise)
""", """if sebastian: block_list.extend([sebastian_built, sebastian_chapel])      # (the hermitage of San Sebastián and its little chapel, likewise)
if cristobal: block_list.append(cristobal_built)    # (the little hermitage of San Cristóbal, likewise)
"""),
    ("""'sebastian': sebastian, """, """'sebastian': sebastian, 'cristobal': cristobal, """),
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
    print('tools/bake_godot.py: the little hermitage of San Cristóbal added')


if __name__ == '__main__':
    if sys.argv[1] == 'ensayo':
        ensayo(sys.argv[2])
    elif sys.argv[1] == 'aplicar':
        aplicar()
