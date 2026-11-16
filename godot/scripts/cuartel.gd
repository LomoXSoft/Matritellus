extends "res://scripts/obra.gd"
## The Guardia Civil's barracks of the Avenida de la Constitución -- the Tricornios' in the game -- built by hand (the
## user, 16 November 2026: "Vamos con el cuartel de la guardia civil (tricornios)"; referencias/cuartel_tricornios/,
## tools/cuartel/).
##
## As Street View has it in November 2024 from the three streets round it: four plain white blocks of three floors
## under a moulded cornice, set round a court. The main front is on the avenue: two blocks of four windows a floor
## -- the ground floor's behind green bars, air conditioners between them -- and in the narrow recess between the
## two the way in: glass doors up five steps, a black plaque over them, the flag-striped sign of its motto over that;
## a ramp with a black rail runs down along the south block; the flag flies from a pole on a foot of rubble; cars park
## nose-in before it, and two clipped trees stand by the ramp. On the Calle de Víctor Pradera the fronts are plainer
## still -- barred windows, washing lines under the upper ones -- and between the two north blocks a tall gate of
## green bars shuts the court. To the south a yard of bare earth under big trees, behind a low white wall with a
## mesh fence on the Calle Nueva; the south-east block has its garages there.
##
## Frame: origin at the north end of the main front (the corner of the avenue and the Calle de Víctor Pradera); +x
## along the front, southwards; +z out of it, towards the avenue (west); y = 0 the ground before the steps.
## Catastro's parcel 4397001VJ5649N is not raised by the bake (tools/bake_godot.py, CUARTEL): this builds it. Catastro
## has the gaps between the blocks two metres too wide: the recess of the way in and the gate are as the pictures
## have them.
## Its lettering: the motto stays; the plaque and the badge are the game's (the Tricornios; a gold tricorn on black) and name no
## ministry (the user: "Vale"). Nobody goes in; the court and the yard are shut. No people in it.
## The user, the same day: "deja siempre un coche aparcado de los tricornios en la puerta, sin ocupantes"; taking it is
## the chase the game already starts for any of their cars, and "al día siguiente vuelve a aparecer uno". The car
## and those rules are the game's business (not this script's):
## `patrol` says where it stands -- the yellow box before the steps, nose to the door -- and `door`, `gate` and `bays`
## what else is here.

const READY := true                             # (tools/bake_godot.py looks for this: with it, Catastro's block is not raised)
const O := Vector2(46.84, -534.47)
const U := Vector2(0.165, 0.986)
const MOTTO := "TODO POR LA PATRIA"
const PLAQUE := "ES LA PRINCIPAL DIVISA DEL TRICORNIO"
const BADGE := "LOS TRICORNIOS"
const LOGO := "res://assets/tricornios/logo.png"                # their badge: the gold tricorn on black, painted by tools/cuartel/logo.py
const FLOOR := 0.77                             # the ground floor, over the ground before the steps
const TOP := 11.0                               # the top of the walls
const WW := 1.05                                # a window's width
const SILL: Array = [1.73, 4.65, 7.6]           # the windows of each floor: their sills...
const HEAD: Array = [3.03, 5.9, 8.85]           # ...and their heads
const LINES: Array = [3.85, 6.97]               # the lines scored in the render at each floor
const R0 := 15.81                               # the recess of the way in: from...
const R1 := 19.71                               # ...to
const RD := -2.02                               # ...and how far back its wall is
const DOWN := -4.0                              # well under any ground
const GREEN := 0x2f4a3c                         # the bars of its windows and its gate
const GLASS := 0x3a4854
const FRAME := 0xf4f3ee
const BLIND := 0xdedbd0
const RAIL := 0x1e1e20
const ROOF := 0x86827a
const STEP := 0xcfc8b6
const NW: Array = [Vector2(0, -1.61), Vector2(4.9, -1.61), Vector2(4.9, 0), Vector2(15.81, 0), Vector2(15.81, -15.3), Vector2(0, -15.3)]
const SW: Array = [Vector2(19.71, 0), Vector2(30.62, 0), Vector2(30.62, -1.62), Vector2(35.63, -1.62), Vector2(35.63, -15.3), Vector2(19.71, -15.3)]
const LINK: Array = [Vector2(15.81, -2.02), Vector2(19.71, -2.02), Vector2(19.71, -4.72), Vector2(15.81, -4.72)]
const NE: Array = [Vector2(0, -21.3), Vector2(13.45, -21.3), Vector2(13.45, -47.59), Vector2(0, -47.59)]
const SE: Array = [Vector2(20.5, -21.3), Vector2(35.65, -21.3), Vector2(35.65, -37.9), Vector2(20.5, -37.9)]
const ELINK: Array = [Vector2(13.45, -38.0), Vector2(22.0, -38.0), Vector2(22.0, -43.6), Vector2(13.45, -43.6)]
const GARAGES: Array = [Rect2(2.2, -4.0, 2.8, 6.77), Rect2(9.2, -4.0, 2.8, 6.77)]      # the two garages of the south-east block, on its south front (from DOWN up to 2 m over the floor)
const YARD: Array = [Vector2(35.63, -1.62), Vector2(39.3, -1.6), Vector2(55.2, -31.8), Vector2(47.0, -31.6), Vector2(39.9, -35.5), Vector2(38.8, -38.4), Vector2(35.65, -37.9)]      # the south yard: the block's corner, the wall along the Calle Nueva, the neighbour's walls, back to the block

