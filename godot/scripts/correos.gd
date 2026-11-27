extends "res://scripts/obra.gd"
## The post office of the Calle de Zaragoza, number 1, by the Plaza del Ayuntamiento (the user, 17 November 2026: "Vamos
## con la oficina de correos"): Catastro 4193608VJ5649S, a public building of two floors that Texturas had left as a plain
## house (zaragoza_b608, handed over). Built by hand from Street View (November 2024, and 2013), Catastro's photo of its
## front and the orthophoto. Measured: referencias/correos/LEEME.md, tools/correos/.
##
## Its front on the Zaragoza, from the corner by the town hall (the left, as seen from the street): the ground floor of
## red facing brick -- the great arch with its door of dark wood, the meter box, three windows in brown frames, the way in
## under a low arch, deep, with its ramp and its rail up to the glass door, the window by the north corner between two
## pilasters of cream render, the alarm -- the yellow boards with their blue foot along it, "CORREA" (the user's name for
## it: "Servicio Postal Correa") and our own horn, no crown; the floor over it of cream render between bands of brick, its windows with their blinds, the loggia over the
## way in; the grey cornice and the tiled roof behind it.
##
## Frame: the map's own (x east, z south), y = 0 the street before its door.

const READY := true                 # (tools/bake_godot.py: Catastro's block is not raised while this is true)
const NAME := "Correa"             # the user's name for it: "Servicio Postal Correa" (17 Nov 2026), on its boards "CORREA"
const DIR := "res://assets/correos/"
const HOUSE := "zaragoza_b608"
const A := Vector2(-130.12, -66.22)       # its front on the Zaragoza: the south end, by the town hall...
const B := Vector2(-122.17, -83.17)       # ...and the north end
const RING: Array = [Vector2(-133.85, -89.18), Vector2(-132.11, -88.29), Vector2(-127.86, -86.1), Vector2(-122.17, -83.17), Vector2(-130.12, -66.22),
	Vector2(-134.86, -68.43), Vector2(-133.34, -72.06), Vector2(-138.91, -74.57), Vector2(-141.54, -75.8), Vector2(-139.59, -79.88), Vector2(-138.37, -79.17),
	Vector2(-138.02, -79.99), Vector2(-135.91, -79.42), Vector2(-134.68, -83.84), Vector2(-133.11, -83.5), Vector2(-132.86, -84.73), Vector2(-135.83, -85.25),
	Vector2(-137.0, -85.53), Vector2(-135.11, -89.83)]      # Catastro's outline (the part of two floors and its little back part)
const FLOOR1 := 3.95                # the brick up to here, the boards from here...
const BOARD := 0.8                  # ...this high
const CORNICE := 7.2                # the top of the cream
const ROOF_D := 8.0                 # the tiled roof over the front block, this deep
const ARCH := [1.1, 3.9]            # the great arch's opening (metres from the south end)
const WINS := [[5.0, 6.0], [6.55, 7.55], [8.1, 9.1]]
const WAY := [9.6, 12.2]            # the way in (Street View from the north: a metre and a half of brick between it and the north window's pilaster)
const NWIN := [14.2, 15.8]          # the window by the north corner
const OPENS := 8.0                  # Monday to Friday, 8:00 to 20:00 (the user, 16 Nov 2026, for the letters: cartas.gd;
const SHUTS := 20.0                 # it was Google's 8:30 to 14:30)
const DOWN := -3.0
const DentroS = preload("res://scripts/correos_dentro.gd")
const BROWN := 0x5a3a24

