## Dry plants on the bare ground (the user, 21 Nov 2026: "poner plantas secas sueltas, para que no quede todo tan plano").
## Tufts of dead grass and the odd dry bush on the earth of empty lots, verges and the edges of the town: thicker at
## the foot of walls and along the roadside, in loose patches elsewhere, as weeds grow. Never on a road or its
## pavement, inside a block of houses, on a lawn, a park, a vineyard or water, or on a place built by hand; and a ray
## down must meet the bare terrain itself (not a floor, a deck, a car). Fewer on the fields of bare earth and furrows.
##
## They are MultiMeshes, one per 64 m square and kind, not drawn from far (Parts._range, so the draw-distance option
## applies), with no shadow and nothing to bump into. The same ones every time (fixed seeds). They go in once the
## physics of the world is up, a slice at a time while the town is being built (a step of world.gd's).
extends Node3D

const Parts = preload("res://scripts/parts.gd")

const CELL := 64.0          # the squares they are drawn in
const STEP := 6.4           # one candidate spot on a jittered grid this far apart (5 by 5 in each square of GRID)
const REACH := 2            # how many squares of GRID past the last block of houses they still grow (64 m)
const FAR := 120.0          # not drawn past this (times the draw-distance option)
const ROAD_Y := -0.18       # (world.gd's: the drawn ground lies this far under the physics one)

var world
var count := 0              # plants placed (for the self-test and --timing)
var ready_done := false

static func start(w) -> Node3D:
	var m = load("res://scripts/matojos.gd").new()
	m.name = "Matojos"
	m.world = w
	w.add_child(m)
	return m

# ---------------- where they may grow ----------------
var _blocks := {}           # Vector2i cell -> [ring...] (the blocks of houses)
var _areas := {}            # Vector2i cell -> [[ring, kind]...]
var _places: Array = []     # [inverse transform, local Rect2 grown a metre] of each place built by hand
const GRID := 32.0

func _gk(x: float, z: float) -> Vector2i:
	return Vector2i(floori(x / GRID), floori(z / GRID))

func _grid_put(grid: Dictionary, ring: PackedVector2Array, item) -> void:
	var lo := ring[0]
	var hi := ring[0]
	for q in ring:
		lo = lo.min(q)
		hi = hi.max(q)
	for cx in range(floori(lo.x / GRID), floori(hi.x / GRID) + 1):
		for cz in range(floori(lo.y / GRID), floori(hi.y / GRID) + 1):
			var k := Vector2i(cx, cz)
			if not grid.has(k):
				grid[k] = []
			grid[k].append(item)

func _index() -> void:
	for ring in MapData.outlines:
		var r: PackedVector2Array = ring
		if r.size() >= 3:
			_grid_put(_blocks, r, r)
	for a in MapData.areas:
		var ap: Array = a["p"]
		var r := PackedVector2Array()
		for i in range(0, ap.size(), 2):
			r.append(Vector2(ap[i], ap[i + 1]))
		if r.size() >= 3:
			_grid_put(_areas, r, [r, int(a["k"])])

func _index_places() -> void:
	for c in world.get_children():
		if c is Node3D and _hand_built(c):
			var place := c as Node3D
			var inv := place.global_transform.affine_inverse()
			var box := AABB()
			var first := true
			for mi in place.find_children("*", "MeshInstance3D", true, false):
				var m := mi as MeshInstance3D
				if m.mesh == null:
					continue
				var b: AABB = (inv * m.global_transform) * m.mesh.get_aabb()
				box = b if first else box.merge(b)
				first = false
			if not first:
				_places.append([inv, Rect2(box.position.x, box.position.z, box.size.x, box.size.z).grow(1.0)])

## a place built by hand: its script is obra.gd's (or the Petril's, which obra.gd came from) or descends from it
func _hand_built(n: Node) -> bool:
	var s: Script = n.get_script()
	while s != null:
		var p := s.resource_path
		if p.ends_with("/obra.gd") or p.ends_with("/petril.gd"):
			return true
		s = s.get_base_script()
	return false

