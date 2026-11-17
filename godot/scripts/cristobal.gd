extends "res://scripts/obra.gd"
## The little hermitage of San Cristóbal, built by the town's own people (the user, 17 November 2026: "Ahora la hermita
## de san Cristóbal. Una pequeña hermita hecha por ciudadanos del pueblo que hace esquina con Ortega y Gasset y
## Carretera antigua Madrid Cádiz (está carretera tiene alias: ruta del colesterol)"; referencias/cristobal/,
## tools/cristobal/).
##
## On the north side of the Calle de Ortega y Gasset, a little before it meets the old road. Catastro's building
## 4602021 (14 m²) for its plan; Street View for the rest (the old road: November 2024, March 2021, 2015, 2009; Ortega y
## Gasset past its front: March 2013, May 2009):
##   - a little house of lime, its gable to the street, a roof of old tiles with its edges finished in lime, a little
##     white dome at the north end of its ridge; a door on its east side and another on its west side (the user, 17 Nov:
##     "Le falta una puerta en este lado"), each under a grille of dark green iron with a crest of scrolls and a round
##     tile over it; brown stone at their corners and jambs;
##   - before each door, a little yard: a low wall of rubble with its coping and a black railing on it, a gate;
##   - along the pavement, a thick white wall; west of it, the next lot's low wall of blocks with a chain-link fence on it;
##   - round it, the sandy lot, its trees, the floodlights' pole, a lattice pylon, the street lamp and a wooden pole.
##
## Frame: origin at the house's south-west corner; +x along the street (east-north-east, towards the old road), +z out of
## its gable, towards the street (south-south-east); y = 0 the ground in front of it, on the pavement.

const READY := true                             # (tools/bake_godot.py looks for this: with it, Catastro's building is not raised here)
const O := Vector2(429.23, -981.43)
const U := Vector2(0.8875, -0.4610)
const LX := 3.75                                # the house: along the street...
const LZ := 3.81                                # ...and deep
const EAVES := 2.55
const RIDGE := 3.55
const WALL_Z := 0.8                             # the white wall along the pavement: its back face
const WALL_T := 0.45
const YARD_X := 6.1                             # the little yard before the door: its east side
const YARD_N := -4.5                            # ...and its north side (the west one's too)
const YARD_W := -1.6                            # the little yard before the west door: its west side

var door: Vector2                               # before the door, on the map (the self-test)
var fl := 0.0                                   # the floor of the house and its yard
var openings := 0

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"cal":              # lime, very white and smooth (Street View: no stains on it)
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.04, 1.035, 1.02)), 0.45)
		"tiles_vieja":      # old tiles, greyed and brown (its UVs in units of 1.6 m down the slope, as obra's roofs)
			var tm: StandardMaterial3D = Tex.mat("roof_tiles", Color(1.0, 0.95, 0.9), true, 1.6)
			tm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = tm
		"piedra":           # the brown stone of its corners and the yard's low wall
			m = Tex.mat("stone_wall", Color(0.82, 0.66, 0.5))
		"bloque":           # the next lot's wall of concrete blocks
			m = Tex.mat("stone_tile_wall", Color(0.78, 0.76, 0.72))
		"losa":
			m = W._tmat(0xc9c0b0, "pavement", 0.9)
		"leaf":
			m = W._tmat(0x6a9a46, "leaf", 1.3)
		"malla":            # the chain-link: see-through
			var mm := StandardMaterial3D.new()
			mm.albedo_color = Color(0.6, 0.62, 0.6, 0.5)
			mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = mm
		"foco":             # the floodlights' and the lamp's glass, lit a little
			var fm := StandardMaterial3D.new()
			fm.albedo_color = Color(0.95, 0.95, 0.9)
			fm.emission_enabled = true
			fm.emission = Color(1.0, 0.92, 0.75)
			fm.emission_energy_multiplier = 0.5
			m = fm
		"azulejo":          # the round tile over the door: white and blue
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.93, 0.95, 1.0)), 0.3)
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	var data: Dictionary = MapData.cristobal
	var o := Vector2(data["o"][0], data["o"][1]) if data.has("o") else O
	var u := Vector2(data["u"][0], data["u"][1]) if data.has("u") else U
	var out := Vector2(-u.y, u.x)
	level = MapData.height(o + u * 1.9 + out * 1.0)
	transform = Transform3D(Basis(Vector3(u.x, 0, u.y), Vector3.UP, Vector3(out.x, 0, out.y)), Vector3(o.x, level, o.y))
	W.add_child(self)
	for q in [Vector2(0, 0), Vector2(LX, 0), Vector2(0, -LZ), Vector2(LX, -LZ), Vector2(YARD_X, YARD_N), Vector2(YARD_X, 0.0), Vector2(YARD_W, YARD_N), Vector2(YARD_W, 0.0)]:
		fl = maxf(fl, ground(q.x, q.y))
	fl += 0.12
	door = spot(LX + 3.2, -LZ / 2.0)
	_house()
	_roof()
	_yard()
	_street_wall()
	_fence()
	_around()
	home()
	_commit()
	_tell_map()

