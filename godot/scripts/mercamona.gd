extends "res://scripts/obra.gd"
## The supermarket by the old Madrid-Cádiz road, "Mercamona" in the game, with its car park on a lower level, built by
## hand (the user, 15 November 2026: "habría que intentarlo con el Mercadona (que llamaremos Mercamona). Es más o menos
## toda la zona roja. Tiene aparcamiento a desnivel. Varios bloques (no solo el rojo)"; referencias/mercamona/,
## tools/mercamona/).
##
## As Street View has it in November 2024, from the three streets round it: a long box of corrugated sheet in upright
## stripes of greys and white, its floor level with the old road to the west. At the north end of that side, the way
## in: a tall white fascia with the name in green and its round badge, dark glass under it, a fence of coloured slats
## and lawns with poplars before it; at the south end, the loading dock: a white box with the badge over a great
## shutter, and a yard behind green mesh. The ground falls away to the east, and there the car park lies a whole floor
## lower: open tarmac with painted bays inside a mesh fence on a concrete wall, running in UNDER the east half of the
## shop between its columns; cars come down a ramp from the gate at the north corner, under a blue sign with an arrow.
## At that corner the shop has a taller block clad in darker greys, with big square windows. (The little house under
## its tiles north of it all is the pizza house: todopizza.gd.)
##
## Frame: origin at the north-west corner of the shop; +x along its west side (south), +z out of it towards the old
## road (west); y = 0 the shop's floor. The car park is `low` (some 3.2 m) below: the bake digs it (`pit`).
## The badge is ours (a monkey's face: "mona"); the name is the user's. Nobody goes in.

const READY := true                             # (tools/bake_godot.py looks for this)
const O := Vector2(905.0, 306.1)
const U := Vector2(-0.1838, 0.983)
const HT := 7.4                                 # the shop's walls
const HB := 9.4                                 # the taller block at its north-east corner
const BACK := -24.0                             # how far in under the shop the car park goes (the shop's east wall is at z = -39)
const MAIN: Array = [Vector2(0, 0), Vector2(51.7, 0), Vector2(51.7, -4.7), Vector2(74, -4.7), Vector2(74, 0), Vector2(84.4, 0), Vector2(85, -13.1), Vector2(79, -13.1),
	Vector2(79, -39), Vector2(3.7, -39), Vector2(3.7, -14.2), Vector2(0, -11.5)]
const BLOCK: Array = [Vector2(-5.4, -14.3), Vector2(3.8, -14.2), Vector2(3.7, -39), Vector2(2.9, -39), Vector2(0.9, -34.5), Vector2(-1.6, -28.9), Vector2(-4.3, -23.0), Vector2(-5.4, -21.0)]
## (The game's street along the car park's north-east side runs straight from (-7.8, -22.7) to (60.2, -175.3) in this frame,
## some five metres nearer the shop than the real one: the taller block is cut back to it, and the fence stands 3 m off it.)
const PARK: Array = [Vector2(4.5, -39.4), Vector2(5.5, -45.0), Vector2(28.9, -97.0), Vector2(34.0, -108.0), Vector2(78.0, -108.0), Vector2(78.0, -39.4)]
const THROAT: Array = [Vector2(0.6, -38.6), Vector2(4.5, -39.4), Vector2(5.5, -45.0), Vector2(2.9, -46.0)]      # between the street and the gate
const GREYS: Array = [0xa4a6a6, 0x8f9292, 0xc9cbca, 0x9a9d9c, 0xe2e3e0, 0x868989]      # mostly mid greys, a pale stripe now and then
const DARKS: Array = [0x8a8c8b, 0xa2a4a3, 0x7c7e7d, 0xb4b5b3, 0x929493]
const GREEN := 0x1f9a55
const MESH := 0x2f7a4a

