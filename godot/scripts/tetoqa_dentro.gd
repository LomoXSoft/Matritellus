extends "res://scripts/obra.gd"
## The inside of the accessories shop "Tetoqa" of the corner of Santa Ana and the Cristo (tetoqa.gd builds its fronts).
## The user, 23 November 2026: "Mismo tratamiento que con MiniPrecio pero esta vez para complementos". A set built far
## out in the fields, like the MaxiPrecio's (maxiprecio_dentro.gd), walked into by the green arrow before the chamfer
## (entradas.gd).
##
## FIRST DRAFT, before the user's pictures of the real inside (Google Maps shows them only signed in): a small shop of
## accessories as the town's are, as its windows show it -- white walls, a floor of pale wood, little round lights in the
## ceiling. Along the wall at your left as you come in, white cube shelves of handbags, shoes and hat boxes; along the
## other, past the counter, a rail of clothes and a row of hooks of hats and scarves over it; in the middle a glass case
## of jewellery and watches, a tower of sunglasses, a round table of scarves and hats, a hat stand; on the back wall
## the shop's name in pink handwriting (the game's own) over a low bench of hat boxes, an oval mirror; the counter with
## the till at your right as you come in, a pink wall behind it with shelves of gift boxes and bags; the fitting room in
## the far corner behind a pink curtain. Nobody is modelled (no mannequins either: the user decides figures).
## A saffron flower is hidden in a hat box of the bench at the back, its lid off beside it (the user, 23 Nov 2026,
## to the proposal "dentro de una sombrerera del banco del fondo": "Si a las tres recomendaciones").
##
## What a place you go into has to give (game.gd _use_door): `door_out`, `out_spawn`, `out_h` on the street; `in_door`
## and `in_spawn` in the set; `open` (the shop's hours: tetoqa.gd set_open keeps it). For Sistemas, if somebody serves
## here: `clerk_spot` and `clerk_h` (behind the counter, looking at the room), `client_spot` and `client_h` (before it),
## `probador_spot` and `probador_h` (in the fitting room, looking out at the room: 3.6 m free before it, and a step to
## its side). The room: 7 m wide, 9 deep; +z deeper in, the door at z = 0; looking in, +x is on your left.

const INSIDE := Vector2(-1000.0, -1200.0)       # where the set is: no street within 260 m, no tree of the map within
                                                # 790 m, no field, the other sets 600 m off or more (the Recress's nearest)
const HALF := 3.5                               # half its width
const D := 9.0                                  # how deep it is
const TALL := 3.0
const DIR := "res://assets/tetoqa/"
const COUNTER := Rect2(-2.6, 1.3, 0.85, 2.2)    # the counter: from x, from z, how wide (x), how long (z)
const CUBE := 0.38                              # the cube shelves' cubes
const SHELF_D := 0.4
const ROOM := Rect2(-HALF, D - 1.5, 1.3, 1.5)   # the fitting room: from x, from z, how wide, how deep
const PINK := 0xe8a0b8
const COLOURS := [0xc8384a, 0x2f2f36, 0xe8d8b0, 0x8a5a3a, 0xe8a0b0, 0xf2f0ea, 0x3a5a9a, 0xd8a040, 0x7a5aa0, 0x5a8a6a, 0xb07a52, 0x9a2a3a, 0xd0c0a8, 0x1f1f22, 0x58b8c8, 0xf0c8a0]

