"""What the old bridge of the Arroyuelo Medio adds to godot/scripts/selftest.gd: the mode --puente (pictures of it with
the demolition works round it and without, and its checks) and _arroyuelo_checks() in the full run. Kept as the record
of which lines are the bridge's; run once (it refuses to run twice).

    python tools/puente/enganche.py
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


MODE = '''	if OS.get_cmdline_user_args().has("--puente"):        # just the old bridge of the Arroyuelo Medio: with the works round it and the demonstration, then clean, from both ends of the bed, the corner, the deck, the air
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		g.set_time(11.0)
		var br = g.bridge
		br.auto = false
		for clean in [false, true]:
			br.set_works(not clean)
			br.close_off(not clean)
			br.dress(not clean)
			for n in g.npcs:
				if n.p.distance_to(br.p) < 70.0:
					n.visible = (not clean) or not g.protesters.has(n)
					n.sync()
			await _frames(4)
			for v in [["santo", Vector2(-0.7, -46.0), 1.7, Vector2(0.0, -10.0), 1.0, 55.0], ["cauce", Vector2(-0.6, -14.0), 1.7, Vector2(0.0, 0.0), 1.0, 60.0], ["acera", Vector2(4.1, -9.5), 2.75, Vector2(-0.5, 0.5), 1.3, 65.0],
					["sur", Vector2(1.6, 14.5), 1.7, Vector2(0.0, 0.0), 1.2, 60.0], ["palo", Vector2(11.0, 24.0), 1.7, Vector2(0.0, 0.0), 1.2, 42.0], ["placeta", Vector2(-9.0, 5.0), 1.7, Vector2(-1.0, 0.8), 1.3, 65.0],
					["encima", Vector2(2.8, 0.4), 2.8, Vector2(-3.0, -0.2), 2.0, 75.0], ["cochera", Vector2(-0.5, 9.0), 1.7, Vector2(5.0, 5.5), 1.6, 60.0], ["aire", Vector2(11.0, 17.0), 14.0, Vector2(0.0, -3.0), 0.5, 60.0],
					["aire_norte", Vector2(9.0, -42.0), 16.0, Vector2(0.0, -22.0), 0.5, 60.0]]:
				g.player.p = br.spot(0.0, -70.0)
				g.cam.position = MapData.at(br.spot(v[1].x, v[1].y), v[2])
				g.cam.look_at(MapData.at(br.spot(v[3].x, v[3].y), v[4]))
				g.cam.fov = v[5]
				await _frames(6)
				await _shot("puente_%s_%s" % ["limpio" if clean else "obra", v[0]])
		g.phase = "free"
		await _arroyuelo_checks(true)
		print("PUENTE %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--toros"):         # just the old bullring: the ruin and then restored, from the three streets, from inside, from the air
'''
CHECKS = '''## The old bridge of the Arroyuelo Medio as rebuilt by hand (puente.gd): the bed, its raised pavements, the houses of
## the row level with them, and the demolition works that wait round it until the signatures stop them. `walk`: also
## go on foot up the steps, across the bridge and down to the Calle de Matías Pérez, and let the works leave by
## themselves. (What the story does with the bridge -- the demonstration, the signatures, the council's tape -- is
## _firmas_checks and _puente_checks.)
func _arroyuelo_checks(walk := false) -> void:
	var b = g.bridge
	var space := get_tree().root.get_world_3d().direct_space_state
	var ray := func(a: Vector2, c: Vector2, h: float) -> bool:
		return not space.intersect_ray(PhysicsRayQueryParameters3D.create(MapData.at(b.spot(a.x, a.y), h), MapData.at(b.spot(c.x, c.y), h), 1)).is_empty()
	var was_works: bool = b.works
	var was_auto: bool = b.auto
	var was_closed: bool = b.closed()
	b.auto = false
	var floors := ""
	var level_ok := true
	for id in ["arroyuelo_34", "arroyuelo_36"]:
		for h in MapData.houses:
			if String(h["id"]) == id:
				floors += "%s %.2f " % [id, float(h["base"]) - b.top]
				level_ok = level_ok and (MapData.puente.is_empty() or (float(h["base"]) > b.top - 0.03 and float(h["base"]) < b.top + 0.25))      # (on it, or a doorstep above)
	var east: float = MapData.foot(b.spot(4.0, -8.0)) - b.top
	var west: float = MapData.foot(b.spot(-4.0, -8.0)) - b.top
	var up_e: float = MapData.foot(b.spot(4.6, -30.0)) - MapData.height(b.spot(0.0, -30.0))
	var up_w: float = MapData.foot(b.spot(-4.0, -30.0)) - MapData.height(b.spot(0.0, -30.0))
	var deck: float = b.top - MapData.height(b.p)
	_check(b.pieces > 120 and level_ok and absf(east) < 0.02 and absf(west) < 0.02 and up_e > 0.3 and up_e < 0.9 and absf(up_e - up_w) < 0.05 and deck > 0.8 and deck < 1.3
		and absf(MapData.foot(b.spot(0.0, -8.0)) - MapData.height(b.spot(0.0, -8.0))) < 0.001,
		"the old bridge is built by hand (%d pieces): its deck %.2f m over the bed, a raised pavement each side level with it (%.2f and %.2f m off) and %.2f m over the bed further up; the houses beside it stand on the pavement (%s)" % [b.pieces, deck, east, west, up_e, floors])
	_check(ray.call(Vector2(0.0, -8.0), Vector2(4.2, -8.0), 0.4) and ray.call(Vector2(0.0, -8.0), Vector2(-4.2, -8.0), 0.4) and ray.call(Vector2(0.0, -25.0), Vector2(4.4, -25.0), 0.3)
		and ray.call(Vector2(0.0, -4.0), Vector2(0.0, 4.0), 0.5) and not ray.call(Vector2(-2.6, 0.0), Vector2(2.6, 0.0), deck + 1.0),
		"the walls of the pavements stop you in the bed, the bridge stops whatever comes along it, and its deck is clear between its parapets")
	# the works: an excavator below the bridge, the fence and the truck up the bed; and nothing of them when they are gone
	b.set_works(true)
	await _frames(4)
	var there: bool = b._works_node.visible and ray.call(Vector2(-2.9, 6.7), Vector2(3.6, 6.7), 1.0) and ray.call(Vector2(0.9, -14.0), Vector2(0.9, -17.5), 1.0) and ray.call(Vector2(-3.0, -23.0), Vector2(3.0, -23.0), 1.5)
	b.set_works(false)
	await _frames(4)
	var gone: bool = not b._works_node.visible and not ray.call(Vector2(-2.9, 6.7), Vector2(3.6, 6.7), 1.0) and not ray.call(Vector2(0.9, -14.0), Vector2(0.9, -40.0), 1.0) and not ray.call(Vector2(-3.0, -23.0), Vector2(3.0, -23.0), 1.5)
	var near_road := 99.0
	for q in b.yard:
		for s in MapData.segs:
			if MapData.drivable(s):
				near_road = minf(near_road, MapData.seg_point(s, q).distance_to(q))
	_check(there and gone and near_road > 1.6, "with the works: the excavator below the bridge, the site fence and the truck up the bed are there and solid; without: nothing of them is left; nothing of it all stands in the way of the traffic (%.1f m from the nearest lane at the least)" % near_road)
	if walk:
		var back: Vector2 = g.player.p
		b.close_off(false)
		g.player.p = b.spot(4.4, 6.5)
		await _frames(4)
		var left: float = await _walk_at(b.spot(4.1, 1.0), 6.0)
		var on_pav: float = g.player.global_position.y - b.top
		var left2: float = await _walk_at(b.spot(4.1, 0.0), 2.0)
		left2 = await _walk_at(b.spot(-4.3, 0.0), 8.0)
		var on_far: float = g.player.global_position.y - b.top
		var left3: float = await _walk_at(b.spot(-5.4, 0.1), 3.0)
		left3 = await _walk_at(b.spot(-7.9, 0.1), 5.0)
		var down: float = g.player.global_position.y - MapData.height(g.player.p)
		_check(left < 0.6 and absf(on_pav) < 0.12 and left2 < 0.6 and absf(on_far) < 0.12 and left3 < 0.7 and absf(down) < 0.2,
			"on foot: up the steps to the pavement (%.1f m short, %.2f m off its level), across the bridge to the corner (%.1f short, %.2f off) and down its steps to the Calle de Matías Pérez (%.1f short, %.2f over the ground)" % [left, on_pav, left2, on_far, left3, down])
		# the works leave by themselves: the first morning after the signatures are in, with the player far away and not looking
		var si_was: int = g.si
		var stats_was: Dictionary = g.stats.duplicate()
		b.set_works(true)
		b.auto = true
		g.si = g._idx("alberto_back") + 1
		g.stats.erase("obra_fuera")
		g.stats["obra_h"] = g._now_h() - 0.2
		g.player.p = b.spot(0.0, -400.0)
		await _frames(6)
		var waits: bool = b.works                     # (far away, but it is not yet the morning after)
		g.stats["obra_h"] = g._now_h() - 30.0
		b._done_h = -1.0
		g.player.p = b.spot(2.0, 20.0)
		await _frames(6)
		var seen: bool = b.works                      # (the morning after, but the player is standing there)
		g.player.p = b.spot(0.0, -400.0)
		await _frames(6)
		var left_alone: bool = not b.works and g.stats.has("obra_fuera")
		g.si = g._idx("alberto")
		await _frames(6)
		var again: bool = b.works and not g.stats.has("obra_fuera")
		_check(waits and seen and left_alone and again, "the works wait until the first morning after the signatures are handed in, do not go while the player is there, are gone once the player is far away and not looking, and are back in a game begun again")
		g.si = si_was
		g.stats = stats_was
		g.player.p = back
	b.auto = was_auto
	b.set_works(was_works)
	b.close_off(was_closed)

## The old bullring (toros.gd), in its two states. `walk`: also go on foot into the restored ring by its door.
'''
patch('godot/scripts/selftest.gd', [
    ('''	if OS.get_cmdline_user_args().has("--toros"):         # just the old bullring: the ruin and then restored, from the three streets, from inside, from the air
''', MODE),
    ('''## The old bullring (toros.gd), in its two states. `walk`: also go on foot into the restored ring by its door.
''', CHECKS),
    ('''	await _toros_checks()
	var th: Dictionary = MapData.townhall
''', '''	await _toros_checks()
	await _arroyuelo_checks()
	var th: Dictionary = MapData.townhall
'''),
])
