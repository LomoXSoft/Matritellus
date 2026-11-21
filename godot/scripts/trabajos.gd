extends RefCounted
## Jobs: paid work you can do over and over (the user, 21 November 2026). The house you inherit costs 210.000 € all
## told (fondo_casa.gd), and nothing else in the game paid more than a few hundred, so: "Quiero meter los tres. De
## momento pon que se puedan activar en un NPC genérico que dé trabajos en la plaza del ayuntamiento, luego ya los
## repartiremos para que los den distintos NPCs. Es más, podemos poner que hablar con Henry cuando no sea jueves te dé
## misiones de reparto a distintos NPCs."
##
##   El de las faenas, a generic man on the Plaza del Ayuntamiento, gives three:
##     reparto   a load picked up somewhere in town and taken by car to a house across it, against the clock: paid
##               200-600 € by how fast and how whole it gets there
##     taxi      a shift: people on the pavement hail you, you stop by them, they get in and say where; five fares,
##               each paid by distance and time (100-500 €); get out of the car for long and the shift is over
##     jornal    a day in the fields outside town: saffron flowers to pick by hand before the time is up, 25 € each
##               (up to 30: 750 €, and a bonus if you pick them all)
##   Henry, any day but Thursday (Thursday is the ham's), sends you with an order to somebody you know: it gets cold,
##   so the quicker the better (30-150 €, and they like you a little better for it).
##
## They take the errand slot (G.side = {id: "trabajo", kind, stage...}): one thing at a time, and a main mission that
## starts drops them (abort). The money earned is kept in G.stats["trabajos"] = {kind: total}.

const GIVER_LOOK := {
	"top": 3, "shirt": 0x6b8e5a, "skin": 0xe0b48c, "hair": 0x5a4636, "hair_style": 0, "brows": 1, "face": 2,
	"hat": "cap", "hat_color": 0x2c3e50, "scale": 1.0, "build": 1.12,
}
const FARES := 5
const FIELD_N := 30
const FIELD_PAY := 25
const FIELD_ALL := 50
const FIELD_TIME := 150.0
const STOP_SPEED := 3.0
const OUT_OF_CAR := 10.0       # seconds out of the car before a taxi shift is over

var G
var giver                       # El de las faenas (npc.gd)
var _dwell := 0.0
var _out_t := 0.0
var _hail = null                # the neighbour waving you down (taxi)
var _rider = null               # ...and once in the car
var _find_t := 0.0
var _beat_t := 0.0

func setup(game) -> void:
	G = game
	giver = G._make_npc("faenas", GIVER_LOOK.duplicate(), "adult_m", _giver_spot())
	giver.still = true
	var pl = G.world.get("plaza")
	if pl != null:
		var to: Vector2 = pl.spot(0.0, 60.0) - giver.p          # (facing out over the square)
		giver.h = atan2(to.x, to.y)
	giver.sync()

func _giver_spot() -> Vector2:
	var pl = G.world.get("plaza")
	if pl != null:
		return pl.spot(6.0, 24.0)
	return MapData.poi("Plaza del Ayuntamiento") + Vector2(4.0, 4.0)

func active() -> bool:
	return G != null and G.side != null and G.side.get("id", "") == "trabajo"

func kind() -> String:
	return String(G.side.get("kind", "")) if active() else ""

func earned(k := "") -> int:
	var d: Dictionary = G.stats.get("trabajos", {})
	if k != "":
		return int(d.get(k, 0))
	var t := 0
	for v in d.values():
		t += int(v)
	return t

func _henry_day() -> bool:
	return int(G.weekday) != 3

func _free() -> bool:
	return G.side == null and not G.in_mission() and G.comida.faint == null

# ---------------- who has something for you ----------------
func givers(free_hands: bool) -> Array:
	var out: Array = []
	if free_hands and giver != null and is_instance_valid(giver) and giver.visible:
		out.append(giver)
	if free_hands and henry_can() and G.named.has("henry"):
		out.append(G.named["henry"])
	if active():
		if kind() == "taxi" and _hail != null and is_instance_valid(_hail):
			out.append(_hail)
		if kind() == "pedido" and G.named.has(String(G.side.get("who", ""))):
			out.append(G.named[String(G.side["who"])])
	return out

