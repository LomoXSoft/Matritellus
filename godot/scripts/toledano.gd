extends "res://scripts/obra.gd"
## The Plazuela del Toledano (the user, 16 November 2026: "puedes ponerte con la Plazuela del Toledano"): the little
## three-cornered square where five streets meet, built by hand from Street View (November 2024) and a private 360
## picture taken on it. A kerbed islet paved in irregular flags of slate between bands of pale stone; two tall
## cypresses, a big tree, a leaning pine in a round bed, a sapling in its cage, each in a bed of red; four benches of
## black iron with lacy backs; a lamp, two bins on posts; the give-way and no-entry signs at its west point; and in the
## middle, standing on its rubber, a pencil three metres high.
##
## No rebake: the islet is the pedestrian ring the map already has there (the world draws it as a wide path of pale
## tiles round a patch of sand), read as it is baked and cut back to keep clear of the streets round it as the GAME
## has them (the unnamed street along its north-west side runs 2.3 m from it: the islet loses a metre and a half
## there). Under it an apron of asphalt hides the pale path; the islet lies on the ground as the relief has it (it
## falls nearly a metre from its north point to its south one): every flat piece is cut along the relief's own facets.
##
## Frame: map metres from MID, north up the map (-z); y = 0 is the ground at MID. Things are given in map coordinates,
## placed from two or more cameras each (tools/toledano/rumbos.py, LEEME.md).

const MID := Vector2(-368.0, -42.0)
const KERB := 0.14
const CLEAR := 3.9                  # how far its kerb keeps from the middle of a street
const STEP := 0.4                   # how far out of the kerb somebody on foot is already up on it
const BLACK := 0x1c1c1e
const PALE := 0xb9ab8e              # the bands of pale stone
const RED := 0x6a3128               # the beds
const PENCIL := Vector2(-365.65, -41.07)
const LAMP := Vector2(-369.9, -39.6)
const CYPRESSES: Array = [Vector2(-374.1, -41.5), Vector2(-368.8, -37.3)]
const BIG_TREE := Vector2(-364.1, -45.8)
const PINE := Vector2(-361.1, -52.1)
const SAPLING := Vector2(-374.0, -37.0)
const BENCHES: Array = [[Vector2(-367.1, -46.9), 0], [Vector2(-363.6, -44.4), 1], [Vector2(-365.6, -37.4), 1], [Vector2(-371.8, -42.3), 0]]      # where, and which side it lies along (0 the north-west one, 1 the east one): each looks in
const BINS: Array = [Vector2(-373.6, -36.9), Vector2(-361.5, -45.8)]

var outline := PackedVector2Array()    # the islet's kerb, on the map
var area := 0.0
var lamp_at := Vector3.ZERO         # its lantern, in the world
var things: Array = []              # where what stands on it is, on the map (the self-test: all inside the kerb)
var decks := 0
var _along := Vector2(0.77, -0.638) # the way its long north-west side runs
var _east := Vector2(0.39, -0.92)   # ...and its east side

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"losas":            # the flags of slate (tools/toledano/losas.py), laid by the map's own metres
			var lm := StandardMaterial3D.new()
			lm.albedo_texture = load("res://assets/toledano/losas.png")
			lm.uv1_triplanar = true
			lm.uv1_world_triplanar = true
			lm.uv1_scale = Vector3.ONE / 3.0
			lm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			lm.roughness = 1.0
			m = lm
		"asfalto":          # the streets' own
			m = W._tmat(0x77727a, "asphalt", 3.0)
		"bordillo":
			m = Tex.mat("granular_concrete", Color(0.72, 0.72, 0.7))
		"cipres":
			m = W._tmat(0x2c4a34, "leaf", 1.1)
		"hoja":
			m = W._tmat(0x6f8f3e, "leaf", 1.6)
		"pino":
			m = W._tmat(0x4f6f3a, "leaf", 1.3)
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> bool:
	W = world
	outline = _islet()
	if outline.size() < 3:
		return false
	level = MapData.height(MID)
	transform = Transform3D(Basis.IDENTITY, Vector3(MID.x, level, MID.y))
	W.add_child(self)
	var mid := Vector2.ZERO
	for i in range(outline.size()):
		mid += outline[i] / outline.size()
		var b: Vector2 = outline[(i + 1) % outline.size()]
		area += (outline[i].x * b.y - b.x * outline[i].y) / 2.0
	area = absf(area)
	_floor()
	_kerb()
	_walkable()
	_pencil()
	for at: Vector2 in CYPRESSES:
		_cypress(at, 11.5)
	_big_tree(BIG_TREE, 9.5)
	_pine(PINE)
	_sapling(SAPLING)
	for b in BENCHES:
		var way: Vector2 = _along if int(b[1]) == 0 else _east
		var look := Vector2(-way.y, way.x)           # square to its side, and in towards the middle
		if look.dot(mid - (b[0] as Vector2)) < 0.0:
			look = -look
		_bench(b[0], look)
	for at: Vector2 in BINS:
		_bin(at)
	_lamp(LAMP)
	_signs(mid)
	_containers()
	home()
	_commit()
	return true

