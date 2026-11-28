extends "res://scripts/obra.gd"
## The car electrician's "Taller Lápiz" and the sweet maker's "Dulces San Paquito" of the Avenida de Martín Descalzo,
## side by side (the user, 27 November 2026: "Vamos ahora con Taller López (que llamaremos taller Lápiz) y dulces san
## Francisco (que llamaremos dulces san Paquito) ya que están los edificios pegados", with five pictures of Street View,
## November 2024), built by hand on Texturas's three houses of the map (md_9e, md_9d, md_9c, handed over as ["obra"] in
## casas_calles.gd); referencias/taller_lapiz/, tools/lapiz/. Measures: Catastro (the nave, 4398811, and the house
## next door, 4398813, with their photographs of the fronts) and Street View 2024.
##
## From the south end (the left, seen from the street):
##   - the workshop: a white front 14.5 m long and 5 m high, its trade painted along the top in blue (ELECTRICIDAD DEL
##     AUTOMÓVIL), TALLER LÁPIZ in tall faded red letters on a board raised over it (a dish and an air-conditioner up
##     there too); below, the old bay: its left part open on the dark workshop, its right part shut with blue
##     corrugated sheet; a little window; a foot of grey tiles with a white lattice;
##   - a bay of blue corrugated sheet a little behind it (a big door, a band of louvres over it), its concrete ramp;
##   - the sweet maker's nave: tan facing brick on blue steel posts, a pale foot, three barred windows, a scissor gate
##     before its shop door, a big blue door up its own ramp, the corrugated eaves with their gutter; before it a white
##     parapet with rose bushes behind it, and another low wall beyond the big door;
##   - the white pier with the painted panel (DULCES SAN PAQUITO, a friar's plain silhouette as on the real one, a
##     scroll of what they make: our own wording), the meters' recess, a box of the wires; the oven's flue behind it;
##   - the low white house (a big window, its brown blind down behind black bars; its door; a foot of salmon tiles) and
##     the beige wall of the store beyond, up to the yard wall of the corner (Texturas's md_9).
## In the street: the tree before the workshop, the beige bin with a green lid before the pier, the pole by the house.
## No house numbers, telephones or web addresses (the game shows none).
## Hours (Google Maps): the workshop Monday to Friday 9:00-20:45, Saturdays 9:00-14:00, shut on Sundays (shut: a
## sliding leaf of blue sheet across the open bay, its light out); the sweet maker's every day 9:00-14:00 and
## 16:00-20:00 (shut: the scissor gate across its door; open: the gate folded, the door in, light inside).
##
## Frame: origin at the front's south end, on the party wall with the salmon house (md_7); +x along the front, +z out
## of it, towards the street; y = 0 the nave's pavement.

const READY := true
const HOUSES := ["md_9e", "md_9d", "md_9c"]
const DIR := "res://assets/lapiz/"
const NAME_T := "TALLER LÁPIZ"                  # (the user's names, 27 Nov 2026)
const NAME_D := "DULCES SAN PAQUITO"
const T1 := 14.45               # the workshop's white front ends here...
const BACK := 2.6               # ...and the blue bay and the nave stand this far behind the street's line, on which the
                                # workshop and the white pier and house stand (Google's aerial; the user's photographs
                                # of 27 Nov 2026: the pier's side to the south-west, with the sweet maker's board, looks
                                # down the avenue)
const SET := BACK
const ZW := 1.7                 # the parapets' face, out from the nave's (the walk with the roses behind them)
const ZF := 0.3                 # the ramps come down to here, out from the street's line
const TOP_T := 5.0              # the top of the workshop's front
const TOP_N := 4.7              # the nave's eaves (and the blue bay's)
const RIDGE_N := 6.05
const FLOOR_N := 0.38           # the nave's floor (and its walk behind the parapet), over the pavement
const DT := 8.0                 # how deep the workshop is (Texturas's house; Catastro's photograph of number 7)
const DH := 6.0                 # how deep the pier, the house and the store are
const BAY := Rect2(0.7, 0.0, 5.8, 3.35)        # the workshop's old bay...
const OPEN_X := 3.95                           # ...open as far as this, shut with blue sheet beyond
const WIN_T := Rect2(6.85, 1.95, 0.6, 0.55)
const TOP_P := 3.55             # the pier's top
const P1 := 35.0                # the pier's block ends...
const H0 := 36.1                # ...the house begins...
const H1 := 42.7                # ...and ends; the store's beige wall beyond
const TOP_H := 3.05
const WIN_H := Rect2(37.3, 0.85, 2.15, 1.35)
const DOOR_H := Rect2(40.75, 0.0, 0.9, 2.15)
const TALLER_HOURS := {0: [Vector2(9.0, 20.75)], 1: [Vector2(9.0, 20.75)], 2: [Vector2(9.0, 20.75)], 3: [Vector2(9.0, 20.75)],
	4: [Vector2(9.0, 20.75)], 5: [Vector2(9.0, 14.0)]}        # the day (0 Monday ... 6 Sunday) and from when to when; Sundays shut
const DULCES_HOURS := {0: [Vector2(9.0, 14.0), Vector2(16.0, 20.0)], 1: [Vector2(9.0, 14.0), Vector2(16.0, 20.0)],
	2: [Vector2(9.0, 14.0), Vector2(16.0, 20.0)], 3: [Vector2(9.0, 14.0), Vector2(16.0, 20.0)], 4: [Vector2(9.0, 14.0), Vector2(16.0, 20.0)],
	5: [Vector2(9.0, 14.0), Vector2(16.0, 20.0)], 6: [Vector2(9.0, 14.0), Vector2(16.0, 20.0)]}
const BLUE := 0x3a70b8
const BLUE_DARK := 0x2c5a98
const WHITE := 0xf0eee8

var B1 := 18.69                 # the blue bay ends and the nave begins (md_9d's corner)
var N1 := 33.27                 # the nave ends (Catastro's corner) and the pier begins
var E := 48.08                  # the row ends at the corner's yard wall
var DN := 20.07                 # how deep the nave is (Catastro)
var EU := Vector2(0.6112, -0.7915)
var EV := Vector2(0.7915, 0.6112)
var A := Vector2(53.65, -620.16)
# the nave's openings, set once its corner is known (from its west end: window, gate, window, big door, window)
var W1: Rect2
var GATE: Rect2
var W2: Rect2
var DOOR_N: Rect2
var W3: Rect2
var POSTS: Array = []

