"""What the pizza house ("Todopizza") adds to the shared files of the game: the world's step, and in
godot/scripts/selftest.gd the mode --todopizza (its pictures and its checks) and _todopizza_checks in the full run; and
what it takes out of mercamona.gd, which used to draw a plain little house in its place. Already applied; kept to show
what was added and to apply it again.

    python tools/todopizza/enganche.py
"""
import io, os
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


if '_todopizza_checks' in read('godot/scripts/selftest.gd'):
    raise SystemExit('already applied')

# ---- mercamona.gd no longer draws the little house north of the shop ----
s = read('godot/scripts/mercamona.gd')
i = s.index("# ---------------- the older little house to the north ----------------")
s = s[:i].rstrip('\n') + '\n'
for a, b in (("	_old_house()\n", ""),
             ("	var hut: Array = [HUT.position, Vector2(HUT.end.x, HUT.position.y), HUT.end, Vector2(HUT.position.x, HUT.end.y)]\n	for ring in [MAIN, BLOCK, hut]:\n", "	for ring in [MAIN, BLOCK]:\n"),
             ("const HUT := Rect2(-19.3, -10.9, 13.4, 13.4)    # the little old house: x, z, long, deep\n", ""),
             ("## At that corner the shop has a taller block clad in darker greys, with big square windows. North of it all stands\n## an older little house, white under a hipped roof of tiles with a porch round it.\n",
              "## At that corner the shop has a taller block clad in darker greys, with big square windows. (The little house under\n## its tiles north of it all is the pizza house: todopizza.gd.)\n")):
    assert s.count(a) == 1, a[:60]
    s = s.replace(a, b)
write('godot/scripts/mercamona.gd', s)

