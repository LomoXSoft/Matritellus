extends "res://scripts/obra.gd"
## The inside of the house you inherit as it is after each of its works (casa_dentro.gd keeps the five and shows one;
## its own room is the house as you inherit it, state 0). The user, 21 November 2026, through Sistemas, for the
## missions of the house:
##   1  done up: the same room, in a decent state;
##   2  the first enlargement: the room is bigger (it grows to the right: a kitchen and a table to eat at);
##   3  a room more on the left (a bathroom);
##   4  a room more on the right (a sitting room);
##   5  an upper floor, reached by a door at the back (a flight of stairs behind it, and up there a study and a terrace
##      door).
## The bed against the back wall and the wardrobe on the left wall are casa_dentro.gd's own, there in every state (the
## game looks for them where they are), and so is your peña's graffiti over the bed: none of that is built here. Nobody
## is modelled.
##
## The frame is casa_dentro.gd's: x to the right as you come in, +z deeper in, the street door at (0, 0); y = 0 the
## floor. The upper floor is not over the ground floor but further back (two floors cannot share a spot of the map:
## MapData.decks), up its stairs: in a set nobody can tell.

const TALL := 2.8
const X0 := -3.0                    # the room as inherited: from here...
const X1 := 3.0                     # ...to here
const D := 6.0
const WIDE := 7.0                   # the room's right wall once it is enlarged
const LEFT := Rect2(-6.8, 0.0, 3.4, 4.0)            # the bathroom (x, z, wide, deep)
const LEFT_DOOR := Vector2(0.7, 1.6)                # ...its door in the room's left wall (along z)
const RIGHT := Rect2(7.4, 0.0, 4.0, 6.0)            # the sitting room
const RIGHT_DOOR := Vector2(2.0, 3.0)               # ...its door in the room's right wall (along z)
const BACK_DOOR := Vector2(4.6, 5.6)                # the door at the back, to the stairs (along x)
const STAIRS := Rect2(4.6, 6.4, 1.0, 4.0)           # the flight
const UP := 3.0                     # how far up the upper floor is
const UPPER := Rect2(0.6, 10.8, 8.0, 6.0)           # the upper floor
const WALL := 0.4                   # how thick a wall between two rooms is

var state := 1
var cfg := {}                       # what casa_dentro.gd lends it: "dia" (the day's light in the windows), "bed", "wardrobe" (their solids)
var props := 0

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: StandardMaterial3D = null
	match (String(key) if key is String else ""):
		"cal":
			m = _lit(Color(0.98, 0.98, 0.96), 0.24)
		"crema":            # the sitting room's walls
			m = _lit(Color(0.96, 0.9, 0.76), 0.22)
		"anil":
			m = _lit(Color(0.22, 0.38, 0.72), 0.2)
		"techo":
			m = _lit(Color(0.97, 0.97, 0.96), 0.3)
		"viga":
			m = _lit(Color(0.42, 0.29, 0.18), 0.14)
		"barro":            # the old floor, scrubbed
			m = _tiles(0xc0704a, 0xb2643e, 0.66, 2)
		"hidraulica":       # the new floor of the enlarged house: cream and brick-red, in checks
			m = _tiles(0xe6dcc4, 0xb85a3c, 0.5, 2)
		"azulejo":          # white tiles
			m = _tiles(0xf4f5f3, 0xe8eaea, 0.3, 2)
		"tarima":           # the boards of the upper floor
			m = _tiles(0xb8905a, 0xa88050, 0.6, 4, true)
		"encimera":
			m = _lit(Color(0.36, 0.36, 0.38), 0.12)
		"pantalla":
			m = _lit(Color(0.2, 0.42, 0.72), 0.8)
		"luz":
			m = _lit(Color(1.0, 0.96, 0.84), 2.2)
		"dia":
			return cfg.get("dia", _lit(Color(0.86, 0.93, 1.0), 1.4))
		_:
			var pm := Parts.mat(int(key)).duplicate() as StandardMaterial3D
			pm.emission_enabled = true
			pm.emission = pm.albedo_color
			pm.emission_energy_multiplier = 0.22
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

func _tiles(a: int, b: int, metres: float, n: int, boards := false) -> StandardMaterial3D:
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	for y in range(n):
		for x in range(n):
			img.set_pixel(x, y, Parts.col(a if ((x if boards else x + y) % 2 == 0) else b))
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / metres
	m.roughness = 1.0
	m.emission_enabled = true
	m.emission = Parts.col(a).lerp(Parts.col(b), 0.5)
	m.emission_energy_multiplier = 0.14
	return m

## `at`: where the set stands in the world (casa_dentro.gd's own transform); `which`: 1 to 5
func build(world, at: Transform3D, which: int, lend: Dictionary) -> void:
	W = world
	state = which
	cfg = lend
	level = at.origin.y
	transform = at
	W.add_child(self)
	_main()
	if state >= 3:
		_bath()
	if state >= 4:
		_sitting()
	if state >= 5:
		_upstairs()
	home()
	_commit()
	_indoors(self)

