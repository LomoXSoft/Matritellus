extends "res://scripts/esquina.gd"
## The accessories shop "Tetoqa" of the corner of the Calle de Santa Ana and the Calle del Cristo: the real Tutoq
## Complementos (the user, 23 November 2026: "Vamos con la tienda de complementos Tutoq (que llamaremos Tetoqa). Mismo
## tratamiento que con MiniPrecio pero esta vez para complementos"). Built by hand on Texturas's house of the map
## (stana_54, handed over as ["obra"] in casas_calles.gd), with no rebake; referencias/tetoqa/. From Street View of
## November 2024.
##
## A block of flats on the corner, a ground floor and two floors over it under a hipped roof of old tiles:
##   - the ground floor is the shop, clad in polished pink-brown granite: to the Santa Ana two windows of clothes and
##     bags under the shop's board ("Complementos" in pink handwriting, the game's own, with sprigs of almond blossom
##     and "Tetoqa" small at its corner), an air conditioner, and at the west end the flats' doorway in pale stone, a
##     grey iron gate before its wooden door; on the chamfer the shop's door behind a white roller shutter; to the
##     Cristo two big windows (handbags and shoes on white cube shelves, a dress form, glass shelves of bags, and four
##     mannequins behind the glass: maniqui.gd in_window, the user's yes of 23 Nov 2026) and the light box with the
##     shop's name in a green frame over the pier by the corner (our own name: it is not blank, Street View from the
##     Cristo shows the real one's);
##   - the floors above stand out over the pavement: orange brick, cream panels framed by it, French windows behind
##     little balconies of wrought iron (two to each street, near the far end, one wide one on the chamfer), beige
##     blinds part of the way down, a cream strip with a brick diamond over each window under each floor's band; a
##     brick cornice under the eaves, a row of tiles' mouths along their edge.
## No number on it, no telephone, no social network (the game shows none). No saffron hidden here: one is proposed and
## the user says whether it goes in.
##
## Its hours are made up (Google Maps gives the real shop none, 23 November 2026), the town's usual for a shop: Monday
## to Friday from ten to half past one and from half past five to half past eight, Saturdays from ten to two, shut on
## Sundays. A card on the window by the door says so. Open: the shutter rolled up, the glass door behind it, light
## inside, the mannequin out on the pavement (maniqui.gd, dressed in hats and trinkets: it sells accessories). Shut: the
## shutter down, the windows dim, the mannequin in. Its inside is a set of its own (tetoqa_dentro.gd), walked into by
## the green arrow before the chamfer (entradas.gd).
##
## Frame: the map's own (x east, z south), y = 0 the pavement before the chamfer. Each front is built in its own frame
## (obra.face: +x along it, its left end seen from the street first; +z out of it).

const READY := true
const HOUSE := "stana_54"
const NAME := "Tetoqa"                           # what the shop is called in the game (the user, 23 Nov 2026)
const DIR := "res://assets/tetoqa/"
const DentroS = preload("res://scripts/tetoqa_dentro.gd")
const ManiquiS = preload("res://scripts/maniqui.gd")
const SemaforoS = preload("res://scripts/semaforo_ambar.gd")
## the mannequin at its door (as the MaxiPrecio's: the user, 23 Nov 2026, "Mismo tratamiento"): on the Santa Ana's
## pavement by the corner (along it from the chamfer, out), turned a little towards the chamfer's door
const MANIQUI := Vector2(0.3, 0.85)

# its outline on the map (the house stana_54), in the ring's order
const F0 := Vector2(402.31, 148.04)              # the back end of the wall it shares with the house west of it
const A := Vector2(405.45, 144.29)               # where it ends on the Calle de Santa Ana (the flats' doorway at that end)
const B := Vector2(412.54, 146.11)               # the Santa Ana's corner with the chamfer
const C := Vector2(414.3, 148.59)                # the chamfer's corner with the Calle del Cristo
const D := Vector2(412.17, 156.08)               # where it ends on the Cristo
const BACK := [Vector2(407.5, 154.88), Vector2(407.37, 155.41), Vector2(405.93, 155.11), Vector2(404.12, 156.54),
	Vector2(402.26, 152.92), Vector2(401.97, 150.48)]           # its back: walls to the plots behind it
const WEST_X := 401.97                           # where the roof's slope to the back starts

const SILL := 0.55              # the shop's windows, from here...
const HEAD := 2.75              # ...to here
const SOFFIT := 3.55            # the underside of the floors above, which stand out over the pavement...
const OUT := 0.45               # ...this far
const F1 := 4.0                 # the first floor
const F2 := 6.85                # the second
const TOP := 9.75               # the top of its walls, under the eaves
const EAVE := 0.42
const PITCH := 0.36
const RISE0 := 0.151            # (EAVE * PITCH: the eaves' edge level with the walls' top)
const PIER := 0.4               # the brick piers at the ends of each front above
const FRAME := 0.15             # the brick round each French window
const WIN_W := 1.1              # the French windows of the flats: how wide...
const WIN_H := 2.15             # ...and how high (they go down to the floor)
const CH_W := 1.5               # the chamfer's: two leaves
const BALC := 0.32              # how far their balconies stand out
const SA_WIN := [Rect2(0.45, SILL, 2.0, HEAD - SILL), Rect2(2.8, SILL, 2.0, HEAD - SILL)]     # the Santa Ana's windows (x from the chamfer)
const PORTAL := Vector2(5.75, 6.75)              # the flats' doorway on the Santa Ana (x from the chamfer)
const SA_UP := [3.9, 5.85]                       # the French windows over the Santa Ana (their middles, x from the chamfer below)
const DOOR := Rect2(0.5, 0.0, 2.04, 2.7)         # the shop's door on the chamfer (x from the Cristo's corner)
const CR_WIN := [Rect2(0.4, SILL, 2.0, HEAD - SILL), Rect2(2.8, SILL, 3.8, HEAD - SILL)]     # the Cristo's windows (x from its south end)
const CR_UP := [1.4, 3.35]                       # the French windows over the Cristo (x from its south end below)
const BOX := Rect2(6.3, 2.9, 1.4, 0.56)          # the light box with the shop's name, over the pier by the chamfer (Street View 2024, from the Cristo: the real one's name, in a green frame)
const HOURS := {0: [Vector2(10.0, 13.5), Vector2(17.5, 20.5)], 1: [Vector2(10.0, 13.5), Vector2(17.5, 20.5)],
	2: [Vector2(10.0, 13.5), Vector2(17.5, 20.5)], 3: [Vector2(10.0, 13.5), Vector2(17.5, 20.5)],
	4: [Vector2(10.0, 13.5), Vector2(17.5, 20.5)], 5: [Vector2(10.0, 14.0)]}      # the day (0 Monday ... 6 Sunday) and from when to when; Sundays shut
