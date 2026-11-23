extends "res://scripts/esquina.gd"
## The optician "Óptica Corsa" of the Calle del Salvador: the real Centro Óptico Corts (the user, 23 November 2026:
## "Vamos con el centro óptico cors (que llamaremos Óptica Corsa, en C. Salvador, 5 ... Igual que Tutoq ... aquí el NPC
## será una Óptica con bata blanca y solo venderá gafas ... Se llamará Fátima Corsa"). Built by hand on Texturas's
## house of the map (salvador_5, handed over as ["obra"] in casas_calles.gd), with no rebake; referencias/optica/.
## From Street View of March 2013 (the only pictures of this stretch of the street).
##
## A house of flats in the row, a ground floor and two floors over it under a slope of old tiles:
##   - the ground floor is clad in pale grey granite as far as the flats' doorway: at the west end a pair of glasses
##     standing out on its black bracket (two thick green rings, our own), a white garage shutter, the shop's window
##     (glasses on white steps and a glass shelf before a backdrop of hexagons, three posters on the glass), and the way
##     in set back half a metre behind a granite step: the glass door in dark aluminium and a little glass case of
##     glasses on a granite foot with a black vent; over it all the long teal green board, "ÓPTICA CORSA" in white
##     capitals between two pairs of glasses (the game's own); then brick: the little maroon plate of the optician
##     (Fátima Corsa, the user's name for her), the round box of the alarm, and the flats' doorway, a wooden door of
##     two leaves under a wooden grille, deep in brick, on a granite step;
##   - the two floors over it stand out over the pavement in buff brick, on a deep moulding of brick (smooth below, a
##     row of thin teeth, courses stepping out to the sills); two wide windows on each floor in brown frames, white net
##     curtains behind, grey blinds part of the way down; between them two air conditioners one over the other and a
##     dish; a band of teeth between the floors, a framed panel between the windows of the second; a brick cornice and
##     the dark rafters of the eaves under the tiles.
## No number on it, no telephone, no social network (the game shows none). Its hidden saffron is inside, behind the eye
## chart (optica_dentro.gd; the user, 23 Nov 2026: "Visto bueno, y c"). APPROVED the same day ("Visto bueno").
##
## Its hours are the real ones (Google Maps, 23 November 2026): Monday to Friday from ten to two and from six to nine,
## Saturdays from ten to two, shut on Sundays. A card on the door's glass says so. Open: the way in clear, light inside.
## Shut: a grey shutter down over the way in, the window dim. Its inside is a set of its own (optica_dentro.gd), walked
## into by the green arrow before the door (entradas.gd); Fátima Corsa, in her white coat, is Sistemas's (fatima.gd).
##
## Frame: the map's own (x east, z south), y = 0 the pavement before the front's middle. The front is built in its own
## frame (obra.face: +x from its west end, the left seen from the street; +z out of it).

const READY := true
const HOUSE := "salvador_5"
const NAME := "Óptica Corsa"                     # what the shop is called in the game (the user, 23 Nov 2026)
const DIR := "res://assets/optica/"
const DentroS = preload("res://scripts/optica_dentro.gd")

# its outline on the map (the house salvador_5), in the ring's order: the front runs from RING[FRONT] (its east end)
# to RING[FRONT + 1] (its west end); the rest are the walls it shares and its back, 29 m deep
const RING := [Vector2(-103.4, -32.58), Vector2(-95.71, -31.01), Vector2(-95.83, -25.16), Vector2(-90.74, -24.57),
	Vector2(-91.16, -19.78), Vector2(-91.62, -19.82), Vector2(-92.16, -15.65), Vector2(-94.16, -15.56), Vector2(-94.52, -8.0),
	Vector2(-95.65, -8.0), Vector2(-95.47, -4.2), Vector2(-103.66, -3.21), Vector2(-103.69, -3.67), Vector2(-104.29, -3.63)]
const FRONT := 10

const SOFFIT := 3.3             # the underside of the floors above, which stand out over the pavement...
const OUT := 0.55               # ...this far
const MOULD := 4.15             # the top of the moulding under them (the first floor's sills)
const BAND := Vector2(6.7, 7.38)        # the band of teeth between the two floors
const TOP := 9.5                # the top of its walls, under the eaves
const EAVE := 0.5
const PITCH := 0.36
const RISE0 := 0.18             # (EAVE * PITCH: the eaves' edge level with the walls' top)
const BACK_K := 0.25            # the slope down to the back: a quarter of the front's (the house is 29 m deep)
# the ground floor, x from the front's west end (Street View 2013, measured on a straight picture of it)
const GARAGE := Rect2(0.55, 0.0, 2.04, 2.42)     # the white shutter
const WIN := Rect2(2.68, 0.74, 1.11, 1.44)       # the shop's window
const BAY := Rect2(3.97, 0.0, 1.61, 2.18)        # the way in, set back: the door and the little glass case by it
const BAY_D := 0.5
const DOOR_W := 0.74
const CASE_SILL := 0.91                          # the little glass case's granite foot
const GRANITE_END := 5.64                        # the granite stops here; brick on to the east end
const PORTAL := Rect2(6.16, 0.0, 0.96, 2.35)     # the flats' doorway
const SIGN := Rect2(0.26, 2.45, 5.36, 0.51)      # the board
# the floors above, x from their west end (the projection's)
const UP1 := [Rect2(0.62, 4.23, 2.7, 1.5), Rect2(4.45, 4.23, 2.9, 1.5)]
const UP2 := [Rect2(0.6, 7.45, 2.85, 1.25), Rect2(4.45, 7.45, 3.1, 1.25)]
const PANEL := Rect2(3.66, 7.55, 0.62, 0.95)     # the framed panel between the second floor's windows
const HOURS := {0: [Vector2(10.0, 14.0), Vector2(18.0, 21.0)], 1: [Vector2(10.0, 14.0), Vector2(18.0, 21.0)],
	2: [Vector2(10.0, 14.0), Vector2(18.0, 21.0)], 3: [Vector2(10.0, 14.0), Vector2(18.0, 21.0)],
	4: [Vector2(10.0, 14.0), Vector2(18.0, 21.0)], 5: [Vector2(10.0, 14.0)]}      # the day (0 Monday ... 6 Sunday) and from when to when; Sundays shut
