extends "res://scripts/obra.gd"
## The inside of the Banco Cantabria, the bank at the corner of the Calle del Teniente Infante (bancosancho.gd builds its
## front and its cash machine). The user, 21 November 2026, through Sistemas, for the missions of the house: the bank
## walked into by the green arrow like the shops (entradas.gd), with a desk for the branch's manager -- a character the
## user asked for, whom Sistemas places and gives his lines: nobody is modelled here. A set built far out in the fields,
## like the copy shop's next door (copisteria_dentro.gd).
##
## A town's branch of a bank, not a copy of any: pale tiles, white walls under the bank's red band, its name on the back
## wall; on the left as you come in, the chairs of those who wait, a low table of leaflets and a plant; across the back
## the counter of the tellers behind its glass, the posts and the red tape of the queue before it, the door of the
## strongroom behind; on the right the manager's corner behind a low screen of glass: his desk with its screen, papers
## and name plate, his chair, two for whoever comes to see him, a cabinet of files, a calendar.
##
## What a place you go into has to give (game.gd _use_door): `door_out`, `out_spawn`, `out_h` on the street; `in_door`
## and `in_spawn` in the set; `open` (the bank's hours: bancosancho.gd set_open keeps it). For Sistemas: `manager_spot`
## and `manager_h` (where the manager is and which way he looks), `client_spot` and `client_h` (where you stand before
## his desk), `counter_front` (before the tellers). The room: 9 m wide, 10 deep; +z deeper in, the door at z = 0.

const INSIDE := Vector2(-1840.0, 1320.0)        # where the set is (no street within 350 m; the other sets far off)
const HALF := 4.5                               # half its width
const D := 10.0                                 # how deep it is
const TALL := 3.2
const COUNTER := 7.2                            # where the tellers' counter's front is
const DESK := Vector2(2.7, 3.6)                 # the manager's desk, its middle
const RED := 0xda2226
const DIR := "res://assets/bancosancho/"

var door_out: Vector2
var out_spawn: Vector2
var out_h := 0.0
var in_door: Vector2
var in_spawn: Vector2
var open := false               # the bank's hours (bancosancho.gd)
var manager_spot: Vector2       # where the manager is, behind his desk
var manager_h := 0.0            # which way he looks there (at whoever sits before him)
var client_spot: Vector2        # where you stand before his desk
var client_h := 0.0             # ...looking at him
var counter_front: Vector2      # before the tellers' counter
var props := 0

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: StandardMaterial3D = null
	match (String(key) if key is String else ""):
		"suelo":            # pale tiles, sixty centimetres, a greyer one here and there
			var img := Image.create(4, 4, false, Image.FORMAT_RGB8)
			for y in range(4):
				for x in range(4):
					img.set_pixel(x, y, Parts.col(0xe6e3dc if (x + y * 3) % 5 != 0 else 0xd6d3cc))
			m = StandardMaterial3D.new()
			m.albedo_texture = ImageTexture.create_from_image(img)
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE / 2.4
			m.roughness = 0.5
			m.emission_enabled = true
			m.emission = Color(0.9, 0.89, 0.86)
			m.emission_energy_multiplier = 0.2
		"pared":
			m = _lit(Color(0.96, 0.95, 0.93), 0.28)
		"techo":
			m = _lit(Color(0.95, 0.95, 0.94), 0.3)
		"calle":            # the street's light at the door and the windows
			m = _lit(Color(0.86, 0.93, 1.0), 1.4)
		"luz":
			m = _lit(Color(1.0, 0.98, 0.94), 1.6)
		"pantalla":
			m = _lit(Color(0.2, 0.42, 0.72), 0.9)
		"cristal":          # the tellers' glass, the manager's screen
			m = StandardMaterial3D.new()
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.72, 0.84, 0.88, 0.28)
			m.roughness = 0.2
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"banco", "cartel_banco":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(DIR + String(key) + ".png")
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			m.emission_enabled = true
			m.emission_texture = m.albedo_texture
			m.emission = Color.WHITE
			m.emission_energy_multiplier = 0.08          # (hardly any: under the lamps a brighter one washed its red out to pink)
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
	in_spawn = INSIDE + Vector2(0.0, 2.2)
	manager_spot = INSIDE + DESK + Vector2(1.05, 0.0)
	manager_h = atan2(-1.0, 0.0)                    # (looking across his desk: -x)
	client_spot = INSIDE + DESK + Vector2(-1.25, 0.0)
	client_h = atan2(1.0, 0.0)
	counter_front = INSIDE + Vector2(-1.6, COUNTER - 0.8)
	_shell()
	_waiting()
	_counter()
	_manager()
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

