extends "res://scripts/obra.gd"
## The fairground and market ("Recinto ferial y mercadillo"; the user, 17 November 2026: "Son una entrada con fuente, una
## entrada con columnas con enredaderas, y tres caminos asfaltados con aceras amplias. Donde se montan ciertos eventos del
## pueblo"), south of the Auditorio, between the Calle del Cristo's end and the road by the Mingoliva. Built by hand from
## Street View (the car went in along its paths in March 2013; round it in November 2024) and the orthophoto (PNOA), on
## the paths, the roundabout and the ground the map already has (no rebake). Measured: referencias/ferial/LEEME.md.
##
##   - the three paths: asphalt with its kerbs, and between them and round them wide strips of beaten earth (where the
##     stalls and the rides stand at the fair), not lawn; tall lamps along them; pairs of containers;
##   - the entrance with the fountain: the island of the roundabout, a ring of red blocks inside its kerb, the round basin
##     of stone with its iron railing, the water, the spout;
##   - the entrance with the columns and the climbers: the pergola along the street to the north, its columns and arches
##     grown over with ivy, its walk under them;
##   - the market's square by it: chequered tiles, red and white, under rows of frames of blue steel (where the stalls of
##     the market go).
##
## Frame: the map's own (x east, z south); y the ground's own height everywhere (MapData.height).

const FAIR: Array = [Vector2(124.0, 606.0), Vector2(182.0, 622.0), Vector2(150.0, 716.0), Vector2(120.0, 720.0), Vector2(92.0, 706.0), Vector2(90.0, 680.0)]   # where its paths are (their middles)
const STRIPS_AT: Array = [Vector2(122.0, 655.0), Vector2(147.0, 660.0), Vector2(90.0, 690.0)]   # a spot in each of the map's lawns round the paths
const FOUNTAIN_NEAR := Vector2(159.0, 595.0)
const PLAZA_LOOP: Array = [Vector2(180, 543), Vector2(201, 551), Vector2(190, 578), Vector2(190, 585), Vector2(192, 589), Vector2(195, 593), Vector2(199, 595),
	Vector2(192, 615), Vector2(178, 610), Vector2(174, 604), Vector2(170, 597), Vector2(168, 591), Vector2(167, 584), Vector2(167, 575)]   # the roads round the market's square (their middles)
const NORTH_A := Vector2(155.0, 533.0)    # the street to the north: its line
const NORTH_B := Vector2(201.0, 551.0)
const PERGOLA := [10.63, 45.83]     # the pergola, metres along that line (its columns either side of the main walk, which crosses it a little aslant)
const BLOCK_W := [-2, 2]            # the two blocks of ivy behind it, by column (_col_s): the west one...
const BLOCK_E := [7, 12]            # ...and the east one, towards the kiosk; the little fountain's square between them
const TUNNEL_HALF := 2.4            # the ivy over the park's walk: its columns this far either side of it
# The main walk of the whole place (the user, 17 Nov 2026, with a line drawn on a picture of it: "La linea roja es la
# 'calle' principal del recinto (las fuentes están en mitad). Se divide en camino empedrado (azul) y asfalto (rojo)"):
# one straight line from the fairground's middle path, through the roundabout's fountain, across the market's square and
# the fairground's street, through the little fountain and the oval one to the Paseo del Cristo. Asphalt in the
# fairground (its paths, the way in from the north), setts in the park.
const AXIS_P := Vector2(159.59, 594.08)  # the roundabout's middle
const AXIS_D := Vector2(0.342, -0.9397)  # towards the Paseo
const AXIS_X := 55.22                    # where it crosses the fairground's street (metres from AXIS_P)...
const AXIS_S := 25.21                    # ...which is this far along that street's line
const AXIS_WALK := 2.4                   # the park's walk of setts, this wide (between the columns of the ivy walks)
const PERGOLA_OUT := [6.0, 9.0]     # ...and how far north of its middle, its two rows of columns
const BLUE := 0x2f6fd8
const PASEO_A := Vector2(156.0, 463.0)    # the Paseo del Cristo, north of the park: its line
const PASEO_B := Vector2(231.0, 492.0)
const PASEO_S := 48.32                   # where along it the fountain's square has its middle (on the main walk)
const PAVEMENT := 5.35                    # the Paseo's pavement's outer edge, from its middle
const ROUND_R := [16.2, 19.0]            # the half circle of ivy round that square: its two rows of columns
const HUERTA_A := Vector2(212.0, 555.0)   # the Calle de la Huerta, east of the park: its line, from the fairground's corner
const HUERTA_B := Vector2(234.0, 493.0)
const HUERTA_WALK := [16.0, 57.0]        # the ivy walk along it, metres from that corner
const KIOSK := Vector2(209.4, 542.6)     # the kiosk at the corner, under the ivy
const PARK_TREES: Array = [Vector2(170.0, 503.0), Vector2(172.0, 516.0), Vector2(182.0, 515.5), Vector2(196.0, 512.0), Vector2(206.0, 518.0), Vector2(199.0, 526.0), Vector2(208.5, 530.0), Vector2(165.0, 520.0)]
const KERB := 0xbdb8ae
const PlazaS = preload("res://scripts/plaza.gd")   # (its water and its jet: the fountain of the plaza's garden)
# The open-air Auditorio north of the fairground and the public toilets at its corner (the user, 17 Nov 2026, on a
# picture with them in green and red: "para el auditorio solo un hueco en el muro por donde pasar y para los baños una
# entrada con flecha a otra ubicación"). Traced on the orthophoto; Street View 2013 round it and inside, 2024 from the car
# park on the west and from the street's end.
const AUD_C0 := Vector2(141.7, 532.1)        # the toilets' south-west corner: where the Auditorio's west wall meets its north wall's line
const AUD_E := Vector2(0.928, 0.371)         # along that north wall, eastwards...
const AUD_N := Vector2(0.371, -0.928)        # ...and along the west wall, northwards
const AUD_NE := Vector2(171.4, 544.0)        # its north-east corner
const AUD_SE := Vector2(164.6, 566.0)        # the east wall's south end: the round corner from there...
const AUD_BEND := Vector2(160.5, 580.5)      # ...(its control point)...
const AUD_S := Vector2(140.0, 583.4)         # ...to here; then two short walls to the west wall's south end
const AUD_SW: Array = [Vector2(128.5, 580.5), Vector2(125.6, 572.4)]
const AUD_GAP := [7.5, 10.0]                 # the way in, the user's "hueco en el muro": metres along the north wall from AUD_C0, beside the toilets
const AUD_TALL := 2.0                        # the cream wall; on the car park's side it is white and taller
const AUD_WEST_TALL := 2.4
const AUD_EARTH := Vector2(132.0, 541.0)     # the earth before the benches (where the stage goes up at the fair): a quarter of an ellipse round here...
const AUD_AXES := Vector2(15.5, 21.0)        # ...its half-axes, east and south
const AUD_ROWS := 9                          # the benches: nine rows round it, the first 2.5 m off it, one every 1.05 m,
const AUD_ROW0 := 2.5
const AUD_ROW_STEP := 1.05
const AUD_BLOCKS := [[-4.0, 12.0], [15.0, 35.0], [39.0, 64.0], [68.0, 96.0]]   # in four blocks (degrees round it, from the east towards the south), aisles between
const WC := Vector2(7.5, 10.0)               # the toilets: along the north wall's line and northwards from AUD_C0
const AseosS = preload("res://scripts/aseos_dentro.gd")

var center := Vector2.ZERO          # the fountain's
var island_r := 0.0
var basin_r := 0.0
var posts := 0                      # the market's frames
var lamps: Array = []
var plaza: PackedVector2Array
var walk_ends: Array = []           # the park's walk of setts: its two ends (the self-test)
var terraces: Array = []            # the bars' terraces under the ivy (the self-test)
var jets := 0                       # the fountains' jets of water
var _water_shader: Shader
var _jet_shader: Shader
var oval_center := Vector2.ZERO     # the park's fountains
var little_center := Vector2.ZERO
var aseos                           # the toilets' inside, a set apart (aseos_dentro.gd), entered by the green arrow at their double door
var aud_outline := PackedVector2Array()   # the Auditorio's walls, round (the self-test)
var aud_gap: Array = []             # its way in: the two ends of the gap (the self-test)
var aud_benches := 0                # how many stretches of bench
var aud_poles: Array = []           # its poles with floodlights
var stage := PackedVector2Array()   # its stage: its outline on the map, its floor's height, a spot on it, the way up its steps (the self-test)
var stage_top := 0.0
var stage_mid := Vector2.ZERO
var stage_climb: Array = []
var wc_outline := PackedVector2Array()    # the toilets' walls, round

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"asfalto":          # (as the town's: world.gd)
			m = W._tmat(0x77727a, "asphalt", 3.0)
		"tierra":           # beaten earth, pale
			m = W._tmat(0xd9c9a2, "earth", 4.0)
		"bloque":           # the red blocks of the island
			m = W._tmat(0x8c4c42, "pavement", 1.2)
		"piedra":
			m = Tex.mat("granular_concrete", Color(0.95, 0.92, 0.86))
		"losa":             # the pergola's walk
			m = W._tmat(0xd8d2c4, "pavement", 2.0)
		"hiedra":
			m = W._tmat(0x3d6a34, "leaf", 1.1)
		"seto":             # the clipped hedges, darker
			m = W._tmat(0x2f5528, "leaf", 0.8)
		"hoja":             # the trees' crowns
			m = W._tmat(0x5f8a3a, "leaf", 1.4)
		"arenisca":         # the fountains' sandstone
			m = Tex.mat("granular_concrete", Color(1.02, 0.9, 0.7))
		"empedrado":        # the setts of the park's main walk (the town's: empedrado.gd's, each tile 2 m)
			var em := StandardMaterial3D.new()
			em.albedo_texture = load("res://assets/empedrado/adoquin.png")
			em.uv1_triplanar = true
			em.uv1_world_triplanar = true
			em.uv1_scale = Vector3.ONE / 2.0
			em.roughness = 0.9
			m = em
		"pavimento":        # the park's grey pavers
			m = W._tmat(0xb4aea4, "pavement", 1.0)
		"agua":
			var am := StandardMaterial3D.new()
			am.albedo_color = Color(0.32, 0.55, 0.5, 0.82)
			am.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			am.roughness = 0.08
			am.metallic_specular = 0.7
			m = am
		"baldosa":          # red and white, chequered, in squares of half a metre
			var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
			img.set_pixel(0, 0, Parts.col(0xe2ddd4)); img.set_pixel(1, 1, Parts.col(0xe2ddd4))
			img.set_pixel(1, 0, Parts.col(0x8e6460)); img.set_pixel(0, 1, Parts.col(0x8e6460))
			var bm := StandardMaterial3D.new()
			bm.albedo_texture = ImageTexture.create_from_image(img)
			bm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			bm.uv1_triplanar = true
			bm.uv1_world_triplanar = true
			bm.uv1_scale = Vector3.ONE / 1.0
			bm.roughness = 0.85
			m = bm
		"crema":            # the Auditorio's wall and the toilets: cream plaster (pale in the shade too)
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.97, 0.9, 0.73)), 0.14)
		"banco":            # the Auditorio's white benches
			m = _glow(Tex.mat("granular_concrete", Color(1.04, 1.04, 1.02)), 0.22)
		"hormigon":         # its floor
			m = W._tmat(0xb7b3ab, "pavement", 2.5)
		"escenario_muro":   # the stage's front: grey blocks of stone
			m = Tex.mat("medieval_blocks_03", Color(0.86, 0.85, 0.83))
		"escenario_suelo":  # its floor: flags of stone
			m = Tex.mat("granite_tile_03", Color(0.76, 0.7, 0.62))
		"silla":            # the wheelchair's sign (white on a blue square, drawn behind it)
			var sm := StandardMaterial3D.new()
			sm.albedo_texture = load("res://assets/masahorro/minusvalido.png")
			sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			sm.alpha_scissor_threshold = 0.5
			m = sm
		"foco":
			var lm := StandardMaterial3D.new()
			lm.albedo_color = Color(1.0, 0.97, 0.88)
			lm.emission_enabled = true
			lm.emission = Color(1.0, 0.95, 0.82)
			lm.emission_energy_multiplier = 1.4
			m = lm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	level = 0.0
	transform = Transform3D.IDENTITY
	W.add_child(self)
	_earth()
	_asphalt()
	_kerbs()
	_fountain()
	_pergola()
	_park()
	_square()
	_frames()
	_path_lamps()
	_containers()
	_auditorio()
	_aseos()
	home()
	_commit()

