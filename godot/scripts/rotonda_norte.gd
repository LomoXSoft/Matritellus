extends "res://scripts/obra.gd"
## The roundabout at the north entrance, where the old Madrid-Cádiz road comes into the town and meets the Avenida de
## la Constitución (the user, 24 November 2026, with two Street View captures of November 2024: "Un poco más adelante
## hay una rotonda bastante bonita. Me gustaría que fuese lo siguiente que hacemos"). Built by hand from Street View
## (cameras north, south and east of it, 2024 and 2025) and the PNOA orthophoto (tools/ign/rotonda_norte.jpg).
##
## A round island behind a kerb painted red and white; inside it a band of red brick laid along the ring, rising
## gently to a white kerb; inside that a lawn. On the lawn, the town's name on a long board of rusty steel, MADRIDEJOS
## painted on it in white by hand (as the real one: the town keeps its name), its east end rolled, looking north to who
## comes from Madrid; behind it, to the west, a gate of brick that goes nowhere -- two pillars, a lintel, a small roof of
## curved tiles and an iron grille over a low sill, all of pale bare brick (the user, 24 Nov: not whitewashed behind,
## "es del mismo material que delante": in the sun it looks white); to the east a
## great clay jar lying on its side, its mouth up to the north-west, a saffron flower hidden inside it (the user's
## choice, 24 Nov: _saffron); the blue signs of the roundabout at its edge.
##
## No rebake: the island is the inside of the ring road the map already has there (road 98), as rotonda.gd does. The map's
## ring is 1.1 m east of the real island and its island 0.6 m smaller (6.34 m against 6.94): the island takes the ring's
## middle and size, the lawn keeps nearly its real size (4.40 m against 4.56; the brick band gives up the rest), and what
## stands on it keeps its real size and its real place measured from the real island's middle (REAL).
## Frame: map metres from the island's middle, north up the map (-z); y = 0 the ground there.

const NEAR := Vector2(276.9, -1555.75)        # where to look for the ring of the map
const REAL := Vector2(275.87, -1555.66)       # the real island's middle (circles fitted to the orthophoto)
const GATE := Vector2(273.74, -1555.28)       # the gate's middle (three cameras' bearings)
const JAR := Vector2(278.8, -1554.75)         # the jar's belly (three cameras and the orthophoto)
const BOARD := Vector2(275.92, -1558.76)      # the board's middle (0.25 m further in than the real one: the lawn is narrower)
const FACE := 350.0                           # the way the board and the gate look (bearing): north-north-west, up the road from Madrid
                                              # (from the east the gate is seen edge on, from the south square on)
const JAR_AXIS := 350.0                       # the way the jar's mouth points (bearing) ...
const JAR_TILT := 28.0                        # ... and how far up
const KERB := 0.15                            # the outer kerb's top, over the road
const OUTER_W := 0.25                         # its width
const BAND_IN := 0.29                         # the brick band at its inner edge (it rises from the kerb)
const WHITE_W := 0.15                         # the white kerb round the lawn
const WHITE_TOP := 0.45
const LAWN := 0.42
const LAWN_R := 4.4
const STEP := 0.4
const RED := 0xb8453a
const WHITE := 0xeeeeea
const RUST := 0x4a3a30                        # the grille's iron, rusty
const BOARD_L := 4.6                          # the board: long, its bottom and top edges over the lawn
const BOARD_LOW := 0.22
const BOARD_TOP := 1.08
const GATE_W := 2.2                           # the gate: wide (outside the pillars), its pillars square, how high to the lintel
const PILLAR := 0.44
const PILLAR_H := 2.8
const Y_SIGN := 0.68                          # the blue signs' middle, over the island
const NO_SIGN := 45.0                         # no sign looks at the road from the east (bearing): Street View shows none there
const SAFFRON_K := 0.35                       # the hidden saffron in the jar: the flower, its glow and its ring this small, to fit in it
const SAFFRON_AT := 0.18                      # how far up the jar's axis from its belly the glow is (its lip is at 0.8)

