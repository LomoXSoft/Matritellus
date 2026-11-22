extends "res://scripts/esquina.gd"
## The white house with indigo frames on the corner of the Calle de Santa Ana and the Calle de los Arcos, at the
## crossroads of the traffic lights. The user, 22 November 2026, with his picture of it from Street View: "Vamos a tratar
## de terminar el cruce de los semáforos para poner definitivamente los semáforos. El siguiente será Calle Santa Ana, 2".
## Built by hand from Street View (November 2024: tools/cruce/capturas.py, the e_ pictures) on the house
## `constitucion_a1` of the map (casas_calles.gd marks it "obra"), with no rebake; referencias/cruce/LEEME.md.
##
## An old house of two low floors, 5.75 m to its eaves, lime-washed, on a foot of dark rubble:
##   - to Santa Ana (north, 15 m): at its east end a carriage gate of pale studded wood under a grille of turned bars,
##     between indigo jambs; two windows behind black grilles; above, three windows in indigo frames with brown blinds
##     and little iron balconies; the west third of the front is blank; two cables along it; the render gone in a patch
##     over the foot (dirty stays dirty);
##   - to the Arcos (west, 4.7 m): a window behind its grille, a doorway behind a purple curtain between indigo jambs,
##     a window above, the street's tile at the corner;
##   - a cornice of white mouldings under the mouths of the tiles, old tiles, the corner hipped, a tall white chimney.
## Behind, across its yard, the house's own back building, plain. No number on it (the game shows none); nobody gets in.
## No saffron hidden here: since 22 November 2026 one is proposed for each place and the user says whether it goes in.
##
## Frame: the map's own (x east, z south), y = 0 the pavement before the middle of its front on Santa Ana. Each front is
## built in its own frame (obra.face). The roof, the shared walls and the solids are esquina.gd's.

const HOUSE := "constitucion_a1"
const DIR := "res://assets/clinica/"        # (the street's tile is the one drawn for the clinic opposite)

# its outline on the map (Catastro 4690001VJ5649S, part 3: the house's own first ring), in the ring's order
const G := Vector2(128.85, 81.10)
const H := Vector2(123.59, 81.17)
const I := Vector2(123.69, 78.77)
const J := Vector2(116.49, 78.83)            # where it ends on the Arcos
const A := Vector2(116.70, 74.14)            # the corner of Santa Ana and the Arcos
const B := Vector2(131.66, 73.67)            # where it ends on Santa Ana
const C := Vector2(131.59, 77.22)
const D := Vector2(133.73, 77.46)
const E := Vector2(133.60, 78.60)
const F := Vector2(128.91, 78.49)
const BACK: Array = [Vector2(128.66, 90.27), Vector2(123.29, 89.19), Vector2(123.46, 84.53), Vector2(128.78, 84.55)]      # (part 2: the back building, the house's second ring)

const TOP := 5.75                   # the top of the walls
const EAVE := 0.3
const PITCH := 0.33
const RISE0 := 0.1
const FOOT := 0.8                   # the rubble at its foot
const UP := 3.6                     # the sills of the windows above
const INDIGO := 0x2b3fb4
const BLIND := 0x8a5a3c
const PINE := 0xc98f52              # the gate's wood

