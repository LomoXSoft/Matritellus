extends Node
## Children at play in the town's nursery yards (the user, 16 November 2026: "creo que ya podríamos meter niños jugando
## en los sitios de niños, y hablando cosas de niños de pueblo"): the little ones of the nursery school on the Calle del
## Palo (calasanz.gd) and of the Caridad's nursery (caridad.gd) are out in their yards on school days in the middle of
## the morning, not in the rain. The square's playground has its own children (plaza.gd). And the Colegio Público's
## (colegiopub.gd; the user, 27 Nov 2026: "que funcione como Calasanz, niños jugando y dando vueltas durante el horario
## escolar"), in school hours ("Horario escolar 9 a 14"; the nurseries' are ten to one): the little ones in its sandy
## yard, the bigger ones on its pitch and its playground.
##
## They are neighbours like any other, made once when the game starts; out of hours they are at home (`away`), and they
## come out and go in only while nobody is looking at the yard, so nobody appears out of thin air. While out they run
## from one spot to another, stand about, hop now and then.
##
## And every child at play, these and the square's (meta "crio"), shouts to the others now and then while you are near
## (Loc "crio_grito"). What they say when you talk to them is the game's "generic_kid".
##
## Where children are out, children are heard (the user, 16 November 2026: "Deberíamos añadir ruidos de libre uso de
## niños jugando cuando haya zonas con niños"): a recording of children at play in a park, CC0 (BigSoundBank #1082,
## Joseph Sardin; tools/sonidos_origen/CREDITOS.txt), looped in the square's playground and in each nursery yard --
## a little higher in the yards, where they are smaller -- from wherever it is in the town, fading with distance, and
## only while they are out.

const PER_YARD := 5
const LOOK_T := 3.0                   # seconds between looks at the clock
const OUT_FROM := 10.0                # the yard's hours, on school days (Monday to Friday)
const OUT_TO := 13.0
const SHOUT_R := 16.0                 # how near you must be to hear them
const FAR := 90.0                     # beyond this nobody is about to see them: they wait where they are
const SOUND := "res://assets/audio/ninos_jugando.ogg"
const SOUND_DB := -3.0                # how loud, a few metres from them
const HEARD := 55.0                   # metres: beyond this they are not heard
## Children in the street (the user, 17 Nov 2026): "los niños no pueden estar en la calle en horario lectivo ni en
## horario de madrugada", and "Niño Negro Gordo de Pueblo solo puede spawnear a la misma hora que el resto de los
## niños". The children out walking (the town's anonymous ones with a child's voice) and the Niño Negro go home in
## school hours, Monday to Friday, and at night; like the yards', only while nobody sees them go or come. (The square's
## playground keeps its own hours, which already leave out both: plaza.gd _play_time.)
const SCHOOL := [9.0, 14.0]           # school hours, Monday to Friday
const KIDS_FROM := 8.0                # out in the street from...
const KIDS_TO := 23.0                 # ...until

var G
var yards: Array = []                 # {name, place, spots: [map points], c: map middle, r, kids: [{n, do, t, goal, speed, stuck}], out}
var _t := 0.0
var _shout_t := 3.0
var _criers: Array = []
var _criers_t := 0.0
var sounds: Array = []                # {name, p: AudioStreamPlayer3D, out: Callable -> bool}

func setup(game) -> void:
	G = game
	var w = game.world
	if w == null:
		return
	if w.calasanz != null:                       # its play floor, left of the house, and the front yard behind the railings
		_add_yard("calasanz", w.calasanz, [Vector2(-6.2, -2.6), Vector2(-3.4, -6.4), Vector2(-4.7, 0.2), Vector2(-1.3, -4.6), Vector2(-5.8, -4.8),
			Vector2(-3.6, 1.8), Vector2(-0.6, 3.0), Vector2(1.8, 2.4), Vector2(4.2, 2.6)], 0.0, w.calasanz.PLOT)
	if w.caridad != null:                        # between its slide, swings, horses, sandpit, hopscotch and little goal
		_add_yard("caridad", w.caridad, [Vector2(29.8, -1.4), Vector2(38.0, -1.8), Vector2(40.0, -2.2), Vector2(43.0, -1.8), Vector2(45.0, -2.2),
			Vector2(46.6, -3.4), Vector2(41.5, -5.4), Vector2(43.6, -6.2), Vector2(49.2, -1.2)], float(w.caridad.fn), w.caridad.YARD)
	if w.colegiopub != null:                    # its three yards (colegiopub.gd KID_YARDS) lie on the sloping ground: each child on the floor under it, no deck
		var cp = w.colegiopub
		for yd in cp.KID_YARDS:
			var first: Vector2 = cp.map_at((yd[1][0] as Vector2).x, (yd[1][0] as Vector2).y)
			_add_yard(String(yd[0]), cp, yd[1], MapData.foot(first) - float(cp.level), [], yd[2])
			var made: Dictionary = yards.back()
			made["slope"] = true
			made["eye"] = cp.map_at((yd[3] as Vector2).x, (yd[3] as Vector2).y)      # (where its picture is taken from)
			made["hours"] = Vector2(SCHOOL[0], SCHOOL[1])          # (the user, 27 Nov 2026: "Horario escolar 9 a 14")
			made["out"] = play_time(made["hours"])
			for k in made["kids"]:
				_send(made, k, bool(made["out"]))
	for y in yards:
		_add_sound(y["name"], Vector3((y["c"] as Vector2).x, float(y["top"]) + 1.0, (y["c"] as Vector2).y), 1.12, func(): return bool(y["out"]))
	if w.plaza != null:                          # (the square's children are plaza.gd's: heard while they are out)
		var pl = w.plaza
		var c: Vector2 = pl.spot(pl.PLAY.x, pl.PLAY.y)
		_add_sound("plaza", Vector3(c.x, MapData.foot(c) + 1.0, c.y), 1.0, func(): return bool(pl._kids_out))

