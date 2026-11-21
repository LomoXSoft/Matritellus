extends "res://scripts/obra.gd"
## The roast chicken shop "Javi" of the Calle de los Arcos (the user, 21 November 2026: "Siguiente edificio asador de
## pollos juli (que llamaremos Javi). Abrirá en horario comercial y dentro estará Javi, del Asador de pollos. [...] Se
## podrá acceder al interior, que estará diseñado"), built by hand on Texturas's house of the map (arcos_4d, Catastro
## 4390040VJ5649S, handed over as ["obra"] in casas_calles.gd); referencias/asador/, tools/asador/. From Street View of
## November 2024 (and 2009 to 2021 for what has changed).
##
## A house of two floors under tiles, mustard over a foot of pale stone, 7.1 m of front:
##   - below, from the left: the house's own door behind its flowered curtain, a letter box, the white box of a meter,
##     and the shop: a white door and pane of glass behind a folding grille of white mesh, a beige awning over them, a
##     vent by the foot;
##   - over the shop its board (the game's own: a badge with a roast chicken and "Javi", POLLOS ASADOS -- the user:
##     "En vez de Asador de Pollos mejor llamarlo Pollos Asados" --, COMIDAS PREPARADAS; no telephone numbers), and
##     between the two balconies the tall sign that says POLLOS ASADOS down it, standing out from the wall to be read
##     from both ends of the street;
##   - above, two balconies behind iron rails, their white blinds down; a cable along the front; the arm of a street
##     lamp at the right;
##   - a little white dormer on the tiles.
## No house number (the game shows none).
## Its hours are the user's (21 November 2026): the real shop's days, Tuesdays and Sundays, the days of the chickens,
## and those days from 7 in the morning to 4 in the afternoon ("Pon que esos días abre a las 7:00 mejor. Y cierra a
## las 16:00"; the real one opens from 11 or half past to 3); shut the rest of the week. A card in its window says
## so. Shut: the grille across. Open: the grille folded to the sides, the door in, light inside. Its inside is a set of its own
## (asador_dentro.gd), walked into by the green arrow at its door (entradas.gd); Javi himself is Sistemas's.
##
## Frame: origin at the front's south end (its left, seen from the street), +x along the front, +z out of it, towards the
## street; y = 0 the pavement.

const READY := true
const HOUSE := "arcos_4d"
const NAME := "Pollos Asados Javi"              # what the shop is called (the user, 21 Nov 2026)
const DIR := "res://assets/asador/"
const DentroS = preload("res://scripts/asador_dentro.gd")
const EAVES := 6.3
const RIDGE := 7.8
const SKIRT := 0.95
const HOUSE_DOOR := Rect2(0.45, 0.0, 0.9, 2.1)
const SHOP := Rect2(4.05, 0.0, 2.2, 2.45)       # the shop's opening...
const LEAF := 0.95                              # ...and how wide its door is, at the opening's left
const BALCONIES := [Rect2(1.88, 3.62, 0.95, 2.0), Rect2(4.62, 3.62, 0.95, 2.0)]
const HOURS := {1: Vector2(7.0, 16.0), 6: Vector2(7.0, 16.0)}         # when it is open: the day (0 Monday ... 6 Sunday) and from when to when. The user: Tuesdays and Sundays, from 7:00 to 16:00; shut the other days
const WHITE := 0xf2f2ee
const IRON_HEX := 0x26262a

