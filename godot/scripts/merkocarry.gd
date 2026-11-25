extends "res://scripts/obra.gd"
## The Merkocarry (the user's name for the Merkocash of the Calle de Santa Ana, 17 November 2026: "Este tiene miga
## porque ocupa varias fachadas de las calles Santa Ana, Cristo, Suspiro y Magallanes, pero sin ocupar toda la manzana"):
## the supermarket in the middle of the block, with its narrow front on Santa Ana, the side of its hall on the Cristo
## and its car park's gate, the long side on the Suspiro, and its car park running down to Magallanes. Built by hand
## from Street View (November 2024, along the four streets), the orthophoto (PNOA) and Catastro (4790703VJ5649S: a shop
## of 2001, nine parts of one and two floors). Measured: referencias/merkocarry/LEEME.md, tools/merkocarry/.
##
## Santa Ana: the front of painted brick, blue up to the windows' heads and white over them, the board with the name
## (our own lettering, after its colours), the green strip and a row of badges of no brand, the blue band at the top
## and the railing of the roof behind it; two windows with their posters, the glass doors with their red band, the
## meter box, the lamps on their arms over the board. The Cristo: the hall's wall, a pale stone foot, a blue band, white,
## the blue sheet at the top and the railing; the canopy of blue steel over the service door at the corner, two more
## doors; the gate of the car park between the hall and the pastry cook's, its board ("ENTRADA PARKING"), its lattice
## gates, the tall blue pier with the P. The Suspiro: the long wall, blue, white, blue, its railing; the louvred door;
## the gate of the customers with its board and steps; the low wall of the car park with the wire fence over it.
## Magallanes: the car park's tall blue wall and its fence. The car park: its asphalt, the shelters for the cars along
## its west side and Magallanes and round its corner (blue posts, grey sheet), the bays, the covered walk from the
## customers' gate to the door at the back of the shop, the crossing to it, its lamps. The lane in from the Cristo.
## Behind the glass, the shop, lit while it is open (Monday to Saturday, 9:30 to 21:00; its plate says so too).
##
## Frame: the map's own (x east, z south), y = 0 the shop's floor (the pavement of Santa Ana before its doors). The
## shop stands on Catastro's outline but for two things: its corner on the Cristo by the Mayordomía is cut back a metre
## (the game's street runs nearer than the real one), and the south end of Catastro's part on the Cristo is the lane
## into the car park, open to the sky (the orthophoto, and the gate seen from the Cristo). The nave of the Mayordomía
## del Cristo del Prado (4790711, the plate on its front) is NOT the shop's: it stays as the map has it.

const READY := true                 # (tools/bake_godot.py: Catastro's block is not raised while this is true)
const CarS = preload("res://scripts/car.gd")
const MAKES := ["panda", "panda", "panda", "cuatrolatas", "cuatrolatas", "z15", "z15", "z15", "julietta", "tunero"]
const UNSEEN := 40.0                # cars come and go where you are not looking
const NAME := "Merkocarry"
const DIR := "res://assets/merkocarry/"
const POSTER := "res://assets/chinos/poster_roster.png"         # the user's "Roster Energy" poster: by each way in, at his word
const DentroS = preload("res://scripts/merkocarry_dentro.gd")
const MayordomiaS = preload("res://scripts/mayordomia.gd")
const HOUSE := "stana_60d"          # Texturas's house of its front on Santa Ana (handed over: ["obra"])
const DOWN := -3.0
const OPENS := 9.5                  # its hours (Google's and its own plate: Monday to Saturday 9:30 to 21:00, Sunday shut)
const SHUTS := 21.0

# the shop's outline (Catastro's, but for the corner on the Cristo and the lane), on the map
const SA_E := Vector2(461.41, 158.56)     # the front on Santa Ana: its east end (by the brick house)...
const SA_W := Vector2(445.71, 154.61)     # ...and its west end (by the greengrocer's)
const STRIP_SE := Vector2(459.82, 162.30) # the two floors behind that front: their back corners
const STRIP_SW := Vector2(443.16, 160.15)
const STRIP_B := Vector2(458.80, 164.68)
const STRIP_BW := Vector2(450.62, 162.31)
const E_IN := Vector2(452.57, 179.38)     # the hall: the inner corner behind the houses of Santa Ana...
const NE := Vector2(467.48, 182.94)       # ...its corner on the Suspiro (by the old store of number 4)...
const SE := Vector2(445.05, 222.26)       # ...its other end on the Suspiro, at the car park
const S5 := Vector2(438.05, 218.29)       # its back on the car park: the corners of the recess of the door
const S4 := Vector2(439.06, 216.44)
const S3 := Vector2(434.85, 214.50)
const S2 := Vector2(432.70, 219.09)
const SW := Vector2(420.36, 213.47)       # the back's west end, at the lane
const HL_E := Vector2(421.43, 204.23)     # the hall of the Cristo: its south wall along the lane, east end...
const HL_W := Vector2(401.59, 199.05)     # ...and its corner on the Cristo
const CR_N := Vector2(411.41, 179.03)     # its corner on the Cristo by the Mayordomía (Catastro: 410.35, 178.75)
const CH_E := Vector2(425.90, 182.81)     # where the hall of the Cristo meets the big hall, on the north wall
const N_IN := Vector2(432.01, 184.40)     # the north wall's east end, behind the greengrocer's
const TOP_SA := 7.85                # the front on Santa Ana: the top of its blue band
const TOP_HALL := 5.6               # the big hall (Street View from the Suspiro: blue, white, the blue band, about 6 m over the street)
const TOP_CR := 4.6                 # the hall on the Cristo
# the Cristo, from the corner by the Mayordomía: the hall's wall to 22.3 m, its gate from 22.4 to 29.5, the pier after
const CR_GATE := [22.4, 29.5]
const CR_PIER := [29.5, 30.3]
# the car park (the orthophoto): its shelters' outer edge, from the north end of the west one round to the Suspiro
const PK_WN := Vector2(417.45, 216.05)    # the west shelter's north end, on its back (the corner of the pastry cook's yard)...
const PK_MW := Vector2(404.31, 252.57)    # ...its corner on Magallanes...
const PK_MC := Vector2(421.19, 254.57)    # ...the wall on Magallanes to the corner's cut...
const PK_SC := Vector2(428.40, 251.45)    # ...the cut, to the Suspiro...
const PK_SN := Vector2(435.50, 239.00)    # ...and the shelter along the Suspiro to here
const SHELTER := 5.6                # how deep the shelters are
const SU_GATE := [0.15, 1.75]       # the customers' gate on the Suspiro: metres south of the shop's corner (it is right against it)
const BAY := 2.5
const BLUE := 0x2b56b8
const DARK_BLUE := 0x1d3f8e
const PAINT := 0xf2f2ee
const STEEL := 0x8d9195
const BLACK := 0x1d1e20