const ALU := 0xeeeeea           # the shop's white aluminium
const BLIND := 0xd9cfb8         # the flats' beige blinds
const GLASS := 0x26313a         # the flats' windows (dark: nothing is built behind them)
const COLOURS := [0xc8384a, 0x2f2f36, 0xe8d8b0, 0x8a5a3a, 0xe8a0b0, 0xf2f0ea, 0x3a5a9a, 0xd8a040, 0x7a5aa0, 0x5a8a6a, 0xb07a52, 0x9a2a3a, 0xd0c0a8, 0x1f1f22]

var door: Vector2                               # before the shop's door on the chamfer, on the pavement
var sa_spot: Vector2                            # before the Santa Ana's windows
var cr_spot: Vector2                            # before the Cristo's
var dentro                                      # its inside (tetoqa_dentro.gd)
var maniqui                                     # the mannequin at the door (maniqui.gd): street furniture, dressed anew each day
var semaforo                                    # the light before the chamfer, its amber blinking (semaforo_ambar.gd): street furniture
var dummies: Array = []                         # the mannequins behind the Cristo's glass (maniqui.gd in_window): dressed anew each day
var _slots: Array = []                          # (where they go, while the windows are built: [x along D->C, z out, y, turn])
var is_open := false
var openings := 0
var balconies := 0
var _shut: Node3D
var _open: Node3D
var _lights: Array = []
var _ns: Vector2                                # the outward normals of the Santa Ana, the chamfer and the Cristo
var _nc: Vector2
var _ne: Vector2
var _up: Array = []                             # the outline of the floors above (they stand out over the streets)
var _n := 0

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"granito":          # the shop's polished pinkish-grey granite (Street View 2024: about 143, 124, 110 in the shade of Santa Ana, 200, 195, 195 in the sun of the Cristo)
			m = Tex.mat("granite_tile_03@1.2", Color(0.86, 0.76, 0.7))
		"piedra":           # the pale stone round the flats' doorway, the windows' sills
			m = Tex.mat("granite_tile_04@1.0", Color(0.84, 0.76, 0.72))
		"ladrillo":         # the orange brick of the floors above (about 161, 117, 87 in the shade)
			m = _glow(Tex.mat("brick_wall_003@1.2", Color(0.92, 0.84, 0.86)), 0.06)
		"crema":            # the cream panels (about 186, 142, 103 in the sun)
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.96, 0.78, 0.56)), 0.14)
		"losa":             # the underside of the floors above, the balconies' slabs
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.92, 0.88, 0.8)), 0.22)
		"medianera":        # what looks on to its neighbours and the plots behind
			m = Tex.mat("painted_plaster_wall", Color(0.82, 0.76, 0.68))
		"tiles_tetoqa":     # its old tiles, darker than the town's new ones (its UVs in units of 1.6 m, down the slope)
			var tm: StandardMaterial3D = Tex.mat(Tex.pick("tiles") if Tex.pick("tiles") != "" else "clay_roof_tiles_02", Color(0.78, 0.62, 0.56), true, 1.6)
			tm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = tm
		"rotulo", "horario":
			var pm := StandardMaterial3D.new()
			pm.albedo_texture = load(DIR + String(key) + ".png")
			pm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			pm.roughness = 1.0
			pm.metallic_specular = 0.0          # (a shine picks up the sky and greys the pink)
			pm.emission_enabled = true          # (the board is in the shade of the floors above)
			pm.emission_texture = pm.albedo_texture
			pm.emission = Color.WHITE
			pm.emission_energy_multiplier = 0.12
			m = pm
		"caja":             # the light box's face: our own name between sprigs of almond (tools/tetoqa/dibujos.py)
			var cm := StandardMaterial3D.new()
			cm.albedo_texture = load(DIR + "caja.png")
			cm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			cm.roughness = 0.7
			cm.metallic_specular = 0.0
			cm.emission_enabled = true
			cm.emission_texture = cm.albedo_texture
			cm.emission = Color.WHITE
			cm.emission_energy_multiplier = 0.14
			m = cm
		"vidrio":
			var gm := StandardMaterial3D.new()
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.albedo_color = Color(0.55, 0.68, 0.72, 0.26)
			gm.roughness = 0.12
			gm.metallic_specular = 0.7
			gm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = gm
		"interior":         # the walls of what shows through the glass: the shop behind the windows, darker than the street (Street View 2024); dim when shut, lit when open
			var im := StandardMaterial3D.new()
			im.albedo_color = Color(0.4, 0.38, 0.37)
			im.roughness = 1.0
			im.emission_enabled = true
			im.emission = Color(1.0, 0.97, 0.92)
			im.emission_energy_multiplier = 0.05
			m = im
		"luz":
			var lm := StandardMaterial3D.new()
			lm.albedo_color = Color(1.0, 0.99, 0.95)
			lm.emission_enabled = true
			lm.emission = Color(1.0, 0.98, 0.92)
			lm.emission_energy_multiplier = 1.6
			m = lm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world, _hd: Dictionary) -> void:
	W = world
	_ns = _outward(B, A)
	_nc = _outward(C, B)
	_ne = _outward(D, C)
	var mid := B.lerp(C, 0.5)
	level = MapData.height(mid + _nc * 1.0)
	transform = Transform3D(Basis.IDENTITY, Vector3(0.0, level, 0.0))
	W.add_child(self)
	var ring := _ring()
	var by := []
	for i in range(ring.size()):
		by.append(-OUT if i in [1, 2, 3] else 0.0)                 # (the floors above stand out over the three streets)
	_up = _inset(ring, by)
	wall_top = TOP
	eave_out = EAVE
	roof_pitch = PITCH
	roof_rise0 = RISE0
	var A2: Vector2 = _up[1]
	var B2: Vector2 = _up[2]
	var C2: Vector2 = _up[3]
	var D2: Vector2 = _up[4]
	_planes = [[_ns, B2.dot(_ns)], [_nc, B2.dot(_nc)], [_ne, C2.dot(_ne)], [Vector2(-1.0, 0.0), -WEST_X]]      # a slope to each street, and one that falls to the back
	var rby := []
	for i in range(ring.size()):
		rby.append(-EAVE if i in [1, 2, 3] else 0.0)
	var rr := _inset(_up, rby)                                     # (the roof's outline: where the eaves end)
	_santa_ana()
	_chamfer()
	_cristo()
	var l_sa := B2.distance_to(A2)
	var l_ch := C2.distance_to(B2)
	var l_cr := D2.distance_to(C2)
	var sa_mids: Array = []
	for x: float in SA_UP:
		sa_mids.append(_x_on(_along(B, A, x), B2, A2))
	var cr_mids: Array = []
	for x: float in CR_UP:
		cr_mids.append(_x_on(_along(D, C, x), D2, C2))
	_flats(B2, A2, sa_mids, WIN_W, -_x_on(rr[2], B2, A2), _x_on(rr[1], B2, A2) - l_sa, [0.4, 0.45, 0.3, 0.4], false, true)
	_flats(C2, B2, [l_ch / 2.0], CH_W, -_x_on(rr[3], C2, B2), _x_on(rr[2], C2, B2) - l_ch, [0.5, 0.4], false, false)
	_flats(D2, C2, cr_mids, WIN_W, -_x_on(rr[4], D2, C2), _x_on(rr[3], D2, C2) - l_cr, [0.25, 0.55, 0.45, 0.2], true, false)
	home()
	_flat_down(PackedVector2Array([A, B, C, D, D2, C2, B2, A2]), SOFFIT, "losa")      # the underside of the floors above
	_party_wall(F0, A)
	_return(A2, A)
	_party_wall(D, BACK[0])
	_return(D, D2)
	for i in range(BACK.size()):
		_party_wall(BACK[i], BACK[i + 1] if i + 1 < BACK.size() else F0)
	_roof_over(_up, rby, "tiles_tetoqa")
	home()
	_commit()
	_states()
	_ring_solids(ring, 12.0)
	door = mid + _nc * 1.2
	sa_spot = _along(B, A, 2.6) + _ns * 1.5
	cr_spot = _along(D, C, 4.5) + _ne * 1.5
	dentro = DentroS.new()                          # (its door on the chamfer: the arrow stands before it)
	dentro.build(world, mid + _nc * 0.5, mid + _nc * 1.9, atan2(_nc.x, _nc.y))
	var mp := _along(B, A, MANIQUI.x) + _ns * MANIQUI.y
	maniqui = ManiquiS.new()
	maniqui.setup(world, mp, atan2(_ns.x, _ns.y) - 0.4, MapData.foot(mp) - level, true)
	add_child(maniqui)
	for sl: Array in _slots:                       # the mannequins behind the Cristo's glass: on its windows' floor, looking out
		var wp: Vector2 = _along(D, C, float(sl[0])) + _ne * float(sl[1])
		var dm = ManiquiS.new()
		dm.setup(world, wp, atan2(_ne.x, _ne.y) + float(sl[3]), float(sl[2]), true, true)
		add_child(dm)
		dummies.append(dm)
	var sp := _along(B, C, B.distance_to(C) * 0.92) + _nc * 0.6      # the light: at the Cristo's end of the chamfer, by the kerb (Street View 2024)
	for k in range(60):
		if MapData.road_edge_dist(sp + _nc * 0.05) < 0.45:
			break
		sp += _nc * 0.05
	semaforo = SemaforoS.new()
	semaforo.setup(world, sp, B + (B - A).normalized() * 12.0 + _ns * 3.0, MapData.foot(sp) - level)     # (its head looks up the Santa Ana, to the east)
	add_child(semaforo)
	set_open(open_at(0, 12.0))

