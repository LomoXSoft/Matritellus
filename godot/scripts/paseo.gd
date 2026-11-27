extends "res://scripts/obra.gd"
## The park of the Paseo del Cristo ("Parque del Paseo del Cristo" on the map), built by hand (the user, 21 November
## 2026, after the Residencia: "Podemos continuar con el parque largo empedrado que hay al lado del paseo del cristo
## (tiene su propia linea en street view, sin nombre)"; tools/paseo/, referencias/paseo/).
##
## A long walk of some 165 m from the corner of the Calle de las Viñas and the Calle de los Arcos to the little square
## before the hermitage of the Cristo del Prado, straight at its door. Street View along the walk itself (March 2013,
## the line with no name), from the Paseo (November 2024) and the orthophoto (PNOA):
##   - the walk: pale square tiles, a red square in a frame of red every fifteen metres; a band of slate flags
##     (irregular, blue-grey, in grey cement) along either side, iron benches and lanterns on them;
##   - a lawn on either side behind a kerb, trees in rows: planes with their trunks limewashed, old pollarded elms,
##     poplars, a weeping willow by a rockery, a palm;
##   - the chequered pavement, red and cream, along the Paseo;
##   - to the west, before the old house with the arches: a square of red brick, the millstone and the cone of stone on
##     their round base, a bed of box; the bed of cypresses with its low railing, the poplar, the tall lamp; the stone
##     and the carved trunk standing on the slate; the round planter of rubble round a tree;
##   - to the north: the limewashed wall of the gardens (its coping of tiles), then the yards' and the lane's low wall
##     of rubble with brick piers and a railing; a rockery of stones and urns;
##   - the square of slate where the path from the lane crosses to the Paseo (lanterns of two arms); at the east end
##     the slate round the calvario (the hermitage's, cristoprado.gd), stone benches, the bollards at its square.
##
## No rebake: it is laid over the ground, grass and footway the map has there, cut to the streets as the game has them
## (the game's Paseo lies some 4 m into the real park, so the south lawn is narrower), and the map's own trees in it are
## taken away when it is built (it plants its own, where the orthophoto has their crowns).
##
## Frame: origin at the west end of the map's footway down the park; +x along it, eastwards (east-south-east, to the
## hermitage); +z across it, southwards (to the Paseo); y = 0 the ground there.

const CristopradoS = preload("res://scripts/cristoprado.gd")
const Chara = preload("res://scripts/chara.gd")   # (the statue of the fountain: one of the game's own figures, in marble)

const O := Vector2(132.6, 441.6)
const U := Vector2(0.94236986, 0.33457292)
const S_W := -5.0                  # the west end (the corner's streets cut it short)
const S_E := 162.0                 # the east end, when the hermitage is not there to say where its square begins
const WALK_V0 := -3.2              # the walk's middle at x = 0 ...
const WALK_DV := 0.004             # ... and how it turns to meet the hermitage's door
const WALK_HALF := 2.2
const BAND := 1.4                  # the slate on either side of it
const ACERA := 2.6                 # the chequered pavement along the Paseo
const WALL_S0 := 13.0              # the white wall of the gardens to the north (the house of the arches west of it)
const WALL_S1 := 40.0
const WALL_V := -12.0
const FENCE_V := -11.0             # east of the wall, the line of the yards' railings (the lane's, where the map has it nearer)
const WEST_N := 14.0               # the square of brick before the house of the arches (north of the walk), to here
const WEST_S := 22.0               # the slate of the sculptures (south of the walk), to here...
const WEST_B := 15.5               # ...brick before it, as before the house
const CROSS0 := 61.0               # the square of slate where the path from the lane crosses to the Paseo
const CROSS1 := 80.0
const EAST0 := 139.0               # the slate round the calvario, to the hermitage's square
const LANE_GAP := Vector2(61.0, 71.0)     # (no railing there: the square opens onto the lane)
const MOTIFS: Array = [9.0, 24.0, 39.0, 54.0, 87.0, 102.0, 117.0, 132.0, 147.0]      # the red squares on the walk

# the trees: x, z, kind, how tall (their crowns on the orthophoto; kinds from Street View)
const TREES: Array = [
	[5.8, 3.0, "alamo", 17.0], [6.0, -8.0, "platano", 12.0], [17.2, 4.0, "acacia", 9.5],
	[21.5, -10.9, "olmo", 11.0], [27.3, -11.0, "olmo", 12.0], [31.5, -10.9, "alamo", 15.0], [38.2, -10.9, "olmo", 11.0],
	[28.2, 3.8, "platano", 12.0], [36.0, 4.4, "platano", 12.5], [41.2, 4.4, "platano", 11.5], [47.9, 4.6, "platano", 12.0], [54.0, 4.7, "platano", 12.0],
	[48.3, -7.9, "trasmocho", 10.0], [55.0, -8.4, "olmo", 10.0], [62.1, -8.7, "platano", 12.5],
	[71.0, 7.4, "platano", 13.0], [86.0, -6.9, "palmera", 7.0],
	[90.3, -7.8, "trasmocho", 10.5], [91.1, 4.7, "platano", 12.0], [96.4, 5.0, "platano", 12.0], [99.2, -7.6, "olmo", 10.5],
	[104.0, -8.4, "trasmocho", 11.0], [105.6, 5.2, "platano", 12.5], [107.4, 8.0, "platano", 10.0], [113.4, -8.6, "platano", 16.0],
	[113.5, 6.0, "platano", 11.0], [120.2, 7.4, "platano", 12.0], [125.0, -8.4, "sauce", 9.0], [131.0, 7.8, "platano", 12.0],
	[138.8, 7.4, "platano", 12.0], [131.2, -8.5, "palmera", 6.5], [142.5, -7.0, "platano", 12.0], [147.4, 9.8, "platano", 13.5], [156.2, 10.6, "olmo", 9.0]]
const LAMPS_N: Array = [3.0, 19.0, 35.0, 51.0, 83.0, 99.0, 115.0, 131.0, 147.0]
const LAMPS_S: Array = [11.0, 27.0, 43.0, 59.0, 91.0, 107.0, 123.0, 139.0, 155.0]
const BENCHES_N: Array = [7.0, 23.0, 31.0, 45.0, 57.0, 89.0, 95.0, 111.0, 119.0, 135.0]     # (none at 127: the fountain)
const BENCHES_S: Array = [25.0, 39.0, 49.0, 87.0, 101.0, 117.0, 129.0]
const BINS: Array = [[15.0, -1.0], [53.0, -1.0], [97.0, -1.0], [121.0, -1.0], [33.0, 1.0], [85.0, 1.0], [115.0, 1.0]]

var V := Vector2(-U.y, U.x)
var trees_n := 0                   # how many trees it planted (the self-test)
var felled := 0                    # how many of the map's trees it took away
var lamps: Array = []              # where its lanterns hang, in the world
var door := Vector2.ZERO           # the hermitage's door, on the map (the walk is aimed at it)
var _vk: PackedFloat32Array        # where the Paseo's asphalt begins, every metre from S_W
var _vn: PackedFloat32Array        # the north edge, every metre
var _vn_kind: Array = []           # what is there: "wall" (the gardens'), "house", "fence" (a railing on rubble)
var _east_a := Vector2(S_E, -20.0) # the hermitage's square's west edge, two points on it in this frame
var _east_b := Vector2(S_E, 20.0)
var _roads: Array = []             # [capsule, box]: the asphalt round the park, in this frame (_road_polys)

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"baldosa":          # the walk's pale tiles, laid square to it (forty centimetres)
			m = _laid(W._tex("pavement"), Color(0.86, 0.85, 0.82), 1.6)
		"losas":            # the slate flags (tools/paseo/losas.py)
			m = _laid(load("res://assets/paseo/losas.png"), Color.WHITE, 3.0)
		"ladrillo":         # the red brick of the square at the west end
			m = _laid(load("res://assets/empedrado/ladrillo.png"), Color(1.05, 0.9, 0.86), 1.6)
		"cesped":
			m = W._tmat(0x8cc45e, "grass", 3.0)
		"tierra":           # the earth of the beds
			m = W._tmat(0x8a6a4a, "earth", 2.0)
		"bordillo":         # the kerbs of the lawns and the Paseo
			m = Tex.mat("granular_concrete", Color(0.8, 0.79, 0.76))
		"mamposteria":      # the rubble of the low walls
			m = Tex.mat("stone_wall", Color(0.95, 0.9, 0.84))
		"granito":          # the stone benches, the millstones, the bases
			m = Tex.mat("granite_tile_03@1.8", Color(0.9, 0.89, 0.87))
		"ladrillo_muro":    # the piers of the low walls
			m = Tex.mat("medieval_red_brick", Color(1.0, 0.92, 0.86))
		"hoja_platano":
			m = W._tmat(0x7ca44c, "leaf", 1.5)
		"hoja_olmo":
			m = W._tmat(0x6a9444, "leaf", 1.4)
		"hoja_alamo":
			m = W._tmat(0x95b85a, "leaf", 1.4)
		"hoja_acacia":
			m = W._tmat(0xa2b85a, "leaf", 1.2)
		"hoja_sauce":
			m = W._tmat(0xa6c46c, "leaf", 1.0)
		"cipres":
			m = W._tmat(0x2f5a36, "leaf", 1.0)
		"palma":
			m = W._tmat(0x6f9a3e, "leaf", 1.0)
		"seto":             # the box of the beds
			m = W._tmat(0x4f7a3a, "leaf", 0.8)
		"roca":             # the monolith's rough stone, weathered
			m = W._tmat(0xa1957f, "earth", 1.2)
		"toba":             # the fountain's tufa, pale grey
			m = W._tmat(0xc2bdb1, "earth", 0.8)
		"agua":             # the fountain's water: clean (as the user wanted the plaza's)
			var wm := StandardMaterial3D.new()
			wm.albedo_color = Color(0.36, 0.62, 0.78)
			wm.roughness = 0.15
			wm.emission_enabled = true
			wm.emission = Color(0.3, 0.55, 0.7)
			wm.emission_energy_multiplier = 0.25
			m = wm
		"farol":            # the lanterns' glass (game.gd's lights warm it at dusk)
			var fm := StandardMaterial3D.new()
			fm.albedo_color = Color(0.98, 0.94, 0.8)
			fm.emission_enabled = true
			fm.emission = Color(1.0, 0.86, 0.55)
			fm.emission_energy_multiplier = 0.5
			m = fm
		_:
			return super(key)
	_mats[key] = m
	return m

