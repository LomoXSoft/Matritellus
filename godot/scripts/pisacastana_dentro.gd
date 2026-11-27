extends "res://scripts/obra.gd"
## The inside of the shoe shop "Pisacastaña" of the corner of the Calle de los Arcos and the Calle Argentina
## (pisacastana.gd builds its fronts). The user, 23 November 2026: "Ahora la zapatería. Usaremos Pisamorena (que
## llamaremos Pisacastaña). Mismo tratamiento que las otras dos tiendas pero solo con zapatos". A set built far out in
## the fields, like the MaxiPrecio's and the Tetoqa's, walked into by the green arrow before its door (entradas.gd).
##
## FIRST DRAFT, before the user's pictures of the real inside (Google Maps shows them only signed in): a small shoe shop
## as the town's are, as its windows show it -- white walls, a floor of big pale tiles, little round lights in the
## ceiling, and shoes only. The door is at the front's right as you come in (on the street it is the last thing of the
## shop on the Calle Argentina); at its left the frosted glass and the window of shoes, and on the wall at your left the
## window to the Calle de los Arcos, both with a low white step of shoes behind the glass. Along the wall at your right,
## from the door to the back, a wall of sloping white shelves full of pairs; along the one at your left, past the
## window, another; in the middle a round table of shoes, a long padded bench to try them on with the shop's sloping
## stool before it, a low mirror on the floor; at the back the counter with the till before a wall of shoe boxes, and
## the shop's name over a low white step of boots on the turquoise back wall. Nobody is modelled (the user decides
## figures). A saffron flower is hidden in an open shoe box on the floor by the bench (the user, 23 Nov 2026, to the
## proposal "en una caja de zapatos abierta, en el suelo junto al banco": "Azafrán en caja de zapatos").
##
## Approved by the user as it is (23 Nov 2026: "Visto bueno [...] Así está bien el interior").
##
## What a place you go into has to give (game.gd _use_door): `door_out`, `out_spawn`, `out_h` on the street; `in_door`
## and `in_spawn` in the set; `open` (the shop's hours: pisacastana.gd set_open keeps it). For Sistemas, if somebody
## serves here: `clerk_spot` and `clerk_h` (behind the counter, looking at the room), `client_spot` and `client_h`
## (before it), `probador_spot` and `probador_h` (where you try shoes on, by the low mirror, looking back towards the
## door: 3.6 m free before it, a step free to its side). The room: 6.8 m wide, 9 deep; +z deeper in, the door at
## z = 0; looking in, +x is on your left.

const INSIDE := Vector2(-1400.0, -150.0)        # where the set is: no street within 249 m, no tree of the map within
                                                # 136 m, no field, the other sets 1124 m off or more
const HALF := 3.4                               # half its width
const D := 9.0                                  # how deep it is
const TALL := 3.0
const DIR := "res://assets/pisacastana/"
const DOOR := Vector2(-2.9, -1.9)               # the door in the front: from x, to x
const FROST := Vector2(-1.65, -0.25)            # the frosted glass by it
const WIN := Vector2(0.0, 3.2)                  # the window of shoes
const SIDE_WIN := Vector2(0.5, 3.25)            # the window to the Arcos, on the wall at your left: from z, to z
const COUNTER := Rect2(0.8, 7.0, 2.2, 0.65)     # the counter: from x, from z, how long (x), how deep (z)
const SHELF_D := 0.35                           # the shoe walls' depth
const TURQ := 0x7ec8c0
const COLOURS := [0x1f1f22, 0x6a3a22, 0xc8a070, 0x8a1f2a, 0xf2f0ea, 0x2a3a5a, 0xb07a52, 0xd8c8a8, 0x3a2a20, 0xc8384a,
	0x9a6a3a, 0x4a4a50, 0xe8b8a8, 0x2f5a3a, 0xd8a040, 0x7a5a8a]
const BOXES := [0xf2f0ea, 0xb08a5a, 0x2a2a2e, 0xd8c8a8, 0xc8603a, 0x8a5a3a, 0x7ec8c0]
const KINDS := ["zapato", "tacon", "bota", "deportiva", "bailarina", "sandalia", "tacon", "zapato", "botin"]

