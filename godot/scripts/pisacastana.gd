extends "res://scripts/esquina.gd"
## The shoe shop "Pisacastaña" of the corner of the Calle de los Arcos and the Calle Argentina: the real Pisamorena (the
## user, 23 November 2026: "Ahora la zapatería. Usaremos Pisamorena (que llamaremos Pisacastaña). Mismo tratamiento que
## las otras dos tiendas pero solo con zapatos"). Built by hand on Texturas's house of the map (arcos_5, handed over as
## ["obra"] in casas_calles.gd), with no rebake; referencias/pisacastana/. From Street View of November 2024 (and 2019,
## 2021 for the door and the windows).
##
## A block of flats on the corner: the ground floor and three floors over it, of orange brick, the floors above
## standing out over both pavements, a low hipped roof:
##   - the ground floor is white render on a foot of turquoise tiles. The shoe shop has the corner: to the Calle
##     Argentina a narrow frosted pane at the corner, two windows of shoes under cream awnings (white shelves; white cube
##     shelves) with the shop's board over the first, a frosted window of pale turquoise with the name in it, and the
##     door set back in a white doorway under a little glass canopy hung with ivy (a white roller shutter down over it
##     when shut, Street View 2024); to the Arcos one more window of shoes under its awning, the name on its top light.
##     Past the shop on the Argentina, the flats' own room in beige render, a window behind a white grille, a meter box,
##     two air conditioners. On the Arcos, past the shop, the flats' doorway in black granite (three steps up, a carved
##     wooden double door) and an appliance shop, shut and for sale, in black granite under a board and an awning (no
##     brand: "Electrodomésticos"; a "se vende" card in its window);
##   - the floors above: plain brick, white-framed windows with white roller blinds and lace behind the glass, brick
##     sills, a soldier course at each floor; on the Arcos a stack of loggias with red-brown railings (the first one half
##     shut in with white aluminium, its side painted orange; a green awning in the top one), plants, air conditioners, a
##     satellite dish, the street's name plate at the corner, the cables along the projection's edge.
## No number on it, no telephone, no social network (the game shows none). A saffron flower is hidden inside, in a shoe
## box by the bench (pisacastana_dentro.gd; the user: "Azafrán en caja de zapatos").
## Approved by the user, 23 Nov 2026: "Visto bueno".
##
## Its hours are the real shop's (Google Maps, 23 November 2026): Monday to Friday from ten to half past one and from
## five to eight, Saturdays from half past ten to two, shut on Sundays. A card on the frosted glass by the door says so.
## Open: the shutter up, the glass door behind it, light inside, the mannequin out on the pavement (maniqui.gd, with a
## stand of the day's shoes by it). Shut: the shutter down, the windows dim, the mannequin in. Its inside is a set of its
## own (pisacastana_dentro.gd), walked into by the green arrow before the door (entradas.gd).
##
## Frame: the map's own (x east, z south), y = 0 the pavement at the corner. Each front is built in its own frame
## (obra.face: +x along it, its left end seen from the street first; +z out of it).

const READY := true
const HOUSE := "arcos_5"
const NAME := "Pisacastaña"                      # what the shop is called in the game (the user, 23 Nov 2026)
const DIR := "res://assets/pisacastana/"
const DentroS = preload("res://scripts/pisacastana_dentro.gd")
const ManiquiS = preload("res://scripts/maniqui.gd")
## the mannequin at its door ("Mismo tratamiento"): on the Calle Argentina's pavement past the door (along it from the
## corner, out), turned a little towards the door
const MANIQUI := Vector2(12.25, 0.6)

# its outline on the map (the house arcos_5), in the ring's order
const P0 := Vector2(123.29, 89.19)               # its back: the wall to the plots north of it...
const P1 := Vector2(133.38, 91.21)               # ...and the corner of the one it shares with the house east of it
const E := Vector2(131.95, 105.78)               # where it ends on the Calle Argentina (the painting studio's house beyond)
const K := Vector2(116.54, 102.08)               # the corner
const N := Vector2(116.05, 88.65)                # where it ends on the Calle de los Arcos (the low white house beyond)

const BASE_T := 0.5             # the turquoise tiles at the shop's foot, up to here
const SILL := 0.62              # the shop's windows, from here...
const HEAD := 2.62              # ...to here
const AWNING := 2.7             # the awnings' boxes on the wall (the boards over them)
const SOFFIT := 3.55            # the underside of the floors above, which stand out over the pavements...
const OUT := 0.4                # ...this far
const F1 := 3.75                # the first floor
const F2 := 6.6
const F3 := 9.45
const TOP := 12.25              # the top of its walls, under the eaves (Catastro: 12.3 m for four floors)
const EAVE := 0.45
const PITCH := 0.3
const RISE0 := 0.135            # (EAVE * PITCH: the eaves' edge level with the walls' top)
const WIN_W := 1.3              # the flats' windows: how wide...
const WIN_SILL := 0.72          # ...their sills over each floor...
const WIN_H := 1.1              # ...how high
const RECESS := 0.95            # how far back the shop's door is
const LOG_D := 1.1              # how deep the loggias on the Arcos are
const LOG_H := 2.55             # how high
const BALC := 0.35              # how far their slabs stand out
# the Calle Argentina (x from the corner, east)
const AR_NARROW := Rect2(0.3, SILL, 0.45, HEAD - SILL)                               # the narrow frosted pane at the corner
const AR_WIN := [Rect2(1.05, SILL, 3.15, HEAD - SILL), Rect2(4.85, SILL, 3.1, HEAD - SILL)]      # the two windows of shoes
const AR_FROST := Rect2(8.5, SILL, 1.6, HEAD - SILL)                                # the frosted window with the name
const DOOR := Rect2(10.4, 0.0, 1.1, HEAD)                                           # the shop's door, set back
const BEIGE := 11.75                                                                 # the flats' room in beige render, from here to its end
const GRILLE := Rect2(12.6, 0.95, 2.25, 1.35)                                        # its window behind a white grille
const SIGN := Rect2(1.9, 2.9, 1.45, 0.62)                                            # the shop's board over the first window
const AR_UP := [3.3, 6.35, 9.4, 13.2]                                                # the flats' windows over it (their middles)
# the Calle de los Arcos (x from its north end, south to the corner)
const EL_END := 6.75                                                                 # the appliance shop, from its north end to here
const EL_DOOR := Rect2(0.32, 0.0, 2.0, 2.5)                                          # its door (a folding grille before it)...
const EL_WIN := [Rect2(2.58, 0.55, 1.8, 1.95), Rect2(4.65, 0.55, 1.62, 1.95)]         # ...its windows (a mesh grille behind the glass)
const PORTAL := Rect2(6.99, 0.0, 1.9, 2.75)                                         # the flats' doorway (black granite round it, 6.75 to 9.12)
const STONE_END := 9.12
const AC_WIN := Rect2(9.84, SILL, 2.75, HEAD - SILL)                                # the shoe shop's window on the Arcos
const FRISO := Rect2(10.27, 2.9, 1.9, 0.62)                                          # its top light with the name, over the awning
const AC_UP := [[2.34, 1.4], [11.15, 1.25]]                                          # the flats' windows over it (their middles, how wide)
const LOGGIA := Vector2(4.3, 9.9)                                                    # the loggias, from, to
const HOURS := {0: [Vector2(10.0, 13.5), Vector2(17.0, 20.0)], 1: [Vector2(10.0, 13.5), Vector2(17.0, 20.0)],
	2: [Vector2(10.0, 13.5), Vector2(17.0, 20.0)], 3: [Vector2(10.0, 13.5), Vector2(17.0, 20.0)],
	4: [Vector2(10.0, 13.5), Vector2(17.0, 20.0)], 5: [Vector2(10.5, 14.0)]}      # the day (0 Monday ... 6 Sunday) and from when to when; Sundays shut
const ALU := 0xf0f0ec           # white aluminium
const BLIND := 0xeeeeea         # the flats' white roller blinds
const LACE := 0xcfd4d2          # the lace behind their glass
const IRON_RED := 0x5a2a24      # the loggias' railings
const COLOURS := [0x1f1f22, 0x6a3a22, 0xc8a070, 0x8a1f2a, 0xf2f0ea, 0x2a3a5a, 0xb07a52, 0xd8c8a8, 0x3a2a20, 0xc8384a,
	0x9a6a3a, 0x4a4a50, 0xe8b8a8, 0x2f5a3a, 0xd8a040, 0x7a5a8a]
const KINDS := ["zapato", "tacon", "bota", "deportiva", "bailarina", "sandalia", "tacon", "zapato", "botin"]

