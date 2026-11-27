extends "res://scripts/obra.gd"
## What else stands by the old road in the cemetery's zone (the user, 25 Nov 2026, of the eight things proposed after
## the review: «Haz las 8»): the white nave by the zone's gate and the blue signs to the A-4. zonas.gd makes it
## ("afueras"), after the motorway.
##
## The nave (PNOA: tools/ign/cementerio_nave.jpg, 0.125 m a pixel; Street View 2024 from the road): a lorry workshop,
## west of the road just north of the zone's gate, 51 m along the road by 27.5 deep. Two white blocks under one front:
## the south one lower, under a blue roof with pale strips, four shut roller doors in it; the north one taller, under a
## white roof, three open bays side by side (a real hall behind them, 7 m deep: a pit, a bench, drums, tyres) and a
## shut door. Before it a concrete apron, and trodden earth from that to the road. Its north half is inside the zone's
## circle: you walk up to it and into its bays.
##
## It is «Recoveco» (the user's name for it, 25 Nov 2026: «en vez de Iveco llamarla Recoveco, y que funcione como los
## demás talleres, puerta plegable, arreglo y pintura»): the name in big blue letters high on its lower block, where
## the real one has its maker's, in our own lettering; a blue board of what it is; and the door north of the open bays
## is a garage as the town's four (garage.gd: the shutter that rolls up when you come, the bay behind it, the horn,
## mended and painted while it is down). It is NOT one of game.gd's `garages` nor of props.gd's repair points: those
## are all on the map (the tow truck takes cars to the nearest, the map's edge and the relief's tests count them), and
## this one is past its north end. tick() here does for it what game.gd does for those.
##
## The signs: before the junction, on the cemetery's side of the old road, a blue board for who goes north -- the A-4
## to Madrid straight on, to Córdoba by the slip road on the right (it only joins the carriageway south: OSM); the same
## board again at the junction, seen far off; and on the A-4 itself, past where the slip road joins it, the tall blue
## board that tells how far the next towns are, behind its fence east of the cemetery.
##
## All in the map's own measures (the frame is the map, y from the ground at the nave's front).

const NAVE_S := Vector2(331.5, -2281.9)    # its front to the road: the south end and the north one (PNOA)
const NAVE_N := Vector2(335.9, -2332.8)
const DEEP_N := 27.5                       # how far back it goes
const SOUTH := 24.5                        # the lower block, from the south end to here
const H_S := 8.3                           # the blocks' tops (Street View 2024: by the lorries before it)
const H_N := 9.9
const BAY0 := 26.4                         # the open bays: from here...
const BAY1 := 41.4                         # ...to here, two pillars between
const BAY_H := 4.9
const BAY_D := 7.0                         # the hall behind them, this deep
const PILLARS := [[30.8, 0.5], [35.7, 0.7]]
const DOORS := [[4.3, 8.4, 4.4], [10.0, 14.5, 4.4], [15.3, 19.7, 4.4], [20.0, 23.7, 4.4]]      # the shut ones: from, to, how tall
const GarageS = preload("res://scripts/garage.gd")
const SHOP := [41.8, 46.7, 4.9]            # the door that works, north of the open bays: from, to, how tall
const SHOP_D := 9.0                        # its bay: this deep...
const SHOP_TOP := 5.2                      # ...and this high
const SHOP_LOOK := {"tall": 5.2, "door_w": 4.9, "door_h": 4.9, "wall": 0xc9cac6, "inside": 0xd6d5cf, "shutter": 0xd9dad6, "roof": 0xb9bab6}      # (as garage.gd's LOOKS: its jambs the other doors' grey frames)
const NAME := "RECOVECO"
const NAME_BLUE := 0x1b3f8f
const APRON := 9.5                         # the concrete before it
const BLUE := 0x1c4f9e                     # the signs' blue
const SIGN_Z := -2602.0                    # the board on the old road: where the road is this far north (between two lamps)
const KM_Z := -2392.0                      # the board on the A-4: where its southbound carriageway is this far north

