extends "res://scripts/obra.gd"
## The Polideportivo Municipal (the user, 28 Nov 2026: "Ese es el polideportivo. Se lo pasamos a pretil", then, with
## photographs of its door and of its inside: "Quiero que se pueda acceder"): the town's sports hall east of the Calle
## de Federico Martín Bahamontes, its front on the car park. Built by hand from the IGN's orthophoto (the roof's white
## edge: OpenStreetMap's outline is 2 m off and Catastro's is a plain box of "suelo sin edificar"), Street View 2024
## from the car park, the lane on its south and the earth on its west (Texturas's twelve pictures), and the user's
## photograph of the doors, which gives the front's measures: the letters, the plate on the middle piers, the doors of
## red panels and wired glass, the windows of slats behind bars.
##
## What it is: a hall of orange brick with strong piers every half bay, under four roofs of grey sheet with broken
## gables (each rises gently from the south, turns at its ridge and drops steeply to the north: that steep side is of
## translucent sheet). The front, on the east, is stepped: the two end bays stand 2.7 m forward, each with a low block
## before it (a strip of little windows behind bars); in the recess between them the two glass doors under the raised
## letters POLIDEPORTIVO MUNICIPAL, and a concrete stair either side climbing along the wall to a landing and a high
## door in the end bay's side (the top of the stand, inside). A row of little white windows under the eaves, lamps on
## the piers, an air conditioner, yellow bicycle racks. The south and west sides are blind brick with black louvres low
## down; a white sheet door on the west; a brick hut at the south-west corner. Round it: the paved apron and the car
## park with its bays on the east, the street to the pitch on the north with the pitch's white wall and its cypresses,
## the paved walk and its trees on the south. Over the middle piers the real hall has the five rings: here it is an
## emblem of our own (a ball in a wreath).
##
## The map: Catastro's box of it is not raised once READY says so (tools/bake_godot.py, POLIDEPORTIVO_RC); the relief
## is left as it is. Its streets are the map's since 28 Nov 2026 (the user: «Calles con coches y algunos aparcados en
## el parking»; «no le falta aquí carretera? (C. Mariano Haro)»): two service roads the map's source has not got
## (the bake's EXTRA_WAYS), one with no name from the Calle Bahamontes along the north side (v -6.25) and down the
## car park's aisle (u 46.4), and the Calle Mariano Haro along the south side (v 50) from the Calle Bahamontes past
## the foot of the aisle to the Avenida de la Constitución (u 113), its two rows of trees planted here. And a third,
## the car park's second aisle (the user, of the two a street map draws: «Dibújalo»): on east from the head of the
## first to u 61, and down along the workshop's wall, slanting as it does, to the Calle Mariano Haro at u 54.5. The
## car park's asphalt goes out to that wall, as in the orthophoto (EAST: its east edge). The car park's and the north street's asphalt is still laid here, 3 cm over the map's own. Frame (u, v): u from the west wall to the east, v from the north wall to the south, from the
## hall's north-west corner (A); y = 0 the ground before its doors. The ground falls 0.6 m to the west: the walls go
## down to it.
## Its inside is a set of its own (polideportivo_dentro.gd), by the green arrow before the south door (entradas.gd).

const READY := true                 # (tools/bake_godot.py: the map leaves the plot to this script once this says so)
const DentroS = preload("res://scripts/polideportivo_dentro.gd")
const CarS = preload("res://scripts/car.gd")
const MAKES := ["panda", "panda", "panda", "cuatrolatas", "cuatrolatas", "z15", "z15", "z15", "julietta", "tunero"]
const UNSEEN := 40.0                # cars come and go where you are not looking
const EAST: Array = [Vector2(65.6, -10.5), Vector2(63.8, 6.2), Vector2(61.1, 24.9), Vector2(58.35, 43.4), Vector2(58.35, 52.0)]      # the car park's east edge, north to south: the workshop's low block, its yard, its wall (the orthophoto; 15 to 25 cm off the map's walls)
const BARE: Array = [[35.8, -10.5, 66.0, 54.2], [-29.0, -10.5, 35.8, -2.0]]      # (u0, v0, u1, v1) its own asphalt: the car park, the street on the north
const NAME := "POLIDEPORTIVO MUNICIPAL"
const A := Vector2(-42.4, -1046.4)
const EU := Vector2(0.98769, 0.15643)
const EV := Vector2(-0.15643, 0.98769)
const V: Array = [0.0, 11.4, 22.2, 33.0, 44.4]     # where each of the four roofs begins and ends, from the north
const L := 44.4                     # how long the hall is
const UR := 28.6                    # the front in the recess (the two middle bays)
const UE := 31.3                    # the front of the two end bays
const UL := 33.6                    # the front of the low blocks before them
const EAVE := 6.9                   # the top of the brick
const VALLEY := 8.1                 # the roofs' valleys (the sheet goes on up to them)
const KNEE := 9.8                   # the top of each roof's steep north side
const RIDGE := 10.4
const LAND := 3.25                  # the stairs' landings
const LOW := 3.45                   # the low blocks
const STAIR_W := 2.3
const STAIR_FOOT := 18.6            # the north stair's foot and top (v); the south one is its mirror
const STAIR_TOP := 13.7
const STEPS := 17
const DOWN := -2.5
const DIR := "res://assets/polideportivo/"
const WHITE := 0xf2f0ea
const BLACK := 0x1c1c1f
const PIPE := 0x8f969b
const RUST := 0x8e4a32
const YELLOW := 0xf0c41c

