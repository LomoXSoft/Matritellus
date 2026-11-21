"""What the old people's home of the Cristo del Prado adds to the game's shared scripts (with Sistemas's OK): the map's
key in map_data.gd, the step that builds it in world.gd (after the hermitage), its test mode and checks in selftest.gd.

    python tools/residencia/enganche_juego.py aplicar
"""
import io, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')
S = os.path.join(ROOT, 'godot', 'scripts')

MAP_DATA = [
    ("""var cristoprado: Dictionary = {}   # the hermitage of the Cristo del Prado (cristoprado.gd): {o: the nave's south-west corner, u: its south side's way}; empty on a map baked without it
""", """var cristoprado: Dictionary = {}   # the hermitage of the Cristo del Prado (cristoprado.gd): {o: the nave's south-west corner, u: its south side's way}; empty on a map baked without it
var residencia: Dictionary = {}   # the old people's home beside it (residencia.gd): {o: its frame's origin}; empty on a map baked without it
"""),
    ("""	cristoprado = data.get("cristoprado", {})
""", """	cristoprado = data.get("cristoprado", {})
	residencia = data.get("residencia", {})
"""),
]

WORLD = [
    ("""const CristopradoS = preload("res://scripts/cristoprado.gd")
""", """const CristopradoS = preload("res://scripts/cristoprado.gd")
const ResidenciaS = preload("res://scripts/residencia.gd")
"""),
    ("""var cristoprado                 # the hermitage of the Cristo del Prado, built by hand (cristoprado.gd)
""", """var cristoprado                 # the hermitage of the Cristo del Prado, built by hand (cristoprado.gd)
var residencia                  # the old people's home beside it, built by hand (residencia.gd)
"""),
    ("""["the hermitage of the Cristo del Prado", _build_cristoprado], """, """["the hermitage of the Cristo del Prado", _build_cristoprado], ["the old people's home of the Cristo", _build_residencia], """),
    ("""func _build_cristoprado() -> void:
""", """func _build_residencia() -> void:
	if MapData.residencia.is_empty(): # (a map baked before it: Catastro's block of it still stands there)
		return
	residencia = ResidenciaS.new()     # (the old people's home of the Cristo del Prado: residencia.gd)
	residencia.build(self)

func _build_cristoprado() -> void:
"""),
]

CHECKS = '''## The old people's home of the Cristo del Prado (residencia.gd): built where the rest of Catastro's building was (no
## longer raised by the bake); its walls stop you; the ground before its main door is free; nothing of it on the asphalt.
func _residencia_checks() -> void:
	if MapData.residencia.is_empty():               # (a map baked before it: nothing to check yet)
		print("  the old people's home of the Cristo del Prado: not in this map yet")
		return
	var rs = g.world.get("residencia")
	_check(rs != null and rs.pieces > 1500 and rs.openings >= 60, "the old people's home of the Cristo del Prado is built by hand (%d pieces, %d windows and doors)" % [(rs.pieces if rs != null else 0), (rs.openings if rs != null else 0)])
	if rs == null:
		return
	var space := get_tree().root.get_world_3d().direct_space_state
	var a := Vector2(334.0, 470.0)
	var b := Vector2(316.0, 470.0)
	var stops: bool = not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(a.x, MapData.height(a) + 1.5, a.y), Vector3(b.x, MapData.height(a) + 1.5, b.y), 1)).is_empty()
	var q := PhysicsPointQueryParameters3D.new()
	q.position = Vector3(rs.door.x, MapData.foot(rs.door) + 0.9, rs.door.y)
	q.collision_mask = 1
	var free_: bool = space.intersect_point(q).is_empty()
	var nearest := 99.0
	var worst := Vector2.ZERO
	for p in rs.yard:
		var dd: float = MapData.road_edge_dist(p)
		if MapData.road_hit != null:
			dd += MapData.road_hit.hw - MapData.fitted_hw(MapData.road_hit)
		if dd < nearest:
			nearest = dd
			worst = p
	_check(stops and free_ and nearest > 0.0, "its walls stop you (%s), the ground before its main door is free (%s), nothing of it on the asphalt (the nearest %.2f m, at %s)" % [stops, free_, nearest, worst])

'''

MODE = '''	if OS.get_cmdline_user_args().has("--residencia"):      # just the old people's home of the Cristo del Prado: along the east arm of the Calle del Cristo, its main door, the north end, the west arm, the low wing on the square, at night, from the air
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		var rs = g.world.get("residencia")
		if rs == null:
			print("RESIDENCIA FAILED (not built: the map was baked without it)")
			get_tree().quit(1)
			return
		for moment in [["", 12.0], ["_noche", 22.0]]:
			g.set_time(moment[1])
			await _frames(4)
			for v in [["este", Vector2(336.0, 490.0), 1.7, Vector2(320.0, 455.0), 5.0, 75.0], ["entrada", Vector2(334.0, 479.0), 1.7, Vector2(324.5, 476.0), 4.0, 72.0],
					["norte", Vector2(310.0, 424.0), 1.7, Vector2(307.0, 440.0), 6.0, 75.0], ["oeste", Vector2(291.0, 440.0), 1.7, Vector2(300.0, 468.0), 5.0, 75.0],
					["ala", Vector2(281.0, 500.0), 1.7, Vector2(295.0, 487.0), 2.5, 72.0], ["aire", Vector2(360.0, 520.0), 45.0, Vector2(310.0, 468.0), -14.0, 60.0]]:
				if moment[0] != "" and v[0] != "este":
					continue
				var eye: Vector2 = v[1]
				var at: Vector2 = v[3]
				g.player.p = Vector2(240.0, 60.0)
				g.cam.position = Vector3(eye.x, MapData.height(eye) + v[2], eye.y)
				g.cam.look_at(Vector3(at.x, MapData.height(at) + v[4], at.y))
				g.cam.fov = v[5]
				await _frames(6)
				await _shot("residencia_%s%s" % [v[0], moment[0]])
		g.set_time(12.0)
		g.phase = "free"
		await _residencia_checks()
		print("RESIDENCIA %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
'''

SELFTEST = [
    ("""## The hermitage of San Sebastián and its park (sebastian.gd): built where Catastro's parcel was (no longer raised by
""", CHECKS + """## The hermitage of San Sebastián and its park (sebastian.gd): built where Catastro's parcel was (no longer raised by
"""),
    ("""	if OS.get_cmdline_user_args().has("--sebastian"):""", MODE + """	if OS.get_cmdline_user_args().has("--sebastian"):"""),
    ("""	await _cristoprado_checks()
	await _gacha_checks()
""", """	await _cristoprado_checks()
	await _residencia_checks()
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
