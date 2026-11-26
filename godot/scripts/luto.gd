extends RefCounted
## The people in mourning at the cemetery (the user, 25 November 2026: "En el cementerio habrá siempre 4/6 NPCs dando
## vueltas. Varias ancianas y un anciano. Vestirán de negro/colores oscuros y las mujeres siempre pañoleta negra se
## llamarán simplemente Viejo/a de luto (then: "Mejor que solo un 25% de la viejas lleve la pañoleta") y dirán frases en tono humor negro manchego con toda la naturalidad con la que
## llevamos la muerte ... No serán NPCs únicos pero tendrán esas características").
##
##   Five old women and an old man, anonymous neighbours (id "") called "Vieja de luto" / "Viejo de luto" (Loc
##   "generic_names", the last two), in black and dark colours, one woman in four under a black headscarf. Each day four,
##   five or six of them are about (the old man always): the others are not there that day.
##   They go round the cemetery's walks (the gaps between its plots of cementerio.gd, a grid of lanes clear of graves,
##   trees and pantheons) and turn into the aisle between two rows of graves to stand at one for a while -- cleaning it,
##   looking at the flowers, having their tea -- then walk on to another. What they say: Loc "luto_f" / "luto_m".
##   Nobody appears or vanishes in your sight. Until the cemetery is built (world.cementerio), there is nobody.
##
## The unique neighbours who come here when they have nothing for you are rondas.gd's ("cementerio" spots: spots()).

const WOMEN := 5
const MEN := 1
const STAY := [14.0, 40.0]          # seconds at a grave
const PAUSE := [2.0, 6.0]           # seconds at a crossing of two walks, now and then
const EVERY := 0.25
const NEAR := 35.0                  # the graves they go to: within this of where they are
const NAME_F := 10                  # Loc "generic_names": Vieja de luto, Viejo de luto
const NAME_M := 11
const BLACK := 0x1b1b1f
const TOQUILLA := 0.45               # how many of the women wear a black toquilla (the user, 25 Nov 2026: "una toquilla (negra para el cementerio, de colores fuera)")
const SCARF := 0.25                 # how many of the women wear a black headscarf (the user, 25 Nov 2026: "Mejor que solo un 25% de la viejas lleve la pañoleta")
const DARKS := [0x1b1b1f, 0x1b1b1f, 0x26262b, 0x2a2d36, 0x2e2a30, 0x33302e, 0x2b3040, 0x3a3340]

var G
var cm                              # world.cementerio
var people: Array = []              # [{n, path: [map points], wait, stay}]
var lanes_u: Array = []             # the walks running south (constant u) and east (constant v), in the cemetery's (u, v)
var lanes_v: Array = []
var _t := 0.0
var _day := -1

func setup(game) -> void:
	G = game
	cm = G.world.get("cementerio") if G.get("world") != null else null
	if cm == null:
		return
	lanes_u = [15.5, 35.5, 55.5, 77.3, 97.0, 117.5, 138.0, (148.0 + cm.L_N - cm.WALL_T) / 2.0]
	lanes_v = [1.7, 25.0, 44.75, 65.0, 86.0, 106.25, 125.5, 144.5, minf(168.4, cm.L_W - 1.3)]
	var rng := RandomNumberGenerator.new()
	rng.seed = 1102
	for k in range(WOMEN + MEN):
		var man: bool = k >= WOMEN
		var at: Vector2 = _node(rng.randi() % lanes_u.size(), rng.randi() % lanes_v.size())
		var n = G._make_npc("", _look(man), "old_m" if man else "old_f", at)
		n.lines_key = "luto_m" if man else "luto_f"
		n.display_name = str(NAME_M if man else NAME_F)
		n.line_i = rng.randi() % 8
		n.still = true
		n.home = at
		n.set_meta("luto", true)
		n.sync()
		people.append({"n": n, "path": [], "wait": rng.randf_range(0.0, 8.0), "stay": false})
	_sync_day(true)

