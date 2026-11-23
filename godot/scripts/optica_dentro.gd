extends "res://scripts/obra.gd"
## The inside of the optician "Óptica Corsa" of the Calle del Salvador (optica.gd builds its front). The user, 23
## November 2026: "Igual que Tutoq ... aquí el NPC será una Óptica con bata blanca y solo venderá gafas. Y te dirá cosas
## sobre graduarte la vista, parece que tienes estrabismo, tengo modelos nuevos y vintage y tal. Se llamará Fátima
## Corsa." A set built far out in the fields, like the other shops', walked into by the green arrow before its door
## (entradas.gd). Fátima herself is Sistemas's (fatima.gd): she stands at `clerk_spot`.
##
## FIRST DRAFT, from what an optician of the town has (Google Maps shows the real inside only signed in): white walls,
## a floor of big pale tiles, little round lights in the ceiling.
##   - at your right as you come in, the counter with the till, a teal wall behind it with shelves of glasses cases and
##     bottles of lens cleaner, her diploma in a frame;
##   - along the wall at your left, the new frames ("Novedades": rows of glass shelves on a lit white wall, a pair on
##     each place) and past them the old ones ("Vintage": a dark wooden cabinet, round frames of tortoiseshell and gold
##     on trays of green baize) -- the user: "tengo modelos nuevos y vintage";
##   - in the middle a tower of sunglasses and a low glass case of more;
##   - on the right past the counter a long mirror on the wall and a little table with a mirror on it, where you try
##     glasses on (`probador_spot`);
##   - at the back, behind a partition with the shop's name and an open doorway, the room where she tests your eyes:
##     the black chair, the column with its arm and the phoropter before the chair's head, the lit eye chart on the
##     wall before it (its smallest row says the town's name), a desk with the box of trial lenses, the machine that
##     reads your eyes and a screen.
## Nobody is modelled but what is sold (the user decides figures). A saffron flower is hidden behind the eye chart, in
## the slit between its box and the wall, a little of its purple peeping out at the side (the user, 23 Nov 2026, to the
## proposal "detrás del optotipo, en la rendija entre su caja y la pared": "Visto bueno, y c").
##
## What a place you go into has to give (game.gd _use_door): `door_out`, `out_spawn`, `out_h` on the street; `in_door`
## and `in_spawn` in the set; `open` (the shop's hours: optica.gd set_open keeps it). For Sistemas: `clerk_spot` and
## `clerk_h` (behind the counter, looking at the room), `client_spot` and `client_h` (before it), `probador_spot` and
## `probador_h` (before the long mirror, looking at the room). The room: 6 m wide, 9 deep; +z deeper in, the door at
## z = 0; looking in, +x is on your left.

const INSIDE := Vector2(2150.0, 650.0)          # where the set is: no street within 245 m, no tree of the map within
                                                # 285 m, no field, the other sets 820 m off or more (the Chinos's nearest)
const HALF := 3.0                               # half its width
const D := 9.0                                  # how deep it is
const TALL := 3.0
const PART := 6.5                               # the partition before the eyes' room
const DOORWAY := Vector2(0.7, 1.6)              # its open doorway (x from, to)
const DIR := "res://assets/optica/"
const COUNTER := Rect2(-2.2, 1.5, 0.8, 2.2)     # the counter: from x, from z, how wide (x), how long (z)
const MIRROR_Z := Vector2(4.55, 5.25)           # the long mirror on the right wall (z from, to)
const TEAL := 0x0a7060
const FRAMES := [0x1f1f22, 0x7a4a2a, 0xc8384a, 0x3a5a9a, 0xd8b84a, 0x2f2f36, 0x8a5a3a, 0xb8bcc0, 0x5a8a6a, 0x9a2a3a, 0x1a1a1c, 0xe8a0b0, 0x6a3a7a, 0xc0a060, 0x58b8c8, 0xf2f0ea]
const OLD := [0x6a3a1e, 0xc8a050, 0x3a2418, 0x9a6a3a, 0xd8b84a, 0x1f1f22, 0x8a4a2a]      # the vintage frames: tortoiseshell, gold, horn

