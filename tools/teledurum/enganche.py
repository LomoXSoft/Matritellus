"""What the kebab house of the Calle de Santa Ana ("Tele Dürum") adds to the shared files of the game: its house is
handed over in casas_calles.gd ("obra"), the world's step, and in godot/scripts/selftest.gd the mode --teledurum (its
pictures and its checks) and _teledurum_checks in the full run. Already applied; kept to show what was added.

    python tools/teledurum/enganche.py
"""
import io, os, re
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


if '_teledurum_checks' in read('godot/scripts/selftest.gd'):
    raise SystemExit('already applied')

s = read('godot/scripts/casas_calles.gd')
nl = '\r\n' if '\r\n' in s else '\n'
lines = s.replace('\r\n', '\n').split('\n')
hit = [i for i, l in enumerate(lines) if re.match(r'^\t"stana_44": \[', l)]
assert len(hit) == 1, hit
lines[hit[0]] = '\t"stana_44": ["obra"],      # built by hand: teledurum.gd (the kebab house "Tele Dürum"; the user, 15 Nov 2026)'
write('godot/scripts/casas_calles.gd', nl.join(lines))

edit('godot/scripts/world.gd', [
    ("const TodopizzaS = preload(\"res://scripts/todopizza.gd\")\n", "const TodopizzaS = preload(\"res://scripts/todopizza.gd\")\nconst TeleDurumS = preload(\"res://scripts/teledurum.gd\")\n"),
    ("[\"the pizza house\", _build_todopizza], ", "[\"the pizza house\", _build_todopizza], [\"the kebab house of Santa Ana\", _build_teledurum], "),
    ("func _build_todopizza() -> void:\n", "func _build_teledurum() -> void:\n\tfor hd in MapData.houses:        # (the kebab house of the Calle de Santa Ana, \"Tele Dürum\": teledurum.gd, on its house of the map)\n\t\tif String(hd[\"id\"]) == TeleDurumS.HOUSE:\n\t\t\tteledurum = TeleDurumS.new()\n\t\t\tteledurum.build(self, hd)\n\t\t\treturn\n\nfunc _build_todopizza() -> void:\n"),
    ("var todopizza                   # the pizza house beside it, built by hand (todopizza.gd)\n", "var todopizza                   # the pizza house beside it, built by hand (todopizza.gd)\nvar teledurum                   # the kebab house of the Calle de Santa Ana, built by hand (teledurum.gd)\n"),
])
checks = '''## The kebab house of the Calle de Santa Ana ("Tele Dürum", teledurum.gd): built on its house of the map, which the
## houses' own script no longer draws; its front solid, its gumball machine by its door, nothing of it in the roadway;
## and its hours (18:00 to 04:00), tried without moving the game's clock: the rule, then each state set by hand.
func _teledurum_checks() -> void:
	var td = g.world.teledurum
	_check(td != null and td.pieces > 40 and td.get_child_count() > 6, "the kebab house of the Calle de Santa Ana is built by hand (%d pieces)" % (td.pieces if td != null else 0))
	if td == null:
		return
	var space := get_tree().root.get_world_3d().direct_space_state
	var ray := func(a: Vector2, b: Vector2, h: float) -> bool:
		var p: Vector2 = td.spot(a.x, a.y)
		var q: Vector2 = td.spot(b.x, b.y)
		return not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, td.level + h, p.y), Vector3(q.x, td.level + h, q.y), 1)).is_empty()
	var drawn := 0
	var found := false
	for casa in g.world.casas:
		if casa.id == td.HOUSE:
			drawn += casa.get_child_count()
			found = true
	var shut: bool = ray.call(Vector2(2.9, 3.0), Vector2(2.9, -2.0), 1.5) and ray.call(Vector2(8.7, 3.0), Vector2(8.7, -2.0), 1.5)
	_check(found and drawn == 0 and shut, ("" if shut else "(NOT SOLID) ") + "it stands on its house of the map (%s), which the houses' own script no longer draws, and its front stops you" % td.HOUSE)
	var by_door: float = td.gumball.distance_to(td.door)
	var free: float = MapData.road_edge_dist(td.gumball)
	if MapData.road_hit != null:
		free += MapData.road_hit.hw - MapData.fitted_hw(MapData.road_hit)
	var hit: bool = ray.call(Vector2(td.WAY_IN.position.x + 0.22, 2.5), Vector2(td.WAY_IN.position.x + 0.22, 0.1), 0.8)
	_check(by_door < 2.2 and free > 0.2 and hit and td.NAME == "TELE DÜRUM",
		"its gumball machine stands on the pavement by its door (%.1f m from it, %.1f m from the roadway) and you bump into it; its sign reads %s" % [by_door, free, td.NAME])
	var rule: bool = not td.open_at(12.5) and not td.open_at(17.9) and td.open_at(18.0) and td.open_at(23.0) and td.open_at(0.0) and td.open_at(3.9) and not td.open_at(4.0)
	var good := true
	var turned := [0.0, 0.0]
	for on in [true, false]:
		td.set_open(on)
		var lit := 0
		for lamp in td._lights:
			lit += 1 if lamp.visible else 0
		var r0: float = td._spit.rotation.y
		td.turn(0.5)
		turned[0 if on else 1] = absf(angle_difference(r0, td._spit.rotation.y))
		var stops: bool = ray.call(Vector2(2.9, 3.0), Vector2(2.9, -2.0), 1.5) and ray.call(Vector2(4.85, 3.0), Vector2(4.85, -2.0), 1.2)
		if td.is_open != on or td._open.visible != on or td._shut.visible == on or lit != (td._lights.size() if on else 0) or not stops:
			good = false
	td.set_open(td.open_at(g.clock))
	_check(rule and good and turned[0] > 0.3 and turned[1] == 0.0 and td._spit.get_child_count() >= 14 and td._lights.size() >= 3,
		"it opens from 18:00 to 04:00: shut, its shutters are down and its lamps out; open, they are rolled up, %d lamps are lit and the spit turns (%d pieces of it); its front stops you either way" % [td._lights.size(), td._spit.get_child_count()])

'''
mode = '''	if OS.get_cmdline_user_args().has("--teledurum"):     # just the kebab house of the Calle de Santa Ana: shut at midday, open in the evening and at night, shut again before dawn
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		var td = g.world.teledurum
		if td == null:
			print("TELEDURUM FAILED (the map has no stana_44)")
			get_tree().quit(1)
			return
		var views := {"frente": [Vector2(5.2, 6.4), 1.7, Vector2(5.2, 0.0), 3.3, 95.0], "entrada": [Vector2(4.7, 3.6), 1.6, Vector2(4.8, 0.0), 1.5, 75.0], "maquina": [Vector2(2.9, 1.9), 1.25, Vector2(3.77, 0.24), 0.75, 50.0],
				"rotulo": [Vector2(5.4, 5.2), 1.7, Vector2(5.1, 0.0), 3.4, 55.0], "alto": [Vector2(5.2, 6.6), 1.7, Vector2(5.2, 0.45), 5.7, 80.0], "desde_este": [Vector2(-7.0, 3.0), 1.7, Vector2(6.0, 0.0), 3.0, 75.0],
				"desde_oeste": [Vector2(18.0, 3.0), 1.7, Vector2(5.0, 0.0), 3.0, 75.0], "dentro": [Vector2(4.9, 1.3), 1.55, Vector2(5.4, -3.5), 1.3, 75.0], "asador": [Vector2(5.25, 0.4), 1.6, Vector2(5.3, -3.7), 1.8, 45.0],
				"ventana": [Vector2(8.4, 2.4), 1.6, Vector2(8.4, -2.0), 1.4, 70.0]}
		for turn in [[12.5, "", ["frente", "entrada", "maquina", "rotulo", "alto", "desde_este", "desde_oeste"]],        # shut, at midday
				[18.5, "abierto_", ["frente", "entrada", "dentro", "asador", "ventana", "desde_este"]],                      # open, in the evening
				[23.0, "noche_", ["frente", "entrada", "asador", "desde_oeste"]], [4.5, "madrugada_", ["frente"]]]:          # open at night; shut again before dawn
			g.set_time(turn[0])
			for name in turn[2]:
				var v: Array = views[name]
				var eye: Vector2 = td.spot(v[0].x, v[0].y)
				var at: Vector2 = td.spot(v[2].x, v[2].y)
				g.player.p = td.spot(5.0, 80.0)
				g.cam.position = Vector3(eye.x, MapData.height(eye) + v[1], eye.y)
				g.cam.look_at(Vector3(at.x, td.level + v[3], at.y))
				g.cam.fov = v[4]
				await _frames(6)
				await _shot("teledurum_%s%s" % [turn[1], name])
		g.phase = "free"
		await _teledurum_checks()
		print("TELEDURUM %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
'''
edit('godot/scripts/selftest.gd', [
    ("## The nursery school of the Calle del Palo (calasanz.gd): the house, its yard a step above the street behind its\n", checks + "## The nursery school of the Calle del Palo (calasanz.gd): the house, its yard a step above the street behind its\n"),
    ('	if OS.get_cmdline_user_args().has("--calasanz"):      # just the nursery school', mode + '	if OS.get_cmdline_user_args().has("--calasanz"):      # just the nursery school'),
    ("\n\tawait _todopizza_checks()\n", "\n\tawait _todopizza_checks()\n\tawait _teledurum_checks()\n"),
])
print('ok')