var dentro                          # its inside (polideportivo_dentro.gd)
var door: Vector2                   # before its way in, on the map
var blocks: Array = []              # the outlines of what it builds, on the map (the little map, the self-test)
var lamps: Array = []
var openings := 0                   # windows and doors
var bays := 0                       # the car park's bays
var bay_spots: Array = []           # [where the nose goes (map), which way it points (map)]
var parked: Array = []              # the cars it has parked: {"car", "at"}
var _cars_t := 0.0
var trees := 0

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"ladrillo":         # orange facing brick
			m = Tex.mat("brick_wall_003@0.9", Color(1.0, 0.9, 0.82))        # (the texture is more orange than the hall's brick: the user's photograph)
		"sardinel":         # the courses set on end
			m = Tex.mat("brick_wall_003@0.9", Color(0.92, 0.8, 0.72))
		"hormigon":
			m = Tex.mat("granular_concrete", Color(0.8, 0.8, 0.78))
		"blanco":           # the pitch's wall
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.96, 0.96, 0.93)), 0.12)
		"chapa", "traslucido":      # ribbed sheet: a rib every 30 cm, upright on the gables and down the slope on the roofs
			var base := Color(0.72, 0.75, 0.76) if String(key) == "chapa" else Color(0.84, 0.85, 0.76)
			var img := Image.create(8, 2, false, Image.FORMAT_RGB8)
			for x in range(8):
				var c := base.darkened(0.24) if x == 0 else (base.darkened(0.08) if x == 1 or x == 7 else base)
				img.set_pixel(x, 0, c)
				img.set_pixel(x, 1, c)
			img.generate_mipmaps()
			var sm := StandardMaterial3D.new()
			sm.albedo_texture = ImageTexture.create_from_image(img)
			sm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			sm.uv1_triplanar = true
			sm.uv1_scale = Vector3.ONE / 0.3
			sm.roughness = 0.55
			sm.metallic = 0.25
			m = sm
		"losa":
			m = W._tmat(0xd2ccc0, "pavement", 1.2)
		"asfalto":
			m = W._tmat(0x6f6c73, "asphalt", 3.0)
		"terraza":          # the low blocks' flat roofs, of red tile
			m = W._tmat(0xb0604a, "pavement", 0.5)
		"hoja":
			m = W._tmat(0x5f8a3e, "leaf", 1.5)
		"cipres":
			m = W._tmat(0x2f4a30, "leaf", 1.0)
		"vidrio":           # the little windows and the doors' wired glass
			var gm := StandardMaterial3D.new()
			gm.albedo_color = Color(0.42, 0.47, 0.5)
			gm.roughness = 0.3
			gm.metallic_specular = 0.5
			m = gm
		"lamas":            # the slats behind the bars
			var lm := StandardMaterial3D.new()
			lm.albedo_color = Color(0.7, 0.72, 0.72)
			lm.roughness = 0.6
			m = lm
		"foco":
			var fm := StandardMaterial3D.new()
			fm.albedo_color = Color(1.0, 0.98, 0.92)
			fm.emission_enabled = true
			fm.emission = Color(1.0, 0.96, 0.86)
			fm.emission_energy_multiplier = 1.5
			m = fm
		"emblema":          # our own emblem over the plate (tools/polideportivo/dibujos.py)
			var em := StandardMaterial3D.new()
			em.albedo_texture = load(DIR + "emblema.png")
			em.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			em.alpha_scissor_threshold = 0.5
			em.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			em.roughness = 0.7
			m = em
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	level = MapData.height(map_at(UR + 1.5, V[2]))
	transform = Transform3D(Basis(Vector3(EU.x, 0, EU.y), Vector3.UP, Vector3(EV.x, 0, EV.y)), Vector3(A.x, level, A.y))
	W.add_child(self)
	door = map_at(UR + 0.5, V[2] + 1.39)
	# Its own asphalt -- the car park with its aisle, the street on the north -- takes none of the town's random
	# furniture and no car parked at random when a game begins (world.sin_muebles: props.gd, game.gd; Sistemas, 28 Nov
	# 2026, after a bin landed in the aisle before the doors). The boxes are the map's (x, z), so each holds its strip
	# whole, turned as it is. The lane on the south has pavements of its own: it is left to the town.
	if W.get("sin_muebles") != null:
		for r in BARE:
			var zone := Rect2(map_at(r[0], r[1]), Vector2.ZERO)
			for q in [map_at(r[2], r[1]), map_at(r[2], r[3]), map_at(r[0], r[3])]:
				zone = zone.expand(q)
			W.sin_muebles.append(zone)
	_grounds()
	_nave()
	_front()
	_low(V[0], V[1])
	_low(V[3], V[4])
	_stair(false)
	_stair(true)
	_roofs()
	_hut()
	_street()
	home()
	_commit()
	dentro = DentroS.new()                          # (its door: the south one of the two; the arrow stands before it)
	dentro.build(world, map_at(UR + 0.6, V[2] + 1.39), map_at(UR + 2.0, V[2] + 1.39), atan2(EU.x, EU.y))
	dentro.open = true                              # (no hours: the user asked for a way in, and gave none)
	_tell_map()

