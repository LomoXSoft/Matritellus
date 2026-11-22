extends "res://scripts/obra.gd"
## The almazara "González de la Ruz" (the user, 21 November 2026: "Ahora ponte con aceites García de la Cruz (que
## llamaremos Gonzalez de la Ruz) tiene fachada tanto en calle triunfo como en carretera de villacañas"): the oil mill
## between the road to Villacañas and the Calle del Triunfo, Catastro 4699012VJ5649N (Calle Reyes Católicos 23, of 1953
## and after), and the tall nave of the 2010s beside it on the road, which Catastro has not got. Built by hand from
## Catastro, the IGN's orthophoto and Street View of November 2024 (tools/almazara/, referencias/almazara/).
##
## On the road, from the garage of Errejota north-east (s: metres along the front from its south-west corner):
##   s 0-15     the end of the old nave, white over a blue foot, a roof of one slope high on the garage's side (9.6 m
##              down to 6.6 m), and painted on it the mural: a grey quarter of a circle, a fan of leaves on the corner,
##              the name, a branch of olive. The game's own lettering and badge (tools/almazara/dibujos.py): not the
##              real firm's name, cross or anniversary;
##   s 15-26.5  the way in, open, between two hedges; the yard behind it, with the shop's door in the nave's side
##              (the board TIENDA, the tall banner), the salmon offices of two floors under tiles at the back and the
##              reception nave beside them, open in front and on their side, with its cabin, its hopper and its belt;
##   s 26.5-89  the long white wall over its blue foot, the name on it every twenty metres; behind it the timber
##              shed, the flags, the steel tanks and the low works;
##   s 89-97.5  a higher piece of wall, a small building's;
##   s 97.5-165 the tall nave, 14.7 m of white panels, the name big near its far end and on the slanting wall beyond
##              its point; then a few metres of white sheet fence.
## The road falls four metres to the north-east in the game (the relief is 2.5 times the real one): the wall, its foot
## and its names follow the ground.
## On the Triunfo, from the house of the corner north-east: the nave's other end with its barred windows, a white block
## of two floors under a flat roof, a low old stretch under tiles, and the long back wall of the naves under the edge
## of a sheet roof, with its high windows, its air machines and its drainpipes.
## The street door of nothing moves: there is no inside yet. A saffron flower is hidden in the nook behind the low
## works (the user: hide one in every special place).
##
## Frame: the map's own, y = 0 the yard. P(s, d): s along the road front, d into the plot.

const READY := true
const DIR := "res://assets/almazara/"
const CHAPA := "res://assets/masahorro/chapa.png"
const A := Vector2(264.27, -523.36)       # the front's south-west corner on the road (Catastro)
const U := Vector2(0.7340, -0.6792)       # along the front, to the north-east
const IN := Vector2(-0.6792, -0.7340)     # into the plot
const DOWN := -8.0
const C1 := Vector2(275.24, -533.51)      # the old nave: its other corner on the road...
const T0 := Vector2(218.76, -545.09)      # ...and its two on the Triunfo (the south-west one, by the corner house...
const T1 := Vector2(227.29, -556.58)      # ...and the north-east one). Both a metre back from Catastro's line, and T2
                                          # 0.4 m: the bake keeps 2.4 m of the Triunfo clear either side of its middle, and
                                          # Catastro's wall stands up to 0.95 m inside that (tools/almazara/LEEME.md)
const T2 := Vector2(238.73, -573.00)      # the Triunfo: where the block of two floors ends...
const T3 := Vector2(244.48, -581.42)      # ...where the low old stretch does...
const B := Vector2(269.73, -615.42)       # ...where the street bends...
const E0 := Vector2(279.33, -637.50)      # ...and the mill's last corner on it
const E1 := Vector2(302.76, -633.48)      # the naves' north-east end, inside the block
const Q1 := Vector2(298.58, -612.00)      # the naves' side on the yard: from here...
const Q0 := Vector2(280.41, -581.98)      # ...to here, by the reception nave
const OA := Vector2(240.50, -550.38)      # the offices' front on the yard, from the old nave...
const OB := Vector2(260.29, -577.48)      # ...to the reception nave
const OA2 := Vector2(233.53, -553.77)     # their back
const OB2 := Vector2(254.11, -581.97)
const T2P := Vector2(245.32, -569.93)     # on their back's line, behind T2 and T3
const T3P := Vector2(251.33, -578.17)
const RS := Vector2(278.47, -564.22)      # the reception nave: its open front, from here...
const RE := Vector2(287.61, -576.74)      # ...to here
const RN := Vector2(269.43, -590.00)      # its back corner
const LSW := Vector2(301.70, -609.29)     # the big nave behind the tall one (Catastro's north-east lobe)
const WC := Vector2(326.5, -603.5)
const LK := Vector2(333.2, -628.5)
const LN := Vector2(319.55, -630.61)
const LP := Vector2(322.53, -644.79)
const NN := Vector2(336.4, -640.5)        # the tall nave's back corner
const WAY := [14.95, 26.5]                # the way in, along the front
const WALL_END := 89.0
const TALL := [97.5, 165.0]               # the tall nave, along the front
const TALL_H := 14.7
const WALL_H := 3.2
const SKIRT := 0.85
const NAVE_HI := [9.6, 8.6]               # the old nave's roof on the garage's side: at the road, at the Triunfo
const NAVE_LO := [6.6, 5.6]               # ...and on the yard's
const BLUE := 0x2a4aa8
const STEEL := 0x8a8e92

var gate := Vector2.ZERO                  # the middle of the way in, on the front's line
var saffron_spot := Vector2.ZERO
var outlines: Array = []                  # what it has built, as the map's outlines
var lamps: Array = []

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"crema":
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.95, 0.88)), 0.18)
		"salmon":
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.95, 0.55, 0.45)), 0.1)
		"azul":
			m = Tex.mat("painted_plaster_wall", Color(0.16, 0.3, 0.78))
		"chapa_bl", "chapa_gris", "chapa_claro", "chapa_osc", "chapa_verde":
			var hex: int = {"chapa_bl": 0xf1eee4, "chapa_gris": 0xb4b8bc, "chapa_claro": 0xcdd0d2, "chapa_osc": 0x6c7076, "chapa_verde": 0x2f5a3a}[key]
			var cm := StandardMaterial3D.new()
			cm.albedo_texture = load(CHAPA)
			cm.albedo_color = Parts.col(hex)
			cm.uv1_triplanar = true
			cm.uv1_scale = Vector3.ONE
			cm.uv1_triplanar_sharpness = 8.0
			cm.roughness = 0.6
			cm.metallic_specular = 0.4
			cm.cull_mode = BaseMaterial3D.CULL_DISABLED
			if key == "chapa_bl":
				_glow(cm, 0.12)
				cm.emission_texture = cm.albedo_texture
			m = cm
		"hormigon":
			m = W._tmat(0xb4b2ac, "asphalt", 3.0)
		"cesped":
			m = W._tmat(0x86b85c, "grass", 3.0)
		"acero":
			var sm := StandardMaterial3D.new()
			sm.albedo_color = Color(0.84, 0.85, 0.86)
			sm.metallic = 0.3
			sm.roughness = 0.42
			m = sm
		"cristal":
			var gm := StandardMaterial3D.new()
			gm.albedo_color = Color(0.1, 0.14, 0.17)
			gm.roughness = 0.12
			gm.metallic_specular = 0.7
			m = gm
		"mural", "logo", "logo_gris", "emblema", "cartel", "tienda":
			var tm := StandardMaterial3D.new()
			tm.albedo_texture = load(DIR + String(key) + ".png")
			tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			tm.alpha_scissor_threshold = 0.5
			tm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			tm.roughness = 0.9
			m = tm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	level = MapData.height(Vector2(272.0, -556.0)) + 0.02
	transform = Transform3D(Basis.IDENTITY, Vector3(0, level, 0))
	W.add_child(self)
	gate = P((WAY[0] + WAY[1]) / 2.0, 0.0)
	_floors()
	_old_nave()
	_offices()
	_reception()
	_back_naves()
	_lobe()
	_tall_nave()
	_road_wall()
	_shed()
	_tanks()
	_flags()
	_greens()
	_saffron(P(87.5, 2.2))
	home()
	_commit()
	_tell_map()

# ---------------- helpers ----------------
## a spot of the plot: s metres along the road front from its south-west corner, d metres into the plot
func P(s: float, d: float) -> Vector2:
	return A + U * s + IN * d

## the ground at a spot of the map, as a height in this frame
func gr(p: Vector2) -> float:
	return MapData.height(p) - level

