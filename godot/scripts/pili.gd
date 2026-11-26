extends RefCounted
## La Pili and her bacaladitos (the user, 25 November 2026):
##   "Una vez finalizada la conversación sobre la herencia aparecerá un nuevo NPC en el mapa que dará una misión. Estará
##   andando por el arroyuelo mientras tenga misión activa, si no dando vueltas por ubicaciones del pueblo (tiendas,
##   supermercados, restaurantes). La misión se activará hablando ella, si estás cerca del NPC te perseguirá andando y
##   murmurándote que tiene que hablar contigo, oye tú y tal."
##   "NPC: La Pili, personalidad muy pesada y muy cotilla y muy parlanchina y sin filtro (te pregunta cosas muy personales
##   o te dice cosas demasiado personales sobre ella)", with a photo of her (curly black hair going grey, a purple
##   cardigan, pearl earrings, brown shoes and her tartan shopping trolley).
##
## Stages (G.stats "pili"): "" she walks up and down the Calle del Arroyuelo Medio and comes after you when you are near;
## "fetch" you have said yes: her bacaladitos are at the first till of the Merkocarry (merkocarry_dentro.gd, a set apart),
## where La Pescadera (on the till while her fish counter is shut) tells you she is banned (a crossed-out poster of her up by the till and by the doors); "give" the
## fish in your hands, she waits by her house in the Magdalena; "done" it was a panga -- +50 € and +30 P.C. all the same
## -- and from then on she goes round the town's shops, supermarkets and restaurants, telling you far too much.
## It takes the errand slot (G.side = {id: "pili"}), like Tomasa's (tomasa.gd).

const Parts = preload("res://scripts/parts.gd")
const Portrait = preload("res://scripts/portrait.gd")

const PAY := 50
const PC := 30
const EVERY := 0.35
const CHASE_NEAR := 14.0            # she sees you and comes after you...
const CHASE_GIVE_UP := 30.0         # ...until you are this far off
const BARK_EVERY := 3.6
const WANDER_STAY := 40.0           # seconds at each shop's door after her errand

const PILI_LOOK := {        # (look A of the four the user was shown beside the picture, 25 Nov 2026: "Fiel a la foto")
	"top": 25, "shirt": 0x8a4fb0, "shirt2": -1, "estampado": 1, "skin": 0xf3d2a8, "hair": 0x2a2626, "hair_style": 35,
	"canas": 1, "brows": 5, "brow_color": 0x9a9aa0, "eyes": 1, "eye_color": 0x3f7cc0, "lashes": 1, "nose": 1,      # (blue: the user, 25 Nov 2026, "Ojos azules estaría bien")
	"earrings": 5, "pendant": 0, "shoe_type": 13, "shoes": 0x6a4630,
	"scale": 0.9, "build": 1.18, "hat": "", "carro": true, "carro_color": 0x9a3a3a,
}
const PESCADERA_LOOK := {        # (La Pescadera: the user's name for whoever tells you of the ban, 25 Nov 2026; on the till
	"top": 24, "shirt": 0xf4f4f0, "skin": 0xeec29e, "hair": 0x6a4a2e, "hair_style": 1,       # while her fish counter is shut)
	"brows": 0, "eyes": 1, "eye_color": 0x4a3424, "earrings": 3, "scale": 0.95, "build": 1.1, "hat": "", "shoe_type": 1, "shoes": 0xf4f4f0,
}
# Calle del Arroyuelo Medio, from its north end by the Arroyuelo Alto down past the old bridge to the Arroyuelo Bajo
const ARROYO := [Vector2(-262.0, -436.0), Vector2(-202.0, -375.0), Vector2(-166.0, -310.0), Vector2(-141.0, -249.0),
	Vector2(-149.0, -191.0), Vector2(-175.0, -143.0), Vector2(-197.0, -91.0), Vector2(-230.0, -28.0)]