func _indoors(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).layers = 1 << 10
	for c in n.get_children():
		_indoors(c)

## the rooms of this state, for casa_dentro.gd's camera: [name, x0, x1, z0, z1, floor's height, the wall the camera hangs on]
func rooms() -> Array:
	var out: Array = [["sala", X0, (WIDE if state >= 2 else X1), 0.0, D, 0.0, "z0"]]
	if state >= 3:
		out.append(["bano", LEFT.position.x, LEFT.end.x, LEFT.position.y, LEFT.end.y, 0.0, "x1"])
	if state >= 4:
		out.append(["salon", RIGHT.position.x, RIGHT.end.x, RIGHT.position.y, RIGHT.end.y, 0.0, "x0"])
	if state >= 5:
		out.append(["escalera", STAIRS.position.x, STAIRS.end.x, STAIRS.position.y, STAIRS.end.y, 0.0, "z0"])
		out.append(["arriba", UPPER.position.x, UPPER.end.x, UPPER.position.y, UPPER.end.y, UP, "z0"])
	return out

# ---------------- pieces of a room ----------------
## A wall from a to b (in plan) from y0 up `tall`, facing `n`, with its doors ([[from, to, how high], ...] along x if the
## wall runs along x, along z if not); `dado`: the colour of its foot, and how high; solid behind it.
func _wall(a: Vector2, b: Vector2, y0: float, n: Vector3, holes: Array, key, dado = null, dado_h := 0.95) -> void:
	var along_x := absf(b.x - a.x) > absf(b.y - a.y)
	var from := a.x if along_x else a.y
	var to := b.x if along_x else b.y
	var cuts: Array = [from]
	holes.sort_custom(func(p, q): return float(p[0]) < float(q[0]))
	for h in holes:
		cuts.append(float(h[0]))
		cuts.append(float(h[1]))
	cuts.append(to)
	for i in range(cuts.size() - 1):
		var s0: float = cuts[i]
		var s1: float = cuts[i + 1]
		if s1 - s0 < 0.01:
			continue
		var lo := 0.0
		if i % 2 == 1:
			lo = float(holes[i >> 1][2])
		var p0 := Vector3(s0, y0 + lo, a.y) if along_x else Vector3(a.x, y0 + lo, s0)
		var p1 := Vector3(s1, y0 + lo, a.y) if along_x else Vector3(a.x, y0 + lo, s1)
		if dado != null and lo < dado_h:
			quad(p0, p1, p1 + Vector3(0, dado_h - lo, 0), p0 + Vector3(0, dado_h - lo, 0), dado, n)
			quad(p0 + Vector3(0, dado_h - lo, 0), p1 + Vector3(0, dado_h - lo, 0), p1 + Vector3(0, TALL - lo, 0), p0 + Vector3(0, TALL - lo, 0), key, n)
		else:
			quad(p0, p1, p1 + Vector3(0, TALL - lo, 0), p0 + Vector3(0, TALL - lo, 0), key, n)
		if i % 2 == 0:
			var mid := (p0 + p1) / 2.0 - n * 0.2
			solid(Vector3(mid.x, y0 + TALL / 2.0, mid.z), Vector3((s1 - s0) if along_x else 0.4, TALL, 0.4 if along_x else (s1 - s0)))

## a room's floor and ceiling, beams across it
func _floor(r: Rect2, y0: float, key, beams := true) -> void:
	var a := r.position
	var b := r.end
	quad(Vector3(a.x, y0, a.y), Vector3(b.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(a.x, y0, b.y), key, Vector3.UP)
	quad(Vector3(a.x, y0 + TALL, a.y), Vector3(b.x, y0 + TALL, a.y), Vector3(b.x, y0 + TALL, b.y), Vector3(a.x, y0 + TALL, b.y), "techo", Vector3.DOWN)
	solid(Vector3((a.x + b.x) / 2.0, y0 + TALL + 0.1, (a.y + b.y) / 2.0), Vector3(r.size.x + 0.8, 0.2, r.size.y + 0.8))
	if beams:
		var z := a.y + 0.55
		while z < b.y:
			box(a.x, y0 + TALL - 0.16, z - 0.07, r.size.x, 0.16, 0.14, "viga")
			z += 0.95

## the way through a wall WALL thick: its floor, its head and its two cheeks
func _through(x0: float, x1: float, z0: float, z1: float, y0: float, h: float, key) -> void:
	quad(Vector3(x0, y0 + 0.003, z0), Vector3(x1, y0 + 0.003, z0), Vector3(x1, y0 + 0.003, z1), Vector3(x0, y0 + 0.003, z1), key, Vector3.UP)
	quad(Vector3(x0, y0 + h, z0), Vector3(x1, y0 + h, z0), Vector3(x1, y0 + h, z1), Vector3(x0, y0 + h, z1), "cal", Vector3.DOWN)
	if absf(x1 - x0) < absf(z1 - z0):                 # (a wall that runs along z: cheeks across it)
		quad(Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y0 + h, z0), Vector3(x0, y0 + h, z0), "cal", Vector3(0, 0, 1))
		quad(Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x1, y0 + h, z1), Vector3(x0, y0 + h, z1), "cal", Vector3(0, 0, -1))
	else:
		quad(Vector3(x0, y0, z0), Vector3(x0, y0, z1), Vector3(x0, y0 + h, z1), Vector3(x0, y0 + h, z0), "cal", Vector3(1, 0, 0))
		quad(Vector3(x1, y0, z0), Vector3(x1, y0, z1), Vector3(x1, y0 + h, z1), Vector3(x1, y0 + h, z0), "cal", Vector3(-1, 0, 0))

