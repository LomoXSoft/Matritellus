extends "res://scripts/obra.gd"
## The Noche (the user's name for the Dia of the Calle del Teniente Infante, 17 November 2026: "Puedes empezar con el Dia
## (al que llamaremos Noche) ... Hazle lo mismo de siempre. Modelo abierto y cerrado según el horario. Haz que se pueda
## pasar y haz un interior genérico de momento"; and, with a picture of it as it was: "Mismos colores y diseños, pero que
## ponga noche y el logotipo en vez de un porcentaje, una luna").
##
## The house of three floors the shop is in (Catastro 4290005VJ5649S, of 2005: the shop on the ground floor, two flats
## over it): its front of cream render between two pilasters of brick; on the ground floor the arched door of the flats,
## green iron and glass in a brick surround, and the shop; over them two balconies swelling out in a bow, iron railings,
## the doors behind them with their roller blinds; at the top a bowed cornice. The shop as it was in Street View until
## 2019 (the user's picture): white, framed by a broad red band with rounded corners; the red board over the door with
## the name and the moon in its square, the strip of lime green under it; the door set back between panels of lime
## green; the red square sign standing out from the corner. Its hours: Monday to Saturday 9:00 to 21:30, Sunday shut
## (the user). Open: the shutter up, lit inside, the board of offers out on the pavement; shut: the grey shutter down.
## Its door takes you in (entradas.gd): the inside is a set apart (noche_dentro.gd).
##
## Frame: origin at the east end of its front, +x along the front westwards, +z out of it (north, to the street); y = 0
## the shop's floor. Measured: referencias/noche/LEEME.md, tools/noche/.

const READY := true                 # (tools/bake_godot.py: Catastro's block is not raised while this is true)
const NAME := "Noche"
const DIR := "res://assets/noche/"
const DentroS = preload("res://scripts/noche_dentro.gd")
const POSTER := "res://assets/chinos/poster_roster.png"         # the user's "Roster Energy" poster (tools/chinos/poster.py): on the white beside the door, at his word
const O := Vector2(-10.62, 99.01)   # the east end of its front (Catastro)
const U := Vector2(-0.98945, 0.14483)   # along the front, westwards
const WIDE := 7.8
const DOWN := -3.0                  # walls go on down under the pavement
const TOP := 10.2                   # its height (the cornice)
const FLOOR1 := 3.45                # the first floor's balcony slab
const FLOOR2 := 6.6
const PIER := 0.45                  # the brick pilasters at its ends
const ARCH := [0.85, 3.05, 2.45, 3.05]    # the flats' door: its sides, where its low arch springs and its crown
const SHOP0 := 3.6                  # the shop: its red band from here...
const SHOP1 := 7.8                  # ...to the west end
const DOOR := [4.55, 6.59, 2.74]    # its doorway: sides, top
const RECESS := 0.6                 # how far back the glass doors stand
const BAND := 0.3                   # the red band
const BAND_TOP := 3.42
const BOARD := [4.55, 7.0, 2.93, 3.42]      # the board: from, to, foot, top (the lime strip under it, down to the doorway)
const BOW := [0.6, 7.2, 0.95]       # the balconies: from, to, how far they swell out
const OPENS := 9.0                  # Monday to Saturday 9:00 to 21:30; Sunday shut (the user)
const SHUTS := 21.5
const RED := 0xd6202a
const LIME := 0xb2ce34
const WHITE := 0xf6f5f1
const HIERRO := 0x2a2a2c
const GREEN_DOOR := 0x1d4a3c
const WOOD := 0x6b4a32
# Catastro's parts: the house of three floors (its front is the frame's x axis) and the shop's hall behind, of one
const RING3: Array = [Vector2(-10.62, 99.01), Vector2(-10.24, 103.61), Vector2(-9.92, 107.52), Vector2(-9.69, 110.38), Vector2(-9.43, 113.56),
	Vector2(-9.04, 118.26), Vector2(-17.35, 118.88), Vector2(-17.45, 117.68), Vector2(-17.48, 114.24), Vector2(-18.33, 114.31), Vector2(-18.88, 108.81),
	Vector2(-17.96, 108.79), Vector2(-18.11, 105.32), Vector2(-18.34, 100.14)]
const RING1: Array = [Vector2(-9.04, 118.26), Vector2(-8.82, 121.05), Vector2(-7.54, 120.85), Vector2(-6.66, 130.36), Vector2(-6.47, 132.45),
	Vector2(-7.89, 132.52), Vector2(-11.93, 132.53), Vector2(-13.06, 143.35), Vector2(-19.53, 143.34), Vector2(-19.97, 143.34), Vector2(-19.79, 132.35),
	Vector2(-19.74, 129.33), Vector2(-19.48, 129.34), Vector2(-16.41, 129.39), Vector2(-17.35, 118.88)]

