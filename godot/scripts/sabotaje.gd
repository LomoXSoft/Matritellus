extends Node
## Don Luis's side mission (the user's design, 13 November 2026; guion/kebab_luis_diseno.md). His is the fourth kebab
## house to open in a town that is not that big, so he asks you to spoil the food of the other three: "no es ético,
## pero en el amor y en kebab todo vale".
##
##   1  You take it and he tells you the delivery lorry has just left his place (a scene: the delivery man comes out
##      of the kebab, gets into the lorry and drives off) for the other three.
##   2  You follow it: not too close, he would see you; not too far, you would lose it.
##   3  At each kebab he gets out, carries two boxes to the door and leaves them there. From then you have 30 seconds,
##      until the lorry sets off again, to get to the boxes and spoil them -- but only once he has turned his back and
##      is on his way to the lorry: a bogey, a piss and a shit, in that order of restaurants.
##   4  The moment you have done it: a scene of the lorry setting off, and a word to get into a car, quick.
##   5  Now and then he says something in "Arabic", which is never Arabic.
##   6  Caught, lost, or too close: the screen says so, Don Luis rings and tells you to come back to the restaurant and
##      try again; the mission starts over with fewer words.
##   7  The third one spoilt: back to Don Luis for your money and a kebab. He goes into the Agenda and his kebab is
##      yours whenever you like.
##   8  Talk to him a day or more later and he tells you it was all for nothing.
##
## The lorry and the delivery man are stand-ins (a black Z15 and a man made of the usual parts): their own models are
## still to be made.

const Parts = preload("res://scripts/parts.gd")
const TITLE := "luis_title"
const STOPS := [["castilla_17", "moco", "Kebab Deluxe"], ["stana_44", "meo", "Tele Durum"], ["castilla_4", "cago", "ShawarMadridejos"]]
const LORRY := "z15"
const LORRY_PAINT := 0x1f1f24
const MAN := {"shirt": 0x2a9d8f, "hair": 0x111111, "face": 2, "brows": 1, "hat": "cap", "hat_color": 0xc0392b, "top": 4, "skin": 0xc98e5f}
const PAY := 30                 # euros (a provisional figure)
const CLOSE := 13.0             # nearer the lorry than this while it is on its way and he sees you in the mirror...
const SEEN_FOR := 2.0           # ...after this many seconds of it
const FAR := 100.0              # further than this...
const LOST_FOR := 6.0           # ...for this long, and it is gone
const BLIND_FOR := 12.0         # as it is if you have not had it in sight for this long
const NEAR_ENOUGH := 45.0       # ...but never while you are this close to it, seen or not
const WINDOW := 30.0            # seconds from the boxes being set down to the lorry setting off
const EYES := 16.0              # how far he sees when he is out of the lorry, in front of him...
const EYES_ANGLE := 0.96        # ...this many radians either side of where he is facing
const ACT_FOR := 2.6            # seconds the deed takes
const PACE := 1.0               # the lorry goes at the pace of the rest of the traffic

var G
var K
var stage := ""                 # "" | cine_out | follow | unload | window | act | cine_go | back | failed | retry
var stop_i := 0
var lorry = null                # its entry in traffic.gd
var man = null                  # the delivery man, while he is out of it
var boxes: Node3D               # the two boxes, in his arms or on the pavement
var cine := false               # a scene is playing: hands off
var declined := false           # you said no (the next time he only asks)
var t := 0.0
var seen := 0.0
var lost := 0.0
var blind := 0.0
var caught := 0.0
var armed := false              # you have been far enough from the lorry for "too close" to mean anything
var _warned := ""
var _sight_t := 0.0
var _in_sight := true
var _route_t := 0.0
var _target_t := 0.0
var _walk: Array = []           # where he is walking to: points on the map
var _then := ""                 # what he does when he gets there
var _pause := 0.0
var _left: Array = []           # what a mission left lying about (boxes, a man standing there): gone once you are far away
var _rang := false
var _done_here := false

func setup(game) -> void:
	G = game
	K = game.kebab

