extends "res://scripts/obra.gd"
## The solar plant across the old road from the cemetery (the user, 25 Nov 2026: «En frente del cementerio hay una
## planta solar. Estaría bien añadirla también», with a Street View of its gate, Nov 2024). In the cemetery's zone
## (zonas.gd makes it: "solar"), west of the road. Built from the PNOA orthophoto (tools/ign/cementerio_solar.jpg, 0.25 m
## a pixel; cementerio_solar_oeste.jpg, all of it) and from Street View of its gate.
##
## A yard of bare earth 330 m long, a wedge between fields, coming to the road in a neck with the gate at its south end:
## a wide low gate of tube and wire between two posts, a white board on it (its two lines as the real one's, blue over
## red; none of its small print). A wire fence all round it. Behind the gate a small white hut; scrap along its north
## and east sides -- stacks of pallets, drums, big bags, an old white car (dirty stays dirty). And its 28 trackers, in
## seven rows of four: each a table of panels 16 m by 13 (six rows of modules, a gap between each two: PNOA) on a steel
## mast on a round foot of concrete. They follow the sun, all as one, as the real ones do (on the orthophoto all face
## south-west, the afternoon's sun): turned to it and tilted square to it, no steeper than 55 degrees; at night laid
## nearly flat, facing where it will rise. They turn slowly: at dusk all of them swing back east together.
##
## All of it in the map's own measures (the frame is the map, y from the ground at its gate). Nobody gets in: the
## fence is solid wherever the zone's circle lets you reach it. Its land keeps the zone's dry plants (zonas.gd _scrub)
## but for its drive, its hut and the trackers' feet; no loose tree in it (keep_off).

const AutoviaS = preload("res://scripts/autovia.gd")       # (its fence's wire: the motorway's)
const Matojos = preload("res://scripts/matojos.gd")        # (the fields' tufts of dry grass, round its hidden saffron)
const Modelos = preload("res://scripts/modelos.gd")

const GATE_S := Vector2(372.6, -2461.3)    # the gate's posts (PNOA: where its drive meets the fence)
const GATE_N := Vector2(373.4, -2466.4)
## the fence, from the gate's north post round to its south one: along the road to the neck's corner, west along the
## neck, north up its east side, the long north side to the farm track, down the track, and back along its south side
const FENCE := [Vector2(373.4, -2466.4), Vector2(378.5, -2499.5), Vector2(370.0, -2497.0), Vector2(360.0, -2493.5), Vector2(348.0, -2490.5),
	Vector2(343.5, -2503.0), Vector2(340.0, -2518.0), Vector2(335.0, -2535.0), Vector2(329.5, -2554.0), Vector2(54.0, -2467.5), Vector2(42.0, -2330.0),
	Vector2(100.0, -2337.0), Vector2(130.0, -2357.0), Vector2(167.5, -2369.0), Vector2(205.0, -2392.0), Vector2(237.5, -2414.0), Vector2(280.0, -2428.0),
	Vector2(310.0, -2441.5), Vector2(345.0, -2454.0), Vector2(372.6, -2461.3)]
## the trackers' masts (PNOA), from the row nearest the road west
const TRACKERS := [Vector2(305.0, -2534.0), Vector2(301.75, -2506.0), Vector2(299.0, -2478.5), Vector2(295.5, -2451.0),
	Vector2(266.0, -2521.5), Vector2(262.75, -2492.0), Vector2(259.0, -2462.0), Vector2(256.0, -2438.5),
	Vector2(227.0, -2509.0), Vector2(223.5, -2477.5), Vector2(219.75, -2446.5), Vector2(216.75, -2420.0),
	Vector2(187.5, -2496.0), Vector2(184.0, -2463.0), Vector2(180.0, -2430.0), Vector2(176.5, -2397.0),
	Vector2(148.0, -2483.0), Vector2(144.0, -2449.0), Vector2(140.5, -2413.5), Vector2(136.0, -2378.5),
	Vector2(109.5, -2470.5), Vector2(105.0, -2434.5), Vector2(101.0, -2397.0), Vector2(96.5, -2360.0),
	Vector2(69.0, -2458.5), Vector2(65.0, -2420.5), Vector2(61.0, -2381.0), Vector2(57.5, -2342.0)]
