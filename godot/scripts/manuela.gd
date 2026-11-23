extends RefCounted
## Manuela Moreno, the clerk of the Pisacastaña, the shoe shop of the Calle de los Arcos and the Calle Argentina. The
## shop and its inside are Pretil's (pisacastana.gd, pisacastana_dentro.gd); she is ours.
##
## What the user asked for, 23 November 2026:
##   - the shop: "Mismo tratamiento que las otras dos tiendas pero solo con zapatos";
##   - when asked whether to give it a clerk with lines like Maxi's and a shoe picker on its bench: "Las dos opciones
##     me gustan";
##   - her name: "Manuela Moreno";
##   - the price: every shoe at 20 €.
## Her lines play on the shop's name as Maxi's do on his ("pisaprecios", "pisaofertas", "¡pisa fuerte!").
##
## How she works:
##   - She stands behind the counter while the shop is open (its dentro: clerk_spot, clerk_h).
##   - Talked to, she says a line, then asks "¿te pruebas algo?". Say yes and the bench opens: the fitting room's
##     screen (game.gd open_shop_ropa) with every shoe of the creator but going barefoot, in the colour you choose
##     (LT / RT, Z / X), PRICE each, what you buy straight to your wardrobe at home. You try them on by the low floor
##     mirror (probador_spot, probador_h); the pictures are of your feet (ropa_icono.gd).
##   - Until the inside is built, she is not anywhere.
## Her look goes with the shop: the turquoise of its tiles and the cream of its awnings, her hair chestnut ("castaña").

const PRICE := 20
const SHOE := 17                # the creator's options for the shoes and their colour (Creator.OPTIONS "shoe_type", "shoes")
const SHOE_COLOUR := 18
const LOOK := {
	"top": 16, "shirt": 0x2fa59a, "shirt2": 0xf3e3c3, "skin": 0xf0c8a0, "hair": 0x6a3a22, "hair_style": 28, "brows": 1,
	"eyes": 1, "eye_color": 0x4a3424, "lashes": 1, "earrings": 1, "face": 0, "glasses": 0, "shoe_type": 9, "shoes": 0x6a3a22,
	"build": 1.0, "scale": 0.96, "hat": "",
}

var G
var n                           # Manuela (npc.gd)
var _t := 0.0
var _chat_i := 0

func setup(game) -> void:
	G = game
	var d = _inside()
	if d == null:
		return
	n = G._make_npc("manuela", LOOK.duplicate(), "adult_f", _clerk_spot())
	n.still = true
	n.away = true
	n.visible = false

func _shop():
	return G.world.get("pisacastana") if G != null and G.get("world") != null else null

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
	if who == null or who.id != "manuela":
		return false
	var first: bool = not G.stats.has("manuela")
	if first:
		G.stats["manuela"] = int(G.day_n)
		G.folk.meet("manuela")
	var lines: Array
	if first:
		lines = Loc.t("manuela_hello")
	else:
		var pool: Array = Loc.t("manuela_chat")
		lines = pool[_chat_i % pool.size()]
		_chat_i += 1
	G.say(who.shown_name(), lines, who.voice, func(): _offer(who))
	return true

func _offer(who) -> void:
	var prev: String = G.phase
	G.ask(who, who.shown_name(), Loc.t("manuela_q") % PRICE, [
		[Loc.t("manuela_yes"), func():
			G.phase = prev
			try_on()],
		[Loc.t("manuela_no"), func():
			G.phase = prev
			G.say(who.shown_name(), [Loc.t("manuela_bye").pick_random()], who.voice)],
	])

## onto the bench
func try_on() -> void:
	var f: Array = fitting()
	G.open_shop_ropa(f[0], f[1], Vector2.ZERO, PRICE, n, {"opt": SHOE, "col": SHOE_COLOUR, "title": "arm_shop_title_zapatos",
		"poor": "manuela_poor", "bought": "manuela_bought", "have": "arm_have_zapatos", "have_btn": "arm_have_btn_zapatos"})
