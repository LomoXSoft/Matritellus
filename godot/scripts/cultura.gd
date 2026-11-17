extends "res://scripts/obra.gd"
## The block of public buildings between the Calle de los Arcos, the Calle de Argentina and the Callejón Pando (the user,
## 17 November 2026: "son varios edificios públicos pegados que ocupan una manzana entera: La casa de la cultura (en
## rojo), la biblioteca pública (en medio) y la escuela de música y danza (en frente de Centro Salud). Tiene bastantes
## detalles así que tómatelo con calma"). From Catastro (parcel 4590001, nine parts), the orthophoto and Street View
## (November 2024 up the Arcos and along Argentina, October 2019 and March 2013 along the Callejón Pando).
## Measured: referencias/cultura/LEEME.md.
##
##   - the Casa Grande: an old house of two floors in "aparejo toledano" (brick framing panels of rubble), a foot
##     of granite slabs; on the Arcos four tall barred windows under arches of brick, the doorway of granite with its
##     cornice and its coat of arms over it, four little windows above with their iron cages; on Argentina the same,
##     and a little door under an arch of brick; a brick cornice under the tiles; its notice board, the panel by it.
##     The arch over the Callejón Pando where it comes out on the Arcos, with its little tower;
##   - the library, in the middle: two floors, brick with paler panels of stone, a band of brick teeth between them,
##     barred windows with crests of scrolls below, its door on Argentina under a little tiled roof, the ramp before it;
##   - the school of music and dance, east: three floors, then two, brick with piers of white stone, its glazed front
##     and door to the car park opposite the health centre, the curved end of its hall, steps up to its side door.
##
## Frame: the map's own (x east, z south), y = 0 the pavement before the Casa Grande's doorway.

const READY := true                 # (the bake leaves Catastro's parcel of it to this script: tools/cultura/enganche.py)

# the Casa Grande: its corners (north-west, north-east, south-east, south-west), the bend of its north front
const CC: Array = [Vector2(118.40, 109.21), Vector2(147.93, 115.54), Vector2(147.46, 145.08), Vector2(117.22, 139.04)]
const CC_BEND := Vector2(142.44, 113.95)
# the library: north-west, north-east, south-east, south-west
const LIB: Array = [Vector2(147.93, 115.54), Vector2(160.62, 119.22), Vector2(159.48, 147.68), Vector2(147.46, 145.08)]
# the music school: its tall north block, its block on the car park, its south block with the hall's curved end
const MUS_T: Array = [Vector2(160.62, 119.22), Vector2(168.34, 121.45), Vector2(167.67, 138.50), Vector2(159.76, 140.45)]
const MUS_E: Array = [Vector2(168.34, 121.45), Vector2(175.76, 123.60), Vector2(175.24, 136.64), Vector2(174.13, 136.91), Vector2(167.67, 138.50)]
const CURVE: Array = [Vector2(174.13, 136.91), Vector2(174.53, 138.74), Vector2(174.66, 139.58), Vector2(174.84, 141.12), Vector2(174.95, 142.51),
	Vector2(174.95, 144.23), Vector2(174.88, 145.60), Vector2(174.65, 147.35), Vector2(174.29, 149.20), Vector2(173.84, 150.82), Vector2(173.46, 152.05)]
const MUS_S_REST: Array = [Vector2(167.22, 150.10), Vector2(159.48, 147.68), Vector2(159.76, 140.45), Vector2(167.67, 138.50)]
# the arch over the Callejón Pando: its front on the Arcos, from the Casa Grande's corner south to the next house
const ARCH_N := Vector2(117.22, 139.04)
const ARCH_S := Vector2(117.03, 143.85)
const ARCH_DEEP := 3.4
# the library's entrance (the user, 17 Nov, with two pictures of it: "La entrada de la biblioteca no se parece en nada"):
# its front on Argentina is set back between a block of it that stands out to the street at the west and the music
# school's tall block at the east; that block's corner along the front from the library's north-west corner, and how
# far the front is set back (Street View n4 and n5_w, the orthophoto)
const LIB_NE := 5.2
const LIB_HONDO := 2.8

const CC_EAVES := 7.7
const LIB_EAVES := 8.5
const MT_EAVES := 12.0                # (its street stands two metres over the Casa Grande's doorway)
const ME_EAVES := 9.3
const TOWER_EAVES := 9.8
const PLINTH := 1.15                # the granite foot's height
const HIERRO := 0x1d1e20
const WOOD := 0x4a3426

var portal: Vector2                 # before the Casa Grande's doorway, the library's door, the music school's door (on the map)
var door_lib: Vector2
var door_mus: Vector2
var openings := 0                   # (the self-test: windows and doors)
var arch_mid: Vector2               # the passage under the arch (the self-test)

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"rubble":           # the rubble of the Casa Grande's panels: golden, irregular
			m = Tex.mat("stone_wall", Color(1.16, 1.03, 0.86))
		"piedra_gris":      # the library's paler, greyer panels
			m = Tex.mat("stone_wall", Color(1.05, 1.02, 0.96))
		"piedra_blanca":    # the music school's panels of white stone
			m = Tex.mat("stone_wall_02", Color(1.33, 1.32, 1.3))
		"ladrillo_claro":   # the music school's light brown brick of these years, to the car park
			m = Tex.mat("brick_wall_09", Color(1.16, 1.03, 0.88))
		"granito":
			m = Tex.mat("granite_tile_04@1.2", Color(0.7, 0.7, 0.72))
		"cristal":
			var gm := StandardMaterial3D.new()
			gm.albedo_color = Color(0.16, 0.21, 0.26)
			gm.roughness = 0.2
			gm.metallic_specular = 0.6
			m = gm
		"escudo":           # the coat of arms' stone, carved
			m = Tex.mat("granular_concrete", Color(0.9, 0.86, 0.78))
		"caliza":           # the doorway's white stone, a little cream: its lintel, its cornice, the coat of arms' frame
			m = Tex.mat("white_plaster_02", Color(1.0, 0.9, 0.74))
		"caliza_gris":      # the same stone gone grey (every other voussoir, a moulding)
			m = Tex.mat("white_plaster_02", Color(0.9, 0.83, 0.72))
		"relieve":          # the carving itself (tools/cultura/escudo.py): its picture and its normal map
			var rm := StandardMaterial3D.new()
			rm.albedo_texture = load("res://assets/cultura/escudo.png")
			rm.normal_enabled = true
			rm.normal_texture = load("res://assets/cultura/escudo_n.png")
			rm.normal_scale = 1.2
			rm.roughness = 0.92
			m = rm
		"tablon":           # the notice board's sheet: pale paper, a red heading, lines of print and two little pictures
			var img := Image.create(40, 56, false, Image.FORMAT_RGB8)
			img.fill(Parts.col(0xf1ece0))
			img.fill_rect(Rect2i(3, 3, 34, 6), Parts.col(0x9a2a2a))
			for i in range(3):
				img.fill_rect(Rect2i(8 + i * 8, 5, 6, 2), Parts.col(0xf1ece0))
			for j in range(14):
				var row := 13 + j * 3
				if row > 52:
					break
				var wide := 30 - (j * 7) % 11
				if j >= 3 and j <= 6:
					wide = 16
				img.fill_rect(Rect2i(4, row, wide, 1), Parts.col(0x5a5650))
			img.fill_rect(Rect2i(23, 22, 13, 10), Parts.col(0x5a7a9a))
			img.fill_rect(Rect2i(25, 27, 9, 4), Parts.col(0x8aa06a))
			img.fill_rect(Rect2i(4, 47, 12, 6), Parts.col(0xc89a3a))
			var pm := StandardMaterial3D.new()
			pm.albedo_texture = ImageTexture.create_from_image(img)
			pm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			m = pm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	var front: Vector2 = CC[0].lerp(CC[3], 15.1 / CC[0].distance_to(CC[3]))
	portal = front + _out(CC[0], CC[3]) * 1.2
	level = MapData.height(portal)
	transform = Transform3D(Basis.IDENTITY, Vector3(0.0, level, 0.0))
	W.add_child(self)
	_casa_cultura()
	_arco()
	_biblioteca()
	_musica()
	_roofs()
	home()
	_commit()
	for poly in [CC, _lib_real(), MUS_T, MUS_E, _mus_s()]:
		for part in Geometry2D.decompose_polygon_in_convex(PackedVector2Array(poly)):
			var pts: Array = []
			for q: Vector2 in part:
				pts.append(q)
			_prism(pts, -2.0, 7.0)

