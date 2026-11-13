extends Node3D
## The cooperative on the Avenida de la Constitución, built by hand: the look comes from street photos, the positions
## from the IGN aerial photo (tools/fetch_ortho.py). Walking north along the avenue you pass, behind the compound wall:
##   the white block with the transformer door and the offices behind it · the winery lane (sign pillar, vats on blue
##   legs, conveyor, press house, wine sheds and their tanks) · the open green shed · the yard of the green shed with
##   the co-op's name on its gable · the forecourt, with the ochre oil mill at the back · the pit, the green hoppers and
##   the silo · the red wall with the sliding green gate (Ahorros Rurales) · the tanker · the long ochre block.
## The names painted on things are made up.
##
## This node sits in the compound's own frame: +x runs north along the avenue, +z goes in from the centre of the
## avenue (east), and the origin is on the centre line at the south corner. So (x, z) below is (s, d) in MapData.coop_point.

const Parts = preload("res://scripts/parts.gd")
const Brand = preload("res://scripts/brand.gd")

const WALL := 9.6            # the compound wall, metres in from the centre of the avenue
const KERB := 4.6
const GATE := 114.0          # middle of the green gate (the bake repeats it as MapData.coop["gate"])

const WHITE := 0xf2f0ea
const BLUE := 0x3d57cf
const RED := 0x9c3b45
const OCHRE := 0xe0a83a
const TRIM := 0xc23b32
const GREEN_DARK := 0x2c6b4a
const GREEN := 0x3f9f72
const GREEN_PALE := 0x8fb5a6
const HOPPER := 0x3fae7d
const STEEL := 0xc9ced3
const CONCRETE := 0xb9b4aa

var W                        # the world (textures, static body)
var _cache := {}
var gate: StaticBody3D       # the sliding gate
var gate_open := false       # set by the game: the gate rolls to wherever this says
var _slide := 0.0
var _at: Node3D              # while set, new pieces go into this (turned) node instead of straight into the compound

func build(world) -> void:
	W = world
	var c: Dictionary = MapData.coop
	if c.is_empty():
		return
	var u := Vector2(c["u"][0], c["u"][1])
	transform = Transform3D(Basis(Vector3.UP, atan2(-u.y, u.x)), MapData.at(Vector2(c["o"][0], c["o"][1])))
	W.add_child(self)
	_ground()
	_front_wall()
	_south_block()
	_winery()
	_open_shed()
	_name_shed()
	_oil_mill()
	_hoppers()
	_north_end()
	_tanks()
	_street()

# ---------------- materials ----------------
func _flat(hex: int) -> Material:
	return Parts.mat(hex)

func _ribs() -> ImageTexture:
	if not _cache.has("ribs"):
		var img := Image.create(16, 4, true, Image.FORMAT_RGB8)
		for x in range(16):
			var v := 0.78 + 0.22 * (0.5 + 0.5 * sin(x / 16.0 * TAU))
			for y in range(4):
				img.set_pixel(x, y, Color(v, v, v))
		img.generate_mipmaps()
		_cache["ribs"] = ImageTexture.create_from_image(img)
	return _cache["ribs"]

## corrugated sheet: fine upright ribs, whichever way the wall faces
func _metal(hex: int, shine := 0.0) -> StandardMaterial3D:
	var key := "m%d_%d" % [hex, int(shine * 10.0)]
	if not _cache.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = Parts.col(hex)
		m.albedo_texture = _ribs()
		m.uv1_triplanar = true
		m.uv1_scale = Vector3.ONE * 2.6
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		m.roughness = 0.9 - shine * 0.55
		m.metallic = shine
		_cache[key] = m
	return _cache[key]

func _checks(a: int, b: int, tile: float) -> StandardMaterial3D:
	var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
	img.set_pixel(0, 0, Parts.col(a)); img.set_pixel(1, 1, Parts.col(a))
	img.set_pixel(1, 0, Parts.col(b)); img.set_pixel(0, 1, Parts.col(b))
	img.generate_mipmaps()             # far away the checks melt into one colour instead of shimmering
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE / (tile * 2.0)
	m.roughness = 1.0
	return m

