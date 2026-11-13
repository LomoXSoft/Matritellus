extends Node
## The roast ham riot (the user's design, 13 November 2026; guion/misiones_y_puntos_civicos.md).
##
## Every Thursday there is a crowd outside La Cocina de Henry, all of them after the roast ham. Walk up and a scene
## begins: Henry comes out and tells them there are too many of them and not enough hams, so it will have to be "the
## usual" -- close shots of neighbours bringing out short weapons (a bat with nails in it, a knife, a knuckle-duster),
## held like the duel at the end of a western -- "you know how it goes: whoever is left standing gets roast ham".
##
## The game: you raise the bat Josefa "gave" you (she only ever mentions it), the camera drops in over your shoulder,
## and for sixty seconds it is everybody against everybody. Every neighbour has 100 points of health and loses 25 with
## each blow; at nought they are out cold. You can be knocked down, but you have no health: it is a race. Two of
## them are always after you. There are never fewer than ten on their feet: when there are, more come running from
## the street corners. Los Pitufos take no notice while it lasts. +5 for a blow that lands, +10 for the one that
## lays somebody out. Afterwards Henry congratulates you on your way with a stick.
##
## When: the first time, whenever you go for Josefa's menu (her first errand); from then on, every Thursday -- with a
## ham to fetch or without -- and from the Agenda whenever you like (no Puntos Cívicos for that).

const Parts = preload("res://scripts/parts.gd")
const TIME := 60.0
const ACTIVE := 10              # never fewer than this many on their feet
const CROWD := 14               # how many are waiting outside to begin with
const HP := 100
const BLOW := 25
const HIT := 5
const KO := 10
const RING := 15.0              # how far from the middle of it you can get while it lasts
const NEAR := 13.0              # walk up this close and it begins
const ON_YOU := 2               # how many are always after you
const FLOORED := 1.6            # seconds on the ground when they get you
const WEAPONS := ["bate", "cuchillo", "puno"]

var G
var stage := ""                 # "" | wait | cine | fight | after
var crowd: Array = []           # {n, hp, target (a fighter, "you" or null), cool, stun, down, bar, fill, arm, kind}
var score := 0
var blows := 0
var kos := 0
var t := 0.0
var floor_t := 0.0              # > 0: you are on the ground
var safe_t := 0.0               # > 0: just up again, they cannot floor you yet
var raising := false            # the bat held up, for the last shot of the scene
var agenda := false             # started from the Agenda: for the score only
var came := 0                   # how many have come running from the corners
var _back = null                # where to put you back afterwards (from the Agenda)
var _beats: Array = []
var _beat := -1
var _beat_t := 0.0
var _bat: Node3D
var _was_muted := false
var _spawn_cool := 0.0
var _shout := 3.0
var _left: Array = []           # [neighbour, seconds until they get up / wander off]
var _fov := 55.0

func setup(game) -> void:
	G = game

func centre() -> Vector2:
	return G.places["henry"]["p"]

func along() -> Vector2:
	return G.places["henry"]["u"]

func fighting() -> bool:
	return stage == "fight"

func busy() -> bool:
	return stage == "cine" or stage == "fight" or stage == "after"

func floored() -> bool:
	return stage == "fight" and floor_t > 0.0

func _errand() -> bool:
	return G.side != null and (G.side["id"] == "ham" or G.side["id"] == "menu") and G.side["stage"] == "fetch"

## Is there a crowd outside Henry's now? With a ham to fetch, always; otherwise on Thursdays, once you have been
## through it once, until you have had today's.
func wanted() -> bool:
	if stage == "cine" or stage == "fight" or stage == "after":
		return true
	if not (G.phase == "play" or G.phase == "free"):
		return stage == "wait"
	if _errand():
		return true
	if G.side != null or G.in_mission():         # (with a mission under way nothing else is on: no events, no minigames)
		return false
	return G.unlocked.has("jamon") and G.weekday == 3 and G.clock >= 8.0 and G.clock < 21.0 and int(G.stats.get("jamon_day", -1)) != int(G.day_n) and G.negocio("restaurantes") 		and not G.sabotaje.active()              # (Don Luis's delivery lorry comes down this very street: not while it is about)

