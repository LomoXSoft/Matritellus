extends "res://scripts/obra.gd"
## The IES Valdeacero (the user's name for the IES Valdehierro, 17 November 2026: "Tu siguiente proyecto será el IES
## Valdehierro (que llamaremos IES Valdeacero). Mas o menos dentro del recinto rojo. En el C. Viejo de Tembleque"):
## the secondary school at the north end of the town, by the Camino Viejo de Tembleque. Built by hand from the
## orthophoto (PNOA, tools/ign/ies_valdeacero*.jpg: every footprint traced on its 5 m grid, tools/ies/recortes.py)
## and Street View along the avenue on its east side (November 2024) -- its other sides give on to fields, so what is
## not seen from there is made in keeping with what is.
##
## Inside its fence: the main building, a comb of two floors -- a spine on the west and five bars running east from it,
## narrow patios between them, a court of trees under a low blue roof, a covered walk along the sports courts; the
## sports courts; the great gym, its walls of sage-green panels under a band of glass; north of it the car park under
## its row of trees; the low hall under a red roof and the grey block of the vocational school beside its stepped
## garden; and north of those a field with a long greenhouse and a row of big trees. On the avenue, the fence: a low
## wall painted blue, a mesh over it and a hedge behind; the white porch of the way in with the school's name, three
## flags behind it; the gate of the car park.
##
## The map has nothing there (fields): no rebake. Frame: map metres from O, north up the map (-z), y = 0 the ground at
## O; each building stands on its own floor, the floors and courts lie on the ground as the relief has it.

const NAME := "I.E.S. VALDEACERO"
const O := Vector2(-130.0, -1220.0)
const DOWN := -4.0
const CREAM := 0xeadfc6
const BLUE := 0x2c4fc4
const WHITE := 0xf2f0ea
const SAGE := 0x86a094
const ROOF := 0xa8a6a0
const MESH := 0x8c9296
const GREEN := 0x3f6a34

