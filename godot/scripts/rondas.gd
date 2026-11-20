extends RefCounted
## The rounds of the neighbours with a name of their own: when a unique NPC has no mission for you and is not working,
## they appear at leisure spots around town matching their personality (food places, bars, pubs, arcade/Recress, medical
## centre, churches, square, parks).
##
##   Missions first: whoever has one for you, or is wanted by the step under way, or goes with you, or is on duty, is
##   put back at their usual spot (and stays there). Nobody is moved where you can see them go or come.

const ROUNDS := {
	"paca": "old",
	"josefa": "old_social",
	"maruja": "adult",
	"alberto": "young_arcade",
	"chiki": "young_night",
	"kevin": "kid",
	"eusebio": "adult_bar",
	"ramirez": "officer_off",
	"anselmo": "priest",
	"genaro": "old_miller",
	"venancio": "undertaker",
	"alcalde": "mayor",
}
const AFTER_PROTEST := ["alberto", "chiki"]      # (at the bridge until their demonstration is over)
const EVERY := 3.0              # seconds between looks
const STAY := [150.0, 300.0]    # seconds at one place before trying another
## what each personality does at each hour: [from, to, where]
const PLAN := {
	"old": [[8.0, 13.0, "church"], [13.0, 17.0, "home"], [17.0, 21.0, "out_old"], [21.0, 32.0, "home"]],
	"old_social": [[8.0, 12.0, "salud_or_church"], [12.0, 15.0, "comida"], [15.0, 17.5, "home"], [17.5, 21.0, "square_or_bar"], [21.0, 32.0, "home"]],
	"adult": [[10.0, 13.0, "square"], [13.0, 16.0, "bar"], [16.0, 19.0, "home"], [19.0, 23.5, "pub_or_bar"], [23.5, 34.0, "home"]],
	"adult_bar": [[9.0, 14.0, "home"], [14.0, 16.5, "comida"], [16.5, 19.5, "home"], [19.5, 24.5, "pub_or_bar"], [24.5, 33.0, "home"]],
	"young_arcade": [[10.0, 13.5, "square"], [13.5, 16.0, "comida"], [16.0, 21.0, "recreativos_or_bar"], [21.0, 25.5, "pub_or_rec"], [25.5, 34.0, "home"]],
	"young_night": [[11.0, 14.0, "square"], [14.0, 16.5, "comida"], [16.5, 20.0, "recreativos_or_bar"], [20.0, 26.0, "pub"], [26.0, 35.0, "home"]],
	"officer_off": [[8.0, 14.0, "home"], [14.0, 16.5, "comida"], [16.5, 19.0, "salud"], [19.0, 23.0, "bar"], [23.0, 32.0, "home"]],
	"priest": [[7.0, 13.0, "home"], [13.0, 15.5, "comida"], [15.5, 18.0, "salud"], [18.0, 20.5, "square"], [20.5, 31.0, "home"]],
	"old_miller": [[7.0, 14.0, "home"], [14.0, 16.5, "bar"], [16.5, 19.0, "salud_or_church"], [19.0, 21.5, "square"], [21.5, 31.0, "home"]],
	"undertaker": [[8.0, 17.0, "home"], [17.0, 19.5, "salud"], [19.5, 22.0, "church"], [22.0, 25.0, "pub"], [25.0, 32.0, "home"]],
	"mayor": [[8.5, 14.0, "home"], [14.0, 16.5, "comida"], [16.5, 19.0, "home"], [19.0, 22.5, "bar"], [22.5, 32.5, "home"]],
	"kid": [[0.0, 24.0, "park"]],
}

var G
var zones := {}                 # "church", "square", "comida", "bar", "pub", "recreativos", "salud", "park" -> [points on the pavement]
var base := {}                  # id -> [where they usually are, still there?]
var _at := {}                   # id -> {kind of place, point, until}
var _t := 0.0

func setup(game) -> void:
	G = game
	base.clear()
	for id in ROUNDS:
		var n = G.named.get(id)
		if n != null:
			base[id] = [n.home, n.still]
	var w = G.world
	var kerb := func(p) -> Array: return [G._pavement(p)] if p is Vector2 and p != Vector2.ZERO else []
	var of := func(place) -> Vector2: return Vector2(place.global_position.x, place.global_position.z) if place != null else Vector2.ZERO
	zones["church"] = []
	for p in [MapData.poi("Divino Salvador"), of.call(w.caridad if w != null else null), of.call(w.santaana if w != null else null), of.call(w.sebastian if w != null else null)]:
		zones["church"] += kerb.call(p)
	zones["square"] = kerb.call(MapData.poi("Plaza del Ayuntamiento"))
	zones["comida"] = []
	for p in [G.places["henry"]["p"] if G.places.has("henry") else null, G.places["kebab"]["p"] if G.places.has("kebab") else null,
			of.call(w.teledurum if w != null else null), of.call(w.kebabdeluxe if w != null else null)]:
		zones["comida"] += kerb.call(p)
	zones["bar"] = []
	for p in [of.call(w.toti if w != null else null)]:
		zones["bar"] += kerb.call(p)
	if G.props != null and G.props.get("terrazas") != null:
		for tz in G.props.terrazas:
			if tz is Dictionary and tz.has("p"):
				zones["bar"] += kerb.call(tz["p"])
			elif tz is Vector2:
				zones["bar"] += kerb.call(tz)
	zones["bar"] += zones["comida"]
	zones["bar"] += zones["square"]               # (the square's bar, with its awnings)
	zones["pub"] = []
	for p in [of.call(w.toti if w != null else null), MapData.poi("Recinto Ferial")]:
		zones["pub"] += kerb.call(p)
	zones["pub"] += zones["bar"]
	zones["recreativos"] = []
	if G.recress != null and G.recress.sala != null:
		zones["recreativos"] += kerb.call(G.recress.sala.out_spawn)
	zones["salud"] = []
	if w != null and w.get("salud") != null and w.salud != null:
		if w.salud.get("door") != null:
			zones["salud"] += kerb.call(w.salud.door)
		elif w.salud.get("casualty") != null:
			zones["salud"] += kerb.call(w.salud.casualty)
		else:
			zones["salud"] += kerb.call(of.call(w.salud))
	if zones["salud"].is_empty():
		zones["salud"] = zones["square"].duplicate()
	zones["park"] = []
	if w != null and w.plaza != null:
		zones["park"].append(G._pavement(w.plaza.spot(w.plaza.PLAY.x, w.plaza.PLAY.y) + Vector2(w.plaza.PLAY_R + 2.0, 0.0)))
	for p in [of.call(w.caridad if w != null else null), MapData.poi("Recinto Ferial"), of.call(w.sebastian if w != null else null)]:
		zones["park"] += kerb.call(p)

