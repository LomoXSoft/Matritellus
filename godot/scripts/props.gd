extends Node3D
## Things to hit and things to use: breakable street furniture and trees, jump ramps, and repair points.
## Street furniture stands frozen until a car touches it, then becomes a loose rigid body (layer 32) that tumbles away.

const Parts = preload("res://scripts/parts.gd")
const AcerasAltas = preload("res://scripts/aceras_altas.gd")
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
## Mended the next day (the user, 22 Nov 2026, asked when what you knock down comes back: "Al día siguiente"): what a car
## or a punch has knocked over lies there as before, and is cleared away after a while; the next day it is back in its
## place, each thing as soon as nobody is looking at it. The felled trees too, and the crossroads' traffic lights
## (cruce.gd repair(): anything of its own with an "on_knock" is its to put back, all of it at once).
var _down: Array = []        # {b: the piece, day: the day it was knocked over}
var _felled: Array = []      # {i: the tree, wreck: the falling one, day}
var _kept_day := -1          # the day something of its owner's own ("keep": the crossroads) was knocked down
var _mend_t := 0.0
const MEND_EVERY := 2.0

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

## how far a point is from a thing: from its middle, or for a long one (a fence) from the line of it
func _reach(b: Node, q: Vector2) -> float:
	var at: Vector2 = b.get_meta("p")
	var half: float = float(b.get_meta("half", 0.0))
	if half <= 0.0:
		return at.distance_to(q)
	var u: Vector2 = b.get_meta("along")
	return q.distance_to(at + u * clampf((q - at).dot(u), -half, half))

