extends "res://scripts/esquina.gd"
## The Plaza de Jesús Requejo: the Red Cross's building and the park behind it, the whole block between the Avenida de
## Juan Carlos I, the Calle de Don Jesús Requejo, the Calle de las Viñas and the street west of it (the user, 23
## November 2026, with a picture of the block drawn round in red: "Ahora la cruz roja y el parque que tiene detrás, los
## dos lados de la misma manzana. Tiene varias 360 así que debería ser fácil"). Built by hand on Texturas's house of the
## map (vin_jr3, Catastro 3890502VJ5639S, handed over as ["obra"]: the bake had made its three parts one low white box),
## with no rebake; referencias/requejo/. From Street View of November 2024 (and 2009, 2013, 2019, 2021), the IGN's
## aerial (tools/ign/cruzroja.jpg) and Catastro.
##
## The game shows no real organisation's name or emblem: it is the "Cruz Verde", with a green cross (the user, the same
## day: "Que llamaremos la cruz verde. La plaza puede mantener el nombre"; the square keeps its real name). The town is "MADRIDEJOS" on its signs (Matritellus is the game's title). No number, telephone or party's sign on it.
##
##   - the block of flats (Catastro: three floors, 21.1 x 9.3 m): cream render on a foot of brown rubble, brick
##     pilasters at its corners, a brick band at the first floor, a hipped roof of old tiles over a brick cornice. To the
##     avenue (north) it has eight windows a floor with brick heads and sills, brown roller blinds at all heights,
##     grilles on the ground floor's; in the middle a bay of brick with the door, the balcony (the board with the cross
##     on its railing, two glass doors behind it) and two windows; a plaque, a little sign, a street lamp on its bracket,
##     air conditioners, cables, aerials and two chimney pipes on the roof. The sides and the back are plain render with
##     the same pilasters and band (the back with its windows over the wings);
##   - two low white wings behind it (one floor; Catastro, as the aerial shows them now), a narrow yard between them. The
##     west one is the office: its door behind an iron gate, the cross and the name painted on the wall, two windows
##     behind grilles, a brown garage door; the east one has a grey garage door, a grey cement foot and a window behind
##     a grille. Their roofs: flat at the north, tiles at the south, behind their parapets; their tops follow the
##     ground (the game's falls 2.5 times as much as the real one). The south walls of both and the yard's are one: the mural of a painted town over the park (our own drawing);
##   - before the front (north), the bare earth of the square where its trees were (2013), the town's red plastic
##     barriers round what is left, a young tree; along the east side, earth and weeds down to the pavement;
##   - behind (south), the park: a walk of grey setts along the mural with its iron benches and a bin, the kerbed lawn
##     with five tamarisks, a notice board at its end, the big tree in its pit on the west pavement and the no-entry
##     sign by it.
##   - the transformer hut on the square's corner to the avenue (Texturas's requejo_1, handed over as ["obra"] the same
##     day after the user saw the plain white box of the bake: "este edificio no se parece nada"): a tall white box
##     with a gabled roof of old tiles, its grey sheet-metal door, the louvre high up, the plates, the cables and the
##     street lamp at its corners.
##
## Frame: the map's own (x east, z south), y = 0 the ground before the front door. Each front is built in its own
## frame (obra.face: +x along it, its left end seen from the street first; +z out of it).

const READY := true
const HOUSE := "vin_jr3"
const NAME := "Cruz Verde"                        # (the user's name for it; tools/requejo/dibujos.py draws it)
const DIR := "res://assets/requejo/"

# the block of flats (Catastro 3890502VJ5639S, part 1), in the ring's order
const A := Vector2(-439.19, 178.14)               # its corner to the avenue and the west street
const B := Vector2(-418.13, 179.63)               # to the avenue and the Calle de Don Jesús Requejo
const C := Vector2(-418.53, 188.70)               # its back corner on the Requejo
const F := Vector2(-439.81, 187.49)               # its back corner on the west street
# the wings (parts 2 and 3; their inner sides where the aerial shows them now, a yard between them)
const G := Vector2(-440.68, 200.63)               # the west wing's corner to the park (the mural's west end)
const S := Vector2(-419.11, 201.68)               # the east wing's (the mural's east end)
const WX := -431.2                                # the west wing's yard side...
const EX := -428.6                                # ...and the east wing's
const ROOFS_Z := 192.4                            # their roofs: flat north of this, tiles south of it

const TOP := 9.6                # the top of its walls, under the cornice (Street View: 9.6 m over the door's step)
const EAVE := 0.42
const PITCH := 0.5
const RISE0 := 0.21             # (EAVE * PITCH)
const PLINTH := 0.85            # the rubble foot, up to here (level all round, as the real one)
const BAND := 3.22              # the brick band at the first floor, from here...
const BAND_H := 0.16            # ...this high
const PIL := 0.7                # the brick pilasters at its corners
const SILLS := [1.04, 4.16, 7.2]                  # its windows' sills, a floor each...
const WIN_H := 1.85                               # ...how high they are
const WIN_W := 1.1
const COLS := [2.2, 5.0, 7.7, 13.41, 16.11, 18.91]            # the front's windows (their middles, from its east end)
const BAY := Vector2(9.05, 12.05)                             # the bay of brick in its middle...
const BAY_WIN := [9.89, 11.21]                                # ...its two windows (glass doors on the balcony)
const DOOR := Rect2(9.8, 0.0, 1.5, 2.55)
const BACK_COLS := [2.2, 5.0, 7.7, 10.65, 13.6, 16.3, 19.1]  # the back's (from its west end)
const WING_H := 3.2             # the wings' walls, this high over the ground at the block's back corners and at the office's corner to the park
const PARAPET := 0.45           # their roofs lie this far under it
# the office's west front (from its north end)
const OF_DOOR := Rect2(0.8, 0.0, 1.2, 2.3)
const OF_WIN := [2.9, 5.1]                        # its windows (their left sides)
const OF_GARAGE := Vector2(7.95, 11.95)
# the east wing's front (from its south end)
const EW_GARAGE := Vector2(0.45, 4.1)
const EW_WIN := 9.6

const FRAME := 0x5a3c2a         # brown aluminium
const GLASS := 0x26323a
const BLIND := 0x5f4434         # the brown roller blinds
const IRON_ := 0x26262a
const BARRIER := 0xd8262e       # the red plastic barriers

# the park (map metres)
const WALK := [Vector2(-443.6, 200.7), Vector2(-440.68, 200.63), Vector2(-419.11, 201.68), Vector2(-416.5, 201.8), Vector2(-416.4, 207.0),
	Vector2(-417.4, 209.9), Vector2(-419.5, 207.6), Vector2(-424.0, 206.2), Vector2(-444.4, 204.6)]
const KERB := [Vector2(-444.4, 204.6), Vector2(-424.0, 206.2), Vector2(-419.5, 207.6), Vector2(-417.4, 209.9)]
const TAMARISKS := [[Vector2(-441.0, 206.4), 6.4, 3.0], [Vector2(-435.3, 208.3), 7.0, 3.2], [Vector2(-431.0, 210.8), 6.6, 3.0],
	[Vector2(-426.3, 210.2), 7.2, 3.3], [Vector2(-422.0, 212.6), 5.8, 2.6]]
const BENCHES := [-435.0, -431.6, -425.9, -422.6]  # along the mural (their middles' x)
const BIN_X := -428.8
const BOARD := Vector2(-417.9, 208.6)
const BIG_TREE := Vector2(-443.9, 200.0)
const SAFFRON := Vector2(-426.72, 210.62)          # the hidden saffron: at the foot of the whitewashed tamarisk, on the side away from the walk
const NO_ENTRY := Vector2(-444.5, 202.4)           # (the map's street is wider than the real one: the sign at its edge)
# the square before the front
const BARRIERS := [[Vector2(-416.9, 170.9), Vector2(-424.3, 172.7)], [Vector2(-424.3, 172.7), Vector2(-424.8, 177.3)], [Vector2(-416.9, 170.9), Vector2(-417.3, 174.6)]]
const YOUNG_TREE := Vector2(-422.8, 175.5)
const HUT_SIGN := Vector2(-414.05, 161.75)         # the no-entry sign off the transformer hut's east side by its corner, the blue turn-right one under it
# the transformer hut (Texturas's requejo_1, handed over as ["obra"]), in the block's ring order: its north front to the
# avenue first
const HUT := "requejo_1"
const H_NW := Vector2(-420.12, 161.2)
const H_NE := Vector2(-415.15, 160.73)
const H_SE := Vector2(-414.69, 165.57)
const H_SW := Vector2(-419.67, 166.04)
const HUT_EAVE := 6.7           # the top of its walls over the foot of its north front (Street View: 6.4 to 7.2 m; at 6.45 it looked squat)
const HUT_RISE := 1.35          # its ridge (east-west) over the eaves: a gable at each end
const HUT_OUT := 0.3            # its eaves beyond the north and south walls...
const HUT_RAKE := 0.12          # ...and its tiles beyond the gables
const HUT_DOOR := Rect2(1.62, 0.0, 1.51, 2.28)    # the door of its north front (from its east end; y over the ground there)
const BUSHES := [[Vector2(-417.3, 192.4), 1.5], [Vector2(-417.5, 189.5), 1.0], [Vector2(-417.2, 195.2), 1.1], [Vector2(-417.7, 198.5), 0.7],
	[Vector2(-417.5, 187.6), 0.5], [Vector2(-417.2, 183.6), 0.45], [Vector2(-416.9, 177.0), 0.5]]     # (the big one before the east wing's window)

