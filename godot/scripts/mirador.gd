extends "res://scripts/esquina.gd"
## The cream house with the bay window on the corner of the Avenida de la Constitución and the Calle de Santa Ana, at
## the crossroads of the traffic lights (the one the tall arm of the traffic light stands before). The user, 22 November
## 2026, after the white house opposite: "No se pone Azafrán. Visto Bueno. Siguiente". Built by hand from Street View
## (November 2024: tools/cruce/capturas.py, the f_ pictures) on the house `constitucion_2` of the map (casas_calles.gd
## marks it "obra"), with no rebake; referencias/cruce/LEEME.md.
##
## A house of 1925, two tall floors over a half-sunk one, 8.3 m to its cornice: cream render, its foot, its frames,
## its balconies and its cornice in ochre.
##   - on the corner's cut: the door behind a brown curtain in an ochre frame, up a step; over it the bay window, a
##     closed box on stepped mouldings with a white blind and a black bar across it;
##   - to the avenue (west, 10.3 m): three windows behind black grilles in ochre frames, the vents of the half-sunk
##     floor in the foot under them, the street's tile; above, a balcony with a solid parapet and a black rail before
##     two doors, and a window with two bars;
##   - to Santa Ana (south): two more barred windows under another such balcony, the street's tile; past them the
##     house's east part, white: a round-arched carriage gate of studded wood in an ochre arch, a gallery of wooden
##     windows over it.
## Nobody gets in. No saffron hidden here (one is proposed for each place and the user says whether it goes in).
##
## Frame: the map's own (x east, z south), y = 0 the pavement before the corner's cut. Each front is built in its own
## frame (obra.face). The roof, the shared walls and the solids are esquina.gd's.

const HOUSE := "constitucion_2"

# its outline on the map (Catastro 4491809VJ5649S: the house's own ring), in the ring's order
const C1 := Vector2(117.97, 57.91)           # the corner's cut: its end on the avenue...
const N := Vector2(118.50, 47.62)            # where it ends on the avenue
const NE := Vector2(131.34, 47.37)
const P1 := Vector2(130.91, 51.61)           # round its yard, open to the east
const P2 := Vector2(124.45, 51.50)
const P3 := Vector2(124.02, 56.79)
const P4 := Vector2(130.21, 58.38)
const E := Vector2(129.63, 63.93)            # where it ends on Santa Ana
const C2 := Vector2(120.12, 61.46)           # ...and the cut's end on Santa Ana

const TOP := 8.3                    # the top of the walls (the cornice's)
const EAVE := 0.2
const PITCH := 0.3
const RISE0 := 0.06
const FOOT := 1.0                   # the ochre foot
const SILL := 1.8                   # the sills of the windows below (the floor is raised over a half-sunk one)
const HEAD := 3.5
const F1 := 4.2                     # the floor above: the balconies' floor
const DOOR_H := 3.0                 # how tall the balconies' doors are
const EAST := 6.44                  # on Santa Ana, where the cream house ends and its white east part begins
const BLIND := 0xeeece4
const WOOD := 0x7a5236              # the east part's gate and gallery

