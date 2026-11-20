extends Node
## Neighbours out driving. A dozen cars cruise the streets around the player: they keep to the right and follow the
## road from junction to junction. They appear a little way off and are removed when left far behind.
##
## Now and then one of them is a patrol car of Los Pitufos on its beat: it drives like anybody else, but if it sees
## you with a turbo lit it comes after you there and then (game.gd asks, police.gd takes the car over).
##
## How they cope with what is in the way:
##   people                 in the road: they stop, wait, and lean on the horn (people on the pavement are left alone)
##   a car going their way  they follow it at its speed
##   something standing     (a parked car, a trailer, a car that has given up) they pull out round it on whichever
##                          side has room, slowly, after letting anything coming the other way go by
##   no room either side    they wait a few seconds, then turn round and go back the way they came
##   wedged                 if they are trying to move and are not moving, they back off a little with the wheels
##                          turned and try again; a target behind them is reached with a three-point turn

const CarS = preload("res://scripts/car.gd")
## Far off, a neighbour's car goes along its lane on its own, without the physics (the user, 17 Nov 2026: "Si, coches
## lejanos sin física completa"; a car driving cost the engine about half a millisecond a tick wherever it was): this far
## from you, or this far when it is out of the picture; and back to a real car nearer than RAILS_BACK, or than
## RAILS_FROM - 20 in the picture. Never the tow truck on a job, one with somewhere to be, or yours on autopilot.
const RAILS_FROM := 110.0
const RAILS_HIDDEN := 70.0
const RAILS_BACK := 60.0
var rails := true               # (the self-test's --perfil turns it off to compare)
const MAX_CARS := 10            # (14 until 17 Nov 2026: each car driving costs about half a millisecond a frame; the user, measured: "Baja y vuelve a medir")
const CRUISE := 9.0
const STUCK_FOR := 30.0        # seconds getting nowhere before the driver gives up and rings for the tow truck
const PERSON := 1
const VEHICLE := 0
const FIXED := 2

var game
var list: Array = []          # {car, a, b, wait, honk, lat, stuck, rev, rs, tries}
var _spawn_t := 2.0
var _pool: Array = []         # cars left far behind, put away to be used again (building one from nothing takes several
                              # milliseconds -- a hitch every time a neighbour drove into view)
const POOL := 10
var _warm: Array = []         # one of each kind never pooled (patrol cars, the tow truck), built while loading and kept hidden (prewarm)
var max_cars := MAX_CARS        # (the graphics option "traffic": fewer when it is light)
var _obs: Array = []          # what there is to run into this tick: [position, radius, velocity, kind, owner]
var _still: Array = []        # ...of which what stands still (asleep parked cars, the trailers): made again twice a second
var _still_t := 0
const CELL := 38.0
var _cells := {}              # the same, by map cell (Vector2i -> Array), so each car only looks at its surroundings

func setup(game_) -> void:
	game = game_

## While the game loads: a car of each of the commoner makes, built and put away, so that the first ones to drive into
## view do not have to be built there and then (that was a hitch each time).
func prewarm() -> void:
	for kind in ["panda", "panda", "panda", "z15", "z15", "z15", "tractor", "yondir", "tunero", "edison", "julietta"]:
		var c = CarS.new()
		game.add_child(c)
		c.setup(kind, 0, Vector2(0, -5000), 0.0)
		c.seat(game.driver_look())
		_put_away(c)
	# One each of those never put back in the pool (Los Pitufos on their beat, three spawns in ten; the Tricornios; the
	# tow truck): built once here, kept out of sight, so that the first of each out on the road is not built from
	# nothing in the middle of the game -- a hitch of about 22 ms (measured 17 Nov 2026, "--tirones": traffic 22.5).
	for kind in ["pitufo", "tricornio", "grua"]:
		var c = CarS.new()
		game.add_child(c)
		c.setup(kind, 0, Vector2(0, -5000), 0.0)
		c.seat(game.officer_look(kind) if (kind == "pitufo" or kind == "tricornio") else game.driver_look())
		c.visible = false
		c.set_speed(Vector2.ZERO)
		c.place(Vector2(-6000.0 - (_pool.size() + _warm.size()) * 12.0, -6100.0), 0.0)
		c.doze(true)
		_warm.append(c)