var openings := 0
var barriers := 0
var trees := 0
var benches := 0
var hut_pieces := 0             # (the transformer hut's)
var door: Vector2               # before the front door, on the square
var office: Vector2             # before the office's door, on the west street's pavement
var park: Vector2               # on the walk before the mural
var saffron_spot: Vector2       # (where its hidden saffron flower grows)
var _nn: Vector2                # the outward normals of the front, the east side, the back, the west side
var _ne: Vector2
var _ns: Vector2
var _nw: Vector2
var _n := 0
var _wk := Vector3.ZERO        # the wings' tops: a plane (at F, along C - F, along the south)
var _wu: Vector2
var _wv: Vector2

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"revoco":           # the cream render (Street View 2024, overcast: about 163, 139, 110)
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.04, 0.88, 0.66)), 0.16)
		"ladrillo":         # the brick of the pilasters, the bay, the band, the heads and sills (about 149, 98, 69)
			m = _glow(Tex.mat("brick_wall_09@2.5", Color(0.98, 0.74, 0.62)), 0.18)
		"zocalo":           # the foot of brown rubble (about 100, 75, 54)
			m = Tex.mat("stone_wall", Color(0.82, 0.68, 0.54))
		"blanco":           # the wings' white render
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.99, 0.97)), 0.26)
		"cemento":          # the grey cement foot of the east wing, the yard
			m = Tex.mat("granular_concrete", Color(0.72, 0.7, 0.66))
		"azotea":           # the wings' flat roofs
			m = Tex.mat("granular_concrete", Color(0.6, 0.58, 0.56))
		"losa":             # the balcony's slab, the step
			m = _glow(Tex.mat("granular_concrete", Color(0.86, 0.84, 0.8)), 0.1)
		"tiles_req":        # its old tiles, grey and mossy (Street View, overcast: about 95, 90, 75)
			var tm: StandardMaterial3D = Tex.mat(Tex.pick("tiles") if Tex.pick("tiles") != "" else "clay_roof_tiles_02", Color(0.62, 0.9, 1.3), true, 1.6)
			tm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = tm
		"tiles_hut":        # the transformer hut's old tiles, browner than the block's (Street View 2024)
			var hm: StandardMaterial3D = Tex.mat(Tex.pick("tiles") if Tex.pick("tiles") != "" else "clay_roof_tiles_02", Color(0.58, 0.86, 1.28), true, 1.6)      # (Street View: about 115, 98, 80)
			hm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = hm
		"tierra_req":       # the bare earth of the square and of the east side
			m = W._tmat(0xa8987e, "earth", 4.0)
		"adoquin":          # the park's walk of grey setts
			var em := StandardMaterial3D.new()
			em.albedo_texture = load("res://assets/empedrado/adoquin.png")
			em.albedo_color = Color(0.86, 0.86, 0.86)
			em.uv1_triplanar = true
			em.uv1_world_triplanar = true
			em.uv1_scale = Vector3.ONE / 2.0
			em.roughness = 1.0
			m = em
		"taraje", "taraje2", "hoja", "hoja2", "matorral", "seco":       # the tamarisks' feathery dark green (and its drier lumps), the trees' autumn leaves, the weeds
			var lm := StandardMaterial3D.new()
			lm.albedo_color = {"taraje": Color(0.34, 0.41, 0.25), "taraje2": Color(0.45, 0.47, 0.29), "hoja": Color(0.62, 0.6, 0.3), "hoja2": Color(0.55, 0.56, 0.26),
				"matorral": Color(0.33, 0.4, 0.24), "seco": Color(0.56, 0.52, 0.32)}[String(key)]
			lm.roughness = 1.0
			m = lm
		"rotulo", "cartel", "placa", "cruz", "mural", "panel", "vado", "aviso", "chapa", "calle", "camino", "desconchon", "tag_costrola", "tag_croquetilla":
			var pm := StandardMaterial3D.new()
			pm.albedo_texture = load(("res://assets/penas/" + String(key).substr(4) if String(key).begins_with("tag_") else DIR + String(key)) + ".png")
			pm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			pm.roughness = 1.0
			pm.metallic_specular = 0.0
			if key == "rotulo" or key == "aviso" or key == "desconchon" or String(key).begins_with("tag_"):      # (the peñas' tags: what is sprayed on the hut, as on any wall of the town)
				pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				pm.alpha_scissor_threshold = 0.5
			pm.emission_enabled = true
			pm.emission_texture = pm.albedo_texture
			pm.emission = Color.WHITE
			pm.emission_energy_multiplier = 0.12
			m = pm
		"farol":            # the street lamp's glass (no light of its own: shining by its material)
			var um := StandardMaterial3D.new()
			um.albedo_color = Color(1.0, 0.97, 0.88)
			um.emission_enabled = true
			um.emission = Color(1.0, 0.94, 0.8)
			um.emission_energy_multiplier = 0.6
			m = um
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world, _hd: Dictionary) -> void:
	W = world
	_nn = _outward(B, A)
	_ne = _outward(C, B)
	_ns = _outward(F, C)
	_nw = _outward(A, F)
	var mid := _along(B, A, DOOR.get_center().x)
	level = MapData.height(mid + _nn * 1.0)
	transform = Transform3D(Basis.IDENTITY, Vector3(0.0, level, 0.0))
	W.add_child(self)
	wall_top = TOP
	eave_out = EAVE
	roof_pitch = PITCH
	roof_rise0 = RISE0
	ridge_hex = 0x77695a          # (its hips' round tiles as grey as the rest)
	_planes = [[_nn, B.dot(_nn)], [_ne, C.dot(_ne)], [_ns, F.dot(_ns)], [_nw, A.dot(_nw)]]
	_front()
	_side(C, B, 0.9, true)
	_side(A, F, 5.6, false)
	_back()
	_roof_over([A, B, C, F], [-EAVE, -EAVE, -EAVE, -EAVE], "tiles_req")
	home()
	_roof_things()
	_wings()
	_square()
	_hut()
	_park()
	home()
	_commit()
	_ring_solids([A, B, C, F], 12.0)
	door = mid + _nn * 1.6
	office = _along(F, G, OF_DOOR.get_center().x) + _outward(F, G) * 1.4
	park = _along(G, S, 10.0) + _outward(G, S) * 1.6

# ---------------- pieces ----------------
func _x_on(p: Vector2, a: Vector2, b: Vector2) -> float:
	return (p - a).dot((b - a).normalized())

## how high the ground is before a spot of a front (this frame's y)
func _g(a: Vector2, b: Vector2, x: float) -> float:
	var p := _along(a, b, x) + _outward(a, b) * 0.6
	return ground(p.x, p.y)

## the point of the line a -> b at this x of the map
func _on_x(a: Vector2, b: Vector2, x: float) -> Vector2:
	return a.lerp(b, (x - a.x) / (b.x - a.x))

func _on_z(a: Vector2, b: Vector2, z: float) -> Vector2:
	return a.lerp(b, (z - a.y) / (b.y - a.y))

## a number from 0 to 1 that is always the same for the same window (the blinds' heights)
func _rnd(k: int) -> float:
	return fposmod(sin(float(k) * 12.9898 + 4.1) * 43758.5453, 1.0)

## A window of the flats in its hole: its brown frame and glass, its roller blind down `down` of it.
func _ventana(r: Rect2, down: float, bars := false) -> void:
	openings += 1
	window(r, FRAME, GLASS, 1)
	if down > 0.02:
		box(r.position.x, r.end.y - r.size.y * down, -DEEP + 0.1, r.size.x, r.size.y * down, 0.03, BLIND)
		for k in range(1, int(r.size.y * down / 0.06)):
			box(r.position.x, r.end.y - k * 0.06, -DEEP + 0.13, r.size.x, 0.008, 0.004, 0x4a3426)
	if bars:
		grille(r, 0.1, IRON_)

## the rubble foot's top at a corner: PLINTH where the ground is at the door's, lower where it falls (the game's ground
## falls 2.5 times as much as the real one: a level foot would stand 1.8 m high at the back corner of the west street)
func _pl(p: Vector2) -> float:
	return PLINTH + minf(0.0, ground(p.x, p.y)) * 0.6

## its head and sill of brick: the head a panel of the wall (masonry), the sill a brick standing out
func _sill(r: Rect2) -> void:
	box(r.position.x - 0.1, r.position.y - 0.07, 0.0, r.size.x + 0.2, 0.07, 0.07, "ladrillo")

func _head(r: Rect2) -> Rect2:
	return Rect2(r.position.x - 0.12, r.end.y, r.size.x + 0.24, 0.26)