func _ring() -> Array:
	var r: Array = [F0, A, B, C, D]
	r.append_array(BACK)
	return r

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

## The projection's side over a neighbour's wall (or where its neighbour would be), from the floors' underside up to
## the roof's line, on the line a -> b.
func _return(a: Vector2, b: Vector2) -> void:
	var ln := face(a, b)
	pieces += 1
	quad(Vector3(0, SOFFIT, 0), Vector3(ln, SOFFIT, 0), Vector3(ln, wall_top, 0), Vector3(0, wall_top, 0), "medianera", Vector3(0, 0, 1))
	quad(Vector3(0, wall_top, 0), Vector3(ln, wall_top, 0), Vector3(ln, _roof_y(b) - 0.03, 0), Vector3(0, _roof_y(a) - 0.03, 0), "medianera", Vector3(0, 0, 1))
	home()

## the dark grilles of the vents low in the granite, under a window
func _vents(x0: float, x1: float) -> void:
	for x in [x0 + 0.25, x1 - 0.55]:
		box(x, 0.12, 0.0, 0.3, 0.16, 0.012, 0x2e2e30)
		for k in range(4):
			box(x + 0.02, 0.14 + k * 0.035, 0.012, 0.26, 0.012, 0.006, 0x4a4a4c)

## A shop window in its hole: white aluminium round the glass, a sill of pale stone, and behind the glass a little lit
## room with what it shows (`kind`: "ropa" clothes on a rail and bags; "bolsos" white cube shelves of handbags, shoes
## and hats; "mixto" glass shelves of bags and a hat stand).
func _vitrina(r: Rect2, kind: String) -> void:
	openings += 1
	var z := -DEEP + 0.08
	var a := r.position
	var b := r.end
	pieces += 1
	quad(Vector3(a.x, a.y, z), Vector3(b.x, a.y, z), Vector3(b.x, b.y, z), Vector3(a.x, b.y, z), "vidrio", Vector3(0, 0, 1))
	for q in [[a.x, a.y, 0.06, r.size.y], [b.x - 0.06, a.y, 0.06, r.size.y], [a.x, a.y, r.size.x, 0.07], [a.x, b.y - 0.06, r.size.x, 0.06]]:
		box(q[0], q[1], z - 0.03, q[2], q[3], 0.05, ALU)
	box(a.x - 0.03, a.y - 0.06, -0.04, r.size.x + 0.06, 0.06, 0.1, "piedra")
	var zb := -1.35
	var zf := z - 0.04
	pieces += 1
	quad(Vector3(a.x, a.y, zb), Vector3(b.x, a.y, zb), Vector3(b.x, b.y, zb), Vector3(a.x, b.y, zb), "interior", Vector3(0, 0, 1))
	quad(Vector3(a.x, a.y, zb), Vector3(a.x, a.y, zf), Vector3(a.x, b.y, zf), Vector3(a.x, b.y, zb), "interior", Vector3(1, 0, 0))
	quad(Vector3(b.x, a.y, zb), Vector3(b.x, a.y, zf), Vector3(b.x, b.y, zf), Vector3(b.x, b.y, zb), "interior", Vector3(-1, 0, 0))
	quad(Vector3(a.x, a.y, zb), Vector3(b.x, a.y, zb), Vector3(b.x, a.y, zf), Vector3(a.x, a.y, zf), 0xcfc4b8, Vector3.UP)
	quad(Vector3(a.x, b.y, zb), Vector3(b.x, b.y, zb), Vector3(b.x, b.y, zf), Vector3(a.x, b.y, zf), "interior", Vector3.DOWN)
	box(a.x + 0.1, b.y - 0.04, zb + 0.5, r.size.x - 0.2, 0.03, 0.1, "luz")          # (its strip light)
	match kind:
		"ropa":
			var yr := b.y - 0.28
			bar(Vector3(a.x + 0.08, yr, zb + 0.4), Vector3(b.x - 0.08, yr, zb + 0.4), 0.025, 0.025, 0xb8bcc0)
			for px in [a.x + 0.1, b.x - 0.1]:
				bar(Vector3(px, yr, zb + 0.4), Vector3(px, b.y, zb + 0.4), 0.02, 0.02, 0xb8bcc0)
			var x := a.x + 0.25
			var k := 0
			while x < b.x - 0.2:                                    # clothes on hangers, their fronts to the street
				var c := _colour()
				var long := 0.7 + 0.14 * (k % 3)
				var zz := zb + 0.36 + 0.025 * (k % 2)
				bar(Vector3(x - 0.16, yr - 0.06, zz), Vector3(x, yr, zz), 0.012, 0.012, 0x5a4636)
				bar(Vector3(x, yr, zz), Vector3(x + 0.16, yr - 0.06, zz), 0.012, 0.012, 0x5a4636)
				box(x - 0.19, yr - 0.06 - long, zz - 0.02, 0.38, long, 0.04, c)
				if k % 3 == 1:                                      # (a scarf over this one)
					box(x - 0.06, yr - 0.5, zz + 0.02, 0.12, 0.44, 0.015, _colour(k))
				x += 0.36
				k += 1
			box(a.x + 0.15, a.y, zb + 0.75, r.size.x - 0.3, 0.28, 0.36, 0xf2f2ee)          # a low white stand
			var xs := a.x + 0.35
			var j := 0
			while xs < b.x - 0.3:
				if j % 2 == 0:
					_bag(xs, a.y + 0.28, zb + 0.93, 0.28, _colour())
				else:
					_shoes(xs, a.y + 0.28, zb + 0.93, _colour())
				xs += 0.42
				j += 1
		"bolsos":                                                   # (Street View 2024: a mannequin at each end, the cubes between)
			_slots.append([a.x + 0.42, zb + 0.55, a.y, 0.25])
			_slots.append([b.x - 0.42, zb + 0.55, a.y, -0.25])
			var cols := int((r.size.x - 1.7) / 0.42)
			var cw := (r.size.x - 1.7) / cols
			var rows := 3
			var ch := 0.42
			var x0 := a.x + 0.85
			_dress_form(x0 + cw * 1.5, a.y + rows * ch, zb + 0.58)
			for i in range(cols + 1):                               # the white cube shelves
				box(x0 + i * cw - 0.015, a.y, zb + 0.4, 0.03, rows * ch, 0.36, 0xf4f4f0)
			for j in range(rows + 1):
				box(x0, a.y + j * ch - (0.03 if j > 0 else 0.0), zb + 0.4, cols * cw, 0.03, 0.36, 0xf4f4f0)
			for i in range(cols):
				for j in range(rows):
					var cx := x0 + (i + 0.5) * cw
					var y := a.y + j * ch + 0.03
					match (i * 3 + j * 2) % 5:
						0, 2:
							_bag(cx, y, zb + 0.6, cw * 0.62, _colour())
						1:
							_shoes(cx, y, zb + 0.62, _colour())
						3:
							_hat(cx, y, zb + 0.58, _colour(), 0.15)
						4:
							for f in range(3):                     # folded scarves
								box(cx - cw * 0.35, y + f * 0.05, zb + 0.5, cw * 0.7, 0.045, 0.24, _colour(f))
		"mixto":                                                    # (Street View 2024: two mannequins, glass shelves of bags by them)
			_slots.append([a.x + 0.4, zb + 0.6, a.y, 0.2])
			_slots.append([a.x + 1.08, zb + 0.6, a.y, -0.1])
			var sx := a.x + 1.44
			for y in [a.y + 0.05, a.y + 0.6, a.y + 1.15]:          # glass shelves on a chrome stand
				box(sx, y, zb + 0.45, b.x - 0.08 - sx, 0.015, 0.4, 0xc8dce0)
			for x in [sx + 0.02, b.x - 0.1]:
				bar(Vector3(x, a.y, zb + 0.65), Vector3(x, a.y + 1.35, zb + 0.65), 0.025, 0.025, 0xc0c4c8)
			for y in [a.y + 0.065, a.y + 0.615, a.y + 1.165]:
				_bag((sx + b.x - 0.08) / 2.0, y, zb + 0.65, 0.26, _colour())