# ---------------- the islet's outline ----------------
func _ccw(p: PackedVector2Array) -> PackedVector2Array:
	if Geometry2D.is_polygon_clockwise(p):
		p.reverse()
	return p

## The pedestrian ring of the map nearest MID, cut back from every street that passes: what is left is the islet.
func _islet() -> PackedVector2Array:
	var out := PackedVector2Array()
	for r in MapData.roads:
		var p: PackedInt32Array = r["p"]
		if int(r["k"]) != 2 or p.size() < 4 or p[0] != p[p.size() - 1] or (MapData.nodes[p[0]] as Vector2).distance_to(MID) > 25.0:
			continue
		for i in range(p.size() - 1):
			out.append(MapData.nodes[p[i]])
	if out.size() < 3:
		return out
	out = _ccw(out)
	var longest := 0.0
	for s in MapData.segs:
		if int(s.road["k"]) != 0 or Geometry2D.get_closest_point_to_segment(MID, s.a, s.b).distance_to(MID) > 40.0:
			continue
		var d: Vector2 = (s.b - s.a).normalized()
		var n := Vector2(-d.y, d.x) * CLEAR
		var a: Vector2 = s.a - d * 4.0
		var b: Vector2 = s.b + d * 4.0
		var cut := Geometry2D.clip_polygons(out, _ccw(PackedVector2Array([a - n, b - n, b + n, a + n])))
		var best := PackedVector2Array()
		for piece in cut:
			if not Geometry2D.is_polygon_clockwise(piece) and piece.size() > best.size():
				best = piece
		if cut.is_empty() or best.size() < 3:
			continue                                 # (a street right through it: leave it as it was rather than nothing)
		out = best
	for i in range(out.size()):                      # its two long sides, as they came out
		var e: Vector2 = out[(i + 1) % out.size()] - out[i]
		if e.length() > longest:
			longest = e.length()
			_along = e.normalized()
	if _along.x < 0.0:
		_along = -_along
	var second := 0.0
	for i in range(out.size()):
		var e: Vector2 = out[(i + 1) % out.size()] - out[i]
		if e.length() > second and absf(e.normalized().dot(_along)) < 0.9:
			second = e.length()
			_east = e.normalized()
	return out

# ---------------- laying things on the ground ----------------
func _p3(q: Vector2, lift: float) -> Vector3:
	return Vector3(q.x - MID.x, MapData.height(q) - level + lift, q.y - MID.y)

## how high the islet's floor is at a spot of the map, in this frame
func _gy(q: Vector2) -> float:
	return MapData.height(q) - level + KERB

## the relief's facets under a rectangle of the map: [triangle (PackedVector2Array), its three heights]
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

## A flat piece of this outline (on the map) laid on the ground, `lift` over it: cut along the relief's facets, so it
## neither floats nor sinks anywhere.
func _lay(poly: PackedVector2Array, lift: float, key) -> void:
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
				tri(_p3(piece[idx[t]], lift), _p3(piece[idx[t + 1]], lift), _p3(piece[idx[t + 2]], lift), key, Vector3.UP)

func _grown(poly: PackedVector2Array, by: float) -> PackedVector2Array:
	var best := PackedVector2Array()
	for piece in Geometry2D.offset_polygon(poly, by, Geometry2D.JOIN_MITER):
		if not Geometry2D.is_polygon_clockwise(piece) and piece.size() > best.size():
			best = piece
	return best

## a rectangle on the map: its middle, the way it runs, how long and how wide
func _strip(mid: Vector2, way: Vector2, long: float, wide: float) -> PackedVector2Array:
	var n := Vector2(-way.y, way.x) * wide / 2.0
	var h := way * long / 2.0
	return PackedVector2Array([mid - h - n, mid + h - n, mid + h + n, mid - h + n])

## the same, kept to what of it is inside `within`
func _inside(poly: PackedVector2Array, within: PackedVector2Array) -> Array:
	var out: Array = []
	for piece in Geometry2D.intersect_polygons(_ccw(poly), within):
		if not Geometry2D.is_polygon_clockwise(piece):
			out.append(piece)
	return out