## Whether this car goes along its lane on its own this tick (and if so, it is moved): far off, or out of the picture a
## little nearer. Coming back near, it is a real car again with the speed it had -- once it is clear of every other car.
func _rails(e: Dictionary, c, cp: Vector2, far: float, dt: float) -> bool:
	var on: bool = e.has("rail")
	if not rails or e.get("auto", false) or e.has("job") or not (e.get("route", []) as Array).is_empty():
		if on:
			_off_rails(e, c)
		return false
	var seen: bool = game.cam != null and game.cam.is_position_in_frustum(Vector3(cp.x, c.global_position.y + 1.0, cp.y))
	var want: bool
	if on:
		want = not (far < RAILS_BACK or (seen and far < RAILS_FROM - 20.0))
		if not want and not _clear_of_cars(c, cp):
			want = true                               # (it would land on top of another: one more tick along the lane)
	else:
		want = far > RAILS_FROM or (far > RAILS_HIDDEN and not seen)
	if not want:
		if on:
			_off_rails(e, c)
		return false
	if not on:
		e["rail"] = maxf(4.0, c.forward_speed())
		c.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		c.freeze = true
		c.set_physics_process(false)
	_rail_move(e, c, cp, dt)
	return true

func _off_rails(e: Dictionary, c) -> void:
	var v: float = float(e.get("rail", 0.0))
	e.erase("rail")
	c.freeze = false
	c.set_physics_process(true)
	var f := Vector3(sin(c.h), 0.0, cos(c.h))
	c.linear_velocity = f * v
	c.angular_velocity = Vector3.ZERO

func _clear_of_cars(c, cp: Vector2) -> bool:
	var room: float = float(c.spec["len"]) * 0.5 + 2.2
	for o in game.cars:
		if is_instance_valid(o) and o != c and o.visible and (o.p as Vector2).distance_squared_to(cp) < room * room:
			return false
	for o in list:
		var oc = o["car"]
		if oc != c and is_instance_valid(oc) and (oc.p as Vector2).distance_squared_to(cp) < room * room:
			return false
	return true

## how many are going along their lane just now (the self-test)
func on_rails() -> int:
	return list.filter(func(e): return e.has("rail")).size()

## along its lane at its own pace, slowing for one going the same way just ahead; at the junction the usual choice of
## the way on is made (tick), and it carries on from there
func _rail_move(e: Dictionary, c, cp: Vector2, dt: float) -> void:
	var from: Vector2 = MapData.nodes[e["a"]]
	var to: Vector2 = MapData.nodes[e["b"]]
	var d := to - from
	var length := d.length()
	if length < 0.01:
		return
	var u := d / length
	var rightv := Vector2(-u.y, u.x)
	var s = MapData.seg_between(e["a"], e["b"])
	var hw: float = MapData.fitted_hw(s) if s != null else 3.0
	var lane := clampf(hw * 0.3, 0.6, 1.25)
	var along := (cp - from).dot(u)
	var want: float = CRUISE * float(e.get("pace", 1.0)) * (0.7 if c.spec.get("tractor", false) else 1.0)
	for o in list:
		if o == e or o["a"] != e["a"] or o["b"] != e["b"] or not is_instance_valid(o["car"]):
			continue
		var oa: float = ((o["car"].p as Vector2) - from).dot(u)
		if oa > along and oa - along < 9.0:
			want = 0.0
	var v: float = move_toward(float(e["rail"]), want, 4.0 * dt)
	e["rail"] = v
	along = minf(length, along + v * dt)
	var pos := from + u * along + rightv * lane
	var up := MapData.normal(pos)
	var fwd := Vector3(u.x, 0.0, u.y)
	fwd = (fwd - up * fwd.dot(up)).normalized()
	c.global_transform = Transform3D(Basis(up.cross(fwd), up, fwd), MapData.at(pos, 0.12))

