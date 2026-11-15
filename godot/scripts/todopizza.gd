extends "res://scripts/obra.gd"
## The pizza house beside the supermarket, "Todopizza" in the game, built by hand (the user, 15 November 2026: "Puede
## empezar con el Telepizza que hay al lado. Lo llamaremos Todopizza"; referencias/todopizza/, tools/todopizza/).
##
## As Street View has it in November 2024 from the three streets round it: a square pavilion of some eleven metres under
## one great roof of old tiles, four slopes to a point with a weather vane on it, its eaves well out on
## brown wooden posts with their brackets. Between the posts, towards the old road, it is all glass over a low white
## wall, with the glass doors in the second bay; the glass turns the corner for one bay; the rest is white wall -- a
## little barred window and a vent to the north; at the back, its paint peeling, a brown door, the air conditioners, a
## great silver flue up through the eaves and the white gas tank in its cage. Before it, a paved forecourt inside a low
## wire fence, black lanterns on posts, a bench; to the north a garden of rocks and bushes, and by the corner of the
## roads its sign on a tall post; behind, the street's bins.
##
## Frame: origin at the north end of its front; +x along the front (south, towards the supermarket), +z out of it
## towards the old road (west); y = 0 its floor.
## It stands on the parcel the bake leaves unraised for the supermarket (MERCAMONA_RCS in tools/bake_godot.py): it is
## built when the map carries the supermarket. The name is the user's; the badge on its sign is ours (a pizza).
## Nobody goes in; through the glass you see the counter and the tables. No people in it.

const O := Vector2(907.0, 288.27)               # (Catastro's square is its roof, eaves and all: the walls stand 1.2 m inside it)
const U := Vector2(-0.1583, 0.9874)
const L := 10.87                                # its front
const D := 10.75                                # how deep it is
const POST := 2.5                               # its posts, up to the beam
const EAVE := 1.25                              # how far the roof comes out
const RISE := 3.3                               # the roof, from its eaves to its point
const WOOD := 0x6a4630
const RED := 0xc8281e
const NAME := "TODOPIZZA"

var door: Vector2               # in front of its doors, on the map
var sign_at: Vector2            # its sign on its post

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"blanco":
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.985, 0.95)), 0.4)
		"interior":         # what is inside: lit by its own lamps
			var im := StandardMaterial3D.new()
			im.albedo_color = Color(0.93, 0.88, 0.76)
			im.emission_enabled = true
			im.emission = Color(0.9, 0.84, 0.7)
			im.emission_energy_multiplier = 0.45
			m = im
		"vidrio":
			var gm := StandardMaterial3D.new()
			gm.albedo_color = Color(0.6, 0.76, 0.82, 0.28)
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.roughness = 0.08
			gm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = gm
		"granito":
			m = Tex.mat("granular_concrete", Color(0.8, 0.79, 0.77), false)
		"tiles":            # old tiles, gone brown and grey (its UVs are in units of 1.6 m, running down the slope)
			var tm: StandardMaterial3D = Tex.mat(Tex.pick("tiles") if Tex.pick("tiles") != "" else "clay_roof_tiles_02", Color(0.5, 0.56, 0.66), true, 1.6)
			tm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = tm
		"losa":
			m = W._tmat(0xcfc9be, "pavement", 1.4)
		"leaf":
			m = W._tmat(0x79a24a, "leaf", 1.3)
		"mata":
			m = W._tmat(0x4f8a44, "leaf", 0.9)
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	var out := Vector2(-U.y, U.x)
	level = MapData.height(O + U * (L / 2.0) + out * 0.5) + 0.06
	transform = Transform3D(Basis(Vector3(U.x, 0, U.y), Vector3.UP, Vector3(out.x, 0, out.y)), Vector3(O.x, level, O.y))
	W.add_child(self)
	door = spot(L * 0.3, 1.6)
	_ground_round()
	_side(Vector2(0, 0), Vector2(L, 0), ["glass", "door", "glass", "glass", "glass"])              # the front, to the old road
	_side(Vector2(0, -D), Vector2(0, 0), ["wall", "vent", "window", "wall", "glass"])            # north (from its back to its front)
	_side(Vector2(L, -D), Vector2(0, -D), ["window", "peel", "peel", "back", "ac"])              # the back (from south to north)
	_side(Vector2(L, 0), Vector2(L, -D), ["wall", "wall", "wall", "wall", "wall"])               # south, towards the supermarket
	_inside()
	_roof()
	_back_yard()
	_forecourt()
	_sign()
	_garden()
	home()
	_commit()
	_tell_map()

