extends Node
## "Un torneo en los Galaxy Recress": the second mission of the Civismo line, Alberto's (the user's design, 13 November
## 2026; guion/recress.md has it in their words). After the bridge, Alberto has an idea for putting some life into the
## town: a Tokken 9 tournament in the old amusement arcade, shut these twenty years.
##
##   0  After the bridge, talk to Alberto (or, twelve hours on, he rings you and asks you to come by). He asks how the
##      civic things are going; the town is half dead outside the fiestas (a fly-over of the sad corners of it); then
##      the idea comes to him -- a star over his head -- the Galaxy Recress! A Tokken 9 tournament.
##   1  The mayor, at the town hall door: a lot of words saying nothing, and no money. Unless you put it up (you get it
##      back twice over at the end). Without it he waits for you there, and the rest of the town is yours meanwhile.
##   2  The girl at the copy shop has the posters ready: five, for five shops. Any shop front will do.
##   3  The last one up, Alberto rings: the Recress is packed. The tournament, the final (the mayor wins it), his
##      challenge, double or nothing; you play him (the Tokken 9 game itself is still to be made: you sit down, press
##      the button and win), and win. That night, outside, his wife. The Recress is open from then on.
##
## Its progress is kept in stats["recress"] = {stage, posters: [spot ids], ...}, so it is in the saved game.

const Sala = preload("res://scripts/recress_sala.gd")
const CasasS = preload("res://scripts/casas.gd")
const TITLE := "rec_title"
const COST := 100                # what the mayor wants from you (the user's figure, 14 November 2026: 100 € in, 200 € back)
const PRIZE := 1                 # the tournament's prize gives it back to you...
const BET := 2                   # ...and beating him at double or nothing doubles it
const POSTERS := 5
const CALL_AFTER_H := 12.0       # game hours after the bridge until Alberto rings, if you have not been to see him
const COPY_SHOP := Vector2(-112.3, 111.2)        # Calle Teniente Infante (Catastro 4190004VJ5649S): its glass door (Street View 2024; the girl stands inside when the shop is a set: bancosancho.gd)
const POSTER_REACH := 2.4
## the people who only come out for the tournament (and the photos of the family tree: selftest --portraits)
const LOOKS := {
	"katakumba": {"top": 0, "shirt": 0x1b1b1f, "hair": 0x2a1c14, "hair_style": 3, "face": 5, "glasses": 2, "hat": "cap", "hat_color": 0x111111, "build": 1.2, "scale": 1.04},
	"comentarista": {"top": 1, "shirt": 0xf2f2f2, "hair": 0x5a3a22, "hair_style": 8, "face": 3, "scale": 0.98},
	"madre_alcalde": {"top": 7, "shirt": 0x6a3d7a, "hair": 0x9a9aa0, "hair_style": 1, "glasses": 1, "earrings": 5, "pendant": 3, "scale": 0.86},
	"alcaldesa": {"top": 2, "shirt": 0x7a1f3d, "hair": 0x3b2416, "hair_style": 9, "earrings": 6, "pendant": 4, "scale": 0.95},
}

var G
var sala                         # recress_sala.gd: the front on the street, and the hall
var st: Dictionary = {}          # stats["recress"]
var shops: Array = []            # {id, name, stand (where you stand), at (on the wall), n (out of the wall), y}
var crowd: Array = []            # the neighbours brought along for the tournament
var cine := false
var _beats: Array = []
var _beat := -1
var _beat_t := 0.0
var _pan = null                  # [from0, at0, from1, at1, seconds, t, fov]
var _walkers: Array = []         # [npc, to, speed, then]
var _taunts := 0
var _offered := false            # (Alberto's call has been made)
var _shop_posters: Array = []    # the posters you have put up (MeshInstance3D)
var _star: Sprite3D
var _star_t := 0.0
var _music := ""                 # (game.gd _update_audio plays this instead, while it is set)
var _music_db := -14.0
var _remind_t := 0.0
var _poster_t := 0.0
var _poster_shop_id := ""

func setup(game) -> void:
	G = game
	sala = Sala.new()
	G.add_child(sala)
	sala.setup(G)
	_make_people()
	_find_shops()
	_star = Sprite3D.new()
	_star.texture = load("res://assets/recress/eureka.png")
	_star.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_star.no_depth_test = true
	_star.pixel_size = 0.0055
	_star.visible = false
	G.add_child(_star)

## (the saved game has been read, or a new one begun)
func load_state() -> void:
	if not G.stats.has("recress"):
		G.stats["recress"] = {"stage": "", "posters": []}
	st = G.stats["recress"]
	if st["stage"] in ["llamada", "torneo", "reto", "final"]:
		st["stage"] = "llamada"                  # (a tournament half seen starts again from Alberto's call)
		_offered = false
	sala.set_state(("abierto" if open_hours(G.clock) else "cerrado") if st["stage"] == "hecho" else "viejo")     # (before the tournament, as it was)
	sala.show_posters(st["stage"] == "hecho")
	if st["stage"] == "hecho":
		_open_hall()
	else:
		_close_hall()
	for q in _shop_posters:
		q.queue_free()
	_shop_posters.clear()
	for id in st.get("posters", []):
		var s = _shop(String(id))
		if s != null:
			_shop_posters.append(sala.poster_at(s["at"], s["n"], s["y"]))
	if st["stage"] in ["alcalde", "copisteria", "carteles", "llamada"]:
		G.side = {"id": "recress", "who": "alberto", "stage": st["stage"]}

func stage() -> String:
	return String(st.get("stage", ""))

func done() -> bool:
	return stage() == "hecho"

func active() -> bool:
	return G.side != null and G.side.get("id", "") == "recress"

## the line opens with the bridge: is the mission there to be had (and not yet taken)?
func available() -> bool:
	return G.stats.has("puente") and stage() in ["", "rechazada"]

func _to(to: String) -> void:
	st["stage"] = to
	if G.side != null and G.side.get("id", "") == "recress":
		G.side["stage"] = to

# ---------------- people ----------------
## the mayor at the town hall door and the girl at the copy shop's: there all the time (stand-ins, until they have a
## look and a name of their own)
func _make_people() -> void:
	var th: Dictionary = MapData.townhall
	var m := Vector2(th["m"][0], th["m"][1])
	var tu := Vector2(th["u"][0], th["u"][1])
	var plaza := MapData.poi("Plaza del Ayuntamiento")
	var n := Vector2(-tu.y, tu.x)
	if (plaza - m).dot(n) < 0.0:
		n = -n
	var mayor = G._make_npc("alcalde", {"top": 1, "shirt": 0x2c3e50, "hair": 0xb8b8bc, "face": 1, "brows": 1, "glasses": 1, "scale": 1.0, "build": 1.1},
		"adult_m", m + n * 2.2)
	mayor.still = true
	mayor.h = atan2(n.x, n.y)
	mayor.home = mayor.p
	mayor.sync()
	var shop = _copy_shop()
	var stand: Vector2
	var face: float
	if shop != null:                                 # behind the copy shop's counter, in its set (the user, 17 Nov 2026: "metes a la chica dentro")
		stand = shop.keeper_spot
		face = shop.keeper_face
	else:                                            # (no set: at its door, on the pavement)
		var r: Dictionary = MapData.nearest_road(COPY_SHOP)
		var to_shop: Vector2 = (COPY_SHOP - (r["p"] as Vector2)).normalized()
		stand = (r["p"] as Vector2) + to_shop * minf(float(r["seg"].hw) + 1.0, maxf(1.0, MapData.side_room(r) - 0.6))
		face = atan2(-to_shop.x, -to_shop.y)
	var girl = G._make_npc("copista", {"top": 0, "shirt": 0x8e44ad, "hair": 0x2a1c14, "hair_style": 2, "earrings": 1, "glasses": 2, "scale": 0.94},
		"adult_f", stand)
	girl.still = true
	girl.h = face
	girl.home = girl.p
	girl.sync()

## the copy shop you go into (bancosancho.gd's set), or null on a map without it
func _copy_shop():
	var bs = G.world.get("bancosancho") if G.world != null else null
	return bs.tienda if bs != null and bs.get("tienda") != null else null

