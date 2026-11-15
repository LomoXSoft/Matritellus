extends Node
## Breakdowns and the tow truck. A neighbour whose car has got nowhere for half a minute gives up: gets out, stands in
## front of it and rings for the grúa, saying one of four things into the phone. A little way off, where you cannot see it, a tow
## truck sets out. It drives up like any other traffic (traffic.gd does the driving: it is an entry with a route),
## pulls up past the car, winches it on by whichever end is nearer, and hauls it to the nearest garage, where the car is
## left mended and parked. If you are far away and not looking, the whole scene is simply cleared away.
##
## A job: {car, driver, state: call | wait | hook | tow, t, truck (the traffic entry, or null), front (hooked by the nose?),
##         centre (where the towed car is), dest (the garage), ...timers}

const CALL_FOR := 8.0         # seconds on the phone
const HOOK_FOR := 2.2         # seconds to winch the car on

var game
var jobs: Array = []
var _blink := 0.0

func setup(game_) -> void:
	game = game_

func clear() -> void:
	for job in jobs.duplicate():
		_scrap(job)

func _dir(h: float) -> Vector2:
	return Vector2(sin(h), cos(h))

# ---------------- the breakdown ----------------
## this car is going nowhere: its driver gets out and rings for help
func breakdown(c) -> Dictionary:
	c.park()
	c.set_speed(Vector2.ZERO)
	var f := _dir(c.h)
	var spot: Vector2 = c.p + f * (float(c.spec["len"]) / 2.0 + 1.3)
	var d = game.spawn_neighbour(spot, true, c.riders[0])       # (whoever was at the wheel, now out of it)
	c.seat({})
	d.h = atan2(-f.x, -f.y)                     # looking at the car, as if that helped
	d.phone = true
	d.sync()
	var job := {"car": c, "driver": d, "state": "call", "t": 0.0, "say": 0.4, "line": randi() % 4, "truck": null, "retry": 0.0, "route_t": 0.0, "close_t": 0.0,
		"front": true, "centre": c.p, "dest": c.p, "from": c.global_transform, "dir": f}
	jobs.append(job)
	return job

## the string of junctions from one place to another, as traffic.gd wants it
func _route(from: Vector2, to: Vector2) -> Array:
	var out: Array = [MapData.nearest_node(from)]
	for q in MapData.path(from, to):
		var n: int = MapData.nearest_node(q)
		if n == out[-1]:
			continue
		var s = MapData.seg_between(out[-1], n)
		if s != null and MapData.drivable(s):
			out.append(n)
	return out

## ...ending with a run along the very stretch of street the car is standing in, so the truck drives past it
func _route_to_car(from: Vector2, car_p: Vector2) -> Array:
	var r: Dictionary = MapData.nearest_road(car_p)
	var seg = r["seg"]
	var out := _route(from, MapData.nodes[seg.na])
	if out.is_empty() or out[-1] != seg.na:
		return out
	if out.size() < 2 or out[-2] != seg.nb:
		out.append(seg.nb)
	return out

var force_from = null                          # (tests only: the truck sets out from the street corner nearest this point)

func _send_truck(job: Dictionary, pp: Vector2) -> void:
	var cp: Vector2 = job["car"].p
	for k in range(8):
		var spot = MapData.random_node_near(cp, 70.0, 170.0) if force_from == null else MapData.nodes[MapData.nearest_node(force_from)]
		if spot == null:
			return
		var at: Vector2 = spot
		if at.distance_to(pp) < 60.0 or game.sees(at):
			continue                             # not where you would watch it pop out of thin air
		var nodes := _route_to_car(at, cp)
		if nodes.size() < 2:
			continue
		if force_from == null and not _room_at(MapData.nodes[nodes[0]]):
			continue                                 # a car parked on that corner: it would come out on top of it, and stay there
		var e: Dictionary = game.traffic.add("grua", 0, nodes[0], nodes[1])
		e["route"] = nodes.slice(2)
		e["job"] = true
		job["truck"] = e
		job["t"] = 0.0
		job["route_t"] = 6.0
		job["close_t"] = 0.0
		return

## nothing parked or driving where the truck would appear (it is ~7 m long, and comes out on the street corner itself)
const ROOM := 7.5
func _room_at(at: Vector2) -> bool:
	for c in game.cars:
		if is_instance_valid(c) and c.p.distance_to(at) < ROOM:
			return false
	for e in game.traffic.list:
		if is_instance_valid(e["car"]) and e["car"].p.distance_to(at) < ROOM:
			return false
	return true

