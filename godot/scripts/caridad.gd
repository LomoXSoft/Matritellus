extends "res://scripts/obra.gd"
## The hermitage of the Caridad with its square, the park of the fountain and the nursery, built by hand (the user,
## 15 November 2026: "Ahora pinta con la hermita de la caridad. Que es hermita, parque con fuente y guardería";
## referencias/ermita_caridad/, tools/caridad/).
##
## The island between the Avenida de Juan Carlos I (south), the Calle del Rollo (north), the Calle del Peso (east) and
## the roundabout of the Viñas (west), as Street View's cars and three round pictures taken inside it have it (the user,
## on the first version: "Creo que no has hecho suficientes capturas. En esos tres círculos street view tiene imágenes
## 360 de la zona"): a garden raised over the avenue behind a wall of rubble with brick piers and iron railings.
## The hermitage is long, tall and white on a foot of rubble; its front is its WEST end, towards the park -- a great
## arched door, a niche, two lanterns, and four columns of granite standing before it on a low wall --, a lower house
## with a wooden gate leaning on its north side, a small door on the square, a square body at its south-east corner
## and the little bell-gable over its east end. Before it, the square: beaten earth, a walk of chequered tiles with
## benches and lanterns, lawns with old elms behind low green rails, and the cross of granite among its cypresses.
## To the east the nursery, of rubble and brick, its play yard behind railings of every colour; to the west the
## park, earth and beds of grass, with its round fountain of rubble.
##
## Frame: origin at the hermitage's south-west corner; +x along its south side (east), +z out of it, towards the
## avenue; y = 0 the square's floor at x = 0.
## The game's ground falls seven metres across the island (its relief is exaggerated) and is NOT levelled: the square
## is a floor that meets the ground at the foot of the buildings and ends over the avenue on its wall (it slopes a
## little down to the west, `SLOPE`); the nursery's yard is a step higher; the buildings are part buried on the Calle
## del Rollo, which runs higher; the park keeps the ground as it is.
## No children are put in the yard (the user: no new characters for now). The gate of the yard is shut.

const READY := true                             # (tools/bake_godot.py looks for this: with it, Catastro's blocks are not raised here)
const O := Vector2(-489.5, 141.2)
const U := Vector2(0.9984, -0.0564)
const SLOPE := 0.0415                           # how much the square rises to the metre, eastwards
const LE := 23.04                               # the hermitage's south side
const FE := 0.48                                # its floor (the square at its door)
const HE := 6.0                                 # its nave's walls
const NAVE := 8.6                               # how deep the nave is (the lower house behind it takes the rest)
const HA := 4.1                                 # the lower house's walls
const ANNEX: Array = [Vector2(0.15, -8.6), Vector2(22.7, -8.6), Vector2(18.76, -23.58), Vector2(3.27, -18.85), Vector2(0.15, -16.82)]
const ERMITA: Array = [Vector2(0, 0), Vector2(23.04, 0), Vector2(23.05, -7.41), Vector2(18.76, -23.58), Vector2(3.27, -18.85), Vector2(0.15, -16.82)]
const TOWER := Rect2(23.04, -7.4, 5.61, 7.5)    # the square body at its corner (x, z, wide, deep)
const HT := 7.2
const NURSERY: Array = [Vector2(18.76, -23.58), Vector2(23.55, -25.11), Vector2(42.1, -30.78), Vector2(45.07, -19.39), Vector2(47.9, -9.21), Vector2(28.67, -3.99), Vector2(28.66, -7.4), Vector2(23.05, -7.41)]
const YARD: Array = [Vector2(28.67, -3.99), Vector2(47.9, -9.21), Vector2(50.6, 1.5), Vector2(28.67, 1.5)]
const FOUNTAIN := Vector2(-10.2, 3.2)
const CROSS := Vector2(12.7, 11.4)
const YARD_PAINT: Array = [0x2a62c8, 0x2a62c8, 0xe8c020, 0xc8323a, 0x2f9a4a]      # the yard's railings, from the hermitage's corner on
const PAINT: Array = [0xe8c020, 0x2a62c8, 0xc8323a, 0x2f9a4a]
const PLAY_SET := "res://assets/parque/juegos.glb"

var door: Vector2               # in front of the hermitage's door, on the map
var fn := 0.0                   # the nursery's floor and yard
var en := 0.0                   # its eaves
var _floor_decks: Array = []

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"blanco":
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.985, 0.95)), 0.4)
		"crema":
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.95, 0.88, 0.74)), 0.3)
		"rubble":
			m = Tex.mat("stone_wall")
		"granito":
			m = Tex.mat("granular_concrete", Color(0.78, 0.77, 0.76), false)
		"columna":          # the old columns: a paler granite, worn
			m = _glow(Tex.mat("granular_concrete", Color(0.97, 0.95, 0.9), false), 0.25)
		"hormigon":
			m = Tex.mat("granular_concrete", Color(0.86, 0.84, 0.8), false)
		"tierra":           # the square's floor: beaten earth
			m = W._tmat(0xcdb890, "earth", 2.4)
		"losa":             # its paved walks
			m = W._tmat(0xd9cfc0, "pavement", 1.2)
		"cesped":
			m = W._tmat(0x6fa24e, "leaf", 2.0)
		"leaf":
			m = W._tmat(0x5a9a48, "leaf", 1.3)
		"cipres":
			m = W._tmat(0x2f5a36, "leaf", 1.0)
		"agua":
			var wm := StandardMaterial3D.new()
			wm.albedo_color = Color(0.36, 0.62, 0.78)
			wm.roughness = 0.15
			wm.emission_enabled = true
			wm.emission = Color(0.3, 0.55, 0.7)
			wm.emission_energy_multiplier = 0.25
			m = wm
		_:
			return super(key)
	_mats[key] = m
	return m

## the square's floor at x (it rises a little towards the Calle del Peso)
func sq(x: float) -> float:
	return SLOPE * x

## where the wall over the avenue runs, at x
func wall_z(x: float) -> float:
	return 16.17 - 0.1337 * x

func build(world) -> void:
	W = world
	var data: Dictionary = MapData.caridad
	var o := Vector2(data["o"][0], data["o"][1]) if data.has("o") else O
	var u := Vector2(data["u"][0], data["u"][1]) if data.has("u") else U
	var out := Vector2(-u.y, u.x)
	level = -99.0                                   # (the square's floor never dips under the ground at the foot of the buildings)
	for x in [0.0, 6.0, 12.0, 18.0, 23.0, 26.0, 29.0]:
		level = maxf(level, MapData.height(o + u * x + out * 0.4) - SLOPE * x)
	level += 0.05
	transform = Transform3D(Basis(Vector3(u.x, 0, u.y), Vector3.UP, Vector3(out.x, 0, out.y)), Vector3(o.x, level, o.y))
	W.add_child(self)
	door = spot(11.5, 2.0)
	fn = sq(38.0) + 0.6
	for q in [Vector2(30, -3.5), Vector2(38, -6.0), Vector2(47, -8.5), Vector2(49.5, -2.0), Vector2(40, 1.0), Vector2(30, 1.0)]:
		fn = maxf(fn, ground(q.x, q.y) + 0.08)
	en = maxf(fn + 3.3, ground(41.0, -31.6) + 2.75)
	_square()
	_hermitage()
	_tower()
	_nursery()
	_yard()
	_cross()
	_green()
	_fountain()
	home()
	_commit()
	_tell_map()
	MapData.decks = _decks + _floor_decks + MapData.decks

## What stands here, for whoever asks the map how much room there is and for the little map.
func _tell_map() -> void:
	var t: Array = [TOWER.position, Vector2(TOWER.end.x, TOWER.position.y), TOWER.end, Vector2(TOWER.position.x, TOWER.end.y)]
	for ring in [ERMITA, NURSERY, t]:
		var pts := PackedVector2Array()
		for q: Vector2 in ring:
			pts.append(spot(q.x, q.y))
		MapData.outlines.append(pts)
		if not MapData._wall_grid.is_empty():
			for i in range(pts.size()):
				var a: Vector2 = pts[i]
				var b: Vector2 = pts[(i + 1) % pts.size()]
				MapData._grid_add(MapData._wall_grid, a.min(b), a.max(b), [a, b])

