extends "res://scripts/esquina.gd"
## The two-storey house north of the Calle del Salvador, on its corner with the Avenida de la Constitución: the last of
## the four corners of the crossroads of the traffic lights (the one with a traffic light, a no-entry sign and a grey
## cabinet before its corner). The user, 22 November 2026, after the white house of Santa Ana: "Vamos a tratar de
## terminar el cruce de los semáforos para poner definitivamente los semáforos" and "Siguiente". Built by hand from
## Street View (November 2024: tools/cruce/capturas.py, the g_ pictures) on the house `salvador_c3` of the map
## (casas_calles.gd marks it "obra"), with no rebake; referencias/cruce/LEEME.md.
##
## A plain house of 1976, two floors, 6.25 m to its eaves, one room deep along each street round a yard:
##   - to the avenue (east, 12.6 m): beige render over a worn reddish foot; a deep doorway up two steps, lime-washed
##     inside, a dark studded door at its back; a window behind a black grille at each side, all three in rough white
##     frames; above, three windows with their blinds down and little iron rails; cables along it;
##   - to the Salvador (south, 20.3 m): bare grey render over a pinkish foot; four windows behind grey grilles (the
##     first with bellied bars), a low wooden hatch, vents; above, a narrow window and three with rails; the east third
##     of the front is blank; the street's tile by the corner;
##   - its north end, where a neighbour was pulled down: bare wall, the white plaster of the lost house's room still
##     on it, edged in broken brick (dirty stays dirty);
##   - eaves of two steps under the mouths of old tiles; each wing's roof of two slopes, to its street and to the
##     yard, hipped at the corner; a gable at each far end.
## Behind, in its yard: a back building of bare brick, a low shed, and two more at the bottom of the plot (the map's
## other pieces of this house), all plain. North of it, the empty plot's wall of grey blocks: along the avenue, with
## its gate of red sheet beside the house, and round the corner along the Calle de Colón as far as the plot's last
## building. Nobody gets in. No number on it (the game shows none).
## No saffron hidden here: one is proposed for each place and the user says whether it goes in.
##
## Frame: the map's own (x east, z south), y = 0 the pavement before its corner. Each front is built in its own frame
## (obra.face). The roof, the shared walls and the solids are esquina.gd's.

const HOUSE := "salvador_c3"
const DIR := "res://assets/clinica/"        # (the street's tile is drawn with the clinic's: tools/cruce/dibujos_clinica.py)

# its outline on the map (Catastro 4391110VJ5649S, parts 2 and 6: the two wings on the streets), in the ring's order
const NE := Vector2(109.16, 43.81)           # where it ends on the avenue
const SE := Vector2(107.84, 56.33)           # the corner of the avenue and the Salvador
const WEST := Vector2(88.66, 49.82)          # where it ends on the Salvador
const Y1 := Vector2(90.05, 45.15)            # round its yard
const Y2 := Vector2(91.98, 45.80)
const Y3 := Vector2(100.88, 47.62)
const Y4 := Vector2(104.61, 48.38)
const Y5 := Vector2(105.29, 45.56)
const Y6 := Vector2(105.57, 43.69)
const PE := Vector2(103.08, 54.71)           # where the avenue wing's yard side, carried on, meets the front of the Salvador
const QS := Vector2(108.59, 49.19)           # where the Salvador wing's yard side, carried on, meets the front of the avenue
const BACK: Array = [Vector2(93.39, 42.06), Vector2(101.83, 44.55), Vector2(100.88, 47.62), Vector2(91.98, 45.80), Vector2(92.58, 44.22)]      # (part 7: the back building, two floors)
const SHED: Array = [Vector2(101.83, 44.55), Vector2(105.29, 45.56), Vector2(104.61, 48.38), Vector2(100.88, 47.62)]      # (part 5: one floor, in the yard's corner)
const FAR1: Array = [Vector2(84.90, 40.28), Vector2(86.83, 34.97), Vector2(91.29, 36.59), Vector2(89.40, 42.00)]          # (part 4, at the bottom of the plot: the map's second piece of this house)
const FAR2: Array = [Vector2(83.97, 24.76), Vector2(88.76, 26.68), Vector2(87.21, 33.37), Vector2(81.54, 31.24)]          # (part 1: the third)