var door: Vector2                               # before the shop's door, on the pavement of the Calle Argentina
var ar_spot: Vector2                            # before the Argentina's windows
var ac_spot: Vector2                            # before the Arcos's
var dentro                                      # its inside (pisacastana_dentro.gd)
var maniqui                                     # the mannequin at the door (maniqui.gd): street furniture, dressed anew each day
var is_open := false
var openings := 0
var balconies := 0
var pairs := 0                                  # (how many pairs of shoes its windows show: the self-test)
var _shut: Node3D
var _open: Node3D
var _lights: Array = []
var _na: Vector2                                # the outward normals of the Argentina and the Arcos
var _nw: Vector2
var _up: Array = []                             # the outline of the floors above (they stand out over the streets)
var _n := 0

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"blanco":           # the shop's white render (it reads white in the shade of the floors above too)
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.99, 0.97)), 0.34)
		"beige":            # the flats' room on the Argentina
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.9, 0.84, 0.72)), 0.1)
		"mancha":           # the grey patch of cement at its foot, the damp (dirty stays dirty)
			m = Tex.mat("granular_concrete", Color(0.62, 0.6, 0.56))
		"azulejo":          # the turquoise tiles at the shop's foot (Street View 2024: about 0, 128, 128 in the shade)
			var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
			for y in range(32):
				for x in range(32):
					var c := Color(0.06, 0.6, 0.58).lightened(0.035 * float((x / 16 + y / 16) % 2))
					if x % 16 == 0 or y % 16 == 0:
						c = Color(0.82, 0.88, 0.86)
					img.set_pixel(x, y, c)
			var am := StandardMaterial3D.new()
			am.albedo_texture = ImageTexture.create_from_image(img)
			am.uv1_triplanar = true
			am.uv1_world_triplanar = true
			am.uv1_scale = Vector3(2.5, 2.5, 2.5)          # (tiles of 20 cm)
			am.roughness = 0.25
			am.metallic_specular = 0.6
			am.emission_enabled = true
			am.emission_texture = am.albedo_texture
			am.emission = Color.WHITE
			am.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			am.emission_energy_multiplier = 0.12
			m = am
		"granito_negro":    # the black granite of the flats' doorway and the appliance shop
			m = Tex.mat("granite_tile_03@0.8", Color(0.3, 0.3, 0.32))
		"ladrillo":         # the brick of the floors above: a soft salmon in the sun (Street View 2024: about 216, 168, 146), not the strong
			# orange of brick_wall_003 (its tile has twice the courses: 2.5 m of it)
			m = _glow(Tex.mat("brick_wall_09@2.5", Color(1.0, 0.86, 0.9)), 0.36)
		"sardinel":         # the soldier courses, the sills: the same brick on its end, a little darker
			m = _glow(Tex.mat("brick_wall_09@1.25", Color(0.88, 0.8, 0.8)), 0.08)
		"losa":             # the underside of the floors above, the loggias' ceilings and slabs, the eaves
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.93, 0.9, 0.85)), 0.22)
		"naranja":          # the side of the first loggia's shut-in part (Street View 2024)
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.96, 0.58, 0.22)), 0.12)
		"medianera":        # what looks on to its neighbours and the plots behind
			m = Tex.mat("painted_plaster_wall", Color(0.8, 0.7, 0.62))
		"tiles_pisa":       # its tiles (its UVs in units of 1.6 m, down the slope)
			var tm: StandardMaterial3D = Tex.mat(Tex.pick("tiles") if Tex.pick("tiles") != "" else "clay_roof_tiles_02", Color(0.82, 0.66, 0.58), true, 1.6)
			tm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = tm
		"lona", "lona_verde":   # the awnings' canvas: cream; green (the top loggia's)
			var lm := StandardMaterial3D.new()
			lm.albedo_color = Color(0.93, 0.9, 0.82) if key == "lona" else Color(0.2, 0.52, 0.32)
			lm.roughness = 1.0
			lm.emission_enabled = true
			lm.emission = lm.albedo_color
			lm.emission_energy_multiplier = 0.2
			lm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = lm
		"rotulo", "friso", "cristal", "estrecho", "horario", "placa", "electro", "vende":
			var pm := StandardMaterial3D.new()
			pm.albedo_texture = load(DIR + String(key) + ".png")
			pm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			pm.roughness = 1.0
			pm.metallic_specular = 0.0          # (a shine picks up the sky and greys it)
			pm.emission_enabled = true          # (in the shade of the floors above)
			pm.emission_texture = pm.albedo_texture
			pm.emission = Color.WHITE
			pm.emission_energy_multiplier = 0.14
			m = pm
		"vidrio":
			var gm := StandardMaterial3D.new()
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.albedo_color = Color(0.55, 0.68, 0.72, 0.26)
			gm.roughness = 0.12
			gm.metallic_specular = 0.7
			gm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = gm
		"humo":             # the door's little canopy: smoked glass
			var hm := StandardMaterial3D.new()
			hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			hm.albedo_color = Color(0.5, 0.44, 0.38, 0.55)
			hm.roughness = 0.2
			hm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = hm
		"interior":         # the walls of what shows through the glass: the shop behind the windows; dim when shut, lit when open
			var im := StandardMaterial3D.new()
			im.albedo_color = Color(0.42, 0.4, 0.39)
			im.roughness = 1.0
			im.emission_enabled = true
			im.emission = Color(1.0, 0.97, 0.92)
			im.emission_energy_multiplier = 0.05
			m = im
		"luz":
			var um := StandardMaterial3D.new()
			um.albedo_color = Color(1.0, 0.99, 0.95)
			um.emission_enabled = true
			um.emission = Color(1.0, 0.98, 0.92)
			um.emission_energy_multiplier = 1.6
			m = um
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world, _hd: Dictionary) -> void:
	W = world
	_na = _outward(K, E)
	_nw = _outward(N, K)
	level = MapData.height(K + (_na + _nw).normalized() * 1.0)
	transform = Transform3D(Basis.IDENTITY, Vector3(0.0, level, 0.0))
	W.add_child(self)
	var ring := _ring()
	var by := [0.0, 0.0, -OUT, -OUT, 0.0]                           # (the floors above stand out over the two streets)
	_up = _inset(ring, by)
	wall_top = TOP
	eave_out = EAVE
	roof_pitch = PITCH
	roof_rise0 = RISE0
	var E2: Vector2 = _up[2]
	var K2: Vector2 = _up[3]
	var N2: Vector2 = _up[4]
	var nb1 := _outward(P0, N)                                       # (the slopes to the plots behind and to the neighbour east)
	var nb2 := _outward(P1, P0)
	var ne := _outward(E, P1)
	_planes = [[_na, K2.dot(_na)], [_nw, K2.dot(_nw)], [nb1, N.dot(nb1)], [nb2, P0.dot(nb2)], [ne, E.dot(ne)]]
	var rby := [0.0, 0.0, -EAVE, -EAVE, 0.0]
	var rr := _inset(_up, rby)                                     # (the roof's outline: where the eaves end)
	_argentina()
	_arcos()
	_flats_argentina(K2, E2, -_x_on(rr[3], K2, E2), _x_on(rr[2], K2, E2) - K2.distance_to(E2))
	_flats_arcos(N2, K2, -_x_on(rr[4], N2, K2), _x_on(rr[3], N2, K2) - N2.distance_to(K2))
	home()
	_flat_down(PackedVector2Array([E, K, N, N2, K2, E2]), SOFFIT, "losa")      # the underside of the floors above
	_return(E2, E)
	_return(N, N2)
	_party_wall(P0, P1)
	_party_wall(P1, E)
	_party_wall(N, P0)
	_roof_over(_up, rby, "tiles_pisa")
	home()
	_commit()
	_states()
	_ring_solids(ring, 12.0)
	door = _along(K, E, DOOR.get_center().x) + _na * 0.9
	ar_spot = _along(K, E, 4.5) + _na * 1.3
	ac_spot = _along(N, K, 11.2) + _nw * 1.3
	dentro = DentroS.new()                          # (its door on the Argentina: the arrow stands before it)
	var at := _along(K, E, DOOR.get_center().x)
	dentro.build(world, at + _na * 0.5, at + _na * 1.6, atan2(_na.x, _na.y))
	var mp := _along(K, E, MANIQUI.x) + _na * MANIQUI.y
	maniqui = ManiquiS.new()
	maniqui.setup(world, mp, atan2(_na.x, _na.y) - 0.45, MapData.foot(mp) - level, false, false, true)
	add_child(maniqui)
	set_open(open_at(0, 12.0))

func _ring() -> Array:
	return [P0, P1, E, K, N]