var door: Vector2                               # before the shop's door, on the pavement
var dentro                                      # its inside (asador_dentro.gd)
var is_open := false
var len_front := 7.14
var openings := 0
var _shut: Node3D
var _open: Node3D
var _lights: Array = []

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"ocre":             # mustard render (Street View 2024: about 205, 150, 40 in the sun)
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.92, 0.62, 0.13)), 0.08)
		"piedra":           # the foot: pale stone-faced tiles
			m = _glow(Tex.mat("granular_concrete", Color(1.0, 0.9, 0.72)), 0.3)      # (pale in the shade of the street too, as in the photographs)
		"cortina":          # the house door's curtain: dark, printed with leaves
			m = _cloth(Color(0.36, 0.3, 0.2), Color(0.62, 0.6, 0.36))
		"naranja":          # the shop's own curtains, orange
			m = _cloth(Color(0.86, 0.42, 0.16), Color(0.86, 0.42, 0.16))
		"reja":             # the folding grille: a mesh of white diamonds
			var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
			for y in range(16):
				for x in range(16):
					var on: bool = (x + y) % 8 == 0 or posmod(x - y, 8) == 0
					img.set_pixel(x, y, Color(0.95, 0.95, 0.93, 1.0 if on else 0.0))
			var rm := StandardMaterial3D.new()
			rm.albedo_texture = ImageTexture.create_from_image(img)
			rm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			rm.alpha_scissor_threshold = 0.5
			rm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = rm
		"vidrio":
			var gm := StandardMaterial3D.new()
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.albedo_color = Color(0.55, 0.68, 0.72, 0.3)
			gm.roughness = 0.12
			gm.metallic_specular = 0.7
			m = gm
		"interior":         # what shows through the glass: dark when shut, warm when open
			var im := StandardMaterial3D.new()
			im.albedo_color = Color(0.2, 0.14, 0.1)
			im.emission_enabled = true
			im.emission = Color(1.0, 0.82, 0.55)
			im.emission_energy_multiplier = 0.06
			m = im
		"luz":
			var lm := StandardMaterial3D.new()
			lm.albedo_color = Color(1.0, 0.97, 0.88)
			lm.emission_enabled = true
			lm.emission = Color(1.0, 0.95, 0.82)
			lm.emission_energy_multiplier = 1.4
			m = lm
		"rotulo", "banderola", "reparto", "horario":
			var tm := StandardMaterial3D.new()
			tm.albedo_texture = load(DIR + String(key) + ".png")
			tm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			tm.roughness = 0.8
			tm.emission_enabled = true          # (a little light of their own: they are read at dusk too)
			tm.emission_texture = tm.albedo_texture
			tm.emission = Color.WHITE
			tm.emission_energy_multiplier = 0.12
			m = tm
		_:
			return super(key)
	_mats[key] = m
	return m

## a curtain's cloth: folds (light and shade in columns) and a print of leaves of another colour
func _cloth(base: Color, print_: Color) -> StandardMaterial3D:
	var img := Image.create(64, 96, false, Image.FORMAT_RGB8)
	for x in range(64):
		var fold := 0.84 + 0.16 * sin(x / 64.0 * TAU * 5.0)
		for y in range(96):
			img.set_pixel(x, y, base * fold)
	if print_ != base:
		for k in range(24):
			var cx := 6 + (k % 4) * 16 + (8 if (k / 4) % 2 == 1 else 0)
			var cy := 8 + (k / 4) * 16
			for dx in range(-3, 4):
				for dy in range(-2, 3):
					if absi(dx) + absi(dy) * 2 <= 4:
						img.set_pixel(posmod(cx + dx, 64), posmod(cy + dy, 96), print_ * (0.84 + 0.16 * sin(posmod(cx + dx, 64) / 64.0 * TAU * 5.0)))
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.roughness = 1.0
	return m

func build(world, hd: Dictionary) -> void:
	W = world
	var o := Vector2(hd["o"][0], hd["o"][1])
	var u := Vector2(hd["u"][0], hd["u"][1]).normalized()
	var out := Vector2(-u.y, u.x)
	len_front = float(hd["len"])
	level = float(hd.get("base", MapData.height(o + u * (len_front / 2.0) + out * 1.0)))
	transform = Transform3D(Basis(Vector3(u.x, 0, u.y), Vector3.UP, Vector3(out.x, 0, out.y)), Vector3(o.x, level, o.y))
	W.add_child(self)
	var cx := SHOP.position.x + 0.1 + LEAF / 2.0
	door = spot(cx, 1.1)
	_front()
	_signs()
	_balconies()
	_body(hd)
	home()
	_commit()
	_states()
	dentro = DentroS.new()                          # (its door a little inside the glass: the arrow stays on the pavement)
	dentro.build(world, spot(cx, -0.45), spot(cx, 1.2), atan2(out.x, out.y))
	set_open(open_at(0, 12.0))