## What stands here, for whoever asks the map how much room there is and for the little map.
func _tell_map() -> void:
	var pts := PackedVector2Array()
	for q in [Vector2(0, 0), Vector2(LX, 0), Vector2(LX, -LZ), Vector2(0, -LZ)]:
		pts.append(spot(q.x, q.y))
	MapData.outlines.append(pts)
	if not MapData._wall_grid.is_empty():
		for i in range(pts.size()):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % pts.size()]
			MapData._grid_add(MapData._wall_grid, a.min(b), a.max(b), [a, b])

## a spot of the map in this frame
func _loc(p: Vector2) -> Vector2:
	var t := transform.affine_inverse() * Vector3(p.x, 0.0, p.y)
	return Vector2(t.x, t.z)

# ---------------- the house ----------------
## Four walls of lime from under the ground; its gables to the street and to the north; a door on its east side and one
## on its west side, each under its grille with the round tile over it; brown stone at their corners and jambs.
func _house() -> void:
	var dr := Rect2(LZ / 2.0 - 0.5, fl, 1.0, 2.05)
	var sides: Array = [[Vector2(0, 0), Vector2(LX, 0), "gable"], [Vector2(LX, 0), Vector2(LX, -LZ), "door"],
		[Vector2(LX, -LZ), Vector2(0, -LZ), "gable"], [Vector2(0, -LZ), Vector2(0, 0), "door"]]
	for sd in sides:
		var a: Vector2 = sd[0]
		var b: Vector2 = sd[1]
		var ln := face(a, b)
		var holes: Array = [dr] if sd[2] == "door" else []
		masonry(0.0, ln, -1.5, EAVES, holes, [], "cal")
		if sd[2] == "gable":
			slab(PackedVector2Array([Vector2(0, EAVES), Vector2(ln, EAVES), Vector2(ln / 2.0, RIDGE)]), 0.0, 0.0, "cal")
		# brown stone at its corners, on the doors' sides only (the gables are plain white: Street View o1, o2)
		if sd[2] == "door":
			for x in [0.0, ln - 0.32]:
				var y := -0.3
				var k := 0
				while y < EAVES - 0.1:
					var h := minf(0.32, EAVES - y)
					var w := 0.32 if k % 2 == 0 else 0.22
					box(x if x == 0.0 else ln - w, y, 0.0, w, h - 0.03, 0.03, "piedra")
					y += h
					k += 1
		if sd[2] == "door":
			# the door: old boards behind; its grille of dark green iron in front, a crest of scrolls over it
			box(dr.position.x, dr.position.y, -DEEP, dr.size.x, dr.size.y, 0.06, 0x4a3020)
			var gz := -0.06
			var green := 0x1f3a2a
			for i in range(9):
				var x := dr.position.x + 0.06 + i * (dr.size.x - 0.12) / 8.0
				box(x - 0.012, dr.position.y, gz, 0.024, dr.size.y, 0.024, green)
			for y in [dr.position.y + 0.1, dr.position.y + 0.9, dr.position.y + 1.7, dr.end.y - 0.03]:
				box(dr.position.x, y, gz - 0.005, dr.size.x, 0.03, 0.03, green)
			for s in [-1.0, 1.0]:                                             # the crest: two scrolls and a ring
				for k in range(7):
					var a0 := PI * k / 7.0
					var a1 := PI * (k + 1) / 7.0
					var c := Vector3(dr.position.x + dr.size.x / 2.0 + s * 0.22, dr.end.y + 0.12, gz)
					bar(c + Vector3(cos(a0) * 0.16 * s, sin(a0) * 0.12, 0), c + Vector3(cos(a1) * 0.16 * s, sin(a1) * 0.12, 0), 0.02, 0.02, green)
			ball(Vector3(dr.position.x + dr.size.x / 2.0, dr.end.y + 0.18, gz), 0.07, green, 1.0, 8, 4)
			# its jambs of brown stone
			for x in [dr.position.x - 0.2, dr.end.x]:
				var y := fl
				var k := 0
				while y < dr.end.y - 0.05:
					box(x + (0.0 if k % 2 == 0 else 0.04), y, 0.0, 0.2 - (0.0 if k % 2 == 0 else 0.04), 0.28, 0.025, "piedra")
					y += 0.31
					k += 1
			# the round tile over it, in its white frame
			slab(oval(dr.position.x + dr.size.x / 2.0, EAVES - 0.22, 0.17, 0.17, 16), 0.02, 0.02, "azulejo")
			slab(oval(dr.position.x + dr.size.x / 2.0, EAVES - 0.22, 0.11, 0.11, 14), 0.03, 0.0, 0x3a62a8)
			openings += 1
		home()
	_prism([Vector2(0, 0), Vector2(LX, 0), Vector2(LX, -LZ), Vector2(0, -LZ)], -1.0, RIDGE)
	yard.append(spot(0.0, 0.0))
	yard.append(spot(LX, 0.0))

