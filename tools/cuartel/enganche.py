"""What the Guardia Civil's barracks of the Avenida de la Constitución (the Tricornios') adds to the shared files of the
game: its block in tools/bake_godot.py (Catastro's parcel not raised, no trees, its buildings in the streets'
clearance), MapData.cuartel, the world's step, and in godot/scripts/selftest.gd the mode --cuartel (its pictures and
its checks) and _cuartel_checks in the full run. Already applied; kept to show what was added. Nothing happens on
import: tools/cuartel/ensayo.py uses BAKE_EDITS to rehearse the bake. The map must be baked again after it.

    python tools/cuartel/enganche.py
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


block = '''# The Guardia Civil's barracks of the Avenida de la Constitución, at the corner of the Calle de Víctor Pradera -- the
# Tricornios' in the game (godot/scripts/cuartel.gd; the user, 16 November 2026; referencias/cuartel_tricornios/):
# Catastro's parts of it are not raised -- cuartel.gd builds its four blocks -- and the map plants no trees in it, in
# the apron before it or in its yard. The ground is not levelled.
CUARTEL_RC = '4397001VJ5649N'
CUARTEL = {'o': (46.84, -534.47), 'u': (0.165, 0.986)}
def _cua(pts): return Polygon([(CUARTEL['o'][0] + CUARTEL['u'][0] * x - CUARTEL['u'][1] * z, CUARTEL['o'][1] + CUARTEL['u'][1] * x + CUARTEL['u'][0] * z) for x, z in pts])
cuartel_zone = _cua(((-2.5, 9.5), (37.5, 9.0), (40.5, -1.0), (56.0, -31.0), (47.0, -31.0), (39.5, -35.0), (38.5, -38.6), (36.0, -38.6), (36.0, -48.2), (-2.5, -48.2)))
# what cuartel.gd builds on it, as one outline (its court is shut): the streets beside it are only as wide as it leaves them
cuartel_built = _cua(((0, -1.61), (4.9, -1.61), (4.9, 0), (30.62, 0), (30.62, -1.62), (35.63, -1.62), (35.65, -37.9), (22.0, -37.9), (22.0, -43.6), (13.45, -43.6), (13.45, -47.59), (0, -47.59)))
cuartel = {'o': list(CUARTEL['o']), 'u': list(CUARTEL['u'])}
_cuartel_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'cuartel.gd')
if not (os.path.exists(_cuartel_gd) and 'const READY := true' in open(_cuartel_gd, encoding='utf-8').read()):      # (not built yet: Catastro's block stays)
    CUARTEL_RC, cuartel, cuartel_zone = None, {}, Polygon()
'''
BAKE_EDITS = [
    ("    COLEGIO_RC, colegio, colegio_zone = None, {}, Polygon()\n", "    COLEGIO_RC, colegio, colegio_zone = None, {}, Polygon()\n" + block),
    ("    if bid == COLEGIO_RC: return                                 # ...and the old school of the Avenida de Juan Carlos I\n",
     "    if bid == COLEGIO_RC: return                                 # ...and the old school of the Avenida de Juan Carlos I\n    if bid == CUARTEL_RC: return                                 # ...and the Guardia Civil's barracks\n"),
    ("if colegio: block_list.append(colegio_built)        # (the old school, likewise)\n",
     "if colegio: block_list.append(colegio_built)        # (the old school, likewise)\nif cuartel: block_list.append(cuartel_built)        # (the barracks, likewise)\n"),
    ("trees = [t for t in trees if not colegio_zone.contains(Point(t[0], t[1]))]      # ...and the old school and its court (colegio.gd plants its own)\n",
     "trees = [t for t in trees if not colegio_zone.contains(Point(t[0], t[1]))]      # ...and the old school and its court (colegio.gd plants its own)\ntrees = [t for t in trees if not cuartel_zone.contains(Point(t[0], t[1]))]      # ...and the barracks, its apron and its yard\n"),
    ("'colegio': colegio,", "'colegio': colegio, 'cuartel': cuartel,"),
]
MAP_DATA_EDITS = [
    ("var colegio: Dictionary = {}     # the old school's", "var cuartel: Dictionary = {}     # the barracks' (cuartel.gd): {o: the north end of its main front, u: along that front}; empty on a map baked without it\nvar colegio: Dictionary = {}     # the old school's"),
    ('	colegio = data.get("colegio", {})\n', '	colegio = data.get("colegio", {})\n	cuartel = data.get("cuartel", {})\n'),
]
WORLD_EDITS = [
    ('const ColegioS = preload("res://scripts/colegio.gd")\n', 'const ColegioS = preload("res://scripts/colegio.gd")\nconst CuartelS = preload("res://scripts/cuartel.gd")\n'),
    ('["the old school", _build_colegio], ', '["the old school", _build_colegio], ["the Tricornios\' barracks", _build_cuartel], '),
    ("func _build_colegio() -> void:\n", "func _build_cuartel() -> void:\n\tif MapData.cuartel.is_empty():    # (a map baked before it: Catastro's block stands there)\n\t\treturn\n\tcuartel = CuartelS.new()        # the Guardia Civil's barracks of the Avenida de la Constitución: its four blocks, its way in, its yard\n\tcuartel.build(self)\n\nfunc _build_colegio() -> void:\n"),
    ("var colegio                     # the old school of the Avenida de Juan Carlos I, built by hand (colegio.gd)\n", "var colegio                     # the old school of the Avenida de Juan Carlos I, built by hand (colegio.gd)\nvar cuartel                     # the Tricornios' barracks of the Avenida de la Constitución, built by hand (cuartel.gd)\n"),
]
checks = '''## The Tricornios' barracks of the Avenida de la Constitución (cuartel.gd): built, with its three signs and its bays;
## its fronts, its gate and its yard's wall solid; nothing of it in a roadway; its way in on the avenue and the gate of
## its court on the Calle de Víctor Pradera; its lettering the game's.
func _cuartel_checks() -> void:
	var cu = g.world.cuartel
	_check(cu != null and cu.pieces > 1500 and cu.signs == 3 and cu.bays.size() >= 5 and cu.patrol.has("at"),
		"the Tricornios' barracks is built by hand (%d pieces), its %d signs up, %d bays painted before it and the place of its own car before its steps" % [cu.pieces if cu != null else 0, cu.signs if cu != null else 0, cu.bays.size() if cu != null else 0])
	if cu == null:
		return
	var space := get_tree().root.get_world_3d().direct_space_state
	var ray := func(a: Vector2, b: Vector2, h: float) -> bool:
		var p: Vector2 = cu.spot(a.x, a.y)
		var q: Vector2 = cu.spot(b.x, b.y)
		return not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, cu.level + h, p.y), Vector3(q.x, cu.level + h, q.y), 1)).is_empty()
	# the two bodies of its main front and its steps; its two north fronts; the gate of its court; the wall of its yard
	var shut: bool = ray.call(Vector2(10.0, 6.0), Vector2(10.0, -3.0), 1.5) and ray.call(Vector2(25.0, 6.0), Vector2(25.0, -3.0), 2.5) and ray.call(Vector2(17.76, 8.0), Vector2(17.76, -1.0), 0.5)
	shut = shut and ray.call(Vector2(-4.0, -8.0), Vector2(3.0, -8.0), 1.5) and ray.call(Vector2(-4.0, -35.0), Vector2(3.0, -35.0), 1.5)
	var gated: bool = ray.call(Vector2(-4.0, -18.3), Vector2(4.0, -18.3), 1.2)
	var walled: bool = ray.call(Vector2(47.9, -13.6), Vector2(42.0, -10.5), 0.6) and ray.call(Vector2(37.5, 2.5), Vector2(37.5, -4.5), 0.6)
	_check(shut and gated and walled, ("" if shut else "(FRONTS NOT SOLID) ") + ("" if gated else "(GATE NOT SOLID) ") + ("" if walled else "(YARD WALL NOT SOLID) ")
		+ "its fronts and its steps stop you, and so do the gate of its court and the wall of its yard")
	var nearest := 99.0
	var spots: Array = cu.yard.duplicate()
	if cu.patrol.has("at"):                       # (its own car's place: its two ends)
		spots.append(cu.patrol["at"] + cu.patrol["to"] * 2.3)
		spots.append(cu.patrol["at"] - cu.patrol["to"] * 2.3)
	for q in spots:
		var d: float = MapData.road_edge_dist(q)
		if MapData.road_hit != null:                # (to the roadway as it is drawn, not to the street's nominal width)
			d += MapData.road_hit.hw - MapData.fitted_hw(MapData.road_hit)
		nearest = minf(nearest, d)
	_check(nearest > 0.0 and MapData.room_at(cu.spot(8.0, -1.2)) < 3.0 and not MapData.cuartel.is_empty(),
		"nothing of it stands in a roadway (the nearest is %.1f m from one) and the map knows it stands there" % nearest)
	var front: String = String(MapData.nearest_road(cu.door)["seg"].road["n"])
	var side: String = String(MapData.nearest_road(cu.gate)["seg"].road["n"])
	_check(front.begins_with("Avenida de la Constit") and side.contains("Pradera") and cu.MOTTO == "TODO POR LA PATRIA" and cu.PLAQUE.ends_with("TRICORNIO") and cu.BADGE == "LOS TRICORNIOS",
		"its way in gives on to the %s and the gate of its court on to the %s; its plaque ends \\"...%s\\" and its badge reads %s" % [front, side, cu.PLAQUE.right(13), cu.BADGE])

'''
mode = '''	if OS.get_cmdline_user_args().has("--cuartel"):       # just the Tricornios' barracks: its main front, its way in, its signs, the corner, the Calle de Víctor Pradera and the gate, the yard, from the air
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		g.set_time(12.5)
		var cu = g.world.cuartel
		if cu == null:
			print("CUARTEL FAILED (the map was baked without it)")
			get_tree().quit(1)
			return
		for v in [["frente", Vector2(17.8, 27.0), 1.9, Vector2(17.8, 0.0), 5.0, 62.0], ["entrada", Vector2(17.8, 10.0), 1.7, Vector2(17.76, -2.0), 3.2, 60.0], ["puerta", Vector2(13.0, 6.2), 1.7, Vector2(17.76, -2.0), 2.7, 62.0],
				["rotulos", Vector2(17.76, 9.5), 1.7, Vector2(17.76, -2.0), 4.4, 30.0], ["desde_norte", Vector2(-9.0, 13.0), 1.7, Vector2(14.0, 0.0), 4.5, 70.0], ["desde_sur", Vector2(44.0, 14.0), 1.7, Vector2(22.0, 0.0), 4.5, 70.0],
				["esquina", Vector2(-9.5, 6.5), 1.7, Vector2(2.0, -6.0), 5.0, 80.0], ["norte", Vector2(-6.2, -33.0), 1.7, Vector2(0.0, -34.0), 5.0, 95.0], ["verja", Vector2(-6.0, -18.3), 1.7, Vector2(2.0, -18.3), 2.0, 75.0],
				["norte_largo", Vector2(-8.4, -50.0), 1.7, Vector2(0.0, -26.0), 4.5, 70.0], ["patio_sur", Vector2(51.0, -13.0), 1.7, Vector2(38.0, -20.0), 2.5, 80.0], ["sur", Vector2(46.0, 2.0), 1.7, Vector2(36.0, -8.0), 4.0, 80.0],
				["aire", Vector2(17.8, 46.0), 30.0, Vector2(17.8, -14.0), 0.0, 55.0], ["aire_patio", Vector2(60.0, -70.0), 34.0, Vector2(22.0, -20.0), 0.0, 55.0]]:
			var eye: Vector2 = cu.spot(v[1].x, v[1].y)
			var at: Vector2 = cu.spot(v[3].x, v[3].y)
			g.player.p = cu.spot(17.0, 140.0)
			g.cam.position = Vector3(eye.x, MapData.height(eye) + v[2], eye.y)
			g.cam.look_at(Vector3(at.x, cu.level + v[4], at.y))
			g.cam.fov = v[5]
			await _frames(6)
			await _shot("cuartel_%s" % v[0])
		g.phase = "free"
		await _cuartel_checks()
		print("CUARTEL %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
'''
SELFTEST_EDITS = [      # (three small edits in place: other sessions work on this file too)
    ('## The old school of the Avenida de Juan Carlos I (colegio.gd): built, its two towers over its body; its fronts and its\n',
     checks + '## The old school of the Avenida de Juan Carlos I (colegio.gd): built, its two towers over its body; its fronts and its\n'),
    ('	if OS.get_cmdline_user_args().has("--colegio"):', mode + '	if OS.get_cmdline_user_args().has("--colegio"):'),
    ("\n\tawait _colegio_checks()\n", "\n\tawait _colegio_checks()\n\tawait _cuartel_checks()\n"),
]

if __name__ == '__main__':
    if '_cuartel_checks' in read('godot/scripts/selftest.gd'):
        raise SystemExit('already applied')
    edit('tools/bake_godot.py', BAKE_EDITS)
    edit('godot/scripts/map_data.gd', MAP_DATA_EDITS)
    edit('godot/scripts/world.gd', WORLD_EDITS)
    edit('godot/scripts/selftest.gd', SELFTEST_EDITS)
    print('ok: now bake the map again (python tools/bake_godot.py)')
