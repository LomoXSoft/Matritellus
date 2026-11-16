"""What the grocer's at the point between San José and Santo Domingo ("los chinos del Arroyuelo") adds to the shared
files of the game: its house is handed over in casas_calles.gd ("obra"), the world's step, and in
godot/scripts/selftest.gd the mode --chinos (its pictures and its checks) and _chinos_checks in the full run.
Already applied; kept to show what was added.

    python tools/chinos/enganche.py
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


if '_chinos_checks' in read('godot/scripts/selftest.gd'):
    raise SystemExit('already applied')

s = read('godot/scripts/casas_calles.gd')
nl = '\r\n' if '\r\n' in s else '\n'
lines = s.replace('\r\n', '\n').split('\n')
hit = [i for i, l in enumerate(lines) if re.match(r'^\t"sanjose_1": \[', l)]
assert len(hit) == 1, hit
lines[hit[0]] = '\t"sanjose_1": ["obra"],      # built by hand: chinos.gd (the grocer\'s at the point between San José and Santo Domingo; the user, 15 Nov 2026)'
write('godot/scripts/casas_calles.gd', nl.join(lines))

edit('godot/scripts/world.gd', [
    ("const TeleDurumS = preload(\"res://scripts/teledurum.gd\")\n", "const TeleDurumS = preload(\"res://scripts/teledurum.gd\")\nconst ChinosS = preload(\"res://scripts/chinos.gd\")\n"),
    ("[\"the kebab house of Santa Ana\", _build_teledurum], ", "[\"the kebab house of Santa Ana\", _build_teledurum], [\"the grocer's at the point\", _build_chinos], "),
    ("func _build_teledurum() -> void:\n", "func _build_chinos() -> void:\n\tfor hd in MapData.houses:        # (the grocer's at the point between San José and Santo Domingo: chinos.gd, on its house of the map)\n\t\tif String(hd[\"id\"]) == ChinosS.HOUSE:\n\t\t\tchinos = ChinosS.new()\n\t\t\tchinos.build(self, hd)\n\t\t\treturn\n\nfunc _build_teledurum() -> void:\n"),
    ("var teledurum                   # the kebab house of the Calle de Santa Ana, built by hand (teledurum.gd)\n", "var teledurum                   # the kebab house of the Calle de Santa Ana, built by hand (teledurum.gd)\nvar chinos                      # the grocer's at the point between San José and Santo Domingo, built by hand (chinos.gd)\n"),
])
checks = '''## The grocer's at the point between San José and Santo Domingo (chinos.gd): built on its house of the map, which the
## houses' own script no longer draws; its three fronts solid; its slab level over two falling streets; its two road
## signs on the pavement at the point, out of the roadway; its board says what it sells; and its hours (7 to 21 from
## Monday to Friday, 6 to 2 of the next morning on Saturdays and Sundays), tried without moving the game's clock.
func _chinos_checks() -> void:
	var ch = g.world.chinos
	_check(ch != null and ch.pieces > 400 and ch.get_child_count() > 10, "the grocer's at the point between San José and Santo Domingo is built by hand (%d pieces)" % (ch.pieces if ch != null else 0))
	if ch == null:
		return
	var space := get_tree().root.get_world_3d().direct_space_state
	var ray := func(a: Vector2, b: Vector2, h: float) -> bool:
		var p: Vector2 = ch.spot(a.x, a.y)
		var q: Vector2 = ch.spot(b.x, b.y)
		return not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, ch.level + h, p.y), Vector3(q.x, ch.level + h, q.y), 1)).is_empty()
	var drawn := 0
	var found := false
	for casa in g.world.casas:
		if casa.id == ch.HOUSE:
			drawn += casa.get_child_count()
			found = true
	var mid_s: Vector2 = ch.WS + ch.ds * 10.0
	var stops: bool = ray.call(Vector2(10.0, 3.0), Vector2(10.0, -2.0), -1.5) and ray.call(mid_s + ch.ns * 3.0, mid_s - ch.ns * 2.0, -1.5) \\
		and ray.call((ch.PS + ch.PN) / 2.0 + ch.np * 3.0, (ch.PS + ch.PN) / 2.0 - ch.np * 2.0, -1.5)
	_check(found and drawn == 0 and stops, ("" if stops else "(NOT SOLID) ") + "it stands on its house of the map (%s), which the houses' own script no longer draws, and its three fronts stop you" % ch.HOUSE)
	var west: float = ch.level - MapData.height(ch.spot(ch.len_n - 1.0, 0.6))
	var point: float = ch.level - MapData.height(ch.spot(-0.6, -1.5))
	_check(west > 2.2 and west < 3.6 and point > west and point < 5.0, "its slab is level: %.2f m over the Calle de San José at its west end, %.2f m over the pavement at the point" % [west, point])
	var near := 99.0
	var free := 99.0
	for p: Vector2 in ch.posts:
		near = minf(near, minf(p.distance_to(ch.spot(0.0, 0.0)), p.distance_to(ch.spot(ch.PS.x, ch.PS.y))))
		var f: float = MapData.road_edge_dist(p)
		if MapData.road_hit != null:
			f += MapData.road_hit.hw - MapData.fitted_hw(MapData.road_hit)
		free = minf(free, f)
	var by_door: float = ch.door.distance_to(ch.spot(ch.PS.x / 2.0, ch.PS.y / 2.0))
	_check(ch.posts.size() == 2 and near < 1.0 and free > 0.1 and by_door < 2.5 and ch.NAME == "ALIMENTACIÓN" and ch.poster,
		("" if ch.poster else "(NO POSTER) ") + "its two road signs stand at the point, on the pavement (%.1f m from the roadway), its door gives on to the point with the poster on it, and its board reads %s" % [free, ch.NAME])
	var rule: bool = not ch.open_at(0, 6.9) and ch.open_at(0, 7.0) and ch.open_at(4, 20.9) and not ch.open_at(4, 21.0) and not ch.open_at(1, 1.0) and not ch.open_at(5, 1.0) and not ch.open_at(5, 5.9)
	rule = rule and ch.open_at(5, 6.0) and ch.open_at(5, 23.5) and ch.open_at(6, 1.9) and not ch.open_at(6, 2.0) and ch.open_at(6, 6.0) and ch.open_at(0, 1.5) and not ch.open_at(0, 2.0) and ch.open_at(6, 23.99) and not ch.open_at(0, 21.0)
	var good := true
	for on in [true, false]:
		ch.set_open(on)
		var lit := 0
		for lamp in ch._lights:
			lit += 1 if lamp.visible else 0
		var front: bool = ray.call((ch.PS + ch.PN) / 2.0 + ch.np * 3.0, (ch.PS + ch.PN) / 2.0 - ch.np * 2.0, -2.2)
		if ch.is_open != on or ch._open.visible != on or ch._shut.visible == on or lit != (ch._lights.size() if on else 0) or not front:
			good = false
	ch.set_open(ch.open_at(g.weekday, g.clock))
	_check(rule and good and ch._lights.size() == 2 and ch._shut.get_child_count() > 0 and ch._open.get_child_count() > 0 and ch.on_shutter == 2,
		"it opens from 7 to 21 from Monday to Friday and from 6 to 2 of the next morning on Saturdays and Sundays: shut, its door is shut, its lamps are out, its awning is rolled up and its shutter is down with %d posters on it; open, a leaf stands open, the awning is out and %d lamps are lit; its front stops you either way" % [ch.on_shutter, ch._lights.size()])

'''
mode = '''	if OS.get_cmdline_user_args().has("--chinos"):        # just the grocer's at the point between San José and Santo Domingo: the point, its two long sides from each end, its doors, from the air
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		g.weekday = 0
		g.set_time(12.5)
		var ch = g.world.chinos
		if ch == null:
			print("CHINOS FAILED (the map has no sanjose_1)")
			get_tree().quit(1)
			return
		var s_mid: Vector2 = ch.WS + ch.ds * 10.0
		var s_door: Vector2 = ch.WS + ch.ds * 4.85
		for v in [["punta", Vector2(-9.5, -1.6), 1.7, Vector2(-0.3, -1.5), -1.2, 62.0], ["tienda", Vector2(-4.6, -1.7), 1.6, Vector2(-0.3, -1.5), -2.1, 72.0], ["rotulo", Vector2(-4.0, -1.6), 1.7, Vector2(-0.3, -1.5), -0.6, 48.0], ["cartel", ch.PS + ch.dp * (ch.len_p * 0.34) + ch.np * 1.5, 1.5, ch.PS + ch.dp * (ch.len_p * 0.34), -2.35, 50.0],
				["balcon", Vector2(-7.5, -1.6), 1.7, Vector2(-0.3, -1.5), 1.6, 55.0], ["norte", Vector2(9.5, 4.6), 1.7, Vector2(9.5, 0.0), -1.0, 100.0], ["norte_desde_punta", Vector2(-2.6, 3.4), 1.7, Vector2(9.0, 0.0), -1.0, 80.0],
				["norte_verjas", Vector2(21.5, 4.4), 1.7, Vector2(15.5, 0.0), -1.2, 80.0], ["sur", s_mid + ch.ns * 4.4, 1.7, s_mid, -1.0, 100.0], ["sur_desde_punta", ch.PS + ch.ns * 3.4 + ch.ds * 2.6, 1.7, ch.WS + ch.ds * 9.0, -1.0, 80.0],
				["sur_desde_oeste", ch.WS - ch.ds * 2.6 + ch.ns * 3.6, 1.7, ch.WS + ch.ds * 8.0, -1.0, 80.0], ["puerta", s_door + ch.ns * 3.2, 1.6, s_door, -1.7, 72.0], ["aire", Vector2(-13.0, -1.5), 13.0, Vector2(8.0, -4.5), 2.0, 60.0]]:
			var eye: Vector2 = ch.spot(v[1].x, v[1].y)
			var at: Vector2 = ch.spot(v[3].x, v[3].y)
			g.player.p = ch.spot(5.0, 80.0)
			g.cam.position = Vector3(eye.x, MapData.height(eye) + v[2], eye.y)
			g.cam.look_at(Vector3(at.x, ch.level + v[4], at.y))
			g.cam.fov = v[5]
			await _frames(6)
			await _shot("chinos_%s" % v[0])
		for moment in [["lunes_cerrado", 0, 6.6], ["lunes_noche_cerrado", 0, 22.0], ["sabado_noche_abierto", 5, 23.0], ["domingo_madrugada_abierto", 6, 1.0]]:      # its hours: shut on a Monday before seven and after nine, open late on a Saturday
			g.weekday = moment[1]
			g.set_time(moment[2])
			for v in [["", Vector2(-9.5, -1.6), 1.7, Vector2(-0.3, -1.5), -1.2, 62.0], ["_tienda", Vector2(-4.6, -1.7), 1.6, Vector2(-0.3, -1.5), -2.1, 72.0], ["_cerca", ch.PS + ch.dp * (ch.len_p * 0.5) + ch.np * 2.4, 1.5, ch.PS + ch.dp * (ch.len_p * 0.5), -2.5, 62.0]]:
				var eye: Vector2 = ch.spot(v[1].x, v[1].y)
				var at: Vector2 = ch.spot(v[3].x, v[3].y)
				g.cam.position = Vector3(eye.x, MapData.height(eye) + v[2], eye.y)
				g.cam.look_at(Vector3(at.x, ch.level + v[4], at.y))
				g.cam.fov = v[5]
				await _frames(6)
				await _shot("chinos_%s%s" % [moment[0], v[0]])
		g.weekday = 0
		g.set_time(12.5)
		g.phase = "free"
		await _chinos_checks()
		print("CHINOS %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
'''
edit('godot/scripts/selftest.gd', [
    ('## The kebab house of the Calle de Santa Ana ("Tele Dürum", teledurum.gd): built on its house of the map, which the\n', checks + '## The kebab house of the Calle de Santa Ana ("Tele Dürum", teledurum.gd): built on its house of the map, which the\n'),
    ('	if OS.get_cmdline_user_args().has("--teledurum"):', mode + '	if OS.get_cmdline_user_args().has("--teledurum"):'),
    ("\n\tawait _teledurum_checks()\n", "\n\tawait _teledurum_checks()\n\tawait _chinos_checks()\n"),
])
print('ok')