## The roof: two slopes of old tiles to the east and the west, their eaves a little out; the edges of the gables and the
## ridge finished in lime, thick and rounded; the little white dome at the north end of the ridge.
func _roof() -> void:
	var o := 0.28
	var mx := LX / 2.0
	var zs := o * 0.6
	var zn := -LZ - o * 0.6
	var drop := (RIDGE - EAVES) / mx * o
	roof([Vector3(mx, RIDGE, zs), Vector3(mx, RIDGE, zn), Vector3(LX + o, EAVES - drop, zn), Vector3(LX + o, EAVES - drop, zs)], "tiles_vieja")
	roof([Vector3(mx, RIDGE, zn), Vector3(mx, RIDGE, zs), Vector3(-o, EAVES - drop, zs), Vector3(-o, EAVES - drop, zn)], "tiles_vieja")
	for z in [zs, zn]:                                                       # the gables' edges, of lime
		bar(Vector3(-o, EAVES - drop + 0.05, z), Vector3(mx, RIDGE + 0.07, z), 0.22, 0.14, "cal")
		bar(Vector3(mx, RIDGE + 0.07, z), Vector3(LX + o, EAVES - drop + 0.05, z), 0.22, 0.14, "cal")
	bar(Vector3(mx, RIDGE + 0.07, zs), Vector3(mx, RIDGE + 0.07, zn), 0.26, 0.14, "cal")
	for x in [-o, LX + o]:                                                   # the eaves: a row of tiles' mouths, in lime
		box(x - 0.06, EAVES - drop - 0.08, zn, 0.12, 0.1, zs - zn, "cal")
	var d := Vector3(mx, RIDGE, -LZ + 0.35)
	cbox(d + Vector3(0, 0.12, 0), Vector3(0.5, 0.3, 0.5), "cal")
	ball(d + Vector3(0, 0.3, 0), 0.27, "cal", 0.9, 10, 5)

# ---------------- the little yards before its doors ----------------
## Before each of its two doors (east and west: Street View o2 and o3), a little yard between the white wall of the
## pavement and the house: a floor of tiles; a low wall of brown rubble with a coping of brick round it, a black railing
## with spear-heads on it, its gate; by the east door a bush and a pot.
func _yard() -> void:
	_little_yard(LX, YARD_X, [[Vector2(YARD_X, WALL_Z), Vector2(YARD_X, YARD_N)], [Vector2(YARD_X, YARD_N), Vector2(LX, YARD_N)], [Vector2(LX, YARD_N), Vector2(LX, -LZ)]])
	_little_yard(YARD_W, 0.0, [[Vector2(0.0, YARD_N), Vector2(YARD_W, YARD_N)], [Vector2(YARD_W, YARD_N), Vector2(YARD_W, WALL_Z)], [Vector2(0.0, -LZ), Vector2(0.0, YARD_N)]])      # (its gate to the north: the next lot's fence runs by its west side)
	ball(Vector3(YARD_X - 0.45, fl + 0.5, YARD_N + 0.45), 0.5, "leaf", 1.3, 8, 5)        # a bush in its north-east corner
	drum(Vector3(LX + 0.4, fl, -0.4), 0.18, 0.22, 0.35, 0x9a5a3a, 10)
	ball(Vector3(LX + 0.4, fl + 0.5, -0.4), 0.25, "leaf", 0.9, 7, 4)

