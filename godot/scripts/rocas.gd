extends "res://scripts/obra.gd"
## The inside of the Papelería Rocas, the stationer's of the Calle de los Arcos (comunal.gd builds its front): a set
## built far out in the fields, like V.I.P.'s (vipshop.gd) and the hall of the Recress (recress_sala.gd). The user, 16
## November 2026: "pasar sobre él [the arrow at the door] te mandará a la tienda, que será un espacio aparte y ahí
## podremos trabajar sin límites de fachada o tamaño" -- so it is as big as a stationer's wants to be, not the three
## metres of its real front.
##
## What a place you go into has to give (game.gd _use_door): `door_out` and `out_spawn`, `out_h` on the street;
## `in_door` and `in_spawn` in the set; `open`. Here `open` is the shop's hours (comunal.gd set_open keeps it).
##
## The room: 7.6 m wide and 12 deep; +z goes deeper in, the street door is at z = 0, y = 0 is its floor. The arch of
## the front from inside, bright with the street; by it the press (PRENSA) on one hand and the school bags on the
## other; books down one wall (LIBRERÍA), stationery down the other (PAPELERÍA); two tables of books in the middle; the
## counter across the far end with its flap down, the copier and the reams of paper behind it. Nobody keeps it yet
## (`keeper_spot` is where somebody would stand, `counter_front` where a customer does).
##
## The furniture is Kenney's "Furniture Kit" (CC0; assets/rocas/CREDITOS.txt), readied by tools/rocas/muebles.py; the
## shelves' goods, the press, the bags and the copier are built here.

const INSIDE := Vector2(-1800.0, -1800.0)       # where the set is (nothing of the map within 330 m; V.I.P.'s is at (1800, -1350), the Recress's at (-1500, -1650))
const HALF := 3.8                               # half its width
const D := 12.0                                 # how deep it is
const TALL := 3.1
const COUNTER := 9.4                            # where the counter's front is
const DIR := "res://assets/rocas/"
const KEBAB := "res://assets/kebab/"             # (three pieces of the same kit are already there)
const GREEN := 0x2f7a44                         # the shop's green, as on its sign in the street
const WOODC := 0xb98a52
const BOARD := 0xe9e2cc
const TINTS: Array = [0xf2c230, 0x3a9a4a, 0x2a82d8, 0xe8322a, 0xf07a22, 0xfdfcf8, 0x8a5ad0, 0xe85aa8, 0x1f3a6a, 0x7a2a2a, 0x2a6a6a, 0xd9c8a0]

var door_out: Vector2           # the arch on the street
var out_spawn: Vector2          # where you stand when you come out
var out_h := 0.0
var in_door: Vector2            # the same door seen from inside
var in_spawn: Vector2
var open := false               # the shop's hours (comunal.gd)
var counter_front: Vector2      # where a customer stands
var keeper_spot: Vector2        # where whoever keeps it would
var props := 0                  # how many pieces of the kit were set out
var _name := ""
var _rng := RandomNumberGenerator.new()

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: StandardMaterial3D = null
	match (String(key) if key is String else ""):
		"pared":
			m = _lit(Color(0.95, 0.92, 0.84), 0.3)
		"techo":
			m = _lit(Color(0.97, 0.97, 0.95), 0.34)
		"suelo":            # terrazzo in two tones
			var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
			img.set_pixel(0, 0, Parts.col(0xcfc6b0)); img.set_pixel(1, 1, Parts.col(0xcfc6b0))
			img.set_pixel(1, 0, Parts.col(0xb8ad96)); img.set_pixel(0, 1, Parts.col(0xb8ad96))
			m = StandardMaterial3D.new()
			m.albedo_texture = ImageTexture.create_from_image(img)
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE / 0.9
			m.roughness = 1.0
		"calle":            # the street, seen through the arch from inside: all light
			m = _lit(Color(0.86, 0.93, 1.0), 1.5)
		"luz":
			m = _lit(Color(1.0, 0.98, 0.9), 2.2)
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

## its name, as on its sign; then the arch on the street, where you come out to and which way you face there
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
	counter_front = INSIDE + Vector2(-0.4, COUNTER - 0.75)
	keeper_spot = INSIDE + Vector2(-0.4, COUNTER + 1.3)
	_rng.seed = 1012
	_shell()
	_press()
	_bags()
	_books()
	_stationery()
	_tables()
	_counter()
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

