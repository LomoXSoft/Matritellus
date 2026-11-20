extends "res://scripts/obra.gd"
## Interior of "Los chinos del Arroyuelo" (Alimentación at the point between Calle de San José and Calle de Santo Domingo,
## built outside by chinos.gd). A standalone interior set off the map (same pattern as noche_dentro.gd):
##   - checkout counter on the left where the shopkeeper watches you like a hawk;
##   - snacks, toys, bazar shelves, cold drinks fridge along the right wall;
##   - spacious right aisle where the spinning tobacco pack (6 €) sits for Tomasa Malvora's errand.
## Room: 9.6 m wide (-HALF..HALF), 14 m deep (0..D), 3.1 m tall; +z goes deeper in, door at z = 0.

const INSIDE := Vector2(1800.0, 1400.0)        # 400 m south of noche_dentro (1800, 1800), well clear of town & other sets
const HALF := 4.8
const D := 14.0
const TALL := 3.1
const RED := 0xc82420
const GOLD := 0xe6b64a
const WOOD := 0x7a5230
const TINTS: Array = [0xd8243a, 0xf2c230, 0x2c7a3a, 0x2a5fb0, 0xf4f2ec, 0xe2702a, 0x8a3a8a, 0x2a8ab0, 0xe85aa8, 0xb2ce34]

var door_out: Vector2
var out_spawn: Vector2
var out_h := 0.0
var in_door: Vector2
var in_spawn: Vector2
var open := false
var counter_front: Vector2
var keeper_spot: Vector2
var tobacco_spot: Vector2
var _name := ""
var _rng := RandomNumberGenerator.new()

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: StandardMaterial3D = null
	match (String(key) if key is String else ""):
		"pared":
			m = _lit(Color(0.96, 0.93, 0.86), 0.28)
		"techo":
			m = _lit(Color(0.97, 0.96, 0.93), 0.34)
		"suelo":
			var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
			img.set_pixel(0, 0, Parts.col(0xe2d9c6)); img.set_pixel(1, 1, Parts.col(0xe2d9c6))
			img.set_pixel(1, 0, Parts.col(0xd2c8b4)); img.set_pixel(0, 1, Parts.col(0xd2c8b4))
			m = StandardMaterial3D.new()
			m.albedo_texture = ImageTexture.create_from_image(img)
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE / 1.15
			m.roughness = 0.78
		"calle":
			m = _lit(Color(0.88, 0.94, 1.0), 1.4)
		"luz":
			m = _lit(Color(1.0, 0.98, 0.90), 2.2)
		"frio":
			m = _lit(Color(0.88, 0.96, 1.0), 0.9)
		"vidrio":
			m = StandardMaterial3D.new()
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.80, 0.90, 0.95, 0.22)
			m.roughness = 0.1
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"farol":
			m = _lit(Color(0.92, 0.18, 0.14), 0.65)
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

func build(world, shown: String, at: Vector2, out: Vector2, heading: float) -> void:
	W = world
	_name = shown
	door_out = at
	out_spawn = out
	out_h = heading
	var top := -1e9
	for dx in range(-int(HALF) - 2, int(HALF) + 3):
		for dz in range(-2, int(D) + 3):
			top = maxf(top, MapData.height(INSIDE + Vector2(dx, dz)))
	level = top + 0.03
	var ring := PackedVector2Array([
		INSIDE + Vector2(-HALF - 0.6, -0.6),
		INSIDE + Vector2(HALF + 0.6, -0.6),
		INSIDE + Vector2(HALF + 0.6, D + 0.6),
		INSIDE + Vector2(-HALF - 0.6, D + 0.6),
	])
	MapData.decks.append({
		"o": INSIDE + Vector2(0.0, D / 2.0),
		"poly": ring,
		"r2": (HALF + 2.0) * (HALF + 2.0) + (D / 2.0 + 2.0) * (D / 2.0 + 2.0),
		"top": level,
	})
	transform = Transform3D(Basis.IDENTITY, Vector3(INSIDE.x, level, INSIDE.y))
	W.add_child(self)
	in_door = INSIDE + Vector2(0.0, 0.45)
	in_spawn = INSIDE + Vector2(0.0, 2.0)
	counter_front = INSIDE + Vector2(-2.1, 2.8)
	keeper_spot = INSIDE + Vector2(-3.8, 2.8)
	tobacco_spot = INSIDE + Vector2(1.9, 7.8)
	_rng.seed = 2011
	_shell()
	_counter()
	_aisles()
	_fridge()
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