var mid := Vector2.ZERO                       # the island's middle, on the map (the ring's)
var R := 0.0                                  # its radius, to the outside of its kerb: where the ring's lane begins
var outline := PackedVector2Array()
var ring_r := 0.0
var ring_hw := 0.0
var things: Array = []                        # where what stands on it is, on the map (the self-test)
var decks := 0
var signs := 0
var gate_mid := Vector2.ZERO                  # where the gate, the board and the jar stand, on the map
var board_mid := Vector2.ZERO
var jar_mid := Vector2.ZERO
var _look := Vector2.ZERO                     # the way the board and the gate look
var jar_xf := Transform3D()                   # the jar's frame, in the island's: z up its axis to the mouth, its belly at 0
var saffron_spot := Vector2.ZERO              # where its hidden saffron is, on the map (in the game's flowers, "id": "rotonda_norte")
var saffron_glow := Vector3.ZERO              # the middle of that flower's glow, in the island's frame

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"asfalto":
			m = W._tmat(0x77727a, "asphalt", 3.0)
		"cesped":
			m = W._tmat(0x5c7c40, "leaf", 2.0)
		"adoquin":            # the brick band: its UVs run round the ring, in metres
			var am: StandardMaterial3D = Tex.mat("red_brick_03@1.05", Color(0.88, 0.72, 0.7), false, 1.0)
			am.normal_enabled = false
			m = am
		"ladrillo":           # pale salmon brick with light joints
			m = _glow(Tex.mat("brick_wall_09", Color(1.0, 0.94, 0.9)), 0.4)      # (its north face is in the shade: lit by the lawn)
		"tiles_viejas":       # old curved tiles, gone grey (its UVs in units of 1.6 m, as obra.gd's "tiles")
			var tm: StandardMaterial3D = Tex.mat(Tex.pick("tiles") if Tex.pick("tiles") != "" else "clay_roof_tiles_02", Color(0.7, 0.64, 0.58), true, 1.6)
			tm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = tm
		"chapa", "oxido":
			var cm := StandardMaterial3D.new()
			cm.albedo_texture = load("res://assets/rotonda_norte/" + ("chapa" if key == "chapa" else "oxido") + ".png")
			cm.roughness = 0.9
			cm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			if key == "oxido":
				cm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = cm
		"barro":
			m = Tex.mat("granular_concrete", Color(0.8, 0.62, 0.5))
		"barro_dentro":
			m = Parts.mat(0x4a3428)
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> bool:
	W = world
	if not _ring():
		return false
	R = ring_r - ring_hw
	level = MapData.height(mid)
	transform = Transform3D(Basis.IDENTITY, Vector3(mid.x, level, mid.y))
	W.add_child(self)
	for i in range(64):
		outline.append(mid + Vector2(cos(TAU * i / 64.0), sin(TAU * i / 64.0)) * R)
	var b := deg_to_rad(FACE)
	_look = Vector2(sin(b), -cos(b))
	gate_mid = mid + (GATE - REAL)
	board_mid = mid + (BOARD - REAL)
	jar_mid = mid + (JAR - REAL)
	ridge_hex = 0x8a6c5c                      # (the round tiles of its gate's ridge and eaves, old and grey)
	_floor()
	_kerbs()
	_walkable()
	_gate()
	_board()
	_jar()
	_saffron()
	_signs()
	home()
	_commit()
	return true

## The ring road of the map round NEAR: the island's middle is the middle of its nodes
func _ring() -> bool:
	for r in MapData.roads:
		var p: PackedInt32Array = r["p"]
		if int(r["k"]) != 0 or p.size() < 8 or p[0] != p[p.size() - 1]:
			continue
		var c := Vector2.ZERO
		for i in range(p.size() - 1):
			c += (MapData.nodes[p[i]] as Vector2) / (p.size() - 1)
		if c.distance_to(NEAR) > 6.0:
			continue
		var rr := 0.0
		for i in range(p.size() - 1):
			rr += (MapData.nodes[p[i]] as Vector2).distance_to(c) / (p.size() - 1)
		mid = c
		ring_r = rr
		ring_hw = float(r["w"]) / 2.0
		return true
	return false

# ---------------- laying things on the ground (as rotonda.gd) ----------------
func _ccw(p: PackedVector2Array) -> PackedVector2Array:
	if Geometry2D.is_polygon_clockwise(p):
		p.reverse()
	return p

func _p3(q: Vector2, lift: float) -> Vector3:
	return Vector3(q.x - mid.x, MapData.height(q) - level + lift, q.y - mid.y)