var G
var zone: Dictionary
var signs := 0                             # how many boards (the self-test)
var nave_solids := 0                       # the nave's solid pieces (the self-test)
var bay := Vector2.ZERO                    # the middle of its open bays' hall, on the map (the self-test walks in)
var taller                                 # its garage (a garage.gd, driven from tick() here)
var name_boards := 0                       # how many times its name and its trade are written on it (the self-test)
var _shop := {}                            # what game.gd is told the car stands in: {p, garage} (as props.gd's repair points)
var _spanner: Node3D                       # the spanner turning over where the car goes
var _asked := false                        # the price told to the car that is in the bay
var _served := false                       # ...and that car mended: nothing more till it goes out
var outlines: Array = []                   # what is drawn of it on the map's plan: [kind, PackedVector2Array] (zonas.gd hands them to the minimap)
var _pads: Array = []                      # what the dry plants keep off, on the map

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"blanco":             # its walls: white sheet and render
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.97, 0.97, 0.95)), 0.16)
		"hormigon":           # its apron
			m = Tex.mat("granular_concrete", Color(0.84, 0.83, 0.8), false)
		"tierra":             # trodden earth and gravel to the road (as the solar plant's drive)
			m = Tex.mat("granular_concrete", Color(0.8, 0.72, 0.6), false)
		_:
			return super(key)
	_mats[key] = m
	return m

func build(game, z: Dictionary, autovia) -> bool:
	G = game
	zone = z
	W = game.world
	if W == null:
		return false
	name = "afueras"
	level = MapData.height((NAVE_S + NAVE_N) / 2.0)
	transform = Transform3D(Basis.IDENTITY, Vector3(0.0, level, 0.0))
	_nave()
	_workshop()
	_yard()
	_road_signs()
	if autovia != null:
		_km_sign(autovia)
	home()
	_commit()
	return true

## a spot on the map as a point of the frame, `lift` over the ground there
func _at(p: Vector2, lift := 0.0) -> Vector3:
	return Vector3(p.x, MapData.height(p) - level + lift, p.y)

## What of it the zone's dry plants (trees false) and loose trees keep off, as outlines on the map
func keep_off(trees: bool, grow: float) -> Array:
	if not trees or grow <= 0.0:
		return _pads
	var out: Array = []
	for pd in _pads:
		out.append_array(_grow(pd, grow))
	return out

## an outline `by` metres bigger all round (whichever way round it goes)
static func _grow(poly: PackedVector2Array, by: float) -> Array:
	var size0 := _span(poly)
	var rev := poly.duplicate()
	rev.reverse()
	for way in [poly, rev]:
		var out: Array = Geometry2D.offset_polygon(way, by)
		if not out.is_empty() and _span(out[0]) > size0:
			return out
	return [poly]

static func _span(poly: PackedVector2Array) -> float:
	var r := Rect2(poly[0], Vector2.ZERO)
	for q in poly:
		r = r.expand(q)
	return r.size.x + r.size.y

## a solid given in the frame being built
func _solid_xf(mid: Vector3, size: Vector3) -> void:
	var m := _xf * mid
	var xd := _xf.basis.x
	solid(m, size, atan2(-xd.z, xd.x))

