extends "res://scripts/obra.gd"
## The inside of the roast chicken shop "Javi" of the Calle de los Arcos (asador.gd builds its front). The user, 21
## November 2026: "Se podrá acceder al interior, que estará diseñado (adjunto foto)" -- his picture of the real shop
## from behind its counter: a counter of steel under a guard of glass on posts of aluminium, trays of fried things in
## it (rings of squid, croquettes, chips, wings), the till at its left end, a purple cloth on it, a floor of red clay
## tiles, a dark mat, the white door and its orange curtains, the street beyond. A set built far out in the fields,
## like the bank's (banco_dentro.gd), walked into by the green arrow at the shop's door (entradas.gd).
##
## A small shop: you come in to a few metres of floor before the counter, which runs from one wall (-x: your right as
## you come in, the left in the user's picture, taken from behind it) most of the way across (a flap closes the rest: nobody but Javi goes behind). On the counter the trays under their glass, the
## till, paper bags. Behind it, against the back wall, the roaster: a cabinet of steel and glass with four spits of
## chickens turning before the fire while the shop is open, its hood over it; the fryer on the left, the tall fridge
## and the work table on the right, oil on a shelf. On your side: the drinks' fridge, crates of bread, the list of
## what there is on the left wall, the notice of the deliveries (Tuesdays and Sundays), a clock, a china hen.
## Nobody is modelled here: Javi is Sistemas's, and stands at `javi_spot`.
## A saffron flower is hidden in the corner by the window, behind the crates (the user: one in every special place).
##
## What a place you go into has to give (game.gd _use_door): `door_out`, `out_spawn`, `out_h` on the street; `in_door`
## and `in_spawn` in the set; `open` (the shop's hours: asador.gd set_open keeps it). For Sistemas: `javi_spot` and
## `javi_h` (behind the counter, looking at whoever comes in), `client_spot` and `client_h` (before him),
## `counter_front`. The room: 4.4 m wide, 6.4 deep; +z deeper in, the door at z = 0.

const INSIDE := Vector2(2100.0, -1400.0)        # where the set is: no street within 300 m, no other set (V.I.P.'s is the
                                                # nearest), no tree of the map (the first spot tried had two olives in it)
                                                # and no field with a crop
const HALF := 2.2                               # half its width
const D := 6.4                                  # how deep it is
const TALL := 2.8
const COUNTER := 2.3                            # where the counter's front is...
const COUNTER_D := 0.8                          # ...how deep it is...
const COUNTER_END := 1.35                       # ...and where it ends on the right (the flap from there to the wall)
const DIR := "res://assets/asador/"
const STEEL := 0xb8bcc0
const PURPLE := 0x6a2a7a