var door: Vector2                   # before its way in, on the map
var outline: PackedVector2Array
var is_open := true
var tienda                          # its inside, a set apart (correos_dentro.gd), entered by the way in
var _open_nodes: Array = []         # what shows only while open (the grille rolled up)...
var _shut_nodes: Array = []         # ...and only while shut (the grille down across the way in)
var _grille_solid: CollisionShape3D

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"ladrillo":         # red facing brick
			m = Tex.mat("brick_wall_003@1.0", Color(0.9, 0.64, 0.54))             # (redder and darker than the texture's orange: Street View)
		"crema":
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.07, 0.98, 0.84)), 0.34)
		"cornisa":
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.86, 0.86, 0.84)), 0.2)
		"rotulo", "corto", "horario":
			var pm := StandardMaterial3D.new()
			pm.albedo_texture = load(DIR + String(key) + ".png")
			pm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			pm.roughness = 0.5
			if key != "horario":            # the boards are light boxes: lit from inside at dusk (_process)
				pm.emission_enabled = true
				pm.emission_texture = pm.albedo_texture
				pm.emission = Color.WHITE
				pm.emission_energy_multiplier = 0.0
			m = pm
		"cristal":
			var gm := StandardMaterial3D.new()
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.albedo_color = Color(0.25, 0.3, 0.32, 0.55)
			gm.roughness = 0.2
			gm.metallic_specular = 0.4
			gm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = gm
		"luz":
			var lm := StandardMaterial3D.new()
			lm.albedo_color = Color(1.0, 0.98, 0.92)
			lm.emission_enabled = true
			lm.emission = Color(1.0, 0.97, 0.9)
			lm.emission_energy_multiplier = 1.2
			m = lm
		"sala":
			var sm := StandardMaterial3D.new()
			sm.albedo_color = Color(0.86, 0.85, 0.82)
			sm.emission_enabled = true
			sm.emission = Color(0.96, 0.95, 0.9)
			sm.emission_energy_multiplier = 0.3
			m = sm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	var out := Vector2(0.9055, 0.4247)                   # out of the front, into the Zaragoza
	var mid := A.lerp(B, (WAY[0] + WAY[1]) / 2.0 / A.distance_to(B))
	level = MapData.height(mid + out * 1.0)
	transform = Transform3D(Basis.IDENTITY, Vector3(0, level, 0))
	W.add_child(self)
	door = mid + out * 1.6
	outline = PackedVector2Array(RING)
	_front()
	_way_in()
	_upper()
	_boards()
	_others()
	_roof()
	home()
	_commit()
	_grille()
	_build_inside(out)
	for part in Geometry2D.decompose_polygon_in_convex(outline):
		_prism(Array(part), DOWN, CORNICE)
	MapData.outlines.append(outline)
	if not MapData._wall_grid.is_empty():
		for i in range(outline.size()):
			var a: Vector2 = outline[i]
			var c: Vector2 = outline[(i + 1) % outline.size()]
			MapData._grid_add(MapData._wall_grid, a.min(c), a.max(c), [a, c])
	set_open(open_at(0, 10.0))

# ---------------- helpers ----------------
func _picture(x0: float, x1: float, y0: float, y1: float, z: float, key) -> void:
	pieces += 1
	quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