# ---------------- helpers ----------------
## the outward normal of a front built from a to b (obra.face's +z)
func _out(a: Vector2, b: Vector2) -> Vector2:
	var d := (b - a).normalized()
	return Vector2(-d.y, d.x)

## the ground (this frame's y) at a spot of the front a..b, s along it, a little out
func _gf(a: Vector2, b: Vector2, s: float) -> float:
	var p: Vector2 = a.lerp(b, s / a.distance_to(b)) + _out(a, b) * 0.4
	return ground(p.x, p.y)

func _mus_s() -> Array:
	return CURVE + MUS_S_REST

## Aparejo toledano: panels of rubble framed by brick, in rows, clear of the openings (each widened by `margin`)
func _cajones(x0: float, x1: float, y0: float, y1: float, holes: Array, w := 1.3, h := 0.85, gap := 0.3, margin := 0.35) -> Array:
	var out: Array = []
	var y := y0 + gap
	var row := 0
	while y + h <= y1 - gap * 0.5:
		var x := x0 + gap + (0.0 if row % 2 == 0 else (w + gap) * 0.5)
		while x + w <= x1 - gap:
			var r := Rect2(x, y, w, h)
			var clear := true
			for hr: Rect2 in holes:
				if r.intersects(hr.grow(margin)):
					clear = false
					break
			if clear:
				out.append(r)
			x += w + gap
		y += h + gap
		row += 1
	return out

## upright piers of stone up a wall (the library's and the music school's), clear of the openings
func _pilares(x0: float, x1: float, y0: float, y1: float, holes: Array, every := 3.2, w := 0.75) -> Array:
	var out: Array = []
	var x := x0 + 0.35
	while x + w <= x1 - 0.2:
		var y := y0 + 0.25
		while y + 0.6 <= y1 - 0.2:
			var r := Rect2(x, y, w, 0.6)
			var clear := true
			for hr: Rect2 in holes:
				if r.intersects(hr.grow(0.15)):
					clear = false
					break
			if clear:
				out.append(r)
			y += 0.78
		x += every
	return out

## The granite foot along a front. Its top runs straight from one end of the front to the other, `tall` over the street
## at each end, so that it stands as high on both sides of a door (the user, 17 Nov: "Debería estar igualada"); it is
## cut where a door or a window comes down into it, and under a window it goes on up to the window's sill.
func _foot(L: float, g0: float, g1: float, doors: Array, tall := PLINTH) -> void:
	var holes: Array = doors.duplicate()
	holes.sort_custom(func(p: Rect2, q: Rect2) -> bool: return p.position.x < q.position.x)
	var cuts: Array = [0.0]
	for d: Rect2 in holes:
		cuts.append(d.position.x)
		cuts.append(d.end.x)
	cuts.append(L)
	var gy: float = minf(g0, g1) - 0.6
	for i in range(0, cuts.size() - 1, 2):
		var x0: float = clampf(cuts[i], 0.0, L)
		var x1: float = clampf(cuts[i + 1], 0.0, L)
		if x1 - x0 < 0.05:
			continue
		var t0 := lerpf(g0, g1, x0 / L) + tall
		var t1 := lerpf(g0, g1, x1 / L) + tall
		slab(PackedVector2Array([Vector2(x0, gy), Vector2(x1, gy), Vector2(x1, t1), Vector2(x0, t0)]), 0.045, 0.045, "granito")
		slab(PackedVector2Array([Vector2(x0, t0), Vector2(x1, t1), Vector2(x1, t1 + 0.05), Vector2(x0, t0 + 0.05)]), 0.07, 0.07, "granito")
	for d: Rect2 in holes:                                                          # (under a window: up to its sill)
		var street := lerpf(g0, g1, (d.position.x + d.size.x / 2.0) / L)
		if d.position.y - street > 0.1:
			box(d.position.x, gy, 0.0, d.size.x, d.position.y - gy, 0.045, "granito")
		var t := street + tall                                                      # (over a little window in it: up to its top)
		if d.end.y < t - 0.05:
			box(d.position.x, d.end.y, 0.0, d.size.x, t - d.end.y, 0.045, "granito")
			box(d.position.x, t, 0.0, d.size.x, 0.05, 0.07, "granito")

## A tall window of the ground floor in its hole, as on the Arcos (Street View straight at it): dark frame and glass,
## the reveal plastered white, an iron grille standing out in front of it in a cage, a granite sill; over it a flat
## lintel of bricks on end fanning out, flush with the wall and of its colour (the aparejo's "dintel a sardinel").
func _ventana_baja(r: Rect2, arch := true) -> void:
	window(r, 0x2a2420, 0x1f2a33, 2)
	for q in [Rect2(r.position.x, r.position.y, 0.025, r.size.y), Rect2(r.end.x - 0.025, r.position.y, 0.025, r.size.y), Rect2(r.position.x, r.end.y - 0.025, r.size.x, 0.025)]:
		box(q.position.x, q.position.y, -DEEP, q.size.x, q.size.y, DEEP - 0.002, 0xe6e0d4)
	grille(r, 0.12, HIERRO)
	box(r.position.x - 0.06, r.position.y - 0.06, 0.0, r.size.x + 0.12, 0.06, 0.1, "granito")
	if arch:
		_dintel_ladrillo(r.position.x - 0.08, r.end.x + 0.08, r.end.y + 0.02)
	openings += 1

## a flat lintel of upright bricks over an opening, from x0 to x1 at its foot (y), `tall` high and a little wider at
## its top: each brick a little proud of its pale joints, the wall's red in three shades
func _dintel_ladrillo(x0: float, x1: float, y: float, tall := 0.5) -> void:
	var flare := 0.11
	slab(PackedVector2Array([Vector2(x0, y), Vector2(x1, y), Vector2(x1 + flare, y + tall), Vector2(x0 - flare, y + tall)]), 0.006, 0.006, 0xc8b49a)
	var n := maxi(8, int((x1 - x0) / 0.06))
	var cols := [0x7e442d, 0x88492f, 0x733d28]
	for i in range(n):
		var b0 := lerpf(x0, x1, float(i) / n)
		var b1 := lerpf(x0, x1, float(i + 1) / n)
		var t0 := lerpf(x0 - flare, x1 + flare, float(i) / n)
		var t1 := lerpf(x0 - flare, x1 + flare, float(i + 1) / n)
		slab(PackedVector2Array([Vector2(b0 + 0.006, y + 0.006), Vector2(b1 - 0.006, y + 0.006), Vector2(t1 - 0.006, y + tall - 0.006), Vector2(t0 + 0.006, y + tall - 0.006)]),
			0.014, 0.008, cols[i % 3])

## a little window of the floor above: a frame of pale stone, its iron cage standing out
func _ventana_alta(r: Rect2, cage := true) -> void:
	window(r, 0x3a2a1e, 0x1f2a33, 1)
	stone_frame(r, 0.11, 0.035, 0xd8ccb4)
	if cage:
		grille(r, 0.2, HIERRO)
	openings += 1

## a window of the music school: dark frame and glass, its grille standing out a little, a granite sill
func _ventana_reja(r: Rect2) -> void:
	window(r, 0x2b2d31, 0x1f2a33, 1)
	grille(r, 0.1, HIERRO)
	box(r.position.x - 0.1, r.position.y - 0.09, 0.0, r.size.x + 0.2, 0.09, 0.18, "granito")
	openings += 1

