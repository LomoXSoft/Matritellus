extends Node3D
## Things to hit and things to use: breakable street furniture and trees, jump ramps, and repair points.
## Street furniture stands frozen until a car touches it, then becomes a loose rigid body (layer 32) that tumbles away.

const Parts = preload("res://scripts/parts.gd")
const CELL := 8.0

var game
var world
var _grid := {}           # Vector2i -> Array of standing props
var _tree_grid := {}      # Vector2i -> Array of tree indices
var ramps: Array = []     # {p: Vector2, h: float}
var repairs: Array = []   # {p: Vector2, node: Node3D}
var broken_count := 0
const Creator = preload("res://scripts/creator.gd")
var tags: Array = []          # peña graffiti: {p: where you stand to paint it, label: Label3D, owner: int}
var terrazas: Array = []   # {p: Vector2, u: Vector2}
var _repair_cool := 0.0

func setup(game_, world_) -> void:
	game = game_
	world = world_
	for i in range(world.tree_info.size()):
		_cell_add(_tree_grid, world.tree_info[i]["p"], i)
	_place_terrazas()
	_place_tags()
	_place_furniture()
	_place_ramps()
	_place_repairs()

func _key(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / CELL), floori(p.y / CELL))

func _cell_add(grid: Dictionary, p: Vector2, item) -> void:
	var k := _key(p)
	if not grid.has(k):
		grid[k] = []
	grid[k].append(item)

# ================= street furniture =================
func _place_furniture() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for s in MapData.segs:
		var h: String = s.road["h"]
		if s.road["k"] != 0 or h.begins_with("motorway"):
			continue
		var d: Vector2 = s.b - s.a
		var length := d.length()
		if length < 12.0:
			continue
		var room: float = minf(float(MapData.clr[s.na]), float(MapData.clr[s.nb]))
		var edge: float = minf(s.hw, maxf(1.8, room - 0.5))        # where the asphalt ends on this stretch
		if room < edge + 1.1:
			continue                                               # no pavement here: facades right on the street
		var u := d / length
		var n := Vector2(-u.y, u.x)
		var side := 1.0 if rng.randf() < 0.5 else -1.0
		var along: Vector2 = s.a + u * length * rng.randf_range(0.3, 0.7)
		var roll := rng.randf()
		if roll < 0.10:
			_prop("sign", along + n * (edge + 0.55) * side, atan2(u.x, u.y) + (0.0 if side < 0.0 else PI), rng.randi() % 3)
		elif roll < 0.17 and room > edge + 1.7:
			var facing := -n * side
			_prop("bench", along + n * (edge + 1.1) * side, atan2(facing.x, facing.y), 0)
		elif roll < 0.28:
			_prop("bin", along + n * (edge + 0.6) * side, 0.0, 0)
	for req in world.extra_props:                 # what the hand-built places have standing by them in their photos
		_prop(String(req[0]), req[1], float(req[2]), int(req[3]))