var door_out: Vector2
var out_spawn: Vector2
var out_h := 0.0
var in_door: Vector2
var in_spawn: Vector2
var open := false               # the shop's hours (asador.gd)
var javi_spot: Vector2          # where Javi is, behind the counter
var javi_h := 0.0               # which way he looks there (at the door)
var client_spot: Vector2        # where you stand before him
var client_h := 0.0
var counter_front: Vector2
var saffron_spot: Vector2
var props := 0
var _spits: Array = []

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: StandardMaterial3D = null
	match (String(key) if key is String else ""):
		"suelo":            # red clay tiles, thirty centimetres, one darker here and there
			var img := Image.create(4, 4, false, Image.FORMAT_RGB8)
			for y in range(4):
				for x in range(4):
					img.set_pixel(x, y, Parts.col(0xb4623c if (x * 3 + y) % 5 != 0 else 0xa4563a))
			m = StandardMaterial3D.new()
			m.albedo_texture = ImageTexture.create_from_image(img)
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE / 1.2
			m.roughness = 0.6
			m.emission_enabled = true
			m.emission = Color(0.7, 0.38, 0.24)
			m.emission_energy_multiplier = 0.18
		"pared":
			m = _lit(Color(0.96, 0.9, 0.76), 0.26)
		"azulejo":          # white tiles behind the counter and round the room's foot
			var timg := Image.create(8, 8, false, Image.FORMAT_RGB8)
			for y in range(8):
				for x in range(8):
					timg.set_pixel(x, y, Parts.col(0xd8d6ce if x == 0 or y == 0 else 0xf2f1ec))
			m = StandardMaterial3D.new()
			m.albedo_texture = ImageTexture.create_from_image(timg)
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE / 0.2
			m.roughness = 0.35
			m.emission_enabled = true
			m.emission = Color(0.93, 0.92, 0.9)
			m.emission_energy_multiplier = 0.22
		"techo":
			m = _lit(Color(0.95, 0.94, 0.9), 0.3)
		"calle":            # the street's light at the door and the window
			m = _lit(Color(0.88, 0.94, 1.0), 1.4)
		"luz":
			m = _lit(Color(1.0, 0.98, 0.92), 1.6)
		"brasa":            # the fire behind the spits
			m = _lit(Color(1.0, 0.45, 0.12), 1.8)
		"cristal":
			m = StandardMaterial3D.new()
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.78, 0.88, 0.9, 0.22)
			m.roughness = 0.15
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"naranja":          # the curtains: orange, in folds
			var cimg := Image.create(32, 4, false, Image.FORMAT_RGB8)
			for x in range(32):
				for y in range(4):
					cimg.set_pixel(x, y, Color(0.88, 0.44, 0.17) * (0.82 + 0.18 * sin(x / 32.0 * TAU * 4.0)))
			m = StandardMaterial3D.new()
			m.albedo_texture = ImageTexture.create_from_image(cimg)
			m.roughness = 1.0
			m.emission_enabled = true
			m.emission_texture = m.albedo_texture
			m.emission = Color.WHITE
			m.emission_energy_multiplier = 0.3
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"carta", "reparto":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(DIR + String(key) + ".png")
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			m.emission_enabled = true
			m.emission_texture = m.albedo_texture
			m.emission = Color.WHITE
			m.emission_energy_multiplier = 0.25
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
	in_spawn = INSIDE + Vector2(0.0, 1.35)
	javi_spot = INSIDE + Vector2(-0.2, COUNTER + COUNTER_D + 0.65)
	javi_h = PI                                     # (looking at the door: -z)
	client_spot = INSIDE + Vector2(-0.2, COUNTER - 0.65)
	client_h = 0.0
	counter_front = client_spot
	_shell()
	_counter()
	_kitchen()
	_shop_side()
	_lamps()
	_saffron(Vector2(1.92, 0.24))
	home()
	_commit()
	_roaster()
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

## a picture on a wall: on the left one (facing +x), the right one (facing -x) or the back (facing -z); `a` its lower
## corner nearest the door (or the left, on the back wall), w along the wall, h up
func _on_wall(wall: String, a: float, y: float, w: float, h: float, key, off := 0.012) -> void:
	var uv := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	if wall == "left":            # (the wall at -x; read from inside the room, the picture's left is deeper in)
		quad(Vector3(-HALF + off, y, a + w), Vector3(-HALF + off, y, a), Vector3(-HALF + off, y + h, a), Vector3(-HALF + off, y + h, a + w), key, Vector3(1, 0, 0), uv)
	elif wall == "right":         # (the wall at +x)
		quad(Vector3(HALF - off, y, a), Vector3(HALF - off, y, a + w), Vector3(HALF - off, y + h, a + w), Vector3(HALF - off, y + h, a), key, Vector3(-1, 0, 0), uv)
	else:
		quad(Vector3(a + w, y, D - off), Vector3(a, y, D - off), Vector3(a, y + h, D - off), Vector3(a + w, y + h, D - off), key, Vector3(0, 0, -1), uv)

