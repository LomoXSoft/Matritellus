extends Node
## Heat and Los Pitufos (the local police).
## Misbehaving fills the heat meter. When it is full, two patrol cars come looking for you: they drive to where you
## were last seen, and the moment one has you in sight it rams you. The meter only drains while NONE of them can
## see you; when it reaches zero they give up and everything goes back to normal.
## Crawl along or stand still for 5 seconds with one of them on top of you and you are caught.
##
## They are the best drivers in town. Every tick each patrol car looks down a fan of headings and takes the clearest
## one that still leads where it wants to go, so it threads between parked cars, trailers, trees, traffic and people
## instead of ploughing into them; it brakes for what it cannot get round and for the bends of its route, and backs
## out the moment it is boxed in.

const CarS = preload("res://scripts/car.gd")
const BUST_SECONDS := 5.0
const SIGHT := 95.0          # how far a patrol car can see along a clear street
const DRAIN := 7.0           # heat lost per second while out of sight
const HEAD_START := 3.0      # seconds between the chase being called and the patrol cars turning up
const TRICORNIOS_AFTER := 100.0      # seconds in their sights without a break before Los Tricornios are sent for

var game
var heat := 0.0              # 0..100
var chasing := false
var elite := false           # Los Tricornios have been called: more cars, faster, sharper
var _due := 0.0              # patrol cars are on their way: seconds until they appear
var _streak := 0.0           # how long they have had you in sight without losing you for a moment
var muted := false           # nothing you do raises the heat (the Thursday ham run: they are all at lunch)
var seen := false            # is any patrol car looking at you right now?
var cops: Array = []         # {car, path, repath, stuck, reverse, last_seen, sees}
var bust_t := 0.0
var _calm := 0.0             # seconds since the last offence
var _siren := 0.0
var _blink := 0.0
var boost := 1.0             # every patrol car's top speed, times this (out of town for a while: limite.gd)

func setup(game_) -> void:
	game = game_

func add_heat(amount: float) -> void:
	if muted or game.get("dev_no_heat"):         # (developer mode: no police)
		return
	amount *= game.heat_scale()                  # (half, with a mission under way)
	heat = minf(100.0, heat + amount)
	_calm = 0.0
	if heat >= 100.0 and not chasing:
		_start_chase()

func reset() -> void:
	heat = 0.0
	chasing = false
	seen = false
	bust_t = 0.0
	elite = false
	_due = 0.0
	_streak = 0.0
	boost = 1.0
	for e in cops:
		e["car"].queue_free()
	cops.clear()

func _spawn(pp: Vector2, kind := "pitufo", ace := false) -> void:
	var spot = MapData.random_node_near(pp, 80.0, 150.0)
	if spot == null:
		spot = MapData.random_node_near(pp, 30.0, 450.0)      # (out in the fields the roads are few and far between)
	if spot == null:
		return
	var c = CarS.new()
	game.add_child(c)
	var to: Vector2 = pp - spot
	var route := MapData.path(spot, pp)          # set off along the street, not nose-first into a wall
	for q in route:
		if q.distance_to(spot) > 6.0:
			to = q - spot
			break
	c.setup(kind, 0x2456b8, spot, atan2(to.x, to.y))
	c.seat(game.officer_look(kind))
	cops.append({"car": c, "path": PackedVector2Array(), "repath": randf() * 0.5, "stuck": 0.0, "reverse": 0.0, "last_seen": pp, "sees": false, "best": 1e9, "idle": 0.0, "ace": ace, "n": cops.size()})

## A patrol car on its beat has caught you at it (the turbo): that very car gives chase, and calls a mate.
func spotted(c, pp: Vector2) -> void:
	cops.append({"car": c, "path": PackedVector2Array(), "repath": 0.0, "stuck": 0.0, "reverse": 0.0, "last_seen": pp, "sees": true, "best": 1e9, "idle": 0.0})
	if chasing:
		return
	heat = 100.0
	_calm = 0.0
	chasing = true
	bust_t = 0.0
	_streak = 0.0
	_due = HEAD_START
	game.hud.toast(Loc.t("t_turbo_seen"), 4.0)
	Sfx.jingle([880, 660, 880, 660], 0.18)