var gate_spot: Vector2              # before the carriage gate, on Santa Ana (the self-test)
var door: Vector2                   # before the doorway of the Arcos
var openings := 0
var balconies := 0

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"cal":              # lime wash: it reads white on the front that never sees the sun, too
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.985, 0.94)), 0.32)
		"zocalo":           # the foot of dark rubble, its joints pale
			m = Tex.mat("stone_wall", Color(0.72, 0.68, 0.64))
		"placa_arcos":
			var tm := StandardMaterial3D.new()
			tm.albedo_texture = load(DIR + "placa_arcos.png")
			tm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			tm.roughness = 0.85
			m = tm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world, _hd: Dictionary) -> void:
	W = world
	var on := _outward(B, A)
	var ow := _outward(A, J)
	level = MapData.height((A + B) / 2.0 + on * 1.0)
	transform = Transform3D(Basis.IDENTITY, Vector3(0.0, level, 0.0))
	W.add_child(self)
	wall_top = TOP
	eave_out = EAVE
	roof_pitch = PITCH
	roof_rise0 = RISE0
	_planes = [[on, A.dot(on)], [ow, A.dot(ow)], [-on, H.dot(-on)]]      # the roof: a slope to each street, and one that falls to the yard
	_north()
	_west()
	for pair in [[G, H], [H, I], [I, J], [B, C], [C, D], [D, E], [E, F], [F, G]]:      # (what looks on its neighbours and on its own yard: plain white)
		_party_wall(pair[0], pair[1], "cal")
	_roof_over([G, H, I, J, A, B, C, D, E, F], [0.0, 0.0, 0.0, -EAVE, -EAVE, 0.0, 0.0, 0.0, 0.0, 0.0])
	_chimney(Vector2(130.6, 76.0))
	# the back building, across the yard: four plain walls, one slope of tiles
	var n2 := ((BACK[3] as Vector2) - (BACK[2] as Vector2)).normalized()
	n2 = Vector2(n2.y, -n2.x)
	_planes = [[n2, (BACK[2] as Vector2).dot(n2)]]
	for i in range(4):
		_party_wall(BACK[i], BACK[(i + 1) % 4], "cal")
	_roof_over(BACK, [0.0, 0.0, 0.0, 0.0])
	home()
	_commit()
	_ring_solids([G, H, I, J, A, B, C, D, E, F], 9.0)
	_ring_solids(BACK, 9.0)
	gate_spot = _along(B, A, 1.88) + on * 1.2
	door = _along(A, J, 3.87) + ow * 1.2

# ---------------- what the fronts share ----------------
## how high the ground is before a spot of a front (this frame's y)
func _g(a: Vector2, b: Vector2, x: float) -> float:
	var p := _along(a, b, x) + _outward(a, b) * 0.5
	return ground(p.x, p.y)

## the rubble at the foot of a stretch of the front being built (a..b: its ends on the map), following the ground
func _rubble(a: Vector2, b: Vector2, x0: float, x1: float) -> void:
	var n := maxi(1, int(ceil((x1 - x0) / 2.0)))
	for i in range(n):
		var xa := lerpf(x0, x1, float(i) / n)
		var xb := lerpf(x0, x1, float(i + 1) / n)
		plinth(xa, xb, _g(a, b, xa) + FOOT, _g(a, b, xb) + FOOT, "zocalo", 0.05, -1.0)

## an indigo band round an opening on the front being built: its jambs and, with `lintel`, its head
func _indigo(r: Rect2, w: float, lintel := true) -> void:
	box(r.position.x - w, r.position.y, 0.0, w, r.size.y + (w if lintel else 0.0), 0.012, INDIGO)
	box(r.end.x, r.position.y, 0.0, w, r.size.y + (w if lintel else 0.0), 0.012, INDIGO)
	if lintel:
		box(r.position.x, r.end.y, 0.0, r.size.x, w, 0.012, INDIGO)

## the inside of an opening painted indigo (its jambs and head, as deep as the wall)
func _indigo_reveal(r: Rect2) -> void:
	box(r.position.x, r.position.y, -DEEP + 0.07, 0.014, r.size.y, DEEP - 0.07, INDIGO)
	box(r.end.x - 0.014, r.position.y, -DEEP + 0.07, 0.014, r.size.y, DEEP - 0.07, INDIGO)
	box(r.position.x, r.end.y - 0.014, -DEEP + 0.07, r.size.x, 0.014, DEEP - 0.07, INDIGO)

