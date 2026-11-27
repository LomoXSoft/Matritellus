extends "res://scripts/obra.gd"
## The windmill and its yard on the Calle de Dulcinea del Toboso: in the game, the "Molino del Tío Gerardo" (the user,
## 15 November 2026: the real one's name is not used). Built by hand the way the Petril and the square were, from
## Catastro, the IGN's aerial photograph and Street View (referencias/molino_tio_gerardo/, tools/molino/).
##
## A white wall with a dark red foot and a coping of tiles runs along the street. Behind it, a round threshing floor
## of cobbles with the mill in the middle: a lime-washed tower of rubble 6.2 m across, a dozen little windows under
## its eaves to see where the wind is from, a dark cap that comes to a point at 11.6 m, four sails of lattice (they
## turn: world.mill_blades) and, behind, the long pole the cap is turned with. To the south, the two-storey "corral":
## a Manchegan courtyard under a glass roof, its galleries of red wood, the big red gate to the street. To the north,
## two low sheds and the old gateway with its carved doors.
##
## Its frame: the middle of the mill; +x along the corral's north wall (east), +z towards the corral (south); y = 0 is
## the floor of the yard. The street is to the west, at x = -12 and beyond.
## (You get in on foot by the red door in the wall, which stands open. The gates are shut.)

const READY := true                                # (tools/bake_godot.py looks for this: with it, Catastro's own blocks are not raised here)
const O := Vector2(-278.0, -729.1)                 # the middle of the mill, on the map
const U := Vector2(0.96823, 0.25006)               # +x of the frame, on the map

# ---- the mill ----
const R0 := 3.25                                   # the tower's radius at its foot...
const R1 := 3.05                                   # ...and under the eaves
const EAVES := 8.1
const CAP := 3.5
const FACING := Vector2(-0.67, 0.74)               # which way the sails look: south-west, to the street and the corral (as in 2024, and in the aerial photograph)
const HUB_UP := 9.6                                # how high the middle of the sails is
const ARM := 7.8                                   # the length of a sail from there
const ERA := 11.5                                  # the radius of the threshing floor

# ---- the wall along the street (its outer face) ----
const WALL_N := Vector2(-12.79, -25.9)
const WALL_S := Vector2(-11.13, 15.6)
const WALL_H := 2.65                               # (2.85 with its coping: 1.42 times the red door, in the street photos)
const THICK := 0.45
const RED_DOOR := -7.0                             # where the red door is (z), and the old gateway
const GATEWAY := Vector2(-25.0, -20.4)

# ---- the corral ----
const C_N := 16.9                                  # its north wall (z); the gallery in front of it comes out to 15.6
const C_S := 29.3
const C_E := 13.4
const C_H := 6.3                                   # its eaves
const GLASS := Rect2(-6.5, 21.5, 18.0, 6.0)        # the glass roof over its courtyard (x, z)

var sails: Node3D                                  # what turns
var door := Vector2.ZERO                           # by the mill's door, on the map (where the miller could stand)

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"granate":          # the dark red painted along the foot of every wall here
			m = Tex.mat("painted_plaster_wall", Color(0.62, 0.17, 0.18))
		"cobble":           # the threshing floor
			m = Tex.mat("square_cobblestone@2.4", Color(0.8, 0.83, 0.9), false)
		"earth":            # the rest of the yard: trodden earth and grit
			m = W._tmat(0xb8a98c, "earth", 2.2)
		"leaf":
			m = W._tmat(0x4f8a48, "leaf", 1.1)
		"grass":
			m = W._tmat(0x86b85c, "grass", 3.0)
		"rough":            # the tower: lime over rubble (white, in the shade too: the user's rule for lime-wash)
			m = _glow(Tex.mat("painted_plaster_wall@3.2", Color(1.0, 0.99, 0.96), false), 0.2)
		"stone":
			m = Tex.mat("granular_concrete", Color(0.95, 0.9, 0.8))
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	level = MapData.height(O)
	transform = Transform3D(Basis(Vector3.UP, atan2(-U.y, U.x)), Vector3(O.x, level, O.y))
	W.add_child(self)
	_floors()
	_mill()
	_street_wall()
	_yard()
	_corral()
	_sheds()
	_east_wall()
	home()
	_commit()
	_tell_map()

## What stands here, for whoever asks the map how much room there is (MapData.room_at: where cars are parked, where
## tables are put out) and for the little map: the tower, the corral, the sheds, the walls.
func _tell_map() -> void:
	var w_in := Vector2(THICK, 0.0)
	var tower: Array = []
	for k in range(8):
		tower.append(Vector2(cos(TAU * k / 8.0), sin(TAU * k / 8.0)) * R0)
	var rings: Array = [tower,
		[WALL_N, WALL_S, WALL_S + w_in, WALL_N + w_in],
		[WALL_S, Vector2(10.7, C_N), Vector2(10.7, 12.6), Vector2(C_E, 12.6), Vector2(C_E, C_S), Vector2(-10.0, C_S)],
		[Vector2(-5.3, -21.8), Vector2(-12.3, -21.8), Vector2(-12.0, -14.0), Vector2(-5.3, -14.0)],
		[Vector2(1.2, -16.3), Vector2(8.1, -17.5), Vector2(1.3, -28.0), Vector2(-5.2, -27.0)],
		[Vector2(8.1, -17.5), Vector2(12.7, -8.0), Vector2(13.3, 0.0), Vector2(13.35, 12.6), Vector2(13.05, 12.6), Vector2(13.0, 0.0), Vector2(12.4, -8.0), Vector2(7.8, -17.4)]]
	for ring in rings:
		var pts := PackedVector2Array()
		for q in ring:
			pts.append(spot((q as Vector2).x, (q as Vector2).y))
		MapData.outlines.append(pts)
		if not MapData._wall_grid.is_empty():          # (somebody has asked already: add it to what they were told)
			for i in range(pts.size()):
				var a: Vector2 = pts[i]
				var b: Vector2 = pts[(i + 1) % pts.size()]
				MapData._grid_add(MapData._wall_grid, a.min(b), a.max(b), [a, b])