## the ground before a wall (face(a, b)), x metres along it, `out` metres out of it
func _g(a: Vector2, b: Vector2, x: float, out := 0.6) -> float:
	var d := (b - a).normalized()
	return gr(a + d * x + Vector2(-d.y, d.x) * out)

## the frame of the road front: x = s, z = -d (out towards the road)
func _front() -> void:
	_xf = Transform3D(Basis(Vector3(U.x, 0, U.y), Vector3.UP, Vector3(-U.y, 0, U.x)), Vector3(A.x, 0, A.y))

## a plain piece of wall in the frame being built, from y0 up to ya at x0 and yb at x1
func _sloped(x0: float, x1: float, y0: float, ya: float, yb: float, key, z := 0.0) -> void:
	pieces += 1
	quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, yb, z), Vector3(x0, ya, z), key, Vector3(0, 0, 1))

## A stretch of the wall face(a, b) that stands h over the ground before it and follows it, from x0 to x1. With
## `thick`, its back and its top too (a wall standing on its own).
func _follow(a: Vector2, b: Vector2, x0: float, x1: float, h: float, key, z := 0.0, thick := 0.0, step := 2.5) -> void:
	var n := maxi(1, int(ceil((x1 - x0) / step)))
	for i in range(n):
		var xa := lerpf(x0, x1, float(i) / n)
		var xb := lerpf(x0, x1, float(i + 1) / n)
		var ya := _g(a, b, xa) + h
		var yb := _g(a, b, xb) + h
		pieces += 1
		quad(Vector3(xa, DOWN, z), Vector3(xb, DOWN, z), Vector3(xb, yb, z), Vector3(xa, ya, z), key, Vector3(0, 0, 1))
		if thick > 0.0:
			quad(Vector3(xa, DOWN, z - thick), Vector3(xb, DOWN, z - thick), Vector3(xb, yb, z - thick), Vector3(xa, ya, z - thick), key, Vector3(0, 0, -1))
			quad(Vector3(xa, ya, z), Vector3(xb, yb, z), Vector3(xb, yb, z - thick), Vector3(xa, ya, z - thick), key, Vector3.UP)

## a flat picture (x0..x1, y0..y1) on the plane z of the frame being built, facing +z
func _picture(x0: float, x1: float, y0: float, y1: float, z: float, key) -> void:
	pieces += 1
	quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

## the name on a wall, its middle at x, w wide, its foot at y
func _name(x: float, y: float, w: float, key = "logo") -> void:
	_picture(x - w / 2.0, x + w / 2.0, y, y + w * 520.0 / 1377.0, 0.025, key)

## twice the area of an outline, signed: negative when face(a, b) of its sides, taken in order, looks out
func _area2(pts: Array) -> float:
	var s := 0.0
	for i in range(pts.size()):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		s += a.x * b.y - b.x * a.y
	return s

## the walls round an outline, plain, from under the ground up to `top`, but for the sides in `skip` (by number)
func _ring(pts: Array, top: float, key, skip: Array = []) -> void:
	var out_as_given := _area2(pts) < 0.0
	for i in range(pts.size()):
		if i in skip:
			continue
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		var ln := face(a, b) if out_as_given else face(b, a)
		_sloped(0.0, ln, DOWN, top, top, key)
	home()

## an outline as a solid and as one of the map's
func _mass(pts: Array, top: float) -> void:
	_prism(pts, DOWN, top)
	outlines.append(PackedVector2Array(pts))

## a round thing lying on the wall being built (a vent, a lamp's glass)
func _disc(at: Vector3, r: float, key, deep := 0.05) -> void:
	var keep := _xf
	_xf = keep * Transform3D(Basis(Vector3.RIGHT, PI / 2.0), at)
	drum(Vector3.ZERO, r, r, deep, key, 12)
	_xf = keep

## a solid in the frame of the road front: from s0 to s1, d0 to d1 into the plot, y0 to y1
func _solid_f(s0: float, s1: float, d0: float, d1: float, y0: float, y1: float) -> void:
	var m := P((s0 + s1) / 2.0, (d0 + d1) / 2.0)
	solid(Vector3(m.x, (y0 + y1) / 2.0, m.y), Vector3(absf(s1 - s0), absf(y1 - y0), absf(d1 - d0)), atan2(-U.y, U.x))

func _ccw(p: PackedVector2Array) -> PackedVector2Array:
	if Geometry2D.is_polygon_clockwise(p):
		p.reverse()
	return p

func _facets(box_: Rect2) -> Array:
	var out: Array = []
	var g: float = MapData.rg
	for i in range(int(floor((box_.position.x - MapData.rx0) / g)), int(floor((box_.end.x - MapData.rx0) / g)) + 1):
		for j in range(int(floor((box_.position.y - MapData.rz0) / g)), int(floor((box_.end.y - MapData.rz0) / g)) + 1):
			var a := Vector2(MapData.rx0 + i * g, MapData.rz0 + j * g)
			out.append(_ccw(PackedVector2Array([a, a + Vector2(g, 0), a + Vector2(g, g)])))
			out.append(_ccw(PackedVector2Array([a, a + Vector2(g, g), a + Vector2(0, g)])))
	return out

## a flat piece of this outline (on the map) laid on the ground `lift` over it, cut along the relief's facets
func _lay(pts: Array, lift: float, key) -> void:
	pieces += 1
	var keep := _xf
	home()
	var mp := _ccw(PackedVector2Array(pts))
	var bx := Rect2(mp[0], Vector2.ZERO)
	for q in mp:
		bx = bx.expand(q)
	for facet: PackedVector2Array in _facets(bx):
		for piece in Geometry2D.intersect_polygons(mp, facet):
			if piece.size() < 3 or Geometry2D.is_polygon_clockwise(piece):
				continue
			var idx := Geometry2D.triangulate_polygon(piece)
			for t in range(0, idx.size(), 3):
				var a: Vector2 = piece[idx[t]]
				var b: Vector2 = piece[idx[t + 1]]
				var c: Vector2 = piece[idx[t + 2]]
				tri(Vector3(a.x, gr(a) + lift, a.y), Vector3(b.x, gr(b) + lift, b.y), Vector3(c.x, gr(c) + lift, c.y), key, Vector3.UP)
	_xf = keep

## a window of the works: its hole's glass, a pale blind down over most of it, a grille
func _barred(r: Rect2, blind := 0.7) -> void:
	box(r.position.x, r.position.y, -DEEP + 0.03, r.size.x, r.size.y, 0.03, "cristal")
	if blind > 0.0:
		box(r.position.x + 0.03, r.end.y - r.size.y * blind, -DEEP + 0.07, r.size.x - 0.06, r.size.y * blind, 0.03, 0xdcdad2)
	grille(r, 0.1, 0x9a9c9e)
	box(r.position.x - 0.06, r.position.y - 0.06, 0.0, r.size.x + 0.12, 0.06, 0.1, 0xd8d6ce)

## a roller door of ribbed sheet on the wall being built
func _roller(x0: float, x1: float, y0: float, y1: float, key = "chapa_gris") -> void:
	box(x0, y0, 0.0, x1 - x0, y1 - y0, 0.06, key)
	box(x0 - 0.12, y0, 0.0, 0.12, y1 - y0 + 0.3, 0.1, STEEL)
	box(x1, y0, 0.0, 0.12, y1 - y0 + 0.3, 0.1, STEEL)
	box(x0 - 0.12, y1, 0.0, x1 - x0 + 0.24, 0.3, 0.14, STEEL)

# ---------------- the ground ----------------
func _floors() -> void:
	# the yard, from the way in to the tall nave, under the shed and the tanks too
	_lay([C1, P(WAY[1], 0.25), P(WALL_END, 0.25), P(WALL_END, 10.0), P(98.9, 10.0), WC, LSW, Q1, Q0, RE, RS, OB, OA], 0.04, "hormigon")
	_lay([OB, RS, RE, RN], 0.05, "hormigon")
	# before the way in: the apron down to the road's pavement, and the lawn before the wall
	_lay([P(WAY[0] - 0.4, 0.3), P(WAY[1] + 0.4, 0.3), P(WAY[1] + 2.0, -7.4), P(WAY[0] - 2.0, -7.4)], 0.045, "hormigon")
	_lay([P(27.6, -0.4), P(46.0, -0.4), P(46.0, -5.0), P(28.6, -5.0)], 0.05, "cesped")