# ---------------- talking ----------------
func talk(n) -> bool:
	if n == null:
		return false
	if active() and kind() == "pedido" and n.id == String(G.side.get("who", "")):
		_pedido_done(n)
		return true
	if n.id == "faenas":
		_giver_talk(n)
		return true
	return false

## Henry's counter (game.gd _food_offer) has "Un pedido pa llevar" among its answers when he has one for you
func henry_can() -> bool:
	return _henry_day() and _free() and G.negocio("restaurantes")      # (his counter opens once Josefa has sent you to the restaurants)

func _giver_talk(n) -> void:
	if active():
		G.say(n.shown_name(), Loc.t("faenas_busy_mine"), n.voice)
		return
	if not _free():
		G.say(n.shown_name(), Loc.t("faenas_busy"), n.voice)
		return
	var prev: String = G.phase
	G.say(n.shown_name(), Loc.t("faenas_hello").pick_random(), n.voice, func():
		G.ask(n, n.shown_name(), Loc.t("faenas_q"), [
			[Loc.t("faenas_opt_reparto"), func(): G.phase = prev; _start_reparto(n)],
			[Loc.t("faenas_opt_taxi"), func(): G.phase = prev; _start_taxi(n)],
			[Loc.t("faenas_opt_jornal"), func(): G.phase = prev; _start_jornal(n)],
			[Loc.t("faenas_opt_no"), func(): G.phase = prev],
		]))

func _begin(k: String, extra: Dictionary) -> void:
	G.side = {"id": "trabajo", "kind": k, "stage": "", "t": 0.0}
	G.side.merge(extra, true)
	_dwell = 0.0
	_out_t = 0.0
	G.hud.show_card(Loc.t("faena_title_" + k), "")
	Sfx.jingle([392, 523, 659, 784])
	show()

# ---------------- reparto: a load across town, by car ----------------
func _start_reparto(n) -> void:
	var from := _pickup_spot()
	var to := _house_spot(from, 250.0, 800.0)
	G.say(n.shown_name(), _with_street(Loc.t("faenas_reparto"), from), n.voice)
	_begin("reparto", {"stage": "carga", "from": from, "to": to, "dist": from.distance_to(to)})

func _pickup_spot() -> Vector2:
	var pp: Vector2 = G.player.p
	var keys: Array = ["coop", "kiosk", "kebab", "henry", "vip", "tanatorio"].filter(func(k): return G.places.has(k))
	keys.shuffle()
	for k in keys:
		var p: Vector2 = G.places[k]["p"]
		if p.distance_to(pp) > 120.0:
			return p
	return G.places[keys[0]]["p"] if not keys.is_empty() else pp + Vector2(150.0, 0.0)

## a pavement before a house front between `rmin` and `rmax` from `from`
func _house_spot(from: Vector2, rmin: float, rmax: float) -> Vector2:
	var cands: Array = []
	for hd in MapData.houses:
		var o := Vector2(hd["o"][0], hd["o"][1])
		var d := o.distance_to(from)
		if d > rmin and d < rmax and float(hd.get("len", 0.0)) > 5.0:
			cands.append(hd)
	if cands.is_empty():
		var node = MapData.random_node_near(from, rmin, rmax)
		return G._pavement(node if node != null else from + Vector2(rmin, 0.0))
	var hd: Dictionary = cands.pick_random()
	var o := Vector2(hd["o"][0], hd["o"][1])
	var u := Vector2(hd["u"][0], hd["u"][1]).normalized()
	return G._pavement(o + u * float(hd["len"]) * 0.5)

# ---------------- taxi: a shift of fares ----------------
func _start_taxi(n) -> void:
	G.say(n.shown_name(), Loc.t("faenas_taxi"), n.voice)
	_begin("taxi", {"stage": "buscar", "fares": 0, "cash": 0})

func _find_fare() -> void:
	var c = G.in_car
	if c == null:
		return
	var best = null
	var bd := 1e9
	for n in G.npcs:
		if not is_instance_valid(n) or n.id != "" or n.away or not n.visible or not (n.state in ["idle", "walk"]):
			continue
		var d: float = (n.p as Vector2).distance_to(c.p)
		if d > 40.0 and d < 150.0 and d < bd:
			best = n
			bd = d
	if best == null:
		return
	_hail = best
	_hail.still = true
	_hail.state = "idle"
	_hail.home = _hail.p
	_hail.bark(Loc.t("taxi_hail").pick_random(), 4.0)
	show()