func _goods(from: Vector3, along: Vector3, run: float, deep: float, clear: float) -> void:
	var across := Vector3(-along.z, 0, along.x)
	var s := 0.0
	var c := _tint()
	var kind := _rng.randi() % 3
	while s < run - 0.06:
		var w := _rng.randf_range(0.08, 0.17) if kind != 2 else 0.09
		if _rng.randf() < 0.22:
			c = _tint()
			kind = _rng.randi() % 3
		if _rng.randf() < 0.06:
			s += w
			continue
		var h := clear * (_rng.randf_range(0.5, 0.85) if kind == 0 else (_rng.randf_range(0.32, 0.55) if kind == 1 else 0.72))
		var a := from + along * s
		var b := a + along * minf(w, run - s) + across * deep
		if kind == 2:
			drum(a + along * w / 2.0 + across * deep / 2.0, w * 0.44, w * 0.30, h, c, 8)
		else:
			box(minf(a.x, b.x), from.y, minf(a.z, b.z), absf(b.x - a.x) - 0.004, h, absf(b.z - a.z), c)
		s += w + 0.008

func _shell() -> void:
	quad(Vector3(-HALF, 0, 0), Vector3(HALF, 0, 0), Vector3(HALF, 0, D), Vector3(-HALF, 0, D), "suelo", Vector3.UP)
	quad(Vector3(-HALF, TALL, 0), Vector3(HALF, TALL, 0), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "techo", Vector3.DOWN)
	quad(Vector3(-HALF, 0, D), Vector3(HALF, 0, D), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "pared", Vector3(0, 0, -1))
	quad(Vector3(-HALF, 0, 0), Vector3(-HALF, 0, D), Vector3(-HALF, TALL, D), Vector3(-HALF, TALL, 0), "pared", Vector3(1, 0, 0))
	quad(Vector3(HALF, 0, 0), Vector3(HALF, 0, D), Vector3(HALF, TALL, D), Vector3(HALF, TALL, 0), "pared", Vector3(-1, 0, 0))
	var dw := 0.95
	for q in [[-HALF, -dw, 0.0, TALL], [dw, HALF, 0.0, TALL], [-dw, dw, 2.45, TALL]]:
		quad(Vector3(q[0], q[2], 0), Vector3(q[1], q[2], 0), Vector3(q[1], q[3], 0), Vector3(q[0], q[3], 0), "pared", Vector3(0, 0, 1))
	quad(Vector3(-dw, 0, -0.1), Vector3(dw, 0, -0.1), Vector3(dw, 2.45, -0.1), Vector3(-dw, 2.45, -0.1), "calle", Vector3(0, 0, 1))
	for x in [-dw, -0.03, dw - 0.06]:
		box(x, 0.0, -0.06, 0.06, 2.45, 0.06, WOOD)
	box(-dw, 2.4, -0.06, 2.0 * dw, 0.08, 0.08, WOOD)
	box(-0.9, 0.0, 0.25, 1.8, 0.012, 0.95, 0x8a3a30)
	# Red and gold trim along the top of the walls
	box(-HALF, 2.58, 0.02, 2.0 * HALF, 0.16, 0.02, RED)
	box(-HALF, 2.52, 0.02, 2.0 * HALF, 0.05, 0.02, GOLD)
	box(-HALF + 0.02, 2.58, 0.0, 0.02, 0.16, D, RED)
	box(HALF - 0.04, 2.58, 0.0, 0.02, 0.16, D, RED)
	# Solid walls and ceiling
	solid(Vector3(0, TALL / 2.0, -0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	solid(Vector3(0, TALL / 2.0, D + 0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	for sx in [-1.0, 1.0]:
		solid(Vector3(sx * (HALF + 0.2), TALL / 2.0, D / 2.0), Vector3(0.4, TALL, D + 0.8))
	solid(Vector3(0, TALL + 0.1, D / 2.0), Vector3(2.0 * HALF + 0.8, 0.2, D + 0.8))

func _counter() -> void:
	# L-shaped counter on the front-left with register, candy jars, and surveillance camera box
	var x0 := -3.35
	box(x0, 0.0, 1.4, 0.72, 0.92, 2.7, WOOD)
	box(x0 - 0.04, 0.92, 1.36, 0.80, 0.05, 2.78, 0xe8dec8)
	box(-HALF, 0.0, 3.55, 1.55, 0.92, 0.55, WOOD)
	box(-HALF, 0.92, 3.52, 1.60, 0.05, 0.61, 0xe8dec8)
	# Cash register & lucky cat / candy jars
	box(x0 + 0.12, 0.97, 2.6, 0.36, 0.22, 0.32, 0x26262b)
	box(x0 + 0.18, 1.19, 2.66, 0.22, 0.14, 0.12, 0x3b8a5a)
	for i in range(4):
		drum(Vector3(x0 + 0.35, 0.97, 1.55 + i * 0.24), 0.09, 0.09, 0.22, TINTS[(i * 3) % TINTS.size()], 8)
		drum(Vector3(x0 + 0.35, 1.19, 1.55 + i * 0.24), 0.095, 0.095, 0.04, RED, 8)
	# Little golden waving cat (Maneki-neko) on the counter
	ball(Vector3(x0 + 0.36, 1.07, 3.32), 0.10, GOLD, 1.15, 8, 6)
	ball(Vector3(x0 + 0.36, 1.21, 3.32), 0.075, GOLD, 1.0, 8, 6)
	box(x0 + 0.30, 1.14, 3.32, 0.12, 0.03, 0.14, RED)
	# Security camera dome & warning sign behind the counter
	box(-HALF + 0.04, 1.55, 2.2, 0.04, 0.55, 1.3, 0xfdfcf4)
	_words("CÁMARAS 24H\nNO ROBAR", Vector3(-HALF + 0.10, 1.82, 2.85), PI / 2.0, 44, RED, 0.0036)
	solid(Vector3(x0 + 0.36, 0.5, 2.75), Vector3(0.76, 1.0, 2.76))
	solid(Vector3(-HALF + 0.78, 0.5, 3.82), Vector3(1.56, 1.0, 0.58))

func _aisles() -> void:
	# Left wall shelves (z = 4.8..12.2): snacks, sweets and groceries
	var lx := -HALF
	box(lx, 0.0, 4.8, 0.04, 2.0, 7.4, 0xd8d2c4)
	for j in range(5):
		var y := 0.12 + j * 0.38
		box(lx + 0.04, y - 0.03, 4.8, 0.46, 0.03, 7.4, 0xb9b4a8)
		_goods(Vector3(lx + 0.08, y, 4.9), Vector3(0, 0, 1), 7.2, 0.34, 0.34)
	_words("CHUCHES · SNACKS", Vector3(lx + 0.06, 2.34, 8.5), PI / 2.0, 68, RED, 0.004)
	solid(Vector3(lx + 0.28, 1.0, 8.5), Vector3(0.56, 2.0, 7.4))

	# Center-left island shelf (x = -0.85..0.15, z = 4.9..10.7) — leaves wide 3.8 m right aisle for tobacco!
	var x0 := -0.85
	var z0 := 4.9
	var z1 := 10.7
	box(x0, 0.0, z0, 0.9, 1.72, z1 - z0, 0xddd8cc)
	for j in range(4):
		var y := 0.12 + j * 0.40
		for side in [0, 1]:
			var sx: float = x0 - 0.02 if side == 0 else x0 + 0.90
			box(sx, y - 0.03, z0, 0.02, 0.03, z1 - z0, 0xb8b2a6)
			_goods(Vector3(sx + 0.34 if side == 1 else sx, y, z0 + 0.06), Vector3(0, 0, 1), z1 - z0 - 0.12, 0.32, 0.35)
	box(x0 - 0.08, 0.0, z0 - 0.55, 1.06, 1.38, 0.55, 0xf6f2e8)
	box(x0 - 0.10, 1.38, z0 - 0.57, 1.10, 0.28, 0.59, RED)
	_words("OFERTA", Vector3(x0 + 0.45, 1.52, z0 - 0.58), PI, 56, GOLD, 0.004)
	solid(Vector3(x0 + 0.45, 0.9, (z0 - 0.55 + z1) / 2.0), Vector3(1.22, 1.8, z1 - z0 + 0.55))

	# Hanging aisle sign above the tobacco aisle
	box(1.15, 2.38, 7.75, 1.5, 0.28, 0.06, RED)
	_words("TABACO · BAZAR", Vector3(1.9, 2.52, 7.71), PI, 40, GOLD, 0.0038)

func _fridge() -> void:
	# Cold drinks cabinets down the right wall (z = 2.8..12.4)
	var z0 := 2.8
	var z1 := 12.4
	var x0 := HALF - 0.78
	box(x0, 0.0, z0, 0.78, 2.1, z1 - z0, 0xf4f2ec)
	box(x0 + 0.06, 0.25, z0 + 0.06, 0.68, 1.72, z1 - z0 - 0.12, "frio")
	for j in range(4):
		var y := 0.30 + j * 0.42
		box(x0 + 0.08, y - 0.02, z0 + 0.08, 0.62, 0.02, z1 - z0 - 0.16, 0xc9ccd0)
		_goods(Vector3(x0 + 0.52, y, z0 + 0.12), Vector3(0, 0, 1), z1 - z0 - 0.24, 0.30, 0.36)
	var z := z0
	while z < z1 - 0.15:
		quad(Vector3(x0, 0.25, z), Vector3(x0, 0.25, z + 0.92), Vector3(x0, 1.97, z + 0.92), Vector3(x0, 1.97, z), "vidrio", Vector3(-1, 0, 0))
		box(x0 - 0.02, 0.25, z, 0.04, 1.72, 0.04, 0x8a8d90)
		box(x0 - 0.03, 1.0, z + 0.80, 0.04, 0.28, 0.03, 0x4a4c50)
		z += 0.96
	_words("BEBIDAS FRÍAS", Vector3(HALF - 0.06, 2.34, (z0 + z1) / 2.0), -PI / 2.0, 68, RED, 0.004)
	solid(Vector3(HALF - 0.40, 1.05, (z0 + z1) / 2.0), Vector3(0.80, 2.1, z1 - z0))

func _back() -> void:
	var z := D - 0.75
	box(-HALF + 0.8, 0.0, z, 2.0 * HALF - 1.6, 1.85, 0.75, 0xddd8cc)
	for j in range(4):
		var y := 0.18 + j * 0.42
		box(-HALF + 0.85, y - 0.02, z - 0.02, 2.0 * HALF - 1.7, 0.03, 0.68, 0xb8b2a6)
		_goods(Vector3(-HALF + 0.95, y, z + 0.12), Vector3(1, 0, 0), 2.0 * HALF - 1.9, 0.34, 0.36)
	solid(Vector3(0, 0.95, z + 0.38), Vector3(2.0 * HALF - 1.6, 1.9, 0.76))
	# Wooden/gold sign matching the exterior
	box(-2.4, 2.02, D - 0.08, 4.8, 0.66, 0.06, WOOD)
	_words("ALIMENTACIÓN · BAZAR", Vector3(0.0, 2.36, D - 0.10), PI, 64, GOLD, 0.0044)
	# Two red paper lanterns hanging from the ceiling
	for sx in [-2.6, 2.6]:
		bar(Vector3(sx, TALL, 12.2), Vector3(sx, 2.48, 12.2), 0.02, 0.02, GOLD)
		ball(Vector3(sx, 2.28, 12.2), 0.22, "farol", 1.15, 10, 8)
		drum(Vector3(sx, 2.02, 12.2), 0.08, 0.08, 0.06, GOLD, 8)

func _lamps() -> void:
	for z in [2.2, 5.6, 9.0, 12.0]:
		for sx in [-2.5, 0.0, 2.5]:
			cbox(Vector3(sx, TALL - 0.035, z), Vector3(0.18, 0.05, 1.5), "luz")
			cbox(Vector3(sx, TALL - 0.01, z), Vector3(0.24, 0.02, 1.6), 0xd9d6cc)
	for at in [Vector3(-2.2, 2.65, 3.0), Vector3(2.2, 2.65, 3.0), Vector3(-1.8, 2.65, 8.2), Vector3(2.0, 2.65, 8.2), Vector3(0.0, 2.65, 12.2)]:
		var lamp := OmniLight3D.new()
		lamp.position = at
		lamp.light_color = Color(1.0, 0.97, 0.90)
		lamp.omni_range = 8.0
		lamp.light_energy = 0.6
		lamp.shadow_enabled = false
		add_child(lamp)