func _prop(kind: String, p: Vector2, heading: float, variant: int) -> void:
	var b := RigidBody3D.new()
	var size := Vector3.ONE
	var rad := 0.55        # how close a car has to get to knock it over
	var heat := 5.0        # how much the police mind
	var lift := 0.0        # collider height, when it is not sitting on the ground
	match kind:
		"sign":
			size = Vector3(0.3, 2.6, 0.3)
			b.mass = 15.0
			b.add_child(Parts.part("cyl", 0x9aa0a6, Vector3(0, 1.2, 0), Vector3(0.045, 2.4, 0.045)))
			var face: int = [0xd23b2e, 0xf4f4f0, 0x2f6bff][variant]
			var rim: int = [0xf4f4f0, 0xd23b2e, 0xd23b2e][variant]
			for layer in [[rim, 0.36, 0.0], [face, 0.28, 0.02]]:
				var disc := Parts.part("cyl", layer[0], Vector3(0, 2.25, 0.04 + layer[2]), Vector3(layer[1], 0.03, layer[1]))
				disc.rotation.x = PI / 2.0
				b.add_child(disc)
		"bench":
			size = Vector3(1.7, 0.85, 0.55)
			b.mass = 45.0
			b.add_child(Parts.part("box", 0x8a5a2b, Vector3(0, 0.45, 0.05), Vector3(1.7, 0.08, 0.45)))
			b.add_child(Parts.part("box", 0x8a5a2b, Vector3(0, 0.75, -0.2), Vector3(1.7, 0.35, 0.07)))
			for sx in [-0.7, 0.7]:
				b.add_child(Parts.part("box", 0x33363b, Vector3(sx, 0.22, 0), Vector3(0.08, 0.45, 0.5)))
		"bin":
			size = Vector3(0.5, 0.9, 0.5)
			b.mass = 10.0
			heat = 3.0
			b.add_child(Parts.part("cyl", 0x3f7d4a, Vector3(0, 0.45, 0), Vector3(0.24, 0.85, 0.24)))
			b.add_child(Parts.part("cyl", 0x2c5a35, Vector3(0, 0.88, 0), Vector3(0.27, 0.06, 0.27)))
		"container":      # the big bins of the kerb: 0 beige with a green lid, 1 yellow (packaging), 2 blue (paper), 3 green
			size = Vector3(1.5, 1.45, 1.05)
			b.mass = 70.0
			heat = 6.0
			rad = 1.0
			var tub: int = [0xd9cfa8, 0xf0c21c, 0x2f63b5, 0x3f7d4a][variant % 4]
			var lid: int = [0x55b54a, 0xf0c21c, 0x2f63b5, 0x2c5a35][variant % 4]
			b.add_child(Parts.part("box", tub, Vector3(0, 0.62, 0), Vector3(1.45, 0.95, 0.95)))
			b.add_child(Parts.part("box", tub, Vector3(0, 0.2, 0), Vector3(1.25, 0.18, 0.8)))
			var top := Parts.part("box", lid, Vector3(0, 1.22, -0.04), Vector3(1.5, 0.3, 1.02))
			top.rotation.x = -0.12
			b.add_child(top)
			b.add_child(Parts.part("box", 0x2a2c30, Vector3(0, 0.75, 0.49), Vector3(0.14, 1.0, 0.06)))      # the bar the lorry lifts it by
			for sx in [-0.55, 0.55]:
				b.add_child(Parts.part("box", 0xf4f4f0, Vector3(sx, 0.5, 0.485), Vector3(0.12, 0.3, 0.02)))
				b.add_child(Parts.part("box", 0xd23b2e, Vector3(sx, 0.5, 0.49), Vector3(0.12, 0.08, 0.02)))
				b.add_child(Parts.part("cyl", 0x2a2c30, Vector3(sx, 0.07, 0.3), Vector3(0.07, 0.14, 0.07)))
				b.add_child(Parts.part("cyl", 0x2a2c30, Vector3(sx, 0.07, -0.3), Vector3(0.07, 0.14, 0.07)))
			if variant % 4 == 1:                      # (the yellow ones have their two round mouths)
				for sx in [-0.38, 0.38]:
					var mouth := Parts.part("cyl", 0xf08a1c, Vector3(sx, 1.2, 0.5), Vector3(0.16, 0.04, 0.16))
					mouth.rotation.x = PI / 2.0
					b.add_child(mouth)
		"bollard":        # 0 yellow, 1 dark iron
			size = Vector3(0.16, 0.85, 0.16)
			b.mass = 12.0
			heat = 2.0
			rad = 0.35
			b.add_child(Parts.part("cyl", [0xe6b422, 0x33363b][variant % 2], Vector3(0, 0.42, 0), Vector3(0.055, 0.84, 0.055)))
			b.add_child(Parts.part("cyl", [0xc99a18, 0xb5202a][variant % 2], Vector3(0, 0.7, 0), Vector3(0.06, 0.08, 0.06)))
		"psign":          # the blue square of a car park; variant 1: with the plate of a bay for the disabled under it
			size = Vector3(0.5, 2.7, 0.2)
			b.mass = 15.0
			b.add_child(Parts.part("cyl", 0x9aa0a6, Vector3(0, 1.25, 0), Vector3(0.04, 2.5, 0.04)))
			b.add_child(Parts.part("box", 0xf4f4f0, Vector3(0, 2.3, 0.04), Vector3(0.52, 0.52, 0.03)))
			b.add_child(Parts.part("box", 0x1f55c4, Vector3(0, 2.3, 0.05), Vector3(0.46, 0.46, 0.03)))
			var pl := Label3D.new()
			pl.text = "P"
			pl.font_size = 96
			pl.pixel_size = 0.004
			pl.outline_size = 0
			pl.shaded = false
			pl.position = Vector3(0, 2.3, 0.07)
			b.add_child(pl)
			if variant == 1:
				b.add_child(Parts.part("box", 0x1f55c4, Vector3(0, 1.85, 0.05), Vector3(0.46, 0.3, 0.03)))
				b.add_child(Parts.part("ball", 0xf4f4f0, Vector3(0.0, 1.93, 0.07), Vector3(0.07, 0.07, 0.02)))
				b.add_child(Parts.part("box", 0xf4f4f0, Vector3(0.0, 1.84, 0.07), Vector3(0.05, 0.12, 0.02)))
		"noparking":      # no parking: blue, ringed and crossed in red; variant 1: with the plate that says when
			size = Vector3(0.5, 2.7, 0.2)
			b.mass = 15.0
			b.add_child(Parts.part("cyl", 0x9aa0a6, Vector3(0, 1.25, 0), Vector3(0.04, 2.5, 0.04)))
			for layer in [[0xd23b2e, 0.3, 0.0], [0x1f55c4, 0.23, 0.012]]:
				var disc := Parts.part("cyl", layer[0], Vector3(0, 2.3, 0.04 + layer[2]), Vector3(layer[1], 0.03, layer[1]))
				disc.rotation.x = PI / 2.0
				b.add_child(disc)
			var bar := Parts.part("box", 0xd23b2e, Vector3(0, 2.3, 0.075), Vector3(0.52, 0.06, 0.02))
			bar.rotation.z = -PI / 4.0
			b.add_child(bar)
			if variant == 1:
				b.add_child(Parts.part("box", 0xf4f4f0, Vector3(0, 1.78, 0.05), Vector3(0.5, 0.34, 0.03)))
				for k in range(3):
					b.add_child(Parts.part("box", 0x33363b if k > 0 else 0xd23b2e, Vector3(0, 1.87 - k * 0.09, 0.07), Vector3(0.4, 0.035, 0.01)))
		"heart":          # the big heart that plastic bottle tops are thrown into, for some good cause
			size = Vector3(1.1, 1.3, 0.45)
			b.mass = 30.0
			heat = 4.0
			rad = 0.7
			for sx in [-1.0, 1.0]:
				b.add_child(Parts.part("ball", 0x2f4fa8, Vector3(sx * 0.26, 0.95, 0), Vector3(0.34, 0.34, 0.2)))
			var point := Parts.part("cone", 0x2f4fa8, Vector3(0, 0.48, 0), Vector3(0.55, 0.85, 0.2))
			point.rotation.x = PI
			b.add_child(point)
			b.add_child(Parts.part("box", 0xdfe6f2, Vector3(0, 0.85, 0.2), Vector3(0.5, 0.3, 0.02)))
			b.add_child(Parts.part("box", 0x33363b, Vector3(0, 0.04, 0), Vector3(0.7, 0.08, 0.45)))
		"bikerack":       # a row of hoops to chain a bicycle to
			size = Vector3(2.0, 0.8, 0.5)
			b.mass = 25.0
			heat = 3.0
			rad = 0.9
			for k in range(4):
				for sz in [-0.2, 0.2]:
					b.add_child(Parts.part("cyl", 0x8a8f94, Vector3(-0.75 + k * 0.5, 0.38, sz), Vector3(0.025, 0.76, 0.025)))
				b.add_child(Parts.part("box", 0x8a8f94, Vector3(-0.75 + k * 0.5, 0.76, 0), Vector3(0.05, 0.05, 0.45)))
			b.add_child(Parts.part("box", 0x8a8f94, Vector3(0, 0.03, 0), Vector3(1.9, 0.05, 0.06)))
		"valla":          # a yellow works fence; variant 1: with the plate of the firm on it (blank)
			size = Vector3(2.5, 1.05, 0.35)
			b.mass = 14.0
			heat = 3.0
			rad = 1.2
			for y in [0.25, 1.0]:
				b.add_child(Parts.part("box", 0xe9b21c, Vector3(0, y, 0), Vector3(2.5, 0.05, 0.05)))
			for k in range(11):
				b.add_child(Parts.part("box", 0xe9b21c, Vector3(-1.23 + k * 0.246, 0.62, 0), Vector3(0.035 if k % 10 != 0 else 0.05, 0.75 if k % 10 != 0 else 1.0, 0.035)))
			for sx in [-1.05, 1.05]:
				b.add_child(Parts.part("box", 0xe9b21c, Vector3(sx, 0.03, 0), Vector3(0.05, 0.05, 0.6)))
			if variant == 1:
				b.add_child(Parts.part("box", 0xf4f4f0, Vector3(0, 0.75, 0.03), Vector3(0.6, 0.3, 0.02)))
				b.add_child(Parts.part("box", 0x2f63b5, Vector3(0, 0.84, 0.045), Vector3(0.6, 0.08, 0.01)))
		"espejo":         # the round mirror of a blind corner, on its post
			size = Vector3(0.7, 2.9, 0.25)
			b.mass = 16.0
			b.add_child(Parts.part("cyl", 0x9aa0a6, Vector3(0, 1.3, 0), Vector3(0.04, 2.6, 0.04)))
			for layer in [[0xd23b2e, 0.36, 0.0], [0xf4f4f0, 0.31, 0.012], [0xa9c4d6, 0.27, 0.024]]:
				var glass := Parts.part("cyl", layer[0], Vector3(0, 2.55, 0.06 + layer[2]), Vector3(layer[1], 0.03, layer[1]))
				glass.rotation.x = PI / 2.0
				b.add_child(glass)
			b.add_child(Parts.part("ball", 0xdfeaf2, Vector3(-0.08, 2.63, 0.1), Vector3(0.09, 0.07, 0.02)))
		"paso":           # a pedestrian crossing: the blue square with its white triangle; variant 1: on a yellow board
			size = Vector3(0.6, 2.9, 0.2)
			b.mass = 15.0
			b.add_child(Parts.part("cyl", 0x9aa0a6, Vector3(0, 1.3, 0), Vector3(0.04, 2.6, 0.04)))
			if variant == 1:
				b.add_child(Parts.part("box", 0xe6d21c, Vector3(0, 2.35, 0.03), Vector3(0.72, 0.9, 0.03)))
			b.add_child(Parts.part("box", 0x1f55c4, Vector3(0, 2.4, 0.05), Vector3(0.56, 0.56, 0.03)))
			var tri := Parts.part("cone", 0xf4f4f0, Vector3(0, 2.4, 0.06), Vector3(0.26, 0.4, 0.01))
			b.add_child(tri)
			b.add_child(Parts.part("box", 0x22252a, Vector3(0, 2.34, 0.075), Vector3(0.05, 0.2, 0.01)))
		"ceda":           # give way, and under it no turning left
			size = Vector3(0.6, 3.0, 0.2)
			b.mass = 15.0
			b.add_child(Parts.part("cyl", 0x9aa0a6, Vector3(0, 1.4, 0), Vector3(0.04, 2.8, 0.04)))
			for layer in [[0xd23b2e, 0.4, 0.0], [0xf4f4f0, 0.27, 0.012]]:
				var gw := Parts.part("cone", layer[0], Vector3(0, 2.65, 0.05 + layer[2]), Vector3(layer[1], layer[1] * 1.5, 0.01))
				gw.rotation.z = PI
				b.add_child(gw)
			for layer in [[0xd23b2e, 0.27, 0.0], [0xf4f4f0, 0.2, 0.012]]:
				var nt := Parts.part("cyl", layer[0], Vector3(0, 1.95, 0.05 + layer[2]), Vector3(layer[1], 0.03, layer[1]))
				nt.rotation.x = PI / 2.0
				b.add_child(nt)
			var slash := Parts.part("box", 0xd23b2e, Vector3(0, 1.95, 0.08), Vector3(0.42, 0.045, 0.01))
			slash.rotation.z = -PI / 4.0
			b.add_child(slash)
		"table":
			size = Vector3(0.85, 0.76, 0.85)
			b.mass = 12.0
			heat = 4.0
			b.add_child(Parts.part("cyl", 0xd9dde2, Vector3(0, 0.74, 0), Vector3(0.45, 0.04, 0.45)))
			b.add_child(Parts.part("cyl", 0x8a8f94, Vector3(0, 0.37, 0), Vector3(0.04, 0.72, 0.04)))
			b.add_child(Parts.part("cyl", 0x8a8f94, Vector3(0, 0.02, 0), Vector3(0.26, 0.03, 0.26)))
			if variant % 2 == 0:      # somebody's caña and a bottle
				b.add_child(Parts.part("cyl", 0x5a7a1e, Vector3(0.14, 0.87, 0.06), Vector3(0.035, 0.22, 0.035)))
			b.add_child(Parts.part("cyl", 0xe8b93a, Vector3(-0.12, 0.83, -0.1), Vector3(0.04, 0.13, 0.04)))
		"chair":
			size = Vector3(0.45, 0.82, 0.45)
			b.mass = 4.0
			heat = 2.0
			rad = 0.45
			b.add_child(Parts.part("box", 0xc4c8cc, Vector3(0, 0.45, 0), Vector3(0.42, 0.04, 0.42)))
			b.add_child(Parts.part("box", 0xc4c8cc, Vector3(0, 0.66, -0.2), Vector3(0.42, 0.34, 0.04)))
			for lx in [-0.18, 0.18]:
				for lz in [-0.18, 0.18]:
					b.add_child(Parts.part("box", 0x8a8f94, Vector3(lx, 0.22, lz), Vector3(0.03, 0.45, 0.03)))
		"parasol":
			size = Vector3(0.25, 2.3, 0.25)
			b.mass = 8.0
			heat = 3.0
			rad = 0.7
			var canopy: int = [0xd23b2e, 0xf4f4f0, 0x2f8f5b, 0xe6b422][variant % 4]
			b.add_child(Parts.part("cyl", 0x8a8f94, Vector3(0, 1.15, 0), Vector3(0.035, 2.3, 0.035)))
			b.add_child(Parts.part("cone", canopy, Vector3(0, 2.25, 0), Vector3(1.35, 0.5, 1.35)))
		"toldo":      # an awning over the whole terraza: four poles and a striped canvas. You can walk under it.
			size = Vector3(8.0, 0.14, 3.2)
			b.mass = 40.0
			heat = 8.0
			rad = 2.3
			lift = 2.45
			var stripe: int = [0x2f8f5b, 0xd23b2e, 0x2f6bb5, 0xe6b422][variant % 4]
			b.add_child(Parts.part("box", 0xf4f1e8, Vector3(0, 2.45, 0), Vector3(8.0, 0.08, 3.2)))
			for k in range(-3, 4, 2):
				b.add_child(Parts.part("box", stripe, Vector3(k * 1.0, 2.46, 0), Vector3(0.9, 0.09, 3.22)))
			b.add_child(Parts.part("box", stripe, Vector3(0, 2.3, 1.6), Vector3(8.0, 0.3, 0.05)))
			for px in [-3.8, 3.8]:
				for pz in [-1.5, 1.5]:
					b.add_child(Parts.part("cyl", 0x8a8f94, Vector3(px, 1.2, pz), Vector3(0.05, 2.4, 0.05)))
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	cs.position.y = lift if lift > 0.0 else size.y / 2.0
	b.add_child(cs)
	b.set_meta("rad", rad)
	b.set_meta("heat", heat)
	b.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	b.freeze = true
	b.collision_layer = 16            # only people on foot bump into standing furniture
	b.collision_mask = 0
	b.position = MapData.at(p)
	b.rotation.y = heading
	b.set_meta("p", p)
	b.set_meta("kind", kind)
	add_child(b)
	_cell_add(_grid, p, b)

