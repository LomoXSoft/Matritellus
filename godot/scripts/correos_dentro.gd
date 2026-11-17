extends "res://scripts/obra.gd"
## The inside of Correa, the post office of the Calle de Zaragoza (correos.gd builds its outside): a set built far out in
## the fields, like the Noche's (noche_dentro.gd). The user, 17 November 2026: "añade abierto/cerrado (...) e interiores".
##
## A town's post office, not a copy of any: the counter across the room with its three windows behind glass, their
## numbers and the screen of the turns over them; the machine of the turns by the door; the row of chairs to wait in; the
## wall of post office boxes; the shelves of boxes and envelopes for sale, the stand of postcards; the desk to write at;
## a letterbox; behind the counter, the sorting frame, the parcels and the sacks. Nobody behind it yet.
##
## What a place you go into has to give (game.gd _use_door): `door_out` and `out_spawn`, `out_h` in the street;
## `in_door` and `in_spawn` in the set; `open`. The room: 9 m wide, 12 deep; +z goes deeper in, the street door at z = 0.

const INSIDE := Vector2(1300.0, -1850.0)       # where the set is (no street within 310 m; the other sets 700 m off or more)
const HALF := 4.5                               # half its width
const D := 12.0                                 # how deep it is
const TALL := 3.2
const DIR := "res://assets/correos/"
const YELLOW := 0xf8cc00
const BLUE := 0x1e4aa0
const COUNTER := 7.2                            # where the counter's front is

var door_out: Vector2
var out_spawn: Vector2
var out_h := 0.0
var in_door: Vector2
var in_spawn: Vector2
var open := false               # its hours (correos.gd set_open keeps it)
var counter_front: Vector2      # where a customer stands at a window (the one numbered 3, on the right from the door)
var windows: Array = []         # each window, numbered 1 to 3 from the left as seen from the door: {n, front: where a customer stands, keeper: where whoever serves stands behind it} (on the map)
var keeper_face := PI           # whoever serves behind the counter faces the door (-z)
var _rng := RandomNumberGenerator.new()

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: StandardMaterial3D = null
	match (String(key) if key is String else ""):
		"pared":
			m = _lit(Color(0.97, 0.95, 0.9), 0.3)
		"techo":
			m = _lit(Color(0.97, 0.97, 0.96), 0.34)
		"suelo":
			var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
			img.set_pixel(0, 0, Parts.col(0xd8d4cc)); img.set_pixel(1, 1, Parts.col(0xd8d4cc))
			img.set_pixel(1, 0, Parts.col(0xc4beb4)); img.set_pixel(0, 1, Parts.col(0xc4beb4))
			m = StandardMaterial3D.new()
			m.albedo_texture = ImageTexture.create_from_image(img)
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE / 0.8
			m.roughness = 0.7
		"calle":
			m = _lit(Color(0.86, 0.93, 1.0), 1.5)
		"luz":
			m = _lit(Color(1.0, 0.98, 0.92), 2.2)
		"pantalla":
			m = _lit(Color(0.15, 0.2, 0.3), 0.8)
		"corto", "horario":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(DIR + String(key) + ".png")
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		"vidrio":
			m = StandardMaterial3D.new()
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.8, 0.9, 0.95, 0.2)
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
	in_spawn = INSIDE + Vector2(0.0, 2.2)
	counter_front = INSIDE + Vector2(-2.6, COUNTER - 0.7)
	var pw: float = ((HALF - 1.4) - (-HALF + 0.6) - 1.4) / 3.0
	for k in range(3):                               # (the counter's three places: see _counter)
		var cx: float = -HALF + 0.6 + (k + 0.5) * pw
		windows.append({"n": 3 - k, "front": INSIDE + Vector2(cx, COUNTER - 0.7), "keeper": INSIDE + Vector2(cx, COUNTER + 1.1)})
	_rng.seed = 1117
	_shell()
	_counter()
	_turns()
	_chairs()
	_boxes_wall()
	_for_sale()
	_desk()
	_behind()
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