func _pick_up() -> void:
	var c = G.in_car
	_rider = _hail
	_hail = null
	_rider.away = true
	_rider.visible = false
	c.seat(_rider.look_data, 1)
	var node = MapData.random_node_near(c.p, 250.0, 700.0)
	var to: Vector2 = G._pavement(node if node != null else c.p + Vector2(300.0, 0.0))
	var dist := to.distance_to(c.p)
	var t0 := dist / 8.0 + 35.0
	G.side["stage"] = "llevar"
	G.side["to"] = to
	G.side["dist"] = dist
	G.side["t"] = t0
	G.side["t0"] = t0
	G.hud.toast(_with_street([Loc.t("taxi_to").pick_random()], to)[0], 5.0)
	Sfx.beep(660.0, 0.06, 2, -16.0)
	_dwell = 0.0
	show()

func _drop_rider(paid: bool) -> void:
	if _rider == null or not is_instance_valid(_rider):
		_rider = null
		return
	var c = G.in_car
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
	_rider.bark(Loc.t("taxi_thanks" if paid else "taxi_angry").pick_random(), 3.5)
	_rider = null

# ---------------- jornal: a day in the fields ----------------
func _start_jornal(n) -> void:
	var f := _field()
	G.say(n.shown_name(), Loc.t("faenas_jornal"), n.voice)
	_begin("jornal", {"stage": "ir", "to": f[0], "poly": f[1], "got": 0})

## [its middle, its outline]: the vineyards and furrowed land outside town (MapData.areas k 2 and 4), the nearest
## big one
func _field() -> Array:
	var pp: Vector2 = G.player.p
	var best: Array = []
	var bd := 1e12
	for a in MapData.areas:
		if not (int(a["k"]) in [2, 4]):
			continue
		var pts: Array = a["p"]
		var poly := PackedVector2Array()
		for i in range(0, pts.size() - 1, 2):
			poly.append(Vector2(pts[i], pts[i + 1]))
		if poly.size() < 3:
			continue
		var c := Vector2.ZERO
		for q in poly:
			c += q
		c /= poly.size()
		if not Geometry2D.is_point_in_polygon(c, poly):
			continue
		var r := Rect2(poly[0], Vector2.ZERO)
		for q in poly:
			r = r.expand(q)
		if r.size.x < 40.0 or r.size.y < 40.0:
			continue
		var d := c.distance_to(pp)
		if d < bd:
			bd = d
			best = [c, poly]
	if best.is_empty():
		return [pp + Vector2(0.0, 400.0), PackedVector2Array()]
	return best

func _sow() -> void:
	var c: Vector2 = G.side["to"]
	var poly: PackedVector2Array = G.side["poly"]
	var made := 0
	var tries := 0
	while made < FIELD_N and tries < 600:
		tries += 1
		var q := c + Vector2(randf_range(-26.0, 26.0), randf_range(-26.0, 26.0))
		if not poly.is_empty() and not Geometry2D.is_point_in_polygon(q, poly):
			continue
		G.pickups.spawn("azafran", q, {"tag": "jornal_%d" % made, "label": "", "on_take": _picked})
		made += 1
	G.side["tot"] = made

func _picked() -> void:
	if active() and kind() == "jornal":
		G.side["got"] = int(G.side.get("got", 0)) + 1
		G.hud.toast(Loc.t("t_jornal_rosa") % [int(G.side["got"]), int(G.side.get("tot", FIELD_N))], 1.6)
		if int(G.side["got"]) >= int(G.side.get("tot", FIELD_N)):
			_jornal_end()

func _jornal_end() -> void:
	var got: int = int(G.side.get("got", 0))
	var all: bool = got >= int(G.side.get("tot", FIELD_N))
	for i in range(int(G.side.get("tot", FIELD_N))):
		G.pickups.remove_tag("jornal_%d" % i)
	var pay: int = got * FIELD_PAY + (FIELD_ALL if all else 0)
	if got <= 0:
		_fail("faena_fail_jornal")
		return
	_paid(pay, Loc.t("faena_done_jornal") % [got, int(G.side.get("tot", FIELD_N))])