var door: Vector2                   # before the door on the corner's cut (the self-test)
var gate_spot: Vector2              # before the carriage gate on Santa Ana
var openings := 0
var balconies := 0

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	var name_ := String(key) if key is String else ""
	match name_:
		"crema":            # the render (Street View 2024: about 240, 228, 200)
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.94, 0.78)), 0.28)
		"ocre":             # its foot, its frames, its balconies, its cornice
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.9, 0.72, 0.52)), 0.16)
		"cal":              # the east part: lime wash
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.985, 0.94)), 0.32)
		"medianera":
			m = Tex.mat("painted_plaster_wall", Color(0.8, 0.76, 0.68))
		"losa":             # the pavement before it (the town's own)
			m = W._tmat(0xcfc9be, "pavement", 1.4)
		"placa_avenida", "placa_santa_ana":
			var tm := StandardMaterial3D.new()
			tm.albedo_texture = load(("res://assets/sopiss/" if name_ == "placa_avenida" else "res://assets/clinica/") + name_ + ".png")
			tm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			tm.roughness = 0.85
			m = tm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world, _hd: Dictionary) -> void:
	W = world
	var ow := _outward(N, C1)
	var oc := _outward(C1, C2)
	var os := _outward(C2, E)
	level = MapData.height((C1 + C2) / 2.0 + oc * 1.0)
	transform = Transform3D(Basis.IDENTITY, Vector3(0.0, level, 0.0))
	W.add_child(self)
	wall_top = TOP
	eave_out = EAVE
	roof_pitch = PITCH
	roof_rise0 = RISE0
	var d_n := (NE - N).normalized()
	var o_n := Vector2(d_n.y, -d_n.x)                         # (north: the wall it shares at its back)
	var o_e := Vector2(-o_n.y, o_n.x)                         # (east)
	_planes = [[ow, C1.dot(ow)], [os, C2.dot(os)], [oc, C1.dot(oc)], [o_n, N.dot(o_n)], [o_e, NE.dot(o_e)]]      # the roof: a slope to each front and to each wall behind
	_west()
	_cut()
	_south()
	for pair in [[N, NE], [NE, P1], [P1, P2], [P2, P3], [P3, P4], [P4, E]]:
		_party_wall(pair[0], pair[1])
	_roof_over([C1, N, NE, P1, P2, P3, P4, E, C2], [-EAVE, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -EAVE, -EAVE])
	# the pavement before the corner and along Santa Ana, up to its walls (the town's stops short of them and bare earth showed)
	var apron := PackedVector2Array([C1])                            # (each point runs out from the wall as far as the kerb, no further: the roadway comes close on the avenue side)
	for t in [0.0, 0.5, 1.0]:
		var c: Vector2 = C1.lerp(C2, t)
		apron.append(c + oc * _to_kerb(c, oc, 3.2))
	var oo: Vector2 = (oc + os).normalized()
	apron.append(C2 + oo * _to_kerb(C2, oo, 3.6))
	for i in 6:
		var c: Vector2 = C2.lerp(E, float(i) / 5.0)
		apron.append(c + os * _to_kerb(c, os, 3.2))
	apron.append(E)
	apron.append(C2)
	var lift := -10.0
	for q in apron:
		lift = maxf(lift, MapData.height(q) - level)
		yard.append(q)                                               # (the self-test: none of it on the asphalt)
	flat(apron, lift + 0.025, "losa")
	home()
	_commit()
	_ring_solids([C1, N, NE, P1, P2, P3, P4, E, C2], 11.0)
	door = _along(C1, C2, 2.08) + oc * 1.3
	gate_spot = _along(C2, E, 8.25) + os * 1.3

## How far a pavement can run out from `p` along `dir` before it meets the asphalt (never more than `cap` metres).
func _to_kerb(p: Vector2, dir: Vector2, cap: float) -> float:
	var s := 0.0
	while s + 0.1 <= cap:
		var q := p + dir * (s + 0.1)
		var d: float = MapData.road_edge_dist(q)
		if MapData.road_hit != null:
			d += MapData.road_hit.hw - MapData.fitted_hw(MapData.road_hit)
		if d < 0.06:
			break
		s += 0.1
	return s

# ---------------- what the fronts share ----------------
## the ochre foot of a stretch of the front being built
func _foot(x0: float, x1: float) -> void:
	box(x0, -0.9, 0.0, x1 - x0, 0.9 + FOOT, 0.05, "ocre")

## the cornice over a stretch of the front being built: ochre mouldings stepping out (e0, e1: how much further it runs
## to turn the corner, per metre of standing out)
func _cornice(x0: float, x1: float, e0: float, e1: float) -> void:
	for q in [[0.62, 0.14, 0.06], [0.48, 0.26, 0.15], [0.22, 0.3, 0.26]]:
		box(x0 - e0 * float(q[2]), TOP - float(q[0]), 0.0, x1 - x0 + (e0 + e1) * float(q[2]), float(q[1]), float(q[2]), "ocre")

## A window of the floor below in its hole, behind its black grille: dark frame, a white blind half down, an ochre
## frame round it; under it, in the foot, the vent of the half-sunk floor.
func _barred(r: Rect2, vent := true) -> void:
	openings += 1
	window(r, 0x4a3a30, 0x1f2a33, 1)
	box(r.position.x + 0.03, r.end.y - r.size.y * 0.55, -0.12, r.size.x - 0.06, r.size.y * 0.55, 0.025, BLIND)
	stone_frame(r, 0.17, 0.045, "ocre")
	grille(r, 0.15, IRON)
	for k in range(int(r.size.x / 0.2)):                         # (the scrolls at the grille's foot: a row of rings)
		box(r.position.x + 0.05 + k * 0.2, r.position.y + 0.02, 0.14, 0.12, 0.2, 0.012, IRON)
	if vent:
		var cx := r.get_center().x
		box(cx - 0.45, 0.16, 0.05, 0.9, 0.5, 0.012, 0x16161a)
		for k in range(6):
			box(cx - 0.42 + k * 0.165, 0.16, 0.06, 0.03, 0.5, 0.02, IRON)
		for y in [0.16, 0.63]:
			box(cx - 0.47, y, 0.05, 0.94, 0.035, 0.03, IRON)