## What is left of an outline (on the map) once these others are cut out of it: whole pieces, none with a hole in it
## (where one of them lies right inside a piece, that piece is first split in two through its middle).
func _minus(poly: PackedVector2Array, cutters: Array, from := 0, depth := 0) -> Array:
	if poly.size() < 3 or _m2(poly) < 0.0004:
		return []
	poly = _ccw(poly)
	if from >= cutters.size():
		return [poly]
	var cutter: PackedVector2Array = _ccw(cutters[from])
	var rest := Geometry2D.clip_polygons(poly, cutter)
	var holed := false
	for piece in rest:
		if Geometry2D.is_polygon_clockwise(piece):
			holed = true
	var out: Array = []
	if not holed or depth > 6:
		for piece in rest:
			if not Geometry2D.is_polygon_clockwise(piece):
				out.append_array(_minus(piece, cutters, from + 1, 0))
		return out
	var mid := Vector2.ZERO
	for q in cutter:
		mid += q / cutter.size()
	var around := _box_of(poly).grow(1.0)
	var halves: Array = []
	if depth % 2 == 0:
		halves = [Rect2(around.position, Vector2(mid.x - around.position.x, around.size.y)), Rect2(Vector2(mid.x, around.position.y), Vector2(around.end.x - mid.x, around.size.y))]
	else:
		halves = [Rect2(around.position, Vector2(around.size.x, mid.y - around.position.y)), Rect2(Vector2(around.position.x, mid.y), Vector2(around.size.x, around.end.y - mid.y))]
	for half: Rect2 in halves:
		var sq := PackedVector2Array([half.position, Vector2(half.end.x, half.position.y), half.end, Vector2(half.position.x, half.end.y)])
		for part in Geometry2D.intersect_polygons(poly, _ccw(sq)):
			if not Geometry2D.is_polygon_clockwise(part):
				out.append_array(_minus(part, cutters, from, depth + 1))
	return out

## an outline's area, m2
func _m2(poly: PackedVector2Array) -> float:
	var sum := 0.0
	for i in range(poly.size()):
		var q: Vector2 = poly[(i + 1) % poly.size()]
		sum += poly[i].x * q.y - q.x * poly[i].y
	return absf(sum) / 2.0

## Lays these stones edge to edge as one sheet with no seam in it, `lift` over the ground: [[outline (map), what of],
## ...], none over another. Each is cut along the relief's facets as _lay does; then the corners that should be one
## are made one, and every triangle is split at whatever corner of another falls on one of its sides, so that no two
## triangles meet along part of a side. Where they do, a hair's gap opens between them at some pixels, what is under
## the floor shows through it far deeper, and the ink of the screen's outlines (game.gd) draws a line along the seam.
func _lay_tight(parts: Array, lift: float) -> void:
	var cells: Array = []                            # [outline, what of], cut along the facets
	for part in parts:
		var poly: PackedVector2Array = _ccw(part[0])
		if poly.size() < 3:
			continue
		pieces += 1
		for facet: PackedVector2Array in _facets(_box_of(poly)):
			for piece in Geometry2D.intersect_polygons(poly, facet):
				if piece.size() >= 3 and not Geometry2D.is_polygon_clockwise(piece):
					cells.append([piece, part[1]])
	var knots := {}                                  # a grid of 0.2 mm -> the corner kept there
	var corners: Array = []
	for cell in cells:
		var tied := PackedVector2Array()             # (its corners, each the one kept for its spot)
		for q: Vector2 in cell[0]:
			tied.append(_knot(q, knots, corners))
		cell.append(tied)
	for cell in cells:
		var ring: PackedVector2Array = cell[0]       # (cut into triangles as Clipper gave it: two of its corners made one may pinch it)
		var tied: PackedVector2Array = cell[2]
		var box := _box_of(ring).grow(0.001)
		var near: Array = []
		for q: Vector2 in corners:
			if box.has_point(q):
				near.append(q)
		var idx := Geometry2D.triangulate_polygon(ring)
		if idx.is_empty():                           # (it would not be cut into triangles as it is: in convex parts, a fan each)
			for part: PackedVector2Array in Geometry2D.decompose_polygon_in_convex(ring):
				for t in range(1, part.size() - 1):
					_tight_tri(_knot(part[0], knots, corners), _knot(part[t], knots, corners), _knot(part[t + 1], knots, corners), near, lift, cell[1], 0)
			continue
		for t in range(0, idx.size(), 3):
			_tight_tri(tied[idx[t]], tied[idx[t + 1]], tied[idx[t + 2]], near, lift, cell[1], 0)