var taller_door: Vector2        # before the workshop's open bay, on the pavement (the self-test)
var dulces_door: Vector2        # before the sweet maker's door, on its walk
var walk_y := 0.0               # the walk behind the parapet, in the world
var taller_open := false
var dulces_open := false
var openings := 0
var decks: Array = []           # its walk and its ramps, as given to the map
var _taller_shut: Node3D
var _taller_lit: Node3D
var _dulces_shut: Node3D
var _dulces_lit: Node3D
var _lights: Array = []

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"blanco":           # the workshop's white render, a little dirty
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.97, 0.96, 0.92)), 0.12)
		"blanco_viejo":     # the pier's and the house's, older and rougher
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.93, 0.92, 0.87)), 0.1)
		"ladrillo":         # the nave's tan facing brick (Street View 2024: about 205, 170, 130 in the sun)
			m = Tex.mat("brick_wall_003@0.9", Color(1.02, 1.2, 1.38))
		"revoco":           # the nave's pale foot
			m = Tex.mat("painted_plaster_wall", Color(0.9, 0.82, 0.7))
		"beige":            # the store's wall
			m = Tex.mat("painted_plaster_wall", Color(0.86, 0.79, 0.66))
		"cemento":          # the ramps and the walk
			m = Tex.mat("granular_concrete", Color(0.8, 0.78, 0.74))
		"solera":           # the concrete before the workshop and the blue bay, where cars and the tractor stand
			m = Tex.mat("granular_concrete", Color(0.7, 0.68, 0.64))
		"acera":            # the small grey tiles before the parapets, the pier and the house
			m = W._tmat(0xc4c0b8, "pavement", 1.0)
		"tierra":
			m = Tex.mat("granular_concrete", Color(0.5, 0.38, 0.28))
		"chapa_azul", "chapa_gris", "uralita", "chapa_tejado":     # corrugated sheet: one rib to the picture, its UVs in ribs
			var cols := {"chapa_azul": [Color(0.27, 0.49, 0.78), Color(0.17, 0.33, 0.58)], "chapa_gris": [Color(0.66, 0.68, 0.7), Color(0.46, 0.48, 0.5)],
				"uralita": [Color(0.78, 0.77, 0.74), Color(0.55, 0.54, 0.52)], "chapa_tejado": [Color(0.46, 0.46, 0.47), Color(0.3, 0.3, 0.31)]}
			var c: Array = cols[String(key)]
			var img := Image.create(16, 4, false, Image.FORMAT_RGB8)
			for x in range(16):
				var k := 0.5 + 0.5 * cos(x / 16.0 * TAU)
				for y in range(4):
					img.set_pixel(x, y, (c[1] as Color).lerp(c[0], k))
			var sm := StandardMaterial3D.new()
			sm.albedo_texture = ImageTexture.create_from_image(img)
			sm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			sm.roughness = 0.7 if String(key) != "uralita" else 0.95
			sm.metallic = 0.25 if String(key).begins_with("chapa") else 0.0
			sm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = sm
		"rotulo", "dulces", "baldosa_gris", "baldosa_salmon":
			var tm := StandardMaterial3D.new()
			tm.albedo_texture = load(DIR + String(key) + ".png")
			tm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			tm.roughness = 0.85
			if String(key) == "rotulo" or String(key) == "dulces":
				tm.emission_enabled = true          # (a little light of their own: they are read at dusk too)
				tm.emission_texture = tm.albedo_texture
				tm.emission = Color.WHITE
				tm.emission_energy_multiplier = 0.1
			m = tm
		"letras":           # the trade, painted on the wall: blue letters on nothing
			var lm := StandardMaterial3D.new()
			lm.albedo_texture = load(DIR + "letras.png")
			lm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			lm.alpha_scissor_threshold = 0.5
			lm.roughness = 0.9
			m = lm
		"tijera":           # the scissor gate: a lattice of galvanised flats
			var img2 := Image.create(32, 32, false, Image.FORMAT_RGBA8)
			for y in range(32):
				for x in range(32):
					var on: bool = absi(x - 16) < 2 or absi(posmod(x - y, 32) - 0) < 2 or absi(posmod(x + y, 32) - 0) < 2 or absi(posmod(x + y, 32) - 31) < 1
					img2.set_pixel(x, y, Color(0.7, 0.72, 0.72, 1.0 if on else 0.0))
			var gm := StandardMaterial3D.new()
			gm.albedo_texture = ImageTexture.create_from_image(img2)
			gm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			gm.alpha_scissor_threshold = 0.5
			gm.metallic = 0.4
			gm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = gm
		"vidrio":
			var vm := StandardMaterial3D.new()
			vm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			vm.albedo_color = Color(0.55, 0.68, 0.72, 0.32)
			vm.roughness = 0.12
			vm.metallic_specular = 0.7
			m = vm
		"vidrio_puerta":    # the house door's glass: frosted, pale green
			var pm := StandardMaterial3D.new()
			pm.albedo_color = Color(0.72, 0.78, 0.62)
			pm.roughness = 0.3
			m = pm
		"interior":         # what shows through the sweet maker's door: dark when shut, warm when open
			var im := StandardMaterial3D.new()
			im.albedo_color = Color(0.12, 0.1, 0.08)
			im.emission_enabled = true
			im.emission = Color(1.0, 0.86, 0.62)
			im.emission_energy_multiplier = 0.05
			m = im
		"luz":
			var lm2 := StandardMaterial3D.new()
			lm2.albedo_color = Color(0.95, 0.97, 1.0)
			lm2.emission_enabled = true
			lm2.emission = Color(0.92, 0.96, 1.0)
			lm2.emission_energy_multiplier = 1.6
			m = lm2
		"taller_dentro":    # the workshop's dark inside
			m = Tex.mat("granular_concrete", Color(0.42, 0.41, 0.4))
		_:
			return super(key)
	_mats[key] = m
	return m

## the three houses of the map it stands on, if Texturas has handed them over: [md_9e, md_9d, md_9c] (or empty)
## (`anyway`: the houses as they are even if not handed over yet -- the self-test's --lapiz, to see it before then)
static func handed_over(anyway := false) -> Array:
	var short = preload("res://scripts/casas_calles.gd").HOUSES
	var out := {}
	for hd in MapData.houses:
		var id := String(hd["id"])
		if id in HOUSES:
			var line = short.get(id, [])
			if not anyway and not (line is Array and (line as Array).size() == 1 and String(line[0]) == "obra"):
				return []
			out[id] = hd
	if out.size() < HOUSES.size():
		return []
	return [out["md_9e"], out["md_9d"], out["md_9c"]]

func build(world, hds: Array) -> void:
	W = world
	var he: Dictionary = hds[0]
	var hn: Dictionary = hds[1]
	var hc: Dictionary = hds[2]
	A = Vector2(he["o"][0], he["o"][1])
	EU = Vector2(he["u"][0], he["u"][1]).normalized()
	EV = Vector2(-EU.y, EU.x)
	B1 = to_uv(Vector2(hn["o"][0], hn["o"][1])).x
	N1 = to_uv(Vector2(hc["o"][0], hc["o"][1])).x
	E = N1 + float(hc["len"])
	DN = 0.0
	for i in range(0, (hn["pieces"][0]["ring"] as Array).size(), 2):
		DN = maxf(DN, -to_uv(Vector2(hn["pieces"][0]["ring"][i], hn["pieces"][0]["ring"][i + 1])).y)
	level = float(hn.get("base", MapData.height(map_at((B1 + N1) / 2.0, 1.5))))
	transform = Transform3D(Basis(Vector3(EU.x, 0, EU.y), Vector3.UP, Vector3(EV.x, 0, EV.y)), Vector3(A.x, level, A.y))
	W.add_child(self)
	var s0 := B1
	W1 = Rect2(s0 + 1.0, 1.75, 1.5, 0.9)
	GATE = Rect2(s0 + 3.75, FLOOR_N, 1.1, 2.2)
	W2 = Rect2(s0 + 5.2, 1.75, 1.6, 0.9)
	DOOR_N = Rect2(s0 + 7.25, FLOOR_N, 3.55, 3.15)
	W3 = Rect2(s0 + 11.35, 1.75, 1.6, 0.9)
	POSTS = [s0, s0 + 3.5, s0 + 7.0, s0 + 10.9, N1 - 0.1]
	walk_y = level + FLOOR_N
	taller_door = spot(2.3, 1.4)
	dulces_door = spot(GATE.get_center().x, -BACK + 0.6)
	_taller()
	_blue_bay()
	_nave()
	_pier()
	_house()
	_forecourt()
	_apron()
	_street()
	home()
	_commit()
	_states()
	_solids_all()
	set_open(open_taller(0, 12.0), open_dulces(0, 12.0))

func map_at(u: float, v: float) -> Vector2:
	return A + EU * u + EV * v

func to_uv(p: Vector2) -> Vector2:
	var d := p - A
	return Vector2(d.dot(EU), d.dot(EV))

static func _open_at(hours: Dictionary, day: int, hour: float) -> bool:
	var d := posmod(day, 7)
	if not hours.has(d):
		return false
	for h: Vector2 in hours[d]:
		if hour >= h.x and hour < h.y:
			return true
	return false

func open_taller(day: int, hour: float) -> bool:
	return _open_at(TALLER_HOURS, day, hour)

func open_dulces(day: int, hour: float) -> bool:
	return _open_at(DULCES_HOURS, day, hour)

# ---------------- pieces ----------------
## a flat picture (x0..x1, y0..y1) on the plane z of the frame being built, facing +z
func _picture(x0: float, x1: float, y0: float, y1: float, z: float, key) -> void:
	pieces += 1
	quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