## a door or window of the floor above in its hole: white frame and blind, an ochre frame round it
func _upper(r: Rect2, blind: float, bars := 0) -> void:
	openings += 1
	var z := -DEEP + 0.08
	box(r.position.x, r.position.y, z - 0.05, r.size.x, r.size.y, 0.03, 0x1f2a33)
	for q in [[r.position.x, r.position.y, 0.07, r.size.y], [r.end.x - 0.07, r.position.y, 0.07, r.size.y], [r.position.x, r.end.y - 0.07, r.size.x, 0.07]]:
		box(q[0], q[1], z - 0.02, q[2], q[3], 0.06, 0xf4f2ec)
	var drop := r.size.y * blind
	box(r.position.x + 0.03, r.end.y - drop, -0.11, r.size.x - 0.06, drop, 0.025, BLIND)
	for i in range(1, int(drop / 0.1)):
		box(r.position.x + 0.03, r.end.y - i * 0.1, -0.085, r.size.x - 0.06, 0.012, 0.005, 0xd6d4cc)
	stone_frame(r, 0.15, 0.04, "ocre")
	for k in range(bars):
		box(r.position.x - 0.2, r.position.y + 0.25 + k * 0.3, 0.08, r.size.x + 0.4, 0.03, 0.03, IRON)
		for x in [r.position.x - 0.2, r.end.x + 0.17]:
			box(x, r.position.y + 0.25 + k * 0.3, 0.0, 0.03, 0.03, 0.08, IRON)

## A balcony with a solid parapet on the front being built: an ochre slab on two brackets, the parapet, a black rail
## on little posts over it.
func _parapet_balcony(x0: float, x1: float) -> void:
	balconies += 1
	var out := 0.75
	box(x0, F1 - 0.22, 0.0, x1 - x0, 0.22, out, "ocre")
	box(x0 + 0.05, F1 - 0.34, 0.0, x1 - x0 - 0.1, 0.12, out - 0.12, "ocre")
	for x in [x0 + 0.12, x1 - 0.34]:                               # (its brackets)
		box(x, F1 - 0.62, 0.0, 0.22, 0.3, out - 0.3, "ocre")
		box(x, F1 - 0.8, 0.0, 0.22, 0.18, out - 0.5, "ocre")
	box(x0, F1, out - 0.14, x1 - x0, 0.92, 0.14, "ocre")
	box(x0 - 0.02, F1 + 0.92, out - 0.17, x1 - x0 + 0.04, 0.07, 0.2, "ocre")
	for x in [x0, x1 - 0.14]:
		box(x, F1, 0.0, 0.14, 0.92, out - 0.14, "ocre")
		box(x - 0.02, F1 + 0.92, 0.0, 0.18, 0.07, out - 0.14, "ocre")
	var n := maxi(2, int((x1 - x0) / 1.2))
	for k in range(n + 1):
		box(lerpf(x0 + 0.05, x1 - 0.08, float(k) / n), F1 + 0.99, out - 0.08, 0.03, 0.2, 0.03, IRON)
	box(x0 + 0.04, F1 + 1.19, out - 0.085, x1 - x0 - 0.08, 0.035, 0.04, IRON)

# ---------------- the front to the avenue (west) ----------------
func _west() -> void:
	var L := face(N, C1)                                          # (x from its north end, as seen from the avenue)
	var e1 := _miter(_outward(N, C1), _outward(C1, C2), 1.0)
	var lows: Array = [Rect2(1.6, SILL, 1.36, HEAD - SILL), Rect2(4.72, SILL, 1.2, HEAD - SILL), Rect2(7.16, SILL, 1.32, HEAD - SILL)]
	var ups: Array = [Rect2(1.74, F1 + 1.0, 1.19, 2.0), Rect2(4.77, F1, 1.2, DOOR_H), Rect2(7.13, F1, 1.2, DOOR_H)]
	masonry(0.0, L, -0.9, TOP, lows + ups, [], "crema")
	_foot(0.0, L + e1 * 0.05)
	for r: Rect2 in lows:
		_barred(r)
	_upper(ups[0], 0.9, 2)
	_upper(ups[1], 0.75)
	_upper(ups[2], 0.8)
	_parapet_balcony(4.44, 9.33)
	_picture(8.74, 9.22, 2.86, 2.86 + 0.48 * 280.0 / 360.0, 0.012, "placa_avenida")
	for k in range(10):                                          # (the cables along it, under the balconies)
		var xa := L * k / 10.0
		var xb := L * (k + 1) / 10.0
		bar(Vector3(xa, F1 - 0.42 - 0.04 * sin(PI * (k % 2)), 0.035), Vector3(xb, F1 - 0.42 - 0.04 * sin(PI * ((k + 1) % 2)), 0.035), 0.03, 0.03, 0x2a2a2c)
	_cornice(0.0, L, 0.0, e1)
	home()

