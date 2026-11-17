extends RefCounted
## Feliciano (the user, 17 November 2026): a neighbour who is at every roast ham riot outside La Cocina de Henry
## (motin.gd: the first of them to bring out his weapon, the butcher's cleaver, in its close shot), and lives for it.
##
##   Where: the rest of the time he goes up and down the streets round the convent of the Poor Clares (santaana.gd),
##   a while at each of a few spots. On Thursdays, from eight in the morning until nine at night, while there is no
##   ham had yet that day, he waits at Henry's door, where the crowd stands.
##   What he says (Loc): on Thursdays he is beside himself ("feliciano_jueves"); any other day he is downcast, counting
##   the days still to go ("feliciano_semana", {dias}); and now and then he grumbles about the convent's bell, which
##   strikes every hour, every day, at all hours ("feliciano_campana"). All of it: an obsession with Thursday's ham.
##   Looks (the user): skin on the dark side, thick eyebrows, black hair, brown eyes, no beard.
##
## He is moved only where you cannot see him (from the convent to Henry's and back); round the convent he walks.

const LOOK := {"top": 1, "shirt": 0x6f7f5a, "skin": 0xc68a5c, "hair": 0x15110e, "hair_style": 2, "brows": 1, "eyes": 0,
	"eye_color": 0x4a2c18, "face": 0, "build": 1.12, "hat": ""}
const EVERY := 2.0              # seconds between looks at where he ought to be
const ROAM := 75.0              # seconds at each spot round the convent
const BELL := 0.25              # how often what he says is about the bell instead

var G
var n                           # himself (npc.gd)
var _t := 0.0
var _roam_t := 0.0
var _roam_i := 0
var _said := {}                 # key -> which of its talks is next

func setup(game) -> void:
	G = game
	var spots := roams()
	n = G._make_npc("feliciano", LOOK, "adult_m", spots[0])
	n.still = false

## the spots round the convent he goes between: on the pavement of the streets in front of and beside it
func roams() -> Array:
	var c = G.world.santaana if G.world != null else null
	var out: Array = []
	if c != null:
		for xy in [Vector2(36.0, 6.0), Vector2(8.0, 6.0), Vector2(62.0, 6.0)]:
			out.append(_kerb(c.spot(xy.x, xy.y)))
	else:                                            # (a map from before the convent: by Henry's, then)
		out.append(_kerb(G.places["henry"]["p"] + Vector2(30.0, 0.0)))
	return out

func _kerb(pos: Vector2) -> Vector2:
	var r: Dictionary = MapData.nearest_road(pos, true)
	var u: Vector2 = r["u"]
	var side := 1.0 if (pos - r["p"]).dot(G._perp(u)) >= 0.0 else -1.0
	return r["p"] + G._perp(u) * minf(r["seg"].hw + 1.1, maxf(1.0, MapData.side_room(r) - 0.7)) * side

## Thursday, from eight until nine at night, and no ham had there yet today: at Henry's door
func waiting() -> bool:
	return G.weekday == 3 and G.clock >= 8.0 and G.clock < 21.0 and int(G.stats.get("jamon_day", -1)) != int(G.day_n)

func tick(dt: float) -> void:
	if n == null or not is_instance_valid(n) or n.away:
		return
	_t -= dt
	if _t > 0.0:
		return
	_t = EVERY
	if G.motin != null and G.motin.has(n):           # (in the riot, or getting up after it: the riot has him)
		return
	if waiting():
		var door: Vector2 = G.motin._spot(1) if G.motin != null else n.home
		if n.p.distance_to(door) > 2.0:
			place(door, true)
		return
	_roam_t -= EVERY
	if n.still or _roam_t <= 0.0:
		_roam_t = ROAM
		var spots := roams()
		_roam_i = (_roam_i + 1) % spots.size()
		place(spots[_roam_i], false)

## where he goes: from far off (the convent to Henry's), only out of your sight; near, he walks there himself
func place(at: Vector2, stand: bool, now := false) -> void:
	var far: bool = n.p.distance_to(at) > 30.0
	if far and not now and (G.sees(n.p) or G.sees(at)):
		return
	if far or now:
		n.p = at
		n.global_position = MapData.at(at, MapData.foot(at) - MapData.height(at))
		n.state = "idle"
	n.home = at
	n.still = stand
	if stand:
		var door: Vector2 = G.named["henry"].home if G.named.has("henry") else at
		var to: Vector2 = door - at
		n.h = atan2(to.x, to.y)
	n.sync()

## what he says to you: his Thursday, or how far off it is, or the bell
func talk(who) -> void:
	var key := "feliciano_jueves" if G.weekday == 3 else "feliciano_semana"
	if randf() < BELL:
		key = "feliciano_campana"
	var all: Array = Loc.t(key)
	var i: int = int(_said.get(key, 0))
	_said[key] = i + 1
	var lines: Array = []
	for l in (all[i % all.size()] as Array):
		lines.append(String(l).replace("{dias}", days_left()))
	G.say(who.shown_name(), lines, who.voice)

## how long to Thursday, in words ("un día", "seis días")
func days_left() -> String:
	var d: int = (3 - int(G.weekday) + 7) % 7
	if d == 0:
		d = 7
	return Loc.t("feliciano_dia") if d == 1 else Loc.t("feliciano_dias") % d
