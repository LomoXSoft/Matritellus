extends "res://scripts/obra.gd"
## The town's cemetery, on the old Madrid-Cádiz road 450 m north of where the map ends (the user, 25 November 2026:
## "Vamos a poner las con el cementerio"; reached through the zone change of zonas.gd, the user's idea from Borderlands
## 2, "A pie y en coche"). Built by hand from the PNOA orthophoto (tools/ign/cementerio_todo.jpg, 0.15 m a pixel) and
## from Street View of its front (2009, 2013 and 2024, from the road before it).
##
## A walled square of 151 by 170 m, turned 8.6 degrees with the road. Its wall plain and whitewashed, 2.4 m high. In
## the middle of its west side, on the road, the gatehouse: a long low white building under roofs of old curved tiles,
## hipped at both ends, a grey dado along its foot; in its middle a raised front between two stone pinnacles, and before
## it a body standing out with a gable, a small roof of tiles in its triangle and an iron cross over it; an arch either
## side of the middle -- the north one shut with an iron gate, the south one open: the way in, through the building.
## Before it, a square of concrete pavers to park on, round an island behind a kerb painted red and white: dark soil,
## junipers, cypresses and a bare tree, a no-entry sign at its north end.
## Inside: graves in plots of white, grey and black stone on a floor of pale gravel, in rows back to back with a narrow
## aisle between each two; a walk of cypresses east from the gatehouse; a broad walk down the middle with the family
## pantheons, a row of cypresses along it. No names and no dates on any grave (the advisor, 25 Nov: nobody's real grave).
##
## The cemetery's own measures: u along its north wall from its NW corner (east), v along its west wall (south). Its
## four corners are not quite a rectangle (north side 151.0 m, south 147.2), so a spot (u, v) goes to the frame by the
## four corners (P): what is square on the orthophoto turned square to its walls (tools/cementerio/perfiles.py) is
## square here. The frame: x along the north wall, z square to it (south), its origin the NW corner at the level of the
## gatehouse's floor.

const NW := Vector2(430.3, -2534.6)        # the outer corners of its wall (PNOA)
const NE := Vector2(579.6, -2512.0)
const SE := Vector2(551.6, -2345.3)
const SW := Vector2(406.0, -2366.8)
const WALL_H := 2.4
const WALL_T := 0.35
# the gatehouse, on the west wall: from v HALL_N to HALL_S, HALL_D deep into the cemetery
const HALL_N := 63.0
const HALL_S := 105.0
const HALL_D := 9.5
const MID := 23.3                          # its middle, from its north end (the cross: v 86.3, Street View 2024)
const ARCH := 4.7                          # its two arches, this far either side of the middle
const PIN := 3.55                          # the pinnacles at the corners of its raised front
const HOOD_OUT := 0.5                      # the little tiled roof on its gable, this far out of it
const EAVE := 3.2                          # the eaves of its wings (a van beside it: Street View 2024)...
const RISE := 1.6                          # ...and their ridges this much higher
const FRONT_TOP := 4.95                    # the corners of its raised front, the pinnacles' foot (Street View 2024, from the eaves)...
const APEX := 6.1                          # ...and the top of its broad low gable, pinnacle to pinnacle (the cross's top 1.7 higher)
const WINDOW := 1.4                        # the narrow arched window, this far south of the middle
const PASS_W := 1.5                        # the open arch, the way in on foot (no car goes through it)
const SHUT_R := 0.7                        # the shut arch: its radius, where its round begins, how far in its doorway is behind its gate
const SHUT_SPRING := 1.75
const SHUT_DEEP := 0.45
const ANNEX := 57.0                        # a low store behind the wall north of the gatehouse, from here to it
# the plots of graves: their columns (u) and rows (v), measured on the orthophoto
const COLS := [[2.0, 14.5], [16.5, 34.5], [36.5, 54.5], [56.5, 74.0], [78.0, 96.0], [98.0, 116.5], [118.5, 137.0], [139.0, 148.0]]
const ROWS := [[3.0, 24.0], [26.0, 43.5], [46.0, 64.0], [66.0, 82.5], [90.0, 105.5], [107.0, 124.5], [126.5, 143.5], [145.5, 167.0]]
const CROSS_WALK := [83.6, 88.4]           # the walk of cypresses across it, east from the gatehouse
const AVENUE := [76.5, 97.0]               # the broad walk down its middle (between its 3rd and 6th rows), with the pantheons
# a grave: its width, its length, how far apart side by side; two back to back (heads together), then an aisle
const G_W := 1.0
const G_L := 2.15
const PITCH := 1.25
const PAIR := 4.4
const AISLE := 1.0                         # (the player is 0.76 across: room to walk between the pairs of rows)
# the family pantheons on the broad walk: u0, u1, v0, v1 and what they are (orthophoto: their outlines and shadows)
const PANTHEONS := [
	[80.0, 84.5, 45.0, 50.5, "recinto"], [86.0, 90.0, 45.0, 50.5, "recinto"], [85.0, 88.5, 53.0, 57.0, "losa"],
	[80.0, 83.5, 58.0, 62.0, "capilla"], [79.0, 84.0, 65.5, 70.5, "capilla"], [90.0, 94.0, 66.0, 70.5, "recinto"],
	[80.0, 84.0, 72.0, 76.5, "losa"], [85.0, 89.0, 72.0, 76.5, "losa"], [82.0, 86.0, 89.5, 93.0, "losa"],
	[90.0, 94.0, 88.6, 92.5, "losa"], [80.0, 84.0, 94.0, 98.0, "capilla"], [86.0, 90.0, 95.5, 99.5, "recinto"],
	[86.0, 90.5, 101.0, 106.0, "recinto"], [80.0, 84.0, 102.0, 106.0, "losa"], [80.0, 85.0, 110.0, 115.0, "losa"],
	[87.0, 92.0, 112.0, 117.0, "capilla"]]
# before it, on the road side (u < 0): the island of the square
const CYPRESS := Vector2(-5.8, 93.8)       # the cypress with the whitewashed trunk before the gatehouse (u, v), south of the open arch
const SAFFRON_VASE := Vector2(139.0, 156.0)      # the hidden saffron in a vase: the one nearest here on the end of a row
const ISLE_U := -23.6                      # its straight side, along the road
const ISLE_V0 := 76.0
const ISLE_V1 := 97.0
const ISLE_OUT := 12.6                     # how far its round side bulges east of that
const PAVE_U := -24.6                      # where the pavers meet the road
const PAVE_V0 := 58.0
const PAVE_V1 := 108.0
const MARBLE := 0xe9e6df
const GRANITE := 0x8e8c88
const DARK := 0x3a3a3d
const SOIL := 0x4a3a2c

var ex := Vector2.ZERO                     # the frame's x on the map (along the north wall) and z (square to it, south)
var ez := Vector2.ZERO
var c_ne := Vector2.ZERO                   # the corners in the frame (NW is its origin)
var c_se := Vector2.ZERO
var c_sw := Vector2.ZERO
var L_N := 0.0                             # the north and west walls' lengths: what u and v run over
var L_W := 0.0
var graves := 0                            # how many graves (for the self-test)
var plots: Array = []                      # [u0, u1, v0, v1] of each plot filled (for the self-test)
var pair_rows: Array = []                  # [u0, u1, v0, v1] of each two rows of graves back to back (their solids)
var gate_in := Vector2.ZERO                # the way in, on the map: the middle of the open arch, on the road side...
var gate_out := Vector2.ZERO               # ...and where it comes out inside
var shut_arch := Vector2.ZERO              # the shut arch, on the map
var trees_put: Array = []                  # the trees planted here: [x, z, kind, size, turn] (world.add_trees)
var _mm := {}                              # what the graves are drawn with: name -> [[Transform3D, Color]...]
var _vases: Array = []                     # the vases at the outer end of a row in the south-east quarter: [spot (frame), top, q, its flower's index]
var saffron: Array = []                    # the hidden saffrons: [id, spot on the map] (for the self-test)
var candles := 0                           # how many graves have candles (for the self-test)
var words := 0                             # how many graves have «R.I.P.» or «D.E.P.» cut in them (for the self-test)...
var words_rip := 0                         # ...how many of them the first...
var words_upright := 0                     # ...and how many in an upright stone (the rest, in the slab)
var whitewashed := 0                       # how many trees of the road's row have a whitewashed trunk (for the self-test)
var _candle_at: Array = []                 # each candle's flame, in the frame
var _glow_mi: MultiMeshInstance3D          # their glow at night
var _glow_mat: ShaderMaterial
var _white_mm: MultiMesh                   # the whitewash on the trunks: one sleeve a tree...
var _white: Array = []                     # ...[its index in the world's tree_info, its sleeve's Transform3D, shown]
var _wait := 0.0

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"cal":                # the whitewash of its walls and its gatehouse
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.99, 0.96)), 0.22)
		"grava":              # the pale gravel of its walks
			m = Tex.mat("granular_concrete", Color(0.84, 0.79, 0.7), false)
		"losetas":            # the grey tiles of the walk of cypresses and of the way in
			m = Tex.mat("granite_tile_03", Color(0.8, 0.79, 0.77), false)
		"adoquin":            # the pavers of the square before it: grey concrete (Street View 2024)
			m = Tex.mat("square_cobblestone", Color(1.0, 1.08, 1.4), false)
		"acera":              # the light tiles of the pavement along the road
			m = Tex.mat("granite_tile_04", Color(0.92, 0.92, 0.9), false)
		"tierra_isleta":
			m = W._tmat(SOIL, "leaf", 2.0)
		"enebro":             # the junipers of the island, low and spread
			m = W._tmat(0x4c6a47, "leaf", 1.2)
		"seto":
			m = W._tmat(0x7a8a4a, "leaf", 1.2)
		"rojizo":             # the shrubs gone red-brown in autumn among them
			m = W._tmat(0x8a4a36, "leaf", 1.2)
		"tiles_viejas":       # old curved tiles, gone grey and brown (its UVs in units of 1.6 m, as obra.gd's "tiles")
			var tm: StandardMaterial3D = Tex.mat("roof_tiles", Color(0.62, 0.7, 0.8), true, 1.6)
			tm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = tm
		"farol":              # the lamps' glass (lights.gd lights them at dusk: world.lamp_spots)
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

# ---------------- the frame ----------------
func _frame() -> void:
	ex = (NE - NW).normalized()
	ez = Vector2(-ex.y, ex.x)
	c_ne = to_frame(NE)
	c_se = to_frame(SE)
	c_sw = to_frame(SW)
	L_N = c_ne.length()
	L_W = c_sw.length()

