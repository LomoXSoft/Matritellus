extends "res://scripts/obra.gd"
## The inside of the Noche, the little supermarket of the Calle del Teniente Infante (noche.gd builds its front): a set
## built far out in the fields, like the Papelería Rocas's (rocas.gd). The user, 17 November 2026: "Haz que se pueda
## pasar y haz un interior genérico de momento" -- so for now it is any small supermarket: the till by the door, the
## fruit, three runs of shelves, the cold cabinets down one wall, drinks down the other, the dairy across the back
## under the shop's name and its moon.
##
## What a place you go into has to give (game.gd _use_door): `door_out` and `out_spawn`, `out_h` on the street;
## `in_door` and `in_spawn` in the set; `open`. Here `open` is the shop's hours (noche.gd set_open keeps it).
## The room: 10 m wide, 16 deep; +z goes deeper in, the street door is at z = 0, y = 0 is its floor.

const INSIDE := Vector2(1800.0, 1800.0)        # where the set is (no street within 260 m; V.I.P.'s at (1800, -1350), the Recress's at (-1500, -1650), the Rocas's at (-1800, -1800), your house's at (-1800, -1450), the bull's at (669, 1980))
const HALF := 5.0                               # half its width
const D := 16.0                                 # how deep it is
const TALL := 3.2
const DIR := "res://assets/noche/"
const RED := 0xd6202a
const LIME := 0xb2ce34
const TINTS: Array = [0xd8243a, 0xf2c230, 0x2c7a3a, 0x2a5fb0, 0xf4f2ec, 0xe2702a, 0x8a3a8a, 0x6a4a2a, 0x2a8ab0, 0xb2ce34, 0x1f3a6a, 0xe85aa8]

var door_out: Vector2           # its door on the street
var out_spawn: Vector2          # where you stand when you come out
var out_h := 0.0
var in_door: Vector2            # the same door seen from inside
var in_spawn: Vector2
var open := false               # the shop's hours (noche.gd)
var counter_front: Vector2      # where a customer stands at the till
var keeper_spot: Vector2        # where whoever keeps it would
var _name := ""
var _rng := RandomNumberGenerator.new()

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: StandardMaterial3D = null
	match (String(key) if key is String else ""):
		"pared":
			m = _lit(Color(0.95, 0.95, 0.93), 0.3)
		"techo":
			m = _lit(Color(0.97, 0.97, 0.96), 0.34)
		"suelo":            # pale tiles
			var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
			img.set_pixel(0, 0, Parts.col(0xdedcd6)); img.set_pixel(1, 1, Parts.col(0xdedcd6))
			img.set_pixel(1, 0, Parts.col(0xcfccc4)); img.set_pixel(0, 1, Parts.col(0xcfccc4))
			m = StandardMaterial3D.new()
			m.albedo_texture = ImageTexture.create_from_image(img)
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE / 1.2
			m.roughness = 0.8
		"calle":            # the street, seen through the glass doors from inside: all light
			m = _lit(Color(0.86, 0.93, 1.0), 1.5)
		"luz":
			m = _lit(Color(1.0, 0.98, 0.92), 2.2)
		"frio":             # the inside of the cold cabinets, lit
			m = _lit(Color(0.9, 0.96, 1.0), 0.9)
		"logo":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(DIR + "logo.png")
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

## its name; then its door on the street, where you come out to and which way you face there
func build(world, shown: String, at: Vector2, out: Vector2, heading: float) -> void:
	W = world
	_name = shown
	door_out = at
	out_spawn = out
	out_h = heading
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
	in_spawn = INSIDE + Vector2(0.0, 2.2)
	counter_front = INSIDE + Vector2(-2.9, 2.6)
	keeper_spot = INSIDE + Vector2(-4.2, 2.6)
	_rng.seed = 1117
	_shell()
	_till()
	_fruit()
	_runs()
	_cold()
	_drinks()
	_back()
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