func _facets(box: Rect2) -> Array:
	var out: Array = []
	var g: float = MapData.rg
	for i in range(int(floor((box.position.x - MapData.rx0) / g)), int(floor((box.end.x - MapData.rx0) / g)) + 1):
		for j in range(int(floor((box.position.y - MapData.rz0) / g)), int(floor((box.end.y - MapData.rz0) / g)) + 1):
			var a := Vector2(MapData.rx0 + i * g, MapData.rz0 + j * g)
			out.append(_ccw(PackedVector2Array([a, a + Vector2(g, 0), a + Vector2(g, g)])))
			out.append(_ccw(PackedVector2Array([a, a + Vector2(g, g), a + Vector2(0, g)])))
	return out

func _box_of(poly: PackedVector2Array) -> Rect2:
	var box := Rect2(poly[0], Vector2.ZERO)
	for q in poly:
		box = box.expand(q)
	return box

## how high the floor of the island is over the ground at a spot (its brick band rises from the kerb to the white kerb)
func lift_at(q: Vector2) -> float:
	var r := q.distance_to(mid)
	if r < LAWN_R:
		return LAWN
	if r < LAWN_R + WHITE_W - 0.005:
		return WHITE_TOP
	if r >= R - OUTER_W:
		return KERB
	return lerpf(BAND_IN, KERB, clampf((r - LAWN_R - WHITE_W) / (R - OUTER_W - LAWN_R - WHITE_W), 0.0, 1.0))

## a piece of this outline (on the map) laid on the ground, cut along the relief's facets: `lift` over it, or (lift < 0)
## as high as the island's floor is there; `ac` (an angle) gives it UVs that run round the ring, in metres
func _lay(poly: PackedVector2Array, lift: float, key, ac := INF) -> void:
	if poly.size() < 3:
		return
	pieces += 1
	poly = _ccw(poly)
	for facet: PackedVector2Array in _facets(_box_of(poly)):
		for piece in Geometry2D.intersect_polygons(poly, facet):
			if piece.size() < 3 or Geometry2D.is_polygon_clockwise(piece):
				continue
			var idx := Geometry2D.triangulate_polygon(piece)
			for t in range(0, idx.size(), 3):
				var q: Array = [piece[idx[t]], piece[idx[t + 1]], piece[idx[t + 2]]]
				var v: Array = []
				var uv = null
				for e in q:
					v.append(_p3(e, lift if lift >= 0.0 else lift_at(e)))
				if ac != INF:
					uv = []
					for e: Vector2 in q:
						var d: Vector2 = e - mid
						uv.append(Vector2(wrapf(d.angle() - ac, -PI, PI) * d.length() + ac * 7.0, d.length()))
				var n: Vector3 = ((v[1] as Vector3) - v[0]).cross((v[2] as Vector3) - v[0]).normalized()
				if n.y < 0.0:
					n = -n
				tri(v[0], v[1], v[2], key, n, uv)