## a flat thing lying on the ground with this outline on the map, `lift` over it: cut along the columns of the plain's
## heights (past the map's edge the land is straight between them), so it lies on it everywhere (as cementerio.gd's)
func _lay_map(wpoly: PackedVector2Array, lift: float, key) -> void:
	if Geometry2D.is_polygon_clockwise(wpoly):
		wpoly.reverse()
	var rect := Rect2(wpoly[0], Vector2.ZERO)
	for q in wpoly:
		rect = rect.expand(q)
	var g: float = MapData.rg
	for i in range(int(floor((rect.position.x - MapData.rx0) / g)), int(floor((rect.end.x - MapData.rx0) / g)) + 1):
		var xa: float = MapData.rx0 + i * g
		var strip := PackedVector2Array([Vector2(xa, rect.position.y - 1.0), Vector2(xa + g, rect.position.y - 1.0), Vector2(xa + g, rect.end.y + 1.0), Vector2(xa, rect.end.y + 1.0)])
		for piece in Geometry2D.intersect_polygons(wpoly, strip):
			var idx := Geometry2D.triangulate_polygon(piece)
			for t in range(0, idx.size(), 3):
				var pa: Vector2 = piece[idx[t]]
				var pb: Vector2 = piece[idx[t + 1]]
				var pc: Vector2 = piece[idx[t + 2]]
				tri(_at(pa, lift), _at(pb, lift), _at(pc, lift), key, Vector3.UP)