var door: Vector2               # in front of the shop's doors, on the map
var gate: Vector2               # the car park's gate
var yl := -3.2                  # the car park, under the shop's floor
var un := 30.0                  # from where (along the shop) the car park runs in under it: north of that the ground is still coming down from the street

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"blanco":
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.99, 0.97)), 0.36)
		"hormigon":
			m = Tex.mat("granular_concrete", Color(0.9, 0.89, 0.86), false)
		"asfalto":
			m = W._tmat(0x6f6c73, "asphalt", 3.0)
		"losa":
			m = W._tmat(0xcfc9be, "pavement", 1.4)
		"cesped":
			m = W._tmat(0x6fa24e, "leaf", 2.0)
		"leaf":
			m = W._tmat(0x79a24a, "leaf", 1.3)
		"sombra":           # what is under the shop: lit by its own lamps
			var sm := StandardMaterial3D.new()
			sm.albedo_color = Color(0.62, 0.63, 0.62)
			sm.emission_enabled = true
			sm.emission = Color(0.5, 0.5, 0.48)
			sm.emission_energy_multiplier = 0.5
			m = sm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	var data: Dictionary = MapData.mercamona
	var o := Vector2(data["o"][0], data["o"][1]) if data.has("o") else O
	var u := Vector2(data["u"][0], data["u"][1]) if data.has("u") else U
	var out := Vector2(-u.y, u.x)
	level = MapData.height(o + u * 10.0 + out * 1.5) + 0.05
	if data.has("low"):
		yl = float(data["low"]) - level
	transform = Transform3D(Basis(Vector3(u.x, 0, u.y), Vector3.UP, Vector3(out.x, 0, out.y)), Vector3(o.x, level, o.y))
	W.add_child(self)
	door = spot(11.5, 4.5)
	gate = spot(4.8, -42.2)
	un = 60.0
	for k in range(4, 60):                         # (the ground is dug level only so far north: tools/bake_godot.py, pit)
		if ground(k, -38.6) < yl + 0.12 and ground(k, BACK - 0.5) < yl + 0.12 and ground(k + 2.0, -38.6) < yl + 0.12:
			un = k + 0.5
			break
	_shop()
	_under()
	_block()
	_forecourt()
	_car_park()
	home()
	_commit()
	_tell_map()

func _tell_map() -> void:
	for ring in [MAIN, BLOCK]:
		var pts := PackedVector2Array()
		for q: Vector2 in ring:
			pts.append(spot(q.x, q.y))
			yard.append(spot(q.x, q.y))
		MapData.outlines.append(pts)
		if not MapData._wall_grid.is_empty():
			for i in range(pts.size()):
				var a: Vector2 = pts[i]
				var b: Vector2 = pts[(i + 1) % pts.size()]
				MapData._grid_add(MapData._wall_grid, a.min(b), a.max(b), [a, b])

# ---------------- helpers ----------------
## corrugated sheet in upright stripes, on the wall being built
func _stripes(x0: float, x1: float, y0: float, y1: float, tints: Array, seed := 0) -> void:
	var x := x0
	var k := seed
	while x < x1 - 0.01:
		var w: float = minf([1.3, 2.2, 0.9, 1.7, 2.6, 1.1, 1.9][k % 7], x1 - x)
		quad(Vector3(x, y0, 0), Vector3(x + w, y0, 0), Vector3(x + w, y1, 0), Vector3(x, y1, 0), tints[(k * 3 + k / 2) % tints.size()], Vector3(0, 0, 1))
		x += w
		k += 1
	pieces += 1

