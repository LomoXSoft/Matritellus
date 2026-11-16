"""What the people's university of the Calle de los Arcos ("Universidad Comunal") and the stationer's beside it
("Papelería Rocas") add to the shared files of the game: their three houses are handed over in casas_calles.gd
("obra"), the world's step, and in godot/scripts/selftest.gd the mode --comunal (its pictures and its checks) and
_comunal_checks in the full run. No rebake. Already applied; kept to show what was added.

    python tools/comunal/enganche.py
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


HOUSES = {'arcos_10': 'the people\'s university ("Universidad Comunal")', 'arcos_10t': 'its garden wall and porch', 'arcos_12': 'the stationer\'s beside it ("Papelería Rocas") and its block on the Calle Cervantes'}
WORLD_EDITS = [
    ('const CuartelS = preload("res://scripts/cuartel.gd")\n', 'const CuartelS = preload("res://scripts/cuartel.gd")\nconst ComunalS = preload("res://scripts/comunal.gd")\n'),
    ('["the Tricornios\' barracks", _build_cuartel], ', '["the Tricornios\' barracks", _build_cuartel], ["the people\'s university and the stationer\'s", _build_comunal], '),
    ("func _build_cuartel() -> void:\n", "func _build_comunal() -> void:\n\tvar found := {}                  # (the people's university of the Calle de los Arcos and the stationer's beside it: comunal.gd, on their houses of the map)\n\tfor hd in MapData.houses:\n\t\tif String(hd[\"id\"]) == ComunalS.HOUSE or String(hd[\"id\"]) == ComunalS.SHOP:\n\t\t\tfound[String(hd[\"id\"])] = hd\n\tif found.has(ComunalS.HOUSE):\n\t\tcomunal = ComunalS.new()\n\t\tcomunal.build(self, found[ComunalS.HOUSE], found.get(ComunalS.SHOP, {}))\n\nfunc _build_cuartel() -> void:\n"),
    ("var cuartel                     # the Tricornios' barracks of the Avenida de la Constitución, built by hand (cuartel.gd)\n", "var cuartel                     # the Tricornios' barracks of the Avenida de la Constitución, built by hand (cuartel.gd)\nvar comunal                     # the people's university of the Calle de los Arcos and the stationer's beside it, built by hand (comunal.gd)\n"),
]
checks = '''## The people's university of the Calle de los Arcos and the stationer's beside it (comunal.gd): built on their three
## houses of the map, which the houses' own script no longer draws; the garden wall, the gate, the shop and the block
## behind solid; what stands on the pavement out of the roadway; their names the game's; the shop shut and open.
func _comunal_checks() -> void:
	var co = g.world.comunal
	_check(co != null and co.pieces > 700 and co.has_shop, "the people's university and the stationer's are built by hand (%d pieces)" % (co.pieces if co != null else 0))
	if co == null:
		return
	var space := get_tree().root.get_world_3d().direct_space_state
	var ray := func(a: Vector2, b: Vector2, h: float) -> bool:
		var p: Vector2 = co.spot(a.x, a.y)
		var q: Vector2 = co.spot(b.x, b.y)
		return not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, co.level + h, p.y), Vector3(q.x, co.level + h, q.y), 1)).is_empty()
	var drawn := 0
	var found := 0
	for casa in g.world.casas:
		if casa.id == co.HOUSE or casa.id == co.WALL or casa.id == co.SHOP:
			drawn += casa.get_child_count()
			found += 1
	# the garden wall north and south of the porch, its gate, the stationer's arch, and the block on the Calle Cervantes
	var shut: bool = ray.call(Vector2(15.0, 9.0), Vector2(15.0, 1.5), 1.0) and ray.call(Vector2(3.5, 9.0), Vector2(3.5, 1.5), 1.0) and ray.call(Vector2(8.4, 9.0), Vector2(8.4, 1.5), 1.0)
	shut = shut and ray.call(Vector2(-1.5, 9.0), Vector2(-1.5, 1.0), 0.8) and ray.call(Vector2(-1.5, -31.0), Vector2(-1.5, -22.0), 1.5)
	_check(found == 3 and drawn == 0 and shut, ("" if shut else "(NOT SOLID) ") + "they stand on their three houses of the map, which the houses' own script no longer draws (%d found), and the wall, the gate, the shop and the block behind stop you" % found)
	var nearest := 99.0
	for q in co.yard:
		var d: float = MapData.road_edge_dist(q)
		if MapData.road_hit != null:                # (to the roadway as it is drawn, not to the street's nominal width)
			d += MapData.road_hit.hw - MapData.fitted_hw(MapData.road_hit)
		nearest = minf(nearest, d)
	var street: String = String(MapData.nearest_road(co.door)["seg"].road["n"])
	_check(nearest > 0.0 and street.contains("Arcos") and co.NAME == "UNIVERSIDAD COMUNAL" and co.SHOP_NAME == "Rocas",
		"its notice board and the road sign stand on the pavement (the nearest is %.1f m from the roadway), its gate gives on to the %s, and the names read %s and %s" % [nearest, street, co.NAME, co.SHOP_NAME])
	var good := true
	for on in [true, false]:
		co.set_open(on)
		var lit := 0
		for lamp in co._lights:
			lit += 1 if lamp.visible else 0
		if co.is_open != on or co._open.visible != on or co._shut.visible == on or lit != (co._lights.size() if on else 0):
			good = false
	co.set_open(co.open_at(g.weekday, g.clock))
	var rule: bool = not co.open_at(0, 9.9) and co.open_at(0, 10.0) and co.open_at(0, 13.9) and not co.open_at(0, 14.0) and not co.open_at(2, 17.4) and co.open_at(2, 17.5) and co.open_at(4, 20.9) and not co.open_at(4, 21.0)
	rule = rule and co.open_at(5, 10.0) and co.open_at(5, 13.9) and not co.open_at(5, 14.0) and not co.open_at(5, 18.0) and not co.open_at(6, 11.0) and not co.open_at(6, 18.0) and not co.open_at(1, 2.0)
	_check(good and rule and co._shut.get_child_count() > 0 and co._lights.size() == 2,
		"the stationer's opens from 10 to 14 and from 17:30 to 21 from Monday to Friday, on Saturday mornings, and not on Sundays: shut, its mesh of wire is down over its arch; open, the arch is an open doorway and its %d lamps are lit" % co._lights.size())

'''
mode = '''	if OS.get_cmdline_user_args().has("--comunal"):       # just the people's university of the Calle de los Arcos and the stationer's: the porch, the wall, the front behind it, the shop, the block behind, from the air
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		g.weekday = 0                               # (a Monday at half past twelve: the stationer's is open)
		g.set_time(12.5)
		var co = g.world.comunal
		if co == null:
			print("COMUNAL FAILED (the map has no arcos_10)")
			get_tree().quit(1)
			return
		for v in [["desde_callejon", Vector2(2.5, 21.0), 1.7, Vector2(8.0, 0.0), 2.6, 62.0], ["porche", Vector2(8.4, 10.6), 1.7, Vector2(8.4, 3.9), 2.6, 72.0], ["rotulo", Vector2(8.4, 9.6), 1.7, Vector2(8.4, 4.0), 3.6, 40.0],
				["tablon", Vector2(11.4, 8.6), 1.6, Vector2(11.4, 4.6), 1.5, 55.0], ["desde_norte", Vector2(24.0, 8.6), 1.7, Vector2(9.0, 2.5), 2.6, 72.0], ["desde_sur", Vector2(-12.0, 8.6), 1.7, Vector2(4.0, 2.5), 3.0, 72.0],
				["tapia", Vector2(16.5, 10.0), 1.7, Vector2(14.5, 2.0), 2.2, 80.0], ["papeleria", Vector2(-1.5, 11.0), 1.7, Vector2(-1.5, 3.7), 2.9, 78.0], ["papeleria_arco", Vector2(-1.4, 8.4), 1.6, Vector2(-1.5, 3.6), 0.9, 62.0], ["papeleria_dentro", Vector2(-1.45, 5.6), 1.6, Vector2(-1.5, -2.0), 0.6, 70.0],
				["papeleria_rotulo", Vector2(-7.5, 7.4), 1.7, Vector2(-2.6, 4.2), 4.3, 45.0], ["cervantes", Vector2(-1.7, -29.6), 1.7, Vector2(-1.7, -25.6), 3.6, 95.0], ["aire", Vector2(9.9, 19.0), 24.0, Vector2(9.9, -2.0), 2.0, 60.0],
				["aire_detras", Vector2(6.0, -46.0), 26.0, Vector2(5.0, -8.0), 2.0, 55.0]]:
			var eye: Vector2 = co.spot(v[1].x, v[1].y)
			var at: Vector2 = co.spot(v[3].x, v[3].y)
			g.player.p = co.spot(10.0, 140.0)
			g.cam.position = Vector3(eye.x, MapData.height(eye) + v[2], eye.y)
			g.cam.look_at(Vector3(at.x, co.level + v[4], at.y))
			g.cam.fov = v[5]
			await _frames(6)
			await _shot("comunal_%s" % v[0])
		for moment in [["cerrada", 0, 15.5], ["tarde", 0, 20.0], ["domingo", 6, 12.0]]:      # the stationer's hours: shut at midday, open in the evening, shut on Sunday
			g.weekday = moment[1]
			g.set_time(moment[2])
			for v in [["", Vector2(-1.4, 8.4), 1.6, Vector2(-1.5, 3.6), 0.9, 62.0], ["_dentro", Vector2(-1.45, 5.6), 1.6, Vector2(-1.5, -2.0), 0.6, 70.0]]:
				var eye: Vector2 = co.spot(v[1].x, v[1].y)
				var at: Vector2 = co.spot(v[3].x, v[3].y)
				g.cam.position = Vector3(eye.x, MapData.height(eye) + v[2], eye.y)
				g.cam.look_at(Vector3(at.x, co.level + v[4], at.y))
				g.cam.fov = v[5]
				await _frames(6)
				await _shot("comunal_papeleria_%s%s" % [moment[0], v[0]])
		g.weekday = 0
		g.set_time(12.5)
		g.phase = "free"
		await _comunal_checks()
		print("COMUNAL %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
'''
SELFTEST_EDITS = [      # (three small edits in place: other sessions work on this file too)
    ("## The Tricornios' barracks of the Avenida de la Constitución (cuartel.gd): built, with its three signs and its bays;\n",
     checks + "## The Tricornios' barracks of the Avenida de la Constitución (cuartel.gd): built, with its three signs and its bays;\n"),
    ('	if OS.get_cmdline_user_args().has("--cuartel"):', mode + '	if OS.get_cmdline_user_args().has("--cuartel"):'),
    ("\n\tawait _cuartel_checks()\n", "\n\tawait _cuartel_checks()\n\tawait _comunal_checks()\n"),
]

if __name__ == '__main__':
    if '_comunal_checks' in read('godot/scripts/selftest.gd'):
        raise SystemExit('already applied')
    s = read('godot/scripts/casas_calles.gd')
    nl = '\r\n' if '\r\n' in s else '\n'
    lines = s.replace('\r\n', '\n').split('\n')
    for hid, what in HOUSES.items():
        hit = [i for i, l in enumerate(lines) if re.match(r'^\t"%s": \[' % hid, l)]
        assert len(hit) == 1, (hid, hit)
        lines[hit[0]] = '\t"%s": ["obra"],      # built by hand: comunal.gd (%s; the user, 16 Nov 2026)' % (hid, what)
    write('godot/scripts/casas_calles.gd', nl.join(lines))
    edit('godot/scripts/world.gd', WORLD_EDITS)
    edit('godot/scripts/selftest.gd', SELFTEST_EDITS)
    print('ok')