## the cornice, the boards under the eaves and the tiles' edge over the front being built (ln long)
func _eaves_top(ln: float) -> void:
	cornice(0.0, ln, TOP, false, "ladrillo")
	pieces += 1
	quad(Vector3(-EAVE, TOP, EAVE), Vector3(ln + EAVE, TOP, EAVE), Vector3(ln + EAVE, TOP, 0.0), Vector3(-EAVE, TOP, 0.0), 0x6e5040, Vector3.DOWN)
	bar(Vector3(-EAVE, TOP - 0.03, EAVE - 0.03), Vector3(ln + EAVE, TOP - 0.03, EAVE - 0.03), 0.06, 0.09, 0x7a4a3a)

## an air conditioner on the wall
func _ac(x: float, y: float) -> void:
	box(x - 0.4, y, 0.0, 0.8, 0.55, 0.28, 0xe2e2de)
	box(x - 0.3, y + 0.08, 0.28, 0.38, 0.38, 0.01, 0x56585a)
	box(x - 0.35, y - 0.06, 0.04, 0.05, 0.06, 0.2, 0x8a8c8e)
	box(x + 0.3, y - 0.06, 0.04, 0.05, 0.06, 0.2, 0x8a8c8e)

## the front to the avenue (north): from its east end (B) to its west end (A)
func _front() -> void:
	var ln := face(B, A)
	var holes: Array = []
	var panels: Array = [Rect2(0.0, -3.0, PIL, TOP + 3.0), Rect2(ln - PIL, -3.0, PIL, TOP + 3.0), Rect2(BAY.x, -3.0, BAY.y - BAY.x, TOP + 3.0), Rect2(0.0, BAND, ln, BAND_H)]
	var wins: Array = []
	for f in range(3):
		for c: float in COLS:
			wins.append([Rect2(c - WIN_W / 2.0, SILLS[f], WIN_W, WIN_H), f])
	for c: float in BAY_WIN:            # the bay's: on the balcony, glass doors down to its slab; over it, windows
		wins.append([Rect2(c - 0.55, 3.48, 1.1, 5.99 - 3.48), 1])
		wins.append([Rect2(c - 0.55, SILLS[2], 1.1, WIN_H), 2])
	for w: Array in wins:
		holes.append(w[0])
		panels.append(_head(w[0]))
	holes.append(DOOR)
	masonry(0.0, ln, -3.0, TOP, holes, panels, "revoco", "ladrillo")
	var pb := _pl(B)
	var pa := _pl(A)
	plinth(0.0, DOOR.position.x, pb, lerpf(pb, pa, DOOR.position.x / ln), "zocalo", 0.07, -3.0)
	plinth(DOOR.end.x, ln, lerpf(pb, pa, DOOR.end.x / ln), pa, "zocalo", 0.07, -3.0)
	for w: Array in wins:
		var r: Rect2 = w[0]
		_n += 1
		if r.position.y > 3.4 and r.position.y < 3.6:          # (the balcony's glass doors: white curtains behind)
			openings += 1
			window(r, FRAME, GLASS, 0)
			box(r.position.x + 0.08, r.position.y + 0.1, -DEEP + 0.041, r.size.x - 0.16, r.size.y - 0.3, 0.005, 0xbcb8ae)
		else:
			var down := 0.0 if _rnd(_n) < 0.25 else (1.0 if _rnd(_n + 40) < 0.2 else 0.15 + 0.6 * _rnd(_n + 80))
			_ventana(r, down, int(w[1]) == 0)
		if r.position.y > 3.6 or r.position.y < 3.4:
			_sill(r)
	# the door: dark wood, two leaves, a stone step before it
	openings += 1
	box(DOOR.position.x, 0.0, -DEEP + 0.04, DOOR.size.x, DOOR.size.y, 0.06, 0x2a1812)
	box(DOOR.get_center().x - 0.02, 0.0, -DEEP + 0.1, 0.04, DOOR.size.y, 0.02, 0x1a0e0a)
	for sx in [DOOR.position.x + 0.12, DOOR.get_center().x + 0.1]:
		box(sx, 0.35, -DEEP + 0.1, 0.53, 0.8, 0.02, 0x3a2418)
		box(sx, 1.35, -DEEP + 0.1, 0.53, 0.9, 0.02, 0x3a2418)
	box(DOOR.position.x - 0.15, -0.6, 0.0, DOOR.size.x + 0.3, 0.6, 0.4, "losa")
	# the balcony: its slab, its railing, the board with the cross hung on it
	box(BAY.x + 0.1, 3.32, 0.0, BAY.y - BAY.x - 0.2, 0.15, 0.55, "losa")
	var rx0 := BAY.x + 0.12
	var rx1 := BAY.y - 0.12
	box(rx0, 4.38, 0.5, rx1 - rx0, 0.05, 0.05, IRON_)
	box(rx0, 3.55, 0.51, rx1 - rx0, 0.03, 0.03, IRON_)
	var nb := int((rx1 - rx0) / 0.12)
	for i in range(nb + 1):
		box(rx0 + (rx1 - rx0) * i / nb - 0.01, 3.47, 0.51, 0.02, 0.92, 0.02, IRON_)
	for x: float in [rx0, rx1 - 0.04]:
		box(x, 4.38, 0.0, 0.04, 0.05, 0.52, IRON_)
	_picture(BAY.x + 1.1, BAY.x + 2.85, 3.6, 4.15, 0.56, "cartel")
	# a plaque, the little sign with the cross, the street lamp on its bracket, the air conditioners, the cables
	_picture(14.45, 15.05, 2.4, 2.9, 0.02, "placa")
	_picture(12.32, 12.62, 1.35, 1.75, 0.02, "cruz")
	bar(Vector3(DOOR.get_center().x, 6.3, 0.0), Vector3(DOOR.get_center().x, 6.42, 0.72), 0.05, 0.05, 0x2e3134)
	box(DOOR.get_center().x - 0.14, 6.0, 0.6, 0.28, 0.32, 0.26, "farol")
	box(DOOR.get_center().x - 0.18, 6.32, 0.56, 0.36, 0.06, 0.34, 0x2e3134)
	_ac(8.4, 4.4)
	_ac(12.75, 4.4)
	_ac(12.75, 7.45)
	box(PIL, BAND + BAND_H + 0.05, 0.02, ln - 2.0 * PIL, 0.025, 0.025, 0x1e1e20)
	box(0.85, 0.0, 0.03, 0.03, BAND + 0.2, 0.03, 0x1e1e20)
	box(ln - 0.85, BAND + 0.2, 0.03, 0.03, TOP - BAND - 0.6, 0.03, 0x1e1e20)
	_eaves_top(ln)
	home()

## A plain side of the block (the Requejo's, the west street's): render between its brick pilasters, the band, the
## foot; a floodlight at its top, at `lamp` along it; on the east the meter boxes by its foot, on the west the air
## conditioners over the band.
func _side(a: Vector2, b: Vector2, lamp: float, east: bool) -> void:
	var ln := face(a, b)
	masonry(0.0, ln, -3.0, TOP, [], [Rect2(0.0, -3.0, PIL, TOP + 3.0), Rect2(ln - PIL, -3.0, PIL, TOP + 3.0), Rect2(0.0, BAND, ln, BAND_H)], "revoco", "ladrillo")
	plinth(0.0, ln, _pl(a), _pl(b), "zocalo", 0.07, -3.0)
	bar(Vector3(lamp, TOP - 0.7, 0.0), Vector3(lamp, TOP - 0.6, 0.45), 0.05, 0.05, 0x2e3134)
	box(lamp - 0.2, TOP - 0.78, 0.4, 0.4, 0.22, 0.12, 0x3a3c3e)
	if east:
		for x: float in [ln - 1.6, ln - 1.05]:
			box(x - 0.24, _g(a, b, x) + 0.3, 0.0, 0.48, 0.66, 0.22, 0x9a9c9a)
		box(ln - 1.25, _g(a, b, ln - 1.25) + 0.96, 0.02, 0.03, TOP - 1.5, 0.03, 0x1e1e20)
	else:
		_ac(2.4, BAND + BAND_H + 0.12)
		_ac(3.4, BAND + BAND_H + 0.12)
		box(0.45, _g(a, b, 0.45) - 0.1, 0.03, 0.08, TOP - 0.2 - _g(a, b, 0.45), 0.08, 0x9a9c9e)        # a grey downpipe by the pilaster
		box(4.0, _g(a, b, 4.0) - 0.1, 0.03, 0.06, BAND + 0.45 - _g(a, b, 4.0), 0.04, 0xd8d6d0)          # the white conduit down from the air conditioners
		box(lamp, BAND + BAND_H, 0.02, 0.02, TOP - 0.8 - BAND - BAND_H, 0.02, 0x1e1e20)               # the floodlight's cable
	_eaves_top(ln)
	home()

