extends Node
## Autoload. Loads data/map.json (baked from OpenStreetMap by tools/bake_map.py) and answers
## spatial questions: nearest road, street clearance, GPS route. (Collisions are Godot physics, see world.gd.) Ground positions are Vector2(x, z) in metres.

const CELL := 40.0

class Seg:
	var a: Vector2
	var b: Vector2
	var hw: float
	var road: Dictionary
	var na: int
	var nb: int

var nodes: Array = []          # Vector2 per road node
var roads: Array = []          # {w, k, h, n, p: PackedInt32Array}
var clr: Array = []            # free half-width of the street at each node (distance to the nearest building)
var walls: Array = []          # per facade style: flat [x1, z1, x2, z2, height, floors, tint, ...]
var roofs_gable: Array = []    # [cx, cz, long, short, rot, h, colour]
var roofs_flat: Array = []     # [h, colour, x, z, x, z, ...]
var outlines: Array = []       # PackedVector2Array per city block (collision + map drawing)
var towers: Array = []
var coop: Dictionary = {}        # the cooperative's frame: {o: [x, z] on the avenue, u: [x, z] north along it, len, depth}
var townhall: Dictionary = {}    # the town hall's frame: {m: [x, z], u: [x, z] along the facade, len, depth}
var wall_y: Array = []           # per facade style: the level each of those walls' buildings stands at
var looks: Array = []            # the houses drawn after the real ones: the look (fachadas.gd) of facade style 7, 8, 9...
var houses: Array = []           # the houses built by hand (casas.gd): {id, o: left end of the front, u: along it, len, h, base}
# the relief: a grid of heights, rg metres apart, starting at (rx0, rz0); inside a square the ground is two flat
# triangles split along the diagonal from its (x0, z0) corner to its (x1, z1) corner
var rh := PackedFloat32Array()
var rg := 12.0
var rx0 := 0.0
var rz0 := 0.0
var rnx := 0
var rnz := 0
var salud: Dictionary = {}       # the health centre's frame: {o: south-west corner, u: east along the Callejón Pando}
var church: Dictionary = {}      # the parish church's frame: {o: south-west corner, u: east along the south wall, len, wid, tower}
var petril: Dictionary = {}      # the Petril's frame (petril.gd): {o: south-west corner of its church, u: east along the church's front}
var molino: Dictionary = {}      # the windmill's (molino.gd): {o: the middle of the mill, u: east along the north wall of its corral}; empty on a map baked without it
var toros: Dictionary = {}       # the old bullring's (toros.gd): {o: the middle of its ring}; empty on a map baked without it
var calasanz: Dictionary = {}    # the nursery school of the Calle del Palo's (calasanz.gd): {o: the north-west corner of its front, u: along the front}; empty on a map baked without it
var caridad: Dictionary = {}     # the hermitage of the Caridad's island (caridad.gd): {o: the hermitage's south-west corner, u: along its south side}; empty on a map baked without it
var mercamona: Dictionary = {}   # the supermarket's (mercamona.gd): {o: the shop's north-west corner, u: along its west side, low: its car park's level}; empty on a map baked without it
var correos: Dictionary = {}     # the post office of the Calle de Zaragoza's (correos.gd): {o: its front's middle}; empty on a map baked without it
var sebastian: Dictionary = {}   # the hermitage of San Sebastián and its park (sebastian.gd): {o: its front's south-west corner, u: the front's way}; empty on a map baked without it
var cultura: Dictionary = {}     # the block of the Casa Grande, the library and the music school (cultura.gd): {o: its north-west corner}; empty on a map baked without it
var merkocarry: Dictionary = {}  # the supermarket of the Calle de Santa Ana's (merkocarry.gd): {o: the middle of its front}; empty on a map baked without it
var masahorro: Dictionary = {}   # the supermarket of the Calle de las Viñas's (masahorro.gd): {o: the corner of its front on the Noria, u: along the front}; empty on a map baked without it
var noche: Dictionary = {}       # the Noche of the Calle del Teniente Infante's (noche.gd): {o: the east end of its front, u: along the front}; empty on a map baked without it
var cuartel: Dictionary = {}     # the barracks' (cuartel.gd): {o: the north end of its main front, u: along that front}; empty on a map baked without it
var colegio: Dictionary = {}     # the old school's (colegio.gd): {o: the south-west corner of its west tower, u: along its front}; empty on a map baked without it
var santaana: Dictionary = {}    # the convent of Santa Ana's (santaana.gd): {o: the south end of its front, u: along the front}; empty on a map baked without it
var puente: Dictionary = {}      # the old bridge of the Arroyuelo Medio's (puente.gd): {o: its middle, u: down the bed, top: its deck, pav: [[z, level], ...] the pavements}; empty on a map baked without it
var aceras: Array = []          # high pavements on walls of rubble (aceras_altas.gd): [{street, side, h, w, pts: [[x, z, nx, nz, top, node a, node b, f], ...]}]; empty on a map baked without them
var decks: Array = []            # things people walk over: {o, ax: along it, half, wide (half-width), top: its height, ramp} (the old bridge)
var _blocked := {}               # stretches of street no car can use (Seg -> true)
var garages: Array = []          # the garages you drive into: {id, m: doorway [x, z], n: out into the street, w, d, left, right}
var areas: Array = []
var trees: Array = []
var pois: Array = []
var xmin: float
var xmax: float
var zmin: float
var zmax: float