var door: Vector2                   # before its door, on the map
var tienda                          # its inside, a set apart (noche_dentro.gd): what you go into from its door
var is_open := true
var outline3: PackedVector2Array
var outline1: PackedVector2Array
var _shut: Node3D                   # what shows only while it is shut: the shutter down
var _open: Node3D                   # ...and while it is open: the board of offers on the pavement, its inside lit

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"crema":            # the house's render
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.87, 0.67)), 0.16)
		"ladrillo":         # the pale brick of its pilasters, its surrounds and the edges of its balconies (between casas.gd's
			m = Tex.mat("brick_wall_003@1.15", Color(1.38, 1.24, 1.1))      # "brick_pale" and "brick_salmon")
		"blanco":           # the shop's white panels (white in the shade too)
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 1.0, 0.99)), 0.25)
		"rotulo", "mercado", "banderola", "cartel", "horario":
			var tm := StandardMaterial3D.new()
			tm.albedo_texture = load(DIR + String(key) + ".png")
			tm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			tm.roughness = 0.6
			m = tm
		"roster":           # the poster: printed paper, bright in the shade too
			var rm := StandardMaterial3D.new()
			rm.albedo_texture = Parts.texture(POSTER)
			rm.roughness = 1.0
			m = _glow(rm, 0.3)
		"persiana":
			var pm := StandardMaterial3D.new()
			pm.albedo_texture = load(DIR + "persiana.png")
			pm.uv1_triplanar = true
			pm.uv1_scale = Vector3.ONE
			pm.roughness = 0.7
			pm.metallic_specular = 0.4
			m = pm
		"cristal":
			var gm := StandardMaterial3D.new()
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.albedo_color = Color(0.55, 0.62, 0.64, 0.32)
			gm.roughness = 0.1
			gm.metallic_specular = 0.6
			gm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = gm
		"visillo":          # the white curtains behind the glass of the flats' door and windows
			var vm := StandardMaterial3D.new()
			vm.albedo_color = Color(0.86, 0.92, 0.9)
			vm.emission_enabled = true
			vm.emission = Color(0.86, 0.92, 0.9)
			vm.emission_energy_multiplier = 0.15
			m = vm
		"sala", "luz":      # inside the shop, seen through its doors: lit while it is open
			var sm := StandardMaterial3D.new()
			sm.albedo_color = Color(0.85, 0.85, 0.82) if key == "sala" else Color(1.0, 0.98, 0.93)
			sm.emission_enabled = true
			sm.emission = Color(0.97, 0.96, 0.92)
			sm.emission_energy_multiplier = 0.3 if key == "sala" else 1.6
			m = sm
		"terrado":          # the flat roofs, of red tiles
			m = Parts.mat(0x9c5e48)
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	_frame(0.0)
	var top := -1e9
	for x in [3.8, 5.0, 6.5, 7.6]:                                   # the shop's floor: a step up from the pavement before it
		top = maxf(top, MapData.height(spot(x, 0.5)))
	level = top + 0.12
	_frame(level)
	W.add_child(self)
	door = spot((DOOR[0] + DOOR[1]) / 2.0, 1.2)
	_front()
	_flats_door()
	_shop()
	_balconies()
	_top()
	_body()
	home()
	_commit()
	_states()
	var dx: float = (DOOR[0] + DOOR[1]) / 2.0
	tienda = DentroS.new()
	tienda.build(world, NAME, spot(dx, -RECESS + 0.25), spot(dx, 1.4), _out_heading())
	_tell_map()
	set_open(open_at(0, 12.0))

func _frame(y: float) -> void:
	transform = Transform3D(Basis(Vector3(U.x, 0, U.y), Vector3.UP, Vector3(-U.y, 0, U.x)), Vector3(O.x, y, O.y))

## which way you face coming out of its door (out to the street)
func _out_heading() -> float:
	var n := Vector2(-U.y, U.x)
	return atan2(n.x, n.y)

## a spot of the map in this frame
func _fr(p: Vector2) -> Vector2:
	var r := p - O
	return Vector2(r.dot(U), r.dot(Vector2(-U.y, U.x)))

## the pavement under the front, at x: how far below the floor
func _foot(x: float) -> float:
	return minf(ground(x, 0.3), ground(x, 1.0))