## a spot on the map, in the frame
func to_frame(p: Vector2) -> Vector2:
	var d := p - NW
	return Vector2(d.dot(ex), d.dot(ez))

## a spot of the cemetery (u east along its north wall, v south along its west wall) in the frame, by its four corners
func P(u: float, v: float) -> Vector2:
	var s := u / L_N
	var t := v / L_W
	return c_ne * s * (1.0 - t) + c_se * s * t + c_sw * (1.0 - s) * t

## the same, on the map
func map_at(u: float, v: float) -> Vector2:
	var f := P(u, v)
	return NW + ex * f.x + ez * f.y

## how high the ground is at (u, v), over the gatehouse's floor
func g_uv(u: float, v: float) -> float:
	return MapData.height(map_at(u, v)) - level

func build(world) -> bool:
	W = world
	_frame()
	level = MapData.height(map_at(0.0, HALL_N + MID))
	transform = Transform3D(Basis(Vector3(ex.x, 0, ex.y), Vector3.UP, Vector3(ez.x, 0, ez.y)), Vector3(NW.x, level, NW.y))
	W.add_child(self)
	ridge_hex = 0x8a7e72                   # (the round tiles of its ridges and hips, old and grey)
	gate_in = map_at(-1.5, HALL_N + MID + ARCH)
	gate_out = map_at(HALL_D + 1.5, HALL_N + MID + ARCH)
	shut_arch = map_at(0.0, HALL_N + MID - ARCH)
	_floors()
	_walls()
	_gatehouse()
	_annex()
	_square()
	_island()
	_graves()
	_pantheons()
	_trees()
	_lamps()
	_roadside()
	home()
	_commit()
	_saffron()
	_grave_meshes()
	_candle_glow()
	var first: int = W.tree_info.size()
	if not trees_put.is_empty():
		W.add_trees(trees_put)
	_whitewash(first)
	return true

## Each moment (zonas.gd tick): the candles' glow by the night, and the whitewash of a tree a car has felled gone with
## it (and back with it the next day)
func tick(dt: float) -> void:
	_wait -= dt
	if _wait > 0.0:
		return
	_wait = 0.25
	var game = W.get_parent() if W != null else null
	var night := 0.0
	if game != null and game.get("sky_fx") != null:
		night = float(game.sky_fx.night)
	if _glow_mi != null:
		_glow_mi.visible = night > 0.02
		if _glow_mi.visible:
			_glow_mat.set_shader_parameter("night", night)
	if _white_mm != null:
		for k in range(_white.size()):
			var e: Array = _white[k]
			var down: bool = bool((W.tree_info[int(e[0])] as Dictionary)["down"])
			if down == bool(e[2]):
				e[2] = not down
				_white_mm.set_instance_transform(k, (e[1] as Transform3D) if not down else Transform3D(Basis.from_scale(Vector3.ONE * 0.0001), Vector3(0.0, -50.0, 0.0)))

## What of the land round it is its own, for the zone's dry plants and loose trees to keep off (zonas.gd _scrub), as
## outlines on the map: for the plants its wall and all in it, `grow` metres out, its square with the island and its
## pavement; for the trees all that and the whole strip before it out past the road and its row of trees across it
func keep_off(trees: bool, grow: float) -> Array:
	if trees:
		return [_uv_poly(-47.0 - grow, L_N + grow, -6.0 - grow, L_W + 6.0 + grow)]
	return [_uv_poly(-grow, L_N + grow, -grow, L_W + grow), _uv_poly(PAVE_U - 1.0, 0.0, PAVE_V0 - 1.5, PAVE_V1 + 1.0),
		_uv_poly(PAVE_U - 1.0, PAVE_U + 3.6, PAVE_V1, L_W - 1.0)] + roadside

func _uv_poly(u0: float, u1: float, v0: float, v1: float) -> PackedVector2Array:
	return PackedVector2Array([map_at(u0, v0), map_at(u1, v0), map_at(u1, v1), map_at(u0, v1)])

# ---------------- laying things on the ground ----------------
## a flat thing lying on the ground with this outline (u, v), `lift` over it: cut along the columns of the plain's
## heights (past the map's edge the land is straight between them, world.gd _terrain), so it lies on it everywhere
func _lay(uv_pts: Array, lift: float, key) -> void:
	var wpoly := PackedVector2Array()
	for q in uv_pts:
		wpoly.append(map_at(q.x, q.y))
	_lay_map(wpoly, lift, key)

## the same, its outline on the map
func _lay_map(wpoly: PackedVector2Array, lift: float, key) -> void:
	if Geometry2D.is_polygon_clockwise(wpoly):
		wpoly.reverse()
	var box := Rect2(wpoly[0], Vector2.ZERO)
	for q in wpoly:
		box = box.expand(q)
	var g: float = MapData.rg
	for i in range(int(floor((box.position.x - MapData.rx0) / g)), int(floor((box.end.x - MapData.rx0) / g)) + 1):
		for j in range(int(floor((box.position.y - MapData.rz0) / g)), int(floor((box.end.y - MapData.rz0) / g)) + 1):
			var cell := Vector2(MapData.rx0 + i * g, MapData.rz0 + j * g)
			for facet in [PackedVector2Array([cell, cell + Vector2(g, 0), cell + Vector2(g, g)]), PackedVector2Array([cell, cell + Vector2(g, g), cell + Vector2(0, g)])]:
				if Geometry2D.is_polygon_clockwise(facet):
					facet.reverse()
				for piece in Geometry2D.intersect_polygons(wpoly, facet):
					if piece.size() < 3 or Geometry2D.is_polygon_clockwise(piece):
						continue
					var idx := Geometry2D.triangulate_polygon(piece)
					for t in range(0, idx.size(), 3):
						var a: Vector2 = piece[idx[t]]
						var b: Vector2 = piece[idx[t + 1]]
						var c: Vector2 = piece[idx[t + 2]]
						tri(_on(a, lift), _on(b, lift), _on(c, lift), key, Vector3.UP)

## a spot on the map as a point of the frame, `lift` over the ground there
func _on(w: Vector2, lift: float) -> Vector3:
	var f := to_frame(w)
	return Vector3(f.x, MapData.height(w) - level + lift, f.y)

## a rectangle (u, v) as an outline
func _rect(u0: float, u1: float, v0: float, v1: float) -> Array:
	return [Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1)]

# ---------------- floors ----------------
## the gravel over all of it inside the wall, the walk of cypresses and the way in tiled
func _floors() -> void:
	var t := WALL_T
	_lay([Vector2(t, t), Vector2(L_N - t, t), Vector2(L_N - t, L_W - t), Vector2(t, L_W - t)], 0.0, "grava")
	_lay(_rect(HALL_D, AVENUE[0], CROSS_WALK[0], CROSS_WALK[1]), 0.03, "losetas")
	_lay(_rect(AVENUE[1], L_N - t - 0.5, CROSS_WALK[0], CROSS_WALK[1]), 0.03, "losetas")
	_lay(_rect(HALL_D, 16.0, CROSS_WALK[1], HALL_N + MID + ARCH + 1.0), 0.03, "losetas")      # (from the way in, round to the walk)

# ---------------- the wall ----------------
## Its four sides, plain and whitewashed, a grey coping on top and a dirty foot; in pieces of a few metres, each standing
## on the ground where it is. The west side is broken by the gatehouse.
func _walls() -> void:
	var sides := [[Vector2(L_N, 0.0), Vector2(0.0, 0.0)],                       # north (walked east to west: its face looks out)
		[Vector2(0.0, 0.0), Vector2(0.0, HALL_N)], [Vector2(0.0, HALL_S), Vector2(0.0, L_W)],      # west, either side of the gatehouse
		[Vector2(0.0, L_W), Vector2(L_N, L_W)], [Vector2(L_N, L_W), Vector2(L_N, 0.0)]]           # south, east
	for s in sides:
		var a: Vector2 = s[0]
		var b: Vector2 = s[1]
		var n := int(ceil(Vector2(P(a.x, a.y)).distance_to(P(b.x, b.y)) / 7.0))
		for k in range(n):
			var qa: Vector2 = a.lerp(b, float(k) / n)
			var qb: Vector2 = a.lerp(b, float(k + 1) / n)
			_wall_piece(qa, qb)
	home()

func _wall_piece(qa: Vector2, qb: Vector2) -> void:
	var fa := P(qa.x, qa.y)
	var fb := P(qb.x, qb.y)
	var mid := (qa + qb) / 2.0
	var gy := g_uv(mid.x, mid.y)
	var ln := face(fa, fb, gy)
	box(-0.01, -0.4, -WALL_T, ln + 0.02, WALL_H + 0.4, WALL_T, "cal")
	box(-0.02, -0.4, 0.0, ln + 0.04, 0.62, 0.012, 0xb8b0a2)                  # (its dirty foot, outside)
	box(-0.02, WALL_H, -WALL_T - 0.05, ln + 0.04, 0.07, WALL_T + 0.1, 0xd9d4ca)
	var d := (fb - fa).normalized()
	var mf := (fa + fb) / 2.0 - Vector2(-d.y, d.x) * WALL_T / 2.0
	home()
	solid(Vector3(mf.x, gy + WALL_H / 2.0, mf.y), Vector3(ln, WALL_H + 0.8, WALL_T), atan2(-d.y, d.x))