func _tell_map() -> void:
	var pts := PackedVector2Array()
	for q in [Vector2(0, 0), Vector2(L, 0), Vector2(L, -D), Vector2(0, -D)]:
		pts.append(spot(q.x, q.y))
		yard.append(spot(q.x, q.y))
	MapData.outlines.append(pts)
	if not MapData._wall_grid.is_empty():
		for i in range(pts.size()):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % pts.size()]
			MapData._grid_add(MapData._wall_grid, a.min(b), a.max(b), [a, b])
	solid(Vector3(L / 2.0, 1.5, -D / 2.0), Vector3(L, 7.0, D))

# ---------------- helpers ----------------
## a piece of ground laid over the ground as it lies: a rectangle, in squares
func _drape(x0: float, x1: float, z0: float, z1: float, key, lift: float, step := 3.0) -> void:
	var x := x0
	while x < x1 - 0.01:
		var xb: float = minf(x + step, x1)
		var z := z0
		while z < z1 - 0.01:
			var zb: float = minf(z + step, z1)
			quad(Vector3(x, ground(x, z) + lift, z), Vector3(xb, ground(xb, z) + lift, z), Vector3(xb, ground(xb, zb) + lift, zb), Vector3(x, ground(x, zb) + lift, zb), key, Vector3.UP)
			z = zb
		x = xb
	pieces += 1

## a black lantern on its post
func _lantern(at: Vector2) -> void:
	var g: float = ground(at.x, at.y)
	drum(Vector3(at.x, g, at.y), 0.07, 0.05, 3.0, 0x1c1c1e, 7)
	cbox(Vector3(at.x, g + 3.22, at.y), Vector3(0.3, 0.42, 0.3), 0xf2e6b8)
	cbox(Vector3(at.x, g + 3.46, at.y), Vector3(0.42, 0.07, 0.42), 0x1c1c1e)
	cbox(Vector3(at.x, g + 3.0, at.y), Vector3(0.22, 0.06, 0.22), 0x1c1c1e)
	solid(Vector3(at.x, g + 1.5, at.y), Vector3(0.25, 3.0, 0.25))
	yard.append(spot(at.x, at.y))

## a low fence of wire on thin posts, from a to b
func _wire(a: Vector2, b: Vector2, tall := 1.0, hex := 0x7a5a48) -> void:
	var n: int = maxi(1, int(round(a.distance_to(b) / 2.4)))
	for k in range(n + 1):
		var p: Vector2 = a.lerp(b, float(k) / n)
		cbox(Vector3(p.x, ground(p.x, p.y) + tall / 2.0, p.y), Vector3(0.05, tall, 0.05), hex)
	for j in range(3):
		var y: float = tall * (0.3 + 0.33 * j)
		bar(Vector3(a.x, ground(a.x, a.y) + y, a.y), Vector3(b.x, ground(b.x, b.y) + y, b.y), 0.02, 0.02, hex)
	var d: Vector2 = (b - a).normalized()
	solid(Vector3((a.x + b.x) / 2.0, ground(a.x, a.y) + tall / 2.0, (a.y + b.y) / 2.0), Vector3(a.distance_to(b), tall + 0.6, 0.12), atan2(-d.y, d.x))
	yard.append(spot(a.x, a.y))
	yard.append(spot(b.x, b.y))