var door: Vector2                   # before its doors on Santa Ana, on the map (the self-test, missions)
var back_door: Vector2              # ...and before its door from the car park
var is_open := true
var lamps: Array = []
var outline: PackedVector2Array     # the shop, on the map
var park_poly: PackedVector2Array   # the car park's asphalt, on the map
var bays := 0
var bay_spots: Array = []           # [where the nose goes (map), which way it points (map)]
var parked: Array = []
var _cars_t := 0.0
var _open_nodes: Array = []         # what shows only while open (the gates swung back, the lit rooms)...
var _shut_nodes: Array = []         # ...and only while shut (the gates closed)
var _gate_solids: Array = []        # the shut gates' solids
var tienda                          # its inside (merkocarry_dentro.gd), a set apart: entered by the front doors...
var trasera                         # ...and by the back door (tienda.back): the same set
var mayordomia                      # the Mayordomía's nave beside it on the Cristo (mayordomia.gd), on a map baked with it
var _su_u := Vector2.ZERO           # along the Suspiro, from the shop's corner on it southwards
var _cr_u := Vector2.ZERO           # along the Cristo, from the corner by the Mayordomía southwards

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"blanco":           # painted brick and render: white in the shade too
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.04, 1.04, 1.02)), 0.4)
		"azul":             # the blue paint of its walls
			m = Tex.mat("painted_plaster_wall", Color(0.2, 0.36, 0.78))
		"chapa":            # the blue sheet at the top of its walls, in ribs (a metre to the picture)
			var cm := StandardMaterial3D.new()
			cm.albedo_texture = load(DIR + "chapa.png")
			cm.roughness = 0.5
			cm.metallic = 0.2
			m = cm
		"piedra":           # the pale stone of the feet of its walls
			m = Tex.mat("granular_concrete", Color(0.95, 0.88, 0.76))
		"asfalto":
			m = W._tmat(0x6a686e, "asphalt", 3.0)
		"acera":
			m = W._tmat(0xd2cdc2, "pavement", 2.0)
		"techo":            # the shelters' sheet, grey
			var tm := StandardMaterial3D.new()
			tm.albedo_color = Color(0.74, 0.76, 0.78)
			tm.roughness = 0.45
			tm.metallic = 0.4
			tm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = tm
		"malla", "celosia": # the wire fence; the lattice of the gates (see-through, a metre to the picture)
			var fm := StandardMaterial3D.new()
			fm.albedo_texture = load(DIR + String(key) + ".png")
			fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			fm.alpha_scissor_threshold = 0.5
			fm.cull_mode = BaseMaterial3D.CULL_DISABLED
			fm.roughness = 0.6
			m = fm
		"roster":           # the poster: printed paper, bright in the shade too
			var rm := StandardMaterial3D.new()
			rm.albedo_texture = Parts.texture(POSTER)
			rm.roughness = 1.0
			m = _glow(rm, 0.3)
		"cristal":
			var gm := StandardMaterial3D.new()
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.albedo_color = Color(0.3, 0.36, 0.38, 0.42)
			gm.roughness = 0.3
			gm.metallic_specular = 0.35
			gm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = gm
		"sala":             # the shop behind the glass: lit while it is open
			var sm := StandardMaterial3D.new()
			sm.albedo_color = Color(0.86, 0.86, 0.84)
			sm.emission_enabled = true
			sm.emission = Color(0.96, 0.95, 0.9)
			sm.emission_energy_multiplier = 0.3
			m = sm
		"luz", "foco":
			var lm := StandardMaterial3D.new()
			lm.albedo_color = Color(1.0, 0.98, 0.93)
			lm.emission_enabled = true
			lm.emission = Color(1.0, 0.97, 0.9)
			lm.emission_energy_multiplier = 1.4
			m = lm
		"rotulo", "logo", "cartel_iva", "cartel_hora", "entrada", "parking", "clientes", "p_flecha":
			var pm := StandardMaterial3D.new()
			pm.albedo_texture = load(DIR + String(key) + ".png")
			pm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			pm.roughness = 0.55
			m = pm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	level = MapData.height((SA_E + SA_W) / 2.0 + Vector2(0.244, -0.97) * 1.0) + 0.12
	transform = Transform3D(Basis.IDENTITY, Vector3(0, level, 0))
	W.add_child(self)
	_su_u = (SE - NE).normalized()
	_cr_u = (HL_W - CR_N).normalized()
	outline = PackedVector2Array([SA_W, SA_E, STRIP_SE, E_IN, NE, SE, S5, S4, S3, S2, SW, HL_E, HL_W, CR_N, N_IN])
	door = (SA_E + SA_W) / 2.0 + Vector2(0.244, -0.97) * 1.6 + (SA_W - SA_E).normalized() * 5.6
	back_door = (S3 + S4) / 2.0 + Vector2(-0.419, 0.908) * 2.5
	_santa_ana()
	_inside_front()
	_cristo()
	_cristo_gate()
	_suspiro()
	_backs()
	_back_door()
	_roofs()
	_park()
	_park_walls()
	_shelters()
	_walkway()
	_lane()
	_park_lamps()
	home()
	_commit()
	_solids_of_shop()
	_tell_map()
	_build_inside()
	if bool(MapData.merkocarry.get("nave", false)):    # the Mayordomía's nave beside it (the user: "es otro edificio distinto")
		mayordomia = MayordomiaS.new()
		mayordomia.build(W)
	set_open(open_at(0, 12.0))

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
	return Vector3(m.x, MapData.height(m) - level + lift, m.y)

## a painted line (or any strip) on the ground, from a to b (on the map), w wide
func _strip(a: Vector2, b: Vector2, w: float, lift: float, key) -> void:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x) * w / 2.0
	_lay(PackedVector2Array([a - n, b - n, b + n, a + n]), lift, key)

## the ground under a stretch, its lowest and its highest
func _low(a: Vector2, b: Vector2) -> float:
	var y := 1e9
	for k in range(9):
		var q := a.lerp(b, k / 8.0)
		y = minf(y, ground(q.x, q.y))
	return y

func _high(a: Vector2, b: Vector2) -> float:
	var y := -1e9
	for k in range(9):
		var q := a.lerp(b, k / 8.0)
		y = maxf(y, ground(q.x, q.y))
	return y

## a flat picture standing on the plane z of the frame being built (x0..x1, y0..y1), facing +z
func _picture(x0: float, x1: float, y0: float, y1: float, z: float, key) -> void:
	pieces += 1
	quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

## The user's "Roster Energy" poster (the one of the chinos', flat: tools/chinos/poster.py), stuck on the wall being built
## a little askew, its middle at (x, y), `z` out of it (the user, 17 Nov 2026: "Pega un póster de Roster Energy cerca de
## cada entrada")
func _roster(x: float, y: float, z: float, tilt: float) -> void:
	if Parts.texture(POSTER) == null:
		return
	var keep := _xf
	_xf = _xf * Transform3D(Basis(Vector3.BACK, tilt), Vector3(x, y, z))
	_picture(-0.27, 0.27, -0.36, 0.36, 0.0, "roster")
	_xf = keep

## a stretch of a texture that repeats a metre to the picture (the ribbed sheet, the wire, the lattice), facing +z
func _tiled(x0: float, x1: float, y0: float, y1: float, z: float, key) -> void:
	pieces += 1
	quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1),
		[Vector2(x0, -y0), Vector2(x1, -y0), Vector2(x1, -y1), Vector2(x0, -y1)])

## A wall on the plane z = 0 of the frame being built, from 0 to ln, in horizontal bands [[y0, y1, key], ...], with
## holes (Rect2) left open: each hole's sides `deep` back, in the colour of the band they cross.
func _banded(ln: float, bands: Array, holes: Array, deep := 0.25) -> void:
	for bd in bands:
		var y0: float = bd[0]
		var y1: float = bd[1]
		var xs: Array = [0.0, ln]
		var ys: Array = [y0, y1]
		for r: Rect2 in holes:
			for v in [r.position.x, r.end.x]:
				if v > 0.001 and v < ln - 0.001:
					xs.append(v)
			for v in [r.position.y, r.end.y]:
				if v > y0 + 0.001 and v < y1 - 0.001:
					ys.append(v)
		xs.sort()
		ys.sort()
		for j in range(ys.size() - 1):
			var run_from := -1.0
			for i in range(xs.size()):
				var solid_here := false
				if i < xs.size() - 1:
					var c := Vector2((xs[i] + xs[i + 1]) / 2.0, (ys[j] + ys[j + 1]) / 2.0)
					solid_here = true
					for r: Rect2 in holes:
						if r.has_point(c):
							solid_here = false
							break
				if solid_here and run_from < 0.0:
					run_from = xs[i]
				elif not solid_here and run_from >= 0.0:
					if xs[i] - run_from > 0.0005 and ys[j + 1] - ys[j] > 0.0005:
						pieces += 1
						quad(Vector3(run_from, ys[j], 0), Vector3(xs[i], ys[j], 0), Vector3(xs[i], ys[j + 1], 0), Vector3(run_from, ys[j + 1], 0), bd[2], Vector3(0, 0, 1))
					run_from = -1.0
		for r: Rect2 in holes:
			var lo := maxf(r.position.y, y0)
			var hi := minf(r.end.y, y1)
			if hi <= lo or r.position.x < -0.001 or r.end.x > ln + 0.001:
				continue
			quad(Vector3(r.position.x, lo, -deep), Vector3(r.position.x, lo, 0), Vector3(r.position.x, hi, 0), Vector3(r.position.x, hi, -deep), bd[2], Vector3(1, 0, 0))
			quad(Vector3(r.end.x, lo, -deep), Vector3(r.end.x, lo, 0), Vector3(r.end.x, hi, 0), Vector3(r.end.x, hi, -deep), bd[2], Vector3(-1, 0, 0))
			if r.end.y > y0 + 0.001 and r.end.y <= y1 + 0.001:
				quad(Vector3(r.position.x, r.end.y, -deep), Vector3(r.end.x, r.end.y, -deep), Vector3(r.end.x, r.end.y, 0), Vector3(r.position.x, r.end.y, 0), bd[2], Vector3(0, -1, 0))
			if r.position.y >= y0 - 0.001 and r.position.y < y1 - 0.001 and r.position.y > DOWN + 0.5:
				quad(Vector3(r.position.x, r.position.y, -deep), Vector3(r.end.x, r.position.y, -deep), Vector3(r.end.x, r.position.y, 0), Vector3(r.position.x, r.position.y, 0), bd[2], Vector3(0, 1, 0))