# ---------------- the old nave: the mural on the road, the shop's side on the yard, its end on the Triunfo ----------------
func _old_nave() -> void:
	var hi0: float = NAVE_HI[0]
	var hi1: float = NAVE_HI[1]
	var lo0: float = NAVE_LO[0]
	var lo1: float = NAVE_LO[1]
	# its end on the road: the mural
	var ln := face(A, C1)
	var g := _g(A, C1, ln / 2.0)
	_sloped(0.0, ln, DOWN, hi0, lo0, "white")
	plinth(0.0, ln, g + SKIRT, g + SKIRT, "azul", 0.03, DOWN)
	_picture(0.0, ln, g, g + 6.6, 0.015, "mural")
	bar(Vector3(-0.06, hi0 + 0.03, 0.02), Vector3(ln + 0.06, lo0 + 0.03, 0.02), 0.2, 0.08, 0x9a9ea2)
	box(ln - 0.3, lo0, -0.35, 0.1, 1.4, 0.1, STEEL)                     # the floodlight on its mast, at the corner of the way in
	box(ln - 0.5, lo0 + 1.3, -0.4, 0.5, 0.26, 0.4, 0x3a3c3f)
	var lamp: Vector3 = transform * (_xf * Vector3(ln + 1.5, lo0 + 1.2, -2.0))
	W.lamp_spots.append(lamp)
	lamps.append(lamp)
	# its side against the garage: bare but for the corner, which shows
	ln = face(T0, A)
	_sloped(0.0, ln, DOWN, hi1, hi0, "white")
	plinth(ln - 3.72, ln, g + SKIRT, g + SKIRT, "azul", 0.03, DOWN)
	# its side on the yard: the shop
	ln = face(C1, T1)
	var gy := _g(C1, T1, 10.0)
	var holes: Array = []
	var wins: Array = [Rect2(8.6, gy + 1.1, 1.2, 1.1), Rect2(11.2, gy + 1.1, 1.2, 1.1), Rect2(15.6, gy + 1.1, 1.2, 1.1), Rect2(28.6, gy + 1.1, 1.2, 1.1), Rect2(31.6, gy + 1.1, 1.2, 1.1), Rect2(8.0, gy + 4.0, 0.8, 0.7)]
	var doors: Array = [Rect2(13.5, DOWN, 1.0, gy + 2.1 - DOWN), Rect2(18.2, DOWN, 1.0, gy + 2.1 - DOWN)]
	var big := Rect2(22.0, DOWN, 4.2, gy + 4.3 - DOWN)
	holes.append_array(wins)
	holes.append_array(doors)
	holes.append(big)
	masonry(0.0, ln, DOWN, 5.2, holes, [], "white")
	_sloped(0.0, ln, 5.2, lo0, lo1, "white")
	plinth(0.0, 3.0, gy + SKIRT, gy + SKIRT, "azul", 0.03, DOWN)
	for r: Rect2 in wins:
		window(r, 0x6a4a30, 0x1f2a33, 1)
		box(r.position.x - 0.06, r.position.y - 0.06, 0.0, r.size.x + 0.12, 0.06, 0.08, 0xd8d6ce)
	for i in range(doors.size()):
		var r: Rect2 = doors[i]
		box(r.position.x, gy, -DEEP + 0.04, r.size.x, 2.1, 0.05, 0xe8e6e0)
		if i == 0:                                                          # (the shop's: glazed)
			box(r.position.x + 0.12, gy + 0.9, -DEEP + 0.09, r.size.x - 0.24, 1.05, 0.01, "cristal")
		box(r.end.x - 0.18, gy + 1.0, -DEEP + 0.09, 0.04, 0.14, 0.05, STEEL)
		box(r.position.x - 0.05, gy - 0.3, -0.05, r.size.x + 0.1, 0.34, 0.3, 0xb8b6ae)
	box(big.position.x, gy, -DEEP + 0.04, big.size.x, 4.3, 0.06, "chapa_verde")
	box(big.position.x - 0.1, gy + 4.3, 0.0, big.size.x + 0.2, 0.18, 0.1, STEEL)
	_picture(1.3, 2.5, gy + 1.15, gy + 2.15, 0.03, "tienda")
	box(1.26, gy + 1.11, 0.0, 1.28, 1.08, 0.025, 0xe8e6e0)
	_picture(5.3, 6.2, gy + 0.5, gy + 4.0, 0.035, "cartel")
	# the band of ribbed sheet along its top, from past the corner to the offices
	var x0 := 4.0
	var x1 := OA.distance_to(C1)
	var ya := lerpf(lo0, lo1, x0 / ln)
	var yb := lerpf(lo0, lo1, x1 / ln)
	quad(Vector3(x0, ya - 1.45, 0.14), Vector3(x1, yb - 1.45, 0.14), Vector3(x1, yb + 0.12, 0.14), Vector3(x0, ya + 0.12, 0.14), "chapa_bl", Vector3(0, 0, 1))
	quad(Vector3(x0, ya - 1.45, 0.0), Vector3(x1, yb - 1.45, 0.0), Vector3(x1, yb - 1.45, 0.14), Vector3(x0, ya - 1.45, 0.14), 0xb8bcc0, Vector3.DOWN)
	quad(Vector3(x0, ya - 1.45, 0.0), Vector3(x0, ya - 1.45, 0.14), Vector3(x0, ya + 0.12, 0.14), Vector3(x0, ya + 0.12, 0.0), "chapa_bl", Vector3(-1, 0, 0))
	# its end on the Triunfo: the barred windows, two round vents, the blue-grey edge of the roof
	ln = face(T1, T0)
	var gt := _g(T1, T0, ln / 2.0, 1.0)
	holes = []
	wins = [Rect2(6.6, gt + 0.9, 1.4, 1.3), Rect2(8.3, gt + 0.9, 1.4, 1.3), Rect2(10.0, gt + 0.9, 1.4, 1.3), Rect2(4.1, gt + 0.5, 0.6, 0.6), Rect2(4.9, gt + 0.5, 0.6, 0.6)]
	holes.append_array(wins)
	masonry(0.0, ln, DOWN, lo1, holes, [], "white")
	tri(Vector3(0, lo1, 0), Vector3(ln, lo1, 0), Vector3(ln, hi1, 0), "white", Vector3(0, 0, 1))
	for r: Rect2 in wins:
		_barred(r, 0.75 if r.size.x > 1.0 else 0.0)
	bar(Vector3(-0.1, lo1 - 0.1, 0.04), Vector3(ln + 0.1, hi1 - 0.1, 0.04), 0.1, 0.26, 0x8a9aae)
	_disc(Vector3(3.6, gt + 4.2, 0.0), 0.22, 0x6a4a3a)
	_disc(Vector3(9.2, gt + 5.2, 0.0), 0.22, 0x6a4a3a)
	home()
	# its roof: one slope of grey sheet
	pieces += 1
	quad(Vector3(A.x, hi0, A.y), Vector3(C1.x, lo0, C1.y), Vector3(T1.x, lo1, T1.y), Vector3(T0.x, hi1, T0.y), "chapa_gris", Vector3(0.2, 1, 0.1))
	_mass([A, C1, T1, T0], lo1)