## in black or dark colours: the women in a dress, a cardigan over a dress or a blouse, one in four a black headscarf, black
## shoes; the man in a shirt or a jersey and a beret
func _look(man: bool) -> Dictionary:
	var o: Dictionary = G._neighbour_look("old_m" if man else "old_f")
	o["shirt"] = DARKS.pick_random()
	o["shirt2"] = DARKS.pick_random()
	o["shirt3"] = -1
	o["shoes"] = BLACK
	o.erase("carro")
	o["smoke"] = false
	o["glasses"] = [0, 0, 0, 1, 2].pick_random()          # (nothing gaudy: no heart-shaped glasses, no flowers at the ears)
	o["earrings"] = 0 if man else [0, 1, 5, 5].pick_random()
	if man:
		o["top"] = [1, 1, 13].pick_random()
		o["hat"] = "beret"
		o.erase("toquilla")
		o.erase("mandil")
		o["shoe_type"] = [1, 13, 13].pick_random()
	else:
		o["top"] = [25, 25, 22, 1].pick_random()        # (not the cardigan alone: under a dark one it shows a white top)
		o["estampado"] = [0, 0, 0, 1].pick_random()
		o["hat"] = "panoleta" if randf() < SCARF else ""        # (a black headscarf on one in four: the user, 25 Nov 2026)
		o["hat_color"] = BLACK
		o["toquilla"] = BLACK if randf() < TOQUILLA else -1
		if int(o.get("mandil", -1)) >= 0:                    # (an apron, if she has one on, in black gingham)
			o["mandil"] = 0x26262b
		o["shoe_type"] = [9, 13, 13, 11].pick_random()
		o["pendant"] = [0, 3, 3, 2].pick_random()
	return o

## a crossing of two walks, on the map
func _node(iu: int, iv: int) -> Vector2:
	return cm.map_at(lanes_u[iu], lanes_v[iv])

## can one walk straight from crossing a to crossing b (next to each other on one walk)? Down the broad walk with its
## pantheons only along the walk of cypresses and the last walk: the others pass too close to a pantheon there
func _edge_ok(a: Vector2i, b: Vector2i) -> bool:
	if a.y == b.y and mini(a.x, b.x) == 3 and maxi(a.x, b.x) == 4:
		return lanes_v[a.y] in [86.0, 125.5] or a.y == 0 or a.y == lanes_v.size() - 1
	return true

## the crossings from one to the other, by the walks (breadth first over the grid)
func _route(from: Vector2i, to: Vector2i) -> Array:
	var prev := {from: from}
	var todo: Array = [from]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_front()
		if c == to:
			break
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx: Vector2i = c + d
			if nx.x < 0 or nx.y < 0 or nx.x >= lanes_u.size() or nx.y >= lanes_v.size() or prev.has(nx) or not _edge_ok(c, nx):
				continue
			prev[nx] = c
			todo.append(nx)
	var out: Array = []
	var c2: Vector2i = to
	if not prev.has(to):
		return [from]
	while c2 != from:
		out.push_front(c2)
		c2 = prev[c2]
	out.push_front(from)
	return out

## the crossing nearest a spot
func _nearest(p: Vector2) -> Vector2i:
	var f: Vector2 = _uv(p)
	var best := Vector2i.ZERO
	var bd := INF
	for iu in range(lanes_u.size()):
		for iv in range(lanes_v.size()):
			var d: float = Vector2(lanes_u[iu], lanes_v[iv]).distance_to(f)
			if d < bd:
				bd = d
				best = Vector2i(iu, iv)
	return best

## a spot on the map in the cemetery's (u, v): cementerio.gd's P() undone (its four corners are not quite a rectangle:
## a few steps of Newton's, from where it would be if they were)
func _uv(p: Vector2) -> Vector2:
	var f: Vector2 = cm.to_frame(p)
	var q := Vector2(f.x * cm.L_N / maxf(cm.c_ne.x, 1.0), f.y * cm.L_W / maxf(cm.c_sw.y, 1.0))
	for k in range(4):
		var e: Vector2 = cm.P(q.x, q.y) - f
		if e.length() < 0.001:
			break
		var ju: Vector2 = cm.P(q.x + 0.5, q.y) - cm.P(q.x - 0.5, q.y)
		var jv: Vector2 = cm.P(q.x, q.y + 0.5) - cm.P(q.x, q.y - 0.5)
		var det: float = ju.x * jv.y - ju.y * jv.x
		if absf(det) < 1e-6:
			break
		q -= Vector2((e.x * jv.y - e.y * jv.x) / det, (ju.x * e.y - ju.y * e.x) / det)
	return q