## words on a wall: `turn` 0 faces +z (read from deeper in), PI faces the door
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

## a shelf's worth of goods: packets side by side from `from`, `run` metres along `along`, standing `deep` across
func _goods(from: Vector3, along: Vector3, run: float, deep: float, clear: float) -> void:
	var across := Vector3(-along.z, 0, along.x)
	var s := 0.0
	var c := _tint()
	var kind := _rng.randi() % 3
	while s < run - 0.05:
		var w := _rng.randf_range(0.07, 0.16) if kind != 2 else 0.09
		if _rng.randf() < 0.18:                          # (the next product along: another colour, another shape)
			c = _tint()
			kind = _rng.randi() % 3
		if _rng.randf() < 0.05:                          # (a gap: sold)
			s += w
			continue
		var h := clear * (_rng.randf_range(0.5, 0.85) if kind == 0 else (_rng.randf_range(0.3, 0.5) if kind == 1 else 0.75))
		var a := from + along * s
		var b := a + along * minf(w, run - s) + across * deep
		if kind == 2:                                    # bottles and jars: round
			drum(a + along * w / 2.0 + across * deep / 2.0, w * 0.45, w * 0.3, h, c, 8)
		else:
			box(minf(a.x, b.x), from.y, minf(a.z, b.z), absf(b.x - a.x) - 0.004, h, absf(b.z - a.z), c)
		s += w + 0.006