const TOP := 6.25                   # the top of the walls
const EAVE := 0.3
const PITCH := 0.3
const RISE0 := 0.09
const FOOT := 0.75                  # the worn band at its foot
const UP := 3.45                    # the sills of the windows above
const WALL := 2.4                   # how tall the empty plot's wall is (2.8 m over its gate)
const BLIND := 0xd9d2c2             # the blinds above
const OCHRE := 0xc9a45c             # the painted insides of the windows above
const SHUT := 0x54392a              # the wooden blinds below
const GREY_IRON := 0x5a5d62         # the grilles of the Salvador

var door: Vector2                   # before the doorway on the avenue (the self-test)
var side_spot: Vector2              # before the front of the Salvador
var plot_spot: Vector2              # before the empty plot's wall
var openings := 0
var balconies := 0

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"beige":            # the avenue's render (Street View 2024, in the sun: about 200, 180, 140)
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.86, 0.77, 0.6)), 0.14)
		"gris":             # the Salvador's: cement, never painted
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.73, 0.72, 0.68)), 0.1)
		"zocalo":           # the foot: a reddish wash, worn
			m = Tex.mat("painted_plaster_wall", Color(0.74, 0.58, 0.52))
		"zocalo_gris":      # the Salvador's: paler
			m = Tex.mat("painted_plaster_wall", Color(0.78, 0.66, 0.61))
		"cal":              # the lime wash round the openings of the avenue
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.985, 0.94)), 0.3)
		"medianera":        # what looks on the yard and on its neighbours
			m = Tex.mat("painted_plaster_wall", Color(0.78, 0.74, 0.66))
		"bloque":           # the empty plot's wall: grey concrete blocks
			m = Tex.mat("granular_concrete", Color(0.74, 0.74, 0.72))
		"uralita":          # the shed's sheets (only roofs use it: they carry their own UVs)
			var um := StandardMaterial3D.new()
			um.albedo_color = Color(0.72, 0.72, 0.7)
			um.roughness = 0.9
			um.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = um
		"placa_salvador":
			var tm := StandardMaterial3D.new()
			tm.albedo_texture = load(DIR + "placa_salvador.png")
			tm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			tm.roughness = 0.85
			m = tm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world, _hd: Dictionary) -> void:
	W = world
	var oe := _outward(SE, NE)
	var os := _outward(WEST, SE)
	level = MapData.height(SE + (oe + os).normalized() * 1.0)
	transform = Transform3D(Basis.IDENTITY, Vector3(0.0, level, 0.0))
	W.add_child(self)
	wall_top = TOP
	eave_out = EAVE
	roof_pitch = PITCH
	roof_rise0 = RISE0
	_east()
	_south()
	# the roofs: each wing has two slopes, to its street and to the yard, and is hipped at the corner. Each is laid
	# whole over its own wing, the corner under both: the higher hides the lower, and the valley is where they cross.
	var o_n := _outward(Y4, Y3)                               # (the Salvador wing's yard side looks north)
	var o_w := _outward(Y4, PE)                               # (the avenue wing's looks west)
	_planes = [[os, SE.dot(os)], [o_n, Y4.dot(o_n)], [oe, SE.dot(oe)]]
	for pair in [[WEST, Y1], [Y1, Y2], [Y2, Y3], [Y3, Y4]]:      # (what looks on its neighbour and on its own yard)
		_party_wall(pair[0], pair[1])
	_roof_over([QS, SE, WEST, Y1, Y2, Y3, Y4], [-EAVE, -EAVE, 0.0, -0.1, -0.15, -0.15, 0.0])
	_planes = [[oe, SE.dot(oe)], [o_w, Y4.dot(o_w)], [os, SE.dot(os)]]
	for pair in [[Y4, Y5], [Y5, Y6]]:
		_party_wall(pair[0], pair[1])
	_north()
	_roof_over([NE, SE, PE, Y4, Y5, Y6], [-EAVE, -EAVE, 0.0, -0.15, -0.15, 0.0])
	# what stands in its yard and at the bottom of its plot: plain walls, one slope each
	roof_rise0 = 0.05
	_block(BACK, 5.0, 0, "brick", "tiles", [2])
	_block(SHED, 2.7, 0, "medianera", "uralita", [1, 2, 3])
	_block(FAR1, 5.4, 1, "medianera", "tiles")
	_block(FAR2, 5.4, 1, "medianera", "tiles")
	wall_top = TOP
	_plot_wall(oe)
	home()
	_commit()
	_ring_solids([NE, SE, WEST, Y1, Y2, Y3, Y4, Y5, Y6], 10.0)
	for ring in [BACK, SHED, FAR1, FAR2]:
		_ring_solids(ring, 9.0)
	door = _along(SE, NE, 6.37) + oe * 1.3
	side_spot = _along(WEST, SE, 10.0) + os * 1.3
	plot_spot = _along(NE, NE + (NE - SE), 4.5) + oe * 1.3

