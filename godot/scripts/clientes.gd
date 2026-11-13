extends RefCounted
## Kebab Luis's customers (the user's rules, 13 November 2026; guion/kebab_luis_diseno.md).
##
## One table a day has its regulars (kebab.gd, seat_day). Of the other neighbours, whoever comes near the kebab has a
## 33 % chance of stopping. ("Near" was first only the stretch of street in front of the gate; the user found the place
## too empty and asked for the net to be cast wider: it is now anybody out walking within NEAR metres, who then comes
## along the pavements to the gate.) They come in, queue in front of Don Luis, ask him for something, carry it to a free table
## -- never the regulars' -- and sit down to it. Eating takes 30 to 45 seconds; 15 to 30 seconds after that they get
## up, walk back out to the street and go on with their walk.
##
## While they are at it their state is "kebab" (game.gd leaves them alone) and they are moved from here; while they
## sit, the neighbour is put away and a sitting figure with their looks is on the chair instead.

const EAT := Vector2(30.0, 45.0)        # seconds eating
const LINGER := Vector2(15.0, 30.0)     # seconds at the table after that
const NEAR := 70.0                      # "coming near the kebab": within this many metres of its gate...
const GONE := 85.0                      # ...and not asked again until they have been this far away,
const AGAIN := 60.0                     # or have been hanging about the place for this many seconds more
const ALONG := 22.0                     # in front of the gate: this far either side of it, along the street...
const ACROSS := Vector2(-0.5, 13.0)     # ...and from the plot's own kerb to the far pavement
const ORDER_FOR := 4.6                  # seconds at the bar: asking, and being answered
const FOODS := ["comida_sub", "comida_taco", "comida_fries"]
# the plot's own frame (kebab.gd): x along the front, z out towards the street
const GATE_OUT := Vector2(11.0, 1.3)
const GATE_IN := Vector2(11.0, -2.2)
const YARD := Vector2(9.5, -7.5)
const DOOR_OUT := Vector2(8.0, -10.4)
const DOOR_IN := Vector2(8.0, -12.2)
const HUB := Vector2(9.3, -12.9)        # just inside the door, clear of the table by it
const QUEUE := [Vector2(11.3, -14.2), Vector2(11.0, -13.3), Vector2(10.2, -12.6), Vector2(8.0, -10.5), Vector2(8.0, -9.5), Vector2(8.6, -8.6)]
const INDOORS := 3                      # the queue's places from this one on are out of doors

var G                               # the game
var K                               # the kebab house
var odds := 0.33
var list: Array = []                # {n, stage, path, slot, table, seat, t, told, figure, setting, food, bag, stuck}
var queue: Array = []               # those of them waiting their turn, first come first
var passed := 0                     # how many neighbours have walked past
var stopped := 0                    # ...how many of them came in
var served := 0
var gone := 0                       # how many have eaten, left and gone on their way
var _scan_t := 0.0

func setup(game, kebab) -> void:
	G = game
	K = kebab

func _roll() -> bool:
	return randf() < odds

## the seats nobody has: every chair of every table but the regulars', less the ones taken or spoken for
func free_seats() -> Array:
	var taken := {}
	for c in list:
		taken[Vector2i(c["table"], c["seat"])] = true
	var out: Array = []
	for ti in range(K.tables.size()):
		if ti == K.busy:
			continue
		for si in range((K.tables[ti]["seats"] as Array).size()):
			if not taken.has(Vector2i(ti, si)):
				out.append(Vector2i(ti, si))
	return out

func is_client(n) -> bool:
	for c in list:
		if c["n"] == n:
			return true
	return false

## a neighbour out walking is in front of the gate: do they fancy one?
func _scan() -> void:
	var gate: Vector2 = K.spot(GATE_OUT.x, GATE_OUT.y)
	for n in G.npcs:
		if n.id != "" or not n.walker or n.still or n.away or n.state != "idle" or n.voice == "goat":
			continue
		var d: float = n.p.distance_to(gate)
		if d > NEAR:
			if d > GONE and n.has_meta("kebab_seen"):
				n.remove_meta("kebab_seen")
			continue
		if n.has_meta("kebab_seen") and G.time - float(n.get_meta("kebab_seen")) < AGAIN:
			continue
		n.set_meta("kebab_seen", G.time)           # (one throw of the dice each time they come by)
		passed += 1
		if _roll():
			come_in(n)