## something that repeats every `step` metres across and `stepy` up (tiles, corrugated sheet), facing +z
func _tiled(x0: float, x1: float, y0: float, y1: float, z: float, key, step := 0.2, stepy := 0.2) -> void:
	pieces += 1
	quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1),
		[Vector2(x0 / step, -y0 / stepy), Vector2(x1 / step, -y0 / stepy), Vector2(x1 / step, -y1 / stepy), Vector2(x0 / step, -y1 / stepy)])

## a stretch of corrugated sheet standing on the plane z (its ribs upright, 18 cm apart), with a little thickness
func _sheet(x0: float, x1: float, y0: float, y1: float, z: float, key := "chapa_azul") -> void:
	_tiled(x0, x1, y0, y1, z, key, 0.18, 4.0)
	box(x0, y0, z - 0.03, x1 - x0, y1 - y0, 0.025, BLUE_DARK if key == "chapa_azul" else 0x6a6c6e)

## a piece of corrugated roof: four corners in order (its ribs running down the slope)
func _roof_sheet(pts: Array, key := "uralita") -> void:
	pieces += 1
	var n: Vector3 = ((pts[1] as Vector3) - pts[0]).cross((pts[2] as Vector3) - pts[0]).normalized()
	if n.y < 0.0:
		n = -n
	var along := Vector3.UP.cross(n).normalized()
	var uv: Array = []
	for p: Vector3 in pts:
		uv.append(Vector2(p.dot(along) / 0.18, 0.0 + p.y))
	quad(pts[0], pts[1], pts[2], pts[3], key, n, uv)

## a plain wall seen from both sides (a gable, a back), between two heights
func _both(a: Vector2, b: Vector2, y0: float, y1: float, key) -> void:
	_plain(a, b, y0, y1, key)
	_plain(b, a, y0, y1, key)

# ---------------- the workshop ----------------
func _taller() -> void:
	face(Vector2(0, 0), Vector2(T1, 0))
	masonry(0.025, T1, -1.0, TOP_T, [BAY, WIN_T], [], "blanco", "blanco")
	openings += 2
	# the foot of grey tiles, a little proud, cut at the bay
	for run in [[0.025, BAY.position.x], [BAY.end.x, T1]]:
		_tiled(run[0], run[1], -0.4, 1.0, 0.014, "baldosa_gris", 0.8, 0.8)
		box(run[0], 1.0, 0.0, run[1] - run[0], 0.03, 0.02, 0xd8d8d4)
	# the trade painted along the top, the band's lines
	_picture(0.3, T1 - 0.3, 3.68, 4.6, 0.012, "letras")
	box(0.025, 3.62, 0.0, T1 - 0.025, 0.04, 0.012, 0xdad8d0)
	# the old bay: its steel lintel painted white; the open part (the workshop behind), the part shut with blue sheet
	box(BAY.position.x - 0.05, BAY.end.y - 0.16, 0.0, BAY.size.x + 0.1, 0.16, 0.03, 0xe4e2dc)
	_sheet(OPEN_X, BAY.end.x, 0.0, BAY.end.y - 0.02, -0.12)
	box(OPEN_X - 0.06, 0.0, -0.16, 0.08, BAY.end.y, 0.12, 0x6a6c70)                 # (the steel post between the two)
	box(BAY.position.x - 0.02, -0.02, -DEEP, BAY.size.x + 0.04, 0.04, DEEP + 0.02, 0x8a8884)   # (the sill of the bay)
	_inside()
	# the little window: white frame, a cross of bars
	window(WIN_T, 0xeeeeea, 0x2a3640, 1)
	box(WIN_T.position.x - 0.05, WIN_T.position.y - 0.05, 0.0, WIN_T.size.x + 0.1, 0.05, 0.07, 0xe8e8e4)
	# the top: a coping, the board on its raised parapet with two stays behind, the dish, the air-conditioner
	box(-0.0, TOP_T, -0.25, T1, 0.06, 0.29, 0xdcdad2)
	var b0 := 3.8
	var b1 := 10.9
	box(b0, TOP_T + 0.06, -0.14, b1 - b0, 1.12, 0.14, "blanco")
	box(b0 - 0.02, TOP_T + 1.18, -0.16, b1 - b0 + 0.04, 0.04, 0.18, 0xd4d2ca)
	_picture(b0 + 0.04, b1 - 0.04, TOP_T + 0.08, TOP_T + 1.16, 0.014, "rotulo")
	for x in [b0 + 0.5, (b0 + b1) / 2.0, b1 - 0.5]:
		bar(Vector3(x, TOP_T + 1.05, -0.14), Vector3(x, TOP_T + 0.06, -1.3), 0.05, 0.05, 0x8a8a86)
	var dish := Vector3(b0 - 0.45, TOP_T + 0.62, -0.05)
	bar(Vector3(dish.x, TOP_T + 0.06, -0.2), Vector3(dish.x, dish.y - 0.1, -0.2), 0.05, 0.05, 0x9a9a96)
	var keep := _xf
	_xf = keep * Transform3D(Basis(Vector3.RIGHT, -0.45), dish)
	drum(Vector3(0, -0.02, 0), 0.32, 0.3, 0.04, 0xeeeeea, 16)
	_xf = keep
	bar(Vector3(dish.x, dish.y - 0.1, -0.2), Vector3(dish.x, dish.y + 0.15, 0.35), 0.025, 0.025, 0x9a9a96)
	box(0.08, TOP_T + 0.06, -0.42, 0.82, 0.56, 0.3, 0xdedcd6)
	drum(Vector3(0.62, TOP_T + 0.34, -0.11), 0.2, 0.2, 0.01, 0x5a5a5a, 12)
	box(0.12, TOP_T + 0.1, -0.11, 0.24, 0.48, 0.012, 0xbcbab4)
	# the downpipe at its north end, the return of its wall to the blue bay
	bar(Vector3(T1 - 0.14, TOP_T, 0.07), Vector3(T1 - 0.14, 0.0, 0.07), 0.08, 0.08, 0x8a8c8e)
	home()
	_plain(Vector2(T1, 0.0), Vector2(T1, -SET), -1.0, TOP_T, "blanco")
	# its body: the party wall with the salmon house, the back, the north side over the yard; the roof sheets behind
	# the parapet, falling to the back
	_both(Vector2(0.025, -DT), Vector2(T1, -DT), -0.5, 4.3, "blanco_viejo")
	_roof_sheet([Vector3(0.025, 4.82, -0.2), Vector3(T1, 4.82, -0.2), Vector3(T1, 4.3, -DT - 0.25), Vector3(0.025, 4.3, -DT - 0.25)])