const ALU := 0x2c2826           # the shop's dark aluminium
const FRAME := 0x5a4636         # the flats' brown window frames
const BLIND := 0xd4d4ce         # their grey blinds
const GLASS := 0x26313a
const RING_GREEN := 0x22a05e    # the glasses standing out at the west end: green faces...
const RING_SIDE := 0x1c2636     # ...on dark navy rings
const FRAMES := [0x1f1f22, 0x7a4a2a, 0xc8384a, 0x3a5a9a, 0xd8b84a, 0x2f2f36, 0x8a5a3a, 0xb8bcc0, 0x5a8a6a, 0x9a2a3a, 0x1a1a1c, 0xe8a0b0, 0x6a3a7a, 0xc0a060]

var door: Vector2                               # before the shop's door, on the pavement
var front_spot: Vector2                         # before the middle of the front, out in the street
var dentro                                      # its inside (optica_dentro.gd)
var is_open := false
var openings := 0
var _shut: Node3D
var _open: Node3D
var _lights: Array = []
var _nf: Vector2                                # the front's outward normal
var _up: Array = []                             # the outline of the floors above (they stand out over the street)
var _n := 0

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"granito":          # the pale grey granite of the ground floor (Street View 2013: about 90, 104, 115 in the street's shade)
			m = _glow(Tex.mat("granite_tile_03@1.0", Color(0.8, 0.84, 0.9)), 0.1)
		"ladrillo":         # the buff brick of the floors above (about 150, 136, 118 in the sun)
			m = _glow(Tex.mat("brick_wall_09@1.0", Color(1.0, 1.08, 1.16)), 0.06)
		"ladrillo_bajo":    # the warmer brick round the flats' doorway (about 165, 115, 90)
			m = _glow(Tex.mat("brick_wall_09@1.0", Color(1.0, 0.94, 0.94)), 0.08)
		"losa":             # the underside of the floors above, in their shade
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.74, 0.68, 0.6)), 0.12)
		"medianera":        # what looks on to its neighbours and the plots behind
			m = Tex.mat("painted_plaster_wall", Color(0.82, 0.76, 0.68))
		"tiles_optica":     # its old tiles, darker than the town's new ones (its UVs in units of 1.6 m, down the slope)
			var tm: StandardMaterial3D = Tex.mat(Tex.pick("tiles") if Tex.pick("tiles") != "" else "clay_roof_tiles_02", Color(0.78, 0.62, 0.56), true, 1.6)
			tm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = tm
		"piedra":           # the sills of the flats' windows
			m = Tex.mat("granite_tile_04@1.0", Color(0.9, 0.86, 0.8))
		"rotulo", "horario", "placa", "carteles", "fondo":
			var pm := StandardMaterial3D.new()
			pm.albedo_texture = load(DIR + String(key) + ".png")
			pm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			pm.roughness = 1.0
			pm.metallic_specular = 0.0          # (a shine picks up the sky and greys the green)
			pm.emission_enabled = true          # (the board is in the shade of the floors above)
			pm.emission_texture = pm.albedo_texture
			pm.emission = Color.WHITE
			pm.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY      # (the picture's own colours: with the default, added, a grey veil of the whole energy lies over it, and the board's green came out the colour of sage)
			pm.emission_energy_multiplier = 0.55 if key == "rotulo" else 0.3
			m = pm
		"visillo":          # the flats' white net curtains, in folds
			var img := Image.create(48, 4, false, Image.FORMAT_RGB8)
			for x in range(48):
				for y in range(4):
					img.set_pixel(x, y, Color(0.9, 0.9, 0.88) * (0.84 + 0.16 * sin(x / 48.0 * TAU * 6.0)))
			var vm := StandardMaterial3D.new()
			vm.albedo_texture = ImageTexture.create_from_image(img)
			vm.uv1_triplanar = true
			vm.uv1_scale = Vector3(1.4, 1.0, 1.4)
			vm.roughness = 1.0
			vm.emission_enabled = true
			vm.emission = Color(0.9, 0.9, 0.88)
			vm.emission_energy_multiplier = 0.08
			m = vm
		"vidrio":
			var gm := StandardMaterial3D.new()
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.albedo_color = Color(0.55, 0.68, 0.72, 0.24)
			gm.roughness = 0.12
			gm.metallic_specular = 0.7
			gm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = gm
		"interior":         # what shows through the glass: the shop behind its window and its door, darker than the street; dim when shut, lit when open
			var im := StandardMaterial3D.new()
			im.albedo_color = Color(0.42, 0.42, 0.42)
			im.roughness = 1.0
			im.emission_enabled = true
			im.emission = Color(1.0, 0.98, 0.94)
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
	var e: Vector2 = RING[FRONT]
	var w: Vector2 = RING[FRONT + 1]
	_nf = _outward(w, e)
	var mid := w.lerp(e, 0.5)
	level = MapData.height(mid + _nf * 1.0)
	transform = Transform3D(Basis.IDENTITY, Vector3(0.0, level, 0.0))
	W.add_child(self)
	var ring: Array = RING.duplicate()
	var by := []
	for i in range(ring.size()):
		by.append(-OUT if i == FRONT else 0.0)                     # (the floors above stand out over the street)
	_up = _inset(ring, by)
	wall_top = TOP
	eave_out = EAVE
	roof_pitch = PITCH
	roof_rise0 = RISE0
	var e2: Vector2 = _up[FRONT]
	var w2: Vector2 = _up[FRONT + 1]
	var nb := _outward(RING[1], RING[0])
	_planes = [[_nf, w2.dot(_nf)], [nb * BACK_K, (RING[0] as Vector2).dot(nb) * BACK_K]]      # a slope to the street, a long low one to the back
	var rby := []
	for i in range(ring.size()):
		rby.append(-EAVE if i == FRONT else 0.0)
	_ground_floor(w, e)
	_upper(w2, e2)
	home()
	_flat_down(PackedVector2Array([e, w, w2, e2]), SOFFIT, "losa")      # the underside of the floors above
	_return(e2, e)
	_return(w, w2)
	for i in range(ring.size()):
		if i != FRONT:
			_party_wall(ring[i], ring[(i + 1) % ring.size()])
	_roof_over(_up, rby, "tiles_optica")
	home()
	_commit()
	_states()
	_ring_solids(ring, 12.0)
	var dx := BAY.position.x + DOOR_W / 2.0
	door = _along(w, e, dx) + _nf * 1.2
	front_spot = mid + _nf * 2.6
	dentro = DentroS.new()                          # (its door in the way in: the arrow stands before it)
	dentro.build(world, _along(w, e, dx) + _nf * 0.5, _along(w, e, dx) + _nf * 1.9, atan2(_nf.x, _nf.y))
	set_open(open_at(0, 12.0))

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
## how high the ground is before a spot of a front (this frame's y)
func _g(a: Vector2, b: Vector2, x: float) -> float:
	var p := _along(a, b, x) + _outward(a, b) * 0.6
	return ground(p.x, p.y)