## whether it is open then (day: 0 Monday ... 6 Sunday)
func open_at(day: int, hour: float) -> bool:
	var d := posmod(day, 7)
	if not HOURS.has(d):
		return false
	for h: Vector2 in HOURS[d]:
		if hour >= h.x and hour < h.y:
			return true
	return false

# ---------------- pieces ----------------
## how far along the line a -> b a spot is
func _x_on(p: Vector2, a: Vector2, b: Vector2) -> float:
	return (p - a).dot((b - a).normalized())

## how high the ground is before a spot of a front (this frame's y)
func _g(a: Vector2, b: Vector2, x: float) -> float:
	var p := _along(a, b, x) + _outward(a, b) * 0.6
	return ground(p.x, p.y)

## the next colour of the goods (always the same sequence)
func _colour(shift := 0) -> int:
	_n += 1
	return COLOURS[(_n * 5 + shift * 3 + (_n / 7)) % COLOURS.size()]

## The projection's side over a neighbour's wall, from the floors' underside up to the roof's line, on the line a -> b.
func _return(a: Vector2, b: Vector2) -> void:
	var ln := face(a, b)
	pieces += 1
	quad(Vector3(0, SOFFIT, 0), Vector3(ln, SOFFIT, 0), Vector3(ln, wall_top, 0), Vector3(0, wall_top, 0), "ladrillo", Vector3(0, 0, 1))
	quad(Vector3(0, wall_top, 0), Vector3(ln, wall_top, 0), Vector3(ln, _roof_y(b) - 0.03, 0), Vector3(0, _roof_y(a) - 0.03, 0), "medianera", Vector3(0, 0, 1))
	home()

## the cables along the front being built at height y, from x0 to x1, in their clips
func _cables(y: float, x0: float, x1: float) -> void:
	var n := maxi(2, int(round((x1 - x0) / 1.1)))
	for k in range(n):
		var xa := lerpf(x0, x1, float(k) / n)
		var xb := lerpf(x0, x1, float(k + 1) / n)
		var ya := y - 0.025 * (k % 2)
		var yb := y - 0.025 * ((k + 1) % 2)
		bar(Vector3(xa, ya, 0.035), Vector3(xb, yb, 0.035), 0.035, 0.035, 0x2c2c2e)
		bar(Vector3(xa, ya - 0.06, 0.03), Vector3(xb, yb - 0.06, 0.03), 0.026, 0.026, 0x1e1e20)
		box(xa - 0.01, ya - 0.09, 0.0, 0.02, 0.13, 0.05, 0x8a8a86)

## an air conditioner's outdoor box on the wall, its foot at (x, y): white, its fan's grille, its brackets
func _ac(x: float, y: float, w := 0.78) -> void:
	box(x, y, 0.0, w, 0.54, 0.27, 0xe9e9e5)
	box(x + w * 0.1, y + 0.08, 0.27, w * 0.52, 0.38, 0.01, 0x9a9c9e)
	for i in range(6):
		box(x + w * 0.12, y + 0.1 + i * 0.06, 0.275, w * 0.48, 0.012, 0.01, 0x6a6c70)
	for q in [x + 0.03, x + w - 0.06]:
		bar(Vector3(q, y - 0.02, 0.0), Vector3(q, y - 0.02, 0.25), 0.03, 0.03, 0x8a8a86)
	bar(Vector3(x + w - 0.1, y + 0.2, 0.05), Vector3(x + w - 0.1, y - 0.6, 0.05), 0.02, 0.02, 0xe0e0dc)       # (its pipe down the wall)

## a meter box on the wall, its foot at (x, y)
func _meter(x: float, y: float) -> void:
	box(x, y, 0.0, 0.42, 0.42, 0.06, 0xf0f0ec)
	box(x + 0.25, y + 0.22, 0.06, 0.11, 0.12, 0.004, 0x5a6a70)
	box(x + 0.04, y + 0.36, 0.06, 0.34, 0.012, 0.004, 0xc8c8c4)

## An awning over a window, its box on the wall at y: cream canvas sloping out `out` and down `drop`, its valance, its
## arms and its front bar.
func _awning(x0: float, x1: float, y: float, out := 1.35, drop := 0.62, key = "lona") -> void:
	box(x0, y, 0.0, x1 - x0, 0.14, 0.16, 0xe6e4de)
	pieces += 1
	quad(Vector3(x0, y + 0.03, 0.12), Vector3(x1, y + 0.03, 0.12), Vector3(x1, y - drop, out), Vector3(x0, y - drop, out), key, Vector3(0, out, drop).normalized())
	quad(Vector3(x0, y - drop, out), Vector3(x1, y - drop, out), Vector3(x1, y - drop - 0.22, out), Vector3(x0, y - drop - 0.22, out), key, Vector3(0, 0, 1))
	bar(Vector3(x0, y - drop, out), Vector3(x1, y - drop, out), 0.04, 0.04, 0xdedcd6)
	for x in [x0 + 0.12, x1 - 0.12]:
		bar(Vector3(x, y - 0.55, 0.02), Vector3(x, y - drop - 0.02, out - 0.03), 0.025, 0.025, 0xc8c8c4)
		box(x - 0.04, y - 0.6, 0.0, 0.08, 0.1, 0.04, 0xc8c8c4)

## A frosted glass in its hole (the picture is the glass): its frame, its sill.
func _frosted(r: Rect2, key: String, frame: int) -> void:
	openings += 1
	var z := -DEEP + 0.08
	_picture(r.position.x, r.end.x, r.position.y, r.end.y, z, key)
	var a := r.position
	var b := r.end
	for q in [[a.x, a.y, 0.05, r.size.y], [b.x - 0.05, a.y, 0.05, r.size.y], [a.x, a.y, r.size.x, 0.05], [a.x, b.y - 0.05, r.size.x, 0.05]]:
		box(q[0], q[1], z - 0.02, q[2], q[3], 0.05, frame)
	box(a.x - 0.03, a.y - 0.038, -0.04, r.size.x + 0.06, 0.05, 0.1, ALU)