## where a piece stands: `at` its foot, turned `yaw` (until home())
func _put(at: Vector3, yaw := 0.0) -> void:
	_xf = Transform3D(Basis(Vector3.UP, yaw), at)
	props += 1

## a window on a wall: the day in it, a frame, a sill; `n` the way it faces
func _pane(at: Vector3, n: Vector3, w: float, h: float, frame := 0x5a3a22) -> void:
	_put(at, atan2(n.x, n.z))
	box(-w / 2.0, 0.0, 0.004, w, h, 0.004, "dia")
	for q in [[-w / 2.0 - 0.06, 0.0, 0.06, h], [w / 2.0, 0.0, 0.06, h], [-w / 2.0 - 0.06, h, w + 0.12, 0.06], [-0.02, 0.0, 0.04, h]]:
		box(float(q[0]), float(q[1]), 0.0, float(q[2]), float(q[3]), 0.06, frame)
	box(-w / 2.0 - 0.1, -0.06, 0.0, w + 0.2, 0.06, 0.16, "cal")
	home()

func _chair(at: Vector3, yaw: float, hex) -> void:
	_put(at, yaw)
	for sx in [-0.19, 0.19]:
		box(sx - 0.02, 0.0, -0.19, 0.04, 0.44, 0.04, hex)
		box(sx - 0.02, 0.0, 0.15, 0.04, 0.92, 0.04, hex)
	box(-0.21, 0.44, -0.21, 0.42, 0.04, 0.4, 0xd9c27a)
	for y in [0.62, 0.8]:
		box(-0.19, y, 0.155, 0.38, 0.06, 0.025, hex)
	home()
	solid(at + Vector3(0, 0.3, 0), Vector3(0.45, 0.6, 0.45))

func _table(at: Vector3, w: float, d: float, h: float, top, legs := 0x7a5232) -> void:
	_put(at)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			box(sx * (w / 2.0 - 0.06) - 0.03, 0.0, sz * (d / 2.0 - 0.06) - 0.03, 0.06, h, 0.06, legs)
	box(-w / 2.0, h - 0.05, -d / 2.0, w, 0.05, d, top)
	home()
	solid(at + Vector3(0, h / 2.0, 0), Vector3(w, h, d))

func _picture(at: Vector3, n: Vector3, w: float, h: float, frame, inside) -> void:
	_put(at, atan2(n.x, n.z))
	box(-w / 2.0, -h / 2.0, 0.0, w, h, 0.03, frame)
	box(-w / 2.0 + 0.04, -h / 2.0 + 0.04, 0.03, w - 0.08, h - 0.08, 0.004, inside)
	home()

func _plant(at: Vector3, tall: float) -> void:
	_put(at)
	drum(Vector3.ZERO, 0.15, 0.2, 0.36, 0xb0623a, 10)
	for k in range(5):
		var a := TAU * k / 5.0
		ball(Vector3(cos(a) * 0.16, 0.36 + tall * (0.4 + 0.1 * (k % 2)), sin(a) * 0.16), 0.2, 0x3f7a3a, 1.3, 7, 4)
	ball(Vector3(0, 0.36 + tall * 0.7, 0), 0.22, 0x4a8a44, 1.3, 7, 4)
	home()
	solid(at + Vector3(0, 0.4, 0), Vector3(0.45, 0.8, 0.45))

## a ceiling lamp with its shade, and its light
func _lamp(at: Vector3, reach := 6.5) -> void:
	bar(at + Vector3(0, 0.25, 0), at + Vector3(0, 0.6, 0), 0.012, 0.012, 0x1b1b1f)
	drum(at, 0.26, 0.12, 0.2, 0xe8dcc0, 10)
	ball(at + Vector3(0, 0.03, 0), 0.06, "luz", 1.0, 6, 4)
	var l := OmniLight3D.new()
	l.position = at - Vector3(0, 0.2, 0)
	l.light_color = Color(1.0, 0.95, 0.86)
	l.omni_range = reach
	l.light_energy = 0.6
	l.shadow_enabled = false
	l.light_cull_mask = 1 << 10
	add_child(l)