## (game.gd asks: is the ham to be had by walking up to the door, or does it have to be fought for?)
func in_the_way() -> bool:
	return stage != "" or wanted()

# ---------------- the crowd ----------------
func _spot(k: int) -> Vector2:
	var u := along()
	var side := Vector2(-u.y, u.x)
	var hw: float = maxf(2.0, MapData.fitted_hw(G.places["henry"]["seg"]) - 0.4)
	return centre() + u * (-6.5 + (k % 7) * 2.1 + (0.5 if (k / 7) % 2 == 1 else 0.0)) + side * clampf(-hw + 0.8 + (k / 7) * (hw * 0.9) + sin(k * 2.3) * 0.5, -hw, hw)

func _fighter(at: Vector2) -> Dictionary:
	var n = G.spawn_neighbour(at, true)
	if n.voice == "kid":                         # (no children in this)
		n.voice = "adult_m"
		n.look_data["scale"] = 1.0
		n.set_look(n.look_data)
	n.state = "busy"
	var f := {"n": n, "hp": HP, "target": null, "cool": randf_range(0.6, 1.6), "stun": 0.0, "down": false, "bar": null, "fill": null, "arm": null, "kind": WEAPONS[crowd.size() % WEAPONS.size()]}
	crowd.append(f)
	return f

func _gather() -> void:
	var door: Vector2 = G.named["henry"].home
	for k in range(CROWD):
		var f := _fighter(_spot(k))
		var to: Vector2 = door - f["n"].p
		f["n"].h = atan2(to.x, to.y)
		f["n"].sync()
	stage = "wait"

## a weapon in their right hand (the hand is a ball a tenth the size of anything: what hangs from it is scaled back up)
func _weapon(kind: String) -> Node3D:
	var w := Node3D.new()
	w.scale = Vector3.ONE / 0.12
	match kind:
		"bate":                                  # a bat with nails through it
			w.add_child(Parts.part("cyl", 0x8a6a48, Vector3(0, 0.36, 0), Vector3(0.05, 0.82, 0.05)))
			w.add_child(Parts.part("cyl", 0x6f5236, Vector3(0, 0.62, 0), Vector3(0.075, 0.34, 0.075)))
			for k in range(5):
				var nail := Parts.part("box", 0xc9ced4, Vector3(0, 0.5 + k * 0.06, 0), Vector3(0.2, 0.012, 0.012))
				nail.rotation.y = k * 1.3
				w.add_child(nail)
		"cuchillo":
			w.add_child(Parts.part("box", 0x2a2c30, Vector3(0, 0.02, 0), Vector3(0.04, 0.14, 0.05)))
			w.add_child(Parts.part("box", 0xd8dde2, Vector3(0, 0.26, 0.01), Vector3(0.015, 0.34, 0.07)))
		_:                                       # a knuckle-duster
			var ring := Parts.part("ring", 0xe6b422, Vector3(0, 0.0, 0.06), Vector3.ONE * 0.11)
			ring.rotation.x = PI / 2.0
			w.add_child(ring)
			for k in range(4):
				w.add_child(Parts.part("ball", 0xe6b422, Vector3(-0.06 + k * 0.04, 0.03, 0.11), Vector3.ONE * 0.022))
	return w

func _arm(f: Dictionary) -> void:
	if f["arm"] != null or not is_instance_valid(f["n"]):
		return
	f["arm"] = _weapon(f["kind"])
	f["n"]._hr.add_child(f["arm"])
	# and over their head, how much they have left
	var bar := Node3D.new()
	bar.position = Vector3(0, 2.35 * f["n"].size, 0)
	bar.add_child(Parts.part("box", 0x1a120c, Vector3.ZERO, Vector3(0.9, 0.13, 0.02)))
	var fill := Parts.part("box", 0x35c05a, Vector3(0, 0, 0.012), Vector3(0.86, 0.09, 0.02))
	bar.add_child(fill)
	bar.visible = false
	f["n"].add_child(bar)
	f["bar"] = bar
	f["fill"] = fill

func _bar(f: Dictionary) -> void:
	var frac: float = clampf(float(f["hp"]) / HP, 0.0, 1.0)
	var fill: MeshInstance3D = f["fill"]
	fill.scale.x = maxf(0.001, 0.86 * frac)
	fill.position.x = -(1.0 - frac) * 0.43
	fill.material_override = Parts.mat(0x35c05a if frac > 0.5 else (0xe6c229 if frac > 0.25 else 0xe23b3b))