## 0 where nothing may grow, else how thick they may grow there (1 on bare ground, less on fields)
func _ground_ok(p: Vector2) -> float:
	var list = MapData._seg_grid.get(Vector2i(MapData._cell(p.x), MapData._cell(p.y)))
	if list != null:
		for s in list:
			var need: float = 0.4 if int(s.road["k"]) == 1 else (0.8 if int(s.road["k"]) == 2 else 3.5)      # (asphalt has its pavement)
			if MapData.seg_point(s, p).distance_to(p) - s.hw < need:
				return 0.0
	var k := _gk(p.x, p.y)
	var blocks = _blocks.get(k)
	if blocks != null:
		for r in blocks:
			if Geometry2D.is_point_in_polygon(p, r):
				return 0.0
	var thick := 1.0
	var areas = _areas.get(k)
	if areas != null:
		for e in areas:
			if Geometry2D.is_point_in_polygon(p, e[0]):
				var kind: int = e[1]
				if kind <= 2 or kind == 5:               # lawn, park, vineyard, water
					return 0.0
				thick = 0.6                              # bare fields, furrows
	for pl in _places:
		var l: Vector3 = (pl[0] as Transform3D) * Vector3(p.x, 0.0, p.y)
		if (pl[1] as Rect2).has_point(Vector2(l.x, l.z)):
			return 0.0
	return thick

# ---------------- placing them ----------------
## A slice of the work at a time, as a step of the world's build (world.gd): true while there is more to do. The first
## slice only reads the map; the rays are cast from the next one on, when the world's bodies are in the physics.
var _phase := 0
var _cells: Array = []      # the squares of GRID in or near the town, in order
var _ci := 0
var _noise: FastNoiseLite
var _rng: RandomNumberGenerator
var _q: PhysicsRayQueryParameters3D
var _kept: Array = []
var _tried := 0
var _t0 := 0

func step() -> bool:
	var stop := Time.get_ticks_usec() + 12000
	if _phase == 0:
		_t0 = Time.get_ticks_msec()
		_index_places()
		var cached := _load()
		if not cached.is_empty():
			_show(cached)
			_phase = 2
			ready_done = true
			if OS.get_cmdline_user_args().has("--timing"):
				print("dry plants: %d from the cache in %d ms" % [count, Time.get_ticks_msec() - _t0])
			return false
		_index()
		var near := {}
		for k in _blocks:
			for dx in range(-REACH, REACH + 1):
				for dz in range(-REACH, REACH + 1):
					near[k + Vector2i(dx, dz)] = true
		_cells = near.keys()
		_cells.sort()
		_noise = FastNoiseLite.new()
		_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
		_noise.seed = 21
		_noise.frequency = 1.0 / 45.0
		_rng = RandomNumberGenerator.new()
		_rng.seed = 2111
		_q = PhysicsRayQueryParameters3D.new()
		_q.collide_with_areas = false
		_phase = 1
		return true
	if _phase == 1:
		var space := get_world_3d().direct_space_state
		while _ci < _cells.size():
			var cell: Vector2i = _cells[_ci]
			_ci += 1
			for n in range(25):
				var p := Vector2((cell.x * GRID) + (n % 5 + _rng.randf()) * STEP, (cell.y * GRID) + (n / 5 + _rng.randf()) * STEP)
				var roll := _rng.randf()
				var base := clampf((_noise.get_noise_2d(p.x, p.y) + 0.15) * 1.1, 0.02, 0.7)      # (in loose patches)
				if roll >= base + 0.45:
					continue
				_tried += 1
				var thick := _ground_ok(p)
				if thick <= 0.0:
					continue
				var near := 0.0
				var room: float = MapData.room_at(p)
				if room < 0.3:
					continue                              # (not right against a wall)
				if room < 2.5:
					near = 0.3                            # at the foot of a wall
				if MapData.road_edge_dist(p) < 6.0:
					near += 0.15                          # the roadside, past the pavement
				if roll >= (base + near) * thick:
					continue
				var h: float = MapData.height(p)          # a ray down: it must meet the bare terrain
				_q.from = Vector3(p.x, h + 40.0, p.y)
				_q.to = Vector3(p.x, h - 1.0, p.y)
				var hit := space.intersect_ray(_q)
				if not hit.is_empty() and absf(float(hit["position"].y) - h) < 0.05 and float(hit["normal"].y) > 0.85:
					_kept.append(p)
			if Time.get_ticks_usec() > stop:
				return true
		var bufs := _plant(_kept, _rng)
		_show(bufs)
		_save(bufs)
		_phase = 2
		ready_done = true
		if OS.get_cmdline_user_args().has("--timing"):
			print("dry plants: %d at %d spots (%d candidates) in %d ms" % [count, _kept.size(), _tried, Time.get_ticks_msec() - _t0])
	return false

