extends "res://scripts/obra.gd"
## The inside of the Vivero de Empresas of the Avenida de la Reina Sofía (vivero.gd builds its front). The user, 27
## November 2026: "Que se pueda pasar y tenga horario". A set built far out in the fields, like the other places you go
## into by the green arrow before their doors (entradas.gd); open in the Vivero's hours (vivero.gd set_open keeps it).
##
## What it is (the architects' published photographs of the rehabilitation and the Vivero's own pictures; the plan of
## the ground floor is ours, on the house's outline): white walls and ceilings, a floor of big grey tiles, navy steel
## and glass, and the blue of its front inside too.
##   - the hall: the reception counter with the Vivero's name on the wall behind it, two red armchairs, the cork board
##     of notices, the hours by the door, the frosted band of the front's windows;
##   - a corridor on, between the two glass offices on your left (DESPACHO 1, DESPACHO 2) and, on your right, a low
##     wall of blue mosaic under glass, the patio beyond it;
##   - the patio in the open air (where the real house has its yards, on the east): the lattice of the front again on
##     its walls, black wicker chairs round a low table, olive trees and plants in pots;
##   - the co-working room at the end, under three skylights: long white tables for fourteen, chairs of every colour,
##     and the floating stair of oak against a blue wall, a rope across its foot (the floor above is not built);
##   - behind it, the meeting room (a long table, the screen with "PLAN DE EMPRESA") and the office (the little
##     kitchen); the toilets' door, shut.
## A saffron flower is hidden in the patio, behind the pot of the far olive tree (the user, 28 November 2026: "Ponlo").
## Nobody in it (the user decides the figures). Everything is made here, of the kit's pieces and tools/vivero/'s
## pictures.
##
## What a place you go into has to give (game.gd _use_door): `door_out`, `out_spawn`, `out_h` in the street; `in_door`
## and `in_spawn` in the set; `open`. It has several rooms: `room_at` tells entradas.gd's camera which one you are in.
## The set's frame: +z deeper in, the door at z = 0; looking in, +x is on your left; y = 0 the floor.

const INSIDE := Vector2(-550.0, 1550.0)         # where the set is: no street within 225 m, no tree of the map within
                                                # 280 m, the other sets 1300 m off or more
const W2 := 6.0                                 # half its width
const D := 24.0                                 # how deep it is
const TH := 0.12                                # its inner walls
const DIR := "res://assets/vivero/"
const DOOR := Vector2(3.2, 4.8)                 # the glass doors from the porch (x from, to)
const PATIO := Rect2(-6.0, 5.0, 5.0, 8.0)       # the patio (x, z, wide, deep)
const HIGH := 6.6                               # the patio's walls (the house's two floors)
const STAIR := Rect2(4.95, 14.2, 1.0, 5.4)      # the floating stair (x, z, wide, long)
const STEPS := 20
const LABELS := ["RECEPCIÓN", "DESPACHO 1", "DESPACHO 2", "COWORKING", "SALA DE REUNIONES", "OFFICE", "ASEOS", "PATIO"]   # carteles.png's rows
const CHAIRS := [0xd8323a, 0xf2b31a, 0x2a5ac8, 0x3aa05a, 0xf07a24, 0x1a288c, 0xe85a8a]

## the rooms: [name, x0, x1, z0, z1, how tall, (unused), the wall the camera hangs on ("x0", "x1", "z0", "z1")]
const ROOMS: Array = [
	["recepcion", -6.0, 6.0, 0.0, 5.0, 3.0, "", "z0"],
	["pasillo", -1.0, 2.0, 5.0, 13.0, 3.0, "", "z0"],
	["despacho1", 2.0, 6.0, 5.0, 9.0, 3.0, "", "x0"],
	["despacho2", 2.0, 6.0, 9.0, 13.0, 3.0, "", "x0"],
	["patio", -6.0, -1.0, 5.0, 13.0, 6.6, "", "x1"],
	["coworking", -6.0, 6.0, 13.0, 20.0, 3.6, "", "z0"],
	["office", -6.0, -3.0, 20.0, 24.0, 3.0, "", "z0"],
	["reuniones", 0.0, 6.0, 20.0, 24.0, 3.0, "", "z0"]]

var door_out: Vector2
var out_spawn: Vector2
var out_h := 0.0
var in_door: Vector2
var in_spawn: Vector2
var open := false               # the Vivero's hours (vivero.gd)
var props := 0                  # how many pieces of furniture it has (the self-test)
var desks := 0                  # the places to work in the co-working room (the self-test)
var lamps := 0
var _sun: Array = []            # the materials of the patio, in the open air (the sun lights those)
var _open_air: Array = []       # the nodes left out of the indoors layer (the saffron, in the patio)
var saffron_spot: Vector2       # the hidden saffron (in the game's flowers, "id": "vivero")
var _n := 0

# ---------------- materials ----------------
func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: StandardMaterial3D = null
	var name: String = String(key) if key is String else ""
	match name:
		"suelo":            # big grey tiles
			var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
			for y in range(32):
				for x in range(32):
					var c := Color(0.72, 0.72, 0.71).lightened(0.025 * sin(x * 0.7 + y * 0.3))
					if x == 0 or y == 0:
						c = Color(0.6, 0.6, 0.59)
					img.set_pixel(x, y, c)
			m = _pattern(img, 0.6, 0.25)
			m.roughness = 0.35
		"pared":
			m = _lit(Color(0.97, 0.97, 0.96), 0.3)
		"techo":
			m = _lit(Color(0.96, 0.96, 0.95), 0.32)
		"azul":             # the stair's wall: the front's blue
			m = _lit(Color(0.16, 0.24, 0.62), 0.28)
		"mosaico":          # small tiles of three blues
			var img := Image.create(12, 12, false, Image.FORMAT_RGB8)
			var blues := [Color(0.12, 0.2, 0.6), Color(0.2, 0.34, 0.72), Color(0.32, 0.5, 0.82)]
			for y in range(12):
				for x in range(12):
					img.set_pixel(x, y, Color(0.86, 0.88, 0.9) if x % 4 == 0 or y % 4 == 0 else blues[((x / 4) * 5 + (y / 4) * 7) % 3])
			m = _pattern(img, 0.075, 0.3)
			m.roughness = 0.25
		"madera":           # the stair's oak, the tables' edges
			m = _lit(Color(0.76, 0.6, 0.4), 0.22)
		"rojo":             # the armchairs
			m = _lit(Color(0.72, 0.1, 0.14), 0.18)
		"calle":            # the porch's light beyond the glass doors
			m = _lit(Color(0.9, 0.94, 1.0), 1.3)
		"esmerilado":       # the front's frosted panes, lit from outside
			m = _lit(Color(0.92, 0.94, 0.95), 0.9)
		"luz":
			m = _lit(Color(1.0, 0.99, 0.96), 1.8)
		"cielo":            # the skylights
			m = _lit(Color(0.86, 0.93, 1.0), 1.5)
		"hueco":            # the stair's well, up to the floor not built
			m = _lit(Color(0.85, 0.85, 0.84), 0.12)
		"pantalla_negra":
			m = _lit(Color(0.06, 0.06, 0.07), 0.05)
			m.roughness = 0.1
		"cristal":
			m = StandardMaterial3D.new()
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.75, 0.86, 0.9, 0.2)
			m.roughness = 0.1
			m.metallic_specular = 0.8
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"rotulo", "placas", "tablon", "pantalla", "carteles":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(DIR + name + ".png")
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			m.roughness = 0.8
			m.emission_enabled = true
			m.emission_texture = m.albedo_texture
			m.emission = Color.WHITE
			m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY      # (the picture's own colours, with no grey veil over them)
			m.emission_energy_multiplier = 0.85 if name == "pantalla" else 0.4
			if name == "rotulo":
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				m.alpha_scissor_threshold = 0.5
		# the patio, in the open air
		"revoco_sol":       # white render
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.97, 0.96, 0.93)), 0.08)
		"celosia_sol":      # the front's lattice
			m = StandardMaterial3D.new()
			m.albedo_texture = load(DIR + "celosia.png")
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.5
			m.roughness = 0.95
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"baldosa_sol":      # terracotta tiles
			var img := Image.create(16, 16, false, Image.FORMAT_RGB8)
			for y in range(16):
				for x in range(16):
					var c := Color(0.72, 0.42, 0.28).lightened(0.04 * sin(x * 1.3 + y * 0.8))
					if x == 0 or y == 0:
						c = Color(0.82, 0.76, 0.66)
					img.set_pixel(x, y, c)
			m = _pattern(img, 0.33, 0.0)
		"mimbre_sol":       # black wicker
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.08, 0.08, 0.09)
			m.roughness = 0.7
		"maceta_sol":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.62, 0.32, 0.2)
			m.roughness = 0.9
		"hoja_sol":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.36, 0.46, 0.3)
			m.roughness = 0.9
		"olivo_sol":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.5, 0.56, 0.44)
			m.roughness = 0.9
		"tronco_sol":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.36, 0.3, 0.24)
			m.roughness = 1.0
		"piedra_sol":       # the copings
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.86, 0.84, 0.8)
			m.roughness = 0.9
		"mesa_sol":         # the patio's low table
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.9, 0.9, 0.88)
			m.roughness = 0.6
		_:
			var pm := Parts.mat(int(key)).duplicate() as StandardMaterial3D      # (plain colours, with a little light of their own: it is a set, lit by its lamps alone)
			pm.emission_enabled = true
			pm.emission = pm.albedo_color
			pm.emission_energy_multiplier = 0.25
			_mats[key] = pm
			return pm
	_mats[key] = m
	if name.ends_with("_sol"):
		_sun.append(m)
	return m