func _give_bat() -> void:
	if _bat != null and is_instance_valid(_bat):
		return
	_bat = Node3D.new()
	_bat.scale = Vector3.ONE / 0.12
	_bat.add_child(Parts.part("cyl", 0xc9a26b, Vector3(0, 0.4, 0), Vector3(0.05, 0.9, 0.05)))
	_bat.add_child(Parts.part("cyl", 0xb58a52, Vector3(0, 0.68, 0), Vector3(0.08, 0.36, 0.08)))
	G.player._hr.add_child(_bat)

## laid over whatever your arms and legs were doing (called after the player's own anim)
func pose(pl) -> void:
	if raising:
		pl._hr.position = Vector3(0.42, 1.72, 0.12)
	if stage == "fight" and floor_t > 0.0:
		var k := clampf((FLOORED - floor_t) / 0.3, 0.0, 1.0) * clampf(floor_t / 0.3, 0.0, 1.0)
		pl.inner.rotation.x = -k * PI / 2.0
		pl.inner.position.y = 0.35 * k
	elif stage == "fight":
		pl.inner.rotation.x = 0.0

# ---------------- the scene ----------------
func _cut(from: Vector3, at: Vector3, fov := 55.0) -> void:
	G.cam_fixed = [from, at]
	G.cam_pos = from
	G.cam_look = at
	G.cam.fov = fov

func _eye(p: Vector2, lift: float) -> Vector3:
	return Vector3(p.x, MapData.foot(p) + lift, p.y)

func _begin() -> void:
	if G.in_car != null:
		G.in_car.set_speed(Vector2.ZERO)
		G._exit_car()
	stage = "cine"
	score = 0
	blows = 0
	kos = 0
	came = 0
	raising = false
	_was_muted = G.police.muted
	G.police.muted = true                        # Los Pitufos take no notice of any of it
	G.cine_lock = true
	G.hud.cine(true)
	G.set_target(null, false)
	_fov = G.cam.fov
	for e in G.traffic.list.duplicate():         # the street is theirs
		if not e.get("auto", false) and e["car"].p.distance_to(centre()) < 70.0:
			G.traffic.list.erase(e)
			e["car"].queue_free()
	var u := along()
	var henry = G.named["henry"]
	G.player.p = centre() - u * 8.5
	G.player.h = atan2(u.x, u.y)
	G.player.sync()
	G.cam_yaw = G.player.h
	var out: Vector2 = (centre() - henry.p).normalized()
	henry.h = atan2(out.x, out.y)
	henry.sync()
	for f in crowd:
		var to: Vector2 = henry.p - f["n"].p
		f["n"].h = atan2(to.x, to.y)
		f["n"].sync()
	var side := Vector2(-u.y, u.x)
	var three: Array = [crowd[1], crowd[5], crowd[9]]
	_beats = [
		["cut", 2.4, _eye(centre() - u * 15.0 + side * 2.0, 0.7), _eye(henry.p, 1.7), 60.0],                    # low and wide: the street, the crowd, the door
		["say", Loc.t("henry_motin"), _eye(henry.p + out * 5.5 + side * 1.6, 2.9), _eye(henry.p, 1.2), 30.0],        # over their heads, down on him at his door
	]
	for k in range(3):                               # the weapons come out: one hand after another
		_beats.append(["draw", [1.0, 0.85, 0.7][k], three[k]])
	for k in range(6):                               # and the eyes, quicker each time
		_beats.append(["eyes", maxf(0.22, 0.6 - k * 0.08), three[k % 3] if k % 2 == 0 else null])
	_beats.append(["say", [Loc.t("henry_motin_ya")], _eye(henry.p + out * 2.3, 1.45), _eye(henry.p, 1.4), 22.0])
	_beats.append(["raise", 1.5])
	_beat = -1
	_next_beat()