# ---------------- helpers ----------------
## a level (or gently sloping) floor people walk on: its top, what holds it up, and the map told
func _floor(pts: Array, key, slope := true, y := 0.0) -> void:
	var top: Array = []
	var low := 99.0
	var flatp := PackedVector2Array()
	var mid := 0.0
	for q: Vector2 in pts:
		var h: float = sq(q.x) if slope else y
		top.append(Vector3(q.x, h, q.y))
		low = minf(low, ground(q.x, q.y))
		flatp.append(q)
		mid += q.x / pts.size()
	pieces += 1
	if top.size() == 4:
		quad(top[0], top[1], top[2], top[3], key, Vector3.UP)
	else:
		for i in range(1, top.size() - 1):
			tri(top[0], top[i], top[i + 1], key, Vector3.UP)
	var all: Array = top.duplicate()
	for q: Vector3 in top:
		all.append(Vector3(q.x, low - 1.0, q.z))
	_hull(all)
	var deck := _poly_deck(flatp, level + (sq(mid) if slope else y))
	if slope:
		deck["grad"] = Vector2(transform.basis.x.x, transform.basis.x.z) * SLOPE
	_floor_decks.append(deck)

## A wall of rubble from under the ground up to `top`, between two places of the floor plan, seen from `a`'s left...
## with its coping; solid. `rail`: an iron railing on it (0: none); `hex`: its colour.
func _rubble(a: Vector2, b: Vector2, top: float, rail := 0.0, hex := IRON, thick := 0.45) -> void:
	var ln: float = face(a, b)
	var low: float = minf(ground(a.x, a.y), ground(b.x, b.y)) - 0.8
	box(0.0, low, -thick, ln, top - low, thick, "rubble")
	box(-0.03, top, -thick - 0.04, ln + 0.06, 0.1, thick + 0.08, "hormigon")
	if rail > 0.0:
		var y0: float = top + 0.14
		box(0.0, y0 + rail - 0.04, -thick / 2.0 - 0.02, ln, 0.04, 0.04, hex)
		box(0.0, y0 + 0.08, -thick / 2.0 - 0.015, ln, 0.03, 0.03, hex)
		var n := maxi(2, int(round(ln / 0.14)))
		for i in range(n + 1):
			box(ln * i / n - 0.01, y0, -thick / 2.0 - 0.01, 0.02, rail, 0.02, hex)
	home()
	var d: Vector2 = (b - a).normalized()
	var mid: Vector2 = (a + b) / 2.0 + Vector2(d.y, -d.x) * (thick / 2.0)
	solid(Vector3(mid.x, (low + top + rail) / 2.0, mid.y), Vector3(ln, top + rail - low, thick), atan2(-d.y, d.x))
	yard.append(spot(a.x, a.y))
	yard.append(spot(b.x, b.y))

## a brick pier on a wall's end
func _pier(at: Vector2, top: float, tall := 0.95) -> void:
	cbox(Vector3(at.x, top + tall / 2.0, at.y), Vector3(0.58, tall, 0.58), "brick")
	cbox(Vector3(at.x, top + tall + 0.04, at.y), Vector3(0.68, 0.08, 0.68), "hormigon")

## A flight of steps coming down from `edge` (the middle of its top edge, at height y) towards `down`.
func _flight(edge: Vector2, y: float, down: Vector2, wide: float, drop: float) -> void:
	if drop < 0.12:
		return
	down = down.normalized()
	var n: int = maxi(2, int(round(drop / 0.17)))
	var tread := 0.32
	var rise: float = drop / n
	var keep := _xf
	_xf = Transform3D(Basis(Vector3(down.y, 0, -down.x), Vector3.UP, Vector3(down.x, 0, down.y)), Vector3(edge.x, y, edge.y))
	for k in range(1, n):
		box(-wide / 2.0, -drop - 0.4, (k - 1) * tread, wide, drop + 0.4 - k * rise, tread, "hormigon")
	_xf = keep
	var run: float = tread * (n - 1)
	var foot: Vector2 = edge + down * run
	var side := Vector2(down.y, -down.x) * wide / 2.0
	var c: Array = [edge + side, edge - side, foot - side, foot + side]
	_hull([Vector3(c[0].x, y, c[0].y), Vector3(c[1].x, y, c[1].y), Vector3(c[2].x, y - drop + rise, c[2].y), Vector3(c[3].x, y - drop + rise, c[3].y),
		Vector3(c[0].x, y - drop - 0.4, c[0].y), Vector3(c[1].x, y - drop - 0.4, c[1].y), Vector3(c[2].x, y - drop - 0.4, c[2].y), Vector3(c[3].x, y - drop - 0.4, c[3].y)])
	var mid: Vector2 = edge + down * run / 2.0
	var up_axis: Vector2 = (spot(0.0, 0.0) - spot(down.x, down.y)).normalized()
	_decks.append({"o": spot(mid.x, mid.y), "ax": up_axis, "half": run / 2.0, "wide": wide / 2.0, "top": level + y, "ramp": run, "low": level + y - drop})

## A roof of tiles over any outline: every eave runs up to the nearer end of the ridge (r0 -- r1).
func _tent(ring: Array, r0: Vector2, r1: Vector2, ye: float, yr: float, out := 0.45) -> void:
	var c := Vector2.ZERO
	for q: Vector2 in ring:
		c += q / ring.size()
	var a0 := Vector3(r0.x, yr, r0.y)
	var a1 := Vector3(r1.x, yr, r1.y)
	var n := ring.size()
	for i in range(n):
		var a: Vector2 = ring[i] + (ring[i] - c).normalized() * out
		var b: Vector2 = ring[(i + 1) % n] + (ring[(i + 1) % n] - c).normalized() * out
		var ra: Vector3 = a0 if a.distance_to(r0) <= a.distance_to(r1) else a1
		var rb: Vector3 = a0 if b.distance_to(r0) <= b.distance_to(r1) else a1
		var pa := Vector3(a.x, ye, a.y)
		var pb := Vector3(b.x, ye, b.y)
		if ra == rb:
			roof([pa, pb, ra])
		else:
			roof([pa, pb, rb])
			roof([pa, rb, ra])
		ridge(pa, ra)
	ridge(a0, a1)

## a tree: its trunk and its crown (`kind` 0: an elm cut back many times; 1: a cypress)
func _tree(at: Vector2, tall: float, kind := 0, y := -99.0) -> void:
	var g: float = ground(at.x, at.y) if y < -90.0 else y
	if kind == 1:
		drum(Vector3(at.x, g, at.y), 0.16, 0.12, 1.2, 0x5a4636, 7)
		drum(Vector3(at.x, g + 0.9, at.y), 1.0, 0.75, tall * 0.45, "cipres", 9)
		drum(Vector3(at.x, g + 0.9 + tall * 0.45, at.y), 0.75, 0.08, tall * 0.55 - 0.9, "cipres", 9)
	else:
		var crown: float = tall * 0.3
		drum(Vector3(at.x, g - 0.3, at.y), 0.26, 0.18, tall * 0.55, 0x6b5a45, 8)
		ball(Vector3(at.x, g + tall * 0.72, at.y), crown, "leaf", 0.85, 10, 6)
		ball(Vector3(at.x + crown * 0.6, g + tall * 0.6, at.y - crown * 0.3), crown * 0.7, "leaf", 0.85, 9, 5)
		ball(Vector3(at.x - crown * 0.55, g + tall * 0.62, at.y + crown * 0.3), crown * 0.68, "leaf", 0.85, 9, 5)
	solid(Vector3(at.x, g + 1.0, at.y), Vector3(0.4, 2.4, 0.4))
	yard.append(spot(at.x, at.y))

