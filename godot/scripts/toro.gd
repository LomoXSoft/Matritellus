extends RefCounted
## The Osborne bull on the A-4 at km 120, just south of the town (the user, 14 November 2026: "poner el toro de
## Osborne en su situación"). Where it stands comes from three sources that agree within 3 m: Google's place for it,
## two Street View panoramas from the motorway, and the geolocation of the model "Toro en Madridejos" (3D Warehouse,
## by Fdiaz.osborne). Its outline was traced from that model's south elevation (tools/toro/silueta.py ->
## data/toro.json); the steel frame behind it and the clay bank it stands on are built here from the photos.
## It is past the map's south edge (z 1905): nobody walks up to it, it is seen from the motorway, as on the road.
## No words on it: the bulls on the roads carry none.

const Parts = preload("res://scripts/parts.gd")

const WHERE := Vector2(669.5, 1980.5)      # map metres (x east, z south)
const HEAD := 80.0                          # heading its head points to (Street View: east-north-east)
const LIFT := 0.45                          # its hooves stand on short posts above the top of the bank
const BANK_LONG := 46.0                     # the clay bank: half-length along the bull, half-width across, height
const BANK_WIDE := 21.0
const BANK_HIGH := 5.0
const SHEET := 0x141414
const STEEL := 0x8a8e92
const CLAY := 0xb06a44
const GRASS := 0xb6a36c

static func add(world) -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/toro.json"))
	if data == null:
		return
	var root := Node3D.new()
	root.name = "ToroOsborne"
	world.add_child(root)
	var ground := MapData.height(WHERE)
	_bank(root, ground)
	# the bull's own frame: x from its head towards its tail, y up, z out of the side the motorway sees (north)
	var h := deg_to_rad(HEAD + 180.0)
	var ax := Vector3(sin(h), 0.0, -cos(h))
	var bull := Node3D.new()
	bull.name = "Toro"
	bull.transform = Transform3D(Basis(ax, Vector3.UP, ax.cross(Vector3.UP)), Vector3(WHERE.x, ground + BANK_HIGH + LIFT, WHERE.y))
	root.add_child(bull)
	var w: float = data["width"]
	bull.position -= ax * (w / 2.0)             # (WHERE is its middle)
	_sheet(bull, data)
	_frame(bull, data)

## the black sheet: one face, seen from both sides
static func _sheet(bull: Node3D, data: Dictionary) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for pc in data["pieces"]:
		var poly := PackedVector2Array()
		for p in pc:
			poly.append(Vector2(p[0], p[1]))
		var idx := Geometry2D.triangulate_polygon(poly)
		for i in range(0, idx.size(), 3):
			for k in [0, 2, 1]:                  # (counter-clockwise with y up, so clockwise from the north: its front)
				var q: Vector2 = poly[idx[i + k]]
				st.set_normal(Vector3(0, 0, 1))
				st.add_vertex(Vector3(q.x, q.y, 0.0))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.albedo_color = Parts.col(SHEET)
	m.roughness = 0.75
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	bull.add_child(mi)

## how high the sheet reaches at x (the top of its outline there), and how low it starts
static func _span(outline: Array, x: float) -> Vector2:
	var lo := 1e9
	var hi := -1e9
	for i in range(outline.size()):
		var a: Array = outline[i]
		var b: Array = outline[(i + 1) % outline.size()]
		if (a[0] - x) * (b[0] - x) <= 0.0 and a[0] != b[0]:
			var y: float = a[1] + (b[1] - a[1]) * (x - a[0]) / (b[0] - a[0])
			lo = minf(lo, y)
			hi = maxf(hi, y)
	return Vector2(lo, hi)