## a dress form on top of the cube shelves (Street View 2024: a cream jacket with a black bow on one): its foot at y,
## a chrome stem, the jacket's body tapered at the waist, the neck and its knob
func _dress_form(x: float, y: float, z: float) -> void:
	drum(Vector3(x, y, z), 0.09, 0.09, 0.015, 0xc0c4c8, 12)
	bar(Vector3(x, y, z), Vector3(x, y + 0.12, z), 0.02, 0.02, 0xc0c4c8)
	var j := 0xefe6d2
	drum(Vector3(x, y + 0.12, z), 0.15, 0.125, 0.1, j, 16)                   # the hips...
	drum(Vector3(x, y + 0.22, z), 0.125, 0.165, 0.17, j, 16)                 # ...the waist up to the chest...
	drum(Vector3(x, y + 0.39, z), 0.165, 0.1, 0.12, j, 16)                   # ...the shoulders
	drum(Vector3(x, y + 0.51, z), 0.045, 0.04, 0.07, 0xf1f0ec, 12)           # its neck
	drum(Vector3(x, y + 0.58, z), 0.05, 0.02, 0.025, 0x2a2622, 12)           # (the knob)
	box(x - 0.012, y + 0.18, z + 0.155, 0.024, 0.24, 0.012, 0x1f1f22)        # the black edge down its front...
	box(x - 0.08, y + 0.4, z + 0.13, 0.07, 0.06, 0.02, 0x1f1f22)             # ...and the bow
	box(x + 0.01, y + 0.4, z + 0.13, 0.07, 0.06, 0.02, 0x1f1f22)
	box(x - 0.015, y + 0.4, z + 0.14, 0.03, 0.06, 0.022, 0x1f1f22)