# ---------------- helpers ----------------
func _ccw(p: PackedVector2Array) -> PackedVector2Array:
	if Geometry2D.is_polygon_clockwise(p):
		p.reverse()
	return p

func _facets(box_: Rect2) -> Array:
	var out: Array = []
	var g: float = MapData.rg
	for i in range(int(floor((box_.position.x - MapData.rx0) / g)), int(floor((box_.end.x - MapData.rx0) / g)) + 1):
		for j in range(int(floor((box_.position.y - MapData.rz0) / g)), int(floor((box_.end.y - MapData.rz0) / g)) + 1):
			var a := Vector2(MapData.rx0 + i * g, MapData.rz0 + j * g)
			out.append(_ccw(PackedVector2Array([a, a + Vector2(g, 0), a + Vector2(g, g)])))
			out.append(_ccw(PackedVector2Array([a, a + Vector2(g, g), a + Vector2(0, g)])))
	return out

## a flat piece of this outline (on the map) laid on the ground `lift` over it, cut along the relief's facets
func _lay(poly: PackedVector2Array, lift: float, key) -> void:
	if poly.size() < 3:
		return
	pieces += 1
	var keep := _xf
	home()
	var mp := _ccw(poly.duplicate())
	var bx := Rect2(mp[0], Vector2.ZERO)
	for q in mp:
		bx = bx.expand(q)
	for facet: PackedVector2Array in _facets(bx):
		for piece in Geometry2D.intersect_polygons(mp, facet):
			if piece.size() < 3 or Geometry2D.is_polygon_clockwise(piece):
				continue
			var idx := Geometry2D.triangulate_polygon(piece)
			for t in range(0, idx.size(), 3):
				tri(_p3(piece[idx[t]], lift), _p3(piece[idx[t + 1]], lift), _p3(piece[idx[t + 2]], lift), key, Vector3.UP)
	_xf = keep

func _p3(m: Vector2, lift: float) -> Vector3:
	return Vector3(m.x, MapData.height(m) + lift, m.y)

func _g(p: Vector2) -> float:
	return MapData.height(p)

## the fairground's own paths: the map's unnamed roads with their middles inside it
func _fair_segs() -> Array:
	var out: Array = []
	var fair := PackedVector2Array(FAIR)
	for s in MapData.segs:
		if String(s.road.get("n", "")) != "" or not (int(s.road["k"]) == 0 or int(s.road.get("paved", 0)) == 4):
			continue
		if Geometry2D.is_point_in_polygon((s.a + s.b) / 2.0, fair):
			out.append(s)
	return out

## a kerb along a line on the map: its top 0.12 over the ground, 0.15 wide; left out where it would cross another road
func _kerb_line(a: Vector2, b: Vector2) -> void:
	var L := a.distance_to(b)
	if L < 0.05:
		return
	var d := (b - a) / L
	var n := Vector2(-d.y, d.x) * 0.075
	var k := maxi(1, int(ceil(L / 1.0)))
	for i in range(k):
		var p0 := a.lerp(b, float(i) / k)
		var p1 := a.lerp(b, float(i + 1) / k)
		var mid := (p0 + p1) / 2.0
		if MapData.road_edge_dist(mid) < -0.6:                 # (inside another road's asphalt: a mouth, a crossing)
			continue
		var y0 := _g(p0) + 0.12
		var y1 := _g(p1) + 0.12
		pieces += 1
		quad(Vector3(p0.x - n.x, y0, p0.y - n.y), Vector3(p1.x - n.x, y1, p1.y - n.y), Vector3(p1.x + n.x, y1, p1.y + n.y), Vector3(p0.x + n.x, y0, p0.y + n.y), KERB, Vector3.UP)
		for sg in [-1.0, 1.0]:
			var q0: Vector2 = p0 + n * sg
			var q1: Vector2 = p1 + n * sg
			quad(Vector3(q0.x, y0 - 0.3, q0.y), Vector3(q1.x, y1 - 0.3, q1.y), Vector3(q1.x, y1, q1.y), Vector3(q0.x, y0, q0.y), KERB, Vector3(n.x * sg, 0, n.y * sg).normalized())

# ---------------- the paths and their strips ----------------
## beaten earth over the map's lawns round the paths and over the pavements it laid along them (the real paths have a kerb
## and then the earth: the "aceras amplias" the stalls stand on)
func _earth() -> void:
	for a in MapData.areas:
		var ap: Array = a["p"]
		var pts := PackedVector2Array()
		for i in range(0, ap.size(), 2):
			pts.append(Vector2(ap[i], ap[i + 1]))
		for at in STRIPS_AT:
			if Geometry2D.is_point_in_polygon(at, pts):
				_lay(pts, -0.072, "tierra")
				break
	for s in _fair_segs():
		var d: Vector2 = (s.b - s.a).normalized()
		var hw: float = MapData.fitted_hw(s)
		var u_n := Vector2(-d.y, d.x)
		var e := d * 0.6
		for sg: float in [-1.0, 1.0]:
			var n0: Vector2 = u_n * (sg * hw)
			var n1: Vector2 = u_n * (sg * (hw + 2.2))
			_lay(PackedVector2Array([s.a - e + n0, s.b + e + n0, s.b + e + n1, s.a - e + n1]), -0.072, "tierra")

## The asphalt of its roads closed to traffic (the bake's "paved" 4: the user, 17 Nov 2026, "El recinto ferial sin líneas
## de tráfico. Y tampoco deben circular coches por ahí"): the map lays them as footpaths; this lays their asphalt, with no
## lines and no crossings, each stretch and a round patch at each of its points so that the bends close.
func _asphalt() -> void:
	for r in MapData.roads:
		if int(r.get("paved", 0)) != 4:
			continue
		var p: PackedInt32Array = r["p"]
		var hw: float = float(r["w"]) / 2.0
		for i in range(p.size() - 1):
			var a: Vector2 = MapData.nodes[p[i]]
			var b: Vector2 = MapData.nodes[p[i + 1]]
			if a.distance_to(b) < 0.05:
				continue
			var d := (b - a).normalized()
			var n := Vector2(-d.y, d.x) * hw
			_lay(PackedVector2Array([a - n, b - n, b + n, a + n]), -0.002, "asfalto")
		for i in range(p.size()):
			var c: Vector2 = MapData.nodes[p[i]]
			var disc := PackedVector2Array()
			for k in range(14):
				disc.append(c + Vector2(cos(TAU * k / 14.0), sin(TAU * k / 14.0)) * hw)
			_lay(disc, -0.004, "asfalto")

## the kerbs along both edges of its paths
func _kerbs() -> void:
	for s in _fair_segs():
		var d: Vector2 = (s.b - s.a).normalized()
		var n := Vector2(-d.y, d.x) * (MapData.fitted_hw(s) + 0.075)
		_kerb_line(s.a + n, s.b + n)
		_kerb_line(s.a - n, s.b - n)

# ---------------- the fountain ----------------
## a ring between two radii at height y, facing up
func _annulus(c: Vector3, r0: float, r1: float, n: int, key) -> void:
	pieces += 1
	for i in range(n):
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var u0 := Vector3(cos(a0), 0, sin(a0))
		var u1 := Vector3(cos(a1), 0, sin(a1))
		quad(c + u0 * r0, c + u1 * r0, c + u1 * r1, c + u0 * r1, key, Vector3.UP)