## the galvanised steel frame behind it (on its south side): uprights along the bull, each with a raking strut back
## to the ground, ties between them and a cross in every bay -- as the photo from the farm track shows it
static func _frame(bull: Node3D, data: Dictionary) -> void:
	var outline: Array = data["outline"]
	var w: float = data["width"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cols: Array = []                        # [x, top]
	var x := 0.9
	while x < w - 0.4:
		var sp := _span(outline, x)
		if sp.y > 2.0:
			cols.append([x, sp.y - 0.35])
		x += 1.45
	var step := 1.55
	for c in cols:
		var cx: float = c[0]
		var top: float = c[1]
		var back := 0.18 + top * 0.24            # how far back the strut's foot stands
		_bar(st, Vector3(cx, -LIFT, -0.2), Vector3(cx, top, -0.2), 0.11)
		_bar(st, Vector3(cx, -LIFT, -0.2 - back), Vector3(cx, top * 0.88, -0.32), 0.09)
		var y := step
		while y < top * 0.85:
			var dz := -0.2 - back * (1.0 - y / (top * 0.88))
			_bar(st, Vector3(cx, y, -0.2), Vector3(cx, y, dz), 0.06)
			y += step
	for i in range(cols.size() - 1):
		var a: Array = cols[i]
		var b: Array = cols[i + 1]
		var reach := minf(a[1], b[1])
		var y := 0.6
		while y + step <= reach:
			_bar(st, Vector3(a[0], y, -0.26), Vector3(b[0], y, -0.26), 0.06)
			_bar(st, Vector3(a[0], y, -0.26), Vector3(b[0], y + step, -0.26), 0.05)
			_bar(st, Vector3(b[0], y, -0.26), Vector3(a[0], y + step, -0.26), 0.05)
			y += step
		_bar(st, Vector3(a[0], y, -0.26), Vector3(b[0], y, -0.26), 0.06)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.albedo_color = Parts.col(STEEL)
	m.metallic = 0.4
	m.roughness = 0.55
	mi.material_override = m
	bull.add_child(mi)

## a square bar from a to b, t thick
static func _bar(st: SurfaceTool, a: Vector3, b: Vector3, t: float) -> void:
	var d := (b - a).normalized()
	var s := d.cross(Vector3.UP if absf(d.y) < 0.9 else Vector3.RIGHT).normalized() * (t / 2.0)
	var u := d.cross(s).normalized() * (t / 2.0)
	var c := [s + u, -s + u, -s - u, s - u]
	for i in range(4):
		var p0: Vector3 = c[i]
		var p1: Vector3 = c[(i + 1) % 4]
		_quad(st, [a + p0, b + p0, b + p1, a + p1], (p0 + p1).normalized())

static func _quad(st: SurfaceTool, q: Array, n: Vector3) -> void:
	var a: Vector3 = q[0]
	var b: Vector3 = q[1]
	var c: Vector3 = q[2]
	var d: Vector3 = q[3]
	if (b - a).cross(c - a).dot(n) > 0.0:       # (Godot draws clockwise faces: turn it round)
		var t := b
		b = d
		d = t
	for v in [a, b, c, a, c, d]:
		st.set_normal(n)
		st.add_vertex(v)

## the bank of red clay it stands on, its top grown over with dry grass, long along the bull
static func _bank(root: Node3D, ground: float) -> void:
	var h := deg_to_rad(HEAD)
	var al := Vector2(sin(h), -cos(h))
	var ac := Vector2(-al.y, al.x)
	var n := 28
	var pts: Array = []
	var cols: Array = []
	for j in range(n + 1):
		var row: Array = []
		var crow: Array = []
		for i in range(n + 1):
			var u := (i / float(n)) * 2.0 - 1.0
			var v := (j / float(n)) * 2.0 - 1.0
			var r := sqrt(u * u + v * v)
			var k := clampf(1.0 - r, 0.0, 1.0)
			var lift := BANK_HIGH * smoothstep(0.0, 0.55, k)       # steep clay sides, a broad flat top
			var p := WHERE + al * (u * BANK_LONG * 1.25) + ac * (v * BANK_WIDE * 1.25)
			row.append(Vector3(p.x, MapData.height(p) + lift - (0.3 if k <= 0.0 else 0.0), p.y))
			crow.append(Parts.col(GRASS).lerp(Parts.col(CLAY), 0.15) if k > 0.42 else Parts.col(CLAY) if k > 0.02 else Parts.col(GRASS).darkened(0.1))
		pts.append(row)
		cols.append(crow)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(n):
		for i in range(n):
			for tri in [[[i, j], [i + 1, j], [i + 1, j + 1]], [[i, j], [i + 1, j + 1], [i, j + 1]]]:
				var a: Vector3 = pts[tri[0][1]][tri[0][0]]
				var b: Vector3 = pts[tri[1][1]][tri[1][0]]
				var c: Vector3 = pts[tri[2][1]][tri[2][0]]
				var order := [0, 1, 2] if (b - a).cross(c - a).y < 0.0 else [0, 2, 1]
				var nrm := (b - a).cross(c - a).normalized()
				if nrm.y < 0.0:
					nrm = -nrm
				for o in order:
					var q: Array = tri[o]
					st.set_color(cols[q[1]][q[0]])
					st.set_normal(nrm)
					st.add_vertex(pts[q[1]][q[0]])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true            # (the colours are paint, not light)
	m.roughness = 1.0
	mi.material_override = m
	root.add_child(mi)