## the next colour of a frame (always the same sequence)
func _colour(shift := 0) -> int:
	_n += 1
	return FRAMES[(_n * 5 + shift * 3 + (_n / 7)) % FRAMES.size()]

## The projection's side over a neighbour's wall (or where its neighbour would be), from the floors' underside up to
## the roof's line, on the line a -> b.
func _return(a: Vector2, b: Vector2) -> void:
	var ln := face(a, b)
	pieces += 1
	quad(Vector3(0, SOFFIT, 0), Vector3(ln, SOFFIT, 0), Vector3(ln, wall_top, 0), Vector3(0, wall_top, 0), "ladrillo", Vector3(0, 0, 1))
	quad(Vector3(0, wall_top, 0), Vector3(ln, wall_top, 0), Vector3(ln, _roof_y(b) - 0.03, 0), Vector3(0, _roof_y(a) - 0.03, 0), "medianera", Vector3(0, 0, 1))
	home()

## A pair of glasses at x (its middle), its foot at y, its front at z, facing out (+z): two lenses (dark if `sun`), the
## frame round them and across, the arms going back. `s` scales it (1: a real pair, 14 cm across).
func _gafas(x: float, y: float, z: float, col: int, sun: bool, s := 1.0) -> void:
	var lw := 0.052 * s
	var lh := 0.04 * s
	var t := 0.006 * s
	for side in [-1.0, 1.0]:
		var cx: float = x + side * 0.034 * s
		box(cx - lw / 2.0, y, z - 0.004, lw, lh, 0.004, 0x202428 if sun else 0x9ab4bc)
		box(cx - lw / 2.0 - t, y + lh, z - t, lw + 2.0 * t, t * 1.6, t, col)                 # (the frame: over...
		box(cx - lw / 2.0 - t, y - t, z - t, lw + 2.0 * t, t, t, col)                          # ...under...
		box(cx + side * (lw / 2.0) - (t if side < 0.0 else 0.0), y, z - t, t, lh, t, col)     # ...and at its outer side)
		box(cx + side * (lw / 2.0 + t) - t / 2.0, y + lh * 0.7, z - 0.13 * s, t, t * 1.4, 0.13 * s, col)      # an arm, going back
	box(x - 0.012 * s, y + lh * 0.7, z - t, 0.024 * s, t, t, col)                              # the bridge

## a pair of glasses standing on a little clear stand, at x, its foot at y, z its front
func _en_soporte(x: float, y: float, z: float, col: int, sun: bool) -> void:
	box(x - 0.025, y, z - 0.09, 0.05, 0.05, 0.05, 0xdfe8ea)
	_gafas(x, y + 0.05, z, col, sun)

## a ring standing out of the frame being built along +x (its axis), its middle at c: radius r0 inside, r1 outside,
## hw half its thickness; `face_key` on its two faces, `side_key` round it
func _ring_x(c: Vector3, r0: float, r1: float, hw: float, face_key, side_key, n := 20) -> void:
	pieces += 1
	for i in range(n):
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var p0 := Vector3(0, cos(a0), sin(a0))
		var p1 := Vector3(0, cos(a1), sin(a1))
		var nm := ((p0 + p1) / 2.0).normalized()
		for s in [-1.0, 1.0]:
			var off := Vector3(s * hw, 0, 0)
			quad(c + off + p0 * r1, c + off + p1 * r1, c + off + p1 * r0, c + off + p0 * r0, face_key, Vector3(s, 0, 0))
		var l := Vector3(-hw, 0, 0)
		var r := Vector3(hw, 0, 0)
		quad(c + l + p0 * r1, c + l + p1 * r1, c + r + p1 * r1, c + r + p0 * r1, side_key, nm)
		quad(c + l + p0 * r0, c + l + p1 * r0, c + r + p1 * r0, c + r + p0 * r0, side_key, -nm)

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

