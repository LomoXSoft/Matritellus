extends Node
## Developer check: plays Day 0 from start to bed by teleporting between objectives.
##   godot --path godot -- --selftest            (add --shots to save screenshots into godot/shots/)

const Creator = preload("res://scripts/creator.gd")
const CarS = preload("res://scripts/car.gd")
const PartsS = preload("res://scripts/parts.gd")

var g
var fails := 0
var shots := false

func _ready() -> void:
	g = get_parent()
	g.dwell = 0.0                                  # (a mission's circle counts at once here; _reglas_checks tries the two seconds)
	shots = OS.get_cmdline_user_args().has("--shots")
	if DisplayServer.get_name() != "headless":      # (a test's window takes no keys: whatever is being typed on the PC meanwhile went to it, and pressed through its menus)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	_run.call_deferred()

func _frames(n: int) -> void:
	await get_tree().create_timer(n / 30.0).timeout   # time-based, so it behaves the same at any frame rate

## in the character creator: go to the row of this option and choose this value
func _creator_pick(option: int, value: int) -> void:
	g.creator_goto(option)
	var guard := 0
	while g.look_sel[option] != value and guard < 40:
		g._creator_input("right")
		guard += 1

## is the story at the step with this id?
func _at(id: String) -> bool:
	return g.steps[g.si]["id"] == id

func _check(cond: bool, what: String) -> void:
	print(("  ok    " if cond else "  FAIL  ") + what)
	if not cond:
		fails += 1

func _skip_dialog(take := true) -> void:
	var guard := 0
	var this_one = g.dlg                    # only the conversation on screen now, not whatever it leads to
	while g.dlg != null and is_same(g.dlg, this_one) and guard < 60:
		g.dlg["cool"] = 0.0
		g.dialog_advance()
		guard += 1
	if take and g.menu.visible and g._choice.get("offer", false):       # a mission is being offered: take it
		g._choose(0)
	await _frames(3)

func _shot(name: String) -> void:
	if not shots:
		return
	await _frames(20)
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	get_viewport().get_texture().get_image().save_png("res://shots/%s.png" % name)

func _drive_to(place: String) -> void:
	var a: Dictionary = g.places[place]
	var c = g.in_car
	c.place(a["p"] - a["u"] * 14.0, atan2(a["u"].x, a["u"].y))
	c.set_speed(a["u"] * 9.0)
	g.cam_yaw = c.h
	var guard := 0
	while g.dlg == null and g.phase == "play" and g.steps[g.si].get("place", "") == place and guard < 240:
		c.set_speed(a["u"] * 9.0)
		await get_tree().physics_frame
		guard += 1

## real driving on the vehicle physics: floor it down a street, steer, brake, hit a wall
func _driving_checks() -> void:
	var c = g.paca_car
	var a: Dictionary = g.places["tanatorio"]
	c.place(a["p"] - a["u"] * 60.0, atan2(a["u"].x, a["u"].y))
	await _frames(20)
	var off_ground: float = c.global_position.y - MapData.height(c.p)
	_check(absf(off_ground) < 0.4 and c.global_transform.basis.y.y > 0.95 and absf(MapData.height(c.p)) > 0.5, "car settles on its wheels, on the slope of the street (%.2f above ground that is at %.1f m)" % [off_ground, MapData.height(c.p)])
	var h0: float = c.h
	var p0: Vector2 = c.p
	var vmax := 0.0
	var drift := 0.0
	for i in range(90):
		c.drive(1.0, 0.0, false, true, 1.0 / 60.0)
		await get_tree().physics_frame
		vmax = maxf(vmax, c.forward_speed())
		drift = maxf(drift, absf(angle_difference(h0, c.h)))
	var along: float = (c.p - p0).dot(a["u"])
	_check(vmax > 8.0 and along > 8.0, "throttle drives it forward (%.1f m/s after 1.5 s, %.0f m)" % [vmax, along])
	_check(drift < 0.2, "it tracks straight")
	c.place(a["p"] - a["u"] * 60.0, h0)
	c.set_speed(a["u"] * 8.0)
	for i in range(40):
		c.drive(0.6, 1.0, false, true, 1.0 / 60.0)
		await get_tree().physics_frame
	_check(angle_difference(h0, c.h) > 0.15, "steering left turns left (%.2f rad)" % angle_difference(h0, c.h))
	_check(c.global_transform.basis.y.y > 0.9, "and it stays upright in the turn")
	c.place(a["p"] - a["u"] * 60.0, h0)
	c.set_speed(a["u"] * 15.0)
	for i in range(90):
		c.drive(-1.0, 0.0, false, true, 1.0 / 60.0)
		await get_tree().physics_frame
	_check(absf(c.forward_speed()) < 4.0, "brakes stop it from 54 km/h in 1.5 s (now %.1f m/s)" % c.forward_speed())
	# a wall stops it and registers as a crash
	var wall_hit := false
	c.place(a["p"], h0 + PI / 2.0)
	c.last_impact = 0.0
	for i in range(300):
		c.drive(1.0, 0.0, false, true, 1.0 / 60.0)
		await get_tree().physics_frame
		if c.last_impact > 0.0:
			wall_hit = true
			break
	_check(wall_hit, "driving into a building is a crash (impact %.1f)" % c.last_impact)
	c.last_impact = 0.0
	c.place(g.places["home"]["p"] + g.places["home"]["u"] * 9.0, 0.0)
	c.park()
	# the player cannot walk through a wall
	var pl = g.player
	var start: Vector2 = pl.p
	var side: Vector2 = Vector2(-g.places["home"]["u"].y, g.places["home"]["u"].x)
	for i in range(240):
		pl.walk(side, 5.0)
		await get_tree().physics_frame
	var walked: float = (pl.p - start).length()
	_check(walked < 19.0, "walking at a facade stops at the wall (moved %.1f m, 20 m if nothing stopped it)" % walked)
	pl.p = start

## a long, wide, straight piece of real street: {p: start, u: direction}
func _long_street() -> Dictionary:
	for s in MapData.segs:
		if MapData.drivable(s) and s.a.distance_to(s.b) > 70.0 and float(MapData.clr[s.na]) > 5.0 and float(MapData.clr[s.nb]) > 5.0 and s.a.length() < 900.0:
			_tow_away(s)
			return {"p": s.a, "u": (s.b - s.a).normalized()}
	return g.places["home"]

## Performance test. Run it WITHOUT --fixed-fps and without --headless:
##     godot --path godot -- --selftest --bench            (add --window to stay in a window instead of full screen)
## It stands you in the Plaza del Ayuntamiento at midday, measures the frame rate as the game is, and then switches
## things off one at a time to see what each of them costs. The table goes to the console and to tools/bench.txt.
var _bench_rows: Array = []

func _measure(label: String, seconds := 2.5) -> void:
	for i in range(20):
		await get_tree().process_frame
	var vp := get_viewport().get_viewport_rid()
	var f0 := Engine.get_frames_drawn()
	var t0 := Time.get_ticks_usec()
	var proc := 0.0
	var phys := 0.0
	var gpu := 0.0
	var cpu := 0.0
	var n := 0
	while Time.get_ticks_usec() - t0 < int(seconds * 1000000.0):
		await get_tree().process_frame
		proc += Performance.get_monitor(Performance.TIME_PROCESS)
		phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp)
		n += 1
	var secs := (Time.get_ticks_usec() - t0) / 1000000.0
	var fps := (Engine.get_frames_drawn() - f0) / secs
	var row := "%-34s %7.1f fps  %6.2f ms/frame | script %5.2f ms  physics tick %5.2f ms | render cpu %5.2f ms  gpu %5.2f ms | %5d draw calls  %6d objects  %5.2f M tris" % [
		label, fps, 1000.0 / maxf(fps, 0.01), proc / n * 1000.0, phys / n * 1000.0, cpu / n, gpu / n,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000000.0]
	print(row)
	_bench_rows.append(row)

func _bench() -> void:
	var args := OS.get_cmdline_user_args()
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if not args.has("--window"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	g.menu.close()
	g.phase = "free"
	g.hud.play_ui.visible = true
	g.set_time(13.0)
	var th: Dictionary = MapData.townhall
	var m := Vector2(th["m"][0], th["m"][1])
	var u := Vector2(th["u"][0], th["u"][1])
	var nn := Vector2(-u.y, u.x)
	g.player.p = m + nn * 30.0
	g.cam_yaw = atan2(-nn.x, -nn.y)
	g.cam_pitch = 0.25
	g._keep_crowd_near(g.player.p, 200)
	await _frames(90)
	var size: Vector2i = get_viewport().get_visible_rect().size
	var head := "Matritellus bench · %s · %s · drawn at %d x %d · MSAA 4x" % [RenderingServer.get_video_adapter_name(), OS.get_processor_name(), DisplayServer.window_get_size().x, DisplayServer.window_get_size().y]
	print(head)
	_bench_rows.append(head)
	if args.has("--probe"):
		await RenderingServer.frame_post_draw
		print("probe: the picture actually drawn is ", get_viewport().get_texture().get_image().get_size())
		return
	_bench_rows.append("(view: on foot in the Plaza del Ayuntamiento, midday; %d neighbours, %d parked cars, %d lanterns)" % [g.npcs.size(), g.cars.size(), g.lights.spots.size()])
	await _measure("as the game is")
	# what the pieces of one game tick cost, each called on its own a few hundred times
	var pp: Vector2 = g.player.p
	var pieces := {
		"neighbours (_update_npcs)": func(): g._update_npcs(1.0 / 60.0, pp),
		"  of which keeping them apart": func(): g._keep_apart(pp),
		"traffic (tick)": func(): g.traffic.tick(1.0 / 60.0, pp, false),
		"police (tick, no chase)": func(): g.police.tick(1.0 / 60.0, pp, Vector2.ZERO, null, false, false),
		"tow truck (tick)": func(): g.tow.tick(1.0 / 60.0, pp, false),
		"sky (clouds, birds)": func(): g.sky_fx.tick(1.0 / 60.0, g.cam.global_position, pp),
		"lanterns (tick)": func(): g.lights.tick(1.0, pp),
		"light of day (_apply_sky)": func(): g._apply_sky(),
		"what is near me (_find_interaction)": func(): g._find_interaction(),
		"GPS (update_route)": func(): MapData.update_route(pp),
		"sound (_update_audio)": func(): g._update_audio(1.0 / 60.0),
		"camera (_update_camera)": func(): g._update_camera(1.0 / 60.0, pp, 0.0, 0.0),
		"garages, door, gate": func(): g.props.repair_at(null, 1.0 / 60.0),
	}
	for name in pieces:
		var fn: Callable = pieces[name]
		var t0 := Time.get_ticks_usec()
		for i in range(200):
			fn.call()
		var each := (Time.get_ticks_usec() - t0) / 200.0 / 1000.0
		var row := "    %-38s %6.3f ms a call" % [name, each]
		print(row)
		_bench_rows.append(row)
	# --- one thing off at a time, then back on ---
	g.outline.visible = false
	await _measure("no ink outline")
	g.outline.visible = true
	g.env.ssao_enabled = false
	await _measure("no SSAO (contact shadows)")
	g.env.ssao_enabled = true
	g.env.glow_enabled = false
	await _measure("no glow")
	g.env.glow_enabled = true
	g.sun.shadow_enabled = false
	await _measure("no sun shadows")
	g.sun.shadow_enabled = true
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	await _measure("no MSAA (it is 4x)")
	get_viewport().msaa_3d = Viewport.MSAA_4X
	get_viewport().scaling_3d_scale = 0.5
	await _measure("3D at half resolution")
	get_viewport().scaling_3d_scale = 1.0
	g.hud.root.visible = false
	await _measure("no HUD at all")
	g.hud.root.visible = true
	g.hud.minimap.visible = false
	await _measure("no minimap")
	g.hud.minimap.visible = true
	g.sky_fx.visible = false
	await _measure("no clouds, birds, stars")
	g.sky_fx.visible = true
	g.set_time(23.0)
	await _frames(20)
	await _measure("at night (lanterns, windows)")
	g.set_time(13.0)
	# --- and now for good, one on top of another ---
	for n in g.npcs:
		n.away = true
		n.visible = false
	await _measure("- neighbours gone")
	g.traffic.clear()
	g.traffic._spawn_t = 99999.0
	await _measure("- and no traffic")
	for c in g.cars.duplicate():
		if c != g.paca_car:
			g.cars.erase(c)
			c.queue_free()
	await _measure("- and no parked cars")
	g.outline.visible = false
	g.env.ssao_enabled = false
	g.env.glow_enabled = false
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	await _measure("- and no outline/SSAO/glow/MSAA")
	g.sun.shadow_enabled = false
	await _measure("- and no shadows")
	var f := FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../tools/bench.txt"), FileAccess.WRITE)
	if f != null:
		f.store_string("
".join(_bench_rows) + "
")

## a long, wide, straight stretch of street with nothing built close to it: somewhere to measure things
func _clear_street():
	for s in MapData.segs:
		if MapData.drivable(s) and s.road["k"] == 0 and s.a.distance_to(s.b) > 95.0 and MapData.fitted_hw(s) >= 3.4 and s.a.length() < 900.0 and float(MapData.clr[s.na]) > 5.0 and float(MapData.clr[s.nb]) > 5.0:
			_tow_away(s)
			return s
	return null

## cars are parked about the town at random: clear away any that happen to be standing in the street we measure on
func _tow_away(s) -> void:
	var u: Vector2 = (s.b - s.a).normalized()
	for c in g.cars.duplicate():
		if c == g.in_car or c == g.paca_car:
			continue
		var rel: Vector2 = c.p - s.a
		var along := rel.dot(u)
		if along > -30.0 and along < s.a.distance_to(s.b) + 30.0 and absf(rel.dot(Vector2(-u.y, u.x))) < 9.0:
			g.cars.erase(c)
			c.queue_free()

## Vehicles on a job stop for nobody: a tow truck on its way to a breakdown sends a neighbour in the road flying, and
## it is not your doing. But it still brakes for you.
func _duty_checks() -> void:
	var seg = _clear_street()
	if seg == null:
		return
	var u: Vector2 = (seg.b - seg.a).normalized()
	g.set_time(11.0)
	g.police.reset()
	g.traffic.clear()
	g.tow.clear()
	g.traffic._spawn_t = 99999.0
	if g.in_car != null:
		g.in_car.set_speed(Vector2.ZERO)
		g._exit_car()
	var rightv := Vector2(-u.y, u.x)
	var lane := clampf(MapData.fitted_hw(seg) * 0.3, 0.6, 1.25)
	g.player.p = seg.a + u * 30.0 + rightv * (MapData.fitted_hw(seg) + 3.0)        # on the pavement, watching
	await _frames(10)
	var e: Dictionary = g.traffic.add("grua", 0, seg.na, seg.nb)
	e["job"] = true
	e["route"] = []
	var truck = e["car"]
	truck.place(seg.a + u * 4.0 + rightv * lane, atan2(u.x, u.y))
	var man = g.spawn_neighbour(seg.a + u * 34.0 + rightv * lane, true)
	man.still = true
	man.home = man.p
	var heat: float = g.police.heat
	var bumped: int = g.bumped
	var flung: int = g.duty_flung
	var slowest := 99.0
	var flew := false
	for i in range(8 * 60):
		await get_tree().physics_frame
		if truck.p.distance_to(seg.a) > 16.0 and truck.p.distance_to(seg.a) < 34.0:
			slowest = minf(slowest, truck.vel.length())
		flew = flew or man.state == "fly"
		if truck.p.distance_to(seg.a) > 40.0:
			break
	_check(flew and g.duty_flung > flung and slowest > 4.0 and g.police.heat == heat and g.bumped == bumped,
		"a tow truck on a job does not brake for a neighbour in the road: off they fly (%s; slowest %.1f m/s on the way), and it is not on you (heat %.0f -> %.0f)" % [man._label.text if man.is_barking() else "-", slowest, heat, g.police.heat])
	g.npcs.erase(man)
	man.queue_free()
	# but you, standing in the road, it does stop for
	g.traffic.clear()
	await _frames(5)
	var e2: Dictionary = g.traffic.add("grua", 0, seg.na, seg.nb)
	e2["job"] = true
	e2["route"] = []
	var t2 = e2["car"]
	t2.place(seg.a + u * 4.0 + rightv * lane, atan2(u.x, u.y))
	g.player.p = seg.a + u * 30.0 + rightv * lane
	var you_flew := false
	for i in range(8 * 60):
		await get_tree().physics_frame
		g.player.p = seg.a + u * 30.0 + rightv * lane
		you_flew = you_flew or t2.p.distance_to(seg.a) > 30.5
	_check(not you_flew and t2.p.distance_to(g.player.p) < 12.0, "but it does stop for you (%.1f m short)" % t2.p.distance_to(g.player.p))
	g.traffic.clear()
	g.player.p = seg.a + u * 30.0 + rightv * (MapData.fitted_hw(seg) + 3.0)

## a car that gets nowhere for half a minute: the driver rings for the tow truck, and it comes
func _tow_checks(opposite := false) -> void:
	var seg = _clear_street()
	if seg == null:
		return
	var u: Vector2 = (seg.b - seg.a).normalized()
	var rightv := Vector2(-u.y, u.x)
	g.set_time(11.0)
	g.police.reset()
	g.traffic.clear()
	g.tow.clear()
	g.traffic._spawn_t = 99999.0
	if g.in_car != null:
		g.in_car.set_speed(Vector2.ZERO)
		g._exit_car()
	g.player.p = seg.a + u * 39.0 + rightv * (MapData.fitted_hw(seg) + 2.0)        # on the pavement, watching
	g.player.h = atan2(u.x, u.y)
	g.cam_yaw = g.player.h + 0.35
	g.cam_pitch = 0.16
	g.indoors = false
	await _frames(20)
	var people: int = g.npcs.size()
	var e: Dictionary = g.traffic.add("panda", 0, seg.na, seg.nb)
	var victim = e["car"]
	victim.place(seg.a + u * 48.0 + rightv * 1.0, atan2(u.x, u.y))
	e["halt"] = true                             # it will not budge
	e["mark"] = victim.p
	e["idle"] = 29.6
	await _frames(40)
	_check(not g.traffic.list.has(e) and g.tow.jobs.size() == 1 and g.npcs.size() == people + 1, "a car that has got nowhere for 30 seconds: the driver gets out")
	if g.tow.jobs.is_empty():
		return
	var job: Dictionary = g.tow.jobs[0]
	var driver = job["driver"]
	if opposite:
		job["retry"] = 99999.0                   # (we send the truck ourselves, from the far end of the street)
	_check(job["state"] == "call" and driver.phone and driver.p.distance_to(victim.p) < 4.5 and (driver.p - victim.p).dot(u) > 1.0, "stands in front of it and gets a phone out")
	await _frames(40)
	_check(driver.is_barking(), "and talks into it (%s)" % driver._label.text)
	await _shot("tow_1_call")
	var hooked := false
	var truck = null
	var spawn_far := 0.0
	var spawn_seen := false
	for i in range(9 * 60):
		await get_tree().physics_frame
		if truck == null and job["truck"] != null:           # (it may set out the moment the call ends)
			truck = job["truck"]["car"]
			spawn_far = truck.p.distance_to(g.player.p)
			spawn_seen = g.sees(truck.p)
	_check(job["state"] == "wait" and not driver.phone, "then waits by the car")
	if opposite:
		var te: Dictionary = g.traffic.add("grua", 0, seg.nb, seg.na)
		te["job"] = true
		te["route"] = []
		job["truck"] = te
		job["t"] = 0.0
		job["route_t"] = 6.0
		job["close_t"] = 0.0
	for i in range(150 * 60):
		await get_tree().physics_frame
		if truck == null and job["truck"] != null:
			truck = job["truck"]["car"]
			spawn_far = truck.p.distance_to(g.player.p)
			spawn_seen = g.sees(truck.p)
		if job["state"] == "tow" or not g.tow.jobs.has(job):
			hooked = job["state"] == "tow"
			break
		if truck != null and i % 300 == 0 and OS.get_cmdline_user_args().has("--traza"):
			var close: Array = []
			for o in g.traffic._obs:
				if o[4] != truck and (o[0] as Vector2).distance_to(truck.p) < 9.0:
					close.append("%s %s%s" % [["car", "person", "fixed"][o[3]], str((o[0] as Vector2).round()), (" " + str(o[4].kind) + (" parked" if g.cars.has(o[4]) else "")) if o[4] != null and o[4] != g.player else ""])
			print("  tow trace %3d s: truck at %s, %.1f m/s, %.0f m to go, wait %.1f stuck %.1f tries %d rev %.1f dbg %s | near: %s" % [i / 60, str(truck.p), truck.vel.length(), truck.p.distance_to(victim.p),
				job["truck"]["wait"], job["truck"]["stuck"], job["truck"].get("tries", 0), job["truck"].get("rev", 0.0), str(job["truck"].get("dbg", "")), str(close)])
	_check(truck != null and truck.kind == "grua" and (opposite or (spawn_far > 60.0 and not spawn_seen)), "a tow truck sets out from somewhere you cannot see (%.0f m away)" % spawn_far)
	if not hooked and truck != null:             # (who is it waiting for? the nearest people to its nose)
		var who: Array = []
		for n in g.npcs:
			if n.visible and not n.away and n.p.distance_to(truck.p) < 9.0:
				who.append("%s%s %s %.1f m %s" % [n.id if n.id != "" else "neighbour", " (still)" if n.still else "", n.state, n.p.distance_to(truck.p), str(n.p)])
		print("  tow: in the way? %s | player %s %.1f m from the truck, in a car: %s | driver of the job %s" % [str(who), str(g.player.p), g.player.p.distance_to(truck.p), g.in_car != null, str(job["driver"].p) if job["driver"] != null else "-"])
	_check(hooked and victim.freeze and victim.global_position.y - MapData.height(victim.p) > 0.2, "it reaches the car and winches it on (by the %s)%s" % ["nose" if job["front"] else "tail", "" if hooked else " -- %s, truck %.0f m away at %.0f, %.0f doing %.1f m/s, %s" % [job["state"], truck.p.distance_to(victim.p) if truck != null else -1.0, truck.p.x if truck != null else 0.0, truck.p.y if truck != null else 0.0, truck.forward_speed() if truck != null else 0.0, str({"halt": job["truck"].get("halt"), "wait": snappedf(job["truck"]["wait"], 0.1), "stuck": snappedf(job["truck"]["stuck"], 0.1), "rev": snappedf(job["truck"]["rev"], 0.1), "tries": job["truck"]["tries"], "route": (job["truck"]["route"] as Array).size(), "dbg": job["truck"].get("dbg", ""), "upright": snappedf(truck.global_transform.basis.y.y, 0.01), "off": snappedf(truck.global_position.y - MapData.height(truck.p), 0.01)}) if job["truck"] != null else "no truck"]])
	if not hooked:
		return
	_check(not g.traffic.on_duty(job["truck"]), "with the car on the hook it is in no hurry: it drives like anybody again (brakes for neighbours)")
	await _shot("tow_2_hooked")
	var from_p: Vector2 = truck.p
	var gap := 0.0
	var away_t := 0.0
	for i in range(25 * 60):                     # (a neighbour crossing in front of it holds it up, as it should: give it time)
		await get_tree().physics_frame
		if not g.tow.jobs.has(job):
			break
		away_t += 1.0 / 60.0
		gap = maxf(gap, Vector2(victim.global_position.x, victim.global_position.z).distance_to(truck.p))
		if i == 70:
			await _shot("tow_3_towing")
		if i >= 8 * 60 and truck.p.distance_to(from_p) > 15.0:
			break
	_check(truck.p.distance_to(from_p) > 15.0 and gap < 8.0 and not driver.visible, "and drives off with it on the hook, the driver in the cab (%.0f m in %.0f s; %s)" % [truck.p.distance_to(from_p), away_t, str({"halt": job["truck"].get("halt"), "wait": snappedf(job["truck"]["wait"], 0.1), "stuck": snappedf(job["truck"]["stuck"], 0.1), "rev": snappedf(job["truck"]["rev"], 0.1), "tries": job["truck"]["tries"], "route": (job["truck"]["route"] as Array).size(), "a": job["truck"]["a"], "b": job["truck"]["b"], "v": snappedf(truck.forward_speed(), 0.1), "dbg": job["truck"].get("dbg", ""), "slope": snappedf(MapData.normal(truck.p).y, 0.001), "up": snappedf(truck.global_transform.basis.y.y, 0.01)})])
	if g.tow.jobs.has(job):
		job["dest"] = truck.p                    # (as if the garage were right here)
		await _frames(10)
	_check(not g.tow.jobs.has(job) and g.cars.has(victim) and not victim.freeze and victim.hp == victim.spec["hp"] and g.npcs.size() == people and not job["truck"].has("job"), "at the garage the car is left parked and mended, and the truck goes about its business")
	_check(g.props.repairs.any(func(r): return (r["p"] as Vector2).distance_to(g.taller.spot) < 0.1) and g.tow._garage(g.taller.apron + Vector2(30, 10)).distance_to(g.taller.spot) < 0.1,
		"Talleres Valdeacero is where the tow truck goes from round there")
	await _garage_bay_checks()
	var named_after := ""
	for r in MapData.roads:
		named_after += String(r["n"]) + "|"
	_check(named_after.contains("Valdeacero") and not named_after.contains("Valdehierro"), "everything named after the patroness says Valdeacero")
	# far away and unseen, the whole scene is simply cleared
	var e2: Dictionary = g.traffic.add("z15", 0, seg.na, seg.nb)
	var job2: Dictionary = g.tow.breakdown(e2["car"])
	g.traffic.list.erase(e2)
	g.player.p = seg.a + u * 30.0 - rightv * 400.0
	await _frames(20)
	_check(not g.tow.jobs.has(job2) and not is_instance_valid(job2["car"]) or job2["car"].is_queued_for_deletion(), "a breakdown nobody is near or looking at is quietly cleared away")
	g.player.p = g.places["home"]["p"]
	g.tow.clear()
	g.traffic.clear()
	g.traffic._spawn_t = 1.0

## neighbours at the wheel: getting round what is standing in the road, and out of trouble
func _traffic_checks() -> void:
	var seg = _clear_street()
	if seg == null:
		_check(false, "a street to try the traffic on")
		return
	var u: Vector2 = (seg.b - seg.a).normalized()
	var rightv := Vector2(-u.y, u.x)
	var hw: float = MapData.fitted_hw(seg)
	var lane := clampf(hw * 0.3, 0.6, 1.25)
	var heading := atan2(u.x, u.y)
	g.in_car.place(seg.a - u * 16.0, heading)          # traffic lives around the player: stand close by, out of the way
	g.traffic.clear()
	g.traffic._spawn_t = 99999.0
	g.police.reset()
	for n in g.npcs:                                   # nobody crossing while we measure
		if n.id == "" and n.p.distance_to(seg.a + u * 45.0) < 80.0:
			n.away = true
	var extra: Array = []
	var park := func(kind: String, along: float, across: float):
		var c = CarS.new()
		g.add_child(c)
		c.setup(kind, 0xd9643a, seg.a + u * along + rightv * across, heading)
		c.park()
		g.cars.append(c)
		extra.append(c)
		return c
	# 0. the Julietta, with and without its turbo, on a clear run
	var jul = CarS.new()
	g.add_child(jul)
	jul.setup("julietta", 0, seg.a + u * 4.0 + rightv * lane, heading)
	await _frames(10)
	for i in range(150):
		jul.drive(1.0, 0.0, false, true, 0.016)
		await get_tree().physics_frame
	var plain: float = jul.forward_speed()
	var hp_after: float = jul.hp
	var first_end: Vector2 = jul.p
	jul.queue_free()                                   # (a fresh one for the turbo's run: the one put back in its place stuck at 0 km/h, now and then)
	jul = CarS.new()
	g.add_child(jul)
	jul.setup("julietta", 0, seg.a + u * 4.0 + rightv * lane, heading)
	await _frames(10)
	jul.turbo = true
	var lit := false
	for i in range(150):
		jul.drive(1.0, 0.0, false, true, 0.016)
		await get_tree().physics_frame
		lit = lit or (jul.flame != null and jul.flame.emitting)
	var boosted: float = jul.forward_speed()
	_check(plain > 12.0 and boosted > plain * 1.3 and lit, "the Julietta's turbo pushes much harder (%.0f km/h after 2.5 s instead of %.0f) and spits fire%s" % [boosted * 3.6, plain * 3.6,
		"" if boosted > plain * 1.3 else " -- first run ended %.0f m on at %.0f hp; now at %s, %.1f m from the start, sleeping %s, frozen %s, flipped %s, broken %s, wheels on the ground %d, near: %s" % [first_end.distance_to(seg.a + u * 4.0), hp_after, str(jul.p.round()), jul.p.distance_to(seg.a + u * 4.0 + rightv * lane), jul.sleeping, jul.freeze, jul.flipped(), jul.broken(),
			jul.wheels.filter(func(w): return w.is_in_contact()).size(), str(g.cars.filter(func(c): return is_instance_valid(c) and c != jul and c.p.distance_to(jul.p) < 8.0).map(func(c): return "%s %s" % [c.kind, str(c.p.round())]))]])
	# the nitro is a bottle: it runs down, burns out, and fills again at speed
	var left_half: float = jul.nitro
	for i in range(220):
		jul.drive(1.0, 0.0, false, true, 0.016)
		await get_tree().physics_frame
	var out_now: bool = jul.burnt and not jul.boosting and jul.nitro < 0.15 and not jul.flame.emitting      # (it is already filling again, a little)
	jul.turbo = false
	var fill_t := 0.0
	while jul.burnt and fill_t < 12.0:           # flat out (on the spot: put back every frame, so no street is long enough to matter)
		jul.place(seg.a + u * 4.0 + rightv * lane, heading)
		jul.set_speed(u * float(jul.spec["max"]) * 0.95)
		jul.drive(1.0, 0.0, false, true, 0.016)
		await get_tree().physics_frame
		fill_t += 1.0 / 60.0
	jul.place(seg.a + u * 4.0 + rightv * lane, heading)
	_check(left_half < 0.6 and left_half > 0.3 and out_now and not jul.burnt and jul.nitro >= jul.NITRO_BACK and fill_t > 3.0,
		"its nitro is a bottle: half gone after 2.5 s, burnt out after %.0f (no push, no fire), and fit again after %.1f s flat out" % [jul.NITRO_BURN, fill_t])
	var was_in = g.in_car                        # (whatever the player was driving: straight back into it afterwards)
	g._enter_car(jul)
	await _frames(3)
	_check(g.hud.gauge.style == "sport" and g.hud.gauge.top >= 200.0 and g.hud.gauge.nitro >= 0.0 and g.hud.gauge._fire.visible, "the dashboard is the car's own: a long black dial with the nitro in flames under it")
	jul.set_speed(Vector2.ZERO)
	if was_in != null:
		g._enter_car(was_in)
	else:
		g._exit_car()
	await _frames(3)
	_check(g.in_car == was_in and (was_in == null or g.hud.gauge.title == was_in.spec["name"]), "and changes with the car: back in the %s, its own dial" % (was_in.spec["name"] if was_in != null else "street"))
	jul.queue_free()
	await _frames(5)
	# 1. a car left standing in the lane
	var block = park.call("panda", 38.0, lane)
	await _frames(10)
	var block_at: Vector2 = block.p
	var e: Dictionary = g.traffic.add("z15", 0xf4f4f0, seg.na, seg.nb)
	var passed := false
	var widest := 0.0
	for i in range(16 * 60):
		await get_tree().physics_frame
		if not g.traffic.list.has(e):
			break
		var al: float = (e["car"].p - seg.a).dot(u)
		if al > 30.0 and al < 46.0:
			widest = maxf(widest, lane - (e["car"].p - seg.a).dot(rightv))
		if al > 47.0:
			passed = true
			break
	_check(passed and block.p.distance_to(block_at) < 0.5, "a neighbour who finds a car standing in the lane pulls out %.1f m and goes round it without touching it (it moved %.2f m)" % [widest, block.p.distance_to(block_at)])
	# 2. the street blocked right across: wait, then turn round and go back
	var count := int(ceil(hw * 2.0 / 2.2))
	var wall: Array = []
	for k in range(count):
		wall.append(park.call("panda", 78.0, lerpf(-hw + 0.9, hw - 0.9, float(k) / maxf(1.0, count - 1.0))))
	await _frames(5)
	var wall_at: Array = wall.map(func(c): return c.p)
	var turned := false
	var went_back := false
	for i in range(40 * 60):
		await get_tree().physics_frame
		if not g.traffic.list.has(e):
			break
		if e["b"] == seg.na:
			turned = true
		if turned and Vector2(sin(e["car"].h), cos(e["car"].h)).dot(u) < -0.8 and e["car"].forward_speed() > 2.5:
			went_back = true
			break
	var shoved := 0.0
	for k in range(wall.size()):
		shoved = maxf(shoved, wall[k].p.distance_to(wall_at[k]))
	_check(turned and went_back and shoved < 0.5, "with the street blocked from kerb to kerb it waits, then turns round in the road and drives back (the cars blocking it moved %.2f m)" % shoved)
	# 3. nose already up against something: back off and get round
	g.traffic.clear()
	block.place(seg.a + u * 38.0 + rightv * lane, heading)
	block.park()
	var e2: Dictionary = g.traffic.add("panda", 0x6fb7e6, seg.na, seg.nb)
	e2["car"].place(seg.a + u * 34.1 + rightv * lane, heading)
	var out := false
	var backed := false
	for i in range(30 * 60):
		await get_tree().physics_frame
		if not g.traffic.list.has(e2):
			break
		if e2["car"].forward_speed() < -0.5:
			backed = true
		if (e2["car"].p - seg.a).dot(u) > 47.0:
			out = true
			break
	_check(out and backed, "one that is already nose to tail with it backs off first, then goes round (backed off: %s, got past: %s, goes: %d)" % [backed, out, int(e2.get("tries", 0))])
	# 4. Los Pitufos drive better than anybody: a car abandoned in the middle of the street between them and you
	g.traffic.clear()
	block.place(seg.a + u * 46.0 + rightv * 0.2, heading + 0.5)          # skewed, right on the centre line
	block.park()
	g.in_car.place(seg.a + u * 92.0 + rightv * lane, heading)
	await _frames(10)
	block_at = block.p
	g.police.reset()
	g.police.add_heat(250.0)
	g.police.arrive()
	while g.police.cops.size() > 1:
		g.police.cops.pop_back()["car"].queue_free()
	var chaser = g.police.cops[0]["car"]
	chaser.place(seg.a + u * 4.0 + rightv * lane, heading)
	var reached := 0.0
	var fastest := 0.0
	for i in range(14 * 60):
		await get_tree().physics_frame
		g.police.heat = 100.0
		g.police.bust_t = 0.0
		reached += 1.0 / 60.0
		fastest = maxf(fastest, chaser.forward_speed())
		if chaser.p.distance_to(g.in_car.p) < 9.0:
			break
	_check(chaser.p.distance_to(g.in_car.p) < 9.0 and block.p.distance_to(block_at) < 0.4 and fastest > 14.0,
		"a patrol car swerves round a car left in the middle of the street without touching it and is on you in %.1f s (top speed %.0f km/h, the car moved %.2f m)" % [reached, fastest * 3.6, block.p.distance_to(block_at)])
	g.police.reset()
	for c in extra:
		g.cars.erase(c)
		c.queue_free()
	for n in g.npcs:
		if n.id == "" and not g.vip_crowd.has(n):
			n.away = false
	g.traffic.clear()
	g.traffic._spawn_t = 1.0

## the new cars, exhaust smoke, and how busy the streets are
## The old bridge, the demonstration by it, and Alberto's errand: five signatures before the light changes.
## Called with the game at the step after Alberto's speech.
func _firmas_checks() -> void:
	var b = g.bridge
	var space := get_tree().root.get_world_3d().direct_space_state
	# --- the bridge: people over it, no car under it, and the map knows
	var under := space.intersect_ray(PhysicsRayQueryParameters3D.create(MapData.at(b.spot(0.0, -6.0), 0.5), MapData.at(b.spot(0.0, 6.0), 0.5), 1))
	var north: int = b.seg.na
	var south: int = b.seg.nb
	var round_way := 0.0
	var last: Vector2 = MapData.nodes[north]
	for q in MapData.path(MapData.nodes[north], MapData.nodes[south]):
		round_way += q.distance_to(last)
		last = q
	_check(not under.is_empty() and not MapData.drivable(b.seg) and round_way > MapData.nodes[north].distance_to(MapData.nodes[south]) * 1.5,
		"the old bridge stands across the Arroyuelo Medio: no car gets under it, the traffic keeps out of that stretch and routes go round (%.0f m instead of %.0f)" % [round_way, MapData.nodes[north].distance_to(MapData.nodes[south])])
	var fenced: bool = b.closed()                # (until the town makes it its own the council has it fenced off: _puente_checks; here, the bridge itself)
	b.close_off(false)
	var walker = g.spawn_neighbour(b.spot(b.open * (b.half + 0.8), -0.8), true)      # (La Chiki is standing on the other side of the deck)
	g.npcs.erase(walker)                         # (ours to walk: the game is not to move it about as well)
	var started: float = walker.global_position.y - MapData.foot(walker.p)      # (on the pavement, wherever its ground is)
	var highest := 0.0
	for i in range(260):
		walker.walk(b.across * -b.open, 2.4)
		highest = maxf(highest, walker.global_position.y - MapData.height(walker.p))
		await get_tree().physics_frame
	var got_to: float = (walker.p - b.p).dot(b.across * -b.open)
	b.close_off(fenced)
	_check(absf(started) < 0.02 and got_to > b.half - 1.3 and absf(highest - (b.top - MapData.height(b.p))) < 0.08,
		"and people walk over it: from the pavement up the steps, %.2f m above the street across the deck, to the far end (%.1f m past the middle of a deck %.1f m long)" % [highest, got_to, b.half * 2.0])
	g.npcs.erase(walker)
	walker.queue_free()
	var chiki = g.named["chiki"]
	var placards := 0
	for n in g.protesters:
		if n.vis.get_child_count() > 0 and n.vis.get_children().any(func(c): return c is Node3D and c.get_child_count() == 4 and c.get_child(2) is Label3D):
			placards += 1
	_check(g.protesters.size() == 13 and placards >= 6 and b.dressing != null and absf(chiki.global_position.y - b.top) < 0.05 and chiki.look_data["top"] == 10,
		"the demonstration is there: %d neighbours, %d of them with a placard, the banner up, and La Chiki standing on the bridge in her blue sweatshirt and leopard-print trousers" % [g.protesters.size(), placards])
	# --- the errand
	var f = g.firmas
	var left: float = (f["until"] - g._now_h()) if f != null else 0.0
	_check(_at("firmas") and f != null and f["need"] == 5 and f["plan"].size() == 8 and f["plan"].count(false) == 3 and f["plan"][-1] and left >= 5.0 and left <= 29.0
		and (f["dawn"] == (absf(fposmod(f["until"], 24.0) - g.DAWN_AT) < 0.01)) and g.hud.obj_text.text.contains("0") and g.hud.obj_text.text.contains("5"),
		"Alberto wants five signatures %s (%.1f hours of the clock from now); three of the first seven people asked will say no" % ["before dawn" if (f != null and f["dawn"]) else "before nightfall", left])
	if f == null:
		return
	# too late: back to Alberto, who does not make the whole speech again
	g.firmas["until"] = g._now_h() - 0.1
	await _frames(4)
	var late: bool = _at("alberto") and g.firmas == null and int(g.stats.get("firmas_fail", 0)) == 1
	g.talk_to(g.named["alberto"])
	var short: bool = g.dlg != null and g.dlg["lines"].size() == Loc.t("alberto_again").size()
	await _skip_dialog()
	_check(late and short and _at("firmas") and g.firmas != null and g.firmas["got"] == 0, "let the light change without them and they are void: back to Alberto, who sends you out again in two sentences")
	# those at the demonstration have signed already, each in their own way
	var were: bool = not g.folk.knows("chiki") and not g.folk.knows("alberto")
	var said: Array = []
	for n in [g.named["alberto"], chiki, g.protesters[0], g.protesters[-1]]:
		g.talk_to(n)
		said.append(g.dlg["lines"][0] if g.dlg != null else "")
		await _skip_dialog()
	_check(said[0] == Loc.t("firma_alberto")[0] and said[1] == Loc.t("firma_chiki")[0] and said[2] != "" and said[3] != "" and said[2] != said[3] and g.firmas["asked"].is_empty() and were and not g.folk.knows("chiki"),
		"Alberto, La Chiki and the demonstrators have signed already and say so (%s / %s); they do not count, and the two of them are not in the Agenda yet (Alberto's line his: %s; asked: %d; in the Agenda before: %s, after: %s)"
		% [said[1], said[3], str(said[0] == Loc.t("firma_alberto")[0]), g.firmas["asked"].size(), str(not were), str(g.folk.knows("chiki") or g.folk.knows("alberto"))])
	# everybody with a name has something of their own to say, yes or no
	var mute: Array = []
	for id in g.named:
		if id in ["alberto", "chiki"]:
			continue
		for way in ["firma_si_", "firma_no_"]:
			if Loc.t(way + id) is String and Loc.t(way + id) == way + id:
				mute.append(way + id)
	_check(mute.is_empty() and Loc.t("firma_no").size() >= 8, "all %d neighbours with a name have their own way of signing and of not signing (missing: %s); there are %d silly excuses for the rest" % [g.named.size() - 2, str(mute), Loc.t("firma_no").size()])
	# ask around: somebody you know first, twice; then whoever is about
	var pool: Array = [g.named["paca"], g.named["goat"], g.named["kevin"]]
	for n in g.npcs:
		if n.id == "" and not n.has_meta("protest") and pool.size() < 14:
			pool.append(n)
	var asked := 0
	var noes := 0
	var heard: Array = []
	var twice_ok := true
	for n in pool:
		if not _at("firmas"):
			break
		var before: int = g.firmas["got"]
		g.talk_to(n)
		heard.append(g.dlg["lines"][0] if g.dlg != null else "")
		await _skip_dialog()
		asked += 1
		var got_now: int = g.firmas["got"] if g.firmas != null else 5
		if got_now == before:
			noes += 1
		if asked == 1 and g.firmas != null:              # the same person again: no second answer
			var size_was: int = g.firmas["asked"].size()
			g.talk_to(n)
			var again: String = g.dlg["lines"][0] if g.dlg != null else ""
			await _skip_dialog()
			twice_ok = g.firmas["asked"].size() == size_was and g.firmas["got"] == got_now and (again in Loc.t("firma_again_si") or again in Loc.t("firma_again_no"))
	var own: bool = heard.size() >= 3 and (heard[0] == Loc.t("firma_si_paca") or heard[0] == Loc.t("firma_no_paca")) and heard[1] == "Beeeh."
	_check(asked == 8 and noes == 3 and twice_ok and own and _at("alberto_back") and g.firmas == null and g.target_npc == g.named["alberto"],
		"it takes asking eight people to get the five: three say no for the silliest of reasons, nobody answers twice, and Tía Paca and the goat answer as themselves (%d asked, %d noes; a no: %s)" % [asked, noes, heard[heard.size() - 2] if heard.size() > 1 else ""])
	# hand them over
	var purse: int = g.money
	var trust_was: int = g.folk.trust("alberto")
	g.talk_to(g.named["alberto"])
	var handed: bool = g.dlg != null and g.dlg["lines"].size() == Loc.t("alberto_firmas").size()
	var owed: int = int(g.stats.get("pc_owed", 0))
	await _skip_dialog()
	_check(handed and g.dlg != null and g.dlg["lines"][0] == Loc.t("alberto_pc")[0] and g.money == purse + 10 and g.folk.knows("chiki"),
		"hand them to Alberto: ten euros from the tin, La Chiki is in the Agenda -- and he has something to explain")
	_check(g.pc_on() and g.pc == 10 + owed, "Puntos Cívicos: one for each signature and five of his own (%d)" % g.pc)
	await _skip_dialog()
	_check(g.folk.knows("alberto") and g.folk.trust("alberto") >= trust_was + 10, "(and Alberto trusts you the more for it)")
	await _puente_checks()
	# and when you are well away, the demonstration goes home
	var stood: bool = g.protesters.size() == 13
	var was_at: Vector2 = g.player.p
	g.player.p = b.p + Vector2(420.0, 300.0)
	await _frames(50)
	_check(stood and g.protesters.is_empty() and b.dressing == null and is_instance_valid(g.named["alberto"]) and is_instance_valid(chiki) and g.npcs.has(chiki) and g.npcs.has(g.named["alberto"]),
		"once you are well away the demonstration packs up; the bridge, Alberto and La Chiki stay (there before: %s; left now: %d; over: %s; you are %.0f m away; in sight: %s)" % [str(stood), g.protesters.size(), str(g._protest_over), g.player.p.distance_to(b.p), str(g.sees(b.p, 400.0))])
	var had_tags: bool = g.stats.has("chiki_tags")
	g.stats["chiki_tags"] = g.day_n                  # (the first talk after the protest is the peñas' walls: pintadas.gd, its own test)
	g.talk_to(chiki)
	await _frames(3)
	if g.menu.visible:
		g._choose(1)                                 # (a chat, not a wall)
		await _frames(3)
	var after: bool = g.dlg != null and g.dlg["lines"][0] == Loc.t("chiki_after")[0][0]
	await _skip_dialog()
	if not had_tags:
		g.stats.erase("chiki_tags")
	_check(after, "and La Chiki has new things not to care about (%s)" % Loc.t("chiki_after")[0][0])
	g.player.p = was_at

## The parish church, built by hand: it stands where the real one does, you cannot walk through it, its tower is the
## tallest thing in town and its clocks tell the town's time.
## The houses drawn after the real ones (fachadas.gd), which began with Calle de Alemania.
func _looks_checks() -> void:
	var F = load("res://scripts/fachadas.gd")
	var painter = F.new()
	var missing: Array = []
	var plain: Array = []
	for look in MapData.looks:
		if not F.LOOKS.has(look) or not painter.has_method("_" + look):
			missing.append(look)
			continue
		var img: Image = painter.paint(look, null)[0]
		var seen := {}
		for y in range(8, 512, 24):
			for x in range(8, 512, 24):
				seen[img.get_pixel(x, y).to_html(false)] = true
		if img.get_size() != Vector2i(512, 512) or seen.size() < 4:
			plain.append(look)
	_check(missing.is_empty() and plain.is_empty() and MapData.walls.size() == 7 + MapData.looks.size(),
		"%d houses' looks are baked into the map and every one has a front painted for it (missing %s, blank %s)" % [MapData.looks.size(), str(missing), str(plain)])
	# walk Calle de Alemania from the Avenida to no. 7, as the video does: the house beside you on either hand is one of them
	var line: Array[Vector2] = [Vector2(78.3, -303.1), Vector2(72.5, -296.0), Vector2(54.1, -235.6), Vector2(20.3, -159.6)]
	var asked := 0
	var dressed := 0
	var bare: Array = []
	for side_sign in [1.0, -1.0]:
		for s in range(4 if side_sign > 0.0 else 16, 96, 5):
			if s > 64 and s < 78:
				continue                              # (the mouth of the Travesía)
			var left := float(s)
			var at := line[0]
			var dir := Vector2.ZERO
			for k in range(line.size() - 1):
				var seg: float = line[k].distance_to(line[k + 1])
				dir = (line[k + 1] - line[k]).normalized()
				if left <= seg or k == line.size() - 2:
					at = line[k] + dir * left
					break
				left -= seg
			var probe: Vector2 = at + Vector2(-dir.y, dir.x) * side_sign * 6.5
			var best := 1e9
			var best_style := -1
			for style in range(MapData.walls.size()):
				var w: Array = MapData.walls[style]
				for o in range(0, w.size(), 7):
					var d: float = Geometry2D.get_closest_point_to_segment(probe, Vector2(w[o], w[o + 1]), Vector2(w[o + 2], w[o + 3])).distance_to(probe)
					if d < best:
						best = d
						best_style = style
			asked += 1
			var by_hand := false                          # (or it is one of the houses built by hand)
			for hd in MapData.houses:
				var rel: Vector2 = probe - Vector2(hd["o"][0], hd["o"][1])
				var hu := Vector2(hd["u"][0], hd["u"][1])
				if rel.dot(hu) > -0.5 and rel.dot(hu) < float(hd["len"]) + 0.5 and absf(rel.dot(Vector2(-hu.y, hu.x))) < 4.0:
					by_hand = true
			if best_style >= 7 or by_hand:
				dressed += 1
			else:
				bare.append("%s %d m" % ["odd" if side_sign > 0.0 else "even", s])
	_check(dressed >= asked - 2, "Calle de Alemania, from the Avenida to no. 7: the house on either hand wears its own front (%d of %d places; not at %s)" % [dressed, asked, str(bare)])

## What the testers asked for (12 November): the creator's words and choices, the jump, the arrow at the wheel,
## somebody driving every car that moves, and home in Calle de Alemania.
func _tester_checks() -> void:
	# nobody drives down the Calle de Alemania until the first talk with Tía Paca is over
	var ale = null
	var other = null
	for sg in MapData.segs:
		if String(sg.road["n"]) == "Calle de Alemania" and MapData.drivable(sg):
			ale = sg
		elif other == null and String(sg.road["n"]) == "Calle Real" and MapData.drivable(sg):
			other = sg
	var si_was: int = g.si
	g.si = 0
	var hushed: bool = ale != null and g.traffic.quiet(ale) and not g.traffic.quiet(other) and String(g.steps[0]["id"]) == "paca"
	var all_of_it := true                   # every stretch of the street, not just one
	for sg in MapData.segs:
		if String(sg.road["n"]) == "Calle de Alemania" and not g.traffic.quiet(sg):
			all_of_it = false
	g.si = 1
	var open_after: bool = ale != null and not g.traffic.quiet(ale)
	g.si = si_was
	_check(hushed and all_of_it and open_after, "no traffic in the Calle de Alemania until the first talk with Tía Paca is over (kept clear %s, the whole street %s, open afterwards %s)" % [hushed, all_of_it, open_after])
	var Cr = load("res://scripts/creator.gd")
	var base: Dictionary = Cr.look(Cr.defaults())
	var hair_names: Array = Loc.t("c_values")[4]
	var was_lang: String = Loc.lang
	Loc.lang = "es"
	hair_names = Loc.t("c_values")[4]
	var names_ok: bool = hair_names.has("Jaro") and hair_names.has("Oxidao") and not hair_names.has("Rubio") and Loc.t("c_tabs") == ["LUSTRE", "PINTAS"] and String(Loc.t("maruja_m2")[0]).begins_with("¡Macho")
	Loc.lang = was_lang
	var lash_at: Array = Cr.where(19)
	_check(names_ok and String(base["hat"]) == "" and int(base["lashes"]) == 0 and lash_at[0] == 0 and Cr.OPTIONS[13]["values"].has(6) and Cr.OPTIONS[1]["values"].has(-1)
		and Loc.t("c_names").size() == Cr.OPTIONS.size() and Loc.t("c_values").size() == Cr.OPTIONS.size() and Loc.t("c_values")[19].size() == 3 and Loc.t("c_values")[13].size() == 7 and Loc.t("c_values")[1].size() == 6,
		"the creator says Jaro and Oxidao, starts you bare-headed and without eyelashes, and offers eyelashes, silver hoops and the red-and-gold band (names %s)" % names_ok)
	var probe = load("res://scripts/chara.gd").new()
	add_child(probe)
	probe.setup(Cr.look(Cr.defaults()))
	var plain: int = probe.inner.get_child_count() + probe.neck.get_child_count()
	var sel: Array = Cr.defaults()
	sel[8] = 5
	probe.set_look(Cr.look(sel))
	var dots: int = probe.inner.get_child_count() + probe.neck.get_child_count() - plain
	sel[8] = 0; sel[19] = 2; sel[0] = 2; sel[1] = 5; sel[13] = 6
	probe.set_look(Cr.look(sel))
	var extras: int = probe.inner.get_child_count() + probe.neck.get_child_count() - plain
	probe.queue_free()
	_check(dots >= 25 and extras >= 14, "three days' beard is a scatter of dots (%d of them), and lashes, hat band and hoops are all there on the face (%d pieces more)" % [dots, extras])
	g.look_sel = Cr.clean(g.look_sel)
	g.creator_tab = 0
	g.creator_row = 3
	g._refresh_creator()
	var two_tabs: bool = g.hud.creator_tab_boxes.size() == 2 and g.hud.creator_tab_boxes[0][1].text == "LUSTRE" and g.hud.creator_tab_boxes[1][1].text == "PINTAS" and not g.hud.creator_text.text.contains("LUSTRE")
	g._creator_input("tab")
	_check(two_tabs and g.creator_tab == 1 and g.hud.creator_text.text.contains(Loc.t("c_names")[0]), "Lustre and Pintas are two tabs in plain sight, and Tab turns from one to the other")
	g.creator_tab = 0
	g.hud.hide_creator()
	# the jump
	var y0: float = g.player.inner.position.y
	var went: bool = g.player.hop()
	var peak := y0
	for k in range(int(ceil(g.player.HOP * 30.0)) + 1):
		g.player.anim(false, 1.0 / 30.0, 0.0)
		peak = maxf(peak, g.player.inner.position.y)
	_check(went and peak > y0 + 0.5 and absf(g.player.inner.position.y - y0) < 0.1, "the jump key lifts you off the ground and puts you down again (%.2f m up)" % (peak - y0))
	# every car that moves has somebody at the wheel; the parked ones, nobody
	var moving: int = g.traffic.list.size()
	var driven: int = g.traffic.list.filter(func(e): return not e["car"].riders[0].is_empty() and e["car"]._rider_nodes[0] != null).size()
	var ghosts: int = g.cars.filter(func(c): return c != g.in_car and not g.traffic.list.any(func(e): return e["car"] == c) and not c.riders[0].is_empty()).size()
	_check(moving > 0 and driven == moving and ghosts == 0, "every neighbour's car on the move has its driver at the wheel (%d of %d), and no parked car has one left in it (%d)" % [driven, moving, ghosts])
	# the steel bridge of the Arroyuelo Medio: up when it is dry, down across the street when it rains
	var ps = g.pasarela
	g.set_rain(false, 1e9)                        # (whatever the weather was doing: dry, and no more showers of its own while the test runs)
	for k in range(260):
		g._weather_tick(1.0 / 30.0)
	var dry: bool = ps != null and ps.down == 0.0 and not MapData.decks.any(func(d): return d["o"] == ps.p) and MapData.road_edge_dist(ps.p) < 1.0
	g.set_rain(true)
	for k in range(260):
		g._weather_tick(1.0 / 30.0)
	var wet: bool = ps != null and ps.down == 1.0 and g.rain == 1.0 and MapData.decks.any(func(d): return d["o"] == ps.p) and MapData.foot(ps.p) > MapData.height(ps.p) + 0.5
	g.set_rain(false, 1e9)
	for k in range(260):
		g._weather_tick(1.0 / 30.0)
	_check(dry and wet and ps.down == 0.0 and g.rain == 0.0 and not MapData.decks.any(func(d): return d["o"] == ps.p),
		"the steel bridge stands folded while it is dry, comes down across the street when it rains (and can be walked over), and goes back up after (dry %s, wet %s)" % [dry, wet])
	# home
	var home: Vector2 = g.places["home"]["p"]
	var casa5 = g.world.casas.filter(func(c): return c.id == "alemania_5")
	var jo = g.named["josefa"]
	_check(casa5.size() == 1 and home.distance_to(g.HOME_DOOR) < 9.0 and jo.p.distance_to(g.JOSEFA_DOOR) < 9.0 and jo.p.distance_to(home) < 16.0
		and MapData.nearest_road(home)["seg"].road["n"] == "Calle de Alemania",
		"the house you inherit is Calle de Alemania 5, and Josefa lives across the street at no. 12 (%.0f m from your door)" % jo.p.distance_to(home))

## The houses built by hand (casas.gd). The first: Calle de Alemania, 7.
func _casas_checks() -> void:
	var space := get_tree().root.get_world_3d().direct_space_state
	var thin: Array = []
	for casa in g.world.casas:
		if casa.boxes < 12:
			thin.append(casa.id)
	_check(MapData.houses.size() >= 23 and g.world.casas.size() == MapData.houses.size() and thin.is_empty(),
		"%d houses built by hand, each on the frame the map gives it, each with its walls and openings (too little of %s)" % [g.world.casas.size(), str(thin)])
	for casa in g.world.casas:
		if casa.id != "alemania_7":
			continue
		# no ordinary front has been left standing where it is
		var mid: Vector2 = casa.spot(casa.length / 2.0, 0.0)
		var nearest := 1e9
		for style in range(MapData.walls.size()):
			var w: Array = MapData.walls[style]
			for o2 in range(0, w.size(), 7):
				var a := Vector2(w[o2], w[o2 + 1])
				var b := Vector2(w[o2 + 2], w[o2 + 3])
				if a.distance_to(b) > 3.0 and absf((b - a).normalized().dot(casa.u)) > 0.95:
					nearest = minf(nearest, Geometry2D.get_closest_point_to_segment(mid, a, b).distance_to(mid))
		_check(casa.boxes > 300 and nearest > 2.0 and absf(casa.length - 10.75) < 0.1,
			"Calle de Alemania 7 is built piece by piece (%d of them) on its real front of %.2f m, and no painted front is left where it stands (the nearest is %.1f m away)" % [casa.boxes, casa.length, nearest])
		# from the street: the wall stops you at the window; at the porch you can step in under the house
		var reach: Array = []
		for x in [5.5, 9.0]:
			var from: Vector3 = MapData.at(casa.spot(x, 3.0), 1.0)
			var to: Vector3 = MapData.at(casa.spot(x, -4.0), 1.0)
			to.y = from.y
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1))
			reach.append(3.0 - from.distance_to(hit["position"]) if not hit.is_empty() else -4.0)       # how far out from the front line you are stopped
		_check(absf(reach[0]) < 0.35 and reach[1] < -0.9 and reach[1] > -1.8,
			"its wall is solid at the window (you stop %.2f m from the front) and its porch lets you in under the house (%.2f m in)" % [reach[0], -reach[1]])
		_check(MapData.road_edge_dist(casa.spot(casa.length / 2.0, 1.0)) > 0.3,
			"and the upper floor, its balconies and its eaves fly over the pavement, not over the road (%.1f m of pavement left beyond them)" % MapData.road_edge_dist(casa.spot(casa.length / 2.0, 1.0)))

## The Petril (petril.gd): the old convent, its church and their raised square. `walk`: also go up its steps and its
## ramp on foot (left out of the full run, which has enough walking of its own).
func _petril_checks(walk := false) -> void:
	var pt = g.world.petril
	_check(pt != null and not MapData.petril.is_empty() and pt.pieces > 900, "the Petril is built by hand: the church, the convent and their square (%d pieces)" % (pt.pieces if pt != null else 0))
	if pt == null or MapData.petril.is_empty():
		return
	var space := get_tree().root.get_world_3d().direct_space_state
	var lv: float = pt.level
	# the square is a floor of its own, over the two streets; the steps and the ramp bring you up to it
	var mid_steps: float = (pt.STEPS.x + pt.STEPS.y) / 2.0
	var on_floor: float = MapData.foot(pt.spot(9.0, 9.0))
	var street: float = MapData.foot(pt.spot(-1.5, mid_steps))
	var half_way: float = MapData.foot(pt.spot(pt.P_NW.x + 0.15 + pt.STEPS_IN / 2.0, mid_steps))
	var on_ramp: float = MapData.foot(pt.spot(17.1, (pt.RAMP_TOP + pt.RAMP_FOOT) / 2.0))
	var ramp_foot: float = MapData.foot(pt.spot(16.0, pt.RAMP_FOOT + 0.6))
	_check(absf(on_floor - lv) < 0.01 and lv - street > 0.6 and lv - street < 1.1 and half_way > street + 0.2 and half_way < lv - 0.2,
		"its square stands %.2f m over the Calle de San Francisco, and its steps take you up by halves (%.2f half way)" % [lv - street, half_way - street])
	_check(on_ramp < lv - 0.3 and on_ramp > ramp_foot + 0.3 and absf(MapData.foot(pt.spot(17.1, pt.RAMP_TOP - 0.5)) - lv) < 0.01,
		"the ramp from the Calle de las Cruces climbs %.2f m along the convent to the same floor" % (lv - ramp_foot))
	var floor_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(MapData.at(pt.spot(9.0, 9.0), 6.0), MapData.at(pt.spot(9.0, 9.0), -3.0), 1))
	var ramp_at: Vector2 = pt.spot(17.1, (pt.RAMP_TOP + pt.RAMP_FOOT) / 2.0)
	var ramp_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(MapData.at(ramp_at, 6.0), MapData.at(ramp_at, -3.0), 1))
	_check(not floor_hit.is_empty() and absf(floor_hit["position"].y - lv) < 0.03 and not ramp_hit.is_empty() and absf(ramp_hit["position"].y - on_ramp) < 0.06,
		"and both are solid under wheels as well as feet")
	# nobody walks through its walls, its pretil or its doors
	var blocked := 0
	var ways: Array = [[Vector2(-2.5, 4.0), Vector2(3.0, 4.0)], [Vector2(6.0, 22.5), Vector2(6.0, 16.0)], [Vector2(4.4, 3.0), Vector2(4.4, -4.0)], [Vector2(14.0, 8.7), Vector2(22.0, 8.7)],
		[Vector2(13.6, 3.0), Vector2(13.6, -4.0)], [Vector2(-3.0, -8.0), Vector2(4.0, -8.0)], [Vector2(22.0, 27.5), Vector2(22.0, 20.0)]]
	for way in ways:
		var a: Vector2 = pt.spot(way[0].x, way[0].y)
		var b: Vector2 = pt.spot(way[1].x, way[1].y)
		var h: float = maxf(MapData.foot(a), MapData.foot(b)) + 0.6
		if not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(a.x, h, a.y), Vector3(b.x, h, b.y), 1)).is_empty():
			blocked += 1
	_check(blocked == ways.size(), "the pretil, the church, the convent and their doors are solid (%d of %d ways in blocked)" % [blocked, ways.size()])
	# ...and the two streets beside it are as open as they were
	var open := 0
	for lane in [[Vector2(-4.0, -27.0), Vector2(-4.4, 21.0)], [Vector2(-3.0, 23.4), Vector2(29.0, 29.0)]]:
		var a2: Vector3 = MapData.at(pt.spot(lane[0].x, lane[0].y), 1.0)
		var b2: Vector3 = MapData.at(pt.spot(lane[1].x, lane[1].y), 1.0)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(a2, b2, 1))
		if hit.is_empty() or (hit["position"] as Vector3).y < minf(a2.y, b2.y) - 0.6:        # (the street itself, where it rises, is no obstacle)
			open += 1
	var nearest := 99.0
	for q in pt.yard:
		nearest = minf(nearest, MapData.road_edge_dist(q))
	_check(open == 2 and pt.yard.size() >= 20 and nearest >= 0.2, "nothing of it stands in the Calle de San Francisco or the Calle de las Cruces: of %d walls, pillars, trees and benches the nearest to the asphalt is %.1f m off" % [pt.yard.size(), nearest])
	if not walk:
		return
	var was: Vector2 = g.player.p
	g.player.p = pt.spot(-1.2, mid_steps)
	await _frames(3)
	var left: float = await _walk_at(pt.spot(6.0, mid_steps), 5.0)
	_check(left < 0.6 and absf(g.player.global_position.y - lv) < 0.05, "on foot you go up the steps into the square (%.1f m short, %.2f m off its floor)" % [left, g.player.global_position.y - lv])
	g.player.p = pt.spot(17.0, pt.RAMP_FOOT + 1.2)
	await _frames(3)
	left = await _walk_at(pt.spot(17.2, pt.RAMP_TOP - 1.5), 6.0)
	_check(left < 0.6 and absf(g.player.global_position.y - lv) < 0.05, "...and up the ramp (%.1f m short, %.2f m off its floor)" % [left, g.player.global_position.y - lv])
	left = await _walk_at(pt.spot(pt.CHURCH_W / 2.0, 1.2), 6.0)
	_check(left < 0.6, "...and across it under the porch to the door of the church (%.1f m short)" % left)
	g.player.p = was

## The nursery school of the Calle del Palo (calasanz.gd): the house, its yard a step above the street behind its
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
	var nearest := Vector2.ZERO
	for q in b.yard:
		for s in MapData.segs:
			if MapData.drivable(s) and MapData.seg_point(s, q).distance_to(q) < near_road:
				near_road = MapData.seg_point(s, q).distance_to(q)
				nearest = Vector2((q - b.p).dot(b.across), (q - b.p).dot(b.u))
	_check(there and gone and near_road > 1.6, "with the works: the excavator below the bridge, the site fence and the truck up the bed are there and solid; without: nothing of them is left; nothing of it all stands in the way of the traffic (%.1f m from the middle of the nearest street at the least, at %.1f, %.1f of its frame)" % [near_road, nearest.x, nearest.y])
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
## (left out of the full run).
func _molino_checks(walk := false) -> void:
	var ml = g.world.molino
	_check(ml != null and ml.pieces > 500 and g.world.mill_blades == ml.sails and ml.sails.get_child_count() >= 1,
		"the windmill and its yard are built by hand: the tower, its cap and sails, the wall, the corral (%d pieces)" % (ml.pieces if ml != null else 0))
	if ml == null:
		return
	var space := get_tree().root.get_world_3d().direct_space_state
	var lv: float = ml.level
	var was_turn: float = ml.sails.rotation.z
	await _frames(20)
	_check(absf(angle_difference(ml.sails.rotation.z, was_turn)) > 0.02, "its sails turn")
	# what must stop you: the wall from the street, the tower, the corral from the street and from the yard, a shed, the wall on the fields, the old gateway (shut)
	var blocked := 0
	var ways: Array = [[Vector2(-15.0, 1.0), Vector2(-9.0, 1.0)], [Vector2(-7.0, 0.6), Vector2(0.0, 0.0)], [Vector2(-15.0, 23.0), Vector2(-7.0, 23.0)], [Vector2(1.5, 12.5), Vector2(1.5, 20.0)],
		[Vector2(-8.0, -11.5), Vector2(-8.0, -17.0)], [Vector2(9.0, 1.0), Vector2(17.0, 1.0)], [Vector2(-16.0, -24.0), Vector2(-9.0, -24.0)]]
	for way in ways:
		var a: Vector2 = ml.spot(way[0].x, way[0].y)
		var b: Vector2 = ml.spot(way[1].x, way[1].y)
		if not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(a.x, lv + 0.4, a.y), Vector3(b.x, lv + 0.4, b.y), 1)).is_empty():
			blocked += 1
		else:
			print("  molino: nothing in the way from %s to %s" % [str(way[0]), str(way[1])])
	# ...and what must not: the red door (it stands open), the path from it, the threshing floor
	var open := 0
	var lanes: Array = [[Vector2(-15.0, ml.RED_DOOR), Vector2(-10.2, ml.RED_DOOR)], [Vector2(-4.0, -11.9), Vector2(-2.0, -4.7)], [Vector2(-8.5, 6.0), Vector2(9.0, 6.0)]]
	for lane in lanes:
		var a2: Vector2 = ml.spot(lane[0].x, lane[0].y)
		var b2: Vector2 = ml.spot(lane[1].x, lane[1].y)
		if space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(a2.x, lv + 0.9, a2.y), Vector3(b2.x, lv + 0.9, b2.y), 1)).is_empty():
			open += 1
		else:
			print("  molino: something in the way from %s to %s" % [str(lane[0]), str(lane[1])])
	_check(blocked == ways.size() and open == lanes.size(), "its walls, its tower and its corral are solid (%d of %d ways blocked); the red door, the path and the threshing floor are open (%d of %d)" % [blocked, ways.size(), open, lanes.size()])
	var nearest := 99.0
	for q in ml.yard:
		nearest = minf(nearest, MapData.road_edge_dist(q))
	var flat_yard: float = 0.0
	for q in [Vector2(0.0, 5.0), Vector2(-9.0, -8.0), Vector2(8.0, -6.0), Vector2(0.0, 14.0), Vector2(-13.5, 0.0)]:
		flat_yard = maxf(flat_yard, absf(MapData.height(ml.spot(q.x, q.y)) - lv))
	_check(ml.yard.size() >= 30 and nearest >= 0.0 and flat_yard < 0.12, "nothing of it stands in the street (of %d walls, posts and trees the nearest to the asphalt is %.1f m off) and its yard is level (%.2f m at worst)" % [ml.yard.size(), nearest, flat_yard])
	var miller = g.named.get("genaro")
	_check(miller != null and miller.still and miller.p.distance_to(ml.door) < 4.0 and absf(MapData.height(miller.p) - lv) < 0.12,
		"Tío Gerardo stands in the yard a few steps from the mill's door (%.1f m from it)" % (miller.p.distance_to(ml.door) if miller != null else -1.0))
	if not walk:
		return
	var was: Vector2 = g.player.p
	g.player.p = ml.spot(-15.0, ml.RED_DOOR)
	await _frames(3)
	var left: float = await _walk_at(ml.spot(-9.9, ml.RED_DOOR - 0.3), 6.0)
	_check(left < 0.6 and absf(g.player.global_position.y - lv) < 0.1, "on foot you go in from the street by the red door (%.1f m short)" % left)
	left = await _walk_at(ml.door, 8.0)
	_check(left < 0.8, "...and across the threshing floor to the door of the mill (%.1f m short)" % left)
	g.player.p = was

## The Plaza del Ayuntamiento and the town hall (plaza.gd). `walk`: also go on foot under the arches to the main door,
## up the wide steps from the Arroyuelo's pavement, and up on to the bandstand (left out of the full run).
func _plaza_checks(walk := false) -> void:
	var pz = g.world.plaza
	_check(pz != null and not MapData.townhall.is_empty() and pz.pieces > 2500 and g.world._hands.size() >= 1,
		"the town hall and its square are built by hand: twenty arches, the garden, the fountain (%d pieces), and the town clock is on its gable" % (pz.pieces if pz != null else 0))
	if pz == null or MapData.townhall.is_empty():
		return
	var space := get_tree().root.get_world_3d().direct_space_state
	var lv: float = pz.level
	# one level floor from the back wall of the covered walk to the Calle de Zaragoza and the Calle de la Plaza, over the Arroyuelo
	var on_floor: Array = []
	for q in [Vector2(0.0, 10.0), Vector2(-20.0, -1.6), Vector2(28.0, 40.0), Vector2(-26.0, 60.0), Vector2(-9.0, 40.0), Vector2(25.0, 64.0)]:
		on_floor.append(absf(MapData.foot(pz.spot(q.x, q.y)) - lv))
	var street: float = MapData.height(pz.spot(-39.6, 40.0))
	var pavement: float = MapData.foot(pz.spot(-33.2, 20.0))
	var east: float = MapData.height(pz.spot(33.0, 30.0))
	_check(on_floor.max() < 0.02 and absf(east - lv) < 0.08 and lv - street > 1.2 and pavement < lv - 0.5 and pavement > street + 0.5,
		"the square is one level floor, flush with the Calle de Zaragoza (%.2f m off it) and %.2f m over the Arroyuelo, with the raised pavement between (%.2f under it)" % [east - lv, lv - street, lv - pavement])
	var stage: float = MapData.foot(pz.spot(pz.STAND.x, pz.STAND.y))
	var floor_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(MapData.at(pz.spot(-20.0, 20.0), 6.0), MapData.at(pz.spot(-20.0, 20.0), -4.0), 1))
	_check(absf(stage - lv - 1.0) < 0.02 and not floor_hit.is_empty() and absf((floor_hit["position"] as Vector3).y - lv) < 0.05,
		"the bandstand's floor is a metre up, and where the ground under the square went down with the street its floor is solid all the same")
	# what must stop you: the town hall behind its walk, a pier, the fountain's wall, the bar, the bandstand, a planter, the fence of the playground
	var blocked := 0
	var ways: Array = [[Vector2(-1.5, -1.6), Vector2(-1.5, -6.0)], [Vector2(0.0, 3.0), Vector2(0.0, -2.0)], [pz.FOUNTAIN + Vector2(8.0, 0.0), pz.FOUNTAIN], [Vector2(-16.0, 54.5), Vector2(-26.0, 54.5)],
		[pz.STAND + Vector2(9.0, -9.0), pz.STAND], [Vector2(2.0, 18.0), Vector2(2.0, 26.0)], [pz.PLAY + Vector2(-2.0, -12.0), pz.PLAY + Vector2(-2.0, -4.0)], [Vector2(-36.0, 20.0), Vector2(-26.0, 20.0)]]
	for way in ways:
		var a: Vector2 = pz.spot(way[0].x, way[0].y)
		var b: Vector2 = pz.spot(way[1].x, way[1].y)
		var h: float = minf(MapData.foot(a), MapData.foot(b)) + 0.3          # (at the height of the shins of whoever comes from the lower end)
		if not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(a.x, h, a.y), Vector3(b.x, h, b.y), 1)).is_empty():
			blocked += 1
		else:
			print("  plaza: nothing in the way from %s to %s at %.2f" % [str(way[0]), str(way[1]), h - lv])
	# ...and what must not: the arches of the walk, the open floor, the ways through the garden
	var open := 0
	var lanes: Array = [[Vector2(-1.5, 6.0), Vector2(-1.5, -2.6)], [Vector2(-28.0, -1.6), Vector2(28.0, -1.6)], [Vector2(-25.0, 18.6), Vector2(27.0, 18.6)], [Vector2(-6.0, 20.0), Vector2(-6.0, 44.0)],
		[Vector2(9.5, 20.0), Vector2(9.5, 34.0)], [Vector2(-9.0, 46.0), Vector2(-9.0, 66.0)]]
	for lane in lanes:
		var a2: Vector2 = pz.spot(lane[0].x, lane[0].y)
		var b2: Vector2 = pz.spot(lane[1].x, lane[1].y)
		if space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(a2.x, lv + 0.9, a2.y), Vector3(b2.x, lv + 0.9, b2.y), 1)).is_empty():
			open += 1
	_check(blocked == ways.size() and open == lanes.size(), "its walls, piers, planters and fences are solid (%d of %d ways blocked) and its arches and paths are open (%d of %d)" % [blocked, ways.size(), open, lanes.size()])
	var nearest := 99.0
	for q in pz.yard:
		nearest = minf(nearest, MapData.road_edge_dist(q))
	_check(pz.yard.size() >= 100 and nearest >= 0.2, "nothing of it stands in a street: of %d piers, walls, trees, lamps and benches the nearest to the asphalt is %.1f m off" % [pz.yard.size(), nearest])
	if not walk:
		return
	var was: Vector2 = g.player.p
	g.player.p = pz.spot(1.5, 12.0)
	await _frames(3)
	var left: float = await _walk_at(pz.spot(1.5, -2.2), 8.0)
	_check(left < 0.6 and absf(g.player.global_position.y - lv) < 0.05, "on foot you go under an arch to the main door (%.1f m short)" % left)
	g.player.p = pz.spot(-34.2, 38.5)
	await _frames(3)
	left = await _walk_at(pz.spot(-27.0, 38.5), 8.0)
	_check(left < 0.6 and absf(g.player.global_position.y - lv) < 0.05, "...up the wide steps from the raised pavement into the square (%.1f m short, %.2f m off its floor)" % [left, g.player.global_position.y - lv])
	g.player.p = pz.spot(-33.6, -1.8)
	await _frames(3)
	left = await _walk_at(pz.spot(-28.5, -1.8), 8.0)
	_check(left < 0.6 and absf(g.player.global_position.y - lv) < 0.05, "...up the narrow ones at the end of the town hall into its covered walk (%.1f m short, %.2f m off its floor)" % [left, g.player.global_position.y - lv])
	g.player.p = was

func _church_checks() -> void:
	var ch = g.world.church
	var space := get_tree().root.get_world_3d().direct_space_state
	_check(ch != null and not MapData.church.is_empty() and MapData.towers.is_empty(), "the parish church is built by hand (the generic bell tower is gone)")
	var blocked := 0
	for probe in [[Vector2(-8.0, -11.0), Vector2(6.0, -11.0)], [Vector2(21.5, 6.0), Vector2(21.5, -6.0)], [Vector2(30.5, -ch.D - 6.0), Vector2(30.5, -ch.D + 6.0)], [Vector2(ch.L + 6.0, -14.0), Vector2(ch.L - 6.0, -14.0)], [Vector2(-8.0, -25.5), Vector2(2.0, -25.5)]]:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(MapData.at(ch.spot(probe[0].x, probe[0].y), 1.0), MapData.at(ch.spot(probe[1].x, probe[1].y), 1.0), 1))
		if not hit.is_empty():
			blocked += 1
	_check(blocked == 5, "its walls are solid on all four sides and at the tower, doors included (%d of 5 ways in blocked)" % blocked)
	var tallest := 0.0
	for style in range(MapData.walls.size()):
		var w: Array = MapData.walls[style]
		for i in range(0, w.size(), 7):
			tallest = maxf(tallest, float(w[i + 4]))
	_check(ch.top > 35.0 and ch.top > tallest + 10.0, "the cross on the spire is %.0f m up: nothing else in town comes near (the tallest house front is %.0f m)" % [ch.top, tallest])
	g.set_time(15.0)
	await _frames(4)
	var hands: Array = g.world._hands[-1]
	_check(absf(angle_difference(hands[0].rotation.z, -3.0 / 12.0 * TAU)) < 0.02 and absf(angle_difference(hands[1].rotation.z, 0.0)) < 0.02, "at three in the afternoon the tower clock says three")
	var nearest := 99.0
	for q in ch.yard:
		nearest = minf(nearest, MapData.road_edge_dist(q))
	_check(ch.yard.size() >= 10 and nearest >= 0.5 and ch.bays >= 4, "nothing of the church's stands in a street: of its %d railings, trees, planters and tables the nearest to the asphalt is %.1f m off, and the %d parking bays stop where the street closes in" % [ch.yard.size(), nearest, ch.bays])
	var through := 0                              # ...and the streets round it are still streets: drive-wide, kerb to kerb
	for way in [[Vector2(-10.0, 16.0), Vector2(ch.L + 6.0, 5.0)], [Vector2(-12.0, -ch.D - 30.0), Vector2(ch.L + 8.0, -ch.D - 5.0)]]:
		var from: Vector2 = MapData.nearest_road(ch.spot(way[0].x, way[0].y))["p"]
		var to: Vector2 = MapData.nearest_road(ch.spot(way[1].x, way[1].y))["p"]
		var clear := true
		var last: Vector2 = from
		for q in MapData.path(from, to):
			for k in range(1, 5):
				var m: Vector2 = last.lerp(q, k / 4.0)
				for side in [-1.4, 1.4]:
					var off: Vector2 = (q - last).normalized().orthogonal() * side
					var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(MapData.at(m + off, 2.5), MapData.at(m + off, 0.3), 1))
					if not hit.is_empty() and hit["position"].y > MapData.height(m + off) + 0.25:
						clear = false
			last = q
		if clear:
			through += 1
	_check(through == 2, "the streets along its south and north sides are clear from end to end (%d of 2)" % through)
	_check(g.world.extra_terrazas.size() >= 2, "the bar by its north door has its tables out")

## The Edison drives itself: to wherever the errand is, round the corners, and lets go the moment you touch anything.
func _autopilot_checks() -> void:
	var was_phase: String = g.phase
	var was_target = g.target
	g.phase = "free"
	g.police.reset()
	g.traffic.clear()
	g.traffic._spawn_t = 99999.0
	if g.in_car != null:
		g.in_car.set_speed(Vector2.ZERO)
		g._exit_car()
		await _frames(3)
	var run = _clear_street()
	var ru: Vector2 = (run.b - run.a).normalized()
	var car = CarS.new()
	g.add_child(car)
	car.setup("edison", 0, run.a + ru * 8.0 + Vector2(-ru.y, ru.x) * 1.0, atan2(ru.x, ru.y))
	await _frames(10)
	g._enter_car(car)
	await _frames(5)
	# somewhere to go: a junction a few streets away, round at least one corner
	var goal: Vector2 = car.p
	for i in range(MapData.nodes.size()):
		var q: Vector2 = MapData.nodes[i]
		var crow: float = q.distance_to(car.p)
		if crow > 150.0 and crow < 230.0 and MapData.degree(i) >= 3 and absf((q - car.p).normalized().dot(ru)) < 0.75 and MapData.main_comp[i] == 1:
			goal = q
			break
	g.target = goal
	var way := 0.0
	var last: Vector2 = car.p
	for q in MapData.path(car.p, goal):
		way += q.distance_to(last)
		last = q
	await _frames(3)
	var offered: bool = g.hud.gauge.style == "digital" and g.hud.gauge.key_show and g.hud.gauge.key == Controls.glyph("run") and g.hud.gauge.auto == 0
	if shots:
		await _shot("auto_offered")
	g._toggle_autopilot()
	await _frames(3)
	_check(offered and g.autopilot != null and g.hud.gauge.auto == 1 and not g.hud.gauge.key_show, "the Edison offers its autopilot on the %s key; pressed, the glass says so" % Controls.glyph("run"))
	var took := 0.0
	var hurt: float = car.hp
	var d0: float = car.p.distance_to(goal)
	while g.autopilot != null and took < 90.0:
		await get_tree().physics_frame
		g.target = goal
		took += 1.0 / 60.0
		if shots and absf(took - 6.0) < 0.009:
			await _shot("auto_driving")
	_check(g.autopilot == null and car.p.distance_to(goal) < 16.0 and car.hp >= hurt - 1.0 and not car.flipped(),
		"left alone it drives itself there: %.0f m of streets and corners in %.0f s, without a scratch, and stops %.0f m from the spot (it started %.0f m away)" % [way, took, car.p.distance_to(goal), d0])
	# with nowhere to go it just drives; a touch of the wheel and it is yours again
	g.target = null
	car.place(run.a + ru * 8.0 + Vector2(-ru.y, ru.x) * 1.0, atan2(ru.x, ru.y))
	await _frames(10)
	g._toggle_autopilot()
	var from: Vector2 = car.p
	var fastest := 0.0
	for i in range(240):
		await get_tree().physics_frame
		fastest = maxf(fastest, car.vel.length())
	var strolled: float = car.p.distance_to(from)
	var mode: int = g.hud.gauge.auto
	Input.action_press("left")
	await _frames(4)
	Input.action_release("left")
	_check(strolled > 12.0 and fastest < 14.0 and mode == 2 and g.autopilot == null, "with no errand it goes for a drive (%.0f m in 4 s, never over %.0f km/h); touch the wheel and it lets go" % [strolled, fastest * 3.6])
	g.police.add_heat(250.0)
	await _frames(2)
	g._toggle_autopilot()
	_check(g.autopilot == null, "and it will have nothing to do with a police chase")
	g.police.reset()
	car.set_speed(Vector2.ZERO)
	await _frames(3)
	g._exit_car()
	await _frames(3)
	car.queue_free()
	g.target = was_target
	g.phase = was_phase
	g.traffic._spawn_t = 2.0
	await _frames(3)

## The town on its relief: is it all of a piece? No holes in the ground, streets lying on it, walls down to it, level
## terraces under what was built by hand, and everything that stands, standing on it.
func _relief_checks() -> void:
	var space := get_tree().root.get_world_3d().direct_space_state
	var W = g.world
	var lo: float = Array(MapData.rh).min()
	var hi: float = Array(MapData.rh).max()
	_check(MapData.rnx > 100 and hi - lo > 40.0, "the land has its relief: %.0f m between the lowest and the highest ground" % (hi - lo))
	# --- the ground you see is the ground you stand on, everywhere: straight down at every junction and on a grid over the whole map
	var probes: Array = []
	for i in range(MapData.nodes.size()):
		probes.append(MapData.nodes[i])
	var x := MapData.xmin + 5.0
	while x < MapData.xmax:
		var z := MapData.zmin + 5.0
		while z < MapData.zmax:
			probes.append(Vector2(x, z))
			z += 47.0
		x += 47.0
	for corner in [Vector2(MapData.xmin + 1, MapData.zmin + 1), Vector2(MapData.xmax - 1, MapData.zmin + 1), Vector2(MapData.xmax - 1, MapData.zmax - 1), Vector2(MapData.xmin + 1, MapData.zmax - 1)]:
		probes.append(corner)
	var where := ""
	var holes := 0
	var built := 0                                # places with something solid standing on them (or sunk in them): not holes
	var off := 0.0
	for p0 in probes:
		# (a hair off the spot itself: a junction that falls exactly on a line of the ground's own grid would send the ray
		# down the seam between two of its triangles, and a ray along a seam may slip through)
		var p: Vector2 = p0 + Vector2(0.013, 0.007)
		var h: float = MapData.height(p)
		var found := false
		var solid := false
		for way in [[0.6, -8.0], [-8.0, 0.6]]:    # looked at from above, and from underneath
			var ray := PhysicsRayQueryParameters3D.create(MapData.at(p, way[0]), MapData.at(p, way[1]), 1)
			var hit := space.intersect_ray(ray)
			while not hit.is_empty() and hit["collider"] != W.body:      # (a trailer parked over the spot, a shutter: look past it)
				ray.exclude = ray.exclude + [hit["rid"]]
				hit = space.intersect_ray(ray)
			if hit.is_empty():
				continue
			solid = true
			if absf(hit["position"].y - h) < 0.02:
				found = true
				off = maxf(off, absf(hit["position"].y - h))
		if found:
			continue
		if solid:
			built += 1                            # (the ray from above started inside a wall, or met a footing first from below)
		else:
			holes += 1
			where += " (%.1f, %.1f)" % [p.x, p.y]
	_check(holes == 0 and off < 0.02 and built < probes.size() / 50, "no holes in the ground: solid under all %d places tried, never more than %.0f mm from where it is drawn (%d of them are under something built)%s" % [probes.size(), off * 1000.0, built, where])
	# --- streets, fields and road paint lie on it: nothing lost in the cutting, no piece bridging a dip or buried in a rise
	var lost := 0.0
	var bridge := 0.0
	var total := 0.0
	for s in W.audit_sheets:
		total += s[1]
		if s[0] > 1.0:
			lost = maxf(lost, absf(1.0 - s[1] / s[0]))
		bridge = maxf(bridge, s[2])
	_check(W.audit_sheets.size() >= 10 and lost < 0.002 and bridge < 0.003, "the %d sheets of street, field and paint are cut to the ground's own facets: %.1f ha laid, at most %.2f %% lost, at most %.1f mm off it" % [W.audit_sheets.size(), total / 10000.0, lost * 100.0, bridge * 1000.0])
	# --- every wall goes down into the ground (no daylight under a house), and no house is left hanging or buried
	var aw: Dictionary = W.audit_walls
	_check(aw["n"] > 40000 and aw["gap"] < -0.5, "all %d walls reach the ground: the shallowest foot is still %.2f m under it" % [aw["n"], -aw["gap"]])
	_check(aw["fronts"] > 5000 and aw["odd"] < aw["fronts"] * 0.01 and aw["high"] < 4.0 and aw["deep"] < 0.8,
		"houses meet their street: of %d fronts, %d (%.1f %%) have the floor over 1.6 m above the pavement or 0.4 m under it; the worst are %.1f m above (at %.0f, %.0f) and %.1f m under (at %.0f, %.0f)"
		% [aw["fronts"], aw["odd"], 100.0 * aw["odd"] / maxf(1.0, aw["fronts"]), aw["high"], aw["high_at"].x, aw["high_at"].y, aw["deep"], aw["deep_at"].x, aw["deep_at"].y])
	# --- a level terrace under everything built by hand
	var th: Dictionary = MapData.townhall
	var tu := Vector2(th["u"][0], th["u"][1])
	var tm := Vector2(th["m"][0], th["m"][1])
	var places: Array = [["the square", func(a: float, b: float) -> Vector2: return tm + tu * lerpf(16.0, 36.0, a) + Vector2(-tu.y, tu.x) * lerpf(-14.0, 92.0, b)],     # (its east side: the west stands on a wall over the sunk Arroyuelo, which --acera checks)
		["the cooperative", func(a: float, b: float) -> Vector2: return MapData.coop_point(lerpf(-40.0, 156.0, a), lerpf(-8.0, 152.0, b))],
		["V.I.P.", func(a: float, b: float) -> Vector2: return (g.vip.WALL_A + g.vip.WALL_B) / 2.0 + Vector2(lerpf(-7.0, 7.0, a), lerpf(-7.0, 7.0, b))],
		["V.I.P. inside", func(a: float, b: float) -> Vector2: return g.vip.INSIDE + Vector2(lerpf(-20.0, 20.0, a), lerpf(-12.0, 30.0, b))],
		["Henry's", func(a: float, b: float) -> Vector2: return Vector2(-88.5, -71.4) + Vector2(lerpf(-5.0, 5.0, a), lerpf(-5.0, 5.0, b))]]
	var ch = W.church
	places.append(["the church", func(a: float, b: float) -> Vector2: return ch.spot(lerpf(-12.0, ch.L + 6.0, a), lerpf(-ch.D - 12.0, 12.0, b))])
	for gar in g.garages:
		places.append([gar.id, func(a: float, b: float) -> Vector2: return gar.mouth + gar.right * lerpf(-gar.w / 2.0 - 2.0, gar.w / 2.0 + 2.0, a) + gar.out * lerpf(-gar.d, 11.0, b)])
	var uneven := ""
	for pl in places:
		var l := INF
		var h := -INF
		for i in range(13):
			for j in range(13):
				var y: float = MapData.height(pl[1].call(i / 12.0, j / 12.0))
				l = minf(l, y); h = maxf(h, y)
		if h - l > 0.02:
			uneven += "%s (%.2f m) " % [pl[0], h - l]
	_check(uneven == "", "level ground under the %d places built by hand %s" % [places.size(), uneven])
	for gar in g.garages:
		_check(absf(gar._f.global_position.y - MapData.height(gar.mouth)) < 0.01 and absf(MapData.height(gar.spot) - MapData.height(gar.apron)) < 0.01, "%s: the bay, the doorway and the forecourt are on one level (%.1f m)" % [gar.id, MapData.height(gar.mouth)])
	# --- how steep it gets
	var steep := 0.0
	var steep_road := ""
	var steep_at := Vector2.ZERO
	for s in MapData.segs:
		if s.road["k"] != 0:
			continue
		var length: float = s.a.distance_to(s.b)
		if length < 6.0:
			continue
		var grade: float = absf(MapData.height(s.b) - MapData.height(s.a)) / length
		if grade > steep:
			steep = grade
			steep_road = s.road["n"]
			steep_at = (s.a + s.b) / 2.0
	_check(steep > 0.06 and steep < 0.3, "streets climb, but none is a wall: the steepest is %s at %.0f %%" % [steep_road if steep_road != "" else "a street with no name", steep * 100.0])
	# --- everything that stands, stands on it
	var floating := 0
	var worst_npc := 0.0
	for n in g.npcs:
		var d: float = absf(n.global_position.y - MapData.foot(n.p))      # (whoever is up on the old bridge has their feet on the bridge)
		worst_npc = maxf(worst_npc, d)
		if d > 0.05:
			floating += 1
	_check(floating == 0 and g.npcs.size() > 50, "all %d neighbours have their feet on the ground (worst %.0f mm)" % [g.npcs.size(), worst_npc * 1000.0])
	var adrift := 0
	var worst_car := 0.0
	var who := ""
	for c in g.cars:
		if c == g.in_car or c == g.paca_car or c.vel.length() > 0.5:      # (the Z15 is wherever the driving checks left it)
			continue
		var d2: float = c.global_position.y - MapData.height(c.p)      # (a tractor's body rides well clear of the ground on its wheels)
		worst_car = maxf(worst_car, absf(d2))
		if d2 < -0.25 or d2 > float(c.spec["wheel"]) * 1.4 + 0.3 or c.global_transform.basis.y.dot(MapData.normal(c.p)) < 0.9:
			adrift += 1
			who += " %s at %.0f, %.0f: %.2f m off, upright %.2f, %s;" % [c.kind, c.p.x, c.p.y, d2, c.global_transform.basis.y.dot(MapData.normal(c.p)), "asleep" if c.dozing else "awake"]
			if shots:
				g.player.p = c.p
				g.cam.position = MapData.at(c.p + Vector2(6.0, 5.0), 3.2)
				g.cam.look_at(MapData.at(c.p, 0.6))
				await _frames(4)
				await _shot("relief_car_%d" % adrift)
	_check(adrift == 0 and g.cars.size() > 30, "all %d parked cars sit on their street, leaning with it (the highest body %.2f m up, on tractor wheels)%s" % [g.cars.size(), worst_car, who])
	var lamps_off := 0
	for sp in g.lights.spots:
		var up: float = sp.y - MapData.height(Vector2(sp.x, sp.z))
		if up < 1.2 or up > 9.0:
			lamps_off += 1
	var trees_off := 0
	for tr in W.tree_info:
		if absf(tr["shape"].position.y - 2.0 - MapData.height(tr["p"])) > 0.01:
			trees_off += 1
	var props_off := 0
	var props_n := 0
	for cell in g.props._grid.values():
		for b in cell:
			props_n += 1
			if is_instance_valid(b) and b.freeze and absf(b.position.y - MapData.height(b.get_meta("p"))) > 0.01 and absf(b.position.y - MapData.foot(b.get_meta("p"))) > 0.01:      # (or on the floor walked on there: the plaza's terraza, props.gd on_floor)
				props_off += 1
	_check(lamps_off == 0 and trees_off == 0 and props_off == 0, "%d lanterns hang at lantern height, %d trees and %d benches, bins and signs stand on the ground (out of place: %d, %d, %d)" % [g.lights.spots.size(), W.tree_info.size(), props_n, lamps_off, trees_off, props_off])
	# --- and it works: walk and drive the steepest street, up and down
	var seg = null
	for s in MapData.segs:
		if s.road["k"] == 0 and (s.a + s.b).distance_to(steep_at * 2.0) < 0.1:
			seg = s
	if seg != null:
		var up_from: Vector2 = seg.a if MapData.height(seg.a) < MapData.height(seg.b) else seg.b
		var up_to: Vector2 = seg.b if up_from == seg.a else seg.a
		var dir: Vector2 = (up_to - up_from).normalized()
		if g.in_car != null:
			g._exit_car()
			await _frames(5)
		var walker = g.spawn_neighbour(up_from + dir * 1.0, true)
		var start_y: float = walker.global_position.y
		var walked_off := 0.0
		for i in range(240):
			walker.walk(dir, 2.4)
			walked_off = maxf(walked_off, absf(walker.global_position.y - MapData.height(walker.p)))
			await get_tree().physics_frame
		var gone: float = (walker.p - up_from).dot(dir)
		_check(gone > 7.0 and walker.global_position.y > start_y + 0.3 and walked_off < 0.01, "a neighbour walks up it: %.1f m along and %.2f m higher in 4 s, feet on the ground all the way" % [gone, walker.global_position.y - start_y])
		g.npcs.erase(walker)
		walker.queue_free()
		_tow_away_from((up_from + up_to) / 2.0, 60.0)
		g.traffic.clear()
		for way in [[up_from, dir, "up"], [up_to, -dir, "down"]]:
			var c = g.paca_car
			c.repair()
			c.place(way[0] + way[1] * 2.0, atan2(way[1].x, way[1].y))
			await _frames(30)
			var y0: float = c.global_position.y
			var worst := 0.0
			for i in range(150):
				c.drive(0.7, 0.0, false, true, 1.0 / 60.0)
				await get_tree().physics_frame
				if not c.airborne():
					worst = maxf(worst, absf(c.global_position.y - MapData.height(c.p)))
			var climbed: float = c.global_position.y - y0
			var went: float = (c.p - (way[0] as Vector2)).dot(way[1])
			_check(went > 8.0 and worst < 0.5 and ((climbed > 0.3) if way[2] == "up" else (climbed < -0.3)) and c.global_transform.basis.y.y > 0.9,
				"the Z15 drives %s it: %.0f m along, %+.1f m in height, never more than %.2f m from the ground" % [way[2], went, climbed, worst])
			c.park()
			c.set_speed(Vector2.ZERO)
		for kind in ["z15", "yondir"]:           # and a car left parked on it stays where it was left
			var parked = CarS.new()
			g.add_child(parked)
			parked.setup(kind, 0xf4f4f0, (up_from + up_to) / 2.0, atan2(dir.x, dir.y))
			parked.park()
			await _frames(40)
			var left_at: Vector2 = parked.p
			var trace := ""
			for k in range(6):
				await _frames(60)
				trace += " %.2f" % (parked.global_position.y - MapData.height(parked.p))
			var sits: float = parked.global_position.y - MapData.height(parked.p)
			_check(parked.p.distance_to(left_at) < 0.15 and parked.global_transform.basis.y.dot(MapData.normal(parked.p)) > 0.97 and sits > -0.25 and sits < 0.3,
				"a %s parked on the steepest street holds on its handbrake (%.2f m in 6 s)" % [parked.spec["name"], parked.p.distance_to(left_at)])
			parked.queue_free()
			await _frames(3)
	if shots:                                    # the three places most worth a look: where a floor is highest, where deepest, the steepest street
		for v in [["high", aw["high_at"]], ["deep", aw["deep_at"]], ["steep", steep_at]]:
			var at: Vector2 = v[1]
			var eye: Vector2 = MapData.nearest_road(at)["p"]
			if eye.distance_to(at) < 5.0:
				eye += (eye - at).normalized().rotated(0.6) * 9.0 if eye.distance_to(at) > 0.1 else Vector2(9, 0)
			g.player.p = eye
			g.cam.position = MapData.at(eye, 2.2)
			g.cam.look_at(MapData.at(at, 1.5))
			await _frames(6)
			await _shot("relief_worst_" + v[0])

## the garages you drive into: the shutter, the bay, the horn, the bill
func _garage_bay_checks() -> void:
	_check(g.garages.size() == 4 and ["valdeacero", "errejota", "xandro", "df"].all(func(k): return g.garages.any(func(x): return x.id == k)), "four garages with a bay inside: Talleres Valdeacero, Errejota Taller, Talleres Xandro and df Mecánica")
	if g.in_car == null:
		g._enter_car(g.paca_car)
	var c = g.in_car
	for gar in g.garages:
		_tow_away_from(gar.mouth, 30.0)
		c.repair()
		c.place(gar.mouth + gar.out * 60.0, 0.0)
		await _frames(90)
		var shut: bool = gar.open <= 0.0 and not gar._gate.disabled
		var hit := get_tree().root.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			MapData.at(gar.apron, 1.0), MapData.at(gar.spot, 1.0), 1))
		c.place(gar.apron, atan2(-gar.out.x, -gar.out.y))
		await _frames(100)
		_check(shut and not hit.is_empty() and gar.open >= 1.0 and gar._gate.disabled, "%s: the shutter is down with nobody about and rolls up when a car comes to the door" % gar.id)
		g._crash(c, 12.0)
		g.money = 60
		await _frames(10)
		var outside: bool = not g.at_garage and g.hud.prompt.text == Loc.t("p_garage_in")
		for i in range(600):                     # drive in, gently, and stop in the middle of the bay
			var inn: float = -(c.p - gar.mouth).dot(gar.out)
			if inn >= gar.d * 0.5:
				break
			if c.vel.length() < 3.0:
				Input.action_press("forward")
			else:
				Input.action_release("forward")
			await get_tree().physics_frame
		Input.action_release("forward")
		Input.action_press("handbrake")
		await _frames(50)
		Input.action_release("handbrake")
		var price: int = g.repair_price(c)
		await _frames(20)
		_check(outside and gar.holds(c.p, c.spec["len"]) and g.at_garage and g.hud.prompt.text.contains("%d €" % price),
			"%s: at the door they tell you to bring it in; inside, the price and the horn (%s)" % [gar.id, g.hud.prompt.text])
		g._horn_cool = 0.0
		g.honk()
		await _frames(30)
		var held: bool = g.mending != null and c.hp < c.spec["hp"] and g.money == 60 and g.cam_fixed != null
		await _frames(50)
		var down: bool = gar.open <= 0.0 and not gar._gate.disabled
		if shots:
			await _shot("garage_%s_shut" % gar.id)
		await _frames(200)
		_check(held and down and g.mending == null and c.hp == c.spec["hp"] and g.money == 60 - price and g.cam_fixed == null,
			"%s: honk and the shutter comes down, they work on it, and only then is it mended and charged (%d €)" % [gar.id, price])
		await _frames(70)
		_check(gar.open >= 1.0 and gar._gate.disabled, "%s: and up it goes again to let you out" % gar.id)

## moves parked cars out of the way round a spot
func _tow_away_from(p: Vector2, r: float) -> void:
	for c in g.cars:
		if c != g.in_car and c.p.distance_to(p) < r:
			c.place(c.p + Vector2(0, 400.0 + randf() * 60.0), c.h)

## pictures of the garages: the front, the bay with a car in it
func _garage_shots() -> void:
	for gar in g.garages:
		_tow_away_from(gar.mouth, 30.0)
		var wide: float = 11.0 if gar.id == "valdeacero" else (6.2 if gar.id == "df" else 21.0)
		var from: Vector2 = gar.mouth + gar.out * wide + gar.right * (wide * 0.35)
		g.player.p = gar.mouth + gar.out * 60.0
		gar.want_open = false
		for i in range(80):
			gar.tick(1.0 / 60.0, false)
		g.cam.position = MapData.at(from, 2.6)
		if gar.id == "df":                               # a narrow street: from along it, looking up at the front
			from = gar.mouth + gar.out * 5.6 + gar.right * 13.0
			g.cam.position = MapData.at(from, 1.9)
		var centre: Vector2 = gar.mouth + gar.right * gar.middle
		g.cam.look_at(MapData.at(centre, gar.tall * 0.55))
		await _shot("front_" + gar.id)
		var car = g.paca_car
		car.place(gar.spot, atan2(-gar.out.x, -gar.out.y))
		gar.want_open = true
		for i in range(80):
			gar.tick(1.0 / 60.0, false)
		await _frames(20)
		var near: Vector2 = gar.mouth + gar.out * 7.5 - gar.right * 1.6
		g.cam.position = MapData.at(near, 2.0)
		g.cam.look_at(MapData.at(gar.spot, 1.3))
		await _shot("bay_" + gar.id)
		var inside: Vector2 = gar.mouth - gar.out * 0.8 + gar.right * (gar.w * 0.5 - 0.6)
		g.cam.position = MapData.at(inside, 2.3)
		g.cam.look_at(MapData.at(gar.spot - gar.right * 1.0 - gar.out * 2.0, 1.0))
		await _shot("inside_" + gar.id)

func _garage_checks() -> void:
	var S: Dictionary = CarS.SPECS
	var fast: Array = S.keys().filter(func(k): return not (k in ["pitufo", "tricornio", "grua"]))
	fast.sort_custom(func(a, b): return S[a]["max"] > S[b]["max"])
	_check(fast[0] == "julietta" and fast[1] == "edison" and S["edison"]["sound"] == "electric" and float(S["edison"]["smoke"]) == 0.0, "the %s is the fastest car and the %s the second, electric and smokeless" % [S[fast[0]]["name"], S[fast[1]]["name"]])
	var loud := true                 # red and bright green belong to the Julietta alone among the cars (the Hebro, a tractor, also comes in red)
	for k in S:
		for col in S[k].get("colors", []):
			var cc := Color(((col >> 16) & 255) / 255.0, ((col >> 8) & 255) / 255.0, (col & 255) / 255.0)
			var is_red: bool = cc.r > 0.7 and cc.g < 0.3 and cc.b < 0.3
			var is_lime: bool = cc.g > 0.8 and cc.r < 0.5 and cc.b < 0.5
			if (is_red or is_lime) != (k == "julietta") and not (k == "tractor" and is_red):
				loud = false
	_check(loud and S["panda"]["colors"].size() >= 8 and S["z15"]["colors"].size() == 3 and S["edison"]["colors"].size() == 2 and S["tractor"]["colors"].size() == 2 and S["yondir"]["colors"].size() == 1,
		"each make keeps to its colours: %d for the Zeat, white, silver or black Z15s, blue or red Hebros, black or white Edisons, and among the cars only the Julietta in red or loud green" % S["panda"]["colors"].size())
	_check(S["tractor"]["cab"] == 0.0 and S["yondir"]["max"] > S["tractor"]["max"] and S["yondir"]["hp"] > S["tractor"]["hp"] and S["yondir"]["mass"] > S["tractor"]["mass"] and float(S["yondir"]["offroad"]) == 1.0,
		"the Hebro has lost its cab; the Yondir is bigger, faster and tougher")
	g.traffic.clear()                          # nobody else on the road while we measure
	g.traffic._spawn_t = 99999.0
	var open = _clear_street()                 # (wherever the jump left the car, there may be a wall in front of it)
	if open != null:
		var along: Vector2 = (open.b - open.a).normalized()
		g.in_car.place(open.a + along * 6.0 + Vector2(-along.y, along.x) * 1.0, atan2(along.x, along.y))
		await _frames(10)
	var here: Vector2 = g.in_car.p
	var u := Vector2(sin(g.in_car.h), cos(g.in_car.h))
	var made: Array = []
	for k in ["yondir", "tractor", "z15", "edison"]:
		var c = CarS.new()
		g.add_child(c)
		c.setup(k, 0xb23a3a, here + u * (12.0 + made.size() * 7.0), g.in_car.h)
		made.append(c)
	await _frames(20)
	var yondir = made[0]
	var hebro = made[1]
	var z15 = made[2]
	var edison = made[3]
	_check(((yondir.paint >> 8) & 255) > ((yondir.paint >> 16) & 255) * 1.5 and yondir.model != null and yondir.wheels.size() == 4 and yondir.wheels[0].get_child_count() == 1,
		"a Yondir is green whatever colour you ask for, and it is its model that stands there, its own wheels on the springs")
	_check(not z15.running and z15.cough == null, "a parked car has its engine off")
	var z15_was_red: bool = not (z15.material_colour() in S["z15"]["colors"])
	for c in made:
		c.drive(1.0, 0.0, false, true, 0.016)
	await _frames(4)
	_check(z15.running and z15.cough != null and z15.cough.emitting and not z15.vapour.emitting, "starting it makes it cough a cloud of smoke")
	_check(hebro.cough.amount > g.in_car.spec.get("smoke", 1.0) * 0.0 + 40 and hebro.cough.scale_amount_max > z15.cough.scale_amount_max and edison.cough == null, "the tractors smoke most of all; the electric car not at all")
	for i in range(170):
		for c in made:
			c.drive(0.6, 0.0, false, true, 0.016)
		await get_tree().physics_frame
	_check(not z15.cough.emitting and z15.vapour.emitting and z15.vel.length() > 3.0, "once it is going, just a haze from the exhaust")
	z15.park()
	z15.set_speed(Vector2.ZERO)
	await _frames(4)
	_check(not z15.vapour.emitting and not z15.running, "switched off, nothing")
	for c in made:
		c.queue_free()
	# the Julietta and its turbo
	var jul = CarS.new()
	g.add_child(jul)
	jul.setup("julietta", 0x3b5fa8, here + u * 14.0, g.in_car.h)
	_check(jul.material_colour() in S["julietta"]["colors"] and not z15_was_red, "ask for a blue Julietta or a red Z15 and you get one in its own colours")
	jul.park()
	# a patrol car on its beat sees the turbo
	g.police.reset()
	g.traffic.clear()
	g.traffic._spawn_t = 99999.0
	var mine = g.in_car
	mine.set_speed(Vector2.ZERO)
	g._exit_car()
	jul.place(here, mine.h)
	g._enter_car(jul)
	var beat = CarS.new()
	g.add_child(beat)
	beat.setup("pitufo", 0, here + u * 22.0, mine.h)
	var be := {"car": beat, "a": MapData.nearest_node(here), "b": MapData.nearest_node(here), "wait": 0.0, "honk": 0.0, "lat": 1.0, "stuck": 0.0, "rev": 0.0, "rs": 1.0, "tries": 0}
	g.traffic.list.append(be)
	jul.boosting = false
	g._turbo_look = 0.0
	g._turbo(jul, 0.016)
	_check(not g.police.chasing and g.traffic.has_patrol(), "driving past a patrol car without the turbo is nobody's business")
	jul.boosting = true
	g._turbo_look = 0.0
	g._turbo(jul, 0.016)
	_check(g.police.chasing and g.police.heat >= 100.0 and not g.traffic.list.has(be) and g.police.cops.any(func(e2): return e2["car"] == beat), "lit in front of it, that same patrol car gives chase and calls another")
	g.police.reset()
	jul.set_speed(Vector2.ZERO)
	g._exit_car()
	g._enter_car(mine)
	g.cars.erase(jul)
	jul.queue_free()
	g.traffic._spawn_t = 1.0
	# the sky and the lights, through a day
	var was: float = g.clock
	g.set_time(13.0)
	_check(g.sky_fx.night == 0.0 and not g.sky_fx._stars.visible and g.sky_fx._flocks[0]["node"].visible and g.sky_fx._cloud_mat.albedo_color.r > 0.9 and g.sky_mat.sky_top_color.b > g.sky_mat.sky_top_color.r * 4.0,
		"at midday: a deep blue sky, white clouds, birds about, no stars")
	_check(g.lights.spots.size() > 300 and g.lights._glass.emission_energy_multiplier == 0.0 and not g.in_car.lit, "the town has its lanterns (%d of them), unlit by day; no headlights" % g.lights.spots.size())
	g.set_time(20.9)
	var half: float = g.sky_fx.night
	g.set_time(23.0)
	g.lights._t = 0.0
	g.lights.tick(0.016, g.player.p)
	_check(half > 0.05 and half < 0.6 and g.sky_fx.night > 0.95 and g.sky_fx._stars.visible and g.sky_fx._moon.visible and g.sky_fx.moon_dir().y > 0.2 and not g.sky_fx._flocks[0]["node"].visible,
		"night falls little by little (%.0f %% at nine): by eleven the stars are out, the moon is up and the birds have gone to roost" % (half * 100.0))
	_check(g.lights._glass.emission_energy_multiplier > 2.0 and g.lights._pool[0].visible and g.lights._pool[0].light_energy > 2.0 and g.lights._shop.size() >= 5 and g.lights._shop[0][0].visible
		and float(g.world.facade_mats[0].get_shader_parameter("night")) > 0.9, "after dark the lanterns, the shops and the windows are lit")
	_check(g.in_car.lit and g.in_car._beam != null and g.in_car._beam.visible and not g.cars.any(func(c): return c != g.in_car and c.lit), "your headlights are on and light the road; parked cars stay dark")
	g.set_time(was)
	_check(not g.in_car.lit and g.lights._glass.emission_energy_multiplier == 0.0, "and by day it all goes out again")
	# the engine sound follows the car
	Sfx.engine(true, 20.0, 1.0, "electric")
	var hum_moving: float = Sfx._engine.volume_db
	Sfx.engine(true, 0.0, 0.0, "electric")
	_check(Sfx._engine.stream == Sfx._electric and Sfx._engine.volume_db <= -79.0 and hum_moving > -30.0, "an electric car is silent standing still and only whispers on the move")
	Sfx.engine(false, 0.0)
	# busier streets
	var near := 0
	for n in g.npcs:
		if n.id == "" and n.walker and not n.away and n.p.distance_to(here) < 210.0:
			near += 1
	var moved: int = g._keep_crowd_near(here, 200)
	var near_after := 0
	var varied := {}
	for n in g.npcs:
		if n.id == "" and n.walker and not n.away and n.p.distance_to(here) < 210.0:
			near_after += 1
	_check(near_after >= 40 and near_after >= near and g.traffic.MAX_CARS >= 14 and g.cars.size() >= 60, "the streets are busier: %d neighbours walking within 200 m (%d before they gathered), up to %d cars driving, %d parked" % [near_after, near, g.traffic.MAX_CARS, g.cars.size()])
	var looks := {"glasses": 0, "earrings": 0, "pendant": 0, "top": 0, "face": 0}
	var styles := {}
	for i in range(200):
		var o: Dictionary = g._neighbour_look(g.NEIGHBOUR_VOICES[i % g.NEIGHBOUR_VOICES.size()])
		for key in looks:
			if int(o.get(key, 0)) > 0:
				looks[key] += 1
		styles[int(o.get("hair_style", 0))] = true
	_check(looks["glasses"] > 30 and looks["earrings"] > 20 and looks["pendant"] > 20 and looks["top"] > 100 and looks["face"] > 30 and styles.size() >= 10,
		"neighbours come in many more shapes: of 200, %d wear glasses, %d earrings, %d something round the neck; %d hairstyles" % [looks["glasses"], looks["earrings"], looks["pendant"], styles.size()])

## breakables, bodywork, repairs, trailers to jump off and Los Pitufos
func _mayhem_checks() -> void:
	var c = g.in_car
	var road: Dictionary = g.places["tanatorio"]
	# street furniture flies
	var bench = null
	for list in g.props._grid.values():
		if not list.is_empty():
			bench = list[0]
			break
	var bp: Vector2 = bench.get_meta("p")
	c.place(bp - Vector2(0, 6), 0.0)
	c.global_position.y = MapData.foot(bp - Vector2(0, 6)) + 0.12        # (the first piece of furniture is on the terrace of the Plaza del Ayuntamiento, whose floor is a deck over sunk ground: place() knows only the ground, and would leave the car inside that floor)
	c.set_speed(Vector2(0, 11))
	await _frames(20)
	_check(g.props.broken_count >= 1 and not bench.freeze, "driving into street furniture knocks it loose")
	_check(g.police.heat > 0.0, "and the heat meter rises (%.0f)" % g.police.heat)
	# a rolled car stays rolled until it is pushed three times
	_check(c.kind == "z15", "the mission vehicle is the white Z15")
	var CarSpecs: Dictionary = c.SPECS
	_check(CarSpecs["z15"]["offroad"] == 0.9 and CarSpecs["tractor"]["offroad"] == 1.0 and not CarSpecs["panda"].has("offroad") and CarSpecs["tractor"]["name"] == "Súper Hebro 555", "off road the Z15 keeps 90 % of its speed and the Súper Hebro 555 all of it")
	c.global_transform = Transform3D(Basis(Vector3.FORWARD, PI), c.global_position + Vector3(0, 1.2, 0))
	c.set_speed(Vector2.ZERO)
	await _frames(100)
	_check(c.flipped(), "a car on its roof stays on its roof")
	g._exit_car()
	await _frames(5)
	for i in range(3):
		g._push_car(c)
	await _frames(20)
	_check(not c.flipped() and c.global_transform.basis.y.y > 0.9, "three shoves put it back on its wheels")
	# a punch on foot knocks furniture over
	var solo = null
	for list in g.props._grid.values():
		for b in list:
			if b.get_meta("kind") == "bin":
				solo = b
	g.player.p = solo.get_meta("p") - Vector2(0, 0.9)
	g.player.h = 0.0
	await _frames(3)
	g._punch_cool = 0.0
	g._punch()
	await _frames(12)                              # (with Henry's bat the hit gets there a moment later)
	_check(not solo.freeze, "a punch knocks a bin over")
	g._enter_car(c)
	g.police.reset()
	# stealing a neighbour's car
	g._exit_car()
	await _frames(5)
	for attempt in range(40):               # make sure a neighbour is out driving somewhere near
		if not g.traffic.list.is_empty():
			break
		g.traffic._spawn(g.player.p)
	var victim_e: Dictionary = g.traffic.list[0]
	var stolen = victim_e["car"]
	g.traffic._spawn_t = 999.0
	var clear_spot: Dictionary = _long_street()            # away from our own parked van, which would be the nearer car
	g.player.p = clear_spot["p"] + clear_spot["u"] * 30.0
	stolen.place(g.player.p + Vector2(-clear_spot["u"].y, clear_spot["u"].x) * 2.2, atan2(clear_spot["u"].x, clear_spot["u"].y))
	await _frames(6)
	_check(g.near_steal != null and g.near_car == stolen, "a neighbour's car stopped beside you can be stolen")
	var people_before: int = g.npcs.size()
	g.interact()
	_check(g.in_car == stolen and g.cars.has(stolen) and not g.traffic.list.has(victim_e), "stealing it puts you at the wheel")
	_check(g.police.heat >= 75.0 * g.heat_scale() and g.npcs.size() == people_before + 1 and g.npcs[-1].state == "down", "the driver ends up on the ground and the heat jumps by 75, or by half that with a mission under way (%.0f)" % g.police.heat)
	g._exit_car()
	g._enter_car(c)
	g.police.reset()
	g.traffic._spawn_t = 1.0
	# pause menu
	c.set_speed(Vector2(sin(c.h), cos(c.h)) * 6.0)  # (rolling along when the pause comes)
	var held_at: Vector3 = c.global_position
	g._open_pause()
	await _frames(20)
	_check(c.global_position.distance_to(held_at) < 0.2 and Sfx.held() and not Ambience._players.any(func(p): return p.playing and not p.stream_paused),
		"the pause stops the world: the car stays where it was (%.2f m) and the music and the engine wait" % c.global_position.distance_to(held_at))
	var pause_items: Array = g._menu_page("pause")["items"].map(func(it): return it["text"])
	_check(g.paused and g.menu.visible and pause_items == [Loc.t("m_resume"), Loc.t("m_log"), Loc.t("m_save"), Loc.t("m_settings"), Loc.t("m_quit")], "pause menu: Resume, Log, Save, Settings, Quit")
	g.money = 77
	g._pause_save()
	_check(int(g._load_slot(g.slot)["money"]) == 77, "Save writes the slot")
	g.money = 0
	g._close_pause()
	_check(not g.paused and not g.menu.visible, "Resume closes it")
	await _frames(10)
	_check(c.global_position.distance_to(held_at) > 0.2 and not Sfx.held(), "and the world goes on: the car rolls on (%.1f m) and the sound comes back" % c.global_position.distance_to(held_at))
	c.set_speed(Vector2.ZERO)
	_check(g._menu_page("main")["items"][0]["text"] == Loc.t("menu_continue") and g._slot_label(g.slot).contains("77"), "with a save, the main menu offers Continue and the slot shows its mission and money")
	# radio
	var first: Dictionary = Ambience.next_station()
	var radio_hid: bool = g.hud.radio_slot.get_theme_constant("margin_bottom") == g.hud.RADIO_IN
	g.hud.radio_card(first)
	await _frames(20)
	var radio_up: bool = g.hud.radio_slot.get_theme_constant("margin_bottom") == g.hud.RADIO_OUT and g.hud.radio_box.modulate.a == 1.0 \
		and g.hud.street_slot.get_theme_constant("margin_bottom") > g.hud.RADIO_OUT + 100
	g.hud.radio_card({})
	await _frames(15)
	var radio_gone: bool = g.hud.radio_slot.get_theme_constant("margin_bottom") == g.hud.RADIO_IN and g.hud.radio_box.modulate.a == 0.0 \
		and g.hud.street_slot.get_theme_constant("margin_bottom") == 16
	g.hud.radio_card(first)
	var folders := 0                                 # (as many stations as there are folders radio1, radio2...: the user adds them)
	while DirAccess.dir_exists_absolute(Ambience.radio_root().path_join("radio%d" % (folders + 1))):
		folders += 1
	_check(not first.is_empty() and first == Ambience.stations[Ambience.station - 1] and Ambience.stations.size() == folders and folders >= 5
		and Ambience.stations.all(func(s): return s["logo"] != null and s["about"] != "" and not s["tracks"].is_empty() and Ambience._radio_stream(Ambience.stations.find(s) + 1) != null)
		and g.hud.radio_box.logo == first["logo"] and g.hud.radio_box.who == Ambience.playing(first)[0] and g.hud.radio_box.what == Ambience.playing(first)[1] and g.hud.radio_box.preset == Ambience.station and g.hud.radio_box.presets == folders and radio_hid and radio_up and radio_gone,
		"the car radio has a station for each folder (%d), each with its name, description, logo and music; tuning one in slides the radio's front up from the bottom and back down: its logo, who is playing what, and its button lit (%s / %s, button %d)" % [folders, g.hud.radio_box.who, g.hud.radio_box.what, g.hud.radio_box.preset])
	var dial: Array = g._menu_page("log_radio")["items"].filter(func(it): return it.has("logo"))
	_check(dial.size() == folders and dial.all(func(it): return it["logo"] != null and it["sub"] != "" and it["songs"] != "") and dial.filter(func(it): return it["on"]).size() == 1 and g.AGENDA.size() == 5
		and dial[Ambience.station - 1]["text"] == first["name"] and String(dial[Ambience.station - 1]["songs"]).contains(Ambience.playing(first)[1]),
		"everything else about them is on a page of the Agenda: logo, name, description and the tunes of each, the one tuned in marked (%s)" % dial[Ambience.station - 1]["text"])
	# peña graffiti
	var mine: int = g.look_sel[11]
	var each: Array = []
	for k in range(Creator.PENAS.size()):
		each.append(g.props.tags_of(k))
	var furthest := 0.0
	for t in g.props.tags:
		furthest = maxf(furthest, (t["p"] as Vector2).distance_to(g.props.TOWN))
	var firsts: Array = range(Creator.PENAS.size()).map(func(k): return g.props.tags.filter(func(t): return t["first"] == k).size())
	_check(Creator.PENAS.size() == 6 and g.props.tags.size() == 60 and firsts.all(func(n): return n == 10) and each[mine] == 0 and each.reduce(func(a, b): return a + b, 0) == 60
		and furthest < g.props.TAG_REACH + 5.0 and g.props.tags.all(func(t): return t["node"].material_override.get_shader_parameter("logo") != null),
		"each of the six peñas painted ten walls about the town, none further out than %.0f m; yours have gone to the others (nobody of yours has painted anything yet): %s" % [furthest, str(each)])
	var gap := 1e9
	for t1 in g.props.tags:
		for t2 in g.props.tags:
			if t1 != t2:
				gap = minf(gap, (t1["p"] as Vector2).distance_to(t2["p"]))
	var old_paint: bool = g.props.tags.all(func(t): return float(t["wear"]) >= 0.7 and float(t["node"].material_override.get_shader_parameter("opacity")) <= 0.9)
	_check(gap > 40.0 and old_paint, "spread out (never two within %.0f m) and old: nine tenths opaque and worn" % gap)
	g._exit_car()
	var tag: Dictionary = g.props.tags.filter(func(t): return t["owner"] != mine)[0]
	g.player.p = tag["p"]
	for n in g.npcs:                               # (nobody standing right there to be talked to instead: that would win)
		if n.p.distance_to(tag["p"]) < 4.0 and n.id == "":
			n.p = n.p + (n.p - tag["p"]).normalized() * 6.0
			n.home = n.p
	for beside in g.cars + g.traffic.list.map(func(e): return e["car"]):      # (nor a car parked or stopped beside it: "Conducir" won once)
		if is_instance_valid(beside) and beside.p.distance_to(tag["p"]) < 6.0:
			var off: Vector2 = (beside.p - tag["p"]).normalized() if beside.p.distance_to(tag["p"]) > 0.1 else Vector2(1, 0)
			beside.place(beside.p + off * 9.0, beside.h)
	var had_spray: bool = g.stats.has("chiki_tags")
	g.stats.erase("chiki_tags")
	await _frames(4)
	_check(g.near_tag == null, "before La Chiki has given you a spray, a wall is there to be seen, not painted")
	g.stats["chiki_tags"] = g.day_n
	await _frames(4)
	_check(g.near_tag == tag and g.hud.prompt.text == g.hud.as_shown(g.hud.prompt, Loc.t("p_paint")), "with her spray, standing at a rival tag offers to paint over it: %s" % g.hud.prompt.text)
	g.cam_yaw = tag["node"].rotation.y + PI
	g.cam_pitch = 0.25
	await _frames(40)
	await _shot("3d_tag_before")
	var agenda_was: Dictionary = g.folk.data.duplicate(true)     # (painting moves La Chiki's trust, and that puts her in the Agenda: not for the story's checks)
	g.interact()
	_check(tag["owner"] == mine and tag["node"].material_override.get_shader_parameter("logo") == g.props._tag_tex[mine] and float(tag["wear"]) == 0.0 and g.props.tags_owned(mine) == 1
		and (g.stats.get("painted", []) as Array).has(g.props.tags.find(tag)),
		"E paints our peña's logo over it, in fresh paint (and it is kept with the game)")
	g.stats.erase("painted")
	g.folk.data = agenda_was
	if not had_spray:
		g.stats.erase("chiki_tags")
	g.pintadas.assign(mine)
	await _frames(10)
	await _shot("3e_tag_after")
	g.cam_pitch = 0.62
	g._enter_car(c)
	g.police.reset()
	# a terraza: tables, chairs and shade all go flying
	_check(g.props.terrazas.size() >= 8, "there are terrazas around town (%d)" % g.props.terrazas.size())
	var tz: Dictionary = g.props.terrazas[4]      # (an earlier check already drove through the first one)
	var before_count: int = g.props.broken_count
	c.place(tz["p"] - tz["u"] * 11.0, atan2(tz["u"].x, tz["u"].y))
	g.cam_yaw = c.h
	await _frames(45)
	await _shot("3a_terraza")
	c.set_speed(tz["u"] * 13.0)
	for i in range(70):
		if i < 35:
			c.set_speed(tz["u"] * 13.0)
		await get_tree().physics_frame
	_check(g.props.broken_count - before_count >= 4, "driving through a terraza wrecks it (%d things)" % (g.props.broken_count - before_count))
	g.police.reset()
	# trees fall at speed
	var ti := 0
	while g.world.tree_info[ti]["down"]:
		ti += 1
	var tp: Vector2 = g.world.tree_info[ti]["p"]
	c.place(tp - Vector2(0, 7), 0.0)
	c.set_speed(Vector2(0, 14))
	await _frames(20)
	_check(g.world.tree_info[ti]["down"], "hitting a tree at speed fells it")
	# bodywork and repair
	c.repair()
	g._crash(c, 12.0)
	_check(c.hp < c.spec["hp"], "a crash damages the bodywork (%.0f / %.0f)" % [c.hp, c.spec["hp"]])
	g.money = 40
	var kerbside: Array = g.props.repairs.filter(func(r): return not r.has("garage"))
	var shop: Dictionary = kerbside[0] if not kerbside.is_empty() else {}
	if shop.is_empty():                          # (no petrol station on this map: borrow a spot in the street)
		g.props.add_repair(g._start["p"])
		shop = g.props.repairs[-1]
	c.place(shop["p"], 0.0)
	await _frames(15)
	var price: int = g.repair_price(c)
	var hurt_pc: float = (1.0 - c.hp / c.spec["hp"]) * 100.0
	_check(c.hp < c.spec["hp"] and g.money == 40 and g.at_garage and g.hud.prompt.text.contains("%d €" % price) and g.hud.prompt.text.contains(Controls.icon("horn")),
		"at a taller nothing is mended or charged yet: it shows the price and asks you to sound the horn (%s)" % g.hud.prompt.text)
	_check(price == roundi(hurt_pc / 4.0) and price > 0 and price <= 25, "the price is the percentage of damage divided by four (%.0f %% damaged: %d €)" % [hurt_pc, price])
	g.honk()
	_check(c.hp == c.spec["hp"] and g.money == 40 - price and not g.at_garage, "honk, and it is repaired for that much (money now %d)" % g.money)
	c.damage(c.spec["hp"])
	var wreck: int = g.repair_price(c)
	c.damage(-c.spec["hp"] * 0.98)
	_check(wreck == 25 and g.repair_price(c) <= 1, "a wreck costs 25 €, a scratch next to nothing")
	c.repair()
	var paid: int = g.money
	g._horn_cool = 0.0
	g.honk()
	_check(g.money == paid and InputMap.has_action("horn") and Controls.REBINDABLE.has("horn") and Loc.t("k_horn") != "k_horn", "honking again costs nothing; the horn is one more key you can reassign")
	var kb: String = Loc.t("p_out")
	Controls.pad = true
	Controls.device_changed.emit()
	var on_pad: String = Loc.t("p_out")
	Controls.pad = false
	Controls.device_changed.emit()
	_check(kb.contains("kb_" + Controls.key_name("interact") + ".png") and on_pad.contains("xb_a.png") and Loc.t("m_foot").contains("kb_Enter_") and not kb.contains("(") and not Loc.t("m_foot").contains("<"),
		"the buttons on screen are pictures of what you are holding: the key on the keyboard, (A) on a pad (%s | %s)" % [kb.get_file(), on_pad.get_file()])
	c.damage(9999.0)
	_check(c.broken(), "with no bodywork left the car is dead")
	c.repair()
	# ramp
	var ramp: Dictionary = g.props.ramps[0]
	var fwd := Vector2(sin(ramp["h"]), cos(ramp["h"]))
	c.place(ramp["p"] - fwd * 22.0, ramp["h"])
	g.cam_yaw = ramp["h"]
	await _shot("3b_ramp")
	c.place(ramp["p"] - fwd * 16.0, ramp["h"])
	var top := 0.0
	for i in range(150):
		if i < 40:
			c.set_speed(fwd * 20.0)
		await get_tree().physics_frame
		top = maxf(top, c.global_position.y - MapData.height(c.p))
	_check(top > 1.2, "a trailer parked at the kerb launches the car (%.1f m clear of the ground at the top)" % top)
	_check(c.global_transform.basis.y.y > 0.5, "and it lands the right way up")
	await _garage_checks()
	await _traffic_checks()
	# Los Pitufos
	g.police.reset()
	c.repair()
	var street := _long_street()
	var sh := atan2(street["u"].x, street["u"].y)
	c.place(street["p"] + street["u"] * 55.0, sh)
	await _frames(10)
	g.police.add_heat(250.0)
	_check(g.police.chasing and g.police.cops.is_empty(), "full heat starts the chase, and gives you a head start: nobody is here yet")
	await _frames(100)
	_check(g.police.cops.size() == 2, "three seconds later two patrol cars turn up")
	var cop = g.police.cops[0]["car"]
	var d0: float = cop.p.distance_to(c.p)
	var best := d0
	var took := 0.0
	for i in range(50 * 60):                     # (the streets are full of parked cars now: give them time to thread through)
		await get_tree().physics_frame
		took += 1.0 / 60.0
		g.police.heat = 100.0
		for e in g.police.cops:
			best = minf(best, e["car"].p.distance_to(c.p))
		if best < 30.0:
			break
	await _shot("3c_pitufos")
	_check(best < 30.0, "a patrol car finds its way to you through the streets (from %.0f m to %.0f m in %.0f s)" % [d0, best, took])
	# on sight they ram
	c.repair()
	c.place(street["p"] + street["u"] * 55.0, sh)
	cop.place(street["p"] + street["u"] * 20.0, sh)
	g.police.cops[1]["car"].place(street["p"] + street["u"] * 8.0, sh)
	var saw := false
	var hit_me := false
	var ram_t := 0.0
	for i in range(7 * 60):                      # (uphill it takes them a little longer to get there)
		await get_tree().physics_frame
		g.police.heat = 100.0
		saw = saw or g.police.seen
		hit_me = hit_me or c.hp < c.spec["hp"] or c.vel.length() > 2.0
		ram_t += 1.0 / 60.0
		if hit_me:
			break
	_check(saw, "a patrol car with a clear view sees you")
	_check(hit_me, "and rams you (bodywork %.0f / %.0f after %.1f s; the street climbs %.1f m between you)" % [c.hp, c.spec["hp"], ram_t, MapData.height(c.p) - MapData.height(street["p"] + street["u"] * 20.0)])
	# a hundred seconds without shaking them off: Los Tricornios
	_check(not g.police.elite and g.police._streak > 1.0, "they keep count of how long they have had you in sight (%.1f s)" % g.police._streak)
	g.police._streak = 99.6
	for i in range(60):
		await get_tree().physics_frame
		g.police.heat = 100.0
		g.police.bust_t = 0.0
		g.police._streak = maxf(g.police._streak, 99.6)
		if g.police.elite:
			break
	var aces: Array = g.police.cops.filter(func(e2): return e2["car"].kind == "tricornio")
	_check(g.police.elite and aces.size() == 3 and aces[0]["ace"] and aces[0]["car"].spec["max"] > CarS.SPECS["pitufo"]["max"] and g.hud.toast_label.text == Loc.t("t_tricornios"),
		"after 100 s in their sights Los Tricornios turn up: three more cars, faster than the Pitufos")
	await _frames(5)
	_check(g.hud.heat_arc.elite and g.hud.heat_arc.chasing and g.hud.heat_arc.idle == 0.0 and g.hud.heat_label.text == Loc.t("heat_elite") and Loc.rich("Los Pitufos y Los Tricornios").contains("[color=#2f6bff]Los Pitufos[/color]") and Loc.rich("Los Tricornios").contains("[color=#2f8f55]"),
		"the bar says whose turn it is; Los Pitufos are written in blue and Los Tricornios in green")
	for e2 in aces:
		g.police.cops.erase(e2)
		e2["car"].queue_free()
	g.police.elite = false
	g.police._streak = 0.0
	_check(g.props.broken_count >= 1, "patrol cars knock street furniture over too (%d things broken so far)" % g.props.broken_count)
	# pinned by them for 5 s: caught
	g.money = 40
	var caught := false
	for i in range(20 * 60):
		await get_tree().physics_frame
		if not g.police.chasing:
			caught = true
			break
		g.police.heat = 100.0
	_check(caught and g.money == 20, "pinned for 5 s: caught, half the money gone (%d €)" % g.money)
	g.money = 150
	g.busted()
	var after_150: int = g.money
	g.money = 640
	g.busted()
	_check(after_150 == 75 and g.money == 540, "caught with less than 200 € you lose half; with more, a flat 100 € (150 -> %d, 640 -> %d)" % [after_150, g.money])
	g.money = 20
	# out of their sight the meter drains and they give up
	g.police.reset()
	g.police.add_heat(250.0)
	g.police.arrive()
	var home: Dictionary = g.places["home"]
	c.place(home["p"], atan2(home["u"].x, home["u"].y))       # far across town from where they spawned
	for e in g.police.cops:
		e["car"].place(road["p"], 0.0)
		e["last_seen"] = road["p"]
	await _frames(60)
	_check(not g.police.seen and g.police.heat < 100.0, "out of sight the heat drains (%.0f)" % g.police.heat)
	for i in range(20 * 60):
		await get_tree().physics_frame
		if not g.police.chasing:
			break
	_check(not g.police.chasing and g.police.heat == 0.0 and g.police.cops.is_empty(), "at zero they give up and everything resets")
	g.police.reset()
	g.money = 0
	g.bumped = 0

## Kebab Luis's customers (clientes.gd): one in three of those who walk past comes in, queues in front of Don Luis,
## asks, sits at a free table that is not the regulars', eats for 30 to 45 seconds, sits on for 15 to 30 more and goes
## back to the street and on with their walk.
func _kebab_view(from: Vector2, high: float, at: Vector2, at_h: float, name: String, fov := 55.0) -> void:
	var K = g.kebab
	var kc := Camera3D.new()
	g.add_child(kc)
	kc.fov = fov
	var a: Vector2 = K.spot(from.x, from.y)
	var b: Vector2 = K.spot(at.x, at.y)
	kc.position = Vector3(a.x, K.base + high, a.y)
	kc.look_at(Vector3(b.x, K.base + at_h, b.y))
	kc.current = true
	await _frames(6)
	await _shot(name)
	kc.queue_free()
	g.cam.make_current()

func _kebab_checks(pictures := false) -> void:
	var K = g.kebab
	var C = g.clientes
	if g.in_car != null:
		g.in_car.set_speed(Vector2.ZERO)
		g._exit_car()
	var was_p: Vector2 = g.player.p
	g.traffic.clear()
	g.traffic._spawn_t = 99999.0
	g.player.p = K.spot(11.0, 7.0)
	await _frames(10)
	for c in C.list.duplicate():
		C._release(c)
	var hits := 0
	for i in range(6000):
		if C._roll():
			hits += 1
	_check(absf(C.odds - 0.33) < 0.001 and hits > 1800 and hits < 2160, "a neighbour walking past Kebab Luis stops one time in three (%d of 6000 throws)" % hits)
	var open: Array = C.free_seats()
	_check(K.tables.size() == 12 and K.busy >= 0 and open.size() == 44 and not open.any(func(v): return v.x == K.busy), "eleven tables are free for them: the regulars' table of the day is never offered (%d chairs)" % open.size())
	var walkers: Array = g.npcs.filter(func(n): return n.id == "" and n.walker and not n.away and n.state == "idle" and n.voice != "goat")
	var w0 = walkers[0]
	# somebody walks past and does not fancy one; then somebody does
	C.odds = 0.0
	var passed0: int = C.passed
	w0.remove_meta("kebab_seen")
	w0.p = K.spot(1.0, 0.9)
	w0.wpts = []
	await _frames(20)
	var asked_at: float = float(w0.get_meta("kebab_seen", -1.0))
	await _frames(40)
	_check(C.passed >= passed0 + 1 and not C.is_client(w0) and w0.state == "idle" and asked_at > 0.0 and float(w0.get_meta("kebab_seen", -1.0)) == asked_at, "whoever does not fancy one walks on (and is not asked again at every step)")
	# ...and from a couple of streets away, by the pavements
	var far_node = MapData.random_node_near(K.spot(11.0, 2.0), 45.0, 65.0)
	var w5 = walkers[5]
	if far_node != null:
		w5.p = g._pavement(far_node)
		w5.wpts = []
		var d5: float = w5.p.distance_to(K.spot(11.0, 1.3))
		C.come_in(w5)
		var c5: Dictionary = C.list[0]
		var worst := 0.0
		var steps5 := 0
		while c5["stage"] == "come" and steps5 < 60 * 150:
			await get_tree().physics_frame
			steps5 += 1
			if K.local(w5.p).y > 0.5:                  # (until they are in at the gate)
				worst = maxf(worst, MapData.road_edge_dist(w5.p))
		_check(c5["stage"] != "come" and worst < 6.0, "somebody %.0f m away comes round by the streets to the gate (%.0f s, never more than %.1f m off a street)" % [d5, steps5 / 60.0, worst])
		C._release(c5)
	_check(far_node != null, "(there is a street corner 45 to 65 m from the kebab to try that from)")
	C.odds = 1.0
	w0.remove_meta("kebab_seen")
	w0.p = K.spot(1.0, 0.9)
	await _frames(20)
	C.odds = 0.0
	_check(C.is_client(w0) and w0.state == "kebab" and C.stopped >= 1, "whoever does comes in through the gate")
	for c in C.list.duplicate():                   # (anybody else who happened to be about and came in too: not now)
		if c["n"] != w0:
			C._release(c)
	var c0: Dictionary = C.list[0]
	var guard := 0
	while c0["stage"] != "order" and guard < 60 * 70:
		await get_tree().physics_frame
		guard += 1
	_check(c0["stage"] == "order" and K.local(w0.p).y < K.FRONT and w0.p.distance_to(K.keeper) < 3.6, "they go indoors and up to the bar, in front of Don Luis (%.1f m from him, after %.0f s)" % [w0.p.distance_to(K.keeper), guard / 60.0])
	await _frames(40)
	_check(w0.is_barking() or g.named["luis"].is_barking(), "they ask him for something, and he has an answer ready")
	if pictures:
		await _kebab_view(Vector2(7.4, -12.4), 1.9, Vector2(11.6, -15.6), 1.2, "kebab_1_pide")
	guard = 0
	while c0["stage"] != "eat" and guard < 60 * 90:
		await get_tree().physics_frame
		guard += 1
	var sat: bool = c0["stage"] == "eat"
	_check(sat and w0.away and not w0.visible and c0["figure"] != null and c0["food"] != null and c0["table"] != K.busy, "served, they carry it to a free table and sit down to it (table %d, after %.0f s)" % [c0["table"], guard / 60.0])
	_check(sat and c0["t"] >= 29.0 and c0["t"] <= 45.0, "eating takes them between 30 and 45 seconds (%.0f s this time)" % c0["t"])
	if pictures and sat:
		var sp: Vector2 = K.seat_at(c0["table"], c0["seat"])
		var tp: Vector2 = K.table_at(c0["table"])
		var off: Vector2 = (tp - sp).normalized()
		await _kebab_view(tp + off * 2.6 + Vector2(-off.y, off.x) * 1.2, 1.7, sp, 0.9, "kebab_2_come")
	c0["t"] = 0.2
	await _frames(15)
	_check(c0["stage"] == "after" and c0["food"] == null and c0["t"] >= 14.0 and c0["t"] <= 30.0 and w0.away, "then they sit on over the empty plate for 15 to 30 seconds more (%.0f s)" % c0["t"])
	c0["t"] = 0.2
	await _frames(15)
	_check(c0["stage"] == "leave" and not w0.away and w0.visible and c0["figure"] == null, "and get up")
	var gone0: int = C.gone
	guard = 0
	while C.is_client(w0) and guard < 60 * 90:
		await get_tree().physics_frame
		guard += 1
	_check(not C.is_client(w0) and w0.state == "idle" and K.local(w0.p).y > 0.0 and C.gone == gone0 + 1 and C.free_seats().size() == 44, "they walk back out to the street (after %.0f s) and their chair is free again" % (guard / 60.0))
	g.player.p = K.spot(11.0, -6.0)                # (out of their way: nobody walks on while you stand next to them)
	await _frames(90)
	_check(not w0.wpts.is_empty() and not C.is_client(w0), "and go on with their walk")
	g.player.p = K.spot(11.0, 7.0)
	# three at once: a queue, one at the bar at a time
	var served0: int = C.served
	for k in range(3):
		var wk = walkers[1 + k]
		wk.wpts = []
		wk.p = K.spot(4.0 + k * 3.0, 0.9)
		C.come_in(wk)
	await _frames(20)
	_check(C.list.size() == 3 and C.queue.size() == 3, "three come by together and all three come in")
	var at_bar := 0
	var apart := 99.0
	var queued := false
	guard = 0
	while C.served < served0 + 3 and guard < 60 * 120:
		await get_tree().physics_frame
		guard += 1
		at_bar = maxi(at_bar, C.list.filter(func(c): return c["stage"] == "order").size())
		var waiting: Array = C.list.filter(func(c): return c["stage"] == "queue" and c["path"].is_empty())
		if C.list.any(func(c): return c["stage"] == "order") and waiting.size() == 2:
			apart = minf(apart, waiting[0]["n"].p.distance_to(waiting[1]["n"].p))
			if pictures and not queued:
				queued = true
				await _kebab_view(Vector2(7.4, -12.4), 1.9, Vector2(11.6, -15.2), 1.1, "kebab_3_cola")
	_check(C.served == served0 + 3 and at_bar == 1 and apart > 0.6 and apart < 50.0, "they queue: one at the bar at a time, the others behind (%.1f m apart), and all three are served (%.0f s)" % [apart, guard / 60.0])
	guard = 0
	while C.list.any(func(c): return c["stage"] == "go") and guard < 60 * 90:
		await get_tree().physics_frame
		guard += 1
	var chairs := {}
	for c in C.list:
		chairs[Vector2i(c["table"], c["seat"])] = true
	_check(C.list.size() == 3 and chairs.size() == 3 and C.list.all(func(c): return c["stage"] == "eat" and c["table"] != K.busy), "each on a chair of their own, none at the regulars' table")
	# the day turns and the regulars' table is now one of theirs: whoever sits there gets up
	var mine: int = C.list[0]["table"]
	var day := 1000
	while K.busy != mine and day < 3000:
		day += 1
		K.seat_day(day)
	await _frames(10)
	_check(K.busy == mine and not C.list.any(func(c): return c["table"] == mine and c["stage"] != "leave"), "when the day turns and the regulars take a table, whoever was at it gets up and goes")
	# run over on the way in: no longer a customer, and the chair is free for somebody else
	var w4 = walkers[4]
	w4.wpts = []
	w4.p = K.spot(9.0, 0.9)
	C.come_in(w4)
	await _frames(20)
	var had: bool = C.is_client(w4)
	var free_then: int = C.free_seats().size()
	w4.state = "fly"
	w4.vy = 4.0
	w4.vel = Vector2.ZERO
	await _frames(6)
	_check(had and not C.is_client(w4) and C.free_seats().size() == free_then + 1, "somebody knocked down on the way in is no longer a customer, and their chair is free")
	if pictures:                                 # a busy evening, for the picture
		for k in range(6):
			var wk = walkers[6 + k]
			wk.wpts = []
			wk.p = K.spot(2.0 + k * 3.0, 0.9)
			C.come_in(wk)
			await _frames(45)
		guard = 0
		while C.list.any(func(c): return c["stage"] != "eat" and c["stage"] != "after") and guard < 60 * 100:
			await get_tree().physics_frame
			guard += 1
			if guard == 60 * 14:
				await _kebab_view(Vector2(14.0, -0.8), 2.3, Vector2(8.5, -10.0), 1.0, "kebab_4_entran", 65.0)
		await _kebab_view(Vector2(11.0, -2.5), 2.5, Vector2(11.0, -11.0), 1.2, "kebab_5_terraza", 80.0)
		await _kebab_view(Vector2(1.0, -1.5), 3.0, Vector2(9.0, -12.0), 1.0, "kebab_6_lado", 60.0)
	# indoors you see through your own eyes; out of doors, from behind as ever
	g.player.p = K.spot(9.6, -12.8)
	g.cam_yaw = atan2(K.keeper.x - g.player.p.x, K.keeper.y - g.player.p.y)
	g.cam_pitch = 0.45
	await _frames(30)
	var head := Vector3(g.player.p.x, g.player.global_position.y + 1.5 * g.player.size, g.player.p.y)
	var to_luis: Vector3 = (MapData.at(K.keeper, 0.0) - g.cam.global_position).normalized()
	_check(g.first_person and not g.player.vis.visible and g.cam.global_position.distance_to(head) < 0.3 and (-g.cam.global_transform.basis.z).dot(to_luis) > 0.8,
		"inside the kebab house the camera is your own eyes (%.2f m from your head, looking where you look)" % g.cam.global_position.distance_to(head))
	if pictures:
		g.hud.play_ui.visible = true
		await _shot("kebab_7_dentro")
		g.hud.play_ui.visible = false
	g.player.p = K.spot(11.0, -6.0)
	await _frames(30)
	_check(not g.first_person and g.player.vis.visible and g.cam.global_position.distance_to(head) > 3.0, "and out on the terrace it is behind you again")
	g.cam_pitch = 0.62
	for c in C.list.duplicate():
		C._release(c)
	K.seat_day(int(g.day_n))
	C.odds = 0.33
	g.traffic._spawn_t = 2.0
	g.player.p = was_p

## a picture from a camera of its own (the game's goes on following you)
func _view_at(from: Vector3, at: Vector3, name: String, fov := 50.0) -> void:
	var vc := Camera3D.new()
	g.add_child(vc)
	vc.fov = fov
	vc.position = from
	vc.look_at(at)
	vc.current = true
	await _frames(6)
	await _shot(name)
	vc.queue_free()
	g.cam.make_current()

## Food (comida.gd): you can eat; the fourth meal of a day makes you a size wider; at the widest it makes you faint
## instead -- the screen swims, you reel, you go head over heels every ten seconds of walking, and after fifty
## seconds it goes black and you come to at your own door.
func _comida_checks(pictures := false) -> void:
	var F = g.comida
	if g.in_car != null:
		g.in_car.set_speed(Vector2.ZERO)
		g._exit_car()
	var was_p: Vector2 = g.player.p
	var was_look: Array = g.look_sel.duplicate()
	var was_money: int = g.money
	var was_day: int = g.day_n
	var was_weekday: int = g.weekday
	var luis_was: Array = [g.stats.get("luis_done"), g.stats.get("luis_told"), g.stats.get("menu_done")]
	g.stats["luis_done"] = g.day_n                 # (as if his errand were done and told: he goes straight to what you want to eat)
	g.stats["luis_told"] = true
	g.stats["menu_done"] = true                    # (and the restaurants known: until then they sell you nothing)
	g.weekday = 0                                  # (not a Thursday: nobody rings about hams while this goes on)
	g.traffic.clear()
	g.traffic._spawn_t = 99999.0
	g.phone_call = null
	g.hud.phone(false)
	F.reset()
	g.look_sel[F.BUILD] = F.WIDTHS[0]
	g._apply_look()
	_check(F.width() == 0 and is_equal_approx(float(g.player.look["build"]), 0.86) and F.today() == 0, "(a thin one to begin with, who has not eaten today)")
	var luis = g.named["luis"]
	var henry = g.named["henry"]
	# asking Don Luis for something to eat
	g.player.p = g.kebab.spot(11.3, -14.2)
	await _frames(5)
	g.money = 3
	g.talk_to(luis)
	_check(g.menu.visible and g.phase == "talking" and g._choice["options"].size() == 2 and not (g._choice["options"][0][1] as Callable).is_valid(), "talk to Don Luis and he asks what it will be; without %d euros there is nothing doing" % F.PRICE)
	g._choose(1)
	_check(g.dlg != null and g.phase == "free" and not g.menu.visible, "...but he will still talk")
	await _skip_dialog()
	g.money = 100
	g.talk_to(luis)
	if pictures:
		await _frames(10)
		await _shot("comida_1_pedir")
	g._choose(0)
	_check(g.money == 100 - F.PRICE and g.dlg != null and F.today() == 0, "with the money, he takes his %d euros and hands it over" % F.PRICE)
	await _skip_dialog()
	_check(F.today() == 1 and g.phase == "free", "and you eat it there and then: one meal today")
	g.player.p = henry.p + Vector2(1.2, 0.8)
	await _frames(5)
	g.talk_to(henry)
	g._choose(0)
	await _skip_dialog()
	_check(F.today() == 2 and g.money == 100 - 2 * F.PRICE, "Henry sells you a plate as well: two")
	var third: String = F.eat()
	_check(third == "three" and F.width() == 0 and F.faint == null, "three meals in a day do nothing to you (but you are told you have had three)")
	var fourth: String = F.eat()
	_check(fourth == "wider" and F.width() == 1 and is_equal_approx(float(g.player.look["build"]), 1.0) and F.faint == null, "the fourth makes you a size wider: from 0.86 to 1.0")
	_check(F.eat() == "" and F.width() == 1, "a fifth the same day changes nothing more")
	g.day_n += 1
	_check(F.today() == 0, "the count starts again with the day")
	for i in range(3):
		F.eat()
	_check(F.width() == 1 and F.eat() == "wider" and F.width() == 2 and is_equal_approx(float(g.player.look["build"]), 1.2), "four more the next day: from 1.0 to 1.2, the widest there is")
	g._save(g.save_si)
	var kept = g._load_slot(g.slot)
	_check(kept != null and int(kept["look"][F.BUILD]) == F.WIDTHS[2] and kept.has("meals") and int(kept["meals"][1]) == 4 and int(kept["meals"][0]) == g.day_n, "your girth and what you have eaten today are saved with the game")
	if pictures:
		for wdt in range(3):
			g.look_sel[F.BUILD] = F.WIDTHS[wdt]
			g._apply_look()
			g.player.h = 0.0
			g.player.sync()
			var pp3: Vector3 = g.player.global_position
			await _view_at(pp3 + Vector3(0.0, 1.2, 3.4), pp3 + Vector3(0.0, 0.95, 0.0), "comida_2_ancho_%d" % wdt, 40.0)
	g.day_n += 1
	for i in range(3):
		F.eat()
	_check(F.faint == null and F.width() == 2, "at the widest, three meals in a day are still only three meals")
	var last: String = F.eat()
	_check(last == "faint" and F.faint != null and F._rect.visible and F.width() == 2, "the fourth, at the widest: you faint")
	await _frames(100)
	_check(F.amount > 0.95 and absf(g.cam.rotation.z) < 0.2, "the screen swims like a drunk's (%.2f)" % F.amount)
	# not fit to drive
	var st: Dictionary = _long_street()
	var su: Vector2 = st["u"]
	g.player.p = st["p"] + su * 12.0
	g.paca_car.place(g.player.p + Vector2(-su.y, su.x) * 2.6, atan2(su.x, su.y))
	g.paca_car.park()
	await _frames(15)
	g.interact()
	_check(g.near_car != null and g.in_car == null, "in that state you cannot get into a car")
	g.paca_car.place(g.places["home"]["p"] + g.places["home"]["u"] * 9.0, 0.0)
	g.paca_car.park()
	await _frames(5)
	# walking: you reel, and every ten seconds of it you go over
	g.player.p = st["p"] + su * 12.0
	g.cam_yaw = atan2(su.x, su.y)
	g.player.h = g.cam_yaw
	var from: Vector2 = g.player.p
	var astray := 0.0
	var steps := 0
	var trips0: int = F.trips
	var t0: float = g.time
	for held in ["forward", "back", "left", "right", "run", "handbrake"]:
		Input.action_release(held)
	Input.action_press("forward")
	while F.trips == trips0 and steps < 60 * 14:
		await get_tree().physics_frame
		steps += 1
		g.cam_yaw = atan2(su.x, su.y)
		astray = maxf(astray, absf((g.player.p - from).dot(Vector2(-su.y, su.x))))
		if pictures and steps == 60 * 5:
			await _shot("comida_3_borracho")
			Input.action_press("forward")
	_check(F.trips == trips0 + 1 and absf(g.time - t0 - F.TRIP_EVERY) < 0.6 and F.down(), "after %.1f seconds of walking you go head over heels" % (g.time - t0))
	_check(astray > 0.5, "and meanwhile you could not walk straight (%.1f m off the line you meant to keep; dlg %s, menu %s, phase %s, paused %s, back %s)" % [astray, g.dlg != null, g.menu.visible, g.phase, g.paused, Input.is_action_pressed("back")])
	var lain: Vector2 = g.player.p
	while F.down() and F.faint["fall"] < 0.3:
		await get_tree().physics_frame
	var over: float = g.player.inner.rotation.x
	if pictures:
		g.phase = "selfshot"                       # (hold it there for the picture)
		await _shot("comida_4_tropezon")
		g.phase = "free"
	while F.down() and F.faint["fall"] < F.TUMBLE + 0.1:
		await get_tree().physics_frame
	var flat: bool = is_equal_approx(g.player.inner.rotation.x, PI / 2.0)
	var held: Vector2 = g.player.p
	await _frames(15)
	_check(over > 1.0 and flat and g.player.p.distance_to(held) < 0.05 and held.distance_to(lain) < 4.0, "over you go and flat on the ground, key held down or not")
	if pictures:
		g.phase = "selfshot"
		await _shot("comida_5_suelo")
		g.phase = "free"
	steps = 0
	while F.down() and steps < 60 * 4:
		await get_tree().physics_frame
		steps += 1
	_check(not F.down() and absf(g.player.inner.rotation.x) < 0.01, "then you get up and reel on")
	Input.action_release("forward")
	# fifty seconds of it and the lights go out
	_check(F.faint != null and F.faint["t"] > 10.0 and F.faint["t"] < F.FAINT_FOR, "(it has lasted %.0f s so far)" % F.faint["t"])
	F.faint["t"] = F.FAINT_FOR - 1.0
	await _frames(40)
	_check(F.blackout and F.faint != null, "at fifty seconds the screen goes black")
	await _frames(120)
	var centre = g.world.get("salud")
	_check(F.faint == null and not F.blackout and not F._rect.visible and g.player.p.distance_to(g.faint_spot()) < 1.0 and F.width() == 2 and g.in_car == null
		and centre != null and g.faint_spot() == centre.door and g.faint_spot().distance_to(g.home_spot) > 30.0 and MapData.room_at(g.player.p) > 0.3,
		"and you come to at the door of the health centre, out in the open, as wide as you were")
	if pictures:
		await _frames(60)
		await _shot("comida_6_centro_salud")
	g.look_sel = was_look
	g._apply_look()
	g.money = was_money
	g.day_n = was_day
	g.weekday = was_weekday
	for k in range(3):
		var key: String = ["luis_done", "luis_told", "menu_done"][k]
		if luis_was[k] == null:
			g.stats.erase(key)
		else:
			g.stats[key] = luis_was[k]
	g._refresh_counts()
	F.reset()
	g.traffic._spawn_t = 2.0
	g.player.p = was_p
	g._save(g.save_si)

## The rules every mission follows (game.gd, _offer): it can be taken or turned down -- whoever was offering it says
## something nasty and tells you to talk to them later --; the ones that come by phone ask Yes / No, and ring again
## when you finish another mission or when you ring them yourself; and with a mission under way Los Pitufos count
## every offence at half. Begins at the first step of the story, with nothing taken yet.
func _reglas_checks(pictures := false) -> void:
	var paca = g.named["paca"]
	g.police.reset()
	g.side = null
	g.recalls = []
	g.phone_call = null
	g.hud.phone(false)
	g.dlg = null
	g.hud.dlg_slot.visible = false
	if g.in_car != null:
		g.in_car.set_speed(Vector2.ZERO)
		g._exit_car()
	g.player.p = paca.p + Vector2(1.5, 0.5)
	await _frames(5)
	_check(_at("paca") and not g.in_mission() and is_equal_approx(g.heat_scale(), 1.0), "(nothing taken yet: Los Pitufos count offences in full)")
	var H = g.hud
	var plate: Control = H.map_slot.get_child(0)
	await _frames(45)                              # (whatever was being said before this has been put away by now)
	_check(H.stowed == 0.0 and plate.size.x <= 190.0 and plate.size.x >= 170.0 and is_equal_approx(H.minimap.radius, 95.0) and plate.global_position.x >= 0.0 and H.obj_box.global_position.x >= 0.0,
		"the little map is smaller than it was (%.0f px, from 226) and shows closer in (%.0f m round you, from 150)" % [plate.size.x, H.minimap.radius])
	if pictures:
		await _frames(30)
		await _shot("hud_1_jugando")
	_check(g.near_npc == paca and H.prompt.text == H.as_shown(H.prompt, Loc.t("p_talk")) and not H.prompt.text.contains(paca.shown_name()) and H.prompt.get_parsed_text().length() < 14,
		"the tag over her head says only how to talk to her: %s" % H.prompt.text)
	_check(H.toast_label.text != g._tag() and H.obj_tag.text == g._tag(), "the day is written in one place only, the calendar leaf in the corner (not on a notice as well)")
	_check(H.card_box.modulate.a < 0.05, "the mission's card is not up yet: nobody has given you the mission")
	g.folk.data.erase("paca")
	g.floats.clear()
	g.talk_to(paca)
	_check(g.dlg != null and g.dlg["lines"].size() == Loc.t("paca_intro").size(), "Tía Paca tells you about the mission")
	var up: Label3D = g.floats[0] if g.floats.size() == 1 else null
	_check(up != null and up.text == "+3" and up.position.distance_to(paca.global_position) < 4.0 and not H.toast_label.text.contains(Loc.t("t_trust").split("%s")[1].strip_edges().split(" ")[1]),
		"saying hello: the trust it earns is a +3 rising from over her head, not a line of text")
	if pictures:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://shots/hud_3_confianza.png")
	await _frames(40)
	_check(not g.arrow.visible, "(and the guide arrow is put away while she talks, with the map and the errand)")
	_check(H.stowed == 1.0 and plate.global_position.x + plate.size.x < 0.0 and H.obj_box.global_position.x + H.obj_box.size.x < 0.0 and H.dlg_slot.visible,
		"while she talks the map and the errand slide off the screen, out of the way")
	if pictures:
		g.dlg["shown"] = 999.0
		g.hud.dlg_text.visible_characters = -1
		await _shot("hud_2_dialogo")
	await _skip_dialog(false)
	var opts: Array = g._choice.get("options", [])
	_check(g.menu.visible and g._choice.get("offer", false) and opts.size() == 2 and opts[0][0] == Loc.t("offer_accept") and opts[1][0] == Loc.t("offer_reject") and _at("paca"),
		"and you are asked: Accept, or Turn it down (nothing has started yet)")
	if pictures:
		await _shot("reglas_1_aceptar")
	g._choose(1)
	var said: Array = g.dlg["lines"] if g.dlg != null else []
	_check(said == Loc.speaker(Loc.t("reject_paca"), true) and said.size() == 2 and String(said[1]).contains("luego hablas conmigo"), "turned down: she says something nasty, and to talk to her later")
	if pictures:
		g.dlg["shown"] = 999.0
		g.hud.dlg_text.visible_characters = -1
		await _shot("reglas_2_rechazo")
	await _skip_dialog(false)
	await _frames(40)
	_check(H.stowed == 0.0 and plate.global_position.x >= 0.0 and H.obj_box.global_position.x >= 0.0, "and come back when the talking is over")
	_check(_at("paca") and g._step_flag == "declined" and g.phase == "play" and not g.in_mission() and g.hud.obj_text.text == Loc.t("obj_declined") % paca.shown_name(),
		"the mission has not started, and the notebook says who to talk to when you change your mind")
	g.talk_to(paca)
	_check(g.dlg != null and g.dlg["lines"].size() == 1, "talk to her again and she asks again, without the whole speech")
	await _skip_dialog(false)
	_check(g.menu.visible and g._choice.get("offer", false), "(the same question)")
	g._choose(0)
	await _frames(5)
	_check(_at("loli") and g.in_mission() and is_equal_approx(g.heat_scale(), 0.5), "accepted: the mission is under way")
	await _frames(15)
	_check(H.card_title.text == Loc.t("m1") and H.card_box.modulate.a > 0.9 and not H.card_sub.visible, "and only now does its card go up: its title, without the day")
	if pictures:
		await _shot("hud_4_cartel")
	g.police.reset()
	g.police.add_heat(10.0)
	_check(is_equal_approx(g.police.heat, 5.0), "with a mission under way an offence worth 10 puts 5 on the meter (%.1f)" % g.police.heat)
	g.side = {"id": "x", "who": "paca", "stage": "bring", "t": 99.0, "heat": 1.0}
	g.police.add_heat(10.0)
	g.side = null
	_check(is_equal_approx(g.police.heat, 15.0), "unless that mission says otherwise (one that says 1: the whole 10)")
	g.police.reset()
	var offers: Array = g.steps.filter(func(st): return g._is_offer(st)).map(func(st): return st["id"])
	_check(offers == ["paca", "maruja", "call", "alberto"], "every mission there is begins with that question (%s)" % ", ".join(offers))
	# the graphics options: each row does something, and the defaults are the game as it always was
	_check(Settings.preset() == 2 and g.get_viewport().msaa_3d == Viewport.MSAA_4X and g.env.ssao_enabled and g.sun.shadow_enabled and is_equal_approx(g.cam.fov, 55.0) and PartsS.draw == 1.0,
		"the graphics options start at High: the game as it always was")
	_check(g._menu_page("graphics")["items"].size() == 20, "(twenty rows on the graphics page)")
	_check(g.get_viewport().use_occlusion_culling and g.occluders != null and (g.occluders.occluder as ArrayOccluder3D).vertices.size() > 20000 and is_equal_approx(g.get_viewport().mesh_lod_threshold, 2.5) and is_equal_approx(PartsS.detail, PartsS.LOD_NEAR),
		"High has occlusion culling (the town's walls hide what is behind them: %d corners) and automatic LOD on" % ((g.occluders.occluder as ArrayOccluder3D).vertices.size() if g.occluders != null else 0))
	Settings.data["lod"] = false
	Settings.data["dynres"] = true
	Settings.apply()
	_check(is_equal_approx(g.get_viewport().mesh_lod_threshold, 0.0) and is_equal_approx(PartsS.detail, 1.0) and g.get_viewport().scaling_3d_mode == Viewport.SCALING_3D_MODE_FSR,
		"LOD off draws everything at its fullest; dynamic resolution on keeps FSR ready to bring a smaller 3D up")
	var ups_seen: Array = []
	for i in range(Settings.upscalers()):
		g._step_upscale(1)
		ups_seen.append(int(Settings.data["upscale"]))
	ups_seen.sort()
	_check(ups_seen == range(Settings.upscalers()), "the spatial upscaling goes round the ways there are here (%s of Bilineal, FSR 1, FSR 2: a phone has no FSR 2)" % str(ups_seen))
	Settings.data["lod"] = true
	Settings.data["dynres"] = false
	Settings.data["upscale"] = 1
	Settings.apply()
	Settings.data["silent"] = true
	Settings.apply()
	_check(g.cam.far < 200.0 and g.env.fog_density > 0.01 and PartsS.draw < 0.5, "Modo Silent Hill: a street or two drawn (%.0f m), in a thick fog" % g.cam.far)
	Settings.data["silent"] = false
	Settings.apply()
	Settings.step_preset(-1)
	Settings.step_preset(-1)
	_check(Settings.preset() == 0 and g.sun.shadow_enabled and g.sun.directional_shadow_max_distance == 60.0 and g.get_viewport().msaa_3d == Viewport.MSAA_DISABLED
		and not g.env.ssao_enabled and not g.env.glow_enabled and g.get_viewport().scaling_3d_scale < 0.8 and PartsS.draw < 1.0 and g.traffic.max_cars < g.traffic.MAX_CARS and g.cam.far < 1000.0,
		"Low: short shadows, no anti-aliasing, no SSAO nor glow, 3D at 75 %%, a shorter draw distance and less traffic")
	var a_far := -1.0
	for n in g.find_children("*", "MeshInstance3D", true, false):
		if n.has_meta("far0") and float(n.get_meta("far0")) == 32.0:
			a_far = n.visibility_range_end
			break
	_check(is_equal_approx(a_far, 32.0 * 0.6 * PartsS.LOD_NEAR), "(and what was already built takes the shorter distance at once: %.1f m, with the LOD's)" % a_far)
	Settings.data["shadows"] = 0
	Settings.data["fx"] = 0
	Settings.apply()
	_check(not g.sun.shadow_enabled and Settings.preset() == -1 and g._menu_page("graphics")["items"][0]["value"] == Loc.t("s_custom"), "shadows off, and the quality says it has been set by hand")
	Settings.nudge("fov", 50, Settings.FOV[0], Settings.FOV[1])
	_check(is_equal_approx(g.cam.fov, 90.0), "the field of view goes up to 90 degrees and no further")
	if pictures:
		g._open_pause()
		g.menu.open("graphics")
		await _frames(10)
		await _shot("graficos_1_menu")
		g._close_pause()
	for key in ["window", "shadows", "textures", "draw", "fov", "fx", "aa", "ssao", "glow", "scale", "traffic", "dynres", "upscale", "lod", "occlusion", "silent"]:
		Settings.data[key] = {"window": 0, "fov": 55}.get(key, Settings.PRESETS[2].get(key))
	Settings.apply()
	_check(Settings.preset() == 2 and g.sun.shadow_enabled and is_equal_approx(g.cam.fov, 55.0) and PartsS.draw == 1.0 and PartsS.fx == 1.0 and g.get_viewport().scaling_3d_scale == 1.0, "and back to High, as it was")
	# the cars put away to be used again are nowhere near the town (where they were left, they were invisible walls)
	_check(g.traffic._pool.all(func(c): return not c.visible and c.p.length() > 4000.0), "the traffic's spare cars are kept out of the town, not standing invisible in its streets")
	# on a pad the stick sets the pace: no run button
	_check(g.stick_speed(0.25) < 2.0 and g.stick_speed(0.5) < 3.0 and g.stick_speed(0.85) < 4.0 and g.stick_speed(0.85) > g.stick_speed(0.5) and is_equal_approx(g.stick_speed(1.0), 9.0),
		"with a pad (or a phone's stick), how far it is pushed is how fast you go, little by little: a stroll (%.1f), a walk (%.1f), a brisk walk (%.1f), and a run only all the way (%.1f)" % [g.stick_speed(0.25), g.stick_speed(0.5), g.stick_speed(0.85), g.stick_speed(1.0)])
	# a mission's circle: two seconds inside it, not the moment you touch it
	g.dwell = 2.0
	g.begin_step(g._idx("home"))
	g.player.p = g.places["home"]["p"] + Vector2(5.0, 0.0)
	await _frames(30)
	_check(_at("home") and g._inside_t > 0.8, "walking into a mission's circle does not set it off at once (%.1f s inside)" % g._inside_t)
	g.player.p = g.places["home"]["p"] + Vector2(40.0, 0.0)
	await _frames(6)
	g.player.p = g.places["home"]["p"] + Vector2(5.0, 0.0)
	await _frames(45)
	_check(_at("home"), "step out and in again and the two seconds start over")
	await _frames(25)
	_check(not _at("home"), "stay two seconds and it counts")
	g.dwell = 0.0
	g.dlg = null
	g.hud.dlg_slot.visible = false
	# by phone: yes or no
	g.begin_step(g._idx("call"))
	await _frames(5)
	g.interact()
	await _skip_dialog(false)
	opts = g._choice.get("options", [])
	_check(g.menu.visible and g._choice.get("offer", false) and opts.size() == 2 and opts[0][0] == Loc.t("offer_si") and opts[1][0] == Loc.t("offer_no") and g.phone_call != null and g.player.phone,
		"a mission by phone: when they have finished, Yes or No (still on the line)")
	if pictures:
		await _shot("reglas_3_telefono")
	g._choose(1)
	_check(g.dlg != null and g.dlg["lines"] == Loc.speaker(Loc.t("reject_call_paca"), true), "No: you get an earful")
	await _skip_dialog(false)
	_check(_at("call") and g.phone_call == null and not g.player.phone and g.recalls.size() == 1 and not g.in_mission(), "she hangs up, and the mission has not started")
	await _frames(120)
	_check(g.phone_call == null, "she does not ring again by herself")
	g._open_pause()
	g.menu.open("log_folk")
	var ring: Array = g._menu_page("log_folk")["items"].filter(func(it): return it.has("do") and it["text"] == Loc.t("log_call_back") % paca.shown_name())
	_check(ring.size() == 1, "the Agenda's neighbours page lets you ring her back")
	if pictures:
		await _shot("reglas_4_agenda")
	if ring.size() == 1:
		ring[0]["do"].call()
	_check(not g.paused and not g.menu.visible and g.phone_call != null and g.phone_call["on"] and g.dlg != null and g.dlg["lines"].size() == 1, "you ring: she picks up and asks again, in one line")
	await _skip_dialog(false)
	_check(g.menu.visible and g._choice.get("offer", false), "(Yes or No, again)")
	g._choose(1)
	await _skip_dialog(false)
	_check(g.recalls.size() == 1 and g.phone_call == null and _at("call"), "No again: she is still owed an answer")
	g._mission_done()
	g._recall_t = 0.3
	await _frames(25)
	_check(g.phone_call != null and not g.phone_call["on"] and g.phone_call["npc"] == "paca", "finish another mission and she rings again")
	g.interact()
	await _skip_dialog(false)
	g._choose(0)
	await _frames(5)
	_check(_at("josefa") and g.recalls.is_empty() and g.phone_call == null and not g.player.phone and g.in_mission(), "Yes: the mission starts")
	# the Thursday ham, which also comes by phone
	g.stats["menu_done"] = true                # (the restaurants are known)
	g.phase = "free"
	g.weekday = 3
	g.set_time(9.0)
	g.stats.erase("thu")
	g._weekly_call()
	var caller: String = g.phone_call["npc"] if g.phone_call != null else ""
	g.interact()
	await _skip_dialog(false)
	opts = g._choice.get("options", [])
	_check(caller != "" and g.menu.visible and g._choice.get("offer", false) and opts[0][0] == Loc.t("offer_si") and g.side == null, "the Thursday call asks Yes or No as well")
	g._choose(1)
	_check(g.dlg != null and g.dlg["lines"].size() == 2, "No: whoever it is has something to say about it")
	await _skip_dialog(false)
	_check(g.side == null and g.phone_call == null and g.recalls.size() == 1 and g.recalls[0]["kind"] == "ham", "and no ham is fetched")
	g._mission_done()
	g._recall_t = 0.3
	await _frames(25)
	_check(g.phone_call != null and g.phone_call["npc"] == caller and g.phone_call.get("side", false), "finish another mission that morning and they ring again")
	g.interact()
	await _skip_dialog(false)
	g._choose(0)
	await _frames(5)
	_check(g.side != null and g.side["stage"] == "fetch" and g.recalls.is_empty() and g.police.muted, "Yes: off for the ham (and for that one Los Pitufos count nothing at all)")
	g.side = null
	g.police.muted = false
	g.hud.timer_slot.visible = false
	g.set_target(null, false)
	# said no, and rang back when the morning was over
	g.stats.erase("thu")
	g._weekly_call()
	caller = g.phone_call["npc"] if g.phone_call != null else ""
	g.interact()
	await _skip_dialog(false)
	g._choose(1)
	await _skip_dialog(false)
	g.set_time(13.0)
	_check(g.recalls.size() == 1, "(another Thursday, another no)")
	if g.recalls.size() == 1:
		g._call_back(g.recalls[0])
	_check(g.dlg != null and g.phone_call != null and g.phone_call.get("late", false), "ring them back after midday and it is too late: they have eaten")
	await _skip_dialog(false)
	_check(g.side == null and g.recalls.is_empty() and g.phone_call == null and not g.menu.visible, "and that is the end of it until next week")
	g.police.reset()

## --- Don Luis's side mission (sabotaje.gd) ---
## waits (for at most `secs` of the game's time) until the mission is at one of these stages; meanwhile, with `tail`,
## you are kept that many metres behind the lorry, as somebody following it properly would be
func _sab_until(stages: Array, secs: float, tail := 0.0) -> float:
	var S = g.sabotaje
	var n := 0
	var trail: Array = []                          # where the lorry has been: you come along the same streets
	while not (S.stage in stages) and n < int(secs * 60.0):
		await get_tree().physics_frame
		n += 1
		if tail > 0.0 and S.lorry != null and S.stage == "follow":
			var c = S.lorry["car"]
			if trail.is_empty():
				trail.append(c.p - Vector2(sin(c.h), cos(c.h)) * tail)
			if c.p.distance_to(trail[-1]) > 1.0:
				trail.append(c.p)
			var k := trail.size() - 1              # (the last place it went through that is that far from where it is now)
			while k > 0 and (trail[k] as Vector2).distance_to(c.p) < tail:
				k -= 1
			if g.player.p.distance_to(c.p) > tail + 2.0 or (trail[k] as Vector2).distance_to(c.p) >= tail:      # (if it backs towards you, you stay where you are)
				g.player.p = trail[k]
				trail = trail.slice(k)
			if OS.get_cmdline_user_args().has("--traza") and n % 60 == 0 and float(S.lorry["wait"]) > 0.5:
				var e: Dictionary = S.lorry
				print("traza t=%.0f p=%s v=%.1f goal=%.0f you=%.1f seen=%.1f blind=%.1f wait=%.1f rev=%.1f tries=%d idle=%.0f a=%d b=%d dbg=%s hw=%.1f route=%s" % [n / 60.0, c.p.round(), c.forward_speed(), c.p.distance_to(S.stop(S.stop_i)["road"]), g.player.p.distance_to(c.p), S.seen, S.blind, e["wait"], float(e.get("rev", 0.0)), int(e["tries"]), float(e.get("idle", 0.0)), e["a"], e["b"], str(e.get("dbg", "")), MapData.fitted_hw(MapData.seg_between(e["a"], e["b"])), str(e.get("route", [])).left(12)])
		if g.dlg != null and S.stage in ["cine_out", "cine_go"] and not (S.stage in stages):      # (what he says in a scene)
			await _skip_dialog(false)
	return n / 60.0

## puts the lorry in the street a little short of where it is going (so as not to drive across town every time)
func _sab_near() -> void:
	var S = g.sabotaje
	var goal: Vector2 = S.stop(S.stop_i)["road"]
	var r: Dictionary = MapData.nearest_road(goal)
	var s = r["seg"]
	var u: Vector2 = (s.b - s.a).normalized()
	var along: float = (goal - s.a).dot(u)
	var e: Dictionary = S.lorry
	if along > 26.0:
		e["a"] = s.na
		e["b"] = s.nb
		e["car"].place(s.a + u * (along - 24.0) + Vector2(-u.y, u.x) * 1.0, atan2(u.x, u.y))
	else:
		e["a"] = s.nb
		e["b"] = s.na
		e["car"].place(s.a + u * minf(along + 24.0, s.a.distance_to(s.b) - 1.0) - Vector2(-u.y, u.x) * 1.0, atan2(-u.x, -u.y))
	e["route"] = []
	e["car"].set_speed(Vector2.ZERO)

## from having failed to following the lorry again: Don Luis rings (answered or not), back to him, yes, the short scene
func _sab_again(answer: bool) -> void:
	var S = g.sabotaje
	var luis = g.named["luis"]
	var n := 0
	while g.phone_call == null and n < 60 * 8:
		await get_tree().physics_frame
		n += 1
	if answer:
		g.interact()
		await _skip_dialog(false)
	elif g.phone_call != null:
		g.phone_call["left"] = 0.1
	await _frames(20)
	g.player.p = g.kebab.spot(11.3, -14.2)
	await _frames(5)
	g.talk_to(luis)
	await _skip_dialog(false)
	if g.menu.visible:
		g._choose(0)
	await _skip_dialog(false)
	await _sab_until(["follow"], 25.0)

## at a kebab, with the boxes down and his back turned: to the boxes, and do it. Returns what the prompt said.
func _sab_do() -> String:
	var S = g.sabotaje
	if S.boxes == null:
		return ""                                  # (not there yet: the check that follows says so, rather than the script stopping)
	var bp := Vector2(S.boxes.global_position.x, S.boxes.global_position.z)
	var d: Dictionary = S.stop(S.stop_i)
	g.player.p = bp + Vector2(-d["out"].y, d["out"].x) * 1.3 - d["out"] * 0.3
	await _frames(8)
	var said: String = S.prompt() if S.can_act() else ""
	g.interact()
	return said

func _sabotaje_checks(pictures := false) -> void:
	var S = g.sabotaje
	var K = g.kebab
	var luis = g.named["luis"]
	if g.in_car != null:
		g.in_car.set_speed(Vector2.ZERO)
		g._exit_car()
	var was_p: Vector2 = g.player.p
	var was_weekday: int = g.weekday
	g.weekday = 0
	g.phone_call = null
	g.hud.phone(false)
	g.recalls = []
	g.police.reset()
	g.stats.erase("luis_done")
	g.stats.erase("luis_told")
	g.stats.erase("luis_seen")
	g.stats["menu_done"] = true                    # (the restaurants are known: that is what opens his line)
	var pc_was: int = g.pc + int(g.stats.get("pc_owed", 0))
	g.folk.data.erase("luis")
	g.comida.reset()
	var arabic: Array = Loc.t("arabe")
	_check(S.stop(0)["name"] == "Kebab Deluxe" and S.stop(1)["name"] == "Tele Durum" and S.stop(2)["name"] == "ShawarMadridejos" and S.stop(0)["road"].distance_to(S.stop(0)["door"]) < 14.0
		and S.stop(1)["road"].distance_to(S.stop(2)["road"]) > 100.0, "the three other kebab houses are on the map, each with its street in front (Kebab Deluxe, Tele Durum, ShawarMadridejos)")
	# he offers it; no; yes
	g.player.p = K.spot(11.3, -14.2)
	await _frames(5)
	g.talk_to(luis)
	_check(g.dlg != null and g.dlg["lines"] == Loc.t("luis_mision") and String(g.dlg["lines"][-1]).contains("en el amor y en kebab todo vale") and not g.folk.knows("luis"),
		"Don Luis has an errand: he is the fourth kebab in town, and all's fair in love and kebab (and no, he is not in your Agenda yet)")
	await _skip_dialog(false)
	_check(g.menu.visible and g._choice.get("offer", false) and g._choice["options"][0][0] == Loc.t("offer_accept"), "it can be taken or turned down, like any other")
	g._choose(1)
	_check(g.dlg != null and g.dlg["lines"] == Loc.speaker(Loc.t("reject_luis"), false) and String(g.dlg["lines"][1]).contains("luego hablas conmigo"), "turned down: he has something nasty to say, and to talk to him later")
	await _skip_dialog(false)
	_check(g.side == null and not S.active() and S.declined and g._step_flag == "", "nothing has started (and the main story has not been touched)")
	g.talk_to(luis)
	_check(g.menu.visible and g._choice["options"].size() == 3 and g._choice["options"][1][0] == Loc.t("food_job"), "from then on his errand is at his counter, between the kebab and the chat")
	g._choose(1)
	_check(g.dlg != null and g.dlg["lines"].size() == 1, "ask him for it and he only asks")
	await _skip_dialog(false)
	g._choose(0)
	_check(g.dlg != null and g.dlg["lines"] == Loc.t("luis_go") and g.side != null and g.side["id"] == "luis", "taken: the delivery lorry has just left his place, he says")
	await _skip_dialog(false)
	await _frames(20)
	_check(S.stage == "cine_out" and S.cine and g.cine_lock and g.cam_fixed != null and S.lorry != null and S.lorry["car"].kind == "z15" and S.man != null and K.local(S.man.p).y < 2.0
		and (S.lorry["car"].riders[0] as Dictionary).is_empty(), "a scene: the lorry is in the street at the gate and the delivery man is coming out of the kebab")
	if pictures:
		await _frames(40)
		await _shot("sab_1_sale")
	var n := 0
	while g.dlg == null and n < 60 * 15:
		await get_tree().physics_frame
		n += 1
	var line: String = g.dlg["lines"][0] if g.dlg != null else ""
	_check(line in arabic and S.man != null and S.man.p.distance_to(S.lorry["car"].p) < 4.0, "at the lorry's door he says something in \"Arabic\": %s" % line)
	if pictures and g.dlg != null:
		g.dlg["shown"] = 999.0
		g.hud.dlg_text.visible_characters = -1
		await _shot("sab_2_arabe")
	await _skip_dialog(false)
	var lp: Vector2 = S.lorry["car"].p
	_check(S.man == null and not (S.lorry["car"].riders[0] as Dictionary).is_empty(), "he gets in")
	await _sab_until(["follow"], 6.0)
	_check(S.stage == "follow" and not S.cine and not g.cine_lock and g.cam_fixed == null and S.lorry["car"].p.distance_to(lp) > 4.0, "and drives off; the scene ends and it is up to you (it has gone %.0f m)" % S.lorry["car"].p.distance_to(lp))
	_check(is_equal_approx(g.heat_scale(), 0.5), "(with this mission under way too, Los Pitufos count at half)")
	# too close
	var c = S.lorry["car"]
	n = 0
	while S.stage == "follow" and n < 60 * 16:       # (it only counts while the lorry is on the move: stuck behind something, it waits)
		await get_tree().physics_frame
		n += 1
		g.player.p = c.p - Vector2(sin(c.h), cos(c.h)) * (30.0 if n < 60 else 7.0)
	_check(S.stage == "failed" and S.lorry == null and g.side != null and g.hud.toast_label.text == Loc.t("t_sab_fail_close"), "follow it too close and he sees you: the screen says so (after %.1f s on his bumper)" % (n / 60.0 - 1.0))
	n = 0
	while g.phone_call == null and n < 60 * 8:
		await get_tree().physics_frame
		n += 1
	_check(g.phone_call != null and g.phone_call["npc"] == "luis" and not g.phone_call["on"], "and Don Luis rings")
	g.interact()
	_check(g.dlg != null and g.dlg["lines"] == Loc.t("luis_fail_call") and String(g.dlg["lines"][1]).contains("Esto no puede quedar así"), "back to the restaurant to try again: this cannot be left like this")
	await _skip_dialog(false)
	_check(S.stage == "retry" and not g.menu.visible and g.phone_call == null and g.target != null and g.target.distance_to(K.door) < 1.0 and not g.folk.knows("luis"), "(no question to answer: you are sent back to him)")
	g.player.p = K.spot(11.3, -14.2)
	await _frames(5)
	g.talk_to(luis)
	var short_1: int = g.dlg["lines"].size() if g.dlg != null else 0
	await _skip_dialog(false)
	g._choose(0)
	var short_2: int = g.dlg["lines"].size() if g.dlg != null else 0
	_check(short_1 == 1 and short_2 == 1 and short_1 + short_2 < Loc.t("luis_mision").size() + Loc.t("luis_go").size(), "the mission starts over with fewer words (two lines, where there were %d)" % (Loc.t("luis_mision").size() + Loc.t("luis_go").size()))
	await _skip_dialog(false)
	await _sab_until(["follow"], 25.0)
	_check(S.stage == "follow" and S.stop_i == 0 and S.lorry != null, "and the lorry leaves the kebab again")
	# too far
	c = S.lorry["car"]
	n = 0
	while S.stage == "follow" and n < 60 * 10:
		await get_tree().physics_frame
		n += 1
		g.player.p = c.p - Vector2(sin(c.h), cos(c.h)) * 30.0 if n < 30 else K.spot(11.0, -30.0) + Vector2(400.0, 0.0)
	_check(S.stage == "failed" and g.hud.toast_label.text == Loc.t("t_sab_fail_lost"), "let it get away and it is lost (%.1f s out of reach)" % (n / 60.0 - 0.5))
	await _sab_again(false)
	_check(S.stage == "follow", "(not picking up when he rings changes nothing: he is waiting all the same)")
	# the main story takes over: the side mission is dropped
	g._side_drop()
	_check(g.side == null and not S.active() and S.lorry == null and not g.cine_lock, "if the main story starts up, this is dropped")
	g.player.p = K.spot(11.3, -14.2)
	await _frames(5)
	g.talk_to(luis)
	g._choose(1)
	await _skip_dialog(false)
	g._choose(0)
	await _skip_dialog(false)
	await _sab_until(["follow"], 25.0)
	# all the way to the first kebab, by itself, with you behind it
	var took: float = await _sab_until(["unload", "failed"], 420.0, 32.0)
	c = S.lorry["car"] if S.lorry != null else null
	var d0: Dictionary = S.stop(0)
	_check(S.stage == "unload" and c != null and c.p.distance_to(d0["road"]) < 16.0, "followed at thirty metres, it drives across town to Kebab Deluxe and stops in front (%.0f s%s)" % [took, "" if S.stage == "unload" else ", " + g.hud.toast_label.text])
	var on_its_way: int = g.traffic.list.filter(func(e): return not e.get("auto", false) and not e.has("job") and g.traffic.is_closed(e["a"], e["b"]) and not g.sees(e["car"].p)).size()
	_check(not g.traffic.closed.is_empty() and on_its_way == 0, "its way is closed to the town's traffic while the errand lasts (%d stretches; nobody's car left on them out of sight)" % g.traffic.closed.size())
	if S.stage != "unload":
		await _sab_again(true)
		_sab_near()
		await _sab_until(["unload"], 30.0, 32.0)
	_check(S.man != null and S.boxes != null and S.boxes.get_parent() != g and (S.lorry["car"].riders[0] as Dictionary).is_empty() and S.man.is_barking(), "he gets out with two boxes in his arms, saying something")
	if pictures:
		g.player.p = S.lorry["car"].p - Vector2(sin(S.lorry["car"].h), cos(S.lorry["car"].h)) * 9.0
		g.cam_yaw = S.lorry["car"].h
		await _frames(50)
		await _shot("sab_3_descarga")
	# in front of him while he carries them: caught
	g.player.p = S.man.p + Vector2(sin(S.man.h), cos(S.man.h)) * 4.0
	n = 0
	while S.stage == "unload" and n < 60 * 3:
		await get_tree().physics_frame
		n += 1
		if S.man != null:
			g.player.p = S.man.p + Vector2(sin(S.man.h), cos(S.man.h)) * 4.0
	_check(S.stage == "failed" and g.hud.toast_label.text == Loc.t("t_sab_fail_caught"), "get in front of him while he is at it and you are caught")
	await _sab_again(true)
	_sab_near()
	g.player.p = S.lorry["car"].p - Vector2(sin(S.lorry["car"].h), cos(S.lorry["car"].h)) * 30.0
	await _sab_until(["unload"], 90.0, 30.0)          # (traffic in the way can hold it up: once a trip took half again as long)
	# behind the lorry, out of his way: he sets them down, turns round, and the thirty seconds start
	await _sab_until(["window", "failed"], 60.0)
	var bp := Vector2(S.boxes.global_position.x, S.boxes.global_position.z) if S.boxes != null else Vector2.ZERO
	_check(S.stage == "window" and S.boxes != null and S.boxes.get_parent() == g and bp.distance_to(d0["door"]) < 2.0 and S.t > 29.0 and g.hud.timer_slot.visible and not S.can_act(),
		"keep out of his sight and he leaves the two boxes at the door: thirty seconds on the clock (%.0f)" % S.t)
	await _frames(40)
	var back_turned: bool = S.man == null or absf(angle_difference(S.man.h, atan2(bp.x - S.man.p.x, bp.y - S.man.p.y))) > 1.6
	_check(back_turned, "and walks back to the lorry with his back to them")
	if pictures:
		g.player.p = bp + Vector2(-d0["out"].y, d0["out"].x) * 5.0 + d0["out"] * 1.0
		g.cam_yaw = atan2(bp.x - g.player.p.x, bp.y - g.player.p.y)
		await _frames(40)
		await _shot("sab_4_cajas")
	var said: String = await _sab_do()
	_check(said == Loc.t("p_sab_moco") and S.stage == "act" and g.cine_lock, "at the boxes, behind his back: %s" % said)
	await _sab_until(["cine_go"], 5.0)
	_check(S.stage == "cine_go" and S.cine and S.boxes.get_child_count() > 4 and not g.hud.timer_slot.visible and int(g.stats.get("luis_sab", 0)) >= 1, "done (it shows on the boxes): at once, a scene of the lorry setting off")
	n = 0
	while g.dlg == null and n < 60 * 3:
		await get_tree().physics_frame
		n += 1
	_check(g.dlg != null and g.dlg["lines"][0] in arabic and g.hud.dlg_name.text == Loc.t("n_repartidor"), "(with a word from him as he gets in)")
	if pictures:
		g.dlg["shown"] = 999.0
		g.hud.dlg_text.visible_characters = -1
		await _shot("sab_5_arranca")
	await _skip_dialog(false)
	await _sab_until(["follow"], 8.0)
	_check(S.stage == "follow" and S.stop_i == 1 and g.hud.toast_label.text == Loc.t("t_sab_car") and not S.cine, "it sets off for the next one, and you are told to get into a car, quick")
	# the second: too slow
	_sab_near()
	await _sab_until(["window", "failed"], 120.0, 30.0)
	_check(S.stage == "window" and S.stop(1)["name"] == "Tele Durum", "at Tele Durum the same again")
	S.t = 0.4
	await _frames(30)
	_check(S.stage == "failed" and g.hud.toast_label.text == Loc.t("t_sab_fail_late"), "do nothing for thirty seconds and the lorry goes, the boxes as clean as ever")
	# and now the three of them, one after another
	await _sab_again(true)
	var prompts: Array = []
	for k in range(3):
		_sab_near()
		await _sab_until(["window", "failed"], 120.0, 30.0)
		if S.stage != "window":
			break
		prompts.append(await _sab_do())
		await _sab_until(["cine_go"], 5.0)
		await _sab_until(["follow", "back"], 12.0)
	_check(prompts == [Loc.t("p_sab_moco"), Loc.t("p_sab_meo"), Loc.t("p_sab_cago")], "a bogey at the first, a piss at the second, a shit at the third (%d of 3 done)" % prompts.size())
	_check(S.stage == "back" and S.lorry == null and g.side != null and g.target != null and g.target.distance_to(K.door) < 1.0, "the third one done: back to Don Luis")
	var money0: int = g.money
	var meals0: int = g.comida.today()
	g.player.p = K.spot(11.3, -14.2)
	await _frames(5)
	g.talk_to(luis)
	_check(g.dlg != null and g.dlg["lines"] == Loc.t("luis_done"), "he is delighted")
	await _skip_dialog(false)
	_check(g.money == money0 + S.PAY and g.comida.today() == meals0 + 1 and g.side == null and not S.active() and S.done(), "the reward: %d euros and a kebab (eaten there and then)" % S.PAY)
	_check(g.folk.knows("luis") and g.folk.trust("luis") >= 10, "Don Luis is in the Agenda now")
	_check(g.traffic.closed.is_empty(), "and the lorry's streets are open to everybody again")
	_check(g.pc + int(g.stats.get("pc_owed", 0)) == pc_was + 3, "and it is worth 3 Puntos Cívicos, as a side mission is")
	g.menu.open("log_side")
	_check(g._menu_page("log_side")["items"].any(func(it): return String(it["text"]).contains(Loc.t("luis_title")) and String(it["text"]).contains(Loc.t("log_done"))), "and the mission is in it as done")
	g.menu.close()
	g.talk_to(luis)
	_check(g.menu.visible and not g._choice.get("offer", false) and g._choice["options"][0][0].begins_with(Loc.t("food_buy_luis").split("(")[0]), "and at his counter there is no errand left: a kebab or a chat")
	g._choose(1)
	await _skip_dialog(false)
	g.day_n += 1
	g.talk_to(luis)
	_check(g.dlg != null and g.dlg["lines"] == Loc.t("luis_after") and String(g.dlg["lines"][1]).contains("Nadie notó la diferencia"), "a day later he tells you it was all for nothing: nobody noticed the taste")
	await _skip_dialog(false)
	g.talk_to(luis)
	_check(g.menu.visible and g.dlg == null, "(only the once)")
	g._choose(1)
	await _skip_dialog(false)
	g.day_n -= 1
	g.weekday = was_weekday
	g.police.reset()
	g.set_target(null, false)
	g.player.p = was_p
	g._show_step()

## Heads and bodies (chara.gd, look_at_spot): a neighbour out walking who goes past you turns their head to look and
## keeps walking; the head turns as far as a neck does and no further, and not at all towards what is behind them.
func _mirada_checks(pictures := false) -> void:
	if g.in_car != null:
		g.in_car.set_speed(Vector2.ZERO)
		g._exit_car()
	var was_p: Vector2 = g.player.p
	g.traffic.clear()
	g.traffic._spawn_t = 99999.0
	var st: Dictionary = _long_street()
	var u: Vector2 = st["u"]
	var side := Vector2(-u.y, u.x)
	var w = null
	for n in g.npcs:
		if n.id == "" and n.walker and not n.away and n.state == "idle" and n.voice != "goat" and n.voice != "kid" and not g.clientes.is_client(n):
			if OS.get_cmdline_user_args().has("--viejo") and not String(n.voice).begins_with("old"):
				continue                              # (--viejo: an old one, who talks in old Manchego)
			w = n
			break
	var from: Vector2 = st["p"] + u * 20.0
	w.p = from
	w.h = atan2(u.x, u.y)
	w.wpts = [from + u * 40.0]                     # straight down the street, past you
	w.wi = 0
	w.wstuck = 0.0
	w.neck.rotation.y = 0.0
	g.player.p = from + u * 6.0 + side * 2.6       # standing by the way they will come
	var walking_for := 12                          # (seconds: long enough to have left you well behind, however slowly they walk)
	var most := 0.0
	var turned := 0.0
	var nearest := 99.0
	var shot_done := false
	var behind_neck := -1.0                        # how far the head is turned once you are well behind them
	for i in range(60 * walking_for):
		await get_tree().physics_frame
		var d: float = w.p.distance_to(g.player.p)
		nearest = minf(nearest, d)
		var to_you: Vector2 = g.player.p - w.p
		if absf(angle_difference(w.h, atan2(to_you.x, to_you.y))) > 2.4 and d > 3.0:      # (past the 2.3 a neck turns to)
			behind_neck = absf(w.neck.rotation.y)
		most = maxf(most, absf(w.neck.rotation.y))
		if d < 3.2:
			turned = maxf(turned, absf(w.neck.rotation.y))
			if pictures and not shot_done and (w.p - from).dot(u) > 4.6:
				shot_done = true
				var ahead: Vector2 = w.p + u * 4.2 + side * 0.9
				g.phase = "selfshot"
				await _view_at(MapData.at(ahead, 1.5), MapData.at(w.p, 1.1), "mirada_1_andando", 42.0)
				g.phase = "free"
	var gone: float = (w.p - from).dot(u)
	_check(nearest < 3.2 and gone > 7.0, "a neighbour walking past you does not stop: they go by at %.1f m and are %.0f m down the street %d seconds later" % [nearest, gone, walking_for])
	_check(turned > 0.5, "but their head turns to look at you as they pass (%.0f degrees)" % rad_to_deg(turned))
	_check(most <= w.NECK_TURN + 0.01 and w.NECK_TURN < PI / 2.0, "no further than a neck goes (%.0f degrees at most, of %.0f allowed)" % [rad_to_deg(most), rad_to_deg(w.NECK_TURN)])
	_check(behind_neck >= 0.0 and behind_neck < 0.15, "and once you are behind them it faces front again (%.0f degrees)" % rad_to_deg(behind_neck))
	# talk to them and they do stop, for as long as it lasts
	g.player.p = w.p + u * 1.6
	await _frames(4)
	g.talk_to(w)
	var at_talk: Vector2 = w.p
	await _frames(45)
	_check(g.dlg != null and w.p.distance_to(at_talk) < 0.2, "talk to them and they stand still to answer%s" % ("" if g.dlg != null and w.p.distance_to(at_talk) < 0.2 else
		" -- voice %s, state %s, dialogue %s, moved %.2f m" % [w.voice, w.state, "open" if g.dlg != null else "none", w.p.distance_to(at_talk)]))
	await _skip_dialog()
	g.dlg = null
	g.hud.dlg_slot.visible = false
	await _frames(60)
	_check(w.p.distance_to(at_talk) > 0.5, "and walk on when you have finished")
	# somebody with a place to keep: body and head both, as before
	var paca = g.named["paca"]
	g.player.p = paca.p + Vector2(sin(paca.h + 2.0), cos(paca.h + 2.0)) * 3.0
	await _frames(90)
	var facing: float = absf(angle_difference(paca.h + paca.neck.rotation.y, atan2(g.player.p.x - paca.p.x, g.player.p.y - paca.p.y)))
	_check(facing < 0.25 and absf(paca.neck.rotation.y) <= paca.NECK_TURN + 0.01, "whoever stands waiting for you still turns to face you (%.0f degrees off)" % rad_to_deg(facing))
	g.traffic._spawn_t = 2.0
	g.player.p = was_p

## walks you towards a spot for a while (real collisions) and says how near you got
func _walk_at(to: Vector2, secs: float) -> float:
	for i in range(int(secs * 60.0)):
		var d: Vector2 = to - g.player.p
		if d.length() < 0.3:
			break
		g.player.walk(d.normalized(), 5.0)
		await get_tree().physics_frame
	return g.player.p.distance_to(to)

## The bridge, fenced off and then unlocked. Begins at the step "puente", with the Puntos Cívicos for it in hand.
func _puente_checks(pictures := false) -> void:
	var b = g.bridge
	var cost: int = int(g.steps[g._idx("puente")]["cost"])
	var had: int = g.pc
	var end_out: Vector2 = b.p + b.across * b.open * (b.half + 1.6)        # on the pavement at its open end
	_check(_at("puente") and b.closed() and g.target != null and g.target.distance_to(b.p) < 1.0 and had >= cost, "the next thing is the bridge itself: the council has it fenced off (you have %d P.C.)" % had)
	g.player.p = end_out
	await _frames(5)
	var got: float = await _walk_at(b.p, 3.0)
	_check(got > b.half - 1.0, "and there is no walking on to it (stopped %.1f m from its middle)" % got)
	g.player.p = b.p + b.u * 5.0
	await _frames(3)
	got = await _walk_at(b.p, 3.0)
	_check(got > 1.2, "nor from the street under it (stopped %.1f m from its middle)" % got)
	g.player.p = end_out
	g.cam_yaw = atan2(b.p.x - end_out.x, b.p.y - end_out.y)
	await _frames(30)
	_check(g._can_unlock() and g.hud.prompt.text == g.hud.as_shown(g.hud.prompt, Loc.t("p_puente") % cost), "walk up to it and the button offers to unlock it for %d P.C." % cost)
	if pictures:
		await _view_at(MapData.at(b.p + b.u * 8.5 + b.across * b.open * 6.5, 3.6), MapData.at(b.p, 1.3), "civicos_3_puente_vallado", 55.0)
	g.interact()
	await _frames(10)
	_check(g.pc == had - cost and g.stats.has("puente") and not b.closed() and _at("tbc"), "pressed: the %d points are spent, the fence comes down, and the mission of the bridge is done" % cost)
	got = await _walk_at(b.p, 4.0)
	_check(got < 0.6 and absf(g.player.global_position.y - b.top) < 0.3, "and now you can walk across it (%.1f m from its middle, %.1f m up)" % [got, g.player.global_position.y - MapData.height(b.p)])
	if pictures:
		g.cam_yaw = atan2(b.across.x * -b.open, b.across.y * -b.open)
		await _frames(40)
		await _shot("civicos_4_puente_abierto")
	g.player.p = end_out

## Puntos Cívicos, the businesses you get to know and the neighbours' own lines of errands (the user's scheme of 13
## November 2026). Begins at the first step of the story.
func _civicos_checks(pictures := false) -> void:
	var josefa = g.named["josefa"]
	var henry = g.named["henry"]
	var luis = g.named["luis"]
	var alberto = g.named["alberto"]
	if g.in_car != null:
		g.in_car.set_speed(Vector2.ZERO)
		g._exit_car()
	g.traffic.clear()
	g.traffic._spawn_t = 99999.0
	g.police.reset()
	g.side = null
	g.recalls = []
	g.phone_call = null
	g.hud.phone(false)
	g.sabotaje.abort(true) if g.sabotaje.active() else null
	for key in ["menu_done", "menu_seen", "pc_on", "pc_owed", "puente", "luis_done", "luis_seen", "luis_told", "box_pc", "thu"]:
		g.stats.erase(key)
	g.pc = 0
	g.money = 50
	g.weekday = 0
	g.bridge.close_off(true)
	g._refresh_counts()
	g.comida.reset()
	await _frames(5)
	# before anybody has told you anything
	_check(_at("paca") and not g.pc_on() and not g.hud.tally[2][0].visible and not g.hud.tally[2][1].visible and g.hud.tally[0][0].visible, "the slate shows money, saffron and tags: no run-over count, and no Puntos Cívicos until somebody explains them")
	_check(not g.negocio("informatica") and not g.negocio("restaurantes"), "(you know none of the town's businesses yet)")
	g.player.p = henry.p + Vector2(1.2, 0.8)
	await _frames(5)
	g.talk_to(henry)
	_check(g.dlg != null and not g.menu.visible, "a restaurant you have not been sent to is closed to you: Henry only chats")
	await _skip_dialog()
	g.player.p = josefa.p + Vector2(1.2, 0.8)
	await _frames(5)
	g.talk_to(josefa)
	_check(g.dlg != null and g.dlg["lines"] != Loc.t("josefa_menu") and g.side == null, "and Josefa has no errands for you yet")
	await _skip_dialog()
	g.weekday = 3
	g.set_time(9.0)
	g._weekly_call()
	_check(g.phone_call == null, "(nor does anybody ring on a Thursday about a ham from a restaurant you do not know)")
	g.weekday = 0
	# after the mission of Josefa's phone: her own line of errands
	var she_says: Array = Loc.t("josefa_bridge")
	_check(String(she_says[-1]).contains("todos los negocios del pueblo") and String(she_says[-1]).contains("recados"), "at the end of the phone mission Josefa tells you she knows every business in town, and to come to her for errands")
	g.begin_step(g._idx("alberto"))
	await _frames(5)
	_check(g.negocio("informatica") and not g.negocio("restaurantes") and not g.in_mission(), "that mission done: you know the computer shops (V.I.P., so far)")
	g.talk_to(josefa)
	_check(g.dlg != null and g.dlg["lines"] == Loc.t("josefa_menu"), "and Josefa has an errand: fetch her the menu from La Cocina de Henry")
	await _skip_dialog(false)
	_check(g.menu.visible and g._choice.get("offer", false), "to take or to turn down, like any mission")
	g._choose(1)
	_check(g.dlg != null and g.dlg["lines"] == Loc.t("reject_josefa") and g._step_flag == "", "(turned down: an earful, and the main story is not touched)")
	await _skip_dialog(false)
	g.talk_to(josefa)
	await _skip_dialog(false)
	g._choose(0)
	await _frames(5)
	_check(g.side != null and g.side["id"] == "menu" and g.side["stage"] == "fetch" and g.target.distance_to(g.places["henry"]["p"]) < 1.0 and not g.hud.timer_slot.visible and not g.police.muted and is_equal_approx(g.heat_scale(), 0.5),
		"taken: to Henry's for a roast ham, with no clock running (and Los Pitufos at half, as in any mission)")
	var rioted: bool = await _riot_through()
	_check(rioted and g.side != null and g.side["stage"] == "bring", "at Henry's the ham has to be fought for (the riot: its own test), and then it is yours")
	var purse: int = g.money
	g.player.p = josefa.p + Vector2(1.5, 1.0)
	await _frames(20)
	_check(g.side == null and g.dlg != null and g.dlg["lines"] == Loc.t("josefa_menu_done") and g.money == purse + g.MENU_PAY and g.stats.has("menu_done"), "back to Josefa with it: done, and %d euros for you" % g.MENU_PAY)
	_check(g.pc == 0 and int(g.stats.get("pc_owed", 0)) == 3 and not g.hud.tally[2][0].visible, "a side mission is worth 3 Puntos Cívicos: nobody has explained them yet, so they are kept on account")
	_check(g.hud.stamp_text.text == Loc.t("stamp_done") and g.hud.stamp_box.modulate.a > 0.5 and not g.hud.toast_label.text.contains(Loc.t("mission_done")),
		"the stamp comes down, and no notice saying so as well: the stamp and the money on the slate are enough")
	g.hud.fade.modulate.a = 1.0                    # a stamp while the screen is still black (the end of a scene)...
	g.hud.stamp(Loc.t("stamp_done"))
	await _frames(10)
	var stamp_dark: float = g.hud.stamp_box.modulate.a
	g.hud.fade.modulate.a = 0.0
	await _frames(20)
	_check(stamp_dark < 0.05 and g.hud.stamp_box.modulate.a > 0.5, "...waits for the screen to clear, and then comes down")
	await _skip_dialog()
	_check(g.negocio("restaurantes") and g.hud.toast_label.text == Loc.t("t_negocio") % Loc.t("neg_restaurantes"), "and now you know the restaurants: %s" % g.hud.toast_label.text)
	g.talk_to(josefa)
	_check(g.dlg != null and g.side == null and g.dlg["lines"][0] in Loc.t("josefa_no_more"), "she has no more errands for now")
	await _skip_dialog()
	# Henry's bat is yours now: a hit is a swing of it, and whoever is in front of you goes to the ground
	var away_dir: Vector2 = (g.player.p - josefa.p).normalized()
	g.player.h = atan2(away_dir.x, away_dir.y)
	var batted = g.spawn_neighbour(g.player.p + away_dir * 1.2, true)
	await _frames(3)
	g._punch_cool = 0.0
	g._punch()
	await _frames(4)
	var bat_out: bool = g.player._bat != null and g.player._bat.visible
	await _frames(14)
	_check(g.has_bat() and bat_out and (batted.state == "fly" or batted.state == "down") and josefa.state != "fly" and josefa.state != "down",
		"with the ham delivered you keep Henry's bat: a hit draws it, swings it, and the neighbour in front goes to the ground (%s)" % batted.state)
	await _frames(20)
	_check(not g.player._bat.visible, "and the bat is put away again")
	g.npcs.erase(batted)
	batted.queue_free()
	# what knowing the restaurants opens
	g.player.p = henry.p + Vector2(1.2, 0.8)
	await _frames(5)
	g.talk_to(henry)
	_check(g.menu.visible and not g._choice.get("offer", false), "Henry sells you a plate now")
	g._choose(g._choice["options"].size() - 1)
	await _skip_dialog()
	g.player.p = g.kebab.spot(11.3, -14.2)
	await _frames(5)
	g.talk_to(luis)
	_check(g.dlg != null and g.dlg["lines"] == Loc.t("luis_mision"), "and Don Luis, whose line of missions this opens, tells you about his")
	await _skip_dialog(false)
	g._choose(1)
	await _skip_dialog(false)
	g.talk_to(luis)
	var counter: Array = g._choice.get("options", []).map(func(o): return o[0])
	_check(g.menu.visible and counter.size() == 3 and counter[1] == Loc.t("food_job"), "after that he is behind his counter: a kebab, his errand, or a chat")
	g._choose(2)
	await _skip_dialog()
	g.weekday = 3
	g.set_time(9.0)
	g.stats.erase("thu")
	g._weekly_call()
	_check(g.phone_call != null and g.phone_call.get("side", false), "and on Thursday mornings somebody rings about the ham")
	g.interact()
	await _skip_dialog()
	g._side_over(true)
	await _skip_dialog()
	_check(int(g.stats.get("pc_owed", 0)) == 6 and g.pc == 0, "a Thursday ham delivered: 3 more on account")
	g.weekday = 0
	if pictures:
		g._open_pause()
		g.menu.open("log_side")
		await _frames(10)
		await _shot("civicos_1_agenda")
		g._close_pause()
	# Alberto: the first Puntos Cívicos, and what they are for
	g.begin_step(g._idx("alberto_back"))
	g.player.p = alberto.p + Vector2(1.3, 0.8)
	await _frames(5)
	purse = g.money
	g.talk_to(alberto)
	await _skip_dialog(false)
	var lesson: Array = g.dlg["lines"] if g.dlg != null else []
	_check(lesson.size() == Loc.t("alberto_pc").size() + 2 and lesson[0] == Loc.t("alberto_pc")[0] and lesson[-2] == Loc.t("alberto_pc_owed") % 6 and lesson[-1] == Loc.t("alberto_pc_go"),
		"the signatures handed over, Alberto explains Puntos Cívicos: favours earn them, and they change the town")
	_check(g.pc_on() and g.pc == 5 + 5 + 6 and g.money == purse + 10 and g.hud.tally[2][0].visible and g.hud.tally[2][1].text == "16", "5 for your five signatures, 5 for his, and the 6 you were owed: 16 on the slate (and his ten euros)")
	if pictures:
		g.dlg["i"] = 1
		g.hud.dlg_text.text = Loc.rich(lesson[1])
		g.dlg["shown"] = 999.0
		g.hud.dlg_text.visible_characters = -1
		await _frames(30)
		await _shot("civicos_2_alberto")
	await _skip_dialog(false)
	await _puente_checks(pictures)
	_check(g.pc == 6, "(the mission of the bridge pays what Alberto gave you, and no more)")
	# from here on: 5, 3 and 1
	g.phase = "play"
	g.si = g._idx("wake")
	g._complete_step()
	_check(g.pc == 11, "from here on a main mission is worth 5")
	g.phase = "free"
	g._fight_done(true)
	g._fight_done(true)
	_check(g.pc == 12, "a minigame 1, the first time you win it each day")
	g.day_n += 1
	g._fight_done(false)
	g._fight_done(true)
	_check(g.pc == 13, "(lost: nothing; won again the next day: one more)")
	g.day_n -= 1
	g.side = {"id": "ham", "who": "paca", "stage": "bring", "t": 50.0}
	g._side_over(true)
	await _skip_dialog()
	_check(g.pc == 16, "and a side mission 3, straight on to the slate now")
	g._save(g.save_si)
	var kept = g._load_slot(g.slot)
	_check(kept != null and int(kept.get("pc", -1)) == 16 and kept["stats"].has("pc_on") and kept["stats"].has("puente") and kept["stats"].has("menu_done"), "all of it is saved with the game")
	g.traffic._spawn_t = 2.0
	g.set_target(null, false)

## --- the roast ham riot (motin.gd) ---
## walks up to the crowd, sits through the scene and lets the fight run out at once: for tests that only need the
## ham. Returns false if there was no riot to go through.
func _riot_through() -> bool:
	var M = g.motin
	g.player.p = M.centre() - M.along() * 30.0
	var n := 0
	while M.stage == "" and n < 120:
		await get_tree().physics_frame
		n += 1
	if M.stage != "wait":
		return false
	g.player.p = M.centre() - M.along() * 9.0
	n = 0
	while M.stage != "fight" and n < 60 * 30:
		await get_tree().physics_frame
		n += 1
		if g.dlg != null:
			await _skip_dialog(false)
	if M.stage != "fight":
		return false
	M.t = 0.2
	n = 0
	while M.stage == "fight" and n < 120:
		await get_tree().physics_frame
		n += 1
	await _skip_dialog(false)
	await _frames(5)
	return M.stage == ""

## The whole of it. Begins with Josefa's errand on offer (the phone mission done, restaurants not yet known).
func _motin_checks(pictures := false) -> void:
	var M = g.motin
	var henry = g.named["henry"]
	var josefa = g.named["josefa"]
	if g.in_car != null:
		g.in_car.set_speed(Vector2.ZERO)
		g._exit_car()
	g.traffic.clear()
	g.police.reset()
	g.side = null
	g.phone_call = null
	g.hud.phone(false)
	for key in ["menu_done", "menu_seen", "jamon_day", "jamon_pc", "jamon_best", "jamon_fights", "jamon_wins", "thu", "pc_owed"]:
		g.stats.erase(key)
	g.unlocked.erase("jamon")
	g.stats["pc_on"] = true
	g.pc = 0
	g.money = 0
	g.weekday = 3
	g.set_time(10.0)
	g._refresh_counts()
	if g.si != g._idx("alberto"):
		g.begin_step(g._idx("alberto"))
	g.player.p = M.centre() - M.along() * 30.0
	await _frames(30)
	_check(M.stage == "" and M.crowd.is_empty() and not M.wanted(), "before you have ever been sent for a ham there is nobody outside Henry's, Thursday or not")
	# Josefa's errand: the bat
	g.player.p = josefa.p + Vector2(1.2, 0.8)
	await _frames(5)
	g.weekday = 1
	g.talk_to(josefa)
	_check(g.dlg != null and String(g.dlg["lines"][-1]).contains("bate") and String(g.dlg["lines"][-1]).contains("costumbres"), "Josefa sends you for the menu, and \"gives\" you a bat: every town has its customs")
	await _skip_dialog()
	_check(g.side != null and g.side["id"] == "menu" and M.wanted(), "(taken, and it is not even Thursday: the first time is whenever she sends you)")
	g.player.p = M.centre() - M.along() * 30.0
	await _frames(20)
	_check(M.stage == "wait" and M.crowd.size() == M.CROWD and M.crowd.all(func(f): return f["n"].p.distance_to(M.centre()) < 12.0 and f["arm"] == null), "outside La Cocina de Henry there is a crowd: %d neighbours, all after the same ham" % M.crowd.size())
	if pictures:
		await _view_at(MapData.at(M.centre() - M.along() * 14.0, 4.5), MapData.at(M.centre(), 1.0), "motin_1_gente", 60.0)
	g.player.p = M.centre() - M.along() * 10.0
	await _frames(20)
	_check(M.stage == "cine" and g.cine_lock and g.cam_fixed != null and g.police.muted, "walk up and a scene begins (and Los Pitufos stop counting)")
	if pictures:
		await _frames(8)
		g.phase = "selfshot"
		await _shot("motin_2_plano_general")
		g.phase = "play"
	var n := 0
	while g.dlg == null and n < 60 * 5:
		await get_tree().physics_frame
		n += 1
	_check(g.dlg != null and g.dlg["lines"] == Loc.t("henry_motin") and String(g.dlg["lines"][2]).contains("lo de siempre") and g.hud.dlg_name.text == henry.shown_name(),
		"Henry comes out: too many of you, not enough hams, so it will have to be the usual")
	if pictures:
		g.dlg["shown"] = 999.0
		g.hud.dlg_text.visible_characters = -1
		await _shot("motin_3_henry")
	await _skip_dialog(false)
	await _frames(20)
	var armed: int = M.crowd.filter(func(f): return f["arm"] != null).size()
	_check(armed >= 1 and armed <= 3 and g.cam.fov < 30.0, "close shots: the weapons come out, one hand at a time (%d so far, lens at %.0f degrees)" % [armed, g.cam.fov])
	if pictures:
		await _shot("motin_4_arma")
	n = 0
	var tightest := 99.0
	var eyes_shot := false
	while g.dlg == null and n < 60 * 10:
		await get_tree().physics_frame
		n += 1
		tightest = minf(tightest, g.cam.fov)
		if pictures and not eyes_shot and g.cam.fov < 10.0:
			eyes_shot = true
			await _shot("motin_5_ojos")
	_check(tightest < 10.0 and M.crowd.filter(func(f): return f["arm"] != null).size() == 3, "then the eyes, closer and quicker, as before a duel")
	_check(g.dlg != null and g.dlg["lines"][0] == Loc.t("henry_motin_ya") and String(g.dlg["lines"][0]).contains("los que queden en pie tendrán jamón"), "\"you know how it goes: whoever is left standing gets roast ham\"")
	await _skip_dialog(false)
	await _frames(20)
	_check(M.raising and M._bat != null and g.player._hr.position.y > 1.5, "and you raise the bat")
	if pictures:
		await _shot("motin_6_bate")
	n = 0
	while M.stage != "fight" and n < 60 * 4:
		await get_tree().physics_frame
		n += 1
	await _frames(10)
	_check(M.stage == "fight" and not g.cine_lock and g.cam_fixed == null and absf(g.cam.fov - 55.0) < 0.1 and g.hud.timer_slot.visible and M.t > 59.0, "the camera comes in over your shoulder and it begins: sixty seconds")
	var behind: Vector3 = g.cam.global_position - g.player.global_position
	var facing := Vector2(sin(g.cam_yaw), cos(g.cam_yaw))
	_check(Vector2(behind.x, behind.z).dot(facing) < -2.0 and Vector2(behind.x, behind.z).dot(facing) > -4.5 and behind.y > 1.5 and behind.y < 2.8, "(%.1f m behind you and %.1f m up)" % [-Vector2(behind.x, behind.z).dot(facing), behind.y])
	_check(M.crowd.all(func(f): return f["arm"] != null and f["hp"] == 100 and f["bar"].visible) and M._standing().size() >= M.ACTIVE, "everybody armed, everybody with a hundred points over their head")
	g.police.add_heat(50.0)
	_check(g.police.heat == 0.0, "nothing you do here reaches Los Pitufos")
	await _frames(30)
	_check(M.crowd.filter(func(f): return f["target"] is String).size() == M.ON_YOU, "two of them are after you, always")
	if pictures:
		await _frames(120)
		await _shot("motin_7_pelea")
	# your bat
	M.floor_t = 0.0                                # (on your feet, and left alone for the moment)
	M.safe_t = 5.0
	g.player.inner.rotation.x = 0.0
	var mark: Dictionary = M._standing()[0]
	for f in M._standing():
		f["hp"] = 100
		f["cool"] = 3.0
		M._bar(f)
	mark["n"].p = g.player.p + Vector2(sin(g.player.h), cos(g.player.h)) * 1.1
	g._punch_cool = 0.0
	var before: int = M.score
	g._punch()
	_check(mark["hp"] == 75 and M.score >= before + M.HIT and g.player.punch > 0.0, "a blow that lands takes 25 off them and is worth %d points" % M.HIT)
	mark["hp"] = 25
	mark["n"].p = g.player.p + Vector2(sin(g.player.h), cos(g.player.h)) * 1.1
	g._punch_cool = 0.0
	before = M.score
	g._punch()
	_check(mark["down"] and mark["hp"] <= 0 and M.score >= before + M.KO and M.kos >= 1 and not mark["bar"].visible and absf(mark["n"].inner.rotation.x + PI / 2.0) < 0.01, "the one that takes them to nought lays them out, and is worth %d" % M.KO)
	# they fight one another too, and more come from the corners
	var total: int = M.crowd.size()
	for f in M._standing().slice(0, 7):
		f["down"] = true
		f["bar"].visible = false
		f["n"].inner.rotation.x = -PI / 2.0
	var low: int = M._standing().size()
	var came0: int = M.came
	n = 0
	var fewest := 99
	while n < 60 * 8:
		await get_tree().physics_frame
		n += 1
		if n > 60 * 5:
			fewest = mini(fewest, M._standing().size())
	_check(low < M.ACTIVE and M.came > came0 and fewest >= M.ACTIVE - 1 and M.crowd.size() > total, "lay enough of them out and more come running from the street corners: never fewer than ten for long (%d came; %d on their feet)" % [M.came - came0, M._standing().size()])
	_check(M.crowd.any(func(f): return not f["down"] and f["hp"] < 100) or M.crowd.filter(func(f): return f["down"]).size() > 8, "and they are hitting one another, not only you")
	# they can floor you, and it only costs you time
	M.floor_t = 0.0
	M.safe_t = 0.0
	M._floor_you()
	g._punch_cool = 0.0
	before = M.score
	g._punch()
	var lain: Vector2 = g.player.p
	Input.action_press("forward")
	await _frames(20)
	_check(M.floored() and M.score == before and g.player.p.distance_to(lain) < 0.6 and absf(g.player.inner.rotation.x) > 0.8, "knocked down, you can neither swing nor walk")
	if pictures:
		await _shot("motin_8_al_suelo")
	await _frames(45)
	Input.action_release("forward")
	_check(not M.floored() and absf(g.player.inner.rotation.x) < 0.01, "and a second and a half later you are up again, with no harm done but the time")
	g.player.p = M.centre() + M.along() * 40.0
	await _frames(5)
	_check(g.player.p.distance_to(M.centre()) <= M.RING + 0.5, "nobody leaves the street until it is over")
	# time
	var final: int = M.score
	M.t = 0.3
	await _frames(30)
	_check(M.stage == "after" and g.dlg != null and g.dlg["lines"] == Loc.t("henry_motin_fin") and String(g.dlg["lines"][1]).contains("coger aceituna") and not g.hud.timer_slot.visible,
		"time: Henry stops it and congratulates you on your way with a stick")
	await _skip_dialog(false)
	await _frames(5)
	_check(M.stage == "" and int(g.stats["jamon_best"]) == final and g.unlocked.has("jamon") and g.pc == 1 and not g.police.muted and M._bat == null, "your score is kept (%d), the minigame is in the Agenda, and it is worth 1 Punto Cívico (the first of the day)" % final)
	_check(g.side != null and g.side["stage"] == "bring", "and the ham is yours to carry")
	var purse: int = g.money
	g.player.p = josefa.p + Vector2(1.5, 1.0)
	await _frames(20)
	_check(g.side == null and g.money == purse + 20 and g.pc == 4 and g.dlg != null and String(g.dlg["lines"][1]).contains("jueves"), "taken to Josefa: 20 euros and the 3 Puntos Cívicos of a side mission; and she tells you about Thursdays")
	await _skip_dialog()
	# every Thursday from now on
	g.weekday = 1
	g.player.p = M.centre() - M.along() * 30.0
	await _frames(30)
	_check(M.stage == "" and not M.wanted(), "on any other day the street is quiet")
	g.weekday = 3
	g.day_n += 1
	g.set_time(10.0)
	await _frames(30)
	_check(M.stage == "wait" and M.crowd.size() == M.CROWD, "on Thursdays they are back, ham to fetch or not")
	var went: bool = await _riot_through()
	_check(went and g.side == null and g.pc == 5 and int(g.stats["jamon_fights"]) == 2, "walk up and it is on again, for the score and the Punto Cívico of the day")
	g.player.p = M.centre() - M.along() * 30.0
	await _frames(30)
	_check(M.stage == "" and not M.wanted(), "once a Thursday: after that they have gone home")
	# a Thursday call: no clock, the riot, twenty euros
	g.day_n += 7
	g.stats.erase("thu")
	g._weekly_call()
	var caller: String = g.phone_call["npc"] if g.phone_call != null else ""
	g.interact()
	await _skip_dialog()
	_check(g.side != null and g.side["id"] == "ham" and not g.hud.timer_slot.visible, "the Thursday call has no clock any more")
	went = await _riot_through()
	purse = g.money
	_check(went and g.side != null and g.side["stage"] == "bring" and g.police.muted, "the ham is fought for like any other Thursday's")
	g.player.p = g.named[caller].p + Vector2(1.5, 1.0) if caller != "vip" else g.player.p
	g.indoors = caller == "vip"
	await _frames(20)
	g.indoors = false
	_check(g.side == null and g.money == purse + 20, "and delivered: 20 euros")
	await _skip_dialog()
	# from the Agenda, whenever you like: no Puntos Cívicos
	var pc_was: int = g.pc
	g.weekday = 0
	var home: Vector2 = g.places["home"]["p"]
	g.player.p = home
	await _frames(10)
	g.menu.open("log_games")
	var item: Array = g._menu_page("log_games")["items"].filter(func(it): return it.has("do") and String(it["text"]).contains(Loc.t("mg_jamon")))
	_check(item.size() == 1, "the Agenda's minigames page has it")
	if item.size() == 1:
		item[0]["do"].call()
	await _frames(10)
	_check(M.stage == "cine" and M.agenda and g.player.p.distance_to(M.centre()) < 12.0, "chosen there, it starts there and then, any day of the week")
	n = 0
	while M.stage != "fight" and n < 60 * 30:
		await get_tree().physics_frame
		n += 1
		if g.dlg != null:
			await _skip_dialog(false)
	M.t = 0.2
	await _frames(30)
	await _skip_dialog(false)
	await _frames(5)
	_check(M.stage == "" and g.pc == pc_was and g.player.p.distance_to(home) < 1.0, "played from the Agenda it gives no Puntos Cívicos, and you are put back where you were")
	g.traffic._spawn_t = 2.0
	g.police.reset()

## The radio stations are on the air whether you listen or not: tune in and the song is under way; get out of the car
## and back in and it has gone on meanwhile.
## how far into its song the radio is: the player that is playing station 1's tune (-1 if none is)
func _radio_pos(A) -> float:
	var tune: AudioStream = A._radio_stream(1)
	for pl in A._players:
		if pl.playing and pl.stream == tune:
			return pl.get_playback_position()
	return -1.0

func _radio_live_checks() -> void:
	var A = Ambience
	if A.stations.is_empty():
		_check(false, "there are radio stations to listen to")
		return
	if g.in_car != null:
		g.in_car.set_speed(Vector2.ZERO)
		g._exit_car()
	A.station = 1
	g.police.reset()
	await _frames(10)
	g._enter_car(g.paca_car)                     # in the car: the radio comes on
	await _frames(40)
	var first: float = _radio_pos(A)
	var on: bool = A.current() == "radio_1"
	if first < 0.0:
		var seen: Array = []
		for pl in A._players:
			seen.append("%s playing %s vol %.0f at %.1f" % [pl.stream.resource_path.get_file() if pl.stream != null and pl.stream.resource_path != "" else str(pl.stream), pl.playing, pl.volume_db, pl.get_playback_position()])
		print("  radio: current %s, active %d, phase %s, in car %s, station %d, i %d | %s" % [A.current(), A._active, g.phase, g.in_car != null, A.station, int(A.stations[0]["i"]), " / ".join(seen)])
	g.in_car.set_speed(Vector2.ZERO)
	g._exit_car()                                # out of the car
	var away := Time.get_ticks_msec()
	await _frames(150)
	var gone: float = (Time.get_ticks_msec() - away) / 1000.0
	g._enter_car(g.paca_car)                     # and back in
	await _frames(3)
	var back: float = _radio_pos(A)
	_check(on and first >= 0.0 and back > first + gone * 0.7, "the radio is on the air all along: tuned in, the song is %.0f s under way; out of the car %.1f s and back in, it is at %.0f s" % [first, gone, back])
	# a station left long enough for its song to end: the next one, already going
	var st: Dictionary = A.stations[0]
	g.in_car.set_speed(Vector2.ZERO)
	g._exit_car()
	await _frames(3)
	var i0: int = int(st["i"])
	var long: float = A._radio_stream(1).get_length()
	st["since"] = A._now() - long - 30.0
	g._enter_car(g.paca_car)
	await _frames(3)
	var later: float = _radio_pos(A)
	_check(st["tracks"].size() == 1 or (int(st["i"]) == i0 + 1 and later > 25.0),
		"left until its song is over, the station is on the next one, already %.0f s in" % later)
	g.in_car.set_speed(Vector2.ZERO)
	g._exit_car()

## Worldbuilding in what people say (guion/palabros.md): the old neighbours have sayings of their own in the Manchego of
## their day; «apretar» is said without its diphthong; and the man whose web the words come from is in the credits.
func _palabros_checks() -> void:
	var pools_ok := true
	for k in ["generic_old", "whisper_old", "ouch_old"]:
		var e = Loc.TX.get(k)
		pools_ok = pools_ok and e != null and e["es"].size() >= 8 and e["es"].size() == e["en"].size()
	var old_lines: Array = []
	for d in Loc.speaker(Loc.t("generic_old"), false):
		old_lines.append(String(d[0]))
	var old_look: Dictionary = g._neighbour_look("old_m")
	old_look["voice_i"] = 2                                       # (NEIGHBOUR_VOICES[2]: an old man)
	var n = g.spawn_neighbour(g.player.p + Vector2(2, 0), true, old_look)
	var heard := false
	for i in range(30):
		g.dlg = null
		g.talk_to(n, true)
		if g.dlg != null and String(g.dlg["lines"][0]) in old_lines:
			heard = true
			break
	g.dlg = null
	g.hud.dlg_slot.visible = false
	g.npcs.erase(n)
	n.queue_free()
	var apriet := 0
	for k in Loc.TX:
		var es = Loc.TX[k].get("es")
		if es != null and str(es).findn("apriet") >= 0:
			apriet += 1
	_check(pools_ok and heard and apriet == 0 and str(Loc.TX["credits"]["es"]).contains("José-María Moreno García"),
		"the old neighbours have sayings of their own in old Manchego (heard: %s), nobody says «aprieta» but «apreta» (%d texts), and Moreno García is in the credits" % [heard, apriet])

## The hitch log (tirones.gd): a frame that takes too long is written down, with what was going on.
func _tirones_checks() -> void:
	var T = g.tirones
	if T == null:
		_check(false, "the hitch log is running")
		return
	var before: int = T.count
	g.prof["traffic"] = 312.0                    # (as if the traffic had taken a third of a second)
	T._process(0.6)                               # a frame of six tenths of a second
	T._since = 99.0
	T._process(0.016)
	var text := FileAccess.get_file_as_string("user://tirones.txt")
	var last: String = Array(text.strip_edges().split("
")).back()
	_check(T.count == before + 1 and last.contains("600 ms") and last.contains("traffic 312") and last.contains("shaders"),
		"a frame that takes too long is written down in tirones.txt, with what took the time: %s" % last.left(140))

## Shaders made while playing, which is what makes a frame hang the first time something new is seen (the Steam
## Machine: "tirones puntuales para luego jugar con normalidad"). A tour of a minute through what the game shows, and
## for each stretch of it: the pipelines the graphics card had to make on the spot ("draw": those stall the frame) and
## in the background, and the slowest frame.
func _pipes() -> Dictionary:
	return {"draw": Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_DRAW), "spec": Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SPECIALIZATION),
		"surface": Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SURFACE), "mesh": Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_MESH),
		"canvas": Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_CANVAS)}

var _tour_rows: Array = []
func _tour_leg(name: String, frames: int, each = null) -> void:
	var p0 := _pipes()
	var worst := 0.0
	for i in range(frames):
		if each != null:
			each.call(i)
		var t0 := Time.get_ticks_usec()
		await get_tree().process_frame
		worst = maxf(worst, (Time.get_ticks_usec() - t0) / 1000.0)
	var p1 := _pipes()
	var row := "%-22s draw %3d  spec %3d  surface %3d  mesh %3d  canvas %3d   slowest frame %6.1f ms" % [name, int(p1["draw"] - p0["draw"]), int(p1["spec"] - p0["spec"]),
		int(p1["surface"] - p0["surface"]), int(p1["mesh"] - p0["mesh"]), int(p1["canvas"] - p0["canvas"]), worst]
	_tour_rows.append(row)
	print("  tour: " + row)

func _shader_tour() -> void:
	var total0 := _pipes()
	print("  tour: after the boot so far: %s" % str(total0))
	await _tour_leg("title and menu", 60)
	g.menu.close()
	g.phase = "free"
	g.hud.play_ui.visible = true
	g.set_time(11.0)
	var plaza: Vector2 = MapData.poi("Plaza del Ayuntamiento")
	g.player.p = plaza
	await _tour_leg("on foot in the plaza", 90, func(i): g.cam_yaw += 0.03)
	g._enter_car(g.paca_car)
	var spots: Array = []
	for name in ["Molino", "Plaza del Ayuntamiento"]:
		spots.append(MapData.nearest_road(MapData.poi(name))["p"])      # (in the street by it: the mill has a wall round it now, the square a raised floor)
	for k in range(6):
		var q = MapData.random_node_near(Vector2(cos(k * 1.1), sin(k * 1.1)) * 420.0, 0.0, 120.0)
		if q != null:
			spots.append(q)
	var k := 0
	for q in spots:
		g.in_car.place(q, k * 0.9)
		k += 1
		await _tour_leg("driving %d" % k, 40, func(i): g.cam_yaw += 0.04)
	g.set_time(23.0)
	g.in_car.place(plaza, 0.3)
	await _tour_leg("night in the plaza", 90, func(i): g.cam_yaw += 0.04)
	g.set_time(11.0)
	g.police.all_out(g.player.p)
	await _tour_leg("the chase", 120)
	g.police.reset()
	Input.action_press("handbrake")
	Input.action_press("left")
	g.in_car.set_speed(Vector2(sin(g.in_car.h), cos(g.in_car.h)) * 20.0)
	await _tour_leg("a skid", 60)
	Input.action_release("handbrake")
	Input.action_release("left")
	g.map_open = true
	g.hud.bigmap.visible = true
	await _tour_leg("the big map", 30)
	g.map_open = false
	g.hud.bigmap.visible = false
	g._open_pause()
	await _tour_leg("pause menu", 30)
	g.menu.close()
	g.paused = false
	var t: Dictionary = g.props.tags[3]
	g.cam_fixed = [(t["node"] as Node3D).global_position + Vector3((t["n"] as Vector2).x, 0.3, (t["n"] as Vector2).y) * 5.0, (t["node"] as Node3D).global_position]
	await _tour_leg("a graffiti", 40)
	g.cam_fixed = null
	g.in_car.set_speed(Vector2.ZERO)
	g._exit_car()
	g._start_creator()
	await _tour_leg("the creator", 40)
	var total1 := _pipes()
	print("  tour: all of it, made while playing: draw %d, specialization %d, surface %d, mesh %d, canvas %d" % [int(total1["draw"] - total0["draw"]),
		int(total1["spec"] - total0["spec"]), int(total1["surface"] - total0["surface"]), int(total1["mesh"] - total0["mesh"]), int(total1["canvas"] - total0["canvas"])])
	if OS.get_cmdline_user_args().has("--calentar"):
		var later: int = int(total1["spec"] - total0["spec"] + total1["surface"] - total0["surface"] + total1["mesh"] - total0["mesh"] + total1["canvas"] - total0["canvas"])
		_check(total1["draw"] - total0["draw"] == 0 and later <= 6,
			"with the shaders made behind the loading screen, a minute of play makes none on the spot and only %d in the background" % later)
		print("SOMBREADORES %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])

## The edge of the map (limite.gd): past it, a red count-down to turn back; stay out and everybody comes after you,
## one more car and 5 % more speed for every thirty seconds out there.
func _limite_checks() -> void:
	var L = g.limite
	# everywhere the game sends you is well inside it (the first mission, the oil, was out of it: the user, 14 Nov 2026)
	var spots: Array = []
	for k in g.places:
		var pl = g.places[k]
		if pl is Dictionary and pl.has("p"):
			spots.append([String(k), pl["p"]])
	for r in g.props.repairs:                       # (not the people: the ones behind a counter are on sets built far off, where the edge does not count -- their doors are places)
		spots.append(["garage", r["p"]])
	for q in MapData.pois:
		spots.append([String(q["n"]), Vector2(q["x"], q["z"])])
	spots.sort_custom(func(a, b): return (a[1] as Vector2).distance_to(L.CENTRE) > (b[1] as Vector2).distance_to(L.CENTRE))
	print("limit: farthest from the middle: %s" % ", ".join(spots.slice(0, 10).map(func(s): return "%s %.0f m" % [s[0], (s[1] as Vector2).distance_to(L.CENTRE)])))
	var outs: Array = spots.filter(func(s): return (s[1] as Vector2).distance_to(L.CENTRE) > L.RADIUS - 150.0 or L.outside(s[1]))
	_check(outs.is_empty(), "every place a mission sends you to, every garage and every place on the map with a name is 150 m or more inside the edge (%s)" % ("all of them" if outs.is_empty() else ", ".join(outs.map(func(s): return "%s at %.0f m" % [s[0], (s[1] as Vector2).distance_to(L.CENTRE)]))))
	g.police.reset()
	L.reset()
	g.traffic.clear()
	if g.in_car == null:
		g._enter_car(g.paca_car)
	var c = g.in_car
	var out_at = null                               # a road a little way out of town
	for k in range(24):
		var dir := Vector2(cos(k * TAU / 24.0), sin(k * TAU / 24.0))
		var cand = MapData.random_node_near(L.CENTRE + dir * (L.RADIUS + 120.0), 0.0, 90.0)
		if cand != null and L.outside(cand) and (cand as Vector2).distance_to(L.CENTRE) < L.RADIUS + 300.0:
			out_at = cand
			break
	if out_at == null:
		_check(false, "there is a road out of town to test the edge of the map on")
		return
	var back_in = MapData.random_node_near(L.CENTRE + ((out_at as Vector2) - L.CENTRE).normalized() * (L.RADIUS - 150.0), 0.0, 150.0)
	c.place(out_at, 0.0)
	await _frames(70)
	var warned: bool = L.warning and g.hud.limit_slot.visible and not g.police.chasing and L.left < 29.5 and L.left > 26.0
	var shown: String = g.hud.limit_count.text
	await _shot("limite_aviso")
	c.place(back_in, 0.0)
	await _frames(10)
	var cleared: bool = not L.warning and not g.hud.limit_slot.visible and L.left == L.WARN
	_check(warned and cleared, "past the edge of the town a red count-down says to turn back (%s seconds left after one), and back inside it goes away" % shown)
	c.place(out_at, 0.0)                            # out again, and this time the count-down runs out (sped up)
	await _frames(5)
	L.left = 0.3
	await _frames(40)
	var kinds := {}
	for e in g.police.cops:
		kinds[e["car"].kind] = true
	_check(L.hunting and g.police.chasing and g.police.heat >= 99.0 and kinds.has("pitufo") and kinds.has("tricornio") and g.police.cops.size() >= 5,
		"stay out and everybody comes after you: the heat full, Pitufos and Tricornios at once (%d cars: %s; heat %.0f, hunting %s, chasing %s)" % [g.police.cops.size(), str(kinds.keys()), g.police.heat, str(L.hunting), str(g.police.chasing)])
	var n0: int = g.police.cops.size()
	L._more_t = 0.2
	await _frames(30)
	var boosted: bool = g.police.cops.all(func(e): return absf(float(e["car"].speed_boost) - 1.05) < 0.001)
	_check(g.police.cops.size() == n0 + 1 and absf(g.police.boost - 1.05) < 0.001 and boosted,
		"thirty seconds more out there: one more car (%d), and every one of them 5 %% faster" % g.police.cops.size())
	L._more_t = 0.2
	await _frames(30)
	_check(g.police.cops.size() == n0 + 2 and absf(g.police.boost - 1.10) < 0.001, "and thirty more: %d cars, 10 %% faster" % g.police.cops.size())
	g.police.reset()                                # (lost them)
	await _frames(3)
	_check(not L.hunting and g.police.boost == 1.0, "lose them, or be caught, and it is over")
	c.place(back_in, 0.0)
	c.set_speed(Vector2.ZERO)
	await _frames(5)

## Rollovers. Each make of car is driven hard through the town by a reckless driver: flat out along real streets,
## braking only for the sharp corners, over the bumps, kerbs and slopes there are; then held at full lock at top speed
## on a long street, and zig-zagged. Counted: how often it ends up on its side or its roof. (The user, 13 November 2026:
## "Coches vuelcan con gran facilidad, sobre todo a gran velocidad".)
const VUELCO_MAKES := ["panda", "z15", "tunero", "edison", "julietta", "grua", "tricornio", "pitufo"]

func _vuelco_run(kind: String, route: PackedVector2Array, seconds: float) -> Dictionary:
	var c = CarS.new()
	g.add_child(c)
	var to: Vector2 = route[mini(4, route.size() - 1)] - route[0]
	c.setup(kind, 0xcc3322, route[0], atan2(to.x, to.y))
	c.running = true
	await _frames(5)
	var flips := 0
	var was_flipped := false
	var worst := 1.0
	var i := 0
	var dist := 0.0
	var last: Vector2 = c.p
	var ticks := int(seconds * 60.0)
	for t in range(ticks):
		var cp: Vector2 = c.p
		var speed: float = c.forward_speed()
		var ahead: float = 7.0 + absf(speed) * 0.55
		while i < route.size() - 1 and route[i].distance_to(cp) < ahead:
			i += 1
		var aim: Vector2 = route[i]
		var diff := angle_difference(c.h, atan2(aim.x - cp.x, aim.y - cp.y))
		var thr := 1.0
		if absf(diff) > 0.55 and speed > 14.0:
			thr = -1.0                                  # (a corner: brakes, as anybody would)
		if c.flipped():
			thr = 0.0
		c.drive(thr, clampf(diff * 2.2, -1.0, 1.0), false, MapData.road_edge_dist(cp) < 1.6, 1.0 / 60.0)
		await get_tree().physics_frame
		var up_y: float = c.global_transform.basis.y.y
		worst = minf(worst, up_y)
		var now_flipped: bool = up_y < 0.35
		if now_flipped and not was_flipped:
			flips += 1
		was_flipped = now_flipped
		if now_flipped and c.flipped():                 # put back on its wheels where it lies, and drive on
			c.place(c.p, c.h)
			was_flipped = false
		dist += c.p.distance_to(last)
		last = c.p
		if i >= route.size() - 1 and cp.distance_to(route[route.size() - 1]) < 8.0:
			break
	var out := {"flips": flips, "worst": worst, "dist": dist}
	c.queue_free()
	return out

## hard cornering at top speed on a long, wide, straight street: full lock held; then a zig-zag
func _vuelco_lock(kind: String, st: Dictionary) -> Dictionary:
	var c = CarS.new()
	g.add_child(c)
	var u: Vector2 = st["u"]
	c.setup(kind, 0xcc3322, st["p"] + u * 5.0, atan2(u.x, u.y))
	c.running = true
	await _frames(5)
	var flips := 0
	var worst := 1.0
	for run in range(2):
		c.place(st["p"] + u * 5.0, atan2(u.x, u.y))
		await _frames(3)
		for t in range(150):
			var sp: float = float(c.spec["max"])
			if t < 30:
				c.set_speed(u * sp)                      # up to its top speed...
			var steer := 0.0
			if t >= 30:
				steer = 1.0 if run == 0 else (1.0 if (t / 25) % 2 == 0 else -1.0)      # ...then full lock, or a zig-zag
			c.drive(1.0, steer, false, true, 1.0 / 60.0)
			await get_tree().physics_frame
			worst = minf(worst, c.global_transform.basis.y.y)
		if c.global_transform.basis.y.y < 0.35 or worst < 0.35:
			flips += 1
		worst = minf(worst, 1.0)
	c.queue_free()
	return {"flips": flips, "worst": worst}

func _vuelcos_checks(short := false) -> void:
	if g.in_car != null:
		g.in_car.set_speed(Vector2.ZERO)
		g._exit_car()
	g.traffic.clear()
	g.traffic._spawn_t = 99999.0
	g.police.reset()
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var routes: Array = []                              # three long routes across the town
	var tries := 0
	while routes.size() < (1 if short else 3) and tries < 200:
		tries += 1
		var a = MapData.random_node_near(Vector2(rng.randf_range(-500, 500), rng.randf_range(-500, 500)), 0.0, 120.0)
		var b = MapData.random_node_near(Vector2(rng.randf_range(-500, 500), rng.randf_range(-500, 500)), 0.0, 120.0)
		if a == null or b == null or (a as Vector2).distance_to(b) < 600.0:
			continue
		var path: PackedVector2Array = MapData.path(a, b)
		if path.size() > 10:
			routes.append(path)
	var st: Dictionary = _long_street()
	g.player.p = st["p"] + Vector2(40, 40)
	var total := 0
	var lines: Array = []
	for kind in (["panda", "z15", "julietta", "tricornio"] if short else VUELCO_MAKES):      # (the full run: the light, the tall, the fast, the police)
		var town_flips := 0
		var metres := 0.0
		var worst := 1.0
		for route in routes:
			var r: Dictionary = await _vuelco_run(kind, route, 45.0 if short else 75.0)
			town_flips += int(r["flips"])
			metres += float(r["dist"])
			worst = minf(worst, float(r["worst"]))
		var lk: Dictionary = await _vuelco_lock(kind, st)
		total += town_flips + int(lk["flips"])
		lines.append("%s: %d flips in %.1f km of town, %d at full lock/zig-zag (most tilted: up %.2f / %.2f)" % [kind, town_flips, metres / 1000.0, int(lk["flips"]), worst, float(lk["worst"])])
	for l in lines:
		print("  vuelcos: " + l)
	_check(total == 0, "no make of car rolls over when driven hard: flat out through the town, full lock and zig-zag at top speed (%d rollovers)" % total)

## The switchboard (llamadas.gd): a call nobody answers is tried again an hour later; one that finds the line engaged
## waits until you hang up, rings ten minutes later and starts by having a go at you for it.
func _llamadas_checks() -> void:
	var L = g.llamadas
	L.reset()
	if g.phone_call != null:
		g._hang_up()
	if g.in_car != null:
		g.in_car.set_speed(Vector2.ZERO)
		g._exit_car()
	g.police.reset()
	await _frames(5)
	# nobody picks up
	L.ring({"npc": "paca", "say": ["Una cosa…"], "plain": true})
	var rang: bool = g.phone_call != null and g.phone_call["npc"] == "paca"
	g.phone_call["left"] = 0.05
	await _frames(10)
	var gave_up: bool = g.phone_call == null and L.pending("paca")
	var when: float = float(L.queue[0]["at"]) - L.now() if not L.queue.is_empty() else -1.0
	await _frames(5)
	var not_yet: bool = g.phone_call == null
	g.clock += 1.02
	await _frames(5)
	_check(rang and gave_up and absf(when - 1.0) < 0.05 and not_yet and g.phone_call != null and g.phone_call["npc"] == "paca",
		"a call nobody answers is tried again an hour later, game time (%.2f h)" % when)
	g._hang_up()
	L.reset()
	# the line is engaged
	L.ring({"npc": "paca", "say": ["Te cuento…"], "plain": true})
	g._answer_call()
	await _frames(2)
	L.ring({"npc": "josefa", "say": ["Lo que te quería decir."], "plain": true})
	var waiting: bool = L.pending("josefa") and g.phone_call["npc"] == "paca"
	while g.dlg != null:                                # (Paca says her piece and hangs up)
		g.dlg["cool"] = 0.0
		g.dialog_advance()
		await _frames(1)
	await _frames(3)
	var after: float = float(L.queue[0]["at"]) - L.now() if not L.queue.is_empty() else -1.0
	var quiet: bool = g.phone_call == null
	g.clock += 0.18
	await _frames(5)
	var josefa: bool = g.phone_call != null and g.phone_call["npc"] == "josefa"
	g._answer_call()
	var first: String = g.dlg["lines"][0] if g.dlg != null else ""
	var engaged_lines: Array = Loc.t("call_engaged")
	_check(waiting and quiet and absf(after - 10.0 / 60.0) < 0.02 and josefa and engaged_lines.any(func(l): return first == Loc.speaker(l, true) or first == Loc.speaker(l, false)),
		"somebody who rings while you are on the phone waits until you hang up, rings ten minutes later and opens with: %s" % first)
	while g.dlg != null:
		g.dlg["cool"] = 0.0
		g.dialog_advance()
		await _frames(1)
	L.reset()
	# a call that comes while you are talking to somebody does not cut in: it rings when you have finished
	if g.phone_call != null:
		g._hang_up()
	g.say("Paca", ["Espera, que te cuento una cosa."], "old_f")
	await _frames(2)
	L.ring({"npc": "josefa", "say": ["Ya estoy."], "plain": true})
	await _frames(3)
	var held: bool = g.phone_call == null and L.pending("josefa") and g.dlg != null
	while g.dlg != null:
		g.dlg["cool"] = 0.0
		g.dialog_advance()
		await _frames(1)
	await _frames(5)
	_check(held and g.phone_call != null and g.phone_call["npc"] == "josefa",
		"a call that comes while you are talking to somebody does not cut in: it rings as soon as you have finished")
	g._hang_up()
	L.reset()

## Who has a mission for you (marcas.gd): their photo on the map, and a green arrow over the head that is not there
## from thirty metres off and comes in as you get closer.
func _marcas_checks() -> void:
	var M = g.marcas
	if g.in_car != null:
		g.in_car.set_speed(Vector2.ZERO)
		g._exit_car()
	var josefa = g.named["josefa"]
	var had_menu: bool = g.stats.has("menu_done")
	var was_side = g.side
	g.stats.erase("menu_done")
	g.side = null
	var givers: Array = M.givers()
	var listed: bool = josefa in givers if g.negocio("informatica") else true
	if not g.negocio("informatica"):
		_check(true, "(Josefa has no errands yet at this point: the markers are checked with the Recress)")
	else:
		M._t = 0.0
		g.player.p = josefa.p + Vector2(40.0, 0.0)
		await _frames(30)
		var far_arrow = M.arrow_of(josefa)
		var far_hidden: bool = far_arrow != null and not far_arrow.visible
		g.player.p = josefa.p + Vector2(20.0, 0.0)
		await _frames(3)
		var mid_a: float = (far_arrow.material_override as StandardMaterial3D).albedo_color.a if far_arrow != null else -1.0
		g.player.p = josefa.p + Vector2(4.0, 0.0)
		await _frames(3)
		var near_a: float = (far_arrow.material_override as StandardMaterial3D).albedo_color.a if far_arrow != null else -1.0
		var on_map: bool = g.hud.minimap.givers.any(func(gv): return (gv[0] as Vector2).distance_to(josefa.p) < 0.5)
		var photo_ok: bool = M.photos.has("josefa") and M.photos["josefa"] != null
		_check(listed and far_hidden and mid_a > 0.3 and mid_a < 0.7 and near_a > 0.99 and on_map and photo_ok,
			"somebody with a mission for you is on the map with their photo in a circle, and has a green arrow over the head: not there from 40 m, half there at 20 m (%.2f), all there close to (%.2f)" % [mid_a, near_a])
	if had_menu:
		g.stats["menu_done"] = true
	g.side = was_side

## "Un torneo en los Galaxy Recress" (recress.gd), played through from Alberto's idea to the night outside. Every
## line of dialogue is skipped through as soon as it has been typed out; the scenes run at their own pace. With
## --shots, pictures at the moments that matter.
var _rec_seen := {}

## let the scenes and the talk run until it is up to you again (or `until` says so); take the pictures on the way
func _rec_play_out(pics: Dictionary, until = null, limit := 9000) -> void:
	var R = g.recress
	for i in range(limit):
		if until != null and (until as Callable).call():
			return
		if g.dlg != null:
			var line: String = g.dlg["lines"][g.dlg["i"]]
			for key in pics:
				var first = Loc.t(key)
				var first_line: String = String(first[0]) if first is Array else String(first)
				if not _rec_seen.has(key) and (line == first_line or (line.length() > 12 and first_line.begins_with(line.left(12)))):
					_rec_seen[key] = true
					await _frames(25)
					await _shot("recress_" + String(pics[key]))
			g.dlg["shown"] = 9999.0
			g.dlg["cool"] = 0.0
			g.hud.dlg_text.visible_characters = -1
			g.dialog_advance()
			await _frames(2)
			continue
		if not R.cine and not g.menu.visible and g.dlg == null:
			if until == null:
				return
		await get_tree().physics_frame

func _recress_checks() -> void:
	var R = g.recress
	var S = R.sala
	_rec_seen.clear()
	if g.in_car != null:
		g.in_car.set_speed(Vector2.ZERO)
		g._exit_car()
	g.police.reset()
	g.traffic.clear()
	g.traffic._spawn_t = 99999.0
	g.side = null
	g.stats["puente"] = true
	g.stats["puente_h"] = g.llamadas.now()
	g.stats["recress"] = {"stage": "", "posters": []}
	R.load_state()
	g.set_time(11.0)
	var alberto = g.named["alberto"]
	var mayor = g.named["alcalde"]
	var girl = g.named["copista"]
	_check(S.flen > 0.0 and not S.open and g.marcas.givers().has(alberto) and mayor != null and girl != null,
		"after the bridge Alberto has a mission for you (on the map, the arrow over his head); the mayor and the copy-shop girl are at their doors")
	if shots:
		g.cam_fixed = [MapData.at(S.shutter(11.0) + S.u * 3.0, 2.0), Vector3(S.shutter(0.0).x, S.base + 2.2, S.shutter(0.0).y)]
		await _frames(40)
		await _shot("recress_0_cerrado")
		g.cam_fixed = null
	# 0: Alberto's idea
	g.player.p = alberto.p + Vector2(1.6, 0.4)
	await _frames(4)
	g.talk_to(alberto)
	var scene_on: bool = R.cine
	await _rec_play_out({"alberto_rec_tour": "1_rincones", "alberto_rec_idea": "2_idea", "alberto_rec_recress": "3_recreativos"})
	var offered: bool = g.menu.visible and g._choice.get("title", "") == Loc.t("rec_title").to_upper()
	if offered:
		g._choose(0)
	await _frames(5)
	_check(scene_on and offered and R.stage() == "alcalde" and R.active() and g.target != null and (g.target as Vector2).distance_to(mayor.p) < 1.0,
		"Alberto's idea: the town's sad corners, a star over his head, the Galaxy Recress; taken, it sends you to the mayor (%s)" % R.stage())
	# 1: the mayor, and no money
	g.money = 10
	g.player.p = mayor.p + Vector2(1.2, 0.8)
	await _frames(4)
	g.talk_to(mayor)
	await _rec_play_out({"alcalde_rec": "4_alcalde"})
	_check(R.stage() == "dinero" and g.side == null and g.marcas.givers().has(mayor),
		"the mayor has no money, and without yours there is no tournament: he waits for you, the town is yours meanwhile, and he has the mission for you")
	g.money = 120
	g.talk_to(mayor)
	await _rec_play_out({})
	var asked_pay: bool = g.menu.visible
	if asked_pay:
		g._choose(0)
	await _rec_play_out({})
	_check(asked_pay and R.stage() == "copisteria" and g.money == 120 - R.COST and R.active(), "back with the money: you put it up (%d €), and off to the copy shop" % R.COST)
	# 2: the posters
	g.player.p = girl.p + Vector2(1.0, 0.8)
	await _frames(4)
	g.talk_to(girl)
	var marked := false
	await _frames(3)
	if g.dlg != null:
		marked = String(g.hud.dlg_text.text).contains("[color=#3fd25a]") or true
	await _rec_play_out({"copista_rec": "5_copisteria"})
	var any_green := false
	for l in Loc.t("copista_rec"):
		any_green = any_green or Loc.rich(String(l)).contains("[color=#3fd25a]")
	var any_red := false
	for l in Loc.t("copista_rec"):
		any_red = any_red or Loc.rich(String(l)).contains("[color=#e8402e]")
	print("  recress posters: stage %s carteles %s shops %d green %s red %s | %s" % [R.stage(), str(R.st.get("carteles", 0)), R.shops.size(), any_green, any_red, Loc.rich(String(Loc.t("copista_rec")[1])).left(160)])
	_check(R.stage() == "carteles" and int(R.st.get("carteles", 0)) == 5 and R.shops.size() >= 8 and any_green and any_red,
		"the copy shop gives you five posters (in green in what she says), and sends you to the shops (in red): %d shop fronts to choose from" % R.shops.size())
	var stuck := 0
	var prompt_ok := true
	for k in range(R.POSTERS):
		var sh = R._nearest_free_shop(g.player.p)
		if sh == null:
			break
		g.player.p = sh["stand"]
		await _frames(6)
		prompt_ok = prompt_ok and g.hud.prompt.text == g.hud.as_shown(g.hud.prompt, Loc.t("p_rec_poster"))
		if k == 0 and shots:
			var n: Vector2 = sh["n"]
			var at3: Vector3 = Vector3((sh["at"] as Vector2).x, sh["y"], (sh["at"] as Vector2).y)
			g.interact()
			g.player.p = (sh["stand"] as Vector2) + Vector2(-n.y, n.x) * 1.8      # (out of the picture)
			g.cam_fixed = [at3 + Vector3(n.x, 0.0, n.y) * 3.2 + Vector3(0, 0.2, 0), at3]
			await _frames(40)
			await _shot("recress_6_cartel")
			g.cam_fixed = null
		else:
			g.interact()
		await _frames(3)
		stuck += 1
	_check(stuck == 5 and prompt_ok and R.st["posters"].size() == 5 and R.stage() == "llamada",
		"five posters up, one at each of five shops (E at the front), and now to wait for Alberto")
	# 3: Alberto rings, and the tournament
	g.player.p = Vector2(100, 100)
	var rang := false
	for i in range(300):
		await get_tree().physics_frame
		if g.phone_call != null and g.phone_call["npc"] == "alberto":
			rang = true
			break
	if rang:
		g._answer_call()
	await _rec_play_out({"alberto_rec_door": "7_puerta", "com_rec_kata": "8_final", "com_rec_mayor": "9_el_alcalde", "com_rec_mayor_wins": "10_gana_el_alcalde", "alcalde_rec_challenge": "11_el_reto"},
		func(): return g.menu.visible and g._choice.get("title", "") == Loc.t("rec_bet_title").to_upper())
	var crowd_n: int = R.crowd.size()
	var inside: bool = g.indoors and g.inside_of == S
	var bet: bool = g.menu.visible
	_check(rang and inside and crowd_n >= 20 and S.screens.size() >= 9 and bet,
		"the last poster up, Alberto rings: the arcade is packed (the posters by its door); inside, %d people, the screens, the final, the mayor wins it, and his challenge" % crowd_n)
	if bet:
		g._choose(1)                                  # no: everybody has a go at you...
	await _rec_play_out({"madre_rec_shout": "12_la_madre"}, func(): return g.menu.visible)
	var asked_again: bool = g.menu.visible
	if asked_again:
		g._choose(0)                                  # ...and yes
	await _frames(5)
	_check(asked_again and R.stage() == "reto" and not R.cine and R.can_play(S.seat_you),
		"say no to his double or nothing and they will not let you: then yes, and the machine is yours to sit at")
	g.player.p = S.seat_you + Vector2(0.0, -0.6)
	await _frames(5)
	var play_prompt: bool = g.hud.prompt.text == g.hud.as_shown(g.hud.prompt, Loc.t("p_rec_play"))
	var money0: int = g.money
	g.interact()                                  # Tokken 9, against the mayor: lose one, and he offers another
	await _frames(6)
	var versus_mayor: bool = g.phase == "tokken" and g.tokken.active and String(g.tokken.opts.get("foe_tag", "")) == "DoomAssasin78"
	g.tokken.test_end(false)
	await _frames(8)
	var another: bool = not g.tokken.active and R.stage() == "reto" and g.dlg != null and g.dlg["lines"] == Loc.t("alcalde_rec_again")
	await _rec_play_out({})
	_check(versus_mayor and another and R.can_play(g.player.p), "E at the machine is a game of Tokken 9 against DoomAssasin78; lose it and he offers you another")
	g.interact()
	await _frames(6)
	g.tokken.test_end(true)
	await _rec_play_out({"alcalde_rec_lost": "13_perdio", "alcaldesa_rec_1": "14_noche", "alcaldesa_rec_3": "15_la_luna"}, func(): return R.stage() == "hecho" and not R.cine, 12000)
	await _frames(10)
	var night: bool = g.clock >= 21.5 or g.clock < 6.0
	print("  recress end: prompt %s done %s open %s money %d (want %d) indoors %s at door %.1f night %s (%.1f h) side %s" % [play_prompt, R.done(), S.open, g.money, money0 + R.COST * R.PRIZE * R.BET, g.indoors, g.player.p.distance_to(S.out_spawn), night, g.clock, str(g.side)])
	_check(play_prompt and R.done() and S.open and g.money == money0 + R.COST * R.PRIZE * R.BET and not g.indoors and g.player.p.distance_to(S.out_spawn) < 1.0 and night and g.side == null,
		"E at the machine, and you beat him (the game itself is still to come); that night his wife outside; then you at the door, the mission done: +%d €, and the Recress open" % (R.COST * R.PRIZE * R.BET))
	if shots:
		g.set_time(21.0)
		g.cam_fixed = [MapData.at(S.shutter(11.0) + S.u * 3.0, 2.0), Vector3(S.shutter(0.0).x, S.base + 2.2, S.shutter(0.0).y)]
		await _frames(40)
		await _shot("recress_16_abierto")
		g.cam_fixed = null
	# the Recress open: in through the door, and out
	g.player.p = S.door_out + S.out * 1.0
	g.player.h = atan2(-S.out.x, -S.out.y)
	g._door_cool = 0.0
	for i in range(60):
		Input.action_press("forward")
		await get_tree().physics_frame
		if g.indoors:
			break
	Input.action_release("forward")
	await _frames(5)
	var went_in: bool = g.indoors and g.inside_of == S
	if shots and went_in:
		await _frames(30)
		await _shot("recress_17_dentro")
	g._use_door(false, S)
	await _frames(5)
	_check(went_in and not g.indoors and g.player.p.distance_to(S.out_spawn) < 0.5, "the Recress is open: in through its door and out again")
	# with the Recress open, the big machine is a game against Katakumba69, and a game with him counts with him
	var kata = g.named.get("katakumba")
	var folk_was: Dictionary = g.folk.data.duplicate(true)
	g.indoors = true
	g.inside_of = S
	g.player.p = S.seat_you + Vector2(0.0, -0.4)
	await _frames(4)
	var trust0: int = g.folk.trust("katakumba")
	var free_prompt: bool = g.hud.prompt.text == g.hud.as_shown(g.hud.prompt, Loc.t("p_rec_play"))
	g.interact()
	await _frames(6)
	var versus_kata: bool = g.tokken.active and String(g.tokken.opts.get("foe_tag", "")) == "Katakumba69"
	g.tokken.test_end(false)
	await _frames(8)
	_check(free_prompt and versus_kata and not g.tokken.active and g.folk.trust("katakumba") == trust0 + 5,
		"the Recress open: the big machine is a game against Katakumba69, and playing him counts with him (+%d)" % (g.folk.trust("katakumba") - trust0))
	g._use_door(false, S)
	await _frames(4)
	# Katakumba69, at full trust, tells you his real name: the once
	var told := ""
	var then := ""
	if kata != null:
		g.stats.erase("nachin")
		g.folk.add("katakumba", 100)
		for k in range(2):
			g.talk_to(kata)
			var first: String = String(g.dlg["lines"][0]) if g.dlg != null else ""
			if k == 0:
				told = first
			else:
				then = first
			while g.dlg != null:
				g.dlg["cool"] = 0.0
				g.dialog_advance()
				await _frames(1)
	g.folk.data = folk_was
	_check(told == Loc.t("katakumba_nachin")[0] and then != "" and then != told,
		"Katakumba69 at full trust tells you his real name (Ignacio José Gómez-Carreño de la Llave, Nachín to his friends online), and only the once")
	# its hours: shut in the morning, open from the afternoon; closing time with you inside, it waits for you to come out
	g.set_time(10.0)
	await _frames(5)
	var shut_morning: bool = S.state == "cerrado" and not S.open
	g.set_time(17.0)
	await _frames(5)
	var open_afternoon: bool = S.state == "abierto" and S.open
	g._use_door(true, S)
	await _frames(5)
	g.set_time(10.0)
	await _frames(5)
	var waits: bool = g.indoors and S.state == "abierto"
	g._use_door(false, S)
	await _frames(5)
	var shut_after: bool = not g.indoors and S.state == "cerrado"
	g.set_time(21.0)
	await _frames(3)
	_check(shut_morning and open_afternoon and waits and shut_after,
		"the Recress keeps its hours: shut in the morning (%s), open from the afternoon (%s), and at closing time with you inside it waits for you to come out (%s, then %s)" % [shut_morning, open_afternoon, waits, shut_after])

## Tokken 9 (tokken.gd), the fighting game on the Recress's machines. The test plays for you against a machine's player
## that stands still, so that what each thing does is known; then the machine plays itself (without a screen, in no
## time) to see how hard the mayor is for somebody who has never played and for somebody who has found the combo.
func _tokken_checks(matches := 12) -> void:
	var T = g.tokken
	var phase_was: String = g.phase
	if g.in_car != null:
		g.in_car.set_speed(Vector2.ZERO)
		g._exit_car()
	var tick := func(n: int):
		for i in range(n):
			await get_tree().physics_frame
	var snap := func(name: String):
		T.hold = true
		await _shot(name)
		T.hold = false
	var ended: Array = []
	T.start({"foe": "monstruo", "foe_tag": "DoomAssasin78", "ai": "alcalde"}, func(w): ended.append(w))
	await tick.call(20)
	var opened: bool = g.phase == "tokken" and T.active and T.mode == "select" and T.touch_buttons().size() == 1
	T.pick = 3
	await snap.call("tokken_1_elegir")
	T.pick = 0
	T._pressed["right"] = true
	await tick.call(2)
	var moved: bool = T.pick == 1
	T._pressed["ok"] = true
	await tick.call(3)
	var versus: bool = T.mode == "versus" and T.a != null and T.a.id == "napoleon" and T.b.id == "monstruo" and T.stage_n == 3
	await tick.call(50)
	await snap.call("tokken_2_versus")
	for i in range(700):
		if T.mode == "fight":
			break
		await get_tree().physics_frame
	var buttons: Array = T.touch_buttons().map(func(b): return b[1])
	_check(opened and moved and versus and T.mode == "fight" and T.clock == 99 and buttons == ["punch", "interact", "handbrake", "pause"],
		"Tokken 9 takes the screen: choose a fighter, the two of them face to face, and round one (on a touch screen: %s)" % str(buttons))
	var A = T.a
	var B = T.b
	var still: Dictionary = T.AI["quieto"]
	var wall: Dictionary = still.duplicate()        # covers up from everything
	wall["guard"] = 1.0
	wall["string"] = 1.0
	wall["react"] = 0
	var old_school: Dictionary = wall.duplicate()   # covers up from the first blow, and thinks that was it
	old_school["string"] = 0.0
	T.test_inp = {"dir": 0, "up": false, "light": false, "heavy": false, "special": false}
	var place := func(gap: float, how: Dictionary):
		B.ai["p"] = how
		B.ai["seen"] = 0
		B.ai["struck"] = 0
		A.x = 600.0
		B.x = 600.0 + A.half + B.half + gap
		A.face = 1
		B.face = -1
		T._to_idle(A)
		T._to_idle(B)
		A.hp = 100.0
		B.hp = 100.0
		B.hp_shown = 100.0
		B.guard = 100.0
		B.inv = 0
		A.meter = 0.0
		A.combo_n = 0
		T.shots.clear()
		T.clock = 99
	# the quick blow
	place.call(30.0, still)
	await tick.call(2)
	T.test_inp["light"] = true
	var hurt := false
	for i in range(34):
		await get_tree().physics_frame
		hurt = hurt or B.st == "hurt"
	var d1: float = 100.0 - B.hp
	_check(hurt and d1 > 4.0 and d1 < 8.0, "the quick blow lands (%.1f of their 100)" % d1)
	# the cancel: quick, and the strong one pressed at once
	place.call(30.0, still)
	await tick.call(2)
	T.test_inp["light"] = true
	await tick.call(3)
	T.test_inp["heavy"] = true
	var most := 0
	var pic := false
	for i in range(80):
		await get_tree().physics_frame
		most = maxi(most, A.combo_n)
		if shots and not pic and A.combo_n == 2:
			pic = true
			await snap.call("tokken_3_combo")
	var d2: float = 100.0 - B.hp
	_check(most == 2 and d2 > d1 + 8.0, "quick and the strong one at once: the second lands before they can do a thing, a combo of %d (%.1f)" % [most, d2])
	# covering up
	place.call(30.0, wall)
	await tick.call(2)
	T.test_inp["heavy"] = true
	var blocked := false
	for i in range(60):
		await get_tree().physics_frame
		blocked = blocked or B.st == "block"
	_check(blocked and B.hp == 100.0 and B.guard < 100.0, "a blow they see coming they cover up from: it does not hurt, but it wears the guard down (%.0f left)" % B.guard)
	# and what the mayor never learnt
	place.call(30.0, old_school)
	await tick.call(2)
	T.test_inp["light"] = true
	await tick.call(3)
	T.test_inp["heavy"] = true
	var first_covered := false
	var then_hit := false
	for i in range(80):
		await get_tree().physics_frame
		first_covered = first_covered or B.st == "block"
		then_hit = then_hit or (first_covered and B.st == "hurt")
	_check(first_covered and then_hit and B.hp < 100.0, "somebody who plays as in the eighties covers the quick blow and takes the strong one cancelled out of it (%.1f)" % (100.0 - B.hp))
	# the power
	place.call(190.0, still)
	await tick.call(2)
	var no_power_yet: bool = true
	T.test_inp["special"] = true
	await tick.call(20)
	no_power_yet = A.st == "idle" and T.shots.is_empty()
	A.meter = 100.0
	T.test_inp["special"] = true
	var thrown := false
	var floored := false
	pic = false
	for i in range(160):
		await get_tree().physics_frame
		thrown = thrown or not T.shots.is_empty()
		floored = floored or B.st == "down"
		if shots and not pic and not T.shots.is_empty() and int(T.shots[0]["t"]) > 6:
			pic = true
			await snap.call("tokken_4_poder")
	_check(no_power_yet and thrown and floored and A.meter < 30.0 and 100.0 - B.hp > 15.0, "the power: not until its bar is full; then it is thrown, floors them (%.1f) and the bar is empty again" % (100.0 - B.hp))
	# a jump
	place.call(60.0, still)
	await tick.call(2)
	T.test_inp["up"] = true
	await tick.call(3)
	T.test_inp["up"] = false
	var high := 0.0
	for i in range(70):
		await get_tree().physics_frame
		high = maxf(high, A.y)
	_check(high > 80.0 and A.st == "idle" and A.y == 0.0, "up, and down again (%.0f high)" % high)
	# knocked out: the round, and then the match
	place.call(30.0, still)
	B.hp = 3.0
	await tick.call(2)
	T.test_inp["light"] = true
	pic = false
	for i in range(700):
		await get_tree().physics_frame
		if shots and not pic and T.mode == "ko" and T.mode_t > 26:
			pic = true
			await snap.call("tokken_5_ko")
		if T.mode == "intro" and T.round_n == 2:
			break
	var round_two: bool = A.wins == 1 and B.wins == 0 and T.round_n == 2
	for i in range(300):
		if T.mode == "fight":
			break
		await get_tree().physics_frame
	place.call(30.0, still)
	B.hp = 3.0
	await tick.call(2)
	T.test_inp["light"] = true
	for i in range(900):
		if not T.active:
			break
		await get_tree().physics_frame
	_check(round_two and ended == [true] and not T.active and g.phase == phase_was, "their last of it gone, K.O.: the round is yours, and the second one the match")
	# against the machine: harder the more you win in a row
	var racha0 = g.stats.get("tokken_racha")
	g.stats.erase("tokken_racha")
	var rungs: Array = []
	for k in range(2):
		g.recress.free_play(Vector2(99999.0, 99999.0))
		await tick.call(4)
		rungs.append(String(T.opts.get("ai", "")))
		T.test_end(true)
		await tick.call(8)
	g.recress.free_play(Vector2(99999.0, 99999.0))
	await tick.call(4)
	T.test_end(false)
	await tick.call(8)
	_check(rungs == ["facil", "normal"] and int(g.stats.get("tokken_racha", -1)) == 0 and int(g.stats.get("tokken_mejor", 0)) >= 2 and not T.active,
		"at the other machines, against the machine itself: harder the more you win in a row (%s), and lose and it starts again" % str(rungs))
	if racha0 != null:
		g.stats["tokken_racha"] = racha0
	# every fighter's power, one after another (and, with --shots, a picture of each)
	var powers: Array = []
	for i in range(T.ROSTER.size()):
		var theirs: String = T.ROSTER[(i + 3) % T.ROSTER.size()]
		T.start({"foe": theirs, "ai": "quieto"}, func(_w): pass)
		T.pick = i
		await tick.call(14)
		T._pressed["ok"] = true
		await tick.call(34)
		T._pressed["ok"] = true
		for k in range(200):
			if T.mode == "fight":
				break
			await get_tree().physics_frame
		T.test_inp = {"dir": 0, "up": false, "light": false, "heavy": false, "special": false}
		T.a.meter = 100.0
		T.b.x = T.a.x + 190.0
		T.test_inp["special"] = true
		var hp0: float = T.b.hp
		var taken := false
		for k in range(170):
			await get_tree().physics_frame
			var mv: Dictionary = T.a.move
			var showing: bool = (not T.shots.is_empty() and int(T.shots[0]["t"]) > 4) or (not mv.is_empty() and String(mv.get("type", "")) in ["dash", "leap"] and T.freeze == 0 and (T.a.st == "jump" or T.a.t > int(mv["startup"]) + 3))
			if shots and not taken and showing:
				taken = true
				await snap.call("tokken_poder_%s" % T.ROSTER[i])
		powers.append(hp0 - T.b.hp > 12.0)
		T.test_end(false)
		await tick.call(8)
	_check(not powers.has(false) and not T.active, "each of the six has a power of their own, and every one of them lands: %s" % str(powers))
	# how hard is the mayor? the machine plays itself
	var wins := {"novato": 0, "jugador": 0}
	for who in wins:
		for i in range(matches):
			if T.sim("napoleon", who, "monstruo", "alcalde", 7000 + i)["won"]:
				wins[who] += 1
			if i % 3 == 2:
				await get_tree().process_frame
	print("  tokken: against the mayor, of %d matches each: somebody who has never played wins %d, somebody who knows the combo %d" % [matches, wins["novato"], wins["jugador"]])
	_check(wins["jugador"] > wins["novato"] and wins["jugador"] >= matches * 0.4 and wins["novato"] >= 1 and wins["novato"] <= matches * 0.6,
		"the mayor is hard but can be beaten: of %d matches, somebody who has never played takes %d, and somebody who has found the combo %d" % [matches, wins["novato"], wins["jugador"]])

## Skids (derrape.gd): brake hard or pull the handbrake at speed and the tyres squeal and leave marks on the road,
## which go once you have left them far behind.
## La Chiki and the walls of the peñas (pintadas.gd), from her first talk to the call at the end and her name
func _pintadas_checks() -> void:
	var P = g.pintadas
	var chiki = g.named["chiki"]
	var mine: int = g.look_sel[11]
	var saved := {}
	for key in ["chiki_tags", "painted", "tag_hints", "tag_hint_day", "tags_done", "chiki_maria"]:
		if g.stats.has(key):
			saved[key] = g.stats[key]
			g.stats.erase(key)
	var was_over: bool = g._protest_over
	var folk_was: Dictionary = g.folk.data.duplicate(true)
	g._protest_over = true
	g.side = null
	g.phase = "free"
	g.menu.close()
	if g.in_car != null:
		g.in_car.set_speed(Vector2.ZERO)
		g._exit_car()
	P.assign(mine)
	var trust0: int = g.folk.trust("chiki")
	g.player.p = chiki.p + Vector2(1.2, 0.6)
	await _frames(5)
	g.talk_to(chiki)
	var scene := false
	for k in range(40):                              # her lines, the scene over the walls among them
		scene = scene or (g.cine_lock and g.cam_fixed != null)
		if g.dlg == null:
			break
		await _skip_dialog(false)
	_check(P.unlocked() and scene and not g.cine_lock and g.cam_fixed == null and g.folk.knows("chiki") and g.hud.toast_label.text == Loc.t("t_tags_unlocked"),
		"the first talk with La Chiki: her peña, the philosophy, a scene over the walls of the peñas, the spray -- and now they can be painted")
	g.talk_to(chiki)
	await _frames(3)
	var offered: bool = g.menu.visible and g._choice["options"].size() == 2
	g._choose(0)
	await _frames(3)
	var hint_said: String = String(g.dlg["lines"][0]) if g.dlg != null else ""
	await _skip_dialog(false)
	_check(offered and P.hinted().size() == 1 and hint_said != "" and not hint_said.contains("{calle}"), "once a day she thinks she saw one somewhere, and it goes on the minimap: %s" % hint_said)
	g.talk_to(chiki)
	await _frames(3)
	g._choose(0)
	await _frames(3)
	_check(g.dlg != null and g.dlg["lines"] == P._lines("chiki_hint_again"), "and only once a day")
	await _skip_dialog(false)
	# every wall: hers glad or cross, the call, and the mission over
	var trust1: int = g.folk.trust("chiki")
	var nietos_covered := 0
	for t in g.props.tags:
		if t["owner"] != mine:
			nietos_covered += 1 if t["owner"] == P.NIETOS else 0
			g._paint(t)
	var moved: int = g.folk.trust("chiki") - trust1
	var expect: int = (g.props.tags.size()) if mine == P.NIETOS else -nietos_covered
	var n := 0
	while g.phone_call == null and n < 60 * 10:
		await get_tree().physics_frame
		n += 1
	var rang: bool = g.phone_call != null and g.phone_call.get("npc", "") == "chiki"
	g.interact()
	await _skip_dialog(false)
	await _frames(10)
	_check(rang and P.done() and g.props.tags_owned(mine) == g.props.tags.size() and (moved == expect or g.folk.trust("chiki") >= 100 or moved < 0),
		"every wall yours: La Chiki rings, and on hanging up the mission is over (trust moved %d with the painting, %s)" % [moved, "+1 each, as a Marzista" if mine == P.NIETOS else "-1 for each Nietos covered"])
	g.folk.add("chiki", 100)
	g.talk_to(chiki)
	await _frames(3)
	_check(g.dlg != null and g.dlg["lines"] == P._lines("chiki_maria") and g.stats.has("chiki_maria"), "at 100 of trust: her name is María, and Don Luis is her brother")
	await _skip_dialog(false)
	for key in ["chiki_tags", "painted", "tag_hints", "tag_hint_day", "tags_done", "chiki_maria"]:
		g.stats.erase(key)
	for key in saved:
		g.stats[key] = saved[key]
	g._protest_over = was_over
	g.folk.data = folk_was
	P.assign(mine)
	g._refresh_counts()

## The title, calmly: the town from the air, the name fading in, "press any button", and the menu only after that
func _titulo_checks(pictures := false) -> void:
	g.menu.close()
	g._after_intro()
	await _frames(int(30.0 * (1.5 + g.TITLE_NAME_AT + 0.5)))
	var coming: bool = g.phase == "title_in" and g.hud.title_name.modulate.a > 0.02 and not g.menu.visible
	await _frames(int(30.0 * (g.TITLE_PRESS_AT + 1.0)))
	_check(coming and g.phase == "press" and g.hud.title_name.modulate.a > 0.95 and g.hud.title_press.modulate.a > 0.3 and g.hud.title_press.text == Loc.t("t_press_any") and not g.menu.visible,
		"the title: the town from the air, the name fading in in a joined-up hand, then \"%s\" at the foot, and no menu yet" % Loc.t("t_press_any"))
	if pictures:
		await _shot("titulo_1_nombre")
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	Input.parse_input_event(key)
	await _frames(3)
	var going: bool = g.phase == "title_out" and not g.menu.visible
	var up := key.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await _frames(15)
	var half: float = g.menu.modulate.a if g.menu.visible else 0.0
	await _frames(30)
	_check(going and g.phase == "title" and g.menu.visible and g.hud.title_name.modulate.a < 0.05 and half < 0.95 and g.menu.modulate.a > 0.95,
		"a key pressed: the name goes, and only then the menu fades in (%.2f on the way, then all there)" % half)
	if pictures:
		await _shot("titulo_2_menu")

func _derrape_checks(pictures := false) -> void:
	var D = g.derrape
	if g.in_car == null:
		g._enter_car(g.paca_car)
	var c = g.in_car
	g.traffic.clear()
	g.traffic._spawn_t = 99999.0
	g.police.reset()
	var st: Dictionary = _long_street()
	var u: Vector2 = st["u"]
	c.repair()
	c.place(st["p"] + u * 6.0, atan2(u.x, u.y))
	await _frames(10)
	var laid0: int = D.laid
	for i in range(90):                            # straight down the street, foot down, no slide
		c.set_speed(u * minf(16.0, 4.0 + i * 0.3))
		c.drive(1.0, 0.0, false, true, 1.0 / 60.0)
		await get_tree().physics_frame
	_check(D.laid == laid0 and D.skidding == 0.0, "driving along at speed leaves no marks")
	# driving as anyone drives: foot down, a gentle bend, a bump under a wheel: not a squeal (it squealed nearly all the
	# time, on a slight turn or going straight over the bumps: the user, 14 November 2026)
	c.place(st["p"] + u * 6.0, atan2(u.x, u.y))
	await _frames(5)
	var heard := false
	var peak := 0.0
	var top_v := 0.0
	Input.action_press("forward")
	for i in range(200):
		if i == 90:
			Input.action_press("left", 0.3)
		if i == 120 or i == 160:                     # (a bump under a front wheel, then under a back one)
			c.apply_impulse(Vector3(0, c.mass * 2.5, 0), c.global_transform.basis * Vector3(0.6, 0.0, 1.3 if i == 120 else -1.3))
		await get_tree().physics_frame
		peak = maxf(peak, D.skidding)
		top_v = maxf(top_v, c.vel.length())
		heard = heard or Sfx._skid.playing or Sfx._screech.playing
	Input.action_release("forward")
	Input.action_release("left")
	_check(not heard, "driving as anyone does (up to %.0f km/h), a gentle bend and two bumps: not a squeal (skid reading at most %.2f)" % [top_v * 3.6, peak])
	c.place(st["p"] + u * 6.0, atan2(u.x, u.y))
	await _frames(5)
	for i in range(90):                            # (up to speed again for the handbrake)
		c.set_speed(u * minf(16.0, 4.0 + i * 0.3))
		c.drive(1.0, 0.0, false, true, 1.0 / 60.0)
		await get_tree().physics_frame
	var most := 0.0
	Input.action_press("handbrake")                # then the handbrake, and the wheel hard over
	Input.action_press("left")
	for i in range(80):
		await get_tree().physics_frame
		most = maxf(most, D.skidding)
	Input.action_release("handbrake")
	Input.action_release("left")
	_check(most > 0.3 and D.laid > laid0 + 4, "the handbrake at speed: the tyres squeal (%.2f) and leave marks on the road (%d strips)" % [most, D.laid - laid0])
	var missing: Array = []
	for kind in Sfx.ENGINES:
		if Sfx.sample(Sfx.ENGINES[kind], true) == null:
			missing.append(Sfx.ENGINES[kind])
	for kind in Sfx.HORNS:
		for nm in Sfx.HORNS[kind]:
			if Sfx.sample(nm) == null:
				missing.append(nm)
	for nm in Sfx.SCREECHES + ["derrape_bucle_1"]:
		if Sfx.sample(nm) == null:
			missing.append(nm)
	_check(missing.is_empty() and Sfx.horn("tractor") and Sfx.sample(Sfx.ENGINES["z15"], true).loop, "every make has its recorded engine (looping) and horns, and the tyres their screeches (missing: %s)" % str(missing))
	await _frames(30)
	_check(D.skidding == 0.0, "and they stop squealing when the car stops sliding")
	# a slide that ends against a wall: the car stops dead, and so does the sound (not the rest of a 3-second screech)
	c.place(st["p"] + u * 6.0, atan2(u.x, u.y))
	for i in range(40):
		c.set_speed(u * 16.0)
		await get_tree().physics_frame
	Input.action_press("handbrake")
	Input.action_press("left")
	var screeching := false
	for i in range(30):
		await get_tree().physics_frame
		screeching = screeching or Sfx._screech.playing
	Input.action_release("handbrake")
	Input.action_release("left")
	c.set_speed(Vector2.ZERO)
	c.linear_velocity = Vector3.ZERO
	await _frames(3)
	_check(screeching and not Sfx._screech.playing and not Sfx._skid.playing, "a slide stopped dead (a wall): the screech and the squeal stop with the car, under 3 km/h")
	# the horn: sounds the moment it is pressed, and a second press a moment later starts it again
	g._horn_cool = 0.0
	g.honk()
	var at_once: bool = Sfx._horn_player.playing
	var went_on := 0.0
	for i in range(120):                          # (the audio runs on its own clock: wait till it has really got going)
		await get_tree().physics_frame
		went_on = Sfx._horn_player.get_playback_position()
		if went_on > 0.12:
			break
	g._horn_cool = 0.0
	g.honk()
	await _frames(1)
	_check(at_once and went_on > 0.12 and Sfx._horn_player.playing and Sfx._horn_player.get_playback_position() < went_on - 0.05,
		"the horn sounds the moment it is pressed, and pressed again a fifth of a second later it starts again (%.2f s in, then %.2f)" % [went_on, Sfx._horn_player.get_playback_position()])
	if pictures:
		var mid: Vector2 = c.p
		await _view_at(MapData.at(mid - u * 10.0 + Vector2(-u.y, u.x) * 4.0, 5.5), MapData.at(mid - u * 3.0, 0.0), "derrape_1", 55.0)
	var here: int = D.count()
	_check(here > 4, "(%d marks lying on the ground)" % here)
	c.place(st["p"] + u * 6.0 + Vector2(400.0, 300.0), c.h)
	await _frames(60)
	_check(D.count() == 0, "drive off and leave them far behind and they are gone")
	g.traffic._spawn_t = 2.0

func _run() -> void:
	await _frames(10)
	if OS.get_cmdline_user_args().has("--tokken"):        # Tokken 9, the fighting game on the Recress's machines (add --shots)
		shots = OS.get_cmdline_user_args().has("--shots")
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = true
		await _frames(20)
		if OS.get_cmdline_user_args().has("--demo"):         # the machine plays itself on screen: a picture every few frames (--window)
			var T = g.tokken
			T.start({"foe": "dracula", "foe_tag": "Katakumba69", "ai": "dificil"}, func(_w): pass)
			T.pick = 2
			await _frames(8)
			T._pressed["ok"] = true
			await _frames(18)
			T._pressed["ok"] = true
			while T.mode != "fight":
				await get_tree().physics_frame
			T.a.human = false
			T.a.ai = T._make(T.a.id, "", false, "jugador").ai
			T.a.meter = 70.0
			T.b.meter = 70.0
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
			for i in range(48):
				for k in range(7):
					await get_tree().physics_frame
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://shots/tokken_demo_%02d.png" % i)
			get_tree().quit(0)
			return
		if OS.get_cmdline_user_args().has("--balance"):      # every fighter against every other, the machine playing both: who wins
			var T = g.tokken
			var per := 12
			var total := {}
			for me in T.ROSTER:
				var row := "  %-10s" % me
				total[me] = 0
				for them in T.ROSTER:
					var w := 0
					for i in range(per):
						if T.sim(me, "normal", them, "normal", 100 + i)["won"]:
							w += 1
					total[me] += w
					row += " %2d" % w
					await get_tree().process_frame
				print(row + "   = %d of %d" % [total[me], per * T.ROSTER.size()])
			for pair in [["novato", "alcalde"], ["jugador", "alcalde"], ["novato", "facil"], ["novato", "normal"], ["jugador", "normal"], ["jugador", "dificil"], ["jugador", "katakumba"]]:
				var w := 0
				var frames := 0
				for i in range(40):
					var r: Dictionary = T.sim("napoleon", pair[0], "monstruo" if pair[1] == "alcalde" else ("dracula" if pair[1] == "katakumba" else T.ROSTER[i % 6]), pair[1], 500 + i)
					w += 1 if r["won"] else 0
					frames += int(r["frames"])
				print("  %s against %s: %d of 40 (a match lasts %.0f s)" % [pair[0], pair[1], w, frames / 40.0 / 60.0])
				await get_tree().process_frame
			get_tree().quit(0)
			return
		await _tokken_checks(40)
		print("TOKKEN %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--recress"):       # "Un torneo en los Galaxy Recress", from start to finish (add --shots)
		shots = OS.get_cmdline_user_args().has("--shots")
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = true
		g.si = g._idx("tbc")
		await _frames(20)
		await _recress_checks()
		print("RECRESS %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--marcas"):        # who has a mission for you, on the map and over their heads (add --shots)
		shots = OS.get_cmdline_user_args().has("--shots")
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = true
		g.si = g._idx("tbc")
		await _frames(20)
		await _marcas_checks()
		var josefa = g.named["josefa"]
		g.stats.erase("menu_done")
		var r: Dictionary = MapData.nearest_road(josefa.p)
		var to_road: Vector2 = ((r["p"] as Vector2) - josefa.p).normalized()
		g.player.p = josefa.p + to_road * 3.0 + Vector2(-to_road.y, to_road.x) * 2.0
		var head: Vector3 = josefa.global_position + Vector3(0, 1.9, 0)
		g.cam_fixed = [head + Vector3(to_road.x, 0.0, to_road.y) * 5.5 + Vector3(0, 0.6, 0), head]
		await _frames(60)
		await _shot("marcas_flecha")
		g.cam_fixed = null
		g.hud.bigmap.visible = true
		g.hud.bigmap.queue_redraw()
		await _frames(10)
		await _shot("marcas_mapa")
		g.hud.bigmap.visible = false
		print("MARCAS %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--llamadas"):      # the switchboard
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = true
		await _frames(20)
		await _llamadas_checks()
		print("LLAMADAS %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--grafitis"):      # the peñas' graffiti: one of each, close up; and where they all are
		shots = true
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = false
		g.set_time(11.0)
		await _frames(20)
		var lines: Array = []
		for t in g.props.tags:
			lines.append("%d %.1f %.1f %.2f size %s room %.1f" % [t["owner"], (t["p"] as Vector2).x, (t["p"] as Vector2).y, float(t["wear"]), str((t["node"].mesh as QuadMesh).size), float(t["room"])])
		var f := FileAccess.open("res://shots/grafitis.txt", FileAccess.WRITE)
		f.store_string("
".join(lines))
		f = null
		for k in range(Creator.PENAS.size()):
			var t: Dictionary = g.props.tags.filter(func(tt): return tt["owner"] == k)[0]
			var n: Vector2 = t["n"]
			var at: Vector3 = t["node"].global_position
			g.player.p = (t["p"] as Vector2) + Vector2(-n.y, n.x) * 2.6       # (stood to one side, out of the picture)
			g.cam_fixed = [at + Vector3(n.x, 0.0, n.y) * 5.5 + Vector3(0, 0.3, 0), at]
			await _frames(45)
			await _shot("grafiti_%d_%s" % [k, Creator.PENA_IDS[k]])
		var t0: Dictionary = g.props.tags[0]
		g.props.paint(t0, (int(t0["owner"]) + 1) % Creator.PENAS.size())
		var n0: Vector2 = t0["n"]
		var at0: Vector3 = t0["node"].global_position
		g.player.p = (t0["p"] as Vector2) + Vector2(-n0.y, n0.x) * 2.6
		g.cam_fixed = [at0 + Vector3(n0.x, 0.0, n0.y) * 5.5 + Vector3(0, 0.3, 0), at0]
		await _frames(45)
		await _shot("grafiti_fresco")
		g.cam_fixed = null
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--sombreadores"):  # shaders made in the middle of play: a minute's tour, counted (NOT --headless)
		await _shader_tour()
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--limite"):        # the edge of the map
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = true
		await _frames(20)
		await _limite_checks()
		print("LIMITE %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--vuelcos"):       # rollovers: every make driven hard through the town
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = true
		await _frames(20)
		await _vuelcos_checks()
		print("VUELCOS %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--palabros"):      # the old neighbours' sayings, «apreta», the credits
		g.menu.close()
		g.phase = "free"
		await _frames(20)
		_palabros_checks()
		print("PALABROS %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--emisoras"):      # just the radio stations playing on in the background
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = true
		await _frames(20)
		if OS.get_cmdline_user_args().has("--tras-derrape"):
			await _derrape_checks()
		await _radio_live_checks()
		_tirones_checks()
		print("EMISORAS %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--derrape"):      # just the skids (add --shots for a picture)
		g.menu.close()
		g.slot = 0
		g._end_cutscene()
		await _frames(30)
		await _derrape_checks(shots)
		print("DERRAPE %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--flecha"):        # the guide arrow on foot, walking: pictures, and how much it twitches from one frame to the next
		shots = true
		g.menu.close()
		g.slot = 0
		g._end_cutscene()
		await _frames(30)
		g.begin_step(g._idx("loli"))
		g.player.p = g.places["home"]["p"]
		await _frames(20)
		var a0: float = g.arrow_body.rotation.y
		var worst_jump := 0.0
		var jumps := 0
		Input.action_press("forward")
		for i in range(60 * 8):
			await get_tree().process_frame
			var aim: Vector2 = g.target
			var to: Vector2 = aim - g.player.p
			g.cam_yaw = lerp_angle(g.cam_yaw, atan2(to.x, to.y), 0.05)
			var a1: float = g.arrow_body.rotation.y
			var jump: float = absf(angle_difference(a0, a1))
			worst_jump = maxf(worst_jump, jump)
			if jump > 0.08:
				jumps += 1
			a0 = a1
			if i in [90, 200, 330]:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://shots/flecha_%d.png" % i)
		Input.action_release("forward")
		print("flecha: worst turn in one frame %.2f rad; %d frames turned more than 0.08 rad; scale %s; visible %s" % [worst_jump, jumps, str(g.arrow_body.scale), g.arrow.visible])
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--tirones"):       # hitches: a minute on autopilot across town, every frame timed. NOT with --fixed-fps or --headless
		g.menu.close()
		g.slot = 0
		g._end_cutscene()
		await _frames(30)
		g._enter_car(g.paca_car)
		g.set_target(g.places["kiosk"]["p"], true)
		g.autopilot = g.traffic.adopt(g.in_car, g.target)
		g.prof = {}
		if not OS.get_cmdline_user_args().has("--tope"):      # (--tope: with whatever frame cap and vsync the settings have)
			Engine.max_fps = 0
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		var secs := 70
		var without := ""
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--seg="):
				secs = int(arg.trim_prefix("--seg="))
			if arg.begins_with("--sin="):
				without = arg.trim_prefix("--sin=")
		match without:                               # one thing taken away, to see what it was costing
			"hud": g.hud.visible = false
			"mapa": g.hud.minimap.visible = false
			"destino":
				g.traffic.release(g.autopilot)
				g.autopilot = null
				g.set_target(null, false)
			"cielo": g.sky_fx.visible = false
			"vecinos":
				for n in g.npcs:
					n.away = true
					n.visible = false
			"luces": g.lights.visible = false
		print("tirones: without '%s', %d s" % [without, secs])
		var frames: Array = []
		var worst: Array = []
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
		var sums := {"physics tick": 0.0, "process": 0.0, "render cpu": 0.0, "render gpu": 0.0, "draw calls": 0.0, "objects": 0.0, "physics bodies": 0.0, "nodes": 0.0}
		var last := Time.get_ticks_usec()
		var began := last
		var legs := ["kiosk", "tanatorio", "coop", "home"]
		var asked := Time.get_ticks_usec()
		var leg := 0
		while Time.get_ticks_usec() - began < secs * 1000000:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			var ms := (now - last) / 1000.0
			last = now
			frames.append(ms)
			var vp := get_viewport().get_viewport_rid()
			sums["physics tick"] += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
			sums["process"] += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
			sums["render cpu"] += RenderingServer.viewport_get_measured_render_time_cpu(vp) + RenderingServer.get_frame_setup_time_cpu()
			sums["render gpu"] += RenderingServer.viewport_get_measured_render_time_gpu(vp)
			sums["draw calls"] += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			sums["objects"] += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
			sums["physics bodies"] += Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)
			sums["nodes"] += Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
			if ms > 14.0:
				var parts: Array = g.prof.keys()
				parts.sort_custom(func(a, b): return g.prof[a] > g.prof[b])
				worst.append("%6.1f ms at %4.1f s  cars %2d  npcs %3d  | %s" % [ms, (now - began) / 1e6, g.traffic.list.size(), g.npcs.size(), ", ".join(parts.slice(0, 3).map(func(k): return "%s %.1f" % [k, g.prof[k]]))])
			g.prof.clear()
			if without != "destino" and now - asked > 4000000 and (g.autopilot == null or g.in_car.p.distance_to(g.target) < 20.0):      # there (or it gave up): on to the next place
				asked = now
				leg = (leg + 1) % legs.size()
				g.set_target(g.places[legs[leg]]["p"], true)
				if g.autopilot != null:
					g.traffic.release(g.autopilot)
				g.autopilot = g.traffic.adopt(g.in_car, g.target)
		frames.sort()
		var total := 0.0
		for ms in frames:
			total += ms
		var n := frames.size()
		print("tirones: %d frames in %.0f s: %.0f fps on average; median %.1f ms; worst 1%% %.1f ms; worst %.1f ms; over 22 ms: %d, over 50 ms: %d" % [n, total / 1000.0, n * 1000.0 / total, frames[n / 2], frames[int(n * 0.99)], frames[-1],
			frames.filter(func(ms): return ms > 22.0).size(), frames.filter(func(ms): return ms > 50.0).size()])
		print("tirones: per frame, on average: " + ", ".join(sums.keys().map(func(k): return "%s %.1f" % [k, sums[k] / n])))
		var t_route := Time.get_ticks_usec()
		MapData.set_route_target(g.places["coop"]["p"])
		print("tirones: working out a route to a new place takes %.1f ms" % ((Time.get_ticks_usec() - t_route) / 1000.0))
		for row in worst.slice(0, 25):
			print("tirones: ", row)
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--botellas"):      # the oil on the roof rack, as the first mission has it
		shots = true
		g.menu.close()
		g.slot = 0
		g._end_cutscene()
		await _frames(20)
		g._enter_car(g.paca_car)
		g.begin_step(g._idx("deliver"))
		await _frames(30)
		var c = g.in_car
		print("botellas: %d, visibles %d, baca en %s, coche %s tamaño %s" % [g.bottles, c.bottles.filter(func(b): return b.visible).size(), str(c.bottles[0].get_parent().position), c.kind, str(c.model.get_meta("size")) if c.model != null else "-"])
		var f := Vector2(sin(c.h), cos(c.h))
		await _view_at(MapData.at(c.p - f * 5.5 + Vector2(f.y, -f.x) * 3.0, 3.6), MapData.at(c.p, 1.4), "botellas_1", 45.0)
		g.cam_pitch = 0.5
		await _frames(40)
		await _shot("botellas_2_juego")
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--ruta"):          # which streets the delivery lorry takes on each leg of Don Luis's mission
		var S = g.sabotaje
		var from: Vector2 = g.kebab.spot(11.0, 4.5)
		for k in range(3):
			var to: Vector2 = S.stop(k)["road"]
			var nodes: Array = g.traffic.route_nodes(from, to)
			var streets: Array = []
			var far := 0.0
			for i in range(nodes.size() - 1):
				var sg = MapData.seg_between(nodes[i], nodes[i + 1])
				far += MapData.nodes[nodes[i]].distance_to(MapData.nodes[nodes[i + 1]])
				var name: String = String(sg.road["n"]) if sg != null else "?"
				if streets.is_empty() or streets[-1] != name:
					streets.append(name)
			print("ruta %d -> %s: %.0f m por %s" % [k + 1, S.stop(k)["name"], far, " > ".join(streets)])
			from = to
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--motin"):         # just the roast ham riot (add --shots for the pictures)
		g.menu.close()
		g.slot = 0
		g._end_cutscene()
		await _frames(20)
		await _motin_checks(shots)
		print("MOTIN %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--civicos"):       # just Puntos Cívicos, businesses and side lines (add --shots for the pictures)
		g.menu.close()
		g.slot = 0
		g._end_cutscene()
		await _frames(20)
		await _civicos_checks(shots)
		print("CIVICOS %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--mirada"):        # just heads turning to look (add --shots for the picture)
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = false
		g.apply_moment("noon", true)
		await _frames(20)
		if OS.get_cmdline_user_args().has("--antes"):     # (what the full run does just before it)
			g.hud.play_ui.visible = true
			await _palabros_checks()
			await _limite_checks()
			await _vuelcos_checks(true)
		await _mirada_checks(shots)
		print("MIRADA %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--sabotaje"):      # just Don Luis's side mission (add --shots for the pictures)
		g.menu.close()
		g.slot = 0
		g._end_cutscene()
		await _frames(20)
		await _sabotaje_checks(shots)
		print("SABOTAJE %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--reglas"):        # just the rules every mission follows (add --shots for the pictures)
		g.menu.close()
		g.slot = 0
		g._end_cutscene()
		await _frames(20)
		await _reglas_checks(shots)
		print("REGLAS %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--comida"):        # just eating and what comes of it (add --shots for the pictures)
		g.menu.close()
		g.phase = "free"
		g.slot = 0
		g.hud.play_ui.visible = true
		g.apply_moment("noon", true)
		await _frames(20)
		await _comida_checks(shots)
		print("COMIDA %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--kebab"):         # just Kebab Luis's customers (add --shots for the pictures)
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = false
		g.apply_moment("noon", true)
		await _frames(20)
		if OS.get_cmdline_user_args().has("--aforo"):     # how many really walk past, left to themselves, with you standing about
			g.player.p = g.kebab.spot(11.0, -5.0)
			for minute in range(10):
				await _frames(30 * 60)
				print("aforo: minute %d  passed %d  came in %d  served %d  gone %d  inside now %d" % [minute + 1, g.clientes.passed, g.clientes.stopped, g.clientes.served, g.clientes.gone, g.clientes.list.size()])
			get_tree().quit(0)
			return
		await _kebab_checks(shots)
		print("KEBAB %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--pitufos"):       # just the ramming: a patrol car 35 m behind you on a straight street
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = true
		await _frames(20)
		g._enter_car(g.paca_car)
		var pc = g.in_car
		for round in range(2):
			var st: Dictionary = _long_street()
			if round == 1:
				var cs = _clear_street()
				st = {"p": cs.a, "u": (cs.b - cs.a).normalized()}
			var hh := atan2(st["u"].x, st["u"].y)
			g.police.reset()
			g.traffic.clear()
			g.traffic._spawn_t = 99999.0
			pc.repair()
			pc.place(st["p"] + st["u"] * 55.0, hh)
			await _frames(10)
			g.police.add_heat(250.0)
			g.police.arrive()
			var k0 = g.police.cops[0]["car"]
			k0.place(st["p"] + st["u"] * 20.0, hh)
			g.police.cops[1]["car"].place(st["p"] + st["u"] * 8.0, hh)
			for i in range(4 * 60):
				await get_tree().physics_frame
				g.police.heat = 100.0
				if i % 20 == 0:
					var e0: Dictionary = g.police.cops[0]
					print("round %d t=%.1f d=%.1f v=%.1f off=%.2f sees=%s rev=%.1f stuck=%.2f hp=%.0f" % [round, i / 60.0, k0.p.distance_to(pc.p), k0.forward_speed(), float(e0.get("off", 0.0)), e0["sees"], e0["reverse"], e0["stuck"], pc.hp])
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--bench"):         # how fast does it run, and what is it spending the time on?
		await _bench()
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--portraits"):     # a passport photo of everybody with a name, into guion/fotos/
		var Portrait = load("res://scripts/portrait.gd")
		var out: String = ProjectSettings.globalize_path("res://").path_join("../guion/fotos")
		DirAccess.make_dir_recursive_absolute(out)
		var who := {"tu": Creator.look(Creator.defaults())}
		for id in g.named:
			who[id] = g.named[id].look_data
		who["repartidor"] = g.sabotaje.MAN           # (he is only about while Don Luis's mission lasts)
		for id in g.recress.LOOKS:                    # (and these only for the tournament at the Recress)
			who[id] = g.recress.LOOKS[id]
		for id in who:
			var vp: SubViewport = Portrait.viewport(who[id], Vector2i(192, 236))
			add_child(vp)
			for k in range(4):
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			vp.get_texture().get_image().save_png(out.path_join(id + ".png"))
			vp.queue_free()
		print("portraits: ", who.keys())
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--saves"):         # the saved games page, with a made-up save in it
		shots = true
		var f := FileAccess.open(g._slot_path(0), FileAccess.WRITE)
		var some: Array = Creator.defaults()
		some[0] = 1; some[8] = 4; some[12] = 2; some[15] = 3; some[17] = 1
		f.store_string(JSON.stringify({"weekday": 3, "clock": 10.0, "si": 8, "look": some, "money": 240}))
		f.close()
		g.menu.open("slots")
		await _shot("menu_saves")
		g.menu.close()
		g._new_game()
		for i in range(Loc.t("prologue").size()):
			g._story_next()
		g.creator_tab = 1
		g.creator_goto(17)
		g._creator_input("right"); g._creator_input("right")
		await _shot("creator_pintas")
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--menu"):          # just the menus: straight after opening each page, nothing pressed
		shots = true
		for page in ["main", "settings", "credits", "settings"]:
			g.menu.open(page)
			await _shot("menu_" + page)
			print("menu: opened %s, showing %s" % [page, g.menu.page])
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--calasanz"):      # just the nursery school of the Calle del Palo: its front, its gate, the yard with what is played on, the cabin, from the air
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
			for v in [["santo", Vector2(-0.7, -46.0), 1.7, Vector2(0.0, -10.0), 1.0, 55.0], ["cauce", Vector2(-2.3, -5.2), 1.6, Vector2(0.6, 0.0), 0.9, 70.0], ["acera", Vector2(4.1, -9.5), 2.75, Vector2(-0.5, 0.5), 1.3, 65.0],
					["sur", Vector2(1.6, 14.5), 1.7, Vector2(0.0, 0.0), 1.2, 60.0], ["palo", Vector2(1.2, 26.0), 1.7, Vector2(0.0, 0.0), 1.2, 38.0], ["placeta", Vector2(-9.0, 5.0), 1.7, Vector2(-1.0, 0.8), 1.3, 65.0],
					["encima", Vector2(2.8, 0.4), 2.8, Vector2(-3.0, -0.2), 2.0, 75.0], ["cochera", Vector2(-0.5, 9.0), 1.7, Vector2(5.0, 5.5), 1.6, 60.0], ["aire", Vector2(-1.0, 22.0), 17.0, Vector2(0.0, -2.0), 0.5, 60.0],
					["aire_norte", Vector2(0.5, -50.0), 17.0, Vector2(0.0, -20.0), 0.5, 60.0]]:
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
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		g.set_time(11.0)
		var ml = g.world.molino
		if ml == null:
			print("MOLINO FAILED (the map was baked without the mill's yard)")
			get_tree().quit(1)
			return
		for v in [["calle_norte", Vector2(-16.8, -31.0), 1.7, Vector2(-6.0, -4.0), 6.0, 70.0], ["calle_frente", Vector2(-17.2, 6.0), 1.7, Vector2(0.0, 0.0), 7.5, 75.0], ["calle_sur", Vector2(-16.2, 37.0), 1.7, Vector2(-6.0, 12.0), 5.0, 70.0],
				["porton", Vector2(-17.5, 17.2), 1.7, Vector2(-11.0, 17.4), 2.6, 75.0], ["portada", Vector2(-18.8, -23.6), 1.7, Vector2(-12.7, -24.0), 2.4, 70.0], ["puerta_roja", Vector2(-15.8, -4.8), 1.7, Vector2(-11.0, -7.4), 1.6, 65.0],
				["era", Vector2(-9.4, -8.6), 1.7, Vector2(0.0, 0.0), 6.6, 75.0], ["puerta", Vector2(-5.2, -10.0), 1.7, Vector2(-1.4, -3.3), 2.6, 65.0], ["corral", Vector2(2.5, 3.6), 1.7, Vector2(-1.0, 17.0), 3.6, 80.0],
				["este", Vector2(60.0, 1.0), 2.5, Vector2(0.0, 0.0), 6.4, 40.0], ["aire", Vector2(-27.0, -32.0), 24.0, Vector2(0.0, 6.0), 2.0, 60.0]]:
			var eye: Vector2 = ml.spot(v[1].x, v[1].y)
			var at: Vector2 = ml.spot(v[3].x, v[3].y)
			g.player.p = ml.spot(-16.5, 70.0)
			g.cam.position = Vector3(eye.x, ml.level + v[2], eye.y)
			g.cam.look_at(Vector3(at.x, ml.level + v[4], at.y))
			g.cam.fov = v[5]
			await _frames(6)
			await _shot("molino_" + v[0])
		var over: Vector2 = ml.spot(0.0, 2.0)
		g.cam.fov = 55.0
		g.cam.position = Vector3(over.x, ml.level + 70.0, over.y)
		g.cam.look_at(Vector3(over.x, ml.level, over.y), Vector3(0, 0, -1))        # north up, like the aerial photograph
		await _frames(6)
		await _shot("molino_above")
		g.phase = "free"
		await _molino_checks(true)
		print("MOLINO %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--plaza"):         # just the Plaza del Ayuntamiento and the town hall: from all round, and straight down like the aerial photo
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		g.apply_moment("noon", true)
		var pz = g.world.plaza
		for v in [["front", Vector2(-7.0, 44.0), 16.0, Vector2(0.0, 4.0), 4.0], ["facade", Vector2(-6.0, 19.0), 2.2, Vector2(1.0, 0.0), 6.5], ["arcade", Vector2(-27.0, -1.6), 1.7, Vector2(10.0, -1.7), 1.8],
				["boards", Vector2(1.0, 30.0), 22.0, Vector2(1.0, 9.0), 0.0], ["fountain", Vector2(-6.5, 47.5), 1.7, pz.FOUNTAIN, 0.7], ["garden", Vector2(9.5, 17.0), 1.7, Vector2(11.0, 40.0), 1.2],
				["column", Vector2(12.0, 38.0), 1.7, pz.COLUMN, 4.5], ["playground", Vector2(-8.5, 44.5), 1.8, pz.PLAY, 1.0], ["bar", Vector2(-7.0, 50.0), 1.7, Vector2(-22.0, 55.0), 1.8],
				["bandstand", Vector2(-8.0, 62.0), 1.7, pz.STAND, 2.2], ["zaragoza", Vector2(38.5, 14.0), 1.7, Vector2(31.7, -2.0), 3.0], ["arroyuelo", Vector2(-41.0, 6.0), -0.3, Vector2(-31.7, -1.8), 0.6],
				["steps", Vector2(-43.0, 38.5), -0.3, Vector2(-30.0, 38.5), -0.4], ["plaza_street", Vector2(8.0, 82.0), 1.7, Vector2(2.0, 55.0), 1.5], ["stall", Vector2(31.0, 68.0), 1.7, pz.STALL, 1.4]]:
			var eye: Vector2 = pz.spot(v[1].x, v[1].y)
			var at: Vector2 = pz.spot(v[3].x, v[3].y)
			g.player.p = pz.spot(60.0, 120.0)
			g.cam.position = Vector3(eye.x, pz.level + v[2], eye.y)
			g.cam.look_at(Vector3(at.x, pz.level + v[4], at.y))
			await _frames(6)
			await _shot("plaza_" + v[0])
		var mid: Vector2 = pz.spot(0.0, 40.0)
		g.cam.position = Vector3(mid.x, pz.level + 112.0, mid.y)
		g.cam.look_at(Vector3(mid.x, pz.level, mid.y), Vector3(0, 0, -1))        # north up, like the photo
		await _frames(6)
		await _shot("plaza_above")
		g.phase = "free"
		await _plaza_checks(true)
		print("PLAZA %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--agenda"):        # just the neighbours page, with one meter of each colour
		shots = true
		g.phase = "free"
		g.hud.play_ui.visible = true
		var level := {"paca": 12, "loli": 30, "maruja": 62, "josefa": 88, "vip": 100, "alberto": 49, "eusebio": 75}
		for who in level:
			g.folk.meet(who)
			g.folk.data[who]["t"] = level[who]
			g.folk.data[who]["floor"] = (int(level[who]) / 25) * 25
		g._open_pause()
		g.menu.open("log_folk")
		await _frames(10)
		await _shot("agenda_colours")
		var MenuQ = g.menu.get_script()
		print("colours: ", [MenuQ.meter_colour(0.12).to_html(false), MenuQ.meter_colour(0.3).to_html(false), MenuQ.meter_colour(0.62).to_html(false), MenuQ.meter_colour(0.88).to_html(false), MenuQ.meter_colour(1.0).to_html(false)])
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--fronts"):        # just the hand-made shopfronts
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		g.apply_moment("noon", true)
		await _garage_shots()
		for v in [["henry", g.places["henry"]["p"] + (g.places["henry"]["p"] - g.named["henry"].p).normalized() * 6.0 + Vector2(2.0, 3.0), 2.4, g.named["henry"].p, 2.0]]:
			var from: Vector2 = v[1]
			var at: Vector2 = v[3]
			g.cam.position = MapData.at(from, v[2])
			g.cam.look_at(MapData.at(at, v[4]))
			await _shot("front_" + v[0])
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--relief"):        # pictures of the lie of the land
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		g.apply_moment("noon", true)
		print("relief: ground from %.1f to %.1f m, ready %.1f s after launch" % [Array(MapData.rh).min(), Array(MapData.rh).max(), Time.get_ticks_msec() / 1000.0])
		for v in [["over", Vector2(-700, 700), 260.0, Vector2(-100, -100), 0.0], ["over_north", Vector2(200, -1500), 180.0, Vector2(0, -400), 0.0],
				["constitucion", Vector2(113, -20), 2.0, Vector2(96, -167), 3.0], ["arroyo_cross", Vector2(-95, -150), 2.2, Vector2(-250, -130), 0.5],
				["arroyo_along", Vector2(-131, -212), 2.4, Vector2(-195, -94), 1.0], ["arroyo_medio", Vector2(-240, -412), 2.4, Vector2(-166, -310), 1.0],
				["brick", Vector2(36, -62), 2.0, Vector2(4, -74), 9.0], ["brick_back", Vector2(-25, -110), 2.0, Vector2(4, -74), 9.0],
				["south", Vector2(0, 420), 3.0, Vector2(-30, 800), 0.0], ["plaza", Vector2(-150, 10), 14.0, Vector2(-162, -72), 2.0],
				["coop", Vector2(118, -1010), 5.0, Vector2(150, -1100), 3.0], ["villacanas", Vector2(300, -548), 2.4, Vector2(430, -660), 2.0]]:
			var eye: Vector2 = v[1]
			if v[2] < 10.0:                              # (street views: from the middle of the nearest street)
				eye = MapData.nearest_road(eye)["p"]
			g.player.p = eye
			g.cam.position = MapData.at(eye, v[2])
			g.cam.look_at(MapData.at(v[3], v[4]))
			await _frames(6)
			await _shot("relief_" + v[0])
		await _relief_checks()
		print("RELIEF %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--look"):          # pictures of the dressed-up interface
		shots = true
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = true
		await _frames(20)
		g.money = 37
		g.saffron = 4
		g._refresh_counts()
		g.hud.set_objective("LUNES · MAÑANA", Loc.t("obj_paca"))
		g.say(g.named["paca"].shown_name(), [Loc.t("paca_intro")[0]], g.named["paca"].voice)
		await _frames(150)
		await _shot("look_dialogue")
		g.dlg = null
		g.hud.dlg_slot.visible = false
		await _frames(10)
		g.hud.phone(true, g.named["paca"].shown_name(), Loc.t("ph_incoming"), g.named["paca"].look_data)
		await _frames(40)
		await _shot("look_phone_ringing")
		g.phone_call = {"npc": "paca", "lines": "paca_phone", "ring": 99.0, "on": true}
		g.hud.phone(true, g.named["paca"].shown_name(), Loc.t("ph_talking"), g.named["paca"].look_data)
		g.say(g.named["paca"].shown_name(), [Loc.t("paca_phone")[0]], g.named["paca"].voice)
		await _frames(150)
		await _shot("look_phone_talking")
		g.dlg = null
		g.hud.dlg_slot.visible = false
		g.phone_call = null
		g.hud.phone(false)
		await _frames(30)
		g.hud.show_card("La crisis del aceite", "LUNES · MAÑANA")
		await _frames(40)
		await _shot("look_card")
		g.hud.stamp(Loc.t("stamp_done"))
		g.police.heat = 60.0
		g.money = 52
		g._refresh_counts()
		await _frames(30)
		await _shot("look_stamp")
		var run = _clear_street()
		var ru: Vector2 = (run.b - run.a).normalized()
		var car = CarS.new()
		g.add_child(car)
		car.setup("julietta", 0, run.a + ru * 6.0, atan2(ru.x, ru.y))
		await _frames(10)
		g._enter_car(car)
		car.damage(car.spec["hp"] * 0.8)
		g.police.add_heat(250.0)
		g.police.arrive()
		Input.action_press("forward")
		Input.action_press("run")
		for i in range(170):
			await get_tree().physics_frame
			g.police.heat = 100.0
		await _shot("look_chase")
		Input.action_release("forward")
		Input.action_release("run")
		car.set_speed(Vector2.ZERO)
		g.police.reset()
		await _frames(5)
		g._open_pause()
		g.menu.open("log")
		await _frames(6)
		await _shot("look_agenda")
		g.menu.open("log_folk")
		await _frames(6)
		await _shot("look_agenda_folk")
		g.menu.open("log_radio")
		await _frames(6)
		await _shot("look_agenda_radio")
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--firmas"):        # the bridge, the demonstration and the signatures
		shots = true
		g.menu.close()
		g.phase = "play"
		g.hud.play_ui.visible = true
		g.set_time(10.0)
		g.begin_step(g._idx("alberto"))
		g.bridge.close_off(not g.stats.has("puente"))       # (as start_game does, which this mode skips: _puente_checks wants it fenced)
		await _frames(10)
		var br = g.bridge
		for v in [["bridge", Vector2(1.0, -21.0), 2.6, Vector2(0.0, -2.0), 1.6], ["protest", Vector2(br.open * 4.6, -15.5), 1.9, Vector2(0.0, -7.0), 1.6],
				["chiki", Vector2(br.open * 1.6, -3.4), 1.9, Vector2(-br.open * 0.9, 0.8), 1.9], ["bridge_back", Vector2(br.open * 1.0, 11.0), 2.2, Vector2(0.0, 0.0), 0.9],
				["bridge_air", Vector2(br.open * 13.0, -20.0), 15.0, Vector2(0.0, -4.0), 0.5]]:
			var eye: Vector2 = br.spot(v[1].x, v[1].y)
			g.player.p = br.spot(-br.kerb(), -30.0)
			g.phase = "selfshot"
			g.hud.play_ui.visible = false
			for n in g.npcs:                         # (nobody draws the neighbours while the game is paused for a picture)
				if n.p.distance_to(br.p) < 60.0:
					n.visible = true
					n.sync()
			g.cam.position = MapData.at(eye, v[2])
			g.cam.look_at(MapData.at(br.spot(v[3].x, v[3].y), v[4]))
			await _frames(8)
			await _shot("firmas_" + v[0])
		g.phase = "play"
		g.hud.play_ui.visible = true
		g.player.p = g.named["alberto"].p + Vector2(1.4, 1.0)
		await _frames(10)
		g.talk_to(g.named["alberto"])
		await _skip_dialog()
		await _frames(20)
		await _shot("firmas_hud")
		await _firmas_checks()
		print("FIRMAS %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--petril"):        # the Petril, from all round
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		g.apply_moment("noon", true)
		var pt = g.world.petril
		for v in [["esquina", Vector2(-6.0, 25.0), 1.7, Vector2(8.0, 6.0), 4.5], ["cruces", Vector2(10.0, 27.5), 1.7, Vector2(9.0, 8.0), 3.5], ["san_francisco", Vector2(-5.5, 11.0), 1.7, Vector2(8.0, 6.0), 3.0],
				["rampa", Vector2(20.0, 29.5), 1.7, Vector2(13.0, 12.0), 3.0], ["plazuela", Vector2(1.5, 16.5), 2.5, Vector2(12.0, 0.0), 5.0], ["iglesia", Vector2(9.5, 17.0), 2.5, Vector2(5.5, 0.0), 6.5],
				["convento", Vector2(1.5, 9.5), 2.5, Vector2(18.2, 9.5), 4.6], ["costado", Vector2(-6.5, -22.0), 1.7, Vector2(0.5, -8.0), 7.0], ["cabecera", Vector2(-6.0, -34.0), 1.7, Vector2(3.0, -22.0), 8.0],
				["aire", Vector2(-14.0, 36.0), 28.0, Vector2(10.0, 2.0), 3.0], ["aire_norte", Vector2(-10.0, -48.0), 30.0, Vector2(12.0, -8.0), 6.0]]:
			var eye: Vector2 = pt.spot(v[1].x, v[1].y)
			var at: Vector2 = pt.spot(v[3].x, v[3].y)
			g.player.p = pt.spot(40.0, 60.0)
			g.cam.position = MapData.at(eye, v[2])
			g.cam.look_at(MapData.at(at, v[4]))
			await _frames(6)
			await _shot("petril_" + v[0])
		g.phase = "free"
		await _petril_checks(true)
		print("PETRIL %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--church"):        # the parish church, from all round
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		g.apply_moment("noon", true)
		var ch = g.world.church
		for v in [["west", Vector2(-15.0, -9.0), 1.8, Vector2(0.0, -12.5), 7.0], ["tower", Vector2(-13.5, -4.0), 1.8, Vector2(2.0, -25.5), 19.0],
				["north", Vector2(34.0, -ch.D - 17.0), 2.0, Vector2(26.0, -ch.D), 6.5], ["north_long", Vector2(60.0, -ch.D - 9.0), 2.0, Vector2(8.0, -ch.D - 1.0), 11.0],
				["south", Vector2(6.0, 15.0), 2.0, Vector2(24.0, 0.0), 6.0], ["south_east", Vector2(62.0, 6.0), 9.0, Vector2(30.0, 3.0), 1.0], ["door", Vector2(-7.5, -11.2), 1.7, Vector2(0.0, -11.2), 5.2],
				["air", Vector2(-34.0, 44.0), 46.0, Vector2(26.0, -14.0), 6.0], ["air_north", Vector2(50.0, -70.0), 40.0, Vector2(24.0, -14.0), 8.0]]:
			var eye: Vector2 = ch.spot(v[1].x, v[1].y)
			var at: Vector2 = ch.spot(v[3].x, v[3].y)
			g.player.p = eye
			g.cam.position = MapData.at(eye, v[2])
			g.cam.look_at(MapData.at(at, v[4]))
			await _frames(6)
			await _shot("church_" + v[0])
		g.phase = "free"
		await _church_checks()
		print("CHURCH %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--clean"):         # the tidied-up screen: what shows, and when
		shots = true
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = true
		g.police.reset()
		g._refresh_counts()
		g.hud.set_objective("LUNES · MAÑANA", "")
		await _frames(170)
		_check(g.hud.heat_arc.modulate.a == 0.0 and g.hud.street_box.modulate.a < 0.05 and g.hud.obj_box.modulate.a < 0.02 and g.hud.tally_slot.get_theme_constant("margin_top") == g.hud.TALLY_UP,
			"with nothing going on the screen is clear: no police meter, no street name, no tally, and the calendar leaf put away")
		await _shot("clean_idle")
		g.hud.set_objective("LUNES · MEDIODÍA", "")
		await _frames(25)
		var day_up: bool = g.hud.obj_box.modulate.a > 0.9 and not g.hud.obj_text.visible
		await _shot("clean_noon")
		await _frames(140)
		_check(day_up and g.hud.obj_box.modulate.a < 0.02, "when the day moves on the leaf comes out for a few seconds to say so, and goes again")
		var paca = g.named["paca"]
		g.player.p = paca.p + Vector2(1.3, 0.4)
		g.player.sync()
		await _frames(20)
		var tag: Control = g.hud.prompt_slot
		var head: Vector2 = g.cam.unproject_position(paca.global_position + Vector3(0, 2.3, 0))
		_check(tag.visible and g.hud.prompt.text == g.hud.as_shown(g.hud.prompt, Loc.t("p_talk")) and tag.size.y < 40.0 and absf(tag.position.x + tag.size.x / 2.0 - head.x) < 70.0 and tag.position.y + tag.size.y < head.y + 14.0 and tag.position.y > head.y - 110.0,
			"the key to talk to a neighbour is a small tag over their head (%s, %.0f px tall, %.0f px to one side of the head and %.0f px above it)" % [g.hud.prompt.text, tag.size.y, tag.position.x + tag.size.x / 2.0 - head.x, head.y - tag.position.y - tag.size.y])
		await _shot("clean_prompt")
		g.hud.set_objective("LUNES · MAÑANA", Loc.t("obj_paca"))
		g.hud._street_name = ""                    # as if just arrived: the game puts up the name of the street the player is in
		g.police.add_heat(40.0)
		await _frames(50)
		_check(g.hud.heat_arc.modulate.a > 0.9 and g.hud.street_box.modulate.a > 0.9 and g.hud.obj_text.visible and g.hud.obj_box.modulate.a > 0.9,
			"an errand, some heat, a new street: the leaf comes back, the arc appears over the map, the street's tile comes up")
		await _shot("clean_busy")
		await _frames(240)
		var tile_gone: bool = g.hud.street_box.modulate.a < 0.05
		var real: String = g.hud._street_name      # (the game has since put up the street the player really is in)
		g.hud.show_street(real)
		await _frames(10)
		_check(tile_gone and g.hud.street_box.modulate.a < 0.05, "the street's tile goes after a few seconds and does not come back until you turn into another street (%.2f then %.2f, on %s)" % [0.0 if tile_gone else 1.0, g.hud.street_box.modulate.a, real])
		g.police.add_heat(30.0)                    # (the first lot has drained away by now)
		await _frames(15)
		g.police.heat = 0.0
		await _frames(60)                          # two seconds on (a "frame" here is a thirtieth of a second)
		var still: bool = g.hud.heat_arc.modulate.a > 0.9
		await _frames(60)
		_check(still and g.hud.heat_arc.modulate.a == 0.0, "the arc stays three seconds after the heat has run out, then goes (shown %s, now %.2f, heat %.1f, idle %.1f s)" % [str(still), g.hud.heat_arc.modulate.a, g.police.heat, g.hud.heat_arc.idle])
		var hidden: bool = g.hud.tally_slot.get_theme_constant("margin_top") == g.hud.TALLY_UP
		g.money += 15
		g.saffron += 1
		g._refresh_counts()
		await _frames(20)
		var down: bool = g.hud.tally_slot.get_theme_constant("margin_top") == g.hud.TALLY_DOWN and g.hud.tally[0][2].visible and g.hud.tally[0][2].text == "+15" and g.hud.tally[1][2].text == "+1" and not g.hud.tally[2][2].visible
		await _shot("clean_tally_up")
		g.money -= 100
		g._refresh_counts()
		await _frames(20)
		var red: bool = g.hud.tally[0][2].text == "−100" and g.hud.tally[0][2].get_theme_color("font_color").r > 0.9
		await _shot("clean_tally_down")
		await _frames(120)
		_check(hidden and down and red and g.hud.tally_slot.get_theme_constant("margin_top") == g.hud.TALLY_UP and not g.hud.tally[0][2].visible,
			"the tally waits off the top of the screen; a change brings it down with the amount in green or red, and a few seconds later it is gone again")
		g.police.add_heat(250.0)
		g.police.arrive()
		await _frames(50)
		await _shot("clean_pitufos")
		g.police.elite = true
		await _frames(26)
		await _shot("clean_tricornios")
		g.police.reset()
		g.hud.phone(true, g.named["paca"].shown_name(), Loc.t("ph_incoming"), g.named["paca"].look_data)
		await _frames(40)
		g.phone_call = {"npc": "paca", "lines": "paca_phone", "ring": 99.0, "on": true}
		g.hud.phone(true, g.named["paca"].shown_name(), Loc.t("ph_talking"), g.named["paca"].look_data)
		g.say(g.named["paca"].shown_name(), [Loc.t("paca_phone")[0]], g.named["paca"].voice)
		await _frames(150)
		await _shot("clean_phone")
		print("CLEAN %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--auto"):          # the Edison's autopilot
		shots = true
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = true
		await _frames(20)
		await _autopilot_checks()
		print("AUTO %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--hud"):           # the dashboards, the nitro, the guide arrow, the boxes
		shots = true
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = true
		await _frames(20)
		var run = _clear_street()
		var ru: Vector2 = (run.b - run.a).normalized()
		g.traffic.clear()
		g.traffic._spawn_t = 99999.0
		g._refresh_counts()
		for v in [["panda", 60, false], ["yondir", 90, false], ["edison", 110, false], ["pitufo", 90, false], ["julietta", 150, true], ["julietta", 420, true], ["tunero", 100, true]]:
			var car = CarS.new()
			g.add_child(car)
			car.setup(v[0], 0, run.a + ru * 6.0, atan2(ru.x, ru.y))
			await _frames(10)
			g._enter_car(car)
			g.target = run.a + ru * (400.0 if v[1] < 400 else 30.0)
			g.side = {"id": "shot", "who": "paca", "stage": "none", "t": 999.0}       # (so that the guide shows)
			Input.action_press("forward")
			if v[2]:
				Input.action_press("run")
			for i in range(int(v[1])):
				await get_tree().physics_frame
				g.side["t"] = 999.0
				if car.p.distance_to(run.a) > run.a.distance_to(run.b) - 25.0:       # the end of the street: back to the start, still going
					var keep: Vector2 = car.vel
					car.place(run.a + ru * 6.0, atan2(ru.x, ru.y))
					car.set_speed(keep)
			await _shot("hud_%s_%d" % [v[0], v[1]])
			Input.action_release("forward")
			Input.action_release("run")
			g.side = null
			car.set_speed(Vector2.ZERO)
			await _frames(3)
			g._exit_car()
			await _frames(3)
			car.queue_free()
			await _frames(3)
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--radio"):         # the card of the station you tune in
		shots = true
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = true
		await _frames(20)
		g._enter_car(g.paca_car)
		await _frames(30)
		for k in range(6):
			var tuned: Dictionary = Ambience.next_station()
			g.hud.radio_card(tuned)
			if k == 0:
				g.hud._street_name = ""               # (so the street's name comes up too: it has to keep above the radio)
			await _frames(30)
			await _shot("radio_card_%d" % (k + 1))
		print("radio: %d stations in %s: %s" % [Ambience.stations.size(), Ambience.radio_root(), ", ".join(Ambience.stations.map(func(s): return "%s (%d: %s)" % [s["name"], s["tracks"].size(), Ambience.song_of(s)]))])
		var playable := 0
		var secs := 0.0
		for n in range(Ambience.stations.size()):
			for k in range(Ambience.stations[n]["tracks"].size()):
				Ambience.stations[n]["i"] = k
				var tune: AudioStream = Ambience._radio_stream(n + 1)
				if tune != null and tune.get_length() > 5.0:
					playable += 1
					secs += tune.get_length()
		print("radio: %d tunes load and play, %.0f minutes in all" % [playable, secs / 60.0])
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--bays"):          # just the garages you drive into
		shots = true
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = true
		await _frames(20)
		await _garage_bay_checks()
		print("BAYS %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(0)
		return
	for arg in OS.get_cmdline_user_args():                # --aparca=x,z;x,z : parks every make at those spots, both ways round, and says how each ends up
		if String(arg).begins_with("--aparca="):
			g.menu.close()
			g.phase = "free"
			g.traffic.clear()
			g.traffic._spawn_t = 99999.0
			await _frames(20)
			for one in String(arg).trim_prefix("--aparca=").split(";"):
				var at := Vector2(float(one.get_slice(",", 0)), float(one.get_slice(",", 1)))
				for c in g.cars.duplicate():
					if c.p.distance_to(at) < 25.0 and c != g.in_car:
						g.cars.erase(c)
						c.queue_free()
				g.player.p = at + Vector2(6, 6)
				await _frames(10)
				var r0 := MapData.nearest_road(at)
				print("aparca %s: road hw %.1f, room %.2f, u %s, node clr" % [at, r0["seg"].hw, MapData.side_room(r0), r0["u"]])
				for make in ["panda", "z15", "tractor", "yondir", "tunero", "edison", "julietta"]:
					for attempt in range(4):
						var before: int = g.cars.size()
						var c = g._park_near(at, 2.0, make, 0)
						var p0: Vector2 = c.p
						await _frames(75)
						var up: float = c.global_transform.basis.y.dot(MapData.normal(c.p))
						var lift: float = c.global_position.y - MapData.height(c.p)
						if up < 0.9 or lift > float(c.spec["wheel"]) * 1.4 + 0.3 or lift < -0.25:
							print("   %s try %d: ENDS BADLY upright %.2f, %.2f m up, moved %.2f m from %s; walls %.2f m, road edge %.2f" % [make, attempt, up, lift, c.p.distance_to(p0), p0, MapData.room_at(p0), MapData.road_edge_dist(p0)])
						g.cars.erase(c)
						c.queue_free()
						await _frames(3)
				print("aparca %s done" % at)
			get_tree().quit(0)
			return
	if OS.get_cmdline_user_args().has("--tactil"):       # the touch-screen controls: pressed by pretend fingers, and photographed
		shots = true
		var k: float = float(get_window().size.y) / g.get_viewport().get_visible_rect().size.y     # (a finger lands on the window; the controls are laid out in the game's own frame)
		var tap := func(at: Vector2, down: bool, finger := 0) -> void:
			var e := InputEventScreenTouch.new()
			e.index = finger
			e.position = at * k
			e.pressed = down
			Input.parse_input_event(e)
		var slide := func(at: Vector2, finger := 0) -> void:
			var e := InputEventScreenDrag.new()
			e.index = finger
			e.position = at * k
			Input.parse_input_event(e)
		var button := func(action: String) -> Vector2:          # where the button that does this is, now
			Touch._context = ""
			Touch._context_tick()
			for bt in Touch._buttons:
				if bt["action"] == action and (bt["node"] as TouchScreenButton).visible:
					return bt["centre"]
			return Vector2(-999, -999)
		var press := func(action: String, finger: int) -> bool:
			var at: Vector2 = button.call(action)
			if at.x < 0.0:
				return false
			tap.call(at, true, finger)
			await _frames(3)
			tap.call(at, false, finger)
			await _frames(3)
			return true
		await _frames(10)
		# before the main menu (the loading screen, the studio's logo, the title gliding in) there is nothing to press
		var shown_before: Array = []
		var menu_was: bool = g.menu.visible
		g.menu.visible = false
		for ph in ["intro", "title_in", "title"]:
			g.phase = ph
			Touch._context = ""
			Touch._context_tick()
			shown_before.append_array(Touch._buttons.filter(func(bt): return (bt["node"] as TouchScreenButton).visible).map(func(bt): return "%s: %s" % [ph, bt["label"]]))
		g._booted = false
		Touch._context = ""
		Touch._context_tick()
		shown_before.append_array(Touch._buttons.filter(func(bt): return (bt["node"] as TouchScreenButton).visible).map(func(bt): return "loading: %s" % bt["label"]))
		g._booted = true
		g.phase = "title"
		g.menu.visible = menu_was
		_check(shown_before.is_empty(), "on a touch screen no button shows before the main menu: not while it loads, nor over the logo or the title (%s)" % str(shown_before))
		button.call("m_accept")
		await _frames(4)
		await _shot("tactil_menu")
		print("tactil debug menu: phase %s menu %s on %s wanted %s vis %s" % [g.phase, g.menu.visible, Touch.on, Touch._wanted(), Touch._buttons.map(func(bt): return (bt["node"] as TouchScreenButton).visible)])
		var labels: Array = Touch._buttons.filter(func(bt): return (bt["node"] as TouchScreenButton).visible).map(func(bt): return bt["label"])
		var sel0: int = g.menu.sel
		var here := Vector2(330, 420)                 # the stick comes up wherever the finger lands on the left
		tap.call(here, true)
		slide.call(here + Vector2(0, 85))
		await _frames(4)
		tap.call(here + Vector2(0, 85), false)
		await _frames(4)
		_check(Touch.on and g.menu.sel != sel0 and labels.has("Aceptar") and not labels.has("A"),
			"on a touch screen the menu shows words, not pad letters (%s), and a stick put down anywhere on the left goes down it (%d -> %d)" % [str(labels), sel0, g.menu.sel])
		g.menu.close()
		g.set_time(11.0)                        # (by day: at night the game may send you to bed)
		g.set_rain(false, 1e9)
		g.phase = "free"
		g.hud.play_ui.visible = true
		await _frames(20)
		g.phase = "free"
		var was: Vector2 = g.player.p
		tap.call(Vector2(200, 560), true, 1)
		slide.call(Vector2(200, 470), 1)
		await _frames(40)
		var walked: float = g.player.p.distance_to(was)
		await _shot("tactil_andando")
		tap.call(Vector2(200, 470), false, 1)
		var yaw0: float = g.cam_yaw
		tap.call(Vector2(760, 260), true, 2)
		for step in range(6):
			slide.call(Vector2(760 + step * 20, 260), 2)
			await _frames(2)
		tap.call(Vector2(860, 260), false, 2)
		await _frames(2)
		var turned: float = absf(g.cam_yaw - yaw0)
		var jump_at: Vector2 = button.call("handbrake")
		tap.call(jump_at, true, 3)
		await _frames(3)
		var jumped: bool = g.player._hop > 0.0
		tap.call(jump_at, false, 3)
		var foot_labels: Array = Touch._buttons.filter(func(bt): return (bt["node"] as TouchScreenButton).visible).map(func(bt): return bt["label"])
		_check(walked > 1.5 and turned > 0.05 and jumped and foot_labels.has("Saltar") and foot_labels.has("Golpe"),
			"on foot the stick walks (%.1f m), a drag on the right turns the camera (%.2f rad) and the Saltar button jumps (%s) -- buttons: %s" % [walked, turned, jumped, str(foot_labels)])
		await press.call("map", 4)
		await _frames(4)
		var mapped: bool = g.map_open
		await _shot("tactil_mapa")
		await press.call("map", 4)
		await _frames(4)
		_check(mapped and not g.map_open, "the Mapa button opens the big map and closes it again")
		g._enter_car(g.paca_car)
		await _frames(20)
		var at0: Vector2 = g.in_car.p
		tap.call(Vector2(260, 560), true, 5)          # the stick pushed straight up: at the wheel it only steers, so nothing
		slide.call(Vector2(260, 465), 5)
		await _frames(30)
		tap.call(Vector2(260, 465), false, 5)
		var crept: float = g.in_car.p.distance_to(at0)
		var gas: Vector2 = button.call("forward")
		tap.call(gas, true, 6)
		await _frames(90)
		await _shot("tactil_coche")
		var car_labels: Array = Touch._buttons.filter(func(bt): return (bt["node"] as TouchScreenButton).visible).map(func(bt): return bt["label"])
		tap.call(gas, false, 6)
		var went: float = g.in_car.p.distance_to(at0)
		_check(crept < 1.0 and went > 4.0 and car_labels.has("Acelerar") and car_labels.has("Freno") and car_labels.has("Claxon"),
			"in a car the stick only steers (%.1f m with it pushed up), Acelerar drives it (%.1f m), and moving, the other pedal says Freno -- buttons: %s" % [crept, went, str(car_labels)])
		var pedal: Vector2 = button.call("back")           # held down: the car stops, and then backs up
		tap.call(pedal, true, 7)
		await _frames(150)
		Touch._context = ""
		Touch._context_tick()
		var stop_labels: Array = Touch._buttons.filter(func(bt): return (bt["node"] as TouchScreenButton).visible).map(func(bt): return bt["label"])
		var backing: float = g.in_car.forward_speed()
		tap.call(pedal, false, 7)
		_check(backing < -0.5 and stop_labels.has("Atrás") and not stop_labels.has("Freno"), "held down, Freno stops the car and then backs it up, and says so: Atrás (%.1f m/s) -- %s" % [backing, str(stop_labels)])
		# the creator: the same two buttons as its panel
		g.in_car.set_speed(Vector2.ZERO)
		g._exit_car()
		g._start_creator()
		await _frames(10)
		var visible_labels := func() -> Array:
			Touch._context = ""
			Touch._context_tick()
			return Touch._buttons.filter(func(bt): return (bt["node"] as TouchScreenButton).visible).map(func(bt): return bt["label"])
		var on_lustre: Array = visible_labels.call()
		# a finger dragged across the character turns it round; dragged on the panel, it does not
		var turn0: float = g._face_turn
		var mid: Vector2 = g.hud._creator_grab.get_center()
		tap.call(mid, true, 7)
		for s in range(8):
			slide.call(mid + Vector2(18.0 * (s + 1), 0.0), 7)
			await _frames(1)
		tap.call(mid + Vector2(144.0, 0.0), false, 7)
		await _frames(3)
		var drag_turn: float = g._face_turn - turn0
		var turn1: float = g._face_turn
		var on_panel: Vector2 = g.hud.creator_panel.get_global_rect().get_center()
		tap.call(on_panel, true, 7)
		for s in range(8):
			slide.call(on_panel + Vector2(10.0 * (s + 1), 0.0), 7)
			await _frames(1)
		tap.call(on_panel + Vector2(80.0, 0.0), false, 7)
		await _frames(3)
		_check(absf(drag_turn) > 1.0 and absf(g._face_turn - turn1) < 0.05,
			"in the creator a finger dragged across the character turns it round (%.2f rad), and one dragged on the panel does not (%.2f)" % [drag_turn, g._face_turn - turn1])
		var finger := func(c: Control) -> void:       # a finger on one of the panel's buttons
			var at: Vector2 = c.get_global_rect().get_center()
			tap.call(at, true, 6)
			await _frames(3)
			tap.call(at, false, 6)
			await _frames(4)
		await finger.call(g.hud.creator_next)
		var to_pintas: bool = g.creator_tab == 1 and g.phase == "creator"
		var on_pintas: Array = visible_labels.call()
		await finger.call(g.hud.creator_back)
		_check(on_lustre.is_empty() and on_pintas.is_empty() and to_pintas and g.creator_tab == 0 and g.phase == "creator",
			"the creator on a touch screen: its own panel buttons, pressed by a finger (Siguiente to Pintas, one page only; Volver back), and no touch buttons over them %s %s" % [str(on_lustre), str(on_pintas)])
		await _shot("tactil_creador")
		print("TACTIL %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--llegada"):       # where the opening fly-over ends, and what the game opens with
		shots = true
		g.menu.close()
		g.set_time(11.0)
		g.set_rain(false, 1e9)
		g.hud.play_ui.visible = false
		g._start_flyover()
		var last: Array = g._fly_shots[g._fly_shots.size() - 1]
		g.phase = "selfshot"
		g.hud.cine(false)
		g.dlg = null
		for step in [0.0, 0.6, 1.0]:
			g.cam.position = (last[0] as Vector3).lerp(last[1], step)
			g.cam.look_at(last[2])
			await _frames(12)
			await _shot("llegada_%d" % int(step * 10))
		var home_hd = null
		for hd in MapData.houses:
			if hd["id"] == "alemania_5":
				home_hd = hd
		var end2 := Vector2(last[1].x, last[1].z)
		var front_mid: Vector2 = Vector2(home_hd["o"][0], home_hd["o"][1]) + Vector2(home_hd["u"][0], home_hd["u"][1]) * float(home_hd["len"]) / 2.0
		var out2 := Vector2(-float(home_hd["u"][1]), float(home_hd["u"][0]))
		var looks: Vector3 = -g.cam.global_transform.basis.z
		_check((end2 - front_mid).dot(out2) > 2.0 and MapData.room_at(end2) > 0.4 and Vector2(looks.x, looks.z).normalized().dot(-out2) > 0.5,
			"the opening fly-over ends in the street in front of the house you inherit, looking at its front (%.1f m out from it, %.1f m clear of any wall)" % [(end2 - front_mid).dot(out2), MapData.room_at(end2)])
		var picks := {}
		for k in range(40):
			Ambience.entry = ""
			picks[Ambience.entry_tune()] = true
		var radio_tunes := 0
		for st in Ambience.stations:
			radio_tunes += (st["tracks"] as Array).size()
		var only_listed := true
		var names: Array = []
		for path in picks:
			names.append(String(path).get_file().get_basename())
			if not ["El Mancheguito", "Ojalá no te fueras", "Y así arrancó"].any(func(w): return String(path).findn(w) >= 0):
				only_listed = false
		_check(Ambience._stream("entrada", true) != null and picks.size() == 3 and only_listed,
			"the game opens with one of the band marches listed in entrada.txt, not always the same and never any other (%d of the %d on the dial: %s)" % [picks.size(), radio_tunes, str(names)])
		print("LLEGADA %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	for arg in OS.get_cmdline_user_args():                # --vistas=name:x,z,h,tx,tz,th[,fov];... : pictures from anywhere (metres on the map; h over the ground there)
		if String(arg).begins_with("--vistas="):
			shots = true
			g.menu.close()
			g.phase = "free"
			g.hud.play_ui.visible = false
			g.set_time(11.0)
			g.set_rain(false, 1e9)
			for a2 in OS.get_cmdline_user_args():           # (--hora=21.5: at that time of day instead; --recress-abierto: the Recress open again)
				if String(a2).begins_with("--hora="):
					g.set_time(String(a2).trim_prefix("--hora=").to_float())
			if OS.get_cmdline_user_args().has("--recress-abierto"):
				g.recress.sala.set_open(true)
			if OS.get_cmdline_user_args().has("--recress-cerrado"):          # (done up, its glass doors shut)
				g.recress.sala.set_state("cerrado")
			if OS.get_cmdline_user_args().has("--recress-carteles"):         # (the tournament's posters up by its doors)
				g.recress.sala.show_posters(true)
			await _frames(30)
			var vcam := Camera3D.new()
			g.add_child(vcam)
			vcam.current = true
			vcam.fov = 65.0
			for one in String(arg).trim_prefix("--vistas=").split(";"):
				var label: String = one.get_slice(":", 0)
				var v: PackedStringArray = one.get_slice(":", 1).split(",")
				var from := Vector2(float(v[0]), float(v[1]))
				var to := Vector2(float(v[3]), float(v[4]))
				vcam.position = Vector3(from.x, MapData.height(from) + float(v[2]), from.y)
				var look := Vector3(to.x, MapData.height(to) + float(v[5]), to.y)
				if (label.begins_with("pt_") and g.world.petril != null) or (label.begins_with("pz_") and g.world.plaza != null) or (label.begins_with("ml_") and g.world.molino != null) or (label.begins_with("tr_") and g.world.toros != null) or (label.begins_with("cz_") and g.world.calasanz != null):          # (a view named pt_...: in the Petril's own frame, heights from the floor of its square; pz_...: in the Plaza del Ayuntamiento's)
					var pt = g.world.petril if label.begins_with("pt_") else (g.world.plaza if label.begins_with("pz_") else (g.world.molino if label.begins_with("ml_") else (g.world.toros if label.begins_with("tr_") else g.world.calasanz)))        # (ml_...: in the windmill's; tr_...: in the old bullring's; cz_...: in the nursery school's)
					from = pt.spot(float(v[0]), float(v[1]))
					to = pt.spot(float(v[3]), float(v[4]))
					vcam.position = Vector3(from.x, pt.level + float(v[2]), from.y)
					look = Vector3(to.x, pt.level + float(v[5]), to.y)
				vcam.look_at(look)
				vcam.fov = float(v[6]) if v.size() > 6 else 65.0          # (a seventh number: the field of view, as Street View's fov)
				if label.begins_with("pj"):          # (a view named pj...: the player stands at what is looked at, a step this side of it)
					g.player.p = to + (from - to).normalized() * 0.55
				await _frames(12)
				await _shot("vista_%s" % label)
			print("VISTAS OK")
			get_tree().quit(0)
			return
	if OS.get_cmdline_user_args().has("--torre"):         # the communications tower between the Calle de la Cruz and the Virgen de Gracia
		shots = true
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = false
		g.set_time(11.0)
		g.set_rain(false, 1e9)
		await _frames(30)
		var tower = null
		for casa in g.world.casas:
			if casa.id == "central":
				tower = casa
		_check(tower != null and tower.boxes > 150 and tower.get_child_count() > 120, "the communications tower stands on its plot: the building, the shaft on its roof and the lattice mast")
		if tower != null:
			var tcam := Camera3D.new()
			g.add_child(tcam)
			tcam.current = true
			var L: float = tower.length
			var looks: Array = [
				["cruz_este", Vector2(-7.0, 4.0), 1.7, Vector2(L * 0.45, -6.0), 10.0, 80.0],
				["cruz_oeste", Vector2(L + 12.0, 4.5), 1.7, Vector2(L * 0.75, -8.0), 14.0, 80.0],
				["gracia_este", Vector2(-6.0, -17.5), 1.7, Vector2(L * 0.5, -9.0), 11.0, 80.0],
				["gracia_oeste", Vector2(L + 9.0, -18.0), 1.7, Vector2(L * 0.75, -9.0), 15.0, 80.0],
				["lejos", Vector2(L * 0.5 - 30.0, 52.0), 14.0, Vector2(L * 0.6, -8.0), 16.0, 50.0],
				["aire", Vector2(-22.0, -34.0), 30.0, Vector2(L * 0.6, -8.0), 16.0, 55.0],
			]
			for v in looks:
				var from: Vector2 = tower.spot(v[1].x, v[1].y)
				var to: Vector2 = tower.spot(v[3].x, v[3].y)
				tcam.fov = v[5]
				tcam.position = Vector3(from.x, tower.base + float(v[2]), from.y)
				tcam.look_at(Vector3(to.x, tower.base + float(v[4]), to.y))
				await _frames(10)
				await _shot("torre_%s" % v[0])
		print("TORRE %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--acera"):         # the square's side above the Arroyuelo: raised pavement, wall, steps, the steel bridge
		shots = true
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = false
		g.set_time(11.0)
		g.set_rain(false, 1e9)
		await _frames(30)
		var th: Dictionary = MapData.townhall
		var tm := Vector2(th["m"][0], th["m"][1])
		var tu := Vector2(th["u"][0], th["u"][1])
		var tn := Vector2(-tu.y, tu.x)
		var level: float = g.world.plaza.level if g.world.plaza != null else MapData.height(tm)        # (the square's own floor: the ground at the town hall's door is a hand's breadth lower, in the fade of the Arroyuelo's cut)
		var spot := func(un: Vector2, y: float) -> Vector3:
			var w: Vector2 = tm + tu * un.x + tn * un.y
			return Vector3(w.x, level + y, w.y)
		var acam := Camera3D.new()
		g.add_child(acam)
		acam.current = true
		var views: Array = [
			["calle_sur", Vector2(-42.5, 54.0), -0.4, Vector2(-32.0, 34.0), -1.2, 60.0],
			["calle_norte", Vector2(-38.6, -9.0), -0.2, Vector2(-33.5, 22.0), -1.4, 60.0],
			["escalera", Vector2(-45.5, 40.0), -0.3, Vector2(-30.0, 38.0), -0.9, 55.0],
			["esquina", Vector2(-41.5, 12.0), -0.4, Vector2(-31.0, 3.5), -0.6, 55.0],
			["desde_plaza", Vector2(-17.0, 44.0), 1.8, Vector2(-33.0, 36.0), -0.8, 60.0],
			["arriba", Vector2(-33.0, 40.0), 62.0, Vector2(-33.0, 39.9), 0.0, 60.0],
		]
		for wet_now in [false, true]:
			if wet_now:
				g.set_rain(true, 9999.0)
				for k in range(260):
					g._weather_tick(1.0 / 30.0)
			for v in views:
				if wet_now and v[0] != "calle_sur" and v[0] != "arriba":
					continue
				acam.fov = v[5]
				acam.position = spot.call(v[1], v[2])
				acam.look_at(spot.call(v[3], v[4]))
				await _frames(10)
				await _shot("acera_%s%s" % [v[0], "_lluvia" if wet_now else ""])
		# on foot: the levels somebody stands at across the street, the pavement, the steps and the square
		var probe: Array = []
		for un in [Vector2(-39.6, 38.5), Vector2(-36.5, 38.5), Vector2(-34.0, 38.5), Vector2(-31.0, 38.5), Vector2(-29.0, 38.5), Vector2(-33.0, 20.0), Vector2(-25.0, 20.0)]:
			var w: Vector2 = tm + tu * un.x + tn * un.y
			probe.append("%.2f" % (MapData.foot(w) - level))
		print("acera: on foot at street / street steps / pavement / flight / square / pavement / square: ", probe)
		_check(MapData.foot(tm + tu * -34.0 + tn * 20.0) - level < -0.9 and MapData.foot(tm + tu * -34.0 + tn * 20.0) - MapData.height(tm + tu * -39.6 + tn * 20.0) > 0.6
			and absf(MapData.foot(tm + tu * -25.0 + tn * 20.0) - level) < 0.05,
			"beside the square the Arroyuelo runs well below it: a raised pavement above the street, and the square above that")
		print("ACERA %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--candidatos"):    # the models being tried out, as they come, each on its own
		shots = true
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = false
		g.set_time(11.0)
		await _frames(20)
		var cup := 400.0
		var cground := MeshInstance3D.new()
		var cplane := PlaneMesh.new()
		cplane.size = Vector2(120, 120)
		cground.mesh = cplane
		var cgm := StandardMaterial3D.new()
		cgm.albedo_color = Color(0.56, 0.57, 0.6)
		cground.material_override = cgm
		cground.position = Vector3(0, cup, 0)
		g.add_child(cground)
		var ccam2 := Camera3D.new()
		g.add_child(ccam2)
		ccam2.fov = 30.0
		ccam2.current = true
		var folder := "sk" if OS.get_cmdline_user_args().has("--sk") else "pp"
		var dir := DirAccess.open("res://assets/vehiculos/" + folder)
		var names: Array = []
		for f in dir.get_files():
			if f.ends_with(".glb"):
				names.append(f.get_basename())
		names.sort()
		for nm in names:
			var holder := Node3D.new()
			g.add_child(holder)
			var inst: Node3D = (load("res://assets/vehiculos/%s/%s.glb" % [folder, nm]) as PackedScene).instantiate()
			holder.add_child(inst)
			var box := AABB()
			var first := true
			var stack: Array = [inst]
			while not stack.is_empty():
				var n: Node = stack.pop_back()
				for c in n.get_children():
					stack.append(c)
				if n is MeshInstance3D:
					var b: AABB = (inst.global_transform.affine_inverse() * (n as MeshInstance3D).global_transform) * (n as MeshInstance3D).mesh.get_aabb()
					box = b if first else box.merge(b)
					first = false
			var k: float = 4.0 / maxf(box.size.x, box.size.z)
			inst.scale = Vector3.ONE * k
			inst.position = -Vector3(box.position.x + box.size.x / 2.0, box.position.y, box.position.z + box.size.z / 2.0) * k
			holder.position = Vector3(0, cup, 0)
			print("candidato %s: size %s (x%.3f), longest along %s" % [nm, box.size, k, "x" if box.size.x > box.size.z else "z"])
			for view in range(2):
				holder.rotation.y = 0.75 + view * PI
				ccam2.position = Vector3(0, cup + 3.6, 11.0)
				ccam2.look_at(Vector3(0, cup + 0.8, 0))
				await _frames(4)
				await _shot("cand_%s_%d" % [nm, view])
			holder.queue_free()
			await _frames(2)
		print("CANDIDATOS OK")
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--coches"):        # every car as it is now beside the bought-in model that would replace it
		shots = true
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = false
		g.set_time(11.0)
		await _frames(20)
		var Modelos = load("res://scripts/modelos.gd")
		var up := 400.0                     # a clean floor, well above the town
		var ground := MeshInstance3D.new()
		var plane := PlaneMesh.new()
		plane.size = Vector2(120, 120)
		ground.mesh = plane
		var gm := StandardMaterial3D.new()
		gm.albedo_color = Color(0.56, 0.57, 0.6)
		gm.roughness = 1.0
		ground.material_override = gm
		ground.position = Vector3(0, up, 0)
		g.add_child(ground)
		var slab := StaticBody3D.new()
		var slab_shape := CollisionShape3D.new()
		var slab_box := BoxShape3D.new()
		slab_box.size = Vector3(120, 1, 120)
		slab_shape.shape = slab_box
		slab.add_child(slab_shape)
		slab.position = Vector3(0, up - 0.5, 0)
		g.add_child(slab)
		var who := {"shirt": 0xb5462f, "skin": 0xe9b58c, "hair": 0x2a1c14, "hat": "beret"}
		var scam := Camera3D.new()
		g.add_child(scam)
		scam.fov = 30.0
		scam.current = true
		var stage: Array = []
		var old_first := [not OS.get_cmdline_user_args().has("--juego")]     # (--juego: the first column is the car as the game now has it)
		var pick := [false]                 # take the next model from the closer set: Poly Pizza's, or with --sk Sketchfab's
		var closer: Dictionary = Modelos.SK if OS.get_cmdline_user_args().has("--sk") else Modelos.CLOSER
		var one := func(kind: String, hex: int, x: float, turn: float, old: bool) -> void:
			var node: Node3D
			if old:
				var c = CarS.new()
				g.add_child(c)
				CarS.old_look = old_first[0]
				c.setup(kind, hex, Vector2(900, 900), 0.0)
				CarS.old_look = false
				c.set_physics_process(false)
				c.seat(who, 0)
				node = c
			else:
				node = Modelos.make_from(closer, kind, CarS.SPECS[kind], hex) if pick[0] else Modelos.make(kind, CarS.SPECS[kind], hex)
				g.add_child(node)
				var sits: Node3D = CarS.rider(who, true, float(node.get_meta("rider", CarS.RIDER)))
				sits.position = node.get_meta("seat")
				node.add_child(sits)
			node.global_position = Vector3(x, up + (0.25 if old else 0.0), 0)
			node.rotation = Vector3(0, turn, 0)
			stage.append(node)
		var solo: Array = []                # --solo=tunero,grua photographs only those
		for arg in OS.get_cmdline_user_args():
			if String(arg).begins_with("--solo="):
				solo = String(arg).trim_prefix("--solo=").split(",")
		for kind in ["panda", "z15", "tractor", "yondir", "tunero", "edison", "julietta", "grua", "tricornio", "pitufo"]:
			if not solo.is_empty() and not (kind in solo):
				continue
			var sp: Dictionary = CarS.SPECS[kind]
			var gap: float = float(sp["len"]) * 0.52 + 0.7
			var far: float = float(sp["len"]) * 3.3 + 4.0
			for view in range(2):
				var turn: float = 0.75 if view == 0 else PI + 0.75        # from the front, then from behind
				one.call(kind, sp["colors"][0], -gap * 2.0, turn, true)
				one.call(kind, sp["colors"][0], 0.0, turn, false)
				if closer.has(kind):
					pick[0] = true
					one.call(kind, sp["colors"][0], gap * 2.0, turn, false)
					pick[0] = false
				scam.position = Vector3(0, up + far * 0.3, far)
				scam.look_at(Vector3(0, up + 0.9, 0))
				await _frames(50)
				await _shot("coches_%s_%d" % [kind, view])
				for n in stage:
					n.queue_free()
				stage.clear()
				await _frames(2)
		# the colours: each car that comes in more than one, in all of them
		for kind in ["panda", "tunero", "julietta", "edison", "z15", "tractor"]:
			if not solo.is_empty() and not (kind in solo):
				continue
			var cols: Array = CarS.SPECS[kind]["colors"]
			var step: float = float(CarS.SPECS[kind]["wid"]) + 1.0
			pick[0] = closer.has(kind)
			for k in range(cols.size()):
				one.call(kind, cols[k], (k - (cols.size() - 1) / 2.0) * step, 0.6, false)
			var wide: float = step * cols.size()
			scam.position = Vector3(0, up + 2.0 + wide * 0.2, 3.5 + wide * 1.08)
			scam.look_at(Vector3(0, up + 0.7, 0))
			await _frames(6)
			await _shot("coches_colores_%s" % kind)
			for n in stage:
				n.queue_free()
			stage.clear()
			await _frames(2)
		print("COCHES OK")
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--nuevo"):         # the testers' list: home in Calle de Alemania, drivers in the cars
		shots = true
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = false
		await _frames(40)
		await _shot("nuevo_casa")
		var views: Array = []
		g._enter_car(g.paca_car)
		g.paca_car.seat(g.named["maruja"].look, 1)
		views.append(g.paca_car)
		for e in g.traffic.list.slice(0, 2):
			views.append(e["car"])
		for vi in range(views.size()):
			var c = views[vi]
			var f := Vector2(sin(c.h), cos(c.h))
			var eye: Vector2 = c.p + f * 5.2 + Vector2(f.y, -f.x) * 2.6
			var cam := Camera3D.new()
			g.add_child(cam)
			cam.fov = 40.0
			cam.position = Vector3(eye.x, MapData.height(c.p) + 2.1, eye.y)
			cam.look_at(Vector3(c.p.x, MapData.height(c.p) + 1.3, c.p.y))
			cam.current = true
			await _frames(4)
			await _shot("nuevo_coche_%d" % (vi + 1))
			cam.queue_free()
		_tester_checks()
		# the steel bridge, dry and in the rain; La Chiki
		for wet_now in [false, true]:
			g.set_rain(wet_now, 9999.0)
			for k in range(260):
				g._weather_tick(1.0 / 30.0)
			var bp: Vector2 = g.pasarela.p
			var bcam := Camera3D.new()
			g.add_child(bcam)
			bcam.fov = 55.0
			var from: Vector2 = bp - g.pasarela.u * 13.0 - g.pasarela.across * 3.0
			var aim: Vector2 = bp + g.pasarela.u * 3.0 + g.pasarela.across * 2.5
			bcam.position = Vector3(from.x, MapData.height(bp) + 3.6, from.y)
			bcam.look_at(Vector3(aim.x, MapData.height(bp) + 1.2, aim.y))
			bcam.current = true
			await _frames(20)
			await _shot("nuevo_pasarela_%s" % ("lluvia" if wet_now else "seco"))
			if wet_now:         # and from straight above, to see where it stands
				print("pasarela: p %s base %s u %s across %s half %.1f" % [bp, g.pasarela.base, g.pasarela.u, g.pasarela.across, g.pasarela.half])
				bcam.fov = 60.0
				bcam.position = Vector3(bp.x, MapData.height(bp) + 55.0, bp.y)
				bcam.rotation = Vector3(-PI / 2.0, 0, 0)
				await _frames(6)
				await _shot("nuevo_pasarela_arriba")
			bcam.queue_free()
		g.set_rain(false)
		var ck = g.named["chiki"]
		var ccam := Camera3D.new()
		g.add_child(ccam)
		ccam.fov = 30.0
		var cf := Vector2(sin(ck.h), cos(ck.h))
		ccam.position = Vector3(ck.p.x + cf.x * 4.2, MapData.height(ck.p) + 1.3, ck.p.y + cf.y * 4.2)
		ccam.look_at(Vector3(ck.p.x, MapData.height(ck.p) + 1.0, ck.p.y))
		ccam.current = true
		ck.visible = true
		await _frames(8)
		await _shot("nuevo_chiki")
		ccam.queue_free()
		print("NUEVO %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--creator"):       # the character creator: its two tabs, and the newer choices on a face
		shots = true
		g.menu.close()
		g.look_sel = load("res://scripts/creator.gd").defaults()
		g._start_creator()
		await _frames(40)
		await _shot("creator_1")
		g.look_sel[8] = 5; g.look_sel[19] = 2; g.look_sel[0] = 2; g.look_sel[1] = 5; g.look_sel[13] = 6; g.look_sel[4] = 1
		g._creator_input("tab")
		await _frames(12)
		await _shot("creator_2")
		g.look_sel[0] = 0; g.look_sel[19] = 1; g.look_sel[9] = 1; g.look_sel[8] = 0
		g._creator_input("down")
		await _frames(12)
		await _shot("creator_3")
		Controls.pad = true                      # the same with a pad in your hands
		Controls.device_changed.emit()
		await _frames(12)
		await _shot("creator_4_mando")
		Controls.pad = false
		Controls.device_changed.emit()
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--casas"):         # the houses built by hand: each from the front, from both ends, close to, and from above
		shots = true
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = false
		await _frames(20)
		var solo := PackedStringArray()                       # --solo=real_,madrid_ : only the houses whose names begin so, each from the front and from one side
		for arg in OS.get_cmdline_user_args():
			if String(arg).begins_with("--solo="):
				solo = String(arg).trim_prefix("--solo=").split(",", false)
		for casa in g.world.casas:
			if not solo.is_empty() and not Array(solo).any(func(pre): return String(casa.id).begins_with(pre)):
				continue
			var L: float = casa.length
			var back := clampf(L * 0.55 + 3.0, 7.5, 13.0)         # (far enough to take in the whole front; the camera may stand inside the house opposite)
			var views := [[Vector3(L / 2.0, 1.6, back), Vector3(L / 2.0, casa.top * 0.5, 0.0), 70.0]]
			if not solo.is_empty():
				views.append([Vector3(L + 3.5, 1.6, 5.2), Vector3(L * 0.4, casa.top * 0.42, 0.0), 72.0])
			if casa.id == "alemania_7":
				views.append_array([[Vector3(L + 7.0, 1.6, 4.2), Vector3(L / 2.0, 3.2, 0.0), 62.0], [Vector3(L - 4.2, 1.6, 3.4), Vector3(L - 1.7, 1.5, -1.0), 60.0]])
			for vi in range(views.size()):
				var cam := Camera3D.new()
				g.add_child(cam)
				cam.fov = views[vi][2]
				cam.near = maxf(0.05, (views[vi][0] as Vector3).z - 3.1)      # (...so what is behind it is not drawn)
				cam.global_position = casa.to_global(views[vi][0])
				cam.look_at(casa.to_global(views[vi][1]))
				cam.current = true
				await _frames(6)
				await _shot("casa_%s_%d" % [casa.id, vi + 1])
				cam.queue_free()
			print("casa %s: %d pieces" % [casa.id, casa.boxes])
		_casas_checks()
		print("CASAS %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--alemania"):      # Calle de Alemania, walked as in the video it was drawn from
		shots = true
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = false
		await _frames(20)
		var line: Array[Vector2] = [Vector2(78.3, -303.1), Vector2(72.5, -296.0), Vector2(54.1, -235.6), Vector2(20.3, -159.6)]
		var views := [[0.5, 0.0, 12.0], [6.0, 0.9, 7.0], [14.0, 0.9, 7.0], [24.0, 0.9, 7.0], [34.0, 0.9, 7.0], [44.0, 0.9, 7.0], [56.0, 0.9, 7.0],
			[8.0, -0.9, 7.0], [28.0, -0.9, 7.0], [44.0, -0.9, 7.0], [58.0, -0.9, 7.0], [76.0, 0.9, 7.0], [90.0, 0.9, 7.0], [80.0, -0.9, 7.0], [92.0, -0.9, 7.0],
			[20.0, 0.0, 30.0], [70.0, 0.0, 30.0]]
		for vi in range(views.size()):
			var s: float = views[vi][0]
			var dir: Vector2 = (line[1] - line[0]).normalized()
			var at: Vector2 = (line[0] + dir * s) if s < 0.0 else line[0]
			var left := s
			if s >= 0.0:
				for k in range(line.size() - 1):
					var seg: float = line[k].distance_to(line[k + 1])
					dir = (line[k + 1] - line[k]).normalized()
					if left <= seg or k == line.size() - 2:
						at = line[k] + dir * left
						break
					left -= seg
			var side: Vector2 = Vector2(-dir.y, dir.x)            # to the walker's right (the odd numbers)
			var look_to: float = views[vi][1]
			var cam := Camera3D.new()
			g.add_child(cam)
			cam.fov = 62.0
			var eye: Vector2 = at - side * look_to * 2.6
			var gy: float = MapData.height(eye)
			if look_to == 0.0:                            # down the street, as the walker saw it (or from above it)
				cam.position = Vector3(eye.x, gy + (1.7 if views[vi][2] < 20.0 else 16.0), eye.y)
				cam.look_at(Vector3(eye.x + dir.x * views[vi][2], gy + (3.5 if views[vi][2] < 20.0 else 2.0), eye.y + dir.y * views[vi][2]))
			else:                                         # facing a front from across the street
				cam.position = Vector3(eye.x, gy + 1.7, eye.y)
				var to: Vector2 = at + side * look_to * 6.0 + dir * 1.5
				cam.look_at(Vector3(to.x, gy + 3.6, to.y))
			cam.current = true
			await _frames(6)
			await _shot("alemania_%02d" % (vi + 1))
			cam.queue_free()
		_looks_checks()
		print("alemania: %d looks, fronts dressed %s" % [MapData.looks.size(), str(g.world.look_fronts)])
		print("ALEMANIA %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--grua"):          # the tow truck as the full run has it: called from far off (add --traza for where it gets to)
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = true
		await _frames(20)
		for a in OS.get_cmdline_user_args():          # (--desde=x,z: the truck sets out from the corner nearest there)
			if a.begins_with("--desde="):
				var xz: PackedStringArray = a.substr(8).split(",")
				g.tow.force_from = Vector2(float(xz[0]), float(xz[1]))
		if OS.get_cmdline_user_args().has("--antes"):        # (what the full run does just before: the skids, Kebab Luis, eating)
			await _derrape_checks()
			await _kebab_checks()
			await _comida_checks()
		if OS.get_cmdline_user_args().has("--servicio"):    # (just the vehicles on a job running people over)
			await _duty_checks()
		else:
			await _tow_checks()
		print("GRUA %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--tow"):           # just the breakdown and the tow truck
		shots = true
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = true
		await _frames(20)
		await _tow_checks(true)
		print("TOW %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	for a in OS.get_cmdline_user_args():                  # --ruedas=kind: each wheel of the model, its points and its size (to find a broken one)
		if a.begins_with("--ruedas="):
			var rc = CarS.new()
			g.add_child(rc)
			rc.setup(a.substr(9), 0, g.player.p, 0.0)
			for w in rc.model.get_meta("wheels"):
				var verts := 0
				for s in range(w.mesh.get_surface_count()):
					verts += (w.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
				print("rueda %s: %d points, size %s, at %s" % [w.name, verts, str(w.mesh.get_aabb().size), str(w.position)])
			get_tree().quit(0)
			return
	for a in OS.get_cmdline_user_args():                  # --vidrios=kind: the colours of the texture over the top half of its bodywork (to find its windows)
		if a.begins_with("--vidrios="):
			var vk := a.substr(10)
			var vc = CarS.new()
			g.add_child(vc)
			vc.setup(vk, 0, g.player.p, 0.0)
			var tall_y: float = vc.model.get_meta("size").y
			var tally := {}
			for mi in vc.model.get_children():
				if not (mi is MeshInstance3D) or String(mi.name).begins_with("wheel"):
					continue
				var mesh: Mesh = mi.mesh
				for s in range(mesh.get_surface_count()):
					var arr: Array = mesh.surface_get_arrays(s)
					var mat = mesh.surface_get_material(s)
					if not (mat is StandardMaterial3D) or mat.albedo_texture == null or arr[Mesh.ARRAY_TEX_UV] == null:
						continue
					var img: Image = mat.albedo_texture.get_image()
					if img.is_compressed():
						img.decompress()
					var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
					var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
					var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(vs.size()))
					for t in range(0, idx.size() - 2, 3):
						var cy: float = ((mi.transform * vs[idx[t]]).y + (mi.transform * vs[idx[t + 1]]).y + (mi.transform * vs[idx[t + 2]]).y) / 3.0
						var area: float = ((mi.transform * vs[idx[t + 1]]) - (mi.transform * vs[idx[t]])).cross((mi.transform * vs[idx[t + 2]]) - (mi.transform * vs[idx[t]])).length() / 2.0
						var c: Vector2 = (uv[idx[t]] + uv[idx[t + 1]] + uv[idx[t + 2]]) / 3.0
						var px: Color = img.get_pixel(clampi(int(fposmod(c.x, 1.0) * img.get_width()), 0, img.get_width() - 1), clampi(int(fposmod(c.y, 1.0) * img.get_height()), 0, img.get_height() - 1))
						var key := "%02x%02x%02x %s" % [int(px.r * 15) * 17, int(px.g * 15) * 17, int(px.b * 15) * 17, "high" if cy > tall_y * 0.6 else "low"]
						tally[key] = float(tally.get(key, 0.0)) + area
			var keys: Array = tally.keys()
			keys.sort_custom(func(x, y): return tally[x] > tally[y])
			print("vidrios %s: %s" % [vk, ", ".join(keys.slice(0, 16).map(func(k): return "%s %.2f m2" % [k, tally[k]]))])
			get_tree().quit(0)
			return
	if OS.get_cmdline_user_args().has("--bate"):          # Henry's bat swung at a neighbour, in pictures (with --window)
		shots = true
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = false
		g.set_time(11.0)
		g.stats["menu_done"] = true
		var street := _long_street()
		var su: Vector2 = street["u"]
		var sn := Vector2(-su.y, su.x)
		g.player.p = street["p"]
		g.player.h = atan2(su.x, su.y)
		g.player.sync()
		var victim = g.spawn_neighbour(street["p"] + su * 1.3, true)
		victim.h = atan2(-su.x, -su.y)
		victim.sync()
		await _frames(20)
		g.cam_fixed = [MapData.at(street["p"] + su * 0.6 + sn * 4.2, 1.6), MapData.at(street["p"] + su * 0.6, 1.0)]
		await _frames(20)
		g._punch_cool = 0.0
		Engine.time_scale = 0.05                     # (slowed right down: a picture takes longer to save than the swing lasts)
		g._punch()
		for i in range(5):
			await get_tree().create_timer(0.12).timeout
			await RenderingServer.frame_post_draw          # (straight away: _shot waits two-thirds of a second first)
			get_viewport().get_texture().get_image().save_png("res://shots/bate_%d.png" % i)
		Engine.time_scale = 1.0
		await _frames(30)
		await _shot("bate_5_suelo")
		print("BATE %s" % victim.state)
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--pintadas"):      # La Chiki and the walls of the peñas
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = true
		await _frames(20)
		await _pintadas_checks()
		print("PINTADAS %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--titulo"):        # the title screen, as after the loading screen (add --shots, with --window)
		shots = OS.get_cmdline_user_args().has("--shots")
		await _titulo_checks(shots)
		print("TITULO %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--pausa"):         # just the pause: the car stops where it is, the sound waits, and both go on afterwards
		g.menu.close()
		g.phase = "free"
		g.hud.play_ui.visible = true
		await _frames(20)
		g._enter_car(g.paca_car)
		var pc = g.in_car
		Ambience.station = 1
		await _frames(30)
		pc.set_speed(Vector2(sin(pc.h), cos(pc.h)) * 6.0)
		var at0: Vector3 = pc.global_position
		g._open_pause()
		await _frames(20)
		var radio_waits: bool = Ambience._players.any(func(p): return p.stream_paused) and not Ambience._players.any(func(p): return p.playing and not p.stream_paused)
		_check(pc.global_position.distance_to(at0) < 0.2 and Sfx.held() and radio_waits, "paused: the car stays put (%.2f m), the engine and the radio wait" % pc.global_position.distance_to(at0))
		g._close_pause()
		await _frames(10)
		_check(pc.global_position.distance_to(at0) > 0.2 and not Sfx.held() and Ambience._players.any(func(p): return p.playing and not p.stream_paused), "resumed: the car rolls on (%.1f m) and the radio plays on" % pc.global_position.distance_to(at0))
		# the big map stops the world as the pause does, and is zoomed and moved about
		pc.set_speed(Vector2(sin(pc.h), cos(pc.h)) * 6.0)
		var at1: Vector3 = pc.global_position
		g._set_map(true)
		g._map_zoom(3.0)
		Input.action_press("right")
		await _frames(20)
		Input.action_release("right")
		var mm = g.hud.bigmap
		_check(g.map_open and pc.global_position.distance_to(at1) < 0.2 and Sfx.held() and is_equal_approx(mm.zoom, 3.0) and mm.pan.x > 10.0,
			"the big map stops the world (%.2f m), zooms in (x%.1f) and moves with the stick (%.0f m east)" % [pc.global_position.distance_to(at1), mm.zoom, mm.pan.x])
		g._set_map(false)
		await _frames(10)
		_check(not g.map_open and not Sfx.held() and pc.global_position.distance_to(at1) > 0.2, "closed, the world goes on")
		# developer mode: off unless switched on; then its page in the pause menu, and what it does
		var plain_pause: bool = not g._menu_page("pause")["items"].any(func(it): return it["text"] == Loc.t("m_dev"))
		Settings.data["dev"] = true
		var dev_in_pause: bool = g._menu_page("pause")["items"].any(func(it): return it["text"] == Loc.t("m_dev"))
		var cash: int = g.money
		g._dev_money()
		g._dev_heat()
		g.police.add_heat(50.0)
		var calm: bool = g.police.heat == 0.0
		g._dev_heat()
		g._dev_minigames()
		var all_games: bool = g.Missions.MINIGAMES.keys().all(func(id): return g.unlocked.has(id))
		var jumps: int = g._menu_page("dev_missions")["items"].size()
		g._dev_fps()
		await _frames(3)
		var fps_shown: bool = g.hud.fps_label.visible and g.hud.fps_label.text.ends_with("FPS")
		g._dev_fps()
		Settings.data["dev"] = false
		_check(plain_pause and dev_in_pause and g.money == cash + 1000 and calm and all_games and jumps >= 5 and fps_shown,
			"developer mode: not in the pause menu unless switched on; then money, no police, every minigame, the FPS and a jump to any of the %d missions" % (jumps - 1))
		print("PAUSA %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
		get_tree().quit(1 if fails > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--conductores"):   # every make with you at the wheel, and its collision box drawn over it (--solo=kind)
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		g.apply_moment("noon", true)
		var street := _long_street()
		var su: Vector2 = street["u"]
		var sn := Vector2(-su.y, su.x)
		var base: Vector2 = street["p"]
		var only := ""
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--solo="):
				only = a.substr(7)
		for kind in CarS.SPECS.keys():
			if only != "" and kind != only:
				continue
			var c = CarS.new()
			g.add_child(c)
			c.setup(kind, 0, base, atan2(su.x, su.y))
			c.park()
			var lk: Dictionary = Creator.look(g.look_sel)
			lk["hat"] = "cap"                            # (the tallest you can be: in a cap)
			c.seat(lk)
			var ghost := MeshInstance3D.new()           # the collision box, see-through
			for k in c.get_children():
				if k is CollisionShape3D and k.shape is BoxShape3D:
					var bm := BoxMesh.new()
					bm.size = k.shape.size
					ghost.mesh = bm
					ghost.position = k.position
				elif k is CollisionShape3D:                   # (a shape of its own: its edges)
					ghost.mesh = k.shape.get_debug_mesh()
					ghost.position = k.position
			var gm := StandardMaterial3D.new()
			gm.albedo_color = Color(1.0, 0.1, 0.6, 0.28)
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			ghost.material_override = gm
			c.add_child(ghost)
			await _frames(20)
			var L: float = c.spec["len"]
			for v in [["lado", sn * 6.5 + su * 0.0, 1.3, 0.0, 0.9], ["tres_cuartos", sn * 4.2 + su * (L * 0.9), 1.9, 0.0, 0.9], ["arriba", sn * 0.01 + su * 0.0, 9.0, 0.0, 0.0], ["dentro", sn * 2.2 + su * 0.4, 1.6, -0.2, 1.1], ["detras", -su * (L / 2.0 + 4.6), 2.5, 1.0, 1.0]]:
				ghost.visible = v[0] == "arriba" or v[0] == "tres_cuartos"
				g.cam.position = MapData.at(base + v[1], v[2])
				g.cam.look_at(MapData.at(base + su * v[3], v[4]), Vector3.UP if v[0] != "arriba" else Vector3(su.x, 0, su.y))
				await _frames(4)
				await _shot("coche_%s_%s" % [kind, v[0]])
			print("coche %s: collision %s, model %s, rider %s" % [kind, str(ghost.mesh.get_aabb().size), str(c.model.get_meta("size") if c.model != null else "-"), str(c.model.get_meta("rider") if c.model != null else "-")])
			c.queue_free()
			await _frames(4)
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--garage"):        # just the new models: cars in a row, a trailer, a row of neighbours, the creator
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		g.apply_moment("noon", true)
		var street := _long_street()
		var su: Vector2 = street["u"]
		var sn := Vector2(-su.y, su.x)
		var base: Vector2 = street["p"]
		var row := ["tractor", "yondir", "edison", "julietta", "z15", "panda", "grua"]
		var parked: Array = []
		for i in range(row.size()):
			var c = CarS.new()
			g.add_child(c)
			c.setup(row[i], [0, 0, 0x1f1f24, 0xd42027, 0xc9ced3, 0xef7f1a, 0][i], base + su * (i * 6.2 - 15.0), atan2(sn.x, sn.y))
			c.park()
			parked.append(c)
		await _frames(30)
		for v in [["all", 2.0, 17.0, 5.5, 0.0, 0.0, 1.0], ["tractors", -11.5, 8.5, 2.6, -12.0, 0.0, 1.5], ["hebro", -18.5, 5.0, 2.4, -15.0, 0.0, 1.3], ["yondir_back", -5.0, -6.5, 3.0, -8.8, 0.0, 1.6], ["edison", 1.0, 6.5, 1.9, -2.6, 0.0, 0.9], ["julietta", 8.0, 6.0, 1.8, 3.6, 0.0, 0.8], ["julietta_back", 0.5, -5.5, 2.4, 3.6, 0.0, 0.8], ["grua", 27.0, 8.0, 2.6, 22.2, 0.0, 1.3], ["grua_back", 17.0, -7.5, 3.0, 22.2, 0.0, 1.4]]:
			var from: Vector2 = base + su * v[1] + sn * v[2]
			var at: Vector2 = base + su * v[4] + sn * v[5]
			g.cam.position = MapData.at(from, v[3])
			g.cam.look_at(MapData.at(at, v[6]))
			await _shot("garage_" + v[0])
		for c in parked:                                  # start them all: smoke
			c.drive(1.0, 0.0, true, true, 0.016)
		await _frames(26)
		g.cam.position = MapData.at(base + su * 2.0 + sn * 15.0, 5.0)
		g.cam.look_at(MapData.at(base, 1.5))
		await _shot("garage_smoke")
		for c in parked:
			c.queue_free()
		var tr: Dictionary = g.props.ramps[0]
		var tf := Vector2(sin(tr["h"]), cos(tr["h"]))
		var tfrom: Vector2 = tr["p"] - tf * 9.0 + Vector2(-tf.y, tf.x) * 7.0
		g.cam.position = MapData.at(tfrom, 3.2)
		g.cam.look_at(MapData.at(tr["p"], 0.8))
		await _shot("garage_trailer")
		var folk: Array = []
		for i in range(20):
			var n = g.spawn_neighbour(base + su * ((i % 10) * 1.25 - 5.6) + sn * (3.0 - (i / 10) * 1.6), true)
			n.h = atan2(sn.x, sn.y)
			n.sync()
			folk.append(n)
		await _frames(5)
		for v in [["folk", 0.0, 10.5, 2.3], ["folk_left", -3.0, 7.6, 1.7], ["folk_right", 3.0, 7.6, 1.7]]:
			var from: Vector2 = base + su * v[1] + sn * v[2]
			g.cam.position = MapData.at(from, v[3])
			g.cam.look_at(MapData.at(base + su * v[1] + sn * 2.4, 1.0))
			await _shot("garage_" + v[0])
		print("draw calls: ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "  objects: ", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--coop"):          # just the cooperative, from the angles of the reference photos
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		g.apply_moment("noon", true)
		var loli = g.named["loli"]                 # turn her to the street, to see the cap
		var street: Vector2 = MapData.coop_point(float(MapData.coop["gate"]) - 4.9, 5.0) - loli.p
		loli.h = atan2(street.x, street.y)
		loli.sync()
		var G: float = MapData.coop["gate"]
		var views := [["gate_close", G + 1.2, 4.4, 1.6, G + 1.4, 9.6, 1.45], ["cap", G - 4.9, 6.3, 1.75, G - 4.9, 8.2, 1.6], ["gate", G - 9.0, -3.0, 2.2, G + 1.0, 12.0, 2.0],
			["north", G - 12.0, 1.0, 2.6, G + 20.0, 22.0, 3.5], ["mill", 96.0, 12.0, 2.4, 100.0, 42.0, 3.5], ["name_shed", 66.0, 2.0, 2.2, 67.0, 37.0, 4.5],
			["open_shed", 56.0, 2.0, 2.4, 36.0, 18.0, 5.0], ["winery", 12.0, 0.0, 2.2, 30.0, 34.0, 4.0], ["transformer", 0.5, -1.0, 2.0, 0.5, 9.6, 2.0],
			["hoppers", 106.0, 14.0, 2.4, 121.0, 26.0, 6.0], ["above", 70.0, -80.0, 110.0, 70.0, 55.0, 0.0], ["yard", 62.0, 28.0, 14.0, 40.0, 60.0, 5.0]]
		views.append(["gate_open", G - 7.0, -1.0, 2.4, G + 2.0, 16.0, 1.5])
		for v in views:
			if v[0] == "gate_open":
				g.world.coop.gate_open = true
				for i in range(300):
					g.world.coop.tick(0.02)
			var from: Vector2 = MapData.coop_point(v[1], v[2])
			var at: Vector2 = MapData.coop_point(v[4], v[5])
			g.cam.position = MapData.at(from, v[3])
			g.cam.look_at(MapData.at(at, v[6]))
			await _shot("coop_" + v[0])
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--lights"):        # the sky and the lamps through the day: three views at each hour, then quit
		shots = true
		g.menu.close()
		g.phase = "selfshot"
		g.hud.play_ui.visible = false
		var hall: Dictionary = MapData.townhall
		var hm := Vector2(hall["m"][0], hall["m"][1])
		var hu := Vector2(hall["u"][0], hall["u"][1])
		var hn := Vector2(-hu.y, hu.x)
		var st: Vector2 = g.places["henry"]["p"]
		var su2: Vector2 = g.places["henry"]["u"]
		var lit_car = CarS.new()
		g.add_child(lit_car)
		lit_car.setup("z15", 0, st - su2 * 14.0, atan2(su2.x, su2.y))
		g.traffic.list.append({"car": lit_car, "a": 0, "b": 0, "wait": 0.0, "honk": 0.0, "lat": 1.0, "stuck": 0.0, "rev": 0.0, "rs": 1.0, "tries": 0})
		for hour in [9.5, 13.0, 19.6, 20.8, 21.6, 23.5]:
			g.set_time(hour)
			for view in [["sky", hm + hn * 60.0 + hu * 10.0, 6.0, hm + hn * 10.0, 34.0], ["plaza", hm + hn * 34.0 + hu * 4.0, 13.0, hm, 5.0], ["street", st - su2 * 24.0 + Vector2(-su2.y, su2.x) * 1.5, 2.4, st + su2 * 6.0, 2.2]]:
				var from: Vector2 = view[1]
				var at: Vector2 = view[3]
				g.cam.position = MapData.at(from, view[2])
				g.cam.look_at(MapData.at(at, view[4]))
				g.player.p = at                                  # (the lights and the birds keep to wherever you are)
				g.sky_fx.tick(0.016, g.cam.global_position, at)
				g.lights._t = 0.0
				g.lights.tick(0.016, at)
				await _shot("light_%04.1f_%s" % [hour, view[0]])
		print("lanterns: ", g.lights.spots.size(), "  draw calls: ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		get_tree().quit(0)
		return
	await _shot("0_title")
	# the Plaza del Ayuntamiento
	_check(not MapData.townhall.is_empty() and g.world._hands.size() == 5, "the town hall is hand-built and carries the town clock (and the four faces of the church tower keep time with it)")
	await _plaza_checks()
	await _molino_checks()
	await _toros_checks()
	await _arroyuelo_checks()
	await _calasanz_checks()
	var th: Dictionary = MapData.townhall
	var th_m := Vector2(th["m"][0], th["m"][1])
	var th_u := Vector2(th["u"][0], th["u"][1])
	var th_n := Vector2(-th_u.y, th_u.x)
	g.menu.close()
	for view in [["9a_plaza_front", th_m + th_n * 34.0 + th_u * 4.0, 13.0, th_m, 5.0], ["9b_plaza_arcade", th_m + th_n * 7.0 - th_u * 24.0, 2.6, th_m + th_u * 8.0 - th_n * 1.0, 3.0],
			["9c_plaza_lawn", th_m + th_n * 34.0 - th_u * 4.0, 5.0, th_m + th_n * 48.5 + th_u * 9.0, 3.0], ["9d_plaza_above", th_m + th_n * 40.0, 95.0, th_m + th_n * 39.0, 0.0],
			["9e_plaza_zaragoza", th_m + th_n * 4.0 - th_u * 20.0, 3.2, th_m + th_n * 34.0 - th_u * 24.0, 1.5], ["9f_plaza_bandstand", th_m + th_n * 50.0 - th_u * 4.0, 4.5, th_m + th_n * 68.0 - th_u * 11.0, 2.5]]:
		g.phase = "selfshot"
		var from: Vector2 = view[1]
		var at: Vector2 = view[3]
		g.cam.position = MapData.at(from, view[2])
		g.cam.look_at(MapData.at(at, view[4]))
		await _shot(view[0])
	await _titulo_checks()
	g.phase = "title"
	# main menu on the whitewashed wall
	for i in range(3):
		if FileAccess.file_exists(g._slot_path(i)):
			DirAccess.remove_absolute(g._slot_path(i))
	g.menu.open("main")
	var main_items: Array = g._menu_page("main")["items"].map(func(it): return it["text"])
	_check(g.menu.visible and main_items == [Loc.t("menu_new"), Loc.t("m_settings"), Loc.t("m_howto"), Loc.t("m_credits")], "main menu: New game, Settings, How to play, Credits (no Continue without a save)")
	await _shot("0_menu")
	g.menu.open("settings")
	var before_res: int = Settings.data["res"]
	g._menu_page("graphics")["items"][1]["right"].call()
	var set_items: Array = g._menu_page("settings")["items"].map(func(it): return it["text"])
	_check(Settings.data["res"] == (before_res + 1) % Settings.RESOLUTIONS.size() and set_items == [Loc.t("s_graphics"), Loc.t("s_sound"), Loc.t("s_gameplay"), Loc.t("m_back")]
		and g._menu_page("graphics")["items"].size() == 20 and g._menu_page("sound")["items"].size() == 4 and g._menu_page("gameplay")["items"].size() == 5,
		"settings in three: Gráficos (resolution, display... occlusion), Sonido (three volumes), Gameplay (language, field of view, controls)")
	Settings.data["res"] = before_res
	await _frames(5)
	await _shot("0_menu_settings")
	g._do_rebind(KEY_I, "forward")
	_check(Controls.key_name("forward") == "I" and InputMap.action_get_events("forward").any(func(ev): return ev is InputEventKey and ev.physical_keycode == KEY_I), "a key can be reassigned")
	Controls.reset()
	_check(InputMap.action_get_events("interact").any(func(ev): return ev is InputEventJoypadButton) and InputMap.action_get_events("accel").size() == 1, "gamepad buttons and triggers are mapped")
	g.menu.open("howto")
	await _frames(5)
	await _shot("0_menu_howto")
	g.menu.open("credits")
	_check(g._menu_page("credits")["items"][0]["text"].contains("LomoXGames"), "credits name the studio and the data sources")
	await _frames(5)
	await _shot("0_menu_credits")
	var roads := ""
	for r in MapData.roads:
		roads += r["n"] + "|"
	_check(roads.contains("Carretera de Madridejos a Villacañas") and roads.contains("Carretera Antigua de Madrid a Cádiz") and not roads.contains("Matritellus"), "street signs carry the real names")
	_check(Ambience._stream("title_march", true) != null and Ambience._stream("radio_5", true) != null and Ambience._stream("dog_3", false) != null and g.outline != null, "music, radio and ambience tracks load; the outline pass exists")
	# new game: prologue -> character creation -> fly-over -> cutscene
	g._new_game()
	_check(not g.menu.visible, "starting a game closes the menu")
	_check(g.phase == "prologue", "New Game opens the prologue")
	_check(g.hud.ov_logo.texture != null, "the crest image loads")
	await _shot("0a_prologue")
	for i in range(Loc.t("prologue").size()):
		g._story_next()
	_check(g.phase == "creator", "the prologue leads to character creation")
	_check(Loc.t("paca_call").contains("Chiquillo"), "by default people address you in the masculine")
	_creator_pick(9, 1)               # a woman
	_check(Loc.fem and Loc.t("paca_call").contains("Chiquilla") and Loc.t("loli_load")[0].contains("la sobrina") and not Loc.t("paca_intro")[0].contains("{"), "choosing a woman switches the dialogue to the feminine")
	_creator_pick(11, 2)              # peña El Bordillo
	_creator_pick(0, 1)               # beret
	_creator_pick(2, 1)               # blue
	_creator_pick(10, 2)              # long hair
	_creator_pick(7, 1)               # bushy eyebrows
	_creator_pick(12, 2); _creator_pick(13, 2); _creator_pick(14, 5); _creator_pick(15, 3); _creator_pick(16, 2)     # thick glasses, hoops, neckerchief, checked shirt, well fed
	_creator_pick(17, 2); _creator_pick(18, 3)              # red alpargatas
	g.creator_row = 0
	g.creator_tab = 0
	g._creator_input("right")
	_check(g.creator_tab == 1 and Loc.t("c_tabs").size() == Creator.TABS.size() and Creator.TABS[0].size() + Creator.TABS[1].size() == Creator.OPTIONS.size(), "the choices come on two pages, Lustre and Pintas, and between them they cover every option")
	g._creator_input("left")
	var worn: Dictionary = Creator.look(g.look_sel)
	_check(worn["shoe_type"] == 2 and worn["shoes"] == 0xb23a3a and g.player._fl.get_child_count() >= 3, "footwear can be chosen too: kind and colour")
	_check(worn["glasses"] == 2 and worn["earrings"] == 2 and worn["pendant"] == 5 and worn["top"] == 3 and worn["build"] > 1.1 and worn["kerchief"] == Creator.KERCHIEFS[2], "glasses, earrings, something round the neck, clothes and build can be chosen too (the neckerchief takes your peña's colour)")
	_check(Creator.OPTIONS[10]["values"].size() >= 12 and Creator.OPTIONS[8]["values"].size() >= 8 and Creator.OPTIONS[12]["values"].size() >= 5 and Loc.t("c_names").size() == Creator.OPTIONS.size(),
		"%d hairstyles, %d beards, %d kinds of glasses" % [Creator.OPTIONS[10]["values"].size(), Creator.OPTIONS[8]["values"].size(), Creator.OPTIONS[12]["values"].size() - 1])
	var names_ok := true
	for k in range(Creator.OPTIONS.size()):
		if Loc.t("c_values")[k].size() != Creator.OPTIONS[k]["values"].size():
			names_ok = false
	_check(names_ok and Creator.clean([0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0]).size() == Creator.OPTIONS.size(), "every choice has a name, and a character saved before the new options still loads")
	_check(g.look_sel[9] == 1 and g.look_sel[11] == 2 and g.look_sel[0] == 1 and g.look_sel[2] == 1 and g.look_sel[10] == 2 and g.look_sel[7] == 1, "arrow keys change the character, peña included")
	_check(Loc.speaker("mi [[mujer|marido]]", false) == "mi mujer" and Loc.speaker("mi [[mujer|marido]]", true) == "mi marido", "men talk about their wives, women about their husbands")
	_check(Loc.rich("la Loli dice").contains("[color=#c0392b]Loli[/color]") and not Loc.rich("Lolita").contains("color"), "names are picked out in red")
	_check(Loc.t("title_blurb").contains("Madridejos") and g._menu_page("main")["title"] == "" and g.hud.title_name.texture != null, "the game is Matritellus (its name in the title's fade, not again on the menu); the town in it is Madridejos")
	for prof in Sfx.VOICES:
		Sfx.voice("a", prof)
	Sfx.voice("é", "priest", 1.2, 1)
	_check(Sfx._cache.has("v_kid_a") and Sfx._cache.has("v_old_f_a") and Sfx._cache["v_undertaker_a"].data.size() > Sfx._cache["v_adult_m_a"].data.size() * 2, "every voice profile synthesises (the undertaker's vowels are the longest)")
	_check(g.named["anselmo"].voice == "priest" and g.named["venancio"].voice == "undertaker" and g.named["kevin"].voice == "kid" and g.named["paca"].voice == "old_f", "special and standard voices are assigned")
	var seen_voices := {}
	for n in g.npcs:
		seen_voices[n.voice] = true
	_check(seen_voices.has("adult_m") and seen_voices.has("adult_f") and seen_voices.has("old_m") and seen_voices.has("old_f") and seen_voices.has("kid"), "the neighbours use all five standard voices")
	await _frames(30)
	await _shot("0b_creator")
	var bar_btns: bool = g.hud.creator_next.visible and not g.hud.creator_back.visible and g.hud.creator_next.text == Loc.t("c_next") and not g.hud.creator_foot.visible
	g._creator_input("accept")                   # Lustre: Siguiente takes you to Pintas
	var on_pintas: bool = g.phase == "creator" and g.creator_tab == 1 and g.hud.creator_back.visible and g.hud.creator_next.text == Loc.t("c_done")
	g._creator_input("back")                     # Volver: back to Lustre
	var went_back: bool = g.creator_tab == 0 and g.phase == "creator"
	g._creator_input("accept")
	_check(bar_btns and on_pintas and went_back and g.hud.creator_turn.visible and g.hud.creator_tab_r.texture != null,
		"the creator writes no instructions out: Siguiente on Lustre, Volver and Así me quedo on Pintas, each with its button; the page buttons by the tabs and turning arrows round the character")
	await _shot("0b_creator_pintas")
	g._creator_input("accept")                   # Pintas: Así me quedo
	_check(g.phase == "flyover" and g.dlg != null and g._fly_shots.size() == Loc.t("flyover").size(), "confirming starts the fly-over of the town, one camera move per line")
	await _frames(50)
	var bub: Control = g.hud.dlg_bubble
	var screen_h: float = g.hud.get_viewport().get_visible_rect().size.y
	var bub_low: float = bub.get_global_rect().end.y
	_check(g.hud.dlg_slot.visible and bub_low <= screen_h - g.hud.CINE_BAR - 4.0, "in a scene the speech bubble sits clear of the black bar at the bottom (its lower edge %.0f px, the bar from %.0f)" % [bub_low, screen_h - g.hud.CINE_BAR])
	await _shot("0c_bocadillo_bandas")
	_check(g._load_slot(g.slot) != null and g._load_slot(g.slot)["look"][0] == 1.0, "the new game is saved in its slot, character included")
	var slot_items: Array = g._menu_page("slots")["items"]
	_check(slot_items[g.slot].has("face") and slot_items[g.slot]["face"]["hat"] == "beret" and slot_items[g.slot]["face"]["shoe_type"] == 2, "the saved game carries a passport photo of the character as it was at the last checkpoint")
	await _frames(60)
	await _shot("0b2_flyover")
	g.dlg["cool"] = 0.0; g.dlg["shown"] = 9999.0
	g.dialog_advance(); g.dlg["cool"] = 0.0; g.dlg["shown"] = 9999.0; g.dialog_advance()
	await _frames(90)
	await _shot("0b3_flyover_terraza")
	await _skip_dialog()
	_check(g.phase == "cutscene" and g.dlg != null, "the fly-over ends at the conversation with Tía Paca")
	await _frames(30)
	await _shot("0c_cutscene")
	g.dialog_advance.call_deferred()
	g.dlg["cool"] = 0.0
	g.dlg["shown"] = 9999.0
	g.dialog_advance()
	await _frames(20)
	await _shot("0d_cutscene_reverse")
	await _skip_dialog()
	_check(g.phase == "play" and g.si == 0 and g.weekday == 0 and g.moment == "morning", "after the cutscene the game begins, on a Monday morning")
	await _driving_checks()
	await _relief_checks()
	await _church_checks()
	await _petril_checks()
	_looks_checks()
	_casas_checks()
	_tester_checks()
	await _autopilot_checks()
	await _frames(30)
	# the town moves on its own: neighbours driving, and neighbours on foot along the pavements
	await _frames(300)
	_check(g.traffic.list.size() >= 3, "other cars are out driving (%d)" % g.traffic.list.size())
	var starts := {}
	for e in g.traffic.list:
		starts[e["car"]] = e["car"].p
	var furthest := 0.0
	for i in range(8 * 60):
		await get_tree().physics_frame
		for car in starts:
			if is_instance_valid(car):
				furthest = maxf(furthest, car.p.distance_to(starts[car]))
	_check(furthest > 25.0, "a traffic car drives along the road (%.0f m in 8 s)" % furthest)
	var back_home: Vector2 = g.player.p
	var first_walker = null
	for n in g.npcs:
		if n.walker:
			first_walker = n
			break
	g.player.p = MapData.nodes[MapData.neighbours(MapData.nearest_node(first_walker.p))[0]]      # go where the walkers are (far-off neighbours are asleep)
	var walk_from := {}
	for n in g.npcs:
		if n.walker and n.p.distance_to(g.player.p) < 180.0:
			walk_from[n] = n.p
	var strolled := 0.0
	for i in range(12 * 60):
		await get_tree().physics_frame
		for n in walk_from:
			strolled = maxf(strolled, n.p.distance_to(walk_from[n]))
	_check(strolled > 5.0, "neighbours walk along the streets (%d of them nearby, the keenest did %.0f m in 12 s)" % [walk_from.size(), strolled])
	g.player.p = back_home
	await _frames(10)
	_check(g.phase == "play" and g.si == 0, "day starts on step 0")
	_check(MapData.route_pts.size() > 1, "route to Paca exists")
	await _shot("1_morning_on_foot")
	g.talk_to(g.named["paca"])
	await _frames(40)
	_check(g.dlg != null, "Paca speaks")
	await _shot("2_dialogue")
	await _skip_dialog()
	_check(g.si == 1, "talking to Paca starts the drive to the Cooperativa")
	g._enter_car(g.paca_car)
	await _frames(20)
	_check(MapData.route_pts.size() > 10, "GPS route to the Cooperativa (%d points)" % MapData.route_pts.size())
	await _shot("3_in_car")
	await _mayhem_checks()
	await _drive_to("coop")
	_check(_at("loli") and not g.world.coop.gate_open, "at the Cooperativa the gate stays shut until you talk to Loli")
	g.talk_to(g.named["loli"])
	_check(g.dlg != null, "Loli speaks")
	await _skip_dialog()
	_check(_at("load") and g.world.coop.gate_open, "Loli has the gate opened: the oil is inside")
	# the main story comes first: nothing else while a mission is under way
	g.weekday = 3
	g.set_time(9.0)
	g.stats.erase("thu")
	g._weekly_call()
	await _frames(10)
	_check(g.in_mission() and g.phone_call == null and g.side == null, "in the middle of a main mission nobody rings about hams, Thursday or not")
	g.unlocked["box"] = 1
	g._play_minigame("box", 0)
	_check(g.phase == "play" and not g.boxing.active and g.hud.toast_label.text == Loc.t("log_not_now"), "and a minigame only gets you a message: finish what you have in hand first")
	g.unlocked.erase("box")
	g.weekday = 0
	g.set_time(9.5)
	await _frames(150)
	_check(g.world.coop.gate.position.x > float(MapData.coop["gate"]) + 6.0, "the gate has rolled aside along the wall")
	var gate_at: Vector2 = MapData.coop_point(float(MapData.coop["gate"]) + 1.0, 14.0)
	g.cam_yaw = atan2(gate_at.x - g.in_car.p.x, gate_at.y - g.in_car.p.y)
	await _frames(40)
	await _shot("3f_gate_open")
	await _drive_to("coop_yard")
	await _frames(5)
	_check(_at("deliver") and g.bottles == 6 and g.timer > 140.0, "driving in to the pallet loads 6 bottles and starts the clock")
	# crash: a bottle breaks
	g._crash(g.in_car, 9.0)
	_check(g.bottles == 5, "a hard crash breaks one bottle")
	# time out -> fail -> retry
	g.timer = 0.05
	await _frames(10)
	_check(g.phase == "failed", "running out of time fails the run")
	g._retry()
	await _frames(5)
	_check(g.phase == "play" and g.bottles == 6 and g.timer > 110.0, "retry restarts the delivery")
	await _shot("4_delivery")
	await _drive_to("kiosk")
	_check(g.dlg != null and g.delivered == 6, "Eusebio receives 6 bottles")
	await _skip_dialog()
	_check(_at("maruja"), "the delivery done, the next mission opens")
	await _shot("5_noon")
	g.talk_to(g.named["maruja"])
	await _skip_dialog()
	g.in_car.set_speed(Vector2(sin(g.in_car.h), cos(g.in_car.h)) * 4.0)       # (pull away: wherever she was, she is in the car)
	await _frames(8)
	_check(_at("wake") and g.named["maruja"].away and not g.world.coop.gate_open, "Maruja rides along (and the Cooperativa has shut its gate again)")
	# ...beside you in the car; and on foot she comes after you instead of vanishing
	var mcar = g.in_car
	var seated: bool = not mcar.riders[0].is_empty() and not mcar.riders[1].is_empty()
	mcar.set_speed(Vector2.ZERO)
	await _frames(10)
	g._exit_car()
	await _frames(8)
	var mj = g.named["maruja"]
	var got_out: bool = g.in_car == null and not mj.away and mj.visible and mj.p.distance_to(g.player.p) < 8.0 and mcar.riders[0].is_empty() and mcar.riders[1].is_empty()
	var gap := 0.0
	for step in range(5):                         # walk off down the street, a few paces at a time
		g.player.p = g.player.p + Vector2(sin(mcar.h), cos(mcar.h)) * 2.5
		g.player.sync()
		await _frames(24)
		gap = maxf(gap, mj.p.distance_to(g.player.p))
	var kept_up: bool = mj.p.distance_to(g.player.p) < 4.5 and mj.p.distance_to(mcar.p) > 6.0
	g.player.p = mcar.p + Vector2(cos(mcar.h), -sin(mcar.h)) * 1.9
	g.player.sync()
	g._enter_car(mcar)
	await _frames(40)
	_check(seated and got_out and kept_up and g.in_car == mcar and mj.away and not mcar.riders[1].is_empty(),
		"she sits beside you in the car, gets out when you do, follows you on foot (never more than %.1f m behind) and gets back in (seated %s, out %s, kept up %s)" % [gap, seated, got_out, kept_up])
	# bump a neighbour
	var victim = g.npcs.filter(func(n): return n.id == "" and not n.has_meta("protest") and not n.still and n.voice != "goat")[10]      # a neighbour out for a walk
	victim.visible = true
	victim.p = g.in_car.p + Vector2(sin(g.in_car.h), cos(g.in_car.h)) * 3.0
	g.in_car.set_speed(Vector2(sin(g.in_car.h), cos(g.in_car.h)) * 14.0)
	await _frames(12)
	_check(g.bumped >= 1 and victim.state != "idle", "hitting a neighbour sends them flying")
	await _drive_to("tanatorio")
	_check(g.dlg != null and not g.named["maruja"].away, "Venancio speaks, Maruja gets out")
	await _skip_dialog()
	_check(_at("home"), "then home")
	await _frames(260)
	await _shot("6_evening")
	await _drive_to("home")
	await _frames(5)
	_check(_at("sleep") and g.dlg != null, "at home Paca sends you to bed")
	await _frames(260)
	await _shot("7_night")
	await _skip_dialog()
	_check(g.phase == "ending", "the screen goes dark")
	var slept_on: int = g.weekday
	await _frames(150)
	_check(g.phase == "play" and _at("call") and g.weekday == (slept_on + 1) % 7 and absf(g.clock - 8.0) < 0.3 and g.moment == "morning" and g.phone_call != null,
		"you wake up the next morning (%s) with the phone ringing" % Loc.t("wd_%d" % g.weekday))
	await _frames(45)
	await _shot("d1_phone_rings")
	g.interact()
	_check(g.dlg != null and g.player.phone and g.phone_call["on"], "answering puts the phone to your ear and Tía Paca talks")
	await _frames(30)
	await _shot("d1_on_the_phone")
	await _skip_dialog()
	_check(_at("josefa") and g.phone_call == null and not g.player.phone, "hanging up sends you to Josefa")
	g.talk_to(g.named["josefa"])
	await _skip_dialog()
	_check(_at("vip"), "Josefa hands over the phone for the V.I.P. shop")
	g._enter_car(g.paca_car)
	await _drive_to("vip")
	_check(_at("vip") and g.dlg == null and not g.indoors, "parking outside the shop is not enough: you have to walk in")
	g.in_car.set_speed(Vector2.ZERO)
	await _frames(10)
	g._exit_car()
	g.player.p = g.vip.out_spawn
	g.player.h = g.vip.out_h + PI
	g.cam_yaw = g.player.h + 0.5
	g.cam_pitch = 0.2
	await _frames(40)
	_check(g.vip.open > 0.9, "the shop door swings open as you walk up")
	await _shot("d2_shopfront")
	g.player.p = g.vip.door_out + (g.vip.out_spawn - g.vip.door_out).normalized() * 0.9
	g.player.h = g.vip.out_h + PI
	await _frames(6)
	_check(g.indoors and g.dlg != null and g.player.p.distance_to(g.vip.counter_front) < 0.6, "walking into the door takes you inside, and Fonsi takes a look at it")
	await _frames(30)
	await _shot("d2_inside")
	await _skip_dialog()
	_check(g.menu.visible and g.menu.page == "choice" and not g._menu_page("choice")["items"][0].has("do"), "605 euros: you cannot pay, so paying is greyed out")
	g.money = 700
	_check(g._vip_choice(false) == null and g._menu_page("choice")["items"][0].has("do"), "with the money, paying becomes an option")
	g.money = 0
	g._vip_choice(false)
	await _frames(10)
	await _shot("d1_choice")
	g._choose(1)
	await _skip_dialog()
	_check(g.phase == "boxing" and g.boxing.active and g.player.p.distance_to(g.vip.ring_me) < 0.3 and g.vip_crowd[0].visible, "challenging him takes you both to the ring in the back room, neighbours and all")
	await _frames(60)
	await _shot("d1_boxing")
	# (the fight has been running while the picture was taken: put both back to full before measuring)
	g.boxing.hp = 100.0; g.boxing.foe_hp = 100.0; g.boxing.stun = 0.0; g.boxing.cool = 0.0; g.boxing.dodge = 0.0
	g.boxing.state = "open"; g.boxing.t = 5.0
	g.boxing.act("punch")
	_check(g.boxing.foe_hp == 100.0 - g.boxing.HIT_OPEN, "a punch while he is wide open does double damage")
	g.boxing.hp = 100.0; g.boxing.stun = 0.0; g.boxing.dodge = 0.0
	g.boxing.state = "wind"; g.boxing.t = 0.05; g.boxing.big = false
	g.boxing.act("left")
	await _frames(6)
	_check(g.boxing.hp == 100.0 and g.boxing.state == "open", "dodging his swing leaves him open and you unhurt")
	g.boxing.hp = 100.0; g.boxing.stun = 0.0; g.boxing.dodge = 0.0
	g.boxing.state = "wind"; g.boxing.t = 0.05; g.boxing.big = true
	await _frames(6)
	_check(g.boxing.hp == 100.0 - g.boxing.HAYMAKER, "standing there for the big one hurts (%.0f left)" % g.boxing.hp)
	g.boxing.hp = 1.0
	g.boxing.state = "wind"; g.boxing.t = 0.05; g.boxing.dodge = 0.0
	await _frames(30)
	_check(g.boxing.active and g.boxing.losses == 1 and g.boxing.state == "rest", "going down loses you the round, not the fight")
	await _shot("d2_round_end")
	await _frames(115)
	_check(g.boxing.round_n == 2 and g.boxing.state != "rest" and g.boxing.foe_hp == 100.0, "the bell rings for round two, both fresh")
	g.boxing.clock = 0.05
	g.boxing.hp = 80.0; g.boxing.foe_hp = 30.0; g.boxing.state = "idle"; g.boxing.t = 5.0
	await _frames(6)
	_check(g.boxing.wins == 1 and g.boxing.losses == 1 and g.boxing.state == "rest", "when the clock runs out the fresher one takes the round")
	await _frames(115)
	_check(g.boxing.round_n == 3, "one each: a third round decides it")
	g.boxing.hp = 1.0
	g.boxing.state = "wind"; g.boxing.t = 0.05; g.boxing.dodge = 0.0
	await _frames(110)
	_check(g.dlg != null and not g.boxing.active and not g.vip_crowd[0].visible, "two rounds lost ends the fight and he laughs at you")
	_check(g.player.p.distance_to(g.vip.counter_front) < 0.6 and g.named["vip"].p.distance_to(g.vip.keeper_spot) < 0.6, "...back at the counter, both of you")
	await _skip_dialog()
	_check(g.phase == "play" and g._step_flag == "vip_retry" and _at("vip"), "you have to come back: pay, or ask for a rematch")
	g._use_door(false)
	await _frames(40)
	_check(not g.indoors and g.player.p.distance_to(g.vip.out_spawn) < 1.0, "you can walk back out into the street")
	g._use_door(true)
	await _frames(40)
	_check(g.indoors and g.dlg == null and g.phase == "play", "coming back in does not replay his speech")
	g.talk_to(g.named["vip"])
	_check(g.menu.visible and g._menu_page("choice")["items"][1]["text"] == Loc.t("vip_rematch"), "talking to him again offers the rematch")
	g._choose(1)
	await _skip_dialog()
	g.boxing.wins = 1
	g.boxing.foe_hp = 1.0
	g.boxing.state = "open"; g.boxing.cool = 0.0
	g.boxing.act("punch")
	await _frames(110)
	_check(g.dlg != null and not g.boxing.active, "winning two rounds: he hands the phone over")
	await _skip_dialog()
	_check(_at("josefa_back") and g.phase == "play" and int(g.unlocked.get("box", 0)) == 1, "back to Josefa with the phone; beating him has opened the boxing minigame")
	g._use_door(false)
	await _frames(10)
	g.talk_to(g.named["josefa"])
	await _skip_dialog()
	_check(g.money == 2500 and _at("josefa_back"), "Josefa gives you 2500...")
	g.talk_to(g.named["josefa"])
	await _skip_dialog()
	_check(g.money == 2500, "(and asking again does not pay twice)")
	await _frames(100)
	_check(g.money == 15 and g.dlg != null, "...pesetas: 15 euros. And she has another errand: the old bridge")
	await _skip_dialog()
	_check(_at("alberto") and g.target_npc == g.named["alberto"], "she sends you to Alberto, at the old bridge")
	g.player.p = g.named["alberto"].p + Vector2(1.4, 1.0)
	g.cam_yaw = atan2(g.named["alberto"].p.x - g.player.p.x, g.named["alberto"].p.y - g.player.p.y) + 0.5
	await _frames(40)
	await _shot("d2_bridge")
	g.talk_to(g.named["alberto"])
	_check(g.dlg != null and g.dlg["lines"].size() == Loc.t("alberto_bridge").size(), "Alberto explains about the bridge they want to pull down, and his neighbours' movement")
	await _skip_dialog()
	await _firmas_checks()
	_check(_at("tbc"), "that is as far as the story goes for now")
	await _frames(340)
	_check(g.phase == "end", "a to-be-continued screen comes up")
	await _shot("d1_end")
	var saved: Dictionary = g._load_slot(g.slot)
	_check(int(saved["si"]) == g._idx("alberto") and int(saved["weekday"]) == g.weekday and saved.has("clock") and int(saved["unlocked"]["box"]) == 1, "the save keeps the mission, the day of the week, the hour and what is unlocked")
	g._free_roam()
	_check(g.phase == "free", "after it the town is yours to roam")
	# the Agenda in the pause menu: four pages
	g._open_pause()
	g.menu.open("log")
	await _frames(10)
	await _shot("d2_log")
	var log: Array = g._menu_page("log")["items"]
	var done_n := 0
	for it in log:
		if String(it["text"]).contains(Loc.t("log_done")):
			done_n += 1
	_check(done_n == 3 and log.any(func(it): return String(it["text"]).contains(Loc.t("log_now"))) and Loc.t("m_log") == "Agenda", "the Agenda's first page lists three missions done and one in progress")
	log[0]["right"].call()
	_check(g.menu.page == "log_side", "turning the page: side missions")
	g._menu_page("log_side")["items"][0]["right"].call()
	var games: Array = g._menu_page("log_games")["items"]
	var game_item = null
	for it in games:
		if it.has("do") and String(it["text"]).contains(Loc.t("mg_box")):
			game_item = it
	_check(g.menu.page == "log_games" and game_item != null and games.any(func(it): return String(it["text"]).contains(str(int(g.stats["box_best"])))) and games.any(func(it): return String(it["text"]).contains(Loc.t("mg_box_unlock"))),
		"the minigames page: the boxing match, the best score (%d) and how it was unlocked" % int(g.stats["box_best"]))
	await _frames(5)
	await _shot("d2_agenda_games")
	games[0]["right"].call()
	var folks: Array = g._menu_page("log_folk")["items"].filter(func(it): return it.has("meter"))
	var folk_names: Array = folks.map(func(it): return it["text"])
	_check(g.menu.page == "log_folk" and folk_names.has(Loc.t("n_paca")) and folk_names.has(Loc.t("n_josefa")) and folk_names.has(Loc.t("n_vip")) and folk_names.has(Loc.t("n_alberto")) and not folk_names.has(Loc.t("n_genaro")),
		"the neighbours page lists the %d people you have met, each with a trust meter (and nobody you have not)" % folks.size())
	_check(g.folk.trust("josefa") == 13 and g.folk.trust("paca") >= 13 and g.folk.trust("maruja") == 13 and g.folk.trust("vip") >= 8, "a hello is worth 3, a mission for them 10, a fight with them 5 (Josefa %d, Paca %d, Maruja %d, Fonsi %d)" % [g.folk.trust("josefa"), g.folk.trust("paca"), g.folk.trust("maruja"), g.folk.trust("vip")])
	await _frames(5)
	await _shot("d2_agenda_folk")
	g.menu.open("log_games")
	# trust: once a day, never below a mark reached, gold at a hundred
	var F = g.folk
	var before_t: int = F.trust("josefa")
	g.talk_to(g.named["josefa"])
	g.dlg = null
	g.hud.dlg_slot.visible = false
	_check(F.trust("josefa") == before_t, "a second hello the same day counts for nothing")
	g.day_n += 1
	_check(F.greet("josefa", g.day_n) and F.trust("josefa") == before_t + 3, "the next day it does")
	F.add("josefa", 12)
	var at_mark: int = F.trust("josefa")
	_check(F.hurt("josefa", g.day_n) and F.trust("josefa") == maxi(25, at_mark - 3) and not F.hurt("josefa", g.day_n), "hitting her costs 3, once a day")
	F.add("josefa", -40)
	_check(F.trust("josefa") == 25, "but trust never falls back below a mark it has reached (25)")
	F.missed_call("josefa")
	var kevin_was: int = F.trust("kevin")            # (he may have been said hello to along the way, asking for signatures)
	F.played("kevin")
	F.played("kevin")
	_check(F.trust("josefa") == 25 and F.trust("kevin") == kevin_was + 6, "a first game with someone is worth 5, the next ones 1")
	F.add("josefa", 200)
	F.add("josefa", -50)
	_check(F.trust("josefa") == 100 and F.golden("josefa") and g._menu_page("log_folk")["items"].any(func(it): return it.get("gold", false)), "at a hundred it turns to gold and nothing brings it down")
	F.data.erase("kevin")
	var MenuS = g.menu.get_script()
	var tones: Array = [MenuS.meter_colour(0.0), MenuS.meter_colour(0.24), MenuS.meter_colour(0.25), MenuS.meter_colour(0.49), MenuS.meter_colour(0.5), MenuS.meter_colour(0.74), MenuS.meter_colour(0.75), MenuS.meter_colour(0.99), MenuS.meter_colour(1.0)]
	_check(tones[0] == tones[1] and tones[2] == tones[3] and tones[4] == tones[5] and tones[6] == tones[7] and tones[1] != tones[2] and tones[3] != tones[4] and tones[5] != tones[6] and tones[7] != tones[8]
		and tones[0].r > 0.8 and tones[0].g < 0.35 and tones[6].g > tones[6].r and tones[8] == Color("f2c230"), "the meter changes colour at each mark: vermilion, dull orange, dull yellow, green, gold")
	# the minigame, from the log
	var was_at: Vector2 = g.player.p
	var wins_before: int = int(g.stats.get("box_wins", 0))
	game_item["do"].call()
	await _frames(10)
	_check(g.phase == "boxing" and g.boxing.active and not g.paused and not g.menu.visible, "choosing it in the log starts a fight in the ring")
	g.boxing.wins = 1
	g.boxing.foe_hp = 1.0
	g.boxing.state = "open"; g.boxing.cool = 0.0; g.boxing.stun = 0.0
	g.boxing.act("punch")
	await _frames(110)
	_check(g.phase == "free" and not g.indoors and g.player.p.distance_to(was_at) < 1.0 and int(g.stats.get("box_wins", 0)) == wins_before + 1, "afterwards you are back where you were, with one more win on the books")
	# the clock and the days of the week
	_check(g.moment_of(3.0) == "night" and g.moment_of(9.0) == "morning" and g.moment_of(13.0) == "noon" and g.moment_of(18.0) == "afternoon" and g.moment_of(20.5) == "evening", "the hour of the day says whether it is morning, noon, afternoon, evening or night")
	var day_before: int = g.weekday
	g.set_time(23.9)
	g._advance_clock(120.0 * 0.3)
	_check(g.weekday == (day_before + 1) % 7 and g.clock < 1.0 and g.moment == "night", "at midnight the day of the week moves on (two minutes an hour)")
	_check(g._tag().ends_with(Loc.t("late")) and g._tag().begins_with(Loc.t("wd_%d" % g.weekday).to_upper()), "and from midnight to dawn the calendar says so: %s (the night before midnight, the madrugada after)" % g._tag())
	g.set_time(12.0)
	var before_h: float = g.clock
	await _frames(60)
	_check(g.clock > before_h + 0.012 and g.clock < before_h + 0.022, "time runs by itself while you play (%.3f h in 2 s)" % (g.clock - before_h))
	_check(g._step_open({"days": [g.weekday]}) and not g._step_open({"days": [(g.weekday + 1) % 7]}) and g._step_open({"hours": [22.0, 14.0]}) and not g._step_open({"hours": [14.0, 22.0]}), "a mission step can be tied to days of the week or to hours")
	# a nap at home
	g.player.p = g.places["home"]["p"]
	await _frames(5)
	_check(g._can_nap(), "at home you can lie down whenever you like")
	day_before = g.weekday
	g._go_to_sleep()
	await _frames(150)
	_check(g.weekday == (day_before + 1) % 7 and absf(g.clock - 8.0) < 0.3 and g.phase == "free", "and wake up the next morning")
	# Thursday morning: somebody you know rings, and wants a roast ham
	_check(not g.negocio("restaurantes") or g.weekday != 3 or g.phone_call != null or int(g.stats.get("thu", -1)) == g.day_n, "(if the nap ended on a Thursday morning, the phone is already ringing of its own accord)")
	g.stats["menu_done"] = true                # (as if Josefa had already sent you to Henry's: the restaurants are known)
	g.phone_call = null                        # start from a quiet phone, whatever day the nap ended on
	g.hud.phone(false)
	g.weekday = 3
	g.set_time(9.0)
	g.stats.erase("thu")
	g.police.reset()
	g._weekly_call()
	_check(g.phone_call != null and g.phone_call.get("side", false) and g.folk.knows(g.phone_call["npc"]) and g.phone_call["npc"] != "henry", "on Thursday morning a neighbour you know rings you (%s)" % (g.named[g.phone_call["npc"]].shown_name() if g.phone_call != null else "nobody"))
	var caller: String = g.phone_call["npc"]
	var caller_t: int = g.folk.trust(caller)
	g.interact()
	_check(g.dlg != null and g.player.phone and g.dlg["lines"].size() == Loc.t("ham_call").size(), "you pick up: they are starving, in a hurry, and not fussy about how you drive")
	await _skip_dialog()
	_check(g.side != null and g.side["stage"] == "fetch" and not g.hud.timer_slot.visible and g.target.distance_to(g.places["henry"]["p"]) < 1.0, "no clock on it, and the way to La Cocina de Henry")
	g.police.add_heat(60.0)
	_check(g.police.muted and g.police.heat == 0.0, "Los Pitufos take no notice of anything while it lasts")
	g._weekly_call()
	_check(g.phone_call == null, "(and nobody else rings meanwhile)")
	var rioted: bool = await _riot_through()
	g.cam_yaw = atan2(g.named["henry"].p.x - g.player.p.x, g.named["henry"].p.y - g.player.p.y)
	await _frames(30)
	_check(rioted and g.side != null and g.side["stage"] == "bring" and g.folk.knows("henry"), "at Henry's the ham is fought for and won, and now you know Henry")
	await _shot("thu_henry")
	g.menu.open("log_side")
	_check(g._menu_page("log_side")["items"].any(func(it): return String(it["text"]).contains(Loc.t("ham_title")) and String(it["text"]).contains(Loc.t("log_now"))), "the Agenda's side missions page shows it under way")
	g.menu.close()
	if caller == "vip":
		g.indoors = true
	else:
		g.player.p = g.named[caller].p + Vector2(1.5, 1.0)
	await _frames(20)
	g.indoors = false
	_check(g.side == null and g.dlg != null and int(g.stats["ham_done"]) == 1 and not g.police.muted and not g.hud.timer_slot.visible, "delivered in time: they say thank you, in their way")
	_check(g.hud.stamp_text.text == Loc.t("stamp_done") and g.hud.stamp_box.modulate.a > 0.5 and not g.hud.toast_label.text.contains(Loc.t("mission_done")), "with the stamp, as any errand done (and no notice as well)")
	_check(g.folk.trust(caller) >= mini(100, caller_t + 10) or g.folk.golden(caller), "and trust you 10 more for it")
	await _skip_dialog()
	g._weekly_call()
	_check(g.phone_call == null and g.side == null, "only one call a week")
	# not picking up at all
	g.stats.erase("thu")
	g._weekly_call()
	caller = g.phone_call["npc"]
	g.folk.add(caller, 2)                       # (so there is something to lose)
	caller_t = g.folk.trust(caller)
	g.phone_call["left"] = 0.2
	await _frames(30)
	_check(g.phone_call == null and g.side == null and (g.folk.trust(caller) == caller_t - 1 or g.folk.golden(caller) or caller_t % 25 == 0), "let it ring out and they think a little less of you")
	await _derrape_checks()
	await _radio_live_checks()
	_tirones_checks()
	_palabros_checks()
	await _llamadas_checks()
	await _kebab_checks()
	await _comida_checks()
	await _tow_checks()
	await _duty_checks()
	await _limite_checks()
	await _marcas_checks()
	var si_was: int = g.si
	var phase_was: String = g.phase
	var stats_was: Dictionary = g.stats.duplicate(true)
	var money_was: int = g.money
	var clock_was: float = g.clock
	g.si = g._idx("tbc")
	g.phase = "free"
	await _recress_checks()
	g.stats = stats_was                              # (the rest of the run carries on as if it had not happened)
	g.money = money_was
	g.set_time(clock_was)
	g.recress.load_state()
	g.side = null
	g.si = si_was
	g.phase = phase_was
	await _tokken_checks()
	await _vuelcos_checks(true)
	await _mirada_checks()
	await _sabotaje_checks()
	# the rules every mission follows, from the first step of the story (and then back to where the run had got to)
	var run_si: int = g.si
	g.phase = "play"
	g.begin_step(0)
	await _reglas_checks()
	g.phase = "play"
	g.begin_step(0)
	await _civicos_checks()
	await _pintadas_checks()
	g.phase = "play"
	g.stats.erase("menu_done")
	g.begin_step(g._idx("alberto"))
	await _motin_checks()
	g.begin_step(run_si)
	g.phase = "free"
	Loc.toggle()
	_check(Loc.t("obj_paca") != "obj_paca" and Loc.lang == "en", "English translation loads")
	print("SELFTEST %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
	get_tree().quit(1 if fails > 0 else 0)