## this neighbour stops and comes in (false if there is no chair for them, or the queue is out of the gate)
func come_in(n) -> bool:
	var seats := free_seats()
	if seats.is_empty() or queue.size() >= QUEUE.size() or is_client(n):
		return false
	var seat: Vector2i = seats.pick_random()
	var c := {"n": n, "stage": "come", "path": _way_in(n) + [GATE_OUT, GATE_IN, YARD], "slot": -1, "table": seat.x, "seat": seat.y, "t": 0.0, "told": false,
		"figure": null, "setting": null, "food": null, "bag": null, "stuck": 0.0, "what": FOODS.pick_random()}
	n.state = "kebab"
	n.set_meta("kebab_seen", G.time)
	list.append(c)
	queue.append(c)
	stopped += 1
	return true

# ---------------- ways about the place ----------------
func _in_front(at: Vector2) -> bool:
	return absf(at.x - GATE_OUT.x) < ALONG and at.y > ACROSS.x and at.y < ACROSS.y

## From wherever they are in the streets round about to the street in front of the gate: junction to junction along
## the pavement they were on, as they walk anywhere else (game.gd, _walker_plan). In the plot's frame, as every path here.
func _way_in(n) -> Array:
	var out: Array = []
	if _in_front(K.local(n.p)):
		return out
	var nodes: Array = G.traffic.route_nodes(n.p, K.spot(GATE_OUT.x, GATE_OUT.y + 3.0))
	for i in range(nodes.size() - 1):
		var from: Vector2 = MapData.nodes[nodes[i]]
		var to: Vector2 = MapData.nodes[nodes[i + 1]]
		var s = MapData.seg_between(nodes[i], nodes[i + 1])
		var d := to - from
		var length := maxf(d.length(), 0.01)
		var u := d / length
		var room: float = minf(float(MapData.clr[nodes[i]]), float(MapData.clr[nodes[i + 1]]))
		var off: float = clampf(MapData.fitted_hw(s) + 0.9, 0.9, maxf(0.9, room - 0.55)) * n.wside
		var inset := minf(4.6, length * 0.3)
		var perp := Vector2(-u.y, u.x)
		for q in [from + u * inset + perp * off, to - u * inset + perp * off]:
			if i > 0 or (q - n.p).dot(u) > 0.0:      # (not back to a corner they have already passed)
				out.append(K.local(q))
	return out
func _indoor_table(ti: int) -> bool:
	var tp: Vector2 = K.table_at(ti)
	return tp.x > K.X0 and tp.x < K.X1 and tp.y < K.FRONT and tp.y > K.BACK

## from a to b without walking through a table: where the straight line would cross one, a point to go round it by
func _leg(a: Vector2, b: Vector2, indoors: bool) -> Array:
	var out: Array = []
	for ti in range(K.tables.size()):
		var tp: Vector2 = K.table_at(ti)
		var ab := b - a
		if ab.length() < 0.1:
			continue
		var f := (tp - a).dot(ab) / ab.length_squared()
		var q := a + ab * clampf(f, 0.0, 1.0)
		var d := q.distance_to(tp)
		var r := 1.25 if indoors else 1.6
		if d >= r or f <= 0.001 or f >= 0.999:       # (clear of it; or it only comes near at one end: the chair itself)
			continue
		var side := (q - tp) / d if d > 0.05 else Vector2(-ab.y, ab.x).normalized()
		var by := tp + side * (r + 0.3)
		if indoors:
			by = Vector2(clampf(by.x, K.X0 + 0.8, 9.2), clampf(by.y, K.BACK + 0.8, K.FRONT - 0.8))
		else:
			by = Vector2(clampf(by.x, 0.8, K.WIDE - 0.8), clampf(by.y, -K.DEEP + 0.8, -0.8))
		out.append([(q - a).length(), by])
	out.sort_custom(func(m, n): return m[0] < n[0])
	return out.map(func(e): return e[1]) + [b]

func _chain(pts: Array, indoors: bool) -> Array:
	var out: Array = [pts[0]]
	for i in range(1, pts.size()):
		out.append_array(_leg(pts[i - 1], pts[i], indoors))
	return out