## the workshop seen through its open bay: a dark floor, walls of a dim grey, the bench, the batteries, the charger,
## a stack of tyres; its tube of light (lit when it is open: _states)
func _inside() -> void:
	var x0 := 0.06
	var x1 := OPEN_X + 2.4
	var z1 := -DT + 0.3
	var fy := ground(2.3, -1.0) + 0.01
	flat(PackedVector2Array([Vector2(x0, -DEEP), Vector2(x1, -DEEP), Vector2(x1, z1), Vector2(x0, z1)]), fy, 0x4a4844)
	quad(Vector3(x0, 0, z1), Vector3(x1, 0, z1), Vector3(x1, 4.2, z1), Vector3(x0, 4.2, z1), "taller_dentro", Vector3(0, 0, 1))
	quad(Vector3(x0, 0, -DEEP), Vector3(x0, 0, z1), Vector3(x0, 4.2, z1), Vector3(x0, 4.2, -DEEP), "taller_dentro", Vector3(1, 0, 0))
	quad(Vector3(x1, 0, z1), Vector3(x1, 0, -DEEP), Vector3(x1, 4.2, -DEEP), Vector3(x1, 4.2, z1), "taller_dentro", Vector3(-1, 0, 0))
	quad(Vector3(x0, 3.6, -DEEP), Vector3(x1, 3.6, -DEEP), Vector3(x1, 3.6, z1), Vector3(x0, 3.6, z1), 0x3a3a3a, Vector3(0, -1, 0))
	for x in [1.6, 3.2, 4.8]:                                   # (the roof's steel, overhead)
		box(x, 3.4, z1, 0.12, 0.2, -z1 - DEEP, 0x2e2e30)
	# the bench along the party wall, its vice, the board of tools over it
	box(x0, 0.86, -4.6, 0.7, 0.06, 2.6, 0x6a4a30)
	for z in [-4.5, -2.15]:
		box(x0 + 0.05, 0.0, z, 0.6, 0.86, 0.06, 0x3a3c40)
	box(x0 + 0.3, 0.92, -2.6, 0.2, 0.18, 0.14, 0x2a5a8a)
	box(x0 + 0.01, 1.3, -4.4, 0.02, 0.9, 2.2, 0x6a5a40)
	for k in range(9):
		box(x0 + 0.03, 1.45 + (k % 3) * 0.26, -4.25 + int(k / 3.0) * 0.7, 0.04, 0.18, 0.04, [0xb02a2a, 0x9a9a9a, 0x2a2a2a][k % 3])
	# the batteries on their shelf at the back, the charger on its wheels, the tyres
	for y in [0.0, 0.6, 1.2]:
		box(1.2, y + 0.02, z1 + 0.02, 2.0, 0.04, 0.45, 0x5a5a5c)
		if y < 1.0:
			for k in range(5):
				box(1.28 + k * 0.38, y + 0.06, z1 + 0.08, 0.3, 0.22, 0.3, 0x1e1e20)
				box(1.32 + k * 0.38, y + 0.28, z1 + 0.18, 0.06, 0.03, 0.06, 0xc02a20)
	box(1.18, 0.0, z1 + 0.02, 0.04, 1.3, 0.45, 0x5a5a5c)
	box(3.18, 0.0, z1 + 0.02, 0.04, 1.3, 0.45, 0x5a5a5c)
	box(2.7, 0.18, -2.4, 0.55, 0.7, 0.45, 0xb8281e)
	box(2.78, 0.6, -1.96, 0.38, 0.2, 0.02, 0x2a2a2a)
	for x in [2.78, 3.17]:
		drum(Vector3(x, 0.0, -2.2), 0.09, 0.09, 0.05, 0x1a1a1a, 8)
	for k in range(4):
		drum(Vector3(4.9, k * 0.21, -5.4), 0.32, 0.32, 0.2, 0x1c1c1e, 14)
	box(x0, 0.0, -1.2, 0.04, 0.04, 0.04, 0x8a8a8a)

# ---------------- the blue bay ----------------
func _blue_bay() -> void:
	var x0 := T1
	var x1 := B1
	face(Vector2(x0, -SET), Vector2(x1, -SET))
	var L := x1 - x0
	var d0 := 0.28
	var d1 := L - 0.25
	_sheet(0.0, d0, FLOOR_N, TOP_N, 0.0)
	_sheet(d1, L, FLOOR_N, TOP_N, 0.0)
	_sheet(d0, d1, 4.05, TOP_N, 0.0)
	# the louvres over the door: pale slats in a frame
	box(d0, 3.36, -0.06, d1 - d0, 0.69, 0.06, 0x4a4c4e)
	for k in range(9):
		box(d0, 3.38 + k * 0.074, -0.02, d1 - d0, 0.05, 0.05, 0xdcdcd6)
	# the big door: two leaves of the same sheet, a little door in the left one, the frame and the handles
	_sheet(d0, (d0 + d1) / 2.0 - 0.01, FLOOR_N, 3.34, -0.05)
	_sheet((d0 + d1) / 2.0 + 0.01, d1, FLOOR_N, 3.34, -0.05)
	box(d0, 3.3, -0.04, d1 - d0, 0.06, 0.06, BLUE_DARK)
	box((d0 + d1) / 2.0 - 0.02, FLOOR_N, -0.03, 0.04, 3.34 - FLOOR_N, 0.06, BLUE_DARK)
	var pd := Rect2(d0 + 0.3, FLOOR_N + 0.05, 0.85, 2.0)
	for q in [[pd.position.x, pd.position.y, 0.03, pd.size.y], [pd.end.x - 0.03, pd.position.y, 0.03, pd.size.y], [pd.position.x, pd.end.y - 0.03, pd.size.x, 0.03]]:
		box(q[0], q[1], -0.02, q[2], q[3], 0.03, BLUE_DARK)
	box(pd.end.x - 0.14, 1.4, -0.02, 0.1, 0.04, 0.05, 0x9a9a9a)
	box((d0 + d1) / 2.0 - 0.12, 1.5, -0.02, 0.08, 0.2, 0.05, 0x9a9a9a)
	home()
	var yb := TOP_N + (RIDGE_N - TOP_N) * (DT - BACK + 0.4) / ((DN - BACK) / 2.0 + 0.4)       # (its roof in the nave's plane)
	_plain(Vector2(x0, -DT), Vector2(x0, -SET), 4.0, TOP_N, "blanco_viejo")       # (over the workshop's roof, facing it)
	_both(Vector2(x0, -DT), Vector2(x1, -DT), FLOOR_N - 0.3, yb, "ladrillo")
	_roof_sheet([Vector3(x0, TOP_N - 0.02, 0.38 - SET), Vector3(x1, TOP_N - 0.02, 0.38 - SET), Vector3(x1, yb, -DT), Vector3(x0, yb, -DT)])
	tri(Vector3(x0, TOP_N, -SET), Vector3(x0, yb, -DT), Vector3(x0, TOP_N, -DT), "blanco_viejo", Vector3(-1, 0, 0))