func done() -> bool:
	return G.stats.has("luis_done")

func active() -> bool:
	return stage != ""

func _luis():
	return G.named["luis"]

## where the lorry stops and the boxes go at each of the three: {road, door, name, kind}
func stop(i: int) -> Dictionary:
	var hd: Dictionary = {}
	for h in MapData.houses:
		if h["id"] == STOPS[i][0]:
			hd = h
	if hd.is_empty():
		return {}
	var o := Vector2(hd["o"][0], hd["o"][1])
	var u := Vector2(hd["u"][0], hd["u"][1])
	var mid: Vector2 = o + u * float(hd["len"]) / 2.0
	var r: Dictionary = MapData.nearest_road(mid)
	var out: Vector2 = ((r["p"] as Vector2) - mid).normalized()
	return {"road": r["p"], "door": mid + out * 1.2, "out": out, "name": STOPS[i][2], "kind": STOPS[i][1]}

func _arabic() -> String:
	return Loc.t("arabe").pick_random()

# ---------------- talking to Don Luis ----------------
## You talk to Don Luis. True if this mission had something to say about it.
## (`ask`: you have asked him for the errand yourself, from his counter)
func talk(n, ask := false) -> bool:
	if stage == "back":
		_reward()
		return true
	if stage == "retry":
		G.say(n.shown_name(), Loc.t("luis_retry"), n.voice, func():
			G._offer(n, Loc.t(TITLE), begin.bind(false), false, "step", abort.bind(false)))
		return true
	if stage != "":
		G.say(n.shown_name(), Loc.t("luis_busy"), n.voice)
		return true
	if done():
		if not G.stats.has("luis_told") and int(G.day_n) > int(G.stats["luis_done"]):      # a day or more later: it was all for nothing
			G.stats["luis_told"] = true
			G.say(n.shown_name(), Loc.t("luis_after"), n.voice)
			return true
		return false
	if G.side != null or G.in_mission() or G.comida.faint != null:      # (first things first)
		return false
	if G.stats.has("luis_seen") and not ask:     # he has told you once: after that it is on his counter, with the kebabs
		return false
	var pitch = [Loc.t("offer_again").pick_random()] if declined else Loc.t("luis_mision")
	G.stats["luis_seen"] = true
	G.say(n.shown_name(), pitch, n.voice, func():
		G._offer(n, Loc.t(TITLE), begin.bind(true), false, "step", func(): declined = true))
	return true

## You go and talk to the delivery man himself. Whatever he answers, he has had a good look at you.
func spoken(n) -> void:
	G.say(Loc.t("n_repartidor"), _arabic(), n.voice, func():
		if n == man and stage in ["unload", "window"]:
			fail("caught"))

## taken (or taken up again after a failure, with fewer words)
func begin(first: bool) -> void:
	declined = false
	_clear()
	G.side = {"id": "luis", "who": "luis", "stage": "follow", "t": 0.0}
	stop_i = 0
	var n = _luis()
	if first:
		G.hud.show_card(Loc.t(TITLE), "")
	G.say(n.shown_name(), Loc.t("luis_go" if first else "luis_go_again"), n.voice, _cine_out)

func show() -> void:
	match stage:
		"follow", "cine_out", "cine_go":
			G.hud.set_objective(G._tag(), Loc.t("obj_luis_follow"))
		"unload":
			G.hud.set_objective(G._tag(), Loc.t("obj_luis_wait") % String(stop(stop_i)["name"]))
		"window", "act":
			G.hud.set_objective(G._tag(), Loc.t("obj_luis_sab"))
		"back":
			G.hud.set_objective(G._tag(), Loc.t("obj_luis_back"))
			G.set_target(K.door, true)
		"failed", "retry":
			G.hud.set_objective(G._tag(), Loc.t("obj_luis_retry"))
			G.set_target(K.door, true)

func _stage(to: String) -> void:
	stage = to
	t = 0.0
	show()