## the badge: a pizza in a red ring, on the wall being built
func _badge(cx: float, cy: float, r: float, z: float) -> void:
	slab(oval(cx, cy, r, r, 20), z, 0.0, RED)
	slab(oval(cx, cy, r * 0.86, r * 0.86, 20), z + 0.008, 0.0, 0xfdf6e4)
	slab(oval(cx, cy, r * 0.66, r * 0.66, 18), z + 0.016, 0.0, 0xd9a25a)
	slab(oval(cx, cy, r * 0.54, r * 0.54, 18), z + 0.024, 0.0, 0xf2c94a)
	for k in range(6):
		var a: float = TAU * k / 6.0 + 0.4
		slab(oval(cx + cos(a) * r * 0.3, cy + sin(a) * r * 0.3, r * 0.1, r * 0.1, 8), z + 0.032, 0.0, 0xb8281e)
	slab(oval(cx, cy, r * 0.07, r * 0.07, 6), z + 0.032, 0.0, 0x3f8a3a)

# ---------------- the house ----------------
## One side of it, from a to b seen from outside: posts on stone feet with their brackets, the beam, the rafters' ends,
## and between the posts what each bay has (`kinds`, from left to right).
func _side(a: Vector2, b: Vector2, kinds: Array) -> void:
	var ln: float = face(a, b)
	var n := kinds.size()
	var w: float = ln / n
	for k in range(n):
		var x0: float = k * w
		var kind := String(kinds[k])
		if kind == "glass":
			box(x0, -1.2, -0.16, w, 2.05, 0.16, "blanco")
			box(x0, 0.85, -0.2, w, 0.05, 0.26, 0xe9e4d8)
			quad(Vector3(x0, 0.9, -0.06), Vector3(x0 + w, 0.9, -0.06), Vector3(x0 + w, POST, -0.06), Vector3(x0, POST, -0.06), "vidrio", Vector3(0, 0, 1))
			box(x0 + w / 2.0 - 0.03, 0.9, -0.09, 0.06, POST - 0.9, 0.07, 0x4a3324)
			box(x0, 2.02, -0.09, w, 0.05, 0.07, 0x4a3324)
		elif kind == "door":
			quad(Vector3(x0, 0.0, -0.06), Vector3(x0 + w, 0.0, -0.06), Vector3(x0 + w, 2.06, -0.06), Vector3(x0, 2.06, -0.06), "vidrio", Vector3(0, 0, 1))
			box(x0, -1.2, -0.16, w, 1.2, 0.3, "granito")                                # the threshold
			for q in [x0 + 0.1, x0 + 0.62, x0 + w / 2.0 - 0.03, x0 + w - 0.68, x0 + w - 0.16]:
				box(q, 0.0, -0.09, 0.06, 2.06, 0.07, 0x2a2a2c)
			box(x0 + 0.1, 0.0, -0.09, w - 0.2, 0.08, 0.07, 0x2a2a2c)
			for s in [-1.0, 1.0]:                       # the handles
				box(x0 + w / 2.0 + s * 0.1 - 0.015, 0.9, -0.02, 0.03, 0.4, 0.03, 0xb9bcc0)
			box(x0 + 0.1, 2.06, -0.1, w - 0.2, POST - 2.06, 0.14, RED)                  # its name over the doors
			_text(NAME, Vector3(x0 + w / 2.0, 2.06 + (POST - 2.06) / 2.0, 0.05), 64, 0xfdfcf8, 0.005)
		else:
			quad(Vector3(x0, -1.2, 0), Vector3(x0 + w, -1.2, 0), Vector3(x0 + w, POST, 0), Vector3(x0, POST, 0), "blanco", Vector3(0, 0, 1))
			pieces += 1
			var mx: float = x0 + w / 2.0
			if kind == "window":
				box(mx - 0.35, 1.25, 0.0, 0.7, 0.7, 0.02, 0x2a3640)
				for i in range(4):
					box(mx - 0.3 + i * 0.2, 1.25, 0.02, 0.025, 0.7, 0.025, 0x3a3d40)
				box(mx - 0.4, 1.2, 0.0, 0.8, 0.05, 0.06, 0xe9e4d8)
			elif kind == "vent":
				box(mx - 0.25, 0.3, 0.0, 0.5, 0.3, 0.02, 0x8a8f96)
			elif kind == "back":
				box(mx - 0.5, 0.0, 0.0, 1.0, 2.1, 0.04, 0x5a3626)
				for j in range(4):
					box(mx - 0.42, 0.12 + j * 0.5, 0.04, 0.84, 0.4, 0.015, 0x6a4230)
				box(mx - 0.7, -1.2, 0.0, 1.4, 1.2, 0.5, "granito")                   # a step, where the ground has fallen
			elif kind == "ac":
				for q in [mx - 0.75, mx + 0.3]:
					box(q, 1.5, 0.0, 0.85, 0.65, 0.32, 0xf1f0ea)
					slab(oval(q + 0.3, 1.82, 0.24, 0.24, 12), 0.33, 0.0, 0x9a9c9e)
			if kind == "peel" or kind == "ac" or kind == "window" and a.y < -1.0 and b.y < -1.0:
				for q in [[0.5, 2.15, 0.5, 0.2], [1.5, 2.3, 0.4, 0.14], [2.1, 1.95, 0.3, 0.22]]:      # where the paint has come off
					slab(oval(x0 + q[0], q[1], q[2], q[3], 9), 0.006, 0.0, 0xcdb9a0)
	for k in range(n):                              # the posts (the corner at the far end is the next side's)
		var xp: float = k * w
		box(xp - 0.1, 0.0, -0.1, 0.2, POST, 0.2, WOOD)
		box(xp - 0.17, -1.2, -0.17, 0.34, 1.5, 0.34, "granito")
		if k > 0:
			box(xp - 0.5, POST - 0.14, -0.08, 1.0, 0.14, 0.16, WOOD)
	box(0.0, POST, -0.12, ln, 0.22, 0.24, WOOD)                                         # the beam
	var m := int(ln / 0.6)
	for i in range(m + 1):                          # the rafters' ends under the eaves
		box(i * ln / m - 0.04, POST + 0.1, 0.12, 0.08, 0.12, EAVE - 0.14, 0x5a3a26)
	home()