func _knock(b: RigidBody3D, v: Vector3) -> void:
	_grid[_key(b.get_meta("p"))].erase(b)
	b.freeze = false
	b.collision_layer = 32
	b.collision_mask = 1 | 2 | 32
	b.linear_velocity = v * 0.9 + Vector3(randf_range(-2, 2), 3.0 + v.length() * 0.18, randf_range(-2, 2))
	b.angular_velocity = Vector3(randf_range(-7, 7), randf_range(-4, 4), randf_range(-7, 7))
	broken_count += 1
	get_tree().create_timer(40.0).timeout.connect(b.queue_free)

func _fell(i: int, c) -> void:
	var t: Dictionary = world.fell_tree(i)
	var k: int = t["kind"]
	var s: float = t["s"]
	var b := RigidBody3D.new()
	b.mass = 120.0
	var th := 2.4 if k == 0 else (1.3 if k == 1 else 1.0)
	b.add_child(Parts.part("cyl", 0x7a5536, Vector3(0, th / 2.0 - 1.5, 0), Vector3(0.28, th, 0.28)))
	var lcol := [0x6fb24c, 0x93a070, 0x3d7044]
	if k == 0:
		b.add_child(Parts.part("ball", lcol[0], Vector3(0, 0.7 + 1.9 * s, 0), Vector3(2.2, 2.1, 2.2) * s))
	elif k == 1:
		b.add_child(Parts.part("ball", lcol[1], Vector3(0, -0.3 + 1.2 * s, 0), Vector3(2.0, 1.35, 2.0) * s))
	else:
		b.add_child(Parts.part("cone", lcol[2], Vector3(0, -0.9 + 3.6 * s, 0), Vector3(1.1, 7.2 * s, 1.1)))
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.35
	cyl.height = 3.0
	cs.shape = cyl
	b.add_child(cs)
	b.collision_layer = 32
	b.collision_mask = 1 | 32          # falls on the ground and other debris; cars drive over the wreck
	b.position = MapData.at(t["p"], 1.5)
	add_child(b)
	var v: Vector3 = c.linear_velocity
	var flat := Vector3(v.x, 0, v.z)
	b.linear_velocity = flat * 0.5 + Vector3(0, 1.5, 0)
	b.angular_velocity = Vector3.UP.cross(flat.normalized()) * 2.5      # topples away from the car
	broken_count += 1
	get_tree().create_timer(40.0).timeout.connect(b.queue_free)

