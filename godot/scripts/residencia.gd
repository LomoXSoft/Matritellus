extends "res://scripts/obra.gd"
## The old people's home of the Cristo del Prado, in the hermitage's block, built by hand (the user, 21 November 2026,
## after the hermitage: "After these fixes we can continue with the rest of the apple"; tools/residencia/,
## referencias/cristoprado/).
##
## Catastro has it and the hermitage as one building (4587301): the hermitage is cristoprado.gd; this is the rest. From
## the orthophoto and Street View round the block (2024 on the east arm of the Calle del Cristo and the north end, 2013
## on the west arm):
##   - the great block of three floors between the two arms of the Calle del Cristo, narrow to the north, wide to the
##     south: pale brick with tall irregular panels of rubble between its bays, a foot of rubble with the cellar's
##     barred windows; tall windows behind grilles with their crests on the ground floor, little balconies of iron
##     above, the blinds down; the eaves of tiles round a flat roof with its solar panels;
##   - the main door on the Calle del Cristo, up a flight of steps under a flat canopy, the great fan window over it;
##   - its two levels: the street falls three metres from the north end to the Paseo (the game's relief), so the south
##     part stands a step lower;
##   - the round body of two floors between it and the hermitage's nave; to the square, in the corner between the low
##     wing and the hermitage, the home's gate under the band with its name and a fanlight with the cross, the balcony
##     over it;
##   - the low wing of one floor on the hermitage's square and the west arm, on its foot of pale granite, its deep eaves
##     of tiles on dark rafters over a course of brick dentils, its barred windows; to the square (the user's 360°
##     photos, 21 November: "Here in red the fachada is very different to the photo, also a door is missing") four
##     windows, the one porch of two bays shut by iron gates the whole height with the brotherhood's wooden door, its
##     board and the tile of the Cristo inside, and a last window by the round body.
##   - The wing's face to the square stands 2.85 m behind Catastro's line: the orthophoto has its eave a steady 2.25 m
##     inside that line from end to end (its west face and the hermitage's front sit on theirs), and the photos show
##     the gate of the home in the round body's wall there, which the old line covered.
##
## Frame: the map's own axes (+x east, +z south), the origin at O; y = 0 the ground there.

const READY := true                             # (tools/bake_godot.py looks for this: with it, Catastro's building 4587301 is not raised at all)
const O := Vector2(312.0, 465.0)

# the great block, on the map: its north part and its south part (a step lower), round from the north-west corner
const NORTH: Array = [Vector2(302.77, 434.61), Vector2(311.78, 433.23), Vector2(318.89, 452.64), Vector2(319.3, 454.3), Vector2(298.0, 453.0), Vector2(297.25, 452.76)]
const SOUTH: Array = [Vector2(298.0, 453.0), Vector2(319.3, 454.3), Vector2(320.57, 459.55), Vector2(329.48, 496.30), Vector2(329.81, 497.64), Vector2(328.53, 500.19),
	Vector2(328.20, 500.84), Vector2(320.77, 497.43), Vector2(309.42, 484.58), Vector2(308.49, 485.50), Vector2(309.20, 483.59), Vector2(305.63, 482.28), Vector2(299.14, 453.33)]
# the arc of the round body (Catastro's points), from the east to the west
const ARC: Array = [Vector2(320.77, 497.43), Vector2(321.55, 495.63), Vector2(322.27, 494.57), Vector2(322.81, 493.42), Vector2(323.17, 492.19), Vector2(323.34, 490.92),
	Vector2(323.30, 489.64), Vector2(323.06, 488.38), Vector2(322.64, 487.18), Vector2(322.03, 486.05), Vector2(321.24, 485.04), Vector2(320.32, 484.15),
	Vector2(319.27, 483.42), Vector2(318.11, 482.86), Vector2(316.52, 482.42), Vector2(315.24, 482.30), Vector2(313.97, 482.38), Vector2(312.72, 482.65),
	Vector2(311.52, 483.12), Vector2(310.42, 483.77), Vector2(309.42, 484.58)]
# the round body (part 5), down to the hermitage's nave
const ROUND_BODY: Array = [Vector2(318.61, 502.34), Vector2(304.80, 495.44), Vector2(308.49, 485.50), Vector2(309.42, 484.58)]
# the low wing (part 4, without the hermitage's nave): its face to the square 2.85 m behind Catastro's (see above),
# from its corner on the west arm to the round body's wall
const WING: Array = [Vector2(305.84, 492.65), Vector2(287.36, 485.25), Vector2(292.80, 467.37), Vector2(300.96, 470.38),
	Vector2(297.64, 479.34), Vector2(305.63, 482.28), Vector2(309.20, 483.59), Vector2(308.49, 485.50)]
const CAT_SW := Vector2(286.53, 487.99)         # Catastro's corner of the wing on the west arm
const NAVE_NW := Vector2(303.46, 494.77)        # the corner of the hermitage's front and nave
const BACK := 2.85                              # how far the wing's face stands behind Catastro's line
# along the wing's face to the square, from its corner on the west arm: its windows, its porch and the porch's post
const WIN_S: Array = [1.5, 4.1, 6.7, 9.3]
const PORCH_0 := 10.6
const PORCH_1 := 16.6
const POST := 13.6
const PORCH_D := 2.6
# along the round body's wall to the square (from its north end): the middle of the home's gate
const ZAGUAN := 9.2
# the main door on the Calle del Cristo: along the east face of the south part, from its north end
const DOOR_AT := 16.9

const FLOOR := 3.1
const GROUND_H := 3.6
const EAVES := GROUND_H + 2.0 * FLOOR + 0.55    # over the floor
const BAY := 3.3