## who has a mission for you here (marcas.gd): Alberto with the idea, the mayor waiting for the money
func givers(free_hands: bool) -> Array:
	var out: Array = []
	if available() and free_hands and G.named.has("alberto"):
		out.append(G.named["alberto"])
	if stage() == "dinero" and free_hands:
		out.append(G.named["alcalde"])
	if stage() == "reto" and _inside_people.get("alcalde") != null:       # waiting for you at the machine (the user, 17 Nov 2026)
		out.append(_inside_people["alcalde"])
	return out

# ---------------- the shops the posters can go on ----------------
## Any shop will do: the town's shops on the map (supermarkets, the chemist's, the bookshops, the bars...), the
## businesses of the game, and the shop fronts of the houses built from photos. For each: a bit of wall beside it.
func _find_shops() -> void:
	var kinds := ["supermarket", "pharmacy", "books", "hairdresser", "pub", "restaurant", "biergarten", "car_repair"]
	for p in MapData.pois:
		if String(p.get("t", "")) in kinds:
			var at := Vector2(float(p["x"]), float(p["z"]))
			if at.distance_to(G.limite.CENTRE) < G.limite.RADIUS - 100.0:
				_add_shop("poi_" + String(p["n"]).to_lower().replace(" ", "_"), at)
	for key in ["vip", "henry", "kebab", "kiosk"]:
		if G.places.has(key):
			_add_shop(key, G.places[key]["p"])
	for h in MapData.houses:                      # the shop fronts built by hand: those with a board over them
		var spec = _spec_of(String(h["id"]))
		if spec != null and spec.has("floors") and not spec["floors"].is_empty() and spec["floors"][0].has("signs") and String(h["id"]) != Sala.HOUSE:
			var o := Vector2(h["o"][0], h["o"][1])
			var u := Vector2(h["u"][0], h["u"][1])
			var sg: Array = spec["floors"][0]["signs"][0]
			_add_wall_shop("casa_" + String(h["id"]), o + u * float(h["len"]) * (float(sg[0]) + float(sg[1])) / 2.0, Vector2(-u.y, u.x))

## the description casas.gd builds a house from (null for the ones it builds otherwise)
func _spec_of(id: String):
	if CasasS.SPECS.has(id):
		return CasasS.SPECS[id]
	if CasasS.Short.HOUSES.has(id):
		return CasasS._unpack(CasasS.Short.HOUSES[id])
	return null

## a shop near `p`: the poster goes on the nearest bit of wall that faces a street
func _add_shop(id: String, p: Vector2) -> void:
	var best := 1e9
	var best_at := Vector2.ZERO
	var best_n := Vector2.ZERO
	for w in MapData.walls:
		for i in range(w.size() / 7):
			var k := i * 7
			var a := Vector2(w[k], w[k + 1])
			var b := Vector2(w[k + 2], w[k + 3])
			if a.distance_squared_to(p) > 900.0 and b.distance_squared_to(p) > 900.0:
				continue
			var q := Geometry2D.get_closest_point_to_segment(p, a, b)
			var d := q.distance_to(p)
			if d < best and a.distance_to(b) > 2.0:
				var n := Vector2(b.y - a.y, -(b.x - a.x)).normalized()
				if MapData.road_edge_dist(q + n * 2.5) < 3.0:
					best = d
					best_at = q
					best_n = n
	if best < 25.0:
		_add_wall_shop(id, best_at, best_n)

func _add_wall_shop(id: String, at: Vector2, n: Vector2) -> void:
	for s in shops:
		if (s["at"] as Vector2).distance_to(at) < 6.0:
			return                                # (one poster to a shop front)
	shops.append({"id": id, "at": at, "n": n, "stand": at + n * 1.0, "y": MapData.height(at + n * 0.5) + 1.45})

func _shop(id: String):
	for s in shops:
		if s["id"] == id:
			return s
	return null

## the nearest shop without a poster of ours yet, within reach of where you stand (or null)
func shop_near(p: Vector2):
	if stage() != "carteles" or int(st.get("carteles", 0)) <= 0:
		return null
	for s in shops:
		if not (s["id"] in st["posters"]) and (s["stand"] as Vector2).distance_to(p) < POSTER_REACH:
			return s
	return null

func _nearest_free_shop(p: Vector2):
	var best = null
	var bd := 1e12
	for s in shops:
		if s["id"] in st["posters"]:
			continue
		var d: float = (s["stand"] as Vector2).distance_squared_to(p)
		if d < bd:
			bd = d
			best = s
	return best

## E at a shop front: up goes a poster
func stick(s: Dictionary) -> void:
	st["posters"].append(s["id"])
	st["carteles"] = int(st.get("carteles", 0)) - 1
	_shop_posters.append(sala.poster_at(s["at"], s["n"], s["y"]))
	G.player.punch = 0.28
	Sfx.noise(0.12, -16.0)
	Sfx.beep(1600.0, 0.05, 1, -18.0)
	var n: int = st["posters"].size()
	G.hud.toast(Loc.t("t_rec_poster") % [n, POSTERS], 2.5)
	if n >= POSTERS:
		_to("llamada")
		_offered = false
		G.hud.toast(Loc.t("t_rec_posters_done"), 4.0)
	show()

# ---------------- talking ----------------
## You talk to somebody. True if this mission had something to say to them.
func talk(n) -> bool:
	match n.id:
		"alberto":
			if available() and G.side == null and not G.in_mission() and G.comida.faint == null:
				_pitch(n, stage() == "rechazada")
				return true
			if active():
				G.say(n.shown_name(), Loc.t("alberto_rec_busy"), n.voice)
				return true
		"alcalde":
			if stage() in ["alcalde", "dinero"]:
				_mayor(n)
				return true
			if stage() in ["copisteria", "carteles", "llamada"]:
				G.say(n.shown_name(), Loc.t("alcalde_rec_wait"), n.voice)
				return true
			if done():
				G.say(n.shown_name(), Loc.t("alcalde_after"), n.voice)
				return true
		"copista":
			if stage() == "copisteria":
				G.say(n.shown_name(), Loc.t("copista_rec"), n.voice, _got_posters)
				return true
			if stage() == "carteles":
				G.say(n.shown_name(), Loc.t("copista_rec_again"), n.voice)
				return true
		"katakumba":                             # at full trust he tells you his real name (the user's joke, 13 November 2026); in the hall, ask to play him
			if G.folk.golden("katakumba") and not G.stats.has("nachin"):
				G.stats["nachin"] = true
				G.say(n.shown_name(), Loc.t("katakumba_nachin"), n.voice)
				return true
			if done() and G.indoors and G.inside_of == sala:
				var prev_phase: String = G.phase
				G.ask(n, n.shown_name(), Loc.t("kata_ask").pick_random(), [
					[Loc.t("kata_opt_play"), func(): G.phase = prev_phase; play_katakumba()],
					[Loc.t("kata_opt_chat"), func(): G.phase = prev_phase; G.talk_to(n, true)],
					[Loc.t("kata_opt_bye"), func(): G.phase = prev_phase],
				])
				return true
	return false

## Alberto's idea (the scene), and the question
func _pitch(n, again: bool) -> void:
	if again:                                    # you said no before: only the question this time
		G.say(n.shown_name(), [Loc.t("offer_again").pick_random()], n.voice, _ask.bind(n))
		return
	_begin_scene()
	var a = n
	var you: Vector2 = G.player.p
	var face: Vector2 = (a.p - you).normalized()
	G.player.h = atan2(face.x, face.y)
	a.h = G.player.h + PI
	G.player.sync()
	a.sync()
	var two := _two_shot(G.player, a)
	_beats = [
		["say", a, Loc.t("alberto_rec_1"), two[0], two[1], 42.0],
	]
	# the sad corners of the town, while he goes on
	var tour: Array = _sad_corners()
	var lines: Array = Loc.t("alberto_rec_tour")
	for i in range(tour.size()):
		var c: Array = tour[i]
		_beats.append(["pan", 0.1, c[0], c[1], c[2], c[3], 5.0, 50.0])
		_beats.append(["say", a, [lines[i % lines.size()]], null, null, 50.0])
	_beats.append(["cut", 0.4, two[0], two[1], 42.0])
	_beats.append(["star", 1.6, a])
	var door: Vector2 = sala.shutter(0.0)
	var look := Vector3(door.x, sala.base + 2.6, door.y)
	var road: Dictionary = MapData.nearest_road(door)            # (down the middle of the street: no tree, no wall in the way)
	var along: Vector2 = (road["u"] as Vector2) * (1.0 if (road["u"] as Vector2).dot(sala.u) >= 0.0 else -1.0)
	var mid: Vector2 = road["p"]
	var door_shot: Array = G.scene_shot(look, MapData.at(mid + along * 13.0, 4.6), MapData.at(mid + along * 5.0 + (door - mid) * 0.2, 2.2))
	var from0: Vector3 = door_shot[0]
	var from1: Vector3 = door_shot[1]
	_beats.append(["say", a, Loc.t("alberto_rec_idea"), two[0], two[1], 42.0])
	_beats.append(["pan", 0.1, from0, look, from1, look, 6.0, 46.0])
	_beats.append(["say", a, Loc.t("alberto_rec_recress"), null, null, 46.0])
	_beats.append(["cut", 0.3, two[0], two[1], 42.0])
	_beats.append(["say", a, Loc.t("alberto_rec_tokken"), two[0], two[1], 42.0])
	_beats.append(["do", 0.0, func():
		_end_scene()
		_ask(a)])
	_run()