# ---------------- the nave ----------------
func _nave() -> void:
	face(Vector2(B1, -BACK), Vector2(N1, -BACK))
	var L := N1 - B1
	var loc := func(r: Rect2) -> Rect2: return Rect2(r.position.x - B1, r.position.y, r.size.x, r.size.y)
	var holes: Array = [loc.call(W1), loc.call(GATE), loc.call(W2), loc.call(DOOR_N), loc.call(W3)]
	openings += holes.size()
	masonry(0.0, L, -1.0, TOP_N, holes, [Rect2(0.0, -1.0, L, 1.0 + 1.3)], "ladrillo", "revoco")
	box(0.0, 1.3, 0.0, L, 0.035, 0.03, 0xc8b89c)                                # (the foot's edge)
	box(0.0, TOP_N - 0.22, 0.0, L, 0.22, 0.03, "ladrillo")                          # (a course of bricks on end under the eaves)
	for p in POSTS:                                                               # the blue steel posts
		box(float(p) - B1 - 0.08, -0.4, 0.0, 0.16, TOP_N + 0.4, 0.07, BLUE)
		box(float(p) - B1 - 0.02, -0.4, 0.07, 0.04, TOP_N + 0.4, 0.01, BLUE_DARK)
	# the windows: blue frames, a pale blind half down, blue bars before them
	for r: Rect2 in [loc.call(W1), loc.call(W2), loc.call(W3)]:
		window(r, 0x3a6ab0, 0x2a3640, 0)
		box(r.position.x + 0.06, r.position.y + r.size.y * 0.45, -DEEP + 0.1, r.size.x - 0.12, r.size.y * 0.55 - 0.06, 0.02, 0xe6e2d6)
		grille(r, 0.05, 0x3a6ab0)
		box(r.position.x - 0.06, r.position.y - 0.06, 0.0, r.size.x + 0.12, 0.06, 0.1, 0xd8d0c0)
	# the gate's opening: its frame; what is behind it (the door, the gate) comes and goes with the hours (_states)
	var g: Rect2 = loc.call(GATE)
	for x in [g.position.x, g.end.x - 0.05]:
		box(x, g.position.y, -0.06, 0.05, g.size.y, 0.06, 0x8a8c8e)
	box(g.position.x, g.end.y - 0.05, -0.06, g.size.x, 0.05, 0.06, 0x8a8c8e)
	box(g.position.x - 0.03, g.position.y - 0.03, -DEEP, g.size.x + 0.06, 0.042, DEEP + 0.02, 0x9a9890)
	var gin := -2.4                     # (the way in: a passage into the obrador, its steel table at the end)
	quad(Vector3(g.position.x, g.position.y, gin), Vector3(g.end.x, g.position.y, gin), Vector3(g.end.x, g.end.y + 0.3, gin), Vector3(g.position.x, g.end.y + 0.3, gin), "interior", Vector3(0, 0, 1))
	box(g.position.x, g.position.y - 0.03, gin, g.size.x, 0.03, -gin - DEEP, 0x8a8880)           # (the floor and the head of the way in)
	quad(Vector3(g.position.x, g.end.y + 0.3, -DEEP), Vector3(g.end.x, g.end.y + 0.3, -DEEP), Vector3(g.end.x, g.end.y + 0.3, gin), Vector3(g.position.x, g.end.y + 0.3, gin), 0x8e8a80, Vector3(0, -1, 0))
	quad(Vector3(g.position.x, g.end.y, -DEEP), Vector3(g.end.x, g.end.y, -DEEP), Vector3(g.end.x, g.end.y + 0.3, -DEEP), Vector3(g.position.x, g.end.y + 0.3, -DEEP), 0x8e8a80, Vector3(0, 0, -1))
	for x in [g.position.x, g.end.x]:
		quad(Vector3(x, g.position.y, -DEEP), Vector3(x, g.position.y, gin), Vector3(x, g.end.y + 0.3, gin), Vector3(x, g.end.y + 0.3, -DEEP), 0x9a958a, Vector3(1 if x == g.position.x else -1, 0, 0))
	box(g.position.x + 0.05, g.position.y, gin + 0.02, g.size.x - 0.1, 0.88, 0.62, 0x7c8084)
	box(g.position.x + 0.03, g.position.y + 0.88, gin + 0.02, g.size.x - 0.06, 0.04, 0.66, 0xc4c8cc)
	for i in range(3):
		box(g.position.x + 0.12 + i * 0.3, g.position.y + 0.92, gin + 0.12, 0.26, 0.04, 0.36, 0xb8925a)
	# the big door: two leaves of blue sheet, its handles, a lamp over it, the little box of the alarm
	var d: Rect2 = loc.call(DOOR_N)
	var mid := d.get_center().x
	_sheet(d.position.x, mid - 0.01, d.position.y, d.end.y, -0.1)
	_sheet(mid + 0.01, d.end.x, d.position.y, d.end.y, -0.1)
	box(mid - 0.02, d.position.y, -0.08, 0.04, d.size.y, 0.06, BLUE_DARK)
	box(d.position.x, d.end.y - 0.06, -0.09, d.size.x, 0.06, 0.06, BLUE_DARK)
	box(mid - 0.16, 1.6, -0.06, 0.1, 0.22, 0.05, 0x9a9a9a)
	box(d.position.x - 0.04, d.position.y - 0.03, -DEEP, d.size.x + 0.08, 0.042, DEEP + 0.02, 0x9a9890)
	var lx := mid + 0.3
	bar(Vector3(lx, 4.28, 0.0), Vector3(lx - 0.05, 4.5, 0.55), 0.04, 0.04, 0x3a3a3c)
	box(lx - 0.18, 4.4, 0.42, 0.26, 0.1, 0.28, 0x3a3a3c)
	box(lx - 0.16, 4.38, 0.44, 0.22, 0.02, 0.24, "luz")
	W.lamp_spots.append(transform * Vector3(B1 + lx - 0.05, 4.3, 0.75 - BACK))
	box(d.position.x - 0.7, 3.6, 0.0, 0.18, 0.26, 0.08, 0xe8e6e0)
	box(d.position.x - 0.66, 3.66, 0.08, 0.1, 0.06, 0.01, 0xc03020)
	# the eaves: corrugated fibre-cement over the front, its gutter, the white downpipe by the big door's west post
	box(-0.05, TOP_N - 0.02, 0.32, L + 0.1, 0.1, 0.07, 0xb8b6b0)                  # (the gutter)
	bar(Vector3(POSTS[2] - B1 - 0.3, TOP_N, 0.38), Vector3(POSTS[2] - B1 - 0.3, 0.0, 0.06), 0.09, 0.09, 0xf0f0ec)
	home()
	var yr := RIDGE_N
	var zr := (-BACK - DN) / 2.0
	_roof_sheet([Vector3(B1, TOP_N, 0.4 - BACK), Vector3(N1 + 0.05, TOP_N, 0.4 - BACK), Vector3(N1 + 0.05, yr, zr), Vector3(B1, yr, zr)])
	_roof_sheet([Vector3(B1, yr, zr), Vector3(N1 + 0.05, yr, zr), Vector3(N1 + 0.05, TOP_N, -DN - 0.35), Vector3(B1, TOP_N, -DN - 0.35)])
	bar(Vector3(B1, yr + 0.06, zr), Vector3(N1 + 0.05, yr + 0.06, zr), 0.3, 0.1, 0x9a9894)
	box(B1, TOP_N - 0.04, -BACK, L + 0.05, 0.05, 0.4, 0x8a8884)                       # (under the eaves' edge)
	# its walls round the back: brick, the gables over the neighbours
	_both(Vector2(B1, -DT), Vector2(B1, -DN), -0.5, TOP_N, "ladrillo")
	_both(Vector2(N1 - 0.025, -DH), Vector2(N1 - 0.025, -DN), -0.5, TOP_N, "ladrillo")
	_both(Vector2(N1 - 0.025, -BACK), Vector2(N1 - 0.025, -DH), TOP_P - 0.3, TOP_N, "ladrillo")     # (over the pier's roof)
	_both(Vector2(N1 - 0.025, -DN), Vector2(B1, -DN), -0.5, TOP_N, "ladrillo")
	for x in [B1, N1 - 0.025]:
		tri(Vector3(x, TOP_N, -BACK), Vector3(x, yr, zr), Vector3(x, TOP_N, -DN), "ladrillo", Vector3(-1 if x == B1 else 1, 0, 0))
		tri(Vector3(x, TOP_N, -BACK), Vector3(x, yr, zr), Vector3(x, TOP_N, -DN), "ladrillo", Vector3(1 if x == B1 else -1, 0, 0))