## a low arch of bricks on end over an opening from x0 to x1, its springing at `spring`, rising `rise`
func _brick_arch(x0: float, x1: float, spring: float, rise: float, deep := 0.3) -> void:
	var n := 14
	var span := x1 - x0
	var r: float = (span * span / 4.0 + rise * rise) / (2.0 * rise)       # the circle through its springings and its crown
	var cx := (x0 + x1) / 2.0
	var cy := spring + rise - r
	var a0: float = asin(clampf(span / 2.0 / r, -1.0, 1.0))
	for i in range(n):
		var t0: float = -a0 + 2.0 * a0 * i / n
		var t1: float = -a0 + 2.0 * a0 * (i + 1) / n
		var p0 := Vector3(cx + sin(t0) * r, cy + cos(t0) * r, 0.0)
		var p1 := Vector3(cx + sin(t1) * r, cy + cos(t1) * r, 0.0)
		var q0 := Vector3(cx + sin(t0) * (r + 0.32), cy + cos(t0) * (r + 0.32), 0.0)
		var q1 := Vector3(cx + sin(t1) * (r + 0.32), cy + cos(t1) * (r + 0.32), 0.0)
		quad(p0 + Vector3(0, 0, 0.02), p1 + Vector3(0, 0, 0.02), q1 + Vector3(0, 0, 0.02), q0 + Vector3(0, 0, 0.02), "ladrillo", Vector3(0, 0, 1))
		quad(p0, p1, p1 + Vector3(0, 0, -deep), p0 + Vector3(0, 0, -deep), "ladrillo", (Vector3(cx, cy, 0) - (p0 + p1) / 2.0).normalized())
		pieces += 1
	# the wall between the arch and the square head of its opening
	for side in [-1.0, 1.0]:
		var pts := PackedVector2Array()
		var edge: float = cx + side * span / 2.0
		pts.append(Vector2(edge, spring))
		for i in range(1, n / 2 + 1):
			var t: float = side * a0 * (1.0 - float(i) / (n / 2))
			pts.append(Vector2(cx + sin(t) * r, cy + cos(t) * r))
		pts.append(Vector2(edge, spring + rise + 0.02))
		var idx := Geometry2D.triangulate_polygon(pts)
		for k in range(0, idx.size(), 3):
			tri(Vector3(pts[idx[k]].x, pts[idx[k]].y, 0.01), Vector3(pts[idx[k + 1]].x, pts[idx[k + 1]].y, 0.01), Vector3(pts[idx[k + 2]].x, pts[idx[k + 2]].y, 0.01), "ladrillo", Vector3(0, 0, 1))

## a window of brown frames, sliding, with a cream surround and sill
func _window(x0: float, x1: float, y0: float, y1: float, blind := false) -> void:
	box(x0, y0, -0.2, x1 - x0, y1 - y0, 0.02, 0x2a2e30)
	_picture(x0, x1, y0, y1, -0.16, "cristal")
	for e in [[x0, y0, 0.07, y1 - y0], [x1 - 0.07, y0, 0.07, y1 - y0], [x0, y0, x1 - x0, 0.07], [x0, y1 - 0.07, x1 - x0, 0.07], [(x0 + x1) / 2.0 - 0.03, y0, 0.06, y1 - y0]]:
		box(e[0], e[1], -0.18, e[2], e[3], 0.06, BROWN)
	for e in [[x0 - 0.1, y0 - 0.1, 0.1, y1 - y0 + 0.2], [x1, y0 - 0.1, 0.1, y1 - y0 + 0.2], [x0 - 0.1, y1, x1 - x0 + 0.2, 0.1]]:
		box(e[0], e[1], 0.0, e[2], e[3], 0.03, 0xe8dcc0)
	box(x0 - 0.12, y0 - 0.1, -0.05, x1 - x0 + 0.24, 0.07, 0.2, 0xe8dcc0)
	if blind:                                                                         # the roller blind half down
		box(x0 + 0.04, y1 - (y1 - y0) * 0.45, -0.17, x1 - x0 - 0.08, (y1 - y0) * 0.45 - 0.04, 0.02, 0xc8b89a)
		for k in range(int((y1 - y0) * 0.45 / 0.08)):
			box(x0 + 0.04, y1 - 0.08 - k * 0.08, -0.15, x1 - x0 - 0.08, 0.01, 0.005, 0xa89878)