func _ask(n) -> void:
	G._offer(n, Loc.t(TITLE), _accepted, false, "step", func(): _to("rechazada"))

func _accepted() -> void:
	G.side = {"id": "recress", "who": "alberto", "stage": "alcalde"}
	_to("alcalde")
	G.hud.show_card(Loc.t(TITLE), "")
	Sfx.jingle([392, 523, 659, 784])
	show()

## the places the scene shows while Alberto says the town is half dead: [from0, at0, from1, at1] for each
func _sad_corners() -> Array:
	var out: Array = []
	var add := func(target: Vector2, lift: float, _back: Vector2, up: float):
		var at := MapData.at(target, lift)
		var r: Dictionary = MapData.nearest_road(target)             # (seen from the street: never from inside a wall)
		var road: Vector2 = r["p"]
		var back: Vector2 = (road - target).normalized() if road.distance_to(target) > 1.0 else _back
		var along: Vector2 = r["u"]
		# (7 m along the street went into a house where it bends or ends: G.scene_shot keeps both ends where `at` is seen)
		var s: Array = G.scene_shot(at, MapData.at(road + back * 2.0 + along * 7.0, up), MapData.at(road + back * 1.0 - along * 5.0, up - 1.5))
		out.append([s[0], at, s[1], at])
	if not G.world.extra_ramps.is_empty():                       # a builder's skip full of rubble: a dirty corner
		var sk: Array = G.world.extra_ramps[0]
		add.call(sk[0] as Vector2, 0.8, Vector2(sin(float(sk[1]) + 1.2), cos(float(sk[1]) + 1.2)), 4.5)
	if G.bridge != null:                                         # the old bridge
		add.call(G.bridge.p, 2.0, (G.bridge.spot(0.0, -6.0) - G.bridge.p).normalized(), 6.0)
	add.call(sala.shutter(0.0), 2.0, sala.out, 4.0)              # the Recress, shut
	for h in MapData.houses:                                     # the communications tower
		if h["id"] == "central":
			var o := Vector2(h["o"][0], h["o"][1])
			var u := Vector2(h["u"][0], h["u"][1])
			add.call(o + u * float(h["len"]) / 2.0, 9.0, Vector2(-u.y, u.x), 7.0)
	if G.world.get("salud") != null and G.world.salud != null and G.world.salud.get("casualty") != null:      # urgencias
		var cz: Vector2 = G.world.salud.casualty
		var r: Dictionary = MapData.nearest_road(cz)
		add.call(cz, 2.0, ((r["p"] as Vector2) - cz).normalized(), 4.0)
	return out

# ---------------- the mayor ----------------
## the lines with what it costs written in
func _fmt(lines: Array) -> Array:
	return lines.map(func(l): return String(l) % COST if String(l).contains("%d") else l)

func _mayor(n) -> void:
	var first := stage() == "alcalde"
	var lines: Array = _fmt(Loc.t("alcalde_rec") if first else Loc.t("alcalde_rec_back"))
	G.say(n.shown_name(), lines, n.voice, func():
		if G.money >= COST:
			G._offer(n, Loc.t("rec_pay") % COST, _pay.bind(n), false, "step", _no_money.bind(n, false))
		else:
			_no_money(n, true))

func _no_money(n, short: bool) -> void:
	var paused := stage() == "alcalde"
	_to("dinero")
	if active():
		G.side = null                            # (the town is yours meanwhile: other missions, jobs...)
	G.say(n.shown_name(), Loc.t("alcalde_rec_nomoney") if short else Loc.t("alcalde_rec_later"), n.voice, func():
		G.hud.set_objective(G._tag(), Loc.t("obj_rec_money") % [COST, G.money])
		G.set_target(n.p, false)
		if paused:
			G.hud.toast(Loc.t("t_rec_paused"), 4.0))

func _pay(n) -> void:
	G.money -= COST
	G._refresh_counts()
	Sfx.jingle([523, 392], 0.12)
	st["paid"] = COST
	G.side = {"id": "recress", "who": "alberto", "stage": "copisteria"}
	_to("copisteria")
	G.say(n.shown_name(), Loc.t("alcalde_rec_paid"), n.voice, show)

func _got_posters() -> void:
	st["carteles"] = POSTERS
	_to("carteles")
	if G.pickups != null:
		var at: Vector2 = G.player.p + Vector2(sin(G.player.h), cos(G.player.h)) * 1.5
		G.pickups.spawn("carteles", at, {"tag": "carteles"})
	G.hud.toast(Loc.t("t_rec_posters"), 3.0)
	Sfx.jingle([659, 784], 0.1)
	show()

# ---------------- what you are to do, and the GPS ----------------
func show() -> void:
	if not active():
		return
	match stage():
		"alcalde":
			G.hud.set_objective(G._tag(), Loc.t("obj_rec_mayor"))
			G.set_target(G.named["alcalde"].p, false)
		"copisteria":
			G.hud.set_objective(G._tag(), Loc.t("obj_rec_copy"))
			var shop = _copy_shop()                  # (she is inside it: the arrow leads to its door)
			G.set_target(shop.door_out if shop != null else G.named["copista"].p, false)
		"carteles":
			G.hud.set_objective(G._tag(), Loc.t("obj_rec_posters") % [st["posters"].size(), POSTERS])
			var s = _nearest_free_shop(G.player.p)
			_poster_shop_id = String(s["id"]) if s != null else ""
			G.set_target(s["stand"] if s != null else null, s != null)
		"llamada":
			G.hud.set_objective(G._tag(), Loc.t("obj_rec_wait"))
			G.set_target(null, false)

## the main story has started up again: this is put aside where it was (it carries on afterwards)
func abort() -> void:
	G.side = null

# ---------------- every tick ----------------
func tick(dt: float, pp: Vector2) -> void:
	_tick_star(dt)
	_tick_walkers(dt)
	if cine:
		_tick_beats(dt)
	_keep_hours()
	sala.hold_in = stage() == "reto"             # no way out while the mayor waits for you at the machine (entradas.gd)
	if G.phase != "play" and G.phase != "free":
		return
	# twelve hours after the bridge, if you have not been to see him, Alberto rings
	if available() and stage() == "" and not _offered and G.stats.has("puente_h") and G.llamadas.now() - float(G.stats["puente_h"]) >= CALL_AFTER_H \
			and G.side == null and not G.in_mission():
		_offered = true
		G.llamadas.ring({"npc": "alberto", "lines": "alberto_rec_call", "plain": true, "valid": func(): return available() and G.side == null})
	# the posters are up: Alberto rings, and off you go
	if stage() == "llamada" and active() and not _offered and G.phone_call == null:
		_offered = true
		G.llamadas.ring({"npc": "alberto", "lines": "alberto_rec_packed", "plain": true, "after": _tournament,
			"valid": func(): return stage() == "llamada"})
	if active() and stage() == "carteles":
		_poster_t -= dt
		if _poster_t <= 0.0:
			_poster_t = 0.35
			var s = _nearest_free_shop(pp)
			var sid: String = String(s["id"]) if s != null else ""
			if sid != _poster_shop_id:
				show()
	# put off until you have the money: the mayor is waiting, and the objective says so (when nothing else is on)
	_remind_t -= dt
	if _remind_t <= 0.0:
		_remind_t = 1.0
		if stage() == "dinero" and G.side == null and not G.in_mission() and (G.phase == "free" or G.phase == "play" and G.steps[G.si]["type"] == "tbc"):
			G.hud.set_objective(G._tag(), Loc.t("obj_rec_money") % [COST, G.money])