func _add_sound(sound_name: String, at: Vector3, pitch: float, out: Callable) -> void:
	var s = load(SOUND) if ResourceLoader.exists(SOUND) else null
	if s == null:
		return
	s.loop = true
	var p := AudioStreamPlayer3D.new()
	p.stream = s
	p.bus = "SFX"
	p.pitch_scale = pitch
	p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE      # (at 8 m as loud as it is; at 20, a murmur; at 50, a whisper)
	p.unit_size = 8.0
	p.max_distance = HEARD
	p.volume_db = -60.0
	G.add_child(p)
	p.global_position = at
	sounds.append({"name": sound_name, "p": p, "out": out})

## each one up while its children are out and you are in the town, down otherwise; started at some point of the
## recording of its own, so two places are never heard in step
func _hear(dt: float) -> void:
	var in_world: bool = G.phase in ["play", "free", "talking", "failed", "flyover", "cutscene", "boxing", "ajedrez"] and not G.paused and not G.map_open
	for s in sounds:
		var p: AudioStreamPlayer3D = s["p"]
		var want: float = SOUND_DB if in_world and (s["out"] as Callable).call() and p.global_position.distance_to(G.player.global_position) < HEARD + 10.0 else -60.0
		p.volume_db = move_toward(p.volume_db, want, 30.0 * dt)
		if p.volume_db > -58.0 and not p.playing:
			p.play(randf() * p.stream.get_length())
		elif p.volume_db <= -59.0 and p.playing:
			p.stop()

func _add_yard(yard_name: String, place, local: Array, floor_y: float, outline: Array, size := Vector2(0.5, 0.58)) -> void:
	var top: float = float(place.level) + floor_y
	var spots: Array = []
	var c := Vector2.ZERO
	for q in local:
		var m: Vector2 = place.spot((q as Vector2).x, (q as Vector2).y)
		spots.append(m)
		c += m / local.size()
	# (a yard raised over the street with nothing under it for people to stand on: the children would stand in the ground)
	if absf(MapData.foot(spots[0]) - top) > 0.12:
		MapData.decks.append(place._poly_deck(PackedVector2Array(outline), top))
	var r := 0.0
	for m in spots:
		r = maxf(r, c.distance_to(m))
	var y := {"name": yard_name, "place": place, "spots": spots, "c": c, "r": r, "kids": [], "out": false, "top": top}
	var kind: int = G.NEIGHBOUR_VOICES.find("kid")
	for i in range(PER_YARD):
		var look: Dictionary = G._neighbour_look("kid")
		look["voice_i"] = kind
		look["scale"] = randf_range(size.x, size.y)  # (little ones: smaller than the square's; the Colegio Público's bigger ones as big as the street's)
		look["hat"] = ""
		var n = G.spawn_neighbour(spots[(i * 3) % spots.size()], true, look)
		n.set_meta("crio", true)
		y["kids"].append({"n": n, "do": "stand", "t": randf_range(1.0, 4.0), "goal": Vector2.ZERO, "speed": randf_range(1.8, 2.6), "stuck": 0.0})
	yards.append(y)
	var out := play_time()
	y["out"] = out
	for k in y["kids"]:
		_send(y, k, out)

## may a child be out in the street now?
func street_time() -> bool:
	if G.clock < KIDS_FROM or G.clock >= KIDS_TO:
		return false
	return int(G.weekday) >= 5 or G.clock < SCHOOL[0] or G.clock >= SCHOOL[1]

## the children of the street: the anonymous ones with a child's voice, out and about, and the Niño Negro
func _street_kids() -> Array:
	var out: Array = []
	for n in G.npcs:
		if n.voice != "kid" or n.has_meta("crio") or not (n.id == "" or n.id == "nino_negro") or n.state == "fly" or n.state == "down":
			continue
		if n.id == "" and n.still:                # (one of a crowd standing somewhere: not out and about)
			continue
		out.append(n)
	return out

func _street(out: bool) -> void:
	for n in _street_kids():
		if n.away == (not out) or G.sees(n.p):
			continue
		if G.dlg != null and G.dlg.get("from") == n:
			continue
		n.away = not out
		n.visible = out
		if not out:
			n.state = "idle"