## the corner kept for this spot: the first one seen within 0.1 mm of it
func _knot(q: Vector2, knots: Dictionary, corners: Array) -> Vector2:
	var cx := roundi(q.x * 5000.0)
	var cy := roundi(q.y * 5000.0)
	for dx: int in [0, -1, 1]:
		for dy: int in [0, -1, 1]:
			var k := Vector2i(cx + dx, cy + dy)
			if knots.has(k) and (knots[k] as Vector2).distance_squared_to(q) < 1e-8:
				return knots[k]
	knots[Vector2i(cx, cy)] = q
	corners.append(q)
	return q

## a triangle of the sheet, split first at any corner that falls on one of its sides
func _tight_tri(a: Vector2, b: Vector2, c: Vector2, near: Array, lift: float, key, depth: int) -> void:
	if absf((b - a).cross(c - a)) < 2e-8:            # (nothing left of it)
		return
	if depth < 24:
		for side in [[a, b, c], [b, c, a], [c, a, b]]:
			var p0: Vector2 = side[0]
			var p1: Vector2 = side[1]
			var d := p1 - p0
			var ln2 := d.length_squared()
			for q: Vector2 in near:
				var t: float = (q - p0).dot(d) / ln2
				if t <= 0.0 or t >= 1.0 or q.distance_squared_to(p0) < 4e-8 or q.distance_squared_to(p1) < 4e-8:
					continue
				if (p0 + d * t).distance_squared_to(q) < 1e-8:
					_tight_tri(p0, q, side[2], near, lift, key, depth + 1)
					_tight_tri(q, p1, side[2], near, lift, key, depth + 1)
					return
	tri(_p3(a, lift), _p3(b, lift), _p3(c, lift), key, Vector3.UP)

## The floor: asphalt out to where the map's pale path reached; the kerb's stone; the flags; a band of pale stone
## inside the kerb all round, more of them across and one along; the beds of red under the trees and the pencil.
## It is one sheet at the kerb's height, where one walks (_walkable) and the things on it stand (_gy): no stone of it
## lies on another, each is cut out of the ones it would cover, and they are laid edge to edge with no seam (27 Nov
## 2026 -- the user: «Que no se apilen las capas del suelo». Laid one on another a centimetre and a half apart, the
## last of the five was 7 cm up and the benches and the pencil stood sunk in it).
func _floor() -> void:
	_lay(_grown(outline, 3.5), 0.006, "asfalto")
	var sheet: Array = []                            # its stones: [outline, what of]
	var flags := _grown(outline, -0.16)
	for piece in _minus(outline, [flags]):           # the kerb's stone, all round
		sheet.append([piece, "bordillo"])
	var band_out := _grown(outline, -1.15)
	var band_in := _grown(outline, -1.45)
	# (what is cut out of the others is each bed and each band whole, not what of it is laid: one that ended on an
	# edge of what it cuts would leave the two sides of it joined by a bridge of no width, and Godot will not cut
	# such an outline into triangles -- that stone would be missing)
	var red: Array = []                              # the beds, whole: nothing lies on them
	var beds: Array = [[PENCIL, 1.7], [BIG_TREE, 1.6], [SAPLING, 1.3]]
	for at: Vector2 in CYPRESSES:
		beds.append([at, 1.6])
	for bed in beds:
		red.append(_strip(bed[0], _along, bed[1], bed[1]))
	var round_bed := PackedVector2Array()
	for i in range(16):
		round_bed.append(PINE + Vector2(cos(TAU * i / 16.0), sin(TAU * i / 16.0)) * 1.0)
	red.append(round_bed)
	for bed in red:
		for piece in _inside(bed, flags):
			sheet.append([piece, RED])
	if band_in.size() < 3:                           # (too small an islet for its bands: flags up to the kerb)
		for piece in _minus(flags, red):
			sheet.append([piece, "losas"])
		_lay_tight(sheet, KERB)
		return
	var strips: Array = []                           # the bands of pale stone across it, whole, 4.4 m apart, through the pencil's bed
	var across := Vector2(-_along.y, _along.x)
	for k in range(-4, 5):
		strips.append(_strip(PENCIL + _along * (k * 4.4), across, 40.0, 0.28))
	var along := _strip(PENCIL, _along, 60.0, 0.28)  # ...and the one along it
	for strip in strips:
		for laid in _inside(strip, band_in):
			for piece in _minus(laid, red):
				sheet.append([piece, PALE])
	for laid in _inside(along, band_in):
		for piece in _minus(laid, strips + red):
			sheet.append([piece, PALE])
	for piece in _minus(band_in, strips + [along] + red):        # the flags within the band all round
		sheet.append([piece, "losas"])
	for piece in _minus(band_out, [band_in] + red):              # that band of pale stone
		sheet.append([piece, PALE])
	for piece in _minus(flags, [band_out] + red):                # the flags between it and the kerb
		sheet.append([piece, "losas"])
	_lay_tight(sheet, KERB)