## the plants of each spot: one there, and maybe a few more round it where the ground is free too (they grow in clumps)
func _plant(kept: Array, rng: RandomNumberGenerator) -> Dictionary:
	var bufs := {}              # Vector3i(square x, square z, kind) -> the MultiMesh buffer: 12 floats of transform, 4 of colour
	var straw := [Color(1.0, 0.97, 0.9), Color(0.9, 0.84, 0.72), Color(0.82, 0.77, 0.7), Color(1.0, 0.9, 0.74)]
	for p in kept:
		var n := 1 + int(pow(rng.randf(), 1.3) * 8.0)
		for j in range(n):
			var at: Vector2 = p
			if j > 0:
				at = p + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.5, 2.2)
				if _ground_ok(at) <= 0.0:
					continue
			var bush := rng.randf() < 0.18
			var sc := rng.randf_range(0.55, 1.05) if bush else rng.randf_range(0.3, 0.62)
			var y: float = MapData.height(at) + ROAD_Y - 0.02
			var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(sc * rng.randf_range(0.85, 1.2), sc, sc * rng.randf_range(0.85, 1.2)))
			var c: Color = straw[rng.randi() % straw.size()] * rng.randf_range(0.88, 1.05)
			var key := Vector3i(floori(at.x / CELL), floori(at.y / CELL), 1 if bush else 0)
			if not bufs.has(key):
				bufs[key] = []                    # (an Array while it grows: a packed one in a Dictionary is copied on every append)
			var o := Vector3(at.x - (key.x + 0.5) * CELL, y, at.y - (key.y + 0.5) * CELL)
			(bufs[key] as Array).append_array([b.x.x, b.y.x, b.z.x, o.x, b.x.y, b.y.y, b.z.y, o.y, b.x.z, b.y.z, b.z.z, o.z, c.r, c.g, c.b, 1.0])
	for key in bufs:
		bufs[key] = PackedFloat32Array(bufs[key])
	return bufs

