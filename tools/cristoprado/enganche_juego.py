"""What the hermitage of the Cristo del Prado adds to the game's shared scripts (with Sistemas's OK): the map's key in
map_data.gd, the step that builds it in world.gd, its test mode and checks in selftest.gd (kept with LF).

    python tools/cristoprado/enganche_juego.py aplicar
"""
import io, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')
S = os.path.join(ROOT, 'godot', 'scripts')

MAP_DATA = [
    ("""var cristobal: Dictionary = {}   # the little hermitage of San Cristóbal (cristobal.gd): {o: its south-west corner, u: the street's way}; empty on a map baked without it
""", """var cristobal: Dictionary = {}   # the little hermitage of San Cristóbal (cristobal.gd): {o: its south-west corner, u: the street's way}; empty on a map baked without it
var cristoprado: Dictionary = {}   # the hermitage of the Cristo del Prado (cristoprado.gd): {o: the nave's south-west corner, u: its south side's way}; empty on a map baked without it
"""),
    ("""	cristobal = data.get("cristobal", {})
""", """	cristobal = data.get("cristobal", {})
	cristoprado = data.get("cristoprado", {})
"""),
]

WORLD = [
    ("""const MatiasS = preload("res://scripts/matias.gd")
""", """const MatiasS = preload("res://scripts/matias.gd")
const CristopradoS = preload("res://scripts/cristoprado.gd")
"""),
    ("""var matias                      # the house of the Calle de Matías Pérez, built by hand on its house of the map (matias.gd)
""", """var matias                      # the house of the Calle de Matías Pérez, built by hand on its house of the map (matias.gd)
var cristoprado                 # the hermitage of the Cristo del Prado, built by hand (cristoprado.gd)
"""),
    ("""["the house of Matías Pérez", _build_matias], """, """["the house of Matías Pérez", _build_matias], ["the hermitage of the Cristo del Prado", _build_cristoprado], """),
    ("""func _build_matias() -> void:
""", """func _build_cristoprado() -> void:
	if MapData.cristoprado.is_empty(): # (a map baked before it: Catastro's building still stands there whole)
		return
	cristoprado = CristopradoS.new()     # (the hermitage of the Cristo del Prado: cristoprado.gd)
	cristoprado.build(self)

func _build_matias() -> void:
"""),
]

CHECKS = '''## The hermitage of the Cristo del Prado (cristoprado.gd): built where its parts of Catastro's building were (no longer
## raised by the bake; the old people's home beside it still is); its walls stop you; the ground before its two doors is
## free; nothing of it on the asphalt.
func _cristoprado_checks() -> void:
	if MapData.cristoprado.is_empty():              # (a map baked before it: nothing to check yet)
		print("  the hermitage of the Cristo del Prado: not in this map yet")
		return
	var cp = g.world.get("cristoprado")
	_check(cp != null and cp.pieces > 1500 and cp.openings >= 9, "the hermitage of the Cristo del Prado is built by hand (%d pieces, %d windows and doors)" % [(cp.pieces if cp != null else 0), (cp.openings if cp != null else 0)])
	if cp == null:
		return
	var space := get_tree().root.get_world_3d().direct_space_state
	var a: Vector2 = cp.spot(-2.5, -2.5)
	var b: Vector2 = cp.spot(3.0, -2.5)
	var stops: bool = not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(a.x, cp.level + 1.2, a.y), Vector3(b.x, cp.level + 1.2, b.y), 1)).is_empty()
	var free_ := true
	for d: Vector2 in [cp.door, cp.side_door]:
		var q := PhysicsPointQueryParameters3D.new()
		q.position = Vector3(d.x, MapData.foot(d) + 0.9, d.y)
		q.collision_mask = 1
		if not space.intersect_point(q).is_empty():
			free_ = false
	var nearest := 99.0
	var worst := Vector2.ZERO
	for p in cp.yard:
		var dd: float = MapData.road_edge_dist(p)
		if MapData.road_hit != null:
			dd += MapData.road_hit.hw - MapData.fitted_hw(MapData.road_hit)
		if dd < nearest:
			nearest = dd
			worst = p
	_check(stops and free_ and nearest > 0.0, "its walls stop you (%s), the ground before its two doors is free (%s), nothing of it on the asphalt (the nearest %.2f m, at %s)" % [stops, free_, nearest, worst])

'''

