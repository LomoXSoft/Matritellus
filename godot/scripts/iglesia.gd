extends Node3D
## The parish church, "Paroecia Divini Salvatoris" over its door: hand-built over the real footprint (Catastro) from
## the user's walk round it and the aerial photo.
##
## What it is: one great block of ochre rubble stone laid in panels between courses of brick, with a gallery of little
## brick arches under the eaves all the way round and a hipped roof of old tile. A brick tower with a slate spire
## stands in its north-west corner. The stone doorway, with its niche, is in the west front, on a little square off
## the Calle de Cervantes; there is a plain arched door in each long side. Along the south wall, an atrium with a
## row of trees behind a low wall with brick piers and railings; along the north wall, cars parked nose to the stone.
##
## Its own frame (MapData.church): the origin is the south-west corner of the nave, +x runs east along the south
## wall, +z points south, away from the church: the nave is x 0..L, z -D..0.

const Parts = preload("res://scripts/parts.gd")
const H := 14.0                 # the walls of the nave
const BAY := 5.6                # one repeat of the wall: two arches of the gallery
const RIDGE := 6.5              # the roof above the eaves
const TOWER := 25.0             # the tower up to the belfry
const BELFRY := 6.0
const STONE := 0xdccfb2
const WOOD := 0x4a3020

var W
var L := 58.5
var D := 27.4
var top := 0.0                  # how high the cross on the spire is (for whoever asks)
var yard: Array = []            # where its railings, trees, planters and tables stand, in the town's own coordinates (the self-test checks none is in a street)
var bays := 0                   # parking bays painted along the north wall
static var _wall_img: ImageTexture

func build(world) -> void:
	W = world
	var c: Dictionary = MapData.church
	if c.is_empty():
		return
	L = float(c["len"])
	D = float(c["wid"])
	var u := Vector2(c["u"][0], c["u"][1])
	transform = Transform3D(Basis(Vector3.UP, atan2(-u.y, u.x)), MapData.at(Vector2(c["o"][0], c["o"][1])))
	W.add_child(self)
	_nave()
	_roof()
	_tower(c["tower"])
	_west_front()
	_side_doors()
	_sacristy()
	_atrium()
	_west_square()
	_north_side()

# ---------------- helpers ----------------
## a spot in the church's own frame, as a place in the town
func spot(x: float, z: float) -> Vector2:
	var p := transform * Vector3(x, 0, z)
	return Vector2(p.x, p.z)

func _box(parent: Node3D, material, pos: Vector3, size: Vector3) -> MeshInstance3D:
	var mi := Parts.part("box", 0xffffff, pos, size)
	mi.material_override = material if material is Material else Parts.mat(material)
	parent.add_child(mi)
	return mi

func _solid(size: Vector3, pos: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = size
	cs.shape = b
	cs.transform = transform * Transform3D(Basis(), pos)
	W.body.add_child(cs)

## a frame standing on a wall: +x runs along it (to the right of somebody looking at it), +z comes out of it
func _face(at: Vector3, turn: float) -> Node3D:
	var f := Node3D.new()
	f.position = at
	f.rotation.y = turn
	add_child(f)
	return f

func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3, ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	if (b - a).cross(c - a).dot(n) > 0.0:         # Godot wants clockwise front faces
		var t := b; b = c; c = t
		var tu := ub; ub = uc; uc = tu
	for v in [[a, ua], [b, ub], [c, uc]]:
		st.set_normal(n)
		st.set_uv(v[1])
		st.add_vertex(v[0])

func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, uv: Array) -> void:
	_tri(st, a, b, c, n, uv[0], uv[1], uv[2])
	_tri(st, a, c, d, n, uv[0], uv[2], uv[3])

func _text(parent: Node3D, s: String, pos: Vector3, px: int, hex: int) -> Label3D:
	var l := Label3D.new()
	l.text = s
	l.font_size = px
	l.pixel_size = 0.004
	l.modulate = Parts.col(hex)
	l.outline_size = 0
	l.position = pos
	parent.add_child(l)
	return l