## from the door (out of doors) or from just inside it (indoors) to the chair
func _to_table(ti: int, si: int) -> Array:
	var tp: Vector2 = K.table_at(ti)
	var seat: Vector2 = K.seat_at(ti, si)
	if _indoor_table(ti):
		var pts: Array = [HUB]
		if tp.y < -15.5:
			pts.append(Vector2(8.9, -15.6))          # (round the end of the bar)
		pts.append(seat)
		return _chain(pts, true)
	var way: Array = [DOOR_OUT]
	if tp.y > -8.0:                                  # across the front of the house
		pass
	elif tp.x < K.X0:                                # down its left side
		way.append_array([Vector2(5.0, -10.0), Vector2(5.0, tp.y)])
	else:                                            # ...or its right
		way.append_array([Vector2(9.5, -9.4), Vector2(17.0, -9.4), Vector2(17.0, tp.y)])
	way.append(seat)
	return _chain(way, false)

func _way_to_seat(c: Dictionary) -> Array:
	var way := _to_table(c["table"], c["seat"])
	if _indoor_table(c["table"]):
		return way
	return [HUB, DOOR_IN] + way

func _way_out(c: Dictionary) -> Array:
	var way := _to_table(c["table"], c["seat"])
	way.reverse()
	way = way.slice(1)
	if _indoor_table(c["table"]):
		way.append_array([DOOR_IN, DOOR_OUT])
	if K.table_at(c["table"]).y > -8.0:              # from a table at the front: straight to the gate, not back by the door
		return _chain([K.seat_at(c["table"], c["seat"]), GATE_IN], false).slice(1) + [GATE_OUT]
	return way + [YARD, GATE_IN, GATE_OUT]

## the way to a place in the queue from wherever they are
func _way_to_slot(c: Dictionary, slot: int) -> Array:
	var at: Vector2 = K.local(c["n"].p)
	var inside: bool = at.y < K.FRONT
	if slot < INDOORS and not inside:
		return [DOOR_OUT, DOOR_IN, QUEUE[slot]]
	return [QUEUE[slot]]

# ---------------- every tick ----------------
## walks them along their path; true once there is none of it left
func _walk(c: Dictionary, dt: float, near: bool) -> bool:
	var n = c["n"]
	var path: Array = c["path"]
	if path.is_empty():
		return true
	if c["stage"] == "come" and path.size() > 3 and _in_front(K.local(n.p)):      # in sight of the gate: straight to it
		while path.size() > 3:
			path.pop_front()
	var goal: Vector2 = K.spot(path[0].x, path[0].y)
	var to: Vector2 = goal - n.p
	if to.length() < 0.4:
		path.pop_front()
		c["stuck"] = 0.0
		return path.is_empty()
	var dir := to.normalized()
	var was: Vector2 = n.p
	var speed: float = maxf(n.wspeed, 1.25)
	if near:
		n.walk(dir, speed)
		n.anim(true, dt, 0.0)
	else:
		n.p = n.p + dir * minf(speed * dt, to.length())
	n.h = lerp_angle(n.h, atan2(dir.x, dir.y), 1.0 - exp(-8.0 * dt))
	c["stuck"] = float(c["stuck"]) + dt if n.p.distance_to(was) < speed * dt * 0.3 else 0.0
	if float(c["stuck"]) > 2.5:                      # up against something that should not be there: past it
		c["stuck"] = 0.0
		n.p = goal
		n.reset_physics_interpolation()
	return false

func _stand(c: Dictionary, dt: float, facing: Vector2, near: bool) -> void:
	var n = c["n"]
	var to: Vector2 = facing - n.p
	n.h = lerp_angle(n.h, atan2(to.x, to.y), 1.0 - exp(-6.0 * dt))
	if near:
		n.anim(false, dt, 0.0)

## no longer a customer: whatever they had on the table goes, and so does their place
func _drop(c: Dictionary) -> void:
	for key in ["figure", "setting", "bag"]:
		if c[key] != null and is_instance_valid(c[key]):
			c[key].queue_free()
		c[key] = null
	list.erase(c)
	queue.erase(c)

## back to being a neighbour out for a walk, from wherever they are
func _release(c: Dictionary) -> void:
	var n = c["n"]
	_drop(c)
	n.away = false
	n.visible = true
	n.state = "idle"
	n.t = 1.0
	n.home = n.p
	n.wpts = []
	n.wa = -1
	n.wb = -1
	n.wstuck = 0.0
	n.set_meta("kebab_seen", G.time)