# ---------------- the ground floor ----------------
func _ground_floor(a: Vector2, b: Vector2) -> void:
	var ln := face(a, b)
	var gg := _g(a, b, GARAGE.get_center().x)
	var gb := _g(a, b, BAY.get_center().x)
	var gp := _g(a, b, PORTAL.get_center().x)
	var garage := Rect2(GARAGE.position.x, gg, GARAGE.size.x, GARAGE.end.y - gg)
	var bay := Rect2(BAY.position.x, gb, BAY.size.x, BAY.end.y - gb)
	var portal := Rect2(PORTAL.position.x, gp, PORTAL.size.x, PORTAL.end.y - gp)
	masonry(0.0, GRANITE_END, -0.9, SOFFIT, [garage, WIN, bay], [], "granito")
	masonry(GRANITE_END, ln, -0.9, SOFFIT, [portal], [], "ladrillo_bajo")
	plinth(GRANITE_END, PORTAL.position.x, gp + 0.32, gp + 0.32, "granito", 0.03, -0.9)              # (a foot of granite under the brick)
	plinth(PORTAL.end.x, ln, gp + 0.32, gp + 0.32, "granito", 0.03, -0.9)
	_garage(garage)
	_escaparate(WIN)
	_bay(bay)
	_portal(portal)
	# the board: "ÓPTICA CORSA" (the game's own), on a thin pale frame
	box(SIGN.position.x - 0.02, SIGN.position.y - 0.02, 0.0, SIGN.size.x + 0.04, SIGN.size.y + 0.04, 0.05, 0xc8d6d0)
	_picture(SIGN.position.x, SIGN.end.x, SIGN.position.y, SIGN.end.y, 0.051, "rotulo")
	# the glasses standing out at the west end, on their black bracket (Street View 2013: two thick green rings)
	var hx := 0.1
	box(hx - 0.02, 2.7, 0.0, 0.04, 0.55, 0.03, 0x1a1a1c)                                            # its plate on the wall...
	bar(Vector3(hx, 3.2, 0.02), Vector3(hx, 3.2, 0.68), 0.03, 0.03, 0x1a1a1c)                       # ...its arm...
	bar(Vector3(hx, 2.82, 0.02), Vector3(hx, 3.19, 0.36), 0.025, 0.025, 0x1a1a1c)                   # ...its brace...
	for zz in [0.3, 0.6]:
		bar(Vector3(hx, 3.2, zz), Vector3(hx, 3.07, zz), 0.02, 0.02, 0x1a1a1c)                    # ...and the rods it hangs by
	_ring_x(Vector3(hx, 2.94, 0.32), 0.055, 0.12, 0.06, RING_GREEN, RING_SIDE)
	_ring_x(Vector3(hx, 2.94, 0.58), 0.055, 0.12, 0.06, RING_GREEN, RING_SIDE)
	box(hx - 0.05, 2.96, 0.43, 0.1, 0.04, 0.04, RING_SIDE)                                          # (the bridge between them)
	# on the brick: the optician's little maroon plate, the alarm's round box, a lamp over the doorway, a white box
	_picture(5.72, 6.06, 1.35, 1.59, 0.012, "placa")
	box(5.7, 1.33, 0.0, 0.38, 0.28, 0.01, 0xc8b070)
	var keep := _xf
	_xf = _xf * Transform3D(Basis(Vector3(1, 0, 0), PI / 2.0), Vector3(5.86, 3.0, 0.0))          # (its axis out of the wall)
	drum(Vector3.ZERO, 0.1, 0.09, 0.07, 0xf0f0ec, 16)
	_xf = keep
	box(5.83, 2.86, 0.0, 0.06, 0.03, 0.06, 0xc8384a)
	box(PORTAL.get_center().x - 0.08, 2.55, 0.0, 0.16, 0.1, 0.1, 0x2a2a2c)
	box(7.48, 2.78, 0.0, 0.42, 0.4, 0.24, 0xe9e9e5)
	for i in range(5):
		box(7.52, 2.82 + i * 0.07, 0.24, 0.34, 0.012, 0.008, 0x8a8c90)
	_cables(SOFFIT - 0.12, 0.0, ln)
	home()

## the white garage shutter, always down
func _garage(r: Rect2) -> void:
	openings += 1
	var z := -0.12
	box(r.position.x, r.position.y, z - 0.03, r.size.x, r.size.y, 0.03, 0xe6e2da)
	var n := int(r.size.y / 0.1)
	for i in range(1, n):
		box(r.position.x, r.position.y + i * r.size.y / n, z, r.size.x, 0.012, 0.006, 0xc4c0b8)
	box(r.position.x, r.position.y, z, r.size.x, 0.07, 0.03, 0xd0ccc4)
	box(r.get_center().x - 0.05, r.position.y + 0.5, z, 0.1, 0.06, 0.012, 0x6a6a68)               # (its lock)
	for x in [r.position.x, r.end.x - 0.04]:                                                         # its runners
		box(x, r.position.y, z - 0.02, 0.04, r.size.y, 0.06, 0xb8b6b0)

