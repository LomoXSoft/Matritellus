"""Hooks the Travesía del Clavel (godot/scripts/travesia.gd) into the shared files, by exact insertions:

    python tools/travesia/enganche.py            tools/bake_godot.py, map_data.gd, world.gd, empedrado.gd, selftest.gd

Each insertion is made once (it is skipped where its text is already there). Tell Sistemas and Texturas before running
it, and before the bake that follows (python tools/bake_godot.py; rehearse it first: tools/colegio/ensayo.py).
"""
import io, os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')

BAKE_EDITS = [
    ("# ...and streets paved like the Calle Real -- setts down the middle, brick along the houses, all at one level -- that cars",
     """# ...and the Travesía del Clavel, the alley between the Calle de San Rafael and the Calle del Clavel (godot/scripts/
# travesia.gd; the user, 21 November 2026: "que sea peatonal"): a walk for people on foot raised over both streets. A
# footpath closed to traffic that travesia.gd floors itself ("paved": 5), with a car street's corridor: no house moves.
_travesia_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'travesia.gd')
TRAVESIA = os.path.exists(_travesia_gd) and 'const READY := true' in open(_travesia_gd, encoding='utf-8').read()
if TRAVESIA:
    for r in roads:
        if r['n'] == 'Travesía del Clavel' and r['k'] == 0:
            r.update(k=2, h='pedestrian', paved=5)
            r.pop('ow', None)
            print('the Travesía del Clavel: a raised walk, closed to traffic (%d nodes)' % len(r['p']))
# ...and streets paved like the Calle Real -- setts down the middle, brick along the houses, all at one level -- that cars"""),
    ("""    RIZE_RCS, rize, rize_built = set(), {}, []
""",
     """    RIZE_RCS, rize, rize_built = set(), {}, []
# The Travesía del Clavel (above; referencias/travesia_clavel/): Catastro has the row on its west side as a strip (part 2
# of 4494604) drawn 1.4 to 5 m short of the alley -- the aerial photo has its front 7 m from the east row's all the way.
# That strip is not raised: travesia.gd builds the row where it stands, and the white house on the corner of the Calle
# del Clavel beside it. (Part 1 of that parcel, on the Clavel, stays.) Its frame: s along the east row's front from
# its corner on San Rafael, t west of it.
TRAVESIA_RC = '4494604VJ5649S'
_tv_o, _tv_u = (140.56, -160.80), (0.19084, -0.98162)
def _tv(s, t): return (_tv_o[0] + _tv_u[0] * s + _tv_u[1] * t, _tv_o[1] + _tv_u[1] * s - _tv_u[0] * t)
travesia_zone = Polygon([_tv(-3.0, 6.0), _tv(50.0, 6.0), _tv(50.0, 24.0), _tv(-3.0, 24.0)])      # (where Catastro's strip is)
travesia_built = [Polygon([_tv(0.95, 7.0), _tv(52.9, 7.0), _tv(52.9, 16.5), _tv(0.95, 13.4)]),                               # the west row
                  Polygon([_tv(52.9, 7.0), _tv(63.2, 7.0), _tv(63.6, 12.4), _tv(52.9, 12.4)])]                               # the white house
travesia = {'o': list(_tv_o), 'u': list(_tv_u)}
if not TRAVESIA:      # (not built yet: Catastro's strip stays)
    TRAVESIA_RC, travesia, travesia_built = None, {}, []
"""),
    ("""    if bid in RIZE_RCS: return                                   # ...and the Cafetería Rize and the garage opposite it in its alley
""",
     """    if bid in RIZE_RCS: return                                   # ...and the Cafetería Rize and the garage opposite it in its alley
    if bid == TRAVESIA_RC and travesia_zone.contains(c): return  # ...and the west row of the Travesía del Clavel
"""),
    ("""if rize: block_list.extend(rize_built)              # (the Cafetería Rize, the garage opposite and the wall at the alley's end, likewise)
""",
     """if rize: block_list.extend(rize_built)              # (the Cafetería Rize, the garage opposite and the wall at the alley's end, likewise)
if travesia: block_list.extend(travesia_built)      # (the west row of the Travesía del Clavel and the white house on the Clavel, likewise)
"""),
    ("'rize': rize, 'aceras': aceras", "'rize': rize, 'travesia': travesia, 'aceras': aceras"),
]

GAME_EDITS = {
    'godot/scripts/map_data.gd': [
        ("""	rize = data.get("rize", {})
""",
         """	rize = data.get("rize", {})
	travesia = data.get("travesia", {})
"""),
    ],
    'godot/scripts/world.gd': [
        ("""const RizeS = preload("res://scripts/rize.gd")
""",
         """const RizeS = preload("res://scripts/rize.gd")
const TravesiaS = preload("res://scripts/travesia.gd")
"""),
        ("""["the Cafetería Rize", _build_rize], """, """["the Cafetería Rize", _build_rize], ["the Travesía del Clavel", _build_travesia], """),
        ("""func _build_asador() -> void:
""",
         """func _build_travesia() -> void:
	if MapData.travesia.is_empty():  # (a map baked before it: the alley is still a street for cars)
		return
	travesia = TravesiaS.new()       # (the Travesía del Clavel, a raised walk between San Rafael and the Clavel: travesia.gd)
	travesia.build(self)

func _build_asador() -> void:
"""),
    ],
    'godot/scripts/empedrado.gd': [
        ("""int(r.get("paved", 0)) == 4:   # (only a street made pedestrian: footpaths are narrower; the grey lanes below; the fairground's lay their own asphalt, ferial.gd)""",
         """int(r.get("paved", 0)) >= 4:   # (only a street made pedestrian: footpaths are narrower; the grey lanes below; the fairground's lay their own asphalt, ferial.gd; the Travesía del Clavel is floored by travesia.gd, "paved" 5)"""),
    ],
}

# (lines found by their beginning: each gets a line added after it)
AFTER_LINE = {
    'godot/scripts/map_data.gd': [("var rize: Dictionary = {}", "var travesia: Dictionary = {}    # the Travesía del Clavel, a raised walk for people on foot (travesia.gd): {o: the south end of its east row's front, u: north along it}; empty on a map baked without it")],
    'godot/scripts/world.gd': [("var rize ", "var travesia                    # the Travesía del Clavel, a raised walk between San Rafael and the Clavel, built by hand (travesia.gd)")],
}


def apply(rel, pairs, lines=()):
    p = os.path.join(ROOT, rel)
    s = io.open(p, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in s else '\n'
    s = s.replace('\r\n', '\n')
    for a, b in pairs:
        if b in s:
            continue
        assert s.count(a) == 1, (rel, a[:70], s.count(a))
        s = s.replace(a, b)
    for start, new in lines:
        if new in s:
            continue
        hits = [l for l in s.split('\n') if l.startswith(start)]
        assert len(hits) == 1, (rel, start, len(hits))
        s = s.replace(hits[0] + '\n', hits[0] + '\n' + new + '\n')
    io.open(p, 'w', encoding='utf-8', newline='').write(s.replace('\n', nl))
    print(rel, 'ok')


if __name__ == '__main__':
    apply('tools/bake_godot.py', BAKE_EDITS)
    for rel in GAME_EDITS:
        apply(rel, GAME_EDITS[rel], AFTER_LINE.get(rel, ()))