# [x0, z0, x1, z1, height, look]: the blocks (look: "aula" windows on two floors, "bajo" one floor, "liso" none)
const COMB: Array = [
	[-172.0, -1218.0, -163.0, -1141.0, 7.6, "aula"],     # its spine
	[-163.0, -1211.0, -123.0, -1200.0, 7.6, "aula"],     # the five bars, north to south
	[-163.0, -1198.0, -150.0, -1190.0, 7.6, "aula"],
	[-163.0, -1182.0, -126.0, -1174.0, 7.6, "aula"],
	[-163.0, -1170.0, -127.0, -1163.0, 7.6, "aula"],
	[-163.0, -1159.0, -127.0, -1151.0, 7.6, "aula"],
	[-175.0, -1150.0, -128.0, -1141.0, 7.6, "aula"],
	[-182.0, -1190.0, -172.0, -1172.0, 4.0, "bajo"],      # lower pieces on its west
	[-178.0, -1170.0, -172.0, -1152.0, 4.0, "bajo"],
]
const NORTH: Array = [
	[-158.0, -1262.0, -137.0, -1250.0, 7.0, "aula"],     # the vocational school
	[-137.0, -1262.0, -120.0, -1252.0, 6.0, "aula"],
	[-146.0, -1252.0, -122.0, -1238.0, 4.2, "bajo"],
]
const HALL := [-163.0, -1254.0, -150.0, -1236.0]       # the hall under the red roof
const GYM := [-115.0, -1233.0, -67.0, -1204.0]
const COURTS := [-122.0, -1181.0, -82.0, -1137.0]
const PARK := [-120.0, -1262.0, -62.0, -1238.0]
const FRONT_S := Vector2(-71.19, -1175.23)             # the way in: the south end of its front (the pier) and the north end (the
const FRONT_N := Vector2(-68.19, -1188.67)             # lodge's corner) -- bearings from four cameras on the avenue, agreeing to 7 cm
const LODGE := 5.5                                     # where along the front the porter's lodge begins (the gates are south of it)
const FLAGS: Array = [3.1, 5.7, 8.3]                   # the three flagpoles along the front (the region's, the country's, Europe's)...
const FLAGS_BACK := 6.0                                # ...this far behind it
const FENCE_E: Array = [Vector2(-57.0, -1263.0), Vector2(-60.5, -1240.0), Vector2(-66.5, -1200.0), Vector2(-68.0, -1190.0), FRONT_N]
const FENCE_E2: Array = [FRONT_S, Vector2(-79.5, -1176.0), Vector2(-80.5, -1136.0)]
const FLAG_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D tex : source_color;
void vertex() {
	float t = UV.x;
	VERTEX.z += sin(UV.x * 7.0 - TIME * 3.3) * 0.13 * t + sin(UV.y * 3.0 + TIME * 1.9) * 0.03 * t;
	VERTEX.y -= t * t * 0.12;
}
void fragment() {
	ALBEDO = texture(tex, UV).rgb;
	ROUGHNESS = 1.0;
}
"""
const GATE_Z := -1247.0                                 # the car park's gate, on the east fence

var door: Vector2                                      # before the way in, on the map
var blocks: Array = []                                 # [Rect2 on the map, height]: every building (the self-test, the map)
var lamps: Array = []
var _flags: Array = []

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"crema":
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.94, 0.82)), 0.2)
		"ladrillo":
			m = Tex.mat("brick_wall_003@1.15", Color(1.02, 0.9, 0.82))
		"hormigon":
			m = Tex.mat("granular_concrete", Color(0.86, 0.85, 0.82))
		"asfalto":
			m = W._tmat(0x6f6c73, "asphalt", 3.0)
		"pista":
			m = W._tmat(0x8c9a8e, "asphalt", 4.0)
		"tierra":
			m = W._tmat(0xc9ab7c, "earth", 4.0)
		"hoja":
			m = W._tmat(0x5f8a3e, "leaf", 1.5)
		"seto":
			m = W._tmat(0x3d6634, "leaf", 1.1)
		"cipres":
			m = W._tmat(0x2f5634, "leaf", 1.0)
		"morado":
			m = W._tmat(0x4a2a34, "leaf", 1.2)
		"tejas":
			var tm: StandardMaterial3D = Tex.mat("clay_roof_tiles_02", Color(0.86, 0.5, 0.42), true, 1.6)
			tm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = tm
		"cristal":
			var gm := StandardMaterial3D.new()
			gm.albedo_color = Color(0.56, 0.66, 0.72)
			gm.roughness = 0.35
			gm.metallic_specular = 0.3
			m = gm
		"invernadero":
			var im := StandardMaterial3D.new()
			im.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			im.albedo_color = Color(0.9, 0.94, 0.95, 0.55)
			im.roughness = 0.4
			im.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = im
		"chapa":            # the gym's roof of white sheet
			m = Parts.mat(0xe6e8ea)
		"azulado":          # the low blue roof over the court of the main building
			m = Parts.mat(0x3a7ac8)
		"foco":
			var fm := StandardMaterial3D.new()
			fm.albedo_color = Color(1.0, 0.98, 0.92)
			fm.emission_enabled = true
			fm.emission = Color(1.0, 0.96, 0.86)
			fm.emission_energy_multiplier = 1.5
			m = fm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	level = MapData.height(O)
	transform = Transform3D(Basis.IDENTITY, Vector3(O.x, level, O.y))
	W.add_child(self)
	door = _m(2.9, 2.0)
	_grounds()
	for b in COMB:
		_block(b)
	_court_roof()
	_walk()
	for b in NORTH:
		_block(b)
	_hall()
	_gym()
	_courts()
	_park()
	_fences()
	_porch()
	_garden()
	_field()
	_trees()
	_street_side()
	home()
	_commit()
	_tell_map()

## a spot of the way in, on the map: `a` metres along its front from the pier (northwards), `z` out of it (to the avenue)
func _m(a: float, z: float) -> Vector2:
	var u: Vector2 = (FRONT_N - FRONT_S).normalized()
	return FRONT_S + u * a + Vector2(-u.y, u.x) * z

# ---------------- helpers ----------------
## a spot of the map in this frame (x, z)
func _f(p: Vector2) -> Vector2:
	return p - O

## the ground under a spot of the map, in this frame
func _g(p: Vector2) -> float:
	return MapData.height(p) - level

func _ccw(p: PackedVector2Array) -> PackedVector2Array:
	if Geometry2D.is_polygon_clockwise(p):
		p.reverse()
	return p

func _p3(q: Vector2, lift: float) -> Vector3:
	return Vector3(q.x - O.x, MapData.height(q) - level + lift, q.y - O.y)

func _facets(box: Rect2) -> Array:
	var out: Array = []
	var g: float = MapData.rg
	for i in range(int(floor((box.position.x - MapData.rx0) / g)), int(floor((box.end.x - MapData.rx0) / g)) + 1):
		for j in range(int(floor((box.position.y - MapData.rz0) / g)), int(floor((box.end.y - MapData.rz0) / g)) + 1):
			var a := Vector2(MapData.rx0 + i * g, MapData.rz0 + j * g)
			out.append(_ccw(PackedVector2Array([a, a + Vector2(g, 0), a + Vector2(g, g)])))
			out.append(_ccw(PackedVector2Array([a, a + Vector2(g, g), a + Vector2(0, g)])))
	return out

## a flat piece of this outline (on the map) laid on the ground `lift` over it, cut along the relief's facets
func _lay(poly: PackedVector2Array, lift: float, key) -> void:
	if poly.size() < 3:
		return
	pieces += 1
	poly = _ccw(poly)
	var box := Rect2(poly[0], Vector2.ZERO)
	for q in poly:
		box = box.expand(q)
	for facet: PackedVector2Array in _facets(box):
		for piece in Geometry2D.intersect_polygons(poly, facet):
			if piece.size() < 3 or Geometry2D.is_polygon_clockwise(piece):
				continue
			var idx := Geometry2D.triangulate_polygon(piece)
			for t in range(0, idx.size(), 3):
				tri(_p3(piece[idx[t]], lift), _p3(piece[idx[t + 1]], lift), _p3(piece[idx[t + 2]], lift), key, Vector3.UP)

func _rect(r: Array) -> PackedVector2Array:
	return PackedVector2Array([Vector2(r[0], r[1]), Vector2(r[2], r[1]), Vector2(r[2], r[3]), Vector2(r[0], r[3])])

## the floor of a block: the highest ground under it, a step up
func _floor_of(r: Array) -> float:
	var top := -1e9
	for q in _rect(r):
		top = maxf(top, _g(q))
	top = maxf(top, _g(Vector2((r[0] + r[2]) / 2.0, (r[1] + r[3]) / 2.0)))
	return top + 0.15

## The four faces of a rectangle on the map, each as [a, b] (a: its left end seen from outside), in this frame
func _faces(r: Array) -> Array:
	var x0: float = r[0] - O.x
	var z0: float = r[1] - O.y
	var x1: float = r[2] - O.x
	var z1: float = r[3] - O.y
	return [[Vector2(x1, z0), Vector2(x0, z0)], [Vector2(x1, z1), Vector2(x1, z0)], [Vector2(x0, z1), Vector2(x1, z1)], [Vector2(x0, z0), Vector2(x0, z1)]]

## A building: cream walls on a foot of brick, windows in rows (on two floors, one, or none), a flat roof behind a
## parapet; solid. [x0, z0, x1, z1, height, look]
func _block(b: Array) -> void:
	var fl: float = _floor_of(b)
	var h: float = float(b[4])
	var look: String = b[5]
	var top: float = fl + h
	for f in _faces(b):
		var ln: float = face(f[0], f[1])
		var holes: Array = []
		if look != "liso" and ln > 3.0:
			var n := int(floor((ln - 1.2) / 3.2))
			var step: float = (ln - 1.2) / maxf(n, 1)
			var rows: Array = [fl + 1.0] if look == "bajo" else [fl + 1.0, fl + 4.6]
			for i in range(n):
				for y in rows:
					holes.append(Rect2(0.6 + step * (i + 0.5) - 0.9, y, 1.8, 1.4))
		masonry(0.0, ln, DOWN, top + 0.6, holes, [], "crema")
		box(0.0, DOWN, 0.0, ln, fl + 0.7 - DOWN, 0.04, "ladrillo")                    # the foot of brick
		for r: Rect2 in holes:
			window(r, WHITE, 0x34404a, 1)
			box(r.position.x - 0.06, r.position.y - 0.08, 0.0, r.size.x + 0.12, 0.08, 0.12, WHITE)
		if look == "aula":
			box(0.0, fl + 3.8, 0.0, ln, 0.18, 0.05, "ladrillo")                        # a band of brick between the floors
		box(-0.02, top + 0.5, -0.02, ln + 0.04, 0.12, 0.3, WHITE)                      # the parapet's coping
	home()
	flat(_frame_rect(b, 0.25), top, ROOF)
	_prism([_f(Vector2(b[0], b[1])), _f(Vector2(b[2], b[1])), _f(Vector2(b[2], b[3])), _f(Vector2(b[0], b[3]))], DOWN, top + 0.6)
	blocks.append([Rect2(b[0], b[1], b[2] - b[0], b[3] - b[1]), top + 0.6])

func _frame_rect(r: Array, inset := 0.0) -> PackedVector2Array:
	return PackedVector2Array([_f(Vector2(r[0] + inset, r[1] + inset)), _f(Vector2(r[2] - inset, r[1] + inset)), _f(Vector2(r[2] - inset, r[3] - inset)), _f(Vector2(r[0] + inset, r[3] - inset))])

# ---------------- the ground ----------------
## paving all over inside the fence, the court of trees, the patios
func _grounds() -> void:
	_lay(PackedVector2Array([Vector2(-189.5, -1262.0), Vector2(-57.0, -1262.0), Vector2(-60.5, -1240.0), Vector2(-66.5, -1200.0), FRONT_N, FRONT_S, Vector2(-79.5, -1176.0), Vector2(-80.5, -1135.0), Vector2(-189.5, -1135.0)]), 0.03, "hormigon")
	_lay(_rect([-183.0, -1276.0, -117.0, -1262.0]), 0.03, "hormigon")            # the drive round the north of the buildings, under the row of trees
	_lay(_rect([-150.0, -1200.0, -125.0, -1190.0]), 0.05, "tierra")              # the court of trees
	# the west strip between the fence and the buildings: earth, and a path of concrete on it
	_lay(_rect([-189.5, -1225.0, -183.0, -1135.0]), 0.05, "tierra")

## the low blue roof over the court between the third bar and the stub, on slim posts
func _court_roof() -> void:
	var r := [-163.0, -1190.0, -125.0, -1182.0]
	var fl: float = _floor_of(r)
	var y: float = fl + 3.6
	flat(_frame_rect(r), y, "azulado")
	flat(_frame_rect(r), y - 0.15, 0xd9d6cc)
	for x in range(-160, -124, 6):
		cbox(Vector3(x - O.x, (fl + y) / 2.0, -1182.4 - O.y), Vector3(0.18, y - fl, 0.18), WHITE)
		solid(Vector3(x - O.x, (fl + y) / 2.0, -1182.4 - O.y), Vector3(0.2, y - fl, 0.2))
	blocks.append([Rect2(r[0], r[1], r[2] - r[0], r[3] - r[1]), y])

## the covered walk along the east of the main building, by the courts: a slab on white posts
func _walk() -> void:
	var r := [-126.0, -1210.0, -120.0, -1142.0]
	var fl: float = _floor_of(r)
	var y: float = fl + 3.2
	flat(_frame_rect(r), y, ROOF)
	flat(_frame_rect(r), y - 0.2, 0xe6e2d8)
	box(-120.2 - O.x, y - 0.4, -1210.0 - O.y, 0.25, 0.45, 68.0, WHITE)
	for z in range(-1208, -1142, 5):
		cbox(Vector3(-120.4 - O.x, (fl + y) / 2.0, z - O.y), Vector3(0.22, y - fl, 0.22), WHITE)
		solid(Vector3(-120.4 - O.x, (fl + y) / 2.0, z - O.y), Vector3(0.24, y - fl, 0.24))

## the hall: cream walls with tall windows, a hipped roof of red tiles, a pale platform round it
func _hall() -> void:
	_lay(_rect([-166.0, -1257.0, -149.0, -1232.0]), 0.08, 0xd9d4c8)
	var b := [HALL[0], HALL[1], HALL[2], HALL[3], 5.2, "liso"]
	var fl: float = _floor_of(b)
	var top: float = fl + 5.2
	for f in _faces(b):
		var ln: float = face(f[0], f[1])
		var holes: Array = []
		var n := int(floor(ln / 3.0))
		for i in range(n):
			holes.append(Rect2((i + 0.5) * ln / n - 0.6, fl + 1.2, 1.2, 2.8))
		masonry(0.0, ln, DOWN, top, holes, [], "crema")
		box(0.0, DOWN, 0.0, ln, fl + 0.7 - DOWN, 0.04, "ladrillo")
		for r: Rect2 in holes:
			window(r, WHITE, 0x34404a, 2)
	home()
	_hip(HALL[0] - O.x, HALL[2] - O.x, HALL[1] - O.y, HALL[3] - O.y, top, 2.6, 0.5, 0.0, "tejas")
	_prism(Array(_frame_rect(b)), DOWN, top)
	blocks.append([Rect2(HALL[0], HALL[1], HALL[2] - HALL[0], HALL[3] - HALL[1]), top + 2.6])

## The gym: walls of sage-green panels with their ribs, a band of glass under the eaves, a shallow roof of white
## sheet; a lower annex along its north side and a white one along its south
func _gym() -> void:
	var b := [GYM[0], GYM[1], GYM[2], GYM[3], 9.4, "liso"]
	var fl: float = _floor_of(b)
	var top: float = fl + 9.4
	for f in _faces(b):
		var ln: float = face(f[0], f[1])
		box(0.0, DOWN, 0.0, ln, fl + 7.2 - DOWN, 0.06, SAGE)
		var n := int(ln / 0.9)
		for i in range(n + 1):
			box(i * ln / n - 0.04, fl, 0.06, 0.08, 7.2, 0.05, 0x7a948a)
		box(0.0, fl + 7.2, -0.05, ln, top - fl - 7.2, 0.05, "cristal")
		for i in range(int(ln / 1.5) + 1):
			box(i * ln / int(ln / 1.5) - 0.04, fl + 7.2, 0.0, 0.08, top - fl - 7.2, 0.06, 0xd9dcdf)
		box(0.0, fl + 8.3, 0.0, ln, 0.06, 0.06, 0xd9dcdf)
		box(-0.05, top, -0.05, ln + 0.1, 0.25, 0.2, 0xd9dcdf)
	home()
	var x0: float = GYM[0] - O.x
	var x1: float = GYM[2] - O.x
	var z0: float = GYM[1] - O.y
	var z1: float = GYM[3] - O.y
	var zm: float = (z0 + z1) / 2.0
	roof([Vector3(x0 - 0.3, top + 0.2, z0 - 0.3), Vector3(x1 + 0.3, top + 0.2, z0 - 0.3), Vector3(x1 + 0.3, top + 1.2, zm), Vector3(x0 - 0.3, top + 1.2, zm)], "chapa")
	roof([Vector3(x0 - 0.3, top + 1.2, zm), Vector3(x1 + 0.3, top + 1.2, zm), Vector3(x1 + 0.3, top + 0.2, z1 + 0.3), Vector3(x0 - 0.3, top + 0.2, z1 + 0.3)], "chapa")
	for s in [x0 - 0.3, x1 + 0.3]:
		tri(Vector3(s, top + 0.2, z0 - 0.3), Vector3(s, top + 1.2, zm), Vector3(s, top + 0.2, z1 + 0.3), SAGE, Vector3(signf(s - x0) if s > x0 else -1.0, 0, 0))
	_prism(Array(_frame_rect(b)), DOWN, top + 1.2)
	blocks.append([Rect2(GYM[0], GYM[1], GYM[2] - GYM[0], GYM[3] - GYM[1]), top + 1.2])
	_block([-113.0, -1238.5, -66.0, -1233.0, 4.5, "bajo"])
	_block([-105.0, -1204.0, -70.0, -1197.0, 4.0, "bajo"])

# ---------------- the courts ----------------
## two courts side by side, their white lines, a hoop at each end of the basketball one, goals on the other; the
## floodlights on their tall posts
func _courts() -> void:
	_lay(_rect(COURTS), 0.07, "pista")
	var halves: Array = [[-1181.0, -1160.0], [-1158.0, -1137.0]]
	for k in range(2):
		var za: float = halves[k][0] + 0.5
		var zb: float = halves[k][1] - 0.5
		var xa := -121.0
		var xb := -83.0
		var lines: Array = [[Vector2(xa, za), Vector2(xb, za)], [Vector2(xa, zb), Vector2(xb, zb)], [Vector2(xa, za), Vector2(xa, zb)], [Vector2(xb, za), Vector2(xb, zb)], [Vector2((xa + xb) / 2.0, za), Vector2((xa + xb) / 2.0, zb)]]
		for ln in lines:
			var a: Vector2 = ln[0]
			var bb: Vector2 = ln[1]
			var dd: Vector2 = (bb - a).normalized()
			var nn := Vector2(-dd.y, dd.x) * 0.05
			_lay(PackedVector2Array([a - nn, bb - nn, bb + nn, a + nn]), 0.085, WHITE)
		var mid := Vector2((xa + xb) / 2.0, (za + zb) / 2.0)
		var circle := PackedVector2Array()
		for i in range(24):
			circle.append(mid + Vector2(cos(TAU * i / 24.0), sin(TAU * i / 24.0)) * 3.0)
		for i in range(24):
			var a: Vector2 = circle[i]
			var bb: Vector2 = circle[(i + 1) % 24]
			var dd: Vector2 = (bb - a).normalized()
			var nn := Vector2(-dd.y, dd.x) * 0.05
			_lay(PackedVector2Array([a - nn, bb - nn, bb + nn, a + nn]), 0.086, WHITE)
		for s in [-1.0, 1.0]:
			var end := Vector2(mid.x + s * 19.6, mid.y)
			var o := Vector3(end.x - O.x, _g(end), end.y - O.y)
			if k == 0:                                     # basketball: a post, its arm, the board, the ring
				cbox(o + Vector3(s * 1.0, 1.6, 0), Vector3(0.14, 3.2, 0.14), 0x2a5fb0)
				bar(o + Vector3(s * 1.0, 3.2, 0), o + Vector3(s * 0.05, 3.2, 0), 0.1, 0.1, 0x2a5fb0)
				cbox(o + Vector3(0, 3.45, 0), Vector3(0.05, 1.05, 1.8), WHITE)
				cbox(o + Vector3(-s * 0.03, 3.4, 0), Vector3(0.02, 0.45, 0.59), 0xd8243a)
				drum(o + Vector3(-s * 0.3, 3.05, 0), 0.23, 0.23, 0.03, 0xe0602a, 12)
				solid(o + Vector3(s * 1.0, 1.6, 0), Vector3(0.2, 3.2, 0.2))
			else:                                          # futsal: a goal
				for zz in [-1.5, 1.5]:
					cbox(o + Vector3(0, 1.0, zz), Vector3(0.08, 2.0, 0.08), WHITE)
				cbox(o + Vector3(0, 2.0, 0), Vector3(0.08, 0.08, 3.08), WHITE)
				for zz in [-1.5, 1.5]:
					bar(o + Vector3(0, 2.0, zz), o + Vector3(s * 0.9, 0.05, zz), 0.03, 0.03, 0xd9d6cc)
				solid(o + Vector3(0, 1.0, 0), Vector3(0.3, 2.0, 3.2))
	for q in [Vector2(-123.0, -1182.0), Vector2(-81.0, -1182.0), Vector2(-123.0, -1136.0), Vector2(-81.0, -1136.0)]:
		var o := Vector3(q.x - O.x, _g(q), q.y - O.y)
		drum(o, 0.14, 0.09, 12.0, 0x9aa0a4, 8)
		cbox(o + Vector3(0, 12.1, 0), Vector3(1.0, 0.3, 0.3), 0x5a5d60)
		cbox(o + Vector3(0, 11.95, 0.1), Vector3(0.9, 0.04, 0.22), "foco")
		solid(o + Vector3(0, 2.0, 0), Vector3(0.3, 4.0, 0.3))
		var w: Vector3 = transform * (o + Vector3(0, 11.9, 0))
		W.lamp_spots.append(w)
		lamps.append(w)
		yard.append(q)

# ---------------- the car park ----------------
func _park() -> void:
	_lay(PackedVector2Array([Vector2(PARK[0], PARK[1]), Vector2(-57.0, PARK[1]), Vector2(-60.5, PARK[3]), Vector2(PARK[0], PARK[3])]), 0.05, "asfalto")
	for row in [[-1261.5, -1256.5], [-1243.5, -1238.5]]:          # its bays, either side of its lane
		var x: float = PARK[0] + 1.0
		while x < -64.0:
			var a := Vector2(x, row[0])
			var bb := Vector2(x, row[1])
			_lay(PackedVector2Array([a - Vector2(0.05, 0), bb - Vector2(0.05, 0), bb + Vector2(0.05, 0), a + Vector2(0.05, 0)]), 0.06, WHITE)
			x += 2.5
	_lay(_rect([PARK[0] + 1.0, -1249.0, -66.0, -1245.0]), 0.055, "tierra")      # the strip of its trees
	for x in range(-116, -66, 7):
		_tree(Vector2(x, -1247.0), 7.0, 2.2)

# ---------------- the fences ----------------
## a stretch of fence from p to q (on the map): a low wall painted blue under a white coping, a mesh on posts over
## it, a hedge behind (on its inner side); `wall`: false for a mesh straight on the ground
func _fence_run(p: Vector2, q: Vector2, wall := true, hedge := true) -> void:
	var ln: float = p.distance_to(q)
	var d: Vector2 = (q - p) / ln
	var n := maxi(1, int(ceil(ln / 2.5)))
	var inn := Vector2(-d.y, d.x)
	if inn.dot(Vector2(-130.0, -1200.0) - p) < 0.0:
		inn = -inn
	for i in range(n):
		var a: Vector2 = p + d * (ln * i / n)
		var b: Vector2 = p + d * (ln * (i + 1) / n)
		var ya: float = _g(a)
		var yb: float = _g(b)
		var fa := _f(a)
		var fb := _f(b)
		var low := minf(ya, yb) - 0.5
		var top := 0.0
		if wall:
			top = 0.7
			_slab_wall(fa, fb, 0.22, low, ya + 0.7, yb + 0.7, BLUE)
			_slab_wall(fa, fb, 0.28, ya + 0.7, ya + 0.76, yb + 0.76, WHITE)
		cbox(Vector3(fa.x, ya + top + 0.85, fa.y), Vector3(0.06, 1.7, 0.06), MESH)
		for y in [top + 0.1, top + 0.9, top + 1.68]:
			bar(Vector3(fa.x, ya + y, fa.y), Vector3(fb.x, yb + y, fb.y), 0.025, 0.025, MESH)
		var m := int((ln / n) / 0.2)
		for j in range(1, m):
			var t: float = float(j) / m
			var g: Vector2 = fa.lerp(fb, t)
			cbox(Vector3(g.x, lerpf(ya, yb, t) + top + 0.86, g.y), Vector3(0.012, 1.62, 0.012), MESH)
		if hedge:
			var h1: Vector2 = a + inn * 0.7
			var h2: Vector2 = b + inn * 0.7
			var hm: Vector2 = (h1 + h2) / 2.0
			var hc := Vector3(hm.x - O.x, _g(hm) + 1.05, hm.y - O.y)
			tbox(Transform3D(Basis(Vector3.UP, atan2(-d.y, d.x)) * Basis.from_scale(Vector3(ln / n + 0.1, 2.1, 0.9)), hc), "seto")
	var mid: Vector2 = _f((p + q) / 2.0)
	solid(Vector3(mid.x, _g((p + q) / 2.0) + 1.3, mid.y), Vector3(ln, 2.6, 0.3), atan2(-d.y, d.x))
	yard.append(p)
	yard.append(q)

func _slab_wall(a: Vector2, b: Vector2, thick: float, low: float, t0: float, t1: float, key) -> void:
	pieces += 1
	var d: Vector2 = (b - a).normalized()
	var n := Vector2(-d.y, d.x) * thick / 2.0
	var c := [a - n, b - n, b + n, a + n]
	for s in [[0, 1, -1.0], [3, 2, 1.0]]:
		var u0: Vector2 = c[s[0]]
		var u1: Vector2 = c[s[1]]
		quad(Vector3(u0.x, low, u0.y), Vector3(u1.x, low, u1.y), Vector3(u1.x, t1, u1.y), Vector3(u0.x, t0, u0.y), key, Vector3(n.x, 0, n.y).normalized() * float(s[2]))
	quad(Vector3(c[0].x, t0, c[0].y), Vector3(c[1].x, t1, c[1].y), Vector3(c[2].x, t1, c[2].y), Vector3(c[3].x, t0, c[3].y), key, Vector3.UP)
	quad(Vector3(c[0].x, low, c[0].y), Vector3(c[3].x, low, c[3].y), Vector3(c[3].x, t0, c[3].y), Vector3(c[0].x, t0, c[0].y), key, Vector3(-d.x, 0, -d.y))
	quad(Vector3(c[1].x, low, c[1].y), Vector3(c[2].x, low, c[2].y), Vector3(c[2].x, t1, c[2].y), Vector3(c[1].x, t1, c[1].y), key, Vector3(d.x, 0, d.y))

## a white pier of a gate
func _pier(at: Vector2) -> void:
	var f := _f(at)
	var y: float = _g(at)
	cbox(Vector3(f.x, y + 0.9, f.y), Vector3(0.5, 2.6, 0.5), WHITE)
	cbox(Vector3(f.x, y + 2.25, f.y), Vector3(0.58, 0.08, 0.58), 0xd9d6cc)
	solid(Vector3(f.x, y + 1.0, f.y), Vector3(0.5, 2.6, 0.5))

func _fences() -> void:
	# the east fence on the avenue, with the car park's gate in it
	var gate0 := Vector2(-59.0, GATE_Z - 3.0)
	var gate1 := Vector2(-59.9, GATE_Z + 3.0)
	_fence_run(FENCE_E[0], gate0)
	_pier(gate0)
	_pier(gate1)
	var g0 := _f(gate0)
	var g1 := _f(gate1)
	var gy: float = _g(gate0)
	for i in range(2):                                 # the gate: two leaves of mesh in their frames, shut
		var a: Vector2 = g0.lerp(g1, i * 0.5)
		var b: Vector2 = g0.lerp(g1, i * 0.5 + 0.5)
		for y in [0.1, 1.0, 1.9]:
			bar(Vector3(a.x, gy + y, a.y), Vector3(b.x, gy + y, b.y), 0.05, 0.05, MESH)
		for j in range(13):
			var c: Vector2 = a.lerp(b, j / 12.0)
			cbox(Vector3(c.x, gy + 1.0, c.y), Vector3(0.02, 1.9, 0.02), MESH)
	solid(Vector3((g0.x + g1.x) / 2.0, gy + 1.0, (g0.y + g1.y) / 2.0), Vector3(0.3, 2.0, 6.0), atan2(-(g1 - g0).y, (g1 - g0).x) + PI / 2.0)
	_fence_run(gate1, FENCE_E[1])
	for i in range(1, FENCE_E.size() - 1):
		_fence_run(FENCE_E[i], FENCE_E[i + 1])
	for i in range(FENCE_E2.size() - 1):
		_fence_run(FENCE_E2[i], FENCE_E2[i + 1], true, i > 0)       # (no hedge on the first stretch: it would stand in the passage)
	# the south, west and north sides on the fields: mesh, hedge
	_fence_run(Vector2(-80.5, -1135.0), Vector2(-189.5, -1135.0), false)
	_fence_run(Vector2(-189.5, -1135.0), Vector2(-189.5, -1226.0), false, false)
	_fence_run(Vector2(-189.5, -1226.0), Vector2(-183.0, -1226.0), false, false)
	_fence_run(Vector2(-183.0, -1226.0), Vector2(-183.0, -1305.0), false, false)
	_fence_run(Vector2(-183.0, -1305.0), Vector2(-117.0, -1305.0), false)
	_fence_run(Vector2(-117.0, -1305.0), Vector2(-117.0, -1263.0), false)
	_fence_run(Vector2(-117.0, -1263.0), Vector2(-57.0, -1263.0), false, false)

# ---------------- the way in ----------------
## The way in on the avenue (Street View, November 2024, and the user's photo of it, 17 November 2026): a long flat
## canopy with a dark edge, and on it the board with the school's name in raised letters of slate blue; under it, at
## the south, a white pier with the notice of the school and the iron gates of the passage, standing open; at the
## north the porter's lodge, white on a blue foot, two windows with grey louvres, a grey door; pale paving before it
## all; behind, the three flags.
func _porch() -> void:
	var L: float = FRONT_S.distance_to(FRONT_N)
	var fl := -1e9
	for k in range(15):
		fl = maxf(fl, _g(_m(k * L / 14.0, 0.6)))
	fl += 0.06
	var nf := func(a: float, z: float) -> Vector2:
		return _f(_m(a, z))
	var ceil_y: float = fl + 3.3
	var back := -4.0
	face(nf.call(0.0, 0.0), nf.call(L, 0.0))
	# the paving, under the canopy and through the passage
	flat(PackedVector2Array([Vector2(-0.4, 1.0), Vector2(L + 0.4, 1.0), Vector2(L + 0.4, back - 2.5), Vector2(-0.4, back - 2.5)]), fl, 0xd6d0c2)
	box(-0.4, fl - 0.6, 0.98, L + 0.8, 0.6, 0.04, 0xc9c2b4)
	# the pier at the south end, and the school's notice on it
	box(-0.35, DOWN, -0.55, 0.7, ceil_y - DOWN, 0.6, WHITE)
	box(-0.28, fl + 0.85, 0.05, 0.56, 1.25, 0.02, 0xf8f8f4)
	box(-0.28, fl + 1.94, 0.07, 0.56, 0.16, 0.004, 0x2c4fc4)
	box(-0.08, fl + 1.62, 0.07, 0.16, 0.22, 0.004, 0x8a1c3a)
	for k in range(5):
		box(-0.2, fl + 1.0 + k * 0.1, 0.07, 0.4 - 0.06 * (k % 2), 0.025, 0.004, 0x8a8d90)
	solid(Vector3(_f(_m(0.0, -0.25)).x, fl + 1.6, _f(_m(0.0, -0.25)).y), Vector3(0.7, 3.4, 0.6), atan2(-(FRONT_N - FRONT_S).y, (FRONT_N - FRONT_S).x))
	# the gates of the passage, standing open: two leaves of bars swung in against its sides
	for side in [[0.35, 1.0, 1.3], [LODGE, -1.0, -1.3]]:
		var keep := _xf
		_xf = _xf * Transform3D(Basis(Vector3.UP, side[2]), Vector3(side[0], 0.0, -0.2))
		var s: float = side[1]
		var ln := 2.5
		for y in [0.08, 1.25, 2.42]:
			box(minf(0.0, s * ln), fl + y, -0.025, ln, 0.06, 0.05, 0x2e3032)
		for x in [0.0, s * (ln - 0.06)]:
			box(minf(x, x + 0.06), fl + 0.08, -0.03, 0.06, 2.4, 0.06, 0x2e3032)
		for k in range(1, 21):
			var x: float = s * ln * k / 21.0
			box(x - 0.012, fl + 0.12, -0.012, 0.024, 2.32, 0.024, 0x2e3032)
		_xf = keep
	# the porter's lodge: its front with two louvred windows and a door, a sign by the passage
	var lodge_f: Array = [Rect2(8.3, fl + 1.65, 0.95, 0.72), Rect2(10.5, fl + 1.65, 0.95, 0.72)]
	var door_r := Rect2(12.45, fl, 0.92, 2.15)
	masonry(LODGE, L, DOWN, ceil_y, lodge_f + [door_r], [], WHITE)
	box(LODGE, DOWN, 0.0, door_r.position.x - LODGE, fl + 0.6 - DOWN, 0.03, BLUE)
	box(door_r.end.x, DOWN, 0.0, L - door_r.end.x, fl + 0.6 - DOWN, 0.03, BLUE)
	for r: Rect2 in lodge_f:
		box(r.position.x, r.position.y, -0.16, r.size.x, r.size.y, 0.02, 0x8a8d90)
		for k in range(6):
			box(r.position.x + 0.04, r.position.y + 0.05 + k * 0.11, -0.13, r.size.x - 0.08, 0.04, 0.09, 0xb4b7ba)
		box(r.position.x - 0.05, r.position.y - 0.06, 0.0, r.size.x + 0.1, 0.06, 0.08, 0xf6f4ee)
	box(door_r.position.x, fl, -0.16, door_r.size.x, door_r.size.y, 0.04, 0x8f9396)
	box(door_r.position.x + 0.1, fl + 1.65, -0.12, door_r.size.x - 0.2, 0.32, 0.02, 0xa6aaad)
	box(door_r.end.x - 0.14, fl + 1.0, -0.12, 0.04, 0.16, 0.05, 0x3a3a3c)
	box(LODGE + 0.35, fl + 2.15, 0.0, 0.42, 0.55, 0.02, 0xf8f8f4)                   # its notices by the passage
	box(LODGE + 0.35, fl + 2.6, 0.02, 0.42, 0.08, 0.004, 0x2c4fc4)
	box(LODGE + 1.0, fl + 2.3, 0.0, 0.32, 0.36, 0.02, 0xf8f8f4)
	# its other three walls
	for w in [[nf.call(LODGE, back), nf.call(LODGE, 0.0), true], [nf.call(L, 0.0), nf.call(L, back), false], [nf.call(L, back), nf.call(LODGE, back), false]]:
		var ln: float = face(w[0], w[1])
		var holes: Array = [Rect2(1.2, fl, 0.9, 2.15)] if w[2] else []
		masonry(0.0, ln, DOWN, ceil_y, holes, [], WHITE)
		box(0.0, DOWN, 0.0, ln, fl + 0.6 - DOWN, 0.03, BLUE)
		if w[2]:
			box(1.2, fl, -0.16, 0.9, 2.15, 0.04, 0x8f9396)
	face(nf.call(0.0, 0.0), nf.call(L, 0.0))
	var lc: Array = [nf.call(LODGE, 0.0), nf.call(L, 0.0), nf.call(L, back), nf.call(LODGE, back)]
	_prism(lc, DOWN, ceil_y)
	# the canopy over it all, its dark edge; the board on it, the name in raised letters
	box(-0.5, ceil_y, back - 0.4, L + 1.0, 0.22, -back + 0.4 + 0.42, 0xeeebe4)
	box(-0.5, ceil_y, 0.4, L + 1.0, 0.22, 0.04, 0x6e5e4c)
	for x in [-0.5, L + 0.46]:
		box(x, ceil_y, back - 0.4, 0.04, 0.22, -back + 0.84, 0x6e5e4c)
	box(0.5, ceil_y + 0.22, -0.32, 11.7, 1.05, 0.32, 0xe9e6df)
	box(0.48, ceil_y + 1.27, -0.34, 11.74, 0.05, 0.36, 0xd2cec4)
	var shade := _text(NAME, Vector3(6.37, ceil_y + 0.72, 0.004), 150, 0x4a5566, 0.0066)
	shade.outline_size = 14
	shade.outline_modulate = shade.modulate
	var name_l := _text(NAME, Vector3(6.35, ceil_y + 0.74, 0.03), 150, 0x76859c, 0.0066)
	name_l.outline_size = 14
	name_l.outline_modulate = name_l.modulate
	var front_ring: Array = [nf.call(-0.5, 0.45), nf.call(L + 0.5, 0.45), nf.call(L + 0.5, back - 0.4), nf.call(-0.5, back - 0.4)]
	var lo: Rect2 = Rect2(lc[0], Vector2.ZERO)
	for q: Vector2 in lc:
		lo = lo.expand(q)
	blocks.append([Rect2(lo.position + O, lo.size), ceil_y + 1.32])
	home()
	# the three flags behind it: the region's, the country's, Europe's, flying to the south-east
	var u: Vector2 = (FRONT_N - FRONT_S).normalized()
	var fly: Vector2 = (-u + Vector2(-u.y, u.x) * 0.5).normalized()
	var names: Array = ["region", "espana", "europa"]
	for k in range(3):
		var at: Vector2 = _m(FLAGS[k], -FLAGS_BACK)
		var o := Vector3(at.x - O.x, _g(at), at.y - O.y)
		drum(o - Vector3(0, 0.05, 0), 0.2, 0.2, 0.1, 0xd9d6cc, 10)
		drum(o, 0.065, 0.045, 9.4, 0xf2f1ec, 10)
		ball(o + Vector3(0, 9.46, 0), 0.07, 0xd9b84a, 1.0, 8, 5)
		var mesh := QuadMesh.new()
		mesh.size = Vector2(1.5, 1.0)
		mesh.subdivide_width = 12
		mesh.subdivide_depth = 4
		var sm := ShaderMaterial.new()
		var sh := Shader.new()
		sh.code = FLAG_SHADER
		sm.shader = sh
		sm.set_shader_parameter("tex", load("res://assets/ies/bandera_%s.png" % names[k]))
		var flag := MeshInstance3D.new()
		flag.mesh = mesh
		flag.material_override = sm
		flag.position = Vector3(0.79, 0, 0)
		var holder := Node3D.new()
		holder.position = o + Vector3(0, 9.4 - 0.55, 0)
		holder.rotation.y = atan2(-fly.y, fly.x)
		holder.add_child(flag)
		add_child(holder)
		_flags.append(flag)
		solid(o + Vector3(0, 2.0, 0), Vector3(0.2, 4.0, 0.2))
		yard.append(at)

# ---------------- green things ----------------
## the stepped garden before the vocational school: terraces of planted earth behind low walls, the purple tree
func _garden() -> void:
	for k in range(4):
		var r := [-150.0 + k * 3.0, -1238.0 + k * 3.0, -120.0 - k * 2.0, -1235.0 + k * 3.0]
		_lay(_rect(r), 0.12 + k * 0.25, "tierra")
		var y: float = _g(Vector2(r[0], r[1])) + 0.12 + k * 0.25
		box(r[0] - O.x, y - 0.6, r[1] - O.y - 0.1, r[2] - r[0], 0.6 + 0.08, 0.2, CREAM)
		for i in range(5):
			ball(Vector3(r[0] - O.x + 2.0 + i * (r[2] - r[0] - 4.0) / 4.0, y + 0.35, r[1] - O.y + 1.5), 0.5, "seto", 0.9, 8, 5)
	_tree(Vector2(-132.0, -1228.0), 5.0, 2.4, "morado")

## the field of the north with its long greenhouse and its shed
func _field() -> void:
	_lay(_rect([-163.0, -1300.0, -118.0, -1276.0]), 0.04, "tierra")
	for k in range(16):                                  # its furrows
		var z := -1298.5 + k * 1.4
		_lay(_rect([-160.0, z, -121.0, z + 0.22]), 0.06, 0x9a7a52)
	var r := [-173.0, -1300.0, -163.0, -1277.0]
	_lay(_rect([-174.0, -1301.0, -162.0, -1276.0]), 0.05, 0xd9d4c8)
	var fl: float = _floor_of(r)
	var x0: float = r[0] - O.x
	var x1: float = r[2] - O.x
	var z0: float = r[1] - O.y
	var z1: float = r[3] - O.y
	var xm: float = (x0 + x1) / 2.0
	for s in [[x0, xm], [x1, xm]]:                       # its two slopes, and its walls, of clouded plastic
		quad(Vector3(s[0], fl + 2.4, z0), Vector3(s[0], fl + 2.4, z1), Vector3(s[1], fl + 3.8, z1), Vector3(s[1], fl + 3.8, z0), "invernadero", Vector3(signf(s[0] - xm) * 0.7, 0.7, 0))
	for x in [x0, x1]:
		quad(Vector3(x, fl, z0), Vector3(x, fl, z1), Vector3(x, fl + 2.4, z1), Vector3(x, fl + 2.4, z0), "invernadero", Vector3(1, 0, 0))
	for z in [z0, z1]:
		quad(Vector3(x0, fl, z), Vector3(x1, fl, z), Vector3(x1, fl + 2.4, z), Vector3(x0, fl + 2.4, z), "invernadero", Vector3(0, 0, 1))
		tri(Vector3(x0, fl + 2.4, z), Vector3(x1, fl + 2.4, z), Vector3(xm, fl + 3.8, z), "invernadero", Vector3(0, 0, 1))
	for k in range(9):                                   # its ribs
		var z: float = lerpf(z0, z1, k / 8.0)
		for s in [x0, x1]:
			cbox(Vector3(s, fl + 1.2, z), Vector3(0.05, 2.4, 0.05), 0xd9dcdf)
		bar(Vector3(x0, fl + 2.4, z), Vector3(xm, fl + 3.8, z), 0.04, 0.04, 0xd9dcdf)
		bar(Vector3(x1, fl + 2.4, z), Vector3(xm, fl + 3.8, z), 0.04, 0.04, 0xd9dcdf)
	_prism(Array(_frame_rect(r)), DOWN, fl + 2.4)
	blocks.append([Rect2(r[0], r[1], r[2] - r[0], r[3] - r[1]), fl + 3.8])
	_block([-175.0, -1272.0, -172.0, -1268.5, 2.4, "liso"])          # the shed

## a tree: a trunk, a crown of a few balls
func _tree(at: Vector2, tall: float, crown: float, key = "hoja") -> void:
	var o := Vector3(at.x - O.x, _g(at), at.y - O.y)
	drum(o - Vector3(0, 0.1, 0), 0.2, 0.14, tall * 0.55, 0x6b5a45, 7)
	ball(o + Vector3(0, tall * 0.7, 0), crown, key, 0.85, 9, 5)
	ball(o + Vector3(crown * 0.55, tall * 0.62, -crown * 0.3), crown * 0.7, key, 0.85, 8, 5)
	ball(o + Vector3(-crown * 0.5, tall * 0.6, crown * 0.35), crown * 0.68, key, 0.85, 8, 5)
	solid(o + Vector3(0, 1.0, 0), Vector3(0.4, 2.2, 0.4))
	yard.append(at)

## a cypress of the west hedge
func _cypress(at: Vector2, tall: float) -> void:
	var o := Vector3(at.x - O.x, _g(at), at.y - O.y)
	drum(o, 0.12, 0.1, 0.8, 0x5a4636, 6)
	drum(o + Vector3(0, 0.6, 0), 0.9, 0.7, tall * 0.5, "cipres", 8)
	drum(o + Vector3(0, 0.6 + tall * 0.5, 0), 0.7, 0.06, tall * 0.5 - 0.6, "cipres", 8)
	yard.append(at)

func _trees() -> void:
	for q in [Vector2(-112.0, -1193.0), Vector2(-104.0, -1188.0), Vector2(-97.0, -1192.0), Vector2(-90.0, -1189.0), Vector2(-82.0, -1194.0), Vector2(-108.0, -1199.0)]:
		_tree(q, 8.0, 2.8)
	for q in [Vector2(-145.0, -1195.0), Vector2(-138.0, -1193.0), Vector2(-131.0, -1196.0)]:
		_tree(q, 7.5, 2.6)
	for x in range(-160, -121, 7):
		_tree(Vector2(x, -1269.0), 9.0, 3.2)
	for z in range(-1302, -1228, 3):
		_cypress(Vector2(-181.0, z), 6.5)
	for z in range(-1220, -1138, 6):
		_cypress(Vector2(-187.0, z), 4.5)

# ---------------- before the fence ----------------
## Between the fence and the avenue's pavement (Street View): a broad strip of beaten earth where cars park, a row of
## trees in it, and pale paving before the way in.
func _street_side() -> void:
	var line: Array = [Vector2(-57.0, -1263.0), Vector2(-60.5, -1240.0), Vector2(-66.5, -1200.0), Vector2(-68.0, -1190.0), _m(13.77, 0.9),
		_m(0.0, 0.9), Vector2(-79.5, -1176.0), Vector2(-80.5, -1136.0)]
	var pts: Array = []                                # along the fence every 2 m: [the fence's foot, the pavement's edge]
	for i in range(line.size() - 1):
		var a: Vector2 = line[i]
		var b: Vector2 = line[i + 1]
		var n := maxi(1, int(ceil(a.distance_to(b) / 2.0)))
		for k in range(n):
			var p: Vector2 = a.lerp(b, float(k) / n)
			var r: Dictionary = MapData.nearest_road(p)
			if r.is_empty():
				continue
			var on: Vector2 = r["p"]
			var away: Vector2 = (p - on).normalized()
			var edge: Vector2 = on + away * (float(r["seg"].hw) + 3.4)
			if (p - edge).dot(away) < 0.8:
				continue
			pts.append([p + away * 0.25, edge])
	var since := 0.0
	var side := 1.0
	for i in range(pts.size() - 1):
		var a0: Vector2 = pts[i][0]
		var a1: Vector2 = pts[i][1]
		var b0: Vector2 = pts[i + 1][0]
		var b1: Vector2 = pts[i + 1][1]
		var paved: bool = a0.y > -1192.0 and a0.y < -1170.0           # (before the way in)
		_lay(PackedVector2Array([a0, b0, b1, a1]), 0.02, 0xd6d0c2 if paved else "tierra")
		since += a0.distance_to(b0)
		if since > 11.0 and not paved:                                  # a tree every eleven metres or so, in the earth
			since = 0.0
			side = -side
			var at: Vector2 = a0.lerp(a1, 0.5 + 0.12 * side)
			_tree(at, 7.5, 2.4)

# ---------------- what the map should know ----------------
## its buildings, for the little map and for whoever asks the map how much room there is
func _tell_map() -> void:
	for b in blocks:
		var r: Rect2 = b[0]
		var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
		MapData.outlines.append(pts)
		if not MapData._wall_grid.is_empty():
			for i in range(4):
				var a: Vector2 = pts[i]
				var c: Vector2 = pts[(i + 1) % 4]
				MapData._grid_add(MapData._wall_grid, a.min(c), a.max(c), [a, c])