## A car out of use: invisible, out of the physics, and out of the town altogether (left where it was, it was an
## invisible wall in the street)
func _put_away(c) -> void:
	if c.freeze and c.freeze_mode == RigidBody3D.FREEZE_MODE_KINEMATIC and not c.dozing:
		c.freeze = false                          # (it was going along its lane: _rails)
		c.set_physics_process(true)
	c.visible = false
	c.set_speed(Vector2.ZERO)
	c.place(Vector2(-6000.0 - _pool.size() * 12.0, -6000.0), 0.0)
	c.doze(true)
	_pool.append(c)

func clear() -> void:
	_still_t = 0
	for e in list:
		if not e.get("auto", false):             # (the player's own car on autopilot is not ours to scrap)
			e["car"].queue_free()
	list.clear()
	for c in _pool:
		if is_instance_valid(c):
			c.queue_free()
	_pool.clear()

## the string of junctions from one place to another
func route_nodes(from: Vector2, to: Vector2) -> Array:
	var out: Array = [MapData.nearest_node(from)]
	for q in MapData.path(from, to):
		var n: int = MapData.nearest_node(q)
		if n == out[-1]:
			continue
		var s = MapData.seg_between(out[-1], n)
		if s != null and MapData.drivable(s):
			out.append(n)
	return out

## The autopilot: takes a car that is already out there (the player's) and drives it like any neighbour's, to `goal`
## if there is one and wherever the road goes if not. Returns its entry, or {} if the car is not on a street.
func adopt(c, goal = null) -> Dictionary:
	var r: Dictionary = MapData.nearest_road(c.p)
	if r.is_empty() or (r["p"] as Vector2).distance_to(c.p) > 9.0 or not MapData.drivable(r["seg"]):
		return {}
	var s = r["seg"]
	var a: int = s.na
	var b: int = s.nb
	var facing := Vector2(sin(c.h), cos(c.h))
	var flip: bool = (s.b - s.a).dot(facing) < 0.0          # by default, the way the car is pointing
	if goal != null:                                        # ...unless there is somewhere to be: then the shorter way round
		var best := INF
		for end in [[s.nb, false], [s.na, true]]:
			var at: Vector2 = MapData.nodes[end[0]]
			var far: float = c.p.distance_to(at)
			var last := at
			for q in MapData.path(at, goal):
				far += q.distance_to(last)
				last = q
			if (at - c.p).dot(facing) < 0.0:
				far += 25.0                                 # (turning round costs something)
			if far < best:
				best = far
				flip = end[1]
	if flip:
		a = s.nb
		b = s.na
	var e := {"car": c, "a": a, "b": b, "wait": 0.0, "honk": 0.0, "lat": 1.0, "stuck": 0.0, "rev": 0.0, "rs": 1.0, "tries": 0, "auto": true, "pace": 1.3}
	if goal != null:
		e["route"] = route_nodes(MapData.nodes[b], goal).slice(1)
	list.append(e)
	return e

func release(e: Dictionary) -> void:
	list.erase(e)

## puts a neighbour's car on the road at junction a, heading for junction b
func add(kind: String, hex: int, a: int, b: int) -> Dictionary:
	var u: Vector2 = (MapData.nodes[b] - MapData.nodes[a]).normalized()
	var c = null
	for old in _pool:                            # one of that make that was put away, if there is one (any colour: hex 0)
		if is_instance_valid(old) and old.kind == kind and hex == 0:
			c = old
			break
	_pool = _pool.filter(func(o): return is_instance_valid(o) and o != c)
	if c != null:
		c.doze(false)
		c.visible = true
		c.repair()
		c.flip_told = false
		c.last_impact = 0.0
		c.place(MapData.nodes[a] + Vector2(-u.y, u.x) * 1.0, atan2(u.x, u.y))
		c.reset_physics_interpolation()
	else:
		c = CarS.new()
		game.add_child(c)
		c.setup(kind, hex, MapData.nodes[a] + Vector2(-u.y, u.x) * 1.0, atan2(u.x, u.y))
		c.seat(game.officer_look(kind) if (kind == "pitufo" or kind == "tricornio") else game.driver_look())
	var e := {"car": c, "a": a, "b": b, "wait": 0.0, "honk": 0.0, "lat": 1.0, "stuck": 0.0, "rev": 0.0, "rs": 1.0, "tries": 0}
	list.append(e)
	return e