## What shows through the glass: the tiled floor, the counter and the menu over it, tables and stools.
func _inside() -> void:
	var back := -7.0
	flat(PackedVector2Array([Vector2(0.1, -0.1), Vector2(L - 0.1, -0.1), Vector2(L - 0.1, back), Vector2(0.1, back)]), 0.02, 0xb9774f)
	quad(Vector3(0.1, 0, back), Vector3(L - 0.1, 0, back), Vector3(L - 0.1, POST, back), Vector3(0.1, POST, back), "interior", Vector3(0, 0, 1))
	quad(Vector3(L - 0.17, 0, back), Vector3(L - 0.17, 0, -0.1), Vector3(L - 0.17, POST, -0.1), Vector3(L - 0.17, POST, back), "interior", Vector3(-1, 0, 0))
	quad(Vector3(0.17, 0, back), Vector3(0.17, 0, -D / 5.0), Vector3(0.17, POST, -D / 5.0), Vector3(0.17, POST, back), "interior", Vector3(1, 0, 0))
	quad(Vector3(0.1, POST, back), Vector3(L - 0.1, POST, back), Vector3(L - 0.1, POST, -0.1), Vector3(0.1, POST, -0.1), "interior", Vector3(0, -1, 0))
	box(3.2, 0.0, -6.2, 7.0, 1.05, 0.7, RED)                                            # the counter
	box(3.1, 1.05, -6.3, 7.2, 0.05, 0.9, 0xf4f1e8)
	cbox(Vector3(9.4, 1.28, -5.85), Vector3(0.4, 0.4, 0.35), 0x2a2a2c)                  # the till
	for i in range(3):                              # the menu, lit, over the counter
		box(3.4 + i * 2.3, 1.6, back + 0.01, 2.0, 0.7, 0.03, [0xfdf2c8, 0xf6d28a, 0xfdf2c8][i])
		for j in range(3):
			box(3.55 + i * 2.3, 1.72 + j * 0.2, back + 0.04, 1.2 + 0.2 * ((i + j) % 2), 0.035, 0.006, 0x8a2a1e if j == 2 else 0x4a3a2a)
	box(0.5, 0.0, back + 0.02, 0.8, 1.9, 0.6, 0x2a2a2c)                                 # the fridge of drinks
	box(0.56, 0.2, back + 0.62, 0.68, 1.6, 0.01, 0xbfe0ea)
	for t in [Vector2(6.4, -1.7), Vector2(8.8, -1.7), Vector2(9.6, -4.1), Vector2(1.5, -1.6)]:
		cbox(Vector3(t.x, 0.74, t.y), Vector3(0.7, 0.04, 0.7), 0xf4f1e8)
		cbox(Vector3(t.x, 0.37, t.y), Vector3(0.08, 0.72, 0.08), 0x4a4d52)
		for s in [-1.0, 1.0]:
			cbox(Vector3(t.x + s * 0.62, 0.23, t.y), Vector3(0.34, 0.46, 0.34), RED)
			cbox(Vector3(t.x + s * 0.77, 0.66, t.y), Vector3(0.04, 0.4, 0.34), RED)