const DRIVE := Vector2(377.6, -2463.2)     # where its drive crosses the row of trees along the road (cementerio.gd plants none there)
const SIGN := ["PLANTA INDUSTRIAL", "AGROSOLAR"]      # its board's two lines: the user's name for it
const SAFFRON_ID := "planta_solar_puerta"  # its hidden saffron (Sistemas keeps the count of them)
const FENCE_H := 1.8
const TABLE_W := 16.0                      # a tracker's table, across...
const ROWS := 6                            # ...and its rows of modules up it, each this high, this far apart
const ROW_H := 2.0
const ROW_GAP := 0.2
const TABLE_Z := 0.95                      # the table this far before the mast's head
const MAST := 6.5                          # the mast's head, over the ground
const TILT := [8.0, 55.0]                  # the table's tilt from flat: the least and the most (degrees)
const STOW := 12.0                         # ...and at night
const SLEW := 5.0                          # degrees a second, at the most
## the two big fields of fixed panels past the farm track, west and north-west of it (PNOA: tools/ign/
## cementerio_fijas.jpg, 1 m a pixel): their outlines on the map
const FARMS := [
	[Vector2(-335.0, -2568.0), Vector2(-283.0, -2598.0), Vector2(-283.0, -2500.0), Vector2(-160.0, -2508.0), Vector2(40.0, -2545.0),
		Vector2(32.0, -2360.0), Vector2(-220.0, -2368.0), Vector2(-335.0, -2428.0), Vector2(-348.0, -2550.0)],
	[Vector2(-223.0, -2840.0), Vector2(-160.0, -2857.0), Vector2(-80.0, -2805.0), Vector2(-48.0, -2785.0), Vector2(-52.0, -2655.0),
		Vector2(55.0, -2620.0), Vector2(50.0, -2580.0), Vector2(-280.0, -2598.0), Vector2(-230.0, -2655.0)]]
const FARM_PITCH := 6.5                    # a row of their tables every so far, north to south
const FARM_SLOPE := 3.9                    # a table up its slope...
const FARM_TILT := 28.0                    # ...tilted so to the south
const FARM_FOOT := 0.75                    # its low edge over the ground
const STEEL := 0x8d9296
const CONCRETE := 0xb9b4aa

const PANEL_SHADER := """
shader_type spatial;
void fragment() {
	vec2 m = UV / vec2(1.0, 2.0);                 // modules 1 m across, a row high (UV in metres)
	vec2 f = fract(m);
	vec2 fw = fwidth(m);
	float fx = min(f.x, 1.0 - f.x);
	float fy = min(f.y, 1.0 - f.y);
	float frame = max(1.0 - smoothstep(0.022, 0.022 + fw.x, fx), 1.0 - smoothstep(0.011, 0.011 + fw.y, fy));
	vec2 c = fract(m * vec2(6.0, 12.0));           // its cells
	vec2 cw = fwidth(m * vec2(6.0, 12.0));
	float cell = max(1.0 - smoothstep(0.03, 0.03 + cw.x, min(c.x, 1.0 - c.x)), 1.0 - smoothstep(0.03, 0.03 + cw.y, min(c.y, 1.0 - c.y)));
	float far = clamp(max(fw.x, fw.y) * 5.0 - 0.25, 0.0, 1.0);        // (far off, its lines' share of it: no shimmer)
	frame = mix(frame, 0.08, far);
	cell = mix(cell, 0.1, clamp(max(cw.x, cw.y) * 2.0 - 0.3, 0.0, 1.0));
	vec3 glass = mix(vec3(0.035, 0.06, 0.13), vec3(0.1, 0.14, 0.22), cell * 0.5);
	ALBEDO = mix(glass, vec3(0.62, 0.65, 0.68), frame);
	METALLIC = 0.12;                              // (dark glass: a little of the sky in it, no mirror)
	SPECULAR = 0.6;
	ROUGHNESS = mix(0.22, 0.5, frame);
}
"""

var G
var zone: Dictionary
var trackers := 0                          # how many tables (the self-test)
var fence_solids := 0                      # the pieces of its fence that are solid (the self-test)
var normal := Vector3.UP                   # where its tables face now
var _mm: MultiMesh
var _heads: Array = []                     # each table's pivot, in the frame
var _wait := 0.0
var _pads: Array = []                      # what the dry plants keep off, on the map
var saffron: Array = []                    # its hidden saffron: [id, spot on the map] (the self-test)
var farm_rows := 0                         # the rows of fixed panels in the far fields (the self-test)
var _panel_mat: ShaderMaterial

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"hormigon":           # its drive: trodden earth and gravel, paler than the land (Street View 2024)
			m = Tex.mat("granular_concrete", Color(0.8, 0.72, 0.6), false)
		"cal":
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.99, 0.96)), 0.18)
		_:
			return super(key)
	_mats[key] = m
	return m

func build(game, z: Dictionary) -> bool:
	G = game
	zone = z
	W = game.world
	if W == null:
		return false
	name = "planta_solar"
	level = MapData.height((GATE_S + GATE_N) / 2.0)
	transform = Transform3D(Basis.IDENTITY, Vector3(0.0, level, 0.0))
	_fence()
	_gate()
	_drive()
	_hut()
	_junk()
	_masts()
	home()
	_commit()
	_tables()
	_farms()
	_saffron()
	track(true)
	return true