## a railing on the roof's edge, `back` behind the wall's face, from 0 to ln, its top `tall` over y
func _railing(ln: float, y: float, back: float, tall := 1.0, hex := DARK_BLUE) -> void:
	bar(Vector3(0.0, y + tall, -back), Vector3(ln, y + tall, -back), 0.05, 0.05, hex)
	bar(Vector3(0.0, y + tall * 0.5, -back), Vector3(ln, y + tall * 0.5, -back), 0.035, 0.035, hex)
	var x := 0.0
	while x <= ln + 0.01:
		bar(Vector3(x, y, -back), Vector3(x, y + tall, -back), 0.045, 0.045, hex)
		x += 1.9

## the blue sheet in ribs at the top of a wall (from y0 to y1), standing `proud` out of it, with its edges
func _sheet(ln: float, y0: float, y1: float, proud := 0.04) -> void:
	_tiled(0.0, ln, y0, y1, proud, "chapa")
	box(0.0, y1, -0.3, ln, 0.06, 0.3 + proud + 0.02, 0xdfe3e8)            # its coping
	box(0.0, y0 - 0.03, 0.0, ln, 0.05, proud + 0.02, DARK_BLUE)

## everything built so far goes into its own node (shown only while open, or only while shut)
func _commit_to(list: Array) -> void:
	var node := Node3D.new()
	add_child(node)
	for key in _tools:
		var mi := MeshInstance3D.new()
		mi.mesh = (_tools[key] as SurfaceTool).commit()
		mi.material_override = _material(key)
		node.add_child(mi)
	_tools.clear()
	list.append(node)

## a point on the Suspiro's line (t metres south of the shop's corner on it), on the Cristo's (s south of the corner
## by the Mayordomía)
func _su(t: float) -> Vector2:
	return SE + _su_u * t

func _cr(s: float) -> Vector2:
	return CR_N + _cr_u * s

# ---------------- Santa Ana ----------------
const SA_WIN := [[1.25, 4.86], [5.92, 9.82]]   # its windows (metres from the east end), 1.4 to 3.42 m up
const SA_DOOR := [11.67, 15.44]                # the glass doors, to 3.17 m
const SA_BOARD := [4.6, 7.1]                   # the board with the name

## The front on Santa Ana, from its east end (the left, as seen from the street).
func _santa_ana() -> void:
	var ln := face(SA_E, SA_W)
	var holes: Array = [Rect2(SA_WIN[0][0], 1.4, SA_WIN[0][1] - SA_WIN[0][0], 2.02), Rect2(SA_WIN[1][0], 1.4, SA_WIN[1][1] - SA_WIN[1][0], 2.02),
		Rect2(SA_DOOR[0], DOWN, SA_DOOR[1] - SA_DOOR[0], 3.17 - DOWN)]
	_banded(ln, [[DOWN, 3.5, "azul"], [3.5, SA_BOARD[0], "blanco"], [SA_BOARD[0], SA_BOARD[1], "azul"], [SA_BOARD[1], TOP_SA, "azul"]], holes, 0.3)
	# the board: the name, the strip, the badges, a little proud, with the blue round it
	box(0.0, SA_BOARD[0] - 0.02, 0.0, ln, SA_BOARD[1] - SA_BOARD[0] + 0.04, 0.1, "azul")
	_picture(0.3, ln - 0.3, SA_BOARD[0], SA_BOARD[1], 0.105, "rotulo")
	box(0.0, SA_BOARD[1], 0.0, ln, TOP_SA - SA_BOARD[1], 0.16, "azul")                      # the blue band at the top
	box(-0.02, TOP_SA - 0.04, -0.02, ln + 0.04, 0.05, 0.2, 0xdfe3e8)
	_railing(ln, TOP_SA, 0.7)
	for x in [2.4, 6.3, 10.2, 14.1]:                                                     # the lamps on their arms over the board
		bar(Vector3(x, SA_BOARD[1] + 0.35, 0.16), Vector3(x, SA_BOARD[1] + 0.55, 0.95), 0.04, 0.04, 0x3a3c3f)
		cbox(Vector3(x, SA_BOARD[1] + 0.5, 1.0), Vector3(0.3, 0.14, 0.22), 0x3a3c3f)
		box(x - 0.12, SA_BOARD[1] + 0.42, 0.9, 0.24, 0.01, 0.18, "foco")
	# the windows: white frames, the glass, the posters behind
	for i in range(2):
		var x0: float = SA_WIN[i][0]
		var x1: float = SA_WIN[i][1]
		_picture(x0 + 0.08, x1 - 0.08, 1.48, 3.34, -0.22, "cartel_iva" if i == 0 else "cartel_hora")
		_picture(x0, x1, 1.4, 3.42, -0.12, "cristal")
		for e in [[x0, 1.4, 0.07, 2.02], [x1 - 0.07, 1.4, 0.07, 2.02], [x0, 1.4, x1 - x0, 0.07], [x0, 3.35, x1 - x0, 0.07]]:
			box(e[0], e[1], -0.14, e[2], e[3], 0.06, 0xf4f4f0)
		box(x0 - 0.04, 1.32, -0.3, x1 - x0 + 0.08, 0.08, 0.36, 0xe6e6e2)                  # the sill
	# the glass doors: a frame of aluminium, two fixed panes and two leaves, the red band, the transom, notices
	var d0: float = SA_DOOR[0]
	var d1: float = SA_DOOR[1]
	var dz := -0.3
	_picture(d0, d1, -0.12, 3.17, dz, "cristal")
	for x in [d0, d0 + 0.85, (d0 + d1) / 2.0 - 0.03, d1 - 0.85 - 0.06, d1 - 0.06]:
		box(x, -0.12, dz - 0.04, 0.06, 3.29, 0.08, 0x9a9da0)
	box(d0, 2.4, dz - 0.05, d1 - d0, 0.08, 0.1, 0x9a9da0)
	box(d0, 3.09, dz - 0.05, d1 - d0, 0.08, 0.1, 0x6a6d70)
	_picture(d0 + 0.06, d1 - 0.06, 1.5, 1.72, dz + 0.01, "entrada")
	for p in [[d0 + 0.15, 0.4, 0.5, 0.7, 0xe8322a], [d0 + 0.2, 1.85, 0.45, 0.4, 0xf2e6a0], [d1 - 0.65, 0.5, 0.45, 0.65, 0xf4f4f0], [d1 - 0.62, 1.85, 0.4, 0.45, 0xe8a030]]:
		box(p[0], p[1], dz + 0.012, p[2], p[3], 0.004, p[4])
	_lay_front_step(d0, d1)
	_roster(11.04, 1.95, 0.004, 0.04)                                                   # the Roster poster between the meter box and the doors (the user, 17 Nov 2026)
	box(10.57, 0.25, 0.0, 0.84, 1.05, 0.18, 0xa8a8a4)                                   # the meter box
	box(10.6, 0.28, 0.18, 0.78, 0.99, 0.006, 0xbcbcb8)
	home()

## the threshold before the glass doors, level with the floor
func _lay_front_step(d0: float, d1: float) -> void:
	box(d0, -0.4, -0.3, d1 - d0, 0.4, 0.62, 0xb8b4aa)