## Water that works (the user, 17 Nov 2026: "Las fuentes funcionan? Creo que ya tenemos un sistema implementado para
## eso"): the plaza's (plaza.gd): its water never still, little waves and rings spreading from the jet, and its jet a
## streaming sheet of water.
func _water(c: Vector2, y: float, ra: float, rb: float, u: Vector2) -> void:
	if _water_shader == null:
		_water_shader = Shader.new()
		_water_shader.code = PlazaS.WATER_SHADER
	var m := ShaderMaterial.new()
	m.shader = _water_shader
	m.set_shader_parameter("centre", c)
	var nn := Vector2(-u.y, u.x)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var k := 40
	for i in range(k):
		var a0 := TAU * i / k
		var a1 := TAU * (i + 1) / k
		var p0 := c + u * cos(a0) * ra + nn * sin(a0) * rb
		var p1 := c + u * cos(a1) * ra + nn * sin(a1) * rb
		for q in [Vector3(c.x, y, c.y), Vector3(p1.x, y, p1.y), Vector3(p0.x, y, p0.y)]:
			st.set_normal(Vector3.UP)
			st.add_vertex(q)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

## a jet of water rising from `foot`, `tall` high: two crossed sheets, wider at the foot
func _jet(foot: Vector3, tall: float, wide: float) -> void:
	if _jet_shader == null:
		_jet_shader = Shader.new()
		_jet_shader.code = PlazaS.JET_SHADER
	var jm := ShaderMaterial.new()
	jm.shader = _jet_shader
	for turn in [0.0, PI / 2.0]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var side := Vector3(cos(turn), 0, sin(turn))
		var top := foot + Vector3(0, tall, 0)
		var corners: Array = [[foot - side * wide, Vector2(0, 0)], [foot + side * wide, Vector2(1, 0)], [top + side * wide * 0.45, Vector2(1, 1)], [top - side * wide * 0.45, Vector2(0, 1)]]
		for q in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3(-side.z, 0, side.x))
			st.set_uv(corners[q][1])
			st.add_vertex(corners[q][0])
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = jm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	jets += 1

## the side of a cylinder from y0 to y1 (over c's height), facing out (or in)
func _side(c: Vector3, r: float, y0: float, y1: float, n: int, key, inward := false) -> void:
	pieces += 1
	for i in range(n):
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var u0 := Vector3(cos(a0), 0, sin(a0))
		var u1 := Vector3(cos(a1), 0, sin(a1))
		var nn := ((u0 + u1) / 2.0).normalized() * (-1.0 if inward else 1.0)
		quad(c + u0 * r + Vector3(0, y0, 0), c + u1 * r + Vector3(0, y0, 0), c + u1 * r + Vector3(0, y1, 0), c + u0 * r + Vector3(0, y1, 0), key, nn)

## The island of the roundabout: a ring of red blocks inside its kerb, the round basin of stone with its iron railing,
## the water, the spout in the middle.
func _fountain() -> void:
	var best = null
	for r in MapData.roads:
		var p: PackedInt32Array = r["p"]
		if p.size() > 6 and p[0] == p[p.size() - 1]:
			var c := Vector2.ZERO
			for i in range(p.size() - 1):
				c += MapData.nodes[p[i]]
			c /= float(p.size() - 1)
			if c.distance_to(FOUNTAIN_NEAR) < 8.0:
				best = [r, c]
	if best == null:
		return
	var road: Dictionary = best[0]
	center = best[1]
	var rmin := 99.0
	var pp: PackedInt32Array = road["p"]
	for i in range(pp.size() - 1):
		rmin = minf(rmin, (MapData.nodes[pp[i]] as Vector2).distance_to(center))
	island_r = rmin - float(road["w"]) / 2.0 - 0.15
	basin_r = island_r * 0.62
	var g := _g(center)
	var c := Vector3(center.x, g, center.y)
	var n := 32
	_side(c, island_r, -0.3, 0.16, n, KERB)                                     # the kerb
	_annulus(c + Vector3(0, 0.16, 0), island_r - 0.22, island_r, n, KERB)
	_annulus(c + Vector3(0, 0.14, 0), basin_r, island_r - 0.22, n, "bloque")    # the red blocks
	_side(c, basin_r, 0.14, 0.62, n, "piedra")                                  # the basin's wall: out, top, in
	_annulus(c + Vector3(0, 0.62, 0), basin_r - 0.28, basin_r, n, "piedra")
	_side(c, basin_r - 0.28, 0.1, 0.62, n, 0x5f9a8c, true)
	_annulus(c + Vector3(0, 0.1, 0), 0.0, basin_r - 0.28, n, 0x4f8a7c)            # its painted bottom
	_water(center, g + 0.42, basin_r - 0.28, basin_r - 0.28, Vector2.RIGHT)        # the water
	var rr := basin_r - 0.14                                                     # the railing on its wall
	for i in range(n):
		var a := TAU * i / n
		var p := c + Vector3(cos(a), 0, sin(a)) * rr
		bar(p + Vector3(0, 0.62, 0), p + Vector3(0, 1.45, 0), 0.025, 0.025, IRON)
	for y in [0.75, 1.42]:
		for i in range(n):
			var a0 := TAU * i / n
			var a1 := TAU * (i + 1) / n
			bar(c + Vector3(cos(a0) * rr, y, sin(a0) * rr), c + Vector3(cos(a1) * rr, y, sin(a1) * rr), 0.03, 0.03, IRON)
	drum(c + Vector3(0, 0.1, 0), 0.32, 0.25, 0.55, "piedra", 12)                  # the spout: a little column, its pipe, the jet
	bar(c + Vector3(0, 0.65, 0), c + Vector3(0, 0.95, 0), 0.06, 0.06, 0x8a7a5a)
	_jet(c + Vector3(0, 0.95, 0), 1.5, 0.09)
	box(center.x + island_r * 0.72 - 0.3, g + 0.15, center.y - 0.3, 0.6, 0.02, 0.6, 0x6a5a3a)   # the lid of its works
	var hull: Array = []                                                         # what stops you: the basin
	for i in range(12):
		var a := TAU * i / 12.0
		for y in [0.0, 1.45]:
			hull.append(Vector3(center.x + cos(a) * basin_r, g + y, center.y + sin(a) * basin_r))
	_hull(hull)
	yard.append(center)

# ---------------- the pergola of ivy ----------------
## a point `s` metres along the street to the north and `out` metres north of its middle
func _north(s: float, out: float) -> Vector2:
	var u := (NORTH_B - NORTH_A).normalized()
	var n := Vector2(u.y, -u.x)
	return NORTH_A + u * s + n * out

## an ivy-grown column at p, `tall` high: its post, the ivy over it in lumps
func _ivy_column(p: Vector2, tall: float, k: int) -> void:
	var g := _g(p)
	box(p.x - 0.2, g, p.y - 0.2, 0.4, tall, 0.4, 0x8a7a64)
	box(p.x - 0.36, g, p.y - 0.36, 0.72, tall + 0.05, 0.72, "hiedra")
	for j in range(4):
		var y: float = 0.35 + j * (tall - 0.4) / 3.0
		var a: float = (k * 1.7 + j * 2.3)
		ball(Vector3(p.x + cos(a) * 0.22, g + y, p.y + sin(a) * 0.22), 0.42, "hiedra", 0.85, 7, 4)
	solid(Vector3(p.x, g + tall / 2.0, p.y), Vector3(0.75, tall, 0.75))
	yard.append(p)

## a beam of ivy from a to b (on the map) at height y: its timber and the ivy over it, lumpy
func _ivy_beam(a: Vector2, b: Vector2, y: float, k: int) -> void:
	var ga := _g(a)
	var gb := _g(b)
	bar(Vector3(a.x, ga + y, a.y), Vector3(b.x, gb + y, b.y), 0.5, 0.42, "hiedra")
	var L := a.distance_to(b)
	var m := maxi(1, int(L / 1.1))
	for i in range(m):
		var t := (i + 0.5) / m
		var p := a.lerp(b, t)
		ball(Vector3(p.x, lerpf(ga, gb, t) + y + 0.12, p.y), 0.38 + 0.08 * ((i + k) % 3), "hiedra", 0.6, 7, 4)

## A covered walk of ivy: two rows of columns (`inner`, `outer`: points on the map, pairwise), beams of ivy along both
## rows and across each pair, an arch of ivy between each two columns of the inner row; its walk paved. `gaps`: the
## stretches (by their first column's index) left open for a way through.
func _pergola_rows(inner: Array, outer: Array, gaps: Array, arches := true) -> void:
	var tall := 2.7
	for i in range(inner.size()):
		_ivy_column(inner[i], tall, i)
		_ivy_column(outer[i], tall, i + 7)
		_ivy_beam(inner[i], outer[i], tall, i)                                  # across, over each pair
	for i in range(inner.size() - 1):
		var a: Vector2 = inner[i]
		var b: Vector2 = inner[i + 1]
		var c: Vector2 = outer[i + 1]
		var d: Vector2 = outer[i]
		_lay(PackedVector2Array([a, b, c, d]), -0.044, "losa")                 # its walk
		if i in gaps:
			continue
		_ivy_beam(a, b, tall, i)                                                # along both rows
		_ivy_beam(d, c, tall, i + 3)
		if not arches:
			continue
		var g := (_g(a) + _g(b)) / 2.0                                          # the arch between two columns: a round head of ivy
		var mid := (a + b) / 2.0
		var half := a.distance_to(b) / 2.0
		var u := (b - a).normalized()
		var steps := 8
		for j in range(steps):
			var t0 := PI * j / steps
			var t1 := PI * (j + 1) / steps
			var p0 := mid - u * cos(t0) * half
			var p1 := mid - u * cos(t1) * half
			bar(Vector3(p0.x, g + tall - 0.7 + sin(t0) * 1.1, p0.y), Vector3(p1.x, g + tall - 0.7 + sin(t1) * 1.1, p1.y), 0.36, 0.36, "hiedra")

## The entrance with the columns and the climbers: the covered walk of ivy along the fairground's street to the north,
## its arches on the street's side (Street View 2013 from that street, 2024 from the Calle de la Huerta)
## Its front runs from the park's west corner nearly to the kiosk; behind it, either side of the little fountain's square,
## the two deep blocks of ivy the bars put their terraces under (the user, 17 Nov 2026, with the park outlined on a
## picture: "faltan dos fragmentos de enredadera abajo (donde hay dos bares con dos terrazas)").
func _col_s(k: int) -> float:                  # the columns along the street: every 3.2 m (k 4 and 5 either side of the main walk)
	return PERGOLA[0] + 3.2 * k