## the back (south), over the wings and the yard: its windows on the two floors above, the same pilasters and band
func _back() -> void:
	var ln := face(F, C)
	var holes: Array = []
	var panels: Array = [Rect2(0.0, -3.0, PIL, TOP + 3.0), Rect2(ln - PIL, -3.0, PIL, TOP + 3.0), Rect2(0.0, BAND, ln, BAND_H)]
	var wins: Array = []
	for f in [1, 2]:
		for c: float in BACK_COLS:
			wins.append(Rect2(c - WIN_W / 2.0, SILLS[f], WIN_W, WIN_H))
	for r: Rect2 in wins:
		holes.append(r)
		panels.append(_head(r))
	masonry(0.0, ln, -3.0, TOP, holes, panels, "revoco", "ladrillo")
	for r: Rect2 in wins:
		_n += 1
		_ventana(r, 0.1 + 0.85 * _rnd(_n + 7))
		_sill(r)
	_eaves_top(ln)
	home()

## what stands on its roof: two chimney pipes and the aerials
func _roof_things() -> void:
	var m := (A + B + C + F) / 4.0
	var u := (A - B).normalized()
	for s in [-5.2, 3.6]:
		var p: Vector2 = m + u * float(s) + _ns * 1.2
		var y := _roof_y(p)
		drum(Vector3(p.x, y - 0.2, p.y), 0.09, 0.09, 1.1, 0x8a8c8a, 8)
		drum(Vector3(p.x, y + 0.9, p.y), 0.15, 0.04, 0.18, 0x6a6c6a, 8)
	for s in [-2.6, 1.0, 1.9]:
		var p: Vector2 = m + u * float(s)
		var y := _roof_y(p)
		cbox(Vector3(p.x, y + 1.5, p.y), Vector3(0.04, 3.0, 0.04), 0x8a8c8e)
		for k in range(3):
			cbox(Vector3(p.x, y + 2.2 + k * 0.32, p.y), Vector3(0.9 - k * 0.2, 0.025, 0.025), 0x8a8c8e)

# ---------------- the wings, the yard, the mural ----------------
## The tops of the wings' walls: WING_H over the ground at the block's two back corners and at the office's corner to the
## park, on the plane through those three. (The game's ground falls 2.5 times as much as the real one under them: level
## tops would leave them 2.9 m high at the office's door and 4 m at the park.)
func _wing_plane() -> void:
	_wu = (C - F).normalized()
	_wv = Vector2(-_wu.y, _wu.x)
	var tf := ground(F.x, F.y) + WING_H
	var tc := ground(C.x, C.y) + WING_H
	var tg := ground(G.x, G.y) + WING_H
	var kx := (tc - tf) / (C - F).dot(_wu)
	var kz := (tg - tf - kx * (G - F).dot(_wu)) / (G - F).dot(_wv)
	_wk = Vector3(tf, kx, kz)

## how high the wings' tops are over a spot of the map (this frame's y)
func _wt(p: Vector2) -> float:
	var d := p - F
	return _wk.x + _wk.y * d.dot(_wu) + _wk.z * d.dot(_wv)

## ...at x along the front from a to b
func _wt_at(a: Vector2, b: Vector2, x: float) -> float:
	return _wt(_along(a, b, x))

func _wings() -> void:
	_wing_plane()
	var wm := _on_x(F, C, WX)                     # the west wing's yard side, at the block...
	var wp := _on_x(G, S, WX)                     # ...and at the mural
	var em := _on_x(F, C, EX)
	var ep := _on_x(G, S, EX)
	_office(F, G)
	_east_front(S, C)
	_mural(G, S)
	_wing_wall(wp, wm, [])                        # the west wing's side to the yard
	_wing_wall(em, ep, [])                        # the east wing's
	_wing_wall(ep, wp, [])                        # the mural's wall seen from the yard
	home()
	_lay(PackedVector2Array([wm, em, ep, wp]), -0.04, "cemento")
	# their roofs behind their parapets: flat at the north, tiles at the south (one slope, the ground's)
	for ring: Array in [[F, wm, wp, G], [em, C, S, ep]]:
		for i in range(1, 4):                     # (not along the block's back: its wall goes on up)
			_parapet(ring[i], ring[(i + 1) % 4])
	var wr := _on_z(F, G, ROOFS_Z)
	var wq := _on_z(wm, wp, ROOFS_Z)
	var er := _on_z(em, ep, ROOFS_Z)
	var eq := _on_z(C, S, ROOFS_Z)
	_deck([F, wm, wq, wr], "azotea")
	_deck([em, C, eq, er], "azotea")
	for q: Array in [[wr, wq, wp, G], [er, eq, S, ep]]:
		var v: Array = []
		for p: Vector2 in q:
			v.append(Vector3(p.x, _wt(p) - PARAPET + 0.05, p.y))
		roof(v, "tiles_req")
	home()
	_wing_solids([F, wm, wp, G])
	_wing_solids([em, C, S, ep])
	var d := (ep - wp).normalized()
	var mid := (wp + ep) / 2.0 - Vector2(-d.y, d.x) * 0.17
	var top := maxf(_wt(wp), _wt(ep))
	solid(Vector3(mid.x, (top - 2.5) / 2.0, mid.y), Vector3(wp.distance_to(ep), top + 2.5, 0.34), atan2(-d.y, d.x))

## a flat piece of a wing's roof over these corners of the map, PARAPET under the wings' tops
func _deck(q: Array, key) -> void:
	pieces += 1
	var pts := PackedVector2Array(q)
	var idx := Geometry2D.triangulate_polygon(pts)
	for t in range(0, idx.size(), 3):
		var a := pts[idx[t]]
		var b := pts[idx[t + 1]]
		var c := pts[idx[t + 2]]
		tri(Vector3(a.x, _wt(a) - PARAPET, a.y), Vector3(b.x, _wt(b) - PARAPET, b.y), Vector3(c.x, _wt(c) - PARAPET, c.y), key, Vector3.UP)

## A wall of a wing from a to b (seen from outside: a on the left): white render from under the ground up to the wings'
## tops, sloping with them, and the edge of tiles along its top. Leaves its frame set; returns its length.
func _wing_wall(a: Vector2, b: Vector2, holes: Array) -> float:
	var ln := face(a, b)
	var t0 := _wt(a)
	var t1 := _wt(b)
	var ym := minf(t0, t1)
	masonry(0.0, ln, minf(_g(a, b, 0.0), _g(a, b, ln)) - 0.8, ym, holes, [], "blanco", "blanco")
	if absf(t1 - t0) > 0.005:
		pieces += 1
		quad(Vector3(0, ym, 0), Vector3(ln, ym, 0), Vector3(ln, t1, 0), Vector3(0, t0, 0), "blanco", Vector3(0, 0, 1))
	bar(Vector3(-0.05, t0 + 0.035, -0.1), Vector3(ln + 0.05, t1 + 0.035, -0.1), 0.34, 0.07, 0x8a5644)
	return ln

## the inside of a wing's parapet over its roof (a -> b in the wing's ring's order)
func _parapet(a: Vector2, b: Vector2) -> void:
	var ln := face(b, a)
	var tb := _wt(b)
	var ta := _wt(a)
	pieces += 1
	quad(Vector3(0, tb - PARAPET, -0.2), Vector3(ln, ta - PARAPET, -0.2), Vector3(ln, ta, -0.2), Vector3(0, tb, -0.2), "blanco", Vector3(0, 0, -1))
	home()

func _wing_solids(ring: Array) -> void:
	for i in range(ring.size()):
		var a: Vector2 = ring[i]
		var b: Vector2 = ring[(i + 1) % ring.size()]
		var d := (b - a).normalized()
		var mid := (a + b) / 2.0 + Vector2(-d.y, d.x) * 0.17
		var top := maxf(_wt(a), _wt(b))
		solid(Vector3(mid.x, (top - 2.5) / 2.0, mid.y), Vector3(a.distance_to(b), top + 2.5, 0.34), atan2(-d.y, d.x))