## does a mission or job want them where they usually are?
func wanted(n) -> bool:
	var id: String = n.id
	if G.dlg != null and G.dlg.get("from") == n:
		return true
	if G.marcas != null and n in G.marcas._list:                 # (a mission for you: the green arrow)
		return true
	if G.phase == "play" and G.si >= 0 and G.si < G.steps.size():
		var s: Dictionary = G.steps[G.si]
		if String(s.get("npc", "")) == id or String(s.get("passenger", "")) == id or String(s.get("who", "")) == id:
			return true
	if G.side != null and String(G.side.get("who", "")) == id:
		return true
	if id in AFTER_PROTEST and not G._protest_over:
		return true
	if id == "josefa" and not G.negocio("informatica"):
		return true
	if id == "alcalde":
		if G.recress != null and (G.recress.cine or G.recress.active() or G.recress.stage() == "dinero"):
			return true
		if G.ajedrez != null and (G.ajedrez.active or G.ajedrez._scene):
			return true
	if id == "alberto" and G.recress != null and (G.recress.cine or G.recress.active()):
		return true
	return n.away or n.state == "fly" or n.state == "down" or n.state == "busy"

func _recress_open() -> bool:
	return G.recress != null and G.recress.done() and G.recress.open_hours(G.clock) and not (zones.get("recreativos", []) as Array).is_empty()

## where a kind of neighbour goes at this hour
func where(kind: String) -> String:
	if kind == "kid":
		return "park" if G.ninos != null and G.ninos.street_time() and G.clock >= 9.0 and G.clock < 21.5 else "home"
	var h: float = G.clock
	for row in PLAN[kind]:
		for hh in [h, h + 24.0]:
			if hh >= float(row[0]) and hh < float(row[1]):
				var what: String = row[2]
				match what:
					"out_old":
						var r := randf()
						return "square" if r < 0.4 else ("church" if r < 0.75 else "salud")
					"salud_or_church":
						return "salud" if randf() < 0.45 else "church"
					"square_or_bar":
						return "square" if randf() < 0.5 else "bar"
					"pub_or_bar":
						return "pub" if randf() < 0.5 else "bar"
					"recreativos_or_bar":
						return "recreativos" if (_recress_open() and randf() < 0.6) else "bar"
					"pub_or_rec":
						return "recreativos" if (_recress_open() and randf() < 0.5) else "pub"
				return what
	return "home"

func tick(dt: float) -> void:
	_t -= dt
	if _t > 0.0:
		return
	_t = EVERY
	if not (G.phase == "play" or G.phase == "free"):
		return
	for id in ROUNDS:
		var n = G.named.get(id)
		if n == null or not is_instance_valid(n) or not base.has(id):
			continue
		var home: Vector2 = base[id][0]
		if wanted(n):
			if _at.has(id) and n.state != "fly" and n.state != "down":
				if _move(n, home, bool(base[id][1])):
					_at.erase(id)
			continue
		var want := where(ROUNDS[id])
		var now: Dictionary = _at.get(id, {"kind": "home", "p": home, "until": 0.0})
		if want == String(now["kind"]) and (want == "home" or G.time < float(now["until"])):
			continue
		var to: Vector2 = home
		if want != "home":
			var options: Array = (zones.get(want, []) as Array).filter(func(q): return q != now["p"])
			if options.is_empty():
				options = zones.get(want, [])
			if options.is_empty():
				continue
			to = options.pick_random()
		if _move(n, to, want == "home" and bool(base[id][1])):
			if want == "home":
				_at.erase(id)
			else:
				_at[id] = {"kind": want, "p": to, "until": G.time + randf_range(STAY[0], STAY[1])}

## everybody back at their usual spot at once, seen or not (for the self-test, which moves people about itself)
func home_all() -> void:
	for id in base:
		var n = G.named.get(id)
		if n != null and is_instance_valid(n):
			_move(n, base[id][0], bool(base[id][1]), true)
	_at.clear()

## off to `to`: from far off only where nobody sees them go or arrive; near, they walk there. True once it is done.
func _move(n, to: Vector2, stand: bool, now := false) -> bool:
	var far: bool = n.p.distance_to(to) > 25.0
	if far and not now and (G.sees(n.p) or G.sees(to)):
		return false
	if far:
		n.p = to
		n.global_position = MapData.at(to, MapData.foot(to) - MapData.height(to))
		n.state = "idle"
		n.reset_physics_interpolation()
	n.home = to
	n.still = stand
	n.sync()
	return true