# ---------------- the gatehouse ----------------
## Built on the frame of its front: x along it from its north end (v = HALL_N) south, z out of it to the road, y up from
## its floor. Its wings under hipped roofs, the raised front in the middle, the body standing out with its gable and
## cross, the shut arch north of it and the open one south of it, a passage through the building to the inside.
func _gatehouse() -> void:
	var fa := P(0.0, HALL_N)
	var fb := P(0.0, HALL_S)
	var L := face(fa, fb, 0.0)
	var keep := _xf
	var x_shut := MID - ARCH
	var x_pass := MID + ARCH
	var p0 := x_pass - PASS_W / 2.0
	var p1 := x_pass + PASS_W / 2.0
	# the wings and the raised front: solid, but for the passage and the shut arch's doorway, set back in the wall
	var s0 := x_shut - SHUT_R
	var s1 := x_shut + SHUT_R
	var s_top := SHUT_SPRING + SHUT_R
	box(0.0, -0.4, -HALL_D, s0, EAVE + 0.4, HALL_D, "cal")
	box(s1, -0.4, -HALL_D, p0 - s1, EAVE + 0.4, HALL_D, "cal")
	box(s0, s_top, -HALL_D, s1 - s0, EAVE - s_top, HALL_D, "cal")
	box(s0, -0.4, -HALL_D, s1 - s0, s_top + 0.4, HALL_D - SHUT_DEEP, "cal")
	box(p1, -0.4, -HALL_D, L - p1, EAVE + 0.4, HALL_D, "cal")
	box(p0, 2.6, -HALL_D, PASS_W, EAVE - 2.6, HALL_D, "cal")                 # (over the passage)
	box(p0, -0.02, -HALL_D, PASS_W, 0.04, HALL_D + 0.3, "losetas")            # (its floor)
	# the open arch is the passage's own shape: a round vault all the way through, and the same arch on the inside
	# (the user, 25 Nov 2026: «sale el hueco de entrada rectangular y luego clippeado un arco»)
	_vault(x_pass, 1.85, PASS_W / 2.0, -HALL_D, 0.0)
	ring(x_pass, 1.85, PASS_W / 2.0, PASS_W / 2.0 + 0.16, 0.04, 0.04, 0xdcd6cb)
	box(MID - PIN, EAVE, -HALL_D, PIN * 2.0, FRONT_TOP - EAVE, HALL_D, "cal")   # the raised front
	# the grey dado along its foot, but where the arches and the body are
	for run in [[0.0, x_shut - 0.85], [x_shut + 0.85, p0 - 0.1], [p1 + 0.1, L]]:
		box(run[0], -0.4, 0.0, run[1] - run[0], 0.85, 0.025, 0x9a9792)
	# the wings' roofs, hipped, and the raised front's, a gable running back
	_hip_x(0.0, MID - PIN, -HALL_D, 0.0, EAVE, RISE, 0.42)
	_hip_x(MID + PIN, L, -HALL_D, 0.0, EAVE, RISE, 0.42)
	var rr := APEX
	roof([Vector3(MID - PIN - 0.3, FRONT_TOP, -HALL_D - 0.4), Vector3(MID - PIN - 0.3, FRONT_TOP, -0.15), Vector3(MID, rr, -0.15), Vector3(MID, rr, -HALL_D - 0.4)], "tiles_viejas")
	roof([Vector3(MID + PIN + 0.3, FRONT_TOP, -HALL_D - 0.4), Vector3(MID + PIN + 0.3, FRONT_TOP, -0.15), Vector3(MID, rr, -0.15), Vector3(MID, rr, -HALL_D - 0.4)], "tiles_viejas")
	ridge(Vector3(MID, rr, -HALL_D - 0.4), Vector3(MID, rr, -0.15))
	_back_tri(Vector2(MID - PIN, FRONT_TOP), Vector2(MID + PIN, FRONT_TOP), Vector2(MID, rr), -HALL_D - 0.01, "cal")
	# the pinnacles at the raised front's ends: a pyramid on a little plinth, a ball on it
	for side in [-1.0, 1.0]:
		var at := Vector3(MID + side * (PIN - 0.25), FRONT_TOP, -0.25)
		cbox(at + Vector3(0, 0.15, 0), Vector3(0.5, 0.3, 0.5), "cal")
		drum(at + Vector3(0, 0.3, 0), 0.3, 0.0, 0.95, 0xcfc6b6, 4)
		ball(at + Vector3(0, 1.3, 0), 0.08, 0xcfc6b6, 1.0, 6, 4)
	_gable()
	_shut_arch(x_shut)
	# its windows: two in each wing, with grilles (the south wing's first with a frame of red-brown wood)
	for w in [[5.0, 0x1c1a18, 0x2a2622], [11.0, 0x1c1a18, 0x2a2622], [33.0, 0x7a3a24, 0x2a1d16], [38.5, 0x4a3022, 0x2a1d16]]:
		_window_on(Rect2(w[0] - 0.5, 1.0, 1.0, 1.15), w[1], w[2])
	# a bench of white stone against it, between the window and the open arch
	var bx := MID + WINDOW + 0.55
	box(bx, 0.0, 0.05, 1.75, 0.42, 0.45, 0xe6e2da)
	box(bx + 0.1, 0.0, 0.12, 0.25, 0.38, 0.3, 0xcfcac0)
	box(bx + 1.4, 0.0, 0.12, 0.25, 0.38, 0.3, 0xcfcac0)
	# the inside face: two doors of dark wood into its rooms
	for x in [6.0, L - 6.0]:
		box(x - 0.55, 0.0, -HALL_D - 0.03, 1.1, 2.1, 0.04, 0x4a3022)
	# its solids: the two wings either side of the passage, the body standing out
	_xf = keep
	_solid_xf(Vector3(p0 / 2.0, 1.6, -HALL_D / 2.0), Vector3(p0, 3.6, HALL_D))
	_solid_xf(Vector3((p1 + L) / 2.0, 1.6, -HALL_D / 2.0), Vector3(L - p1, 3.6, HALL_D))
	_solid_xf(Vector3(x_pass, 2.85, -HALL_D / 2.0), Vector3(PASS_W, 1.1, HALL_D))     # (the passage's ceiling: the game's camera stays under the vault, by you)
	home()

## A round vault over a passage through the wall being built: the half round of radius r on its spring line, from z0
## (the back) to z1 (the front), smooth (each corner with its own normal), and the two corners left of the square
## hole filled at both ends.
func _vault(cx: float, spring: float, r: float, z0: float, z1: float, n := 16) -> void:
	pieces += 1
	var st: SurfaceTool = _tool("cal")
	var o := Vector3(cx, spring, 0.0)
	for i in range(n):
		var c0 := Vector3(cos(PI * i / n), sin(PI * i / n), 0.0)
		var c1 := Vector3(cos(PI * (i + 1) / n), sin(PI * (i + 1) / n), 0.0)
		var q := [o + c0 * r + Vector3(0, 0, z0), o + c0 * r + Vector3(0, 0, z1), o + c1 * r + Vector3(0, 0, z1), o + c1 * r + Vector3(0, 0, z0)]
		var qn := [-c0, -c0, -c1, -c1]
		for t in [[0, 1, 2], [0, 2, 3]]:
			var a: Vector3 = _xf * (q[t[0]] as Vector3)
			var b: Vector3 = _xf * (q[t[1]] as Vector3)
			var c: Vector3 = _xf * (q[t[2]] as Vector3)
			var na: Vector3 = (_xf.basis * (qn[t[0]] as Vector3)).normalized()
			var nb: Vector3 = (_xf.basis * (qn[t[1]] as Vector3)).normalized()
			var nc: Vector3 = (_xf.basis * (qn[t[2]] as Vector3)).normalized()
			if (b - a).cross(c - a).dot(na + nb + nc) > 0.0:      # (clockwise front faces, as obra.gd's _tri)
				var sw := b; b = c; c = sw
				var sn := nb; nb = nc; nc = sn
			st.set_normal(na); st.add_vertex(a)
			st.set_normal(nb); st.add_vertex(b)
			st.set_normal(nc); st.add_vertex(c)
	spandrels(cx, spring, r, z1 + 0.003, "cal")
	for side in [-1.0, 1.0]:                                     # (the same at the back, facing in)
		var corner := Vector3(cx + side * r, spring + r, z0 - 0.003)
		for i in range(8):
			var a0 := PI / 2.0 * i / 8
			var a1 := PI / 2.0 * (i + 1) / 8
			tri(corner, Vector3(cx + side * r * cos(a0), spring + r * sin(a0), z0 - 0.003), Vector3(cx + side * r * cos(a1), spring + r * sin(a1), z0 - 0.003), "cal", Vector3(0, 0, -1))

## a triangle on the plane z facing back (-z): the gable ends that look into the cemetery
func _back_tri(a: Vector2, b: Vector2, c: Vector2, z: float, key) -> void:
	tri(Vector3(a.x, a.y, z), Vector3(b.x, b.y, z), Vector3(c.x, c.y, z), key, Vector3(0, 0, -1))

## a solid given in the frame being built (the gatehouse's front)
func _solid_xf(mid: Vector3, size: Vector3) -> void:
	var m := _xf * mid
	var xd := _xf.basis.x
	solid(m, size, atan2(-xd.z, xd.x))

## A hipped roof whose ridge runs along x (obra.gd's _hip runs along z): eaves `out` beyond x0..x1, z0..z1 at y.
func _hip_x(x0: float, x1: float, z0: float, z1: float, y: float, rise: float, out := 0.45) -> void:
	var a := Vector3(x0 - out, y, z1 + out)
	var b := Vector3(x1 + out, y, z1 + out)
	var c := Vector3(x1 + out, y, z0 - out)
	var d := Vector3(x0 - out, y, z0 - out)
	var half := (z1 - z0) / 2.0 + out
	var mz := (z0 + z1) / 2.0
	var t0 := Vector3(x0 - out + half, y + rise, mz)
	var t1 := Vector3(x1 + out - half, y + rise, mz)
	roof([a, b, t1, t0], "tiles_viejas")
	roof([c, d, t0, t1], "tiles_viejas")
	roof([d, a, t0], "tiles_viejas")
	roof([b, c, t1], "tiles_viejas")
	for q in [[a, t0], [d, t0], [b, t1], [c, t1], [t0, t1]]:
		ridge(q[0], q[1])
	box(x0 - out, y - 0.12, z1, x1 - x0 + out * 2.0, 0.12, out, 0xe8e4dc)     # (the white eaves' edge under the tiles)