var door: Vector2                               # before the main door, on the map (the self-test)
var fn := 0.0                                   # the floors of the north part and of the south part (a step lower), over the frame's ground
var fs := 0.0
var round_ring: Array = []                      # the round body's outline: its west side, the arc back to the east, the strip by the crossing
var openings := 0
var y_wing := 0.0

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"ladrillo":         # the pale salmon brick
			m = Tex.mat("brick_wall_003@0.9", Color(0.98, 1.1, 1.3))
		"mamposteria":      # the rubble of its panels: grey and rust stones, big, in pale mortar
			m = Tex.mat("stone_wall", Color(1.05, 0.98, 0.9))
		"zocalo":           # the rubble of its foot, darker
			m = Tex.mat("stone_wall", Color(1.0, 0.95, 0.86))
		"acera":            # its pavements, of pale tiles
			m = W._tmat(0xd4d0c8, "pavement", 1.0)
		"losa":             # the square's pale stone, as the hermitage lays it
			m = W._tmat(0xd8d0c2, "pavement", 1.2)
		"granito":          # the low wing's foot of pale granite slabs
			m = Tex.mat("granite_tile_03@1.8", Color(0.86, 0.85, 0.83))
		"zocalo_ermita":    # the hermitage's foot of rubble, as it has it
			m = Tex.mat("stone_wall", Color(0.88, 0.82, 0.74))
		"cubierta":         # the flat roof
			m = W._tmat(0xb9b2a4, "pavement", 2.0)
		"panel":            # the solar panels
			var pm := StandardMaterial3D.new()
			pm.albedo_color = Color(0.13, 0.17, 0.26)
			pm.roughness = 0.25
			pm.metallic_specular = 0.7
			m = pm
		"cristal":
			var gm := StandardMaterial3D.new()
			gm.albedo_color = Color(0.2, 0.26, 0.32)
			gm.roughness = 0.15
			gm.metallic_specular = 0.7
			m = gm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	level = MapData.height(O)
	transform = Transform3D(Basis(), Vector3(O.x, level, O.y))
	W.add_child(self)
	for q: Vector2 in NORTH:
		fn = maxf(fn, MapData.height(q) - level)
	fn += 0.2
	fs = MapData.height(SOUTH[1]) - level + 0.2
	round_ring = ROUND_BODY.duplicate()
	for i in range(ARC.size() - 2, -1, -1):
		round_ring.append(ARC[i])
	round_ring += [Vector2(328.20, 500.84), Vector2(326.0, 505.21), Vector2(318.93, 501.69)]
	var e0: Vector2 = SOUTH[2]
	var e1: Vector2 = SOUTH[3]
	var de: Vector2 = (e1 - e0).normalized()
	var dp: Vector2 = e0 + de * DOOR_AT
	door = dp + Vector2(de.y, -de.x) * 4.5
	_block(NORTH, fn, [0, 1, 2, 5], -1.0)
	_block(SOUTH, fs, [1, 2, 10, 11], DOOR_AT)
	_arc_wall()
	_round_body()
	_wing()
	_franja()
	for ab in [[NORTH[1], NORTH[0]], [NORTH[2], NORTH[1]], [NORTH[0], NORTH[5]], [SOUTH[2], SOUTH[1]], [SOUTH[3], SOUTH[2]], [SOUTH[12], SOUTH[11]], [WING[2], CAT_SW]]:
		_acera(ab[0], ab[1])
	home()
	_commit()
	for ring in [NORTH, SOUTH, round_ring, WING]:
		var pr := PackedVector2Array()
		for q: Vector2 in ring:
			pr.append(_l(q))
		for part in Geometry2D.decompose_polygon_in_convex(pr):
			var pts: Array = []
			for q: Vector2 in part:
				pts.append(q)
			_prism(pts, -4.0, fn + EAVES)
	_tell_map()
	MapData.decks = _decks + MapData.decks

## a spot of the map in this frame
func _l(p: Vector2) -> Vector2:
	return p - O

## What stands here, for whoever asks the map how much room there is and for the little map.
func _tell_map() -> void:
	for ring in [NORTH, SOUTH, round_ring, WING]:
		var pts := PackedVector2Array()
		for q: Vector2 in ring:
			pts.append(q)
		MapData.outlines.append(pts)
		if not MapData._wall_grid.is_empty():
			for i in range(pts.size()):
				var a: Vector2 = pts[i]
				var b: Vector2 = pts[(i + 1) % pts.size()]
				MapData._grid_add(MapData._wall_grid, a.min(b), a.max(b), [a, b])

# ---------------- helpers ----------------
## a window behind a grille of iron, its crest of a cross and scrolls over it
func _reja(r: Rect2, full := false) -> void:
	window(r, 0x4a3a2c, 0x2a3640, 1)
	if full:                                                            # (the red wooden blind right down, its slats)
		box(r.position.x - 0.05, r.position.y - 0.04, -DEEP, r.size.x + 0.1, 0.045, DEEP + 0.07, "granito")     # (its sill, on the granite foot)
		box(r.position.x + 0.07, r.position.y + 0.07, -DEEP + 0.12, r.size.x - 0.14, r.size.y - 0.14, 0.02, 0x6a3a2a)
		for k in range(1, int((r.size.y - 0.14) / 0.11)):
			box(r.position.x + 0.07, r.position.y + 0.07 + k * 0.11, -DEEP + 0.14, r.size.x - 0.14, 0.012, 0.006, 0x48241a)
	else:
		box(r.position.x + 0.07, r.position.y + 0.07, -DEEP + 0.1, r.size.x - 0.14, r.size.y * 0.55, 0.02, 0x6a4a34)     # (the blind half down)
	grille(r, 0.12, IRON)
	var cx := r.position.x + r.size.x / 2.0
	var y := r.end.y + 0.06
	box(cx - 0.015, y, 0.1, 0.03, 0.42, 0.03, IRON)
	box(cx - 0.1, y + 0.3, 0.1, 0.2, 0.03, 0.03, IRON)
	for s in [-1.0, 1.0]:
		bar(Vector3(cx + s * 0.05, y, 0.11), Vector3(cx + s * r.size.x * 0.45, y + 0.16, 0.11), 0.025, 0.025, IRON)
	openings += 1

