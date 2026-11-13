extends Node
## Getting the graphics card's shaders made before play starts, behind the loading screen. Each kind of thing the game
## draws needs its shaders made the first time it is seen; on a machine that has never run the game (a new install, a
## Steam Machine) every one of those first times was a hitch: "tirones puntuales para luego jugar con normalidad, incluso
## en entornos de baja carga" (the user, 13 November 2026, who asked for this). So, the first time this version of the
## game runs on this graphics card:
##   - a museum in front of the camera: one car of every make (lights on, smoke, the turbo's flame, the patrol cars'
##     lamps), neighbours in every kind of dress, graffiti old and new, skid marks, a number floating over a head;
##   - the camera flown over the town, by day and by night (the lanterns, the lit windows, the headlights).
## Then it is all taken away again. The shaders stay made: the engine keeps them on disk for the next time.

const VERSION := "1"            # change it when the game starts drawing new kinds of things: everybody warms up again
const CarS = preload("res://scripts/car.gd")

var G
var _made: Array = []           # what the museum put up (to be taken away)
var _npcs: Array = []
var _night := false             # (the lanterns are lit round wherever the camera is: lights.gd)

## has this version of the game run on this graphics card before?
static func key() -> String:
	return "%s|%s|%s" % [VERSION, Engine.get_version_info().get("string", ""), RenderingServer.get_video_adapter_name()]

static func needed() -> bool:
	if OS.get_cmdline_user_args().has("--calentar"):
		return true
	if Settings.testing or DisplayServer.get_name() == "headless":
		return false
	return String(Settings.data.get("warm", "")) != key()

## the whole thing; `say` shows a line under the loading bar
func run(game, say: Callable) -> void:
	G = game
	say.call(Loc.t("loading_warm"))
	var hour: float = G.time
	var start: Vector2 = G._start["p"]
	var along: Vector2 = G._start.get("u", Vector2(0, 1))
	await _museum(start, along)
	await _hud()
	await _fly(start)
	G.set_time(22.5)                              # the night: lanterns, lit windows, headlights
	_night = true
	for c in _made:
		if c is VehicleBody3D:
			c.set_lights(true, true)
	await _look_from(start - along * 4.0, start + along * 14.0, 4)
	await _fly(start, 4, 1)
	_night = false
	G.set_time(hour)
	if G.lights != null:
		G.lights.tick(1.0, start)
	_clear()
	Settings.data["warm"] = key()
	Settings.save()

func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame

## puts the camera at `from` (6 m up) looking at `at`, and draws `n` frames
func _look_from(from: Vector2, at: Vector2, n: int, high := 6.0) -> void:
	var eye := MapData.at(from, high)
	var target := MapData.at(at, 1.2)
	if eye.distance_to(target) < 0.5:
		target = eye + Vector3(0, -0.2, 1)
	G.cam.global_position = eye
	G.cam.look_at(target, Vector3.UP)
	if G.lights != null:
		G.lights.tick(1.0, from)
	await _frames(n)

func _museum(start: Vector2, along: Vector2) -> void:
	var side := Vector2(-along.y, along.x)
	var kinds: Array = CarS.SPECS.keys()
	for k in range(kinds.size()):                 # the cars, in two rows across the camera's view
		var c = CarS.new()
		G.add_child(c)
		var at: Vector2 = start + along * (12.0 + 7.0 * float(k / 4)) + side * (-7.5 + 5.0 * float(k % 4))
		c.setup(kinds[k], 0xc0392b, at, atan2(along.x, along.y) + 0.6)
		c.running = true
		c.set_lights(k % 2 == 0, k % 4 == 0)
		c.smoke.emitting = true
		if c.spec.has("turbo"):
			c.turbo = true
			c.boosting = true
		for lamp in c.lights:
			lamp.visible = true
		_made.append(c)
	var looks: Array = []                         # neighbours in every kind of dress, and the two kinds of police
	for i in range(10):
		looks.append(G.driver_look() if i < 2 else {})
	looks[0]["hat"] = "tricorn"
	looks[1]["hat"] = "cap"
	for i in range(looks.size()):
		var n = G.spawn_neighbour(start + along * (6.0 + 1.4 * float(i / 5)) + side * (-3.0 + 1.5 * float(i % 5)), true, looks[i])
		if n != null:
			_npcs.append(n)
	if _npcs.size() > 2:
		_npcs[2].bark("¡Arrea!", 3.0)
		G.float_number(_npcs[3], 3)
	if not G.props.tags.is_empty():               # graffiti, worn and fresh
		for fresh in [false, true]:
			var t: Dictionary = G.props.tags[0]
			var mi: MeshInstance3D = t["node"].duplicate()
			mi.material_override = t["node"].material_override.duplicate()
			mi.material_override.set_shader_parameter("wear", 0.0 if fresh else 1.0)
			G.add_child(mi)
			var spot: Vector2 = start + along * 9.0 + side * (-1.5 if fresh else 1.5)
			mi.global_position = MapData.at(spot, 1.4)
			mi.look_at(MapData.at(spot - along, 1.4), Vector3.UP)
			mi.rotate_object_local(Vector3.UP, PI)
			_made.append(mi)
	for s in range(6):                            # skid marks
		var a: Vector2 = start + along * (8.0 + s * 0.4) + side * 2.0
		G.derrape._lay(MapData.at(a, 0.0), MapData.at(a + along * 0.4, 0.0))
	for i in range(5):
		await _look_from(start - along * (2.0 + i), start + along * 14.0, 3, 2.0 + 2.0 * float(i))

## what is on the screen while playing (the dials, the map, the notices): under the loading screen for a moment
func _hud() -> void:
	var h = G.hud
	var was: bool = h.play_ui.visible
	h.play_ui.visible = true
	h.toast(Loc.t("t_chase"), 0.2)
	h.set_prompt(Loc.t("p_talk"))
	h.show_limit(30.0)
	h.bigmap.visible = true
	await _frames(4)
	h.bigmap.visible = false
	h.hide_limit()
	h.set_prompt("")
	h.play_ui.visible = was

## the camera over the town: the flyover's places and a ring of streets round them
func _fly(start: Vector2, frames := 3, ring_step := 1) -> void:
	var spots: Array = []
	for name in ["Plaza del Ayuntamiento", "Molino"]:
		var p: Vector2 = MapData.poi(name)
		if p != Vector2.ZERO:
			spots.append(p)
	spots.append(start)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for k in range(0, 8, ring_step):
		var q = MapData.random_node_near(Vector2(cos(k * 0.785), sin(k * 0.785)) * rng.randf_range(200.0, 600.0), 0.0, 150.0)
		if q != null:
			spots.append(q)
	for p in spots:
		var to: Vector2 = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized() * 25.0
		await _look_from(p - to, p + to, frames, 7.0)
		await _look_from(p, p + to * 2.0, frames, 30.0)

func _clear() -> void:
	for c in _made:
		if is_instance_valid(c):
			c.queue_free()
	_made.clear()
	for n in _npcs:
		if is_instance_valid(n):
			G.npcs.erase(n)
			n.queue_free()
	_npcs.clear()
	G.derrape.clear()