## called every physics tick for a moving car. Returns [furniture knocked, trees felled] this tick.
func sweep(c) -> Array:
	var knocked := 0
	var felled := 0
	var heat := 0.0
	var terraza := false
	var speed: float = c.vel.length()
	if speed < 1.2:
		return [0, 0, 0.0, false]
	var tree_speed := 3.0 if c.spec.get("tractor", false) else 7.0
	for o in [c.off, -c.off]:
		var q: Vector2 = c.p + Vector2(sin(c.h), cos(c.h)) * o + c.vel * 0.05
		var k := _key(q)
		for ax in [-1, 0, 1]:
			for az in [-1, 0, 1]:
				var cell := k + Vector2i(ax, az)
				var list = _grid.get(cell)
				if list != null:
					for b in list.duplicate():
						if (b.get_meta("p") as Vector2).distance_to(q) < c.r + float(b.get_meta("rad")):
							heat += float(b.get_meta("heat"))
							terraza = terraza or b.get_meta("kind") in ["table", "chair", "parasol", "toldo"]
							_knock(b, c.linear_velocity)
							knocked += 1
				if speed < tree_speed:
					continue
				var trees = _tree_grid.get(cell)
				if trees != null:
					for i in trees:
						var t: Dictionary = world.tree_info[i]
						if not t["down"] and (t["p"] as Vector2).distance_to(q) < c.r + 0.6:
							_fell(i, c)
							felled += 1
	return [knocked, felled, heat, terraza]