## The shop's window: dark aluminium round the glass, the three posters on it; behind, a little lit room: a backdrop of
## hexagons with glasses drawn on them, glasses on three white steps and on a glass shelf, a strip light.
func _escaparate(r: Rect2) -> void:
	openings += 1
	var z := -DEEP + 0.08
	var a := r.position
	var b := r.end
	pieces += 1
	quad(Vector3(a.x, a.y, z), Vector3(b.x, a.y, z), Vector3(b.x, b.y, z), Vector3(a.x, b.y, z), "vidrio", Vector3(0, 0, 1))
	for q in [[a.x, a.y, 0.05, r.size.y], [b.x - 0.05, a.y, 0.05, r.size.y], [a.x, a.y, r.size.x, 0.06], [a.x, b.y - 0.05, r.size.x, 0.05]]:
		box(q[0], q[1], z - 0.03, q[2], q[3], 0.05, ALU)
	_picture(a.x + 0.06, a.x + 0.06 + 0.84, b.y - 0.36, b.y - 0.08, z + 0.004, "carteles")
	var zb := -1.05
	var zf := z - 0.04
	pieces += 1
	quad(Vector3(a.x, a.y, zb), Vector3(b.x, a.y, zb), Vector3(b.x, b.y, zb), Vector3(a.x, b.y, zb), "interior", Vector3(0, 0, 1))
	_picture(a.x, b.x, a.y, b.y, zb + 0.005, "fondo")
	quad(Vector3(a.x, a.y, zb), Vector3(a.x, a.y, zf), Vector3(a.x, b.y, zf), Vector3(a.x, b.y, zb), "interior", Vector3(1, 0, 0))
	quad(Vector3(b.x, a.y, zb), Vector3(b.x, a.y, zf), Vector3(b.x, b.y, zf), Vector3(b.x, b.y, zb), "interior", Vector3(-1, 0, 0))
	quad(Vector3(a.x, a.y, zb), Vector3(b.x, a.y, zb), Vector3(b.x, a.y, zf), Vector3(a.x, a.y, zf), 0x2a2a30, Vector3.UP)
	quad(Vector3(a.x, b.y, zb), Vector3(b.x, b.y, zb), Vector3(b.x, b.y, zf), Vector3(a.x, b.y, zf), "interior", Vector3.DOWN)
	box(a.x + 0.08, b.y - 0.04, zb + 0.4, r.size.x - 0.16, 0.03, 0.08, "luz")                       # (its strip light)
	for k in range(3):                                                                                 # three white steps, glasses on each
		var top := a.y + 0.12 * (k + 1)
		var front := zb + 0.6 - k * 0.16
		box(a.x + 0.04, a.y, zb + 0.05, r.size.x - 0.08, top - a.y, front - zb - 0.05, 0xf4f4f0)
		var x := a.x + 0.14
		while x < b.x - 0.1:
			_gafas(x, top, front - 0.03, _colour(k), (k + int(x * 10.0)) % 3 == 0)
			x += 0.17
	var ys := a.y + 0.78                                                                               # a glass shelf on two chrome rods
	box(a.x + 0.05, ys, zb + 0.15, r.size.x - 0.1, 0.012, 0.32, 0xc8dce0)
	for x in [a.x + 0.08, b.x - 0.1]:
		bar(Vector3(x, a.y, zb + 0.3), Vector3(x, ys, zb + 0.3), 0.015, 0.015, 0xc0c4c8)
	var xg := a.x + 0.16
	while xg < b.x - 0.12:
		_en_soporte(xg, ys + 0.012, zb + 0.4, _colour(3), true)
		xg += 0.22