# ---------------- the corner's cut ----------------
func _cut() -> void:
	var L := face(C1, C2)
	var e0 := _miter(_outward(N, C1), _outward(C1, C2), 1.0)
	var e1 := _miter(_outward(C1, C2), _outward(C2, E), 1.0)
	var dr := Rect2(1.33, -0.3, 1.5, 2.85 + 0.3)
	masonry(0.0, L, -0.9, TOP, [dr], [], "crema")
	_foot(-e0 * 0.05, dr.position.x - 0.22)
	_foot(dr.end.x + 0.22, L + e1 * 0.05)
	# the door: a step of stone, a dark hall behind a brown curtain, an ochre frame
	openings += 1
	box(dr.position.x - 0.22, -0.3, -DEEP, dr.size.x + 0.44, 0.3 + 0.16, DEEP + 0.25, 0x9a968c)
	box(dr.position.x, 0.16, -DEEP - 0.02, dr.size.x, dr.end.y - 0.16, 0.02, 0x241c18)
	var n := 12
	for i in range(n):
		var a := lerpf(dr.position.x + 0.03, dr.end.x - 0.03, float(i) / n)
		var b := lerpf(dr.position.x + 0.03, dr.end.x - 0.03, float(i + 1) / n)
		var za := -0.2 + (0.03 if i % 2 == 0 else -0.01)
		var zb := -0.2 + (-0.01 if i % 2 == 0 else 0.03)
		pieces += 1
		quad(Vector3(a, 0.2, za), Vector3(b, 0.2, zb), Vector3(b, dr.end.y - 0.04, zb), Vector3(a, dr.end.y - 0.04, za), 0x9a6a48 if i % 2 == 0 else 0x8c5e40, Vector3(0, 0, 1))
	box(dr.position.x - 0.22, 0.16, 0.0, 0.22, dr.end.y - 0.16 + 0.22, 0.05, "ocre")
	box(dr.end.x, 0.16, 0.0, 0.22, dr.end.y - 0.16 + 0.22, 0.05, "ocre")
	box(dr.position.x, dr.end.y, 0.0, dr.size.x, 0.22, 0.05, "ocre")
	# the bay window over it: a closed box on stepped mouldings, a white blind in an ochre frame, a black bar across it
	balconies += 1
	var x0 := 0.85
	var x1 := 3.3
	var out := 0.7
	box(x0 + 0.3, F1 - 0.2, 0.0, x1 - x0 - 0.6, 0.16, out - 0.4, "ocre")
	box(x0 + 0.15, F1 - 0.04, 0.0, x1 - x0 - 0.3, 0.16, out - 0.2, "ocre")
	box(x0 - 0.04, F1 + 0.12, 0.0, x1 - x0 + 0.08, 0.2, out + 0.04, "ocre")
	box(x0, F1 + 0.32, 0.0, x1 - x0, 2.75, out, "crema")
	box(x0 - 0.05, F1 + 3.07, 0.0, x1 - x0 + 0.1, 0.18, out + 0.05, "ocre")
	var w := Rect2(x0 + 0.42, F1 + 0.75, x1 - x0 - 0.84, 1.85)
	openings += 1
	box(w.position.x, w.position.y, out, w.size.x, w.size.y, 0.012, BLIND)
	for i in range(1, int(w.size.y / 0.1)):
		box(w.position.x, w.end.y - i * 0.1, out + 0.012, w.size.x, 0.012, 0.004, 0xd6d4cc)
	for q in [[w.position.x - 0.13, w.position.y - 0.13, 0.13, w.size.y + 0.26], [w.end.x, w.position.y - 0.13, 0.13, w.size.y + 0.26], [w.position.x, w.end.y, w.size.x, 0.13], [w.position.x, w.position.y - 0.13, w.size.x, 0.13]]:
		box(q[0], q[1], out, q[2], q[3], 0.035, "ocre")
	box(w.position.x - 0.2, w.position.y + 0.45, out + 0.07, w.size.x + 0.4, 0.035, 0.035, IRON)
	for x in [w.position.x - 0.2, w.end.x + 0.165]:
		box(x, w.position.y + 0.45, out, 0.035, 0.035, 0.07, IRON)
	for x in [x0, x1 - 0.012]:                                     # (a narrow blind in each of its sides)
		box(x - (0.012 if x == x0 else -0.012), F1 + 0.85, 0.16, 0.012, 1.6, out - 0.32, BLIND)
	_cornice(0.0, L, e0, e1)
	home()