## a punch on foot: knocks over whatever street furniture is within arm's reach. Returns [count, heat].
func punch(at: Vector2, dir: Vector2) -> Array:
	var count := 0
	var heat := 0.0
	var k := _key(at)
	for ax in [-1, 0, 1]:
		for az in [-1, 0, 1]:
			var list = _grid.get(k + Vector2i(ax, az))
			if list == null:
				continue
			for b in list.duplicate():
				if (b.get_meta("p") as Vector2).distance_to(at) < 0.75 + float(b.get_meta("rad")) and b.get_meta("kind") != "toldo":
					heat += float(b.get_meta("heat"))
					_knock(b, Vector3(dir.x, 0, dir.y) * 5.0)
					count += 1
	return [count, heat]

# ================= terrazas =================
## Tables, chairs and shade out on the street in front of the bars, with people at them. All of it breaks.
func _place_terrazas() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	# terrazas that a hand-built place asks for, exactly where it wants them
	for req in world.extra_terrazas:
		var dir: Vector2 = (req[1] as Vector2).normalized()
		_make_terraza(req[0], dir, Vector2(-dir.y, dir.x), rng)
	# the real bars and restaurants first
	for q in MapData.pois:
		if not (q["t"] in ["pub", "bar", "restaurant", "cafe", "biergarten"]):
			continue
		var at := Vector2(q["x"], q["z"])
		var near: Array = MapData.segs.filter(func(s): return ((s.a + s.b) / 2.0).distance_to(at) < 80.0)
		near.sort_custom(func(a, b): return ((a.a + a.b) / 2.0).distance_to(at) < ((b.a + b.b) / 2.0).distance_to(at))
		for s in near:
			if _try_terraza(s, rng, 40.0):
				break
	# and then a dozen more around the centre: this is La Mancha, there is always another bar
	var tries := 0
	while terrazas.size() < 16 and tries < 1500:
		tries += 1
		var s = MapData.segs[rng.randi() % MapData.segs.size()]
		if ((s.a + s.b) / 2.0).length() < 800.0:
			_try_terraza(s, rng, 110.0)

func _try_terraza(s, rng: RandomNumberGenerator, spacing: float) -> bool:
	var h: String = s.road["h"]
	if s.road["k"] == 1 or h.begins_with("motorway") or h == "service":
		return false
	var d: Vector2 = s.b - s.a
	var length := d.length()
	if length < 14.0:
		return false
	var u := d / length
	var n := Vector2(-u.y, u.x)
	var mid: Vector2 = (s.a + s.b) / 2.0
	var edge: float = minf(s.hw, maxf(1.8, minf(float(MapData.clr[s.na]), float(MapData.clr[s.nb])) - 0.5)) if s.road["k"] == 0 else 0.5
	for t in terrazas:
		if (t["p"] as Vector2).distance_to(mid) < spacing:
			return false
	for pl in game.places.values():
		if (pl["p"] as Vector2).distance_to(mid) < 30.0:
			return false
	for side in [1.0, -1.0]:
		var c: Vector2 = mid + n * side * (edge + 2.3)
		var fits := true
		for along in [-3.6, 0.0, 3.6]:
			for across in [-1.3, 1.3]:
				if MapData.room_at(c + u * along + n * across) < 0.9:
					fits = false
		if not fits:
			continue
		_make_terraza(c, u, n, rng)
		return true
	return false

# ================= peña graffiti =================
## The names of the peñas sprayed on walls that face a street. For now a tag is just the name.
func _place_tags() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var cands: Array = []
	for w in MapData.walls:
		for i in range(w.size() / 7):
			var o := i * 7
			var a := Vector2(w[o], w[o + 1])
			var b := Vector2(w[o + 2], w[o + 3])
			var length := a.distance_to(b)
			if length < 6.5 or float(w[o + 4]) < 3.0:
				continue
			var mid := (a + b) / 2.0
			if mid.length() > 1000.0:
				continue
			var n := Vector2(b.y - a.y, -(b.x - a.x)).normalized()      # outwards (walls are baked counter-clockwise)
			if MapData.road_edge_dist(mid + n * 2.5) > 2.5 or MapData.room_at(mid + n * 1.2) < 0.9:
				continue                                                 # must face a street you can stand in
			cands.append([mid, n, length])
	for i in range(cands.size() - 1, 0, -1):          # shuffle
		var j := rng.randi() % (i + 1)
		var tmp = cands[i]; cands[i] = cands[j]; cands[j] = tmp
	for cnd in cands:
		if tags.size() >= 28:
			break
		var mid: Vector2 = cnd[0]
		var n: Vector2 = cnd[1]
		var ok := true
		for t in tags:
			if (t["p"] as Vector2).distance_to(mid) < 60.0:
				ok = false
		if not ok:
			continue
		var label := Label3D.new()
		label.font_size = 110
		label.outline_size = 26
		label.shaded = false
		label.double_sided = false
		label.outline_modulate = Color(0.1, 0.08, 0.08)
		label.position = Vector3(mid.x + n.x * 0.06, MapData.height(mid + n * 0.4) + 1.75, mid.y + n.y * 0.06)
		label.rotation = Vector3(0, atan2(n.x, n.y), rng.randf_range(-0.09, 0.09))
		label.set_meta("room", float(cnd[2]) - 1.2)
		add_child(label)
		var t := {"p": mid + n * 1.1, "label": label, "owner": 0}
		tags.append(t)
		_style_tag(t)

func _style_tag(t: Dictionary) -> void:
	var label: Label3D = t["label"]
	var name: String = Creator.PENAS[t["owner"]]
	label.text = name
	label.modulate = Creator.PENA_COLORS[t["owner"]]
	label.pixel_size = minf(0.011, float(label.get_meta("room")) / (name.length() * 62.0))      # fit the wall

## at the start of a game: every wall belongs to somebody else's peña
func assign_tags(mine: int) -> void:
	for t in tags:
		t["owner"] = (mine + 1 + randi() % (Creator.PENAS.size() - 1)) % Creator.PENAS.size()
		_style_tag(t)

func paint(t: Dictionary, mine: int) -> void:
	t["owner"] = mine
	_style_tag(t)