## one little yard from x0 to x1 (between the pavement's wall and YARD_N); `sides`: its low walls, each seen from
## outside (a on its left), the first with the gate
func _little_yard(x0: float, x1: float, sides: Array) -> void:
	flat(PackedVector2Array([Vector2(x0, WALL_Z), Vector2(x1, WALL_Z), Vector2(x1, YARD_N), Vector2(x0, YARD_N)]), fl, "losa")
	var low := minf(minf(ground(x0, YARD_N), ground(x1, YARD_N)), minf(ground(x0, WALL_Z), ground(x1, WALL_Z))) - 0.6
	_hull([Vector3(x0, fl, WALL_Z), Vector3(x1, fl, WALL_Z), Vector3(x1, fl, YARD_N), Vector3(x0, fl, YARD_N),
		Vector3(x0, low, WALL_Z), Vector3(x1, low, WALL_Z), Vector3(x1, low, YARD_N), Vector3(x0, low, YARD_N)])
	var top := fl + 0.45
	for i in range(sides.size()):
		var a: Vector2 = sides[i][0]
		var b: Vector2 = sides[i][1]
		var ln := face(a, b)
		if ln < 0.1:
			home()
			continue
		var g0: float = minf(ground(a.x, a.y), ground(b.x, b.y)) - 0.5
		box(0.0, g0, -0.32, ln, top - g0, 0.32, "piedra")
		box(-0.02, top, -0.34, ln + 0.04, 0.07, 0.36, 0xa05a3c)
		var gate := Rect2(ln / 2.0 - 0.55, 0.0, 1.1, 0.0) if i == 0 else Rect2()
		var n := maxi(2, int(round(ln / 0.13)))
		for k in range(n + 1):
			var x := ln * k / n
			var y0 := top + 0.07
			box(x - 0.011, y0, -0.17, 0.022, 0.9, 0.022, IRON)
			tri(Vector3(x - 0.035, y0 + 0.9, -0.16), Vector3(x + 0.035, y0 + 0.9, -0.16), Vector3(x, y0 + 1.02, -0.16), IRON, Vector3(0, 0, 1))
		box(0.0, top + 0.12, -0.18, ln, 0.03, 0.03, IRON)
		box(0.0, top + 0.86, -0.18, ln, 0.03, 0.03, IRON)
		if gate.size.x > 0.0:                                                # (the gate: a frame, its hinges' posts)
			for x in [gate.position.x, gate.end.x]:
				box(x - 0.03, top + 0.07, -0.19, 0.06, 1.0, 0.06, IRON)
		home()
		var dd := (b - a).normalized()
		var mid := (a + b) / 2.0 + Vector2(dd.y, -dd.x) * 0.16
		solid(Vector3(mid.x, top, mid.y), Vector3(ln, 2.0, 0.32), atan2(-dd.y, dd.x))
		yard.append(spot(a.x, a.y))

# ---------------- the walls along the pavement ----------------
## The thick white wall of lime along the pavement, its top rounded, from the next lot's wall to the yard's corner.
func _street_wall() -> void:
	var x0 := -1.6
	var x1 := YARD_X
	var top := 1.25
	var z0 := WALL_Z
	var z1 := WALL_Z + WALL_T
	var g := minf(ground(x0, z1), ground(x1, z1)) - 0.6
	box(x0, g, z0, x1 - x0, top - g, WALL_T, "cal")
	bar(Vector3(x0, top, (z0 + z1) / 2.0), Vector3(x1, top, (z0 + z1) / 2.0), WALL_T * 0.8, 0.16, "cal")
	cbox(Vector3(x0 + 0.4, 0.6, z1 + 0.003), Vector3(0.3, 0.2, 0.01), 0x8a8a8a)                    # (a meter's little door)
	solid(Vector3((x0 + x1) / 2.0, (g + top) / 2.0, (z0 + z1) / 2.0), Vector3(x1 - x0, top - g, WALL_T))
	yard.append(spot(x0, z1))
	yard.append(spot(x1, z1))