## (`on_floor`: it stands on what is walked on there -- the floor of a raised square, say -- and not on the ground under it)
func _prop(kind: String, p: Vector2, heading: float, variant: int, on_floor := false) -> void:
	var b := RigidBody3D.new()
	var size := Vector3.ONE
	var rad := 0.55        # how close a car has to get to knock it over
	var half := 0.0        # a long thing (a fence): this far either way along its heading, and rad is then from that line
	var heat := 5.0        # how much the police mind
	var lift := 0.0        # collider height, when it is not sitting on the ground
	var shapes: Array = []  # [size, position] of each box it is made of, when one box round it all would be too much
	var thin := -1.0       # how thick it is where a fist lands, when that is much less than `rad` (a fence: punch)
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
			rad = 0.25
			half = 1.25                          # (along its length: a car brushing past a metre off went through it)
			# Its shape, as it is: the panel of bars, a few centimetres thick, and the two feet that stick out at the bottom.
			# One box round it all was as deep as the feet all the way up, and a punch counted from far off (the user,
			# 17 Nov 2026: "Las hit-boxes de la vallas amarillas son enormes, puedes golpearlas desde muy lejos").
			shapes = [[Vector3(2.5, 1.0, 0.07), Vector3(0.0, 0.55, 0.0)], [Vector3(0.07, 0.07, 0.6), Vector3(-1.05, 0.035, 0.0)],
				[Vector3(0.07, 0.07, 0.6), Vector3(1.05, 0.035, 0.0)]]
			thin = 0.06
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
		"stop":           # STOP: the red octagon in its white rim, and the word
			size = Vector3(0.6, 2.8, 0.2)
			b.mass = 15.0
			b.add_child(Parts.part("cyl", 0x9aa0a6, Vector3(0, 1.25, 0), Vector3(0.04, 2.5, 0.04)))
			for layer in [[0xf4f4f0, 0.33, 0.0], [0xd23b2e, 0.29, 0.012]]:
				var cm := CylinderMesh.new()
				cm.top_radius = 1.0
				cm.bottom_radius = 1.0
				cm.height = 1.0
				cm.radial_segments = 8
				cm.rings = 1
				var oct := MeshInstance3D.new()
				oct.mesh = cm
				oct.material_override = Parts.mat(layer[0])
				oct.rotation.y = PI / 8.0             # (a flat edge on top, as the real ones)
				oct.scale = Vector3(layer[1], 0.03, layer[1])
				var face := Node3D.new()
				face.position = Vector3(0, 2.3, 0.04 + layer[2])
				face.rotation.x = PI / 2.0
				face.add_child(oct)
				b.add_child(face)
			var word := Label3D.new()
			word.text = "STOP"
			word.font_size = 64
			word.pixel_size = 0.0036
			word.modulate = Parts.col(0xffffff)
			word.outline_size = 0
			word.shaded = false
			word.double_sided = false
			word.position = Vector3(0, 2.3, 0.075)
			b.add_child(word)
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
			if variant >= 100:      # a square one over a table or two: the ten-thousands are the colour of its stripes, the hundreds its side in decimetres, the rest how high its canvas hangs (decimetres)
				var side: float = (floori(variant / 100.0) % 100) * 0.1
				var up: float = (variant % 100) * 0.1
				var band: int = [0x2f8f5b, 0xd23b2e, 0x2f6bb5, 0xe6b422][floori(variant / 10000.0) % 4]
				size = Vector3(side, 0.12, side)
				b.mass = 26.0
				heat = 6.0
				rad = side / 2.0 + 0.3
				lift = up
				b.add_child(Parts.part("box", 0xf4f1e8, Vector3(0, up, 0), Vector3(side, 0.08, side)))
				var bands: int = roundi(side / 0.55) | 1          # (an odd number of bands: white at both edges)
				for k in range(1, bands, 2):
					b.add_child(Parts.part("box", band, Vector3((k + 0.5) * side / bands - side / 2.0, up + 0.01, 0), Vector3(side / bands, 0.09, side + 0.02)))
				for pz in [-1.0, 1.0]:                            # (the strip that hangs at each end)
					b.add_child(Parts.part("box", band, Vector3(0, up - 0.15, pz * side / 2.0), Vector3(side, 0.3, 0.05)))
				for px in [-1.0, 1.0]:
					for pz in [-1.0, 1.0]:
						b.add_child(Parts.part("cyl", 0x8a8f94, Vector3(px * (side / 2.0 - 0.1), up / 2.0, pz * (side / 2.0 - 0.1)), Vector3(0.05, up, 0.05)))
			else:
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
	if shapes.is_empty():
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		cs.shape = box
		cs.position.y = lift if lift > 0.0 else size.y / 2.0
		b.add_child(cs)
	else:
		for sh in shapes:
			var cs := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = sh[0]
			cs.shape = box
			cs.position = sh[1]
			b.add_child(cs)
	if thin >= 0.0:
		b.set_meta("thin", thin)
	b.set_meta("rad", rad)
	b.set_meta("half", half)
	b.set_meta("along", Vector2(cos(heading), -sin(heading)))
	b.set_meta("heat", heat)
	b.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	b.freeze = true
	b.collision_layer = 16            # only people on foot bump into standing furniture
	b.collision_mask = 0
	b.position = Vector3(p.x, MapData.foot(p), p.y) if (on_floor or AcerasAltas.on(p)) else MapData.at(p)      # (on a high pavement: on its floor, aceras_altas.gd)
	b.rotation.y = heading
	b.set_meta("p", p)
	b.set_meta("kind", kind)
	add_child(b)
	_cell_add(_grid, p, b)

func _knock(b: RigidBody3D, v: Vector3) -> void:
	_grid[_key(b.get_meta("p"))].erase(b)
	if not b.has_meta("home"):
		b.set_meta("home", b.transform)
	b.set_meta("knocks", int(b.get_meta("knocks", 0)) + 1)
	b.freeze = false
	b.collision_layer = 32
	b.collision_mask = 1 | 2 | 32
	b.linear_velocity = v * 0.9 + Vector3(randf_range(-2, 2), 3.0 + v.length() * 0.18, randf_range(-2, 2))
	b.angular_velocity = Vector3(randf_range(-7, 7), randf_range(-4, 4), randf_range(-7, 7))
	broken_count += 1
	if b.has_meta("on_knock"):                    # (whoever owns it is told: the crossroads' traffic lights, cruce.gd)
		(b.get_meta("on_knock") as Callable).call(b)
	if b.has_meta("on_knock"):                    # (its owner's to stand up again, the next day: cruce.gd repair())
		_kept_day = game.day_n
		if not b.has_meta("keep"):                # (lying about meanwhile, or cleared away after a while like the rest)
			get_tree().create_timer(40.0).timeout.connect(b.queue_free)
		return
	if b.has_meta("keep"):
		return
	_down.append({"b": b, "day": game.day_n})
	get_tree().create_timer(40.0).timeout.connect(_tidy.bind(b, int(b.get_meta("knocks"))))