## The office's front to the west street (from the block, north, to the park): its door behind an iron gate, the
## cross and the name painted over it and its windows, the two windows behind grilles (their brown blinds down), the
## downpipe, the brown garage door up to under the roof's edge.
func _office(a: Vector2, b: Vector2) -> void:
	var gd := _g(a, b, OF_DOOR.get_center().x) + 0.05
	var dr := Rect2(OF_DOOR.position.x, gd, OF_DOOR.size.x, OF_DOOR.size.y)
	var holes: Array = [dr]
	var wins: Array = []
	for x: float in OF_WIN:
		var r := Rect2(x, _g(a, b, x + 0.65) + 0.95, 1.3, 1.2)
		wins.append(r)
		holes.append(r)
	var gg := _g(a, b, (OF_GARAGE.x + OF_GARAGE.y) / 2.0)
	var gr := Rect2(OF_GARAGE.x, gg, OF_GARAGE.y - OF_GARAGE.x, minf(_wt_at(a, b, OF_GARAGE.x), _wt_at(a, b, OF_GARAGE.y)) - 0.2 - gg)
	holes.append(gr)
	_wing_wall(a, b, holes)
	openings += 1
	box(dr.position.x, dr.position.y, -DEEP + 0.03, dr.size.x, dr.size.y, 0.04, 0x2c2a28)          # the glass door behind...
	box(dr.position.x + 0.1, dr.position.y + 0.9, -DEEP + 0.075, dr.size.x - 0.2, 1.2, 0.01, 0x3a4650)
	var nbar := 10                                                                                     # ...the gate of iron bars
	for i in range(nbar + 1):
		box(dr.position.x + 0.04 + (dr.size.x - 0.1) * i / nbar, dr.position.y, -0.1, 0.022, dr.size.y - 0.02, 0.022, IRON_)
	for y in [0.1, 1.1, dr.size.y - 0.08]:
		box(dr.position.x, dr.position.y + float(y), -0.11, dr.size.x, 0.05, 0.03, IRON_)
	for r: Rect2 in wins:
		_ventana(r, 1.0, true)
		box(r.position.x - 0.06, r.position.y - 0.05, 0.0, r.size.x + 0.12, 0.05, 0.06, 0xd8d6d0)
	openings += 1                                                                                      # the brown garage door, its vents
	box(gr.position.x, gr.position.y, -0.2, gr.size.x, gr.size.y, 0.04, 0x4a3026)
	box(gr.position.x + 0.1, gr.end.y - 0.42, -0.155, gr.size.x - 0.2, 0.26, 0.01, 0x3a241c)
	for k in range(int((gr.size.x - 0.3) / 0.16)):
		box(gr.position.x + 0.2 + k * 0.16, gr.end.y - 0.38, -0.15, 0.1, 0.18, 0.01, 0xb8b0a0)
	for k in range(int((gr.size.y - 0.6) / 0.38)):
		box(gr.position.x, gr.position.y + 0.3 + k * 0.38, -0.155, gr.size.x, 0.012, 0.006, 0x3a241c)
	box(gr.position.x - 0.12, gr.end.y, 0.0, gr.size.x + 0.24, 0.1, 0.06, 0x7a3a2a)                  # its brown head
	var tex: Texture2D = load(DIR + "rotulo.png")                                                       # the name, as wide as its picture says
	var rw := 0.8 * float(tex.get_width()) / float(tex.get_height())
	var rtop := _wt_at(a, b, 2.1 + rw) - 0.12
	_picture(2.1, 2.1 + rw, rtop - 0.8, rtop, 0.01, "rotulo")
	_picture(2.08, 2.38, gd + 1.3, gd + 1.7, 0.02, "cruz")
	box(7.62, _g(a, b, 7.6) - 0.1, 0.02, 0.07, _wt_at(a, b, 7.6) - _g(a, b, 7.6) + 0.05, 0.07, 0xd2d0ca)      # the downpipe
	home()

## The east wing's front to the Requejo (from the park, south, to the block): white over a foot of grey cement, the grey
## garage door of ribbed sheet with its plate, a window behind a grille.
func _east_front(a: Vector2, b: Vector2) -> void:
	var ln := a.distance_to(b)
	var gg := _g(a, b, (EW_GARAGE.x + EW_GARAGE.y) / 2.0)
	var gr := Rect2(EW_GARAGE.x, gg, EW_GARAGE.y - EW_GARAGE.x, minf(_wt_at(a, b, EW_GARAGE.x), _wt_at(a, b, EW_GARAGE.y)) - 0.3 - gg)
	var wr := Rect2(EW_WIN, _g(a, b, EW_WIN + 0.6) + 1.0, 1.2, 1.1)
	var y0 := minf(_g(a, b, 0.0), _g(a, b, ln)) - 0.8
	_wing_wall(a, b, [gr, wr])
	pieces += 1
	quad(Vector3(gr.end.x, y0, 0.03), Vector3(ln, y0, 0.03), Vector3(ln, _g(a, b, ln) + 0.6, 0.03), Vector3(gr.end.x, _g(a, b, gr.end.x) + 0.6, 0.03), "cemento", Vector3(0, 0, 1))
	quad(Vector3(0.0, y0, 0.03), Vector3(gr.position.x, y0, 0.03), Vector3(gr.position.x, _g(a, b, gr.position.x) + 0.6, 0.03), Vector3(0.0, _g(a, b, 0.0) + 0.6, 0.03), "cemento", Vector3(0, 0, 1))
	openings += 2
	box(gr.position.x, gr.position.y, -0.18, gr.size.x, gr.size.y, 0.04, 0xa8acae)
	for k in range(int(gr.size.x / 0.12)):
		box(gr.position.x + 0.05 + k * 0.12, gr.position.y, -0.14, 0.04, gr.size.y, 0.012, 0x8e9294)
	_picture(gr.get_center().x - 0.18, gr.get_center().x + 0.18, gr.position.y + 1.4, gr.position.y + 2.0, -0.12, "vado")      # the vado plate on it
	window(wr, 0xeeeeea, GLASS, 1)
	grille(wr, 0.1, IRON_)
	home()

