extends "res://scripts/obra.gd"
## The Travesía del Clavel, the alley between the Calle de San Rafael (south) and the Calle del Clavel (north): a walk
## for people on foot, raised over both streets on the roof of the garage its two rows of houses share (the user, 21
## November 2026: "Tiene dos accesos, el de la escalera de la calle clavel y el de la rampa de la calle san Rafael",
## and then "De acuerdo, que sea peatonal y con las cosas que has dicho. Que se ponga Petril con eso cuando termine con
## el Rice"). Built by hand from the user's two pictures, Street View from both ends (November 2024) and the aerial
## photo; referencias/travesia_clavel/, tools/travesia/.
##
## What is here:
##   - the walk, paved in chequers of cream and dull red, sloping up gently northwards as the ground does, a metre and
##     more over it; level with it the houses' doors, each up two to four steps on a little landing behind a railing of
##     wrought iron (the east row is Texturas's: tcl_4 to tcl_20);
##   - by San Rafael, three ramps going to and fro across the alley between white walls with their vents and their
##     railings of steel tube;
##   - by the Clavel, the chequered stairs along the white house, the lane of grooved concrete that goes in under the
##     walk to the garage, and the narrow stair of the east row's terrace;
##   - the west row, ochre over a dull red foot (Catastro has it as a strip 1.4 to 5 m short of the alley: the aerial
##     photo has its front 7 m from the east row's all the way), and the white house on the corner of the Clavel with
##     its foot of flat stones and its garage door.
## The bake makes the street a footpath that this script floors ("paved": 5) and does not raise Catastro's strip.
## A saffron flower is hidden behind the first bench of the walk (the user: one in every special place).
##
## Frame: origin at the south end of the east row's front (the corner house's corner on San Rafael); x north along that
## front (s), z east; the alley is z from -WIDE to 0 (t, how far west of the east row, is -z). y = 0 is the walk at
## s = 0; it rises SLOPE to the metre.

const READY := true
const O := Vector2(140.56, -160.80)
const U := Vector2(0.19084, -0.98162)
const LEN := 62.67                              # the east row's front, from San Rafael to the Clavel
const WIDE := 7.0                               # from the east row's front to the west row's
const SLOPE := 0.0239                           # how much the walk rises to the metre, northwards
const UNDER := 0.30                             # the walk is this far under the sill of the first door (tcl_4's)
const DOWN := -4.5
const FRONT := 4.8                              # where the walk begins, over the ramps
const RUNS: Array = [[0.45, 1.75], [1.9, 3.2], [3.35, 4.65]]       # the three ramps (s)
const EAST_L := 0.15                            # the ramps' east and west ends (t)
const WEST_L := 6.85
const LAND := 1.3                               # their landings
const LANE_S := 54.5                            # where the garage's lane goes in under the walk
const LANE: Array = [1.5, 4.3]                  # ...and its two sides (t)
const FOOT_N := 62.7                            # the foot of the stairs, on the Clavel
const ROW: Array = [0.95, 52.9]                 # the west row (s)
const BACK: Array = [13.4, 16.5]                # ...its back at each end (t)
const WHITE_N := 63.2                           # the white house's corner on the Clavel
const WHITE_W := 12.4                           # ...and how far west it goes
const DOORS := {"tcl_4": 0.88, "tcl_6": 0.12, "tcl_8": 0.88, "tcl_10": 0.12, "tcl_12": 0.88, "tcl_14": 0.12, "tcl_16": 0.88, "tcl_18": 0.12, "tcl_20": 0.88}      # the east row's doors: how far along each front (casas_calles.gd)
const SILL := 1.4                               # ...and how far over each house's base (its half-buried floor of stone)
const STEEL := 0x9a9ea4
const DARK := 0x18181b
const WOOD := 0x5a3a22
const DIR := "res://assets/travesia/"

var top_s := 60.4               # where the stairs of the Clavel begin
var ramp_foot: Vector2          # on the pavement of San Rafael, before the ramps (on the map)
var ramp_top: Vector2           # on the walk, where they end
var stairs_foot: Vector2        # on the Clavel, before the stairs
var stairs_top: Vector2
var mid_spot: Vector2           # the middle of the walk
var saffron_spot: Vector2
var outlines: Array = []
var lamps: Array = []
var _first: Array = []          # what people walk on: the pieces that go over the walk first...
var _last: Array = []           # ...and the walk itself

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"baldosa", "rayado":
			var fm := StandardMaterial3D.new()
			fm.albedo_texture = load(DIR + String(key) + ".png")
			fm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			fm.roughness = 1.0
			fm.metallic_specular = 0.0
			m = fm
		"laja":             # the flat stones on the corner houses' feet
			var lm := StandardMaterial3D.new()
			lm.albedo_texture = load(DIR + "laja.png")
			lm.uv1_triplanar = true
			lm.uv1_scale = Vector3.ONE / 1.6
			lm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			lm.roughness = 1.0
			lm.metallic_specular = 0.0
			m = lm
		"ocre":             # the rows' render
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.97, 0.79, 0.45)), 0.1)
		"zocalo":           # the west row's foot
			m = Tex.mat("painted_plaster_wall", Color(0.66, 0.38, 0.3))
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	level = MapData.height(O) + 1.48
	var rows: Dictionary = {}
	for hd in MapData.houses:
		var id := String(hd["id"])
		if DOORS.has(id):
			var o := Vector2(hd["o"][0], hd["o"][1])
			var u := Vector2(hd["u"][0], hd["u"][1]).normalized()
			var ln := float(hd["len"])
			var frac := float(DOORS[id])
			var s_door: float = (o + u * ln * frac - O).dot(U)
			var wall_s: float = (o - O).dot(U) if frac < 0.5 else (o + u * ln - O).dot(U)      # (the party wall its door is by)
			rows[id] = [s_door, float(hd.get("base", 0.0)) + SILL, wall_s, frac < 0.5]
	if rows.has("tcl_4"):                           # (the walk: UNDER the first door's sill, and rising from there)
		level = float(rows["tcl_4"][1]) - UNDER - SLOPE * float(rows["tcl_4"][0])
	transform = Transform3D(Basis(Vector3(U.x, 0, U.y), Vector3.UP, Vector3(-U.y, 0, U.x)), Vector3(O.x, level, O.y))
	W.add_child(self)
	_ramps()
	_north()
	_walk()
	for id in rows:
		_landing(float(rows[id][2]), float(rows[id][1]) - level, bool(rows[id][3]))
	_west_row()
	_white_house()
	_details()
	_saffron(21.65, WIDE - 0.4)
	home()
	_commit()
	MapData.decks = _first + _last + MapData.decks
	_tell_map()
	ramp_foot = spot(-0.5, -0.8)
	ramp_top = spot(FRONT + 1.2, -(WEST_L - 0.65))
	stairs_foot = spot(FOOT_N + 1.0, -5.75)
	stairs_top = spot(top_s - 1.2, -5.75)
	mid_spot = spot(30.0, -3.6)

