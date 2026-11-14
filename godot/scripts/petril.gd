extends Node3D
## The Petril: the old convent of San Francisco with its church and the little raised square in front of them, at the
## corner of the Calle de las Cruces and the Calle de San Francisco. In the game it is the "Iglesia del Petril" (the
## user's name for it, 14 November 2026). Hand-built over Catastro's footprints from the user's street photos
## (referencias/petril/), Street View and the aerial photo.
##
## What it is: a level square held up over the two streets by a wall of ochre rubble with a granite coping (the
## "pretil" that gives the place its name), with a flight of granite steps between two pillars with stone balls on
## the Calle de San Francisco and a ramp up from the Calle de las Cruces along the convent's front. On its north side,
## the narrow tall front of the church -- brick piers and courses with panels of rubble between them, a porch on two
## granite columns over a studded door -- and, in line with it, a lower two-storey wing. On its east side, the long
## two-storey front of the convent, mostly brick with panels of rubble scattered over it, a brick doorway under a
## curved broken pediment with a shield, and at its north end a look-out gallery of white plaster between dark posts
## under its own hipped roof.
##
## Second pass, the same day: the council's three photographs of the square were matched by cameras fitted to them
## (the game photographed from the very spot, then compared patch by patch), and from that came the colours of brick,
## panels, plinth and tiles, the panels of the long front one by one, its doorway, the openings of the wing beside
## the church, the church's doorway and cornice, and the parapet between the square and the ramp. Trees are as
## Street View had them in November 2024 (the council's photographs are older: its two big cypresses were saplings).
##
## Its own frame (MapData.petril): the origin is the south-west corner of the church, +x runs east along the church's
## south front, +z points south, out into the square, and y = 0 is the floor of the square.

const Parts = preload("res://scripts/parts.gd")
const Tex = preload("res://scripts/texturas.gd")

const READY := true                 # (tools/bake_godot.py looks for this line: only then does it leave Catastro's parts of the place to this script)

# Heights over the floor of the square. The church's from two Street View panos 22 m off and the council's square-on
# photograph; the convent's from its doors and windows; the gallery's from the council's photograph of the long front
# (it stands 1.8 m back from it, which that camera's fit allows for); the crossing tower's from the proportions of the
# survey in "Cuadernos de Historia y Cultura Popular de Madridejos" 3 (2017), which no photograph shows whole.
const NAVE := 13.0                  # the top of the nave's cornice
const TOWER := 17.7                 # ...and of the tower's over the crossing
const CHANCEL := 10.6               # the low end of the church, beyond the tower
const WING := 7.5                   # the convent's eaves
const PITCH := 0.54                 # how its roofs rise: metres up for each metre in
const LOFT := 10.5                  # the eaves of the look-out gallery
const PARAPET := 0.95               # the pretil over the floor of the square
const RISE := 0.82                  # the square over the Calle de San Francisco at the steps: five risers
# The outline of the square: its corners on San Francisco and Cruces, the corner the wall turns in at, and where it
# ends beside the ramp. Then the two ends of the convent's long front, which closes the square on the east.
const P_NW := Vector2(0.35, 0.0)
const P_SW := Vector2(0.6, 18.4)
const P_C1 := Vector2(12.3, 20.2)
const P_C2 := Vector2(13.0, 18.0)
const P_C3 := Vector2(16.3, 17.8)
const W1 := Vector2(18.4, 0.0)
const W2 := Vector2(17.8, 21.9)
const STEPS := Vector2(8.0, 9.75)     # the flight on San Francisco: from z to z
const STEPS_IN := 1.65                  # ...and how far in it goes
const RAMP_TOP := 13.5                  # where the ramp from the Calle de las Cruces reaches the floor of the square (z)
const RAMP_FOOT := 21.9
const CHURCH_W := 8.8                   # the width of the church's front
const STONE := 0xd2bba4                 # pale dressed stone: the shield, the niche, the plaques
const FRAME := 0x857d6d                 # the grey surround of the convent's windows
const DOOR := 0x2b1d15                  # old dark doors
const IRON := 0x26262a

var W
var level := 0.0                    # the floor of the square, in the world
var foot := 0.0                     # the pavement of the Calle de las Cruces at the foot of the ramp, measured from that floor (negative)
var pieces := 0                     # how many pieces it took (for the self-test)
var yard: Array = []                # where its walls, pillars, trees and benches stand, on the map (the self-test checks none is in a street)
var door: Vector2                   # in front of the church's door, on the map
var gate: Vector2                   # ...and of the convent's
var _tools := {}                    # material key -> SurfaceTool (everything of one material is one mesh)
var _mats := {}
var _xf := Transform3D.IDENTITY     # where what is being built stands in the Petril's frame (each wall has its own)
var _decks: Array = []

func build(world) -> void:
	W = world
	var c: Dictionary = MapData.petril
	if c.is_empty():
		return
	var u := Vector2(c["u"][0], c["u"][1])
	var o := Vector2(c["o"][0], c["o"][1])
	transform = Transform3D(Basis(Vector3.UP, atan2(-u.y, u.x)), Vector3(o.x, 0.0, o.y))
	level = MapData.height(spot(-1.0, (STEPS.x + STEPS.y) / 2.0)) + RISE
	position.y = level
	W.add_child(self)
	door = spot(CHURCH_W / 2.0, 5.2)
	gate = spot(16.4, 8.75)
	_square()
	_church()
	_convent()
	home()
	_commit()
	_green()
	_occluders()
	MapData.decks = _decks + MapData.decks

## a spot in the Petril's own frame, as a place in the town
func spot(x: float, z: float) -> Vector2:
	var p := transform * Vector3(x, 0, z)
	return Vector2(p.x, p.z)

## how high the town's ground is under a spot of the frame, measured from the floor of the square (negative: below it)
func ground(x: float, z: float) -> float:
	return MapData.height(spot(x, z)) - level

## What hides what (the occlusion culling of game.gd): the town's generic walls do it for the houses, but this place has
## none of those in the map, so it brings its own -- its big walls, each a hand's breadth inside itself and well short
## of its ends, its foot and its top. (Each is given as face() takes a wall: its left end, then its right, seen from
## outside. Nothing of the place itself can be hidden by them: all its pieces of one material are a single mesh.)
func _occluders() -> void:
	var s2 := Vector2(26.4, 23.73)
	var s3 := Vector2(31.0, 24.7)
	var verts := PackedVector3Array()
	var idx := PackedInt32Array()
	for q in [[Vector2(0, 0), Vector2(CHURCH_W, 0), 0.4, NAVE - 0.9], [Vector2(0.6, -14.7), Vector2(0, 0), 0.4, NAVE - 0.9],
			[Vector2(CHURCH_W, 0), Vector2(9.9, -14.7), 0.4, NAVE - 0.9], [Vector2(0.55, -25.0), Vector2(-0.15, -14.7), 0.4, TOWER - 0.9],
			[Vector2(-0.15, -14.7), Vector2(9.9, -14.7), 0.4, TOWER - 0.9], [Vector2(9.9, -14.7), Vector2(10.5, -25.0), 0.4, TOWER - 0.9],
			[Vector2(10.5, -25.0), Vector2(0.55, -25.0), 3.4, TOWER - 0.9],
			[Vector2(CHURCH_W, 0), W1, 0.4, WING - 0.9], [W1, W2, 0.4, WING - 0.9], [W2, s2, 0.4, WING - 0.9], [s2, s3, 0.4, 5.0],
			[Vector2(34.0, -22.6), Vector2(10.5, -24.8), 0.4, WING - 0.9], [s3, Vector2(33.2, -10.0), 0.4, 5.0], [Vector2(33.2, -10.0), Vector2(34.0, -22.6), 0.4, 5.0]]:
		var a: Vector2 = q[0]
		var b: Vector2 = q[1]
		var d := (b - a).normalized()
		var inward := Vector2(d.y, -d.x) * 0.2
		a += d * 0.35 + inward
		b += -d * 0.35 + inward
		var k := verts.size()
		verts.append_array([Vector3(a.x, q[2], a.y), Vector3(b.x, q[2], b.y), Vector3(b.x, q[3], b.y), Vector3(a.x, q[3], a.y)])
		idx.append_array([k, k + 1, k + 2, k, k + 2, k + 3])
	var shape := ArrayOccluder3D.new()
	shape.set_arrays(verts, idx)
	var oc := OccluderInstance3D.new()
	oc.occluder = shape
	add_child(oc)

# ---------------- materials ----------------
func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material
	var name := String(key) if key is String else ""
	match name:
		"brick":            # hand-made brick with thick lime joints, bleached terracotta
			m = Tex.mat("medieval_red_brick")
		"rubble":           # the rubble of the church and of the wing beside it: ochre stones the size of a loaf, in lime
			m = Tex.mat("rock_wall", Color(1.06, 1.04, 1.06))
		"panel":            # the panels of the long front: small rubble all but hidden under its pointing, nearly the brick's own colour
			m = Tex.mat("plaster_stone_wall_02", Color(1.08, 1.03, 0.98))
		"trim":             # brick that has lost its colour: the columns and the flat arch of the doorway
			m = Tex.mat("medieval_red_brick", Color(1.04, 1.04, 1.06))
		"moulding":         # ...and its weathered mouldings
			m = Tex.mat("medieval_red_brick", Color(0.84, 0.78, 0.7))
		"caliza":           # pale limestone: the pedestals of that doorway (it stays pale in the shade, as stone beside a sunlit floor does)
			m = _glow(Tex.mat("granular_concrete", Color(1.08, 1.0, 0.9)), 0.12)
		"pretil":           # the retaining wall: bigger ochre stones
			m = Tex.mat("rock_wall", Color(0.95, 1.0, 1.12))
		"plinth":           # the dark rubble at the foot of the walls
			m = Tex.mat("rock_wall_15")
		"granite":          # bush-hammered granite: steps, copings, columns, balls
			m = _glow(Tex.mat("granular_concrete", Color(0.92, 0.9, 0.86)), 0.12)
		"floor":            # the sandy floor of the square
			m = Tex.mat("granular_concrete@3.0", Color(0.93, 0.9, 0.87), false)
		"band":             # the bands of smaller stones across it
			m = Tex.mat("granular_concrete@1.2", Color(0.8, 0.75, 0.66), false)
		"cobble":           # the cobbles of the slope beside the ramp
			m = Tex.mat("square_cobblestone@1.7", Color(0.88, 0.93, 1.1), false)
		"zocalo":           # the greyer rubble at the foot of the convent's fronts
			m = Tex.mat("stone_wall", Color(1.1, 1.09, 1.17))
		"tiles":            # old curved tiles (its UVs are in units of 1.6 m, running down the slope)
			var tm: StandardMaterial3D = Tex.mat(Tex.pick("tiles") if Tex.pick("tiles") != "" else "clay_roof_tiles_02", Color(0.63, 1.0, 1.6), true, 1.6)
			tm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = tm
		"wood":             # the dark timber of the porch and the gallery
			var wm: StandardMaterial3D = Tex.mat("old_planks_02", Color(0.36, 0.26, 0.2))
			wm.rim_enabled = true
			wm.rim = 0.3
			wm.rim_tint = 0.6
			m = wm
		"white":            # lime-washed plaster (it reads white in the shade too)
			var pm: StandardMaterial3D = Tex.mat("painted_plaster_wall", Color(1.0, 0.985, 0.95))
			pm.emission_enabled = true
			pm.emission = Color(1.0, 0.97, 0.9)
			pm.emission_texture = pm.albedo_texture
			pm.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			pm.emission_energy_multiplier = 0.18
			m = pm
		_:
			m = Parts.mat(int(key))
	_mats[key] = m
	return m

## pale stone under a porch or in the shade of a wall is lit by the floor in front of it: a little light of its own
func _glow(m: StandardMaterial3D, how: float) -> StandardMaterial3D:
	m.emission_enabled = true
	m.emission = Color(1.0, 0.95, 0.86)
	m.emission_texture = m.albedo_texture
	m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	m.emission_energy_multiplier = how
	return m

func _tool(key) -> SurfaceTool:
	if not _tools.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_tools[key] = st
	return _tools[key]

## everything built so far becomes meshes: one for each material
func _commit() -> void:
	for key in _tools:
		var mi := MeshInstance3D.new()
		var st: SurfaceTool = _tools[key]
		if key is String and key == "tiles":
			st.generate_tangents()
		mi.mesh = st.commit()
		mi.material_override = _material(key)
		add_child(mi)
	_tools.clear()

# ---------------- pieces ----------------
func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3, uvs = null) -> void:
	var pts := [a, b, c]
	var tex = uvs
	if (b - a).cross(c - a).dot(n) > 0.0:         # Godot wants clockwise front faces
		pts = [a, c, b]
		if uvs != null:
			tex = [uvs[0], uvs[2], uvs[1]]
	for k in range(3):
		st.set_normal(n)
		if tex != null:
			st.set_uv(tex[k])
		st.add_vertex(pts[k])

## a flat three-sided piece facing `n` (in the frame being built)
func tri(a: Vector3, b: Vector3, c: Vector3, key, n: Vector3, uvs = null) -> void:
	_tri(_tool(key), _xf * a, _xf * b, _xf * c, (_xf.basis * n).normalized(), uvs)