# ---------------- the ground floor ----------------
func _front() -> void:
	var ln := face(A, B)
	var holes: Array = [Rect2(ARCH[0], DOWN, ARCH[1] - ARCH[0], 3.37 - DOWN), Rect2(WAY[0], DOWN, WAY[1] - WAY[0], 3.45 - DOWN), Rect2(NWIN[0], 1.6, NWIN[1] - NWIN[0], 1.65)]
	for w in WINS:
		holes.append(Rect2(w[0], 1.6, w[1] - w[0], 1.7))
	masonry(0.0, ln, DOWN, FLOOR1, holes, [], "ladrillo")
	# the cream pilasters round the north window, the cream panel with the alarm
	for p in [[13.55, 14.05], [15.95, 16.45], [16.95, 17.95]]:
		box(p[0], 0.5, 0.0, p[1] - p[0], 3.1, 0.04, "crema")
	box(17.2, 3.0, 0.04, 0.26, 0.3, 0.12, 0xf2f2ee)                                      # the alarm
	box(17.23, 3.02, 0.16, 0.2, 0.1, 0.005, 0xd8343a)
	# the great arch: its low head of bricks on end, the door of dark wood in planks, studs
	_brick_arch(ARCH[0], ARCH[1], 2.62, 0.75)
	box(ARCH[0], DOWN, -0.25, ARCH[1] - ARCH[0], 3.5 - DOWN, 0.05, 0x3e2a20)
	var k := 0
	var x: float = ARCH[0] + 0.05
	while x < ARCH[1] - 0.1:
		box(x, 0.0, -0.2, 0.17, 3.3, 0.02, 0x4a3428 if k % 2 == 0 else 0x42301f)
		x += 0.18
		k += 1
	box((ARCH[0] + ARCH[1]) / 2.0 - 0.015, 0.0, -0.17, 0.03, 3.3, 0.02, 0x2a1c14)
	for row in range(6):
		for col in range(6):
			ball(Vector3(ARCH[0] + 0.3 + col * (ARCH[1] - ARCH[0] - 0.6) / 5.0, 0.4 + row * 0.5, -0.17), 0.025, 0x1a1a1a, 0.6, 6, 3)
	# the windows; the meter box
	for w in WINS:
		_window(w[0], w[1], 1.6, 3.3)
	_window(NWIN[0], NWIN[1], 1.6, 3.25)
	box(4.25, 0.85, 0.0, 0.5, 0.65, 0.12, 0xe4e4e0)
	box(4.3, 0.9, 0.121, 0.4, 0.55, 0.004, 0xf0f0ec)
	plinth(0.0, ln, 0.0, 0.0, 0x8a6a5a, 0.02, -0.4)
	home()

## the way in: deep under a low arch, its ramp with the rail along it up to the glass door, the plate of its hours
func _way_in() -> void:
	var ln := face(A, B)
	var w0: float = WAY[0]
	var w1: float = WAY[1]
	var dz := 3.0
	_brick_arch(w0, w1, 2.9, 0.55, dz)
	box(w0, 3.45, -dz, w1 - w0, 0.4, dz - DEEP - 0.01, "crema")                            # over its vault
	box(w0 - 0.02, -0.05, -dz, 0.02, 3.5, dz - DEEP - 0.01, "crema")                       # its sides
	box(w1, -0.05, -dz, 0.02, 3.5, dz - DEEP - 0.01, "crema")
	quad(Vector3(w0, 0.02, 0.0), Vector3(w1, 0.02, 0.0), Vector3(w1, 0.45, -dz), Vector3(w0, 0.45, -dz), 0xc8beb0, Vector3(0, 1, 0.15))      # the ramp up
	for y in [0.9, 0.5]:                                                                   # the rail, along its north side
		bar(Vector3(w1 - 0.12, y, -0.1), Vector3(w1 - 0.12, y + 0.45, -dz + 0.3), 0.04, 0.04, 0xb8bcc0)
	for zz in [-0.1, -dz + 0.3]:
		bar(Vector3(w1 - 0.12, (0.0 if zz > -1.0 else 0.45), zz), Vector3(w1 - 0.12, (0.9 if zz > -1.0 else 1.35), zz), 0.04, 0.04, 0xb8bcc0)
	# the glass door at the back, and the room behind it (lit while it is open)
	var bz := -dz
	_picture(w0 + 0.3, w1 - 0.3, 0.45, 2.75, bz + 0.01, "cristal")
	for xx in [w0 + 0.3, (w0 + w1) / 2.0 - 0.03, w1 - 0.36]:
		box(xx, 0.45, bz, 0.06, 2.3, 0.06, 0x9a9da0)
	box(w0 + 0.3, 2.7, bz, w1 - w0 - 0.6, 0.06, 0.06, 0x9a9da0)
	box(w0 - 0.5, 0.43, bz - 4.0, w1 - w0 + 1.0, 0.02, 4.0, 0xd8d6d0)
	box(w0 - 0.5, 0.45, bz - 4.05, w1 - w0 + 1.0, 2.6, 0.05, "sala")
	box(w0 - 0.5, 3.0, bz - 4.0, w1 - w0 + 1.0, 0.04, 4.0, "sala")
	box(w0 + 0.6, 2.97, bz - 2.0, 1.4, 0.02, 0.25, "luz")
	box(w0 + 0.2, 0.45, bz - 3.6, w1 - w0 - 0.4, 1.05, 0.6, 0x3a4a6a)                    # the counter inside
	var keep := _xf
	_xf = keep * Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(w0 + 0.02, 0.0, -0.9))     # the plate of its hours, on the arch's south side, facing the ramp
	_picture(-0.2, 0.2, 1.3, 1.83, 0.0, "horario")
	_xf = keep
	home()