## A car with somewhere to be (the tow truck on its way to a breakdown, a patrol car, the delivery lorry) held up by
## a parked car it cannot get round, in a narrow street or on a corner: if nobody is looking, the parked car goes.
## They are put about the town at random, and now and then one is left where nothing bigger fits past -- the truck
## and the lorry sat behind one for minutes (found by the Pretil session, 15 November 2026).
func _clear_parked(car) -> void:
	if car == null or not is_instance_valid(car) or not game.cars.has(car) or car == game.in_car or car == game.paca_car or car.running:
		return
	if game.sees(car.p):
		return
	game.cars.erase(car)
	car.queue_free()
	_still_t = 0                                 # (gone: not to be braked for any more)

## Streets closed to the town's traffic for a while: the delivery lorry's way across town, while Don Luis's errand
## is on (the user's idea, 15 November 2026: it got stuck behind neighbours and parked cars in the narrow streets).
## Keys are the two ends of a stretch, either way round (closed_key). No new car comes out on them, and those on them
## are taken away when nobody is looking.
var closed := {}
static func closed_key(a: int, b: int) -> int:
	return mini(a, b) * 100000 + maxi(a, b)

func is_closed(a: int, b: int) -> bool:
	return not closed.is_empty() and closed.has(closed_key(a, b))

## The town's one-way streets, as the map's source has them (OpenStreetMap's "oneway", kept by the bake: the user,
## 16 November 2026, instead of putting the traffic right street by street), roundabouts and the motorway's two
## carriageways among them. Where the source says nothing, a street too narrow for two cars to pass is one way as before
## (the user, 15 November 2026: they met nose to nose in it and stuck), its way fixed from its lower-numbered end.
## Only the neighbours keep to it: you, the police after you and the cars on a job go where they must. And at a corner
## with no way on that is allowed, a car turns round as it always did.
const ONE_WAY_HW := 2.4                      # half-widths under this: a street under 4.8 m
func one_way_ok(a: int, b: int) -> bool:
	var says: int = MapData.one_way_says(a, b)
	if says != 0:
		return says > 0
	var s = MapData.seg_between(a, b)
	if s == null or MapData.fitted_hw(s) >= ONE_WAY_HW:
		return true
	return a < b

## The story starts on foot in the Calle de Alemania, Tía Paca's car at the door: until that first talk with her is
## over nobody drives down that street (no car comes out of nowhere through the scene, or through hers).
const QUIET_STREET := "Calle de Alemania"
func quiet(s) -> bool:
	return s != null and game.si <= 0 and String(s.road["n"]) == QUIET_STREET

func _spawn(pp: Vector2) -> void:
	var spot = MapData.random_node_near(pp, 120.0, 210.0)
	if spot == null:
		return
	var a := MapData.nearest_node(spot)
	var opts := MapData.neighbours(a).filter(func(o): return one_way_ok(a, o))
	if opts.is_empty():
		return
	var b: int = opts.pick_random()
	var s = MapData.seg_between(a, b)
	if s == null or not MapData.drivable(s) or quiet(s) or is_closed(a, b):
		return
	var roll := randf()
	var kind := "panda"
	if roll >= 0.36 and roll < 0.64:
		kind = "z15"
	elif roll >= 0.64 and roll < 0.76:
		kind = "tractor"
	elif roll >= 0.76 and roll < 0.83:
		kind = "yondir"
	elif roll >= 0.83 and roll < 0.88:
		kind = "tunero"
	elif roll >= 0.88 and roll < 0.96:
		kind = "edison"
	elif roll >= 0.96:
		kind = "julietta"
	if not game.police.chasing and not has_patrol() and randf() < 0.3:
		kind = "pitufo"                     # one of Los Pitufos doing the rounds: harmless, unless it sees a turbo
	add(kind, 0, a, b)