## a window with a crest of iron scrolls over its grille (the library's), its blind of brown slats `blind` of the way down
func _ventana_volutas(r: Rect2, blind := 0.0) -> void:
	window(r, 0x3a2a1e, 0x1f2a33, 2)
	if blind > 0.0:
		var bh := r.size.y * blind
		box(r.position.x + 0.03, r.end.y - bh, -0.22, r.size.x - 0.06, bh, 0.02, 0x6a4a34)
		for k in range(int(bh / 0.1)):
			box(r.position.x + 0.03, r.end.y - 0.1 * (k + 1), -0.198, r.size.x - 0.06, 0.012, 0.004, 0x4e3424)
	grille(r, 0.15, HIERRO)
	var cx := r.position.x + r.size.x / 2.0
	var y := r.end.y + 0.06
	for s in [-1.0, 1.0]:                                                           # two scrolls and a spike
		for k in range(6):
			var a0 := PI * k / 6.0
			var a1 := PI * (k + 1) / 6.0
			var c := Vector3(cx + s * 0.2, y + 0.12, 0.15)
			bar(c + Vector3(cos(a0) * 0.12 * s, sin(a0) * 0.12, 0), c + Vector3(cos(a1) * 0.12 * s, sin(a1) * 0.12, 0), 0.018, 0.018, HIERRO)
	bar(Vector3(cx, y, 0.15), Vector3(cx, y + 0.38, 0.15), 0.02, 0.02, HIERRO)
	openings += 1

# ---------------- the Casa Grande ----------------
func _casa_cultura() -> void:
	# the Arcos front: four tall barred windows, the doorway in the middle; four little windows above
	var a: Vector2 = CC[0]
	var b: Vector2 = CC[3]
	var L := face(a, b, 0.0)
	var g0 := _gf(a, b, 0.0)
	var g1 := _gf(a, b, L)
	var low: Array = []
	var high: Array = []
	var lintels: Array = []
	for s in [4.5, 10.3, 19.9, 25.6]:                                              # (1.24 by 2.1, down into the plinth: Street View a3)
		var g := _gf(a, b, s)
		low.append(Rect2(s - 0.62, g + 0.3, 1.24, 2.1))
		lintels.append(Rect2(s - 0.82, g + 2.4, 1.64, 0.55))
		high.append(Rect2(s - 0.55, 4.55, 1.1, 0.85))
	var gp := _gf(a, b, 15.1)
	var door := Rect2(14.3, gp, 1.6, 2.5)
	var holes: Array = low + high + [door]
	masonry(0.0, L, -2.5, CC_EAVES, holes, _cajones(0.0, L, PLINTH, CC_EAVES - 0.5, holes + lintels + [Rect2(13.5, gp, 3.2, 5.2)], 1.5, 0.95, 0.3), "brick", "rubble")
	_foot(L, g0, g1, low + [door])
	for r: Rect2 in low:
		_ventana_baja(r)
	for r: Rect2 in high:
		_ventana_alta(r)
	_portada(door)
	cornice(-0.1, L + 0.1, CC_EAVES, true)
	# its notice board, red, by the doorway; the panel of the house's history at the north end
	_tablon(12.6, gp)
	_panel(1.6, _gf(a, b, 1.6))
	home()
	# the north front, in two lengths (its bend): little door under an arch of brick, windows below and above
	for f in [[CC[1], CC_BEND, [[2.6, "door"]]], [CC_BEND, CC[0], [[3.5, "low"], [9.3, "low"], [15.2, "low"], [21.0, "low"]]]]:
		var fa: Vector2 = f[0]
		var fb: Vector2 = f[1]
		var fl := face(fa, fb, 0.0)
		var lows: Array = []
		var highs: Array = []
		var doors: Array = []
		for it in f[2]:
			var s: float = it[0]
			var g := _gf(fa, fb, s)
			if it[1] == "door":
				doors.append(Rect2(s - 0.55, g, 1.1, 2.2))
			else:
				lows.append(Rect2(s - 0.65, g + 1.35, 1.3, 1.6))                    # (over the plinth, as Street View n5 has them)
			highs.append(Rect2(s - 0.45, 4.6, 0.9, 0.8))
		var fh: Array = lows + highs + doors
		var over: Array = []
		for r: Rect2 in lows:
			over.append(Rect2(r.position.x - 0.2, r.end.y, r.size.x + 0.4, 0.55))
		masonry(0.0, fl, -2.5, CC_EAVES, fh, _cajones(0.0, fl, PLINTH, CC_EAVES - 0.5, fh + over, 1.5, 0.95, 0.3), "brick", "rubble")
		_foot(fl, _gf(fa, fb, 0.0), _gf(fa, fb, fl), doors)
		for r: Rect2 in lows:
			_ventana_baja(r)
		for r: Rect2 in highs:
			_ventana_alta(r, false)
		for r: Rect2 in doors:                                                     # the little door: old boards, an arch of brick
			box(r.position.x, r.position.y, -0.22, r.size.x, r.size.y, 0.06, "wood")
			for k in range(9):
				var t := float(k) / 8.0
				tbox(Transform3D(Basis(Vector3.BACK, (0.5 - t) * 1.0) * Basis.from_scale(Vector3(0.12, 0.42, 0.03)), Vector3(lerpf(r.position.x - 0.3, r.end.x + 0.3, t), r.end.y + 0.32 + sin(t * PI) * 0.18, 0.012)), "brick")
			openings += 1
		cornice(-0.1, fl + 0.1, CC_EAVES, true)
		home()
	# the south front on the Callejón Pando: brick with fewer panels, two little windows high up
	var sa: Vector2 = CC[3]
	var sb: Vector2 = CC[2]
	var sl := face(sa, sb, 0.0)
	var sh: Array = [Rect2(9.0, 4.7, 0.8, 0.7), Rect2(21.5, 4.7, 0.8, 0.7)]
	masonry(0.0, sl, -2.5, CC_EAVES, sh, _cajones(0.0, sl, PLINTH, CC_EAVES - 0.5, sh, 1.6, 0.9, 0.55), "brick", "rubble")
	_foot(sl, _gf(sa, sb, 0.0), _gf(sa, sb, sl), [], 1.0)
	for r: Rect2 in sh:
		_ventana_alta(r, false)
	box(18.0, 2.6, 0.0, 0.45, 0.3, 0.14, 0xd8262a)                                    # (an alarm's red box)
	cornice(-0.1, sl + 0.1, CC_EAVES, true)
	home()