## a window above with its little balcony: the slab, the iron railing, the brown blind down
func _balcon(r: Rect2) -> void:
	window(r, 0x4a3a2c, 0x2a3640, 1)
	box(r.position.x + 0.07, r.position.y + r.size.y * 0.3, -DEEP + 0.1, r.size.x - 0.14, r.size.y * 0.7 - 0.07, 0.02, 0x7a5638)
	_baranda(r.position.x - 0.2, r.end.x + 0.2, r.position.y)
	openings += 1

## a little balcony from x0 to x1, its floor at y: the slab, the iron railing
func _baranda(x0: float, x1: float, y: float) -> void:
	box(x0, y - 0.12, 0.0, x1 - x0, 0.12, 0.45, 0x8a7a68)
	for k in range(int((x1 - x0) / 0.12) + 1):
		box(x0 + k * 0.12, y, 0.42, 0.02, 0.95, 0.02, IRON)
	box(x0, y + 0.93, 0.0, x1 - x0, 0.04, 0.46, IRON)
	box(x0, y + 0.12, 0.41, x1 - x0, 0.03, 0.03, IRON)
	for x in [x0, x1 - 0.03]:
		box(x, y, 0.0, 0.03, 0.95, 0.45, IRON)

## The home's gate in the round body's wall: two leaves of iron bars with their spikes, the black band with the home's
## name in gold, the fanlight of iron with the cross in its ring; the passage going in behind it.
func _zaguan(r: Rect2) -> void:
	var x0 := r.position.x
	var x1 := r.end.x
	var g := r.position.y
	var gy := g + 2.05                                                  # (the leaves' top)
	var cx := (x0 + x1) / 2.0
	for i in range(15):
		var x: float = lerpf(x0 + 0.05, x1 - 0.05, i / 14.0)
		box(x - 0.012, g, -0.12, 0.024, gy - g, 0.024, IRON)
		box(x - 0.022, gy - 0.12, -0.125, 0.044, 0.06, 0.034, IRON)     # (its spike's collar)
	for y in [g + 0.1, g + 0.9, gy - 0.06]:
		box(x0, y - 0.02, -0.13, x1 - x0, 0.04, 0.03, IRON)
	for x in [x0 + 0.01, cx - 0.02, x1 - 0.05]:                         # (the leaves' stiles, where they meet)
		box(x, g, -0.135, 0.04, gy - g, 0.04, IRON)
	box(x0, gy, -0.12, x1 - x0, 0.2, 0.05, 0x161618)                    # (the band with its name)
	_text("RESIDENCIA DE ANCIANOS CRISTO DEL PRADO", Vector3(cx, gy + 0.1, -0.065), 36, 0xd8b04a, 0.0017)
	var fy0 := gy + 0.2
	var fy1 := r.end.y
	for i in range(1, 8):                                               # (the fanlight's bars)
		var x: float = lerpf(x0, x1, i / 8.0)
		if absf(x - cx) > 0.3:
			box(x - 0.012, fy0, -0.12, 0.024, fy1 - fy0, 0.024, IRON)
	box(x0, fy1 - 0.05, -0.12, x1 - x0, 0.05, 0.04, IRON)
	var mid := Vector3(cx, (fy0 + fy1) / 2.0, -0.1)
	var rr := minf(0.33, (fy1 - fy0) / 2.0 - 0.02)
	for k in range(20):                                                 # (its ring)
		var a0 := TAU * k / 20.0
		var a1 := TAU * (k + 1) / 20.0
		var c0 := Vector3(cos(a0), sin(a0), 0)
		var c1 := Vector3(cos(a1), sin(a1), 0)
		quad(mid + c0 * (rr - 0.04), mid + c1 * (rr - 0.04), mid + c1 * rr, mid + c0 * rr, IRON, Vector3(0, 0, 1))
	for k in range(4):                                                  # (the cross: four arms widening outwards)
		var d := Vector3(cos(PI / 2.0 * k), sin(PI / 2.0 * k), 0)
		var s := Vector3(-d.y, d.x, 0)
		quad(mid + s * 0.025, mid + d * (rr - 0.05) + s * 0.1, mid + d * (rr - 0.05) - s * 0.1, mid - s * 0.025, IRON, Vector3(0, 0, 1))
	# the passage behind: its sides, its floor, the dark end
	var deep := -2.2
	for x in [x0, x1]:
		quad(Vector3(x, g, deep), Vector3(x, g, -DEEP), Vector3(x, fy1, -DEEP), Vector3(x, fy1, deep), "ladrillo", Vector3(1, 0, 0) if x == x0 else Vector3(-1, 0, 0))
	box(x0, g - 0.085, deep, x1 - x0, 0.1, -deep, 0xb8b0a2)
	box(x0, fy1, deep, x1 - x0, 0.05, -deep - DEEP, 0x4a443c)
	box(x0, g, deep, x1 - x0, fy1 - g, 0.03, 0x3a332c)
	openings += 1

## a barred window of the cellar, low in the foot
func _sotano(x: float, y: float) -> void:
	box(x - 0.55, y, -0.2, 1.1, 0.45, 0.02, 0x1e1e20)
	for k in range(9):
		box(x - 0.55 + k * 0.1375, y, 0.0, 0.02, 0.45, 0.03, IRON)
	box(x - 0.55, y + 0.42, 0.0, 1.1, 0.03, 0.04, IRON)