func _lit(c: Color, how: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = how
	return m

## a little picture laid on a floor or a wall by the world's own axes: `metres` a repeat
func _pattern(img: Image, metres: float, how: float) -> StandardMaterial3D:
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / metres
	m.roughness = 1.0
	if how > 0.0:
		m.emission_enabled = true
		m.emission_texture = m.albedo_texture
		m.emission = Color.WHITE
		m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
		m.emission_energy_multiplier = how
	return m

# ---------------- building it ----------------
func build(world, at: Vector2, out: Vector2, heading: float) -> void:
	W = world
	door_out = at
	out_spawn = out
	out_h = heading
	var top := -1e9
	for dx in range(-int(W2) - 2, int(W2) + 3, 2):
		for dz in range(-2, int(D) + 3, 2):
			top = maxf(top, MapData.height(INSIDE + Vector2(dx, dz)))
	level = top + 0.03
	var ring := PackedVector2Array([INSIDE + Vector2(-W2 - 0.6, -0.6), INSIDE + Vector2(W2 + 0.6, -0.6), INSIDE + Vector2(W2 + 0.6, D + 0.6), INSIDE + Vector2(-W2 - 0.6, D + 0.6)])
	MapData.decks.append({"o": INSIDE + Vector2(0.0, D / 2.0), "poly": ring, "r2": (W2 + 2.0) * (W2 + 2.0) + (D / 2.0 + 2.0) * (D / 2.0 + 2.0), "top": level})
	transform = Transform3D(Basis.IDENTITY, Vector3(INSIDE.x, level, INSIDE.y))
	W.add_child(self)
	in_door = INSIDE + Vector2((DOOR.x + DOOR.y) / 2.0, 0.45)
	in_spawn = INSIDE + Vector2((DOOR.x + DOOR.y) / 2.0, 1.6)
	_shell()
	_inner_walls()
	_hall()
	_offices()
	_patio()
	_coworking()
	_stair()
	_meeting()
	_kitchen()
	_signs()
	_lamps()
	home()
	_commit()
	_indoors(self)

## everything but the patio is indoors: no sun on it (game.gd's render layer 11)
func _indoors(n: Node) -> void:
	if n in _open_air:
		return
	if n is MeshInstance3D and not ((n as MeshInstance3D).material_override in _sun):
		(n as MeshInstance3D).layers = 1 << 10
	for c in n.get_children():
		_indoors(c)

## the room you are in, for entradas.gd's camera: the middle of the wall it hangs on, which way it looks, how big
func room_at(pp: Vector2) -> Dictionary:
	var p := pp - INSIDE
	var best: Array = []
	var bd := 1e9
	for r in ROOMS:
		var mid := Vector2((float(r[1]) + float(r[2])) / 2.0, (float(r[3]) + float(r[4])) / 2.0)
		var half := Vector2((float(r[2]) - float(r[1])) / 2.0, (float(r[4]) - float(r[3])) / 2.0)
		var q := (p - mid).abs() - half
		var d := maxf(q.x, q.y)                         # (how far outside it: below zero, inside)
		if d < bd:
			bd = d
			best = r
	var x0: float = best[1]
	var x1: float = best[2]
	var z0: float = best[3]
	var z1: float = best[4]
	var fwd := Vector2(0, 1)
	var at := Vector2((x0 + x1) / 2.0, z0)
	var half_w := (x1 - x0) / 2.0
	var deep := z1 - z0
	match String(best[7]):
		"z1":
			fwd = Vector2(0, -1); at = Vector2((x0 + x1) / 2.0, z1)
		"x0":
			fwd = Vector2(1, 0); at = Vector2(x0, (z0 + z1) / 2.0); half_w = (z1 - z0) / 2.0; deep = x1 - x0
		"x1":
			fwd = Vector2(-1, 0); at = Vector2(x1, (z0 + z1) / 2.0); half_w = (z1 - z0) / 2.0; deep = x1 - x0
	return {"o": INSIDE + at, "fwd": fwd, "side": Vector2(-fwd.y, fwd.x), "half": half_w, "deep": deep, "tall": float(best[5]), "name": String(best[0])}

## where a piece stands: `at` its foot, turned `yaw` about the upright (until home())
func _put(at: Vector3, yaw := 0.0) -> void:
	_xf = Transform3D(Basis(Vector3.UP, yaw), at)
	props += 1

## A piece of thick wall along the straight line from a to b (x, z), from y0 to y1: its face on the left of the way
## from a to b (`kl`), the one on its right (`kr`), its top and its ends; the line is its middle. A solid for it if
## it is low enough to be walked into.
func _piece(a: Vector2, b: Vector2, y0: float, y1: float, kl, kr, th := TH) -> void:
	if y1 - y0 < 0.005 or a.distance_to(b) < 0.005:
		return
	pieces += 1
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x) * th / 2.0
	var nl := Vector3(n.x, 0, n.y).normalized()
	var la := a + n
	var lb := b + n
	var ra := a - n
	var rb := b - n
	quad(Vector3(la.x, y0, la.y), Vector3(lb.x, y0, lb.y), Vector3(lb.x, y1, lb.y), Vector3(la.x, y1, la.y), kl, nl)
	quad(Vector3(rb.x, y0, rb.y), Vector3(ra.x, y0, ra.y), Vector3(ra.x, y1, ra.y), Vector3(rb.x, y1, rb.y), kr, -nl)
	quad(Vector3(la.x, y1, la.y), Vector3(lb.x, y1, lb.y), Vector3(rb.x, y1, rb.y), Vector3(ra.x, y1, ra.y), kl, Vector3.UP)
	if y0 > 0.01:
		quad(Vector3(ra.x, y0, ra.y), Vector3(rb.x, y0, rb.y), Vector3(lb.x, y0, lb.y), Vector3(la.x, y0, la.y), kl, Vector3.DOWN)
	var dd := Vector3(d.x, 0, d.y)
	quad(Vector3(ra.x, y0, ra.y), Vector3(la.x, y0, la.y), Vector3(la.x, y1, la.y), Vector3(ra.x, y1, ra.y), kl, -dd)
	quad(Vector3(lb.x, y0, lb.y), Vector3(rb.x, y0, rb.y), Vector3(rb.x, y1, rb.y), Vector3(lb.x, y1, lb.y), kl, dd)
	if y0 < 1.7:
		var mid := (a + b) / 2.0
		var ln := a.distance_to(b)
		solid(Vector3(mid.x, (y0 + y1) / 2.0, mid.y), Vector3(ln, y1 - y0, th), -atan2(d.y, d.x))