## The doorway, as the town hall's photographs show it (referencias/cultura/): jambs of granite blocks, long and short
## by turns; a flat lintel of white voussoirs fanning out; a moulded cornice over it; and on the cornice the family's
## coat of arms carved in a block of the same white stone, in its moulded frame (the carving: tools/cultura/escudo.py).
## The old double door, dark green, sits back in a reveal lined with stone.
func _portada(r: Rect2) -> void:
	var x0 := r.position.x
	var x1 := r.end.x
	var y0 := r.position.y
	var y1 := r.end.y
	var cx := (x0 + x1) / 2.0
	# the jambs: blocks 0.42 and 0.55 wide by turns, 0.1 proud, fine joints between them
	var y := y0 - 0.05
	var k := 0
	while y < y1 - 0.01:
		var h := minf(0.46, y1 - y)
		var w := 0.42 if k % 2 == 0 else 0.55
		box(x0 - w, y, 0.0, w, h, 0.085, 0x8a8a86)                                      # (the joint's mortar behind each)
		box(x0 - w, y + 0.008, 0.0, w - 0.008, h - 0.016, 0.1, "granito")
		box(x1, y, 0.0, 0.97 - w, h, 0.085, 0x8a8a86)
		box(x1 + 0.008, y + 0.008, 0.0, (0.97 - w) - 0.008, h - 0.016, 0.1, "granito")
		y += h
		k += 1
	box(x0, y0, -0.3, 0.035, y1 - y0, 0.3, "granito")                                   # the reveal, lined with stone
	box(x1 - 0.035, y0, -0.3, 0.035, y1 - y0, 0.3, "granito")
	box(x0, y1 - 0.035, -0.3, x1 - x0, 0.035, 0.3, "granito")
	# the lintel: seven voussoirs fanning out from a spot under the door, white and grey by turns
	var lx0 := x0 - 0.5
	var lx1 := x1 + 0.5
	var lh := 0.56
	var hub := Vector2(cx, y1 - 1.25)
	box(lx0, y1, 0.0, lx1 - lx0, lh, 0.09, 0x8a8a86)
	var n := 7
	for i in range(n):
		var xa := lerpf(x0, x1, float(i) / n)
		var xb := lerpf(x0, x1, float(i + 1) / n)
		var grow := (y1 + lh - hub.y) / (y1 - hub.y)                                  # (the joints run out from the hub)
		var ta := hub.x + (xa - hub.x) * grow if i > 0 else lx0
		var tb := hub.x + (xb - hub.x) * grow if i < n - 1 else lx1
		var ba := xa if i > 0 else lx0
		var bb := xb if i < n - 1 else lx1
		var pts := PackedVector2Array([Vector2(ba + 0.006, y1), Vector2(bb - 0.006, y1), Vector2(tb - 0.006, y1 + lh), Vector2(ta + 0.006, y1 + lh)])
		slab(pts, 0.11, 0.03, "caliza" if i % 2 == 0 else "caliza_gris")
	# the cornice: a fillet, two steps, the corona, a cap
	var at := y1 + lh
	for st in [[0.06, 0.14, 0.06], [0.1, 0.2, 0.12], [0.08, 0.25, 0.2], [0.14, 0.31, 0.3], [0.05, 0.27, 0.27]]:
		var half: float = (x1 - x0) / 2.0 + 0.5 + st[2]
		box(cx - half, at, 0.0, half * 2.0, st[0], st[1], "caliza")
		at += st[0]
	# the coat of arms: its frame 1.2 by 1.4 m standing on the cornice, a band and three mouldings stepping in, the
	# carved field (0.71 by 0.91) at the back
	var fr := Rect2(cx - 0.6, at, 1.2, 1.4)
	var field := Rect2(cx - 0.355, at + 0.26, 0.71, 0.91)
	var steps := [[0.0, 0.13], [0.36, 0.105], [0.6, 0.08], [0.82, 0.055]]
	for i in range(steps.size()):
		var f0: float = steps[i][0]
		var f1: float = steps[i + 1][0] if i + 1 < steps.size() else 1.0
		var o := _inset(fr, field, f0)
		var q := _inset(fr, field, f1)
		var z: float = steps[i][1]
		var key: String = "caliza_gris" if i == 1 else "caliza"
		box(o.position.x, o.position.y, 0.0, o.size.x, q.position.y - o.position.y, z, key)       # foot
		box(o.position.x, q.end.y, 0.0, o.size.x, o.end.y - q.end.y, z, key)                      # head
		box(o.position.x, q.position.y, 0.0, q.position.x - o.position.x, q.size.y, z, key)       # sides
		box(q.end.x, q.position.y, 0.0, o.end.x - q.end.x, q.size.y, z, key)
	box(field.position.x, field.position.y, 0.0, field.size.x, field.size.y, 0.03, "caliza")
	var mi := MeshInstance3D.new()                                                     # the carving: a picture with its relief
	var qm := QuadMesh.new()
	qm.size = field.size
	mi.mesh = qm
	mi.material_override = _material("relieve")
	mi.transform = _xf * Transform3D(Basis.IDENTITY, Vector3(cx, field.position.y + field.size.y / 2.0, 0.031))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	for kk in range(2):                                                               # the door, two leaves of boards, dark green
		box(x0 + kk * (x1 - x0) / 2.0 + 0.01, y0, -0.26, (x1 - x0) / 2.0 - 0.02, y1 - y0, 0.08, 0x2c3530)
		for j in range(3):
			box(x0 + kk * (x1 - x0) / 2.0 + 0.1, y0 + 0.25 + j * 0.75, -0.18, (x1 - x0) / 2.0 - 0.2, 0.55, 0.02, 0x232b27)
	box(x0 - 0.5, y0 - 0.02, 0.0, x1 - x0 + 1.0, 0.18, 0.5, "granito")                 # its step
	box(x0, y0 - 0.02, -0.26, x1 - x0, 0.2, 0.26, "granito")                           # (and the threshold inside)
	openings += 1

## the rectangle a fraction t of the way in from the frame `o` to the field `i` (each side on its own)
func _inset(o: Rect2, i: Rect2, t: float) -> Rect2:
	var a := o.position.lerp(i.position, t)
	var b := o.end.lerp(i.end, t)
	return Rect2(a, b - a)

## the notice board by the doorway: two red posts, a red frame, the posters behind glass
func _tablon(x: float, g: float) -> void:
	for dx in [0.0, 0.78]:                                                           # the posts, a knob on each
		box(x + dx, g - 0.2, 0.25, 0.07, 2.32, 0.07, 0xa8242a)
		ball(Vector3(x + dx + 0.035, g + 2.17, 0.285), 0.055, 0xa8242a, 1.0, 8, 5)
	box(x - 0.02, g + 0.9, 0.27, 0.89, 1.17, 0.05, 0xa8242a)
	quad(Vector3(x + 0.05, g + 0.96, 0.33), Vector3(x + 0.80, g + 0.96, 0.33), Vector3(x + 0.80, g + 2.01, 0.33), Vector3(x + 0.05, g + 2.01, 0.33), "tablon", Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	solid_local(Vector3(x + 0.42, g + 1.0, 0.3), Vector3(0.95, 2.0, 0.15))
	_yard_local(Vector3(x + 0.42, 0.0, 0.3))

## the panel of the house's history, a lectern of dark iron at the corner
func _panel(x: float, g: float) -> void:
	for dx in [0.0, 0.62]:
		box(x + dx, g - 0.2, 0.3, 0.05, 1.5, 0.05, 0x3a2a24)
	box(x - 0.04, g + 0.9, 0.29, 0.75, 0.62, 0.04, 0x5a3a30)
	box(x + 0.02, g + 0.96, 0.33, 0.63, 0.5, 0.005, 0xe8dcc4)
	_yard_local(Vector3(x + 0.3, 0.0, 0.3))
	for k in range(6):
		box(x + 0.08, g + 1.36 - k * 0.07, 0.336, 0.5 - (k % 2) * 0.12, 0.02, 0.002, 0x6a5a4a)

## a solid given in the frame being built (obra.solid takes the place's own frame)
func solid_local(mid: Vector3, size: Vector3) -> void:
	var t := _xf * Transform3D(Basis(), mid)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	cs.transform = transform * t
	_solids().add_child(cs)

# ---------------- the arch and its little tower ----------------
## Where the Callejón Pando comes out on the Arcos: a round arch through a little tower of two floors over it, of the
## same aparejo; a balcony over the arch to the Arcos, two little windows to the lane; a ceiling of beams in the
## passage; hipped tiles on top.
func _arco() -> void:
	var w := ARCH_N.distance_to(ARCH_S)
	var inward := -_out(ARCH_N, ARCH_S)
	var spring := 2.6
	var rad := 1.75
	var cx := w / 2.0
	var g := _gf(ARCH_N, ARCH_S, cx)
	arch_mid = ARCH_N.lerp(ARCH_S, 0.5) + inward * (ARCH_DEEP / 2.0)
	var e0: Vector2 = ARCH_N + inward * ARCH_DEEP
	var e1: Vector2 = ARCH_S + inward * ARCH_DEEP
	for f in [[ARCH_N, ARCH_S, true], [e1, e0, false]]:                              # its two faces: to the Arcos, to the lane
		var fa: Vector2 = f[0]
		var fb: Vector2 = f[1]
		face(fa, fb, 0.0)
		var hole := Rect2(cx - rad, g, 2.0 * rad, spring + rad - g)
		var ups: Array = [Rect2(cx - 0.55, 5.2, 1.1, 1.9)] if f[2] else [Rect2(0.75, 7.1, 0.8, 0.9), Rect2(w - 1.55, 7.1, 0.8, 0.9)]
		masonry(0.0, w, -2.0, TOWER_EAVES, [hole] + ups, _cajones(0.0, w, 1.0, TOWER_EAVES - 0.5, [Rect2(cx - rad - 0.4, 0.0, 2.0 * rad + 0.8, spring + rad + 0.6)] + ups, 1.1, 0.8, 0.28), "brick", "rubble")
		spandrels(cx, spring, rad, 0.0, "brick")
		ring(cx, spring, rad, rad + 0.3, 0.0, ARCH_DEEP, "brick", 14)
		_foot(w, g, g, [hole], 0.8)
		if f[2]:                                                                    # the balcony door and its iron balcony
			window(ups[0], 0x3a2a1e, 0x1f2a33, 2)
			box(cx - 0.85, 5.1, 0.0, 1.7, 0.12, 0.55, "granito")
			for k in range(14):
				box(cx - 0.8 + k * 0.123, 5.22, 0.5, 0.02, 0.95, 0.02, HIERRO)
			box(cx - 0.82, 6.15, 0.47, 1.64, 0.04, 0.07, HIERRO)
			for s in [-0.8, 0.78]:
				box(cx + s, 6.15, 0.0, 0.04, 0.04, 0.5, HIERRO)
		else:
			for r: Rect2 in ups:
				_ventana_alta(r, false)
		cornice(-0.1, w + 0.1, TOWER_EAVES, true)
		home()
	# the passage's sides of brick and its ceiling of beams
	for s in [ARCH_N, ARCH_S]:
		var p0: Vector2 = s
		var p1: Vector2 = s + inward * ARCH_DEEP
		if s == ARCH_S:                                                             # (each side facing into the passage)
			face(p0, p1, 0.0)
		else:
			face(p1, p0, 0.0)
		quad(Vector3(0, g - 0.3, -0.01), Vector3(ARCH_DEEP, g - 0.3, -0.01), Vector3(ARCH_DEEP, spring + rad, -0.01), Vector3(0, spring + rad, -0.01), "brick", Vector3(0, 0, 1))
		home()
	var q := PackedVector2Array([ARCH_N, ARCH_S, e1, e0])
	_flat_down(q, spring + rad - 0.15, 0x6a4a34)
	for k in range(6):
		var t := (k + 0.5) / 6.0
		var p0: Vector2 = ARCH_N.lerp(ARCH_S, t)
		var p1: Vector2 = p0 + inward * ARCH_DEEP
		bar(Vector3(p0.x, spring + rad - 0.25, p0.y), Vector3(p1.x, spring + rad - 0.25, p1.y), 0.16, 0.2, 0x5a3a26)
	# its solids: the two piers either side of the way through, and the tower over it
	for s in [0.0, w]:
		var at: Vector2 = ARCH_N.lerp(ARCH_S, s / w) + inward * (ARCH_DEEP / 2.0)
		solid(Vector3(at.x, g + 2.0, at.y), Vector3(ARCH_DEEP, 4.0, 0.6), -atan2(inward.y, inward.x))
	_prism([ARCH_N, ARCH_S, e1, e0], spring + rad, TOWER_EAVES)
	# its roof (in a frame along its front, +z out to the Arcos: the tower stands at z < 0)
	_xf = Transform3D(Basis(Vector3((ARCH_S - ARCH_N).normalized().x, 0, (ARCH_S - ARCH_N).normalized().y), Vector3.UP, Vector3(-inward.x, 0, -inward.y)), Vector3(ARCH_N.x, 0.0, ARCH_N.y))
	_hip(0.0, w, -ARCH_DEEP, 0.0, TOWER_EAVES, 1.3, 0.35)
	home()

## a flat piece facing down at height y (this frame)
func _flat_down(pts: PackedVector2Array, y: float, key) -> void:
	pieces += 1
	var idx := Geometry2D.triangulate_polygon(pts)
	for t in range(0, idx.size(), 3):
		var a := pts[idx[t]]
		var b := pts[idx[t + 1]]
		var c := pts[idx[t + 2]]
		tri(Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y), key, Vector3.DOWN)