## a texture laid in this place's own frame (square to the walk), `metres` a repeat
func _laid(t: Texture2D, tint: Color, metres: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.albedo_texture = t
	m.uv1_triplanar = true
	m.uv1_world_triplanar = false
	m.uv1_scale = Vector3.ONE / metres
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.roughness = 1.0
	return m

func build(world) -> void:
	W = world
	level = MapData.height(O)
	transform = Transform3D(Basis(Vector3(U.x, 0, U.y), Vector3.UP, Vector3(V.x, 0, V.y)), Vector3(O.x, level, O.y))
	W.add_child(self)
	var cp = W.get("cristoprado")
	if cp != null:
		_east_a = _loc(cp.spot(CristopradoS.SQ_X, -9.0))
		_east_b = _loc(cp.spot(CristopradoS.SQ_X, 12.0))
		door = cp.door
	_road_polys()
	_edges()
	_floors()
	_kerbs()
	_north()
	_west()
	_trees()
	_furniture()
	_fountain()
	_clear_map_trees()
	_commit()

# ---------------- where things are ----------------
## a spot on the map, in this frame
func _loc(p: Vector2) -> Vector2:
	var q := p - O
	return Vector2(q.dot(U), q.dot(V))

## the walk's middle at x
func vc(s: float) -> float:
	return WALK_V0 + WALK_DV * s

## the hermitage's square's west edge at z (its x)
func s_end(v: float) -> float:
	var t: float = (v - _east_a.y) / (_east_b.y - _east_a.y)
	return lerpf(_east_a.x, _east_b.x, t)

func _on_road(s: float, v: float, margin := 0.05) -> bool:
	return car_dist(spot(s, v)) < margin

## how far a spot on the map is past the edge of the nearest street's asphalt, as the game lays it (fitted between the
## houses; footpaths and the map's footway down the park do not count: the park is laid over them)
func car_dist(p: Vector2) -> float:
	var best := 99.0
	var list = MapData._seg_grid.get(Vector2i(MapData._cell(p.x), MapData._cell(p.y)))
	if list != null:
		for sg in list:
			if int(sg.road["k"]) != 0:
				continue
			best = minf(best, MapData.seg_point(sg, p).distance_to(p) - MapData.fitted_hw(sg))
	return best

## whether a spot on the map is in the park (`grow`: a margin round it)
func inside(p: Vector2, grow := 0.0) -> bool:
	var q := _loc(p)
	return q.x > S_W - grow and q.x < s_end(q.y) + grow and q.y > vn(q.x) - grow and q.y < vk(q.x) + grow

## the Paseo's edge and the north edge, every metre (as the game has its streets and houses)
func _edges() -> void:
	var n := int(S_E - S_W) + 2
	_vk.resize(n)
	_vn.resize(n)
	_vn_kind.resize(n)
	for i in range(n):
		var s: float = S_W + i
		var k := 16.0
		var v := vc(s) + WALK_HALF + BAND + 0.5
		while v < 16.0:
			if _on_road(s, v, 0.0):
				k = v - 0.05
				break
			v += 0.1
		_vk[i] = k
		var cap: float = WALL_V if (s >= WALL_S0 and s < WALL_S1) else (FENCE_V if s >= WALL_S1 else -11.6)
		var north := cap
		var kind := "wall" if (s >= WALL_S0 and s < WALL_S1) else "fence"
		v = vc(s) - WALK_HALF - BAND - 0.6
		while v > cap:
			var p := spot(s, v)
			if car_dist(p) < 0.3:
				north = v + 0.05
				kind = "fence"
				break
			if MapData.room_at(p) < 0.2:
				north = v + 0.05
				kind = "house"
				break
			v -= 0.1
		_vn[i] = north
		_vn_kind[i] = kind

func _at(arr: PackedFloat32Array, s: float) -> float:
	var f: float = clampf(s - S_W, 0.0, float(arr.size() - 1) - 0.001)
	var i := int(f)
	return lerpf(arr[i], arr[i + 1], f - i)

func vk(s: float) -> float:
	return _at(_vk, s)

func vn(s: float) -> float:
	return _at(_vn, s)

func _kind(s: float) -> String:
	return String(_vn_kind[clampi(int(roundf(s - S_W)), 0, _vn_kind.size() - 1)])

## what the ground is at a spot of the frame: "walk", "band", "lawn", "brick", "slate", "acera" (or "" off the park)
func zone(s: float, v: float) -> String:
	if s < S_W or s > s_end(v) or v < vn(s) or v > vk(s):
		return ""
	var c := vc(s)
	if absf(v - c) <= WALK_HALF:
		return "walk"
	if absf(v - c) <= WALK_HALF + BAND:
		return "band"
	if v >= vk(s) - ACERA:
		return "acera"
	if _plaza(s, v < c):
		return "brick" if s < (WEST_N if v < c else WEST_B) else "slate"
	return "lawn"

## whether the ground beside the walk at x is paved (a square) instead of lawn
func _plaza(s: float, north: bool) -> bool:
	if s < (WEST_N if north else WEST_S):
		return true
	return (s >= CROSS0 and s < CROSS1) or s >= EAST0

# ---------------- floors ----------------
## a piece of ground over the ground as it lies (a fan from its middle), a hand above it. Where it reaches a street
## it is cut along the asphalt's own edge (the streets round the park as the game lays them, `_roads`); a small piece
## (`small`: a tile of the chequers, a red square) that touches the asphalt is left out instead.
func _lay(pts: Array, key, lift: float, small := false) -> void:
	var near := false
	var cc := Vector2.ZERO
	for q: Vector2 in pts:
		cc += q / pts.size()
		if _on_road(q.x, q.y, 0.3) or q.x > s_end(q.y) + 0.01:
			near = true
	if not near:
		_fan(pts, cc, key, lift)
		return
	if small:
		for q: Vector2 in pts:
			if _on_road(q.x, q.y, 0.0) or q.x > s_end(q.y) + 0.01:
				return
		_fan(pts, cc, key, lift)
		return
	var box := Rect2(pts[0], Vector2.ZERO)
	for q: Vector2 in pts:
		box = box.expand(q)
	var polys: Array = [PackedVector2Array(pts)]
	if Geometry2D.is_polygon_clockwise(polys[0]):
		polys[0].reverse()
	for r in _roads:
		if not (r[1] as Rect2).intersects(box):
			continue
		var kept: Array = []
		for poly in polys:
			for piece in Geometry2D.clip_polygons(poly, r[0]):
				if not Geometry2D.is_polygon_clockwise(piece):          # (an outline, not a hole)
					kept.append(piece)
		polys = kept
	for poly: PackedVector2Array in polys:
		var idx := Geometry2D.triangulate_polygon(poly)
		for t in range(0, idx.size(), 3):
			var a: Vector2 = poly[idx[t]]
			var b: Vector2 = poly[idx[t + 1]]
			var c: Vector2 = poly[idx[t + 2]]
			tri(Vector3(a.x, ground(a.x, a.y) + lift, a.y), Vector3(b.x, ground(b.x, b.y) + lift, b.y), Vector3(c.x, ground(c.x, c.y) + lift, c.y), key, Vector3.UP)
		pieces += 1

func _fan(pts: Array, cc: Vector2, key, lift: float) -> void:
	var mid := Vector3(cc.x, ground(cc.x, cc.y) + lift, cc.y)
	for i in range(pts.size()):
		var p0: Vector2 = pts[i]
		var p1: Vector2 = pts[(i + 1) % pts.size()]
		tri(mid, Vector3(p0.x, ground(p0.x, p0.y) + lift, p0.y), Vector3(p1.x, ground(p1.x, p1.y) + lift, p1.y), key, Vector3.UP)
	pieces += 1

## the asphalt of the streets round the park as the game lays it (fitted between the houses), each stretch a capsule
## in this frame, with its box
func _road_polys() -> void:
	var lo := Vector2(S_W - 12.0, -30.0)
	var hi := Vector2(S_E + 12.0, 30.0)
	var area := Rect2(lo, hi - lo)
	for sg in MapData.segs:
		if int(sg.road["k"]) != 0:
			continue
		var a := _loc(sg.a)
		var b := _loc(sg.b)
		if not area.intersects(Rect2(a, Vector2.ZERO).expand(b).grow(8.0)):
			continue
		var hw: float = MapData.fitted_hw(sg)
		var d := b - a
		if d.length() < 0.01:
			continue
		var th := atan2(d.y, d.x)
		var poly := PackedVector2Array()
		for k in range(9):
			var t := th - PI / 2.0 + PI * k / 8.0
			poly.append(b + Vector2(cos(t), sin(t)) * hw)
		for k in range(9):
			var t := th + PI / 2.0 + PI * k / 8.0
			poly.append(a + Vector2(cos(t), sin(t)) * hw)
		if Geometry2D.is_polygon_clockwise(poly):
			poly.reverse()
		_roads.append([poly, Rect2(a, Vector2.ZERO).expand(b).grow(hw + 0.1)])

## a strip of ground from x s0 to s1, between z a(s) and b(s) (given at both ends), cut across into pieces 2 m wide
func _strip(s0: float, s1: float, a0: float, a1: float, b0: float, b1: float, key, lift: float) -> void:
	if s0 >= s_end(a0) and s0 >= s_end(b0):
		return
	var n := maxi(1, ceili(maxf(b0 - a0, b1 - a1) / 2.0))
	for k in range(n):
		var t0 := float(k) / n
		var t1 := float(k + 1) / n
		var p := [Vector2(s0, lerpf(a0, b0, t0)), Vector2(s1, lerpf(a1, b1, t0)), Vector2(s1, lerpf(a1, b1, t1)), Vector2(s0, lerpf(a0, b0, t1))]
		for q in p.size():
			var e: Vector2 = p[q]
			p[q] = Vector2(minf(e.x, s_end(e.y)), e.y)
		_lay(p, key, lift)

const LIFT_WALK := 0.05
const LIFT_BAND := 0.056
const LIFT_LAWN := 0.1
const LIFT_ACERA := 0.045
const LIFT_PLAZA := 0.052

## The walk, its bands, the lawns or squares beside it and the chequered pavement, a metre at a time.
func _floors() -> void:
	var s := S_W
	while s < S_E + 1.0:
		var s1 := s + 1.0
		var c0 := vc(s); var c1 := vc(s1)
		_strip(s, s1, c0 - WALK_HALF, c1 - WALK_HALF, c0 + WALK_HALF, c1 + WALK_HALF, "baldosa", LIFT_WALK)
		_strip(s, s1, c0 - WALK_HALF - BAND, c1 - WALK_HALF - BAND, c0 - WALK_HALF, c1 - WALK_HALF, "losas", LIFT_BAND)
		_strip(s, s1, c0 + WALK_HALF, c1 + WALK_HALF, c0 + WALK_HALF + BAND, c1 + WALK_HALF + BAND, "losas", LIFT_BAND)
		var mid := s + 0.5
		# north of the walk, to the wall
		var n0 := vn(s) + 0.02; var n1 := vn(s1) + 0.02
		if _plaza(mid, true):
			_strip(s, s1, n0, n1, c0 - WALK_HALF - BAND, c1 - WALK_HALF - BAND, "ladrillo" if mid < WEST_N else "losas", LIFT_PLAZA)
		else:
			_strip(s, s1, n0, n1, c0 - WALK_HALF - BAND, c1 - WALK_HALF - BAND, "cesped", LIFT_LAWN)
		# south of the walk, to the pavement
		var k0 := vk(s) - ACERA; var k1 := vk(s1) - ACERA
		if _plaza(mid, false):
			_strip(s, s1, c0 + WALK_HALF + BAND, c1 + WALK_HALF + BAND, k0, k1, "ladrillo" if mid < WEST_B else "losas", LIFT_PLAZA)
		else:
			_strip(s, s1, c0 + WALK_HALF + BAND, c1 + WALK_HALF + BAND, k0, k1, "cesped", LIFT_LAWN)
		_strip(s, s1, k0, k1, vk(s), vk(s1), 0xe4dccd, LIFT_ACERA)
		s = s1
	# the red of the chequers: every other square of half a metre, on one grid
	var t := 0.5
	var ix := int(floor(S_W / t))
	while ix * t < S_E:
		var x0: float = ix * t
		var lo: float = vk(x0 + t / 2.0) - ACERA
		var iz := int(ceil(lo / t))
		while (iz + 1) * t <= vk(x0 + t / 2.0) - 0.02:
			if (ix + iz) % 2 == 0:
				_lay([Vector2(x0, iz * t), Vector2(x0 + t, iz * t), Vector2(x0 + t, (iz + 1) * t), Vector2(x0, (iz + 1) * t)], 0xac5e48, LIFT_ACERA + 0.015, true)
			iz += 1
		ix += 1
	# the red squares on the walk
	for m in MOTIFS:
		_motif(m)
	_motif_bar(CROSS0 + 1.2)
	_motif_bar(CROSS1 - 1.6)

## a red square in a frame of red, on the walk (2.4 m across)
func _motif(s: float) -> void:
	var c := vc(s)
	var r := 1.2
	var w := 0.4
	var y := LIFT_WALK + 0.015
	for side in [[Vector2(s - r, c - r), Vector2(s + r, c - r + w)], [Vector2(s - r, c + r - w), Vector2(s + r, c + r)],
			[Vector2(s - r, c - r + w), Vector2(s - r + w, c + r - w)], [Vector2(s + r - w, c - r + w), Vector2(s + r, c + r - w)]]:
		var a: Vector2 = side[0]
		var b: Vector2 = side[1]
		_lay([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)], 0x9a5a4e, y, true)
	_lay([Vector2(s - 0.4, c - 0.4), Vector2(s + 0.4, c - 0.4), Vector2(s + 0.4, c + 0.4), Vector2(s - 0.4, c + 0.4)], 0x9a5a4e, y, true)