# ---------------- the scenes ----------------
func _begin_scene() -> void:
	cine = true
	G.cine_lock = true
	G.hud.cine(true)
	G.set_target(null, false)
	G.hud.set_prompt("")
	if G.in_car != null:
		G.in_car.set_speed(Vector2.ZERO)
		G._exit_car()
	if G.first_person:                           # (indoors you see through your own eyes, and are not drawn; in a scene the
		G.first_person = false                   # camera is elsewhere, and you are seen: at the machine, in the final)
		G.player.vis.visible = true

func _end_scene() -> void:
	_walkers.clear()                             # (nobody goes on walking where a scene sent them)
	_clear_front(false)
	G.player.visible = true
	cine = false
	G.cine_lock = false
	G.cam_fixed = null
	G.cam.fov = 55.0
	G.hud.cine(false)
	_pan = null

## The cars in front of the Recress (parked and traffic alike) are not drawn while a scene is on in its street: one left
## at the door or rolling down the street stood in the middle of the crowd, or clipped through the mayor and his wife.
## They are there again as soon as the scenes leave the street.
var _cars_hid: Array = []
var _npcs_hid: Array = []

func _clear_front(on: bool) -> void:
	for c in _cars_hid:
		if is_instance_valid(c):
			c.visible = true
	_cars_hid.clear()
	for n in _npcs_hid:
		if is_instance_valid(n):
			n.visible = true
	_npcs_hid.clear()
	if not on:
		return
	var pool: Array = G.cars.duplicate()
	for e in G.traffic.list:
		var tc = e.get("car")
		if tc != null and not (tc in pool):
			pool.append(tc)
	for e in G.police.cops:
		var pc = e.get("car")
		if pc != null and not (pc in pool):
			pool.append(pc)
	for c in pool:
		if not is_instance_valid(c) or not c.visible or c == G.in_car:
			continue
		var d: Vector2 = (c.p as Vector2) - sala.shutter(0.0)
		if absf(d.dot(sala.u) + 8.0) < 42.0 and d.dot(sala.out) > -2.0 and d.dot(sala.out) < 16.0:
			c.visible = false
			_cars_hid.append(c)
	for n in G.npcs:
		if not is_instance_valid(n) or not n.visible or n.id in ["alcalde", "alcaldesa", "alberto", "katakumba"]:
			continue
		var d: Vector2 = (n.p as Vector2) - sala.shutter(0.0)
		if absf(d.dot(sala.u) + 8.0) < 42.0 and d.dot(sala.out) > -2.0 and d.dot(sala.out) < 16.0:
			n.visible = false
			_npcs_hid.append(n)

## a camera place over the shoulder of one, onto the other: [from, at]
func _two_shot(a, b, flip := false) -> Array:
	var pa: Vector2 = a.p
	var pb: Vector2 = b.p
	var dir := (pb - pa).normalized()
	var right := Vector2(-dir.y, dir.x) * (-1.0 if flip else 1.0)
	return [MapData.at(pa - dir * 0.9 + right * 1.5, 1.65), MapData.at(pa + dir * 1.1, 1.25)]

func _eye(p: Vector2, lift: float) -> Vector3:
	return Vector3(p.x, MapData.foot(p) + lift, p.y)

func _cut(from: Vector3, at: Vector3, fov := 50.0) -> void:
	G.cam_fixed = [from, at]
	G.cam_pos = from
	G.cam_look = at
	G.cam.fov = fov
	G.cam.position = from
	G.cam.look_at(at)

var _run_id := 0

func _run() -> void:
	_run_id += 1
	_beat = -1
	_next()

func _next() -> void:
	_beat += 1
	if _beat >= _beats.size():
		return
	var b: Array = _beats[_beat]
	_beat_t = float(b[1]) if b[1] is float or b[1] is int else 0.0
	match String(b[0]):
		"cut":
			_pan = null
			_cut(b[2], b[3], b[4])
		"pan":                                   # [pan, -, from0, at0, from1, at1, seconds, fov]: it runs on under what comes next
			_pan = [b[2], b[3], b[4], b[5], float(b[6]), 0.0, float(b[7])]
			_cut(b[2], b[3], b[7])
			_next()
			return
		"say":                                   # [say, npc or [name, voice], lines, from, at, fov]
			if b[3] != null:
				_pan = null
				_cut(b[3], b[4], b[5])
			var who = b[1]
			var name: String = who.shown_name() if not (who is Array) else String(who[0])
			var voice: String = who.voice if not (who is Array) else String(who[1])
			G.say(name, b[2], voice, _next)
			_beat_t = -1.0                       # (it moves on when the talking is over)
		"wait":
			pass
		"do":                                    # (what comes after it comes on the next tick, from _tick_beats: moving
			(b[2] as Callable).call()            # on from here as well made it go on twice when talking had just ended)
		"star":
			eureka(b[2])
		"fade":                                  # [fade, seconds, to (0 clear .. 1 black)]
			G.create_tween().tween_property(G.hud.fade, "modulate:a", float(b[2]), float(b[1]))
		"bark":                                  # [bark, seconds, npc, text]
			(b[2]).bark(String(b[3]), maxf(2.0, float(b[1]) + 1.5))

func _tick_beats(dt: float) -> void:
	if _pan != null:
		_pan[5] = float(_pan[5]) + dt
		var k := smoothstep(0.0, 1.0, clampf(float(_pan[5]) / float(_pan[4]), 0.0, 1.0))
		var from: Vector3 = (_pan[0] as Vector3).lerp(_pan[2], k)
		var at: Vector3 = (_pan[1] as Vector3).lerp(_pan[3], k)
		_cut(from, at, float(_pan[6]))
	if _beat < 0 or _beat >= _beats.size() or _beat_t < 0.0:
		return
	_beat_t -= dt
	if _beat_t <= 0.0:
		_next()

# ---------------- the star over a head ----------------
## An idea strikes somebody: a star pops up over their head, with a ding (the user asked for "the thing Animal
## Crossing does when something catches a character's eye"; this one is drawn and sounded here, not copied).
func eureka(n) -> void:
	_star.set_meta("who", n)
	_star_t = 1.6
	_star.visible = true
	Sfx.beep(1568.0, 0.07, 1, -10.0)
	G.get_tree().create_timer(0.08).timeout.connect(Sfx.beep.bind(2093.0, 0.12, 1, -10.0))
	G.get_tree().create_timer(0.2).timeout.connect(Sfx.beep.bind(2637.0, 0.18, 1, -14.0))

func _tick_star(dt: float) -> void:
	if _star_t <= 0.0:
		return
	_star_t -= dt
	var n = _star.get_meta("who", null)
	if n == null or not is_instance_valid(n) or _star_t <= 0.0:
		_star.visible = false
		_star_t = 0.0
		return
	var age := 1.6 - _star_t
	var pop := 1.0 + 0.35 * sin(clampf(age / 0.25, 0.0, 1.0) * PI) if age < 0.25 else 1.0
	_star.scale = Vector3.ONE * minf(1.0, age / 0.12) * pop
	_star.modulate.a = clampf(_star_t / 0.3, 0.0, 1.0)
	_star.global_position = n.global_position + Vector3(0.0, 2.3 * float(n.look_data.get("scale", 1.0)) + 0.1 * age, 0.0)

# ---------------- people walking about in the scenes ----------------
func _walk(n, to: Vector2, speed := 1.6, then = null) -> void:
	if "state" in n:                             # (a neighbour: the town stops moving them about; you have no such thing)
		n.state = "busy"
	_walkers = _walkers.filter(func(w): return w[0] != n)
	_walkers.append([n, to, speed, then])

func _tick_walkers(dt: float) -> void:
	for w in _walkers.duplicate():
		var n = w[0]
		if not is_instance_valid(n):
			_walkers.erase(w)
			continue
		var to: Vector2 = w[1]
		var d: Vector2 = to - n.p
		if d.length() < 0.25:
			n.anim(false, dt, 0.0)
			_walkers.erase(w)
			if w[3] != null:
				(w[3] as Callable).call()
			continue
		n.h = lerp_angle(n.h, atan2(d.x, d.y), 1.0 - exp(-8.0 * dt))
		n.p = n.p + d.normalized() * minf(d.length(), float(w[2]) * dt)
		n.global_position.y = MapData.foot(n.p)
		n.anim(true, dt, float(w[2]))
		n.sync()