## The chase is on. You get a few seconds' start before the patrol cars actually turn up.
func _start_chase() -> void:
	chasing = true
	bust_t = 0.0
	_streak = 0.0
	_due = HEAD_START
	game.hud.toast(Loc.t("t_chase"), 3.5)
	Sfx.jingle([880, 660, 880, 660], 0.18)

## Out of the town past the warning (limite.gd): everybody at once, with no head start. The heat full, two patrol cars
## of Los Pitufos and the Tricornios' three.
func all_out(pp: Vector2) -> void:
	heat = 100.0
	_calm = 0.0
	if not chasing:
		chasing = true
		bust_t = 0.0
		_streak = 0.0
	arrive()
	if not elite:
		_call_tricornios(pp)

## one more car after you: the Tricornios' and the Pitufos' in turn
func one_more(pp: Vector2) -> void:
	var kind := "tricornio" if cops.size() % 2 == 0 else "pitufo"
	_spawn(pp, kind, kind == "tricornio")

## the patrol cars turn up (until there are two of them)
func arrive() -> void:
	_due = 0.0
	while cops.size() < 2:
		_spawn(game.player.p)

## More than a hundred seconds without shaking them off: the Guardia Civil is sent for.
func _call_tricornios(pp: Vector2) -> void:
	elite = true
	for i in range(3):
		_spawn(pp, "tricornio", true)
	game.hud.toast(Loc.t("t_tricornios"), 5.0)
	Sfx.jingle([392, 392, 523, 392, 523, 659], 0.16)

func _end_chase() -> void:
	reset()
	game.hud.toast(Loc.t("t_lost"), 3.0)

func nearest_cop_dist(pp: Vector2) -> float:
	var best := 1e9
	for e in cops:
		best = minf(best, (e["car"].p as Vector2).distance_to(pp))
	return best

func _can_see(c, pp: Vector2, reach := SIGHT) -> bool:
	var cp: Vector2 = c.p
	if cp.distance_to(pp) > reach:
		return false
	var ray := PhysicsRayQueryParameters3D.create(MapData.at(cp, 1.3), MapData.at(pp, 1.3), 1)   # buildings block the view
	return game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