var door: Vector2               # before its steps, on the map
var gate: Vector2               # before the gate of its court, on the Calle de Víctor Pradera, on the map
var bays: Array = []            # the parking bays before it: {at: its middle on the map, to: the way a car in it looks (towards the front)}
var patrol := {}                # where the Tricornios' own car stands, in the yellow box before the steps: {at: its middle on the map, to: the way it looks}; empty if there is no room
var signs := 0                  # how many of its three signs are up

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"blanco":           # white render: white in the shade too
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.13, 1.12, 1.08)), 0.5)
		"medianera":        # the walls it shares with its neighbours
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.9, 0.87, 0.8)), 0.28)
		"rubble":           # the flagpole's foot
			m = Tex.mat("stone_wall", Color(1.25, 1.2, 1.1))
		"asfalto":
			m = W._tmat(0x77727a, "asphalt", 3.0)
		"tierra":           # the yard's bare earth
			m = W._tmat(0xb9a58a, "earth", 4.0)
		"losa":             # the court's paving
			m = W._tmat(0xb8ad98, "pavement", 2.0)
		"leaf":
			m = W._tmat(0x5a9a48, "leaf", 1.3)
		"seto":             # a clipped tree: darker
			m = W._tmat(0x3f7a3c, "leaf", 1.0)
		"logo":             # their badge, on its plate
			var bm := StandardMaterial3D.new()
			bm.albedo_texture = Parts.texture(LOGO)
			bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			bm.alpha_scissor_threshold = 0.5
			bm.roughness = 1.0
			m = _glow(bm, 0.25)
		"tela_roja", "tela_amarilla":      # the flag's cloth, seen from both sides
			var cm := StandardMaterial3D.new()
			cm.albedo_color = Parts.col(0xc8102e if String(key) == "tela_roja" else 0xf1bf00)
			cm.cull_mode = BaseMaterial3D.CULL_DISABLED
			cm.roughness = 1.0
			m = cm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	var data: Dictionary = MapData.cuartel
	var o := Vector2(data["o"][0], data["o"][1]) if data.has("o") else O
	var u := Vector2(data["u"][0], data["u"][1]) if data.has("u") else U
	var out := Vector2(-u.y, u.x)
	level = MapData.height(o + u * ((R0 + R1) / 2.0) + out * 3.2)
	transform = Transform3D(Basis(Vector3(u.x, 0, u.y), Vector3.UP, Vector3(out.x, 0, out.y)), Vector3(o.x, level, o.y))
	W.add_child(self)
	door = spot((R0 + R1) / 2.0 - 2.4, 4.2)
	gate = spot(-1.6, -18.3)
	_floors()
	_blocks()
	_entrance()
	_steps()
	_apron()
	_front_things()
	_north_things()
	_yard()
	home()
	_commit()
	_solid_walls()
	_tell_map()

## What stands here, for whoever asks the map how much room there is and for the little map.
func _tell_map() -> void:
	for ring in [NW, SW, LINK, NE, SE, ELINK]:
		var pts := PackedVector2Array()
		for q: Vector2 in ring:
			pts.append(spot(q.x, q.y))
		MapData.outlines.append(pts)
		if not MapData._wall_grid.is_empty():
			for i in range(pts.size()):
				var a: Vector2 = pts[i]
				var b: Vector2 = pts[(i + 1) % pts.size()]
				MapData._grid_add(MapData._wall_grid, a.min(b), a.max(b), [a, b])

## its blocks, solid
func _solid_walls() -> void:
	_prism([Vector2(0, 0), Vector2(15.81, 0), Vector2(15.81, -15.3), Vector2(0, -15.3)], DOWN, TOP)
	_prism([Vector2(19.71, 0), Vector2(35.63, 0), Vector2(35.63, -15.3), Vector2(19.71, -15.3)], DOWN, TOP)
	for ring in [LINK, NE, SE, ELINK]:
		_prism(ring, DOWN, TOP)

# ---------------- helpers ----------------
## how far a spot of the frame is from the nearest roadway as it is drawn (negative: in it)
func _free(x: float, z: float) -> float:
	var d: float = MapData.road_edge_dist(spot(x, z))
	if MapData.road_hit != null:
		d += MapData.road_hit.hw - MapData.fitted_hw(MapData.road_hit)
	return d

## A floor laid on the ground itself, following it: this outline (x, z), cut small enough to lie on the map's relief.
func _drape(pts: PackedVector2Array, key, lift := 0.05) -> void:
	pieces += 1
	var idx := Geometry2D.triangulate_polygon(pts)
	var todo: Array = []
	for t in range(0, idx.size(), 3):
		todo.append([pts[idx[t]], pts[idx[t + 1]], pts[idx[t + 2]]])
	while not todo.is_empty():
		var tr: Array = todo.pop_back()
		var a: Vector2 = tr[0]
		var b: Vector2 = tr[1]
		var c: Vector2 = tr[2]
		var ab: float = a.distance_to(b)
		var bc: float = b.distance_to(c)
		var ca: float = c.distance_to(a)
		if maxf(ab, maxf(bc, ca)) > 2.4:              # halve its longest side
			if ab >= bc and ab >= ca:
				todo.append([a, (a + b) / 2.0, c])
				todo.append([(a + b) / 2.0, b, c])
			elif bc >= ca:
				todo.append([a, b, (b + c) / 2.0])
				todo.append([a, (b + c) / 2.0, c])
			else:
				todo.append([a, b, (c + a) / 2.0])
				todo.append([(c + a) / 2.0, b, c])
			continue
		tri(Vector3(a.x, ground(a.x, a.y) + lift, a.y), Vector3(b.x, ground(b.x, b.y) + lift, b.y), Vector3(c.x, ground(c.x, c.y) + lift, c.y), key, Vector3.UP)

## a line painted on the ground, from a to b
func _paint(a: Vector2, b: Vector2, hex: int, wide := 0.1) -> void:
	var d: Vector2 = (b - a).normalized()
	var n := Vector2(-d.y, d.x) * wide / 2.0
	_drape(PackedVector2Array([a - n, b - n, b + n, a + n]), hex, 0.075)