# ---------------- the frame ----------------
## a spot of the hall (u, v) on the map
func map_at(u: float, v: float) -> Vector2:
	return A + EU * u + EV * v

## a spot of the map in the hall's frame
func to_uv(p: Vector2) -> Vector2:
	var d := p - A
	return Vector2(d.dot(EU), d.dot(EV))

# ---------------- laying things on the ground ----------------
## a flat thing lying on the ground with this outline (u, v), `lift` over it, cut along the relief's facets
func _lay(uv_pts: Array, lift: float, key) -> void:
	var wpoly := PackedVector2Array()
	for q: Vector2 in uv_pts:
		wpoly.append(map_at(q.x, q.y))
	_lay_map(wpoly, lift, key)

func _lay_map(wpoly: PackedVector2Array, lift: float, key) -> void:
	if wpoly.size() < 3:
		return
	pieces += 1
	if Geometry2D.is_polygon_clockwise(wpoly):
		wpoly.reverse()
	var bx := Rect2(wpoly[0], Vector2.ZERO)
	for q in wpoly:
		bx = bx.expand(q)
	var g: float = MapData.rg
	for i in range(int(floor((bx.position.x - MapData.rx0) / g)), int(floor((bx.end.x - MapData.rx0) / g)) + 1):
		for j in range(int(floor((bx.position.y - MapData.rz0) / g)), int(floor((bx.end.y - MapData.rz0) / g)) + 1):
			var cell := Vector2(MapData.rx0 + i * g, MapData.rz0 + j * g)
			for facet in [PackedVector2Array([cell, cell + Vector2(g, 0), cell + Vector2(g, g)]), PackedVector2Array([cell, cell + Vector2(g, g), cell + Vector2(0, g)])]:
				if Geometry2D.is_polygon_clockwise(facet):
					facet.reverse()
				for piece in Geometry2D.intersect_polygons(wpoly, facet):
					if piece.size() < 3 or Geometry2D.is_polygon_clockwise(piece):
						continue
					var idx := Geometry2D.triangulate_polygon(piece)
					for t in range(0, idx.size(), 3):
						tri(_on(piece[idx[t]], lift), _on(piece[idx[t + 1]], lift), _on(piece[idx[t + 2]], lift), key, Vector3.UP)

## a spot on the map as a point of the frame, `lift` over the ground there
func _on(w: Vector2, lift: float) -> Vector3:
	var f := to_uv(w)
	return Vector3(f.x, MapData.height(w) - level + lift, f.y)

func _rect(u0: float, v0: float, u1: float, v1: float) -> Array:
	return [Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1)]

## a line painted on the ground from a to b (u, v)
func _line(a: Vector2, b: Vector2, lift: float, w := 0.1) -> void:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x) * w / 2.0
	_lay([a - n, b - n, b + n, a + n], lift, WHITE)

# ---------------- the ground round it ----------------
func _grounds() -> void:
	_lay(_rect(-1.2, -2.0, 35.8, 47.6), 0.06, "losa")              # the pavement all round the hall, the apron before its doors
	_lay(_rect(-9.0, 36.5, -1.2, 47.6), 0.06, "losa")              # ...and round the hut
	_lay([Vector2(35.8, -10.5)] + EAST + [Vector2(35.8, 52.0)], 0.03, "asfalto")      # the car park, out to the workshop's wall
	_lay(_rect(-29.0, -10.5, 35.8, -2.0), 0.03, "asfalto")         # the street to the pitch, from the Calle Bahamontes
	_lay(_rect(-29.0, -12.0, 65.6, -10.5), 0.06, "losa")           # ...and the pavement along the pitch's wall
	var v := 0.0
	while v <= 45.01:                                               # the bays, square to the kerb
		_line(Vector2(36.0, v), Vector2(40.8, v), 0.045)
		bays += 1
		v += 2.5
	bays -= 1
	for k in range(bays):                                           # nose to the kerb, towards the hall
		bay_spots.append([map_at(36.3, 1.25 + 2.5 * k), -EU])

# ---------------- brick walls ----------------
## a pair of piers either side of x on the wall being built, a downpipe between them (or not)
func _pier_pair(x: float, top: float, pipe := true) -> void:
	box(x - 0.5, DOWN, 0.0, 0.42, top - DOWN, 0.3, "ladrillo")
	box(x + 0.08, DOWN, 0.0, 0.42, top - DOWN, 0.3, "ladrillo")
	if pipe:
		drum(Vector3(x, DOWN, 0.11), 0.05, 0.05, top - DOWN + 1.1, PIPE, 8)

## one pier, its left edge at x
func _pier(x: float, top: float, w := 0.42) -> void:
	box(x, DOWN, 0.0, w, top - DOWN, 0.3, "ladrillo")

## a little pane in its hole, a frame round it
func _pane(r: Rect2, frame, glass, fw := 0.05) -> void:
	var z := -DEEP + 0.08
	box(r.position.x, r.position.y, z - 0.03, r.size.x, r.size.y, 0.03, glass)
	box(r.position.x, r.position.y, z, fw, r.size.y, 0.03, frame)
	box(r.end.x - fw, r.position.y, z, fw, r.size.y, 0.03, frame)
	box(r.position.x + fw, r.position.y, z, r.size.x - 2.0 * fw, fw, 0.025, frame)
	box(r.position.x + fw, r.end.y - fw, z, r.size.x - 2.0 * fw, fw, 0.025, frame)
	openings += 1