# ---------------- the library ----------------
## Two floors of brick with paler panels of stone, a band of brick teeth along the floor between; on Argentina its door
## under a little tiled roof on wooden brackets, the ramp with its rails before it, windows with crests of scrolls
## below and caged ones above; the same round on the lane.
## The library. On Argentina (the user's two pictures of 17 Nov, Street View n4 and n5_w): a block of it stands out to
## the street at the west, big panels of stone, its corner rounded; east of it the front is set back LIB_HONDO, and there
## stands the door, two metres from that corner, under its little roof of tiles on wooden beams, on a landing of granite
## with steps up from the pavement and a railing (the two ramps he said could be left out); windows with grilles crested
## with scrolls and their blinds half down, on both floors; small panels of stone in columns between them; a band of
## upright bricks between the floors and another under the eaves.
func _biblioteca() -> void:
	var D := LIB_HONDO
	var R := 0.22                                                                   # (the jutting block's rounded corner)
	var ne := _lp(LIB_NE, 0.0)
	var rc := _lp(LIB_NE, D)
	var re := _lside(LIB[1], LIB[2], D)
	var gs := ground(_lp(8.15, -0.4).x, _lp(8.15, -0.4).y)                         # the pavement before the door
	var lt := maxf(gs + 0.5, maxf(ground(ne.x, ne.y), ground(LIB[1].x, LIB[1].y)) + 0.12)  # the landing's top (half a metre over the door's pavement)
	var band := lt + 3.0                                                            # the band of teeth between the floors
	# the jutting block, to the street: a big window below and one above, both crested; columns of big panels
	var a := _lp(LIB_NE - R, 0.0)
	var b: Vector2 = LIB[0]
	var L := face(a, b, 0.0)
	var g := _gf(a, b, L / 2.0)
	var win := Rect2(L / 2.0 - 0.75, g + 0.95, 1.5, 1.9)
	var up := Rect2(L / 2.0 - 0.7, band + 0.65, 1.4, 1.5)
	var holes: Array = [win, up]
	var bands: Array = [Rect2(0.0, band, L, 0.25), Rect2(0.0, LIB_EAVES - 0.8, L, 0.8)]
	masonry(0.0, L, -2.5, LIB_EAVES, holes, _columnas([0.62, L - 0.62], g + 1.0, LIB_EAVES - 0.8, holes + bands, 0.95, 0.8, 0.16), "brick", "piedra_gris")
	_foot(L, _gf(a, b, 0.0), _gf(a, b, L), [], 0.9)
	_ventana_volutas(win, 0.35)
	_ventana_volutas(up, 0.5)
	_dientes(0.0, L, band)
	_dientes(0.0, L, LIB_EAVES - 0.72)
	cornice(-0.1, L + 0.1, LIB_EAVES, false)
	home()
	# its side to the entrance, and its corner, rounded
	var ea := rc
	var eb := _lp(LIB_NE, R)
	var sw := face(ea, eb, 0.0)
	var sbands: Array = [Rect2(0.0, band, sw, 0.25), Rect2(0.0, LIB_EAVES - 0.8, sw, 0.8)]
	masonry(0.0, sw, -2.5, LIB_EAVES, [], _columnas([0.62, sw - 0.75], lt + 0.5, LIB_EAVES - 0.8, sbands, 0.85, 0.6, 0.16), "brick", "piedra_gris")
	_foot(sw, lt, lt, [], 0.3)
	_dientes(0.0, sw, band)
	_dientes(0.0, sw, LIB_EAVES - 0.72)
	cornice(-0.1, sw, LIB_EAVES, false)
	home()
	var c := _lp(LIB_NE - R, R)
	drum(Vector3(c.x, -2.5, c.y), R, R, LIB_EAVES + 2.5, "brick", 10)
	drum(Vector3(c.x, minf(g, lt) - 0.6, c.y), R + 0.045, R + 0.045, maxf(g + 0.9, lt + 0.3) - minf(g, lt) + 0.6, "granito", 10)
	# the front set back: the door near its west end, a window east of it; above, a window over each
	var fa := re
	var fb := rc
	var lr := face(fa, fb, 0.0)
	var door := Rect2(lr - 3.7, lt, 1.5, 2.45)
	var low := Rect2(1.7, lt + 0.7, 1.4, 1.55)
	var highs: Array = [Rect2(1.75, band + 0.55, 1.3, 1.5), Rect2(door.position.x + 0.1, band + 0.55, 1.3, 1.5)]
	var fh: Array = [door, low] + highs
	var fbands: Array = [Rect2(0.0, band, lr, 0.25), Rect2(0.0, LIB_EAVES - 0.8, lr, 0.8), Rect2(door.position.x - 0.7, band - 0.6, door.size.x + 1.4, 0.6)]
	var cols: Array = [0.68, (low.end.x + door.position.x) / 2.0, (door.end.x + lr) / 2.0]
	masonry(0.0, lr, -2.5, LIB_EAVES, fh, _columnas(cols, lt + 0.45, LIB_EAVES - 0.8, fh + fbands, 0.62, 0.48, 0.15), "brick", "piedra_gris")
	_foot(lr, lt, lt, [door], 0.35)
	_ventana_volutas(low, 0.3)
	for r: Rect2 in highs:
		_ventana_volutas(r, 0.55)
	_puerta_vidrio(door)
	_tejadillo(door, lt + 2.42)
	_dientes(0.0, lr, band)
	_dientes(0.0, lr, LIB_EAVES - 0.72)
	cornice(-0.1, lr + 0.1, LIB_EAVES, false)
	# by the door: its plate, blue with white letters (our own), a grey one under it; a sheet of notices the other side
	var px := door.position.x - 0.72
	box(px, lt + 1.25, 0.0, 0.5, 0.66, 0.025, 0x1f5fb0)
	box(px + 0.04, lt + 1.31, 0.026, 0.42, 0.12, 0.004, 0xf4f4f0)
	var lb := _text("BIBLIOTECA", Vector3(px + 0.25, lt + 1.72, 0.03), 13, 0xf4f4f0, 0.004)
	lb.outline_size = 0
	box(px + 0.03, lt + 0.62, 0.0, 0.44, 0.44, 0.02, 0x9a9c9e)
	ball(Vector3(px + 0.25, lt + 0.84, 0.03), 0.11, 0x2a5aa8, 0.2, 10, 3)
	box(door.end.x + 0.32, lt + 1.25, 0.0, 0.32, 0.44, 0.012, 0xf2efe6)
	for k in range(5):
		box(door.end.x + 0.36, lt + 1.6 - k * 0.07, 0.013, 0.22 - (k % 2) * 0.06, 0.015, 0.002, 0x5a5650)
	home()
	door_lib = _lp(LIB_NE + 3.7 - 0.75, D - 1.3)
	# the music school's tall block where it stands out east of the entrance: its side, brick and white stone
	var ma: Vector2 = LIB[1]
	var mw := face(ma, re, 0.0)
	masonry(0.0, mw, -2.5, MT_EAVES, [], _pilares(0.0, mw, lt + 0.3, MT_EAVES - 0.4, [], 1.4, 0.7), "brick", "piedra_blanca")
	_foot(mw, lt, lt, [], 0.35)
	cornice(-0.1, mw, MT_EAVES, true)
	home()
	_rellano(lt, gs)
	# the lane: windows with crests below, caged above
	var sa: Vector2 = LIB[3]
	var sb: Vector2 = LIB[2]
	var sl := face(sa, sb, 0.0)
	var sl_low: Array = [Rect2(2.2, _gf(sa, sb, 3.0) + 0.8, 1.6, 1.7), Rect2(7.6, _gf(sa, sb, 8.4) + 0.8, 1.6, 1.7)]
	var sl_high: Array = [Rect2(2.3, 4.7, 1.4, 1.4), Rect2(7.7, 4.7, 1.4, 1.4)]
	var sh: Array = sl_low + sl_high
	masonry(0.0, sl, -2.5, LIB_EAVES, sh, _cajones(0.0, sl, 0.95, LIB_EAVES - 0.5, sh, 1.05, 0.7, 0.26), "brick", "piedra_gris")
	_foot(sl, _gf(sa, sb, 0.0), _gf(sa, sb, sl), [], 0.9)
	_dientes(0.0, sl, 3.9)
	for r: Rect2 in sl_low:
		_ventana_volutas(r)
	for r: Rect2 in sl_high:
		_ventana_alta(r)
	cornice(-0.1, sl + 0.1, LIB_EAVES, true)
	home()