## the broad low gable of the raised front, from pinnacle to pinnacle, its white raking edges; on it a little roof of
## tiles coming out of the wall, three-sided like half a pyramid; the narrow arched window south of the middle; the
## finial of brick and the iron cross on top (Street View 2024)
func _gable() -> void:
	var x0 := MID - PIN
	var x1 := MID + PIN
	slab(PackedVector2Array([Vector2(x0, FRONT_TOP), Vector2(x1, FRONT_TOP), Vector2(MID, APEX)]), 0.02, 0.32, "cal")
	for side in [-1.0, 1.0]:
		bar(Vector3(MID + side * (PIN + 0.06), FRONT_TOP - 0.04, 0.06), Vector3(MID, APEX + 0.07, 0.06), 0.18, 0.12, 0xe8e4dc)
	var hy := 3.7                                                # the little roof: its foot, its top against the wall, its half-width
	var ht := FRONT_TOP + 0.02
	var hw := 2.1
	var tip := Vector3(MID, ht, 0.03)
	roof([Vector3(MID - hw, hy, HOOD_OUT), Vector3(MID + hw, hy, HOOD_OUT), tip], "tiles_viejas")
	roof([Vector3(MID - hw, hy, 0.03), Vector3(MID - hw, hy, HOOD_OUT), tip], "tiles_viejas")
	roof([Vector3(MID + hw, hy, HOOD_OUT), Vector3(MID + hw, hy, 0.03), tip], "tiles_viejas")
	for q in [[Vector3(MID - hw, hy, HOOD_OUT), tip], [Vector3(MID + hw, hy, HOOD_OUT), tip]]:
		ridge(q[0], q[1])
	box(MID - hw - 0.05, hy - 0.12, 0.0, hw * 2.0 + 0.1, 0.12, HOOD_OUT + 0.05, 0xe8e4dc)      # (its white eaves' edge)
	arched(MID + WINDOW, 0.75, 2.14, 0.13, 0.004, 0x1f2226)     # the narrow window
	drum(Vector3(MID, APEX - 0.05, -0.1), 0.2, 0.12, 0.25, 0xb8784e, 8)      # the finial, of brick, and the cross
	ball(Vector3(MID, APEX + 0.28, -0.1), 0.13, 0xb8784e, 1.0, 8, 5)
	cbox(Vector3(MID, APEX + 1.0, -0.1), Vector3(0.06, 1.3, 0.06), IRON)
	cbox(Vector3(MID, APEX + 1.27, -0.1), Vector3(0.62, 0.06, 0.06), IRON)

## the north arch: shut with an iron gate, its dark doorway set back in the wall under a round head (a real hole, as
## the open one: the user, 25 Nov 2026, «Un pequeño ajuste a los arcos»)
func _shut_arch(x: float) -> void:
	var r := SHUT_R
	var spring := SHUT_SPRING
	arched(x, 0.0, spring, r, -SHUT_DEEP + 0.004, 0x23201d)
	_vault(x, spring, r, -SHUT_DEEP, 0.0)
	box(x - r, -0.4, -SHUT_DEEP, 2.0 * r, 0.4, SHUT_DEEP, 0xcfc6b6)             # (its sill)
	ring(x, spring, r, r + 0.16, 0.035, 0.035, 0xdcd6cb)
	var n := 11
	for i in range(n + 1):                                       # its bars, each up to the round of the arch
		var dx := -r + 0.06 + (2.0 * r - 0.12) * i / n
		var top := spring + sqrt(maxf(r * r - dx * dx, 0.0)) - 0.05
		box(x + dx - 0.012, 0.0, 0.03, 0.024, top, 0.024, IRON)
	for y in [0.15, 1.0, 1.7]:
		box(x - r + 0.04, y, 0.025, 2.0 * r - 0.08, 0.04, 0.03, IRON)
	box(x - r - 0.1, -0.05, 0.0, 2.0 * r + 0.2, 0.08, 0.3, 0xcfc6b6)          # (its step)

## a window on a wall that is solid behind it: dark glass a touch proud, its frame, an iron grille
func _window_on(r: Rect2, frame: int, glass: int) -> void:
	box(r.position.x, r.position.y, 0.0, r.size.x, r.size.y, 0.02, glass)
	for q in [[r.position.x - 0.06, r.position.y - 0.06, 0.06, r.size.y + 0.12], [r.end.x, r.position.y - 0.06, 0.06, r.size.y + 0.12],
			[r.position.x - 0.06, r.position.y - 0.06, r.size.x + 0.12, 0.06], [r.position.x - 0.06, r.end.y, r.size.x + 0.12, 0.06]]:
		box(q[0], q[1], 0.0, q[2], q[3], 0.04, frame)
	box(r.position.x - 0.1, r.position.y - 0.12, 0.0, r.size.x + 0.2, 0.06, 0.12, 0xd9d4ca)      # (its sill)
	grille(r, 0.13)

## a low store behind the wall, north of the gatehouse: flat-roofed, whitewashed
func _annex() -> void:
	var fa := P(WALL_T, ANNEX)
	var fb := P(WALL_T, HALL_N)
	var L := face(fa, fb, g_uv(5.0, (ANNEX + HALL_N) / 2.0))
	box(0.0, -0.3, -9.0, L, 3.0, 9.0, "cal")
	box(-0.05, 2.7, -9.05, L + 0.1, 0.12, 9.1, 0xa9a49b)
	box(L * 0.5 - 0.5, 0.0, -9.03, 1.0, 2.0, 0.04, 0x5a6066)                    # (its door, inside, of grey sheet)
	var keep := _xf
	_solid_xf(Vector3(L / 2.0, 1.4, -4.5), Vector3(L, 3.0, 9.0))
	_xf = keep
	home()

# ---------------- before it ----------------
## the pavers of the square, round the island; a pavement of light tiles along the road south of it; a cabinet of the
## electricity against the wall
func _square() -> void:
	_lay(_rect(PAVE_U, -0.05, PAVE_V0, PAVE_V1), 0.03, "adoquin")             # (the island's soil lies over them)
	_lay(_rect(PAVE_U, PAVE_U + 3.0, PAVE_V1, L_W - 2.0), 0.05, "acera")
	_kerb_run(Vector2(PAVE_U + 3.0, PAVE_V1), Vector2(PAVE_U + 3.0, L_W - 2.0), 0.12)
	# the cabinet
	var at := P(-0.25, HALL_S + 1.6)
	var gy := g_uv(-0.25, HALL_S + 1.6)
	face(P(0.0, HALL_S + 0.9), P(0.0, HALL_S + 2.3), gy)
	box(0.0, 0.0, 0.0, 1.4, 1.35, 0.42, 0xe7e5df)
	box(0.69, 0.05, 0.42, 0.02, 1.25, 0.01, 0x9a9a96)
	home()
	solid(Vector3(at.x, gy + 0.7, at.y), Vector3(0.5, 1.4, 1.4))

## the outline of the island (u, v), `grow` metres bigger all round: straight along the road, round on the other side
func _isle_outline(grow: float) -> Array:
	var out: Array = []
	var mid := (ISLE_V0 + ISLE_V1) / 2.0
	var rv := (ISLE_V1 - ISLE_V0) / 2.0 + grow
	var base := ISLE_U - grow
	var ru := ISLE_OUT + grow * 2.0
	out.append(Vector2(base, mid + rv))
	out.append(Vector2(base, mid - rv))
	for i in range(1, 16):
		var a := -PI / 2.0 + PI * i / 16.0
		out.append(Vector2(base + cos(a) * ru, mid + sin(a) * rv))
	return out

## a kerb painted red and white in lengths of a metre, from a to b (u, v), `tall` over the ground
func _kerb_run(a: Vector2, b: Vector2, tall: float) -> void:
	var n := int(ceil(a.distance_to(b)))
	for k in range(n):
		var qa := a.lerp(b, float(k) / n)
		var qb := a.lerp(b, float(k + 1) / n)
		var fa := P(qa.x, qa.y)
		var fb := P(qb.x, qb.y)
		var m := (qa + qb) / 2.0
		var ln := face(fa, fb, g_uv(m.x, m.y))
		box(0.0, -0.1, -0.1, ln, tall + 0.1, 0.2, 0xb8382e if k % 2 == 0 else 0xf2efe8)
	home()

## The island: its kerb, its soil, junipers spread low and shrubs; its cypresses and its bare tree are planted with the
## rest (_trees). A no-entry sign at its north end, for who would come in that way.
func _island() -> void:
	var ring_pts := _isle_outline(0.0)
	for i in range(ring_pts.size()):
		var a: Vector2 = ring_pts[i]
		var b: Vector2 = ring_pts[(i + 1) % ring_pts.size()]
		_kerb_seg(a, b, i)
	_lay(_isle_outline(-0.2), 0.13, "tierra_isleta")
	var rng := RandomNumberGenerator.new()
	rng.seed = 4571
	var mid := (ISLE_V0 + ISLE_V1) / 2.0
	for k in range(26):                                          # junipers and shrubs, more along its front
		var a := rng.randf_range(-PI / 2.0, PI / 2.0)
		var f := sqrt(rng.randf()) * 0.85
		var q := Vector2(ISLE_U + 0.9 + cos(a) * (ISLE_OUT - 1.4) * f, mid + sin(a) * ((ISLE_V1 - ISLE_V0) / 2.0 - 1.2) * f)
		var c := P(q.x, q.y)
		var gy := g_uv(q.x, q.y) + 0.12
		var r := rng.randf_range(0.45, 0.95)
		ball(Vector3(c.x, gy + r * 0.25, c.y), r, ["enebro", "enebro", "seto", "rojizo"][k % 4], 0.45 if k % 4 < 2 else 0.75, 9, 5)
	# its solid, in slices along it as wide as it is there: you do not drive over it
	var rv := (ISLE_V1 - ISLE_V0) / 2.0
	for k in range(7):
		var va := ISLE_V0 + (ISLE_V1 - ISLE_V0) * k / 7.0
		var vb := ISLE_V0 + (ISLE_V1 - ISLE_V0) * (k + 1) / 7.0
		var t := maxf(absf(va - mid), absf(vb - mid)) / rv
		var reach := ISLE_OUT * sqrt(maxf(1.0 - t * t, 0.0)) + 0.1
		reach = maxf(reach, 1.0)
		var c0 := P(ISLE_U + reach / 2.0, (va + vb) / 2.0)
		solid(Vector3(c0.x, g_uv(ISLE_U, mid) + 0.25, c0.y), Vector3(reach + 0.2, 0.5, vb - va))
	# the no-entry sign
	var s := P(ISLE_U + 0.6, ISLE_V0 + 1.2)
	var sy := g_uv(ISLE_U + 0.6, ISLE_V0 + 1.2)
	drum(Vector3(s.x, sy, s.y), 0.04, 0.04, 2.3, 0x9a9da0, 6)
	var sign := Node3D.new()
	add_child(sign)
	sign.transform = Transform3D(Basis(Vector3.UP, -PI / 2.0), Vector3(s.x, sy + 2.0, s.y))      # (its face west, to the road)
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.3
	cm.bottom_radius = 0.3
	cm.height = 0.03
	cm.radial_segments = 20
	disc.mesh = cm
	disc.rotation.x = PI / 2.0
	disc.material_override = Parts.mat(0xd0231f)
	sign.add_child(disc)
	var bar_mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.42, 0.1, 0.035)
	bar_mi.mesh = bm
	bar_mi.material_override = Parts.mat(0xf4f4f2)
	sign.add_child(bar_mi)
	solid(Vector3(s.x, sy + 1.0, s.y), Vector3(0.12, 2.0, 0.12))

