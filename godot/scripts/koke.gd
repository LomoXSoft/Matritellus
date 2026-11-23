extends RefCounted
## Koke el Kokas and his taxis (the user, 23 November 2026): "cuarentón pasado de vueltas, le puede la fiesta y las
## drogas y tiene una flota de Z15 tuneadas con las que trabaja de taxista". An hour of game time after Josefa's Vizum
## he rings: his last partner is in a coma ("por ostiarse con el taxi a 140 en la fachada de un colegio"), and he
## offers you the job. The fleet stands on the fairground (the user's choice, 23 Nov), and he with it.
##
## The job, once a day: a run against the clock in the yellow Z15 with the flames and the nitro (car.gd "kokas",
## koke_marcas.gd). Its rules are the arcade taxi games' (no game's name, look or sound of theirs: only how it plays):
##   - the moment you get in the run starts: one clock for the whole shift, START seconds, and an arrow to the first
##     fare. Neighbours stand waving with a ring at their feet whose colour says how far they are going: red near,
##     yellow further, green across town;
##   - stop by one and they get in and say where; each fare has its own clock too. Dropped where they asked, they pay
##     a base by the distance plus a bonus for the time to spare, which shrinks the longer you take (rated: fast,
##     normal, slow), and the shift's clock gets BONUS seconds more. If a fare's own clock runs out they get out
##     without paying;
##   - the shift's clock at nothing, the run is over (what you earned is yours as you went);
##   - the van cannot be broken while it lasts, and Los Pitufos and Los Tricornios leave you be ("a Koke le dejan en
##     paz porque les pasa hierba");
##   - the fares talk: your speed, the knocks, your looks, "si eres el de la Eufrasia" (the user wrote "la Eusebia":
##     the aunt of the game is la Eufrasia), their divorces, their children, their husbands' horns...
## It takes the errand slot as one of the jobs (G.side = {id: "trabajo", kind: "kokas"}: trabajos.gd hands its tick,
## show and abort here). It took the place of El de las faenas' taxi shift (the user, 23 Nov 2026).
##
## Kept in G.stats: "vizum_h" (fondo_casa.gd: game hours at the Vizum), "koke" (the day he rang), "koke_dia" (the
## last day you did the run), "trabajos"["kokas"] (all you have earned with him).

const Chara = preload("res://scripts/chara.gd")
const CarS = preload("res://scripts/car.gd")
const FerialS = preload("res://scripts/ferial.gd")

const LOOK := {
	"top": 23, "shirt": 0xef7f1a, "shirt2": 0x2a9d8f, "skin": 0xe9b58c, "hair": 0x2a1c14, "hair_style": 3, "brows": 2,
	"eyes": 3, "eye_color": 0x3a2a20, "face": 2, "barba3": 1, "glasses": 6, "pendant": 1, "earrings": 1,
	"shoe_type": 0, "shoes": 0xf8f8f8, "build": 1.08, "scale": 1.0, "hat": "",
}
const CALL_AFTER_H := 1.0       # game hours after Josefa's Vizum before he rings
const START := 60.0             # seconds on the shift's clock to begin with
const BONUS := 30.0             # ...and more for each fare left where they asked
const WAITING := 4              # fares waving at a time
const CLASSES := [              # [colour, metres from where they get in: min, max]
	[0xe8402a, 150.0, 320.0],
	[0xf2c81e, 320.0, 560.0],
	[0x3fbf4a, 560.0, 900.0],
]
const STOP := 3.0               # m/s: slow enough to count as stopped
const OUT_OF_CAR := 10.0        # seconds on foot before the shift is over
const FAST := 22.0              # m/s (about 80 km/h): the fare grips the seat
const SLOW := 5.0               # m/s: ...or yawns

var G
var n                           # Koke (npc.gd)
var car                         # the yellow one (car.gd "kokas")
var fleet: Array = []           # the others, standing by it
var spot := Vector2.ZERO        # where the yellow one stands, and its heading
var spot_h := 0.0
var side_sg := 1.0              # which edge of the path the row stands against (Koke on the earth beyond it)
var _t := 0.0
var _chat_i := 0
var _rung := false              # (asked for, this session: a load asks again if it was never answered)
# the run
var _waiting: Array = []        # [{n, cls, ring}]
var _rider = null
var _rider_cls := 0
var _dwell := 0.0
var _out_t := 0.0
var _obj_t := 0.0
var _chat_t := 0.0
var _slow_t := 0.0
var _knocks := 0
var _said: Label3D
var _said_t := 0.0
var _was_muted := false