## a handbag standing at x (its middle), its foot at y, its back at z - 0.06: `w` wide, its handle, its clasp
func _bag(x: float, y: float, z: float, w: float, col: int) -> void:
	var h := w * 0.7
	box(x - w / 2.0, y, z - 0.06, w, h, 0.12, col)
	var top := y + h + w * 0.32
	bar(Vector3(x - w * 0.3, y + h, z), Vector3(x - w * 0.16, top, z), 0.016, 0.016, col)
	bar(Vector3(x - w * 0.16, top, z), Vector3(x + w * 0.16, top, z), 0.016, 0.016, col)
	bar(Vector3(x + w * 0.16, top, z), Vector3(x + w * 0.3, y + h, z), 0.016, 0.016, col)
	box(x - 0.025, y + h * 0.6, z + 0.06, 0.05, 0.03, 0.008, 0xd8b84a)

## a pair of shoes at x, facing out
func _shoes(x: float, y: float, z: float, col: int) -> void:
	for s in [-0.06, 0.06]:
		box(x + s - 0.04, y, z - 0.12, 0.08, 0.055, 0.24, col)
		box(x + s - 0.04, y, z - 0.12, 0.08, 0.11, 0.07, col)
		box(x + s - 0.042, y, z - 0.122, 0.084, 0.012, 0.244, 0x2a2622)

## a hat: its brim (radius r), its crown, its band
func _hat(x: float, y: float, z: float, col: int, r := 0.17) -> void:
	drum(Vector3(x, y, z), r, r, 0.012, col, 16)
	drum(Vector3(x, y + 0.012, z), r * 0.55, r * 0.5, r * 0.6, col, 14)
	drum(Vector3(x, y + 0.012, z), r * 0.56, r * 0.555, r * 0.16, 0x2a2622 if col != 0x1f1f22 else 0xc8384a, 14)

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

