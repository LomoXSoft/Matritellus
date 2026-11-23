extends RefCounted
## Fátima Corsa, the optician of the Óptica Corsa, Calle del Salvador 5. The shop and its inside are Pretil's (optica.gd,
## optica_dentro.gd); she is ours.
##
## What the user asked for, 23 November 2026 (through Pretil): "aquí el NPC será una Óptica con bata blanca y solo
## venderá gafas. Y te dirá cosas sobre graduarte la vista, parece que tienes estrabismo, tengo modelos nuevos y vintage
## y tal. Se llamará Fátima Corsa." Glasses are the opticians' only ("gafas en las ópticas y complementos en las
## tiendas de complementos": tiendas_ropa.gd).
##
## How she works (as Manuela at the Pisacastaña, manuela.gd):
##   - She stands behind the counter while the shop is open (its dentro: clerk_spot, clerk_h).
##   - Talked to, she says a line, then asks whether you want to try a pair. Say yes and the mirror opens: the fitting
##     room's screen (game.gd open_shop_ropa) with every pair of glasses of the creator but none, the pirate's patch
##     too ("también añadiría parche en el ojo, ya que lo considero cosa de ojos": the user, 23 Nov 2026), PRICE each
##     (20 €), no colour to choose (they come in their own), the pictures of your face (ropa_icono.gd), what you buy
##     straight to your wardrobe at home. You try them on at its mirror (probador_spot, probador_h).
##   - The first pair is hers (the user, the same day: "Cuando Fátima te termine las pruebas dirá que te regala las
##     primeras gafas, que te ha visto cara de pobre además de cegato. Si quieres más tendrás que pagarlas"): the first
##     time, she tests your eyes and says so (fatima_test); till you take a pair (stats GIFT) the mirror opens at 0 €,
##     and the moment you take one, the rest go back to PRICE.
##   - Until the inside is built, she is not anywhere.
## PRICE: 20 € for now, as everything, until the user sets the prices.

const PRICE := 20             # (the user, 23 Nov 2026: "De momento todo a 20€ hasta que decida precios")
const GLASSES := 12             # the creator's option for glasses (Creator.OPTIONS "glasses")
const SKIP := []                # (none: the pirate's patch too, "cosa de ojos")
const GIFT := "fatima_regalo"   # stats: the day you took the pair she gave you
const LOOK := {
	"top": 24, "shirt": 0xf8f8f8, "skin": 0xf3cfae, "hair": 0x2a1c14, "hair_style": 22, "brows": 0,
	"eyes": 0, "eye_color": 0x3f7d4a, "lashes": 1, "earrings": 1, "face": 0, "glasses": 7, "shoe_type": 5, "shoes": 0x1b1b1f,
	"build": 1.0, "scale": 0.95, "hat": "",
}

var G
var n                           # Fátima (npc.gd)
var _t := 0.0
var _chat_i := 0

func setup(game) -> void:
	G = game
	var d = _inside()
	if d == null:
		return
	n = G._make_npc("fatima", LOOK.duplicate(), "adult_f", _clerk_spot())
	n.still = true
	n.away = true
	n.visible = false

func _shop():
	return G.world.get("optica") if G != null and G.get("world") != null else null

func _inside():
	var s = _shop()
	return s.get("dentro") if s != null else null

func open() -> bool:
	var d = _inside()
	if d != null and d.get("open") != null:
		return bool(d.open)
	var s = _shop()
	return s != null and s.has_method("open_at") and bool(s.open_at(int(G.weekday), float(G.clock)))

## where she stands: behind the dentro's counter; until it says, a few steps in from the door
func _clerk_spot() -> Vector2:
	var d = _inside()
	if d == null:
		return Vector2.ZERO
	if d.get("clerk_spot") != null:
		return d.clerk_spot
	return G.entradas.spot(d, true) + Vector2(0.0, -3.0)

## where you try them on: [spot, the way you face]
func fitting() -> Array:
	var d = _inside()
	if d != null and d.get("probador_spot") != null:
		return [d.probador_spot, float(d.probador_h) if d.get("probador_h") != null else 0.0]
	var to_her: Vector2 = (n.p - G.player.p) if n != null else Vector2(0.0, 1.0)
	return [G.player.p, atan2(-to_her.x, -to_her.y)]

func tick(dt: float) -> void:
	_t -= dt
	if _t > 0.0:
		return
	_t = 0.5
	if n == null or not is_instance_valid(n):
		return
	var d = _inside()
	if open() and n.away:
		var at := _clerk_spot()
		n.away = false
		n.visible = true
		n.p = at
		n.home = at
		n.h = float(d.clerk_h) if d.get("clerk_h") != null else n.h
		n.sync()
	elif not open() and not n.away and not (G.indoors and G.inside_of == d):
		n.away = true
		n.visible = false

func talk(who) -> bool:
	if who == null or who.id != "fatima":
		return false
	var first: bool = not G.stats.has("fatima")
	if first:
		G.stats["fatima"] = int(G.day_n)
		G.folk.meet("fatima")
	var lines: Array
	if first:
		lines = (Loc.t("fatima_hello") as Array) + (Loc.t("fatima_test") as Array)
	else:
		var pool: Array = Loc.t("fatima_chat")
		lines = pool[_chat_i % pool.size()]
		_chat_i += 1
	G.say(who.shown_name(), lines, who.voice, func(): _offer(who))
	return true

func _offer(who) -> void:
	var prev: String = G.phase
	G.ask(who, who.shown_name(), Loc.t("fatima_q_free") if gift_due() else Loc.t("fatima_q") % PRICE, [
		[Loc.t("fatima_yes"), func():
			G.phase = prev
			try_on()],
		[Loc.t("fatima_no"), func():
			G.phase = prev
			G.say(who.shown_name(), [Loc.t("fatima_bye").pick_random()], who.voice)],
	])

## is the pair she gives you still to take?
func gift_due() -> bool:
	return not G.stats.has(GIFT)

## to the mirror (free till you take the pair she gives you: then PRICE, and her line)
func try_on() -> void:
	var f: Array = fitting()
	var kind := {"opt": GLASSES, "col": -1, "skip": SKIP, "title": "arm_shop_title_gafas",
		"poor": "fatima_poor", "bought": "fatima_bought", "have": "arm_have_gafas", "have_btn": "arm_have_btn_gafas"}
	if gift_due():
		kind["free"] = {"stat": GIFT, "then": PRICE, "line": "fatima_gift"}
	G.open_shop_ropa(f[0], f[1], Vector2.ZERO, 0 if gift_due() else PRICE, n, kind)