# ---------------- the nave ----------------
## In its front's frame: x along it from its south end, z out to the road, y from its floor
func _nave() -> void:
	var L := face(NAVE_S, NAVE_N, 0.0)
	var along := (NAVE_N - NAVE_S).normalized()
	var out := Vector2(-along.y, along.x)                           # (east: to the road)
	# the two blocks, the taller one in pieces round its open hall
	box(0.0, -1.5, -DEEP_N, SOUTH, H_S + 1.5, DEEP_N, "blanco")
	box(SOUTH, -1.5, -DEEP_N, BAY0 - SOUTH, H_N + 1.5, DEEP_N, "blanco")
	var sx0: float = float(SHOP[0]) - GarageS.THICK                           # (the garage's bay: a hole in the block, from here...
	var sx1: float = float(SHOP[1]) + GarageS.THICK                           #  ...to here, SHOP_D deep, SHOP_TOP high)
	box(BAY1, -1.5, -DEEP_N, L - BAY1, H_N + 1.5, DEEP_N - SHOP_D, "blanco")
	box(BAY1, -1.5, -SHOP_D, sx0 - BAY1, H_N + 1.5, SHOP_D, "blanco")
	box(sx1, -1.5, -SHOP_D, L - sx1, H_N + 1.5, SHOP_D, "blanco")
	box(sx0, SHOP_TOP, -SHOP_D, sx1 - sx0, H_N - SHOP_TOP, SHOP_D, "blanco")
	box(sx0, -1.5, -SHOP_D, sx1 - sx0, 1.5, SHOP_D, "hormigon")                  # (under its floor)
	box(BAY0, -1.5, -DEEP_N, BAY1 - BAY0, H_N + 1.5, DEEP_N - BAY_D, "blanco")
	box(BAY0, BAY_H, -BAY_D, BAY1 - BAY0, H_N - BAY_H, BAY_D, "blanco")
	box(BAY0, -1.5, -BAY_D, BAY1 - BAY0, 1.53, BAY_D, "hormigon")               # (the hall's floor)
	for p in PILLARS:
		box(float(p[0]), 0.0, -0.5, float(p[1]), BAY_H, 0.5, "blanco")
		_solid_xf(Vector3(float(p[0]) + float(p[1]) / 2.0, 2.5, -0.25), Vector3(float(p[1]), 5.0, 0.5))
	for s in [[0.0, BAY0, 0.0, DEEP_N], [BAY1, L, SHOP_D, DEEP_N], [BAY1, sx0, 0.0, SHOP_D], [sx1, L, 0.0, SHOP_D], [BAY0, BAY1, BAY_D, DEEP_N]]:      # (x from, to; z from, to back)
		var x0: float = s[0]
		var x1: float = s[1]
		var z0: float = s[2]
		var z1: float = s[3]
		_solid_xf(Vector3((x0 + x1) / 2.0, 5.0, -(z0 + z1) / 2.0), Vector3(x1 - x0, 12.0, z1 - z0))
		nave_solids += 1
	_solid_xf(Vector3((BAY0 + BAY1) / 2.0, (BAY_H + H_N) / 2.0, -BAY_D / 2.0), Vector3(BAY1 - BAY0, H_N - BAY_H, BAY_D))      # (over the hall: the camera stays under it)
	_solid_xf(Vector3((sx0 + sx1) / 2.0, (SHOP_TOP + H_N) / 2.0 + 0.1, -SHOP_D / 2.0), Vector3(sx1 - sx0, H_N - SHOP_TOP - 0.2, SHOP_D))      # (and over the garage's bay)
	# the roofs: blue with pale strips over the lower block, white over the taller (PNOA)
	box(0.25, H_S, -DEEP_N + 0.25, SOUTH - 0.5, 0.06, DEEP_N - 0.5, 0x6b98c6)
	for k in range(9):
		box(1.6 + k * 2.6, H_S + 0.06, -DEEP_N + 1.5, 0.5, 0.012, DEEP_N - 3.0, 0xdfe6ea)
	box(SOUTH + 0.25, H_N, -DEEP_N + 0.25, L - SOUTH - 0.5, 0.06, DEEP_N - 0.5, 0xe4e4e0)
	for k in range(5):
		box(SOUTH + 3.2 + k * 5.0, H_N + 0.06, -DEEP_N + 1.5, 0.08, 0.012, DEEP_N - 3.0, 0xc4c6c6)
	# the shut doors: slatted, pale grey, in their frames
	for dr in DOORS:
		var d0: float = dr[0]
		var d1: float = dr[1]
		var dh: float = dr[2]
		box(d0, 0.0, 0.0, d1 - d0, dh, 0.035, 0xd9dad6)
		var y := 0.32
		while y < dh - 0.1:
			box(d0, y, 0.035, d1 - d0, 0.014, 0.006, 0xb4b6b3)
			y += 0.32
		box(d0 - 0.14, 0.0, 0.0, 0.14, dh + 0.14, 0.09, 0xc9cac6)
		box(d1, 0.0, 0.0, 0.14, dh + 0.14, 0.09, 0xc9cac6)
		box(d0, dh, 0.0, d1 - d0, 0.36, 0.11, 0xc9cac6)                          # (the roll's box)
	box(SOUTH - 0.06, 0.0, 0.0, 0.12, H_S, 0.1, 0xb9bbb8)                        # (a drainpipe at the step between the blocks)
	# its name: big blue letters high on the lower block's south end, where the real one's maker's are (Street View
	# 2024), heavy and wide; a blue board of what it is between its third and fourth doors; and over the door that
	# works, what is done behind it
	var big := _text(NAME, Vector3(5.4, 6.8, 0.02), 250, NAME_BLUE, 0.0056)      # (its letters 0.9 m tall, 7 m of them: as the real one's, letter for letter)
	big.shaded = true
	big.outline_size = 22
	big.outline_modulate = Parts.col(NAME_BLUE)
	big.scale = Vector3(1.22, 1.0, 1.0)
	_name_board(17.7, 22.0, 4.95, 0.8, "TALLER OFICIAL", 120)
	_name_board(float(SHOP[0]) + 0.2, float(SHOP[1]) - 0.2, float(SHOP[2]) + 0.55, 0.62, "CHAPA Y PINTURA", 108)
	name_boards += 1
	# in the hall: the pit under the middle bay, a bench along the back, a red cabinet, drums, stacks of tyres
	var zb := -BAY_D
	box(32.95, 0.03, -6.0, 1.1, 0.012, 5.4, 0x1d1e20)
	for e in [[32.85, -6.05, 0.1, 5.5], [34.05, -6.05, 0.1, 5.5], [32.85, -6.05, 1.3, 0.1], [32.85, -0.65, 1.3, 0.1]]:
		box(float(e[0]), 0.03, float(e[1]), float(e[2]), 0.016, float(e[3]), 0xd7b21c)
	box(BAY0 + 0.8, 0.03, zb + 0.06, 4.2, 0.86, 0.75, 0x46586e)
	box(BAY0 + 0.75, 0.89, zb + 0.04, 4.3, 0.05, 0.82, 0x8d8273)
	box(BAY0 + 5.6, 0.03, zb + 0.06, 1.0, 1.85, 0.5, 0xa5281f)
	_solid_xf(Vector3(BAY0 + 3.7, 1.0, zb + 0.45), Vector3(6.0, 2.0, 0.9))
	for q in [[BAY1 - 1.0, zb + 0.8, 0x3b5e8c], [BAY1 - 1.75, zb + 0.75, 0x3b5e8c], [BAY1 - 1.1, zb + 1.6, 0x7c7f83]]:
		drum(Vector3(float(q[0]), 0.03, float(q[1])), 0.29, 0.29, 0.88, int(q[2]), 10)
	_solid_xf(Vector3(BAY1 - 1.35, 1.0, zb + 1.15), Vector3(1.6, 2.0, 1.6))
	for q in [[BAY1 - 4.6, zb + 0.9, 5], [BAY1 - 6.0, zb + 0.85, 3], [BAY0 + 8.2, zb + 0.9, 4]]:
		for k in range(int(q[2])):
			drum(Vector3(float(q[0]), 0.03 + k * 0.3, float(q[1])), 0.52, 0.52, 0.29, 0x1c1c1e, 12)
		_solid_xf(Vector3(float(q[0]), 1.0, float(q[1])), Vector3(1.1, 2.0, 1.1))
	home()
	bay = NAVE_S + along * ((BAY0 + BAY1) / 2.0) - out * (BAY_D / 2.0)
	var foot := PackedVector2Array([NAVE_S, NAVE_N, NAVE_N - out * DEEP_N, NAVE_S - out * DEEP_N])
	outlines.append(["block", foot])
	_pads.append(PackedVector2Array([NAVE_S - along * 0.6 + out * 0.6, NAVE_N + along * 0.6 + out * 0.6, NAVE_N + along * 0.6 - out * (DEEP_N + 0.6), NAVE_S - along * 0.6 - out * (DEEP_N + 0.6)]))