## Its roof: four slopes of tiles to a point, well out over the posts; the vane on top.
func _roof() -> void:
	var y: float = POST + 0.24
	quad(Vector3(-EAVE, y - 0.02, EAVE), Vector3(L + EAVE, y - 0.02, EAVE), Vector3(L + EAVE, y - 0.02, -D - EAVE), Vector3(-EAVE, y - 0.02, -D - EAVE), 0x7a5438, Vector3(0, -1, 0))
	var top: Vector3 = _hip(0.0, L, -D, 0.0, y, RISE, EAVE)
	cbox(top + Vector3(0, 0.15, 0), Vector3(0.3, 0.3, 0.3), 0xa8623f)
	cbox(top + Vector3(0, 0.8, 0), Vector3(0.03, 1.2, 0.03), 0x3a3d40)                  # the vane: its rod, its arms, its arrow
	cbox(top + Vector3(0, 0.95, 0), Vector3(0.5, 0.02, 0.02), 0x3a3d40)
	cbox(top + Vector3(0, 0.95, 0), Vector3(0.02, 0.02, 0.5), 0x3a3d40)
	bar(top + Vector3(-0.35, 1.3, 0.1), top + Vector3(0.35, 1.3, -0.1), 0.02, 0.1, 0x3a3d40)
	cbox(top + Vector3(0.3, 1.3, -0.085), Vector3(0.16, 0.22, 0.02), 0x3a3d40)

# ---------------- round it ----------------
func _ground_round() -> void:
	_drape(-5.2, L + 2.4, -D - 4.4, 10.8, "losa", 0.05)