## a red band across the walk (where it meets the square of the crossing path)
func _motif_bar(s: float) -> void:
	var c := vc(s)
	_lay([Vector2(s, c - WALK_HALF + 0.4), Vector2(s + 0.4, c - WALK_HALF + 0.4), Vector2(s + 0.4, c + WALK_HALF - 0.4), Vector2(s, c + WALK_HALF - 0.4)], 0x9a5a4e, LIFT_WALK + 0.015, true)

# ---------------- kerbs ----------------
## a kerb along the line a -> b of the frame: its top `w` wide at `top` over the ground, its face to `side` (+1: +z)
func _kerb(a: Vector2, b: Vector2, top: float, side := 1.0, w := 0.12) -> void:
	if _on_road(a.x, a.y, 0.1) or _on_road(b.x, b.y, 0.1) or a.x > s_end(a.y) or b.x > s_end(b.y):
		return
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x) * side
	var ga := ground(a.x, a.y)
	var gb := ground(b.x, b.y)
	var ai := a - n * w
	var bi := b - n * w
	quad(Vector3(ai.x, ga + top, ai.y), Vector3(bi.x, gb + top, bi.y), Vector3(b.x, gb + top, b.y), Vector3(a.x, ga + top, a.y), "bordillo", Vector3.UP)
	quad(Vector3(a.x, ga - 0.05, a.y), Vector3(b.x, gb - 0.05, b.y), Vector3(b.x, gb + top, b.y), Vector3(a.x, ga + top, a.y), "bordillo", Vector3(n.x, 0, n.y))
	pieces += 1

## The kerbs: round every lawn, and along the Paseo between the pavement and the asphalt (down to the street).
func _kerbs() -> void:
	var s := S_W
	while s < S_E + 1.0:
		var s1 := s + 1.0
		var mid := s + 0.5
		var c0 := vc(s); var c1 := vc(s1)
		for north in [true, false]:
			if _plaza(mid, north):
				continue
			var e0: float = (c0 - WALK_HALF - BAND) if north else (c0 + WALK_HALF + BAND)
			var e1: float = (c1 - WALK_HALF - BAND) if north else (c1 + WALK_HALF + BAND)
			_kerb(Vector2(s, e0), Vector2(s1, e1), LIFT_LAWN + 0.05, 1.0 if north else -1.0)            # (the lawn's edge on the slate)
			if not north:
				_kerb(Vector2(s, vk(s) - ACERA), Vector2(s1, vk(s1) - ACERA), LIFT_LAWN + 0.05, 1.0)        # (and on the pavement)
		# the Paseo's kerb
		var a := Vector2(s, vk(s)); var b := Vector2(s1, vk(s1))
		if not (a.x > s_end(a.y) or b.x > s_end(b.y)):
			var ga := ground(a.x, a.y)
			var gb := ground(b.x, b.y)
			quad(Vector3(a.x, ga - 0.22, a.y), Vector3(b.x, gb - 0.22, b.y), Vector3(b.x, gb + LIFT_ACERA, b.y), Vector3(a.x, ga + LIFT_ACERA, a.y), "bordillo", Vector3(0, 0, 1))
			pieces += 1
		s = s1
	# the lawns' ends, across: where a square begins or ends
	for edge in [[WEST_N, true, 1.0], [WEST_S, false, 1.0], [CROSS0, true, -1.0], [CROSS0, false, -1.0], [CROSS1, true, 1.0], [CROSS1, false, 1.0], [EAST0, true, -1.0], [EAST0, false, -1.0]]:
		var x: float = edge[0]
		var north: bool = edge[1]
		var a: float = (vn(x) + 0.02) if north else (vc(x) + WALK_HALF + BAND)
		var b: float = (vc(x) - WALK_HALF - BAND) if north else (vk(x) - ACERA)
		_kerb(Vector2(x, a), Vector2(x, b), LIFT_LAWN + 0.05, float(edge[2]))

# ---------------- the north side ----------------
## The white wall of the gardens with its coping of tiles; then a low wall of rubble with piers of brick and an iron
## railing along the yards and the lane (none where a house stands on the park, none where the square meets the lane).
func _north() -> void:
	# the white wall
	_wall_run(Vector2(WALL_S0, WALL_V), Vector2(WALL_S1, WALL_V), 2.55)
	# the low wall and railing
	var s := WALL_S1
	var run0 := -1.0
	while s <= S_E:
		var ok: bool = _kind(s + 0.5) == "fence" and not (s + 0.5 >= LANE_GAP.x and s + 0.5 < LANE_GAP.y) and s + 1.0 <= s_end(vn(s + 1.0)) - 0.5
		if ok and run0 < 0.0:
			run0 = s
		if (not ok or s + 1.0 > S_E) and run0 >= 0.0:
			_railing(run0, s if not ok else s + 1.0)
			run0 = -1.0
		s += 1.0

