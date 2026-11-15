"""What the nursery school of the Calle del Palo adds to godot/scripts/selftest.gd: the mode --calasanz (pictures of
it from the street, the two corners, the yard and the air, and its checks), _calasanz_checks() in the full run, and
views named cz_... in its own frame. Kept as the record of which lines are the school's; run once.

    python tools/calasanz/enganche.py
"""
import os

R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')


def patch(path, pairs):
    s = open(os.path.join(R, path), encoding='utf8').read()
    for old, new in pairs:
        assert s.count(old) == 1, (path, s.count(old), old[:80])
        s = s.replace(old, new)
    open(os.path.join(R, path), 'w', encoding='utf8', newline='\n').write(s)
    print('ok', path)


MODE = '''	if OS.get_cmdline_user_args().has("--calasanz"):      # just the nursery school of the Calle del Palo: its front, its gate, the yard with what is played on, the cabin, from the air
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		g.set_time(11.0)
		var cz = g.world.calasanz
		if cz == null:
			print("CALASANZ FAILED (the map was baked without the school)")
			get_tree().quit(1)
			return
		for v in [["frente", Vector2(11.7, 13.5), 2.3, Vector2(11.7, 0.0), 3.6, 75.0], ["puerta", Vector2(9.6, 8.6), 1.7, Vector2(11.4, 0.0), 2.6, 70.0], ["izquierda", Vector2(-2.0, 12.0), 1.9, Vector2(6.0, 0.0), 3.4, 75.0],
				["derecha", Vector2(27.0, 12.5), 1.9, Vector2(17.0, 0.0), 3.4, 75.0], ["juegos", Vector2(-9.5, 8.5), 2.0, Vector2(-4.2, -3.0), 1.6, 70.0], ["juegos_cerca", Vector2(-6.4, 6.4), 2.4, Vector2(-4.4, -2.6), 1.2, 60.0],
				["esquina", Vector2(-14.0, 6.0), 1.9, Vector2(-2.0, -3.0), 2.6, 75.0], ["caseta", Vector2(31.0, 10.0), 1.9, Vector2(26.5, -3.0), 2.2, 70.0], ["mural", Vector2(40.0, -2.0), 2.4, Vector2(23.4, -3.4), 2.4, 60.0],
				["arco", Vector2(11.7, 5.6), 2.2, Vector2(11.7, -2.0), 2.0, 65.0], ["aire", Vector2(13.0, 26.0), 20.0, Vector2(12.0, -3.0), 1.0, 60.0], ["aire_juegos", Vector2(-10.0, 12.0), 11.0, Vector2(-3.5, -3.0), 0.5, 60.0]]:
			var eye: Vector2 = cz.spot(v[1].x, v[1].y)
			var at: Vector2 = cz.spot(v[3].x, v[3].y)
			g.player.p = cz.spot(12.0, 60.0)
			g.cam.position = Vector3(eye.x, cz.level - cz.RAISE + v[2], eye.y)
			g.cam.look_at(Vector3(at.x, cz.level + v[4], at.y))
			g.cam.fov = v[5]
			await _frames(6)
			await _shot("calasanz_%s" % v[0])
		g.phase = "free"
		await _calasanz_checks()
		print("CALASANZ %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--puente"):        # just the old bridge of the Arroyuelo Medio: with the works round it and the demonstration, then clean, from both ends of the bed, the corner, the deck, the air
'''
CHECKS = '''## The nursery school of the Calle del Palo (calasanz.gd): the house, its yard a step above the street behind its
## wall and railings, and nothing of it in a street.
func _calasanz_checks() -> void:
	var cz = g.world.calasanz
	_check(cz != null and cz.pieces > 900, "the nursery school of the Calle del Palo is built by hand (%d pieces)" % (cz.pieces if cz != null else 0))
	if cz == null:
		return
	var space := get_tree().root.get_world_3d().direct_space_state
	var lv: float = cz.level
	var ray := func(a: Vector2, b: Vector2, h: float) -> bool:
		var p: Vector2 = cz.spot(a.x, a.y)
		var q: Vector2 = cz.spot(b.x, b.y)
		return not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, lv + h, p.y), Vector3(q.x, lv + h, q.y), 1)).is_empty()
	# its wall and railings stop you all along the street and round both corners; so does its gate; and the house itself
	var shut: bool = ray.call(Vector2(3.0, 8.0), Vector2(3.0, 1.0), 0.4) and ray.call(Vector2(30.0, 8.0), Vector2(30.0, 1.0), 0.9) and ray.call(Vector2(10.9, 8.0), Vector2(10.9, 1.0), 0.6)
	shut = shut and ray.call(Vector2(-14.0, -2.0), Vector2(-6.0, -2.0), 0.6) and ray.call(Vector2(40.0, -6.0), Vector2(30.0, -6.0), 0.6) and ray.call(Vector2(5.0, 3.0), Vector2(5.0, -3.0), 1.5)
	var street: float = MapData.height(cz.spot(12.0, 7.5))
	var nearest := 99.0
	for q in cz.yard:
		nearest = minf(nearest, MapData.road_edge_dist(q))
	var flat_lot := 0.0
	for q in [Vector2(-4.0, -2.0), Vector2(12.0, 2.0), Vector2(30.0, -6.0), Vector2(12.0, 6.5), Vector2(-9.0, 6.5), Vector2(36.0, 6.5)]:
		flat_lot = maxf(flat_lot, absf(MapData.height(cz.spot(q.x, q.y)) - street))
	_check(shut and nearest >= 0.0 and flat_lot < 0.15 and absf(lv - street - cz.RAISE) < 0.05,
		"its wall, its railings and its gate keep you out, and the house is solid; its yard is %.2f m above the street, on level ground (%.2f m at worst); nothing of it stands in a street (the nearest to the asphalt is %.1f m off)" % [lv - street, flat_lot, nearest])
	_check(MapData.room_at(cz.spot(12.0, 2.0)) < 3.0 and cz.door.distance_to(cz.spot(10.9, 5.5)) < 0.1 and MapData.road_edge_dist(cz.door) > -1.5,
		"the map knows its plot is taken (%.1f m of room in its yard), and its gate is on the pavement of the Calle del Palo" % MapData.room_at(cz.spot(12.0, 2.0)))

## The old bridge of the Arroyuelo Medio as rebuilt by hand (puente.gd): the bed, its raised pavements, the houses of
'''
patch('godot/scripts/selftest.gd', [
    ('''	if OS.get_cmdline_user_args().has("--puente"):        # just the old bridge of the Arroyuelo Medio: with the works round it and the demonstration, then clean, from both ends of the bed, the corner, the deck, the air
''', MODE),
    ('''## The old bridge of the Arroyuelo Medio as rebuilt by hand (puente.gd): the bed, its raised pavements, the houses of
''', CHECKS),
    ('''	await _arroyuelo_checks()
	var th: Dictionary = MapData.townhall
''', '''	await _arroyuelo_checks()
	await _calasanz_checks()
	var th: Dictionary = MapData.townhall
'''),
    ('''or (label.begins_with("tr_") and g.world.toros != null):''', '''or (label.begins_with("tr_") and g.world.toros != null) or (label.begins_with("cz_") and g.world.calasanz != null):'''),
    ('''(g.world.molino if label.begins_with("ml_") else g.world.toros))        # (ml_...: in the windmill's; tr_...: in the old bullring's)''',
     '''(g.world.molino if label.begins_with("ml_") else (g.world.toros if label.begins_with("tr_") else g.world.calasanz)))        # (ml_...: in the windmill's; tr_...: in the old bullring's; cz_...: in the nursery school's)'''),
])