# ---------------- the block on the Triunfo, the low old stretch, the offices on the yard ----------------
func _offices() -> void:
	# the block of two floors on the Triunfo: cream, a flat roof behind its parapet, its windows upstairs
	var ln := face(T2, T1)
	var g := _g(T2, T1, ln / 2.0, 1.0)
	var top := g + 7.3
	var holes: Array = []
	for q in [[2.2, 4.5, 1.2, 1.1], [6.0, 4.3, 1.1, 1.1], [7.7, 4.3, 1.0, 1.1], [9.2, 4.3, 1.1, 1.1], [11.8, 4.3, 1.1, 1.1], [13.9, 4.3, 1.1, 1.1], [16.2, 4.7, 0.45, 0.6], [17.6, 4.7, 0.45, 0.6], [19.0, 4.7, 0.45, 0.6]]:
		holes.append(Rect2(q[0], g + q[1], q[2], q[3]))
	masonry(0.0, ln, DOWN, top, holes, [], "crema")
	for r: Rect2 in holes:
		window(r, 0xe8e6e0, 0x1f2a33, 0)
		box(r.position.x - 0.05, r.position.y - 0.06, 0.0, r.size.x + 0.1, 0.06, 0.08, 0xd8d0c0)
		if r.size.x > 1.0:                                                  # (their blinds, part down)
			box(r.position.x + 0.07, r.end.y - 0.35, -DEEP + 0.08, r.size.x - 0.14, 0.35, 0.03, 0x8a6a48)
	box(-0.03, top, -0.25, ln + 0.06, 0.07, 0.3, 0xd8d0c0)
	bar(Vector3(0.0, g + 4.15, 0.03), Vector3(ln, g + 4.15, 0.03), 0.03, 0.03, 0x2a2a2c)      # (the cable along it)
	home()
	_ring([T1, T2, T2P, OA2], top, "crema", [0])
	flat(PackedVector2Array([T1, T2, T2P, OA2]), top - 0.3, 0xcfc4ae)
	_mass([T1, T2, T2P, OA2], top)
	# the low old stretch: white, an eave of tiles, a drainpipe
	ln = face(T3, T2)
	g = _g(T3, T2, ln / 2.0, 1.0)
	var eave := g + 5.1
	_sloped(0.0, ln, DOWN, eave, eave, "white")
	box(4.9, g + 0.3, 0.0, 0.1, eave - g - 0.5, 0.1, 0x8a8e92)
	home()
	var out := Vector2(-0.803, -0.596) * 0.35
	roof([Vector3(T3.x + out.x, eave - 0.08, T3.y + out.y), Vector3(T2.x + out.x, eave - 0.08, T2.y + out.y), Vector3(T2P.x, eave + 1.5, T2P.y), Vector3(T3P.x, eave + 1.5, T3P.y)])
	_ring([T2, T3, T3P, T2P], eave + 1.5, "white", [0, 1, 3])
	_mass([T2, T3, T3P, T2P], eave)
	# the offices: salmon, two floors under tiles, on the yard
	ln = face(OA, OB)
	g = _g(OA, OB, ln / 2.0, 1.0)
	eave = g + 6.1
	holes = []
	var up: Array = []
	var down: Array = []
	var doors: Array = []
	for x in [2.4, 6.4, 10.4, 14.4, 18.4, 22.4, 26.4, 30.4]:
		up.append(Rect2(x, g + 3.9, 1.4, 1.2))
	for x in [2.4, 6.4, 14.4, 22.4, 30.4]:
		down.append(Rect2(x, g + 1.05, 1.4, 1.2))
	for x in [10.5, 26.5]:
		doors.append(Rect2(x, DOWN, 1.2, g + 2.2 - DOWN))
	holes.append_array(up)
	holes.append_array(down)
	holes.append_array(doors)
	masonry(0.0, ln, DOWN, eave, holes, [], "salmon")
	plinth(0.0, 10.5, g + 0.5, g + 0.5, 0x9a8a7a, 0.03, DOWN)
	plinth(11.7, 26.5, g + 0.5, g + 0.5, 0x9a8a7a, 0.03, DOWN)
	plinth(27.7, ln, g + 0.5, g + 0.5, 0x9a8a7a, 0.03, DOWN)
	for r: Rect2 in up:
		window(r, 0x6a4a30, 0x1f2a33, 1)
		box(r.position.x + 0.07, r.end.y - 0.55, -DEEP + 0.08, r.size.x - 0.14, 0.55, 0.03, 0x8a6a48)
		box(r.position.x - 0.06, r.position.y - 0.07, 0.0, r.size.x + 0.12, 0.07, 0.1, 0xc8a890)
	for r: Rect2 in down:
		window(r, 0x6a4a30, 0x1f2a33, 1)
		grille(r, 0.12, 0x26262a)
		box(r.position.x - 0.06, r.position.y - 0.07, 0.0, r.size.x + 0.12, 0.07, 0.1, 0xc8a890)
	for r: Rect2 in doors:
		box(r.position.x, g, -DEEP + 0.04, r.size.x, 2.2, 0.06, 0x7a5232)
		for k in range(1, 3):
			box(r.position.x + r.size.x * k / 3.0 - 0.008, g + 0.05, -DEEP + 0.1, 0.016, 2.1, 0.006, 0x4a3020)
		box(r.position.x - 0.1, g - 0.3, -0.05, r.size.x + 0.2, 0.36, 0.5, 0xb8a898)
		# its little roof of tiles on two brackets
		roof([Vector3(r.position.x - 0.45, g + 2.95, 0.0), Vector3(r.end.x + 0.45, g + 2.95, 0.0), Vector3(r.end.x + 0.45, g + 2.6, 0.8), Vector3(r.position.x - 0.45, g + 2.6, 0.8)])
		for x in [r.position.x - 0.3, r.end.x + 0.22]:
			bar(Vector3(x + 0.04, g + 2.1, 0.02), Vector3(x + 0.04, g + 2.62, 0.7), 0.07, 0.07, 0x5a3a22)
	box(-0.2, eave - 0.12, 0.0, ln + 0.4, 0.12, 0.3, 0xb5653f)                  # the eave's edge
	home()
	# its roof: two slopes of tiles, the ridge along its middle
	var mid0 := (OA + OA2) / 2.0
	var mid1 := (OB + OB2) / 2.0
	var fo := Vector2(0.8078, 0.5895) * 0.4                                   # (the eaves come out a little)
	roof([Vector3(OA.x + fo.x, eave - 0.05, OA.y + fo.y), Vector3(OB.x + fo.x, eave - 0.05, OB.y + fo.y), Vector3(mid1.x, eave + 1.4, mid1.y), Vector3(mid0.x, eave + 1.4, mid0.y)])
	roof([Vector3(mid0.x, eave + 1.4, mid0.y), Vector3(mid1.x, eave + 1.4, mid1.y), Vector3(OB2.x, eave, OB2.y), Vector3(OA2.x, eave, OA2.y)])
	ridge(Vector3(mid0.x, eave + 1.4, mid0.y), Vector3(mid1.x, eave + 1.4, mid1.y))
	_ring([OA, OB, OB2, OA2], eave, "salmon", [0])
	for e in [[OB, OB2, mid1], [OA2, OA, mid0]]:                              # its gables
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		var c: Vector2 = e[2]
		tri(Vector3(a.x, eave, a.y), Vector3(b.x, eave, b.y), Vector3(c.x, eave + 1.4, c.y), "salmon", Vector3((c - (OA + OB) / 2.0).x, 0, (c - (OA + OB) / 2.0).y).normalized())
	_mass([OA, OB, OB2, OA2], eave)