## West of it, the next lot: a low wall of concrete blocks on rubble along the pavement, a chain-link fence on it, posts
## with their braces; and the fence going north along that lot's side, behind the house.
func _fence() -> void:
	var runs: Array = [[Vector2(-13.0, WALL_Z + 0.25), Vector2(-1.6, WALL_Z + 0.25), true], [Vector2(YARD_W - 0.35, WALL_Z), Vector2(YARD_W - 0.35, -14.0), false]]
	for rn in runs:
		var a: Vector2 = rn[0]
		var b: Vector2 = rn[1]
		var ln := face(a, b)
		var g: float = minf(ground(a.x, a.y), ground(b.x, b.y))
		var wall_top := g + (0.85 if rn[2] else 0.35)
		box(0.0, g - 0.5, -0.12, ln, wall_top - g + 0.5, 0.24, "bloque")
		var fence_top := wall_top + 1.6
		quad(Vector3(0, wall_top, 0), Vector3(ln, wall_top, 0), Vector3(ln, fence_top, 0), Vector3(0, fence_top, 0), "malla", Vector3(0, 0, 1))
		var n := maxi(1, int(round(ln / 2.6)))
		for k in range(n + 1):
			var x := ln * k / n
			box(x - 0.025, wall_top, -0.025, 0.05, fence_top - wall_top + 0.05, 0.05, 0x5a3a2a)
		box(0.0, fence_top - 0.02, -0.015, ln, 0.03, 0.03, 0x5a3a2a)
		if rn[2]:                                                            # (a brace leaning on the last post)
			bar(Vector3(ln - 0.1, fence_top - 0.2, 0.0), Vector3(ln - 1.6, g, 0.0), 0.05, 0.05, 0x9a9a9a)
		home()
		var dd := (b - a).normalized()
		var mid := (a + b) / 2.0
		solid(Vector3(mid.x, (g + fence_top) / 2.0, mid.y), Vector3(ln, fence_top - g + 0.5, 0.25), atan2(-dd.y, dd.x))
		yard.append(spot(a.x, a.y))
		yard.append(spot(b.x, b.y))

