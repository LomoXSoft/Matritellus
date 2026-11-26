## Dry plants on the bare ground (the user, 21 Nov 2026: "poner plantas secas sueltas, para que no quede todo tan plano").
## Tufts of dead grass and the odd dry bush on the earth of empty lots, verges and the edges of the town: thicker at
## the foot of walls and along the roadside, in loose patches elsewhere, as weeds grow. Never on a road or its
## pavement, inside a block of houses, on a lawn, a park, a vineyard or water, or on a place built by hand; and a ray
## down must meet the bare terrain itself (not a floor, a deck, a car). Fewer on the fields of bare earth and furrows.
##
## They are MultiMeshes, one per 64 m square and kind, not drawn from far (Parts._range, so the draw-distance option
## applies), with no shadow and nothing to bump into. The same ones every time (fixed seeds). They go in once the
## physics of the world is up, a slice at a time while the town is being built (a step of world.gd's).
##
## And trees (the user, 24 Nov 2026: "Las partes sin construir o de tierra son muy vacías, sin árboles ni matojos. No
## podríamos añadir unos pocos donde no haya solares ni construcciones"): now and then, on the open earth of the town's
## edges and verges, well clear of streets, walls and the map's own trees, an olive, an almond or a stand of umbrella
## pines (as at the north entrance), and among the dry tufts the odd grey-green shrub (retama, romero, coscoja). Never
## in a block (the solares are the Catastro's, inside the blocks), a field, a park or a place built by hand. The trees
## are the town's like the rest (world.gd add_trees: solid, felled by a car, back the next day).
##
## And along the Carretera Antigua de Madrid a Cádiz (the user, 24 Nov 2026): rows of shade trees planted in square
## tree pits (alcorques) along the outer edge of the lateral pavements wherever there are no adjacent constructions
## behind that side, clear of junctions, roundabouts, hand-built places and the north entrance sightline.
extends Node3D

const Parts = preload("res://scripts/parts.gd")

const CELL := 64.0          # the squares they are drawn in
const STEP := 6.4           # one candidate spot on a jittered grid this far apart (5 by 5 in each square of GRID)
const REACH := 2            # how many squares of GRID past the last block of houses they still grow (64 m)
const TREE_REACH := 4       # and the trees (128 m: the open land round the town is where it looked emptiest)
const FAR := 120.0          # not drawn past this (times the draw-distance option)
const ROAD_Y := -0.18       # (world.gd's: the drawn ground lies this far under the physics one)
const MADRID_CADIZ := "Carretera Antigua de Madrid a Cádiz"
const AVE_STEP := 14.0      # spacing of the shade trees along the old Madrid-Cádiz pavements (matches PNOA orthophotos)
const AVE_OFF := 1.38       # past the asphalt edge: outer edge of the 1.6 m pavement, clear of walkers at +0.9 m
const AVE_GAP := 9.5        # minimum gap from another tree

var world
var count := 0              # plants placed (for the self-test and --timing)
var avenue_trees := 0       # roadside shade trees along the Carretera Antigua de Madrid a Cádiz
var trees: Array = []       # the trees grown here: [x, z, kind, size, turn] (world.gd add_trees)
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
var _close := {}                # Vector2i -> true where the plants grow too (within REACH), false where only trees
var _tnoise: FastNoiseLite      # where trees grow at all, and which: olives and almonds, or pines
var _taken := {}                # Vector2i(cell of 8 m) -> [Vector2...]: the trees standing (the map's and these)
var _alcorques: Array = []      # [Vector2 pos, float heading] for the square tree pits on the Madrid-Cádiz pavements
const TREE_GAP := 7.0
var _t0 := 0