## a spot on the map as a point of the frame, `lift` over the ground there
func _at(p: Vector2, lift := 0.0) -> Vector3:
	return Vector3(p.x, MapData.height(p) - level + lift, p.y)

## What of it the zone's dry plants (trees false) and loose trees keep off, as outlines on the map: the plants its
## drive, its hut and the trackers' feet; the trees all of it, `grow` metres out
func keep_off(trees: bool, grow: float) -> Array:
	if trees:
		var out: Array = _grow(PackedVector2Array(FENCE), grow)
		for farm in FARMS:                                         # (nor in the far fields of fixed panels)
			out.append_array(_grow(PackedVector2Array(farm), grow))
		return out
	return _pads

## an outline `by` metres bigger all round (whichever way round it goes)
static func _grow(poly: PackedVector2Array, by: float) -> Array:
	var size0 := _span(poly)
	var rev := poly.duplicate()
	rev.reverse()
	for way in [poly, rev]:
		var out: Array = Geometry2D.offset_polygon(way, by)
		if not out.is_empty() and _span(out[0]) > size0:
			return out
	return [poly]

static func _span(poly: PackedVector2Array) -> float:
	var r := Rect2(poly[0], Vector2.ZERO)
	for q in poly:
		r = r.expand(q)
	return r.size.x + r.size.y

func _round(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(8):
		pts.append(c + Vector2.from_angle(TAU * i / 8.0) * r)
	return pts

# ---------------- the fence and the gate ----------------
## wire on thin posts all round, one every 3 m; solid where the zone's circle lets you come to it
func _fence() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var posts: Array = []
	var c: Vector2 = zone["centre"]
	var rad: float = zone["radius"]
	var run := 0.0
	var s := 0.0
	for i in range(FENCE.size() - 1):
		var a: Vector2 = FENCE[i]
		var b: Vector2 = FENCE[i + 1]
		var ln := a.distance_to(b)
		var d := (b - a) / ln
		var k := int(ceil(ln / 6.0))
		for j in range(k):
			var p0 := a.lerp(b, float(j) / k)
			var p1 := a.lerp(b, float(j + 1) / k)
			_wire(st, _at(p0, -0.2), _at(p1, -0.2), FENCE_H + 0.2, run + ln * j / k, ln / k)
			var mid := (p0 + p1) / 2.0
			if mid.distance_to(c) < rad + 15.0:
				solid(_at(mid, 1.5), Vector3(ln / k + 0.3, 4.0, 0.3), atan2(-d.y, d.x))
				fence_solids += 1
		while s < ln:
			var p := a + d * s
			posts.append(Transform3D(Basis.from_scale(Vector3(0.05, FENCE_H + 0.3, 0.05)), _at(p, (FENCE_H + 0.3) / 2.0 - 0.2)))
			s += 3.0
		s -= ln
		run += ln
	# the gate's leaf: wire in its frame of tube
	var L := face(GATE_S, GATE_N, MapData.height((GATE_S + GATE_N) / 2.0) - level)
	_wire(st, _xf * Vector3(0.14, 0.14, 0.0), _xf * Vector3(L - 0.14, 0.14, 0.0), 1.56, 0.0, L - 0.28)
	home()
	st.generate_normals()
	var wm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = AutoviaS.WIRE_SHADER
	wm.shader = sh
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = wm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var post := BoxMesh.new()
	post.size = Vector3.ONE
	mm.mesh = post
	mm.instance_count = posts.size()
	for i in range(posts.size()):
		mm.set_instance_transform(i, posts[i])
	var pm := MultiMeshInstance3D.new()
	pm.multimesh = mm
	pm.material_override = Parts.mat(STEEL)
	pm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pm)

## a piece of wire from a to b (its foot), `tall` high; its UV in metres
func _wire(st: SurfaceTool, a: Vector3, b: Vector3, tall: float, u0: float, ln: float) -> void:
	var q := [a, b, b + Vector3(0, tall, 0), a + Vector3(0, tall, 0)]
	var uv := [Vector2(u0, 0.0), Vector2(u0 + ln, 0.0), Vector2(u0 + ln, tall), Vector2(u0, tall)]
	for t in [0, 2, 1, 0, 3, 2]:
		st.set_uv(uv[t])
		st.add_vertex(q[t])