## a blue board on its front, white words on it (in the front's frame: from x0 to x1, its foot at y, h tall)
func _name_board(x0: float, x1: float, y: float, h: float, words: String, px: int) -> void:
	box(x0, y, 0.0, x1 - x0, h, 0.05, 0xf2f2ee)
	box(x0 + 0.04, y + 0.04, 0.05, x1 - x0 - 0.08, h - 0.08, 0.014, NAME_BLUE)
	_text(words, Vector3((x0 + x1) / 2.0, y + h / 2.0, 0.072), px, 0xffffff).shaded = true
	name_boards += 1

## Its garage: garage.gd's bay, shutter and clutter in the hole left for it in the north block (as game.gd makes the
## town's, but here: this one is not on the map), a spanner turning over where the car goes (props.gd's, for those)
func _workshop() -> void:
	var along := (NAVE_N - NAVE_S).normalized()
	var out := Vector2(-along.y, along.x)                           # (east: to the road)
	var gar = GarageS.new()
	gar.name = "taller_recoveco"
	gar.id = "recoveco"
	gar.mouth = NAVE_S + along * ((float(SHOP[0]) + float(SHOP[1])) / 2.0)
	gar.out = out
	gar.right = along
	gar.door_w = float(SHOP[1]) - float(SHOP[0])
	gar.door_h = float(SHOP[2])
	gar.w = float(SHOP[1]) - float(SHOP[0]) + GarageS.THICK * 2.0
	gar.d = SHOP_D
	gar.tall = SHOP_TOP
	gar.top = SHOP_TOP
	gar.spot = NAVE_S + along * ((float(SHOP[0]) + float(SHOP[1])) / 2.0) - out * (SHOP_D * 0.55)
	gar.apron = NAVE_S + along * ((float(SHOP[0]) + float(SHOP[1])) / 2.0) + out * 6.0
	gar.middle = 0.0
	add_child(gar)
	var f := Node3D.new()                                           # (garage.gd's frame: x right along the front, z out, at the doorway's foot)
	f.position = Vector3(NAVE_S.x + along.x * (float(SHOP[0]) + float(SHOP[1])) / 2.0, 0.0, NAVE_S.y + along.y * (float(SHOP[0]) + float(SHOP[1])) / 2.0)
	f.rotation.y = atan2(out.x, out.y)
	gar.add_child(f)
	gar._f = f
	var shell := StaticBody3D.new()
	shell.collision_layer = 1
	shell.collision_mask = 0
	f.add_child(shell)
	gar._shell = shell
	gar._bay(SHOP_LOOK)
	gar._shutter(SHOP_LOOK)
	gar._clutter(SHOP_LOOK)
	_spanner = Node3D.new()
	_spanner.position = Vector3(0.0, SHOP_TOP - 0.95, -SHOP_D * 0.55)
	_spanner.scale = Vector3.ONE * 0.5
	_spanner.rotation.z = 0.5
	_spanner.add_child(Parts.part("box", 0xe8eef2, Vector3.ZERO, Vector3(0.28, 1.5, 0.14)))
	_spanner.add_child(Parts.part("box", 0xe8eef2, Vector3(-0.22, 0.85, 0), Vector3(0.2, 0.45, 0.14)))
	_spanner.add_child(Parts.part("box", 0xe8eef2, Vector3(0.22, 0.85, 0), Vector3(0.2, 0.45, 0.14)))
	f.add_child(_spanner)
	taller = gar
	_shop = {"p": NAVE_S + along * ((float(SHOP[0]) + float(SHOP[1])) / 2.0) - out * (SHOP_D * 0.55), "garage": gar}