## The kerb's face all round, following the ground; and what stops a car: a slab with a chamfered edge, so it bumps
## up on to it rather than into it.
func _kerb() -> void:
	var pts: Array = []
	for i in range(outline.size()):
		var a: Vector2 = outline[i]
		var b: Vector2 = outline[(i + 1) % outline.size()]
		var d: Vector2 = (b - a).normalized()
		var out := Vector3(d.y, 0, -d.x)             # (the ring runs anticlockwise on the map: its outside is to the right)
		if (Vector2(out.x, out.z)).dot(a - MID) < 0.0:
			out = -out
		var n := maxi(1, int(ceil(a.distance_to(b) / 1.5)))
		for s in range(n):
			var p: Vector2 = a.lerp(b, float(s) / n)
			var q: Vector2 = a.lerp(b, float(s + 1) / n)
			quad(_p3(p, -0.15), _p3(q, -0.15), _p3(q, KERB), _p3(p, KERB), "bordillo", out)
		pts.append(_p3(a, KERB))
		pts.append(_p3(a, -1.0))
	for q: Vector2 in _grown(outline, 0.25):
		pts.append(_p3(q, 0.0))
		pts.append(_p3(q, -1.0))
	_hull(pts)

## Whoever walks on it stands on its floor (MapData.foot): one sloping deck for each facet of the relief under it,
## reaching a step's width out of the kerb, so that nobody has to climb it.
func _walkable() -> void:
	var wide := _grown(outline, STEP)
	for facet: PackedVector2Array in _facets(_box_of(wide)):
		var ha: float = MapData.height(facet[0] * 0.98 + (facet[1] + facet[2]) * 0.01)      # (just inside each corner: on this facet for sure)
		var hb: float = MapData.height(facet[1] * 0.98 + (facet[0] + facet[2]) * 0.01)
		var hc: float = MapData.height(facet[2] * 0.98 + (facet[0] + facet[1]) * 0.01)
		var pa: Vector2 = facet[0] * 0.98 + (facet[1] + facet[2]) * 0.01
		var v1: Vector2 = (facet[1] * 0.98 + (facet[0] + facet[2]) * 0.01) - pa
		var v2: Vector2 = (facet[2] * 0.98 + (facet[0] + facet[1]) * 0.01) - pa
		var det: float = v1.x * v2.y - v1.y * v2.x
		var grad := Vector2(((hb - ha) * v2.y - (hc - ha) * v1.y) / det, (v1.x * (hc - ha) - v2.x * (hb - ha)) / det)
		for piece in Geometry2D.intersect_polygons(wide, facet):
			if piece.size() < 3 or Geometry2D.is_polygon_clockwise(piece):
				continue
			var o := Vector2.ZERO
			for q in piece:
				o += q / piece.size()
			var r2 := 0.0
			for q in piece:
				r2 = maxf(r2, o.distance_squared_to(q))
			MapData.decks.append({"o": o, "poly": piece, "r2": r2 + 1.0, "top": ha + grad.dot(o - pa) + KERB, "grad": grad})
			decks += 1

# ---------------- what stands on it ----------------
func _stand(at: Vector2) -> Vector3:
	things.append(at)
	yard.append(at)
	return Vector3(at.x - MID.x, _gy(at), at.y - MID.y)