## a limewashed wall from a to b (its foot along the ground), `tall` over it, with a coping of tiles both ways
func _wall_run(a: Vector2, b: Vector2, tall: float) -> void:
	var n := int(ceil(a.distance_to(b) / 2.0))
	for k in range(n):
		var p0 := a.lerp(b, float(k) / n)
		var p1 := a.lerp(b, float(k + 1) / n)
		var g0 := ground(p0.x, p0.y)
		var g1 := ground(p1.x, p1.y)
		var t := 0.34
		for side in [0.0, -t]:
			var nz := Vector3(0, 0, 1) if side == 0.0 else Vector3(0, 0, -1)
			quad(Vector3(p0.x, g0 - 0.3, p0.y + side), Vector3(p1.x, g1 - 0.3, p1.y + side), Vector3(p1.x, g1 + tall, p1.y + side), Vector3(p0.x, g0 + tall, p0.y + side), "white", nz)
		quad(Vector3(p0.x, g0 + tall, p0.y + 0.12), Vector3(p1.x, g1 + tall, p1.y + 0.12), Vector3(p1.x, g1 + tall + 0.2, p1.y - t / 2.0), Vector3(p0.x, g0 + tall + 0.2, p0.y - t / 2.0), 0xa95f3e, Vector3(0, 0.6, 0.8))
		quad(Vector3(p0.x, g0 + tall + 0.2, p0.y - t / 2.0), Vector3(p1.x, g1 + tall + 0.2, p1.y - t / 2.0), Vector3(p1.x, g1 + tall, p1.y - t - 0.12), Vector3(p0.x, g0 + tall, p0.y - t - 0.12), 0xa95f3e, Vector3(0, 0.6, -0.8))
		quad(Vector3(p0.x, g0 + tall - 0.06, p0.y + 0.12), Vector3(p1.x, g1 + tall - 0.06, p1.y + 0.12), Vector3(p1.x, g1 + tall, p1.y + 0.12), Vector3(p0.x, g0 + tall, p0.y + 0.12), 0x8e4f34, Vector3(0, 0, 1))
		quad(Vector3(p0.x, g0 + 0.0, p0.y + 0.005), Vector3(p1.x, g1 + 0.0, p1.y + 0.005), Vector3(p1.x, g1 + 0.35, p1.y + 0.005), Vector3(p0.x, g0 + 0.35, p0.y + 0.005), 0xd8d2c4, Vector3(0, 0, 1))      # (its foot, greyer)
		pieces += 1
	var m := (a + b) / 2.0
	solid(Vector3(m.x, ground(m.x, m.y) + tall / 2.0, m.y - 0.17), Vector3(a.distance_to(b), tall + 0.6, 0.34))
	yard.append(spot(a.x, a.y))
	yard.append(spot(b.x, b.y))

## the low wall of rubble with its piers and railing, from x s0 to s1 along the north edge
func _railing(s0: float, s1: float) -> void:
	if s1 - s0 < 1.5:
		return
	var tall := 0.55
	var rail := 0.95
	var s := s0
	while s < s1 - 0.01:
		var e := minf(s + 1.0, s1)
		var a := Vector2(s, vn(s))
		var b := Vector2(e, vn(e))
		var ga := ground(a.x, a.y)
		var gb := ground(b.x, b.y)
		for side in [0.0, -0.34]:
			var nz := Vector3(0, 0, 1) if side == 0.0 else Vector3(0, 0, -1)
			quad(Vector3(a.x, ga - 0.3, a.y + side), Vector3(b.x, gb - 0.3, b.y + side), Vector3(b.x, gb + tall, b.y + side), Vector3(a.x, ga + tall, a.y + side), "mamposteria", nz)
		quad(Vector3(a.x, ga + tall + 0.05, a.y - 0.38), Vector3(b.x, gb + tall + 0.05, b.y - 0.38), Vector3(b.x, gb + tall + 0.05, b.y + 0.04), Vector3(a.x, ga + tall + 0.05, a.y + 0.04), "granito", Vector3.UP)
		quad(Vector3(a.x, ga + tall, a.y + 0.04), Vector3(b.x, gb + tall, b.y + 0.04), Vector3(b.x, gb + tall + 0.05, b.y + 0.04), Vector3(a.x, ga + tall + 0.05, a.y + 0.04), "granito", Vector3(0, 0, 1))
		# the railing: uprights every 12 cm between two rails, a little in from the face
		var n := maxi(1, int((e - s) / 0.12))
		for k in range(n):
			var p := a.lerp(b, (k + 0.5) / n)
			var g := lerpf(ga, gb, (k + 0.5) / n) + tall + 0.05
			box(p.x - 0.009, g, p.y - 0.18, 0.018, rail, 0.018, IRON)
		for hh in [tall + 0.15, tall + rail]:
			bar(Vector3(a.x, ga + hh, a.y - 0.17), Vector3(b.x, gb + hh, b.y - 0.17), 0.035, 0.03, IRON)
		pieces += 1
		s = e
	# the piers of brick: at both ends and every five metres
	var k := 0
	var count := maxi(1, int(round((s1 - s0) / 5.0)))
	while k <= count:
		var x: float = lerpf(s0, s1, float(k) / count)
		var z: float = vn(x) - 0.17
		var g := ground(x, z)
		cbox(Vector3(x, g + 0.55, z), Vector3(0.42, 1.7, 0.42), "ladrillo_muro")
		cbox(Vector3(x, g + 1.43, z), Vector3(0.5, 0.06, 0.5), "granito")
		k += 1
	var m := Vector2((s0 + s1) / 2.0, vn((s0 + s1) / 2.0) - 0.17)
	var d := Vector2(s1, vn(s1)) - Vector2(s0, vn(s0))
	solid(Vector3(m.x, ground(m.x, m.y) + 0.8, m.y), Vector3(d.length(), 1.6, 0.4), atan2(-d.y, d.x))
	yard.append(spot(s0, vn(s0) - 0.17))
	yard.append(spot(s1, vn(s1) - 0.17))

# ---------------- the west end ----------------
## The stone press before the house of the arches, its bed of box; the bed of cypresses with its low railing, the tall
## lamp; the monolith with its bench and trough, and the round seat with its table, on the slate south of the walk.
func _west() -> void:
	_press()
	# the bed of box before the house's east part
	var bx0 := 4.5
	var bx1 := 12.0
	var bz0 := vn(8.0) + 0.15
	_lay([Vector2(bx0, bz0), Vector2(bx1, bz0), Vector2(bx1, bz0 + 1.3), Vector2(bx0, bz0 + 1.3)], "tierra", LIFT_PLAZA + 0.06)
	for i in range(6):
		var x := bx0 + 0.6 + i * 1.25
		ball(Vector3(x, ground(x, bz0 + 0.65) + 0.42, bz0 + 0.65), 0.45, "seto", 0.85, 9, 5)
	cbox(Vector3(9.5, ground(9.5, bz0 + 0.65) + 0.9, bz0 + 0.65), Vector3(0.45, 1.6, 0.45), "seto")      # (the clipped column)
	# the bed of cypresses with its low railing, the poplar and the tall lamp
	var r0 := Vector2(2.0, 1.9)
	var r1 := Vector2(8.6, 5.9)
	var push := 0.0                      # (east, until its corners are clear of the corner's asphalt as the game lays it)
	while push < 4.0 and (_on_road(r0.x + push, r0.y, 0.4) or _on_road(r0.x + push, r1.y, 0.4)):
		push += 0.25
	r0.x += push
	r1.x += push
	if push < 4.0:
		_lay([r0, Vector2(r1.x, r0.y), r1, Vector2(r0.x, r1.y)], "tierra", LIFT_PLAZA + 0.06)
		var ring: Array = [r0, Vector2(r1.x, r0.y), r1, Vector2(r0.x, r1.y), r0]
		for i in range(4):
			var a: Vector2 = ring[i]
			var b: Vector2 = ring[i + 1]
			_kerb(a, b, LIFT_PLAZA + 0.1, -1.0, 0.1)
			var n := maxi(2, int(a.distance_to(b) / 0.15))
			for k in range(n + 1):
				var p := a.lerp(b, float(k) / n)
				box(p.x - 0.008, ground(p.x, p.y) + LIFT_PLAZA + 0.1, p.y - 0.008, 0.016, 0.42, 0.016, IRON)
			bar(Vector3(a.x, ground(a.x, a.y) + 0.56, a.y), Vector3(b.x, ground(b.x, b.y) + 0.56, b.y), 0.03, 0.025, IRON)
			bar(Vector3(a.x, ground(a.x, a.y) + 0.3, a.y), Vector3(b.x, ground(b.x, b.y) + 0.3, b.y), 0.025, 0.02, IRON)
		for c in [Vector2(3.9 + push, 4.4), Vector2(5.3 + push, 4.7)]:
			_cipres(c, 8.0)
		var tl := Vector2(2.6 + push, 2.5)
		var gt := ground(tl.x, tl.y)
		drum(Vector3(tl.x, gt, tl.y), 0.14, 0.09, 0.6, 0x5d6b5e, 8)
		drum(Vector3(tl.x, gt + 0.6, tl.y), 0.08, 0.06, 7.4, 0x5d6b5e, 8)
		bar(Vector3(tl.x, gt + 7.9, tl.y), Vector3(tl.x + 0.9, gt + 8.1, tl.y + 0.3), 0.06, 0.05, 0x5d6b5e)
		cbox(Vector3(tl.x + 1.0, gt + 7.98, tl.y + 0.33), Vector3(0.5, 0.14, 0.26), 0x5d6b5e)
		solid(Vector3(tl.x, gt + 2.0, tl.y), Vector3(0.3, 4.0, 0.3))
		yard.append(spot(r0.x, r0.y))
		yard.append(spot(r1.x, r1.y))
	_monolith()
	_mesa()

# ---------------- trees ----------------
## the planes, elms, poplars, the acacia, the willow, the palm (none on the walk, the asphalt or past the square)
func _trees() -> void:
	for t in TREES:
		var at := Vector2(t[0], t[1])
		if _on_road(at.x, at.y, 0.8) or at.x > s_end(at.y) - 0.6 or absf(at.y - vc(at.x)) < WALK_HALF + 0.2:
			continue
		var z := zone(at.x, at.y)
		var foot := LIFT_LAWN if z == "lawn" else LIFT_PLAZA
		if z == "acera" or z == "slate" or z == "brick" or z == "band":
			_pit(at)
		match String(t[2]):
			"platano":
				_platano(at, t[3], foot)
			"olmo":
				_olmo(at, t[3], foot, false)
			"trasmocho":
				_olmo(at, t[3], foot, true)
			"alamo":
				_alamo(at, t[3], foot)
			"acacia":
				_acacia(at, t[3], foot)
			"sauce":
				_sauce(at, t[3], foot)
			"palmera":
				_palmera(at, t[3], foot)
		trees_n += 1