# ---------------- helpers ----------------
## a place of the frame: s north along the alley, t west of the east row, y up
func V(s: float, t: float, y: float) -> Vector3:
	return Vector3(s, y, -t)

func Q(s: float, t: float) -> Vector2:
	return Vector2(s, -t)

## the walk's height at s
func dk(s: float) -> float:
	return SLOPE * s

func gnd(s: float, t: float) -> float:
	return ground(s, -t)

## A piece of floor, level or sloping, that people walk on: its corners (x: s, y: how high, z: t) in order round it,
## all in one plane. Its top (if `show`), what holds it up, and the map told. `first`: it goes over the walk.
func _plane(pts: Array, key, show := true, first := true, tile := 1.6) -> void:
	pieces += 1
	var top: Array = []
	var uv: Array = []
	var flatp := PackedVector2Array()
	var mid := Vector3.ZERO
	for q: Vector3 in pts:
		top.append(V(q.x, q.z, q.y))
		uv.append(Vector2(q.z, q.x) / tile)
		flatp.append(Vector2(q.x, -q.z))
		mid += q / float(pts.size())
	if show:
		if top.size() == 4:
			quad(top[0], top[1], top[2], top[3], key, Vector3.UP, uv)
		else:
			for i in range(1, top.size() - 1):
				tri(top[0], top[i], top[i + 1], key, Vector3.UP, [uv[0], uv[i], uv[i + 1]])
	var all: Array = top.duplicate()
	for q2: Vector3 in top:
		all.append(Vector3(q2.x, DOWN, q2.z))
	_hull(all)
	var p0: Vector3 = pts[0]
	var p1: Vector3 = pts[1]
	var p2: Vector3 = pts[2]
	var n := (p1 - p0).cross(p2 - p0)
	var deck := _poly_deck(flatp, level + mid.y)
	if absf(n.y) > 0.0001 and (absf(n.x) > 0.00001 or absf(n.z) > 0.00001):
		deck["grad"] = U * (-n.x / n.y) + Vector2(U.y, -U.x) * (-n.z / n.y)
	if first:
		_first.append(deck)
	else:
		_last.append(deck)

## a level rectangle of floor
func _level(s0: float, s1: float, t0: float, t1: float, y: float, key = "baldosa") -> void:
	_plane([Vector3(s0, y, t0), Vector3(s1, y, t0), Vector3(s1, y, t1), Vector3(s0, y, t1)], key)

## A flight of steps from s_top (at y_top) on along the alley (dir: +1 northwards, -1 southwards), between t0 and t1:
## n risers, down `drop` in all. Paved in the walk's chequers, a row of them to each step.
func _stairs(s_top: float, dir: float, t0: float, t1: float, y_top: float, drop: float, n: int, tread: float) -> float:
	var rise: float = drop / n
	var s_foot: float = s_top + dir * tread * (n - 1)
	for k in range(1, n + 1):
		var sa: float = s_top + dir * tread * (k - 1)
		var ya: float = y_top - rise * (k - 1)
		var yb: float = (y_top - rise * k) if k < n else (y_top - drop - 0.3)
		var v0: float = (k - 1) * 0.25
		quad(V(sa, t0, yb), V(sa, t1, yb), V(sa, t1, ya), V(sa, t0, ya), "baldosa", Vector3(dir, 0, 0),
			[Vector2(t0 / 2.4, v0 + 0.2), Vector2(t1 / 2.4, v0 + 0.2), Vector2(t1 / 2.4, v0 + 0.05), Vector2(t0 / 2.4, v0 + 0.05)])
		if k < n:
			var sb: float = sa + dir * tread
			quad(V(sa, t0, yb), V(sb, t0, yb), V(sb, t1, yb), V(sa, t1, yb), "baldosa", Vector3.UP,
				[Vector2(t0 / 2.4, k * 0.25 + 0.02), Vector2(t0 / 2.4, k * 0.25 + 0.23), Vector2(t1 / 2.4, k * 0.25 + 0.23), Vector2(t1 / 2.4, k * 0.25 + 0.02)])
	pieces += n
	if n > 1:
		_plane([Vector3(s_top, y_top, t0), Vector3(s_foot, y_top - drop + rise, t0), Vector3(s_foot, y_top - drop + rise, t1), Vector3(s_top, y_top, t1)], "baldosa", false)      # (the feet follow the steps' edges: never under a tread)
	return s_foot

