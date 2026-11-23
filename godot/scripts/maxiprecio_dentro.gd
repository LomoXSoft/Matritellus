extends "res://scripts/obra.gd"
## The inside of the clothes and home-textile shop "MaxiPrecio" of the Calle de los Arcos (maxiprecio.gd builds its
## front). The user, 23 November 2026: "Necesitará tener un interior (hay fotos en maps)". A set built far out in the
## fields, like the roast chicken shop's (asador_dentro.gd), walked into by the green arrow before its steps (entradas.gd).
##
## FIRST DRAFT, before the user's pictures of the real inside (Google Maps shows them only signed in): a big room of a
## "hipertextil" as the town's are -- white walls with the shop's blue stripes along their top, a floor of pale
## terrazzo, rows of strip lights. Along both walls tall shelves of what it sells folded in piles (towels, sheets,
## blankets, tablecloths); bedspreads hung on the back wall each side of the badge; in the middle rails of clothes,
## a round one, two tables of piles, a low island of bins (socks, underwear); the counter with the till at your right as
## you come in; two fitting rooms behind blue curtains in the far corner. Boards hanging from the ceiling say where
## each thing is. Nobody is modelled (no mannequins either: the user decides figures). A saffron flower is hidden in
## the far bin of the island, among the socks (the user, 23 Nov 2026, to "en una de las cestas de la isla del centro":
## "Ponlo también").
##
## What a place you go into has to give (game.gd _use_door): `door_out`, `out_spawn`, `out_h` on the street; `in_door`
## and `in_spawn` in the set; `open` (the shop's hours: maxiprecio.gd set_open keeps it). For Sistemas, if somebody
## serves here (Maxi, maxi.gd): `clerk_spot` and `clerk_h` (behind the counter, looking at the room), `client_spot` and
## `client_h` (before it), `probador_spot` and `probador_h` (in the first fitting room, looking out at the room). The room: 9 m wide, 12 deep; +z deeper in, the door at z = 0; looking in, +x is on your left.

const INSIDE := Vector2(2150.0, -600.0)         # where the set is: no street within 320 m, no tree of the map within
                                                # 500 m, no field, the other sets 780 m off or more (the silo's nearest)
const HALF := 4.5                               # half its width
const D := 12.0                                 # how deep it is
const TALL := 3.2
const DIR := "res://assets/maxiprecio/"
const COUNTER := Rect2(-3.6, 1.4, 1.0, 2.3)     # the counter: from x, from z, how wide (x), how long (z)
const SHELF_D := 0.45                           # how deep the wall shelves are
const COLOURS := [0xc8384a, 0x2f5fa8, 0xe8d8b0, 0x6a9a5a, 0xe8a0b0, 0xf2f0ea, 0x3a3a44, 0xd8a040, 0x7a5aa0, 0x58b8c8, 0xf0c8a0, 0x9a2a3a]