## the shop's badge, on the wall being built: a monkey's face in a green ring
func _badge(cx: float, cy: float, r: float, z: float) -> void:
	slab(oval(cx, cy, r, r, 20), z, 0.0, GREEN)
	slab(oval(cx, cy, r * 0.84, r * 0.84, 20), z + 0.01, 0.0, 0xf6f1e2)
	for s in [-1.0, 1.0]:
		slab(oval(cx + s * r * 0.5, cy + r * 0.12, r * 0.2, r * 0.2, 10), z + 0.02, 0.0, 0x8a5a36)
		slab(oval(cx + s * r * 0.5, cy + r * 0.12, r * 0.1, r * 0.1, 8), z + 0.03, 0.0, 0xe9c9a0)
	slab(oval(cx, cy, r * 0.46, r * 0.5, 16), z + 0.025, 0.0, 0x8a5a36)
	slab(oval(cx, cy - r * 0.14, r * 0.33, r * 0.3, 14), z + 0.035, 0.0, 0xe9c9a0)
	for s in [-1.0, 1.0]:
		slab(oval(cx + s * r * 0.15, cy + r * 0.12, r * 0.055, r * 0.07, 8), z + 0.045, 0.0, 0x2a1c12)
	slab(oval(cx, cy - r * 0.22, r * 0.14, r * 0.04, 8), z + 0.045, 0.0, 0x6a3a26)

## a piece of ground laid over the ground as it lies: a polygon, in squares
func _drape(pts: Array, key, lift: float, step := 6.0) -> void:
	var poly := PackedVector2Array(pts)
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for q: Vector2 in pts:
		lo = lo.min(q)
		hi = hi.max(q)
	var x := lo.x
	while x < hi.x:
		var z := lo.y
		while z < hi.y:
			if Geometry2D.is_point_in_polygon(Vector2(x + step / 2.0, z + step / 2.0), poly):
				quad(Vector3(x, ground(x, z) + lift, z), Vector3(x + step, ground(x + step, z) + lift, z), Vector3(x + step, ground(x + step, z + step) + lift, z + step), Vector3(x, ground(x, z + step) + lift, z + step), key, Vector3.UP)
			z += step
		x += step
	pieces += 1

## a line painted on the tarmac
func _line(a: Vector2, b: Vector2, wide := 0.12, hex := 0xf1f1ee) -> void:
	var d: Vector2 = (b - a).normalized()
	var n := Vector2(-d.y, d.x) * wide / 2.0
	var ya: float = ground(a.x, a.y) + 0.06
	var yb: float = ground(b.x, b.y) + 0.06
	if absf(ya - 0.06 - yl) > 0.15 or absf(yb - 0.06 - yl) > 0.15:
		return                                  # (on the slope down from the street: no bays)
	quad(Vector3(a.x + n.x, ya, a.y + n.y), Vector3(b.x + n.x, yb, b.y + n.y), Vector3(b.x - n.x, yb, b.y - n.y), Vector3(a.x - n.x, ya, a.y - n.y), hex, Vector3.UP)

## a fence of green mesh on a low concrete wall, from a to b, following the ground
func _fence(a: Vector2, b: Vector2, wall := 0.5) -> void:
	var n: int = maxi(1, int(round(a.distance_to(b) / 2.5)))
	for k in range(n):
		var p: Vector2 = a.lerp(b, float(k) / n)
		var q: Vector2 = a.lerp(b, float(k + 1) / n)
		var g: float = maxf(ground(p.x, p.y), ground(q.x, q.y))
		var ln: float = face(p, q, g)
		box(0.0, -1.2, -0.1, ln, wall + 1.2, 0.2, "hormigon")
		box(0.0, wall, -0.03, 0.06, 1.75, 0.06, MESH)
		for j in range(5):
			box(0.0, wall + 0.1 + j * 0.4, -0.012, ln, 0.022, 0.022, MESH)
		for i in range(1, 5):
			box(ln * i / 5.0, wall, -0.01, 0.018, 1.7, 0.018, MESH)
		home()
		var d: Vector2 = (q - p).normalized()
		solid(Vector3((p.x + q.x) / 2.0, g + 0.6, (p.y + q.y) / 2.0), Vector3(ln, 3.6, 0.2), atan2(-d.y, d.x))
	yard.append(spot(a.x, a.y))
	yard.append(spot(b.x, b.y))