# ---------------- the front ----------------
## its render and its two pilasters of brick, over the ground floor (and down to the ground beside the flats' door)
func _front() -> void:
	home()
	var g: float = minf(_foot(0.0), _foot(WIDE))
	# the pilasters: the east one from the ground, the west one from over the shop
	box(0.0, DOWN, -0.25, PIER, TOP - DOWN, 0.29, "ladrillo")
	box(WIDE - PIER, FLOOR1, -0.25, PIER, TOP - FLOOR1, 0.29, "ladrillo")
	# the render between them, from the first floor's slab up, round the windows of the two floors
	var holes: Array = [Rect2(2.3, FLOOR1 + 0.45, 3.2, 2.3), Rect2(2.3, FLOOR2 + 0.45, 3.2, 2.3)]
	masonry(PIER, WIDE - PIER, FLOOR1, TOP, holes, [], "crema")
	box(PIER, FLOOR1, -0.25, WIDE - 2.0 * PIER, TOP - FLOOR1, 0.01, "crema")          # (behind the holes: the wall's back)
	# the ground floor beside the flats' door: render (over the door, down to its brick ring), a skirting of pale stone
	masonry(PIER, SHOP0, DOWN, FLOOR1, [Rect2(ARCH[0] - 0.3, DOWN, ARCH[1] - ARCH[0] + 0.6, FLOOR1 - DOWN)], [], "crema")
	var xl: float = ARCH[0] - 0.3
	var xr: float = ARCH[1] + 0.3
	var over := PackedVector2Array([Vector2(xl, FLOOR1)])
	for p: Vector2 in _arc(0.3, true):
		over.append(p)
	over.append(Vector2(xr, FLOOR1))
	slab(over, 0.0, 0.0, "crema")
	box(PIER, g - 0.4, 0.0, ARCH[0] - 0.3 - PIER, 0.4 - g + 0.25, 0.04, STONE)
	box(ARCH[1] + 0.3, g - 0.4, 0.0, SHOP0 - ARCH[1] - 0.3, 0.4 - g + 0.25, 0.04, STONE)
	# a box of meters on the pilaster, the cables along the front under the first balcony
	box(0.05, FLOOR1 - 0.05, 0.04, 0.38, 0.42, 0.14, 0xeceae2)
	bar(Vector3(0.2, FLOOR1 - 0.12, 0.08), Vector3(WIDE + 0.2, FLOOR1 - 0.22, 0.08), 0.025, 0.025, HIERRO)
	bar(Vector3(0.0, FLOOR1 - 0.3, 0.06), Vector3(WIDE, FLOOR1 - 0.28, 0.06), 0.02, 0.02, HIERRO)
	bar(Vector3(0.25, FLOOR1 - 0.12, 0.08), Vector3(0.25, FLOOR1 + 1.6, 0.08), 0.02, 0.02, HIERRO)

## the low arch over the flats' door: its circle's middle and radius (it springs at ARCH[2] and rises to ARCH[3])
func _arch_circle() -> Array:
	var s: float = ARCH[1] - ARCH[0]
	var h: float = ARCH[3] - ARCH[2]
	var r: float = (s * s / 4.0 + h * h) / (2.0 * h)
	return [Vector2((ARCH[0] + ARCH[1]) / 2.0, ARCH[3] - r), r]

## points along that arch (from the left to the right), `grow` out from the door's edge; with `ends`, carried out
## level to the outside of the brick surround
func _arc(grow: float, ends := false) -> Array:
	var c: Array = _arch_circle()
	var mid: Vector2 = c[0]
	var r: float = float(c[1]) + grow
	var half: float = (ARCH[1] - ARCH[0]) / 2.0 + grow
	var a0: float = acos(clampf(-half / r, -1.0, 1.0))
	var out: Array = []
	if ends:
		out.append(Vector2(ARCH[0] - grow, mid.y + r * sin(a0)))
	for k in range(17):
		var a: float = lerpf(a0, PI - a0, k / 16.0)
		out.append(mid + Vector2(cos(a), sin(a)) * r)
	if ends:
		out.append(Vector2(ARCH[1] + grow, mid.y + r * sin(a0)))
	return out

