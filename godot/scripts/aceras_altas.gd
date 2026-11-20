extends "res://scripts/obra.gd"
## High pavements: where the pavements of a street stand well over the road on walls of rubble, with a coping of
## concrete along the kerb and a floor of chequered tiles, and come down to the road in a few steps at their ends --
## as along the Calle del Arroyuelo Bajo (Street View, November 2024; the user, 15 November 2026: "Se podría trabajar
## en las aceras altas y ver cómo quedan"). Built the way the pavements of the old bridge are (puente.gd), whose look
## the user liked.
##
## The stretches come from the bake (tools/bake_godot.py, ACERAS_ALTAS; MapData.aceras): points along the middle of
## the street, the way out to the pavement's side, how high its floor is there, and the two nodes of the street each
## point lies between. The floor goes from the edge of the asphalt as the world draws it (world.gd's fitted ribbon:
## MapData.clr) to OUT beyond it, on under the houses as the town's own pavements do; the bake has set the houses
## along each stretch level with it. People walk on it (MapData.decks); it is solid (a body of its own).

const Puente = preload("res://scripts/puente.gd")

const OUT := 3.2            # how far past the edge of the asphalt the floor goes
const RISER := 0.17         # the steps at the ends
const TREAD := 0.3

var stretches := 0          # how many it built (for the self-test)
static var _areas: Array = []  # [Rect2, [PackedVector2Array, ...]] for each stretch: where its floor is (on())

## whether a spot is on one of the high pavements (props.gd stands things there on its floor, not on the road's level)
static func on(p: Vector2) -> bool:
	for ar in _areas:
		if not (ar[0] as Rect2).has_point(p):
			continue
		for poly in ar[1]:
			if Geometry2D.is_point_in_polygon(p, poly):
				return true
	return false

static func add(world) -> void:
	if MapData.aceras.is_empty():          # (a map baked without them)
		return
	var a = (load("res://scripts/aceras_altas.gd") as GDScript).new()
	a.build(world)

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"rubble":           # the walls that hold the pavements up
			m = Tex.mat("stone_wall")
		"hormigon":         # the coping along the kerb, the steps
			m = Tex.mat("granular_concrete", Color(0.86, 0.84, 0.8), false)
		"tiling":           # the chequered tiles of the floor (the same as by the old bridge)
			var sh := Shader.new()
			sh.code = Puente.TILES
			var sm := ShaderMaterial.new()
			sm.shader = sh
			m = sm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	level = 0.0
	transform = Transform3D.IDENTITY
	world.add_child(self)
	_areas.clear()                          # (a new town: forget the last one's)
	for st in MapData.aceras:
		_stretch(st)
	_commit()
	MapData.decks = _decks + MapData.decks

## the edge of the asphalt at a node of the street, from its middle (as world.gd's fitted ribbon draws it)
func _hw(node: int, w: float) -> float:
	return minf(w / 2.0, maxf(1.8, float(MapData.clr[node]) - 0.5))