## a flat four-sided piece facing `n`
func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, key, n: Vector3, uvs = null) -> void:
	var st := _tool(key)
	n = (_xf.basis * n).normalized()
	a = _xf * a; b = _xf * b; c = _xf * c; d = _xf * d
	_tri(st, a, b, c, n, [uvs[0], uvs[1], uvs[2]] if uvs != null else null)
	_tri(st, a, c, d, n, [uvs[0], uvs[2], uvs[3]] if uvs != null else null)

## a box: its left, bottom, back corner, then how wide, high and deep (out of the wall) it is
func box(x: float, y: float, z: float, w: float, h: float, d: float, key) -> void:
	if w <= 0.0 or h <= 0.0 or d <= 0.0:
		return
	pieces += 1
	var a := Vector3(x, y, z)
	var b := Vector3(x + w, y + h, z + d)
	quad(Vector3(a.x, a.y, b.z), Vector3(b.x, a.y, b.z), Vector3(b.x, b.y, b.z), Vector3(a.x, b.y, b.z), key, Vector3(0, 0, 1))
	quad(Vector3(a.x, a.y, a.z), Vector3(b.x, a.y, a.z), Vector3(b.x, b.y, a.z), Vector3(a.x, b.y, a.z), key, Vector3(0, 0, -1))
	quad(Vector3(a.x, a.y, a.z), Vector3(a.x, a.y, b.z), Vector3(a.x, b.y, b.z), Vector3(a.x, b.y, a.z), key, Vector3(-1, 0, 0))
	quad(Vector3(b.x, a.y, a.z), Vector3(b.x, a.y, b.z), Vector3(b.x, b.y, b.z), Vector3(b.x, b.y, a.z), key, Vector3(1, 0, 0))
	quad(Vector3(a.x, b.y, a.z), Vector3(b.x, b.y, a.z), Vector3(b.x, b.y, b.z), Vector3(a.x, b.y, b.z), key, Vector3(0, 1, 0))
	quad(Vector3(a.x, a.y, a.z), Vector3(b.x, a.y, a.z), Vector3(b.x, a.y, b.z), Vector3(a.x, a.y, b.z), key, Vector3(0, -1, 0))

## a box given by its middle and its size
func cbox(mid: Vector3, size: Vector3, key) -> void:
	box(mid.x - size.x / 2.0, mid.y - size.y / 2.0, mid.z - size.z / 2.0, size.x, size.y, size.z, key)

## a box turned any way: `t` puts a unit cube (-0.5..0.5) where it goes, in the frame being built
func tbox(t: Transform3D, key) -> void:
	var keep := _xf
	_xf = _xf * t
	box(-0.5, -0.5, -0.5, 1.0, 1.0, 1.0, key)
	_xf = keep

## a bar from a to b, w wide and h high (square to its own run; `roll` turns it about that run)
func bar(a: Vector3, b: Vector3, w: float, h: float, key, roll := 0.0) -> void:
	var run := b - a
	var ln := run.length()
	if ln < 0.001:
		return
	var zdir := run / ln
	var up := Vector3.UP if absf(zdir.y) < 0.95 else Vector3.RIGHT
	var xdir := up.cross(zdir).normalized()
	var ydir := zdir.cross(xdir)
	var basis := Basis(xdir, ydir, zdir).rotated(zdir, roll)
	tbox(Transform3D(basis.scaled_local(Vector3(w, h, ln)), (a + b) / 2.0), key)

## a round upright piece: radius r0 at its foot (at `foot`), r1 at the top, h high
func drum(foot: Vector3, r0: float, r1: float, h: float, key, sides := 14) -> void:
	pieces += 1
	for i in range(sides):
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var p0 := foot + Vector3(cos(a0) * r0, 0, sin(a0) * r0)
		var p1 := foot + Vector3(cos(a1) * r0, 0, sin(a1) * r0)
		var q0 := foot + Vector3(cos(a0) * r1, h, sin(a0) * r1)
		var q1 := foot + Vector3(cos(a1) * r1, h, sin(a1) * r1)
		var n := Vector3(cos((a0 + a1) / 2.0), (r0 - r1) / maxf(h, 0.001), sin((a0 + a1) / 2.0)).normalized()
		quad(p0, p1, q1, q0, key, n)
		if r1 > 0.001:
			tri(foot + Vector3(0, h, 0), q0, q1, key, Vector3.UP)
		tri(foot, p0, p1, key, Vector3.DOWN)

## a ball
func ball(mid: Vector3, r: float, key, squash := 1.0, sides := 12, rings := 7) -> void:
	pieces += 1
	for j in range(rings):
		var t0 := PI * j / rings - PI / 2.0
		var t1 := PI * (j + 1) / rings - PI / 2.0
		for i in range(sides):
			var a0 := TAU * i / sides
			var a1 := TAU * (i + 1) / sides
			var v: Array = []
			for q in [[a0, t0], [a1, t0], [a1, t1], [a0, t1]]:
				v.append(Vector3(cos(q[0]) * cos(q[1]), sin(q[1]) * squash, sin(q[0]) * cos(q[1])))
			var n: Vector3 = ((v[0] + v[1] + v[2] + v[3]) / 4.0).normalized()
			quad(mid + v[0] * r, mid + v[1] * r, mid + v[2] * r, mid + v[3] * r, key, n)

## a flat piece with this outline (x, y) in the plane z, facing out (+z), `deep` thick behind it
func slab(pts: PackedVector2Array, z: float, deep: float, key) -> void:
	pieces += 1
	var idx := Geometry2D.triangulate_polygon(pts)
	for t in range(0, idx.size(), 3):
		var a := pts[idx[t]]; var b := pts[idx[t + 1]]; var c := pts[idx[t + 2]]
		tri(Vector3(a.x, a.y, z), Vector3(b.x, b.y, z), Vector3(c.x, c.y, z), key, Vector3(0, 0, 1))
	if deep > 0.0:
		for i in range(pts.size()):
			var a := pts[i]
			var b := pts[(i + 1) % pts.size()]
			var d := (b - a).normalized()
			var n := Vector3(d.y, -d.x, 0)
			var mid := Vector2.ZERO
			for q in pts:
				mid += q / pts.size()
			if Vector2(n.x, n.y).dot((a + b) / 2.0 - mid) < 0.0:
				n = -n
			quad(Vector3(a.x, a.y, z - deep), Vector3(b.x, b.y, z - deep), Vector3(b.x, b.y, z), Vector3(a.x, a.y, z), key, n)

## a piece of roof: three or four corners in order, all in one plane. Its tiles run down the slope.
func roof(pts: Array, key = "tiles") -> void:
	pieces += 1
	var n: Vector3 = ((pts[1] as Vector3) - pts[0]).cross((pts[2] as Vector3) - pts[0]).normalized()
	if n.y < 0.0:
		n = -n
	var along := Vector3.UP.cross(n)
	if along.length() < 0.001:
		along = Vector3.RIGHT
	along = along.normalized()
	var down := n.cross(along).normalized()
	var uv: Array = []
	for p in pts:
		uv.append(Vector2((p as Vector3).dot(along), (p as Vector3).dot(down)) / 1.6)
	if pts.size() == 3:
		tri(pts[0], pts[1], pts[2], key, n, uv)
	else:
		quad(pts[0], pts[1], pts[2], pts[3], key, n, uv)

## The frame of a wall seen from outside: `a` is its left end and `b` its right end on the floor plan (x, z) of the
## Petril; in it +x runs along the wall, +y is up and +z comes out of the wall.
func face(a: Vector2, b: Vector2, y := 0.0) -> float:
	var d := (b - a).normalized()
	_xf = Transform3D(Basis(Vector3(d.x, 0, d.y), Vector3.UP, Vector3(-d.y, 0, d.x)), Vector3(a.x, y, a.y))
	return a.distance_to(b)

func home() -> void:
	_xf = Transform3D.IDENTITY

# ---------------- walls ----------------
const DEEP := 0.34                  # how far in the windows sit

## A wall of brick with panels of rubble, on the plane z = 0 of the frame being built, from x0 to x1 and y0 to y1.
## `holes` (Rect2: x, y, width, height) are left open, with their sides shown `DEEP` back; `panels` (Rect2) are of
## rubble; the rest is brick. The wall is cut along the edges of them all, and each row is joined up again into
## runs of one material. `over`: where the wall is of brick whatever the panels say (round an opening).
func masonry(x0: float, x1: float, y0: float, y1: float, holes: Array, panels: Array, main = "brick", other = "rubble", over: Array = []) -> void:
	var xs := [x0, x1]
	var ys := [y0, y1]
	for list in [holes, panels, over]:
		for r: Rect2 in list:
			for v in [r.position.x, r.end.x]:
				if v > x0 + 0.001 and v < x1 - 0.001:
					xs.append(v)
			for v in [r.position.y, r.end.y]:
				if v > y0 + 0.001 and v < y1 - 0.001:
					ys.append(v)
	xs.sort()
	ys.sort()
	for j in range(ys.size() - 1):
		if ys[j + 1] - ys[j] < 0.0005:
			continue
		var run_from := 0.0
		var run_kind := -1                      # -1 nothing yet, 0 open, 1 brick, 2 rubble
		for i in range(xs.size()):
			var kind := -1
			if i < xs.size() - 1:
				var c := Vector2((xs[i] + xs[i + 1]) / 2.0, (ys[j] + ys[j + 1]) / 2.0)
				kind = 1
				for r: Rect2 in panels:
					if r.has_point(c):
						kind = 2
						break
				for r: Rect2 in over:
					if r.has_point(c):
						kind = 1
						break
				for r: Rect2 in holes:
					if r.has_point(c):
						kind = 0
						break
			if kind != run_kind:
				if run_kind > 0 and xs[i] - run_from > 0.0005:
					pieces += 1
					quad(Vector3(run_from, ys[j], 0), Vector3(xs[i], ys[j], 0), Vector3(xs[i], ys[j + 1], 0), Vector3(run_from, ys[j + 1], 0),
						main if run_kind == 1 else other, Vector3(0, 0, 1))
				run_from = xs[i]
				run_kind = kind
	for r: Rect2 in holes:                      # the sides of each opening
		var a := r.position
		var b := r.end
		if a.x < x0 - 0.001 or b.x > x1 + 0.001:
			continue
		quad(Vector3(a.x, a.y, -DEEP), Vector3(a.x, a.y, 0), Vector3(a.x, b.y, 0), Vector3(a.x, b.y, -DEEP), main, Vector3(1, 0, 0))
		quad(Vector3(b.x, a.y, -DEEP), Vector3(b.x, a.y, 0), Vector3(b.x, b.y, 0), Vector3(b.x, b.y, -DEEP), main, Vector3(-1, 0, 0))
		quad(Vector3(a.x, b.y, -DEEP), Vector3(b.x, b.y, -DEEP), Vector3(b.x, b.y, 0), Vector3(a.x, b.y, 0), main, Vector3(0, -1, 0))
		if a.y > y0 + 0.001:
			quad(Vector3(a.x, a.y, -DEEP), Vector3(b.x, a.y, -DEEP), Vector3(b.x, a.y, 0), Vector3(a.x, a.y, 0), main, Vector3(0, 1, 0))

## The dark rubble at the foot of a wall: it stands a little proud of it, from well under the ground up to `top0` at
## x0 and `top1` at x1 (the street may fall along the wall, and the plinth with it).
func plinth(x0: float, x1: float, top0: float, top1: float, key = "plinth", proud := 0.05, down := -3.0) -> void:
	pieces += 1
	quad(Vector3(x0, down, proud), Vector3(x1, down, proud), Vector3(x1, top1, proud), Vector3(x0, top0, proud), key, Vector3(0, 0, 1))
	quad(Vector3(x0, top0, 0), Vector3(x1, top1, 0), Vector3(x1, top1, proud), Vector3(x0, top0, proud), key, Vector3(0, 1, 0))
	quad(Vector3(x0, down, 0), Vector3(x0, down, proud), Vector3(x0, top0, proud), Vector3(x0, top0, 0), key, Vector3(-1, 0, 0))
	quad(Vector3(x1, down, 0), Vector3(x1, down, proud), Vector3(x1, top1, proud), Vector3(x1, top1, 0), key, Vector3(1, 0, 0))

## The brick cornice under the eaves: courses stepping out one over another, a row of bricks set cornerwise between
## them (the saw-tooth every old wall of the town has), from x0 to x1 with its top at y.
func cornice(x0: float, x1: float, y: float, teeth := true, key = "brick", k := 1.0) -> float:
	var out := 0.0
	var at := y - 0.42 * k
	for step in [[0.07, 0.05], [0.07, 0.05]]:
		out += step[1] * k
		box(x0 - out, at, 0.0, x1 - x0 + 2.0 * out, step[0] * k, out, key)
		at += step[0] * k
	if teeth:
		var n := int((x1 - x0) / (0.14 * k))
		for i in range(n):
			var t := Transform3D(Basis(Vector3.UP, PI / 4.0).scaled_local(Vector3(0.11, 0.09, 0.11) * k), Vector3(x0 + (i + 0.5) * (x1 - x0) / n, at + 0.045 * k, out + 0.02 * k))
			tbox(t, key)
		box(x0 - out, at, 0.0, x1 - x0 + 2.0 * out, 0.09 * k, out - 0.03 * k, 0x8a6a4c)
	else:
		box(x0 - out, at, 0.0, x1 - x0 + 2.0 * out, 0.09 * k, out, key)
	at += 0.09 * k
	for step in [[0.07, 0.06], [0.07, 0.06], [0.05, 0.05]]:
		out += step[1] * k
		box(x0 - out, at, 0.0, x1 - x0 + 2.0 * out, step[0] * k, out, key)
		at += step[0] * k
	return out