## the flats' door: green iron and glass under a low arch, a fan of bars in its head, in a surround of brick
func _flats_door() -> void:
	home()
	var c: Array = _arch_circle()
	var mid: Vector2 = c[0]
	var r: float = c[1]
	var cx: float = mid.x
	var spring: float = ARCH[2]
	var g: float = _foot(cx)
	var inner: Array = _arc(0.0)
	var outer: Array = _arc(0.3)
	inner.reverse()                                      # (right to left: the brick ring is the band between them)
	# the surround: brick jambs, the brick ring of its head, its bricks on end standing a little proud
	box(ARCH[0] - 0.3, g - 0.1, -0.02, 0.3, spring - g + 0.2, 0.08, "ladrillo")
	box(ARCH[1], g - 0.1, -0.02, 0.3, spring - g + 0.2, 0.08, "ladrillo")
	var band := PackedVector2Array()
	for p: Vector2 in outer:
		band.append(p)
	for p: Vector2 in inner:
		band.append(p)
	slab(band, 0.06, 0.08, "ladrillo")
	for k in range(15):
		var t: float = (k + 0.5) / 15.0
		var a: float = lerpf(acos(clampf(-(ARCH[1] - ARCH[0]) / 2.0 / r, -1.0, 1.0)), PI - acos(clampf(-(ARCH[1] - ARCH[0]) / 2.0 / r, -1.0, 1.0)), t)
		var p := mid + Vector2(cos(a), sin(a)) * (r + 0.15)
		tbox(Transform3D(Basis(Vector3.BACK, a - PI / 2.0) * Basis.from_scale(Vector3(0.05, 0.3, 0.02)), Vector3(p.x, p.y, 0.08)), 0xc49a72)
	# its leaves, set back: white curtains behind glass, green iron in squares over them, the brass of their handles
	var z := -0.22
	var leaf := PackedVector2Array([Vector2(ARCH[0], g), Vector2(ARCH[1], g)])
	var head: Array = _arc(0.0)
	head.reverse()
	for p: Vector2 in head:
		leaf.append(p)
	slab(leaf, z - 0.02, 0.0, "visillo")
	var top_at := func(x: float) -> float:
		return mid.y + sqrt(maxf(0.0, r * r - (x - cx) * (x - cx)))
	for x in [ARCH[0], cx - 0.04, cx + 0.04, ARCH[1] - 0.08]:
		box(x, g, z, 0.08, top_at.call(x + 0.04) - g, 0.06, GREEN_DOOR)
	for k in range(1, 6):                                # the grid of iron over the glass
		var y: float = g + k * (spring - g) / 6.0
		box(ARCH[0], y - 0.02, z + 0.02, ARCH[1] - ARCH[0], 0.04, 0.04, GREEN_DOOR)
	for k in range(1, 8):
		var x: float = ARCH[0] + k * (ARCH[1] - ARCH[0]) / 8.0
		box(x - 0.015, g, z + 0.02, 0.03, spring - g, 0.04, GREEN_DOOR)
	box(ARCH[0], g, z, ARCH[1] - ARCH[0], 0.35, 0.07, GREEN_DOOR)                        # the plate at their foot
	box(ARCH[0], spring - 0.05, z, ARCH[1] - ARCH[0], 0.08, 0.07, GREEN_DOOR)             # the transom
	for k in range(9):                                   # the fan in its head
		var x: float = lerpf(ARCH[0] + 0.15, ARCH[1] - 0.15, k / 8.0)
		bar(Vector3(cx, spring, z + 0.03), Vector3(x, top_at.call(x) - 0.03, z + 0.03), 0.025, 0.025, GREEN_DOOR)
	for i in range(head.size() - 1):                     # the iron edge of its head
		var a: Vector2 = head[i]
		var b: Vector2 = head[i + 1]
		bar(Vector3(a.x, a.y - 0.03, z + 0.03), Vector3(b.x, b.y - 0.03, z + 0.03), 0.05, 0.06, GREEN_DOOR)
	for s in [-1.0, 1.0]:
		box(cx + s * 0.18 - 0.07, g + 1.05, z + 0.07, 0.14, 0.03, 0.03, 0xc9a24a)
	box(ARCH[0] - 0.3, g - 0.3, -0.25, ARCH[1] - ARCH[0] + 0.6, 0.3, 0.3, STONE)         # its step
	_solid(ARCH[0] - 0.3, g, -0.6, ARCH[1] + 0.3, FLOOR1, z)