# ---------------- the reception nave: open in front and on the offices' side, its cabin, its hopper and its belt ----------------
## Where the olives come in. Its place and size are the roof with the solar panels of the orthophoto (26 x 16 m, from
## the offices' end out into the yard), pinned by Street View from the way in: its corner on the yard stands 32 m from
## that camera, 9.2 m high, the sheet coming down to 6 m over the floor on the two open sides.
func _reception() -> void:
	var ln := face(RS, RE)
	var g := _g(RS, RE, ln / 2.0, 1.0)
	var top := g + 9.2
	var band := g + 6.0
	var deep := RS.distance_to(OB)
	# the band of white sheet over the open front, the badge on it, the beam under it and the three posts
	_sloped(0.0, ln, band, top, top, "chapa_bl")
	box(0.0, band - 0.3, -0.3, ln, 0.3, 0.3, STEEL)
	for x in [0.0, ln / 2.0 - 0.15, ln - 0.3]:
		box(x, DOWN, -0.3, 0.3, band - DOWN, 0.3, STEEL)
	_picture(2.0, 4.6, band + 0.3, band + 2.9, 0.03, "emblema")
	# inside (x along the front, -z into it): the cabin on its platform by the open side, the stair up to it from
	# the front, the striped post by the corner
	box(0.8, g + 1.2, -8.0, 4.4, 0.15, 4.0, 0x9a9ea2)
	for q in [[0.9, -7.9], [5.0, -7.9], [0.9, -4.2], [5.0, -4.2]]:
		box(q[0], g, q[1], 0.12, 1.2, 0.12, STEEL)
	box(1.2, g + 1.35, -7.8, 3.8, 2.5, 3.2, 0xeeeeea)
	box(1.4, g + 2.3, -4.59, 3.4, 1.0, 0.02, "cristal")
	box(1.19, g + 2.3, -7.5, 0.02, 1.0, 2.6, "cristal")
	for k in range(6):
		box(1.0, g + 0.2 * k, -2.2 - 0.3 * (k + 1), 1.0, 0.2, 0.3, 0x8a8e92)
	bar(Vector3(2.02, g + 1.0, -2.2), Vector3(2.02, g + 2.2, -4.0), 0.04, 0.04, 0xd8b020)
	bar(Vector3(0.98, g + 1.0, -2.2), Vector3(0.98, g + 2.2, -4.0), 0.04, 0.04, 0xd8b020)
	for x in [5.2, 0.8]:                                                         # the platform's rail
		bar(Vector3(x, g + 2.3, -4.0), Vector3(x, g + 2.3, -8.0), 0.04, 0.04, 0xd8b020)
	for k in range(5):
		box(0.5, g + 0.24 * k, -0.9, 0.14, 0.24, 0.14, 0xe8c020 if k % 2 == 0 else 0x26262a)
	_solid_r(0.8, 5.2, -8.0, -2.2, g, g + 3.9, RS, RE)
	# the hopper on its legs, and the belt from it up to the back
	var hx := 10.8
	var hz := -8.0
	var rim := g + 3.3
	for q in [[-1, -1], [1, -1], [1, 1], [-1, 1]]:
		box(hx + q[0] * 1.9 - 0.08, g, hz + q[1] * 1.9 - 0.08, 0.16, rim - g, 0.16, STEEL)
	for k in range(4):
		var a0 := Vector2([-1, 1, 1, -1][k], [-1, -1, 1, 1][k])
		var a1 := Vector2([1, 1, -1, -1][k], [-1, 1, 1, -1][k])
		var n := Vector3((a0.x + a1.x) / 2.0, 0.6, (a0.y + a1.y) / 2.0).normalized()
		quad(Vector3(hx + a0.x * 2.0, rim, hz + a0.y * 2.0), Vector3(hx + a1.x * 2.0, rim, hz + a1.y * 2.0), Vector3(hx + a1.x * 0.4, g + 1.1, hz + a1.y * 0.4), Vector3(hx + a0.x * 0.4, g + 1.1, hz + a0.y * 0.4), 0x9aa0a6, n)
		quad(Vector3(hx + a0.x * 2.0, rim, hz + a0.y * 2.0), Vector3(hx + a1.x * 2.0, rim, hz + a1.y * 2.0), Vector3(hx + a1.x * 0.4, g + 1.1, hz + a1.y * 0.4), Vector3(hx + a0.x * 0.4, g + 1.1, hz + a0.y * 0.4), 0x6a7076, -n)
	bar(Vector3(hx, g + 1.0, hz - 0.5), Vector3(hx - 3.0, g + 6.0, hz - 9.5), 0.9, 0.25, 0x4a5a4a)
	for t in [0.35, 0.7]:
		var at := Vector3(hx, g, hz - 0.5).lerp(Vector3(hx - 3.0, g, hz - 9.5), t)
		for dx in [-0.5, 0.4]:
			box(at.x + dx, g, at.z, 0.1, 1.0 + 5.0 * t - 0.2, 0.1, STEEL)
	_solid_r(hx - 2.0, hx + 2.0, hz - 2.0, hz + 2.0, g, rim, RS, RE)
	# steel vats at the back
	for x in [4.0, 7.2, 10.4, 13.4]:
		drum(Vector3(x, g, -deep + 2.6), 1.25, 1.25, 5.2, "acero", 16)
		drum(Vector3(x, g + 5.2, -deep + 2.6), 1.25, 0.25, 0.6, "acero", 16)
	_solid_r(2.6, 14.8, -deep + 1.3, -deep + 3.9, g, g + 5.5, RS, RE)
	# its back, seen through the front
	_sloped(0.0, ln, DOWN, top, top, "chapa_bl", -deep + 0.05)
	# its lights, under the roof
	for x in [4.0, 11.5]:
		box(x - 0.6, top - 0.5, -6.0, 1.2, 0.08, 0.3, 0xf4f0d8)
		var lamp: Vector3 = transform * (_xf * Vector3(x, top - 1.2, -5.0))
		W.lamp_spots.append(lamp)
		lamps.append(lamp)
	# its roof and the panels on it: the sheet from above, its dark underside from below
	pieces += 1
	quad(Vector3(-0.3, top, 0.3), Vector3(ln, top, 0.3), Vector3(ln, top, -deep), Vector3(-0.3, top, -deep), "chapa_gris", Vector3.UP)
	quad(Vector3(0, top - 0.25, 0.0), Vector3(ln, top - 0.25, 0.0), Vector3(ln, top - 0.25, -deep), Vector3(0, top - 0.25, -deep), 0x8a8e92, Vector3.DOWN)
	for i in range(8):
		var z := -1.2 - i * 2.6
		box(1.0, top + 0.05, z - 2.1, ln - 2.0, 0.07, 2.1, 0x1c2a4a)
		for k in range(1, 9):
			box(1.0 + (ln - 2.0) * k / 9.0 - 0.015, top + 0.12, z - 2.1, 0.03, 0.006, 2.1, 0xaab4c4)
	home()
	# its side on the offices' yard: open under the sheet too, on four posts
	var ls := face(OB, RS)
	_sloped(0.0, ls, band, top, top, "chapa_bl")
	_sloped(0.0, ls, band, top, top, "chapa_bl", -0.2)
	box(0.0, band - 0.3, -0.3, ls, 0.3, 0.3, STEEL)
	for k in range(4):
		box(ls * k / 4.0, DOWN, -0.3, 0.3, band - DOWN, 0.3, STEEL)
	home()
	for k in range(4):
		var pp := OB.lerp(RS, k / 4.0) + (RS - OB).normalized() * 0.15 + Vector2(0.5895, -0.8078) * 0.15
		solid(Vector3(pp.x, g + 3.0, pp.y), Vector3(0.3, 6.0, 0.3))
	# its other side: plaster below, sheet above
	var l2 := face(RE, RN)
	_sloped(0.0, l2, DOWN, g + 2.6, g + 2.6, "white")
	_sloped(0.0, l2, g + 2.6, top, top, "chapa_bl", 0.04)
	_sloped(0.0, l2, DOWN, top, top, "chapa_bl", -0.2)                          # (and from inside)
	home()
	var m := (RE + RN) / 2.0
	var d := (RN - RE).normalized()
	solid(Vector3(m.x, (g + top) / 2.0, m.y), Vector3(RE.distance_to(RN), top - g, 0.3), atan2(-d.y, d.x))
	m = (OB + RN) / 2.0                                                          # (and its back)
	d = (RN - OB).normalized()
	solid(Vector3(m.x, (g + top) / 2.0, m.y), Vector3(OB.distance_to(RN), top - g, 0.3), atan2(-d.y, d.x))
	for x in [0.15, ln / 2.0, ln - 0.15]:                                       # the posts of its front
		var p: Vector2 = RS + (RE - RS).normalized() * float(x) + Vector2(-0.8078, -0.5895) * 0.15
		solid(Vector3(p.x, g + 3.0, p.y), Vector3(0.3, 6.0, 0.3))
	outlines.append(PackedVector2Array([OB, RS, RE, RN]))

## a solid in the frame of face(a, b): x0..x1 along it, z0..z1 (out of it +), y0..y1
func _solid_r(x0: float, x1: float, z0: float, z1: float, y0: float, y1: float, a: Vector2, b: Vector2) -> void:
	var d := (b - a).normalized()
	var o := Vector2(-d.y, d.x)
	var m := a + d * ((x0 + x1) / 2.0) + o * ((z0 + z1) / 2.0)
	solid(Vector3(m.x, (y0 + y1) / 2.0, m.y), Vector3(absf(x1 - x0), absf(y1 - y0), absf(z1 - z0)), atan2(-d.y, d.x))