## whether it is open then (day: 0 Monday ... 6 Sunday)
func open_at(day: int, hour: float) -> bool:
	var d := posmod(day, 7)
	if not HOURS.has(d):
		return false
	var h: Vector2 = HOURS[d]
	return hour >= h.x and hour < h.y

# ---------------- pieces ----------------
## a flat picture (x0..x1, y0..y1) on the plane z of the frame being built, facing +z
func _picture(x0: float, x1: float, y0: float, y1: float, z: float, key) -> void:
	pieces += 1
	quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

## a stretch of something that repeats every `step` metres (the grille's mesh), facing +z
func _tiled(x0: float, x1: float, y0: float, y1: float, z: float, key, step := 0.3) -> void:
	pieces += 1
	quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1),
		[Vector2(x0, -y0) / step, Vector2(x1, -y0) / step, Vector2(x1, -y1) / step, Vector2(x0, -y1) / step])

## what has been built since the last commit becomes meshes under `node`: a part that can be shown and hidden
func _commit_to(node: Node3D) -> void:
	for key in _tools:
		var mi := MeshInstance3D.new()
		mi.mesh = (_tools[key] as SurfaceTool).commit()
		mi.material_override = _material(key)
		node.add_child(mi)
	_tools.clear()

# ---------------- the front ----------------
func _front() -> void:
	var holes: Array = [HOUSE_DOOR, SHOP]
	holes.append_array(BALCONIES)
	openings = holes.size()
	masonry(0.0, len_front, -1.0, EAVES, holes, [], "ocre", "ocre")
	# the foot of pale stone, cut at the doors: its courses, its moulding
	for run in [[0.0, HOUSE_DOOR.position.x], [HOUSE_DOOR.end.x, SHOP.position.x], [SHOP.end.x, len_front]]:
		var a: float = run[0]
		var b: float = run[1]
		plinth(a, b, SKIRT, SKIRT, "piedra", 0.03, -1.0)
		for y in [0.32, 0.64]:
			box(a, y, 0.0, b - a, 0.012, 0.033, 0xc9b592)
		var n := maxi(1, int((b - a) / 0.6))
		for k in range(n + 1):
			for row in range(3):
				var x: float = a + (b - a) * (k + (0.5 if row == 1 else 0.0)) / n
				if x > a + 0.05 and x < b - 0.05:
					box(x - 0.006, row * 0.32, 0.0, 0.012, 0.32 if row < 2 else 0.31, 0.033, 0xc9b592)
		box(a, SKIRT, 0.0, b - a, 0.045, 0.05, 0xe0d2ae)
	box(0.0, EAVES - 0.14, 0.0, len_front, 0.14, 0.1, 0xc98f2a)                     # the course under the tiles
	# the house's own door: wood behind its curtain, a blank tile over it, the step
	var hdr := HOUSE_DOOR
	box(hdr.position.x, 0.0, -DEEP + 0.03, hdr.size.x, hdr.size.y, 0.05, 0x6a4a30)
	_picture(hdr.position.x + 0.02, hdr.end.x - 0.02, 0.06, hdr.size.y - 0.04, -DEEP + 0.2, "cortina")
	box(hdr.position.x - 0.03, hdr.size.y - 0.06, -DEEP + 0.18, hdr.size.x + 0.06, 0.03, 0.03, 0x8a8a88)
	box(hdr.position.x - 0.05, 0.0, -0.03, hdr.size.x + 0.1, 0.05, 0.16, 0xb0a898)
	box(hdr.position.x + 0.38, 2.28, 0.0, 0.15, 0.15, 0.012, 0xf0f0f4)
	box(hdr.position.x + 0.385, 2.285, 0.0, 0.14, 0.14, 0.014, 0x3a5a9a)
	box(hdr.position.x + 0.4, 2.3, 0.0, 0.11, 0.11, 0.016, 0xf0f0f4)
	# the letter box, the meter's box, a little box of the wires, the cable along the front, the vent by the foot
	box(1.62, 1.28, 0.0, 0.26, 0.34, 0.1, 0xf0f0ec)
	box(1.66, 1.5, 0.1, 0.18, 0.02, 0.004, 0x3a3a3c)
	box(2.86, 0.7, 0.0, 0.46, 0.9, 0.06, WHITE)
	box(2.9, 0.74, 0.06, 0.38, 0.82, 0.006, 0xe2e2dc)
	box(3.06, 1.12, 0.066, 0.06, 0.06, 0.01, 0x8a8a88)
	box(3.02, 2.86, 0.0, 0.28, 0.36, 0.1, 0xe6e6e0)
	bar(Vector3(0.0, 3.47, 0.03), Vector3(len_front, 3.47, 0.03), 0.03, 0.03, 0x2a2a2c)
	box(SHOP.end.x + 0.28, 0.3, 0.0, 0.36, 0.36, 0.02, 0x7a4a2a)
	for k in range(5):
		box(SHOP.end.x + 0.3, 0.34 + k * 0.066, 0.02, 0.32, 0.02, 0.012, 0x5a3420)
	# the shop: its frame of white, the pane with its low panel, the notice of the deliveries in it; behind the glass
	# the warm dark of the shop and its orange curtains
	var s0: float = SHOP.position.x
	var s1: float = SHOP.end.x
	var sh: float = SHOP.size.y
	var z := -DEEP + 0.1
	for x in [s0, s1 - 0.07]:
		box(x, 0.0, z - 0.04, 0.07, sh, 0.08, WHITE)
	box(s0, sh - 0.07, z - 0.04, s1 - s0, 0.07, 0.08, WHITE)
	var mid: float = s0 + 0.07 + LEAF
	box(mid, 0.0, z - 0.04, 0.07, sh, 0.08, WHITE)
	box(mid + 0.07, 0.0, z - 0.03, s1 - 0.07 - mid - 0.07, 0.55, 0.05, WHITE)       # the pane's low panel
	quad(Vector3(mid + 0.07, 0.55, z), Vector3(s1 - 0.07, 0.55, z), Vector3(s1 - 0.07, sh - 0.07, z), Vector3(mid + 0.07, sh - 0.07, z), "vidrio", Vector3(0, 0, 1))
	_picture(mid + 0.4, mid + 0.82, 0.95, 1.51, z - 0.01, "reparto")
	_picture(mid + 0.42, mid + 0.8, 1.58, 2.05, z - 0.01, "horario")
	quad(Vector3(s0, 0.0, -DEEP - 0.5), Vector3(s1, 0.0, -DEEP - 0.5), Vector3(s1, sh, -DEEP - 0.5), Vector3(s0, sh, -DEEP - 0.5), "interior", Vector3(0, 0, 1))
	for q in [[s0 + 0.07, s0 + 0.3], [s1 - 0.42, s1 - 0.07]]:
		_picture(q[0], q[1], 0.05, sh - 0.1, z - 0.12, "naranja")
	box(s0 - 0.05, 0.0, -0.03, s1 - s0 + 0.1, 0.05, 0.18, 0xb0a898)                 # the step
	# the awning: beige cloth out over the door, its scalloped edge
	var a0: float = s0 - 0.3
	var a1: float = s1 + 0.3
	quad(Vector3(a0, 2.68, 0.0), Vector3(a1, 2.68, 0.0), Vector3(a1, 2.42, 0.62), Vector3(a0, 2.42, 0.62), 0xe6d6a6, Vector3(0, 1, 0.4))
	quad(Vector3(a0, 2.66, 0.0), Vector3(a1, 2.66, 0.0), Vector3(a1, 2.4, 0.62), Vector3(a0, 2.4, 0.62), 0xcdbd90, Vector3(0, -1, -0.4))
	box(a0, 2.66, 0.0, a1 - a0, 0.05, 0.08, WHITE)
	var sc := 9
	for k in range(sc):
		var x0: float = lerpf(a0, a1, float(k) / sc)
		var x1: float = lerpf(a0, a1, float(k + 1) / sc)
		quad(Vector3(x0, 2.3, 0.62), Vector3(x1, 2.3, 0.62), Vector3(x1, 2.42, 0.62), Vector3(x0, 2.42, 0.62), 0xe6d6a6, Vector3(0, 0, 1))
		tri(Vector3(x0, 2.3, 0.62), Vector3(x1, 2.3, 0.62), Vector3((x0 + x1) / 2.0, 2.22, 0.62), 0xd9853a, Vector3(0, 0, 1))
	# the arm of the street lamp, at the right
	var lx := len_front - 0.35
	bar(Vector3(lx, 5.55, 0.0), Vector3(lx, 6.05, 1.3), 0.06, 0.06, 0x8a8e92)
	box(lx - 0.14, 5.98, 1.2, 0.28, 0.1, 0.5, 0x6a6e72)
	box(lx - 0.11, 5.96, 1.24, 0.22, 0.02, 0.42, "luz")
	W.lamp_spots.append(transform * Vector3(lx, 5.8, 1.5))