## called every physics tick while playing. frozen = dialogue/overlay on screen.
func tick(dt: float, pp: Vector2, pvel: Vector2, in_car, frozen: bool, on_the_gas: bool) -> void:
	_calm += dt
	if not chasing:
		if _calm > 6.0:
			heat = maxf(0.0, heat - 3.0 * dt)
		return
	_blink += dt
	if not frozen:
		if _due > 0.0:
			_due -= dt
			if _due <= 0.0:
				arrive()
		elif cops.size() < 2:                    # somebody has made off with a patrol car: send another
			_due = HEAD_START
			game.hud.toast(Loc.t("t_reinforce"), 3.0)
	seen = false
	for e in cops:
		var c = e["car"]
		c.speed_boost = boost
		for i in range(c.lights.size()):
			c.lights[i].visible = (int(_blink * 6.0) + i) % 2 == 0
		if frozen:
			c.drive(0.0, 0.0, true, true, dt)
			continue
		var cp: Vector2 = c.p
		var d := cp.distance_to(pp)
		var ace: bool = e.get("ace", false)          # Los Tricornios: they see further, think further ahead and work together
		e["sees"] = _can_see(c, pp, 135.0 if ace else SIGHT)
		var aim: Vector2
		if e["sees"]:
			seen = true
			e["last_seen"] = pp
			if ace and d < 60.0:
				# one comes straight at you; the others go for where you will be, to cut you off
				var lead := clampf(d / 22.0, 0.2, 1.1) * (1.0 if int(e.get("n", 0)) % 2 == 0 else 1.7)
				aim = pp + pvel * lead
			elif d < 32.0:
				aim = pp + pvel * clampf(d / 30.0, 0.1, 0.6)        # ram: aim where you are about to be
			else:
				aim = _along_path(e, cp, pp, dt)
		else:
			# search: go to where you were last seen, then prowl the streets around there
			var goal: Vector2 = e["last_seen"]
			if cp.distance_to(goal) < 16.0:
				var next = MapData.random_node_near(cp, 50.0, 130.0)
				if next != null:
					e["last_seen"] = next
					goal = next
					e["repath"] = 0.0
			aim = _along_path(e, cp, goal, dt)
		# properly wedged for a long while (boxed in, stuck in a yard): get going again from a street close to
		# where the patrol car already is. It never jumps towards the player: they still have to find you.
		if c.vel.length() > 1.0:
			e["idle"] = 0.0
		else:
			e["idle"] += dt
			if e["idle"] > 10.0:
				e["idle"] = 0.0
				var fresh = MapData.random_node_near(cp, 15.0, 60.0)
				if fresh != null:
					c.place(fresh, c.h)
					e["repath"] = 0.0
					continue
		var want := atan2(aim.x - cp.x, aim.y - cp.y)
		var diff := angle_difference(c.h, want)
		var speed: float = c.forward_speed()
		# --- eyes on the road: fan out a set of headings and take the clearest one that still goes where we want ---
		var nose: float = c.spec["len"] / 2.0
		var half: float = c.spec["wid"] / 2.0
		var reach := clampf(9.0 + maxf(0.0, speed) * 1.25, 11.0, 46.0)
		var look := _look(c, cp, want, reach, nose, half, in_car, float(e.get("off", 0.0)), ace)
		var off: float = look[0]
		var clear: float = look[1]
		e["off"] = off
		var steer := clampf(off * 2.6, -1.0, 1.0)
		# --- how fast: flat out when the way is clear, but never faster than they can stop or take the corner ---
		var top: float = c.spec["max"] * boost * (1.0 if e["sees"] else (0.92 if ace else 0.8))             # searching is slower than chasing
		var v := top
		if clear < reach - 0.5:
			v = minf(v, sqrt(2.0 * 9.5 * maxf(0.0, clear - nose - 1.4)))
		v = minf(v, lerpf(top, 8.0, clampf((absf(diff) - 0.15) / 0.9, 0.0, 1.0)))          # turning: slow in, fast out
		v = minf(v, _corner_speed(e, cp, top))
		v = maxf(v, 3.5)
		var thr := clampf((v - speed) * 0.55, -1.0, 1.0)
		if thr < 0.0 and speed < v + 2.5:
			thr = 0.0                                                # lift off rather than stamp on the brake for a trifle
		# the way on is behind us: back round in a three-point turn instead of grinding into the wall
		if absf(diff) > 1.9 and d > 14.0 and speed < 4.0 and e["reverse"] <= 0.0:
			e["reverse"] = 0.9
			e["rs"] = -signf(diff)
		# boxed in or nose against something: back out at once, wheels turned the other way
		if e["reverse"] > 0.0:
			e["reverse"] -= dt
			thr = -1.0
			steer = float(e.get("rs", -signf(off)))
		elif (c.vel.length() < 1.0 and d > 5.0) or (clear < nose + 0.9 and speed < 2.0 and d > 6.0):
			e["stuck"] += dt
			if e["stuck"] > (0.28 if ace else 0.45):
				e["stuck"] = 0.0
				e["reverse"] = 0.8
				e["rs"] = -signf(off) if absf(off) > 0.05 else (1.0 if randf() < 0.5 else -1.0)
		else:
			e["stuck"] = 0.0
		c.drive(thr, steer, false, true, dt)
		c.last_impact = 0.0
		game.props.sweep(c)                                          # they flatten street furniture too
	if frozen:
		return
	# never out of their sight for a hundred seconds: Los Tricornios
	_streak = _streak + dt if seen else 0.0
	if _streak >= TRICORNIOS_AFTER and not elite:
		_call_tricornios(pp)
	# the meter holds while they can see you and drains only once you are out of everyone's sight
	if not seen and _due <= 0.0:
		heat -= DRAIN * dt
		if heat <= 0.0:
			_end_chase()
			return
	# siren
	var near := nearest_cop_dist(pp)
	_siren -= dt
	if _siren <= 0.0 and near < 110.0:
		_siren = 0.36
		Sfx.beep(740.0 if int(_blink / 0.36) % 2 == 0 else 560.0, 0.3, 1, -16.0 - near * 0.12)
	# caught: one of them is on top of you and you are not getting away under your own power
	# (being shunted along with your foot off the pedal does not count as escaping)
	if near < 16.0 and (in_car == null or pvel.length() < 7.0 or not on_the_gas):
		bust_t += dt
		if bust_t >= BUST_SECONDS:
			game.busted()
	else:
		bust_t = maxf(0.0, bust_t - dt * 0.5)