## A wall between two places of the plan (s, t), `thick` wide, from under the ground up to ya at a and yb at b.
func _wall(a: Vector2, b: Vector2, ya: float, yb: float, thick: float, key, low := DOWN) -> void:
	pieces += 1
	var pa := Vector3(a.x, 0, -a.y)
	var pb := Vector3(b.x, 0, -b.y)
	var d := (pb - pa).normalized()
	var n := Vector3(-d.z, 0, d.x) * (thick / 2.0)
	var up_a := Vector3(0, ya, 0)
	var up_b := Vector3(0, yb, 0)
	var lo := Vector3(0, low, 0)
	quad(pa + n + lo, pb + n + lo, pb + n + up_b, pa + n + up_a, key, n.normalized())
	quad(pa - n + lo, pb - n + lo, pb - n + up_b, pa - n + up_a, key, -n.normalized())
	quad(pa - n + up_a, pb - n + up_b, pb + n + up_b, pa + n + up_a, key, Vector3.UP)
	quad(pa - n + lo, pa + n + lo, pa + n + up_a, pa - n + up_a, key, -d)
	quad(pb - n + lo, pb + n + lo, pb + n + up_b, pb - n + up_b, key, d)

## something solid along a wall or a railing, from `low` up to `high`
func _stop(a: Vector2, b: Vector2, low: float, high: float, thick := 0.15) -> void:
	var pa := Vector3(a.x, 0, -a.y)
	var pb := Vector3(b.x, 0, -b.y)
	var d := pb - pa
	var mid := (pa + pb) / 2.0
	solid(Vector3(mid.x, (low + high) / 2.0, mid.z), Vector3(d.length(), high - low, thick), atan2(-d.z, d.x))

## a railing of steel tube from a to b (places on the floor it stands on): posts, a handrail and a rail half-way up
func _tube(a: Vector3, b: Vector3, tall := 0.95) -> void:
	var ln := a.distance_to(b)
	var n := maxi(1, int(ceil(ln / 1.6)))
	for i in range(n + 1):
		var p := a.lerp(b, float(i) / n)
		box(p.x - 0.025, p.y, p.z - 0.025, 0.05, tall, 0.05, STEEL)
	for h: float in [tall, tall * 0.62, tall * 0.26]:
		bar(a + Vector3(0, h, 0), b + Vector3(0, h, 0), 0.05, 0.05, STEEL)

## a railing of steel bars from a to b: a handrail, a rail at its foot and thin uprights between them (the stairs')
func _bars(a: Vector3, b: Vector3, tall := 0.95) -> void:
	var ln := a.distance_to(b)
	if ln < 0.2:
		return
	bar(a + Vector3(0, tall, 0), b + Vector3(0, tall, 0), 0.05, 0.04, STEEL)
	bar(a + Vector3(0, 0.1, 0), b + Vector3(0, 0.1, 0), 0.03, 0.03, STEEL)
	var n := maxi(2, int(round(ln / 0.13)))
	for i in range(n + 1):
		var p := a.lerp(b, float(i) / n)
		var w := 0.04 if i % 10 == 0 or i == n else 0.016
		box(p.x - w / 2.0, p.y + (0.0 if w > 0.03 else 0.1), p.z - w / 2.0, w, tall - (0.0 if w > 0.03 else 0.1), w, STEEL)

## a railing of wrought iron from a to b: two rails and thin uprights, a band of rings under the handrail
func _forja(a: Vector3, b: Vector3, tall := 0.9) -> void:
	var ln := a.distance_to(b)
	if ln < 0.2:
		return
	bar(a + Vector3(0, tall, 0), b + Vector3(0, tall, 0), 0.04, 0.03, IRON)
	bar(a + Vector3(0, tall - 0.16, 0), b + Vector3(0, tall - 0.16, 0), 0.02, 0.02, IRON)
	bar(a + Vector3(0, 0.08, 0), b + Vector3(0, 0.08, 0), 0.03, 0.02, IRON)
	var n := maxi(2, int(round(ln / 0.13)))
	for i in range(n + 1):
		var p := a.lerp(b, float(i) / n)
		box(p.x - 0.008, p.y + 0.08, p.z - 0.008, 0.016, tall - 0.08, 0.016, IRON)
		if i < n and i % 2 == 0:
			var q := a.lerp(b, (i + 0.5) / n)
			box(q.x - 0.04, q.y + tall - 0.14, q.z - 0.008, 0.08, 0.1, 0.016, IRON)

## a vent of dark slats on the wall being built (face frame): x, y its corner
func _vent(x: float, y: float, w := 0.7, h := 0.32) -> void:
	box(x, y, 0.0, w, h, 0.015, DARK)
	for k in range(1, 5):
		box(x + 0.02, y + h * k / 5.0 - 0.012, 0.0, w - 0.04, 0.02, 0.03, 0x4a4a4c)

## a flat piece of this outline (s, -t) laid on the ground, `lift` over it, cut along the relief's facets
func _drape(pts: Array, lift: float, key, tile: float) -> void:
	pieces += 1
	var keep := _xf
	home()
	var inv := transform.affine_inverse()
	var mp := PackedVector2Array()
	for q: Vector2 in pts:
		mp.append(spot(q.x, q.y))
	if Geometry2D.is_polygon_clockwise(mp):
		mp.reverse()
	var bx := Rect2(mp[0], Vector2.ZERO)
	for q2 in mp:
		bx = bx.expand(q2)
	var g: float = MapData.rg
	for i in range(int(floor((bx.position.x - MapData.rx0) / g)), int(floor((bx.end.x - MapData.rx0) / g)) + 1):
		for j in range(int(floor((bx.position.y - MapData.rz0) / g)), int(floor((bx.end.y - MapData.rz0) / g)) + 1):
			var c := Vector2(MapData.rx0 + i * g, MapData.rz0 + j * g)
			for facet: PackedVector2Array in [PackedVector2Array([c, c + Vector2(g, 0), c + Vector2(g, g)]), PackedVector2Array([c, c + Vector2(g, g), c + Vector2(0, g)])]:
				if Geometry2D.is_polygon_clockwise(facet):
					facet.reverse()
				for piece in Geometry2D.intersect_polygons(mp, facet):
					if piece.size() < 3 or Geometry2D.is_polygon_clockwise(piece):
						continue
					var idx := Geometry2D.triangulate_polygon(piece)
					for k in range(0, idx.size(), 3):
						var tri_pts: Array = []
						var tri_uv: Array = []
						for m in range(3):
							var w: Vector2 = piece[idx[k + m]]
							var l: Vector3 = inv * Vector3(w.x, MapData.height(w) + lift, w.y)
							tri_pts.append(l)
							tri_uv.append(Vector2(-l.z, l.x) / tile)
						tri(tri_pts[0], tri_pts[1], tri_pts[2], key, Vector3.UP, tri_uv)
	_xf = keep