## A window in its hole (the hole itself is the wall's business): the frame of dark wood, two leaves of glass with
## their bars, `sill` or not; r is the hole.
func window(r: Rect2, frame = 0x3a2a1e, glass := 0x1f2a33, bars := 2) -> void:
	var z := -DEEP + 0.06
	var a := r.position
	var b := r.end
	box(a.x, a.y, z - 0.05, r.size.x, r.size.y, 0.03, glass)
	for q in [[a.x, a.y, 0.07, r.size.y], [b.x - 0.07, a.y, 0.07, r.size.y], [a.x, a.y, r.size.x, 0.07], [a.x, b.y - 0.07, r.size.x, 0.07]]:
		box(q[0], q[1], z - 0.02, q[2], q[3], 0.06, frame)
	box((a.x + b.x) / 2.0 - 0.035, a.y, z - 0.02, 0.07, r.size.y, 0.065, frame)
	for k in range(1, bars + 1):
		box(a.x, a.y + r.size.y * k / (bars + 1.0) - 0.015, z - 0.015, r.size.x, 0.03, 0.05, frame)

## An iron grille standing out in front of a window (a "reja"): square bars upright, flat ones across, in a cage
## that comes `out` from the wall.
func grille(r: Rect2, out := 0.16, iron := 0x26262a) -> void:
	var x0 := r.position.x - 0.06
	var x1 := r.end.x + 0.06
	var y0 := r.position.y - 0.05
	var y1 := r.end.y + 0.05
	var n := maxi(3, int(round((x1 - x0) / 0.13)))
	for i in range(n + 1):
		box(x0 + (x1 - x0) * i / n - 0.011, y0, out - 0.011, 0.022, y1 - y0, 0.022, iron)
	var m := maxi(2, int(round((y1 - y0) / 0.42)))
	for j in range(m + 1):
		var y: float = y0 + (y1 - y0) * j / m
		box(x0, y - 0.006, out - 0.02, x1 - x0, 0.012, 0.04, iron)
		if j == 0 or j == m:                  # the cage's returns to the wall
			box(x0 - 0.011, y - 0.006, 0.0, 0.022, 0.012, out, iron)
			box(x1 - 0.011, y - 0.006, 0.0, 0.022, 0.012, out, iron)

## a solid for cars and people to run into, given in the Petril's frame
func solid(mid: Vector3, size: Vector3, turn := 0.0) -> void:
	var cs := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = size
	cs.shape = b
	cs.transform = transform * Transform3D(Basis(Vector3.UP, turn), mid)
	W.body.add_child(cs)

## a flat piece of floor with this outline (x, z), at height y
func flat(pts: PackedVector2Array, y: float, key) -> void:
	pieces += 1
	var idx := Geometry2D.triangulate_polygon(pts)
	for t in range(0, idx.size(), 3):
		var a := pts[idx[t]]
		var b := pts[idx[t + 1]]
		var c := pts[idx[t + 2]]
		tri(Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y), key, Vector3.UP)

## the two corners left between a round arch and the square hole it stands in (cx: its middle, spring: where the arch
## begins, r: its radius), on the plane z
func spandrels(cx: float, spring: float, r: float, z: float, key, n := 8) -> void:
	pieces += 1
	for side in [-1.0, 1.0]:
		var corner := Vector3(cx + side * r, spring + r, z)
		for i in range(n):
			var a0 := PI / 2.0 * i / n
			var a1 := PI / 2.0 * (i + 1) / n
			tri(corner, Vector3(cx + side * r * cos(a0), spring + r * sin(a0), z), Vector3(cx + side * r * cos(a1), spring + r * sin(a1), z), key, Vector3(0, 0, 1))

## the stones of a round arch, flat on the plane z: between the radii r0 and r1, their inside face going `deep` back
func ring(cx: float, spring: float, r0: float, r1: float, z: float, deep: float, key, n := 12) -> void:
	pieces += 1
	var o := Vector3(cx, spring, z)
	var back := Vector3(0, 0, deep)
	for i in range(n):
		var c0 := Vector3(cos(PI * i / n), sin(PI * i / n), 0)
		var c1 := Vector3(cos(PI * (i + 1) / n), sin(PI * (i + 1) / n), 0)
		var mid := ((c0 + c1) / 2.0).normalized()
		quad(o + c0 * r0, o + c0 * r1, o + c1 * r1, o + c1 * r0, key, Vector3(0, 0, 1))
		quad(o + c0 * r0 - back, o + c0 * r0, o + c1 * r0, o + c1 * r0 - back, key, -mid)
		if z > 0.001:
			quad(o + c0 * r1 - Vector3(0, 0, z), o + c0 * r1, o + c1 * r1, o + c1 * r1 - Vector3(0, 0, z), key, mid)