func setup(game) -> void:
	G = game
	_find_spot()
	car = _one(spot, 0xf2c81e)
	for col in [0x1f1f24, 0x3b5fa8]:
		fleet.append(_one(spot, col))
	n = G._make_npc("koke", LOOK.duplicate(), "adult_m", spot)
	n.still = true
	_settle()

static func _perp(u: Vector2) -> Vector2:
	return Vector2(-u.y, u.x)

## Where the fleet stands: in a row along the fairground's longest path (the map's unnamed roads closed to traffic with
## their middles inside it, as ferial.gd _fair_segs finds them), against either edge, clear of the bars' terraces
## (props.gd) by 7 m all down the row. The terraces are laid out after this is set up, so it is worked out again on
## the first tick that has them (_settled).
var _u := Vector2(0.0, 1.0)
var _settled := false
func _find_spot() -> void:
	var fair := PackedVector2Array(FerialS.FAIR)
	var best = null
	for s in MapData.segs:
		if String(s.road.get("n", "")) != "" or not (int(s.road["k"]) == 0 or int(s.road.get("paved", 0)) == 4):
			continue
		if Geometry2D.is_point_in_polygon((s.a + s.b) / 2.0, fair) and (best == null or s.a.distance_to(s.b) > best.a.distance_to(best.b)):
			best = s
	var mid: Vector2 = FerialS.FAIR[0]
	var hw := 3.0
	if best != null:
		_u = (best.b - best.a).normalized()
		mid = (best.a + best.b) / 2.0
		hw = MapData.fitted_hw(best)
	spot_h = atan2(_u.x, _u.y)
	var terr: Array = (G.props.terrazas if G.get("props") != null else []).map(func(t): return t["p"])
	_settled = not terr.is_empty()
	for along in [5.0, -5.0, 15.0, -15.0, 25.0, -25.0, 35.0, -35.0]:
		for sg in [1.0, -1.0]:
			var at: Vector2 = mid + _perp(_u) * sg * maxf(0.0, hw - 1.3) + _u * along
			var clear := true
			for k in range(3):
				var q: Vector2 = at - _u * 5.2 * k
				if MapData.room_at(q) < 1.0 or terr.any(func(t): return (t as Vector2).distance_to(q) < 7.0):
					clear = false
			if clear:
				spot = at
				side_sg = sg
				return
	spot = mid + _perp(_u) * maxf(0.0, hw - 1.3) + _u * 5.0

## A parked car far from you is frozen (car.doze), and a frozen one moved leaves its wheels behind: woken first
## (game.gd puts it back to sleep when nobody is near).
func _put(c, at: Vector2) -> void:
	c.doze(false)
	c.place(at, spot_h)
	c.park()

## the yellow one at the spot, the others behind it, Koke on the earth beside them
func _settle() -> void:
	_put(car, spot)
	for k in range(fleet.size()):
		_put(fleet[k], spot - _u * 5.2 * (k + 1))
	n.p = spot + _perp(_u) * side_sg * 2.6
	n.home = n.p
	n.h = spot_h + PI / 2.0
	n.sync()

func _one(at: Vector2, hex: int):
	var c = CarS.new()
	G.add_child(c)
	c.setup("kokas", hex, at, spot_h)
	c.park()
	G.cars.append(c)
	return c

func now_h() -> float:
	return float(G.day_n) * 24.0 + float(G.clock)

func called() -> bool:
	return G.stats.has("koke")

## can the day's run be started now?
func available() -> bool:
	return called() and int(G.stats.get("koke_dia", -1)) != int(G.day_n) and not running()

func running() -> bool:
	return G.trabajos != null and G.trabajos.active() and G.trabajos.kind() == "kokas"

# ---------------- his radio ----------------
## His cars are tuned to Koka y Ná, and the dial only turns from it to Traktor and back (the user, 23 Nov 2026: "Los
## coches de Koke tienen sintonizada por defecto Koka Y Na, y solo puedes alternala con Traktor. Ni otras cadenas ni
## apagarla."). Out of the car, the radio goes back to what you had before. The stations are found by their names
## (radio/radio*/emisora.json): without either of the two, his radio is like any other.
var _radio_was := -1            # the station you had before you got into one of his (-1: you are not in one)

static func station_of(word: String) -> int:
	for k in range(Ambience.stations.size()):
		if String(Ambience.stations[k]["name"]).to_lower().contains(word):
			return k + 1
	return 0