## an outline (s, t) as solids and as one of the map's
func _mass(pts: Array, top: float) -> void:
	var flatp := PackedVector2Array()
	var world_pts := PackedVector2Array()
	for q: Vector2 in pts:
		flatp.append(Vector2(q.x, -q.y))
		world_pts.append(spot(q.x, -q.y))
	for part in Geometry2D.decompose_polygon_in_convex(flatp):
		var conv: Array = []
		for q2: Vector2 in part:
			conv.append(q2)
		_prism(conv, DOWN, top)
	outlines.append(world_pts)

# ---------------- the ramps, by San Rafael ----------------
## Three ramps to and fro across the alley, each a third of the way up, with a level landing at each end: in at the
## east end from the pavement, up westwards, back eastwards, up westwards again and on to the walk at its west side.
func _ramps() -> void:
	var h0 := gnd(0.9, 0.8)                         # San Rafael's pavement, where they begin
	var top := dk(FRONT)
	var rise := top - h0
	var la := WEST_L - LAND                         # where the west landings begin
	var lb := EAST_L + LAND                         # where the east ones end
	var y1 := h0 + rise / 3.0
	var y2 := h0 + rise * 2.0 / 3.0
	var r1: Array = RUNS[0]
	var r2: Array = RUNS[1]
	var r3: Array = RUNS[2]
	var a1: float = r1[0]
	var b1: float = r1[1]
	var a2: float = r2[0]
	var b2: float = r2[1]
	var a3: float = r3[0]
	var b3: float = r3[1]
	_level(a1 - 0.15, b1, EAST_L, lb, h0)                                            # in from the pavement
	_plane([Vector3(a1, h0, lb), Vector3(b1, h0, lb), Vector3(b1, y1, la), Vector3(a1, y1, la)], "baldosa")
	_level(a1, b2, la, WEST_L, y1)
	_plane([Vector3(a2, y1, la), Vector3(b2, y1, la), Vector3(b2, y2, lb), Vector3(a2, y2, lb)], "baldosa")
	_level(a2, b3, EAST_L, lb, y2)
	_plane([Vector3(a3, y2, lb), Vector3(b3, y2, lb), Vector3(b3, top, la), Vector3(a3, top, la)], "baldosa")
	_level(a3, FRONT, la, WEST_L, top)
	# the white walls between them, each as high as the ramp above it and a kerb more, with its railing
	var k := 0.15
	var w0 := a1 - 0.075
	var w1 := (b1 + a2) / 2.0
	var w2 := (b2 + a3) / 2.0
	var w3 := (b3 + FRONT) / 2.0
	_wall(Vector2(w0, lb), Vector2(w0, la), h0 + k, y1 + k, 0.15, "white")           # before the first
	_wall(Vector2(w0, la), Vector2(w0, WEST_L), y1 + k, y1 + k, 0.15, "white")
	_tube(V(w0, lb, h0 + k), V(w0, la, y1 + k))
	_tube(V(w0, la, y1 + k), V(w0, WEST_L, y1 + k))
	_stop(Vector2(w0, lb), Vector2(w0, WEST_L), DOWN, y1 + 1.2)
	_wall(Vector2(w1, la), Vector2(w1, lb), y1 + k, y2 + k, 0.15, "white")           # between the first and the second
	_wall(Vector2(w1, lb), Vector2(w1, EAST_L), y2 + k, y2 + k, 0.15, "white")
	_tube(V(w1, la, y1 + k), V(w1, lb, y2 + k))
	_tube(V(w1, lb, y2 + k), V(w1, EAST_L, y2 + k))
	_stop(Vector2(w1, EAST_L), Vector2(w1, la), DOWN, y2 + 1.2)
	_wall(Vector2(w2, lb), Vector2(w2, la), y2 + k, top + k, 0.15, "white")          # between the second and the third
	_wall(Vector2(w2, la), Vector2(w2, WEST_L), top + k, top + k, 0.15, "white")
	_tube(V(w2, lb, y2 + k), V(w2, la, top + k))
	_tube(V(w2, la, top + k), V(w2, WEST_L, top + k))
	_stop(Vector2(w2, lb), Vector2(w2, WEST_L), DOWN, top + 1.2)
	_wall(Vector2(w3, EAST_L), Vector2(w3, la), top + k, top + k, 0.15, "white")     # the walk's own edge over the third
	_tube(V(w3, EAST_L, top + k), V(w3, la, top + k))
	_stop(Vector2(w3, 0.0), Vector2(w3, la), DOWN, top + 1.2)
	# their ends against the houses
	_wall(Vector2(a1 - 0.15, WEST_L + 0.075), Vector2(FRONT, WEST_L + 0.075), top + k, top + k, 0.15, "white")
	_wall(Vector2(a2, EAST_L - 0.075), Vector2(FRONT, EAST_L - 0.075), y2 + k, y2 + k, 0.15, "white")
	_stop(Vector2(a1 - 0.15, WEST_L + 0.075), Vector2(FRONT, WEST_L + 0.075), DOWN, top + 1.2)
	# the vents of the garage in the walls, as they show from the street
	var third := rise / 3.0
	for tv: float in [4.6, 2.6]:
		var up := (tv - lb) / (la - lb)             # (how far up the first ramp that is; the second runs the other way)
		face(Vector2(w1 - 0.076, -(tv + 0.3)), Vector2(w1 - 0.076, -(tv - 0.3)))
		_vent(0.0, h0 + third * up + 0.07, 0.6, 0.26)
		face(Vector2(w2 - 0.076, -(tv + 0.3)), Vector2(w2 - 0.076, -(tv - 0.3)))
		_vent(0.0, y1 + third * (1.0 - up) + 0.07, 0.6, 0.26)
		home()
	face(Vector2(w0 - 0.076, -(WEST_L - 0.1)), Vector2(w0 - 0.076, -(la + 0.1)))      # (and in the front one, under the west landing)
	_vent(0.25, h0 + 0.12, 0.6, 0.26)
	home()