## The face of the great block from a to b (on the map), its floor at f (over the frame's ground): its foot of rubble
## down to the street, its bays (a door bay at `door_at`, along from a), rubble between the bays, the cornice.
func _fachada(a: Vector2, b: Vector2, f: float, door_at := -1.0) -> void:
	var la := _l(a)
	var lb := _l(b)
	var ln := face(la, lb)
	var top := f + EAVES
	var n := maxi(1, int(floor(ln / BAY)))
	var pitch := ln / n
	var holes: Array = []
	var panels: Array = []
	var bays: Array = []
	for k in range(n):
		var cx: float = pitch * (k + 0.5)
		if door_at >= 0.0 and absf(cx - door_at) < 3.0:
			continue
		if cx < 0.9 or cx > ln - 0.9:
			continue
		bays.append(cx)
	for cx: float in bays:
		holes.append(Rect2(cx - 0.65, f + 0.8, 1.3, 2.4))
		holes.append(Rect2(cx - 0.6, f + GROUND_H + 0.35, 1.2, 2.15))
		holes.append(Rect2(cx - 0.6, f + GROUND_H + FLOOR + 0.35, 1.2, 2.1))
	var cuts: Array = [0.0]
	for cx: float in bays:
		cuts.append(cx)
	cuts.append(ln)
	for i in range(cuts.size() - 1):                                    # (the rubble between the bays: tall broken panels on each floor)
		var m: float = (cuts[i] + cuts[i + 1]) / 2.0
		if cuts[i + 1] - cuts[i] < 1.6:
			continue
		for j in range(3):
			var y0: float = f + 0.9 + (0.0 if j == 0 else GROUND_H + FLOOR * (j - 1))
			panels.append(Rect2(m - 0.32, y0 + 0.1, 0.64, 1.3 + 0.25 * ((i + j) % 2)))
			panels.append(Rect2(m - 0.26, y0 + 1.6 + 0.25 * ((i + j) % 2), 0.52, 0.8))
	if door_at >= 0.0:
		holes.append(Rect2(door_at - 1.8, f, 3.6, 3.1))
	masonry(0.0, ln, f + 0.5, top, holes, panels, "ladrillo", "mamposteria")
	# the foot of rubble, from under the street to the floor, the cellar's windows in it
	var runs: Array = [[0.0, ln]]                                          # (cut at the main door: its steps go up through it)
	if door_at >= 0.0:
		runs = [[0.0, door_at - 1.8], [door_at + 1.8, ln]]
	for run in runs:
		var r0: float = run[0]
		var r1: float = run[1]
		if r1 - r0 < 0.05:
			continue
		var parts: int = maxi(1, int(ceil((r1 - r0) / 3.0)))
		for k in range(parts):
			var t0: float = lerpf(r0, r1, float(k) / parts)
			var t1: float = lerpf(r0, r1, float(k + 1) / parts)
			var p0: Vector2 = la.lerp(lb, t0 / ln)
			var p1: Vector2 = la.lerp(lb, t1 / ln)
			quad(Vector3(t0, minf(ground(p0.x, p0.y), f) - 2.5, 0.06), Vector3(t1, minf(ground(p1.x, p1.y), f) - 2.5, 0.06), Vector3(t1, f + 0.5, 0.06), Vector3(t0, f + 0.5, 0.06), "zocalo", Vector3(0, 0, 1))
		box(r0, f + 0.45, 0.0, r1 - r0, 0.1, 0.1, 0xc9bfae)                  # (the string course of brick on the foot)
	for cx: float in bays:
		var pg: Vector2 = la.lerp(lb, cx / ln)
		var gq: float = ground(pg.x, pg.y)
		if f - gq > 0.75:
			_sotano(cx, gq + 0.12)
	for k in range(holes.size()):
		var r: Rect2 = holes[k]
		if door_at >= 0.0 and k == holes.size() - 1:
			continue
		if r.position.y < f + GROUND_H:
			_reja(r)
		else:
			_balcon(r)
	cornice(-0.05, ln + 0.05, top, false, "ladrillo", 1.2)
	if door_at >= 0.0:
		_entrada(door_at, f, la.lerp(lb, door_at / ln))
	home()

## The main door: glass doors under a flat canopy, the great fan window over them through the first floor, a flight of
## steps up from the street with its rails.
func _entrada(cx: float, f: float, at: Vector2) -> void:
	var g: float = ground(at.x, at.y)
	box(cx - 1.8, f, -3.45, 3.6, 3.1, 0.04, "cristal")
	for k in range(5):
		box(cx - 1.8 + k * 0.9 - 0.04, f, -3.43, 0.08, 3.1, 0.08, 0x3a3a3c)
	box(cx - 1.8, f + 2.55, -3.43, 3.6, 0.08, 0.08, 0x3a3a3c)
	for s in [-1.0, 1.0]:                                                 # (the sides of the deep porch)
		box(cx + s * 1.8 - (0.0 if s > 0.0 else 0.04), g - 0.3, -3.45, 0.04, f + 3.1 - g + 0.3, 3.45, "ladrillo")
	box(cx - 1.8, f + 3.06, -3.45, 3.6, 0.04, 3.45, 0x5a5650)
	box(cx - 2.6, f + 3.1, 0.0, 5.2, 0.32, 1.6, 0x4a4844)                  # (the canopy)
	var spring := f + GROUND_H + 0.5
	var r := 2.5
	var pts := PackedVector2Array([Vector2(cx - r, spring), Vector2(cx + r, spring)])
	for i in range(17):
		pts.append(Vector2(cx + r * cos(PI * i / 16.0), spring + r * sin(PI * i / 16.0)))
	box(cx - r, f + 3.42, 0.014, 2.0 * r, spring - f - 3.42, 0.03, 0x3a3a3c)
	slab(pts, 0.02, 0.0, "cristal")
	ring(cx, spring, r - 0.12, r, 0.06, 0.1, 0x3a3a3c, 16)
	for i in range(1, 8):                                                 # (its spokes)
		var a := PI * i / 8.0
		bar(Vector3(cx, spring, 0.05), Vector3(cx + cos(a) * (r - 0.1), spring + sin(a) * (r - 0.1), 0.05), 0.05, 0.05, 0x3a3a3c)
	box(cx - 0.9, spring, 0.05, 1.8, 0.06, 0.05, 0x3a3a3c)
	ring(cx, spring, 1.0, 1.08, 0.06, 0.05, 0x3a3a3c, 10)
	openings += 1
	# the steps, from the floor down to the street, out of the wall
	var drop: float = f - g
	var steps: int = maxi(1, int(round(drop / 0.17)))
	var rise: float = drop / steps
	var zt := -3.3                                                         # (the flight within the porch: the map's asphalt comes up to the wall here)
	for k in range(steps):
		box(cx - 1.75, g - 0.3, zt + k * 0.32, 3.5, drop - k * rise + 0.3, 0.32, 0xb8b0a2)
	for s in [-1.0, 1.0]:
		bar(Vector3(cx + s * 1.7, f + 0.95, zt + 0.6), Vector3(cx + s * 1.7, g + 0.95, zt + steps * 0.32), 0.04, 0.04, IRON)
		var pe: Vector3 = _xf * Vector3(cx + s * 1.75, 0.0, zt + steps * 0.32)  # (the steps' foot: the self-test keeps it off the asphalt)
		yard.append(spot(pe.x, pe.z))
	box(cx - 1.8, f - 0.085, -3.45, 3.6, 0.1, 0.2, 0xb8b0a2)                  # (the porch's floor, by the doors)
	var ax: Vector2 = (SOUTH[3] - SOUTH[2]).normalized()
	var outn := Vector2(ax.y, -ax.x)
	_decks.append({"o": spot(at.x, at.y) + outn * (zt + steps * 0.16), "ax": -outn, "half": steps * 0.16 + 0.3, "wide": 1.75, "top": level + f, "ramp": steps * 0.32, "low": level + g})