# ---------------- the front to the Calle de Santa Ana (south) ----------------
func _south() -> void:
	var L := face(C2, E)                                          # (x from the corner's cut, as seen from the street)
	var e0 := _miter(_outward(C1, C2), _outward(C2, E), 1.0)
	var lows: Array = [Rect2(2.0, SILL, 1.25, HEAD - SILL), Rect2(4.47, SILL, 1.3, HEAD - SILL)]
	var ups: Array = [Rect2(2.03, F1, 1.2, DOOR_H), Rect2(4.52, F1, 1.2, DOOR_H)]
	var cx := 8.2                                                 # the carriage gate's middle...
	var r := 1.3                                                  # ...its half width...
	var spring := 2.35                                            # ...and where its arch begins
	var arch := Rect2(cx - r, -0.3, 2.0 * r, spring + r + 0.3)
	var gallery := Rect2(6.95, 5.25, 2.5, 1.4)
	masonry(0.0, EAST, -0.9, TOP, lows + ups, [], "crema")
	masonry(EAST, L, -0.9, TOP, [arch, gallery], [], "cal")
	_foot(-e0 * 0.05, EAST)
	for q: Rect2 in lows:
		_barred(q)
	_upper(ups[0], 0.8)
	_upper(ups[1], 0.7)
	_parapet_balcony(1.3, 6.2)
	_picture(0.26, 0.74, 3.62, 3.62 + 0.48 * 280.0 / 360.0, 0.012, "placa_santa_ana")
	_cornice(0.0, EAST, e0, 0.0)
	# the east part: the round-arched gate in its ochre arch, the gallery of wooden windows over it, a plain cornice
	openings += 1
	spandrels(cx, spring, r, 0.0, "cal")
	ring(cx, spring, r, r + 0.24, 0.04, 0.05, "ocre")
	for x in [cx - r - 0.24, cx + r]:
		box(x, -0.9, 0.0, 0.24, 0.9 + spring, 0.04, "ocre")
	box(arch.position.x, -0.3, -DEEP, arch.size.x, 0.3 + 0.03, DEEP, 0x8a8680)
	arched(cx, 0.03, spring, r, -DEEP + 0.08, WOOD)
	box(cx - 0.025, 0.03, -DEEP + 0.085, 0.05, spring + r - 0.05, 0.03, 0x5e3e28)
	studs(cx - r + 0.18, cx + r - 0.18, 0.4, spring - 0.1, -DEEP + 0.1, 9, 6, 0x1c1c1e)
	box(cx + 0.14, 0.5, -DEEP + 0.09, 0.62, 1.75, 0.012, 0x6a4630)                         # (the wicket in its right leaf)
	openings += 1
	box(gallery.position.x, gallery.position.y, -DEEP + 0.05, gallery.size.x, gallery.size.y, 0.03, 0x2a343c)
	for k in range(5):
		box(gallery.position.x + (gallery.size.x - 0.08) * k / 4.0, gallery.position.y, -DEEP + 0.07, 0.08, gallery.size.y, 0.08, WOOD)
	for y in [gallery.position.y, gallery.position.y + 0.42, gallery.end.y - 0.08]:
		box(gallery.position.x, y, -DEEP + 0.07, gallery.size.x, 0.08, 0.08, WOOD)
	box(gallery.position.x - 0.1, gallery.position.y - 0.1, 0.0, gallery.size.x + 0.2, 0.1, 0.1, WOOD)
	box(EAST, TOP - 0.34, 0.0, L - EAST, 0.14, 0.08, "cal")
	box(EAST, TOP - 0.2, 0.0, L - EAST, 0.22, 0.16, "cal")
	for i in range(int((L - EAST) / 0.24)):
		drum(Vector3(EAST + 0.12 + i * 0.24, TOP + 0.0, 0.14), 0.085, 0.085, 0.09, 0xa8623f, 6)
	home()