## a window of grey slats in its hole, a white sill under it
func _slats(r: Rect2) -> void:
	var z := -DEEP + 0.08
	box(r.position.x, r.position.y, z - 0.03, r.size.x, r.size.y, 0.03, "lamas")
	var n := int(r.size.y / 0.09)
	for k in range(1, n):
		box(r.position.x, r.position.y + r.size.y * k / n - 0.006, z, r.size.x, 0.012, 0.012, 0x8e9292)
	box(r.position.x - 0.03, r.position.y - 0.05, -DEEP + 0.1, r.size.x + 0.06, 0.062, DEEP - 0.1 + 0.04, WHITE)      # (its top over the hole's own sill, not in its plane)
	openings += 1

## a door of the hall in its hole: black steel, red panels above and below, wired glass between
func _door(r: Rect2, leaves := 2) -> void:
	var z := -DEEP + 0.1
	box(r.position.x, r.position.y, z - 0.03, r.size.x, r.size.y, 0.03, "vidrio")
	var lw := r.size.x / leaves
	var y0 := r.position.y
	var h := r.size.y
	for k in range(leaves):
		var x := r.position.x + lw * k
		box(x, y0, z + 0.003, lw, 0.47, 0.012, RUST)              # the red panels (a hair before the frame's back)
		box(x, y0 + h - 0.5, z + 0.003, lw, 0.5, 0.012, RUST)
		for e in [x, x + lw - 0.05]:                                # the leaf's uprights
			box(e, y0, z, 0.05, h, 0.04, BLACK)
		for y in [0.0, 0.47, 0.47 + (h - 0.97) / 3.0, 0.47 + (h - 0.97) * 2.0 / 3.0, h - 0.5, h - 0.04]:      # ...and its rails
			box(x + 0.05, y0 + y, z, lw - 0.1, 0.04, 0.03, BLACK)
	openings += 1

## black louvres low down on a blind wall: two between each pair of piers
func _vents(xs: Array) -> void:
	for x: float in xs:
		var g := ground(_fspot(x + 0.8, 0.4).x, _fspot(x + 0.8, 0.4).y)
		box(x, g + 0.45, 0.0, 1.6, 0.45, 0.03, BLACK)
		for k in range(1, 5):
			box(x + 0.04, g + 0.45 + 0.09 * k, 0.03, 1.52, 0.02, 0.012, 0x34343a)

## where a spot of the wall being built (x along it, z out of it) is, in the frame (u, v)
func _fspot(x: float, z: float) -> Vector2:
	var p := _xf * Vector3(x, 0.0, z)
	return Vector2(p.x, p.z)

## the row of little white windows under the eaves, four to each half bay: the holes
func _high(ln: float, half: float) -> Array:
	var out: Array = []
	var n := int(round(ln / half))
	for h in range(n):
		for k in range(4):
			out.append(Rect2(h * half + (half - 4.1) / 2.0 + k * 1.1, 6.0, 0.8, 0.55))
	return out

func _nave() -> void:
	# the west side: blind, a white sheet door north of its middle
	var ln := face(Vector2(0, 0), Vector2(0, L))
	var gy := ground(-0.4, 19.5)
	var wd := Rect2(18.5, gy, 2.0, 2.6)
	masonry(0.0, ln, DOWN, EAVE, [wd], [], "ladrillo", "ladrillo")
	box(wd.position.x, gy, -DEEP + 0.04, 2.0, 2.6, 0.04, 0xe6e6e2)
	box(wd.position.x + 0.99, gy, -DEEP + 0.08, 0.02, 2.6, 0.01, 0xa8a8a4)
	box(wd.position.x - 0.05, gy - 0.25, 0.0, 2.1, 0.25, 0.5, "hormigon")
	openings += 1
	_pier(0.0, EAVE)
	_pier(ln - 0.42, EAVE)
	for k in range(1, 8):
		_pier_pair(L * k / 8.0, EAVE, k % 2 == 0)
	var vents: Array = []
	for k in range(8):
		if k != 3:
			vents.append(L * k / 8.0 + 0.9)
			vents.append(L * k / 8.0 + 3.05)
	_vents(vents)
	# the north and the south: blind, the sheet over the brick up to the roofs' edges
	for side in [[Vector2(UE, 0), Vector2(0, 0)], [Vector2(0, L), Vector2(UE, L)]]:
		ln = face(side[0], side[1])
		masonry(0.0, ln, DOWN, EAVE, [], [], "ladrillo", "ladrillo")
		box(-0.03, EAVE, 0.0, ln + 0.06, VALLEY - EAVE + 0.05, 0.06, "chapa")
		_pier(0.0, EAVE)
		_pier(ln - 0.42, EAVE)
		vents = []
		for k in range(1, 5):
			_pier_pair(ln * k / 5.0, EAVE, false)
		for k in range(5):
			vents.append(ln * k / 5.0 + 0.8)
			vents.append(ln * k / 5.0 + 3.5)
		_vents(vents)
	# the two end bays' fronts: the little windows under the eaves (the low blocks stand before them)
	for end in [[Vector2(UE, V[1]), Vector2(UE, V[0])], [Vector2(UE, V[4]), Vector2(UE, V[3])]]:
		ln = face(end[0], end[1])
		var ups := _high(ln, ln / 2.0)
		masonry(0.0, ln, DOWN, EAVE, ups, [], "ladrillo", "ladrillo")
		for r: Rect2 in ups:
			_pane(r, WHITE, "vidrio")
		_pier(0.0, EAVE)
		_pier(ln - 0.42, EAVE)
		_pier_pair(ln / 2.0, EAVE, false)
		_lamp(ln / 2.0, 6.3)
	# the air conditioner on the south end bay
	face(Vector2(UE, V[4]), Vector2(UE, V[3]))
	box(7.4, 5.0, 0.0, 0.9, 0.65, 0.35, 0xe2e2de)
	box(7.5, 5.08, 0.35, 0.5, 0.5, 0.012, 0x6a6e70)
	# their sides on the recess, a high door in each at the stair's landing
	for ret in [[Vector2(UR, V[1]), Vector2(UE, V[1])], [Vector2(UE, V[3]), Vector2(UR, V[3])]]:
		ln = face(ret[0], ret[1])
		var hd := Rect2((ln - 1.0) / 2.0, LAND, 1.0, 2.15)
		masonry(0.0, ln, DOWN, EAVE, [hd], [], "ladrillo", "ladrillo")
		_door(hd, 1)
		box(-0.03, EAVE, 0.0, ln + 0.06, VALLEY - EAVE + 0.05, 0.06, "chapa")
	home()
	solid(Vector3(UR / 2.0, (EAVE + DOWN) / 2.0, L / 2.0), Vector3(UR, EAVE - DOWN, L))
	for k in [0, 3]:
		solid(Vector3((UR + UE) / 2.0, (EAVE + DOWN) / 2.0, (float(V[k]) + float(V[k + 1])) / 2.0), Vector3(UE - UR, EAVE - DOWN, float(V[k + 1]) - float(V[k])))