# ---------------- the lorry and its man ----------------
## the lorry, standing in the street at `at`, pointing the way it will have to go to reach `goal`
func _spawn_lorry(at: Vector2, goal: Vector2) -> void:
	var r: Dictionary = MapData.nearest_road(at)
	var s = r["seg"]
	var a: int = s.na
	var b: int = s.nb
	var route: Array = G.traffic.route_nodes(r["p"], goal)
	if route.size() >= 2 and route[0] == s.nb and route[1] == s.na:
		a = s.nb
		b = s.na
	elif route.size() >= 1 and route[0] == s.na and not (route.size() >= 2 and route[1] == s.nb):
		a = s.nb                                 # (the way on is through the near end: start with our back to the other)
		b = s.na
	var e: Dictionary = G.traffic.add(LORRY, LORRY_PAINT, a, b)
	var u: Vector2 = (MapData.nodes[b] - MapData.nodes[a]).normalized()
	e["car"].place((r["p"] as Vector2) + Vector2(-u.y, u.x) * clampf(MapData.fitted_hw(s) * 0.3, 0.6, 1.25), atan2(u.x, u.y))
	e["car"].seat({})
	e["halt"] = true
	e["auto"] = true                             # (ours: the traffic neither scraps it nor sends the tow truck for it)
	e["pace"] = PACE
	e["patient"] = true                          # (it does not turn round at the first car in its way: it has a round to do)
	e["mark"] = e["car"].p
	e["idle"] = 0.0
	lorry = e

func _spawn_man(at: Vector2) -> void:
	man = G._make_npc("repartidor", MAN.duplicate(), "adult_m", at)
	man.state = "busy"
	man.still = true
	man.sync()

func _board() -> void:
	if man != null and is_instance_valid(man):
		G.npcs.erase(man)
		G.named.erase("repartidor")
		man.queue_free()
	man = null
	if lorry != null:
		lorry["car"].seat(MAN.duplicate())

func _lorry_go(goal) -> void:
	lorry["halt"] = false
	lorry["mark"] = lorry["car"].p
	lorry["idle"] = 0.0
	lorry["wait"] = 0.0
	lorry["tries"] = 0
	lorry["route"] = G.traffic.route_nodes(MapData.nodes[lorry["b"]], goal).slice(1) if goal != null else []

## his way of walking: along `pts`, then `then`
func _man_to(pts: Array, then: String) -> void:
	_walk = pts
	_then = then

func _man_tick(dt: float) -> void:
	if man == null or _walk.is_empty():
		if man != null:
			man.anim(false, dt, 0.0)
		return
	var to: Vector2 = (_walk[0] as Vector2) - man.p
	if to.length() < 0.45:
		_walk.pop_front()
		if _walk.is_empty():
			_arrived(_then)
		return
	var dir := to.normalized()
	man.walk(dir, 1.5)
	man.h = lerp_angle(man.h, atan2(dir.x, dir.y), 1.0 - exp(-9.0 * dt))
	man.anim(true, dt, 0.0)
	man.sync()

func _door_side() -> Vector2:
	return G._free_side(lorry["car"])

func _make_boxes() -> Node3D:
	var b := Node3D.new()
	for k in range(2):
		b.add_child(Parts.part("box", 0xc9a26b, Vector3(0.0, 0.2 + k * 0.38, 0.0), Vector3(0.62, 0.36, 0.46)))
		b.add_child(Parts.part("box", 0xb5202a, Vector3(0.0, 0.2 + k * 0.38, 0.0), Vector3(0.64, 0.07, 0.48)))
	return b

# ---------------- the scenes ----------------
func _cine(on: bool, from = null, at = null) -> void:
	cine = on
	G.cine_lock = on
	G.hud.cine(on)
	G.cam_fixed = [from, at] if on else null