## The gate (Street View 2024): two posts, a leaf of tube right across, and on its south half the white board with
## its two lines. Shut: its solid is the fence's own line on across it.
func _gate() -> void:
	var L := face(GATE_S, GATE_N, MapData.height((GATE_S + GATE_N) / 2.0) - level)
	for x in [0.0, L]:
		box(x - 0.08, -0.25, -0.08, 0.16, 2.35, 0.16, STEEL)
		box(x - 0.1, 2.1, -0.1, 0.2, 0.03, 0.2, 0x70757a)
	var tube := 0x7b8187
	for y in [0.1, 1.7]:
		box(0.1, y, -0.025, L - 0.2, 0.05, 0.05, tube)
	for x in [0.1, L / 3.0, L * 2.0 / 3.0, L - 0.15]:
		box(x, 0.1, -0.025, 0.05, 1.65, 0.05, tube)
	bar(Vector3(L / 3.0, 0.15, 0.0), Vector3(L * 2.0 / 3.0, 1.7, 0.0), 0.04, 0.04, tube)
	# the board: white, a thin dark edge; its name in the game, the user's (25 Nov 2026: «Y el cartel "Planta Industrial
	# Agrosolar"»), in the real one's two lines and colours: blue over red
	var bx := 0.35
	var bw := 2.1
	box(bx, 0.72, 0.03, bw, 0.82, 0.02, 0xf1f0ea)
	for q in [[bx, 0.72, bw, 0.02], [bx, 1.52, bw, 0.02], [bx, 0.72, 0.02, 0.82], [bx + bw - 0.02, 0.72, 0.02, 0.82]]:
		box(q[0], q[1], 0.05, q[2], q[3], 0.004, 0x3a3f46)
	_text(SIGN[0], Vector3(bx + bw / 2.0, 1.33, 0.056), 42, 0x1f4fa0).shaded = true      # (painted: dark at night, as its board)
	_text(SIGN[1], Vector3(bx + bw / 2.0, 0.99, 0.056), 72, 0xb3261e).shaded = true
	_solid_xf(Vector3(L / 2.0, 1.5, 0.0), Vector3(L + 0.3, 4.0, 0.3))
	fence_solids += 1
	home()

## a solid given in the frame being built
func _solid_xf(mid: Vector3, size: Vector3) -> void:
	var m := _xf * mid
	var xd := _xf.basis.x
	solid(m, size, atan2(-xd.z, xd.x))

## its drive: trodden earth from the road's edge in through the gate, splayed where it meets the road
func _drive() -> void:
	var a: Vector2 = zone["road_from"]
	var b: Vector2 = zone["road_to"]
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x)                                    # (east: to the road)
	var f := (GATE_N - GATE_S).normalized()
	var reach: float = -(((GATE_S + GATE_N) / 2.0) - a).dot(n) - float(zone["road_hw"])
	var poly := PackedVector2Array([GATE_S + n * reach - f * 1.6, GATE_N + n * reach + f * 1.6, GATE_N + n * (reach - 3.0),
		GATE_N - n * 15.0, GATE_S - n * 15.0, GATE_S + n * (reach - 3.0)])
	_lay_map(poly, 0.03, "hormigon")
	_pads.append_array(_grow(poly, 0.6))

## a flat thing lying on the ground with this outline on the map, `lift` over it: cut along the columns of the plain's
## heights (past the map's edge the land is straight between them), so it lies on it everywhere (as cementerio.gd's)
func _lay_map(wpoly: PackedVector2Array, lift: float, key) -> void:
	if Geometry2D.is_polygon_clockwise(wpoly):
		wpoly.reverse()
	var rect := Rect2(wpoly[0], Vector2.ZERO)
	for q in wpoly:
		rect = rect.expand(q)
	var g: float = MapData.rg
	for i in range(int(floor((rect.position.x - MapData.rx0) / g)), int(floor((rect.end.x - MapData.rx0) / g)) + 1):
		var xa: float = MapData.rx0 + i * g
		var strip := PackedVector2Array([Vector2(xa, rect.position.y - 1.0), Vector2(xa + g, rect.position.y - 1.0), Vector2(xa + g, rect.end.y + 1.0), Vector2(xa, rect.end.y + 1.0)])
		for piece in Geometry2D.intersect_polygons(wpoly, strip):
			var idx := Geometry2D.triangulate_polygon(piece)
			for t in range(0, idx.size(), 3):
				var pa: Vector2 = piece[idx[t]]
				var pb: Vector2 = piece[idx[t + 1]]
				var pc: Vector2 = piece[idx[t + 2]]
				tri(_at(pa, lift), _at(pb, lift), _at(pc, lift), key, Vector3.UP)