## what fills a window's hole: glass in a white frame of two leaves, its blind part of the way down, its sill; and its
## green bars, if it has them
func _win(r: Rect2, bars: bool, blind: float) -> void:
	var z := -0.1
	box(r.position.x, r.position.y, z - 0.04, r.size.x, r.size.y, 0.02, GLASS)
	for q in [[r.position.x, r.position.y, 0.05, r.size.y], [r.end.x - 0.05, r.position.y, 0.05, r.size.y], [r.position.x, r.position.y, r.size.x, 0.05], [r.position.x, r.end.y - 0.05, r.size.x, 0.05],
			[r.position.x + r.size.x / 2.0 - 0.025, r.position.y, 0.05, r.size.y]]:
		box(q[0], q[1], z - 0.01, q[2], q[3], 0.05, FRAME)
	var h: float = (r.size.y - 0.1) * blind
	if h > 0.05:
		box(r.position.x + 0.05, r.end.y - 0.05 - h, z - 0.025, r.size.x - 0.1, h, 0.025, BLIND)
		var rows := int(h / 0.1)
		for j in range(1, rows):
			box(r.position.x + 0.05, r.end.y - 0.05 - j * h / rows, z, r.size.x - 0.1, 0.008, 0.003, 0xbdb9ab)
	box(r.position.x - 0.05, r.position.y - 0.05, 0.0, r.size.x + 0.1, 0.05, 0.06, 0xd9d6cc)
	if bars:                                        # a frame, bars across it, two uprights
		var g := Rect2(r.position.x - 0.06, r.position.y - 0.04, r.size.x + 0.12, r.size.y + 0.1)
		for q in [[g.position.x, g.position.y, 0.035, g.size.y], [g.end.x - 0.035, g.position.y, 0.035, g.size.y], [g.position.x, g.position.y, g.size.x, 0.035], [g.position.x, g.end.y - 0.035, g.size.x, 0.035]]:
			box(q[0], q[1], 0.03, q[2], q[3], 0.035, GREEN)
		for j in range(1, 10):
			box(g.position.x, g.position.y + j * g.size.y / 10.0 - 0.008, 0.035, g.size.x, 0.016, 0.02, GREEN)
		for s in [0.33, 0.67]:
			box(g.position.x + g.size.x * s - 0.009, g.position.y, 0.04, 0.018, g.size.y, 0.02, GREEN)

## a washing line under a window: two brackets and their wires
func _rack(r: Rect2) -> void:
	var y: float = r.position.y - 0.22
	for x in [r.position.x - 0.45, r.end.x + 0.45]:
		bar(Vector3(x, y - 0.18, 0.0), Vector3(x, y + 0.02, 0.5), 0.025, 0.025, 0x4a4d50)
		bar(Vector3(x, y + 0.02, 0.0), Vector3(x, y + 0.02, 0.5), 0.025, 0.025, 0x4a4d50)
	for k in range(4):
		box(r.position.x - 0.45, y + 0.02, 0.1 + k * 0.12, r.size.x + 0.9, 0.006, 0.006, 0x6a6d70)

## an air conditioner on its brackets: `r` on the wall being built
func _air(r: Rect2, deep := 0.3) -> void:
	box(r.position.x, r.position.y, 0.1, r.size.x, r.size.y, deep, 0xf1f0ea)
	var rad: float = minf(r.size.x * 0.3, r.size.y * 0.4)
	slab(oval(r.position.x + r.size.x * 0.4, r.position.y + r.size.y * 0.5, rad, rad, 12), 0.1 + deep + 0.006, 0.0, 0xb4b8bc)
	for x in [r.position.x + 0.08, r.end.x - 0.12]:
		box(x, r.position.y - 0.04, 0.0, 0.04, 0.04, 0.1 + deep, 0xd9d9d4)

## a street lamp on its arm, on the wall being built
func _lamp(x: float, y: float) -> void:
	bar(Vector3(x, y, 0.0), Vector3(x, y + 0.35, 0.9), 0.04, 0.04, 0x9a9da0)
	cbox(Vector3(x, y + 0.36, 1.05), Vector3(0.2, 0.09, 0.5), 0x8a8d90)
	cbox(Vector3(x, y + 0.31, 1.05), Vector3(0.14, 0.02, 0.36), 0xf4f1e0)

## A front of a block, from a to b on the floor plan (a: its left end seen from outside), up to `top`: white render, a
## window in each of `cols` (metres along it) on each of its floors, the lines scored at each floor, its foot, its
## cornice. `look`: "bars" (the ground floor's windows barred: true), "floors" (which floors have windows), "holes"
## (other holes), "racks" (washing lines under some upper windows), "dress" (lines, foot and cornice: true), "foot"
## (false where a doorway cuts it), "key"
## (what it is made of). The frame stays set on it: the caller adds what else hangs there, then calls home().
func _front(a: Vector2, b: Vector2, top: float, cols: Array, look := {}) -> float:
	var ln: float = face(a, b)
	var floors: Array = look.get("floors", [0, 1, 2])
	var holes: Array = (look.get("holes", []) as Array).duplicate()
	var wins: Array = []
	for c in cols:
		for f: int in floors:
			var r := Rect2(float(c) - WW / 2.0, float(SILL[f]), WW, float(HEAD[f]) - float(SILL[f]))
			holes.append(r)
			wins.append([r, f])
	masonry(0.0, ln, DOWN, top, holes, [], look.get("key", "blanco"))
	var seed := int(absf(a.x * 7.0 + a.y * 13.0 + b.x * 3.0 + b.y * 5.0))
	for k in range(wins.size()):
		var r: Rect2 = wins[k][0]
		var f: int = wins[k][1]
		var barred: bool = f == 0 and look.get("bars", true)
		_win(r, barred, 0.7 if barred else 0.2 + 0.2 * ((seed + k * 5) % 4))
		if f > 0 and look.get("racks", false) and (seed + k) % 3 == 0:
			_rack(r)
	if look.get("dress", true):
		for y in LINES:
			box(0.0, float(y) - 0.012, 0.0, ln, 0.024, 0.004, 0xb9b5a8)
			box(0.0, float(y) + 0.72, 0.0, ln, 0.02, 0.004, 0xc6c2b6)
		if look.get("foot", true):
			box(0.0, DOWN, 0.0, ln, FLOOR + 0.25 - DOWN, 0.03, "blanco")                # its foot
		box(-0.1, top - 0.64, 0.0, ln + 0.2, 0.12, 0.1, "blanco")                       # its cornice
		box(-0.18, top - 0.52, 0.0, ln + 0.36, 0.4, 0.18, "blanco")
		box(-0.24, top - 0.12, 0.0, ln + 0.48, 0.12, 0.25, "blanco")
	return ln

