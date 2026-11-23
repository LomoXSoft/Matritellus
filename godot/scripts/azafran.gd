extends RefCounted
## The saffron sellers (the user, 23 November 2026): "el azafrán será el único objeto que se coge al pasar por encima y
## dejará de dar dinero. Se pasará a vender a uno de los NPCs de venta de azafrán que se ubicarán en la puerta de los
## sitios reales de azafrán de Madridejos". Four of them, for now the same model and called Vendedor Azafrán 1 to 4, at
## the doors of the real saffron sellers of the town (the addresses are the user's; Catastro gave the parcels, as
## tools/locate.py does). Until Tía Paca has told you about the tax debt and how to earn money (fondo_casa.gd, "curro")
## they are not there; then they stand at their doors and a saffron circle marks each on the map.
##
##   1  Calle de Máximo García de la Torre 34 (Azafrán 1994)
##   2  Polígono San Sebastián, Calle Curtidores, parcela 27 (Zaffralia)
##   3  Calle de Santiago Apóstol 5 A (Azafrán Estigma Rojo)
##   4  across from the door that says MUSEO at the Petril, Calle de las Cruces 9 (Museo del Azafrán)
##
## Talking to one with saffron on you sells all of it, at PRICE a flower (50 €, the user's price;
## until 23 Nov 2026 a flower paid 6 € when you picked it). What you have picked and sold is kept in G.stats: "azafran_cogido" (every flower ever) and "azafran_vendido"
## (euros made from it); the flowers on you are G.saffron, as before.

const PRICE := 50                # a flower (the user, 23 Nov 2026: "El azafrán que se pague a 50€ la flor")
const LOOK := {
	"top": 1, "shirt": 0x7a1f2b, "shirt2": 0xf3e3c3, "skin": 0xe9b58c, "hair": 0x2a1c14, "hair_style": 0,
	"brows": 1, "eyes": 0, "eye_color": 0x2a1c14, "face": 2, "build": 1.08, "scale": 1.0, "hat": "",
}
# where each stands: a point a few metres off the street towards the parcel (then on the pavement there, game.gd
# _pavement). Catastro's parcel middles, through tools/locate.py, 23 Nov 2026: 808, 45 / 545, -1769 / -607, -72 / -88, 275.
const TOWARDS := [Vector2(803.6, 44.8), Vector2(566.1, -1771.3), Vector2(-602.4, -90.2), Vector2(-93.0, 288.0)]
const HEAR := 9.0

var G
var sellers: Array = []          # npc.gd, in the order above
var spots: Array = []            # where they stand (Vector2)
var _t := 0.0

func setup(game) -> void:
	G = game
	for i in range(TOWARDS.size()):
		var at: Vector2 = G._pavement(TOWARDS[i])
		var face := Vector2.ZERO
		if i == 3:                                   # at the Petril: before its door that says MUSEO, looking out
			var m = _museo_door()
			if m != null:
				at = m[0]
				face = m[1]
		var n = G._make_npc("", LOOK.duplicate(), "adult_m", at)
		n.name_key = "n_azafran_%d" % (i + 1)
		n.still = true
		n.home = at
		n.set_meta("azafran", i)
		if face == Vector2.ZERO:
			var r: Dictionary = MapData.nearest_road(at, true)
			face = (r["p"] as Vector2) - at           # (looking at the street)
		if face.length() > 0.01:
			n.h = atan2(face.x, face.y)
		n.sync()
		sellers.append(n)
		spots.append(at)
	show()

## the Petril's MUSEO stone (petril.gd puts it over the convent's door as a Label3D): [where to stand, which way to look]
func _museo_door():
	var pt = G.world.get("petril") if G.get("world") != null else null
	if pt == null:
		return null
	for c in pt.get_children():
		if c is Label3D and String(c.text) == "MUSEO":
			var out: Vector3 = c.global_transform.basis.z.normalized()
			var flat := Vector2(out.x, out.z).normalized()
			var foot := Vector2(c.global_position.x, c.global_position.z)
			return [foot + flat * 1.6, flat]
	return null

func unlocked() -> bool:
	return G != null and bool(G.stats.get("curro", false))

## there or not, as the story stands (called when it changes, and on loading)
func show() -> void:
	var on := unlocked()
	for n in sellers:
		if is_instance_valid(n):
			n.away = not on
			n.visible = on

## the seller nearest a spot (for Tía Paca's camera)
func nearest(p: Vector2):
	var best = null
	var bd := INF
	for n in sellers:
		if is_instance_valid(n) and n.p.distance_to(p) < bd:
			bd = n.p.distance_to(p)
			best = n
	return best

## for the map: a saffron circle at each, once they are there
func marks() -> Array:
	return spots if unlocked() else []

func talk(n) -> bool:
	if n == null or not n.has_meta("azafran"):
		return false
	var have: int = int(G.saffron)
	if have <= 0:
		G.say(n.shown_name(), Loc.t("azafran_nada").pick_random(), n.voice)
		return true
	var pay: int = have * PRICE
	G.saffron = 0
	G.money += pay
	G.stats["azafran_vendido"] = int(G.stats.get("azafran_vendido", 0)) + pay
	G._refresh_counts()
	Sfx.jingle([659, 784, 988, 1319], 0.08)
	var line: String = Loc.t("azafran_venta").pick_random()
	G.say(n.shown_name(), [line % [have, pay]], n.voice)
	return true

## a flower picked (game.gd _take_flower): it counts for ever, whatever you do with it afterwards
func picked() -> void:
	G.stats["azafran_cogido"] = int(G.stats.get("azafran_cogido", 0)) + 1

func tick(dt: float, pp: Vector2) -> void:
	_t -= dt
	if _t > 0.0:
		return
	_t = 6.0
	if not unlocked():
		return
	for n in sellers:                                # now and then a call to whoever goes by
		if is_instance_valid(n) and not n.away and n.p.distance_to(pp) < HEAR and G.dlg == null and randf() < 0.35:
			n.bark(Loc.t("azafran_pregon").pick_random(), 3.0)