func step() -> bool:
	var stop := Time.get_ticks_usec() + 12000
	if _phase == 0:
		_t0 = Time.get_ticks_msec()
		_index_places()
		var t1 := Time.get_ticks_msec()
		var cached := _load()
		var t2 := Time.get_ticks_msec()
		if not cached.is_empty():
			_show(cached["bufs"])
			var t3 := Time.get_ticks_msec()
			trees = cached["trees"]
			world.add_trees(trees)
			_phase = 2
			ready_done = true
			if OS.get_cmdline_user_args().has("--timing"):
				print("dry plants: %d and %d trees from the cache in %d ms (the places' outlines %d, reading %d, showing %d, the trees %d)" % [count, trees.size(), Time.get_ticks_msec() - _t0,
					t1 - _t0, t2 - t1, t3 - t2, Time.get_ticks_msec() - t3])
			return false
		_index()
		var near := {}
		for k in _blocks:
			for dx in range(-TREE_REACH, TREE_REACH + 1):
				for dz in range(-TREE_REACH, TREE_REACH + 1):
					var nk: Vector2i = k + Vector2i(dx, dz)
					var close: bool = absi(dx) <= REACH and absi(dz) <= REACH
					near[nk] = near.get(nk, false) or close
		_cells = near.keys()
		_close = near
		_cells.sort()
		_noise = FastNoiseLite.new()
		_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
		_noise.seed = 21
		_noise.frequency = 1.0 / 45.0
		_rng = RandomNumberGenerator.new()
		_rng.seed = 2111
		_q = PhysicsRayQueryParameters3D.new()
		_q.collide_with_areas = false
		_tnoise = FastNoiseLite.new()
		_tnoise.noise_type = FastNoiseLite.TYPE_SIMPLEX
		_tnoise.seed = 2411
		_tnoise.frequency = 1.0 / 140.0
		for t in world.tree_info:
			_take(t["p"])
		_phase = 1
		return true
	if _phase == 1:
		var space := get_world_3d().direct_space_state
		while _ci < _cells.size():
			var cell: Vector2i = _cells[_ci]
			_ci += 1
			for n in range(25 if _close[cell] else 0):
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
			_try_tree(cell, space)
			if Time.get_ticks_usec() > stop:
				return true
		_avenue_trees(space)
		var bufs := _plant(_kept, _rng)
		_add_alcorques(bufs)
		_show(bufs)
		world.add_trees(trees)
		_save(bufs)
		_phase = 2
		ready_done = true
		if OS.get_cmdline_user_args().has("--timing"):
			print("dry plants: %d at %d spots (%d candidates), %d trees (%d avenue), in %d ms" % [count, _kept.size(), _tried, trees.size(), avenue_trees, Time.get_ticks_msec() - _t0])
	return false

## a tree in this square of GRID, maybe: one try at a spot, where the noise lets trees grow (in stands, with open
## earth between), on open bare earth only (not a field), off the streets and walls, its crown clear of every street,
## block and place, nothing standing where it would be (a fence, a lamp, a sign), and no tree already within TREE_GAP
func _try_tree(cell: Vector2i, space: PhysicsDirectSpaceState3D) -> void:
	var p := Vector2((cell.x + _rng.randf()) * GRID, (cell.y + _rng.randf()) * GRID)
	var roll := _rng.randf()
	var kind_roll := _rng.randf()
	var size := _rng.randf_range(0.8, 1.2)
	var turn := _rng.randf() * TAU
	var tn := _tnoise.get_noise_2d(p.x, p.y)
	var chance := clampf((tn + 0.3) * 0.75, 0.04, 0.5)
	if roll >= chance:
		return
	var thick := _ground_ok(p)
	if thick <= 0.0 or (thick < 1.0 and roll >= chance * 0.3) or MapData.room_at(p) < 4.5 or MapData.road_edge_dist(p) < 4.5:
		return                                   # (on a field only now and then: one by its edge)
	for a in range(6):
		if _ground_ok(p + Vector2.from_angle(TAU * a / 6.0) * 2.6) <= 0.0:
			return
	var k := Vector2i(floori(p.x / 8.0), floori(p.y / 8.0))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for q in _taken.get(k + Vector2i(dx, dz), []):
				if (q as Vector2).distance_to(p) < TREE_GAP:
					return
	var h: float = MapData.height(p)
	_q.from = Vector3(p.x, h + 40.0, p.y)
	_q.to = Vector3(p.x, h - 1.0, p.y)
	var hit := space.intersect_ray(_q)
	if hit.is_empty() or absf(float(hit["position"].y) - h) > 0.05 or float(hit["normal"].y) < 0.9:
		return
	var sq := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new()
	for at in [[1.1, 0.9], [3.2, 2.0]]:          # the trunk, then the crown: nothing there
		ball.radius = at[1]
		sq.shape = ball
		sq.transform = Transform3D(Basis.IDENTITY, Vector3(p.x, h + at[0], p.y))
		if not space.intersect_shape(sq, 1).is_empty():
			return
	var kind := 3 if tn > 0.3 and kind_roll < 0.8 and thick >= 1.0 else (1 if kind_roll < 0.7 else 0)       # pines where the stands are thickest; olives most
	trees.append([p.x, p.y, kind, size, turn])
	_take(p)

