extends "res://scripts/obra.gd"
## The inside of the Copistería Sancho Panza, the copy shop on the Calle del Teniente Infante (bancosancho.gd builds its
## front): a set built far out in the fields, like the Papelería Rocas's (rocas.gd). The user, 17 November 2026: "Haz la
## copistería una tienda que se pueda visitar y metes a la chica dentro" -- the girl of the Recress mission, who has the
## posters ready, stands behind its counter (recress.gd puts her at `keeper_spot`).
##
## What a place you go into has to give (game.gd _use_door): `door_out` and `out_spawn`, `out_h` on the street;
## `in_door` and `in_spawn` in the set; `open`. Here `open` is the copy shop's hours (bancosancho.gd set_open keeps it).
## The room: 6.4 m wide, 9 deep; +z goes deeper in, the street door at z = 0, y = 0 its floor. The glass door, and its
## window beside it, bright with the street; the counter across the room with the girl behind it; two copiers and the
## big printer down one wall; paper, reams, files and pens down the other; the table where things are bound and cut; on
## the back wall what it prints (banners, vinyl, cards, posters) and its name with its donkey.

const INSIDE := Vector2(1450.0, 1800.0)        # where the set is (no street within 400 m; the Noche's at (1800, 1800), 350 m; V.I.P.'s at (1800, -1350), the Recress's at (-1500, -1650), the Rocas's at (-1800, -1800), your house's at (-1800, -1450), the bull's at (669, 1980))
const HALF := 3.2                               # half its width
const D := 9.0                                  # how deep it is
const TALL := 3.0
const COUNTER := 5.6                            # where the counter's front is
const DIR := "res://assets/bancosancho/"
const GREEN := 0x346e4a
const TINTS: Array = [0xf2c230, 0x3a9a4a, 0x2a82d8, 0xe8322a, 0xf07a22, 0xfdfcf8, 0x8a5ad0, 0xe85aa8, 0x1f3a6a, 0x7a2a2a]

var door_out: Vector2           # its glass door on the street
var out_spawn: Vector2          # where you stand when you come out
var out_h := 0.0
var in_door: Vector2            # the same door seen from inside
var in_spawn: Vector2
var open := false               # the copy shop's hours (bancosancho.gd)
var counter_front: Vector2      # where a customer stands
var keeper_spot: Vector2        # where the girl stands, behind the counter
var keeper_face := 0.0          # which way she faces there (to the door)
var _rng := RandomNumberGenerator.new()

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: StandardMaterial3D = null
	match (String(key) if key is String else ""):
		"pared":
			m = _lit(Color(0.95, 0.96, 0.93), 0.3)
		"techo":
			m = _lit(Color(0.97, 0.97, 0.96), 0.34)
		"suelo":            # pale grey tiles
			var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
			img.set_pixel(0, 0, Parts.col(0xd2d0ca)); img.set_pixel(1, 1, Parts.col(0xd2d0ca))
			img.set_pixel(1, 0, Parts.col(0xc4c1ba)); img.set_pixel(0, 1, Parts.col(0xc4c1ba))
			m = StandardMaterial3D.new()
			m.albedo_texture = ImageTexture.create_from_image(img)
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE / 0.8
			m.roughness = 0.9
		"ladrillo":         # the brick of its front, from inside
			m = Tex.mat("brick_wall_003@1.15", Color(1.24, 1.06, 0.9))
		"calle":            # the street, through the glass: all light
			m = _lit(Color(0.86, 0.93, 1.0), 1.5)
		"luz":
			m = _lit(Color(1.0, 0.98, 0.92), 2.2)
		"pantalla":
			m = _lit(Color(0.4, 0.7, 0.95), 0.9)
		"copisteria":       # its name and its donkey, the same panel as in its window
			m = StandardMaterial3D.new()
			m.albedo_texture = load(DIR + "copisteria.png")
			m.emission_enabled = true
			m.emission_texture = m.albedo_texture
			m.emission = Color.WHITE
			m.emission_energy_multiplier = 0.3
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

## its door on the street, where you come out to and which way you face there
func build(world, at: Vector2, out: Vector2, heading: float) -> void:
	W = world
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
	in_door = INSIDE + Vector2(-1.4, 0.45)
	in_spawn = INSIDE + Vector2(-1.4, 2.2)
	counter_front = INSIDE + Vector2(-0.6, COUNTER - 0.7)
	keeper_spot = INSIDE + Vector2(-0.6, COUNTER + 1.0)
	keeper_face = atan2(0.0, -1.0)                   # (looking at the door: -z)
	_rng.seed = 2024
	_shell()
	_counter()
	_copiers()
	_paper()
	_table()
	_back()
	_lamps()
	home()
	_commit()
	_indoors(self)