# ---------------- helpers ----------------
## words on a wall: `turn` 0 faces +z (read from deeper in), PI faces the door, PI/2 faces +x, -PI/2 faces -x
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

func _bounds(n: Node, xf: Transform3D, box: Array) -> void:
	var here := xf
	if n is Node3D:
		here = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var ab: AABB = here * (n as MeshInstance3D).mesh.get_aabb()
		box[0] = ab if box[0] == null else (box[0] as AABB).merge(ab)
	for c in n.get_children():
		_bounds(c, here, box)

## the kit's materials made matt, with a little light of their own (as kebab.gd has them: it all stands indoors)
func _matt(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for si in range(mi.mesh.get_surface_count()):
			var m := mi.mesh.surface_get_material(si)
			if m is BaseMaterial3D:
				var d := (m as BaseMaterial3D).duplicate() as BaseMaterial3D
				d.metallic = 0.0
				d.roughness = 1.0
				d.metallic_specular = 0.0
				d.emission_enabled = true
				d.emission = Color(d.albedo_color.r, d.albedo_color.g * 0.97, d.albedo_color.b * 0.9)
				d.emission_energy_multiplier = 0.3
				mi.set_surface_override_material(si, d)
	for c in n.get_children():
		_matt(c)

## A model of the kit stood on `pos` (the middle of its foot), `tall` metres high (or, with `wide`, that wide along its
## longer side), turned `yaw` about the upright. Returns how wide and deep it came out (x, z, before turning).
func _prop(file: String, pos: Vector3, tall: float, yaw := 0.0, wide := 0.0, dir := DIR) -> Vector2:
	var path := dir + file + ".glb"
	if not ResourceLoader.exists(path):
		return Vector2.ZERO
	var model: Node3D = (load(path) as PackedScene).instantiate()
	var box: Array = [null]
	_bounds(model, Transform3D.IDENTITY, box)
	if box[0] == null:
		model.free()
		return Vector2.ZERO
	_matt(model)
	var ab: AABB = box[0]
	var k := tall / maxf(ab.size.y, 0.001) if wide <= 0.0 else wide / maxf(maxf(ab.size.x, ab.size.z), 0.001)
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation.y = yaw
	var sized := Node3D.new()
	sized.scale = Vector3.ONE * k
	model.position = -Vector3(ab.position.x + ab.size.x / 2.0, ab.position.y, ab.position.z + ab.size.z / 2.0)
	sized.add_child(model)
	holder.add_child(sized)
	add_child(holder)
	props += 1
	return Vector2(ab.size.x, ab.size.z) * k

func _tint() -> int:
	return TINTS[_rng.randi() % TINTS.size()]

## a row of books standing on a shelf: from `from`, `run` metres along `along` (a unit vector), their backs `deep`
## metres across; `clear` is the room over the shelf
func _row(from: Vector3, along: Vector3, run: float, deep: float, clear: float) -> void:
	var across := Vector3(-along.z, 0, along.x)
	var s := 0.0
	while s < run - 0.02:
		var t := _rng.randf_range(0.025, 0.06)
		if _rng.randf() < 0.08:                     # (a gap, where one was sold)
			s += t * 2.0
			continue
		var h := clear * _rng.randf_range(0.6, 0.92)
		var a := from + along * s
		var b := a + along * minf(t, run - s) + across * deep * _rng.randf_range(0.85, 1.0)
		box(minf(a.x, b.x), from.y, minf(a.z, b.z), absf(b.x - a.x), h, absf(b.z - a.z), _tint())
		s += t + 0.003

## a pile of flat things (notebooks, pads, books lying down)
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
	# the wall of the door: the arch of the front from inside, bright with the street
	var r := 1.08
	var spring := 1.72
	for q in [[-HALF, -r, 0.0, TALL], [r, HALF, 0.0, TALL], [-r, r, spring + r, TALL]]:
		quad(Vector3(q[0], q[2], 0), Vector3(q[1], q[2], 0), Vector3(q[1], q[3], 0), Vector3(q[0], q[3], 0), "pared", Vector3(0, 0, 1))
	spandrels(0.0, spring, r, 0.0, "pared")
	arched(0.0, 0.0, spring, r, -0.25, "calle")
	for sx in [-r, r - 0.001]:                       # the thickness of the wall, round the arch
		quad(Vector3(sx, 0, -0.25), Vector3(sx, 0, 0), Vector3(sx, spring, 0), Vector3(sx, spring, -0.25), "pared", Vector3(-signf(sx), 0, 0))
	ring(0.0, spring, r, r + 0.001, 0.0, 0.25, "pared")
	box(-0.6, 0.0, 0.25, 1.2, 0.012, 0.75, 0x6a4a3a)                                  # the mat at the door
	for z in [0.0, D - 0.02]:                        # a skirting of wood
		box(-HALF, 0.0, z, 2.0 * HALF, 0.1, 0.02, 0x8a6a48)
	for x in [-HALF, HALF - 0.02]:
		box(x, 0.0, 0.0, 0.02, 0.1, D, 0x8a6a48)
	# what stops you: the four walls and the ceiling
	solid(Vector3(0, TALL / 2.0, -0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	solid(Vector3(0, TALL / 2.0, D + 0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	for sx in [-1.0, 1.0]:
		solid(Vector3(sx * (HALF + 0.2), TALL / 2.0, D / 2.0), Vector3(0.4, TALL, D + 0.8))
	solid(Vector3(0, TALL + 0.1, D / 2.0), Vector3(2.0 * HALF + 0.8, 0.2, D + 0.8))

## the press, by the door: a white rack of magazines in rows, the day's papers in piles on a bench under it
func _press() -> void:
	var x0 := 1.45
	var x1 := 3.55
	box(x0, 0.5, 0.022, x1 - x0, 1.75, 0.05, 0xf4f1e8)
	for j in range(4):
		var y := 0.56 + j * 0.42
		box(x0, y, 0.072, x1 - x0, 0.03, 0.12, 0xd9d4c8)
		box(x0, y + 0.03, 0.177, x1 - x0, 0.05, 0.015, 0xd9d4c8)
		var x := x0 + 0.05
		while x < x1 - 0.24:
			var w := _rng.randf_range(0.2, 0.23)
			var c := _tint()
			box(x, y + 0.03, 0.082 + _rng.randf_range(0.0, 0.03), w, 0.3, 0.012, c)
			box(x + 0.015, y + 0.25, 0.114, w - 0.03, 0.05, 0.004, 0xfdfcf8 if c != 0xfdfcf8 else 0xe8322a)      # its title, a band across the top
			x += w + 0.03
	box(x0, 0.0, 0.022, x1 - x0, 0.42, 0.5, WOODC)                                      # the bench, and the papers on it
	for i in range(5):
		_pile(Vector3(x0 + 0.24 + i * 0.4, 0.42, 0.28), Vector2(0.3, 0.4), _rng.randi_range(5, 12), 0.012, 0xe6e2d6 if i % 2 == 0 else 0xdcd6c8)
		box(x0 + 0.11 + i * 0.4, 0.42 + 0.145, 0.4, 0.26, 0.002, 0.05, 0x26262a)      # (a headline, for what it is worth)
	_words("PRENSA", Vector3((x0 + x1) / 2.0, 2.52, 0.022), 0.0, 96, GREEN)
	solid(Vector3((x0 + x1) / 2.0, 1.1, 0.25), Vector3(x1 - x0, 2.2, 0.5))

## the school bags, on the other side of the door: two rails of them
func _bags() -> void:
	var x0 := -3.55
	var x1 := -1.45
	box(x0, 0.45, 0.022, x1 - x0, 1.75, 0.04, 0xe6dcc6)
	for j in range(2):
		var y := 1.0 + j * 0.85
		box(x0, y + 0.5, 0.062, x1 - x0, 0.03, 0.05, 0x8a8d90)
		for i in range(5):
			var x := x0 + 0.08 + i * 0.41
			var c := _tint()
			var d: int = TINTS[(TINTS.find(c) + 5) % TINTS.size()]
			box(x, y, 0.082, 0.32, 0.44, 0.17, c)
			box(x + 0.04, y + 0.04, 0.252, 0.24, 0.2, 0.04, d)                        # its pocket
			box(x + 0.12, y + 0.44, 0.122, 0.08, 0.07, 0.03, 0x26262a)                 # its handle, on the hook
			box(x + 0.02, y + 0.3, 0.254, 0.28, 0.02, 0.004, 0x26262a)                 # its zip
	for i in range(4):                               # under them, boxes of the season's books
		box(x0 + 0.05 + i * 0.52, 0.0, 0.022, 0.46, 0.34, 0.4, 0xb9925a)
		box(x0 + 0.05 + i * 0.52, 0.34, 0.022, 0.46, 0.004, 0.4, 0xa07c48)
		box(x0 + 0.24 + i * 0.52, 0.0, 0.422, 0.08, 0.34, 0.002, 0xd9c8a0)
	_words("MOCHILAS", Vector3((x0 + x1) / 2.0, 2.52, 0.022), 0.0, 96, GREEN)
	solid(Vector3((x0 + x1) / 2.0, 1.1, 0.22), Vector3(x1 - x0, 2.2, 0.44))

## books: six cases of the kit against the wall at -x, each shelf a row of them, more lying on top
func _books() -> void:
	var tall := 2.2
	var k := tall / 8.8                              # (the kit's case: 4 wide, 2.5 deep, 8.8 high, shelves at 1.3, 3.7 and 6.1)
	var deep := 2.5 * k
	var wide := 4.0 * k
	for i in range(6):
		var z := 1.75 + wide / 2.0 + i * (wide + 0.04)
		_prop("mueble_bookcaseOpen", Vector3(-HALF + deep / 2.0 + 0.02, 0.0, z), tall, PI / 2.0)
		for y in [1.3 * k, 3.7 * k, 6.1 * k]:
			_row(Vector3(-HALF + 0.46, y + 0.012, z - wide / 2.0 + 0.11), Vector3(0, 0, 1), wide - 0.22, 0.3, 2.1 * k)
		for n in range(_rng.randi_range(1, 2)):
			_pile(Vector3(-HALF + 0.3, tall + 0.012, z - 0.2 + n * 0.4), Vector2(0.28, 0.2), _rng.randi_range(2, 5), 0.045)
	var z1 := 1.75 + 6.0 * (wide + 0.04)
	_words("LIBRERÍA", Vector3(-HALF + 0.02, 2.72, (1.75 + z1) / 2.0), PI / 2.0, 110, GREEN)
	solid(Vector3(-HALF + deep / 2.0, 1.1, (1.75 + z1) / 2.0), Vector3(deep + 0.04, 2.2, z1 - 1.75))

## stationery down the wall at +x: white shelving, and on it files, pads in piles, reams, pots of pens, globes on top;
## a bin of rolls of wrapping paper at its far end
func _stationery() -> void:
	var z0 := 1.75
	var z1 := 7.35
	var x := HALF - 0.42
	box(HALF - 0.05, 0.0, z0, 0.03, 2.2, z1 - z0, 0xf4f1e8)
	for i in range(5):
		box(x, 0.0, z0 + i * (z1 - z0 - 0.03) / 4.0, 0.37, 2.2, 0.03, 0xf4f1e8)
	for j in range(6):
		var y := 0.1 + j * 0.42
		box(x, y - 0.03, z0, 0.37, 0.03, z1 - z0, 0xf4f1e8)
		if j == 5:
			break
		for bay in range(4):
			var a := z0 + 0.05 + bay * (z1 - z0 - 0.03) / 4.0
			var run := (z1 - z0 - 0.03) / 4.0 - 0.1
			match (j * 3 + bay * 5) % 4:
				0:                                   # lever arch files, a label on each back
					var s := 0.0
					while s < run - 0.08:
						var c := _tint()
						box(x + 0.06, y, a + s, 0.3, 0.33, 0.07, c)
						box(x + 0.055, y + 0.14, a + s + 0.015, 0.006, 0.12, 0.04, 0xfdfcf8)
						s += 0.078
				1:                                   # pads and notebooks in piles
					for n in range(4):
						_pile(Vector3(x + 0.22, y, a + 0.16 + n * 0.33), Vector2(0.3, 0.22), _rng.randi_range(4, 12), 0.022)
				2:                                   # reams of paper, a band round each
					for n in range(3):
						for m in range(_rng.randi_range(2, 4)):
							box(x + 0.05, y + m * 0.058, a + 0.04 + n * 0.42, 0.31, 0.055, 0.22, 0xfdfcf8)
							box(x + 0.045, y + m * 0.058 + 0.012, a + 0.04 + n * 0.42, 0.006, 0.03, 0.22, [0x2a82d8, 0xe8322a, 0x3a9a4a][(n + m) % 3])
				3:                                   # pots of pens and pencils, boxes of them behind
					for n in range(5):
						var pz := a + 0.12 + n * 0.25
						drum(Vector3(x + 0.12, y, pz), 0.045, 0.045, 0.11, [0x26262a, 0x2a82d8, 0xe8322a][n % 3], 8)
						for p in range(5):
							box(x + 0.1 + p * 0.012, y + 0.1, pz - 0.02 + (p % 3) * 0.015, 0.008, 0.1, 0.008, _tint())
						box(x + 0.24, y, pz - 0.1, 0.14, 0.12 + 0.03 * (n % 2), 0.2, _tint())
	for i in range(3):                               # globes on top of it
		var gz := z0 + 0.9 + i * 1.9
		drum(Vector3(x + 0.21, 2.2, gz), 0.09, 0.05, 0.04, 0x26262a, 10)
		box(x + 0.2, 2.24, gz - 0.01, 0.02, 0.1, 0.02, 0x26262a)
		ball(Vector3(x + 0.21, 2.46, gz), 0.14, 0x2a82d8, 1.0, 10, 6)
		box(x + 0.1, 2.44, gz - 0.06, 0.1, 0.08, 0.05, 0x3a9a4a)
		box(x + 0.22, 2.4, gz + 0.05, 0.08, 0.1, 0.06, 0x3a9a4a)
	_words("PAPELERÍA", Vector3(HALF - 0.02, 2.82, (z0 + z1) / 2.0), -PI / 2.0, 110, GREEN)
	solid(Vector3(HALF - 0.21, 1.1, (z0 + z1) / 2.0), Vector3(0.44, 2.2, z1 - z0))
	box(HALF - 0.62, 0.0, z1 + 0.12, 0.5, 0.5, 0.5, 0x8a6a48)                         # the bin of rolls of wrapping paper
	for i in range(7):
		drum(Vector3(HALF - 0.52 + (i % 3) * 0.15, 0.1, z1 + 0.22 + (i / 3) * 0.14), 0.035, 0.035, 0.85 + 0.05 * (i % 3), _tint(), 8)
	solid(Vector3(HALF - 0.37, 0.5, z1 + 0.37), Vector3(0.5, 1.0, 0.5))

## two tables down the middle with what is new on them, a rug at the door, the stand of cards
func _tables() -> void:
	_prop("mueble_rugRectangle", Vector3(0.0, 0.005, 1.55), 0.0, 0.0, 2.7)
	for i in range(2):
		var z := 4.7 + i * 2.35                      # (well clear of the door: you come in at z = 2.2 and see the shop, not a table)
		var size: Vector2 = _prop("mueble_table", Vector3(0.0, 0.0, z), 0.78, PI / 2.0)
		var half := Vector2(maxf(minf(size.x, size.y), 0.6), maxf(size.x, size.y)) / 2.0     # (turned: its long side runs in)
		for n in range(7):
			var at := Vector3(_rng.randf_range(-half.x + 0.2, half.x - 0.2), 0.78, z - half.y + 0.32 + n * (2.0 * half.y - 0.52) / 6.0)
			if n % 3 == 1:
				_prop("mueble_books", at, 0.0, _rng.randf_range(0.0, TAU), 0.34)
			else:
				_pile(at, Vector2(0.2, 0.28), _rng.randi_range(3, 8), 0.035)
		var cz := z - half.y + 0.07                  # a card stood up at its near end, read from the door
		box(-0.02, 0.78, cz, 0.04, 0.16, 0.02, 0x4a4d52)
		box(-0.26, 0.94, cz, 0.52, 0.2, 0.02, 0xfdfcf8)
		_words("NOVEDADES" if i == 0 else "OFERTAS", Vector3(0.0, 1.04, cz - 0.002), PI, 48, 0xe8322a, 0.0018)
		solid(Vector3(0, 0.45, z), Vector3(2.0 * half.x, 0.9, 2.0 * half.y))
	for px in [-HALF + 0.42, HALF - 0.42]:           # a plant in each corner by the door
		_prop("mueble_pottedPlant", Vector3(px, 0.0, 1.1), 1.25, 0.0, 0.0, KEBAB)
	var sx := 2.15                                   # the stand of cards: a slim post, cards flat on its four faces
	var sz := 1.55
	drum(Vector3(sx, 0.0, sz), 0.2, 0.18, 0.04, 0x4a4d52, 10)
	box(sx - 0.02, 0.0, sz - 0.02, 0.04, 1.55, 0.04, 0x4a4d52)
	for j in range(5):
		var y := 0.55 + j * 0.2
		for q in [[0.075, 0.0, 0.006, 0.11], [-0.081, 0.0, 0.006, 0.11], [0.0, 0.075, 0.11, 0.006], [0.0, -0.081, 0.11, 0.006]]:
			cbox(Vector3(sx + q[0], y + 0.08, sz + q[1]), Vector3(q[2], 0.16, q[3]), _tint())
		box(sx - 0.085, y - 0.012, sz - 0.085, 0.17, 0.012, 0.17, 0x4a4d52)
	solid(Vector3(sx, 0.8, sz), Vector3(0.36, 1.6, 0.36))

## the counter across the far end: green, a top of pale wood, a case of pens under glass at one end, the till and the
## screen on it, its flap down at the other end
func _counter() -> void:
	var x0 := -HALF + 0.02
	var x1 := 2.7
	var z := COUNTER
	box(x0, 0.0, z, x1 - x0, 0.92, 0.6, GREEN)
	box(x0, 0.92, z - 0.05, x1 - x0, 0.05, 0.7, BOARD)
	box(x0, 0.0, z - 0.006, x1 - x0, 0.12, 0.006, 0x26262a)                           # its kick-board
	for i in range(7):                               # its panels
		box(x0 + 0.12 + i * (x1 - x0 - 0.12) / 7.0, 0.2, z - 0.01, (x1 - x0 - 0.12) / 7.0 - 0.12, 0.62, 0.01, 0x286a3b)
	box(x1, 0.87, z + 0.02, HALF - x1, 0.05, 0.56, BOARD)                              # the flap, down
	box(x1 - 0.004, 0.88, z + 0.02, 0.008, 0.03, 0.56, 0x8a8d90)
	# the case of pens: a glass top, rows of them under it
	box(x0 + 0.15, 0.97, z + 0.02, 1.3, 0.12, 0.52, 0xf4f1e8)
	for i in range(11):
		box(x0 + 0.22 + i * 0.11, 1.09, z + 0.08, 0.03, 0.012, 0.36, _tint())
	box(x0 + 0.15, 1.1, z + 0.02, 1.3, 0.01, 0.52, 0xbfd6e2)
	cbox(Vector3(-0.4, 1.07, z + 0.3), Vector3(0.36, 0.2, 0.34), 0x3a3d40)             # the till
	cbox(Vector3(-0.4, 1.19, z + 0.36), Vector3(0.26, 0.04, 0.14), 0x26262a)
	_prop("mueble_computerScreen", Vector3(0.75, 0.97, z + 0.36), 0.42, PI)
	_prop("mueble_computerKeyboard", Vector3(0.75, 0.97, z + 0.14), 0.0, PI, 0.4)
	drum(Vector3(0.1, 0.97, z + 0.12), 0.05, 0.05, 0.11, 0xe8322a, 8)                 # a pot of pens
	for p in range(6):
		box(0.07 + (p % 3) * 0.025, 1.07, z + 0.1 + (p / 3) * 0.03, 0.008, 0.11, 0.008, _tint())
	_pile(Vector3(-1.2, 0.97, z + 0.25), Vector2(0.22, 0.3), 6, 0.02, 0xfdfcf8)       # paper bags, a pad of receipts
	_pile(Vector3(-1.55, 0.97, z + 0.2), Vector2(0.1, 0.16), 4, 0.012, 0xf2c230)
	_prop("mueble_chairDesk", Vector3(0.9, 0.0, z + 1.35), 1.0, PI)
	_prop("mueble_trashcan", Vector3(3.3, 0.0, z - 0.35), 0.55, 0.0, 0.0, KEBAB)
	solid(Vector3(0.0, 0.6, z + 0.3), Vector3(2.0 * HALF, 1.2, 0.7))

## behind the counter: the shop's name on the wall, shelves of reams and boxes, the copier, cartons in the corner
func _back() -> void:
	var z := D
	box(-2.0, 2.2, z - 0.03, 4.0, 0.7, 0.03, GREEN)
	_words(_name, Vector3(0.9, 2.56, z - 0.04), PI, 150, 0xfdfcf8)
	_words("LIBRERÍA · PAPELERÍA\nPRENSA", Vector3(-0.95, 2.55, z - 0.04), PI, 44, 0xf2e6a0)
	for j in range(4):                               # shelves the width of the wall behind the counter
		var y := 0.35 + j * 0.44
		box(-HALF + 0.05, y, z - 0.36, 4.9, 0.03, 0.36, 0xf4f1e8)
		var x := -HALF + 0.12
		while x < -HALF + 4.7:
			if _rng.randf() < 0.55:                  # reams, in their wrappers
				var n := _rng.randi_range(2, 5)
				for m in range(n):
					box(x, y + 0.03 + m * 0.058, z - 0.33, 0.22, 0.055, 0.3, 0xfdfcf8)
					box(x, y + 0.045 + m * 0.058, z - 0.335, 0.22, 0.028, 0.006, [0x2a82d8, 0xe8322a, 0x3a9a4a][(j + m) % 3])
				x += 0.27
			else:                                    # boxes of whatever
				var w := _rng.randf_range(0.24, 0.4)
				box(x, y + 0.03, z - 0.32, w, _rng.randf_range(0.16, 0.3), 0.28, _tint())
				x += w + 0.04
	for sx in [-HALF + 0.05, -HALF + 2.5, -HALF + 4.92]:
		box(sx, 0.0, z - 0.36, 0.03, 1.95, 0.36, 0xf4f1e8)
	# the copier: its body, the glass under its lid, its panel, a tray of copies
	var cx := 3.0
	var cz := z - 0.5
	cbox(Vector3(cx, 0.45, cz), Vector3(0.78, 0.9, 0.66), 0xd9d6cc)
	cbox(Vector3(cx, 0.94, cz), Vector3(0.8, 0.08, 0.68), 0x4a4d52)
	cbox(Vector3(cx, 1.01, cz + 0.02), Vector3(0.74, 0.06, 0.6), 0xe9e6dc)
	cbox(Vector3(cx + 0.2, 0.93, cz - 0.37), Vector3(0.3, 0.06, 0.08), 0x26262a)
	cbox(Vector3(cx + 0.22, 0.96, cz - 0.39), Vector3(0.08, 0.02, 0.03), 0x3a9a4a)
	cbox(Vector3(cx - 0.52, 0.62, cz), Vector3(0.28, 0.03, 0.4), 0xbfbcb2)
	_pile(Vector3(cx - 0.52, 0.635, cz), Vector2(0.21, 0.3), 3, 0.006, 0xfdfcf8)
	for j in range(2):
		cbox(Vector3(cx, 0.22 + j * 0.26, cz - 0.335), Vector3(0.66, 0.2, 0.01), 0xc9c6bc)
		cbox(Vector3(cx, 0.26 + j * 0.26, cz - 0.345), Vector3(0.2, 0.03, 0.02), 0x8a8d90)
	box(cx - 0.55, 1.75, z - 0.02, 1.1, 0.72, 0.02, 0xfdfcf8)
	_words("FOTOCOPIAS\nENCUADERNACIONES\nPLASTIFICADOS", Vector3(cx, 2.11, z - 0.03), PI, 34, 0x26262a, 0.003)
	_prop("mueble_cardboardBoxClosed", Vector3(2.0, 0.0, z - 0.4), 0.5, 0.2)
	_prop("mueble_cardboardBoxClosed", Vector3(2.0, 0.5, z - 0.42), 0.42, -0.25)
	_prop("mueble_cardboardBoxOpen", Vector3(1.4, 0.0, z - 0.42), 0.45, 0.1)

## the strip lamps along the ceiling, and the light they give
func _lamps() -> void:
	for z in [1.8, 4.6, 7.4, 10.4]:
		for sx in [-1.7, 1.7]:
			cbox(Vector3(sx, TALL - 0.035, z), Vector3(0.16, 0.05, 1.3), "luz")
			cbox(Vector3(sx, TALL - 0.01, z), Vector3(0.24, 0.02, 1.4), 0xd9d6cc)
	for at in [Vector3(0, 2.6, 2.2), Vector3(0, 2.6, 5.2), Vector3(0, 2.6, 8.2), Vector3(0, 2.6, 10.9)]:
		var lamp := OmniLight3D.new()
		lamp.position = at
		lamp.light_color = Color(1.0, 0.96, 0.86)
		lamp.omni_range = 7.5
		lamp.light_energy = 0.55
		lamp.shadow_enabled = false
		add_child(lamp)