func _pergola() -> void:
	var inner: Array = []
	var outer: Array = []
	for k in range(BLOCK_W[0], BLOCK_E[1] + 1):
		inner.append(_north(_col_s(k), PERGOLA_OUT[0]))
		outer.append(_north(_col_s(k), PERGOLA_OUT[1]))
	_pergola_rows(inner, outer, [4 - BLOCK_W[0]])                             # (open on the main walk)
	for b in [BLOCK_W, BLOCK_E]:
		_ivy_block(b[0], b[1])

## a block of ivy behind the front, from column k0 to k1: two more rows (12 and 15 m in), beams both ways, its floor
## paved; a bar's terrace under it
func _ivy_block(k0: int, k1: int) -> void:
	var tall := 2.7
	var rows := [PERGOLA_OUT[1], 12.0, 15.0]
	for k in range(k0, k1 + 1):
		for j in range(1, rows.size()):
			var p := _north(_col_s(k), rows[j])
			_ivy_column(p, tall, k * 3 + j)
			_ivy_beam(_north(_col_s(k), rows[j - 1]), p, tall, k + j)
	for j in range(1, rows.size()):
		for k in range(k0, k1):
			_ivy_beam(_north(_col_s(k), rows[j]), _north(_col_s(k + 1), rows[j]), tall, k + j * 2)
	_lay(PackedVector2Array([_north(_col_s(k0) - 0.6, PERGOLA_OUT[1]), _north(_col_s(k1) + 0.6, PERGOLA_OUT[1]),
		_north(_col_s(k1) + 0.6, 15.6), _north(_col_s(k0) - 0.6, 15.6)]), -0.044, "losa")
	var mid := _north((_col_s(k0) + _col_s(k1)) / 2.0, 12.0)              # the terrace: tables and chairs (props.gd lays them out)
	W.extra_terrazas.append([mid, (NORTH_B - NORTH_A).normalized()])
	terraces.append(mid)

## The main walk's stretch through the park under the ivy (the user: "el camino empedrado tiene enredadera por encima"):
## a row of ivy columns either side of the setts, from the little fountain's square to the half circle, ivy over it
func _walk_tunnel() -> void:
	var tall := 2.7
	var t0: float = AXIS_X + 20.0
	var t1: float = (_paseo(PASEO_S, PAVEMENT) - AXIS_P).length() - ROUND_R[0] - 0.9
	var side := Vector2(-AXIS_D.y, AXIS_D.x) * TUNNEL_HALF
	var west: Array = []
	var east: Array = []
	var n := maxi(1, int(round((t1 - t0) / 3.2)))
	for i in range(n + 1):
		var c := _axis(lerpf(t0, t1, float(i) / n))
		west.append(c + side)
		east.append(c - side)
	for i in range(west.size()):
		_ivy_column(west[i], tall, i)
		_ivy_column(east[i], tall, i + 5)
		_ivy_beam(west[i], east[i], tall, i)                                     # across, over the walk
	for i in range(west.size() - 1):
		_ivy_beam(west[i], west[i + 1], tall, i)
		_ivy_beam(east[i], east[i + 1], tall, i + 2)
		var m0 := _axis(lerpf(t0, t1, float(i) / n))                           # and over the middle, so that it is covered
		var m1 := _axis(lerpf(t0, t1, float(i + 1) / n))
		_ivy_beam(m0, m1, tall + 0.15, i + 1)

# ---------------- the park by the Paseo del Cristo ----------------
## A point `s` metres along the Paseo del Cristo and `out` metres south of its middle (into the park)
func _paseo(s: float, out: float) -> Vector2:
	var u := (PASEO_B - PASEO_A).normalized()
	return PASEO_A + u * s + Vector2(-u.y, u.x) * out

## ...and along the Calle de la Huerta, from the fairground's corner northwards, `out` metres west of its middle
func _huerta(s: float, out: float) -> Vector2:
	var u := (HUERTA_B - HUERTA_A).normalized()
	return HUERTA_A + u * s + Vector2(u.y, -u.x) * out

## the half circle of the fountain's square, its middle on the Paseo's pavement: a point at angle a (0 along the Paseo
## eastwards, PI westwards, PI / 2 into the park) and radius r
func _round(a: float, r: float) -> Vector2:
	var u := (PASEO_B - PASEO_A).normalized()
	var n := Vector2(-u.y, u.x)
	var c := _paseo(PASEO_S, PAVEMENT)
	return c + u * cos(a) * r + n * sin(a) * r

## The park north of the fairground ("Parque del Recinto Ferial"; the user, 17 Nov 2026: "te faltaría la parte que se ve
## desde Paseo de Cristo"): the square by the Paseo with its oval fountain inside a half circle of the ivy walk; the
## ivy walk along the Calle de la Huerta; behind the walk of the fairground's street, a paved square with the little
## round fountain and its railing; lawns with low hedges, its own trees, the kiosk under the ivy at the corner.
func _park() -> void:
	# the square by the Paseo, paved, and its half circle of ivy (a gap at its back, into the park)
	var sq := PackedVector2Array()
	for k in range(25):
		sq.append(_round(PI * k / 24.0, ROUND_R[0] - 0.3))
	_lay(sq, -0.044, "pavimento")
	var inner: Array = []
	var outer: Array = []
	var n := 20
	for k in range(n + 1):
		if k == n / 2:                                                          # (no column on the main walk: its way through)
			continue
		var a := lerpf(0.14, PI - 0.14, float(k) / n)
		inner.append(_round(a, ROUND_R[0]))
		outer.append(_round(a, ROUND_R[1]))
	_pergola_rows(inner, outer, [n / 2 - 1])
	_oval_fountain()
	_main_walk()
	# the walk along the Calle de la Huerta, its hedge along the pavement
	inner = []
	outer = []
	var s: float = HUERTA_WALK[0]
	while s <= HUERTA_WALK[1] + 0.01:
		inner.append(_huerta(s, 6.0))
		outer.append(_huerta(s, 9.0))
		s += 3.2
	_pergola_rows(inner, outer, [3, 9], false)
	_hedge_line(_huerta(HUERTA_WALK[0], 5.45), _huerta(HUERTA_WALK[1], 5.45), [Vector2(0.3, 0.38), Vector2(0.62, 0.7)])
	# behind the fairground's walk: a paved square with the little fountain
	var sw: float = _col_s(BLOCK_W[1]) + 0.6                                   # (between the two blocks of ivy)
	var se: float = _col_s(BLOCK_E[0]) - 0.6
	_lay(PackedVector2Array([_north(sw, 9.6), _north(se, 9.6), _north(se, 19.0), _north(sw, 19.0)]), -0.044, "pavimento")
	_little_fountain(_axis(AXIS_X + 14.5))
	_walk_tunnel()
	# lawns' hedges, low and clipped: along the north of the little fountain's square (a way through on the main walk)
	# and along the park's west side
	var gap: float = 1.7 / (se - sw)
	_hedge_line(_north(sw, 19.4), _north(se, 19.4), [Vector2(0.5 + (AXIS_S - (sw + se) / 2.0) / (se - sw) - gap, 0.5 + (AXIS_S - (sw + se) / 2.0) / (se - sw) + gap)])
	_hedge_line(Vector2(174.5, 482.0), Vector2(158.5, 525.5), [Vector2(0.45, 0.55)])
	for p in PARK_TREES:
		_tree(p, 8.5 + fmod(p.x * 0.37 + p.y * 0.11, 2.5))
	# the pavements of the Paseo and of the Calle de la Huerta along the park: chequered tiles, red and white, and a kerb
	_lay(PackedVector2Array([_paseo(21.0, 3.9), _paseo(80.0, 3.9), _paseo(80.0, PAVEMENT + 0.05), _paseo(21.0, PAVEMENT + 0.05)]), -0.058, "baldosa")
	_kerb_line(_paseo(21.0, 3.83), _paseo(80.0, 3.83))
	_lay(PackedVector2Array([_huerta(4.0, 3.9), _huerta(64.0, 3.9), _huerta(64.0, PAVEMENT + 0.05), _huerta(4.0, PAVEMENT + 0.05)]), -0.058, "baldosa")
	_kerb_line(_huerta(4.0, 3.83), _huerta(64.0, 3.83))
	for s2 in [30.0, 40.0, 56.0, 66.0]:                                        # the trees in their pits on the Paseo's pavement
		_tree(_paseo(s2, 4.6), 9.0, true)
	_kiosk()

## a point of the main walk, `t` metres from the roundabout's middle towards the Paseo
func _axis(t: float) -> Vector2:
	return AXIS_P + AXIS_D * t

## The park's stretch of the main walk: setts from the fairground's street, through the ivy walk, round the little
## fountain, to the square of the oval one (the user: "camino empedrado")
func _main_walk() -> void:
	var t0: float = AXIS_X + 3.9                                               # (from the street's kerb...)
	var t1: float = AXIS_X + 3.9 + ((_paseo(PASEO_S, PAVEMENT) - _axis(AXIS_X)).length() - ROUND_R[0] - 3.4)      # (...into the oval's square)
	var n := Vector2(-AXIS_D.y, AXIS_D.x) * (AXIS_WALK / 2.0)
	var a := _axis(t0)
	var b := _axis(t1)
	_lay(PackedVector2Array([a - n, b - n, b + n, a + n]), -0.016, "empedrado")
	var lf := _axis(AXIS_X + 14.5)
	var disc := PackedVector2Array()
	for k in range(24):
		disc.append(lf + Vector2(cos(TAU * k / 24.0), sin(TAU * k / 24.0)) * 3.6)
	_lay(disc, -0.016, "empedrado")
	walk_ends = [a, b]

## a low clipped hedge from a to b, with gaps (fractions of its length) for the ways through
func _hedge_line(a: Vector2, b: Vector2, gaps: Array) -> void:
	var L := a.distance_to(b)
	var cuts: Array = [0.0]
	for gp: Vector2 in gaps:
		cuts.append(gp.x)
		cuts.append(gp.y)
	cuts.append(1.0)
	for i in range(0, cuts.size() - 1, 2):
		var p0 := a.lerp(b, cuts[i])
		var p1 := a.lerp(b, cuts[i + 1])
		if p0.distance_to(p1) < 0.3:
			continue
		var g0 := _g(p0)
		var g1 := _g(p1)
		bar(Vector3(p0.x, (g0 + g1) / 2.0 + 0.35, p0.y), Vector3(p1.x, (g0 + g1) / 2.0 + 0.35, p1.y), 0.6, 0.7, "seto")
		yard.append((p0 + p1) / 2.0)
	if L > 0.0:
		pieces += 1