## The pencil: six-sided, black with a yellow stripe down every other side, its rubber in a band of brass at the
## foot and its point, sharpened, in the air.
func _pencil() -> void:
	var o := _stand(PENCIL)
	var r := 0.12
	drum(o, r * 1.02, r * 1.02, 0.2, 0xd98a90, 6)
	drum(o + Vector3(0, 0.2, 0), r * 1.06, r * 1.06, 0.13, 0xc9a23a, 6)
	for i in range(6):
		var a0: float = TAU * i / 6.0
		var a1: float = TAU * (i + 1) / 6.0
		var p0 := o + Vector3(cos(a0) * r, 0.33, sin(a0) * r)
		var p1 := o + Vector3(cos(a1) * r, 0.33, sin(a1) * r)
		quad(p0, p1, p1 + Vector3(0, 2.45, 0), p0 + Vector3(0, 2.45, 0), BLACK if i % 2 == 0 else 0xe8a422, Vector3(cos((a0 + a1) / 2.0), 0, sin((a0 + a1) / 2.0)))
	pieces += 1
	drum(o + Vector3(0, 2.78, 0), r, 0.035, 0.34, 0xd9b98c, 6)
	drum(o + Vector3(0, 3.12, 0), 0.035, 0.0, 0.11, 0x2a2a2e, 6)
	solid(o + Vector3(0, 1.4, 0), Vector3(0.3, 3.0, 0.3))

## a tall old cypress: a bare trunk, then a column of dark green, ragged, wider in the middle
func _cypress(at: Vector2, tall: float) -> void:
	var o := _stand(at)
	drum(o - Vector3(0, 0.1, 0), 0.24, 0.17, 2.9, 0x6a5444, 8)
	drum(o + Vector3(0, 2.5, 0), 0.6, 1.2, 1.4, "cipres", 9)
	drum(o + Vector3(0, 3.9, 0), 1.2, 1.05, tall * 0.34, "cipres", 9)
	drum(o + Vector3(0, 3.9 + tall * 0.34, 0), 1.05, 0.08, tall * 0.66 - 3.9, "cipres", 9)
	for q in [[0.65, 4.6, 0.35, 0.75], [-0.55, 5.6, -0.4, 0.8], [0.3, 6.9, -0.6, 0.7], [-0.35, 3.6, 0.6, 0.65], [0.7, 3.3, -0.5, 0.55]]:
		ball(o + Vector3(q[0], q[1], q[2]), q[3], "cipres", 1.25, 8, 5)
	solid(o + Vector3(0, 1.5, 0), Vector3(0.5, 3.2, 0.5))

## the big tree: a stout trunk forking low, a wide crown going yellow at the edges
func _big_tree(at: Vector2, tall: float) -> void:
	var o := _stand(at)
	drum(o - Vector3(0, 0.1, 0), 0.33, 0.25, 3.1, 0x5f5046, 9)
	bar(o + Vector3(0, 2.8, 0), o + Vector3(1.3, 4.9, 0.5), 0.2, 0.2, 0x5f5046)
	bar(o + Vector3(0, 2.8, 0), o + Vector3(-1.1, 5.0, -0.7), 0.2, 0.2, 0x5f5046)
	var c: float = tall * 0.3
	for q in [[0.0, 0.72, 0.0, 1.0], [0.62, 0.6, 0.3, 0.72], [-0.6, 0.62, -0.32, 0.74], [0.2, 0.86, -0.5, 0.6], [-0.25, 0.9, 0.45, 0.58], [0.75, 0.74, -0.35, 0.5], [-0.7, 0.5, 0.5, 0.52]]:
		ball(o + Vector3(q[0] * c * 1.5, tall * q[1], q[2] * c * 1.5), c * q[3], "hoja", 0.8, 10, 6)
	solid(o + Vector3(0, 1.5, 0), Vector3(0.66, 3.2, 0.66))

## the pine, leaning out over the street, its crown flat and high
func _pine(at: Vector2) -> void:
	var o := _stand(at)
	var lean := Vector3(-_along.x, 0, -_along.y) * 1.5 + Vector3(0.4, 0, 0.5)
	bar(o - Vector3(0, 0.1, 0), o + lean * 0.55 + Vector3(0, 3.6, 0), 0.34, 0.34, 0x6a4a3a)
	bar(o + lean * 0.55 + Vector3(0, 3.6, 0), o + lean + Vector3(0, 6.4, 0), 0.24, 0.24, 0x6a4a3a)
	var top := o + lean + Vector3(0, 6.6, 0)
	for q in [[0.0, 0.3, 0.0, 2.3], [1.5, 0.0, 0.6, 1.6], [-1.4, 0.1, -0.7, 1.7], [0.3, 0.9, -1.2, 1.4], [-0.5, 0.8, 1.3, 1.4]]:
		ball(top + Vector3(q[0], q[1], q[2]), q[3], "pino", 0.55, 10, 5)
	solid(o + Vector3(0, 1.5, 0), Vector3(0.6, 3.2, 0.6))

