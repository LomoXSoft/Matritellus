import os
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))).replace(os.sep, '/') + '/'      # (the project's folder, wherever it is: X:/Matritellus since 17 Nov 2026)


def patch(path, pairs):
    s = open(R + path, encoding='utf8').read()
    for old, new in pairs:
        assert s.count(old) == 1, (path, s.count(old), old[:80])
        s = s.replace(old, new)
    open(R + path, 'w', encoding='utf8', newline='\n').write(s)
    print('ok', path)


patch('godot/scripts/world.gd', [
    ('const MolinoS = preload("res://scripts/molino.gd")\n', 'const MolinoS = preload("res://scripts/molino.gd")\nconst TorosS = preload("res://scripts/toros.gd")\n'),
    ("var molino                      # the windmill and its yard, when built by hand (molino.gd)\n",
     "var molino                      # the windmill and its yard, when built by hand (molino.gd)\nvar toros                       # the old bullring, when built by hand (toros.gd): the ruin, or restored (toros.set_restored)\n"),
    ('["the Petril", _build_petril], ', '["the Petril", _build_petril], ["the old bullring", _build_toros], '),
    ("func _build_details() -> void:\n", "func _build_toros() -> void:\n	if MapData.toros.is_empty():    # (a map baked before it: Catastro's round block stands there)\n		return\n	toros = TorosS.new()            # the old bullring between Prensa, San Agustín and Vista Alegre, in its two states\n	toros.build(self)\n\nfunc _build_details() -> void:\n"),
])
patch('godot/scripts/map_data.gd', [
    ("	molino = data.get(\"molino\", {})\n", "	molino = data.get(\"molino\", {})\n	toros = data.get(\"toros\", {})\n"),
])
s = open(R + 'godot/scripts/map_data.gd', encoding='utf8').read()
i = s.index("var molino: Dictionary = {}")
j = s.index("\n", i)
s = s[:j + 1] + "var toros: Dictionary = {}       # the old bullring's (toros.gd): {o: the middle of its ring}; empty on a map baked without it\n" + s[j + 1:]
open(R + 'godot/scripts/map_data.gd', 'w', encoding='utf8', newline='\n').write(s)

patch('tools/bake_godot.py', [
    ("# The cooperative on the Avenida de la Constitución is hand-built as well (godot/scripts/coop.gd), from street photos.\n",
     """# The old bullring between the Calle de la Prensa, San Agustín and Vista Alegre (godot/scripts/toros.gd; the user, 15
# November 2026; referencias/plaza_toros/): Catastro's round part is not raised -- toros.gd builds the ring, in its two
# states, and the lot in front of it, on a level terrace. Its frame: the middle of the ring, the map's own axes.
TOROS_RC = '4786002VJ5648N'
TOROS = {'o': (476.3, 548.5)}
toros_zone = Polygon([(TOROS['o'][0] + x, TOROS['o'][1] + z) for x, z in ((-19.6, -28.0), (-42.5, 27.4), (18.5, 65.8), (47.1, -14.5), (23.9, -13.8), (0.0, -28.6), (-21.1, -17.7))])
toros = {'o': list(TOROS['o'])}
_toros_gd = os.path.join(HERE, '..', 'godot', 'scripts', 'toros.gd')
if not (os.path.exists(_toros_gd) and 'const READY := true' in open(_toros_gd, encoding='utf-8').read()):      # (not built yet: Catastro's block stays)
    TOROS_RC, toros, toros_zone = None, {}, Polygon()

# The cooperative on the Avenida de la Constitución is hand-built as well (godot/scripts/coop.gd), from street photos.
"""),
    ("    if bid == MOLINO_RC: return                                  # ...and the windmill with its yard\n",
     "    if bid == MOLINO_RC: return                                  # ...and the windmill with its yard\n    if bid == TOROS_RC: return                                   # ...and the old bullring\n"),
    ("if molino: terrace(molino_zone.buffer(3.0))      # the windmill and its yard (molino.gd)\n",
     "if molino: terrace(molino_zone.buffer(3.0))      # the windmill and its yard (molino.gd)\nif toros: terrace(toros_zone.buffer(3.0))        # the old bullring and its lot (toros.gd)\n"),
    ("trees = [t for t in trees if not molino_zone.contains(Point(t[0], t[1]))]      # ...and so does the mill's yard\n",
     "trees = [t for t in trees if not molino_zone.contains(Point(t[0], t[1]))]      # ...and so does the mill's yard\ntrees = [t for t in trees if not toros_zone.contains(Point(t[0], t[1]))]       # ...and the bullring's lot\n"),
    ("'petril': petril, 'molino': molino, ", "'petril': petril, 'molino': molino, 'toros': toros, "),
])

