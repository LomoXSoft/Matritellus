extends Node3D
## The builder's kit for places built by hand (the Plaza del Ayuntamiento, plaza.gd; whatever comes next): a place is
## a Node3D in its own frame -- +x along its main front, +z out of it, y = 0 its own floor -- and everything of one
## material in it is ONE mesh (a SurfaceTool for each material key, like casas.gd), built from the pieces below:
## flat pieces, boxes, bars, drums, balls, roofs, walls of brick with panels and holes (masonry), round arches,
## windows and grilles, columns; and the solids and floors that let people and cars stand on it or run into it.
##
## A place `extends "res://scripts/obra.gd"`, says what its material keys are in _material() (a whole number is a
## plain colour) and calls _commit() when it has built everything.
## (The Petril, petril.gd, was the first place built this way and keeps its own copy of these, as released.)

const Parts = preload("res://scripts/parts.gd")
const Tex = preload("res://scripts/texturas.gd")

const DEEP := 0.34                  # how far in the windows sit
const STONE := 0xd2bba4             # pale dressed stone
const IRON := 0x26262a

var W                               # the world (its textures, its static body, its lists of lamps and terraces)
var level := 0.0                    # this place's own floor, in the world
var pieces := 0                     # how many pieces it took (for the self-test)
var yard: Array = []                # where its walls, pillars, trees and benches stand, on the map (the self-test checks none is in a street)
var _tools := {}                    # material key -> SurfaceTool (everything of one material is one mesh)
var _mats := {}
var _xf := Transform3D.IDENTITY     # where what is being built stands in the place's frame (each wall has its own)
var _decks: Array = []
var body: StaticBody3D              # this place's own solids
static var t_solids := 0            # (--timing: microseconds the town's places spent handing their solids to the physics, and how many)
static var n_solids := 0

## Where this place's solids go: a body of its own. (The world's own body is one compound shape for the physics, and a
## compound has room for only so many pieces: a place with hundreds of them -- every stretch of a planter's wall, of a
## fence, of a kerb -- would fill it and leave the whole town with nothing solid.)
func _solids() -> StaticBody3D:
	if body == null:
		body = StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		W.add_child(body)
	return body

## What each material key is. A place overrides this for its own names and leaves the rest to this one.
func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material
	match (String(key) if key is String else ""):
		"brick":
			m = Tex.mat("medieval_red_brick")
		"granite":
			m = Tex.mat("granular_concrete", Color(0.92, 0.9, 0.86))
		"tiles":            # (its UVs are in units of 1.6 m, running down the slope)
			var tm: StandardMaterial3D = Tex.mat(Tex.pick("tiles") if Tex.pick("tiles") != "" else "clay_roof_tiles_02", Color.WHITE, true, 1.6)
			tm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = tm
		"wood":
			var wm: StandardMaterial3D = Tex.mat("old_planks_02", Color(0.36, 0.26, 0.2))
			wm.rim_enabled = true
			wm.rim = 0.3
			wm.rim_tint = 0.6
			m = wm
		"white":            # lime-washed plaster (it reads white in the shade too)
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.985, 0.95)), 0.18)
		_:
			m = Parts.mat(int(key))
	_mats[key] = m
	return m

## a spot in the Petril's own frame, as a place in the town
func spot(x: float, z: float) -> Vector2:
	var p := transform * Vector3(x, 0, z)
	return Vector2(p.x, p.z)

## how high the town's ground is under a spot of the frame, measured from the floor of the square (negative: below it)
func ground(x: float, z: float) -> float:
	return MapData.height(spot(x, z)) - level

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
		if key is String and (key as String).begins_with("tiles"):
			st.generate_tangents()
		mi.mesh = st.commit()
		mi.material_override = _material(key)
		add_child(mi)
	_tools.clear()