## put somebody somewhere at once, facing a point
func _place(n, at: Vector2, face: Vector2) -> void:
	n.p = at
	if "home" in n:
		n.home = at
	var d := face - at
	n.h = atan2(d.x, d.y)
	n.global_position.y = MapData.foot(at)
	n.sync()

# ---------------- the music the scenes want ----------------
func music() -> Array:
	return [_music, _music_db]

# ---------------- the tournament ----------------
## Alberto has rung: the Recress is packed. Everything from here to the end of the night is one scene after another,
## with a single stretch in the middle where it is up to you: sitting down at the machine to play the mayor.
func _tournament() -> void:
	_to("torneo")
	G.side = {"id": "recress", "who": "alberto", "stage": "torneo"}
	_begin_scene()
	var fade: Tween = G.create_tween()
	fade.tween_property(G.hud.fade, "modulate:a", 1.0, 0.8)
	fade.tween_callback(_at_the_door)

func _at_the_door() -> void:
	var door: Vector2 = sala.shutter(0.0)
	sala.show_posters(true)
	sala.set_state("abierto")                    # (the user: done up by the tournament, open all through it and that night)
	_gather_crowd()
	_clear_front(true)
	var alberto = G.named["alberto"]
	var along: Vector2 = sala.u
	var arrive: Vector2 = sala.shutter(5.5) + along * 14.0
	G.player.p = arrive
	G.player.h = atan2(-along.x, -along.y)
	G.player.sync()
	_keep_place(alberto)
	_place(alberto, sala.shutter(3.4) + along * 2.6, arrive)
	G.set_time(maxf(G.clock, 18.5) if G.clock < 21.0 else G.clock)       # (the tournament is of an evening)
	var crowd_view := [MapData.at(sala.shutter(12.0) - along * 6.0, 4.5), Vector3(door.x, sala.base + 1.6, door.y)]
	var near_door := [MapData.at(sala.shutter(6.5) + along * 3.0, 1.7), Vector3(door.x, sala.base + 1.5, door.y)]
	_beats = [
		["do", 0.0, func(): G.create_tween().tween_property(G.hud.fade, "modulate:a", 0.0, 1.0)],
		["pan", 0.1, crowd_view[0], crowd_view[1], near_door[0], near_door[1], 5.5, 52.0],
		["wait", 5.5],
		["do", 0.0, func():
			_walk(G.player, sala.shutter(4.0) + along * 6.0, 2.2)
			_walk(alberto, sala.shutter(4.0) + along * 4.6, 1.6)],
		["cut", 0.1, MapData.at(sala.shutter(6.5) + along * 10.0, 1.7), MapData.at(sala.shutter(2.0) + along * 1.0, 1.4), 44.0],
		["bark", 1.4, alberto, Loc.t("alberto_rec_hey")],
		["wait", 2.6],
		["say", alberto, Loc.t("alberto_rec_door"), MapData.at(sala.shutter(8.0) + along * 5.6, 1.7), MapData.at(sala.shutter(3.2) + along * 3.8, 1.3), 40.0],
		["do", 0.0, func():
			var two := _two_shot(G.player, alberto)
			_cut(two[0], two[1], 44.0)],
		["say", alberto, Loc.t("alberto_rec_door2"), null, null, 44.0],
		["do", 0.0, func():
			_walk(G.player, sala.shutter(0.8), 1.8)
			_walk(alberto, sala.shutter(0.9) + along * 0.8, 1.8)],
		["cut", 2.6, MapData.at(sala.shutter(9.0) - along * 1.0, 2.2), Vector3(door.x, sala.base + 1.4, door.y), 44.0],
		["fade", 0.6, 1.0],
		["wait", 0.7],
		["do", 0.0, _inside],
	]
	_run()

## the people outside the doors, and inside
func _gather_crowd() -> void:
	_clear_crowd()
	for i in range(18):
		var at: Vector2 = sala.shutter(1.6 + (i % 4) * 0.9) + sala.u * (float(i / 4) * 1.1 - 2.4 + randf_range(-0.3, 0.3))
		var n = G.spawn_neighbour(at, true)
		n.state = "busy"
		var d: Vector2 = sala.shutter(0.0) - at
		n.h = atan2(d.x, d.y) + randf_range(-0.6, 0.6)
		n.sync()
		crowd.append(n)

func _clear_crowd() -> void:
	for n in crowd:
		if is_instance_valid(n):
			G.npcs.erase(n)
			n.queue_free()
	crowd.clear()

## the people of the tournament itself, in the hall
var _inside_people := {}          # role -> npc
var _players_at := {}             # cabinet -> whoever is playing at it

func _hall_people() -> void:
	_clear_crowd()
	for k in _inside_people.keys():
		var n = _inside_people[k]
		if is_instance_valid(n) and not (n.id in ["alcalde", "alberto"]):
			G.npcs.erase(n)
			G.named.erase(n.id)
			n.queue_free()
	_inside_people.clear()
	var hall: Vector2 = Sala.INSIDE
	var mum_at: Vector2 = sala.crowd_spots[18]       # (in the row nearest the door: she has her say when the mayor makes his challenge out there)
	for i in range(sala.crowd_spots.size()):
		if i == 18:
			continue
		var at: Vector2 = sala.crowd_spots[i]
		var n = G.spawn_neighbour(at, true)
		n.state = "busy"
		_place(n, at, sala.machine + Vector2(0, 2.0))
		crowd.append(n)
	_players_at.clear()
	for i in range(sala.cabinets.size()):         # somebody playing at most of the machines along the walls
		if i % 3 == 2:
			continue
		var c: Array = sala.cabinets[i]
		var n = G.spawn_neighbour(c[0], true)
		n.state = "busy"
		n.p = c[0]
		n.h = float(c[1])
		n.global_position.y = MapData.foot(c[0])
		n.sync()
		crowd.append(n)
		_players_at[i] = n
	if G.named.has("katakumba"):                  # (the one who lives here, if the Recress was open before)
		var old = G.named["katakumba"]
		G.npcs.erase(old)
		G.named.erase("katakumba")
		old.queue_free()
	var kata = G._make_npc("katakumba", LOOKS["katakumba"].duplicate(), "adult_m", hall + Vector2(2.4, Sala.D - 3.9))
	kata.state = "busy"
	_place(kata, hall + Vector2(2.4, Sala.D - 3.9), sala.machine)
	_inside_people["katakumba"] = kata
	var com = G._make_npc("comentarista", LOOKS["comentarista"].duplicate(), "adult_m", sala.mic)
	com.state = "busy"
	_place(com, sala.mic, sala.mic + Vector2(1.0, 0.0))
	_inside_people["comentarista"] = com
	var mum = G._make_npc("madre_alcalde", LOOKS["madre_alcalde"].duplicate(), "old_f", mum_at)
	mum.state = "busy"
	_place(mum, mum_at, sala.machine)
	_inside_people["madre"] = mum
	crowd.append(mum)
	var mayor = G.named["alcalde"]
	_keep_place(mayor)
	mayor.state = "busy"
	_place(mayor, hall + Vector2(-2.4, Sala.D - 3.9), sala.machine)
	_inside_people["alcalde"] = mayor
	var alberto = G.named["alberto"]
	_keep_place(alberto)
	_inside_people["alberto"] = alberto

## A camera in front of somebody's face, as [from, at]. The heads here are big (a metre across), so `dist` is from the
## middle of the head: at 2 m the face fills the picture. `side`: that far to one side of them. `drop`: how far below
## their eyes it looks, which puts the face higher in the picture, clear of the dialogue box (0: the eyes in the
## middle, for the stares). `at_p` and `h`: where they will be standing and which way they will be facing, if not
## where and how they are now.
func _face(n, at_p = null, h = null, dist := 2.1, side := 0.35, drop := 0.3) -> Array:
	var p: Vector2 = at_p if at_p != null else n.p
	var hh: float = float(h) if h != null else float(n.h)
	var f := Vector2(sin(hh), cos(hh))
	var l := Vector2(f.y, -f.x)
	var ld = n.get("look_data") if n != null else null
	var tall: float = float(ld.get("scale", 1.0)) if ld is Dictionary else 1.0
	return [_eye(p + f * dist + l * side, 1.5 * tall), _eye(p, (1.45 - drop) * tall)]