func _next_beat() -> void:
	_beat += 1
	if _beat >= _beats.size():
		_fight()
		return
	var b: Array = _beats[_beat]
	_beat_t = float(b[1]) if not (b[1] is Array) else 0.0
	var henry = G.named["henry"]
	match b[0]:
		"cut":
			_cut(b[2], b[3], b[4])
			Sfx.beep(110.0, 2.0, 3, -16.0, -8.0)
		"say":
			_cut(b[2], b[3], b[4])
			G.say(henry.shown_name(), b[1], henry.voice, _next_beat)
		"draw":
			var f: Dictionary = b[2]
			var n = f["n"]
			_arm(f)
			n.punch = 0.28
			var face := Vector2(sin(n.h), cos(n.h))
			var right := Vector2(face.y, -face.x)
			_cut(_eye(n.p + right * 0.55 + face * 1.25, 0.72 * n.size), _eye(n.p + right * 0.45, 0.72 * n.size), 26.0)
			Sfx.beep(1400.0, 0.06, 1, -12.0)
			Sfx.noise(0.12, -16.0)
		"eyes":
			var who = (b[2] as Dictionary)["n"] if b[2] != null else henry
			var face2 := Vector2(sin(who.h), cos(who.h))
			_cut(_eye(who.p + face2 * 2.4, 1.43 * who.size), _eye(who.p, 1.43 * who.size), 9.0)
			Sfx.beep(220.0 + _beat * 22.0, 0.12, 1, -12.0)
		"raise":
			for f2 in crowd:
				_arm(f2)
			_give_bat()
			raising = true
			var pf := Vector2(sin(G.player.h), cos(G.player.h))
			_cut(_eye(G.player.p + pf * 2.3 + Vector2(pf.y, -pf.x) * 0.9, 0.55), _eye(G.player.p, 1.5), 48.0)
			Sfx.jingle([330, 392, 494, 659], 0.16)

## ...and they are off
func _fight() -> void:
	raising = false
	G.cam.fov = _fov
	G.cam_fixed = null
	G.cine_lock = false
	G.hud.cine(false)
	stage = "fight"
	t = TIME
	floor_t = 0.0
	safe_t = 1.5
	_spawn_cool = 0.0
	for f in crowd:
		_arm(f)
		f["bar"].visible = true
		_bar(f)
		var to: Vector2 = centre() - f["n"].p
	G.hud.set_bottles(0)
	G.hud.timer_slot.visible = true
	_show()
	Sfx.noise(0.5, -8.0)
	Sfx.jingle([659, 880, 659, 880], 0.09)

func _show() -> void:
	G.hud.set_objective(G._tag(), Loc.t("obj_motin") % score)

# ---------------- the fight ----------------
func _standing() -> Array:
	return crowd.filter(func(f): return not f["down"] and is_instance_valid(f["n"]))

func _floor_you() -> void:
	floor_t = FLOORED
	G.shake = 0.5
	Sfx.noise(0.25, -8.0)
	Sfx.beep(300.0, 0.3, 2, -10.0, -200.0)
	G.hud.toast(Loc.t("t_motin_down").pick_random(), 1.6)

## a blow lands on this one. Returns true if it laid them out.
func _hurt(f: Dictionary, from: Vector2, yours: bool) -> bool:
	var n = f["n"]
	f["hp"] = int(f["hp"]) - BLOW
	f["stun"] = 0.35
	_bar(f)
	var away: Vector2 = (n.p - from).normalized()
	n.shove(away * 0.45)
	Sfx.noise(0.1, -9.0 if yours else -18.0)
	Sfx.beep(170.0, 0.1, 2, -10.0 if yours else -20.0, -60.0)
	var out: bool = int(f["hp"]) <= 0
	if out:
		f["down"] = true
		f["target"] = null
		f["bar"].visible = false
		n.inner.rotation.x = -PI / 2.0
		n.inner.position.y = 0.35
		n.look_at_spot(null, 1.0)
	if yours:
		score += KO if out else HIT
		blows += 1
		if out:
			kos += 1
			Sfx.jingle([784, 1047], 0.07)
		_show()
	return out

