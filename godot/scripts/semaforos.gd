extends RefCounted
## The traffic lights of the crossroads of the Avenida, the Salvador, Santa Ana and the Arcos (the user, 22 November 2026:
## "Vamos a tratar de terminar el cruce de los semáforos para poner definitivamente los semáforos"; and, asked what they
## do: "Solo paran coches"). Pretil builds the posts, their lamps, the mirror and the signs (cruce.gd, world.cruce); here
## is their cycle and the town's cars stopping for them. You may go through on red: nothing happens to you.
##
##   world.cruce.heads: one face for each lane coming into the crossroads, {"stop": the stop line (map point, middle of
##   the lane), "a" -> "b": the road nodes the car comes along, b the first node of the crossroads, "group": 0 or 1 (the
##   streets green together)}. set_light(i, "verde" | "ambar" | "rojo" | "off"). Lights for people on foot, if there are
##   any: world.cruce.walk [{"group": the street they cross}], set_walk(i, on), green while that street is red.
##
##   The cycle: the Avenida and the Arcos (group 0) longer, the side streets (group 1) shorter; amber, then a moment of
##   red both ways. In the small hours, and while a post is down (world.cruce.broken: the user, 22 Nov 2026, "que rotos
##   funcionen como ámbar"), amber blinking both ways: the two ways in with a STOP sign as well (the Avenida
##   coming down, by Sopiss; the Arcos coming up, by Santa Ana 2) stop at the line a moment and go; the others go on.
##   A car stops at its line on red, and on amber unless it is going too fast to stop there; once over its line it goes on through
##   the box of the crossroads (the two short stretches inside it have no lights). On a job (a patrol after you, a tow
##   truck on a call) it does not stop.

const GREEN := [16.0, 11.0]          # seconds of green, group 0 (the main road) and group 1 (the side streets)
const AMBER := 3.0
const ALL_RED := 1.5
const NIGHT := [1.0, 7.0]            # hours of blinking amber
const BLINK := 0.6                   # seconds on, seconds off
const LOOK := 45.0                   # metres before the line a car starts minding the light
const STOP_SIGNS := ["avenida", "arcos"]      # (cruce.gd heads' "name"): a STOP sign beside the light, minded when it blinks
const STOP_FOR := 1.2                # seconds stood at a STOP before going on
const BRAKE := 4.5                   # m/s²: on amber, a car that cannot stop at its line this hard goes through

var G
var place                            # world.cruce
var heads: Array = []
var walk: Array = []
var t := 0.0                         # where in the cycle
var shown: Array = []                # what each face shows now
var shown_walk: Array = []
var _blink_t := 0.0
var _blink_on := false

func setup(game, at = null) -> void:
	G = game
	place = at
	if place == null and G.get("world") != null:
		place = G.world.get("cruce")
	if place == null or not (place.get("heads") is Array) or (place.heads as Array).is_empty():
		place = null
		return
	heads = place.heads
	walk = place.walk if place.get("walk") is Array else []
	shown.resize(heads.size())
	shown.fill("")
	shown_walk.resize(walk.size())
	shown_walk.fill("")
	if G.get("traffic") != null:
		G.traffic.lights = self
	if place.get("auto") != null:
		place.auto = false                # (cruce.gd's own cycle, for its lamps alone, until this one was there)
	_show()

func cycle() -> float:
	return GREEN[0] + AMBER + ALL_RED + GREEN[1] + AMBER + ALL_RED

func blinking() -> bool:
	return night() or (place != null and place.get("broken") == true)

func night() -> bool:
	var h: float = float(G.clock)
	return h >= NIGHT[0] and h < NIGHT[1]

## what a group's lights show at this moment of the cycle
func state(group: int) -> String:
	if blinking():
		return "ambar" if _blink_on else "off"
	var k: float = fposmod(t, cycle())
	var g0: float = GREEN[0]
	var a0: float = g0 + AMBER
	var r0: float = a0 + ALL_RED
	var g1: float = r0 + GREEN[1]
	var a1: float = g1 + AMBER
	if group == 0:
		return "verde" if k < g0 else ("ambar" if k < a0 else "rojo")
	if k < r0 or k >= a1:
		return "rojo"
	return "verde" if k < g1 else "ambar"

func tick(dt: float) -> void:
	if place == null:
		return
	if G.traffic != null and G.traffic.lights == null:      # (the traffic is made after the town's people: game.gd _boot_rest)
		G.traffic.lights = self
	t += dt
	_blink_t -= dt
	if _blink_t <= 0.0:
		_blink_t = BLINK
		_blink_on = not _blink_on
	_show()

func _show() -> void:
	for i in range(heads.size()):
		var s := state(int(heads[i].get("group", 0)))
		if s != shown[i]:
			shown[i] = s
			if place.has_method("set_light"):
				place.set_light(i, s)
	for i in range(walk.size()):
		var dark := blinking()                      # (blinking amber: the little men both out)
		var on: bool = not dark and state(int(walk[i].get("group", 0))) == "rojo"
		var want: String = "dark" if dark else ("on" if on else "off")
		if want != shown_walk[i]:
			shown_walk[i] = want
			if place.has_method("set_walk"):
				place.set_walk(i, on, dark)

## for traffic.gd: how far a car has to go to the line where it must stop (metres from its nose), or -1 if nothing
## stops it. `e`: its traffic entry (a, b, and prev: the node before a, kept when it turned at the last junction).
func gap(e: Dictionary, cp: Vector2, nose: float, speed: float) -> float:
	if place == null:
		return -1.0
	var dark := blinking()
	var a: int = e["a"]
	var b: int = e["b"]
	var prev: int = int(e.get("prev", -1))
	for hi in range(heads.size()):
		var h: Dictionary = heads[hi]
		var ha: int = h["a"]
		var hb: int = h["b"]
		# (coming along its street -- the stretch before it too, the last one may be only a few metres long -- or just
		# past the turn-off point of the junction, still short of the line)
		if not ((a == ha and b == hb) or b == ha or (prev == ha and a == hb)):
			continue
		var dir: Vector2 = ((MapData.nodes[hb] as Vector2) - (MapData.nodes[ha] as Vector2)).normalized()
		var rel: Vector2 = (h["stop"] as Vector2) - cp
		if absf(rel.dot(Vector2(-dir.y, dir.x))) > 7.0:
			continue                           # (another street into the same node)
		var g: float = rel.dot(dir) - nose
		if g < -0.3 or g > LOOK:
			return -1.0                    # over the line already, or a long way off
		if dark:                           # (blinking amber: only a STOP sign stops it, once)
			if not (String(h.get("name", "")) in STOP_SIGNS):
				return -1.0
			if g > 8.0:
				e.erase("stop_done")
			if int(e.get("stop_done", -1)) == hi:
				return -1.0
			e["stop_at"] = hi
			return maxf(g, 0.0)
		var s := state(int(h.get("group", 0)))
		if s == "verde" or s == "off":
			return -1.0
		if s == "ambar" and g < maxf(speed, 0.0) * maxf(speed, 0.0) / (2.0 * BRAKE):
			return -1.0
		return maxf(g, 0.0)
	return -1.0

## for traffic.gd: a car is standing at its line. At a STOP in the small hours, a moment, and on it goes.
func held(e: Dictionary, dt: float) -> void:
	if not blinking() or not e.has("stop_at"):
		e["held"] = 0.0
		return
	e["held"] = float(e.get("held", 0.0)) + dt
	if float(e["held"]) >= STOP_FOR:
		e["stop_done"] = e["stop_at"]
		e.erase("stop_at")
		e["held"] = 0.0