# ---------------- small helpers ----------------
func _circle(c: Vector2, r: float, n := 32) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in range(n):
		pts.append(c + Vector2(cos(TAU * k / n), sin(TAU * k / n)) * r)
	return pts

## a frame standing on a round wall of radius r about the middle of the mill, looking out the way `out` points: +x
## along the wall (to the right of whoever looks at it from outside), +y up, +z out
func _on_tower(out: Vector2, r: float, y := 0.0) -> void:
	var o := out.normalized()
	_xf = Transform3D(Basis(Vector3(o.y, 0, -o.x), Vector3.UP, Vector3(o.x, 0, o.y)), Vector3(o.x * r, y, o.y * r))

## a solid along a stretch of the wall being built (face()): from x0 to x1, h high, `thick` behind its face
func _wall_solid(x0: float, x1: float, h: float, thick := THICK, y0 := 0.0) -> void:
	var mid: Vector3 = _xf * Vector3((x0 + x1) / 2.0, y0 + h / 2.0, -thick / 2.0)
	var along: Vector3 = _xf.basis.x
	solid(mid, Vector3(x1 - x0, h, thick), atan2(-along.z, along.x))
	var foot: Vector3 = _xf * Vector3((x0 + x1) / 2.0, 0.0, 0.0)
	yard.append(spot(foot.x, foot.z))

## a stretch of white wall with its dark red foot on the outside, from x0 to x1 of the wall being built
func _wall(x0: float, x1: float, h: float, foot := true, y0 := 0.0, block := true) -> void:
	box(x0, y0, -THICK, x1 - x0, h - y0, THICK, "white")
	if foot and y0 < 0.6:
		box(x0, 0.0, 0.0, x1 - x0, 0.62, 0.035, "granate")
	if block:
		_wall_solid(x0, x1, h - y0, THICK, y0)

## the coping of tiles along the top of a wall: two little slopes, the ridge over its middle
func _coping(x0: float, x1: float, h: float, wide := THICK) -> void:
	var back := -wide - 0.13
	var front := 0.13
	var mid := -wide / 2.0
	roof([Vector3(x0, h + 0.2, mid), Vector3(x1, h + 0.2, mid), Vector3(x1, h + 0.02, front), Vector3(x0, h + 0.02, front)])
	roof([Vector3(x1, h + 0.2, mid), Vector3(x0, h + 0.2, mid), Vector3(x0, h + 0.02, back), Vector3(x1, h + 0.02, back)])
	box(x0, h - 0.02, back + 0.05, x1 - x0, 0.06, front - back - 0.1, "white")
	bar(Vector3(x0, h + 0.21, mid), Vector3(x1, h + 0.21, mid), 0.13, 0.07, ridge_hex)

## a hedge: clipped green, from a to b on the plan, `tall` high
func _hedge(a: Vector2, b: Vector2, tall := 1.5, wide := 0.8) -> void:
	var d: Vector2 = b - a
	var n: int = maxi(1, int(round(d.length() / (wide * 0.95))))
	for k in range(n):
		var at: Vector2 = a.lerp(b, (k + 0.5) / n)
		var wob: float = sin(at.x * 3.1 + at.y * 1.7)
		var h: float = tall * (1.0 + 0.07 * wob)
		_clump(Vector3(at.x, h * 0.5, at.y), Vector3(wide * 0.82, h * 0.56, wide * 0.82))
	solid(Vector3((a.x + b.x) / 2.0, tall / 2.0, (a.y + b.y) / 2.0), Vector3(d.length(), tall, wide * 0.8), atan2(-d.y, d.x))

func _clump(mid: Vector3, size: Vector3, key = "leaf") -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = Parts.mesh("ball")
	mi.material_override = _material(key)
	mi.position = mid
	mi.scale = size
	add_child(mi)

## a small tree: a thin trunk and a round head
func _tree(at: Vector2, tall := 2.2, head := 1.5) -> void:
	drum(Vector3(at.x, 0, at.y), 0.1, 0.08, tall, 0x6b5442, 8)
	_clump(Vector3(at.x, tall + head * 0.45, at.y), Vector3(head, head * 0.9, head) * 0.5)
	_clump(Vector3(at.x + head * 0.2, tall + head * 0.25, at.y - head * 0.15), Vector3(head, head * 0.8, head) * 0.38)
	solid(Vector3(at.x, 1.2, at.y), Vector3(0.4, 2.4, 0.4))
	yard.append(spot(at.x, at.y))

## what has been built since `keep` was set aside becomes meshes of `into`, and building goes on as before
func _commit_into(into: Node3D, keep: Dictionary) -> void:
	for key in _tools:
		var mi := MeshInstance3D.new()
		mi.mesh = (_tools[key] as SurfaceTool).commit()
		mi.material_override = _material(key)
		into.add_child(mi)
	_tools = keep

# ---------------- the ground ----------------
func _floors() -> void:
	# the yard inside the walls: earth; the threshing floor: cobbles, with a ring of bigger stones round its edge
	flat(PackedVector2Array([Vector2(-12.5, -25.7), Vector2(-5.2, -27.0), Vector2(1.2, -16.3), Vector2(8.1, -17.5), Vector2(12.7, -8.0), Vector2(13.3, 0.0), Vector2(13.3, C_N), Vector2(-11.1, C_N)]), 0.02, "earth")
	flat(_circle(Vector2.ZERO, ERA, 48), 0.04, "cobble")
	for k in range(48):
		var a0: float = TAU * k / 48.0
		var a1: float = TAU * (k + 1) / 48.0
		var p0 := Vector2(cos(a0), sin(a0))
		var p1 := Vector2(cos(a1), sin(a1))
		flat(PackedVector2Array([p0 * (ERA - 0.35), p1 * (ERA - 0.35), p1 * ERA, p0 * ERA]), 0.055, "stone")
	# the path from the red door: it bends round to the floor between two kerbs
	var last_in := Vector2.ZERO
	var last_out := Vector2.ZERO
	for k in range(9):
		var a: float = lerpf(deg_to_rad(212.0), deg_to_rad(255.0), k / 8.0)
		var p_in := Vector2(cos(a), sin(a)) * (ERA + 0.2)
		var p_out := Vector2(cos(a), sin(a)) * (ERA + 2.0)
		if k > 0:
			flat(PackedVector2Array([last_in, p_in, p_out, last_out]), 0.05, "cobble")
			bar(Vector3(last_out.x, 0.09, last_out.y), Vector3(p_out.x, 0.09, p_out.y), 0.16, 0.14, "stone")
		last_in = p_in
		last_out = p_out
	# the grass at the foot of the sheds
	flat(PackedVector2Array([Vector2(-4.0, -17.6), Vector2(8.6, -17.2), Vector2(9.1, -15.9), Vector2(-4.0, -16.2)]), 0.06, "grass")