# ---------------- its signs ----------------
func _signs() -> void:
	# the board over the shop
	var b0 := SHOP.position.x - 0.25
	var b1 := minf(len_front - 0.1, b0 + 2.7)
	box(b0 - 0.03, 2.74, 0.0, b1 - b0 + 0.06, 0.74, 0.06, 0x3a3a3c)
	_picture(b0, b1, 2.76, 3.46, 0.065, "rotulo")
	# the tall sign between the balconies: it stands out from the wall, a face to each end of the street
	var x := 3.72
	var y0 := 3.66
	var y1 := 6.26
	var z0 := 0.1
	var z1 := 0.6
	box(x + 0.005, y0, z0, 0.09, y1 - y0, z1 - z0, 0x2a1a16)
	quad(Vector3(x, y0, z0), Vector3(x, y0, z1), Vector3(x, y1, z1), Vector3(x, y1, z0), "banderola", Vector3(-1, 0, 0),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	quad(Vector3(x + 0.1, y0, z1), Vector3(x + 0.1, y0, z0), Vector3(x + 0.1, y1, z0), Vector3(x + 0.1, y1, z1), "banderola", Vector3(1, 0, 0),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	for y in [y0 + 0.3, y1 - 0.3]:
		box(x + 0.03, y, 0.0, 0.04, 0.04, z0, 0x3a3a3c)

# ---------------- the balconies ----------------
func _balconies() -> void:
	for i in range(BALCONIES.size()):
		var r: Rect2 = BALCONIES[i]
		window(r, WHITE, 0x1f2a33, 0)
		box(r.position.x + 0.06, r.position.y + 0.2, -DEEP + 0.1, r.size.x - 0.12, r.size.y - 0.26, 0.03, 0xe8e6de)      # the blind, down
		for k in range(1, 12):
			box(r.position.x + 0.06, r.position.y + 0.2 + (r.size.y - 0.26) * k / 12.0, -DEEP + 0.13, r.size.x - 0.12, 0.008, 0.004, 0xcfccc2)
		var x0 := r.position.x - 0.3
		var w := r.size.x + 0.6
		var y := r.position.y - 0.1
		box(x0, y, 0.0, w, 0.1, 0.45, 0xd8d0c0)
		var n := int(w / 0.11)
		for k in range(n + 1):
			box(x0 + k * w / n - 0.008, y + 0.1, 0.42, 0.016, 0.9, 0.016, IRON_HEX)
		for z in [0.0, 0.21]:
			for sx in [x0, x0 + w - 0.016]:
				box(sx, y + 0.1, z + 0.02, 0.016, 0.9, 0.016, IRON_HEX)
		box(x0, y + 0.98, 0.4, w, 0.035, 0.04, IRON_HEX)
		box(x0, y + 0.4, 0.415, w, 0.02, 0.02, IRON_HEX)
		for sx in [x0, x0 + w - 0.03]:
			box(sx, y + 0.98, 0.0, 0.03, 0.035, 0.44, IRON_HEX)
		if i == 1:                                                              # a plant on the right one
			drum(Vector3(r.end.x + 0.1, y + 0.1, 0.3), 0.08, 0.11, 0.16, 0xb0623a, 8)
			ball(Vector3(r.end.x + 0.1, y + 0.36, 0.3), 0.16, 0x3f7a3a, 0.9, 7, 4)

# ---------------- what is not its front ----------------
## Its other walls, as the map has its plot, plain mustard; its roof of tiles, one ridge along the street; the little
## white dormer on its front slope.
func _body(hd: Dictionary) -> void:
	var inv := transform.affine_inverse()
	var deep := 0.0
	for pc in hd.get("pieces", []):
		var raw: Array = pc["ring"]
		var ring: Array = []
		for i in range(0, raw.size(), 2):
			var q: Vector3 = inv * Vector3(float(raw[i]), level, float(raw[i + 1]))
			ring.append(Vector2(q.x, q.z))
			deep = minf(deep, q.z)
		for i in range(ring.size()):
			var a: Vector2 = ring[i]
			var b: Vector2 = ring[(i + 1) % ring.size()]
			if absf(a.y) < 0.3 and absf(b.y) < 0.3:
				continue
			_plain(a, b, -2.0, EAVES, "ocre")
			_plain(b, a, -2.0, EAVES, "ocre")
		for part in Geometry2D.decompose_polygon_in_convex(PackedVector2Array(ring)):
			var pts: Array = []
			for q: Vector2 in part:
				pts.append(q)
			_prism(pts, -2.0, EAVES)
	deep = minf(deep, -6.0)
	var mid := maxf(deep / 2.0, -5.0)
	roof([Vector3(-0.1, EAVES, 0.35), Vector3(len_front + 0.1, EAVES, 0.35), Vector3(len_front + 0.1, RIDGE, mid), Vector3(-0.1, RIDGE, mid)])
	roof([Vector3(-0.1, RIDGE, mid), Vector3(len_front + 0.1, RIDGE, mid), Vector3(len_front + 0.1, EAVES, 2.0 * mid), Vector3(-0.1, EAVES, 2.0 * mid)])
	if deep < 2.0 * mid - 0.2:                                                    # (what of the plot lies behind: a flat roof)
		flat(PackedVector2Array([Vector2(-0.1, 2.0 * mid), Vector2(len_front + 0.1, 2.0 * mid), Vector2(len_front + 0.1, deep), Vector2(-0.1, deep)]), EAVES - 0.05, 0xb9b4ac)
	for x in [0.0, len_front]:                                                    # the gables
		tri(Vector3(x, EAVES, 0.0), Vector3(x, EAVES, 2.0 * mid), Vector3(x, RIDGE, mid), "ocre", Vector3(-1 if x == 0.0 else 1, 0, 0))
	ridge(Vector3(-0.1, RIDGE, mid), Vector3(len_front + 0.1, RIDGE, mid))
	# the dormer
	var dz := -1.9
	var dy := EAVES + (RIDGE - EAVES) * (0.35 - dz) / (0.35 - mid)
	box(1.25, dy - 0.55, dz - 0.9, 0.9, 1.15, 1.2, WHITE)
	box(1.5, dy + 0.0, dz + 0.3, 0.4, 0.42, 0.01, 0x2a3440)
	roof([Vector3(1.15, dy + 0.6, dz + 0.42), Vector3(1.7, dy + 0.92, dz + 0.42), Vector3(1.7, dy + 0.92, dz - 0.95), Vector3(1.15, dy + 0.6, dz - 0.95)])
	roof([Vector3(1.7, dy + 0.92, dz + 0.42), Vector3(2.25, dy + 0.6, dz + 0.42), Vector3(2.25, dy + 0.6, dz - 0.95), Vector3(1.7, dy + 0.92, dz - 0.95)])
	tri(Vector3(1.25, dy + 0.6, dz + 0.3), Vector3(2.15, dy + 0.6, dz + 0.3), Vector3(1.7, dy + 0.88, dz + 0.3), WHITE, Vector3(0, 0, 1))

# ---------------- shut and open ----------------
## Shut: the grille across the shop's door and pane, the door behind it. Open: the grille folded to the two sides, the
## door swung in, the strip of light over it, lamps lit.
func _states() -> void:
	var s0: float = SHOP.position.x
	var s1: float = SHOP.end.x
	var sh: float = SHOP.size.y
	var z := -DEEP + 0.1
	var mid: float = s0 + 0.07 + LEAF
	_shut = Node3D.new()
	add_child(_shut)
	_leaf(s0 + 0.07, mid, z)
	_tiled(s0 + 0.04, s1 - 0.04, 0.06, sh - 0.05, -0.02, "reja", 0.3)
	for x in [s0 + 0.04, (s0 + s1) / 2.0 - 0.02, s1 - 0.08]:
		box(x, 0.06, -0.04, 0.04, sh - 0.11, 0.04, WHITE)
	box(s0 + 0.04, 0.02, -0.05, s1 - s0 - 0.08, 0.05, 0.06, WHITE)
	_commit_to(_shut)
	_open = Node3D.new()
	add_child(_open)
	for q in [[s0 + 0.04, s0 + 0.2], [s1 - 0.2, s1 - 0.04]]:                      # the grille, folded to each side
		_tiled(q[0], q[1], 0.06, sh - 0.05, -0.02, "reja", 0.08)
		box(q[0], 0.06, -0.04, 0.04, sh - 0.11, 0.04, WHITE)
		box(q[1] - 0.04, 0.06, -0.04, 0.04, sh - 0.11, 0.04, WHITE)
	var keep := _xf                                                              # the door, swung in against the jamb
	_xf = keep * Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(s0 + 0.07, 0.0, z))
	_leaf(0.0, LEAF, 0.0)
	_xf = keep
	cbox(Vector3((s0 + s1) / 2.0, sh + 0.04, 0.1), Vector3(0.8, 0.05, 0.12), "luz")
	_commit_to(_open)
	for q in [[Vector3((s0 + s1) / 2.0, 2.2, 0.9), 4.5, 0.8], [Vector3((s0 + s1) / 2.0, 1.8, -1.6), 4.0, 0.6]]:
		var lamp := OmniLight3D.new()
		lamp.position = q[0]
		lamp.light_color = Color(1.0, 0.9, 0.72)
		lamp.omni_range = q[1]
		lamp.light_energy = q[2]
		lamp.shadow_enabled = false
		add_child(lamp)
		_lights.append(lamp)

## the shop's door: a white frame, glass over a low panel, its handle
func _leaf(x0: float, x1: float, z: float) -> void:
	var h: float = SHOP.size.y - 0.07
	for x in [x0, x1 - 0.06]:
		box(x, 0.0, z - 0.03, 0.06, h, 0.06, WHITE)
	for y in [0.0, 0.5, h - 0.06]:
		box(x0, y, z - 0.03, x1 - x0, 0.06 if y > 0.0 else 0.5, 0.06, WHITE)
	quad(Vector3(x0 + 0.06, 0.56, z), Vector3(x1 - 0.06, 0.56, z), Vector3(x1 - 0.06, h - 0.06, z), Vector3(x0 + 0.06, h - 0.06, z), "vidrio", Vector3(0, 0, 1))
	box(x1 - 0.14, 1.0, z + 0.03, 0.03, 0.22, 0.04, 0xc9ccd0)

func set_open(on: bool) -> void:
	is_open = on
	if dentro != null:
		dentro.open = on
	if _shut != null:
		_shut.visible = not on
		_open.visible = on
	for lamp in _lights:
		(lamp as Light3D).visible = on
	if _mats.has("interior"):
		(_mats["interior"] as StandardMaterial3D).emission_energy_multiplier = 0.55 if on else 0.06

func _process(_delta: float) -> void:
	var game = W.get_parent() if W != null else null
	if game != null and "clock" in game and "weekday" in game:
		var want: bool = open_at(int(game.weekday), float(game.clock))
		if want != is_open:
			set_open(want)