## a tall lamp
func _lamp(at: Vector2) -> void:
	var g: float = ground(at.x, at.y)
	drum(Vector3(at.x, g, at.y), 0.09, 0.06, 7.0, 0x9a9c9e, 7)
	cbox(Vector3(at.x, g + 7.0, at.y - 0.5), Vector3(0.14, 0.1, 1.2), 0x9a9c9e)
	cbox(Vector3(at.x, g + 6.93, at.y - 1.0), Vector3(0.22, 0.06, 0.5), 0xf2ecd2)

# ---------------- the shop ----------------
func _shop() -> void:
	var n := MAIN.size()
	for i in range(n):
		var a: Vector2 = MAIN[i]
		var b: Vector2 = MAIN[(i + 1) % n]
		if i == 8 or i == 9:
			continue                              # (its east side has the car park under it: _under; its north-east side is the taller block's)
		var ln: float = face(a, b)
		quad(Vector3(0, -2.5, 0), Vector3(ln, -2.5, 0), Vector3(ln, 0.7, 0), Vector3(0, 0.7, 0), 0x9b9d9c, Vector3(0, 0, 1))      # a grey foot
		match i:
			0:      # the west side: the way in under its fascia, then the long striped wall
				var e := 23.0
				_stripes(e, ln, 0.7, HT, GREYS, 2)
				box(-0.3, 3.5, 0.0, e + 0.3, 5.9, 0.5, "blanco")                         # the fascia: a white box, proud of the wall
				box(0.0, 0.0, 0.0, e, 3.5, 0.06, 0x2c3a40)                              # dark glass under it
				for k in range(12):
					box(k * e / 11.0 - 0.04, 0.0, 0.06, 0.08, 3.5, 0.05, 0x55595c)
				box(0.0, 3.25, 0.0, e, 0.25, 2.2, 0xe9e9e6)                             # the canopy
				box(9.4, 0.0, 0.07, 4.4, 2.7, 0.04, 0x9fc0c8)                           # the doors, sliding glass
				box(11.56, 0.0, 0.11, 0.08, 2.7, 0.03, 0x55595c)
				_text("MERCAMONA", Vector3(9.3, 2.98, 2.22), 32, GREEN, 0.012)
				_badge(4.0, 6.5, 1.25, 0.52)
				_text("MERCAMONA", Vector3(13.6, 6.5, 0.54), 64, GREEN, 0.0235)
			1, 3:
				_stripes(0.0, ln, 0.7, HT, GREYS, 5 + i)
			2:      # the back of the yard: service doors
				_stripes(0.0, ln, 0.7, HT, GREYS, 1)
				for q in [3.0, 9.5, 17.0]:
					box(q, 0.0, 0.0, 1.1, 2.2, 0.04, 0x6f7376)
			4:      # the loading dock: a white box, the badge over a great shutter
				box(0.0, 0.7, 0.0, ln, 7.8, 0.4, "blanco")
				box(2.4, 0.0, 0.4, 5.0, 4.4, 0.03, 0x6a6e72)
				for j in range(1, 14):
					box(2.4, j * 0.31, 0.43, 5.0, 0.02, 0.01, 0x55595c)
				_badge(ln / 2.0, 6.5, 0.95, 0.42)
			_:
				_stripes(0.0, ln, 0.7, HT, GREYS, i)
		box(0.0, HT, -0.3, ln, 0.25, 0.34, 0xd9d9d5)                                    # the parapet's cap
		home()
	flat(PackedVector2Array(MAIN), HT, 0xb6b6b1)
	# on the roof: rows of solar panels, skylights, the machines
	for r in range(4):
		for c in range(5):
			cbox(Vector3(10.0 + c * 13.0, HT + 0.18, -7.0 - r * 8.0), Vector3(10.0, 0.12, 4.6), 0x25364f)
	for c in range(4):
		cbox(Vector3(17.0 + c * 13.0, HT + 0.3, -20.0), Vector3(1.6, 0.5, 5.0), 0xdfe6e8)
	cbox(Vector3(64.0, HT + 0.7, -9.0), Vector3(4.0, 1.4, 3.0), 0x9a9c9e)
	solid(Vector3(42.5, 2.0, BACK / 2.0), Vector3(85.0, 11.0, -BACK))
	solid(Vector3((un + 79.0) / 2.0, 3.5, (BACK - 39.0) / 2.0), Vector3(79.0 - un, 7.9, 39.0 + BACK))
	solid(Vector3((un + 3.7) / 2.0, 1.0, (BACK - 39.0) / 2.0), Vector3(un - 3.7, 13.0, 39.0 + BACK))
	# the yard of the dock: green mesh on a low white wall across its mouth
	_fence(Vector2(52.0, 0.3), Vector2(73.8, 0.3), 0.6)