## A block: a front on every side of its outline (north-west corner first, then round by the south), and its flat roof.
## `fronts`: side -> what that front has ("cols" and what _front takes; "then": what else to hang on it, given its length).
func _block(ring: Array, top: float, fronts: Dictionary) -> void:
	for i in range(ring.size()):
		var spec: Dictionary = fronts.get(i, {})
		var ln: float = _front(ring[i], ring[(i + 1) % ring.size()], top, spec.get("cols", []), spec)
		if spec.has("then"):
			(spec["then"] as Callable).call(ln)
		home()
	flat(PackedVector2Array(ring), top, ROOF)
	var c := Vector2.ZERO
	for q: Vector2 in ring:
		c += q / ring.size()
	for k in range(3):                              # what stands on its roof: a few vents
		cbox(Vector3(c.x - 3.0 + k * 2.6, top + 0.3, c.y + (k % 2) * 2.4 - 1.0), Vector3(0.5, 0.6, 0.5), 0xb4b0a6)

# ---------------- the floors under it all ----------------
func _floors() -> void:
	_drape(PackedVector2Array([Vector2(0.0, -47.59), Vector2(35.65, -47.59), Vector2(35.65, 0.0), Vector2(0.0, 0.0)]), "losa", 0.04)
	_drape(PackedVector2Array(YARD), "tierra", 0.04)

# ---------------- its four blocks ----------------
## a cable slung along the front being built, at height y
func _cable(ln: float, y: float) -> void:
	bar(Vector3(0.0, y, 0.03), Vector3(ln, y, 0.03), 0.02, 0.02, 0x1c1c1e)

## the round "no parking" plate screwed to a wall
func _no_parking(x: float, y: float) -> void:
	slab(oval(x, y, 0.22, 0.22, 16), 0.03, 0.01, 0xc8281e)
	slab(oval(x, y, 0.16, 0.16, 16), 0.034, 0.0, 0x2a52a0)
	bar(Vector3(x - 0.11, y + 0.11, 0.037), Vector3(x + 0.11, y - 0.11, 0.037), 0.004, 0.035, 0xc8281e)

func _x_strip(ln: float) -> void:
	_lamp(ln * 0.5, 5.0)

func _x_nw_body(ln: float) -> void:
	_air(Rect2(2.0, 2.45, 0.75, 0.52))
	_air(Rect2(9.2, 2.45, 0.75, 0.52))
	_cable(ln, 3.72)

func _x_nw_north(ln: float) -> void:
	_air(Rect2(7.0, 3.45, 0.8, 0.55))
	_cable(ln, 3.3)
	_lamp(ln - 0.6, 5.2)
	_no_parking(ln - 1.2, 2.2)                      # by the avenue's corner

func _x_sw_body(ln: float) -> void:
	_air(Rect2(3.25, 2.45, 0.75, 0.52))
	_air(Rect2(5.7, 2.45, 0.75, 0.52))
	_cable(ln, 3.72)
	_lamp(10.3, 5.0)
	_badge(0.44, 2.45)

func _x_sw_south(_ln: float) -> void:
	_air(Rect2(4.2, 2.3, 0.8, 0.55))

func _x_ne_north(ln: float) -> void:
	_cable(ln, 3.3)
	_lamp(ln * 0.55, 5.2)
	_lamp(2.6, 5.2)
	box(10.8, DOWN, 0.0, 0.1, TOP - 0.7 - DOWN, 0.1, 0xe9e6dc)                          # a rainwater pipe
	_no_parking(0.9, 2.2)

func _x_se_south(_ln: float) -> void:               # the doors of its two garages: green, ribbed
	for g: Rect2 in GARAGES:
		var g0: float = ground(35.65 + 0.4, -21.3 - g.position.x - 1.4)
		box(g.position.x, g0, -0.12, g.size.x, g.end.y - g0, 0.04, 0x5f7a52)
		for j in range(1, 9):
			box(g.position.x, g0 + j * (g.end.y - g0) / 9.0, -0.08, g.size.x, 0.02, 0.012, 0x4c6442)