## the square of earth round a tree in a paved ground, edged
func _pit(at: Vector2) -> void:
	var r := 0.6
	_lay([at + Vector2(-r, -r), at + Vector2(r, -r), at + Vector2(r, r), at + Vector2(-r, r)], "tierra", LIFT_BAND + 0.016, true)
	for e in [[Vector2(-r, -r), Vector2(r, -r)], [Vector2(r, -r), Vector2(r, r)], [Vector2(r, r), Vector2(-r, r)], [Vector2(-r, r), Vector2(-r, -r)]]:
		_kerb(at + e[0], at + e[1], LIFT_PLAZA + 0.03, -1.0, 0.08)

## a plane: a pale mottled trunk limewashed to a man's height, forking, a broad crown of three or four rounds
func _platano(at: Vector2, tall: float, foot: float) -> void:
	var g := ground(at.x, at.y) + foot
	var r0 := 0.16 + tall * 0.012
	drum(Vector3(at.x, g - 0.2, at.y), r0 * 1.04, r0, 1.45, 0xeeebe3, 9)                   # (the lime)
	drum(Vector3(at.x, g + 1.25, at.y), r0, r0 * 0.82, tall * 0.48 - 1.25, 0xb4ab98, 9)
	var top := Vector3(at.x, g + tall * 0.48, at.y)
	var cr := tall * 0.25
	var h := hash(Vector2i(int(at.x * 10), int(at.y * 10)))
	var turn := float(h % 628) / 100.0
	ball(top + Vector3(0, tall * 0.2, 0), cr * 1.15, "hoja_platano", 0.78, 12, 7)            # (the crown's body)
	for k in range(4):
		var a := turn + TAU * k / 4.0
		var d := Vector3(cos(a) * cr * 0.42, tall * 0.13, sin(a) * cr * 0.42)
		bar(top, top + d, r0 * 0.8, r0 * 0.8, 0xb4ab98)
		ball(top + d * 1.6 + Vector3(0, tall * (0.04 + 0.03 * (k % 2)), 0), cr * (0.7 if k % 2 == 0 else 0.62), "hoja_platano", 0.8, 10, 6)
	ball(top + Vector3(cr * 0.15, tall * 0.36, -cr * 0.1), cr * 0.72, "hoja_platano", 0.85, 10, 6)
	solid(Vector3(at.x, g + 1.2, at.y), Vector3(r0 * 2.4, 2.4, r0 * 2.4))
	yard.append(spot(at.x, at.y))

## an elm: a dark trunk, forking into limbs with their crowns; `pollard`: the old ones cut back, a stout gnarled trunk
## swollen at its head, short limbs, smaller crowns
func _olmo(at: Vector2, tall: float, foot: float, pollard: bool) -> void:
	var g := ground(at.x, at.y) + foot
	var r0: float = 0.42 if pollard else 0.22
	var fork: float = tall * (0.3 if pollard else 0.4)
	drum(Vector3(at.x, g - 0.2, at.y), r0 * 1.15, r0 * 0.9, fork + 0.2, 0x5e5143, 9)
	var top := Vector3(at.x, g + fork, at.y)
	if pollard:
		ball(top, r0 * 1.25, 0x5e5143, 0.8, 9, 5)
	var cr: float = tall * (0.17 if pollard else 0.2)
	for k in range(4):
		var a := TAU * k / 4.0 + at.x
		var d := Vector3(cos(a) * cr * 0.8, tall * (0.22 if pollard else 0.25), sin(a) * cr * 0.8)
		bar(top, top + d, r0 * 0.6, r0 * 0.6, 0x5e5143)
		ball(top + d + Vector3(0, cr * 0.3, 0), cr * 0.8, "hoja_olmo", 0.8, 9, 5)
	ball(top + Vector3(0, tall * 0.42, 0), cr * 0.9, "hoja_olmo", 0.8, 9, 5)
	solid(Vector3(at.x, g + 1.2, at.y), Vector3(r0 * 2.3, 2.4, r0 * 2.3))
	yard.append(spot(at.x, at.y))

## a poplar: a tall pale trunk, a narrow crown up it
func _alamo(at: Vector2, tall: float, foot: float) -> void:
	var g := ground(at.x, at.y) + foot
	drum(Vector3(at.x, g - 0.2, at.y), 0.3, 0.16, tall * 0.62, 0xd6d2c6, 9)
	var cr := tall * 0.16
	ball(Vector3(at.x, g + tall * 0.62, at.y), cr, "hoja_alamo", 2.3, 12, 8)
	ball(Vector3(at.x + cr * 0.45, g + tall * 0.52, at.y + cr * 0.2), cr * 0.7, "hoja_alamo", 2.0, 10, 6)
	ball(Vector3(at.x - cr * 0.4, g + tall * 0.58, at.y - cr * 0.3), cr * 0.65, "hoja_alamo", 2.1, 10, 6)
	solid(Vector3(at.x, g + 1.2, at.y), Vector3(0.6, 2.4, 0.6))
	yard.append(spot(at.x, at.y))

## the acacia by the sculptures: a leaning trunk, a light spreading crown
func _acacia(at: Vector2, tall: float, foot: float) -> void:
	var g := ground(at.x, at.y) + foot
	var top := Vector3(at.x + 0.9, g + tall * 0.5, at.y + 0.3)
	bar(Vector3(at.x, g - 0.2, at.y), top, 0.26, 0.26, 0x6a5c4a)
	for q in [[0.0, 0.25, 0.0, 1.0], [1.4, 0.0, 0.6, 0.7], [-1.2, 0.1, -0.5, 0.75], [0.4, 0.3, -1.3, 0.6]]:
		ball(top + Vector3(q[0], tall * 0.18 + q[1], q[2]), tall * 0.26 * q[3], "hoja_acacia", 0.65, 10, 5)
	solid(Vector3(at.x, g + 1.2, at.y), Vector3(0.55, 2.4, 0.55))
	yard.append(spot(at.x, at.y))

## the weeping willow by the rockery: a short trunk, a round head and its curtain hanging nearly to the grass
func _sauce(at: Vector2, tall: float, foot: float) -> void:
	var g := ground(at.x, at.y) + foot
	drum(Vector3(at.x, g - 0.2, at.y), 0.3, 0.24, tall * 0.45, 0x6a5a48, 9)
	var head := Vector3(at.x, g + tall * 0.76, at.y)
	var R := tall * 0.26
	ball(head, R, "hoja_sauce", 0.72, 12, 6)
	for ring in [[1.0, 34, 0.0], [0.72, 22, 0.13]]:      # (its hanging strands, two rings of them, falling nearly to the grass)
		var n: int = ring[1]
		for i in range(n):
			var a: float = TAU * i / n + float(ring[2])
			var out: float = R * float(ring[0])
			var top := head + Vector3(cos(a) * out * 0.9, R * 0.25, sin(a) * out * 0.9)
			var mid := head + Vector3(cos(a) * out * 1.08, -R * 0.55, sin(a) * out * 1.08)
			var low := Vector3(at.x + cos(a) * out * 1.12, g + 1.0 + float((i * 7) % 5) * 0.28, at.y + sin(a) * out * 1.12)
			bar(top, mid, 0.26, 0.07, "hoja_sauce", 0.0)
			bar(mid, low, 0.22, 0.06, "hoja_sauce", 0.0)
	solid(Vector3(at.x, g + 1.2, at.y), Vector3(0.6, 2.4, 0.6))
	yard.append(spot(at.x, at.y))

## a Canary palm: a thick trunk, a great head of arching fronds
func _palmera(at: Vector2, tall: float, foot: float) -> void:
	var g := ground(at.x, at.y) + foot
	drum(Vector3(at.x, g - 0.2, at.y), 0.5, 0.42, tall + 0.2, 0x7a6448, 10)
	var top := Vector3(at.x, g + tall, at.y)
	var n := 24
	for i in range(n):
		var a := TAU * i / n + 0.3
		var up := 0.35 if (i % 2 == 0) else -0.05
		var dir := Vector3(cos(a), 0, sin(a))
		var ln := 3.4
		var mid := top + dir * ln * 0.5 + Vector3(0, ln * (0.25 + up * 0.5), 0)
		var tip := top + dir * ln + Vector3(0, -ln * (0.35 - up), 0)
		bar(top, mid, 0.55, 0.06, "palma")
		bar(mid, tip, 0.42, 0.05, "palma")
	ball(top, 0.6, 0x6a5a3a, 0.8, 8, 4)
	solid(Vector3(at.x, g + 1.2, at.y), Vector3(1.0, 2.4, 1.0))
	yard.append(spot(at.x, at.y))

## a cypress
func _cipres(at: Vector2, tall: float) -> void:
	var g := ground(at.x, at.y) + LIFT_PLAZA + 0.06
	drum(Vector3(at.x, g, at.y), 0.15, 0.12, 0.9, 0x5a4636, 7)
	drum(Vector3(at.x, g + 0.7, at.y), 0.6, 0.5, tall * 0.45, "cipres", 9)
	drum(Vector3(at.x, g + 0.7 + tall * 0.45, at.y), 0.5, 0.05, tall * 0.55 - 0.7, "cipres", 9)
	solid(Vector3(at.x, g + 1.2, at.y), Vector3(0.5, 2.4, 0.5))
	yard.append(spot(at.x, at.y))