## The east side: the white wall and its striped band above, the car park running in under it between the columns.
func _under() -> void:
	var a := Vector2(79, -39)
	var b := Vector2(3.7, -39)
	var ln: float = face(a, b)
	quad(Vector3(0, 0, 0), Vector3(ln, 0, 0), Vector3(ln, 5.2, 0), Vector3(0, 5.2, 0), "blanco", Vector3(0, 0, 1))
	_stripes(0.0, ln, 5.2, HT, [0xf1f1ee, 0xc9c4b8, 0xe6e6e2, 0xbdb8ac], 3)
	box(0.0, HT, -0.3, ln, 0.25, 0.34, 0xd9d9d5)
	box(0.0, -0.5, -0.45, ln, 0.5, 0.45, "blanco")                                  # the edge of the floor
	box(ln - 9.0, 1.7, 0.0, 1.5, 1.7, 0.05, 0x4a6272)                               # a window by the gate
	box(5.2, 0.0, 0.0, 1.1, 2.2, 0.05, 0x6f7376)                                    # the emergency door, at the head of its stairs
	quad(Vector3(79.0 - un, -5.0, 0), Vector3(ln, -5.0, 0), Vector3(ln, 0, 0), Vector3(79.0 - un, 0, 0), "blanco", Vector3(0, 0, 1))      # north of where the car park runs in: a plain foot
	var x := 0.6
	while x < 79.0 - un:
		box(x - 0.22, yl - 0.5, -0.5, 0.44, -yl, 0.44, "hormigon")
		box(x - 0.22, yl - 0.5, -8.0, 0.44, -yl, 0.44, "hormigon")
		x += 7.4
	home()
	x = 78.4
	while x > un:
		solid(Vector3(x, yl / 2.0, -38.7), Vector3(0.44, -yl, 0.44))
		x -= 7.4
	# its back wall, its two ends, its ceiling
	for w in [[Vector2(79, BACK), Vector2(un, BACK)], [Vector2(un, BACK), Vector2(un, -39)], [Vector2(79, -39), Vector2(79, BACK)]]:
		var l2: float = face(w[0], w[1])
		quad(Vector3(0, yl - 0.5, 0), Vector3(l2, yl - 0.5, 0), Vector3(l2, -0.45, 0), Vector3(0, -0.45, 0), "sombra", Vector3(0, 0, 1))
		box(0.0, yl + 1.0, 0.0, l2, 0.25, 0.012, GREEN)
		home()
	quad(Vector3(un, -0.5, -39), Vector3(79, -0.5, -39), Vector3(79, -0.5, BACK), Vector3(un, -0.5, BACK), "sombra", Vector3(0, -1, 0))
	var lx: float = un + 4.0
	while lx < 77.0:                                  # strip lamps on the ceiling
		cbox(Vector3(lx, -0.56, -31.5), Vector3(1.4, 0.06, 0.16), 0xfdfcf0)
		lx += 7.4
	solid(Vector3((un + 79.0) / 2.0, yl / 2.0, BACK + 0.2), Vector3(79.0 - un, -yl + 1.0, 0.4))
	solid(Vector3(un - 0.2, yl / 2.0, (BACK - 39.0) / 2.0), Vector3(0.4, -yl + 1.0, 39.0 + BACK))
	# the emergency stairs outside its south-east end: two flights of grey steel
	var sx := 73.8
	for q in [[Vector3(sx, 0.0, -40.0), Vector3(sx - 5.0, yl / 2.0, -40.0)], [Vector3(sx - 5.0, yl / 2.0, -41.3), Vector3(sx, yl, -41.3)]]:
		bar(q[0], q[1], 1.1, 0.12, 0x8f9499)
		bar(q[0] + Vector3(0, 1.0, 0), q[1] + Vector3(0, 1.0, 0), 0.05, 0.05, 0x8f9499)
	cbox(Vector3(sx - 5.6, yl / 2.0 - 0.05, -40.65), Vector3(1.3, 0.1, 2.5), 0x8f9499)
	cbox(Vector3(sx + 0.5, -0.05, -40.0), Vector3(1.2, 0.1, 1.2), 0x8f9499)
	solid(Vector3(sx - 2.5, yl / 2.0, -40.7), Vector3(6.8, -yl, 2.6))