# ---------------- the mill ----------------
func _mill() -> void:
	drum(Vector3(0, -0.4, 0), R0 + 0.03, R1, EAVES + 0.4, "rough", 32)
	drum(Vector3(0, EAVES - 0.32, 0), R1 + 0.025, R1 + 0.025, 0.34, 0x2a2622, 32)          # the dark band under the cap
	solid(Vector3(0, EAVES / 2.0, 0), Vector3(R0 * 1.85, EAVES, R0 * 1.85))
	solid(Vector3(0, EAVES / 2.0, 0), Vector3(R0 * 1.85, EAVES, R0 * 1.85), PI / 4.0)
	yard.append(spot(0.0, 0.0))
	# the door, in its arched hollow, on the side of the path; another opposite (a mill has two: one is always out of the sails' way)
	for out: Vector2 in [Vector2(-0.42, -0.91), Vector2(0.42, 0.91)]:
		_on_tower(out, R0 - 0.04)
		arched(0.0, 0.0, 1.95, 0.66, 0.05, 0xd9d2c2)
		box(-0.66, 0.0, 0.0, 1.32, 1.95, 0.05, 0xd9d2c2)
		box(-0.5, 0.0, 0.05, 1.0, 2.0, 0.04, "wood")
		for k in range(1, 4):
			box(-0.5 + k * 0.25 - 0.012, 0.0, 0.09, 0.024, 2.0, 0.015, 0x2c2019)
		box(-0.62, 0.0, 0.05, 1.24, 0.07, 0.25, "stone")
		box(0.3, 0.95, 0.09, 0.05, 0.16, 0.04, IRON)
	door = spot(-0.42 * (R0 + 1.3), -0.91 * (R0 + 1.3))
	# its little windows: twelve under the eaves, one half-way up over the door
	for k in range(12):
		var a: float = TAU * (k + 0.5) / 12.0
		_on_tower(Vector2(cos(a), sin(a)), R1 + 0.03, EAVES - 0.86)
		box(-0.16, 0.0, 0.0, 0.32, 0.34, 0.03, 0x1c1814)
	_on_tower(Vector2(-0.42, -0.91), lerpf(R0, R1, 0.52), 4.2)
	box(-0.2, 0.0, 0.0, 0.4, 0.5, 0.05, 0x1c1814)
	box(-0.26, -0.06, 0.0, 0.52, 0.06, 0.1, "stone")
	home()
	# the cap: a dark cone of boards, its edge out past the wall
	var dark := 0x35271f
	drum(Vector3(0, EAVES, 0), R1 + 0.5, 0.1, CAP, dark, 28)
	drum(Vector3(0, EAVES - 0.07, 0), R1 + 0.52, R1 + 0.5, 0.08, 0x231a15, 28)
	for k in range(14):
		var a: float = TAU * k / 14.0
		var d := Vector3(cos(a), 0, sin(a))
		bar(Vector3(0, EAVES + 0.03, 0) + d * (R1 + 0.49), Vector3(0, EAVES + CAP * 0.97, 0) + d * 0.12, 0.07, 0.05, 0x4b392e)
	drum(Vector3(0, EAVES + CAP - 0.05, 0), 0.07, 0.03, 0.55, IRON, 6)
	# the shaft comes out through the cap, climbing a little; the sails are on its end
	var f := FACING.normalized()
	var tilt := deg_to_rad(10.0)
	var axis := Vector3(f.x * cos(tilt), sin(tilt), f.y * cos(tilt))
	var hub := Vector3(f.x * (R1 + 1.25), HUB_UP, f.y * (R1 + 1.25))
	bar(hub - axis * 3.6, hub + axis * 0.5, 0.42, 0.42, 0x3a2c22)
	sails = Node3D.new()
	sails.position = hub
	sails.rotation = Vector3(-tilt, atan2(f.x, f.y), 0.0)        # (its own z runs out along the shaft: the game turns it about that)
	add_child(sails)
	var keep := _tools
	_tools = {}
	var wood := 0x3d2f25
	var grey := 0x655646
	for i in range(4):
		_xf = Transform3D(Basis(Vector3(0, 0, 1), i * PI / 2.0), Vector3.ZERO)
		bar(Vector3(0, -0.4, 0.08 if i % 2 == 0 else 0.26), Vector3(0, ARM, 0.08 if i % 2 == 0 else 0.26), 0.17, 0.17, wood)
		var z := 0.2 if i % 2 == 0 else 0.38
		for rail in [-0.5, 0.45, 0.95, 1.45]:                       # (the lattice: wider behind the spar than in front of it)
			bar(Vector3(rail, 1.3, z), Vector3(rail, ARM, z), 0.06, 0.05, grey)
		for k in range(14):
			var y: float = lerpf(1.3, ARM, k / 13.0)
			bar(Vector3(-0.5, y, z + 0.04), Vector3(1.45, y, z + 0.04), 0.06, 0.05, grey)
	home()
	_commit_into(sails, keep)
	# behind, the long pole the cap is turned with comes down to the ground, and two props to the cap from it
	var back := Vector3(-f.x, 0, -f.y)
	var foot: Vector3 = back * 8.3 + Vector3(0, 0.15, 0)
	bar(back * (R1 + 0.1) + Vector3(0, EAVES + 0.55, 0), foot, 0.2, 0.2, 0x33271f)
	var side := Vector3(-back.z, 0, back.x)
	for s in [-1.0, 1.0]:
		bar(back * (R1 * 0.5) + side * s * (R1 * 0.87) + Vector3(0, EAVES + 0.25, 0), back * 5.4 + Vector3(0, 3.25, 0), 0.11, 0.11, 0x33271f)
	solid(Vector3(foot.x, 0.5, foot.z), Vector3(0.5, 1.0, 0.5))
	# the stone posts round the floor that the pole is tied to
	for k in range(12):
		var a: float = TAU * (k + 0.5) / 12.0
		var p := Vector2(cos(a), sin(a)) * (ERA - 1.1)
		if absf(angle_difference(a, deg_to_rad(230.0))) < 0.5:      # (none in the way in from the path)
			continue
		drum(Vector3(p.x, 0, p.y), 0.17, 0.13, 0.85, "stone", 8)
		solid(Vector3(p.x, 0.45, p.y), Vector3(0.36, 0.9, 0.36))
		yard.append(spot(p.x, p.y))

