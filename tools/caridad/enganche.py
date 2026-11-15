"""What the island of the hermitage of the Caridad adds to godot/scripts/selftest.gd: the mode --caridad (ten pictures and
its checks) and _caridad_checks in the full run. Already applied; kept to show what was added and to apply it again.

    python tools/caridad/enganche.py
"""
import io, os
p = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'godot', 'scripts', 'selftest.gd')
s = io.open(p, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in s else '\n'
s = s.replace('\r\n', '\n')
if '_caridad_checks' in s:
    raise SystemExit('already applied')
def sub(a, b, n=1):
    global s
    assert s.count(a) == n, (s.count(a), a[:70])
    s = s.replace(a, b)

checks = '''## The hermitage of the Caridad with its square, the park of the fountain and the nursery (caridad.gd): built, its walls
## solid, its square a floor over the ground, nothing of it in a roadway.
func _caridad_checks() -> void:
	var ca = g.world.caridad
	_check(ca != null and ca.pieces > 250, "the hermitage of the Caridad, its square, its park and the nursery are built by hand (%d pieces)" % (ca.pieces if ca != null else 0))
	if ca == null:
		return
	var space := get_tree().root.get_world_3d().direct_space_state
	var ray := func(a: Vector2, b: Vector2, h: float) -> bool:
		var p: Vector2 = ca.spot(a.x, a.y)
		var q: Vector2 = ca.spot(b.x, b.y)
		return not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, ca.level + h, p.y), Vector3(q.x, ca.level + h, q.y), 1)).is_empty()
	# the hermitage, the body at its corner, the nursery, the wall over the avenue and the railings of the yard all stop you
	var wz: float = ca.wall_z(20.0)
	var shut: bool = ray.call(Vector2(5.0, 3.0), Vector2(5.0, -3.0), 2.0) and ray.call(Vector2(26.0, 3.0), Vector2(26.0, -3.0), 2.0) and ray.call(Vector2(38.0, -3.0), Vector2(38.0, -12.0), ca.fn + 1.0)
	shut = shut and ray.call(Vector2(20.0, wz + 2.0), Vector2(20.0, wz - 2.0), ca.sq(20.0) - 0.5) and ray.call(Vector2(40.0, 4.0), Vector2(40.0, -1.0), ca.fn + 0.6)
	var on_floor: float = MapData.foot(ca.spot(10.0, 8.0)) - ca.level - ca.sq(10.0)
	var raised: float = ca.level + ca.sq(10.0) - MapData.height(ca.spot(10.0, wz + 2.5))
	var nearest := 99.0
	for q in ca.yard:
		var d: float = MapData.road_edge_dist(q)
		if MapData.road_hit != null and MapData.road_hit.road["k"] == 0:          # (to the roadway as it is drawn; its own footpaths do not count)
			d += MapData.road_hit.hw - MapData.fitted_hw(MapData.road_hit)
			nearest = minf(nearest, d)
	_check(shut and absf(on_floor) < 0.06 and raised > 0.8 and raised < 3.2 and nearest > 0.0,
		("" if shut else "(NOT SOLID) ") + "its walls stop you; its square is a floor you walk on (%.2f m off), %.1f m over the avenue's pavement; nothing of it stands in a roadway (the nearest is %.1f m from one)" % [on_floor, raised, nearest])
	var trees := 0
	for t in MapData.trees:
		var q: Vector3 = ca.to_local(Vector3(t[0], ca.level, t[1]))
		if q.x > -30.0 and q.x < 50.0 and q.z > -8.0 and q.z < 12.0 and absf(q.x - 10.0) < 45.0:
			trees += 1
	_check(trees == 0 and MapData.room_at(ca.spot(11.0, 1.5)) < 3.0 and absf(MapData.foot(ca.door) - ca.level - ca.sq(11.5)) < 0.06,
		"the map's own trees are gone from the island (%d left), the map knows the hermitage stands there (%.1f m of room at its wall), and its door gives on to the square's floor" % [trees, MapData.room_at(ca.spot(11.0, 1.5))])

'''
a = "## The nursery school of the Calle del Palo (calasanz.gd): the house, its yard a step above the street behind its\n"
sub(a, checks + a)
mode = '''	if OS.get_cmdline_user_args().has("--caridad"):       # just the island of the hermitage of the Caridad: from the avenue, the hermitage, the cross, the nursery, the fountain, from the air
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		g.set_time(12.5)
		var ca = g.world.caridad
		if ca == null:
			print("CARIDAD FAILED (the map was baked without it)")
			get_tree().quit(1)
			return
		for v in [["avenida", Vector2(12.0, 25.5), 1.7, Vector2(12.0, 0.0), 5.0, 75.0], ["poniente", Vector2(-15.0, -7.5), 1.7, Vector2(0.0, -6.5), 3.6, 75.0], ["columnas", Vector2(-9.5, -16.5), 1.7, Vector2(-1.0, -9.0), 3.0, 75.0],
				["fuente", Vector2(-18.5, 9.5), 1.7, Vector2(-10.2, 3.2), 0.9, 70.0], ["rollo_columnas", Vector2(-7.0, -25.5), 1.8, Vector2(-3.4, -9.0), 2.4, 75.0], ["rollo_casa", Vector2(13.0, -31.5), 1.7, Vector2(12.5, -22.0), 2.4, 85.0], ["ermita", Vector2(11.5, 11.5), 3.2, Vector2(11.5, 0.0), 4.0, 75.0],
				["paseo", Vector2(36.0, 4.5), 3.0, Vector2(8.0, 8.5), 2.6, 80.0], ["cruz", Vector2(21.5, 5.5), 3.2, Vector2(12.7, 11.4), 3.0, 70.0], ["guarderia", Vector2(36.0, 5.0), 3.0, Vector2(37.0, -6.0), 3.8, 85.0], ["patio", Vector2(52.5, 3.5), 4.2, Vector2(40.0, -3.0), 2.6, 70.0],
				["peso", Vector2(61.5, 5.0), 1.7, Vector2(40.0, 0.0), 4.0, 70.0], ["rollo", Vector2(33.0, -35.4), 1.7, Vector2(32.6, -28.4), 2.4, 90.0], ["aire", Vector2(10.0, 46.0), 40.0, Vector2(10.0, -6.0), 0.0, 60.0]]:
			var eye: Vector2 = ca.spot(v[1].x, v[1].y)
			var at: Vector2 = ca.spot(v[3].x, v[3].y)
			g.player.p = ca.spot(10.0, 90.0)
			g.cam.position = Vector3(eye.x, MapData.height(eye) + v[2], eye.y)
			g.cam.look_at(Vector3(at.x, MapData.height(at) + v[4], at.y))
			g.cam.fov = v[5]
			await _frames(6)
			await _shot("caridad_%s" % v[0])
		g.phase = "free"
		await _caridad_checks()
		print("CARIDAD %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
'''
a = '	if OS.get_cmdline_user_args().has("--calasanz"):      # just the nursery school'
sub(a, mode + a)
sub("\n\tawait _farmacia_checks()\n", "\n\tawait _farmacia_checks()\n\tawait _caridad_checks()\n")
io.open(p, 'w', encoding='utf-8', newline='').write(s.replace('\n', nl))
print('ok')