func _in_his() -> bool:
	return G.in_car != null and String(G.in_car.kind) == "kokas"

func _radio_tick() -> void:
	var inside := _in_his()
	if inside and _radio_was < 0:
		_radio_was = Ambience.station
		var koka := station_of("koka")
		if koka > 0 and station_of("traktor") > 0:
			Ambience.station = koka
			if not Ambience.song_changed.is_connected(G._song_changed):
				Ambience.song_changed.connect(G._song_changed)
			G.hud.radio_card(Ambience.stations[koka - 1])
	elif not inside and _radio_was >= 0:
		Ambience.station = mini(_radio_was, Ambience.stations.size())
		_radio_was = -1

## the radio key in one of his cars: Koka y Ná and Traktor in turn, never another nor off. null: not one of his (the
## dial turns as always)
func radio_flip():
	var koka := station_of("koka")
	var trak := station_of("traktor")
	if not _in_his() or koka == 0 or trak == 0:
		return null
	Ambience.station = trak if Ambience.station == koka else koka
	return Ambience.stations[Ambience.station - 1]

# ---------------- his call ----------------
func tick(dt: float) -> void:
	_radio_tick()
	if _said != null and is_instance_valid(_said):
		_said_t -= dt
		if _said_t <= 0.0:
			_said.visible = false
	_t -= dt
	if _t > 0.0:
		return
	_t = 1.0
	if not _settled and G.get("props") != null and not G.props.terrazas.is_empty() and not running() and G.in_car != car:
		_find_spot()
		_settle()
	if G.stats.has("vizum") and not called() and not _rung and G.phase == "free" and G.dlg == null:
		if not G.stats.has("vizum_h"):
			G.stats["vizum_h"] = now_h() - CALL_AFTER_H         # (a game saved before 23 Nov, the Vizum long had: he rings now)
		if now_h() >= float(G.stats["vizum_h"]) + CALL_AFTER_H:
			_rung = true
			G.llamadas.ring({"npc": "koke", "lines": "koke_call", "plain": true, "valid": func(): return not called(), "after": _hired})
	if not running():
		_bring_back()

func _hired() -> void:
	if called():
		return
	G.stats["koke"] = int(G.day_n)
	G.folk.meet("koke")
	G.hud.toast(Loc.t("t_koke_new"), 7.0)
	Sfx.jingle([392, 523, 659, 784], 0.08)

## the yellow one, left somewhere after a run: back by the fleet, once nobody sees it go
func _bring_back() -> void:
	if car == null or not is_instance_valid(car) or G.in_car == car:
		return
	if car.p.distance_to(spot) > 12.0 and not G.sees(car.p) and not G.sees(spot):
		_put(car, spot)
		car.repair()

# ---------------- face to face ----------------
func talk(who) -> bool:
	if who == null or who.id != "koke":
		return false
	var lines: Array
	if not called():
		lines = [Loc.t("koke_stranger").pick_random()]
	elif running():
		lines = [Loc.t("koke_busy").pick_random()]
	elif available():
		lines = Loc.t("koke_hello")
	elif int(G.stats.get("koke_dia", -1)) == int(G.day_n):
		lines = Loc.t("koke_done_today")
	else:
		var pool: Array = Loc.t("koke_chat")
		lines = pool[_chat_i % pool.size()]
		_chat_i += 1
	G.say(who.shown_name(), lines, who.voice)
	return true

## for the marks (marcas.gd): Koke, while the day's run is there for you
func givers(free_hands: bool) -> Array:
	if free_hands and available() and n != null and is_instance_valid(n):
		return [n]
	return []

## getting into the yellow one: not his unless the run is yours today (game.gd, before _enter_car)
func refuses(c) -> bool:
	if c == null or c != car or running():
		return false
	if not called():
		_bark_koke(Loc.t("koke_mine").pick_random())
		return true
	if int(G.stats.get("koke_dia", -1)) == int(G.day_n):
		_bark_koke(Loc.t("koke_tomorrow").pick_random())
		return true
	if not G.trabajos._free():
		G.hud.toast(Loc.t("t_koke_busy"), 3.0)
		return true
	return false

func _bark_koke(line: String) -> void:
	if n != null and is_instance_valid(n) and n.p.distance_to(G.player.p) < 40.0:
		n.bark(line, 3.5)
	else:
		G.hud.toast(line, 3.0)