# ---------------- Henry's orders ----------------
func henry_offer(n) -> void:
	var who = _order_for(n)
	if who == null:
		G.say(n.shown_name(), Loc.t("henry_pedido_none"), n.voice)
		return
	var prev: String = G.phase
	var lines: Array = (Loc.t("henry_pedido") as Array).map(func(l): return String(l).replace("{quien}", who.shown_name()))
	G.say(n.shown_name(), lines, n.voice, func():
		G.ask(n, n.shown_name(), Loc.t("henry_pedido_q") % who.shown_name(), [
			[Loc.t("henry_pedido_yes"), func():
				G.phase = prev
				var dist: float = (who.p as Vector2).distance_to(n.p)
				var t0 := dist / 5.0 + 60.0
				_begin("pedido", {"stage": "pedido", "who": who.id, "dist": dist, "t": t0, "t0": t0})],
			[Loc.t("henry_pedido_no"), func():
				G.phase = prev
				G.say(n.shown_name(), Loc.t("henry_pedido_later"), n.voice)],
		]))

## somebody you know, out in town, a fair way off
func _order_for(henry):
	var cands: Array = []
	var ids: Array = G.folk.ids().duplicate()
	if ids.size() < 3:                           # (early on you know hardly anybody: anyone in town, then)
		ids = G.named.keys()
	for id in ids:
		if id in ["henry", "goat", "faenas", "edmundo", "chino"] or not G.named.has(id):
			continue
		var n = G.named[id]
		if not is_instance_valid(n) or n.away or not n.visible:
			continue
		var p: Vector2 = n.p
		if p.x < MapData.xmin or p.x > MapData.xmax or p.y < MapData.zmin or p.y > MapData.zmax:
			continue                                 # (in a set apart: inside a shop)
		if p.distance_to(henry.p) > 60.0:
			cands.append(n)
	return cands.pick_random() if not cands.is_empty() else null

func _pedido_done(n) -> void:
	var frac: float = clampf(float(G.side.get("t", 0.0)) / maxf(1.0, float(G.side.get("t0", 1.0))), 0.0, 1.0)
	var pay: int = clampi(int(round((40.0 + float(G.side.get("dist", 0.0)) * 0.12) * (0.6 + 0.4 * frac) / 5.0)) * 5, 30, 150)
	G.folk.add(n.id, 2)
	G.say(n.shown_name(), Loc.speaker(Loc.t("pedido_gracias").pick_random(), n.voice.ends_with("_f")), n.voice)
	_paid(pay, Loc.t("faena_done_pedido") % n.shown_name())