# ---------------- the stairs, the garage's lane and the terrace's stair, by the Clavel ----------------
func _north() -> void:
	var l0: float = LANE[0]
	var l1: float = LANE[1]
	var g_w := gnd(FOOT_N, 5.75)                    # the Clavel at the foot of the stairs
	var g_e := gnd(FOOT_N, 0.65)
	var n := maxi(3, int(round((dk(60.4) - g_w) / 0.15)))
	top_s = FOOT_N - 0.32 * (n - 1)
	var yt := dk(top_s)
	_stairs(top_s, 1.0, l1 + 0.2, WIDE, yt, yt - g_w, n, 0.32)
	_stairs(top_s, 1.0, 0.0, l0 - 0.2, yt, yt - g_e, n, 0.32)
	var yl := dk(LANE_S)
	var k := 0.12
	# the walk's end over the lane: the garage's mouth under it
	face(Vector2(LANE_S, -(l0 - 0.2)), Vector2(LANE_S, -(l1 + 0.2)))
	var ln := l1 - l0 + 0.4
	var gl := gnd(LANE_S + 0.5, (l0 + l1) / 2.0)
	box(0.35, gl - 0.3, 0.0, ln - 0.7, yl - 0.2 - (gl - 0.3), 0.02, DARK)
	box(0.3, yl - 0.2, 0.0, ln - 0.6, 0.08, 0.05, 0x8a8478)
	for i in range(1, 8):
		box(0.35 + (ln - 0.7) * i / 8.0 - 0.012, gl - 0.3, 0.02, 0.024, yl - 0.2 - (gl - 0.3), 0.012, 0x3a3a3e)
	home()
	_wall(Vector2(LANE_S - 0.1, l0 - 0.2), Vector2(LANE_S - 0.1, l1 + 0.2), yl + k, yl + k, 0.2, "ocre")
	_bars(V(LANE_S - 0.1, l0 - 0.1, yl + k), V(LANE_S - 0.1, l1 + 0.1, yl + k))
	_stop(Vector2(LANE_S - 0.1, l0 - 0.2), Vector2(LANE_S - 0.1, l1 + 0.2), yl, yl + 1.2, 0.2)
	# the lane's two walls: the terrace's on the east, the stairs' on the west
	for side in [[l0 - 0.1, g_e, true], [l1 + 0.1, g_w, false]]:
		var t: float = side[0]
		var gf: float = side[1]
		_wall(Vector2(LANE_S, t), Vector2(top_s, t), yl + k, yt + k, 0.2, "ocre")
		_wall(Vector2(top_s, t), Vector2(FOOT_N, t), yt + k, gf + k + 0.1, 0.2, "ocre")
		if bool(side[2]):
			_forja(V(LANE_S, t, yl + k), V(top_s, t, yt + k))
			_forja(V(top_s, t, yt + k), V(FOOT_N, t, gf + k + 0.1))
		else:
			_bars(V(LANE_S, t, yl + k), V(top_s, t, yt + k))
			_bars(V(top_s, t, yt + k), V(FOOT_N, t, gf + k + 0.1))
		_stop(Vector2(LANE_S, t), Vector2(FOOT_N, t), DOWN, yt + 1.2, 0.2)
	face(Vector2(LANE_S + 4.2, -(l0 + 0.001)), Vector2(LANE_S + 1.2, -(l0 + 0.001)))          # (the vent in the terrace's wall)
	_vent(1.0, gl + 0.45)
	home()
	# the lane's floor of grooved concrete, on the ground
	_drape([Q(LANE_S, l0), Q(FOOT_N + 0.6, l0), Q(FOOT_N + 0.6, l1), Q(LANE_S, l1)], 0.015, "rayado", 0.8)

# ---------------- the walk ----------------
func _walk() -> void:
	var l0: float = LANE[0]
	var l1: float = LANE[1]
	_plane([Vector3(FRONT, dk(FRONT), 0.0), Vector3(LANE_S, dk(LANE_S), 0.0), Vector3(LANE_S, dk(LANE_S), WIDE), Vector3(FRONT, dk(FRONT), WIDE)], "baldosa", true, false)
	_plane([Vector3(LANE_S, dk(LANE_S), l1 + 0.2), Vector3(top_s, dk(top_s), l1 + 0.2), Vector3(top_s, dk(top_s), WIDE), Vector3(LANE_S, dk(LANE_S), WIDE)], "baldosa", true, false)
	_plane([Vector3(LANE_S, dk(LANE_S), 0.0), Vector3(top_s, dk(top_s), 0.0), Vector3(top_s, dk(top_s), l0 - 0.2), Vector3(LANE_S, dk(LANE_S), l0 - 0.2)], "baldosa", true, false)
	_plane([Vector3(0.0, dk(FRONT), 0.0), Vector3(FRONT, dk(FRONT), 0.0), Vector3(FRONT, dk(FRONT), EAST_L), Vector3(0.0, dk(FRONT), EAST_L)], "baldosa", false, false)      # (nobody stands on the strip along the corner house)