## The shop behind its glass on Santa Ana: its floor, its ceiling and lights, the shelves in rows, the tills by the
## door, the posters' backs; lit while it is open.
func _inside_front() -> void:
	face(SA_E, SA_W)
	var ln := 16.19
	box(0.4, -0.02, -7.5, ln - 0.8, 0.02, 7.2, 0xd8d6d0)
	box(0.4, 3.4, -7.5, ln - 0.8, 0.04, 7.2, "sala")
	box(0.4, 0.0, -7.55, ln - 0.8, 3.4, 0.05, "sala")
	box(0.35, 0.0, -7.5, 0.05, 3.4, 7.2, "sala")
	box(ln - 0.4, 0.0, -7.5, 0.05, 3.4, 7.2, "sala")
	for x in [2.5, 6.5, 10.5, 14.0]:
		box(x - 0.5, 3.36, -4.5, 1.0, 0.04, 0.3, "luz")
	for k in range(4):                                                                   # the shelves, end on to the windows
		var x: float = 1.4 + k * 2.4
		box(x, 0.0, -7.2, 0.9, 1.8, 4.6, 0xe6e6e2)
		for j in range(4):
			box(x - 0.02, 0.2 + j * 0.42, -7.1, 0.94, 0.28, 4.4, [0xe8322a, 0x2a82d8, 0xf2c230, 0x3a9a4a, 0xf4f4f0][(k + j) % 5])
	for x in [11.2, 13.0]:                                                               # the tills
		box(x, 0.0, -2.6, 1.4, 0.9, 0.6, 0x3a3d40)
		box(x + 0.2, 0.9, -2.5, 0.4, 0.3, 0.05, 0x26262a)
	home()

# ---------------- the Cristo ----------------
## The hall's wall on the Cristo, from its corner by the Mayordomía (the left, as seen from the street): a pale stone
## foot, a blue band, white, the blue sheet at the top and the railing; the canopy over the service door at the corner,
## the double door, the door by the gate; signs of no parking.
func _cristo() -> void:
	var ln := face(CR_N, HL_W)
	var g: float = _high(CR_N, HL_W)
	var top: float = g + TOP_CR
	var holes: Array = [Rect2(1.8, DOWN, 1.0, g + 2.2 - DOWN), Rect2(15.6, DOWN, 1.4, g + 2.3 - DOWN), Rect2(20.6, DOWN, 1.1, g + 2.2 - DOWN)]
	_banded(ln, [[DOWN, g + 0.8, "piedra"], [g + 0.8, g + 1.5, "azul"], [g + 1.5, g + 3.3, "blanco"], [g + 3.3, top, "azul"]], holes, 0.12)
	_sheet(ln, g + 3.3, top)
	_railing(ln, top + 0.06, 0.4)
	for h in holes:                                                                    # the doors: blue sheet
		var r: Rect2 = h
		box(r.position.x, r.position.y, -0.12, r.size.x, r.size.y, 0.04, BLUE)
		if r.size.x > 1.2:
			box(r.position.x + r.size.x / 2.0 - 0.02, g, -0.08, 0.04, 2.3, 0.01, DARK_BLUE)
		box(r.position.x + r.size.x - 0.2, g + 1.0, -0.08, 0.06, 0.15, 0.06, 0xc9ccd0)
	# the canopy of blue steel over the service door at the corner
	var cy: float = g + 3.75
	box(0.0, cy, 0.0, 4.4, 0.12, 0.2, BLUE)
	quad(Vector3(0.0, cy, 0.0), Vector3(4.4, cy, 0.0), Vector3(4.4, cy - 0.35, 1.9), Vector3(0.0, cy - 0.35, 1.9), "techo", Vector3(0, 1, 0.18))
	box(0.0, cy - 0.5, 1.85, 4.4, 0.22, 0.08, BLUE)
	for x in [0.05, 4.3]:
		box(x, cy - 0.45, 0.0, 0.05, 0.05, 1.9, BLUE)
		bar(Vector3(x, cy - 1.2, 0.02), Vector3(x, cy - 0.4, 1.8), 0.04, 0.04, DARK_BLUE)
	for x in [3.6, 14.6, 19.6]:                                                         # no parking before the doors
		_no_parking(Vector3(x, g + 2.0, 0.02))
	home()

## a round sign of no parking flat on a wall: red ring, blue disc, the red stroke across
func _no_parking(at: Vector3) -> void:
	var keep := _xf
	_xf = keep * Transform3D(Basis(Vector3.RIGHT, PI / 2.0), at)
	drum(Vector3.ZERO, 0.16, 0.16, 0.012, 0xd8243a, 16)
	drum(Vector3(0, 0.012, 0), 0.12, 0.12, 0.004, 0x2a64c8, 16)
	_xf = keep
	bar(at + Vector3(-0.085, 0.085, 0.018), at + Vector3(0.085, -0.085, 0.018), 0.035, 0.004, 0xd8243a)

## The gate of the car park on the Cristo, between the hall and the pastry cook's: its board across the top, the lattice
## gates (swung back while it is open, shut across it at night), the tall blue pier with the P.
func _cristo_gate() -> void:
	var a := _cr(CR_GATE[0] - 0.1)
	var b := _cr(CR_PIER[1])
	var ln := face(a, b)
	var g: float = _low(a, b)
	var gw: float = CR_GATE[1] - CR_GATE[0]
	# the pier: blue over a white foot, the P at its top, facing the street
	var px0: float = CR_PIER[0] - CR_GATE[0] + 0.1
	box(px0, DOWN, -0.8, 0.8, g + 1.2 - DOWN, 0.8, "blanco")
	box(px0, g + 1.2, -0.8, 0.8, 4.6, 0.8, BLUE)
	box(px0 - 0.02, g + 5.8, -0.82, 0.84, 0.06, 0.84, 0xdfe3e8)
	_picture(px0 + 0.04, px0 + 0.76, g + 4.6, g + 5.32, 0.005, "p_flecha")
	_roster(px0 + 0.4, g + 2.0, 0.006, -0.03)                                           # the Roster poster on the pier, by the way in
	solid(Vector3(px0 + 0.4, g + 2.5, -0.4), Vector3(0.8, 6.0, 0.8))
	yard.append(_cr(CR_PIER[0] + 0.4))
	# the board across the top
	box(0.1, g + 3.55, -0.1, gw, 0.75, 0.12, DARK_BLUE)
	_picture(0.1, 0.1 + gw, g + 3.55, g + 4.3, 0.025, "parking")
	_commit()                                                                           # (what stands whatever the hour)
	# the gates, two leaves of blue lattice: shut across the opening (built now into the "shut" node)...
	var lw: float = gw / 2.0
	_gate_leaves(Vector3(0.1, g, -0.35), Vector3(1, 0, 0), lw, 2.3)
	_gate_leaves(Vector3(0.1 + gw, g, -0.35), Vector3(-1, 0, 0), lw, 2.3)
	_commit_to(_shut_nodes)
	# ...and swung back against the lane's walls (the "open" one)
	_gate_leaves(Vector3(0.1, g, -0.35), Vector3(0, 0, -1), lw, 2.3)
	_gate_leaves(Vector3(0.1 + gw, g, -0.35), Vector3(0, 0, -1), lw, 2.3)
	_commit_to(_open_nodes)
	var cs := CollisionShape3D.new()                                                    # the shut gates' solid
	var bs := BoxShape3D.new()
	bs.size = Vector3(gw, 2.3, 0.2)
	cs.shape = bs
	cs.transform = transform * _xf * Transform3D(Basis.IDENTITY, Vector3(0.1 + gw / 2.0, g + 1.15, -0.35))
	_solids().add_child(cs)
	_gate_solids.append(cs)
	home()

## one leaf of a gate of blue lattice, hung at `hinge`, running `dir` for `w`, `h` tall: its frame and its lattice
func _gate_leaves(hinge: Vector3, dir: Vector3, w: float, h: float) -> void:
	var keep := _xf
	var side := Vector3.UP.cross(dir)
	_xf = _xf * Transform3D(Basis(dir, Vector3.UP, -side), hinge)
	_tiled(0.05, w - 0.05, 0.08, h - 0.05, 0.0, "celosia")
	for e in [[0.0, 0.0, 0.06, h], [w - 0.06, 0.0, 0.06, h], [0.0, h - 0.06, w, 0.06], [0.0, 0.04, w, 0.06], [0.0, h * 0.5, w, 0.05]]:
		box(e[0], e[1], -0.03, e[2], e[3], 0.06, BLUE)
	_xf = keep

