extends RefCounted
## Marciano (the user, 21 November 2026, through Pretil, who builds the café and its alley): "Enfrente habrá un NPC
## con bigote, hermoso, y peinado tupé negro que se llamará Marciano. De momento será solo un NPC que hablará que los
## jóvenes de hoy no tienen ni idea de lo que es una verdadera fiesta, y hablará de las locuras de los 80 y la ruta del
## bacalao."
##
##   He stands across from the café (G.world.rize, the Cafetería Rize: marciano_spot, marciano_h) all day, and talks: each time a
##   different tale. No mission for now. Until the café is built, he is not anywhere.

const LOOK := {
	"top": 1, "shirt": 0x5b3a6e, "skin": 0xe8b98f, "hair": 0x141210, "hair_style": 8, "face": 4, "brows": 1,
	"eyes": 0, "eye_color": 0x2a1c14, "glasses": 0, "scale": 0.98, "build": 1.3, "hat": "", "pendant": 3,
}

var G
var n
var _i := 0

func setup(game) -> void:
	G = game
	var c = G.world.get("rize") if G.get("world") != null else null
	if c == null or not (c.get("marciano_spot") is Vector2):
		return
	n = G._make_npc("marciano", LOOK.duplicate(), "adult_m", c.marciano_spot)
	n.still = true
	n.home = c.marciano_spot
	if c.get("marciano_h") != null:
		n.h = float(c.marciano_h)
	n.sync()

func talk(who) -> bool:
	if who == null or who.id != "marciano":
		return false
	var pool: Array = Loc.t("marciano_talk")
	G.say(who.shown_name(), pool[_i % pool.size()], who.voice)
	_i += 1
	G.folk.meet("marciano")
	return true
