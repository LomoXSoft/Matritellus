extends Node3D
## The A-4 by the cemetery, seen from its zone (zonas.gd), with its traffic (the user, 25 Nov 2026: «hacia el
## norte/oeste podríamos ver la autovía A4 uniéndose a la carretera, con .PNG de coches y camiones viajando»).
##   - Where it really runs (OpenStreetMap, tools/cementerio/autovia.py -> data/autovia.json): its two carriageways by
##     the cemetery's east wall, 45-60 m from it, and on north to the horizon; the old road ends 515 m north of the
##     cemetery's middle, where a loop takes you on to the southbound carriageway and a slip road brings the southbound
##     traffic off it. Two lanes and hard shoulders each way, the guardrail down the middle, and the motorway's wire
##     fence on the cemetery's side, which you cannot get through (the zone's circle takes in the motorway's west edge).
##   - Its traffic: cars and lorries as pictures (assets/autovia/trafico.png, drawn from the game's own cars and the
##     kit's lorries by lejanias.gd: sixteen views round each), turned to face you and showing the side you see them
##     from, at motorway speeds, keeping their distance; their lamps lit at night. Only drawn and moved while the camera
##     is in the zone: from the town it is not there (the map has no A-4 north of its south end).
const PartsA = preload("res://scripts/parts.gd")
const DATA := "res://data/autovia.json"
const BODY := "res://assets/autovia/trafico.png"
const GLOW := "res://assets/autovia/trafico_luces.png"
const LANE := 3.6
const CARRIAGE := [-4.6, 6.1]           # a carriageway's asphalt across its OSM line (to its right, the way it goes): the inner shoulder, two lanes, the hard shoulder
const RAMP := [-2.6, 3.3]               # a slip road's
const FENCE := 12.0                     # the fence: this far right of the southbound carriageway's line (west, the cemetery's side)
const RAIL := -5.1                      # the guardrail down the middle, on each carriageway's inner side
const STEP := 6.0                       # strips no longer than this (the land rises and falls between the plain's columns)
## the pictures' rows (lejanias_foto.gd draws them): [the model -- a car of the game's (car.gd, Modelos SK) or a lorry
## (LORRIES, built by lejanias_foto.gd: the kit has none) --, its paint, a lorry, how often (of its lane's)]; a car's
## frames are 12 x 6 m round it, a lorry's that times its frame's size
const KINDS := [["panda", 0xb3261e, false, 1.0], ["panda", 0xe9e7e1, false, 0.8], ["cuatrolatas", 0xdcd6c4, false, 0.5],
	["z15", 0xf2f2ee, false, 0.9], ["edison", 0x1c1d20, false, 1.0], ["edison", 0xb8bcc2, false, 1.0], ["julietta", 0x2a4f8f, false, 0.8],
	["julietta", 0x5a5f66, false, 1.0], ["trailer", 0, true, 1.0], ["lona", 0, true, 0.9], ["cisterna", 0, true, 0.5], ["rigido", 0, true, 0.6]]