## a wall from a to b with its holes ([from, to along it, from y, to y]): the pieces round them
func _wall(a: Vector2, b: Vector2, tall: float, holes: Array, kl, kr, th := TH) -> void:
	var ln := a.distance_to(b)
	var d := (b - a) / ln
	holes.sort_custom(func(p, q): return float(p[0]) < float(q[0]))
	var s := 0.0
	for h in holes:
		_piece(a + d * s, a + d * float(h[0]), 0.0, tall, kl, kr, th)
		_piece(a + d * float(h[0]), a + d * float(h[1]), 0.0, float(h[2]), kl, kr, th)
		_piece(a + d * float(h[0]), a + d * float(h[1]), float(h[3]), tall, kl, kr, th)
		s = float(h[1])
	_piece(a + d * s, b, 0.0, tall, kl, kr, th)

## a pane of glass from a to b, from y0 to y1, in a frame of navy steel; a solid for it
func _glass(a: Vector2, b: Vector2, y0: float, y1: float, frame := 0x1a288c) -> void:
	pieces += 1
	quad(Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y), "cristal", Vector3(-(b - a).y, 0, (b - a).x).normalized())
	var d := (b - a).normalized()
	for p: Vector2 in [a, b]:
		cbox(Vector3(p.x, (y0 + y1) / 2.0, p.y), Vector3(0.05, y1 - y0, 0.05), frame)
	var mid := (a + b) / 2.0
	var ln := a.distance_to(b)
	var rail := Vector3(ln, 0.04, 0.05) if absf(d.x) > 0.5 else Vector3(0.05, 0.04, ln)
	cbox(Vector3(mid.x, y0 + 0.02, mid.y), rail, frame)
	cbox(Vector3(mid.x, y1 - 0.02, mid.y), rail, frame)
	solid(Vector3(mid.x, (y0 + y1) / 2.0, mid.y), Vector3(ln, y1 - y0, 0.06), -atan2(d.y, d.x))

## a picture on a wall: its middle, which way it faces (n, flat), how wide and high, the part of the picture (v0, v1)
func _picture(mid: Vector3, n: Vector3, w: float, h: float, key, v0 := 0.0, v1 := 1.0) -> void:
	pieces += 1
	var side := Vector3(n.z, 0, -n.x) * (w / 2.0)       # (to the picture's right as you look at it)
	var up := Vector3(0, h / 2.0, 0)
	var c := mid + n * 0.012
	quad(c - side - up, c + side - up, c + side + up, c - side + up, key, n,
		[Vector2(0, v1), Vector2(1, v1), Vector2(1, v0), Vector2(0, v0)])

## one of the doors' signs (carteles.png's rows): `mid` on the face of its wall, `n` out of it
func _cartel(label: String, mid: Vector3, n: Vector3, w := 0.8) -> void:
	var i := LABELS.find(label)
	cbox(mid + n * 0.006, Vector3(absf(n.z) * w + absf(n.x) * 0.012, w / 8.0, absf(n.x) * w + absf(n.z) * 0.012), 0xf2f2ee)
	_picture(mid + n * 0.012, n, w * 0.98, w / 8.0 * 0.96, "carteles", i / 8.0, (i + 1) / 8.0)