var segs: Array = []
var _seg_grid := {}
var _node_grid := {}
var _wall_grid := {}
var _seg_of := {}               # Vector2i(lower node, higher node) -> Seg
var _adj: Array = []
var main_comp := PackedByteArray()

var road_hit: Seg = null        # set by road_edge_dist()

var route_active := false
var route_target := Vector2.ZERO
var route_pts := PackedVector2Array()
var _dist := PackedFloat64Array()
var _next := PackedInt32Array()

func _ready() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/map.json"))
	var nn: Array = data["nodes"]
	for i in range(0, nn.size(), 2):
		nodes.append(Vector2(nn[i], nn[i + 1]))
	for r in data["roads"]:
		var p := PackedInt32Array()
		for v in r["p"]:
			p.append(int(v))
		roads.append({"w": float(r["w"]), "k": int(r["k"]), "h": String(r["h"]), "n": fictional(String(r["n"])), "p": p, "paved": int(r.get("paved", 0)), "ow": int(r.get("ow", 0))})   # (paved 1: a pedestrian street in setts and brick; 2: a lane in grey pavers, closed to traffic -- empedrado.gd)
	clr = data["clr"]
	walls = data["walls"]
	roofs_gable = data["roofs_gable"]
	roofs_flat = data["roofs_flat"]
	towers = data["towers"]
	townhall = data.get("townhall", {})
	coop = data.get("coop", {})
	garages = data.get("garages", [])
	church = data.get("church", {})
	salud = data.get("salud", {})
	petril = data.get("petril", {})
	molino = data.get("molino", {})
	toros = data.get("toros", {})
	puente = data.get("puente", {})
	aceras = data.get("aceras", [])
	calasanz = data.get("calasanz", {})
	caridad = data.get("caridad", {})
	santaana = data.get("santaana", {})
	colegio = data.get("colegio", {})
	cuartel = data.get("cuartel", {})
	mercamona = data.get("mercamona", {})
	masahorro = data.get("masahorro", {})
	merkocarry = data.get("merkocarry", {})
	correos = data.get("correos", {})
	cultura = data.get("cultura", {})
	sebastian = data.get("sebastian", {})
	noche = data.get("noche", {})
	wall_y = data.get("wall_y", [])
	looks = data.get("looks", [])
	houses = data.get("houses", [])
	var rel: Dictionary = data.get("relief", {})
	if not rel.is_empty():
		rg = float(rel["g"]); rx0 = float(rel["x0"]); rz0 = float(rel["z0"])
		rnx = int(rel["nx"]); rnz = int(rel["nz"])
		var hh: Array = rel["h"]
		rh.resize(hh.size())
		for i in range(hh.size()):
			rh[i] = float(hh[i]) * 0.01
	for o in data["outlines"]:
		var ring := PackedVector2Array()
		for i in range(0, o.size(), 2):
			ring.append(Vector2(o[i], o[i + 1]))
		outlines.append(ring)
	areas = data["areas"]
	trees = data["trees"]
	pois = data["pois"]
	var b: Array = data["bounds"]
	xmin = b[0]; xmax = b[1]; zmin = b[2]; zmax = b[3]
	_build_segments()
	_build_graph()