## the outline of an oval (for slab())
func oval(cx: float, cy: float, rx: float, ry: float, n := 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		pts.append(Vector2(cx + rx * cos(TAU * i / n), cy + ry * sin(TAU * i / n)))
	return pts

## a leaf of that shape (a door under a round arch), on the plane z
func arched(cx: float, y0: float, spring: float, r: float, z: float, key, n := 12) -> void:
	var pts := PackedVector2Array([Vector2(cx - r, y0), Vector2(cx + r, y0)])
	for i in range(n + 1):
		pts.append(Vector2(cx + r * cos(PI * i / n), spring + r * sin(PI * i / n)))
	slab(pts, z, 0.0, key)

## the bright studs of an old door, in rows over a rectangle of it
func studs(x0: float, x1: float, y0: float, y1: float, z: float, nx: int, ny: int, hex := 0x9a9891) -> void:
	for i in range(nx):
		for j in range(ny):
			box(lerpf(x0, x1, (i + 0.5) / nx) - 0.02, lerpf(y0, y1, (j + 0.5) / ny) - 0.02, z, 0.04, 0.04, 0.018, hex)

## a frame of pale stone round an opening
func stone_frame(r: Rect2, w := 0.13, proud := 0.035, key = STONE) -> void:
	box(r.position.x - w, r.end.y, 0.0, r.size.x + 2.0 * w, w, proud, key)
	box(r.position.x - w, r.position.y - w, 0.0, r.size.x + 2.0 * w, w, proud + 0.03, key)
	box(r.position.x - w, r.position.y, 0.0, w, r.size.y, proud, key)
	box(r.end.x, r.position.y, 0.0, w, r.size.y, proud, key)

## words on the wall being built
func _text(s: String, at: Vector3, px: int, hex: int, pixel := 0.004) -> Label3D:
	var l := Label3D.new()
	l.text = s
	l.font_size = px
	l.pixel_size = pixel
	l.modulate = Parts.col(hex)
	l.outline_size = 0
	l.transform = _xf * Transform3D(Basis(), at)
	add_child(l)
	return l

## A granite column on its pedestal: `at` is the middle of its foot. Returns how high its top is.
func column(at: Vector3, shaft: float, r := 0.22, pedestal := 0.5, wide := 0.0) -> float:
	var y := at.y
	if pedestal > 0.0:
		var pw := wide if wide > 0.0 else r * 2.9
		cbox(Vector3(at.x, y + pedestal / 2.0, at.z), Vector3(pw, pedestal, pw), "granite")
		if wide > 0.0:                    # (a moulding round its head and its foot)
			cbox(Vector3(at.x, y + pedestal - 0.05, at.z), Vector3(pw + 0.1, 0.1, pw + 0.1), "granite")
			cbox(Vector3(at.x, y + 0.07, at.z), Vector3(pw + 0.12, 0.14, pw + 0.12), "granite")
		y += pedestal
	drum(Vector3(at.x, y, at.z), r * 1.38, r * 1.12, 0.16, "granite")
	y += 0.16
	drum(Vector3(at.x, y, at.z), r, r * 0.88, shaft, "granite")
	y += shaft
	drum(Vector3(at.x, y, at.z), r * 0.92, r * 1.25, 0.12, "granite")
	y += 0.12
	cbox(Vector3(at.x, y + 0.06, at.z), Vector3(r * 2.8, 0.12, r * 2.8), "granite")
	return y + 0.12

# ---------------- colliders and floors to walk on ----------------
## a solid with this outline (x, z) between two heights
func _prism(pts: Array, y0: float, y1: float) -> void:
	var v: Array = []
	for q: Vector2 in pts:
		v.append(Vector3(q.x, y0, q.y))
		v.append(Vector3(q.x, y1, q.y))
	_hull(v)

## a solid round these points
func _hull(points: Array) -> void:
	var shape := ConvexPolygonShape3D.new()
	var v := PackedVector3Array()
	for q: Vector3 in points:
		v.append(q)
	shape.points = v
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.transform = transform
	W.body.add_child(cs)

## a level floor of this outline, for whoever walks on it (MapData.foot)
func _poly_deck(pts: PackedVector2Array, top: float) -> Dictionary:
	var world_pts := PackedVector2Array()
	var mid := Vector2.ZERO
	for q in pts:
		world_pts.append(spot(q.x, q.y))
		mid += spot(q.x, q.y) / pts.size()
	var r2 := 0.0
	for q in world_pts:
		r2 = maxf(r2, mid.distance_squared_to(q))
	return {"o": mid, "r2": r2 + 1.0, "poly": world_pts, "top": top}

# ---------------- the square ----------------
## where the convent's front is at z (it is not quite square to the church's)
func _wing_x(z: float) -> float:
	return lerpf(W1.x, W2.x, z / W2.y)

func _west_x(z: float) -> float:
	return lerpf(P_NW.x, P_SW.x, z / P_SW.y)

## how high the ramp, and the cobbles beside it, are at z (from the floor of the square)
func _ramp_y(z: float) -> float:
	return foot * clampf((z - RAMP_TOP) / (RAMP_FOOT - RAMP_TOP), 0.0, 1.0)

## A stretch of the pretil from a to b, the street on the left of whoever walks from a to b: rubble on both faces,
## from under the ground up to its granite coping.
func _pretil(a: Vector2, b: Vector2) -> void:
	var ln := face(a, b)
	var t := 0.45
	pieces += 1
	quad(Vector3(0, -3.0, 0), Vector3(ln, -3.0, 0), Vector3(ln, PARAPET, 0), Vector3(0, PARAPET, 0), "pretil", Vector3(0, 0, 1))
	quad(Vector3(0, 0, -t), Vector3(ln, 0, -t), Vector3(ln, PARAPET, -t), Vector3(0, PARAPET, -t), "pretil", Vector3(0, 0, -1))
	quad(Vector3(0, -3.0, -t), Vector3(0, -3.0, 0), Vector3(0, PARAPET, 0), Vector3(0, PARAPET, -t), "pretil", Vector3(-1, 0, 0))
	quad(Vector3(ln, -3.0, -t), Vector3(ln, -3.0, 0), Vector3(ln, PARAPET, 0), Vector3(ln, PARAPET, -t), "pretil", Vector3(1, 0, 0))
	box(-0.05, PARAPET, -t - 0.05, ln + 0.1, 0.13, t + 0.1, "granite")
	home()
	var d := (b - a).normalized()
	var mid := (a + b) / 2.0 - Vector2(-d.y, d.x) * (t / 2.0)
	solid(Vector3(mid.x, (PARAPET + 0.13 - 2.0) / 2.0, mid.y), Vector3(ln, PARAPET + 0.13 + 2.0, t), atan2(-d.y, d.x))
	yard.append(spot(a.x, a.y))
	yard.append(spot(b.x, b.y))

## one of the two granite pillars of the steps, with its ball
func _pillar(z0: float) -> void:
	var x := _west_x(z0) - 0.05
	box(x, -3.0, z0, 0.6, 3.0 + 1.2, 0.55, "granite")
	box(x - 0.06, 1.2, z0 - 0.06, 0.72, 0.13, 0.67, "granite")
	drum(Vector3(x + 0.3, 1.33, z0 + 0.275), 0.2, 0.13, 0.13, "granite", 10)
	ball(Vector3(x + 0.3, 1.33 + 0.1 + 0.27, z0 + 0.275), 0.29, "granite")
	solid(Vector3(x + 0.3, -0.2, z0 + 0.275), Vector3(0.6, 3.2, 0.55))
	yard.append(spot(x + 0.3, z0 + 0.275))

## a short granite post, and the chain that hangs from it to `to`
func _post(x: float, z: float, to: Vector3) -> void:
	drum(Vector3(x, 0, z), 0.15, 0.13, 0.7, "granite", 10)
	ball(Vector3(x, 0.7, z), 0.13, "granite", 0.6, 10, 5)
	solid(Vector3(x, 0.4, z), Vector3(0.3, 0.8, 0.3))
	var from := Vector3(x, 0.62, z)
	var links := 9
	var last := from
	for k in range(1, links + 1):
		var f := float(k) / links
		var p := from.lerp(to, f) - Vector3(0, 0.28 * 4.0 * f * (1.0 - f), 0)
		bar(last, p, 0.04, 0.04, IRON, PI / 4.0 if k % 2 == 0 else 0.0)
		last = p
	yard.append(spot(x, z))

## a stone bench: a slab on two blocks
func _bench(x: float, z: float, along_x: bool) -> void:
	var size := Vector3(1.9, 0.14, 0.5) if along_x else Vector3(0.5, 0.14, 1.9)
	cbox(Vector3(x, 0.49, z), size, "granite")
	for s in [-0.68, 0.68]:
		cbox(Vector3(x + (s if along_x else 0.0), 0.21, z + (0.0 if along_x else s)), Vector3(0.26, 0.42, 0.4) if along_x else Vector3(0.4, 0.42, 0.26), "granite")
	solid(Vector3(x, 0.28, z), Vector3(size.x, 0.56, size.z))
	yard.append(spot(x, z))

## A strip of pavement along the foot of a wall (its line on the plan, the street on the left of whoever walks it),
## laid on whatever the street does there, with its kerb.
func _pavement(line: Array, wide: float) -> void:
	var slabs: Material = W._tmat(0xdcd5c8, "pavement", 2.0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var kerb := SurfaceTool.new()
	kerb.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(line.size() - 1):
		var a: Vector2 = line[k]
		var b: Vector2 = line[k + 1]
		var ln := a.distance_to(b)
		if ln < 0.3:
			continue
		var d := (b - a) / ln
		var out := Vector2(-d.y, d.x)
		var n := maxi(1, int(ceil(ln / 2.0)))
		for i in range(n):
			var q: Array = []
			for corner in [[i, 0.0], [i + 1, 0.0], [i + 1, wide], [i, wide]]:
				var p: Vector2 = a + d * (ln * corner[0] / n) + out * float(corner[1])
				q.append(Vector3(p.x, ground(p.x, p.y) + 0.13, p.y))
			_tri(st, q[0], q[1], q[2], Vector3.UP)
			_tri(st, q[0], q[2], q[3], Vector3.UP)
			var low := Vector3(0, 0.2, 0)
			_tri(kerb, q[3], q[2], q[2] - low, Vector3(out.x, 0, out.y))
			_tri(kerb, q[3], q[2] - low, q[3] - low, Vector3(out.x, 0, out.y))
	for pair in [[st, slabs], [kerb, Parts.mat(0xb9b4aa)]]:
		var mi := MeshInstance3D.new()
		mi.mesh = (pair[0] as SurfaceTool).commit()
		mi.material_override = pair[1]
		add_child(mi)

func _square() -> void:
	foot = MapData.height(spot(15.0, RAMP_FOOT)) + 0.03 - level
	var east := spot(1.0, 0.0) - spot(0.0, 0.0)             # this frame's +x and +z, on the map
	var south := spot(0.0, 1.0) - spot(0.0, 0.0)
	var sx0 := _west_x((STEPS.x + STEPS.y) / 2.0)             # the first riser is in the line of the wall
	var xi := sx0 + STEPS_IN
	var top_e := Vector2(_wing_x(RAMP_TOP), RAMP_TOP)
	# --- the floor: pale and sandy, with bands of cobbles across it ---
	var outline := PackedVector2Array([P_NW, W1, top_e, Vector2(P_C3.x, RAMP_TOP), P_C3, P_C2, P_C1, P_SW,
		Vector2(_west_x(STEPS.y), STEPS.y), Vector2(xi, STEPS.y), Vector2(xi, STEPS.x), Vector2(_west_x(STEPS.x), STEPS.x)])
	flat(outline, 0.0, "floor")
	var mid_z := (STEPS.x + STEPS.y) / 2.0
	for band in [[Vector2(xi + 0.2, mid_z), Vector2(16.9, 8.75)], [Vector2(CHURCH_W / 2.0, 4.6), Vector2(CHURCH_W / 2.0 + 0.3, 9.4)], [Vector2(6.5, 9.45), Vector2(11.8, 16.6)], [Vector2(13.6, 2.4), Vector2(13.4, 8.95)]]:
		var a: Vector2 = band[0]
		var b: Vector2 = band[1]
		bar(Vector3(a.x, 0.011, a.y), Vector3(b.x, 0.011, b.y), 0.55, 0.02, "band")
	_prism([P_NW, W1, Vector2(_wing_x(STEPS.x), STEPS.x), Vector2(_west_x(STEPS.x), STEPS.x)], -1.9, 0.0)
	_prism([Vector2(xi, STEPS.x), Vector2(_wing_x(STEPS.x), STEPS.x), Vector2(_wing_x(STEPS.y), STEPS.y), Vector2(xi, STEPS.y)], -1.9, 0.0)
	_prism([Vector2(_west_x(STEPS.y), STEPS.y), Vector2(_wing_x(STEPS.y), STEPS.y), top_e, Vector2(_west_x(RAMP_TOP), RAMP_TOP)], -1.9, 0.0)
	_prism([Vector2(_west_x(RAMP_TOP), RAMP_TOP), Vector2(P_C3.x, RAMP_TOP), P_C3, P_C2, P_SW], -1.9, 0.0)
	_prism([P_C2, P_C1, P_SW], -1.9, 0.0)
	_decks.append(_poly_deck(outline, level))

	# --- the pretil: along San Francisco (with the steps in it), along Cruces, and in round the corner to the ramp ---
	_pretil(P_NW, Vector2(_west_x(STEPS.x - 0.55), STEPS.x - 0.55))
	_pretil(Vector2(_west_x(STEPS.y + 0.55), STEPS.y + 0.55), P_SW)
	_pretil(P_SW, P_C1)
	_pretil(P_C1, P_C2)
	_pretil(P_C2, P_C3)
	cbox(Vector3(P_C3.x + 0.1, (PARAPET + 0.2) / 2.0 - 1.0, P_C3.y - 0.22), Vector3(0.34, PARAPET + 0.2 + 2.0, 0.62), "granite")      # the dressed stone it ends in
	_pillar(STEPS.x - 0.55)
	_pillar(STEPS.y)

	# --- the steps: granite, five risers, between the two pillars ---
	var going := STEPS_IN / 4.0
	for k in range(4):
		var top := -RISE * (1.0 - (k + 1) / 5.0)
		box(sx0 + k * going, -1.9, STEPS.x, xi - (sx0 + k * going), top + 1.9, STEPS.y - STEPS.x, "granite")
	quad(Vector3(sx0, -1.9, STEPS.x), Vector3(xi, -1.9, STEPS.x), Vector3(xi, 0, STEPS.x), Vector3(sx0, 0, STEPS.x), "granite", Vector3(0, 0, 1))
	quad(Vector3(sx0, -1.9, STEPS.y), Vector3(xi, -1.9, STEPS.y), Vector3(xi, 0, STEPS.y), Vector3(sx0, 0, STEPS.y), "granite", Vector3(0, 0, -1))
	quad(Vector3(xi, -0.4, STEPS.x), Vector3(xi, -0.4, STEPS.y), Vector3(xi, 0, STEPS.y), Vector3(xi, 0, STEPS.x), "granite", Vector3(-1, 0, 0))
	_hull([Vector3(sx0, -RISE, STEPS.x), Vector3(xi, 0, STEPS.x), Vector3(xi, -1.9, STEPS.x), Vector3(sx0, -1.9, STEPS.x),
		Vector3(sx0, -RISE, STEPS.y), Vector3(xi, 0, STEPS.y), Vector3(xi, -1.9, STEPS.y), Vector3(sx0, -1.9, STEPS.y)])
	_decks.append({"o": spot((sx0 + xi) / 2.0, mid_z), "ax": east, "half": STEPS_IN / 2.0, "wide": (STEPS.y - STEPS.x) / 2.0, "top": level, "ramp": STEPS_IN, "low": level - RISE})
	_post(xi + 0.15, STEPS.x - 0.22, Vector3(sx0 + 0.62, 0.8, STEPS.x - 0.22))
	_post(xi + 0.15, STEPS.y + 0.22, Vector3(sx0 + 0.62, 0.8, STEPS.y + 0.22))

	# --- the ramp up from the Calle de las Cruces along the convent's wall, and the cobbles beside it: one slope ---
	var zc := P_C3.y + 0.1
	var yc := _ramp_y(zc)
	var rx := P_C3.x
	var up := Vector3(0.0, RAMP_FOOT - RAMP_TOP, -foot).normalized()
	var e_mid := Vector2(_wing_x(zc), zc)
	var e_foot := Vector2(W2.x, RAMP_FOOT)
	quad(Vector3(rx, 0, RAMP_TOP), Vector3(top_e.x, 0, RAMP_TOP), Vector3(e_foot.x, foot, RAMP_FOOT), Vector3(rx, foot, RAMP_FOOT), "floor", up)
	pieces += 1
	var cobbles := PackedVector2Array([P_C2 + Vector2(0.0, 0.05), Vector2(rx, zc), Vector2(rx, RAMP_FOOT), Vector2(P_C1.x, RAMP_FOOT), P_C1])
	var idx := Geometry2D.triangulate_polygon(cobbles)
	for t in range(0, idx.size(), 3):
		var q: Array = []
		for k in range(3):
			var p: Vector2 = cobbles[idx[t + k]]
			q.append(Vector3(p.x, _ramp_y(p.y), p.y))
		tri(q[0], q[1], q[2], "cobble", up)
	# (the edge of the square's floor above the ramp: a face of rubble under a granite kerb)
	quad(Vector3(rx, -1.9, RAMP_TOP), Vector3(rx, -1.9, P_C3.y), Vector3(rx, 0, P_C3.y), Vector3(rx, 0, RAMP_TOP), "pretil", Vector3(1, 0, 0))
	# ...and on it a parapet between the square and the ramp, a little lower at the head of the ramp than where it
	# meets the pretil (the council's photograph of the long front shows it, with the post it ends in)
	var gx := rx - 0.42
	var g0 := RAMP_TOP + 0.25
	var g1 := P_C3.y - 0.3
	var h0 := 0.62
	pieces += 1
	quad(Vector3(gx, 0, g0), Vector3(gx, 0, g1), Vector3(gx, PARAPET, g1), Vector3(gx, h0, g0), "pretil", Vector3(-1, 0, 0))
	quad(Vector3(rx, 0, g0), Vector3(rx, 0, g1), Vector3(rx, PARAPET, g1), Vector3(rx, h0, g0), "pretil", Vector3(1, 0, 0))
	bar(Vector3(rx - 0.21, h0 + 0.065, g0 - 0.02), Vector3(rx - 0.21, PARAPET + 0.065, g1 + 0.3), 0.52, 0.13, "granite")
	box(gx - 0.05, -0.1, g0 - 0.34, 0.52, h0 + 0.3, 0.36, "granite")
	solid(Vector3(rx - 0.21, 0.5, (g0 + g1) / 2.0 - 0.1), Vector3(0.42, 1.4, g1 - g0 + 0.5))
	yard.append(spot(rx - 0.21, g0))
	yard.append(spot(rx - 0.21, g1))
	_hull([Vector3(rx, 0, RAMP_TOP), Vector3(top_e.x, 0, RAMP_TOP), Vector3(rx, yc, zc), Vector3(e_mid.x, yc, zc),
		Vector3(rx, -2.4, RAMP_TOP), Vector3(top_e.x, -2.4, RAMP_TOP), Vector3(rx, -2.4, zc), Vector3(e_mid.x, -2.4, zc)])
	var low: Array = []
	for p: Vector2 in [P_C2, e_mid, e_foot, Vector2(P_C1.x, RAMP_FOOT), P_C1]:
		low.append(Vector3(p.x, _ramp_y(p.y), p.y))
		low.append(Vector3(p.x, -2.4, p.y))
	_hull(low)
	_decks.append({"o": spot((rx + top_e.x) / 2.0, (RAMP_TOP + zc) / 2.0), "ax": -south, "half": (zc - RAMP_TOP) / 2.0, "wide": (top_e.x - rx) / 2.0, "top": level, "ramp": zc - RAMP_TOP, "low": level + yc})
	_decks.append({"o": spot((P_C1.x + e_mid.x) / 2.0, (zc + RAMP_FOOT) / 2.0), "ax": -south, "half": (RAMP_FOOT - zc) / 2.0, "wide": (e_mid.x - P_C1.x) / 2.0, "top": level, "ramp": RAMP_FOOT - RAMP_TOP, "low": level + foot})

	# --- what stands in it: two stone benches, and the column with its saint by the corner of the church ---
	_bench(_wing_x(3.0) - 0.75, 3.0, false)
	_bench(13.3, P_C2.y - 1.0, true)
	var cx := CHURCH_W + 0.5
	var top_y := column(Vector3(cx, 0, 1.3), 2.5, 0.17, 0.4)
	drum(Vector3(cx, top_y, 1.3), 0.2, 0.1, 0.8, STONE, 10)
	ball(Vector3(cx, top_y + 0.9, 1.3), 0.11, STONE, 1.0, 10, 6)
	solid(Vector3(cx, 1.7, 1.3), Vector3(0.5, 3.4, 0.5))
	yard.append(spot(cx, 1.3))
	# --- outside, on the pavement of San Francisco: the board that tells what the place is, and the no-parking sign ---
	var bx := _west_x(STEPS.x - 1.6) - 0.34
	var by := ground(bx, STEPS.x - 1.6)
	face(Vector2(bx, STEPS.x - 2.0), Vector2(bx, STEPS.x - 1.2))
	for px in [0.0, 0.8]:
		box(px - 0.035, by, -0.035, 0.07, 1.95, 0.07, 0x70757b)
		ball(Vector3(px, by + 1.97, 0.0), 0.05, 0x70757b, 1.0, 8, 4)
	box(0.045, by + 0.72, -0.02, 0.71, 1.08, 0.04, 0x9c2f3a)
	box(0.08, by + 1.5, 0.021, 0.64, 0.24, 0.006, 0xf3ecdc)
	for k in range(7):
		box(0.1, by + 0.85 + k * 0.085, 0.021, 0.6 - 0.07 * (k % 3), 0.03, 0.004, 0xe9c9c0)
	_text("IGLESIA DEL PETRIL", Vector3(0.4, by + 1.62, 0.03), 40, 0x7a2430, 0.0014)
	home()
	yard.append(spot(bx, STEPS.x - 1.6))
	_pavement([Vector2(0.55, -28.5), Vector2(0.6, -25.0), Vector2(-0.15, -24.95), Vector2(-0.15, -14.7), Vector2(0.6, -14.65), Vector2(0.0, 0.0), P_NW, Vector2(_west_x(STEPS.x - 0.6), STEPS.x - 0.6)], 1.15)
	_pavement([Vector2(_west_x(STEPS.y + 0.6), STEPS.y + 0.6), P_SW + Vector2(0.0, 0.3)], 1.15)
	var sign_at := spot(_west_x(13.0) - 0.4, 13.0)
	W.extra_props.append(["noparking", sign_at, atan2(south.x, south.y), 1])
	W.lamp_spots.append(Vector3(door.x, level + 3.6, door.y))
	W.lamp_spots.append(Vector3(gate.x, level + 3.6, gate.y))

# ---------------- the church ----------------
## the rows of rubble of a wall of "aparejo toledano": each `tall` high, with a course of brick between one and the next
func _rows(from: float, to: float, tall := 1.16, course := 0.14) -> Array:
	var out: Array = []
	var y := from
	while y + tall <= to + 0.001:
		out.append(Vector2(y, y + tall))
		y += tall + course
	return out

## those rows between x0 and x1, as panels
func _panels(x0: float, x1: float, rows: Array) -> Array:
	var out: Array = []
	for r: Vector2 in rows:
		out.append(Rect2(x0, r.x, x1 - x0, r.y - r.x))
	return out

## The dark plinth of a wall that stands on a street that is not level: `a`..`b` are the wall's ends on the plan (as
## for face(), which must already have been called with them), `lift` how far over the street the plinth comes.
func _plinth_along(a: Vector2, b: Vector2, lift: float, n := 4, key = "plinth") -> void:
	var ln := a.distance_to(b)
	var d := (b - a) / ln
	var out := Vector2(-d.y, d.x)
	var last := 0.0
	for i in range(n + 1):
		var p := a + d * (ln * i / n) + out * 0.5
		var top := ground(p.x, p.y) + lift
		if i > 0:
			plinth(ln * (i - 1) / n, ln * i / n, last, top, key)
		last = top

## a wall of plain brick (what shows over a lower roof, or looks on to a neighbour's yard)
func _plain(a: Vector2, b: Vector2, y0: float, y1: float, key = "brick") -> void:
	var ln := face(a, b)
	pieces += 1
	quad(Vector3(0, y0, 0), Vector3(ln, y0, 0), Vector3(ln, y1, 0), Vector3(0, y1, 0), key, Vector3(0, 0, 1))
	home()

## the line of rounded tiles along a ridge or a hip
func ridge(a: Vector3, b: Vector3) -> void:
	bar(a + Vector3(0, 0.03, 0), b + Vector3(0, 0.03, 0), 0.3, 0.12, 0x8f8273)

## a four-sided roof coming to a point (or to a short ridge along z): its eaves `out` beyond the walls x0..x1, z0..z1
func _hip(x0: float, x1: float, z0: float, z1: float, y: float, rise: float, out := 0.45, long := 0.0) -> Vector3:
	var a := Vector3(x0 - out, y, z1 + out)
	var b := Vector3(x1 + out, y, z1 + out)
	var c := Vector3(x1 + out, y, z0 - out)
	var d := Vector3(x0 - out, y, z0 - out)
	var mx := (x0 + x1) / 2.0
	var mz := (z0 + z1) / 2.0
	var t0 := Vector3(mx, y + rise, mz + long / 2.0)
	var t1 := Vector3(mx, y + rise, mz - long / 2.0)
	roof([a, b, t0])
	roof([c, d, t1])
	if long > 0.0:
		roof([b, c, t1, t0])
		roof([d, a, t0, t1])
	else:
		roof([b, c, t1])
		roof([d, a, t0])
	for q in [[a, t0], [b, t0], [c, t1], [d, t1], [t0, t1]]:
		if (q[0] as Vector3).distance_to(q[1]) > 0.1:
			ridge(q[0], q[1])
	return (t0 + t1) / 2.0

## what crowns a roof: a little lead spire, a ball, and a vane on its rod
func _finial(at: Vector3, tall := 1.0) -> void:
	drum(at - Vector3(0, 0.1, 0), 0.22, 0.07, tall * 0.55, 0x6f7376, 8)
	ball(at + Vector3(0, tall * 0.55 + 0.1, 0), 0.13, 0x7d6a45, 1.0, 8, 5)
	cbox(at + Vector3(0, tall * 0.55 + 0.75, 0), Vector3(0.035, 1.2, 0.035), IRON)
	cbox(at + Vector3(0, tall * 0.55 + 1.05, 0), Vector3(0.5, 0.035, 0.035), IRON)
	cbox(at + Vector3(0.12, tall * 0.55 + 1.28, 0), Vector3(0.34, 0.16, 0.02), IRON)

func _church() -> void:
	var wide := CHURCH_W
	var mid := wide / 2.0
	var rows := _rows(0.95, NAVE - 0.75)
	var rows_f := _rows(0.95, NAVE - 0.75, 1.1, 0.2)
	# --- the front, on the square: brick at the corners, rubble in rows between courses of brick, a window over the door ---
	face(Vector2(0, 0), Vector2(wide, 0))
	var win := Rect2(mid - 0.48, 7.25, 0.96, 1.7)
	var dr := 1.1                                                 # the doorway: half its width, and where its arch springs
	var spring := 2.7
	var doorway := Rect2(mid - dr, -0.5, 2.0 * dr, spring + dr + 0.5)             # (square: the arch is cut in it below)
	masonry(0.0, wide, -3.0, NAVE - 0.4, [win, doorway], _panels(1.5, wide - 1.5, rows_f),
		"brick", "rubble", [Rect2(mid - 0.85, 6.9, 1.7, 2.65), Rect2(mid - 1.95, -0.5, 3.9, 5.15)])
	cornice(0.0, wide, NAVE, true, "brick", 1.8)
	box(0.0, -0.4, 0.0, mid - 1.75, 1.1, 0.05, "granite")       # the dressed stone at its foot
	box(mid + 1.75, -0.4, 0.0, mid - 1.75, 1.1, 0.05, "granite")
	# the doorway: a round arch of big pale granite blocks in a square frame of the same; the door nearly black, with
	# its rows of studs
	spandrels(mid, spring, dr, 0.06, "granite")
	ring(mid, spring, dr, 1.75, 0.06, DEEP + 0.06, "granite", 13)
	spandrels(mid, spring, 1.75, 0.06, "granite")
	for s in [-1.0, 1.0]:
		box(mid + s * 1.425 - 0.325, 0.0, 0.0, 0.65, spring, 0.06, "granite")
		quad(Vector3(mid + s * dr, 0, -DEEP), Vector3(mid + s * dr, 0, 0.06), Vector3(mid + s * dr, spring, 0.06), Vector3(mid + s * dr, spring, -DEEP), "granite", Vector3(-s, 0, 0))
	box(mid - 1.8, spring + 1.75, 0.0, 3.6, 0.1, 0.11, "granite")                 # (the lip over that frame)
	arched(mid, 0.0, spring, dr, -DEEP + 0.05, DOOR)
	box(mid - 0.02, 0.0, -DEEP + 0.05, 0.04, spring + dr - 0.05, 0.02, 0x16100c)
	for s in [-1.0, 1.0]:
		studs(mid + s * 0.57 - 0.43, mid + s * 0.57 + 0.43, 0.3, spring, -DEEP + 0.05, 5, 12)
		studs(mid + s * 0.43 - 0.3, mid + s * 0.43 + 0.3, spring + 0.1, spring + 0.7, -DEEP + 0.05, 3, 3)
	box(mid - dr, -0.02, -DEEP, 2.0 * dr, 0.14, DEEP + 0.5, "granite")              # its step
	# the window, its leaded glass behind bars flush with the wall; the little stone niche under it
	window(win, 0x3a2a1e, 0x2c3a4a, 3)
	grille(win, 0.03)
	box(win.position.x - 0.22, win.position.y - 0.12, 0.0, win.size.x + 0.44, 0.12, 0.07, "brick")
	box(win.position.x - 0.2, win.end.y, 0.0, win.size.x + 0.4, 0.3, 0.03, "brick")
	box(mid - 0.45, 5.95, 0.0, 0.9, 0.62, 0.14, STONE)
	box(mid - 0.24, 6.03, 0.14, 0.48, 0.46, 0.012, 0x6d675c)
	slab(PackedVector2Array([Vector2(mid - 0.55, 6.57), Vector2(mid + 0.55, 6.57), Vector2(mid, 6.93)]), 0.16, 0.16, STONE)
	box(mid - 0.55, 5.88, 0.0, 1.1, 0.08, 0.2, STONE)
	# the marble that remembers somebody, to the right of the door
	box(wide - 1.45, 2.64, 0.0, 0.77, 1.09, 0.035, 0xecE8dc)
	for k in range(8):
		box(wide - 1.38, 2.8 + k * 0.105, 0.035, 0.62 - 0.08 * ((k * 3) % 4), 0.028, 0.004, 0x8a8478)
	# --- the porch: a tiled roof on two granite columns, its timber dark, its ceiling painted ---
	var reach := 3.55                                             # where the columns stand
	var eave := 4.95
	var px0 := mid - 2.2
	var px1 := mid + 2.2
	var top := 0.0
	for s in [-1.0, 1.0]:
		top = column(Vector3(mid + s * 1.7, 0.0, reach), 2.75, 0.2, 0.95, 0.6)
		cbox(Vector3(mid + s * 1.7, top + 0.1, reach), Vector3(1.25, 0.2, 0.3), "wood")           # the carved bracket on its head
		cbox(Vector3(mid + s * 1.7, top + 0.1, reach - 0.3), Vector3(0.3, 0.2, 0.9), "wood")
		bar(Vector3(mid + s * 1.7, top + 0.33, -0.1), Vector3(mid + s * 1.7, top + 0.33, reach + 0.25), 0.24, 0.26, "wood")     # the beam back to the wall
		cbox(Vector3(mid + s * 1.7, top + 0.05, 0.3), Vector3(0.26, 0.3, 0.6), "wood")           # ...and what carries it there
		solid(Vector3(mid + s * 1.7, 1.9, reach), Vector3(0.64, 3.8, 0.64))
		yard.append(spot(mid + s * 1.7, reach))
	bar(Vector3(px0 + 0.45, top + 0.33, reach), Vector3(px1 - 0.45, top + 0.33, reach), 0.24, 0.26, "wood")              # the beam across the front
	var ceil_y := top + 0.47
	box(mid - 1.58, ceil_y, 0.02, 3.16, 0.03, reach - 0.14, "white")
	for q in [[mid - 1.58, 0.02, 3.16, 0.16], [mid - 1.58, reach - 0.28, 3.16, 0.16], [mid - 1.58, 0.02, 0.16, reach - 0.14], [mid + 1.42, 0.02, 0.16, reach - 0.14]]:
		box(q[0], ceil_y - 0.012, q[1], q[2], 0.012, q[3], 0xb6553a)                       # its painted border
	box(mid - 0.9, ceil_y - 0.01, 0.75, 1.8, 0.01, reach - 1.6, 0x9fbad0)             # ...and the blue of its middle
	cbox(Vector3(mid, ceil_y - 0.02, reach / 2.0), Vector3(0.5, 0.012, 0.3), 0xc9a24a)
	var n_tail := 9
	for k in range(n_tail):                                       # the ends of its rafters, under the eaves
		var tx := lerpf(px0 + 0.25, px1 - 0.25, k / float(n_tail - 1))
		bar(Vector3(tx, eave - 0.02, reach + 0.25), Vector3(tx, eave - 0.2, reach + 0.82), 0.09, 0.12, "wood")
	for s in [-1.0, 1.0]:
		for k in range(6):
			var tz := lerpf(0.35, reach + 0.1, k / 5.0)
			bar(Vector3(mid + s * 1.75, eave - 0.02, tz), Vector3(mid + s * 2.15, eave - 0.2, tz), 0.09, 0.12, "wood")
	var out_z := reach + 0.9
	var ridge_y := eave + 1.15
	roof([Vector3(px0, eave - 0.22, out_z), Vector3(px1, eave - 0.22, out_z), Vector3(px1 - 1.3, ridge_y, 0.04), Vector3(px0 + 1.3, ridge_y, 0.04)])
	roof([Vector3(px0, eave - 0.22, 0.04), Vector3(px0, eave - 0.22, out_z), Vector3(px0 + 1.3, ridge_y, 0.04)])
	roof([Vector3(px1, eave - 0.22, out_z), Vector3(px1, eave - 0.22, 0.04), Vector3(px1 - 1.3, ridge_y, 0.04)])
	ridge(Vector3(px0, eave - 0.22, out_z), Vector3(px0 + 1.3, ridge_y, 0.04))
	ridge(Vector3(px1, eave - 0.22, out_z), Vector3(px1 - 1.3, ridge_y, 0.04))
	quad(Vector3(px0, eave - 0.24, 0.04), Vector3(px1, eave - 0.24, 0.04), Vector3(px1, eave - 0.24, out_z), Vector3(px0, eave - 0.24, out_z), 0x3a2b21, Vector3(0, -1, 0))      # the boards under it
	home()

	# --- its long side on the Calle de San Francisco: three columns of rubble between piers of brick, on a dark plinth ---
	var n_a := Vector2(0.6, -14.7)                                # the nave's north end on that street, and the tower's two
	var t_s := Vector2(-0.15, -14.7)
	var t_n := Vector2(0.55, -25.0)
	var ln := face(n_a, Vector2(0, 0))
	var panels: Array = []
	for col in [[1.25, 4.75], [5.85, 9.3], [10.4, ln - 1.3]]:
		panels.append_array(_panels(col[0], col[1], rows))
	masonry(0.0, ln, -3.0, NAVE - 0.4, [], panels)
	cornice(0.0, ln, NAVE, true, "brick", 1.8)
	_plinth_along(n_a, Vector2(0, 0), 1.15)
	# the bell-gable that rides on that wall near the front: brick, one opening, its bell on a green yoke
	var ex := ln - 3.7
	var eh := NAVE + 0.02
	for s in [-1.0, 1.0]:
		box(ex + s * 0.85 - 0.3, eh, -0.78, 0.6, 2.1, 0.78, "brick")
	box(ex - 1.15, eh + 2.1 + 0.55, -0.78, 2.3, 0.5, 0.78, "brick")
	for zf in [0.0, -0.78]:
		var keep := _xf
		if zf < 0.0:
			_xf = _xf * Transform3D(Basis(Vector3.UP, PI), Vector3(2.0 * ex, 0, -0.78))
		spandrels(ex, eh + 2.1, 0.55, 0.0, "brick")
		slab(PackedVector2Array([Vector2(ex - 1.25, eh + 3.3), Vector2(ex + 1.25, eh + 3.3), Vector2(ex, eh + 4.1)]), 0.0, 0.0, "brick")
		_xf = keep
	quad(Vector3(ex - 1.25, eh + 3.3, 0.0), Vector3(ex, eh + 4.1, 0.0), Vector3(ex, eh + 4.1, -0.78), Vector3(ex - 1.25, eh + 3.3, -0.78), "brick", Vector3(-0.5, 0.8, 0).normalized())
	quad(Vector3(ex + 1.25, eh + 3.3, 0.0), Vector3(ex, eh + 4.1, 0.0), Vector3(ex, eh + 4.1, -0.78), Vector3(ex + 1.25, eh + 3.3, -0.78), "brick", Vector3(0.5, 0.8, 0).normalized())
	box(ex - 1.25, eh + 3.15, -0.84, 2.5, 0.15, 0.9, "brick")
	box(ex - 1.22, eh - 0.0, -0.82, 2.44, 0.12, 0.86, "brick")
	drum(Vector3(ex, eh + 1.25, -0.39), 0.3, 0.15, 0.55, 0x6d5a33, 10)
	cbox(Vector3(ex, eh + 1.95, -0.39), Vector3(0.9, 0.22, 0.16), 0x3f6a4a)
	cbox(Vector3(ex, eh + 2.25, -0.39), Vector3(0.14, 0.5, 0.14), 0x3f6a4a)
	home()

	# --- the tower over the crossing: higher, a little proud of the nave, a window half way up, a pointed roof ---
	var rows_t := _rows(0.95, TOWER - 0.75)
	ln = face(t_n, t_s)
	var twin := Rect2(ln / 2.0 - 0.5, 9.3, 1.0, 1.9)
	panels = []
	for col in [[1.3, ln / 2.0 - 0.75], [ln / 2.0 + 0.75, ln - 1.3]]:
		panels.append_array(_panels(col[0], col[1], rows_t))
	masonry(0.0, ln, -3.0, TOWER - 0.4, [twin], panels)
	cornice(0.0, ln, TOWER, true, "brick", 1.8)
	_plinth_along(t_n, t_s, 1.15, 3)
	window(twin, 0x3a2a1e, 0x1f2a33, 2)
	box(twin.position.x + 0.06, twin.position.y + 0.06, -DEEP + 0.09, 0.42, twin.size.y - 0.12, 0.03, 0x3f7a5c)        # one green shutter, shut
	box(twin.position.x - 0.2, twin.position.y - 0.12, 0.0, twin.size.x + 0.4, 0.12, 0.08, "brick")
	box(twin.position.x - 0.18, twin.end.y, 0.0, twin.size.x + 0.36, 0.28, 0.03, "brick")
	# the Virgin in tiles that looks on to the street from this wall, under her own little roof (the town's patroness:
	# of Valdeacero, in the game)
	var vx := ln * 0.7
	var vy := ground(-0.6, -17.8) + 2.1
	box(vx - 0.37, vy - 0.05, 0.0, 0.74, 0.98, 0.045, 0x3a2b21)
	box(vx - 0.31, vy, 0.045, 0.62, 0.86, 0.01, 0xe8edf1)
	for q in [[vx - 0.31, vy, 0.62, 0.05], [vx - 0.31, vy + 0.81, 0.62, 0.05], [vx - 0.31, vy, 0.05, 0.86], [vx + 0.26, vy, 0.05, 0.86]]:
		box(q[0], q[1], 0.055, q[2], q[3], 0.004, 0x2f5fa8)
	slab(PackedVector2Array([Vector2(vx - 0.17, vy + 0.1), Vector2(vx + 0.17, vy + 0.1), Vector2(vx, vy + 0.6)]), 0.06, 0.0, 0x3d6fb5)
	ball(Vector3(vx, vy + 0.62, 0.06), 0.065, 0xf0d9c0, 1.0, 8, 5)
	ball(Vector3(vx, vy + 0.71, 0.055), 0.05, 0xe2b93a, 0.5, 8, 4)
	for s2 in [-1.0, 1.0]:
		roof([Vector3(vx + s2 * 0.6, vy + 1.0, 0.0), Vector3(vx, vy + 1.3, 0.0), Vector3(vx, vy + 1.3, 0.45), Vector3(vx + s2 * 0.6, vy + 1.0, 0.45)])
		bar(Vector3(vx + s2 * 0.45, vy + 0.9, 0.02), Vector3(vx + s2 * 0.45, vy + 1.02, 0.4), 0.06, 0.07, "wood")
	slab(PackedVector2Array([Vector2(vx - 0.55, vy + 0.98), Vector2(vx + 0.55, vy + 0.98), Vector2(vx, vy + 1.25)]), 0.43, 0.02, "wood")
	home()
	var t_e := Vector2(9.9, -14.7)
	var t_ne := Vector2(10.5, -25.0)
	ln = face(t_s, t_e)                                           # its south face: over the roof of the nave, and its corner down to the street
	masonry(0.0, ln, NAVE - 0.5, TOWER - 0.4, [], _panels(1.3, ln - 1.3, _rows(NAVE + 0.6, TOWER - 0.75)))
	masonry(0.0, 0.8, -3.0, NAVE - 0.5, [], [])
	cornice(0.0, ln, TOWER, true, "brick", 1.8)
	home()
	ln = face(t_e, t_ne)                                          # east, over the convent's roofs
	masonry(0.0, ln, WING - 0.5, TOWER - 0.4, [], _panels(1.3, ln - 1.3, _rows(WING + 3.6, TOWER - 0.75)))
	cornice(0.0, ln, TOWER, true, "brick", 1.8)
	home()
	ln = face(t_ne, t_n)                                          # north, over the chancel
	masonry(0.0, ln, 3.0, TOWER - 0.4, [], _panels(1.3, ln - 1.3, _rows(CHANCEL + 2.6, TOWER - 0.75)))
	cornice(0.0, ln, TOWER, true, "brick", 1.8)
	home()
	var tip := _hip(-0.15, 10.2, -25.0, -14.7, TOWER, 3.5, 0.68)
	_finial(tip, 1.2)

	# --- the roof of the nave: three slopes, the one at the front a hip ---
	var e := 0.45
	var en := 0.66                                                # (the nave's eaves clear its big cornice)
	var ry := NAVE + 3.0
	var r_s := Vector3(mid, ry, -4.3)
	var r_n := Vector3(5.2, ry, -14.7)
	roof([Vector3(-en, NAVE, en), Vector3(wide + en, NAVE, en), r_s])
	roof([Vector3(0.6 - en, NAVE, -14.7), Vector3(-en, NAVE, en), r_s, r_n])
	roof([Vector3(wide + en, NAVE, en), Vector3(9.9 + en, NAVE, -14.7), r_n, r_s])
	ridge(r_s, r_n)
	ridge(Vector3(-en, NAVE, en), r_s)
	ridge(Vector3(wide + en, NAVE, en), r_s)
	# the nave's east wall, where it shows over the convent's roofs
	ln = face(Vector2(wide, 0), t_e)
	masonry(0.0, ln, WING - 0.5, NAVE - 0.4, [], _panels(1.3, ln - 1.3, _rows(WING + 3.4, NAVE - 0.75)))
	cornice(0.0, ln, NAVE, true, "brick", 1.8)
	home()

	# --- beyond the tower: the chancel, lower, and the lean-to against it on the street ---
	var c_w := 4.9
	_plain(Vector2(10.7, -28.4), Vector2(c_w, -28.4), 3.0, CHANCEL)
	_plain(Vector2(10.5, -25.0), Vector2(10.7, -28.4), -3.0, CHANCEL)
	face(Vector2(c_w, -28.4), Vector2(c_w, -25.0))
	masonry(0.0, 3.4, 3.0, CHANCEL - 0.4, [], [Rect2(0.4, CHANCEL - 4.6, 2.6, 3.4)])      # (its west wall, over the lean-to: a panel of rubble high on it)
	cornice(0.0, 3.4, CHANCEL, false)
	home()
	var cy := CHANCEL + 1.9
	roof([Vector3(c_w - e, CHANCEL, -28.4 - e), Vector3(c_w - e, CHANCEL, -25.0), Vector3(7.8, cy, -25.0), Vector3(7.8, cy, -26.6)])
	roof([Vector3(10.7 + e, CHANCEL, -25.0), Vector3(10.7 + e, CHANCEL, -28.4 - e), Vector3(7.8, cy, -26.6), Vector3(7.8, cy, -25.0)])
	roof([Vector3(c_w - e, CHANCEL, -28.4 - e), Vector3(10.7 + e, CHANCEL, -28.4 - e), Vector3(7.8, cy, -26.6)])
	var l_s := Vector2(0.6, -25.02)                               # the lean-to: rubble, two slits, a roof of its own
	var l_n := Vector2(0.5, -28.5)
	ln = face(l_n, l_s)
	var gy := ground(0.0, -26.8)
	var lean := gy + 3.35
	masonry(0.0, ln, -3.0, lean, [Rect2(0.75, gy + 2.1, 0.34, 0.42), Rect2(2.25, gy + 1.75, 0.2, 0.75)], [Rect2(0.3, gy + 0.4, ln - 0.55, 2.5)])
	box(0.75, gy + 2.1, -DEEP + 0.02, 0.34, 0.42, 0.02, 0x15120f)
	box(2.25, gy + 1.75, -DEEP + 0.02, 0.2, 0.75, 0.02, 0x15120f)
	cornice(0.0, ln, lean + 0.42, false)
	_plinth_along(l_n, l_s, 0.55, 1)
	home()
	roof([Vector3(0.5 - e, lean + 0.4, -28.5), Vector3(0.6 - e, lean + 0.4, -25.02), Vector3(c_w, lean + 2.2, -25.02), Vector3(c_w, lean + 2.2, -28.5)])
	_plain(Vector2(c_w, -28.5), Vector2(0.5, -28.5), -3.0, lean + 2.2)

# ---------------- the convent ----------------
## a window of the convent in its hole: dark leaves, a frame of pale stone, and on the ground floor its grille
func _conv_window(r: Rect2, barred: bool, framed := true) -> void:
	window(r, 0x3b2a20, 0x1c2630, 1)
	if framed:
		stone_frame(r, 0.09, 0.03, FRAME)
	if barred:
		grille(r, 0.15)

## a little gabled window on the convent's roof, looking south: (x, z) is the middle of its front
func _dormer(x: float, z: float, wide := 1.0) -> void:
	var y0 := WING + PITCH * (0.35 - z) - 0.12
	var h := 0.95
	var hw := wide / 2.0
	box(x - hw, y0, z - 1.6, wide, h, 1.6, "white")
	box(x - wide * 0.27, y0 + 0.27, z, wide * 0.54, 0.52, 0.012, 0x1a1512)
	slab(PackedVector2Array([Vector2(x - hw, y0 + h), Vector2(x + hw, y0 + h), Vector2(x, y0 + h + 0.36)]), z, 0.0, "white")
	for s in [-1.0, 1.0]:
		roof([Vector3(x + s * (hw + 0.14), y0 + h - 0.06, z + 0.16), Vector3(x, y0 + h + 0.4, z + 0.16), Vector3(x, y0 + h + 0.4, z - 1.7), Vector3(x + s * (hw + 0.14), y0 + h - 0.06, z - 1.7)])

func _convent() -> void:
	var e := 0.35
	var holes: Array = []
	var over: Array = []
	var panels: Array = []
	# --- the south range, on the square beside the church: mostly rubble, in rows, with brick round every opening ---
	var ln := face(Vector2(CHURCH_W, 0.0), W1)
	var up: Array = [Rect2(0.79, 5.1, 0.99, 1.1), Rect2(2.48, 5.55, 0.47, 0.55), Rect2(4.86, 5.1, 0.95, 1.1), Rect2(8.5, 4.4, 0.8, 1.0)]
	var low_win := Rect2(1.48, 1.0, 1.0, 1.4)
	var dh := 2.35                                                # how high its door is
	var way_in := Rect2(4.79, -0.5, 1.43, dh + 0.5)
	var slit := Rect2(8.45, 1.6, 0.28, 0.5)
	holes = up + [low_win, way_in, slit]
	for r: Rect2 in holes:
		over.append(r.grow(0.3))
	# (what is rubble on it: a band under the cornice, two rows between its floors, the foot of its right half, patches)
	panels = [Rect2(0.3, 6.62, ln - 0.6, 0.4), Rect2(0.3, 4.12, ln - 0.6, 0.74), Rect2(0.3, 3.5, 4.3, 0.5), Rect2(6.6, 3.5, ln - 6.9, 0.5),
		Rect2(6.55, 0.8, ln - 6.85, 1.0), Rect2(6.55, 1.92, ln - 6.85, 1.42), Rect2(3.15, 5.0, 1.35, 0.5), Rect2(6.2, 5.62, 1.9, 0.62),
		Rect2(6.25, 5.02, 1.55, 0.44), Rect2(0.3, 0.8, 0.85, 1.1), Rect2(2.8, 0.8, 1.2, 0.55)]
	masonry(0.0, ln, -3.0, WING - 0.4, holes, panels, "brick", "rubble", over)
	cornice(0.0, ln, WING)
	plinth(0.0, way_in.position.x - 0.1, 0.8, 0.8, "zocalo", 0.04)
	plinth(way_in.end.x + 0.1, ln, 0.8, 0.8, "zocalo", 0.04)
	box(0.03, 0.0, 0.0, 0.09, WING - 0.45, 0.09, 0x6f4f3a)                    # (the pipe that brings the rain down beside the church)
	for k in range(up.size()):
		_conv_window(up[k], k == 3, k != 1)
	window(low_win, 0x55705c, 0x8fa894, 5)                        # the window by the way in: a green blind behind its bars
	grille(low_win, 0.1)
	box(low_win.position.x - 0.12, low_win.position.y - 0.1, 0.0, low_win.size.x + 0.24, 0.1, 0.06, "brick")
	box(slit.position.x, slit.position.y, -DEEP + 0.02, slit.size.x, slit.size.y, 0.02, 0x15120f)
	var dm := way_in.position.x + way_in.size.x / 2.0
	box(way_in.position.x, 0.0, -DEEP + 0.04, way_in.size.x, dh, 0.05, 0x3d2a1f)                 # the way in to what the convent is now: a plain old door of two leaves...
	box(dm - 0.015, 0.0, -DEEP + 0.09, 0.03, dh, 0.01, 0x1a120d)
	for s in [-1.0, 1.0]:
		for q in [[0.18, 0.6], [0.92, 0.62], [1.68, 0.5]]:
			box(dm + s * way_in.size.x * 0.25 - 0.24, q[0], -DEEP + 0.09, 0.48, q[1], 0.012, 0x4a3324)
	box(way_in.position.x - 0.3, dh, -0.02, way_in.size.x + 0.6, 0.22, 0.2, "wood")              # ...under a beam on two carved ends...
	for s in [-1.0, 1.0]:
		box(dm + s * (way_in.size.x / 2.0 + 0.14) - 0.09, dh - 0.2, 0.0, 0.18, 0.2, 0.16, "wood")
	box(dm - 0.8, dh + 0.42, 0.0, 1.32, 0.68, 0.045, STONE)        # ...and the stone that says what it is
	_text("MUSEO", Vector3(dm - 0.14, dh + 0.76, 0.05), 64, 0x5a4a38, 0.0034)
	box(way_in.position.x - 0.83, 1.5, 0.0, 0.52, 0.46, 0.04, 0x33251c)          # the board with its opening hours
	box(way_in.position.x - 0.8, 1.53, 0.04, 0.46, 0.4, 0.004, 0xe9e4d6)
	home()
	_dormer(CHURCH_W + 2.2, -1.5)

	# --- the long front that closes the square on the east: brick, panels of rubble scattered over it, the doorway ---
	ln = face(W1, W2)
	var c := 8.73
	var up_w: Array = []
	for x in [1.17, 4.03]:
		up_w.append(Rect2(x - 0.55, 4.73, 1.1, 1.77))
	for x in [7.12, 10.3, 13.06, 17.3]:
		up_w.append(Rect2(x - 0.5, 5.3, 1.0, 1.14))
	var low_w: Array = [Rect2(4.28, 2.13, 1.04, 1.5), Rect2(10.6, 2.08, 1.0, 1.4), Rect2(16.45, 2.2, 0.9, 1.3)]
	var portal := Rect2(c - 1.0, -0.5, 2.0, 3.28)
	var back := Rect2(16.55, -0.95, 0.72, 2.95)                   # a low door on the ramp
	# its panels of rubble, each where the council's square-on photograph has it (from, to, bottom, top): three rows
	# to the ground floor, a band under the upper windows, columns between them up to the cornice
	panels = []
	for q in [[1.35, 3.31, 3.26, 4.12], [1.22, 3.31, 2.08, 3.07], [1.35, 2.27, 1.09, 1.95], [2.4, 3.31, 1.09, 1.95], [4.3, 5.3, 1.1, 1.92],
			[6.12, 6.56, 2.08, 3.12], [6.22, 6.48, 1.3, 1.95], [12.73, 13.46, 3.26, 4.12], [12.63, 13.59, 2.14, 3.07], [12.73, 13.46, 1.17, 1.95],
			[15.03, 15.42, 3.26, 4.12], [14.82, 15.68, 2.21, 3.07], [15.1, 15.6, 1.17, 1.95], [18.67, 19.97, 3.26, 4.12], [18.8, 19.97, 2.08, 3.07],
			[18.93, 19.97, 1.3, 1.95], [20.4, 21.4, 3.26, 4.12], [20.4, 21.4, 2.08, 3.07],
			[2.0, 3.2, 4.6, 5.08], [5.4, 6.9, 4.6, 5.08], [10.6, 11.4, 4.6, 5.08], [13.46, 14.95, 4.6, 5.08], [15.1, 16.07, 4.6, 5.08],
			[17.11, 18.15, 4.6, 5.08], [18.8, 19.97, 4.6, 5.08],
			[2.14, 2.92, 5.3, 5.95], [2.14, 2.92, 6.1, 7.05], [5.08, 6.04, 5.3, 6.0], [5.08, 6.04, 6.12, 7.05], [8.05, 9.3, 6.0, 7.05],
			[11.5, 11.75, 5.5, 6.6], [14.11, 15.03, 5.2, 5.6], [14.11, 15.03, 5.73, 6.25], [15.5, 16.38, 5.26, 5.95], [15.5, 16.38, 6.12, 7.05],
			[18.41, 19.45, 5.2, 5.73], [18.41, 19.45, 6.0, 7.05], [20.3, 21.3, 5.3, 6.0], [20.3, 21.3, 6.12, 7.05]]:
		panels.append(Rect2(q[0], q[2], q[1] - q[0], q[3] - q[2]))
	masonry(0.0, ln, -3.0, WING - 0.4, up_w + low_w + [portal, back], panels, "brick", "panel")
	cornice(0.0, ln, WING)
	box(0.0, 4.3, 0.0, c - 2.15, 0.14, 0.05, "brick")             # the course between its two floors
	box(c + 2.15, 4.3, 0.0, ln - c - 2.15, 0.14, 0.05, "brick")
	plinth(0.0, c - 1.78, 0.95, 0.95, "zocalo", 0.04)
	plinth(c + 1.78, back.position.x - 0.05, 0.95, 0.95, "zocalo", 0.04)
	plinth(back.end.x + 0.05, ln, 0.95, 0.95, "zocalo", 0.04)
	for k in range(up_w.size()):
		_conv_window(up_w[k], false)
		if k < 2:                                                 # (the first two come down to the floor, behind a rail)
			var r: Rect2 = up_w[k]
			grille(Rect2(r.position.x - 0.05, r.position.y + 0.05, r.size.x + 0.1, 0.9), 0.3)
			box(r.position.x - 0.18, r.position.y - 0.1, 0.0, r.size.x + 0.36, 0.1, 0.36, FRAME)
	for k in range(low_w.size()):
		_conv_window(low_w[k], true, k == 1)
	box(back.position.x, back.position.y, -DEEP + 0.04, back.size.x, back.size.y, 0.05, 0x33251c)
	# its doorway: a flat arch of fanned brick between two half-columns of brick on tall stone pedestals; over them an
	# entablature, and a pediment that breaks into a round arch over the founders' shield
	box(portal.position.x, 0.0, -DEEP + 0.04, 2.0, 2.78, 0.05, 0x3d2a1f)
	box(c - 0.015, 0.0, -DEEP + 0.09, 0.03, 2.78, 0.01, 0x1a120d)
	box(portal.position.x, 2.08, -DEEP + 0.09, 2.0, 0.05, 0.02, 0x2a1c14)                 # (the rail under its fixed top)
	for s in [-1.0, 1.0]:
		for q in [[0.2, 0.66], [1.0, 0.92], [2.2, 0.46]]:                         # its leaves are panelled
			box(c + s * 0.5 - 0.36, q[0], -DEEP + 0.09, 0.72, q[1], 0.012, 0x4a3324)
		var px: float = c + s * 1.38
		drum(Vector3(px, 0.0, 0.2), 0.42, 0.36, 0.14, "caliza", 12)           # a round stone foot under a square block...
		drum(Vector3(px, 0.14, 0.2), 0.33, 0.31, 0.72, "caliza", 12)
		box(px - 0.37, 0.86, 0.0, 0.74, 0.64, 0.56, "caliza")
		drum(Vector3(px, 1.5, 0.22), 0.2, 0.17, 1.94, "trim", 12)             # ...the half-column of brick, and its capital
		box(px - 0.27, 3.44, 0.0, 0.54, 0.22, 0.48, "caliza")
		bar(Vector3(c + s * 2.02, 4.47, 0.2), Vector3(c + s * 0.62, 5.2, 0.2), 0.4, 0.16, "moulding")       # the pediment's two slopes
		cbox(Vector3(c + s * 0.7, 5.14, 0.2), Vector3(0.22, 0.22, 0.42), "moulding")
		cbox(Vector3(c + s * 1.98, 4.5, 0.21), Vector3(0.24, 0.2, 0.44), "moulding")
	box(c - 1.12, 2.78, 0.0, 2.24, 0.88, 0.04, "trim")                        # the flat arch
	box(c - 1.94, 3.68, 0.0, 3.88, 0.54, 0.3, "moulding")                     # the entablature...
	box(c - 2.1, 4.22, 0.0, 4.2, 0.2, 0.46, "moulding")                       # ...and its cornice, on its teeth
	for i in range(14):
		box(c - 1.89 + i * 0.28, 4.12, 0.3, 0.14, 0.1, 0.09, "moulding")
	var tymp := PackedVector2Array([Vector2(c - 1.98, 4.42), Vector2(c + 1.98, 4.42), Vector2(c + 0.66, 5.14)])
	for i in range(1, 12):
		var ang := deg_to_rad(12.0 + (180.0 - 24.0) * i / 12.0)
		tymp.append(Vector2(c + 0.67 * cos(ang), 5.0 + 0.67 * sin(ang)))
	tymp.append(Vector2(c - 0.66, 5.14))
	slab(tymp, 0.12, 0.12, "brick")
	ring(c, 5.0, 0.6, 0.78, 0.42, 0.3, "moulding", 12)                        # the round arch it breaks into
	slab(oval(c, 4.87, 0.3, 0.42), 0.24, 0.12, STONE)                         # the shield of the founders
	slab(oval(c, 4.87, 0.2, 0.3, 12), 0.255, 0.0, 0xbfa78f)
	box(c - 0.012, 4.6, 0.26, 0.024, 0.54, 0.006, 0xa8917a)
	box(c - 0.19, 4.86, 0.26, 0.38, 0.022, 0.006, 0xa8917a)
	ball(Vector3(c, 5.36, 0.2), 0.12, STONE, 1.0, 8, 5)
	home()

	# --- its end on the Calle de las Cruces: the same brick, a barred window under a low arch, a dark plinth ---
	var s2 := Vector2(26.4, 23.73)
	var s3 := Vector2(31.0, 24.7)
	ln = face(W2, s2)
	var arch := Rect2(4.07, 1.2, 1.36, 1.98)
	var up_s := Rect2(4.5, 5.3, 1.0, 1.14)
	panels = []
	for col in [[0.6, 1.8], [2.3, 3.5], [6.0, 7.2], [7.6, 8.4]]:
		panels.append_array(_panels(col[0], col[1], [Vector2(0.95, 2.3), Vector2(2.55, 3.9), Vector2(4.62, 5.62), Vector2(5.84, 6.84)]))
	masonry(0.0, ln, -3.0, WING - 0.4, [arch, up_s], panels, "brick", "panel")
	spandrels(4.75, 2.5, 0.68, 0.0, "brick")
	arched(4.75, 1.2, 2.5, 0.68, -DEEP + 0.03, 0x1c2630)
	grille(arch, 0.16)
	box(arch.position.x - 0.1, arch.position.y - 0.1, 0.0, arch.size.x + 0.2, 0.1, 0.08, "brick")
	_conv_window(up_s, false, false)
	box(0.0, 4.3, 0.0, ln, 0.14, 0.05, "brick")
	cornice(0.0, ln, WING)
	_plinth_along(W2, s2, 1.5, 2)
	home()
	# ...and the low white house that follows it there
	ln = face(s2, s3)
	var gy := ground(28.7, 25.2)
	var small_door := Rect2(0.7, gy - 0.3, 0.95, 2.4)
	var small_win := Rect2(2.9, gy + 3.5, 0.9, 1.05)
	masonry(0.0, ln, -3.0, 5.8, [small_door, small_win], [], "white", "white")
	slab(PackedVector2Array([Vector2(0.0, 5.8), Vector2(ln, 5.8), Vector2(0.0, 7.05)]), 0.0, 0.0, "white")
	box(small_door.position.x, gy, -DEEP + 0.04, small_door.size.x, 2.1, 0.05, 0x4a3323)
	window(small_win, 0x3b2a20, 0x1c2630, 1)
	plinth(0.0, small_door.position.x, gy + 0.7, gy + 0.7, "zocalo", 0.03)
	plinth(small_door.end.x, ln, gy + 0.7, gy + 0.7, "zocalo", 0.03)
	home()
	# --- the walls nobody sees from a street: on to the neighbours' yards ---
	_plain(Vector2(34.0, -22.6), Vector2(10.5, -24.8), -3.0, WING)
	_plain(s3, Vector2(33.2, -10.0), -3.0, 5.8)
	_plain(Vector2(33.2, -10.0), Vector2(34.0, -22.6), -3.0, 5.8)
	_plain(s2, Vector2(26.4, -24.7), 5.5, WING)

	# --- its roofs: old tile, sloping in from every eave to a flat top round the cloister, which is glazed over ---
	var top := WING + 3.0
	var cut := 3.0 / PITCH
	var x_e := 26.4 + e
	roof([Vector3(CHURCH_W - 0.2, WING, e), Vector3(x_e, WING, e), Vector3(x_e - cut, top, e - cut), Vector3(CHURCH_W - 0.2, top, e - cut)])
	roof([Vector3(x_e, WING, e), Vector3(x_e, WING, -24.7 - e), Vector3(x_e - cut, top, -24.7 - e + cut), Vector3(x_e - cut, top, e - cut)])
	roof([Vector3(x_e, WING, -24.7 - e), Vector3(10.2, WING, -24.7 - e), Vector3(10.2, top, -24.7 - e + cut), Vector3(x_e - cut, top, -24.7 - e + cut)])
	roof([Vector3(CHURCH_W - 0.2, top, e - cut), Vector3(x_e - cut, top, e - cut), Vector3(x_e - cut, top, -24.7 - e + cut), Vector3(9.9, top, -24.7 - e + cut)])
	ridge(Vector3(x_e, WING, e), Vector3(x_e - cut, top, e - cut))
	ridge(Vector3(x_e, WING, -24.7 - e), Vector3(x_e - cut, top, -24.7 - e + cut))
	ridge(Vector3(CHURCH_W - 0.2, top, e - cut), Vector3(x_e - cut, top, e - cut))
	ridge(Vector3(x_e - cut, top, e - cut), Vector3(x_e - cut, top, -24.7 - e + cut))
	ridge(Vector3(10.2, top, -24.7 - e + cut), Vector3(x_e - cut, top, -24.7 - e + cut))
	var g0 := Vector3(14.8, top, -6.9)                            # the glass over the cloister
	var g1 := Vector3(21.0, top + 0.02, -14.2)
	box(g0.x - 0.15, top, g1.z - 0.15, g1.x - g0.x + 0.3, 0.3, g0.z - g1.z + 0.3, 0x8a8f94)
	var apex := Vector3((g0.x + g1.x) / 2.0, top + 1.5, (g0.z + g1.z) / 2.0)
	var corners := [Vector3(g0.x, top + 0.3, g0.z), Vector3(g1.x, top + 0.3, g0.z), Vector3(g1.x, top + 0.3, g1.z), Vector3(g0.x, top + 0.3, g1.z)]
	for k in range(4):
		var p0: Vector3 = corners[k]
		var p1: Vector3 = corners[(k + 1) % 4]
		var n := (p1 - p0).cross(apex - p0).normalized()
		tri(p0, p1, apex, 0xdfe8ec, n if n.y > 0.0 else -n)
		bar(p0, apex, 0.07, 0.07, 0x4a4f55)
	# the long wing's own roof: a ridge down its middle, hipped at the Cruces end, dying into the other at the north
	var ridge_x := 22.3
	var ry := WING + PITCH * (ridge_x - (W1.x - e))
	var v0 := Vector3(W1.x - e, WING, e)
	var s_e := Vector3(W2.x - e, WING, W2.y + e)
	var se_e := Vector3(x_e, WING, s2.y + e + 0.07)
	var r_s := Vector3(ridge_x, ry, 18.7)
	var r_0 := Vector3(ridge_x, ry, e)
	var r_n := Vector3(ridge_x, ry, e - (ridge_x - (W1.x - e)))
	roof([v0, s_e, r_s, r_0])
	roof([v0, r_0, r_n])
	roof([r_0, r_s, se_e, Vector3(x_e, WING, e)])
	roof([r_0, Vector3(x_e, WING, e), r_n])
	roof([s_e, se_e, r_s])
	ridge(r_s, r_n)
	ridge(s_e, r_s)
	ridge(se_e, r_s)
	roof([Vector3(26.4, 7.05, -24.7), Vector3(34.3, 5.75, -22.6), Vector3(31.3, 5.75, 24.95), Vector3(26.4, 7.05, 23.73)])       # (the low strip behind it)
	_loft()

## The look-out gallery over the inner corner (a drying loft once, open between its posts): brick piers at the
## corners, white plaster between dark posts with a window to each bay, deep eaves on carved brackets.
func _loft() -> void:
	var x0 := 20.2
	var x1 := 25.4
	var z0 := -1.25
	var z1 := 7.45
	var base := 7.85
	var pier := 1.3
	for f in [[Vector2(x0, z0), Vector2(x0, z1), 4], [Vector2(x0, z1), Vector2(x1, z1), 2], [Vector2(x1, z1), Vector2(x1, z0), 4], [Vector2(x1, z0), Vector2(x0, z0), 2]]:
		var ln := face(f[0], f[1])
		var bays: int = f[2]
		var bay := (ln - 2.0 * pier) / bays
		var holes: Array = []
		for k in range(bays):
			holes.append(Rect2(pier + (k + 0.5) * bay - 0.39, LOFT - 1.17, 0.78, 0.95))
		masonry(0.0, pier, base, LOFT, [], [])
		masonry(ln - pier, ln, base, LOFT, [], [])
		masonry(pier, ln - pier, base, LOFT - 0.02, holes, [], "white", "white")
		box(pier - 0.04, LOFT - 0.2, 0.0, ln - 2.0 * pier + 0.08, 0.18, 0.05, "wood")
		for k in range(bays + 1):
			var x := pier + k * bay
			box(x - 0.09, base, 0.0, 0.18, LOFT - 0.2 - base, 0.04, "wood")
			bar(Vector3(x, LOFT - 0.32, 0.03), Vector3(x, LOFT - 0.1, 0.5), 0.15, 0.17, "wood")
		for r: Rect2 in holes:
			window(r, 0x3a2a1e, 0x1c2630, 1)
		var tails := int(ln / 0.6)
		for k in range(tails + 1):
			var tx := ln * k / tails
			bar(Vector3(tx, LOFT - 0.03, 0.0), Vector3(tx, LOFT - 0.13, 0.58), 0.08, 0.1, "wood")
	home()
	box(x0 - 0.6, LOFT - 0.02, z0 - 0.6, x1 - x0 + 1.2, 0.03, z1 - z0 + 1.2, 0x3a2b21)
	var tip := _hip(x0, x1, z0, z1, LOFT, 1.9, 0.62, (z1 - z0) - (x1 - x0))
	_finial(tip, 0.8)

# ---------------- what grows in the square ----------------
func _cypress(x: float, z: float, tall: float, fat := 0.05) -> void:
	var leaf: Material = W._tmat(0x5c5c37, "leaf", 1.1)
	var r := tall * fat + 0.02
	add_child(Parts.part("cyl", 0x5d4630, Vector3(x, 0.2, z), Vector3(0.07, 0.4, 0.07)))
	for q in [[0.0, 0.0, 0.2 + tall * 0.5, 1.0, 0.5], [0.0, 0.0, 0.2 + tall * 0.3, 1.08, 0.3], [0.05, -0.04, 0.2 + tall * 0.42, 0.95, 0.36], [-0.04, 0.05, 0.2 + tall * 0.62, 0.8, 0.3]]:
		var body := Parts.part("ball", 0xffffff, Vector3(x + q[0], q[2], z + q[1]), Vector3(r * q[3], tall * q[4], r * q[3]))      # a column of green, not a Christmas tree
		body.material_override = leaf
		add_child(body)
	add_child(Parts.part("cyl", 0x6b5a48, Vector3(x, 0.012, z), Vector3(0.4, 0.02, 0.4)))
	solid(Vector3(x, 1.5, z), Vector3(maxf(0.5, r * 1.3), 3.0, maxf(0.5, r * 1.3)))
	yard.append(spot(x, z))

func _tree(x: float, z: float, tall: float, crown: float) -> void:
	add_child(Parts.part("cyl", 0x6f5a45, Vector3(x, tall / 2.0, z), Vector3(0.07, tall, 0.07)))       # a young tree: a thin trunk, a light airy crown
	var leaf: Material = W._tmat(0x7d9a52, "leaf", 1.3)
	for q in [[0.0, 0.3, 0.0, 0.7], [0.62, 0.5, 0.3, 0.5], [-0.58, 0.42, -0.36, 0.52], [0.18, 1.05, -0.2, 0.52], [-0.22, 1.6, 0.18, 0.4], [0.42, -0.1, -0.5, 0.4],
			[-0.3, -0.05, 0.55, 0.42], [0.1, 2.05, 0.0, 0.26], [-0.75, 1.0, 0.1, 0.34], [0.72, 1.25, -0.1, 0.32]]:
		var blob := Parts.part("ball", 0xffffff, Vector3(x + q[0] * crown, tall + crown * 0.4 + q[1] * crown, z + q[2] * crown), Vector3(crown * q[3], crown * q[3] * 1.1, crown * q[3]))
		blob.material_override = leaf
		add_child(blob)
	add_child(Parts.part("cyl", 0x6b5a48, Vector3(x, 0.012, z), Vector3(0.6, 0.02, 0.6)))
	solid(Vector3(x, 1.5, z), Vector3(0.3, 3.0, 0.3))
	yard.append(spot(x, z))

func _green() -> void:
	_cypress(16.8, 1.35, 5.6)                                   # (the one in the corner is thin; the two by the pretil have grown tall and full)
	_cypress(P_C1.x - 0.75, P_C1.y - 1.0, 7.6, 0.1)
	_cypress(15.15, 16.95, 8.2, 0.1)
	_tree(4.2, 16.4, 2.6, 1.3)
