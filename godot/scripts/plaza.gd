extends Node3D
## The Plaza del Ayuntamiento, built by hand instead of from generic footprints:
## the town hall (brick arcade below, white upper floor with stone-framed windows, a balcony with flags, and a
## pediment carrying the clock, the crest and the "CASA · AYUNTAMIENTO" plaque), the paved square in front with its
## chequerboard, and the garden beyond: the stone column, stone benches, iron lamp posts, palms and the brick bandstand.
##
## This node sits in the building's own frame: +x runs along the facade, +z points out into the square,
## and the origin is the middle of the facade at ground level.

const Parts = preload("res://scripts/parts.gd")
const Tela = preload("res://scripts/tela.gd")

const BAYS := 15            # arches along the front
const PIER := 0.78          # width of a brick pier
const ARCADE := 3.0         # depth of the covered walk
const SPRING := 2.55        # height at which the arches start
const H1 := 4.5             # top of the arcade storey
const H2 := 8.3             # eaves

const FRONT := 3.0          # the arcade really stands this far in front of the mapped footprint (measured on the IGN aerial photo)

var W                       # the world (for its textures, flat meshes and static body)
var _root: Node3D           # where new pieces go: this node, or the town hall's own (moved forward by FRONT)
var _shift := Vector3.ZERO  # ...and the same offset, for the colliders
var length := 63.0
var depth := 8.0

func build(world) -> void:
	W = world
	var th: Dictionary = MapData.townhall
	if th.is_empty():
		return
	length = float(th["len"])
	depth = minf(float(th["depth"]), 8.0)
	var u := Vector2(th["u"][0], th["u"][1])
	transform = Transform3D(Basis(Vector3.UP, atan2(-u.y, u.x)), MapData.at(Vector2(th["m"][0], th["m"][1])))
	W.add_child(self)
	_root = Node3D.new()
	_root.position.z = FRONT
	add_child(_root)
	_shift = Vector3(0, 0, FRONT)
	_hall()
	_root = self
	_shift = Vector3.ZERO
	_low = MapData.height(_world(Vector2(-39.6, 40.0))) - position.y
	_paving()
	_garden()
	_sunk_side()

# ---------------- helpers ----------------
func _collider(shape: Shape3D, local_pos: Vector3) -> void:
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.transform = transform * Transform3D(Basis(), local_pos + _shift)
	W.body.add_child(cs)

func _box_collider(size: Vector3, local_pos: Vector3) -> void:
	var b := BoxShape3D.new()
	b.size = size
	_collider(b, local_pos)

func _mat(hex: int, tex: String, metres: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = W._tmat(hex, tex, metres)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func _block(size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = material
	mi.position = pos
	_root.add_child(mi)
	return mi

## a flat or upright rectangle with its own image stretched (and repeated `reps` times) across it
func _picture(a: Vector3, b: Vector3, c: Vector3, d: Vector3, tex: Texture2D, reps: float) -> void:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = PackedVector3Array([a, b, c, d])            # bottom-left, bottom-right, top-right, top-left
	arr[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0, 1), Vector2(reps, 1), Vector2(reps, 0), Vector2(0, 0)])
	var n := (b - a).cross(d - a).normalized()
	arr[Mesh.ARRAY_NORMAL] = PackedVector3Array([n, n, n, n])
	arr[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 2, 1, 0, 3, 2])        # clockwise seen from the side the normal points to: that is the front
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.roughness = 1.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	_root.add_child(mi)

func _paint(w: int, h: int, bg: int, rects: Array) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	img.fill(Parts.col(bg))
	for r in rects:
		img.fill_rect(Rect2i(r[0], r[1], r[2], r[3]), Parts.col(r[4]))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _flat_local(pts: PackedVector2Array, y: float, material: Material) -> void:      # a polygon lying on the ground (x, z)
	var v := PackedVector3Array()
	var normals := PackedVector3Array()
	for q in pts:
		v.append(Vector3(q.x, y, q.y))
		normals.append(Vector3.UP)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_INDEX] = Geometry2D.triangulate_polygon(pts)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

func _rect_pts(x0: float, z0: float, x1: float, z1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)])

