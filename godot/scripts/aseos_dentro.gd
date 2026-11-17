extends "res://scripts/obra.gd"
## The inside of the public toilets of the fairground (ferial.gd builds the little house: north of the auditorium, its
## doors on the street's end). The user, 17 November 2026: "los baños una entrada con flecha a otra ubicación". A set
## built far out in the fields, like the post office's (correos_dentro.gd).
##
## A town's public toilets, not a copy of any: white tiles with a blue band, a grey floor; three cubicles down the left with
## their doors, the one at the end wide for a wheelchair; two urinals on the right between their screens; two basins under a
## mirror on the back wall, the hand dryer, a bin, the soap; strip lamps. Nobody in it.
##
## What a place you go into has to give (game.gd _use_door): `door_out` and `out_spawn`, `out_h` in the street;
## `in_door` and `in_spawn` in the set; `open`. The room: 7 m wide, 7.5 deep; +z goes deeper in, its door at z = 0.

const INSIDE := Vector2(-1280.0, -1870.0)       # where the set is (no street within 300 m; the other sets 300 m off or more)
const HALF := 3.5                               # half its width
const D := 7.5                                  # how deep it is
const TALL := 2.8
const BLUE := 0x2f6fb8
const DIR := "res://assets/masahorro/"          # (the wheelchair's sign of the MasAhorro's bays)

var door_out: Vector2
var out_spawn: Vector2
var out_h := 0.0
var in_door: Vector2
var in_spawn: Vector2
var open := true                # (always open: the town's public toilets)
var counter_front: Vector2      # (where somebody would stand: before the basins)

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: StandardMaterial3D = null
	match (String(key) if key is String else ""):
		"azulejo":          # white tiles, in squares of 20 cm
			var img := Image.create(8, 8, false, Image.FORMAT_RGB8)
			img.fill(Parts.col(0xf4f5f3))
			for i in range(8):
				img.set_pixel(i, 0, Parts.col(0xd2d6d6))
				img.set_pixel(0, i, Parts.col(0xd2d6d6))
			m = StandardMaterial3D.new()
			m.albedo_texture = ImageTexture.create_from_image(img)
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE / 0.2
			m.emission_enabled = true
			m.emission = Color(0.95, 0.96, 0.95)
			m.emission_energy_multiplier = 0.22
		"suelo":            # grey tiles, in squares of 30 cm
			var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
			img.set_pixel(0, 0, Parts.col(0xa8acae)); img.set_pixel(1, 1, Parts.col(0xa8acae))
			img.set_pixel(1, 0, Parts.col(0x9ca0a2)); img.set_pixel(0, 1, Parts.col(0x9ca0a2))
			m = StandardMaterial3D.new()
			m.albedo_texture = ImageTexture.create_from_image(img)
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE / 0.6
			m.roughness = 0.6
		"techo":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.95, 0.95, 0.94)
			m.emission_enabled = true
			m.emission = Color(0.95, 0.95, 0.94)
			m.emission_energy_multiplier = 0.3
		"calle":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.86, 0.93, 1.0)
			m.emission_enabled = true
			m.emission = Color(0.86, 0.93, 1.0)
			m.emission_energy_multiplier = 1.4
		"luz":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(1.0, 0.98, 0.94)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.98, 0.94)
			m.emission_energy_multiplier = 2.2
		"espejo":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.72, 0.78, 0.82)
			m.metallic = 0.9
			m.roughness = 0.06
		"loza":             # the china of the basins and the urinals
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.97, 0.97, 0.96)
			m.roughness = 0.2
			m.metallic_specular = 0.6
		"silla":            # the wheelchair's sign (white on a blue square: the square is drawn behind it)
			m = StandardMaterial3D.new()
			m.albedo_texture = load(DIR + "minusvalido.png")
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.5
		_:
			return super(key)
	_mats[key] = m
	return m

## its door in the street, where you come out to and which way you face there
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
	in_spawn = INSIDE + Vector2(0.0, 1.9)
	counter_front = INSIDE + Vector2(0.0, D - 1.4)
	_shell()
	_cubicles()
	_urinals()
	_basins()
	_lamps()
	home()
	_commit()
	_indoors(self)

func _indoors(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).layers = 1 << 10
	for c in n.get_children():
		_indoors(c)

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