# ---------------- what the fronts share ----------------
## how high the ground is before a spot of a front (this frame's y)
func _g(a: Vector2, b: Vector2, x: float) -> float:
	var p := _along(a, b, x) + _outward(a, b) * 0.5
	return ground(p.x, p.y)

## the worn band at the foot of a stretch of the front being built (a..b: its ends on the map), following the ground
func _foot(a: Vector2, b: Vector2, x0: float, x1: float, key, tall := FOOT) -> void:
	var n := maxi(1, int(ceil((x1 - x0) / 2.0)))
	for i in range(n):
		var xa := lerpf(x0, x1, float(i) / n)
		var xb := lerpf(x0, x1, float(i + 1) / n)
		plinth(xa, xb, _g(a, b, xa) + tall, _g(a, b, xb) + tall, key, 0.012, -1.0)

func _darker(hex: int, by: float) -> int:
	var c := Color.hex((hex << 8) | 0xff).darkened(by)
	return (c.r8 << 16) | (c.g8 << 8) | c.b8

## a window in its hole with its blind all the way down: `inside` paints its jambs and head; its sill
func _window(r: Rect2, inside: int, blind: int, sill := 0xcfc8b8) -> void:
	openings += 1
	window(r, 0x5a4030, 0x1f2a33, 1)
	box(r.position.x, r.position.y, -DEEP + 0.07, 0.014, r.size.y, DEEP - 0.07, inside)
	box(r.end.x - 0.014, r.position.y, -DEEP + 0.07, 0.014, r.size.y, DEEP - 0.07, inside)
	box(r.position.x, r.end.y - 0.014, -DEEP + 0.07, r.size.x, 0.014, DEEP - 0.07, inside)
	box(r.position.x + 0.03, r.position.y + 0.02, -0.14, r.size.x - 0.06, r.size.y - 0.03, 0.025, blind)
	var slat := _darker(blind, 0.14)
	for i in range(1, int(r.size.y / 0.09)):
		box(r.position.x + 0.03, r.position.y + i * 0.09, -0.115, r.size.x - 0.06, 0.012, 0.005, slat)
	box(r.position.x - 0.06, r.position.y - 0.06, 0.0, r.size.x + 0.12, 0.06, 0.07, sill)

