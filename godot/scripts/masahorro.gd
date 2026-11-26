extends "res://scripts/obra.gd"
## The MasAhorro (the user's name for the supermarket of the Calle de las Viñas, 17 November 2026: "Intenta empezar por
## el Ahorramás ahora (que llamaremos MasAhorro) intenta fijarte más en los detalles como en la entrada ahora"): the
## long shed at the corner of the Calle de la Noria, its front of mustard panels over the car park, its sides of grey
## sheet. Built by hand from Street View (November 2024: the Noria on its east, the Calle de las Viñas over its car
## park, the lane on its south), the orthophoto (PNOA) and Catastro (4286902VJ5648N: a shop of 1999, one floor).
## Measured: referencias/masahorro/LEEME.md, tools/masahorro/.
##
## The front: panels of mustard yellow in a grid, the name in raised letters (our own lettering, not the chain's); a
## long canopy of cream over the way in, the glass between a cream pier and a cream wall, two automatic doors; a
## raised walk with bollards, bicycles, bins, steps at its end; the blue bays before it. The side on the Noria: grey
## sheet over a black band, its service door, its lamps; the yellow wrapping round the corner. Behind, on the lane:
## the old cladding, yellow over white, the loading door under a canopy of steel, the plant room with its fans and its
## ducts behind a slatted rail. On the roof: the solar panels. The car park: its bays, the trolleys' shelter on its
## island, the chargers for electric cars, its tall lamps, the railings, signs and the bin for old clothes at its way
## in from the Viñas. Behind the glass, the tills and the shelves, lit while it is open.
##
## Frame: origin at the north-east corner of the front (the corner of the Noria), +x along the front to the north-west
## corner, +z out of it (north, over the car park); the shop runs back to z = -LONG. y = 0 is its floor, the raised walk
## before its doors. (Catastro puts the corner at 53.45, 518.01; the shop stands about 1.5 m nearer the Noria and 1 m
## further north: the depth of its pavement from Street View, and the orthophoto.)

const READY := true                 # (tools/bake_godot.py: Catastro's block is not raised while this is true)
const CarS = preload("res://scripts/car.gd")
const MAKES := ["panda", "panda", "panda", "cuatrolatas", "cuatrolatas", "z15", "z15", "z15", "edison", "julietta", "tunero"]
const UNSEEN := 40.0                # cars come and go where you are not looking
const NAME := "MasAhorro"
const DIR := "res://assets/masahorro/"
const O := Vector2(55.3, 517.0)
const U := Vector2(-0.94735, -0.32034)   # along the front, from the corner of the Noria to the other
const WIDE := 29.5                  # the front
const LONG := 54.0                  # the shed, back to its south wall (the plant room and the loading canopy beyond)
const TALL := 6.9                   # the top of the yellow front
const SIDE := 6.35                  # the top of the side walls
const WRAP := 3.6                   # the yellow, round the corner on to the side of the Noria...
const PROUD := 0.25                 # ...standing this far out of it
const CAN0 := 8.07                  # the canopy over the way in: from here along the front...
const CAN1 := 29.07                 # ...to here (the yellow pier at the end)
const CAN_OUT := 2.0                # how far out it comes (from Street View: its ceiling hardly shows)
const RAMP := 8.0                   # the walk slopes down to the Noria's pavement east of here
const CAN_Y0 := 3.1                 # its underside...
const CAN_Y1 := 3.85                # ...and its top
const GL0 := 9.44                   # the glass: from the cream pier...
const GL1 := 24.09                  # ...to the cream wall
const SHOP := -0.45                 # the glass's plane, behind the yellow
const LOGO := [9.08, 19.72, 4.85]   # the name: from, to, its foot
const WALK := 4.0                   # the raised walk before the front
const DOWN := -3.0
const BAYS_W := 2.45                # a bay, along its row
const PARK_LAMPS := [Vector2(15.8, 26.0), Vector2(15.8, 58.0), Vector2(32.0, 33.0), Vector2(-3.7, 30.0), Vector2(-3.7, 58.0)]   # the car park's tall lamps (this frame)
const ANNEX := [18.5, 29.5, 5.0]    # the plant room behind: from, to (along the back), how far out
const DOCK := [8.5, 18.5]           # the loading canopy, beside it
const OPENS := 9.0                  # its hours (the user, 17 November 2026: Monday to Saturday 9:00 to 21:30, Sunday shut;
                                    # the plate at the car park's way in says the same)
const SHUTS := 21.5
const YELLOW := 0xd6a026
const CREAM := 0xe9dfc8
const STEEL := 0x4a4f55
const BLACK := 0x1d1e20
const PAINT := 0xf0f0ea

var door: Vector2                   # before its doors, on the map (the self-test, missions)
var is_open := true
var lamps: Array = []               # the car park's lamps, in the world
var outline: PackedVector2Array     # the shop and its plant room, on the map
var bays := 0                       # how many bays its car park has painted
var trolleys := 0
var vinas: Array = []               # the Calle de las Viñas's stretches (where the car park ends)
var bay_spots: Array = []           # the bays cars are parked in: [the end its nose goes to (this frame), its way in, a charger's]
var parked: Array = []              # the cars parked in them while it is open: {car, at}
var _cars_t := 0.0
var _letters: Array = []            # the name's two quads: [face, lit]

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"amarillo":         # the composite panels of the front: one panel of the picture is one of them
			var am := StandardMaterial3D.new()
			am.albedo_texture = load(DIR + "panel.png")
			am.uv1_triplanar = true
			am.uv1_scale = Vector3(1.0 / 2.95, 1.0 / 0.97, 1.0 / 2.95)
			am.uv1_triplanar_sharpness = 8.0
			am.roughness = 0.55
			am.metallic_specular = 0.35
			am.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			m = am
		"gris", "claro", "oscuro", "chapa_am", "chapa_bl":
			var hex: int = {"gris": 0x9b9fa4, "claro": 0xe2e4e6, "oscuro": 0x34373a, "chapa_am": 0xe3b742, "chapa_bl": 0xf1eee4}[key]
			var cm := StandardMaterial3D.new()
			cm.albedo_texture = load(DIR + "chapa.png")
			cm.albedo_color = Parts.col(hex)
			cm.uv1_triplanar = true
			cm.uv1_scale = Vector3.ONE
			cm.uv1_triplanar_sharpness = 8.0
			cm.roughness = 0.6
			cm.metallic_specular = 0.4
			if key == "chapa_bl" or key == "claro":
				_glow(cm, 0.12)
				cm.emission_texture = cm.albedo_texture
			m = cm
		"crema":
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.95, 0.84)), 0.2)
		"hormigon":
			m = Tex.mat("granular_concrete", Color(0.85, 0.84, 0.8))
		"asfalto":
			m = W._tmat(0x6a686e, "asphalt", 3.0)
		"acera":
			m = W._tmat(0xd2cdc2, "pavement", 2.0)
		"cristal":
			var gm := StandardMaterial3D.new()
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.albedo_color = Color(0.13, 0.16, 0.17, 0.64)
			gm.roughness = 0.12
			gm.metallic_specular = 0.7
			gm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = gm
		"vidrio":           # the clear sides of the trolleys' shelter
			var vm := StandardMaterial3D.new()
			vm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			vm.albedo_color = Color(0.85, 0.9, 0.92, 0.25)
			vm.roughness = 0.2
			vm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = vm
		"rotulo", "rotulo_sombra", "marquesina", "parking", "horario", "ropa", "minusvalido":
			var tm := StandardMaterial3D.new()
			tm.albedo_texture = load(DIR + String(key) + ".png")
			if key in ["rotulo", "minusvalido"]:
				tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				tm.alpha_scissor_threshold = 0.5
			elif key == "rotulo_sombra":
				tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			tm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			tm.roughness = 0.6
			if key == "rotulo":     # (at night, while it is open, the letters are lit from inside)
				tm.emission_enabled = true
				tm.emission_texture = load(DIR + "rotulo_luz.png")
				tm.emission = Color.WHITE
				tm.emission_energy_multiplier = 0.0
			m = tm
		"placas":
			var pm := StandardMaterial3D.new()
			pm.albedo_texture = load(DIR + "placas.png")
			pm.roughness = 0.25
			pm.metallic_specular = 0.6
			m = pm
		"luz":              # the lights in the ceilings, under the canopy and inside
			var lm := StandardMaterial3D.new()
			lm.albedo_color = Color(1.0, 0.98, 0.93)
			lm.emission_enabled = true
			lm.emission = Color(1.0, 0.97, 0.9)
			lm.emission_energy_multiplier = 1.6
			m = lm
		"sala":             # inside: the walls and the ceiling, lit
			var sm := StandardMaterial3D.new()
			sm.albedo_color = Color(0.74, 0.74, 0.72)
			sm.emission_enabled = true
			sm.emission = Color(0.96, 0.96, 0.93)
			sm.emission_energy_multiplier = 0.16
			m = sm
		"suelo":            # inside: its floor of pale tiles
			var fm := StandardMaterial3D.new()
			fm.albedo_color = Color(0.7, 0.69, 0.66)
			fm.emission_enabled = true
			fm.emission = Color(0.86, 0.85, 0.82)
			fm.emission_energy_multiplier = 0.1
			m = fm
		"foco":
			var fo := StandardMaterial3D.new()
			fo.albedo_color = Color(1.0, 0.98, 0.92)
			fo.emission_enabled = true
			fo.emission = Color(1.0, 0.96, 0.86)
			fo.emission_energy_multiplier = 1.5
			m = fo
		"pantalla":
			var pa := StandardMaterial3D.new()
			pa.albedo_color = Color(0.25, 0.55, 0.3)
			pa.emission_enabled = true
			pa.emission = Color(0.3, 0.8, 0.4)
			pa.emission_energy_multiplier = 0.8
			m = pa
		"seto":
			m = W._tmat(0x3d6634, "leaf", 1.1)
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	_frame(0.0)
	var top := -1e9
	for x in [10.0, 13.0, 16.0, 19.0, 22.0, 25.0, 28.0]:          # its floor: the walk before its doors, level with the car park's highest
		top = maxf(top, MapData.height(spot(x, WALK + 0.3)))
	_frame(top + 0.14)
	level = top + 0.14
	W.add_child(self)
	for s in MapData.segs:
		if String(s.road["n"]) == "Calle de las Viñas":
			vinas.append(s)
	door = spot(12.5, 2.0)
	_front()
	_shopfront()
	_inside()
	_noria_side()
	_back()
	_west_side()
	_roof()
	_annex()
	_dock()
	_walk()
	_park()
	_shelter()
	_chargers()
	_park_lamps()
	_way_in()
	_gate()
	home()
	_commit()
	_tell_map()
	set_open(open_at(0, 12.0))