## a lamp: a tall dark post and its lantern
func _lamp(at: Vector2, y: float) -> void:
	drum(Vector3(at.x, y, at.y), 0.08, 0.055, 4.0, 0x2e3134, 7)
	cbox(Vector3(at.x, y + 4.22, at.y), Vector3(0.3, 0.44, 0.3), 0xf2ecd2)
	cbox(Vector3(at.x, y + 4.47, at.y), Vector3(0.42, 0.07, 0.42), 0x2e3134)
	cbox(Vector3(at.x, y + 4.0, at.y), Vector3(0.2, 0.06, 0.2), 0x2e3134)
	yard.append(spot(at.x, at.y))

## a bench: of stone slabs (the park's), or of iron and slats (`iron`: the square's)
func _bench(at: Vector2, y: float, along: Vector2, iron := false) -> void:
	var keep := _xf
	_xf = Transform3D(Basis(Vector3(along.x, 0, along.y), Vector3.UP, Vector3(-along.y, 0, along.x)), Vector3(at.x, y, at.y))
	if iron:
		for i in range(4):
			box(-0.85, 0.42, -0.2 + i * 0.11, 1.7, 0.03, 0.09, 0x8a5a34)
		for i in range(3):
			box(-0.85, 0.52 + i * 0.13, -0.26, 1.7, 0.09, 0.03, 0x8a5a34)
		for s in [-0.8, 0.74]:
			box(s, 0.0, -0.26, 0.06, 0.9, 0.05, 0x26262a)
			box(s, 0.0, -0.22, 0.06, 0.42, 0.46, 0x26262a)
	else:
		box(-0.9, 0.38, -0.22, 1.8, 0.09, 0.44, "granito")
		box(-0.8, 0.0, -0.18, 0.16, 0.38, 0.36, "granito")
		box(0.64, 0.0, -0.18, 0.16, 0.38, 0.36, "granito")
	_xf = keep
	solid(Vector3(at.x, y + 0.25, at.y), Vector3(1.8, 0.5, 0.45), atan2(-along.y, along.x))
	yard.append(spot(at.x, at.y))

## a piece of ground laid over the ground as it lies (each corner at its own height), a hand above it
func _drape(pts: Array, key, lift := 0.04) -> void:
	var c := Vector2.ZERO
	for q: Vector2 in pts:
		c += q / pts.size()
	var cc := Vector3(c.x, ground(c.x, c.y) + lift, c.y)
	for i in range(pts.size()):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		tri(cc, Vector3(a.x, ground(a.x, a.y) + lift, a.y), Vector3(b.x, ground(b.x, b.y) + lift, b.y), key, Vector3.UP)
	pieces += 1

## a round wall in stretches: between two radii, `h` high, of `n` sides; `open`: which sides are left out
func _ring_wall(c: Vector3, r0: float, r1: float, h: float, n: int, open: Array, key) -> void:
	for i in range(n):
		if open.has(i):
			continue
		var a0: float = TAU * i / n
		var a1: float = TAU * (i + 1) / n
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var up := Vector3(0, h, 0)
		var nm: Vector3 = (d0 + d1).normalized()
		quad(c + d0 * r1, c + d1 * r1, c + d1 * r1 + up, c + d0 * r1 + up, key, nm)
		quad(c + d0 * r0, c + d1 * r0, c + d1 * r0 + up, c + d0 * r0 + up, key, -nm)
		quad(c + d0 * (r0 - 0.04) + up, c + d1 * (r0 - 0.04) + up, c + d1 * (r1 + 0.04) + up, c + d0 * (r1 + 0.04) + up, "hormigon", Vector3.UP)
		if open.has((i + n - 1) % n):
			quad(c + d0 * r0, c + d0 * r1, c + d0 * r1 + up, c + d0 * r0 + up, key, Vector3(sin(a0), 0, -cos(a0)))
		if open.has((i + 1) % n):
			quad(c + d1 * r0, c + d1 * r1, c + d1 * r1 + up, c + d1 * r0 + up, key, Vector3(-sin(a1), 0, cos(a1)))
		pieces += 1

# ---------------- the square ----------------
## From the buildings to the avenue: a paved strip along the walls, beaten earth, a walk of chequered tiles with its
## benches and lamps, and the lawn with the old elms behind a low green rail, up to the wall over the avenue.
func _square() -> void:
	var xe := 28.67                              # where the nursery's yard begins
	var x1 := 54.3
	_floor([Vector2(-2.0, 0.0), Vector2(xe, 0.0), Vector2(xe, wall_z(xe)), Vector2(-2.0, wall_z(-2.0))], "tierra")
	_floor([Vector2(xe, 1.5), Vector2(x1, 1.5), Vector2(x1 + 1.5, wall_z(x1 + 1.5)), Vector2(xe, wall_z(xe))], "tierra")
	quad(Vector3(-2.0, sq(-2.0) + 0.012, 0.0), Vector3(xe, sq(xe) + 0.012, 0.0), Vector3(xe, sq(xe) + 0.012, 1.3), Vector3(-2.0, sq(-2.0) + 0.012, 1.3), "losa", Vector3.UP)
	quad(Vector3(xe, sq(xe) + 0.012, 1.5), Vector3(x1, sq(x1) + 0.012, 1.5), Vector3(x1, sq(x1) + 0.012, 2.4), Vector3(xe, sq(xe) + 0.012, 2.4), "losa", Vector3.UP)
	# the walk: red and cream tiles in a chequer
	var w0 := 4.6
	var w1 := 7.8
	var t := 0.4
	var nx := int((x1 + 2.4) / t)
	for i in range(nx):
		for j in range(8):
			var xa: float = -2.0 + i * t
			quad(Vector3(xa, sq(xa) + 0.014, w0 + j * t), Vector3(xa + t, sq(xa + t) + 0.014, w0 + j * t), Vector3(xa + t, sq(xa + t) + 0.014, w0 + (j + 1) * t), Vector3(xa, sq(xa) + 0.014, w0 + (j + 1) * t),
				0xb0705a if (i % 4 == 0 and j % 4 == 0) or (i % 4 == 2 and j % 4 == 2) else (0xd6cfc2 if (i + j) % 2 == 0 else 0xc2bbae), Vector3.UP)
	# the lawn, and the low green rail that keeps people off it
	var lz := w1 + 0.25
	for x0 in [-1.6, 17.0, 24.2, 31.4, 38.6, 45.8]:
		var xa: float = x0
		var xb: float = minf(x0 + 7.0, x1 + 0.6)
		if x0 < 0.0:
			xb = 8.4                              # (the cross and its cypresses stand on a floor of their own)
		quad(Vector3(xa, sq(xa) + 0.016, lz), Vector3(xb, sq(xb) + 0.016, lz), Vector3(xb, sq(xb) + 0.016, wall_z(xb) - 0.6), Vector3(xa, sq(xa) + 0.016, wall_z(xa) - 0.6), "cesped", Vector3.UP)
		var n := maxi(2, int(round((xb - xa) / 1.5)))
		for i in range(n + 1):
			var xp: float = xa + (xb - xa) * i / n
			cbox(Vector3(xp, sq(xp) + 0.24, lz), Vector3(0.035, 0.48, 0.035), 0x2f6a3a)
		bar(Vector3(xa, sq(xa) + 0.46, lz), Vector3(xb, sq(xb) + 0.46, lz), 0.035, 0.035, 0x2f6a3a)
		bar(Vector3(xa, sq(xa) + 0.24, lz), Vector3(xb, sq(xb) + 0.24, lz), 0.03, 0.03, 0x2f6a3a)
	quad(Vector3(8.4, sq(8.4) + 0.016, lz), Vector3(17.0, sq(17.0) + 0.016, lz), Vector3(17.0, sq(17.0) + 0.016, wall_z(17.0) - 0.6), Vector3(8.4, sq(8.4) + 0.016, wall_z(8.4) - 0.6), "losa", Vector3.UP)
	# the wall over the avenue: rubble, a brick pier every few metres, railings between
	var marks: Array = [-2.0, 5.2, 12.4, 19.6, 26.8, 34.0, 41.2, 48.4, x1 + 1.5]
	for i in range(marks.size() - 1):
		var a := Vector2(marks[i], wall_z(marks[i]))
		var b := Vector2(marks[i + 1], wall_z(marks[i + 1]))
		_rubble(a, b, sq((a.x + b.x) / 2.0) + 0.1, 0.85)
		_pier(a + Vector2(0.0, -0.22), sq(a.x) + 0.1)
	_pier(Vector2(x1 + 1.5, wall_z(x1 + 1.5) - 0.22), sq(x1 + 1.5) + 0.1)
	# towards the Calle del Peso: a low wall, and the walk coming in up a few steps
	var e0 := Vector2(x1, 1.5)
	var e1 := Vector2(x1 + 1.5, wall_z(x1 + 1.5))
	var gap0: Vector2 = e0.lerp(e1, (w0 - 0.2 - 1.5) / (e1.y - 1.5))
	var gap1: Vector2 = e0.lerp(e1, minf(0.97, (w1 + 0.2 - 1.5) / (e1.y - 1.5)))
	_rubble(gap0, e0, sq(x1) + 0.1, 0.85)
	_rubble(e1, gap1, sq(x1) + 0.1, 0.85)
	var gm: Vector2 = (gap0 + gap1) / 2.0
	_flight(gm, sq(x1), Vector2(1.0, -0.2), gap0.distance_to(gap1) - 0.1, sq(x1) - ground(gm.x + 2.2, gm.y))
	# towards the park: the same, the steps where the walk goes on
	_rubble(Vector2(-2.0, 0.0), Vector2(-2.0, w0 - 0.2), sq(-2.0) + 0.1, 0.0)
	_rubble(Vector2(-2.0, w1 + 0.2), Vector2(-2.0, wall_z(-2.0)), sq(-2.0) + 0.1, 0.85)
	_flight(Vector2(-2.0, (w0 + w1) / 2.0), sq(-2.0), Vector2(-1.0, 0.0), w1 - w0 + 0.2, sq(-2.0) - ground(-4.4, (w0 + w1) / 2.0))
	# lamps and benches along the walk
	for x in [2.5, 20.5, 32.0, 43.5, 52.0]:
		_lamp(Vector2(x, w0 - 0.35), sq(x))
	for x in [6.5, 26.0, 37.5, 48.0]:
		_bench(Vector2(x, w1 - 0.4), sq(x), Vector2(-1, 0), true)
	# the old elms, in the lawn; and the cypresses that keep the cross company
	for x in [2.4, 20.6, 27.8, 35.0, 42.2, 49.4]:
		_tree(Vector2(x, (lz + wall_z(x)) / 2.0 + 0.4), 9.0, 0, sq(x))
	for q in [Vector2(CROSS.x - 3.0, CROSS.y - 0.4), Vector2(CROSS.x + 3.1, CROSS.y - 0.2), Vector2(CROSS.x - 1.7, CROSS.y + 1.9), Vector2(CROSS.x + 1.9, CROSS.y + 1.8)]:
		_tree(q, 9.5, 1, sq(q.x))