## where the garage nearest to here is
func _garage(from: Vector2) -> Vector2:
	var best := from
	var bd := 1e12
	for r in game.props.repairs:
		var d: float = (r["p"] as Vector2).distance_squared_to(from)
		if d < bd:
			bd = d
			best = r["p"]
	return best

# ---------------- hooking up and hauling ----------------
func _hitch(tc) -> Vector2:
	return tc.p - _dir(tc.h) * (float(tc.spec["len"]) / 2.0 + 0.35)

## how the car sits on the hook: dir points from the car's middle to the hitch
func _towed(job: Dictionary, dir: Vector2) -> Transform3D:
	var c = job["car"]
	var half: float = float(c.spec["len"]) / 2.0
	var centre: Vector2 = _hitch(job["truck"]["car"]) - dir * (half + 0.25)
	var heading := atan2(dir.x, dir.y) + (0.0 if job["front"] else PI)
	var tilt := -0.19 if job["front"] else 0.19            # the end on the hook rides high
	return Transform3D(Basis(Vector3.UP, heading) * Basis(Vector3.RIGHT, tilt), Vector3(centre.x, MapData.height(centre) + 0.12 + half * 0.19, centre.y))

func _hook(job: Dictionary) -> void:
	var c = job["car"]
	var e: Dictionary = job["truck"]
	var tc = e["car"]
	e["halt"] = true
	c.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	c.freeze = true
	c.collision_layer = 0
	c.collision_mask = 0
	var tail := _hitch(tc)
	var f := _dir(c.h)
	var half: float = float(c.spec["len"]) / 2.0
	job["front"] = (c.p + f * half).distance_to(tail) <= (c.p - f * half).distance_to(tail)      # whichever end is nearer
	job["dir"] = (tail - c.p).normalized() if tail.distance_to(c.p) > 0.1 else f
	job["from"] = c.global_transform
	job["state"] = "hook"
	job["t"] = 0.0
	var d = job["driver"]
	d.phone = false
	d.bark(Loc.t("tow_here").pick_random(), 3.5)
	if tc.p.distance_to(game.player.p) < 60.0:
		Sfx.beep(180.0, 0.5, 3, -16.0, 60.0)        # the winch

func _set_off(job: Dictionary) -> void:
	var e: Dictionary = job["truck"]
	var d = job["driver"]
	d.away = true                                # climbs into the cab
	d.visible = false
	job["centre"] = Vector2(job["car"].global_position.x, job["car"].global_position.z)
	job["dest"] = _garage(e["car"].p)
	e["halt"] = false
	e["towing"] = true                           # (with a car on the hook it is in no hurry: it drives like anybody, traffic.gd on_duty)
	e["route"] = _route(MapData.nodes[e["b"]], job["dest"])
	job["route_t"] = 6.0
	job["state"] = "tow"
	job["t"] = 0.0

## at the garage: the car comes off the hook, mended, and is left parked at the kerb
func deliver(job: Dictionary) -> void:
	var c = job["car"]
	var e = job["truck"]
	var at: Vector2 = job["centre"]
	var r: Dictionary = MapData.nearest_road(at)
	var u: Vector2 = r["u"]
	var side: float = minf(r["seg"].hw - 1.25, maxf(0.0, MapData.side_room(r) - 1.7))
	var which := 1.0 if (at - (r["p"] as Vector2)).dot(Vector2(-u.y, u.x)) >= 0.0 else -1.0
	c.freeze = false
	c.collision_layer = 2
	c.collision_mask = 1 | 2 | 8 | 32
	c.place((r["p"] as Vector2) + Vector2(-u.y, u.x) * side * which, atan2(u.x, u.y))
	c.repair()
	c.park()
	game.cars.append(c)
	_dismiss(job)
	if e != null:
		e.erase("job")
		e.erase("towing")
		e["halt"] = false
		e["route"] = []
	jobs.erase(job)

## the driver goes home
func _dismiss(job: Dictionary) -> void:
	var d = job["driver"]
	if d != null and is_instance_valid(d):
		game.npcs.erase(d)
		d.queue_free()
	job["driver"] = null

## clear the whole scene away: car, driver and truck
func _scrap(job: Dictionary) -> void:
	_dismiss(job)
	var c = job["car"]
	if is_instance_valid(c):
		c.queue_free()
	var e = job["truck"]
	if e != null and game.traffic.list.has(e):
		game.traffic.list.erase(e)
		if is_instance_valid(e["car"]):
			e["car"].queue_free()
	jobs.erase(job)