## Each moment (zonas.gd tick, after the car has been driven and before game.gd's own garages and the prompt): its
## shutter as the town's garages' (game.gd _garages_tick: up when you come on foot or at the wheel, never let down on a
## car in the doorway), and their offer to a car stopped in its bay -- the price told once, and game.gd told the car
## stands in a garage (at_shop, at_garage: it puts them out each time it drives the car, having found none of its own
## there), so the prompt, the horn, the shutter coming down, the mending and the paint and the bill are game.gd's own,
## the same as anywhere. Once mended, nothing more is offered till the car goes out.
func tick(dt: float) -> void:
	if taller == null or G == null or G.get("player") == null or G.player == null:
		return
	var pp: Vector2 = G.player.p
	var car = G.in_car
	var mend = G.mending
	var mine: bool = mend != null and mend["garage"] == taller
	var mouth: Vector2 = taller.mouth
	if pp.distance_squared_to(mouth) > 120.0 * 120.0 and float(taller.open) <= 0.0 and not mine:
		return
	_spanner.rotation.y += dt * 2.0
	taller.want_open = pp.distance_to(mouth) < (26.0 if car != null else 12.0) or bool(taller.holds(pp, 0.0))
	var blocked := false
	for c in G.cars:
		if is_instance_valid(c) and bool(taller.in_doorway(c.p, float(c.spec["len"]))):
			blocked = true
	if car != null and bool(taller.in_doorway(car.p, float(car.spec["len"]))):
		blocked = true
	taller.tick(dt, blocked)
	if mine:
		_served = true
		return
	if car == null or not bool(taller.holds(car.p, 0.0)):         # (nobody in the bay: the next one is told afresh)
		_served = false
		_asked = false
		return
	if _served or mend != null:
		return
	var speed: float = (car.vel as Vector2).length()
	if not bool(taller.holds(car.p, float(car.spec["len"]))) or speed >= 2.5:      # (right in, and stopped: as props.gd repair_at)
		return
	if not bool(G._can_garage(car, _shop)):
		return
	if not _asked:
		_asked = true
		var price: int = int(G._service_price(car))
		G.hud.toast(Loc.t("t_garage_ask") % price, 4.5)
		Sfx.beep(660.0, 0.07, 1, -16.0)
	G.at_shop = _shop
	G.at_garage = true