# ---------------- the shell and its walls ----------------
## the floors, the ceilings and the outer walls (outside the rooms' sizes, 20 cm thick); the doors from the porch,
## the porch's light beyond them, the frosted band of the front's windows
func _shell() -> void:
	# floors: the patio's apart
	for r: Rect2 in [Rect2(-W2, 0, 2 * W2, 5), Rect2(-1, 5, 7, 8), Rect2(-W2, 13, 2 * W2, 11)]:
		quad(Vector3(r.position.x, 0, r.position.y), Vector3(r.end.x, 0, r.position.y), Vector3(r.end.x, 0, r.end.y), Vector3(r.position.x, 0, r.end.y), "suelo", Vector3.UP)
	quad(Vector3(PATIO.position.x, 0, PATIO.position.y), Vector3(PATIO.end.x, 0, PATIO.position.y), Vector3(PATIO.end.x, 0, PATIO.end.y), Vector3(PATIO.position.x, 0, PATIO.end.y), "baldosa_sol", Vector3.UP)
	# ceilings: 3 m but the co-working room's, 3.6 under its skylights and over the stair's well
	for r: Rect2 in [Rect2(-W2, 0, 2 * W2, 5), Rect2(-1, 5, 7, 8), Rect2(-W2, 20, 2 * W2, 4)]:
		quad(Vector3(r.position.x, 3.0, r.end.y), Vector3(r.end.x, 3.0, r.end.y), Vector3(r.end.x, 3.0, r.position.y), Vector3(r.position.x, 3.0, r.position.y), "techo", Vector3.DOWN)
		solid(Vector3(r.get_center().x, 3.1, r.get_center().y), Vector3(r.size.x, 0.2, r.size.y))
	var holes: Array = [Rect2(-4.6, 15.8, 1.4, 1.4), Rect2(-2.0, 15.8, 1.4, 1.4), Rect2(0.6, 15.8, 1.4, 1.4), Rect2(STAIR.position.x - 0.05, 16.6, STAIR.size.x + 0.1, 3.4)]
	var xs: Array = [-W2, W2]
	var zs: Array = [13.0, 20.0]
	for h: Rect2 in holes:
		xs.append_array([h.position.x, h.end.x])
		zs.append_array([h.position.y, h.end.y])
	xs.sort()
	zs.sort()
	for i in range(xs.size() - 1):
		for j in range(zs.size() - 1):
			var c := Vector2((xs[i] + xs[i + 1]) / 2.0, (zs[j] + zs[j + 1]) / 2.0)
			var hole := false
			for h: Rect2 in holes:
				if h.has_point(c):
					hole = true
			if not hole and xs[i + 1] - xs[i] > 0.005 and zs[j + 1] - zs[j] > 0.005:
				quad(Vector3(xs[i], 3.6, zs[j + 1]), Vector3(xs[i + 1], 3.6, zs[j + 1]), Vector3(xs[i + 1], 3.6, zs[j]), Vector3(xs[i], 3.6, zs[j]), "techo", Vector3.DOWN)
	solid(Vector3(0, 3.7, 16.5), Vector3(2 * W2, 0.2, 7.0))
	# the skylights' wells, white up to the glass; the stair's, up to the floor not built
	for h: Rect2 in holes:
		var top := 4.4 if h.size.y < 2.0 else 6.4
		var key := "pared" if h.size.y < 2.0 else "hueco"
		var a := Vector3(h.position.x, 3.6, h.position.y)
		var b := Vector3(h.end.x, 3.6, h.end.y)
		quad(Vector3(a.x, a.y, a.z), Vector3(b.x, a.y, a.z), Vector3(b.x, top, a.z), Vector3(a.x, top, a.z), key, Vector3(0, 0, 1))
		quad(Vector3(b.x, a.y, b.z), Vector3(a.x, a.y, b.z), Vector3(a.x, top, b.z), Vector3(b.x, top, b.z), key, Vector3(0, 0, -1))
		quad(Vector3(a.x, a.y, b.z), Vector3(a.x, a.y, a.z), Vector3(a.x, top, a.z), Vector3(a.x, top, b.z), key, Vector3(1, 0, 0))
		quad(Vector3(b.x, a.y, a.z), Vector3(b.x, a.y, b.z), Vector3(b.x, top, b.z), Vector3(b.x, top, a.z), key, Vector3(-1, 0, 0))
		quad(Vector3(a.x, top, b.z), Vector3(b.x, top, b.z), Vector3(b.x, top, a.z), Vector3(a.x, top, a.z), "cielo" if top < 5.0 else "hueco", Vector3.DOWN)
	# the outer walls: the front (the doors from the porch, the band of the windows), the back, the sides
	var f := -0.1
	_wall(Vector2(-W2 - 0.2, f), Vector2(W2 + 0.2, f), 3.0, [[DOOR.x + W2 + 0.2, DOOR.y + W2 + 0.2, 0.0, 2.4], [0.6, 5.6, 0.75, 1.9]], "pared", "pared", 0.2)
	quad(Vector3(DOOR.x, 0, -0.25), Vector3(DOOR.y, 0, -0.25), Vector3(DOOR.y, 2.4, -0.25), Vector3(DOOR.x, 2.4, -0.25), "calle", Vector3(0, 0, 1))
	quad(Vector3(-5.6, 0.75, -0.12), Vector3(-0.6, 0.75, -0.12), Vector3(-0.6, 1.9, -0.12), Vector3(-5.6, 1.9, -0.12), "esmerilado", Vector3(0, 0, 1))
	for x in [-5.6, -4.52, -3.78, -2.7, -1.68, -0.65]:                                 # (the band's mullions, as outside)
		box(x, 0.75, -0.1, 0.05, 1.15, 0.12, 0x1a288c)
	box(-5.6, 0.71, -0.1, 5.0, 0.05, 0.16, 0x1a288c)
	box(-5.6, 1.88, -0.1, 5.0, 0.04, 0.12, 0x1a288c)
	for x in [DOOR.x, (DOOR.x + DOOR.y) / 2.0 - 0.03, DOOR.y - 0.06]:                   # the glass doors, open while you are here
		box(x, 0.0, -0.12, 0.06, 2.34, 0.1, 0x1a288c)
	box(DOOR.x, 2.34, -0.12, DOOR.y - DOOR.x, 0.06, 0.1, 0x1a288c)     # (frame inside the opening: its sides against the wall's)
	box(DOOR.x - 0.2, 0.0, 0.15, DOOR.y - DOOR.x + 0.4, 0.014, 0.9, 0x3a3a3c)            # (the mat)
	solid(Vector3((DOOR.x + DOOR.y) / 2.0, 1.2, -0.35), Vector3(DOOR.y - DOOR.x, 2.4, 0.2))
	solid(Vector3(0.0, 1.5, -0.3), Vector3(2.0 * W2 + 0.4, 3.0, 0.2))                    # (and behind the whole front: the band of windows is no way out)
	_wall(Vector2(W2 + 0.2, D + 0.1), Vector2(-W2 - 0.2, D + 0.1), 3.6, [], "pared", "pared", 0.2)
	var r := -W2 - 0.1                                  # the right as you come in
	_wall(Vector2(r, 5.0), Vector2(r, 0.0), 3.0, [], "pared", "pared", 0.2)
	_wall(Vector2(r, 13.0), Vector2(r, 5.0), HIGH, [], "revoco_sol", "pared", 0.2)
	_wall(Vector2(r, 20.0), Vector2(r, 13.0), 3.6, [], "pared", "pared", 0.2)
	_wall(Vector2(r, D), Vector2(r, 20.0), 3.0, [], "pared", "pared", 0.2)
	var l := W2 + 0.1                                   # the left
	_wall(Vector2(l, 0.0), Vector2(l, 13.0), 3.0, [], "pared", "pared", 0.2)
	_wall(Vector2(l, 13.0), Vector2(l, 20.0), 3.6, [], "azul", "pared", 0.2)
	_wall(Vector2(l, 20.0), Vector2(l, D), 3.0, [], "pared", "pared", 0.2)
	box(-W2, 0.0, 0.0, 0.01, 0.08, 5.0, 0xd8d6d0)                                         # (the skirting, here and there)
	box(W2 - 0.01, 0.0, 0.0, 0.01, 0.08, 13.0, 0xd8d6d0)

## the walls between the rooms
func _inner_walls() -> void:
	var h := TH / 2.0
	# the hall's back: the patio's wall (on up, the house's two floors), the corridor's way on, the offices' wall
	_wall(Vector2(-W2, 5.0), Vector2(-1.0 - h, 5.0), HIGH, [], "revoco_sol", "pared")
	_wall(Vector2(-1.0 - h, 5.0), Vector2(W2, 5.0), 3.0, [[0.0, 3.0 + h, 0.0, 2.6]], "pared", "pared")
	# the corridor's side to the patio: a low wall of blue mosaic under glass, the patio's glass door, the wall on up
	var z0 := 5.0 + h
	var z1 := 13.0 - h
	var gate := Vector2(8.4, 9.4)
	for seg: Vector2 in [Vector2(z0, gate.x), Vector2(gate.y, z1)]:
		_piece(Vector2(-1.0, seg.y), Vector2(-1.0, seg.x), 0.0, 0.9, "mosaico", "revoco_sol")
		_glass(Vector2(-1.0, seg.x), Vector2(-1.0, seg.y), 0.9, 2.6)
	_piece(Vector2(-1.0, z1), Vector2(-1.0, z0), 2.6, HIGH, "pared", "revoco_sol")
	for z in [gate.x, gate.y - 0.05]:                   # (the door's frame; its leaf open against the low wall)
		box(-1.05, 0.0, z, 0.1, 2.6, 0.05, 0x1a288c)
	_put(Vector3(-1.0, 0.0, gate.y + 0.05), -PI / 2.0 + 0.15)
	quad(Vector3(0, 0.02, 0.0), Vector3(0, 0.02, 0.95), Vector3(0, 2.55, 0.95), Vector3(0, 2.55, 0.0), "cristal", Vector3(1, 0, 0))
	box(-0.02, 0.0, 0.0, 0.04, 2.57, 0.04, 0x1a288c)
	box(-0.02, 0.0, 0.91, 0.04, 2.57, 0.04, 0x1a288c)
	home()
	# the offices' glass to the corridor, their doors; the wall between them
	for o: Vector2 in [Vector2(z0, 9.0 - h), Vector2(9.0 + h, z1)]:
		var dz0 := o.x + 0.45
		var dz1 := dz0 + 1.0
		_glass(Vector2(2.0, o.x), Vector2(2.0, dz0), 0.0, 2.6)
		_glass(Vector2(2.0, dz1), Vector2(2.0, o.y), 0.0, 2.6)
		for z in [dz0, dz1 - 0.05]:
			box(1.95, 0.0, z, 0.1, 2.6, 0.05, 0x1a288c)
	_piece(Vector2(2.0, z1), Vector2(2.0, z0), 2.6, 3.0, "pared", "pared")
	_wall(Vector2(2.0 + h, 9.0), Vector2(W2, 9.0), 3.0, [], "pared", "pared")
	# the co-working room's front: glass to the patio over a low wall, the corridor's way in, the offices' back
	_piece(Vector2(-W2, 13.0), Vector2(-1.0 - h, 13.0), 0.0, 0.9, "pared", "revoco_sol")
	_glass(Vector2(-W2 + 0.05, 13.0), Vector2(-1.0 - h, 13.0), 0.9, 2.8)
	_piece(Vector2(-W2, 13.0), Vector2(-1.0 - h, 13.0), 2.8, HIGH, "pared", "revoco_sol")
	_wall(Vector2(-1.0 - h, 13.0), Vector2(W2, 13.0), 3.6, [[0.0, 3.0 + h, 0.0, 2.6]], "pared", "pared")
	# the back rooms: the office's way in, the toilets' (shut), the meeting room's; the walls between them
	_wall(Vector2(-W2, 20.0), Vector2(W2, 20.0), 3.6, [[1.0, 2.2, 0.0, 2.3], [7.0, 8.2, 0.0, 2.3]], "pared", "pared")
	_wall(Vector2(-3.0, 20.0 + h), Vector2(-3.0, D), 3.0, [], "pared", "pared")
	_wall(Vector2(0.0, 20.0 + h), Vector2(0.0, D), 3.0, [], "pared", "pared")
	# frames of the ways through
	for q in [[-1.0, 2.0, 5.0], [-1.0, 2.0, 13.0], [-5.0, -3.8, 20.0], [1.0, 2.2, 20.0]]:
		var tall := 2.6 if float(q[2]) < 15.0 else 2.3
		for x in [float(q[0]) + 0.0, float(q[1]) - 0.04]:
			box(x, 0.0, float(q[2]) - h - 0.005, 0.04, tall, TH + 0.01, 0xe8e8e4)
	# the toilets' door, shut
	box(-2.25, 0.0, 19.9, 1.0, 2.15, 0.04, 0xd8d0c0)
	box(-2.31, 0.0, 19.89, 0.06, 2.2, 0.05, 0xe8e8e4)
	box(-1.25, 0.0, 19.89, 0.06, 2.2, 0.05, 0xe8e8e4)
	box(-2.25, 2.15, 19.89, 1.0, 0.05, 0.05, 0xe8e8e4)
	box(-1.45, 1.0, 19.87, 0.12, 0.025, 0.02, 0xb8bcc0)