## he comes out of the kebab, gets into the lorry and drives off
func _cine_out() -> void:
	var first: Dictionary = stop(0)
	var at: Vector2 = K.spot(11.0, 4.5)
	for x in [11.0, -2.0, 24.0, -15.0, 37.0]:        # in front of the gate, or a little along the street if something is parked there
		var q: Vector2 = K.spot(x, 4.5)
		var free := true
		for car in G.cars + G.traffic.list.map(func(e): return e["car"]):
			if car.p.distance_to(q) < 7.0:
				free = false
		if free:
			at = q
			break
	_spawn_lorry(at, first["road"])
	_spawn_man(K.spot(11.0, -3.5))
	_stage("cine_out")
	var c = lorry["car"]
	var eye: Vector2 = K.spot(19.0, 9.5)
	_cine(true, MapData.at(eye, 3.2), MapData.at(c.p.lerp(K.spot(11.0, 0.0), 0.4), 1.2))
	_man_to([K.spot(11.0, 1.0), _door_side()], "board_out")

func _arrived(what: String) -> void:
	match what:
		"board_out":                             # at the lorry's door: a word, and in
			G.say(man.shown_name(), _arabic(), man.voice, func():
				_board()
				_lorry_go(stop(0)["road"])
				_pause = 3.0
				_then = "out_over")
		"boxes_down":                            # at the door of the shop: down they go
			boxes.get_parent().remove_child(boxes)
			G.add_child(boxes)
			var d: Dictionary = stop(stop_i)
			boxes.position = MapData.at(d["door"], 0.0)
			boxes.position.y = MapData.foot(d["door"])
			boxes.rotation.y = atan2(d["out"].x, d["out"].y)
			man.bark(_arabic(), 3.0)
			Sfx.noise(0.12, -14.0)
			_pause = 1.3
			_then = "turn_back"
		"board_back":                            # back in the cab, where he looks at nothing
			man.bark(_arabic(), 2.2)
			_pause = 0.8
			_then = "sit"

func _after_pause(what: String) -> void:
	match what:
		"out_over":
			_cine(false)
			armed = false
			_stage("follow")
			G.hud.toast(Loc.t("t_sab_follow"), 5.0)
			Sfx.jingle([392, 523, 659, 784])
		"turn_back":                             # his back to the boxes: the thirty seconds start
			_stage("window")
			t = WINDOW
			G.hud.set_bottles(0)
			G.hud.timer_slot.visible = true
			_man_to([_door_side()], "board_back")
		"sit":
			_board()
		"go_over":                               # the lorry is off again
			_cine(false)
			if stop_i >= STOPS.size() - 1:       # that was the last of them
				_release_lorry()
				_stage("back")
				G.hud.toast(Loc.t("t_sab_all"), 5.0)
				Sfx.jingle([523, 659, 784, 1047], 0.12)
			else:
				stop_i += 1
				_left.append(boxes)
				boxes = null
				armed = false
				seen = 0.0
				lost = 0.0
				blind = 0.0
				_stage("follow")
				G.hud.toast(Loc.t("t_sab_car"), 5.0)
		"ring":                                  # Don Luis has heard
			if G.dlg != null:                          # (talking to somebody: in a moment. An engaged line is the switchboard's: llamadas.gd)
				_pause = 2.0
				_then = "ring"
				return
			_rang = true
			G.llamadas.ring({"npc": "luis", "lines": "luis_fail_call", "side": true, "plain": true, "once": true, "after": _to_retry})

## at a kebab: out he gets, with the two boxes
func _unload() -> void:
	_stage("unload")
	var d: Dictionary = stop(stop_i)
	caught = 0.0
	_done_here = false
	lorry["car"].seat({})
	_spawn_man(_door_side())
	man.bark(_arabic(), 2.6)
	boxes = _make_boxes()
	boxes.position = Vector3(0.0, 0.55, 0.5)
	man.vis.add_child(boxes)
	_man_to([d["door"] + (d["out"] as Vector2) * 0.9], "boxes_down")
	G.hud.toast(Loc.t("t_sab_stop") % String(d["name"]), 4.0)

# ---------------- the deed ----------------
func can_act() -> bool:
	return stage == "window" and not _done_here and G.in_car == null and boxes != null and G.dlg == null \
		and G.player.p.distance_to(Vector2(boxes.global_position.x, boxes.global_position.z)) < 2.4

func prompt() -> String:
	return Loc.t("p_sab_" + String(STOPS[stop_i][1]))