edit('godot/scripts/world.gd', [
    ("const MercamonaS = preload(\"res://scripts/mercamona.gd\")\n", "const MercamonaS = preload(\"res://scripts/mercamona.gd\")\nconst TodopizzaS = preload(\"res://scripts/todopizza.gd\")\n"),
    ("[\"the supermarket\", _build_mercamona], ", "[\"the supermarket\", _build_mercamona], [\"the pizza house\", _build_todopizza], "),
    ("func _build_mercamona() -> void:\n", "func _build_todopizza() -> void:\n\tif MapData.mercamona.is_empty():  # (its parcel is left unraised with the supermarket's: on a map baked before it, Catastro's block stands there)\n\t\treturn\n\ttodopizza = TodopizzaS.new()    # the pizza house beside the supermarket\n\ttodopizza.build(self)\n\nfunc _build_mercamona() -> void:\n"),
    ("var mercamona                   # the supermarket and its car park, built by hand (mercamona.gd)\n", "var mercamona                   # the supermarket and its car park, built by hand (mercamona.gd)\nvar todopizza                   # the pizza house beside it, built by hand (todopizza.gd)\n"),
])
checks = '''## The pizza house beside the supermarket ("Todopizza", todopizza.gd): built, solid, out of the roadways, its forecourt open
## before its doors, its sign up.
func _todopizza_checks() -> void:
	var tp = g.world.todopizza
	_check(tp != null and tp.pieces > 60 and tp.get_child_count() > 8, "the pizza house is built by hand (%d pieces)" % (tp.pieces if tp != null else 0))
	if tp == null:
		return
	var space := get_tree().root.get_world_3d().direct_space_state
	var ray := func(a: Vector2, b: Vector2, h: float) -> bool:
		var p: Vector2 = tp.spot(a.x, a.y)
		var q: Vector2 = tp.spot(b.x, b.y)
		return not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, tp.level + h, p.y), Vector3(q.x, tp.level + h, q.y), 1)).is_empty()
	# the house stops you from every side; the way from the pavement to its doors is open, through the gap in the fence
	var shut: bool = ray.call(Vector2(5.4, 4.0), Vector2(5.4, -4.0), 1.2) and ray.call(Vector2(-3.0, -5.4), Vector2(3.0, -5.4), 1.2) and ray.call(Vector2(5.4, -14.0), Vector2(5.4, -8.0), 1.2)
	var way: bool = not ray.call(Vector2(tp.L * 0.3, 12.5), Vector2(tp.L * 0.3, 0.6), 0.6) and ray.call(Vector2(tp.L * 0.75, 12.5), Vector2(tp.L * 0.75, 8.0), 0.6)
	var nearest := 99.0
	for q in tp.yard:
		var d: float = MapData.road_edge_dist(q)
		if MapData.road_hit != null:
			d += MapData.road_hit.hw - MapData.fitted_hw(MapData.road_hit)
		nearest = minf(nearest, d)
	_check(shut and way and nearest > 0.3,
		("" if shut else "(NOT SOLID) ") + ("" if way else "(ITS FORECOURT IS NOT AS IT SHOULD BE) ") + "the house is solid, its fence lets you in only before its doors, and nothing of it stands in a roadway (the nearest is %.1f m from one)" % nearest)
	_check(MapData.room_at(tp.spot(5.4, -1.0)) < 3.0 and MapData.road_edge_dist(tp.door) > 4.0 and tp.NAME == "TODOPIZZA" and MapData.road_edge_dist(tp.sign_at) > 0.5,
		"the map knows it stands there, its doors give on to its forecourt, and its sign reads %s by the corner of the roads (%.1f m from the roadway)" % [tp.NAME, MapData.road_edge_dist(tp.sign_at)])

'''
mode = '''	if OS.get_cmdline_user_args().has("--todopizza"):     # just the pizza house: its front, its doors, through the glass, its sign, its sides and back, with the supermarket, from the air
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		g.set_time(13.0)
		var tp = g.world.todopizza
		if tp == null:
			print("TODOPIZZA FAILED (the map was baked without the supermarket's parcels)")
			get_tree().quit(1)
			return
		for v in [["frente", Vector2(5.4, 18.0), 1.7, Vector2(5.4, 0.0), 2.6, 70.0], ["puerta", Vector2(3.3, 8.5), 1.7, Vector2(3.3, 0.0), 1.6, 65.0], ["dentro", Vector2(3.6, 2.2), 1.6, Vector2(7.0, -5.5), 1.2, 75.0],
				["cartel", Vector2(-21.0, 13.7), 1.7, Vector2(-10.7, 11.7), 3.6, 55.0], ["esquina", Vector2(-11.0, 16.0), 1.7, Vector2(4.0, -4.0), 2.6, 75.0], ["norte", Vector2(-16.0, -5.4), 1.7, Vector2(0.0, -5.4), 2.4, 75.0],
				["trasera", Vector2(5.4, -23.0), 1.7, Vector2(5.4, -10.75), 2.2, 80.0], ["con_mercamona", Vector2(-14.0, 24.0), 1.7, Vector2(11.0, 0.0), 3.5, 75.0], ["aire", Vector2(5.4, 29.0), 20.0, Vector2(5.4, -5.0), 0.0, 60.0]]:
			var eye: Vector2 = tp.spot(v[1].x, v[1].y)
			var at: Vector2 = tp.spot(v[3].x, v[3].y)
			g.player.p = tp.spot(6.6, 120.0)
			g.cam.position = Vector3(eye.x, MapData.height(eye) + v[2], eye.y)
			g.cam.look_at(Vector3(at.x, tp.level + v[4], at.y))
			g.cam.fov = v[5]
			await _frames(6)
			await _shot("todopizza_%s" % v[0])
		g.phase = "free"
		await _todopizza_checks()
		print("TODOPIZZA %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
'''
edit('godot/scripts/selftest.gd', [
    ("## The nursery school of the Calle del Palo (calasanz.gd): the house, its yard a step above the street behind its\n", checks + "## The nursery school of the Calle del Palo (calasanz.gd): the house, its yard a step above the street behind its\n"),
    ('	if OS.get_cmdline_user_args().has("--calasanz"):      # just the nursery school', mode + '	if OS.get_cmdline_user_args().has("--calasanz"):      # just the nursery school'),
    ("\n\tawait _mercamona_checks()\n", "\n\tawait _mercamona_checks()\n\tawait _todopizza_checks()\n"),
])
print('ok')