func _frame(y: float) -> void:
	transform = Transform3D(Basis(Vector3(U.x, 0, U.y), Vector3.UP, Vector3(-U.y, 0, U.x)), Vector3(O.x, y, O.y))

# ---------------- helpers ----------------
## a spot of the map in this frame (x, z)
func _fr(p: Vector2) -> Vector2:
	var r := p - O
	return Vector2(r.dot(U), r.dot(Vector2(-U.y, U.x)))

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

## a flat piece of this outline (in this frame) laid on the ground `lift` over it, cut along the relief's facets
func _lay(poly: PackedVector2Array, lift: float, key) -> void:
	if poly.size() < 3:
		return
	pieces += 1
	var keep := _xf
	home()
	var mp := PackedVector2Array()
	for q in poly:
		mp.append(spot(q.x, q.y))
	mp = _ccw(mp)
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
	var f := _fr(m)
	return Vector3(f.x, MapData.height(m) - level + lift, f.y)

## a painted line (or any strip) on the ground, from a to b (this frame), w wide
func _strip(a: Vector2, b: Vector2, w: float, lift: float, key) -> void:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x) * w / 2.0
	_lay(PackedVector2Array([a - n, b - n, b + n, a + n]), lift, key)

func _rect(x0: float, z0: float, x1: float, z1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)])

## the ground under a stretch of this frame, its lowest
func _low(a: Vector2, b: Vector2) -> float:
	var y := 1e9
	for k in range(9):
		var q := a.lerp(b, k / 8.0)
		y = minf(y, ground(q.x, q.y))
	return y

## a round pipe from a to b (with `caps`, shut at both ends: a disc, if short)
func _pipe(a: Vector3, b: Vector3, r: float, key, sides := 10, caps := false) -> void:
	pieces += 1
	var ax := (b - a).normalized()
	var up := Vector3.UP if absf(ax.y) < 0.9 else Vector3.RIGHT
	var s := ax.cross(up).normalized()
	var t := s.cross(ax).normalized()
	for i in range(sides):
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var o0 := (s * cos(a0) + t * sin(a0)) * r
		var o1 := (s * cos(a1) + t * sin(a1)) * r
		quad(a + o0, b + o0, b + o1, a + o1, key, (o0 + o1).normalized())
		if caps:
			tri(a, a + o0, a + o1, key, -ax)
			tri(b, b + o0, b + o1, key, ax)

## a flat picture standing on the plane z of the frame being built (x0..x1, y0..y1), facing +z
func _picture(x0: float, x1: float, y0: float, y1: float, z: float, key) -> void:
	pieces += 1
	quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

## a solid in this frame, square to it
func _solid(x0: float, y0: float, z0: float, x1: float, y1: float, z1: float) -> void:
	solid(Vector3((x0 + x1) / 2.0, (y0 + y1) / 2.0, (z0 + z1) / 2.0), Vector3(absf(x1 - x0), absf(y1 - y0), absf(z1 - z0)))

## how far out of the back (south) the ground is free at a spot along it before the lane's asphalt (at most `most`)
func _room_south(x: float, most: float) -> float:
	var d := 0.0
	while d < most:
		var p := spot(x, -LONG - d - 0.1)
		var e: float = MapData.road_edge_dist(p)
		if MapData.road_hit != null:
			e += MapData.road_hit.hw - MapData.fitted_hw(MapData.road_hit)
		if e < 0.45:
			break
		d += 0.1
	return d

## where the car park ends at x: the Calle de las Viñas's pavement
func _north_end(x: float) -> float:
	var z := 55.0
	while z < 100.0:
		var p := spot(x, z)
		for s in vinas:
			if MapData.seg_point(s, p).distance_to(p) - float(s.hw) < 3.0:
				return z
		z += 0.25
	return z

# ---------------- the shop ----------------
## The front: the mustard panels over its whole width and round the corner of the Noria, the name on them.
func _front() -> void:
	home()
	box(-PROUD, CAN_Y0, -0.3, WIDE + PROUD, TALL - CAN_Y0, 0.3, "amarillo")              # over the canopy, the whole front
	box(-PROUD, DOWN, -0.3, CAN0 + PROUD, CAN_Y0 - DOWN, 0.3, "amarillo")               # under it, the blank east part...
	box(CAN1, DOWN, -0.3, WIDE - CAN1, CAN_Y0 - DOWN, 0.3, "amarillo")                  # ...and the pier at the west end
	box(-PROUD, DOWN, -WRAP, PROUD + 0.05, TALL - DOWN, WRAP - 0.3, "amarillo")          # round the corner, standing out of the side
	box(-PROUD - 0.02, TALL, -WRAP - 0.02, WIDE + PROUD + 0.02, 0.06, WRAP + 0.04, 0xbdb8ac)    # its coping
	_solid(-PROUD, -1.0, -WRAP, WIDE, TALL, 0.0)
	# the name, in raised letters with their shadow behind them
	var h: float = (LOGO[1] - LOGO[0]) * 320.0 / 1963.0
	_picture(LOGO[0] + 0.07, LOGO[1] + 0.07, LOGO[2] - 0.08, LOGO[2] + h - 0.08, 0.015, "rotulo_sombra")
	_picture(LOGO[0], LOGO[1], LOGO[2], LOGO[2] + h, 0.1, "rotulo")
	for x in [LOGO[0] + 1.0, (LOGO[0] + LOGO[1]) / 2.0, LOGO[1] - 1.0]:               # (the letters' brackets, seen edge-on)
		box(x, LOGO[2] + h * 0.45, 0.0, 0.04, 0.04, 0.1, 0x8a8a86)
	# a floodlight at each top corner, a black box and two stickers by the corner
	for x in [0.6, WIDE - 0.6]:
		box(x - 0.2, TALL - 0.45, 0.0, 0.4, 0.06, 0.35, 0x3a3c3f)
		box(x - 0.18, TALL - 0.62, 0.25, 0.36, 0.2, 0.08, 0x2e3033)
		box(x - 0.15, TALL - 0.6, 0.33, 0.3, 0.15, 0.01, "foco")
	box(1.2, 1.0, 0.0, 0.35, 0.45, 0.16, BLACK)
	box(1.24, 1.38, 0.16, 0.27, 0.03, 0.01, 0x6a6c6e)
	box(0.35, 1.45, 0.0, 0.16, 0.22, 0.005, 0xf4f4f0)
	box(0.35, 1.2, 0.0, 0.16, 0.16, 0.005, 0x2c7a3a)