## The shop: white, framed by the broad red band with rounded corners; its board and its lime strip; the doorway set
## back between lime panels, its two glass doors, the shop lit behind them; the red square sign standing out at the
## corner; the plate of its hours.
func _shop() -> void:
	home()
	var g: float = minf(_foot(SHOP0), _foot(SHOP1))
	# the white: left of the doorway, right of it, over it
	box(SHOP0, g - 0.2, -0.12, DOOR[0] - SHOP0, BAND_TOP - g + 0.2, 0.12, "blanco")
	box(DOOR[1], g - 0.2, -0.12, SHOP1 - DOOR[1], BAND_TOP - g + 0.2, 0.12, "blanco")
	box(DOOR[0], DOOR[2], -0.12, DOOR[1] - DOOR[0], BAND_TOP - DOOR[2], 0.12, "blanco")
	box(SHOP0, BAND_TOP, -0.12, SHOP1 - SHOP0, FLOOR1 - BAND_TOP, 0.12, "crema")
	# the red band: up the left, round, along the top, round, down the right
	var rc := 0.62
	var z := 0.0
	box(SHOP0, g - 0.1, z, BAND, BAND_TOP - rc - g + 0.1, 0.05, RED)
	box(SHOP1 - BAND, g - 0.1, z, BAND, BAND_TOP - rc - g + 0.1, 0.05, RED)
	box(SHOP0 + rc, BAND_TOP - BAND, z, SHOP1 - SHOP0 - 2.0 * rc, BAND, 0.05, RED)
	for c in [[SHOP0 + rc, PI / 2.0, PI], [SHOP1 - rc, 0.0, PI / 2.0]]:
		var pts := PackedVector2Array()
		for k in range(9):
			var a: float = lerpf(c[1], c[2], k / 8.0)
			pts.append(Vector2(c[0] + cos(a) * rc, BAND_TOP - rc + sin(a) * rc))
		for k in range(8, -1, -1):
			var a: float = lerpf(c[1], c[2], k / 8.0)
			pts.append(Vector2(c[0] + cos(a) * (rc - BAND), BAND_TOP - rc + sin(a) * (rc - BAND)))
		slab(pts, z + 0.05, 0.05, RED)
	# the board and the lime strip under it
	box(BOARD[0] - 0.03, BOARD[2] - 0.22, 0.0, BOARD[1] - BOARD[0] + 0.06, BOARD[3] - BOARD[2] + 0.25, 0.1, RED)
	_picture(BOARD[0], BOARD[1], BOARD[2], BOARD[3], 0.112, "rotulo")
	_picture(BOARD[0], BOARD[1], BOARD[2] - 0.19, BOARD[2], 0.112, "mercado")
	# the doorway: its sides of lime, its ceiling, the floor of the step
	for x in [DOOR[0], DOOR[1]]:
		var s: float = 1.0 if x == DOOR[0] else -1.0
		quad(Vector3(x, 0.0, -0.12), Vector3(x, 0.0, -RECESS), Vector3(x, DOOR[2], -RECESS), Vector3(x, DOOR[2], -0.12), LIME, Vector3(s, 0, 0))
	quad(Vector3(DOOR[0], DOOR[2], -0.12), Vector3(DOOR[1], DOOR[2], -0.12), Vector3(DOOR[1], DOOR[2], -RECESS), Vector3(DOOR[0], DOOR[2], -RECESS), WHITE, Vector3.DOWN)
	flat(PackedVector2Array([Vector2(DOOR[0], 0.2), Vector2(DOOR[1], 0.2), Vector2(DOOR[1], -RECESS), Vector2(DOOR[0], -RECESS)]), 0.0, 0xc9c4ba)
	box(DOOR[0] - 0.05, g - 0.3, -0.12, DOOR[1] - DOOR[0] + 0.1, 0.3 - g, 0.32, 0xc9c4ba)
	# the glass doors: two sliding leaves between two fixed panes, their frames dark, the sensor over them
	var gz := -RECESS
	var w: float = DOOR[1] - DOOR[0]
	_picture(DOOR[0], DOOR[1], 0.02, DOOR[2] - 0.1, gz, "cristal")
	for x in [DOOR[0], DOOR[0] + w * 0.25, DOOR[0] + w * 0.5, DOOR[0] + w * 0.75, DOOR[1]]:
		box(x - 0.035, 0.0, gz - 0.03, 0.07, DOOR[2], 0.06, 0x3b3e42)
	box(DOOR[0], DOOR[2] - 0.12, gz - 0.03, w, 0.12, 0.06, 0x3b3e42)
	box(DOOR[0], 0.0, gz - 0.03, w, 0.05, 0.06, 0x3b3e42)
	box(DOOR[0] + w * 0.5 - 0.1, DOOR[2] - 0.2, gz + 0.03, 0.2, 0.06, 0.04, 0x1a1a1a)
	for x in [DOOR[0] + 0.12, DOOR[1] - 0.6]:            # offers stuck on the fixed panes
		box(x, 1.0, gz + 0.04, 0.48, 0.64, 0.005, 0xf2c428)
		box(x + 0.04, 1.42, gz + 0.045, 0.4, 0.16, 0.005, RED)
	# the plate of its hours, a small black lamp of the alarm by the band
	_picture(7.04, 7.36, 1.5, 1.75, 0.005, "horario")
	if Parts.texture(POSTER) != null:                    # the Roster poster on the white left of the door, stuck on a little askew (the user, 17 Nov 2026)
		var pk := _xf
		_xf = _xf * Transform3D(Basis(Vector3.BACK, 0.05), Vector3((SHOP0 + BAND + DOOR[0]) / 2.0, 1.45, 0.006))
		_picture(-0.24, 0.24, -0.32, 0.32, 0.0, "roster")
		_xf = pk
	box(SHOP0 + 0.02, BAND_TOP + 0.05, 0.0, 0.14, 0.14, 0.1, HIERRO)
	# the square sign standing out at the corner: a red box on an arm, the moon on both faces
	var sx := WIDE + 0.06
	box(sx, 2.95, -0.05, 0.08, 0.06, 0.18, HIERRO)
	box(sx, 3.35, -0.05, 0.08, 0.06, 0.18, HIERRO)
	var keep := _xf
	_xf = _xf * Transform3D(Basis(Vector3.UP, -PI / 2.0), Vector3(sx + 0.05, 0.0, 0.12))     # (its faces look along the street)
	box(0.0, 2.85, -0.06, 0.6, 0.6, 0.12, RED)
	_picture(0.0, 0.6, 2.85, 3.45, 0.072, "banderola")
	_xf = _xf * Transform3D(Basis(Vector3.UP, PI), Vector3(0.6, 0.0, 0.0))
	_picture(0.0, 0.6, 2.85, 3.45, 0.072, "banderola")
	_xf = keep
	_solid(SHOP0, g, -0.7, DOOR[0], BAND_TOP, 0.0)
	_solid(DOOR[1], g, -0.7, SHOP1, BAND_TOP, 0.0)
	_solid(DOOR[0], g, -RECESS - 0.3, DOOR[1], DOOR[2], -RECESS)