func act() -> void:
	if not can_act():
		return
	var kind: String = STOPS[stop_i][1]
	var at := Vector2(boxes.global_position.x, boxes.global_position.z)
	var to: Vector2 = (at - G.player.p).normalized()
	G.player.h = atan2(to.x, to.y) + (PI if kind == "cago" else 0.0)       # (for that one you turn your back on them)
	G.player.sync()
	stage = "act"
	t = ACT_FOR
	G.cine_lock = true
	match kind:
		"moco":
			G.player.punch = 0.28
			Sfx.beep(180.0, 0.5, 3, -12.0, 300.0)
		"meo":
			for k in range(8):
				get_tree().create_timer(k * 0.28).timeout.connect(Sfx.noise.bind(0.22, -18.0))
		"cago":
			Sfx.beep(90.0, 0.7, 3, -9.0, -30.0)
			get_tree().create_timer(1.2).timeout.connect(Sfx.beep.bind(70.0, 0.5, 3, -9.0, -20.0))

func _acted() -> void:
	var kind: String = STOPS[stop_i][1]
	_done_here = true
	G.cine_lock = false
	G.player.y = 0.0
	G.player.sync()
	G.hud.timer_slot.visible = false
	var stain: int = {"moco": 0x8fbf3a, "meo": 0xe6d22e, "cago": 0x5a3a1c}[kind]
	if boxes != null:                            # what you left on them
		boxes.add_child(Parts.part("ball", stain, Vector3(0.05, 0.79, 0.02), Vector3(0.3, 0.07 if kind != "cago" else 0.2, 0.24)))
		if kind != "cago":
			boxes.add_child(Parts.part("ball", stain, Vector3(0.3, 0.3, 0.2), Vector3(0.1, 0.3, 0.06)))
	G.hud.toast(Loc.t("t_sab_" + kind), 4.0)
	Sfx.jingle([659, 880], 0.08)
	G.stats["luis_sab"] = int(G.stats.get("luis_sab", 0)) + 1
	_cine_go()

## the lorry sets off again
func _cine_go() -> void:
	if man != null:
		_board()
	_walk = []
	_stage("cine_go")
	var c = lorry["car"]
	var f := Vector2(sin(c.h), cos(c.h))
	var eye: Vector2 = c.p - f * 8.0 + Vector2(f.y, -f.x) * 3.2
	_cine(true, MapData.at(eye, 2.4), MapData.at(c.p + f * 2.0, 1.3))
	G.say(Loc.t("n_repartidor"), _arabic(), "adult_m", func():
		_lorry_go(stop(stop_i + 1)["road"] if stop_i < STOPS.size() - 1 else null)
		Sfx.noise(0.4, -12.0)
		_pause = 3.2
		_then = "go_over")

# ---------------- when it goes wrong ----------------
func _release_lorry() -> void:
	if lorry == null:
		return
	if G.traffic.list.has(lorry):
		if (lorry["car"].riders[0] as Dictionary).is_empty():
			lorry["car"].seat(MAN.duplicate())
		lorry.erase("auto")                      # one more car in the traffic: it goes where it likes and is cleared away like any other
		lorry.erase("pace")
		lorry.erase("patient")
		lorry["halt"] = false
		lorry["route"] = []
	lorry = null

## why: close | lost | caught | late
func fail(why: String) -> void:
	_cine(false)
	G.cine_lock = false
	G.hud.timer_slot.visible = false
	G.player.y = 0.0
	if man != null and is_instance_valid(man):   # he stays where he is, shouting, until you are gone
		if man.state == "busy":
			man.state = "idle"
		man.bark(_arabic(), 4.0)
		G.named.erase("repartidor")
		_left.append(man)
		man = null
	_walk = []
	_pause = 0.0
	if boxes != null:
		if boxes.get_parent() != G:
			boxes.queue_free()
		else:
			_left.append(boxes)
		boxes = null
	_release_lorry()
	G.stats["luis_fails"] = int(G.stats.get("luis_fails", 0)) + 1
	G.hud.toast(Loc.t("t_sab_fail_" + why), 6.0)
	Sfx.noise(0.5, -8.0)
	Sfx.beep(220.0, 0.5, 3, -10.0, -150.0)
	_stage("failed")
	_rang = false
	_pause = 4.0
	_then = "ring"