## The taller block at the north-east corner: darker stripes on a stone foot, big square windows, the door.
func _block() -> void:
	var n := BLOCK.size()
	for i in range(n):
		if i == 1:
			continue                              # (against the shop)
		var a: Vector2 = BLOCK[i]
		var b: Vector2 = BLOCK[(i + 1) % n]
		var ln: float = face(a, b)
		var g: float = maxf(ground(a.x, a.y), ground(b.x, b.y))
		quad(Vector3(0, -4.0, 0), Vector3(ln, -4.0, 0), Vector3(ln, g + 1.0, 0), Vector3(0, g + 1.0, 0), 0x9a958e, Vector3(0, 0, 1))
		_stripes(0.0, ln, g + 1.0, HB, DARKS, i)
		if i == n - 1:                              # its north side: two big windows, small ones, the door in its recess
			for q in [[2.6, 4.2, 2.0, 2.3], [6.2, 4.2, 2.0, 2.3], [10.2, 2.2, 0.9, 0.9], [12.6, 2.2, 0.9, 0.9]]:
				box(q[0] - 0.1, q[1] - 0.1, 0.0, q[2] + 0.2, q[3] + 0.2, 0.08, 0x55595c)
				box(q[0], q[1], 0.08, q[2], q[3], 0.01, 0x8fb0bd)
			box(9.2, g, 0.0, 1.9, 2.4, 0.03, 0x3f4346)
		elif ln > 3.5:
			box(ln / 2.0 - 0.8, 4.2, 0.0, 1.6, 2.0, 0.08, 0x55595c)
			box(ln / 2.0 - 0.7, 4.3, 0.08, 1.4, 1.8, 0.01, 0x8fb0bd)
		box(0.0, HB, -0.3, ln, 0.25, 0.34, 0x8a8c8b)
		home()
	flat(PackedVector2Array(BLOCK), HB, 0xa9a9a4)
	_prism(BLOCK, -4.0, HB)
	# at the gate: the blue sign with its arrow, the P, the height the ramp allows
	var p := Vector2(6.6, -46.4)
	var g2: float = ground(p.x, p.y)
	cbox(Vector3(p.x, g2 + 2.2, p.y), Vector3(0.14, 4.4, 0.14), 0x2c3a40)
	var keep := _xf
	_xf = Transform3D(Basis(Vector3.UP, -PI / 2.0), Vector3(p.x, g2 + 4.4, p.y))
	box(-0.75, 0.0, -0.06, 1.5, 1.7, 0.12, 0x23303a)
	slab(oval(0.0, 1.05, 0.5, 0.5, 16), 0.065, 0.0, 0x2a6fd0)
	box(-0.05, 0.85, 0.07, 0.1, 0.48, 0.01, 0xfdfcf8)
	slab(PackedVector2Array([Vector2(-0.22, 0.95), Vector2(0.22, 0.95), Vector2(0.0, 0.7)]), 0.075, 0.0, 0xfdfcf8)
	_text("MERCAMONA", Vector3(0.0, 0.3, 0.07), 32, 0xfdfcf8, 0.0058)
	slab(oval(0.0, -1.6, 0.34, 0.34, 14), 0.02, 0.0, 0xc8323a)
	slab(oval(0.0, -1.6, 0.27, 0.27, 14), 0.03, 0.0, 0xfdfcf8)
	_text("2,7 m", Vector3(0.0, -1.6, 0.04), 32, 0x1c1c1e, 0.0058)
	_xf = keep
	yard.append(spot(p.x, p.y))