## The way in, set back behind a granite step: the glass door in dark aluminium (its hours on the glass), the little
## glass case of glasses on its granite foot with a black vent; behind the door the shop, lit when open.
func _bay(r: Rect2) -> void:
	openings += 1
	var a := r.position
	var b := r.end
	var zd := -BAY_D
	for x in [a.x, b.x]:                                                                               # its sides and head, on back from the hole's own
		quad(Vector3(x, a.y, zd), Vector3(x, a.y, -DEEP), Vector3(x, b.y, -DEEP), Vector3(x, b.y, zd), "granito", Vector3(1 if x == a.x else -1, 0, 0))
	quad(Vector3(a.x, b.y, zd), Vector3(b.x, b.y, zd), Vector3(b.x, b.y, -DEEP), Vector3(a.x, b.y, -DEEP), "granito", Vector3.DOWN)
	box(a.x - 0.02, a.y - 0.4, zd, r.size.x + 0.04, 0.48, BAY_D + 0.06, "granito")                   # the step
	var y0 := a.y + 0.08
	var dx1 := a.x + DOOR_W
	# the door
	box(a.x, y0, zd - 0.06, 0.06, 2.14 - y0, 0.06, ALU)
	box(dx1 - 0.06, y0, zd - 0.06, 0.06, 2.14 - y0, 0.06, ALU)
	box(a.x, y0, zd - 0.06, DOOR_W, 0.12, 0.06, ALU)
	box(a.x, 2.08, zd - 0.06, b.x - a.x, b.y - 2.08, 0.06, ALU)                                    # (its head, over the case too)
	pieces += 1
	quad(Vector3(a.x + 0.06, y0 + 0.12, zd - 0.03), Vector3(dx1 - 0.06, y0 + 0.12, zd - 0.03), Vector3(dx1 - 0.06, 2.08, zd - 0.03), Vector3(a.x + 0.06, 2.08, zd - 0.03), "vidrio", Vector3(0, 0, 1))
	bar(Vector3(dx1 - 0.14, 0.85, zd + 0.03), Vector3(dx1 - 0.14, 1.35, zd + 0.03), 0.025, 0.025, 0xb8bcc0)      # its handle
	_picture(a.x + 0.16, a.x + 0.43, 1.25, 1.61, zd - 0.025, "horario")
	box(a.x + 0.17, 0.72, zd - 0.027, 0.2, 0.28, 0.003, 0xf4f2ee)                                   # (a notice under it)
	var zb := zd - 2.4                                                                                 # the shop behind the door: lit when open
	pieces += 1
	var c0 := a.x + 0.06
	var c1 := dx1 - 0.06
	quad(Vector3(c0, y0, zb), Vector3(c1, y0, zb), Vector3(c1, 2.08, zb), Vector3(c0, 2.08, zb), "interior", Vector3(0, 0, 1))
	quad(Vector3(c0, y0, zb), Vector3(c0, y0, zd - 0.06), Vector3(c0, 2.08, zd - 0.06), Vector3(c0, 2.08, zb), "interior", Vector3(1, 0, 0))
	quad(Vector3(c1, y0, zb), Vector3(c1, y0, zd - 0.06), Vector3(c1, 2.08, zd - 0.06), Vector3(c1, 2.08, zb), "interior", Vector3(-1, 0, 0))
	quad(Vector3(c0, y0, zb), Vector3(c1, y0, zb), Vector3(c1, y0, zd - 0.06), Vector3(c0, y0, zd - 0.06), 0xd8d8d4, Vector3.UP)
	quad(Vector3(c0, 2.08, zb), Vector3(c1, 2.08, zb), Vector3(c1, 2.08, zd - 0.06), Vector3(c0, 2.08, zd - 0.06), "interior", Vector3.DOWN)
	box(c0, y0, zb + 0.02, c1 - c0, 1.9, 0.2, 0xf2f2ee)                                              # (a wall of glasses at the back...)
	for k in range(5):
		box(c0 + 0.04, y0 + 0.6 + k * 0.25, zb + 0.22, c1 - c0 - 0.08, 0.01, 0.1, 0xc8dce0)
		var x := c0 + 0.12
		while x < c1 - 0.08:
			_gafas(x, y0 + 0.61 + k * 0.25, zb + 0.3, _colour(k), false, 0.9)
			x += 0.16
	box(c0, y0, zb + 0.9, 0.5, 0.95, 0.5, 0x0a7060)                                                  # (...and the counter's teal end)
	# the little glass case by the door, on its granite foot
	box(dx1, y0, zd - 0.06, b.x - dx1, CASE_SILL - y0, 0.06, "granito")
	box(dx1 + (b.x - dx1) / 2.0 - 0.16, y0 + 0.18, zd, 0.32, 0.36, 0.01, 0x141416)                  # its black vent
	for k in range(6):
		box(dx1 + (b.x - dx1) / 2.0 - 0.14, y0 + 0.22 + k * 0.055, zd + 0.01, 0.28, 0.014, 0.008, 0x3a3a3c)
	box(dx1, CASE_SILL, zd - 0.06, 0.05, 2.08 - CASE_SILL, 0.06, ALU)
	box(b.x - 0.05, CASE_SILL, zd - 0.06, 0.05, 2.08 - CASE_SILL, 0.06, ALU)
	box(dx1, CASE_SILL, zd - 0.06, b.x - dx1, 0.05, 0.06, ALU)
	pieces += 1
	quad(Vector3(dx1 + 0.05, CASE_SILL + 0.05, zd - 0.03), Vector3(b.x - 0.05, CASE_SILL + 0.05, zd - 0.03), Vector3(b.x - 0.05, 2.08, zd - 0.03), Vector3(dx1 + 0.05, 2.08, zd - 0.03), "vidrio", Vector3(0, 0, 1))
	var zc := zd - 0.6
	pieces += 1
	quad(Vector3(dx1, CASE_SILL, zc), Vector3(b.x, CASE_SILL, zc), Vector3(b.x, 2.08, zc), Vector3(dx1, 2.08, zc), "interior", Vector3(0, 0, 1))
	_picture(dx1 + 0.05, b.x - 0.05, CASE_SILL + 0.3, 2.0, zc + 0.005, "fondo")
	quad(Vector3(dx1, CASE_SILL + 0.05, zc), Vector3(b.x, CASE_SILL + 0.05, zc), Vector3(b.x, CASE_SILL + 0.05, zd - 0.06), Vector3(dx1, CASE_SILL + 0.05, zd - 0.06), 0x2a2a30, Vector3.UP)
	quad(Vector3(dx1, CASE_SILL, zc), Vector3(dx1, CASE_SILL, zd - 0.06), Vector3(dx1, 2.08, zd - 0.06), Vector3(dx1, 2.08, zc), "interior", Vector3(1, 0, 0))
	quad(Vector3(b.x, CASE_SILL, zc), Vector3(b.x, CASE_SILL, zd - 0.06), Vector3(b.x, 2.08, zd - 0.06), Vector3(b.x, 2.08, zc), "interior", Vector3(-1, 0, 0))
	quad(Vector3(dx1, 2.08, zc), Vector3(b.x, 2.08, zc), Vector3(b.x, 2.08, zd - 0.06), Vector3(dx1, 2.08, zd - 0.06), "interior", Vector3.DOWN)
	box(dx1 + 0.1, 2.0, zc + 0.1, b.x - dx1 - 0.2, 0.03, 0.06, "luz")
	for k in range(3):                                                                                 # glasses on clear stands, a white box among them
		var y := CASE_SILL + 0.05 + k * 0.34
		if k > 0:
			box(dx1 + 0.06, y, zc + 0.05, b.x - dx1 - 0.12, 0.01, 0.4, 0xc8dce0)
		var x := dx1 + 0.17
		while x < b.x - 0.12:
			_en_soporte(x, y + 0.01, zc + 0.32, _colour(k + 5), k == 2)
			x += 0.2
	box(b.x - 0.32, CASE_SILL + 0.05, zc + 0.08, 0.2, 0.22, 0.2, 0xf4f4f0)