# ---------------- the wall along the street ----------------
func _street_wall() -> void:
	var ln := face(WALL_N, WALL_S)
	var k := ln / (WALL_S.y - WALL_N.y)              # metres of wall for each metre of z
	var at := func(z: float) -> float: return (z - WALL_N.y) * k
	# the old gateway: a taller piece of wall under its own little roof on wooden brackets, and the carved doors
	var g0: float = at.call(GATEWAY.x)
	var g1: float = at.call(GATEWAY.y)
	var gh := 3.65
	var dw := 3.1
	var dm: float = at.call(-22.75)
	_wall(0.0, g0, WALL_H)
	_coping(0.0, g0, WALL_H)
	_wall(g0, dm - dw / 2.0, gh)
	_wall(dm + dw / 2.0, g1, gh)
	_wall(dm - dw / 2.0, dm + dw / 2.0, gh, false, 3.15, false)
	_wall_solid(dm - dw / 2.0, dm + dw / 2.0, 3.15, 0.2)
	box(dm - dw / 2.0, 0.0, -0.22, dw, 3.15, 0.1, 0x4a3324)
	for s in [-1.0, 1.0]:                              # (each leaf: a frame, and panels set cornerwise)
		var lx: float = dm + s * dw / 4.0
		for q in [[0.0, 0.08, dw / 2.0 - 0.06, 0.12], [0.0, 3.0, dw / 2.0 - 0.06, 0.12], [0.0, 1.55, dw / 2.0 - 0.06, 0.1]]:
			box(lx - q[2] / 2.0, q[1], -0.12, q[2], q[3], 0.05, 0x2a1d15)
		for e in [-1.0, 1.0]:
			box(lx + e * (dw / 4.0 - 0.07) - 0.05, 0.08, -0.12, 0.1, 3.0, 0.05, 0x2a1d15)
		for j in range(2):
			tbox(Transform3D(Basis(Vector3(0, 0, 1), PI / 4.0).scaled_local(Vector3(0.7, 0.7, 0.05)), Vector3(lx, 0.85 + j * 1.48, -0.1)), 0x33231a)
	box(dm - 0.04, 0.0, -0.11, 0.08, 3.15, 0.06, 0x2a1d15)
	box(dm - dw / 2.0 - 0.06, 3.13, -0.2, dw + 0.12, 0.18, 0.24, 0x33271f)                    # the beam over them
	for j in range(7):                                                                         # the brackets, and the tiles on them
		var bx: float = lerpf(g0 + 0.15, g1 - 0.15, j / 6.0)
		box(bx - 0.05, gh - 0.16, 0.0, 0.1, 0.12, 0.42, 0x33271f)
	roof([Vector3(g0 - 0.15, gh + 0.34, -THICK / 2.0), Vector3(g1 + 0.15, gh + 0.34, -THICK / 2.0), Vector3(g1 + 0.15, gh - 0.02, 0.55), Vector3(g0 - 0.15, gh - 0.02, 0.55)])
	roof([Vector3(g1 + 0.15, gh + 0.34, -THICK / 2.0), Vector3(g0 - 0.15, gh + 0.34, -THICK / 2.0), Vector3(g0 - 0.15, gh + 0.1, -THICK - 0.2), Vector3(g1 + 0.15, gh + 0.1, -THICK - 0.2)])
	bar(Vector3(g0 - 0.15, gh + 0.35, -THICK / 2.0), Vector3(g1 + 0.15, gh + 0.35, -THICK / 2.0), 0.13, 0.07, ridge_hex)
	# from there to the red door: the wall of the shed (a little shuttered window in it), then plain wall
	var d0: float = at.call(RED_DOOR - 0.5)
	var d1: float = at.call(RED_DOOR + 0.5)
	_wall(g1, d0, WALL_H)
	_coping(g1, d0, WALL_H)
	var wx: float = at.call(-20.6)
	box(wx - 0.3, 1.25, 0.0, 0.6, 0.8, 0.05, 0x2a1d2a)
	box(wx - 0.36, 1.19, 0.0, 0.72, 0.06, 0.09, "white")
	box(at.call(-17.4) - 0.17, 1.45, 0.0, 0.34, 0.3, 0.07, 0xb9b6ae)
	# the red door: open, its leaf turned back inside
	_wall(d0, d1, WALL_H, false, 2.15, false)
	_coping(d0, d1, WALL_H)
	_wall_solid(d0, d1, WALL_H - 2.15, THICK, 2.15)
	var red := 0xa3302b
	tbox(Transform3D(Basis(Vector3.UP, deg_to_rad(100.0)).scaled_local(Vector3(1.0, 2.1, 0.05)), Vector3(d0 + 0.04, 1.05, -THICK - 0.5)), red)
	box(d0 - 0.07, 0.0, -THICK - 0.02, 0.09, 2.13, THICK + 0.07, red)
	box(d1 - 0.02, 0.0, -THICK - 0.02, 0.09, 2.13, THICK + 0.07, red)
	box(d0 - 0.07, 2.13, -THICK - 0.02, d1 - d0 + 0.14, 0.09, THICK + 0.07, red)
	box(d0 + 0.02, 0.0, -THICK, d1 - d0 - 0.04, 0.05, THICK + 0.1, "stone")
	# on to the taller piece of wall in front of the mill, and to the corner of the corral
	var h0: float = at.call(3.4)
	var h1: float = at.call(7.6)
	_wall(d1, h0, WALL_H)
	_coping(d1, h0, WALL_H)
	_wall(h0, h1, 3.35)
	box(h0 - 0.05, 3.35, -THICK - 0.04, h1 - h0 + 0.1, 0.12, THICK + 0.08, 0xe9e4d8)
	_wall(h1, ln, WALL_H)
	_coping(h1, ln, WALL_H)
	# the panel of painted tiles by the big gate: a mill, and whose it is
	var px: float = at.call(14.75)
	box(px - 0.46, 1.85, 0.0, 0.92, 0.72, 0.03, 0xf2efe6)
	for e in [[-0.46, 1.85, 0.92, 0.04], [-0.46, 2.53, 0.92, 0.04], [-0.46, 1.85, 0.04, 0.72], [0.42, 1.85, 0.04, 0.72]]:
		box(px + e[0], e[1], 0.0, e[2], e[3], 0.036, 0x2d5aa0)
	box(px - 0.33, 1.98, 0.0, 0.12, 0.27, 0.036, 0x2d5aa0)                                 # (the mill of the picture: a tower, its cap, its sails)
	tbox(Transform3D(Basis(Vector3(0, 0, 1), PI / 4.0).scaled_local(Vector3(0.36, 0.028, 0.02)), Vector3(px - 0.27, 2.31, 0.036)), 0x2d5aa0)
	tbox(Transform3D(Basis(Vector3(0, 0, 1), -PI / 4.0).scaled_local(Vector3(0.36, 0.028, 0.02)), Vector3(px - 0.27, 2.31, 0.036)), 0x2d5aa0)
	_text("MOLINO DEL\nTÍO GERARDO", Vector3(px + 0.13, 2.2, 0.04), 40, 0x2d5aa0, 0.0024)
	# the terrace behind that last piece of wall: a flat roof with an iron rail round it, and the white chimney
	home()
	var tx0 := -10.65
	var tx1 := -6.6
	var tz0 := 7.6
	var th := 2.9
	box(tx0, 0.0, tz0, tx1 - tx0, th, 15.6 - tz0, "white")
	solid(Vector3((tx0 + tx1) / 2.0, th / 2.0, (tz0 + 15.6) / 2.0), Vector3(tx1 - tx0, th, 15.6 - tz0))
	for q in [[Vector3(tx0 + 0.05, th, tz0), Vector3(tx1, th, tz0)], [Vector3(tx1, th, tz0), Vector3(tx1, th, 15.6)], [Vector3(tx0 + 0.05, th, tz0), Vector3(tx0 + 0.05, th, 15.6)]]:
		_railing(q[0], q[1], 1.0)
	var ch := Vector3(-10.92, WALL_H, 11.6)
	cbox(ch + Vector3(0, 1.15, 0), Vector3(0.75, 2.3, 0.75), "white")
	cbox(ch + Vector3(0, 2.35, 0), Vector3(0.98, 0.1, 0.98), "white")
	for s in [-1.0, 1.0]:
		tbox(Transform3D(Basis(Vector3(1, 0, 0), s * 0.6).scaled_local(Vector3(0.98, 0.06, 0.7)), ch + Vector3(0, 2.62, s * 0.24)), "white")
	# a white mast with its cross-piece, inside the wall north of that
	drum(Vector3(-11.15, 0, -0.6), 0.06, 0.05, 6.4, 0xeeeae0, 8)
	bar(Vector3(-11.15, 5.9, -1.4), Vector3(-11.15, 5.9, 0.2), 0.06, 0.06, 0xeeeae0)