## a little iron rail before a window above, on a slab that comes out of its sill: upright bars, two rails
func _rail(r: Rect2) -> void:
	balconies += 1
	var x0 := r.position.x - 0.1
	var x1 := r.end.x + 0.1
	var y := r.position.y
	var out := 0.24
	box(x0, y - 0.08, 0.0, x1 - x0, 0.08, out + 0.04, 0xcfc8b8)
	box(x0, y + 0.45, out - 0.02, x1 - x0, 0.03, 0.035, IRON)
	box(x0, y + 0.05, out - 0.015, x1 - x0, 0.02, 0.022, IRON)
	var n := maxi(4, int((x1 - x0) / 0.11))
	for k in range(n + 1):
		box(lerpf(x0, x1 - 0.016, float(k) / n), y, out - 0.014, 0.016, 0.46, 0.016, IRON)
	for x in [x0, x1 - 0.02]:
		box(x, y + 0.45, 0.0, 0.02, 0.03, out, IRON)
		box(x, y + 0.05, 0.0, 0.02, 0.02, out, IRON)

## a grille whose bars belly out below (a "reja de buche"), before a window
func _belly(r: Rect2, iron: int) -> void:
	var x0 := r.position.x - 0.06
	var x1 := r.end.x + 0.06
	var y0 := r.position.y - 0.05
	var y1 := r.end.y + 0.05
	var prof: Array = [[0.0, 0.13], [0.1, 0.3], [0.36, 0.34], [0.6, 0.14], [1.0, 0.13]]      # (from its foot up: how far out it stands)
	var n := maxi(3, int(round((x1 - x0) / 0.14)))
	for i in range(n + 1):
		var x := x0 + (x1 - x0) * i / n
		for k in range(prof.size() - 1):
			bar(Vector3(x, lerpf(y0, y1, float(prof[k][0])), float(prof[k][1])), Vector3(x, lerpf(y0, y1, float(prof[k + 1][0])), float(prof[k + 1][1])), 0.022, 0.022, iron)
	for q in [[0.0, 0.13], [0.6, 0.14], [1.0, 0.13]]:
		var y := lerpf(y0, y1, float(q[0]))
		box(x0, y - 0.006, float(q[1]) - 0.02, x1 - x0, 0.012, 0.04, iron)
	for y in [y0, y1]:
		box(x0 - 0.011, y - 0.006, 0.0, 0.022, 0.012, 0.13, iron)
		box(x1 - 0.011, y - 0.006, 0.0, 0.022, 0.012, 0.13, iron)

## the eaves over the front being built: two steps of the wall's own render, the mouths of the tiles on them (e0, e1:
## how much further they run to turn the corner)
func _cornice(ln: float, e0: float, e1: float, key) -> void:
	box(-e0 * 0.1, TOP - 0.22, 0.0, ln + (e0 + e1) * 0.1, 0.12, 0.1, key)
	box(-e0 * 0.2, TOP - 0.1, 0.0, ln + (e0 + e1) * 0.2, 0.1, 0.2, key)
	var n := maxi(2, int(round(ln / 0.24)))
	for i in range(n):
		drum(Vector3(ln * (i + 0.5) / n, TOP, 0.17), 0.085, 0.085, 0.1, 0xa8623f, 6)

## the bundle of cables along the front being built at height y, from x0 to x1, in its clips
func _cables(y: float, x0: float, x1: float) -> void:
	var n := maxi(2, int(round((x1 - x0) / 1.1)))
	for k in range(n):
		var xa := lerpf(x0, x1, float(k) / n)
		var xb := lerpf(x0, x1, float(k + 1) / n)
		var ya := y - 0.025 * (k % 2)
		var yb := y - 0.025 * ((k + 1) % 2)
		bar(Vector3(xa, ya, 0.035), Vector3(xb, yb, 0.035), 0.03, 0.03, 0x2c2c2e)
		bar(Vector3(xa, ya - 0.06, 0.03), Vector3(xb, yb - 0.06, 0.03), 0.026, 0.026, 0xbfb9a8)
		box(xa - 0.01, ya - 0.09, 0.0, 0.02, 0.13, 0.05, 0x8a8a86)