# ---------------- the west side: the way in ----------------
func _forecourt() -> void:
	# paved from the shop to the old road, all along; a lawn with its poplars before the long wall
	_drape([Vector2(-4, 0.05), Vector2(88, 0.05), Vector2(88, 16.0), Vector2(-4, 16.0)], "losa", 0.03, 4.0)
	_drape([Vector2(-22, 4.6), Vector2(-4, 4.6), Vector2(-4, 16.0), Vector2(-22, 16.0)], "losa", 0.03, 3.0)
	_drape([Vector2(20, 6.0), Vector2(52, 6.0), Vector2(52, 12.0), Vector2(20, 12.0)], "cesped", 0.045, 4.0)
	# the fence of slats: greens, white and grey, on a low white wall, either side of the way to the doors
	var tints: Array = [GREEN, 0xf4f4f0, 0x8fd0a0, 0xb4b5b2, 0x2f7a4a, 0xf4f4f0]
	for run in [[Vector2(0.5, 3.6), Vector2(8.6, 3.6)], [Vector2(14.6, 3.6), Vector2(51.0, 3.6)]]:
		var a: Vector2 = run[0]
		var b: Vector2 = run[1]
		var parts: int = maxi(1, int(round(a.distance_to(b) / 6.0)))
		for k in range(parts):
			var p: Vector2 = a.lerp(b, float(k) / parts)
			var q: Vector2 = a.lerp(b, float(k + 1) / parts)
			var g: float = maxf(ground(p.x, p.y), ground(q.x, q.y))
			var ln: float = face(p, q, g)
			box(0.0, -0.8, -0.15, ln, 1.25, 0.3, "blanco")
			var m: int = int(ln / 0.24)
			for i in range(m):
				box(0.05 + i * 0.24, 0.45, -0.03, 0.1, 0.95 + 0.32 * ((i * 5 + k) % 3), 0.06, tints[(i * 7 + k * 3) % tints.size()])
			home()
			solid(Vector3((p.x + q.x) / 2.0, g + 0.6, 3.6), Vector3(ln, 2.6, 0.3))
		yard.append(spot(a.x, a.y))
		yard.append(spot(b.x, b.y))
	for q in [Vector2(25.0, 9.0), Vector2(36.5, 9.2), Vector2(47.0, 9.0)]:         # poplars on the lawn
		var g2: float = ground(q.x, q.y)
		drum(Vector3(q.x, g2, q.y), 0.22, 0.14, 3.6, 0x6b5a45, 8)
		ball(Vector3(q.x, g2 + 5.6, q.y), 1.7, "leaf", 1.7, 10, 7)
		solid(Vector3(q.x, g2 + 1.5, q.y), Vector3(0.5, 3.0, 0.5))
		yard.append(spot(q.x, q.y))
	for q in [Vector2(30.5, 13.0), Vector2(42.0, 13.0)]:                             # two benches
		var g3: float = ground(q.x, q.y)
		box(q.x - 0.9, g3 + 0.4, q.y - 0.22, 1.8, 0.07, 0.44, 0x8a6a48)
		box(q.x - 0.8, g3, q.y - 0.2, 0.08, 0.4, 0.4, 0x3a3d40)
		box(q.x + 0.72, g3, q.y - 0.2, 0.08, 0.4, 0.4, 0x3a3d40)