## A shop window in its hole: white aluminium round the glass, a white sill, and behind the glass a little lit room of
## shoes (`kind`: "estantes" white shelves on a white back, a row of pairs on each; "cubos" white cube shelves, a pair or
## a shoe box in each; "escalera" white steps of pairs and boots, a tall shelf at one end).
func _vitrina(r: Rect2, kind: String) -> void:
	openings += 1
	var z := -DEEP + 0.08
	var a := r.position
	var b := r.end
	pieces += 1
	quad(Vector3(a.x, a.y, z), Vector3(b.x, a.y, z), Vector3(b.x, b.y, z), Vector3(a.x, b.y, z), "vidrio", Vector3(0, 0, 1))
	for q in [[a.x, a.y, 0.06, r.size.y], [b.x - 0.06, a.y, 0.06, r.size.y], [a.x, a.y, r.size.x, 0.07], [a.x, b.y - 0.06, r.size.x, 0.06]]:
		box(q[0], q[1], z - 0.03, q[2], q[3], 0.05, ALU)
	box(a.x - 0.03, a.y - 0.038, -0.04, r.size.x + 0.06, 0.05, 0.1, ALU)
	var zb := -1.2
	var zf := z - 0.04
	pieces += 1
	quad(Vector3(a.x, a.y, zb), Vector3(b.x, a.y, zb), Vector3(b.x, b.y, zb), Vector3(a.x, b.y, zb), "interior", Vector3(0, 0, 1))
	quad(Vector3(a.x, a.y, zb), Vector3(a.x, a.y, zf), Vector3(a.x, b.y, zf), Vector3(a.x, b.y, zb), "interior", Vector3(1, 0, 0))
	quad(Vector3(b.x, a.y, zb), Vector3(b.x, a.y, zf), Vector3(b.x, b.y, zf), Vector3(b.x, b.y, zb), "interior", Vector3(-1, 0, 0))
	quad(Vector3(a.x, a.y + 0.012, zb), Vector3(b.x, a.y + 0.012, zb), Vector3(b.x, a.y + 0.012, zf), Vector3(a.x, a.y + 0.012, zf), 0xe2ded8, Vector3.UP)
	quad(Vector3(a.x, b.y - 0.012, zb), Vector3(b.x, b.y - 0.012, zb), Vector3(b.x, b.y - 0.012, zf), Vector3(a.x, b.y - 0.012, zf), "interior", Vector3.DOWN)
	box(a.x + 0.1, b.y - 0.04, zb + 0.45, r.size.x - 0.2, 0.03, 0.1, "luz")          # (its strip light)
	match kind:
		"estantes":                                                 # (Street View 2024, the Argentina's first: five white shelves)
			box(a.x + 0.05, a.y, zb + 0.01, r.size.x - 0.1, r.size.y - 0.06, 0.02, 0xf2f2ee)
			for j in range(5):
				var y := a.y + 0.12 + j * 0.37
				box(a.x + 0.1, y - 0.02, zb + 0.03, r.size.x - 0.2, 0.02, 0.32, 0xf6f6f2)
				var n := int((r.size.x - 0.3) / 0.34)
				for i in range(n):
					var x := a.x + 0.27 + i * (r.size.x - 0.54) / maxf(1.0, n - 1.0)
					_pair(x, y, zb + 0.19, _colour(), KINDS[(i + j * 2) % KINDS.size()])
		"cubos":                                                    # (the second: white cubes, three high, on a white back)
			box(a.x + 0.05, a.y, zb + 0.01, r.size.x - 0.1, r.size.y - 0.06, 0.02, 0xf2f2ee)
			var rows := 3
			var ch := 0.5
			var cols := int((r.size.x - 0.4) / 0.46)
			var cw := (r.size.x - 0.4) / cols
			var x0 := a.x + 0.2
			for i in range(cols + 1):
				box(x0 + i * cw - 0.015, a.y, zb + 0.35, 0.03, rows * ch, 0.36, 0xf4f4f0)
			for j in range(rows + 1):
				box(x0, a.y + j * ch - (0.03 if j > 0 else 0.0), zb + 0.35, cols * cw, 0.03, 0.36, 0xf4f4f0)
			for i in range(cols):
				for j in range(rows):
					var cx := x0 + (i + 0.5) * cw
					var y := a.y + j * ch + 0.03
					if (i * 2 + j) % 5 == 3:                        # (a shoe box, its lid off, the pair in it)
						box(cx - 0.16, y, zb + 0.42, 0.32, 0.1, 0.2, [0xf2f0ea, 0x8a5a3a, 0x2a2a2e][(i + j) % 3])
						_pair(cx, y + 0.1, zb + 0.6, _colour(), KINDS[(i + j) % KINDS.size()])
					else:
						_pair(cx, y, zb + 0.53, _colour(), KINDS[(i * 3 + j * 2) % KINDS.size()])
		"escalera":                                                 # (the Arcos's: Street View 2021 shows it full of shoes, on a white back)
			box(a.x + 0.05, a.y, zb + 0.01, r.size.x - 0.1, r.size.y - 0.06, 0.02, 0xf2f2ee)
			for k in range(3):                                      # three white steps, the lowest by the glass
				var y := a.y + k * 0.32
				var zz := zf - 0.36 * (k + 1)
				box(a.x + 0.08, a.y, zz, r.size.x - 0.9, 0.12 + k * 0.32, 0.36, 0xf4f4f0)
				var n := int((r.size.x - 1.1) / 0.36)
				for i in range(n):
					_pair(a.x + 0.3 + i * (r.size.x - 1.4) / maxf(1.0, n - 1.0), y + 0.12, zz + 0.18, _colour(), KINDS[(i + k * 4) % KINDS.size()])
			var sx := b.x - 0.72                                    # the tall shelf at its end: four glass shelves on chrome
			for y in [a.y + 0.1, a.y + 0.55, a.y + 1.0, a.y + 1.45]:
				box(sx, y, zb + 0.05, 0.6, 0.015, 0.36, 0xc8dce0)
				_pair(sx + 0.3, y + 0.015, zb + 0.23, _colour(), KINDS[int(y * 10.0) % KINDS.size()])
			for x in [sx + 0.02, sx + 0.56]:
				bar(Vector3(x, a.y, zb + 0.1), Vector3(x, a.y + 1.6, zb + 0.1), 0.02, 0.02, 0xc0c4c8)

## a pair of shoes at x (their middle), standing at y, their middle at z, their toes to +z (the street)
func _pair(x: float, y: float, z: float, col: int, kind: String) -> void:
	pairs += 1
	for s in [-0.055, 0.055]:
		_shoe(x + s, y, z, col, kind)

## One shoe, its toe to +z: "zapato" a laced shoe, "tacon" a court shoe with its heel, "bota" a tall boot, "botin" an
## ankle boot, "deportiva" a trainer on its white sole, "bailarina" a flat, "sandalia" a sandal's sole and straps.
func _shoe(x: float, y: float, z: float, col: int, kind: String) -> void:
	var sole := 0x2a2622 if col != 0x1f1f22 else 0x6a4a32
	match kind:
		"tacon":
			box(x - 0.035, y + 0.075, z - 0.12, 0.07, 0.014, 0.09, col)            # the heel's seat...
			bar(Vector3(x, y + 0.078, z - 0.035), Vector3(x, y + 0.012, z + 0.035), 0.07, 0.012, col)     # ...the arch...
			box(x - 0.035, y, z + 0.03, 0.07, 0.014, 0.09, col)                   # ...the sole at the toe
			box(x - 0.033, y + 0.012, z + 0.04, 0.066, 0.034, 0.08, col)           # (its vamp)
			box(x - 0.011, y, z - 0.118, 0.022, 0.078, 0.022, sole)                # (its heel)
		"bota":
			box(x - 0.04, y, z - 0.12, 0.08, 0.018, 0.24, sole)
			box(x - 0.038, y + 0.018, z - 0.12, 0.076, 0.07, 0.22, col)
			box(x - 0.038, y + 0.088, z - 0.12, 0.076, 0.26, 0.1, col)
		"botin":
			box(x - 0.04, y, z - 0.12, 0.08, 0.02, 0.24, sole)
			box(x - 0.038, y + 0.02, z - 0.12, 0.076, 0.07, 0.22, col)
			box(x - 0.038, y + 0.09, z - 0.12, 0.076, 0.07, 0.1, col)
		"deportiva":
			box(x - 0.042, y, z - 0.12, 0.084, 0.035, 0.245, 0xf4f4f0)
			box(x - 0.04, y + 0.035, z - 0.11, 0.08, 0.05, 0.2, col)
			box(x + 0.039, y + 0.045, z - 0.07, 0.004, 0.022, 0.1, 0xf4f4f0 if col != 0xf2f0ea else 0xc8384a)
		"bailarina":
			box(x - 0.038, y, z - 0.12, 0.076, 0.012, 0.24, sole)
			box(x - 0.036, y + 0.012, z - 0.12, 0.072, 0.035, 0.07, col)
			box(x - 0.036, y + 0.012, z + 0.02, 0.072, 0.03, 0.1, col)
		"sandalia":
			box(x - 0.038, y, z - 0.12, 0.076, 0.025, 0.24, 0xc8a878)
			box(x - 0.04, y + 0.025, z + 0.04, 0.08, 0.012, 0.03, col)
			box(x - 0.04, y + 0.025, z - 0.05, 0.08, 0.012, 0.025, col)
			box(x - 0.04, y + 0.025, z - 0.12, 0.08, 0.05, 0.012, col)
		_:
			box(x - 0.04, y, z - 0.12, 0.08, 0.018, 0.24, sole)
			box(x - 0.038, y + 0.018, z - 0.12, 0.076, 0.06, 0.19, col)
			box(x - 0.034, y + 0.018, z + 0.07, 0.068, 0.04, 0.05, col)