## A great block of the home: its faces (the indices of its ring's corners where a face to the street starts), its
## roof of tiles round the flat roof with its panels.
func _block(ring: Array, f: float, faces: Array, door_at: float) -> void:
	for i in faces:                                                     # (the rings run so that a face looks out from b to a)
		var a: Vector2 = ring[i]
		var b: Vector2 = ring[(i + 1) % ring.size()]
		_fachada(b, a, f, (a.distance_to(b) - door_at) if (i == 2 and door_at >= 0.0) else -1.0)
	# the other walls (on the round body, the low wing, the other part), plain brick
	for i in range(ring.size()):
		if i in faces:
			continue
		var a: Vector2 = ring[i]
		var b: Vector2 = ring[(i + 1) % ring.size()]
		if a.distance_to(b) < 0.3:
			continue
		_plain(_l(b), _l(a), f - 1.0, f + EAVES, "ladrillo")
	_roof(ring, f + EAVES)

## the eaves of tiles round a flat roof: a band of tiles 3.6 m deep rising 1.3 m from each eave, mitred at the
## corners; the flat roof inside it, rows of solar panels on it
func _roof(ring: Array, y: float, deep := 3.6, rise := 1.3, out := 0.5, panels := true) -> void:
	var pr := PackedVector2Array()
	for q: Vector2 in ring:                                             # (its corners, without the little steps of Catastro's outline)
		var lq := _l(q)
		if pr.is_empty() or pr[pr.size() - 1].distance_to(lq) > 1.6:
			pr.append(lq)
	if pr.size() > 3 and pr[0].distance_to(pr[pr.size() - 1]) < 1.6:
		pr.remove_at(pr.size() - 1)
	var n := pr.size()
	var sgn := 1.0                                                      # (which way is in: tried on the first side)
	var e0 := (pr[1] - pr[0]).normalized()
	if not Geometry2D.is_point_in_polygon((pr[0] + pr[1]) / 2.0 + Vector2(-e0.y, e0.x) * 0.3, pr):
		sgn = -1.0
	var outer: Array = []
	var inner := PackedVector2Array()
	for i in range(n):
		var a: Vector2 = pr[(i - 1 + n) % n]
		var b: Vector2 = pr[i]
		var c: Vector2 = pr[(i + 1) % n]
		var d0 := (b - a).normalized()
		var d1 := (c - b).normalized()
		var n0 := Vector2(-d0.y, d0.x) * sgn                           # (inward)
		var n1 := Vector2(-d1.y, d1.x) * sgn
		var bis := (n0 + n1).normalized()
		var k := clampf(1.0 / maxf(bis.dot(n0), 0.3), 1.0, 3.0)
		outer.append(b - bis * out * k)
		inner.append(b + bis * deep * k)
	for i in range(n):
		var oa: Vector2 = outer[i]
		var ob: Vector2 = outer[(i + 1) % n]
		var ia: Vector2 = inner[i]
		var ib: Vector2 = inner[(i + 1) % n]
		roof([Vector3(oa.x, y - 0.05, oa.y), Vector3(ob.x, y - 0.05, ob.y), Vector3(ib.x, y + rise, ib.y), Vector3(ia.x, y + rise, ia.y)])
		ridge(Vector3(oa.x, y - 0.05, oa.y), Vector3(ia.x, y + rise, ia.y))
	if Geometry2D.triangulate_polygon(inner).size() < 3:
		return
	flat(inner, y + rise - 0.02, "cubierta" if panels else "tiles")
	if not panels:
		return
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for q in inner:
		lo = lo.min(q)
		hi = hi.max(q)
	var zz: float = lo.y + 1.0
	while zz < hi.y - 1.0:                                              # (rows of panels where the flat roof is)
		var xx: float = lo.x + 1.0
		while xx < hi.x - 1.6:
			if Geometry2D.is_point_in_polygon(Vector2(xx + 0.8, zz + 0.5), inner) and Geometry2D.is_point_in_polygon(Vector2(xx, zz), inner) and Geometry2D.is_point_in_polygon(Vector2(xx + 1.6, zz + 1.0), inner):
				quad(Vector3(xx, y + 1.45, zz + 1.0), Vector3(xx + 1.6, y + 1.45, zz + 1.0), Vector3(xx + 1.6, y + 1.95, zz), Vector3(xx, y + 1.95, zz), "panel", Vector3(0, 0.9, -0.45))
			xx += 1.8
		zz += 2.2