# ---------------- the naves along the Triunfo ----------------
func _back_naves() -> void:
	# the long back wall, from the bend to the low old stretch
	var ln := face(B, T3)
	var g := _g(B, T3, ln / 2.0, 1.0)
	var eave := g + 5.0
	var holes: Array = []
	var high: Array = []
	for x in [16.0, 19.0, 23.1, 26.0]:
		high.append(Rect2(x, g + 4.0, 1.6, 0.85))
	var wide := Rect2(9.8, g + 3.4, 3.2, 0.9)
	var low := Rect2(9.5, g + 0.95, 1.3, 1.1)
	holes.append_array(high)
	holes.append(wide)
	holes.append(low)
	masonry(0.0, ln, DOWN, eave, holes, [], "white")
	for r: Rect2 in high:
		window(r, 0x8a8e92, 0x2a3440, 0)
		for k in range(1, 3):
			box(r.position.x + r.size.x * k / 3.0 - 0.02, r.position.y, -DEEP + 0.1, 0.04, r.size.y, 0.04, 0x8a8e92)
	box(wide.position.x, wide.position.y, -DEEP + 0.03, wide.size.x, wide.size.y, 0.03, "cristal")
	grille(wide, 0.06, 0x9a9c9e)
	_barred(low, 0.0)
	box(6.4, g + 1.65, 0.0, 0.22, 0.22, 0.03, 0x6a6e72)                         # a small vent
	box(5.65, g + 2.6, 0.0, 0.1, eave - g - 2.7, 0.1, STEEL)                    # the drainpipe
	for x in [7.2, 12.4]:                                                       # the air machines
		box(x, g + 4.55, 0.0, 0.8, 0.55, 0.3, 0xe4e4e0)
		_disc(Vector3(x + 0.3, g + 4.82, 0.3), 0.2, 0x5a5e62, 0.02)
	box(34.8, g + 4.5, 0.0, 0.2, 0.14, 0.3, 0x3a3c3f)                           # a lamp on the wall
	var lamp: Vector3 = transform * (_xf * Vector3(35.0, g + 4.4, 1.5))
	W.lamp_spots.append(lamp)
	lamps.append(lamp)
	_eave(ln, eave)
	# the long raised light of the roof, behind the eave
	box(17.0, eave + 1.5, -7.2, 13.0, 1.1, 2.6, "chapa_gris")
	box(17.0, eave + 2.6, -7.4, 13.0, 1.0, 3.0, "chapa_osc")
	box(17.2, eave + 2.75, -4.38, 12.6, 0.7, 0.02, 0x4a5a6a)
	# the wall beyond the bend, to the mill's last corner
	ln = face(E0, B)
	g = _g(E0, B, ln / 2.0, 1.0)
	var eave2 := g + 5.2
	_sloped(0.0, ln, DOWN, eave2, eave2, "white")
	_disc(Vector3(16.3, g + 4.75, 0.0), 0.2, 0x4a4e52)
	box(20.1, g + 4.8, 0.0, 0.5, 0.25, 0.03, 0xb8bcc0)
	box(15.7, eave2 + 0.3, -1.6, 0.6, 0.55, 0.6, 0x5a5e62)
	_eave(ln, eave2)
	home()
	# their end, looking on the neighbour's yard, and their side on the mill's own
	ln = face(E1, E0)
	_sloped(0.0, ln, DOWN, eave2 + 1.4, eave2, "white")
	ln = face(Q0, Q1)
	g = _g(Q0, Q1, ln / 2.0, 1.0)
	var top := eave + 1.5
	_sloped(0.0, ln, DOWN, top, top, "white")
	_roller(6.0, 10.5, g, g + 4.6)
	_roller(20.0, 24.5, g, g + 4.6)
	box(14.0, g, 0.0, 1.0, 2.1, 0.05, STEEL)
	home()
	# the roofs: a slope up from each eave on the street, and the flat of sheet behind
	var in1 := Vector2(0.803, 0.596) * 4.0
	var in2 := Vector2(0.917, 0.399) * 4.0
	var o1 := Vector2(-0.803, -0.596) * 0.35
	var o2 := Vector2(-0.917, -0.399) * 0.35
	_sheet_slope([Vector3(T3.x + o1.x, eave + 0.3, T3.y + o1.y), Vector3(B.x + o1.x, eave + 0.3, B.y + o1.y), Vector3(B.x + in1.x, top, B.y + in1.y), Vector3(T3.x + in1.x, top, T3.y + in1.y)], "chapa_gris")
	_sheet_slope([Vector3(B.x + o2.x, eave2 + 0.3, B.y + o2.y), Vector3(E0.x + o2.x, eave2 + 0.3, E0.y + o2.y), Vector3(E0.x + in2.x, top, E0.y + in2.y), Vector3(B.x + in2.x, top, B.y + in2.y)], "chapa_gris")
	flat(PackedVector2Array([T3 + in1, B + in1, B + in2, E0 + in2, E1, Q1, Q0, RN, T3P]), top, "chapa_gris")
	_mass([T3P, T3, B, RN], eave)
	_mass([B, Q1, Q0, RN], eave)
	_mass([B, E0, E1, Q1], eave)

## A sloping piece of plain sheet (four corners in order, all in one plane). It is obra.roof() without the tiles'
## own lay: the rest of this sheet's mesh carries none, and a mesh cannot have it for some of its pieces only (Godot
## said so twelve times at every start, until 22 November 2026).
func _sheet_slope(pts: Array, key) -> void:
	pieces += 1
	var n: Vector3 = ((pts[1] as Vector3) - pts[0]).cross((pts[2] as Vector3) - pts[0]).normalized()
	if n.y < 0.0:
		n = -n
	quad(pts[0], pts[1], pts[2], pts[3], key, n)

## the edge of a sheet roof over the wall being built: the sheet coming out, the gutter under it, a bracket every 3 m
func _eave(ln: float, y: float) -> void:
	box(-0.1, y + 0.22, 0.0, ln + 0.2, 0.06, 0.38, 0xa8acb0)
	box(-0.1, y, 0.0, ln + 0.2, 0.18, 0.2, 0xd8d0c0)
	var n := int(ln / 3.0)
	for i in range(n + 1):
		box(i * ln / maxf(n, 1.0) - 0.04 if i < n else ln - 0.08, y - 0.2, 0.0, 0.08, 0.2, 0.26, 0x8a7a66)

# ---------------- the big nave behind the tall one ----------------
func _lobe() -> void:
	var top := gr((LSW + WC) / 2.0) + 10.0
	var ln := face(LSW, WC)
	_sloped(0.0, ln, DOWN, top, top, "chapa_bl")
	_follow(LSW, WC, 0.0, ln, 1.2, "white", 0.03)
	_roller(4.0, 9.0, _g(LSW, WC, 6.5), _g(LSW, WC, 6.5) + 5.2)
	_roller(14.0, 19.0, _g(LSW, WC, 16.5), _g(LSW, WC, 16.5) + 5.2)
	home()
	_ring([LSW, WC, LK, NN, LP, LN, E1], top, "chapa_bl", [0, 1, 2])
	flat(PackedVector2Array([LSW, WC, LK, NN, LP, LN, E1]), top - 0.1, "chapa_gris")
	_mass([LSW, WC, LK, LN, E1], top)
	_mass([LN, LK, NN, LP], top)

# ---------------- the tall nave on the road ----------------
func _tall_nave() -> void:
	var f0 := P(TALL[0], 0.0)
	var f1 := P(TALL[1], 0.0)
	var ln := face(f0, f1)
	var g := _g(f0, f1, ln / 2.0, 1.0)
	var top := g + TALL_H
	_sloped(0.0, ln, DOWN, top, top, "white")
	_follow(f0, f1, 0.0, ln, SKIRT, "azul", 0.03, 0.0, 5.0)
	var n := 11
	for i in range(1, n):                                                       # the joints of its panels
		box(ln * i / n - 0.02, g + SKIRT, 0.0, 0.04, TALL_H - SKIRT, 0.012, 0xd4d1c6)
	for y in [5.1, 9.9]:
		box(0.0, g + y, 0.0, ln, 0.035, 0.012, 0xd4d1c6)
	box(-0.05, top, -0.3, ln + 0.1, 0.1, 0.36, 0xc8ccd0)                        # its coping
	_name(56.5, g + 9.4, 6.4)                                                   # the name, big, near its far end
	_name(19.6, _g(f0, f1, 19.6) + 1.45, 3.4)
	var dx := 41.1                                                              # a small door in the blue foot
	var dg := _g(f0, f1, dx)
	box(dx, dg, 0.0, 1.0, 2.1, 0.05, 0xf0efe8)
	box(dx + 0.8, dg + 1.0, 0.05, 0.04, 0.12, 0.04, STEEL)
	home()
	_ring([f0, f1, NN, WC], top, "white", [0])
	ln = face(WC, f0)                                                           # its end towards the yard: the name again, high
	_name(ln / 2.0 + 1.0, top - 4.2, 7.0)
	box(-0.05, top, -0.3, ln + 0.1, 0.1, 0.36, 0xc8ccd0)
	ln = face(f1, NN)                                                           # the slanting wall beyond its point: the name, high, by the corner
	_name(6.5, top - 4.4, 7.0)
	box(-0.05, top, -0.3, ln + 0.1, 0.1, 0.36, 0xc8ccd0)
	# the fence of white sheet after it, to the neighbour's wall
	var fa := P(TALL[1], 0.0)
	var fb := P(float(TALL[1]) + 7.0, 0.0)
	ln = face(fa, fb)
	_follow(fa, fb, 0.0, ln, 3.2, "chapa_bl", 0.0, 0.1)
	box(ln - 0.15, DOWN, -0.25, 0.3, _g(fa, fb, ln) + 3.4 - DOWN, 0.4, "white")
	home()
	_solid_f(TALL[1], float(TALL[1]) + 7.0, 0.0, 0.2, g - 1.0, g + 3.2)
	outlines.append(PackedVector2Array([fa, fb, P(float(TALL[1]) + 7.0, 0.2), P(TALL[1], 0.2)]))
	flat(PackedVector2Array([f0, f1, NN, WC]), top - 0.35, "chapa_claro")
	_mass([f0, f1, NN, WC], top)
	# the small building between it and the long wall
	var x0 := P(WALL_END, 0.0)
	var x1 := P(TALL[0], 0.0)
	ln = face(x0, x1)
	var gx := _g(x0, x1, ln / 2.0)
	var xt := gx + 4.9
	_sloped(0.0, ln, DOWN, xt, xt, "white")
	_follow(x0, x1, 0.0, ln, SKIRT, "azul", 0.03)
	_name(ln / 2.0, gx + 1.5, 3.4)
	box(-0.05, xt, -0.3, ln + 0.1, 0.08, 0.36, 0xd8d6ce)
	home()
	var ring: Array = [x0, x1, P(98.9, 10.0), P(WALL_END, 10.0)]
	_ring(ring, xt, "white", [0, 1])
	flat(PackedVector2Array(ring), xt - 0.2, 0xb9b4ac)
	_mass(ring, xt)