## the flats' doorway: brick reveals, a granite step, two leaves of varnished wood with their panels under a wooden
## grille, a brass knob
func _portal(r: Rect2) -> void:
	openings += 1
	var a := r.position
	var b := r.end
	var z := -DEEP
	box(a.x - 0.04, a.y - 0.4, z, r.size.x + 0.08, 0.55, DEEP + 0.1, "granito")                      # (its step)
	var y0 := a.y + 0.15
	var top := 2.13
	box(a.x, top, z, r.size.x, b.y - top, 0.03, 0x7a4a2a)                                           # the grille over it: wooden bars
	for k in range(9):
		box(a.x + 0.04 + k * (r.size.x - 0.1) / 8.0, top + 0.02, z + 0.03, 0.025, b.y - top - 0.04, 0.03, 0x5a3420)
	box(a.x, top, z + 0.03, r.size.x, 0.04, 0.04, 0x8a5532)
	var half := r.size.x / 2.0
	for s in range(2):
		var x0 := a.x + s * half
		box(x0, y0, z, half, top - y0, 0.05, 0x8a5532)
		for q in [[0.08, 0.2, 0.78], [0.08, 1.12, 0.74]]:
			box(x0 + q[0], y0 + q[1], z + 0.05, half - 0.16, q[2], 0.02, 0x7a4a2a)
	box(a.x + half - 0.01, y0, z + 0.05, 0.02, top - y0, 0.02, 0x4a2a18)
	drum(Vector3(a.x + half + 0.12, 1.1, z + 0.07), 0.03, 0.03, 0.02, 0xc8a850, 10)

# ---------------- the floors above ----------------
## The two floors over the shop, on the line from a to b (their west end first): buff brick on its deep moulding, the
## windows in brown frames with net curtains and grey blinds, the air conditioners and the dish between them, the band
## of teeth, the framed panel, the cornice and the rafters of the eaves.
func _upper(a: Vector2, b: Vector2) -> void:
	var ln := face(a, b)
	var holes: Array = []
	holes.append_array(UP1)
	holes.append_array(UP2)
	masonry(0.0, ln, SOFFIT, TOP, holes, [], "ladrillo")
	# the moulding under the first floor: a smooth band, a row of thin teeth, courses stepping out to the sills
	for c in [[SOFFIT, 3.4, 0.0], [3.4, 3.52, 0.03], [3.52, 3.58, 0.05], [3.58, 3.8, 0.0], [3.8, 3.88, 0.07], [3.88, 4.02, 0.06], [4.02, MOULD, 0.1]]:
		if float(c[2]) > 0.0:
			box(-0.0, c[0], 0.0, ln, float(c[1]) - float(c[0]), c[2], "ladrillo")
	_teeth(ln, 3.6, 3.79, 0.06, 0.055, 0.11)
	# the band between the floors
	for c in [[BAND.x, 6.78, 0.04], [6.96, 7.04, 0.06], [7.3, BAND.y, 0.08]]:
		box(0.0, c[0], 0.0, ln, float(c[1]) - float(c[0]), c[2], "ladrillo")
	_teeth(ln, 6.78, 6.96, 0.05, 0.05, 0.12)
	var downs := [0.28, 0.2, 0.45, 0.5]
	var i := 0
	for r: Rect2 in UP1 + UP2:
		_ventana(r, float(downs[i]))
		i += 1
	stone_frame(PANEL, 0.07, 0.035, "ladrillo")
	box(PANEL.position.x, PANEL.position.y, -0.03, PANEL.size.x, PANEL.size.y, 0.03, "ladrillo")
	_aires(UP1[0].end.x, UP1[1].position.x)
	cornice(0.15, ln - 0.15, TOP, true, "ladrillo", 0.6)
	_eaves(ln, 0.0, 0.0, 0.32)
	var n := maxi(2, int(round(ln / 0.19)))                                                            # the tiles' mouths along the eaves' edge
	for k in range(n):
		var xa := lerpf(0.0, ln, (k + 0.12) / n)
		var xb := lerpf(0.0, ln, (k + 0.88) / n)
		box(xa, TOP - 0.06, EAVE - 0.12, xb - xa, 0.08, 0.13, 0x6a3a2a)
	home()

## a row of thin teeth across the front, from y0 to y1, each `w` wide every `step`, standing `proud` out
func _teeth(ln: float, y0: float, y1: float, proud: float, w: float, step: float) -> void:
	var n := int(ln / step)
	for k in range(n):
		box((k + 0.5) * ln / n - w / 2.0, y0, 0.0, w, y1 - y0, proud, "ladrillo")