# ---------------- the floor over it ----------------
func _upper() -> void:
	var ln := face(A, B)
	var wins: Array = [[2.0, 3.0], [6.55, 7.55], [14.3, 15.5]]
	var loggia := [9.6, 12.4]
	var holes: Array = [Rect2(loggia[0], 4.8, loggia[1] - loggia[0], 1.8)]
	for w in wins:
		holes.append(Rect2(w[0], 5.2, w[1] - w[0], 1.3))
	masonry(0.0, ln, FLOOR1, CORNICE, holes, [], "crema")
	for b in [[0.0, 0.6], [8.9, 9.5], [18.0, ln]]:                                      # the bands of brick up it
		box(b[0], FLOOR1, 0.0, b[1] - b[0], CORNICE - FLOOR1, 0.03, "ladrillo")
	for w in wins:
		_window(w[0], w[1], 5.2, 6.5, true)
	# the loggia over the way in: deep, its soffit, a window and a door at its back, a rail across it
	var lz := -1.2
	box(loggia[0], 6.6, lz, loggia[1] - loggia[0], 0.02, -lz, "crema")
	box(loggia[0] - 0.02, 4.8, lz, 0.02, 1.8, -lz, "crema")
	box(loggia[1], 4.8, lz, 0.02, 1.8, -lz, "crema")
	box(loggia[0], 4.78, lz, loggia[1] - loggia[0], 0.04, -lz, 0xc8beb0)
	box(loggia[0], 4.8, lz - 0.02, loggia[1] - loggia[0], 1.8, 0.02, "crema")
	box(loggia[0] + 0.3, 4.8, lz + 0.01, 1.0, 1.7, 0.02, BROWN)
	box(loggia[0] + 1.6, 5.3, lz + 0.01, 1.0, 1.0, 0.02, 0x2a2e30)
	bar(Vector3(loggia[0], 5.85, -0.08), Vector3(loggia[1], 5.85, -0.08), 0.04, 0.04, 0x26262a)
	for i in range(13):
		bar(Vector3(loggia[0] + 0.1 + i * (loggia[1] - loggia[0] - 0.2) / 12.0, 4.82, -0.08), Vector3(loggia[0] + 0.1 + i * (loggia[1] - loggia[0] - 0.2) / 12.0, 5.85, -0.08), 0.02, 0.02, 0x26262a)
	# the cornice: grey, stepping out, the gutter along it
	box(-0.05, CORNICE, 0.0, ln + 0.1, 0.12, 0.22, "cornisa")
	box(-0.08, CORNICE + 0.12, 0.0, ln + 0.16, 0.14, 0.36, "cornisa")
	bar(Vector3(-0.08, CORNICE + 0.3, 0.42), Vector3(ln + 0.08, CORNICE + 0.3, 0.42), 0.1, 0.1, 0xb8bcc0)
	bar(Vector3(0.3, -0.3, 0.06), Vector3(0.3, CORNICE + 0.3, 0.06), 0.08, 0.08, 0xb8bcc0)       # the downpipes at the corners
	bar(Vector3(ln - 0.3, -0.3, 0.06), Vector3(ln - 0.3, CORNICE + 0.3, 0.06), 0.08, 0.08, 0xb8bcc0)
	home()