# ---------------- the hall ----------------
func _hall() -> void:
	# the reception counter, white over a navy front; the desk behind it, its chair, a screen; the name on the wall
	var c := Rect2(-5.2, 3.2, 3.0, 0.5)
	box(c.position.x, 0.0, c.position.y, c.size.x, 1.05, c.size.y, 0x1a288c)
	box(c.position.x - 0.05, 1.05, c.position.y - 0.08, c.size.x + 0.1, 0.04, c.size.y + 0.08, 0xf2f2ee)
	solid(Vector3(c.get_center().x, 0.55, c.get_center().y), Vector3(c.size.x + 0.1, 1.1, c.size.y + 0.1))
	box(c.position.x + 0.05, 0.0, c.end.y, c.size.x - 0.1, 0.74, 0.4, 0xf2f2ee)                 # (the desk on its inside)
	_screen(Vector3(-3.0, 0.74, c.end.y + 0.1), PI)
	_chair(Vector3(-3.7, 0.0, 4.45), 0.0, 0x1a1a1c)
	solid(Vector3(c.get_center().x, 0.4, c.end.y + 0.2), Vector3(c.size.x, 0.8, 0.4))
	_picture(Vector3(-3.7, 2.05, 5.0 - TH / 2.0), Vector3(0, 0, -1), 3.0, 0.88, "rotulo")
	# two red armchairs and a low table, against the offices' wall
	for x in [3.3, 4.9]:
		_armchair(Vector3(x, 0.0, 4.45), 0.0)
	_put(Vector3(4.1, 0.0, 3.5))
	box(-0.4, 0.0, -0.3, 0.8, 0.4, 0.6, 0xf2f2ee)
	box(-0.3, 0.4, -0.15, 0.25, 0.02, 0.32, 0xd8323a)                                     # (leaflets)
	box(0.05, 0.4, -0.12, 0.22, 0.02, 0.3, 0x2a5ac8)
	home()
	solid(Vector3(4.1, 0.3, 4.1), Vector3(2.6, 0.6, 1.6))
	# the cork board on the wall at your left, the hours by the doors
	box(W2 - 0.03, 1.05, 1.1, 0.03, 0.94, 1.5, 0x8a6a48)
	_picture(Vector3(W2 - 0.03, 1.52, 1.85), Vector3(-1, 0, 0), 1.44, 0.88, "tablon")
	_picture(Vector3(2.75, 1.5, 0.0), Vector3(0, 0, 1), 0.5, 0.25, "placas", 0.5, 1.0)
	_picture(Vector3(2.75, 1.82, 0.0), Vector3(0, 0, 1), 0.5, 0.25, "placas", 0.0, 0.5)
	# plants in the corners
	for p in [Vector2(-5.55, 0.5), Vector2(5.55, 4.5), Vector2(-1.6, 4.55)]:
		_plant(Vector3(p.x, 0.0, p.y), 1.2)

# ---------------- the offices ----------------
func _offices() -> void:
	for z in [5.0, 9.0]:
		var zc: float = z + 2.0
		# the desk against the outer wall, its chair, two chairs for whoever comes; a shelf, a plant
		_desk(Vector3(4.9, 0.0, zc + 0.3), PI / 2.0, 1.4, 0.7)
		_screen(Vector3(4.8, 0.74, zc + 0.3), -PI / 2.0)
		_chair(Vector3(5.5, 0.0, zc + 0.3), PI / 2.0, CHAIRS[_next()])
		_chair(Vector3(3.7, 0.0, zc - 0.1), -PI / 2.0, 0x2a2a2c)
		_chair(Vector3(3.7, 0.0, zc + 0.7), -PI / 2.0, 0x2a2a2c)
		solid(Vector3(4.9, 0.4, zc + 0.3), Vector3(0.7, 0.8, 1.4))
		_put(Vector3(W2 - 0.2, 0.0, z + 0.5))           # (an open shelf against the wall: its back, its sides, its boards, binders on them)
		box(0.15, 0.0, 0.0, 0.03, 1.8, 1.1, 0xf2f2ee)
		for sz in [0.0, 1.08]:
			box(-0.18, 0.0, sz, 0.33, 1.8, 0.02, 0xf2f2ee)
		for k in range(5):
			box(-0.18, k * 0.42 + (0.03 if k == 4 else 0.0), 0.02, 0.33, 0.03, 1.06, 0xe8e8e4)
		for k in range(4):
			for j in range(3):
				box(-0.12, k * 0.42 + 0.03, 0.1 + j * 0.09 + (k % 2) * 0.4, 0.24, 0.3, 0.07, [0x1a288c, 0xd8323a, 0x3aa05a, 0xf2b31a][(k + j) % 4])
		home()
		solid(Vector3(W2 - 0.2, 0.9, z + 1.05), Vector3(0.4, 1.8, 1.1))
		_plant(Vector3(2.5, 0.0, z + 3.55), 0.9)