## a picture flat on the plane z, facing the door (-z) or away from it
func _pic(x0: float, x1: float, y0: float, y1: float, z: float, to_door: bool, key) -> void:
	pieces += 1
	if not to_door:
		quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1), [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	else:
		quad(Vector3(x1, y0, z), Vector3(x0, y0, z), Vector3(x0, y1, z), Vector3(x1, y1, z), key, Vector3(0, 0, -1), [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

# ---------------- the room ----------------
func _shell() -> void:
	quad(Vector3(-HALF, 0, 0), Vector3(HALF, 0, 0), Vector3(HALF, 0, D), Vector3(-HALF, 0, D), "suelo", Vector3.UP)
	quad(Vector3(-HALF, TALL, 0), Vector3(HALF, TALL, 0), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "techo", Vector3.DOWN)
	quad(Vector3(-HALF, 0, D), Vector3(HALF, 0, D), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "pared", Vector3(0, 0, -1))
	quad(Vector3(-HALF, 0, 0), Vector3(-HALF, 0, D), Vector3(-HALF, TALL, D), Vector3(-HALF, TALL, 0), "pared", Vector3(1, 0, 0))
	quad(Vector3(HALF, 0, 0), Vector3(HALF, 0, D), Vector3(HALF, TALL, D), Vector3(HALF, TALL, 0), "pared", Vector3(-1, 0, 0))
	var dw := 0.9                                    # the glass door, bright with the street (up the ramp, outside)
	for q in [[-HALF, -dw, 0.0, TALL], [dw, HALF, 0.0, TALL], [-dw, dw, 2.4, TALL]]:
		quad(Vector3(q[0], q[2], 0), Vector3(q[1], q[2], 0), Vector3(q[1], q[3], 0), Vector3(q[0], q[3], 0), "pared", Vector3(0, 0, 1))
	quad(Vector3(-dw, 0, -0.1), Vector3(dw, 0, -0.1), Vector3(dw, 2.4, -0.1), Vector3(-dw, 2.4, -0.1), "calle", Vector3(0, 0, 1))
	for x in [-dw, -0.03, dw - 0.06]:
		box(x, 0.0, -0.06, 0.06, 2.4, 0.06, 0x9a9da0)
	box(-dw, 2.35, -0.06, 2.0 * dw, 0.08, 0.08, 0x9a9da0)
	box(-0.9, 0.0, 0.25, 1.8, 0.012, 1.0, 0x5a5c5e)                                       # the mat
	box(-HALF, 0.0, 0.0, 2.0 * HALF, 0.12, 0.02, 0x9a8a78)                                # the skirting
	box(-HALF, 2.5, 0.02, 2.0 * HALF, 0.18, 0.02, YELLOW)                                 # a yellow band round the walls, high up
	box(-HALF + 0.02, 2.5, 0.0, 0.02, 0.18, D, YELLOW)
	box(HALF - 0.04, 2.5, 0.0, 0.02, 0.18, D, YELLOW)
	solid(Vector3(0, TALL / 2.0, -0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	solid(Vector3(0, TALL / 2.0, D + 0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	for sx in [-1.0, 1.0]:
		solid(Vector3(sx * (HALF + 0.2), TALL / 2.0, D / 2.0), Vector3(0.4, TALL, D + 0.8))
	solid(Vector3(0, TALL + 0.1, D / 2.0), Vector3(2.0 * HALF + 0.8, 0.2, D + 0.8))

## the counter across the room: three windows behind glass, each with its number, its screen, its scale and its rubber
## stamps; a fourth place for parcels at the end, open, with the big scale
func _counter() -> void:
	var z := COUNTER
	var x0 := -HALF + 0.6
	var x1 := HALF - 1.4
	box(x0, 0.0, z, x1 - x0, 1.05, 0.7, 0xe8e2d4)
	box(x0, 1.05, z - 0.05, x1 - x0, 0.05, 0.8, 0x7a6a5a)
	box(x0, 0.0, z - 0.01, x1 - x0, 0.14, 0.01, BLUE)
	box(x0, 0.6, z - 0.012, x1 - x0, 0.1, 0.01, YELLOW)
	var places := 3
	var pw: float = (x1 - x0 - 1.4) / places
	for k in range(places):
		var px: float = x0 + k * pw
		_pic(px + 0.05, px + pw - 0.05, 1.1, 2.15, z + 0.05, true, "vidrio")                # its glass, a slot at the foot
		box(px, 1.1, z + 0.02, 0.05, 1.1, 0.06, 0x9a9da0)
		box(px, 2.15, z + 0.02, pw, 0.06, 0.06, 0x9a9da0)
		box(px + pw / 2.0 - 0.6, 2.3, z + 0.03, 1.2, 0.3, 0.03, BLUE)                     # its number over it
		_words(str(places - k), Vector3(px + pw / 2.0, 2.45, z + 0.01), PI, 72, 0xfdfcf8, 0.004)      # (1 on the left, as seen from the door)
		box(px + pw / 2.0 + 0.25, 1.1, z + 0.35, 0.4, 0.3, 0.05, 0x26262a)                # its screen, turned to whoever serves
		box(px + 0.25, 1.1, z + 0.15, 0.35, 0.06, 0.3, 0x3a3c3f)                          # the scale for letters
		cbox(Vector3(px + pw / 2.0 - 0.1, 1.13, z + 0.25), Vector3(0.08, 0.06, 0.08), 0x8a3a2a)      # a stamp
	box(x0 + places * pw, 1.1, z + 0.02, 0.05, 1.1, 0.06, 0x9a9da0)
	cbox(Vector3(x1 - 0.7, 1.12, z + 0.35), Vector3(0.7, 0.04, 0.5), 0x3a3c3f)         # the parcels' place: the big scale
	box(x1 - 1.05, 1.16, z + 0.15, 0.7, 0.02, 0.45, 0xb8bcc0)
	_words("PAQUETERÍA", Vector3(x1 - 0.7, 2.4, z + 0.01), PI, 56, BLUE, 0.004)
	box(x1, 0.95, z + 0.05, HALF - x1, 0.05, 0.6, 0x7a6a5a)                               # its flap, down
	solid(Vector3((x0 + x1) / 2.0, 0.6, z + 0.35), Vector3(x1 - x0, 1.2, 0.7))
	solid(Vector3((x0 + x1) / 2.0, 1.6, z + 0.05), Vector3(x1 - x0, 1.2, 0.1))

## the machine of the turns by the door, the screen of the turns over the counter
func _turns() -> void:
	box(-1.6, 0.0, 1.3, 0.45, 1.25, 0.35, YELLOW)
	box(-1.58, 1.0, 1.29, 0.41, 0.18, 0.01, 0x26262a)
	box(-1.42, 0.85, 1.28, 0.12, 0.06, 0.01, 0xfdfcf8)
	solid(Vector3(-1.375, 0.62, 1.47), Vector3(0.45, 1.25, 0.35))
	box(-0.9, 2.65, COUNTER - 0.05, 1.8, 0.45, 0.08, 0x1a1a1c)
	box(-0.85, 2.7, COUNTER - 0.06, 1.7, 0.35, 0.01, "pantalla")
	_words("TURNO 23  >  2", Vector3(0.0, 2.87, COUNTER - 0.075), PI, 48, 0xff4a3a, 0.004)

## a row of chairs along the right wall to wait in
func _chairs() -> void:
	box(HALF - 0.7, 0.0, 1.6, 0.06, 0.45, 3.6, 0x3a3c3f)
	for k in range(5):
		var z: float = 1.8 + k * 0.7
		box(HALF - 0.75, 0.45, z, 0.5, 0.05, 0.5, BLUE)
		box(HALF - 0.28, 0.45, z, 0.05, 0.45, 0.5, BLUE)
	solid(Vector3(HALF - 0.5, 0.45, 3.4), Vector3(0.6, 0.9, 3.6))

## the wall of post office boxes on the left: little doors of brushed metal in rows, each with its number and lock
func _boxes_wall() -> void:
	var x := -HALF + 0.02
	box(x, 0.4, 1.5, 0.12, 2.0, 4.2, 0x8a8d90)
	for r in range(6):
		for c in range(10):
			var y: float = 0.5 + r * 0.32
			var z: float = 1.6 + c * 0.4
			box(x + 0.12, y, z, 0.015, 0.28, 0.36, 0xc4c8cc)
			box(x + 0.135, y + 0.1, z + 0.28, 0.01, 0.05, 0.04, 0x3a3c3f)
	_words("APARTADOS", Vector3(x + 0.02, 2.65, 3.6), PI / 2.0, 64, BLUE, 0.004)
	solid(Vector3(x + 0.08, 1.4, 3.6), Vector3(0.16, 2.0, 4.2))

## what it sells: shelves of boxes for parcels in their sizes (yellow), envelopes and padded bags, a stand of postcards
func _for_sale() -> void:
	var x := -HALF + 0.02
	box(x, 0.0, 6.0, 0.4, 1.9, 0.9, 0xd9dadb)
	for j in range(4):
		var y: float = 0.15 + j * 0.45
		box(x, y - 0.03, 6.0, 0.4, 0.03, 0.9, 0xb9bcbf)
		for k in range(3):
			var s: float = 0.18 + 0.06 * j
			box(x + 0.05, y, 6.05 + k * 0.28, 0.32, s, 0.26, YELLOW if (j + k) % 3 != 0 else 0xf2f0ea)
	solid(Vector3(x + 0.2, 0.95, 6.45), Vector3(0.4, 1.9, 0.9))
	var c := Vector3(1.6, 0.0, 4.8)                     # the stand of postcards, turning
	drum(c, 0.06, 0.06, 1.6, 0x8a8d90, 8)
	for k in range(4):
		var a: float = k * PI / 2.0
		var off := Vector3(cos(a), 0, sin(a)) * 0.18
		for r in range(4):
			cbox(c + off + Vector3(0, 0.6 + r * 0.25, 0), Vector3(0.14 if k % 2 == 0 else 0.02, 0.2, 0.02 if k % 2 == 0 else 0.14), [0x6a9ad8, 0xe8a030, 0x7ac25a, 0xd84a4a][(k + r) % 4])
	solid(c + Vector3(0, 0.8, 0), Vector3(0.4, 1.6, 0.4))

## the desk to write at, under the window, and the letterbox by the door
func _desk() -> void:
	box(1.4, 0.0, 2.3, 1.4, 0.95, 0.5, 0xe8e2d4)
	quad(Vector3(1.4, 0.95, 2.3), Vector3(2.8, 0.95, 2.3), Vector3(2.8, 1.05, 2.8), Vector3(1.4, 1.05, 2.8), 0x7a6a5a, Vector3(0, 1, -0.2))
	bar(Vector3(2.0, 1.0, 2.5), Vector3(2.1, 1.0, 2.55), 0.01, 0.01, 0x26262a)
	solid(Vector3(2.1, 0.5, 2.55), Vector3(1.4, 1.0, 0.5))
	box(-2.6, 0.0, 0.15, 0.55, 1.1, 0.4, YELLOW)                                         # the letterbox, yellow
	drum(Vector3(-2.325, 1.1, 0.35), 0.27, 0.27, 0.02, YELLOW, 12)
	box(-2.5, 0.85, 0.551, 0.3, 0.04, 0.004, 0x26262a)
	solid(Vector3(-2.325, 0.55, 0.35), Vector3(0.55, 1.1, 0.4))
	_pic(-HALF + 0.3, -HALF + 1.0, 1.2, 2.13, 0.02, false, "horario")                   # its hours, by the door

## behind the counter: the frame of pigeon-holes for sorting, the parcels on shelves, the sacks, our name on the wall
func _behind() -> void:
	var z := D - 0.3
	box(-3.4, 0.0, z - 0.4, 2.6, 2.0, 0.4, 0xb98a52)
	for r in range(6):
		for c in range(8):
			box(-3.35 + c * 0.32, 0.25 + r * 0.29, z - 0.41, 0.3, 0.27, 0.01, 0x8a6a42)
			if _rng.randf() < 0.6:
				box(-3.32 + c * 0.32, 0.27 + r * 0.29, z - 0.42, 0.24, 0.12, 0.01, 0xf2f0ea)
	box(0.2, 0.0, z - 0.6, 2.8, 1.9, 0.6, 0xd9dadb)
	for j in range(3):
		for k in range(5):
			box(0.25 + k * 0.55, 0.05 + j * 0.62, z - 0.55, 0.5, _rng.randf_range(0.25, 0.5), 0.5, [0xc8a070, 0xb8905e, YELLOW][_rng.randi() % 3])
	for k in range(3):
		ball(Vector3(3.6 + k * 0.4, 0.35, z - 1.2 + (k % 2) * 0.3), 0.35, 0xc8bc98, 0.8, 8, 5)       # sacks of letters
	_pic(-1.6, 1.6, 2.15, 2.15 + 3.2 * 240.0 / 960.0, D - 0.02, true, "corto")
	solid(Vector3(0, 1.0, D - 0.6), Vector3(2.0 * HALF, 2.0, 1.0))

func _lamps() -> void:
	for z in [2.0, 5.0, 8.0, 10.5]:
		for sx in [-2.4, 0.0, 2.4]:
			cbox(Vector3(sx, TALL - 0.035, z), Vector3(0.6, 0.05, 0.6), "luz")
			cbox(Vector3(sx, TALL - 0.01, z), Vector3(0.66, 0.02, 0.66), 0xd9d6cc)
	for at in [Vector3(-2.0, 2.7, 3.0), Vector3(2.0, 2.7, 3.0), Vector3(0, 2.7, 9.0)]:
		var lamp := OmniLight3D.new()
		lamp.position = at
		lamp.light_color = Color(1.0, 0.98, 0.92)
		lamp.omni_range = 8.0
		lamp.light_energy = 0.55
		lamp.shadow_enabled = false
		add_child(lamp)