# ---------------- the wall: rubble in panels between brick, and the gallery under the eaves ----------------
## One bay of wall, 128 x 256: BAY metres wide, H metres tall. Painted once.
func _wall_texture() -> ImageTexture:
	if _wall_img != null:
		return _wall_img
	var w := 128
	var h := 256
	var rng := RandomNumberGenerator.new()
	rng.seed = 4141
	var cw := 8                                 # stones about a foot across
	var ch := 8
	var nx := w / cw
	var ny := h / ch
	var pts := PackedVector2Array()               # one stone to a cell, each with its own middle...
	var tone := PackedFloat32Array()              # ...and its own colour
	for j in range(ny):
		for i in range(nx):
			pts.append(Vector2((i + rng.randf_range(0.15, 0.85)) * cw, (j + rng.randf_range(0.15, 0.85)) * ch))
			tone.append(rng.randf())
	var data := PackedByteArray()
	data.resize(w * h * 3)
	for y in range(h):
		var cj := y / ch
		for x in range(w):
			var col: Color
			var brick := false
			var in_gallery := y >= 5 and y < 60
			if y < 5 or (y >= 60 and y < 64) or (y >= 64 and (y - 64) % 26 < 3 and y < 238) or x < 5 or x >= 123 or in_gallery:
				brick = true
			if brick:
				var row := y / 3
				var bx := x + (4 if row % 2 == 1 else 0)
				var shade := fposmod(sin(float((bx / 8) * 13 + row * 7)) * 43758.5, 1.0)
				col = Color(0.70 + shade * 0.1, 0.40 + shade * 0.08, 0.27 + shade * 0.05)
				if y % 3 == 0 or bx % 8 == 0:
					col = Color(0.80, 0.72, 0.60)
				if y < 5 and (x / 4) % 2 == 0:        # the dentils of the cornice
					col = col.darkened(0.28)
				if in_gallery:                        # two arches to a bay
					for ax in [32.0, 96.0]:
						var dx := absf(x + 0.5 - ax)
						var inside := false
						var edge := false
						if y >= 28:
							inside = dx < 10.0 and y < 52
							edge = dx < 13.0 and y < 54 and not inside
						else:
							var r := Vector2(dx, 28.0 - y).length()
							inside = r < 10.0
							edge = r < 13.0 and not inside
						if inside:
							col = Color(0.11, 0.09, 0.09).lerp(Color(0.3, 0.24, 0.2), clampf((y - 16) / 44.0, 0.0, 1.0) * 0.5)
						elif edge:
							col = Color(0.78, 0.5, 0.34)
					if y >= 54 and y < 57:              # the sill of the gallery
						col = Color(0.84, 0.76, 0.62)
			else:
				var best := 1e9
				var second := 1e9
				var who := 0
				for dj in range(-1, 2):
					var jj := cj + dj
					if jj < 0 or jj >= ny:
						continue
					for di in range(-1, 2):
						var ii := (x / cw + di + nx) % nx
						var q := pts[jj * nx + ii]
						var ddx := absf(q.x - x)
						ddx = minf(ddx, w - ddx)              # (the bay repeats sideways)
						var dd := ddx * ddx + (q.y - y) * (q.y - y)
						if dd < best:
							second = best
							best = dd
							who = jj * nx + ii
						elif dd < second:
							second = dd
				var t := tone[who]
				col = Color(0.90, 0.75, 0.47).lerp(Color(0.76, 0.62, 0.42), t)
				if t > 0.9:
					col = Color(0.78, 0.56, 0.40)             # the odd reddish one
				col = col.darkened(fposmod(t * 7.3, 1.0) * 0.12)
				if sqrt(second) - sqrt(best) < 1.0:
					col = Color(0.92, 0.85, 0.70)             # mortar
				if y >= 238:                              # the plinth: greyer, damper
					col = col.lerp(Color(0.55, 0.52, 0.48), 0.55)
			var o := (y * w + x) * 3
			data[o] = int(clampf(col.r, 0.0, 1.0) * 255.0)
			data[o + 1] = int(clampf(col.g, 0.0, 1.0) * 255.0)
			data[o + 2] = int(clampf(col.b, 0.0, 1.0) * 255.0)
	var img := Image.create_from_data(w, h, false, Image.FORMAT_RGB8, data)
	img.generate_mipmaps()
	_wall_img = ImageTexture.create_from_image(img)
	return _wall_img

func _nave() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _wall_texture()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mat.roughness = 1.0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var foot := -1.2                               # (down into the ground a little)
	var corners := [Vector3(0, 0, 0), Vector3(L, 0, 0), Vector3(L, 0, -D), Vector3(0, 0, -D)]
	var outs := [Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(-1, 0, 0)]
	for k in range(4):
		var a: Vector3 = corners[k]
		var b: Vector3 = corners[(k + 1) % 4]
		var reps := maxf(1.0, roundf(a.distance_to(b) / BAY))
		var v1 := 1.0 + (-foot) / H
		_quad(st, a + Vector3(0, foot, 0), b + Vector3(0, foot, 0), b + Vector3(0, H, 0), a + Vector3(0, H, 0), outs[k],
			[Vector2(0, v1), Vector2(reps, v1), Vector2(reps, 0), Vector2(0, 0)])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	add_child(mi)