# ---------------- building blocks ----------------
func _solid(size: Vector3, pos: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = size
	cs.shape = b
	cs.transform = transform * (_at.transform if _at != null else Transform3D()) * Transform3D(Basis(), pos)
	W.body.add_child(cs)

## a box from (x0, y0, z0) to (x1, y1, z1)
func _blk(material: Material, x0: float, x1: float, z0: float, z1: float, y0: float, y1: float, solid := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(absf(x1 - x0), absf(y1 - y0), absf(z1 - z0))
	mi.mesh = bm
	mi.material_override = material
	mi.position = Vector3((x0 + x1) / 2.0, (y0 + y1) / 2.0, (z0 + z1) / 2.0)
	(_at if _at != null else self).add_child(mi)
	if solid:
		_solid(bm.size, mi.position)
	return mi

## an upright cylinder standing on (x, y0, z)
func _cyl(material: Material, x: float, z: float, y0: float, r: float, h: float, solid := false, r_top := -1.0, sides := 16) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.bottom_radius = r
	cm.top_radius = r if r_top < 0.0 else r_top
	cm.height = h
	cm.radial_segments = sides
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = material
	mi.position = Vector3(x, y0 + h / 2.0, z)
	add_child(mi)
	if solid:
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = r
		sh.height = h
		cs.shape = sh
		cs.transform = transform * Transform3D(Basis(), mi.position)
		W.body.add_child(cs)
	return mi

## a gable roof (solid, so it closes the gable ends too) over x0..x1, z0..z1; the ridge runs along z unless along_x
func _roof(material: Material, x0: float, x1: float, z0: float, z1: float, y0: float, rise: float, along_x := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(x1 - x0, rise, z1 - z0) if not along_x else Vector3(z1 - z0, rise, x1 - x0)
	mi.mesh = pm
	mi.material_override = material
	mi.position = Vector3((x0 + x1) / 2.0, y0 + rise / 2.0, (z0 + z1) / 2.0)
	if along_x:
		mi.rotation.y = PI / 2.0
	(_at if _at != null else self).add_child(mi)
	return mi

## lettering on a wall. turn = PI faces the avenue, 0 faces into the compound, PI/2 faces north, -PI/2 faces south
func _text(s: String, pos: Vector3, px: int, hex: int, turn := PI) -> Label3D:
	var l := Label3D.new()
	l.text = s
	l.font_size = px
	l.pixel_size = 0.005
	l.modulate = Parts.col(hex)
	l.outline_size = 0
	l.shaded = true
	l.position = pos
	l.rotation.y = turn
	add_child(l)
	return l

## a pillar with a pyramid on top, the way every gate post in La Mancha ends
func _pillar(x: float, z: float, w: float, h: float, hex: int, base_hex := -1) -> void:
	_blk(_flat(hex), x - w / 2.0, x + w / 2.0, z - w / 2.0, z + w / 2.0, 0.0, h, true)
	if base_hex >= 0:
		_blk(_flat(base_hex), x - w / 2.0 - 0.02, x + w / 2.0 + 0.02, z - w / 2.0 - 0.02, z + w / 2.0 + 0.02, 0.0, 1.0)
	var cap := _cyl(_flat(hex), x, z, h, w * 0.78, w * 0.7, false, 0.0, 4)
	cap.rotation.y = PI / 4.0

## a low wall along the avenue with a coping, and a wire fence on top of it
func _wall(x0: float, x1: float, hex: int, h: float, coping := -1, fence := 0.0) -> void:
	_blk(_flat(hex), x0, x1, WALL - 0.15, WALL + 0.15, 0.0, h)
	_solid(Vector3(x1 - x0, 2.6, 0.3), Vector3((x0 + x1) / 2.0, 1.3, WALL))
	if coping >= 0:
		_blk(_flat(coping), x0, x1, WALL - 0.2, WALL + 0.2, h, h + 0.14)
		h += 0.14
	if fence > 0.0:
		var n := int(ceil((x1 - x0) / 3.0))
		for i in range(n + 1):
			var x := x0 + (x1 - x0) * i / n
			_blk(_flat(0x3a6b4a), x - 0.035, x + 0.035, WALL - 0.035, WALL + 0.035, h, h + fence)
		for k in [0.12, 0.5, 0.95]:
			_blk(_flat(0x55806a), x0, x1, WALL - 0.012, WALL + 0.012, h + fence * k - 0.012, h + fence * k + 0.012)

## a window on a wall facing the avenue (the wall's outer face is at z)
func _window(x: float, z: float, y: float, w: float, h: float, frame: int, glass := 0x2b3d55) -> void:
	_blk(_flat(frame), x - w / 2.0 - 0.14, x + w / 2.0 + 0.14, z - 0.07, z + 0.02, y - 0.14, y + h + 0.14)
	_blk(_flat(glass), x - w / 2.0, x + w / 2.0, z - 0.09, z, y, y + h)

## the same on a wall facing south (outer face at x)
func _window_s(x: float, z: float, y: float, w: float, h: float, frame: int, glass := 0x2b3d55) -> void:
	_blk(_flat(frame), x - 0.07, x + 0.02, z - w / 2.0 - 0.14, z + w / 2.0 + 0.14, y - 0.14, y + h + 0.14)
	_blk(_flat(glass), x - 0.09, x, z - w / 2.0, z + w / 2.0, y, y + h)

# ---------------- the ground ----------------
func _ground() -> void:
	var L: float = MapData.coop["len"]
	var D: float = MapData.coop["depth"]
	_blk(W._tmat(0xb3aea4, "asphalt", 5.0), -8.0, L, WALL, D, -0.3, 0.015)               # the yards: worn concrete
	# the chequered pavement of the avenue, kerb and all
	_blk(_checks(0xe7dbc8, 0xb7857c, 0.42), -40.0, L + 10.0, KERB, WALL - 0.15, -0.2, 0.03)
	_blk(_flat(0x9a968e), -40.0, L + 10.0, KERB - 0.16, KERB, -0.2, 0.05)
	for x in [[6.4, 20.6], [67.6, 78.4], [GATE - 3.4, GATE + 3.4]]:                       # where lorries drive across it
		_blk(W._tmat(0xa8a39a, "asphalt", 4.0), x[0], x[1], KERB - 0.16, WALL + 0.2, -0.2, 0.04)

# ---------------- the wall along the avenue ----------------
func _front_wall() -> void:
	var L: float = MapData.coop["len"]
	_wall(-16.0, -4.2, 0x8f8a84, 1.9)                                # grey block wall of the neighbour to the south
	# the blue wall with its white coping, from the winery gate up to the oil side
	_wall(22.0, 48.0, BLUE, 1.0, WHITE, 0.0)
	for i in range(44):                                              # green railings in front of the open shed
		var x := 22.3 + i * 0.6
		_blk(_flat(0x3f9a55), x - 0.05, x + 0.05, WALL - 0.05, WALL + 0.05, 1.14, 2.5)
	for y in [1.4, 2.35]:
		_blk(_flat(0x3f9a55), 22.0, 48.0, WALL - 0.03, WALL + 0.03, y - 0.04, y + 0.04)
	_pillar(48.6, WALL, 0.6, 2.3, WHITE, BLUE)
	_pillar(50.4, WALL, 0.6, 2.3, WHITE, BLUE)
	_wall(51.0, 67.0, BLUE, 1.0, WHITE, 1.1)
	# the gate of the forecourt: two wire leaves with their curved braces, between white pillars
	_pillar(67.6, WALL, 0.6, 2.3, WHITE, BLUE)
	_pillar(78.4, WALL, 0.6, 2.3, WHITE, BLUE)
	_solid(Vector3(10.2, 2.6, 0.2), Vector3(73.0, 1.3, WALL))
	for k in range(2):
		var gx := 68.0 + k * 5.1
		for y in [0.15, 1.0, 1.9]:
			_blk(_flat(0x3a6b4a), gx, gx + 4.9, WALL - 0.03, WALL + 0.03, y - 0.03, y + 0.03)
		for i in range(8):
			_blk(_flat(0x55806a), gx + i * 0.7 - 0.015, gx + i * 0.7 + 0.015, WALL - 0.015, WALL + 0.015, 0.15, 1.9)
		var arc := _blk(_flat(0x3a6b4a), gx + 0.2, gx + 4.7, WALL - 0.03, WALL + 0.03, 1.0, 1.06)
		arc.rotation.z = 0.36 if k == 0 else -0.36
	_wall(79.0, 99.4, BLUE, 1.0, WHITE, 1.1)
	# the dark red wall of the oil side, with the green gate in it
	_pillar(100.0, WALL, 0.7, 2.1, RED)
	_wall(100.4, GATE - 3.8, RED, 1.3, -1, 1.0)
	_pillar(GATE - 3.4, WALL, 0.8, 2.9, RED)
	_pillar(GATE + 3.4, WALL, 0.8, 2.9, RED)
	_wall(GATE + 3.8, 132.8, RED, 1.3, -1, 1.0)
	_wall(143.2, L - 0.4, RED, 1.3, -1, 1.0)
	_pillar(L, WALL, 0.7, 2.1, RED)
	_blk(_flat(0xe2b33c), 100.9, GATE - 4.3, WALL - 0.17, WALL - 0.15, 0.25, 1.05)       # the yellow band with the name
	_text("SOC. COOP. «VIRGEN DEL BUEN ACEITE»", Vector3((100.9 + GATE - 4.3) / 2.0, 0.65, WALL - 0.19), 58, 0x7a2a22)
	_blk(_flat(0xf6f4ee), GATE + 3.25, GATE + 3.55, WALL - 0.42, WALL - 0.4, 1.7, 2.1)   # a notice on the pillar
	_gate()

## the green gate: one corrugated panel that slides away north along the inside of the wall, on a rail
func _gate() -> void:
	gate = StaticBody3D.new()
	gate.collision_layer = 1
	gate.collision_mask = 0
	gate.position = Vector3(GATE, 0.0, WALL + 0.55)
	add_child(gate)
	var cs := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(6.4, 2.8, 0.16)
	cs.shape = b
	cs.position.y = 1.45
	gate.add_child(cs)
	var leaf := func(material: Material, size: Vector3, pos: Vector3) -> void:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = size
		mi.mesh = bm
		mi.material_override = material
		mi.position = pos
		gate.add_child(mi)
	leaf.call(_metal(Brand.GREEN), Vector3(6.4, 2.65, 0.1), Vector3(0, 1.45, 0))
	leaf.call(_flat(0x1f6a3f), Vector3(6.5, 0.12, 0.14), Vector3(0, 2.8, 0))
	leaf.call(_flat(0x1f6a3f), Vector3(6.5, 0.12, 0.14), Vector3(0, 0.12, 0))
	for x in [-3.2, 0.0, 3.2]:
		leaf.call(_flat(0x1f6a3f), Vector3(0.1, 2.7, 0.14), Vector3(x, 1.45, 0))
	var sign := Brand.sign(0.8)                                       # the bank that paid for it, on the half to your left
	sign.position = Vector3(1.6, 1.5, -0.08)
	sign.rotation.y = PI
	gate.add_child(sign)
	_blk(_flat(0x6a6a70), GATE - 3.4, GATE + 10.2, WALL + 0.5, WALL + 0.6, 0.0, 0.03)    # the rail it runs on

## the gate rolls open or shut; true while it is moving
func tick(dt: float) -> bool:
	if gate == null:
		return false
	var want := 6.7 if gate_open else 0.0
	var was := _slide
	_slide = move_toward(_slide, want, dt * 1.7)
	gate.position.x = GATE + _slide
	return _slide != was

# ---------------- south: the white block with the transformer, and the offices behind ----------------
func _south_block() -> void:
	var x0 := -4.0; var x1 := 5.2
	_blk(_flat(WHITE), x0, x1, WALL, 19.0, 0.0, 4.4, true)
	_blk(_flat(BLUE), x0 - 0.03, x1 + 0.03, WALL - 0.03, 19.03, 0.0, 0.95)
	_blk(_flat(0xe4e1d8), x0 - 0.2, x1 + 0.2, WALL - 0.2, 19.2, 4.4, 4.62)                # the flat roof's rim
	# the transformer door: grey-blue, two leaves, the yellow triangles that promise death
	var dx := 0.4
	_blk(_flat(0x9db4c4), dx - 1.2, dx + 1.2, WALL - 0.06, WALL, 0.12, 2.5)
	_blk(_flat(0x6f8797), dx - 0.02, dx + 0.02, WALL - 0.08, WALL, 0.12, 2.5)
	_blk(_flat(0x8f8a84), dx - 1.4, dx + 1.4, WALL - 0.5, WALL, 0.0, 0.12)
	for q in [[dx + 0.8, 1.5], [dx - 0.65, 2.0]]:
		_blk(_flat(0xf2c230), q[0] - 0.14, q[0] + 0.14, WALL - 0.08, WALL - 0.06, q[1], q[1] + 0.28)
	_blk(_flat(0xd23b3b), dx - 0.9, dx - 0.4, WALL - 0.08, WALL - 0.06, 1.35, 1.7)
	_blk(_flat(0x2b3d55), dx + 0.25, dx + 0.85, WALL - 0.08, WALL - 0.06, 0.85, 1.4)
	_blk(_flat(0x6f8797), dx + 0.2, dx + 0.7, WALL - 0.08, WALL - 0.06, 2.0, 2.3)         # vent
	_blk(_flat(0x26408f), dx - 1.75, dx - 1.45, WALL - 0.03, WALL - 0.01, 2.2, 2.4)
	_text("146", Vector3(dx - 1.6, 2.3, WALL - 0.04), 30, 0xffffff)
	# the offices: two floors, white, red plinth, tiled roof. They follow the old boundary, which is not square to the avenue.
	_at = Node3D.new()
	_at.position = Vector3(6.6, 0.0, 43.5)
	_at.rotation.y = 0.254
	add_child(_at)
	_blk(_flat(WHITE), -4.5, 4.5, -24.5, 24.5, 0.0, 6.6, true)
	_blk(_flat(TRIM), 4.48, 4.54, -24.5, 24.5, 0.0, 0.8)
	_roof(W._tmat(0xc9774f, "tiles", 2.2), -4.9, 4.9, -24.9, 24.9, 6.6, 1.6)
	for i in range(8):
		var z := -21.0 + i * 6.0
		_blk(_flat(0x2b3d55), 4.5, 4.55, z - 0.6, z + 0.6, 4.0, 5.3)
		if i % 3 != 1:
			_blk(_flat(0x2b3d55), 4.5, 4.55, z - 0.6, z + 0.6, 1.2, 2.5)
		else:
			_blk(_flat(0x4a3424), 4.5, 4.55, z - 0.6, z + 0.6, 0.0, 2.4)
	_at = null
	_pillar(5.9, WALL, 0.8, 3.0, WHITE, BLUE)                        # the gate post, with the letter box nobody empties
	_blk(_flat(0xd8d2c2), 6.3, 6.36, WALL - 0.2, WALL + 0.2, 1.3, 1.75)

# ---------------- the winery: sign pillar, vats on blue legs, press house and conveyor ----------------
func _winery() -> void:
	# the sign pillar and the gate leaf, slid open behind the railings
	_blk(_flat(WHITE), 20.6, 21.8, WALL - 0.5, WALL + 0.5, 0.0, 3.3, true)
	_blk(_flat(BLUE), 20.58, 21.82, WALL - 0.52, WALL + 0.52, 0.0, 1.0)
	var cap := _cyl(_flat(WHITE), 21.2, WALL, 3.3, 0.86, 0.8, false, 0.0, 4)
	cap.rotation.y = PI / 4.0
	_blk(_flat(0xfaf8f2), 20.56, 20.6, WALL - 0.42, WALL + 0.42, 1.0, 3.2)
	var gold := Parts.part("cyl", 0xd9a441, Vector3(20.54, 2.9, WALL), Vector3(0.18, 0.03, 0.18))
	gold.rotation.z = PI / 2.0
	add_child(gold)
	_text("BODEGAS\nRESACÓN", Vector3(20.53, 2.32, WALL), 38, 0x3a2a22, -PI / 2.0)
	_text("VINOS\nVENTA DIRECTA\nAL PÚBLICO", Vector3(20.53, 1.62, WALL), 23, 0x7a2a22, -PI / 2.0)
	_text("(y al que pase)", Vector3(20.53, 1.14, WALL), 16, 0x3a2a22, -PI / 2.0)
	_blk(_metal(0x2f8f55), 22.2, 28.2, WALL + 0.3, WALL + 0.4, 0.1, 2.4)
	# the white vats on their blue legs, railing and lightning rods on top
	var vx0 := 21.0; var vx1 := 28.0; var vz0 := 30.0; var vz1 := 41.0
	for x in [vx0 + 0.3, vx1 - 0.3]:
		for z in [vz0 + 0.3, (vz0 + vz1) / 2.0, vz1 - 0.3]:
			_blk(_flat(0x2f5fc0), x - 0.14, x + 0.14, z - 0.14, z + 0.14, 0.0, 3.4, true)
	for x in [vx0 + 0.3, vx1 - 0.3]:
		for k in range(2):
			var brace := _blk(_flat(0x2f5fc0), x - 0.05, x + 0.05, vz0 + 0.3 + k * 5.2, vz0 + 5.5 + k * 5.2, 1.6, 1.72)
			brace.rotation.x = -0.56 if k == 0 else 0.56
	_blk(_flat(0x2f5fc0), vx0, vx1, vz0, vz1, 3.3, 3.55)
	_blk(_metal(0xe9eaec), vx0 + 0.2, vx1 - 0.2, vz0 + 0.2, vz1 - 0.2, 3.55, 6.4)
	for x in [vx0 + 0.2, vx1 - 0.2]:
		_blk(_flat(0x8d99ae), x - 0.03, x + 0.03, vz0 + 0.2, vz1 - 0.2, 7.2, 7.26)
	for z in [vz0 + 0.2, vz1 - 0.2]:
		_blk(_flat(0x8d99ae), vx0 + 0.2, vx1 - 0.2, z - 0.03, z + 0.03, 7.2, 7.26)
	for x in [vx0 + 1.6, vx0 + 3.6]:
		_cyl(_flat(0x8d99ae), x, vz0 + 1.0, 6.4, 0.04, 2.6)
		add_child(Parts.part("ball", 0xe9eaec, Vector3(x, 9.2, vz0 + 1.0), Vector3.ONE * 0.32))
	# the press house, pale green, long, behind the open shed
	_blk(_metal(GREEN_PALE), 30.0, 58.0, 33.0, 42.0, 0.0, 8.2, true)
	_roof(_metal(GREEN), 29.6, 58.4, 32.6, 42.4, 8.2, 2.0, true)
	_blk(_flat(WHITE), 40.0, 44.4, 32.94, 33.0, 0.0, 4.4)
	_blk(_metal(GREEN), 40.2, 44.2, 32.9, 33.0, 0.0, 4.2)
	# the conveyor that climbs into it from the grape hopper
	var belt := _blk(_metal(0xd8d8d2), 31.0, 43.4, 30.6, 31.9, 3.9, 4.5)
	belt.rotation.z = 0.56
	for x in [33.5, 36.5, 39.5]:
		_blk(_flat(0x8d99ae), x - 0.06, x + 0.06, 30.7, 31.8, 0.0, 0.5 + (x - 31.5) * 0.63)
	_blk(_metal(GREEN_PALE), 41.6, 43.6, 30.6, 33.0, 6.6, 8.0)
	_blk(_metal(0xbfc3c7), 29.6, 32.6, 30.0, 32.6, 0.9, 1.5)                             # the hopper's little roof
	_roof(_metal(0xbfc3c7), 29.4, 32.8, 29.8, 32.8, 1.5, 0.7)
	for x in [29.8, 32.4]:
		for z in [30.2, 32.4]:
			_blk(_flat(0x8d99ae), x - 0.05, x + 0.05, z - 0.05, z + 0.05, 0.0, 0.9, true)
	# the big sheds the wine sleeps in, and the row of tanks along them
	_blk(_metal(0xe4e2da), 22.0, 52.0, 45.0, 77.0, 0.0, 8.0, true)
	_roof(_metal(0xaab0b4), 21.6, 52.4, 44.6, 77.4, 8.0, 2.6)
	_blk(_metal(GREEN_PALE), 52.0, 52.05, 56.0, 62.0, 0.0, 5.0)
	_blk(_flat(TRIM), 21.97, 52.03, 44.97, 77.03, 0.0, 0.9)
	for i in range(3):                                               # pallets by the way in
		_blk(_flat(0xb98a52), 15.0, 16.2, 21.0, 22.0, i * 0.16, i * 0.16 + 0.13, i == 0)
	_solid(Vector3(1.2, 0.6, 1.0), Vector3(15.6, 0.3, 21.5))

# ---------------- the open shed by the wall ----------------
func _open_shed() -> void:
	var x0 := 23.5; var x1 := 47.0; var z0 := 11.2; var z1 := 26.5
	var steel := _flat(0x24302b)
	for x in [x0, x1]:
		for k in range(4):
			var z := z0 + (z1 - z0) * k / 3.0
			_blk(steel, x - 0.16, x + 0.16, z - 0.16, z + 0.16, 0.0, 8.0, true)
	for k in range(4):                                               # trusses
		var z := z0 + (z1 - z0) * k / 3.0
		_blk(steel, x0, x1, z - 0.08, z + 0.08, 7.7, 8.0)
	_roof(_metal(0x4f6f62), x0 - 0.5, x1 + 0.5, z0 - 0.6, z1 + 0.6, 8.0, 2.4)
	# the dark green skirt of cladding round the top
	var clad := _metal(GREEN_DARK)
	_blk(clad, x0 - 0.3, x1 + 0.3, z0 - 0.35, z0 - 0.2, 5.0, 8.05)
	_blk(clad, x0 - 0.3, x0 - 0.15, z0 - 0.3, z1 + 0.3, 5.6, 8.05)
	_blk(clad, x1 + 0.15, x1 + 0.3, z0 - 0.3, z1 + 0.3, 5.6, 8.05)
	for i in range(3):                                               # bay numbers, for the lorries
		_blk(_flat(0xf6f4ee), x1 - 4.2 - i * 7.6, x1 - 3.7 - i * 7.6, z0 - 0.38, z0 - 0.36, 5.1, 5.7)
		_text(str(i + 1), Vector3(x1 - 3.95 - i * 7.6, 5.4, z0 - 0.4), 60, 0x1b1b1f)
	for q in [[27.0, 15.0], [27.0, 18.0], [40.0, 21.0]]:             # crates under it
		_blk(_flat(0xb98a52), q[0], q[0] + 2.4, q[1], q[1] + 2.0, 0.0, 1.6, true)
		_blk(_flat(0xa67c47), q[0] + 0.2, q[0] + 2.2, q[1] + 0.2, q[1] + 1.8, 1.6, 2.9)

# ---------------- the green shed with the name on it, set back behind its yard ----------------
func _name_shed() -> void:
	var x0 := 60.0; var x1 := 74.0; var z0 := 37.0; var z1 := 58.0
	_blk(_metal(GREEN_PALE), x0, x1, z0, z1, 0.0, 4.7)
	_blk(_metal(GREEN), x0, x1, z0, z1, 4.7, 7.0)
	_solid(Vector3(x1 - x0, 7.0, z1 - z0), Vector3((x0 + x1) / 2.0, 3.5, (z0 + z1) / 2.0))
	_roof(_metal(GREEN), x0 - 0.3, x1 + 0.3, z0 - 0.02, z1 + 0.3, 7.0, 2.6)
	var mid := (x0 + x1) / 2.0
	_blk(_flat(WHITE), mid - 2.2, mid + 2.2, z0 - 0.06, z0, 0.0, 4.2)                    # the door, in its white frame
	_blk(_metal(GREEN_PALE), mid - 2.0, mid + 2.0, z0 - 0.09, z0, 0.0, 4.0)
	_blk(_flat(TRIM), x0, x1, z0 - 0.05, z0, 0.0, 0.18)
	_text("SOC. COOP. «SANTO CRISTO DEL TRACTOR»", Vector3(mid, 5.2, z0 - 0.06), 118, 0xf4f1e8)
	# its emblem above the name: a little dark-green tractor seen from the front, more or less
	var dark := _flat(0x14402c)
	_blk(dark, mid - 1.3, mid + 1.3, z0 - 0.07, z0 - 0.02, 6.05, 6.28)
	_blk(dark, mid - 0.5, mid + 0.5, z0 - 0.07, z0 - 0.02, 6.28, 7.25)
	for sx in [-1.0, 1.0]:
		var wheel := Parts.part("cyl", 0x14402c, Vector3(mid + sx * 0.92, 6.62, z0 - 0.05), Vector3(0.5, 0.06, 0.5))
		wheel.rotation.x = PI / 2.0
		add_child(wheel)
	_blk(_flat(0x1b1b1f), mid - 5.5, mid - 5.1, z0 - 0.3, z0 - 0.05, 4.4, 4.6)           # floodlight
	_blk(_flat(0xb98a52), 62.0, 63.2, 30.0, 31.2, 0.0, 1.1, true)                        # a crate left in the yard
	# the porch with the three white vaults, between this shed and the mill
	var px0 := 76.0; var px1 := 85.0; var pz0 := 42.0; var pz1 := 56.0
	for x in [px0 + 0.3, px1 - 0.3]:
		for z in [pz0 + 0.3, pz1 - 0.3]:
			_blk(_flat(WHITE), x - 0.25, x + 0.25, z - 0.25, z + 0.25, 0.0, 7.4, true)
	_blk(_flat(WHITE), px0, px1, pz0, pz1, 7.4, 7.75)
	for i in range(3):
		var vault := _cyl(_flat(0xe9e6de), px0 + 1.5 + i * 3.0, (pz0 + pz1) / 2.0, 0.0, 1.5, pz1 - pz0, false, -1.0, 14)
		vault.rotation.x = PI / 2.0
		vault.scale = Vector3(1.0, 1.0, 0.4)
		vault.position.y = 7.75
	_cyl(_flat(0x2f5fc0), 75.2, 39.6, 0.0, 1.3, 3.5, true)                                # the blue water tank
	_blk(_flat(WHITE), 79.6, 82.6, 12.4, 15.2, 0.0, 2.7, true)                            # the weighbridge hut
	_blk(_flat(0xe4e1d8), 79.45, 82.75, 12.25, 15.35, 2.7, 2.85)
	_window(81.1, 12.4, 1.2, 2.2, 0.9, 0x8d99ae)
	_blk(_flat(0x8d99ae), 84.0, 96.0, 13.6, 16.6, 0.016, 0.03)                            # the weighbridge itself
	_blk(_flat(0xf6f4ee), 86.0, 86.06, WALL + 0.4, WALL + 2.4, 1.2, 3.0)                  # the grant board every co-op has
	_blk(_flat(0x26408f), 85.98, 86.0, WALL + 0.5, WALL + 1.2, 2.3, 2.9)

# ---------------- the oil mill: ochre, red trim, a parapet with a plaque, at the back of the forecourt ----------------
func _oil_mill() -> void:
	var x0 := 86.0; var x1 := 114.0; var z0 := 42.0; var z1 := 54.0
	var front := z0
	_blk(_flat(OCHRE), x0, x1, z0, z1, 0.0, 4.7, true)
	_blk(_flat(TRIM), x0 - 0.03, x1 + 0.03, z0 - 0.03, z1 + 0.03, 0.0, 0.55)
	_blk(_flat(TRIM), x0 - 0.03, x1 + 0.03, z0 - 0.03, z1 + 0.03, 3.45, 3.65)
	_blk(_flat(0xd09a30), x0 - 0.15, x1 + 0.15, z0 - 0.15, z1 + 0.15, 4.7, 5.1)           # parapet
	_roof(W._tmat(0xc9774f, "tiles", 2.2), x0, x1, z0 + 0.2, z1 + 0.4, 4.9, 1.1, true)
	var mid := (x0 + x1) / 2.0
	_blk(_flat(OCHRE), mid - 3.0, mid + 3.0, front - 0.15, front + 0.3, 5.1, 6.3)        # the stepped pediment
	_blk(_flat(OCHRE), mid - 1.7, mid + 1.7, front - 0.15, front + 0.3, 6.3, 6.9)
	_blk(_flat(0xd09a30), mid - 3.15, mid + 3.15, front - 0.2, front + 0.35, 6.3, 6.42)
	_blk(_flat(0xd09a30), mid - 1.85, mid + 1.85, front - 0.2, front + 0.35, 6.9, 7.02)
	_blk(_flat(0xf0d9a0), mid - 2.4, mid + 2.4, front - 0.18, front - 0.15, 5.3, 6.15)
	_text("ALMAZARA · 1954", Vector3(mid, 5.72, front - 0.2), 88, 0x7a2a22)
	for i in range(7):                                               # red-framed windows, a door in the middle
		var x := x0 + 2.9 + i * 3.7
		if i == 3:
			_blk(_flat(TRIM), x - 1.0, x + 1.0, front - 0.07, front, 0.0, 2.9)
			_blk(_flat(0x4a3424), x - 0.8, x + 0.8, front - 0.1, front, 0.0, 2.7)
		else:
			_window(x, front, 1.3, 1.5, 1.5, TRIM, 0x3f6a52 if i % 2 == 0 else 0x2b3d55)
	# the sheds behind it, teal roofs
	_blk(_metal(0xdfe3e0), 78.0, 114.0, 58.0, 86.0, 0.0, 7.5, true)
	_roof(_metal(0x3f8f8a), 77.6, 114.4, 57.6, 86.4, 7.5, 2.2)
	for i in range(3):                                               # and the fat tanks the oil sleeps in, by the back door
		_cyl(_metal(0x3f9a55 if i < 2 else 0x2f5fc0), 116.6 + i * 3.4, 56.0, 0.0, 1.5, 4.2, true)

# ---------------- where the olives are tipped: the pit under its roof, the hoppers, the silo ----------------
func _hopper(x: float, z: float) -> void:
	var green := _metal(HOPPER)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_blk(_flat(0x2f8f62), x + sx * 1.6 - 0.1, x + sx * 1.6 + 0.1, z + sz * 1.6 - 0.1, z + sz * 1.6 + 0.1, 0.0, 6.0, true)
	_cyl(green, x, z, 6.0, 2.05, 2.0, false)
	var cone := _cyl(green, x, z, 3.2, 0.35, 2.8, false, 2.05)
	cone.position.y = 4.6
	_blk(_flat(0x2f8f62), x - 1.9, x + 1.9, z - 1.9, z + 1.9, 5.9, 6.02)
	for sx in [-1.0, 1.0]:                                           # cross braces
		var b := _blk(_flat(0x2f8f62), x + sx * 1.6 - 0.04, x + sx * 1.6 + 0.04, z - 1.6, z + 1.6, 1.8, 1.9)
		b.rotation.x = 0.7 * sx

func _hoppers() -> void:
	# the reception pit: a grating in the ground under a low steel roof, where the trailers tip
	for x in [103.0, 116.0]:
		for z in [23.0, 31.0]:
			_blk(_flat(0x24302b), x - 0.12, x + 0.12, z - 0.12, z + 0.12, 0.0, 5.0, true)
	_blk(_metal(0x5f6f68), 102.6, 116.4, 22.6, 31.4, 5.0, 5.25)
	_blk(_flat(0x3a3a40), 105.0, 114.0, 24.4, 29.6, 0.016, 0.04)
	for i in range(8):
		_blk(_flat(0x6a6a70), 105.0 + i * 1.2, 105.1 + i * 1.2, 24.4, 29.6, 0.04, 0.07)
	var up := _blk(_metal(0xd8d8d2), 114.0, 120.6, 26.4, 27.4, 3.0, 3.5)                 # the belt from the pit up to the hoppers
	up.rotation.z = 0.74
	_hopper(119.6, 23.4)
	_hopper(124.2, 27.6)
	_blk(_flat(0x2f8f62), 117.4, 126.4, 21.2, 29.8, 7.96, 8.02)      # the walkway over them
	for q in [[117.4, 21.2], [126.4, 21.2], [117.4, 29.8], [126.4, 29.8]]:
		_blk(_flat(0x2f8f62), q[0] - 0.03, q[0] + 0.03, q[1] - 0.03, q[1] + 0.03, 8.0, 9.0)
	_blk(_flat(0x2f8f62), 117.4, 126.4, 21.17, 21.23, 8.95, 9.0)
	_blk(_flat(0x2f8f62), 117.37, 117.43, 21.2, 29.8, 8.95, 9.0)
	var ladder := _blk(_flat(0x2f8f62), 126.6, 127.1, 23.0, 23.8, 0.0, 8.6)
	ladder.rotation.z = 0.12
	# the silo tower behind, the tallest thing on the avenue
	_blk(_flat(0xecebe6), 115.0, 121.0, 34.0, 41.0, 0.0, 17.0, true)
	_blk(_flat(0xdcdad3), 114.8, 121.2, 33.8, 41.2, 17.0, 17.4)
	for y in [5.0, 9.0, 13.0]:
		_window(118.0, 34.0, y, 0.7, 0.9, 0xdcdad3, 0x3a3a40)
	for x in [116.2, 118.0, 119.8]:
		_cyl(_flat(0x8d99ae), x, 37.5, 17.4, 0.05, 2.2)

# ---------------- north: the tanker by the gate and the long ochre block with the solar panels ----------------
func _north_end() -> void:
	var D: float = MapData.coop["depth"]
	var x0 := 133.0; var x1 := 143.0; var z0 := 11.0; var z1 := 78.0
	_blk(_flat(OCHRE), x0, x1, z0, z1, 0.0, 5.2, true)
	_blk(_flat(TRIM), x0 - 0.03, x1 + 0.03, z0 - 0.03, z1 + 0.03, 0.0, 0.55)
	_blk(_flat(TRIM), x0 - 0.03, x1 + 0.03, z0 - 0.03, z1 + 0.03, 3.6, 3.85)
	_blk(_flat(TRIM), x0 - 0.03, x1 + 0.03, z0 - 0.03, z1 + 0.03, 5.0, 5.2)
	_roof(W._tmat(0xc9774f, "tiles", 2.2), x0 - 0.4, x1 + 0.4, z0 - 0.3, z1 + 0.3, 5.2, 1.6)
	for i in range(4):                                               # solar panels on the slope that faces south
		var panel := _blk(_flat(0x1c2c55), 0.0, 4.4, 0.0, 5.6, 0.0, 0.08)
		panel.rotation.z = atan2(1.6, 5.4)
		panel.position = Vector3(x0 + 2.4, 6.1, z0 + 5.5 + i * 6.0)
	for i in range(9):                                               # the long side that looks onto the yard
		_window_s(x0, z0 + 4.5 + i * 7.0, 1.4, 2.4, 1.6, TRIM, 0x6f8f5a if i % 2 == 0 else 0x2b3d55)
	_window(x0 + 5.0, z0, 1.4, 2.2, 1.6, TRIM, 0x6f8f5a)
	_blk(_flat(0x8d99ae), x0 - 0.5, x0 - 0.3, z0 + 1.0, z0 + 1.3, 5.0, 5.5)              # floodlight on the corner
	# the tanker waiting to load, parked along the wall
	var tx0 := 119.4; var tz := 13.5
	var chrome := _metal(0xd9dde2, 0.7)
	var tank := _cyl(chrome, tx0 + 4.8, tz, 0.0, 1.25, 9.4, false, -1.0, 20)
	tank.rotation.z = PI / 2.0
	tank.position.y = 2.35
	for x in [tx0 + 0.1, tx0 + 9.5]:
		var dish := Parts.part("ball", 0xd9dde2, Vector3(x, 2.35, tz), Vector3(0.35, 1.25, 1.25))
		dish.material_override = chrome
		add_child(dish)
	_blk(_flat(0x2f8f55), tx0 + 2.0, tx0 + 8.0, tz - 1.27, tz - 1.24, 2.0, 2.2)          # a swoosh, of sorts
	_blk(_flat(0xf2c230), tx0 + 1.2, tx0 + 6.0, tz - 1.25, tz - 1.2, 1.55, 1.75)
	_text("PORTES YA VOY", Vector3(tx0 + 4.8, 2.75, tz - 1.2), 84, 0x1b1b1f)
	_blk(_flat(0x2a2a30), tx0, tx0 + 9.8, tz - 0.9, tz + 0.9, 0.75, 1.1)                 # chassis
	_blk(_flat(0x8d99ae), tx0 + 0.4, tx0 + 9.2, tz - 0.7, tz + 0.7, 3.6, 3.66)           # the walkway on top
	for x in [tx0 + 0.4, tx0 + 9.2]:
		_blk(_flat(0x8d99ae), x - 0.03, x + 0.03, tz - 0.7, tz - 0.64, 3.6, 4.5)
	_blk(_flat(0x8d99ae), tx0 + 0.4, tx0 + 9.2, tz - 0.7, tz - 0.64, 4.45, 4.5)
	_blk(_flat(0xf4f4f0), tx0 + 10.1, tx0 + 12.5, tz - 1.25, tz + 1.25, 0.75, 3.5)       # the cab
	_blk(_flat(0x1b2733), tx0 + 12.5, tx0 + 12.54, tz - 1.1, tz + 1.1, 2.1, 3.2)
	_blk(_flat(0x1b2733), tx0 + 11.3, tx0 + 12.3, tz - 1.27, tz - 1.25, 2.1, 3.1)
	_blk(_flat(0x2a2a30), tx0 + 10.1, tx0 + 12.6, tz - 1.2, tz + 1.2, 0.45, 0.8)
	for x in [tx0 + 1.2, tx0 + 2.5, tx0 + 3.8, tx0 + 11.6]:
		for sz in [-1.0, 1.0]:
			var wh := Parts.part("cyl", 0x1b1b1f, Vector3(x, 0.52, tz + sz * 1.0), Vector3(0.52, 0.36, 0.52))
			wh.rotation.x = PI / 2.0
			add_child(wh)
	_solid(Vector3(12.8, 4.0, 2.6), Vector3(tx0 + 6.3, 2.0, tz))
	# what is going out today: a pallet of boxes of oil, just inside the gate
	_blk(_flat(0xb98a52), GATE - 2.2, GATE - 0.6, 20.0, 21.4, 0.0, 0.14)
	_blk(_flat(0xd8c53a), GATE - 2.1, GATE - 0.7, 20.1, 21.3, 0.14, 0.9)
	_solid(Vector3(1.6, 0.9, 1.4), Vector3(GATE - 1.4, 0.45, 20.7))
	# the boundary walls: plain block, nothing to see
	var L: float = MapData.coop["len"]
	_blk(_flat(0xcfcac0), 20.0, L, D - 0.15, D + 0.15, 0.0, 2.4, true)
	_blk(_flat(0xcfcac0), L - 0.15, L + 0.15, WALL, D, 0.0, 2.4, true)
	_blk(_flat(0xcfcac0), 19.85, 20.15, 70.0, D, 0.0, 2.4, true)

# ---------------- the stainless tanks ----------------
func _tank(x: float, z: float, r: float, h: float) -> void:
	var steel := _metal(STEEL, 0.6)
	_cyl(steel, x, z, 0.0, r, h, true, -1.0, 18)
	_cyl(steel, x, z, h, r, 0.9, false, 0.25, 18)
	_cyl(_flat(0x8d99ae), x, z, 0.0, r + 0.05, 0.35, false, -1.0, 18)

func _tanks() -> void:
	var D: float = MapData.coop["depth"]
	# the battery along the north side of the wine sheds: two rows, a walkway down the middle with its stair
	for i in range(8):
		for k in range(2):
			_tank(54.6 + k * 3.8, 46.6 + i * 3.9, 1.7, 8.6)
	_blk(_flat(0x8d99ae), 56.0, 57.0, 45.0, 76.0, 9.5, 9.6)
	for x in [56.0, 57.0]:
		_blk(_flat(0x8d99ae), x - 0.03, x + 0.03, 45.0, 76.0, 10.5, 10.56)
		for i in range(9):
			_blk(_flat(0x8d99ae), x - 0.03, x + 0.03, 45.0 + i * 3.87 - 0.03, 45.0 + i * 3.87 + 0.03, 9.6, 10.56)
	# out the back: the tiled shed, the long white one, and the big tanks beyond
	_blk(_flat(WHITE), 24.0, 72.0, 80.0, 114.0, 0.0, 8.5, true)
	_blk(_flat(TRIM), 23.97, 72.03, 79.97, 114.03, 0.0, 0.9)
	for i in range(3):
		_roof(W._tmat(0xb96f4c, "tiles", 2.2), 24.0 + i * 16.0, 40.0 + i * 16.0, 79.6, 114.4, 8.5, 2.2)
	_blk(_metal(0xe9eaec), 76.0, 90.0, 96.0, D - 2.0, 0.0, 6.5, true)
	_roof(_metal(0xf2f3f4), 75.6, 90.4, 95.6, D - 1.6, 6.5, 1.8)
	for i in range(3):
		for k in range(3):
			_tank(26.0 + i * 11.0 + (k % 2) * 5.0, 122.0 + k * 9.0, 4.0, 11.0)

# ---------------- the pavement: pines, poles, a bench and a bin ----------------
func _pine(x: float, z: float, h: float, lean: float) -> void:
	var trunk := _cyl(_flat(0x6b4a34), x, z, 0.0, 0.26, h, true, 0.18, 8)
	trunk.rotation.x = lean
	var top := Vector3(x, h * cos(lean), z + h * sin(lean) * 0.5)
	for q in [[0.0, 0.0, 3.6, 1.5], [1.6, 0.9, 2.6, 1.2], [-1.7, -0.6, 2.8, 1.25], [0.4, -1.4, 2.4, 1.1]]:
		var crown := Parts.part("ball", 0x2f5d3a, top + Vector3(q[0], 0.4 + q[1] * 0.3, q[1]), Vector3(q[2], q[3], q[2]))
		add_child(crown)
	_blk(_flat(0x5a4636), x - 0.7, x + 0.7, z - 0.7, z + 0.7, 0.0, 0.035)

func _small_tree(x: float, z: float) -> void:
	_cyl(_flat(0x6b4a34), x, z, 0.0, 0.11, 2.6, true, 0.08, 8)
	add_child(Parts.part("ball", 0x4f8a3f, Vector3(x, 3.3, z), Vector3(1.25, 1.1, 1.25)))
	_blk(_flat(0x5a4636), x - 0.55, x + 0.55, z - 0.55, z + 0.55, 0.0, 0.035)

func _street() -> void:
	for x in [-36.0, -25.0, -13.0, 26.0, 33.0, 41.0, 106.0, 127.0, 136.0]:
		_pine(x, 7.4 + fmod(absf(x), 3.0) * 0.2, 7.5 + fmod(absf(x), 5.0) * 0.35, -0.08 + fmod(absf(x), 4.0) * 0.05)
	for x in [12.0, 55.0, 63.0, 83.0, 92.0, 121.0, 141.0]:
		_small_tree(x, 7.2)
	for x in [58.0, 95.0]:                                           # the oleanders against the wall
		add_child(Parts.part("ball", 0x3f7a4a, Vector3(x, 0.8, 8.6), Vector3(1.3, 0.95, 0.8)))
	# the pylon and the poles at the south corner
	var px := -6.4
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var leg := _blk(_flat(0x8d99ae), px + sx * 0.55 - 0.04, px + sx * 0.55 + 0.04, 8.3 + sz * 0.55 - 0.04, 8.3 + sz * 0.55 + 0.04, 0.0, 12.0)
			leg.rotation = Vector3(sz * 0.03, 0, -sx * 0.03)
	for i in range(7):
		var y := 1.6 + i * 1.6
		var w := 0.55 - i * 0.045
		for s in [-1.0, 1.0]:
			_blk(_flat(0x8d99ae), px - w, px + w, 8.3 + s * w - 0.025, 8.3 + s * w + 0.025, y, y + 0.05)
			_blk(_flat(0x8d99ae), px + s * w - 0.025, px + s * w + 0.025, 8.3 - w, 8.3 + w, y, y + 0.05)
	_solid(Vector3(1.2, 6.0, 1.2), Vector3(px, 3.0, 8.3))
	_blk(_flat(0xa9a59c), px - 1.7, px - 1.4, 6.6, 6.9, 0.0, 11.0, true)                 # concrete poles
	_blk(_flat(0xa9a59c), px + 1.6, px + 1.86, 5.6, 5.86, 0.0, 10.0, true)
	_blk(_flat(0xdedbd2), px - 3.6, px - 2.8, 7.9, 8.5, 0.0, 1.5, true)                  # the electricity cabinet
	_cyl(_flat(0x9a9aa0), px - 1.6, 8.9, 0.0, 0.55, 2.6, true, -1.0, 10)                 # and the drum everybody pastes posters on
	for i in range(5):
		_blk(_flat([0xf4f1e8, 0xe2b33c, 0xd9643a, 0x6fb7e6, 0xf4f1e8][i]), px - 2.15, px - 2.13, 8.5 + i * 0.16, 8.64 + i * 0.16, 1.0 + (i % 2) * 0.4, 1.5 + (i % 2) * 0.4)
	_cyl(_flat(0x7a5a3c), 21.4, 5.9, 0.0, 0.13, 9.0, true, 0.1, 8)   # the wooden post by the winery gate
	_cyl(_flat(0x7a5a3c), 103.6, 5.6, 0.0, 0.13, 9.0, true, 0.1, 8)  # and the two by the green one
	_cyl(_flat(0x7a5a3c), 105.2, 6.4, 0.0, 0.13, 8.6, true, 0.1, 8)
	# the concrete bench the bank gave the town, and the bin
	var bx := 53.0
	_blk(_flat(0xcfcac0), bx - 1.0, bx + 1.0, 8.2, 8.75, 0.42, 0.52, true)
	_blk(_flat(0xcfcac0), bx - 1.0, bx + 1.0, 8.75, 8.87, 0.42, 1.05)
	for sx in [-0.8, 0.8]:
		_blk(_flat(0xbdb8ae), bx + sx - 0.08, bx + sx + 0.08, 8.2, 8.85, 0.0, 0.42)
	var plate := Brand.sign(0.3, 0x2f6a4a, 0x2f6a4a)
	plate.position = Vector3(bx, 0.8, 8.74)
	plate.rotation.y = PI
	add_child(plate)
	_blk(_flat(0xd9cfae), 58.6, 60.1, 4.9, 6.0, 0.0, 1.15, true)     # the bin: beige, green lid
	_blk(_flat(0x5fae4a), 58.55, 60.15, 4.85, 6.05, 1.15, 1.45)