var door_out: Vector2
var out_spawn: Vector2
var out_h := 0.0
var in_door: Vector2
var in_spawn: Vector2
var open := false               # the shop's hours (tetoqa.gd)
var clerk_spot: Vector2         # behind the counter...
var clerk_h := 0.0              # ...looking at the room
var client_spot: Vector2        # before it
var client_h := 0.0
var probador_spot: Vector2      # in the fitting room...
var probador_h := PI - 0.45     # ...looking out of it, a little towards the middle of the shop (it is in the corner on your right as you come in: straight out, the camera a step to its side would be in the wall)
var props := 0
var saffron_spot: Vector2       # the hidden saffron (in the game's flowers, "id": "tetoqa")
var _n := 0                     # (for the colours: the same every time)

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: StandardMaterial3D = null
	match (String(key) if key is String else ""):
		"suelo":            # pale wood in long boards
			var img := Image.create(16, 64, false, Image.FORMAT_RGB8)
			for y in range(64):
				for x in range(16):
					var board := x / 4
					var c := Color(0.82, 0.7, 0.55).darkened(0.04 * ((board * 5 + y / 16) % 3))
					c = c.lightened(0.03 * sin((y + board * 13) * 0.7))
					if x % 4 == 0 or (y + board * 21) % 64 == 0:
						c = Color(0.62, 0.5, 0.38)
					img.set_pixel(x, y, c)
			m = StandardMaterial3D.new()
			m.albedo_texture = ImageTexture.create_from_image(img)
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3(1.0 / 0.6, 1.0, 1.0 / 2.4)
			m.roughness = 0.5
			m.emission_enabled = true
			m.emission = Color(0.82, 0.7, 0.55)
			m.emission_energy_multiplier = 0.18
		"pared":
			m = _lit(Color(0.97, 0.96, 0.95), 0.3)
		"rosa":             # the wall behind the counter
			m = _lit(Color(0.95, 0.75, 0.8), 0.28)
		"techo":
			m = _lit(Color(0.96, 0.96, 0.95), 0.32)
		"calle":            # the street's light at the door and the windows
			m = _lit(Color(0.88, 0.94, 1.0), 1.4)
		"luz":
			m = _lit(Color(1.0, 0.99, 0.95), 1.8)
		"espejo":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.7, 0.78, 0.82)
			m.metallic = 0.9
			m.roughness = 0.05
			m.emission_enabled = true
			m.emission = Color(0.7, 0.78, 0.82)
			m.emission_energy_multiplier = 0.25
		"cristal":          # the glass of the jewellery case
			m = StandardMaterial3D.new()
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.75, 0.88, 0.9, 0.22)
			m.roughness = 0.1
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"cortina":          # the fitting room's curtain: pink, in folds
			var cimg := Image.create(32, 4, false, Image.FORMAT_RGB8)
			for x in range(32):
				for y in range(4):
					cimg.set_pixel(x, y, Color(0.9, 0.5, 0.64) * (0.82 + 0.18 * sin(x / 32.0 * TAU * 4.0)))
			m = StandardMaterial3D.new()
			m.albedo_texture = ImageTexture.create_from_image(cimg)
			m.roughness = 1.0
			m.emission_enabled = true
			m.emission_texture = m.albedo_texture
			m.emission = Color.WHITE
			m.emission_energy_multiplier = 0.3
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"mural", "horario":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(DIR + String(key) + ".png")
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			m.roughness = 0.9
			m.emission_enabled = true
			m.emission_texture = m.albedo_texture
			m.emission = Color.WHITE
			m.emission_energy_multiplier = 0.3
			if key == "mural":
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				m.alpha_scissor_threshold = 0.5
		_:
			var pm := Parts.mat(int(key)).duplicate() as StandardMaterial3D      # (plain colours, with a little light of their own: it is a set, lit by its lamps alone)
			pm.emission_enabled = true
			pm.emission = pm.albedo_color
			pm.emission_energy_multiplier = 0.25
			_mats[key] = pm
			return pm
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

## its door on the street, where you come out to and which way you face there
func build(world, at: Vector2, out: Vector2, heading: float) -> void:
	W = world
	door_out = at
	out_spawn = out
	out_h = heading
	var top := -1e9
	for dx in range(-int(HALF) - 2, int(HALF) + 3):
		for dz in range(-2, int(D) + 3):
			top = maxf(top, MapData.height(INSIDE + Vector2(dx, dz)))
	level = top + 0.03
	var ring := PackedVector2Array([INSIDE + Vector2(-HALF - 0.6, -0.6), INSIDE + Vector2(HALF + 0.6, -0.6), INSIDE + Vector2(HALF + 0.6, D + 0.6), INSIDE + Vector2(-HALF - 0.6, D + 0.6)])
	MapData.decks.append({"o": INSIDE + Vector2(0.0, D / 2.0), "poly": ring, "r2": (HALF + 2.0) * (HALF + 2.0) + (D / 2.0 + 2.0) * (D / 2.0 + 2.0), "top": level})
	transform = Transform3D(Basis.IDENTITY, Vector3(INSIDE.x, level, INSIDE.y))
	W.add_child(self)
	in_door = INSIDE + Vector2(0.0, 0.45)
	in_spawn = INSIDE + Vector2(0.0, 1.4)
	clerk_spot = INSIDE + Vector2((-HALF + COUNTER.position.x) / 2.0, COUNTER.position.y + COUNTER.size.y / 2.0)
	clerk_h = PI / 2.0                              # (looking across the counter, at the room: +x)
	client_spot = INSIDE + Vector2(COUNTER.end.x + 0.6, COUNTER.position.y + COUNTER.size.y / 2.0)
	client_h = -PI / 2.0
	probador_spot = INSIDE + Vector2(ROOM.get_center().x, D - 0.65)
	_shell()
	_cube_shelves()
	_counter()
	_rail_wall()
	_back_wall()
	_middle()
	_fitting_room()
	_lamps()
	home()
	_commit()
	_indoors(self)

func _indoors(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).layers = 1 << 10
	for c in n.get_children():
		_indoors(c)

## where a piece stands: `at` its foot, turned `yaw` about the upright (until home())
func _put(at: Vector3, yaw := 0.0) -> void:
	_xf = Transform3D(Basis(Vector3.UP, yaw), at)
	props += 1

## the next colour of the shop's things (always the same sequence)
func _colour(shift := 0) -> int:
	_n += 1
	return COLOURS[(_n * 7 + shift * 3 + (_n / 5)) % COLOURS.size()]