## is one of Los Pitufos out on its beat?
func has_patrol() -> bool:
	for e in list:
		if e["car"].kind == "pitufo":
			return true
	return false

# ---------------- what is out there ----------------
func _add_vehicle(c, owner = null, vel = null) -> void:
	var f := Vector2(sin(c.h), cos(c.h))
	var rr: float = c.spec["wid"] * 0.55
	var at := Vector2(c.global_position.x, c.global_position.z)
	for k in [-c.off, c.off]:                # a car is two circles: nose and tail
		_obs.append([at + f * k, rr, c.vel if vel == null else vel, VEHICLE, c if owner == null else owner])

## (The user's 2K at 30-odd fps, 16 Nov 2026: working out every parked car's two circles, every tick, was most of what
## the traffic cost. Those asleep -- `freeze`, nowhere near you -- and the trailers do not move: they are worked out
## twice a second. One woken in between is counted as moving as well, which does no harm.)
func _gather() -> void:
	_still_t -= 1
	if _still_t <= 0:
		_still_t = 30
		_obs.clear()
		for o in game.cars:
			if o.freeze and not o.running:
				_add_vehicle(o)
		for r in game.props.ramps:               # the trailers parked along the streets
			var f := Vector2(sin(r["h"]), cos(r["h"]))
			for k in [-2.6, 0.0, 2.6, 4.9]:
				_obs.append([(r["p"] as Vector2) + f * k, 1.6, Vector2.ZERO, FIXED, null])
		_still = _obs.duplicate()
	_obs = _still.duplicate()
	for o in game.cars:
		if not (o.freeze and not o.running):
			_add_vehicle(o)
	for e in list:
		_add_vehicle(e["car"])
	for e in game.police.cops:
		_add_vehicle(e["car"])
	for job in game.tow.jobs:                # broken down, or on the hook (then it belongs to the truck pulling it)
		if not is_instance_valid(job["car"]):
			continue                             # (taken away by something else: tow.gd lets the job go on its next tick)
		var truck = job["truck"]["car"] if job["truck"] != null else null
		var pulling: bool = job["state"] == "tow" and truck != null and is_instance_valid(truck)
		_add_vehicle(job["car"], truck if pulling else null, truck.vel if pulling else null)
	if game.in_car == null:
		_obs.append([game.player.p, 0.7, Vector2.ZERO, PERSON, game.player])      # (you: the one person a car on a job still brakes for)
	for n in game.npcs:
		if n.visible and not n.away:
			_obs.append([n.p, 0.6, Vector2.ZERO, PERSON, null])

func _index() -> void:
	_cells.clear()
	for o in _obs:
		var key := Vector2i(int(floor(o[0].x / CELL)), int(floor(o[0].y / CELL)))
		var list = _cells.get(key)
		if list == null:
			_cells[key] = [o]
		else:
			list.append(o)

## everything within a cell or so of this spot
func _around(p: Vector2) -> Array:
	var out: Array = []
	var cx := int(floor(p.x / CELL))
	var cy := int(floor(p.y / CELL))
	for ax in range(cx - 1, cx + 2):
		for ay in range(cy - 1, cy + 2):
			var list = _cells.get(Vector2i(ax, ay))
			if list != null:
				out.append_array(list)
	return out

## is this thing standing still (so it has to be driven round rather than waited for)?
## A vehicle on a job, in a hurry: the tow truck on its way to a breakdown (not on the way back with the car on the hook),
## or anything marked "duty" (the ambulance, one day). It does not brake for neighbours in its way (the user's idea,
## 13 November 2026). Los Pitufos and the Tricornios are the same only while they are after you (police.gd); on their
## beat they drive like everybody else.
func on_duty(e: Dictionary) -> bool:
	return (e.has("job") and not e.get("towing", false)) or e.get("duty", false)