## a band of brick teeth along a wall at height y, as the library has them: a course, upright bricks standing out side
## by side with a gap between each, a course over them standing out further
func _dientes(x0: float, x1: float, y: float) -> void:
	box(x0, y, 0.0, x1 - x0, 0.06, 0.05, "brick")
	var n := int((x1 - x0) / 0.115)
	for i in range(n):
		box(x0 + (i + 0.5) * (x1 - x0) / n - 0.03, y + 0.06, 0.0, 0.06, 0.13, 0.08, "brick")
	box(x0, y + 0.19, 0.0, x1 - x0, 0.06, 0.1, "brick")

## panels of stone in upright columns (the library's), one column on each of `xs`, from y0 up to y1, clear of `holes`
func _columnas(xs: Array, y0: float, y1: float, holes: Array, w := 0.62, h := 0.48, gap := 0.15) -> Array:
	var out: Array = []
	for x: float in xs:
		var y := y0
		while y + h <= y1:
			var r := Rect2(x - w / 2.0, y, w, h)
			var clear := true
			for hr: Rect2 in holes:
				if r.intersects(hr.grow(0.12)):
					clear = false
					break
			if clear:
				out.append(r)
			y += h + gap
	return out

## the library's front: a spot `s` along it from its west end, `d` back from the street (into the block)
func _lp(s: float, d: float) -> Vector2:
	var u: Vector2 = (LIB[1] - LIB[0]).normalized()
	return LIB[0] + u * s + Vector2(-u.y, u.x) * d

## where a side of the block running from `a` towards `b` is `d` back from the library's front
func _lside(a: Vector2, b: Vector2, d: float) -> Vector2:
	var u: Vector2 = (LIB[1] - LIB[0]).normalized()
	var dir := (b - a).normalized()
	return a + dir * (d / dir.dot(Vector2(-u.y, u.x)))

## the library's outline with its entrance set back (its solids; Catastro has the front on the street)
func _lib_real() -> Array:
	return [LIB[0], _lp(LIB_NE, 0.0), _lp(LIB_NE, LIB_HONDO), _lside(LIB[1], LIB[2], LIB_HONDO), LIB[2], LIB[3]]

## a spot of the frame being built, on the map
func _wp(x: float, z: float) -> Vector2:
	var p := _xf * Vector3(x, 0.0, z)
	return Vector2(p.x, p.z)

## The landing before the library's door, filling the entrance set back: granite, its front to the pavement, steps up
## before the door and a dark railing along the rest. Its floors for the walkers (MapData.decks: the steps first).
func _rellano(lt: float, gs: float) -> void:
	var a: Vector2 = LIB[1]
	var b := _lp(LIB_NE, 0.0)
	var L := face(a, b, 0.0)                                                        # (x = 0 at its east end, out to the street)
	var sb := (LIB[1] - LIB[0]).length()
	var x0 := sb - 9.3
	var x1 := sb - 7.0
	var D := LIB_HONDO
	var east := -(_lside(LIB[1], LIB[2], D) - a).dot((b - a).normalized())         # (its east side runs slanting back)
	var k := maxi(2, ceili((lt - gs) / 0.17))
	var rise := (lt - gs) / k
	var tread := 0.3
	var gy := minf(gs, minf(_gf(a, b, 0.0), _gf(a, b, L))) - 0.6
	for q in [[0.0, x0], [x1, L]]:                                                  # its front, and its floor
		box(q[0], gy, -0.3, q[1] - q[0], lt - gy, 0.3, "granito")
	flat(PackedVector2Array([Vector2(0.0, 0.0), Vector2(x0, 0.0), Vector2(x0, -D), Vector2(-east, -D)]), lt, "granito")
	flat(PackedVector2Array([Vector2(x1, 0.0), Vector2(L, 0.0), Vector2(L, -D), Vector2(x1, -D)]), lt, "granito")
	flat(PackedVector2Array([Vector2(x0, -k * tread), Vector2(x1, -k * tread), Vector2(x1, -D), Vector2(x0, -D)]), lt, "granito")
	for j in range(k):                                                               # the steps
		box(x0, gy, -(j + 1) * tread, x1 - x0, gs + (j + 1) * rise - gy, tread, "granito")
	for x in [x0 - 0.05, x1]:
		box(x, gy, -k * tread, 0.05, lt - gy, k * tread, "granito")
	for q in [[0.12, x0 - 0.08], [x1 + 0.08, L - 0.12]]:                          # the railing, dark brown
		var r0: float = q[0]
		var r1: float = q[1]
		var n := maxi(1, int((r1 - r0) / 1.1))
		for i in range(n + 1):
			var x := lerpf(r0, r1, float(i) / n)
			bar(Vector3(x, lt, -0.08), Vector3(x, lt + 0.95, -0.08), 0.035, 0.035, 0x3a2a22)
		bar(Vector3(r0, lt + 0.95, -0.08), Vector3(r1, lt + 0.95, -0.08), 0.045, 0.03, 0x3a2a22)
		bar(Vector3(r0, lt + 0.5, -0.08), Vector3(r1, lt + 0.5, -0.08), 0.03, 0.025, 0x3a2a22)
		solid_local(Vector3((r0 + r1) / 2.0, lt + 0.5, -0.08), Vector3(r1 - r0, 1.0, 0.08))
		_yard_local(Vector3((r0 + r1) / 2.0, 0.0, -0.08))
	var inward := _wp(0.0, -1.0) - _wp(0.0, 0.0)
	MapData.decks.append({"o": _wp((x0 + x1) / 2.0, 0.0), "r2": 9.0, "top": level + gs, "grad": inward * ((lt - gs) / (k * tread)),
		"poly": PackedVector2Array([_wp(x0, 0.05), _wp(x1, 0.05), _wp(x1, -k * tread), _wp(x0, -k * tread)])})
	home()
	MapData.decks.append(_poly_deck(PackedVector2Array([LIB[1], _lp(LIB_NE, 0.0), _lp(LIB_NE, D), _lside(LIB[1], LIB[2], D)]), level + lt))