# ---------------- the hut and the scrap ----------------
## the small white hut behind the fence, north of the gate (PNOA: 4 m by 2.5): flat-roofed, a grey steel door in its
## south end, a louvre on the side to the road
func _hut() -> void:
	var f: Vector2 = ((FENCE[1] as Vector2) - (FENCE[0] as Vector2)).normalized()
	var w := Vector2(f.y, -f.x)                                    # (in from the fence: west)
	var pf: Vector2 = FENCE[0] + f * 21.9 + w * 1.1
	var a := pf - f * 2.0
	var b := pf + f * 2.0
	face(a, b, MapData.height(pf) - level)
	box(0.0, -0.3, -2.5, 4.0, 2.9, 2.5, "cal")
	box(-0.15, 2.6, -2.65, 4.3, 0.12, 2.8, 0xa9a59c)
	box(-0.03, 0.0, -1.75, 0.03, 2.0, 0.9, 0x6f757a)
	box(-0.035, 1.0, -1.05, 0.01, 0.06, 0.12, 0x2c2f33)
	box(2.7, 1.75, 0.0, 0.8, 0.45, 0.02, 0x8d9296)
	for k in range(5):
		box(2.72, 1.78 + k * 0.085, 0.02, 0.76, 0.02, 0.012, 0x5d6267)
	home()
	_pads.append(PackedVector2Array([a + f * -0.6 - w * 0.6, b + f * 0.6 - w * 0.6, b + f * 0.6 + w * 3.1, a - f * 0.6 + w * 3.1]))

## the scrap along the neck's north side and up its east side, inside the fence (PNOA and Street View 2024: pallets,
## drums, sacks, sheets, old machines): the same every time
func _junk() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2511
	var runs := [[FENCE[1], FENCE[4]], [FENCE[4], FENCE[7]]]
	var piles: Array = []
	for r in runs:
		var a: Vector2 = r[0]
		var b: Vector2 = r[1]
		var d := (b - a).normalized()
		var inw := Vector2(d.y, -d.x)                              # (the fence goes round with the yard on this side)
		var t := 3.0 + rng.randf() * 2.0
		while t < a.distance_to(b) - 2.0:
			piles.append(a + d * t + inw * rng.randf_range(1.6, 4.2))
			t += rng.randf_range(3.2, 7.0)
	for i in range(piles.size()):
		var p: Vector2 = piles[i]
		var o := _at(p, -0.2)
		var turn := rng.randf() * TAU
		var kind := rng.randi() % 5
		match kind:
			0, 1:               # a stack of pallets, each a little askew
				var n := rng.randi_range(3, 9)
				for k in range(n):
					var t := Transform3D(Basis(Vector3.UP, turn + rng.randf_range(-0.12, 0.12)).scaled_local(Vector3(1.2, 0.13, 0.8)), o + Vector3(0, 0.2 + 0.07 + k * 0.145, 0))
					tbox(t, 0xa58b63 if rng.randf() < 0.6 else 0x8f8068)
			2:                  # drums, one or two fallen
				for k in range(rng.randi_range(2, 5)):
					var at := o + Vector3(rng.randf_range(-0.9, 0.9), 0.2, rng.randf_range(-0.9, 0.9))
					var hex: int = [0x3b5e8c, 0x8a4a2a, 0x2f6b4a, 0x7c7f83][rng.randi() % 4]
					drum(at, 0.29, 0.29, 0.88, hex, 10)
			3:                  # big bags and a sheet leaning on them
				for k in range(rng.randi_range(1, 3)):
					cbox(o + Vector3(k * 0.98 * cos(turn), 0.2 + 0.45, -k * 0.98 * sin(turn)), Vector3(0.92, 0.9, 0.92), 0xdedbd2 if k % 2 == 0 else 0xcfcbc0)
				tbox(Transform3D(Basis(Vector3.UP, turn).rotated(Vector3(cos(turn), 0, -sin(turn)), 0.35).scaled_local(Vector3(2.0, 1.1, 0.03)), o + Vector3(-sin(turn) * 0.75, 0.2 + 0.52, -cos(turn) * 0.75)), 0x8b6a4c)
			_:                  # a heap of scrap: beams and sheets
				for k in range(rng.randi_range(3, 6)):
					var tb := Transform3D(Basis(Vector3.UP, turn + rng.randf_range(-0.5, 0.5)).scaled_local(Vector3(rng.randf_range(1.6, 3.4), rng.randf_range(0.05, 0.14), rng.randf_range(0.1, 0.9))), o + Vector3(rng.randf_range(-0.5, 0.5), 0.2 + 0.06 + k * 0.11, rng.randf_range(-0.5, 0.5)))
					tbox(tb, [0x8a4a2a, 0x7c7f83, 0x6a5a4a, 0x9a9da2][rng.randi() % 4])
	# an old white car among it, by the neck's corner (Street View 2024)
	var cp: Vector2 = FENCE[4] + Vector2(7.5, 9.0)
	var car: Node3D = Modelos.make_from(Modelos.SK, "cuatrolatas", {"wid": 1.65, "len": 3.65}, 0xdcd6c4)      # (car.gd SPECS: its size)
	if car != null:
		car.transform = Transform3D(Basis(Vector3.UP, 2.3), _at(cp, 0.0))
		add_child(car)
		_pads.append(_round(cp, 3.0))