var door_out: Vector2
var out_spawn: Vector2
var out_h := 0.0
var in_door: Vector2
var in_spawn: Vector2
var open := false               # the shop's hours (pisacastana.gd)
var clerk_spot: Vector2         # behind the counter...
var clerk_h := PI               # ...looking at the room, towards the door (-z)
var client_spot: Vector2        # before it
var client_h := 0.0
var probador_spot: Vector2      # by the low mirror...
var probador_h := PI            # ...looking back towards the door
var props := 0
var pairs := 0                  # (how many pairs of shoes it shows: the self-test)
var saffron_spot: Vector2       # the hidden saffron (in the game's flowers, "id": "pisacastana")
var _n := 0                     # (for the colours: the same every time)

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: StandardMaterial3D = null
	match (String(key) if key is String else ""):
		"suelo":            # big pale tiles
			var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
			for y in range(64):
				for x in range(64):
					var c := Color(0.86, 0.84, 0.8).darkened(0.03 * ((x / 32 + y / 32) % 2))
					c = c.lightened(0.02 * sin(x * 0.37 + y * 0.21))
					if x % 32 == 0 or y % 32 == 0:
						c = Color(0.7, 0.68, 0.64)
					img.set_pixel(x, y, c)
			m = StandardMaterial3D.new()
			m.albedo_texture = ImageTexture.create_from_image(img)
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3(1.0 / 1.2, 1.0, 1.0 / 1.2)   # (tiles of 60 cm)
			m.roughness = 0.35
			m.emission_enabled = true
			m.emission = Color(0.86, 0.84, 0.8)
			m.emission_energy_multiplier = 0.16
		"pared":
			m = _lit(Color(0.97, 0.96, 0.95), 0.3)
		"turquesa":         # the back wall behind the name (the colour of the shop's tiles and glass on the street)
			m = _lit(Color(0.62, 0.84, 0.8), 0.3)
		"techo":
			m = _lit(Color(0.96, 0.96, 0.95), 0.32)
		"calle":            # the street's light at the door and the windows
			m = _lit(Color(0.88, 0.94, 1.0), 1.4)
		"esmerilado":       # the frosted glass by the door, the street's light through it
			m = _lit(Color(0.7, 0.9, 0.87), 0.9)
		"luz":
			m = _lit(Color(1.0, 0.99, 0.95), 1.8)
		"espejo":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.7, 0.78, 0.82)
			m.metallic = 0.9
			m.roughness = 0.05
			m.emission_enabled = true
			m.emission = Color(0.7, 0.78, 0.82)
			m.emission_energy_multiplier = 0.25
		"mural", "horario":
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
	var dx0 := (DOOR.x + DOOR.y) / 2.0
	in_door = INSIDE + Vector2(dx0, 0.45)
	in_spawn = INSIDE + Vector2(dx0, 1.4)
	clerk_spot = INSIDE + Vector2(COUNTER.get_center().x, (COUNTER.end.y + D) / 2.0 - 0.1)
	client_spot = INSIDE + Vector2(COUNTER.get_center().x, COUNTER.position.y - 0.55)
	probador_spot = INSIDE + Vector2(-1.0, 6.4)
	_shell()
	_shoe_wall(-1.0, 1.3, D - 0.4)                  # the wall at your right, from the door to the back
	_shoe_wall(1.0, SIDE_WIN.y + 0.35, COUNTER.position.y - 0.2)       # the one at your left, past the window
	_counter()
	_back_wall()
	_middle()
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

# ---------------- the shoes ----------------
## a pair of shoes at x (their middle), standing at y, their middle at z, their toes to +z
func _pair(x: float, y: float, z: float, col: int, kind: String) -> void:
	pairs += 1
	for s in [-0.055, 0.055]:
		_shoe(x + s, y, z, col, kind)