# ---------------- the front to the Avenida de la Constitución (east) ----------------
func _east() -> void:
	var L := face(SE, NE)                                         # (x from the corner, as seen from the street)
	var e0 := _miter(_outward(SE, NE), _outward(WEST, SE), 1.0)
	var w1 := Rect2(3.0, 0.95, 1.2, 1.3)
	var w2 := Rect2(9.39, 0.95, 1.03, 1.3)
	var foot := _g(SE, NE, 6.37)                                  # (the pavement before the doorway)
	var way := Rect2(5.69, foot - 0.4, 1.37, 2.36 + 0.4)
	var ups: Array = [Rect2(1.7, UP, 1.4, 1.35), Rect2(5.58, UP, 1.37, 1.35), Rect2(9.35, UP, 1.3, 1.35)]
	masonry(0.0, L, -1.0, TOP, [w1, way, w2] + ups, [], "beige")
	_foot(SE, NE, -e0 * 0.012, way.position.x - 0.25, "zocalo")
	_foot(SE, NE, way.end.x + 0.14, L, "zocalo")
	# the rough white frames round what opens below
	for r: Rect2 in [w1, w2]:
		box(r.position.x - 0.17, r.position.y - 0.2, 0.0, 0.17, r.size.y + 0.36, 0.016, "cal")
		box(r.end.x, r.position.y - 0.2, 0.0, 0.14, r.size.y + 0.36, 0.016, "cal")
		box(r.position.x, r.end.y, 0.0, r.size.x, 0.16, 0.016, "cal")
		box(r.position.x, r.position.y - 0.2, 0.0, r.size.x, 0.14, 0.016, "cal")
		_window(r, 0xf0ece0, SHUT, 0xe6e2d6)
		grille(r, 0.15, IRON)
	box(way.position.x - 0.25, foot, 0.0, 0.25, 2.36 + 0.2, 0.016, "cal")
	box(way.end.x, foot, 0.0, 0.14, 2.36 + 0.2, 0.016, "cal")
	box(way.position.x, foot + 2.36, 0.0, way.size.x, 0.2, 0.016, "cal")
	_doorway(way, foot)
	for r: Rect2 in ups:
		_window(r, OCHRE, BLIND)
		_rail(r)
	_cables(3.2, 0.25, L - 0.2)
	box(5.16, 2.5, 0.0, 0.22, 0.3, 0.1, 0xe4e0d4)                   # (the boxes on it)
	box(11.65, 2.9, 0.0, 0.2, 0.22, 0.09, 0xe4e0d4)
	box(0.35, 2.75, 0.0, 0.16, 0.42, 0.1, 0xd8d4c8)
	_cornice(L, e0, 0.0, "beige")
	home()

## The doorway of the avenue: as deep as the room's wall is thick and more, lime-washed inside, a step out on the
## pavement and another in; at its back two dark leaves with nails.
func _doorway(r: Rect2, foot: float) -> void:
	openings += 1
	var deep := 0.9
	var top := r.end.y
	box(r.position.x, foot - 0.4, -deep, 0.012, top - foot + 0.4, deep, "cal")
	box(r.end.x - 0.012, foot - 0.4, -deep, 0.012, top - foot + 0.4, deep, "cal")
	box(r.position.x, top - 0.012, -deep, r.size.x, 0.012, deep, "cal")
	box(r.position.x, foot - 0.4, -deep, r.size.x, 0.4 + 0.17, deep + 0.14, 0x9a958c)       # (the step out on the pavement)
	box(r.position.x, foot + 0.17, -deep, r.size.x, 0.17, deep - 0.3, 0x9a958c)
	var y0 := foot + 0.34
	box(r.position.x, y0, -deep - 0.04, r.size.x, top - y0, 0.04, 0x3e2a1e)
	var mid := r.get_center().x
	for s in [-1.0, 1.0]:                                          # (each leaf: a frame and two panels)
		var x0 := mid + (-r.size.x / 2.0 + 0.04 if s < 0.0 else 0.02)
		var w := r.size.x / 2.0 - 0.06
		box(x0, y0 + 0.03, -deep, w, top - y0 - 0.06, 0.03, 0x4a3324)
		box(x0 + 0.08, y0 + 0.14, -deep + 0.03, w - 0.16, 0.7, 0.012, 0x3e2a1e)
		box(x0 + 0.08, y0 + 0.96, -deep + 0.03, w - 0.16, top - y0 - 1.12, 0.012, 0x3e2a1e)
		studs(x0 + 0.05, x0 + w - 0.05, y0 + 0.1, top - 0.12, -deep + 0.04, 3, 6, 0x1c1c1e)
	box(mid - 0.015, y0, -deep + 0.03, 0.03, top - y0, 0.02, 0x2e2018)
	box(mid + 0.07, y0 + 0.95, -deep + 0.045, 0.04, 0.14, 0.03, 0x9a8a5a)                    # (its handle)