func _stretch(st: Dictionary) -> void:
	var pts: Array = st["pts"]
	if pts.size() < 2:
		return
	var w: float = float(st.get("w", 7.5))
	var kerb: Array = []
	var outer: Array = []
	var tops: Array = []
	for q in pts:
		var c := Vector2(float(q[0]), float(q[1]))
		var n := Vector2(float(q[2]), float(q[3]))
		var hw: float = lerpf(_hw(int(q[5]), w), _hw(int(q[6]), w), float(q[7]))
		kerb.append(c + n * hw)
		outer.append(c + n * (hw + OUT))
		tops.append(float(q[4]))
	for i in range(pts.size() - 1):
		var a: Vector2 = kerb[i]
		var b: Vector2 = kerb[i + 1]
		var c: Vector2 = outer[i + 1]
		var d: Vector2 = outer[i]
		var ya: float = tops[i]
		var yb: float = tops[i + 1]
		pieces += 1
		quad(Vector3(a.x, ya, a.y), Vector3(d.x, ya, d.y), Vector3(c.x, yb, c.y), Vector3(b.x, yb, b.y), "tiling", Vector3.UP)
		var n := Vector2(float(pts[i][2]), float(pts[i][3]))
		_face(a, b, ya, yb, -n)
		var low: float = minf(MapData.height(a), MapData.height(b)) - 0.8
		_hull([Vector3(a.x, ya, a.y), Vector3(b.x, yb, b.y), Vector3(c.x, yb, c.y), Vector3(d.x, ya, d.y),
			Vector3(a.x, low, a.y), Vector3(b.x, low, b.y), Vector3(c.x, low, c.y), Vector3(d.x, low, d.y)])
		var deck := _poly_deck(PackedVector2Array([a, b, c, d]), (ya + yb) / 2.0)
		var run: float = (b - a).length()
		if run > 0.01 and absf(yb - ya) > 0.001:
			deck["grad"] = (b - a) / run * ((yb - ya) / run)
		_decks.append(deck)
		yard.append(a)
	# the steps down to the road at both ends, the whole width of the floor
	var polys: Array = []
	var box2 := Rect2(kerb[0], Vector2.ZERO)
	for i in range(pts.size() - 1):
		polys.append(PackedVector2Array([kerb[i], kerb[i + 1], outer[i + 1], outer[i]]))
		box2 = box2.expand(kerb[i + 1]).expand(outer[i]).expand(outer[i + 1])
	_areas.append([box2.grow(0.5), polys])
	var last := pts.size() - 1
	for end in [[0, 1], [last, last - 1]]:
		var k: int = end[0]
		var inward: Vector2 = (kerb[end[1]] - kerb[k]).normalized()
		var mid: Vector2 = (kerb[k] + outer[k]) / 2.0
		var y: float = tops[k]
		var drop: float = y - MapData.height(kerb[k] - inward * 1.0)
		if drop < 0.08:
			continue
		var n_steps: int = maxi(2, int(round(drop / RISER)))
		_flight(mid, y, -inward, (kerb[k] as Vector2).distance_to(outer[k]), drop, n_steps)
	stretches += 1

## a wall of rubble along the kerb from a to b, its top at ya and yb, faced on the side `out` (the road), under a coping
func _face(a: Vector2, b: Vector2, ya: float, yb: float, out: Vector2) -> void:
	var d := b - a
	if Vector2(-d.y, d.x).dot(out) < 0.0:          # (the face is drawn on the side the corners turn to)
		var t := a; a = b; b = t
		var ty := ya; ya = yb; yb = ty
	var ga: float = MapData.height(a + out * 0.3) - 0.3
	var gb: float = MapData.height(b + out * 0.3) - 0.3
	quad(Vector3(a.x, ga, a.y), Vector3(b.x, gb, b.y), Vector3(b.x, yb, b.y), Vector3(a.x, ya, a.y), "rubble", Vector3(out.x, 0, out.y))
	var inn: Vector2 = -out * 0.1
	bar(Vector3(a.x + inn.x, ya - 0.03, a.y + inn.y), Vector3(b.x + inn.x, yb - 0.03, b.y + inn.y), 0.3, 0.08, "hormigon")

## A flight of steps coming down from `edge` (the middle of its top edge, at height y) towards `down`: `n` risers to
## drop `drop`, `wide` across (as by the old bridge, puente.gd)
func _flight(edge: Vector2, y: float, down: Vector2, wide: float, drop: float, n: int) -> void:
	down = down.normalized()
	var rise: float = drop / n
	var keep := _xf
	_xf = Transform3D(Basis(Vector3(down.y, 0, -down.x), Vector3.UP, Vector3(down.x, 0, down.y)), Vector3(edge.x, y, edge.y))
	for k in range(1, n):
		box(-wide / 2.0, -drop - 0.4, (k - 1) * TREAD, wide, drop + 0.4 - k * rise, TREAD, "hormigon")
	_xf = keep
	var run: float = TREAD * (n - 1)
	var foot: Vector2 = edge + down * (run + 0.3)
	var side := Vector2(down.y, -down.x) * wide / 2.0
	var c0: Vector2 = edge + side
	var c1: Vector2 = edge - side
	var c2: Vector2 = foot - side
	var c3: Vector2 = foot + side
	_hull([Vector3(c0.x, y, c0.y), Vector3(c1.x, y, c1.y), Vector3(c2.x, y - drop - 0.04, c2.y), Vector3(c3.x, y - drop - 0.04, c3.y),
		Vector3(c0.x, y - drop - 0.4, c0.y), Vector3(c1.x, y - drop - 0.4, c1.y), Vector3(c2.x, y - drop - 0.4, c2.y), Vector3(c3.x, y - drop - 0.4, c3.y)])
	var mid: Vector2 = edge + down * run / 2.0
	_decks.append({"o": mid, "ax": -down, "half": run / 2.0 + 0.25, "wide": wide / 2.0, "top": y, "ramp": run, "low": y - drop})