## The landing before a door of the east row and its steps down to the walk. `wall_s`: the party wall the door is by;
## `sill`: the door's; `south`: the door is south of that wall (the steps go on southwards) or north of it.
func _landing(wall_s: float, sill: float, south: bool) -> void:
	var dir := -1.0 if south else 1.0
	var deep := 1.25
	var terrace: bool = wall_s > LANE_S - 1.0         # (on the terrace by the Clavel, behind the railing of the lane's wall)
	var s_end: float = wall_s + dir * 1.6
	var drop: float = sill - dk(s_end)
	if drop < 0.04:                                 # (no higher than the walk: nothing to build)
		return
	var n := maxi(1, int(ceil(drop / 0.17)))
	var tread := 0.28
	var s_foot: float = s_end + dir * tread * (n - 1)
	drop = sill - dk(s_foot)
	var s0 := minf(wall_s, s_end)
	var s1 := maxf(wall_s, s_end)
	box(s0, dk(s0) - 0.3, -deep, s1 - s0, sill - 0.01 - (dk(s0) - 0.3), deep, "ocre")
	_level(s0, s1, 0.0, deep, sill)
	_stairs(s_end, dir, 0.0, deep, sill, drop, n, tread)
	if n > 1:                                       # (what shows of the steps from the walk: their side)
		var a := minf(s_end, s_foot)
		var b := maxf(s_end, s_foot)
		for kk in range(1, n):
			var sa: float = s_end + dir * tread * (kk - 1)
			var sb: float = sa + dir * tread
			box(minf(sa, sb), dk(a) - 0.3, -deep, tread, sill - drop * kk / n - 0.005 - (dk(a) - 0.3), 0.02, "ocre")
		if not terrace:
			_forja(V(s_end, deep - 0.03, sill), V(s_foot, deep - 0.03, sill - drop + drop / n))
			_stop(Vector2(a, deep - 0.03), Vector2(b, deep - 0.03), dk(a), sill + 0.95, 0.06)
	if not terrace:
		_forja(V(wall_s, deep - 0.03, sill), V(s_end, deep - 0.03, sill))
		_stop(Vector2(s0, deep - 0.03), Vector2(s1, deep - 0.03), dk(s0), sill + 0.95, 0.06)

# ---------------- the west row ----------------
func _tb(s: float) -> float:
	return lerpf(float(BACK[0]), float(BACK[1]), (s - float(ROW[0])) / (float(ROW[1]) - float(ROW[0])))

func _mx(x: float, w: float, ln: float, mirror: bool) -> float:
	return (ln - x - w) if mirror else x

func _west_row() -> void:
	var r0: float = ROW[0]
	var r1: float = ROW[1]
	var count := 7
	var each: float = (r1 - r0) / count
	for i in range(count):
		_house(i, r0 + each * i, r0 + each * (i + 1), i == count - 1)

func _house(i: int, s0: float, s1: float, last: bool) -> void:
	var ln := s1 - s0
	var fl := dk((s0 + s1) / 2.0) + 0.16            # its floor: a step over the walk
	var eave := fl + 6.2
	var rid := eave + 1.7
	var mirror := i % 2 == 1
	var rt := WIDE + 4.2                            # where its ridge runs
	face(Vector2(s0, -WIDE), Vector2(s1, -WIDE))
	var door := Rect2(_mx(0.95, 0.95, ln, mirror), fl, 0.95, 2.1)
	var win := Rect2(_mx(3.9, 1.3, ln, mirror), fl + 1.0, 1.3, 1.25)
	var up0 := Rect2(_mx(0.9, 1.1, ln, mirror), fl + 3.75, 1.1, 1.25)
	var up1 := Rect2(_mx(4.0, 1.1, ln, mirror), fl + 3.75, 1.1, 1.25)
	masonry(0.0, ln, DOWN, eave, [door, win, up0, up1], [], "ocre", "ocre")
	for span in [[0.0, door.position.x], [door.end.x, ln]]:
		var xa: float = span[0]
		var xb: float = span[1]
		if xb - xa > 0.05:
			plinth(xa, xb, fl + 0.8, fl + 0.8, "zocalo", 0.03, DOWN)
	box(0.0, fl + 2.95, 0.0, ln, 0.1, 0.03, 0xb48a52)                                 # the band between its floors
	box(door.position.x, fl, -DEEP + 0.02, door.size.x, door.size.y, 0.05, 0x6a4a30)
	box(door.position.x + 0.1, fl + 1.25, -DEEP + 0.07, door.size.x - 0.2, 0.6, 0.012, 0x4a3220)
	box(door.position.x + 0.1, fl + 0.2, -DEEP + 0.07, door.size.x - 0.2, 0.8, 0.012, 0x4a3220)
	box(door.position.x - 0.12, dk(s0) - 0.2, 0.0, door.size.x + 0.24, fl - (dk(s0) - 0.2), 0.34, 0xc9b79a)      # its step
	window(win, 0x4a3020)
	grille(win)
	for r: Rect2 in [up0, up1]:
		box(r.position.x, r.position.y, -DEEP + 0.03, r.size.x, r.size.y, 0.04, 0x8a6a48)
		for kk in range(1, 9):
			box(r.position.x, r.position.y + r.size.y * kk / 9.0, -DEEP + 0.07, r.size.x, 0.01, 0.006, 0x6a4e34)
		box(r.position.x - 0.06, r.position.y - 0.07, 0.0, r.size.x + 0.12, 0.07, 0.07, 0xb48a52)
	var nb := int(ln / 0.62)
	for kk in range(nb + 1):                        # the wooden brackets under the eaves
		box(ln * kk / nb - 0.04, eave - 0.37, 0.0, 0.08, 0.14, 0.46, WOOD)
	home()
	# its roof of tiles, the ridge along the alley
	roof([V(s0, WIDE - 0.5, eave - 0.2), V(s1, WIDE - 0.5, eave - 0.2), V(s1, rt, rid), V(s0, rt, rid)])
	roof([V(s0, rt, rid), V(s1, rt, rid), V(s1, _tb(s1), eave), V(s0, _tb(s0), eave)])
	ridge(V(s0, rt, rid), V(s1, rt, rid))
	# its south end (the gable shows over the lower house next to it), its back, and the north end of the last
	_gable(s0, _tb(s0), eave, rid, rt, true, i == 0)
	if last:
		_gable(s1, _tb(s1), eave, rid, rt, false, false)
	_plain(Q(s1, _tb(s1)), Q(s0, _tb(s0)), DOWN, eave, "ocre")
	_mass([Vector2(s0, WIDE), Vector2(s1, WIDE), Vector2(s1, _tb(s1)), Vector2(s0, _tb(s0))], eave)