func _along_path(e: Dictionary, from: Vector2, to: Vector2, dt: float) -> Vector2:
	e["repath"] -= dt
	if e["repath"] <= 0.0:
		e["repath"] = 0.5
		e["path"] = MapData.path(from, to)
	var ahead := clampf(8.0 + (e["car"].vel as Vector2).length() * 0.5, 9.0, 20.0)       # look further the faster they go
	var aim := to
	for q in e["path"]:
		aim = q
		if q.distance_to(from) > ahead:
			break
	return aim

## The fastest they should be going now so as to make the next sharp bend of their route.
func _corner_speed(e: Dictionary, from: Vector2, top: float) -> float:
	var path: PackedVector2Array = e["path"]
	if path.size() < 2:
		return top
	var prev := from
	var run := 0.0
	var heading := Vector2.ZERO
	for q in path:
		var leg := q - prev
		var length := leg.length()
		if length < 0.5:
			continue
		var dir := leg / length
		if heading != Vector2.ZERO:
			var bend := absf(heading.angle_to(dir))
			if bend > 0.55:                                  # a real corner, run metres ahead
				var through := lerpf(13.0, 7.0, clampf((bend - 0.55) / 1.0, 0.0, 1.0))
				return minf(top, sqrt(through * through + 2.0 * 8.0 * maxf(0.0, run - 4.0)))
		heading = dir
		run += length
		prev = q
		if run > 70.0:
			break
	return top

## Looks down a fan of headings either side of where the car is pointing and scores each: how far it is from where we
## want to go, and how soon something is in the way (walls, trees, trailers, parked and moving cars, people).
## Returns [the heading to take, relative to the car's own; how many metres are clear along it].
const FAN := [0.0, -0.12, 0.12, -0.26, 0.26, -0.44, 0.44, -0.68, 0.68, -0.98, 0.98]
const FAN_ACE := [0.0, -0.08, 0.08, -0.17, 0.17, -0.28, 0.28, -0.42, 0.42, -0.6, 0.6, -0.82, 0.82, -1.08, 1.08]

func _look(c, cp: Vector2, want: float, reach: float, nose: float, half: float, in_car, last: float, ace := false) -> Array:
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	var skip: Array[RID] = [c.get_rid()]
	if in_car != null:
		skip.append(in_car.get_rid())                # the one we are after is not something to steer round
	var people: Array = []                           # neighbours near enough to matter
	for n in (game.npcs if not chasing else []):     # (after you, they steer round nobody: whoever is in the way goes flying, game.gd _duty_hits)
		if n.visible and not n.away and n.state != "fly" and n.state != "down":
			var rel: Vector2 = n.p - cp
			if rel.length_squared() < (reach + 2.0) * (reach + 2.0):
				people.append(rel)
	var best_off := 0.0
	var best_cost := 1e9
	var best_clear := 0.0
	for off: float in (FAN_ACE if ace else FAN):
		var h: float = c.h + off
		var dir := Vector2(sin(h), cos(h))
		var side := Vector2(-dir.y, dir.x)
		var clear := reach
		for edge in [-1.0, 1.0]:                     # one ray down each flank: the width of the car has to fit
			var from: Vector2 = cp + side * edge * (half + 0.12)
			var q := PhysicsRayQueryParameters3D.create(MapData.at(from, 0.75), MapData.at(from + dir * reach, 0.75), 1 | 2 | 8)
			q.exclude = skip
			var hit := space.intersect_ray(q)
			if not hit.is_empty():
				clear = minf(clear, Vector2(hit["position"].x - from.x, hit["position"].z - from.y).length())
		for rel: Vector2 in people:
			var along := rel.dot(dir)
			if along > 0.0 and along < clear and absf(rel.dot(side)) < half + 0.75:
				clear = along - 0.4
		var blocked := 1.0 - clear / reach
		var cost := absf(angle_difference(h, want)) * 1.0 + blocked * blocked * 4.5 + absf(off - last) * 0.12
		if clear < nose + 1.2:
			cost += 6.0                              # there is no going that way at all
		if cost < best_cost:
			best_cost = cost
			best_off = off
			best_clear = clear
	return [best_off, best_clear]