## you are in a car (game.gd _enter_car): the yellow one, and the run is there for you -- off it goes
func entered(c) -> void:
	if c != car or not available():
		return
	G.stats["koke_dia"] = int(G.day_n)
	G.side = {"id": "trabajo", "kind": "kokas", "stage": "cliente", "t": START, "t0": START, "cash": 0, "fares": 0}
	_was_muted = G.police.muted
	if G.police.chasing or G.police.heat > 0.0:
		G.police.reset()
	G.police.muted = true                        # (they leave Koke be: he keeps them in grass)
	car.unbreakable = true
	car.repair()
	_knocks = car.knocks
	_out_t = 0.0
	_dwell = 0.0
	_rider = null
	G.hud.show_card(Loc.t("faena_title_kokas"), "")
	G.hud.toast(Loc.t("t_kokas_start") % int(BONUS), 6.0)
	Sfx.jingle([392, 523, 659, 784, 1047], 0.07)
	_fill_waiting()
	run_show()

# ---------------- the run ----------------
func _cls_of(dist: float) -> int:
	return 0 if dist < CLASSES[0][2] else (1 if dist < CLASSES[1][2] else 2)

## neighbours waving, up to WAITING: out walking, grown-ups, 30 to 260 m off
func _fill_waiting() -> void:
	_waiting = _waiting.filter(func(w): return is_instance_valid(w["n"]) and not w["n"].away and w["n"].visible)
	var from: Vector2 = G.in_car.p if G.in_car != null else G.player.p
	var have: Array = _waiting.map(func(w): return w["n"])
	var pool: Array = []
	for o in G.npcs:
		if not is_instance_valid(o) or o.id != "" or o.away or not o.visible or o.voice == "kid" or o.voice == "goat" or o in have:
			continue
		if not (o.state in ["idle", "walk"]):
			continue
		var d: float = (o.p as Vector2).distance_to(from)
		if d > 30.0 and d < 260.0:
			pool.append([d, o])
	pool.sort_custom(func(a, b): return a[0] < b[0])
	var k := 0
	while _waiting.size() < WAITING and k < pool.size():
		var o = pool[k][1]
		k += 1
		var cls: int = randi() % 3
		o.still = true
		o.state = "idle"
		o.home = o.p
		_waiting.append({"n": o, "cls": cls, "ring": _ring(o, CLASSES[cls][0])})

func _ring(o, hex: int) -> MeshInstance3D:
	var t := TorusMesh.new()
	t.inner_radius = 1.05
	t.outer_radius = 1.35
	t.rings = 24
	t.ring_segments = 8
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.emission_enabled = true
	m.emission = Color(hex)
	m.emission_energy_multiplier = 1.4
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mi := MeshInstance3D.new()
	mi.mesh = t
	mi.material_override = m
	mi.scale = Vector3(1.0, 0.25, 1.0)
	G.add_child(mi)
	mi.global_position = MapData.at(o.p, 0.08)
	return mi

func _release(w: Dictionary) -> void:
	if is_instance_valid(w["ring"]):
		w["ring"].queue_free()
	var o = w["n"]
	if is_instance_valid(o) and o != _rider:
		o.still = false

func _nearest_waiting(from: Vector2):
	var best = null
	var bd := 1e9
	for w in _waiting:
		if not is_instance_valid(w["n"]):
			continue
		var d: float = (w["n"].p as Vector2).distance_to(from)
		if d < bd:
			bd = d
			best = w
	return best

func run_tick(dt: float, pp: Vector2) -> void:
	var c = G.in_car
	G.side["t"] = float(G.side["t"]) - dt
	G.trabajos._timer(true)
	if float(G.side["t"]) <= 0.0:
		run_over()
		return
	if c == null:
		_out_t += dt
		if _out_t > OUT_OF_CAR:
			run_over()
		return
	_out_t = 0.0
	for w in _waiting:                               # (the rings stay at their feet)
		if is_instance_valid(w["ring"]) and is_instance_valid(w["n"]):
			w["ring"].global_position = MapData.at(w["n"].p, 0.08)
			w["ring"].rotation.y += dt * 1.5
	var stopped: bool = c.vel.length() < STOP
	_obj_t -= dt
	if G.side["stage"] == "cliente":
		if _waiting.size() < WAITING and _obj_t <= 0.0:
			_fill_waiting()
		var w = _nearest_waiting(c.p)
		if w != null and _stay(stopped and c.p.distance_to(w["n"].p) < 7.0, dt):
			_pick_up(w)
		elif _obj_t <= 0.0:
			_obj_t = 0.5
			run_show()
	else:
		G.side["ft"] = float(G.side["ft"]) - dt
		_passenger_talk(dt, c)
		if _stay(stopped and pp.distance_to(G.side["to"]) < 9.0, dt):
			_drop_off()
		elif float(G.side["ft"]) <= 0.0:
			_jump_out()
		elif _obj_t <= 0.0:
			_obj_t = 0.5
			run_show()