## how high the ground is at a spot
func height(p: Vector2) -> float:
	if rnx == 0:
		return 0.0
	var fx := clampf((p.x - rx0) / rg, 0.0, rnx - 1.001)
	var fz := clampf((p.y - rz0) / rg, 0.0, rnz - 1.001)
	var i := int(fx)
	var j := int(fz)
	fx -= i
	fz -= j
	var o := j * rnx + i
	var a := rh[o]
	var c := rh[o + rnx + 1]
	if fx >= fz:
		var b := rh[o + 1]
		return a + fx * (b - a) + fz * (c - b)
	var d := rh[o + rnx]
	return a + fz * (d - a) + fx * (c - d)

## that spot in the world, `lift` metres above the ground
func at(p: Vector2, lift := 0.0) -> Vector3:
	return Vector3(p.x, height(p) + lift, p.y)

## which way is up there (the ground's normal)
func normal(p: Vector2) -> Vector3:
	if rnx == 0:
		return Vector3.UP
	var fx := clampf((p.x - rx0) / rg, 0.0, rnx - 1.001)
	var fz := clampf((p.y - rz0) / rg, 0.0, rnz - 1.001)
	var i := int(fx)
	var j := int(fz)
	var o := j * rnx + i
	var a := rh[o]
	var c := rh[o + rnx + 1]
	if fx - i >= fz - j:
		var b := rh[o + 1]
		return Vector3(a - b, rg, b - c).normalized()
	var d := rh[o + rnx]
	return Vector3(d - c, rg, a - d).normalized()

func _cell(v: float) -> int:
	return floori(v / CELL)

func _grid_add(grid: Dictionary, lo: Vector2, hi: Vector2, item) -> void:
	for cx in range(_cell(lo.x), _cell(hi.x) + 1):
		for cz in range(_cell(lo.y), _cell(hi.y) + 1):
			var k := Vector2i(cx, cz)
			if not grid.has(k):
				grid[k] = []
			grid[k].append(item)

func _build_segments() -> void:
	var pad := Vector2(12, 12)
	for r in roads:
		var p: PackedInt32Array = r["p"]
		for i in range(p.size() - 1):
			var s := Seg.new()
			s.a = nodes[p[i]]; s.b = nodes[p[i + 1]]; s.hw = r["w"] / 2.0; s.road = r; s.na = p[i]; s.nb = p[i + 1]
			segs.append(s)
			_seg_of[Vector2i(mini(s.na, s.nb), maxi(s.na, s.nb))] = s
			_grid_add(_seg_grid, s.a.min(s.b) - pad, s.a.max(s.b) + pad, s)