## school days, in the middle of the morning (or in `hours`: a yard of its own, the Colegio Público's); never in the rain
func play_time(hours := Vector2(OUT_FROM, OUT_TO)) -> bool:
	if G.rain > 0.3 or int(G.weekday) >= 5:
		return false
	return G.clock >= hours.x and G.clock < hours.y

func _process(dt: float) -> void:
	if G == null:
		return
	_hear(dt)
	if G.paused or G.phase == "title":
		return
	_t -= dt
	if _t <= 0.0:
		_t = LOOK_T
		_street(street_time())
		for y in yards:
			var want := play_time(y.get("hours", Vector2(OUT_FROM, OUT_TO)))
			if want != bool(y["out"]) and not _watched(y):
				y["out"] = want
				for k in y["kids"]:
					_send(y, k, want)
	for y in yards:
		if bool(y["out"]) and (G.player.p as Vector2).distance_squared_to(y["c"]) < FAR * FAR:
			for k in y["kids"]:
				_kid(y, k, dt)
	_shouts(dt)

## out to play (standing somewhere in the yard), or home
func _send(y: Dictionary, k: Dictionary, out: bool) -> void:
	var n = k["n"]
	if not is_instance_valid(n):
		return
	n.y = 0.0
	n.inner.rotation.x = 0.0
	n.away = not out
	n.visible = out
	n.p = (y["spots"] as Array).pick_random()
	_stand(y, k)
	if not out:
		n.state = "busy"
	n.sync()

## whether anybody would see them come or go: you are by the yard, or it is in front of the camera
func _watched(y: Dictionary) -> bool:
	var c: Vector2 = y["c"]
	if (G.player.p as Vector2).distance_to(c) < float(y["r"]) + 8.0:
		return true
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return false
	for m in [c] + (y["spots"] as Array):
		var at := Vector3((m as Vector2).x, float(y["top"]) + 0.6, (m as Vector2).y)
		if cam.global_position.distance_to(at) < 150.0 and cam.is_position_in_frustum(at):
			return true
	return false

func _stand(y: Dictionary, k: Dictionary) -> void:
	var n = k["n"]
	n.state = "idle"
	n.home = n.p
	k["do"] = "stand"
	k["t"] = randf_range(2.0, 6.0)
	var to: Vector2 = (y["c"] as Vector2) - n.p                   # (facing into the yard, where the others are)
	if to.length() > 0.2:
		n.h = atan2(to.x, to.y)

func _kid(y: Dictionary, k: Dictionary, dt: float) -> void:
	var n = k["n"]
	if not is_instance_valid(n) or n.away:
		return
	if n.state == "fly" or n.state == "down":                     # (sent flying: the game picks them up)
		k["do"] = "stand"
		k["t"] = 2.0
		return
	if G.dlg != null and G.dlg.get("from") == n:                  # (you are talking to them: they stop and listen)
		if k["do"] != "stand":
			_stand(y, k)
		k["t"] = maxf(float(k["t"]), 2.0)
		return
	match String(k["do"]):
		"stand":
			if n.state != "idle":
				_stand(y, k)
			k["t"] = float(k["t"]) - dt
			if randf() < dt * 0.3:
				n.hop()
			if float(k["t"]) <= 0.0:
				var goal: Vector2 = (y["spots"] as Array).pick_random()
				if goal.distance_to(n.p) > 0.8:
					k["goal"] = goal
					k["do"] = "run"
					k["stuck"] = 0.0
					n.state = "busy"
				else:
					k["t"] = randf_range(1.0, 3.0)
		"run":
			var gv: Vector2 = (k["goal"] as Vector2) - n.p
			if gv.length() < 0.35:
				_stand(y, k)
				return
			var dir: Vector2 = gv.normalized()
			var was: Vector2 = n.p
			var sp: float = k["speed"]
			n.walk(dir, sp)
			n.h = lerp_angle(n.h, atan2(dir.x, dir.y), 1.0 - exp(-10.0 * dt))
			n.anim(true, dt, sp)
			n.sync()
			k["stuck"] = float(k["stuck"]) + dt if n.p.distance_to(was) < sp * dt * 0.3 else 0.0
			if float(k["stuck"]) > 0.8:                         # (something in the way: they stop where they are)
				_stand(y, k)

## now and then, one of the children playing near you shouts something to the others
func _shouts(dt: float) -> void:
	_criers_t -= dt
	if _criers_t <= 0.0:                                          # (the square's are made a little after the game starts)
		_criers_t = 10.0
		_criers = G.npcs.filter(func(n): return n.has_meta("crio"))
	_shout_t -= dt
	if _shout_t > 0.0:
		return
	_shout_t = randf_range(2.5, 5.5)
	if G.dlg != null or not (G.phase == "play" or G.phase == "free"):
		return
	var pp: Vector2 = G.player.p
	var near: Array = []
	for n in _criers:
		if is_instance_valid(n) and not n.away and n.visible and n.state != "fly" and not n.is_barking() and (n.p as Vector2).distance_to(pp) < SHOUT_R:
			near.append(n)
	if near.is_empty():
		return
	(near.pick_random()).bark(Loc.t("crio_grito").pick_random(), 2.2)
