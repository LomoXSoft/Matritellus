"""What the old school of the Avenida de Juan Carlos I ("el viejo colegio") adds to the shared files of the game:
its block in tools/bake_godot.py (Catastro's parcel not raised, no trees, its building in the streets' clearance),
MapData.colegio, the world's step, and in godot/scripts/selftest.gd the mode --colegio (its pictures and its checks)
and _colegio_checks in the full run. Already applied; kept to show what was added. The map must be baked again after
it (tools/bake_godot.py).

    python tools/colegio/enganche.py
"""
import io, os
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')


def read(p):
    return io.open(os.path.join(ROOT, p), encoding='utf-8', newline='').read()


def write(p, s):
    io.open(os.path.join(ROOT, p), 'w', encoding='utf-8', newline='').write(s)


def edit(p, pairs):
    s = read(p)
    nl = '\r\n' if '\r\n' in s else '\n'
    s = s.replace('\r\n', '\n')
    for a, b in pairs:
        assert s.count(a) == 1, (p, s.count(a), a[:70])
        s = s.replace(a, b)
    write(p, s.replace('\n', nl))


block = '''# The old school of the Avenida de Juan Carlos I, between the Calle del Peso and the Calle de Santa Clara
# (godot/scripts/colegio.gd; the user, 16 November 2026; referencias/colegio_viejo/): Catastro's parts of it are not
# raised -- colegio.gd builds the school and its two towers -- and the map plants no trees in it or in its court.
# The ground is not levelled: colegio.gd lays the court as a floor of its own over it, behind its fence.
COLEGIO_RC = '3891715VJ5639S'
COLEGIO = {'o': (-427.35, 121.61), 'u': (0.9706, -0.2407)}
def _col(pts): return Polygon([(COLEGIO['o'][0] + COLEGIO['u'][0] * x - COLEGIO['u'][1] * z, COLEGIO['o'][1] + COLEGIO['u'][1] * x + COLEGIO['u'][0] * z) for x, z in pts])
colegio_zone = _col(((-0.8, -22.5), (41.2, -22.5), (41.2, 6.0), (38.0, 22.5), (35.5, 24.0), (-0.5, 20.0)))
# what colegio.gd builds on it, as one outline: the streets beside it are only as wide as it leaves them
colegio_built = _col(((0, 0), (40.35, 0), (40.35, -21.7), (32.64, -21.7), (32.64, -20.5), (12.2, -20.5), (12.2, -13.3), (0, -13.3)))
colegio = {'o': list(COLEGIO['o']), 'u': list(COLEGIO['u'])}
_colegio_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'colegio.gd')
if not (os.path.exists(_colegio_gd) and 'const READY := true' in open(_colegio_gd, encoding='utf-8').read()):      # (not built yet: Catastro's block stays)
    COLEGIO_RC, colegio, colegio_zone = None, {}, Polygon()
'''
BAKE_EDITS = [
    ("    SANTAANA_RC, santaana, santaana_zone = None, {}, Polygon()\n", "    SANTAANA_RC, santaana, santaana_zone = None, {}, Polygon()\n" + block),
    ("    if bid == SANTAANA_RC: return                                # ...and the convent of Santa Ana\n",
     "    if bid == SANTAANA_RC: return                                # ...and the convent of Santa Ana\n    if bid == COLEGIO_RC: return                                 # ...and the old school of the Avenida de Juan Carlos I\n"),
    ("if santaana: block_list.append(santaana_built)      # (the convent of Santa Ana: not a block of the map's, but it does narrow its streets)\n",
     "if santaana: block_list.append(santaana_built)      # (the convent of Santa Ana: not a block of the map's, but it does narrow its streets)\nif colegio: block_list.append(colegio_built)        # (the old school, likewise)\n"),
    ("trees = [t for t in trees if not santaana_zone.contains(Point(t[0], t[1]))]     # ...and the convent of Santa Ana\n",
     "trees = [t for t in trees if not santaana_zone.contains(Point(t[0], t[1]))]     # ...and the convent of Santa Ana\ntrees = [t for t in trees if not colegio_zone.contains(Point(t[0], t[1]))]      # ...and the old school and its court (colegio.gd plants its own)\n"),
    ("'santaana': santaana, 'mercamona': mercamona,", "'santaana': santaana, 'mercamona': mercamona, 'colegio': colegio,"),
]
MAP_DATA_EDITS = [
    ("var santaana: Dictionary = {}    # the convent of Santa Ana's", "var colegio: Dictionary = {}     # the old school's (colegio.gd): {o: the south-west corner of its west tower, u: along its front}; empty on a map baked without it\nvar santaana: Dictionary = {}    # the convent of Santa Ana's"),
    ('	santaana = data.get("santaana", {})\n', '	santaana = data.get("santaana", {})\n	colegio = data.get("colegio", {})\n'),
]
WORLD_EDITS = [
    ('const SantaAnaS = preload("res://scripts/santaana.gd")\n', 'const SantaAnaS = preload("res://scripts/santaana.gd")\nconst ColegioS = preload("res://scripts/colegio.gd")\n'),
    ('["the convent of Santa Ana", _build_santaana], ', '["the convent of Santa Ana", _build_santaana], ["the old school", _build_colegio], '),
    ("func _build_santaana() -> void:\n", "func _build_colegio() -> void:\n\tif MapData.colegio.is_empty():    # (a map baked before it: Catastro's block stands there)\n\t\treturn\n\tcolegio = ColegioS.new()        # the old school of the Avenida de Juan Carlos I: its front, its two towers, its court\n\tcolegio.build(self)\n\nfunc _build_santaana() -> void:\n"),
    ("var santaana                    # the convent of Santa Ana, built by hand (santaana.gd)\n", "var santaana                    # the convent of Santa Ana, built by hand (santaana.gd)\nvar colegio                     # the old school of the Avenida de Juan Carlos I, built by hand (colegio.gd)\n"),
]
checks = '''## The old school of the Avenida de Juan Carlos I (colegio.gd): built, its two towers over its body; its fronts and its
## fence solid; its court laid over the ground behind its fence; nothing of it in a roadway; the map knows it.
func _colegio_checks() -> void:
	var co = g.world.colegio
	_check(co != null and co.pieces > 900 and co.trees >= 6 and co.gates.size() == 2 and co.shelter != Vector2.ZERO and co.plate,
		("" if co == null or co.plate else "(NO NAME PLATE) ") + "the old school is built by hand (%d pieces), its name plate of tiles over its door, its court with %d trees and a gate to each side street, the bus shelter on the avenue's pavement" % [co.pieces if co != null else 0, co.trees if co != null else 0])
	if co == null:
		return
	var space := get_tree().root.get_world_3d().direct_space_state
	var ray := func(a: Vector2, b: Vector2, h: float) -> bool:
		var p: Vector2 = co.spot(a.x, a.y)
		var q: Vector2 = co.spot(b.x, b.y)
		return not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, co.level + h, p.y), Vector3(q.x, co.level + h, q.y), 1)).is_empty()
	# its door, its two towers, its two side fronts; and its fence on the avenue and on each side street
	var shut: bool = ray.call(Vector2(co.AXIS, 3.0), Vector2(co.AXIS, -5.0), 1.5) and ray.call(Vector2(3.5, 4.0), Vector2(3.5, -3.0), 1.5) and ray.call(Vector2(36.5, 4.0), Vector2(36.5, -3.0), 1.5)
	shut = shut and ray.call(Vector2(-4.0, -10.5), Vector2(4.0, -10.5), 2.2) and ray.call(Vector2(44.0, -14.0), Vector2(37.0, -14.0), 2.6)
	var fenced: bool = ray.call(Vector2(18.0, 24.0), Vector2(18.0, 16.0), 0.2) and ray.call(Vector2(-3.0, 9.0), Vector2(3.0, 9.0), 0.4) and ray.call(Vector2(43.0, 12.0), Vector2(36.0, 12.0), 0.4)
	_check(shut and fenced, ("" if shut else "(FRONTS NOT SOLID) ") + ("" if fenced else "(FENCE NOT SOLID) ") + "its fronts stop you, and so does the fence of its court on the avenue and on both side streets")
	var nearest := 99.0
	for q in co.yard:
		var d: float = MapData.road_edge_dist(q)
		if MapData.road_hit != null:                # (to the roadway as it is drawn, not to the street's nominal width)
			d += MapData.road_hit.hw - MapData.fitted_hw(MapData.road_hit)
		nearest = minf(nearest, d)
	var south: float = co.level - MapData.height(co.spot(18.0, 21.5))
	_check(nearest > 0.0 and MapData.room_at(co.spot(20.0, -3.0)) < 3.0 and not MapData.colegio.is_empty() and south > 0.3 and south < 3.2,
		"nothing of it stands in a roadway (the nearest is %.1f m from one), the map knows it stands there, and its court lies %.1f m over the avenue's pavement behind the wall of its fence" % [nearest, south + co._cy(Vector2(18.0, 21.5))])

'''
mode = '''	if OS.get_cmdline_user_args().has("--colegio"):       # just the old school of the Avenida de Juan Carlos I: its front, its towers, its door, its two side streets, its court, from the air
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		g.set_time(12.5)
		var co = g.world.colegio
		if co == null:
			print("COLEGIO FAILED (the map was baked without it)")
			get_tree().quit(1)
			return
		for v in [["frente", Vector2(20.0, 31.0), 2.2, Vector2(20.0, 0.0), 6.5, 62.0], ["frente_cerca", Vector2(20.0, 17.0), 1.7, Vector2(20.0, 0.0), 6.0, 85.0], ["puerta", Vector2(20.07, 8.5), 1.7, Vector2(20.07, -1.9), 3.6, 60.0], ["placa", Vector2(20.07, 3.2), 1.7, Vector2(20.07, -1.9), 4.6, 42.0],
				["torre_oeste", Vector2(-6.0, 15.0), 1.7, Vector2(3.5, 0.0), 8.5, 70.0], ["torre_este", Vector2(46.0, 16.0), 1.7, Vector2(36.5, 0.0), 8.5, 70.0], ["arcos", Vector2(-8.0, 7.0), 1.7, Vector2(2.6, -2.2), 13.2, 38.0],
				["peso", Vector2(-7.0, -6.0), 1.7, Vector2(0.0, -6.5), 5.5, 95.0], ["santa_clara", Vector2(46.5, -13.0), 1.7, Vector2(40.35, -13.5), 4.5, 95.0], ["santa_clara_sur", Vector2(45.5, 6.0), 1.7, Vector2(40.0, -8.0), 5.5, 85.0],
				["verja", Vector2(10.0, 26.5), 1.7, Vector2(22.0, 19.0), 0.6, 80.0], ["parada", Vector2(17.6, 29.6), 1.6, Vector2(15.8, 24.0), -0.4, 62.0], ["parada_lado", Vector2(8.2, 27.8), 1.6, Vector2(15.8, 24.6), 0.2, 60.0], ["focos", Vector2(20.0, 33.0), 2.0, Vector2(18.0, 19.5), 4.0, 75.0], ["esquina", Vector2(42.0, 27.0), 1.7, Vector2(28.0, 8.0), 4.0, 80.0], ["pista", Vector2(30.0, 10.0), 6.0, Vector2(22.0, 8.0), -1.0, 85.0],
				["aire", Vector2(20.0, 52.0), 34.0, Vector2(20.0, 2.0), 4.0, 55.0], ["aire_norte", Vector2(20.0, -44.0), 30.0, Vector2(20.0, -6.0), 6.0, 55.0]]:
			var eye: Vector2 = co.spot(v[1].x, v[1].y)
			var at: Vector2 = co.spot(v[3].x, v[3].y)
			g.player.p = co.spot(20.0, 120.0)
			g.cam.position = Vector3(eye.x, MapData.height(eye) + v[2], eye.y)
			g.cam.look_at(Vector3(at.x, co.level + v[4], at.y))
			g.cam.fov = v[5]
			await _frames(6)
			await _shot("colegio_%s" % v[0])
		g.phase = "free"
		await _colegio_checks()
		print("COLEGIO %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
'''
SELFTEST_EDITS = [      # (three small edits in place: other sessions work on this file too)
    ('## The grocer\'s at the point between San José and Santo Domingo (chinos.gd): built on its house of the map, which the\n',
     checks + '## The grocer\'s at the point between San José and Santo Domingo (chinos.gd): built on its house of the map, which the\n'),
    ('	if OS.get_cmdline_user_args().has("--chinos"):', mode + '	if OS.get_cmdline_user_args().has("--chinos"):'),
    ("\n\tawait _chinos_checks()\n", "\n\tawait _chinos_checks()\n\tawait _colegio_checks()\n"),
]

if __name__ == '__main__':
    if '_colegio_checks' in read('godot/scripts/selftest.gd'):
        raise SystemExit('already applied')
    edit('tools/bake_godot.py', BAKE_EDITS)
    edit('godot/scripts/map_data.gd', MAP_DATA_EDITS)
    edit('godot/scripts/world.gd', WORLD_EDITS)
    edit('godot/scripts/selftest.gd', SELFTEST_EDITS)
    print('ok: now bake the map again (python tools/bake_godot.py)')