# ---------------- the pier, the flue ----------------
func _pier() -> void:
	var pz := 0.2
	# its side to the south-west, out before the nave: the sweet maker's board faces those who come up the avenue
	# from the roundabout (the user, 27 Nov 2026: "está en la fachada lateral de la casa blanca, por los que vienen
	# conduciendo desde la rotonda vean el cartel de frente"); the meters in their recess under it, over the parapet's
	# end; the white box of the wires by the corner, its cable round it to the pole
	var Ls := face(Vector2(N1, -BACK), Vector2(N1, pz))
	var meters := Rect2(1.55, 1.12, 0.95, 0.62)
	masonry(0.0, Ls, -1.0, TOP_P, [meters], [], "blanco_viejo", "blanco_viejo")
	box(-0.02, TOP_P + 0.005, -0.05, Ls + 0.04, 0.06, 0.12, 0xdedcd4)
	sign_board(0.35, 1.95, 1.95, 1.38, 0.0, 0.025, 0xe6e4dc, "dulces", 0.02, 0.014)
	# the meters in their recess, their wires, the white box of the wires up by its north end
	quad(Vector3(meters.position.x, meters.position.y, -DEEP + 0.02), Vector3(meters.end.x, meters.position.y, -DEEP + 0.02),
		Vector3(meters.end.x, meters.end.y, -DEEP + 0.02), Vector3(meters.position.x, meters.end.y, -DEEP + 0.02), 0x6a6458, Vector3(0, 0, 1))
	for k in range(3):
		var mx: float = meters.position.x + 0.08 + k * 0.3
		box(mx, meters.position.y + 0.18, -DEEP + 0.03, 0.2, 0.32 if k < 2 else 0.24, 0.12, [0xd8d8d0, 0xc8c8c2, 0x8a8a86][k])
		box(mx + 0.04, meters.position.y + 0.38, -DEEP + 0.15, 0.12, 0.06, 0.005, 0x2a3a3a)
	box(meters.position.x - 0.03, meters.position.y - 0.03, -0.02, meters.size.x + 0.06, 0.042, 0.05, 0xc8c6be)
	box(Ls - 0.42, 2.95, 0.0, 0.34, 0.5, 0.16, 0xf2f2ee)
	home()
	bar(Vector3(N1 - 0.12, 3.0, pz - 0.25), Vector3(N1 - 0.06, 2.95, pz + 0.07), 0.025, 0.025, 0x1a1a1c)
	bar(Vector3(N1 - 0.06, 2.95, pz + 0.07), Vector3(H0 - 0.4, 2.7, 0.3), 0.025, 0.025, 0x1a1a1c)
	# its front to the avenue, plain; its north side and the white wall between it and the house
	face(Vector2(N1, pz), Vector2(P1, pz))
	var L := P1 - N1
	masonry(0.0, L, -1.0, TOP_P, [], [], "blanco_viejo", "blanco_viejo")
	box(-0.02, TOP_P, -0.05, L + 0.04, 0.06, 0.12, 0xdedcd4)
	home()
	_plain(Vector2(P1, pz), Vector2(P1, 0.0), -1.0, TOP_P, "blanco_viejo")
	face(Vector2(P1, 0.0), Vector2(H0, 0.0))
	masonry(0.0, H0 - P1, -1.0, TOP_P, [], [], "blanco_viejo", "blanco_viejo")
	box(-0.02, TOP_P, -0.05, H0 - P1 + 0.04, 0.06, 0.1, 0xdedcd4)
	home()
	_plain(Vector2(H0, 0.0), Vector2(H0, -DH), TOP_H - 0.45, TOP_P, "blanco_viejo")
	# the oven's flue behind: rust below, grey above, its cap
	var f := Vector3(P1 + 0.55, 2.6, -1.1)
	drum(f, 0.12, 0.12, 1.9, 0x8a4a2a, 10)
	drum(f + Vector3(0, 1.9, 0), 0.11, 0.11, 1.7, 0x8a8c8e, 10)
	drum(f + Vector3(0, 3.6, 0), 0.2, 0.0, 0.18, 0x6a6c6e, 10)
	for k in range(3):
		bar(f + Vector3(0, 3.62, 0), f + Vector3(0.15 * cos(k * 2.1), 3.62, 0.15 * sin(k * 2.1)), 0.015, 0.015, 0x5a5a5c)

# ---------------- the white house and the store ----------------
func _house() -> void:
	face(Vector2(H0, 0.0), Vector2(H1, 0.0))
	var L := H1 - H0
	var w: Rect2 = Rect2(WIN_H.position.x - H0, WIN_H.position.y, WIN_H.size.x, WIN_H.size.y)
	var dr: Rect2 = Rect2(DOOR_H.position.x - H0, DOOR_H.position.y, DOOR_H.size.x, DOOR_H.size.y)
	masonry(0.0, L, -1.0, TOP_H, [w, dr], [], "blanco_viejo", "blanco_viejo")
	openings += 2
	for run in [[0.0, dr.position.x], [dr.end.x, L]]:                            # its foot of salmon tiles
		_tiled(run[0], run[1], -0.3, 0.42, 0.014, "baldosa_salmon", 1.0, 0.4)
		box(run[0], 0.42, 0.0, run[1] - run[0], 0.025, 0.02, 0xd8c8b8)
	# the window: its brown blind down, black bars before it, a sill
	window(w, 0x6a4a30, 0x2a3640, 0)
	box(w.position.x + 0.04, w.position.y + 0.04, -DEEP + 0.1, w.size.x - 0.08, w.size.y - 0.08, 0.02, 0x5a3a26)
	for k in range(1, int(w.size.y / 0.06)):
		box(w.position.x + 0.04, w.position.y + k * 0.06, -DEEP + 0.12, w.size.x - 0.08, 0.008, 0.004, 0x46301e)
	grille(w, 0.08, 0x26262a)
	box(w.position.x - 0.06, w.position.y - 0.05, 0.0, w.size.x + 0.12, 0.05, 0.1, 0xe0ded6)
	# the door: brown wood, a panel of frosted glass, a white surround, the step
	box(dr.position.x, 0.0, -DEEP + 0.03, dr.size.x, dr.size.y, 0.05, 0x5a3a24)
	box(dr.position.x + 0.14, 0.75, -DEEP + 0.08, dr.size.x - 0.28, 1.2, 0.01, "vidrio_puerta")
	for y in [0.75, 1.15, 1.55]:
		box(dr.position.x + 0.14, y, -DEEP + 0.09, dr.size.x - 0.28, 0.025, 0.01, 0x5a3a24)
	box(dr.end.x - 0.14, 1.0, -DEEP + 0.08, 0.04, 0.12, 0.05, 0xc0a040)
	door_frame(dr, 0.1, 0.03, 0xf2f2ee)
	box(dr.position.x - 0.1, -0.05, -0.02, dr.size.x + 0.2, 0.06, 0.18, 0xb0a89a)
	# its roof edge: a dark sheet a little out over the front
	home()
	_roof_sheet([Vector3(H0 - 0.02, TOP_H + 0.02, 0.18), Vector3(H1, TOP_H + 0.02, 0.18), Vector3(H1, 2.6, -DH), Vector3(H0 - 0.02, 2.6, -DH)], "chapa_tejado")
	# the store beyond: a beige wall to the corner's yard wall, a patch of older render, a flat roof
	face(Vector2(H1, 0.0), Vector2(E - 0.025, 0.0))
	var L2 := E - 0.025 - H1
	masonry(0.0, L2, -1.0, 2.95, [], [], "beige", "beige")
	plinth(0.0, L2, 0.3, 0.3, 0xb8a888, 0.03, -1.0)
	box(1.6, 0.6, 0.0, 1.3, 0.5, 0.012, 0xc8b898)
	box(-0.02, 2.95, -0.05, L2 + 0.04, 0.08, 0.1, 0xc8b898)
	box(L2 - 1.0, 1.4, 0.0, 0.3, 0.4, 0.08, 0xe8e6e0)
	home()
	_plain(Vector2(H1, 0.0), Vector2(H1, -DH), 2.6, TOP_H, "blanco_viejo")
	flat(PackedVector2Array([Vector2(H1, -0.05), Vector2(E - 0.025, -0.05), Vector2(E - 0.025, -DH), Vector2(H1, -DH)]), 2.9, 0x6a6660)
	# the row's back and its north end over the corner's yard
	_both(Vector2(N1, -DH), Vector2(H0, -DH), -0.5, TOP_P, "blanco_viejo")
	_both(Vector2(H0, -DH), Vector2(H1, -DH), -0.5, 2.6, "blanco_viejo")
	_both(Vector2(H1, -DH), Vector2(E - 0.025, -DH), -0.5, 2.95, "beige")
	_plain(Vector2(E - 0.025, 0.0), Vector2(E - 0.025, -DH), 2.8, 3.0, "beige")
	flat(PackedVector2Array([Vector2(N1, -0.05), Vector2(H0, -0.05), Vector2(H0, -DH), Vector2(N1, -DH)]), TOP_P - 0.05, 0x8a8680)