## the sapling in its cage of wire
func _sapling(at: Vector2) -> void:
	var o := _stand(at)
	drum(o, 0.035, 0.025, 2.3, 0x6f5a45, 6)
	for q in [[0.0, 2.2, 0.0, 0.55], [0.2, 1.7, 0.1, 0.4], [-0.18, 1.9, -0.12, 0.42]]:
		ball(o + Vector3(q[0], q[1], q[2]), q[3], "hoja", 1.2, 8, 5)
	for i in range(4):                               # the cage: four uprights and three hoops of them
		var a: float = TAU * i / 4.0 + PI / 4.0
		var p := o + Vector3(cos(a), 0, sin(a)) * 0.3
		box(p.x - 0.01, p.y, p.z - 0.01, 0.02, 1.5, 0.02, 0x4a4d52)
		var b: float = TAU * (i + 1) / 4.0 + PI / 4.0
		for y in [0.5, 1.0, 1.5]:
			bar(p + Vector3(0, y, 0), o + Vector3(cos(b), 0, sin(b)) * 0.3 + Vector3(0, y, 0), 0.012, 0.012, 0x4a4d52)
	solid(o + Vector3(0, 0.8, 0), Vector3(0.6, 1.6, 0.6))

## A bench of black iron: two cast ends, a seat of plate, and a back of lattice between two rails; `look` is the way
## whoever sits on it faces.
func _bench(at: Vector2, look: Vector2) -> void:
	var o := _stand(at)
	var along := Vector2(look.y, -look.x)
	var keep := _xf
	_xf = Transform3D(Basis(Vector3(along.x, 0, along.y), Vector3.UP, Vector3(look.x, 0, look.y)), o)
	for s in [-0.93, 0.87]:                          # the ends: two legs, the arm, the foot
		box(s, 0.0, 0.17, 0.06, 0.43, 0.05, BLACK)
		box(s, 0.0, -0.3, 0.06, 0.92, 0.05, BLACK)
		box(s, 0.6, -0.28, 0.06, 0.04, 0.5, BLACK)
		box(s, 0.0, -0.3, 0.06, 0.035, 0.52, BLACK)
		ball(Vector3(s + 0.03, 0.64, 0.23), 0.045, BLACK, 1.0, 6, 4)
	box(-0.9, 0.4, -0.22, 1.8, 0.035, 0.44, 0x26262a)
	for y in [0.5, 0.88]:
		box(-0.9, y, -0.29, 1.8, 0.035, 0.03, BLACK)
	for i in range(-2, 12):                          # the lattice of its back: slim bars both ways, cut to the frame
		for way in [1.0, -1.0]:
			var x0: float = -0.9 + i * 0.16
			var x1: float = x0 + way * 0.35
			var a := Vector3(x0, 0.535, -0.275)
			var b := Vector3(x1, 0.88, -0.275)
			var lo: float = clampf((-0.9 - x0) / (x1 - x0), 0.0, 1.0) if x1 < x0 else clampf((0.9 - x0) / (x1 - x0), 0.0, 1.0)
			var hi: float = clampf((-0.9 - x0) / (x1 - x0), 0.0, 1.0) if x1 > x0 else 0.0
			if x0 > 0.9 or x0 < -0.9:
				if (x0 > 0.9 and x1 > 0.9) or (x0 < -0.9 and x1 < -0.9):
					continue
				hi = clampf(((0.9 if x0 > 0.9 else -0.9) - x0) / (x1 - x0), 0.0, 1.0)
				lo = 1.0
				bar(a.lerp(b, hi), a.lerp(b, lo), 0.012, 0.02, BLACK)
			else:
				bar(a, a.lerp(b, lo), 0.012, 0.02, BLACK)
	_xf = keep
	solid(o + Vector3(0, 0.45, 0), Vector3(1.9, 0.9, 0.55), atan2(-along.y, along.x))

## a bin: a basket hung on a post
func _bin(at: Vector2) -> void:
	var o := _stand(at)
	box(o.x - 0.025, o.y, o.z - 0.025, 0.05, 1.05, 0.05, 0x3a3d40)
	drum(o + Vector3(0.2, 0.5, 0), 0.15, 0.17, 0.42, 0x2a5fa0, 10)
	drum(o + Vector3(0.2, 0.92, 0), 0.18, 0.18, 0.03, 0x1f4678, 10)
	box(o.x, o.y + 0.8, o.z - 0.02, 0.1, 0.03, 0.04, 0x3a3d40)
	solid(o + Vector3(0.1, 0.55, 0), Vector3(0.5, 1.1, 0.36))