# ---------------- the Suspiro ----------------
## The long side on the Suspiro, from its south end at the car park (the left, as seen from the street): blue, white,
## the blue sheet and the railing; the louvred door in its frame of pink stone.
func _suspiro() -> void:
	var ln := face(SE, NE)
	var g: float = _high(SE, NE)
	var holes: Array = [Rect2(5.3, DOWN, 1.5, ground(_su(-6.0).x, _su(-6.0).y) + 2.3 - DOWN)]
	_banded(ln, [[DOWN, 2.4, "azul"], [2.4, 4.4, "blanco"], [4.4, TOP_HALL, "azul"]], holes, 0.12)
	_sheet(ln, 4.4, TOP_HALL)
	_railing(ln, TOP_HALL + 0.06, 0.4)
	var r: Rect2 = holes[0]
	var dg: float = ground(_su(-6.0).x, _su(-6.0).y)
	for k in range(int((2.2) / 0.09)):                                                  # the louvres
		box(r.position.x, dg + 0.08 + k * 0.09, -0.1, r.size.x, 0.05, 0.03, BLUE)
	box(r.position.x + 0.73, dg, -0.11, 0.04, 2.2, 0.04, DARK_BLUE)
	stone_frame(Rect2(r.position.x, dg, r.size.x, 2.3), 0.16, 0.04, 0xd8a890)
	box(r.position.x + 1.9, dg + 1.5, 0.01, 0.16, 0.2, 0.01, 0xf2d040)                  # the camera's sticker
	box(r.position.x + 0.5, dg + 1.6, -0.075, 0.32, 0.12, 0.005, 0xc9ccd0)
	var cg: float = ground(_su(-0.5).x, _su(-0.5).y)
	_roster(0.55, cg + 1.65, 0.004, -0.04)                                              # the Roster poster on the corner, beside the customers' gate
	home()

# ---------------- the backs ----------------
## The faces that give on to the car park and the lane, and the walls over the neighbours' roofs: white over a blue
## foot, the blue sheet at the top; on the car park's side the board with the name again, and posters.
func _backs() -> void:
	var pg: float = _high(SW, SE)
	for f in [[SW, S2], [S2, S3], [S4, S5], [S5, SE], [HL_E, SW]]:
		var a: Vector2 = f[0]
		var b: Vector2 = f[1]
		var ln := face(a, b)
		_banded(ln, [[DOWN, pg + 1.0, "azul"], [pg + 1.0, 3.0, "blanco"], [3.0, TOP_HALL, "azul"]], [])
		_sheet(ln, 3.0, TOP_HALL)
		if a == SW:
			box(2.6, 3.95, 0.0, 8.4, 1.45, 0.1, "azul")
			_picture(2.7, 10.9, 4.0, 5.35, 0.105, "rotulo")
			_picture(0.8, 4.4, pg + 1.15, pg + 2.75, 0.01, "cartel_iva")
			_picture(9.2, 12.8, pg + 1.15, pg + 2.75, 0.01, "cartel_hora")
		elif a == S5:
			_picture(2.2, 5.8, pg + 1.15, pg + 2.75, 0.01, "cartel_hora")
	# the hall of the Cristo's wall along the lane: as on the street
	var lg: float = _high(HL_W, HL_E)
	var ln2 := face(HL_W, HL_E)
	var top: float = _high(CR_N, HL_W) + TOP_CR
	_banded(ln2, [[DOWN, lg + 0.8, "piedra"], [lg + 0.8, lg + 1.5, "azul"], [lg + 1.5, lg + 3.3, "blanco"], [lg + 3.3, top, "azul"]], [Rect2(8.0, DOWN, 2.4, lg + 2.6 - DOWN)], 0.12)
	box(8.0, lg, -0.1, 2.4, 2.6, 0.04, BLUE)                                             # the loading door into the hall
	_sheet(ln2, lg + 3.3, top)
	# the big hall over the hall of the Cristo
	var ln3 := face(CH_E, HL_E)
	_tiled(0.0, ln3, top, TOP_HALL, 0.0, "chapa")
	box(0.0, TOP_HALL, -0.3, ln3, 0.06, 0.32, 0xdfe3e8)
	# over the neighbours: the old store of number 4, the houses of Santa Ana, the Mayordomía
	for f in [[E_IN, STRIP_SE], [NE, E_IN], [SA_W, N_IN], [N_IN, CR_N]]:
		var a: Vector2 = f[0]
		var b: Vector2 = f[1]
		var ln := face(a, b)
		var t: float = TOP_SA if a == SA_W else TOP_HALL
		_banded(ln, [[DOWN, 2.4, "azul"], [2.4, 4.4, "blanco"], [4.4, t, "azul"]], [])
	# the two floors of the front, over the big hall's roof
	for f in [[STRIP_SE, STRIP_B], [STRIP_B, STRIP_BW], [STRIP_BW, STRIP_SW]]:
		var a: Vector2 = f[0]
		var b: Vector2 = f[1]
		var ln := face(b, a)
		_banded(ln, [[TOP_HALL - 0.1, TOP_SA, "blanco"]], [])
	home()

## The door from the car park, in its recess: glass, the red band, a canopy over it; the crossing before it.
func _back_door() -> void:
	var ln := face(S3, S4)
	var pg: float = _high(S3, S4)
	_banded(ln, [[DOWN, pg + 1.0, "azul"], [pg + 1.0, 3.0, "blanco"], [3.0, TOP_HALL, "azul"]], [Rect2(1.0, DOWN, 2.64, pg + 2.6 - DOWN)], 0.2)
	_sheet(ln, 3.0, TOP_HALL)
	_picture(1.0, 3.64, pg - 0.1, pg + 2.6, -0.2, "cristal")
	for x in [1.0, 2.29, 3.58]:
		box(x, pg - 0.1, -0.24, 0.06, 2.7, 0.08, 0x9a9da0)
	_picture(1.06, 3.58, pg + 1.3, pg + 1.5, -0.19, "entrada")
	_roster(0.5, pg + 1.7, 0.004, 0.05)                                                 # the Roster poster on the white beside the door
	box(1.0, pg - 3.0, -0.6, 2.64, 3.0, 0.4, 0x5a5a5e)                                  # the shop's floor, seen through it
	# the room behind, lit while it is open
	box(0.6, pg - 0.02, -4.0, 3.4, 0.02, 3.8, 0xd8d6d0)
	box(0.6, pg + 2.9, -4.0, 3.4, 0.04, 3.8, "sala")
	box(0.6, pg, -4.05, 3.4, 2.9, 0.05, "sala")
	box(1.4, pg + 2.86, -2.2, 1.8, 0.04, 0.3, "luz")
	# the canopy over the door, out over the walk (inside the recess: its east side is only two metres deep)
	var cy: float = pg + 3.0
	box(0.0, cy, 0.0, ln, 0.14, 2.0, 0xf2f2ee)
	box(0.0, cy - 0.22, 1.88, ln, 0.24, 0.12, 0xf2f2ee)
	for x in [0.15, ln - 0.27]:
		box(x, pg, 1.8, 0.12, cy - pg, 0.12, BLUE)
		solid(Vector3(x + 0.06, pg + 1.5, 1.86), Vector3(0.12, 3.0, 0.12))
		var w3: Vector3 = _xf * Vector3(x + 0.06, 0, 1.86)
		yard.append(Vector2(w3.x, w3.z))
	home()
	# the crossing before it
	var mid := (S3 + S4) / 2.0
	var out := Vector2(-0.419, 0.908)
	var along := (S4 - S3).normalized()
	for k in range(6):
		var c := mid + out * (1.0 + k * 0.0) + along * (-1.75 + k * 0.7)
		_strip(c + out * 0.2, c + out * 5.2, 0.4, 0.05, PAINT)

# ---------------- the roofs ----------------
const STRIP_PTS := [SA_W, SA_E, STRIP_SE, STRIP_B, STRIP_BW, STRIP_SW]
const MAIN_PTS := [STRIP_SW, STRIP_BW, STRIP_B, STRIP_SE, E_IN, NE, SE, S5, S4, S3, S2, SW, HL_E, CH_E, N_IN]
const CR_PTS := [CR_N, CH_E, HL_E, HL_W]