# ---------------- before the nave: the parapets, the walks, the ramps ----------------
func _forecourt() -> void:
	var g0 := B1 + 0.3                       # the parapet with the roses: from the blue bay's ramp...
	var g1 := float(POSTS[2]) - 0.45         # ...to the big door's ramp
	var r0 := float(POSTS[2]) - 0.45         # the big door's ramp
	var r1 := DOOR_N.end.x + 0.4
	var w2 := N1                             # the low wall beyond, to the pier's side
	var zn := -BACK                          # (the nave's front)
	var zw := ZW                             # the parapets' face, out from it
	var top := 0.78
	for run in [[g0, g1, true], [r1, w2, false]]:
		var a: float = run[0]
		var b: float = run[1]
		var west: bool = run[2]
		box(a, ground(a, zn + zw) - 0.4, zn + zw - 0.25, b - a, top - ground(a, zn + zw) + 0.4, 0.25, "blanco_viejo")
		box(a - 0.02, top, zn + zw - 0.27, b - a + 0.04, 0.04, 0.29, 0xe2e0d8)
		# its end: by the blue bay's ramp (the first), against the pier (the second); the other end open to the big
		# door's ramp
		var ex := a if west else b - 0.2
		var ez := 0.0 if west else 0.2
		box(ex, ground(ex, zn + zw) - 0.4, zn + ez, 0.2, top - ground(ex, zn + zw) + 0.4, zw - 0.25 - ez, "blanco_viejo")
		box(ex - 0.02, top, zn + ez, 0.24, 0.04, zw - 0.25 - ez, 0xe2e0d8)
		solid(Vector3((a + b) / 2.0, 0.4, zn + zw - 0.12), Vector3(b - a, 0.8 + 0.4, 0.25))
		yard.append(spot(a, zn + zw))
		yard.append(spot(b, zn + zw))
		# the walk behind it, at the nave's floor
		var w0 := a + 0.2 if west else a
		var w1 := b if west else b - 0.2
		var pts := [Vector3(w0, FLOOR_N, zn), Vector3(w1, FLOOR_N, zn), Vector3(w1, FLOOR_N, zn + zw - 0.25), Vector3(w0, FLOOR_N, zn + zw - 0.25)]
		_deck(pts, "cemento", false)
	# the roses, in their pits along the wall behind the parapet (none before the gate)
	for x in [B1 + 0.9, B1 + 2.2, GATE.end.x + 0.6, POSTS[2] - 1.0]:
		box(x - 0.3, FLOOR_N, zn + 0.08, 0.6, 0.02, 0.5, "tierra")
		_rose(Vector3(x, FLOOR_N, zn + 0.35))
	var bx := g1 - 0.4                                                            # (one out before the parapet's end, by the pipe)
	_rose(Vector3(bx, ground(bx, zn + zw + 0.32), zn + zw + 0.32), 0.7)
	yard.append(spot(bx, zn + zw + 0.32))
	# the ramps: before the blue bay's door, before the big door
	var zf := ZF
	_deck([Vector3(T1 + 0.05, FLOOR_N, zn + 0.02), Vector3(B1 + 0.3, FLOOR_N, zn + 0.02), Vector3(B1 + 0.3, ground(B1, zf) + 0.02, zf), Vector3(T1 + 0.05, ground(T1, zf) + 0.02, zf)], "cemento", true)
	_deck([Vector3(r0, FLOOR_N, zn + 0.02), Vector3(r1, FLOOR_N, zn + 0.02), Vector3(r1, ground(r1, zf) + 0.02, zf), Vector3(r0, ground(r0, zf) + 0.02, zf)], "cemento", true)
	yard.append(spot(T1 + 0.05, zf))
	yard.append(spot(r1, zf))

## a rose bush: a round of dark leaves, its red flowers
func _rose(at: Vector3, k := 1.0) -> void:
	ball(at + Vector3(0, 0.45 * k, 0), 0.45 * k, 0x2f5a2a, 0.85, 9, 5)
	ball(at + Vector3(0.15, 0.62 * k, 0.1), 0.3 * k, 0x3a6a32, 0.8, 8, 4)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(at.x * 10.0)
	for i in range(7):
		var a := rng.randf() * TAU
		var y := rng.randf_range(0.35, 0.85) * k
		ball(at + Vector3(cos(a) * 0.4 * k, y, sin(a) * 0.4 * k), 0.06, [0xc81e2a, 0xe0465a, 0xb01826][i % 3], 1.0, 6, 3)

## A piece of floor that people walk on: its corners (x, y, z) in order round it, all in one plane. Its top, its sides
## down into the ground, what holds it up, and the map told (a sloping one with its "grad").
func _deck(pts: Array, key, sides: bool) -> void:
	pieces += 1
	var flatp := PackedVector2Array()
	var mid := 0.0
	for q: Vector3 in pts:
		flatp.append(Vector2(q.x, q.z))
		mid += q.y / float(pts.size())
	var uv: Array = []
	for q: Vector3 in pts:
		uv.append(Vector2(q.x, q.z) / 1.6)
	quad(pts[0], pts[1], pts[2], pts[3], key, Vector3.UP, uv)
	if sides:
		for i in [1, 3]:
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[(i + 1) % 4]
			var ga := ground(a.x, a.z) - 0.3
			var gb := ground(b.x, b.z) - 0.3
			quad(Vector3(a.x, ga, a.z), Vector3(b.x, gb, b.z), b, a, key, Vector3(1 if i == 1 else -1, 0, 0))
	var all: Array = []
	for q: Vector3 in pts:
		all.append(q)
		all.append(Vector3(q.x, minf(q.y, ground(q.x, q.z)) - 0.6, q.z))
	_hull(all)
	var n: Vector3 = ((pts[1] as Vector3) - (pts[0] as Vector3)).cross((pts[2] as Vector3) - (pts[0] as Vector3))
	if n.y < 0.0:
		n = -n
	var dk := _poly_deck(flatp, level + mid)
	if absf(n.x) > 0.00001 or absf(n.z) > 0.00001:
		dk["grad"] = EU * (-n.x / n.y) + EV * (-n.z / n.y)
	decks.append(dk)
	MapData.decks.append(dk)

## the ground before the row, from its fronts to the town's pavement (the map leaves it bare earth there): concrete
## before the workshop, the blue bay and the big door, where cars and the tractor stand, small grey tiles before the
## parapets, the pier and the house (Street View 2024); the tree's pit with its kerb
func _apron() -> void:
	var g1 := float(POSTS[2]) - 0.45
	var r1 := DOOR_N.end.x + 0.4
	# [from, to, how far out from the front it starts, what it is]
	var runs := [[0.0, T1 + 0.05, 0.0, "solera"], [T1 + 0.05, B1 + 0.3, ZF, "solera"], [B1 + 0.3, g1, ZW - BACK, "acera"],
		[g1, r1, ZF, "solera"], [r1, N1, ZW - BACK, "acera"], [N1, E, 0.0, "acera"]]
	for run in runs:
		var a: float = run[0]
		var b: float = run[1]
		var v0: float = run[2]
		var n := maxi(1, ceili((b - a) / 0.6))
		pieces += 1
		for i in range(n):
			var ua := lerpf(a, b, float(i) / n)
			var ub := lerpf(a, b, float(i + 1) / n)
			var ea := _pave_edge(ua)
			var eb := _pave_edge(ub)
			if ea <= v0 + 0.05 and eb <= v0 + 0.05:
				continue
			ea = maxf(ea, v0 + 0.05)
			eb = maxf(eb, v0 + 0.05)
			for j in range(3):
				var ta := lerpf(v0, ea, j / 3.0)
				var ta2 := lerpf(v0, ea, (j + 1) / 3.0)
				var tb := lerpf(v0, eb, j / 3.0)
				var tb2 := lerpf(v0, eb, (j + 1) / 3.0)
				quad(Vector3(ua, ground(ua, ta) + 0.025, ta), Vector3(ub, ground(ub, tb) + 0.025, tb), Vector3(ub, ground(ub, tb2) + 0.025, tb2),
					Vector3(ua, ground(ua, ta2) + 0.025, ta2), run[3], Vector3.UP)
	# the tree's square pit, a kerb round its earth
	var tp := Vector2(10.2, 2.4)
	var gy := ground(tp.x, tp.y)
	for k in [[-0.5, -0.5, 1.0, 0.08], [-0.5, 0.42, 1.0, 0.08], [-0.5, -0.42, 0.08, 0.84], [0.42, -0.42, 0.08, 0.84]]:
		box(tp.x + k[0], gy - 0.05, tp.y + k[1], k[2], 0.15, k[3], 0xb8b4aa)
	box(tp.x - 0.42, gy - 0.05, tp.y - 0.42, 0.84, 0.085, 0.84, "tierra")