# ---------------- the Calle de Santa Ana (north) ----------------
func _santa_ana() -> void:
	var ln := face(B, A)
	var g := _g(B, A, (PORTAL.x + PORTAL.y) / 2.0)                  # (the street rises a little to the west)
	var portal := Rect2(PORTAL.x, g, PORTAL.y - PORTAL.x, 2.55)
	var stone := Rect2(PORTAL.x - 0.24, -0.9, PORTAL.y - PORTAL.x + 0.48, g + 2.8 + 0.9)
	masonry(0.0, ln, -0.9, SOFFIT, [SA_WIN[0], SA_WIN[1], portal], [stone], "granito", "piedra")
	for r: Rect2 in SA_WIN:
		_vitrina(r, "ropa")
		_vents(r.position.x, r.end.x)
	pieces += 1                                                     # the card of its hours, on the first window's glass
	var zc := -DEEP + 0.085
	quad(Vector3(0.62, 0.78, zc), Vector3(0.92, 0.78, zc), Vector3(0.92, 1.18, zc), Vector3(0.62, 1.18, zc), "horario", Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	box(1.0, 0.8, zc - 0.002, 0.22, 0.3, 0.004, 0xf4f2ee)          # (and a notice by it)
	# the board over the first window: "Complementos" (the game's own), in a thin dark frame
	box(0.02, 2.88, 0.0, 2.4, 0.58, 0.05, 0x3a3438)
	_picture(0.03, 2.41, 2.89, 3.45, 0.051, "rotulo")
	# the air conditioner over the pier before the doorway, the alarm's box by it, its pipe
	box(4.86, 2.86, 0.0, 0.8, 0.54, 0.27, 0xe9e9e5)
	box(4.93, 2.94, 0.27, 0.42, 0.38, 0.01, 0x9a9c9e)
	for i in range(6):
		box(4.95, 2.96 + i * 0.06, 0.275, 0.38, 0.012, 0.01, 0x6a6c70)
	for q in [[4.88, 2.84], [5.6, 2.84]]:
		bar(Vector3(q[0], q[1], 0.0), Vector3(q[0], q[1], 0.25), 0.03, 0.03, 0x8a8a86)
	box(5.72, 3.0, 0.0, 0.26, 0.2, 0.08, 0xe8e0c8)
	box(5.76, 3.13, 0.08, 0.06, 0.03, 0.005, 0xc8384a)
	bar(Vector3(5.66, 3.0, 0.05), Vector3(5.85, 2.62, 0.05), 0.02, 0.02, 0x2a2a2c)
	_doorway(portal)
	home()

## The flats' doorway: pale stone round it, a step, the hall's wooden door set back, a grey iron gate before it, the
## letter boxes' little window over it.
func _doorway(r: Rect2) -> void:
	openings += 1
	var y0 := r.position.y
	box(r.position.x - 0.06, y0 - 0.5, -DEEP, r.size.x + 0.12, 0.5 + 0.04, DEEP + 0.12, "piedra")       # (its step)
	box(r.position.x, y0, -DEEP - 0.06, r.size.x, r.size.y, 0.06, 0x7a4a2c)                             # the wooden door...
	for q in [[0.1, 0.25, 0.8, 0.9], [0.1, 1.2, 0.8, 1.1]]:                                            # ...its panels
		box(r.position.x + q[0], y0 + q[1], -DEEP, q[2], q[3], 0.02, 0x6a3e24)
	box(r.end.x - 0.18, y0 + 1.05, -DEEP + 0.02, 0.04, 0.12, 0.03, 0xc8b070)
	var z := -0.04                                                                                    # the grey gate, flush with the stone
	for k in range(int(r.size.x / 0.1) + 1):
		box(r.position.x + 0.02 + k * (r.size.x - 0.04) / int(r.size.x / 0.1), y0, z, 0.018, r.size.y - 0.05, 0.018, 0x7c8086)
	for y in [0.1, 1.0, r.size.y - 0.08]:
		box(r.position.x, y0 + y, z - 0.01, r.size.x, 0.04, 0.035, 0x7c8086)
	for k in range(5):                                                                                # (its scrolls over the middle rail)
		var cx := r.position.x + (k + 0.5) * r.size.x / 5.0
		bar(Vector3(cx - 0.08, y0 + 1.04, z), Vector3(cx, y0 + 1.22, z), 0.014, 0.014, 0x7c8086)
		bar(Vector3(cx, y0 + 1.22, z), Vector3(cx + 0.08, y0 + 1.04, z), 0.014, 0.014, 0x7c8086)

# ---------------- the chamfer ----------------
func _chamfer() -> void:
	var ln := face(C, B)
	masonry(0.0, ln, -0.9, SOFFIT, [DOOR], [], "granito")
	openings += 1
	var a := DOOR.position
	var b := DOOR.end
	var z := -DEEP + 0.06
	box(a.x, -0.3, -DEEP, DOOR.size.x, 0.33, DEEP, "piedra")                                         # (its sill)
	for x in [a.x, b.x - 0.06, (a.x + b.x) / 2.0 - 0.03]:                                            # the glass door: two leaves of white aluminium
		box(x, 0.03, z - 0.03, 0.06, 2.5, 0.06, ALU)
	for y in [0.03, 0.95, 2.47]:
		box(a.x, y, z - 0.03, DOOR.size.x, 0.1 if y < 0.1 else 0.06, 0.06, ALU)
	box(a.x, 2.53, z - 0.03, DOOR.size.x, b.y - 2.53, 0.06, 0x5a5a5c)                                  # (over it, the shutter's box, dark)
	pieces += 1
	quad(Vector3(a.x, 0.13, z), Vector3(b.x, 0.13, z), Vector3(b.x, 2.47, z), Vector3(a.x, 2.47, z), "vidrio", Vector3(0, 0, 1))
	for x in [(a.x + b.x) / 2.0 - 0.12, (a.x + b.x) / 2.0 + 0.09]:
		box(x, 0.9, z + 0.03, 0.03, 0.4, 0.04, 0xb8bcc0)                                                # (its handles)
	var zb := -2.4                                                                                    # the shop behind the door: lit when open
	pieces += 1
	quad(Vector3(a.x, 0.03, zb), Vector3(b.x, 0.03, zb), Vector3(b.x, b.y, zb), Vector3(a.x, b.y, zb), "interior", Vector3(0, 0, 1))
	quad(Vector3(a.x, 0.03, zb), Vector3(a.x, 0.03, z), Vector3(a.x, b.y, z), Vector3(a.x, b.y, zb), "interior", Vector3(1, 0, 0))
	quad(Vector3(b.x, 0.03, zb), Vector3(b.x, 0.03, z), Vector3(b.x, b.y, z), Vector3(b.x, b.y, zb), "interior", Vector3(-1, 0, 0))
	quad(Vector3(a.x, 0.03, zb), Vector3(b.x, 0.03, zb), Vector3(b.x, 0.03, z), Vector3(a.x, 0.03, z), 0xd8cfc4, Vector3.UP)
	quad(Vector3(a.x, b.y, zb), Vector3(b.x, b.y, zb), Vector3(b.x, b.y, z), Vector3(a.x, b.y, z), "interior", Vector3.DOWN)
	box(a.x + 0.3, 0.03, zb + 0.05, 0.4, 1.8, 0.35, 0xf4f4f0)                                         # (a shelf of bags at the back...)
	for y in [0.5, 1.0, 1.5]:
		_bag(a.x + 0.5, 0.03 + y, zb + 0.25, 0.24, _colour())
	box(b.x - 0.9, 0.03, zb + 0.3, 0.7, 0.9, 0.5, 0xe8a0b0)                                          # (...and the counter's pink end)
	for x in [a.x - 0.03, b.x - 0.01]:                                                                 # the shutter's runners, either side
		box(x, 0.0, -0.1, 0.04, b.y, 0.06, 0xd8d6d0)
	home()

# ---------------- the Calle del Cristo (east) ----------------
func _cristo() -> void:
	var ln := face(D, C)
	masonry(0.0, ln, -0.9, SOFFIT, CR_WIN, [], "granito")
	_vitrina(CR_WIN[0], "mixto")
	_vitrina(CR_WIN[1], "bolsos")
	for r: Rect2 in CR_WIN:
		_vents(r.position.x, r.end.x)
	box(BOX.position.x, BOX.position.y, 0.0, BOX.size.x, BOX.size.y, 0.14, 0xf2f2ee)                  # the light box with the name...
	_picture(BOX.position.x + 0.04, BOX.end.x - 0.04, BOX.position.y + 0.04, BOX.end.y - 0.04, 0.141, "caja")
	for q in [[BOX.position.x - 0.03, BOX.position.y - 0.03, BOX.size.x + 0.06, 0.05], [BOX.position.x - 0.03, BOX.end.y - 0.02, BOX.size.x + 0.06, 0.05],
			[BOX.position.x - 0.03, BOX.position.y, 0.05, BOX.size.y], [BOX.end.x - 0.02, BOX.position.y, 0.05, BOX.size.y]]:
		box(q[0], q[1], 0.0, q[2], q[3], 0.16, 0x2f6a46)                                              # ...in its green frame
	box(2.48, 3.05, 0.0, 0.2, 0.26, 0.07, 0xf0f0ec)                                                     # (a little white box on the pier)
	home()

# ---------------- the flats above ----------------
## The flats over one street, on the line from a to b (its left end first, seen from the street): brick, cream panels
## framed by it, the French windows (their middles along the line, `w` wide) behind little balconies of wrought iron,
## a cream strip with brick diamonds under each floor's band, the cornice and the tiles' mouths along the eaves (e0,
## e1: how far the eaves run on past its ends); `end0`/`end1`: an end at a neighbour's wall (the cornice stops short).
func _flats(a: Vector2, b: Vector2, mids: Array, w: float, e0: float, e1: float, blinds: Array, end0: bool, end1: bool) -> void:
	var ln := face(a, b)
	var holes: Array = []
	var cream: Array = []
	var marks: Array = []
	for yb: float in [F1, F2]:
		var x := PIER
		var cuts: Array = []
		for m: float in mids:
			holes.append(Rect2(m - w / 2.0, yb, w, WIN_H))
			cuts.append([m - w / 2.0 - FRAME, m + w / 2.0 + FRAME])
			marks.append(Vector2(m, yb + 2.56))
		cuts.append([ln - PIER, ln - PIER])
		for c in cuts:
			_panels_in(cream, x, c[0], yb)
			if c[0] - x > 1.6:                                      # (diamonds over the long blank stretches too)
				var nd := int((c[0] - x) / 1.4)
				for k in range(nd):
					marks.append(Vector2(lerpf(x, c[0], (k + 0.5) / nd), yb + 2.56))
			x = c[1]
		cream.append(Rect2(PIER, yb + 2.42, ln - 2.0 * PIER, 0.28))   # (the strip over the floor)
	masonry(0.0, ln, SOFFIT, TOP, holes, cream, "ladrillo", "crema")
	for p: Vector2 in marks:
		tbox(Transform3D(Basis(Vector3(0, 0, 1), PI / 4.0).scaled_local(Vector3(0.15, 0.15, 0.04)), Vector3(p.x, p.y, 0.012)), "ladrillo")
	for i in range(holes.size()):
		var r: Rect2 = holes[i]
		_french(r, float(blinds[i % blinds.size()]))
		stone_frame(r, FRAME, 0.025, "ladrillo")
		_balcony(r)
	box(PIER - 0.02, SOFFIT, 0.0, ln - 2.0 * PIER + 0.04, 0.05, 0.04, "ladrillo")      # (the projection's edge, a course proud)
	_cables(SOFFIT + 0.2, 0.0, ln)
	cornice(0.18 if end0 else 0.0, ln - (0.18 if end1 else 0.0), TOP, true, "ladrillo", 0.6)
	var n := maxi(2, int(round((ln + e0 + e1) / 0.19)))                  # the tiles' mouths along the eaves' edge
	for k in range(n):
		var xa := lerpf(-e0, ln + e1, (k + 0.12) / n)
		var xb := lerpf(-e0, ln + e1, (k + 0.88) / n)
		box(xa, TOP - 0.06, EAVE - 0.12, xb - xa, 0.08, 0.13, 0x6a3a2a)
	home()

## the cream panels between x0 and x1 on the floor at yb: three long ones one over another on a wide stretch (two side by
## side on a very long one), two tall narrow ones on a narrow stretch, none on a sliver
func _panels_in(list: Array, x0: float, x1: float, yb: float) -> void:
	var wd := x1 - x0
	if wd < 0.3:
		return
	if wd > 1.2:
		var cols := 2 if wd > 3.4 else 1
		var cw := (wd - (cols - 1) * 0.12) / cols
		for c in range(cols):
			for k in range(3):
				list.append(Rect2(x0 + c * (cw + 0.12), yb + 0.15 + k * 0.757, cw, 0.637))
	else:
		for k in range(2):
			list.append(Rect2(x0, yb + 0.15 + k * 1.135, wd, 1.015))

## A French window of the flats in its hole: white aluminium, dark glass, its beige blind down `down` of it.
func _french(r: Rect2, down: float) -> void:
	openings += 1
	var z := -DEEP + 0.08
	box(r.position.x, r.position.y, z - 0.05, r.size.x, r.size.y, 0.03, GLASS)
	for q in [[r.position.x, r.position.y, 0.06, r.size.y], [r.end.x - 0.06, r.position.y, 0.06, r.size.y], [r.position.x, r.position.y, r.size.x, 0.09], [r.position.x, r.end.y - 0.07, r.size.x, 0.07]]:
		box(q[0], q[1], z - 0.02, q[2], q[3], 0.06, ALU)
	box(r.get_center().x - 0.03, r.position.y, z - 0.02, 0.06, r.size.y, 0.065, ALU)
	box(r.position.x, r.position.y + 0.95, z - 0.02, r.size.x, 0.05, 0.06, ALU)
	if down > 0.0:
		var drop := r.size.y * down
		box(r.position.x + 0.03, r.end.y - drop, z + 0.05, r.size.x - 0.06, drop, 0.02, BLIND)
		for i in range(1, int(drop / 0.08)):
			box(r.position.x + 0.03, r.end.y - i * 0.08, z + 0.07, r.size.x - 0.06, 0.01, 0.005, 0xc4b89e)

## a little balcony before a French window: its slab, its wrought iron (uprights, a rail on top and at its foot, a band
## of scrolls under the top), its sides back to the wall
func _balcony(r: Rect2) -> void:
	balconies += 1
	var x0 := r.position.x - 0.18
	var x1 := r.end.x + 0.18
	var y := r.position.y
	box(x0, y - 0.12, 0.0, x1 - x0, 0.12, BALC, "losa")
	box(x0 - 0.01, y - 0.15, BALC - 0.03, x1 - x0 + 0.02, 0.03, 0.04, "ladrillo")
	var z := BALC - 0.04
	var n := maxi(4, int(round((x1 - x0) / 0.11)))
	for k in range(n + 1):
		var ux := lerpf(x0 + 0.02, x1 - 0.02, float(k) / n)
		box(ux - 0.008, y, z - 0.008, 0.016, 0.98, 0.016, IRON)
	bar(Vector3(x0, y + 0.99, z), Vector3(x1, y + 0.99, z), 0.04, 0.03, IRON)
	bar(Vector3(x0, y + 0.06, z), Vector3(x1, y + 0.06, z), 0.025, 0.02, IRON)
	bar(Vector3(x0, y + 0.78, z), Vector3(x1, y + 0.78, z), 0.02, 0.02, IRON)
	var m := maxi(3, int((x1 - x0) / 0.17))
	for k in range(m):                                             # (the scrolls: crossed bars in the band under the rail)
		var xa := lerpf(x0 + 0.02, x1 - 0.02, float(k) / m)
		var xb := lerpf(x0 + 0.02, x1 - 0.02, float(k + 1) / m)
		bar(Vector3(xa, y + 0.79, z + 0.012), Vector3(xb, y + 0.97, z + 0.012), 0.012, 0.012, IRON)
		bar(Vector3(xa, y + 0.97, z + 0.012), Vector3(xb, y + 0.79, z + 0.012), 0.012, 0.012, IRON)
	for x in [x0 + 0.02, x1 - 0.02]:
		bar(Vector3(x, y + 0.99, 0.02), Vector3(x, y + 0.99, z), 0.03, 0.03, IRON)
		for zz in [0.12, 0.22]:
			box(x - 0.008, y, zz, 0.016, 0.98, 0.016, IRON)

# ---------------- open and shut ----------------
## Open: the shutter rolled up, light inside. Shut: the white shutter down over the glass door, its lock.
func _states() -> void:
	_shut = Node3D.new()
	add_child(_shut)
	face(C, B)
	var a := DOOR.position
	var b := DOOR.end
	box(a.x, 0.0, -0.09, DOOR.size.x, b.y, 0.03, 0xebe9e3)
	for i in range(1, int(b.y / 0.09)):
		box(a.x, i * 0.09, -0.06, DOOR.size.x, 0.012, 0.006, 0xc9c7c0)
	box(a.x, 0.0, -0.07, DOOR.size.x, 0.08, 0.04, 0xd0cec8)
	box((a.x + b.x) / 2.0 - 0.06, 0.12, -0.055, 0.12, 0.06, 0.02, 0x8a8a86)                     # (its lock)
	home()
	_commit_to(_shut)
	_open = Node3D.new()
	add_child(_open)
	face(C, B)
	box(a.x + 0.2, b.y - 0.06, -1.2, DOOR.size.x - 0.4, 0.04, 0.5, "luz")
	var lamp := OmniLight3D.new()
	lamp.position = _xf * Vector3((a.x + b.x) / 2.0, 2.2, -1.4)
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
	if maniqui != null:                 # (out only while it is open, as the MaxiPrecio's)
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