# ---------------- the patio ----------------
## the lattice on its walls, its tiles, the wicker chairs round a low table, olive trees and plants in pots, copings
func _patio() -> void:
	var x0 := PATIO.position.x
	var x1 := PATIO.end.x
	var z0 := PATIO.position.y
	var z1 := PATIO.end.y
	var uv := func(s: float, y: float) -> Vector2: return Vector2(s / 0.4, -y / 0.3)
	# the lattice, 4 cm before the render of its far wall and of the hall's, up to the first floor's sills
	quad(Vector3(x0 + 0.04, 0.0, z1 - 0.1), Vector3(x0 + 0.04, 0.0, z0 + 0.1), Vector3(x0 + 0.04, 3.2, z0 + 0.1), Vector3(x0 + 0.04, 3.2, z1 - 0.1), "celosia_sol", Vector3(1, 0, 0),
		[uv.call(z1 - 0.1, 0.0), uv.call(z0 + 0.1, 0.0), uv.call(z0 + 0.1, 3.2), uv.call(z1 - 0.1, 3.2)])
	quad(Vector3(x0 + 0.1, 0.0, z0 + TH / 2.0 + 0.04), Vector3(x1 - 0.2, 0.0, z0 + TH / 2.0 + 0.04), Vector3(x1 - 0.2, 3.2, z0 + TH / 2.0 + 0.04), Vector3(x0 + 0.1, 3.2, z0 + TH / 2.0 + 0.04), "celosia_sol", Vector3(0, 0, 1),
		[uv.call(x0, 0.0), uv.call(x1 - 0.3, 0.0), uv.call(x1 - 0.3, 3.2), uv.call(x0, 3.2)])
	box(x0, 3.2, z0 + 0.1, 0.1, 0.05, z1 - z0 - 0.2, "piedra_sol")
	box(x0 + 0.1, 3.2, z0 + TH / 2.0, x1 - x0 - 0.3, 0.05, 0.1, "piedra_sol")
	# the first floor's windows over it, frosted, dark frames
	for w in [[z0 + 1.5, z0 + 3.0], [z0 + 5.0, z0 + 6.5]]:
		box(x0, 4.1, w[0], 0.03, 1.2, w[1] - w[0], 0x2a2c30)
		box(x0 + 0.03, 4.15, w[0] + 0.05, 0.02, 1.1, w[1] - w[0] - 0.1, 0xd8dcdc)
	for x in [x0 + 1.2, x0 + 3.2]:
		box(x, 4.1, z1 - TH / 2.0 - 0.03, 1.2, 1.2, 0.03, 0x2a2c30)
		box(x + 0.05, 4.15, z1 - TH / 2.0 - 0.05, 1.1, 1.1, 0.02, 0xd8dcdc)
	# copings on its walls
	for q in [[x0 - 0.2, z0 - 0.1, 0.24, z1 - z0 + 0.2], [x0, z0 - TH / 2.0 - 0.02, x1 - x0 + 0.1, TH + 0.04], [x0, z1 - TH / 2.0 - 0.02, x1 - x0 + 0.1, TH + 0.04], [x1 - TH / 2.0 - 0.02, z0, TH + 0.04, z1 - z0]]:
		box(q[0], HIGH, q[1], q[2], 0.06, q[3], "piedra_sol")
	# the wicker chairs round the low table
	var mid := Vector2(-3.6, 9.4)
	_put(Vector3(mid.x, 0.0, mid.y))
	drum(Vector3(0, 0.0, 0), 0.05, 0.05, 0.4, "mimbre_sol", 10)
	drum(Vector3(0, 0.4, 0), 0.42, 0.42, 0.03, "mesa_sol", 18)
	home()
	solid(Vector3(mid.x, 0.22, mid.y), Vector3(0.84, 0.44, 0.84))
	for k in range(4):
		var a := k * PI / 2.0 + PI / 4.0
		var at := mid + Vector2(sin(a), cos(a)) * 1.05
		_wicker(Vector3(at.x, 0.0, at.y), a)
		solid(Vector3(at.x, 0.4, at.y), Vector3(0.7, 0.8, 0.7))
	# olive trees in big pots in two corners; plants along the low wall
	for p in [Vector2(-5.2, 5.9), Vector2(-5.2, 12.1)]:
		_olive(Vector3(p.x, 0.0, p.y))
		solid(Vector3(p.x, 0.5, p.y), Vector3(0.8, 1.0, 0.8))
	_saffron(Vector3(-5.35, 0.0, 12.68))                 # (behind the far one's pot)
	for z in [6.4, 7.4, 10.6, 11.8]:
		_put(Vector3(-1.45, 0.0, z))
		drum(Vector3.ZERO, 0.2, 0.24, 0.45, "maceta_sol", 10)
		ball(Vector3(0, 0.7, 0), 0.32, "hoja_sol", 1.1, 8, 5)
		home()

# ---------------- the co-working room ----------------
## long white tables for fourteen in two islands and a row, chairs of every colour, a screen and a lamp at each place
func _coworking() -> void:
	# two islands along the room, three places a side; a green screen down their middles
	for isle: Rect2 in [Rect2(-5.3, 14.0, 1.4, 4.0), Rect2(-2.0, 14.0, 1.4, 4.0)]:
		_put(Vector3(isle.position.x, 0.0, isle.position.y))
		box(0.0, 0.72, 0.0, isle.size.x, 0.03, isle.size.y, 0xf6f6f4)
		for z in [0.0, isle.size.y / 2.0 - 0.025, isle.size.y - 0.05]:
			box(0.05, 0.0, z, isle.size.x - 0.1, 0.72, 0.05, 0xd0d0cc)
		box(isle.size.x / 2.0 - 0.01, 0.75, 0.05, 0.02, 0.32, isle.size.y - 0.1, 0x3aa05a)
		home()
		solid(Vector3(isle.get_center().x, 0.4, isle.get_center().y), Vector3(isle.size.x, 0.8, isle.size.y))
		for k in range(3):
			var z := isle.position.y + 0.7 + k * 1.3
			for side in [-1.0, 1.0]:
				_screen(Vector3(isle.get_center().x + side * 0.38, 0.75, z), PI / 2.0 if side < 0.0 else -PI / 2.0, true)
				_chair(Vector3(isle.get_center().x + side * 1.05, 0.0, z), -PI / 2.0 if side < 0.0 else PI / 2.0, CHAIRS[_next()])
				desks += 1
	# a table for two along the stair's side
	_put(Vector3(3.6, 0.0, 15.0))
	box(0.0, 0.72, 0.0, 0.7, 0.03, 3.0, 0xf6f6f4)
	for z in [0.0, 2.95]:
		box(0.05, 0.0, z, 0.6, 0.72, 0.05, 0xd0d0cc)
	home()
	solid(Vector3(3.95, 0.4, 16.5), Vector3(0.7, 0.8, 3.0))
	for z in [15.8, 17.2]:
		_screen(Vector3(4.0, 0.75, z), PI / 2.0, true)
		_chair(Vector3(3.2, 0.0, z), -PI / 2.0, CHAIRS[_next()])
		desks += 1
	# a printer by the office's door, a water cooler by the offices' wall, plants
	_put(Vector3(-5.5, 0.0, 19.4))
	box(-0.3, 0.0, -0.25, 0.6, 0.75, 0.5, 0xf2f2ee)
	box(-0.28, 0.75, -0.23, 0.56, 0.3, 0.46, 0xd8d8d4)
	box(-0.2, 0.9, -0.27, 0.4, 0.02, 0.06, 0x2a2a2c)
	home()
	solid(Vector3(-5.5, 0.5, 19.4), Vector3(0.6, 1.0, 0.5))
	_put(Vector3(2.5, 0.0, 13.4))
	box(-0.17, 0.0, -0.17, 0.34, 1.0, 0.34, 0xf2f2ee)
	drum(Vector3(0, 1.0, 0), 0.14, 0.14, 0.4, 0x8ab8d8, 12)
	home()
	solid(Vector3(2.5, 0.6, 13.4), Vector3(0.4, 1.2, 0.4))
	for p in [Vector2(-5.55, 13.5), Vector2(4.4, 19.55), Vector2(-0.3, 19.55)]:
		_plant(Vector3(p.x, 0.0, p.y), 1.3)