# ---------------- the room ----------------
func _shell() -> void:
	quad(Vector3(-HALF, 0, 0), Vector3(HALF, 0, 0), Vector3(HALF, 0, D), Vector3(-HALF, 0, D), "suelo", Vector3.UP)
	quad(Vector3(-HALF, TALL, 0), Vector3(HALF, TALL, 0), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "techo", Vector3.DOWN)
	quad(Vector3(-HALF, 0, D), Vector3(HALF, 0, D), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "pared", Vector3(0, 0, -1))
	quad(Vector3(-HALF, 0, 0), Vector3(-HALF, 0, D), Vector3(-HALF, TALL, D), Vector3(-HALF, TALL, 0), "pared", Vector3(1, 0, 0))
	quad(Vector3(HALF, 0, 0), Vector3(HALF, 0, D), Vector3(HALF, TALL, D), Vector3(HALF, TALL, 0), "pared", Vector3(-1, 0, 0))
	# the wall of the door: the glass doors, bright with the street, between panels of lime (as outside)
	var dw := 1.0
	for q in [[-HALF, -dw, 0.0, TALL], [dw, HALF, 0.0, TALL], [-dw, dw, 2.6, TALL]]:
		quad(Vector3(q[0], q[2], 0), Vector3(q[1], q[2], 0), Vector3(q[1], q[3], 0), Vector3(q[0], q[3], 0), "pared", Vector3(0, 0, 1))
	quad(Vector3(-dw, 0, -0.1), Vector3(dw, 0, -0.1), Vector3(dw, 2.6, -0.1), Vector3(-dw, 2.6, -0.1), "calle", Vector3(0, 0, 1))
	for x in [-dw - 0.35, dw]:
		box(x, 0.0, 0.0, 0.35, 2.6, 0.04, LIME)
	for x in [-dw, -0.03, dw - 0.06]:
		box(x, 0.0, -0.06, 0.06, 2.6, 0.06, 0x3b3e42)
	box(-dw, 2.55, -0.06, 2.0 * dw, 0.08, 0.08, 0x3b3e42)
	box(-0.9, 0.0, 0.25, 1.8, 0.012, 1.0, 0x5a5c5e)                                    # the mat at the door
	box(-HALF, 2.4, 0.02, 2.0 * HALF, 0.25, 0.02, RED)                                   # a red band along the walls, high up
	box(-HALF + 0.02, 2.4, 0.0, 0.02, 0.25, D, RED)
	box(HALF - 0.04, 2.4, 0.0, 0.02, 0.25, D, RED)
	# what stops you: the four walls and the ceiling
	solid(Vector3(0, TALL / 2.0, -0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	solid(Vector3(0, TALL / 2.0, D + 0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	for sx in [-1.0, 1.0]:
		solid(Vector3(sx * (HALF + 0.2), TALL / 2.0, D / 2.0), Vector3(0.4, TALL, D + 0.8))
	solid(Vector3(0, TALL + 0.1, D / 2.0), Vector3(2.0 * HALF + 0.8, 0.2, D + 0.8))

## the till on the left of the door: the counter with its belt, the screen, the bags; the baskets stacked by it
func _till() -> void:
	var x0 := -3.7
	box(x0, 0.0, 1.4, 0.9, 0.88, 2.6, 0x3d4045)
	box(x0 + 0.05, 0.88, 1.5, 0.8, 0.02, 1.8, 0x161616)                                  # the belt
	box(x0 + 0.05, 0.89, 3.35, 0.8, 0.02, 0.6, 0xc9ccd0)
	box(x0 - 0.05, 0.88, 3.0, 0.08, 0.35, 0.4, 0x2a2a2c)                                 # the screen, turned to the till's chair
	box(x0 - 0.04, 0.95, 3.04, 0.01, 0.25, 0.32, 0x2a6a3a)
	box(x0 + 0.1, 0.9, 3.4, 0.35, 0.12, 0.3, 0x2a2a2c)                                    # the till itself
	drum(Vector3(x0 + 0.45, 0.9, 1.6), 0.03, 0.03, 1.2, 0x9a9da0, 6)                     # its number on a post
	box(x0 + 0.3, 2.1, 1.58, 0.3, 0.3, 0.04, RED)
	_words("1", Vector3(x0 + 0.45, 2.25, 1.555), PI, 64, 0xfdfcf8, 0.004)
	for i in range(6):                                   # bags hanging at its end
		box(x0 + 0.1 + i * 0.12, 0.6, 4.02, 0.1, 0.25, 0.02, 0xf2f0ea)
	_prop_chair(Vector3(-4.5, 0.0, 3.0))
	for i in range(8):                                   # a stack of red baskets
		box(1.4, i * 0.09, 0.7, 0.55, 0.12, 0.38, RED)
	solid(Vector3(x0 + 0.45, 0.45, 2.7), Vector3(0.9, 0.9, 2.6))

func _prop_chair(at: Vector3) -> void:
	drum(at, 0.25, 0.04, 0.05, 0x2a2a2c, 8)
	drum(at + Vector3(0, 0.05, 0), 0.03, 0.03, 0.45, 0x8a8d90, 6)
	box(at.x - 0.22, 0.5, at.z - 0.22, 0.44, 0.08, 0.44, 0x2a2a2c)
	box(at.x - 0.22, 0.5, at.z + 0.18, 0.44, 0.5, 0.06, 0x2a2a2c)

## the fruit and vegetables on the right of the door: crates on stepped stands
func _fruit() -> void:
	var colours: Array = [0xe2702a, 0xd8243a, 0x9ac23a, 0xf2c230, 0x5a8a2a, 0x8a3a5a, 0xe8e0a0, 0x7a4a2a]
	for j in range(2):
		var x0: float = 1.6 + j * 1.6
		box(x0, 0.0, 2.2, 1.4, 0.55, 1.2, 0x6a4a2a)
		box(x0, 0.55, 2.8, 1.4, 0.3, 0.6, 0x6a4a2a)
		for k in range(4):
			var cx: float = x0 + 0.2 + (k % 2) * 0.62
			var cz: float = 2.3 + (k / 2) * 0.6
			var cy: float = 0.55 + (k / 2) * 0.3
			var c: int = colours[(j * 4 + k) % colours.size()]
			box(cx - 0.05, cy, cz, 0.55, 0.1, 0.5, 0xb98a52)
			for n in range(6):
				ball(Vector3(cx + 0.06 + (n % 3) * 0.17, cy + 0.15, cz + 0.12 + (n / 3) * 0.25), 0.08, c, 0.9, 6, 4)
		solid(Vector3(x0 + 0.7, 0.45, 2.8), Vector3(1.4, 0.9, 1.2))
	_words("FRUTA Y VERDURA", Vector3(3.2, 2.2, 0.03), 0.0, 64, 0x2c7a3a, 0.004)

## three runs of shelves going in, goods on four shelves each side, an end of offers at the door's end of each
func _runs() -> void:
	for xr in [-1.6, 0.6, 2.8]:
		var x0: float = xr
		var z0 := 5.2
		var z1 := 12.4
		box(x0, 0.0, z0, 0.9, 1.75, z1 - z0, 0xd9dadb)
		for j in range(4):
			var y := 0.12 + j * 0.42
			for side in [0, 1]:
				var x: float = x0 - 0.02 if side == 0 else x0 + 0.9
				box(x, y - 0.03, z0, 0.02, 0.03, z1 - z0, 0xb9bcbf)
				box(x - 0.005, y - 0.03, z0, 0.03, 0.06, z1 - z0, 0xf4f4f0)            # the price strip
				_goods(Vector3(x + 0.34 if side == 1 else x, y, z0 + 0.05), Vector3(0, 0, 1), z1 - z0 - 0.1, 0.32, 0.38)      # (they stand out from its face: across is -x)
		box(x0 - 0.1, 0.0, z0 - 0.6, 1.1, 1.4, 0.6, 0xf4f4f0)                            # the end of offers
		box(x0 - 0.12, 1.4, z0 - 0.62, 1.14, 0.3, 0.64, RED)
		_words("OFERTA", Vector3(x0 + 0.45, 1.55, z0 - 0.63), PI, 64, 0xfdfcf8, 0.004)
		for j in range(3):
			_goods(Vector3(x0 - 0.05, 0.15 + j * 0.42, z0 - 0.62), Vector3(1, 0, 0), 1.0, 0.25, 0.36)
		solid(Vector3(x0 + 0.45, 0.9, (z0 - 0.6 + z1) / 2.0), Vector3(1.2, 1.8, z1 - z0 + 0.6))

## the cold cabinets down the left wall: white bodies, lit insides behind glass, goods on their shelves
func _cold() -> void:
	var z0 := 5.0
	var z1 := 14.6
	var x0 := -HALF
	box(x0, 0.0, z0, 0.8, 2.1, z1 - z0, 0xf4f4f0)
	box(x0 + 0.05, 0.25, z0 + 0.05, 0.7, 1.7, z1 - z0 - 0.1, "frio")
	for j in range(4):
		var y := 0.3 + j * 0.42
		box(x0 + 0.1, y - 0.02, z0 + 0.05, 0.6, 0.02, z1 - z0 - 0.1, 0xc9ccd0)
		_goods(Vector3(x0 + 0.45, y, z0 + 0.1), Vector3(0, 0, 1), z1 - z0 - 0.2, 0.3, 0.36)
	var z := z0
	while z < z1 - 0.1:                                  # the glass doors, their frames
		quad(Vector3(x0 + 0.8, 0.25, z), Vector3(x0 + 0.8, 0.25, z + 0.9), Vector3(x0 + 0.8, 1.95, z + 0.9), Vector3(x0 + 0.8, 1.95, z), "vidrio", Vector3(1, 0, 0))
		box(x0 + 0.78, 0.25, z, 0.04, 1.7, 0.04, 0x8a8d90)
		box(x0 + 0.79, 1.0, z + 0.8, 0.04, 0.3, 0.03, 0x5a5c5e)
		z += 0.95
	_words("FRESCOS", Vector3(x0 + 0.02, 2.62, (z0 + z1) / 2.0), PI / 2.0, 90, RED, 0.004)
	solid(Vector3(x0 + 0.4, 1.05, (z0 + z1) / 2.0), Vector3(0.8, 2.1, z1 - z0))

## drinks down the right wall: shelving with rows of bottles, packs of water at its foot
func _drinks() -> void:
	var z0 := 4.6
	var z1 := 14.6
	var x0 := HALF - 0.5
	box(HALF - 0.03, 0.0, z0, 0.03, 2.0, z1 - z0, 0xd9dadb)
	for j in range(5):
		var y := 0.1 + j * 0.4
		box(x0, y - 0.03, z0, 0.47, 0.03, z1 - z0, 0xb9bcbf)
		if j == 0:
			var z := z0 + 0.1
			while z < z1 - 0.5:                          # packs of water
				box(x0 + 0.05, y, z, 0.38, 0.3, 0.45, 0xa8d0e8)
				box(x0 + 0.04, y + 0.12, z, 0.4, 0.08, 0.45, 0x2a82d8)
				z += 0.5
		else:
			_goods(Vector3(x0 + 0.44, y, z0 + 0.05), Vector3(0, 0, 1), z1 - z0 - 0.1, 0.32, 0.36)
	_words("BEBIDAS", Vector3(HALF - 0.04, 2.62, (z0 + z1) / 2.0), -PI / 2.0, 90, RED, 0.004)
	solid(Vector3(HALF - 0.25, 1.0, (z0 + z1) / 2.0), Vector3(0.5, 2.0, z1 - z0))

## the back: the dairy in a long cold cabinet, open-fronted; over it the shop's name and its moon
func _back() -> void:
	var z := D - 0.9
	box(-HALF + 1.0, 0.0, z, 2.0 * HALF - 2.0, 1.9, 0.9, 0xf4f4f0)
	box(-HALF + 1.05, 0.3, z + 0.02, 2.0 * HALF - 2.1, 1.4, 0.75, "frio")
	for j in range(3):
		var y := 0.35 + j * 0.44
		box(-HALF + 1.05, y - 0.02, z + 0.02, 2.0 * HALF - 2.1, 0.02, 0.7, 0xc9ccd0)
		_goods(Vector3(-HALF + 1.1, y, z + 0.2), Vector3(1, 0, 0), 2.0 * HALF - 2.2, 0.35, 0.38)
	box(-HALF + 1.0, 1.9, z, 2.0 * HALF - 2.0, 0.12, 0.9, RED)
	solid(Vector3(0, 0.95, z + 0.45), Vector3(2.0 * HALF - 2.0, 1.9, 0.9))
	# the name and its moon, on the wall over the cabinet
	var w := 3.6
	var h := w * 300.0 / 1400.0
	quad(Vector3(w / 2.0, 2.2, D - 0.02), Vector3(-w / 2.0, 2.2, D - 0.02), Vector3(-w / 2.0, 2.2 + h, D - 0.02), Vector3(w / 2.0, 2.2 + h, D - 0.02), "logo", Vector3(0, 0, -1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

## the strip lamps along the ceiling, and the light they give
func _lamps() -> void:
	for z in [2.0, 5.0, 8.0, 11.0, 14.0]:
		for sx in [-3.0, 0.0, 3.0]:
			cbox(Vector3(sx, TALL - 0.035, z), Vector3(0.18, 0.05, 1.6), "luz")
			cbox(Vector3(sx, TALL - 0.01, z), Vector3(0.26, 0.02, 1.7), 0xd9d6cc)
	for at in [Vector3(-2.5, 2.7, 3.0), Vector3(2.5, 2.7, 3.0), Vector3(-2.5, 2.7, 9.0), Vector3(2.5, 2.7, 9.0), Vector3(0, 2.7, 14.0)]:
		var lamp := OmniLight3D.new()
		lamp.position = at
		lamp.light_color = Color(1.0, 0.98, 0.92)
		lamp.omni_range = 8.0
		lamp.light_energy = 0.55
		lamp.shadow_enabled = false
		add_child(lamp)