func _kerb_seg(a: Vector2, b: Vector2, k: int) -> void:
	var fa := P(a.x, a.y)
	var fb := P(b.x, b.y)
	var m := (a + b) / 2.0
	var ln := face(fb, fa, g_uv(m.x, m.y))
	var n := maxi(1, int(round(ln)))
	for i in range(n):
		box(ln * i / n, -0.1, -0.1, ln / n + 0.01, 0.25, 0.22, 0xb8382e if (k + i) % 2 == 0 else 0xf2efe8)
	home()

# ---------------- the graves ----------------
## Every plot, but the gatehouse's yard and the broad walk's pantheons; the last column, by the east wall, half empty.
func _graves() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1906
	for name in ["base", "top", "stone", "book", "cross_v", "cross_h", "vase", "flower", "candle", "wax", "rip", "dep"]:
		_mm[name] = [[], [], [], []]
	for ci in range(COLS.size()):
		for ri in range(ROWS.size()):
			var u0: float = COLS[ci][0]
			var u1: float = COLS[ci][1]
			var v0: float = ROWS[ri][0]
			var v1: float = ROWS[ri][1]
			if ci == 0 and ri == 2:
				v1 = ANNEX - 1.5                                  # (the gatehouse's yard begins there)
			elif ci == 0 and (ri == 3 or ri == 4):
				continue
			if ci == 4 and ri >= 2 and ri <= 5:
				continue                                          # (the broad walk)
			_plot(u0, u1, v0, v1, 0.55 if ci == 7 else 0.96, rng)

## a plot of graves from u0 to u1, v0 to v1: as many pairs of rows as fit, each grave in it or not (fill)
func _plot(u0: float, u1: float, v0: float, v1: float, fill: float, rng: RandomNumberGenerator) -> void:
	var n_pairs := int(floor((v1 - v0 + AISLE) / (PAIR + AISLE)))
	var n_u := int(floor((u1 - u0 + PITCH - G_W) / PITCH))
	if n_pairs < 1 or n_u < 1:
		return
	plots.append([u0, u1, v0, v1])
	var used_v := n_pairs * (PAIR + AISLE) - AISLE
	var vs := v0 + (v1 - v0 - used_v) / 2.0
	var used_u := (n_u - 1) * PITCH + G_W
	var us := u0 + (u1 - u0 - used_u) / 2.0
	var quarter := (1 if (u0 + u1) / 2.0 > L_N / 2.0 else 0) + (2 if (v0 + v1) / 2.0 > L_W / 2.0 else 0)
	for k in range(n_pairs):
		var va := vs + k * (PAIR + AISLE)
		for i in range(n_u):
			var uc := us + i * PITCH + G_W / 2.0
			var edge := -1 if i == 0 else (1 if i == n_u - 1 else 0)      # (the first and last of a row: the walk beside them)
			for side in [0, 1]:
				if rng.randf() > fill:
					continue
				var vfoot: float = va if side == 0 else va + PAIR
				var vhead: float = va + G_L if side == 0 else va + PAIR - G_L
				_grave(uc, vfoot, vhead, rng, quarter, edge)
		pair_rows.append([us, us + used_u, va, va + PAIR])
		var c := P(us + used_u / 2.0, va + PAIR / 2.0)
		solid(Vector3(c.x, g_uv(us + used_u / 2.0, va + PAIR / 2.0) + 0.3, c.y), Vector3(used_u, 0.9, PAIR))

## the stone a grave is of: white marble mostly, then grey and black granite, some cream
func _tone(rng: RandomNumberGenerator) -> Color:
	var r := rng.randf()
	var c: Color
	if r < 0.5:
		c = Color(0.93, 0.92, 0.89)
	elif r < 0.62:
		c = Color(0.86, 0.82, 0.74)
	elif r < 0.77:
		c = Color(0.68, 0.68, 0.67)
	elif r < 0.9:
		c = Color(0.36, 0.36, 0.38)
	else:
		c = Color(0.13, 0.13, 0.14)
	var k := rng.randf_range(0.95, 1.03)
	return Color(c.r * k, c.g * k, c.b * k)

## One grave, from its foot (v) to its head: a kerb of stone with a slab on it (or gravel in it), and at its head an
## upright stone, or a book of stone, or a cross; flowers in a vase on some. No name and no date on any: on half of
## them, «R.I.P.» or «D.E.P.» and no more.
func _grave(uc: float, vfoot: float, vhead: float, rng: RandomNumberGenerator, q: int, edge := 0) -> void:
	graves += 1
	var vm := (vfoot + vhead) / 2.0
	var c := P(uc, vm)
	var g := g_uv(uc, vm)
	var dir := signf(vhead - vfoot)                              # (+1: its head to the south)
	var tone := _tone(rng)
	var bh := rng.randf_range(0.22, 0.42)
	var w := G_W * rng.randf_range(0.9, 1.0)
	_put("base", q, Basis.from_scale(Vector3(w, bh + 0.1, G_L)), Vector3(c.x, g + bh / 2.0 - 0.05, c.y), tone)
	var r := rng.randf()
	var top: Color = tone if r < 0.5 else (_tone(rng) if r < 0.8 else Color(0.84, 0.81, 0.74))
	_put("top", q, Basis.from_scale(Vector3(w - 0.14, 0.05, G_L - 0.18)), Vector3(c.x, g + bh + 0.02, c.y), top)
	var head := P(uc, vhead - dir * 0.14)
	var stone_h := 0.0                                           # (its upright stone, if it has one: for the words cut in it)
	var stone_tone := tone
	var r2 := rng.randf()
	if r2 < 0.62:                                                # an upright stone
		var sh := rng.randf_range(0.45, 1.0)
		var st: Color = tone if rng.randf() < 0.6 else _tone(rng)
		_put("stone", q, Basis.from_scale(Vector3(w - 0.08, sh, 0.1)), Vector3(head.x, g + bh + sh / 2.0, head.y), st)
		stone_h = sh
		stone_tone = st
		if rng.randf() < 0.3:                                    # a small cross on it
			var ty := g + bh + sh
			var iron := Color(0.12, 0.12, 0.13) if rng.randf() < 0.5 else st
			_put("cross_v", q, Basis.from_scale(Vector3(0.05, 0.36, 0.05)), Vector3(head.x, ty + 0.18, head.y), iron)
			_put("cross_h", q, Basis.from_scale(Vector3(0.24, 0.05, 0.05)), Vector3(head.x, ty + 0.24, head.y), iron)
	elif r2 < 0.78:                                              # a book of stone, open, leaning back
		var bk := P(uc, vhead - dir * 0.5)
		var tilt := Basis(Vector3.RIGHT, deg_to_rad(-55.0) * dir)
		_put("book", q, tilt * Basis.from_scale(Vector3(0.62, 0.46, 0.06)), Vector3(bk.x, g + bh + 0.2, bk.y), _tone(rng))
	else:                                                        # a cross, of iron or of stone
		var tall := rng.randf_range(0.7, 1.15)
		var cc := Color(0.12, 0.12, 0.13) if rng.randf() < 0.45 else tone
		_put("cross_v", q, Basis.from_scale(Vector3(0.07, tall, 0.07)), Vector3(head.x, g + bh + tall / 2.0, head.y), cc)
		_put("cross_h", q, Basis.from_scale(Vector3(tall * 0.5, 0.07, 0.07)), Vector3(head.x, g + bh + tall * 0.72, head.y), cc)
	if rng.randf() < 0.42:                                       # flowers, mostly of cloth: red, white, yellow, pink, purple
		var side := 1.0 if rng.randf() < 0.5 else -1.0
		var vp := P(uc + side * (w / 2.0 - 0.16), vhead - dir * 0.42)
		_put("vase", q, Basis.from_scale(Vector3(0.14, 0.24, 0.14)), Vector3(vp.x, g + bh + 0.12, vp.y), Color(0.55, 0.55, 0.56) if rng.randf() < 0.6 else tone)
		var fl: Color = [Color(0.8, 0.12, 0.14), Color(0.95, 0.94, 0.9), Color(0.95, 0.8, 0.2), Color(0.92, 0.5, 0.62), Color(0.55, 0.3, 0.7), Color(0.95, 0.45, 0.15)][rng.randi() % 6]
		_put("flower", q, Basis.from_scale(Vector3(0.3, 0.24, 0.3)), Vector3(vp.x, g + bh + 0.34, vp.y), fl)
		if q == 3 and edge != 0 and int(side) == edge:
			_vases.append([vp, g + bh + 0.24, q, (_mm["flower"][q] as Array).size() - 1])
	# The candles (the user, 25 Nov 2026, of the «lamparillas» proposed: «cambiaría lamparillas por velas, que son las
	# que se suelen poner», with two pictures: tall tubes of red plastic, the white wax at their mouth): one to three at
	# the foot of one grave in seven, some whole and some burnt lower. Lit at night (_candle_glow). Which graves, by
	# where each lies and not by rng: all else on the graves stays as it was
	var hk: int = hash(Vector2i(int(round(uc * 10.0)), int(round(vfoot * 10.0))))
	if posmod(hk, 7) == 0:
		var c_side := 1.0 if posmod(hk >> 4, 2) == 0 else -1.0
		var foot := g + bh + 0.045
		for k in range(1 + posmod(hk >> 6, 3)):
			var ch := 0.24 if posmod(hk >> (9 + 2 * k), 3) != 0 else 0.16
			var cp := P(uc + c_side * (w / 2.0 - 0.2 - 0.05 * (k % 2)), vfoot + dir * (0.3 + 0.11 * k))
			_put("candle", q, Basis.from_scale(Vector3(0.085, ch, 0.085)), Vector3(cp.x, foot + ch / 2.0, cp.y), Color(0.8, 0.07, 0.08))
			_put("wax", q, Basis.from_scale(Vector3(0.064, 0.012, 0.064)), Vector3(cp.x, foot + ch + 0.003, cp.y), Color(0.95, 0.93, 0.88))
			_candle_at.append(Vector3(cp.x, foot + ch * 0.72, cp.y))
		candles += 1
	# The words (the user, 25 Nov 2026: «Poner R.I.P y D.E.P grabado en algunas lápidas (50% de todas ellas)»): on one
	# grave in two, the one or the other, cut in its upright stone if it has one and if not in its slab, to be read
	# from its foot; dark on pale stone, gilt on dark. Still no name and no date on any. Which graves, by where each
	# lies (as the candles): the rest of every grave stays as it was
	if posmod(hk >> 13, 2) == 0:
		var word := "rip" if posmod(hk >> 15, 2) == 0 else "dep"
		var on: Color = stone_tone if stone_h > 0.0 else top
		var ink := Color(0.15, 0.15, 0.16) if on.get_luminance() > 0.45 else Color(0.8, 0.6, 0.16)
		var xa := Vector3(-dir * WORD_W, 0.0, 0.0)                  # (its letters run to the right of who reads it from the foot)
		if stone_h > 0.0:
			_put(word, q, Basis(xa, Vector3(0.0, WORD_H, 0.0), Vector3(0.0, 0.0, -dir)), Vector3(head.x, g + bh + stone_h * 0.68, head.y - dir * 0.056), ink)
			words_upright += 1
		else:
			var wp := P(uc, vhead - dir * 1.02)
			_put(word, q, Basis(xa, Vector3(0.0, 0.0, dir * WORD_H), Vector3(0.0, 1.0, 0.0)), Vector3(wp.x, g + bh + 0.051, wp.y), ink)
		words += 1
		if word == "rip":
			words_rip += 1