## Behind it: the silver flue up through the eaves, the gas tank in its cage, a mesh fence, and the street's bins.
func _back_yard() -> void:
	var zw: float = -D
	var silver := 0xc4c8cc
	var fx: float = L * 0.5                         # the flue: out of the wall, along it, and up through the eaves
	var tx: float = L * 0.82                        # the tank's south end
	bar(Vector3(fx + 1.5, 1.95, zw - 0.3), Vector3(fx, 1.95, zw - 0.3), 0.4, 0.4, silver)
	drum(Vector3(fx, 1.75, zw - 0.45), 0.22, 0.22, 2.7, silver, 10)
	drum(Vector3(fx, 4.45, zw - 0.45), 0.3, 0.3, 0.12, silver, 10)
	var g: float = ground(tx - 1.2, zw - 1.4)
	var keep := _xf
	_xf = keep * Transform3D(Basis(Vector3(0, 0, 1), PI / 2.0), Vector3(tx, g + 0.85, zw - 1.4))      # (the tank lies on its side)
	drum(Vector3.ZERO, 0.45, 0.45, 2.3, 0xf4f4f0, 12)
	_xf = keep
	for q in [tx - 1.9, tx - 0.4]:
		cbox(Vector3(q, g + 0.2, zw - 1.4), Vector3(0.12, 0.4, 0.7), 0x9a9c9e)
	for q in [Vector2(tx - 2.8, zw - 0.5), Vector2(tx + 0.6, zw - 0.5), Vector2(tx + 0.6, zw - 2.3), Vector2(tx - 2.8, zw - 2.3)]:      # its cage
		cbox(Vector3(q.x, g + 0.95, q.y), Vector3(0.05, 1.9, 0.05), 0x8a8f96)
	for y in [0.5, 1.2, 1.88]:
		bar(Vector3(tx - 2.8, g + y, zw - 2.3), Vector3(tx + 0.6, g + y, zw - 2.3), 0.025, 0.025, 0x8a8f96)
		bar(Vector3(tx - 2.8, g + y, zw - 0.5), Vector3(tx - 2.8, g + y, zw - 2.3), 0.025, 0.025, 0x8a8f96)
		bar(Vector3(tx + 0.6, g + y, zw - 0.5), Vector3(tx + 0.6, g + y, zw - 2.3), 0.025, 0.025, 0x8a8f96)
	solid(Vector3(tx - 1.1, g + 0.9, zw - 1.4), Vector3(3.4, 1.9, 1.8))
	_wire(Vector2(-2.2, zw - 4.4), Vector2(L + 2.2, zw - 4.4), 1.6, 0x8a8f96)
	# the bins by the street behind: a green one for glass, and brown, blue and yellow
	var bz: float = zw - 9.2
	var gb: float = ground(1.5, bz)
	drum(Vector3(1.5, gb, bz), 0.62, 0.55, 0.9, 0x2f9a4a, 12)
	ball(Vector3(1.5, gb + 0.9, bz), 0.56, 0x2f9a4a, 0.8, 12, 6)
	solid(Vector3(1.5, gb + 0.7, bz), Vector3(1.2, 1.4, 1.2))
	yard.append(spot(1.5, bz))
	var k := 0
	for hex in [0x8a5a3a, 0x2a62c8, 0xe8c020]:
		var bx: float = 3.6 + k * 1.9
		var gk: float = ground(bx, bz)
		cbox(Vector3(bx, gk + 0.65, bz), Vector3(1.5, 1.1, 1.0), 0xe9e4d2)
		cbox(Vector3(bx, gk + 1.28, bz), Vector3(1.56, 0.2, 1.06), hex)
		cbox(Vector3(bx, gk + 0.06, bz), Vector3(1.3, 0.12, 0.8), 0x2a2a2c)
		solid(Vector3(bx, gk + 0.7, bz), Vector3(1.5, 1.4, 1.0))
		yard.append(spot(bx, bz))
		k += 1

## Before it: the forecourt inside its wire fence, the lanterns, a bench on the pavement.
func _forecourt() -> void:
	var w: float = L / 5.0
	_wire(Vector2(-5.2, 10.8), Vector2(w - 0.3, 10.8))
	_wire(Vector2(2.0 * w + 0.3, 10.8), Vector2(L + 2.4, 10.8))
	_wire(Vector2(-5.2, -0.8), Vector2(-5.2, 10.8))
	for q in [Vector2(-4.7, 10.3), Vector2(L + 2.0, 10.3), Vector2(-4.7, -0.3), Vector2(L * 0.66, 10.3)]:
		_lantern(q)
	var b := Vector2(7.8, 12.4)                     # the bench: iron and boards
	var g: float = ground(b.x, b.y)
	for i in range(3):
		box(b.x - 0.9, g + 0.42, b.y - 0.2 + i * 0.14, 1.8, 0.03, 0.11, 0x3a3d40)
		box(b.x - 0.9, g + 0.52 + i * 0.13, b.y - 0.26, 1.8, 0.1, 0.03, 0x3a3d40)
	for s in [-0.85, 0.79]:
		box(b.x + s, g, b.y - 0.26, 0.06, 0.9, 0.05, 0x1c1c1e)
		box(b.x + s, g, b.y - 0.22, 0.06, 0.42, 0.46, 0x1c1c1e)
	solid(Vector3(b.x, g + 0.3, b.y), Vector3(1.8, 0.6, 0.5))
	yard.append(spot(b.x, b.y))