func _get_up(c: Dictionary) -> void:
	var n = c["n"]
	for key in ["figure", "setting"]:
		if c[key] != null and is_instance_valid(c[key]):
			c[key].queue_free()
		c[key] = null
	c["food"] = null
	var seat: Vector2 = K.seat_at(c["table"], c["seat"])
	n.away = false
	n.visible = true
	n.p = K.spot(seat.x, seat.y)
	n.reset_physics_interpolation()
	c["stage"] = "leave"
	c["path"] = _way_out(c)

func tick(dt: float, pp: Vector2) -> void:
	_scan_t -= dt
	if _scan_t <= 0.0:
		_scan_t = 0.4
		_scan()
	if list.is_empty():
		return
	var far: float = pp.distance_to(K.door)
	var near: bool = far < 60.0
	var luis = G.named.get("luis")
	for c in list.duplicate():
		var n = c["n"]
		if not is_instance_valid(n):
			_drop(c)
			continue
		var sitting: bool = c["stage"] == "eat" or c["stage"] == "after"
		if not sitting and n.state != "kebab":       # sent flying by a car, or anything else that took them out of it
			_drop(c)
			continue
		if c["table"] == K.busy and c["stage"] != "leave":       # the day has turned and today's regulars have this table
			if sitting:
				_get_up(c)
			else:
				var seats := free_seats()
				if seats.is_empty():
					c["stage"] = "leave"
					c["path"] = [DOOR_IN, DOOR_OUT, YARD, GATE_IN, GATE_OUT] if K.local(n.p).y < K.FRONT else [GATE_IN, GATE_OUT]
					queue.erase(c)
				else:
					var seat: Vector2i = seats.pick_random()
					c["table"] = seat.x
					c["seat"] = seat.y
					if c["stage"] == "go":
						c["path"] = ([DOOR_IN, DOOR_OUT] if K.local(n.p).y < K.FRONT else []) + _to_table(seat.x, seat.y)
		if G.dlg != null and G.dlg.get("from") == n:      # you are talking to them: they wait
			if near:
				n.anim(false, dt, 0.0)
			continue
		match c["stage"]:
			"come":
				if _walk(c, dt, near):
					c["stage"] = "queue"
					c["slot"] = -1
			"queue":
				var slot: int = queue.find(c)
				if slot != c["slot"]:
					c["slot"] = slot
					c["path"] = _way_to_slot(c, slot)
				if _walk(c, dt, near):
					_stand(c, dt, K.keeper, near)
					if slot == 0:
						c["stage"] = "order"
						c["t"] = ORDER_FOR
						c["told"] = false
						if far < 40.0:
							n.bark(Loc.speaker(Loc.t("kebab_pide").pick_random(), n.voice.ends_with("_f")), 2.4)
			"order":
				c["t"] -= dt
				_stand(c, dt, K.keeper, near)
				if not c["told"] and c["t"] < ORDER_FOR - 2.3:
					c["told"] = true
					if luis != null and far < 40.0 and G.dlg == null:
						luis.bark(Loc.t("kebab_sirve").pick_random(), 2.6)
				if c["t"] <= 0.0:                    # served: off to the table with it
					queue.erase(c)
					served += 1
					c["bag"] = K.takeaway(c["what"], n.vis)
					c["stage"] = "go"
					c["path"] = _way_to_seat(c)
			"go":
				if _walk(c, dt, near):
					if c["bag"] != null:
						c["bag"].queue_free()
						c["bag"] = null
					n.away = true
					n.visible = false
					c["figure"] = K.seat_guest(c["table"], c["seat"], n.look_data)
					var laid: Array = K.serve(c["table"], c["seat"], c["what"])
					c["setting"] = laid[0]
					c["food"] = laid[1]
					c["stage"] = "eat"
					c["t"] = randf_range(EAT.x, EAT.y)
			"eat":
				c["t"] -= dt
				if c["t"] <= 0.0:                    # finished: the plate is empty, and they sit on a while
					if c["food"] != null and is_instance_valid(c["food"]):
						c["food"].queue_free()
					c["food"] = null
					c["stage"] = "after"
					c["t"] = randf_range(LINGER.x, LINGER.y)
			"after":
				c["t"] -= dt
				if c["t"] <= 0.0:
					_get_up(c)
			"leave":
				if _walk(c, dt, near):
					gone += 1
					_release(c)