func _build_graph() -> void:
	var n := nodes.size()
	_adj.resize(n)
	for i in range(n):
		_adj[i] = []
	for r in roads:
		if r["k"] == 2:
			continue
		var h: String = r["h"]
		var mult := 2.2 if r["k"] == 1 else (4.0 if h.begins_with("motorway") else (1.5 if h == "service" else 1.0))
		var p: PackedInt32Array = r["p"]
		for i in range(p.size() - 1):
			var c: float = nodes[p[i]].distance_to(nodes[p[i + 1]]) * mult
			_adj[p[i]].append(p[i + 1]); _adj[p[i]].append(c)
			_adj[p[i + 1]].append(p[i]); _adj[p[i + 1]].append(c)
	# biggest connected piece, so missions never point at an orphan service road
	var comp := PackedInt32Array(); comp.resize(n); comp.fill(-1)
	var best_id := -1
	var best_size := 0
	for i in range(n):
		if comp[i] >= 0 or _adj[i].is_empty():
			continue
		var stack := [i]
		comp[i] = i
		var size := 0
		while not stack.is_empty():
			var u: int = stack.pop_back()
			size += 1
			var a: Array = _adj[u]
			for k in range(0, a.size(), 2):
				var v: int = a[k]
				if comp[v] < 0:
					comp[v] = i
					stack.append(v)
		if size > best_size:
			best_size = size; best_id = i
	main_comp.resize(n)
	for i in range(n):
		main_comp[i] = 1 if comp[i] == best_id else 0
		if main_comp[i] == 1:
			var k := Vector2i(_cell(nodes[i].x), _cell(nodes[i].y))
			if not _node_grid.has(k):
				_node_grid[k] = PackedInt32Array()
			_node_grid[k].append(i)
	_dist.resize(n); _next.resize(n)

# ---------------- roads ----------------
func seg_point(s: Seg, p: Vector2) -> Vector2:
	var d := s.b - s.a
	var l := d.length_squared()
	var t := clampf((p - s.a).dot(d) / l, 0.0, 1.0) if l > 0.0 else 0.0
	return s.a + d * t

## distance past the edge of the nearest road (<= 0 means on it); the road is left in road_hit
func road_edge_dist(p: Vector2) -> float:
	var best := 99.0
	road_hit = null
	var list = _seg_grid.get(Vector2i(_cell(p.x), _cell(p.y)))
	if list != null:
		for s: Seg in list:
			var d := seg_point(s, p).distance_to(p) - s.hw
			if d < best:
				best = d; road_hit = s
	return best

func drivable(s: Seg) -> bool:
	var h: String = s.road["h"]
	return s.road["k"] == 0 and not h.begins_with("motorway") and main_comp[s.na] == 1 and not _blocked.has(s)

## closes a stretch of street to cars: the traffic will not take it, and routes go round (it costs half a kilometre)
func block(s: Seg) -> void:
	_blocked[s] = true
	for pair in [[s.na, s.nb], [s.nb, s.na]]:
		var a: Array = _adj[pair[0]]
		for k in range(0, a.size(), 2):
			if a[k] == pair[1]:
				a[k + 1] = float(a[k + 1]) + 500.0

## how high somebody on foot stands at a spot: the ground, or the deck of a bridge if they are on one (its steps
## carry them up from the ground at either end)
## A deck is {o, ax, half, wide, top, ramp}: a strip `half` long each way along ax and `wide` to each side, that rises
## from the ground to `top` over `ramp` at both ends. With "low" it is a flight of steps instead: from that level at
## its -ax end up to `top` over `ramp`, and level from there on. With "poly" (and o, r2: a circle round it) it is a
## level floor of that outline (the raised pavement and the square above the Arroyuelo, plaza.gd) -- or, with "grad"
## (how much it rises to the metre, as a vector on the map), one that slopes: `top` is its height at o (puente.gd).
##
## The decks are found through a grid (the user's 2K at 30-odd fps, 16 Nov 2026): every step of every neighbour asks
## this, and going through all of them -- nearly three hundred, with the places built by hand -- took 89 microseconds
## a call. Each cell keeps the decks that reach into it, in their order in `decks` (the first that holds the spot is
## the one: a flight of steps is put before the floors it joins). The grid is made again whenever `decks` is another
## list or changes length (the places add theirs when they are built; the footbridge by the plaza while it is across).
const DECK_CELL := 16.0
var _deck_cells := {}
var _deck_list = null
var _deck_n := -1