# ---------------- the room you come into ----------------
## The room as inherited, done up; from state 2 it reaches to WIDE, and what is new of it is a kitchen along the back
## wall and a table to eat at. Its walls leave the ways through to whatever rooms this state has.
func _main() -> void:
	var x1 := WIDE if state >= 2 else X1
	var floor_k = "barro" if state < 2 else "hidraulica"
	_floor(Rect2(X0, 0.0, x1 - X0, D), 0.0, floor_k)
	var back: Array = [[BACK_DOOR.x, BACK_DOOR.y, 2.05]] if state >= 5 else []
	var left: Array = [[LEFT_DOOR.x, LEFT_DOOR.y, 2.05]] if state >= 3 else []
	var right: Array = [[RIGHT_DOOR.x, RIGHT_DOOR.y, 2.05]] if state >= 4 else []
	_wall(Vector2(X0, D), Vector2(x1, D), 0.0, Vector3(0, 0, -1), back, "cal", "anil")
	_wall(Vector2(X0, 0.0), Vector2(X0, D), 0.0, Vector3(1, 0, 0), left, "cal", "anil")
	_wall(Vector2(x1, 0.0), Vector2(x1, D), 0.0, Vector3(-1, 0, 0), right, "cal", "anil")
	_wall(Vector2(X0, 0.0), Vector2(x1, 0.0), 0.0, Vector3(0, 0, 1), [], "cal", "anil")
	box(X0, 0.95, 0.0, x1 - X0, 0.03, 0.012, 0xf4f1ea)                        # a white line over the blue, all round
	box(X0, 0.95, D - 0.012, x1 - X0, 0.03, 0.012, 0xf4f1ea)
	for x in [X0, x1 - 0.012]:
		box(x, 0.95, 0.0, 0.012, 0.03, D, 0xf4f1ea)
	# the street door from inside: green now, its frame, a mat
	box(-0.62, 0.0, 0.0, 0.1, 2.25, 0.06, 0x3a2a1e)
	box(0.52, 0.0, 0.0, 0.1, 2.25, 0.06, 0x3a2a1e)
	box(-0.62, 2.15, 0.0, 1.24, 0.1, 0.06, 0x3a2a1e)
	box(-0.52, 0.0, 0.0, 1.04, 2.15, 0.035, 0x2f5a3a)
	box(0.34, 1.0, 0.035, 0.05, 0.14, 0.04, 0xc9a23a)
	box(-0.55, 0.0, 0.18, 1.1, 0.012, 0.6, 0x8a3a2a)
	# windows on the street, the day in them, curtains
	for wx in ([1.9] if state < 2 else [1.9, 4.6]):
		_pane(Vector3(wx, 1.1, 0.0), Vector3(0, 0, 1), 0.9, 1.0, 0x2f5a3a)
		for sx in [-0.62, 0.42]:
			box(wx + sx, 1.0, 0.07, 0.2, 1.25, 0.03, 0xf0e6d0)
		box(wx - 0.7, 2.22, 0.06, 1.4, 0.03, 0.05, 0x5a3a22)
	if state < 2:                                    # (its old window on the right wall, there while that wall is)
		_pane(Vector3(X1, 1.1, 3.2), Vector3(-1, 0, 0), 0.9, 0.95, 0x2f5a3a)
	# the bed's and the wardrobe's solids (the pieces themselves are casa_dentro.gd's), a rug, a chair, a picture
	for s in cfg.get("solids", []):
		solid(s[0], s[1])
	_chair(Vector3(X0 + 0.45, 0.0, 1.9 if state < 3 else 5.2), -PI / 2.0, 0x7a5232)
	_picture(Vector3(X0 + 0.02, 1.7, 0.9 if state < 3 else 2.0), Vector3(1, 0, 0), 0.5, 0.4, 0x5a3a22, 0x8aa8c0)
	_lamp(Vector3(0.0, TALL - 0.6, 3.0))
	if state < 2:                                    # a small table and two chairs: all the room there is
		_table(Vector3(1.9, 0.0, 2.0), 0.9, 0.9, 0.74, 0x8a6240)
		_chair(Vector3(1.9, 0.0, 1.3), PI, 0x7a5232)
		_chair(Vector3(2.6, 0.0, 2.0), PI / 2.0, 0x7a5232)
		_plant(Vector3(X1 - 0.4, 0.0, 5.5), 0.9)
		return
	# the kitchen along the back wall, right of the bed: cupboards under a worktop, the sink, the cooker, cupboards
	# over them on a wall of white tiles, a fridge at the end
	var kx0 := 1.0
	var kx1 := 4.3 if state >= 5 else 5.9
	box(kx0, 0.95, D - 0.012, kx1 - kx0, 0.75, 0.012, "azulejo")
	box(kx0, 0.0, D - 0.6, kx1 - kx0, 0.86, 0.6, 0xf0ece2)
	box(kx0 - 0.02, 0.86, D - 0.64, kx1 - kx0 + 0.04, 0.04, 0.64, "encimera")
	var n := int((kx1 - kx0) / 0.6)
	for i in range(n):
		box(kx0 + 0.04 + i * (kx1 - kx0) / n, 0.08, D - 0.62, (kx1 - kx0) / n - 0.08, 0.72, 0.02, 0xe2ddd0)
		box(kx0 + (i + 0.5) * (kx1 - kx0) / n - 0.06, 0.72, D - 0.64, 0.12, 0.02, 0.02, 0x8a8c90)
	box(kx0 + 0.7, 0.9, D - 0.5, 0.6, 0.012, 0.4, 0xb8bcc0)                    # the sink, its tap
	box(kx0 + 0.98, 0.9, D - 0.12, 0.04, 0.22, 0.04, 0x8a8c90)
	box(kx0 + 1.9, 0.9, D - 0.55, 0.6, 0.012, 0.5, 0x1e1e20)                   # the hob
	for i in range(4):
		drum(Vector3(kx0 + 2.05 + (i % 2) * 0.3, 0.912, D - 0.42 + (i >> 1) * 0.24), 0.09, 0.09, 0.006, 0x3a3a3e, 10)
	box(kx0 + 0.2, 1.75, D - 0.36, kx1 - kx0 - 0.4, 0.7, 0.36, 0xf0ece2)        # the cupboards over it
	solid(Vector3((kx0 + kx1) / 2.0, 0.45, D - 0.3), Vector3(kx1 - kx0, 0.9, 0.6))
	if state < 5:                                    # the fridge (in the last state the door to the stairs is there)
		box(6.2, 0.0, D - 0.66, 0.68, 1.85, 0.66, 0xe8eaec)
		box(6.24, 1.15, D - 0.68, 0.6, 0.012, 0.02, 0x9a9da0)
		solid(Vector3(6.54, 0.9, D - 0.33), Vector3(0.68, 1.85, 0.66))
	else:
		box(6.2, 0.0, 0.4, 0.68, 1.85, 0.66, 0xe8eaec)
		box(6.24, 1.15, 1.06, 0.6, 0.012, 0.02, 0x9a9da0)
		solid(Vector3(6.54, 0.9, 0.73), Vector3(0.68, 1.85, 0.66))
	props += 4
	# the table to eat at, its four chairs, its cloth; a dresser; a plant
	_table(Vector3(4.3, 0.0, 2.6), 1.5, 0.9, 0.76, 0x8a6240)
	box(3.6, 0.762, 2.2, 1.4, 0.008, 0.8, 0xe8dcc0)
	for q in [[3.85, 1.95, PI], [4.75, 1.95, PI], [3.85, 3.25, 0.0], [4.75, 3.25, 0.0]]:
		_chair(Vector3(float(q[0]), 0.0, float(q[1])), float(q[2]), 0x7a5232)
	if state < 4:
		box(WIDE - 0.45, 0.0, 1.6, 0.45, 0.95, 1.5, 0x7a5232)                   # the dresser on the right wall, plates on it
		box(WIDE - 0.4, 0.95, 1.6, 0.4, 1.0, 1.5, 0x8a6240)
		for k in range(3):
			box(WIDE - 0.38, 1.1 + k * 0.3, 1.65, 0.02, 0.2, 1.4, 0xf4f1ea)
		solid(Vector3(WIDE - 0.22, 1.0, 2.35), Vector3(0.45, 2.0, 1.5))
		props += 1
	_plant(Vector3(2.9, 0.0, 0.5), 1.0)
	_lamp(Vector3(4.3, TALL - 0.6, 2.6))