func _to_retry() -> void:
	if stage == "failed":
		_stage("retry")

## the mission is off: `dropped` if the main story took over, otherwise you told him no after a failure
func abort(dropped: bool) -> void:
	_cine(false)
	G.cine_lock = false
	G.hud.timer_slot.visible = false
	_clear()
	stage = ""
	G.side = null
	if dropped:
		G.hud.toast(Loc.t("t_side_dropped_luis"), 4.0)
	else:
		declined = true
		G._show_step()

func _clear() -> void:
	if man != null and is_instance_valid(man):
		G.npcs.erase(man)
		G.named.erase("repartidor")
		man.queue_free()
	man = null
	if boxes != null and is_instance_valid(boxes):
		boxes.queue_free()
	boxes = null
	_release_lorry()
	_walk = []
	_pause = 0.0
	_then = ""
	seen = 0.0
	lost = 0.0
	blind = 0.0
	caught = 0.0
	armed = false
	_warned = ""

func _reward() -> void:
	var n = _luis()
	G.say(n.shown_name(), Loc.t("luis_done"), n.voice, func():
		stage = ""
		G.side = null
		_clear()
		G.money += PAY
		G._refresh_counts()
		G.stats["luis_done"] = int(G.day_n)
		G.hud.stamp(Loc.t("stamp_done"))
		Sfx.jingle([523, 659, 784, 1047], 0.12)
		G.folk.add("luis", 10)                   # (which is also what puts him in the Agenda)
		G.add_pc(3, true)                        # (a side mission: three Puntos Cívicos)
		G._mission_done()
		G._show_step()
		G.comida.eat()                           # ...and the kebab, there and then
		get_tree().create_timer(4.5).timeout.connect(func(): G.hud.toast(Loc.t("t_luis_unlocked"), 5.0)))

# ---------------- every tick ----------------
func _sees_you(pp: Vector2) -> bool:
	if man == null:
		return false
	var to: Vector2 = pp - man.p
	var d := to.length()
	if d < 1.4:
		return true                              # (you have walked into him)
	if d > EYES or absf(angle_difference(man.h, atan2(to.x, to.y))) > EYES_ANGLE:
		return false
	return G.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(MapData.at(man.p, 1.4), MapData.at(pp, 1.2), 1)).is_empty()

func _warn(what: String) -> void:
	if _warned != what:
		_warned = what
		if what != "":
			G.hud.toast(Loc.t("t_sab_" + what), 2.6)
			Sfx.beep(880.0, 0.12, 1, -12.0)

func tick(dt: float, pp: Vector2) -> void:
	for thing in _left.duplicate():              # what an earlier try left behind
		if not is_instance_valid(thing):
			_left.erase(thing)
		elif Vector2(thing.global_position.x, thing.global_position.z).distance_to(pp) > 120.0 or stage == "cine_out":
			G.npcs.erase(thing)
			thing.queue_free()
			_left.erase(thing)
	if stage == "":
		return
	if G.dlg == null and _pause > 0.0:
		_pause -= dt
		if _pause <= 0.0:
			_after_pause(_then)
	if G.dlg == null:
		_man_tick(dt)
	if man != null and is_instance_valid(man) and man.state != "busy":       # knocked flying: he has seen you, and how
		fail("caught")
		return
	if lorry != null and not G.traffic.list.has(lorry):      # you have made off with the lorry itself
		lorry = null
		fail("caught")
		return
	match stage:
		"follow":
			_follow(dt, pp)
		"unload", "window":
			if _sees_you(pp):
				caught += dt
				if caught > 0.6:
					fail("caught")
					return
			else:
				caught = maxf(0.0, caught - dt)
			if stage == "window":
				t -= dt
				var left := maxf(0.0, t)
				G.hud.timer_label.text = "%d:%02d" % [int(left) / 60, int(left) % 60]
				G.hud.timer_label.add_theme_color_override("font_color", Color("ff7b5c") if left < 10.0 else G.hud.CREAM)
				if left < 10.0 and int(left) != int(left + dt):
					Sfx.beep(880.0, 0.07)
				if t <= 0.0:
					fail("late")
		"act":
			t -= dt
			if STOPS[stop_i][1] == "cago":
				G.player.y = -0.28 * sin(clampf(1.0 - t / ACT_FOR, 0.0, 1.0) * PI)       # down on your haunches, and up
				G.player.sync()
			if _sees_you(pp):
				fail("caught")
			elif t <= 0.0:
				_acted()
		"failed":
			if _rang and G.phone_call == null and G.dlg == null and not G.llamadas.pending("luis"):      # (you let it ring out: he is waiting all the same)
				_to_retry()