## a window in its hole: brown wooden frame, its brown blind down `blind` of it; with `bars`, a black grille before it
func _window(r: Rect2, blind: float, bars: bool) -> void:
	openings += 1
	window(r, 0x6a4630, 0x1f2a33, 1)
	_indigo_reveal(r)
	if blind > 0.0:
		var drop := r.size.y * blind
		box(r.position.x + 0.03, r.end.y - drop, -0.11, r.size.x - 0.06, drop, 0.025, BLIND)
		for i in range(1, int(drop / 0.085)):
			box(r.position.x + 0.03, r.end.y - i * 0.085, -0.085, r.size.x - 0.06, 0.012, 0.005, 0x71482f)
	box(r.position.x - 0.05, r.position.y - 0.05, 0.0, r.size.x + 0.1, 0.05, 0.07, 0xe8e4da)      # (its sill)
	if bars:
		grille(r, 0.14, IRON)

## a little iron balcony on a window's sill: a rail, a low one, uprights, a row of rings between them
func _balconet(r: Rect2) -> void:
	balconies += 1
	var x0 := r.position.x - 0.14
	var x1 := r.end.x + 0.14
	var y := r.position.y
	var out := 0.2
	box(x0, y - 0.06, 0.0, x1 - x0, 0.05, out + 0.03, 0xe8e4da)
	box(x0, y + 0.36, out - 0.02, x1 - x0, 0.03, 0.03, IRON)
	box(x0, y + 0.02, out - 0.015, x1 - x0, 0.02, 0.02, IRON)
	var n := maxi(3, int((x1 - x0) / 0.22))
	for k in range(n + 1):
		box(lerpf(x0, x1 - 0.016, float(k) / n), y + 0.02, out - 0.014, 0.016, 0.36, 0.016, IRON)
	for k in range(n):                                             # (the rings: a diamond in each bay)
		var a := lerpf(x0, x1, float(k) / n) + 0.012
		var b := lerpf(x0, x1, float(k + 1) / n) - 0.002
		var m := (a + b) / 2.0
		for q in [[a, 0.2, m, 0.34], [m, 0.34, b, 0.2], [b, 0.2, m, 0.06], [m, 0.06, a, 0.2]]:
			bar(Vector3(q[0], y + float(q[1]), out - 0.006), Vector3(q[2], y + float(q[3]), out - 0.006), 0.012, 0.012, IRON)
	for x in [x0, x1 - 0.02]:
		box(x, y + 0.36, 0.0, 0.02, 0.03, out, IRON)
		box(x, y + 0.02, 0.0, 0.02, 0.02, out, IRON)

## the cornice over the front being built: white mouldings stepping out, the mouths of the tiles on them (e0, e1: how
## much further it runs to turn the corner)
func _cornice(ln: float, e0: float, e1: float) -> void:
	box(-e0 * 0.08, TOP - 0.34, 0.0, ln + (e0 + e1) * 0.08, 0.14, 0.08, "cal")
	box(-e0 * 0.16, TOP - 0.2, 0.0, ln + (e0 + e1) * 0.16, 0.12, 0.16, "cal")
	box(-e0 * 0.24, TOP - 0.08, 0.0, ln + (e0 + e1) * 0.24, 0.1, 0.24, "cal")
	var n := maxi(2, int(round(ln / 0.24)))
	for i in range(n):                                             # (the mouths of the tiles, one beside another)
		drum(Vector3(ln * (i + 0.5) / n, TOP + 0.0, 0.2), 0.085, 0.085, 0.09, 0xa8623f, 6)