func _stay(inside: bool, dt: float) -> bool:
	_dwell = _dwell + dt if inside else 0.0
	if _dwell >= 0.5:
		_dwell = 0.0
		return true
	return false

func _pick_up(w: Dictionary) -> void:
	var c = G.in_car
	_waiting.erase(w)
	if is_instance_valid(w["ring"]):
		w["ring"].queue_free()
	_rider = w["n"]
	_rider_cls = int(w["cls"])
	_rider.away = true
	_rider.visible = false
	c.seat(_rider.look_data, 1)
	var cl: Array = CLASSES[_rider_cls]
	var to: Vector2 = G.trabajos._drivable_spot(c.p, float(cl[1]), float(cl[2]))
	var dist: float = to.distance_to(c.p)
	var ft: float = dist / 9.0 + 10.0
	G.side["stage"] = "viaje"
	G.side["to"] = to
	G.side["dist"] = dist
	G.side["ft"] = ft
	G.side["ft0"] = ft
	_chat_t = 2.0
	_slow_t = 0.0
	_knocks = c.knocks
	_say(G.trabajos._with_street([Loc.speaker(Loc.t("kokas_to").pick_random(), _fem(_rider))], to)[0], 4.0)
	Sfx.beep(660.0, 0.06, 2, -16.0)
	run_show()

static func _fem(o) -> bool:
	return o != null and String(o.voice).ends_with("_f")

## what they pay: a base by the distance, and a bonus for the time to spare
func fare_pay(dist: float, frac: float) -> Array:
	var base: int = int(round((30.0 + dist * 0.22) / 5.0)) * 5
	var plus: int = int(round(base * clampf(frac, 0.0, 1.0) / 5.0)) * 5
	return [base, plus]

func _drop_off() -> void:
	var frac: float = float(G.side["ft"]) / maxf(1.0, float(G.side["ft0"]))
	var pay: Array = fare_pay(float(G.side["dist"]), frac)
	var rate: String = Loc.t("kokas_rate")[0 if frac > 0.5 else (1 if frac > 0.2 else 2)]
	var fem: bool = _fem(_rider)
	_let_out(true)
	var total: int = int(pay[0]) + int(pay[1])
	G.trabajos._earn("kokas", total)
	G.side["cash"] = int(G.side["cash"]) + total
	G.side["fares"] = int(G.side["fares"]) + 1
	G.side["t"] = float(G.side["t"]) + BONUS
	G.hud.toast(Loc.t("t_kokas_fare") % [rate, G.trabajos._eur(total), G.trabajos._eur(int(pay[0])), G.trabajos._eur(int(pay[1])), int(BONUS)], 4.5)
	_say(Loc.speaker(Loc.t("kokas_thanks").pick_random(), fem), 3.0)
	Sfx.jingle([880, 1175, 1568], 0.06)
	_next()

func _jump_out() -> void:
	var fem: bool = _fem(_rider)
	_let_out(false)
	G.hud.toast(Loc.t("t_kokas_jump"), 4.0)
	_say(Loc.speaker(Loc.t("kokas_angry").pick_random(), fem), 3.0)
	Sfx.beep(196.0, 0.3, 2, -12.0)
	_next()

func _next() -> void:
	G.side["stage"] = "cliente"
	G.side.erase("to")
	_obj_t = 0.0
	_fill_waiting()
	run_show()

## the fare out of the car, on the pavement beside it
func _let_out(paid: bool) -> void:
	if _rider == null or not is_instance_valid(_rider):
		_rider = null
		return
	var c = G.in_car if G.in_car != null else car
	var at: Vector2 = G._free_side(c) if c != null else G.player.p + Vector2(1.2, 0.0)
	if c != null:
		c.seat({}, 1)
	_rider.away = false
	_rider.visible = true
	_rider.p = at
	_rider.home = at
	_rider.still = false
	_rider.state = "idle"
	_rider.sync()
	if not paid:
		_rider.bark(Loc.speaker(Loc.t("kokas_angry").pick_random(), _fem(_rider)), 3.0)
	_rider = null