# ---------------- the hermitage ----------------
## The nave: long and tall, white on a foot of rubble, under four slopes of tiles. Its front is its west end, towards
## the park: the great arched door, a niche over it, a lantern each side, and four columns of granite standing before it
## on a low wall. A lower house leans on its north side, with a wooden gate; a small door gives on to the square.
func _hermitage() -> void:
	# --- the south side, on the square ---
	face(Vector2(0, 0), Vector2(LE, 0), FE)
	var side := Rect2(12.9, 0.0, 1.3, 2.35)
	var wins: Array = [Rect2(4.2, 4.0, 0.55, 0.9), Rect2(9.2, 4.0, 0.55, 0.9), Rect2(18.6, 4.0, 0.55, 0.9)]
	var holes: Array = [side]
	holes.append_array(wins)
	masonry(0.0, LE, -1.8, HE, holes, [], "blanco")
	box(0.0, -1.8, 0.0, side.position.x - 0.22, 2.8, 0.06, "rubble")
	box(side.end.x + 0.22, -1.8, 0.0, LE - side.end.x - 0.22, 2.8, 0.06, "rubble")
	for q in [[side.position.x - 0.2, 0.0, 0.2, side.size.y + 0.2], [side.end.x, 0.0, 0.2, side.size.y + 0.2], [side.position.x - 0.2, side.size.y, side.size.x + 0.4, 0.2]]:
		box(q[0], q[1], 0.0, q[2], q[3], 0.05, 0xf4f1e8)
	box(side.position.x, 0.0, -DEEP, side.size.x, side.size.y, 0.06, 0x4a2e1e)
	for w: Rect2 in wins:
		window(w, 0x4a3324, 0x2a3640, 0)
	cornice(0.0, LE, HE + 0.42, true, "brick")
	home()
	# --- the west end: its front ---
	face(Vector2(0, -NAVE), Vector2(0, 0), FE)
	var r := 1.35
	var spring := 2.2
	var gate := Rect2(NAVE / 2.0 - r, 0.0, 2.0 * r, spring + r)
	var niche := Rect2(NAVE / 2.0 - 0.28, 4.95, 0.56, 0.75)
	masonry(0.0, NAVE, -2.4, HE, [gate, niche], [], "blanco")
	box(0.0, -2.4, 0.0, gate.position.x - 0.4, 3.4, 0.06, "rubble")
	box(gate.end.x + 0.4, -2.4, 0.0, NAVE - gate.end.x - 0.4, 3.4, 0.06, "rubble")
	spandrels(NAVE / 2.0, spring, r, 0.0, "blanco")
	ring(NAVE / 2.0, spring, r, r + 0.42, 0.07, 0.34, 0xcdbfa6)                  # the arch and its jambs, of pale stone
	for s in [-1.0, 1.0]:
		box(NAVE / 2.0 + s * r - (0.0 if s < 0.0 else 0.42), 0.0, 0.0, 0.42, spring, 0.07, 0xcdbfa6)
		box(NAVE / 2.0 + s * (r + 0.62) - 0.07, 0.0, 0.0, 0.14, spring + r + 0.62, 0.05, 0xcdbfa6)      # the square frame round it all
	box(NAVE / 2.0 - r - 0.69, spring + r + 0.5, 0.0, 2.0 * r + 1.38, 0.14, 0.06, 0xcdbfa6)
	box(gate.position.x, 0.0, -DEEP, gate.size.x, gate.size.y, 0.07, 0x4a2c1a)     # the door: two leaves of old wood, studded
	box(NAVE / 2.0 - 0.014, 0.0, -DEEP + 0.07, 0.028, gate.size.y - 0.15, 0.014, 0x2a170e)
	for s in [0, 1]:
		for j in range(7):
			for i in range(3):
				box(gate.position.x + 0.2 + s * r + i * 0.43, 0.3 + j * 0.42, -DEEP + 0.07, 0.05, 0.05, 0.02, 0x8a8478)
	box(niche.position.x, niche.position.y, -DEEP, niche.size.x, niche.size.y, 0.05, 0x3a3f46)
	ring(NAVE / 2.0, niche.end.y, 0.3, 0.42, 0.03, 0.0, 0xcdbfa6, 8)
	slab(oval(NAVE / 2.0, spring + r + 1.08, 0.36, 0.36, 14), 0.04, 0.0, 0xd9cfb8)      # the round medallion over the arch
	slab(oval(NAVE / 2.0, spring + r + 1.08, 0.25, 0.25, 12), 0.05, 0.0, 0xb9ad98)
	for s in [-1.0, 1.0]:                           # a lantern each side
		var lx: float = NAVE / 2.0 + s * (r + 1.1)
		box(lx - 0.02, 2.75, 0.0, 0.04, 0.04, 0.3, IRON)
		box(lx - 0.1, 2.35, 0.2, 0.2, 0.36, 0.2, 0xf2e2a8)
		box(lx - 0.13, 2.71, 0.17, 0.26, 0.05, 0.26, IRON)
		box(lx - 0.12, 2.3, 0.18, 0.24, 0.05, 0.24, IRON)
	cornice(0.0, NAVE, HE + 0.42, true, "brick")
	home()
	# its other two walls, plain: the east end over the nursery's roof, the north one over the lower house
	for e in [[Vector2(LE, 0.0), Vector2(LE, -NAVE)], [Vector2(LE, -NAVE), Vector2(0.0, -NAVE)]]:
		var ln: float = face(e[0], e[1], FE)
		quad(Vector3(0, -2.0, 0), Vector3(ln, -2.0, 0), Vector3(ln, HE, 0), Vector3(0, HE, 0), "blanco", Vector3(0, 0, 1))
		cornice(0.0, ln, HE + 0.42, true, "brick")
		home()
	_hip(0.0, LE, -NAVE, 0.0, FE + HE + 0.42, 3.3, 0.55)
	solid(Vector3(LE / 2.0, FE + 2.5, -NAVE / 2.0), Vector3(LE, 10.0, NAVE))
	_espadana(LE - 1.0, -NAVE / 2.0, FE + HE + 1.1)
	# --- the lower house on its north side ---
	var top: float = FE + HA
	for i in range(1, ANNEX.size()):
		var a: Vector2 = ANNEX[i]
		var b: Vector2 = ANNEX[(i + 1) % ANNEX.size()]
		var ln: float = face(a, b, 0.0)
		if i == 4:                                # its west wall: a big gate of brown boards
			var g0: float = ground(a.x - 0.6, (a.y + b.y) / 2.0)
			var gt := Rect2(ln / 2.0 - 1.3, g0, 2.6, minf(2.8, top - g0 - 0.35))
			masonry(0.0, ln, -2.0, top, [gt], [], "blanco")
			box(gt.position.x, gt.position.y, -DEEP, gt.size.x, gt.size.y, 0.06, 0x5a3a26)
			for j in range(1, 8):
				box(gt.position.x + j * gt.size.x / 8.0 - 0.01, gt.position.y, -DEEP + 0.06, 0.02, gt.size.y, 0.01, 0x3f2618)
			box(0.0, -2.0, 0.0, gt.position.x - 0.1, g0 + 0.8 + 2.0, 0.05, "rubble")
			box(gt.end.x + 0.1, -2.0, 0.0, ln - gt.end.x - 0.1, g0 + 0.8 + 2.0, 0.05, "rubble")
		else:
			quad(Vector3(0, -2.0, 0), Vector3(ln, -2.0, 0), Vector3(ln, top, 0), Vector3(0, top, 0), "blanco", Vector3(0, 0, 1))
			if i == 2 or i == 3:
				var parts: int = maxi(1, int(round(ln / 4.0)))
				for k in range(parts):
					var t0: float = float(k) / parts
					var t1: float = float(k + 1) / parts
					var pm: Vector2 = a.lerp(b, (t0 + t1) / 2.0)
					var gm: float = ground(pm.x, pm.y - 0.5)
					box(ln * t0, -2.0, 0.0, ln * (t1 - t0), gm + 0.9 + 2.0, 0.04, 0xe6c4a4)
				if i == 2:
					box(ln * 0.3, top - 0.75, 0.0, 0.9, 0.22, 0.03, 0x4a4d52)
		home()
		yard.append(spot(a.x, a.y))
	_tent(ANNEX, Vector2(6.0, -14.0), Vector2(17.0, -15.6), top + 0.08, top + 1.5, 0.4)
	solid(Vector3(10.5, FE + 2.0, -14.6), Vector3(19.5, 9.0, 9.0), -0.3)
	# --- the paved way along the front, and beyond it the row of old columns of granite on their low wall ---
	var zz := -21.0
	while zz < -0.5:
		quad(Vector3(-3.5, ground(-3.5, zz) + 0.05, zz), Vector3(-0.08, ground(-0.08, zz) + 0.05, zz), Vector3(-0.08, ground(-0.08, zz + 3.0) + 0.05, zz + 3.0), Vector3(-3.5, ground(-3.5, zz + 3.0) + 0.05, zz + 3.0), "losa", Vector3.UP)
		zz += 3.0
	var cx := -4.3
	var places: Array = [-18.6, -14.5, -10.4, -6.3, -2.2]
	var tall: Array = [3.0, 3.35, 3.15, 3.4, 3.1]
	for k in range(places.size()):
		var zc: float = places[k]
		var gy: float = ground(cx, zc)
		if k < places.size() - 1:                # the low wall from this one to the next
			var zn: float = places[k + 1]
			var wy: float = maxf(gy, ground(cx, zn)) + 0.32
			var lw: float = minf(gy, ground(cx, zn)) - 0.8
			cbox(Vector3(cx, (wy + lw) / 2.0, (zc + zn) / 2.0), Vector3(0.7, wy - lw, zn - zc), "rubble")
			cbox(Vector3(cx, wy + 0.035, (zc + zn) / 2.0), Vector3(0.8, 0.07, zn - zc), "hormigon")
			solid(Vector3(cx, wy - 0.4, (zc + zn) / 2.0), Vector3(0.7, 1.6, zn - zc))
		cbox(Vector3(cx, gy + 0.3, zc), Vector3(1.0, 0.9, 1.0), "columna")
		drum(Vector3(cx, gy + 0.75, zc), 0.36, 0.31, float(tall[k]), "columna", 14)
		if k % 2 == 1:
			drum(Vector3(cx, gy + 0.75 + float(tall[k]), zc), 0.37, 0.37, 0.1, "columna", 14)
		solid(Vector3(cx, gy + 2.0, zc), Vector3(0.9, 4.4, 0.9))
		yard.append(spot(cx, zc))