func _put(kind: String, q: int, b: Basis, at: Vector3, col: Color) -> void:
	(_mm[kind][q] as Array).append([Transform3D(b, at), col])

## the graves drawn: for each kind of piece, one MultiMesh in each quarter of the cemetery (so a quarter out of sight is
## not drawn), not drawn past VISIBLE metres; the small pieces cast no shadow
const VISIBLE := 240.0
const WORD_W := 0.62                       # the words' picture on a stone: this wide (the letters, 9 cm tall)...
const WORD_H := 0.62 * 72.0 / 256.0        # ...and as tall as the picture is (tools/cementerio/lapidas.py)
const WORD_SEEN := 70.0                    # ...drawn to this far
func _grave_meshes() -> void:
	var word_mesh := QuadMesh.new()
	word_mesh.size = Vector2.ONE
	var word_mats := {}
	for wk in ["rip", "dep"]:
		var tex: Texture2D = Parts.texture("res://assets/cementerio/lapida_%s.png" % wk)
		if tex == null:                                          # (not there: no words, rather than blank patches)
			_mm[wk] = [[], [], [], []]
			continue
		var wm := StandardMaterial3D.new()
		wm.albedo_texture = tex
		wm.vertex_color_use_as_albedo = true
		wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		wm.alpha_scissor_threshold = 0.4
		wm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		wm.roughness = 0.55
		word_mats[wk] = wm
	var box_mesh := BoxMesh.new()
	var vase_mesh := CylinderMesh.new()
	vase_mesh.top_radius = 0.5
	vase_mesh.bottom_radius = 0.36
	vase_mesh.height = 1.0
	vase_mesh.radial_segments = 8
	vase_mesh.rings = 1
	var flower_mesh := SphereMesh.new()
	flower_mesh.radius = 0.5
	flower_mesh.height = 1.0
	flower_mesh.radial_segments = 7
	flower_mesh.rings = 3
	var candle_mesh := CylinderMesh.new()
	candle_mesh.top_radius = 0.5
	candle_mesh.bottom_radius = 0.5
	candle_mesh.height = 1.0
	candle_mesh.radial_segments = 8
	candle_mesh.rings = 1
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.82
	for kind in _mm:
		for q in range(4):
			var list: Array = _mm[kind][q]
			if list.is_empty():
				continue
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_colors = true
			mm.mesh = vase_mesh if kind == "vase" else (flower_mesh if kind == "flower" else (candle_mesh if kind in ["candle", "wax"] else (word_mesh if word_mats.has(kind) else box_mesh)))
			mm.instance_count = list.size()
			for i in range(list.size()):
				mm.set_instance_transform(i, list[i][0])
				mm.set_instance_color(i, list[i][1])
			var mi := MultiMeshInstance3D.new()
			mi.name = "tumbas_%s_%d" % [kind, q]
			mi.multimesh = mm
			if word_mats.has(kind):                              # (how each word stands or lies, kept by the script: with no window the engine gives no instance back, and the self-test asks)
				var stood: Array = []
				for i in range(list.size()):
					stood.append(list[i][0])
				mi.set_meta("xf", stood)
			mi.material_override = word_mats[kind] if word_mats.has(kind) else mat
			mi.visibility_range_end = WORD_SEEN if word_mats.has(kind) else VISIBLE
			mi.visibility_range_end_margin = 20.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			if not (kind in ["base", "stone", "book"]):
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(mi)
	_mm.clear()