# ---------------- the bathroom ----------------
## Through the left wall: white tiles to the height of a man, a bath, the basin under its mirror, the pan, a window
## high up, towels on a rail, a mat.
func _bath() -> void:
	var r := LEFT
	var x0 := r.position.x
	var x1 := r.end.x
	_floor(r, 0.0, "azulejo", false)
	_through(x1, X0, LEFT_DOOR.x, LEFT_DOOR.y, 0.0, 2.05, "azulejo")
	_wall(Vector2(x1, r.position.y), Vector2(x1, r.end.y), 0.0, Vector3(-1, 0, 0), [[LEFT_DOOR.x, LEFT_DOOR.y, 2.05]], "cal", "azulejo", 1.9)
	_wall(Vector2(x0, r.position.y), Vector2(x0, r.end.y), 0.0, Vector3(1, 0, 0), [], "cal", "azulejo", 1.9)
	_wall(Vector2(x0, r.position.y), Vector2(x1, r.position.y), 0.0, Vector3(0, 0, 1), [], "cal", "azulejo", 1.9)
	_wall(Vector2(x0, r.end.y), Vector2(x1, r.end.y), 0.0, Vector3(0, 0, -1), [], "cal", "azulejo", 1.9)
	box(x0, 1.9, r.position.y, r.size.x, 0.05, 0.012, 0x3a7ab8)                  # a blue line over the tiles
	box(x0, 1.9, r.end.y - 0.012, r.size.x, 0.05, 0.012, 0x3a7ab8)
	# the bath along the far wall
	box(x0 + 0.05, 0.0, r.end.y - 0.8, 1.7, 0.56, 0.75, 0xf6f7f6)
	box(x0 + 0.12, 0.5, r.end.y - 0.73, 1.56, 0.07, 0.61, 0xcfe3ea)
	box(x0 + 0.1, 0.56, r.end.y - 0.14, 0.04, 0.3, 0.04, 0x9a9da0)
	solid(Vector3(x0 + 0.9, 0.3, r.end.y - 0.42), Vector3(1.7, 0.6, 0.75))
	# the basin and its mirror on the left wall, the pan beside it
	_put(Vector3(x0 + 0.02, 0.0, 1.5), PI / 2.0)
	box(-0.3, 0.8, 0.0, 0.6, 0.14, 0.45, 0xf6f7f6)
	box(-0.06, 0.0, 0.08, 0.12, 0.8, 0.18, 0xf6f7f6)
	box(-0.02, 0.94, 0.04, 0.04, 0.16, 0.04, 0x9a9da0)
	box(-0.3, 1.25, 0.0, 0.6, 0.7, 0.02, 0xbcd6e0)
	box(-0.33, 1.22, 0.0, 0.66, 0.03, 0.03, 0x9a9da0)
	home()
	solid(Vector3(x0 + 0.25, 0.45, 1.5), Vector3(0.5, 0.9, 0.6))
	_put(Vector3(x0 + 0.02, 0.0, 0.55), PI / 2.0)
	box(-0.19, 0.0, 0.1, 0.38, 0.4, 0.5, 0xf6f7f6)
	box(-0.21, 0.4, 0.08, 0.42, 0.04, 0.54, 0xf0f1f0)
	box(-0.2, 0.4, 0.0, 0.4, 0.42, 0.16, 0xf6f7f6)
	home()
	solid(Vector3(x0 + 0.33, 0.3, 0.55), Vector3(0.66, 0.6, 0.42))
	_pane(Vector3((x0 + x1) / 2.0, 1.75, r.position.y), Vector3(0, 0, 1), 0.7, 0.5, 0xf4f1ea)
	box(x1 - 0.06, 1.2, 2.3, 0.04, 0.03, 0.8, 0x9a9da0)                         # the rail and its towels
	box(x1 - 0.08, 0.75, 2.35, 0.03, 0.47, 0.3, 0x3a7ab8)
	box(x1 - 0.08, 0.8, 2.72, 0.03, 0.42, 0.3, 0xf0e6d0)
	box(x0 + 2.0, 0.0, 2.9, 0.8, 0.012, 0.5, 0x3a7ab8)                           # the mat
	props += 4
	_lamp(Vector3((x0 + x1) / 2.0, TALL - 0.6, 2.0), 5.0)