# ---------------- the long wall on the road ----------------
func _road_wall() -> void:
	var a := P(WAY[1], 0.0)
	var b := P(WALL_END, 0.0)
	var ln := face(a, b)
	_follow(a, b, 0.0, ln, WALL_H, "white", 0.0, 0.3)
	_follow(a, b, 0.0, ln, SKIRT, "azul", 0.03)
	for s in [36.0, 56.0, 74.5]:
		_name(s - WAY[1], _g(a, b, s - WAY[1]) + 1.45, 3.4)
	var g0 := _g(a, b, 0.0)
	box(-0.25, DOWN, -0.45, 0.5, g0 + WALL_H + 0.2 - DOWN, 0.6, "white")        # the pier of the way in
	box(-0.3, g0 + WALL_H + 0.2, -0.5, 0.6, 0.08, 0.7, 0xd8d6ce)
	# the gate, slid open behind the wall
	for y in [0.12, 1.85]:
		box(0.6, g0 + y, -0.75, 11.0, 0.07, 0.07, STEEL)
	for i in range(56):
		box(0.6 + i * 0.2, g0 + 0.12, -0.74, 0.03, 1.8, 0.03, STEEL)
	home()
	var n := int(ceil(ln / 5.0))
	for i in range(n):                                                          # its solids, a stretch at a time
		var s0: float = float(WAY[1]) + ln * i / n
		var s1: float = float(WAY[1]) + ln * (i + 1) / n
		var g := gr(P((s0 + s1) / 2.0, -0.5))
		_solid_f(s0, s1, 0.0, 0.3, g - 2.0, g + WALL_H)
	outlines.append(PackedVector2Array([a, b, P(WALL_END, 0.3), P(WAY[1], 0.3)]))

# ---------------- behind the wall: the timber shed, the tanks and the low works, the flags ----------------
func _shed() -> void:
	_front()
	var g := gr(P(41.0, 3.5))
	for s in [32.2, 36.7, 41.2, 45.7, 50.2]:
		box(s - 0.1, DOWN, -0.7, 0.2, g + 4.0 - DOWN, 0.2, 0x5a4030)
		box(s - 0.1, DOWN, -6.9, 0.2, g + 5.0 - DOWN, 0.2, 0x5a4030)
		bar(Vector3(s, g + 3.92, -0.2), Vector3(s, g + 5.08, -7.3), 0.12, 0.2, 0x4a3426)
	for z in [-0.6, -6.8]:
		box(31.8, g + (3.8 if z > -1.0 else 4.8), z - 0.08, 18.8, 0.2, 0.16, 0x4a3426)
	pieces += 1
	quad(Vector3(31.6, g + 4.05, -0.1), Vector3(50.8, g + 4.05, -0.1), Vector3(50.8, g + 5.25, -7.4), Vector3(31.6, g + 5.25, -7.4), 0x5a4636, Vector3(0, 1, 0.16))
	quad(Vector3(31.6, g + 4.0, -0.1), Vector3(50.8, g + 4.0, -0.1), Vector3(50.8, g + 5.2, -7.4), Vector3(31.6, g + 5.2, -7.4), 0x7a5a40, Vector3(0, -1, -0.16))
	# what is kept under it: stacked crates
	for q in [[33.4, -5.6, 2], [35.0, -5.6, 3], [36.6, -5.6, 2], [46.2, -5.4, 3], [47.8, -5.4, 1]]:
		for k in range(int(q[2])):
			box(q[0], g + k * 0.78, q[1] - 0.6, 1.2, 0.74, 1.2, 0x3a6a8a if k % 2 == 0 else 0x4a7a9a)
		_solid_f(q[0], q[0] + 1.2, -q[1] - 0.6, -q[1] + 0.6, g, g + 0.78 * float(q[2]))
	home()
	for s in [32.2, 41.2, 50.2]:
		for d in [0.7, 6.9]:
			var p := P(s, d)
			solid(Vector3(p.x, g + 2.0, p.y), Vector3(0.25, 4.5, 0.25))

func _tanks() -> void:
	_front()
	for q in [[53.6, 3.3], [57.4, 3.3], [53.6, 7.2], [57.4, 7.2]]:
		var p := P(q[0], q[1])
		var g := gr(p)
		drum(Vector3(q[0], g, -q[1]), 1.6, 1.6, 6.4, "acero", 18)
		drum(Vector3(q[0], g + 6.4, -q[1]), 1.6, 0.3, 0.8, "acero", 18)
		drum(Vector3(q[0], g - 0.2, -q[1]), 1.68, 1.68, 0.5, 0x8d99ae, 18)
	home()
	for q in [[53.6, 3.3], [57.4, 3.3], [53.6, 7.2], [57.4, 7.2]]:
		var p := P(q[0], q[1])
		solid(Vector3(p.x, gr(p) + 3.0, p.y), Vector3(2.9, 6.4, 2.9), atan2(-U.y, U.x))
	# the low works: a grey building with its machines on the roof and a pipe to the tanks
	var ring: Array = [P(61.0, 1.6), P(86.0, 1.6), P(86.0, 10.0), P(61.0, 10.0)]
	var top := gr(P(61.0, 5.0)) + 3.6
	_ring(ring, top, 0xc8c8c2)
	flat(PackedVector2Array(ring), top, 0x9a9ea2)
	_mass(ring, top)
	_front()
	for q in [[64.0, 4.0, 2.2, 1.4], [70.0, 6.5, 3.0, 1.1], [77.5, 4.5, 1.6, 1.8], [82.0, 7.0, 2.4, 1.0]]:
		box(q[0], top, -q[1] - q[2] / 2.0, q[2], q[3], q[2] * 0.7, 0x7a8086)
	bar(Vector3(59.0, top + 0.5, -5.2), Vector3(64.0, top + 0.5, -5.2), 0.18, 0.18, "acero")
	bar(Vector3(59.0, top + 0.5, -5.2), Vector3(59.0, top + 2.4, -5.2), 0.18, 0.18, "acero")
	home()

func _flags() -> void:
	_front()
	var cols: Array = [[0xc8102e, 0xf1bf00, 0xc8102e], [0xf4f4f0, 0xf4f4f0, 0xf4f4f0], [0x1a3a9a, 0x1a3a9a, 0x1a3a9a]]
	for i in range(3):
		var s := 28.4 + i * 1.5
		var g := gr(P(s, 1.7))
		drum(Vector3(s, g, -1.7), 0.06, 0.04, 7.2, 0xd8dade, 8)
		ball(Vector3(s, g + 7.25, -1.7), 0.07, 0xd8b020, 1.0, 6, 4)
		var c: Array = cols[i]
		for k in range(3):
			box(s + 0.05, g + 6.0 + [0.75, 0.25, 0.0][k], -1.71, 1.5, [0.25, 0.5, 0.25][k], 0.02, int(c[k]))
		if i >= 1:                                                              # (a ring on the mill's own white one, cobalt, and on the blue one, gold)
			var dots := 10 if i == 1 else 8
			var dot := 0.09 if i == 1 else 0.06
			for j in range(dots):
				cbox(Vector3(s + 0.8 + cos(j * TAU / dots) * 0.3, g + 6.5 + sin(j * TAU / dots) * 0.3, -1.69), Vector3(dot, dot, 0.03), BLUE if i == 1 else 0xf1bf00)
	home()