## Under the canopy: the cream pier, the glass with its two automatic doors, the cream wall; the canopy over them.
func _shopfront() -> void:
	home()
	box(CAN0, -0.6, -0.65, GL0 - CAN0, CAN_Y0 + 0.6, 0.5, "crema")                      # the pier (proud of the glass)
	box(GL1, -0.6, -0.65, CAN1 - GL1, CAN_Y0 + 0.6, 0.5, "crema")                        # the wall at the west end
	box(GL1 + 2.2, 0.0, -0.15, 0.6, 0.95, 0.5, BLACK)                                     # a bin before it, an ashtray
	drum(Vector3(GL1 + 1.4, 0.0, 0.3), 0.14, 0.14, 0.85, 0x4a4c4f, 10)
	# the glass: bays of 1.63 m between dark mullions, a transom, a dark band over it
	var n := 9
	var bw: float = (GL1 - GL0) / n
	box(GL0, -0.6, SHOP - 0.1, GL1 - GL0, 0.62, 0.12, 0x2f3236)                           # its sill
	_picture(GL0, GL1, 0.02, 2.55, SHOP, "cristal")
	box(GL0, 2.55, SHOP - 0.05, GL1 - GL0, CAN_Y0 - 2.55, 0.06, 0x27292c)
	box(GL0, 2.5, SHOP - 0.02, GL1 - GL0, 0.08, 0.1, 0x3b3e42)
	for i in range(n + 1):
		box(GL0 + i * bw - 0.045, 0.02, SHOP - 0.03, 0.09, 2.5, 0.12, 0x3b3e42)
	# the two automatic doors (the way in, the way out at the west end): their frames, the leaves, the sensor over them
	for k in [1, 8]:
		var x0: float = GL0 + k * bw
		box(x0 + 0.05, 0.02, SHOP + 0.02, bw - 0.1, 0.07, 0.06, 0x3b3e42)
		box(x0 + bw / 2.0 - 0.025, 0.08, SHOP + 0.03, 0.05, 2.4, 0.06, 0x3b3e42)
		box(x0 + 0.05, 2.38, SHOP + 0.02, bw - 0.1, 0.12, 0.08, 0x3b3e42)
		box(x0 + bw / 2.0 - 0.12, 2.42, SHOP + 0.1, 0.24, 0.06, 0.04, 0x1a1a1a)
		box(x0 + 0.3, 1.2, SHOP + 0.04, 0.25, 0.25, 0.004, 0xd8243a if k == 1 else 0x2c8a3a)    # their stickers
	# posters inside the glass: the week's offers
	for x in [GL0 + 3.6 * bw + 0.2, GL0 + 5.2 * bw + 0.3]:
		box(x, 0.9, SHOP - 0.06, 0.8, 1.15, 0.01, 0xf6f2e8)
		box(x + 0.05, 1.75, SHOP - 0.055, 0.7, 0.22, 0.01, 0xd8243a)
		box(x + 0.1, 1.05, SHOP - 0.055, 0.6, 0.5, 0.01, 0xf2c230)
	# the canopy: a box of cream with a pale lip, its ceiling with the lights in it
	box(CAN0, CAN_Y0, -0.3, CAN1 - CAN0, CAN_Y1 - CAN_Y0, CAN_OUT + 0.3, "crema")
	box(CAN0 - 0.02, CAN_Y0 - 0.16, CAN_OUT - 0.1, CAN1 - CAN0 + 0.04, 0.16, 0.12, "crema")          # its fascia, hanging a little
	box(CAN0 - 0.03, CAN_Y0 - 0.17, CAN_OUT + 0.01, CAN1 - CAN0 + 0.06, 0.04, 0.02, 0xf4f0e6)
	box(CAN0 - 0.02, CAN_Y1, -0.3, CAN1 - CAN0 + 0.04, 0.05, CAN_OUT + 0.32, 0xc9c3b6)
	var lx := CAN0 + 1.0
	while lx < CAN1 - 0.6:
		box(lx - 0.13, CAN_Y0 - 0.012, 0.9, 0.26, 0.012, 0.26, "luz")
		lx += 2.1
	_solid(CAN0, -1.0, -0.65, GL0, CAN_Y0, -0.15)
	_solid(GL1, -1.0, -0.65, CAN1, CAN_Y0, -0.15)
	_solid(GL0, -1.0, SHOP - 0.2, GL1, CAN_Y0, SHOP)

## Behind the glass: the tills, the shelves, the lights; the hall shut off a few metres in.
func _inside() -> void:
	home()
	var back := -13.0
	flat(_rect(GL0 - 0.5, SHOP - 0.1, GL1 + 0.5, back), 0.01, "suelo")
	box(GL0 - 0.6, 3.6, back, GL1 - GL0 + 1.2, 0.05, -back + SHOP - 0.1, "sala")          # its ceiling
	box(GL0 - 0.6, 0.0, back - 0.1, GL1 - GL0 + 1.2, 3.6, 0.1, "sala")
	for x in [GL0 - 0.6, GL1 + 0.5]:
		box(x, 0.0, back, 0.1, 3.6, -back + SHOP - 0.1, "sala")
	box(GL0 - 0.6, 3.0, back + 0.05, GL1 - GL0 + 1.2, 0.5, 0.02, 0x2c8a3a)               # the green band on its back wall
	for i in range(4):                                                                 # the lights in its ceiling
		for j in range(3):
			box(GL0 + 1.5 + i * 3.8, 3.58, -2.5 - j * 3.4, 1.2, 0.02, 0.3, "luz")
	for k in range(4):                                                                 # four tills, their belts running in
		var x: float = GL0 + 2.4 + k * 2.9
		box(x, 0.0, -5.6, 0.85, 0.9, 2.4, 0x3d4045)
		box(x + 0.05, 0.9, -5.5, 0.6, 0.02, 1.6, 0x161616)
		box(x + 0.6, 0.9, -3.5, 0.25, 0.32, 0.04, 0x1f1f22)
		box(x + 0.62, 0.95, -3.48, 0.21, 0.22, 0.005, "pantalla")
		drum(Vector3(x + 0.42, 0.9, -3.3), 0.02, 0.02, 1.1, 0x9a9da0, 6)
		box(x + 0.3, 2.0, -3.35, 0.25, 0.25, 0.04, 0x2c8a3a)                           # its number on a post
	var colours: Array = [0xd8243a, 0xf2c230, 0x2c7a3a, 0x2a5fb0, 0xeeeeea, 0xe2702a, 0x8a3a8a, 0x6a4a2a]
	var seed_ := 7
	for k in range(5):                                                                 # the shelves, aisles running in
		var x: float = GL0 + 1.2 + k * 3.0
		box(x, 0.0, back + 0.6, 1.0, 1.9, 4.6, 0xd9dadb)
		for side in [x - 0.01, x + 1.0]:
			for row in range(4):
				var z: float = back + 0.7
				while z < back + 5.1:
					seed_ = (seed_ * 1103515245 + 12345) % 2147483648
					var ln: float = 0.25 + float(seed_ % 5) * 0.1
					var deep: float = minf(ln, back + 5.1 - z)
					if deep > 0.02:                                # (the last of a shelf may have no room left: nothing there, rather than a box with no depth)
						box(side - 0.02, 0.15 + row * 0.45, z, 0.04, 0.3, deep, colours[seed_ % colours.size()])
					z += ln + 0.04
	box(GL0, 0.0, back + 0.5, 1.8, 1.0, 1.0, 0x2c7a3a)                                  # the fruit by the door
	for i in range(6):
		ball(Vector3(GL0 + 0.2 + i * 0.28, 1.05, back + 1.0), 0.12, [0xe2702a, 0xd8243a, 0x9ac23a][i % 3], 0.9, 6, 4)