# ---------------- the car park ----------------
func _car_park() -> void:
	var under: Array = [Vector2(un, -43.0), Vector2(79, -43.0), Vector2(79, BACK), Vector2(un, BACK)]
	_drape(under, "asfalto", 0.035, 2.5)
	_drape([Vector2(3.9, -38.9), PARK[1], PARK[2], PARK[3], Vector2(79.0, -108.0), Vector2(79.0, -38.9)], "asfalto", 0.035, 3.0)
	_drape(THROAT, "asfalto", 0.04, 2.0)
	# the bays: a row under the shop against its back wall, two double rows in the open, one along the far end
	var x := 6.5
	while x < 77.0:
		if x > un + 0.5:
			_line(Vector2(x, BACK - 0.3), Vector2(x, BACK - 5.0))
		if x > 14.0 and x < 74.5:
			_line(Vector2(x, -47.5), Vector2(x, -57.0))
		if x > 22.0 and x < 74.5:
			_line(Vector2(x, -65.5), Vector2(x, -75.0))
		if x > 34.0 and x < 74.5:
			_line(Vector2(x, -84.0), Vector2(x, -93.5))
		x += 2.5
	_line(Vector2(15.0, -52.25), Vector2(74.0, -52.25))
	_line(Vector2(23.0, -70.25), Vector2(74.0, -70.25))
	_line(Vector2(35.0, -88.75), Vector2(74.0, -88.75))
	for q in [Vector2(40.0, -43.3), Vector2(60.0, -61.2), Vector2(45.0, -79.5)]:      # arrows on the lanes
		_line(q + Vector2(-1.2, 0), q + Vector2(1.2, 0), 0.16)
		_line(q + Vector2(0.5, -0.5), q + Vector2(1.2, 0), 0.16)
		_line(q + Vector2(0.5, 0.5), q + Vector2(1.2, 0), 0.16)
	# its fence: along the street side from the gate, round the far end, back along the south
	_fence(PARK[1], PARK[2], 0.9)
	_fence(PARK[2], PARK[3], 0.6)
	_fence(PARK[3], PARK[4], 0.5)
	_fence(PARK[4], PARK[5], 0.5)
	for q in [Vector2(30.0, -62.0), Vector2(58.0, -62.0), Vector2(40.0, -100.0), Vector2(68.0, -100.0)]:
		_lamp(q)
		yard.append(spot(q.x, q.y))
	# the little white house of the machines, by the fence: brown doors, a red-brown cap
	var h := Vector2(20.5, -66.0)
	var g: float = ground(h.x, h.y)
	cbox(Vector3(h.x, g + 1.3, h.y), Vector3(5.2, 2.6, 3.2), "blanco")
	cbox(Vector3(h.x, g + 2.68, h.y), Vector3(5.7, 0.16, 3.7), 0x8a4a3a)
	for s in [-1.2, 1.2]:
		cbox(Vector3(h.x - 2.61, g + 1.1, h.y + s), Vector3(0.03, 2.1, 1.5), 0x6a4a34)
	solid(Vector3(h.x, g + 1.3, h.y), Vector3(5.2, 2.6, 3.2))
	# where the trolleys are kept: a green frame with a clear roof
	var t := Vector2(46.0, -45.2)
	var gt: float = ground(t.x, t.y)
	for s in [-1.8, 1.8]:
		cbox(Vector3(t.x + s, gt + 1.0, t.y), Vector3(0.06, 2.0, 1.6), MESH)
	cbox(Vector3(t.x, gt + 2.02, t.y), Vector3(3.8, 0.05, 1.8), 0xbfe0c8)
	for i in range(5):
		cbox(Vector3(t.x - 1.2 + i * 0.6, gt + 0.5, t.y), Vector3(0.45, 0.9, 0.9), 0x9aa0a4)