## the floating stair of oak against the blue wall: its steps out of the wall, a balustrade of glass, a rope at its foot
func _stair() -> void:
	var x0 := STAIR.position.x
	var x1 := STAIR.end.x
	var rise := 3.6 / STEPS
	var run := STAIR.size.y / STEPS
	for i in range(STEPS):
		box(x0, (i + 1) * rise - 0.06, STAIR.position.y + i * run, x1 - x0, 0.06, run + 0.02, "madera")
	var a := Vector3(x0, rise, STAIR.position.y)
	var b := Vector3(x0, 3.6, STAIR.end.y)
	quad(a, b, b + Vector3(0, 0.95, 0), a + Vector3(0, 0.95, 0), "cristal", Vector3(-1, 0, 0))
	bar(a + Vector3(-0.02, 0.97, 0), b + Vector3(-0.02, 0.97, 0), 0.04, 0.04, 0x1a288c)
	for p in [a, b]:
		bar(p, p + Vector3(0, 0.95, 0), 0.03, 0.03, 0x1a288c)
	bar(Vector3(x1 - 0.04, rise + 0.9, STAIR.position.y), Vector3(x1 - 0.04, 3.6 + 0.9, STAIR.end.y), 0.03, 0.03, 0xb8bcc0)      # (its handrail on the wall)
	# the rope across its foot, between two posts of chrome
	var z := STAIR.position.y - 0.35
	for x in [x0 - 0.15, x1 - 0.05]:
		_put(Vector3(x, 0.0, z))
		drum(Vector3.ZERO, 0.15, 0.15, 0.03, 0xb8bcc0, 12)
		drum(Vector3(0, 0.03, 0), 0.025, 0.025, 0.9, 0xb8bcc0, 8)
		ball(Vector3(0, 0.95, 0), 0.045, 0xb8bcc0, 1.0, 8, 5)
		home()
	var p0 := Vector3(x0 - 0.15, 0.88, z)
	var p1 := Vector3(x1 - 0.05, 0.88, z)
	var mid := (p0 + p1) / 2.0 - Vector3(0, 0.14, 0)
	bar(p0, mid, 0.035, 0.035, 0xa8202a)
	bar(mid, p1, 0.035, 0.035, 0xa8202a)
	solid(Vector3((x0 + x1) / 2.0 - 0.1, 1.8, (STAIR.position.y + STAIR.end.y) / 2.0 - 0.2), Vector3(STAIR.size.x + 0.3, 3.6, STAIR.size.y + 0.6))

# ---------------- the meeting room ----------------
func _meeting() -> void:
	_put(Vector3(3.0, 0.0, 22.0))
	box(-1.6, 0.72, -0.55, 3.2, 0.04, 1.1, 0xf6f6f4)
	for x in [-1.4, 1.35]:
		box(x, 0.0, -0.35, 0.05, 0.72, 0.7, 0x2a2a2c)
	home()
	solid(Vector3(3.0, 0.4, 22.0), Vector3(3.2, 0.8, 1.1))
	for k in range(4):
		var x := 1.8 + k * 0.8
		_chair(Vector3(x, 0.0, 21.05), PI, 0x2a2a2c)
		_chair(Vector3(x, 0.0, 22.95), 0.0, 0x2a2a2c)
	# the screen on the end wall, the plan on it; a whiteboard on the side
	box(1.85, 1.05, D - 0.06, 2.3, 1.35, 0.05, "pantalla_negra")
	_picture(Vector3(3.0, 1.725, D - 0.06), Vector3(0, 0, -1), 2.2, 1.24, "pantalla")
	box(W2 - 0.03, 0.95, 20.8, 0.03, 1.1, 2.0, 0xf6f6f4)
	box(W2 - 0.05, 0.93, 20.75, 0.02, 0.02, 2.1, 0xb8bcc0)

# ---------------- the office ----------------
## the little kitchen: a counter along its back wall with the sink, the coffee machine and the microwave, cupboards
## over it, the fridge; a round table and two stools
func _kitchen() -> void:
	box(-5.95, 0.0, D - 0.62, 2.85, 0.88, 0.6, 0xf2f2ee)
	box(-5.97, 0.88, D - 0.65, 2.89, 0.04, 0.63, 0x5a5a5c)
	box(-5.0, 0.9, D - 0.5, 0.5, 0.03, 0.36, 0xb8bcc0)                                     # (the sink)
	box(-4.0, 0.92, D - 0.45, 0.25, 0.35, 0.3, 0x2a2a2c)                                   # (the coffee machine)
	box(-3.65, 0.92, D - 0.5, 0.48, 0.3, 0.36, 0xe8e8e4)                                   # (the microwave)
	box(-3.6, 0.97, D - 0.15, 0.32, 0.2, 0.012, 0x2a2a2c)
	box(-5.95, 1.5, D - 0.35, 2.85, 0.7, 0.35, 0xf2f2ee)
	solid(Vector3(-4.5, 0.45, D - 0.32), Vector3(2.9, 0.9, 0.65))
	box(-3.7, 0.0, 20.2, 0.6, 1.8, 0.62, 0xd8d8d4)                                          # (the fridge, by the way in)
	solid(Vector3(-3.4, 0.9, 20.51), Vector3(0.6, 1.8, 0.62))
	_put(Vector3(-4.6, 0.0, 21.9))
	drum(Vector3.ZERO, 0.25, 0.25, 0.03, 0x2a2a2c, 12)
	drum(Vector3(0, 0.03, 0), 0.04, 0.04, 0.72, 0x2a2a2c, 8)
	drum(Vector3(0, 0.75, 0), 0.4, 0.4, 0.03, 0xf6f6f4, 16)
	home()
	solid(Vector3(-4.6, 0.4, 21.9), Vector3(0.8, 0.8, 0.8))
	for p in [Vector2(-5.35, 21.9), Vector2(-3.85, 21.9)]:
		_put(Vector3(p.x, 0.0, p.y))
		drum(Vector3.ZERO, 0.03, 0.03, 0.62, 0xb8bcc0, 8)
		drum(Vector3(0, 0.62, 0), 0.18, 0.18, 0.05, 0xf07a24, 12)
		home()

# ---------------- the signs and the lamps ----------------
func _signs() -> void:
	var h := TH / 2.0
	_cartel("RECEPCIÓN", Vector3(-3.7, 0.82, 3.2), Vector3(0, 0, -1), 0.9)
	_cartel("DESPACHO 1", Vector3(2.0 - 0.06, 2.75, 5.0 + h + 0.95), Vector3(-1, 0, 0), 0.7)
	_cartel("DESPACHO 2", Vector3(2.0 - 0.06, 2.75, 9.0 + h + 0.95), Vector3(-1, 0, 0), 0.7)
	_cartel("PATIO", Vector3(-1.0 + h, 2.75, 8.9), Vector3(1, 0, 0), 0.6)
	_cartel("COWORKING", Vector3(0.5, 2.8, 13.0 - h), Vector3(0, 0, -1), 0.9)
	_cartel("OFFICE", Vector3(-4.4, 2.45, 20.0 - h), Vector3(0, 0, -1), 0.6)
	_cartel("ASEOS", Vector3(-1.75, 1.55, 19.9), Vector3(0, 0, -1), 0.5)
	_cartel("SALA DE REUNIONES", Vector3(1.6, 2.45, 20.0 - h), Vector3(0, 0, -1), 1.0)