## The side on the Noria: grey sheet over a black band, panels of a paler grey, the service door, vents, lamps.
func _noria_side() -> void:
	var a := Vector2(0.0, -LONG)
	var b := Vector2(0.0, -WRAP)
	var g: float = _low(a, Vector2(0.0, 0.0))
	var ln: float = face(a, b)
	var band: float = g + 1.45
	box(0.0, DOWN, -0.3, ln, band - DOWN, 0.3, "oscuro")
	box(0.0, band, -0.3, ln, SIDE - band, 0.3, "gris")
	for p in [[0.8, 4.8], [6.0, 13.6], [17.6, 23.8], [25.0, 32.4], [33.6, 40.6], [42.0, 49.4]]:    # its paler panels
		box(p[0], band + 0.15, 0.0, p[1] - p[0], SIDE - 0.9 - band - 0.15, 0.02, "claro")
	box(0.0, g - 0.25, 0.0, ln, 0.4, 0.07, "hormigon")                                  # the concrete at its foot
	box(-0.02, SIDE, -0.32, ln + 0.02, 0.08, 0.36, 0xc7cacc)                             # its flashing
	# the service door: black, two leaves, a white frame, the box of its shutter over it
	var dx := 14.6
	box(dx - 0.12, g + 0.15, 0.0, 2.04, 2.47, 0.05, 0xf2f2ee)
	box(dx, g + 0.15, 0.04, 1.8, 2.35, 0.03, BLACK)
	box(dx + 0.89, g + 0.15, 0.07, 0.02, 2.35, 0.01, 0x0c0c0c)
	box(dx - 0.16, g + 2.62, 0.0, 2.12, 0.38, 0.22, BLACK)
	box(dx + 2.1, g + 1.5, 0.0, 0.22, 0.3, 0.005, 0xf2c230)                             # a warning sticker beside it
	for v in [[47.0, 4.0], [31.0, 4.1], [12.6, 4.3]]:                                  # vents
		box(v[0], g + v[1], 0.0, 0.5, 0.5, 0.05, 0x3a3d40)
		for k in range(4):
			box(v[0] + 0.04, g + v[1] + 0.06 + k * 0.11, 0.05, 0.42, 0.04, 0.02, 0x55595d)
	for x in [8.0, 21.0, 34.0, 46.0]:                                                  # its lamps under the top
		box(x - 0.15, SIDE - 0.55, 0.0, 0.3, 0.06, 0.3, 0x3a3c3f)
		box(x - 0.14, SIDE - 0.7, 0.2, 0.28, 0.18, 0.08, 0x2e3033)
		box(x - 0.12, SIDE - 0.69, 0.28, 0.24, 0.14, 0.01, "foco")
	home()
	_solid(0.0, -1.0, -LONG, 0.4, SIDE, -WRAP)

## The back, on the lane: the old cladding, yellow over white (it reads white in the shade too).
func _back() -> void:
	var a := Vector2(WIDE, -LONG)
	var b := Vector2(0.0, -LONG)
	var g: float = _low(a, b)
	var ln: float = face(a, b)
	var line: float = g + 3.2
	box(0.0, DOWN, -0.3, ln, line - DOWN, 0.3, "chapa_bl")
	box(0.0, line, -0.3, ln, SIDE - line, 0.3, "chapa_am")
	box(0.0, g - 0.25, 0.0, ln, 0.35, 0.06, "hormigon")
	box(-0.02, SIDE, -0.32, ln + 0.04, 0.08, 0.36, 0xc7cacc)
	# under the loading canopy (DOCK, along the frame's x: here ln - x): the loading door, a door, a grille, a bench
	var dock_x := func(x: float) -> float: return ln - x
	var d0: float = dock_x.call(13.6)
	box(d0, g, 0.0, 3.7, 3.25, 0.04, 0x5e6368)                                          # the loading door
	for k in range(1, 3):
		box(d0 + k * 1.233, g, 0.04, 0.02, 3.25, 0.01, 0x4a4e52)
	box(d0 + 1.9, g + 1.0, 0.05, 0.04, 0.35, 0.04, 0xc8202a)                            # its red handle
	box(d0 - 0.12, g, 0.0, 0.12, 3.37, 0.06, 0x8a8e92)
	box(d0 + 3.7, g, 0.0, 0.12, 3.37, 0.06, 0x8a8e92)
	box(d0 - 0.12, g + 3.25, 0.0, 3.94, 0.12, 0.06, 0x8a8e92)
	var gx: float = dock_x.call(17.6)
	box(gx, g + 2.6, 0.0, 0.62, 0.62, 0.05, 0x34373a)                                   # the grille of a vent
	for k in range(5):
		box(gx + 0.05, g + 2.66 + k * 0.11, 0.05, 0.52, 0.04, 0.02, 0x55595d)
	var bx: float = dock_x.call(16.6)
	box(bx, g + 0.42, 0.25, 1.5, 0.06, 0.4, 0xd8b56a)                                   # the bench
	box(bx, g + 0.5, 0.05, 1.5, 0.35, 0.05, 0xd8b56a)
	for x in [bx + 0.1, bx + 1.32]:
		box(x, g, 0.1, 0.08, 0.45, 0.5, 0x6a6e72)
	drum(Vector3(dock_x.call(14.4), g, 0.35), 0.16, 0.16, 0.9, 0x55595d, 10)          # an ashtray bin
	var sx: float = dock_x.call(3.0)
	box(sx, g, 0.0, 0.95, 2.15, 0.04, 0x5e6368)                                         # a small door at the east end
	box(sx + 0.8, g + 1.0, 0.04, 0.05, 0.12, 0.04, 0x2a2a2a)
	home()
	_solid(0.0, -1.0, -LONG, WIDE, SIDE, -LONG + 0.4)

## The side on the houses (hardly seen): plain cladding.
func _west_side() -> void:
	var a := Vector2(WIDE, 0.0)
	var b := Vector2(WIDE, -LONG)
	var g: float = _low(a, b)
	var ln: float = face(a, b)
	box(0.3, DOWN, -0.3, ln - 0.3, g + 3.2 - DOWN, 0.3, "chapa_bl")
	box(0.3, g + 3.2, -0.3, ln - 0.3, SIDE - g - 3.2, 0.3, "chapa_am")
	box(0.3, SIDE, -0.32, ln - 0.3, 0.08, 0.36, 0xc7cacc)
	home()
	_solid(WIDE - 0.4, -1.0, -LONG, WIDE, SIDE, 0.0)

## The roof: flat, its membrane, the solar panels in rows, the plant on it.
func _roof() -> void:
	home()
	var y: float = SIDE - 0.25
	flat(_rect(0.3, -0.3, WIDE - 0.3, -LONG + 0.3), y, 0xbabdc0)
	flat(_rect(0.0, -0.3, WIDE, -WRAP), TALL - 0.05, 0xbdb8ac)                          # (the top of the deep front)
	box(0.0, y, -WRAP - 0.3, WIDE, TALL - y, 0.3, 0xc9c4b8)                              # its back, over the roof
	# the panels: rows facing south, a little tilted, in three fields (the orthophoto)
	for field in [[1.5, 11.5, -1.5, -40.0], [15.5, 24.5, -4.5, -19.5], [15.5, 24.5, -29.0, -34.5]]:
		var z: float = field[2]
		while z - 1.0 > field[3]:
			var x0: float = field[0]
			var x1: float = field[1]
			var cnt: float = round((x1 - x0) / 1.0)
			quad(Vector3(x0, y + 0.3, z - 1.0), Vector3(x1, y + 0.3, z - 1.0), Vector3(x1, y + 0.55, z), Vector3(x0, y + 0.55, z), "placas", Vector3(0, 0.97, -0.24),
				[Vector2(0, 1), Vector2(cnt, 1), Vector2(cnt, 0), Vector2(0, 0)])
			box(x0, y, z - 0.95, 0.05, 0.5, 0.05, 0x9a9da0)
			box(x1 - 0.05, y, z - 0.95, 0.05, 0.5, 0.05, 0x9a9da0)
			pieces += 1
			z -= 2.2
	# the plant: three boxes of the air conditioning, a dome of white, a duct
	for c in [[15.0, -46.5], [17.2, -46.5], [19.4, -46.5]]:
		box(c[0], y, c[1], 1.8, 1.1, 1.2, 0x9ea2a6)
		drum(Vector3(c[0] + 0.9, y + 1.1, c[1] + 0.6), 0.4, 0.4, 0.05, 0x3a3c3f, 12)
	ball(Vector3(14.5, y, -50.5), 1.2, 0xf2f2ee, 0.45, 12, 5)
	_pipe(Vector3(13.0, y + 0.6, -42.0), Vector3(13.0, y + 0.6, -52.5), 0.3, 0xc9ccd0)
	for k in range(4):                                                                  # skylights
		box(4.0 + k * 6.0, y, -45.0, 1.6, 0.25, 2.4, 0xdfe6ea)