## the little bell-gable: two piers, an arch, a pediment; its bell, its iron cross
func _espadana(bx: float, bz: float, by: float) -> void:
	box(bx - 0.25, by, bz - 0.8, 0.5, 1.6, 0.42, "blanco")
	box(bx - 0.25, by, bz + 0.38, 0.5, 1.6, 0.42, "blanco")
	box(bx - 0.25, by + 1.6, bz - 0.8, 0.5, 0.4, 1.6, "blanco")
	for s in [-1.0, 1.0]:
		tri(Vector3(bx + s * 0.26, by + 2.0, bz - 0.9), Vector3(bx + s * 0.26, by + 2.0, bz + 0.9), Vector3(bx + s * 0.26, by + 2.6, bz), "blanco", Vector3(s, 0, 0))
	box(bx - 0.25, by - 0.9, bz - 0.8, 0.5, 0.9, 1.6, "blanco")
	ball(Vector3(bx, by + 1.15, bz), 0.27, 0x6a5a34, 1.2, 8, 5)
	box(bx - 0.02, by + 2.6, bz - 0.02, 0.04, 0.7, 0.04, IRON)
	box(bx - 0.02, by + 3.0, bz - 0.2, 0.04, 0.04, 0.4, IRON)

## The square body at the hermitage's corner: rubble and brick below, plain render above.
func _tower() -> void:
	var x0: float = TOWER.position.x
	var x1: float = TOWER.end.x
	var z0: float = TOWER.position.y
	var z1: float = TOWER.end.y
	var sides: Array = [[Vector2(x0, z1), Vector2(x1, z1)], [Vector2(x1, z1), Vector2(x1, z0)], [Vector2(x1, z0), Vector2(x0, z0)], [Vector2(x0, z0), Vector2(x0, z1)]]
	for k in range(4):
		var ln: float = face(sides[k][0], sides[k][1], FE)
		var win := Rect2(ln / 2.0 - 0.4, 1.1, 0.8, 1.3)
		masonry(0.0, ln, -2.0, HT, [win] if k == 0 else [], [Rect2(0.55, -2.0, ln - 1.1, 4.6)], "brick", "rubble", [Rect2(win.position.x - 0.25, win.position.y - 0.25, win.size.x + 0.5, win.size.y + 0.5)] if k == 0 else [])
		box(0.0, 2.6, 0.0, ln, HT - 2.6, 0.03, "crema")
		if k == 0:
			window(win, 0x4a3324, 0x2a3640, 0)
		home()
	_hip(x0, x1, z0, z1, FE + HT, 0.8, 0.3)
	solid(Vector3((x0 + x1) / 2.0, FE + 3.0, (z0 + z1) / 2.0), Vector3(x1 - x0, 9.0, z1 - z0))