MODE = '''	if OS.get_cmdline_user_args().has("--cristoprado"):      # just the hermitage of the Cristo del Prado: its front on the square, the Paseo, the side door, the crossing, the east end on the Calle del Cristo, the bell tower, the calvario, at night, from the air
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		var cp = g.world.get("cristoprado")
		if cp == null:
			print("CRISTOPRADO FAILED (not built: the map was baked without it)")
			get_tree().quit(1)
			return
		for moment in [["", 12.0], ["_noche", 22.0]]:
			g.set_time(moment[1])
			await _frames(4)
			for v in [["frente", cp.spot(-17.0, -4.81), 1.7, cp.spot(0.0, -4.81), 6.5, 72.0], ["portada", cp.spot(-7.0, -4.81), 1.7, cp.spot(0.0, -4.81), 4.6, 62.0],
					["paseo", cp.spot(-8.0, 13.0), 1.7, cp.spot(14.0, -2.0), 6.0, 75.0], ["puerta", cp.spot(10.0, 7.0), 1.7, cp.spot(10.0, 0.0), 3.0, 70.0],
					["crucero", cp.spot(40.0, 13.5), 1.7, cp.spot(22.0, -3.0), 8.0, 72.0], ["cabecera", cp.spot(46.0, -8.0), 1.7, cp.spot(33.0, -6.0), 5.0, 72.0],
					["campanario", cp.spot(-14.0, -2.0), 1.7, cp.spot(1.7, -4.8), 15.0, 55.0], ["calvario", cp.spot(-25.0, 14.0), 1.7, cp.calvario, 1.8, 70.0],
					["aire", cp.spot(-30.0, 40.0), 40.0, cp.spot(15.0, -6.0), 0.0, 60.0]]:
				if moment[0] != "" and v[0] != "frente":
					continue
				var eye: Vector2 = v[1]
				var at: Vector2 = v[3]
				g.player.p = Vector2(240.0, 60.0)
				g.cam.position = Vector3(eye.x, MapData.height(eye) + v[2], eye.y)
				g.cam.look_at(Vector3(at.x, cp.level + v[4], at.y))
				g.cam.fov = v[5]
				await _frames(6)
				await _shot("cristoprado_%s%s" % [v[0], moment[0]])
		g.set_time(12.0)
		g.phase = "free"
		await _cristoprado_checks()
		print("CRISTOPRADO %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
'''

SELFTEST = [
    ("""## The hermitage of San Sebastián and its park (sebastian.gd): built where Catastro's parcel was (no longer raised by
""", CHECKS + """## The hermitage of San Sebastián and its park (sebastian.gd): built where Catastro's parcel was (no longer raised by
"""),
    ("""	if OS.get_cmdline_user_args().has("--sebastian"):""", MODE + """	if OS.get_cmdline_user_args().has("--sebastian"):"""),
    ("""	await _cristobal_checks()
	await _matias_checks()
	await _gacha_checks()
""", """	await _cristobal_checks()
	await _matias_checks()
	await _cristoprado_checks()
	await _gacha_checks()
"""),
]


def edit(name, edits):
    p = os.path.join(S, name)
    s = io.open(p, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in s else '\n'
    s = s.replace('\r\n', '\n')
    for a, b in edits:
        assert s.count(a) == 1, (name, a[:70], s.count(a))
        s = s.replace(a, b)
    io.open(p, 'w', encoding='utf-8', newline='').write(s.replace('\n', nl))
    print(name, 'edited', 'CRLF' if nl == '\r\n' else 'LF')


if __name__ == '__main__' and sys.argv[1:] == ['aplicar']:
    edit('map_data.gd', MAP_DATA)
    edit('world.gd', WORLD)
    edit('selftest.gd', SELFTEST)