## a glazed door of dark aluminium in its hole (two leaves, a transom)
func _puerta_vidrio(r: Rect2) -> void:
	box(r.position.x, r.position.y, -0.24, r.size.x, r.size.y, 0.01, "cristal")
	for q in [[r.position.x, 0.07], [r.position.x + r.size.x / 2.0 - 0.035, 0.07], [r.end.x - 0.07, 0.07]]:
		box(q[0], r.position.y, -0.26, q[1], r.size.y, 0.05, 0x2b2d31)
	box(r.position.x, r.end.y - 0.45, -0.26, r.size.x, 0.06, 0.05, 0x2b2d31)
	box(r.position.x, r.end.y - 0.06, -0.26, r.size.x, 0.06, 0.05, 0x2b2d31)
	openings += 1

## a little roof of old tiles over a door, as the library's: boards on three wooden beams coming straight out of the
## wall, a board along their ends; `y` its front edge
func _tejadillo(r: Rect2, y: float) -> void:
	var x0 := r.position.x - 0.7
	var x1 := r.end.x + 0.7
	roof([Vector3(x0, y + 0.42, 0.0), Vector3(x1, y + 0.42, 0.0), Vector3(x1, y + 0.02, 1.05), Vector3(x0, y + 0.02, 1.05)])
	quad(Vector3(x0, y + 0.38, 0.0), Vector3(x1, y + 0.38, 0.0), Vector3(x1, y - 0.02, 1.0), Vector3(x0, y - 0.02, 1.0), 0x5a3a24, Vector3(0, -0.93, -0.37))
	box(x0, y - 0.16, 0.94, x1 - x0, 0.17, 0.07, 0x4a3020)
	for x in [x0 + 0.12, (x0 + x1) / 2.0 - 0.06, x1 - 0.24]:
		box(x, y - 0.18, 0.0, 0.12, 0.15, 0.96, 0x5a3a24)

## a spot of the frame being built, kept for the self-test (nothing of it may stand on the asphalt)
func _yard_local(at: Vector3) -> void:
	var p := _xf * at
	yard.append(Vector2(p.x, p.z))

## a plate with what the building is, on the wall by its door
func _placa(x: float, y: float, words: String, hex: int) -> void:
	box(x, y - 0.22, 0.0, 1.5, 0.44, 0.03, hex)
	var lb := _text(words, Vector3(x + 0.75, y, 0.035), 40, 0xf6f6f2, 0.004)
	lb.outline_size = 0