# ---------------- the sitting room ----------------
## Through the right wall: cream walls, a sofa and an armchair round a low table on a rug, the television on its
## sideboard, shelves of books, a window on the street, a brazier table for the winter.
func _sitting() -> void:
	var r := RIGHT
	var x0 := r.position.x
	var x1 := r.end.x
	_floor(r, 0.0, "hidraulica")
	_through(WIDE, x0, RIGHT_DOOR.x, RIGHT_DOOR.y, 0.0, 2.05, "hidraulica")
	_wall(Vector2(x0, r.position.y), Vector2(x0, r.end.y), 0.0, Vector3(1, 0, 0), [[RIGHT_DOOR.x, RIGHT_DOOR.y, 2.05]], "crema")
	_wall(Vector2(x1, r.position.y), Vector2(x1, r.end.y), 0.0, Vector3(-1, 0, 0), [], "crema")
	_wall(Vector2(x0, r.position.y), Vector2(x1, r.position.y), 0.0, Vector3(0, 0, 1), [], "crema")
	_wall(Vector2(x0, r.end.y), Vector2(x1, r.end.y), 0.0, Vector3(0, 0, -1), [], "crema")
	box(x0, 0.0, r.position.y, r.size.x, 0.1, 0.012, 0x7a5232)
	box(x0, 0.0, r.end.y - 0.012, r.size.x, 0.1, 0.012, 0x7a5232)
	_pane(Vector3((x0 + x1) / 2.0, 1.0, r.position.y), Vector3(0, 0, 1), 1.4, 1.15, 0x2f5a3a)
	# the sofa against the back wall, an armchair, the low table on its rug
	box(x0 + 0.7, 0.0, r.end.y - 0.95, 2.2, 0.42, 0.9, 0x6a7a4a)
	box(x0 + 0.7, 0.42, r.end.y - 0.3, 2.2, 0.5, 0.25, 0x6a7a4a)
	for sx in [x0 + 0.7, x0 + 2.68]:
		box(sx, 0.42, r.end.y - 0.95, 0.22, 0.25, 0.9, 0x5a6a3e)
	for k in range(2):
		box(x0 + 1.0 + k * 0.95, 0.42, r.end.y - 0.9, 0.85, 0.12, 0.6, 0x7a8a58)
	solid(Vector3(x0 + 1.8, 0.45, r.end.y - 0.5), Vector3(2.2, 0.9, 0.9))
	_put(Vector3(x1 - 0.6, 0.0, r.end.y - 2.4), -PI / 2.0)
	box(-0.45, 0.0, -0.4, 0.9, 0.4, 0.8, 0xb8683e)
	box(-0.45, 0.4, 0.2, 0.9, 0.5, 0.2, 0xb8683e)
	home()
	solid(Vector3(x1 - 0.6, 0.45, r.end.y - 2.4), Vector3(0.8, 0.9, 0.9))
	box(x0 + 0.8, 0.0, r.end.y - 3.0, 2.2, 0.012, 1.6, 0x8a3a2a)                 # the rug
	_table(Vector3(x0 + 1.9, 0.0, r.end.y - 2.2), 1.0, 0.55, 0.4, 0x8a6240)
	# the television on its sideboard, on the front wall side; shelves of books on the right wall
	box(x0 + 1.0, 0.0, r.position.y + 0.05, 1.8, 0.5, 0.45, 0x5a3a26)
	box(x0 + 1.25, 0.5, r.position.y + 0.2, 1.3, 0.75, 0.06, 0x1a1a1c)
	box(x0 + 1.29, 0.54, r.position.y + 0.262, 1.22, 0.67, 0.004, "pantalla")
	solid(Vector3(x0 + 1.9, 0.6, r.position.y + 0.28), Vector3(1.8, 1.2, 0.45))
	box(x1 - 0.32, 0.0, 0.5, 0.32, 1.9, 1.6, 0x7a5232)
	for k in range(4):
		for b in range(7):
			box(x1 - 0.3, 0.12 + k * 0.45, 0.56 + b * 0.21, 0.2, 0.3, 0.16, [0x8a2a2a, 0x2a5a8a, 0x3a7a4a, 0xc9a23a, 0x5a3a6a, 0xe8dcc0, 0x2a2a30][(b + k) % 7])
	solid(Vector3(x1 - 0.16, 0.95, 1.3), Vector3(0.32, 1.9, 1.6))
	_picture(Vector3(x0 + 1.8, 1.75, r.end.y - 0.02), Vector3(0, 0, -1), 0.9, 0.6, 0xc9a23a, 0x8ab0a0)
	_plant(Vector3(x0 + 0.4, 0.0, r.end.y - 0.5), 1.1)
	props += 6
	_lamp(Vector3((x0 + x1) / 2.0, TALL - 0.6, 3.0))