# ---------------- the cross ----------------
## The cross of granite on its steps, south of the walk, among its cypresses.
func _cross() -> void:
	var y: float = sq(CROSS.x) + 0.016
	for k in range(3):
		var s: float = 3.0 - k * 0.7
		cbox(Vector3(CROSS.x, y + 0.11 + k * 0.22, CROSS.y), Vector3(s, 0.22, s), "granito")
	cbox(Vector3(CROSS.x, y + 0.66 + 0.95, CROSS.y), Vector3(1.1, 1.9, 1.1), "granito")
	cbox(Vector3(CROSS.x, y + 2.62, CROSS.y), Vector3(1.36, 0.16, 1.36), "granito")
	cbox(Vector3(CROSS.x, y + 2.7 + 1.0, CROSS.y), Vector3(0.3, 2.0, 0.3), "granito")
	cbox(Vector3(CROSS.x, y + 2.7 + 1.45, CROSS.y), Vector3(1.3, 0.3, 0.3), "granito")
	solid(Vector3(CROSS.x, y + 1.3, CROSS.y), Vector3(1.6, 2.8, 1.6))
	yard.append(spot(CROSS.x, CROSS.y))

# ---------------- the nursery ----------------
func _nursery() -> void:
	var n := NURSERY.size()
	# towards its yard: rubble dressed with brick, barred windows, the glass door under its yellow arch
	var a: Vector2 = NURSERY[5]
	var b: Vector2 = NURSERY[4]
	var ln: float = face(a, b, fn)
	var h: float = en - fn
	var wins: Array = [Rect2(1.6, 0.9, 1.5, 1.3), Rect2(5.6, 0.9, 1.5, 1.3), Rect2(15.2, 0.9, 1.5, 1.3)]
	var r := 1.1
	var gate := Rect2(10.3, 0.0, 2.0 * r, 1.5 + r)
	var holes: Array = [gate]
	holes.append_array(wins)
	masonry(0.0, ln, -2.5, h, holes, [Rect2(0, 2.5, ln, 0.16)], "rubble", "brick")
	for q in [0.0, ln - 0.4]:
		box(q, -2.5, 0.0, 0.4, h + 2.5, 0.03, "brick")
	spandrels(10.3 + r, 1.5, r, 0.0, "rubble")
	ring(10.3 + r, 1.5, r, r + 0.24, 0.05, 0.34, 0xe9c81a)
	for s in [-1.0, 1.0]:
		box(10.3 + r + s * r - (0.0 if s < 0.0 else 0.24), 0.0, 0.0, 0.24, 1.5, 0.05, 0xe9c81a)
	box(gate.position.x, 0.0, -DEEP, gate.size.x, gate.size.y, 0.04, 0x6f9fb8)
	for i in range(5):
		box(gate.position.x + i * gate.size.x / 4.0 - 0.02, 0.0, -DEEP + 0.04, 0.04, gate.size.y, 0.03, 0xfdfcf8)
	box(gate.position.x, 2.05, -DEEP + 0.04, gate.size.x, 0.05, 0.03, 0xfdfcf8)
	for w: Rect2 in wins:
		for f in [[w.position.x - 0.18, w.position.y - 0.18, 0.18, w.size.y + 0.36], [w.end.x, w.position.y - 0.18, 0.18, w.size.y + 0.36], [w.position.x - 0.18, w.end.y, w.size.x + 0.36, 0.18], [w.position.x - 0.18, w.position.y - 0.18, w.size.x + 0.36, 0.18]]:
			box(f[0], f[1], 0.0, f[2], f[3], 0.03, "brick")
		window(w, 0x3a3d40, 0x2a3640, 1)
		grille(w, 0.1, 0x2a2c30)
	box(0.0, h, 0.0, ln, 0.12, 0.3, "brick")
	# the porch before the first two windows: a cage of tall blue railings
	var c0 := 0.6
	var c1 := 8.2
	var out := 2.3
	for q in [[c0, 0.0, c0, out], [c0, out, c1, out], [c1, out, c1, 0.0]]:
		var pa := Vector3(q[0], 0.0, q[1])
		var pb := Vector3(q[2], 0.0, q[3])
		var m := maxi(2, int(round(pa.distance_to(pb) / 0.13)))
		for i in range(m + 1):
			var pp: Vector3 = pa.lerp(pb, float(i) / m)
			cbox(pp + Vector3(0, 1.15, 0), Vector3(0.025, 2.3, 0.025), 0x2a4fc0)
		for yy in [0.12, 1.15, 2.26]:
			bar(pa + Vector3(0, yy, 0), pb + Vector3(0, yy, 0), 0.04, 0.04, 0x2a4fc0)
	home()
	# its other walls: rubble on the Calle del Rollo, where its door is; cream on rubble towards the Calle del Peso
	for i in [0, 1, 2, 3, 7]:
		var p: Vector2 = NURSERY[i]
		var q: Vector2 = NURSERY[(i + 1) % n]
		var l2: float = face(q, p, 0.0)
		if i == 1:
			# On the Calle del Rollo: rubble in panels between brick, barred windows, and in the middle the great
			# glazed arch of its way in. (x runs from the Calle del Peso westwards; the street climbs towards the Peso.)
			var gw: float = ground(p.x, p.y - 0.6)                     # the street at its west end...
			var ge: float = ground(q.x, q.y - 0.6)                     # ...and at its east end
			var gs := func(x: float) -> float:
				return lerpf(ge, gw, x / l2)
			var ar := 2.3
			var ax := l2 * 0.52
			var arch := Rect2(ax - ar, float(gs.call(ax)), 2.0 * ar, minf(0.9 + ar, en - float(gs.call(ax)) - 0.3))
			var nw: Array = []
			for x in [l2 * 0.1, l2 * 0.27, l2 * 0.78, l2 * 0.92]:
				nw.append(Rect2(x - 0.65, float(gs.call(x)) + 0.95, 1.3, minf(1.25, en - float(gs.call(x)) - 1.4)))
			var hs: Array = [arch]
			hs.append_array(nw)
			var bands: Array = [Rect2(0, -3.0, 0.5, en + 3.0), Rect2(l2 - 0.5, -3.0, 0.5, en + 3.0), Rect2(0, en - 0.3, l2, 0.3), Rect2(arch.position.x - 0.5, -3.0, 0.5, en + 3.0), Rect2(arch.end.x, -3.0, 0.5, en + 3.0)]
			for o: Rect2 in nw:
				bands.append(Rect2(o.position.x - 0.22, o.position.y - 0.22, o.size.x + 0.44, o.size.y + 0.44))
			masonry(0.0, l2, -3.0, en, hs, bands, "rubble", "brick")
			var spring: float = arch.end.y - ar
			spandrels(ax, spring, ar, 0.0, "brick")
			ring(ax, spring, ar, ar + 0.3, 0.06, 0.34, 0xeadfae)
			box(arch.position.x, arch.position.y, -DEEP, arch.size.x, arch.size.y, 0.04, 0x4f6a78)
			for k in range(9):
				box(arch.position.x + k * arch.size.x / 8.0 - 0.025, arch.position.y, -DEEP + 0.04, 0.05, arch.size.y, 0.03, 0x4a4d52)
			for k in range(1, 6):
				box(arch.position.x, arch.position.y + k * 0.62 - 0.025, -DEEP + 0.04, arch.size.x, 0.05, 0.03, 0x4a4d52)
			for o: Rect2 in nw:
				window(o, 0x6a6d70, 0x39566a, 1)
				_blind_white(o)
				grille(o, 0.12, 0x4a4d52)
			box(arch.position.x - 1.35, arch.position.y + 1.1, 0.0, 0.8, 0.95, 0.04, 0xe9a8c4)      # what it is, on its pink board by the door
			_text("ESCUELA\nINFANTIL\nMUNICIPAL", Vector3(arch.position.x - 0.95, arch.position.y + 1.58, 0.05), 32, 0x3a2a4a, 0.0042)
			box(arch.position.x - 1.2, arch.position.y + 0.7, 0.0, 0.3, 0.26, 0.14, 0x2f9a4a)       # its green letter box
			box(0.9, float(gs.call(0.9)) + 2.3, 0.0, 0.6, 0.32, 0.02, 0xf4f2ec)                      # the street's name on its tile
			_text("Calle\nRollo", Vector3(1.2, float(gs.call(0.9)) + 2.46, 0.03), 32, 0x2a3a6a, 0.0028)
		elif i == 0:
			var g1: float = ground((p.x + q.x) / 2.0, (p.y + q.y) / 2.0 - 0.6)
			var w0 := Rect2(l2 / 2.0 - 0.75, g1 + 0.95, 1.5, minf(1.3, en - g1 - 1.4))
			masonry(0.0, l2, -3.0, en, [w0], [Rect2(0, -3.0, l2, g1 + 0.9 + 3.0)], "crema", "rubble")
			window(w0, 0x6a6d70, 0x39566a, 1)
			_blind_white(w0)
			grille(w0, 0.12, 0x4a4d52)
		else:
			quad(Vector3(0, -3.0, 0), Vector3(l2, -3.0, 0), Vector3(l2, en, 0), Vector3(0, en, 0), "crema", Vector3(0, 0, 1))
			if i == 2 or i == 3:
				box(0.0, -3.0, 0.0, l2, fn + 0.9 + 3.0, 0.05, "rubble")
		home()
		yard.append(spot(p.x, p.y))
	_tent(NURSERY, Vector2(27.5, -15.0), Vector2(40.5, -19.5), en + 0.1, en + 2.2)
	solid(Vector3(34.5, en / 2.0, -17.5), Vector3(22.0, en + 6.0, 17.0), 0.29)
	solid(Vector3(24.0, en / 2.0, -15.5), Vector3(8.0, en + 6.0, 15.0))