## (26 Nov 2026, the loading: no lists made on the way. The normal given once holds for the three corners.)
func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3, uvs = null) -> void:
	st.set_normal(n)
	if (b - a).cross(c - a).dot(n) > 0.0:         # Godot wants clockwise front faces
		if uvs == null:
			st.add_vertex(a); st.add_vertex(c); st.add_vertex(b)
		else:
			st.set_uv(uvs[0]); st.add_vertex(a)
			st.set_uv(uvs[2]); st.add_vertex(c)
			st.set_uv(uvs[1]); st.add_vertex(b)
	elif uvs == null:
		st.add_vertex(a); st.add_vertex(b); st.add_vertex(c)
	else:
		st.set_uv(uvs[0]); st.add_vertex(a)
		st.set_uv(uvs[1]); st.add_vertex(b)
		st.set_uv(uvs[2]); st.add_vertex(c)

## a flat three-sided piece facing `n` (in the frame being built)
func tri(a: Vector3, b: Vector3, c: Vector3, key, n: Vector3, uvs = null) -> void:
	_tri(_tool(key), _xf * a, _xf * b, _xf * c, (_xf.basis * n).normalized(), uvs)

## a flat four-sided piece facing `n`
func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, key, n: Vector3, uvs = null) -> void:
	var st := _tool(key)
	n = (_xf.basis * n).normalized()
	a = _xf * a; b = _xf * b; c = _xf * c; d = _xf * d
	if uvs == null:
		_tri(st, a, b, c, n)
		_tri(st, a, c, d, n)
	else:
		_tri(st, a, b, c, n, [uvs[0], uvs[1], uvs[2]])
		_tri(st, a, c, d, n, [uvs[0], uvs[2], uvs[3]])

## a box: its left, bottom, back corner, then how wide, high and deep (out of the wall) it is
## (26 Nov 2026, the loading -- the user: "El juego tarda muchísimo en cargar". Its eight corners are worked out once
## and its 36 laid straight down, face by face and corner by corner as the six quads below lay them: which way round
## each triangle goes hangs only on whether the frame it stands in is mirrored -- the sign of its determinant --,
## never on the box's size. `--cajas-viejas`: the six quads, to check that the places come out the same.)
static var old_boxes := OS.get_cmdline_user_args().has("--cajas-viejas")
func box(x: float, y: float, z: float, w: float, h: float, d: float, key) -> void:
	if w <= 0.0 or h <= 0.0 or d <= 0.0:
		return
	pieces += 1
	var bs := _xf.basis
	var det := bs.determinant()
	var lo := Vector3(x, y, z)
	var hi := Vector3(x + w, y + h, z + d)
	# (a box so thin that its two sides fall on the same spot -- the MasAhorro has one -- goes the old way: with faces
	# of no size the six quads cannot tell which way round they go and leave them as given, and the meshes must come
	# out the same to the last corner, since that is how this change was checked: `--mundo-huella`)
	if det != 0.0 and not old_boxes and lo.x != hi.x and lo.y != hi.y and lo.z != hi.z:
		var st := _tool(key)
		var x1 := x + w
		var y1 := y + h
		var z1 := z + d
		var p0 := _xf * Vector3(x, y, z); var p1 := _xf * Vector3(x1, y, z)
		var p2 := _xf * Vector3(x, y1, z); var p3 := _xf * Vector3(x1, y1, z)
		var p4 := _xf * Vector3(x, y, z1); var p5 := _xf * Vector3(x1, y, z1)
		var p6 := _xf * Vector3(x, y1, z1); var p7 := _xf * Vector3(x1, y1, z1)
		if det > 0.0:
			st.set_normal((bs * Vector3(0, 0, 1)).normalized())
			st.add_vertex(p4); st.add_vertex(p7); st.add_vertex(p5); st.add_vertex(p4); st.add_vertex(p6); st.add_vertex(p7)
			st.set_normal((bs * Vector3(0, 0, -1)).normalized())
			st.add_vertex(p0); st.add_vertex(p1); st.add_vertex(p3); st.add_vertex(p0); st.add_vertex(p3); st.add_vertex(p2)
			st.set_normal((bs * Vector3(-1, 0, 0)).normalized())
			st.add_vertex(p0); st.add_vertex(p6); st.add_vertex(p4); st.add_vertex(p0); st.add_vertex(p2); st.add_vertex(p6)
			st.set_normal((bs * Vector3(1, 0, 0)).normalized())
			st.add_vertex(p1); st.add_vertex(p5); st.add_vertex(p7); st.add_vertex(p1); st.add_vertex(p7); st.add_vertex(p3)
			st.set_normal((bs * Vector3(0, 1, 0)).normalized())
			st.add_vertex(p2); st.add_vertex(p3); st.add_vertex(p7); st.add_vertex(p2); st.add_vertex(p7); st.add_vertex(p6)
			st.set_normal((bs * Vector3(0, -1, 0)).normalized())
			st.add_vertex(p0); st.add_vertex(p5); st.add_vertex(p1); st.add_vertex(p0); st.add_vertex(p4); st.add_vertex(p5)
		else:
			st.set_normal((bs * Vector3(0, 0, 1)).normalized())
			st.add_vertex(p4); st.add_vertex(p5); st.add_vertex(p7); st.add_vertex(p4); st.add_vertex(p7); st.add_vertex(p6)
			st.set_normal((bs * Vector3(0, 0, -1)).normalized())
			st.add_vertex(p0); st.add_vertex(p3); st.add_vertex(p1); st.add_vertex(p0); st.add_vertex(p2); st.add_vertex(p3)
			st.set_normal((bs * Vector3(-1, 0, 0)).normalized())
			st.add_vertex(p0); st.add_vertex(p4); st.add_vertex(p6); st.add_vertex(p0); st.add_vertex(p6); st.add_vertex(p2)
			st.set_normal((bs * Vector3(1, 0, 0)).normalized())
			st.add_vertex(p1); st.add_vertex(p7); st.add_vertex(p5); st.add_vertex(p1); st.add_vertex(p3); st.add_vertex(p7)
			st.set_normal((bs * Vector3(0, 1, 0)).normalized())
			st.add_vertex(p2); st.add_vertex(p7); st.add_vertex(p3); st.add_vertex(p2); st.add_vertex(p6); st.add_vertex(p7)
			st.set_normal((bs * Vector3(0, -1, 0)).normalized())
			st.add_vertex(p0); st.add_vertex(p1); st.add_vertex(p5); st.add_vertex(p0); st.add_vertex(p5); st.add_vertex(p4)
		return
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
	var t0 := Time.get_ticks_usec()
	_solids().add_child(cs)
	t_solids += Time.get_ticks_usec() - t0
	n_solids += 1

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
	var t0 := Time.get_ticks_usec()
	_solids().add_child(cs)
	t_solids += Time.get_ticks_usec() - t0
	n_solids += 1

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