var door_out: Vector2
var out_spawn: Vector2
var out_h := 0.0
var in_door: Vector2
var in_spawn: Vector2
var open := false               # the shop's hours (optica.gd)
var clerk_spot: Vector2         # behind the counter...
var clerk_h := 0.0              # ...looking at the room
var client_spot: Vector2        # before it
var client_h := 0.0
var probador_spot: Vector2      # before the long mirror...
var probador_h := PI / 2.0 + 0.45               # ...looking at the room, a little towards the door
var chair_spot: Vector2         # the eyes' chair (if Sistemas wants to sit you there)
var chair_h := PI / 2.0         # (it looks at the eye chart, on the wall at your left as you came in)
var saffron_spot: Vector2       # the hidden saffron (in the game's flowers, "id": "optica")
var props := 0
var glasses := 0                # how many pairs are shown (the self-test)
var _n := 0                     # (for the colours: the same every time)

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: StandardMaterial3D = null
	match (String(key) if key is String else ""):
		"suelo":            # big pale tiles
			var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
			for y in range(32):
				for x in range(32):
					var c := Color(0.86, 0.85, 0.82).lightened(0.02 * sin(x * 0.9 + y * 0.4))
					if x == 0 or y == 0:
						c = Color(0.7, 0.69, 0.66)
					img.set_pixel(x, y, c)
			m = StandardMaterial3D.new()
			m.albedo_texture = ImageTexture.create_from_image(img)
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3(1.0 / 0.6, 1.0, 1.0 / 0.6)
			m.roughness = 0.3
			m.emission_enabled = true
			m.emission = Color(0.86, 0.85, 0.82)
			m.emission_energy_multiplier = 0.18
		"pared":
			m = _lit(Color(0.97, 0.97, 0.96), 0.3)
		"verde":            # the wall behind the counter: the board's teal
			m = _lit(Color(0.1, 0.46, 0.4), 0.3)
		"techo":
			m = _lit(Color(0.96, 0.96, 0.95), 0.32)
		"calle":            # the street's light at the door and the windows
			m = _lit(Color(0.88, 0.94, 1.0), 1.4)
		"luz":
			m = _lit(Color(1.0, 0.99, 0.95), 1.8)
		"panel":            # the lit white wall of the new frames
			m = _lit(Color(0.98, 0.98, 0.97), 0.7)
		"tablero":          # the dark wood of the vintage cabinet
			m = _lit(Color(0.27, 0.17, 0.11), 0.12)
		"pano":             # its trays' green baize
			m = _lit(Color(0.14, 0.3, 0.2), 0.15)
		"cuero":            # the eyes' chair
			m = _lit(Color(0.09, 0.09, 0.1), 0.1)
		"espejo":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.7, 0.78, 0.82)
			m.metallic = 0.9
			m.roughness = 0.05
			m.emission_enabled = true
			m.emission = Color(0.7, 0.78, 0.82)
			m.emission_energy_multiplier = 0.25
		"cristal":          # the glass of the cases
			m = StandardMaterial3D.new()
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.75, 0.88, 0.9, 0.22)
			m.roughness = 0.1
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"mural", "horario", "optotipo", "novedades", "vintage", "placa":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(DIR + String(key) + ".png")
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			m.roughness = 0.9
			m.emission_enabled = true
			m.emission_texture = m.albedo_texture
			m.emission = Color.WHITE
			m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY      # (the picture's own colours, with no grey veil over them)
			m.emission_energy_multiplier = 0.9 if key == "optotipo" else 0.45         # (the eye chart is lit from behind)
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
	probador_spot = INSIDE + Vector2(-HALF + 0.75, (MIRROR_Z.x + MIRROR_Z.y) / 2.0)
	chair_spot = INSIDE + Vector2(-0.9, 7.8)
	_shell()
	_counter()
	_novedades()
	_vintage()
	_middle()
	_try_on()
	_partition()
	_eyes_room()
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

## the next colour of a frame (always the same sequence)
func _colour(shift := 0, list: Array = FRAMES) -> int:
	_n += 1
	return list[(_n * 7 + shift * 3 + (_n / 5)) % list.size()]

## A pair of glasses at x (its middle), its foot at y, its front at z, facing +z in the frame being built (turn it with
## _put): two lenses (dark if `sun`, clear if not), the frame round them, the bridge, the arms folded back. `round_`
## for the old round ones.
func _gafas(x: float, y: float, z: float, col: int, sun: bool, round_ := false) -> void:
	glasses += 1
	var lw := 0.05
	var lh := 0.038 if not round_ else 0.046
	var t := 0.006
	for side in [-1.0, 1.0]:
		var cx: float = x + side * 0.033
		if round_:
			box(cx - lh / 2.0, y, z - 0.004, lh, lh, 0.004, 0xb8ccd2)
			for q in [[cx - lh / 2.0 - t, y - t, lh + 2.0 * t, t], [cx - lh / 2.0 - t, y + lh, lh + 2.0 * t, t], [cx - lh / 2.0 - t, y, t, lh], [cx + lh / 2.0, y, t, lh]]:
				box(q[0], q[1], z - t, q[2], q[3], t, col)
		else:
			box(cx - lw / 2.0, y, z - 0.004, lw, lh, 0.004, 0x202428 if sun else 0xb8ccd2)
			box(cx - lw / 2.0 - t, y + lh, z - t, lw + 2.0 * t, t * 1.6, t, col)
			box(cx - lw / 2.0 - t, y - t, z - t, lw + 2.0 * t, t, t, col)
			box(cx + side * (lw / 2.0) - (t if side < 0.0 else 0.0), y, z - t, t, lh, t, col)
		box(cx + side * 0.03 - t / 2.0, y + lh * 0.7, z - 0.12, t, t * 1.4, 0.12, col)
	box(x - 0.012, y + lh * 0.7, z - t, 0.024, t, t, col)