const MAGDALENA := Vector2(-534.0, -404.0)          # her house: the Plaza de la Magdalena's corner, Calle Silos de la Magdalena
const SHOPS := ["mercamona", "masahorro", "todopizza", "toti", "teledurum", "chinos", "asador", "kebabdeluxe", "noche",
	"maxiprecio", "pisacastana", "tetoqa", "rize"]   # (never the Merkocarry: she is banned)
const FISH_TAG := "pili_bacaladitos"

var G
var n                               # La Pili (npc.gd)
var cajera                          # La Pescadera, on the Merkocarry's first till (npc.gd)
var _t := 0.0
var _route_i := 0
var _route_dir := 1
var _chasing := false
var _bark_t := 0.0
var _bark_i := 0
var _after_i := 0
var _cajera_i := 0
var _wander_t := 0.0
var _wander_i := 0
var _was_in_shop := false
var _told := false                  # (the cashier has told you why she is banned, this time round)
var _posters: Array = []

func setup(game) -> void:
	G = game
	n = G._make_npc("pili", PILI_LOOK.duplicate(), "old_f", _kerb(ARROYO[0]))
	n.still = true
	n.home = n.p
	n.away = true
	n.visible = false
	var t = _tienda()
	if t != null:
		cajera = G._make_npc("pescadera", PESCADERA_LOOK.duplicate(), "adult_f", t.spot(-6.4, 3.2))
		cajera.still = true
		cajera.home = cajera.p
		cajera.h = PI / 2.0                     # (facing her till, across the set)
		cajera.sync()
		_put_posters(t)
	restore()

func _tienda():
	var m = G.world.get("merkocarry") if G != null and G.get("world") != null else null
	return m.tienda if m != null and m.get("tienda") != null else null

func stage() -> String:
	return String(G.stats.get("pili", "")) if G != null else ""

func _set_stage(s: String) -> void:
	G.stats["pili"] = s
	if active():
		G.side["stage"] = s

func done() -> bool:
	return stage() == "done"

func active() -> bool:
	return G != null and G.side != null and G.side.get("id", "") == "pili"

## she is in the town once Tía Paca has told you of the inheritance and how to earn money (fondo_casa.gd "casa_curro")
func met() -> bool:
	if G == null or G.chavisca or not bool(G.stats.get("curro", false)):
		return false
	var fc = G.get("fondo_casa")
	return fc == null or not bool(fc.get("_tour"))

func restore() -> void:
	_chasing = false
	_told = false
	if G.pickups != null:
		G.pickups.remove_tag(FISH_TAG)
	var st := stage()
	if st == "fetch" or st == "give":
		G.side = {"id": "pili", "who": "pili", "stage": st}
		if st == "fetch" and in_shop():
			_spawn_fish()
	_sync_presence(true)

func _kerb(pos: Vector2) -> Vector2:
	var r: Dictionary = MapData.nearest_road(pos, true)
	var u: Vector2 = r["u"]
	var side := 1.0 if (pos - r["p"]).dot(G._perp(u)) >= 0.0 else -1.0
	return r["p"] + G._perp(u) * minf(r["seg"].hw + 1.1, maxf(1.0, MapData.side_room(r) - 0.7)) * side

func _route(i: int) -> Vector2:
	return _kerb(ARROYO[clampi(i, 0, ARROYO.size() - 1)])

func _house() -> Vector2:
	return _kerb(MAGDALENA)

## the doors she goes round after her errand
func _shop_doors() -> Array:
	var out: Array = []
	for k in SHOPS:
		var o = G.world.get(k)
		if o != null and o.get("door") != null and (o.door as Vector2) != Vector2.ZERO:
			out.append(_kerb(o.door))
	if out.is_empty():
		out.append(_route(0))
	return out