func _show(bufs: Dictionary) -> void:
	var meshes := [_tuft_mesh(), _bush_mesh()]
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	count = 0
	for key in bufs:
		var buf: PackedFloat32Array = bufs[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = meshes[key.z]
		mm.instance_count = buf.size() / 16
		mm.buffer = buf
		count += mm.instance_count
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3((key.x + 0.5) * CELL, 0.0, (key.y + 0.5) * CELL)
		add_child(mi)
		Parts._range(mi, FAR)

# ---------------- kept from one time to the next ----------------
## Worked out once and kept (as world.gd keeps the ground's sheets): again only when the map, the places built by
## hand or VERSION change; the self-test uses the same (where they grow is no test's business, and it saves seconds a run).
const CACHE := "user://matojos.cache"
const VERSION := 1

func _key() -> String:
	var sig := 0.0
	for pl in _places:
		var r: Rect2 = pl[1]
		sig += r.position.x * 0.37 + r.position.y * 0.11 + r.size.x + r.size.y * 3.0
	return "%d|%s|%d|%.1f" % [VERSION, FileAccess.get_md5("res://data/map.json"), _places.size(), sig]

func _load() -> Dictionary:
	if not FileAccess.file_exists(CACHE):
		return {}
	var f := FileAccess.open_compressed(CACHE, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return {}
	var kept = f.get_var()
	if kept is Dictionary and kept.get("key", "") == _key() and kept.get("bufs") is Dictionary:
		return kept["bufs"]
	return {}

func _save(bufs: Dictionary) -> void:
	var f := FileAccess.open_compressed(CACHE, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	if f != null:
		f.store_var({"key": _key(), "bufs": bufs})

# ---------------- what they look like ----------------
## a tuft of dead grass, a metre tall at scale 1: blades bent out from the foot, darker there, straw at the tips
static func _tuft_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var foot := Color(0.33, 0.26, 0.16)
	var tip := Color(0.64, 0.54, 0.34)
	for i in range(15):
		var ang := TAU * i / 15.0 + rng.randf_range(-0.3, 0.3)
		var hgt := rng.randf_range(0.5, 1.0)
		var lean := rng.randf_range(0.2, 0.7)
		var d := Vector3(cos(ang), 0.0, sin(ang))
		var side := Vector3(-d.z, 0.0, d.x) * rng.randf_range(0.06, 0.09)
		var b := d * 0.05
		var m := d * (0.05 + lean * hgt * 0.3) + Vector3(0.0, hgt * 0.55, 0.0)
		var t := d * (0.05 + lean * hgt) + Vector3(0.0, hgt, 0.0)
		var mc := foot.lerp(tip, 0.6)
		_tri(st, b - side, b + side, m + side * 0.7, foot, foot, mc)
		_tri(st, b - side, m + side * 0.7, m - side * 0.7, foot, mc, mc)
		_tri(st, m - side * 0.7, m + side * 0.7, t, mc, mc, tip)
	return st.commit()

## a dry bush, a metre tall at scale 1: grey-brown stems out of one foot, each with a twig or two off it
static func _bush_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var foot := Color(0.36, 0.3, 0.24)
	var tip := Color(0.62, 0.55, 0.43)
	for i in range(8):
		var ang := TAU * i / 8.0 + rng.randf_range(-0.35, 0.35)
		var d := Vector3(cos(ang), 0.0, sin(ang))
		var top := d * rng.randf_range(0.25, 0.5) + Vector3(0.0, rng.randf_range(0.6, 1.0), 0.0)
		_stem(st, Vector3.ZERO, top, 0.035, foot, tip)
		for k in range(2):
			var from: Vector3 = top * rng.randf_range(0.4, 0.75)
			var out := (d.rotated(Vector3.UP, rng.randf_range(-1.2, 1.2)) * rng.randf_range(0.15, 0.3) + Vector3(0.0, rng.randf_range(0.1, 0.3), 0.0))
			_stem(st, from, from + out, 0.02, foot.lerp(tip, 0.5), tip)
	return st.commit()

## a stem from a to b: two thin strips crossed, so it shows from every side
static func _stem(st: SurfaceTool, a: Vector3, b: Vector3, w: float, ca: Color, cb: Color) -> void:
	var along := (b - a).normalized()
	var s1 := along.cross(Vector3.UP if absf(along.y) < 0.95 else Vector3.RIGHT).normalized() * w
	var s2 := along.cross(s1).normalized() * w
	for s in [s1, s2]:
		_tri(st, a - s, a + s, b + s * 0.4, ca, ca, cb)
		_tri(st, a - s, b + s * 0.4, b - s * 0.4, ca, cb, cb)

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	for e in [[a, ca], [b, cb], [c, cc]]:
		st.set_color(e[1])
		st.set_normal(Vector3.UP)              # (lit as the ground they stand on, whichever way a blade faces)
		st.add_vertex(e[0])