## a street lamp on its arm, over the pier at x of the wall being built
func _lamp(x: float, y: float) -> void:
	bar(Vector3(x, y, 0.3), Vector3(x, y + 0.35, 1.2), 0.05, 0.05, PIPE)
	box(x - 0.14, y + 0.3, 1.1, 0.28, 0.1, 0.5, 0x5a5d60)
	box(x - 0.11, y + 0.285, 1.15, 0.22, 0.015, 0.4, "foco")
	var w: Vector3 = transform * (_xf * Vector3(x, y + 0.25, 1.35))
	W.lamp_spots.append(w)
	lamps.append(w)

# ---------------- the front in the recess ----------------
func _front() -> void:
	var ln := face(Vector2(UR, V[3]), Vector2(UR, V[1]))
	var c := ln / 2.0
	var doors: Array = [Rect2(c - 2.34, 0.06, 1.9, 2.44), Rect2(c + 0.44, 0.06, 1.9, 2.44)]
	var wins: Array = [Rect2(c - 5.16, 1.77, 0.95, 0.73), Rect2(c - 3.92, 1.77, 0.95, 0.73), Rect2(c + 2.97, 1.77, 0.95, 0.73), Rect2(c + 4.21, 1.77, 0.95, 0.73)]
	var ups := _high(ln, ln / 4.0)
	masonry(0.0, ln, DOWN, EAVE, doors + wins + ups, [], "ladrillo", "ladrillo")
	for r: Rect2 in ups:
		_pane(r, WHITE, "vidrio")
	for r: Rect2 in doors:
		_door(r)
		box(r.position.x - 0.15, -0.3, 0.0, r.size.x + 0.3, 0.38, 0.55, "hormigon")      # its doorstep
	for r: Rect2 in wins:
		_slats(r)
	for x in [c - 5.16, c + 2.97]:                                  # the bars over each pair of windows: lying, as in the user's photograph
		for k in range(1, 7):
			box(x - 0.04, 1.77 + 0.73 * k / 7.0 - 0.007, 0.05, 2.27, 0.014, 0.014, BLACK)
		for ux in [x - 0.04, x + 0.95, x + 1.22, x + 2.21]:
			box(ux, 1.74, 0.036, 0.02, 0.79, 0.02, BLACK)
	_pier(0.0, EAVE)
	_pier(ln - 0.42, EAVE)
	_pier_pair(ln / 4.0, EAVE, false)
	_pier_pair(c, EAVE)
	_pier_pair(ln * 0.75, EAVE, false)
	_lamp(ln / 4.0, 6.3)
	_lamp(ln * 0.75, 6.3)
	for x0 in [ln / 4.0 + 0.5, c + 0.5]:                            # the courses set on end, over the doors and under the plain wall
		for y in [2.5, 3.55]:
			box(x0, y, 0.0, ln / 4.0 - 1.0, 0.085, 0.022, "sardinel")
	# the raised letters (the user's photograph: black, 30 cm, POLIDEPORTIVO over the south door and MUNICIPAL over the north one)
	var word: Label3D = _text("POLIDEPORTIVO", Vector3(c - 2.32, 3.1, 0.035), 96, BLACK, 0.0033)
	word.outline_size = 6
	word.outline_modulate = Parts.col(BLACK)
	word = _text("MUNICIPAL", Vector3(c + 1.86, 3.1, 0.035), 96, BLACK, 0.0033)
	word.outline_size = 6
	word.outline_modulate = Parts.col(BLACK)
	# the plate on the middle piers and our emblem over it
	box(c - 0.33, 2.86, 0.3, 0.66, 0.42, 0.025, 0x35332f)
	box(c - 0.28, 2.91, 0.325, 0.56, 0.32, 0.006, 0x47443f)
	quad(Vector3(c - 0.375, 3.32, 0.315), Vector3(c + 0.375, 3.32, 0.315), Vector3(c + 0.375, 3.82, 0.315), Vector3(c - 0.375, 3.82, 0.315), "emblema", Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

# ---------------- the low blocks before the end bays ----------------
func _low(v0: float, v1: float) -> void:
	var ln := face(Vector2(UL, v1), Vector2(UL, v0))
	var holes: Array = []
	for g in range(2):
		for k in range(4):
			holes.append(Rect2(0.95 + g * 5.2 + k * 1.2, 2.3, 0.95, 0.5))
	masonry(0.0, ln, DOWN, LOW, holes, [], "ladrillo", "ladrillo")
	for r: Rect2 in holes:
		_slats(r)
	for g in range(2):
		grille(Rect2(0.95 + g * 5.2, 2.3, 4.55, 0.5), 0.08, BLACK)
	box(0.0, LOW - 0.085, 0.0, ln, 0.085, 0.022, "sardinel")
	for side in [[Vector2(UL, v0), Vector2(UE, v0)], [Vector2(UE, v1), Vector2(UL, v1)]]:
		var w := face(side[0], side[1])
		masonry(0.0, w, DOWN, LOW, [], [], "ladrillo", "ladrillo")
	home()
	flat(PackedVector2Array([Vector2(UE, v0), Vector2(UL, v0), Vector2(UL, v1), Vector2(UE, v1)]), LOW - 0.18, "terraza")
	for e in [[UE, v0 - 0.02, UL - UE + 0.02, 0.24], [UE, v1 - 0.22, UL - UE + 0.02, 0.24], [UL - 0.22, v0 + 0.22, 0.24, v1 - v0 - 0.44]]:      # the coping
		box(e[0], LOW, e[1], e[2], 0.06, e[3], "hormigon")
	solid(Vector3((UE + UL) / 2.0, (LOW + DOWN) / 2.0, (v0 + v1) / 2.0), Vector3(UL - UE, LOW - DOWN, v1 - v0))

# ---------------- the two stairs ----------------
## a stair along the recess's wall up to its landing by the end bay: the north one, or its mirror on the south
func _stair(south: bool) -> void:
	home()
	var m := func(v: float) -> float: return (L - v) if south else v
	var tread := (STAIR_FOOT - STAIR_TOP) / (STEPS - 1)
	var rise := LAND / STEPS
	var ue := UR + STAIR_W
	for k in range(STEPS - 1):
		var va: float = m.call(STAIR_FOOT - (k + 1) * tread)
		var vb: float = m.call(STAIR_FOOT - k * tread)
		var top := (k + 1) * rise
		box(UR, -0.6, minf(va, vb), STAIR_W, top - 0.05 + 0.6, tread, "ladrillo")
		box(UR - 0.01, top - 0.05, minf(va, vb) - 0.015, STAIR_W + 0.035, 0.05, tread + 0.03, "hormigon")      # (let into the wall)
	var la: float = m.call(float(V[1]))
	var lb: float = m.call(STAIR_TOP)
	box(UR, -0.6, minf(la, lb), STAIR_W, LAND - 0.05 + 0.6, absf(lb - la), "ladrillo")
	box(UR - 0.01, LAND - 0.05, minf(la, lb) - 0.015, STAIR_W + 0.035, 0.05, absf(lb - la) + 0.03, "hormigon")
	# the little window under the landing
	var wm: float = (la + lb) / 2.0
	box(ue, 1.2, wm - 0.25, 0.02, 0.75, 0.5, WHITE)
	box(ue + 0.02, 1.25, wm - 0.2, 0.006, 0.65, 0.4, "vidrio")
	# the railing on its open side: black, the handrail rust red
	var fv: float = m.call(STAIR_FOOT)
	var foot := Vector3(ue - 0.06, 0.0, fv)
	var head := Vector3(ue - 0.06, LAND, lb)
	var far := Vector3(ue - 0.06, LAND, la + (0.12 if not south else -0.12))
	for seg in [[foot, head, 5], [head, far, 2]]:
		var p: Vector3 = seg[0]
		var q: Vector3 = seg[1]
		for i in range(int(seg[2]) + 1):
			var at := p.lerp(q, float(i) / float(seg[2]))
			box(at.x - 0.02, at.y, at.z - 0.02, 0.04, 1.0, 0.04, BLACK)
		bar(p + Vector3(0, 0.5, 0), q + Vector3(0, 0.5, 0), 0.03, 0.03, BLACK)
		bar(p + Vector3(0, 0.85, 0), q + Vector3(0, 0.85, 0), 0.03, 0.03, BLACK)
		bar(p + Vector3(0, 1.0, 0), q + Vector3(0, 1.0, 0), 0.05, 0.05, RUST)
	# the yellow racks for bicycles by its side
	for i in range(5):
		var rv: float = m.call(STAIR_TOP + 0.5 + i * 0.5)
		var ru := ue + 0.5
		bar(Vector3(ru, 0.0, rv), Vector3(ru, 0.75, rv), 0.04, 0.04, YELLOW)
		bar(Vector3(ru + 0.6, 0.0, rv), Vector3(ru + 0.6, 0.75, rv), 0.04, 0.04, YELLOW)
		bar(Vector3(ru - 0.02, 0.75, rv), Vector3(ru + 0.62, 0.75, rv), 0.04, 0.04, YELLOW)
	solid(Vector3(UR + STAIR_W / 2.0, LAND / 2.0, (la + lb) / 2.0), Vector3(STAIR_W, LAND + 1.0, absf(lb - la)))
	for q in range(4):                                              # (the stair is not climbed: the door at its top is shut)
		var s0: float = m.call(STAIR_FOOT - (q + 1) * 4.0 * tread)
		var s1: float = m.call(STAIR_FOOT - q * 4.0 * tread)
		var hh := (q * 4 + 2.5) * rise
		solid(Vector3(UR + STAIR_W / 2.0, hh / 2.0, (s0 + s1) / 2.0), Vector3(STAIR_W, hh, absf(s1 - s0)))

# ---------------- the four roofs ----------------
func _roofs() -> void:
	for b in range(4):
		home()
		var v0: float = V[b]
		var v1: float = V[b + 1]
		var w := v1 - v0
		var ue: float = UE if (b == 0 or b == 3) else UR
		var pv: Array = [v0, v0 + 0.12 * w, v0 + 0.53 * w, v1]
		var ph: Array = [VALLEY, KNEE, RIDGE, VALLEY]
		for i in range(3):
			var p0 := Vector3(-0.1, float(ph[i]), float(pv[i]))
			var p1 := Vector3(ue + 0.1, float(ph[i]), float(pv[i]))
			var p2 := Vector3(ue + 0.1, float(ph[i + 1]), float(pv[i + 1]))
			var p3 := Vector3(-0.1, float(ph[i + 1]), float(pv[i + 1]))
			var n := (p1 - p0).cross(p3 - p0).normalized()
			if n.y < 0.0:
				n = -n
			pieces += 1
			quad(p0, p1, p2, p3, "traslucido" if i == 0 else "chapa", n)
		# its two gables, of sheet from the brick up
		face(Vector2(ue, v1), Vector2(ue, v0))
		slab(PackedVector2Array([Vector2(0, EAVE), Vector2(w, EAVE), Vector2(w, VALLEY - 0.02), Vector2(w * 0.88, KNEE - 0.02), Vector2(w * 0.47, RIDGE - 0.02), Vector2(0, VALLEY - 0.02)]), 0.06, 0.06, "chapa")      # (2 cm under the roof's sheet: its rim is not in the roof's plane)
		face(Vector2(0, v0), Vector2(0, v1))
		slab(PackedVector2Array([Vector2(0, EAVE), Vector2(w, EAVE), Vector2(w, VALLEY - 0.02), Vector2(w * 0.53, RIDGE - 0.02), Vector2(w * 0.12, KNEE - 0.02), Vector2(0, VALLEY - 0.02)]), 0.06, 0.06, "chapa")
	home()

# ---------------- the brick hut at the south-west corner ----------------
func _hut() -> void:
	var u0 := -6.6
	var v0 := 38.0
	var v1 := 42.5
	var gy := ground(-3.3, 40.2)
	var top := gy + 3.1
	var ln := face(Vector2(u0, v0), Vector2(u0, v1))                # its west side: two little windows behind bars
	var wins: Array = [Rect2(0.9, gy + 1.7, 0.9, 0.6), Rect2(2.7, gy + 1.7, 0.9, 0.6)]
	masonry(0.0, ln, DOWN, top, wins, [], "ladrillo", "ladrillo")
	for r: Rect2 in wins:
		_pane(r, BLACK, 0x23272b)
		grille(r, 0.1, BLACK)
	ln = face(Vector2(-0.02, v0), Vector2(u0, v0))
	masonry(0.0, ln, DOWN, top, [], [], "ladrillo", "ladrillo")
	ln = face(Vector2(u0, v1), Vector2(-0.02, v1))
	var hd := Rect2(2.6, gy + 0.06, 0.9, 2.0)
	masonry(0.0, ln, DOWN, top, [hd], [], "ladrillo", "ladrillo")
	box(hd.position.x, hd.position.y, -DEEP + 0.04, 0.9, 2.0, 0.04, 0x8a8f92)
	openings += 1
	home()
	box(u0 - 0.12, top, v0 - 0.12, -0.02 - u0 + 0.12, 0.12, v1 - v0 + 0.24, "hormigon")
	solid(Vector3(u0 / 2.0, (top + DOWN) / 2.0, (v0 + v1) / 2.0), Vector3(-u0, top - DOWN, v1 - v0))

# ---------------- the street on the north, the walk on the south ----------------
func _tree(at: Vector2, tall: float, crown: float) -> void:
	var o := Vector3(at.x, ground(at.x, at.y), at.y)
	drum(o - Vector3(0, 0.1, 0), 0.13, 0.09, tall * 0.55, 0x6b5a45, 7)
	ball(o + Vector3(0, tall * 0.72, 0), crown, "hoja", 0.85, 9, 5)
	ball(o + Vector3(crown * 0.55, tall * 0.64, -crown * 0.3), crown * 0.7, "hoja", 0.85, 8, 5)
	ball(o + Vector3(-crown * 0.5, tall * 0.62, crown * 0.35), crown * 0.68, "hoja", 0.85, 8, 5)
	solid(o + Vector3(0, 1.0, 0), Vector3(0.3, 2.2, 0.3))
	yard.append(map_at(at.x, at.y))
	trees += 1

func _street() -> void:
	home()
	# the pitch's white wall along the street's far side, cypresses behind it
	var u := -24.0
	while u < 66.0:
		var g := ground(u + 3.8, -12.2)
		box(u, g - 0.6, -12.4, 7.6, 2.8, 0.2, "blanco")
		box(u - 0.02, g + 2.2, -12.44, 7.64, 0.06, 0.28, "hormigon")
		solid(Vector3(u + 3.8, g + 0.8, -12.3), Vector3(7.6, 3.0, 0.2))
		u += 7.6
	for k in range(11):
		var at := Vector2(-18.0 + k * 8.0, -14.2)
		var o := Vector3(at.x, ground(at.x, at.y), at.y)
		drum(o - Vector3(0, 0.1, 0), 0.12, 0.1, 1.2, 0x5a4a3a, 6)
		drum(o + Vector3(0, 0.9, 0), 0.95, 0.06, 7.0 + (k % 3) * 0.6, "cipres", 8)
		trees += 1
	# the trees of the walk on the south, each in its square of earth
	for k in range(5):
		_tree(Vector2(2.0 + k * 7.0, 53.7), 4.6 + (k % 2) * 0.6, 1.5)      # (on the far side of the lane, as in the orthophoto: the lane is the map's, v 47.5 to 52.5)
	# ...and the two rows of the Calle Mariano Haro east of the car park, on its pavements (the orthophoto: five along
	# the workshop's wall, three across the street)
	for k in range(5):
		_tree(Vector2(66.8 + k * 9.2, 46.6), 5.0 + (k % 2) * 0.5, 1.7)
	for k in range(3):
		_tree(Vector2(63.6 + k * 9.7, 53.7), 5.3 - (k % 2) * 0.5, 1.8)

# ---------------- the cars in its car park ----------------
## Some cars parked in its bays (the user, 28 Nov 2026: «algunos aparcados en el parking»), as at the Merkocarry: five
## by day, seven in the evening, when people train and play, two left overnight. Nose to the kerb, the nearer the doors
## the likelier. They come and go where you are not looking.
func cars_wanted(hour: float) -> int:
	if hour >= 17.0 and hour < 22.0:
		return 7
	return 5 if hour >= 8.0 and hour < 17.0 else 2

## where a car of that make stands in that bay, on the map, and which way it faces
func _bay_place(bi: int, kind: String) -> Array:
	var s: Array = bay_spots[bi]
	var nose: Vector2 = s[0]
	var dir: Vector2 = s[1]
	var ln: float = float(CarS.SPECS[kind]["len"])
	return [nose - dir * (ln / 2.0), atan2(dir.x, dir.y)]

## a free bay, the nearer the doors the likelier (-1: none)
func _free_bay(G) -> int:
	var total := 0.0
	var free: Array = []
	for bi in range(bay_spots.size()):
		var at: Vector2 = _bay_place(bi, "z15")[0]
		if G.cars.any(func(c): return is_instance_valid(c) and c.p.distance_to(at) < 2.2):
			continue
		var w: float = 1.0 / (1.0 + at.distance_to(door) / 12.0)
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

func _process(delta: float) -> void:
	var game = W.get_parent() if W != null else null
	if game != null and "clock" in game:
		_cars_t -= delta
		if _cars_t <= 0.0:
			_cars_t = 1.0
			_tend_cars(game)

# ---------------- what the map should know ----------------
## its outlines, for the little map and for whoever asks the map how much room there is
func _tell_map() -> void:
	var hall: Array = [Vector2(0, 0), Vector2(UL, 0), Vector2(UL, V[1]), Vector2(UR + STAIR_W, V[1]), Vector2(UR + STAIR_W, STAIR_TOP), Vector2(UR, STAIR_TOP),
		Vector2(UR, L - STAIR_TOP), Vector2(UR + STAIR_W, L - STAIR_TOP), Vector2(UR + STAIR_W, V[3]), Vector2(UL, V[3]), Vector2(UL, L), Vector2(0, L)]
	var hut: Array = [Vector2(-6.6, 38.0), Vector2(0, 38.0), Vector2(0, 42.5), Vector2(-6.6, 42.5)]
	for ring in [hall, hut]:
		var pts := PackedVector2Array()
		for q: Vector2 in ring:
			pts.append(map_at(q.x, q.y))
		blocks.append(pts)
		MapData.outlines.append(pts)
		if not MapData._wall_grid.is_empty():
			for i in range(pts.size()):
				var a: Vector2 = pts[i]
				var c: Vector2 = pts[(i + 1) % pts.size()]
				MapData._grid_add(MapData._wall_grid, a.min(c), a.max(c), [a, c])