# ---------------- the front to the Calle del Salvador (south) ----------------
func _south() -> void:
	var L := face(WEST, SE)                                       # (x from its west end, as seen from the street)
	var e1 := _miter(_outward(SE, NE), _outward(WEST, SE), 1.0)
	var g1 := Rect2(0.85, 1.0, 1.25, 1.15)
	var g2 := Rect2(6.7, 1.0, 1.2, 1.2)
	var g3 := Rect2(11.2, 1.0, 1.3, 1.15)
	var g4 := Rect2(14.4, 1.0, 1.2, 1.2)
	var up_a := Rect2(1.6, UP, 0.9, 1.55)
	var ups: Array = [Rect2(4.6, UP, 1.45, 1.45), Rect2(9.0, UP, 1.45, 1.45), Rect2(12.25, UP, 1.36, 1.45)]
	masonry(0.0, L, -1.0, TOP, [g1, g2, g3, g4, up_a] + ups, [], "gris")
	_foot(WEST, SE, 0.0, L + e1 * 0.012, "zocalo_gris", 0.85)
	for r: Rect2 in [g1, g2, g3, g4]:
		_window(r, 0xb9b7b0, SHUT, 0xb9b7b0)
	_belly(g1, GREY_IRON)
	for r: Rect2 in [g2, g3, g4]:
		grille(r, 0.15, 0x3c3e42)
	_window(up_a, OCHRE, BLIND)
	for r: Rect2 in ups:
		_window(r, OCHRE, BLIND)
		_rail(r)
	# the low hatch of old boards; the louvred vent by the third window; two little vents; a round lamp; a box
	var hy := _g(WEST, SE, 4.3)
	box(3.98, hy + 0.36, 0.0, 0.66, 0.98, 0.02, 0x8a8478)
	for i in range(4):
		box(4.01 + i * 0.15, hy + 0.39, 0.02, 0.14, 0.92, 0.015, 0x7a5a3c if i % 2 == 0 else 0x6e5036)
	var vy := _g(WEST, SE, 10.8)
	box(10.42, vy + 0.36, 0.0, 0.8, 0.5, 0.03, 0xc9c7c0)
	for i in range(6):
		box(10.45, vy + 0.4 + i * 0.075, 0.03, 0.74, 0.03, 0.02, 0x9a9892)
	for q in [[5.4, 1.85], [6.2, 2.75]]:
		box(float(q[0]), float(q[1]), 0.0, 0.2, 0.22, 0.02, 0xe4e2dc)
		for i in range(4):
			box(float(q[0]) + 0.02, float(q[1]) + 0.03 + i * 0.045, 0.02, 0.16, 0.015, 0.008, 0xb4b2ac)
	drum(Vector3(6.6, 4.95, 0.0), 0.09, 0.09, 0.07, 0xecebe6, 10)
	box(11.05, 3.3, 0.0, 0.16, 0.16, 0.08, 0xe4e0d4)
	_cables(3.14, 0.9, L - 0.25)
	for k in range(4):                                             # (at its west end they climb to the next house)
		bar(Vector3(0.9 - k * 0.22, 3.14 + 0.5 * sin(k * PI / 8.0), 0.035), Vector3(0.9 - (k + 1) * 0.22, 3.14 + 0.5 * sin((k + 1) * PI / 8.0), 0.035), 0.03, 0.03, 0x2c2c2e)
	_picture(L - 0.95, L - 0.47, 2.72, 2.72 + 0.48 * 280.0 / 360.0, 0.012, "placa_salvador")
	_cornice(L, 0.0, e1, "gris")
	home()