func _sync_presence(force := false) -> void:
	if n == null or not is_instance_valid(n):
		return
	var st := stage()
	var day: bool = float(G.clock) >= 8.0 and float(G.clock) < 22.0
	var want := met() and (st == "fetch" or st == "give" or day)       # (with her errand under way she waits at home, any hour)
	if not want:
		if not n.away and (force or not G.sees(n.p)):
			n.away = true
			n.visible = false
			_chasing = false
		return
	if n.away:
		var at: Vector2
		if st == "fetch" or st == "give":
			at = _house()
		elif st == "done":
			var doors := _shop_doors()
			at = doors[_wander_i % doors.size()]
		else:
			at = _route(_route_i)
		if force or not G.sees(at):
			n.away = false
			n.visible = true
			n.p = at
			n.home = at
			n.still = true
			n.state = "idle"
			n.sync()

func _spawn_fish() -> void:
	var t = _tienda()
	if t == null or G.pickups == null:
		return
	G.pickups.spawn("bacaladitos", t.spot(-4.75, 2.5), {
		"tag": FISH_TAG,                         # (auto: taken with the action button, like any other thing to pick up)
		"indoors": true,
		"label": Loc.t("inv_n_bacaladitos"),
		"on_take": _fish_taken,
	})

func in_shop() -> bool:
	var t = _tienda()
	return t != null and G.indoors and (G.inside_of == t or (t.get("back") != null and G.inside_of == t.back))

func tick(dt: float, pp: Vector2) -> void:
	var inside_now := in_shop()
	if inside_now and not _was_in_shop:
		if stage() == "fetch":
			_spawn_fish()
			show()
		if cajera != null and is_instance_valid(cajera) and stage() != "fetch":
			cajera.bark(Loc.t("pescadera_hola").pick_random(), 3.5)
	elif not inside_now and _was_in_shop:
		if G.pickups != null:
			G.pickups.remove_tag(FISH_TAG)
		if active():
			show()
	_was_in_shop = inside_now
	_t -= dt
	if _t > 0.0:
		return
	_t = EVERY
	_sync_presence(false)
	if n == null or not is_instance_valid(n) or n.away:
		return
	var st := stage()
	if st == "fetch" or st == "give":
		var house := _house()
		n.home = house
		if n.p.distance_to(house) > 40.0 and not G.sees(n.p) and not G.sees(house):      # (gone home while you were not looking:
			n.p = house                                                                    # past 185 m nobody walks at all)
			n.sync()
		return
	var talking: bool = G.dlg != null or G._ask != null
	if talking:
		n.home = n.p
		return
	if st == "":
		_chase_tick(pp)
		if _chasing:
			return
		if n.p.distance_to(n.home) < 1.2:                # on along the Arroyuelo, up and back
			if _route_i + _route_dir < 0 or _route_i + _route_dir >= ARROYO.size():
				_route_dir = -_route_dir
			_route_i += _route_dir
			n.home = _route(_route_i)
		return
	# done: from one shop's door to the next, a while at each
	_wander_t -= EVERY
	if _wander_t <= 0.0:
		_wander_t = WANDER_STAY
		var doors := _shop_doors()
		_wander_i = (_wander_i + 1) % doors.size()
		n.home = doors[_wander_i]

## "si estás cerca del NPC te perseguirá andando y murmurándote que tiene que hablar contigo, oye tú y tal"
func _chase_tick(pp: Vector2) -> void:
	var free_hands: bool = G.side == null and not G.in_mission() and G.comida.faint == null
	var d: float = n.p.distance_to(pp)
	var can: bool = free_hands and G.in_car == null and not G.indoors and (G.phase == "play" or G.phase == "free")
	if not _chasing:
		if can and d < CHASE_NEAR:
			_chasing = true
			_bark_t = 0.0
		else:
			return
	if not can or d > CHASE_GIVE_UP:
		_chasing = false
		n.home = _route(_route_i)
		return
	var to_her: Vector2 = (n.p - pp).normalized() if d > 0.01 else Vector2.RIGHT
	n.home = pp + to_her * 1.5                  # (right up to you, not into you)
	_bark_t -= EVERY
	if _bark_t <= 0.0:
		_bark_t = BARK_EVERY
		var pool: Array = Loc.t("pili_chase")
		n.bark(pool[_bark_i % pool.size()], 3.2)
		_bark_i += 1