func _index_decks() -> void:
	_deck_cells.clear()
	_deck_list = decks
	_deck_n = decks.size()
	for i in range(decks.size()):
		var d: Dictionary = decks[i]
		var lo := Vector2(1e9, 1e9)
		var hi := Vector2(-1e9, -1e9)
		if d.has("poly"):
			for q in (d["poly"] as PackedVector2Array):
				lo = lo.min(q)
				hi = hi.max(q)
		else:
			var o: Vector2 = d["o"]
			var ax: Vector2 = d["ax"]
			var side := Vector2(-ax.y, ax.x) * float(d["wide"])
			for q in [o + ax * float(d["half"]) + side, o + ax * float(d["half"]) - side, o - ax * float(d["half"]) + side, o - ax * float(d["half"]) - side]:
				lo = lo.min(q)
				hi = hi.max(q)
		for cx in range(floori(lo.x / DECK_CELL), floori(hi.x / DECK_CELL) + 1):
			for cy in range(floori(lo.y / DECK_CELL), floori(hi.y / DECK_CELL) + 1):
				var key := Vector2i(cx, cy)
				if not _deck_cells.has(key):
					_deck_cells[key] = PackedInt32Array()
				var arr: PackedInt32Array = _deck_cells[key]
				arr.append(i)
				_deck_cells[key] = arr

func foot(p: Vector2) -> float:
	var h := height(p)
	if decks.is_empty():
		return h
	if not is_same(decks, _deck_list) or decks.size() != _deck_n:
		_index_decks()
	var cell = _deck_cells.get(Vector2i(floori(p.x / DECK_CELL), floori(p.y / DECK_CELL)))
	if cell == null:
		return h
	for i in (cell as PackedInt32Array):
		var d: Dictionary = decks[i]
		var rel: Vector2 = p - (d["o"] as Vector2)
		if d.has("poly"):
			if rel.length_squared() < float(d["r2"]) and Geometry2D.is_point_in_polygon(p, d["poly"]):
				return float(d["top"]) + (rel.dot(d["grad"]) if d.has("grad") else 0.0)
			continue
		var ax: Vector2 = d["ax"]
		var s := rel.dot(ax)
		var a := absf(s)
		if a < float(d["half"]) and absf(rel.dot(Vector2(-ax.y, ax.x))) < float(d["wide"]):
			if d.has("low"):
				return lerpf(float(d["low"]), float(d["top"]), clampf((float(d["half"]) + s) / float(d["ramp"]), 0.0, 1.0))
			return lerpf(h, float(d["top"]), clampf((float(d["half"]) - a) / float(d["ramp"]), 0.0, 1.0))
	return h

## slow full scan, for setup only. Returns {p: point on the road, u: unit direction, seg}
func nearest_road(p: Vector2, any_road := false) -> Dictionary:
	var best: Seg = null
	var bd := 1e12
	var bp := Vector2.ZERO
	for s: Seg in segs:
		if any_road:
			if s.road["h"] == "motorway":
				continue
		elif not drivable(s):
			continue
		var q := seg_point(s, p)
		var d := q.distance_squared_to(p)
		if d < bd:
			bd = d; best = s; bp = q
	return {"p": bp, "u": (best.b - best.a).normalized(), "seg": best}

## how far from the centre line something can stand/park at this road spot without touching a building
func side_room(r: Dictionary) -> float:
	return room_at(r["p"])

## distance from any point to the nearest building wall (capped at 30 m)
func room_at(p: Vector2) -> float:
	if _wall_grid.is_empty():
		for ring in outlines:
			for i in range(ring.size()):
				var a: Vector2 = ring[i]
				var b: Vector2 = ring[(i + 1) % ring.size()]
				_grid_add(_wall_grid, a.min(b), a.max(b), [a, b])
	var best := 30.0
	var cx := _cell(p.x)
	var cz := _cell(p.y)
	for ax in [-1, 0, 1]:
		for az in [-1, 0, 1]:
			var list = _wall_grid.get(Vector2i(cx + ax, cz + az))
			if list == null:
				continue
			for e in list:
				best = minf(best, Geometry2D.get_closest_point_to_segment(p, e[0], e[1]).distance_to(p))
	return best

func poi(name_part: String) -> Vector2:
	for q in pois:
		if String(q["n"]).contains(name_part):
			return Vector2(q["x"], q["z"])
	return Vector2.ZERO