## a wall of plain brick (what shows over a lower roof, or looks on to a neighbour's yard)
func _plain(a: Vector2, b: Vector2, y0: float, y1: float, key = "brick") -> void:
	var ln := face(a, b)
	pieces += 1
	quad(Vector3(0, y0, 0), Vector3(ln, y0, 0), Vector3(ln, y1, 0), Vector3(0, y1, 0), key, Vector3(0, 0, 1))
	home()

## the line of rounded tiles along a ridge or a hip
var ridge_hex := 0xa8623f              # the rounded tiles of ridges and hips
func ridge(a: Vector3, b: Vector3) -> void:
	bar(a + Vector3(0, 0.03, 0), b + Vector3(0, 0.03, 0), 0.3, 0.12, ridge_hex)

## a four-sided roof coming to a point (or to a short ridge along z): its eaves `out` beyond the walls x0..x1, z0..z1
func _hip(x0: float, x1: float, z0: float, z1: float, y: float, rise: float, out := 0.45, long := 0.0, key = "tiles") -> Vector3:
	var a := Vector3(x0 - out, y, z1 + out)
	var b := Vector3(x1 + out, y, z1 + out)
	var c := Vector3(x1 + out, y, z0 - out)
	var d := Vector3(x0 - out, y, z0 - out)
	var mx := (x0 + x1) / 2.0
	var mz := (z0 + z1) / 2.0
	var t0 := Vector3(mx, y + rise, mz + long / 2.0)
	var t1 := Vector3(mx, y + rise, mz - long / 2.0)
	roof([a, b, t0], key)
	roof([c, d, t1], key)
	if long > 0.0:
		roof([b, c, t1, t0], key)
		roof([d, a, t0, t1], key)
	else:
		roof([b, c, t1], key)
		roof([d, a, t0], key)
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