## the lamp: a slim black post and its four-sided lantern (lights.gd lights it at dusk)
func _lamp(at: Vector2) -> void:
	var o := _stand(at)
	drum(o, 0.13, 0.09, 0.5, BLACK, 8)
	drum(o + Vector3(0, 0.5, 0), 0.05, 0.04, 2.9, BLACK, 8)
	drum(o + Vector3(0, 3.4, 0), 0.07, 0.14, 0.1, BLACK, 8)
	cbox(o + Vector3(0, 3.74, 0), Vector3(0.26, 0.46, 0.26), 0xfff1c4)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			cbox(o + Vector3(sx * 0.13, 3.74, sz * 0.13), Vector3(0.025, 0.5, 0.025), BLACK)
	drum(o + Vector3(0, 3.98, 0), 0.24, 0.03, 0.22, BLACK, 8)
	ball(o + Vector3(0, 4.24, 0), 0.04, BLACK, 1.0, 6, 4)
	solid(o + Vector3(0, 2.0, 0), Vector3(0.3, 4.0, 0.3))
	lamp_at = transform * (o + Vector3(0, 3.74, 0))
	W.lamp_spots.append(lamp_at)

## the two signs of its west point: give way, and no entry, each on its post, looking down the street they are for
func _signs(mid: Vector2) -> void:
	var tip: Vector2 = outline[0]
	for q in outline:
		if q.x < tip.x:
			tip = q
	var inw: Vector2 = (mid - tip).normalized()
	var look := Vector2(0.1, 1.0).normalized()
	var across := Vector2(look.y, -look.x)
	for k in range(2):
		var at: Vector2 = tip + inw * (1.3 + k * 1.0) + Vector2(0, 0.25 - k * 0.2)
		if not Geometry2D.is_point_in_polygon(at, outline):
			at = tip + inw * (2.0 + k * 1.0)
		var o := _stand(at)
		var keep := _xf
		_xf = Transform3D(Basis(Vector3(across.x, 0, across.y), Vector3.UP, Vector3(look.x, 0, look.y)), o)
		box(-0.03, 0.0, -0.03, 0.06, 2.75 if k == 0 else 2.6, 0.06, 0x9a9da0)
		if k == 0:                                   # give way: the white triangle, point down, in its red rim
			slab(PackedVector2Array([Vector2(-0.4, 2.72), Vector2(0.4, 2.72), Vector2(0.0, 2.02)]), 0.04, 0.012, 0xc8202a)
			slab(PackedVector2Array([Vector2(-0.27, 2.645), Vector2(0.27, 2.645), Vector2(0.0, 2.17)]), 0.044, 0.0, 0xfdfcf8)
		else:                                        # no entry: the red disc and its white bar
			slab(oval(0.0, 2.25, 0.32, 0.32, 18), 0.04, 0.012, 0xc8202a)
			box(-0.23, 2.2, 0.04, 0.46, 0.1, 0.004, 0xfdfcf8)
		_xf = _xf * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)      # their backs, grey
		if k == 0:
			slab(PackedVector2Array([Vector2(-0.4, 2.72), Vector2(0.4, 2.72), Vector2(0.0, 2.02)]), -0.028, 0.0, 0x9a9da0)
		else:
			slab(oval(0.0, 2.25, 0.32, 0.32, 18), -0.028, 0.0, 0x9a9da0)
		_xf = keep
		solid(o + Vector3(0, 1.3, 0), Vector3(0.2, 2.6, 0.2))

## the three big bins for paper, glass and packaging, in a row on the far side of the street along its north-west
## side (props.gd stands them there: a car sends them flying like any other)
func _containers() -> void:
	var from := MID + Vector2(-_along.y, _along.x) * (-8.0 if Vector2(-_along.y, _along.x).y > 0.0 else 8.0)      # a point of that street: north of the islet
	var best = null
	var bd := 1e9
	for s in MapData.segs:
		if int(s.road["k"]) != 0:
			continue
		var d: float = Geometry2D.get_closest_point_to_segment(from, s.a, s.b).distance_to(from)
		if d < bd and absf((s.b - s.a).normalized().dot(_along)) > 0.9:
			bd = d
			best = s
	if best == null or bd > 12.0:
		return
	var foot: Vector2 = Geometry2D.get_closest_point_to_segment(from, best.a, best.b)
	var n: Vector2 = (foot - MID).normalized()
	n = (n - _along * n.dot(_along)).normalized()   # square to the street, away from the islet
	for k in range(3):
		var at: Vector2 = foot + _along * ((k - 1) * 2.3) + n * (float(best.hw) + 0.65)
		W.extra_props.append(["container", at, atan2(-n.x, -n.y), [2, 3, 1][k]])