# ---------------- the town hall ----------------
func _hall() -> void:
	var half := length / 2.0
	var bay := length / BAYS
	var brick := _mat(0xffffff, "brick", 1.6)
	var stone := Parts.mat(0xd9d2c2)
	var white := Parts.mat(0xf6f3ea)
	var back_d := depth - ARCADE

	# the body: everything behind the covered walk, both floors, and the upper floor carried over the arches
	_block(Vector3(length, H2, back_d), Vector3(0, H2 / 2.0, -ARCADE - back_d / 2.0), white)
	_block(Vector3(length, H2 - H1, ARCADE), Vector3(0, (H1 + H2) / 2.0, -ARCADE / 2.0), white)
	_box_collider(Vector3(length, 12.0, back_d), Vector3(0, 6.0, -ARCADE - back_d / 2.0))
	# the back wall of the walk: ochre, with a barred window in every bay and the doors in the middle
	var back_tex := _paint(256, 256, 0xf1e2b6, [[0, 206, 256, 50, 0xcfc4a8], [78, 70, 100, 124, 0x8a8378], [84, 76, 88, 112, 0x2a2f38],
		[84, 76, 3, 112, 0x15171b], [104, 76, 3, 112, 0x15171b], [126, 76, 3, 112, 0x15171b], [148, 76, 3, 112, 0x15171b], [169, 76, 3, 112, 0x15171b], [84, 130, 88, 3, 0x15171b]])
	_picture(Vector3(-half, 0, -ARCADE + 0.02), Vector3(half, 0, -ARCADE + 0.02), Vector3(half, H1, -ARCADE + 0.02), Vector3(-half, H1, -ARCADE + 0.02), back_tex, BAYS)
	_block(Vector3(length, 0.06, ARCADE), Vector3(0, H1 - 0.03, -ARCADE / 2.0), Parts.mat(0xf3efe4))            # ceiling of the walk
	for sx in [-1.0, 1.0]:      # two big doors in the middle bays
		_block(Vector3(1.7, 3.0, 0.08), Vector3(sx * bay, 1.5, -ARCADE + 0.06), Parts.mat(0x5a3a22))
		_block(Vector3(1.9, 0.14, 0.1), Vector3(sx * bay, 3.08, -ARCADE + 0.06), stone)

	# the arcade: brick piers on stone feet, and a brick arch over every bay
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var quad := func(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
		for q in [a, b, c, a, c, d]:
			st.add_vertex(q)
	for i in range(BAYS + 1):
		var px := -half + i * bay
		_block(Vector3(PIER, SPRING, PIER), Vector3(px, SPRING / 2.0, -PIER / 2.0), brick)
		_block(Vector3(PIER + 0.16, 0.4, PIER + 0.16), Vector3(px, 0.2, -PIER / 2.0), stone)
		_block(Vector3(PIER + 0.12, 0.14, PIER + 0.12), Vector3(px, SPRING - 0.07, -PIER / 2.0), stone)
		_box_collider(Vector3(PIER, 5.0, PIER), Vector3(px, 2.5, -PIER / 2.0))
	for i in range(BAYS):
		var x0 := -half + i * bay + PIER / 2.0
		var x1 := x0 + bay - PIER
		var rx := (x1 - x0) / 2.0
		var cx := (x0 + x1) / 2.0
		var rise := 1.45
		var steps := 12
		for k in range(steps):
			var a0 := PI - PI * k / steps
			var a1 := PI - PI * (k + 1) / steps
			var p0 := Vector2(cx + cos(a0) * rx, SPRING + sin(a0) * rise)
			var p1 := Vector2(cx + cos(a1) * rx, SPRING + sin(a1) * rise)
			for z in [0.0, -PIER]:                                         # front and back faces of the spandrel
				quad.call(Vector3(p0.x, p0.y, z), Vector3(p1.x, p1.y, z), Vector3(p1.x, H1, z), Vector3(p0.x, H1, z))
			quad.call(Vector3(p0.x, p0.y, 0), Vector3(p1.x, p1.y, 0), Vector3(p1.x, p1.y, -PIER), Vector3(p0.x, p0.y, -PIER))      # underside of the arch
		for z in [0.0, -PIER]:                                             # the strip of wall over each pier
			quad.call(Vector3(x0 - PIER, SPRING, z), Vector3(x0, SPRING, z), Vector3(x0, H1, z), Vector3(x0 - PIER, H1, z))
	for z in [0.0, -PIER]:
		quad.call(Vector3(half - PIER / 2.0, SPRING, z), Vector3(half + PIER / 2.0, SPRING, z), Vector3(half + PIER / 2.0, H1, z), Vector3(half - PIER / 2.0, H1, z))
	st.generate_normals()
	var arches := MeshInstance3D.new()
	arches.mesh = st.commit()
	arches.material_override = brick
	_root.add_child(arches)
	_block(Vector3(length + PIER, 0.16, 0.9), Vector3(0, H1 + 0.02, -0.38), stone)                   # string course over the arches

	# the upper floor: white, a stone-framed window with a brown shutter in every bay
	var slats: Array = [[150, 44, 212, 176, 0xb9b3a6], [164, 58, 184, 150, 0x7a4a2c], [150, 222, 212, 12, 0xcfc8b8]]
	for y in range(64, 204, 12):
		slats.append([164, y, 184, 3, 0x5f3820])
	var up_tex := _paint(512, 256, 0xf6f3ea, slats)
	_picture(Vector3(-half, H1 + 0.1, 0.02), Vector3(half, H1 + 0.1, 0.02), Vector3(half, H2, 0.02), Vector3(-half, H2, 0.02), up_tex, BAYS)
	_block(Vector3(length + 0.5, 0.22, depth + 0.5), Vector3(0, H2 + 0.05, -depth / 2.0), Parts.mat(0xc08a5a))      # eaves
	# the tiled roof, on the same tile shader as every other roof in town
	var roof_shader := Shader.new()
	roof_shader.code = W.ROOF_SHADER
	var rm := ShaderMaterial.new()
	rm.shader = roof_shader
	rm.set_shader_parameter("tex", W._tex("tiles"))
	var roof_t := transform * Transform3D(Basis.from_scale(Vector3(length + 0.6, 1.9, depth + 0.8)), Vector3(0, H2 + 0.16, -depth / 2.0) + _shift)
	W._multimesh(W._roof_mesh(), rm, [[roof_t, Parts.col(0xc9603a)]])

	# balcony over the three middle bays, with its flags
	var bw := bay * 3.0 - 0.4
	_block(Vector3(bw, 0.12, 0.95), Vector3(0, H1 + 0.32, 0.48), stone)
	_block(Vector3(bw, 0.05, 0.05), Vector3(0, H1 + 1.35, 0.93), Parts.mat(0x1b1b1f))
	var x := -bw / 2.0
	while x <= bw / 2.0 + 0.01:
		_block(Vector3(0.035, 1.0, 0.035), Vector3(x, H1 + 0.85, 0.93), Parts.mat(0x1b1b1f))
		x += 0.28
	var flags := [[0x7a2030], [0xc8102e, 0xf1bf00, 0xc8102e], [0x9b1b30, 0xf4f4f0], [0x1f3f9a]]
	for i in range(flags.size()):
		var pole := Node3D.new()
		pole.position = Vector3((i - 1.5) * 1.5, H1 + 1.2, 0.9)
		pole.rotation.x = 0.6
		_root.add_child(pole)
		pole.add_child(Parts.part("cyl", 0x3a3a3a, Vector3(0, 1.1, 0), Vector3(0.025, 2.2, 0.025)))
		var stripes: Array = flags[i]
		var across: bool = stripes.size() == 3              # three horizontal bands, or two halves side by side
		var paint := func(a: float, d: float) -> Color:
			return Parts.col(stripes[mini(stripes.size() - 1, int((d if across else a) * stripes.size()))])
		var fst := Tela.begin()                              # cloth: it waves in the wind (tela.gd)
		Tela.sheet(fst, Vector3(0.02, 2.01, 0.0), Vector3(1.0, 0.0, 0.0), Vector3(0.0, -0.62, 0.0), false, paint, 0.2, i * 0.27 + 0.1, 0.0, 14, 6)
		var cloth := MeshInstance3D.new()
		cloth.mesh = fst.commit()
		cloth.material_override = Tela.material()
		cloth.extra_cull_margin = 1.5
		pole.add_child(cloth)

	# the pediment: clock on top, the crest under it, the plaque along the bottom, brick pinnacles with stone balls
	var outline := PackedVector2Array([Vector2(-4.7, 0), Vector2(4.7, 0), Vector2(4.7, 1.25), Vector2(1.55, 2.35), Vector2(1.55, 2.9)])
	for k in range(1, 12):
		var a := PI * k / 12.0
		outline.append(Vector2(cos(a) * 1.55, 2.9 + sin(a) * 1.2))
	outline.append(Vector2(-1.55, 2.9)); outline.append(Vector2(-1.55, 2.35)); outline.append(Vector2(-4.7, 1.25))
	var pv := PackedVector3Array()
	var pn := PackedVector3Array()
	for q in outline:
		pv.append(Vector3(q.x, H2 + 0.2 + q.y, 0.08))
		pn.append(Vector3(0, 0, 1))
	var parr := []
	parr.resize(Mesh.ARRAY_MAX)
	parr[Mesh.ARRAY_VERTEX] = pv
	parr[Mesh.ARRAY_NORMAL] = pn
	var ptri := Geometry2D.triangulate_polygon(outline)
	ptri.reverse()                               # the outline runs anticlockwise: turn the triangles to face the square
	parr[Mesh.ARRAY_INDEX] = ptri
	var pmesh := ArrayMesh.new()
	pmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, parr)
	var pmi := MeshInstance3D.new()
	pmi.mesh = pmesh
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Parts.col(0xf6f3ea)
	pmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	pmat.roughness = 1.0
	pmi.material_override = pmat
	_root.add_child(pmi)
	_block(Vector3(9.4, 0.5, 0.5), Vector3(0, H2 + 0.3, -0.2), white)                       # so it has some body behind
	for rake in [[-3.12, 1.8, 0.336], [3.12, 1.8, -0.336]]:                                     # brick copings on the slopes
		var cop := _block(Vector3(3.4, 0.16, 0.22), Vector3(rake[0], H2 + 0.2 + rake[1] + 0.06, 0.1), brick)
		cop.rotation.z = rake[2]
	for pin in [[-4.7, 1.25], [4.7, 1.25], [-1.55, 2.9], [1.55, 2.9]]:
		_block(Vector3(0.36, 0.95, 0.36), Vector3(pin[0], H2 + 0.2 + pin[1] + 0.45, 0.02), brick)
		_root.add_child(Parts.part("ball", 0xd9d2c2, Vector3(pin[0], H2 + 0.2 + pin[1] + 1.06, 0.02), Vector3.ONE * 0.2))
	# clock
	var cy := H2 + 0.2 + 3.15
	var rim := Parts.part("cyl", 0x4a3424, Vector3(0, cy, 0.1), Vector3(0.72, 0.05, 0.72))
	rim.rotation.x = PI / 2.0
	_root.add_child(rim)
	var dial := Parts.part("cyl", 0xfffaf0, Vector3(0, cy, 0.115), Vector3(0.64, 0.05, 0.64))
	dial.rotation.x = PI / 2.0
	_root.add_child(dial)
	for k in range(12):
		var tick := Parts.part("box", 0x1b1b1f, Vector3(sin(k * TAU / 12.0) * 0.54, cy + cos(k * TAU / 12.0) * 0.54, 0.15), Vector3(0.035, 0.1, 0.01))
		tick.rotation.z = -k * TAU / 12.0
		_root.add_child(tick)
	var pair: Array = []
	for hand in [[0.06, 0.34], [0.04, 0.52]]:
		var pivot := Node3D.new()
		pivot.position = Vector3(0, cy, 0.16)
		pivot.add_child(Parts.part("box", 0x1b1b1f, Vector3(0, hand[1] / 2.0, 0), Vector3(hand[0], hand[1], 0.02)))
		_root.add_child(pivot)
		pair.append(pivot)
	W._hands = [pair]
	# crest
	var logo := Parts.texture("res://assets/logo.png")
	if logo != null:
		var crest := Sprite3D.new()
		crest.texture = logo
		crest.pixel_size = 1.55 / logo.get_width()
		crest.position = Vector3(0, H2 + 0.2 + 1.55, 0.13)
		crest.shaded = false
		_root.add_child(crest)
	# plaque
	_block(Vector3(6.6, 0.42, 0.04), Vector3(0, H2 + 0.2 + 0.42, 0.11), Parts.mat(0xefe9da))
	var plaque := Label3D.new()
	plaque.text = "CASA · AYUNTAMIENTO"
	plaque.font_size = 64
	plaque.pixel_size = 0.0052
	plaque.modulate = Color("2a221c")
	plaque.outline_size = 0
	plaque.shaded = false
	plaque.position = Vector3(0, H2 + 0.2 + 0.42, 0.14)
	_root.add_child(plaque)
	# iron lanterns on every third pier
	for i in range(1, BAYS, 3):
		var lx := -half + i * bay
		_block(Vector3(0.05, 0.05, 0.5), Vector3(lx, 3.5, 0.25), Parts.mat(0x1b1b1f))
		_block(Vector3(0.22, 0.34, 0.22), Vector3(lx, 3.25, 0.5), Parts.mat(0x1b1b1f))
		_block(Vector3(0.16, 0.22, 0.16), Vector3(lx, 3.25, 0.5), Parts.mat(0xffe9a8))