# ---------------- the room ----------------
func _shell() -> void:
	quad(Vector3(-HALF, 0, 0), Vector3(HALF, 0, 0), Vector3(HALF, 0, D), Vector3(-HALF, 0, D), "suelo", Vector3.UP)
	quad(Vector3(-HALF, TALL, 0), Vector3(HALF, TALL, 0), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "techo", Vector3.DOWN)
	quad(Vector3(-HALF, 0, D), Vector3(HALF, 0, D), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "azulejo", Vector3(0, 0, -1))
	quad(Vector3(-HALF, 0, 0), Vector3(-HALF, 0, D), Vector3(-HALF, TALL, D), Vector3(-HALF, TALL, 0), "azulejo", Vector3(1, 0, 0))
	quad(Vector3(HALF, 0, 0), Vector3(HALF, 0, D), Vector3(HALF, TALL, D), Vector3(HALF, TALL, 0), "azulejo", Vector3(-1, 0, 0))
	var dw := 0.8                                    # the double door of wood, open on the street's light
	for q in [[-HALF, -dw, 0.0, TALL], [dw, HALF, 0.0, TALL], [-dw, dw, 2.2, TALL]]:
		quad(Vector3(q[0], q[2], 0), Vector3(q[1], q[2], 0), Vector3(q[1], q[3], 0), Vector3(q[0], q[3], 0), "azulejo", Vector3(0, 0, 1))
	quad(Vector3(-dw, 0, -0.1), Vector3(dw, 0, -0.1), Vector3(dw, 2.2, -0.1), Vector3(-dw, 2.2, -0.1), "calle", Vector3(0, 0, 1))
	for x in [-dw - 0.08, dw]:
		box(x, 0.0, -0.02, 0.08, 2.25, 0.1, 0x5a3a24)
	box(-dw, 2.2, -0.02, 2.0 * dw, 0.08, 0.1, 0x5a3a24)
	box(-HALF + 0.005, 1.35, 0.0, 0.01, 0.12, D, BLUE)                       # a blue band round the walls, at the height of the hand
	box(HALF - 0.015, 1.35, 0.0, 0.01, 0.12, D, BLUE)
	box(-HALF, 1.35, D - 0.015, 2.0 * HALF, 0.12, 0.01, BLUE)
	box(-HALF, 1.35, 0.005, HALF - dw, 0.12, 0.01, BLUE)
	box(dw, 1.35, 0.005, HALF - dw, 0.12, 0.01, BLUE)
	box(-0.9, 0.0, 0.2, 1.8, 0.012, 0.8, 0x4a4c4e)                                   # the mat
	solid(Vector3(0, TALL / 2.0, -0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	solid(Vector3(0, TALL / 2.0, D + 0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	for sx in [-1.0, 1.0]:
		solid(Vector3(sx * (HALF + 0.2), TALL / 2.0, D / 2.0), Vector3(0.4, TALL, D + 0.8))
	solid(Vector3(0, TALL + 0.1, D / 2.0), Vector3(2.0 * HALF + 0.8, 0.2, D + 0.8))

## three cubicles down the left: partitions of grey board on little legs, their doors ajar, a pan in each; the last one
## wide, for a wheelchair, its sign on the door
func _cubicles() -> void:
	var x1 := -HALF + 1.5                           # their fronts
	var zs := [2.2, 3.5, 4.8, D]                    # their partitions (the last cubicle 2.7 wide)
	for i in range(zs.size()):
		var z: float = zs[i]
		if i < zs.size() - 1:
			box(-HALF, 0.15, z - 0.02, 1.5, 1.95, 0.04, 0x8a96a0)
			solid(Vector3(-HALF + 0.75, 1.0, z), Vector3(1.5, 2.0, 0.06))
	for i in range(zs.size() - 1):
		var z0: float = zs[i] + 0.02
		var z1: float = zs[i + 1] - 0.02
		var wide: bool = i == zs.size() - 2
		# the front: a board either side of the door, the door ajar (turned in a little)
		var dz0 := z0 + 0.15
		var dz1 := minf(z1 - 0.15, dz0 + (0.9 if wide else 0.7))
		box(x1 - 0.02, 0.15, z0, 0.04, 1.95, dz0 - z0, 0x8a96a0)
		box(x1 - 0.02, 0.15, dz1, 0.04, 1.95, z1 - dz1, 0x8a96a0)
		var hinge := Vector3(x1, 0.15, dz1)
		var a := 0.5
		var leaf := dz1 - dz0
		quad(hinge, hinge + Vector3(sin(a) * leaf, 0, -cos(a) * leaf), hinge + Vector3(sin(a) * leaf, 1.95, -cos(a) * leaf), hinge + Vector3(0, 1.95, 0), 0x6f7d88, Vector3(cos(a), 0, sin(a)))
		solid(Vector3(x1, 1.0, (z0 + dz0) / 2.0), Vector3(0.06, 2.0, dz0 - z0))
		solid(Vector3(x1, 1.0, (dz1 + z1) / 2.0), Vector3(0.06, 2.0, z1 - dz1))
		# its pan against the wall, the cistern over it
		var cz := (z0 + z1) / 2.0
		drum(Vector3(-HALF + 0.42, 0.0, cz), 0.2, 0.18, 0.4, "loza", 10)
		box(-HALF + 0.22, 0.4, cz - 0.2, 0.42, 0.04, 0.4, "loza")
		box(-HALF + 0.02, 0.8, cz - 0.22, 0.16, 0.4, 0.44, "loza")
		if wide:                                     # the rail, and the sign on the door
			bar(Vector3(-HALF + 0.05, 0.8, cz + 0.6), Vector3(-HALF + 0.8, 0.8, cz + 0.6), 0.04, 0.04, 0xb8bcc0)
			var sp := hinge + Vector3(sin(a) * leaf * 0.5, 1.35, -cos(a) * leaf * 0.5) + Vector3(cos(a), 0, sin(a)) * 0.012
			var keep := _xf
			_xf = Transform3D(Basis(Vector3.UP, PI / 2.0 - a), sp)
			quad(Vector3(-0.14, -0.14, -0.004), Vector3(0.14, -0.14, -0.004), Vector3(0.14, 0.14, -0.004), Vector3(-0.14, 0.14, -0.004), BLUE, Vector3(0, 0, 1))
			quad(Vector3(-0.12, -0.12, 0), Vector3(0.12, -0.12, 0), Vector3(0.12, 0.12, 0), Vector3(-0.12, 0.12, 0), "silla", Vector3(0, 0, 1),
				[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
			_xf = keep

## two urinals on the right-hand wall between their screens
func _urinals() -> void:
	for k in range(2):
		var z: float = 3.0 + k * 1.0
		box(HALF - 0.32, 0.5, z - 0.2, 0.3, 0.65, 0.4, "loza")
		box(HALF - 0.36, 0.5, z - 0.16, 0.04, 0.12, 0.32, "loza")
		bar(Vector3(HALF - 0.05, 1.15, z), Vector3(HALF - 0.05, 1.6, z), 0.03, 0.03, 0xb8bcc0)
		box(HALF - 0.55, 0.5, z + 0.48, 0.55, 0.9, 0.03, 0x8a96a0)       # the screen
		solid(Vector3(HALF - 0.17, 0.85, z), Vector3(0.34, 0.7, 0.4))
	box(HALF - 0.55, 0.5, 2.52, 0.55, 0.9, 0.03, 0x8a96a0)

## two basins under a mirror on the back wall, the soap, the hand dryer beside them, a bin
func _basins() -> void:
	var z := D - 0.02
	box(-1.4, 0.82, z - 0.55, 2.8, 0.06, 0.55, 0xd8d6d0)               # the counter
	for x in [-0.7, 0.7]:
		box(x - 0.25, 0.75, z - 0.45, 0.5, 0.08, 0.36, "loza")
		bar(Vector3(x, 0.88, z - 0.05), Vector3(x, 1.02, z - 0.2), 0.03, 0.03, 0xb8bcc0)
		box(x + 0.3, 0.88, z - 0.1, 0.08, 0.18, 0.06, 0xf2f2ee)            # the soap
	box(-1.2, 0.0, z - 0.5, 2.4, 0.82, 0.04, 0xd8d6d0)
	solid(Vector3(0, 0.45, z - 0.28), Vector3(2.8, 0.9, 0.56))
	quad(Vector3(-1.3, 1.1, z - 0.01), Vector3(1.3, 1.1, z - 0.01), Vector3(1.3, 2.0, z - 0.01), Vector3(-1.3, 2.0, z - 0.01), "espejo", Vector3(0, 0, -1))
	box(1.75, 1.2, z - 0.2, 0.32, 0.36, 0.2, 0xe8e8e4)                    # the dryer
	box(1.83, 1.12, z - 0.18, 0.16, 0.08, 0.06, 0x8a8d90)
	drum(Vector3(2.4, 0.0, z - 0.3), 0.2, 0.18, 0.55, 0x8a8d90, 10)        # the bin
	_words("ASEOS", Vector3(0.0, 2.35, z - 0.02), PI, 72, BLUE, 0.004)

func _lamps() -> void:
	for z in [1.6, 4.0, 6.4]:
		cbox(Vector3(0.0, TALL - 0.03, z), Vector3(1.2, 0.05, 0.16), "luz")
	for at in [Vector3(0, 2.4, 2.0), Vector3(0, 2.4, 5.5)]:
		var lamp := OmniLight3D.new()
		lamp.position = at
		lamp.light_color = Color(1.0, 0.98, 0.95)
		lamp.omni_range = 6.0
		lamp.light_energy = 0.5
		lamp.shadow_enabled = false
		add_child(lamp)