## The plant room behind the shop, at its west end: white sheet, a slatted rail on top, the fans and the big ducts.
func _annex() -> void:
	var x0: float = ANNEX[0]
	var x1: float = ANNEX[1]
	var out: float = minf(ANNEX[2], _room_south((x0 + x1) / 2.0, ANNEX[2]))
	var z1: float = -LONG - out
	var g: float = minf(_low(Vector2(x0, z1), Vector2(x1, z1)), _low(Vector2(x0, -LONG), Vector2(x0, z1)))
	var h: float = g + 3.3
	for w in [[Vector2(x1, z1), Vector2(x0, z1)], [Vector2(x0, z1), Vector2(x0, -LONG)], [Vector2(x1, -LONG), Vector2(x1, z1)]]:
		var ln: float = face(w[0], w[1])
		box(0.0, DOWN, -0.25, ln, h - DOWN, 0.25, "chapa_bl")
		box(0.0, g - 0.2, 0.0, ln, 0.3, 0.05, "hormigon")
		box(0.0, h, -0.2, ln, 0.08, 0.22, 0xd4bc8e)                                      # the rail: its foot, its top, its slats
		box(0.0, h + 1.0, -0.2, ln, 0.07, 0.22, 0xd4bc8e)
		var s := 0.07
		while s < ln - 0.05:
			box(s, h + 0.08, -0.12, 0.05, 0.92, 0.05, 0xc9b184)
			s += 0.15
	home()
	flat(_rect(x0, -LONG, x1, z1), h, 0x9fa3a6)
	# the fans along its east edge, leaning out, and the long ducts over it
	for k in range(7):
		var c := Vector3(x0 + 0.7, h + 0.9, -LONG - 0.6 - k * (out - 1.0) / 6.0)
		_pipe(c, c + Vector3(-0.7, 0.25, 0.0), 0.45, 0xc9ccd0, 12)
		_pipe(c + Vector3(-0.66, 0.235, 0.0), c + Vector3(-0.68, 0.24, 0.0), 0.4, 0x2a2c2e, 12, true)     # (its grille, dark)
	_pipe(Vector3(x1 - 0.8, h + 1.2, -LONG - 1.2), Vector3(x0 + 1.6, h + 1.2, -LONG - 1.2), 0.42, 0xc9ccd0, 12)
	_pipe(Vector3(x1 - 1.6, h + 1.0, -LONG - 3.2), Vector3(x0 + 2.0, h + 1.0, -LONG - 3.2), 0.32, 0xc9ccd0, 12)
	for x in [x0 + 3.0, x0 + 6.5, x1 - 1.5]:
		box(x, h, -LONG - 1.4, 0.1, 1.0, 0.1, 0x8a8e92)
	_solid(x0, -1.0, z1, x1, h + 1.0, -LONG)
	outline = PackedVector2Array([spot(-PROUD, 0.0), spot(WIDE, 0.0), spot(WIDE, z1), spot(x0, z1), spot(x0, -LONG), spot(0.0, -LONG)])

## The loading canopy beside it: a roof of sheet on a frame of dark steel, on two posts and a strut; the apron under it.
func _dock() -> void:
	var x0: float = DOCK[0]
	var x1: float = DOCK[1]
	var o0: float = _room_south(x0 + 0.3, 5.0)
	var o1: float = _room_south(x1 - 0.3, 5.0)
	var g: float = _low(Vector2(x0, -LONG), Vector2(x1, -LONG))
	var y: float = g + 4.3
	home()
	var a := Vector3(x0, y, -LONG - o0)
	var b := Vector3(x1, y, -LONG - o1)
	quad(Vector3(x0, y + 0.18, -LONG), Vector3(x1, y + 0.18, -LONG), b + Vector3(0, 0.08, 0), a + Vector3(0, 0.08, 0), "chapa_am", Vector3(0, 1, 0))
	quad(Vector3(x0, y + 0.17, -LONG), Vector3(x1, y + 0.17, -LONG), b + Vector3(0, 0.07, 0), a + Vector3(0, 0.07, 0), 0x6a6e72, Vector3(0, -1, 0))
	bar(a, b, 0.14, 0.22, STEEL)                                                      # its edge beam
	bar(Vector3(x0, y, -LONG), a, 0.12, 0.2, STEEL)
	bar(Vector3(x1, y, -LONG), b, 0.12, 0.2, STEEL)
	var k := 1
	while k < 6:
		var t := k / 6.0
		bar(Vector3(lerpf(x0, x1, t), y + 0.05, -LONG), a.lerp(b, t) + Vector3(0, 0.05, 0), 0.06, 0.1, STEEL)
		k += 1
	for p in [a + Vector3(0.3, 0, 0.3), b + Vector3(-0.3, 0, 0.3)]:                  # the posts (a strut to the far one)
		var foot := Vector3(p.x, ground(p.x, p.z), p.z)
		bar(foot, Vector3(p.x, y, p.z), 0.14, 0.14, STEEL)
		solid(Vector3(p.x, foot.y + 1.0, p.z), Vector3(0.2, 2.0, 0.2))
		yard.append(spot(p.x, p.z))
	bar(Vector3(b.x - 0.3, ground(b.x, b.z) + 2.6, b.z + 0.3), Vector3(b.x - 2.2, y, -LONG - o1 * 0.4), 0.1, 0.1, STEEL)
	_lay(PackedVector2Array([Vector2(x0, -LONG), Vector2(x0, -LONG - o0), Vector2(x1, -LONG - o1), Vector2(x1, -LONG)]), 0.03, "hormigon")
	for p in [Vector2(x0 + 1.2, -LONG - o0 + 0.5), Vector2(x0 + 4.5, -LONG - lerpf(o0, o1, 0.4) + 0.5)]:     # yellow bollards
		drum(Vector3(p.x, ground(p.x, p.y), p.y), 0.09, 0.09, 1.0, 0xe8c020, 10)
		yard.append(spot(p.x, p.y))
	var w := Vector2(x0 + 6.8, -LONG - 0.6)                                            # a white post by the door
	cbox(Vector3(w.x, ground(w.x, w.y) + 0.55, w.y), Vector3(0.22, 1.1, 0.22), 0xeeeeea)

## The walk before the front: its pale paving, level before the doors and sloping down to the Noria's pavement at its
## east end (Street View: no steps at the corner), its kerb on the car park, the bollards along it, the bicycles, a bin.
var _ramp_low := 0.0                 # the walk's height at its east end (below the floor)

## how high the walk is at x along the front
func _walk_y(x: float) -> float:
	if x >= RAMP:
		return 0.0
	return lerpf(_ramp_low, 0.0, clampf((x + PROUD + 0.6) / (RAMP + PROUD + 0.6), 0.0, 1.0))

func _walk() -> void:
	home()
	var x0: float = -PROUD - 0.6
	_ramp_low = minf(0.0, maxf(ground(x0, 1.0), ground(x0, WALK - 0.5)) + 0.03)
	flat(_rect(RAMP, 0.0, WIDE, WALK), 0.0, "acera")
	quad(Vector3(x0, _ramp_low, 0.0), Vector3(RAMP, 0.0, 0.0), Vector3(RAMP, 0.0, WALK), Vector3(x0, _ramp_low, WALK), "acera", Vector3.UP)
	var kerb_low: float = _low(Vector2(x0, WALK), Vector2(WIDE, WALK))
	box(RAMP, kerb_low - 0.3, WALK - 0.15, WIDE - RAMP, -kerb_low + 0.3, 0.15, 0xb8b4aa)
	quad(Vector3(x0, kerb_low - 0.3, WALK), Vector3(RAMP, kerb_low - 0.3, WALK), Vector3(RAMP, 0.0, WALK), Vector3(x0, _ramp_low, WALK), 0xb8b4aa, Vector3(0, 0, 1))
	if _ramp_low > kerb_low - 0.25:
		box(x0, kerb_low - 0.3, -0.05, 0.1, _ramp_low - kerb_low + 0.3, WALK, 0xb8b4aa)
	# whoever walks on it: the level part, and the slope (it rises along the front, towards the doors)
	var flat_poly := PackedVector2Array([spot(RAMP, 0.0), spot(WIDE, 0.0), spot(WIDE, WALK), spot(RAMP, WALK)])
	var mid := spot((RAMP + WIDE) / 2.0, WALK / 2.0)
	var r2 := 0.0
	for q in flat_poly:
		r2 = maxf(r2, mid.distance_squared_to(q))
	MapData.decks.append({"o": mid, "poly": flat_poly, "r2": r2 + 1.0, "top": level})
	var ramp_poly := PackedVector2Array([spot(x0, 0.0), spot(RAMP, 0.0), spot(RAMP, WALK), spot(x0, WALK)])
	var rmid := spot((x0 + RAMP) / 2.0, WALK / 2.0)
	var rr2 := 0.0
	for q in ramp_poly:
		rr2 = maxf(rr2, rmid.distance_squared_to(q))
	MapData.decks.append({"o": rmid, "poly": ramp_poly, "r2": rr2 + 1.0, "top": level + _walk_y((x0 + RAMP) / 2.0), "grad": U * (-_ramp_low / (RAMP - x0))})
	# bollards along its edge, black with a pale band
	var x := 0.8
	while x < WIDE - 0.3:
		var y: float = _walk_y(x)
		drum(Vector3(x, y, WALK - 0.3), 0.07, 0.07, 0.95, BLACK, 8)
		drum(Vector3(x, y + 0.78, WALK - 0.3), 0.072, 0.072, 0.06, 0xd9d9d4, 8)
		solid(Vector3(x, y + 0.5, WALK - 0.3), Vector3(0.16, 1.0, 0.16))
		yard.append(spot(x, WALK - 0.3))
		x += 1.62
	# the bicycles' rack: five hoops by the pier
	for k in range(5):
		var hx: float = 6.0 + k * 0.42
		var hy: float = _walk_y(hx)
		bar(Vector3(hx, hy, 0.5), Vector3(hx, hy + 0.75, 0.5), 0.04, 0.04, 0x8d9195)
		bar(Vector3(hx, hy, 1.25), Vector3(hx, hy + 0.75, 1.25), 0.04, 0.04, 0x8d9195)
		bar(Vector3(hx, hy + 0.75, 0.5), Vector3(hx, hy + 0.75, 1.25), 0.04, 0.04, 0x8d9195)
	bar(Vector3(5.9, _walk_y(5.9) + 0.08, 0.5), Vector3(7.8, _walk_y(7.8) + 0.08, 0.5), 0.05, 0.05, 0x8d9195)
	bar(Vector3(5.9, _walk_y(5.9) + 0.08, 1.25), Vector3(7.8, _walk_y(7.8) + 0.08, 1.25), 0.05, 0.05, 0x8d9195)
	box(5.0, _walk_y(5.25) - 0.05, 0.1, 0.5, 1.0, 0.5, BLACK)                            # a bin by the corner