## the yellow boards along the top of the ground floor: a short one over the arch, a long one over the windows and the
## way in; rounded, their foot and ends blue
func _boards() -> void:
	var ln := face(A, B)
	for b in [[1.0, 4.1, "corto"], [4.8, 12.6, "rotulo"]]:
		var x0: float = b[0]
		var x1: float = b[1]
		var y0 := FLOOR1 + 0.05
		box(x0 - 0.06, y0 - 0.02, 0.0, x1 - x0 + 0.12, 0.16, 0.42, 0x1e4aa0)               # its blue foot
		var segs := int(round((x1 - x0) / 3.6)) if b[2] == "rotulo" else 1
		for s in range(segs):
			var sx0: float = x0 + (x1 - x0) * s / segs
			var sx1: float = x0 + (x1 - x0) * (s + 1) / segs
			pieces += 1
			quad(Vector3(sx0, y0 + 0.14, 0.4), Vector3(sx1, y0 + 0.14, 0.4), Vector3(sx1, y0 + BOARD, 0.2), Vector3(sx0, y0 + BOARD, 0.2), b[2], Vector3(0, 0.25, 1),
				[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
		box(x0, y0 + BOARD, 0.0, x1 - x0, 0.04, 0.22, 0xf2c800)
		for e in [x0 - 0.06, x1]:                                                           # its blue ends
			box(e, y0 - 0.02, 0.0, 0.06, BOARD + 0.06, 0.42, 0x1e4aa0)
	home()

## the other sides, over the neighbours (the house to the north, the town hall's end to the south) and the yard behind
func _others() -> void:
	var n := outline.size()
	var cw := Geometry2D.is_polygon_clockwise(outline)
	for i in range(n):
		var a: Vector2 = outline[i]
		var b: Vector2 = outline[(i + 1) % n]
		if (a.is_equal_approx(B) and b.is_equal_approx(A)) or (a.is_equal_approx(A) and b.is_equal_approx(B)):
			continue
		var p: Vector2 = a if not cw else b
		var q: Vector2 = b if not cw else a
		var ln := face(p, q)                                 # (out of the outline, whichever way it runs)
		if ln < 0.3:
			continue
		var top: float = CORNICE if a.distance_to(A) < 9.0 or a.distance_to(B) < 9.0 or b.distance_to(A) < 9.0 or b.distance_to(B) < 9.0 else CORNICE - 0.4
		pieces += 1
		quad(Vector3(0, DOWN, 0), Vector3(ln, DOWN, 0), Vector3(ln, top, 0), Vector3(0, top, 0), "crema", Vector3(0, 0, 1))
	home()

## the roof: tiles in a hip over the block of the front, flat behind it
func _roof() -> void:
	face(A, B)
	_hip(0.0, A.distance_to(B), -ROOF_D, 0.0, CORNICE + 0.26, 2.1, 0.3)
	home()
	flat(outline, CORNICE - 0.05, 0xa8a49c)

# ---------------- open and shut ----------------
## The grille of the way in (the user, 17 Nov 2026: "añade abierto/cerrado (verja en la entrada, iluminación del cartel,...)"):
## shut, a grille of bars down across the arch from its box under the crown; open, rolled up into the box.
func _grille() -> void:
	var ln := face(A, B)
	var w0: float = WAY[0]
	var w1: float = WAY[1]
	var top := 2.9                                   # (the box under the arch's springing)
	box(w0 + 0.05, top, -0.32, w1 - w0 - 0.1, 0.42, 0.3, 0x4a4d52)                        # its box
	for x in [w0 + 0.02, w1 - 0.08]:                                                     # its guides
		box(x, 0.0, -0.3, 0.06, top, 0.08, 0x5a5d62)
	_commit()
	var bars := int((w1 - w0 - 0.2) / 0.11)                                            # shut: the bars, the cross pieces, the lock
	for i in range(bars + 1):
		box(w0 + 0.1 + i * (w1 - w0 - 0.2) / bars - 0.012, 0.0, -0.26, 0.024, top, 0.024, 0x6a6d72)
	for y in [0.12, 0.9, 1.7, 2.5]:
		box(w0 + 0.08, y, -0.27, w1 - w0 - 0.16, 0.05, 0.03, 0x5a5d62)
	box(w0 + 0.08, 0.0, -0.28, w1 - w0 - 0.16, 0.08, 0.05, 0x4a4d52)
	box((w0 + w1) / 2.0 - 0.08, 0.05, -0.31, 0.16, 0.14, 0.05, 0x2a2c2e)
	_commit_to(_shut_nodes)
	box(w0 + 0.05, top - 0.12, -0.31, w1 - w0 - 0.1, 0.12, 0.05, 0x5a5d62)               # open: only its bottom bar shows under the box
	_commit_to(_open_nodes)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(w1 - w0, top, 0.2)
	cs.shape = bs
	cs.transform = transform * _xf * Transform3D(Basis.IDENTITY, Vector3((w0 + w1) / 2.0, top / 2.0, -0.25))
	_solids().add_child(cs)
	_grille_solid = cs
	home()

## everything built so far goes into its own node (shown only while open, or only while shut)
func _commit_to(list: Array) -> void:
	var node := Node3D.new()
	add_child(node)
	for key in _tools:
		var mi := MeshInstance3D.new()
		mi.mesh = (_tools[key] as SurfaceTool).commit()
		mi.material_override = _material(key)
		node.add_child(mi)
	_tools.clear()
	list.append(node)

## its inside, a set apart (the user: "e interiores"): in by the green arrow before the way in, while it is open
func _build_inside(out: Vector2) -> void:
	var mid: Vector2 = A.lerp(B, (WAY[0] + WAY[1]) / 2.0 / A.distance_to(B))
	tienda = DentroS.new()
	tienda.build(W, mid + out * 0.3, mid + out * 2.2, atan2(out.x, out.y))

# ---------------- its hours ----------------
func open_at(day: int, hour: float) -> bool:
	if posmod(day, 7) >= 5:
		return false
	return hour >= OPENS and hour < SHUTS

func _process(_delta: float) -> void:
	var game = W.get_parent() if W != null else null
	if game != null and "clock" in game and "weekday" in game:
		var want: bool = open_at(int(game.weekday), float(game.clock))
		if want != is_open:
			set_open(want)
		_light_boards(float(game.clock))

## its boards are light boxes: lit from dusk to near midnight, open or shut, in their own colours whatever the light
## (the user, 17 Nov 2026: "iluminación del cartel"); by day, plain
func lit_at(hour: float) -> bool:
	return hour >= 18.5 or hour < 0.5

func _light_boards(hour: float) -> void:
	var lit: bool = lit_at(hour)
	for key in ["rotulo", "corto"]:
		if _mats.has(key):
			var bm := _mats[key] as StandardMaterial3D
			var mode := BaseMaterial3D.SHADING_MODE_UNSHADED if lit else BaseMaterial3D.SHADING_MODE_PER_PIXEL
			if bm.shading_mode != mode:
				bm.shading_mode = mode

func set_open(on: bool) -> void:
	is_open = on
	if tienda != null:                              # (its door with it: entradas.gd lets you in only while it is open)
		tienda.open = on
	for n in _open_nodes:
		(n as Node3D).visible = on
	for n in _shut_nodes:
		(n as Node3D).visible = not on
	if _grille_solid != null:
		_grille_solid.disabled = on
	for q in [["luz", 1.2], ["sala", 0.3]]:
		if _mats.has(q[0]):
			(_mats[q[0]] as StandardMaterial3D).emission_energy_multiplier = float(q[1]) if on else 0.0