## The pavement along a face to the street, from a to b on the map (the street on the left going from a to b): pale tiles from the wall
## out to the asphalt, a hand over the ground
func _acera(a: Vector2, b: Vector2) -> void:
	var la := _l(a)
	var lb := _l(b)
	var ln := la.distance_to(lb)
	var d := (lb - la) / ln
	var outn := Vector2(-d.y, d.x)
	var steps: int = maxi(1, int(ceil(ln / 1.0)))
	var deep: Array = []
	for k in range(steps + 1):
		var q: Vector2 = la + d * (ln * k / steps)
		var w := 0.0
		while w < 6.0 and MapData.road_edge_dist(spot(q.x + outn.x * (w + 0.25), q.y + outn.y * (w + 0.25))) > 0.2:
			w += 0.25
		deep.append(w)
	for k in range(steps):
		var q0: Vector2 = la + d * (ln * k / steps)
		var q1: Vector2 = la + d * (ln * (k + 1) / steps)
		var w0: float = deep[k]
		var w1: float = deep[k + 1]
		if w0 < 0.1 and w1 < 0.1:
			continue
		var pts: Array = [q0 - outn * 0.05, q1 - outn * 0.05, q1 + outn * w1, q0 + outn * w0]
		var c := Vector2.ZERO
		for q: Vector2 in pts:
			c += q / 4.0
		var cc := Vector3(c.x, ground(c.x, c.y) + 0.05, c.y)
		for i in range(4):
			var pa: Vector2 = pts[i]
			var pb: Vector2 = pts[(i + 1) % 4]
			tri(cc, Vector3(pa.x, ground(pa.x, pa.y) + 0.05, pa.y), Vector3(pb.x, ground(pb.x, pb.y) + 0.05, pb.y), "acera", Vector3.UP)
	pieces += 1

## the wall of the great block's notch over the round body, one floor higher than it
func _arc_wall() -> void:
	for i in range(ARC.size() - 1):
		var a: Vector2 = ARC[i]
		var b: Vector2 = ARC[i + 1]
		_plain(_l(b), _l(a), fs + GROUND_H + FLOOR - 0.5, fs + EAVES, "ladrillo")
		if i % 3 == 1:
			var keep := _xf
			var ln := face(_l(b), _l(a))
			window(Rect2(ln / 2.0 - 0.5, fs + GROUND_H + FLOOR + 0.4, 1.0, 1.9), 0x4a3a2c, 0x2a3640, 1)
			_xf = keep
			home()

## The round body between the great block and the hermitage's nave: two floors of brick with panels of rubble, a flat
## roof with its parapet. Its wall to the west rises over the low wing's roof (three little windows up there) and comes
## down to the square in the corner between the wing and the hermitage (the user's 360° photo): there the home's gate,
## columns of rubble either side of it on both floors, the balcony of two windows over it.
func _round_body() -> void:
	var f := fs
	var top := f + GROUND_H + FLOOR + 0.6
	var la := _l(ROUND_BODY[2])
	var lb := _l(ROUND_BODY[1])
	var ln := face(la, lb)
	var pd: Vector2 = la.lerp(lb, ZAGUAN / ln)
	var g: float = ground(pd.x, pd.y)                                    # (the square before the gate)
	var up: float = g + 3.6                                              # (the balcony's floor)
	var gate := Rect2(ZAGUAN - 0.75, g, 1.5, 2.95)
	var pair: Array = [Rect2(ZAGUAN - 0.6, up + 0.1, 0.52, 1.8), Rect2(ZAGUAN + 0.08, up + 0.1, 0.52, 1.8)]
	var small: Array = []
	for x in [6.65, 5.0, 3.35]:
		small.append(Rect2(x - 0.25, up + 0.55, 0.5, 0.75))
	var panels: Array = [Rect2(7.15, up - 0.1, 0.45, 0.6), Rect2(7.15, up + 0.6, 0.45, 0.7),
		Rect2(7.88, g + 1.46, 0.42, 0.68), Rect2(7.86, g + 2.2, 0.46, 0.9), Rect2(7.88, up - 0.1, 0.42, 0.6), Rect2(7.86, up + 0.6, 0.46, 0.7),
		Rect2(10.1, g + 1.5, 0.4, 0.62), Rect2(10.1, g + 2.27, 0.42, 0.9), Rect2(10.1, up + 0.1, 0.42, 0.6), Rect2(10.1, up + 0.8, 0.42, 0.66)]
	masonry(0.0, ln, minf(f, g) - 1.0, top, [gate] + pair + small, panels, "ladrillo", "mamposteria")
	for r: Rect2 in pair + small:
		window(r, 0x7a5a3a, 0x2a3640, 1 if r.size.y > 1.0 else 0)
		openings += 1
	_baranda(ZAGUAN - 0.85, ZAGUAN + 0.85, up + 0.1)
	_zaguan(gate)
	cornice(-0.05, ln + 0.05, top, false, "ladrillo", 1.0)
	home()
	var pts := PackedVector2Array()
	for q in round_ring:
		pts.append(_l(q))
	var clean := PackedVector2Array()
	for q in pts:
		if clean.is_empty() or clean[clean.size() - 1].distance_to(q) > 0.05:
			clean.append(q)
	flat(clean, top - 0.05, "cubierta")
	var mid := Vector2.ZERO
	for q in clean:
		mid += q / clean.size()
	box(mid.x - 2.0, top - 0.04, mid.y - 2.0, 4.0, 0.02, 4.0, 0x3a3632)         # (its little court, dark from above)