## Flat roofs of grey, at three heights: the two floors of the front, the big hall, the hall of the Cristo.
func _roofs() -> void:
	home()
	var crt: float = _high(CR_N, HL_W) + TOP_CR
	for r in [[STRIP_PTS, TOP_SA], [MAIN_PTS, TOP_HALL], [CR_PTS, crt]]:
		var pts := PackedVector2Array(r[0])
		flat(pts, float(r[1]) - 0.02, 0xb9bdc2)
	# the plant on the big hall's roof: two boxes of fans, a duct
	for c in [Vector2(446.0, 190.0), Vector2(440.0, 200.0)]:
		box(c.x - 1.2, TOP_HALL, c.y - 0.8, 2.4, 1.1, 1.6, 0xd9dcdf)
		drum(Vector3(c.x - 0.5, TOP_HALL + 1.1, c.y), 0.42, 0.42, 0.06, 0x3a3c3f, 14)
		drum(Vector3(c.x + 0.5, TOP_HALL + 1.1, c.y), 0.42, 0.42, 0.06, 0x3a3c3f, 14)

func _solids_of_shop() -> void:
	var crt: float = _high(CR_N, HL_W) + TOP_CR
	for r in [[STRIP_PTS, TOP_SA], [MAIN_PTS, TOP_HALL], [CR_PTS, crt]]:
		for part in Geometry2D.decompose_polygon_in_convex(PackedVector2Array(r[0])):
			_prism(Array(part), DOWN, float(r[1]))

# ---------------- the car park ----------------
## Its asphalt, on the ground as it falls towards Magallanes; the lane in from the Cristo.
func _park() -> void:
	home()
	park_poly = PackedVector2Array([PK_WN, SW, S2, S3, S4, S5, SE, PK_SC, PK_MC, PK_MW])
	_lay(park_poly, 0.02, "asfalto")

## A stretch of the car park's wall from a to b (the street out of its face, `face`): a foot of pale stone, blue, a
## white coping, `over` metres over the street, its top following the street; the wire fence `fence` over it on posts.
func _park_wall(a: Vector2, b: Vector2, over: float, fence: float, over_b := -1.0) -> void:
	if over_b < 0.0:
		over_b = over
	var total := a.distance_to(b)
	var n := maxi(1, int(ceil(total / 4.0)))
	for i in range(n):
		var p0 := a.lerp(b, float(i) / n)
		var p1 := a.lerp(b, float(i + 1) / n)
		var ln := face(p0, p1)
		var o0: Vector3 = _xf * Vector3(0, 0, 0.8)
		var o1: Vector3 = _xf * Vector3(ln, 0, 0.8)
		var g0: float = ground(o0.x, o0.z)
		var g1: float = ground(o1.x, o1.z)
		var t0: float = g0 + lerpf(over, over_b, float(i) / n)
		var t1: float = g1 + lerpf(over, over_b, float(i + 1) / n)
		pieces += 1
		quad(Vector3(0, DOWN, 0), Vector3(ln, DOWN, 0), Vector3(ln, g1 + 0.35, 0), Vector3(0, g0 + 0.35, 0), "piedra", Vector3(0, 0, 1))
		quad(Vector3(0, g0 + 0.35, 0), Vector3(ln, g1 + 0.35, 0), Vector3(ln, t1, 0), Vector3(0, t0, 0), "azul", Vector3(0, 0, 1))
		quad(Vector3(0, DOWN, -0.25), Vector3(ln, DOWN, -0.25), Vector3(ln, t1, -0.25), Vector3(0, t0, -0.25), "azul", Vector3(0, 0, -1))
		quad(Vector3(0, t0 + 0.06, -0.27), Vector3(ln, t1 + 0.06, -0.27), Vector3(ln, t1 + 0.06, 0.03), Vector3(0, t0 + 0.06, 0.03), 0xf2f2ee, Vector3.UP)
		quad(Vector3(0, t0, 0.03), Vector3(ln, t1, 0.03), Vector3(ln, t1 + 0.06, 0.03), Vector3(0, t0 + 0.06, 0.03), 0xf2f2ee, Vector3(0, 0, 1))
		if fence > 0.0:
			quad(Vector3(0, t0, -0.12), Vector3(ln, t1, -0.12), Vector3(ln, t1 + fence, -0.12), Vector3(0, t0 + fence, -0.12), "malla", Vector3(0, 0, 1),
				[Vector2(0, -t0), Vector2(ln, -t1), Vector2(ln, -t1 - fence), Vector2(0, -t0 - fence)])
			bar(Vector3(0, t0 + fence, -0.12), Vector3(ln, t1 + fence, -0.12), 0.04, 0.04, STEEL)
			bar(Vector3(0, t0, -0.12), Vector3(0, t0 + fence + 0.05, -0.12), 0.05, 0.05, STEEL)
		_hull([_xf * Vector3(0, DOWN, 0), _xf * Vector3(ln, DOWN, 0), _xf * Vector3(0, DOWN, -0.25), _xf * Vector3(ln, DOWN, -0.25),
			_xf * Vector3(0, t0 + fence, 0), _xf * Vector3(ln, t1 + fence, 0), _xf * Vector3(0, t0 + fence, -0.25), _xf * Vector3(ln, t1 + fence, -0.25)])
		var mid: Vector3 = _xf * Vector3(ln / 2.0, 0, -0.12)
		yard.append(Vector2(mid.x, mid.z))
	home()

## Its walls: low on the Suspiro (the customers' gate in it), tall on Magallanes and round the corner's cut; the plain
## wall behind the west shelter (the pastry cook's yard and the backs of the houses of the Cristo); the lane's wall.
func _park_walls() -> void:
	_park_wall(PK_SC, _su(SU_GATE[1]), 2.4, 1.6, 1.3)     # (taller towards the corner, as the street falls: Street View)
	_park_wall(_su(SU_GATE[0]), SE, 1.3, 1.8)
	_park_wall(PK_MC, PK_SC, 2.4, 1.4)                   # (as high as a man's eyes and more, on Magallanes: Street View)
	_park_wall(PK_MW, PK_MC, 2.4, 1.4)
	# the plain wall behind the west shelter, seen from the car park
	for f in [[PK_MW, PK_WN, 3.4], [PK_WN, _cr(CR_PIER[1]), 3.0]]:
		var a: Vector2 = f[0]
		var b: Vector2 = f[1]
		var ln := face(a, b)
		var g: float = _high(a, b)
		var t: float = g + float(f[2])
		_banded(ln, [[DOWN, g + 0.9, "azul"], [g + 0.9, t - 0.7, "blanco"], [t - 0.7, t, "azul"]], [])
		box(0.0, t, -0.3, ln, 0.06, 0.32, 0xf2f2ee)
		_hull([_xf * Vector3(0, DOWN, 0), _xf * Vector3(ln, DOWN, 0), _xf * Vector3(0, DOWN, -0.3), _xf * Vector3(ln, DOWN, -0.3),
			_xf * Vector3(0, t, 0), _xf * Vector3(ln, t, 0), _xf * Vector3(0, t, -0.3), _xf * Vector3(ln, t, -0.3)])
	home()
	_su_gate()

## The customers' gate on the Suspiro: two blue posts, the board over it, two leaves of lattice (back while it is open)
func _su_gate() -> void:
	var ln := face(_su(SU_GATE[1]), _su(SU_GATE[0]))
	var g: float = _high(_su(SU_GATE[1]), _su(SU_GATE[0]))
	for x in [-0.12, ln - 0.13]:
		box(x, DOWN, -0.25, 0.25, g + 2.7 - DOWN, 0.25, BLUE)
		solid(Vector3(x + 0.125, g + 1.0, -0.125), Vector3(0.25, 2.0, 0.25))
		var w3: Vector3 = _xf * Vector3(x + 0.125, 0, -0.125)
		yard.append(Vector2(w3.x, w3.z))
	box(-0.2, g + 2.7, -0.15, ln + 0.4, 0.56, 0.1, DARK_BLUE)
	_picture(-0.18, ln + 0.18, g + 2.72, g + 3.24, -0.045, "clientes")
	box(0.0, g - 0.2, -2.0, ln, 0.32, 2.0, 0xc9c5bc)                                     # the step in
	_commit()
	_gate_leaves(Vector3(0.13, g, -0.12), Vector3(1, 0, 0), ln / 2.0 - 0.13, 2.0)
	_gate_leaves(Vector3(ln - 0.13, g, -0.12), Vector3(-1, 0, 0), ln / 2.0 - 0.13, 2.0)
	_commit_to(_shut_nodes)
	_gate_leaves(Vector3(0.13, g, -0.12), Vector3(0, 0, -1), ln / 2.0 - 0.13, 2.0)
	_gate_leaves(Vector3(ln - 0.13, g, -0.12), Vector3(0, 0, -1), ln / 2.0 - 0.13, 2.0)
	_commit_to(_open_nodes)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(ln, 2.0, 0.2)
	cs.shape = bs
	cs.transform = transform * _xf * Transform3D(Basis.IDENTITY, Vector3(ln / 2.0, g + 1.0, -0.12))
	_solids().add_child(cs)
	_gate_solids.append(cs)
	home()