func chasing() -> bool:
	return _chasing

func givers(free_hands: bool) -> Array:
	if n == null or not is_instance_valid(n) or n.away:      # (not `visible`: past 185 m everybody is hidden, and she still has
		return []                                            # her errand for the map and for Tía Paca's call, fondo_casa.gd _ocio)
	var st := stage()
	if st == "give":
		return [n]
	if st == "" and free_hands:
		return [n]
	return []

func show() -> void:
	if not active():
		return
	var st := stage()
	var t = _tienda()
	if st == "fetch":
		G.hud.set_objective(G._tag(), Loc.t("obj_pili_fetch"))
		if in_shop() and t != null:
			G.set_target(t.spot(-4.75, 2.5), false)
		else:
			var m = G.world.get("merkocarry")
			if m != null:
				G.set_target(m.door, false)
	elif st == "give":
		G.hud.set_objective(G._tag(), Loc.t("obj_pili_give"))
		if n != null and is_instance_valid(n):
			G.set_target(n.p if not n.away else _house(), false)

func abort() -> void:
	if active():
		G.side = null
	if stage() == "fetch":
		_set_stage("")
	if G.pickups != null:
		G.pickups.remove_tag(FISH_TAG)

## picked up at the till: the cashier has something to say about it
func _fish_taken() -> void:
	_set_stage("give")
	show()
	if cajera != null and is_instance_valid(cajera) and not _told:
		_told = true
		G.say(cajera.shown_name(), Loc.t("pescadera_pili"), cajera.voice)

func talk(who) -> bool:
	if who == null:
		return false
	if who.id == "pescadera":
		var lines: Array
		if stage() == "fetch":
			lines = Loc.t("pescadera_fetch")
		elif stage() == "give" or stage() == "done":
			lines = Loc.t("pescadera_pili_after")
		else:
			var pool: Array = Loc.t("pescadera_idle")
			lines = pool[_cajera_i % pool.size()]
			_cajera_i += 1
		G.say(who.shown_name(), lines, who.voice)
		return true
	if who.id != "pili":
		return false
	_chasing = false
	var st := stage()
	if st == "give":
		_finish(who)
		return true
	if st == "fetch":
		G.say(who.shown_name(), Loc.t("pili_wait"), who.voice)
		return true
	if st == "done":
		var pool: Array = Loc.t("pili_after")
		var lines: Array = pool[_after_i % pool.size()]
		_after_i += 1
		G.say(who.shown_name(), lines, who.voice)
		return true
	if G.side != null or G.in_mission() or G.comida.faint != null:
		G.say(who.shown_name(), Loc.t("pili_busy"), who.voice)
		return true
	var prev_phase: String = G.phase
	G.say(who.shown_name(), Loc.t("pili_intro"), who.voice, func():
		G.say(who.shown_name(), Loc.t("pili_ask"), who.voice, func():
			G.ask(who, who.shown_name(), Loc.t("pili_ask_q"), [
				[Loc.t("pili_opt_yes"), func():
					G.phase = prev_phase
					_accept(who)],
				[Loc.t("pili_opt_no"), func():
					G.phase = prev_phase
					_decline(who)],
			])))
	return true

func _accept(who) -> void:
	_set_stage("fetch")
	G.side = {"id": "pili", "who": "pili", "stage": "fetch"}
	_told = false
	G.hud.show_card(Loc.t("pili_title"), "")
	Sfx.jingle([392, 523, 659, 784])
	n.home = _house()
	show()
	G.say(who.shown_name(), Loc.t("pili_yes"), who.voice)

func _decline(who) -> void:
	G.folk.add("pili", -5)
	Sfx.beep(196.0, 0.22, 1, -12.0)
	G.say(who.shown_name(), Loc.t("pili_no"), who.voice)