## The low wing on the hermitage's square and the west arm: one floor of brick on a foot of pale granite, columns of
## rubble panels between its windows behind their grilles (the red blinds down), its deep eaves of tiles on dark rafters
## over a course of brick dentils; to the square its one porch (_porche) and a last window by the round body; a
## hipped roof of tiles.
func _wing() -> void:
	var la := _l(WING[1])
	var lr := _l(WING[0])
	var gmax := -99.0
	var span := la.distance_to(lr)
	for k in range(7):                                                      # (the square before the porch: it rises east)
		var q: Vector2 = la.lerp(lr, lerpf(PORCH_0, PORCH_1, k / 6.0) / span)
		gmax = maxf(gmax, ground(q.x, q.y))
	var f: float = gmax + 0.03                                              # (the porch's floor, level with the square)
	y_wing = f
	var top := f + 3.55
	# the face to the square
	var ln := face(la, lr)
	var wins: Array = []
	for cx: float in WIN_S:
		wins.append(Rect2(cx - 0.65, f + 1.1, 1.3, 1.45))
	wins.append(Rect2(ln - 1.5, f + 1.1, 1.1, 1.45))                        # (the last one, by the round body)
	var open: Array = []
	for r: Rect2 in wins:
		open.append([r.position.x, r.end.x])
	open.append([PORCH_0, PORCH_1])
	open.sort_custom(func(s0, s1): return s0[0] < s1[0])
	var panels := _columnas(open, ln, f)
	masonry(0.0, PORCH_0, f + 1.1, top, wins, panels, "ladrillo", "mamposteria")
	masonry(PORCH_0, PORCH_1, f + 2.9, top, [], [], "ladrillo", "mamposteria")
	masonry(PORCH_1, ln, f + 1.1, top, wins, panels, "ladrillo", "mamposteria")
	plinth(0.0, PORCH_0, f + 1.1, f + 1.1, "granito", 0.04, f - 3.0)
	plinth(PORCH_1, ln, f + 1.1, f + 1.1, "granito", 0.04, f - 3.0)
	for r: Rect2 in wins:
		_reja(r, true)
	box(PORCH_1 + 0.14, f + 1.75, 0.0, 0.4, 0.28, 0.03, 0x6a4426)          # (the little board on the pier)
	_porche(f)
	_alero(0.0, ln, top)
	home()
	# the face to the west arm
	ln = face(_l(WING[2]), la)
	var n := maxi(1, int(floor(ln / 3.0)))
	wins = []
	open = []
	for k in range(n):
		var cx: float = ln * (k + 0.5) / n
		wins.append(Rect2(cx - 0.65, f + 1.1, 1.3, 1.45))
		open.append([cx - 0.65, cx + 0.65])
	masonry(0.0, ln, f + 1.1, top, wins, _columnas(open, ln, f), "ladrillo", "mamposteria")
	plinth(0.0, ln, f + 1.1, f + 1.1, "granito", 0.04, f - 3.0)
	for r: Rect2 in wins:
		_reja(r, true)
	_alero(0.0, ln, top)
	home()
	_roof(WING, top, 2.4, 1.1, 0.6, false)

## columns of rubble panels framed in brick down the piers between the openings (`open`: [from, to] along the wall,
## in order), three to a pier over the granite foot
func _columnas(open: Array, ln: float, f: float) -> Array:
	var out: Array = []
	var x := 0.0
	for o in open + [[ln, ln]]:
		var a: float = x
		var b: float = o[0]
		x = maxf(x, o[1])
		if b - a < 0.8:
			continue
		var m := (a + b) / 2.0
		var w := minf(0.62, b - a - 0.3)
		for j in range(3):
			out.append(Rect2(m - w / 2.0, f + 1.25 + j * 0.55, w, 0.43))
	return out

## the eaves of the low wing, from x0 to x1 under the tiles' edge at `top`: a course of brick, the row of brick dentils,
## another course standing further out, the dark rafters every forty centimetres
func _alero(x0: float, x1: float, top: float) -> void:
	box(x0, top - 0.42, 0.0, x1 - x0, 0.07, 0.06, "ladrillo")
	var n := int((x1 - x0) / 0.14)
	for i in range(n):
		box(x0 + (i + 0.25) * (x1 - x0) / n, top - 0.35, 0.0, 0.065, 0.12, 0.13, "ladrillo")
	box(x0, top - 0.23, 0.0, x1 - x0, 0.07, 0.16, "ladrillo")
	for k in range(int((x1 - x0) / 0.4)):
		box(x0 + k * 0.4 + 0.15, top - 0.16, -0.1, 0.08, 0.11, 0.7, "wood")
	pieces += 1