## The car park: its asphalt, its bays (the blue ones before the doors, the green ones of the chargers), its lanes'
## arrows, the crossing to the doors, the kerb along the Noria and the low wall along the houses.
func _park() -> void:
	var xs: Array = [-3.3, 0.0, 4.0, 8.2, 13.3, 18.4, 23.0, 27.8, 30.2, 32.3]
	var north: Array = []
	for x in xs:
		north.append(_north_end(x))
	var poly := PackedVector2Array([Vector2(-3.3, WALK), Vector2(WIDE, WALK), Vector2(WIDE, 0.6), Vector2(32.3, 0.6)])
	for i in range(xs.size() - 1, -1, -1):
		poly.append(Vector2(xs[i], north[i]))
	_lay(poly, 0.02, "asfalto")
	# the kerb along the Noria, with its strip of tiles
	var nz: float = north[0]
	_lay(_rect(-4.3, WALK, -3.3, nz), 0.15, "acera")
	_strip(Vector2(-3.3, WALK), Vector2(-3.3, nz), 0.12, 0.17, 0xb8b4aa)
	# the low wall along the houses: dark slate, the bays' heads painted on it in white
	for run in [[Vector2(32.3, 0.6), Vector2(32.3, north[9])]]:
		var a: Vector2 = run[0]
		var b: Vector2 = run[1]
		var g: float = minf(_low(a, b), maxf(ground(a.x, a.y), ground(b.x, b.y)) - 0.3)
		var top: float = maxf(ground(a.x, a.y), ground(b.x, b.y)) + 0.9
		var ln: float = face(a, b)
		box(0.0, g - 0.3, -0.25, ln, top - g + 0.3, 0.25, 0x3b4658)
		box(0.0, top, -0.27, ln, 0.06, 0.29, 0x8a8f96)
		if a.x == b.x:                                                                  # (at each bay's line)
			var zm: float = 12.0 if a.y < 1.0 else 40.0
			while zm < b.y - 0.2:
				var s: float = zm - a.y
				box(s - 0.04, ground(a.x, zm) + 0.05, 0.0, 0.08, top - ground(a.x, zm) - 0.15, 0.005, PAINT)
				zm += BAYS_W
		home()
		_hull([Vector3(a.x, g - 0.5, a.y), Vector3(a.x + 0.25, g - 0.5, a.y), Vector3(b.x, g - 0.5, b.y), Vector3(b.x + 0.25, g - 0.5, b.y),
			Vector3(a.x, top, a.y), Vector3(a.x + 0.25, top, a.y), Vector3(b.x, top, b.y), Vector3(b.x + 0.25, top, b.y)])
	home()
	# the bays: the row along the houses (the chargers' three at its south end, green), the double row in the middle,
	# the row along the Noria
	var rows: Array = [[27.8, 32.3, 12.0, north[7] - 1.0], [13.3, 18.4, 14.0, north[5] - 4.0], [8.2, 13.3, 14.0, north[4] - 4.0], [-3.3, 0.9, 12.0, north[1] - 2.0]]
	for r in rows:
		var x0: float = r[0]
		var x1: float = r[1]
		var z: float = r[2]
		while z + BAYS_W <= float(r[3]) + 0.01:
			if x0 == 13.3 and z > 42.0 and z < 52.5:                                    # (the trolleys' island)
				z += BAYS_W
				continue
			if x0 == 27.8 and z < 19.4:
				_lay(_rect(x0, z + 0.05, x1, z + BAYS_W - 0.05), 0.032, 0x5fae5a)
			_strip(Vector2(x0, z), Vector2(x1, z), 0.1, 0.045, PAINT)
			var dir := Vector2(-1.0 if x0 == 13.3 else 1.0, 0.0)
			var nose := Vector2(x0 if x0 == 13.3 else x1, z + BAYS_W / 2.0)
			if x0 != -3.3 and _bay_clear(nose, dir):                                  # (cars park nose in; not along the Noria, where the lane passes their tails)
				bay_spots.append([nose, dir, x0 == 27.8 and z < 19.4])
			bays += 1
			z += BAYS_W
		_strip(Vector2(x0, z), Vector2(x1, z), 0.1, 0.045, PAINT)
	_strip(Vector2(13.3, 14.0), Vector2(13.3, north[4] - 4.0), 0.1, 0.045, PAINT)      # the middle row's spine
	# the blue bays before the doors, the crossing to them
	for x0 in [5.0, 8.55, 12.1, 18.6]:
		_lay(_rect(x0, WALK, x0 + 3.45, WALK + 5.0), 0.032, 0x3a64b4)
		for xl in [x0, x0 + 3.45]:
			_strip(Vector2(xl, WALK), Vector2(xl, WALK + 5.0), 0.1, 0.045, PAINT)
		var c := Vector2(x0 + 1.72, WALK + 2.6)
		var cy: float = ground(c.x, c.y) + 0.055
		quad(Vector3(c.x - 0.75, cy, c.y + 0.75), Vector3(c.x + 0.75, cy, c.y + 0.75), Vector3(c.x + 0.75, cy, c.y - 0.75), Vector3(c.x - 0.75, cy, c.y - 0.75),
			"minusvalido", Vector3.UP, [Vector2(1, 1), Vector2(0, 1), Vector2(0, 0), Vector2(1, 0)])
		bays += 1
	var zx := 15.75
	while zx < 18.4:
		_strip(Vector2(zx, WALK + 0.2), Vector2(zx, 13.6), 0.4, 0.045, PAINT)
		zx += 0.75
	# the lanes' arrows: in down the lane by the houses, along the front, out up the lane by the Noria
	for ar in [[Vector2(23.0, 50.0), Vector2(0, -1)], [Vector2(23.0, 25.0), Vector2(0, -1)], [Vector2(20.0, 11.5), Vector2(-1, 0)], [Vector2(3.0, 11.5), Vector2(-1, 0)], [Vector2(4.5, 28.0), Vector2(0, 1)], [Vector2(4.5, 55.0), Vector2(0, 1)]]:
		_arrow(ar[0], ar[1])

func _arrow(at: Vector2, d: Vector2) -> void:
	var n := Vector2(-d.y, d.x)
	_lay(PackedVector2Array([at - d * 1.2 - n * 0.12, at + d * 0.3 - n * 0.12, at + d * 0.3 + n * 0.12, at - d * 1.2 + n * 0.12]), 0.045, PAINT)
	_lay(PackedVector2Array([at + d * 0.3 - n * 0.45, at + d * 1.1, at + d * 0.3 + n * 0.45]), 0.045, PAINT)