## somebody turns to face a heading (radians)
func _turn(n, h: float) -> void:
	if is_instance_valid(n):
		n.h = h
		n.sync()

## where somebody belongs, and which way they face, kept before a scene moves them (_place moves their home too)
func _keep_place(n) -> void:
	if not n.has_meta("back"):
		n.set_meta("back", [n.home, n.h])

## everybody in the hall turns to look at a spot
func _all_look(at: Vector2) -> void:
	for n in crowd:
		if is_instance_valid(n) and n.state == "busy" and (n.p as Vector2).y > Sala.INSIDE.y + 8.5 and absf((n.p as Vector2).x - Sala.INSIDE.x) < 5.0:
			var d := at - (n.p as Vector2)
			n.h = atan2(d.x, d.y)
			n.sync()

func _inside() -> void:
	_walkers.clear()
	_clear_front(false)
	_hall_people()
	var alberto = G.named["alberto"]
	G.indoors = true
	G.inside_of = sala
	G.player.p = sala.in_spawn
	G.player.h = 0.0
	G.player.sync()
	_place(alberto, sala.aside, sala.machine)
	_music = "none"                              # (no music in there: the people are the noise. Traktor FM comes with the win)
	var hall: Vector2 = Sala.INSIDE
	var kata = _inside_people["katakumba"]
	var com = _inside_people["comentarista"]
	var mayor = _inside_people["alcalde"]
	var talk: Array = Loc.t("rec_shit_talk")
	# where the camera goes
	var screen := [_eye(hall + Vector2(0.0, Sala.D - 3.1), 2.3), _eye(hall + Vector2(0.0, Sala.D - 0.3), 2.7)]      # over the players' heads, onto the big screen
	var com_shot := _face(com)
	var kata_up := _face(kata, sala.stage_other, PI, 2.1, 0.3)          # the two finalists, presented to everybody
	var mayor_up := _face(mayor, sala.stage_you, PI, 2.1, -0.3)
	var mayor_play := _face(mayor, sala.seat_you, 0.0, 1.5, -1.5, 0.12) # at the machine: from beside it, three-quarters on
	var kata_play := _face(kata, sala.seat_other, 0.0, 1.5, 1.5, 0.12)
	var shout_a := _face(crowd[3], null, null, 2.0, 0.4)               # somebody in the front row, from in front of them
	var shout_b := _face(crowd[5], null, null, 2.0, -0.4)
	var audience := [_eye(hall + Vector2(1.8, Sala.D - 3.6), 1.9), _eye(hall + Vector2(0.0, Sala.D - 7.2), 1.3)]   # from by the stools, onto everybody
	var mid: Vector2 = (sala.duel_you + sala.duel_him) / 2.0
	var thanks := _face(mayor, sala.duel_him, PI, 2.4, 0.6)
	var him_eyes := _face(mayor, sala.duel_him, PI, 2.1, 0.0, 0.0)
	var you_eyes := _face(G.player, sala.duel_you, 0.0, 2.1, 0.0, 0.0)
	var challenge := _face(mayor, sala.duel_him, PI, 2.4, 0.5)
	# about thirty seconds of people playing, laughing and having a go at each other, then the final
	_beats = [
		["do", 0.0, func(): G.create_tween().tween_property(G.hud.fade, "modulate:a", 0.0, 0.8)],
		["pan", 0.1, _eye(hall + Vector2(-6.0, 2.0), 3.4), _eye(hall + Vector2(0.0, 10.0), 1.2), _eye(hall + Vector2(5.5, 4.5), 3.0), _eye(hall + Vector2(-1.0, 12.0), 1.2), 6.0, 60.0],
		["bark", 2.4, crowd[0], talk[0]],
		["wait", 2.6],
		["bark", 2.4, crowd[20], talk[1]],
		["wait", 3.2],
	]
	for i in range(4):                            # somebody at a machine along the walls, side on, and the fight on its screen
		var k: int = [0, 3, 4, 7][i]
		var c: Array = sala.cabinets[k]
		var at: Vector2 = c[0]
		var f := Vector2(sin(float(c[1])), cos(float(c[1])))
		var l := Vector2(f.y, -f.x)
		var scr: Vector3 = _eye(at + f * 0.62, 1.48)
		_beats.append(["pan", 0.1, _eye(at - f * 0.1 + l * 1.75, 1.66), scr, _eye(at - f * 0.2 + l * 1.45, 1.6), scr, 2.6, 36.0])
		_beats.append(["bark", 2.0, _players_at.get(k, crowd[0]), talk[(i + 2) % talk.size()]])
		_beats.append(["wait", 2.6])
	_beats.append_array([
		["say", com, Loc.t("com_rec_final"), com_shot[0], com_shot[1], 40.0],
		["do", 0.0, func(): _walk(kata, sala.stage_other, 1.4, _turn.bind(kata, PI))],
		["cut", 0.1, _eye(hall + Vector2(4.6, Sala.D - 2.2), 1.7), _eye(sala.stage_other, 1.3), 40.0],
		["wait", 1.8],
		["say", com, Loc.t("com_rec_kata"), kata_up[0], kata_up[1], 40.0],
		["do", 0.0, func():
			Sfx.beep(98.0, 2.4, 3, -14.0, 10.0)
			_walk(mayor, sala.stage_you, 1.5, _turn.bind(mayor, PI))],
		["say", com, [Loc.t("com_rec_mayor")[0]], com_shot[0], com_shot[1], 40.0],
		["pan", 0.1, _eye(sala.stage_you + Vector2(0.3, -1.8), 0.4), _eye(sala.stage_you, 0.5), mayor_up[0], mayor_up[1], 3.4, 40.0],      # from his feet up
		["wait", 3.4],
		["say", com, [Loc.t("com_rec_mayor")[1]], null, null, 40.0],
		["cut", 0.1, audience[0], audience[1], 50.0],
		["bark", 2.0, crowd[2], Loc.t("rec_gasp")[0]],
		["bark", 2.0, crowd[5], Loc.t("rec_gasp")[1]],
		["say", mayor, Loc.t("alcalde_rec_born"), mayor_up[0], mayor_up[1], 40.0],
		["do", 0.0, func():                     # and to the machine, the two of them
			_walk(mayor, sala.seat_you, 1.2, _turn.bind(mayor, 0.0))
			_walk(kata, sala.seat_other, 1.2, _turn.bind(kata, 0.0))],
		["say", com, Loc.t("com_rec_go"), _eye(hall + Vector2(-5.5, 10.5), 2.6), _eye(hall + Vector2(0.0, Sala.D - 1.5), 1.4), 46.0],
	])
	# the fight: faces, the screen, the audience; the mayor wins it
	for i in range(4):
		var fs: Array = mayor_play if i % 2 == 0 else kata_play
		_beats.append(["cut", 0.9, fs[0], fs[1], 26.0])
		_beats.append(["cut", 0.8, screen[0], screen[1], 34.0])
	_beats.append_array([
		["cut", 0.1, shout_a[0], shout_a[1], 40.0],
		["bark", 2.2, crowd[3], Loc.t("rec_fight")[0]],
		["cut", 0.1, shout_b[0], shout_b[1], 40.0],
		["bark", 2.4, crowd[5], Loc.t("rec_fight")[1]],
		["do", 0.0, func():
			sala.knock_out(1.0)
			G.create_tween().tween_method(sala.knock_out, 1.0, 0.0, 1.2)
			Sfx.noise(0.4, -8.0)],
		["cut", 1.2, screen[0], screen[1], 34.0],
		["say", com, Loc.t("com_rec_mayor_wins"), com_shot[0], com_shot[1], 40.0],
		["do", 0.0, func():
			sala.confetti()
			_cheer(Loc.t("rec_cheer"))],
		["pan", 0.1, _eye(hall + Vector2(0.0, 3.0), 3.0), _eye(hall + Vector2(0.0, 12.0), 2.0), _eye(hall + Vector2(0.0, 6.5), 2.4), _eye(hall + Vector2(0.0, 13.0), 2.0), 4.0, 56.0],
		["wait", 4.0],
		["do", 0.0, func():                     # he comes out in front of everybody, and you are standing there
			_place(mayor, sala.duel_him, sala.duel_you)
			_place(G.player, sala.duel_you, sala.duel_him)
			_all_look(mid)],
		["say", mayor, Loc.t("alcalde_rec_thanks"), thanks[0], thanks[1], 40.0],
	])
	# the challenge, as at a duel in the old West: side on and low, then the eyes, nearer each time
	_beats.append_array([
		["cut", 1.8, _eye(mid + Vector2(4.2, 0.0), 0.6), _eye(mid, 1.0), 50.0],
		["say", mayor, Loc.t("alcalde_rec_more"), him_eyes[0], him_eyes[1], 20.0],
		["cut", 0.7, you_eyes[0], you_eyes[1], 14.0],
		["cut", 0.7, him_eyes[0], him_eyes[1], 11.0],
		["say", mayor, Loc.t("alcalde_rec_challenge"), challenge[0], challenge[1], 32.0],
		["do", 0.0, _challenge],
	])
	_run()