func _take(p: Vector2) -> void:
	var k := Vector2i(floori(p.x / 8.0), floori(p.y / 8.0))
	if not _taken.has(k):
		_taken[k] = []
	_taken[k].append(p)

func _in_block(p: Vector2) -> bool:
	var blocks = _blocks.get(_gk(p.x, p.y))
	if blocks != null:
		for r in blocks:
			if Geometry2D.is_point_in_polygon(p, r):
				return true
	return false

func _in_place_pad(p: Vector2, pad: float) -> bool:
	for pl in _places:
		var l: Vector3 = (pl[0] as Transform3D) * Vector3(p.x, 0.0, p.y)
		if (pl[1] as Rect2).grow(pad).has_point(Vector2(l.x, l.z)):
			return true
	return false

## Shade trees planted in square alcorques along the lateral pavements of the Carretera Antigua de Madrid a Cádiz,
## wherever there are no constructions behind that side (matching Google Maps / PNOA orthophotos).
func _avenue_trees(space: PhysicsDirectSpaceState3D) -> void:
	var arng := RandomNumberGenerator.new()
	arng.seed = 24112
	var ent = world.get("entrada")
	var sq := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new()
	for r in MapData.roads:
		if int(r["k"]) != 0 or String(r["n"]) != MADRID_CADIZ:
			continue
		var pts: PackedInt32Array = r["p"]
		var hw: float = float(r["w"]) * 0.5
		var carry := AVE_STEP * 0.5
		for i in range(pts.size() - 1):
			var a: Vector2 = MapData.nodes[pts[i]]
			var b: Vector2 = MapData.nodes[pts[i + 1]]
			var d := b - a
			var length := d.length()
			if length < 0.5:
				continue
			var u := d / length
			var perp := Vector2(-u.y, u.x)
			var along := carry
			while along <= length:
				var j_along := clampf(along + arng.randf_range(-0.6, 0.6), 0.5, maxf(0.5, length - 0.5))
				var mid := a + u * j_along
				for sgn: float in [-1.0, 1.0]:
					var skip_roll := arng.randf()
					var size := arng.randf_range(0.72, 0.96)
					var turn := arng.randf() * TAU
					if skip_roll < 0.06:                   # small natural gaps along the avenue
						continue
					var out: Vector2 = perp * sgn
					var at: Vector2 = mid + out * (hw + AVE_OFF)
					if ent != null and out.x < 0.0 and at.y >= -1685.0 and at.y <= -1620.0:
						continue                           # keep the north entrance welcome wall & sign sightline open
					var list = MapData._seg_grid.get(Vector2i(MapData._cell(at.x), MapData._cell(at.y)))
					var road_ok := true
					if list != null:
						for s in list:
							var ed: float = MapData.seg_point(s, at).distance_to(at) - s.hw
							if String(s.road["n"]) == MADRID_CADIZ:
								if ed < 1.15:
									road_ok = false
									break
							else:
								var need: float = 4.2 if int(s.road["k"]) == 0 else 2.2
								if ed < need:
									road_ok = false
									break
					if not road_ok:
						continue
					if _in_block(at) or _in_block(at + out * 2.5) or _in_block(at + out * 6.0):
						continue
					if MapData.room_at(at) < 7.5 or MapData.room_at(at + out * 4.0) < 8.0:
						continue                           # constructions stand behind this side of the road
					var area_ok := true
					var areas = _areas.get(_gk(at.x, at.y))
					if areas != null:
						for e in areas:
							if Geometry2D.is_point_in_polygon(at, e[0]):
								var ak: int = e[1]
								if ak <= 2 or ak == 5:     # lawn, park, vineyard, water
									area_ok = false
									break
					if not area_ok:
						continue
					if _in_place_pad(at, 4.5) or _in_place_pad(at + out * 5.0, 4.5):
						continue
					var k := Vector2i(floori(at.x / 8.0), floori(at.y / 8.0))
					var spaced := true
					for dx in range(-2, 3):
						for dz in range(-2, 3):
							for q in _taken.get(k + Vector2i(dx, dz), []):
								if (q as Vector2).distance_to(at) < AVE_GAP:
									spaced = false
									break
							if not spaced:
								break
						if not spaced:
							break
					if not spaced:
						continue
					var h: float = MapData.height(at)
					_q.from = Vector3(at.x, h + 40.0, at.y)
					_q.to = Vector3(at.x, h - 1.0, at.y)
					var hit := space.intersect_ray(_q)
					if hit.is_empty() or absf(float(hit["position"].y) - h) > 0.08 or float(hit["normal"].y) < 0.85:
						continue
					var clear := true
					for sp in [[1.1, 0.65], [3.5, 1.55]]:
						ball.radius = sp[1]
						sq.shape = ball
						sq.transform = Transform3D(Basis.IDENTITY, Vector3(at.x, h + sp[0], at.y))
						if not space.intersect_shape(sq, 1).is_empty():
							clear = false
							break
					if not clear:
						continue
					trees.append([at.x, at.y, 0, size, turn])
					_alcorques.append([at, u])
					_take(at)
					avenue_trees += 1
				along += AVE_STEP
			carry = along - length