# ---------------- benches, lanterns, bins, bollards ----------------
func _furniture() -> void:
	for s in LAMPS_N:
		_lamp(Vector2(s, vc(s) - WALK_HALF - BAND + 0.3))
	for s in LAMPS_S:
		_lamp(Vector2(s, vc(s) + WALK_HALF + BAND - 0.3))
	for s in BENCHES_N:
		_bench(Vector2(s, vc(s) - WALK_HALF - BAND * 0.55), Vector2(0, 1))
	for s in BENCHES_S:
		_bench(Vector2(s, vc(s) + WALK_HALF + BAND * 0.55), Vector2(0, -1))
	# the lanterns of two arms in the square of the crossing path
	_lamp2(Vector2(CROSS0 + 4.0, vc(CROSS0 + 4.0) - WALK_HALF - BAND - 1.2))
	_lamp2(Vector2(CROSS1 - 5.0, vc(CROSS1 - 5.0) + WALK_HALF + BAND + 1.2))
	# the stone benches at the east end, either side of the walk
	for side in [-1.0, 1.0]:
		var at := Vector2(151.0, vc(151.0) + side * (WALK_HALF + 0.75))
		_stone_bench(at)
	# bins (street furniture: a car knocks them over)
	for b in BINS:
		var s: float = b[0]
		var v: float = vc(s) + float(b[1]) * (WALK_HALF + BAND - 0.25)
		if not _on_road(s, v, 0.6):
			W.extra_props.append(["bin", spot(s + 1.3, v), 0.0, 0])
	# the bollards of dark iron where the walk meets the hermitage's square
	for k in range(7):
		var v := vc(150.0) - 3.3 + k * 1.1
		var s := s_end(v) - 0.6
		if not _on_road(s, v, 0.4) and s > EAST0:
			W.extra_props.append(["bollard", spot(s, v), 0.0, 1])

## A bench of iron (its back a grille of scrolls), its ends cast; `look`: the way whoever sits on it faces (in the frame).
func _bench(at: Vector2, look: Vector2) -> void:
	if _on_road(at.x, at.y, 1.0) or at.x > s_end(at.y) - 1.0:
		return
	var g := ground(at.x, at.y) + LIFT_BAND
	var along := Vector2(look.y, -look.x)
	var keep := _xf
	_xf = Transform3D(Basis(Vector3(along.x, 0, along.y), Vector3.UP, Vector3(look.x, 0, look.y)), Vector3(at.x, g, at.y))
	var dark := 0x2f3336
	for s in [-0.92, 0.86]:
		box(s, 0.0, 0.16, 0.06, 0.44, 0.06, dark)
		box(s, 0.0, -0.3, 0.06, 0.92, 0.06, dark)
		box(s, 0.6, -0.28, 0.06, 0.04, 0.5, dark)
		box(s, 0.0, -0.3, 0.06, 0.04, 0.52, dark)
	for i in range(5):
		box(-0.9, 0.42, -0.24 + i * 0.09, 1.8, 0.03, 0.06, dark)
	for y in [0.5, 0.9]:
		box(-0.9, y, -0.29, 1.8, 0.035, 0.03, dark)
	for i in range(9):                                       # (the scrolls of its back: rings between the rails)
		var x := -0.8 + i * 0.2
		for j in range(6):
			var a0 := TAU * j / 6.0
			var a1 := TAU * (j + 1) / 6.0
			bar(Vector3(x + cos(a0) * 0.08, 0.7 + sin(a0) * 0.12, -0.275), Vector3(x + cos(a1) * 0.08, 0.7 + sin(a1) * 0.12, -0.275), 0.014, 0.02, dark)
	_xf = keep
	solid(Vector3(at.x, g + 0.45, at.y), Vector3(1.9, 0.9, 0.55), atan2(-along.y, along.x))
	yard.append(spot(at.x, at.y))

## a bench of granite: a slab on two blocks
func _stone_bench(at: Vector2) -> void:
	if _on_road(at.x, at.y, 1.0) or at.x > s_end(at.y) - 1.0:
		return
	var g := ground(at.x, at.y) + LIFT_BAND
	cbox(Vector3(at.x, g + 0.36, at.y), Vector3(1.9, 0.12, 0.5), "granito")
	for sx in [-0.65, 0.65]:
		cbox(Vector3(at.x + sx, g + 0.15, at.y), Vector3(0.3, 0.3, 0.42), "granito")
	solid(Vector3(at.x, g + 0.21, at.y), Vector3(1.9, 0.42, 0.5))
	yard.append(spot(at.x, at.y))

## a lantern of the park: a dark post, its four-sided lantern (lit at dusk)
func _lamp(at: Vector2) -> void:
	if _on_road(at.x, at.y, 0.6) or at.x > s_end(at.y) - 0.5:
		return
	var g := ground(at.x, at.y) + LIFT_BAND
	var o := Vector3(at.x, g, at.y)
	var dark := 0x33383a
	drum(o, 0.14, 0.1, 0.55, dark, 8)
	drum(o + Vector3(0, 0.55, 0), 0.055, 0.045, 2.75, dark, 8)
	drum(o + Vector3(0, 3.3, 0), 0.07, 0.15, 0.1, dark, 8)
	cbox(o + Vector3(0, 3.65, 0), Vector3(0.28, 0.5, 0.28), "farol")
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			cbox(o + Vector3(sx * 0.14, 3.65, sz * 0.14), Vector3(0.025, 0.52, 0.025), dark)
	drum(o + Vector3(0, 3.9, 0), 0.26, 0.03, 0.22, dark, 8)
	ball(o + Vector3(0, 4.15, 0), 0.04, dark, 1.0, 6, 4)
	solid(o + Vector3(0, 2.0, 0), Vector3(0.3, 4.0, 0.3))
	yard.append(spot(at.x, at.y))
	var w: Vector3 = transform * (o + Vector3(0, 3.65, 0))
	lamps.append(w)
	W.lamp_spots.append(w)

## a lantern of two arms (the square of the crossing path)
func _lamp2(at: Vector2) -> void:
	if _on_road(at.x, at.y, 0.6):
		return
	var g := ground(at.x, at.y) + LIFT_PLAZA
	var o := Vector3(at.x, g, at.y)
	var dark := 0x33383a
	drum(o, 0.16, 0.11, 0.6, dark, 8)
	drum(o + Vector3(0, 0.6, 0), 0.065, 0.05, 3.2, dark, 8)
	for side in [-1.0, 1.0]:
		var hand := o + Vector3(side * 0.55, 3.55, 0)
		bar(o + Vector3(0, 3.5, 0), hand + Vector3(0, 0.2, 0), 0.04, 0.04, dark)
		cbox(hand + Vector3(0, -0.05, 0), Vector3(0.26, 0.46, 0.26), "farol")
		drum(hand + Vector3(0, 0.18, 0), 0.24, 0.03, 0.2, dark, 8)
		var w: Vector3 = transform * (hand + Vector3(0, -0.05, 0))
		lamps.append(w)
		W.lamp_spots.append(w)
	solid(o + Vector3(0, 2.0, 0), Vector3(0.32, 4.0, 0.32))
	yard.append(spot(at.x, at.y))

# ---------------- the pieces of stone (the user, 21 November 2026, with four pictures of March 2013: "Faltan varias
# cosas. La prensa de piedra, el monolito de piedra, la mesa de piedra, la fuente") ----------------

## a rough stone: a ball pulled out of round by a fixed noise (`salt`), its faces flat, so it reads as rock
func _lump(mid: Vector3, rad: Vector3, key, salt: int, rough := 0.22, sides := 10, rings := 6) -> void:
	pieces += 1
	var rows: Array = []
	for j in range(rings + 1):
		var t := PI * j / rings - PI / 2.0
		var row: Array = []
		for i in range(sides):
			var a := TAU * i / sides
			var k: float = (1.0 + rough * _noise(i, j, salt)) if (j > 0 and j < rings) else 1.0
			var ky := 1.0 + 0.5 * rough * _noise(j, i, salt + 7)
			row.append(mid + Vector3(cos(a) * cos(t) * rad.x * k, sin(t) * rad.y * ky, sin(a) * cos(t) * rad.z * k))
		rows.append(row)
	for j in range(rings):
		for i in range(sides):
			var a: Vector3 = rows[j][i]
			var b: Vector3 = rows[j][(i + 1) % sides]
			var c: Vector3 = rows[j + 1][(i + 1) % sides]
			var d: Vector3 = rows[j + 1][i]
			var n := (c - a).cross(d - b)
			var out := (a + b + c + d) / 4.0 - mid
			if n.length() < 0.000001:
				n = out
			if n.dot(out) < 0.0:
				n = -n
			quad(a, b, c, d, key, n.normalized())

func _noise(i: int, j: int, salt: int) -> float:
	var h := sin(float(i) * 12.9898 + float(j) * 78.233 + float(salt) * 37.719) * 43758.5453
	return (h - floor(h)) * 2.0 - 1.0

## a curved low wall about c (in the frame) from angle a0 to a1 (radians from +x towards +z), between radii r0 and r1,
## from y0 to y1; its top in `cap`, its ends closed unless it goes all round
func _arc(c: Vector2, r0: float, r1: float, a0: float, a1: float, y0: float, y1: float, key, cap, n := 12) -> void:
	pieces += 1
	for i in range(n):
		var t0 := lerpf(a0, a1, float(i) / n)
		var t1 := lerpf(a0, a1, float(i + 1) / n)
		var d0 := Vector2(cos(t0), sin(t0))
		var d1 := Vector2(cos(t1), sin(t1))
		var o0 := c + d0 * r1
		var o1 := c + d1 * r1
		var i0 := c + d0 * r0
		var i1 := c + d1 * r0
		var nm := Vector3(cos((t0 + t1) / 2.0), 0, sin((t0 + t1) / 2.0))
		quad(Vector3(o0.x, y0, o0.y), Vector3(o1.x, y0, o1.y), Vector3(o1.x, y1, o1.y), Vector3(o0.x, y1, o0.y), key, nm)
		if r0 > 0.01:
			quad(Vector3(i0.x, y0, i0.y), Vector3(i1.x, y0, i1.y), Vector3(i1.x, y1, i1.y), Vector3(i0.x, y1, i0.y), key, -nm)
		quad(Vector3(i0.x, y1, i0.y), Vector3(i1.x, y1, i1.y), Vector3(o1.x, y1, o1.y), Vector3(o0.x, y1, o0.y), cap, Vector3.UP)
	if a1 - a0 < TAU - 0.01:
		for e in [[a0, -1.0], [a1, 1.0]]:
			var ea: float = e[0]
			var d := Vector2(cos(ea), sin(ea))
			var tn: Vector2 = Vector2(-d.y, d.x) * float(e[1])
			var p := c + d * r0
			var q := c + d * r1
			quad(Vector3(p.x, y0, p.y), Vector3(q.x, y0, q.y), Vector3(q.x, y1, q.y), Vector3(p.x, y1, p.y), key, Vector3(tn.x, 0, tn.y))