# ---------------- the front to the Calle de Santa Ana (north) ----------------
func _north() -> void:
	var L := face(B, A)                                           # (x from its east end, as seen from the street)
	var e1 := _miter(_outward(B, A), _outward(A, J), 1.0)
	var gate := Rect2(1.1, _g(B, A, 1.88) - 0.4, 1.55, 2.45 + 0.4)
	var w1 := Rect2(3.12, _g(B, A, 3.6) + 0.85, 1.03, 1.15)
	var w2 := Rect2(6.38, _g(B, A, 6.95) + 0.8, 1.14, 1.3)
	var ups: Array = [Rect2(1.65, UP, 0.95, 0.82), Rect2(4.05, UP, 0.95, 0.82), Rect2(6.62, UP + 0.02, 1.26, 0.86)]
	masonry(0.0, L, -1.0, TOP, [gate, w1, w2] + ups, [], "cal")
	_rubble(B, A, 0.0, gate.position.x - 0.14)
	_rubble(B, A, gate.end.x + 0.14, L + e1 * 0.05)
	_gate(gate)
	_window(w1, 1.0, true)
	_window(w2, 1.0, true)
	var blinds := [0.8, 0.85, 0.45]
	for i in range(ups.size()):
		var r: Rect2 = ups[i]
		_window(r, blinds[i], false)
		_indigo(r, 0.09)
		_balconet(r)
	# the two cables along it, their drop between the second window and the third; the plate beside the gate
	for q in [[3.08, 0.5, L - 0.3], [2.72, 5.6, L - 0.3]]:
		var n := 14
		for k in range(n):
			var xa := lerpf(float(q[1]), float(q[2]), float(k) / n)
			var xb := lerpf(float(q[1]), float(q[2]), float(k + 1) / n)
			bar(Vector3(xa, float(q[0]) - 0.03 * sin(PI * (k % 2)), 0.03), Vector3(xb, float(q[0]) - 0.03 * sin(PI * ((k + 1) % 2)), 0.03), 0.028, 0.028, 0xd8d4c8)
	box(5.6, 2.72, 0.0, 0.03, 2.5, 0.03, 0xd8d4c8)
	box(2.2, 3.05, 0.0, 0.3, 0.3, 0.012, 0xf4f2ec)                     # (a blank tile over the gate)
	# the render gone over the foot, towards the corner: the old wall under it
	for q in [[9.4, 1.5, 0.34], [11.8, 2.0, 0.24], [8.5, 0.6, 0.18]]:
		var gx := _g(B, A, float(q[0])) + FOOT
		slab(PackedVector2Array([Vector2(q[0], gx), Vector2(float(q[0]) + float(q[1]), gx), Vector2(float(q[0]) + float(q[1]) * 0.8, gx + float(q[2]) * 0.7),
			Vector2(float(q[0]) + float(q[1]) * 0.45, gx + float(q[2])), Vector2(float(q[0]) + float(q[1]) * 0.15, gx + float(q[2]) * 0.6)]), 0.006, 0.0, 0xb3a492)
	_cornice(L, 0.0, e1)
	home()

## The carriage gate on Santa Ana: two leaves of pale boards studded with black nails, a wicket in the right one, a
## grille of turned wooden bars across their top; indigo jambs.
func _gate(r: Rect2) -> void:
	openings += 1
	var z := -DEEP + 0.1
	var foot := r.position.y + 0.4                                 # (the ground before it)
	box(r.position.x, r.position.y, -DEEP, r.size.x, 0.4 + 0.03, DEEP, 0x8a8680)
	box(r.position.x, foot, z - 0.05, r.size.x, r.end.y - foot, 0.04, 0x8a5c30)
	var top := r.end.y - 0.42                                      # (where the grille begins)
	var n := 10
	for i in range(n):                                             # (the boards)
		box(r.position.x + r.size.x * i / n + 0.006, foot + 0.02, z - 0.012, r.size.x / n - 0.012, top - foot - 0.02, 0.03, PINE if i % 2 == 0 else 0xc0864a)
	box(r.position.x, top, z - 0.012, r.size.x, 0.07, 0.045, 0xb07a40)
	box(r.position.x, r.end.y - 0.07, z - 0.012, r.size.x, 0.07, 0.045, 0xb07a40)
	for i in range(14):                                            # (the turned bars of the grille)
		var x := r.position.x + 0.06 + (r.size.x - 0.12) * i / 13.0
		box(x - 0.016, top + 0.07, z, 0.032, r.end.y - top - 0.14, 0.032, 0xb88448)
		box(x - 0.024, top + 0.17, z - 0.004, 0.048, 0.06, 0.04, 0xb88448)
	box(r.get_center().x - 0.02, foot, z - 0.012, 0.04, r.end.y - foot, 0.05, 0xa87238)       # (where the leaves meet)
	studs(r.position.x + 0.1, r.end.x - 0.1, foot + 0.3, top - 0.2, z + 0.02, 8, 6, 0x1c1c1e)
	box(r.end.x - 0.36, foot + 0.95, z + 0.02, 0.05, 0.16, 0.03, 0x1c1c1e)                     # (the latch and the knocker)
	box(r.end.x - 0.6, foot + 1.25, z + 0.02, 0.06, 0.06, 0.03, 0xd8d0c0)
	_indigo(Rect2(r.position.x, foot, r.size.x, r.end.y - foot), 0.13, false)