## The walls to the park, the wings' and the yard's, as one: white, the mural painted over them (its foot follows the
## ground, its top the walls').
func _mural(a: Vector2, b: Vector2) -> void:
	var ln := _wing_wall(a, b, [])
	var g0 := _g(a, b, 0.0)
	var g1 := _g(a, b, ln)
	pieces += 1
	quad(Vector3(0.06, g0 + 0.22, 0.012), Vector3(ln - 0.06, g1 + 0.22, 0.012), Vector3(ln - 0.06, _wt(b) - 0.12, 0.012), Vector3(0.06, _wt(a) - 0.12, 0.012), "mural", Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	home()

# ---------------- the square before it ----------------
func _square() -> void:
	var north := _area_at(Vector2(-428.0, 168.0))
	if north.size() >= 3:
		_lay(north, -0.09, "tierra_req")
	for run: Array in BARRIERS:
		_barriers(run[0], run[1])
	_young_tree(YOUNG_TREE)
	_no_entry(HUT_SIGN, (Vector2(-413.78, 153.26) - HUT_SIGN).normalized(), true)
	for b: Array in BUSHES:
		_bush(b[0], b[1])
	for k in range(16):                                # dry weeds on the bare earth along the east side
		var p := Vector2(-417.0 + 0.8 * sin(k * 2.3), 176.0 + k * 1.6)
		ball(Vector3(p.x, ground(p.x, p.y) + 0.06, p.y), 0.22 + 0.16 * _rnd(k), "seco" if k % 3 != 0 else "matorral", 0.6, 7, 4)

## the area of the map that holds this spot
func _area_at(p: Vector2) -> PackedVector2Array:
	for a in MapData.areas:
		var ap: Array = a["p"]
		var pts := PackedVector2Array()
		for i in range(0, ap.size(), 2):
			pts.append(Vector2(ap[i], ap[i + 1]))
		if Geometry2D.is_point_in_polygon(p, pts):
			return pts
	return PackedVector2Array()

## The town's red plastic barriers from a to b, one after another (each 2 m long): two feet, two posts, the rails and
## the panel with its white reflectors; a solid for each.
func _barriers(a: Vector2, b: Vector2) -> void:
	var n := maxi(1, int(round(a.distance_to(b) / 2.0)))
	for i in range(n):
		var p0 := a.lerp(b, float(i) / n)
		var p1 := a.lerp(b, float(i + 1) / n)
		var d := (p1 - p0).normalized()
		var L := p0.distance_to(p1) - 0.05
		var m := (p0 + p1) / 2.0
		var y := ground(m.x, m.y)
		var tw := 0.04 * sin(i * 1.7)                         # (each stands a little askew)
		_xf = Transform3D(Basis(Vector3.UP, tw) * Basis(Vector3(d.x, 0, d.y), Vector3.UP, Vector3(-d.y, 0, d.x)), Vector3(p0.x, y, p0.y))
		for x: float in [0.08, L - 0.16]:
			box(x - 0.04, 0.0, -0.3, 0.16, 0.08, 0.6, BARRIER)
			box(x, 0.0, -0.04, 0.08, 1.0, 0.08, BARRIER)
		box(0.08, 0.92, -0.035, L - 0.16, 0.08, 0.07, BARRIER)
		box(0.08, 0.2, -0.035, L - 0.16, 0.07, 0.07, BARRIER)
		box(0.16, 0.32, -0.02, L - 0.32, 0.55, 0.04, BARRIER)
		for k in range(3):
			box(0.3 + k * (L - 0.6) / 2.6, 0.5, 0.0, 0.32, 0.12, 0.02, 0xf4f4f2)
		home()
		solid(Vector3(m.x, y + 0.5, m.y), Vector3(L, 1.0, 0.12), atan2(-d.y, d.x))
		yard.append(m)
		barriers += 1

## a young tree: a thin trunk, leaning a little, and a small crown of a few lumps (yellowing in November)
func _young_tree(at: Vector2) -> void:
	var y := ground(at.x, at.y)
	bar(Vector3(at.x, y - 0.2, at.y), Vector3(at.x + 0.15, y + 2.5, at.y - 0.1), 0.14, 0.14, 0x6b5a45)
	for q: Array in [[Vector3(0.1, 3.3, -0.1), 1.05, "hoja"], [Vector3(0.75, 2.85, 0.35), 0.75, "hoja2"], [Vector3(-0.6, 2.9, -0.4), 0.8, "hoja2"],
			[Vector3(0.2, 4.0, 0.3), 0.6, "hoja"], [Vector3(-0.2, 2.6, 0.6), 0.55, "hoja"]]:
		ball(Vector3(at.x, y, at.y) + (q[0] as Vector3), float(q[1]), q[2], 0.85, 8, 5)
	solid(Vector3(at.x, y + 1.0, at.y), Vector3(0.3, 2.0, 0.3))
	yard.append(at)
	trees += 1

## a bush of weeds, in lumps
func _bush(at: Vector2, r: float) -> void:
	var y := ground(at.x, at.y)
	ball(Vector3(at.x, y + r * 0.6, at.y), r, "matorral", 0.85, 9, 5)
	ball(Vector3(at.x + r * 0.45, y + r * 0.45, at.y + r * 0.5), r * 0.72, "matorral", 0.8, 8, 4)
	ball(Vector3(at.x - r * 0.3, y + r * 0.5, at.y - r * 0.55), r * 0.66, "seco", 0.8, 8, 4)
	ball(Vector3(at.x + r * 0.1, y + r * 1.25, at.y + r * 0.1), r * 0.5, "matorral", 0.9, 7, 4)

# ---------------- the transformer hut ----------------
## The transformer hut on the square's corner to the avenue (requejo_1): a tall box of whitewashed walls and a gabled
## roof of old tiles (the ridge east-west) over a white moulding. To the avenue, its grey sheet-metal door with the
## warning signs, a cabinet with a peña's tag on it, the old metal plate over the door and the square's name plate, the
## louvre high up, the cables hanging from their bracket at its east end and coiled round the corner, the street lamp
## on its arm at its west end, a cable down that corner; on its east gable the pilgrims' arrow, on its south side a
## niche of vents and the iron hooks under the eave, on its west gable the bar of insulators, a patch of fallen render
## and another tag by its foot (Street View 2024; 2013 and 2019 the same).
func _hut() -> void:
	var p0 := pieces
	var ln := H_NE.distance_to(H_NW)
	var top := _g(H_NE, H_NW, ln / 2.0) + HUT_EAVE
	var k := HUT_RISE / (H_NW.distance_to(H_SW) / 2.0)
	_hut_north(top, k)
	_hut_east(top)
	_hut_south(top, k)
	_hut_west(top)
	var u := ((H_NE + H_SE) / 2.0 - (H_NW + H_SW) / 2.0).normalized()
	var nn := _outward(H_NE, H_NW)
	var ns := _outward(H_SW, H_SE)
	var rw := (H_NW + H_SW) / 2.0 - u * HUT_RAKE
	var re := (H_NE + H_SE) / 2.0 + u * HUT_RAKE
	var ry := top + HUT_RISE + 0.02
	var ey := top + 0.02 - HUT_OUT * k
	var nw := H_NW + nn * HUT_OUT - u * HUT_RAKE
	var ne := H_NE + nn * HUT_OUT + u * HUT_RAKE
	var sw := H_SW + ns * HUT_OUT - u * HUT_RAKE
	var se := H_SE + ns * HUT_OUT + u * HUT_RAKE
	var RW := Vector3(rw.x, ry, rw.y)
	var RE := Vector3(re.x, ry, re.y)
	roof([Vector3(nw.x, ey, nw.y), Vector3(ne.x, ey, ne.y), RE, RW], "tiles_hut")
	roof([Vector3(se.x, ey, se.y), Vector3(sw.x, ey, sw.y), RW, RE], "tiles_hut")
	bar(RW + Vector3(0, 0.05, 0), RE + Vector3(0, 0.05, 0), 0.26, 0.12, 0x6a5444)           # the ridge's round tiles
	for q: Array in [[nw, RW], [ne, RE], [sw, RW], [se, RE]]:                                  # the gables' edges: a row of tiles on a white bead of mortar
		var e: Vector2 = q[0]
		var r: Vector3 = q[1]
		bar(Vector3(e.x, ey + 0.05, e.y), r + Vector3(0, 0.05, 0), 0.15, 0.1, 0x6a5444)
		bar(Vector3(e.x, ey - 0.03, e.y), r - Vector3(0, 0.03, 0), 0.11, 0.07, 0xe6e2da)
	var mid := (H_NW + H_NE + H_SE + H_SW) / 4.0
	var d := (H_NE - H_NW).normalized()
	var foot := ground(mid.x, mid.y) - 1.5
	solid(Vector3(mid.x, (foot + top) / 2.0, mid.y), Vector3(ln, top - foot, H_NW.distance_to(H_SW)), atan2(-d.y, d.x))
	hut_pieces = pieces - p0

## one of the hut's walls seen from outside (a is its left end), from under the ground up to its top; `gable`: with its
## triangle up to the ridge. Its length.
func _hut_wall(a: Vector2, b: Vector2, top: float, gable: bool, holes: Array = []) -> float:
	var ln := face(a, b)
	var foot := minf(_g(a, b, 0.0), _g(a, b, ln)) - 0.8
	masonry(0.0, ln, foot, top, holes, [], "blanco", "blanco")
	if gable:
		pieces += 1
		tri(Vector3(0.0, top, 0.0), Vector3(ln, top, 0.0), Vector3(ln / 2.0, top + HUT_RISE, 0.0), "blanco", Vector3(0, 0, 1))
	return ln

## the white moulding under an eave of the hut and the round ends of its tiles along it (in the wall's frame)
func _hut_eave(ln: float, top: float, k: float) -> void:
	var ey := top + 0.02 - HUT_OUT * k
	box(-0.08, ey - 0.13, 0.0, ln + 0.16, 0.12, HUT_OUT - 0.05, "blanco")          # the bead of mortar the tiles sit on...
	box(-0.08, ey - 0.25, 0.0, ln + 0.16, 0.12, 0.13, "blanco")                    # ...and the moulding under it
	var n := int((ln + 2.0 * HUT_RAKE) / 0.18)
	for i in range(n):
		box(-HUT_RAKE + 0.03 + i * 0.18, ey - 0.1, HUT_OUT - 0.12, 0.13, 0.12, 0.14, 0x4a3a2e if i % 2 == 0 else 0x5a4636)

func _hut_north(top: float, k: float) -> void:
	var ln := H_NE.distance_to(H_NW)
	var g := _g(H_NE, H_NW, HUT_DOOR.get_center().x)
	var door := Rect2(HUT_DOOR.position.x, g - 0.05, HUT_DOOR.size.x, HUT_DOOR.size.y + 0.05)
	_hut_wall(H_NE, H_NW, top, false, [door])
	_hut_eave(ln, top, k)
	openings += 1
	# the door: two leaves of grey sheet metal a hand back in its hole, a cement frame round it, its step, its signs
	var x0 := door.position.x
	var x1 := door.end.x
	var xm := (x0 + x1) / 2.0
	box(x0, g - 0.05, -0.13, x1 - x0, door.size.y, 0.03, 0x8a949a)
	box(xm - 0.012, g, -0.1, 0.024, door.size.y - 0.08, 0.01, 0x5c6468)
	box(xm + 0.1, g + 1.0, -0.1, 0.03, 0.14, 0.03, 0x3a3e40)                       # its lock
	for q: Array in [[x0 - 0.06, 0.06, door.size.y + 0.06], [x1, 0.06, door.size.y + 0.06]]:
		box(q[0], g - 0.05, 0.0, q[1], q[2], 0.015, 0xb4b2ac)
	box(x0 - 0.06, g + door.size.y - 0.05, 0.0, x1 - x0 + 0.12, 0.06, 0.015, 0xb4b2ac)
	box(x0 - 0.05, g - 0.25, 0.0, x1 - x0 + 0.1, 0.27, 0.2, "cemento")
	_picture(xm + 0.22, xm + 0.5, g + 1.72, g + 1.97, -0.095, "aviso")
	_picture(x0 + 0.3, x0 + 0.58, g + 1.12, g + 1.37, -0.095, "aviso")
	box(x0 + 0.24, g + 1.5, -0.1, 0.42, 0.42, 0.006, 0x6a7276)                     # (where the company's sticker was: bare)
	box(x0 + 0.28, g + 1.44, -0.1, 0.34, 0.08, 0.008, 0xeeeeea)
	# the cabinet to the left of it, with a peña's tag; the old metal plate over the door; the square's name plate
	box(0.5, g + 1.1, 0.0, 0.8, 0.98, 0.035, 0x9ea4a6)
	box(0.53, g + 1.13, 0.035, 0.74, 0.92, 0.004, 0xa8aeb0)
	_picture(0.56, 1.24, g + 1.25, g + 1.93, 0.041, "tag_costrola")
	box(1.92, g + 2.58, 0.0, 0.71, 0.34, 0.012, 0x5a4430)
	_picture(1.95, 2.6, g + 2.6, g + 2.9, 0.013, "chapa")
	box(4.11, g + 2.68, 0.0, 0.59, 0.39, 0.014, 0xb4b4b0)
	_picture(4.13, 4.68, g + 2.7, g + 3.05, 0.015, "calle")
	# the louvre high up: a dark hole, grey metal slats, their frame
	var lx0 := 1.82
	var lx1 := 3.0
	var ly1 := top - 1.2
	var ly0 := ly1 - 0.72
	box(lx0, ly0, 0.0, lx1 - lx0, ly1 - ly0, 0.012, 0x2a2c2e)
	for i in range(9):
		box(lx0 + 0.03, ly0 + 0.04 + i * 0.075, 0.012, lx1 - lx0 - 0.06, 0.04, 0.02, 0x7c8082)
	for q: Array in [[lx0 - 0.04, ly0 - 0.04, 0.04, ly1 - ly0 + 0.08], [lx1, ly0 - 0.04, 0.04, ly1 - ly0 + 0.08],
			[lx0, ly0 - 0.04, lx1 - lx0, 0.04], [lx0, ly1, lx1 - lx0, 0.04]]:
		box(q[0], q[1], 0.0, q[2], q[3], 0.035, 0x8a8e90)
	# the cables: their bracket under the eave at the east end, a bundle hanging down the front, coiled round the corner
	box(0.42, top - 0.42, 0.0, 0.26, 0.07, 0.2, IRON_)
	for x: float in [0.46, 0.62]:
		ball(Vector3(x, top - 0.47, 0.17), 0.05, 0x8a5a3a, 1.3, 6, 4)
	var hz := Vector3(-1.0, 0.0, 1.0).normalized()                                 # (the coils hang across the corner)
	for i in range(4):
		var a := Vector3(0.36 + i * 0.05, top - 0.38, 0.05 + i * 0.012)
		var b := Vector3(0.18 + i * 0.05, top - 2.3 - i * 0.05, 0.06 + i * 0.015)
		bar(a, b, 0.026, 0.026, 0x161616)
		var c := Vector3(-0.02, top - 2.6 - i * 0.07, 0.24) + Vector3(1.0, 0.0, 1.0).normalized() * (float(i) - 1.5) * 0.07
		var r := 0.22 + 0.05 * float(i % 2)
		var last := b
		for j in range(15):
			var t := PI / 2.0 + TAU * (0.95 + 0.1 * float(i)) * float(j) / 14.0
			var q := c + hz * (cos(t) * r) + Vector3.UP * (sin(t) * r) + Vector3(0.02, 0.0, 0.02) * float(j) / 14.0
			bar(last, q, 0.026, 0.026, 0x161616)
			last = q
	# the street lamp on its arm at the west end, a cable down that corner and its little box
	box(4.45, top - 0.68, 0.0, 0.2, 0.26, 0.05, 0x2e3134)
	bar(Vector3(4.55, top - 0.55, 0.05), Vector3(4.55, top + 0.12, 1.35), 0.05, 0.05, 0x5a5e60)
	box(4.4, top + 0.1, 1.15, 0.3, 0.08, 0.55, 0x6a6e70)
	box(4.43, top + 0.075, 1.2, 0.24, 0.03, 0.45, "farol")
	box(ln - 0.07, g - 0.1, 0.02, 0.022, top - 0.3 - g, 0.022, 0x161616)
	box(ln - 0.16, g + 3.5, 0.02, 0.12, 0.17, 0.08, 0x9a9c9e)
	home()

func _hut_east(top: float) -> void:
	var ln := _hut_wall(H_SE, H_NE, top, true)
	var g := _g(H_SE, H_NE, ln - 0.35)
	_picture(ln - 0.43, ln - 0.28, g + 3.35, g + 3.5, 0.012, "camino")
	home()

func _hut_south(top: float, k: float) -> void:
	var ln := H_SW.distance_to(H_SE)
	var niche := Rect2(3.0, top - 1.72, 1.2, 0.72)
	_hut_wall(H_SW, H_SE, top, false, [niche])
	_hut_eave(ln, top, k)
	box(niche.position.x, niche.position.y, -0.14, niche.size.x, niche.size.y, 0.02, 0xcfcdc6)     # the niche's back (in its shade), with its three little vents
	box(niche.position.x, niche.end.y - 0.05, -0.14, niche.size.x, 0.05, 0.14, 0x9e9c96)
	for i in range(3):
		box(niche.position.x + 0.28 + i * 0.3, niche.position.y + 0.42, -0.125, 0.07, 0.07, 0.01, 0x262626)
	for x: float in [2.6, 3.6, 4.2]:                                               # the iron hooks under the eave
		bar(Vector3(x, top - 0.42, 0.0), Vector3(x, top - 0.48, 0.17), 0.025, 0.025, IRON_)
	home()

func _hut_west(top: float) -> void:
	var ln := _hut_wall(H_NW, H_SW, top, true)
	var g := _g(H_NW, H_SW, ln / 2.0)
	box(0.88, top - 1.5, 0.04, 0.05, 1.7, 0.05, IRON_)                             # the bar of insulators near the corner
	for y: float in [top - 1.4, top - 0.12]:
		box(0.84, y, 0.0, 0.14, 0.05, 0.09, IRON_)
	for i in range(3):
		ball(Vector3(0.905, top - 0.55 - i * 0.32, 0.13), 0.05, 0x8a5a3a, 1.3, 6, 4)
	_picture(0.55, 1.3, g + 1.15, g + 2.35, 0.006, "desconchon")                    # a patch where the render has fallen, its stain run down
	_picture(3.95, 4.75, g + 0.95, g + 1.75, 0.012, "tag_croquetilla")
	home()

# ---------------- the park behind it ----------------
func _park() -> void:
	_lay(PackedVector2Array(WALK), -0.045, "adoquin")
	for i in range(KERB.size() - 1):
		_kerb_line(KERB[i], KERB[i + 1])
	for t: Array in TAMARISKS:
		_tamarisk(t[0], t[1], t[2], (t[0] as Vector2).distance_to(Vector2(-426.3, 210.2)) < 0.1)
	var d := (S - G).normalized()
	var out := _outward(G, S)
	for x: float in BENCHES:
		var p := _on_x(G, S, x) + out * 1.0
		_bench(p, d)
	var bp := _on_x(G, S, BIN_X) + out * 0.7
	var by := ground(bp.x, bp.y)
	drum(Vector3(bp.x, by, bp.y), 0.24, 0.27, 0.9, 0x4a4e50, 12)
	drum(Vector3(bp.x, by + 0.9, bp.y), 0.29, 0.29, 0.05, 0x2e3032, 12)
	solid(Vector3(bp.x, by + 0.45, bp.y), Vector3(0.55, 0.9, 0.55))
	yard.append(bp)
	_board(BOARD, Vector2(1.0, 0.25).normalized())
	_big_tree(BIG_TREE)
	_no_entry(NO_ENTRY, (Vector2(-448.6, 204.8) - NO_ENTRY).normalized())
	_saffron(SAFFRON)
	var lawn_patch := Vector2(-426.6, 210.9)          # (the bare patch round the tree with the whitewashed foot)
	var patch := PackedVector2Array()
	for k in range(10):
		patch.append(lawn_patch + Vector2(cos(TAU * k / 10.0) * 1.6, sin(TAU * k / 10.0) * 1.1))
	_lay(patch, -0.1, "tierra_req")

## A saffron flower hidden in the bare earth at the foot of the whitewashed tamarisk, behind its trunk from the walk,
## a tuft of dry grass by it (the user, 23 November 2026, choosing where: «En el parque»). The flower is the game's to
## take away; it counts once a game, as the other hidden ones.
func _saffron(at: Vector2) -> void:
	var g := ground(at.x, at.y)
	ball(Vector3(at.x + 0.22, g + 0.08, at.y + 0.1), 0.2, "seco", 0.6, 7, 4)
	var flower := Node3D.new()
	flower.add_child(Parts.part("cyl", 0x5f9c4a, Vector3(0, 0.3, 0), Vector3(0.03, 0.6, 0.03)))
	for k in range(5):
		flower.add_child(Parts.part("ball", 0x9b5de5, Vector3(cos(k * 1.257) * 0.12, 0.66, sin(k * 1.257) * 0.12), Vector3(0.11, 0.2, 0.11)))
	flower.add_child(Parts.part("ball", 0xe63946, Vector3(0, 0.74, 0), Vector3(0.05, 0.13, 0.05)))
	flower.position = Vector3(at.x, g - 0.06, at.y)
	add_child(flower)
	saffron_spot = at
	var game = W.get_parent()                           # (the game: the world is its child)
	if game != null and game.get("flowers") != null:
		(game.flowers as Array).append({"node": flower, "p": saffron_spot, "id": "requejo", "hidden": true})      # (hidden: Sistemas keeps count of these)

## a kerb along a line: its top a hand over the ground, 0.15 wide (left out where it would cross a road)
func _kerb_line(a: Vector2, b: Vector2) -> void:
	var L := a.distance_to(b)
	var d := (b - a) / L
	var n := Vector2(-d.y, d.x) * 0.075
	var k := maxi(1, int(ceil(L / 1.0)))
	for i in range(k):
		var p0 := a.lerp(b, float(i) / k)
		var p1 := a.lerp(b, float(i + 1) / k)
		if MapData.road_edge_dist((p0 + p1) / 2.0) < -0.6:
			continue
		var y0 := ground(p0.x, p0.y) + 0.06
		var y1 := ground(p1.x, p1.y) + 0.06
		pieces += 1
		quad(Vector3(p0.x - n.x, y0, p0.y - n.y), Vector3(p1.x - n.x, y1, p1.y - n.y), Vector3(p1.x + n.x, y1, p1.y + n.y), Vector3(p0.x + n.x, y0, p0.y + n.y), 0xc8c4bc, Vector3.UP)
		for sg in [-1.0, 1.0]:
			var q0: Vector2 = p0 + n * sg
			var q1: Vector2 = p1 + n * sg
			quad(Vector3(q0.x, y0 - 0.3, q0.y), Vector3(q1.x, y1 - 0.3, q1.y), Vector3(q1.x, y1, q1.y), Vector3(q0.x, y0, q0.y), 0xc8c4bc, Vector3(n.x * sg, 0, n.y * sg).normalized())

## A tamarisk: its thick trunk leaning, forking into limbs that reach out and up, its feathery dark crown in lumps
## that hang down round them (Street View: they droop to two metres off the lawn); `white`: its foot whitewashed.
func _tamarisk(at: Vector2, tall: float, crown: float, white := false) -> void:
	var y := ground(at.x, at.y)
	var ang0 := at.x * 1.7 + at.y
	var lean := Vector2(cos(ang0), sin(ang0)) * 0.9
	var fork := Vector3(at.x + lean.x, y + tall * 0.3, at.y + lean.y)
	bar(Vector3(at.x, y - 0.3, at.y), fork, 0.38, 0.38, 0x4e4034)
	if white:
		drum(Vector3(at.x, y - 0.05, at.y), 0.22, 0.21, 0.55, 0xf0eee8, 8)
	for k in range(4):
		var a := ang0 + TAU * k / 4.0 + 0.4 * sin(k * 2.1 + at.y)
		var reach := crown * (0.5 + 0.25 * _rnd(k + int(absf(at.x))))
		var end := fork + Vector3(cos(a) * reach, tall * (0.22 + 0.08 * float(k % 2)), sin(a) * reach)
		bar(fork, end, 0.2, 0.2, 0x4e4034)
		ball(end + Vector3(0, 0.3, 0), crown * 0.5, "taraje", 0.72, 10, 6)
		ball(end + Vector3(cos(a) * crown * 0.42, -crown * 0.05, sin(a) * crown * 0.42), crown * 0.36, "taraje2" if k % 2 == 0 else "taraje", 0.78, 9, 5)
	ball(fork + Vector3(0, tall * 0.52, 0), crown * 0.6, "taraje", 0.66, 10, 6)
	solid(Vector3(at.x, y + 1.0, at.y), Vector3(0.5, 2.4, 0.5))
	yard.append(at)
	trees += 1

## an iron bench with wooden slats, its back to the wall (`along`: which way it runs)
func _bench(at: Vector2, along: Vector2) -> void:
	var y := ground(at.x, at.y)
	_xf = Transform3D(Basis(Vector3(along.x, 0, along.y), Vector3.UP, Vector3(-along.y, 0, along.x)), Vector3(at.x, y, at.y))
	for i in range(4):
		box(-0.85, 0.42, -0.2 + i * 0.11, 1.7, 0.03, 0.09, 0x7a5232)
	for i in range(3):
		box(-0.85, 0.52 + i * 0.13, -0.27, 1.7, 0.09, 0.03, 0x7a5232)
	for s in [-0.8, 0.74]:
		box(s, 0.0, -0.27, 0.06, 0.9, 0.05, IRON_)
		box(s, 0.0, -0.22, 0.06, 0.42, 0.46, IRON_)
		box(s, 0.4, -0.22, 0.06, 0.05, 0.5, IRON_)
	home()
	solid(Vector3(at.x, y + 0.25, at.y), Vector3(1.8, 0.5, 0.5), atan2(-along.y, along.x))
	yard.append(at)
	benches += 1

## the park's notice board on its two posts, facing `look`
func _board(at: Vector2, look: Vector2) -> void:
	var y := ground(at.x, at.y)
	_xf = Transform3D(Basis(Vector3.UP, atan2(look.x, look.y)), Vector3(at.x, y, at.y))
	for x: float in [-0.48, 0.42]:
		box(x, -0.2, -0.03, 0.06, 2.0, 0.06, 0x5a5e60)
	box(-0.52, 1.0, 0.03, 1.04, 0.79, 0.03, 0xe8e8e6)
	_picture(-0.5, 0.5, 1.02, 1.77, 0.065, "panel")
	home()
	solid(Vector3(at.x, y + 1.0, at.y), Vector3(1.0, 2.0, 0.2), atan2(look.x, look.y))
	yard.append(at)

## the big tree in its pit on the west pavement: its trunk, its yellowing crown, the kerb of its pit
func _big_tree(at: Vector2) -> void:
	var y := ground(at.x, at.y)
	drum(Vector3(at.x, y - 0.3, at.y), 0.3, 0.22, 3.6, 0x5e5044, 8)
	bar(Vector3(at.x, y + 2.8, at.y), Vector3(at.x + 1.0, y + 4.6, at.y - 0.6), 0.2, 0.2, 0x5e5044)
	bar(Vector3(at.x, y + 2.8, at.y), Vector3(at.x - 0.8, y + 4.8, at.y + 0.7), 0.2, 0.2, 0x5e5044)
	ball(Vector3(at.x, y + 6.0, at.y), 3.0, "hoja", 0.78, 11, 6)
	ball(Vector3(at.x + 1.8, y + 5.0, at.y - 1.2), 2.0, "hoja", 0.8, 10, 5)
	ball(Vector3(at.x - 1.6, y + 5.2, at.y + 1.3), 2.1, "hoja", 0.8, 10, 5)
	var pit := PackedVector2Array([at + Vector2(-0.8, -0.8), at + Vector2(0.8, -0.8), at + Vector2(0.8, 0.8), at + Vector2(-0.8, 0.8)])
	_lay(pit, -0.02, "tierra_req")
	for i in range(4):
		_kerb_line(pit[i], pit[(i + 1) % 4])
	solid(Vector3(at.x, y + 1.2, at.y), Vector3(0.6, 2.6, 0.6))
	yard.append(at)
	trees += 1

## the no-entry sign on its post, facing `look` (`blue`: with the blue round sign to turn right under it)
func _no_entry(at: Vector2, look: Vector2, blue := false) -> void:
	var y := ground(at.x, at.y)
	drum(Vector3(at.x, y - 0.2, at.y), 0.035, 0.035, 2.6, 0x9a9c9e, 6)
	_xf = Transform3D(Basis(Vector3.UP, atan2(look.x, look.y)), Vector3(at.x, y + 2.15, at.y))
	pieces += 1
	var pts := PackedVector2Array()
	for k in range(16):
		pts.append(Vector2(cos(TAU * k / 16.0) * 0.3, sin(TAU * k / 16.0) * 0.3))
	slab(pts, 0.05, 0.02, 0xc81e24)
	box(-0.21, -0.05, 0.051, 0.42, 0.1, 0.01, 0xf4f4f2)
	if blue:
		_xf = Transform3D(Basis(Vector3.UP, atan2(look.x, look.y)), Vector3(at.x, y + 1.5, at.y))
		slab(pts, 0.05, 0.02, 0x1f4fa0)
		box(-0.19, -0.035, 0.051, 0.24, 0.07, 0.01, 0xf4f4f2)
		tri(Vector3(0.04, -0.12, 0.062), Vector3(0.2, 0.0, 0.062), Vector3(0.04, 0.12, 0.062), 0xf4f4f2, Vector3(0, 0, 1))
	home()
	solid(Vector3(at.x, y + 1.2, at.y), Vector3(0.1, 2.4, 0.1))
	yard.append(at)

# ---------------- helpers ----------------
func _ccw(p: PackedVector2Array) -> PackedVector2Array:
	if Geometry2D.is_polygon_clockwise(p):
		p.reverse()
	return p

## the relief's triangles round a box of the map
func _facets(box_: Rect2) -> Array:
	var out: Array = []
	var gg: float = MapData.rg
	for i in range(int(floor((box_.position.x - MapData.rx0) / gg)), int(floor((box_.end.x - MapData.rx0) / gg)) + 1):
		for j in range(int(floor((box_.position.y - MapData.rz0) / gg)), int(floor((box_.end.y - MapData.rz0) / gg)) + 1):
			var a := Vector2(MapData.rx0 + i * gg, MapData.rz0 + j * gg)
			out.append(_ccw(PackedVector2Array([a, a + Vector2(gg, 0), a + Vector2(gg, gg)])))
			out.append(_ccw(PackedVector2Array([a, a + Vector2(gg, gg), a + Vector2(0, gg)])))
	return out

## a flat piece of this outline (on the map) laid on the ground `lift` over it, cut along the relief's facets (so that it
## lies on it exactly: under the pavements, -0.09; over them, -0.045)
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
				var p0: Vector2 = piece[idx[t]]
				var p1: Vector2 = piece[idx[t + 1]]
				var p2: Vector2 = piece[idx[t + 2]]
				tri(Vector3(p0.x, ground(p0.x, p0.y) + lift, p0.y), Vector3(p1.x, ground(p1.x, p1.y) + lift, p1.y), Vector3(p2.x, ground(p2.x, p2.y) + lift, p2.y), key, Vector3.UP)
	_xf = keep
