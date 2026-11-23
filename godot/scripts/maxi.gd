extends RefCounted
## Maxi, the clerk of the MaxiPrecio (the user, 23 November 2026: "Haz un dependiente para el MaxiPrecio, que se llame
## Maxi y diga muchas frases con maxi (maxiprecios, maxiofertas, maxidias, ...). Que aquí se pueda comprar de momento
## toda la ropa (no zapatos ni complementos ni gorras) y vaya directa al armario del jugador, que de momento todo valga
## 20€"). The shop and its inside are Pretil's (maxiprecio.gd, maxiprecio_dentro.gd); he is ours.
##
##   - He stands at his till inside while the shop is open (its dentro: clerk_spot, clerk_h).
##   - Talked to, a line full of maxis, then "¿te pruebas algo?": yes, and the fitting room opens (game.gd
##     open_shop_ropa: the wardrobe's screen with every garment, PRICE each, what you buy straight to your wardrobe at
##     home); you try them on where the dentro says (probador_spot, probador_h).
##   - Until the inside is built, he is not anywhere.

const PRICE := 20
const LOOK := {
	"top": 1, "shirt": 0x2456c9, "shirt2": 0xf3f3f3, "skin": 0xeec39d, "hair": 0x1d1612, "hair_style": 8, "brows": 1,
	"eyes": 1, "eye_color": 0x3a2a20, "face": 1, "glasses": 0, "build": 1.15, "scale": 0.98, "hat": "",
}

var G
var n                           # Maxi (npc.gd)
var _t := 0.0
var _chat_i := 0

func setup(game) -> void:
	G = game
	var d = _inside()
	if d == null:
		return
	n = G._make_npc("maxi", LOOK.duplicate(), "adult_m", _clerk_spot())
	n.still = true
	n.away = true
	n.visible = false

func _shop():
	return G.world.get("maxiprecio") if G != null and G.get("world") != null else null

func _inside():
	var s = _shop()
	return s.get("dentro") if s != null else null

func open() -> bool:
	var d = _inside()
	if d != null and d.get("open") != null:
		return bool(d.open)
	var s = _shop()
	return s != null and s.has_method("open_at") and bool(s.open_at(int(G.weekday), float(G.clock)))

## where he stands: the dentro's till; until it says, a few steps in from the door
func _clerk_spot() -> Vector2:
	var d = _inside()
	if d == null:
		return Vector2.ZERO
	if d.get("clerk_spot") != null:
		return d.clerk_spot
	return G.entradas.spot(d, true) + Vector2(0.0, -3.0)

## where you try things on: [spot, the way you face]
func fitting() -> Array:
	var d = _inside()
	if d != null and d.get("probador_spot") != null:
		return [d.probador_spot, float(d.probador_h) if d.get("probador_h") != null else 0.0]
	var to_him: Vector2 = (n.p - G.player.p) if n != null else Vector2(0.0, 1.0)
	return [G.player.p, atan2(-to_him.x, -to_him.y)]

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
	if who == null or who.id != "maxi":
		return false
	var first: bool = not G.stats.has("maxi")
	if first:
		G.stats["maxi"] = int(G.day_n)
		G.folk.meet("maxi")
	var lines: Array
	if first:
		lines = Loc.t("maxi_hello")
	else:
		var pool: Array = Loc.t("maxi_chat")
		lines = pool[_chat_i % pool.size()]
		_chat_i += 1
	G.say(who.shown_name(), lines, who.voice, func(): _offer(who))
	return true

func _offer(who) -> void:
	var prev: String = G.phase
	G.ask(who, who.shown_name(), Loc.t("maxi_q") % PRICE, [
		[Loc.t("maxi_yes"), func():
			G.phase = prev
			try_on()],
		[Loc.t("maxi_no"), func():
			G.phase = prev
			G.say(who.shown_name(), [Loc.t("maxi_bye").pick_random()], who.voice)],
	])

## into the fitting room
func try_on() -> void:
	var f: Array = fitting()
	G.open_shop_ropa(f[0], f[1], Vector2.ZERO, PRICE, n)