# ---------------- the hedges, the pines of the road, the olives ----------------
func _greens() -> void:
	_front()
	for q in [[10.0, 14.9, 3.0, 4.2], [13.9, 14.9, 0.9, 3.0], [27.1, 30.9, 1.0, 2.2]]:      # hedges: from s, to s, from d out, to d out
		var g := gr(P((q[0] + q[1]) / 2.0, -(q[2] + q[3]) / 2.0))
		box(q[0] + 0.1, g - 0.3, q[2] + 0.1, q[1] - q[0] - 0.2, 1.2, q[3] - q[2] - 0.2, 0x2f5228)
		var long_s: bool = (q[1] - q[0]) >= (q[3] - q[2])
		var run: float = (q[1] - q[0]) if long_s else (q[3] - q[2])
		var wide: float = (q[3] - q[2]) if long_s else (q[1] - q[0])
		var n := maxi(1, int(round(run / (wide * 0.8))))
		for k in range(n):
			var t := (k + 0.5) / n
			var cx: float = (q[0] + run * t) if long_s else (q[0] + q[1]) / 2.0
			var cz: float = (q[2] + q[3]) / 2.0 if long_s else (q[2] + run * t)
			ball(Vector3(cx, g + 0.62 + 0.05 * sin(k * 2.3), cz), wide * 0.62, 0x35602c if k % 2 == 0 else 0x3d6a30, 1.1, 8, 5)
		_solid_f(q[0], q[1], -q[3], -q[2], g - 0.3, g + 1.1)
	home()
	for q in [[31.3, 4.4, 11.0, 0.05], [57.0, 5.2, 10.0, -0.06], [79.5, 5.0, 10.5, 0.04], [105.5, 5.6, 11.0, 0.07], [108.4, 4.8, 9.5, -0.05], [111.2, 5.6, 10.5, 0.03], [136.5, 5.2, 11.0, -0.04], [158.0, 6.0, 9.5, 0.05]]:
		_pine(P(q[0], -q[1]), q[2], q[3])
	_olive(P(42.2, -3.0), 5.8)
	_clutter()
	var before := OA.lerp(OB, 0.74) + Vector2(0.8078, 0.5895) * 3.4               # the olive before the offices
	_olive(before, 4.2)
	for k in range(3):                                                           # and the bushes by their door
		var p := OA.lerp(OB, 0.6 + 0.035 * k) + Vector2(0.8078, 0.5895) * 1.1
		ball(Vector3(p.x, gr(p) + 0.5, p.y), 0.55, 0x4a7a3a, 0.9, 8, 5)

## What stands about the yard: totes of oil in their cages, stacks of pallets, blue drums.
func _clutter() -> void:
	for q in [[271.2, -563.6, 0.3], [272.5, -562.5, 0.3], [270.0, -564.9, 0.25], [286.6, -584.6, 1.0], [287.5, -586.1, 1.0]]:
		_tote(Vector2(q[0], q[1]), q[2])
	for q in [[289.6, -590.5, 5, 1.0], [290.5, -592.1, 7, 1.0], [291.5, -593.8, 4, 1.05], [263.2, -568.9, 6, 0.3]]:
		_pallets(Vector2(q[0], q[1]), int(q[2]), q[3])
	for k in range(7):
		var p := P(52.0 + (k % 4) * 0.72, 10.6 + (k / 4) * 0.72)
		drum(Vector3(p.x, gr(p), p.y), 0.3, 0.3, 0.9, 0x2a5a9a, 10)
		drum(Vector3(p.x, gr(p) + 0.9, p.y), 0.31, 0.31, 0.03, 0x1f4a86, 10)
	var dm := P(53.1, 11.0)
	solid(Vector3(dm.x, gr(dm) + 0.45, dm.y), Vector3(3.0, 0.9, 1.5), atan2(-U.y, U.x))

## a tote of a thousand litres: a white tank in its cage of steel, on its pallet
func _tote(at: Vector2, turn: float) -> void:
	var g := gr(at)
	var keep := _xf
	_xf = Transform3D(Basis(Vector3.UP, turn), Vector3(at.x, g, at.y))
	box(-0.6, 0.0, -0.5, 1.2, 0.14, 1.0, 0x8a6a48)
	box(-0.56, 0.14, -0.46, 1.12, 1.0, 0.92, 0xe8e6da)
	for x in [-0.59, 0.56]:
		for z in [-0.49, 0.46]:
			box(x, 0.14, z, 0.03, 1.02, 0.03, STEEL)
	for y in [0.4, 0.75, 1.14]:
		box(-0.59, y, -0.49, 1.18, 0.025, 0.025, STEEL)
		box(-0.59, y, 0.465, 1.18, 0.025, 0.025, STEEL)
		box(-0.59, y, -0.49, 0.025, 0.025, 0.98, STEEL)
		box(0.565, y, -0.49, 0.025, 0.025, 0.98, STEEL)
	drum(Vector3(0, 1.14, 0), 0.12, 0.12, 0.06, 0x26262a, 8)
	_xf = keep
	solid(Vector3(at.x, g + 0.6, at.y), Vector3(1.2, 1.2, 1.0), turn)

## a stack of pallets
func _pallets(at: Vector2, n: int, turn: float) -> void:
	var g := gr(at)
	var keep := _xf
	_xf = Transform3D(Basis(Vector3.UP, turn), Vector3(at.x, g, at.y))
	for k in range(n):
		var y := k * 0.15
		box(-0.6, y + 0.1, -0.4, 1.2, 0.03, 0.8, 0xb08a5a)
		for z in [-0.4, -0.05, 0.3]:
			box(-0.6, y, z, 1.2, 0.1, 0.1, 0x9a7648)
	_xf = keep
	solid(Vector3(at.x, g + n * 0.075, at.y), Vector3(1.2, n * 0.15, 0.8), turn)

## a stone pine of the road: a leaning trunk that forks, a flat dark crown
func _pine(at: Vector2, tall: float, lean: float) -> void:
	var g := gr(at)
	var foot := Vector3(at.x, g - 0.3, at.y)
	var fork := foot + Vector3(lean * tall * 0.5, tall * 0.5, lean * tall * 0.3)
	bar(foot, fork, 0.42, 0.42, 0x7a6450)
	var head := fork + Vector3(lean * tall * 0.3, tall * 0.34, 0.0)
	for q in [[-0.5, 0.2], [0.6, -0.3], [0.0, 0.5]]:
		bar(fork, head + Vector3(q[0] * 1.8, -0.4, q[1] * 1.8), 0.2, 0.2, 0x7a6450)
	for q in [[0.0, 0.0, 3.3, 1.0], [1.7, 0.9, 2.3, 0.85], [-1.8, -0.6, 2.5, 0.9], [0.4, -1.7, 2.2, 0.8], [-0.6, 1.8, 2.1, 0.8]]:
		ball(head + Vector3(q[0], 0.3, q[1]), q[2], 0x2f5d3a, 0.55 * q[3], 9, 5)
	solid(Vector3(at.x, g + 1.5, at.y), Vector3(0.45, 3.4, 0.45))
	yard.append(at)

## an old olive: a short thick trunk, a wide grey-green head
func _olive(at: Vector2, tall: float) -> void:
	var g := gr(at)
	drum(Vector3(at.x, g - 0.3, at.y), 0.34, 0.2, tall * 0.42, 0x6a5a48, 8)
	for q in [[0.0, 0.0, 1.0], [0.9, 0.4, 0.75], [-0.8, 0.5, 0.7], [0.2, -0.9, 0.72], [-0.5, -0.6, 0.6]]:
		ball(Vector3(at.x + q[0] * tall * 0.3, g + tall * (0.62 + 0.08 * q[2]), at.y + q[1] * tall * 0.3), tall * 0.3 * q[2], 0x7d8a6a, 0.8, 9, 5)
	solid(Vector3(at.x, g + 1.0, at.y), Vector3(0.5, 2.4, 0.5))
	yard.append(at)

# ---------------- the saffron, and what the map is told ----------------
## A saffron flower in a little pot of clay, in the nook between the low works and the small building, behind the
## long wall (the user, 21 November 2026: hide saffron in special places). The flower is the game's to take away; the
## pot stays.
func _saffron(at: Vector2) -> void:
	var g := gr(at) + 0.04
	drum(Vector3(at.x, g, at.y), 0.1, 0.14, 0.16, 0xb0623a, 10)
	drum(Vector3(at.x, g + 0.15, at.y), 0.12, 0.12, 0.012, 0x5a3a26, 10)
	var flower := Node3D.new()
	flower.add_child(Parts.part("cyl", 0x5f9c4a, Vector3(0, 0.3, 0), Vector3(0.03, 0.6, 0.03)))
	for k in range(5):
		flower.add_child(Parts.part("ball", 0x9b5de5, Vector3(cos(k * 1.257) * 0.12, 0.66, sin(k * 1.257) * 0.12), Vector3(0.11, 0.2, 0.11)))
	flower.add_child(Parts.part("ball", 0xe63946, Vector3(0, 0.74, 0), Vector3(0.05, 0.13, 0.05)))
	flower.position = Vector3(at.x, g + 0.12, at.y)
	add_child(flower)
	saffron_spot = at
	var game = W.get_parent()                           # (the game: the world is its child)
	if game != null and game.get("flowers") != null:
		(game.flowers as Array).append({"node": flower, "p": saffron_spot, "id": "almazara", "hidden": true})      # (hidden: Sistemas keeps count of these)

func _tell_map() -> void:
	for outline: PackedVector2Array in outlines:
		MapData.outlines.append(outline)
		if not MapData._wall_grid.is_empty():
			for i in range(outline.size()):
				var a: Vector2 = outline[i]
				var c: Vector2 = outline[(i + 1) % outline.size()]
				MapData._grid_add(MapData._wall_grid, a.min(c), a.max(c), [a, c])