## The shelters for the cars, along the west wall, Magallanes and round the corner on to the Suspiro: grey sheet on
## blue posts, higher at the wall, a white edge; the bays under them, and the open row along the Suspiro.
func _shelters() -> void:
	home()
	var outp: Array = [PK_WN, PK_MW, PK_MC, PK_SC, PK_SN]
	var nrm: Array = []
	for i in range(outp.size() - 1):
		var d: Vector2 = ((outp[i + 1] as Vector2) - outp[i]).normalized()
		nrm.append(Vector2(d.y, -d.x))
	var inp: Array = [(outp[0] as Vector2) + (nrm[0] as Vector2) * SHELTER]
	for i in range(1, outp.size() - 1):
		var a0: Vector2 = (outp[i - 1] as Vector2) + (nrm[i - 1] as Vector2) * SHELTER
		var a1: Vector2 = (outp[i] as Vector2) + (nrm[i - 1] as Vector2) * SHELTER
		var b0: Vector2 = (outp[i] as Vector2) + (nrm[i] as Vector2) * SHELTER
		var b1: Vector2 = (outp[i + 1] as Vector2) + (nrm[i] as Vector2) * SHELTER
		var x = Geometry2D.line_intersects_line(a0, a1 - a0, b0, b1 - b0)
		inp.append(x if x != null else b0)
	inp.append((outp[-1] as Vector2) + (nrm[-1] as Vector2) * SHELTER)
	var posts: Array = []
	for i in range(outp.size() - 1):
		var o0: Vector2 = outp[i]
		var o1: Vector2 = outp[i + 1]
		var i0: Vector2 = inp[i]
		var i1: Vector2 = inp[i + 1]
		var n: Vector2 = nrm[i]
		# the roof: higher at the wall (2.95 m), lower at its edge (2.55 m)
		var yo0: float = ground(o0.x, o0.y) + 2.95
		var yo1: float = ground(o1.x, o1.y) + 2.95
		var yi0: float = ground(i0.x, i0.y) + 2.55
		var yi1: float = ground(i1.x, i1.y) + 2.55
		pieces += 1
		quad(Vector3(o0.x, yo0, o0.y), Vector3(o1.x, yo1, o1.y), Vector3(i1.x, yi1, i1.y), Vector3(i0.x, yi0, i0.y), "techo", Vector3.UP)
		quad(Vector3(i0.x, yi0 - 0.25, i0.y), Vector3(i1.x, yi1 - 0.25, i1.y), Vector3(i1.x, yi1 + 0.04, i1.y), Vector3(i0.x, yi0 + 0.04, i0.y), 0xf4f4f0, Vector3(n.x, 0, n.y))
		quad(Vector3(i0.x, yi0 - 0.25, i0.y), Vector3(i1.x, yi1 - 0.25, i1.y), Vector3(i1.x, yi1 + 0.04, i1.y), Vector3(i0.x, yi0 + 0.04, i0.y), 0xf4f4f0, Vector3(-n.x, 0, -n.y))
		# its posts along the edge, and against the wall, every five metres or so
		var L := i0.distance_to(i1)
		var k := maxi(1, int(round(L / 5.0)))
		for j in range(k + 1):
			if j == 0 and i > 0:
				continue
			var t := float(j) / k
			var pi_ := i0.lerp(i1, t)
			var po := o0.lerp(o1, float(j) / k) + n * 0.35
			posts.append([pi_, lerpf(yi0, yi1, t), po, lerpf(yo0, yo1, t)])
		# the bays under it, nose to the wall, clear of the corners
		var span := o0.distance_to(o1)
		var dd := (o1 - o0).normalized()
		var s0: float = 0.6 if i == 0 else SHELTER + 0.4
		var s1: float = span - (0.6 if i == outp.size() - 2 else SHELTER + 0.4)
		var nb := int(floor((s1 - s0) / BAY))
		if nb > 0:
			var st: float = s0 + ((s1 - s0) - nb * BAY) / 2.0
			for b in range(nb + 1):
				var p := o0 + dd * (st + b * BAY)
				_strip(p + n * 0.3, p + n * 5.3, 0.1, 0.05, PAINT)
				if b < nb:
					var c := o0 + dd * (st + (b + 0.5) * BAY)
					bay_spots.append([c + n * 0.9, -n])
					bays += 1
	for p in posts:
		var pi_: Vector2 = p[0]
		var po: Vector2 = p[2]
		var gi: float = ground(pi_.x, pi_.y)
		var go: float = ground(po.x, po.y)
		box(pi_.x - 0.06, gi, pi_.y - 0.06, 0.12, float(p[1]) - gi, 0.12, BLUE)
		box(po.x - 0.06, go, po.y - 0.06, 0.12, float(p[3]) - go, 0.12, BLUE)
		bar(Vector3(pi_.x, float(p[1]) - 0.08, pi_.y), Vector3(po.x, float(p[3]) - 0.08, po.y), 0.1, 0.12, BLUE)
		solid(Vector3(pi_.x, gi + 1.2, pi_.y), Vector3(0.14, 2.4, 0.14))
		yard.append(pi_)
		box(lerpf(pi_.x, po.x, 0.5) - 0.3, lerpf(float(p[1]), float(p[3]), 0.5) - 0.14, lerpf(pi_.y, po.y, 0.5) - 0.06, 0.6, 0.03, 0.12, "luz")
	# the open row along the Suspiro, north of the shelter
	var inward := Vector2(-_su_u.y, _su_u.x) * -1.0
	if inward.dot(Vector2(-1, 0)) < 0.0:
		inward = -inward
	var t := 4.6
	while t <= 17.1 + 0.01:
		var p := _su(t)
		_strip(p + inward * 0.3, p + inward * 5.3, 0.1, 0.05, PAINT)
		if t < 17.0:
			var c := _su(t + BAY / 2.0)
			bay_spots.append([c + inward * 0.9, -inward])
			bays += 1
		t += BAY
	# the lanes' arrows
	_arrow(Vector2(424.0, 224.0), Vector2(0.33, 0.94))
	_arrow(Vector2(422.0, 238.0), Vector2(0.6, -0.8))

func _arrow(at: Vector2, d: Vector2) -> void:
	var n := Vector2(-d.y, d.x)
	_lay(PackedVector2Array([at - d * 1.2 - n * 0.12, at + d * 0.3 - n * 0.12, at + d * 0.3 + n * 0.12, at - d * 1.2 + n * 0.12]), 0.045, PAINT)
	_lay(PackedVector2Array([at + d * 0.3 - n * 0.45, at + d * 1.1, at + d * 0.3 + n * 0.45]), 0.045, PAINT)

## The covered walk from the customers' gate along the shop's back to its door: a raised walk of paving, its kerb, the
## white canopy on blue posts.
func _walkway() -> void:
	var out := Vector2(-0.493, 0.87)                                                     # out of the back (face S5 -> SE)
	var a := S5
	var b := SE + _su_u * 0.0
	var poly := PackedVector2Array([a, b, b + out * 2.4, a + out * 2.4])
	_lay(poly, 0.14, "acera")
	var ln := face(a + out * 2.4, b + out * 2.4)
	var g: float = _low(a + out * 2.4, b + out * 2.4)
	box(0.0, g - 0.2, -0.12, ln, 0.36, 0.12, 0xb8b4aa)
	home()
	var pg: float = _high(S5, SE)
	var cy: float = pg + 3.0
	var ln2 := face(S5, SE)
	box(0.0, cy, 0.0, ln2 - 1.2, 0.14, 2.5, 0xf2f2ee)                                   # (it stops short of the gate: its board shows over it)
	box(0.0, cy - 0.22, 2.38, ln2 - 1.2, 0.24, 0.12, 0xf2f2ee)
	for x in [0.2, (ln2 - 1.2) / 2.0, ln2 - 1.52]:
		box(x, pg - 0.1, 2.3, 0.12, cy - pg + 0.1, 0.12, BLUE)
		solid(Vector3(x + 0.06, pg + 1.5, 2.36), Vector3(0.12, 3.0, 0.12))
		var w3: Vector3 = _xf * Vector3(x + 0.06, 0, 2.36)
		yard.append(Vector2(w3.x, w3.z))
		box(x - 0.2, cy - 0.04, 1.0, 0.5, 0.03, 0.14, "luz")
	home()