# ---------------- round it ----------------
## The trees of the next lot and of the sandy lot, the floodlights' pole, the lattice pylon, the street lamp and the
## wooden pole on the pavement.
func _around() -> void:
	for t in [[Vector2(-8.3, -8.3), 9.0, 1.0], [Vector2(-16.9, -4.9), 8.5, 1.0], [Vector2(-4.0, -13.0), 8.0, 1.0],
			[Vector2(12.5, -2.5), 5.0, 0.6], [Vector2(19.0, -10.0), 5.5, 0.6]]:   # (the next lot's trees, behind; young ones in the sandy lot)
		_tree(t[0], t[1], t[2])
	# the floodlights' pole: a tall grey pole, a cross-arm, two lamps
	var fp := Vector2(2.6, -6.4)
	var gf := ground(fp.x, fp.y)
	drum(Vector3(fp.x, gf, fp.y), 0.11, 0.07, 9.0, 0x8a8c8e, 8)
	cbox(Vector3(fp.x, gf + 9.0, fp.y), Vector3(1.1, 0.07, 0.07), 0x6a6c6e)
	for s in [-0.45, 0.45]:
		cbox(Vector3(fp.x + s, gf + 9.12, fp.y + 0.1), Vector3(0.36, 0.26, 0.16), 0x3a3c3e)
		cbox(Vector3(fp.x + s, gf + 9.1, fp.y + 0.19), Vector3(0.3, 0.2, 0.02), "foco")
	solid(Vector3(fp.x, gf + 1.5, fp.y), Vector3(0.3, 3.0, 0.3))
	yard.append(spot(fp.x, fp.y))
	# the lattice pylon by the north-east corner, its box of the transformer
	var pp := Vector2(5.2, -5.9)
	var gp := ground(pp.x, pp.y)
	for c in [Vector2(-0.25, -0.25), Vector2(0.25, -0.25), Vector2(0.25, 0.25), Vector2(-0.25, 0.25)]:
		bar(Vector3(pp.x + c.x, gp, pp.y + c.y), Vector3(pp.x + c.x * 0.4, gp + 9.0, pp.y + c.y * 0.4), 0.05, 0.05, 0x4a4c4e)
	for k in range(1, 12):
		var y := gp + k * 0.8
		var s := 0.25 * (1.0 - 0.6 * k * 0.8 / 9.0)
		for e in [[Vector2(-s, -s), Vector2(s, s)], [Vector2(s, -s), Vector2(-s, s)]]:
			bar(Vector3(pp.x + e[0].x, y - 0.4, pp.y + e[0].y), Vector3(pp.x + e[1].x, y, pp.y + e[1].y), 0.025, 0.025, 0x4a4c4e)
	cbox(Vector3(pp.x, gp + 3.4, pp.y + 0.35), Vector3(0.5, 0.7, 0.3), 0x6a6e70)
	cbox(Vector3(pp.x, gp + 8.6, pp.y), Vector3(1.6, 0.08, 0.08), 0x4a4c4e)
	solid(Vector3(pp.x, gp + 1.5, pp.y), Vector3(0.6, 3.0, 0.6))
	yard.append(spot(pp.x, pp.y))
	# the street lamp at the wall's east end, its arm over the street; a wooden pole on the pavement
	var lp := Vector2(6.6, WALL_Z + WALL_T + 0.35)
	var gl := ground(lp.x, lp.y)
	drum(Vector3(lp.x, gl, lp.y), 0.09, 0.06, 7.0, 0x9a9c9e, 8)
	bar(Vector3(lp.x, gl + 7.0, lp.y), Vector3(lp.x, gl + 7.4, lp.y + 0.9), 0.06, 0.06, 0x9a9c9e)
	bar(Vector3(lp.x, gl + 7.4, lp.y + 0.9), Vector3(lp.x, gl + 7.3, lp.y + 1.5), 0.06, 0.06, 0x9a9c9e)
	cbox(Vector3(lp.x, gl + 7.2, lp.y + 1.5), Vector3(0.28, 0.12, 0.55), 0x7a7c7e)
	cbox(Vector3(lp.x, gl + 7.13, lp.y + 1.5), Vector3(0.22, 0.02, 0.45), "foco")
	solid(Vector3(lp.x, gl + 1.5, lp.y), Vector3(0.25, 3.0, 0.25))
	yard.append(spot(lp.x, lp.y))
	var wp := Vector2(1.8, WALL_Z + WALL_T + 0.3)
	var gw := ground(wp.x, wp.y)
	drum(Vector3(wp.x, gw, wp.y), 0.13, 0.1, 8.5, 0x8a6a4a, 8)
	cbox(Vector3(wp.x, gw + 8.2, wp.y), Vector3(0.9, 0.08, 0.08), 0x6a4a2a)
	solid(Vector3(wp.x, gw + 1.5, wp.y), Vector3(0.3, 3.0, 0.3))
	yard.append(spot(wp.x, wp.y))

## a tree of the lots: a trunk, a round crown in three balls
func _tree(at: Vector2, tall: float, fat := 1.0) -> void:
	var g: float = ground(at.x, at.y)
	var crown: float = tall * 0.24 * fat
	drum(Vector3(at.x, g - 0.3, at.y), 0.24, 0.16, tall * 0.55, 0x6b5a45, 8)
	ball(Vector3(at.x, g + tall * 0.72, at.y), crown, "leaf", 0.85, 10, 6)
	ball(Vector3(at.x + crown * 0.6, g + tall * 0.6, at.y - crown * 0.3), crown * 0.7, "leaf", 0.85, 9, 5)
	ball(Vector3(at.x - crown * 0.55, g + tall * 0.62, at.y + crown * 0.3), crown * 0.68, "leaf", 0.85, 9, 5)
	solid(Vector3(at.x, g + 1.2, at.y), Vector3(0.45, 2.4, 0.45))
	yard.append(spot(at.x, at.y))