func _roof() -> void:
	var tile: StandardMaterial3D = W._tmat(0xb39a80, "tiles", 1.5)
	tile.cull_mode = BaseMaterial3D.CULL_DISABLED
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var e := 0.55                                  # the eaves overhang
	var a := Vector3(-e, H, e)
	var b := Vector3(L + e, H, e)
	var c := Vector3(L + e, H, -D - e)
	var d := Vector3(-e, H, -D - e)
	var r1 := Vector3(D / 2.0, H + RIDGE, -D / 2.0)
	var r2 := Vector3(L - D / 2.0, H + RIDGE, -D / 2.0)
	var z2 := [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	var slope := Vector3(0, D / 2.0, RIDGE).normalized()
	_quad(st, a, b, r2, r1, slope, z2)
	_quad(st, c, d, r1, r2, Vector3(0, slope.y, -slope.z), z2)
	_tri(st, d, a, r1, Vector3(-slope.z, slope.y, 0), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	_tri(st, b, c, r2, Vector3(slope.z, slope.y, 0), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = tile
	add_child(mi)
	_box(self, 0xb9552f, (r1 + r2) / 2.0 + Vector3(0, 0.08, 0), Vector3(r1.distance_to(r2) + 0.4, 0.3, 0.42))      # the ridge tiles
	_box(self, 0xc9b79d, Vector3(L / 2.0, H - 0.02, -D / 2.0), Vector3(L + 2.0 * e, 0.12, D + 2.0 * e))           # the boards under the eaves

# ---------------- the tower ----------------
func _tower(t: Array) -> void:
	var x0: float = t[0]
	var x1: float = t[1]
	var z0: float = t[2]
	var z1: float = t[3]
	var cx := (x0 + x1) / 2.0
	var cz := (z0 + z1) / 2.0
	var wx := x1 - x0
	var wz := z1 - z0
	var brick: StandardMaterial3D = W._tmat(0xffffff, "brick", 1.5)
	_box(self, brick, Vector3(cx, TOWER / 2.0 - 0.6, cz), Vector3(wx, TOWER + 1.2, wz))
	for y in [8.0, 16.0, TOWER]:                    # string courses
		_box(self, 0xb5764e, Vector3(cx, y, cz), Vector3(wx + 0.3, 0.3, wz + 0.3))
	_box(self, brick, Vector3(cx, TOWER + BELFRY / 2.0, cz), Vector3(wx - 0.3, BELFRY, wz - 0.3))      # the belfry, a touch narrower
	_box(self, 0xb5764e, Vector3(cx, TOWER + BELFRY + 0.2, cz), Vector3(wx + 0.7, 0.4, wz + 0.7))      # its cornice
	_box(self, 0x9a5a3a, Vector3(cx, TOWER + BELFRY + 0.55, cz), Vector3(wx + 0.3, 0.3, wz + 0.3))
	# the four faces: two bell openings each, a slit lower down, and the clock
	for side in [[Vector3(cx, 0, z1), 0.0, wx], [Vector3(x1, 0, cz), PI / 2.0, wz], [Vector3(cx, 0, z0), PI, wx], [Vector3(x0, 0, cz), -PI / 2.0, wz]]:
		var f := _face(side[0], side[1])
		var wide: float = side[2]
		for sx in [-1.0, 1.0]:
			var ox: float = sx * wide * 0.22
			_box(f, 0x1a1512, Vector3(ox, TOWER + 2.4, -0.13), Vector3(wide * 0.2, 2.6, 0.02))
			var arch := Parts.part("cyl", 0x1a1512, Vector3(ox, TOWER + 3.7, -0.13), Vector3(wide * 0.1, 0.02, wide * 0.1))
			arch.rotation.x = PI / 2.0
			f.add_child(arch)
			_box(f, 0x8a6a2a, Vector3(ox, TOWER + 2.9, -0.4), Vector3(wide * 0.11, 0.9, 0.3))          # a bell, inside
			_box(f, 0xb5764e, Vector3(ox, TOWER + 1.05, 0.03), Vector3(wide * 0.24, 0.14, 0.12))       # the sill
		for y in [6.0, 13.0]:
			_box(f, 0x1a1512, Vector3(0, y, 0.01), Vector3(0.35, 1.1, 0.02))
		_clock(f, 20.4)
	# the spire: slate, four-sided, with its ball and its cross
	var sp := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = (wx + 0.2) / 2.0 * sqrt(2.0)
	cone.height = 7.5
	cone.radial_segments = 4
	cone.rings = 1
	sp.mesh = cone
	sp.material_override = Parts.mat(0x4a5360)
	sp.position = Vector3(cx, TOWER + BELFRY + 0.7 + 3.75, cz)
	sp.rotation.y = PI / 4.0
	sp.scale = Vector3(1.0, 1.0, wz / wx)
	add_child(sp)
	var tip := TOWER + BELFRY + 0.7 + 7.5
	add_child(Parts.part("ball", 0xd9b23c, Vector3(cx, tip + 0.2, cz), Vector3.ONE * 0.3))
	_box(self, 0x26262b, Vector3(cx, tip + 1.2, cz), Vector3(0.1, 1.9, 0.1))
	_box(self, 0x26262b, Vector3(cx, tip + 1.5, cz), Vector3(0.9, 0.1, 0.1))
	top = tip + 2.1

## a clock face that tells the time with the town's (world.gd turns the hands)
func _clock(f: Node3D, y: float) -> void:
	var rim := Parts.part("cyl", 0x4a3424, Vector3(0, y, 0.04), Vector3(1.25, 0.05, 1.25))
	rim.rotation.x = PI / 2.0
	f.add_child(rim)
	var dial := Parts.part("cyl", 0xf4f1e8, Vector3(0, y, 0.07), Vector3(1.1, 0.04, 1.1))
	dial.rotation.x = PI / 2.0
	f.add_child(dial)
	for k in range(12):
		var tick := Parts.part("box", 0x1b1b1f, Vector3(sin(k * TAU / 12.0) * 0.9, y + cos(k * TAU / 12.0) * 0.9, 0.1), Vector3(0.06, 0.2, 0.01))
		tick.rotation.z = -k * TAU / 12.0
		f.add_child(tick)
	var pair: Array = []
	for hand in [[0.11, 0.55], [0.07, 0.86]]:
		var pivot := Node3D.new()
		pivot.position = Vector3(0, y, 0.12)
		pivot.add_child(Parts.part("box", 0x1b1b1f, Vector3(0, hand[1] / 2.0, 0), Vector3(hand[0], hand[1], 0.02)))
		f.add_child(pivot)
		pair.append(pivot)
	W._hands.append(pair)

# ---------------- doors ----------------
## an arched door of dark wood in a surround: w wide, h to the top of the arch
func _door(f: Node3D, w: float, h: float, frame, z := 0.0) -> void:
	var spring := h - w / 2.0                      # where the arch begins
	_box(f, frame, Vector3(0, spring / 2.0, z + 0.06), Vector3(w + 0.9, spring, 0.12))
	var arch := Parts.part("cyl", 0xffffff, Vector3(0, spring, z + 0.06), Vector3(w / 2.0 + 0.45, 0.12, w / 2.0 + 0.45))
	arch.material_override = frame if frame is Material else Parts.mat(frame)
	arch.rotation.x = PI / 2.0
	f.add_child(arch)
	_box(f, WOOD, Vector3(0, spring / 2.0, z + 0.14), Vector3(w, spring, 0.06))
	var leaf := Parts.part("cyl", WOOD, Vector3(0, spring, z + 0.14), Vector3(w / 2.0, 0.06, w / 2.0))
	leaf.rotation.x = PI / 2.0
	f.add_child(leaf)
	_box(f, 0x2e1c12, Vector3(0, (spring + w / 2.0) / 2.0, z + 0.18), Vector3(0.07, spring + w / 2.0 - 0.1, 0.02))      # where the two leaves meet
	for sx in [-1.0, 1.0]:                          # panels and studs
		for k in range(3):
			_box(f, 0x3a2418, Vector3(sx * w * 0.25, 0.7 + k * spring * 0.31, z + 0.18), Vector3(w * 0.32, spring * 0.22, 0.02))
		f.add_child(Parts.part("ball", 0x8a6a2a, Vector3(sx * 0.2, spring * 0.5, z + 0.21), Vector3.ONE * 0.07))

## the west front: the stone doorway with its niche, the window over it, the name
func _west_front() -> void:
	var f := _face(Vector3(0, 0, -11.2), -PI / 2.0)
	var stone := Parts.mat(STONE)
	_door(f, 2.7, 4.5, stone)
	for sx in [-1.0, 1.0]:                          # pilasters on their pedestals
		_box(f, stone, Vector3(sx * 2.2, 0.6, 0.16), Vector3(0.75, 1.2, 0.34))
		_box(f, stone, Vector3(sx * 2.2, 3.1, 0.14), Vector3(0.52, 3.8, 0.26))
		_box(f, stone, Vector3(sx * 2.2, 5.1, 0.16), Vector3(0.7, 0.24, 0.34))
	_box(f, stone, Vector3(0, 5.55, 0.18), Vector3(5.6, 0.66, 0.38))                       # the entablature, with the name cut in it
	_text(f, "PAROECIA  DIVINI  SALVATORIS", Vector3(0, 5.55, 0.38), 80, 0x5a4632)
	_box(f, stone, Vector3(0, 5.95, 0.24), Vector3(6.0, 0.16, 0.5))
	# over it: the niche between two scrolls, a little pediment, pinnacles
	_box(f, stone, Vector3(0, 7.2, 0.14), Vector3(2.2, 2.3, 0.28))
	_box(f, 0x8f8672, Vector3(0, 7.2, 0.29), Vector3(1.1, 1.6, 0.02))                      # the hollow of the niche
	var hood := Parts.part("cyl", 0x8f8672, Vector3(0, 8.0, 0.29), Vector3(0.55, 0.02, 0.55))
	hood.rotation.x = PI / 2.0
	f.add_child(hood)
	_box(f, 0xe9e2cf, Vector3(0, 7.0, 0.36), Vector3(0.34, 1.0, 0.16))                     # the saint (a saint: do not ask which)
	f.add_child(Parts.part("ball", 0xe9e2cf, Vector3(0, 7.65, 0.36), Vector3.ONE * 0.17))
	_box(f, stone, Vector3(0, 8.45, 0.18), Vector3(2.7, 0.2, 0.4))
	var gable := SurfaceTool.new()
	gable.begin(Mesh.PRIMITIVE_TRIANGLES)
	_tri(gable, Vector3(-1.35, 8.55, 0.3), Vector3(0, 9.35, 0.3), Vector3(1.35, 8.55, 0.3), Vector3(0, 0, 1), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	var gm := MeshInstance3D.new()
	gm.mesh = gable.commit()
	gm.material_override = stone
	f.add_child(gm)
	for sx in [-1.0, 1.0]:
		_box(f, stone, Vector3(sx * 2.2, 6.4, 0.2), Vector3(0.5, 0.7, 0.4))
		f.add_child(Parts.part("cone", STONE, Vector3(sx * 2.2, 7.2, 0.2), Vector3(0.24, 0.9, 0.24)))
		f.add_child(Parts.part("ball", STONE, Vector3(sx * 2.2, 7.75, 0.2), Vector3.ONE * 0.16))
		_box(f, stone, Vector3(sx * 1.45, 6.75, 0.14), Vector3(0.7, 1.3, 0.2))             # the scrolls, more or less
	# the window over the doorway, and the damp
	_box(f, stone, Vector3(0, 10.1, 0.05), Vector3(1.5, 2.0, 0.12))
	_box(f, 0x1f2a36, Vector3(0, 10.1, 0.12), Vector3(1.0, 1.5, 0.02))
	_box(f, stone, Vector3(0, 10.1, 0.14), Vector3(0.06, 1.5, 0.02))
	_box(f, stone, Vector3(0, 10.1, 0.14), Vector3(1.0, 0.06, 0.02))
	W.lamp_spots.append(MapData.at(spot(-3.0, -11.2), 4.2))

## a plain arched door in each long side, in a surround of brick
func _side_doors() -> void:
	var brick: StandardMaterial3D = W._tmat(0xffffff, "brick", 1.5)
	var south := _face(Vector3(21.5, 0, 0), 0.0)
	_door(south, 2.6, 4.3, brick)
	_box(south, STONE, Vector3(0, 0.08, 0.6), Vector3(4.2, 0.16, 1.2))                     # its step
	var north := _face(Vector3(30.5, 0, -D), PI)
	_door(north, 2.4, 4.0, brick)
	_box(north, STONE, Vector3(0, 0.08, 0.6), Vector3(4.0, 0.16, 1.2))
	W.lamp_spots.append(MapData.at(spot(30.5, -D - 2.5), 4.0))
	W.lamp_spots.append(MapData.at(spot(21.5, 2.5), 4.0))
	# a few real windows low in the long walls: narrow, deep-set, barred
	for x in [9.0, 34.0, 46.0]:
		for wall in [[0.0, 0.0], [-D, PI]]:
			var f := _face(Vector3(x if wall[1] == 0.0 else L - x, 0, wall[0]), wall[1])
			_box(f, brick, Vector3(0, 6.0, 0.03), Vector3(1.3, 2.3, 0.06))
			_box(f, 0x1f2a36, Vector3(0, 6.0, 0.07), Vector3(0.8, 1.8, 0.02))
			for k in range(3):
				_box(f, 0x26262b, Vector3(-0.27 + k * 0.27, 6.0, 0.1), Vector3(0.04, 1.8, 0.03))

## the sacristy: a low brick house with its own little roof, against the north wall beside the tower
func _sacristy() -> void:
	var brick: StandardMaterial3D = W._tmat(0xffffff, "brick", 1.5)
	var x0 := 5.5
	var x1 := 12.6
	var z0 := -D - 6.0
	var z1 := -D
	var cx := (x0 + x1) / 2.0
	var cz := (z0 + z1) / 2.0
	_box(self, brick, Vector3(cx, 2.3, cz), Vector3(x1 - x0, 5.8, z1 - z0))
	_solid(Vector3(x1 - x0, 6.0, z1 - z0), Vector3(cx, 3.0, cz))
	var roof := MeshInstance3D.new()
	var pyramid := CylinderMesh.new()
	pyramid.top_radius = 0.0
	pyramid.bottom_radius = (x1 - x0 + 0.8) / 2.0 * sqrt(2.0)
	pyramid.height = 2.2
	pyramid.radial_segments = 4
	pyramid.rings = 1
	roof.mesh = pyramid
	roof.material_override = W._tmat(0xb39a80, "tiles", 1.5)
	roof.position = Vector3(cx, 5.2 + 1.1, cz)
	roof.rotation.y = PI / 4.0
	roof.scale = Vector3(1.0, 1.0, (z1 - z0 + 0.8) / (x1 - x0 + 0.8))
	add_child(roof)
	var f := _face(Vector3(cx + 0.6, 0, z0), PI)
	_box(f, WOOD, Vector3(-1.6, 1.1, 0.04), Vector3(1.1, 2.2, 0.06))
	_box(f, 0x1f2a36, Vector3(1.2, 2.4, 0.04), Vector3(0.9, 1.2, 0.04))
	for k in range(3):
		_box(f, 0x26262b, Vector3(0.9 + k * 0.3, 2.4, 0.07), Vector3(0.04, 1.2, 0.03))

# ---------------- round about ----------------
func _tree(x: float, z: float, tall: float, crown: float) -> void:
	var trunk := Parts.part("cyl", 0x7a5536, Vector3(x, tall / 2.0, z), Vector3(0.22, tall, 0.22))
	add_child(trunk)
	var leaf: Material = W._tmat(0x5fa846, "leaf", 1.8)
	for q in [[0.0, 0.0, 0.0, 1.0], [0.5, 0.4, 0.3, 0.7], [-0.45, 0.3, -0.35, 0.72], [0.1, 0.75, -0.1, 0.62]]:
		var ball := Parts.part("ball", 0xffffff, Vector3(x + q[0] * crown, tall + crown * 0.5 + q[1] * crown, z + q[2] * crown), Vector3.ONE * crown * q[3])
		ball.material_override = leaf
		add_child(ball)
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.3
	cyl.height = 3.0
	cs.shape = cyl
	cs.transform = transform * Transform3D(Basis(), Vector3(x, 1.5, z))
	W.body.add_child(cs)

func _cypress(x: float, z: float, tall: float) -> void:
	add_child(Parts.part("cyl", 0x5d4630, Vector3(x, 0.5, z), Vector3(0.18, 1.0, 0.18)))
	var body := Parts.part("cone", 0xffffff, Vector3(x, 0.8 + tall / 2.0, z), Vector3(0.95, tall, 0.95))
	body.material_override = W._tmat(0x3d7044, "leaf", 1.6)
	add_child(body)
	add_child(Parts.part("ball", 0x3d7044, Vector3(x, 1.1, z), Vector3(0.9, 0.9, 0.9)))
	_solid(Vector3(0.7, 3.0, 0.7), Vector3(x, 1.5, z))

## a run of the low wall of the atrium: a stone footing, a brick pier every few metres, two rails between
func _railing(a: Vector3, b: Vector3) -> void:
	var run := a.distance_to(b)
	var dir := (b - a) / run
	var mid := (a + b) / 2.0
	var turn := atan2(-dir.z, dir.x)
	var base := _box(self, 0xb7a98c, mid + Vector3(0, 0.25, 0), Vector3(run, 0.5, 0.42))
	base.rotation.y = turn
	for y in [0.85, 1.2]:
		var rail := _box(self, 0x2a2c30, mid + Vector3(0, y, 0), Vector3(run, 0.05, 0.05))
		rail.rotation.y = turn
	var n := maxi(1, int(round(run / 4.2)))
	var brick: StandardMaterial3D = W._tmat(0xffffff, "brick", 1.5)
	for k in range(n + 1):
		var p := a + dir * (run * k / float(n))
		_box(self, brick, p + Vector3(0, 0.7, 0), Vector3(0.55, 1.4, 0.55))
		_box(self, 0xc9b79d, p + Vector3(0, 1.45, 0), Vector3(0.7, 0.1, 0.7))
		if k < n:
			for j in range(1, 8):                  # the bars
				var q := a + dir * (run * (k + j / 8.0) / float(n))
				_box(self, 0x2a2c30, q + Vector3(0, 0.85, 0), Vector3(0.03, 0.7, 0.03))
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(run, 1.4, 0.45)
	cs.shape = shape
	cs.transform = transform * Transform3D(Basis(Vector3.UP, turn), mid + Vector3(0, 0.7, 0))
	W.body.add_child(cs)

## How far you can go from (x, z) in a direction before coming within `keep` metres of the edge of a street. The
## streets round the church are not parallel to it: everything laid out round it asks this first.
func _room(x: float, z: float, dir: Vector2, most: float, keep: float) -> float:
	var d := 0.0
	while d < most:
		if MapData.road_edge_dist(spot(x + dir.x * (d + 0.25), z + dir.y * (d + 0.25))) < keep:
			break
		d += 0.25
	return d

## a flat piece of ground between four corners (given in order round it)
func _slab(material: Material, a: Vector2, b: Vector2, c: Vector2, d: Vector2, y: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var z2 := [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	_quad(st, Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y), Vector3(d.x, y, d.y), Vector3.UP, z2)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

## The atrium along the south wall: flagstones, a row of trees, the low wall with its railings and a way in opposite
## the door. The street on this side closes in on the church towards the east, so the atrium is a wedge: its outer
## edge keeps a pavement's width from the street all the way, and it stops where there is no room left for it.
func _atrium() -> void:
	var slabs: StandardMaterial3D = W._tmat(0xd9cfbc, "pavement", 2.2)
	slabs.cull_mode = BaseMaterial3D.CULL_DISABLED
	var pts: Array = []                              # the outer edge: [x, depth]
	for x in [-3.0, 3.5, 10.5, 18.6, 24.4, 31.0, 37.5, 44.0, 50.0]:
		var deep := minf(8.4, _room(x, 0.0, Vector2(0, 1), 9.0, 1.9))
		if deep < 2.6:
			if pts.is_empty():
				continue                             # (the Calle de Cervantes cuts the south-west corner: the atrium starts past it)
			break                                    # the street is at the wall from here on
		pts.append([x, deep])
	if pts.size() < 2:
		return
	for k in range(pts.size() - 1):
		var a: Array = pts[k]
		var b: Array = pts[k + 1]
		_slab(slabs, Vector2(a[0], 0.0), Vector2(b[0], 0.0), Vector2(b[0], b[1]), Vector2(a[0], a[1]), 0.035)
		if not (a[0] >= 18.0 and b[0] <= 25.0):      # the way in is opposite the door
			_railing(Vector3(a[0], 0, a[1]), Vector3(b[0], 0, b[1]))
		var mid_x: float = (a[0] + b[0]) / 2.0
		var mid_d: float = (a[1] + b[1]) / 2.0
		if mid_d >= 4.2 and absf(mid_x - 21.5) > 3.5:         # a tree, where there is room for one and not in front of the door
			_tree(mid_x, clampf(mid_d - 2.8, 2.4, 5.6), 2.6 + (k % 2) * 0.4, 1.7)
			yard.append(spot(mid_x, clampf(mid_d - 2.8, 2.4, 5.6)))
		yard.append(spot(a[0], a[1]))
	var last: Array = pts[-1]
	var first: Array = pts[0]
	yard.append(spot(last[0], last[1]))
	_railing(Vector3(last[0], 0, last[1]), Vector3(last[0], 0, 0.4))
	if first[0] > -2.0:                              # closed at the west end too, where it does not reach the corner
		_railing(Vector3(first[0], 0, first[1]), Vector3(first[0], 0, 0.4))
	for bx in [12.0, 31.0]:                          # stone benches against the wall, where the atrium is still wide
		if bx > last[0] - 2.0:
			continue
		_box(self, STONE, Vector3(bx, 0.42, 1.2), Vector3(2.2, 0.14, 0.55))
		for sx in [-0.8, 0.8]:
			_box(self, STONE, Vector3(bx + sx, 0.2, 1.2), Vector3(0.22, 0.4, 0.5))
		_solid(Vector3(2.2, 0.5, 0.55), Vector3(bx, 0.25, 1.2))

## the little square in front of the west door: brick paving as far as the street, two cypresses by the tower, planters
func _west_square() -> void:
	var paving: StandardMaterial3D = W._tmat(0xffffff, "brickpave", 1.6)
	paving.cull_mode = BaseMaterial3D.CULL_DISABLED
	var edge: Array = []                             # [z, how far west the paving goes]
	var z := -24.0
	while z <= 2.01:
		edge.append([z, minf(12.0, _room(0.0, z, Vector2(-1, 0), 12.5, 0.1))])
		z += 2.0
	for k in range(edge.size() - 1):
		var a: Array = edge[k]
		var b: Array = edge[k + 1]
		if a[1] < 0.5 and b[1] < 0.5:
			continue
		_slab(paving, Vector2(0.0, a[0]), Vector2(-a[1], a[0]), Vector2(-b[1], b[0]), Vector2(0.0, b[0]), 0.03)
	var to_door := minf(12.0, _room(0.0, -11.2, Vector2(-1, 0), 12.5, 0.1))
	if to_door > 1.0:
		var band: StandardMaterial3D = W._tmat(0xd9cfbc, "pavement", 2.2)
		_box(self, band, Vector3(-to_door / 2.0, 0.045, -11.2), Vector3(to_door, 0.03, 3.4))      # a strip of stone up to the door
	for c in [[-4.0, -20.2, 9.5], [-4.4, -17.0, 11.5]]:
		if _room(0.0, c[1], Vector2(-1, 0), 12.5, 0.1) > -c[0] + 1.2:
			_cypress(c[0], c[1], c[2])
			yard.append(spot(c[0], c[1]))
	for pz in [-15.2, -7.2]:
		if _room(0.0, pz, Vector2(-1, 0), 12.5, 0.1) < 5.2:
			continue
		_box(self, 0x8a5a3c, Vector3(-3.6, 0.35, pz), Vector3(0.9, 0.7, 0.9))
		add_child(Parts.part("ball", 0x4f8f45, Vector3(-3.6, 1.0, pz), Vector3(0.6, 0.55, 0.6)))
		_solid(Vector3(0.9, 0.8, 0.9), Vector3(-3.6, 0.4, pz))
		yard.append(spot(-3.6, pz))

## The north side: the bar's tables against the wall by the door, and bays painted on the ground with the cars nose
## to the stone -- but only as far east as there is room for a car between the wall and the street, which comes in
## at an angle here too.
func _north_side() -> void:
	var tarmac: StandardMaterial3D = W._tmat(0x8a858c, "asphalt", 3.0)
	var tables := _room(24.0, -D, Vector2(0, -1), 9.0, 0.6) >= 7.0
	if tables:
		var at := spot(24.0, -D - 3.4)
		W.extra_terrazas.append([at, spot(25.0, -D - 3.4) - at])
		yard.append(at)
	var x := 13.0
	while x < L - 2.0:
		var free := minf(_room(x, -D, Vector2(0, -1), 8.0, 0.3), _room(x + 2.6, -D, Vector2(0, -1), 8.0, 0.3))
		if free >= 4.8 and absf(x + 1.3 - 30.5) > 2.8 and not (tables and x + 2.6 > 19.6 and x < 28.4):
			var deep := minf(5.4, free)                  # as long as the gap between wall and street allows
			_box(self, tarmac, Vector3(x + 1.3, 0.008, -D - deep / 2.0), Vector3(2.6, 0.02, deep))
			_box(self, 0xf4f1e8, Vector3(x, 0.02, -D - 0.6 - (deep - 0.6) / 2.0), Vector3(0.12, 0.012, deep - 0.6))
			_box(self, 0xf4f1e8, Vector3(x + 2.6, 0.02, -D - 0.6 - (deep - 0.6) / 2.0), Vector3(0.12, 0.012, deep - 0.6))
			bays += 1
		x += 2.6
