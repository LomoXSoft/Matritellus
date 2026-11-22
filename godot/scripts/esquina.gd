extends "res://scripts/obra.gd"
## What the corner buildings of the crossroads of the traffic lights share (sopiss.gd, clinica.gd; the user, 21 and 22
## November 2026: "las cuatro esquinas", one building at a time): each is built by hand on its house of the map, in the
## map's own frame (x east, z south, y = 0 its pavement), front by front (obra.face). Here: the corners between fronts,
## the roof, the eaves, the walls it shares with its neighbours, the solids along its outline.
##
## A building says how high its walls are and how its roof goes (wall_top, eave_out, roof_pitch, roof_rise0), gives the
## roof its slopes (_planes: each rises from a wall's line at the same pitch) and calls _roof_over() with its outline:
## the roof is the lowest of those slopes over every spot, so it closes by itself whatever the outline.

var wall_top := 6.4                 # the top of the walls, over the pavement
var eave_out := 0.6                 # how far the eaves come out
var roof_pitch := 0.33              # the roof's slope
var roof_rise0 := 0.2               # the tiles over the wall's line (eave_out * roof_pitch: the eaves' edge level with wall_top)
var roof_pieces := 0
var ridge_top := 0.0                # the roof's highest point over the pavement (the self-test)
var roof_area := 0.0                # how much ground its pieces cover...
var roof_outline := 0.0             # ...and how much its outline holds (the self-test: the same)
var _planes: Array = []             # the roof's slopes: [outward (Vector2), the wall line's distance along it]

## the outward normal of a front built from a to b (obra.face's +z)
func _outward(a: Vector2, b: Vector2) -> Vector2:
	var d := (b - a).normalized()
	return Vector2(-d.y, d.x)

func _along(a: Vector2, b: Vector2, s: float) -> Vector2:
	return a + (b - a).normalized() * s

## how much longer a piece standing `proud` of a front must be to meet its neighbour's round a corner (the outward
## normals of the two fronts)
func _miter(n0: Vector2, n1: Vector2, proud: float) -> float:
	return proud * tan(absf(n0.angle_to(n1)) / 2.0)

## a ring set in (or, with negative distances, out) from each of its edges
func _inset(ring: Array, by: Array) -> Array:
	var n := ring.size()
	var out: Array = []
	for i in range(n):
		var a0: Vector2 = ring[(i + n - 1) % n]
		var a1: Vector2 = ring[i]
		var a2: Vector2 = ring[(i + 1) % n]
		var d0 := (a1 - a0).normalized()
		var d1 := (a2 - a1).normalized()
		var p0 := a0 + Vector2(-d0.y, d0.x) * float(by[(i + n - 1) % n])
		var p1 := a1 + Vector2(-d1.y, d1.x) * float(by[i])
		var hit = Geometry2D.line_intersects_line(p0, d0, p1, d1) if absf(d0.cross(d1)) > 0.02 else null      # (two edges all but in one line never cross, or cross hundreds of metres away: the second one's own point then)
		out.append(hit if hit != null else p1)
	return out

## the part of an outline where p . n >= c
func _clip(poly: PackedVector2Array, n: Vector2, c: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(poly.size()):
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var da := a.dot(n) - c
		var db := b.dot(n) - c
		if da >= 0.0:
			out.append(a)
		if (da >= 0.0) != (db >= 0.0):
			out.append(a.lerp(b, da / (da - db)))
	return out

## a flat picture (x0..x1, y0..y1) on the plane z of the frame being built, facing +z
func _picture(x0: float, x1: float, y0: float, y1: float, z: float, key) -> void:
	pieces += 1
	quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

## a flat piece facing down at height y
func _flat_down(pts: PackedVector2Array, y: float, key) -> void:
	pieces += 1
	var idx := Geometry2D.triangulate_polygon(pts)
	for t in range(0, idx.size(), 3):
		var a := pts[idx[t]]
		var b := pts[idx[t + 1]]
		var c := pts[idx[t + 2]]
		tri(Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y), key, Vector3.DOWN)

# ---------------- the roof ----------------
## how high the roof's tiles are over a spot of the map (this frame's y): the lowest of its slopes there
func _roof_y(p: Vector2) -> float:
	var y := 1000.0
	for i in range(_planes.size()):
		y = minf(y, _plane_y(i, p))
	return y

func _plane_y(i: int, p: Vector2) -> float:
	return wall_top + roof_rise0 + roof_pitch * (float(_planes[i][1]) - p.dot(_planes[i][0]))