## One shoe, its toe to +z: "zapato" a laced shoe, "tacon" a court shoe with its heel, "bota" a tall boot, "botin" an
## ankle boot, "deportiva" a trainer on its white sole, "bailarina" a flat, "sandalia" a sandal's sole and straps.
func _shoe(x: float, y: float, z: float, col: int, kind: String) -> void:
	var sole := 0x2a2622 if col != 0x1f1f22 else 0x6a4a32
	match kind:
		"tacon":
			box(x - 0.035, y + 0.075, z - 0.12, 0.07, 0.014, 0.09, col)
			bar(Vector3(x, y + 0.078, z - 0.035), Vector3(x, y + 0.012, z + 0.035), 0.07, 0.012, col)
			box(x - 0.035, y, z + 0.03, 0.07, 0.014, 0.09, col)
			box(x - 0.033, y + 0.012, z + 0.04, 0.066, 0.034, 0.08, col)
			box(x - 0.011, y, z - 0.118, 0.022, 0.078, 0.022, sole)
		"bota":
			box(x - 0.04, y, z - 0.12, 0.08, 0.018, 0.24, sole)
			box(x - 0.038, y + 0.018, z - 0.12, 0.076, 0.07, 0.22, col)
			box(x - 0.038, y + 0.088, z - 0.12, 0.076, 0.26, 0.1, col)
		"botin":
			box(x - 0.04, y, z - 0.12, 0.08, 0.02, 0.24, sole)
			box(x - 0.038, y + 0.02, z - 0.12, 0.076, 0.07, 0.22, col)
			box(x - 0.038, y + 0.09, z - 0.12, 0.076, 0.07, 0.1, col)
		"deportiva":
			box(x - 0.042, y, z - 0.12, 0.084, 0.035, 0.245, 0xf4f4f0)
			box(x - 0.04, y + 0.035, z - 0.11, 0.08, 0.05, 0.2, col)
			box(x + 0.039, y + 0.045, z - 0.07, 0.004, 0.022, 0.1, 0xf4f4f0 if col != 0xf2f0ea else 0xc8384a)
		"bailarina":
			box(x - 0.038, y, z - 0.12, 0.076, 0.012, 0.24, sole)
			box(x - 0.036, y + 0.012, z - 0.12, 0.072, 0.035, 0.07, col)
			box(x - 0.036, y + 0.012, z + 0.02, 0.072, 0.03, 0.1, col)
		"sandalia":
			box(x - 0.038, y, z - 0.12, 0.076, 0.025, 0.24, 0xc8a878)
			box(x - 0.04, y + 0.025, z + 0.04, 0.08, 0.012, 0.03, col)
			box(x - 0.04, y + 0.025, z - 0.05, 0.08, 0.012, 0.025, col)
			box(x - 0.04, y + 0.025, z - 0.12, 0.08, 0.05, 0.012, col)
		_:
			box(x - 0.04, y, z - 0.12, 0.08, 0.018, 0.24, sole)
			box(x - 0.038, y + 0.018, z - 0.12, 0.076, 0.06, 0.19, col)
			box(x - 0.034, y + 0.018, z + 0.07, 0.068, 0.04, 0.05, col)

## a shoe box: its lid a little paler, a white label at its end (towards +z)
func _shoebox(x: float, y: float, z: float, w: float, h: float, d: float, col: int) -> void:
	box(x, y, z, w, h * 0.78, d, col)
	box(x - 0.004, y + h * 0.78, z - 0.004, w + 0.008, h * 0.22, d + 0.008, Color(Parts.col(col)).lightened(0.12).to_rgba32() >> 8)
	box(x + w * 0.3, y + h * 0.25, z + d, w * 0.4, h * 0.4, 0.003, 0xf8f8f6)

