extends RefCounted
## Places of the town that you have restored with Puntos Cívicos, standing before their doors: the prompt says what it
## costs and the action button pays (as the old bridge is unlocked: game.gd _unlock_bridge). What is paid goes in the
## game's stats, and so in its save; begin() leaves each place as the game that begins has it.
##
##   toros      the old bullring (toros.gd: the ruin, or restored), 15 P.C. before its boarded door, reached through the
##              gate left open on Vista Alegre. The user, 25 November 2026: "Añade también la plaza de toros para
##              arreglar igual 15 P.C." ("igual": like the Sala Cavernas, whose 30 P.C. are in fiesta.gd with its nights
##              and its people).
##
## In the free mode there are no Puntos Cívicos to pay with, so every place is restored there from the start (as the
## Sala Cavernas is, by the user's word, and as the bridge is open). A stopgap until each has its mission (the user,
## of the Sala Cavernas: "De momento ... luego ya daremos misión").

const REACH := 4.5                    # how near the door you pay
const PLACES := {
	"toros": {"cost": 15, "key": "toros_arreglada", "prompt": "p_toros", "done": "t_toros_open", "flag": "--toros-restaurada"},
}

var G

func setup(game) -> void:
	G = game

## the place itself (its script has `restored` and set_restored), or null on a map baked before it
func place(id: String):
	match id:
		"toros":
			return G.world.get("toros") if G.world != null else null
	return null

## where you stand to pay for it, on the map
func spot(id: String) -> Vector2:
	var pl = place(id)
	match id:
		"toros":
			var d: Vector2 = pl._p(float(pl.DOOR) + 2.57, float(pl.R) + 3.0)      # (before its door, outside)
			return pl.spot(d.x, d.y)
	return Vector2.ZERO

## a game begins or is loaded: each place as that game has it
func begin() -> void:
	for id in PLACES:
		var pl = place(id)
		if pl == null:
			continue
		var want: bool = G.stats.has(PLACES[id]["key"]) or G.chavisca or OS.get_cmdline_user_args().has(PLACES[id]["flag"])
		if pl.restored != want:
			pl.set_restored(want)

## the place you could pay for where you stand ("" if none): on foot, once you know what the Puntos Cívicos are for
func here() -> String:
	if G.chavisca or not G.pc_on() or not (G.phase == "play" or G.phase == "free") or G.in_car != null or G.dlg != null or G.indoors:
		return ""
	for id in PLACES:
		var pl = place(id)
		if pl != null and not pl.restored and G.player.p.distance_to(spot(id)) < REACH:
			return id
	return ""

func can_fix() -> bool:
	return here() != ""

func prompt() -> String:
	var id := here()
	return "" if id == "" else Loc.t(PLACES[id]["prompt"]) % int(PLACES[id]["cost"])

func fix() -> void:
	var id := here()
	if id == "":
		return
	var cost: int = int(PLACES[id]["cost"])
	if G.pc < cost:
		G.hud.toast(Loc.t("t_puente_short") % [cost, G.pc], 4.0)
		Sfx.beep(220.0, 0.2, 1, -12.0)
		return
	G.pc -= cost
	G.stats[PLACES[id]["key"]] = true
	G._refresh_counts()
	place(id).set_restored(true)
	Sfx.noise(0.5, -12.0)
	Sfx.jingle([523, 659, 784, 1047, 1319], 0.1)
	G.shake = 0.25
	G.hud.toast(Loc.t(PLACES[id]["done"]), 7.0)