## an end wall of the row, up into its gable: at s, from the front (t = WIDE) to its back
func _gable(s: float, back: float, eave: float, rid: float, rt: float, south: bool, street: bool) -> void:
	var ln := back - WIDE
	if south:
		face(Vector2(s, -back), Vector2(s, -WIDE))
	else:
		face(Vector2(s, -WIDE), Vector2(s, -back))
	var apex: float = (back - rt) if south else (rt - WIDE)
	var holes: Array = []
	if street:                                      # (the end on San Rafael: a window upstairs)
		holes.append(Rect2(ln - 3.2, dk(s) + 3.9, 1.1, 1.25))
	masonry(0.0, ln, DOWN, eave, holes, [], "ocre", "ocre")
	pieces += 1
	tri(Vector3(0, eave, 0), Vector3(ln, eave, 0), Vector3(apex, rid, 0), "ocre", Vector3(0, 0, 1))
	if street:
		var r: Rect2 = holes[0]
		box(r.position.x, r.position.y, -DEEP + 0.03, r.size.x, r.size.y, 0.04, 0x8a6a48)
		for kk in range(1, 9):
			box(r.position.x, r.position.y + r.size.y * kk / 9.0, -DEEP + 0.07, r.size.x, 0.01, 0.006, 0x6a4e34)
		plinth(0.0, ln, dk(s) + 1.2, dk(s) + 1.2, "laja", 0.04, DOWN)
		# the street's name on its tile, by the corner
		var calle := "Travesía del Clavel"
		for road in MapData.roads:
			if int(road.get("paved", 0)) == 5:
				calle = String(road["n"])
		box(ln - 1.75, dk(s) + 1.5, 0.0, 1.3, 0.62, 0.025, 0xf2efe6)
		box(ln - 1.75, dk(s) + 1.5, 0.0, 1.3, 0.04, 0.03, 0x2a4a8a)
		box(ln - 1.75, dk(s) + 2.08, 0.0, 1.3, 0.04, 0.03, 0x2a4a8a)
		var words := calle.to_upper().replace(" DEL ", "\nDEL ")
		_text(words, Vector3(ln - 1.1, dk(s) + 1.81, 0.03), 44, 0x2a4a8a, 0.004)
	home()

## a round thing lying on the wall being built
func _disc(at: Vector3, r: float, key, deep := 0.006) -> void:
	var keep := _xf
	_xf = keep * Transform3D(Basis(Vector3.RIGHT, PI / 2.0), at)
	drum(Vector3.ZERO, r, r, deep, key, 14)
	_xf = keep

# ---------------- the white house on the corner of the Clavel ----------------
func _white_house() -> void:
	var s0: float = ROW[1]
	var s1 := WHITE_N
	var g := gnd(WHITE_N + 0.7, (WIDE + WHITE_W) / 2.0)        # the Clavel before it
	var eave := g + 6.3
	var rid := eave + 1.1
	var rt := (WIDE + WHITE_W) / 2.0
	# its side along the stairs and the walk: white over a foot of flat stones
	var ln := face(Vector2(s0, -WIDE), Vector2(s1, -WIDE))
	masonry(0.0, ln, DOWN, eave, [], [], "white", "white")
	plinth(0.0, ln, dk(s0) + 0.95, dk(s1) + 0.75, "laja", 0.04, DOWN)
	box(1.4, eave - 2.5, 0.0, 0.8, 0.55, 0.3, 0xe6e4de)                             # (the air conditioner's box)
	box(1.48, eave - 2.42, 0.3, 0.64, 0.39, 0.01, 0x9a9c9e)
	home()
	# its front on the Clavel: the garage's door, two windows over it
	var ne := Vector2(s1, -WIDE)
	var nw := Vector2(s1 + 0.4, -WHITE_W)
	ln = face(ne, nw)
	var gar := Rect2(0.7, g - 0.2, 2.6, 2.5)
	var w0 := Rect2(1.2, g + 3.5, 1.5, 1.2)
	var w1 := Rect2(3.6, g + 3.5, 1.1, 1.2)
	masonry(0.0, ln, DOWN, eave, [gar, w0, w1], [], "white", "white")
	plinth(0.0, gar.position.x, g + 2.4, g + 2.4, "laja", 0.04, DOWN)
	plinth(gar.end.x, ln, g + 2.4, g + 2.4, "laja", 0.04, DOWN)
	box(gar.position.x, g + 2.3, 0.0, gar.size.x, 0.1, 0.04, "laja")
	box(gar.position.x, g - 0.2, -DEEP + 0.04, gar.size.x, gar.size.y, 0.05, 0x5a3a2c)
	for kk in range(1, 14):
		box(gar.position.x + gar.size.x * kk / 14.0 - 0.01, g, -DEEP + 0.09, 0.02, 2.25, 0.012, 0x452b20)
	box(gar.position.x + 0.95, g + 1.25, -DEEP + 0.1, 0.36, 0.46, 0.012, 0xf0eee6)   # (the sign on it: no parking)
	_disc(Vector3(gar.position.x + 1.13, g + 1.55, -DEEP + 0.112), 0.13, 0xc8322a)
	_disc(Vector3(gar.position.x + 1.13, g + 1.55, -DEEP + 0.118), 0.1, 0x2a4a9a)
	bar(Vector3(gar.position.x + 1.05, g + 1.47, -DEEP + 0.126), Vector3(gar.position.x + 1.21, g + 1.63, -DEEP + 0.126), 0.03, 0.006, 0xc8322a)
	window(w0, 0xf0eee6)
	grille(w0)
	window(w1, 0xf0eee6)
	pieces += 1
	tri(Vector3(0, eave, 0), Vector3(ln, eave, 0), Vector3(ln / 2.0, rid, 0), "white", Vector3(0, 0, 1))
	home()
	_plain(Q(s1 + 0.4, WHITE_W), Q(s0, WHITE_W), DOWN, eave, "white")
	roof([V(s0, WIDE - 0.4, eave - 0.15), V(s1 + 0.25, WIDE - 0.4, eave - 0.15), V(s1 + 0.25, rt, rid), V(s0, rt, rid)])
	roof([V(s0, rt, rid), V(s1 + 0.25, rt, rid), V(s1 + 0.45, WHITE_W + 0.3, eave - 0.12), V(s0, WHITE_W + 0.3, eave - 0.12)])
	ridge(V(s0, rt, rid), V(s1 + 0.25, rt, rid))
	_mass([Vector2(s0, WIDE), Vector2(s1, WIDE), Vector2(s1 + 0.4, WHITE_W), Vector2(s0, WHITE_W)], eave)