## solids along an arc (for people and cars to run into), a box to each step
func _arc_solids(c: Vector2, r: float, a0: float, a1: float, y: float, tall: float, thick: float, n: int) -> void:
	for i in range(n):
		var t := lerpf(a0, a1, (i + 0.5) / n)
		var p := c + Vector2(cos(t), sin(t)) * r
		solid(Vector3(p.x, y + tall / 2.0, p.y), Vector3(r * (a1 - a0) / n + 0.05, tall, thick), -t - PI / 2.0)

## The stone press of the corner, as it was in March 2013 (by 2024 an upright millstone and a cone of stone stood there):
## a round plinth of rubble under its coping, the bed stone on it, three cones of stone lying on it round an iron pole,
## each on its axle with the iron plate of its eye, and the ring of iron that joins the axles' ends. Moved east until
## clear of the corner's streets as the game lays them.
func _press() -> void:
	var ms := Vector2(-3.0, -9.0)
	while car_dist(spot(ms.x, ms.y)) < 1.9 and ms.x < 6.0:
		ms.x += 0.5
	if ms.x >= 6.0:
		return
	var g := ground(ms.x, ms.y) + LIFT_PLAZA
	drum(Vector3(ms.x, g - 0.25, ms.y), 1.55, 1.55, 0.67, "mamposteria", 22)
	drum(Vector3(ms.x, g + 0.42, ms.y), 1.62, 1.62, 0.07, "granito", 22)              # (its coping)
	drum(Vector3(ms.x, g + 0.49, ms.y), 1.27, 1.27, 0.15, "granito", 22)              # (the bed stone)
	var yb := g + 0.64
	var ends: Array = []
	for k in range(3):
		var a := 1.6 + TAU * k / 3.0                                                   # (one pointing at the house, as in the picture)
		var d := Vector2(cos(a), sin(a))
		var p0 := Vector3(ms.x + d.x * 0.2, yb + 0.24, ms.y + d.y * 0.2)
		var p1 := Vector3(ms.x + d.x * 1.08, yb + 0.56, ms.y + d.y * 1.08)
		var ax := (p1 - p0).normalized()
		var ln := p0.distance_to(p1)
		var keep := _xf
		_xf = Transform3D(Basis(Quaternion(Vector3.UP, ax)), p0)
		drum(Vector3.ZERO, 0.24, 0.56, ln, "granito", 18)                              # (the cone, its big end out)
		drum(Vector3(0, ln, 0), 0.19, 0.19, 0.025, 0x2e2c2a, 12)                        # (the iron plate of its eye)
		var dn := _xf.basis.inverse() * Vector3.DOWN                                   # (and its rust, run down the face)
		var sd := Vector2(dn.x, dn.z).normalized()
		var pr := Vector2(-sd.y, sd.x) * 0.045
		var q0 := sd * 0.17
		var q1 := sd * 0.5
		quad(Vector3(q0.x - pr.x, ln + 0.006, q0.y - pr.y), Vector3(q0.x + pr.x, ln + 0.006, q0.y + pr.y),
				Vector3(q1.x + pr.x * 1.5, ln + 0.006, q1.y + pr.y * 1.5), Vector3(q1.x - pr.x * 1.5, ln + 0.006, q1.y - pr.y * 1.5), 0x6b3c24, Vector3.UP)
		_xf = keep
		ends.append(p1 + ax * 0.09)
	drum(Vector3(ms.x, yb, ms.y), 0.045, 0.04, 2.3, IRON, 8)                            # (the pole)
	for e in ends:
		bar(Vector3(ms.x, yb + 0.2, ms.y), e, 0.045, 0.045, IRON)                       # (the axles)
	var rr := 1.3
	var ry := yb + 0.6
	for i in range(18):                                                                  # (the ring)
		var t0 := TAU * i / 18.0
		var t1 := TAU * (i + 1) / 18.0
		bar(Vector3(ms.x + cos(t0) * rr, ry, ms.y + sin(t0) * rr), Vector3(ms.x + cos(t1) * rr, ry, ms.y + sin(t1) * rr), 0.035, 0.035, IRON)
	for e in ends:
		var f: Vector3 = e
		var h := Vector2(f.x - ms.x, f.z - ms.y).normalized() * rr
		bar(f, Vector3(ms.x + h.x, ry, ms.y + h.y), 0.035, 0.035, IRON)
	solid(Vector3(ms.x, g + 0.7, ms.y), Vector3(2.5, 1.6, 2.5))
	solid(Vector3(ms.x, g + 0.7, ms.y), Vector3(2.5, 1.6, 2.5), PI / 4.0)
	yard.append(spot(ms.x, ms.y))

## The monolith on the slate south of the walk (March 2013): a tall rough stone, broad at its foot and spreading east, a
## smear of red paint on it; a long bench of granite beside it at the walk's edge and a trough of stone for plants.
func _monolith() -> void:
	var mo := Vector2(12.4, 1.7)
	if _on_road(mo.x, mo.y, 1.5):
		return
	var g := ground(mo.x, mo.y) + LIFT_PLAZA
	var keep := _xf
	_xf = Transform3D(Basis(Vector3.UP, -0.25), Vector3(mo.x, g, mo.y))
	_lump(Vector3(0.25, 0.16, 0.0), Vector3(0.85, 0.3, 0.55), "roca", 3, 0.25)           # (its foot, spreading)
	_lump(Vector3(0.8, 0.1, 0.08), Vector3(0.45, 0.2, 0.34), "roca", 5, 0.3)
	_lump(Vector3(-0.05, 0.85, 0.0), Vector3(0.45, 0.72, 0.4), "roca", 11, 0.2)          # (its body)
	_lump(Vector3(-0.13, 1.47, 0.03), Vector3(0.34, 0.45, 0.31), "roca", 17, 0.22)
	_lump(Vector3(-0.06, 1.95, 0.0), Vector3(0.22, 0.26, 0.23), "roca", 23, 0.25)        # (its head)
	cbox(Vector3(-0.02, 0.95, -0.4), Vector3(0.13, 0.32, 0.04), 0xb02a26)                 # (the red paint)
	_xf = keep
	solid(Vector3(mo.x + 0.15, g + 1.0, mo.y), Vector3(1.3, 2.0, 1.0))
	yard.append(spot(mo.x, mo.y))
	_stone_bench(Vector2(10.4, vc(10.4) + WALK_HALF + 0.55))
	var tg := Vector2(10.6, 1.3)                                                           # the trough
	var gt := ground(tg.x, tg.y) + LIFT_PLAZA
	cbox(Vector3(tg.x, gt + 0.2, tg.y), Vector3(1.05, 0.4, 0.58), "granito")
	cbox(Vector3(tg.x, gt + 0.405, tg.y), Vector3(0.85, 0.02, 0.4), "tierra")
	for k in range(3):
		ball(Vector3(tg.x - 0.28 + k * 0.28, gt + 0.5, tg.y + (0.05 if k == 1 else -0.04)), 0.12, 0x6a6242, 1.3, 6, 4)    # (its dry plants)
	solid(Vector3(tg.x, gt + 0.2, tg.y), Vector3(1.05, 0.4, 0.58))
	yard.append(spot(tg.x, tg.y))

## The stone table (March 2013): a round seat of rubble under a coping of stone, open to the east and the west, its
## south half (towards the Paseo) with a back; in the middle the table, a round stone on a foot that widens upwards.
func _mesa() -> void:
	var c := Vector2(17.9, 1.2)
	if _on_road(c.x, c.y, 2.0):
		return
	var g := ground(c.x, c.y) + LIFT_PLAZA
	var gap := 0.42
	_arc(c, 1.1, 1.5, gap, PI - gap, g - 0.15, g + 0.44, "mamposteria", "granito", 10)            # (south: the seat...)
	_arc(c, 1.3, 1.5, gap, PI - gap, g + 0.44, g + 0.8, "mamposteria", "granito", 10)             # (...and its back)
	_arc(c, 1.1, 1.5, PI + gap, TAU - gap, g - 0.15, g + 0.44, "mamposteria", "granito", 10)      # (north: the seat)
	drum(Vector3(c.x, g - 0.05, c.y), 0.28, 0.4, 0.72, "granito", 16)
	drum(Vector3(c.x, g + 0.67, c.y), 0.55, 0.55, 0.09, "granito", 20)
	_arc_solids(c, 1.3, gap, PI - gap, g, 0.8, 0.4, 4)
	_arc_solids(c, 1.3, PI + gap, TAU - gap, g, 0.44, 0.4, 4)
	solid(Vector3(c.x, g + 0.38, c.y), Vector3(0.8, 0.76, 0.8))
	yard.append(spot(c.x, c.y))

