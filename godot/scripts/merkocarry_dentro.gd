extends "res://scripts/obra.gd"
## The inside of the Merkocarry (merkocarry.gd builds its outside): a set built far out in the fields, like the Noche's
## (noche_dentro.gd). The user, 17 November 2026: "luego les haces un interior al que se puede acceder por las dos
## entradas" -- you go in by its glass doors on Santa Ana and come in at the front, by the tills; or by its door from the
## car park and come in at the back, by the butcher's. Out by either, whichever you came in by (entradas.gd: both doors are
## one set, `set_id`).
##
## A cash and carry of the town, not a copy of any: the tills by the front doors, the fruit beside them, tall racks of blue
## and orange in long rows with the stock in boxes on top, pallets of water and oil, the cold cabinets down the left wall,
## drinks down the right, the butcher's counter at the back, trolleys at both doors, our name over both.
##
## What a place you go into has to give (game.gd _use_door): `door_out` and `out_spawn`, `out_h` in the street;
## `in_door` and `in_spawn` in the set; `open`. This is the front door's; `back` is the same for the door at the back.
## The room: 14 m wide, 24 deep; +z goes deeper in, from the front doors (z = 0) to the back door (z = D); y = 0 its floor.

const INSIDE := Vector2(1100.0, 1850.0)        # where the set is (no street within 360 m; the other sets 350 m off or more)
const HALF := 7.0                               # half its width
const D := 24.0                                 # how deep it is
const TALL := 4.2
const DIR := "res://assets/merkocarry/"
const RED := 0xde343e
const GREEN := 0x2e964e
const BLUE := 0x2b56b8
const ORANGE := 0xe8782a
const TINTS: Array = [0xd8243a, 0xf2c230, 0x2c7a3a, 0x2a5fb0, 0xf4f2ec, 0xe2702a, 0x8a3a8a, 0x6a4a2a, 0x2a8ab0, 0xb2ce34, 0x1f3a6a, 0xe85aa8]

## the door at the back, from the car park: a place of its own for entradas.gd, the same set as the front's
class Back extends Node:
	const HALF := 7.0                           # (the room seen from this door: entradas.gd room())
	const D := 24.0
	const TALL := 4.2
	var set_id := "merkocarry"
	var door_out: Vector2
	var out_spawn: Vector2
	var out_h := 0.0
	var in_door: Vector2
	var in_spawn: Vector2
	var open := false

var set_id := "merkocarry"      # (entradas.gd: the doors of one set, each a way out of it)
var door_out: Vector2           # its front doors on Santa Ana
var out_spawn: Vector2          # where you stand when you come out
var out_h := 0.0
var in_door: Vector2            # the same doors seen from inside
var in_spawn: Vector2
var open := false               # the shop's hours (merkocarry.gd set_open keeps it, and the back's)
var back: Back                  # the door at the back
var counter_front: Vector2      # where a customer stands at the first till
var trolleys := 0
var _rng := RandomNumberGenerator.new()

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: StandardMaterial3D = null
	match (String(key) if key is String else ""):
		"pared":
			m = _lit(Color(0.95, 0.95, 0.94), 0.3)
		"techo":
			m = _lit(Color(0.9, 0.91, 0.92), 0.25)
		"suelo":            # grey speckled concrete in big squares
			var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
			img.set_pixel(0, 0, Parts.col(0xbcbcb8)); img.set_pixel(1, 1, Parts.col(0xbcbcb8))
			img.set_pixel(1, 0, Parts.col(0xb2b2ae)); img.set_pixel(0, 1, Parts.col(0xb2b2ae))
			m = StandardMaterial3D.new()
			m.albedo_texture = ImageTexture.create_from_image(img)
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE / 2.0
			m.roughness = 0.75
		"calle":            # the street, seen through the glass doors from inside: all light
			m = _lit(Color(0.86, 0.93, 1.0), 1.5)
		"luz":
			m = _lit(Color(1.0, 0.98, 0.92), 2.2)
		"frio":             # the inside of the cold cabinets, lit
			m = _lit(Color(0.9, 0.96, 1.0), 0.9)
		"logo", "entrada", "cartel_iva", "cartel_hora":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(DIR + String(key) + ".png")
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		"vidrio":
			m = StandardMaterial3D.new()
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.8, 0.9, 0.95, 0.22)
			m.roughness = 0.1
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_:
			return super(key)
	_mats[key] = m
	return m