## what they say on the way: the speed, the knocks, your looks, their lives
func _passenger_talk(dt: float, c) -> void:
	var v: float = c.vel.length()
	_slow_t = _slow_t + dt if v < SLOW else 0.0
	if c.knocks > _knocks:
		_knocks = c.knocks
		if _said_t < 1.0:
			_say(Loc.speaker(Loc.t("kokas_crash").pick_random(), _fem(_rider)), 3.0)
			_chat_t = 4.0
			return
	_chat_t -= dt
	if _chat_t > 0.0 or _said_t > 0.5:
		return
	_chat_t = randf_range(5.0, 7.5)
	var key: String
	if v > FAST and randf() < 0.7:
		key = "kokas_fast"
	elif _slow_t > 3.0 and randf() < 0.7:
		key = "kokas_slow"
	else:
		var r := randf()
		key = "kokas_look" if r < 0.3 else ("kokas_life" if r < 0.75 else "kokas_any")
	_say(Loc.speaker(Loc.t(key).pick_random(), _fem(_rider)), 3.0)

## a line said from the passenger's seat, the way the neighbours mutter (the user, 23 Nov 2026: "Que las frases del
## cliente sean como los murmullos que ya tenemos"): npc.gd bark()'s label, white with its brown outline, over the van
func _say(text: String, dur: float) -> void:
	var c = G.in_car if G.in_car != null else car
	if c == null:
		return
	if _said == null or not is_instance_valid(_said) or _said.get_parent() != c:
		if _said != null and is_instance_valid(_said):
			_said.queue_free()
		_said = Label3D.new()
		_said.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_said.no_depth_test = true
		_said.pixel_size = 0.011
		_said.font_size = 34
		_said.outline_size = 12
		_said.modulate = Color(1, 1, 1)
		_said.outline_modulate = Color(0.29, 0.2, 0.14)
		_said.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_said.width = 420
		_said.position = Vector3(0.0, 2.5, 0.0)        # (where a neighbour's would be over their head: just over the roof)
		c.add_child(_said)
	_said.text = text
	_said.visible = true
	_said_t = dur

func said() -> String:
	return _said.text if _said != null and is_instance_valid(_said) and _said.visible else ""

## the shift is over: the clock at nothing, out of the van for long, or a main mission begun. You may stay at the wheel
## (the user, 23 Nov 2026: "puedes seguir montado en el coche, pero vuelve a ser destructible y la policía volverá a estar
## activa"); once you get out, it is his again until tomorrow (refuses) and goes back to the fleet when nobody sees it.
func run_over() -> void:
	if _rider != null:
		_let_out(false)
	for w in _waiting:
		_release(w)
	_waiting.clear()
	var cash: int = int(G.side.get("cash", 0)) if G.side != null else 0
	var fares: int = int(G.side.get("fares", 0)) if G.side != null else 0
	G.side = null
	G.trabajos._timer(false)
	G.set_target(null, false)
	G.police.muted = _was_muted
	if car != null and is_instance_valid(car):
		car.unbreakable = false
	if fares > 0:
		G.hud.stamp(Loc.t("stamp_done"))
		G.hud.toast(Loc.t("t_kokas_over") % [fares, G.trabajos._eur(cash)], 6.0)
		Sfx.jingle([523, 659, 784, 1047], 0.1)
	else:
		G.hud.toast(Loc.t("t_kokas_none"), 5.0)
	G._show_step()

## the objective and the arrow
func run_show() -> void:
	if not running():
		return
	var cash: String = G.trabajos._eur(int(G.side.get("cash", 0)))
	if G.side["stage"] == "cliente":
		var from: Vector2 = G.in_car.p if G.in_car != null else G.player.p
		var w = _nearest_waiting(from)
		G.hud.set_objective(G._tag(), Loc.t("obj_kokas_cliente") % cash if G.in_car != null else Loc.t("obj_kokas_coche"))
		G.set_target(w["n"].p if w != null else null, false)
	else:
		var ft: float = maxf(0.0, float(G.side["ft"]))
		var line: String = G.trabajos._with_street([Loc.t("obj_kokas_viaje")], G.side["to"])[0]
		G.hud.set_objective(G._tag(), line % ["%d:%02d" % [int(ft) / 60, int(ft) % 60], cash])
		G.set_target(G.side["to"], true)