## everybody shouts at once
func _cheer(lines: Array) -> void:
	for i in range(crowd.size()):
		if i % 2 == 0 and is_instance_valid(crowd[i]):
			crowd[i].bark(lines[i % lines.size()], 3.0)
			crowd[i].punch = 0.28

## Double or nothing: you can say no, but nobody will let you
func _challenge() -> void:
	G._choice = {"offer": true, "title": Loc.t("rec_bet_title").to_upper(), "options": [
		[Loc.t("rec_bet_yes"), func(): _accept_bet()],
		[Loc.t("rec_bet_no"), func(): _refuse_bet()]]}
	G.menu.open("choice")

func _refuse_bet() -> void:
	G.menu.close()
	_taunts += 1
	var mayor = _inside_people["alcalde"]
	var mum = _inside_people["madre"]
	var alberto = G.named["alberto"]
	var mid: Vector2 = (sala.duel_you + sala.duel_him) / 2.0
	var jeers: Array = Loc.t("rec_jeer")
	_cheer([jeers[_taunts % jeers.size()]])
	_place(alberto, sala.aside, mid)
	var a: Array = _face(alberto)
	_beats = [
		["say", alberto, Loc.t("alberto_rec_dale"), a[0], a[1], 34.0],
	]
	if _taunts == 1:
		_place(mum, mum.p, mid)
		var m: Array = _face(mum, null, null, 1.9, 0.9)
		var him: Array = _face(mayor, sala.duel_him, PI, 2.2, -0.4)
		_beats.append_array([
			["say", mum, Loc.t("madre_rec_shout"), m[0], m[1], 30.0],
			["say", mayor, Loc.t("alcalde_rec_mum"), him[0], him[1], 30.0],
		])
	_beats.append(["do", 0.0, _challenge])
	_run()

func _accept_bet() -> void:
	G.menu.close()
	_cheer(Loc.t("rec_cheer"))
	_place(_inside_people["alcalde"], sala.seat_other, sala.seat_other + Vector2(0.0, 1.0))
	var kata = _inside_people["katakumba"]
	_place(kata, Sala.INSIDE + Vector2(2.4, Sala.D - 3.9), sala.machine)
	_all_look(sala.machine)
	_end_scene()
	_to("reto")
	G.hud.set_objective(G._tag(), Loc.t("obj_rec_play"))
	G.set_target(sala.seat_you, false)

## (game.gd) can you sit down at the machine now? Near it, or near him: there the action button is "Jugar", before
## "Hablar" with anybody (the user, 17 November 2026: "le he dado a «hablar» varias veces hasta que lo he conseguido")
func can_play(p: Vector2) -> bool:
	if stage() != "reto" or not G.indoors or G.inside_of != sala:
		return false
	var mayor = _inside_people.get("alcalde")
	return p.distance_to(sala.seat_you) < 2.2 or (mayor != null and p.distance_to(mayor.p) < 3.2)      # (3.2: as far off as you can talk to him)

## E at the machine: Tokken 9 (tokken.gd), against the mayor. He is DoomAssasin78 and plays the Monster, as in the
## final; you choose yours.
func play() -> void:
	_place(G.player, sala.seat_you, sala.seat_you + Vector2(0.0, 1.0))
	G.tokken.start({"foe": "monstruo", "foe_tag": "DoomAssasin78", "ai": "alcalde"}, result)

## how the game against the mayor went (lose, and you are back in front of the machine: "¿Otra?")
func result(won: bool) -> void:
	if not won:
		G.say(_inside_people["alcalde"].shown_name(), Loc.t("alcalde_rec_again"), _inside_people["alcalde"].voice)
		return
	_begin_scene()
	_to("final")
	_final()

func _final() -> void:
	var mayor = _inside_people["alcalde"]
	var com = _inside_people["comentarista"]
	var alberto = G.named["alberto"]
	var hall: Vector2 = Sala.INSIDE
	var screen := [_eye(hall + Vector2(0.0, Sala.D - 3.1), 2.3), _eye(hall + Vector2(0.0, Sala.D - 0.3), 2.7)]
	var him: Array = _face(mayor, sala.seat_other, 0.0, 1.5, 1.5, 0.12)       # from beside the machine, three-quarters on
	var com_shot: Array = _face(com)
	_place(alberto, sala.aside, sala.machine)
	var a: Array = _face(alberto)
	_beats = [
		["cut", 1.2, screen[0], screen[1], 34.0],
		["do", 0.0, func():
			sala.knock_out(1.0)
			G.create_tween().tween_method(sala.knock_out, 1.0, 0.0, 1.4)
			Sfx.noise(0.5, -6.0)],
		["pan", 0.1, screen[0], screen[1], him[0], him[1], 2.4, 38.0],
		["wait", 2.4],
		["say", mayor, Loc.t("alcalde_rec_lost"), null, null, 38.0],
		["do", 0.0, func():
			_music = "radio_2"
			_music_db = -20.0],
		["say", com, Loc.t("com_rec_champion"), com_shot[0], com_shot[1], 40.0],
		["do", 0.0, func():
			sala.confetti()
			_cheer(Loc.t("rec_cheer_you"))
			_walk(mayor, sala.in_door + Vector2(0.0, 0.6), 1.3)],
		["pan", 0.1, _eye(hall + Vector2(0.0, 5.5), 2.9), _eye(sala.seat_you, 1.3), _eye(hall + Vector2(1.5, 8.0), 2.7), _eye(sala.seat_you, 1.3), 4.5, 52.0],
		["say", alberto, Loc.t("alberto_rec_won"), a[0], a[1], 40.0],
		["cut", 3.0, _eye(hall + Vector2(5.5, 6.0), 1.9), _eye(sala.in_door, 1.3), 40.0],
		["fade", 0.9, 1.0],
		["wait", 1.0],
		["do", 0.0, _night],
	]
	_run()