# ---------------- every tick ----------------
func tick(dt: float, pp: Vector2) -> void:
	if not active():
		_timer(false)
		return
	var c = G.in_car
	var stopped: bool = c != null and c.vel.length() < STOP_SPEED
	match kind():
		"reparto":
			if G.side["stage"] == "carga":
				if _stay(c != null and stopped and pp.distance_to(G.side["from"]) < 8.0, dt):
					var t0: float = float(G.side["dist"]) / 8.0 + 40.0
					G.side["stage"] = "entrega"
					G.side["t"] = t0
					G.side["t0"] = t0
					G.side["hp0"] = float(c.hp)
					G.hud.toast(Loc.t("t_reparto_loaded"), 4.0)
					Sfx.beep(523.0, 0.08, 2, -14.0)
					show()
				elif c == null and pp.distance_to(G.side["from"]) < 8.0:
					_onfoot()
			else:
				G.side["t"] = float(G.side["t"]) - dt
				_timer(true)
				if _stay(c != null and stopped and pp.distance_to(G.side["to"]) < 8.0, dt):
					var frac: float = clampf(float(G.side["t"]) / float(G.side["t0"]), 0.0, 1.0)
					var whole: float = clampf(float(c.hp) / maxf(1.0, float(G.side.get("hp0", c.hp))), 0.0, 1.0)
					var pay: int = clampi(int(round((200.0 + float(G.side["dist"]) * 0.3) * (0.55 + 0.45 * frac) * (0.5 + 0.5 * whole) / 10.0)) * 10, 100, 600)
					_paid(pay, Loc.t("faena_done_reparto"))
				elif c == null and pp.distance_to(G.side["to"]) < 8.0:
					_onfoot()
				elif float(G.side["t"]) <= 0.0:
					_fail("faena_fail_reparto")
		"taxi":
			if c == null:
				_out_t += dt
				if _out_t > OUT_OF_CAR:
					_taxi_over()
				return
			_out_t = 0.0
			if G.side["stage"] == "buscar":
				if _hail == null or not is_instance_valid(_hail) or _hail.away:
					_hail = null
					_find_t -= dt
					if _find_t <= 0.0:
						_find_t = 2.0
						_find_fare()
				elif c.p.distance_to(_hail.p) > 220.0:
					_hail.still = false
					_hail = null
				else:
					_beat_t -= dt
					if _beat_t <= 0.0:
						_beat_t = 6.0
						_hail.bark(Loc.t("taxi_hail").pick_random(), 3.0)
					if _stay(stopped and c.p.distance_to(_hail.p) < 6.0, dt):
						_pick_up()
			else:
				G.side["t"] = float(G.side["t"]) - dt
				_timer(true)
				if _stay(stopped and pp.distance_to(G.side["to"]) < 8.0, dt):
					var frac: float = clampf(float(G.side["t"]) / float(G.side["t0"]), 0.0, 1.0)
					var pay: int = clampi(int(round((150.0 + float(G.side["dist"]) * 0.3) * (0.6 + 0.4 * frac) / 10.0)) * 10, 100, 500)
					_fare_paid(pay)
				elif float(G.side["t"]) <= 0.0:
					_drop_rider(false)
					G.hud.toast(Loc.t("t_taxi_lost"), 4.0)
					Sfx.beep(196.0, 0.3, 2, -12.0)
					_next_fare()
		"jornal":
			if G.side["stage"] == "ir":
				if pp.distance_to(G.side["to"]) < 28.0:
					G.side["stage"] = "coger"
					G.side["t"] = FIELD_TIME
					G.side["t0"] = FIELD_TIME
					_sow()
					G.hud.toast(Loc.t("t_jornal_go") % [FIELD_N, int(FIELD_TIME)], 5.0)
					show()
			else:
				G.side["t"] = float(G.side["t"]) - dt
				_timer(true)
				if float(G.side["t"]) <= 0.0:
					_jornal_end()
		"pedido":
			G.side["t"] = float(G.side["t"]) - dt
			_timer(true)
			var who = G.named.get(String(G.side["who"]))
			if who != null and c == null and _stay(pp.distance_to(who.p) < 2.6, dt):
				_pedido_done(who)
			elif float(G.side["t"]) <= 0.0:
				_fail("faena_fail_pedido")
			else:
				_beat_t -= dt
				if _beat_t <= 0.0 and who != null:
					_beat_t = 0.5
					G.set_target(who.p, false)          # (they walk about: the arrow follows them)

func _stay(inside: bool, dt: float) -> bool:
	_dwell = _dwell + dt if inside else 0.0
	if _dwell >= 1.2:
		_dwell = 0.0
		return true
	return false

var _onfoot_t := -10.0
func _onfoot() -> void:
	if Time.get_ticks_msec() / 1000.0 - _onfoot_t > 6.0:
		_onfoot_t = Time.get_ticks_msec() / 1000.0
		G.hud.toast(Loc.t("t_faena_car"), 3.0)

func _fare_paid(pay: int) -> void:
	_drop_rider(true)
	_earn("taxi", pay)
	G.side["cash"] = int(G.side.get("cash", 0)) + pay
	G.side["fares"] = int(G.side.get("fares", 0)) + 1
	G.hud.toast(Loc.t("t_taxi_fare") % [_eur(pay), int(G.side["fares"]), FARES], 4.0)
	Sfx.jingle([880, 1175], 0.06)
	_next_fare()

func _next_fare() -> void:
	if int(G.side.get("fares", 0)) >= FARES:
		_taxi_over()
		return
	G.side["stage"] = "buscar"
	_find_t = 1.5
	_timer(false)
	show()

func _taxi_over() -> void:
	if _rider != null:
		_drop_rider(false)
	if _hail != null and is_instance_valid(_hail):
		_hail.still = false
	_hail = null
	var cash: int = int(G.side.get("cash", 0))
	var fares: int = int(G.side.get("fares", 0))
	G.side = null
	_timer(false)
	G.set_target(null, false)
	if fares > 0:
		G.hud.stamp(Loc.t("stamp_done"))
		G.hud.toast(Loc.t("t_taxi_over") % [fares, _eur(cash)], 5.0)
		Sfx.jingle([523, 659, 784, 1047], 0.1)
	else:
		G.hud.toast(Loc.t("t_taxi_none"), 4.0)
	G._show_step()