## the two balconies swelling out in a bow: a slab edged in brick, tiled on top, an iron railing; the doors behind them
## with their roller blinds, white curtains; the air conditioners
func _balconies() -> void:
	home()
	for y in [FLOOR1, FLOOR2]:
		_bow(y, y + 0.42, BOW[0], BOW[1], BOW[2], "ladrillo", 0xa8644a)
		_railing(y + 0.42, BOW[0] + 0.08, BOW[1] - 0.08, BOW[2] - 0.08)
		# the doors behind: frames of wood, four leaves, the blind's box and the blind half down
		var x0 := 2.3
		var x1 := 5.5
		var y0: float = y + 0.45
		var yt: float = y0 + 2.3
		box(x0, y0, -0.23, x1 - x0, 2.3, 0.02, "visillo")
		for k in range(5):
			box(x0 + k * (x1 - x0) / 4.0 - 0.04, y0, -0.22, 0.08, 2.3, 0.07, WOOD)
		box(x0, y0 + 1.1, -0.22, x1 - x0, 0.06, 0.07, WOOD)
		box(x0, yt - 0.9, -0.185, x1 - x0, 0.9, 0.05, 0x7a5236)                             # the blind, half down
		for k in range(8):
			box(x0, yt - 0.9 + k * 0.11, -0.135, x1 - x0, 0.015, 0.01, 0x5a3c28)
		box(x0 - 0.1, yt, -0.05, x1 - x0 + 0.2, 0.3, 0.2, 0x7a5236)                       # its box
		box(x0 - 0.12, y0 - 0.02, 0.0, 0.12, 2.6, 0.06, "ladrillo")                         # its jambs of brick
		box(x1, y0 - 0.02, 0.0, 0.12, 2.6, 0.06, "ladrillo")
	# the air conditioners on the balconies, an awning folded over the first-floor doors
	box(5.9, FLOOR1 + 0.42, 0.1, 0.75, 0.52, 0.3, 0xeeeeea)
	drum(Vector3(6.275, FLOOR1 + 0.68, 0.41), 0.17, 0.17, 0.005, 0x6a6c6e, 12)
	box(5.6, FLOOR2 + 2.3, -0.05, 0.75, 0.52, 0.3, 0xeeeeea)

## a slab swelling out in a bow (from x0 to x1 along the front, `out` at its middle), y0 to y1
func _bow(y0: float, y1: float, x0: float, x1: float, out: float, edge, top) -> void:
	var pts: Array = []
	var n := 14
	for k in range(n + 1):
		var t: float = float(k) / n
		pts.append(Vector2(lerpf(x0, x1, t), out * sin(PI * t)))
	pieces += 1
	for k in range(n):                                   # its top and its underside: fans from the middle of the chord
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[k + 1]
		var m := Vector2((x0 + x1) / 2.0, -0.02)
		tri(Vector3(m.x, y1, m.y), Vector3(a.x, y1, a.y), Vector3(b.x, y1, b.y), top, Vector3.UP)
		tri(Vector3(m.x, y0, m.y), Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), "crema", Vector3.DOWN)
		var d := (b - a).normalized()
		quad(Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y), edge, Vector3(-d.y, 0, d.x))

## an iron railing along the same bow: rails, bars, a band of scrolls low down
func _railing(y: float, x0: float, x1: float, out: float) -> void:
	var n := 14
	var prev := Vector3.ZERO
	for k in range(n + 1):
		var t: float = float(k) / n
		var p := Vector3(lerpf(x0, x1, t), y, out * sin(PI * t))
		if k > 0:
			bar(prev + Vector3(0, 1.0, 0), p + Vector3(0, 1.0, 0), 0.05, 0.04, HIERRO)
			bar(prev + Vector3(0, 0.08, 0), p + Vector3(0, 0.08, 0), 0.03, 0.03, HIERRO)
			bar(prev + Vector3(0, 0.26, 0), p + Vector3(0, 0.26, 0), 0.02, 0.02, HIERRO)
			var bars := 4
			for j in range(bars):
				var q: Vector3 = prev.lerp(p, (j + 0.5) / bars)
				bar(q + Vector3(0, 0.08, 0), q + Vector3(0, 1.0, 0), 0.016, 0.016, HIERRO)
			var mid: Vector3 = prev.lerp(p, 0.5)
			ball(mid + Vector3(0, 0.17, 0), 0.07, HIERRO, 1.0, 6, 4)
		prev = p
	for x in [x0, x1]:
		bar(Vector3(x, y, 0.0), Vector3(x, y + 1.0, 0.0), 0.04, 0.04, HIERRO)