## The roof over a ring (the house's outline, in its own order) set out by `by` from each edge (negative: the eaves of
## a front; 0: a wall it shares). Each slope's share is cut out of the outline; where two meet, a line of round tiles.
func _roof_over(ring: Array, by: Array, key = "tiles") -> void:
	home()
	var outline := PackedVector2Array(_inset(ring, by))
	var edges: Array = []
	var oidx := Geometry2D.triangulate_polygon(outline)
	for t in range(0, oidx.size(), 3):
		roof_outline += 0.5 * absf((outline[oidx[t + 1]] - outline[oidx[t]]).cross(outline[oidx[t + 2]] - outline[oidx[t]]))
	for part: PackedVector2Array in Geometry2D.decompose_polygon_in_convex(outline):
		for i in range(_planes.size()):
			var poly := part
			for j in range(_planes.size()):
				if j == i or poly.size() < 3:
					continue
				poly = _clip(poly, (_planes[i][0] as Vector2) - (_planes[j][0] as Vector2), float(_planes[i][1]) - float(_planes[j][1]))      # (where slope i is the lower of the two)
			if poly.size() < 3:
				continue
			var v: Array = []
			for q in poly:
				v.append(Vector3(q.x, _plane_y(i, q), q.y))
				ridge_top = maxf(ridge_top, _plane_y(i, q))
			for k in range(1, v.size() - 1):
				if ((v[k] as Vector3) - v[0]).cross((v[k + 1] as Vector3) - v[0]).length() > 0.0005:
					roof([v[0], v[k], v[k + 1]], key)
					roof_pieces += 1
					roof_area += 0.5 * absf((poly[k] - poly[0]).cross(poly[k + 1] - poly[0]))
			for k in range(v.size()):
				edges.append([v[k], v[(k + 1) % v.size()], i])
	for i in range(edges.size()):                       # the round tiles where two slopes meet
		for j in range(i + 1, edges.size()):
			if int(edges[i][2]) == int(edges[j][2]):
				continue
			var a0: Vector3 = edges[i][0]
			var a1: Vector3 = edges[i][1]
			var b0: Vector3 = edges[j][0]
			var b1: Vector3 = edges[j][1]
			if a0.distance_to(a1) > 0.2 and ((a0.distance_to(b1) < 0.03 and a1.distance_to(b0) < 0.03) or (a0.distance_to(b0) < 0.03 and a1.distance_to(b1) < 0.03)):
				ridge(a0, a1)

## the wooden beam on the wall's top, the boards and rafters of the eaves over the front being built (e0, e1: how much
## further the eaves' edge runs to meet the next front's)
func _eaves(ln: float, e0: float, e1: float, step := 0.55) -> void:
	box(0.0, wall_top - 0.16, 0.0, ln, roof_rise0 + 0.16, 0.05, "wood")
	var yi := wall_top + roof_rise0 - 0.05
	var yo := wall_top - 0.05
	pieces += 1
	quad(Vector3(0.0, yi, 0.0), Vector3(ln, yi, 0.0), Vector3(ln + e1, yo, eave_out), Vector3(-e0, yo, eave_out), "wood", Vector3(0, -1, -roof_pitch).normalized())
	var n := maxi(2, int(round(ln / step)))
	for i in range(n + 1):
		var x := ln * i / n
		bar(Vector3(x, yi - 0.1, 0.02), Vector3(x, yo - 0.1, eave_out - 0.05), 0.07, 0.12, 0x3a2a20)
	bar(Vector3(-e0, yo - 0.04, eave_out - 0.02), Vector3(ln + e1, yo - 0.04, eave_out - 0.02), 0.04, 0.14, 0x3a2a20)

# ---------------- the walls it shares, the solids ----------------
## A wall the house shares, from a to b in its ring's order: bare render from the ground to the roof's own line.
func _party_wall(a: Vector2, b: Vector2, key = "medianera") -> void:
	var ln := face(b, a)
	pieces += 1
	quad(Vector3(0, -0.9, 0), Vector3(ln, -0.9, 0), Vector3(ln, wall_top, 0), Vector3(0, wall_top, 0), key, Vector3(0, 0, 1))
	var n := maxi(1, int(ceil(ln / 0.5)))
	for i in range(n):
		var xa := ln * i / n
		var xb := ln * (i + 1) / n
		quad(Vector3(xa, wall_top, 0), Vector3(xb, wall_top, 0), Vector3(xb, _roof_y(b.lerp(a, xb / ln)) - 0.03, 0), Vector3(xa, _roof_y(b.lerp(a, xa / ln)) - 0.03, 0), key, Vector3(0, 0, 1))
	home()

## Its walls are thin solids along its outline (nobody gets in, and whoever stands inside is not inside a solid).
func _ring_solids(ring: Array, tall := 12.0) -> void:
	for i in range(ring.size()):
		var a: Vector2 = ring[i]
		var b: Vector2 = ring[(i + 1) % ring.size()]
		var d := (b - a).normalized()
		var mid := (a + b) / 2.0 + Vector2(-d.y, d.x) * 0.17
		solid(Vector3(mid.x, tall / 2.0 - 1.0, mid.y), Vector3(a.distance_to(b), tall, 0.34), atan2(-d.y, d.x))