## The hidden saffron (the user, 25 Nov 2026, of the eight things proposed after the review: «Haz las 8»): at the foot
## of the gate's south post, on the outside, among tufts of dry grass (the fields' own: matojos.gd's), where the fence
## comes to the gate. Reached from the road's verge; it counts once a game, as the other hidden ones (game.flowers).
func _saffron() -> void:
	var a: Vector2 = zone["road_from"]
	var b: Vector2 = zone["road_to"]
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x)                                    # (east: to the road)
	var f := (GATE_N - GATE_S).normalized()
	var spot := GATE_S + n * 0.2 - f * 0.8
	var back: Vector2 = ((FENCE[FENCE.size() - 2] as Vector2) - GATE_S).normalized()      # (back along the fence from the post)
	var out := Vector2(back.y, -back.x)                            # (out of the yard: south)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2512
	var tufts: Array = []
	for k in range(8):                                             # (round the flower; none on the drive)
		var ang := TAU * k / 8.0 + rng.randf_range(-0.3, 0.3)
		var q := spot + Vector2.from_angle(ang) * rng.randf_range(0.3, 0.7)
		if (q - GATE_S).dot(f) < -0.4:
			tufts.append(q)
	for k in range(5):                                             # (and on along the fence's foot)
		tufts.append(GATE_S + back * (0.5 + k * 0.75 + rng.randf_range(-0.2, 0.2)) + out * rng.randf_range(0.25, 0.6))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = Matojos._tuft_mesh()
	mm.instance_count = tufts.size()
	var straw := [Color(1.0, 0.97, 0.9), Color(0.9, 0.84, 0.72), Color(0.82, 0.77, 0.7), Color(1.0, 0.9, 0.74)]
	for k in range(tufts.size()):
		var t: Vector2 = tufts[k]
		var sc := rng.randf_range(0.4, 0.62)
		var tb := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(sc * rng.randf_range(0.85, 1.2), sc, sc * rng.randf_range(0.85, 1.2)))
		mm.set_instance_transform(k, Transform3D(tb, _at(t, -0.04)))
		mm.set_instance_color(k, (straw[rng.randi() % straw.size()] as Color) * rng.randf_range(0.88, 1.05))
	var grass := MultiMeshInstance3D.new()
	grass.name = "matas_azafran"
	grass.multimesh = mm
	var gm := StandardMaterial3D.new()
	gm.vertex_color_use_as_albedo = true
	gm.cull_mode = BaseMaterial3D.CULL_DISABLED
	gm.roughness = 1.0
	grass.material_override = gm
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(grass)
	var flower := Node3D.new()
	flower.add_child(Parts.part("cyl", 0x5f9c4a, Vector3(0, 0.3, 0), Vector3(0.03, 0.6, 0.03)))
	for i in range(5):
		flower.add_child(Parts.part("ball", 0x9b5de5, Vector3(cos(i * 1.257) * 0.12, 0.66, sin(i * 1.257) * 0.12), Vector3(0.11, 0.2, 0.11)))
	flower.add_child(Parts.part("ball", 0xe63946, Vector3(0, 0.74, 0), Vector3(0.05, 0.13, 0.05)))
	flower.scale = Vector3.ONE * 0.7
	flower.position = _at(spot, -0.02)
	add_child(flower)
	saffron.append([SAFFRON_ID, spot])
	if G != null and G.get("flowers") != null:
		(G.flowers as Array).append({"node": flower, "p": spot, "id": SAFFRON_ID, "hidden": true})

# ---------------- the trackers ----------------
## each one's mast: a round foot of concrete, the steel column, its head; a grey box of switches on it
func _masts() -> void:
	for p in TRACKERS:
		var w: Vector2 = p
		var o := _at(w, -0.2)
		drum(o, 1.5, 1.4, 0.7, CONCRETE, 10)
		drum(o + Vector3(0, 0.7, 0), 0.42, 0.36, MAST - 0.5 - 0.3, STEEL, 10)
		cbox(o + Vector3(0, 0.2 + MAST - 0.15, 0), Vector3(0.95, 0.6, 0.95), 0x565b61)
		cbox(o + Vector3(0.5, 0.2 + 1.4, 0), Vector3(0.22, 0.55, 0.4), 0xb4b8bb)
		_heads.append(_at(w, MAST))
		_pads.append(_round(w, 2.3))
	trackers = TRACKERS.size()