## the nearest tag within reach that is not yours yet, or null
func tag_near(p: Vector2, mine: int):
	for t in tags:
		if t["owner"] != mine and (t["p"] as Vector2).distance_to(p) < 2.4:
			return t
	return null

func tags_owned(mine: int) -> int:
	var n := 0
	for t in tags:
		if t["owner"] == mine:
			n += 1
	return n

## three tables with chairs, shade and customers, centred on c and strung out along u
func _make_terraza(c: Vector2, u: Vector2, n: Vector2, rng: RandomNumberGenerator) -> void:
	var style := rng.randi() % 4
	var awning := rng.randf() < 0.45
	if awning:
		_prop("toldo", c, atan2(u.x, u.y) + PI / 2.0, style)
	for i in range(3):
		var tp: Vector2 = c + u * (i - 1) * 2.7 + n * rng.randf_range(-0.35, 0.35)
		_prop("table", tp, rng.randf() * TAU, i)
		if not awning:
			_prop("parasol", tp + Vector2(0.05, 0.05), 0.0, style)
		var seats := 2 + rng.randi() % 3
		var a0 := rng.randf() * TAU
		for k in range(seats):
			var ang := a0 + k * TAU / seats
			var cp: Vector2 = tp + Vector2(sin(ang), cos(ang)) * 0.82
			_prop("chair", cp, ang + PI, 0)
		if rng.randf() < 0.8:      # somebody standing at the table, mid-argument
			var ga := a0 + PI / seats
			game.spawn_neighbour(tp + Vector2(sin(ga), cos(ga)) * 1.15, true)
	terrazas.append({"p": c, "u": u})

# ================= jumps: tipped trailers parked along the streets (still called ramps in the code) =================
func _place_ramps() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var cands: Array = []
	for s in MapData.segs:
		var h: String = s.road["h"]
		if s.road["k"] != 0 or h.begins_with("motorway") or h == "service":
			continue
		if s.a.distance_to(s.b) < 38.0 or minf(float(MapData.clr[s.na]), float(MapData.clr[s.nb])) < 5.5:
			continue
		cands.append(s)
	cands.shuffle()
	for s in cands:
		if ramps.size() >= 16:
			break
		var mid: Vector2 = (s.a + s.b) / 2.0
		var ok := true
		for r in ramps:
			if (r["p"] as Vector2).distance_to(mid) < 230.0:
				ok = false
		for pl in game.places.values():
			if (pl["p"] as Vector2).distance_to(mid) < 70.0:
				ok = false
		for c in game.cars:                      # not where somebody has already parked
			if c.p.distance_to(mid) < 14.0:
				ok = false
		if not ok:
			continue
		var u: Vector2 = (s.b - s.a).normalized() * (1.0 if rng.randf() < 0.5 else -1.0)
		var right := Vector2(u.y, -u.x)
		_trailer(mid + right * s.hw * 0.45, atan2(u.x, u.y))
	for req in world.extra_ramps:               # the builders' skips seen in the street photos (after the trailers: the first ramp stays a trailer)
		_skip(req[0], float(req[1]))