func _add_alcorques(bufs: Dictionary) -> void:
	for entry in _alcorques:
		var at: Vector2 = entry[0]
		var u: Vector2 = entry[1]
		var up: Vector3 = MapData.normal(at)
		var fwd := Vector3(u.x, 0.0, u.y)
		var right := up.cross(fwd).normalized()
		fwd = right.cross(up).normalized()
		var b := Basis(right, up, fwd)
		var y: float = MapData.height(at) + ROAD_Y + 0.12
		var key := Vector3i(floori(at.x / CELL), floori(at.y / CELL), 3)
		if not bufs.has(key):
			bufs[key] = []
		var o := Vector3(at.x - (key.x + 0.5) * CELL, y, at.y - (key.y + 0.5) * CELL)
		(bufs[key] as Array).append_array([b.x.x, b.y.x, b.z.x, o.x, b.x.y, b.y.y, b.z.y, o.y, b.x.z, b.y.z, b.z.z, o.z, 1.0, 1.0, 1.0, 1.0])
	for key in bufs:
		if key.z == 3 and bufs[key] is Array:
			bufs[key] = PackedFloat32Array(bufs[key])

## the plants of each spot: one there, and maybe a few more round it where the ground is free too (they grow in clumps)
func _plant(kept: Array, rng: RandomNumberGenerator) -> Dictionary:
	var bufs := {}              # Vector3i(square x, square z, kind) -> the MultiMesh buffer: 12 floats of transform, 4 of colour
	var straw := [Color(1.0, 0.97, 0.9), Color(0.9, 0.84, 0.72), Color(0.82, 0.77, 0.7), Color(1.0, 0.9, 0.74)]
	var greens := [Color(1.0, 1.0, 1.0), Color(0.86, 0.92, 0.84), Color(1.05, 1.0, 0.9), Color(0.78, 0.8, 0.76)]
	for p in kept:
		var n := 1 + int(pow(rng.randf(), 1.3) * 8.0)
		for j in range(n):
			var at: Vector2 = p
			if j > 0:
				at = p + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.5, 2.2)
				if _ground_ok(at) <= 0.0:
					continue
			var r := rng.randf()
			var bush := r < 0.18
			var mata := j == 0 and r > 0.9 and MapData.room_at(at) > 2.0       # (one to a clump, in the open)
			var sc := rng.randf_range(0.55, 1.05) if bush else rng.randf_range(0.3, 0.62)
			if mata:
				sc = rng.randf_range(0.6, 1.15)
			var y: float = MapData.height(at) + ROAD_Y - 0.02
			var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(sc * rng.randf_range(0.85, 1.2), sc, sc * rng.randf_range(0.85, 1.2)))
			var c: Color = (greens[rng.randi() % greens.size()] if mata else straw[rng.randi() % straw.size()]) * rng.randf_range(0.88, 1.05)
			var key := Vector3i(floori(at.x / CELL), floori(at.y / CELL), 2 if mata else (1 if bush else 0))
			if not bufs.has(key):
				bufs[key] = []                    # (an Array while it grows: a packed one in a Dictionary is copied on every append)
			var o := Vector3(at.x - (key.x + 0.5) * CELL, y, at.y - (key.y + 0.5) * CELL)
			(bufs[key] as Array).append_array([b.x.x, b.y.x, b.z.x, o.x, b.x.y, b.y.y, b.z.y, o.y, b.x.z, b.y.z, b.z.z, o.z, c.r, c.g, c.b, 1.0])
	for key in bufs:
		bufs[key] = PackedFloat32Array(bufs[key])
	return bufs