func _indoors(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).layers = 1 << 10
	for c in n.get_children():
		_indoors(c)

func _tint() -> int:
	return TINTS[_rng.randi() % TINTS.size()]

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

func _pile(at: Vector3, size: Vector2, n: int, thick: float, one := -1) -> void:
	for i in range(n):
		var j := Vector2(_rng.randf_range(-0.012, 0.012), _rng.randf_range(-0.012, 0.012))
		box(at.x - size.x / 2.0 + j.x, at.y + i * thick, at.z - size.y / 2.0 + j.y, size.x, thick - 0.002, size.y, one if one >= 0 else _tint())

# ---------------- the room ----------------
func _shell() -> void:
	quad(Vector3(-HALF, 0, 0), Vector3(HALF, 0, 0), Vector3(HALF, 0, D), Vector3(-HALF, 0, D), "suelo", Vector3.UP)
	quad(Vector3(-HALF, TALL, 0), Vector3(HALF, TALL, 0), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "techo", Vector3.DOWN)
	quad(Vector3(-HALF, 0, D), Vector3(HALF, 0, D), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "pared", Vector3(0, 0, -1))
	quad(Vector3(-HALF, 0, 0), Vector3(-HALF, 0, D), Vector3(-HALF, TALL, D), Vector3(-HALF, TALL, 0), "pared", Vector3(1, 0, 0))
	quad(Vector3(HALF, 0, 0), Vector3(HALF, 0, D), Vector3(HALF, TALL, D), Vector3(HALF, TALL, 0), "pared", Vector3(-1, 0, 0))
	# the front from inside: its bare brick, the glass door at one side, the window at the other, bright with the street
	var door := [-2.1, -0.7]
	var win := [0.4, 2.5]
	for q in [[-HALF, door[0], 0.0, TALL], [door[1], win[0], 0.0, TALL], [win[1], HALF, 0.0, TALL], [door[0], door[1], 2.45, TALL], [win[0], win[1], 2.45, TALL], [win[0], win[1], 0.0, 0.5]]:
		quad(Vector3(q[0], q[2], 0), Vector3(q[1], q[2], 0), Vector3(q[1], q[3], 0), Vector3(q[0], q[3], 0), "ladrillo", Vector3(0, 0, 1))
	quad(Vector3(door[0], 0, -0.15), Vector3(door[1], 0, -0.15), Vector3(door[1], 2.45, -0.15), Vector3(door[0], 2.45, -0.15), "calle", Vector3(0, 0, 1))
	quad(Vector3(win[0], 0.5, -0.15), Vector3(win[1], 0.5, -0.15), Vector3(win[1], 2.45, -0.15), Vector3(win[0], 2.45, -0.15), "calle", Vector3(0, 0, 1))
	for x in [door[0], door[1] - 0.06]:
		box(x, 0.0, -0.08, 0.06, 2.45, 0.08, 0x9a9da0)
	box(door[0], 2.0, -0.08, door[1] - door[0], 0.06, 0.08, 0x9a9da0)
	box(win[0], 0.45, 0.0, win[1] - win[0], 0.06, 0.35, 0xc9c4ba)                       # the window's sill, books stood on it
	for k in range(6):
		box(win[0] + 0.15 + k * 0.32, 0.51, 0.08, 0.06, 0.28, 0.2, _tint())
	box(door[0] - 0.1, 0.0, 0.25, door[1] - door[0] + 0.2, 0.012, 0.8, 0x4a4c4e)       # the mat
	box(-HALF, 0.0, 0.0, 2.0 * HALF, 0.1, 0.02, 0x8a8478)                               # a skirting
	solid(Vector3(0, TALL / 2.0, -0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	solid(Vector3(0, TALL / 2.0, D + 0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	for sx in [-1.0, 1.0]:
		solid(Vector3(sx * (HALF + 0.2), TALL / 2.0, D / 2.0), Vector3(0.4, TALL, D + 0.8))
	solid(Vector3(0, TALL + 0.1, D / 2.0), Vector3(2.0 * HALF + 0.8, 0.2, D + 0.8))

## the counter across the room: green, a pale top, the screen and the till, a pad of orders, a stapler; its flap
func _counter() -> void:
	var x0 := -HALF + 0.02
	var x1 := 1.6
	var z := COUNTER
	var h := 0.78                                    # low, so the girl behind it shows from the chest up
	box(x0, 0.0, z, x1 - x0, h, 0.6, GREEN)
	box(x0, h, z - 0.05, x1 - x0, 0.05, 0.7, 0xe9e4d6)
	for i in range(5):
		box(x0 + 0.12 + i * (x1 - x0 - 0.12) / 5.0, 0.18, z - 0.01, (x1 - x0 - 0.12) / 5.0 - 0.12, h - 0.33, 0.01, 0x2a5a3c)
	box(x1, h - 0.05, z + 0.02, HALF - x1, 0.05, 0.56, 0xe9e4d6)                        # the flap, down
	var t := h + 0.05                                # the top
	cbox(Vector3(0.45, t + 0.25, z + 0.4), Vector3(0.44, 0.3, 0.05), 0x26262a)         # the screen, turned to her, off her face
	cbox(Vector3(0.45, t + 0.25, z + 0.37), Vector3(0.38, 0.25, 0.01), "pantalla")
	cbox(Vector3(0.45, t + 0.05, z + 0.4), Vector3(0.1, 0.1, 0.1), 0x26262a)
	cbox(Vector3(-1.6, t + 0.1, z + 0.3), Vector3(0.36, 0.2, 0.34), 0x3a3d40)          # the till
	_pile(Vector3(-0.8, t, z + 0.2), Vector2(0.22, 0.3), 5, 0.012, 0xfdfcf8)            # orders, and the posters of the mission ready on it
	_pile(Vector3(-2.4, t, z + 0.25), Vector2(0.45, 0.62), 6, 0.006, 0xf2c230)
	box(0.95, t, z + 0.1, 0.18, 0.06, 0.05, 0x26262a)                                    # a stapler
	solid(Vector3(-0.8, 0.6, z + 0.3), Vector3(2.0 * HALF, 1.2, 0.7))

## two copiers and the big printer down the right-hand wall, a bin of paper for recycling
func _copiers() -> void:
	for k in range(2):
		var cz: float = 1.6 + k * 1.6
		var cx := HALF - 0.45
		cbox(Vector3(cx, 0.5, cz), Vector3(0.7, 1.0, 0.75), 0xd9d6cc)
		cbox(Vector3(cx, 1.04, cz), Vector3(0.72, 0.08, 0.77), 0x4a4d52)
		cbox(Vector3(cx, 1.11, cz), Vector3(0.66, 0.06, 0.66), 0xe9e6dc)
		cbox(Vector3(cx - 0.38, 1.02, cz - 0.2), Vector3(0.06, 0.1, 0.3), 0x26262a)
		cbox(Vector3(cx - 0.39, 1.05, cz - 0.2), Vector3(0.01, 0.06, 0.14), "pantalla")
		cbox(Vector3(cx - 0.45, 0.7, cz), Vector3(0.24, 0.03, 0.4), 0xbfbcb2)
		_pile(Vector3(cx - 0.45, 0.715, cz), Vector2(0.2, 0.3), 3, 0.006, 0xfdfcf8)
		solid(Vector3(cx, 0.55, cz), Vector3(0.75, 1.1, 0.8))
	# the big printer: a long body on legs, a roll in it, a banner coming out
	var pz := 4.9 + 0.3
	box(HALF - 0.75, 0.75, pz - 0.2, 0.65, 0.45, 1.9, 0x3a3d40)
	for z in [pz - 0.1, pz + 1.55]:
		box(HALF - 0.6, 0.0, z, 0.06, 0.75, 0.06, 0x8a8d90)
	box(HALF - 0.8, 0.95, pz - 0.15, 0.06, 0.04, 1.8, 0xfdfcf8)
	quad(Vector3(HALF - 0.82, 0.95, pz - 0.15), Vector3(HALF - 0.82, 0.95, pz + 1.65), Vector3(HALF - 1.05, 0.4, pz + 1.65), Vector3(HALF - 1.05, 0.4, pz - 0.15), 0xe8322a, Vector3(-1, 0.4, 0))
	solid(Vector3(HALF - 0.45, 0.6, pz + 0.75), Vector3(0.7, 1.2, 1.95))
	drum(Vector3(HALF - 0.35, 0.0, 0.7), 0.22, 0.2, 0.6, 0x2a6aa8, 10)                  # the recycling bin

## paper and stationery down the left-hand wall: shelving with reams, files, pads, boxes of pens
func _paper() -> void:
	var z0 := 1.2
	var z1 := 4.9
	var x := -HALF + 0.02
	box(x, 0.0, z0, 0.42, 2.1, 0.03, 0xf4f1e8)
	box(x, 0.0, z1 - 0.03, 0.42, 2.1, 0.03, 0xf4f1e8)
	for j in range(5):
		var y := 0.1 + j * 0.45
		box(x, y - 0.03, z0, 0.42, 0.03, z1 - z0, 0xf4f1e8)
		var s := z0 + 0.06
		while s < z1 - 0.3:
			if (j + int(s * 3.0)) % 3 == 0:                    # reams in their wrappers
				for m in range(_rng.randi_range(2, 4)):
					box(x + 0.06, y + m * 0.058, s, 0.3, 0.055, 0.22, 0xfdfcf8)
					box(x + 0.055, y + m * 0.058 + 0.012, s, 0.006, 0.03, 0.22, [0x2a82d8, 0xe8322a, 0x3a9a4a][m % 3])
				s += 0.28
			else:                                            # files, boxes, pads
				var w := _rng.randf_range(0.08, 0.22)
				box(x + 0.06, y, s, 0.32, _rng.randf_range(0.18, 0.36), w, _tint())
				s += w + 0.02
	_words("PAPELERÍA", Vector3(-HALF + 0.02, 2.5, (z0 + z1) / 2.0), PI / 2.0, 90, GREEN)
	solid(Vector3(-HALF + 0.21, 1.05, (z0 + z1) / 2.0), Vector3(0.44, 2.1, z1 - z0))

## the table in the middle near the door: the guillotine, the binding machine, a pile of bound jobs
func _table() -> void:
	var tx := -0.1
	var tz := 2.9
	box(tx - 0.6, 0.0, tz - 0.4, 0.06, 0.85, 0.06, 0x8a8d90)
	box(tx + 0.54, 0.0, tz - 0.4, 0.06, 0.85, 0.06, 0x8a8d90)
	box(tx - 0.6, 0.0, tz + 0.34, 0.06, 0.85, 0.06, 0x8a8d90)
	box(tx + 0.54, 0.0, tz + 0.34, 0.06, 0.85, 0.06, 0x8a8d90)
	box(tx - 0.65, 0.85, tz - 0.45, 1.3, 0.05, 0.9, 0xe9e4d6)
	cbox(Vector3(tx - 0.3, 0.92, tz), Vector3(0.5, 0.06, 0.45), 0x3a3d40)               # the guillotine
	bar(Vector3(tx - 0.52, 0.96, tz - 0.2), Vector3(tx - 0.1, 1.15, tz + 0.2), 0.04, 0.04, 0x8a8d90)
	cbox(Vector3(tx + 0.3, 0.97, tz - 0.1), Vector3(0.4, 0.16, 0.3), 0x2a5fb0)         # the binding machine
	_pile(Vector3(tx + 0.3, 0.9, tz + 0.25), Vector2(0.22, 0.3), 6, 0.02)
	solid(Vector3(tx, 0.45, tz), Vector3(1.3, 0.9, 0.9))

## the back wall: what it prints, hung up -- a banner, vinyl, cards, posters -- and its name with its donkey
func _back() -> void:
	var z := D - 0.02
	var w := 2.6
	var h := w * 500.0 / 900.0
	quad(Vector3(w / 2.0, 1.4, z), Vector3(-w / 2.0, 1.4, z), Vector3(-w / 2.0, 1.4 + h, z), Vector3(w / 2.0, 1.4 + h, z), "copisteria", Vector3(0, 0, -1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	for s in [["LONAS", -2.4, 0xe8322a], ["VINILOS", 2.2, 0x2a82d8]]:
		box(float(s[1]) - 0.6, 1.5, z - 0.02, 1.2, 0.9, 0.02, s[2])
		_words(s[0], Vector3(float(s[1]), 1.95, z - 0.03), PI, 64, 0xfdfcf8, 0.004)
	for k in range(6):                                   # cards and little posters pinned up below
		box(-2.8 + k * 0.95, 0.9, z - 0.02, 0.6, 0.4, 0.01, _tint())
	_words("FOTOCOPIAS · ENCUADERNACIONES · PLASTIFICADOS · IMPRESIÓN DIGITAL", Vector3(0.0, 2.75, z - 0.03), PI, 40, GREEN, 0.0035)

## strip lamps along the ceiling, and the light they give
func _lamps() -> void:
	for z in [1.6, 4.0, 6.6]:
		for sx in [-1.5, 1.5]:
			cbox(Vector3(sx, TALL - 0.035, z), Vector3(0.16, 0.05, 1.3), "luz")
			cbox(Vector3(sx, TALL - 0.01, z), Vector3(0.24, 0.02, 1.4), 0xd9d6cc)
	for at in [Vector3(0, 2.5, 2.0), Vector3(0, 2.5, 5.0), Vector3(0, 2.5, 7.6)]:
		var lamp := OmniLight3D.new()
		lamp.position = at
		lamp.light_color = Color(1.0, 0.98, 0.92)
		lamp.omni_range = 6.5
		lamp.light_energy = 0.55
		lamp.shadow_enabled = false
		add_child(lamp)