## after a while the wreck is cleared away (kept, out of sight, to be put back the next day)
func _tidy(b, knocks: int) -> void:      # (b untyped: it may be freed before the timer fires)
	if not is_instance_valid(b) or int(b.get_meta("knocks", 0)) != knocks or b.freeze:
		return
	b.freeze = true
	b.collision_layer = 0
	b.collision_mask = 0
	b.visible = false

func _process(dt: float) -> void:
	if game == null:
		return
	_mend_t -= dt
	if _mend_t > 0.0:
		return
	_mend_t = MEND_EVERY
	mend(false)

## puts back what was knocked down on an earlier day and nobody is looking at (all of it: `anyway`, for the tests)
func mend(anyway: bool) -> int:
	var n := 0
	for d in _down.duplicate():
		var b = d["b"]
		if not is_instance_valid(b):
			_down.erase(d)
			continue
		var p: Vector2 = b.get_meta("p")
		if not anyway and (game.day_n <= int(d["day"]) or game.sees(p)):
			continue
		_down.erase(d)
		b.linear_velocity = Vector3.ZERO
		b.angular_velocity = Vector3.ZERO
		b.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		b.freeze = true
		b.collision_layer = 16
		b.collision_mask = 0
		b.transform = b.get_meta("home")
		b.visible = true
		if b.is_inside_tree():
			b.reset_physics_interpolation()
		_cell_add(_grid, p, b)
		n += 1
	for d in _felled.duplicate():
		var p: Vector2 = world.tree_info[int(d["i"])]["p"]
		if not anyway and (game.day_n <= int(d["day"]) or game.sees(p)):
			continue
		_felled.erase(d)
		if is_instance_valid(d["wreck"]):
			d["wreck"].queue_free()
		world.unfell_tree(int(d["i"]))
		n += 1
	var cr = world.get("cruce")
	if cr != null and (cr.get("broken") == true or int(cr.get("down") if cr.get("down") != null else 0) > 0) and cr.has_method("repair") and (anyway or game.day_n > _kept_day):
		var spots: Array = cr.fallen() if cr.has_method("fallen") else ([cr.heads[0]["stop"]] if cr.get("heads") is Array and not (cr.heads as Array).is_empty() else [])
		var seen := false                         # (every place where something would stand up again: none in sight)
		for q in spots:
			seen = seen or game.sees(q)
		if anyway or not seen:
			cr.repair()
			n += 1
	return n

## A thing another file built and keeps (a frozen body with its own pieces and shapes, standing at `p`) joins the
## street's furniture: cars and fists knock it over like the rest (the crossroads' traffic lights, cruce.gd). `rad`: how
## close a car has to get; `heat`: how much the police mind.
func adopt(b: RigidBody3D, p: Vector2, kind: String, rad := 0.55, heat := 5.0) -> void:
	b.set_meta("rad", rad)
	b.set_meta("half", 0.0)
	b.set_meta("along", Vector2.RIGHT)
	b.set_meta("heat", heat)
	b.set_meta("p", p)
	b.set_meta("kind", kind)
	b.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	b.freeze = true
	b.collision_layer = 16
	b.collision_mask = 0
	_cell_add(_grid, p, b)