## a white roller blind let most of the way down a window
func _blind_white(r: Rect2) -> void:
	box(r.position.x + 0.04, r.position.y + r.size.y * 0.3, -DEEP + 0.1, r.size.x - 0.08, r.size.y * 0.7 - 0.04, 0.04, 0xf1f0ea)

## The play yard: a step above the square on its wall of rubble, railings in every colour, a white pergola by the door.
func _yard() -> void:
	_floor(YARD, 0xb5553f, false, fn)
	var tint := 0
	for e in [[YARD[3], YARD[0]], [YARD[2], YARD[3]], [YARD[1], YARD[2]]]:
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		var parts: int = maxi(1, int(round(a.distance_to(b) / 2.6)))
		for k in range(parts):
			_rubble(a.lerp(b, float(k + 1) / parts), a.lerp(b, float(k) / parts), fn + 0.05, 1.15, YARD_PAINT[tint % YARD_PAINT.size()], 0.4)
			tint += 1
	cbox(Vector3(YARD[3].x + 1.3, fn + 1.15, YARD[3].y - 1.3), Vector3(2.3, 2.3, 2.3), "blanco")      # a low white hut in its corner
	# the pergola: white posts and beams, an awning over them
	var mid: Vector2 = (YARD[0] as Vector2).lerp(YARD[1], 0.58) + Vector2(0.4, 1.9)
	for i in range(3):
		for j in range(2):
			cbox(Vector3(mid.x - 2.4 + i * 2.4, fn + 1.3, mid.y - 0.9 + j * 2.2), Vector3(0.08, 2.6, 0.08), 0xfdfcf8)
	for j in range(2):
		cbox(Vector3(mid.x, fn + 2.62, mid.y - 0.9 + j * 2.2), Vector3(5.2, 0.08, 0.08), 0xfdfcf8)
	cbox(Vector3(mid.x, fn + 2.7, mid.y + 0.2), Vector3(5.0, 0.03, 2.6), 0xe9e2cc)
	# What is played on (the user: "Solo añadiría más juegos a la guardería. Está un poco vacía. Quizá algún balón o
	# portería pequeña también"): a slide, swings, a roundabout, two horses on springs and a seesaw from the set of the
	# square's playground; a sandpit, a little goal, balls, a hopscotch painted on the floor.
	var kit: Node = (load(PLAY_SET) as PackedScene).instantiate() if ResourceLoader.exists(PLAY_SET) else null
	if kit != null:
		for q in [["tobogan", Vector2(33.4, -0.4), 1.57], ["columpios", Vector2(38.6, 0.1), 0.0], ["tiovivo", Vector2(47.6, -0.6), 0.5], ["muelle_a", Vector2(42.3, 0.5), 0.4],
				["muelle_b", Vector2(44.0, 0.3), -0.6], ["balancin", Vector2(45.6, -5.6), 1.3]]:
			var src: Node3D = kit.get_node_or_null(String(q[0]))
			if src != null:
				var toy: Node3D = src.duplicate()
				toy.transform = Transform3D(Basis(Vector3.UP, float(q[2])), Vector3((q[1] as Vector2).x, fn + 0.01, (q[1] as Vector2).y))
				add_child(toy)
				pieces += 1
		kit.free()
	# the sandpit: a low kerb in four colours, sand in it, a bucket and a spade left behind
	var sp := Vector2(36.2, -2.3)
	box(sp.x - 1.2, fn, sp.y - 0.9, 2.4, 0.06, 1.8, 0xe6d3a0)
	for k in range(4):
		var along: bool = k % 2 == 0
		box(sp.x - 1.3 if k != 1 else sp.x + 1.2, fn, sp.y - 1.0 if k != 2 else sp.y + 0.9, 2.6 if along else 0.1, 0.22, 0.1 if along else 2.0, PAINT[k])
	drum(Vector3(sp.x + 0.5, fn + 0.06, sp.y + 0.2), 0.1, 0.13, 0.2, 0xc8323a, 8)
	box(sp.x - 0.4, fn + 0.07, sp.y - 0.3, 0.32, 0.03, 0.09, 0x2a62c8)
	# the little goal: white tubes and a net, by the railings at the far end
	var gx := 48.0
	var gz := -3.2
	for s2 in [-0.8, 0.8]:
		cbox(Vector3(gx, fn + 0.55, gz + s2), Vector3(0.06, 1.1, 0.06), 0xfdfcf8)
		bar(Vector3(gx, fn + 1.1, gz + s2), Vector3(gx + 0.55, fn + 0.03, gz + s2), 0.04, 0.04, 0xfdfcf8)
	cbox(Vector3(gx, fn + 1.1, gz), Vector3(0.06, 0.06, 1.66), 0xfdfcf8)
	cbox(Vector3(gx + 0.55, fn + 0.03, gz), Vector3(0.05, 0.05, 1.66), 0xfdfcf8)
	for k in range(1, 8):
		bar(Vector3(gx, fn + 1.1, gz - 0.8 + k * 0.2), Vector3(gx + 0.55, fn + 0.03, gz - 0.8 + k * 0.2), 0.012, 0.012, 0xe6e6e6)
	for k in range(1, 5):
		bar(Vector3(gx + k * 0.11, fn + 1.1 - k * 0.214, gz - 0.8), Vector3(gx + k * 0.11, fn + 1.1 - k * 0.214, gz + 0.8), 0.012, 0.012, 0xe6e6e6)
	# balls: one before the goal, others where they were left
	for q in [[Vector2(46.8, -3.0), 0.11, 0xfdfcf8], [Vector2(40.9, -2.2), 0.13, 0xe8c020], [Vector2(32.4, -2.2), 0.1, 0xc8323a], [Vector2(46.3, 0.9), 0.12, 0x2a62c8], [Vector2(43.2, -5.0), 0.1, 0x2f9a4a]]:
		ball(Vector3((q[0] as Vector2).x, fn + float(q[1]), (q[0] as Vector2).y), float(q[1]), int(q[2]), 1.0, 10, 7)
	# a hopscotch painted on the floor, and two low tables with their stools
	var hop := Vector2(39.6, -3.6)
	for k in range(7):
		var c: Vector2 = hop + Vector2(k * 0.5, -k * 0.135)
		quad(Vector3(c.x - 0.23, fn + 0.012, c.y - 0.23), Vector3(c.x + 0.23, fn + 0.012, c.y - 0.23), Vector3(c.x + 0.23, fn + 0.012, c.y + 0.23), Vector3(c.x - 0.23, fn + 0.012, c.y + 0.23), PAINT[k % 4] if k % 2 == 0 else 0xfdfcf8, Vector3.UP)
	for t in [Vector2(31.2, 0.4), Vector2(34.6, -3.0)]:
		cbox(Vector3(t.x, fn + 0.42, t.y), Vector3(0.9, 0.05, 0.6), 0xe8c020)
		for sx in [-0.38, 0.38]:
			cbox(Vector3(t.x + sx, fn + 0.2, t.y), Vector3(0.05, 0.4, 0.5), 0xc8323a)
		for k in range(4):
			cbox(Vector3(t.x - 0.5 + k * 0.33, fn + 0.14, t.y + (0.55 if k % 2 == 0 else -0.55)), Vector3(0.26, 0.28, 0.26), PAINT[k])