# ---------------- its north end ----------------
## Where the neighbour was pulled down: the bare wall, the white plaster of the lost house's upper room still on it,
## edged by what is left of its walls and its roof in broken brick, two stubs of its beams.
func _north() -> void:
	_party_wall(Y6, NE)
	var L := face(NE, Y6)                                         # (x from the avenue's end, as seen from the plot)
	slab(PackedVector2Array([Vector2(0.5, 3.25), Vector2(L - 0.35, 3.25), Vector2(L - 0.35, 4.85), Vector2(L - 1.1, 5.45), Vector2(1.5, 5.95), Vector2(0.5, 6.02)]), 0.02, 0.02, 0xe9e6dc)
	box(0.22, 3.1, 0.0, 0.28, 2.95, 0.13, "brick")                 # (the stump of its front wall)
	box(0.5, 3.1, 0.0, L - 0.85, 0.15, 0.1, "brick")               # (where its floor was)
	for q in [[0.5, 6.02, 1.5, 5.95], [1.5, 5.95, L - 1.1, 5.45], [L - 1.1, 5.45, L - 0.35, 4.85]]:      # (the line of its roof)
		bar(Vector3(float(q[0]), float(q[1]) + 0.06, 0.06), Vector3(float(q[2]), float(q[3]) + 0.06, 0.06), 0.12, 0.16, "brick")
	for q in [[1.0, 5.6], [2.1, 5.25]]:
		box(float(q[0]), float(q[1]), 0.0, 0.1, 0.12, 0.4, 0x4a3a2c)
	for q in [[0.9, 3.9, 0.5, 0.35], [2.0, 4.6, 0.4, 0.5]]:        # (plaster fallen off it in patches)
		slab(PackedVector2Array([Vector2(q[0], q[1]), Vector2(float(q[0]) + float(q[2]), float(q[1]) + 0.05), Vector2(float(q[0]) + float(q[2]) * 0.8, float(q[1]) + float(q[3])), Vector2(float(q[0]) + 0.08, float(q[1]) + float(q[3]) * 0.8)]), 0.045, 0.0, 0xb9a48c)
	home()

# ---------------- the yard's buildings ----------------
## A plain building: walls of `key` up to `top`, one slope of `cover` falling to the edge `low` of its ring (in the
## ring's order, clockwise seen from above); `skip`: the edges another building already closes.
func _block(ring: Array, top: float, low: int, key, cover, skip: Array = []) -> void:
	var a: Vector2 = ring[low]
	var b: Vector2 = ring[(low + 1) % ring.size()]
	var out := _outward(b, a)
	wall_top = top
	_planes = [[out, a.dot(out)]]
	var by: Array = []
	for i in range(ring.size()):
		by.append(-0.12 if i == low else 0.0)
		if not (i in skip):
			_party_wall(ring[i], ring[(i + 1) % ring.size()], key)
	_roof_over(ring, by, cover)