func _fell(i: int, c) -> void:
	var t: Dictionary = world.fell_tree(i)
	var k: int = t["kind"]
	var s: float = t["s"]
	var b := RigidBody3D.new()
	b.mass = 120.0
	var th: float = world.trunk_h(k)
	b.add_child(Parts.part("cyl", 0x7a5536, Vector3(0, th / 2.0 - 1.5, 0), Vector3(0.28, th, 0.28)))
	var cr: Array = world.crown(k, s)
	b.add_child(Parts.part(cr[0], world.TREE_COL[k], Vector3(0, cr[1] - 1.5, 0), cr[2]))
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
	_felled.append({"i": i, "wreck": b, "day": game.day_n})
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
						if _reach(b, q) < c.r + float(b.get_meta("rad")):
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
				var hit := false
				if b.has_meta("thin"):                # (a thin thing, a fence: the fist's path, from a little in front of you to
					for back in [0.0, 0.3, 0.55]:     # where it lands, has to come close to the thing itself)
						hit = hit or _reach(b, at - dir * back) < 0.3 + float(b.get_meta("thin"))
				else:
					hit = _reach(b, at) < 0.75 + float(b.get_meta("rad"))
				if hit and b.get_meta("kind") != "toldo":
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
		if (req as Array).size() > 2:               # (with every piece given its own spot)
			_make_terraza_as(req[0], dir, req[2], rng)
			continue
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
## Each peña's logo sprayed on walls that face a street (Luis's logos, tools/make_penas.py): ten of each, spread over
## the town and not out at its edges (the user, 13 November 2026). The paint is old: nine tenths opaque, a little faded
## and flaking, as if it had been there for years. Paint over another peña's and your own goes on in its place, fresh.
const TAGS_EACH := 10
const TAG_REACH := 650.0                 # metres from the middle of the town, at most
const TOWN := preload("res://scripts/limite.gd").CENTRE      # the middle of the town (where its buildings average out)
const TAG_H := 1.7                       # how tall a logo is painted (less, if the wall is short)
const TAG_FOOT := 0.55                   # how far off the ground it starts
const TAG_SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, specular_disabled;
uniform sampler2D logo : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D wear_tex : filter_linear_mipmap, repeat_enable;
uniform float opacity = 0.9;
uniform float wear = 1.0;
void fragment() {
	vec4 c = texture(logo, UV);
	vec2 seed = fract(NODE_POSITION_WORLD.xz * 0.0173);           // (each wall worn its own way)
	float blotch = smoothstep(0.5, 0.82, texture(wear_tex, UV * 1.3 + seed * 7.0).r);
	float flake = smoothstep(0.68, 0.92, texture(wear_tex, UV * 5.0 + seed * 3.0).g);
	float keep = 1.0 - wear * (blotch * 0.28 + flake * 0.5);       // faded patches, and specks where it has flaked off
	float grey = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	vec3 sunned = mix(c.rgb, vec3(grey) * 0.92 + 0.05, 0.22);      // the sun has had at it, a little
	ALBEDO = mix(c.rgb, sunned, wear);
	ALPHA = c.a * opacity * keep;
	ROUGHNESS = 0.95;
}
"""
## Where on a house front a logo can go without covering its door or windows. A front's picture repeats every 7 m or so
## along the wall (world.gd _facade: 256 units across); on the ground floor each style leaves these stretches plain, or
## has a garage door or a warehouse's sheet, which take paint as well as any wall. Some run on into the next repeat.
const TAG_SPANS := {
	0: [[100, 156], [206, 306]],                 # añil skirting: between the door and the window; window to next door
	1: [[34, 144], [218, 290]],                  # ochre: the garage door itself; window to the next garage door
	2: [[102, 158], [206, 308]],                 # balconies
	3: [[104, 164], [204, 310]],                 # green shutters
	4: [[0, 256]],                               # a warehouse: all of it
	6: [[102, 160], [204, 314]],                 # brick flats
}
const TAG_MIN_SPAN := 1.7                       # metres of plain wall a logo needs (the wide ones still come out a metre tall)

## [metres along the wall to the middle of its widest plain stretch, how wide that is] (or [] if it has none)
func _widest_span(style: int, length: float) -> Array:
	var reps := maxf(1.0, roundf(length / 7.0))
	var unit := length / reps / 256.0
	var best: Array = []
	for r in range(-1, int(reps)):
		for sp in TAG_SPANS[style]:
			var x0 := clampf((r * 256.0 + float(sp[0])) * unit, 0.0, length)
			var x1 := clampf((r * 256.0 + float(sp[1])) * unit, 0.0, length)
			var wide := x1 - x0
			if wide >= TAG_MIN_SPAN and (best.is_empty() or wide > float(best[1])):
				best = [(x0 + x1) / 2.0, wide]
	return best

var _tag_tex: Array = []
var _tag_shader: Shader
var _wear_tex: Texture2D

static func _v2(x) -> Vector2:
	return x if x is Vector2 else Vector2(float(x[0]), float(x[1]))

## places no graffiti goes: the houses built by hand from photos, and the landmarks ([where, how far off])
func _tag_keep_off() -> Array:
	var out: Array = []
	for h in MapData.houses:
		var o := _v2(h["o"])
		var u := _v2(h["u"])
		var length := float(h.get("len", 10.0))
		out.append([o + u * length / 2.0, length / 2.0 + 3.0])
	if MapData.church.has("o"):
		out.append([_v2(MapData.church["o"]), 45.0])
	if MapData.townhall.has("m"):
		out.append([_v2(MapData.townhall["m"]), 30.0])
	if MapData.salud.has("o"):
		out.append([_v2(MapData.salud["o"]), 45.0])
	if MapData.coop.has("o"):
		out.append([_v2(MapData.coop["o"]), 40.0])
	return out

func _place_tags() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	_tag_shader = Shader.new()
	_tag_shader.code = TAG_SHADER
	_wear_tex = load("res://assets/penas/desgaste.png")
	for id in Creator.PENA_IDS:
		_tag_tex.append(load("res://assets/penas/%s.png" % id))
	var keep_off := _tag_keep_off()
	var cands: Array = []
	for style in range(MapData.walls.size()):
		if not TAG_SPANS.has(style):
			continue                                                     # (landmarks, and the fronts drawn by hand)
		var w: Array = MapData.walls[style]
		var wy: Array = MapData.wall_y[style] if style < MapData.wall_y.size() else []
		for i in range(w.size() / 7):
			var o := i * 7
			var a := Vector2(w[o], w[o + 1])
			var b := Vector2(w[o + 2], w[o + 3])
			var length := a.distance_to(b)
			if length < 4.2 or float(w[o + 4]) < 3.0 or a.distance_to(TOWN) > TAG_REACH + 40.0:
				continue
			var u := (b - a) / length
			var n := Vector2(u.y, -u.x)                              # outwards (walls are baked counter-clockwise)
			var best: Array = _widest_span(style, length)
			if best.is_empty():
				continue
			var at := a + u * float(best[0])
			if at.distance_to(TOWN) > TAG_REACH:
				continue
			if MapData.road_edge_dist(at + n * 2.5) > 2.5 or MapData.room_at(at + n * 1.2) < 0.9:
				continue                                                 # must face a street you can stand in
			if keep_off.any(func(k): return at.distance_to(k[0]) < k[1]):
				continue
			var base: float = float(wy[i]) if i < wy.size() else MapData.height(at + n * 0.4)
			cands.append([at, n, float(best[1]), maxf(base, MapData.height(at + n * 0.4))])
	if cands.is_empty():
		return
	# Spread out: each one as far as it can be from all those already picked (the first at random). The order they
	# are picked in is spread out too, so dealing them round the peñas in turn spreads each peña's ten over the town.
	var nearest := PackedFloat32Array()
	nearest.resize(cands.size())
	nearest.fill(1e12)
	var cur := rng.randi() % cands.size()
	var picked: Array = []
	for ht in world.hand_tags:               # where the photos of a house built by hand show graffiti: those walls first
		if picked.size() >= TAGS_EACH * Creator.PENAS.size():
			break
		picked.append(ht)
		for j in range(cands.size()):
			nearest[j] = minf(nearest[j], (cands[j][0] as Vector2).distance_squared_to(ht[0]))
	if not picked.is_empty():                # (and the spreading starts from the wall furthest from them)
		var far := -1.0
		for j in range(cands.size()):
			if nearest[j] > far:
				far = nearest[j]
				cur = j
	while picked.size() < TAGS_EACH * Creator.PENAS.size():
		picked.append(cands[cur])
		var here: Vector2 = cands[cur][0]
		var best := -1.0
		var nxt := -1
		for j in range(cands.size()):
			var d2: float = (cands[j][0] as Vector2).distance_squared_to(here)
			if d2 < nearest[j]:
				nearest[j] = d2
			if nearest[j] > best:
				best = nearest[j]
				nxt = j
		if nxt < 0 or best < 25.0:
			break
		cur = nxt
	for k in range(picked.size()):
		tags.append(_make_tag(picked[k], k % Creator.PENAS.size(), rng))

func _make_tag(cand: Array, owner: int, rng: RandomNumberGenerator) -> Dictionary:
	var mid: Vector2 = cand[0]
	var n: Vector2 = cand[1]
	var mi := MeshInstance3D.new()
	mi.mesh = QuadMesh.new()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = 240.0
	mi.material_override = ShaderMaterial.new()
	mi.material_override.shader = _tag_shader
	mi.material_override.set_shader_parameter("wear_tex", _wear_tex)
	add_child(mi)
	var gy: float = cand[3]
	var wear := rng.randf_range(0.7, 1.0)
	var t := {"p": mid + n * 1.1, "node": mi, "owner": owner, "first": owner, "wear": wear, "first_wear": wear,
		"room": float(cand[2]) * 0.9, "at": Vector3(mid.x + n.x * 0.035, gy, mid.y + n.y * 0.035), "n": n, "roll": rng.randf_range(-0.05, 0.05)}
	_style_tag(t)
	return t

## the logo of the peña it belongs to now, as big as the wall allows, and as worn as it is
func _style_tag(t: Dictionary) -> void:
	var mi: MeshInstance3D = t["node"]
	var tex: Texture2D = _tag_tex[t["owner"]]
	var aspect := float(tex.get_width()) / float(tex.get_height())
	var h := TAG_H
	if h * aspect > float(t["room"]):
		h = float(t["room"]) / aspect
	(mi.mesh as QuadMesh).size = Vector2(h * aspect, h)
	var n: Vector2 = t["n"]
	mi.position = (t["at"] as Vector3) + Vector3(0.0, TAG_FOOT + h / 2.0, 0.0)
	mi.rotation = Vector3(0.0, atan2(n.x, n.y), t["roll"])
	var m: ShaderMaterial = mi.material_override
	m.set_shader_parameter("logo", tex)
	m.set_shader_parameter("wear", t["wear"])
	m.set_shader_parameter("opacity", 0.9 if float(t["wear"]) > 0.0 else 0.94)

## at the start of a game: each wall back to the peña that had it, as worn as it was (some of them are yours already)
func assign_tags(_mine: int) -> void:
	for t in tags:
		t["owner"] = t["first"]
		t["wear"] = t["first_wear"]
		_style_tag(t)

## your peña's logo over another's: fresh paint
func paint(t: Dictionary, mine: int) -> void:
	t["owner"] = mine
	t["wear"] = 0.0
	_style_tag(t)

## how many walls each peña has (for the tests and the tally)
func tags_of(pena: int) -> int:
	return tags.filter(func(t): return t["owner"] == pena).size()

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

## A terrace a hand-built place has laid out itself: `lay` = {"props": [[kind, where, heading, variant], ...] in the
## order they are to be put down, "gente": [where somebody may stand, ...]}. Everything stands on that place's floor.
## The dice are thrown exactly as _make_terraza throws them (so every other terrace in town stays as it was), and
## they still say how many of the three customers have come.
func _make_terraza_as(c: Vector2, u: Vector2, lay: Dictionary, rng: RandomNumberGenerator) -> void:
	rng.randi()
	rng.randf()
	var come := 0
	for i in range(3):
		rng.randf_range(-0.35, 0.35)
		rng.randf()
		rng.randi()
		rng.randf()
		if rng.randf() < 0.8:
			come += 1
	for q in lay.get("props", []):
		_prop(String(q[0]), q[1], float(q[2]), int(q[3]), true)
	var where: Array = lay.get("gente", [])
	for i in range(mini(come, where.size())):
		game.spawn_neighbour(where[i], true)
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