## The tables, all one mesh drawn 28 times (a MultiMesh: they all turn as one). A table in its own frame: x across it,
## y up its slope, z out of its face; its pivot the mast's head. Its face the rows of modules (PANEL_SHADER), behind
## them their white backs, the rafters, two beams and the arm to the pivot, of steel.
func _tables() -> void:
	var face_st := SurfaceTool.new()
	face_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var back := SurfaceTool.new()
	back.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tall: float = ROWS * ROW_H + (ROWS - 1) * ROW_GAP
	var hw: float = TABLE_W / 2.0
	for r in range(ROWS):
		var y0: float = -tall / 2.0 + r * (ROW_H + ROW_GAP)
		_squad(face_st, [Vector3(-hw, y0, TABLE_Z), Vector3(hw, y0, TABLE_Z), Vector3(hw, y0 + ROW_H, TABLE_Z), Vector3(-hw, y0 + ROW_H, TABLE_Z)], Vector3(0, 0, 1),
			[Vector2(0, 0), Vector2(TABLE_W, 0), Vector2(TABLE_W, ROW_H), Vector2(0, ROW_H)])
		_sbox(back, Vector3(0.0, y0 + ROW_H / 2.0, TABLE_Z - 0.03), Vector3(TABLE_W, ROW_H, 0.05), true)
	for x in [-6.0, -2.0, 2.0, 6.0]:
		_sbox(back, Vector3(x, 0.0, TABLE_Z - 0.19), Vector3(0.14, tall, 0.28))
	for y in [-3.3, 3.3]:
		_sbox(back, Vector3(0.0, y, TABLE_Z - 0.48), Vector3(TABLE_W - 0.6, 0.3, 0.3))
	_sbox(back, Vector3(0.0, 0.0, TABLE_Z - 0.78), Vector3(0.5, 7.0, 0.34))
	_sbox(back, Vector3(0.0, 0.0, 0.0), Vector3(1.6, 0.5, 0.5))
	var mesh := ArrayMesh.new()
	face_st.commit(mesh)
	back.commit(mesh)
	var pm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = PANEL_SHADER
	pm.shader = sh
	_panel_mat = pm
	mesh.surface_set_material(0, pm)
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0.62, 0.64, 0.66)
	bm.roughness = 0.6
	bm.metallic = 0.2
	mesh.surface_set_material(1, bm)
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.mesh = mesh
	_mm.instance_count = _heads.size()
	var mi := MultiMeshInstance3D.new()
	mi.name = "mesas"
	mi.multimesh = _mm
	add_child(mi)

## a flat four-sided piece facing n, into a SurfaceTool (clockwise front faces, as obra.gd's _tri)
static func _squad(st: SurfaceTool, q: Array, n: Vector3, uv = null) -> void:
	for t in [[0, 1, 2], [0, 2, 3]]:
		var ia: int = t[0]
		var ib: int = t[1]
		var ic: int = t[2]
		if ((q[ib] as Vector3) - (q[ia] as Vector3)).cross((q[ic] as Vector3) - (q[ia] as Vector3)).dot(n) > 0.0:
			var sw := ib
			ib = ic
			ic = sw
		for i in [ia, ib, ic]:
			st.set_normal(n)
			if uv != null:
				st.set_uv(uv[i])
			st.add_vertex(q[i])

## a box, into a SurfaceTool (`no_front`: without its +z face, another's in its place)
static func _sbox(st: SurfaceTool, mid: Vector3, size: Vector3, no_front := false) -> void:
	var h := size / 2.0
	for f in [[Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)], [Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 1, 0)],
			[Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0)], [Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0)],
			[Vector3(0, 1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)], [Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)]]:
		var n: Vector3 = f[0]
		if no_front and n.z > 0.5:
			continue
		var c: Vector3 = mid + n * h
		var u: Vector3 = (f[1] as Vector3) * h
		var v: Vector3 = (f[2] as Vector3) * h
		_squad(st, [c - u - v, c + u - v, c + u + v, c - u + v], n)