## an iron rail from a to b: uprights with a point, a bar along the top and one near the foot
func _railing(a: Vector3, b: Vector3, tall := 1.0) -> void:
	bar(a + Vector3(0, tall, 0), b + Vector3(0, tall, 0), 0.04, 0.04, IRON)
	bar(a + Vector3(0, 0.12, 0), b + Vector3(0, 0.12, 0), 0.04, 0.03, IRON)
	var n: int = maxi(2, int(a.distance_to(b) / 0.14))
	for k in range(n + 1):
		var p: Vector3 = a.lerp(b, k / float(n))
		bar(p, p + Vector3(0, tall + (0.12 if k % 6 == 0 else 0.0), 0), 0.022, 0.022, IRON)

# ---------------- the yard ----------------
func _yard() -> void:
	# the tall hedge round the floor on the east and the south, and a stretch of it inside the street wall
	for arc in [[-40.0, 62.0], [98.0, 120.0]]:
		var last := Vector2.ZERO
		for k in range(9):
			var a: float = deg_to_rad(lerpf(arc[0], arc[1], k / 8.0))
			var p := Vector2(cos(a), sin(a)) * (ERA + 0.75)
			if k > 0:
				_hedge(last, p, 1.7, 0.9)
			last = p
	_hedge(Vector2(-10.9, -4.6), Vector2(-10.55, 3.2), 2.6, 0.7)
	_hedge(Vector2(-4.0, -16.9), Vector2(8.7, -16.5), 1.1, 0.8)
	# the iron fence between the path and the trees to the north
	_railing(Vector3(-10.4, 0, -9.7), Vector3(-4.7, 0, -13.7), 1.25)
	for t in [Vector2(-3.9, -14.4), Vector2(2.6, -13.6), Vector2(7.2, -12.0), Vector2(9.6, -8.6), Vector2(5.8, -15.2)]:
		_tree(t, 2.0 + fmod(absf(t.x), 0.7), 1.5 + fmod(absf(t.y), 0.5))
	# an old millstone leaning on the hedge, and a stone trough
	var ms := Vector3(9.4, 0.0, -3.4)
	drum(ms, 0.72, 0.72, 0.3, "stone", 18)
	drum(ms + Vector3(0, 0.3, 0), 0.12, 0.12, 0.012, 0x3a342c, 10)
	solid(ms + Vector3(0, 0.2, 0), Vector3(1.3, 0.4, 1.3))
	box(-9.9, 0.0, 5.2, 0.7, 0.45, 1.6, "stone")
	solid(Vector3(-9.55, 0.3, 6.0), Vector3(0.7, 0.6, 1.6))
	# two lanterns on posts by the path and by the corral's gallery (lights.gd lights them)
	for q in [Vector2(-8.4, -9.6), Vector2(-3.0, 13.6), Vector2(9.0, 12.2)]:
		var o := Vector3(q.x, 0, q.y)
		drum(o, 0.14, 0.1, 0.4, IRON, 8)
		drum(o + Vector3(0, 0.4, 0), 0.06, 0.05, 2.5, IRON, 8)
		cbox(o + Vector3(0, 3.15, 0), Vector3(0.28, 0.48, 0.28), 0xfff1c4)
		drum(o + Vector3(0, 3.39, 0), 0.24, 0.04, 0.22, IRON, 8)
		solid(o + Vector3(0, 1.5, 0), Vector3(0.3, 3.0, 0.3))
		W.lamp_spots.append(transform * (o + Vector3(0, 3.15, 0)))
		yard.append(spot(q.x, q.y))