func _blocks() -> void:
	var body: Array = [1.125, 3.545, 5.965, 8.385]         # the four windows of a body of the main front, from its outer end
	var inner: Array = [2.525, 4.945, 7.365, 9.785]         # ...and from the recess
	var plain := {"dress": false, "key": "medianera"}
	# north-west: its strip, the side of its body, its body on the avenue, its side on the recess, the court, the Calle de Víctor Pradera
	_block(NW, TOP, {0: {"then": _x_strip}, 2: {"cols": body, "then": _x_nw_body}, 4: {"cols": [3.2, 8.0, 12.6], "bars": false},
		5: {"cols": [1.95, 4.35, 8.65, 11.2], "racks": true, "then": _x_nw_north}})
	# south-west: its body on the avenue, the side of it, its strip, the yard, the court, its side on the recess
	_block(SW, TOP, {0: {"cols": inner, "then": _x_sw_body}, 3: {"cols": [2.6, 6.8, 11.0], "then": _x_sw_south}, 4: {"cols": [3.2, 8.0, 12.6], "bars": false}})
	# the link between them: the way in is in its front (_entrance draws it)
	_block(LINK, TOP - 0.3, {0: {"dress": false, "holes": [Rect2(0.45, DOWN, 3.0, FLOOR + 2.75 - DOWN)]}, 1: plain, 2: plain, 3: plain})
	# north-east: the court, its inner side, its end against the neighbour, the Calle de Víctor Pradera
	_block(NE, TOP, {0: {"cols": [3.0, 7.0, 10.6], "bars": false}, 2: plain,
		3: {"cols": [1.84, 5.54, 8.34, 13.24, 16.04, 20.69, 23.54], "racks": true, "then": _x_ne_north}})
	# south-east: the court, the yard with its two garages, the neighbour, its inner side
	_block(SE, TOP, {0: {"cols": [3.2, 8.0, 12.2], "bars": false}, 1: {"cols": [3.6, 10.6, 14.3], "floors": [1, 2], "holes": GARAGES, "foot": false, "then": _x_se_south}, 2: plain})
	_block(ELINK, TOP - 0.3, {0: plain, 1: plain, 2: plain, 3: plain})

# ---------------- the way in ----------------
## In the front of the link: the glass doors in their white frame, the black plaque over them, the flag-striped sign
## of the motto over that, a lamp between the two.
func _entrance() -> void:
	var ln: float = face(Vector2(R0, RD), Vector2(R1, RD))
	var x0 := 0.45
	var y0: float = FLOOR
	var z := -0.1
	box(x0, y0, z - 0.06, 3.0, 2.75, 0.02, 0x2a3138)
	for x in [x0, x0 + 0.62, x0 + 1.47, x0 + 2.33, x0 + 2.94]:
		box(x, y0, z - 0.02, 0.06, 2.75, 0.07, FRAME)
	for y in [y0, y0 + 2.18, y0 + 2.69]:
		box(x0, y, z - 0.02, 3.0, 0.06, 0.07, FRAME)
	for y in [y0 + 0.35, y0 + 1.1]:                 # the bars across its fixed lights
		for x in [x0 + 0.06, x0 + 2.39]:
			box(x, y, z - 0.02, 0.56, 0.05, 0.06, FRAME)
	for x in [x0 + 1.38, x0 + 1.56]:                # its handles
		box(x, y0 + 0.95, z + 0.05, 0.03, 0.35, 0.03, 0xb9bcc0)
	# the plaque: black, its letters pale
	var pw := 2.87
	box((ln - pw) / 2.0, 3.98, 0.0, pw, 0.68, 0.04, 0x1c1c1e)
	box((ln - pw) / 2.0 + 0.5, 4.66, 0.0, pw - 1.0, 0.07, 0.04, 0x1c1c1e)
	_text("EL HONOR", Vector3(ln / 2.0, 4.47, 0.05), 48, 0xd9d2b8, 0.0042)
	_text(PLAQUE, Vector3(ln / 2.0, 4.17, 0.05), 32, 0xd9d2b8, 0.0034)
	signs += 1
	# the sign of the motto: the flag's three bands, black letters on the yellow one
	var sw := 1.65
	box((ln - sw) / 2.0, 5.35, 0.0, sw, 0.5, 0.04, 0xc8102e)
	box((ln - sw) / 2.0, 5.45, 0.0, sw, 0.3, 0.045, 0xf1bf00)
	_text(MOTTO, Vector3(ln / 2.0, 5.6, 0.055), 32, 0x1c1c1e, 0.0041)
	signs += 1
	cbox(Vector3(ln / 2.0, 5.02, 0.09), Vector3(0.12, 0.2, 0.16), 0x2a2a2c)             # the lamp under it
	_lamp(ln - 0.25, 5.3)
	home()