## your swing: whoever is within reach in front of you gets it (two of them at most)
func swing() -> void:
	if stage != "fight" or floor_t > 0.0 or G._punch_cool > 0.0:
		return
	G._punch_cool = 0.38
	G.player.punch = 0.28
	Sfx.beep(190.0, 0.07, 4, -14.0)
	var dir := Vector2(sin(G.player.h), cos(G.player.h))
	var near: Array = []
	for f in _standing():
		var to: Vector2 = f["n"].p - G.player.p
		if to.length() < 1.9 and (to.length() < 0.6 or to.normalized().dot(dir) > 0.25):
			near.append(f)
	near.sort_custom(func(a, b): return a["n"].p.distance_squared_to(G.player.p) < b["n"].p.distance_squared_to(G.player.p))
	for f in near.slice(0, 2):
		_hurt(f, G.player.p, true)

func _pick(f: Dictionary, up: Array):
	var best = null
	var bd := 1e9
	for o in up:
		if o == f:
			continue
		var d: float = o["n"].p.distance_squared_to(f["n"].p) * randf_range(0.6, 1.4)
		if d < bd:
			bd = d
			best = o
	return best

func _fight_tick(dt: float, pp: Vector2) -> void:
	t -= dt
	var left := maxf(0.0, t)
	G.hud.timer_label.text = "%d:%02d" % [int(left) / 60, int(left) % 60]
	G.hud.timer_label.add_theme_color_override("font_color", Color("ff7b5c") if left < 10.0 else G.hud.CREAM)
	if left < 10.0 and int(left) != int(left + dt):
		Sfx.beep(880.0, 0.07)
	if floor_t > 0.0:
		floor_t -= dt
		if floor_t <= 0.0:
			safe_t = 1.4
	safe_t = maxf(0.0, safe_t - dt)
	var off: Vector2 = pp - centre()             # nobody leaves until it is over
	if off.length() > RING:
		G.player.p = centre() + off.normalized() * RING
	var up := _standing()
	# never fewer than ten on their feet: more come running from the street corners
	_spawn_cool -= dt
	if up.size() < ACTIVE and _spawn_cool <= 0.0:
		_spawn_cool = 0.5
		var corner = MapData.random_node_near(centre(), 26.0, 75.0)
		if corner != null:
			var f := _fighter(corner)
			_arm(f)
			f["bar"].visible = true
			_bar(f)
			came += 1
			up.append(f)
	# two of them are always after you
	var on_you: Array = up.filter(func(f): return f["target"] is String)
	while on_you.size() < ON_YOU and on_you.size() < up.size():
		var best = null
		var bd := 1e9
		for f in up:
			if not (f["target"] is String) and f["n"].p.distance_squared_to(pp) < bd:
				bd = f["n"].p.distance_squared_to(pp)
				best = f
		if best == null:
			break
		best["target"] = "you"
		on_you.append(best)
	for f in up:
		var n = f["n"]
		if n.state != "busy":                    # (sent flying by something else: back into it when they land)
			if n.state == "idle":
				n.state = "busy"
			continue
		if f["bar"] != null:
			f["bar"].global_rotation.y = G.cam_yaw + PI      # (its face to the camera)
		if float(f["stun"]) > 0.0:
			f["stun"] -= dt
			n.anim(false, dt, 0.0)
			n.sync()
			continue
		if not (f["target"] is String) and (f["target"] == null or f["target"]["down"] or not is_instance_valid(f["target"]["n"])):
			f["target"] = _pick(f, up)
		var at: Vector2 = pp if f["target"] is String else (f["target"]["n"].p if f["target"] != null else centre())
		var to: Vector2 = at - n.p
		var d := to.length()
		var dir := to / maxf(d, 0.01)
		n.h = lerp_angle(n.h, atan2(dir.x, dir.y), 1.0 - exp(-10.0 * dt))
		if d > 1.3:
			n.walk(dir, 5.2 if n.p.distance_to(centre()) > RING else 3.1)
			n.anim(true, dt, 0.0)
		else:
			n.anim(false, dt, 0.0)
			f["cool"] -= dt
			if f["cool"] <= 0.0 and f["target"] != null:
				f["cool"] = randf_range(1.0, 1.7)
				n.punch = 0.28
				if f["target"] is String:
					if floor_t <= 0.0 and safe_t <= 0.0 and randf() < 0.4:
						_floor_you()
				elif randf() < 0.6:
					_hurt(f["target"], n.p, false)
		n.sync()
	if t <= 0.0:
		_over()