# ---------------- the corral ----------------
func _corral() -> void:
	var red := 0x9c2f24                                   # the red of its woodwork
	var w_s := Vector2(-10.0, C_S)                        # its corners on the street (a little turned from the real line: the map's street comes half a metre closer at this end)
	var w_n: Vector2 = WALL_S.lerp(w_s, (C_N - WALL_S.y) / (C_S - WALL_S.y))
	# --- to the street: the big red gate under its arch, a little roof of tiles over it, windows behind iron upstairs ---
	var ln := face(Vector2(WALL_S.x, WALL_S.y), w_s)
	var gate := Rect2(0.5, -0.3, 3.3, 3.45)               # (its hole: the arch is drawn over the top of it)
	var ups: Array = [Rect2(1.2, 3.95, 1.1, 1.4), Rect2(6.6, 3.9, 1.3, 1.6), Rect2(9.7, 3.9, 1.3, 1.6)]
	var small := Rect2(4.2, 4.75, 0.5, 0.6)
	var low: Array = [Rect2(7.3, 1.2, 0.4, 0.5)]
	masonry(0.0, ln, -0.5, C_H, [gate, small] + ups + low, [], "white", "white")
	box(0.0, 0.0, 0.0, 0.5, 0.62, 0.035, "granate")
	box(3.7, 0.0, 0.0, ln - 3.7, 0.62, 0.035, "granate")
	box(gate.position.x, 0.0, -0.2, gate.size.x, gate.end.y, 0.06, red)                    # the gate's two leaves, shut
	box(gate.position.x + gate.size.x / 2.0 - 0.02, 0.0, -0.14, 0.04, gate.end.y, 0.03, 0x7a221b)
	box(gate.position.x + gate.size.x - 1.05, 0.0, -0.14, 0.03, 2.0, 0.03, 0x7a221b)        # (the little door cut in one of them)
	box(gate.position.x + gate.size.x - 1.05, 2.0, -0.14, 0.95, 0.03, 0.03, 0x7a221b)
	var gm: float = gate.position.x + gate.size.x / 2.0
	for side in [-1.0, 1.0]:                              # (the corners of the hole filled in white up to the curve of the arch)
		var corner := Vector3(gm + side * gate.size.x / 2.0, gate.end.y, -0.13)
		var last := Vector3(corner.x, gate.end.y - 0.75, -0.13)
		for j in range(1, 7):
			var th: float = j / 6.0 * PI / 2.0
			var pt := Vector3(gm + side * gate.size.x / 2.0 * cos(th), gate.end.y - 0.75 + 0.75 * sin(th), -0.13)
			if side < 0.0:
				tri(corner, pt, last, "white", Vector3(0, 0, 1))
			else:
				tri(corner, last, pt, "white", Vector3(0, 0, 1))
			last = pt
	for j in range(9):                                    # the little roof over the gate, on its brackets
		box(lerpf(-0.2, 5.2, j / 8.0) - 0.04, 3.3, 0.0, 0.08, 0.1, 0.5, 0x33271f)
	roof([Vector3(-0.35, 3.74, 0.0), Vector3(5.4, 3.74, 0.0), Vector3(5.4, 3.4, 0.66), Vector3(-0.35, 3.4, 0.66)])
	for r: Rect2 in ups:
		box(r.position.x, r.position.y, -DEEP + 0.02, r.size.x, r.size.y, 0.03, 0x39424a)
		grille(r, 0.14)
	box(small.position.x, small.position.y, -DEEP + 0.02, small.size.x, small.size.y, 0.03, 0x7a221b)
	for bx in [0.12, 0.25, 0.38]:
		box(small.position.x + bx - 0.012, small.position.y, -0.08, 0.024, small.size.y, 0.024, 0x7a221b)
	roof([Vector3(small.position.x - 0.15, small.end.y + 0.32, 0.0), Vector3(small.end.x + 0.15, small.end.y + 0.32, 0.0), Vector3(small.end.x + 0.15, small.end.y + 0.14, 0.3), Vector3(small.position.x - 0.15, small.end.y + 0.14, 0.3)])
	box(low[0].position.x, low[0].position.y, -DEEP + 0.02, 0.4, 0.5, 0.03, 0x7a221b)
	box(8.6, 1.3, 0.0, 0.3, 0.42, 0.08, 0xcfcabb)                                           # (a meter box)
	for j in range(int(ln / 0.6) + 1):                    # the ends of the red rafters under the eaves
		box(j * 0.6, C_H - 0.14, 0.0, 0.09, 0.12, 0.4, red)
	_wall_solid(0.0, ln, C_H, 0.5)
	home()
	# --- the south wall: blind, on the neighbour's yard; and the east one ---
	_plain(w_s, Vector2(C_E, C_S), -0.5, C_H, "white")
	_plain(Vector2(C_E, C_S), Vector2(C_E, 12.6), -0.5, C_H, "brick")       # (its back, on the fields, is of bare brick)
	_plain(Vector2(C_E, 12.6), Vector2(10.7, 12.6), -0.5, C_H, "brick")
	_plain(Vector2(10.7, 12.6), Vector2(10.7, C_N), -0.5, C_H, "white")
	solid(Vector3((w_s.x + C_E) / 2.0, C_H / 2.0, C_S - 0.25), Vector3(C_E - w_s.x, C_H, 0.5))
	solid(Vector3(C_E - 0.25, C_H / 2.0, (12.6 + C_S) / 2.0), Vector3(0.5, C_H, C_S - 12.6))
	solid(Vector3(12.05, C_H / 2.0, (12.6 + C_N) / 2.0), Vector3(2.7, C_H, C_N - 12.6))
	yard.append(spot(C_E, C_S))
	yard.append(spot(w_s.x, C_S))
	# --- to the mill: the gallery. Posts of red wood below, a balcony with its rail and a row of glazed doors above ---
	ln = face(Vector2(10.7, C_N), w_n + Vector2(0.55, 0.0))
	var doors: Array = []
	for j in range(5):
		doors.append(Rect2(1.6 + j * 4.3, -0.3, 1.5, 2.5))
	var glazed: Array = []
	for j in range(7):
		glazed.append(Rect2(1.0 + j * 3.0, 3.35, 1.7, 2.1))
	masonry(0.0, ln, -0.5, C_H, doors + glazed, [], "white", "white")
	for r: Rect2 in doors:
		box(r.position.x, 0.0, -DEEP + 0.02, r.size.x, r.end.y, 0.04, red)
		for e in [0.33, 0.66]:
			box(r.position.x + r.size.x * e - 0.015, 0.0, -DEEP + 0.05, 0.03, r.end.y, 0.02, 0x7a221b)
	for r: Rect2 in glazed:
		box(r.position.x, r.position.y, -DEEP + 0.02, r.size.x, r.size.y, 0.03, 0x39424a)
		for e in [0.0, 0.5, 1.0]:
			box(r.position.x + (r.size.x - 0.07) * e, r.position.y, -DEEP + 0.04, 0.07, r.size.y, 0.04, red)
		for e in [0.0, 0.45, 1.0]:
			box(r.position.x, r.position.y + (r.size.y - 0.07) * e, -DEEP + 0.04, r.size.x, 0.07, 0.04, red)
	var out := 1.3                                         # (how far the gallery comes out)
	box(0.0, 3.05, 0.0, ln, 0.16, out, red)                # its floor, on a beam
	box(0.0, 3.21, 0.0, ln, 0.05, out, 0x6b4a36)
	for j in range(9):
		var gx: float = lerpf(0.12, ln - 0.12, j / 8.0)
		box(gx - 0.09, 0.3, out - 0.18, 0.18, 2.75, 0.18, red)                 # the posts below, each on its stone
		box(gx - 0.16, 0.0, out - 0.25, 0.32, 0.3, 0.32, "stone")
		box(gx - 0.2, 2.85, out - 0.22, 0.4, 0.2, 0.26, red)                   # (the shoe under the beam)
		box(gx - 0.07, 3.26, out - 0.14, 0.14, C_H - 3.5, 0.14, red)           # the posts above
		solid(_xf * Vector3(gx, 1.5, out - 0.09), Vector3(0.26, 3.0, 0.26))
	bar(Vector3(0.0, 4.2, out - 0.07), Vector3(ln, 4.2, out - 0.07), 0.07, 0.07, red)
	bar(Vector3(0.0, 3.4, out - 0.07), Vector3(ln, 3.4, out - 0.07), 0.06, 0.05, red)
	for j in range(int(ln / 0.16)):
		box(0.08 + j * 0.16, 3.4, out - 0.085, 0.035, 0.8, 0.035, red)
	box(0.0, C_H - 0.26, out - 0.16, ln, 0.18, 0.18, red)                      # the beam its roof sits on
	roof([Vector3(-0.3, C_H + 0.05, 0.0), Vector3(ln + 0.3, C_H + 0.05, 0.0), Vector3(ln + 0.3, C_H - 0.18, out + 0.45), Vector3(-0.3, C_H - 0.18, out + 0.45)])
	home()
	_plain(w_n + Vector2(0.55, 0.0), w_n, -0.5, C_H, "white")
	solid(Vector3((10.7 + w_n.x) / 2.0, C_H / 2.0, C_N + 0.25), Vector3(10.7 - w_n.x, C_H, 0.5))
	# --- its roofs: tiles down to the eaves all round, and the glass over the courtyard in the middle ---
	var e0 := Vector2(w_n.x - 0.4, C_N - 0.05)            # the eaves' corners (the street side follows the street)
	var e1 := Vector2(C_E + 0.35, C_N - 0.05)
	var e2 := Vector2(C_E + 0.35, C_S + 0.35)
	var e3 := Vector2(w_s.x - 0.4, C_S + 0.35)
	var top := C_H + 1.15
	var g0 := Vector2(GLASS.position.x, GLASS.position.y)
	var g1 := Vector2(GLASS.end.x, GLASS.position.y)
	var g2 := Vector2(GLASS.end.x, GLASS.end.y)
	var g3 := Vector2(GLASS.position.x, GLASS.end.y)
	var up := func(p: Vector2, y: float) -> Vector3: return Vector3(p.x, y, p.y)
	roof([up.call(e0, C_H), up.call(e1, C_H), up.call(g1, top), up.call(g0, top)])
	roof([up.call(e1, C_H), up.call(e2, C_H), up.call(g2, top), up.call(g1, top)])
	roof([up.call(e2, C_H), up.call(e3, C_H), up.call(g3, top), up.call(g2, top)])
	roof([up.call(e3, C_H), up.call(e0, C_H), up.call(g0, top), up.call(g3, top)])
	for q in [[e0, g0], [e1, g1], [e2, g2], [e3, g3]]:
		ridge(up.call(q[0], C_H + 0.03), up.call(q[1], top + 0.03))
	_plain(g0, g1, top - 0.1, top + 0.35, "white")        # the kerb the glass stands on
	_plain(g1, g2, top - 0.1, top + 0.35, "white")
	_plain(g2, g3, top - 0.1, top + 0.35, "white")
	_plain(g3, g0, top - 0.1, top + 0.35, "white")
	var gy: float = top + 0.35
	var crown: float = gy + 1.0
	var zm: float = GLASS.position.y + GLASS.size.y / 2.0
	var pane := 0xbfd6dd
	quad(Vector3(g0.x, gy, g0.y), Vector3(g1.x, gy, g1.y), Vector3(g1.x, crown, zm), Vector3(g0.x, crown, zm), pane, Vector3(0, 0.95, -0.3).normalized())
	quad(Vector3(g2.x, gy, g2.y), Vector3(g3.x, gy, g3.y), Vector3(g3.x, crown, zm), Vector3(g2.x, crown, zm), pane, Vector3(0, 0.95, 0.3).normalized())
	tri(Vector3(g0.x, gy, g0.y), Vector3(g0.x, crown, zm), Vector3(g3.x, gy, g3.y), pane, Vector3(-1, 0, 0))
	tri(Vector3(g1.x, gy, g1.y), Vector3(g2.x, gy, g2.y), Vector3(g1.x, crown, zm), pane, Vector3(1, 0, 0))
	for j in range(13):                                    # its white ribs: what shows as stripes from the air
		var rx: float = lerpf(g0.x, g1.x, j / 12.0)
		bar(Vector3(rx, gy + 0.02, g0.y), Vector3(rx, crown + 0.03, zm), 0.1, 0.08, 0xf2f0ea)
		bar(Vector3(rx, gy + 0.02, g3.y), Vector3(rx, crown + 0.03, zm), 0.1, 0.08, 0xf2f0ea)
	bar(Vector3(g0.x, crown + 0.04, zm), Vector3(g1.x, crown + 0.04, zm), 0.14, 0.1, 0xf2f0ea)