# ---------------- the room ----------------
func _shell() -> void:
	quad(Vector3(-HALF, 0, 0), Vector3(HALF, 0, 0), Vector3(HALF, 0, D), Vector3(-HALF, 0, D), "suelo", Vector3.UP)
	quad(Vector3(-HALF, TALL, 0), Vector3(HALF, TALL, 0), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "techo", Vector3.DOWN)
	for sx in [-1.0, 1.0]:
		var x: float = sx * HALF
		quad(Vector3(x, 0, 0), Vector3(x, 0, D), Vector3(x, TALL, D), Vector3(x, TALL, 0), "pared", Vector3(-sx, 0, 0))
		box(x - (0.01 if sx > 0.0 else 0.0), 0.0, 0.0, 0.01, 0.08, D, 0xd8d6d0)                                      # (the skirting)
	quad(Vector3(-HALF, 0, D), Vector3(HALF, 0, D), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "pared", Vector3(0, 0, -1))
	box(-HALF, 0.0, D - 0.01, 2.0 * HALF, 0.08, 0.01, 0xd8d6d0)
	# the front from inside: the glass door in the middle, open while you are here; the shop's window at its left (the
	# back of its white steps), the little glass case at its right; the street bright beyond them
	var door := [-0.45, 0.45]
	var top := 2.3
	var win := [0.9, 2.5]
	var case_ := [-1.7, -0.9]
	var cuts: Array = [[-HALF, case_[0], 0.0, TALL], [case_[1], door[0], 0.0, TALL], [door[1], win[0], 0.0, TALL], [win[1], HALF, 0.0, TALL],
		[door[0], door[1], top, TALL], [win[0], win[1], 0.0, 0.75], [win[0], win[1], 2.2, TALL], [case_[0], case_[1], 0.0, 0.9], [case_[0], case_[1], 2.1, TALL]]
	for q in cuts:
		quad(Vector3(q[0], q[2], 0), Vector3(q[1], q[2], 0), Vector3(q[1], q[3], 0), Vector3(q[0], q[3], 0), "pared", Vector3(0, 0, 1))
	quad(Vector3(door[0], 0, -0.15), Vector3(door[1], 0, -0.15), Vector3(door[1], top, -0.15), Vector3(door[0], top, -0.15), "calle", Vector3(0, 0, 1))
	for p in [[win[0], win[1], 0.75, 2.2], [case_[0], case_[1], 0.9, 2.1]]:
		quad(Vector3(p[0], p[2], -0.15), Vector3(p[1], p[2], -0.15), Vector3(p[1], p[3], -0.15), Vector3(p[0], p[3], -0.15), "calle", Vector3(0, 0, 1))
		for x in [p[0], p[1] - 0.05]:
			box(x, p[2], -0.08, 0.05, p[3] - p[2], 0.1, 0x2c2826)
		box(p[0], p[2] - 0.05, -0.08, p[1] - p[0], 0.05, 0.14, 0x2c2826)
		box(p[0], p[3], -0.08, p[1] - p[0], 0.05, 0.1, 0x2c2826)
	box(win[0] + 0.04, 0.75, 0.0, win[1] - win[0] - 0.08, 0.12, 0.25, 0xf4f4f0)                                   # (the window's white steps, their backs)
	for x in [door[0] - 0.06, door[1]]:
		box(x, 0.0, -0.08, 0.06, top, 0.1, 0x2c2826)
	box(door[0] - 0.06, top, -0.08, door[1] - door[0] + 0.12, 0.06, 0.1, 0x2c2826)
	box(door[0] - 0.2, 0.0, 0.2, door[1] - door[0] + 0.4, 0.014, 0.8, 0x2a3a36)                                    # the mat
	quad(Vector3(0.62, 1.35, 0.012), Vector3(0.84, 1.35, 0.012), Vector3(0.84, 1.65, 0.012), Vector3(0.62, 1.65, 0.012), "horario", Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])                                               # (its hours, seen from inside: on the wall by the door)
	solid(Vector3(0, TALL / 2.0, -0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	solid(Vector3(0, TALL / 2.0, D + 0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	for sx in [-1.0, 1.0]:
		solid(Vector3(sx * (HALF + 0.2), TALL / 2.0, D / 2.0), Vector3(0.4, TALL, D + 0.8))
	solid(Vector3(0, TALL + 0.1, D / 2.0), Vector3(2.0 * HALF + 0.8, 0.2, D + 0.8))

# ---------------- the counter ----------------
## At your right as you come in: a white counter with a teal front, the till, the card machine, a tray of cloths, a
## rack of glasses cords; behind it the teal wall, its shelves of glasses cases and bottles of lens cleaner, her diploma.
func _counter() -> void:
	var x0 := COUNTER.position.x
	var x1 := COUNTER.end.x
	var z0 := COUNTER.position.y
	var z1 := COUNTER.end.y
	box(x0, 0.0, z0, x1 - x0, 0.95, z1 - z0, 0xf4f4f0)
	box(x0 - 0.03, 0.95, z0 - 0.03, x1 - x0 + 0.06, 0.04, z1 - z0 + 0.06, 0xf8f8f6)
	box(x1 - 0.01, 0.12, z0 + 0.1, 0.012, 0.7, z1 - z0 - 0.2, TEAL)                                 # its teal front
	_put(Vector3(x0 + 0.35, 0.99, z0 + 0.7), PI / 2.0)                              # the till: its drawer, its screen towards you
	box(-0.22, 0.0, -0.2, 0.44, 0.1, 0.4, 0x2a2a2e)
	box(-0.2, 0.1, -0.12, 0.4, 0.06, 0.24, 0x3a3a3e)
	bar(Vector3(0, 0.16, 0.05), Vector3(0, 0.42, 0.12), 0.04, 0.04, 0x2a2a2e)
	box(-0.17, 0.38, 0.1, 0.34, 0.24, 0.03, 0x1a1a1c)
	box(-0.15, 0.4, 0.13, 0.3, 0.2, 0.002, 0x4a7ab0)
	home()
	box(x0 + 0.55, 0.99, z0 + 1.3, 0.08, 0.04, 0.16, 0x2a2a2e)                      # the card machine
	box(x0 + 0.56, 1.03, z0 + 1.32, 0.06, 0.012, 0.08, 0x4a7ab0)
	box(x0 + 0.4, 0.99, z0 + 1.65, 0.3, 0.03, 0.22, 0xe8e4dc)                       # a tray of cloths, folded
	for k in range(3):
		box(x0 + 0.43, 1.02 + k * 0.012, z0 + 1.68 + k * 0.02, 0.24, 0.012, 0.14, [0x58b8c8, 0xe8a0b0, 0xd8b84a][k])
	_put(Vector3(x0 + 0.55, 0.99, z0 + 0.25), PI / 2.0)                             # a little stand of glasses, two pairs
	box(-0.12, 0.0, -0.05, 0.24, 0.12, 0.1, 0xf4f4f0)
	_gafas(-0.05, 0.12, 0.05, _colour(), false)
	_gafas(0.07, 0.04, 0.06, _colour(), true)
	home()
	# behind it: the teal wall, its shelves of glasses cases and bottles, her diploma
	quad(Vector3(-HALF + 0.005, 0, z0 - 0.4), Vector3(-HALF + 0.005, 0, z1 + 0.4), Vector3(-HALF + 0.005, TALL, z1 + 0.4), Vector3(-HALF + 0.005, TALL, z0 - 0.4), "verde", Vector3(1, 0, 0))
	for y in [1.15, 1.5]:
		box(-HALF, y, z0 - 0.2, 0.24, 0.025, z1 - z0 + 0.4, 0xf4f4f0)
		var z := z0 - 0.1
		var k := 0
		while z < z1 + 0.15:
			if k % 3 == 2:                                                             # (a bottle of lens cleaner)
				drum(Vector3(-HALF + 0.1, y + 0.025, z + 0.05), 0.03, 0.03, 0.16, 0xf2f2ee, 10)
				drum(Vector3(-HALF + 0.1, y + 0.185, z + 0.05), 0.012, 0.01, 0.04, 0x0a7060, 8)
			else:                                                                      # (glasses cases, a stack)
				for s in range(2 + k % 2):
					box(-HALF + 0.03, y + 0.025 + s * 0.045, z, 0.16, 0.044, 0.09, [0x1f1f22, TEAL, 0x7a4a2a, 0xc8384a][(k + s) % 4])
			z += 0.16
			k += 1
	pieces += 1                                                                        # her diploma, in a black frame
	box(-HALF, 1.85, z0 + 0.5, 0.03, 0.5, 0.66, 0x1a1a1c)
	quad(Vector3(-HALF + 0.032, 1.9, z0 + 0.55), Vector3(-HALF + 0.032, 1.9, z0 + 1.11), Vector3(-HALF + 0.032, 2.3, z0 + 1.11), Vector3(-HALF + 0.032, 2.3, z0 + 0.55), 0xf4efe0, Vector3(1, 0, 0))
	for k in range(4):
		box(-HALF + 0.034, 2.0 + k * 0.065, z0 + 0.63, 0.002, 0.018, 0.4 - (0.1 if k == 0 else 0.0), 0x6a6a68)
	_put(Vector3(-HALF + 0.035, 1.6, z1 + 0.15), PI / 2.0)                          # and the plate by it (the one on the street, her name)
	quad(Vector3(-0.17, 0.0, 0.0), Vector3(0.17, 0.0, 0.0), Vector3(0.17, 0.24, 0.0), Vector3(-0.17, 0.24, 0.0), "placa", Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	home()
	props += 6
	solid(Vector3(COUNTER.get_center().x, 0.5, COUNTER.get_center().y), Vector3(COUNTER.size.x, 1.0, COUNTER.size.y))
	for zs in [z0 - 0.05, z1 + 0.05]:                                              # (nobody goes behind it but who serves)
		solid(Vector3((-HALF + x0) / 2.0, 0.5, zs), Vector3(x0 + HALF, 1.0, 0.1))
	box(-HALF, 0.0, z0 - 0.08, x0 + HALF, 0.9, 0.05, 0xf4f4f0)                     # (a low flap at its ends)
	box(-HALF, 0.0, z1 + 0.03, x0 + HALF, 0.9, 0.05, 0xf4f4f0)

# ---------------- the new frames along the wall at your left ----------------
## A white wall lit from behind, seven rows of thin glass shelves, a pair on each place, "Novedades" over it.
func _novedades() -> void:
	var x := HALF
	var z0 := 0.8
	var z1 := 4.4
	box(x - 0.06, 0.0, z0 - 0.05, 0.06, 0.6, z1 - z0 + 0.1, 0xf4f4f0)                         # (its foot, a cupboard)
	box(x - 0.4, 0.0, z0, 0.4, 0.6, z1 - z0, 0xf4f4f0)
	pieces += 1
	quad(Vector3(x - 0.02, 0.6, z0), Vector3(x - 0.02, 0.6, z1), Vector3(x - 0.02, 2.4, z1), Vector3(x - 0.02, 2.4, z0), "panel", Vector3(-1, 0, 0))
	for z in [z0, z1]:
		box(x - 0.24, 0.6, z - 0.02, 0.24, 1.85, 0.04, 0xe8e8e4)
	for row in range(7):
		var y := 0.72 + row * 0.24
		box(x - 0.2, y, z0, 0.18, 0.01, z1 - z0, 0xc8dce0)
		_put(Vector3(x - 0.08, y + 0.01, 0.0), -PI / 2.0)                          # (facing the room: -x)
		var zz := z0 + 0.14
		while zz < z1 - 0.08:
			_gafas(zz, 0.0, 0.08, _colour(row), row >= 5)
			zz += 0.17
		home()
	_put(Vector3(x - 0.01, 2.5, (z0 + z1) / 2.0), -PI / 2.0)
	quad(Vector3(-0.7, 0.0, 0.0), Vector3(0.7, 0.0, 0.0), Vector3(0.7, 0.35, 0.0), Vector3(-0.7, 0.35, 0.0), "novedades", Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	home()
	solid(Vector3(x - 0.2, 1.2, (z0 + z1) / 2.0), Vector3(0.4, 2.4, z1 - z0))

# ---------------- the old frames past them ----------------
## A dark wooden cabinet: four shelves of green baize trays with round frames of tortoiseshell, gold and horn, a little
## brass lamp on top, "Vintage" over it.
func _vintage() -> void:
	var x := HALF
	var z0 := 4.7
	var z1 := 6.2
	var dd := 0.45
	box(x - dd, 0.0, z0, dd, 2.1, 0.05, "tablero")
	box(x - dd, 0.0, z1 - 0.05, dd, 2.1, 0.05, "tablero")
	box(x - 0.03, 0.0, z0, 0.03, 2.1, z1 - z0, "tablero")
	box(x - dd - 0.02, 2.1, z0 - 0.03, dd + 0.02, 0.06, z1 - z0 + 0.06, "tablero")
	box(x - dd, 0.0, z0, dd, 0.35, z1 - z0, "tablero")
	for k in range(4):
		var y := 0.35 + k * 0.44
		box(x - dd, y, z0, dd, 0.03, z1 - z0, "tablero")
		box(x - dd + 0.05, y + 0.03, z0 + 0.08, dd - 0.1, 0.02, z1 - z0 - 0.16, "pano")
		_put(Vector3(x - 0.2, y + 0.05, 0.0), -PI / 2.0)
		var zz := z0 + 0.22
		while zz < z1 - 0.15:
			_gafas(zz, 0.0, 0.08, _colour(k, OLD), false, true)
			zz += 0.2
		home()
	drum(Vector3(x - 0.25, 2.16, (z0 + z1) / 2.0), 0.07, 0.07, 0.02, 0xc8a050, 12)        # the brass lamp
	bar(Vector3(x - 0.25, 2.18, (z0 + z1) / 2.0), Vector3(x - 0.25, 2.45, (z0 + z1) / 2.0), 0.015, 0.015, 0xc8a050)
	drum(Vector3(x - 0.25, 2.42, (z0 + z1) / 2.0), 0.12, 0.06, 0.12, 0x2a5a3a, 12)
	_put(Vector3(x - 0.01, 2.62, (z0 + z1) / 2.0), -PI / 2.0)
	quad(Vector3(-0.5, 0.0, 0.0), Vector3(0.5, 0.0, 0.0), Vector3(0.5, 0.25, 0.0), Vector3(-0.5, 0.25, 0.0), "vintage", Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	home()
	props += 1
	solid(Vector3(x - dd / 2.0, 1.05, (z0 + z1) / 2.0), Vector3(dd, 2.1, z1 - z0))

# ---------------- the middle of the room ----------------
func _middle() -> void:
	_sun_tower(Vector2(1.3, 2.1))
	_low_case(Vector2(0.7, 4.3))

## a turning tower of sunglasses: a post, four faces of little shelves, a pair on each, a teal pair on its sign
func _sun_tower(at: Vector2) -> void:
	props += 1
	bar(Vector3(at.x, 0.0, at.y), Vector3(at.x, 1.75, at.y), 0.05, 0.05, 0xc0c4c8)
	drum(Vector3(at.x, 0.0, at.y), 0.28, 0.28, 0.03, 0xc0c4c8, 14)
	box(at.x - 0.14, 1.75, at.y - 0.14, 0.28, 0.24, 0.28, 0xf4f4f0)
	for face_ in range(4):
		var yaw := face_ * PI / 2.0
		_put(Vector3(at.x, 0.0, at.y), yaw)
		for s in [-1.0, 1.0]:
			box(s * 0.045 - 0.03, 1.84, 0.141, 0.06, 0.05, 0.004, TEAL)
		for row in range(7):
			var y := 0.35 + row * 0.19
			box(-0.13, y, 0.1, 0.26, 0.012, 0.06, 0xd8dce0)
			_gafas(0.0, y + 0.014, 0.17, _colour(row + face_), true)
		home()
	solid(Vector3(at.x, 0.9, at.y), Vector3(0.5, 1.8, 0.5))

## a low glass case along the room: a white foot, the glass, sunglasses and frames on dark velvet in four rows
func _low_case(at: Vector2) -> void:
	props += 1
	var w := 0.6
	var dd := 1.4
	var x0 := at.x - w / 2.0
	var z0 := at.y - dd / 2.0
	box(x0, 0.0, z0, w, 0.75, dd, 0xf4f4f0)
	box(x0 + 0.03, 0.75, z0 + 0.03, w - 0.06, 0.02, dd - 0.06, 0x24242a)
	_put(Vector3(at.x, 0.77, at.y), PI)                                              # (facing the door)
	for i in range(3):
		for j in range(6):
			var px := -0.18 + i * 0.18
			var pz := -0.55 + j * 0.22
			_gafas(px, 0.0, pz, _colour(i + j), (i + j) % 2 == 0)
	home()
	var y1 := 1.0
	pieces += 1
	quad(Vector3(x0, 0.77, z0), Vector3(x0 + w, 0.77, z0), Vector3(x0 + w, y1, z0), Vector3(x0, y1, z0), "cristal", Vector3(0, 0, -1))
	quad(Vector3(x0, 0.77, z0 + dd), Vector3(x0 + w, 0.77, z0 + dd), Vector3(x0 + w, y1, z0 + dd), Vector3(x0, y1, z0 + dd), "cristal", Vector3(0, 0, 1))
	quad(Vector3(x0, 0.77, z0), Vector3(x0, 0.77, z0 + dd), Vector3(x0, y1, z0 + dd), Vector3(x0, y1, z0), "cristal", Vector3(-1, 0, 0))
	quad(Vector3(x0 + w, 0.77, z0), Vector3(x0 + w, 0.77, z0 + dd), Vector3(x0 + w, y1, z0 + dd), Vector3(x0 + w, y1, z0), "cristal", Vector3(1, 0, 0))
	quad(Vector3(x0, y1, z0), Vector3(x0 + w, y1, z0), Vector3(x0 + w, y1, z0 + dd), Vector3(x0, y1, z0 + dd), "cristal", Vector3.UP)
	for c in [Vector3(x0, 0.75, z0), Vector3(x0 + w, 0.75, z0), Vector3(x0, 0.75, z0 + dd), Vector3(x0 + w, 0.75, z0 + dd)]:
		box(c.x - 0.012, c.y, c.z - 0.012, 0.024, y1 - 0.75 + 0.01, 0.024, 0xc0c4c8)
	solid(Vector3(at.x, 0.5, at.y), Vector3(w, 1.0, dd))

# ---------------- where you try glasses on ----------------
## On the right wall past the counter: a long mirror in a pale frame (you stand before it: probador_spot), a little
## round table with a mirror on a stand, a tray of frames and a stool.
func _try_on() -> void:
	var x := -HALF
	box(x, 0.25, MIRROR_Z.x - 0.04, 0.03, 1.95, MIRROR_Z.y - MIRROR_Z.x + 0.08, 0xd8d0c0)
	quad(Vector3(x + 0.032, 0.3, MIRROR_Z.x), Vector3(x + 0.032, 0.3, MIRROR_Z.y), Vector3(x + 0.032, 2.15, MIRROR_Z.y), Vector3(x + 0.032, 2.15, MIRROR_Z.x), "espejo", Vector3(1, 0, 0))
	props += 1
	var t := Vector2(-2.4, 5.95)
	drum(Vector3(t.x, 0.0, t.y), 0.2, 0.2, 0.03, 0xf4f4f0, 14)
	bar(Vector3(t.x, 0.0, t.y), Vector3(t.x, 0.72, t.y), 0.06, 0.06, 0xf4f4f0)
	drum(Vector3(t.x, 0.72, t.y), 0.4, 0.4, 0.03, 0xf8f8f6, 18)
	_put(Vector3(t.x - 0.12, 0.75, t.y - 0.1), PI / 2.0 + 0.4)                     # the mirror on its stand, turned to the stool
	box(-0.04, 0.0, -0.06, 0.08, 0.02, 0.12, 0xc0c4c8)
	bar(Vector3(0, 0.02, 0), Vector3(0, 0.2, 0), 0.015, 0.015, 0xc0c4c8)
	box(-0.13, 0.2, -0.012, 0.26, 0.2, 0.012, 0xc0c4c8)
	quad(Vector3(-0.12, 0.21, 0.001), Vector3(0.12, 0.21, 0.001), Vector3(0.12, 0.39, 0.001), Vector3(-0.12, 0.39, 0.001), "espejo", Vector3(0, 0, 1))
	home()
	_put(Vector3(t.x + 0.12, 0.75, t.y + 0.12), 0.3)                                # a tray of frames to try
	box(-0.15, 0.0, -0.1, 0.3, 0.02, 0.2, 0x24242a)
	for k in range(3):
		_gafas(-0.09 + k * 0.09, 0.02, -0.05 + (k % 2) * 0.08, _colour(k), false)
	home()
	props += 2
	drum(Vector3(t.x + 0.55, 0.0, t.y + 0.1), 0.17, 0.17, 0.48, TEAL, 14)          # its stool
	drum(Vector3(t.x + 0.55, 0.48, t.y + 0.1), 0.19, 0.19, 0.04, 0x1f1f22, 14)
	solid(Vector3(t.x, 0.4, t.y), Vector3(0.8, 0.8, 0.8))

# ---------------- the partition and the room where she tests your eyes ----------------
## Across the room before the back: white, the shop's name in green over it, an open doorway with a pale frame.
func _partition() -> void:
	var z := PART
	for q in [[-HALF, DOORWAY.x], [DOORWAY.y, HALF]]:
		box(q[0], 0.0, z, q[1] - q[0], TALL, 0.1, "pared")
		solid(Vector3((q[0] + q[1]) / 2.0, TALL / 2.0, z + 0.05), Vector3(q[1] - q[0], TALL, 0.1))
	box(DOORWAY.x, 2.2, z, DOORWAY.y - DOORWAY.x, TALL - 2.2, 0.1, "pared")
	for x in [DOORWAY.x - 0.06, DOORWAY.y]:
		box(x, 0.0, z - 0.02, 0.06, 2.26, 0.14, 0xd8d0c0)
	box(DOORWAY.x - 0.06, 2.2, z - 0.02, DOORWAY.y - DOORWAY.x + 0.12, 0.06, 0.14, 0xd8d0c0)
	box(DOORWAY.x - 0.04, 0.0, z + 0.12, 0.04, 2.15, 0.8, 0xe8e4dc)                                  # (its door, open against the wall inside)
	pieces += 1                                                                                       # the shop's name, facing the room
	quad(Vector3(0.5, 2.25, z - 0.005), Vector3(-2.7, 2.25, z - 0.005), Vector3(-2.7, 0.65, z - 0.005), Vector3(0.5, 0.65, z - 0.005), "mural", Vector3(0, 0, -1),
		[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])

## The room behind it: the black chair looking at the eye chart on the wall at your left, the column with its arm and the
## phoropter before the chair's head, a stool, the desk at the back with the box of trial lenses, the machine that
## reads your eyes and a screen.
func _eyes_room() -> void:
	var c := Vector3(chair_spot.x - INSIDE.x, 0.0, chair_spot.y - INSIDE.y)
	_put(c, PI / 2.0)                                                                 # the chair, facing +x (its front: +z here)
	drum(Vector3(0, 0, 0), 0.3, 0.3, 0.05, 0x3a3a3e, 14)
	bar(Vector3(0, 0.05, 0), Vector3(0, 0.42, 0), 0.12, 0.12, 0x5a5a5e)
	box(-0.28, 0.42, -0.25, 0.56, 0.14, 0.55, "cuero")
	box(-0.28, 0.56, -0.32, 0.56, 0.72, 0.12, "cuero")
	box(-0.14, 1.28, -0.32, 0.28, 0.2, 0.12, "cuero")
	for s in [-1.0, 1.0]:
		box(s * 0.3 - 0.05, 0.62, -0.2, 0.1, 0.06, 0.45, "cuero")
		bar(Vector3(s * 0.3, 0.42, 0.18), Vector3(s * 0.3, 0.62, 0.18), 0.03, 0.03, 0x5a5a5e)
	box(-0.2, 0.15, 0.32, 0.4, 0.04, 0.2, 0x3a3a3e)                                   # (its footrest)
	home()
	solid(c + Vector3(0, 0.6, 0), Vector3(0.7, 1.2, 0.7))
	var col := Vector3(c.x + 0.1, 0.0, c.z + 0.85)                                    # the column and its arm, at the chair's side
	box(col.x - 0.2, 0.0, col.z - 0.2, 0.4, 0.95, 0.4, 0xe8e8e4)
	box(col.x - 0.28, 0.95, col.z - 0.28, 0.56, 0.04, 0.56, 0xd8d8d4)
	bar(Vector3(col.x, 0.99, col.z), Vector3(col.x, 1.75, col.z), 0.08, 0.08, 0xd8d8d4)
	var ph := Vector3(c.x + 0.3, 1.3, c.z)                                             # the phoropter, before the chair's head
	bar(Vector3(col.x, 1.72, col.z), Vector3(ph.x, 1.72, ph.z), 0.06, 0.06, 0xd8d8d4)
	bar(Vector3(ph.x, 1.72, ph.z), Vector3(ph.x, ph.y + 0.14, ph.z), 0.03, 0.03, 0x9a9a9e)
	_put(ph, PI / 2.0)
	box(-0.32, -0.12, -0.05, 0.64, 0.26, 0.1, 0x3a3c42)
	for s in [-1.0, 1.0]:
		var e := Vector3(s * 0.15, 0.0, -0.05)
		_ring_z(e, 0.03, 0.11, 0.02, 0x2a2a2e)
		box(e.x - 0.025, -0.025, -0.07, 0.05, 0.05, 0.02, 0x9ab4bc)                     # (the lens it shows you)
		for k in range(6):
			var a := TAU * k / 6.0
			box(e.x + cos(a) * 0.08 - 0.012, sin(a) * 0.08 - 0.012, 0.05, 0.024, 0.024, 0.02, 0xd8d8d4)      # (its little knobs)
	box(-0.04, 0.12, -0.03, 0.08, 0.06, 0.06, 0x2a2a2e)
	home()
	props += 2
	solid(Vector3(col.x, 0.9, col.z), Vector3(0.5, 1.8, 0.5))
	# the eye chart on the wall at your left, lit from behind in its white box, which stands off the wall on two grey
	# brackets (its cable down the wall to a plug); in the slit behind it, on the lower bracket, the hidden saffron
	var ez := c.z
	var gap := 0.2
	box(HALF - gap - 0.08, 0.95, ez - 0.45, 0.08, 1.3, 0.9, 0xf4f4f0)
	quad(Vector3(HALF - gap - 0.081, 1.0, ez - 0.4), Vector3(HALF - gap - 0.081, 1.0, ez + 0.4), Vector3(HALF - gap - 0.081, 2.2, ez + 0.4), Vector3(HALF - gap - 0.081, 2.2, ez - 0.4), "optotipo", Vector3(-1, 0, 0),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	pieces += 1
	box(HALF - gap, 1.05, ez - 0.43, gap, 0.04, 0.86, 0x9a9a9e)                         # its brackets
	box(HALF - gap, 2.08, ez - 0.3, gap, 0.04, 0.6, 0x9a9a9e)
	bar(Vector3(HALF - gap * 0.5, 0.95, ez - 0.35), Vector3(HALF - 0.015, 0.32, ez - 0.35), 0.012, 0.012, 0xe8e8e4)      # its cable...
	box(HALF - 0.025, 0.26, ez - 0.4, 0.025, 0.1, 0.1, 0xf4f4f0)                        # ...and the plug
	_saffron(Vector3(HALF - gap * 0.5, 1.09, ez + 0.42))
	drum(Vector3(c.x + 0.9, 0.0, c.z + 0.55), 0.18, 0.18, 0.04, 0x3a3a3e, 12)         # her stool, on its foot
	bar(Vector3(c.x + 0.9, 0.04, c.z + 0.55), Vector3(c.x + 0.9, 0.5, c.z + 0.55), 0.04, 0.04, 0x9a9a9e)
	drum(Vector3(c.x + 0.9, 0.5, c.z + 0.55), 0.18, 0.18, 0.06, "cuero", 12)
	# the desk at the back: the box of trial lenses, the machine that reads your eyes, a screen
	var dz := D - 0.55
	box(0.3, 0.0, dz, 2.2, 0.75, 0.55, 0xf4f4f0)
	box(0.28, 0.75, dz - 0.02, 2.24, 0.03, 0.59, 0xe8e4dc)
	var tl := Vector3(0.55, 0.78, dz + 0.08)                                            # the box of trial lenses: open, its lid up
	box(tl.x, tl.y, tl.z, 0.55, 0.06, 0.36, 0x2a2a30)
	box(tl.x + 0.02, tl.y + 0.06, tl.z + 0.02, 0.51, 0.004, 0.32, 0x5a1e2a)
	for i in range(8):
		for j in range(4):
			drum(Vector3(tl.x + 0.05 + i * 0.064, tl.y + 0.064, tl.z + 0.06 + j * 0.08), 0.022, 0.022, 0.006, [0xc0c4c8, 0x101012][(i + j) % 2] if j < 3 else 0xd8b84a, 10)
	box(tl.x, tl.y + 0.06, tl.z + 0.36, 0.55, 0.32, 0.02, 0x2a2a30)
	var am := Vector3(1.55, 0.78, dz + 0.2)                                             # the machine: a grey body, its chin rest towards the room, its little screen
	box(am.x - 0.18, am.y, am.z - 0.15, 0.36, 0.08, 0.4, 0xd8d8d4)
	box(am.x - 0.12, am.y + 0.08, am.z - 0.05, 0.24, 0.32, 0.26, 0xe8e8e4)
	box(am.x - 0.1, am.y + 0.3, am.z - 0.08, 0.2, 0.06, 0.04, 0x2a2a2e)
	box(am.x - 0.09, am.y + 0.12, am.z + 0.21, 0.18, 0.14, 0.01, 0x1a2a3a)
	for s in [-1.0, 1.0]:
		bar(Vector3(am.x + s * 0.12, am.y + 0.08, am.z - 0.22), Vector3(am.x + s * 0.12, am.y + 0.42, am.z - 0.22), 0.015, 0.015, 0xc0c4c8)
	box(am.x - 0.12, am.y + 0.2, am.z - 0.24, 0.24, 0.02, 0.06, 0x2a2a2e)
	box(2.0, 0.78, dz + 0.35, 0.36, 0.26, 0.03, 0x1a1a1c)                               # a screen
	box(2.01, 0.83, dz + 0.349, 0.34, 0.2, 0.002, 0x4a7ab0)
	bar(Vector3(2.18, 0.78, dz + 0.4), Vector3(2.18, 0.83, dz + 0.4), 0.04, 0.04, 0x1a1a1c)
	props += 3
	solid(Vector3(1.4, 0.4, dz + 0.28), Vector3(2.2, 0.8, 0.56))

## The hidden saffron, behind the eye chart: a small flower standing on its lower bracket in the slit between its box and
## the wall, a little of its purple peeping out past the box's edge. The flower is the game's to take away (just walking
## by: game.gd takes it within 1.26 m).
func _saffron(at: Vector3) -> void:
	props += 1
	var flower := Node3D.new()
	flower.add_child(Parts.part("cyl", 0x5f9c4a, Vector3(0, 0.22, 0), Vector3(0.025, 0.44, 0.025)))
	for k in range(5):
		flower.add_child(Parts.part("ball", 0x9b5de5, Vector3(cos(k * 1.257) * 0.09, 0.48, sin(k * 1.257) * 0.09), Vector3(0.085, 0.15, 0.085)))
	flower.add_child(Parts.part("ball", 0xe63946, Vector3(0, 0.54, 0), Vector3(0.04, 0.1, 0.04)))
	flower.position = at
	flower.scale = Vector3.ONE * 0.55                   # (small: it has to fit the slit)
	add_child(flower)
	saffron_spot = INSIDE + Vector2(at.x, at.z)
	var game = W.get_parent()                           # (the game: the world is its child)
	if game != null and game.get("flowers") != null:
		(game.flowers as Array).append({"node": flower, "p": saffron_spot, "id": "optica", "hidden": true})      # (hidden: Sistemas keeps count of these)

## a ring in the frame being built, its axis along z (its middle at c): radius r0 inside, r1 outside, hw half its depth
func _ring_z(c: Vector3, r0: float, r1: float, hw: float, key, n := 16) -> void:
	pieces += 1
	for i in range(n):
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var p0 := Vector3(cos(a0), sin(a0), 0)
		var p1 := Vector3(cos(a1), sin(a1), 0)
		var nm := ((p0 + p1) / 2.0).normalized()
		for s in [-1.0, 1.0]:
			var off := Vector3(0, 0, s * hw)
			quad(c + off + p0 * r1, c + off + p1 * r1, c + off + p1 * r0, c + off + p0 * r0, key, Vector3(0, 0, s))
		quad(c + Vector3(0, 0, -hw) + p0 * r1, c + Vector3(0, 0, -hw) + p1 * r1, c + Vector3(0, 0, hw) + p1 * r1, c + Vector3(0, 0, hw) + p0 * r1, key, nm)

func _lamps() -> void:
	for z in [1.5, 3.3, 5.1, 7.4, 8.4]:
		for x in [-1.8, 0.0, 1.8]:
			drum(Vector3(x, TALL - 0.02, z), 0.09, 0.09, 0.018, "luz", 12)
			drum(Vector3(x, TALL - 0.008, z), 0.11, 0.11, 0.008, 0xd8d6cc, 12)
	for at in [Vector3(0.0, 2.5, 2.0), Vector3(0.0, 2.5, 4.8), Vector3(-2.3, 2.3, 2.6), Vector3(2.3, 2.3, 3.5), Vector3(0.0, 2.5, 7.8)]:
		var lamp := OmniLight3D.new()
		lamp.position = at
		lamp.light_color = Color(1.0, 0.97, 0.92)
		lamp.omni_range = 5.0
		lamp.light_energy = 0.45
		lamp.shadow_enabled = false
		lamp.light_cull_mask = 1 << 10
		add_child(lamp)