## somewhere to go: a grave (into the aisle beside a row of them, from the walk at its end), or just another crossing
func _plan(e: Dictionary) -> void:
	var n = e["n"]
	var here := _nearest(n.p)
	var path: Array = []
	if e.get("back") is Array:                         # (out of the aisle the way they came in, first)
		path += (e["back"] as Array)
		here = e["back_node"]
		e.erase("back")
	var face = null
	if randf() < 0.75 and not cm.pair_rows.is_empty():
		var me: Vector2 = _uv(n.p)                         # (a grave not far off: within 35 m if there is one)
		var near: Array = cm.pair_rows.filter(func(q): return Vector2((float(q[0]) + float(q[1])) / 2.0, (float(q[2]) + float(q[3])) / 2.0).distance_to(me) < NEAR)
		var pr: Array = (near if not near.is_empty() else cm.pair_rows).pick_random()
		var top: bool = randf() < 0.5
		var av: float = float(pr[2]) - 0.5 if top else float(pr[3]) + 0.5      # (the aisle, half a metre off the row)
		var west: bool = randf() < 0.5
		var end_u: float = float(pr[0]) if west else float(pr[1])
		var iu := 0
		var bd := INF
		for k in range(lanes_u.size()):                   # (the walk at that end of the row)
			var d: float = absf(float(lanes_u[k]) - end_u)
			if d < bd and (float(lanes_u[k]) < end_u if west else float(lanes_u[k]) > end_u):
				bd = d
				iu = k
		if bd > 4.0:
			west = not west
			end_u = float(pr[0]) if west else float(pr[1])
			bd = INF
			for k in range(lanes_u.size()):
				var d2: float = absf(float(lanes_u[k]) - end_u)
				if d2 < bd:
					bd = d2
					iu = k
		var iv := 0
		var bv := INF
		for k in range(lanes_v.size()):
			var dv: float = absf(float(lanes_v[k]) - av)
			if dv < bv:
				bv = dv
				iv = k
		for c in _route(here, Vector2i(iu, iv)):
			path.append(_node(c.x, c.y))
		var ug: float = lerpf(float(pr[0]) + 0.6, float(pr[1]) - 0.6, randf())
		path.append(cm.map_at(lanes_u[iu], av))
		path.append(cm.map_at(ug, av))
		face = cm.map_at(ug, float(pr[2]) + 1.0 if top else float(pr[3]) - 1.0)
		e["back"] = [cm.map_at(lanes_u[iu], av)]
		e["back_node"] = Vector2i(iu, iv)
	else:                                              # (or on to the next crossing, or the one after)
		var to := here
		for k in range(1 + randi() % 2):
			var steps: Array = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)].filter(func(d):
				var nx: Vector2i = to + d
				return nx.x >= 0 and nx.y >= 0 and nx.x < lanes_u.size() and nx.y < lanes_v.size() and _edge_ok(to, nx))
			if not steps.is_empty():
				to += steps.pick_random()
		for c in _route(here, to):
			path.append(_node(c.x, c.y))
	e["path"] = path
	e["face"] = face
	e["stay"] = face != null

## how many are about today: four, five or six, the man always among them
func _today() -> int:
	return 4 + posmod(int(G.day_n) * 7 + 3, 3)

func _sync_day(force := false) -> void:
	if int(G.day_n) == _day and not force:
		return
	_day = int(G.day_n)
	var many := _today()
	for i in range(people.size()):
		var n = people[i]["n"]
		var man: bool = i >= WOMEN
		var want: bool = man or i < many - MEN
		if want == (not n.away):
			continue
		if not force and G.sees(n.p):
			_day = -1                                   # (try again when nobody is looking)
			continue
		n.away = not want
		n.visible = want

func tick(dt: float) -> void:
	if cm == null or people.is_empty():
		return
	_t -= dt
	if _t > 0.0:
		return
	var step: float = EVERY - _t
	_t = EVERY
	_sync_day()
	for e in people:
		var n = e["n"]
		if n == null or not is_instance_valid(n) or n.away:
			continue
		if n.state == "fly" or n.state == "down" or (G.dlg != null and G.dlg.get("from") == n):
			continue
		if n.p.distance_to(n.home) > 0.6:
			continue                                    # (still on the way to the last point)
		var path: Array = e["path"]
		if not path.is_empty():
			path.pop_front()
			if not path.is_empty():
				n.home = path[0]
				continue
			if e["stay"]:                              # at the grave: facing it, a while
				var f = e.get("face")
				if f is Vector2:
					var d: Vector2 = (f as Vector2) - n.p
					n.h = atan2(d.x, d.y)
				e["wait"] = randf_range(STAY[0], STAY[1])
			else:
				e["wait"] = randf_range(PAUSE[0], PAUSE[1]) if randf() < 0.5 else 0.0
			continue
		e["wait"] = float(e["wait"]) - step
		if float(e["wait"]) > 0.0:
			continue
		_plan(e)
		if not (e["path"] as Array).is_empty():
			n.home = e["path"][0]

## spots for the unique neighbours who come here (rondas.gd): in the aisles by the graves, a few of them
func spots() -> Array:
	if cm == null or cm.pair_rows.is_empty():
		return []
	var rng := RandomNumberGenerator.new()
	rng.seed = 2511
	var out: Array = []
	for i in range(8):
		var pr: Array = cm.pair_rows[rng.randi() % cm.pair_rows.size()]
		var ug: float = lerpf(float(pr[0]) + 0.6, float(pr[1]) - 0.6, rng.randf())
		out.append(cm.map_at(ug, float(pr[2]) - 0.5))
	return out

## the ones about just now (for the self-test)
func about() -> Array:
	return people.filter(func(e): return not e["n"].away).map(func(e): return e["n"])