const LORRIES := {"trailer": [16.5, 2.55, 1.5], "lona": [16.5, 2.55, 1.5], "cisterna": [16.0, 2.55, 1.5], "rigido": [9.5, 2.5, 1.0]}     # its length and width (m), its frame's size
const FRAMES := 16
const BOTTOM := -0.3                    # a frame's bottom edge, under the ground it stands on (lejanias.gd draws them so)
const VEH_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
uniform sampler2D body : source_color, filter_linear_mipmap;
uniform sampler2D glow : source_color, filter_linear_mipmap;
uniform vec3 lit = vec3(1.0);
uniform float night = 0.0;
uniform float rows = 9.0;
uniform float frames = 16.0;
varying vec2 tuv;
void vertex() {
	vec3 o = MODEL_MATRIX[3].xyz;
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec2 to_cam = cam.xz - o.xz;
	to_cam /= max(length(to_cam), 0.001);
	vec2 f = INSTANCE_CUSTOM.xy;                                   // the way it goes
	vec2 r = vec2(-f.y, f.x);                                      // its right
	float az = atan(dot(to_cam, r), dot(to_cam, f));               // where it is seen from, round it (0: its nose)
	float k = mod(floor(az / (TAU / frames) + 0.5) + frames, frames);
	vec2 side = vec2(to_cam.y, -to_cam.x);                         // the camera's right, along the ground
	vec3 w = o + (vec3(side.x, 0.0, side.y) * VERTEX.x + vec3(0.0, VERTEX.y, 0.0)) * INSTANCE_CUSTOM.w;     // (a lorry's frame, bigger)
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(w, 1.0);
	tuv = vec2((k + UV.x) / frames, (INSTANCE_CUSTOM.z + UV.y) / rows);
}
void fragment() {
	vec4 b = texture(body, tuv);
	vec3 g = texture(glow, tuv).rgb;
	ALBEDO = b.rgb * lit + g * night * 1.8;
	ALPHA = max(b.a, clamp(dot(g, vec3(0.6)) * night * 2.0, 0.0, 1.0));
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
"""
const WIRE_SHADER := """
shader_type spatial;
render_mode cull_disabled, shadows_disabled, depth_draw_never;
uniform vec3 tint : source_color = vec3(0.42, 0.45, 0.42);
void fragment() {
	vec2 m = UV / 0.15;                                              // a 15 cm mesh of wire (UV in metres along and up)
	vec2 g = abs(fract(m) - 0.5);
	float fw = max(fwidth(m.x), fwidth(m.y));
	float wire = smoothstep(0.44 - fw, 0.44 + fw, max(g.x, g.y));
	ALBEDO = tint;
	ROUGHNESS = 0.7;
	ALPHA = mix(wire * 0.75, 0.22, clamp(fw * 2.0 - 0.5, 0.0, 1.0));   // (far off, an even grey veil: no shimmer)
}
"""

var G
var zone: Dictionary
var lines := {}                         # sb, nb, entrada, salida -> PackedVector2Array (the way they go)
var fence: PackedVector2Array           # the fence's line
var _grid := {}                         # Vector2i (32 m) -> [[a, b, reach]...]: the asphalt near each square (gap)
var _asphalt: Material
var _paint: StandardMaterial3D
var _metal: StandardMaterial3D
var _lanes: Array = []                  # {pts: PackedVector2Array, len: PackedFloat32Array, cars: [{s, v, want, row}], lorries: bool}
var _mm: MultiMesh
var _veh_mat: ShaderMaterial
var _rng := RandomNumberGenerator.new()
var traffic_on := false                 # the pictures are there (lejanias.gd has drawn them)
var shown := false

func setup(game, z: Dictionary) -> void:
	G = game
	zone = z
	name = "autovia_%s" % z["id"]
	var f := FileAccess.open(DATA, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if not (data is Dictionary):
		return
	for key in ["sb", "nb", "entrada", "salida"]:
		var pl := PackedVector2Array()
		for q in data.get(key, []):
			pl.append(Vector2(float(q[0]), float(q[1])))
		lines[key] = pl
	_asphalt = G.world._tmat(0x77727a, "asphalt", 3.0) if G.world != null and G.world.has_method("_tmat") else null
	_paint = StandardMaterial3D.new()
	_paint.albedo_color = Color(0.92, 0.92, 0.9)
	_paint.roughness = 0.9
	_metal = StandardMaterial3D.new()
	_metal.albedo_color = Color(0.68, 0.7, 0.72)
	_metal.metallic = 0.5
	_metal.roughness = 0.45
	_metal.cull_mode = BaseMaterial3D.CULL_DISABLED
	_draw()
	_fence()
	_index()
	_traffic()
	visible = false

# ---------------- where it is ----------------
## how far a spot is from the edge of the A-4's asphalt or its slip roads' (negative on it): for the zone's dry plants
## and trees to keep off (zonas.gd _road_gap)
func gap(p: Vector2) -> float:
	var best := 1e9
	for e in _grid.get(Vector2i(floori(p.x / 32.0), floori(p.y / 32.0)), []):
		var q: Vector2 = Geometry2D.get_closest_point_to_segment(p, e[0], e[1])
		best = minf(best, p.distance_to(q) - float(e[2]))
	return best

func _index() -> void:
	for key in lines:
		var reach: float = (RAMP[1] if key in ["entrada", "salida"] else CARRIAGE[1])
		var pl: PackedVector2Array = lines[key]
		for i in range(pl.size() - 1):
			_index_seg(pl[i], pl[i + 1], reach)
	for i in range(fence.size() - 1):
		_index_seg(fence[i], fence[i + 1], 0.6)

func _index_seg(a: Vector2, b: Vector2, reach: float) -> void:
	var lo := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2.ONE * (reach + 12.0)
	var hi := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2.ONE * (reach + 12.0)
	for i in range(floori(lo.x / 32.0), floori(hi.x / 32.0) + 1):
		for j in range(floori(lo.y / 32.0), floori(hi.y / 32.0) + 1):
			var c := Vector2(i + 0.5, j + 0.5) * 32.0
			var q: Vector2 = Geometry2D.get_closest_point_to_segment(c, a, b)
			if c.distance_to(q) < 23.0 + reach + 12.0:
				var k := Vector2i(i, j)
				if not _grid.has(k):
					_grid[k] = []
				(_grid[k] as Array).append([a, b, reach])

## a polyline made fine (pieces no longer than STEP), with the way across it at each point (mitred)
static func _fine(pl: PackedVector2Array) -> Array:
	var pts := PackedVector2Array()
	for i in range(pl.size() - 1):
		var n := maxi(1, int(ceil(pl[i].distance_to(pl[i + 1]) / STEP)))
		for k in range(n):
			pts.append(pl[i].lerp(pl[i + 1], float(k) / n))
	pts.append(pl[pl.size() - 1])
	var rights := PackedVector2Array()
	for i in range(pts.size()):
		var d0: Vector2 = (pts[i] - pts[maxi(i - 1, 0)]).normalized() if i > 0 else (pts[1] - pts[0]).normalized()
		var d1: Vector2 = (pts[mini(i + 1, pts.size() - 1)] - pts[i]).normalized() if i < pts.size() - 1 else d0
		var d := (d0 + d1).normalized()
		var r := Vector2(-d.y, d.x)
		var mitre := maxf(0.5, r.dot(Vector2(-d0.y, d0.x)))
		rights.append(r / mitre)
	return [pts, rights]

## a ribbon along a fine polyline from e0 to e1 across it (to its right), lift over the ground, uv in metres
static func _ribbon(st: SurfaceTool, fine: Array, e0: float, e1: float, lift: float, dash := Vector2.ZERO) -> void:
	var pts: PackedVector2Array = fine[0]
	var rights: PackedVector2Array = fine[1]
	var s := 0.0
	for i in range(pts.size() - 1):
		var ln := pts[i].distance_to(pts[i + 1])
		if dash != Vector2.ZERO and fmod(s, dash.x + dash.y) > dash.x:
			s += ln
			continue
		var q := [pts[i] + rights[i] * e0, pts[i] + rights[i] * e1, pts[i + 1] + rights[i + 1] * e1, pts[i + 1] + rights[i + 1] * e0]
		var uv := [Vector2(e0, s), Vector2(e1, s), Vector2(e1, s + ln), Vector2(e0, s + ln)]
		for t in [[0, 2, 1], [0, 3, 2]]:
			for k in t:
				var w: Vector2 = q[k]
				st.set_uv(uv[k])
				st.set_normal(Vector3.UP)
				st.add_vertex(Vector3(w.x, MapData.height(w) + lift, w.y))
		s += ln

## a wall along a fine polyline at `at` across it, from y0 to y1 over the ground (both faces: cull disabled)
static func _band(st: SurfaceTool, fine: Array, at: float, y0: float, y1: float) -> void:
	var pts: PackedVector2Array = fine[0]
	var rights: PackedVector2Array = fine[1]
	var s := 0.0
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i] + rights[i] * at
		var b: Vector2 = pts[i + 1] + rights[i + 1] * at
		var ln := a.distance_to(b)
		var ha: float = MapData.height(a)
		var hb: float = MapData.height(b)
		var q := [Vector3(a.x, ha + y0, a.y), Vector3(b.x, hb + y0, b.y), Vector3(b.x, hb + y1, b.y), Vector3(a.x, ha + y1, a.y)]
		var uv := [Vector2(s, y1 - y0), Vector2(s + ln, y1 - y0), Vector2(s + ln, 0.0), Vector2(s, 0.0)]
		var nn := Vector3(rights[i].x, 0.0, rights[i].y)
		for t in [[0, 1, 2], [0, 2, 3]]:
			for k in t:
				st.set_uv(uv[k])
				st.set_normal(nn)
				st.add_vertex(q[k])
		s += ln

func _mesh(st: SurfaceTool, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

# ---------------- what it looks like ----------------
func _draw() -> void:
	var road := SurfaceTool.new()
	road.begin(Mesh.PRIMITIVE_TRIANGLES)
	var paint := SurfaceTool.new()
	paint.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rail := SurfaceTool.new()
	rail.begin(Mesh.PRIMITIVE_TRIANGLES)
	for key in ["sb", "nb"]:
		var fine := _fine(lines[key])
		_ribbon(road, fine, CARRIAGE[0], CARRIAGE[1], 0.03)
		for e in [-LANE, LANE]:                                    # its edge lines, solid
			_ribbon(paint, fine, e - 0.08, e + 0.08, 0.045)
		_ribbon(paint, fine, -0.08, 0.08, 0.045, Vector2(4.5, 9.0))      # and between its lanes, broken
		_band(rail, fine, RAIL, 0.45, 0.78)                        # the guardrail down the middle
	for key in ["entrada", "salida"]:
		var fine := _fine(lines[key])
		_ribbon(road, fine, RAMP[0], RAMP[1], 0.025)
		for e in [-1.8, 1.8]:
			_ribbon(paint, fine, e - 0.08, e + 0.08, 0.04)
	road.generate_normals()
	_mesh(road, _asphalt if _asphalt != null else _paint)
	_mesh(paint, _paint)
	_mesh(rail, _metal)

## the wire fence along the cemetery's side of it: from where the loop joins the southbound carriageway, south as far
## as it is drawn; posts every 3 m and the wire between; solid where you could reach it, in the zone's circle
func _fence() -> void:
	var sb: PackedVector2Array = lines.get("sb", PackedVector2Array())
	var ent: PackedVector2Array = lines.get("entrada", PackedVector2Array())
	if sb.size() < 2 or ent.size() < 2:
		return
	var merge: Vector2 = ent[ent.size() - 1]
	var from := 0
	var best := 1e9
	for i in range(sb.size()):
		if sb[i].distance_to(merge) < best:
			best = sb[i].distance_to(merge)
			from = i
	var part := PackedVector2Array()
	for i in range(from, sb.size()):
		part.append(sb[i])
	var fine := _fine(part)
	var pts: PackedVector2Array = fine[0]
	var rights: PackedVector2Array = fine[1]
	for i in range(pts.size()):
		fence.append(pts[i] + rights[i] * FENCE)
	var wire := SurfaceTool.new()
	wire.begin(Mesh.PRIMITIVE_TRIANGLES)
	_band(wire, fine, FENCE, 0.0, 2.0)
	var wm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = WIRE_SHADER
	wm.shader = sh
	_mesh(wire, wm)
	var posts: Array = []
	var s := 0.0
	var c: Vector2 = zone["centre"]
	var rad: float = zone["radius"]
	var body := StaticBody3D.new()
	body.name = "autovia_valla"
	add_child(body)
	for i in range(fence.size() - 1):
		var a: Vector2 = fence[i]
		var b: Vector2 = fence[i + 1]
		var ln := a.distance_to(b)
		while s < ln:
			var p := a.lerp(b, s / ln)
			posts.append(Transform3D(Basis.from_scale(Vector3(0.06, 2.1, 0.06)), Vector3(p.x, MapData.height(p) + 1.05, p.y)))
			s += 3.0
		s -= ln
		var mid := (a + b) / 2.0
		if mid.distance_to(c) < rad + 20.0:                       # (solid where it can be reached)
			var cs := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = Vector3(ln + 0.4, 3.0, 0.4)
			cs.shape = bs
			var d := (b - a) / ln
			cs.transform = Transform3D(Basis(Vector3.UP, atan2(-d.y, d.x)), Vector3(mid.x, MapData.height(mid) + 1.5, mid.y))
			body.add_child(cs)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var post := BoxMesh.new()
	post.size = Vector3.ONE
	mm.mesh = post
	mm.instance_count = posts.size()
	for i in range(posts.size()):
		mm.set_instance_transform(i, posts[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = PartsA.mat(0x3e5a44)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

# ---------------- its traffic ----------------
func _traffic() -> void:
	if not (ResourceLoader.exists(BODY) and ResourceLoader.exists(GLOW)):
		return
	_rng.seed = 2511
	for key in ["sb", "nb"]:
		for e in [LANE / 2.0, -LANE / 2.0]:                        # the slow lane, then the fast one
			var fine := _fine(lines[key])
			var pts := PackedVector2Array()
			var lens := PackedFloat32Array()
			var run := 0.0
			for i in range((fine[0] as PackedVector2Array).size()):
				var p: Vector2 = (fine[0] as PackedVector2Array)[i] + (fine[1] as PackedVector2Array)[i] * e
				if i > 0:
					run += p.distance_to(pts[i - 1])
				pts.append(p)
				lens.append(run)
			_lanes.append({"pts": pts, "len": lens, "cars": [], "lorries": e > 0.0, "gap": 0.0})
	_veh_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = VEH_SHADER
	_veh_mat.shader = sh
	_veh_mat.set_shader_parameter("body", load(BODY))
	_veh_mat.set_shader_parameter("glow", load(GLOW))
	_veh_mat.set_shader_parameter("rows", float(KINDS.size()))
	_veh_mat.set_shader_parameter("frames", float(FRAMES))
	var quad := ArrayMesh.new()
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(-6, BOTTOM, 0), Vector3(6, BOTTOM, 0), Vector3(6, BOTTOM + 6, 0), Vector3(-6, BOTTOM + 6, 0)])
	arr[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	arr[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	quad.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_custom_data = true
	_mm.mesh = quad
	_mm.instance_count = 96
	_mm.visible_instance_count = 0
	var mi := MultiMeshInstance3D.new()
	mi.name = "autovia_trafico"
	mi.multimesh = _mm
	mi.material_override = _veh_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.custom_aabb = AABB(Vector3(-10000, -1000, -10000), Vector3(20000, 2000, 20000))     # (the shader places them)
	add_child(mi)
	for ln in _lanes:                                              # the lanes as they would be after a while
		var total: float = (ln["len"] as PackedFloat32Array)[(ln["len"] as PackedFloat32Array).size() - 1]
		var s := _rng.randf_range(0.0, 120.0)
		while s < total:
			(ln["cars"] as Array).append(_new_car(ln, s))         # (the hindmost first)
			s += _rng.randf_range(90.0, 320.0)
	traffic_on = true

func _new_car(ln: Dictionary, s: float) -> Dictionary:
	var lorries: bool = ln["lorries"]
	var lorry: bool = lorries and _rng.randf() < 0.45          # (lorries in the slow lane only)
	var w := 0.0
	for k in KINDS:
		if bool(k[2]) == lorry:
			w += float(k[3])
	var roll := _rng.randf() * w
	var row := 0
	for i in range(KINDS.size()):
		if bool(KINDS[i][2]) != lorry:
			continue
		row = i
		roll -= float(KINDS[i][3])
		if roll <= 0.0:
			break
	var want: float = _rng.randf_range(23.0, 25.5) if lorry else (_rng.randf_range(30.0, 34.0) if lorries else _rng.randf_range(33.5, 37.5))
	var dims: Array = LORRIES.get(KINDS[row][0], [4.5, 1.9, 1.0])
	return {"s": s, "v": want, "want": want, "row": row, "len": float(dims[0]), "frame": float(dims[2])}

## where on its lane a car is, and the way it goes
static func _at(ln: Dictionary, s: float) -> Array:
	var pts: PackedVector2Array = ln["pts"]
	var lens: PackedFloat32Array = ln["len"]
	var i := clampi(lens.bsearch(s) - 1, 0, pts.size() - 2)
	var t := clampf((s - lens[i]) / maxf(0.001, lens[i + 1] - lens[i]), 0.0, 1.0)
	return [pts[i].lerp(pts[i + 1], t), (pts[i + 1] - pts[i]).normalized()]

# ---------------- every frame ----------------
func tick(dt: float) -> void:
	var cam: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
	var here := false
	if cam != null and G != null and G.zonas != null:
		var cp := Vector2(cam.global_position.x, cam.global_position.z)
		var zz = G.zonas.zone_at(cp)
		here = zz != null and String((zz as Dictionary)["id"]) == String(zone["id"])
	if here != shown:
		shown = here
		visible = here
	_tick_hum(dt, here)
	if not here or not traffic_on:
		return
	var held: bool = G.paused if G.get("paused") != null else false
	var n := 0
	for ln in _lanes:
		var cars: Array = ln["cars"]
		var total: float = (ln["len"] as PackedFloat32Array)[(ln["len"] as PackedFloat32Array).size() - 1]
		for i in range(cars.size() - 1, -1, -1):                   # (the one in front last in the list)
			var c: Dictionary = cars[i]
			if not held:
				var v: float = c["want"]
				if i < cars.size() - 1:                            # keeping its distance behind the one in front
					var ahead: Dictionary = cars[i + 1]
					var room: float = float(ahead["s"]) - float(c["s"]) - (float(ahead["len"]) + float(c["len"])) / 2.0 - 2.0
					if room < 30.0 + v * 1.6:
						v = minf(v, float(ahead["v"]) * clampf(room / (30.0 + v * 1.6), 0.6, 1.0))
				c["v"] = v
				c["s"] = float(c["s"]) + v * dt
		while not cars.is_empty() and float((cars[cars.size() - 1] as Dictionary)["s"]) > total:
			cars.pop_back()
		if not held and (cars.is_empty() or float((cars[0] as Dictionary)["s"]) > float(ln["gap"])):
			cars.push_front(_new_car(ln, 0.0))                    # (one more coming on at its start, after a while)
			ln["gap"] = _rng.randf_range(90.0, 450.0) if ln["lorries"] else _rng.randf_range(250.0, 1200.0)
		for c in cars:
			if n >= _mm.instance_count:
				break
			var at := _at(ln, float(c["s"]))
			var p: Vector2 = at[0]
			var d: Vector2 = at[1]
			_mm.set_instance_transform(n, Transform3D(Basis.IDENTITY, Vector3(p.x, MapData.height(p) + 0.03, p.y)))
			_mm.set_instance_custom_data(n, Color(d.x, d.y, float(c["row"]), float(c["frame"])))
			n += 1
	_mm.visible_instance_count = n
	var night: float = G.sky_fx.night if G.get("sky_fx") != null else 0.0
	var amb: Color = G.env.ambient_light_color * G.env.ambient_light_energy
	var sun: Color = G.sun.light_color * G.sun.light_energy
	var lit := Color(minf(1.0, amb.r * 0.55 + sun.r * 0.5), minf(1.0, amb.g * 0.55 + sun.g * 0.5), minf(1.0, amb.b * 0.55 + sun.b * 0.5))
	_veh_mat.set_shader_parameter("lit", Vector3(lit.r, lit.g, lit.b))
	_veh_mat.set_shader_parameter("night", night)

# ---------------- its hum ----------------
## The A-4's hum (the user, 25 Nov 2026, of the things proposed after the review: «Haz las 8»): in its zone, by day,
## the steady roar of its traffic, louder the nearer its carriageways (they run some 30 m behind the cemetery's east
## wall). At night it goes on, much lower (HUM_NIGHT: the user, the same day, «Dejar el rumor de la autovía por la
## noche, pero mucho más bajo»; it had been none at all, for the night there to be the wind's alone, zonas.gd hush):
## under the gusts of wind. The loop is made by tools/cementerio/rumor.py (no recording of anyone's).
const HUM := "res://assets/autovia/rumor.wav"
const HUM_NEAR := 14.0                  # this near its carriageways (at its fence) it is loudest...
const HUM_FAR := 340.0                  # ...and from here on, at its lowest
const HUM_DB := [-13.0, -30.0]
const HUM_NIGHT := -16.0                # at night, this much lower (the user, 25 Nov 2026: «Dejar el rumor de la autovía por la noche, pero mucho más bajo»): under the gusts of wind
var _hum: AudioStreamPlayer
var _hum_wait := 0.0
var _hum_want := -60.0

## how loud it is heard at a spot (dB; -60: not at all), by how dark the night is (0 to 1)
func hum_level(p: Vector2, night: float) -> float:
	var best := 1e9
	for key in ["sb", "nb"]:
		var pl: PackedVector2Array = lines.get(key, PackedVector2Array())
		for i in range(pl.size() - 1):
			best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, pl[i], pl[i + 1])))
	if best > 1e8:
		return -60.0
	var k: float = clampf(log(maxf(best, HUM_NEAR) / HUM_NEAR) / log(HUM_FAR / HUM_NEAR), 0.0, 1.0)
	return lerpf(float(HUM_DB[0]), float(HUM_DB[1]), k) + HUM_NIGHT * clampf(night * 1.25, 0.0, 1.0)

func _tick_hum(dt: float, here: bool) -> void:
	if G == null:
		return
	if _hum == null:
		var s = load(HUM) if ResourceLoader.exists(HUM) else null
		if not (s is AudioStreamWAV):
			return
		var loop: AudioStreamWAV = s
		loop.loop_mode = AudioStreamWAV.LOOP_FORWARD                  # (round and round: its end runs into its beginning)
		loop.loop_begin = 0
		loop.loop_end = int(loop.get_length() * loop.mix_rate)
		_hum = AudioStreamPlayer.new()
		_hum.bus = "SFX"
		_hum.stream = loop
		_hum.volume_db = -60.0
		add_child(_hum)
	var held: bool = bool(G.get("paused")) or bool(G.get("map_open"))
	if _hum.playing:
		_hum.stream_paused = held
	if held:
		return
	_hum_wait -= dt
	if _hum_wait <= 0.0:
		_hum_wait = 0.25
		_hum_want = -60.0
		if here and G.player != null:
			var dark: float = G.sky_fx.night if G.get("sky_fx") != null else 0.0
			_hum_want = hum_level(G.player.p, dark)
	if _hum_want > -59.0 and not _hum.playing:
		_hum.volume_db = -60.0
		_hum.play(randf() * 15.0)
	if _hum.playing:
		_hum.volume_db = move_toward(_hum.volume_db, _hum_want, 22.0 * dt)
		if _hum_want <= -59.0 and _hum.volume_db <= -59.0:
			_hum.stop()

## how many cars and lorries are on it now (the self-test)
func cars_on() -> int:
	var n := 0
	for ln in _lanes:
		n += (ln["cars"] as Array).size()
	return n