## the top: a bowed cornice of brick over the second floor's balcony, the parapet of the roof
func _top() -> void:
	home()
	_bow(TOP - 0.45, TOP - 0.1, BOW[0] - 0.2, BOW[1] + 0.2, BOW[2] + 0.15, "ladrillo", 0xb9a088)
	box(0.0, TOP - 0.1, -0.3, WIDE, 0.3, 0.32, "ladrillo")
	box(-0.02, TOP + 0.2, -0.32, WIDE + 0.04, 0.06, 0.36, 0xd8c8b0)

## the rest of the house, out of the street's sight: its sides and its back of render, the roofs of red tiles, the
## shop's hall behind, a box of the stairs on the roof
func _body() -> void:
	outline3 = PackedVector2Array()
	for p: Vector2 in RING3:
		outline3.append(p)
	outline1 = PackedVector2Array()
	for p: Vector2 in RING1:
		outline1.append(p)
	_walls(RING3, TOP, true)
	_walls(RING1, 4.3, false)
	home()
	var f3: Array = []
	for p: Vector2 in RING3:
		f3.append(_fr(p))
	var f1: Array = []
	for p: Vector2 in RING1:
		f1.append(_fr(p))
	flat(PackedVector2Array(f3), TOP + 0.15, "terrado")
	flat(PackedVector2Array(f1), 4.32, "terrado")
	_prism(f3, DOWN, TOP)
	_prism(f1, DOWN, 4.3)
	var st: Vector2 = _fr(Vector2(-13.3, 110.0))                                         # the box of the stairs on the roof
	box(st.x - 1.4, TOP + 0.2, st.y - 1.6, 2.8, 2.3, 3.2, "crema")
	box(st.x - 1.5, TOP + 2.5, st.y - 1.7, 3.0, 0.12, 3.4, 0x9c5e48)

## the walls of one of its parts, all but its front (the frame's x axis): render down to the ground
func _walls(ring: Array, h: float, skip_front: bool) -> void:
	var f: Array = []
	for p: Vector2 in ring:
		f.append(_fr(p))
	var area := 0.0
	for i in range(f.size()):
		var a: Vector2 = f[i]
		var b: Vector2 = f[(i + 1) % f.size()]
		area += a.x * b.y - b.x * a.y
	for i in range(f.size()):
		var a: Vector2 = f[i]
		var b: Vector2 = f[(i + 1) % f.size()]
		if skip_front and absf(a.y) < 0.05 and absf(b.y) < 0.05:
			continue
		if a.distance_to(b) < 0.05:
			continue
		var l: Vector2 = a if area < 0.0 else b
		var r: Vector2 = b if area < 0.0 else a
		var ln: float = face(l, r)
		box(0.0, DOWN, -0.2, ln, h - DOWN, 0.2, "crema")
	home()