## one of its trees: a trunk, a crown of three lumps (`pit`: in a square of earth in the pavement)
func _tree(at: Vector2, tall: float, pit := false) -> void:
	var y := _g(at)
	var crown := tall * 0.26
	drum(Vector3(at.x, y - 0.3, at.y), 0.26, 0.18, tall * 0.5, 0x6b5a45, 8)
	bar(Vector3(at.x, y + tall * 0.4, at.y), Vector3(at.x + crown * 0.5, y + tall * 0.62, at.y - crown * 0.2), 0.15, 0.15, 0x6b5a45)
	bar(Vector3(at.x, y + tall * 0.4, at.y), Vector3(at.x - crown * 0.45, y + tall * 0.64, at.y + crown * 0.25), 0.15, 0.15, 0x6b5a45)
	ball(Vector3(at.x, y + tall * 0.74, at.y), crown, "hoja", 0.86, 10, 6)
	ball(Vector3(at.x + crown * 0.62, y + tall * 0.62, at.y - crown * 0.3), crown * 0.72, "hoja", 0.86, 9, 5)
	ball(Vector3(at.x - crown * 0.58, y + tall * 0.64, at.y + crown * 0.3), crown * 0.7, "hoja", 0.86, 9, 5)
	if pit:
		cbox(Vector3(at.x, y + 0.015, at.y), Vector3(1.1, 0.04, 1.1), 0x6a5a48)
	solid(Vector3(at.x, y + 1.2, at.y), Vector3(0.5, 2.6, 0.5))
	yard.append(at)

## The oval fountain of the square by the Paseo: a low rim of sandstone, the water inside it
func _oval_fountain() -> void:
	var u := (PASEO_B - PASEO_A).normalized()
	var nn := Vector2(-u.y, u.x)
	var c: Vector2 = _paseo(PASEO_S, PAVEMENT) - AXIS_D * 5.0                    # (on the main walk, as the other two)
	oval_center = c
	var g := _g(c)
	var A := 6.0
	var B := 3.4
	var ring := 0.35
	var tall := 0.5
	var k := 36
	var hull: Array = []
	for i in range(k):
		var a0 := TAU * i / k
		var a1 := TAU * (i + 1) / k
		var o0 := c + u * cos(a0) * A + nn * sin(a0) * B
		var o1 := c + u * cos(a1) * A + nn * sin(a1) * B
		var i0 := c + u * cos(a0) * (A - ring) + nn * sin(a0) * (B - ring)
		var i1 := c + u * cos(a1) * (A - ring) + nn * sin(a1) * (B - ring)
		var out := ((o0 + o1) / 2.0 - c).normalized()
		quad(Vector3(o0.x, g - 0.2, o0.y), Vector3(o1.x, g - 0.2, o1.y), Vector3(o1.x, g + tall, o1.y), Vector3(o0.x, g + tall, o0.y), "arenisca", Vector3(out.x, 0, out.y))
		quad(Vector3(i0.x, g + tall, i0.y), Vector3(i1.x, g + tall, i1.y), Vector3(o1.x, g + tall, o1.y), Vector3(o0.x, g + tall, o0.y), "arenisca", Vector3.UP)
		quad(Vector3(i0.x, g + 0.05, i0.y), Vector3(i1.x, g + 0.05, i1.y), Vector3(i1.x, g + tall, i1.y), Vector3(i0.x, g + tall, i0.y), 0x8aa89a, Vector3(-out.x, 0, -out.y))
		tri(Vector3(c.x, g + 0.05, c.y), Vector3(i0.x, g + 0.05, i0.y), Vector3(i1.x, g + 0.05, i1.y), 0x6f9a8a, Vector3.UP)
		if i % 3 == 0:
			hull.append(Vector3(o0.x, g, o0.y))
			hull.append(Vector3(o0.x, g + 0.9, o0.y))
	pieces += 1
	_water(c, g + 0.36, A - ring, B - ring, u)                                 # its water, and three low jets down its middle
	for s in [-2.6, 0.0, 2.6]:
		var jp: Vector2 = c + u * s
		_jet(Vector3(jp.x, g + 0.36, jp.y), 0.75 if s != 0.0 else 1.2, 0.06)
	_hull(hull)
	yard.append(c)

## the little round fountain behind the fairground's walk: a low wall, the iron railing on it, the water, the spout
func _little_fountain(at: Vector2) -> void:
	little_center = at
	var g := _g(at)
	var c := Vector3(at.x, g, at.y)
	var r := 2.1
	var n := 24
	_side(c, r, -0.2, 0.5, n, "arenisca")
	_annulus(c + Vector3(0, 0.5, 0), r - 0.3, r, n, "arenisca")
	_side(c, r - 0.3, 0.05, 0.5, n, 0x8aa89a, true)
	_annulus(c + Vector3(0, 0.05, 0), 0.0, r - 0.3, n, 0x6f9a8a)
	_water(at, g + 0.34, r - 0.3, r - 0.3, Vector2.RIGHT)
	_jet(c + Vector3(0, 0.5, 0), 1.1, 0.07)
	var rr := r - 0.15
	for i in range(n):
		var a := TAU * i / n
		bar(c + Vector3(cos(a) * rr, 0.5, sin(a) * rr), c + Vector3(cos(a) * rr, 1.15, sin(a) * rr), 0.025, 0.025, IRON)
	for y in [0.62, 1.12]:
		for i in range(n):
			var a0 := TAU * i / n
			var a1 := TAU * (i + 1) / n
			bar(c + Vector3(cos(a0) * rr, y, sin(a0) * rr), c + Vector3(cos(a1) * rr, y, sin(a1) * rr), 0.03, 0.03, IRON)
	drum(c + Vector3(0, 0.05, 0), 0.18, 0.14, 0.45, "arenisca", 10)
	var hull: Array = []
	for i in range(10):
		var a := TAU * i / 10.0
		for y in [0.0, 1.15]:
			hull.append(Vector3(at.x + cos(a) * r, g + y, at.y + sin(a) * r))
	_hull(hull)
	yard.append(at)

## The kiosk at the corner of the fairground's street and the Calle de la Huerta, under the ivy: black, its shutters
## down; the white box of the electricity beside it
func _kiosk() -> void:
	var at: Vector2 = KIOSK
	var u := (NORTH_B - NORTH_A).normalized()
	var n := Vector2(u.y, -u.x)
	var g := _g(at)
	var keep := _xf
	_xf = Transform3D(Basis(Vector3(u.x, 0, u.y), Vector3.UP, Vector3(-n.x, 0, -n.y)), Vector3(at.x, g, at.y))
	box(-1.5, 0.0, -1.1, 3.0, 2.3, 2.2, 0x1e1f21)
	for k in range(14):
		box(-1.4, 0.2 + k * 0.13, 1.1, 2.8, 0.02, 0.012, 0x2c2e31)
	box(-1.7, 2.3, -1.3, 3.4, 0.08, 2.6, 0x1e1f21)
	box(-1.75, 2.38, -1.35, 3.5, 0.5, 2.7, "hiedra")
	for k in range(5):
		ball(Vector3(-1.5 + k * 0.75, 2.75, 0.0), 0.6, "hiedra", 0.6, 7, 4)
	box(-1.7, 0.0, -1.3, 0.35, 2.4, 0.35, "hiedra")
	box(1.35, 0.0, -1.3, 0.35, 2.4, 0.35, "hiedra")
	box(2.4, 0.0, -0.3, 1.3, 1.7, 0.6, 0xe8e8e2)                                    # the electricity's box
	box(2.45, 0.1, 0.3, 1.2, 1.5, 0.01, 0xd8d8d2)
	_xf = keep
	solid(Vector3(at.x, g + 1.2, at.y), Vector3(3.2, 2.4, 2.4), -atan2(u.y, u.x))
	yard.append(at)

# ---------------- the market's square ----------------
func _area(p: PackedVector2Array) -> float:
	var a := 0.0
	for i in range(p.size()):
		a += p[i].cross(p[(i + 1) % p.size()])
	return absf(a) / 2.0

## The square between the roads to the north and the east of the roundabout: chequered tiles from kerb to kerb.
func _square() -> void:
	var loop := PackedVector2Array(PLAZA_LOOP)
	var a0 := _area(loop)
	for delta in [-3.8, 3.8]:
		var res := Geometry2D.offset_polygon(loop, delta, Geometry2D.JOIN_ROUND)
		var best := PackedVector2Array()
		for q: PackedVector2Array in res:
			if q.size() > best.size():
				best = q
		if best.size() >= 3 and _area(best) < a0:
			plaza = best
			break
	if plaza.size() < 3:
		return
	_lay(plaza, -0.058, "baldosa")
	for i in range(plaza.size()):
		_kerb_line(plaza[i], plaza[(i + 1) % plaza.size()])

## The rows of frames of blue steel over it: posts on a grid along the road to the roundabout, beams both ways on top,
## their ends standing out past the last posts.
func _frames() -> void:
	if plaza.size() < 3:
		return
	var inner := PackedVector2Array()
	for q: PackedVector2Array in Geometry2D.offset_polygon(plaza, -1.2):
		if q.size() > inner.size():
			inner = q
	if inner.size() < 3 or _area(inner) > _area(plaza):
		inner = plaza
	var along := (Vector2(167, 575) - Vector2(180, 543)).normalized()
	var across := Vector2(-along.y, along.x)
	if across.x < 0.0:
		across = -across
	var o := Vector2(176.0, 556.0)
	var tall := 3.1
	var grid := {}
	for i in range(0, 7):
		for j in range(-2, 16):
			var p := o + across * (i * 5.0) + along * (j * 4.4)
			if Geometry2D.is_point_in_polygon(p, inner):
				grid[Vector2i(i, j)] = p
	for key: Vector2i in grid:
		var p: Vector2 = grid[key]
		var g := _g(p)
		box(p.x - 0.06, g, p.y - 0.06, 0.12, tall, 0.12, BLUE)
		box(p.x - 0.1, g, p.y - 0.1, 0.2, 0.05, 0.2, 0x5a5d62)
		solid(Vector3(p.x, g + 1.2, p.y), Vector3(0.14, 2.4, 0.14))
		yard.append(p)
		posts += 1
		for nb in [Vector2i(0, 1), Vector2i(1, 0)]:
			var q = grid.get(key + nb)
			var d: Vector2 = along if nb.y == 1 else across
			if q != null:
				bar(Vector3(p.x, g + tall, p.y), Vector3(q.x, _g(q) + tall, q.y), 0.12, 0.12, BLUE)
			elif grid.has(key - nb):                                  # the end of a run: the beam stands out past it
				bar(Vector3(p.x, g + tall, p.y), Vector3(p.x + d.x * 0.45, g + tall, p.y + d.y * 0.45), 0.12, 0.12, BLUE)
			if not grid.has(key - nb) and grid.has(key + nb):
				bar(Vector3(p.x, g + tall, p.y), Vector3(p.x - d.x * 0.45, g + tall, p.y - d.y * 0.45), 0.12, 0.12, BLUE)