var door_out: Vector2
var out_spawn: Vector2
var out_h := 0.0
var in_door: Vector2
var in_spawn: Vector2
var open := false               # the shop's hours (maxiprecio.gd)
var clerk_spot: Vector2         # behind the counter...
var clerk_h := 0.0              # ...looking at the door
var client_spot: Vector2        # before it
var client_h := 0.0
var probador_spot: Vector2      # in the first fitting room...
var probador_h := PI            # ...looking out of it
var props := 0
var saffron_spot: Vector2       # the hidden saffron (in the game's flowers, "id": "maxiprecio")
var _n := 0                     # (for the colours: the same every time)

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: StandardMaterial3D = null
	match (String(key) if key is String else ""):
		"suelo":            # pale terrazzo in tiles of forty centimetres
			var img := Image.create(8, 8, false, Image.FORMAT_RGB8)
			for y in range(8):
				for x in range(8):
					var c := Color(0.86, 0.85, 0.82) if ((x / 4) + (y / 4)) % 2 == 0 else Color(0.82, 0.81, 0.78)
					if (x * 7 + y * 3) % 11 == 0:
						c = c.darkened(0.12)
					if x % 4 == 0 or y % 4 == 0:
						c = Color(0.74, 0.73, 0.7)
					img.set_pixel(x, y, c)
			m = StandardMaterial3D.new()
			m.albedo_texture = ImageTexture.create_from_image(img)
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE / 0.8
			m.roughness = 0.35
			m.emission_enabled = true
			m.emission = Color(0.85, 0.84, 0.8)
			m.emission_energy_multiplier = 0.2
		"pared":
			m = _lit(Color(0.97, 0.97, 0.95), 0.3)
		"techo":
			m = _lit(Color(0.95, 0.95, 0.93), 0.32)
		"calle":            # the street's light at the door and the windows
			m = _lit(Color(0.88, 0.94, 1.0), 1.4)
		"luz":
			m = _lit(Color(1.0, 0.99, 0.95), 1.8)
		"cortina":          # the fitting rooms' curtains: blue, in folds
			var cimg := Image.create(32, 4, false, Image.FORMAT_RGB8)
			for x in range(32):
				for y in range(4):
					cimg.set_pixel(x, y, Color(0.16, 0.32, 0.66) * (0.82 + 0.18 * sin(x / 32.0 * TAU * 4.0)))
			m = StandardMaterial3D.new()
			m.albedo_texture = ImageTexture.create_from_image(cimg)
			m.roughness = 1.0
			m.emission_enabled = true
			m.emission_texture = m.albedo_texture
			m.emission = Color.WHITE
			m.emission_energy_multiplier = 0.3
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"rayas", "mural", "horario":
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
	in_spawn = INSIDE + Vector2(0.0, 1.5)
	clerk_spot = INSIDE + Vector2(COUNTER.position.x - 0.32, COUNTER.position.y + COUNTER.size.y / 2.0)
	clerk_h = PI / 2.0                              # (looking across the counter, at the room: +x)
	client_spot = INSIDE + Vector2(COUNTER.end.x + 0.6, COUNTER.position.y + COUNTER.size.y / 2.0)
	client_h = -PI / 2.0
	probador_spot = INSIDE + Vector2(HALF - 1.8, D - 0.95)
	_shell()
	_wall_shelves()
	_back_wall()
	_counter()
	_middle()
	_fitting_rooms()
	_boards()
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

## a pile of folded things on a shelf at y, its foot's middle at (x, z) of the frame being built: `w` wide, `d` deep
func _pile(x: float, y: float, z: float, w: float, d: float, high: float) -> void:
	var c := _colour()
	var at := y
	var k := 0
	while at < y + high - 0.05:
		var t := 0.055 + 0.03 * ((k + _n) % 3)
		var cc: int = c if (k + _n) % 4 != 3 else _colour(k)
		box(x - w / 2.0 + 0.01 * (k % 2), at, z - d / 2.0, w - 0.02, t - 0.006, d, cc)
		at += t
		k += 1