## A window of the flats in its hole: brown frames, four sliding leaves, white net curtains behind, its grey blind down
## `down` of it, a pale sill.
func _ventana(r: Rect2, down: float) -> void:
	openings += 1
	var z := -DEEP + 0.08
	var a := r.position
	var b := r.end
	box(a.x, a.y, z - 0.09, r.size.x, r.size.y, 0.02, GLASS)
	box(a.x + 0.04, a.y + 0.04, z - 0.06, r.size.x - 0.08, r.size.y - 0.08, 0.01, "visillo")
	for q in [[a.x, a.y, 0.06, r.size.y], [b.x - 0.06, a.y, 0.06, r.size.y], [a.x, a.y, r.size.x, 0.07], [a.x, b.y - 0.07, r.size.x, 0.07]]:
		box(q[0], q[1], z - 0.03, q[2], q[3], 0.06, FRAME)
	for k in range(1, 4):
		box(a.x + r.size.x * k / 4.0 - 0.025, a.y, z - 0.03 + (0.01 if k % 2 == 0 else 0.0), 0.05, r.size.y, 0.05, FRAME)
	if down > 0.0:
		var drop := r.size.y * down
		box(a.x + 0.02, b.y - drop, z + 0.04, r.size.x - 0.04, drop, 0.015, BLIND)
		for k in range(1, int(drop / 0.06)):
			box(a.x + 0.02, b.y - k * 0.06, z + 0.055, r.size.x - 0.04, 0.008, 0.004, 0xa8a8a2)
	box(a.x - 0.04, a.y - 0.05, -0.04, r.size.x + 0.08, 0.05, 0.09, "piedra")

## the two air conditioners on the pier between the first floor's windows, one over the other on their brackets, the
## pipes going down, and a dish over them
func _aires(x0: float, x1: float) -> void:
	var cx := (x0 + x1) / 2.0
	for q in [[4.32, false], [5.1, true]]:
		var y: float = q[0]
		box(cx - 0.4, y, 0.05, 0.8, 0.56, 0.28, 0xe9e9e5)
		if not q[1]:                                                                                   # (the fan behind its grille)
			pieces += 1
			var c := Vector3(cx + 0.12, y + 0.28, 0.331)
			for k in range(16):
				var a0 := TAU * k / 16.0
				var a1 := TAU * (k + 1) / 16.0
				tri(c, c + Vector3(cos(a0), sin(a0), 0) * 0.2, c + Vector3(cos(a1), sin(a1), 0) * 0.2, 0x3a3c40, Vector3(0, 0, 1))
			box(cx + 0.11, y + 0.08, 0.332, 0.02, 0.4, 0.004, 0xb8bcc0)
		else:
			for k in range(7):
				box(cx - 0.36, y + 0.06 + k * 0.065, 0.33, 0.72, 0.012, 0.004, 0xb0b2b4)
		for x in [cx - 0.35, cx + 0.33]:
			box(x, y - 0.03, 0.0, 0.03, 0.03, 0.36, 0x9a9c9e)
	bar(Vector3(cx - 0.3, 4.32, 0.1), Vector3(cx - 0.3, SOFFIT + 0.4, 0.06), 0.03, 0.03, 0xd8d8d4)
	bar(Vector3(cx - 0.24, 5.1, 0.1), Vector3(cx - 0.24, 4.88, 0.1), 0.025, 0.025, 0xd8d8d4)
	var dish := Vector3(cx + 0.1, 6.25, 0.32)                                                          # the dish: a shallow bowl on an arm, aimed up to the south
	bar(Vector3(cx + 0.1, 5.9, 0.0), dish, 0.03, 0.03, 0x9a9c9e)
	var keep := _xf
	_xf = _xf * Transform3D(Basis(Vector3(1, 0, 0), 1.1), dish)
	drum(Vector3.ZERO, 0.04, 0.3, 0.08, 0xdedfdc, 16)
	_xf = keep

# ---------------- open and shut ----------------
## Open: the way in clear, light inside. Shut: a grey shutter down over the way in, its lock.
func _states() -> void:
	var e: Vector2 = RING[FRONT]
	var w: Vector2 = RING[FRONT + 1]
	_shut = Node3D.new()
	add_child(_shut)
	face(w, e)
	var gb := _g(w, e, BAY.get_center().x)
	var a := Vector2(BAY.position.x, gb)
	var b := BAY.end
	box(a.x, a.y, -0.07, BAY.size.x, b.y - a.y, 0.03, 0x9a9c9e)
	for i in range(1, int((b.y - a.y) / 0.08)):
		box(a.x, a.y + i * 0.08, -0.04, BAY.size.x, 0.01, 0.005, 0x7a7c7e)
	box(a.x, a.y, -0.05, BAY.size.x, 0.07, 0.04, 0x8a8c8e)
	box(a.x + BAY.size.x / 2.0 - 0.06, a.y + 0.12, -0.035, 0.12, 0.06, 0.02, 0x5a5a58)          # (its lock)
	home()
	_commit_to(_shut)
	_open = Node3D.new()
	add_child(_open)
	face(w, e)
	box(BAY.position.x + 0.15, 2.0, -BAY_D - 1.4, 0.45, 0.04, 0.5, "luz")
	var lamp := OmniLight3D.new()
	lamp.position = _xf * Vector3(BAY.position.x + DOOR_W / 2.0, 1.9, -BAY_D - 1.2)
	lamp.light_color = Color(1.0, 0.97, 0.92)
	lamp.omni_range = 3.5
	lamp.light_energy = 0.5
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
	if _shut != null:
		_shut.visible = not on
		_open.visible = on
	for lamp in _lights:
		(lamp as Light3D).visible = on
	if _mats.has("interior"):
		(_mats["interior"] as StandardMaterial3D).emission_energy_multiplier = 0.16 if on else 0.02
	if _mats.has("luz"):
		(_mats["luz"] as StandardMaterial3D).emission_energy_multiplier = 1.6 if on else 0.15

func _process(_delta: float) -> void:
	var game = W.get_parent() if W != null else null
	if game != null and "clock" in game and "weekday" in game:
		var want: bool = open_at(int(game.weekday), float(game.clock))
		if want != is_open:
			set_open(want)