## The two big fields of fixed panels past the farm track (the user, 25 Nov 2026, of the things proposed after the
## review: «Haz las 8»): rows of low tables running east to west, tilted to the south, one row every FARM_PITCH metres
## all over each field's outline. Seen far off behind the trackers, 250 m and more past where you can walk: one mesh,
## no legs, no shadows. They lie on the plain (its heights go by x alone out there).
func _farms() -> void:
	var face_st := SurfaceTool.new()
	face_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var back := SurfaceTool.new()
	back.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tilt := deg_to_rad(FARM_TILT)
	var half: float = FARM_SLOPE * cos(tilt) / 2.0                  # (a table on the ground, north to south)
	var rise: float = FARM_SLOPE * sin(tilt)
	var nrm := Vector3(0.0, cos(tilt), sin(tilt))                  # (it faces up and south)
	for farm in FARMS:
		var poly := PackedVector2Array(farm)
		var z0 := 1e9
		var z1 := -1e9
		for q in poly:
			z0 = minf(z0, q.y)
			z1 = maxf(z1, q.y)
		var zr: float = z0 + 4.0
		while zr < z1 - 3.0:
			var xs: Array = []
			for i in range(poly.size()):
				var a: Vector2 = poly[i]
				var b: Vector2 = poly[(i + 1) % poly.size()]
				if (a.y - zr) * (b.y - zr) < 0.0:
					xs.append(a.x + (b.x - a.x) * (zr - a.y) / (b.y - a.y))
			xs.sort()
			for j in range(0, xs.size() - 1, 2):
				var xa: float = float(xs[j]) + 4.0
				var xb: float = float(xs[j + 1]) - 4.0
				if xb - xa < 10.0:
					continue
				farm_rows += 1
				var k := int(ceil((xb - xa) / 30.0))
				for s in range(k):
					var u0: float = lerpf(xa, xb, float(s) / k)
					var u1: float = lerpf(xa, xb, float(s + 1) / k)
					var g0: float = MapData.height(Vector2(u0, zr)) - level + FARM_FOOT
					var g1: float = MapData.height(Vector2(u1, zr)) - level + FARM_FOOT
					var q4: Array = [Vector3(u0, g0, zr + half), Vector3(u1, g1, zr + half), Vector3(u1, g1 + rise, zr - half), Vector3(u0, g0 + rise, zr - half)]
					_squad(face_st, q4, nrm, [Vector2(u0 - xa, 0.0), Vector2(u1 - xa, 0.0), Vector2(u1 - xa, FARM_SLOPE), Vector2(u0 - xa, FARM_SLOPE)])
					var qb: Array = []
					for v in q4:
						qb.append((v as Vector3) - nrm * 0.04)
					_squad(back, qb, -nrm)
			zr += FARM_PITCH
	if farm_rows == 0:
		return
	var mesh := ArrayMesh.new()
	face_st.commit(mesh)
	back.commit(mesh)
	mesh.surface_set_material(0, _panel_mat)
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0.6, 0.62, 0.64)
	bm.roughness = 0.7
	mesh.surface_set_material(1, bm)
	var mi := MeshInstance3D.new()
	mi.name = "fijas"
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

# ---------------- following the sun ----------------
## where the tables should face: square to the sun by day (no flatter and no steeper than TILT), nearly flat at night,
## already turned to where it rises
func _aim() -> Vector3:
	var flat := Vector3(sin(deg_to_rad(100.0)), 0.0, cos(deg_to_rad(100.0)))      # (where the game's sun comes up: game.gd)
	var tilt := deg_to_rad(STOW)
	var sun = G.get("sun") if G != null else null
	if sun is DirectionalLight3D and float(G.clock) >= float(G.SUNRISE) and float(G.clock) <= float(G.SUNSET):
		var s: Vector3 = (sun as DirectionalLight3D).global_basis.z
		var h := Vector3(s.x, 0.0, s.z)
		if h.length() > 0.05:
			flat = h.normalized()
			tilt = clampf(PI / 2.0 - asin(clampf(s.y, -1.0, 1.0)), deg_to_rad(TILT[0]), deg_to_rad(TILT[1]))
	return (flat * sin(tilt) + Vector3.UP * cos(tilt)).normalized()

## turn the tables towards the sun: at once (snap), or as far as they go in dt
func track(snap: bool, dt := 0.0) -> void:
	if _mm == null:
		return
	var want := _aim()
	var ang := normal.angle_to(want)
	if not snap and ang < 0.0008:
		return
	var step := deg_to_rad(SLEW) * dt
	if snap or ang <= step:
		normal = want
	else:
		normal = normal.slerp(want, step / ang).normalized()
	var x := Vector3.UP.cross(normal)
	if x.length() < 0.01:
		x = Vector3.RIGHT
	x = x.normalized()
	var b := Basis(x, normal.cross(x).normalized(), normal)
	for i in range(_heads.size()):
		_mm.set_instance_transform(i, Transform3D(b, _heads[i]))

func tick(dt: float) -> void:
	_wait -= dt
	if _wait > 0.0:
		return
	track(false, 0.2 - _wait)
	_wait = 0.2