## That night, outside: the mayor and his wife.
func _night() -> void:
	_walkers.clear()
	_music = ""
	G.indoors = false
	G.inside_of = null
	_clear_front(true)
	if G.clock > 5.0 and G.clock < 22.0:
		G.set_time(22.5)
	var mayor = _inside_people["alcalde"]
	var door: Vector2 = sala.shutter(0.4)
	var stop: Vector2 = sala.shutter(2.4) + sala.u * 0.6       # where he stops, in front of her
	var her: Vector2 = sala.shutter(2.6) + sala.u * 3.0
	var wife = G._make_npc("alcaldesa", LOOKS["alcaldesa"].duplicate(), "adult_f", her)
	wife.state = "busy"
	_inside_people["alcaldesa"] = wife
	_place(mayor, door, sala.shutter(5.0))
	_place(wife, her, door)
	G.player.p = sala.in_spawn                              # (you are still inside: hidden, out of the picture)
	G.player.visible = false
	G.player.sync()
	var two := [MapData.at(sala.shutter(6.4) + sala.u * 2.4, 2.1), MapData.at(sala.shutter(1.8) + sala.u * 1.8, 1.3)]
	var h_him := atan2((her - stop).x, (her - stop).y)
	var him: Array = _face(mayor, stop, h_him, 2.0, 1.2)
	var she: Array = _face(wife, her, h_him + PI, 2.0, -1.2)
	var away: Vector2 = (her - door).normalized()             # (behind her, when she turns to look at the Recress)
	var by := Vector2(-away.y, away.x)
	var moon: Vector3 = G.sky_fx.moon_dir() if G.sky_fx.has_method("moon_dir") else Vector3(0.3, 0.6, 0.7).normalized()
	_beats = [
		["do", 0.0, func():
			G.create_tween().tween_property(G.hud.fade, "modulate:a", 0.0, 1.2)
			_walk(mayor, stop, 1.0, func():
				_turn(mayor, h_him)
				_turn(wife, h_him + PI))],
		["cut", 2.6, two[0], two[1], 46.0],
		["say", wife, Loc.t("alcaldesa_rec_1"), two[0], two[1], 46.0],
		["say", mayor, Loc.t("alcalde_rec_excuse"), him[0], him[1], 38.0],
		["do", 0.0, func():
			mayor.bark(Loc.t("alcalde_rec_curse"), 3.0)
			_walk(mayor, sala.shutter(3.5) - sala.u * 22.0, 1.5)],
		["wait", 1.6],
		["say", wife, Loc.t("alcaldesa_rec_2"), she[0], she[1], 38.0],
		["do", 0.0, func(): _turn(wife, atan2((door - her).x, (door - her).y))],
		["pan", 0.1, _eye(her + away * 2.4 + by * 1.0, 2.3), _eye(door, 2.3), _eye(her + away * 2.0 + by * 0.8, 2.4), _eye(door, 2.6), 3.0, 40.0],
		["say", wife, Loc.t("alcaldesa_rec_3"), null, null, 40.0],
		["do", 0.0, func(): _walk(wife, sala.shutter(3.5) - sala.u * 22.0, 1.3)],
		["pan", 0.1, MapData.at(sala.shutter(_far_side(moon)), 1.8), MapData.at(sala.shutter(3.0) - sala.u * 4.0, 1.8), MapData.at(sala.shutter(_far_side(moon)), 7.0), MapData.at(sala.shutter(_far_side(moon)), 7.0) + moon * 100.0, 6.0, 52.0],
		["wait", 6.2],
		["fade", 1.2, 1.0],
		["wait", 1.3],
		["do", 0.0, _finished],
	]
	_run()

## how far out from the front to stand so that the moon is not behind the building (it may be on its side of the street)
func _far_side(moon: Vector3) -> float:
	var m := Vector2(moon.x, moon.z)
	return 2.0 if m.dot(sala.out) >= 0.0 else 9.0       # (moon out over the street: from by the door; behind the building: from across the street)

## out of the door of the Recress, and the mission done
func _finished() -> void:
	_end_scene()
	_clear_crowd()
	for k in _inside_people.keys():
		var n = _inside_people[k]
		if not is_instance_valid(n):
			continue
		if n.id == "alcalde" or n.id == "alberto":       # back where they belong: the mayor at his door, Alberto at his bridge
			var back: Array = n.get_meta("back", [n.home, n.h])
			var at: Vector2 = back[0]
			_place(n, at, at + Vector2(sin(float(back[1])), cos(float(back[1]))))
			if n.has_meta("back"):
				n.remove_meta("back")
			n.state = "idle"
		elif n.id != "katakumba":                 # (Katakumba69 lives at the Recress now)
			G.npcs.erase(n)
			G.named.erase(n.id)
			n.queue_free()
	_inside_people.clear()
	_walkers.clear()
	_to("hecho")
	sala.set_state("abierto")
	_open_hall()
	G.side = null
	G.player.p = sala.out_spawn
	G.player.h = sala.out_h
	G.player.sync()
	G._door_cool = 1.0                       # (out of its door, as by the door: its green arrow does not take you straight back in -- entradas.gd)
	G.cam_yaw = G.player.h
	G.create_tween().tween_property(G.hud.fade, "modulate:a", 0.0, 1.0)
	var pay := maxi(int(st.get("paid", COST)), COST) * PRIZE * BET       # (a game saved when he asked for less: the same 200 €)
	G.money += pay
	G._refresh_counts()
	G.add_pc(3, true)
	G.hud.stamp(Loc.t("stamp_done"))
	Sfx.jingle([523, 659, 784, 1047], 0.12)
	G._mission_done()
	G.chismes.mission_over("recress")          # (the town will talk about it: chismes.gd)
	G._show_step()

## Its hours (the user, 14 November 2026): from three in the afternoon to two at night; the rest of the time shut,
## done up, its shutter down. Time to shut with you inside: it waits for you to come out.
const OPENS := 15.0
const SHUTS := 2.0
func open_hours(h: float) -> bool:
	return h >= OPENS or h < SHUTS

func _keep_hours() -> void:
	if not done() or cine:
		return
	var want := "abierto" if open_hours(G.clock) else "cerrado"
	if want == sala.state:
		return
	if want == "cerrado" and G.indoors and G.inside_of == sala:
		return
	sala.set_state(want)

## The Recress open: Katakumba69 lives there now, and a few others are always at the machines.
var _regulars: Array = []

## (not open: nobody in there)
func _close_hall() -> void:
	for n in _regulars:
		if is_instance_valid(n):
			G.npcs.erase(n)
			n.queue_free()
	_regulars.clear()
	if G.named.has("katakumba"):
		var k = G.named["katakumba"]
		G.npcs.erase(k)
		G.named.erase("katakumba")
		k.queue_free()

func _open_hall() -> void:
	for n in _regulars:
		if is_instance_valid(n):
			G.npcs.erase(n)
			n.queue_free()
	_regulars.clear()
	var kata_at: Vector2 = sala.stage_other + Vector2(0.8, -0.4)
	if not G.named.has("katakumba"):
		G._make_npc("katakumba", LOOKS["katakumba"].duplicate(), "adult_m", kata_at)
	var kata = G.named["katakumba"]
	kata.state = "busy"
	kata.still = true
	_place(kata, kata_at, sala.duel_him)
	kata.sync()
	for i in [3, 4, 6]:
		var c: Array = sala.cabinets[i]
		var n = G.spawn_neighbour(c[0], true)
		n.state = "busy"
		n.p = c[0]
		n.h = float(c[1])
		n.global_position.y = MapData.foot(c[0])
		n.sync()
		_regulars.append(n)

## The Recress open: a game of Tokken 9 at any machine is against the machine (harder the more games you win in a row).
## To play against Katakumba69 himself (Dracula; counts with him: folk.played), talk to him in the hall.
const LADDER := ["facil", "normal", "normal", "dificil", "dificil", "katakumba"]

func play_katakumba() -> void:
	G.tokken.start({"foe": "dracula", "foe_tag": "Katakumba69", "ai": "katakumba"}, func(won: bool):
		G.folk.played("katakumba")
		G.stats["tokken_kata"] = int(G.stats.get("tokken_kata", 0)) + (1 if won else 0)
		var kata = G.named.get("katakumba")
		if kata != null:
			kata.bark(Loc.t("kata_tk_won" if won else "kata_tk_lost").pick_random(), 4.0)
		G.hud.toast(Loc.t("t_tk_won" if won else "t_tk_lost") % "Katakumba69", 3.5))

func free_play(_p: Vector2) -> void:
	var streak: int = int(G.stats.get("tokken_racha", 0))
	G.tokken.start({"foe": "", "ai": LADDER[mini(streak, LADDER.size() - 1)]}, func(won: bool):
		G.stats["tokken_racha"] = streak + 1 if won else 0
		G.stats["tokken_mejor"] = maxi(int(G.stats.get("tokken_mejor", 0)), int(G.stats["tokken_racha"]))
		G.hud.toast((Loc.t("t_tk_streak") % int(G.stats["tokken_racha"])) if won else Loc.t("t_tk_over"), 3.5))

func at_rally(p: Vector2) -> bool:
	return done() and G.indoors and G.inside_of == sala and sala.state == "abierto" and p.distance_to(sala.rally_seat) < 1.35

func at_hit_vip(p: Vector2) -> bool:
	return done() and G.indoors and G.inside_of == sala and sala.open and p.distance_to(sala.cabinets[sala.HIT_VIP][0]) < 1.2

func at_machine(p: Vector2) -> bool:
	if not done() or not G.indoors or G.inside_of != sala:
		return false
	for i in range(sala.cabinets.size()):
		if i != sala.HIT_VIP and p.distance_to(sala.cabinets[i][0]) < 1.2:
			return true
	return p.distance_to(sala.seat_you) < 1.4