## The trolleys' shelter on its island in the middle row: clear sides, a roof with a yellow edge, our name on its
## side, the trolleys in two rows; a bin by it, a yellow post at the island's tip.
func _shelter() -> void:
	home()
	var r := [13.6, 43.4, 18.1, 51.6]
	_lay(_rect(r[0], r[1], r[2], r[3]), 0.14, "acera")
	var g: float = _low(Vector2(r[0], r[1]), Vector2(r[2], r[3]))
	for e in [[Vector2(r[2], r[1]), Vector2(r[0], r[1])], [Vector2(r[0], r[1]), Vector2(r[0], r[3])], [Vector2(r[0], r[3]), Vector2(r[2], r[3])], [Vector2(r[2], r[3]), Vector2(r[2], r[1])]]:
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		var ln: float = face(a, b)
		box(0.0, g - 0.2, -0.15, ln, 0.36, 0.15, 0xc9c5bc)
	home()
	var y0: float = g + 0.15
	var x0 := 14.4
	var x1 := 17.3
	var z0 := 44.3
	var z1 := 50.7
	for p in [Vector2(x0, z0), Vector2(x1, z0), Vector2(x0, z1), Vector2(x1, z1), Vector2(x0, (z0 + z1) / 2.0), Vector2(x1, (z0 + z1) / 2.0)]:
		box(p.x - 0.05, y0, p.y - 0.05, 0.1, 2.3, 0.1, 0xc9ccd0)
		yard.append(spot(p.x, p.y))
	box(x0 - 0.2, y0 + 2.3, z0 - 0.2, x1 - x0 + 0.4, 0.12, z1 - z0 + 0.4, 0xd9dcdf)
	box(x0 - 0.22, y0 + 2.27, z0 - 0.22, x1 - x0 + 0.44, 0.14, 0.04, 0xe8c020)
	box(x0 - 0.22, y0 + 2.27, z1 + 0.18, x1 - x0 + 0.44, 0.14, 0.04, 0xe8c020)
	box(x0 - 0.22, y0 + 2.27, z0 - 0.22, 0.04, 0.14, z1 - z0 + 0.44, 0xe8c020)
	box(x1 + 0.18, y0 + 2.27, z0 - 0.22, 0.04, 0.14, z1 - z0 + 0.44, 0xe8c020)
	quad(Vector3(x0, y0 + 0.2, z0), Vector3(x0, y0 + 0.2, z1), Vector3(x0, y0 + 2.2, z1), Vector3(x0, y0 + 2.2, z0), "vidrio", Vector3(-1, 0, 0))
	quad(Vector3(x1, y0 + 0.2, z0), Vector3(x1, y0 + 0.2, z1), Vector3(x1, y0 + 2.2, z1), Vector3(x1, y0 + 2.2, z0), "vidrio", Vector3(1, 0, 0))
	quad(Vector3(x0, y0 + 0.2, z1), Vector3(x1, y0 + 0.2, z1), Vector3(x1, y0 + 2.2, z1), Vector3(x0, y0 + 2.2, z1), "vidrio", Vector3(0, 0, 1))
	# our name on its sides, low
	var keep := _xf
	_xf = Transform3D(Basis(Vector3(0, 0, 1), Vector3.UP, Vector3(-1, 0, 0)), Vector3(x0 - 0.01, 0.0, z0))
	_picture(0.4, 2.6, y0 + 0.55, y0 + 1.1, 0.0, "marquesina")
	_xf = Transform3D(Basis(Vector3(0, 0, -1), Vector3.UP, Vector3(1, 0, 0)), Vector3(x1 + 0.01, 0.0, z1))
	_picture(0.4, 2.6, y0 + 0.55, y0 + 1.1, 0.0, "marquesina")
	_xf = keep
	# the trolleys, nested in two rows
	for row in [x0 + 0.75, x1 - 0.75]:
		var z := z0 + 0.6
		while z < z1 - 0.7:
			_trolley(Vector3(row, y0, z))
			z += 0.42
	_solid(x0, y0, z0, x1, y0 + 2.4, z1)
	drum(Vector3(18.6, g, 52.2), 0.25, 0.25, 0.95, BLACK, 10)                             # a bin
	drum(Vector3(16.0, g, 53.4), 0.08, 0.08, 0.9, 0xe8c020, 8)                            # a yellow post at its tip
	box(15.93, g + 0.55, 53.33, 0.14, 0.1, 0.14, 0x1d1e20)
	yard.append(spot(16.0, 53.4))

## one trolley: its yellow basket, its handle, its wheels
func _trolley(at: Vector3) -> void:
	trolleys += 1
	box(at.x - 0.27, at.y + 0.45, at.z - 0.42, 0.54, 0.42, 0.82, 0xe2b52c)
	box(at.x - 0.24, at.y + 0.5, at.z - 0.39, 0.48, 0.38, 0.76, 0xc9a028)
	bar(Vector3(at.x - 0.3, at.y + 1.0, at.z + 0.48), Vector3(at.x + 0.3, at.y + 1.0, at.z + 0.48), 0.04, 0.04, 0x2a6a3a)
	for s in [-0.22, 0.22]:
		bar(Vector3(at.x + s, at.y + 0.12, at.z - 0.35), Vector3(at.x + s, at.y + 0.45, at.z - 0.35), 0.025, 0.025, 0x8d9195)
		bar(Vector3(at.x + s, at.y + 0.12, at.z + 0.35), Vector3(at.x + s, at.y + 1.0, at.z + 0.48), 0.025, 0.025, 0x8d9195)
		box(at.x + s - 0.03, at.y, at.z - 0.38, 0.06, 0.12, 0.06, 0x1a1a1a)
		box(at.x + s - 0.03, at.y, at.z + 0.32, 0.06, 0.12, 0.06, 0x1a1a1a)

## The chargers for electric cars: two green posts against the low wall at the south end of the row along the houses.
func _chargers() -> void:
	home()
	for z in [12.0 + BAYS_W, 12.0 + 2.0 * BAYS_W]:
		var x := 32.0
		var g: float = ground(x, z)
		box(x - 0.3, g, z - 0.22, 0.3, 1.55, 0.44, 0x2f9a48)
		box(x - 0.32, g + 1.0, z - 0.16, 0.02, 0.32, 0.32, 0x1b1d1f)
		box(x - 0.325, g + 1.04, z - 0.12, 0.005, 0.24, 0.24, "pantalla")
		box(x - 0.31, g + 1.42, z - 0.2, 0.02, 0.1, 0.4, 0xf2f2ee)
		bar(Vector3(x - 0.3, g + 0.8, z + 0.15), Vector3(x - 0.55, g + 0.3, z + 0.4), 0.04, 0.04, 0x1b1d1f)
		solid(Vector3(x - 0.15, g + 0.8, z), Vector3(0.3, 1.6, 0.44))
		yard.append(spot(x - 0.15, z))

## The tall lamps of the car park: two floodlights on each (the town's: they light at night).
func _park_lamps() -> void:
	home()
	for p: Vector2 in PARK_LAMPS:
		var g: float = ground(p.x, p.y)
		var o := Vector3(p.x, g, p.y)
		drum(o - Vector3(0, 0.1, 0), 0.22, 0.22, 0.35, 0x9a9da0, 10)
		drum(o, 0.11, 0.07, 10.0, 0x9a9da0, 8)
		bar(o + Vector3(-0.6, 10.0, 0), o + Vector3(0.6, 10.0, 0), 0.08, 0.08, 0x6a6e72)
		for s in [-0.55, 0.55]:
			box(p.x + s - 0.25, g + 9.75, p.y - 0.2, 0.5, 0.22, 0.4, 0x3a3c3f)
			box(p.x + s - 0.22, g + 9.74, p.y - 0.17, 0.44, 0.01, 0.34, "foco")
		solid(o + Vector3(0, 2.0, 0), Vector3(0.3, 4.0, 0.3))
		var w: Vector3 = transform * (o + Vector3(0, 9.7, 0))
		W.lamp_spots.append(w)
		lamps.append(w)
		yard.append(spot(p.x, p.y))