# ---------------- the upper floor ----------------
## Through the door at the back: a flight of stairs of wood between white walls, and up there one long room under
## the roof: boards on the floor, a desk and its lamp by the window, shelves, a rug and two armchairs, plants, and
## glazed doors onto the terrace with the day in them.
func _upstairs() -> void:
	var s := STAIRS
	# the way through the back wall, and the stairs
	_through(BACK_DOOR.x, BACK_DOOR.y, D, s.position.y, 0.0, 2.05, "hidraulica")
	box(BACK_DOOR.x - 0.08, 0.0, D - 0.03, 0.08, 2.13, 0.08, 0x5a3a22)
	box(BACK_DOOR.y, 0.0, D - 0.03, 0.08, 2.13, 0.08, 0x5a3a22)
	box(BACK_DOOR.x - 0.08, 2.05, D - 0.03, BACK_DOOR.y - BACK_DOOR.x + 0.16, 0.08, 0.08, 0x5a3a22)
	var n := 15
	for i in range(n):
		var z0 := s.position.y + s.size.y * i / n
		var y := UP * (i + 1) / n
		box(s.position.x, y - 0.2, z0, s.size.x, 0.2, s.size.y / n, 0x8a6240)
		box(s.position.x, y - 0.03, z0 - 0.02, s.size.x, 0.03, s.size.y / n + 0.02, 0xb8905a)
	for sx in [s.position.x, s.end.x]:                # its two walls, from the foot of the stairs to the top
		var nn := Vector3(1 if sx == s.position.x else -1, 0, 0)
		quad(Vector3(sx, -0.2, s.position.y), Vector3(sx, -0.2, s.end.y), Vector3(sx, UP + TALL, s.end.y), Vector3(sx, UP + TALL, s.position.y), "cal", nn)
		solid(Vector3(sx - nn.x * 0.2, (UP + TALL) / 2.0, s.position.y + s.size.y / 2.0), Vector3(0.4, UP + TALL + 0.4, s.size.y + 0.2))
		bar(Vector3(sx + nn.x * 0.06, 0.95, s.position.y + 0.1), Vector3(sx + nn.x * 0.06, UP + 0.95, s.end.y), 0.04, 0.04, 0x5a3a22)      # (a handrail)
	quad(Vector3(s.position.x, TALL, s.position.y), Vector3(s.end.x, TALL, s.position.y), Vector3(s.end.x, UP + TALL, s.end.y), Vector3(s.position.x, UP + TALL, s.end.y), "techo", Vector3(0, -1, 0.5).normalized())
	_lamp(Vector3(s.position.x + 0.5, UP + TALL - 0.7, s.end.y - 0.6), 6.0)
	# the room up there
	var r := UPPER
	var x0 := r.position.x
	var x1 := r.end.x
	var z0 := r.position.y
	var z1 := r.end.y
	_floor(r, UP, "tarima")
	_through(s.position.x, s.end.x, s.end.y, z0, UP, 2.2, "tarima")
	_wall(Vector2(x0, z0), Vector2(x1, z0), UP, Vector3(0, 0, 1), [[s.position.x, s.end.x, 2.2]], "cal")
	_wall(Vector2(x0, z1), Vector2(x1, z1), UP, Vector3(0, 0, -1), [], "cal")
	_wall(Vector2(x0, z0), Vector2(x0, z1), UP, Vector3(1, 0, 0), [], "cal")
	_wall(Vector2(x1, z0), Vector2(x1, z1), UP, Vector3(-1, 0, 0), [], "cal")
	for wx in [x0 + 2.0, x0 + 4.0, x0 + 6.0]:        # the terrace's glazed doors on the back wall
		_pane(Vector3(wx, UP + 0.05, z1), Vector3(0, 0, -1), 1.1, 2.1, 0x2f5a3a)
	# a desk and its lamp on the left, shelves over it; armchairs and a rug in the middle; plants; a chest
	_table(Vector3(x0 + 0.6, UP, z0 + 2.6), 0.8, 1.6, 0.76, 0x8a6240)
	box(x0 + 0.35, UP + 0.76, z0 + 2.2, 0.5, 0.012, 0.36, 0xf6f4ee)
	box(x0 + 0.4, UP + 0.76, z0 + 3.1, 0.12, 0.3, 0.12, 0x2a5a8a)
	ball(Vector3(x0 + 0.46, UP + 1.12, z0 + 3.16), 0.12, "luz", 0.8, 8, 4)
	_chair(Vector3(x0 + 1.4, UP, z0 + 2.6), PI / 2.0, 0x7a5232)
	box(x0, UP + 1.5, z0 + 1.8, 0.28, 0.04, 1.8, 0x7a5232)
	for b in range(8):
		box(x0 + 0.03, UP + 1.54, z0 + 1.86 + b * 0.2, 0.2, 0.26, 0.15, [0x8a2a2a, 0x2a5a8a, 0x3a7a4a, 0xc9a23a, 0x5a3a6a, 0xe8dcc0, 0x2a2a30, 0xb8683e][b])
	box(x0 + 3.0, UP, z0 + 2.2, 2.6, 0.012, 1.9, 0x3a5a8a)                        # the rug
	for q in [[x0 + 3.4, z0 + 3.9, PI], [x0 + 5.2, z0 + 3.9, PI]]:
		_put(Vector3(float(q[0]), UP, float(q[1])), float(q[2]))
		box(-0.45, 0.0, -0.4, 0.9, 0.4, 0.8, 0xb8683e)
		box(-0.45, 0.4, 0.2, 0.9, 0.5, 0.2, 0xb8683e)
		home()
		solid(Vector3(float(q[0]), UP + 0.45, float(q[1])), Vector3(0.9, 0.9, 0.8))
	_table(Vector3(x0 + 4.3, UP, z0 + 2.9), 0.9, 0.5, 0.4, 0x8a6240)
	box(x1 - 0.5, UP, z0 + 0.6, 0.5, 0.55, 1.2, 0x6f4a2c)                         # a chest
	solid(Vector3(x1 - 0.25, UP + 0.28, z0 + 1.2), Vector3(0.5, 0.55, 1.2))
	_plant(Vector3(x1 - 0.45, UP, z1 - 0.5), 1.2)
	_plant(Vector3(x0 + 0.45, UP, z1 - 0.5), 1.0)
	_picture(Vector3(x1 - 0.02, UP + 1.7, z0 + 3.4), Vector3(-1, 0, 0), 0.8, 0.55, 0xc9a23a, 0xc0a878)
	props += 5
	_lamp(Vector3(x0 + 2.2, UP + TALL - 0.6, z0 + 3.0))
	_lamp(Vector3(x0 + 5.8, UP + TALL - 0.6, z0 + 3.0))