## "me has traído los bacaladitos? bendito seas" ... "…." ... "esto es una puta panga?" -- and +50 €, +30 P.C.
func _finish(who) -> void:
	_set_stage("done")
	if active():
		G.side = null
	G.money += PAY
	G._refresh_counts()
	G.hud.stamp(Loc.t("stamp_done"))
	Sfx.jingle([523, 659, 784, 1047], 0.12)
	G.folk.add("pili", 5)
	G.add_pc(PC, true)
	G._mission_done()
	_wander_t = WANDER_STAY
	G._show_step()
	G.say(who.shown_name(), Loc.t("pili_done"), who.voice)

# ---------------- the poster: her photo crossed out, "PROHIBIDA LA ENTRADA" ----------------
## On the front of the first till (seen as you come in) and on the wall by the front doors (seen as you go out).
func _put_posters(t) -> void:
	for at in [[Vector3(-5.5, 0.47, 1.594), PI], [Vector3(2.4, 1.5, 0.036), 0.0]]:
		var root := Node3D.new()
		root.position = at[0]
		root.rotation.y = at[1]
		t.add_child(root)
		var paper := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.62, 0.78)
		paper.mesh = q
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(1, 1, 1)
		m.roughness = 0.9
		paper.material_override = m
		paper.layers = 1 << 10
		root.add_child(paper)
		var words := Label3D.new()
		words.text = Loc.t("pili_cartel")
		words.font_size = 22
		words.pixel_size = 0.0028
		words.modulate = Color(0.78, 0.08, 0.1)
		words.outline_size = 0
		words.double_sided = false
		words.position = Vector3(0.0, -0.31, 0.004)
		words.width = 200.0
		words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		root.add_child(words)
		_posters.append(m)
	_poster_photo()

func _poster_photo() -> void:
	var img: Image = null
	if DisplayServer.get_name() != "headless":
		var vp: SubViewport = Portrait.viewport(PILI_LOOK, Vector2i(120, 148))
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		G.add_child(vp)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		img = vp.get_texture().get_image() if vp.get_texture() != null else null
		vp.queue_free()
	var tex := ImageTexture.create_from_image(poster_image(img))
	for m in _posters:
		(m as StandardMaterial3D).albedo_color = Color.WHITE
		(m as StandardMaterial3D).albedo_texture = tex

## white paper, her photo up top and a fat red cross over it (the words go under it, a Label3D)
static func poster_image(photo: Image) -> Image:
	var w := 124
	var h := 156
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.97, 0.96, 0.93))
	var px := Rect2i(12, 10, 100, 110)
	if photo != null and not photo.is_empty():
		var ph := photo.duplicate() as Image
		ph.convert(Image.FORMAT_RGBA8)
		ph.resize(px.size.x, px.size.y, Image.INTERPOLATE_BILINEAR)
		out.blit_rect(ph, Rect2i(Vector2i.ZERO, px.size), px.position)
	else:
		out.fill_rect(px, Parts.col(int(PILI_LOOK["shirt"])))
	for x in range(px.position.x - 1, px.end.x + 1):        # a black edge round the photo
		out.set_pixel(x, px.position.y - 1, Color.BLACK)
		out.set_pixel(x, px.end.y, Color.BLACK)
	for y in range(px.position.y - 1, px.end.y + 1):
		out.set_pixel(px.position.x - 1, y, Color.BLACK)
		out.set_pixel(px.end.x, y, Color.BLACK)
	var red := Color(0.82, 0.07, 0.09)
	for k in range(px.size.x):                              # the cross, corner to corner, 7 px thick
		var fy0: float = px.position.y + float(k) * px.size.y / px.size.x
		var fy1: float = px.end.y - 1 - float(k) * px.size.y / px.size.x
		for t in range(-3, 4):
			var x: int = px.position.x + k
			out.set_pixel(x, clampi(int(fy0) + t, 0, h - 1), red)
			out.set_pixel(x, clampi(int(fy1) + t, 0, h - 1), red)
	return out
