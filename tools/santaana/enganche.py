"""What the convent of Santa Ana adds to godot/scripts/selftest.gd: the mode --santaana (its pictures and its checks) and
_santaana_checks in the full run. Already applied; kept to show what was added and to apply it again.

    python tools/santaana/enganche.py
"""
import io, os
p = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'godot', 'scripts', 'selftest.gd')
s = io.open(p, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in s else '\n'
s = s.replace('\r\n', '\n')
if '_santaana_checks' in s:
    raise SystemExit('already applied')


def sub(a, b, n=1):
    global s
    assert s.count(a) == n, (s.count(a), a[:70])
    s = s.replace(a, b)


checks = '''## The convent of Santa Ana (santaana.gd): built, solid, out of the roadways; and the Calle de las Monjas before it paved
## in setts and brick but still a street cars drive.
func _santaana_checks() -> void:
	var sa = g.world.santaana
	_check(sa != null and sa.pieces > 150 and sa.friar != null, "the convent of Santa Ana is built by hand (%d pieces), the bronze friar on his pedestal before the church" % (sa.pieces if sa != null else 0))
	if sa == null:
		return
	var space := get_tree().root.get_world_3d().direct_space_state
	var ray := func(a: Vector2, b: Vector2, h: float) -> bool:
		var p: Vector2 = sa.spot(a.x, a.y)
		var q: Vector2 = sa.spot(b.x, b.y)
		return not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, sa.level + h, p.y), Vector3(q.x, sa.level + h, q.y), 1)).is_empty()
	# its front, its church's doorway and end, its north range and its garden wall all stop you
	var shut: bool = ray.call(Vector2(8.0, 3.0), Vector2(8.0, -3.0), 1.5) and ray.call(Vector2(22.0, 3.0), Vector2(22.0, -3.0), 1.5) and ray.call(Vector2(32.0, 0.5), Vector2(32.0, -7.0), 2.0)
	shut = shut and ray.call(Vector2(41.0, 2.0), Vector2(41.0, -5.0), 2.0) and ray.call(Vector2(46.0, -26.0), Vector2(36.0, -26.0), 2.0) and ray.call(Vector2(42.0, -45.0), Vector2(33.0, -45.0), 2.0)
	var nearest := 99.0
	for q in sa.yard:
		var d: float = MapData.road_edge_dist(q)
		if MapData.road_hit != null:                # (to the roadway as it is drawn, not to the street's nominal width)
			d += MapData.road_hit.hw - MapData.fitted_hw(MapData.road_hit)
		nearest = minf(nearest, d)
	_check(shut and nearest > 0.0 and MapData.room_at(sa.spot(15.0, -2.0)) < 3.0,
		("" if shut else "(NOT SOLID) ") + "its walls stop you all round, nothing of it stands in a roadway (the nearest is %.1f m from one), and the map knows it stands there" % nearest)
	var near: Dictionary = MapData.nearest_road(sa.door)
	var seg = near["seg"]
	var north: Dictionary = MapData.nearest_road(sa.spot(75.0, 2.0))
	_check(int(seg.road.get("paved", 0)) == 3 and int(seg.road["k"]) == 0 and MapData.drivable(seg) and int(north["seg"].road.get("paved", 0)) == 0,
		"the Calle de las Monjas is paved in setts and brick before the convent and cars still drive it (%s); past the crossroads it is asphalt again" % String(seg.road["n"]))

'''
a = "## The nursery school of the Calle del Palo (calasanz.gd): the house, its yard a step above the street behind its\n"
sub(a, checks + a)
mode = '''	if OS.get_cmdline_user_args().has("--santaana"):      # just the convent of Santa Ana: its front, its doors, the tower, the church's doorway and end, both streets, from the air
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		g.set_time(10.5)
		var sa = g.world.santaana
		if sa == null:
			print("SANTAANA FAILED (the map was baked without it)")
			get_tree().quit(1)
			return
		for v in [["calle", Vector2(-9.0, 5.2), 1.7, Vector2(14.0, 0.0), 4.6, 75.0], ["frente_sur", Vector2(5.0, 7.4), 1.7, Vector2(5.5, 0.0), 4.2, 90.0], ["puerta", Vector2(15.75, 7.6), 1.7, Vector2(15.75, 0.0), 3.6, 85.0],
				["frente_norte", Vector2(22.0, 7.4), 1.7, Vector2(21.5, 0.0), 4.2, 90.0], ["torre", Vector2(-4.0, 6.0), 1.7, Vector2(8.5, -4.5), 9.5, 70.0], ["compas", Vector2(33.5, 7.2), 1.7, Vector2(31.6, -3.5), 4.0, 85.0],
				["portada", Vector2(31.8, 3.6), 1.7, Vector2(31.4, -3.6), 3.9, 80.0], ["fraile", Vector2(36.6, 3.4), 1.7, Vector2(34.3, -0.7), 2.3, 55.0], ["iglesia", Vector2(47.0, 7.8), 1.7, Vector2(38.0, -2.0), 5.6, 85.0], ["desde_norte", Vector2(58.0, 3.0), 1.7, Vector2(30.0, -1.0), 5.0, 75.0],
				["santiago", Vector2(48.5, -30.0), 1.7, Vector2(41.5, -24.0), 3.4, 95.0], ["suelo", Vector2(12.0, 4.2), 2.6, Vector2(34.0, 3.0), 0.0, 75.0], ["aire", Vector2(20.0, 42.0), 34.0, Vector2(22.0, -14.0), 3.0, 60.0]]:
			var eye: Vector2 = sa.spot(v[1].x, v[1].y)
			var at: Vector2 = sa.spot(v[3].x, v[3].y)
			g.player.p = sa.spot(15.0, 90.0)
			g.cam.position = Vector3(eye.x, MapData.height(eye) + v[2], eye.y)
			g.cam.look_at(Vector3(at.x, sa.level + v[4], at.y))
			g.cam.fov = v[5]
			await _frames(6)
			await _shot("santaana_%s" % v[0])
		g.phase = "free"
		await _santaana_checks()
		print("SANTAANA %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
'''
a = '	if OS.get_cmdline_user_args().has("--calasanz"):      # just the nursery school'
sub(a, mode + a)
sub("\n\tawait _caridad_checks()\n", "\n\tawait _caridad_checks()\n\tawait _santaana_checks()\n")
io.open(p, 'w', encoding='utf-8', newline='').write(s.replace('\n', nl))
print('ok')