# ---------------- the room ----------------
func _shell() -> void:
	quad(Vector3(-HALF, 0, 0), Vector3(HALF, 0, 0), Vector3(HALF, 0, D), Vector3(-HALF, 0, D), "suelo", Vector3.UP)
	quad(Vector3(-HALF, TALL, 0), Vector3(HALF, TALL, 0), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "techo", Vector3.DOWN)
	quad(Vector3(-HALF, 0, 0), Vector3(-HALF, 0, D), Vector3(-HALF, TALL, D), Vector3(-HALF, TALL, 0), "pared", Vector3(1, 0, 0))
	# the wall at your left: the window to the Arcos in it
	var x := HALF
	for q in [[0.0, SIDE_WIN.x, 0.0, TALL], [SIDE_WIN.y, D, 0.0, TALL], [SIDE_WIN.x, SIDE_WIN.y, 0.0, 0.62], [SIDE_WIN.x, SIDE_WIN.y, 2.62, TALL]]:
		quad(Vector3(x, q[2], q[0]), Vector3(x, q[2], q[1]), Vector3(x, q[3], q[1]), Vector3(x, q[3], q[0]), "pared", Vector3(-1, 0, 0))
	quad(Vector3(x + 0.15, 0.62, SIDE_WIN.x), Vector3(x + 0.15, 0.62, SIDE_WIN.y), Vector3(x + 0.15, 2.62, SIDE_WIN.y), Vector3(x + 0.15, 2.62, SIDE_WIN.x), "calle", Vector3(-1, 0, 0))
	for z in [SIDE_WIN.x, SIDE_WIN.y - 0.06]:
		box(x - 0.02, 0.62, z, 0.1, 2.0, 0.06, 0xeeeeea)
	box(x - 0.02, 0.56, SIDE_WIN.x, 0.1, 0.06, SIDE_WIN.y - SIDE_WIN.x, 0xeeeeea)
	box(x - 0.02, 2.58, SIDE_WIN.x, 0.1, 0.06, SIDE_WIN.y - SIDE_WIN.x, 0xeeeeea)
	_window_step(Vector3(x, 0.0, (SIDE_WIN.x + SIDE_WIN.y) / 2.0), -PI / 2.0, SIDE_WIN.y - SIDE_WIN.x - 0.1)
	box(-HALF, 0.0, 0.0, 0.01, 0.08, D, 0xd8d0c8)                                                     # (the skirting)
	quad(Vector3(-HALF, 0, D), Vector3(HALF, 0, D), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "pared", Vector3(0, 0, -1))
	# the front from inside: the glass door (open while you are here), the frosted glass, the window, the street bright
	# beyond them
	var top := 2.5
	var cuts: Array = [[-HALF, DOOR.x, 0.0, TALL], [DOOR.x, DOOR.y, top, TALL], [DOOR.y, FROST.x, 0.0, TALL], [FROST.x, FROST.y, 0.0, 0.62],
		[FROST.x, FROST.y, 2.62, TALL], [FROST.y, WIN.x, 0.0, TALL], [WIN.x, WIN.y, 0.0, 0.62], [WIN.x, WIN.y, 2.62, TALL], [WIN.y, HALF, 0.0, TALL]]
	for q in cuts:
		quad(Vector3(q[0], q[2], 0), Vector3(q[1], q[2], 0), Vector3(q[1], q[3], 0), Vector3(q[0], q[3], 0), "pared", Vector3(0, 0, 1))
	quad(Vector3(DOOR.x, 0, -0.15), Vector3(DOOR.y, 0, -0.15), Vector3(DOOR.y, top, -0.15), Vector3(DOOR.x, top, -0.15), "calle", Vector3(0, 0, 1))
	quad(Vector3(FROST.x, 0.62, -0.1), Vector3(FROST.y, 0.62, -0.1), Vector3(FROST.y, 2.62, -0.1), Vector3(FROST.x, 2.62, -0.1), "esmerilado", Vector3(0, 0, 1))
	quad(Vector3(WIN.x, 0.62, -0.15), Vector3(WIN.y, 0.62, -0.15), Vector3(WIN.y, 2.62, -0.15), Vector3(WIN.x, 2.62, -0.15), "calle", Vector3(0, 0, 1))
	for p in [FROST, WIN]:
		for xx in [p.x, p.y - 0.06]:
			box(xx, 0.62, -0.08, 0.06, 2.0, 0.1, 0xeeeeea)
		box(p.x, 0.56, -0.08, p.y - p.x, 0.06, 0.16, 0xeeeeea)
		box(p.x, 2.58, -0.08, p.y - p.x, 0.06, 0.1, 0xeeeeea)
	for xx in [DOOR.x - 0.07, DOOR.y]:
		box(xx, 0.0, -0.08, 0.07, top, 0.1, 0xeeeeea)
	box(DOOR.x - 0.07, top, -0.08, DOOR.y - DOOR.x + 0.14, 0.07, 0.1, 0xeeeeea)
	box(DOOR.x - 0.1, 0.0, 0.2, DOOR.y - DOOR.x + 0.2, 0.014, 0.8, 0x2a5a58)                       # the mat
	_window_step(Vector3((WIN.x + WIN.y) / 2.0, 0.0, 0.0), 0.0, WIN.y - WIN.x - 0.1)
	quad(Vector3(-3.3, 1.35, 0.012), Vector3(-3.0, 1.35, 0.012), Vector3(-3.0, 1.75, 0.012), Vector3(-3.3, 1.75, 0.012), "horario", Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])                                # (its hours, seen from inside: on the wall by the door)
	solid(Vector3(0, TALL / 2.0, -0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	solid(Vector3(0, TALL / 2.0, D + 0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	for sx in [-1.0, 1.0]:
		solid(Vector3(sx * (HALF + 0.2), TALL / 2.0, D / 2.0), Vector3(0.4, TALL, D + 0.8))
	solid(Vector3(0, TALL + 0.1, D / 2.0), Vector3(2.0 * HALF + 0.8, 0.2, D + 0.8))

## The low white step behind a window's glass (its back to the room): two steps of pairs, their toes to the street. `at`
## the middle of the window's foot on the wall, `yaw` turning the street (local -z) where it is.
func _window_step(at: Vector3, yaw: float, w: float) -> void:
	_put(at, yaw)
	box(-w / 2.0, 0.0, 0.06, w, 0.5, 0.36, 0xf4f4f0)
	box(-w / 2.0, 0.0, 0.42, w, 0.25, 0.3, 0xf4f4f0)
	var n := int(w / 0.36)
	for i in range(n):
		var px := -w / 2.0 + 0.2 + i * (w - 0.4) / maxf(1.0, n - 1.0)
		_put_pair(px, 0.5, 0.24, _colour(), KINDS[(i * 2) % KINDS.size()], true)
		_put_pair(px + 0.1, 0.25, 0.57, _colour(), KINDS[(i * 3 + 1) % KINDS.size()], true)
	home()
	solid(Vector3(at.x, 0.25, at.z) + Basis(Vector3.UP, yaw) * Vector3(0, 0, 0.36), (Basis(Vector3.UP, yaw) * Vector3(w, 0.5, 0.72)).abs())

## a pair in the frame set by _put: toes to local -z when `to_street`
func _put_pair(x: float, y: float, z: float, col: int, kind: String, to_street := false) -> void:
	if not to_street:
		_pair(x, y, z, col, kind)
		return
	var keep := _xf
	_xf = keep * Transform3D(Basis(Vector3.UP, PI), Vector3(x, y, z))
	_pair(0.0, 0.0, 0.0, col, kind)
	_xf = keep

# ---------------- the walls of shoes ----------------
## A wall of white shelves of shoes on the side wall `side` (-1 at your right, +1 at your left) from z0 to z1: a white
## back, uprights every metre or so, six shelves, a pair every 34 cm on each, their toes to the room.
func _shoe_wall(side: float, z0: float, z1: float) -> void:
	var ln := z1 - z0
	_put(Vector3(side * HALF, 0.0, (z0 + z1) / 2.0), -side * PI / 2.0)
	var h := 2.35
	box(-ln / 2.0, 0.0, 0.012, ln, h, 0.02, 0xf4f4f0)                                 # its back
	box(-ln / 2.0, 0.0, 0.032, ln, 0.10, SHELF_D, 0xe4e4e0)                           # its foot
	var bays := maxi(1, int(round(ln / 1.0)))
	for i in range(bays + 1):
		box(-ln / 2.0 + i * ln / bays - (0.025 if i == bays else 0.0), 0.0, 0.032, 0.025, h, SHELF_D, 0xf4f4f0)
	box(-ln / 2.0, h, 0.012, ln, 0.06, SHELF_D + 0.04, 0xf4f4f0)                      # its top
	var ys := [0.12, 0.48, 0.84, 1.2, 1.56, 1.92]
	for j in range(ys.size()):
		var y: float = ys[j]
		box(-ln / 2.0, y - 0.02, 0.032, ln, 0.02, SHELF_D, 0xf8f8f6)
		box(-ln / 2.0, y - 0.02, 0.032 + SHELF_D, ln, 0.035, 0.015, 0xd8d8d4)         # (its lip)
		var n := int((ln - 0.2) / 0.34)
		for i in range(n):
			var px := -ln / 2.0 + 0.2 + i * (ln - 0.4) / maxf(1.0, n - 1.0)
			var kind: String = KINDS[(i + j * 4 + int(side + 1.0)) % KINDS.size()]
			if j == 0:                                                              # (boots, ankle boots and trainers on the lowest)
				kind = ["bota", "botin", "deportiva"][i % 3]
			_pair(px, y, 0.2, _colour(j), kind)
	home()
	solid(Vector3(side * (HALF - SHELF_D / 2.0), 1.2, (z0 + z1) / 2.0), Vector3(SHELF_D + 0.02, 2.4, ln))

# ---------------- the counter and the wall of boxes behind it ----------------
## At the back on your left: a white counter with a turquoise front, the till, the card machine, a shoehorn, a roll of
## paper bags; behind it the back wall's shelves of shoe boxes up to the ceiling.
func _counter() -> void:
	var x0 := COUNTER.position.x
	var x1 := COUNTER.end.x
	var z0 := COUNTER.position.y
	var z1 := COUNTER.end.y
	box(x0, 0.0, z0, x1 - x0, 0.95, z1 - z0, 0xf4f4f0)
	box(x0 - 0.03, 0.95, z0 - 0.03, x1 - x0 + 0.06, 0.04, z1 - z0 + 0.06, 0xf8f8f6)
	box(x0 + 0.1, 0.12, z0 - 0.012, x1 - x0 - 0.2, 0.7, 0.012, TURQ)                    # its turquoise front
	_put(Vector3(x0 + 0.7, 0.99, z0 + 0.35), PI)                                        # the till: its drawer, its screen towards you
	box(-0.22, 0.0, -0.2, 0.44, 0.1, 0.4, 0x2a2a2e)
	box(-0.2, 0.1, -0.12, 0.4, 0.06, 0.24, 0x3a3a3e)
	bar(Vector3(0, 0.16, 0.05), Vector3(0, 0.42, 0.12), 0.04, 0.04, 0x2a2a2e)
	box(-0.17, 0.38, 0.1, 0.34, 0.24, 0.03, 0x1a1a1c)
	box(-0.15, 0.4, 0.13, 0.3, 0.2, 0.002, 0x4a7ab0)
	home()
	box(x0 + 1.25, 0.99, z0 + 0.2, 0.16, 0.04, 0.08, 0x2a2a2e)                          # the card machine
	box(x0 + 1.27, 1.03, z0 + 0.21, 0.08, 0.012, 0.06, 0x4a7ab0)
	bar(Vector3(x0 + 1.6, 1.0, z0 + 0.25), Vector3(x0 + 1.95, 1.0, z0 + 0.3), 0.04, 0.012, 0xc8b070)     # a shoehorn
	drum(Vector3(x1 - 0.2, 0.99, z0 + 0.4), 0.09, 0.09, 0.3, 0xf2f0ea, 10)          # a roll of paper bags
	_shoebox(x0 + 1.5, 0.99, z0 + 0.3, 0.32, 0.12, 0.2, 0xb08a5a)                     # (a box being wrapped)
	props += 4
	solid(Vector3(COUNTER.get_center().x, 0.5, COUNTER.get_center().y), Vector3(COUNTER.size.x, 1.0, COUNTER.size.y))
	solid(Vector3((x1 + HALF) / 2.0, 0.5, COUNTER.get_center().y), Vector3(HALF - x1 + 0.02, 1.0, COUNTER.size.y))      # (nobody goes behind it but who serves)
	solid(Vector3(x0 - 0.05, 0.5, (z1 + D) / 2.0), Vector3(0.1, 1.0, D - z1))
	box(x0 - 0.08, 0.0, z1, 0.05, 0.9, D - z1, 0xf4f4f0)                             # (a low flap at its end)
	box(x1, 0.0, z0, HALF - x1, 0.9, 0.05, 0xf4f4f0)
	# behind it: the back wall's shelves of shoe boxes
	var bx0 := x0 - 0.03
	var bx1 := HALF
	for y in [0.0, 0.45, 0.9, 1.35, 1.8, 2.25]:
		box(bx0, y, D - 0.4, bx1 - bx0, 0.025, 0.4, 0xf4f4f0)
		var xx := bx0 + 0.04
		var k := int(y * 10.0)
		while xx < bx1 - 0.36:
			var hh := 0.12 + 0.02 * (k % 3)
			var stack := 3 if y < 2.2 else 2
			for s in range(stack):
				_shoebox(xx, y + 0.025 + s * (hh + 0.005), D - 0.38, 0.32, hh, 0.3, BOXES[(k + s * 2) % BOXES.size()])
			xx += 0.35
			k += 1
	for xx in [bx0, (bx0 + bx1) / 2.0, bx1 - 0.03]:
		box(xx, 0.0, D - 0.4, 0.03, TALL - 0.3, 0.4, 0xf4f4f0)
	props += 1

# ---------------- the back wall: the shop's name over a step of boots ----------------
func _back_wall() -> void:
	var z := D - 0.012
	quad(Vector3(-HALF + SHELF_D, 0, z), Vector3(COUNTER.position.x - 0.03, 0, z), Vector3(COUNTER.position.x - 0.03, TALL, z), Vector3(-HALF + SHELF_D, TALL, z), "turquesa", Vector3(0, 0, -1))
	_picture_back(-2.7, 0.1, 1.55, 2.6, z - 0.01, "mural")
	box(-2.6, 0.0, D - 0.5, 2.6, 0.35, 0.49, 0xf4f4f0)                                # the low step
	box(-2.6, 0.35, D - 0.3, 2.6, 0.3, 0.29, 0xf4f4f0)
	for i in range(6):
		var px := -2.35 + i * 0.42
		_pair(px, 0.35, D - 0.4 + 0.05, _colour(i), ["bota", "botin"][i % 2])
		_pair(px + 0.1, 0.65, D - 0.17, _colour(i + 3), ["bota", "tacon", "botin"][i % 3])
	solid(Vector3(-1.3, 0.35, D - 0.25), Vector3(2.6, 0.7, 0.5))

## a picture on the back wall, read from inside the room (facing -z)
func _picture_back(x0: float, x1: float, y0: float, y1: float, z: float, key) -> void:
	pieces += 1
	quad(Vector3(x1, y0, z), Vector3(x0, y0, z), Vector3(x0, y1, z), Vector3(x1, y1, z), key, Vector3(0, 0, -1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

# ---------------- the middle of the room ----------------
func _middle() -> void:
	_round_table(Vector2(1.5, 3.4))
	_bench(Vector2(1.5, 5.15))
	_mirror(Vector2(0.05, 6.4))

## a round white table of shoes on a white foot: pairs round its edge, a boot in the middle on a little column
func _round_table(at: Vector2) -> void:
	props += 1
	drum(Vector3(at.x, 0.0, at.y), 0.25, 0.25, 0.04, 0xf4f4f0, 16)
	bar(Vector3(at.x, 0.0, at.y), Vector3(at.x, 0.72, at.y), 0.08, 0.08, 0xf4f4f0)
	drum(Vector3(at.x, 0.72, at.y), 0.55, 0.55, 0.04, 0xf8f8f6, 20)
	for k in range(7):
		var a := TAU * k / 7.0
		_put(Vector3(at.x + cos(a) * 0.38, 0.76, at.y + sin(a) * 0.38), PI / 2.0 - a)
		_pair(0.0, 0.0, 0.0, _colour(k), KINDS[(k * 2 + 1) % KINDS.size()])
		home()
	drum(Vector3(at.x, 0.76, at.y), 0.1, 0.1, 0.3, TURQ, 12)
	_pair(at.x, 1.06, at.y, _colour(), "bota")
	solid(Vector3(at.x, 0.4, at.y), Vector3(1.1, 0.8, 1.1))

## the long padded bench where you try shoes on (along x), and the shop's sloping stool before it
func _bench(at: Vector2) -> void:
	props += 2
	var w := 1.6
	for xx in [at.x - w / 2.0 + 0.05, at.x + w / 2.0 - 0.1]:
		box(xx, 0.0, at.y - 0.2, 0.05, 0.32, 0.4, 0xc0c4c8)
	box(at.x - w / 2.0, 0.32, at.y - 0.22, w, 0.12, 0.44, 0x6a2a32)                   # its padded seat
	for i in range(1, 4):
		box(at.x - w / 2.0 + i * w / 4.0 - 0.005, 0.44, at.y - 0.22, 0.01, 0.004, 0.44, 0x4a1a22)
	_put(Vector3(at.x, 0.0, at.y + 0.6))                                               # the stool: a seat with its sloping foot rest
	box(-0.17, 0.0, -0.15, 0.34, 0.3, 0.3, 0xf4f4f0)
	box(-0.15, 0.3, -0.13, 0.3, 0.05, 0.26, 0x2a5a58)
	bar(Vector3(0, 0.05, 0.15), Vector3(0, 0.22, 0.42), 0.26, 0.03, 0xd8d8d4)
	box(-0.13, 0.0, 0.38, 0.26, 0.05, 0.08, 0xd8d8d4)
	home()
	_saffron(Vector3(at.x + w / 2.0 - 0.29, 0.0, at.y + 0.4))                       # (a box on the floor by it, open, the saffron in it; a pair beside it)
	_pair(at.x - w / 2.0 + 0.3, 0.0, at.y + 0.45, _colour(), "tacon")
	solid(Vector3(at.x, 0.22, at.y), Vector3(w, 0.44, 0.44))
	solid(Vector3(at.x, 0.17, at.y + 0.6), Vector3(0.34, 0.34, 0.6))

## The hidden saffron: a black shoe box on the floor by the bench (`at` the middle of its foot), open, tissue paper in
## it, its lid on its edge leaning on its front, the flower standing up out of it. The flower is the game's to take
## away (just walking by: game.gd takes it within 1.26 m); the box stays.
func _saffron(at: Vector3) -> void:
	props += 1
	var w := 0.32
	var dd := 0.2
	var h := 0.12
	var x0 := at.x - w / 2.0
	var z0 := at.z - dd / 2.0
	box(x0, 0.0, z0, w, 0.01, dd, 0x2a2a2e)                                          # its bottom...
	box(x0, 0.0, z0, w, h, 0.012, 0x2a2a2e)                                          # ...its four sides, open at the top
	box(x0, 0.0, z0 + dd - 0.012, w, h, 0.012, 0x2a2a2e)
	box(x0, 0.0, z0, 0.012, h, dd, 0x2a2a2e)
	box(x0 + w - 0.012, 0.0, z0, 0.012, h, dd, 0x2a2a2e)
	box(x0 + 0.015, h - 0.035, z0 + 0.015, w - 0.03, 0.012, dd - 0.03, 0xf2f0ea)   # (the tissue paper)
	box(x0 + w * 0.3, h * 0.25, z0 + dd, w * 0.4, h * 0.4, 0.003, 0xf8f8f6)          # (its label)
	_xf = Transform3D(Basis(Vector3(1, 0, 0), -(PI - 1.25)), Vector3(x0 - 0.004, 0.0, z0 + dd + 0.045))     # its lid, on its long edge, leaning on the box's front
	box(0.0, 0.0, 0.0, w + 0.008, 0.03, dd + 0.008, 0x3a3a3e)
	home()
	var flower := Node3D.new()
	flower.add_child(Parts.part("cyl", 0x5f9c4a, Vector3(0, 0.22, 0), Vector3(0.025, 0.44, 0.025)))
	for k in range(5):
		flower.add_child(Parts.part("ball", 0x9b5de5, Vector3(cos(k * 1.257) * 0.09, 0.48, sin(k * 1.257) * 0.09), Vector3(0.085, 0.15, 0.085)))
	flower.add_child(Parts.part("ball", 0xe63946, Vector3(0, 0.54, 0), Vector3(0.04, 0.1, 0.04)))
	flower.position = Vector3(at.x, 0.06, at.z)
	add_child(flower)
	saffron_spot = INSIDE + Vector2(at.x, at.z)
	var game = W.get_parent()                           # (the game: the world is its child)
	if game != null and game.get("flowers") != null:
		(game.flowers as Array).append({"node": flower, "p": saffron_spot, "id": "pisacastana", "hidden": true})      # (hidden: Sistemas keeps count of these)

## a low mirror on the floor, for the feet: its foot, its frame leaning back, turned to the side of the spot where you
## try them on
func _mirror(at: Vector2) -> void:
	props += 1
	box(at.x - 0.05, 0.0, at.y - 0.25, 0.25, 0.03, 0.5, 0xc0c4c8)
	var keep := _xf
	_xf = Transform3D(Basis(Vector3(0, 0, 1), -0.25), Vector3(at.x, 0.03, at.y))
	box(0.0, 0.0, -0.22, 0.03, 0.6, 0.44, 0xd8dce0)
	quad(Vector3(-0.002, 0.03, -0.19), Vector3(-0.002, 0.03, 0.19), Vector3(-0.002, 0.57, 0.19), Vector3(-0.002, 0.57, -0.19), "espejo", Vector3(-1, 0, 0))
	_xf = keep
	solid(Vector3(at.x + 0.08, 0.3, at.y), Vector3(0.25, 0.6, 0.5))

func _lamps() -> void:
	for z in [1.5, 3.5, 5.5, 7.5]:
		for x in [-2.0, 0.0, 2.0]:
			drum(Vector3(x, TALL - 0.02, z), 0.09, 0.09, 0.018, "luz", 12)
			drum(Vector3(x, TALL - 0.008, z), 0.11, 0.11, 0.008, 0xd8d6cc, 12)
	for at in [Vector3(0.0, 2.5, 2.2), Vector3(0.0, 2.5, 5.5), Vector3(0.0, 2.5, 8.0), Vector3(-2.5, 2.3, 4.0), Vector3(2.5, 2.3, 6.0)]:
		var lamp := OmniLight3D.new()
		lamp.position = at
		lamp.light_color = Color(1.0, 0.97, 0.92)
		lamp.omni_range = 5.0
		lamp.light_energy = 0.45
		lamp.shadow_enabled = false
		lamp.light_cull_mask = 1 << 10
		add_child(lamp)