# ---------------- the park and its fountain ----------------
## The park: beaten earth with beds of grass round its old elms, benches of stone, lamps; all round it, towards the
## streets, the same low wall of rubble with its piers and railings. It keeps the ground as it lies.
func _green() -> void:
	var edge: Array = [Vector2(-5.4, -19.0), Vector2(-19.0, -14.5), Vector2(-37.5, -10.5), Vector2(-38.3, 0.5), Vector2(-33.4, 12.0), Vector2(-31.0, 16.8), Vector2(-26.0, wall_z(-26.0)), Vector2(-2.0, wall_z(-2.0))]
	var poly := PackedVector2Array(edge)
	poly[0] = Vector2(-2.0, -20.0)                 # (the earth goes on to the hermitage's front; only the wall stops short)
	var step := 4.0
	var x := -40.0
	while x < -2.0:
		var z := -22.0
		while z < 21.0:
			if Geometry2D.is_point_in_polygon(Vector2(x + step / 2.0, z + step / 2.0), poly):
				quad(Vector3(x, ground(x, z) + 0.05, z), Vector3(x + step, ground(x + step, z) + 0.05, z), Vector3(x + step, ground(x + step, z + step) + 0.05, z + step), Vector3(x, ground(x, z + step) + 0.05, z + step), "tierra", Vector3.UP)
			z += step
		x += step
	# its elms, each in a bed of grass with a kerb round it
	for q in [Vector2(-8.5, -12.5), Vector2(-17.0, -8.5), Vector2(-27.5, -5.0), Vector2(-33.0, 2.5), Vector2(-22.0, 6.0), Vector2(-28.5, 11.5), Vector2(-7.5, 12.2), Vector2(-17.5, 14.0), Vector2(-24.0, -12.0)]:
		var bed: Array = []
		for k in range(10):
			bed.append(q + Vector2(cos(TAU * k / 10.0) * 2.6, sin(TAU * k / 10.0) * 2.0))
		_drape(bed, "cesped", 0.08)
		_tree(q, 8.6 + fmod(absf(q.x), 1.5), 0)
	_tree(Vector2(-13.0, 15.5), 10.0, 1)
	for q in [Vector2(-5.0, 9.0), Vector2(-16.5, -2.5), Vector2(-21.5, 10.0), Vector2(-30.0, -7.0)]:
		_lamp(q, ground(q.x, q.y))
	for q in [[Vector2(-17.5, 3.0), Vector2(0.2, 1.0)], [Vector2(-10.0, -4.6), Vector2(1.0, 0.1)], [Vector2(-23.5, -1.5), Vector2(0.6, -0.8)]]:
		_bench(q[0], ground((q[0] as Vector2).x, (q[0] as Vector2).y) + 0.05, (q[1] as Vector2).normalized())
	# the wall round it: every side but the one of the square; gates left open at the corners of the streets
	var n := edge.size()
	for i in range(n - 1):
		var a: Vector2 = edge[i]
		var b: Vector2 = edge[i + 1]
		var parts: int = maxi(1, int(round(a.distance_to(b) / 6.0)))
		for k in range(parts):
			if (i == 2 and k == 0) or (i == 4):
				continue                          # (a way in from the corner of the streets, and from the avenue's end)
			var p: Vector2 = a.lerp(b, float(k) / parts)
			var q: Vector2 = a.lerp(b, float(k + 1) / parts)
			var top: float = maxf(ground(p.x, p.y), ground(q.x, q.y)) + 0.5
			_rubble(p, q, top, 0.85)
			_pier(q, top)

## The fountain: a round basin of rubble under its coping, water in it and a stone in the middle; round it, a ring of
## low curved walls of the same rubble, with ways through.
func _fountain() -> void:
	var top := -99.0
	var low := 99.0
	for k in range(8):
		var g: float = ground(FOUNTAIN.x + 4.6 * cos(TAU * k / 8.0), FOUNTAIN.y + 4.6 * sin(TAU * k / 8.0))
		top = maxf(top, g)
		low = minf(low, g)
	top += 0.08
	var c := Vector3(FOUNTAIN.x, top, FOUNTAIN.y)
	drum(Vector3(c.x, low - 0.8, c.z), 9.5, 4.8, top - low + 0.77, "tierra", 24)                    # the floor it stands on, banked up with earth where the ground falls
	drum(Vector3(c.x, top - 0.03, c.z), 4.86, 4.86, 0.03, "losa", 24)
	_ring_wall(c, 3.5, 3.95, 0.46, 16, [1, 5, 9, 13], "rubble")
	drum(c, 2.3, 2.3, 0.62, "rubble", 20)
	drum(c + Vector3(0, 0.62, 0), 2.42, 2.42, 0.08, "hormigon", 20)
	drum(c + Vector3(0, 0.56, 0), 1.95, 1.95, 0.15, "agua", 20)
	drum(c + Vector3(0, 0.5, 0), 0.4, 0.3, 0.7, "granito", 10)
	drum(c + Vector3(0, 1.2, 0), 0.05, 0.02, 0.7, 0xd9eef6, 6)                                     # the jet
	ball(c + Vector3(0, 1.95, 0), 0.12, 0xe9f6fa, 0.7, 8, 5)
	solid(Vector3(c.x, top + 0.3, c.z), Vector3(4.2, 1.2, 4.2))
	solid(Vector3(c.x, top + 0.3, c.z), Vector3(4.2, 1.2, 4.2), PI / 4.0)
	var pts := PackedVector2Array()
	for k in range(12):
		pts.append(Vector2(FOUNTAIN.x + 4.8 * cos(TAU * k / 12.0), FOUNTAIN.y + 4.8 * sin(TAU * k / 12.0)))
	_floor_decks.append(_poly_deck(pts, level + top))
	yard.append(spot(FOUNTAIN.x, FOUNTAIN.y))