# ---------------- lamps and containers ----------------
## Tall lamps along its three long paths, on the strip at one side (the town's: they light at night).
func _path_lamps() -> void:
	for s in _fair_segs():
		var L: float = s.a.distance_to(s.b)
		if L < 50.0:
			continue
		var d: Vector2 = (s.b - s.a) / L
		var n := Vector2(-d.y, d.x)
		if n.x < 0.0:
			n = -n
		var off: float = MapData.fitted_hw(s) + 0.9
		var t := 10.0
		while t < L - 8.0:
			var p: Vector2 = s.a + d * t + n * off
			var g := _g(p)
			drum(Vector3(p.x, g - 0.05, p.y), 0.14, 0.14, 0.4, 0x9a9da0, 8)
			drum(Vector3(p.x, g, p.y), 0.08, 0.05, 8.0, 0x9a9da0, 8)
			var arm := Vector3(-n.x, 0, -n.y) * 1.3                    # over the path
			bar(Vector3(p.x, g + 7.9, p.y), Vector3(p.x, g + 8.25, p.y) + arm * 0.5, 0.06, 0.06, 0x8a8d90)
			bar(Vector3(p.x, g + 8.25, p.y) + arm * 0.5, Vector3(p.x, g + 8.2, p.y) + arm, 0.06, 0.06, 0x8a8d90)
			var head := Vector3(p.x, g + 8.12, p.y) + arm
			cbox(head, Vector3(0.55, 0.14, 0.3), 0x5a5d62)
			cbox(head - Vector3(0, 0.075, 0), Vector3(0.45, 0.01, 0.22), "foco")
			solid(Vector3(p.x, g + 2.0, p.y), Vector3(0.22, 4.0, 0.22))
			W.lamp_spots.append(head - Vector3(0, 0.2, 0))
			lamps.append(head)
			yard.append(p)
			t += 24.0

## Pairs of containers (beige with green lids) on the strips beside the paths, as in the photographs (props.gd stands them)
func _containers() -> void:
	var segs := _fair_segs()
	var long: Array = []
	for s in segs:
		if s.a.distance_to(s.b) >= 50.0:
			long.append(s)
	var picks := [[0, 0.42, -1.0], [1, 0.35, 1.0], [1, 0.62, -1.0], [2, 0.55, 1.0]]
	for q in picks:
		if int(q[0]) >= long.size():
			continue
		var s = long[int(q[0])]
		var d: Vector2 = (s.b - s.a).normalized()
		var n := Vector2(-d.y, d.x) * float(q[2])
		var at: Vector2 = s.a.lerp(s.b, float(q[1])) + n * (MapData.fitted_hw(s) + 1.3)
		for k in range(2):
			var p := at + d * (k * 1.7)
			W.extra_props.append(["container", p, atan2(-n.x, -n.y), 0])
			yard.append(p)

# ---------------- the Auditorio ----------------
## a point of its round corner (t 0 at AUD_SE, 1 at AUD_S)
func _aud_bend(t: float) -> Vector2:
	return AUD_SE.lerp(AUD_BEND, t).lerp(AUD_BEND.lerp(AUD_S, t), t)

## a point of a row of benches `d` metres out from the earth's edge, `deg` degrees round it (0 east, 90 south)
func _aud_row(deg: float, d: float) -> Vector2:
	var a := deg_to_rad(deg)
	return AUD_EARTH + Vector2((AUD_AXES.x + d) * cos(a), (AUD_AXES.y + d) * sin(a))

## how far a spot is from the Auditorio's walls (negative: outside them)
func _aud_room(p: Vector2) -> float:
	var best := 1e9
	for i in range(aud_outline.size()):
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, aud_outline[i], aud_outline[(i + 1) % aud_outline.size()])))
	return best if Geometry2D.is_point_in_polygon(p, aud_outline) else -best

## How far the faces of a wall along these points stand from its line at each point, inwards (the outside is minus it):
## where it turns, along the line halfway between the two stretches' and longer, so that the stretches meet with no gap.
func _miters(pts: Array) -> Array:
	var out: Array = []
	for i in range(pts.size()):
		var ns: Array = []
		if i > 0:
			var d0 := ((pts[i] as Vector2) - (pts[i - 1] as Vector2)).normalized()
			ns.append(Vector2(-d0.y, d0.x))
		if i < pts.size() - 1:
			var d1 := ((pts[i + 1] as Vector2) - (pts[i] as Vector2)).normalized()
			ns.append(Vector2(-d1.y, d1.x))
		var m: Vector2 = ns[0]
		if ns.size() == 2:
			m = ((ns[0] as Vector2) + (ns[1] as Vector2)).normalized()
			m /= maxf(0.4, m.dot(ns[1]))
		out.append(m)
	return out

## A wall along these points (on the map), `tall` over the ground and 0.25 thick, running clockwise round what it shuts in
## (so its outside is on its right): its two faces, its top, its ends, mitred where it turns; a solid for each stretch.
## `ledge`: the seat all along its foot outside (the user, 17 Nov 2026, of the line along the bottom of the Auditorio's
## wall: "en realidad está salida hacia fuera, así la gente se puede sentar ahí"), 0.45 high and 0.4 deep.
func _wall_run(pts: Array, tall: float, key, ledge := false) -> void:
	var half := 0.125
	var seat := 0.45
	var deep := 0.4
	var mit := _miters(pts)
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var L := a.distance_to(b)
		if L < 0.02:
			continue
		var d := (b - a) / L
		var n := Vector2(-d.y, d.x)                                              # inwards
		var ma: Vector2 = mit[i]
		var mb: Vector2 = mit[i + 1]
		var ga := _g(a)
		var gb := _g(b)
		var ia := a + ma * half
		var ib := b + mb * half
		var oa := a - ma * half
		var ob := b - mb * half
		pieces += 1
		quad(Vector3(oa.x, ga - 0.6, oa.y), Vector3(ob.x, gb - 0.6, ob.y), Vector3(ob.x, gb + tall, ob.y), Vector3(oa.x, ga + tall, oa.y), key, Vector3(-n.x, 0, -n.y))
		quad(Vector3(ia.x, ga - 0.6, ia.y), Vector3(ib.x, gb - 0.6, ib.y), Vector3(ib.x, gb + tall, ib.y), Vector3(ia.x, ga + tall, ia.y), key, Vector3(n.x, 0, n.y))
		quad(Vector3(oa.x, ga + tall, oa.y), Vector3(ob.x, gb + tall, ob.y), Vector3(ib.x, gb + tall, ib.y), Vector3(ia.x, ga + tall, ia.y), key, Vector3.UP)
		solid(Vector3((a.x + b.x) / 2.0, (ga + gb) / 2.0 + tall / 2.0 - 0.2, (a.y + b.y) / 2.0), Vector3(L + 0.05, tall + 0.4, 0.3), atan2(-d.y, d.x))
		yard.append((a + b) / 2.0)
		if not ledge:
			continue
		var fa := a - ma * (half + deep)                                         # the seat along its foot: its front, its top
		var fb := b - mb * (half + deep)
		quad(Vector3(fa.x, ga - 0.3, fa.y), Vector3(fb.x, gb - 0.3, fb.y), Vector3(fb.x, gb + seat, fb.y), Vector3(fa.x, ga + seat, fa.y), key, Vector3(-n.x, 0, -n.y))
		quad(Vector3(fa.x, ga + seat, fa.y), Vector3(fb.x, gb + seat, fb.y), Vector3(ob.x, gb + seat, ob.y), Vector3(oa.x, ga + seat, oa.y), key, Vector3.UP)
		var sm := (a + b) / 2.0 - n * (half + deep / 2.0)
		solid(Vector3(sm.x, (ga + gb) / 2.0 + (seat - 0.3) / 2.0, sm.y), Vector3(L + 0.05, seat + 0.3, deep), atan2(-d.y, d.x))
	for e in [[pts[0], pts[1]], [pts[pts.size() - 1], pts[pts.size() - 2]]]:       # its two ends (and the seat's)
		var p: Vector2 = e[0]
		var into := ((e[1] as Vector2) - p).normalized()
		var s := Vector2(-into.y, into.x) * half
		var g := _g(p)
		var face_n := Vector3(-into.x, 0, -into.y)
		quad(Vector3(p.x - s.x, g - 0.6, p.y - s.y), Vector3(p.x + s.x, g - 0.6, p.y + s.y), Vector3(p.x + s.x, g + tall, p.y + s.y), Vector3(p.x - s.x, g + tall, p.y - s.y), key, face_n)
		if ledge:
			var o := Vector2(into.y, -into.x)                                    # (outwards, whichever end this is)
			if e[0] == pts[pts.size() - 1]:
				o = -o
			var q0: Vector2 = p + o * half
			var q1: Vector2 = p + o * (half + deep)
			quad(Vector3(q0.x, g - 0.3, q0.y), Vector3(q1.x, g - 0.3, q1.y), Vector3(q1.x, g + seat, q1.y), Vector3(q0.x, g + seat, q0.y), key, face_n)