# ---------------- GPS: one Dijkstra from the target, then follow pointers ----------------
func _nearest_node(p: Vector2, need_reach: bool) -> int:
	var best := -1
	var bd := 1e12
	var cx := _cell(p.x)
	var cz := _cell(p.y)
	for ring in range(1, 8):
		for ax in range(-ring, ring + 1):
			for az in range(-ring, ring + 1):
				var l = _node_grid.get(Vector2i(cx + ax, cz + az))
				if l == null:
					continue
				for i: int in l:
					if need_reach and _dist[i] == INF:
						continue
					var d: float = nodes[i].distance_squared_to(p)
					if d < bd:
						bd = d; best = i
		if best >= 0:
			break
	return best

func set_route_target(p: Vector2) -> void:
	route_target = p
	route_active = true
	_dist.fill(INF)
	_next.fill(-1)
	var src := _nearest_node(p, false)
	if src < 0:
		return
	_dist[src] = 0.0
	var heap := [[0.0, src]]
	while not heap.is_empty():
		# pop
		var top: Array = heap[0]
		var last: Array = heap.pop_back()
		if not heap.is_empty():
			heap[0] = last
			var i := 0
			while true:
				var l := i * 2 + 1
				var r := l + 1
				var m := i
				if l < heap.size() and heap[l][0] < heap[m][0]: m = l
				if r < heap.size() and heap[r][0] < heap[m][0]: m = r
				if m == i:
					break
				var tmp = heap[m]; heap[m] = heap[i]; heap[i] = tmp
				i = m
		var d: float = top[0]
		var u: int = top[1]
		if d > _dist[u]:
			continue
		var a: Array = _adj[u]
		for k in range(0, a.size(), 2):
			var v: int = a[k]
			var nd: float = d + a[k + 1]
			if nd < _dist[v]:
				_dist[v] = nd
				_next[v] = u
				heap.append([nd, v])
				var j := heap.size() - 1
				while j > 0:
					var par := (j - 1) >> 1
					if heap[par][0] <= heap[j][0]:
						break
					var t2 = heap[par]; heap[par] = heap[j]; heap[j] = t2
					j = par

func clear_route() -> void:
	route_active = false
	route_pts = PackedVector2Array()

func update_route(p: Vector2) -> void:
	route_pts = PackedVector2Array()
	if not route_active:
		return
	# Start from the street we are standing on, and from whichever END of it is really on the way.
	# (Starting from the nearest node pointed the arrow backwards, or down a parallel street.)
	var n := -1
	var best := 30.0
	var list = _seg_grid.get(Vector2i(_cell(p.x), _cell(p.y)))
	if list != null:
		for s: Seg in list:
			if s.road["k"] == 2 or _dist[s.na] == INF or _dist[s.nb] == INF:
				continue
			var d := seg_point(s, p).distance_to(p)
			if d < best:
				best = d
				n = s.na if p.distance_to(s.a) + _dist[s.na] <= p.distance_to(s.b) + _dist[s.nb] else s.nb
	if n < 0:
		n = _nearest_node(p, true)
	var guard := 0
	while n >= 0 and guard < 800:
		route_pts.append(nodes[n])
		n = _next[n]
		guard += 1
	route_pts.append(route_target)

# ---------------- extras for street furniture and the police ----------------
## how many streets meet at a node (>= 3 is a junction)
func degree(node: int) -> int:
	return _adj[node].size() / 2

## a random road node between rmin and rmax metres from p, or null
func random_node_near(p: Vector2, rmin: float, rmax: float):
	var found: Array = []
	var reach := int(ceil(rmax / CELL))
	var cx := _cell(p.x)
	var cz := _cell(p.y)
	for ax in range(-reach, reach + 1):
		for az in range(-reach, reach + 1):
			var l = _node_grid.get(Vector2i(cx + ax, cz + az))
			if l == null:
				continue
			for i: int in l:
				var d: float = nodes[i].distance_to(p)
				if d >= rmin and d <= rmax and float(clr[i]) > 2.6:
					found.append(nodes[i])
	return found.pick_random() if not found.is_empty() else null