## the truck has gone (stolen, most likely): whatever it was pulling is left where it is
func _let_go(job: Dictionary) -> void:
	var c = job["car"]
	if c.freeze:
		c.freeze = false
		c.collision_layer = 2
		c.collision_mask = 1 | 2 | 8 | 32
		c.place(Vector2(c.global_position.x, c.global_position.z), c.h)
		c.park()

func tick(dt: float, pp: Vector2, frozen: bool) -> void:
	if frozen:
		return
	_blink += dt
	for job in jobs.duplicate():
		var c = job["car"]
		if not is_instance_valid(c):                 # (the car itself taken away by something else: there is no job left)
			_dismiss(job)
			if job["truck"] != null and is_instance_valid(job["truck"]["car"]):
				job["truck"].erase("job")
			jobs.erase(job)
			continue
		var cp := Vector2(c.global_position.x, c.global_position.z)
		var far := cp.distance_to(pp)
		if far > 230.0 and not game.sees(cp):        # nobody is watching: no need to act it all out
			_scrap(job)
			continue
		var e = job["truck"]
		if e != null and (not game.traffic.list.has(e) or not is_instance_valid(e["car"])):   # the truck is no longer ours (or no longer there)
			_let_go(job)
			if job["state"] == "tow" or job["state"] == "hook":
				_dismiss(job)
				game.cars.append(c)
				jobs.erase(job)
				continue
			job["truck"] = null
			e = null
		if e != null:                                # working lights
			for l in e["car"].lights:
				l.visible = int(_blink * 3.0) % 2 == 0
		job["t"] += dt
		var d = job["driver"]
		match job["state"]:
			"call":
				job["say"] -= dt
				if job["say"] <= 0.0:
					job["say"] = 2.4
					d.bark(Loc.t("tow_call")[job["line"]], 2.3)
					if far < 30.0:
						for k in range(5):
							get_tree().create_timer(k * 0.11).timeout.connect(Sfx.voice.bind("aeiou".substr(randi() % 5, 1), d.voice))
				if job["t"] > CALL_FOR:
					d.phone = false
					d.bark(Loc.t("tow_called").pick_random(), 3.5)
					job["state"] = "wait"
					job["t"] = 0.0
					job["say"] = 9.0
			"wait":
				job["say"] -= dt
				if job["say"] <= 0.0:
					job["say"] = randf_range(8.0, 13.0)
					d.bark(Loc.t("tow_wait").pick_random(), 3.2)
				if e == null:
					job["retry"] -= dt
					if job["retry"] <= 0.0:
						job["retry"] = 2.0
						_send_truck(job, pp)
					continue
				var tc = e["car"]
				job["route_t"] -= dt
				if job["route_t"] <= 0.0:
					job["route_t"] = 6.0
					e["route"] = _route_to_car(MapData.nodes[e["b"]], cp).slice(1)
				var rel: Vector2 = cp - tc.p
				var dist := rel.length()
				if dist < 14.0:
					if tc.vel.length() < 0.6:
						job["close_t"] += dt
					var passed: bool = rel.dot(_dir(tc.h)) < -(float(tc.spec["len"]) / 2.0 + 1.0)
					if (passed and dist < 12.5) or job["close_t"] > 5.0:
						_hook(job)
				elif job["t"] > 90.0 and not game.sees(cp) and not game.sees(tc.p):
					_scrap(job)                      # it never got here, and nobody saw
			"hook":
				if e == null:
					continue
				var k := smoothstep(0.0, 1.0, float(job["t"]) / HOOK_FOR)
				c.global_transform = (job["from"] as Transform3D).interpolate_with(_towed(job, job["dir"]), k)
				if job["t"] >= HOOK_FOR:
					_set_off(job)
			"tow":
				if e == null:
					continue
				var tc2 = e["car"]
				var hitch := _hitch(tc2)
				var lead: Vector2 = hitch - (job["centre"] as Vector2)
				var dir: Vector2 = lead.normalized() if lead.length() > 0.05 else (job["dir"] as Vector2)
				job["dir"] = dir
				c.global_transform = _towed(job, dir)
				job["centre"] = Vector2(c.global_position.x, c.global_position.z)
				job["route_t"] -= dt
				if job["route_t"] <= 0.0 and (e["route"] as Array).is_empty():
					job["route_t"] = 6.0
					e["route"] = _route(MapData.nodes[e["b"]], job["dest"]).slice(1)
				if tc2.p.distance_to(job["dest"]) < 24.0 or job["t"] > 150.0:
					deliver(job)