# ---------------- the music school ----------------
## Its tall block (three floors) and its lower ones (two). On Argentina (Street View n5, n6) red brick with panels of
## white stone in columns between the windows, barred windows over a granite sill on every floor, the basement's little
## ones in the plinth. To the car park (n7_este, n8_este) a light brown brick of these years: a row of little windows up
## on the first floor, a glazed box over the entrance, the entrance set back under the floor above, glazed, with its
## steps, a big barred window by it. The hall's curved end with its windows high up and steps up to its side door; on
## the lane its windows. Its heights go from its own street, which stands two metres over the Casa Grande's doorway.
func _musica() -> void:
	for blk in [[MUS_T[1], MUS_T[0], MT_EAVES, 3], [MUS_E[1], MUS_E[0], ME_EAVES, 2]]:
		var a: Vector2 = blk[0]
		var b: Vector2 = blk[1]
		var top: float = blk[2]
		var floors: int = blk[3]
		var L := face(a, b, 0.0)
		var g0 := _gf(a, b, 0.0)
		var g1 := _gf(a, b, L)
		var gm := maxf(g0, g1)
		var n := maxi(1, int(L / 3.6))
		var holes: Array = []
		var basement: Array = []
		var cols: Array = []
		for i in range(n):
			var x: float = L * (i + 0.5) / n
			for fl in range(floors):
				holes.append(Rect2(x - 0.7, gm + 1.25 + fl * 3.1, 1.4, 1.35))
			basement.append(Rect2(x - 0.45, _gf(a, b, x) + 0.2, 0.9, 0.4))
			cols.append(L * i / n)
		cols.append(L)
		var panels := _columnas(cols, gm + 1.1, top - 0.9, holes + basement, 1.15, 0.85, 0.16)
		masonry(0.0, L, -2.5, top, holes + basement, panels, "brick", "piedra_blanca")
		_foot(L, g0, g1, basement, 1.0)
		for r: Rect2 in holes:
			_ventana_reja(r)
		for r: Rect2 in basement:
			window(r, 0x2b2d31, 0x1f2a33, 0)
			grille(r, 0.06, HIERRO)
			openings += 1
		cornice(-0.1, L + 0.1, top, true)
		home()
	# to the car park
	var ea: Vector2 = MUS_E[2]
	var eb: Vector2 = MUS_E[1]
	var el := face(ea, eb, 0.0)
	var g0 := _gf(ea, eb, 0.0)
	var g1 := _gf(ea, eb, el)
	var gd := _gf(ea, eb, el - 4.0)
	var fl1 := maxf(g0, g1) + 4.2                                                   # (the first floor's windows' foot)
	var door := Rect2(el - 5.6, gd + 0.45, 3.2, 2.9)                                 # the mouth of the entrance
	var caja := Rect2(el - 5.4, fl1 - 0.4, 2.8, 2.2)                                 # the glazed box over it
	var big := Rect2(el - 1.9, gd + 1.0, 1.3, 1.6)
	var big_up := Rect2(el - 1.9, fl1, 1.3, 1.25)
	var smalls: Array = []
	var wx := 1.0
	while wx + 0.9 < caja.position.x - 0.6:
		smalls.append(Rect2(wx, fl1 + 0.3, 0.9, 0.7))
		wx += 1.65
	var holes: Array = [door, caja, big, big_up] + smalls
	masonry(0.0, el, -2.5, ME_EAVES, holes, [], "ladrillo_claro", "ladrillo_claro")
	_foot(el, g0, g1, [door], 0.6)
	door_mus = ea.lerp(eb, (el - 4.0) / el) + _out(ea, eb) * 2.0
	var deep := 1.6                                                                 # the entrance, set back under the floor above
	box(door.position.x, door.position.y - 0.05, -deep, door.size.x, 0.05, deep, "granito")
	box(door.position.x, door.position.y, -deep, 0.03, door.size.y, deep - DEEP, "ladrillo_claro")
	box(door.end.x - 0.03, door.position.y, -deep, 0.03, door.size.y, deep - DEEP, "ladrillo_claro")
	box(door.position.x, door.end.y - 0.03, -deep, door.size.x, 0.03, deep - DEEP, 0xd8d4cc)
	box(door.position.x, door.position.y, -deep - 0.02, door.size.x, door.size.y, 0.01, "cristal")
	for k in range(5):
		box(door.position.x + door.size.x * k / 4.0 - 0.035, door.position.y, -deep, 0.07, door.size.y, 0.06, 0x2b2d31)
	box(door.position.x, door.position.y + 2.2, -deep, door.size.x, 0.06, 0.06, 0x2b2d31)
	openings += 1
	for k in range(3):                                                              # its steps up from the car park
		box(door.position.x - 0.3, gd + k * 0.15, 0.0, door.size.x + 0.6, 0.15, 1.2 - k * 0.35, 0xb8b4ac)
	box(caja.position.x - 0.08, caja.position.y - 0.08, 0.0, caja.size.x + 0.16, caja.size.y + 0.16, 0.14, 0x2b2d31)   # the glazed box
	box(caja.position.x, caja.position.y, 0.0, caja.size.x, caja.size.y, 0.15, "cristal")
	for k in range(1, 3):
		box(caja.position.x + caja.size.x * k / 3.0 - 0.03, caja.position.y, 0.0, 0.06, caja.size.y, 0.17, 0x2b2d31)
	box(caja.position.x, caja.position.y + caja.size.y / 2.0 - 0.03, 0.0, caja.size.x, 0.06, 0.17, 0x2b2d31)
	openings += 1
	for r: Rect2 in smalls:
		window(r, 0x2b2d31, 0x1f2a33, 0)
		box(r.position.x - 0.05, r.position.y - 0.06, 0.0, r.size.x + 0.1, 0.06, 0.08, 0xd8d4cc)
		openings += 1
	_ventana_reja(big)
	_ventana_reja(big_up)
	_placa(door.position.x - 1.8, gd + 2.0, "ESCUELA DE MÚSICA Y DANZA", 0x8a2a3a)
	cornice(-0.1, el + 0.1, ME_EAVES, false, "ladrillo_claro")
	home()
	# the hall's curved end: each length of it a front, a row of windows high up, steps up to its side door
	var pts: Array = CURVE.duplicate()
	pts.reverse()
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var L := face(a, b, 0.0)
		var hs: Array = []
		if L > 1.2 and i % 2 == 1:
			hs.append(Rect2(L / 2.0 - 0.3, _gf(a, b, L / 2.0) + 4.4, 0.6, 1.0))
		var side_door := i == 0
		if side_door:
			hs.append(Rect2(0.2, _gf(a, b, 0.8) + 0.9, 1.1, 2.3))
		masonry(0.0, L, -2.5, ME_EAVES, hs, [], "ladrillo_claro", "ladrillo_claro")                   # (the car park's light brick, n8_este)
		for r: Rect2 in hs:
			if r.size.y > 2.0:
				box(r.position.x, r.position.y, -0.22, r.size.x, r.size.y, 0.06, WOOD)
				for k in range(4):
					box(r.position.x - 0.2, r.position.y - 0.9 + k * 0.22, 0.0, r.size.x + 0.4, 0.22, 1.2 - k * 0.3, 0xb8b4ac)
			else:
				_ventana_alta(r, false)
		box(-0.02, _gf(a, b, L / 2.0) - 0.6, 0.0, L + 0.04, 1.5, 0.04, "granito")
		cornice(-0.12, L + 0.12, ME_EAVES, false, "ladrillo_claro")
		home()
	# the lane: the south block's front, as far as the hall's curved end
	var la: Vector2 = MUS_S_REST[1]
	var lb: Vector2 = CURVE[CURVE.size() - 1]
	var ll := face(la, lb, 0.0)
	var lh: Array = []
	for x in [2.0, 5.2]:
		lh.append(Rect2(x, _gf(la, lb, x) + 1.0, 1.3, 1.4))
		lh.append(Rect2(x, _gf(la, lb, x) + 4.2, 1.3, 1.4))
		lh.append(Rect2(x + 0.2, _gf(la, lb, x) + 0.05, 0.9, 0.4))                    # (the basement's low windows)
	masonry(0.0, ll, -2.5, ME_EAVES, lh, _pilares(0.0, ll, 0.9, ME_EAVES - 0.4, lh), "brick", "piedra_blanca")
	_foot(ll, _gf(la, lb, 0.0), _gf(la, lb, ll), [], 0.9)
	for r: Rect2 in lh:
		_ventana_alta(r, r.position.y < 3.0)
	cornice(-0.1, ll + 0.1, ME_EAVES, true)
	home()

# ---------------- the walls between them and the roofs ----------------
## Each block's walls where it stands against a lower one (seen over its roof), and its hipped roof of tiles: a slope
## up from every eave to a ridge round a flat top (a hipped roof, square in the middle).
func _roofs() -> void:
	# the tall block over its neighbours
	for e in [[MUS_T[0], MUS_T[3]], [MUS_T[2], MUS_T[1]], [MUS_T[3], MUS_T[2]]]:
		_plain(e[0], e[1], ME_EAVES - 0.5, MT_EAVES, "brick")
		_plain(e[1], e[0], ME_EAVES - 0.5, MT_EAVES, "brick")
	home()
	_plain(_lside(LIB[1], LIB[2], LIB_HONDO), LIB[2], CC_EAVES - 0.4, LIB_EAVES, "brick")
	_plain(LIB[3], LIB[0], CC_EAVES - 0.4, LIB_EAVES, "brick")
	home()
	_hip_roof(CC, CC_EAVES, 2.1, 6.0)
	var lw := _lside(LIB[0], LIB[3], LIB_HONDO)                                   # the library behind its entrance, and its jutting block
	_hip_roof([lw, _lside(LIB[1], LIB[2], LIB_HONDO), LIB[2], LIB[3]], LIB_EAVES, 2.4, 5.0)
	_hip_roof([LIB[0], _lp(LIB_NE, 0.0), _lp(LIB_NE, LIB_HONDO), lw], LIB_EAVES, 1.1, 1.4)
	_hip_roof(MUS_T, MT_EAVES, 1.8, 3.4)
	_hip_roof(MUS_E, ME_EAVES, 1.5, 3.0)
	_hip_roof(_mus_s(), ME_EAVES, 1.5, 3.5)

## A hipped roof over a polygon of the map: tiles from its eaves (a little out over the walls) up to a ridge `inset` in
## from each wall, a flat top within; the hips' rounded tiles.
func _hip_roof(poly: Array, eaves: float, rise: float, inset: float, over := 0.38) -> void:
	var pts: Array = poly.duplicate()
	if Geometry2D.is_polygon_clockwise(PackedVector2Array(pts)):
		pts.reverse()
	var n := pts.size()
	var mit: Array = []
	for i in range(n):                                                               # inwards, mitred
		var p0: Vector2 = pts[(i - 1 + n) % n]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[(i + 1) % n]
		var d0 := (p1 - p0).normalized()
		var d1 := (p2 - p1).normalized()
		var n0 := Vector2(-d0.y, d0.x)
		var n1 := Vector2(-d1.y, d1.x)
		var m := (n0 + n1).normalized()
		mit.append(m / maxf(0.35, m.dot(n1)))
	var slope := rise / inset
	var outer: Array = []
	var inner: Array = []
	for i in range(n):
		var p: Vector2 = pts[i]
		var o: Vector2 = p - (mit[i] as Vector2) * over
		var q: Vector2 = p + (mit[i] as Vector2) * inset
		outer.append(Vector3(o.x, eaves - over * slope, o.y))
		inner.append(Vector3(q.x, eaves + rise, q.y))
	for i in range(n):
		var j := (i + 1) % n
		roof([outer[i], outer[j], inner[j], inner[i]])
		ridge(outer[i], inner[i])
	var top := PackedVector2Array()
	for v: Vector3 in inner:
		top.append(Vector2(v.x, v.z))
	if top.size() >= 3 and not Geometry2D.triangulate_polygon(top).is_empty():
		flat(top, eaves + rise, 0x8a7a6a)
	for i in range(n):
		ridge(inner[i], inner[(i + 1) % n])