## Before it: the concrete apron along its front, and trodden earth from that to the road's edge, a little past both
## its ends (PNOA: lorries and vans stand all over it)
func _yard() -> void:
	var a: Vector2 = zone["road_from"]
	var b: Vector2 = zone["road_to"]
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x)                                    # (east)
	var hw: float = zone["road_hw"]
	var along := (NAVE_N - NAVE_S).normalized()
	var out := Vector2(-along.y, along.x)
	var s0 := NAVE_S - along * 1.5
	var s1 := NAVE_N + along * 1.5
	_lay_map(PackedVector2Array([s0, s1, s1 + out * APRON, s0 + out * APRON]), 0.04, "hormigon")
	var y0 := NAVE_S - along * 12.0 + out * APRON
	var y1 := NAVE_N + along * 10.0 + out * APRON
	var e0 := y0 - n * ((y0 - a).dot(n) + hw + 0.15)                 # (the same two, at the road's west edge)
	var e1 := y1 - n * ((y1 - a).dot(n) + hw + 0.15)
	var earth := PackedVector2Array([y0, y1, e1, e0])
	_lay_map(earth, 0.03, "tierra")
	_lay_map(PackedVector2Array([NAVE_S - along * 12.0, s0, s0 + out * APRON, y0]), 0.03, "tierra")
	_lay_map(PackedVector2Array([s1, NAVE_N + along * 10.0, y1, s1 + out * APRON]), 0.03, "tierra")
	_pads.append(PackedVector2Array([NAVE_S - along * 12.6 - out * 0.6, NAVE_N + along * 10.6 - out * 0.6, e1 + along * 0.6, e0 - along * 0.6]))

# ---------------- the signs ----------------
## The blue board before the junction, for who goes north on the old road, on the cemetery's side past its pavement:
## the A-4 to Madrid straight on, to Córdoba to the right. And the same at the junction itself, far off.
func _road_signs() -> void:
	var a: Vector2 = zone["road_from"]
	var b: Vector2 = zone["road_to"]
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x)                                    # (east)
	var p := a + d * ((SIGN_Z - a.y) / d.y)
	_board(p + n * 10.2, p + n * 14.4, true)
	var q := b - d * 26.0
	_board(q + n * 8.2, q + n * 12.4, false)

## a board of the A-4's two ways, from a to b (a its left end as you read it)
func _board(a: Vector2, b: Vector2, solid_posts: bool) -> void:
	var mid := (a + b) / 2.0
	var w := face(a, b, MapData.height(mid) - level)
	var y0 := 1.7
	var h := 2.5
	for x in [0.6, w - 0.6]:
		box(float(x) - 0.07, -0.4, -0.18, 0.14, y0 + h + 0.3, 0.14, 0x8d9296)
		if solid_posts:
			_solid_xf(Vector3(float(x), 1.5, -0.1), Vector3(0.3, 4.0, 0.3))
	box(0.0, y0, -0.04, w, h, 0.04, 0x9a9da1)                              # (its back, of grey steel)
	box(0.0, y0, 0.0, w, h, 0.012, 0xf2f2ee)                               # (its white edge...)
	box(0.06, y0 + 0.06, 0.012, w - 0.12, h - 0.12, 0.014, BLUE)           # (...and its blue)
	var rows := [["up", "Madrid"], ["right", "Córdoba"]]
	for i in range(rows.size()):
		var cy: float = y0 + h - 0.68 - i * 1.12
		_arrow(Vector3(0.52, cy, 0.038), String(rows[i][0]))
		_shield(Vector3(1.5, cy, 0.026), 1.0, 0.5, 88)
		_text(String(rows[i][1]), Vector3(3.08, cy, 0.034), 112, 0xffffff).shaded = true
	if solid_posts:
		var e := (b - a).normalized() * 0.3
		var s := Vector2(-e.y, e.x) * 2.0
		_pads.append(PackedVector2Array([a - e + s, b + e + s, b + e - s, a - e - s]))
	home()
	signs += 1