# ---------------- the paved square ----------------
## Laid out from the aerial view. u runs along the facade (negative = the Calle Zaragoza side), n is metres out from it.
func _paving() -> void:
	var half := length / 2.0
	var y := 0.03
	var bricks := _mat(0xffffff, "brickpave", 1.6)
	# the whole square is paved, right up to the back wall of the covered walk
	_flat_local(_rect_pts(-half - 1.0, -ARCADE, half + 1.0, FRONT + 0.6), y, bricks)
	var park := PackedVector2Array()
	for q in MapData.townhall.get("park", []):
		park.append(Vector2(q[0], q[1]))
	if park.size() >= 3 and _low < -0.6:        # the square stops at its wall above the Arroyuelo
		for piece in Geometry2D.intersect_polygons(park, _rect_pts(EDGE, -50.0, 200.0, 200.0)):
			_flat_local(piece, y, bricks)
	elif park.size() >= 3:
		_flat_local(park, y, bricks)
	else:
		_flat_local(_rect_pts(-half, 0, half, 60.0), y, bricks)
	# the town's crest laid into the paving in front of the main doors, brick by brick, and worn by the years
	_floor_crest(Vector2(0.0, 9.4), 11.0, y + 0.012)
	# the two giant chessboards: the same size, the same distance from the arcade, one each side of the doors
	_checker(Vector2(-16.6, 10.4), 9.6, y)
	_checker(Vector2(18.6, 10.4), 9.6, y)
	# fans of cobbles round the tree planters on the Calle Zaragoza side
	_flat_local(_rect_pts(-31.0 if _low > -0.6 else EDGE, 8.0, -24.5, 52.0), y + 0.01, _mat(0xb9a99a, "pavement", 1.2))

func _checker(centre: Vector2, side: float, y: float) -> void:
	var cells := 8
	var sq := side / cells
	var x0 := centre.x - side / 2.0
	var z0 := centre.y - side / 2.0
	_flat_local(_rect_pts(x0 - 0.4, z0 - 0.4, x0 + side + 0.4, z0 + side + 0.4), y + 0.01, _mat(0x6f6c6c, "pavement", 2.3))
	# years of feet and footballs: no two squares are quite the same colour any more
	var dark: Array = [_mat(0x8b8d93, "pavement", 2.3), _mat(0x97918f, "pavement", 2.3), _mat(0x9f948c, "pavement", 2.3)]
	var light: Array = [_mat(0xe6e2d9, "pavement", 2.3), _mat(0xd9d2c6, "pavement", 2.3), _mat(0xcfc3b4, "pavement", 2.3)]
	var rng := RandomNumberGenerator.new()
	rng.seed = int(centre.x * 13.0)
	for i in range(cells):
		for k in range(cells):
			var worn := mini(2, int(rng.randf() * rng.randf() * 3.4))
			_flat_local(_rect_pts(x0 + i * sq, z0 + k * sq, x0 + (i + 1) * sq, z0 + (k + 1) * sq), y + 0.02, light[worn] if (i + k) % 2 == 0 else dark[worn])