func _show(bufs: Dictionary) -> void:
	var ts0 := Time.get_ticks_msec()
	var meshes := [_tuft_mesh(), _bush_mesh(), _mata_mesh(), _alcorque_mesh()]
	if OS.get_cmdline_user_args().has("--timing"):
		print("dry plants: their four meshes in %d ms, %d squares to show" % [Time.get_ticks_msec() - ts0, bufs.size()])
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	count = 0
	avenue_trees = 0
	for key in bufs:
		var buf: PackedFloat32Array = bufs[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = meshes[key.z]
		mm.instance_count = buf.size() / 16
		mm.buffer = buf
		if key.z == 3:
			avenue_trees += mm.instance_count
		else:
			count += mm.instance_count
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3((key.x + 0.5) * CELL, 0.0, (key.y + 0.5) * CELL)
		add_child(mi)
		Parts._range(mi, 220.0 if key.z == 3 else FAR)

# ---------------- kept from one time to the next ----------------
## Worked out once and kept (as world.gd keeps the ground's sheets): again only when the map, the places built by
## hand or VERSION change; the self-test uses the same (where they grow is no test's business, and it saves seconds a run).
const CACHE := "user://matojos.cache"
const VERSION := 4          # (2, 3: trees & shrubs; 4: Madrid-Cádiz roadside pavement trees + alcorques, 24 Nov 2026)

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
	if kept is Dictionary and kept.get("key", "") == _key() and kept.get("bufs") is Dictionary and kept.get("trees") is Array:
		return kept
	return {}

func _save(bufs: Dictionary) -> void:
	var f := FileAccess.open_compressed(CACHE, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	if f != null:
		f.store_var({"key": _key(), "bufs": bufs, "trees": trees})

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

## a shrub of the dry land (retama, romero, coscoja), a metre tall at scale 1: a lumpy low mound of grey-green, darker
## underneath, made of a few overlapping blobs so it is never a clean ball
static func _mata_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	var under := Color(0.2, 0.24, 0.15)
	var top := Color(0.43, 0.5, 0.32)
	for b in range(4):
		var c := Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(0.3, 0.5), rng.randf_range(-0.3, 0.3)) if b > 0 else Vector3(0.0, 0.45, 0.0)
		var rad := Vector3(0.45, 0.42, 0.45) * (1.0 if b == 0 else rng.randf_range(0.55, 0.8))
		var rows := 4
		var cols := 7
		var pts := []
		for i in range(rows + 1):
			var ring := []
			var la := PI * (0.5 - float(i) / rows)
			for j in range(cols):
				var lo := TAU * j / cols + (0.4 if i % 2 == 1 else 0.0)
				var d := Vector3(cos(la) * cos(lo), sin(la), cos(la) * sin(lo))
				var v := c + d * rad * rng.randf_range(0.85, 1.12)
				v.y = maxf(v.y, 0.0)
				ring.append([v, d])
			pts.append(ring)
		for i in range(rows):
			for j in range(cols):
				var q := [pts[i][j], pts[i][(j + 1) % cols], pts[i + 1][(j + 1) % cols], pts[i + 1][j]]
				for tri in [[0, 1, 2], [0, 2, 3]]:
					for e in tri:
						var v: Vector3 = q[e][0]
						var d: Vector3 = q[e][1]
						st.set_color(under.lerp(top, clampf(v.y / 0.8, 0.0, 1.0)))
						st.set_normal((d + Vector3.UP).normalized())
						st.add_vertex(v)
	return st.commit()

## a stem from a to b: two thin strips crossed, so it shows from every side
static func _stem(st: SurfaceTool, a: Vector3, b: Vector3, w: float, ca: Color, cb: Color) -> void:
	var along := (b - a).normalized()
	var s1 := along.cross(Vector3.UP if absf(along.y) < 0.95 else Vector3.RIGHT).normalized() * w
	var s2 := along.cross(s1).normalized() * w
	for s in [s1, s2]:
		_tri(st, a - s, a + s, b + s * 0.4, ca, ca, cb)
		_tri(st, a - s, b + s * 0.4, b - s * 0.4, ca, cb, cb)

## a square pavement tree pit (alcorque): thin concrete kerb framing a recessed square of dark earth
static func _alcorque_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ro := 0.47            # outer half-size (0.94 m square)
	var ri := 0.37            # inner soil half-size (0.74 m square)
	var yt := 0.042           # kerb top above pavement
	var ys := 0.016           # recessed earth bed
	var yb := -0.14           # skirt into the pavement/verge so gentle slopes never show a gap
	var kerb_top := Color(0.75, 0.72, 0.67)
	var kerb_side := Color(0.58, 0.55, 0.51)
	var soil_mid := Color(0.37, 0.28, 0.19)
	var soil_edge := Color(0.28, 0.21, 0.14)
	# earth bed (4 triangles to center for subtle darker edge)
	var sc := Vector3(0.0, ys + 0.006, 0.0)
	var ic := [Vector3(-ri, ys, -ri), Vector3(ri, ys, -ri), Vector3(ri, ys, ri), Vector3(-ri, ys, ri)]
	var oc := [Vector3(-ro, yt, -ro), Vector3(ro, yt, -ro), Vector3(ro, yt, ro), Vector3(-ro, yt, ro)]
	var it := [Vector3(-ri, yt, -ri), Vector3(ri, yt, -ri), Vector3(ri, yt, ri), Vector3(-ri, yt, ri)]
	var ob := [Vector3(-ro, yb, -ro), Vector3(ro, yb, -ro), Vector3(ro, yb, ro), Vector3(-ro, yb, ro)]
	for i in range(4):
		var j := (i + 1) % 4
		# recessed soil quad
		_tri(st, sc, ic[i], ic[j], soil_mid, soil_edge, soil_edge)
		# kerb top bevel strip
		_tri(st, oc[i], oc[j], it[j], kerb_top, kerb_top, kerb_top)
		_tri(st, oc[i], it[j], it[i], kerb_top, kerb_top, kerb_top)
		# inner kerb drop into soil
		_tri(st, it[i], it[j], ic[j], kerb_side, kerb_side, soil_edge)
		_tri(st, it[i], ic[j], ic[i], kerb_side, soil_edge, soil_edge)
		# outer kerb wall + skirt
		_tri(st, oc[j], oc[i], ob[i], kerb_side, kerb_side, kerb_side)
		_tri(st, oc[j], ob[i], ob[j], kerb_side, kerb_side, kerb_side)
	return st.commit()

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	for e in [[a, ca], [b, cb], [c, cc]]:
		st.set_color(e[1])
		st.set_normal(Vector3.UP)              # (lit as the ground they stand on, whichever way a blade faces)
		st.add_vertex(e[0])