# ---------------- the room ----------------
func _shell() -> void:
	quad(Vector3(-HALF, 0, 0), Vector3(HALF, 0, 0), Vector3(HALF, 0, D), Vector3(-HALF, 0, D), "suelo", Vector3.UP)
	quad(Vector3(-HALF, TALL, 0), Vector3(HALF, TALL, 0), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "techo", Vector3.DOWN)
	for sx in [-1.0, 1.0]:
		var x: float = sx * HALF
		quad(Vector3(x, 0, 0), Vector3(x, 0, D), Vector3(x, TALL, D), Vector3(x, TALL, 0), "pared", Vector3(-sx, 0, 0))
		box(x - (0.01 if sx > 0.0 else 0.0), 0.0, 0.0, 0.01, 0.1, D, 0x9aa0a8)                                      # (the skirting)
		var uv0 := Vector2(0.0, 0.0)
		var y0 := 2.62
		var y1 := 2.98
		var off: float = -sx * 0.012
		pieces += 1                                                                                                 # the shop's stripes along the top of the walls
		quad(Vector3(x + off, y0, 0), Vector3(x + off, y0, D), Vector3(x + off, y1, D), Vector3(x + off, y1, 0), "rayas", Vector3(-sx, 0, 0),
			[uv0, Vector2(D / 0.45, 0.0), Vector2(D / 0.45, -(y1 - y0) / 0.9), Vector2(0.0, -(y1 - y0) / 0.9)])      # (the stripes at half their size outside)
	quad(Vector3(-HALF, 0, D), Vector3(HALF, 0, D), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "pared", Vector3(0, 0, -1))
	box(-HALF, 0.0, D - 0.01, 2.0 * HALF, 0.1, 0.01, 0x9aa0a8)
	# the front from inside: the glass door in the middle, open while you are here, a window at each side, the street
	# bright beyond them
	var door := [-0.6, 0.6]
	var top := 2.5
	var panes := [[1.1, 4.0], [-4.0, -1.1]]
	var cuts: Array = [[-HALF, -4.0, 0.0, TALL], [-1.1, door[0], 0.0, TALL], [door[1], 1.1, 0.0, TALL], [4.0, HALF, 0.0, TALL], [door[0], door[1], top, TALL],
		[-4.0, -1.1, 0.0, 0.62], [1.1, 4.0, 0.0, 0.62], [-4.0, -1.1, 2.6, TALL], [1.1, 4.0, 2.6, TALL]]
	for q in cuts:
		quad(Vector3(q[0], q[2], 0), Vector3(q[1], q[2], 0), Vector3(q[1], q[3], 0), Vector3(q[0], q[3], 0), "pared", Vector3(0, 0, 1))
	quad(Vector3(door[0], 0, -0.15), Vector3(door[1], 0, -0.15), Vector3(door[1], top, -0.15), Vector3(door[0], top, -0.15), "calle", Vector3(0, 0, 1))
	for p in panes:
		quad(Vector3(p[0], 0.62, -0.15), Vector3(p[1], 0.62, -0.15), Vector3(p[1], 2.6, -0.15), Vector3(p[0], 2.6, -0.15), "calle", Vector3(0, 0, 1))
		for x in [p[0], (p[0] + p[1]) / 2.0 - 0.03, p[1] - 0.06]:
			box(x, 0.62, -0.08, 0.06, 1.98, 0.1, 0xdcdcd8)
		box(p[0], 0.56, -0.08, p[1] - p[0], 0.08, 0.16, 0xdcdcd8)
		box(p[0], 2.56, -0.08, p[1] - p[0], 0.06, 0.1, 0xdcdcd8)
	for x in [door[0] - 0.07, door[1]]:
		box(x, 0.0, -0.08, 0.07, top, 0.1, 0xdcdcd8)
	box(door[0] - 0.07, top, -0.08, door[1] - door[0] + 0.14, 0.07, 0.1, 0xdcdcd8)
	box(door[0] - 0.2, 0.0, 0.2, door[1] - door[0] + 0.4, 0.014, 0.9, 0x2a3a5a)                                   # the mat
	quad(Vector3(0.75, 1.35, 0.012), Vector3(1.05, 1.35, 0.012), Vector3(1.05, 1.75, 0.012), Vector3(0.75, 1.75, 0.012), "horario", Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])                                              # (its hours, seen from inside: on the wall by the door)
	solid(Vector3(0, TALL / 2.0, -0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	solid(Vector3(0, TALL / 2.0, D + 0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	for sx in [-1.0, 1.0]:
		solid(Vector3(sx * (HALF + 0.2), TALL / 2.0, D / 2.0), Vector3(0.4, TALL, D + 0.8))
	solid(Vector3(0, TALL + 0.1, D / 2.0), Vector3(2.0 * HALF + 0.8, 0.2, D + 0.8))

# ---------------- the shelves along the walls ----------------
## Along both walls, from the counter (or the door) to the fitting rooms: tall white shelves in bays of 1.2 m, five
## shelves of folded piles each.
func _wall_shelves() -> void:
	for sx in [-1.0, 1.0]:
		var z0: float = (COUNTER.end.y + 0.6) if sx < 0.0 else 1.2
		var z1: float = D - 0.3 if sx < 0.0 else D - 2.6
		var bays := int((z1 - z0) / 1.2)
		for i in range(bays):
			var zb: float = z0 + i * 1.2
			_shelf_bay(sx, zb)
		solid(Vector3(sx * (HALF - SHELF_D / 2.0), 1.2, (z0 + z0 + bays * 1.2) / 2.0), Vector3(SHELF_D, 2.4, bays * 1.2))

func _shelf_bay(sx: float, zb: float) -> void:
	var x_wall: float = sx * HALF
	var x_in: float = sx * (HALF - SHELF_D)
	var xm := (x_wall + x_in) / 2.0
	props += 1
	for z in [zb, zb + 1.17]:                                                     # its sides
		box(minf(x_wall, x_in), 0.0, z, SHELF_D, 2.4, 0.03, 0xf2f2ee)
	box(minf(x_wall, x_in), 0.0, zb, SHELF_D, 0.12, 1.2, 0xd8d8d4)              # its foot
	for k in range(5):
		var y := 0.12 + k * 0.46
		box(minf(x_wall, x_in), y, zb + 0.03, SHELF_D, 0.025, 1.14, 0xf2f2ee)
		if k < 4 or zb > 4.0:                                                     # (the top shelf of the first bays bare)
			for j in range(3):
				_pile(xm - sx * 0.02, y + 0.025, zb + 0.22 + j * 0.37, 0.32 if j != 1 else 0.36, SHELF_D - 0.08, 0.3 + 0.06 * ((j + k) % 3))
	box(minf(x_wall, x_in), 2.37, zb, SHELF_D, 0.03, 1.2, 0xf2f2ee)

# ---------------- the back wall: the bedspreads, the badge ----------------
func _back_wall() -> void:
	var z := D - 0.04
	_picture_back(-1.1, 1.1, 1.05, 3.08, z - 0.01, "mural")
	for x in [-3.9, -2.75, 1.65, 2.8]:                                            # bedspreads hung from a rail, folds and all
		var c := _colour()
		var w := 1.0
		for k in range(5):
			box(x + k * w / 5.0, 0.35, z - 0.06 - 0.03 * (k % 2), w / 5.0, 2.15, 0.02, c if k % 2 == 0 else _darker(c))
		box(x - 0.05, 2.5, z - 0.12, w + 0.1, 0.03, 0.12, 0x9aa0a8)
		props += 1
	box(-4.2, 2.52, z - 0.1, 8.4, 0.03, 0.03, 0x9aa0a8)

func _darker(hex: int) -> int:
	var c := Color.hex((hex << 8) | 0xff).darkened(0.15)
	return (c.r8 << 16) | (c.g8 << 8) | c.b8

## a picture on the back wall, read from inside the room (facing -z)
func _picture_back(x0: float, x1: float, y0: float, y1: float, z: float, key) -> void:
	pieces += 1
	quad(Vector3(x1, y0, z), Vector3(x0, y0, z), Vector3(x0, y1, z), Vector3(x1, y1, z), key, Vector3(0, 0, -1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

# ---------------- the counter ----------------
## At your right as you come in: a counter of pale wood with a white top, the till, the card machine, a roll of bags,
## a stand of socks on it; behind it a shelf of bags and boxes.
func _counter() -> void:
	var x0 := COUNTER.position.x
	var x1 := COUNTER.end.x
	var z0 := COUNTER.position.y
	var z1 := COUNTER.end.y
	box(x0, 0.0, z0, x1 - x0, 0.95, z1 - z0, 0xc8a878)
	box(x0 - 0.03, 0.95, z0 - 0.03, x1 - x0 + 0.06, 0.04, z1 - z0 + 0.06, 0xf2f2ee)
	box(x1 - 0.01, 0.15, z0 + 0.1, 0.012, 0.6, z1 - z0 - 0.2, 0x2a5ab0)                                         # its blue front
	_put(Vector3(x0 + 0.35, 0.99, z0 + 0.9), PI / 2.0)                              # the till: its drawer, its screen towards you
	box(-0.22, 0.0, -0.2, 0.44, 0.1, 0.4, 0x2a2a2e)
	box(-0.2, 0.1, -0.12, 0.4, 0.06, 0.24, 0x3a3a3e)
	bar(Vector3(0, 0.16, 0.05), Vector3(0, 0.42, 0.12), 0.04, 0.04, 0x2a2a2e)
	box(-0.17, 0.38, 0.1, 0.34, 0.24, 0.03, 0x1a1a1c)
	box(-0.15, 0.4, 0.13, 0.3, 0.2, 0.002, 0x4a7ab0)
	home()
	box(x0 + 0.55, 0.99, z0 + 1.45, 0.08, 0.04, 0.16, 0x2a2a2e)                     # the card machine
	box(x0 + 0.56, 1.03, z0 + 1.47, 0.06, 0.012, 0.08, 0x4a7ab0)
	drum(Vector3(x0 + 0.3, 0.99, z0 + 1.9), 0.09, 0.09, 0.3, 0xf2f0ea, 10)       # a roll of bags
	box(x0 + 0.62, 0.99, z0 + 0.25, 0.25, 0.45, 0.25, 0x9aa0a8)                    # a stand of socks
	for k in range(6):
		box(x0 + 0.6 + (k % 2) * 0.15, 1.05 + (k / 2) * 0.13, z0 + 0.22, 0.1, 0.1, 0.02, _colour())
	# behind it, against the wall: a low shelf of bags, boxes, rolls of wrapping
	box(-HALF, 0.0, z0, 0.3, 1.1, z1 - z0, 0xf2f2ee)
	for k in range(4):
		box(-HALF + 0.03, 1.1, z0 + 0.15 + k * 0.5, 0.24, 0.25 + 0.08 * (k % 2), 0.35, [0xc8a070, 0xf2f0ea, 0x2a5ab0, 0xd8c8a8][k])
	props += 4
	solid(Vector3(COUNTER.get_center().x, 0.5, COUNTER.get_center().y), Vector3(COUNTER.size.x, 1.0, COUNTER.size.y))
	solid(Vector3(-HALF + 0.15, 0.55, COUNTER.get_center().y), Vector3(0.3, 1.1, COUNTER.size.y))
	for z in [z0 - 0.05, z1 + 0.05]:                                               # (nobody goes behind it but who serves)
		solid(Vector3((-HALF + x0) / 2.0, 0.5, z), Vector3(x0 + HALF, 1.0, 0.1))
	box(-HALF, 0.0, z0 - 0.08, x0 + HALF, 0.9, 0.05, 0xc8a878)                    # (a low flap at its front end)

# ---------------- the middle of the room ----------------
func _middle() -> void:
	# two rails of clothes each side of the walk to the back
	for q in [[1.4, 4.2], [1.4, 7.0], [-1.4, 5.0], [-1.4, 7.8]]:
		_rail(Vector2(q[0], q[1]))
	_round_rack(Vector2(-2.5, 10.3))
	for q in [[-2.6, 6.2], [2.4, 2.3]]:
		_table(Vector2(q[0], q[1]))
	_island(Vector2(0.0, 9.6))

## a rail of clothes on hangers, 1.6 m long along z, on its two feet
func _rail(at: Vector2) -> void:
	props += 1
	var z0 := at.y - 0.8
	var z1 := at.y + 0.8
	for z in [z0, z1]:
		bar(Vector3(at.x, 0.03, z), Vector3(at.x, 1.6, z), 0.035, 0.035, 0xb8bcc0)
		bar(Vector3(at.x - 0.28, 0.03, z), Vector3(at.x + 0.28, 0.03, z), 0.04, 0.03, 0xb8bcc0)
	bar(Vector3(at.x, 1.58, z0), Vector3(at.x, 1.58, z1), 0.03, 0.03, 0xb8bcc0)
	var z := z0 + 0.06
	var c := _colour()
	var k := 0
	while z < z1 - 0.05:
		if k % 5 == 0:
			c = _colour(k)
		var long := 0.7 + 0.25 * ((k / 5) % 2)
		box(at.x - 0.22, 1.5 - long, z - 0.015, 0.44, long, 0.03, c)
		bar(Vector3(at.x - 0.2, 1.52, z), Vector3(at.x + 0.2, 1.52, z), 0.012, 0.012, 0x4a3a2a)
		z += 0.065
		k += 1
	solid(Vector3(at.x, 0.8, at.y), Vector3(0.6, 1.6, 1.7))

## a round rack: a ring of clothes about a post
func _round_rack(at: Vector2) -> void:
	props += 1
	bar(Vector3(at.x, 0.0, at.y), Vector3(at.x, 1.45, at.y), 0.05, 0.05, 0xb8bcc0)
	drum(Vector3(at.x, 0.0, at.y), 0.35, 0.35, 0.03, 0xb8bcc0, 12)
	var n := 22
	for i in range(n):
		var a := TAU * i / n
		var p := Vector2(at.x + cos(a) * 0.5, at.y + sin(a) * 0.5)
		_put(Vector3(p.x, 0.0, p.y), -a)
		box(-0.015, 0.7, -0.2, 0.03, 0.72, 0.4, _colour())
		home()
	solid(Vector3(at.x, 0.8, at.y), Vector3(1.3, 1.6, 1.3))

## a table of piles of folded things (jumpers, pyjamas)
func _table(at: Vector2) -> void:
	props += 1
	box(at.x - 0.6, 0.0, at.y - 0.45, 1.2, 0.72, 0.9, 0xc8a878)
	box(at.x - 0.62, 0.72, at.y - 0.47, 1.24, 0.03, 0.94, 0xf2f2ee)
	for i in range(3):
		for j in range(2):
			_pile(at.x - 0.38 + i * 0.38, 0.75, at.y - 0.2 + j * 0.4, 0.32, 0.34, 0.18 + 0.06 * ((i + j) % 3))
	solid(Vector3(at.x, 0.4, at.y), Vector3(1.24, 0.8, 0.94))

## a low island of bins (socks, underwear in their packets)
func _island(at: Vector2) -> void:
	props += 1
	box(at.x - 0.9, 0.0, at.y - 0.5, 1.8, 0.7, 1.0, 0xf2f2ee)
	for i in range(3):
		for j in range(2):
			var x := at.x - 0.85 + i * 0.6
			var z := at.y - 0.45 + j * 0.5
			box(x, 0.7, z, 0.56, 0.12, 0.46, 0x2a5ab0)
			var hid := i == 2 and j == 1                        # (the far bin at your left: the saffron among its socks)
			for k in range(8):
				if hid and (k == 1 or k == 2):
					continue
				box(x + 0.04 + (k % 4) * 0.13, 0.74 + 0.02 * (k % 3), z + 0.05 + (k / 4) * 0.2, 0.11, 0.06, 0.16, _colour())
			if hid:
				_saffron(Vector3(x + 0.24, 0.74, z + 0.13))
	solid(Vector3(at.x, 0.45, at.y), Vector3(1.8, 0.9, 1.0))

## The hidden saffron, standing up among the packets of socks of a bin. The flower is the game's to take away (just
## walking by: game.gd takes it within 1.26 m).
func _saffron(at: Vector3) -> void:
	props += 1
	var flower := Node3D.new()
	flower.add_child(Parts.part("cyl", 0x5f9c4a, Vector3(0, 0.15, 0), Vector3(0.025, 0.3, 0.025)))
	for k in range(5):
		flower.add_child(Parts.part("ball", 0x9b5de5, Vector3(cos(k * 1.257) * 0.09, 0.34, sin(k * 1.257) * 0.09), Vector3(0.085, 0.15, 0.085)))
	flower.add_child(Parts.part("ball", 0xe63946, Vector3(0, 0.4, 0), Vector3(0.04, 0.1, 0.04)))
	flower.position = at
	add_child(flower)
	saffron_spot = INSIDE + Vector2(at.x, at.z)
	var game = W.get_parent()                           # (the game: the world is its child)
	if game != null and game.get("flowers") != null:
		(game.flowers as Array).append({"node": flower, "p": saffron_spot, "id": "maxiprecio", "hidden": true})      # (hidden: Sistemas keeps count of these)

# ---------------- the fitting rooms ----------------
## Two cabins in the far corner at your left (+x), a mirror and a stool in each: the first one's blue curtain pulled
## to the side (it is where you try things on: probador_spot), the second's drawn.
func _fitting_rooms() -> void:
	var x0 := HALF - 2.4
	var z0 := D - 2.0
	for k in range(3):
		box(x0 + k * 1.2 - 0.03, 0.0, z0, 0.06, 2.3, 2.0, 0xf2f2ee)
	box(x0 - 0.03, 2.3, z0, 2.43, 0.05, 2.0, 0xf2f2ee)
	for k in range(2):
		var x := x0 + k * 1.2 + 0.03
		box(x, 2.18, z0 - 0.03, 1.14, 0.03, 0.03, 0xb8bcc0)                       # its rail
		pieces += 1
		var drawn := 0.22 if k == 0 else 1.0
		quad(Vector3(x, 0.15, z0 + 0.01), Vector3(x + 1.14 * drawn, 0.15, z0 + 0.01), Vector3(x + 1.14 * drawn, 2.17, z0 + 0.01), Vector3(x, 2.17, z0 + 0.01), "cortina", Vector3(0, 0, -1),
			[Vector2(0, 1), Vector2(drawn * 2.0, 1), Vector2(drawn * 2.0, 0), Vector2(0, 0)])
		box(x + 0.35, 0.6, D - 0.03, 0.45, 1.3, 0.02, 0xa8c0c8)                   # its mirror
		box(x + 0.4, 0.0, D - 0.6, 0.32, 0.45, 0.32, 0x8a6a4a)                    # its stool
		props += 1
	for k in range(3):                                                            # (the walls between them: the first one you can step into)
		solid(Vector3(x0 + k * 1.2, 1.15, z0 + 1.0), Vector3(0.08, 2.3, 2.0))
	solid(Vector3(x0 + 1.8, 1.15, z0 + 0.03), Vector3(1.2, 2.3, 0.08))

# ---------------- the boards hung from the ceiling ----------------
func _boards() -> void:
	for q in [["TOALLAS", Vector3(3.6, 2.55, 3.2), -PI / 2.0], ["ROPA DE CAMA", Vector3(-3.6, 2.55, 6.5), PI / 2.0], ["MODA", Vector3(0.0, 2.55, 5.8), 0.0],
			["PROBADORES", Vector3(HALF - 1.2, 2.55, D - 2.25), 0.0], ["CAJA", Vector3(-3.1, 2.55, 2.55), 0.0]]:
		_put(q[1], q[2])
		box(-0.65, -0.14, -0.015, 1.3, 0.32, 0.03, 0x2a5ab0)
		box(-0.67, -0.16, -0.012, 1.34, 0.025, 0.024, 0xf2f2ee)
		box(-0.67, 0.155, -0.012, 1.34, 0.025, 0.024, 0xf2f2ee)
		for x in [-0.5, 0.5]:
			bar(Vector3(x, 0.18, 0), Vector3(x, TALL - q[1].y, 0), 0.01, 0.01, 0x9aa0a8)
		for side in [1.0, -1.0]:
			var l := _text(q[0], Vector3(0, 0.02, -0.02 * side), 64, 0xffffff, 0.0026)
			l.double_sided = false
			if side > 0.0:
				l.rotate_object_local(Vector3.UP, PI)
		home()

func _lamps() -> void:
	for z in [2.0, 5.0, 8.0, 10.8]:
		for x in [-2.6, 0.0, 2.6]:
			cbox(Vector3(x, TALL - 0.03, z), Vector3(1.25, 0.04, 0.18), "luz")
			cbox(Vector3(x, TALL - 0.008, z), Vector3(1.35, 0.016, 0.26), 0xd9d6cc)
	for at in [Vector3(0.0, 2.6, 2.5), Vector3(0.0, 2.6, 6.5), Vector3(0.0, 2.6, 10.0), Vector3(-3.0, 2.4, 4.0), Vector3(3.0, 2.4, 8.0)]:
		var lamp := OmniLight3D.new()
		lamp.position = at
		lamp.light_color = Color(1.0, 0.98, 0.92)
		lamp.omni_range = 6.0
		lamp.light_energy = 0.45
		lamp.shadow_enabled = false
		lamp.light_cull_mask = 1 << 10
		add_child(lamp)