## A builder's skip at the kerb, heaped with rubble, and the scaffold boards somebody propped against it to wheel the
## barrow up (the user's idea, 14 November 2026: a ramp that looks as if it had every right to be there). Drive up the
## boards, over the rubble and off the far end.
func _skip(p: Vector2, heading: float) -> void:
	var w := 2.3
	var l := 8.2
	var hh := 1.45
	var pts := PackedVector3Array([Vector3(-w / 2, 0, -l / 2), Vector3(w / 2, 0, -l / 2), Vector3(-w / 2, 0, l / 2), Vector3(w / 2, 0, l / 2), Vector3(-w / 2, hh, l / 2), Vector3(w / 2, hh, l / 2)])
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := ConvexPolygonShape3D.new()
	shape.points = pts
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	var run := sqrt(l * l + hh * hh)
	var tilt := Node3D.new()       # what lies on the slope: +z runs up it, from the road (-run/2) to the top (+run/2)
	tilt.position = Vector3(0, hh / 2.0, 0)
	tilt.rotation.x = -atan2(hh, l)
	body.add_child(tilt)
	# the skip: the far 3.4 m. Rusty yellow, its ends sloping, a lip round the top and the lugs it is lifted by
	var sz := l / 2.0 - 1.7       # its middle
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw := w / 2.0
	var top0 := hh * (sz - 1.7 + l / 2.0) / l - 0.04      # (its rim follows the slope, a hand under the rubble)
	var top1 := hh - 0.04
	var c := [Vector3(-hw + 0.15, 0.0, sz - 1.25), Vector3(hw - 0.15, 0.0, sz - 1.25), Vector3(hw - 0.15, 0.0, sz + 1.25), Vector3(-hw + 0.15, 0.0, sz + 1.25),
		Vector3(-hw, top0, sz - 1.7), Vector3(hw, top0, sz - 1.7), Vector3(hw, top1, sz + 1.7), Vector3(-hw, top1, sz + 1.7)]
	for f in [[0, 1, 5, 4], [1, 2, 6, 5], [2, 3, 7, 6], [3, 0, 4, 7]]:
		var nrm: Vector3 = ((c[f[1]] as Vector3) - (c[f[0]] as Vector3)).cross((c[f[3]] as Vector3) - (c[f[0]] as Vector3)).normalized()
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_normal(-nrm)
			st.add_vertex(c[f[k]])
		for k in [0, 2, 1, 0, 3, 2]:
			st.set_normal(nrm)
			st.add_vertex(c[f[k]])
	var tub := MeshInstance3D.new()
	tub.mesh = st.commit()
	var paint := Parts.mat(0xd9a521).duplicate()
	(paint as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	tub.material_override = paint
	body.add_child(tub)
	for sx in [-1.0, 1.0]:
		tilt.add_child(Parts.part("box", 0xb98a1c, Vector3(sx * hw, -0.02, run / 2.0 - 1.75), Vector3(0.09, 0.09, 3.5)))       # the lip
		for dz in [-0.9, 0.9]:
			body.add_child(Parts.part("box", 0x6a5a3a, Vector3(sx * (hw + 0.04), 0.7, sz + dz), Vector3(0.1, 0.16, 0.2)))        # lugs
		body.add_child(Parts.part("box", 0x8a6a1c, Vector3(sx * (hw - 0.02), 0.5, sz), Vector3(0.05, 0.9, 0.08)))               # a rib
	# the rubble it is heaped with, level with the boards: broken brick, plaster, a sack or two
	tilt.add_child(Parts.part("box", 0xb9aa94, Vector3(0, -0.04, run / 2.0 - 1.75), Vector3(w - 0.12, 0.08, 3.5)))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(p)
	for k in range(26):
		var lump := Parts.part("box", [0xb5583c, 0xd9d2c4, 0x9a938a, 0xc9a070, 0x8a4a34][rng.randi() % 5],
			Vector3(rng.randf_range(-hw + 0.25, hw - 0.25), 0.01, run / 2.0 - rng.randf_range(0.2, 3.3)), Vector3(rng.randf_range(0.15, 0.4), 0.05, rng.randf_range(0.12, 0.35)))
		lump.rotation.y = rng.randf() * PI
		tilt.add_child(lump)
	# the boards: three scaffold planks side by side from the road up to the rim, steel bands at their ends, on two tubes
	var bl := run - 3.45
	for k in range(3):
		var bx := (k - 1) * 0.74
		var plank := Parts.part("box", [0xc9a56a, 0xb98f58, 0xd2b078][k], Vector3(bx, 0.0, -run / 2.0 + bl / 2.0), Vector3(0.7, 0.05, bl))
		tilt.add_child(plank)
		for ez in [0.06, bl - 0.06]:
			tilt.add_child(Parts.part("box", 0x8a8f94, Vector3(bx, 0.005, -run / 2.0 + ez), Vector3(0.71, 0.055, 0.08)))
	for tz in [bl * 0.45, bl * 0.9]:
		var tube := Parts.part("cyl", 0x9aa0a6, Vector3(0, -0.07, -run / 2.0 + tz), Vector3(0.05, w + 0.3, 0.05))
		tube.rotation.z = PI / 2.0
		tilt.add_child(tube)
	# what holds them up: a trestle of scaffold tube half way, and the heap of sand the skip came with
	var mz := -l / 2.0 + bl * 0.45
	var mh := hh * (mz + l / 2.0) / l
	for sx in [-1.0, 1.0]:
		body.add_child(Parts.part("cyl", 0x9aa0a6, Vector3(sx * (hw + 0.05), mh / 2.0, mz), Vector3(0.045, mh + 0.1, 0.045)))
		var brace := Parts.part("cyl", 0x9aa0a6, Vector3(sx * (hw + 0.05), mh / 2.0, mz + 0.5), Vector3(0.035, 1.3, 0.035))
		brace.rotation.x = 0.9
		body.add_child(brace)
	body.add_child(Parts.part("cone", 0xd9c08a, Vector3(hw + 0.9, 0.35, sz - 0.6), Vector3(1.1, 0.7, 1.3)))
	body.add_child(Parts.part("cone", 0xd9c08a, Vector3(hw + 0.5, 0.2, sz - 1.6), Vector3(0.7, 0.4, 0.8)))
	var up := MapData.normal(p)                  # standing on the slope of the street
	var fwd := Vector3(sin(heading), 0.0, cos(heading))
	fwd = (fwd - up * fwd.dot(up)).normalized()
	body.transform = Transform3D(Basis(up.cross(fwd), up, fwd), MapData.at(p))
	add_child(body)
	ramps.append({"p": p, "h": heading, "skip": true})

## A tipping trailer left "conveniently" parked at the kerb: the bed is tipped up, the tailgate is down on the road
## and the front board went missing years ago. Drive up the back of it and off the top.
func _trailer(p: Vector2, heading: float) -> void:
	var w := 3.0
	var l := 7.5
	var hh := 1.5
	var pts := PackedVector3Array([Vector3(-w / 2, 0, -l / 2), Vector3(w / 2, 0, -l / 2), Vector3(-w / 2, 0, l / 2), Vector3(w / 2, 0, l / 2), Vector3(-w / 2, hh, l / 2), Vector3(w / 2, hh, l / 2)])
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := ConvexPolygonShape3D.new()
	shape.points = pts
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	var steel := 0xbfc4c9          # galvanised
	var dark := 0x7d848b
	var run := sqrt(l * l + hh * hh)
	var bed := Node3D.new()        # everything that tips: +z runs up the slope
	bed.position = Vector3(0, hh / 2.0, 0)
	bed.rotation.x = -atan2(hh, l)
	body.add_child(bed)
	bed.add_child(Parts.part("box", steel, Vector3(0, -0.03, run * 0.07), Vector3(w, 0.06, run * 0.86)))          # the bed
	bed.add_child(Parts.part("box", dark, Vector3(0, -0.025, -run * 0.43), Vector3(w, 0.05, run * 0.14)))         # the tailgate, let down as a ramp
	for k in range(4):
		bed.add_child(Parts.part("box", steel, Vector3(0, 0.005, -run * (0.49 - k * 0.034)), Vector3(w * 0.9, 0.02, 0.05)))
	for sx in [-1.0, 1.0]:
		var edge: float = sx * (w / 2.0 - 0.03)
		bed.add_child(Parts.part("box", steel, Vector3(edge, 0.21, run * 0.07), Vector3(0.06, 0.42, run * 0.86)))  # side boards
		bed.add_child(Parts.part("box", 0x26262b, Vector3(edge, 0.15, run * 0.07), Vector3(0.07, 0.07, run * 0.86)))
		bed.add_child(Parts.part("box", dark, Vector3(edge, 0.25, -run * 0.36), Vector3(0.09, 0.5, 0.09)))
		bed.add_child(Parts.part("box", dark, Vector3(edge, 0.25, run * 0.5), Vector3(0.09, 0.5, 0.09)))
		bed.add_child(Parts.part("box", 0xf08a2a, Vector3(edge + sx * 0.01, 0.3, run * 0.25), Vector3(0.07, 0.08, 0.14)))   # reflectors
		bed.add_child(Parts.part("box", 0xd23b2e, Vector3(edge, 0.3, -run * 0.365), Vector3(0.1, 0.12, 0.05)))
		# what does not tip: wheels and mudguards
		var wx: float = sx * (w / 2.0 - 0.3)
		var tyre := Parts.part("cyl", 0x2b2b30, Vector3(wx, 0.36, 1.1), Vector3(0.36, 0.26, 0.36))
		tyre.rotation.z = PI / 2.0
		body.add_child(tyre)
		var hub := Parts.part("cyl", steel, Vector3(wx + sx * 0.1, 0.36, 1.1), Vector3(0.2, 0.08, 0.2))
		hub.rotation.z = PI / 2.0
		body.add_child(hub)
		body.add_child(Parts.part("box", steel, Vector3(wx, 0.76, 1.1), Vector3(0.36, 0.05, 1.0)))
	body.add_child(Parts.part("box", dark, Vector3(0, 0.5, 1.75), Vector3(1.6, 0.1, 4.2)))                      # chassis
	body.add_child(Parts.part("cyl", dark, Vector3(0, 0.95, 3.1), Vector3(0.06, 0.8, 0.06)))                    # the ram that tips the bed
	body.add_child(Parts.part("box", dark, Vector3(0, 0.5, l / 2.0 + 0.9), Vector3(0.12, 0.1, 2.2)))            # drawbar
	body.add_child(Parts.part("ball", 0x3a3a40, Vector3(0, 0.53, l / 2.0 + 2.0), Vector3.ONE * 0.09))
	body.add_child(Parts.part("box", dark, Vector3(0.2, 0.31, l / 2.0 + 1.3), Vector3(0.05, 0.42, 0.05)))       # jockey wheel
	var jockey := Parts.part("cyl", 0x2b2b30, Vector3(0.2, 0.11, l / 2.0 + 1.3), Vector3(0.11, 0.07, 0.11))
	jockey.rotation.z = PI / 2.0
	body.add_child(jockey)
	var up := MapData.normal(p)                  # standing on the slope of the street
	var fwd := Vector3(sin(heading), 0.0, cos(heading))
	fwd = (fwd - up * fwd.dot(up)).normalized()
	body.transform = Transform3D(Basis(up.cross(fwd), up, fwd), MapData.at(p))
	add_child(body)
	ramps.append({"p": p, "h": heading})

# ================= repair points (talleres and gasolineras) =================
func _place_repairs() -> void:
	for q in MapData.pois:
		if not (q["t"] == "fuel" or q["t"] == "car_repair"):
			continue
		var r := MapData.nearest_road(Vector2(q["x"], q["z"]))
		var p: Vector2 = r["p"]
		var ok := (Vector2(q["x"], q["z"]) - p).length() < 120.0
		for pl in game.places.values():
			if (pl["p"] as Vector2).distance_to(p) < 45.0:
				ok = false
		for e in repairs:
			if (e["p"] as Vector2).distance_to(p) < 60.0:
				ok = false
		if not ok:
			continue
		add_repair(p)

## a garage with a bay inside (garage.gd): the car is mended in there, and there is no ring, just the spanner
func add_garage(gar) -> void:
	for e in repairs.duplicate():                 # no kerbside repair point next door to the real thing
		if (e["p"] as Vector2).distance_to(gar.mouth) < 90.0:
			e["node"].queue_free()
			repairs.erase(e)
	var g := Node3D.new()
	g.position = MapData.at(gar.spot)
	var spanner := Node3D.new()
	spanner.position.y = gar.top - 0.95
	spanner.scale = Vector3.ONE * 0.5
	spanner.add_child(Parts.part("box", 0xe8eef2, Vector3.ZERO, Vector3(0.28, 1.5, 0.14)))
	spanner.add_child(Parts.part("box", 0xe8eef2, Vector3(-0.22, 0.85, 0), Vector3(0.2, 0.45, 0.14)))
	spanner.add_child(Parts.part("box", 0xe8eef2, Vector3(0.22, 0.85, 0), Vector3(0.2, 0.45, 0.14)))
	spanner.rotation.z = 0.5
	g.add_child(spanner)
	add_child(g)
	repairs.append({"p": gar.spot, "node": g, "spin": spanner, "garage": gar})

## a place where cars are mended at the kerb: the blue ring with the spanner turning over it
func add_repair(p: Vector2) -> void:
	var g := Node3D.new()
	g.position = MapData.at(p)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.2, 0.8, 0.95, 0.35)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var ring := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 4.0; cm.bottom_radius = 4.0; cm.height = 5.0; cm.cap_top = false; cm.cap_bottom = false
	ring.mesh = cm
	ring.material_override = m
	ring.position.y = 2.5
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	g.add_child(ring)
	var spanner := Node3D.new()      # a chunky floating spanner
	spanner.position.y = 3.2
	spanner.add_child(Parts.part("box", 0xe8eef2, Vector3.ZERO, Vector3(0.28, 1.5, 0.14)))
	spanner.add_child(Parts.part("box", 0xe8eef2, Vector3(-0.22, 0.85, 0), Vector3(0.2, 0.45, 0.14)))
	spanner.add_child(Parts.part("box", 0xe8eef2, Vector3(0.22, 0.85, 0), Vector3(0.2, 0.45, 0.14)))
	spanner.rotation.z = 0.5
	g.add_child(spanner)
	add_child(g)
	repairs.append({"p": p, "node": g, "spin": spanner})

## spin the markers; returns the repair point the car is standing in, or null (the mending itself is game.gd's
## business: you sound the horn to have it done)
func repair_at(c, dt: float):
	var found = null
	for e in repairs:
		e["spin"].rotation.y += dt * 2.0
		if c == null:
			continue
		if e.has("garage"):                       # indoors: right in, and stopped
			if e["garage"].holds(c.p, c.spec["len"]) and c.vel.length() < 2.5:
				found = e
		elif (e["p"] as Vector2).distance_to(c.p) < 4.5 and c.vel.length() < 9.0:
			found = e
	return found