## The fountain of the east part (March 2013, before the willow and the palm): a pond of clean water ringed by a low
## wall of tufa, pillars of tufa round it with white bowls of plants on them and chains hung between them, a heap of tufa
## in the middle with a white statue on it; slate round it, to the walk's band.
func _fountain() -> void:
	var cx := 128.3
	var north := -99.0                   # (the north edge as the game has it: the lane runs ~2 m nearer than the real one)
	for i in range(-3, 4):
		north = maxf(north, vn(cx + i * 0.8))
	var walk := vc(cx) - WALK_HALF - 0.3             # (it may take some of the slate band, never the walk)
	var r := minf(2.25, (walk - north - 0.4) / 2.0)  # (the outside of its wall)
	if r < 1.5:
		return
	var c := Vector2(cx, clampf(vc(cx) - WALK_HALF - BAND - 0.4 - r, north + 0.4 + r, walk - r))
	if car_dist(spot(c.x, c.y)) < r + 0.2:
		return
	var f := r / 2.25
	var pts: Array = []
	for k in range(28):
		var a := TAU * k / 28.0
		var p := c + Vector2(cos(a), sin(a)) * (r + 0.75)
		p.y = clampf(p.y, vn(p.x) + 0.2, vc(p.x) - WALK_HALF - BAND)
		pts.append(p)
	_lay(pts, "losas", LIFT_LAWN + 0.012)
	var g := ground(c.x, c.y) + LIFT_LAWN + 0.012
	drum(Vector3(c.x, g - 0.1, c.y), r - 0.4, r - 0.4, 0.3, "agua", 24)                # (the water, a hand under the wall's top)
	_arc(c, r - 0.45, r, 0.0, TAU, g - 0.1, g + 0.28, "toba", "toba", 24)                # the low wall...
	for k in range(20):                                                                  # (...rough with tufa)
		var a := TAU * k / 20.0 + 0.12 * _noise(k, 1, 31)
		_lump(Vector3(c.x + cos(a) * (r - 0.23), g + 0.3, c.y + sin(a) * (r - 0.23)), Vector3(0.3, 0.15 + 0.05 * _noise(k, 2, 31), 0.26), "toba", 40 + k, 0.3, 8, 4)
	var posts: Array = []
	for k in range(8):                                                                   # the pillars, their bowls
		var a := 0.2 + TAU * k / 8.0
		var p := c + Vector2(cos(a), sin(a)) * (r - 0.2)
		_lump(Vector3(p.x, g + 0.33, p.y), Vector3(0.23, 0.32, 0.22), "toba", 60 + k, 0.3, 9, 5)
		_lump(Vector3(p.x, g + 0.76, p.y), Vector3(0.18, 0.26, 0.17), "toba", 70 + k, 0.3, 9, 5)
		drum(Vector3(p.x, g + 0.97, p.y), 0.13, 0.27, 0.2, 0xeeebe4, 14)
		drum(Vector3(p.x, g + 1.15, p.y), 0.24, 0.24, 0.015, "tierra", 12)
		ball(Vector3(p.x, g + 1.27, p.y), 0.19, "seto", 0.7, 8, 4)
		posts.append(p)
	for k in range(8):                                                                   # the chains, hung between them
		var a: Vector2 = posts[k]
		var b: Vector2 = posts[(k + 1) % 8]
		var prev := Vector3(a.x, g + 0.7, a.y)
		for i in range(1, 7):
			var t := i / 6.0
			var q := a.lerp(b, t)
			var cur := Vector3(q.x, g + 0.7 - 0.2 * sin(PI * t), q.y)
			bar(prev, cur, 0.025, 0.025, 0x2a2826)
			prev = cur
	_lump(Vector3(c.x, g + 0.25, c.y), Vector3(0.85, 0.45, 0.8) * f, "toba", 81, 0.3)    # the heap in the middle
	_lump(Vector3(c.x + 0.05, g + 0.7, c.y - 0.03), Vector3(0.6, 0.4, 0.55) * f, "toba", 82, 0.3)
	_lump(Vector3(c.x - 0.03, g + 1.1, c.y), Vector3(0.4, 0.36, 0.38), "toba", 83, 0.3)
	_lump(Vector3(c.x, g + 1.45, c.y + 0.02), Vector3(0.26, 0.24, 0.25), "toba", 84, 0.3)
	for k in range(6):                                                                   # (stones in the water)
		var a := 0.5 + TAU * k / 6.0
		_lump(Vector3(c.x + cos(a) * 1.25 * f, g + 0.18, c.y + sin(a) * 1.25 * f), Vector3(0.24, 0.17, 0.21), "toba", 90 + k, 0.3, 8, 4)
	_statue(Vector3(c.x, g + 1.62, c.y), g + 0.2, f)                                     # the statue on it, its water running down
	solid(Vector3(c.x, g + 0.5, c.y), Vector3(1.9 * r, 1.0, 1.9 * r))
	solid(Vector3(c.x, g + 0.5, c.y), Vector3(1.9 * r, 1.0, 1.9 * r), PI / 4.0)
	yard.append(spot(c.x, c.y))

## The statue of the fountain. First the user said (21 November 2026): "la estatua de la fuente es de una mujer
## desnuda con un jarrón de donde sale el agua que cae a la fuente". Then: "vamos a sustituirlo por una figura de
## mármol de una mujer al estilo de nuestros personajes. Igual que con la estatua de bronce del fraile". So she is one
## of the game's own figures (chara.gd, as santaana.gd's friar), a woman with her hair up and nothing on, cast whole
## in white marble. She holds the pitcher on her left shoulder with that hand, her head leant towards it, and the other
## hand before her (Street View, March 2013). From the pitcher's mouth the water falls by her side onto the heap and runs
## down the tufa into the pond. `pond` is the water's height; `f` is how much the heap was shrunk to fit. She faces the
## walk (+z in this frame).
const STATUE_SCALE := 0.55               # (the game's people stand ~1.9 m: the real statue is about a metre)
var statue: Node3D
func _statue(at: Vector3, pond: float, f: float) -> void:
	var keep := _xf
	_xf = Transform3D(Basis.IDENTITY, at)
	drum(Vector3(0, -0.02, 0), 0.2, 0.18, 0.1, 0xeeebe4, 12)                             # (its little base)
	_xf = keep
	var tone := 0xeeebe4
	var who = Chara.new()
	who.setup({"shirt": tone, "skin": tone, "hair": tone, "shoes": tone, "socks": tone, "hair_style": 1, "face": 0, "brows": 0,
			"top": 0, "eye_color": tone, "lashes": 1, "shoe_type": 3})
	var pivot := Vector3(0, 0.95, 0)                    # her head leant a little towards the pitcher
	var tilt := Basis(Vector3(0, 0, 1), -0.12)
	who.neck.transform = Transform3D(tilt, pivot - tilt * pivot)
	who._hr.position = Vector3(0.54, 0.98, 0.1)          # the hand under the pitcher, on her left
	who._hl.position = Vector3(-0.26, 0.6, 0.31)         # the other before her
	var figure: Node3D = who.vis
	who.remove_child(figure)
	who.free()
	var jar := Vector3(0.7, 1.12, 0.02)                  # the pitcher, its mouth tipped out and down
	var d := Vector3(0.75, -0.55, 0.3).normalized()
	var turn := Quaternion(Vector3.UP, d)
	for piece in [["ball", jar, Vector3(0.17, 0.22, 0.17)], ["cyl", jar + d * 0.25, Vector3(0.07, 0.14, 0.07)],
			["cyl", jar + d * 0.325, Vector3(0.095, 0.03, 0.095)]]:
		var m := Parts.part(piece[0], tone, piece[1], piece[2])
		m.quaternion = turn
		figure.add_child(m)
	var marble := StandardMaterial3D.new()
	marble.albedo_color = Color(0.94, 0.93, 0.9)
	marble.roughness = 0.35
	marble.rim_enabled = true
	marble.rim = 0.25
	marble.emission_enabled = true                       # (so that it reads as white stone in the willow's shade too)
	marble.emission = Color(0.42, 0.41, 0.39)
	marble.emission_energy_multiplier = 0.25
	var todo: Array = [figure]
	while not todo.is_empty():
		var n: Node = todo.pop_back()
		if n is MeshInstance3D:
			(n as MeshInstance3D).material_override = marble
			(n as MeshInstance3D).visible = true
		todo.append_array(n.get_children())
	var foot := Vector3(0, 0.08, 0)
	statue = Node3D.new()
	statue.position = at + foot
	statue.scale = Vector3.ONE * STATUE_SCALE
	statue.add_child(figure)
	add_child(statue)
	pieces += 1
	# the water: a thread falling from the mouth onto the heap, then running down the tufa to the pond
	_xf = Transform3D(Basis.IDENTITY, at)
	var mouth := foot + (jar + d * 0.34) * STATUE_SCALE
	var top := 0.0
	var fall: Array = []
	for i in range(6):
		var t := i / 5.0
		fall.append(Vector3(mouth.x + 0.1 * t, lerpf(mouth.y, top + 0.02, t * t), mouth.z + 0.04 * t))
	for i in range(5):
		_limb(fall[i], fall[i + 1], 0.01, 0.014, 0xdff0f6, 6)
	var heap: Array = [[-1.37, 0.85 * f, 0.45 * f, 0.0], [-0.92, 0.6 * f, 0.4 * f, 0.05], [-0.52, 0.4, 0.36, -0.03], [-0.17, 0.26, 0.24, 0.0]]
	var run: Array = [fall[5]]           # (the heap's stones as _fountain lays them: their middle's height, x and y radii, x offset)
	var y: float = fall[5].y - 0.08
	var x: float = fall[5].x
	while y > pond - at.y + 0.04:
		for hp in heap:
			var q: float = (y - float(hp[0])) / float(hp[2])
			if absf(q) < 1.0:
				x = maxf(x, float(hp[3]) + float(hp[1]) * sqrt(1.0 - q * q) + 0.04)
		run.append(Vector3(x, y, 0.05))
		y -= 0.08
	run.append(Vector3(x + 0.05, pond - at.y + 0.01, 0.05))
	for i in range(run.size() - 1):
		_limb(run[i], run[i + 1], 0.016, 0.02, "agua", 6)
	_xf = keep

## a round piece from a to b (in the frame being built), ra thick at a and rb at b
func _limb(a: Vector3, b: Vector3, ra: float, rb: float, key, sides := 8) -> void:
	var run := b - a
	if run.length() < 0.001:
		return
	if run.normalized().y < -0.999:          # (straight down: from the other end, the turn from UP is not defined)
		_limb(b, a, rb, ra, key, sides)
		return
	var keep := _xf
	_xf = keep * Transform3D(Basis(Quaternion(Vector3.UP, run.normalized())), a)
	drum(Vector3.ZERO, ra, rb, run.length(), key, sides)
	_xf = keep

# ---------------- the map's own trees ----------------
## the trees the map plants in the park go (this plants its own where the orthophoto has them)
func _clear_map_trees() -> void:
	for i in range(W.tree_info.size()):
		var t: Dictionary = W.tree_info[i]
		if t["down"]:
			continue
		if inside(t["p"], 0.5):
			W.fell_tree(i)
			felled += 1
