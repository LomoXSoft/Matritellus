import io
p = 'godot/scripts/selftest.gd'
s = io.open(p, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in s else '\n'
s = s.replace('\r\n', '\n')
def sub(a, b, n=1):
    global s
    assert s.count(a) == n, (s.count(a), a[:70])
    s = s.replace(a, b)

checks = '''## The pharmacy of the Calle Real, the chemist's on the corner of the Calle de Colón and the brick house to the north
## (farmacia.gd): built, solid from end to end, out of the roadways; and the houses' own script draws nothing there.
func _farmacia_checks() -> void:
	var fa = g.world.farmacia
	_check(fa != null and fa.pieces > 300, "the pharmacy of the Calle Real and its two neighbours are built by hand (%d pieces)" % (fa.pieces if fa != null else 0))
	if fa == null:
		return
	var space := get_tree().root.get_world_3d().direct_space_state
	var ray := func(a: Vector2, b: Vector2, h: float) -> bool:
		var p: Vector2 = fa.spot(a.x, a.y)
		var q: Vector2 = fa.spot(b.x, b.y)
		return not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, fa.level + h, p.y), Vector3(q.x, fa.level + h, q.y), 1)).is_empty()
	# every front stops you: the pharmacy's new northern half too (the map had a yard open to the street there)
	var shut: bool = ray.call(Vector2(2.5, 3.0), Vector2(2.5, -2.0), 1.2) and ray.call(Vector2(7.5, 3.0), Vector2(7.5, -2.0), 1.2) and ray.call(Vector2(12.0, 3.0), Vector2(12.0, -2.0), 1.2)
	shut = shut and ray.call(Vector2(19.0, 3.0), Vector2(19.0, -2.0), 1.2) and ray.call(Vector2(26.0, 3.0), Vector2(26.0, -2.0), 1.4)
	var nearest := 99.0
	for q in fa.yard:
		var d: float = MapData.road_edge_dist(q)
		if MapData.road_hit != null:                # (to the roadway as it is drawn, not to the street's nominal width)
			d += MapData.road_hit.hw - MapData.fitted_hw(MapData.road_hit)
		nearest = minf(nearest, d)
	_check(shut and nearest > 0.2, "its fronts stop you from end to end, and nothing of it stands in a roadway (its nearest corner is %.1f m from one)" % nearest)
	var drawn := 0
	for casa in g.world.casas:
		if casa.id in ["real_22", "real_24", "real_26", "real_30"]:
			drawn += casa.get_child_count()
	_check(drawn == 0 and MapData.road_edge_dist(fa.door) > -1.5 and MapData.room_at(fa.spot(9.0, -2.0)) < 3.0,
		"the houses' own script draws nothing where these stand; the pharmacy's door is on the pavement, and the map knows its northern half is built on (%.1f m of room there)" % MapData.room_at(fa.spot(9.0, -2.0)))

'''
a = "## The nursery school of the Calle del Palo (calasanz.gd): the house, its yard a step above the street behind its\n"
sub(a, checks + a)

mode = '''	if OS.get_cmdline_user_args().has("--farmacia"):      # just the pharmacy of the Calle Real and its neighbours: the corner, each front, the side on Colón, from the air
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		g.set_time(17.0)
		var fa = g.world.farmacia
		if fa == null:
			print("FARMACIA FAILED (the map has no real_26)")
			get_tree().quit(1)
			return
		for v in [["esquina", Vector2(40.0, 2.5), 1.7, Vector2(27.0, -1.0), 3.5, 70.0], ["drogueria", Vector2(27.0, 5.0), 1.7, Vector2(26.4, 0.0), 3.0, 85.0], ["farmacia_sur", Vector2(20.3, 5.2), 1.7, Vector2(19.4, 0.0), 3.8, 95.0],
				["farmacia_norte", Vector2(10.8, 5.2), 1.7, Vector2(10.6, 0.0), 3.8, 95.0], ["puerta", Vector2(19.6, 4.2), 1.7, Vector2(18.2, 0.0), 1.9, 60.0], ["ladrillo", Vector2(3.4, 5.0), 1.7, Vector2(2.9, 0.0), 3.2, 85.0],
				["colon", Vector2(35.6, -6.2), 1.7, Vector2(31.2, -4.7), 3.0, 95.0], ["desde_norte", Vector2(-5.0, 3.6), 1.7, Vector2(12.0, 0.0), 4.0, 70.0], ["desde_sur", Vector2(33.0, 4.6), 1.7, Vector2(16.0, 0.0), 4.2, 75.0],
				["aire", Vector2(15.0, 24.0), 26.0, Vector2(15.0, -4.0), 3.0, 60.0]]:
			var eye: Vector2 = fa.spot(v[1].x, v[1].y)
			var at: Vector2 = fa.spot(v[3].x, v[3].y)
			g.player.p = fa.spot(15.0, 60.0)
			g.cam.position = Vector3(eye.x, MapData.height(eye) + v[2], eye.y)
			g.cam.look_at(Vector3(at.x, fa.level + v[4], at.y))
			g.cam.fov = v[5]
			await _frames(6)
			await _shot("farmacia_%s" % v[0])
		g.phase = "free"
		await _farmacia_checks()
		print("FARMACIA %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
'''
a = '	if OS.get_cmdline_user_args().has("--calasanz"):      # just the nursery school'
sub(a, mode + a)
sub("\n\tawait _calasanz_checks()\n", "\n\tawait _calasanz_checks()\n\tawait _farmacia_checks()\n")
io.open(p, 'w', encoding='utf-8', newline='').write(s.replace('\n', nl))
print('ok')