## The Auditorio (the user's green): its wall round it, cream, white and taller on the car park's side with the two blue
## signs of the bays for the disabled; the way in, a gap in the wall by the toilets (the user: "solo un hueco en el muro
## por donde pasar"), the green gate folded back against it; its concrete floor; the earth by the west wall where the stage
## is set up; nine rows of low white benches round it in four blocks (traced on the orthophoto, which shows them as
## quarter ellipses round the earth); three wooden poles with floodlights over them. The photographs show its outside
## painted all round: peñas' tags there.
func _auditorio() -> void:
	body = null                                                                  # (a body of its own for its solids: the fairground's has hundreds)
	var bend: Array = []
	for i in range(1, 15):
		bend.append(_aud_bend(i / 14.0))
	aud_outline = PackedVector2Array([AUD_C0, AUD_NE, AUD_SE] + bend + AUD_SW)
	_lay(aud_outline, -0.03, "hormigon")
	_stage()
	# the wall, and its way in
	var gap0: Vector2 = AUD_C0 + AUD_E * AUD_GAP[0]
	var gap1: Vector2 = AUD_C0 + AUD_E * AUD_GAP[1]
	aud_gap = [gap0, gap1]
	_wall_run([gap1, AUD_NE, AUD_SE] + bend + AUD_SW, AUD_TALL, "crema", true)
	var sw_end: Vector2 = AUD_SW[AUD_SW.size() - 1]
	_wall_run([sw_end, AUD_C0], AUD_WEST_TALL, "white")
	var gs := _g(sw_end)
	drum(Vector3(sw_end.x, gs - 0.6, sw_end.y), 0.18, 0.18, AUD_TALL + 0.6, "crema", 8)
	_aud_pavement([AUD_NE, AUD_SE] + bend + AUD_SW)
	# the green gate of the gap, open: folded back against the wall inside
	var gg := _g(gap1)
	var inward := Vector2(-AUD_E.y, AUD_E.x)
	var hinge: Vector2 = gap1 + inward * 0.16
	bar(Vector3(hinge.x, gg + 1.0, hinge.y), Vector3(hinge.x + AUD_E.x * 2.3, gg + 1.0, hinge.y + AUD_E.y * 2.3), 0.04, 1.9, 0x2f7a3e)
	for k in range(6):
		var q: Vector2 = hinge + AUD_E * (0.1 + 0.42 * k) + inward * 0.03
		bar(Vector3(q.x, gg + 0.1, q.y), Vector3(q.x, gg + 1.95, q.y), 0.03, 0.03, 0x24602f)
	# the two signs of the disabled bays on the white wall, to the car park
	var outward := -AUD_E
	for s in [1.55, 5.35]:
		var p: Vector2 = AUD_C0 - AUD_N * s + outward * 0.145                  # (the wall's face is 0.125 out: its blue square clear of it)
		var g := _g(p) + 1.78
		var r := Vector3(-AUD_N.x, 0, -AUD_N.y) * 0.27                       # (to the right of whoever looks at it)
		var up := Vector3(0, 0.27, 0)
		var c := Vector3(p.x, g, p.y)
		var back := Vector3(AUD_E.x, 0, AUD_E.y) * 0.006
		quad(c - r - up + back, c + r - up + back, c + r + up + back, c - r + up + back, 0x2a62b0, Vector3(outward.x, 0, outward.y))
		quad(c - r * 0.82 - up * 0.82, c + r * 0.82 - up * 0.82, c + r * 0.82 + up * 0.82, c - r * 0.82 + up * 0.82, "silla", Vector3(outward.x, 0, outward.y),
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	# graffiti on its outside, as in the photographs: the walls handed to props.gd for the peñas' tags (narrow: the wall is low)
	for w in [[AUD_C0 + AUD_E * 15.0, AUD_C0 + AUD_E * 25.0], [AUD_NE, AUD_SE], [bend[2], bend[5]], [bend[8], bend[11]]]:
		var a: Vector2 = w[0]
		var b: Vector2 = w[1]
		var d := (b - a).normalized()
		var o := Vector2(d.y, -d.x)                                              # (outwards: the walls run clockwise)
		var at: Vector2 = (a + b) / 2.0 + o * 0.125
		W.hand_tags.append([at, o, 1.5, _g(at)])
	_benches()
	_aud_poles()

## The stage (the user, 17 Nov 2026: "la zona que has hecho de tierra y plana, en realidad de piedra también"; Street
## View 2013 over the north wall shows it): a platform a metre high against the west wall, the shape the benches go round,
## its curved front of grey blocks of stone under a coping of granite, its floor of flags of stone; a short flight of
## steps up at its north end, by the way in, so that you can get on to it.
func _stage() -> void:
	var ell := PackedVector2Array()
	for k in range(96):
		ell.append(_aud_row(360.0 * k / 96.0, 0.0))
	for piece: PackedVector2Array in Geometry2D.intersect_polygons(ell, aud_outline):
		if piece.size() > stage.size():
			stage = piece
	if stage.size() < 3:
		return
	# its front: the ellipse where it runs inside the walls, from wall to wall
	var a0 := -60.0
	while _aud_room(_aud_row(a0, 0.0)) <= 0.125 and a0 < 40.0:
		a0 += 1.0
	var a1 := a0
	while _aud_room(_aud_row(a1 + 1.0, 0.0)) > 0.125 and a1 < 170.0:
		a1 += 1.0
	a0 = _stage_end(a0, a0 - 1.0)
	a1 = _stage_end(a1, a1 + 1.0)
	var n := maxi(8, int(ceil((a1 - a0) / 1.5)))
	var front: Array = []
	var gsum := 0.0
	for i in range(n + 1):
		var p := _aud_row(lerpf(a0, a1, float(i) / n), 0.0)
		front.append(p)
		gsum += _g(p)
	var high := -1e9
	for q in stage:
		high = maxf(high, _g(q))
	stage_top = maxf(gsum / (n + 1) + 1.0, high + 0.3)
	var top := stage_top
	# the steps: 1.6 m wide, three risers, straight out from the front a little way from its north end
	var sa := a0 + 5.0
	var sf := _aud_row(sa, 0.0)
	var su := _aud_out(sa)
	stage_climb = [sf + su * 1.4, sf - su * 1.2]
	# the front, its coping, its solids (none before the steps)
	for i in range(n):
		var p: Vector2 = front[i]
		var q: Vector2 = front[i + 1]
		var mid := (p + q) / 2.0
		var o := _aud_out(lerpf(a0, a1, (i + 0.5) / n))
		pieces += 1
		quad(Vector3(p.x, _g(p) - 0.3, p.y), Vector3(q.x, _g(q) - 0.3, q.y), Vector3(q.x, top - 0.09, q.y), Vector3(p.x, top - 0.09, p.y), "escenario_muro", Vector3(o.x, 0, o.y))
		var cp := p + _aud_out(lerpf(a0, a1, float(i) / n)) * 0.04
		var cq := q + _aud_out(lerpf(a0, a1, float(i + 1) / n)) * 0.04
		bar(Vector3(cp.x, top - 0.045, cp.y), Vector3(cq.x, top - 0.045, cq.y), 0.34, 0.1, "granite")
		if mid.distance_to(sf) > 1.0:
			var d := (q - p).normalized()
			solid(Vector3(mid.x - o.x * 0.15, (_g(mid) - 0.3 + top) / 2.0, mid.y - o.y * 0.15), Vector3(p.distance_to(q) + 0.05, top - _g(mid) + 0.3, 0.3), atan2(-d.y, d.x))
	# its floor, a little in from the front so that the coping covers its edge
	flat(stage, top - 0.005, "escenario_suelo")
	stage_mid = _aud_row(30.0, -6.0)
	# the steps: two treads below the floor against the front, a sloping floor over them for whoever walks up (put
	# before the stage's own, as a flight of steps is: MapData.foot takes the first that holds the spot)
	var g0 := _g(sf + su * 0.7)
	var rise := (top - g0) / 3.0
	var al := _aud_along(sa) * 0.85
	MapData.decks.append({"o": sf, "r2": 4.0, "poly": PackedVector2Array([sf - su * 0.05 - al, sf + su * 0.75 - al, sf + su * 0.75 + al, sf - su * 0.05 + al]),
		"top": top, "grad": -su * ((top - g0) / 0.75)})
	MapData.decks.append(_poly_deck(stage, top))
	var keep := _xf
	_xf = Transform3D(Basis(Vector3(su.y, 0, -su.x), Vector3.UP, Vector3(su.x, 0, su.y)), Vector3(sf.x, 0.0, sf.y))
	for k in range(2):                                                           # (the upper one nearer the front)
		box(-0.8, g0 - 0.3, -0.06, 1.6, 0.24 + rise * (2 - k), 0.36 + 0.32 * k, "escenario_muro")
		box(-0.82, g0 + rise * (2 - k) - 0.06, -0.06, 1.64, 0.06, 0.38 + 0.32 * k, "granite")
	_xf = keep
	yard.append(stage_mid)

## the outward direction of the stage's front (and of the rows of benches) at `deg` degrees round it
func _aud_out(deg: float) -> Vector2:
	var a := deg_to_rad(deg)
	return Vector2(cos(a) / AUD_AXES.x, sin(a) / AUD_AXES.y).normalized()

## ...and along it, the way the degrees grow
func _aud_along(deg: float) -> Vector2:
	var o := _aud_out(deg)
	return Vector2(-o.y, o.x)

## where between two angles (inside the walls, outside them) the stage's front meets the wall's face
func _stage_end(inside: float, outside: float) -> float:
	for i in range(18):
		var m := (inside + outside) / 2.0
		if _aud_room(_aud_row(m, 0.0)) > 0.125:
			inside = m
		else:
			outside = m
	return inside

## The pavement of red and white tiles outside its east wall, round its corner and along its south, from the wall to the
## road's kerb (Street View 2013 from the road and the roundabout)
func _aud_pavement(pts: Array) -> void:
	var mit := _miters(pts)
	var wide: Array = []                                                         # how wide it is at each point: as far as the road, 3 m at most
	for i in range(pts.size()):
		var face: Vector2 = (pts[i] as Vector2) - (mit[i] as Vector2) * 0.125
		var rd := MapData.road_edge_dist(face)
		if MapData.road_hit != null:
			rd += MapData.road_hit.hw - MapData.fitted_hw(MapData.road_hit)
		wide.append(clampf(rd, 0.0, 3.0))
	for i in range(pts.size() - 1):
		var wa: float = wide[i]
		var wb: float = wide[i + 1]
		if wa < 0.4 and wb < 0.4:
			continue
		var oa: Vector2 = -(mit[i] as Vector2).normalized()
		var ob: Vector2 = -(mit[i + 1] as Vector2).normalized()
		var fa: Vector2 = (pts[i] as Vector2) - (mit[i] as Vector2) * 0.125
		var fb: Vector2 = (pts[i + 1] as Vector2) - (mit[i + 1] as Vector2) * 0.125
		_lay(PackedVector2Array([fa, fb, fb + ob * wb, fa + oa * wa]), -0.058, "baldosa")
		if wa < 2.95 and wb < 2.95:
			_kerb_line(fa + oa * (wa - 0.075), fb + ob * (wb - 0.075))

## the rows of benches: low blocks of white concrete along each row, broken where a row would come within a metre of the
## wall; a solid every three metres or so
func _benches() -> void:
	for blk in AUD_BLOCKS:
		var a0: float = blk[0]
		var a1: float = blk[1]
		for k in range(AUD_ROWS):
			var d: float = AUD_ROW0 + AUD_ROW_STEP * k
			var arc := 0.0
			for i in range(8):
				arc += _aud_row(lerpf(a0, a1, i / 8.0), d).distance_to(_aud_row(lerpf(a0, a1, (i + 1) / 8.0), d))
			var n := maxi(2, int(ceil(arc / 1.0)))
			var run: Array = []
			for i in range(n + 1):
				var p := _aud_row(lerpf(a0, a1, float(i) / n), d)
				if _aud_room(p) > 1.1:
					run.append(p)
					continue
				if run.size() >= 2:
					_bench(run)
				run = []
			if run.size() >= 2:
				_bench(run)

func _bench(run: Array) -> void:
	for i in range(run.size() - 1):
		var a: Vector2 = run[i]
		var b: Vector2 = run[i + 1]
		bar(Vector3(a.x, _g(a) + 0.22, a.y), Vector3(b.x, _g(b) + 0.22, b.y), 0.4, 0.44, "banco")
	aud_benches += run.size() - 1
	var i := 0
	while i < run.size() - 1:
		var j := mini(i + 3, run.size() - 1)
		var a: Vector2 = run[i]
		var b: Vector2 = run[j]
		var d := (b - a).normalized()
		solid(Vector3((a.x + b.x) / 2.0, (_g(a) + _g(b)) / 2.0 + 0.22, (a.y + b.y) / 2.0), Vector3(a.distance_to(b) + 0.2, 0.44, 0.42), atan2(-d.y, d.x))
		i = j

## its poles: dark wooden posts (where Street View 2013 sees them over the north wall from the street's end: in the
## north-east corner, by the east wall, one among the benches between two rows), two floodlights at the top of each
## turned on the earth
func _aud_poles() -> void:
	for p: Vector2 in [Vector2(167.6, 545.6), Vector2(164.3, 552.0), _aud_row(5.0, AUD_ROW0 + AUD_ROW_STEP * 6.5)]:
		var g := _g(p)
		drum(Vector3(p.x, g - 0.4, p.y), 0.14, 0.1, 8.7, 0x4a3b2e, 8)
		var look: Vector2 = (AUD_EARTH + Vector2(9.0, 9.0) - p).normalized()
		var keep := _xf
		_xf = Transform3D(Basis(Vector3.UP, atan2(look.x, look.y)), Vector3(p.x, g + 7.9, p.y))
		box(-0.6, 0.0, -0.05, 1.2, 0.08, 0.1, 0x3a3c40)                                  # the arm, across
		for x in [-0.45, 0.45]:
			var lamp := Transform3D(Basis(Vector3.RIGHT, 0.5), Vector3(x, -0.05, 0.2))   # (tipped down towards the earth)
			tbox(lamp.scaled_local(Vector3(0.42, 0.3, 0.18)), 0x4a4d52)
			tbox(lamp.translated_local(Vector3(0, 0, 0.095)).scaled_local(Vector3(0.36, 0.24, 0.01)), "foco")
		_xf = keep
		solid(Vector3(p.x, g + 2.0, p.y), Vector3(0.28, 4.0, 0.28))
		W.lamp_spots.append(Vector3(p.x + look.x * 0.4, g + 7.6, p.y + look.y * 0.4))
		aud_poles.append(p)
		yard.append(p)

# ---------------- the public toilets ----------------
## The public toilets at the Auditorio's north-west corner, where the fairground's street to the north ends (the user's
## red): a little house of cream plaster under a hipped roof of tiles with two chimneys; on its side to the street a door,
## three barred windows high up and the double door of wood you go in by (the green arrow: aseos_dentro.gd, a set apart);
## on its side to the car park four windows with their brown shutters down. Its south wall closes the Auditorio there.
func _aseos() -> void:
	var sw := AUD_C0
	var se: Vector2 = AUD_C0 + AUD_E * WC.x
	var ne: Vector2 = se + AUD_N * WC.y
	var nw: Vector2 = AUD_C0 + AUD_N * WC.y
	wc_outline = PackedVector2Array([sw, se, ne, nw])
	var top := -1e9
	var low := 1e9
	for q in wc_outline:
		top = maxf(top, _g(q))
		low = minf(low, _g(q))
	var y0 := top + 0.06                                  # its floor
	var down := low - y0 - 0.5                            # (its walls go into the ground where it falls away)
	var eaves := 2.7
	var wall_top := eaves + 0.15
	# the side to the street (seen from it: x from its south end)
	var dd := Rect2(7.85, 0.0, 1.55, 2.2)
	var holes := [Rect2(1.4, 0.0, 0.9, 2.25), Rect2(3.45, 1.55, 1.0, 0.72), Rect2(5.35, 1.55, 0.95, 0.72), Rect2(6.65, 1.55, 0.95, 0.72), dd]
	face(se, ne, y0)
	masonry(0.0, WC.y, down, wall_top, holes, [], "crema", "crema")
	plinth(0.0, WC.y, 0.3, 0.3, 0xb3aa98, 0.03, down)
	box(1.4, 0.0, -0.14, 0.9, 2.25, 0.05, 0x5a3a24)                                   # the door, its little grille at the top
	box(1.55, 1.75, -0.1, 0.6, 0.32, 0.02, 0x1d1e20)
	grille(Rect2(1.55, 1.75, 0.6, 0.32), -0.08)
	for r: Rect2 in [holes[1], holes[2], holes[3]]:                                  # the three windows behind their bars
		window(r, 0x4a3426)
		grille(r, 0.08)
	var leaf := dd.size.x / 2.0                                                       # the double door: two leaves of planks, a grille over them
	for k in range(2):
		var x0: float = dd.position.x + k * leaf
		box(x0 + 0.01, 0.0, -0.14, leaf - 0.02, 1.85, 0.05, 0x5a3a24)
		for j in range(1, 4):
			box(x0 + leaf * j / 4.0 - 0.01, 0.0, -0.09, 0.02, 1.85, 0.01, 0x3e2818)
	box(dd.position.x, 1.85, -0.2, dd.size.x, 0.35, 0.02, 0x1d1e20)
	grille(Rect2(dd.position.x + 0.05, 1.88, dd.size.x - 0.1, 0.28), -0.08)
	box(dd.position.x + dd.size.x / 2.0 - 0.12, 2.45, 0.0, 0.24, 0.12, 0.1, 0xe8e6e0)   # its lamp
	# the side to the car park (seen from it: x from its north end): four windows, their shutters down
	face(nw, sw, y0)
	var shut := [Rect2(1.3, 1.5, 1.1, 0.77), Rect2(2.8, 1.5, 1.1, 0.77), Rect2(4.5, 1.5, 1.2, 0.77), Rect2(7.4, 1.5, 1.3, 0.77)]
	masonry(0.0, WC.y, down, wall_top, shut, [], "crema", "crema")
	plinth(0.0, WC.y, 0.3, 0.3, 0xb3aa98, 0.03, down)
	for r: Rect2 in shut:
		box(r.position.x, r.position.y, -0.1, r.size.x, r.size.y, 0.04, 0x6b4029)
		for j in range(1, 7):
			box(r.position.x, r.position.y + r.size.y * j / 7.0, -0.06, r.size.x, 0.012, 0.012, 0x4e2e1d)
		box(r.position.x - 0.03, r.position.y - 0.05, 0.0, r.size.x + 0.06, 0.05, 0.06, 0xd8cfb8)
	# its two plain ends
	for f in [[sw, se], [ne, nw]]:
		face(f[0], f[1], y0)
		masonry(0.0, WC.x, down, wall_top, [], [], "crema", "crema")
		plinth(0.0, WC.x, 0.3, 0.3, 0xb3aa98, 0.03, down)
	# the roof, hipped, its ridge north to south; the two chimneys on the side to the street
	_xf = Transform3D(Basis(Vector3(AUD_E.x, 0, AUD_E.y), Vector3.UP, Vector3(-AUD_N.x, 0, -AUD_N.y)), Vector3(AUD_C0.x, y0, AUD_C0.y))
	box(0.0, wall_top - 0.02, -WC.y, WC.x, 0.02, WC.y, "crema")                      # (its ceiling, under the eaves)
	_hip(0.0, WC.x, -WC.y, 0.0, eaves, 1.5, 0.4, WC.y - WC.x)
	for z in [-3.1, -5.35]:
		box(4.45, 3.4, z - 0.25, 0.5, 1.35, 0.5, "crema")
		box(4.37, 4.75, z - 0.33, 0.66, 0.07, 0.66, 0xb3aa98)
		box(4.42, 4.82, z - 0.28, 0.56, 0.16, 0.56, 0xa8623f)
	home()
	_prism(Array(wc_outline), y0 - 1.0, y0 + 4.0)
	MapData.outlines.append(wc_outline)
	yard.append((sw + ne) / 2.0)
	# its inside, through the double door
	var mid: Vector2 = se + AUD_N * (dd.position.x + dd.size.x / 2.0)
	aseos = AseosS.new()
	aseos.build(W, mid + AUD_E * 0.3, mid + AUD_E * 2.2, atan2(AUD_E.x, AUD_E.y))