# ---------------- the Calle Argentina (south) ----------------
func _argentina() -> void:
	var ln := face(K, E)
	masonry(0.0, ln, -0.9, SOFFIT, [AR_NARROW, AR_WIN[0], AR_WIN[1], AR_FROST, DOOR, GRILLE], [Rect2(BEIGE, -0.9, ln - BEIGE, SOFFIT + 0.9)], "blanco", "beige")
	box(0.0, -0.3, 0.0, DOOR.position.x, 0.3 + BASE_T, 0.025, "azulejo")              # the turquoise tiles at its foot...
	box(DOOR.end.x, -0.3, 0.0, BEIGE - DOOR.end.x, 0.3 + BASE_T, 0.025, "azulejo")
	box(BEIGE, -0.3, 0.0, ln - BEIGE, 0.72, 0.018, "mancha")                          # ...the grey patch at the flats' (dirty stays dirty)
	box(BEIGE + 0.6, 0.42, 0.0, 1.1, 0.14, 0.016, "mancha")
	_frosted(AR_NARROW, "estrecho", 0x6a4a32)
	_vitrina(AR_WIN[0], "estantes")
	_vitrina(AR_WIN[1], "cubos")
	_frosted(AR_FROST, "cristal", ALU)
	pieces += 1                                                                       # the card of its hours on the frosted glass
	var zc := -DEEP + 0.085
	quad(Vector3(9.62, 0.95, zc), Vector3(9.92, 0.95, zc), Vector3(9.92, 1.35, zc), Vector3(9.62, 1.35, zc), "horario", Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	box(9.82, 2.3, zc - 0.002, 0.09, 0.09, 0.004, 0x2a4ab0)                           # (the alarm's blue sticker)
	_doorway()
	_grille_window(GRILLE)
	_meter(12.0, 1.1)
	_ac(11.82, 2.62, 0.72)                                                            # the flats' two air conditioners
	_ac(14.3, 2.9, 0.82)
	box(SIGN.position.x - 0.03, SIGN.position.y - 0.03, 0.0, SIGN.size.x + 0.06, SIGN.size.y + 0.06, 0.04, 0x343438)
	_picture(SIGN.position.x, SIGN.end.x, SIGN.position.y, SIGN.end.y, 0.052, "rotulo")
	for r: Rect2 in AR_WIN:
		_awning(r.position.x - 0.06, r.end.x + 0.06, AWNING)
	_canopy(AR_FROST.position.x - 0.12, DOOR.end.x + 0.12, 2.74)
	home()

## The shop's doorway, set back: white sides and ceiling, a floor of white tiles, the glass door at its back in white
## aluminium, and the shop beyond it (lit when open).
func _doorway() -> void:
	openings += 1
	var a := DOOR.position
	var b := DOOR.end
	var zr := -RECESS
	pieces += 1
	quad(Vector3(a.x, 0, zr), Vector3(a.x, 0, -DEEP), Vector3(a.x, b.y, -DEEP), Vector3(a.x, b.y, zr), "blanco", Vector3(1, 0, 0))
	quad(Vector3(b.x, 0, zr), Vector3(b.x, 0, -DEEP), Vector3(b.x, b.y, -DEEP), Vector3(b.x, b.y, zr), "blanco", Vector3(-1, 0, 0))
	quad(Vector3(a.x, b.y, zr), Vector3(b.x, b.y, zr), Vector3(b.x, b.y, -DEEP), Vector3(a.x, b.y, -DEEP), "blanco", Vector3.DOWN)
	box(a.x + 0.005, -0.3, zr, DOOR.size.x - 0.01, 0.315, RECESS, 0xeeeeea)                           # its floor of white tiles
	for k in range(1, 4):
		box(a.x + 0.005, 0.0151, zr + k * RECESS / 4.0, DOOR.size.x - 0.01, 0.001, 0.008, 0xc8c8c4)
	var z := zr + 0.04
	for x in [a.x, b.x - 0.06]:                                                      # the glass door: white aluminium
		box(x, 0.0, z - 0.03, 0.06, b.y - 0.05, 0.06, ALU)
	for y in [0.0, 1.0, b.y - 0.11]:
		box(a.x, y, z - 0.03, DOOR.size.x, 0.11 if y < 0.1 else 0.06, 0.06, ALU)
	pieces += 1
	quad(Vector3(a.x, 0.11, z), Vector3(b.x, 0.11, z), Vector3(b.x, b.y - 0.11, z), Vector3(a.x, b.y - 0.11, z), "vidrio", Vector3(0, 0, 1))
	box(b.x - 0.2, 0.85, z + 0.03, 0.03, 0.45, 0.04, 0xb8bcc0)                         # (its handle)
	var zb := zr - 2.2                                                                # the shop behind it
	pieces += 1
	quad(Vector3(a.x, 0.0, zb), Vector3(b.x, 0.0, zb), Vector3(b.x, b.y, zb), Vector3(a.x, b.y, zb), "interior", Vector3(0, 0, 1))
	quad(Vector3(a.x, 0.0, zb), Vector3(a.x, 0.0, z), Vector3(a.x, b.y, z), Vector3(a.x, b.y, zb), "interior", Vector3(1, 0, 0))
	quad(Vector3(b.x, 0.0, zb), Vector3(b.x, 0.0, z), Vector3(b.x, b.y, z), Vector3(b.x, b.y, zb), "interior", Vector3(-1, 0, 0))
	quad(Vector3(a.x, 0.0, zb), Vector3(b.x, 0.0, zb), Vector3(b.x, 0.0, z), Vector3(a.x, 0.0, z), 0xd8d4ce, Vector3.UP)
	quad(Vector3(a.x, b.y, zb), Vector3(b.x, b.y, zb), Vector3(b.x, b.y, z), Vector3(a.x, b.y, z), "interior", Vector3.DOWN)
	box(a.x + 0.1, 0.0, zb + 0.05, 0.9, 2.0, 0.32, 0xf4f4f0)                          # (a white shelf of shoes at the back)
	for y in [0.3, 0.7, 1.1, 1.5]:
		box(a.x + 0.12, y, zb + 0.06, 0.86, 0.015, 0.3, 0xe8e8e4)
		_pair(a.x + 0.55, y + 0.015, zb + 0.22, _colour(), KINDS[int(y * 10.0) % KINDS.size()])
	for x in [a.x - 0.03, b.x - 0.01]:                                               # the shutter's runners, at the front
		box(x, 0.0, -0.1, 0.04, b.y, 0.06, 0xdedcd6)

## The flats' window on the Argentina: its wooden frame, its wooden roller blind down, its sill of red tiles, the white
## iron grille before it (its bars bowed out a little at the middle).
func _grille_window(r: Rect2) -> void:
	openings += 1
	var z := -DEEP + 0.06
	box(r.position.x, r.position.y, z - 0.04, r.size.x, r.size.y, 0.03, 0x6a4a30)
	box(r.position.x + 0.06, r.position.y + 0.06, z, r.size.x - 0.12, r.size.y - 0.12, 0.02, 0xc9a77a)
	for i in range(1, int((r.size.y - 0.12) / 0.06)):
		box(r.position.x + 0.06, r.position.y + 0.06 + i * 0.06, z + 0.02, r.size.x - 0.12, 0.008, 0.004, 0xa88a60)
	box(r.position.x - 0.05, r.position.y - 0.028, -DEEP, r.size.x + 0.1, 0.04, DEEP + 0.07, 0xa8583a)
	var zg := 0.07
	var n := 9
	for k in range(n + 1):
		var x := r.position.x + 0.04 + k * (r.size.x - 0.08) / n
		var p0 := Vector3(x, r.position.y - 0.06, zg)
		var p1 := Vector3(x, r.get_center().y, zg + 0.07)
		var p2 := Vector3(x, r.end.y + 0.06, zg)
		bar(p0, p1, 0.018, 0.018, 0xe6e6e2)
		bar(p1, p2, 0.018, 0.018, 0xe6e6e2)
	for t in [0.04, 0.3, 0.5, 0.7, 0.96]:
		var y := lerpf(r.position.y - 0.04, r.end.y + 0.04, t)
		var bulge := 0.07 * (1.0 - absf(t - 0.5) * 2.0)
		bar(Vector3(r.position.x - 0.02, y, zg + bulge), Vector3(r.end.x + 0.02, y, zg + bulge), 0.02, 0.02, 0xe6e6e2)
	for q in [[r.position.x - 0.06, r.position.y], [r.end.x + 0.02, r.position.y], [r.position.x - 0.06, r.end.y], [r.end.x + 0.02, r.end.y]]:
		box(q[0], q[1] - 0.02, 0.0, 0.04, 0.04, zg + 0.02, 0xe6e6e2)

## The little canopy over the frosted window and the door: a sheet of smoked glass on white brackets, ivy along its
## edge hanging down (Street View 2024).
func _canopy(x0: float, x1: float, y: float) -> void:
	box(x0, y, 0.0, x1 - x0, 0.02, 0.38, "humo")
	for x in [x0 + 0.03, x1 - 0.03, (x0 + x1) / 2.0]:
		bar(Vector3(x, y - 0.24, 0.01), Vector3(x, y, 0.36), 0.025, 0.025, 0xe6e6e2)
		bar(Vector3(x, y, 0.01), Vector3(x, y, 0.36), 0.025, 0.025, 0xe6e6e2)
	bar(Vector3(x0, y + 0.01, 0.37), Vector3(x1, y + 0.01, 0.37), 0.025, 0.03, 0xe6e6e2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var x := x0 + 0.05
	while x < x0 + 2.1:                                                               # (the ivy: thick over the frosted window, thinner on)
		var hang := rng.randf_range(0.05, 0.55)
		var k := 0
		while k * 0.07 < hang:
			var c: int = [0x2f5a2a, 0x3f6e34, 0x4a7a3a][(k + int(x * 10.0)) % 3]
			box(x + rng.randf_range(-0.03, 0.03), y - 0.05 - k * 0.07, 0.3 + rng.randf_range(-0.04, 0.06), 0.07, 0.06, 0.03, c)
			k += 1
		x += rng.randf_range(0.05, 0.1)

# ---------------- the Calle de los Arcos (west) ----------------
func _arcos() -> void:
	var ln := face(N, K)
	var gp := _g(N, K, PORTAL.get_center().x)
	var ge := _g(N, K, EL_DOOR.get_center().x)
	var portal := Rect2(PORTAL.position.x, gp, PORTAL.size.x, PORTAL.size.y)
	var el_door := Rect2(EL_DOOR.position.x, ge, EL_DOOR.size.x, EL_DOOR.size.y)
	var el_win: Array = []
	for r: Rect2 in EL_WIN:
		el_win.append(Rect2(r.position.x, _g(N, K, r.get_center().x) + r.position.y, r.size.x, r.size.y))
	masonry(0.0, ln, -0.9, SOFFIT, [el_door, el_win[0], el_win[1], portal, AC_WIN], [Rect2(0.0, -0.9, STONE_END, SOFFIT + 0.9)], "blanco", "granito_negro")
	box(STONE_END, -0.3, 0.0, ln - STONE_END, 0.3 + BASE_T, 0.025, "azulejo")          # the turquoise tiles at the shop's foot
	_vitrina(AC_WIN, "escalera")
	_awning(AC_WIN.position.x - 0.06, AC_WIN.end.x + 0.06, AWNING)
	box(FRISO.position.x - 0.03, FRISO.position.y - 0.03, 0.0, FRISO.size.x + 0.06, FRISO.size.y + 0.06, 0.03, 0x343438)
	_picture(FRISO.position.x, FRISO.end.x, FRISO.position.y, FRISO.end.y, 0.042, "friso")
	_meter(9.3, 1.2)
	_ac(9.15, 2.95, 0.66)                                                             # (the shop's, over its awning by the doorway)
	_portal(portal)
	_appliances(el_door, el_win)
	home()

## The flats' doorway: black granite round it and in it, three steps up, the carved wooden double door at its back, the
## intercom on the granite.
func _portal(r: Rect2) -> void:
	openings += 1
	var y0 := r.position.y
	var zr := -1.0
	pieces += 1
	quad(Vector3(r.position.x, y0, zr), Vector3(r.position.x, y0, -DEEP), Vector3(r.position.x, r.end.y, -DEEP), Vector3(r.position.x, r.end.y, zr), "granito_negro", Vector3(1, 0, 0))
	quad(Vector3(r.end.x, y0, zr), Vector3(r.end.x, y0, -DEEP), Vector3(r.end.x, r.end.y, -DEEP), Vector3(r.end.x, r.end.y, zr), "granito_negro", Vector3(-1, 0, 0))
	quad(Vector3(r.position.x, r.end.y, zr), Vector3(r.end.x, r.end.y, zr), Vector3(r.end.x, r.end.y, -DEEP), Vector3(r.position.x, r.end.y, -DEEP), "granito_negro", Vector3.DOWN)
	var fronts := [0.2, -0.1, -0.4]                                                  # its steps, the lowest out on the pavement, the top one the landing
	for k in range(3):
		var wide := 0.12 if k == 0 else 0.0
		box(r.position.x - wide, y0 - 0.3, zr, r.size.x + wide * 2.0, 0.3 + 0.16 * (k + 1), float(fronts[k]) - zr, 0xd8d8d4)
		box(r.position.x - wide, y0 + 0.16 * (k + 1) - 0.02, float(fronts[k]) - 0.03, r.size.x + wide * 2.0, 0.025, 0.035, 0xb8b8b4)
	var yd := y0 + 0.48
	var zd := zr + 0.03
	box(r.position.x + 0.1, yd, zr, r.size.x - 0.2, r.end.y - yd - 0.25, 0.03, 0x7a4c2a)       # the door's frame...
	for s in [0, 1]:                                                                 # ...its two leaves of carved panels
		var lx: float = r.position.x + 0.16 + s * (r.size.x - 0.32) / 2.0
		var lw := (r.size.x - 0.32) / 2.0 - 0.02
		box(lx, yd + 0.05, zd, lw, r.end.y - yd - 0.36, 0.03, 0x8a5a32)
		for i in range(2):
			for j in range(6):
				box(lx + 0.05 + i * (lw - 0.1) / 2.0, yd + 0.12 + j * 0.31, zd + 0.03, (lw - 0.1) / 2.0 - 0.04, 0.25, 0.015, 0x6a4224)
	box(r.get_center().x - 0.08, yd + 1.05, zd + 0.045, 0.04, 0.1, 0.02, 0xc8b070)
	box(r.get_center().x + 0.04, yd + 1.05, zd + 0.045, 0.04, 0.1, 0.02, 0xc8b070)
	box(r.end.x + 0.06, y0 + 1.25, 0.0, 0.12, 0.2, 0.025, 0xb8bcc0)                  # the intercom
	for k in range(3):
		box(r.end.x + 0.08, y0 + 1.29 + k * 0.05, 0.025, 0.08, 0.025, 0.006, 0x3a3a3e)

## The appliance shop next door, shut and for sale: its black granite front (the masonry's), a board with no brand, a
## cream awning with a green valance, its door behind a folding grille, its windows with a mesh grille behind the glass,
## dark inside, a "se vende" card in the first.
func _appliances(door_r: Rect2, wins: Array) -> void:
	box(0.36, 2.92, 0.0, EL_END - 0.72, 0.56, 0.05, 0x2a2c2a)
	_picture(0.4, EL_END - 0.4, 2.95, 3.45, 0.062, "electro")
	box(0.15, AWNING - 0.12, 0.0, EL_END - 0.3, 0.12, 0.14, 0xe6e4de)
	_awning(0.15, EL_END - 0.15, AWNING - 0.12, 1.1, 0.4)
	box(0.15, AWNING - 0.12 - 0.4 - 0.22, 1.1 + 0.005, EL_END - 0.3, 0.06, 0.004, 0x2e9646)       # (the green stripe along its valance)
	for r: Rect2 in [door_r, wins[0], wins[1]]:
		openings += 1
		var z := -DEEP + 0.08
		var a := r.position
		var b := r.end
		box(a.x, a.y, -0.9, r.size.x, r.size.y, 0.02, 0x1e2022)                         # (dark inside: nothing is left in it)
		pieces += 1
		quad(Vector3(a.x, a.y, z), Vector3(b.x, a.y, z), Vector3(b.x, b.y, z), Vector3(a.x, b.y, z), "vidrio", Vector3(0, 0, 1))
		for q in [[a.x, a.y, 0.05, r.size.y], [b.x - 0.05, a.y, 0.05, r.size.y], [a.x, b.y - 0.05, r.size.x, 0.05]]:
			box(q[0], q[1], z - 0.03, q[2], q[3], 0.05, 0x8a8c8e)
		if r == door_r:                                                             # the folding grille: a lattice of crossed bars
			var zg := -0.06
			var n := int(r.size.x / 0.16)
			for k in range(n + 1):
				var x := a.x + k * r.size.x / n
				box(x - 0.012, a.y, zg, 0.024, r.size.y, 0.02, 0x9a9ea2)
			for k in range(n):
				var xa := a.x + k * r.size.x / n
				var xb := a.x + (k + 1) * r.size.x / n
				for j in range(int(r.size.y / 0.5)):
					var ya := a.y + j * 0.5
					bar(Vector3(xa, ya, zg + 0.01), Vector3(xb, ya + 0.5, zg + 0.01), 0.012, 0.012, 0x9a9ea2)
					bar(Vector3(xb, ya, zg + 0.012), Vector3(xa, ya + 0.5, zg + 0.012), 0.012, 0.012, 0x9a9ea2)
			box(a.x, a.y + r.size.y - 0.06, zg - 0.01, r.size.x, 0.06, 0.04, 0x9a9ea2)
		else:                                                                       # the mesh grille behind the glass
			var zm := z - 0.12
			for k in range(int(r.size.x / 0.14) + 1):
				box(a.x + 0.03 + k * 0.14, a.y + 0.03, zm, 0.01, r.size.y - 0.06, 0.01, 0x5a5e62)
			for k in range(int(r.size.y / 0.14) + 1):
				box(a.x + 0.03, a.y + 0.03 + k * 0.14, zm, r.size.x - 0.06, 0.01, 0.01, 0x5a5e62)
			box(a.x - 0.03, a.y - 0.05, -0.04, r.size.x + 0.06, 0.05, 0.1, 0x2a2c2a)
	var w0: Rect2 = wins[0]                                                          # the "se vende" card, stuck on the glass
	pieces += 1
	var zc := -DEEP + 0.085
	quad(Vector3(w0.position.x + 0.55, w0.position.y + 0.95, zc), Vector3(w0.position.x + 1.15, w0.position.y + 0.95, zc),
		Vector3(w0.position.x + 1.15, w0.position.y + 1.23, zc), Vector3(w0.position.x + 0.55, w0.position.y + 1.23, zc), "vende", Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

# ---------------- the flats above ----------------
## The floors over the Calle Argentina, on the line a -> b (the corner first): brick, four windows on each floor, a
## soldier course at each floor, the projection's edge, the cables, the street's name plate at the corner, the air
## conditioners, a satellite dish, the eaves (e0, e1: how far they run on past its ends).
func _flats_argentina(a: Vector2, b: Vector2, e0: float, e1: float) -> void:
	var ln := face(a, b)
	var holes: Array = []
	for f: float in [F1, F2, F3]:
		for x: float in AR_UP:
			var m := _x_on(_along(K, E, x), a, b)
			holes.append(Rect2(m - WIN_W / 2.0, f + WIN_SILL, WIN_W, WIN_H))
	masonry(0.0, ln, SOFFIT, TOP, holes, [], "ladrillo")
	var downs := [0.35, 0.5, 0.2, 0.6, 0.45, 0.3, 0.55, 0.25, 0.4, 0.65, 0.3, 0.5]
	for i in range(holes.size()):
		_ventana(holes[i], downs[i % downs.size()])
	_bands(ln)
	_cables(SOFFIT + 0.14, 0.0, ln)
	_picture(0.42, 0.87, 3.86, 4.11, 0.012, "placa")                                   # the street's name, at the corner
	_ac(_x_on(_along(K, E, 1.35), a, b) - 0.39, F1 + 0.85)
	_ac(_x_on(_along(K, E, 8.2), a, b) - 0.39, F1 + 0.85)
	_ac(_x_on(_along(K, E, 11.4), a, b) - 0.39, F2 + 0.9)
	_dish(_x_on(_along(K, E, 10.6), a, b), F1 + 1.3)
	_eaves_edge(ln, e0, e1)
	home()

## The floors over the Calle de los Arcos, on the line a -> b (its north end first): brick, a window on each floor at
## either end, the stack of loggias between them.
func _flats_arcos(a: Vector2, b: Vector2, e0: float, e1: float) -> void:
	var ln := face(a, b)
	var holes: Array = []
	for f: float in [F1, F2, F3]:
		for q: Array in AC_UP:
			var m := _x_on(_along(N, K, float(q[0])), a, b)
			holes.append(Rect2(m - float(q[1]) / 2.0, f + WIN_SILL, float(q[1]), WIN_H))
	var lx0 := _x_on(_along(N, K, LOGGIA.x), a, b)
	var lx1 := _x_on(_along(N, K, LOGGIA.y), a, b)
	var logs: Array = []
	for f: float in [F1, F2, F3]:
		logs.append(Rect2(lx0, f, lx1 - lx0, LOG_H))
	var all := holes.duplicate()
	all.append_array(logs)
	masonry(0.0, ln, SOFFIT, TOP, all, [], "ladrillo")
	var downs := [0.5, 0.3, 0.6, 0.25, 0.4, 0.55]
	for i in range(holes.size()):
		_ventana(holes[i], downs[i % downs.size()])
	_loggia(lx0, lx1, F1, "cerrada")
	_loggia(lx0, lx1, F2, "abierta")
	_loggia(lx0, lx1, F3, "toldo")
	_bands(ln, [Vector2(lx0, lx1)])
	_cables(SOFFIT + 0.14, 0.0, ln)
	_ac(_x_on(_along(N, K, 3.15), a, b), F1 + 0.15, 0.66)
	_eaves_edge(ln, e0, e1)
	home()

## the soldier courses of the front being built: at the projection's edge and at each floor over the first (`gaps`:
## where the loggias cut them)
func _bands(ln: float, gaps: Array = []) -> void:
	box(0.0, SOFFIT, 0.0, ln, 0.22, 0.03, "sardinel")
	for f: float in [F2, F3]:
		var x := 0.0
		for gp: Vector2 in gaps:
			box(x, f - 0.07, 0.0, gp.x - x, 0.14, 0.014, "sardinel")
			x = gp.y
		box(x, f - 0.07, 0.0, ln - x, 0.14, 0.014, "sardinel")

## the eaves of the front being built: their underside of brick (Street View: a brick cornice, not a white soffit), their
## edge
func _eaves_edge(ln: float, e0: float, e1: float) -> void:
	pieces += 1
	quad(Vector3(0, TOP, 0), Vector3(ln, TOP, 0), Vector3(ln + e1, TOP, EAVE), Vector3(-e0, TOP, EAVE), "sardinel", Vector3.DOWN)
	box(0.0, TOP - 0.16, 0.0, ln, 0.16, 0.06, "sardinel")
	box(-e0, TOP - 0.04, EAVE - 0.05, ln + e0 + e1, RISE0 + 0.1, 0.05, 0x8a4a3a)

## A window of the flats in its hole: white aluminium, lace behind the glass, its white roller blind down `down` of it,
## the blind's box at its top, a brick sill standing out, a soldier course over it.
func _ventana(r: Rect2, down: float) -> void:
	openings += 1
	var z := -DEEP + 0.1
	box(r.position.x, r.position.y, z - 0.05, r.size.x, r.size.y, 0.03, LACE)
	for q in [[r.position.x, r.position.y, 0.06, r.size.y], [r.end.x - 0.06, r.position.y, 0.06, r.size.y], [r.position.x, r.position.y, r.size.x, 0.07], [r.position.x, r.end.y - 0.06, r.size.x, 0.06]]:
		box(q[0], q[1], z - 0.02, q[2], q[3], 0.06, ALU)
	box(r.get_center().x - 0.03, r.position.y, z - 0.02, 0.06, r.size.y, 0.065, ALU)
	box(r.position.x, r.end.y - 0.15, z + 0.04, r.size.x, 0.15, 0.04, ALU)             # (the blind's box)
	if down > 0.0:
		var drop := (r.size.y - 0.15) * down
		box(r.position.x + 0.02, r.end.y - 0.15 - drop, z + 0.05, r.size.x - 0.04, drop, 0.02, BLIND)
		for i in range(1, int(drop / 0.06)):
			box(r.position.x + 0.02, r.end.y - 0.15 - i * 0.06, z + 0.07, r.size.x - 0.04, 0.008, 0.004, 0xcfcfca)
	box(r.position.x - 0.06, r.position.y - 0.058, -DEEP + 0.1, r.size.x + 0.12, 0.07, DEEP - 0.04, "sardinel")
	box(r.position.x - 0.05, r.end.y, 0.0, r.size.x + 0.1, 0.13, 0.012, "sardinel")

## A loggia of the Arcos: its back wall, its sides past the wall's own depth, its ceiling, its slab standing out over
## the street with a railing of red-brown iron; at its back French windows and windows of white aluminium. `kind`:
## "cerrada" (the first: its north part shut in with white aluminium, that part's side painted orange, plants along
## the railing), "abierta" (the second), "toldo" (the third, a green awning hung at its front).
func _loggia(x0: float, x1: float, f: float, kind: String) -> void:
	balconies += 1
	var zb := -LOG_D
	var top := f + LOG_H
	pieces += 1
	quad(Vector3(x0, f, zb), Vector3(x1, f, zb), Vector3(x1, top, zb), Vector3(x0, top, zb), "ladrillo", Vector3(0, 0, 1))
	quad(Vector3(x0, f, zb), Vector3(x0, f, -DEEP), Vector3(x0, top, -DEEP), Vector3(x0, top, zb), "ladrillo", Vector3(1, 0, 0))
	quad(Vector3(x1, f, zb), Vector3(x1, f, -DEEP), Vector3(x1, top, -DEEP), Vector3(x1, top, zb), "ladrillo", Vector3(-1, 0, 0))
	quad(Vector3(x0, top, zb), Vector3(x1, top, zb), Vector3(x1, top, -DEEP), Vector3(x0, top, -DEEP), "losa", Vector3.DOWN)
	box(x0 - 0.06, f - 0.15, zb, x1 - x0 + 0.12, 0.16, -zb + BALC, "losa")            # its floor, standing out
	box(x0 - 0.07, f - 0.17, BALC - 0.02, x1 - x0 + 0.14, 0.04, 0.04, 0xc8c4bc)
	var zw := zb + 0.02
	var xm := x0 + 2.6                                                               # (where the first one's shut-in part ends)
	match kind:
		"cerrada":
			_french(Rect2(xm + 0.5, f, 0.95, 2.2), zw, 0.3)
			_french(Rect2(x1 - 1.45, f + 0.85, 1.1, 1.15), zw, 0.5)
			var zc := 0.22                                                           # the shut-in part: white aluminium at the front
			box(x0, f, zc - 0.02, xm - x0, 1.0, 0.04, ALU)
			box(x0, f + 1.0, zc - 0.04, xm - x0, LOG_H - 1.0, 0.02, LACE)
			for k in range(4):
				box(x0 + k * (xm - x0) / 3.0 - (0.06 if k == 3 else 0.0), f + 1.0, zc - 0.02, 0.06, LOG_H - 1.0, 0.05, ALU)
			box(x0, f + 0.98, zc - 0.02, xm - x0, 0.06, 0.05, ALU)
			box(x0, top - 0.06, zc - 0.02, xm - x0, 0.06, 0.05, ALU)
			box(x0 + 0.03, top - 0.06 - 0.75, zc, xm - x0 - 0.06, 0.75, 0.015, BLIND)         # (its blinds half down)
			pieces += 1
			quad(Vector3(xm, f, zb), Vector3(xm, f, zc), Vector3(xm, top, zc), Vector3(xm, top, zb), "naranja", Vector3(1, 0, 0))
			for k in range(5):                                                       # plants in pots along the open part's railing
				var px := xm + 0.35 + k * (x1 - xm - 0.7) / 4.0
				box(px - 0.1, f + 0.01, BALC - 0.3, 0.2, 0.18, 0.18, [0xa8583a, 0xd8d0c0, 0x3a6a3a][k % 3])
				for j in range(3):
					box(px - 0.12 + j * 0.06, f + 0.19, BALC - 0.28 + (j % 2) * 0.05, 0.1, 0.16 + 0.06 * (j % 2), 0.1, [0x3f7a34, 0x5a8a3a, 0x2f5a2a][(j + k) % 3])
		"abierta":
			_french(Rect2(x0 + 0.5, f + 0.85, 1.2, 1.15), zw, 0.4)
			_french(Rect2(x0 + 2.4, f, 0.95, 2.2), zw, 0.15, 0xe8c84a)
			_french(Rect2(x1 - 1.7, f + 0.85, 1.2, 1.15), zw, 0.6)
			box(x0 + 1.82, f + 1.9, zw, 0.55, 0.4, 0.22, 0xe9e9e5)                  # (an air conditioner high on its back wall)
		"toldo":
			_french(Rect2(x0 + 0.6, f, 0.95, 2.2), zw, 0.5)
			_french(Rect2(x1 - 1.9, f + 0.85, 1.2, 1.15), zw, 0.3)
			pieces += 1                                                              # its green awning, hung at the front
			quad(Vector3(x0 + 0.05, top - 0.04, -0.2), Vector3(x1 - 0.05, top - 0.04, -0.2), Vector3(x1 - 0.05, top - 0.6, 0.25), Vector3(x0 + 0.05, top - 0.6, 0.25), "lona_verde", Vector3(0, 0.45, 0.56).normalized())
			bar(Vector3(x0 + 0.05, top - 0.6, 0.25), Vector3(x1 - 0.05, top - 0.6, 0.25), 0.03, 0.03, 0xdedcd6)
	_railing(x0 - 0.04, x1 + 0.04, f + 0.01, BALC - 0.05)

## a French window (or a window) on a loggia's back wall at depth z: white aluminium, glass, its blind down `down` of it
## (a coloured curtain behind the glass when `curtain` is given)
func _french(r: Rect2, z: float, down: float, curtain := -1) -> void:
	openings += 1
	box(r.position.x, r.position.y, z, r.size.x, r.size.y, 0.02, LACE if curtain < 0 else curtain)
	for q in [[r.position.x, r.position.y, 0.06, r.size.y], [r.end.x - 0.06, r.position.y, 0.06, r.size.y], [r.position.x, r.position.y, r.size.x, 0.07], [r.position.x, r.end.y - 0.06, r.size.x, 0.06]]:
		box(q[0], q[1], z + 0.02, q[2], q[3], 0.05, ALU)
	box(r.get_center().x - 0.03, r.position.y, z + 0.02, 0.06, r.size.y, 0.05, ALU)
	if down > 0.0:
		var drop := r.size.y * down
		box(r.position.x + 0.03, r.end.y - drop, z + 0.07, r.size.x - 0.06, drop, 0.015, BLIND)

## a railing of red-brown iron from x0 to x1 at z, its foot at y: its uprights, its rails, its sides back to the wall
func _railing(x0: float, x1: float, y: float, z: float) -> void:
	var n := maxi(4, int(round((x1 - x0) / 0.11)))
	for k in range(n + 1):
		var ux := lerpf(x0 + 0.02, x1 - 0.02, float(k) / n)
		box(ux - 0.008, y, z - 0.008, 0.016, 0.98, 0.016, IRON_RED)
	bar(Vector3(x0, y + 0.99, z), Vector3(x1, y + 0.99, z), 0.045, 0.03, IRON_RED)
	bar(Vector3(x0, y + 0.08, z), Vector3(x1, y + 0.08, z), 0.025, 0.02, IRON_RED)
	for x in [x0 + 0.02, x1 - 0.02]:
		bar(Vector3(x, y + 0.99, 0.02), Vector3(x, y + 0.99, z), 0.03, 0.03, IRON_RED)
		for zz in [0.1, 0.2]:
			box(x - 0.008, y, zz, 0.016, 0.98, 0.016, IRON_RED)

## a satellite dish on the wall at (x, y): its arm, its white dish tilted up a little, its head
func _dish(x: float, y: float) -> void:
	bar(Vector3(x, y, 0.0), Vector3(x, y, 0.32), 0.03, 0.03, 0xb8bcc0)
	var keep := _xf
	_xf = keep * Transform3D(Basis(Vector3(1, 0, 0), PI / 2.0 - 0.45), Vector3(x, y + 0.08, 0.32))
	drum(Vector3.ZERO, 0.32, 0.26, 0.05, 0xe8e8e4, 18)
	_xf = keep
	bar(Vector3(x, y - 0.12, 0.34), Vector3(x, y + 0.02, 0.62), 0.02, 0.02, 0x9a9ea2)
	box(x - 0.04, y, 0.6, 0.08, 0.07, 0.06, 0x3a3a3e)

# ---------------- open and shut ----------------
## Open: the shutter rolled up, light inside. Shut: the white roller shutter down at the doorway's front (Street View 2024).
func _states() -> void:
	_shut = Node3D.new()
	add_child(_shut)
	face(K, E)
	var a := DOOR.position
	var b := DOOR.end
	box(a.x, 0.0, -0.09, DOOR.size.x, b.y, 0.03, 0xf0f0ec)
	for i in range(1, int(b.y / 0.09)):
		box(a.x, i * 0.09, -0.06, DOOR.size.x, 0.012, 0.006, 0xcfcfc9)
	box(a.x, 0.0, -0.07, DOOR.size.x, 0.08, 0.04, 0xd8d6d0)
	box((a.x + b.x) / 2.0 - 0.06, 0.12, -0.055, 0.12, 0.06, 0.02, 0x8a8a86)                     # (its lock)
	home()
	_commit_to(_shut)
	_open = Node3D.new()
	add_child(_open)
	face(K, E)
	box(a.x + 0.15, b.y - 0.06, -RECESS - 1.6, DOOR.size.x - 0.3, 0.04, 0.6, "luz")
	var lamp := OmniLight3D.new()
	lamp.position = _xf * Vector3((a.x + b.x) / 2.0, 2.2, -RECESS - 1.2)
	lamp.light_color = Color(1.0, 0.96, 0.9)
	lamp.omni_range = 4.0
	lamp.light_energy = 0.6
	lamp.shadow_enabled = false
	add_child(lamp)
	_lights.append(lamp)
	home()
	_commit_to(_open)

## what has been built since the last commit becomes meshes under `node`: a part that can be shown and hidden
func _commit_to(node: Node3D) -> void:
	for key in _tools:
		var mi := MeshInstance3D.new()
		mi.mesh = (_tools[key] as SurfaceTool).commit()
		mi.material_override = _material(key)
		node.add_child(mi)
	_tools.clear()

func set_open(on: bool) -> void:
	is_open = on
	if dentro != null:
		dentro.open = on
	if maniqui != null:                 # (out only while it is open, as the other two's)
		maniqui.set_out(on)
	if _shut != null:
		_shut.visible = not on
		_open.visible = on
	for lamp in _lights:
		(lamp as Light3D).visible = on
	if _mats.has("interior"):
		(_mats["interior"] as StandardMaterial3D).emission_energy_multiplier = 0.14 if on else 0.0
	if _mats.has("luz"):
		(_mats["luz"] as StandardMaterial3D).emission_energy_multiplier = 1.6 if on else 0.15

func _process(_delta: float) -> void:
	var game = W.get_parent() if W != null else null
	if game != null and "clock" in game and "weekday" in game:
		var want: bool = open_at(int(game.weekday), float(game.clock))
		if want != is_open:
			set_open(want)