## The lane in from the gate on the Cristo, between the hall and the pastry cook's, down to the car park.
func _lane() -> void:
	home()
	_lay(PackedVector2Array([HL_W, HL_E, SW, PK_WN, _cr(CR_PIER[1])]), 0.02, "asfalto")
	_arrow(Vector2(410.0, 207.5), Vector2(0.92, 0.38))

## The car park's lamps: two tall ones by the wall of the Suspiro (the town's: they light at night).
## Its inside, a set apart (the user, 17 Nov 2026: "un interior al que se puede acceder por las dos entradas"): in by the
## glass doors on Santa Ana or by the door from the car park, each with its green arrow while it is open.
func _build_inside() -> void:
	var out_sa := Vector2(0.244, -0.97)                                                 # out of the front on Santa Ana
	var front_mid: Vector2 = SA_E + (SA_W - SA_E).normalized() * ((SA_DOOR[0] + SA_DOOR[1]) / 2.0)
	var out_bk := Vector2(-0.419, 0.908)                                                # out of the back door, into the car park
	var back_mid := (S3 + S4) / 2.0
	tienda = DentroS.new()
	tienda.build(W, front_mid + out_sa * 0.25, front_mid + out_sa * 2.8, atan2(out_sa.x, out_sa.y), back_mid + out_bk * 0.25, back_mid + out_bk * 2.8, atan2(out_bk.x, out_bk.y))
	trasera = tienda.back

func _park_lamps() -> void:
	home()
	var inward := Vector2(_su_u.y, -_su_u.x)
	if inward.dot(Vector2(-1, 0)) < 0.0:
		inward = -inward
	for t in [9.0, 27.0]:
		var p := _su(t) + inward * 0.5
		var g: float = ground(p.x, p.y)
		var o := Vector3(p.x, g, p.y)
		drum(o - Vector3(0, 0.1, 0), 0.18, 0.18, 0.3, 0x9a9da0, 10)
		drum(o, 0.09, 0.06, 6.5, 0x9a9da0, 8)
		var arm := Vector3(inward.x, 0, inward.y) * 1.2
		bar(o + Vector3(0, 6.4, 0), o + Vector3(0, 6.4, 0) + arm, 0.06, 0.06, 0x6a6e72)
		cbox(o + Vector3(0, 6.3, 0) + arm, Vector3(0.5, 0.16, 0.3), 0x3a3c3f)
		cbox(o + Vector3(0, 6.215, 0) + arm, Vector3(0.44, 0.01, 0.24), "foco")
		solid(o + Vector3(0, 2.0, 0), Vector3(0.24, 4.0, 0.24))
		var w: Vector3 = transform * (o + Vector3(0, 6.2, 0) + arm)
		W.lamp_spots.append(w)
		lamps.append(w)
		yard.append(p)

# ---------------- its hours ----------------
## whether it is open on that day of the week (0 Monday ... 6 Sunday) at that hour
func open_at(day: int, hour: float) -> bool:
	if posmod(day, 7) == 6:
		return false
	return hour >= OPENS and hour < SHUTS

func _process(delta: float) -> void:
	var game = W.get_parent() if W != null else null
	if game != null and "clock" in game and "weekday" in game:
		var want: bool = open_at(int(game.weekday), float(game.clock))
		if want != is_open:
			set_open(want)
		_cars_t -= delta
		if _cars_t <= 0.0:
			_cars_t = 1.0
			_tend_cars(game)
		if _mats.has("rotulo"):                       # its name lit at dusk while it is open: its own colours whatever the light
			var hr: float = float(game.clock)
			var lit: bool = is_open and (hr >= 18.5 or hr < 8.0)
			var rm := _mats["rotulo"] as StandardMaterial3D
			var want_mode := BaseMaterial3D.SHADING_MODE_UNSHADED if lit else BaseMaterial3D.SHADING_MODE_PER_PIXEL
			if rm.shading_mode != want_mode:
				rm.shading_mode = want_mode

## open: the gates swung back, the lights on behind the glass and under the shelters; shut: the gates across, dark
func set_open(on: bool) -> void:
	is_open = on
	if tienda != null:                              # (its doors with it: entradas.gd lets you in only while it is open)
		tienda.open = on
		trasera.open = on
	for n in _open_nodes:
		(n as Node3D).visible = on
	for n in _shut_nodes:
		(n as Node3D).visible = not on
	for cs in _gate_solids:
		(cs as CollisionShape3D).disabled = on
	for q in [["luz", 1.4], ["sala", 0.3], ["foco", 1.4]]:
		if _mats.has(q[0]):
			(_mats[q[0]] as StandardMaterial3D).emission_energy_multiplier = float(q[1]) if on else 0.0

# ---------------- the customers' cars ----------------
## While it is open there are cars in its car park, as at the MasAhorro: six, nine at the busy hours (midday, and the
## evening); nose to the wall, most of them near the back door. They come and go where you are not looking; shut, they go.
func cars_wanted(hour: float) -> int:
	if not is_open:
		return 0
	return 9 if (hour >= 12.0 and hour < 14.5) or (hour >= 18.0 and hour < 21.0) else 6

## where a car of that make stands in that bay, on the map, and which way it faces
func _bay_place(bi: int, kind: String) -> Array:
	var s: Array = bay_spots[bi]
	var nose: Vector2 = s[0]
	var dir: Vector2 = s[1]
	var ln: float = float(CarS.SPECS[kind]["len"])
	return [nose - dir * (ln / 2.0), atan2(dir.x, dir.y)]

## a free bay, the nearer the back door the likelier (-1: none)
func _free_bay(G) -> int:
	var total := 0.0
	var free: Array = []
	for bi in range(bay_spots.size()):
		var at: Vector2 = _bay_place(bi, "z15")[0]
		if G.cars.any(func(c): return is_instance_valid(c) and c.p.distance_to(at) < 2.2):
			continue
		var w: float = 1.0 / (1.0 + at.distance_to(back_door) / 12.0)
		free.append([bi, w])
		total += w
	if free.is_empty():
		return -1
	var roll := randf() * total
	for e in free:
		roll -= float(e[1])
		if roll <= 0.0:
			return int(e[0])
	return int(free[-1][0])

## one step towards as many cars as it wants: one parked or one gone, unseen (`now`: at once, seen or not)
func _tend_cars(G, now := false) -> void:
	if G.player == null or not ("cars" in G):
		return
	var keep: Array = []
	for e in parked:
		var c = e["car"]
		if is_instance_valid(c) and c != G.in_car and c.p.distance_to(e["at"]) < 3.0:
			keep.append(e)
	parked = keep
	var want := cars_wanted(float(G.clock))
	if parked.size() < want:
		var bi := _free_bay(G)
		if bi < 0:
			return
		var kind: String = String(MAKES.pick_random())
		var place: Array = _bay_place(bi, kind)
		var at: Vector2 = place[0]
		if not now and (G.player.p.distance_to(at) < UNSEEN or G.sees(at)):
			return
		var c = CarS.new()
		G.add_child(c)
		c.setup(kind, 0, at, place[1])
		c.park()
		G.cars.append(c)
		parked.append({"car": c, "at": at})
	elif parked.size() > want:
		for e in parked:
			var c = e["car"]
			if now or (G.player.p.distance_to(c.p) > UNSEEN and not G.sees(c.p)):
				G.cars.erase(c)
				c.queue_free()
				parked.erase(e)
				return

## (the self-test's pictures: the car park as it should be by now)
func settle_cars(G) -> void:
	for i in range(20):
		_tend_cars(G, true)

# ---------------- what the map should know ----------------
func _tell_map() -> void:
	MapData.outlines.append(outline)
	if not MapData._wall_grid.is_empty():
		for i in range(outline.size()):
			var a: Vector2 = outline[i]
			var c: Vector2 = outline[(i + 1) % outline.size()]
			MapData._grid_add(MapData._wall_grid, a.min(c), a.max(c), [a, c])