func _lamps() -> void:
	# long panels in the ceilings
	for p in [Vector3(-3.0, 3.0, 2.5), Vector3(2.5, 3.0, 2.5), Vector3(0.5, 3.0, 7.0), Vector3(0.5, 3.0, 11.0), Vector3(4.0, 3.0, 7.0), Vector3(4.0, 3.0, 11.0),
			Vector3(-3.9, 3.6, 14.4), Vector3(-1.3, 3.6, 14.4), Vector3(-3.9, 3.6, 18.6), Vector3(-1.3, 3.6, 18.6), Vector3(2.6, 3.6, 14.4), Vector3(-4.5, 3.0, 22.0), Vector3(3.0, 3.0, 22.0)]:
		box(p.x - 0.6, p.y - 0.03, p.z - 0.15, 1.2, 0.025, 0.3, "luz")
	for at in [Vector3(-3.0, 2.5, 2.5), Vector3(2.5, 2.5, 2.5), Vector3(0.5, 2.5, 9.0), Vector3(4.0, 2.5, 7.0), Vector3(4.0, 2.5, 11.0),
			Vector3(-3.6, 3.0, 15.0), Vector3(-1.6, 3.0, 18.0), Vector3(2.6, 3.0, 16.0), Vector3(-4.5, 2.5, 22.0), Vector3(3.0, 2.5, 22.0)]:
		var lamp := OmniLight3D.new()
		lamp.position = at
		lamp.light_color = Color(1.0, 0.98, 0.94)
		lamp.omni_range = 5.0
		lamp.light_energy = 0.45
		lamp.shadow_enabled = false
		lamp.light_cull_mask = 1 << 10
		add_child(lamp)
		lamps += 1

# ---------------- furniture ----------------
## the next colour of a chair (always the same sequence)
func _next() -> int:
	_n += 1
	return (_n * 3 + _n / 4) % CHAIRS.size()

## an office chair on five legs: its seat and back in `col`
func _chair(at: Vector3, yaw: float, col) -> void:
	_put(at, yaw)
	for k in range(5):
		var a := k * TAU / 5.0
		bar(Vector3(0, 0.06, 0), Vector3(sin(a) * 0.28, 0.04, cos(a) * 0.28), 0.03, 0.025, 0x2a2a2c)
	drum(Vector3(0, 0.06, 0), 0.03, 0.03, 0.36, 0x9a9ca0, 8)
	box(-0.23, 0.42, -0.22, 0.46, 0.07, 0.44, col)
	box(-0.21, 0.52, 0.2, 0.42, 0.5, 0.05, col)
	box(-0.03, 0.42, 0.18, 0.06, 0.12, 0.04, 0x2a2a2c)
	home()

## a red armchair of the hall: a low square one
func _armchair(at: Vector3, yaw: float) -> void:
	_put(at, yaw)
	box(-0.4, 0.08, -0.38, 0.8, 0.34, 0.76, "rojo")
	box(-0.4, 0.42, 0.24, 0.8, 0.42, 0.14, "rojo")
	for sx in [-0.4, 0.28]:
		box(sx, 0.42, -0.38, 0.12, 0.2, 0.62, "rojo")
	for q in [[-0.36, -0.34], [0.32, -0.34], [-0.36, 0.3], [0.32, 0.3]]:
		box(q[0], 0.0, q[1], 0.04, 0.08, 0.04, 0x2a2a2c)
	home()

## a desk: white top on two white panels
func _desk(at: Vector3, yaw: float, w: float, d: float) -> void:
	_put(at, yaw)
	box(-w / 2.0, 0.72, -d / 2.0, w, 0.03, d, 0xf6f6f4)
	for sx in [-w / 2.0, w / 2.0 - 0.03]:
		box(sx, 0.0, -d / 2.0 + 0.03, 0.03, 0.72, d - 0.06, 0xf2f2ee)
	home()

## a screen on its foot, facing `yaw`; with a lamp and a keyboard if `lamp`
func _screen(at: Vector3, yaw: float, lamp := false) -> void:
	_put(at, yaw)
	box(-0.08, 0.0, -0.06, 0.16, 0.012, 0.12, 0x2a2a2c)
	box(-0.015, 0.012, -0.02, 0.03, 0.14, 0.02, 0x2a2a2c)
	box(-0.27, 0.12, -0.03, 0.54, 0.32, 0.02, 0x1a1a1c)
	box(-0.25, 0.14, -0.035, 0.5, 0.28, 0.005, 0x3a5a8a)
	box(-0.2, 0.0, -0.3, 0.4, 0.015, 0.13, 0xe8e8e4)
	if lamp:
		drum(Vector3(0.42, 0.0, 0.0), 0.06, 0.06, 0.015, 0x2a2a2c, 8)
		bar(Vector3(0.42, 0.015, 0.0), Vector3(0.42, 0.38, -0.08), 0.015, 0.015, 0x2a2a2c)
		drum(Vector3(0.42, 0.34, -0.14), 0.06, 0.03, 0.08, 0x2a2a2c, 8)
	home()

## a plant in a white pot
func _plant(at: Vector3, tall: float) -> void:
	_put(at)
	drum(Vector3.ZERO, 0.2, 0.24, 0.42, 0xf2f2ee, 12)
	drum(Vector3(0, 0.42, 0), 0.02, 0.02, tall * 0.4, 0x5a4a3a, 6)
	ball(Vector3(0, 0.42 + tall * 0.5, 0), 0.28, 0x3a7a4a, 1.3, 8, 5)
	ball(Vector3(0.1, 0.42 + tall * 0.72, 0.06), 0.22, 0x4a8a5a, 1.2, 8, 5)
	home()

## a black wicker armchair of the patio
func _wicker(at: Vector3, yaw: float) -> void:
	_put(at, yaw)
	drum(Vector3.ZERO, 0.3, 0.34, 0.38, "mimbre_sol", 12)
	drum(Vector3(0, 0.38, 0), 0.32, 0.32, 0.06, "piedra_sol", 12)
	box(-0.32, 0.38, 0.2, 0.64, 0.45, 0.1, "mimbre_sol")
	home()

## The hidden saffron (the user, 28 November 2026: "Ponlo"): in the patio, on the tiles behind the pot of the far olive
## tree, between it and the back wall, a little of its purple showing past the pot. It is in the open air: the sun
## lights it (_indoors leaves it be). The flower is the game's to take away (just walking by: game.gd takes it within
## 1.26 m).
func _saffron(at: Vector3) -> void:
	props += 1
	var flower := Node3D.new()
	flower.add_child(Parts.part("cyl", 0x5f9c4a, Vector3(0, 0.22, 0), Vector3(0.025, 0.44, 0.025)))
	for k in range(5):
		flower.add_child(Parts.part("ball", 0x9b5de5, Vector3(cos(k * 1.257) * 0.09, 0.48, sin(k * 1.257) * 0.09), Vector3(0.085, 0.15, 0.085)))
	flower.add_child(Parts.part("ball", 0xe63946, Vector3(0, 0.54, 0), Vector3(0.04, 0.1, 0.04)))
	flower.position = at
	flower.scale = Vector3.ONE * 0.8
	add_child(flower)
	_open_air.append(flower)
	saffron_spot = INSIDE + Vector2(at.x, at.z)
	var game = W.get_parent()                           # (the game: the world is its child)
	if game != null and game.get("flowers") != null:
		(game.flowers as Array).append({"node": flower, "p": saffron_spot, "id": "vivero", "hidden": true})      # (hidden: Sistemas keeps count of these)

## an olive tree in a big pot
func _olive(at: Vector3) -> void:
	_put(at)
	drum(Vector3.ZERO, 0.34, 0.4, 0.6, "maceta_sol", 12)
	bar(Vector3(0, 0.55, 0), Vector3(0.06, 1.6, 0.04), 0.09, 0.09, "tronco_sol")
	ball(Vector3(0.05, 2.0, 0.05), 0.6, "olivo_sol", 0.8, 10, 6)
	ball(Vector3(-0.25, 1.8, 0.2), 0.42, "olivo_sol", 0.8, 8, 5)
	ball(Vector3(0.3, 1.85, -0.2), 0.4, "olivo_sol", 0.8, 8, 5)
	home()