# ---------------- the sheds to the north ----------------
func _sheds() -> void:
	var sheet := 0x9aa6ae                                  # their roofs: grey sheet
	# the one on the street (its street wall is the wall itself)
	var a: Array = [Vector2(-5.3, -21.8), Vector2(-12.3, -21.8), Vector2(-12.0, -14.0), Vector2(-5.3, -14.0)]      # (north-east, north-west, south-west, south-east)
	for i in [0, 2, 3]:                                    # (its west wall is the wall of the street)
		_plain(a[i], a[(i + 1) % 4], -0.3, 3.1, "white")
	flat(PackedVector2Array([a[0] + Vector2(0.25, -0.2), a[1] + Vector2(-0.3, -0.2), a[2] + Vector2(-0.3, 0.25), a[3] + Vector2(0.25, 0.25)]), 3.2, sheet)
	_prism(a, 0.0, 3.1)
	var dr := face(a[2], a[3])                              # (a door and a window on the side of the mill)
	box(1.2, 0.0, 0.0, 1.0, 2.05, 0.05, 0x4a3324)
	box(3.6, 1.1, 0.0, 0.9, 0.9, 0.05, 0x39424a)
	home()
	# the one at the back, against the east wall
	var b: Array = [Vector2(1.2, -16.3), Vector2(8.1, -17.5), Vector2(1.3, -28.0), Vector2(-5.2, -27.0)]
	for i in range(4):
		_plain(b[i], b[(i + 1) % 4], -0.3, 3.4, "white")
	flat(PackedVector2Array(b), 3.5, sheet)
	_prism(b, 0.0, 3.4)
	dr = face(b[3], b[0])
	box(2.0, 0.0, 0.0, 2.4, 2.6, 0.05, 0x4a3324)
	home()
	for q in a + b:
		yard.append(spot((q as Vector2).x, (q as Vector2).y))
	# the wall that closes the gateway's yard on the side of the neighbour
	_plain(Vector2(-12.6, -25.75), Vector2(-5.2, -27.0), -0.3, 3.4, "white")
	_prism([Vector2(-12.6, -25.75), Vector2(-5.2, -27.0), Vector2(-5.2, -27.3), Vector2(-12.6, -26.05)], 0.0, 3.4)

# ---------------- the wall on the side of the fields ----------------
func _east_wall() -> void:
	var line: Array = [Vector2(8.1, -17.5), Vector2(12.7, -8.0), Vector2(13.3, 0.0), Vector2(13.35, 12.6)]
	for i in range(1, line.size()):
		var a: Vector2 = line[i - 1]
		var b: Vector2 = line[i]
		_plain(b, a, -0.4, 2.6, "brick")                    # brick to the fields, white to the yard
		_plain(a, b, -0.4, 2.6, "white")
		var d: Vector2 = (b - a).normalized()
		var n := Vector2(-d.y, d.x)
		flat(PackedVector2Array([a - n * 0.03, b - n * 0.03, b + n * 0.03, a + n * 0.03]), 2.6, "white")
		_prism([a - n * 0.15, b - n * 0.15, b + n * 0.15, a + n * 0.15], 0.0, 2.6)
		yard.append(spot(a.x, a.y))
