"""What the supermarket ("Mercamona") adds to the shared files of the game: the map's entry, the world's step, and in
godot/scripts/selftest.gd the mode --mercamona (its pictures and its checks) and _mercamona_checks in the full run.
Already applied; kept to show what was added and to apply it again.

    python tools/mercamona/enganche.py
"""
import io, os
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')


def edit(p, pairs):
    p = os.path.join(ROOT, p)
    s = io.open(p, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in s else '\n'
    s = s.replace('\r\n', '\n')
    for a, b in pairs:
        assert s.count(a) == 1, (p, s.count(a), a[:70])
        s = s.replace(a, b)
    io.open(p, 'w', encoding='utf-8', newline='').write(s.replace('\n', nl))


if '_mercamona_checks' in io.open(os.path.join(ROOT, 'godot/scripts/selftest.gd'), encoding='utf-8').read():
    raise SystemExit('already applied')

edit('godot/scripts/map_data.gd', [
    ("\tsantaana = data.get(\"santaana\", {})\n", "\tsantaana = data.get(\"santaana\", {})\n\tmercamona = data.get(\"mercamona\", {})\n"),
    ("var santaana: Dictionary = {}", "var mercamona: Dictionary = {}   # the supermarket's (mercamona.gd): {o: the shop's north-west corner, u: along its west side, low: its car park's level}; empty on a map baked without it\nvar santaana: Dictionary = {}"),
])
edit('godot/scripts/world.gd', [
    ("const SantaAnaS = preload(\"res://scripts/santaana.gd\")\n", "const SantaAnaS = preload(\"res://scripts/santaana.gd\")\nconst MercamonaS = preload(\"res://scripts/mercamona.gd\")\n"),
    ("[\"the convent of Santa Ana\", _build_santaana], ", "[\"the convent of Santa Ana\", _build_santaana], [\"the supermarket\", _build_mercamona], "),
    ("func _build_santaana() -> void:\n", "func _build_mercamona() -> void:\n\tif MapData.mercamona.is_empty():  # (a map baked before it: Catastro's block stands there)\n\t\treturn\n\tmercamona = MercamonaS.new()    # the supermarket by the old road, and its car park a floor below\n\tmercamona.build(self)\n\nfunc _build_santaana() -> void:\n"),
    ("var santaana                    # the convent of Santa Ana, built by hand (santaana.gd)\n", "var santaana                    # the convent of Santa Ana, built by hand (santaana.gd)\nvar mercamona                   # the supermarket and its car park, built by hand (mercamona.gd)\n"),
])
checks = '''## The supermarket by the old road ("Mercamona", mercamona.gd): built, solid, its car park a floor below the shop and
## running in under its east half, level where the cars stand.
func _mercamona_checks() -> void:
	var mm = g.world.mercamona
	_check(mm != null and mm.pieces > 150, "the supermarket and its car park are built by hand (%d pieces)" % (mm.pieces if mm != null else 0))
	if mm == null:
		return
	var space := get_tree().root.get_world_3d().direct_space_state
	var ray := func(a: Vector2, b: Vector2, h: float) -> bool:
		var p: Vector2 = mm.spot(a.x, a.y)
		var q: Vector2 = mm.spot(b.x, b.y)
		return not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, mm.level + h, p.y), Vector3(q.x, mm.level + h, q.y), 1)).is_empty()
	# the shop stops you from the road and from the car park's upper side; under it you drive in as far as its back wall
	var shut: bool = ray.call(Vector2(35.0, 6.0), Vector2(35.0, -3.0), 1.5) and ray.call(Vector2(80.0, 4.0), Vector2(80.0, -3.0), 1.5) and ray.call(Vector2(-12.0, 8.0), Vector2(-12.0, -4.0), 1.5)
	var under: bool = not ray.call(Vector2(60.0, -50.0), Vector2(60.0, mm.BACK - 1.5), mm.yl + 1.0) and ray.call(Vector2(60.0, mm.BACK - 1.5), Vector2(60.0, mm.BACK + 3.0), mm.yl + 1.0)
	var worst := 0.0                          # the ground where the cars stand: at the car park's level
	for q in [Vector2(mm.un + 4.0, -31.0), Vector2(55.0, -32.0), Vector2(62.0, -34.0), Vector2(56.0, -52.0), Vector2(60.0, -70.0), Vector2(62.0, -88.0), Vector2(60.0, -100.0)]:
		worst = maxf(worst, absf(MapData.height(mm.spot(q.x, q.y)) - mm.level - mm.yl))
	_check(shut and under and worst < 0.06 and mm.yl < -2.9,
		("" if shut else "(NOT SOLID) ") + ("" if under else "(NO WAY IN UNDER IT) ") + "the shop is solid; its car park lies %.1f m below its floor and runs in under it to its back wall, level where the cars stand (%.2f m off at worst)" % [-mm.yl, worst])
	var road: float = MapData.road_edge_dist(mm.door)
	var nearest := 99.0
	for q in mm.yard:
		var d: float = MapData.road_edge_dist(q)
		if MapData.road_hit != null:
			d += MapData.road_hit.hw - MapData.fitted_hw(MapData.road_hit)
		nearest = minf(nearest, d)
	_check(nearest > 0.0 and road > 4.0 and MapData.room_at(mm.spot(40.0, -2.0)) < 3.0 and mm.level - MapData.height(mm.gate) < 2.4 and mm.un < 45.0,
		"nothing of it stands in a roadway (the nearest is %.1f m from one); the map knows the shop is there; its gate is %.1f m below the shop's floor, at the head of the ramp" % [nearest, mm.level - MapData.height(mm.gate)])

'''
mode = '''	if OS.get_cmdline_user_args().has("--mercamona"):     # just the supermarket: from the road, its way in, the dock, the gate and the ramp, the car park, under the shop, from the air
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		g.set_time(12.0)
		var mm = g.world.mercamona
		if mm == null:
			print("MERCAMONA FAILED (the map was baked without it)")
			get_tree().quit(1)
			return
		for v in [["carretera", Vector2(14.0, 26.0), 1.7, Vector2(14.0, 0.0), 4.5, 75.0], ["entrada", Vector2(11.5, 12.5), 1.7, Vector2(11.5, 0.0), 3.6, 80.0], ["oeste", Vector2(40.0, 26.0), 1.7, Vector2(38.0, 0.0), 3.5, 85.0],
				["muelle", Vector2(70.0, 22.0), 1.7, Vector2(74.0, 0.0), 3.6, 80.0], ["norte", Vector2(-30.0, -20.0), 1.7, Vector2(-4.0, -22.0), 4.5, 75.0], ["puerta_coches", Vector2(-9.0, -47.0), 1.7, Vector2(10.0, -45.0), 0.5, 80.0],
				["rampa", Vector2(1.0, -42.0), 1.7, Vector2(40.0, -46.0), -2.5, 80.0], ["aparcamiento", Vector2(66.0, -100.0), 1.7, Vector2(30.0, -40.0), 1.5, 80.0], ["bajo_tienda", Vector2(45.0, -58.0), 1.6, Vector2(36.0, -30.0), -1.0, 80.0],
				["dentro", Vector2(60.0, -34.0), 1.5, Vector2(20.0, -31.0), -1.6, 85.0], ["este", Vector2(26.0, -112.0), 1.7, Vector2(40.0, -39.0), 2.0, 75.0], ["aire", Vector2(40.0, -150.0), 70.0, Vector2(40.0, -40.0), 0.0, 55.0]]:
			var eye: Vector2 = mm.spot(v[1].x, v[1].y)
			var at: Vector2 = mm.spot(v[3].x, v[3].y)
			g.player.p = mm.spot(40.0, 150.0)
			g.cam.position = Vector3(eye.x, MapData.height(eye) + v[2], eye.y)
			g.cam.look_at(Vector3(at.x, mm.level + v[4], at.y))
			g.cam.fov = v[5]
			await _frames(6)
			await _shot("mercamona_%s" % v[0])
		g.phase = "free"
		await _mercamona_checks()
		print("MERCAMONA %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
'''
edit('godot/scripts/selftest.gd', [
    ("## The nursery school of the Calle del Palo (calasanz.gd): the house, its yard a step above the street behind its\n", checks + "## The nursery school of the Calle del Palo (calasanz.gd): the house, its yard a step above the street behind its\n"),
    ('	if OS.get_cmdline_user_args().has("--calasanz"):      # just the nursery school', mode + '	if OS.get_cmdline_user_args().has("--calasanz"):      # just the nursery school'),
    ("\n\tawait _santaana_checks()\n", "\n\tawait _santaana_checks()\n\tawait _mercamona_checks()\n"),
])
print('ok')