## the road's own name in its little white-edged box
func _shield(at: Vector3, w: float, h: float, px: int) -> void:
	box(at.x - w / 2.0, at.y - h / 2.0, at.z, w, h, 0.012, 0xf2f2ee)
	box(at.x - w / 2.0 + 0.03, at.y - h / 2.0 + 0.03, at.z + 0.012, w - 0.06, h - 0.06, 0.012, BLUE)
	_text("A-4", Vector3(at.x, at.y, at.z + 0.03), px, 0xffffff).shaded = true

## a white arrow painted on a board, its middle at `at`: "up" or "right"
func _arrow(at: Vector3, way: String) -> void:
	var u := Vector3(0, 1, 0) if way == "up" else Vector3(1, 0, 0)
	var v := Vector3(1, 0, 0) if way == "up" else Vector3(0, -1, 0)
	var tip := at + u * 0.37
	bar(at - u * 0.37, tip - u * 0.05, 0.012, 0.1, 0xffffff)
	bar(tip - u * 0.27 - v * 0.23, tip + u * 0.02, 0.012, 0.1, 0xffffff)
	bar(tip - u * 0.27 + v * 0.23, tip + u * 0.02, 0.012, 0.1, 0xffffff)

## The tall board on the A-4, on the right of its southbound carriageway past where the slip road joins it: how far
## the next towns are (by the road's own kilometres, from 117 here). Behind its fence: nobody reaches it.
func _km_sign(autovia) -> void:
	var sb: PackedVector2Array = autovia.lines.get("sb", PackedVector2Array())
	for i in range(sb.size() - 1):
		var p0: Vector2 = sb[i]
		var p1: Vector2 = sb[i + 1]
		if (p0.y - KM_Z) * (p1.y - KM_Z) > 0.0 or is_equal_approx(p0.y, p1.y):
			continue
		var p := p0.lerp(p1, (KM_Z - p0.y) / (p1.y - p0.y))
		var f := (p1 - p0).normalized()                              # (the way it goes: south)
		var r := Vector2(-f.y, f.x)                                  # (its right: west, the cemetery's side)
		var a := p + r * 6.6
		var b := p + r * 11.2
		var w := face(a, b, MapData.height((a + b) / 2.0) - level)
		var y0 := 2.3
		var h := 3.3
		for x in [0.6, w - 0.6]:
			box(float(x) - 0.09, -0.4, -0.22, 0.18, y0 + h + 0.4, 0.18, 0x8d9296)
		box(0.0, y0, -0.05, w, h, 0.05, 0x9a9da1)
		box(0.0, y0, 0.0, w, h, 0.012, 0xf2f2ee)
		box(0.07, y0 + 0.07, 0.012, w - 0.14, h - 0.14, 0.014, BLUE)
		_shield(Vector3(w / 2.0, y0 + h - 0.55, 0.026), 1.1, 0.5, 96)
		var rows := [["Puerto Lápice", "18"], ["Manzanares", "57"], ["Córdoba", "283"]]
		for i2 in range(rows.size()):
			var cy: float = y0 + h - 1.3 - i2 * 0.7
			_text(String(rows[i2][0]), Vector3(w * 0.4, cy, 0.034), 84, 0xffffff).shaded = true
			_text(String(rows[i2][1]), Vector3(w - 0.6, cy, 0.034), 84, 0xffffff).shaded = true
		home()
		signs += 1
		return