func _standing(o: Array) -> bool:
	return o[3] == FIXED or (o[3] == VEHICLE and (o[2] as Vector2).length() < 0.8)

func _turn_round(e: Dictionary) -> void:
	e["route"] = []                          # (whoever sent it this way will have to think again)
	var a: int = e["a"]
	e["a"] = e["b"]
	e["b"] = a
	e["wait"] = 0.0
	e["tries"] = 0
	e["stuck"] = 0.0

func tick(dt: float, pp: Vector2, frozen: bool) -> void:
	_spawn_t -= dt
	if list.size() < max_cars and _spawn_t <= 0.0:
		_spawn_t = 0.7
		_spawn(pp)
	if list.is_empty():
		return
	_gather()
	_index()
	for e in list.duplicate():
		var c = e["car"]
		var cp: Vector2 = c.p
		var around := _around(cp)
		var far := cp.distance_to(pp)
		var working: bool = e.has("job")              # a tow truck on a call: tow.gd decides when it goes
		var auto: bool = e.get("auto", false)          # the player's car on autopilot: never scrapped, never towed
		if not auto and (far > 330.0 or (not working and ((e["wait"] > 16.0 and far > 40.0) or (c.flipped() and far > 60.0) or (e["tries"] >= 4 and far > 55.0) or (is_closed(e["a"], e["b"]) and not game.sees(cp))))):
			list.erase(e)
			if _pool.size() < POOL and not c.flipped() and c.kind != "pitufo" and c.kind != "grua" and c.kind != "tricornio" and not e.has("job"):
				_put_away(c)
			else:
				c.queue_free()
			continue
		if frozen:
			c.drive(0.0, 0.0, true, true, dt)
			continue
		# has it got anywhere lately? Half a minute on the same spot and the driver rings for the tow truck
		if not e.has("mark") or cp.distance_to(e["mark"]) > 4.0:
			e["mark"] = cp
			e["idle"] = 0.0
		else:
			e["idle"] = float(e["idle"]) + dt
		if e["idle"] > STUCK_FOR and not working and not auto and c.kind != "pitufo" and c.kind != "grua" and not e.has("rail"):
			list.erase(e)
			game.tow.breakdown(c)
			continue
		if c.flipped() or e.get("halt", false):
			c.drive(0.0, 0.0, true, true, dt)
			continue
		var from: Vector2 = MapData.nodes[e["a"]]
		var to: Vector2 = MapData.nodes[e["b"]]
		var d := to - from
		var length := d.length()
		var u := d / maxf(length, 0.01)
		var rightv := Vector2(-u.y, u.x)
		var along := (cp - from).dot(u)
		if along > length - 5.0:                      # reached the junction: pick the way on, preferring straight ahead
			var opts := MapData.neighbours(e["b"])
			var best := -1
			var best_score := -9.0
			var route: Array = e.get("route", [])          # somewhere to be (a tow truck): take the next turning on the list
			while not route.is_empty() and best < 0:
				var nxt: int = route.pop_front()
				var sr = MapData.seg_between(e["b"], nxt) if nxt != e["b"] else null
				if sr != null and MapData.drivable(sr):
					best = nxt
			for o in (opts if best < 0 else []):
				if o == e["a"] and opts.size() > 1:
					continue
				var s2 = MapData.seg_between(e["b"], o)
				if s2 == null or not MapData.drivable(s2) or quiet(s2) or not one_way_ok(e["b"], o):
					continue
				var score: float = (MapData.nodes[o] - to).normalized().dot(u) + randf() * 1.2
				if score > best_score:
					best_score = score
					best = o
			if best < 0:
				best = e["a"]
			e["a"] = e["b"]
			e["b"] = best
			continue
		if _rails(e, c, cp, far, dt):
			continue
		var s = MapData.seg_between(e["a"], e["b"])
		var hw: float = MapData.fitted_hw(s)
		var half: float = c.spec["wid"] / 2.0
		var nose: float = c.spec["len"] / 2.0
		var lane := clampf(hw * 0.3, 0.6, 1.25)        # keep right
		var f := Vector2(sin(c.h), cos(c.h))
		var side := Vector2(-f.y, f.x)
		var speed: float = c.forward_speed()
		var duty := on_duty(e)

		# --- the road ahead, in the street's own terms: what is standing in my lane, and is anything coming? ---
		var standing: Array = []                       # [along the street from me, across the street, radius]
		var lo := 1e9
		var hi := -1e9
		var oncoming := false
		for o in around:
			if o[4] == c:
				continue
			var rel: Vector2 = (o[0] as Vector2) - from
			var sa := rel.dot(u) - along
			if sa < -4.0 or sa > 34.0:
				continue
			var q := rel.dot(rightv)
			if absf(q) > hw + 3.0:
				continue
			if o[3] == VEHICLE and (o[2] as Vector2).dot(u) < -1.0 and sa > 2.0 and q < lane + half:
				oncoming = true
			if sa > 20.0 or not _standing(o):
				continue
			standing.append([sa, q, o[1]])
			if q + o[1] > lane - half - 0.35 and q - o[1] < lane + half + 0.35:
				lo = minf(lo, q - o[1])
				hi = maxf(hi, q + o[1])
		var target := lane
		var jam := false
		var hold := false
		if hi > lo:                                    # something is standing in my lane: which side can I get by on?
			var bound := hw - half + 0.4
			var options: Array = []
			for cand in [lo - half - 0.45, hi + half + 0.45]:
				if absf(cand) > bound:
					continue
				var clear := true
				for st in standing:
					if st[1] + st[2] > cand - half - 0.15 and st[1] - st[2] < cand + half + 0.15:
						clear = false
				if clear:
					options.append(cand)
			if options.is_empty():
				jam = true
			else:
				target = options[0]
				if options.size() > 1 and absf(options[1] - lane) < absf(options[0] - lane) - 0.3:
					target = options[1]
				hold = oncoming and target < half * 0.6          # pulling out onto the other side: wait for it to pass
				if hold:
					target = lane
		e["lat"] = move_toward(float(e.get("lat", lane)), target, 3.2 * dt)
		var dodging: bool = absf(float(e["lat"]) - lane) > 0.3
		var aim: Vector2 = from + u * minf(length, along + (6.5 if dodging else 9.0)) + rightv * float(e["lat"])
		var diff := angle_difference(c.h, atan2(aim.x - cp.x, aim.y - cp.y))
		var steer := clampf(diff * 2.2, -1.0, 1.0)

		# --- backing off: out of a wedge, or the first half of a three-point turn ---
		if float(e.get("rev", 0.0)) > 0.0:
			e["rev"] -= dt
			var behind := false
			for o in around:
				if o[4] == c:
					continue
				var rb: Vector2 = (o[0] as Vector2) - cp
				var back := -rb.dot(f)
				if back > 0.3 and back < nose + 2.0 + o[1] and absf(rb.dot(side)) < half + o[1] * 0.9:
					behind = true
			if behind:
				e["rev"] = 0.0
			else:
				c.drive(-0.65 if speed > -3.2 else 0.0, e["rs"], false, true, dt)
				c.last_impact = 0.0
				continue
		if absf(diff) > 1.9 and absf(speed) < 3.0:     # where I want to go is behind me
			e["rev"] = 1.5
			e["rs"] = -signf(diff)
			continue

		# --- right in front of the bonnet ---
		var near_d := 1e9
		var near: Array = []
		var reach := nose + 7.0 + maxf(0.0, speed) * 0.7
		for o in around:
			if o[4] == c:
				continue
			var rel2: Vector2 = (o[0] as Vector2) - cp
			var ahead := rel2.dot(f)
			if ahead < 0.4 or ahead > reach + o[1]:
				continue
			# somebody walking along the pavement is not in the way, however close to the kerb the car runs
			# (otherwise a lorry crawls down the whole street behind a neighbour out for a stroll)
			if o[3] == PERSON and absf(((o[0] as Vector2) - from).dot(rightv)) > hw - 0.5:
				continue
			if o[3] == PERSON and duty and o[4] == null:
				continue                              # (on a job it does not stop for neighbours: they had better jump. game.gd _duty_hits)
			if absf(rel2.dot(side)) < half + o[1] * (1.0 if o[3] == PERSON else 0.9) + (0.1 if o[3] == PERSON else 0.0):
				var gap: float = ahead - nose - o[1]
				if gap < near_d:
					near_d = gap
					near = o
		var want := CRUISE * float(e.get("pace", 1.0)) * (0.55 if absf(diff) > 0.35 else 1.0) * (0.7 if c.spec.get("tractor", false) else 1.0)
		if dodging:
			want = minf(want, 4.5)
		var stop := false
		var honk := false
		if not near.is_empty():
			if near[3] == PERSON:
				stop = true
				honk = true
			elif _standing(near):
				if near_d < 0.9 and not jam and not hold:          # nose up against it: back off and come at it again
					e["rev"] = 2.3
					e["rs"] = -signf(diff) if absf(diff) > 0.08 else (1.0 if e["lat"] > lane else -1.0)
					e["tries"] = int(e.get("tries", 0)) + 1
					continue
				stop = (jam or hold) and near_d < 4.5
				honk = stop and near[4] != null and near[4] == game.in_car
				want = minf(want, 2.0 + near_d * 0.55)             # creep, and steer round it
			else:
				var their: float = (near[2] as Vector2).dot(f)
				if their < -0.5:
					stop = near_d < 8.0                            # nose to nose: let it sort itself out
				else:
					want = minf(want, maxf(0.0, their) + near_d * 0.4)
					stop = near_d < 2.2
		if stop:
			e["dbg"] = [near[3], near_d, near[0]]        # (what it is waiting for: the self-test reports it if the wait goes wrong)
			e["wait"] += dt
			if near[3] == VEHICLE and e["wait"] > 3.0 and (on_duty(e) or not (e.get("route", []) as Array).is_empty()):
				_clear_parked(near[4])
			e["honk"] -= dt
			e["stuck"] = 0.0
			c.drive(0.0, steer, true, true, dt)
			if honk and e["wait"] > 2.5 and e["honk"] <= 0.0 and far < 60.0:      # ¡pero arranca!
				e["honk"] = randf_range(2.5, 5.0)
				if not Sfx.horn(c.kind, -16.0 - far * 0.15):      # (its own horn, quieter the further off it is)
					Sfx.beep(415.0, 0.32, 0, -15.0)
					Sfx.beep(330.0, 0.32, 0, -15.0)
			if jam and e["wait"] > (25.0 if e.get("patient", false) else 5.0):      # no way through: back the way I came (somebody with a round to do waits a good while first)
				_turn_round(e)
			c.last_impact = 0.0
			continue
		e["wait"] = maxf(0.0, e["wait"] - dt * 2.0)
		var thr := clampf((want - speed) * 0.45, -1.0, 1.0)
		c.drive(thr if thr > -0.3 else 0.0, steer, thr < -0.6, true, dt)
		c.last_impact = 0.0
		# trying to go and not going: wedged against something (a wall, a kerb, a bench)
		if thr > 0.2 and absf(speed) < 0.45:
			e["stuck"] = float(e.get("stuck", 0.0)) + dt
			if e["stuck"] > 1.4:
				e["stuck"] = 0.0
				e["rev"] = 1.4
				e["rs"] = -signf(diff) if absf(diff) > 0.08 else (1.0 if randf() < 0.5 else -1.0)
				e["tries"] = int(e.get("tries", 0)) + 1
				if e["tries"] >= 4 and far <= 55.0:    # still stuck with someone watching: give up on this street
					_turn_round(e)
		else:
			e["stuck"] = maxf(0.0, float(e.get("stuck", 0.0)) - dt)
			if speed > 4.0:
				e["tries"] = 0