func _lit(c: Color, how: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = how
	return m

## its two doors in the street: the front's (on Santa Ana) and the back's (in the car park): where each is, where you come
## out, which way you face there
func build(world, front_at: Vector2, front_out: Vector2, front_h: float, back_at: Vector2, back_out: Vector2, back_h: float) -> void:
	W = world
	door_out = front_at
	out_spawn = front_out
	out_h = front_h
	var top := -1e9                                  # its floor is a deck at one height, whatever the field under it does
	for dx in range(-int(HALF) - 2, int(HALF) + 3):
		for dz in range(-2, int(D) + 3):
			top = maxf(top, MapData.height(INSIDE + Vector2(dx, dz)))
	level = top + 0.03
	var ring := PackedVector2Array([INSIDE + Vector2(-HALF - 0.6, -0.6), INSIDE + Vector2(HALF + 0.6, -0.6), INSIDE + Vector2(HALF + 0.6, D + 0.6), INSIDE + Vector2(-HALF - 0.6, D + 0.6)])
	MapData.decks.append({"o": INSIDE + Vector2(0.0, D / 2.0), "poly": ring, "r2": (HALF + 2.0) * (HALF + 2.0) + (D / 2.0 + 2.0) * (D / 2.0 + 2.0), "top": level})
	transform = Transform3D(Basis.IDENTITY, Vector3(INSIDE.x, level, INSIDE.y))
	W.add_child(self)
	in_door = INSIDE + Vector2(0.0, 0.45)
	in_spawn = INSIDE + Vector2(0.0, 2.4)
	back = Back.new()
	back.door_out = back_at
	back.out_spawn = back_out
	back.out_h = back_h
	back.in_door = INSIDE + Vector2(0.0, D - 0.45)
	back.in_spawn = INSIDE + Vector2(0.0, D - 2.4)
	add_child(back)
	counter_front = INSIDE + Vector2(-3.4, 3.2)
	_rng.seed = 1712
	_shell()
	_tills()
	_fruit()
	_racks()
	_pallets()
	_cold()
	_drinks()
	_butcher()
	for k in range(6):                               # trolleys by both doors
		_trolley(Vector3(6.2, 0.0, 1.2 + k * 0.42))
		_trolley(Vector3(5.6, 0.0, D - 2.0 - k * 0.42))
	_lamps()
	home()
	_commit()
	_indoors(self)

## indoors: the sun does not reach any of this (its cull mask in game.gd leaves this layer out)
func _indoors(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).layers = 1 << 10
	for c in n.get_children():
		_indoors(c)

func _tint() -> int:
	return TINTS[_rng.randi() % TINTS.size()]

## words on a wall: `turn` 0 faces +z (read from deeper in), PI faces the front doors
func _words(s: String, at: Vector3, turn: float, px: int, hex: int, pixel := 0.004) -> Label3D:
	var l := Label3D.new()
	l.text = s
	l.font_size = px
	l.pixel_size = pixel
	l.modulate = Parts.col(hex)
	l.outline_size = 0
	l.double_sided = false
	l.position = at
	l.rotation.y = turn
	add_child(l)
	return l

## a picture flat on the plane z (facing `n`: +1 deeper in, -1 the front doors)
func _pic(x0: float, x1: float, y0: float, y1: float, z: float, n: float, key) -> void:
	pieces += 1
	if n > 0.0:
		quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1), [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	else:
		quad(Vector3(x1, y0, z), Vector3(x0, y0, z), Vector3(x0, y1, z), Vector3(x1, y1, z), key, Vector3(0, 0, -1), [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

## a shelf's worth of goods: packets side by side from `from`, `run` metres along `along`, standing `deep` across
func _goods(from: Vector3, along: Vector3, run: float, deep: float, clear: float) -> void:
	var across := Vector3(-along.z, 0, along.x)
	var s := 0.0
	var c := _tint()
	var kind := _rng.randi() % 3
	while s < run - 0.05:
		var w := _rng.randf_range(0.08, 0.2) if kind != 2 else 0.1
		if _rng.randf() < 0.16:
			c = _tint()
			kind = _rng.randi() % 3
		if _rng.randf() < 0.05:
			s += w
			continue
		var h := clear * (_rng.randf_range(0.5, 0.85) if kind == 0 else (_rng.randf_range(0.3, 0.5) if kind == 1 else 0.75))
		var a := from + along * s
		var b := a + along * minf(w, run - s) + across * deep
		if kind == 2:
			drum(a + along * w / 2.0 + across * deep / 2.0, w * 0.45, w * 0.3, h, c, 8)
		else:
			box(minf(a.x, b.x), from.y, minf(a.z, b.z), absf(b.x - a.x) - 0.004, h, absf(b.z - a.z), c)
		s += w + 0.006

## one trolley (the car park's are the same): a basket of red, its handle, its wheels
func _trolley(at: Vector3) -> void:
	trolleys += 1
	box(at.x - 0.27, at.y + 0.45, at.z - 0.42, 0.54, 0.42, 0.82, RED)
	box(at.x - 0.24, at.y + 0.5, at.z - 0.39, 0.48, 0.38, 0.76, 0xb02a32)
	bar(Vector3(at.x - 0.3, at.y + 1.0, at.z + 0.48), Vector3(at.x + 0.3, at.y + 1.0, at.z + 0.48), 0.04, 0.04, GREEN)
	for s in [-0.22, 0.22]:
		bar(Vector3(at.x + s, at.y + 0.12, at.z - 0.35), Vector3(at.x + s, at.y + 0.45, at.z - 0.35), 0.025, 0.025, 0x8d9195)
		bar(Vector3(at.x + s, at.y + 0.12, at.z + 0.35), Vector3(at.x + s, at.y + 1.0, at.z + 0.48), 0.025, 0.025, 0x8d9195)
		box(at.x + s - 0.03, at.y, at.z - 0.38, 0.06, 0.12, 0.06, 0x1a1a1a)
		box(at.x + s - 0.03, at.y, at.z + 0.32, 0.06, 0.12, 0.06, 0x1a1a1a)

# ---------------- the room ----------------
## the floor, the ceiling, the walls; at each end the glass doors bright with the street, our name over them, the band
func _shell() -> void:
	quad(Vector3(-HALF, 0, 0), Vector3(HALF, 0, 0), Vector3(HALF, 0, D), Vector3(-HALF, 0, D), "suelo", Vector3.UP)
	quad(Vector3(-HALF, TALL, 0), Vector3(HALF, TALL, 0), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "techo", Vector3.DOWN)
	quad(Vector3(-HALF, 0, 0), Vector3(-HALF, 0, D), Vector3(-HALF, TALL, D), Vector3(-HALF, TALL, 0), "pared", Vector3(1, 0, 0))
	quad(Vector3(HALF, 0, 0), Vector3(HALF, 0, D), Vector3(HALF, TALL, D), Vector3(HALF, TALL, 0), "pared", Vector3(-1, 0, 0))
	for k in range(int(D / 4.0) + 1):                    # the beams under the roof
		box(-HALF, TALL - 0.35, k * 4.0 - 0.1, 2.0 * HALF, 0.3, 0.2, 0xc9ccd0)
	var dw := 1.4
	for end in [[0.0, 1.0], [D, -1.0]]:                  # the wall at each end: the doors in the middle
		var z: float = end[0]
		var n: float = end[1]
		for q in [[-HALF, -dw, 0.0, TALL], [dw, HALF, 0.0, TALL], [-dw, dw, 2.7, TALL]]:
			if n > 0.0:
				quad(Vector3(q[0], q[2], z), Vector3(q[1], q[2], z), Vector3(q[1], q[3], z), Vector3(q[0], q[3], z), "pared", Vector3(0, 0, 1))
			else:
				quad(Vector3(q[1], q[2], z), Vector3(q[0], q[2], z), Vector3(q[0], q[3], z), Vector3(q[1], q[3], z), "pared", Vector3(0, 0, -1))
		_pic(-dw, dw, 0.0, 2.7, z - n * 0.1, n, "calle")
		for x in [-dw, -0.03, dw - 0.06]:
			box(x, 0.0, z - (0.06 if n > 0.0 else 0.0), 0.06, 2.7, 0.06, 0x9a9da0)
		box(-dw, 2.65, z - (0.06 if n > 0.0 else 0.0), 2.0 * dw, 0.08, 0.06, 0x9a9da0)
		_pic(-dw + 0.06, dw - 0.06, 1.45, 1.65, z + n * 0.004, n, "entrada")
		box(-1.0, 0.0, z + (0.25 if n > 0.0 else -1.25), 2.0, 0.012, 1.0, 0x5a5c5e)         # the mat
		_pic(-2.4, 2.4, 2.95, 2.95 + 4.8 * 180.0 / 900.0, z + n * 0.02, n, "logo")
	box(-HALF, 2.6, 0.02, 2.0 * HALF, 0.22, 0.02, GREEN)                                     # a green band round the walls, high up
	box(-HALF, 2.6, D - 0.04, 2.0 * HALF, 0.22, 0.02, GREEN)
	box(-HALF + 0.02, 2.6, 0.0, 0.02, 0.22, D, GREEN)
	box(HALF - 0.04, 2.6, 0.0, 0.02, 0.22, D, GREEN)
	# what stops you: the four walls and the ceiling
	solid(Vector3(0, TALL / 2.0, -0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	solid(Vector3(0, TALL / 2.0, D + 0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	for sx in [-1.0, 1.0]:
		solid(Vector3(sx * (HALF + 0.2), TALL / 2.0, D / 2.0), Vector3(0.4, TALL, D + 0.8))
	solid(Vector3(0, TALL + 0.1, D / 2.0), Vector3(2.0 * HALF + 0.8, 0.2, D + 0.8))

## three tills on the left of the front doors: counters with belts, screens, the number of each on its post
func _tills() -> void:
	for k in range(3):
		var x0: float = -5.9 + k * 1.5
		box(x0, 0.0, 1.6, 0.8, 0.88, 2.6, 0x3d4045)
		box(x0 + 0.05, 0.88, 1.7, 0.7, 0.02, 1.8, 0x161616)
		box(x0 + 0.05, 0.89, 3.55, 0.7, 0.02, 0.6, 0xc9ccd0)
		box(x0 - 0.05, 0.88, 3.2, 0.08, 0.35, 0.4, 0x2a2a2c)
		box(x0 - 0.04, 0.95, 3.24, 0.01, 0.25, 0.32, 0x2a6a3a)
		box(x0 + 0.1, 0.9, 3.6, 0.35, 0.12, 0.3, 0x2a2a2c)
		drum(Vector3(x0 + 0.4, 0.9, 1.8), 0.03, 0.03, 1.3, 0x9a9da0, 6)
		box(x0 + 0.25, 2.2, 1.78, 0.3, 0.3, 0.04, RED)
		_words(str(k + 1), Vector3(x0 + 0.4, 2.35, 1.755), PI, 64, 0xfdfcf8, 0.004)
		solid(Vector3(x0 + 0.4, 0.45, 2.9), Vector3(0.8, 0.9, 2.6))
	_pic(-6.8, -5.0, 0.6, 1.6, 0.03, 1.0, "cartel_iva")                                   # its posters, by the doors, inside
	_pic(5.0, 6.8, 0.6, 1.6, 0.03, 1.0, "cartel_hora")

## the fruit and vegetables on the right of the front doors: crates on stepped stands
func _fruit() -> void:
	var colours: Array = [0xe2702a, 0xd8243a, 0x9ac23a, 0xf2c230, 0x5a8a2a, 0x8a3a5a, 0xe8e0a0, 0x7a4a2a]
	for j in range(2):
		var x0: float = 2.2 + j * 1.9
		box(x0, 0.0, 2.6, 1.6, 0.55, 1.2, 0x6a4a2a)
		box(x0, 0.55, 3.2, 1.6, 0.3, 0.6, 0x6a4a2a)
		for k in range(4):
			var cx: float = x0 + 0.2 + (k % 2) * 0.7
			var cz: float = 2.7 + (k / 2) * 0.6
			var cy: float = 0.55 + (k / 2) * 0.3
			var c: int = colours[(j * 4 + k) % colours.size()]
			box(cx - 0.05, cy, cz, 0.62, 0.1, 0.5, 0xb98a52)
			for n in range(6):
				ball(Vector3(cx + 0.06 + (n % 3) * 0.19, cy + 0.15, cz + 0.12 + (n / 3) * 0.25), 0.08, c, 0.9, 6, 4)
		solid(Vector3(x0 + 0.8, 0.45, 3.2), Vector3(1.6, 0.9, 1.2))
	_words("FRUTA Y VERDURA", Vector3(4.0, 2.3, 0.03), 0.0, 64, GREEN, 0.004)

## the tall racks: blue uprights, orange beams, goods on the lower shelves, boxes of stock on the top; four double
## rows going in, an end of offers at each end
func _racks() -> void:
	for xr in [-4.2, -1.8, 1.8, 4.2]:                     # (a wide aisle down the middle, from one door to the other)
		var x0: float = xr - 0.5
		var z0 := 6.0
		var z1 := 17.5
		var z := z0
		while z <= z1 + 0.01:                                 # the uprights
			for x in [x0, x0 + 1.0]:
				box(x - 0.04, 0.0, z - 0.04, 0.08, 3.0, 0.08, BLUE)
			z += 2.3
		for j in range(4):                                    # the beams and their shelves
			var y: float = 0.12 + j * 0.62
			for x in [x0 - 0.02, x0 + 0.94]:
				box(x, y - 0.06, z0, 0.08, 0.08, z1 - z0, ORANGE)
			box(x0, y - 0.02, z0, 1.0, 0.02, z1 - z0, 0xb9bcbf)
			if j < 3:
				for side in [0, 1]:
					var x: float = x0 + (0.5 if side == 1 else 0.0)
					_goods(Vector3(x + (0.48 if side == 1 else 0.0), y, z0 + 0.05), Vector3(0, 0, 1), z1 - z0 - 0.1, 0.46, 0.55)
			else:
				var zb := z0 + 0.1
				while zb < z1 - 0.6:                          # cartons of stock on the top shelf
					box(x0 + 0.05, y, zb, 0.9, _rng.randf_range(0.35, 0.55), _rng.randf_range(0.45, 0.7), [0xc8a070, 0xb8905e, 0xd8b884][_rng.randi() % 3])
					zb += 0.75
		for e in [[z0 - 0.7, PI], [z1 + 0.05, 0.0]]:          # the ends of offers
			var ez: float = e[0]
			box(x0 - 0.05, 0.0, ez, 1.1, 1.3, 0.65, 0xf4f4f0)
			box(x0 - 0.07, 1.3, ez - 0.02, 1.14, 0.3, 0.69, RED)
			_words("OFERTA", Vector3(x0 + 0.5, 1.45, ez - 0.03 if e[1] == PI else ez + 0.68), e[1], 64, 0xfdfcf8, 0.004)
			for j in range(3):
				_goods(Vector3(x0, 0.12 + j * 0.42, ez + 0.05), Vector3(1, 0, 0), 1.0, 0.3, 0.36)
		solid(Vector3(x0 + 0.5, 1.5, (z0 + z1) / 2.0), Vector3(1.1, 3.0, z1 - z0 + 1.5))

## pallets at the back, between the racks and the back door: packs of water, bottles of oil, under the price card
func _pallets() -> void:
	for p in [[1.6, 19.4, 0xa8d0e8, 0x2a82d8], [2.9, 19.4, 0xe8d070, 0x4a7a2a], [4.2, 19.4, 0xa8d0e8, 0x2a82d8]]:
		var x: float = p[0]
		var z: float = p[1]
		box(x - 0.6, 0.0, z - 0.5, 1.2, 0.14, 1.0, 0xb98a52)
		for i in range(3):
			for j in range(2):
				for l in range(3):
					box(x - 0.58 + i * 0.39, 0.14 + l * 0.3, z - 0.48 + j * 0.48, 0.37, 0.28, 0.46, p[2])
					box(x - 0.58 + i * 0.39, 0.24 + l * 0.3, z - 0.48 + j * 0.48, 0.37, 0.07, 0.46, p[3])
		box(x - 0.2, 1.05, z - 0.02, 0.4, 0.3, 0.02, 0xf2d040)
		solid(Vector3(x, 0.55, z), Vector3(1.2, 1.1, 1.0))

## the cold cabinets down the left wall: white bodies, lit insides behind glass, goods on their shelves
func _cold() -> void:
	var z0 := 5.6
	var z1 := 17.8
	var x0 := -HALF
	box(x0, 0.0, z0, 0.8, 2.1, z1 - z0, 0xf4f4f0)
	box(x0 + 0.05, 0.25, z0 + 0.05, 0.7, 1.7, z1 - z0 - 0.1, "frio")
	for j in range(4):
		var y := 0.3 + j * 0.42
		box(x0 + 0.1, y - 0.02, z0 + 0.05, 0.6, 0.02, z1 - z0 - 0.1, 0xc9ccd0)
		_goods(Vector3(x0 + 0.45, y, z0 + 0.1), Vector3(0, 0, 1), z1 - z0 - 0.2, 0.3, 0.36)
	var z := z0
	while z < z1 - 0.1:
		quad(Vector3(x0 + 0.8, 0.25, z), Vector3(x0 + 0.8, 0.25, z + 0.9), Vector3(x0 + 0.8, 1.95, z + 0.9), Vector3(x0 + 0.8, 1.95, z), "vidrio", Vector3(1, 0, 0))
		box(x0 + 0.78, 0.25, z, 0.04, 1.7, 0.04, 0x8a8d90)
		box(x0 + 0.79, 1.0, z + 0.8, 0.04, 0.3, 0.03, 0x5a5c5e)
		z += 0.95
	_words("CONGELADOS Y LÁCTEOS", Vector3(x0 + 0.02, 2.4, (z0 + z1) / 2.0), PI / 2.0, 80, BLUE, 0.004)
	solid(Vector3(x0 + 0.4, 1.05, (z0 + z1) / 2.0), Vector3(0.8, 2.1, z1 - z0))

## drinks down the right wall: shelving with rows of bottles, packs at its foot
func _drinks() -> void:
	var z0 := 5.0
	var z1 := 18.5
	var x0 := HALF - 0.55
	box(HALF - 0.03, 0.0, z0, 0.03, 2.2, z1 - z0, 0xd9dadb)
	for j in range(5):
		var y := 0.1 + j * 0.42
		box(x0, y - 0.03, z0, 0.52, 0.03, z1 - z0, 0xb9bcbf)
		if j == 0:
			var z := z0 + 0.1
			while z < z1 - 0.5:
				box(x0 + 0.05, y, z, 0.42, 0.3, 0.45, 0xa8d0e8)
				box(x0 + 0.04, y + 0.12, z, 0.44, 0.08, 0.45, 0x2a82d8)
				z += 0.5
		else:
			_goods(Vector3(x0 + 0.49, y, z0 + 0.05), Vector3(0, 0, 1), z1 - z0 - 0.1, 0.36, 0.38)
	_words("BEBIDAS", Vector3(HALF - 0.04, 2.4, (z0 + z1) / 2.0), -PI / 2.0, 90, RED, 0.004)
	solid(Vector3(HALF - 0.27, 1.1, (z0 + z1) / 2.0), Vector3(0.55, 2.2, z1 - z0))

## the butcher's at the back, on the left of the back door: a counter of glass, lit, the meat in trays on its shelves,
## the white tiles and the hooks behind; its name over it (nobody behind it yet)
func _butcher() -> void:
	var z := D - 3.6
	var x0 := -HALF + 0.3
	var x1 := -1.8
	box(x0, 0.0, z, x1 - x0, 0.85, 0.9, 0xf4f4f0)
	box(x0 + 0.05, 0.85, z + 0.78, x1 - x0 - 0.1, 0.42, 0.06, "frio")                     # its lit back, and its lid: the meat shows through the glass
	box(x0 + 0.05, 1.27, z + 0.3, x1 - x0 - 0.1, 0.03, 0.54, "frio")
	quad(Vector3(x0, 0.85, z), Vector3(x1, 0.85, z), Vector3(x1, 1.3, z + 0.3), Vector3(x0, 1.3, z + 0.3), "vidrio", Vector3(0, 0.6, -1))
	var x := x0 + 0.15
	while x < x1 - 0.4:
		box(x, 0.87, z + 0.2, 0.32, 0.04, 0.45, 0xe8e8e4)
		box(x + 0.03, 0.91, z + 0.24, 0.26, 0.05, 0.36, [0xb8343a, 0xc84a4a, 0xe8b0a0, 0xa02a30][_rng.randi() % 4])
		x += 0.38
	box(x0, 0.0, D - 0.06, x1 - x0, 2.4, 0.04, 0xf2f2ee)                                   # the tiles behind
	for k in range(6):
		box(x0 + 0.4 + k * 0.7, 2.0, D - 0.3, 0.04, 0.25, 0.04, 0x8a8d90)
	box(x0 + 0.2, 2.65, D - 0.08, 3.4, 0.5, 0.04, RED)
	_words("CARNICERÍA", Vector3(x0 + 1.9, 2.9, D - 0.1), PI, 90, 0xfdfcf8, 0.004)
	solid(Vector3((x0 + x1) / 2.0, 0.6, z + 0.45), Vector3(x1 - x0, 1.2, 0.9))
	# on the right of the back door: the trolleys (built with the front's) and an end of offers
	box(2.4, 0.0, D - 1.2, 1.1, 1.3, 0.65, 0xf4f4f0)
	box(2.38, 1.3, D - 1.22, 1.14, 0.3, 0.69, RED)
	solid(Vector3(2.95, 0.65, D - 0.9), Vector3(1.1, 1.3, 0.7))

## the strip lamps along the ceiling, and the light they give
func _lamps() -> void:
	for z in [2.0, 6.0, 10.0, 14.0, 18.0, 22.0]:
		for sx in [-4.8, -2.4, 0.0, 2.4, 4.8]:
			cbox(Vector3(sx, TALL - 0.4, z), Vector3(0.18, 0.05, 1.8), "luz")
			cbox(Vector3(sx, TALL - 0.37, z), Vector3(0.26, 0.02, 1.9), 0xd9d6cc)
	for at in [Vector3(-3.5, 3.4, 3.0), Vector3(3.5, 3.4, 3.0), Vector3(-3.5, 3.4, 11.0), Vector3(3.5, 3.4, 11.0), Vector3(-3.5, 3.4, 20.0), Vector3(3.5, 3.4, 20.0)]:
		var lamp := OmniLight3D.new()
		lamp.position = at
		lamp.light_color = Color(1.0, 0.98, 0.92)
		lamp.omni_range = 10.0
		lamp.light_energy = 0.55
		lamp.shadow_enabled = false
		add_child(lamp)