func _over() -> void:
	stage = "after"
	floor_t = 0.0
	G.player.inner.rotation.x = 0.0
	G.hud.timer_slot.visible = false
	G.cine_lock = true
	Sfx.noise(0.5, -8.0)
	Sfx.jingle([523, 659, 784, 1047], 0.12)
	var henry = G.named["henry"]
	for f in crowd:
		if is_instance_valid(f["n"]) and not f["down"]:
			var to: Vector2 = henry.p - f["n"].p
			f["n"].h = atan2(to.x, to.y)
			f["n"].anim(false, 0.016, 0.0)
			f["n"].sync()
	G.say(henry.shown_name(), Loc.t("henry_motin_fin"), henry.voice, _finish)

func _finish() -> void:
	var errand := _errand()
	G.cine_lock = false
	G.police.muted = _was_muted
	stage = ""
	G.stats["jamon_best"] = maxi(int(G.stats.get("jamon_best", 0)), score)
	G.stats["jamon_fights"] = int(G.stats.get("jamon_fights", 0)) + 1
	G.stats["jamon_wins"] = int(G.stats.get("jamon_wins", 0)) + 1
	G.hud.toast(Loc.t("t_motin_score") % [score, blows, kos], 6.0)
	G._unlock("jamon")
	if not agenda:
		G.stats["jamon_day"] = int(G.day_n)
		if int(G.stats.get("jamon_pc", -1)) != int(G.day_n):      # a minigame: one Punto Cívico, the first of the day
			G.stats["jamon_pc"] = int(G.day_n)
			G.add_pc(1)
	if _bat != null and is_instance_valid(_bat):
		_bat.queue_free()
	_bat = null
	for f in crowd:                              # they put their things away; the ones on the ground come round in a while
		if not is_instance_valid(f["n"]):
			continue
		for key in ["arm", "bar"]:
			if f[key] != null and is_instance_valid(f[key]):
				f[key].queue_free()
		_left.append([f["n"], randf_range(3.0, 7.0) if f["down"] else 0.0])
	crowd.clear()
	if agenda:
		agenda = false
		if _back != null:
			G.player.p = _back
			G.player.sync()
		_back = null
		G._show_step()
	elif errand:
		G.ham_loaded()
	else:
		G._show_step()

## from the Agenda: there and then, for the score
func replay() -> void:
	agenda = true
	_back = G.player.p
	if stage == "wait":
		_scatter()
	_gather()
	_begin()

func _scatter() -> void:
	for f in crowd:
		if is_instance_valid(f["n"]):
			_left.append([f["n"], 0.0])
	crowd.clear()
	stage = ""

func tick(dt: float, pp: Vector2) -> void:
	for e in _left.duplicate():                  # those who were in it: up again, and off home once you are not there to see
		var n = e[0]
		if not is_instance_valid(n):
			_left.erase(e)
			continue
		e[1] -= dt
		if n.state == "busy" and e[1] <= 0.0:
			n.inner.rotation.x = 0.0
			n.state = "idle"
			n.still = false
			n.home = n.p
			n.t = 1.0
		if n.p.distance_to(pp) > 110.0 or (e[1] < -40.0 and not G.sees(n.p, 200.0)):
			G.npcs.erase(n)
			n.queue_free()
			_left.erase(e)
	match stage:
		"":
			if wanted() and pp.distance_to(centre()) < 130.0 and not G.indoors:
				_gather()
		"wait":
			if not wanted():
				_scatter()
				return
			for f in crowd:
				f["n"].anim(false, dt, 0.0)
			_shout -= dt
			if _shout <= 0.0 and pp.distance_to(centre()) < 45.0:
				_shout = randf_range(1.8, 4.0)
				crowd.pick_random()["n"].bark(Loc.t("motin_grita").pick_random(), 2.4)
			if pp.distance_to(centre()) < NEAR and G.dlg == null and G.phone_call == null and not G.cine_lock and (G.phase == "play" or G.phase == "free") \
					and G.comida.faint == null and not G.sabotaje.active() and (_errand() or not G.in_mission()):
				_begin()
		"cine":
			for f in crowd:
				f["n"].anim(false, dt, 0.0)
			if G.dlg == null and _beat >= 0 and _beat < _beats.size() and _beats[_beat][0] != "say":
				_beat_t -= dt
				if _beat_t <= 0.0:
					_next_beat()
		"fight":
			_fight_tick(dt, pp)