# ---------------- what else is in the alley ----------------
func _details() -> void:
	# lamps on the west row's wall, their arms out over the walk
	for s: float in [9.0, 24.0, 39.0, 51.0]:
		var y := dk(s) + 4.6
		bar(V(s, WIDE, y), V(s, WIDE - 1.1, y + 0.25), 0.04, 0.04, 0x5a5c60)
		box(s - 0.14, y + 0.16, -(WIDE - 1.0), 0.28, 0.1, 0.42, 0x5a5c60)
		var lamp: Vector3 = transform * Vector3(s, y, -(WIDE - 1.2))
		if W != null and "lamp_spots" in W:
			W.lamp_spots.append(lamp)
		lamps.append(lamp)
	# a bench and two pots of flowers in the middle of the walk, by the west row
	for s2: float in [20.5, 35.5]:
		var yb := dk(s2)
		box(s2 - 0.75, yb + 0.4, -(WIDE - 0.25), 1.5, 0.05, 0.38, 0x7a5a3a)
		box(s2 - 0.75, yb + 0.45, -(WIDE - 0.2), 1.5, 0.4, 0.05, 0x7a5a3a)
		for e: float in [-0.65, 0.65]:
			box(s2 + e - 0.03, yb, -(WIDE - 0.3), 0.06, 0.42, 0.36, 0x3a3c40)
		solid(V(s2, WIDE - 0.42, yb + 0.4), Vector3(1.5, 0.8, 0.45))
	for pot in [[13.2, 6.6], [28.0, 6.6], [43.0, 6.6]]:
		var ps: float = pot[0]
		var pt: float = pot[1]
		drum(V(ps, pt, dk(ps)), 0.2, 0.26, 0.42, 0xb0623a, 10)
		ball(V(ps, pt, dk(ps) + 0.6), 0.3, 0x3f7a3a, 0.8, 8, 5)
		for kk in range(5):
			ball(V(ps + cos(kk * 1.257) * 0.2, pt + sin(kk * 1.257) * 0.2, dk(ps) + 0.74), 0.07, 0xd8423a, 1.0, 5, 3)
		solid(V(ps, pt, dk(ps) + 0.4), Vector3(0.5, 0.8, 0.5))

## A saffron flower in a little pot of clay, by the west row's wall behind the first bench, where neither street sees
## it (the user: hide saffron in special places).
func _saffron(s: float, t: float) -> void:
	var g := dk(s) + 0.01
	drum(V(s, t, g), 0.1, 0.14, 0.16, 0xb0623a, 10)
	drum(V(s, t, g + 0.15), 0.12, 0.12, 0.012, 0x5a3a26, 10)
	var flower := Node3D.new()
	flower.add_child(Parts.part("cyl", 0x5f9c4a, Vector3(0, 0.3, 0), Vector3(0.03, 0.6, 0.03)))
	for k in range(5):
		flower.add_child(Parts.part("ball", 0x9b5de5, Vector3(cos(k * 1.257) * 0.12, 0.66, sin(k * 1.257) * 0.12), Vector3(0.11, 0.2, 0.11)))
	flower.add_child(Parts.part("ball", 0xe63946, Vector3(0, 0.74, 0), Vector3(0.05, 0.13, 0.05)))
	flower.position = V(s, t, g + 0.12)
	add_child(flower)
	saffron_spot = spot(s, -t)
	var game = W.get_parent()                           # (the game: the world is its child)
	if game != null and game.get("flowers") != null:
		(game.flowers as Array).append({"node": flower, "p": saffron_spot, "id": "travesia", "hidden": true})      # (hidden: Sistemas keeps count of these)

func _tell_map() -> void:
	for outline: PackedVector2Array in outlines:
		MapData.outlines.append(outline)
		if not MapData._wall_grid.is_empty():
			for i in range(outline.size()):
				var a: Vector2 = outline[i]
				var c: Vector2 = outline[(i + 1) % outline.size()]
				MapData._grid_add(MapData._wall_grid, a.min(c), a.max(c), [a, c])