## how far out from the row's front the town's pavement begins at `u` along it (its ribbon along the street: MapData.sunk)
func _pave_edge(u: float) -> float:
	var v := 0.0
	while v < 6.0:
		if MapData.sunk(spot(u, v), true) < 0.0:
			return v + 0.3              # (over the pavement's sunk edge, which shows the earth)
		v += 0.05
	return 0.0

# ---------------- in the street ----------------
func _street() -> void:
	# the tree before the workshop (a pavement tree of the town's, to be knocked down like the rest)
	var tp := spot(10.2, 2.4)
	W.add_trees([[tp.x, tp.y, 0, 0.8, 0.6]])
	yard.append(tp)
	# the beige bin with a green lid before the pier (props.gd stands it there)
	var bp := spot(N1 + 1.0, 2.2)
	W.extra_props.append(["container", bp, atan2(-EV.x, -EV.y), 0])
	yard.append(bp)
	# the pole by the house, against its wall: concrete, a little crossarm at its top
	var px := H0 - 0.25
	drum(Vector3(px, ground(px, 0.32) - 0.3, 0.32), 0.15, 0.1, 9.3, 0xb8ae9a, 10)
	box(px - 0.6, 8.6, 0.27, 1.2, 0.1, 0.1, 0x7a746a)
	for x in [px - 0.5, px + 0.5]:
		drum(Vector3(x, 8.7, 0.32), 0.03, 0.03, 0.1, 0xe0e0e0, 6)
	solid(Vector3(px, 3.0, 0.32), Vector3(0.28, 6.0, 0.28))
	yard.append(spot(px, 0.32))

# ---------------- shut and open ----------------
## what changes with the hours: the workshop's sliding leaf (shut) or its tube lit (open); the sweet maker's scissor
## gate across (shut) or folded (open), its door shut or in, its light
func _states() -> void:
	var o0 := BAY.position.x
	_taller_shut = Node3D.new()
	add_child(_taller_shut)
	_sheet(o0 + 0.02, OPEN_X - 0.04, 0.0, BAY.end.y - 0.18, -0.07)
	box(o0 + 0.02, BAY.end.y - 0.2, -0.09, OPEN_X - o0 - 0.06, 0.06, 0.06, 0x5a5c60)
	box(o0 + 0.4, 1.0, -0.04, 0.12, 0.06, 0.04, 0x9a9a9a)
	_commit_to(_taller_shut)
	_taller_lit = Node3D.new()
	add_child(_taller_lit)
	box(1.2, 3.2, -3.0, 1.5, 0.06, 0.1, "luz")
	box(3.6, 3.2, -4.6, 1.5, 0.06, 0.1, "luz")
	_commit_to(_taller_lit)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(2.4, 2.8, -2.6)
	lamp.light_color = Color(0.92, 0.95, 1.0)
	lamp.omni_range = 5.5
	lamp.light_energy = 0.9
	lamp.shadow_enabled = false
	_taller_lit.add_child(lamp)
	var g := GATE
	_dulces_shut = Node3D.new()
	add_child(_dulces_shut)
	_door_leaf(g.position.x + 0.05, g.end.x - 0.05, -BACK - DEEP + 0.06)
	_tiled(g.position.x + 0.05, g.end.x - 0.05, g.position.y + 0.03, g.end.y - 0.06, -BACK - 0.035, "tijera", 0.26, 0.26)
	box(g.position.x + 0.05, g.end.y - 0.1, -BACK - 0.05, g.size.x - 0.1, 0.05, 0.04, 0x9a9c9e)
	box(g.position.x + 0.05, g.position.y + 0.02, -BACK - 0.05, g.size.x - 0.1, 0.04, 0.04, 0x9a9c9e)
	_commit_to(_dulces_shut)
	_dulces_lit = Node3D.new()
	add_child(_dulces_lit)
	_tiled(g.position.x + 0.05, g.position.x + 0.22, g.position.y + 0.03, g.end.y - 0.06, -BACK - 0.035, "tijera", 0.06, 0.26)
	var keep := _xf
	_xf = keep * Transform3D(Basis(Vector3.UP, -PI / 2.0), Vector3(g.end.x - 0.05, 0.0, -BACK - DEEP + 0.06))
	_door_leaf(-(g.size.x - 0.1), 0.0, 0.0)
	_xf = keep
	_commit_to(_dulces_lit)
	var warm := OmniLight3D.new()
	warm.position = Vector3(g.get_center().x, 2.2, -BACK - 1.6)        # (inside the way in: the obrador's light falling out)
	warm.light_color = Color(1.0, 0.88, 0.68)
	warm.omni_range = 2.6
	warm.light_energy = 0.35
	warm.shadow_enabled = false
	_dulces_lit.add_child(warm)

## the sweet maker's door: a white frame of aluminium, glass over a low panel
func _door_leaf(x0: float, x1: float, z: float) -> void:
	var y0 := FLOOR_N
	var h := GATE.size.y - 0.08
	for x in [x0, x1 - 0.06]:
		box(x, y0, z - 0.03, 0.06, h, 0.05, 0xe8e8e4)
	for y in [y0, y0 + 0.6, y0 + h - 0.06]:
		box(x0, y, z - 0.03, x1 - x0, 0.06 if y > y0 else 0.6, 0.05, 0xe8e8e4)
	quad(Vector3(x0 + 0.06, y0 + 0.66, z), Vector3(x1 - 0.06, y0 + 0.66, z), Vector3(x1 - 0.06, y0 + h - 0.06, z), Vector3(x0 + 0.06, y0 + h - 0.06, z), "vidrio", Vector3(0, 0, 1))
	box(x1 - 0.16, y0 + 1.0, z + 0.02, 0.03, 0.2, 0.04, 0xc9ccd0)

## what has been built since the last commit becomes meshes under `node`: a part that can be shown and hidden
func _commit_to(node: Node3D) -> void:
	for key in _tools:
		var mi := MeshInstance3D.new()
		mi.mesh = (_tools[key] as SurfaceTool).commit()
		mi.material_override = _material(key)
		node.add_child(mi)
	_tools.clear()

## its solids: the workshop, the blue bay, the nave, the pier and the house with the store (the walks and the ramps are
## floors: _deck; the parapets and the pole their own)
func _solids_all() -> void:
	solid(Vector3(T1 / 2.0, 2.5, -DT / 2.0), Vector3(T1 - 0.05, 5.0 + 1.0, DT))
	solid(Vector3((T1 + B1) / 2.0, 2.4, -SET - (DT - SET) / 2.0), Vector3(B1 - T1, 4.8 + 1.0, DT - SET))
	solid(Vector3((B1 + N1) / 2.0, 2.4, (-BACK - DN) / 2.0), Vector3(N1 - B1 - 0.05, 4.8 + 1.0, DN - BACK))
	solid(Vector3((N1 + E) / 2.0, 1.8, -DH / 2.0 + 0.1), Vector3(E - N1 - 0.05, 3.6 + 1.0, DH + 0.2))

func set_open(t: bool, d: bool) -> void:
	taller_open = t
	dulces_open = d
	if _taller_shut != null:
		_taller_shut.visible = not t
		_taller_lit.visible = t
		_dulces_shut.visible = not d
		_dulces_lit.visible = d
	if _mats.has("interior"):
		(_mats["interior"] as StandardMaterial3D).emission_energy_multiplier = 0.14 if d else 0.03      # (a dim glow from the obrador when open: in the photographs the way in is dark)

func _process(_delta: float) -> void:
	var game = W.get_parent() if W != null else null
	if game != null and "clock" in game and "weekday" in game:
		var t: bool = open_taller(int(game.weekday), float(game.clock))
		var d: bool = open_dulces(int(game.weekday), float(game.clock))
		if t != taller_open or d != dulces_open:
			set_open(t, d)