## The crest as a mosaic of bricks: the image is read brick by brick (so it has the joints of the paving), in dulled
## colours, and each brick has lost more or less of its colour.
const CREST_SHADER := "
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform sampler2D crest : source_color, filter_linear;
void fragment() {
	vec2 grid = vec2(46.0, 92.0);                         // bricks across and down
	vec2 g = UV * grid;
	float row = floor(g.y);
	g.x += mod(row, 2.0) * 0.5;                           // every other course is shifted half a brick
	vec2 cell = vec2(floor(g.x), row);
	vec2 at = (cell + vec2(0.5 - mod(row, 2.0) * 0.5, 0.5)) / grid;
	vec4 c = texture(crest, clamp(at, vec2(0.0), vec2(1.0)));
	float wear = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	float patch = 0.5 + 0.5 * sin(cell.x * 0.21 + 1.3) * sin(cell.y * 0.13 + 0.4);      // where everybody walks
	vec2 in_brick = fract(g);
	float joint = step(0.06, in_brick.x) * step(0.1, in_brick.y);
	float grey = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	ALBEDO = mix(vec3(grey), c.rgb, 0.55) * 0.82 + vec3(0.06, 0.03, 0.02);
	ROUGHNESS = 1.0;
	ALPHA = c.a * joint * mix(0.25, 0.8, wear) * mix(0.55, 1.0, patch);
}
"