## Its sign by the corner of the roads: a tall post, the badge on top, a red board with its name and where the number goes.
func _sign() -> void:
	var at := Vector2(-10.7, 11.7)
	sign_at = spot(at.x, at.y)
	var g: float = ground(at.x, at.y)
	cbox(Vector3(at.x, g + 2.4, at.y), Vector3(0.14, 4.8, 0.14), 0x3a3d40)
	var keep := _xf
	for turn in [-PI / 2.0, PI / 2.0]:              # (it reads both ways along the old road)
		_xf = keep * Transform3D(Basis(Vector3.UP, turn), Vector3(at.x, g, at.y))
		box(-0.5, 2.55, 0.07, 1.0, 1.5, 0.03, RED)
		_text("TODO\nPIZZA", Vector3(0.0, 3.55, 0.105), 64, 0xfdfcf8, 0.0042)
		for i in range(7):                          # where the telephone number goes: a scribble
			box(-0.38 + i * 0.11, 2.78 + 0.03 * (i % 2), 0.1, 0.08, 0.035, 0.006, 0xfdfcf8)
		_badge(0.0, 4.75, 0.55, 0.075)
	_xf = keep
	solid(Vector3(at.x, g + 2.4, at.y), Vector3(0.3, 4.8, 0.3))
	yard.append(sign_at)

## North of it: rocks, bushes and two trees, and a raised bed by its wall.
func _garden() -> void:
	for q in [[Vector2(-6.5, 6.5), 0.7], [Vector2(-8.8, 3.0), 0.9], [Vector2(-10.5, 7.5), 0.6], [Vector2(-7.5, -1.0), 0.75]]:
		var at: Vector2 = q[0]
		ball(Vector3(at.x, ground(at.x, at.y) + float(q[1]) * 0.35, at.y), float(q[1]), 0x9a9288, 0.7, 7, 4)
		solid(Vector3(at.x, ground(at.x, at.y) + 0.4, at.y), Vector3(float(q[1]) * 1.6, 0.9, float(q[1]) * 1.6))
		yard.append(spot(at.x, at.y))
	for q in [Vector2(-7.5, 4.8), Vector2(-9.8, 5.5), Vector2(-6.0, 1.5), Vector2(-9.5, 0.0), Vector2(-11.0, 3.5)]:
		ball(Vector3(q.x, ground(q.x, q.y) + 0.45, q.y), 0.8, "mata", 0.7, 8, 5)
	for q in [Vector2(-8.0, 8.6), Vector2(-10.8, -3.0)]:
		var g: float = ground(q.x, q.y)
		drum(Vector3(q.x, g, q.y), 0.2, 0.13, 3.0, 0x6b5a45, 8)
		ball(Vector3(q.x, g + 4.8, q.y), 2.2, "leaf", 1.15, 10, 6)
		solid(Vector3(q.x, g + 1.5, q.y), Vector3(0.45, 3.0, 0.45))
		yard.append(spot(q.x, q.y))
	var p := Vector2(-3.0, -7.0)                    # the raised bed, white, with its young tree
	var gp: float = ground(p.x, p.y)
	cbox(Vector3(p.x, gp + 0.25, p.y), Vector3(1.8, 0.5, 3.0), "blanco")
	cbox(Vector3(p.x, gp + 0.51, p.y), Vector3(1.5, 0.04, 2.7), 0x6f5d4a)
	drum(Vector3(p.x, gp + 0.5, p.y), 0.07, 0.05, 1.8, 0x6b5a45, 6)
	ball(Vector3(p.x, gp + 2.7, p.y), 0.9, "leaf", 1.0, 8, 5)
	solid(Vector3(p.x, gp + 0.4, p.y), Vector3(1.8, 0.9, 3.0))
	yard.append(spot(p.x, p.y))