# ---------------- the things it sells ----------------
## a handbag standing at x (its middle), its foot at y, its middle at z: `w` wide, `facing` +1 out of +z, -1 out of -z
## (or turned with _put), its handle, its clasp
func _bag(x: float, y: float, z: float, w: float, col: int, along_x := true) -> void:
	props += 1
	var h := w * 0.7
	var t := 0.12
	if along_x:
		box(x - w / 2.0, y, z - t / 2.0, w, h, t, col)
	else:
		box(x - t / 2.0, y, z - w / 2.0, t, h, w, col)
	var top := y + h + w * 0.32
	var u := Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)
	var c := Vector3(x, 0, z)
	bar(c + u * (-w * 0.3) + Vector3(0, y + h, 0), c + u * (-w * 0.16) + Vector3(0, top, 0), 0.016, 0.016, col)
	bar(c + u * (-w * 0.16) + Vector3(0, top, 0), c + u * (w * 0.16) + Vector3(0, top, 0), 0.016, 0.016, col)
	bar(c + u * (w * 0.16) + Vector3(0, top, 0), c + u * (w * 0.3) + Vector3(0, y + h, 0), 0.016, 0.016, col)

## a pair of shoes at (x, z), their toes towards +z (or -x when `to_x`)
func _shoes(x: float, y: float, z: float, col: int, to_x := false) -> void:
	props += 1
	for s in [-0.06, 0.06]:
		if to_x:
			box(x - 0.12, y, z + s - 0.04, 0.24, 0.055, 0.08, col)
			box(x + 0.05, y, z + s - 0.04, 0.07, 0.11, 0.08, col)
		else:
			box(x + s - 0.04, y, z - 0.12, 0.08, 0.055, 0.24, col)
			box(x + s - 0.04, y, z - 0.12, 0.08, 0.11, 0.07, col)

## a hat: its brim (radius r), its crown, its band
func _hat(at: Vector3, col: int, r := 0.17) -> void:
	props += 1
	drum(at, r, r, 0.012, col, 16)
	drum(at + Vector3(0, 0.012, 0), r * 0.55, r * 0.5, r * 0.6, col, 14)
	drum(at + Vector3(0, 0.012, 0), r * 0.56, r * 0.555, r * 0.16, 0x2a2622 if col != 0x1f1f22 else 0xc8384a, 14)

## a round hat box with its lid
func _hatbox(at: Vector3, col: int, r := 0.2) -> void:
	props += 1
	drum(at, r, r, r * 1.1, col, 16)
	drum(at + Vector3(0, r * 1.05, 0), r + 0.01, r + 0.01, 0.05, 0xf2f0ea if col != 0xf2f0ea else PINK, 16)