# ---------------- the end of a job ----------------
func _earn(k: String, pay: int) -> void:
	var d: Dictionary = G.stats.get("trabajos", {})
	d[k] = int(d.get(k, 0)) + pay
	G.stats["trabajos"] = d
	G.money += pay
	G._refresh_counts()

func _paid(pay: int, what: String) -> void:
	_earn(kind(), pay)
	G.side = null
	_timer(false)
	G.set_target(null, false)
	G.hud.stamp(Loc.t("stamp_done"))
	G.hud.toast(Loc.t("t_faena_paid") % [what, _eur(pay)], 5.0)
	Sfx.jingle([523, 659, 784, 1047], 0.12)
	G._show_step()

func _fail(key: String) -> void:
	G.side = null
	_timer(false)
	G.set_target(null, false)
	G.hud.toast(Loc.t(key), 5.0)
	Sfx.beep(196.0, 0.5, 3, -10.0, -80.0)
	G._show_step()

## a main mission begins: the job is dropped
func abort() -> void:
	if not active():
		return
	if kind() == "taxi":
		_taxi_over()
		return
	if kind() == "jornal":
		for i in range(int(G.side.get("tot", FIELD_N))):
			G.pickups.remove_tag("jornal_%d" % i)
	G.side = null
	_timer(false)
	G.hud.toast(Loc.t("t_faena_dropped"), 4.0)

## what the job wants of you right now: objective and GPS
func show() -> void:
	if not active():
		return
	var st: String = G.side["stage"]
	match kind():
		"reparto":
			if st == "carga":
				G.hud.set_objective(G._tag(), Loc.t("obj_reparto_carga"))
				G.set_target(G.side["from"], true)
			else:
				G.hud.set_objective(G._tag(), _with_street([Loc.t("obj_reparto_entrega")], G.side["to"])[0])
				G.set_target(G.side["to"], true)
		"taxi":
			if st == "buscar":
				G.hud.set_objective(G._tag(), Loc.t("obj_taxi_buscar") % [int(G.side.get("fares", 0)), FARES] if G.in_car != null else Loc.t("obj_taxi_coche"))
				G.set_target(_hail.p if _hail != null and is_instance_valid(_hail) else null, false)
			else:
				G.hud.set_objective(G._tag(), _with_street([Loc.t("obj_taxi_llevar")], G.side["to"])[0])
				G.set_target(G.side["to"], true)
		"jornal":
			if st == "ir":
				G.hud.set_objective(G._tag(), Loc.t("obj_jornal_ir"))
				G.set_target(G.side["to"], true)
			else:
				G.hud.set_objective(G._tag(), Loc.t("obj_jornal_coger") % FIELD_N)
				G.set_target(null, false)
		"pedido":
			var who = G.named.get(String(G.side["who"]))
			G.hud.set_objective(G._tag(), Loc.t("obj_pedido") % (who.shown_name() if who != null else "?"))
			G.set_target(who.p if who != null else null, false)

func _timer(on: bool) -> void:
	if not on:
		if active() and kind() in ["reparto", "taxi", "jornal", "pedido"] and G.side["stage"] in ["entrega", "llevar", "coger", "pedido"]:
			return
		if G.hud.timer_slot.visible and not _timer_owner_other():
			G.hud.timer_slot.visible = false
		return
	var t: float = maxf(0.0, float(G.side["t"]))
	G.hud.timer_slot.visible = true
	G.hud.set_bottles(0)
	G.hud.timer_label.text = "%d:%02d" % [int(t) / 60, int(t) % 60]
	G.hud.timer_label.add_theme_color_override("font_color", Color("ff7b5c") if t < 20.0 else G.hud.CREAM)

## somebody else's countdown on screen (the story's delivery, the riot): leave it be
func _timer_owner_other() -> bool:
	return G.in_mission() and G.steps[G.si].get("type", "") == "deliver" or G.motin.busy()

## lines with {calle} put in: the street nearest `p`
func _with_street(lines: Array, p: Vector2) -> Array:
	var r: Dictionary = MapData.nearest_road(p)
	var street: String = String(r["seg"].road.get("n", ""))
	if street == "":
		street = Loc.t("chiki_somewhere")
	return lines.map(func(l): return String(l).replace("{calle}", street))

static func _eur(v: int) -> String:
	var s := str(absi(v))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if v < 0 else "") + s + out + " €"