## The badge by the door: the Tricornios' own -- a tricorn hat in gold on black (the user: "invertir el logo ... cambiar
## negro por dorado y viceversa ... y usarlo como su logo"; the same picture goes on their cars: tricornio_marcas.gd) --
## and a white board saying whose house this is.
func _badge(x: float, y: float) -> void:
	box(x, y, 0.0, 0.5, 0.5, 0.025, 0x1c1c1e)
	if Parts.texture(LOGO) != null:
		quad(Vector3(x, y, 0.027), Vector3(x + 0.5, y, 0.027), Vector3(x + 0.5, y + 0.5, 0.027), Vector3(x, y + 0.5, 0.027), "logo", Vector3(0, 0, 1), [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	else:                                           # (its picture is missing: the hat drawn here -- its back turned up square, its low crown, its brim)
		var cx: float = x + 0.25
		var cy: float = y + 0.17
		slab(PackedVector2Array([Vector2(cx - 0.13, cy), Vector2(cx + 0.13, cy), Vector2(cx + 0.17, cy + 0.17), Vector2(cx - 0.17, cy + 0.17)]), 0.03, 0.0, 0xe6b422)
		slab(oval(cx, cy + 0.045, 0.11, 0.07, 12), 0.034, 0.0, 0xb08412)
		box(cx - 0.2, cy - 0.03, 0.027, 0.4, 0.035, 0.008, 0xe6b422)
	box(x + 0.5, y, 0.0, 0.84, 0.5, 0.025, 0xf7f6f1)
	_text("LOS\nTRICORNIOS", Vector3(x + 0.92, y + 0.25, 0.03), 32, 0x1f4a30, 0.0034)
	signs += 1

# ---------------- its steps and its ramp ----------------
func _steps() -> void:
	var x0 := 14.1                                  # the north end of the steps
	var x1 := 19.9                                  # where the ramp begins
	var xe := 32.0                                  # ...and where it comes down to the ground
	var wide := 1.3
	box(R0, DOWN, RD, R1 - R0, FLOOR - DOWN, -RD, STEP)                                 # the landing: in the recess...
	box(x0, DOWN, 0.0, x1 - x0, FLOOR - DOWN, wide, STEP)                               # ...and before it
	box(x0 - 0.3, DOWN, wide, 6.4, 0.154 - DOWN, 1.5, STEP)                             # the long bottom step
	for k in range(4):                              # the steps, up from the avenue
		box(x0, DOWN, wide + 0.3 * k, 2.4, FLOOR * (4 - k) / 5.0 - DOWN, 0.3, STEP)
	var ye: float = ground(xe, wide / 2.0)
	quad(Vector3(x1, FLOOR, 0.0), Vector3(xe, ye, 0.0), Vector3(xe, ye, wide), Vector3(x1, FLOOR, wide), STEP, Vector3.UP)
	quad(Vector3(x1, DOWN, wide), Vector3(xe, DOWN, wide), Vector3(xe, ye + 0.1, wide), Vector3(x1, FLOOR + 0.1, wide), "blanco", Vector3(0, 0, 1))
	quad(Vector3(x1, FLOOR, wide - 0.12), Vector3(xe, ye, wide - 0.12), Vector3(xe, ye + 0.1, wide - 0.12), Vector3(x1, FLOOR + 0.1, wide - 0.12), "blanco", Vector3(0, 0, -1))
	quad(Vector3(x1, FLOOR + 0.1, wide - 0.12), Vector3(xe, ye + 0.1, wide - 0.12), Vector3(xe, ye + 0.1, wide), Vector3(x1, FLOOR + 0.1, wide), "blanco", Vector3.UP)
	for q in [[21.6, 0.3], [24.8, 0.22]]:           # two vents of brick in its wall, and a little dark door
		box(q[0], q[1], wide, 0.26, 0.12, 0.01, 0xb8623c)
	box(26.4, ground(26.6, wide + 0.2), wide, 0.55, 0.5, 0.012, 0x2a2a2c)
	# the rail: along the landing from the head of the steps, then down the ramp
	var zr: float = wide - 0.06
	var from := x0 + 2.4
	bar(Vector3(from, FLOOR + 0.95, zr), Vector3(x1, FLOOR + 0.95, zr), 0.04, 0.04, RAIL)
	bar(Vector3(from, FLOOR + 0.12, zr), Vector3(x1, FLOOR + 0.12, zr), 0.03, 0.03, RAIL)
	bar(Vector3(x1, FLOOR + 1.05, zr), Vector3(xe, ye + 1.05, zr), 0.04, 0.04, RAIL)
	bar(Vector3(x1, FLOOR + 0.22, zr), Vector3(xe, ye + 0.22, zr), 0.03, 0.03, RAIL)
	var n := int((xe - from) / 0.13)
	for i in range(n + 1):
		var x: float = from + (xe - from) * i / n
		var y: float = FLOOR if x <= x1 else lerpf(FLOOR, ye, (x - x1) / (xe - x1)) + 0.1
		var post: bool = i % 9 == 0
		cbox(Vector3(x, y + 0.53, zr), Vector3(0.035 if post else 0.014, 0.95 if post else 0.83, 0.035 if post else 0.014), RAIL)
	solid(Vector3((x0 + x1) / 2.0, 0.3, 1.0), Vector3(x1 - x0 + 0.4, 2.0, 3.6))
	solid(Vector3((x1 + xe) / 2.0, 0.6, wide / 2.0), Vector3(xe - x1, 2.4, wide))

# ---------------- before the main front ----------------
## The apron between the front and the avenue: tarmac, the bays painted on it where cars park nose-in, the yellow
## box before the steps.
func _apron() -> void:
	var edge: Array = []                            # how far out the tarmac can go at each step along the front
	var xs: Array = []
	var x := -0.6
	while x <= 37.0:
		var z := 9.5
		while z > 2.5 and _free(x, z) < 0.35:
			z -= 0.25
		xs.append(x)
		edge.append(z)
		x += 1.2
	for i in range(xs.size() - 1):
		_drape(PackedVector2Array([Vector2(xs[i], 0.0 if xs[i] >= 4.9 else -1.61), Vector2(xs[i + 1], 0.0 if xs[i + 1] >= 4.9 else -1.61), Vector2(xs[i + 1], edge[i + 1]), Vector2(xs[i], edge[i])]), "asfalto", 0.055)
	var reach := func(at: float) -> float:
		var best := 99.0
		for i in range(xs.size()):
			if absf(float(xs[i]) - at) < 1.9:
				best = minf(best, float(edge[i]))
		return best
	# the bays: four north of the flag, nose to the wall; five before the ramp, clear of its two trees
	for group in [[0.9, 0.5, 4], [21.2, 3.0, 5]]:
		var g0: float = group[0]
		var near: float = group[1]
		var count: int = group[2]
		for k in range(count + 1):
			var bx: float = g0 + k * 2.48
			var far: float = minf(near + 4.7, float(reach.call(bx)) - 0.1)
			if far - near < 3.4:
				continue
			_paint(Vector2(bx, near), Vector2(bx, far), 0xf1efe6)
			if k < count and minf(far, float(reach.call(bx + 2.48)) - 0.1) - near >= 3.4:
				bays.append({"at": spot(bx + 1.24, (near + far) / 2.0), "to": spot(bx + 1.24, near - 2.0) - spot(bx + 1.24, near)})
				yard.append(spot(bx + 1.24, far))
	# the yellow box before the steps: its edge and its hatching
	var y0 := 3.0
	var y1: float = minf(8.2, float(reach.call(17.0)) - 0.2)
	var bx0 := 13.5
	var bx1 := 20.9
	if y1 - y0 >= 5.0:                              # room for a car nose to the door...
		patrol = {"at": spot(16.9, y0 + 2.45), "to": (spot(16.9, y0) - spot(16.9, y0 + 2.45)).normalized()}
	elif y1 - y0 >= 2.4:                            # ...or only along the front
		patrol = {"at": spot(17.2, (y0 + y1) / 2.0), "to": (spot(18.2, y0) - spot(17.2, y0)).normalized()}
	if y1 - y0 > 1.5:
		for q in [[Vector2(bx0, y0), Vector2(bx1, y0)], [Vector2(bx1, y0), Vector2(bx1, y1)], [Vector2(bx1, y1), Vector2(bx0, y1)], [Vector2(bx0, y1), Vector2(bx0, y0)]]:
			_paint(q[0], q[1], 0xe6c12a)
		var c: float = bx0 - (y1 - y0)
		while c < bx1:
			var t0: float = maxf(0.0, bx0 - c)
			var t1: float = minf(y1 - y0, bx1 - c)
			if t1 - t0 > 0.3:
				_paint(Vector2(c + t0, y0 + t0), Vector2(c + t1, y0 + t1), 0xe6c12a, 0.08)
			c += 1.1

## a tree clipped round, in its bed
func _clipped(at: Vector2, tall: float) -> void:
	var g: float = ground(at.x, at.y)
	drum(Vector3(at.x, g - 0.2, at.y), 0.09, 0.07, tall * 0.62, 0x6b5a45, 7)
	ball(Vector3(at.x, g + tall * 0.72, at.y), tall * 0.3, "seto", 0.82, 10, 6)
	cbox(Vector3(at.x, g + 0.03, at.y), Vector3(0.9, 0.06, 0.9), 0x6a5a48)
	solid(Vector3(at.x, g + 1.0, at.y), Vector3(0.3, 2.2, 0.3))
	yard.append(spot(at.x, at.y))

## a tree with a round crown
func _tree(at: Vector2, tall: float) -> void:
	var g: float = ground(at.x, at.y)
	var crown: float = tall * 0.28
	drum(Vector3(at.x, g - 0.3, at.y), 0.3, 0.2, tall * 0.5, 0x6b5a45, 8)
	ball(Vector3(at.x, g + tall * 0.72, at.y), crown, "leaf", 0.88, 10, 6)
	ball(Vector3(at.x + crown * 0.62, g + tall * 0.6, at.y - crown * 0.3), crown * 0.72, "leaf", 0.88, 9, 5)
	ball(Vector3(at.x - crown * 0.58, g + tall * 0.62, at.y + crown * 0.3), crown * 0.7, "leaf", 0.88, 9, 5)
	solid(Vector3(at.x, g + 1.2, at.y), Vector3(0.5, 2.6, 0.5))
	yard.append(spot(at.x, at.y))

## The flag on its pole, on a foot of rubble; the two clipped trees by the ramp and the little one at the corner; the
## post with its cameras.
func _front_things() -> void:
	var at := Vector2(12.9, 2.3)
	var g: float = ground(at.x, at.y)
	cbox(Vector3(at.x, (DOWN + g + 0.95) / 2.0, at.y), Vector3(0.8, g + 0.95 - DOWN, 0.8), "rubble")
	drum(Vector3(at.x, g + 0.95, at.y), 0.045, 0.03, 5.6, 0xf1f0ea, 8)
	ball(Vector3(at.x, g + 6.6, at.y), 0.06, 0xd9c070, 1.0, 6, 4)
	var top: float = g + 6.4                        # the flag: three bands, hanging a little off the pole
	for band in [[0.0, 0.25, "tela_roja"], [0.25, 0.75, "tela_amarilla"], [0.75, 1.0, "tela_roja"]]:
		var y1: float = top - 0.8 * float(band[0])
		var y0: float = top - 0.8 * float(band[1])
		quad(Vector3(at.x + 0.04, y0, at.y), Vector3(at.x + 1.15, y0 - 0.3, at.y + 0.2), Vector3(at.x + 1.15, y1 - 0.3, at.y + 0.2), Vector3(at.x + 0.04, y1, at.y), band[2], Vector3(0.17, 0, -0.98))
	solid(Vector3(at.x, g + 0.6, at.y), Vector3(0.8, 1.6, 0.8))
	yard.append(spot(at.x, at.y))
	_clipped(Vector2(28.1, 2.3), 4.0)
	_clipped(Vector2(31.7, 2.1), 3.5)
	_tree(Vector2(1.6, 1.4), 3.6)
	var cam := Vector2(-0.9, 0.3)                   # the cameras' post, at the corner
	var cg: float = ground(cam.x, cam.y)
	cbox(Vector3(cam.x, cg + 2.1, cam.y), Vector3(0.09, 4.2, 0.09), 0xb9bcc0)
	cbox(Vector3(cam.x, cg + 4.15, cam.y + 0.25), Vector3(0.1, 0.1, 0.6), 0xb9bcc0)
	ball(Vector3(cam.x, cg + 3.98, cam.y + 0.5), 0.11, 0xf1f0ea, 1.0, 8, 5)
	cbox(Vector3(cam.x + 0.2, cg + 4.05, cam.y - 0.1), Vector3(0.3, 0.09, 0.09), 0xf1f0ea)
	solid(Vector3(cam.x, cg + 1.2, cam.y), Vector3(0.2, 2.6, 0.2))
	yard.append(spot(cam.x, cam.y))

# ---------------- the Calle de Víctor Pradera ----------------
## The gate of the court, between the two north blocks: tall green bars between two rails, shut.
func _north_things() -> void:
	var ln: float = face(Vector2(0.35, -21.3), Vector2(0.35, -15.3))
	var g: float = maxf(ground(0.35, -16.0), ground(0.35, -20.6))
	for y in [g + 0.25, g + 1.55, g + 2.3]:
		box(0.0, y, -0.03, ln, 0.06, 0.06, GREEN)
	var n := int(ln / 0.14)
	for i in range(n + 1):
		box(i * (ln - 0.03) / n, g + 0.06, -0.015, 0.03, 2.5, 0.03, GREEN)
	box(0.0, DOWN, -0.08, ln, g + 0.06 - DOWN, 0.16, 0xb8b4a8)                          # its sill
	home()
	solid(Vector3(0.35, g + 1.3, -18.3), Vector3(0.2, 3.0, 6.0))
	yard.append(spot(0.2, -18.3))

# ---------------- the yard ----------------
## a stretch of wall from p to q (on the floor plan), `thick` wide, from `low` up to `top`
func _wall_piece(p: Vector2, q: Vector2, thick: float, low: float, top: float, key) -> void:
	pieces += 1
	var d: Vector2 = (q - p).normalized()
	var n := Vector2(-d.y, d.x) * thick / 2.0
	var a := [p - n, q - n, q + n, p + n]
	for s in [[0, 1, -1.0], [3, 2, 1.0]]:
		var u0: Vector2 = a[s[0]]
		var u1: Vector2 = a[s[1]]
		quad(Vector3(u0.x, low, u0.y), Vector3(u1.x, low, u1.y), Vector3(u1.x, top, u1.y), Vector3(u0.x, top, u0.y), key, Vector3(n.x, 0, n.y).normalized() * float(s[2]))
	quad(Vector3(a[0].x, top, a[0].y), Vector3(a[1].x, top, a[1].y), Vector3(a[2].x, top, a[2].y), Vector3(a[3].x, top, a[3].y), key, Vector3.UP)
	quad(Vector3(a[0].x, low, a[0].y), Vector3(a[3].x, low, a[3].y), Vector3(a[3].x, top, a[3].y), Vector3(a[0].x, top, a[0].y), key, Vector3(-d.x, 0, -d.y))
	quad(Vector3(a[1].x, low, a[1].y), Vector3(a[2].x, low, a[2].y), Vector3(a[2].x, top, a[2].y), Vector3(a[1].x, top, a[1].y), key, Vector3(d.x, 0, d.y))

## A stretch of the yard's wall from p to q: low and white, a fence of white mesh on it. `open`: from where to where
## along it the sliding gate is, instead; `mesh`: whether it has the fence (the walls against the neighbours are plain
## and taller).
func _yard_wall(p: Vector2, q: Vector2, open := Vector2(-1.0, -1.0), mesh := true) -> void:
	var ln: float = p.distance_to(q)
	var d: Vector2 = (q - p) / ln
	var n := maxi(1, int(ceil(ln / 2.5)))
	for i in range(n):
		var t0: float = ln * i / n
		var t1: float = ln * (i + 1) / n
		var a: Vector2 = p + d * t0
		var b: Vector2 = p + d * t1
		var g: float = maxf(ground(a.x, a.y), ground(b.x, b.y))
		var low: float = minf(ground(a.x, a.y), ground(b.x, b.y)) - 0.6
		if open.x >= 0.0 and (t0 + t1) / 2.0 > open.x and (t0 + t1) / 2.0 < open.y:       # the sliding gate: a sheet of iron, its green gone to rust
			_wall_piece(a, b, 0.06, low, g + 2.2, 0x6f6a4c)
			for j in range(3):
				bar(Vector3(a.x, g + 0.2 + j * 0.9, a.y), Vector3(b.x, g + 0.2 + j * 0.9, b.y), 0.1, 0.06, 0x7a5a3c)
			continue
		if not mesh:
			_wall_piece(a, b, 0.24, low, g + 2.3, "blanco")
			continue
		_wall_piece(a, b, 0.24, low, g + 1.25, "blanco")
		cbox(Vector3(a.x, g + 2.05, a.y), Vector3(0.05, 1.6, 0.05), 0xf1f0ea)
		for y in [g + 1.3, g + 2.82]:
			bar(Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), 0.03, 0.03, 0xf1f0ea)
		for j in range(1, 7):
			bar(Vector3(a.x, g + 1.3 + j * 0.217, a.y), Vector3(b.x, g + 1.3 + j * 0.217, b.y), 0.008, 0.008, 0xd9d9d4)
		var up := int((t1 - t0) / 0.2)
		for j in range(1, up):
			var c: Vector2 = a.lerp(b, float(j) / up)
			cbox(Vector3(c.x, g + 2.06, c.y), Vector3(0.008, 1.5, 0.008), 0xd9d9d4)
	var mid: Vector2 = (p + q) / 2.0
	solid(Vector3(mid.x, ground(mid.x, mid.y) + 1.2, mid.y), Vector3(ln, 3.4, 0.3), atan2(-d.y, d.x))
	yard.append(spot(p.x, p.y))
	yard.append(spot(q.x, q.y))

func _yard() -> void:
	_yard_wall(YARD[0], YARD[1])                    # from the block's corner to the Calle Nueva
	_yard_wall(YARD[1], YARD[2], Vector2(26.0, 31.0))      # along it, with its gate
	_yard_wall(YARD[2], YARD[3], Vector2(-1.0, -1.0), false)       # to the neighbour's corner
	_yard_wall(YARD[5], YARD[6], Vector2(-1.0, -1.0), false)       # ...and from the neighbour's back to the block
	_tree(Vector2(40.6, -8.4), 11.0)
	_tree(Vector2(39.4, -17.6), 8.0)
	_tree(Vector2(46.2, -26.0), 10.0)