# ---------------- the room ----------------
func _shell() -> void:
	quad(Vector3(-HALF, 0, 0), Vector3(HALF, 0, 0), Vector3(HALF, 0, D), Vector3(-HALF, 0, D), "suelo", Vector3.UP)
	quad(Vector3(-HALF, TALL, 0), Vector3(HALF, TALL, 0), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "techo", Vector3.DOWN)
	quad(Vector3(-HALF, 0, D), Vector3(HALF, 0, D), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "pared", Vector3(0, 0, -1))
	quad(Vector3(-HALF, 0, 0), Vector3(-HALF, 0, D), Vector3(-HALF, TALL, D), Vector3(-HALF, TALL, 0), "pared", Vector3(1, 0, 0))
	quad(Vector3(HALF, 0, 0), Vector3(HALF, 0, D), Vector3(HALF, TALL, D), Vector3(HALF, TALL, 0), "pared", Vector3(-1, 0, 0))
	# the front from inside: the glass door in the middle, a window at each side, bright with the street
	var door := [-1.15, 1.15]
	var wins: Array = [[-4.0, -2.2], [2.2, 4.0]]
	var cuts: Array = [[-HALF, wins[0][0], 0.0, TALL], [wins[0][1], door[0], 0.0, TALL], [door[1], wins[1][0], 0.0, TALL], [wins[1][1], HALF, 0.0, TALL], [door[0], door[1], 2.55, TALL]]
	for w in wins:
		cuts.append([w[0], w[1], 2.55, TALL])
		cuts.append([w[0], w[1], 0.0, 0.55])
	for q in cuts:
		quad(Vector3(q[0], q[2], 0), Vector3(q[1], q[2], 0), Vector3(q[1], q[3], 0), Vector3(q[0], q[3], 0), "pared", Vector3(0, 0, 1))
	quad(Vector3(door[0], 0, -0.15), Vector3(door[1], 0, -0.15), Vector3(door[1], 2.55, -0.15), Vector3(door[0], 2.55, -0.15), "calle", Vector3(0, 0, 1))
	for x in [door[0], -0.03, door[1] - 0.06]:
		box(x, 0.0, -0.08, 0.06, 2.55, 0.08, 0x2a2a2c)
	box(door[0], 2.49, -0.08, door[1] - door[0], 0.06, 0.08, 0x2a2a2c)
	for w in wins:
		quad(Vector3(w[0], 0.55, -0.15), Vector3(w[1], 0.55, -0.15), Vector3(w[1], 2.55, -0.15), Vector3(w[0], 2.55, -0.15), "calle", Vector3(0, 0, 1))
		box(w[0], 0.5, 0.0, w[1] - w[0], 0.05, 0.25, 0x9a9a98)
		box(w[0] + 0.25, 0.7, -0.1, 1.05, 1.6, 0.02, 0xb8a8a8)        # (the back of the poster in the window)
	box(door[0] - 0.2, 0.0, 0.3, door[1] - door[0] + 0.4, 0.012, 1.0, 0x3a3c40)             # the mat
	# the bank's red band round the walls, a grey skirting, its name on the back wall, a poster, a clock
	for q in [[-HALF + 0.004, 0.0, 0.01, D], [HALF - 0.014, 0.0, 0.01, D]]:
		box(q[0], 2.5, q[1], q[2], 0.22, q[3], RED)
		box(q[0], 0.0, q[1], q[2], 0.1, q[3], 0x8a8a88)
	box(-HALF, 2.5, D - 0.014, 2.0 * HALF, 0.22, 0.01, RED)
	box(-HALF, 0.0, D - 0.014, 2.0 * HALF, 0.1, 0.01, 0x8a8a88)
	_face_z(Vector3(-1.95, 1.75, D - 0.02), 3.9, 0.585, "banco")
	_put(Vector3(-HALF + 0.02, 0.0, 4.6), PI / 2.0)
	_face_z(Vector3(-0.55, 0.75, 0.0), 1.1, 1.76, "cartel_banco", true)
	home()
	_put(Vector3(HALF - 0.02, 2.05, 6.3), -PI / 2.0)                                       # the clock
	var keep := _xf
	_xf = _xf * Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO)
	drum(Vector3.ZERO, 0.2, 0.2, 0.03, 0x2a2a2c, 16)
	drum(Vector3(0, 0.031, 0), 0.17, 0.17, 0.002, 0xf6f4ee, 16)
	_xf = keep
	box(-0.008, 0.0, 0.034, 0.016, 0.12, 0.004, 0x1a1a1c)
	box(0.0, -0.008, 0.034, 0.09, 0.016, 0.004, 0x1a1a1c)
	home()
	solid(Vector3(0, TALL / 2.0, -0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	solid(Vector3(0, TALL / 2.0, D + 0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	for sx in [-1.0, 1.0]:
		solid(Vector3(sx * (HALF + 0.2), TALL / 2.0, D / 2.0), Vector3(0.4, TALL, D + 0.8))
	solid(Vector3(0, TALL + 0.1, D / 2.0), Vector3(2.0 * HALF + 0.8, 0.2, D + 0.8))

## a picture on a wall that faces -z (or, with `front`, +z of the frame it is put in): its lower left corner, its size
func _face_z(at: Vector3, w: float, h: float, key, front := false) -> void:
	var z := at.z
	if front:
		quad(Vector3(at.x, at.y, z), Vector3(at.x + w, at.y, z), Vector3(at.x + w, at.y + h, z), Vector3(at.x, at.y + h, z), key, Vector3(0, 0, 1),
				[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	else:
		quad(Vector3(at.x + w, at.y, z), Vector3(at.x, at.y, z), Vector3(at.x, at.y + h, z), Vector3(at.x + w, at.y + h, z), key, Vector3(0, 0, -1),
				[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

## a chair: four legs of steel, a seat and a back of its colour
func _chair(at: Vector3, yaw: float, hex, wheels := false) -> void:
	_put(at, yaw)
	if wheels:
		drum(Vector3(0, 0.0, 0), 0.28, 0.05, 0.08, 0x2a2a2c, 10)
		drum(Vector3(0, 0.08, 0), 0.035, 0.035, 0.36, 0x6a6c70, 8)
	else:
		for sx in [-0.2, 0.2]:
			for sz in [-0.2, 0.2]:
				box(sx - 0.015, 0.0, sz - 0.015, 0.03, 0.44, 0.03, 0x8a8c90)
	box(-0.24, 0.44, -0.24, 0.48, 0.07, 0.48, hex)
	box(-0.24, 0.51, 0.19, 0.48, 0.5 if not wheels else 0.62, 0.06, hex)
	home()
	solid(at + Vector3(0, 0.35, 0), Vector3(0.5, 0.7, 0.5))

## a plant in its pot
func _plant(at: Vector3, tall: float) -> void:
	_put(at)
	drum(Vector3.ZERO, 0.17, 0.22, 0.4, 0xb8b4aa, 10)
	drum(Vector3(0, 0.4, 0), 0.03, 0.03, tall * 0.4, 0x5a4a32, 6)
	for k in range(5):
		var a := TAU * k / 5.0
		ball(Vector3(cos(a) * 0.18, 0.4 + tall * (0.45 + 0.1 * (k % 2)), sin(a) * 0.18), 0.22, 0x3f7a3a, 1.3, 7, 4)
	ball(Vector3(0, 0.4 + tall * 0.75, 0), 0.24, 0x4a8a44, 1.3, 7, 4)
	home()
	solid(at + Vector3(0, 0.5, 0), Vector3(0.5, 1.0, 0.5))

## a screen on its foot, a keyboard before it: facing +z of where it is put
func _screen(at: Vector3, yaw: float) -> void:
	_put(at, yaw)
	box(-0.1, 0.0, -0.08, 0.2, 0.02, 0.16, 0x2a2a2c)
	box(-0.02, 0.02, -0.02, 0.04, 0.14, 0.04, 0x2a2a2c)
	box(-0.26, 0.14, -0.02, 0.52, 0.32, 0.03, 0x1e1e20)
	box(-0.24, 0.16, 0.01, 0.48, 0.28, 0.004, "pantalla")
	box(-0.2, 0.0, 0.16, 0.4, 0.015, 0.13, 0x3a3a3e)
	home()

# ---------------- who waits ----------------
## on the left as you come in: four red chairs along the wall, a low table of leaflets, a stand of them, a plant
func _waiting() -> void:
	for i in range(4):
		_chair(Vector3(-HALF + 0.4, 0.0, 1.6 + i * 0.62), -PI / 2.0, RED)
	_put(Vector3(-HALF + 1.5, 0.0, 2.5))
	box(-0.35, 0.36, -0.55, 0.7, 0.04, 1.1, 0xd9d6cc)
	for sx in [-0.3, 0.26]:
		for sz in [-0.5, 0.46]:
			box(sx, 0.0, sz, 0.04, 0.36, 0.04, 0x8a8c90)
	for k in range(3):
		box(-0.25 + k * 0.16, 0.4, -0.3 + k * 0.25, 0.21, 0.01, 0.3, [0xf4f1ea, RED, 0x2a62a8][k])
	home()
	solid(Vector3(-HALF + 1.5, 0.2, 2.5), Vector3(0.7, 0.4, 1.1))
	_put(Vector3(-HALF + 0.25, 0.0, 5.6), PI / 2.0)        # the stand of leaflets
	box(-0.3, 0.0, 0.0, 0.6, 1.5, 0.05, 0x9a9da0)
	for r in range(4):
		box(-0.28, 0.25 + r * 0.32, 0.05, 0.56, 0.03, 0.1, 0x9a9da0)
		for c in range(3):
			box(-0.24 + c * 0.18, 0.28 + r * 0.32, 0.06, 0.14, 0.22, 0.03, [0xf4f1ea, RED, 0x2a62a8, 0xf2c230][(r + c) % 4])
	home()
	solid(Vector3(-HALF + 0.3, 0.75, 5.6), Vector3(0.4, 1.5, 0.6))
	_plant(Vector3(-HALF + 0.45, 0.0, 0.7), 1.3)
	_plant(Vector3(HALF - 0.45, 0.0, 0.7), 1.3)

# ---------------- the tellers ----------------
## Across the back: the counter, pale over a red foot, glass over it between steel posts with a gap to speak through
## at each of its two places; a screen and a tray at each; before it the posts and red tape of the queue; behind it the
## cabinets of files, a printer and the round door of the strongroom.
func _counter() -> void:
	var x0 := -HALF
	var x1 := 1.2
	box(x0, 0.0, COUNTER, x1 - x0, 1.05, 0.6, 0xe9e6de)
	box(x0, 0.0, COUNTER - 0.012, x1 - x0, 0.3, 0.012, RED)
	box(x0, 1.05, COUNTER - 0.08, x1 - x0, 0.04, 0.76, 0xcfccc4)
	box(x1, 0.0, COUNTER, 0.12, 2.3, 0.6, 0xe9e6de)                          # (its end, a pier)
	for i in range(4):
		box(x0 + 0.05 + i * (x1 - x0 - 0.1) / 3.0 - 0.02, 1.09, COUNTER + 0.1, 0.04, 1.2, 0.04, 0x9a9da0)
	box(x0, 1.3, COUNTER + 0.11, x1 - x0, 1.0, 0.012, "cristal")
	box(x0, 2.27, COUNTER + 0.08, x1 - x0, 0.06, 0.08, 0x9a9da0)
	for cx in [-3.2, -0.9]:
		_screen(Vector3(cx + 0.5, 1.09, COUNTER + 0.3), 0.0)
		box(cx - 0.3, 1.09, COUNTER + 0.05, 0.4, 0.02, 0.26, 0x2a2a2c)          # the tray under the glass
		_chair(Vector3(cx + 0.3, 0.0, COUNTER + 1.3), 0.0, 0x2a2a2e, true)
	solid(Vector3((x0 + x1) / 2.0 + 0.06, 1.15, COUNTER + 0.3), Vector3(x1 - x0 + 0.12, 2.3, 0.7))
	# the queue: four posts, red tape between them
	var posts: Array = [Vector2(-3.4, COUNTER - 1.5), Vector2(-1.2, COUNTER - 1.5), Vector2(-1.2, COUNTER - 2.9), Vector2(-3.4, COUNTER - 2.9)]
	for i in range(posts.size()):
		var p: Vector2 = posts[i]
		drum(Vector3(p.x, 0.0, p.y), 0.16, 0.14, 0.03, 0x9a9da0, 10)
		drum(Vector3(p.x, 0.03, p.y), 0.025, 0.025, 0.92, 0x9a9da0, 8)
		solid(Vector3(p.x, 0.5, p.y), Vector3(0.2, 1.0, 0.2))
		if i < posts.size() - 1:
			var q: Vector2 = posts[i + 1]
			bar(Vector3(p.x, 0.9, p.y), Vector3(q.x, 0.9, q.y), 0.012, 0.05, RED)
	props += 1
	# behind the counter: cabinets, the printer, the strongroom's door
	for i in range(3):
		box(-HALF + 0.05 + i * 0.62, 0.0, D - 0.5, 0.58, 1.3, 0.48, 0xb8bcc0)
		for r in range(3):
			box(-HALF + 0.09 + i * 0.62, 0.1 + r * 0.4, D - 0.52, 0.5, 0.34, 0.02, 0xa8acb0)
			box(-HALF + 0.27 + i * 0.62, 0.3 + r * 0.4, D - 0.54, 0.14, 0.03, 0.02, 0x6a6c70)
	box(-2.1, 0.0, D - 0.6, 0.7, 0.75, 0.55, 0xd9d6cc)
	box(-2.05, 0.75, D - 0.55, 0.6, 0.3, 0.45, 0xe9e6e0)
	_put(Vector3(0.1, 1.15, D - 0.03), PI)                                      # the strongroom: a round door of steel, its wheel
	var keep := _xf
	_xf = _xf * Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO)
	drum(Vector3.ZERO, 1.0, 1.0, 0.08, 0x8a8e94, 20)
	drum(Vector3(0, 0.08, 0), 0.85, 0.85, 0.05, 0xa8acb2, 20)
	drum(Vector3(0, 0.13, 0), 0.12, 0.12, 0.08, 0x5a5c60, 10)
	_xf = keep
	for k in range(4):
		var a := TAU * k / 4.0 + 0.4
		bar(Vector3(0, 0, 0.17), Vector3(cos(a) * 0.36, sin(a) * 0.36, 0.17), 0.035, 0.035, 0x5a5c60)
	home()

# ---------------- the manager ----------------
## On the right: a low screen of glass round his corner; his desk of dark wood with its screen, its papers, the phone
## and his name plate; his chair behind it, two before it for whoever comes; a cabinet of files with a plant on it; a
## calendar on the wall. He is not here: Sistemas puts him at `manager_spot`, looking the way of `manager_h`.
func _manager() -> void:
	var c := DESK
	# the screen of glass: along the room's middle, with its way in before the desk
	for q in [[1.3, 1.9, 1.3, 2.7], [1.3, 4.7, 1.3, 5.6]]:
		var a := Vector3(q[0], 0.0, q[1])
		var b := Vector3(q[2], 0.0, q[3])
		box(a.x - 0.03, 0.0, a.z, 0.06, 0.9, b.z - a.z, 0xe9e6de)
		box(a.x - 0.006, 0.9, a.z, 0.012, 0.7, b.z - a.z, "cristal")
		box(a.x - 0.02, 1.6, a.z, 0.04, 0.04, b.z - a.z, 0x9a9da0)
		solid(Vector3(a.x, 0.8, (a.z + b.z) / 2.0), Vector3(0.1, 1.6, b.z - a.z))
	box(1.3, 0.0, 5.57, HALF - 1.3, 0.9, 0.06, 0xe9e6de)
	box(1.3, 0.9, 5.594, HALF - 1.3, 0.7, 0.012, "cristal")
	box(1.3, 1.6, 5.58, HALF - 1.3, 0.04, 0.04, 0x9a9da0)
	solid(Vector3((1.3 + HALF) / 2.0, 0.8, 5.6), Vector3(HALF - 1.3, 1.6, 0.1))
	# the desk: its top, its two ends, a front panel towards whoever comes
	box(c.x - 0.45, 0.72, c.y - 0.9, 0.9, 0.05, 1.8, 0x5a3a26)
	for sz in [-0.88, 0.83]:
		box(c.x - 0.42, 0.0, c.y + sz, 0.84, 0.72, 0.05, 0x4a3020)
	box(c.x - 0.42, 0.15, c.y - 0.86, 0.04, 0.57, 1.72, 0x4a3020)
	solid(Vector3(c.x, 0.4, c.y), Vector3(0.9, 0.8, 1.8))
	_screen(Vector3(c.x + 0.1, 0.77, c.y - 0.5), PI / 2.0)
	box(c.x - 0.3, 0.77, c.y + 0.05, 0.3, 0.012, 0.42, 0xf6f4ee)                # papers, a pen on them
	box(c.x - 0.22, 0.782, c.y + 0.12, 0.02, 0.012, 0.16, 0x1a2a6a)
	box(c.x - 0.05, 0.77, c.y + 0.5, 0.26, 0.05, 0.2, 0x2a2a2c)                  # the phone
	box(c.x - 0.03, 0.82, c.y + 0.52, 0.06, 0.03, 0.16, 0x1e1e20)
	_put(Vector3(c.x - 0.36, 0.77, c.y - 0.1), -PI / 2.0)                       # his name plate, to whoever sits before him
	box(-0.14, 0.0, 0.0, 0.28, 0.07, 0.03, 0xc9a23a)
	home()
	props += 3
	_chair(Vector3(c.x + 1.05, 0.0, c.y), PI / 2.0, 0x2a2a2e, true)             # his
	_chair(Vector3(c.x - 1.1, 0.0, c.y - 0.45), -PI / 2.0, RED)                  # theirs
	_chair(Vector3(c.x - 1.1, 0.0, c.y + 0.45), -PI / 2.0, RED)
	# behind him: files, a plant on them, the calendar; a safe under the window side
	box(HALF - 0.5, 0.0, c.y + 0.5, 0.46, 1.1, 0.9, 0xb8bcc0)
	for r in range(3):
		box(HALF - 0.52, 0.08 + r * 0.34, c.y + 0.55, 0.02, 0.3, 0.8, 0xa8acb0)
	solid(Vector3(HALF - 0.27, 0.55, c.y + 0.95), Vector3(0.46, 1.1, 0.9))
	_put(Vector3(HALF - 0.27, 1.1, c.y + 0.95))
	drum(Vector3.ZERO, 0.1, 0.13, 0.16, 0xb0623a, 8)
	ball(Vector3(0, 0.3, 0), 0.2, 0x3f7a3a, 1.0, 7, 4)
	home()
	_put(Vector3(HALF - 0.02, 1.45, c.y - 0.6), -PI / 2.0)                       # the calendar
	box(-0.2, 0.0, 0.0, 0.4, 0.55, 0.012, 0xf6f4ee)
	box(-0.2, 0.42, 0.012, 0.4, 0.13, 0.004, RED)
	for r in range(4):
		for k in range(6):
			box(-0.17 + k * 0.058, 0.05 + r * 0.085, 0.012, 0.04, 0.05, 0.003, 0xd0d0cc)
	home()

func _lamps() -> void:
	for z in [1.8, 4.6, 7.6]:
		for x in [-2.4, 2.4]:
			cbox(Vector3(x, TALL - 0.03, z), Vector3(1.2, 0.04, 0.6), "luz")
			cbox(Vector3(x, TALL - 0.008, z), Vector3(1.3, 0.016, 0.7), 0xd9d6cc)
	for at in [Vector3(-2.0, 2.6, 2.4), Vector3(2.2, 2.6, 3.4), Vector3(-1.5, 2.6, 6.2), Vector3(0.0, 2.6, 8.8)]:
		var lamp := OmniLight3D.new()
		lamp.position = at
		lamp.light_color = Color(1.0, 0.98, 0.94)
		lamp.omni_range = 7.0
		lamp.light_energy = 0.5
		lamp.shadow_enabled = false
		lamp.light_cull_mask = 1 << 10
		add_child(lamp)