# ---------------- open and shut ----------------
## what shows only while it is open (the board of offers on the pavement, the shop lit behind its glass) and only while
## it is shut (the shutter down over its doorway)
func _states() -> void:
	_open = Node3D.new()
	add_child(_open)
	home()
	var bx := 7.35
	var by: float = _foot(bx)
	var keep := _xf
	_xf = Transform3D(Basis(Vector3.UP, 0.35), Vector3(bx, by, 0.85))                     # the board of offers, standing open on the pavement
	box(-0.32, 0.0, -0.02, 0.04, 1.0, 0.04, RED)
	box(0.28, 0.0, -0.02, 0.04, 1.0, 0.04, RED)
	tbox(Transform3D(Basis(Vector3.RIGHT, 0.22) * Basis.from_scale(Vector3(0.64, 0.9, 0.03)), Vector3(0.0, 0.48, 0.1)), RED)
	_xf = _xf * Transform3D(Basis(Vector3.RIGHT, 0.22), Vector3(0.0, 0.48, 0.12))
	_picture(-0.28, 0.28, -0.4, 0.38, 0.0, "cartel")
	_xf = keep
	# the shop seen through the glass: the room, its lights, shelves of goods, the till by the door
	var z0 := -RECESS - 0.05
	box(SHOP0 + 0.2, 0.0, z0 - 6.0, SHOP1 - SHOP0 - 0.5, 0.02, 6.0, "sala")
	box(SHOP0 + 0.2, 3.0, z0 - 6.0, SHOP1 - SHOP0 - 0.5, 0.04, 6.0, "sala")
	box(SHOP0 + 0.2, 0.0, z0 - 6.1, SHOP1 - SHOP0 - 0.5, 3.0, 0.1, "sala")
	for x in [SHOP0 + 0.1, SHOP1 - 0.4]:
		box(x, 0.0, z0 - 6.0, 0.1, 3.0, 6.0, "sala")
	for k in range(3):
		box(SHOP0 + 0.8 + k * 1.2, 2.96, z0 - 5.0, 0.2, 0.03, 3.5, "luz")
	var cols: Array = [0xd8243a, 0xf2c230, 0x2c7a3a, 0x2a5fb0, 0xeeeeea, 0xe2702a]
	for j in range(2):                                   # two runs of shelves going in
		var sx: float = SHOP0 + 1.2 + j * 2.0
		box(sx, 0.0, z0 - 5.6, 0.8, 1.7, 3.6, 0xd9dadb)
		for row in range(4):
			for k in range(9):
				box(sx - 0.03, 0.15 + row * 0.4, z0 - 5.5 + k * 0.38, 0.03, 0.28, 0.32, cols[(row * 3 + k + j) % cols.size()])
	box(SHOP0 + 0.3, 0.0, z0 - 1.8, 0.7, 0.9, 1.3, 0x3d4045)                                # the till
	_commit_to(_open)
	_shut = Node3D.new()
	add_child(_shut)
	home()
	quad(Vector3(DOOR[0], 0.0, -0.13), Vector3(DOOR[1], 0.0, -0.13), Vector3(DOOR[1], DOOR[2], -0.13), Vector3(DOOR[0], DOOR[2], -0.13), "persiana", Vector3(0, 0, 1))
	box(DOOR[0], 0.0, -0.15, DOOR[1] - DOOR[0], 0.06, 0.04, 0x8a8e92)
	box((DOOR[0] + DOOR[1]) / 2.0 - 0.12, 0.08, -0.11, 0.24, 0.06, 0.03, 0x5a5e62)         # its lock
	_commit_to(_shut)

func _commit_to(node: Node3D) -> void:
	for key in _tools:
		var mi := MeshInstance3D.new()
		mi.mesh = (_tools[key] as SurfaceTool).commit()
		mi.material_override = _material(key)
		node.add_child(mi)
	_tools.clear()

## whether it is open on that day of the week (0 Monday ... 6 Sunday) at that hour
func open_at(day: int, hour: float) -> bool:
	if posmod(day, 7) == 6:
		return false
	return hour >= OPENS and hour < SHUTS

func _process(_delta: float) -> void:
	var game = W.get_parent() if W != null else null
	if game != null and "clock" in game and "weekday" in game:
		var want: bool = open_at(int(game.weekday), float(game.clock))
		if want != is_open:
			set_open(want)
		if _mats.has("rotulo"):                       # its board and its sign lit at dusk while it is open: their own colours
			var hr: float = float(game.clock)
			var lit: bool = is_open and (hr >= 18.5 or hr < 8.0)
			for key in ["rotulo", "mercado", "banderola"]:
				if _mats.has(key):
					var rm := _mats[key] as StandardMaterial3D
					rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if lit else BaseMaterial3D.SHADING_MODE_PER_PIXEL

## open: the shutter up, the board out, lit inside; shut: the shutter down, dark
func set_open(on: bool) -> void:
	is_open = on
	if tienda != null:
		tienda.open = on
	if _shut != null:
		_shut.visible = not on
		_open.visible = on
	for q in [["sala", 0.3], ["luz", 1.6]]:
		if _mats.has(q[0]):
			(_mats[q[0]] as StandardMaterial3D).emission_energy_multiplier = float(q[1]) if on else 0.0

# ---------------- helpers ----------------
func _picture(x0: float, x1: float, y0: float, y1: float, z: float, key) -> void:
	pieces += 1
	quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

func _solid(x0: float, y0: float, z0: float, x1: float, y1: float, z1: float) -> void:
	solid(Vector3((x0 + x1) / 2.0, (y0 + y1) / 2.0, (z0 + z1) / 2.0), Vector3(absf(x1 - x0), absf(y1 - y0), absf(z1 - z0)))

## its parts, for the little map and for whoever asks the map how much room there is
func _tell_map() -> void:
	for ring in [outline3, outline1]:
		MapData.outlines.append(ring)
		if not MapData._wall_grid.is_empty():
			for i in range(ring.size()):
				var a: Vector2 = ring[i]
				var c: Vector2 = ring[(i + 1) % ring.size()]
				MapData._grid_add(MapData._wall_grid, a.min(c), a.max(c), [a, c])