## Its way in from the Calle de las Viñas: the railings (bars in crosses) along the pavement between the two openings,
## the blue P of its customers, the signs (20, no pedestrians), the plate of its hours, the bin for old clothes.
func _way_in() -> void:
	home()
	for run in [[-3.0, -0.8], [5.6, 21.0], [28.6, 32.0]]:
		var x0: float = run[0]
		var x1: float = run[1]
		var x := x0
		while x < x1 - 0.1:
			var xb: float = minf(x + 1.6, x1)
			var za: float = _north_end(x) - 0.4
			var zb: float = _north_end(xb) - 0.4
			var ga: float = ground(x, za)
			var gb: float = ground(xb, zb)
			bar(Vector3(x, ga + 0.95, za), Vector3(xb, gb + 0.95, zb), 0.05, 0.05, BLACK)
			bar(Vector3(x, ga + 0.2, za), Vector3(xb, gb + 0.2, zb), 0.04, 0.04, BLACK)
			bar(Vector3(x, ga + 0.2, za), Vector3(xb, gb + 0.95, zb), 0.025, 0.025, BLACK)
			bar(Vector3(x, ga + 0.95, za), Vector3(xb, gb + 0.2, zb), 0.025, 0.025, BLACK)
			bar(Vector3(x, ga, za), Vector3(x, ga + 1.0, za), 0.06, 0.06, BLACK)
			solid(Vector3((x + xb) / 2.0, (ga + gb) / 2.0 + 0.5, (za + zb) / 2.0), Vector3(absf(xb - x), 1.0, 0.1), atan2(-(zb - za), xb - x))
			yard.append(spot(x, za))
			x = xb
		var ze: float = _north_end(x1) - 0.4
		bar(Vector3(x1, ground(x1, ze), ze), Vector3(x1, ground(x1, ze) + 1.0, ze), 0.06, 0.06, BLACK)
	# the post of the P, beside the opening that comes in, and the post of the signs and the plate
	var pz: float = _north_end(21.4) - 0.9
	var pg: float = ground(21.4, pz)
	box(21.35, pg, pz - 0.05, 0.1, 3.4, 0.1, 0x9a9da0)
	var keep := _xf
	_xf = Transform3D(Basis(), Vector3(21.4, 0.0, pz + 0.06))
	_picture(-0.4, 0.4, pg + 2.35, pg + 3.45, 0.0, "parking")
	_xf = keep
	box(20.95, pg + 2.3, pz - 0.02, 0.9, 1.2, 0.06, 0x1b3f8a)
	yard.append(spot(21.4, pz))
	var sz: float = _north_end(20.2) - 0.9
	var sg: float = ground(20.2, sz)
	box(20.15, sg, sz - 0.04, 0.08, 2.8, 0.08, 0x9a9da0)
	for y in [2.45, 1.85]:                                                               # the 20 and the no-pedestrians: red rings on white
		_pipe(Vector3(20.2, sg + y, sz + 0.04), Vector3(20.2, sg + y, sz + 0.06), 0.3, 0xd8243a, 18, true)
		_pipe(Vector3(20.2, sg + y, sz + 0.06), Vector3(20.2, sg + y, sz + 0.07), 0.24, 0xf6f6f2, 18, true)
	_xf = Transform3D(Basis(), Vector3(20.2, 0.0, sz + 0.075))
	var twenty := _text("20", Vector3(0.0, sg + 2.45, 0.0), 64, BLACK, 0.004)
	twenty.outline_size = 0
	box(-0.03, sg + 1.72, 0.0, 0.06, 0.24, 0.005, BLACK)                                  # (the walker, crossed out)
	box(-0.07, sg + 1.95, 0.0, 0.14, 0.05, 0.005, BLACK)
	tbox(Transform3D(Basis(Vector3.BACK, 0.8) * Basis.from_scale(Vector3(0.5, 0.05, 0.01)), Vector3(0.0, sg + 1.85, 0.006)), 0xd8243a)
	_xf = Transform3D(Basis(), Vector3(20.2, 0.0, sz + 0.06))
	_picture(-0.22, 0.22, sg + 1.0, sg + 1.33, 0.0, "horario")
	_xf = keep
	yard.append(spot(20.2, sz))
	# the bin for old clothes, by the row along the houses
	var cz: float = _bin_z()
	var cg: float = ground(29.0, cz)
	box(28.3, cg, cz - 0.7, 1.4, 1.8, 1.4, 0x2f8a48)
	box(28.25, cg + 1.8, cz - 0.75, 1.5, 0.12, 1.5, 0x26723a)
	_xf = Transform3D(Basis(Vector3(-1, 0, 0), Vector3.UP, Vector3(0, 0, -1)), Vector3(29.0, 0.0, cz - 0.71))
	_picture(-0.5, 0.5, cg + 0.9, cg + 1.65, 0.0, "ropa")
	_xf = keep
	box(28.7, cg + 1.3, cz - 0.72, 0.6, 0.12, 0.02, 0x1b1d1f)
	solid(Vector3(29.0, cg + 0.9, cz), Vector3(1.4, 1.8, 1.4))
	yard.append(spot(29.0, cz))

## The grey gate at the west end of the front, into the passage between the shop and the houses.
func _gate() -> void:
	home()
	var g: float = ground(30.9, -0.3)
	box(WIDE, g, -0.4, 2.8, 2.1, 0.08, 0x5a5f64)
	for k in range(14):
		box(WIDE + 0.1 + k * 0.19, g + 2.1, -0.38, 0.04, 0.45, 0.04, 0x5a5f64)
	box(WIDE, g + 2.5, -0.4, 2.8, 0.06, 0.08, 0x5a5f64)
	box(WIDE + 2.8, g, -0.45, 0.25, 2.6, 0.25, 0xd9d4c8)
	_solid(WIDE, g, -0.45, WIDE + 2.8, g + 2.6, -0.3)

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
				rm.emission_energy_multiplier = 0.0

# ---------------- the customers' cars ----------------
## While it is open there are cars in its car park (the user, 17 November 2026: "Spawnean al menos 4 o 5 coches en el
## aparcamiento mientras abierto? Estaría bien"): five, seven at the busy hours (midday, and the evening); nose in, most
## of them near the doors, an electric one now and then at the chargers. They come and go where you are not looking;
## shut, they go. A car you take, or one pushed out of its bay, is no longer its: it stays where it is left, like any car.
func cars_wanted(hour: float) -> int:
	if not is_open:
		return 0
	return 7 if (hour >= 12.0 and hour < 14.5) or (hour >= 18.0 and hour < 21.0) else 5

## Whether a bay is clear for its customers' cars: the longest and widest of them (4.7 by 1.95 m) standing in it must not
## touch the bin for old clothes or a lamp's post. (The bin stands in the last bay of the row along the houses: a car
## put there came into the world inside its solid and was pushed down through the ground -- the full self-test, 17 Nov
## 2026, Sistemas: "julietta at 50, 439: -1.65 m off".)
func _bay_clear(nose: Vector2, dir: Vector2) -> bool:
	var f: Vector2 = nose - dir * (4.7 / 2.0 + (0.75 if nose.x > 30.0 else 0.35))
	var keep_off: Array = [[Vector2(29.0, _bin_z()), 0.75]]
	for p: Vector2 in PARK_LAMPS:
		keep_off.append([p, 0.2])
	for k in keep_off:
		var c: Vector2 = k[0]
		var r: float = k[1]
		if absf(c.x - f.x) < 4.7 / 2.0 + r and absf(c.y - f.y) < 1.95 / 2.0 + r:
			return false
	return true

## where the bin for old clothes stands along the row by the houses (this frame's z)
func _bin_z() -> float:
	return _north_end(29.0) - 2.0

## where a car of that make stands in that bay, on the map, and which way it faces
func _bay_place(bi: int, kind: String) -> Array:
	var s: Array = bay_spots[bi]
	var nose: Vector2 = s[0]
	var dir: Vector2 = s[1]
	var ln: float = float(CarS.SPECS[kind]["len"])
	var f: Vector2 = nose - dir * (ln / 2.0 + (0.75 if nose.x > 30.0 else 0.35))   # (off the low wall and its chargers)
	var md: Vector2 = U * dir.x + Vector2(-U.y, U.x) * dir.y
	return [spot(f.x, f.y), atan2(md.x, md.y)]

## a free bay, the nearer the doors the likelier (-1: none)
func _free_bay(G) -> int:
	var total := 0.0
	var free: Array = []
	for bi in range(bay_spots.size()):
		var at: Vector2 = _bay_place(bi, "z15")[0]
		if G.cars.any(func(c): return is_instance_valid(c) and c.p.distance_to(at) < 2.2):
			continue
		var w: float = 1.0 / (1.0 + float((bay_spots[bi][0] as Vector2).y) / 12.0)
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
		var ev: bool = bay_spots[bi][2]
		var kind: String = "edison" if ev else String(MAKES.pick_random())
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
	for i in range(16):
		_tend_cars(G, true)

## open: the lights inside and under the canopy on; shut: dark
func set_open(on: bool) -> void:
	is_open = on
	for q in [["luz", 1.6], ["sala", 0.16], ["suelo", 0.1], ["pantalla", 0.8]]:
		if _mats.has(q[0]):
			(_mats[q[0]] as StandardMaterial3D).emission_energy_multiplier = float(q[1]) if on else 0.0

# ---------------- what the map should know ----------------
func _tell_map() -> void:
	MapData.outlines.append(outline)
	if not MapData._wall_grid.is_empty():
		for i in range(outline.size()):
			var a: Vector2 = outline[i]
			var c: Vector2 = outline[(i + 1) % outline.size()]
			MapData._grid_add(MapData._wall_grid, a.min(c), a.max(c), [a, c])