## shortest street route between two points (A*), as a list of points ending at `to`
func path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	var a := _nearest_node(from, false)
	var b := _nearest_node(to, false)
	if a < 0 or b < 0:
		out.append(to)
		return out
	var goal: Vector2 = nodes[b]
	var g := {a: 0.0}
	var came := {}
	var heap := [[nodes[a].distance_to(goal), a]]
	var guard := 0
	while not heap.is_empty() and guard < 6000:
		guard += 1
		var top: Array = heap[0]
		var last: Array = heap.pop_back()
		if not heap.is_empty():
			heap[0] = last
			var i := 0
			while true:
				var l := i * 2 + 1
				var r := l + 1
				var m := i
				if l < heap.size() and heap[l][0] < heap[m][0]: m = l
				if r < heap.size() and heap[r][0] < heap[m][0]: m = r
				if m == i:
					break
				var tmp = heap[m]; heap[m] = heap[i]; heap[i] = tmp
				i = m
		var u: int = top[1]
		if u == b:
			break
		var gu: float = g[u]
		var adj: Array = _adj[u]
		for k in range(0, adj.size(), 2):
			var v: int = adj[k]
			var nd: float = gu + adj[k + 1]
			if not g.has(v) or nd < g[v]:
				g[v] = nd
				came[v] = u
				heap.append([nd + nodes[v].distance_to(goal), v])
				var j := heap.size() - 1
				while j > 0:
					var par := (j - 1) >> 1
					if heap[par][0] <= heap[j][0]:
						break
					var t2 = heap[par]; heap[par] = heap[j]; heap[j] = t2
					j = par
	var chain: Array = []
	var n := b
	while came.has(n) and chain.size() < 800:
		chain.append(nodes[n])
		n = came[n]
	chain.reverse()
	for q in chain:
		out.append(q)
	out.append(to)
	return out

## the road nodes one street-segment away from this one
func neighbours(node: int) -> Array:
	var out: Array = []
	var a: Array = _adj[node]
	for k in range(0, a.size(), 2):
		out.append(a[k])
	return out

func seg_between(a: int, b: int) -> Seg:
	return _seg_of.get(Vector2i(mini(a, b), maxi(a, b)))

## A one-way street of the map's source (OpenStreetMap; the bake's "ow"): may it be driven from node a to node b? Only in
## the order of its points. Any other stretch (two-way, a footpath, no stretch at all): yes.
func one_way_says(a: int, b: int) -> int:
	var s = seg_between(a, b)
	if s == null or int(s.road.get("ow", 0)) == 0 or int(s.road["k"]) != 0:
		return 0                                     # (it says nothing)
	return 1 if s.na == a else -1

func nearest_node(p: Vector2) -> int:
	return _nearest_node(p, false)

## half-width of the asphalt actually drawn on this stretch (narrower where the facades close in)
func fitted_hw(s: Seg) -> float:
	if s.road["k"] != 0:
		return s.hw
	return minf(s.hw, maxf(1.8, minf(float(clr[s.na]), float(clr[s.nb])) - 0.5))

## Street signs show the real names. (The game is called Matritellus; the town in it is Madridejos.)
## If a name ever needs a stand-in, add it here: {"Real name": "Name shown"}.
## The town's patroness (and everything named after her) is "Valdeacero" in the game.
const PLACE_NAMES := {"Valdehierro": "Valdeacero"}
func fictional(name: String) -> String:
	for real in PLACE_NAMES:
		name = name.replace(real, PLACE_NAMES[real])
	return name

## a spot at the cooperative: s metres north along the avenue from its south corner, d metres in from the centre of the avenue
func coop_point(s: float, d: float) -> Vector2:
	if coop.is_empty():
		return poi("Labradores")
	var u := Vector2(coop["u"][0], coop["u"][1])
	return Vector2(coop["o"][0], coop["o"][1]) + u * s + Vector2(-u.y, u.x) * d