# ---------------- the room ----------------
func _shell() -> void:
	quad(Vector3(-HALF, 0, 0), Vector3(HALF, 0, 0), Vector3(HALF, 0, D), Vector3(-HALF, 0, D), "suelo", Vector3.UP)
	quad(Vector3(-HALF, TALL, 0), Vector3(HALF, TALL, 0), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "techo", Vector3.DOWN)
	# the walls: cream over a foot of white tiles; all white tiles behind the counter
	var back := COUNTER + COUNTER_D
	for sx in [-1.0, 1.0]:
		var x: float = sx * HALF
		var n := Vector3(-sx, 0, 0)
		quad(Vector3(x, 1.1, 0), Vector3(x, 1.1, back), Vector3(x, TALL, back), Vector3(x, TALL, 0), "pared", n)
		quad(Vector3(x, 0, 0), Vector3(x, 0, back), Vector3(x, 1.1, back), Vector3(x, 1.1, 0), "azulejo", n)
		quad(Vector3(x, 0, back), Vector3(x, 0, D), Vector3(x, TALL, D), Vector3(x, TALL, back), "azulejo", n)
		box(x - (0.01 if sx > 0.0 else 0.0), 1.1, 0.0, 0.01, 0.04, back, 0x8a5a3a)
	quad(Vector3(-HALF, 0, D), Vector3(HALF, 0, D), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "azulejo", Vector3(0, 0, -1))
	# the front from inside: the white door in the middle, open, the pane at its right over a low panel, the street
	# bright beyond them; the orange curtains drawn to the sides
	var door := [-0.5, 0.5]
	var pane := [0.62, 1.82]
	var top := 2.2
	var cuts: Array = [[-HALF, door[0], 0.0, TALL], [door[1], pane[0], 0.0, TALL], [pane[1], HALF, 0.0, TALL], [door[0], door[1], top, TALL], [pane[0], pane[1], top, TALL], [pane[0], pane[1], 0.0, 0.55]]
	for q in cuts:
		quad(Vector3(q[0], q[2], 0), Vector3(q[1], q[2], 0), Vector3(q[1], q[3], 0), Vector3(q[0], q[3], 0), "pared", Vector3(0, 0, 1))
	quad(Vector3(door[0], 0, -0.15), Vector3(door[1], 0, -0.15), Vector3(door[1], top, -0.15), Vector3(door[0], top, -0.15), "calle", Vector3(0, 0, 1))
	quad(Vector3(pane[0], 0.55, -0.15), Vector3(pane[1], 0.55, -0.15), Vector3(pane[1], top, -0.15), Vector3(pane[0], top, -0.15), "calle", Vector3(0, 0, 1))
	for x in [door[0] - 0.06, door[1], pane[0] - 0.06, pane[1]]:
		box(x, 0.0, -0.08, 0.06, top, 0.1, 0xf2f2ee)
	box(door[0] - 0.06, top, -0.08, pane[1] - door[0] + 0.12, 0.06, 0.1, 0xf2f2ee)
	box(pane[0], 0.5, -0.02, pane[1] - pane[0], 0.05, 0.14, 0xf2f2ee)
	_put(Vector3(door[0], 0.0, 0.0), -1.35)                                       # the door's leaf, swung in
	for q in [[0.0, 0.0, 0.06, top], [0.89, 0.0, 0.06, top], [0.0, 0.0, 0.95, 0.5], [0.0, top - 0.06, 0.95, 0.06]]:
		box(q[0], q[1], 0.0, q[2], q[3], 0.05, 0xf2f2ee)
	quad(Vector3(0.06, 0.5, 0.025), Vector3(0.89, 0.5, 0.025), Vector3(0.89, top - 0.06, 0.025), Vector3(0.06, top - 0.06, 0.025), "cristal", Vector3(0, 0, 1))
	home()
	for q in [[door[1] + 0.02, door[1] + 0.2, 0.05], [pane[1] - 0.3, pane[1], 0.55], [pane[0], pane[0] + 0.16, 0.55]]:      # the curtains
		quad(Vector3(q[0], q[2], 0.06), Vector3(q[1], q[2], 0.06), Vector3(q[1], top - 0.03, 0.06), Vector3(q[0], top - 0.03, 0.06), "naranja", Vector3(0, 0, 1),
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	box(door[0] - 0.1, top + 0.05, 0.03, pane[1] - door[0] + 0.2, 0.03, 0.03, 0x8a8a88)                                  # (their rail)
	box(door[0] - 0.15, 0.0, 0.25, door[1] - door[0] + 0.3, 0.014, 0.85, 0x3a2e28)                                       # the mat
	solid(Vector3(0, TALL / 2.0, -0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	solid(Vector3(0, TALL / 2.0, D + 0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	for sx in [-1.0, 1.0]:
		solid(Vector3(sx * (HALF + 0.2), TALL / 2.0, D / 2.0), Vector3(0.4, TALL, D + 0.8))
	solid(Vector3(0, TALL + 0.1, D / 2.0), Vector3(2.0 * HALF + 0.8, 0.2, D + 0.8))

# ---------------- the counter, as in the user's picture ----------------
func _counter() -> void:
	var z0 := COUNTER
	var z1 := COUNTER + COUNTER_D
	var x0 := -HALF
	var x1 := COUNTER_END
	box(x0, 0.0, z0 + 0.03, x1 - x0, 0.86, COUNTER_D - 0.03, STEEL)
	box(x0, 0.86, z0 - 0.04, x1 - x0, 0.04, COUNTER_D + 0.08, 0xc8ccd0)
	box(x0, 0.08, z0, x1 - x0, 0.78, 0.03, PURPLE)                               # the purple cloth down its front
	box(x0, 0.0, z0 + 0.01, x1 - x0, 0.08, 0.03, 0x3a3a3c)
	# the flap that closes the rest: its board, the cloth under it
	box(x1, 0.86, z0 + 0.1, HALF - x1, 0.04, 0.5, 0xc8ccd0)
	box(x1, 0.1, z0 + 0.34, HALF - x1, 0.76, 0.02, PURPLE)
	# the trays: two rows of five, sunk in the top, each with what it holds
	var foods: Array = ["aros", "croquetas", "nuggets", "patatas", "alitas", "pisto", "empanadillas", "pimientos", "albondigas", "patatas_asadas"]
	for i in range(10):
		var tx: float = -1.38 + (i % 5) * 0.55
		var tz: float = z0 + 0.06 + (i / 5) * 0.36
		_tray(tx, tz, String(foods[i]), i)
	# the guard: posts of aluminium, a rail along their tops, glass between them and a shelf of it over the trays
	var gx0 := -1.48
	var gx1 := 1.3
	for k in range(4):
		var px: float = lerpf(gx0, gx1, k / 3.0)
		box(px - 0.02, 0.9, z0 - 0.01, 0.04, 0.46, 0.04, 0xd4d6d8)
		box(px - 0.02, 1.34, z0 - 0.01, 0.04, 0.03, 0.34, 0xd4d6d8)
	box(gx0 - 0.02, 1.34, z0 - 0.02, gx1 - gx0 + 0.04, 0.045, 0.06, 0xd4d6d8)
	quad(Vector3(gx0, 0.93, z0 + 0.01), Vector3(gx1, 0.93, z0 + 0.01), Vector3(gx1, 1.34, z0 + 0.01), Vector3(gx0, 1.34, z0 + 0.01), "cristal", Vector3(0, 0, -1))
	quad(Vector3(gx0, 1.365, z0), Vector3(gx1, 1.365, z0), Vector3(gx1, 1.365, z0 + 0.32), Vector3(gx0, 1.365, z0 + 0.32), "cristal", Vector3.UP)
	# the till at the left end, as in the picture; the paper bags and the napkins at the other
	_put(Vector3(-1.9, 0.9, z0 + 0.38), 0.25)
	box(-0.2, 0.0, -0.2, 0.4, 0.1, 0.4, 0xd9d2c0)
	quad(Vector3(-0.2, 0.1, -0.2), Vector3(0.2, 0.1, -0.2), Vector3(0.2, 0.2, 0.05), Vector3(-0.2, 0.2, 0.05), 0xe6dfcc, Vector3(0, 1, -0.4))
	for r in range(4):
		for c in range(5):
			cbox(Vector3(-0.14 + c * 0.07, 0.125 + r * 0.02, -0.16 + r * 0.05), Vector3(0.045, 0.014, 0.035), 0x6a6a68 if c < 4 else 0xb04030)
	box(-0.2, 0.2, 0.05, 0.4, 0.14, 0.15, 0xd9d2c0)
	box(-0.14, 0.24, 0.04, 0.2, 0.07, 0.012, 0x1f3a2a)
	box(-0.03, 0.34, 0.1, 0.06, 0.16, 0.04, 0xd9d2c0)
	box(-0.1, 0.48, 0.07, 0.2, 0.08, 0.06, 0x2a2a2c)
	home()
	_put(Vector3(1.0, 0.9, z1 - 0.28), 0.0)
	for k in range(6):
		box(-0.14, k * 0.012, -0.1, 0.28, 0.011, 0.2, 0xc8a878 if k % 2 == 0 else 0xbf9f70)
	box(0.2, 0.0, -0.08, 0.14, 0.12, 0.14, 0xf4f4f0)
	home()
	solid(Vector3(0.0, 0.7, COUNTER + COUNTER_D / 2.0), Vector3(2.0 * HALF, 1.4, COUNTER_D))

## a tray of steel sunk in the counter (0.5 x 0.32), with what it holds
func _tray(x: float, z: float, food: String, salt: int) -> void:
	var y := 0.9
	box(x - 0.015, y - 0.002, z - 0.015, 0.53, 0.012, 0.35, 0xdfe2e4)
	box(x, y + 0.004, z, 0.5, 0.008, 0.32, 0xa8acb0)
	var rnd := func(i: int, k: int) -> float:
		return fposmod(sin(float(i * 7 + salt * 13) * 12.9898 + float(k) * 78.233) * 43758.5453, 1.0)
	match food:
		"aros":                 # rings of squid, pale gold
			for i in range(9):
				var c := Vector3(x + 0.07 + rnd.call(i, 1) * 0.36, y + 0.02 + (i % 3) * 0.012, z + 0.06 + rnd.call(i, 2) * 0.2)
				for k in range(6):
					var a := TAU * k / 6.0
					cbox(c + Vector3(cos(a) * 0.035, 0.0, sin(a) * 0.035), Vector3(0.028, 0.02, 0.028), 0xe6c468)
		"croquetas":
			for i in range(14):
				cbox(Vector3(x + 0.05 + rnd.call(i, 1) * 0.4, y + 0.025 + (i % 2) * 0.02, z + 0.05 + rnd.call(i, 2) * 0.22), Vector3(0.075, 0.035, 0.035), 0xc27a2e if i % 3 else 0xb06a26)
		"nuggets":
			for i in range(12):
				cbox(Vector3(x + 0.06 + rnd.call(i, 1) * 0.38, y + 0.025 + (i % 2) * 0.018, z + 0.05 + rnd.call(i, 2) * 0.22), Vector3(0.055, 0.03, 0.045), 0xd09840)
		"patatas":              # chips
			for i in range(34):
				cbox(Vector3(x + 0.04 + rnd.call(i, 1) * 0.42, y + 0.018 + (i % 4) * 0.01, z + 0.04 + rnd.call(i, 2) * 0.24), Vector3(0.012 + rnd.call(i, 3) * 0.06, 0.012, 0.07 - rnd.call(i, 3) * 0.05), 0xecca54)
		"alitas":               # wings, roasted dark
			for i in range(9):
				ball(Vector3(x + 0.07 + rnd.call(i, 1) * 0.36, y + 0.035, z + 0.07 + rnd.call(i, 2) * 0.18), 0.045, 0x9a5426 if i % 2 else 0x8a4a22, 0.55, 6, 4)
		"pisto":
			box(x + 0.01, y + 0.012, z + 0.01, 0.48, 0.03, 0.3, 0x7a3a22)
			for i in range(10):
				cbox(Vector3(x + 0.05 + rnd.call(i, 1) * 0.4, y + 0.045, z + 0.05 + rnd.call(i, 2) * 0.22), Vector3(0.03, 0.01, 0.03), 0x4a6a2a if i % 2 else 0xb8402a)
		"empanadillas":
			for i in range(10):
				cbox(Vector3(x + 0.06 + rnd.call(i, 1) * 0.38, y + 0.025 + (i % 2) * 0.016, z + 0.06 + rnd.call(i, 2) * 0.2), Vector3(0.08, 0.02, 0.05), 0xd8a850)
		"pimientos":            # fried green peppers
			for i in range(10):
				cbox(Vector3(x + 0.06 + rnd.call(i, 1) * 0.38, y + 0.025, z + 0.05 + rnd.call(i, 2) * 0.22), Vector3(0.09, 0.022, 0.03), 0x4f7a2e if i % 2 else 0x3f6a26)
		"albondigas":           # meatballs in tomato
			box(x + 0.01, y + 0.012, z + 0.01, 0.48, 0.025, 0.3, 0xb03a22)
			for i in range(11):
				ball(Vector3(x + 0.06 + rnd.call(i, 1) * 0.38, y + 0.045, z + 0.06 + rnd.call(i, 2) * 0.2), 0.03, 0x6a3a22, 0.9, 6, 4)
		_:                      # roast potatoes
			for i in range(12):
				ball(Vector3(x + 0.06 + rnd.call(i, 1) * 0.38, y + 0.04, z + 0.06 + rnd.call(i, 2) * 0.2), 0.04, 0xd8b050, 0.7, 6, 4)
	box(x + 0.44, y + 0.03, z + 0.24, 0.012, 0.012, 0.18, 0xd4d6d8)              # its tongs

# ---------------- behind the counter ----------------
func _kitchen() -> void:
	# the roaster's cabinet against the back wall: its base, its frame, its fire, its glass, the hood over it
	var rx0 := -0.9
	var rx1 := 0.9
	var rz := D - 0.78
	box(rx0, 0.0, rz, rx1 - rx0, 0.75, 0.78, STEEL)
	for x in [rx0 + 0.05, 0.02]:
		box(x, 0.08, rz - 0.01, 0.83, 0.6, 0.012, 0xa8acb0)
		box(x + 0.7, 0.3, rz - 0.03, 0.03, 0.18, 0.02, 0x6a6e72)
	for x in [rx0, rx1 - 0.07]:
		box(x, 0.75, rz, 0.07, 1.62, 0.78, STEEL)
	box(rx0, 2.3, rz, rx1 - rx0, 0.08, 0.78, STEEL)
	box(rx0, 0.75, rz, rx1 - rx0, 0.05, 0.78, 0x8a8e92)
	quad(Vector3(rx0 + 0.07, 0.8, D - 0.06), Vector3(rx1 - 0.07, 0.8, D - 0.06), Vector3(rx1 - 0.07, 2.3, D - 0.06), Vector3(rx0 + 0.07, 2.3, D - 0.06), 0x2a1a14, Vector3(0, 0, -1))
	for k in range(4):
		box(rx0 + 0.12, 0.92 + k * 0.36, D - 0.09, rx1 - rx0 - 0.24, 0.12, 0.02, "brasa")
	quad(Vector3(rx0 + 0.07, 0.8, rz + 0.01), Vector3(rx1 - 0.07, 0.8, rz + 0.01), Vector3(rx1 - 0.07, 2.3, rz + 0.01), Vector3(rx0 + 0.07, 2.3, rz + 0.01), "cristal", Vector3(0, 0, -1))
	box(-0.02, 0.8, rz, 0.04, 1.5, 0.03, STEEL)
	box(rx0 - 0.3, 2.42, rz - 0.35, rx1 - rx0 + 0.6, 0.38, 1.13, 0xc4c8cc)        # the hood
	box(rx0 - 0.3, 2.38, rz - 0.35, rx1 - rx0 + 0.6, 0.04, 1.13, 0x8a8e92)
	solid(Vector3(0.0, 1.2, D - 0.39), Vector3(rx1 - rx0, 2.4, 0.78))
	# the fryer on the left: two baths of oil, their baskets
	box(-HALF + 0.05, 0.0, D - 0.85, 0.95, 0.9, 0.8, STEEL)
	for k in range(2):
		box(-HALF + 0.12 + k * 0.45, 0.9, D - 0.75, 0.38, 0.012, 0.55, 0x5a4a22)
		box(-HALF + 0.14 + k * 0.45, 0.91, D - 0.7, 0.34, 0.06, 0.4, 0x8a8e92)
		box(-HALF + 0.28 + k * 0.45, 0.95, D - 0.3, 0.04, 0.03, 0.22, 0x26262a)
	box(-HALF + 0.05, 0.9, D - 0.06, 0.95, 0.4, 0.05, STEEL)
	# the tall fridge and the work table on the right; bottles of oil on a shelf over the table
	box(HALF - 0.85, 0.0, D - 0.8, 0.8, 1.95, 0.75, 0xc8ccd0)
	box(HALF - 0.83, 0.1, D - 0.82, 0.76, 1.8, 0.02, 0xb4b8bc)
	box(HALF - 0.8, 0.9, D - 0.85, 0.03, 0.5, 0.03, 0x6a6e72)
	box(HALF - 0.65, 0.0, 3.5, 0.6, 0.86, 1.7, STEEL)
	box(HALF - 0.68, 0.86, 3.47, 0.66, 0.04, 1.76, 0xc8ccd0)
	for k in range(5):                                                          # trays of foil, one on another
		box(HALF - 0.55, 0.9 + k * 0.025, 3.6, 0.4, 0.022, 0.3, 0xd8dadc)
	for k in range(3):                                                          # loaves
		_put(Vector3(HALF - 0.35, 0.92, 4.2 + k * 0.22), 1.5 + 0.1 * k)
		ball(Vector3(0, 0.03, 0), 0.07, 0xc89a54, 0.6, 6, 4)
		ball(Vector3(0.12, 0.03, 0), 0.06, 0xc89a54, 0.6, 6, 4)
		ball(Vector3(-0.12, 0.03, 0), 0.06, 0xc89a54, 0.6, 6, 4)
		home()
	box(HALF - 0.3, 1.5, 3.6, 0.3, 0.03, 1.5, 0x8a6a48)
	for k in range(6):
		drum(Vector3(HALF - 0.15, 1.53, 3.75 + k * 0.24), 0.045, 0.045, 0.2, 0x5a6a22 if k % 2 == 0 else 0x6a7a2a, 8)
		drum(Vector3(HALF - 0.15, 1.73, 3.75 + k * 0.24), 0.045, 0.018, 0.06, 0x5a6a22, 8)
	# a shelf on the left wall: boxes and tins
	box(-HALF, 1.5, 3.5, 0.3, 0.03, 1.6, 0x8a6a48)
	for k in range(5):
		box(-HALF + 0.03, 1.53, 3.6 + k * 0.3, 0.22, 0.16 + 0.06 * (k % 2), 0.22, [0xc8a050, 0xb04030, 0xe8e4d8, 0x3a6a9a, 0xd8b040][k])

## The spits of the roaster, each a part of its own that turns: four spits, three chickens on each.
func _roaster() -> void:
	for k in range(4):
		var spit := Node3D.new()
		spit.position = Vector3(0.0, 1.02 + k * 0.36, D - 0.42)
		add_child(spit)
		spit.add_child(Parts.part("box", 0xcfd3d6, Vector3.ZERO, Vector3(1.6, 0.02, 0.02)))
		for i in range(3):
			var x := -0.5 + i * 0.5
			spit.add_child(Parts.part("ball", 0x7c4416 if (i + k) % 2 == 0 else 0x6e3a12, Vector3(x, 0, 0), Vector3(0.22, 0.15, 0.17)))
			for s in [-1.0, 1.0]:
				spit.add_child(Parts.part("ball", 0x643410, Vector3(x + s * 0.075, 0.055, 0.055), Vector3(0.065, 0.065, 0.11)))
			spit.add_child(Parts.part("box", 0x3a1a0a, Vector3(x, -0.066, 0.0), Vector3(0.09, 0.022, 0.11)))      # (a scorched patch, so that the turning shows)
		spit.rotation.x = k * 0.9
		for c in spit.get_children():
			var mi := c as MeshInstance3D
			if mi != null and mi.material_override is StandardMaterial3D:
				var pm := (mi.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
				pm.emission_enabled = true
				pm.emission = pm.albedo_color
				pm.emission_energy_multiplier = 0.12
				mi.material_override = pm
		_spits.append(spit)

func _process(delta: float) -> void:
	if open:
		for spit in _spits:
			(spit as Node3D).rotate_x(delta * 0.9)

# ---------------- your side of the counter ----------------
func _shop_side() -> void:
	# the drinks' fridge by the right wall: black, a door of glass, cans in rows
	var fx := HALF - 0.68
	box(fx, 0.0, 1.05, 0.66, 1.95, 0.7, 0x1c1c1e)
	box(fx + 0.02, 1.72, 1.07, 0.02, 0.2, 0.66, 0xc8281e)
	quad(Vector3(fx - 0.004, 0.2, 1.1), Vector3(fx - 0.004, 0.2, 1.7), Vector3(fx - 0.004, 1.68, 1.7), Vector3(fx - 0.004, 1.68, 1.1), "cristal", Vector3(-1, 0, 0))
	for r in range(4):
		box(fx + 0.02, 0.24 + r * 0.36, 1.1, 0.3, 0.012, 0.6, 0xd8dadc)
		for c in range(5):
			drum(Vector3(fx + 0.1, 0.255 + r * 0.36, 1.17 + c * 0.115), 0.035, 0.035, 0.12 if r > 0 else 0.2, [0xc8281e, 0xe8a020, 0x2a6ab0, 0x3a8a3a, 0xf0f0ec][(r + c) % 5], 8)
	box(fx - 0.02, 0.8, 1.66, 0.02, 0.4, 0.03, 0x8a8e92)
	solid(Vector3(fx + 0.33, 1.0, 1.4), Vector3(0.66, 2.0, 0.7))
	# crates of bread in the corner by the window
	for k in range(3):
		box(HALF - 0.7, k * 0.26, 0.5, 0.62, 0.24, 0.42, 0x3a6ab0 if k != 1 else 0xc8a030)
		for i in range(3):
			box(HALF - 0.66 + i * 0.2, k * 0.26 + 0.2, 0.54, 0.16, 0.06, 0.34, 0xd8b070)
	solid(Vector3(HALF - 0.39, 0.4, 0.71), Vector3(0.62, 0.8, 0.42))
	# the list of what there is, on the left wall; the notice of the deliveries, on the right; a clock; a calendar
	box(-HALF, 1.28, 0.74, 0.02, 0.96, 1.26, 0x6a4a30)
	_on_wall("left", 0.77, 1.31, 1.2, 0.9, "carta", 0.026)
	_on_wall("right", 0.12, 1.25, 0.42, 0.56, "reparto")
	_put(Vector3(HALF - 0.02, 2.2, 2.0), -PI / 2.0)                               # the clock
	var keep := _xf
	_xf = _xf * Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO)
	drum(Vector3.ZERO, 0.17, 0.17, 0.03, 0xb04030, 16)
	drum(Vector3(0, 0.031, 0), 0.145, 0.145, 0.002, 0xf6f4ee, 16)
	_xf = keep
	box(-0.007, 0.0, 0.034, 0.014, 0.1, 0.004, 0x1a1a1c)
	box(0.0, -0.007, 0.034, 0.075, 0.014, 0.004, 0x1a1a1c)
	home()
	box(-HALF + 0.012, 1.5, 0.2, 0.01, 0.42, 0.3, 0xf4f2ea)                       # the calendar
	box(-HALF + 0.022, 1.78, 0.2, 0.004, 0.14, 0.3, 0xc8281e)
	# a little shelf with a china hen
	box(-HALF, 2.0, 2.02, 0.2, 0.025, 0.24, 0x8a6a48)
	ball(Vector3(-HALF + 0.1, 2.085, 2.14), 0.06, 0xf4f2ea, 0.9, 8, 5)
	ball(Vector3(-HALF + 0.1, 2.15, 2.19), 0.032, 0xf4f2ea, 1.0, 6, 4)
	cbox(Vector3(-HALF + 0.1, 2.19, 2.19), Vector3(0.012, 0.025, 0.03), 0xc8281e)
	cbox(Vector3(-HALF + 0.1, 2.15, 2.225), Vector3(0.012, 0.012, 0.02), 0xe8a020)
	# the bin by the door
	drum(Vector3(-HALF + 0.3, 0.0, 0.35), 0.16, 0.18, 0.5, 0x8a8e92, 12)
	drum(Vector3(-HALF + 0.3, 0.5, 0.35), 0.185, 0.185, 0.03, 0x3a3a3c, 12)
	solid(Vector3(-HALF + 0.3, 0.3, 0.35), Vector3(0.36, 0.6, 0.36))

func _lamps() -> void:
	for z in [1.2, 4.3]:
		cbox(Vector3(0.0, TALL - 0.03, z), Vector3(1.3, 0.04, 0.2), "luz")
		cbox(Vector3(0.0, TALL - 0.008, z), Vector3(1.4, 0.016, 0.3), 0xd9d6cc)
	for at in [Vector3(0.0, 2.3, 1.2), Vector3(0.0, 2.3, 3.4), Vector3(0.0, 2.2, 5.0)]:
		var lamp := OmniLight3D.new()
		lamp.position = at
		lamp.light_color = Color(1.0, 0.96, 0.88)
		lamp.omni_range = 5.5
		lamp.light_energy = 0.5
		lamp.shadow_enabled = false
		lamp.light_cull_mask = 1 << 10
		add_child(lamp)
	var fire := OmniLight3D.new()                                                # (the roaster's glow)
	fire.position = Vector3(0.0, 1.5, D - 1.2)
	fire.light_color = Color(1.0, 0.55, 0.25)
	fire.omni_range = 2.2
	fire.light_energy = 0.25
	fire.shadow_enabled = false
	fire.light_cull_mask = 1 << 10
	add_child(fire)

## A saffron flower in a little pot of clay, in the corner by the window, behind the crates of bread (the user: hide
## saffron in special places). The flower is the game's to take away; the pot stays.
func _saffron(at: Vector2) -> void:
	drum(Vector3(at.x, 0.0, at.y), 0.1, 0.14, 0.16, 0xb0623a, 10)
	drum(Vector3(at.x, 0.15, at.y), 0.12, 0.12, 0.012, 0x5a3a26, 10)
	props += 1
	var flower := Node3D.new()
	flower.add_child(Parts.part("cyl", 0x5f9c4a, Vector3(0, 0.3, 0), Vector3(0.03, 0.6, 0.03)))
	for k in range(5):
		flower.add_child(Parts.part("ball", 0x9b5de5, Vector3(cos(k * 1.257) * 0.12, 0.66, sin(k * 1.257) * 0.12), Vector3(0.11, 0.2, 0.11)))
	flower.add_child(Parts.part("ball", 0xe63946, Vector3(0, 0.74, 0), Vector3(0.05, 0.13, 0.05)))
	flower.position = Vector3(at.x, 0.12, at.y)
	add_child(flower)
	saffron_spot = INSIDE + at
	var game = W.get_parent()                           # (the game: the world is its child)
	if game != null and game.get("flowers") != null:
		(game.flowers as Array).append({"node": flower, "p": saffron_spot, "id": "asador", "hidden": true})      # (hidden: Sistemas keeps count of these)