MODE = '''	if OS.get_cmdline_user_args().has("--toros"):         # just the old bullring: the ruin and then restored, from the three streets, from inside, from the air
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		g.set_time(11.0)
		var tr = g.world.toros
		if tr == null:
			print("TOROS FAILED (the map was baked without the bullring)")
			get_tree().quit(1)
			return
		for fine in [false, true]:
			tr.set_restored(fine)
			await _frames(4)
			for v in [["sur", Vector2(4.0, 66.0), 1.7, Vector2(0.0, 26.0), 3.0, 60.0], ["sureste", Vector2(30.0, 44.0), 1.7, Vector2(14.0, 20.0), 2.6, 60.0], ["este", Vector2(45.0, 8.0), 1.7, Vector2(26.0, 2.0), 3.0, 70.0],
					["oeste", Vector2(-40.5, 8.0), 1.7, Vector2(-26.0, 4.0), 3.0, 75.0], ["cerca", Vector2(26.0, 38.0), 1.7, Vector2(17.5, 23.0), 2.6, 60.0], ["ruedo", Vector2(8.0, 12.0), 1.7, Vector2(-9.0, -13.0), 2.2, 75.0],
					["grada", Vector2(-13.0, 18.0), 5.2, Vector2(8.0, -10.0), 1.0, 75.0], ["aire", Vector2(34.0, 70.0), 26.0, Vector2(0.0, 6.0), 1.0, 60.0]]:
				var eye: Vector2 = tr.spot(v[1].x, v[1].y)
				var at: Vector2 = tr.spot(v[3].x, v[3].y)
				g.player.p = tr.spot(70.0, 110.0)
				g.cam.position = Vector3(eye.x, tr.level + v[2], eye.y)
				g.cam.look_at(Vector3(at.x, tr.level + v[4], at.y))
				g.cam.fov = v[5]
				await _frames(6)
				await _shot("toros_%s_%s" % ["restaurada" if fine else "ruina", v[0]])
			var over: Vector2 = tr.spot(2.0, 16.0)
			g.cam.fov = 55.0
			g.cam.position = Vector3(over.x, tr.level + 120.0, over.y)
			g.cam.look_at(Vector3(over.x, tr.level, over.y), Vector3(0, 0, -1))
			await _frames(6)
			await _shot("toros_%s_above" % ["restaurada" if fine else "ruina"])
		g.phase = "free"
		await _toros_checks(true)
		print("TOROS %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--molino"):        # just the windmill and its yard: from the streets round it, from inside, from the air
'''
CHECKS = '''## The old bullring (toros.gd), in its two states. `walk`: also go on foot into the restored ring by its door.
func _toros_checks(walk := false) -> void:
	var tr = g.world.toros
	_check(tr != null and tr.pieces > 800 and tr._state.size() == 2, "the old bullring is built by hand, as a ruin and restored (%d pieces)" % (tr.pieces if tr != null else 0))
	if tr == null:
		return
	var space := get_tree().root.get_world_3d().direct_space_state
	var lv: float = tr.level
	var was: bool = tr.restored
	var ray := func(a: Vector2, b: Vector2, h: float) -> bool:
		var p: Vector2 = tr.spot(a.x, a.y)
		var q: Vector2 = tr.spot(b.x, b.y)
		return not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, lv + h, p.y), Vector3(q.x, lv + h, q.y), 1)).is_empty()
	var door_out: Vector2 = tr._p(tr.DOOR + 2.57, tr.R + 3.0)
	var door_in: Vector2 = tr._p(tr.DOOR + 2.57, tr.R_STAND - 0.6)
	# the ruin: its wall stops you all round, its door is boarded up, and the lot is fenced but for the open gate
	tr.set_restored(false)
	await _frames(4)
	var shut: bool = ray.call(door_out, door_in, 0.9) and ray.call(Vector2(0.0, 40.0), Vector2(0.0, 10.0), 0.9) and ray.call(Vector2(40.0, 0.0), Vector2(10.0, 0.0), 0.9)
	var fenced: bool = ray.call(Vector2(40.0, 30.0), Vector2(24.0, 30.0), 0.9) and not ray.call(tr.WEST_B.lerp(tr.SOUTH_B, 0.46) + Vector2(1.6, -2.6) * -1.0, tr.WEST_B.lerp(tr.SOUTH_B, 0.46) + Vector2(1.6, -2.6), 0.9)
	_check(shut and fenced and not tr._state["nuevo"]["node"].visible, "as a ruin its wall is whole enough to keep you out and its door is boarded up; the lot is fenced, the gate on Vista Alegre open")
	# restored: the door open and a way through the stands to the sand; the barrier round it; no fence
	tr.set_restored(true)
	await _frames(4)
	var way_in: bool = not ray.call(door_out, door_in, 0.9)
	var walled: bool = ray.call(Vector2(0.0, 40.0), Vector2(0.0, 10.0), 0.9) and ray.call(Vector2(-10.0, 0.0), Vector2(-20.3, 0.0), 0.5)
	var open_lot: bool = not ray.call(Vector2(40.0, 30.0), Vector2(24.0, 30.0), 0.9)
	_check(way_in and walled and open_lot and tr._state["nuevo"]["node"].visible and not tr._state["viejo"]["node"].visible,
		"restored, its door stands open and leads through the stands to the ring; the wall and the barrier are solid; the fence is gone")
	var nearest := 99.0
	for q in tr.yard:
		nearest = minf(nearest, MapData.road_edge_dist(q))
	var flat_lot := 0.0
	for q in [Vector2(0.0, 0.0), Vector2(0.0, 45.0), Vector2(30.0, 20.0), Vector2(-30.0, 25.0)]:
		flat_lot = maxf(flat_lot, absf(MapData.height(tr.spot(q.x, q.y)) - lv))
	_check(nearest >= 0.0 and flat_lot < 0.15, "nothing of it stands in a street (the nearest to the asphalt is %.1f m off) and its lot is level (%.2f m at worst)" % [nearest, flat_lot])
	if walk:
		var back: Vector2 = g.player.p
		g.player.p = tr.spot(door_out.x, door_out.y)
		await _frames(3)
		var left: float = await _walk_at(tr.spot(door_in.x, door_in.y), 6.0)
		_check(left < 0.6 and absf(g.player.global_position.y - lv) < 0.1, "on foot you go in by the door and through to the alley round the ring (%.1f m short)" % left)
		g.player.p = back
	tr.set_restored(was)

## The windmill and its yard (molino.gd). `walk`: also go in on foot by the red door and round to the door of the mill
'''
patch('godot/scripts/selftest.gd', [
    ('''	if OS.get_cmdline_user_args().has("--molino"):        # just the windmill and its yard: from the streets round it, from inside, from the air
''', MODE),
    ('''## The windmill and its yard (molino.gd). `walk`: also go in on foot by the red door and round to the door of the mill
''', CHECKS),
    ('''	await _molino_checks()
''', '''	await _molino_checks()
	await _toros_checks()
'''),
    ('''or (label.begins_with("ml_") and g.world.molino != null):''', '''or (label.begins_with("ml_") and g.world.molino != null) or (label.begins_with("tr_") and g.world.toros != null):'''),
    ('''(g.world.plaza if label.begins_with("pz_") else g.world.molino)        # (ml_...: in the windmill's)''',
     '''(g.world.plaza if label.begins_with("pz_") else (g.world.molino if label.begins_with("ml_") else g.world.toros))        # (ml_...: in the windmill's; tr_...: in the old bullring's)'''),
])