## a piece of a ring round the middle: from radius r0 to r1, from angle a0 to a1 (radians, map angles)
func _band(r0: float, r1: float, a0: float, a1: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := maxi(2, int(ceil((a1 - a0) / 0.06)))
	for i in range(n + 1):
		var a: float = lerpf(a0, a1, float(i) / n)
		pts.append(mid + Vector2(cos(a), sin(a)) * r1)
	for i in range(n, -1, -1):
		var a: float = lerpf(a0, a1, float(i) / n)
		pts.append(mid + Vector2(cos(a), sin(a)) * r0)
	return pts

func _disc(r: float, n := 64) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		pts.append(mid + Vector2(cos(TAU * i / n), sin(TAU * i / n)) * r)
	return pts

# ---------------- the island ----------------
## the apron of asphalt round it (over the pale ring the world drew there), the brick band, the lawn
func _floor() -> void:
	for k in range(12):
		_lay(_band(R - 0.1, R + 2.6, TAU * k / 12.0, TAU * (k + 1) / 12.0), 0.006, "asfalto")
	for k in range(36):
		var a0: float = TAU * k / 36.0
		var a1: float = TAU * (k + 1) / 36.0
		_lay(_band(LAWN_R + WHITE_W, R - OUTER_W + 0.01, a0, a1), -1.0, "adoquin", (a0 + a1) / 2.0)
	_lay(_disc(LAWN_R + 0.01), LAWN, "cesped")

## the outer kerb, its top and face painted in turns of red and white; the white kerb round the lawn; and what stops a
## car, with a chamfer so that it rides up on to it rather than into it
func _kerbs() -> void:
	var n := 40
	for k in range(n):
		var a0: float = TAU * k / n
		var a1: float = TAU * (k + 1) / n
		var key = RED if k % 2 == 0 else WHITE
		_lay(_band(R - OUTER_W, R, a0, a1), KERB + 0.002, key)
		var p := mid + Vector2(cos(a0), sin(a0)) * R
		var q := mid + Vector2(cos(a1), sin(a1)) * R
		quad(_p3(p, -0.12), _p3(q, -0.12), _p3(q, KERB), _p3(p, KERB), key, Vector3(cos((a0 + a1) / 2.0), 0, sin((a0 + a1) / 2.0)))
	for k in range(48):
		var a0: float = TAU * k / 48.0
		var a1: float = TAU * (k + 1) / 48.0
		_lay(_band(LAWN_R, LAWN_R + WHITE_W, a0, a1), WHITE_TOP, WHITE)
		var out := Vector3(cos((a0 + a1) / 2.0), 0, sin((a0 + a1) / 2.0))
		for side in [[LAWN_R + WHITE_W, BAND_IN - 0.03, 1.0], [LAWN_R, LAWN - 0.02, -1.0]]:
			var p: Vector2 = mid + Vector2(cos(a0), sin(a0)) * float(side[0])
			var q: Vector2 = mid + Vector2(cos(a1), sin(a1)) * float(side[0])
			quad(_p3(p, side[1]), _p3(q, side[1]), _p3(q, WHITE_TOP), _p3(p, WHITE_TOP), WHITE, out * side[2])
	var pts: Array = []
	for q in outline:
		pts.append(_p3(q, KERB))
		pts.append(_p3(q, -1.0))
	for i in range(64):
		var q := mid + Vector2(cos(TAU * i / 64.0), sin(TAU * i / 64.0)) * (R + 0.3)
		pts.append(_p3(q, 0.0))
		pts.append(_p3(q, -1.0))
	_hull(pts)

## whoever walks on it stands on its floor: for each facet of the relief under it, a sloping deck for the kerb (and a
## step out from it), for each piece of the brick band (which also rises to the middle), and for the lawn
func _walkable() -> void:
	var r_in := LAWN_R + WHITE_W
	var r_out := R - OUTER_W
	var rise := (KERB - BAND_IN) / (r_out - r_in)
	var parts: Array = [[_disc(r_in), LAWN, false]]
	for k in range(24):
		var a0: float = TAU * k / 24.0
		var a1: float = TAU * (k + 1) / 24.0
		parts.append([_band(r_in, r_out, a0, a1), -1.0, true])
		parts.append([_band(r_out, R + STEP, a0, a1), KERB, false])
	for part in parts:
		var poly: PackedVector2Array = _ccw(part[0])
		for facet: PackedVector2Array in _facets(_box_of(poly)):
			var pa: Vector2 = facet[0] * 0.98 + (facet[1] + facet[2]) * 0.01
			var pb: Vector2 = facet[1] * 0.98 + (facet[0] + facet[2]) * 0.01
			var pc: Vector2 = facet[2] * 0.98 + (facet[0] + facet[1]) * 0.01
			var ha: float = MapData.height(pa)
			var v1: Vector2 = pb - pa
			var v2: Vector2 = pc - pa
			var hb: float = MapData.height(pb) - ha
			var hc: float = MapData.height(pc) - ha
			var det: float = v1.x * v2.y - v1.y * v2.x
			var grad := Vector2((hb * v2.y - hc * v1.y) / det, (v1.x * hc - v2.x * hb) / det)
			for piece in Geometry2D.intersect_polygons(poly, facet):
				if piece.size() < 3 or Geometry2D.is_polygon_clockwise(piece):
					continue
				var o := Vector2.ZERO
				for q in piece:
					o += q / piece.size()
				var r2 := 0.0
				for q in piece:
					r2 = maxf(r2, o.distance_squared_to(q))
				var lift: float = part[1] if part[1] >= 0.0 else lift_at(o)
				var g2 := grad + ((o - mid).normalized() * rise if part[2] else Vector2.ZERO)
				MapData.decks.append({"o": o, "poly": piece, "r2": r2 + 1.0, "top": ha + grad.dot(o - pa) + lift, "grad": g2})
				decks += 1

## where something stands on the island, in its frame, at the height of its floor there
func _stand(at: Vector2) -> Vector3:
	things.append(at)
	yard.append(at)
	return Vector3(at.x - mid.x, MapData.height(at) - level + lift_at(at), at.y - mid.y)

## the frame of something that looks the way the board looks, standing at o: +x to its right as you read it, +z out of
## its face (not a mirror: x = up x z)
func _facing(o: Vector3) -> Transform3D:
	return Transform3D(Basis(Vector3(_look.y, 0, -_look.x), Vector3.UP, Vector3(_look.x, 0, _look.y)), o)

# ---------------- what stands on it ----------------
## The gate: two pillars of brick, a lintel and a course over it, a small roof of curved tiles with its ridge; between
## the pillars a low sill with bricks on edge and an iron grille over it. All of the same pale bare brick, both faces
## (in the sun from the south it looks nearly white: it is not whitewashed).
func _gate() -> void:
	var o := _stand(gate_mid)
	var lo: float = minf(MapData.height(gate_mid + Vector2(1.1, 0.25)), MapData.height(gate_mid - Vector2(1.1, 0.25))) - level + LAWN
	o.y = lo
	var keep := _xf
	_xf = _facing(o)
	var hw := GATE_W / 2.0
	var back := -PILLAR / 2.0
	for x0 in [-hw, hw - PILLAR]:
		box(x0, -0.15, back, PILLAR, PILLAR_H + 0.15, PILLAR, "ladrillo")
	var gx := hw - PILLAR
	box(-gx, -0.15, -0.15, gx * 2.0, 0.57, 0.3, "ladrillo")                    # the sill
	box(-gx, 0.42, -0.17, gx * 2.0, 0.07, 0.34, "ladrillo")                     # its bricks on edge
	box(-hw, PILLAR_H, back, GATE_W, 0.26, PILLAR, "ladrillo")                 # the lintel
	box(-hw - 0.05, PILLAR_H + 0.26, back - 0.05, GATE_W + 0.1, 0.07, PILLAR + 0.1, "ladrillo")      # the course over it
	# the roof: two slopes from a ridge along the gate, their eaves out over both faces, the gables filled with brick
	var eave := PILLAR_H + 0.36
	var top := PILLAR_H + 0.66
	var ox := hw + 0.08
	var oz := PILLAR / 2.0 + 0.26
	for s in [1.0, -1.0]:
		roof([Vector3(-ox, eave, oz * s), Vector3(ox, eave, oz * s), Vector3(ox, top, 0.0), Vector3(-ox, top, 0.0)], "tiles_viejas")
		for k in range(13):                                                     # the round ends of the tiles along the eaves
			var x: float = lerpf(-ox + 0.1, ox - 0.1, k / 12.0)
			bar(Vector3(x, eave + 0.02, oz * s * 0.8), Vector3(x, eave - 0.005, oz * s + 0.03 * s), 0.11, 0.07, ridge_hex)
	for x in [-hw, hw]:
		tri(Vector3(x, PILLAR_H + 0.33, back), Vector3(x, PILLAR_H + 0.33, -back), Vector3(x, top - 0.04, 0.0), "ladrillo", Vector3(signf(x), 0, 0))
	ridge(Vector3(-ox - 0.04, top, 0.0), Vector3(ox + 0.04, top, 0.0))
	# the grille: round bars from the sill to under the lintel, their tips sharpened, on three flat rails
	var n := 11
	for i in range(n):
		var x: float = lerpf(-gx + 0.07, gx - 0.07, float(i) / (n - 1))
		bar(Vector3(x, 0.49, 0.0), Vector3(x, PILLAR_H - 0.12, 0.0), 0.016, 0.016, RUST)
		bar(Vector3(x, PILLAR_H - 0.12, 0.0), Vector3(x, PILLAR_H - 0.04, 0.0), 0.008, 0.03, RUST)
	for y in [0.64, 1.62, PILLAR_H - 0.3]:
		box(-gx, y, -0.02, gx * 2.0, 0.045, 0.012, RUST)
	box(-0.025, 0.49, -0.025, 0.05, PILLAR_H - 0.55, 0.05, RUST)               # (where its two leaves meet)
	_xf = keep
	solid(o + Vector3(0, 1.5, 0), Vector3(GATE_W, 3.0, PILLAR), atan2(_look.x, _look.y))

## The board: a plate of rusty steel with ragged edges, as if cut with a torch, on three square legs; the town's name
## on its face, its back bare; its east end (the reader's left) rolled into a round edge down to the lawn.
func _board() -> void:
	var o := _stand(board_mid)
	var keep := _xf
	_xf = _facing(o)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4021
	var hl := BOARD_L / 2.0
	var tall := BOARD_TOP - BOARD_LOW
	var low := PackedVector2Array()
	var high := PackedVector2Array()
	var n := 46
	for i in range(n + 1):
		var x: float = lerpf(-hl, hl, float(i) / n)
		var notch: float = -0.045 if rng.randf() < 0.12 else 0.0
		high.append(Vector2(x, BOARD_TOP + rng.randf_range(-0.018, 0.018) + notch))
		low.append(Vector2(x, BOARD_LOW + rng.randf_range(-0.02, 0.02) + (0.03 if rng.randf() < 0.1 else 0.0)))
	var pts := PackedVector2Array(low)
	for i in range(n, -1, -1):
		pts.append(high[i])
	var idx := Geometry2D.triangulate_polygon(pts)
	var th := 0.015
	for t in range(0, idx.size(), 3):
		var q: Array = [pts[idx[t]], pts[idx[t + 1]], pts[idx[t + 2]]]
		var front: Array = []
		var behind: Array = []
		for e: Vector2 in q:
			front.append(Vector2((e.x + hl) / BOARD_L, clampf((BOARD_TOP - e.y) / tall, 0.0, 1.0)))
			behind.append(Vector2(e.x / 0.9, e.y / 0.9))
		tri(Vector3(q[0].x, q[0].y, 0.0), Vector3(q[1].x, q[1].y, 0.0), Vector3(q[2].x, q[2].y, 0.0), "chapa", Vector3(0, 0, 1), front)
		tri(Vector3(q[0].x, q[0].y, -th), Vector3(q[1].x, q[1].y, -th), Vector3(q[2].x, q[2].y, -th), "oxido", Vector3(0, 0, -1), behind)
	for i in range(pts.size()):                                                 # its cut edges
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		var d := (b - a).normalized()
		quad(Vector3(a.x, a.y, -th), Vector3(b.x, b.y, -th), Vector3(b.x, b.y, 0.0), Vector3(a.x, a.y, 0.0), "oxido", Vector3(d.y, -d.x, 0),
			[Vector2(a.x, 0), Vector2(b.x, 0), Vector2(b.x, 0.02), Vector2(a.x, 0.02)])
	# the rolled end: half a tube, from the lawn to the top of the plate, bulging out east
	var rc := 0.09
	var zc := -th / 2.0
	var y1: float = high[0].y
	for k in range(8):
		var f0: float = PI * k / 8.0
		var f1: float = PI * (k + 1) / 8.0
		var p0 := Vector3(-hl - sin(f0) * rc, 0.0, zc + cos(f0) * rc)
		var p1 := Vector3(-hl - sin(f1) * rc, 0.0, zc + cos(f1) * rc)
		var fm := (f0 + f1) / 2.0
		quad(p0 - Vector3(0, 0.08, 0), p1 - Vector3(0, 0.08, 0), p1 + Vector3(0, y1, 0), p0 + Vector3(0, y1, 0), "oxido", Vector3(-sin(fm), 0, cos(fm)),
			[Vector2(f0 * rc / 0.9, 0), Vector2(f1 * rc / 0.9, 0), Vector2(f1 * rc / 0.9, y1 / 0.9), Vector2(f0 * rc / 0.9, y1 / 0.9)])
		tri(p0 + Vector3(0, y1, 0), p1 + Vector3(0, y1, 0), Vector3(-hl, y1, zc), "oxido", Vector3.UP, [Vector2(0, 0), Vector2(0.1, 0), Vector2(0.05, 0.1)])
	for x in [-1.25, 0.35, hl - 0.05]:                                         # its legs, behind it
		box(x - 0.025, -0.15, -th - 0.05, 0.05, BOARD_LOW + 0.4, 0.05, 0x5a3a2a)
	_xf = keep
	solid(o + Vector3(0, 0.6, 0), Vector3(BOARD_L + 0.2, 1.2, 0.2), atan2(_look.x, _look.y))

## The jar: a great tinaja of clay lying on its belly on the lawn, its mouth up to the north-west, the dark of its inside
## showing; a long lamp lying on the grass beside it, to light it at night (unlit), and a small one at its foot.
func _jar() -> void:
	var o := _stand(jar_mid)
	var b := deg_to_rad(JAR_AXIS)
	var t := deg_to_rad(JAR_TILT)
	var axis := Vector3(sin(b) * cos(t), sin(t), -cos(b) * cos(t))
	var u := axis.cross(Vector3.UP).normalized()
	var v := axis.cross(u)
	# its outline, from the middle of its foot to the lip and back down inside: [along the axis, radius]
	var prof: Array = [[0.0, 0.0], [0.0, 0.19], [0.05, 0.26], [0.24, 0.38], [0.5, 0.47], [0.76, 0.515], [0.98, 0.51], [1.18, 0.46],
		[1.33, 0.38], [1.44, 0.31], [1.5, 0.295], [1.52, 0.32], [1.57, 0.338], [1.61, 0.322], [1.625, 0.29], [1.6, 0.268],
		[1.5, 0.27], [1.38, 0.33], [1.1, 0.44], [0.8, 0.47], [0.45, 0.42], [0.15, 0.24], [0.08, 0.0]]
	var inside := 15                         # (from this point on it is its inside)
	var sides := 20
	var jb := Basis(u, v, axis)
	var half := 0.8                          # (its belly, where o is, is this far up the axis from its foot)
	var lowest := INF
	for pr in prof:
		for i in range(sides):
			var a := TAU * i / sides
			var p: Vector3 = jb * Vector3(cos(a) * pr[1], sin(a) * pr[1], pr[0] - half)
			lowest = minf(lowest, p.y)
	var keep := _xf
	_xf = Transform3D(jb, o + Vector3(0, -lowest - 0.12, 0))      # (sunk a little: it has settled into the turf)
	jar_xf = _xf
	for j in range(prof.size() - 1):
		var s0: float = prof[j][0] - half
		var r0: float = prof[j][1]
		var s1: float = prof[j + 1][0] - half
		var r1: float = prof[j + 1][1]
		var key: String = "barro" if j < inside else "barro_dentro"
		for i in range(sides):
			var a0 := TAU * i / sides
			var a1 := TAU * (i + 1) / sides
			var am := (a0 + a1) / 2.0
			var n := Vector3(cos(am) * (s1 - s0), sin(am) * (s1 - s0), -(r1 - r0))
			if n.length() < 0.0001:
				continue
			quad(Vector3(cos(a0) * r0, sin(a0) * r0, s0), Vector3(cos(a1) * r0, sin(a1) * r0, s0), Vector3(cos(a1) * r1, sin(a1) * r1, s1),
				Vector3(cos(a0) * r1, sin(a0) * r1, s1), key, n.normalized())
	pieces += 1
	_xf = keep
	var side := Vector3(u.x, 0, u.z).normalized()
	var lamp := o + side * 1.2 - Vector3(axis.x, 0, axis.z).normalized() * 0.2
	lamp.y = MapData.height(mid + Vector2(lamp.x, lamp.z)) - level + LAWN
	tbox(Transform3D(Basis(Vector3.UP, atan2(axis.x, axis.z)).scaled_local(Vector3(0.12, 0.07, 0.6)), lamp + Vector3(0, 0.035, 0)), 0x8c9094)
	var foot := o - Vector3(axis.x, 0, axis.z).normalized() * 1.25
	foot.y = MapData.height(mid + Vector2(foot.x, foot.z)) - level + LAWN
	drum(foot - Vector3(0, 0.02, 0), 0.07, 0.07, 0.12, 0x26262a, 10)
	solid(o + Vector3(0, 0.5, 0), Vector3(0.95, 1.0, 1.6), PI - b)

## The hidden saffron (the user, 24 November 2026, choosing where: «Dentro de la boca de la tinaja»): a flower inside
## the jar, just in from its mouth. Its glow shows in the dark of the mouth to who looks into it from the north-west,
## and you take it standing at the jar (the game takes a flower within 1.26 m); it counts once a game, as the other
## hidden ones. Every saffron flower is dressed by pickups.gd: it rises 0.42 and spins, with a glow 1.45 across at 1.02
## and a ring 0.56 round at its foot. Here the flower is SAFFRON_K of its size, and all that with it, so that the lot
## fits in the jar's hollow (0.44 to 0.47 m round there): the glow sits on the axis, the flower's foot 0.36 under it.
func _saffron() -> void:
	saffron_glow = jar_xf.origin + jar_xf.basis.z * SAFFRON_AT + Vector3(0, 0.05, 0)
	var flower := Node3D.new()
	flower.add_child(Parts.part("cyl", 0x5f9c4a, Vector3(0, 0.3, 0), Vector3(0.03, 0.6, 0.03)))
	for k in range(5):
		flower.add_child(Parts.part("ball", 0x9b5de5, Vector3(cos(k * 1.257) * 0.12, 0.66, sin(k * 1.257) * 0.12), Vector3(0.11, 0.2, 0.11)))
	flower.add_child(Parts.part("ball", 0xe63946, Vector3(0, 0.74, 0), Vector3(0.05, 0.13, 0.05)))
	flower.scale = Vector3.ONE * SAFFRON_K
	flower.position = saffron_glow - Vector3(0, 1.02 * SAFFRON_K, 0)
	add_child(flower)
	saffron_spot = mid + Vector2(flower.position.x, flower.position.z)
	var game = W.get_parent()                           # (the game: the world is its child)
	if game != null and game.get("flowers") != null:
		(game.flowers as Array).append({"node": flower, "p": saffron_spot, "id": "rotonda_norte", "hidden": true})      # (hidden: Sistemas keeps count of these)

## the blue signs of the roundabout at its edge, one before each street that comes into it, looking out at it
func _signs() -> void:
	var ways: Array = []
	for r in MapData.roads:
		var p: PackedInt32Array = r["p"]
		if int(r["k"]) != 0 or p[0] == p[p.size() - 1]:
			continue
		for i in [0, p.size() - 1]:
			var nd: Vector2 = MapData.nodes[p[i]]
			var d: float = nd.distance_to(mid)
			if absf(d - ring_r) > 2.5:
				continue
			var j: int = 1 if i == 0 else p.size() - 2
			var away: Vector2 = (MapData.nodes[p[j]] as Vector2) - mid
			if away.length() < d + 3.0:              # (it must run away from the ring)
				continue
			var a: float = (nd - mid).angle()
			var dup := false
			for w in ways:
				if absf(angle_difference(float(w), a)) < deg_to_rad(35.0):
					dup = true
			var bearing: float = rad_to_deg(atan2(nd.x - mid.x, -(nd.y - mid.y)))
			if absf(angle_difference(deg_to_rad(bearing), deg_to_rad(NO_SIGN))) < deg_to_rad(25.0):
				dup = true
			if not dup:
				ways.append(a)
	for a in ways:
		var dir := Vector2(cos(a), sin(a))
		var at: Vector2 = mid + dir * (R - 0.45)
		var o := _stand(at)
		var keep := _xf
		_xf = Transform3D(Basis(Vector3(dir.y, 0, -dir.x), Vector3.UP, Vector3(dir.x, 0, dir.y)), o)
		box(-0.03, -0.05, -0.03, 0.06, 0.5, 0.06, 0x9a9da0)
		slab(oval(0.0, Y_SIGN, 0.22, 0.22, 20), 0.04, 0.015, 0x1f5fb0)
		slab(oval(0.0, Y_SIGN, 0.2, 0.2, 20), 0.056, 0.0, 0x2a6ec8)
		for k in range(3):                         # its three white arrows chasing round
			var a0: float = TAU * k / 3.0
			for m in range(4):
				var u0: float = a0 + m * 0.32
				var u1: float = u0 + 0.32
				bar(Vector3(cos(u0) * 0.12, Y_SIGN + sin(u0) * 0.12, 0.06), Vector3(cos(u1) * 0.12, Y_SIGN + sin(u1) * 0.12, 0.06), 0.028, 0.01, 0xfdfcf8)
			var tip := Vector3(cos(a0 + 1.28) * 0.12, Y_SIGN + sin(a0 + 1.28) * 0.12, 0.06)
			bar(tip, tip + Vector3(cos(a0 + 1.28 - 2.4) * 0.055, sin(a0 + 1.28 - 2.4) * 0.055, 0), 0.025, 0.01, 0xfdfcf8)
			bar(tip, tip + Vector3(cos(a0 + 1.28 + 2.2) * 0.055, sin(a0 + 1.28 + 2.2) * 0.055, 0), 0.025, 0.01, 0xfdfcf8)
		_xf = _xf * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)       # its back, grey
		slab(oval(0.0, Y_SIGN, 0.22, 0.22, 20), -0.035, 0.0, 0x9a9da0)
		_xf = keep
		solid(o + Vector3(0, 0.4, 0), Vector3(0.2, 0.8, 0.2))
		signs += 1