func _floor_crest(centre: Vector2, side: float, y: float) -> void:
	var logo := Parts.texture("res://assets/logo.png")
	if logo == null:
		return
	var h := side / 2.0
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	# top of the crest towards the town hall, so you read it as you walk up to the doors
	arr[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(centre.x - h, y, centre.y - h), Vector3(centre.x + h, y, centre.y - h), Vector3(centre.x + h, y, centre.y + h), Vector3(centre.x - h, y, centre.y + h)])
	arr[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	arr[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
	arr[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var sh := Shader.new()
	sh.code = CREST_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("crest", logo)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

## The sweets stall on the corner by the zebra crossing: a blue plastic kiosk that only opens in fine weather.
## (It is shut: shutters down, last summer's ice-cream stickers fading on them.)
func _sweets_stall(at: Vector2, turn: float) -> void:
	var st := Node3D.new()
	st.position = Vector3(at.x, 0, at.y)
	st.rotation.y = turn
	add_child(st)
	var blue := 0x2f86d8
	var deep := 0x2470bd
	var put := func(kind: String, hex: int, pos: Vector3, scl: Vector3) -> MeshInstance3D:
		var mi := Parts.part(kind, hex, pos, scl)
		st.add_child(mi)
		return mi
	put.call("box", blue, Vector3(0, 1.2, 0), Vector3(3.1, 2.4, 3.1))
	put.call("box", deep, Vector3(0, 2.5, 0), Vector3(3.5, 0.22, 3.5))                 # the roof, with its lip
	put.call("box", blue, Vector3(0, 2.72, 0), Vector3(2.9, 0.24, 2.9))
	put.call("box", blue, Vector3(0, 2.92, 0), Vector3(2.0, 0.18, 2.0))
	for face in range(4):
		var side := Node3D.new()
		side.rotation.y = face * PI / 2.0
		st.add_child(side)
		for sx in [-1.0, 1.0]:                                                           # corner posts
			side.add_child(Parts.part("box", deep, Vector3(sx * 1.55, 1.2, 1.56), Vector3(0.14, 2.4, 0.06)))
		side.add_child(Parts.part("box", deep, Vector3(0, 1.2, 1.56), Vector3(0.1, 2.4, 0.05)))            # the shutter's middle
		side.add_child(Parts.part("box", deep, Vector3(0, 1.0, 1.56), Vector3(3.0, 0.08, 0.05)))
		for sx in [-1.0, 1.0]:                                                           # stickers: a brand of ice cream, a biscuit
			var disc := Parts.part("cyl", 0xf4f4f0, Vector3(sx * 0.75, 1.78, 1.575), Vector3(0.3, 0.02, 0.3))
			disc.rotation.x = PI / 2.0
			side.add_child(disc)
			var dot := Parts.part("cyl", 0xd23b3b, Vector3(sx * 0.75, 1.78, 1.59), Vector3(0.17, 0.02, 0.17))
			dot.rotation.x = PI / 2.0
			side.add_child(dot)
			var pic := Parts.part("cyl", 0x1f4f95, Vector3(sx * 0.75, 0.55, 1.575), Vector3(0.38, 0.02, 0.3))
			pic.rotation.x = PI / 2.0
			side.add_child(pic)
			var biscuit := Parts.part("cyl", 0xc98e4a, Vector3(sx * 0.75, 0.55, 1.59), Vector3(0.2, 0.02, 0.16))
			biscuit.rotation.x = PI / 2.0
			side.add_child(biscuit)
	var name := Label3D.new()
	name.text = "CHUCHES · HELADOS\nABIERTO SI HACE BUENO"
	name.font_size = 54
	name.pixel_size = 0.0042
	name.modulate = Color("f4f4f0")
	name.outline_size = 0
	name.shaded = true
	name.position = Vector3(0, 2.5, 1.76)
	st.add_child(name)
	_collider(_stall_shape(), Vector3(at.x, 1.3, at.y))

func _stall_shape() -> CylinderShape3D:
	var c := CylinderShape3D.new()
	c.radius = 2.0
	c.height = 2.6
	return c

func _disc(centre: Vector2, radius: float, y: float, material: Material) -> void:
	var pts := PackedVector2Array()
	for k in range(28):
		pts.append(centre + Vector2(cos(k * TAU / 28.0), sin(k * TAU / 28.0)) * radius)
	_flat_local(pts, y, material)

## a point of this square (u, n) in world coordinates
func _world(q: Vector2) -> Vector2:
	var p := transform * Vector3(q.x, 0, q.y)
	return Vector2(p.x, p.z)

# ---------------- everything standing in the square ----------------
func _garden() -> void:
	var grass := _mat(0x9ccf6e, "grass", 3.0)
	# the round lawn with the stone column in the middle, ringed by a low kerb, benches looking in
	var lawn := Vector2(2.7, 53.4)             # (centred from the IGN aerial photo)
	_disc(lawn, 4.7, 0.06, grass)
	_kerb(lawn, 4.7)
	_column(lawn)
	for k in range(4):
		var a := k * TAU / 4.0 + 0.8
		_bench(lawn + Vector2(sin(a), cos(a)) * 6.6, a + PI)
	# the garden under the big trees on the far side, with its lawn
	var bed := PackedVector2Array([Vector2(13, 39), Vector2(30, 36), Vector2(32, 54), Vector2(22, 60), Vector2(15, 56)])
	_flat_local(bed, 0.05, grass)

	# the playground: a fenced circle of soft red floor
	var play := Vector2(-16.2, 33.1)
	_disc(play, 7.2, 0.05, _mat(0x8a3a34, "asphalt", 2.0))
	for k in range(26):                                  # the fence, with a gap for the gate
		if k == 6 or k == 7:
			continue
		var a := k * TAU / 26.0
		var fp := play + Vector2(sin(a), cos(a)) * 7.2
		add_child(Parts.part("box", [0xd8342c, 0xf2c230, 0x2f6bb5, 0x4f8f45][k % 4], Vector3(fp.x, 0.45, fp.y), Vector3(0.08, 0.9, 0.08)))
	_slide(play + Vector2(-2.2, 1.0))
	_swings(play + Vector2(2.6, -1.2))
	add_child(Parts.part("ball", 0xf2c230, Vector3(play.x + 0.5, 0.55, play.y + 3.4), Vector3(0.45, 0.45, 0.7)))      # a spring rider
	add_child(Parts.part("cyl", 0x3a3a3a, Vector3(play.x + 0.5, 0.2, play.y + 3.4), Vector3(0.07, 0.4, 0.07)))

	# the terraza of the kiosk, where the white parasols are in the aerial view (the breakable furniture comes from props.gd)
	W.extra_terrazas.append([_world(Vector2(-12.5, 56.6)), _world(Vector2(-11.5, 56.6)) - _world(Vector2(-12.5, 56.6))])

	# trees in round stone planters with an iron rail: a row down the Calle Zaragoza side, big ones across the far side
	var west := [12.0, 20.0, 28.0, 38.0, 46.0]
	for k in range(west.size()):
		if k == 1 or k == 3:
			_planter(Vector2(-27.8, west[k]), "palm")
		else:
			_planter(Vector2(-27.8, west[k]), "tree")
	for q in [Vector2(4.6, 24.5), Vector2(18.0, 23.0), Vector2(29.8, 18.5), Vector2(29.6, 8.6), Vector2(31.0, 37.0), Vector2(-3.0, 61.0), Vector2(4.0, 66.0)]:
		_planter(q, "tree")
	for q in [Vector2(12.8, 43.5), Vector2(24.0, 49.0), Vector2(15.0, 60.5), Vector2(29.5, 41.0)]:      # these stand in the garden bed
		_tree(q, 4.2)
	# stone benches by the planters, facing into the square
	for q in [[Vector2(-25.4, 16.0), PI / 2.0], [Vector2(-25.4, 24.0), PI / 2.0], [Vector2(-25.4, 42.0), PI / 2.0], [Vector2(7.4, 22.6), PI], [Vector2(20.8, 21.2), PI]]:
		_bench(q[0], q[1])
	# iron lamp posts
	for q in [Vector2(-24.6, 5.4), Vector2(-5.6, 4.8), Vector2(8.6, 4.8), Vector2(26.0, 5.2), Vector2(-24.5, 33.0), Vector2(-2.0, 30.0), Vector2(12.0, 28.0),
			Vector2(2.0, 42.0), Vector2(16.0, 44.0), Vector2(-4.0, 55.0), Vector2(8.0, 58.0), Vector2(26.0, 28.0)]:
		_lamp(q)
	_sweets_stall(Vector2(31.6, 55.2), -PI / 2.0)
	# the brick bandstand at the far end, by the car park on Calle de la Plaza, looking back at the town hall
	_bandstand(Vector2(-11.0, 68.0))

func _kerb(centre: Vector2, radius: float) -> void:
	for k in range(24):
		var a := k * TAU / 24.0
		var p := centre + Vector2(sin(a), cos(a)) * radius
		var stone := Parts.part("box", 0xd3ccbc, Vector3(p.x, 0.16, p.y), Vector3(radius * TAU / 24.0 + 0.05, 0.32, 0.26))
		stone.rotation.y = a
		add_child(stone)

## a round stone planter with an iron rail and something growing in it
func _planter(at: Vector2, what: String) -> void:
	add_child(Parts.part("cyl", 0xd3ccbc, Vector3(at.x, 0.27, at.y), Vector3(1.75, 0.54, 1.75)))
	add_child(Parts.part("cyl", 0x5f8f3f, Vector3(at.x, 0.56, at.y), Vector3(1.5, 0.04, 1.5)))
	for k in range(8):
		var a := k * TAU / 8.0
		var p := at + Vector2(sin(a), cos(a)) * 1.5
		add_child(Parts.part("box", 0x3a3d44, Vector3(p.x, 0.86, p.y), Vector3(0.05, 0.6, 0.05)))
		var bar := Parts.part("box", 0x3a3d44, Vector3(at.x + sin(a + TAU / 16.0) * 1.39, 1.12, at.y + cos(a + TAU / 16.0) * 1.39), Vector3(1.16, 0.05, 0.05))
		bar.rotation.y = a + TAU / 16.0
		add_child(bar)
	if what == "palm":
		_palm(at)
	else:
		_tree(at, 3.6)
	var c := CylinderShape3D.new()
	c.radius = 1.8
	c.height = 2.4
	_collider(c, Vector3(at.x, 1.2, at.y))

## a big shade tree (plane, chestnut): tall trunk, wide crown made of a few clumps
func _tree(at: Vector2, crown: float) -> void:
	add_child(Parts.part("cyl", 0x8a7460, Vector3(at.x, 2.4, at.y), Vector3(0.3, 4.8, 0.3)))
	var leaf: Material = W._tmat(0x5fa846, "leaf", 1.8)
	for q in [[0.0, 6.2, 0.0, 1.0], [1.5, 5.6, 0.6, 0.72], [-1.3, 5.7, -0.9, 0.7], [0.3, 5.5, -1.6, 0.66], [-0.6, 5.4, 1.5, 0.68]]:
		var clump := MeshInstance3D.new()
		clump.mesh = Parts.mesh("ball")
		clump.material_override = leaf
		clump.position = Vector3(at.x + q[0] * crown / 3.6, q[1], at.y + q[2] * crown / 3.6)
		clump.scale = Vector3(crown, crown * 0.8, crown) * q[3]
		add_child(clump)
	var c := CylinderShape3D.new()
	c.radius = 0.4
	c.height = 5.0
	_collider(c, Vector3(at.x, 2.5, at.y))

func _slide(at: Vector2) -> void:
	add_child(Parts.part("box", 0x2f6bb5, Vector3(at.x, 0.9, at.y), Vector3(0.9, 1.8, 0.9)))
	var chute := Parts.part("box", 0xf2c230, Vector3(at.x + 1.4, 0.95, at.y), Vector3(2.4, 0.08, 0.7))
	chute.rotation.z = -0.62
	add_child(chute)
	add_child(Parts.part("cone", 0xd8342c, Vector3(at.x, 2.2, at.y), Vector3(0.8, 0.8, 0.8)))

func _swings(at: Vector2) -> void:
	for sx in [-1.3, 1.3]:
		add_child(Parts.part("box", 0xd8342c, Vector3(at.x + sx, 1.1, at.y), Vector3(0.1, 2.2, 0.1)))
	add_child(Parts.part("box", 0xd8342c, Vector3(at.x, 2.2, at.y), Vector3(2.8, 0.1, 0.1)))
	for sx in [-0.55, 0.55]:
		add_child(Parts.part("box", 0x3a3a3a, Vector3(at.x + sx, 1.35, at.y), Vector3(0.03, 1.6, 0.03)))
		add_child(Parts.part("box", 0x2f6bb5, Vector3(at.x + sx, 0.55, at.y), Vector3(0.45, 0.06, 0.22)))

func _lamp(at: Vector2) -> void:
	var iron := 0x24262b
	add_child(Parts.part("cyl", iron, Vector3(at.x, 0.35, at.y), Vector3(0.2, 0.7, 0.2)))
	add_child(Parts.part("cyl", iron, Vector3(at.x, 2.0, at.y), Vector3(0.07, 3.3, 0.07)))
	add_child(Parts.part("cyl", iron, Vector3(at.x, 3.7, at.y), Vector3(0.14, 0.1, 0.14)))
	add_child(Parts.part("box", 0xfff1c4, Vector3(at.x, 3.98, at.y), Vector3(0.26, 0.44, 0.26)))
	var lit := _world(at)
	W.lamp_spots.append(MapData.at(lit, 3.7))
	add_child(Parts.part("cone", iron, Vector3(at.x, 4.32, at.y), Vector3(0.24, 0.26, 0.24)))
	var c := CylinderShape3D.new()
	c.radius = 0.2
	c.height = 4.4
	_collider(c, Vector3(at.x, 2.2, at.y))

## the fluted stone column with its little open temple on top
func _column(at: Vector2) -> void:
	var stone := 0xd8d2c4
	add_child(Parts.part("cyl", stone, Vector3(at.x, 0.15, at.y), Vector3(1.1, 0.3, 1.1)))
	add_child(Parts.part("cyl", stone, Vector3(at.x, 0.45, at.y), Vector3(0.8, 0.3, 0.8)))
	add_child(Parts.part("cyl", stone, Vector3(at.x, 3.9, at.y), Vector3(0.42, 6.6, 0.42)))
	for k in range(12):                                 # the fluting
		var a := k * TAU / 12.0
		add_child(Parts.part("box", 0xb9b2a2, Vector3(at.x + sin(a) * 0.41, 3.9, at.y + cos(a) * 0.41), Vector3(0.04, 6.4, 0.04)))
	add_child(Parts.part("cyl", stone, Vector3(at.x, 7.35, at.y), Vector3(0.62, 0.3, 0.62)))
	for k in range(6):
		var a2 := k * TAU / 6.0
		add_child(Parts.part("cyl", stone, Vector3(at.x + sin(a2) * 0.46, 7.95, at.y + cos(a2) * 0.46), Vector3(0.07, 0.9, 0.07)))
	add_child(Parts.part("cyl", stone, Vector3(at.x, 8.5, at.y), Vector3(0.62, 0.2, 0.62)))
	var c := CylinderShape3D.new()
	c.radius = 0.85
	c.height = 8.6
	_collider(c, Vector3(at.x, 4.3, at.y))

func _bench(at: Vector2, facing: float) -> void:
	var g := Node3D.new()
	g.position = Vector3(at.x, 0, at.y)
	g.rotation.y = facing
	add_child(g)
	g.add_child(Parts.part("box", 0xd3ccbc, Vector3(0, 0.46, 0.05), Vector3(1.9, 0.14, 0.6)))
	g.add_child(Parts.part("box", 0xd3ccbc, Vector3(0, 0.85, -0.28), Vector3(1.9, 0.7, 0.14)))
	for sx in [-0.7, 0.7]:
		g.add_child(Parts.part("box", 0xbdb6a6, Vector3(sx, 0.2, 0.0), Vector3(0.2, 0.4, 0.5)))
	var b := BoxShape3D.new()
	b.size = Vector3(1.9, 1.2, 0.7)
	var cs := CollisionShape3D.new()
	cs.shape = b
	cs.transform = transform * Transform3D(Basis(Vector3.UP, facing), Vector3(at.x, 0.6, at.y))
	W.body.add_child(cs)

func _palm(at: Vector2) -> void:
	for k in range(7):                                  # a slightly leaning trunk, ringed
		add_child(Parts.part("cyl", 0x8a6038 if k % 2 == 0 else 0x7a5430, Vector3(at.x + k * 0.07, 0.45 + k * 0.9, at.y), Vector3(0.3 - k * 0.012, 0.9, 0.3 - k * 0.012)))
	var top := Vector3(at.x + 0.5, 6.6, at.y)
	for k in range(9):
		var frond := Node3D.new()
		frond.position = top
		frond.rotation = Vector3(0, k * TAU / 9.0, 0)
		add_child(frond)
		var rise := Parts.part("box", 0x3a8c4e, Vector3(0, 0.3, 0.95), Vector3(0.55, 0.05, 2.0))
		rise.rotation.x = -0.32
		frond.add_child(rise)
		var droop := Parts.part("box", 0x2f7d44, Vector3(0, 0.0, 2.75), Vector3(0.42, 0.05, 2.1))
		droop.rotation.x = 0.62
		frond.add_child(droop)
	add_child(Parts.part("ball", 0x6a4424, top, Vector3.ONE * 0.4))
	var c := CylinderShape3D.new()
	c.radius = 0.4
	c.height = 6.0
	_collider(c, Vector3(at.x, 3.0, at.y))

## the brick bandstand: a raised platform with planters along the front and three tiled brick arches at the back
func _bandstand(at: Vector2) -> void:
	var brick := _mat(0xffffff, "brick", 1.6)
	var g := Node3D.new()
	g.position = Vector3(at.x, 0, at.y)
	g.rotation.y = PI                                   # the arches stand at the back, on the car-park side; it faces the town hall
	add_child(g)
	var blk := func(size: Vector3, pos: Vector3, material: Material) -> void:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = size
		mi.mesh = bm
		mi.material_override = material
		mi.position = pos
		g.add_child(mi)
	blk.call(Vector3(13.0, 0.9, 7.0), Vector3(0, 0.45, 0), brick)
	blk.call(Vector3(13.2, 0.1, 7.2), Vector3(0, 0.95, 0), Parts.mat(0xe4ddcd))
	for i in range(3):                                  # the three arches: the middle one taller
		var x := (i - 1) * 2.6
		var h := 4.2 if i == 1 else 3.2
		for sx in [-1.0, 1.0]:
			blk.call(Vector3(0.45, h, 0.6), Vector3(x + sx * 1.05, 1.0 + h / 2.0, -2.6), brick)
		blk.call(Vector3(2.55, 0.5, 0.6), Vector3(x, 1.0 + h - 0.25, -2.6), brick)
		blk.call(Vector3(1.65, h - 0.5, 0.06), Vector3(x, 1.0 + (h - 0.5) / 2.0, -2.6), Parts.mat(0x2c2f36))       # iron lattice
		var cap := Parts.part("cone", 0xb9552f, Vector3(x, 1.0 + h + 0.4, -2.6), Vector3(1.75, 0.8, 0.75))
		g.add_child(cap)
	var petals := [0xd8342c, 0xe85a9f, 0xf2c230, 0x9b5de5, 0xffffff, 0xd8342c]
	for i in range(6):                                  # concrete planters full of flowers
		var px := -5.4 + i * 2.16
		blk.call(Vector3(2.0, 0.75, 0.9), Vector3(px, 0.38, 4.1), Parts.mat(0xcfccc4))
		for k in range(5):
			g.add_child(Parts.part("ball", petals[(i + k) % petals.size()], Vector3(px - 0.7 + k * 0.35, 0.86, 4.1 + (0.12 if k % 2 == 0 else -0.12)), Vector3.ONE * 0.16))
		g.add_child(Parts.part("box", 0x4f8f45, Vector3(px, 0.78, 4.1), Vector3(1.8, 0.1, 0.7)))
	var b := BoxShape3D.new()
	b.size = Vector3(13.2, 1.9, 8.2)
	var cs := CollisionShape3D.new()
	cs.shape = b
	cs.transform = transform * Transform3D(Basis(Vector3.UP, PI), Vector3(at.x, 0.5, at.y - 0.3))
	W.body.add_child(cs)

# ---------------- the side of the Arroyuelo ----------------
## The old stream bed runs a good two metres below the square (the bake cuts the street down: SUNK). What holds the
## square up on that side, as the user's photos of 12 November 2026 show it: a raised pavement of chequered tiles on a
## rubble wall, its kerb painted yellow and grey, iron hoops along its edge; behind it the white wall of the square
## with its railing; a wide flight of steps up to the square by the steel bridge and a narrow one at the town hall's
## corner, each with a few steps up from the street in front of it.
## All in this node's own (u, n): u along the town hall, n out from it. Heights are from the square's own level.
const EDGE := -30.2             # where the square ends above the street
const END_WALL := -32.75        # ...and beside the end of the town hall
const JOG := 3.6                # the wall steps from the one to the other in front of the arcade
const SW_END := 89.45           # where the wall meets the square's south-west side
const PAV := 0.8                # the raised pavement, above the street (the steel bridge's deck is at the same height)
const KERB: Array = [Vector2(-34.45, -4.0), Vector2(-35.45, 40.0), Vector2(-38.15, 90.0)]       # the line of its rubble wall
const BIG_STAIRS := Vector2(35.0, 42.0)         # (n) the wide flight up to the square
const END_STAIRS := Vector2(3.8, 5.8)           # the narrow one at the corner
const ROAD_STEPS: Array = [Vector2(36.5, 40.5), Vector2(3.4, 6.4)]      # steps up from the street
const BRIDGE_GAP := Vector2(31.9, 34.5)         # where the steel bridge comes ashore (pasarela.gd)
const RISERS := 6

const TILE_SHADER := "
shader_type spatial;
render_mode cull_disabled;
varying vec3 at;
void vertex() {
	at = VERTEX;
}
void fragment() {
	vec2 g = at.xz / 0.42;
	vec2 cell = floor(g);
	vec2 f = fract(g);
	float joint = step(0.045, f.x) * step(0.045, f.y);
	float wear = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	vec3 tile = mix(vec3(0.84, 0.78, 0.66), vec3(0.60, 0.36, 0.31), mod(cell.x + cell.y, 2.0)) * (0.9 + 0.14 * wear);
	ALBEDO = mix(vec3(0.5, 0.47, 0.43), tile, joint);
	ROUGHNESS = 1.0;
}
"

var _low := 0.0                 # the street, from the square's level (about -SUNK; near 0 on a map baked before that)

func _kerb_u(n: float) -> float:
	for k in range(KERB.size() - 1):
		var a: Vector2 = KERB[k]
		var b: Vector2 = KERB[k + 1]
		if n <= b.y or k == KERB.size() - 2:
			return lerpf(a.x, b.x, (n - a.y) / (b.y - a.y))
	return KERB[KERB.size() - 1].x

func _in(n: float, span: Vector2) -> bool:
	return n > span.x and n < span.y

func _faces(quads: Array, material: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for q in quads:
		for k in [0, 1, 2, 0, 2, 3]:
			st.add_vertex(q[k])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = material
	add_child(mi)

## a solid with this outline (u, n) between two heights, for cars and people to stand on or run into
func _prism(pts: Array, y0: float, y1: float) -> void:
	var shape := ConvexPolygonShape3D.new()
	var v := PackedVector3Array()
	for q in pts:
		v.append(Vector3(q.x, y0, q.y))
		v.append(Vector3(q.x, y1, q.y))
	shape.points = v
	_collider(shape, Vector3.ZERO)

func _turned_collider(size: Vector3, pos: Vector3, turn: float) -> void:
	var b := BoxShape3D.new()
	b.size = size
	var cs := CollisionShape3D.new()
	cs.shape = b
	cs.transform = transform * Transform3D(Basis(Vector3.UP, turn), pos)
	W.body.add_child(cs)

func _poly_deck(pts: PackedVector2Array, top: float) -> Dictionary:
	var world_pts := PackedVector2Array()
	var mid := Vector2.ZERO
	for q in pts:
		world_pts.append(_world(q))
		mid += _world(q) / pts.size()
	var r2 := 0.0
	for q in world_pts:
		r2 = maxf(r2, mid.distance_squared_to(q))
	return {"o": mid, "r2": r2 + 1.0, "poly": world_pts, "top": top}

func _sunk_side() -> void:
	if _low > -0.6:
		return                  # (a map baked before the street was sunk: the square is at street level, as it was)
	var here: float = position.y
	var pav: float = _low + PAV
	var rubble := _mat(0xa59884, "earth", 1.1)
	var white := Parts.mat(0xf3f0e8)
	var step_stone := Parts.mat(0xb9b2a6)
	var iron := 0x24262b
	var sh := Shader.new()
	sh.code = TILE_SHADER
	var tiles := ShaderMaterial.new()
	tiles.shader = sh
	var u_axis: Vector2 = _world(Vector2(1, 0)) - _world(Vector2.ZERO)
	var n_axis: Vector2 = _world(Vector2(0, 1)) - _world(Vector2.ZERO)
	var decks: Array = []       # flights of steps and ramps first: they lie over the floors they join

	# --- the raised pavement, its rubble wall, and a ramp down to the street at each end ---
	var k0: Vector2 = KERB[0]
	var k2: Vector2 = KERB[KERB.size() - 1]
	var floor_pts := PackedVector2Array([k0, KERB[1], k2, Vector2(EDGE, SW_END), Vector2(EDGE, JOG), Vector2(END_WALL, JOG), Vector2(END_WALL, k0.y)])
	_flat_local(floor_pts, pav, tiles)
	var faces: Array = []
	for k in range(KERB.size() - 1):
		var a: Vector2 = KERB[k]
		var b: Vector2 = KERB[k + 1]
		faces.append([Vector3(a.x, pav, a.y), Vector3(b.x, pav, b.y), Vector3(b.x, _low - 0.5, b.y), Vector3(a.x, _low - 0.5, a.y)])
	var run := 2.8
	var north: Array = [Vector3(k0.x, pav, k0.y), Vector3(END_WALL, pav, k0.y), Vector3(END_WALL, _low + 0.03, k0.y - run), Vector3(k0.x, _low + 0.03, k0.y - run)]
	var south: Array = [Vector3(k2.x, pav, k2.y), Vector3(EDGE, pav, SW_END), Vector3(EDGE, _low + 0.03, SW_END + run), Vector3(k2.x, _low + 0.03, k2.y + run)]
	_faces([north, south], tiles)
	faces.append([north[0], north[3], Vector3(k0.x, _low - 0.5, k0.y), Vector3(k0.x, _low - 0.5, k0.y)])
	faces.append([south[0], south[3], Vector3(k2.x, _low - 0.5, k2.y), Vector3(k2.x, _low - 0.5, k2.y)])
	_faces(faces, rubble)
	_prism([k0, KERB[1], Vector2(EDGE, KERB[1].y), Vector2(EDGE, JOG), Vector2(END_WALL, JOG), Vector2(END_WALL, k0.y)], _low - 0.3, pav)
	_prism([KERB[1], k2, Vector2(EDGE, SW_END), Vector2(EDGE, KERB[1].y)], _low - 0.3, pav)
	for ramp in [north, south]:
		var wedge := ConvexPolygonShape3D.new()
		wedge.points = PackedVector3Array([ramp[0], ramp[1], ramp[2], ramp[3], Vector3(ramp[0].x, _low - 0.3, ramp[0].z), Vector3(ramp[1].x, _low - 0.3, ramp[1].z)])
		_collider(wedge, Vector3.ZERO)
	decks.append({"o": _world(Vector2((k0.x + END_WALL) / 2.0, k0.y - run / 2.0)), "ax": n_axis, "half": run / 2.0, "wide": (END_WALL - k0.x) / 2.0, "top": here + pav, "ramp": run, "low": here + _low})
	decks.append({"o": _world(Vector2((k2.x + EDGE) / 2.0, k2.y + run / 2.0)), "ax": -n_axis, "half": run / 2.0, "wide": (EDGE - k2.x) / 2.0, "top": here + pav, "ramp": run, "low": here + _low})

	# --- its kerb, yellow and grey by turns; iron hoops along it, except where steps or the steel bridge come up ---
	var n: float = k0.y
	var count := 0
	while n < k2.y - 0.01:
		var mid: float = n + 0.5
		var ku: float = _kerb_u(mid)
		add_child(Parts.part("box", 0xe6b422 if count % 2 == 0 else 0x8f8a80, Vector3(ku + 0.13, pav - 0.05, mid), Vector3(0.28, 0.14, 1.0)))
		var open: bool = _in(mid, BRIDGE_GAP)
		for s in ROAD_STEPS:
			open = open or _in(mid, s)
		if not open:
			var hoop := Parts.part("ring_thin", iron, Vector3(ku + 0.3, pav, mid), Vector3.ONE * 0.48)
			hoop.rotation.z = PI / 2.0
			add_child(hoop)
			_box_collider(Vector3(0.14, PAV + 0.95, 1.0), Vector3(ku + 0.07, _low + (PAV + 0.95) / 2.0, mid))
		n += 1.0
		count += 1

	# --- steps up from the street to the pavement ---
	for s in ROAD_STEPS:
		var mid: float = (s.x + s.y) / 2.0
		var ku: float = _kerb_u(mid)
		for k in range(3):
			var hgt: float = PAV * (k + 1) / 4.0
			_block(Vector3(0.3, hgt, s.y - s.x), Vector3(ku - (2.5 - k) * 0.3, _low + hgt / 2.0, mid), step_stone)
		decks.append({"o": _world(Vector2(ku - 0.45, mid)), "ax": u_axis, "half": 0.45, "wide": (s.y - s.x) / 2.0, "top": here + pav, "ramp": 0.9, "low": here + _low})

	# --- the flights up from the pavement to the square ---
	var rise: float = -pav / RISERS
	var going := 0.3
	var flight: float = going * (RISERS - 1)
	for span in [BIG_STAIRS, END_STAIRS]:
		var mid: float = (span.x + span.y) / 2.0
		for k in range(RISERS - 1):
			var deep: float = (RISERS - 1 - k) * going
			_block(Vector3(deep, rise * (k + 1), span.y - span.x), Vector3(EDGE - deep / 2.0, pav + rise * (k + 1) / 2.0, mid), step_stone)
		for side in [span.x, span.y]:       # a handrail down each side
			var rail := Parts.part("box", iron, Vector3(EDGE - flight / 2.0, pav / 2.0 + 0.95, side), Vector3(Vector2(flight, -pav).length(), 0.05, 0.05))
			rail.rotation.z = atan2(-pav, flight)
			add_child(rail)
			add_child(Parts.part("box", iron, Vector3(EDGE - flight, pav + 0.5, side), Vector3(0.05, 1.0, 0.05)))
			add_child(Parts.part("box", iron, Vector3(EDGE, 0.5, side), Vector3(0.05, 1.0, 0.05)))
		decks.append({"o": _world(Vector2(EDGE - flight / 2.0, mid)), "ax": u_axis, "half": flight / 2.0, "wide": (span.y - span.x) / 2.0, "top": here, "ramp": flight, "low": here + pav})

	# --- the wall that holds the square up, wherever the ground outside is lower: white, a low parapet, a railing ---
	var outline := PackedVector2Array([Vector2(END_WALL, -5.2), Vector2(32.75, -5.2), Vector2(34.47, 56.57), Vector2(27.96, 61.06), Vector2(16.77, 67.44),
		Vector2(EDGE, SW_END), Vector2(EDGE, JOG), Vector2(END_WALL, JOG)])
	var centre := Vector2(0.0, 35.0)
	for k in range(outline.size()):
		var a: Vector2 = outline[k]
		var b: Vector2 = outline[(k + 1) % outline.size()]
		var d: Vector2 = (b - a).normalized()
		var out := Vector2(d.y, -d.x)
		if out.dot((a + b) / 2.0 - centre) < 0.0:
			out = -out
		var turn: float = atan2(-d.y, d.x)
		var pieces: int = maxi(1, int(ceil(a.distance_to(b) / 1.5)))
		var pl: float = a.distance_to(b) / pieces
		var on_edge: bool = absf(a.x - EDGE) < 0.01 and absf(b.x - EDGE) < 0.01
		for j in range(pieces):
			var mid: Vector2 = a + d * (j + 0.5) * pl
			if on_edge and (_in(mid.y, BIG_STAIRS) or _in(mid.y, END_STAIRS)):
				continue
			var h: float = MapData.height(_world(mid + out * 0.6)) - here
			if h > -0.12:
				continue
			var at: Vector2 = mid - out * 0.13
			var foot_y: float = h - 0.4
			var wall := _block(Vector3(pl + 0.02, 0.35 - foot_y, 0.26), Vector3(at.x, (0.35 + foot_y) / 2.0, at.y), white)
			wall.rotation.y = turn
			if h > -0.6:
				continue
			var rails := Node3D.new()
			rails.position = Vector3(at.x, 0.35, at.y)
			rails.rotation.y = turn
			add_child(rails)
			rails.add_child(Parts.part("box", iron, Vector3(0, 0.72, 0), Vector3(pl + 0.02, 0.05, 0.05)))
			rails.add_child(Parts.part("box", iron, Vector3(0, 0.36, 0), Vector3(pl + 0.02, 0.035, 0.035)))
			rails.add_child(Parts.part("box", iron, Vector3(-pl / 2.0, 0.37, 0), Vector3(0.05, 0.74, 0.05)))
			_turned_collider(Vector3(pl + 0.02, 1.1 - h, 0.26), Vector3(at.x, (1.1 + h) / 2.0, at.y), turn)

	# --- floors: the square itself (the ground under its west side has gone down with the street), and the pavement ---
	_prism([Vector2(EDGE, JOG), Vector2(16.0, JOG), Vector2(16.0, 67.7), Vector2(EDGE, SW_END)], -0.6, 0.0)
	_prism([Vector2(END_WALL, -5.2), Vector2(16.0, -5.2), Vector2(16.0, JOG), Vector2(END_WALL, JOG)], -0.6, 0.0)
	decks.append(_poly_deck(floor_pts, here + pav))
	decks.append(_poly_deck(outline, here))
	MapData.decks = decks + MapData.decks