## The porch of the low wing, in the face to the square (its frame being built), its floor at f: two bays between the
## brick piers and a wooden post, under the beam, shut by iron gates the whole height; inside, the white ceiling on dark
## beams, the granite foot round it, and on its back wall the brotherhood's wooden door, a barred window, its carved
## board with the tile of the Cristo between two lanterns, a bench, pots of geraniums.
func _porche(f: float) -> void:
	var p0 := PORCH_0
	var p1 := PORCH_1
	var ph := 2.9                                                           # (to the beam)
	var bk := -PORCH_D
	for x in [p0, p1]:                                                      # (its sides)
		var nn := Vector3(1, 0, 0) if x == p0 else Vector3(-1, 0, 0)
		quad(Vector3(x, f - 0.1, bk), Vector3(x, f - 0.1, 0.04), Vector3(x, f + 1.0, 0.04), Vector3(x, f + 1.0, bk), "granito", nn)
		quad(Vector3(x, f + 1.0, bk), Vector3(x, f + 1.0, 0.0), Vector3(x, f + ph, 0.0), Vector3(x, f + ph, bk), "ladrillo", nn)
	box(p0, f - 1.2, bk, p1 - p0, 1.2, -bk + 0.02, "losa")                   # (its floor, down into the ground)
	box(p0, f + ph + 0.015, bk, p1 - p0, 0.04, -bk, 0xe8e4dc)                # (the white ceiling, its beams)
	for k in range(int((p1 - p0) / 0.55)):
		box(p0 + 0.25 + k * 0.55, f + ph - 0.13, bk, 0.1, 0.13, -bk, "wood")
	box(p0 - 0.12, f + ph, -0.16, p1 - p0 + 0.24, 0.23, 0.3, "wood")         # (the beam over the gates)
	box(POST - 0.1, f, -0.1, 0.2, ph, 0.2, "wood")                          # (the post, on its stone)
	box(POST - 0.14, f, -0.14, 0.28, 0.12, 0.28, "granito")
	for run in [[p0 + 0.03, POST - 0.1], [POST + 0.1, p1 - 0.03]]:          # (the gates: bars the whole height, three rails)
		var a: float = run[0]
		var b: float = run[1]
		var nb := int(round((b - a) / 0.12))
		for i in range(nb + 1):
			box(a + (b - a) * i / nb - 0.012, f, -0.07, 0.024, ph - 0.02, 0.024, IRON)
		for y in [f + 0.08, f + 2.05, f + ph - 0.08]:
			box(a, y - 0.02, -0.08, b - a, 0.04, 0.035, IRON)
		box((a + b) / 2.0 - 0.02, f, -0.085, 0.04, ph - 0.02, 0.04, IRON)    # (where a leaf opens)
		openings += 1
	# its back wall
	var keep := _xf
	_xf = _xf * Transform3D(Basis(), Vector3(0, 0, bk))
	var dr := Rect2(p0 + 0.6, f, 1.0, 2.25)
	var wn := Rect2(p0 + 2.3, f + 1.0, 1.3, 1.45)
	masonry(p0, p1, f + 1.0, f + ph, [dr, wn], [Rect2(p0 + 5.05, f + 1.2, 0.5, 0.42), Rect2(p0 + 5.05, f + 1.75, 0.5, 0.42)], "ladrillo", "mamposteria")
	plinth(p0, dr.position.x, f + 1.0, f + 1.0, "granito", 0.03, f - 0.1)
	plinth(dr.end.x, p1, f + 1.0, f + 1.0, "granito", 0.03, f - 0.1)
	box(dr.position.x, dr.position.y, -DEEP + 0.08, dr.size.x, dr.size.y, 0.06, 0x6e4426)      # (the door of panels)
	for i in range(2):
		for j in range(5):
			var pw := (dr.size.x - 0.2) / 2.0
			var phh := (dr.size.y - 0.3) / 5.0
			box(dr.position.x + 0.1 + i * pw + 0.04, f + 0.15 + j * phh + 0.04, -DEEP + 0.14, pw - 0.08, phh - 0.08, 0.03, 0x87542f)
	box(dr.position.x + dr.size.x / 2.0 - 0.015, f, -DEEP + 0.14, 0.03, dr.size.y, 0.035, 0x4a2c18)
	openings += 1
	_reja(wn, true)
	var sx := p0 + 3.75                                                     # (the board, the tile, the lanterns)
	box(sx, f + 1.98, 0.0, 1.3, 0.56, 0.05, 0x8a5a34)
	_text("MAYORDOMÍA\nDEL SMO.\nCRISTO DEL PRADO", Vector3(sx + 0.65, f + 2.26, 0.055), 48, 0x3a2212, 0.0021)
	var tx := sx + 0.42
	box(tx, f + 1.1, 0.0, 0.46, 0.78, 0.03, 0xf0e8d4)
	for q in [[tx, f + 1.1, 0.46, 0.05], [tx, f + 1.83, 0.46, 0.05], [tx, f + 1.1, 0.05, 0.78], [tx + 0.41, f + 1.1, 0.05, 0.78]]:
		box(q[0], q[1], 0.03, q[2], q[3], 0.01, 0x2c4c8c)
	box(tx + 0.21, f + 1.24, 0.035, 0.04, 0.5, 0.01, 0x6a2a22)
	box(tx + 0.1, f + 1.58, 0.035, 0.26, 0.04, 0.01, 0x6a2a22)
	box(tx + 0.13, f + 1.88, 0.03, 0.2, 0.09, 0.03, 0xd8a83a)               # (its little crest)
	for x in [sx + 0.12, sx + 1.08]:
		box(x, f + 1.55, 0.0, 0.05, 0.05, 0.12, IRON)
		box(x - 0.04, f + 1.45, 0.1, 0.13, 0.2, 0.13, IRON)
	box(p0 + 3.0, f + 0.42, 0.06, 2.6, 0.06, 0.42, "wood")                  # (the bench)
	box(p0 + 3.0, f + 0.55, 0.06, 2.6, 0.3, 0.05, "wood")
	for x in [p0 + 3.1, p0 + 5.4]:
		box(x, f, 0.1, 0.1, 0.42, 0.34, "wood")
	for x in [p0 + 1.85, p0 + 2.4]:                                          # (the pots)
		box(x, f, 0.08, 0.45, 0.3, 0.3, 0xe8e4dc)
		ball(Vector3(x + 0.22, f + 0.38, 0.23), 0.22, 0x4f7a3a, 0.7, 8, 5)
	_xf = keep

## The pavement where Catastro had the wing (its face stands further back) and before the home's gate: the square's
## pale stone, laid a little under the hermitage's so the two never fight where they meet
func _franja() -> void:
	var a := _l(WING[1])
	var b := _l(WING[0])
	var ln := a.distance_to(b)
	var d := (b - a) / ln
	var n := Vector2(-d.y, d.x)                                             # (out, to the square)
	var w := BACK + 0.1
	var west := 0.26                                                        # (the west arm's line slants a little)
	var u := 0.0
	while u < ln + 0.07:
		var u1 := minf(u + 1.0, ln + 0.07)
		var far0 := maxf(u, west)
		var pts: Array = [a + d * u, a + d * u1, a + d * u1 + n * w, a + d * far0 + n * w]
		var c := Vector2.ZERO
		for q: Vector2 in pts:
			c += q / 4.0
		u = u1
		if MapData.road_edge_dist(spot(c.x, c.y)) < 0.25:
			continue
		var cc := Vector3(c.x, ground(c.x, c.y) + 0.05, c.y)
		for i in range(4):
			var pa: Vector2 = pts[i]
			var pb: Vector2 = pts[(i + 1) % 4]
			tri(cc, Vector3(pa.x, ground(pa.x, pa.y) + 0.05, pa.y), Vector3(pb.x, ground(pb.x, pb.y) + 0.05, pb.y), "losa", Vector3.UP)
	pieces += 1
	# the hermitage's foot of rubble along the bit of its nave the corner shows
	var fa := _l(ROUND_BODY[1])
	var fb := _l(NAVE_NW)
	var lf := face(fa, fb)
	var gm: float = ground((fa.x + fb.x) / 2.0, (fa.y + fb.y) / 2.0)
	plinth(0.0, lf, gm + 0.9, gm + 0.9, "zocalo_ermita", 0.06, gm - 1.0)
	home()