# ---------------- the front to the Calle de los Arcos (west) ----------------
func _west() -> void:
	var L := face(A, J)                                           # (x from the corner, as seen from the street)
	var e0 := _miter(_outward(B, A), _outward(A, J), 1.0)
	var win := Rect2(0.99, _g(A, J, 1.7) + 0.75, 1.37, 1.35)
	var gate := Rect2(3.23, _g(A, J, 3.87) - 0.4, 1.28, 2.15 + 0.4)
	var up := Rect2(1.75, UP + 0.2, 1.27, 0.9)
	masonry(0.0, L, -1.0, TOP, [win, gate, up], [], "cal")
	_rubble(A, J, -e0 * 0.05, gate.position.x - 0.12)
	_rubble(A, J, gate.end.x + 0.12, L)
	_window(win, 0.55, true)
	# the doorway: a dark hall behind a purple curtain, indigo jambs
	openings += 1
	var foot := gate.position.y + 0.4
	box(gate.position.x, gate.position.y, -DEEP, gate.size.x, 0.4 + 0.04, DEEP, 0x8a8680)
	box(gate.position.x, foot + 0.04, -DEEP - 0.02, gate.size.x, gate.end.y - foot - 0.04, 0.02, 0x241c18)
	var n := 12
	for i in range(n):
		var a := lerpf(gate.position.x + 0.03, gate.end.x - 0.03, float(i) / n)
		var b := lerpf(gate.position.x + 0.03, gate.end.x - 0.03, float(i + 1) / n)
		var za := -0.2 + (0.03 if i % 2 == 0 else -0.01)
		var zb := -0.2 + (-0.01 if i % 2 == 0 else 0.03)
		pieces += 1
		quad(Vector3(a, foot + 0.06, za), Vector3(b, foot + 0.06, zb), Vector3(b, gate.end.y - 0.04, zb), Vector3(a, gate.end.y - 0.04, za), 0x7c2f5c if i % 2 == 0 else 0x6e2850, Vector3(0, 0, 1))
	_indigo(Rect2(gate.position.x, foot, gate.size.x, gate.end.y - foot), 0.1, true)
	_window(up, 0.9, false)
	_indigo(up, 0.09)
	_balconet(up)
	_picture(0.2, 0.68, 2.95, 2.95 + 0.48 * 280.0 / 360.0, 0.012, "placa_arcos")
	_cornice(L, e0, 0.0)
	home()

## the tall white chimney on its roof, under a little cap of tiles
func _chimney(at: Vector2) -> void:
	home()
	var y := _roof_y(at)
	box(at.x - 0.28, y - 0.4, at.y - 0.28, 0.56, 2.2, 0.56, "cal")
	box(at.x - 0.36, y + 1.8, at.y - 0.36, 0.72, 0.08, 0.72, "cal")
	for k in range(2):
		box(at.x - 0.3 + k * 0.42, y + 1.88, at.y - 0.3, 0.18, 0.3, 0.6, "cal")
	box(at.x - 0.42, y + 2.18, at.y - 0.42, 0.84, 0.07, 0.84, 0xa8623f)
	box(at.x - 0.26, y + 2.25, at.y - 0.26, 0.52, 0.07, 0.52, 0xa8623f)
