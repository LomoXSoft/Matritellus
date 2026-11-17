"""What the block of the Casa Grande, the public library and the school of music and dance adds to the bake
(tools/bake_godot.py): Catastro's parcel of it (4590001, nine parts) is not raised -- cultura.gd builds the three
buildings -- its outline goes into the blocks (the map's drawing, the streets' room), and the map gets its key
("cultura"). Texturas's house of its front on the Calle de los Arcos (arcos_7) hangs from that parcel and goes with it.

    python tools/cultura/enganche.py ensayo OUT.json       the bake with these edits made in memory -> OUT.json (the game's map untouched)
    python tools/cultura/enganche.py aplicar               write them into tools/bake_godot.py (then bake: python tools/bake_godot.py)
"""
import io, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')

OUTLINE = [(118.40, 109.21), (142.44, 113.95), (147.93, 115.54), (160.62, 119.22), (168.34, 121.45), (174.23, 123.16), (175.76, 123.60),
           (175.24, 136.64), (174.13, 136.91), (174.53, 138.74), (174.66, 139.58), (174.84, 141.12), (174.95, 142.51), (174.95, 144.23),
           (174.88, 145.60), (174.65, 147.35), (174.29, 149.20), (173.84, 150.82), (173.46, 152.05), (167.22, 150.10), (159.48, 147.68),
           (157.70, 147.13), (147.46, 145.08), (117.22, 139.04)]

BAKE_EDITS = [
    ("""if not (os.path.exists(_correos_gd) and 'const READY := true' in open(_correos_gd, encoding='utf-8').read()):      # (not built yet: Catastro's block stays)
    CORREOS_RC, correos = None, {}
""", """if not (os.path.exists(_correos_gd) and 'const READY := true' in open(_correos_gd, encoding='utf-8').read()):      # (not built yet: Catastro's block stays)
    CORREOS_RC, correos = None, {}
# The block of the Casa Grande, the public library and the school of music and dance, between the Calle de los
# Arcos, the Calle de Argentina and the Callejón Pando (godot/scripts/cultura.gd; the user, 17 November 2026;
# referencias/cultura/): Catastro's parcel of it (nine parts) is not raised -- cultura.gd builds the three of them, and
# the music school where Catastro has nothing, as the photographs show it -- and Texturas's house of its front on the
# Arcos (arcos_7) goes with it.
CULTURA_RC = '4590001VJ5649S'
cultura_built = Polygon(%r)
cultura = {'o': [118.40, 109.21]}
_cultura_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'cultura.gd')
if not (os.path.exists(_cultura_gd) and 'const READY := true' in open(_cultura_gd, encoding='utf-8').read()):      # (not built yet: Catastro's block stays)
    CULTURA_RC, cultura = None, {}
""" % OUTLINE),
    ("""    if bid == CORREOS_RC: return                                 # ...and the post office of the Calle de Zaragoza
""", """    if bid == CORREOS_RC: return                                 # ...and the post office of the Calle de Zaragoza
    if bid == CULTURA_RC: return                                 # ...and the block of the Casa Grande, the library and the music school
"""),
    ("""if correos: block_list.append(correos_built)        # (the post office, likewise)
""", """if correos: block_list.append(correos_built)        # (the post office, likewise)
if cultura: block_list.append(cultura_built)        # (the block of the Casa Grande, likewise)
"""),
    ("""'correos': correos, """, """'correos': correos, 'cultura': cultura, """),
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
    print('tools/bake_godot.py: the block of the Casa Grande added')


if __name__ == '__main__':
    if sys.argv[1] == 'ensayo':
        ensayo(sys.argv[2])
    elif sys.argv[1] == 'aplicar':
        aplicar()