## The candles by night (the user, 25 Nov 2026, of the things proposed after the review: «Haz las 8»; and «velas», not
## lamps): each red tube aglow with the flame in it, flickering, each to its own beat. No light of the game's: a dot drawn over it, that adds its
## colour, always facing you; far off it keeps its size on the screen (to CANDLE_FAR times), so from the road the
## cemetery is dotted with them. Not drawn by day (tick).
const CANDLE_FAR := 6.0
const CANDLE_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform float night = 0.0;
uniform float far_grow = 6.0;
varying float flick;
varying float grown;
void vertex() {
	vec3 o = MODEL_MATRIX[3].xyz;
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	float dist = distance(o, cam);
	grown = clamp(dist / 22.0, 1.0, far_grow);
	float ph = float(INSTANCE_ID) * 2.399;
	flick = 0.8 + 0.13 * sin(TIME * (4.0 + mod(ph, 3.0)) + ph) + 0.07 * sin(TIME * 13.7 + ph * 1.7);
	vec3 w = o + normalize(cam - o) * 0.14 + (INV_VIEW_MATRIX[0].xyz * VERTEX.x + INV_VIEW_MATRIX[1].xyz * VERTEX.y) * grown;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(w, 1.0);
}
void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float core = 1.0 - smoothstep(0.02, 0.24, r);
	float halo = pow(max(0.0, 1.0 - r * grown), 2.2);            // (its soft glow stays as wide as it is: only its dot grows)
	vec3 col = mix(vec3(0.95, 0.12, 0.05), vec3(1.0, 0.5, 0.22), core) * core + vec3(0.9, 0.08, 0.04) * halo * 0.4;
	ALBEDO = col * night * flick;
}
"""
func _candle_glow() -> void:
	if _candle_at.is_empty():
		return
	var quad := QuadMesh.new()
	quad.size = Vector2(0.5, 0.5)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = quad
	mm.instance_count = _candle_at.size()
	for i in range(_candle_at.size()):
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, _candle_at[i]))
	_glow_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = CANDLE_SHADER
	_glow_mat.shader = sh
	_glow_mat.set_shader_parameter("far_grow", CANDLE_FAR)
	_glow_mi = MultiMeshInstance3D.new()
	_glow_mi.name = "velas"
	_glow_mi.multimesh = mm
	_glow_mi.material_override = _glow_mat
	_glow_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_glow_mi.extra_cull_margin = 4.0
	_glow_mi.visible = false
	add_child(_glow_mi)

## The whitewash on the trunks of the row of trees across the road (the user, 25 Nov 2026, of the things proposed:
## «Haz las 8»; Street View 2024: every trunk of the row limed to a little over a metre): a white sleeve round each
## trunk the world draws (0.56 across: world.gd's trunks are parts.gd's "cyl", a metre in radius, by 0.28). `first`:
## where this place's trees begin in the world's tree_info.
func _whitewash(first: int) -> void:
	for i in range(trees_put.size()):
		var t: Array = trees_put[i]
		if int(t[2]) != 0:                                        # (the row's are the only round-crowned ones planted here)
			continue
		var w := Vector2(float(t[0]), float(t[1]))
		var f := to_frame(w)
		_white.append([first + i, Transform3D(Basis.from_scale(Vector3(0.61, 1.35, 0.61)), Vector3(f.x, MapData.height(w) - level + 1.35 / 2.0 - 0.25, f.y)), true])
	if _white.is_empty():
		return
	var sleeve := CylinderMesh.new()
	sleeve.top_radius = 0.5
	sleeve.bottom_radius = 0.5
	sleeve.height = 1.0
	sleeve.radial_segments = 10
	sleeve.rings = 1
	_white_mm = MultiMesh.new()
	_white_mm.transform_format = MultiMesh.TRANSFORM_3D
	_white_mm.mesh = sleeve
	_white_mm.instance_count = _white.size()
	for k in range(_white.size()):
		_white_mm.set_instance_transform(k, _white[k][1])
	var lime := StandardMaterial3D.new()
	lime.albedo_color = Color(0.9, 0.89, 0.85)
	lime.roughness = 0.95
	var mi := MultiMeshInstance3D.new()
	mi.name = "troncos_encalados"
	mi.multimesh = _white_mm
	mi.material_override = lime
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	whitewashed = _white.size()

# ---------------- the pantheons ----------------
func _pantheons() -> void:
	for p in PANTHEONS:
		var u0: float = p[0]
		var u1: float = p[1]
		var v0: float = p[2]
		var v1: float = p[3]
		var east: bool = (u0 + u1) / 2.0 < (AVENUE[0] + AVENUE[1]) / 2.0      # (its front looks to the walk's middle)
		match String(p[4]):
			"capilla":
				_capilla(u0, u1, v0, v1, east)
			"recinto":
				_recinto(u0, u1, v0, v1, east)
			_:
				_losa(u0, u1, v0, v1, east)

## the frame of a pantheon: its front on the side that looks to the walk, x along that front, z out of it, y from the
## ground at its middle; returns [width along the front, depth]
func _pan_frame(u0: float, u1: float, v0: float, v1: float, east: bool) -> Vector2:
	var gy := g_uv((u0 + u1) / 2.0, (v0 + v1) / 2.0)
	if east:                                                     # (its front is its east side: from its north end to its south end, seen from the east)
		face(P(u1, v1), P(u1, v0), gy)
	else:
		face(P(u0, v0), P(u0, v1), gy)
	return Vector2(v1 - v0, u1 - u0)

## a small chapel of a family: walls of grey granite on a plinth, a gable to the walk with a cross on it, a door of
## iron and glass up two steps, roof slabs of stone
func _capilla(u0: float, u1: float, v0: float, v1: float, east: bool) -> void:
	var s := _pan_frame(u0, u1, v0, v1, east)
	var w := s.x - 0.4
	var d := s.y - 0.4
	var x0 := 0.2
	var z0 := -0.2 - d
	var wall: int = [GRANITE, MARBLE, 0xb7b0a4][int(u0 + v0) % 3]
	box(x0 - 0.15, -0.3, z0 - 0.15, w + 0.3, 0.6, d + 0.3, 0x6f6d6a)      # plinth
	box(x0, 0.3, z0, w, 2.5, d, wall)
	box(x0 - 0.1, 2.8, z0 - 0.1, w + 0.2, 0.16, d + 0.2, 0xd8d2c6)          # cornice
	var top := 2.96
	var apex := top + w * 0.32
	slab(PackedVector2Array([Vector2(x0, top), Vector2(x0 + w, top), Vector2(x0 + w / 2.0, apex)]), -0.2, 0.0, wall)
	_back_tri(Vector2(x0, top), Vector2(x0 + w, top), Vector2(x0 + w / 2.0, apex), z0 - 0.001, wall)
	for side in [0.0, 1.0]:
		var xe: float = x0 - 0.15 + side * (w + 0.3)
		roof([Vector3(xe, top, 0.05), Vector3(xe, top, z0 - 0.25), Vector3(x0 + w / 2.0, apex + 0.05, z0 - 0.25), Vector3(x0 + w / 2.0, apex + 0.05, 0.05)], 0x7a7874)
	var cx := x0 + w / 2.0
	cbox(Vector3(cx, apex + 0.45, -0.25), Vector3(0.1, 0.8, 0.1), 0xd8d2c6)
	cbox(Vector3(cx, apex + 0.58, -0.25), Vector3(0.48, 0.1, 0.1), 0xd8d2c6)
	box(cx - 0.5, 0.3, -0.19, 1.0, 2.0, 0.03, 0x22262a)                      # its door: iron, and glass behind bars
	for k in range(5):
		box(cx - 0.4 + k * 0.2 - 0.015, 0.4, -0.16, 0.03, 1.8, 0.02, 0x45494d)
	box(cx - 0.7, 0.3, -0.2, 0.2, 2.15, 0.05, 0xd8d2c6)
	box(cx + 0.5, 0.3, -0.2, 0.2, 2.15, 0.05, 0xd8d2c6)
	box(cx - 0.7, 2.3, -0.2, 1.4, 0.18, 0.06, 0xd8d2c6)
	box(cx - 0.8, -0.3, -0.2, 1.6, 0.45, 0.5, 0x8c8a86)                     # its steps
	box(cx - 0.8, -0.3, 0.3, 1.6, 0.25, 0.35, 0x8c8a86)
	var keep := _xf
	_solid_xf(Vector3(x0 + w / 2.0, 1.6, z0 + d / 2.0), Vector3(w + 0.3, 3.4, d + 0.3))
	_xf = keep
	home()

## a family's plot behind a kerb and an iron railing: a broad tomb of granite in it, a tall stone and a cross
func _recinto(u0: float, u1: float, v0: float, v1: float, east: bool) -> void:
	var s := _pan_frame(u0, u1, v0, v1, east)
	var w := s.x - 0.3
	var d := s.y - 0.3
	var x0 := 0.15
	var z0 := -0.15 - d
	for e in [[x0, z0, w, 0.2], [x0, z0 + d - 0.2, w, 0.2], [x0, z0, 0.2, d], [x0 + w - 0.2, z0, 0.2, d]]:
		box(e[0], -0.2, e[1], e[2], 0.48, e[3], 0x9a9893)
	var n := int(round(w / 0.16))
	for k in range(n + 1):                                       # the railing along its front and back
		for zz in [z0 + d - 0.1, z0 + 0.1]:
			box(x0 + 0.1 + (w - 0.2) * k / n - 0.01, 0.28, zz - 0.01, 0.02, 0.75, 0.02, IRON)
	var m := int(round(d / 0.16))
	for k in range(m + 1):                                       # and its sides
		for xx in [x0 + 0.1, x0 + w - 0.1]:
			box(xx - 0.01, 0.28, z0 + 0.1 + (d - 0.2) * k / m - 0.01, 0.02, 0.75, 0.02, IRON)
	for zz in [z0 + d - 0.1, z0 + 0.1]:
		box(x0 + 0.08, 1.0, zz - 0.02, w - 0.16, 0.04, 0.04, IRON)
	for xx in [x0 + 0.1, x0 + w - 0.1]:
		box(xx - 0.02, 1.0, z0 + 0.08, 0.04, 0.04, d - 0.16, IRON)
	box(x0 + w / 2.0 - 0.4, 0.28, z0 + d - 0.12, 0.8, 0.85, 0.03, IRON)      # (its gate)
	var tone: int = [DARK, GRANITE, MARBLE][int(u1 + v1) % 3]
	box(x0 + 0.5, 0.0, z0 + 0.5, w - 1.0, 0.55, d - 1.6, tone)
	box(x0 + 0.6, 0.55, z0 + 0.6, w - 1.2, 0.06, d - 1.8, 0xd8d2c6 if tone == DARK else DARK)
	box(x0 + 0.6, 0.0, z0 + 0.35, w - 1.2, 1.5, 0.16, tone)                    # its stone, at the back
	cbox(Vector3(x0 + w / 2.0, 1.95, z0 + 0.43), Vector3(0.08, 0.9, 0.08), IRON)
	cbox(Vector3(x0 + w / 2.0, 2.15, z0 + 0.43), Vector3(0.46, 0.08, 0.08), IRON)
	box(x0 + 0.7, 0.55, z0 + d - 1.25, 0.2, 0.35, 0.2, 0x8c8a86)             # vases with flowers
	ball(Vector3(x0 + 0.8, 1.0, z0 + d - 1.15), 0.18, 0xc23a3a, 0.8, 7, 4)
	box(x0 + w - 0.9, 0.55, z0 + d - 1.25, 0.2, 0.35, 0.2, 0x8c8a86)
	ball(Vector3(x0 + w - 0.8, 1.0, z0 + d - 1.15), 0.18, 0xf0efe6, 0.8, 7, 4)
	var keep := _xf
	_solid_xf(Vector3(x0 + w / 2.0, 0.6, z0 + d / 2.0), Vector3(w, 1.2, d))
	_xf = keep
	home()

## a family's broad tomb, raised: granite, a slab over it, a tall stone at its head with a cross
func _losa(u0: float, u1: float, v0: float, v1: float, east: bool) -> void:
	var s := _pan_frame(u0, u1, v0, v1, east)
	var w := s.x - 0.6
	var d := s.y - 0.6
	var x0 := 0.3
	var z0 := -0.3 - d
	var tone: int = [GRANITE, MARBLE, DARK, 0xb7b0a4][int(u0 * 3.0 + v0) % 4]
	box(x0 - 0.12, -0.2, z0 - 0.12, w + 0.24, 0.3, d + 0.24, 0x8c8a86)
	box(x0, 0.1, z0, w, 0.5, d, tone)
	box(x0 - 0.05, 0.6, z0 - 0.05, w + 0.1, 0.08, d + 0.1, 0xd8d2c6 if tone == DARK else 0x55575a)
	box(x0 + 0.1, 0.68, z0, w - 0.2, 1.2, 0.18, tone)
	cbox(Vector3(x0 + w / 2.0, 2.18, z0 + 0.09), Vector3(0.12, 0.62, 0.12), tone)
	cbox(Vector3(x0 + w / 2.0, 2.28, z0 + 0.09), Vector3(0.44, 0.12, 0.12), tone)
	for side in [0.25, w - 0.45]:
		box(x0 + side, 0.68, z0 + d - 0.55, 0.2, 0.3, 0.2, 0x8c8a86)
		ball(Vector3(x0 + side + 0.1, 1.08, z0 + d - 0.45), 0.17, [0xc23a3a, 0xe8c63a, 0xd77aa0][int(u1 + side) % 3], 0.8, 7, 4)
	var keep := _xf
	_solid_xf(Vector3(x0 + w / 2.0, 0.6, z0 + d / 2.0), Vector3(w + 0.24, 1.2, d + 0.24))
	_xf = keep
	home()

# ---------------- trees and lamps ----------------
## the cypresses (the world's own trees, kind 2: world.add_trees): along the walk east from the gatehouse, along the
## broad walk, a few among its pantheons, small ones outside the west wall, three on the island and one before the
## gatehouse; broad trees along the far side of the road
func _trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2808
	var put := func(u: float, v: float, k: int, s: float) -> void:
		var w := map_at(u, v)
		trees_put.append([w.x, w.y, k, s, rng.randf() * TAU])
	var u := 17.0
	while u < AVENUE[0] - 1.0:
		put.call(u, CROSS_WALK[0] - 0.6, 2, rng.randf_range(1.15, 1.45))
		u += 5.6
	u = AVENUE[1] + 2.0
	while u < L_N - 3.0:
		put.call(u, CROSS_WALK[1] + 0.6, 2, rng.randf_range(1.15, 1.45))
		u += 6.0
	var v := 50.0
	while v < 126.0:
		if v < CROSS_WALK[0] - 1.0 or v > CROSS_WALK[1] + 1.0:
			put.call(AVENUE[0] - 0.8, v, 2, rng.randf_range(1.1, 1.4))
		v += 9.0
	for q in [[85.0, 80.0], [85.0, 108.0], [95.0, 62.0]]:
		put.call(q[0], q[1], 2, rng.randf_range(1.0, 1.3))
	for span in [[6.0, 58.0], [112.0, L_W - 4.0]]:
		v = span[0]
		while v < span[1]:
			put.call(-6.5, v, 2, rng.randf_range(0.42, 0.6))
			v += 8.5
	for q in [[ISLE_U + 2.2, ISLE_V0 + 3.5, 1.35], [ISLE_U + 6.2, (ISLE_V0 + ISLE_V1) / 2.0 + 2.0, 1.5], [CYPRESS.x, CYPRESS.y, 1.25]]:
		put.call(q[0], q[1], 2, q[2])                              # (two on the island, none before its middle: from the road the gatehouse is seen)
	var cp := P(CYPRESS.x, CYPRESS.y)                              # (that one's trunk whitewashed at its foot: Street View 2024)
	drum(Vector3(cp.x, g_uv(CYPRESS.x, CYPRESS.y) - 0.05, cp.y), 0.17, 0.16, 0.95, "cal", 10)
	put.call(ISLE_U + 4.5, ISLE_V0 + 2.5, 1, 0.8)                  # (the bare tree of the island, behind its sign: leaves for now)
	v = -4.0
	while v < L_W + 4.0:
		put.call(-41.0 + rng.randf_range(-0.8, 0.8), v, 0, rng.randf_range(0.8, 1.05))
		v += 18.0

## The two hidden saffrons (the user, 25 Nov 2026, of the two places proposed: «Bien, ponlo en los dos»), each counted
## once a game as the other hidden ones (game.flowers, hidden: Sistemas keeps the count):
##   - in the vase of a grave in the far south-east corner, in the place of its cloth flowers, lost among the rest; on a
##     grave at the end of its row, its vase on the outer side, so it is reached from the walk beside it;
##   - at the foot of the cypress with the whitewashed trunk before the gatehouse, on its side to the wall, under its
##     lowest boughs.
func _saffron() -> void:
	var best = null
	var want := P(SAFFRON_VASE.x, SAFFRON_VASE.y)
	for vz in _vases:
		if best == null or (vz[0] as Vector2).distance_to(want) < (best[0] as Vector2).distance_to(want):
			best = vz
	if best != null:
		var fl: Array = _mm["flower"][best[2]]
		var e: Array = fl[best[3]]
		e[0] = Transform3D(Basis.from_scale(Vector3.ONE * 0.001), (e[0] as Transform3D).origin)      # (its cloth flowers go)
		var vp: Vector2 = best[0]
		_flower("cementerio_tumba", Vector3(vp.x, best[1], vp.y), 0.55)
	var cu := CYPRESS.x + 0.55
	var c := P(cu, CYPRESS.y)
	_flower("cementerio_cipres", Vector3(c.x, g_uv(cu, CYPRESS.y), c.y), 0.7)

## a saffron flower here (as the other hidden ones: pickups.gd dresses it, rising and spinning in its glow), k its size
func _flower(id: String, at: Vector3, k: float) -> void:
	var flower := Node3D.new()
	flower.add_child(Parts.part("cyl", 0x5f9c4a, Vector3(0, 0.3, 0), Vector3(0.03, 0.6, 0.03)))
	for i in range(5):
		flower.add_child(Parts.part("ball", 0x9b5de5, Vector3(cos(i * 1.257) * 0.12, 0.66, sin(i * 1.257) * 0.12), Vector3(0.11, 0.2, 0.11)))
	flower.add_child(Parts.part("ball", 0xe63946, Vector3(0, 0.74, 0), Vector3(0.05, 0.13, 0.05)))
	flower.scale = Vector3.ONE * k
	flower.position = at
	add_child(flower)
	var w := transform * at
	var spot := Vector2(w.x, w.z)
	saffron.append([id, spot])
	var game = W.get_parent()                           # (the game: the world is its child)
	if game != null and game.get("flowers") != null:
		(game.flowers as Array).append({"node": flower, "p": spot, "id": id, "hidden": true})

## the street lamps along the road on its side, a curved arm over the road (Street View 2024); and one lights the square
func _lamps() -> void:
	for v in [12.0, 42.0, 72.0, 104.0, 136.0, 164.0]:
		var at := P(PAVE_U + 0.6, v)
		_lamp(Vector3(at.x, g_uv(PAVE_U + 0.6, v), at.y))

## a lamp of the road's, its foot at o (in the frame), its arm west over the road
func _lamp(o: Vector3) -> void:
	var dark := 0x5c6064
	drum(o, 0.12, 0.08, 8.0, dark, 8)
	var tip := o + Vector3(-1.6, 8.6, 0.0)                    # (its arm west, over the road)
	bar(o + Vector3(0, 8.0, 0), o + Vector3(-0.6, 8.55, 0), 0.08, 0.08, dark)
	bar(o + Vector3(-0.6, 8.55, 0), tip, 0.08, 0.08, dark)
	cbox(tip + Vector3(-0.25, -0.05, 0), Vector3(0.6, 0.12, 0.28), dark)
	cbox(tip + Vector3(-0.25, -0.13, 0), Vector3(0.5, 0.04, 0.22), "farol")
	solid(o + Vector3(0, 2.0, 0), Vector3(0.26, 4.0, 0.26))
	W.lamp_spots.append(transform * (tip + Vector3(-0.25, -0.2, 0)))

# ---------------- on along the road ----------------
## The roadside on along the old road both ways, past its own stretch (the user, 25 Nov 2026: «Veo que la acera, los
## pinos y las farolas se cortan donde se cortaba antes la carretera. Podemos extenderlos también?"): its lamps every
## 30 m on its side of the road, the row of trees on the other side every 18 m (PNOA 2024: the row goes on north to the
## yard past the white nave, and south to the town), and its light pavement with its kerb on its side. They go by the
## road's own line (zonas.gd), not by the cemetery's frame: the two are a third of a degree apart, metres off over
## hundreds of metres. North to a little short of where the old road meets the A-4's slip roads (OSM), south to the
## town's gate; none at a zone gate (its posts stand where the lamps and the pavement would).
const ZonasS = preload("res://scripts/zonas.gd")
const SolarS = preload("res://scripts/planta_solar.gd")
const AfuerasS = preload("res://scripts/afueras.gd")
const SIDE_END := 30.0                     # (short of the old road's end)
const TREES_NORTH := -2700.0               # the row of trees north to here
var roadside: Array = []                   # the pavement's outlines on the map (keep_off: no dry plants on it)

func _roadside() -> void:
	var zd: Dictionary = ZonasS.ZONES[0]
	var a: Vector2 = zd["road_from"]
	var b: Vector2 = zd["road_to"]
	var d: Vector2 = (b - a).normalized()
	var n := Vector2(-d.y, d.x)                                    # (east: the cemetery's side)
	var L: float = a.distance_to(b)
	var gate_t: Array = [((zd["town"] as Vector2) - a).dot(d), ((zd["zone"] as Vector2) - a).dot(d)]
	var rng := RandomNumberGenerator.new()
	rng.seed = 2511
	# the lamps
	var l0: Vector2 = map_at(PAVE_U + 0.6, 12.0)
	var l1: Vector2 = map_at(PAVE_U + 0.6, 164.0)
	var lo: float = (l0 - a).dot(n)
	var spots: Array = []
	var t: float = (l0 - a).dot(d) + 30.0
	while t < L - SIDE_END:
		spots.append(t)
		t += 30.0
	t = (l1 - a).dot(d) - 30.0
	while t > 25.0:
		spots.append(t)
		t -= 30.0
	for tt in spots:
		if _by_gate(float(tt), gate_t, 9.0):
			continue
		var w: Vector2 = a + d * float(tt) + n * lo
		var f := to_frame(w)
		_lamp(Vector3(f.x, MapData.height(w) - level, f.y))
	# the row of trees across the road
	var r0: Vector2 = map_at(-41.0, -4.0)
	var r1: Vector2 = map_at(-41.0, -4.0 + 18.0 * ceil((L_W + 8.0) / 18.0))
	var ro: float = (r0 - a).dot(n)
	var t_north: float = (TREES_NORTH - a.y) / d.y                  # (along the road to where it is that far north)
	spots.clear()
	t = (r0 - a).dot(d) + 18.0
	while t < t_north:
		spots.append(t)
		t += 18.0
	t = (r1 - a).dot(d)
	while t > 25.0:
		spots.append(t)
		t -= 18.0
	for tt in spots:
		var jig := rng.randf_range(-0.8, 0.8)
		var size := rng.randf_range(0.8, 1.05)
		var turn := rng.randf() * TAU
		if _by_gate(float(tt), gate_t, 10.0):
			continue
		var w: Vector2 = a + d * float(tt) + n * (ro + jig)
		if w.distance_to(SolarS.DRIVE) < 4.5:                      # (none in the solar plant's drive across the road: planta_solar.gd)
			continue
		var nave_t: float = (w - AfuerasS.NAVE_S).dot((AfuerasS.NAVE_N - AfuerasS.NAVE_S).normalized())
		if nave_t > -14.0 and nave_t < AfuerasS.NAVE_S.distance_to(AfuerasS.NAVE_N) + 12.0:      # (nor before the white nave: its yard is open to the road, afueras.gd)
			continue
		trees_put.append([w.x, w.y, 0, size, turn])
	# the pavement and its kerb: north from the square's pavers, south from the end of its own
	var e0: float = (map_at(PAVE_U, PAVE_V1) - a).dot(n)
	var spans: Array = [[(map_at(PAVE_U, PAVE_V0) - a).dot(d), L - SIDE_END - 10.0], [25.0, (map_at(PAVE_U, L_W - 2.0) - a).dot(d)]]
	for gt in gate_t:                                              # (cut at the gates)
		var cut: Array = []
		for sp in spans:
			var s0: float = sp[0]
			var s1: float = sp[1]
			var g0: float = float(gt) - 5.0
			var g1: float = float(gt) + 5.0
			if s1 <= g0 or s0 >= g1:
				cut.append(sp)
				continue
			if s0 < g0:
				cut.append([s0, g0])
			if s1 > g1:
				cut.append([g1, s1])
		spans = cut
	for sp in spans:
		var s0: float = sp[0]
		var s1: float = sp[1]
		var k := int(ceil((s1 - s0) / 10.0))
		for i in range(k):                                         # (in pieces of 10 m: on the map the land rises and falls)
			var ta: float = lerpf(s0, s1, float(i) / k)
			var tb: float = lerpf(s0, s1, float(i + 1) / k)
			var pa: Vector2 = a + d * ta
			var pb: Vector2 = a + d * tb
			var poly := PackedVector2Array([pa + n * e0, pb + n * e0, pb + n * (e0 + 3.0), pa + n * (e0 + 3.0)])
			_lay_map(poly, 0.05, "acera")
			_kerb_map(pa + n * (e0 + 3.0), pb + n * (e0 + 3.0), 0.12)
		roadside.append(PackedVector2Array([a + d * s0 + n * (e0 - 0.4), a + d * s1 + n * (e0 - 0.4), a + d * s1 + n * (e0 + 3.4), a + d * s0 + n * (e0 + 3.4)]))

## within `reach` of a zone gate, along the road
func _by_gate(t: float, gate_t: Array, reach: float) -> bool:
	for gt in gate_t:
		if absf(t - float(gt)) < reach:
			return true
	return false

## a kerb as the pavement's, from a to b on the map
func _kerb_map(a: Vector2, b: Vector2, tall: float) -> void:
	var n := int(ceil(a.distance_to(b)))
	for k in range(n):
		var qa := a.lerp(b, float(k) / n)
		var qb := a.lerp(b, float(k + 1) / n)
		var ln := face(to_frame(qa), to_frame(qb), MapData.height((qa + qb) / 2.0) - level)
		box(0.0, -0.1, -0.1, ln, tall + 0.1, 0.2, 0xb8382e if k % 2 == 0 else 0xf2efe8)
	home()