# ---------------- the empty plot's wall, north along the avenue ----------------
## Grey concrete blocks, 2.4 m tall, stepping with the ground. Along the avenue from the house's end: a rendered pier
## and a gate of red corrugated sheet with a yellow plate on it, blocks over it up to 2.8 m; then round the corner,
## along the Calle de Colón, to the house's own building at the bottom of its plot.
func _plot_wall(oe: Vector2) -> void:
	var dn := (NE - SE).normalized()
	var corner := NE + dn * _plot_reach(dn, oe)
	var L := face(NE, corner)                                     # (x from the house's end, as seen from the avenue)
	box(0.0, -1.0, -0.26, 0.5, 2.8 + 1.0, 0.26, "medianera")
	box(0.5, -0.3, -0.16, 1.7, 2.6, 0.04, 0x8c2e24)                # (the gate)
	for i in range(17):
		box(0.53 + i * 0.1, -0.3, -0.12, 0.045, 2.6, 0.014, 0x7a261e)
	box(1.2, 1.3, -0.1, 0.3, 0.42, 0.01, 0xe2b93a)
	box(0.5, 2.3, -0.2, 1.7, 0.5, 0.2, "bloque")
	_joints(0.5, 2.2, 2.3, 2.8)
	_run(NE, corner, 2.2, L)
	home()
	var end: Vector2 = (FAR2[1] as Vector2).lerp(FAR2[2], 0.12)
	var L2 := face(corner, end)                                   # (x from the corner, as seen from the Calle de Colón)
	_run(corner, end, 0.0, L2)
	home()
	for pair in [[NE, corner], [corner, end]]:
		var a: Vector2 = pair[0]
		var b: Vector2 = pair[1]
		var d := (b - a).normalized()
		var mid := (a + b) / 2.0 - Vector2(-d.y, d.x) * 0.1
		solid(Vector3(mid.x, 1.0, mid.y), Vector3(a.distance_to(b), 4.0, 0.22), atan2(-d.y, d.x))
		for k in [0.0, 0.25, 0.5, 0.75, 1.0]:
			yard.append(a.lerp(b, k) + Vector2(-d.y, d.x) * 0.02)      # (the self-test: none of it on the asphalt)

## how far the plot's wall runs north along the avenue: to a metre and a half short of the next street's kerb
func _plot_reach(dn: Vector2, oe: Vector2) -> float:
	var s := 4.0
	while s < 30.0:
		var q := NE + dn * (s + 0.25) - oe * 4.0                  # (four metres into the plot: there only the next street's kerb can be near)
		var d: float = MapData.road_edge_dist(q)
		if MapData.road_hit != null:
			d += MapData.road_hit.hw - MapData.fitted_hw(MapData.road_hit)
		if d < 1.5:
			break
		s += 0.25
	return s

## a stretch of the wall of blocks on the front being built (a..b: its ends on the map), in steps that follow the ground
func _run(a: Vector2, b: Vector2, x0: float, x1: float) -> void:
	var n := maxi(1, int(ceil((x1 - x0) / 4.0)))
	for i in range(n):
		var xa := lerpf(x0, x1, float(i) / n)
		var xb := lerpf(x0, x1, float(i + 1) / n)
		var g := snappedf(_g(a, b, (xa + xb) / 2.0), 0.1)
		box(xa, g - 1.0, -0.2, xb - xa, WALL + 1.0, 0.2, "bloque")
		_joints(xa, xb, g, g + WALL)

## the joints of the blocks on a piece of it: courses of 20 cm, the blocks 40 cm long, breaking joint
func _joints(x0: float, x1: float, y0: float, y1: float) -> void:
	var hex := 0x8f8f8a
	var rows := int(round((y1 - y0) / 0.2))
	for j in range(rows):
		if j > 0:
			box(x0, y0 + j * 0.2 - 0.005, 0.0, x1 - x0, 0.01, 0.004, hex)
		var x := x0 + (0.2 if j % 2 == 0 else 0.4)
		while x < x1 - 0.05:
			box(x - 0.005, y0 + j * 0.2, 0.0, 0.01, 0.2, 0.004, hex)
			x += 0.4