# ---------------- the room ----------------
func _shell() -> void:
	quad(Vector3(-HALF, 0, 0), Vector3(HALF, 0, 0), Vector3(HALF, 0, D), Vector3(-HALF, 0, D), "suelo", Vector3.UP)
	quad(Vector3(-HALF, TALL, 0), Vector3(HALF, TALL, 0), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "techo", Vector3.DOWN)
	for sx in [-1.0, 1.0]:
		var x: float = sx * HALF
		quad(Vector3(x, 0, 0), Vector3(x, 0, D), Vector3(x, TALL, D), Vector3(x, TALL, 0), "pared", Vector3(-sx, 0, 0))
		box(x - (0.01 if sx > 0.0 else 0.0), 0.0, 0.0, 0.01, 0.08, D, 0xd8d0c8)                                      # (the skirting)
	quad(Vector3(-HALF, 0, D), Vector3(HALF, 0, D), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "pared", Vector3(0, 0, -1))
	box(-HALF, 0.0, D - 0.01, 2.0 * HALF, 0.08, 0.01, 0xd8d0c8)
	# the front from inside: the glass door in the middle, open while you are here, a window at each side, the street
	# bright beyond them
	var door := [-0.55, 0.55]
	var top := 2.5
	var panes := [[1.0, 3.2], [-3.2, -1.0]]
	var cuts: Array = [[-HALF, -3.2, 0.0, TALL], [-1.0, door[0], 0.0, TALL], [door[1], 1.0, 0.0, TALL], [3.2, HALF, 0.0, TALL], [door[0], door[1], top, TALL],
		[-3.2, -1.0, 0.0, 0.55], [1.0, 3.2, 0.0, 0.55], [-3.2, -1.0, 2.6, TALL], [1.0, 3.2, 2.6, TALL]]
	for q in cuts:
		quad(Vector3(q[0], q[2], 0), Vector3(q[1], q[2], 0), Vector3(q[1], q[3], 0), Vector3(q[0], q[3], 0), "pared", Vector3(0, 0, 1))
	quad(Vector3(door[0], 0, -0.15), Vector3(door[1], 0, -0.15), Vector3(door[1], top, -0.15), Vector3(door[0], top, -0.15), "calle", Vector3(0, 0, 1))
	for p in panes:
		quad(Vector3(p[0], 0.55, -0.15), Vector3(p[1], 0.55, -0.15), Vector3(p[1], 2.6, -0.15), Vector3(p[0], 2.6, -0.15), "calle", Vector3(0, 0, 1))
		for x in [p[0], (p[0] + p[1]) / 2.0 - 0.03, p[1] - 0.06]:
			box(x, 0.55, -0.08, 0.06, 2.05, 0.1, 0xeeeeea)
		box(p[0], 0.49, -0.08, p[1] - p[0], 0.08, 0.16, 0xeeeeea)
		box(p[0], 2.56, -0.08, p[1] - p[0], 0.06, 0.1, 0xeeeeea)
	for x in [door[0] - 0.07, door[1]]:
		box(x, 0.0, -0.08, 0.07, top, 0.1, 0xeeeeea)
	box(door[0] - 0.07, top, -0.08, door[1] - door[0] + 0.14, 0.07, 0.1, 0xeeeeea)
	box(door[0] - 0.2, 0.0, 0.2, door[1] - door[0] + 0.4, 0.014, 0.8, 0x7a3a4e)                                    # the mat
	quad(Vector3(0.7, 1.35, 0.012), Vector3(1.0, 1.35, 0.012), Vector3(1.0, 1.75, 0.012), Vector3(0.7, 1.75, 0.012), "horario", Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])                                               # (its hours, seen from inside: on the wall by the door)
	solid(Vector3(0, TALL / 2.0, -0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	solid(Vector3(0, TALL / 2.0, D + 0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	for sx in [-1.0, 1.0]:
		solid(Vector3(sx * (HALF + 0.2), TALL / 2.0, D / 2.0), Vector3(0.4, TALL, D + 0.8))
	solid(Vector3(0, TALL + 0.1, D / 2.0), Vector3(2.0 * HALF + 0.8, 0.2, D + 0.8))

# ---------------- the cube shelves along the wall at your left ----------------
## From near the door to near the back: white cubes five high, a handbag, a pair of shoes, a hat box or folded scarves
## in each.
func _cube_shelves() -> void:
	var x_wall := HALF
	var x_in := HALF - SHELF_D
	var z0 := 0.9
	var cols := 15
	var rows := 5
	for i in range(cols + 1):
		box(x_in, 0.0, z0 + i * CUBE - 0.012, SHELF_D, rows * CUBE + 0.1, 0.024, 0xf4f4f0)
	for j in range(rows + 1):
		box(x_in, 0.1 + j * CUBE - (0.024 if j > 0 else 0.0), z0, SHELF_D, 0.024, cols * CUBE, 0xf4f4f0)
	box(x_in, 0.0, z0, SHELF_D, 0.1, cols * CUBE, 0xe4e4e0)                                                         # its foot
	box(x_wall - 0.01, 0.1, z0, 0.01, rows * CUBE, cols * CUBE, 0xe8e6e2)                                           # its back
	props += 1
	for i in range(cols):
		for j in range(rows):
			var zc := z0 + (i + 0.5) * CUBE
			var y := 0.1 + j * CUBE + 0.012
			var xc := x_in + SHELF_D / 2.0
			match (i * 2 + j * 3) % 6:
				0, 3:
					_bag(xc, y, zc, CUBE * 0.62, _colour(), false)
				1, 4:
					_shoes(xc, y, zc, _colour(), true)
				2:
					_hatbox(Vector3(xc, y, zc), _colour(), 0.13)
				5:
					for f in range(4):
						box(xc - 0.13, y + f * 0.045, zc - 0.13, 0.26, 0.04, 0.26, _colour(f))
	solid(Vector3(HALF - SHELF_D / 2.0, 1.0, z0 + cols * CUBE / 2.0), Vector3(SHELF_D, 2.0, cols * CUBE))

# ---------------- the counter ----------------
## At your right as you come in: a white counter with a pink front, the till, the card machine, a jar of hair clips, a
## roll of paper bags; behind it a pink wall with shelves of gift boxes and bags.
func _counter() -> void:
	var x0 := COUNTER.position.x
	var x1 := COUNTER.end.x
	var z0 := COUNTER.position.y
	var z1 := COUNTER.end.y
	box(x0, 0.0, z0, x1 - x0, 0.95, z1 - z0, 0xf4f4f0)
	box(x0 - 0.03, 0.95, z0 - 0.03, x1 - x0 + 0.06, 0.04, z1 - z0 + 0.06, 0xf8f8f6)
	box(x1 - 0.01, 0.12, z0 + 0.1, 0.012, 0.7, z1 - z0 - 0.2, PINK)                                          # its pink front
	_put(Vector3(x0 + 0.35, 0.99, z0 + 0.8), PI / 2.0)                              # the till: its drawer, its screen towards you
	box(-0.22, 0.0, -0.2, 0.44, 0.1, 0.4, 0x2a2a2e)
	box(-0.2, 0.1, -0.12, 0.4, 0.06, 0.24, 0x3a3a3e)
	bar(Vector3(0, 0.16, 0.05), Vector3(0, 0.42, 0.12), 0.04, 0.04, 0x2a2a2e)
	box(-0.17, 0.38, 0.1, 0.34, 0.24, 0.03, 0x1a1a1c)
	box(-0.15, 0.4, 0.13, 0.3, 0.2, 0.002, 0x4a7ab0)
	home()
	box(x0 + 0.55, 0.99, z0 + 1.35, 0.08, 0.04, 0.16, 0x2a2a2e)                     # the card machine
	box(x0 + 0.56, 1.03, z0 + 1.37, 0.06, 0.012, 0.08, 0x4a7ab0)
	drum(Vector3(x0 + 0.62, 0.99, z0 + 0.3), 0.07, 0.07, 0.14, 0xc8dce0, 10)       # a jar of hair clips
	for k in range(5):
		box(x0 + 0.58 + (k % 2) * 0.04, 1.08 + k * 0.012, z0 + 0.26 + (k % 3) * 0.03, 0.04, 0.012, 0.02, _colour())
	drum(Vector3(x0 + 0.3, 0.99, z0 + 1.85), 0.09, 0.09, 0.3, 0xf2f0ea, 10)       # a roll of paper bags
	# behind it: the pink wall, its shelves of gift boxes and bags
	quad(Vector3(-HALF + 0.005, 0, z0 - 0.4), Vector3(-HALF + 0.005, 0, z1 + 0.4), Vector3(-HALF + 0.005, TALL, z1 + 0.4), Vector3(-HALF + 0.005, TALL, z0 - 0.4), "rosa", Vector3(1, 0, 0))
	for y in [1.2, 1.6, 2.0]:
		box(-HALF, y, z0 - 0.2, 0.22, 0.025, z1 - z0 + 0.4, 0xf4f4f0)
		var z := z0 - 0.05
		var k := 0
		while z < z1 + 0.1:
			if k % 2 == 0:
				box(-HALF + 0.03, y + 0.025, z, 0.15, 0.14 + 0.04 * (k % 3), 0.2, [0xf2f0ea, PINK, 0xc8384a, 0xd8c8a8][k % 4])
			else:
				_bag(-HALF + 0.11, y + 0.025, z + 0.1, 0.2, _colour(), false)
			z += 0.3
			k += 1
	props += 6
	solid(Vector3(COUNTER.get_center().x, 0.5, COUNTER.get_center().y), Vector3(COUNTER.size.x, 1.0, COUNTER.size.y))
	for zs in [z0 - 0.05, z1 + 0.05]:                                              # (nobody goes behind it but who serves)
		solid(Vector3((-HALF + x0) / 2.0, 0.5, zs), Vector3(x0 + HALF, 1.0, 0.1))
	box(-HALF, 0.0, z0 - 0.08, x0 + HALF, 0.9, 0.05, 0xf4f4f0)                     # (a low flap at its front end)

# ---------------- the rail along the other wall ----------------
## Past the counter, along the wall at your right: a rail of clothes (dresses, jackets, cardigans) and over it a row of
## hooks with hats and scarves.
func _rail_wall() -> void:
	var x := -HALF + 0.32
	var z0 := COUNTER.end.y + 0.7
	var z1 := ROOM.position.y - 0.35
	for zz in [z0, z1]:
		bar(Vector3(-HALF, 1.62, zz), Vector3(x, 1.62, zz), 0.025, 0.025, 0xb8bcc0)
	bar(Vector3(x, 1.62, z0), Vector3(x, 1.62, z1), 0.025, 0.025, 0xb8bcc0)
	var z := z0 + 0.06
	var c := _colour()
	var k := 0
	while z < z1 - 0.05:
		if k % 4 == 0:
			c = _colour(k)
		var long := 0.75 + 0.3 * ((k / 4) % 2)
		box(x - 0.22, 1.55 - long, z - 0.015, 0.44, long, 0.03, c)
		bar(Vector3(x - 0.2, 1.57, z), Vector3(x + 0.2, 1.57, z), 0.012, 0.012, 0x5a4636)
		z += 0.07
		k += 1
	props += 1
	solid(Vector3(x, 0.8, (z0 + z1) / 2.0), Vector3(0.6, 1.6, z1 - z0 + 0.1))
	box(-HALF, 2.15, z0, 0.03, 0.03, z1 - z0, 0xb8bcc0)                            # the hooks' rail...
	var zh := z0 + 0.25
	var i := 0
	while zh < z1 - 0.2:                                                           # ...hats and scarves on its hooks
		bar(Vector3(-HALF + 0.02, 2.16, zh), Vector3(-HALF + 0.12, 2.2, zh), 0.012, 0.012, 0x9aa0a8)
		if i % 2 == 0:                                                             # (a hat hung by its brim, its crown to the room)
			var keep := _xf
			_xf = Transform3D(Basis(Vector3(0, 0, 1), -PI / 2.0 + 0.25), Vector3(-HALF + 0.14, 2.1, zh))
			drum(Vector3.ZERO, 0.18, 0.18, 0.012, _colour(), 16)
			drum(Vector3(0, 0.012, 0), 0.1, 0.09, 0.1, _colour(i), 14)
			_xf = keep
			props += 1
		else:
			box(-HALF + 0.08, 1.35, zh - 0.08, 0.025, 0.82, 0.16, _colour(i))
			props += 1
		zh += 0.45
		i += 1

# ---------------- the back wall: the shop's name, a bench of hat boxes, the mirror ----------------
func _back_wall() -> void:
	var z := D - 0.04
	_picture_back(-0.5, 1.9, 1.45, 2.65, z - 0.01, "mural")
	box(-0.4, 0.0, D - 0.5, 3.4, 0.45, 0.45, 0xf4f4f0)                              # the low bench
	for q in [[-0.1, 0.2], [0.35, 0.16], [0.75, 0.2], [1.3, 0.14], [1.75, 0.2], [2.2, 0.16]]:
		_hatbox(Vector3(q[0], 0.45, D - 0.27), _colour(), q[1])
	_hatbox(Vector3(0.35, 0.45 + 0.16 * 1.1 + 0.05, D - 0.27), _colour(), 0.12)
	_hat(Vector3(1.75, 0.45 + 0.2 * 1.1 + 0.05, D - 0.27), _colour(), 0.2)
	_saffron(Vector3(2.75, 0.45, D - 0.27), 0.18)                                   # (the last box: open, the saffron in it)
	solid(Vector3(1.3, 0.3, D - 0.27), Vector3(3.4, 0.6, 0.5))
	pieces += 1                                                                    # the oval mirror by the cube shelves
	var mid := Vector3(HALF - 0.75, 1.55, z - 0.01)
	var pts := oval(0.0, 0.0, 0.34, 0.62, 20)
	for i in range(pts.size()):
		var p0 := pts[i]
		var p1 := pts[(i + 1) % pts.size()]
		tri(mid, mid + Vector3(p1.x, p1.y, 0), mid + Vector3(p0.x, p0.y, 0), "espejo", Vector3(0, 0, -1))
		bar(mid + Vector3(p0.x * 1.06, p0.y * 1.04, -0.01), mid + Vector3(p1.x * 1.06, p1.y * 1.04, -0.01), 0.035, 0.03, 0xd8b84a)

## The hidden saffron: a hat box with its lid off, leaning against it, the flower standing up out of it. The flower is
## the game's to take away (just walking by: game.gd takes it within 1.26 m); the box stays.
func _saffron(at: Vector3, r: float) -> void:
	props += 1
	drum(at, r, r, r * 1.1, 0xe8a0b0, 16)                                          # the box, open
	drum(at + Vector3(0, r * 1.1 - 0.01, 0), r - 0.012, r - 0.012, 0.012, 0xf2f0ea, 16)     # (tissue paper in it)
	_xf = Transform3D(Basis(Vector3(0, 0, 1), 1.25), at + Vector3(-r - 0.09, 0.95 * (r + 0.01) + 0.005, 0.03))     # its lid, on its edge, leaning on the box
	drum(Vector3.ZERO, r + 0.01, r + 0.01, 0.05, 0xf2f0ea, 16)
	home()
	var flower := Node3D.new()
	flower.add_child(Parts.part("cyl", 0x5f9c4a, Vector3(0, 0.22, 0), Vector3(0.025, 0.44, 0.025)))
	for k in range(5):
		flower.add_child(Parts.part("ball", 0x9b5de5, Vector3(cos(k * 1.257) * 0.09, 0.48, sin(k * 1.257) * 0.09), Vector3(0.085, 0.15, 0.085)))
	flower.add_child(Parts.part("ball", 0xe63946, Vector3(0, 0.54, 0), Vector3(0.04, 0.1, 0.04)))
	flower.position = at + Vector3(0, r * 0.4, 0)
	add_child(flower)
	saffron_spot = INSIDE + Vector2(at.x, at.z)
	var game = W.get_parent()                           # (the game: the world is its child)
	if game != null and game.get("flowers") != null:
		(game.flowers as Array).append({"node": flower, "p": saffron_spot, "id": "tetoqa", "hidden": true})      # (hidden: Sistemas keeps count of these)

## a picture on the back wall, read from inside the room (facing -z)
func _picture_back(x0: float, x1: float, y0: float, y1: float, z: float, key) -> void:
	pieces += 1
	quad(Vector3(x1, y0, z), Vector3(x0, y0, z), Vector3(x0, y1, z), Vector3(x1, y1, z), key, Vector3(0, 0, -1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

# ---------------- the middle of the room ----------------
func _middle() -> void:
	_jewellery(Vector2(0.9, 3.0))
	_glasses_tower(Vector2(1.9, 5.3))
	_round_table(Vector2(-0.7, 5.6))
	_hat_stand(Vector2(1.0, 7.3))

## a glass case of jewellery: a white foot, a glass top and sides, rings, earrings, necklaces and watches on dark velvet
func _jewellery(at: Vector2) -> void:
	props += 1
	var w := 1.5
	var dd := 0.6
	var x0 := at.x - w / 2.0
	var z0 := at.y - dd / 2.0
	box(x0, 0.0, z0, w, 0.7, dd, 0xf4f4f0)
	box(x0 + 0.03, 0.7, z0 + 0.03, w - 0.06, 0.02, dd - 0.06, 0x2a2430)            # the velvet
	for i in range(9):
		for j in range(3):
			var x := x0 + 0.12 + i * (w - 0.24) / 8.0
			var z := z0 + 0.14 + j * 0.16
			match (i + j) % 4:
				0:
					drum(Vector3(x, 0.72, z), 0.02, 0.02, 0.012, 0xd8b84a, 10)      # a ring
					ball(Vector3(x, 0.74, z + 0.01), 0.008, [0xc8384a, 0x58b8c8, 0xf2f0ea][(i + j) % 3], 1.0, 6, 4)
				1:
					for s in [-0.015, 0.015]:                                      # a pair of earrings
						ball(Vector3(x + s, 0.73, z), 0.009, 0xd8dde2 if i % 2 == 0 else 0xd8b84a, 1.0, 6, 4)
				2:
					for k in range(6):                                             # a necklace laid out
						var a0 := PI * k / 6.0
						var a1 := PI * (k + 1) / 6.0
						bar(Vector3(x + cos(a0) * 0.05, 0.722, z + sin(a0) * 0.05 - 0.03), Vector3(x + cos(a1) * 0.05, 0.722, z + sin(a1) * 0.05 - 0.03), 0.005, 0.005, 0xd8b84a)
				3:
					drum(Vector3(x, 0.72, z), 0.022, 0.022, 0.01, 0xd8dde2, 12)     # a watch
					box(x - 0.012, 0.72, z - 0.06, 0.024, 0.004, 0.12, 0x3a2a20)
	pieces += 1
	var y1 := 0.95
	for q in [[Vector3(x0, 0.72, z0), Vector3(x0 + w, 0.72, z0), Vector3(0, 0, -1)], [Vector3(x0 + w, 0.72, z0 + dd), Vector3(x0, 0.72, z0 + dd), Vector3(0, 0, 1)]]:
		var p: Vector3 = q[0]
		var e: Vector3 = q[1]
		quad(p, e, Vector3(e.x, y1, e.z), Vector3(p.x, y1, p.z), "cristal", q[2])
	quad(Vector3(x0, 0.72, z0), Vector3(x0, 0.72, z0 + dd), Vector3(x0, y1, z0 + dd), Vector3(x0, y1, z0), "cristal", Vector3(-1, 0, 0))
	quad(Vector3(x0 + w, 0.72, z0), Vector3(x0 + w, 0.72, z0 + dd), Vector3(x0 + w, y1, z0 + dd), Vector3(x0 + w, y1, z0), "cristal", Vector3(1, 0, 0))
	quad(Vector3(x0, y1, z0), Vector3(x0 + w, y1, z0), Vector3(x0 + w, y1, z0 + dd), Vector3(x0, y1, z0 + dd), "cristal", Vector3.UP)
	for c in [Vector3(x0, 0.7, z0), Vector3(x0 + w, 0.7, z0), Vector3(x0, 0.7, z0 + dd), Vector3(x0 + w, 0.7, z0 + dd)]:
		box(c.x - 0.012, c.y, c.z - 0.012, 0.024, y1 - 0.7 + 0.01, 0.024, 0xc0c4c8)
	solid(Vector3(at.x, 0.5, at.y), Vector3(w, 1.0, dd))

## a turning tower of sunglasses: a post, four faces of little shelves, a pair on each
func _glasses_tower(at: Vector2) -> void:
	props += 1
	bar(Vector3(at.x, 0.0, at.y), Vector3(at.x, 1.75, at.y), 0.05, 0.05, 0xc0c4c8)
	drum(Vector3(at.x, 0.0, at.y), 0.28, 0.28, 0.03, 0xc0c4c8, 14)
	box(at.x - 0.14, 1.75, at.y - 0.14, 0.28, 0.24, 0.28, 0xf4f4f0)              # its little sign: a pink pair of glasses on it
	for s in [-1.0, 1.0]:
		drum(Vector3(at.x + s * 0.045, 1.86, at.y - 0.142), 0.035, 0.035, 0.004, PINK, 10)
	for face_ in range(4):
		var yaw := face_ * PI / 2.0
		_put(Vector3(at.x, 0.0, at.y), yaw)
		for row in range(7):
			var y := 0.35 + row * 0.19
			box(-0.13, y, 0.1, 0.26, 0.012, 0.06, 0xd8dce0)
			var col := _colour(row + face_)
			for s in [-0.035, 0.035]:                                               # the pair: two dark lenses, a frame across
				box(s - 0.03, y + 0.02, 0.16, 0.06, 0.04, 0.008, 0x1a1a1c)
			box(-0.07, y + 0.055, 0.162, 0.14, 0.012, 0.01, col)
		home()
	solid(Vector3(at.x, 0.9, at.y), Vector3(0.5, 1.8, 0.5))

## a round table of folded scarves and hats on a white foot
func _round_table(at: Vector2) -> void:
	props += 1
	drum(Vector3(at.x, 0.0, at.y), 0.25, 0.25, 0.04, 0xf4f4f0, 16)
	bar(Vector3(at.x, 0.0, at.y), Vector3(at.x, 0.72, at.y), 0.08, 0.08, 0xf4f4f0)
	drum(Vector3(at.x, 0.72, at.y), 0.6, 0.6, 0.04, 0xf8f8f6, 20)
	for k in range(6):
		var a := TAU * k / 6.0
		var p := Vector2(at.x + cos(a) * 0.38, at.y + sin(a) * 0.38)
		if k % 2 == 0:
			_put(Vector3(p.x, 0.76, p.y), -a)
			for f in range(3):
				box(-0.12, f * 0.04, -0.1, 0.24, 0.035, 0.2, _colour(f + k))
			home()
		else:
			_hat(Vector3(p.x, 0.76, p.y), _colour(k), 0.16)
	_hatbox(Vector3(at.x, 0.76, at.y), PINK, 0.14)
	solid(Vector3(at.x, 0.4, at.y), Vector3(1.2, 0.8, 1.2))

## a hat stand: a post with arms, a hat on each
func _hat_stand(at: Vector2) -> void:
	props += 1
	drum(Vector3(at.x, 0.0, at.y), 0.22, 0.22, 0.03, 0xc0c4c8, 14)
	bar(Vector3(at.x, 0.0, at.y), Vector3(at.x, 1.8, at.y), 0.035, 0.035, 0xc0c4c8)
	for k in range(4):
		var a := TAU * k / 4.0 + 0.4
		var tip := Vector3(at.x + cos(a) * 0.28, 1.35 + 0.15 * (k % 2), at.y + sin(a) * 0.28)
		bar(Vector3(at.x, tip.y - 0.12, at.y), tip, 0.02, 0.02, 0xc0c4c8)
		_hat(tip, _colour(k), 0.16)
	_hat(Vector3(at.x, 1.8, at.y), _colour(), 0.18)
	solid(Vector3(at.x, 0.9, at.y), Vector3(0.6, 1.8, 0.6))

# ---------------- the fitting room ----------------
## In the far corner at your right: a cabin of white boards, its pink curtain pulled to the side (it is where you try
## things on: probador_spot), a long mirror, a stool, a hook.
func _fitting_room() -> void:
	var x0 := ROOM.position.x
	var x1 := ROOM.end.x
	var z0 := ROOM.position.y
	box(x1 - 0.03, 0.0, z0, 0.06, 2.3, ROOM.size.y, 0xf4f4f0)                       # its side wall
	box(x0, 2.3, z0, ROOM.size.x + 0.03, 0.05, ROOM.size.y, 0xf4f4f0)
	box(x0, 2.18, z0 - 0.03, ROOM.size.x, 0.03, 0.03, 0xb8bcc0)                     # its rail...
	pieces += 1                                                                    # ...its curtain, pulled to the wall's side
	quad(Vector3(x0, 0.15, z0 + 0.01), Vector3(x0 + 0.32, 0.15, z0 + 0.01), Vector3(x0 + 0.32, 2.17, z0 + 0.01), Vector3(x0, 2.17, z0 + 0.01), "cortina", Vector3(0, 0, -1),
		[Vector2(0, 1), Vector2(0.6, 1), Vector2(0.6, 0), Vector2(0, 0)])
	box(x0 + 0.01, 0.35, D - 1.2, 0.02, 1.7, 0.55, 0x9a8a6a)                         # the long mirror on the wall, in its frame
	box(x0 + 0.03, 0.4, D - 1.15, 0.01, 1.6, 0.45, 0x000000)
	quad(Vector3(x0 + 0.045, 0.4, D - 1.15), Vector3(x0 + 0.045, 0.4, D - 0.7), Vector3(x0 + 0.045, 2.0, D - 0.7), Vector3(x0 + 0.045, 2.0, D - 1.15), "espejo", Vector3(1, 0, 0))
	box(x1 - 0.5, 0.0, D - 0.45, 0.35, 0.45, 0.35, 0xe8a0b8)                        # its stool
	bar(Vector3(x0 + 0.02, 1.7, D - 0.3), Vector3(x0 + 0.12, 1.75, D - 0.3), 0.015, 0.015, 0x9aa0a8)      # a hook
	props += 1
	solid(Vector3(x1, 1.15, z0 + ROOM.size.y / 2.0), Vector3(0.08, 2.3, ROOM.size.y))
	var lamp_at := Vector3(ROOM.get_center().x, 2.28, ROOM.get_center().y)          # its light
	cbox(lamp_at, Vector3(0.3, 0.02, 0.3), "luz")

func _lamps() -> void:
	for z in [1.5, 3.5, 5.5, 7.5]:
		for x in [-2.0, 0.0, 2.0]:
			drum(Vector3(x, TALL - 0.02, z), 0.09, 0.09, 0.018, "luz", 12)
			drum(Vector3(x, TALL - 0.008, z), 0.11, 0.11, 0.008, 0xd8d6cc, 12)
	for at in [Vector3(0.0, 2.5, 2.2), Vector3(0.0, 2.5, 5.5), Vector3(0.0, 2.5, 8.0), Vector3(-2.5, 2.3, 4.0), Vector3(2.5, 2.3, 6.0)]:
		var lamp := OmniLight3D.new()
		lamp.position = at
		lamp.light_color = Color(1.0, 0.97, 0.92)
		lamp.omni_range = 5.0
		lamp.light_energy = 0.45
		lamp.shadow_enabled = false
		lamp.light_cull_mask = 1 << 10
		add_child(lamp)