## A parked car the lorry cannot get past is taken out of its way (its owner has moved it, shall we say): the lorry
## has a round to finish, and whoever follows it cannot be left waiting behind a jam that will never clear.
func _make_way() -> void:
	if float(lorry.get("wait", 0.0)) < 3.0 or not lorry.has("dbg") or int(lorry["dbg"][0]) != G.traffic.VEHICLE:
		return
	var at: Vector2 = lorry["dbg"][2]
	for car in G.cars:
		if car != G.in_car and car != G.paca_car and car.p.distance_to(at) < 3.2 and car.vel.length() < 0.5:
			G.cars.erase(car)
			car.queue_free()
			lorry["wait"] = 0.0
			return

func _follow(dt: float, pp: Vector2) -> void:
	var c = lorry["car"]
	var d: float = pp.distance_to(c.p)
	var goal: Vector2 = stop(stop_i)["road"]
	if G.target == null:                         # (the arrow points straight at it: no street route to work out, which is slow)
		G.set_target(c.p, false)
		MapData.clear_route()
	G.target = c.p
	_route_t -= dt
	if _route_t <= 0.0:
		_route_t = 2.0
		if (lorry.get("route", []) as Array).size() < 2:
			lorry["route"] = G.traffic.route_nodes(MapData.nodes[lorry["b"]], goal).slice(1)
		if float(lorry.get("idle", 0.0)) > 24.0:             # wedged somewhere: on to the next corner
			c.place(MapData.nodes[lorry["b"]], c.h)
			lorry["idle"] = 0.0
	if c.p.distance_to(goal) < 13.0:             # there
		lorry["halt"] = true
		if c.vel.length() < 0.6:
			G.set_target(null, false)
			_warn("")
			_unload()
		return
	_make_way()
	if c.forward_speed() < -0.5:                 # backing out of somewhere, towards you: if it brings you within its mirror,
		armed = false                            # that is not you following too close -- not until you have dropped back again
		seen = 0.0
	if not armed and d > CLOSE + 5.0:
		armed = true
	# "he sees you in the mirror": close behind it while it is going along. (Not while it stands in a jam or backs out of
	# one, and not if it has had to turn round and comes past you: none of that is your doing.)
	var behind: bool = (pp - c.p).dot(Vector2(sin(c.h), cos(c.h))) < 0.0
	if armed and d < CLOSE and behind and c.forward_speed() > 1.5:
		seen += dt
		_warn("close")
		if seen >= SEEN_FOR:
			fail("close")
			return
	else:
		seen = maxf(0.0, seen - dt * 0.5)
	_sight_t -= dt
	if _sight_t <= 0.0:
		_sight_t = 0.3
		_in_sight = G.police._can_see(c, pp, 9999.0)
	blind = 0.0 if (_in_sight or d < NEAR_ENOUGH) else blind + dt      # (round a corner from it but close by is not having lost it)
	lost = lost + dt if d > FAR else 0.0
	if d > FAR * 0.75 or blind > BLIND_FOR * 0.5:
		_warn("far")
	elif not (armed and d < CLOSE and behind):
		_warn("")
	if lost >= LOST_FOR or blind >= BLIND_FOR:
		fail("lost")
