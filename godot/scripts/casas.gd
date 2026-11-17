extends Node3D
## Houses built by hand, one by one, each after the real one: real walls with real openings in them, balconies, eaves,
## a porch you can step into. (The ordinary houses of the town are a painted front on a flat wall.)
##
## The method, for the next one:
##   1. python tools/house_data.py CL ALEMANIA 7   -> tools/casas/<reference>/: what Catastro knows (year, uses and
##      surfaces by floor, every part's footprint with its storeys -- a part with 0 storeys is a floor that flies over
##      the pavement), Catastro's own photo of the front, the aerial photo with the footprint drawn on it, the ground.
##   2. In tools/bake_godot.py, HOUSES: its reference, the two ends of its front, how high its walls are, its porch.
##      The bake then keeps the block solid but draws no walls or roof for it, and hands over the frame of its front.
##   3. Here: a function for it, in metres measured off the photos. x runs along the front from its left end as you
##      face it, y up from its floor, z out into the street (the ground-floor wall is z = 0).
##
## Everything is boxes (and a few flat pieces for roofs and gables), gathered into one mesh for each material.
##
## House rule (the user, 12 November 2026): the references and street numbers here are for building them and stay in
## the code. In the game no house wears its number and no text names its street and number: several are real houses,
## some empty for decades, and they are not to be pointed at.

const Parts = preload("res://scripts/parts.gd")
const Tex = preload("res://scripts/texturas.gd")              # photographic textures, for the kinds of surface that have one chosen
const Tela = preload("res://scripts/tela.gd")                 # cloth that moves: the curtains at the doors
const Short = preload("res://scripts/casas_calles.gd")       # whole streets of houses, each described in a line or two

var W                       # the world (for its textures)
var def: Dictionary
var id := ""
var o := Vector2.ZERO       # the left end of the front, as you face the house
var u := Vector2.RIGHT      # along the front, to the right
var out := Vector2.DOWN     # out into the street
var length := 0.0
var base := 0.0
var boxes := 0              # how many pieces it took (for the self-test)
var pavement := 0           # how many lengths of pavement were laid in front of it
var _tools := {}            # material key -> Acc (or a SurfaceTool, for the cloth: tela.gd)
## What a house's pieces of one material are gathered in before they become a mesh: plain lists of corners, normals and
## texture places, the mesh made of them in one go. (The user, 17 Nov 2026: the loading took 45 s, 19 of them the
## houses drawing their pieces a corner at a time into a SurfaceTool. The same corners, in the same order: the same mesh.)
class Acc:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var uv := PackedVector2Array()
	var first := true           # (as a SurfaceTool: whether there are texture places is settled by the first corner;
	var has_uv := false         # a corner given none after that takes the last one given)
	var last_uv := Vector2.ZERO
static var t_geom := 0      # (--timing: microseconds the town's houses spent drawing their pieces, making their meshes, making their materials)
static var t_commit := 0
static var t_mats := 0
static var slow := false    # (--casas-lento: the old way, a SurfaceTool a corner at a time, to check the new one makes the same houses)
var _mats := {}             # material key -> Material
var _xf := Transform3D.IDENTITY     # where what is being built stands in the house's own frame (a side front has its own)
var pieces: Array = []      # the plot's outline(s), in the house's frame: {ring: PackedVector2Array (x, z), edges: [[a, b, hidden, street], ...]}
var top := 0.0              # the top of the walls

## Brick and the like: [the colour the town's brick texture is multiplied by, the size of its repeat in metres]
const MASONRY := {
	"brick": [Color(1.22, 1.2, 1.12), 1.15],            # tan facing brick
	"brick_red": [Color(0.96, 0.74, 0.68), 1.15],        # the pressed red of a block of flats
	"brick_orange": [Color(1.18, 0.95, 0.78), 1.15],
	"brick_brown": [Color(0.84, 0.76, 0.76), 1.15],     # the mottled brown of the 2000s
	"brick_dark": [Color(0.6, 0.48, 0.44), 1.15],       # nearly chocolate
	"tile_brown": [Color(0.62, 0.44, 0.38), 0.55],      # little glazed tiles
	"tile_tan": [Color(1.05, 0.9, 0.74), 0.6],
	"brick_pale": [Color(1.42, 1.4, 1.3), 1.15],        # the pale yellow facing brick of the communications tower
	"brick_salmon": [Color(1.22, 1.06, 0.96), 1.15],    # ...and the pinker one of its foot
	"brick_rose": [Color(1.2, 1.3, 1.5), 1.15],        # the pale pink facing brick of houses built since 2005
	"brick_buff": [Color(1.14, 1.26, 1.34), 1.15],      # buff, nearly grey: the facing brick of the 2000s on the Calle de Colón
	"brick_pardo": [Color(0.9, 0.98, 1.0), 1.15],       # the dull brown-tan of the 1990s and 2000s (Calle del Clavel 54, 55)
	"brick_tostado": [Color(0.88, 0.84, 0.86), 1.15],   # salmon gone brown: the terraces of 1987 at the end of the Calle del Clavel
}

func build(world, d: Dictionary) -> Node3D:
	W = world
	def = d
	id = String(d["id"])
	o = Vector2(d["o"][0], d["o"][1])
	u = Vector2(d["u"][0], d["u"][1])
	out = Vector2(-u.y, u.x)
	length = float(d["len"])
	base = float(d["base"])
	top = float(d.get("h", 6.2))
	position = Vector3(o.x, base, o.y)
	rotation.y = atan2(-u.y, u.x)
	for pc in d.get("pieces", []):
		var ring := PackedVector2Array()
		var flat: Array = pc["ring"]
		for i in range(0, flat.size(), 2):
			ring.append(_local(Vector2(flat[i], flat[i + 1])))
		var edges: Array = []
		for e in pc.get("edges", []):
			edges.append([_local(Vector2(e[0], e[1])), _local(Vector2(e[2], e[3])), int(e[4]) == 1, int(e[5]) == 1])
		pieces.append({"ring": ring, "edges": edges})
	if Short.HOUSES.has(id) and (Short.HOUSES[id] as Array).size() == 1 and String(Short.HOUSES[id][0]) == "obra":
		boxes = 99                                    # built by hand elsewhere, walls and roof and all (farmacia.gd): nothing of it is drawn here
		return self
	var t0 := Time.get_ticks_usec()
	if has_method("_" + id):
		call("_" + id)
	elif Short.ADOSADOS.has(id):
		_adosado(String(Short.ADOSADOS[id]))
	elif Short.ROSAS.has(id):
		_rosa(Short.ROSAS[id] as Array)
	elif SPECS.has(id):
		_from_spec(SPECS[id])
	elif Short.HOUSES.has(id):
		_from_spec(_unpack(Short.HOUSES[id]))
	var t1 := Time.get_ticks_usec()
	t_geom += t1 - t0
	for key in _tools:
		var mi := MeshInstance3D.new()
		var tool = _tools[key]
		if tool is Acc:
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = tool.v
			arrays[Mesh.ARRAY_NORMAL] = tool.n
			if tool.has_uv:
				arrays[Mesh.ARRAY_TEX_UV] = tool.uv
			if key is String and key == "tiles" and Tex.pick("tiles") != "":
				var st := SurfaceTool.new()                   # (a normal map on its own UVs needs tangents)
				st.create_from_arrays(arrays)
				st.generate_tangents()
				mi.mesh = st.commit()
			else:
				var am := ArrayMesh.new()
				if not tool.v.is_empty():
					am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
				mi.mesh = am
		else:
			mi.mesh = (tool as SurfaceTool).commit()
		mi.material_override = _mats[key]
		if key is String and key == "tela":
			mi.extra_cull_margin = 1.5              # (it moves out of where its mesh says it is)
		add_child(mi)
	t_commit += Time.get_ticks_usec() - t1
	_tools.clear()                                  # (the meshes are made: what they were made from goes. Kept, the town's houses held
	return self                                     # 3.7 GB between them, and a phone closed the game while loading -- 16 Nov 2026)

## a place on the map, in the house's frame: x along the front, y out into the street
func _local(p: Vector2) -> Vector2:
	return Vector2((p - o).dot(u), (p - o).dot(out))

## a place given along the front and out from it, on the map
func spot(x: float, z: float) -> Vector2:
	return o + u * x + out * z

# ---------------- materials ----------------
func _tool(key):
	if not _tools.has(key):
		if slow:
			var old_st := SurfaceTool.new()
			old_st.begin(Mesh.PRIMITIVE_TRIANGLES)
			_tools[key] = old_st
		else:
			_tools[key] = Acc.new()
		var tm0 := Time.get_ticks_usec()
		var m: Material
		var name := String(key) if key is String else ""
		if name == "render" or (name.begins_with("r") and name.substr(1).is_valid_int()):       # painted render (white, or "r" + its colour)
			var photo := Tex.pick("render")
			var sm: StandardMaterial3D = W._tmat(0xffffff, "plaster", 4.0) if photo == "" else Tex.mat(photo)
			var c: Color = Parts.col(int(name.substr(1))) if name != "render" else Color(1.0, 0.995, 0.975)
			sm.albedo_color = Color(c.r * 1.1, c.g * 1.1, c.b * 1.1)
			if photo != "":
				sm.emission_texture = sm.albedo_texture       # (...and its stains and cracks with it)
				sm.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			sm.emission_enabled = true          # (a painted wall keeps its colour in the shade, where the sky would turn white to blue-grey)
			sm.emission = Color(c.r, c.g * 0.97, c.b * 0.9)
			sm.emission_energy_multiplier = 0.2
			m = sm
		elif MASONRY.has(name):
			if Tex.pick(name) != "":            # (a set made to be coloured takes this brick's own colour)
				m = Tex.mat(Tex.pick(name), MASONRY[name][0] if Tex.info(Tex.pick(name).get_slice("@", 0))["tint"] else Color.WHITE)
			else:
				var bm: StandardMaterial3D = W._tmat(0xffffff, "brick", MASONRY[name][1])
				bm.albedo_color = MASONRY[name][0]
				m = bm
		elif name == "stone":           # dressed stone, in blocks
			m = W._tmat(0x9a8c78, "pavement", 0.9) if Tex.pick(name) == "" else Tex.mat(Tex.pick(name))
		elif name.begins_with("w") and name.substr(1).is_valid_int():       # wood, painted or varnished this colour
			if Tex.pick("wood") == "":
				m = Parts.mat(int(name.substr(1)))
			else:
				var wm: StandardMaterial3D = Tex.mat(Tex.pick("wood"), Parts.col(int(name.substr(1))) * 1.15)
				wm.rim_enabled = true           # (as the plain colours of the town have it)
				wm.rim = 0.35
				wm.rim_tint = 0.6
				m = wm
		elif name == "slab" and Tex.pick(name) != "":
			var pl: StandardMaterial3D = Tex.mat(Tex.pick(name), Color(0.957, 0.918, 0.831) * 1.08)
			pl.emission_enabled = true
			pl.emission = Color(0.95, 0.9, 0.78)
			pl.emission_texture = pl.albedo_texture
			pl.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			pl.emission_energy_multiplier = 0.2
			m = pl
		elif name == "slab":            # sawn stone cladding
			var lm: StandardMaterial3D = W._tmat(0xf4ead4, "pavement", 1.7)
			lm.emission_enabled = true
			lm.emission = Color(0.95, 0.9, 0.78)
			lm.emission_energy_multiplier = 0.2
			m = lm
		elif name == "tiles" and Tex.pick(name) != "":
			var pm: StandardMaterial3D = Tex.mat(Tex.pick(name), Color.WHITE, true, 1.6)       # (its UVs are in units of 1.6 m)
			pm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = pm
		elif name == "tiles":           # the roof (this one has its own UVs: the tiles run down the slope)
			var tm := StandardMaterial3D.new()
			tm.albedo_color = Parts.col(0xe6a682)            # (what the town's other roofs come out as)
			tm.albedo_texture = W._tex("tiles")
			tm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			tm.roughness = 1.0
			tm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = tm
		else:
			m = Parts.mat(int(key))
		_mats[key] = m
		t_mats += Time.get_ticks_usec() - tm0
	return _tools[key]

func _tri(st, a: Vector3, b: Vector3, c: Vector3, n: Vector3, uvs = null) -> void:
	if st is Acc:                                 # (the usual way: straight into the lists, no list made per triangle)
		var acc: Acc = st
		var flip := (b - a).cross(c - a).dot(n) > 0.0          # Godot wants clockwise front faces
		if acc.first:
			acc.first = false
			acc.has_uv = uvs != null
		acc.v.append(a)
		if flip:
			acc.v.append(c)
			acc.v.append(b)
		else:
			acc.v.append(b)
			acc.v.append(c)
		acc.n.append(n)
		acc.n.append(n)
		acc.n.append(n)
		if acc.has_uv:
			if uvs != null:
				acc.uv.append(uvs[0])
				if flip:
					acc.uv.append(uvs[2])
					acc.uv.append(uvs[1])
					acc.last_uv = uvs[1]
				else:
					acc.uv.append(uvs[1])
					acc.uv.append(uvs[2])
					acc.last_uv = uvs[2]
			else:
				acc.uv.append(acc.last_uv)
				acc.uv.append(acc.last_uv)
				acc.uv.append(acc.last_uv)
		return
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

## a flat four-sided piece, facing `n`
func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, key, n: Vector3, uvs = null) -> void:
	var st = _tool(key)
	n = (_xf.basis * n).normalized()
	a = _xf * a; b = _xf * b; c = _xf * c; d = _xf * d
	if uvs == null and st is Acc:
		_quad_acc(st, a, b, c, d, n)
		return
	_tri(st, a, b, c, n, [uvs[0], uvs[1], uvs[2]] if uvs != null else null)
	_tri(st, a, c, d, n, [uvs[0], uvs[2], uvs[3]] if uvs != null else null)

## two triangles, a b c and a c d, already in the town's frame, straight into the lists: the same as two _tri()
## without texture places, without the calls and the lists in between (the loading, 17 Nov 2026)
func _quad_acc(acc: Acc, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	if acc.first:
		acc.first = false
		acc.has_uv = false
	acc.v.append(a)
	if (b - a).cross(c - a).dot(n) > 0.0:          # Godot wants clockwise front faces
		acc.v.append(c)
		acc.v.append(b)
	else:
		acc.v.append(b)
		acc.v.append(c)
	acc.v.append(a)
	if (c - a).cross(d - a).dot(n) > 0.0:
		acc.v.append(d)
		acc.v.append(c)
	else:
		acc.v.append(c)
		acc.v.append(d)
	for k in range(6):
		acc.n.append(n)
	if acc.has_uv:
		for k in range(6):
			acc.uv.append(acc.last_uv)

## a box: its left, bottom, back corner, then how wide, high and deep (towards the street) it is
func box(x: float, y: float, z: float, w: float, h: float, d: float, key) -> void:
	if w <= 0.0 or h <= 0.0 or d <= 0.0:
		return
	boxes += 1
	var a := Vector3(x, y, z)
	var b := Vector3(x + w, y + h, z + d)
	var st = _tool(key)
	if st is Acc:                                 # (its eight corners worked out once, not four times a face)
		var p000 := _xf * Vector3(a.x, a.y, a.z); var p100 := _xf * Vector3(b.x, a.y, a.z)
		var p010 := _xf * Vector3(a.x, b.y, a.z); var p110 := _xf * Vector3(b.x, b.y, a.z)
		var p001 := _xf * Vector3(a.x, a.y, b.z); var p101 := _xf * Vector3(b.x, a.y, b.z)
		var p011 := _xf * Vector3(a.x, b.y, b.z); var p111 := _xf * Vector3(b.x, b.y, b.z)
		var bs: Basis = _xf.basis
		_quad_acc(st, p001, p101, p111, p011, (bs * Vector3(0, 0, 1)).normalized())
		_quad_acc(st, p000, p100, p110, p010, (bs * Vector3(0, 0, -1)).normalized())
		_quad_acc(st, p000, p001, p011, p010, (bs * Vector3(-1, 0, 0)).normalized())
		_quad_acc(st, p100, p101, p111, p110, (bs * Vector3(1, 0, 0)).normalized())
		_quad_acc(st, p010, p110, p111, p011, (bs * Vector3(0, 1, 0)).normalized())
		_quad_acc(st, p000, p100, p101, p001, (bs * Vector3(0, -1, 0)).normalized())
		return
	quad(Vector3(a.x, a.y, b.z), Vector3(b.x, a.y, b.z), Vector3(b.x, b.y, b.z), Vector3(a.x, b.y, b.z), key, Vector3(0, 0, 1))
	quad(Vector3(a.x, a.y, a.z), Vector3(b.x, a.y, a.z), Vector3(b.x, b.y, a.z), Vector3(a.x, b.y, a.z), key, Vector3(0, 0, -1))
	quad(Vector3(a.x, a.y, a.z), Vector3(a.x, a.y, b.z), Vector3(a.x, b.y, b.z), Vector3(a.x, b.y, a.z), key, Vector3(-1, 0, 0))
	quad(Vector3(b.x, a.y, a.z), Vector3(b.x, a.y, b.z), Vector3(b.x, b.y, b.z), Vector3(b.x, b.y, a.z), key, Vector3(1, 0, 0))
	quad(Vector3(a.x, b.y, a.z), Vector3(b.x, b.y, a.z), Vector3(b.x, b.y, b.z), Vector3(a.x, b.y, b.z), key, Vector3(0, 1, 0))
	quad(Vector3(a.x, a.y, a.z), Vector3(b.x, a.y, a.z), Vector3(b.x, a.y, b.z), Vector3(a.x, a.y, b.z), key, Vector3(0, -1, 0))

# ---------------- the pieces of a house ----------------
## A wall from x0 to x1 and y0 to y1, its face at `face`, `thick` deep, with holes in it (Rect2: x, y, width, height):
## the wall is cut into a grid along the edges of the holes, so every opening has its real depth
func wall(x0: float, x1: float, y0: float, y1: float, face: float, thick: float, holes: Array, key) -> void:
	var xs := [x0, x1]
	var ys := [y0, y1]
	for hole in holes:
		var r: Rect2 = hole
		for v in [r.position.x, r.end.x]:
			if v > x0 + 0.001 and v < x1 - 0.001:
				xs.append(v)
		for v in [r.position.y, r.end.y]:
			if v > y0 + 0.001 and v < y1 - 0.001:
				ys.append(v)
	xs.sort()
	ys.sort()
	for i in range(xs.size() - 1):
		for j in range(ys.size() - 1):
			var c := Vector2((xs[i] + xs[i + 1]) / 2.0, (ys[j] + ys[j + 1]) / 2.0)
			var open := false
			for hole in holes:
				if (hole as Rect2).has_point(c):
					open = true
					break
			if not open:
				box(xs[i], ys[j], face - thick, xs[i + 1] - xs[i], ys[j + 1] - ys[j], thick, key)

## what fills a window's hole: the glass, set back; its frame; the roller blind, `drop` of the way down
func window(x: float, y: float, w: float, h: float, face: float, drop := 0.7, frame := 0xf1eee6, blind := 0xf1eee6) -> void:
	var z := face - 0.24
	box(x, y, z - 0.03, w, h, 0.03, 0x2f4a6b)
	box(x, y, z, 0.06, h, 0.05, frame)
	box(x + w - 0.06, y, z, 0.06, h, 0.05, frame)
	box(x, y, z, w, 0.06, 0.05, frame)
	box(x, y + h - 0.14, z, w, 0.14, 0.07, frame)                # the blind's box
	box(x + w / 2.0 - 0.03, y, z, 0.06, h, 0.05, frame)
	if drop > 0.0:
		var bh := (h - 0.14) * drop
		box(x + 0.06, y + h - 0.14 - bh, z + 0.02, w - 0.12, bh, 0.02, blind)
		var slat := Parts.col(blind).darkened(0.14).to_rgba32() >> 8
		for i in range(1, int(bh / 0.09) + 1):                    # its slats
			box(x + 0.06, y + h - 0.14 - i * 0.09, z + 0.04, w - 0.12, 0.012, 0.004, slat)
	box(x - 0.04, y - 0.05, face - 0.24, w + 0.08, 0.05, 0.3, 0xd9d2c2)          # the sill

## an iron grille over a window: uprights, three cross bars, a band of curls near the foot
func grille(x: float, y: float, w: float, h: float, face: float, stand := 0.07) -> void:
	var iron := 0x24221f
	var n := maxi(4, int(round(w / 0.12)))
	for i in range(n + 1):
		box(x + (w - 0.02) * i / n, y, face + stand, 0.02, h, 0.02, iron)
	for by in [0.0, 0.2, h * 0.55, h - 0.025]:
		box(x, y + by, face + stand - 0.005, w, 0.025, 0.03, iron)
	for i in range(n):                                            # the curls: a little square between each pair of uprights
		box(x + (w - 0.02) * (i + 0.5) / n - 0.025, y + 0.07, face + stand, 0.07, 0.07, 0.015, iron)
	for sx in [x, x + w - 0.02]:                                  # how it is held to the wall
		for sy in [y + 0.03, y + h - 0.05]:
			box(sx, sy, face, 0.02, 0.02, stand, iron)

## a quarter round of wall (a bay's corner): centre (cx, cz) in the plan, radius r, from angle a0 to a1 (degrees: 0 along
## the front, 90 out into the street), from yb up to yt
func _round(cx: float, cz: float, r: float, a0: float, a1: float, yb: float, yt: float, key) -> void:
	var n := 6
	for k in range(n):
		var t0 := deg_to_rad(a0 + (a1 - a0) * k / float(n))
		var t1 := deg_to_rad(a0 + (a1 - a0) * (k + 1) / float(n))
		var tm := (t0 + t1) / 2.0
		quad(Vector3(cx + r * cos(t0), yb, cz + r * sin(t0)), Vector3(cx + r * cos(t1), yb, cz + r * sin(t1)),
			Vector3(cx + r * cos(t1), yt, cz + r * sin(t1)), Vector3(cx + r * cos(t0), yt, cz + r * sin(t0)), key, Vector3(cos(tm), 0, sin(tm)))
		boxes += 1

## the crest of iron on top of a window's grille: a low arch of flat bar, a curl at each side, a knob at the top
func crest(xc: float, y: float, w: float, z: float) -> void:
	var iron := 0x24221f
	var hw := w * 0.32
	var ht := 0.2
	var n := 8
	for k in range(n):                       # the arch, a short bar at a time
		var t := PI * (k + 0.5) / float(n)
		box(xc - hw * cos(t) - 0.03, y + ht * sin(t) - 0.012, z, 0.06, 0.025, 0.015, iron)
	box(xc - hw, y, z, hw * 2.0, 0.025, 0.015, iron)
	for sx in [-1.0, 1.0]:                   # the curls either side: a little ring of four bars
		var cx: float = xc + sx * (hw + 0.09)
		box(cx - 0.06, y, z, 0.12, 0.02, 0.015, iron)
		box(cx - 0.06, y + 0.1, z, 0.12, 0.02, 0.015, iron)
		box(cx + sx * 0.05 - 0.01, y, z, 0.02, 0.12, 0.015, iron)
		box(cx - sx * 0.05 - 0.01, y + 0.05, z, 0.02, 0.07, 0.015, iron)
	box(xc - 0.035, y + ht, z, 0.07, 0.07, 0.02, iron)

## a little pediment over a window: a triangle of moulding standing out of the wall, on a ledge
func pediment(xc: float, y: float, w: float, face: float, key) -> void:
	var ph := 0.26
	var x0 := xc - w / 2.0
	var x1 := xc + w / 2.0
	var zf := face + 0.07
	box(x0 - 0.03, y, face, w + 0.06, 0.06, 0.09, key)
	var yb := y + 0.06
	tri(Vector3(x0, yb, zf), Vector3(x1, yb, zf), Vector3(xc, yb + ph, zf), key, Vector3(0, 0, 1))
	quad(Vector3(x0, yb, face), Vector3(x0, yb, zf), Vector3(xc, yb + ph, zf), Vector3(xc, yb + ph, face), key, Vector3(-ph, w / 2.0, 0).normalized())
	quad(Vector3(xc, yb + ph, face), Vector3(xc, yb + ph, zf), Vector3(x1, yb, zf), Vector3(x1, yb, face), key, Vector3(ph, w / 2.0, 0).normalized())
	boxes += 1

## the iron of an arched opening: uprights up to the curve, a bar at the springing, and with `fan` the rays of a fan
## in the arch (the gate of a doorway)
func arch_grille(x: float, sy: float, w: float, spring: float, z: float, fan := false) -> void:
	var iron := 0x24221f
	var rr := w / 2.0
	var cx := x + rr
	var n := maxi(4, int(round(w / 0.12)))
	for i in range(1, n):
		var bx := x + w * i / float(n)
		var dx := bx - cx
		var top := spring + (0.0 if fan else sqrt(maxf(0.0, rr * rr - dx * dx)) - 0.02)
		box(bx - 0.01, sy, z, 0.02, top - sy, 0.02, iron)
	for by in [sy + 0.12, sy + (spring - sy) * 0.5, spring]:
		box(x, by, z - 0.005, w, 0.025, 0.03, iron)
	var m := 14
	for k in range(m):                       # the curve itself, in flat bar
		var t := PI * (k + 0.5) / float(m)
		box(cx + (rr - 0.02) * cos(t) - 0.04, spring + (rr - 0.02) * sin(t) - 0.012, z, 0.08, 0.025, 0.02, iron)
	if fan:
		for k in range(1, 6):                # the rays, from a half ring at the springing
			var t := PI * k / 6.0
			for j in range(4):
				var rj := 0.12 + (rr - 0.16) * (j + 0.5) / 4.0
				box(cx + rj * cos(t) - 0.015, spring + rj * sin(t) - 0.04, z, 0.03, 0.08, 0.02, iron)
		for k in range(6):
			var t := PI * (k + 0.5) / 6.0
			box(cx + 0.1 * cos(t) - 0.02, spring + 0.1 * sin(t) - 0.01, z, 0.04, 0.025, 0.02, iron)

## the wooden window of an arched opening: jambs and a sill, a transom where the arch springs, a mullion between its
## two leaves, the frame round the half circle and three bars in the fanlight -- the glass is the opening's dark back
func arch_frame(x: float, sy: float, w: float, spring: float, z: float, fc: int) -> void:
	var rr := w / 2.0
	var cx := x + rr
	var t := 0.07
	box(x, sy, z, t, spring - sy, 0.05, fc)
	box(x + w - t, sy, z, t, spring - sy, 0.05, fc)
	box(x, sy, z, w, 0.09, 0.06, fc)
	box(x, spring - 0.04, z, w, 0.07, 0.05, fc)
	box(cx - 0.03, sy, z, 0.06, spring - sy, 0.05, fc)
	box(x + 0.02, sy + (spring - sy) * 0.5, z + 0.01, w - 0.04, 0.035, 0.03, fc)      # (each leaf split in panes)
	for lx in [x + w * 0.25, x + w * 0.75]:
		box(lx - 0.015, sy, z + 0.01, 0.03, spring - sy, 0.03, fc)
	var m := 12
	for k in range(m):                                   # the frame round the half circle
		var a := PI * (k + 0.5) / float(m)
		box(cx + (rr - 0.04) * cos(a) - 0.045, spring + (rr - 0.04) * sin(a) - 0.035, z, 0.09, 0.07, 0.05, fc)
	for k in range(1, 4):                                # the bars of the fanlight
		var a := PI * k / 4.0
		for j in range(3):
			var rj := (rr - 0.06) * (j + 0.5) / 3.0
			box(cx + rj * cos(a) - 0.02, spring + rj * sin(a) - 0.02, z + 0.005, 0.04, 0.04, 0.04, fc)

## a glazed gallery hung on the front of a floor, from x0 to x1 and `d` out: its floor, a panel under the glass, thin
## frames, pale glass with white curtains behind, a head and a little roof of tiles
func _gallery(x0: float, x1: float, d: float, fc: int, y: float, h: float, face: float) -> void:
	var w := x1 - x0
	var yb := y + 0.08
	var yt := y + h - 0.35
	var gy := yb + 0.8
	var glass := 0x9fb4c0
	box(x0 - 0.06, yb - 0.14, face, w + 0.12, 0.14, d + 0.06, fc)                  # its floor, hung off the wall
	box(x0, yb, face + d - 0.05, w, 0.8, 0.05, fc)                                  # the panel under the glass, front and sides
	box(x0, yb, face, 0.05, 0.8, d, fc)
	box(x1 - 0.05, yb, face, 0.05, 0.8, d, fc)
	box(x0 + 0.05, gy, face + d - 0.035, w - 0.1, yt - gy, 0.012, glass)            # the glass
	box(x0 + 0.02, gy, face + 0.05, 0.012, yt - gy, d - 0.1, glass)
	box(x1 - 0.032, gy, face + 0.05, 0.012, yt - gy, d - 0.1, glass)
	box(x0 + 0.1, gy + 0.05, face + d - 0.22, w - 0.2, (yt - gy) * 0.72, 0.012, 0xf2eee6)   # the curtains behind it
	var nm := maxi(2, int(round(w / 0.55)))
	for k in range(nm + 1):                  # the frames: uprights along the front, one at each back corner
		box(x0 + (w - 0.05) * k / float(nm), gy, face + d - 0.06, 0.05, yt - gy, 0.06, fc)
	for sx in [x0, x1 - 0.05]:
		box(sx, gy, face, 0.05, yt - gy, 0.06, fc)
	box(x0, gy + (yt - gy) * 0.62, face + d - 0.055, w, 0.04, 0.05, fc)            # a transom across the top lights
	box(x0, yt, face, w, 0.12, d, fc)                                                # its head
	box(x0 - 0.1, yt + 0.12, face, w + 0.2, 0.08, d + 0.16, 0xb0603e)              # a little roof of tiles

## a lintel of bricks on end over an opening, with the little ears that hang down at each side of it
func lintel(xc: float, y: float, w: float, face: float) -> void:
	box(xc - w / 2.0, y, face - 0.02, w, 0.24, 0.06, "brick")
	for sx in [xc - w / 2.0, xc + w / 2.0 - 0.13]:
		box(sx, y - 0.13, face - 0.02, 0.13, 0.13, 0.06, "brick")

## a little balcony of iron: its slab, the railing round three sides, a band of curls at its foot
## An outside stair climbing along the front from x0 at the floor's level to x1 a floor higher (x1 < x0: it climbs to
## the left), `w` out from the wall: solid steps of grey stone on a slab of the wall's own render (its edge a band up the
## side you see), and an iron rail along its open side.
func _stair(x0: float, x1: float, y: float, rise: float, face: float, w: float, iron: int, key) -> void:
	if absf(x1 - x0) < 0.5 or rise <= 0.0:
		return
	var n := maxi(3, int(ceil(rise / 0.19)))
	var run := (x1 - x0) / float(n)
	var st := rise / float(n)
	for k in range(n):
		var sx := minf(x0 + run * k, x0 + run * (k + 1))
		box(sx, y + st * k - 0.05, face, absf(run) + 0.01, st + 0.05 - 0.04, w, key)
		box(sx - 0.01, y + st * (k + 1) - 0.04, face, absf(run) + 0.03, 0.04, w + 0.02, 0x9a958c)     # the tread
	_bar(Vector2(x0, y - 0.12), Vector2(x1, y + rise - 0.12), face + w + 0.006, 0.3, key)       # the slab's edge
	var rz := face + w - 0.04
	var posts := maxi(4, int(absf(x1 - x0) / 0.12))
	for i in range(posts + 1):
		var t := float(i) / float(posts)
		var px := lerpf(x0, x1, t)
		var k := clampi(int(t * n), 0, n - 1)
		var base := y + st * (k + 1)
		var top_y := y + rise * t + 0.95
		box(px - 0.01, base, rz, 0.02, maxf(0.1, top_y - base), 0.02, iron)
	for by in [0.95, 0.2]:
		_bar(Vector2(x0, y + by), Vector2(x1, y + rise + by), rz + 0.025, 0.04 if by > 0.5 else 0.03, iron)

func balcony(xc: float, y: float, w: float, face: float, deep := 0.38, iron := 0x24221f) -> void:
	var x := xc - w / 2.0
	box(x, y - 0.09, face, w, 0.09, deep, 0xd9d2c2)
	box(x + 0.03, y - 0.14, face, w - 0.06, 0.05, deep - 0.04, 0xc4bdb0)
	var z := face + deep - 0.03
	var n := maxi(6, int(round(w / 0.115)))
	for i in range(n + 1):
		box(x + (w - 0.02) * i / n, y, z, 0.02, 0.95, 0.02, iron)
	for by in [0.02, 0.2, 0.93]:
		box(x, y + by, z - 0.005, w, 0.03, 0.03, iron)
	for i in range(n):
		box(x + (w - 0.02) * (i + 0.5) / n - 0.025, y + 0.08, z, 0.07, 0.07, 0.015, iron)
	for sx in [x, x + w - 0.02]:
		for k in range(1, 3):
			box(sx, y, face + (deep - 0.03) * k / 3.0, 0.02, 0.95, 0.02, iron)
		for by in [0.02, 0.2, 0.93]:
			box(sx, y + by, face, 0.03, 0.03, deep, iron)

## a pair of plank doors (a garage's), set back in their hole: boards, iron straps, a grille along the top of each leaf
func plank_doors(x: float, w: float, h: float, face: float, wood: int) -> void:
	var z := face - 0.2
	var dark := 0x6f4a1c
	box(x, 0.0, z - 0.04, w, h, 0.04, "w%d" % wood)
	for i in range(1, int(w / 0.19) + 1):                         # the joints between the boards
		box(x + i * 0.19 - 0.006, 0.0, z, 0.012, h - 0.5, 0.004, dark)
	box(x + w / 2.0 - 0.02, 0.0, z, 0.04, h, 0.012, dark)          # where the two leaves meet
	for leaf in range(2):
		var lx := x + leaf * w / 2.0
		box(lx + 0.12, h - 0.46, z, w / 2.0 - 0.24, 0.34, 0.01, 0x1c1a18)          # the grille at the top
		for i in range(1, int((w / 2.0 - 0.24) / 0.1)):
			box(lx + 0.12 + i * 0.1, h - 0.46, z + 0.01, 0.018, 0.34, 0.012, 0x3a342c)
		for sy in [0.45, h * 0.52]:                               # iron straps, with their studs
			box(lx + 0.05, sy, z, w / 2.0 - 0.1, 0.07, 0.012, 0x2e2a25)
			for i in range(5):
				box(lx + 0.14 + i * (w / 2.0 - 0.28) / 4.0 - 0.02, sy + 0.015, z + 0.012, 0.04, 0.04, 0.012, 0x15130f)
	box(x - 0.02, 0.0, z - 0.02, 0.08, h, 0.14, dark)              # the frame
	box(x + w - 0.06, 0.0, z - 0.02, 0.08, h, 0.14, dark)
	box(x, h - 0.08, z - 0.02, w, 0.08, 0.14, dark)

## a street door of varnished wood: two leaves with raised panels and a turned lattice above them, a fanlight with bars
func wood_door(x: float, y: float, w: float, h: float, z: float, wood: int) -> void:
	var dark := 0x8a5a1e
	var fan := 0.38
	box(x - 0.09, y, z, w + 0.18, h + fan + 0.1, 0.07, dark)       # the frame
	box(x, y, z + 0.05, w, h, 0.04, "w%d" % wood)
	box(x + w / 2.0 - 0.012, y, z + 0.09, 0.024, h, 0.008, dark)
	for leaf in range(2):
		var lx := x + leaf * w / 2.0 + 0.07
		var lw := w / 2.0 - 0.14
		box(lx, y + 0.12, z + 0.09, lw, 0.62, 0.02, 0xb58a4a)                      # the lower panel, raised
		box(lx + 0.05, y + 0.17, z + 0.11, lw - 0.1, 0.52, 0.012, wood)
		box(lx, y + 0.86, z + 0.09, lw, h - 1.0, 0.012, 0x7a4f1a)                  # the lattice
		for i in range(1, int(lw / 0.08)):
			box(lx + i * 0.08, y + 0.86, z + 0.1, 0.02, h - 1.0, 0.014, 0xb58a4a)
		for i in range(1, int((h - 1.0) / 0.16)):
			box(lx, y + 0.86 + i * 0.16, z + 0.1, lw, 0.02, 0.014, 0xb58a4a)
	box(x + w / 2.0 - 0.1, y + h * 0.48, z + 0.1, 0.07, 0.07, 0.04, 0xd8c04a)      # the knob, in the middle as they are here
	box(x, y + h + 0.04, z + 0.05, w, fan, 0.02, 0x1c1a18)         # the fanlight
	for i in range(1, int(w / 0.1)):
		box(x + i * 0.1, y + h + 0.04, z + 0.07, 0.018, fan, 0.012, 0x3a342c)

# ---------------- Calle de Alemania, 7 ----------------
## Catastro 4294305VJ5649S: built in 2000, 285 m2 -- a store of 123 m2 and a hall of 19 on the ground floor, the home
## (143 m2) above. A straight front of 10.75 m on a plot that leans to the left as it goes back 14 m; the upper floor
## flies over the pavement. From Catastro's photo of the front and the user's video (referencias/calle-alemania):
## white render over a skirting of tan brick, a brick pier at the left corner; the plank doors of the store, a barred
## window, and at the right the porch with the door at the back of it, under a ceiling of boards. Upstairs, three
## window-doors under brick lintels, each with its iron balcony. Deep eaves on wooden brackets.
func _alemania_7() -> void:
	var L := length
	var G := 2.9                    # the ground floor, up to the beam the upper one stands on
	var F := 3.2                    # the floor of the upper storey
	var T := 6.2                    # the top of the walls
	var FLY := 0.6                  # how far the upper floor comes out over the pavement
	var wood := 0xa98548
	var garage := Rect2(0.6, -0.4, 3.45, 3.0)                 # (to y = 2.6)
	var win := Rect2(4.75, 0.95, 1.5, 1.45)
	var porch := Rect2(7.75, -0.4, 2.55, 3.15)                # (to y = 2.75)
	# --- the ground floor ---
	wall(0.0, L, 0.9, G, 0.0, 0.3, [garage, win, porch], "render")
	wall(0.0, L, -1.4, 0.9, 0.035, 0.335, [garage, porch], "brick")                # the skirting (and on down, where the street falls away)
	box(0.0, -1.4, -0.3, 0.45, G + 1.4, 0.36, "brick")                             # the pier at the corner
	box(0.5, -1.4, -0.3, 3.65, 1.4, 0.42, 0x9a958c)                               # the threshold of the store
	plank_doors(garage.position.x, garage.size.x, 2.6, 0.0, wood)
	lintel(garage.position.x + garage.size.x / 2.0, 2.62, garage.size.x + 0.3, 0.0)
	window(win.position.x, win.position.y, win.size.x, win.size.y, 0.0, 0.75)
	grille(win.position.x - 0.06, win.position.y - 0.08, win.size.x + 0.12, win.size.y + 0.14, 0.0)
	lintel(win.position.x + win.size.x / 2.0, win.end.y + 0.03, win.size.x + 0.4, 0.0)
	box(6.72, 1.25, 0.0, 0.5, 0.36, 0.03, 0xbdb9ae)                               # the meters, behind their grey door
	for i in range(2):
		box(6.8 + i * 0.2, 1.42, 0.03, 0.13, 0.1, 0.004, 0x4a4d50)
	box(7.33, 1.4, 0.0, 0.24, 0.34, 0.11, 0x24221f)                               # the letter box
	box(7.3, 1.72, 0.0, 0.3, 0.05, 0.14, 0x24221f)
	# --- the porch: floor, three walls with the skirting carried round, a ceiling of boards; the door at the back ---
	var deep := 1.3
	box(porch.position.x, -1.4, -deep, porch.size.x, 1.45, deep + 0.12, 0xb9b2a6)                  # granite underfoot
	box(porch.position.x, 0.05, -deep, porch.size.x, 0.13, 0.3, 0xb9b2a6)                          # the doorstep
	box(porch.position.x - 0.2, 0.9, -deep - 0.2, 0.2, G - 0.9, deep - 0.1, "render")              # left wall
	box(porch.position.x - 0.2, -0.2, -deep - 0.2, 0.235, 1.1, deep - 0.1, "brick")
	box(porch.end.x, 0.9, -deep - 0.2, 0.2, G - 0.9, deep - 0.1, "render")                         # right wall
	box(porch.end.x - 0.035, -0.2, -deep - 0.2, 0.235, 1.1, deep - 0.1, "brick")
	box(porch.position.x, 0.9, -deep - 0.2, porch.size.x, G - 0.9, 0.2, "render")                  # the back
	box(porch.position.x, -0.2, -deep - 0.2, porch.size.x, 1.1, 0.235, "brick")
	wood_door(8.55, 0.18, 1.25, 2.1, -deep, 0xa27a40)
	box(porch.position.x - 0.2, 2.75, -deep, porch.size.x + 0.65, 0.15, deep + FLY, 0x9a7646)      # the ceiling of boards, out to the edge of the floor above
	for i in range(1, int((deep + FLY) / 0.16)):
		box(porch.position.x - 0.2, 2.745, -deep + i * 0.16, porch.size.x + 0.65, 0.006, 0.012, 0x6f5630)
	# --- the beam, and the upper floor flying out on it ---
	box(0.0, G, -0.3, L, F - G, 0.3 + FLY, "render")
	box(0.0, G - 0.13, 0.0, porch.position.x - 0.2, 0.13, FLY * 0.5, 0xe9dcc0)                     # the moulding under its edge
	var doors: Array = []
	for xc in [2.3, 5.3, 8.3]:
		doors.append(Rect2(xc - 0.65, F + 0.04, 1.3, 2.26))
	wall(0.0, L, F, T, FLY, FLY, doors, "render")
	for r in doors:
		var d: Rect2 = r
		window(d.position.x, d.position.y, d.size.x, d.size.y, FLY, 0.78)
		lintel(d.position.x + d.size.x / 2.0, d.end.y + 0.03, d.size.x + 0.5, FLY)
		balcony(d.position.x + d.size.x / 2.0, F + 0.02, 2.0, FLY)
	box(L - 0.22, -0.1, 0.0, 0.09, G + 0.1, 0.09, 0xf1eee6)                                        # the downpipe
	box(L - 0.22, G, FLY, 0.09, T - G, 0.09, 0xf1eee6)
	# --- the eaves: brackets of wood, a soffit of tiles, then the roof ---
	box(0.0, T, 0.0, L, 0.24, FLY, "render")
	var eave := FLY + 0.7
	for i in range(int(L / 0.56) + 1):
		box(0.12 + i * 0.56, T, FLY, 0.09, 0.17, 0.62, 0x5a3a22)
	box(-0.15, T + 0.17, FLY - 0.1, L + 0.3, 0.05, 0.8, 0x9c5a3e)
	box(-0.18, T + 0.2, eave - 0.06, L + 0.36, 0.09, 0.08, 0xb0603e)                               # the ends of the first row of tiles
	# The plot leans: the left side wall runs back from (0, 0) to (3.12, -14.87), the right from (10.75, 0) through
	# (11.25, -6.69) to (11.73, -13.08). The ridge runs parallel to the street, 6.5 m back.
	var ey := T + 0.26              # the roof at the edge of the eaves
	var ry := T + 2.2               # ...and at the ridge
	var rz := -6.5
	var e0 := Vector3(-0.18, ey, eave); var e1 := Vector3(L + 0.18, ey, eave)
	var r0 := Vector3(1.2, ry, rz); var r1 := Vector3(11.4, ry, rz)
	var b0 := Vector3(2.95, T + 0.2, -15.0); var b1 := Vector3(11.9, T + 0.2, -13.2)
	var run_f := (r0 - e0).length()
	var run_b := (b0 - r0).length()
	quad(e0, e1, r1, r0, "tiles", Vector3(0, 0.95, 0.3), [Vector2(e0.x, run_f) / 1.6, Vector2(e1.x, run_f) / 1.6, Vector2(r1.x, 0) / 1.6, Vector2(r0.x, 0) / 1.6])
	quad(r0, r1, b1, b0, "tiles", Vector3(0, 0.95, -0.3), [Vector2(r0.x, 0) / 1.6, Vector2(r1.x, 0) / 1.6, Vector2(b1.x, run_b) / 1.6, Vector2(b0.x, run_b) / 1.6])
	box(1.1, ry - 0.04, rz - 0.09, 10.4, 0.1, 0.18, 0xb0603e)                                      # the ridge tiles
	# the side walls and the back, a hand's breadth inside the plot's edge (the neighbours' own walls stand on it)
	var slope_f := (ry - ey) / (eave - rz)
	var top0 := ey + eave * slope_f - 0.06                    # the roof over the front wall
	var inl := 0.06
	var st = _tool("render")
	var l0 := Vector3(inl, -1.4, 0.0); var l2 := Vector3(3.12 + inl, -1.4, -14.87 + inl)
	var lt0 := Vector3(inl, top0, 0.0); var lt1 := Vector3(1.37 + inl, ry - 0.06, rz); var lt2 := Vector3(3.12 + inl, T + 0.14, -14.87 + inl)
	var ln := Vector3(-1.0, 0.0, -0.21)
	_tri(st, l0, l2, lt2, ln.normalized()); _tri(st, l0, lt2, lt1, ln.normalized()); _tri(st, l0, lt1, lt0, ln.normalized())
	var q0 := Vector3(L - inl, -1.4, 0.0); var q2 := Vector3(11.73 - inl, -1.4, -13.08 + inl)
	var qt0 := Vector3(L - inl, top0, 0.0); var qt1 := Vector3(11.24 - inl, ry - 0.06, rz); var qt2 := Vector3(11.73 - inl, T + 0.14, -13.08 + inl)
	var qn := Vector3(1.0, 0.0, 0.075)
	_tri(st, q0, q2, qt2, qn.normalized()); _tri(st, q0, qt2, qt1, qn.normalized()); _tri(st, q0, qt1, qt0, qn.normalized())
	quad(l2, q2, qt2, lt2, "render", Vector3(0.2, 0.0, -1.0))
	_acera(L)

# ---------------- a house from its description ----------------
# Most houses need no function of their own: a description is enough (SPECS, below). What it says:
#   "floors": one entry for each storey, from the ground up:
#       "wall": what it is made of -- a colour (painted render) or a kind of masonry ("brick", "brick_red", "stone"...)
#       "plinth": [how high, of what] -- a skirting (on an upper floor: the apron under its windows)
#       "fly": how far this floor's wall stands out over the pavement (the floors above keep it unless they say otherwise)
#       "h": the height of the ground floor (3.0 if not given; the upper ones share out the rest, up to the house's `h` in the bake)
#       "open": its openings, each [kind, where along the front (0 at its left end as you face it .. 1), how wide, ...]:
#           ["win", at, w, sill, h, {...}]   a window          ["bal", at, w, h, {...}]   a window-door with its balcony
#           ["door", at, w, h, {...}]        a street door     ["gar", at, w, h, {...}]   a garage or store door
#           ["shop", at, w, h, {...}]        a shop window, glass from knee height ("f" its frame's colour)
#         and in {...}: "g" a grille ("bars", "lattice", "tijera": folding, on a window or a door), "b" the blind's colour, "d" how far down it is (0..1), "f" the
#         frame's colour, "s" a surround (colour or masonry) + "sb" its width, "l": "brick" a lintel of bricks on end,
#         "bal" a low rail on a window's sill ("iron", "white"), "rem" (1) a crest of iron on top of the grille (bars; on an
#         arc the bars follow its curve, and rem makes a fan in it), "fr" a little pediment of that colour over the window, "k" the kind of door ("wood", "metal", "curtain";
#         "planks", "roller", "sect", "metal"), "c" its colour, "bw" a balcony's width, "nb" no balcony of its own
#       "terrace": [from, to, how deep, awning colour or -1, (the railing's colour)] -- one long balcony, under an awning
#       "signs": [[from, to, colour, what it says, the letters' colour], ...] -- the boards over the shops. They say what
#           is sold, never whose it is: the real shops' names are not ours to use
#       "awnings": [[from, to, colour], ...] -- over a shop window
#       "plates": [[at, y, kind, z, colour, style, lado], ...] -- a notice on the front, its middle at (at, y) and z out from the
#           wall (on a window's grille: about 0.12): "sevende"/"sealquila" (a board for sale or to let: colour is its
#           band, or with style 1 its letters on a white board), "vado" (the town's plate for a garage way), "noaparcar"
#           (the yellow one people paint themselves), "papel" (a sheet taped to a gate, written by hand). colour -1 and
#           style 0 are the usual. lado 1: on the house's longest wall to another street instead (at along it,
#           from its left end as you face it). In the short form: "cartel at y kind [z=..] [c=colour] [t=1] [lado=1]"
#       "band": a string course at its foot, of this colour or masonry
#       "panels": [[from, to, what, plinth], ...] -- a stretch of this floor's wall in another render or masonry (where one
#           wall runs across two buildings); plinth as above, null for none, "same" for the floor's own.
#           In the short form: "paño <from> <to> wall=<what> [plinth=<height>:<what>, or plinth=0 for none] [out=<m>]"; out= makes
#           it a body standing that far out of the wall (a bay of brick up the front), with its openings in its face; r=<m>
#           rounds its two front corners
#   "eaves": "tiles" (the plain edge of the roof), "brackets" (deep, on wooden brackets), "cornice" (a moulded one), "flat"
#   "tol": how far off the straight line of the front the plot's own outline may wander and still be the front
# Walls that give on to another street get the same materials and a plain row of the house's own windows.
const SLOPE := 0.27
var _rz := -6.0                 # where the ridge is (z, in the house's frame)
var _ey := 0.0                  # the roof at the edge of the eaves...
var _ez := 0.3                  # ...and where that edge is
var _flat_roof := false
var _flank := false             # the side front being built is the house's longest to another street (its notices: lado=1)

func _mat(spec):
	if spec is int:
		return "r%d" % spec
	return String(spec)

## a value written in a house's short description: a colour (six hex digits), a number, or a word
static func _word(s: String):
	if s.length() == 6 and s.is_valid_hex_number():
		return s.hex_to_int()
	if s.is_valid_float():
		return s.to_float()
	return s

## The short way of describing a house (casas_calles.gd): [eaves, the ground floor, the floor above, ...], each floor a
## line of pieces separated by "|". The first piece is the floor itself: wall=<colour or masonry> plinth=<height>:<what>
## fly=<m> h=<m> band=<what>. The others are what is in it:
##     win <at> [w sill h]      bal <at> [w h]      door <at> [w h]      gar <at> [w h]      shop <at> [w h]
##     arc <at> [w sill h]   (an arched bay set into the wall, a loggia: s= its ring, sb= how wide, d= how deep, bal=iron a rail,
##                            f=<colour> a window of wood inside it, g=bars its iron)
##     sign <from> <to> <colour> <WORDS_LIKE_THIS> <letters' colour>      awn <from> <to> <colour>
##     ter <from> <to> <deep> <awning colour or -1> [railing colour]
##     teja <from> <to> [deep] [y=<m>]   (a tejadillo: a strip of tiled roof leaning out over the doors, its foot y up the wall)
##     mir <from> <to> [deep] [c=frame]   (a glazed gallery hung on the floor's front, a mirador)
##     pintada <at> [room]   (graffiti in the photo: props.gd paints a peña's tag there, one of the town's sixty)
##     parche <at> [w sill h] wall=<what> [k=chapa]   (a patch of other brick or render laid on the wall: a window walled up, a mend;
##           k=chapa: corrugated sheet, with its ribs)
## <at> may be several places at once (.2,.5,.8); what is left out takes the usual size; options are key=value as in
## the long form (g=bars b=8a6a4a d=0.5 f=... s=... sb=... l=brick bal=iron k=curtain c=... bw=... nb=1).
## A floor written "=" is the one below it again. "tol=0.9" and "trim=<colour>" may stand as lines of their own.
## A line that begins "lado " is a floor of the house's longest wall to another street, ground floor first, written the
## same way (positions along that wall from its left end as you face it; its notices, signs, awnings and lean-tos go on it). Without them that wall
## gets a plain row of the house's own windows; a floor written "lado wall=..." with nothing else is a blank wall.
static func _unpack(a: Array) -> Dictionary:
	var spec := {"eaves": String(a[0]), "floors": []}
	var usual := {"win": [1.1, 1.0, 1.2], "bal": [1.1, 2.2], "door": [1.1, 2.3], "gar": [2.8, 2.6], "shop": [3.0, 2.6], "arc": [1.6, 0.1, 2.4]}
	for i in range(1, a.size()):
		var line := String(a[i])
		var into := "floors"
		if line.begins_with("lado "):              # a floor of the long side to another street, from the photos (see the docs)
			into = "flank"
			line = line.substr(5).strip_edges()
			if not spec.has("flank"):
				spec["flank"] = []
		if line == "=":
			spec[into].append(spec[into][-1])
			continue
		if line.begins_with("tol=") or line.begins_with("trim="):
			spec[line.get_slice("=", 0)] = _word(line.get_slice("=", 1))
			continue
		var segs := line.split("|")
		var f := {"open": []}
		for tok in segs[0].split(" ", false):
			var key := tok.get_slice("=", 0)
			var val := tok.get_slice("=", 1)
			match key:
				"wall", "band":
					f[key] = _word(val)
				"plinth":
					f["plinth"] = [val.get_slice(":", 0).to_float(), _word(val.get_slice(":", 1))]
				"fly", "h":
					f[key] = val.to_float()
		for s in range(1, segs.size()):
			var t := segs[s].strip_edges().split(" ", false)
			if t.is_empty():
				continue
			var kind := t[0]
			var words: Array = []
			var o := {}
			for k in range(1, t.size()):
				if "=" in t[k]:
					o[t[k].get_slice("=", 0)] = _word(t[k].get_slice("=", 1))
				else:
					words.append(t[k])
			match kind:
				"sign":
					if not f.has("signs"):
						f["signs"] = []
					f["signs"].append([String(words[0]).to_float(), String(words[1]).to_float(), String(words[2]).hex_to_int(), String(words[3]).replace("_", " "), String(words[4]).hex_to_int()])
				"cartel":                         # a notice: cartel at y kind (sevende, sealquila, vado, noaparcar, papel) [z=out] [c=colour] [t=1] [lado=1]
					if not f.has("plates"):
						f["plates"] = []
					f["plates"].append([String(words[0]).to_float(), String(words[1]).to_float(), String(words[2]), float(o.get("z", 0.04)), int(o.get("c", -1)), int(o.get("t", 0)), int(o.get("lado", 1 if into == "flank" else 0))])
				"awn":
					if not f.has("awnings"):
						f["awnings"] = []
					f["awnings"].append([String(words[0]).to_float(), String(words[1]).to_float(), String(words[2]).hex_to_int()])
				"paño", "pano":                   # a stretch of this floor's wall in another render: paño from to wall=... [plinth=h:what or 0]
					if not f.has("panels"):
						f["panels"] = []
					var pp = "same"
					if o.has("plinth"):
						var ps := str(o["plinth"])
						pp = null if ps.to_float() <= 0.0 else [ps.get_slice(":", 0).to_float(), _word(ps.get_slice(":", 1))]
					f["panels"].append([String(words[0]).to_float(), String(words[1]).to_float(), o.get("wall", 0xf2efe6), pp, float(o.get("out", 0.0)), float(o.get("r", 0.0))])
				"parche":                         # a patch of other brick or render on the wall: parche <at>[,<at>...] [w sill h] wall=<what>
					if not f.has("patches"):
						f["patches"] = []
					for at in String(words[0]).split(","):
						f["patches"].append([at.to_float(), String(words[1]).to_float() if words.size() > 1 else 1.0, String(words[2]).to_float() if words.size() > 2 else 0.6, String(words[3]).to_float() if words.size() > 3 else 1.5, o.get("wall", 0xe8e0d0), String(o.get("k", ""))])
				"mir":                            # a glazed gallery hung on the wall: mir <from> <to> [deep] [c=its frame]
					if not f.has("galleries"):
						f["galleries"] = []
					f["galleries"].append([String(words[0]).to_float(), String(words[1]).to_float(), String(words[2]).to_float() if words.size() > 2 else 0.6, int(o.get("c", 0x5a4030))])
				"pintada":                        # graffiti seen in the photo: pintada <at> [room]; a peña's tag goes there (props.gd)
					if not f.has("tags"):
						f["tags"] = []
					f["tags"].append([String(words[0]).to_float(), String(words[1]).to_float() if words.size() > 1 else 3.0])
				"teja":                           # a little lean-to of tiles over the doors: teja <from> <to> [deep] [y=its foot on the wall]
					if not f.has("tejas"):
						f["tejas"] = []
					f["tejas"].append([String(words[0]).to_float(), String(words[1]).to_float(), String(words[2]).to_float() if words.size() > 2 else 0.6, float(o.get("y", -1.0))])
				"esc":                            # an outside stair up the front to the floor above: esc <from> <to> [w=how far out] [c=its rail]
					if not f.has("stairs"):
						f["stairs"] = []
					f["stairs"].append([String(words[0]).to_float(), String(words[1]).to_float(), float(o.get("w", 0.9)), int(o.get("c", 0x24221f))])
				"ter":
					var tr: Array = [String(words[0]).to_float(), String(words[1]).to_float(), String(words[2]).to_float(), -1 if String(words[3]) == "-1" else String(words[3]).hex_to_int()]
					if words.size() > 4:
						tr.append(String(words[4]).hex_to_int())
					f["terrace"] = tr
				_:
					if not usual.has(kind) or words.is_empty():
						continue
					var sizes: Array = (usual[kind] as Array).duplicate()
					for k in range(mini(sizes.size(), words.size() - 1)):
						sizes[k] = String(words[k + 1]).to_float()
					for at in String(words[0]).split(","):
						f["open"].append([kind, at.to_float()] + sizes + [o])
		spec[into].append(f)
	return spec

func _dark(hex: int, by := 0.25) -> int:
	return Parts.col(hex).darkened(by).to_rgba32() >> 8

func tri(a: Vector3, b: Vector3, c: Vector3, key, n: Vector3, uvs = null) -> void:
	_tri(_tool(key), _xf * a, _xf * b, _xf * c, (_xf.basis * n).normalized(), uvs)

## a band of another colour or material round an opening (a door's goes down to the floor)
func surround(r: Rect2, face: float, key, band := 0.13, to_floor := false) -> void:
	box(r.position.x - band, r.end.y, face - 0.02, r.size.x + band * 2.0, band, 0.05, key)
	if not to_floor:
		box(r.position.x - band, r.position.y - band, face - 0.02, r.size.x + band * 2.0, band, 0.05, key)
	box(r.position.x - band, r.position.y, face - 0.02, band, r.size.y, 0.05, key)
	box(r.end.x, r.position.y, face - 0.02, band, r.size.y, 0.05, key)

## a folding lattice shut over a window
func lattice(x: float, y: float, w: float, h: float, face: float) -> void:
	box(x, y, face + 0.02, w, h, 0.03, 0xe6dcb8)
	for i in range(1, int(w / 0.17) + 1):
		box(x + i * 0.17 - 0.01, y, face + 0.05, 0.02, h, 0.006, 0xb8ac88)
	for i in range(1, int(h / 0.17) + 1):
		box(x, y + i * 0.17 - 0.01, face + 0.05, w, 0.02, 0.006, 0xb8ac88)
	for e in [[x - 0.04, y - 0.04, w + 0.08, 0.04], [x - 0.04, y + h, w + 0.08, 0.04], [x - 0.04, y, 0.04, h], [x + w, y, 0.04, h]]:
		box(e[0], e[1], face + 0.02, e[2], e[3], 0.05, 0xa89c7a)

## a folding grille (a tijera): uprights, the links between them crossed like scissors, a rail top and bottom
func tijera(x: float, y: float, w: float, h: float, face: float) -> void:
	var iron := 0x5c5e5c
	var z := face + 0.05
	var n := maxi(3, int(round(w / 0.11)))
	var step := w / n
	for i in range(n + 1):
		box(x + i * step - 0.01, y, z, 0.02, h, 0.025, iron)
	var rows := maxi(2, int(round(h / 0.24)))
	var rh := h / rows
	for i in range(n):
		for j in range(rows):
			var a := Vector2(x + i * step, y + j * rh)
			var b := Vector2(x + (i + 1) * step, y + (j + 1) * rh)
			_bar(a, b, z + 0.026, 0.012, iron)
			_bar(Vector2(a.x, b.y), Vector2(b.x, a.y), z + 0.026, 0.012, iron)
	box(x - 0.02, y + h - 0.05, z - 0.01, w + 0.04, 0.05, 0.04, iron)
	box(x - 0.02, y, z - 0.01, w + 0.04, 0.04, 0.04, iron)

## a flat strip from a to b (x, y), `t` wide, facing the street `z` out (one side only: it is seen from the street)
func _bar(a: Vector2, b: Vector2, z: float, t: float, key) -> void:
	var d := (b - a).normalized()
	var q := Vector2(-d.y, d.x) * t / 2.0
	quad(Vector3(a.x - q.x, a.y - q.y, z), Vector3(b.x - q.x, b.y - q.y, z), Vector3(b.x + q.x, b.y + q.y, z), Vector3(a.x + q.x, a.y + q.y, z), key, Vector3(0, 0, 1))

## a low rail on a window's sill: iron bars, or a white balustrade
func rail(xc: float, y: float, w: float, face: float, h := 0.5, white := false) -> void:
	var c := 0xe8e4d8 if white else 0x24221f
	var t := 0.06 if white else 0.02
	var x := xc - w / 2.0
	var z := face + 0.1
	var n := maxi(4, int(round(w / (0.16 if white else 0.115))))
	for i in range(n + 1):
		box(x + (w - t) * i / n, y, z, t, h, t, c)
	box(x, y + h - 0.04, z - 0.01, w, 0.05, t + 0.02, c)
	box(x, y, z - 0.01, w, 0.04, t + 0.02, c)
	box(x - 0.03, y - 0.06, face, w + 0.06, 0.06, 0.2, 0xd9d2c2)

## a doorway left open behind its curtain
## (the curtain is cloth, moved by the wind and by whoever goes past -- tela.gd). What `o` may say of it, so that it is
## the one in the photo:  c=<colour>  or  c=<colour>+<colour>+...  the colours of its stripes, in order (the same one
## twice makes that stripe twice as wide);  sw=<m> how wide a stripe is (0.09);  p=liso (plain), rayas (stripes: what it
## is if nothing is said -- of one colour, in its lighter and darker tones), flores (flowers) or cuadros (little
## checks), these two printed in  m=<colour>  on the first colour.
func curtain_door(x: float, y: float, w: float, h: float, face: float, o: Dictionary = {}) -> void:
	var z := face - 0.22
	box(x, y, z - 0.03, w, h, 0.03, 0x2a241f)
	box(x, y + h - 0.08, z, w, 0.08, 0.14, 0x5a4a3a)
	if not _tools.has("tela"):
		_tools["tela"] = Tela.begin()
		_mats["tela"] = Tela.material()
	var tones: Array = []
	var given = o.get("c", 0xb9a070)
	if given is String:
		for part in String(given).split("+", false):
			tones.append(Parts.col(part.hex_to_int()))
	else:
		tones.append(Parts.col(int(given)))
	var kind := String(o.get("p", "rayas"))
	if kind == "rayas" and tones.size() == 1:                 # one colour: its own lighter and darker tones
		var base: Color = tones[0]
		tones = [base, base.darkened(0.3), base.lightened(0.3), base.darkened(0.12)]
	elif kind != "rayas":
		tones = [tones[0]]
	var bands := maxi(1, int(round(w / float(o.get("sw", 0.09)))))
	var stripes := func(a: float, d: float) -> Color:
		return (tones[int(a * bands) % tones.size()] as Color) * (1.0 - 0.1 * d)          # (a little grubbier towards the floor)
	var motif := Color(0, 0, 0, 0)
	if kind == "flores" or kind == "cuadros":
		var ink: Color = Parts.col(int(o.get("m", 0x8a4a30)))
		motif = Color(ink.r, ink.g, ink.b, 1.0 if kind == "flores" else 2.0)
	var hang := h - 0.13
	Tela.sheet(_tools["tela"], _xf * Vector3(x + w - 0.01, y + h - 0.08, z + 0.1), _xf.basis * Vector3(-(w - 0.02), 0.0, 0.0), _xf.basis * Vector3(0.0, -hang, 0.0),
		true, stripes, 0.16, fposmod(x * 0.37 + self.o.x * 0.13 + self.o.y * 0.29, 1.0), 0.028, bands * maxi(1, int(ceil(w / 0.06 / bands))), 9, motif)
	boxes += 1

## a door or gate of sheet metal, ribbed
func sheet_door(x: float, y: float, w: float, h: float, face: float, col: int, ribs := 0.3) -> void:
	var z := face - 0.18
	var dark := _dark(col)
	box(x, y, z - 0.04, w, h, 0.04, col)
	for i in range(1, int(w / ribs) + 1):
		box(x + i * ribs - 0.012, y, z, 0.024, h, 0.012, dark)
	box(x, y + h * 0.55, z, w, 0.05, 0.014, dark)
	if w > 1.8:
		box(x + w / 2.0 - 0.02, y, z, 0.04, h, 0.016, _dark(col, 0.45))

func roller_door(x: float, y: float, w: float, h: float, face: float, col: int) -> void:
	var z := face - 0.18
	box(x, y, z - 0.04, w, h, 0.04, col)
	for i in range(1, int(h / 0.12) + 1):
		box(x, y + i * 0.12, z, w, 0.02, 0.01, _dark(col))
	box(x, y + h - 0.2, z, w, 0.2, 0.06, _dark(col, 0.15))

func sect_door(x: float, y: float, w: float, h: float, face: float, col: int) -> void:
	var z := face - 0.18
	box(x, y, z - 0.04, w, h, 0.04, col)
	for i in range(1, 4):
		box(x, y + h * i / 4.0, z, w, 0.03, 0.01, _dark(col))
	for i in range(3):
		box(x + w * (0.14 + i * 0.27), y + h * 0.82, z, w * 0.18, h * 0.09, 0.012, 0xcfd6d0)

## a plain panelled street door, one leaf or two
func panel_door(x: float, y: float, w: float, h: float, face: float, col: int) -> void:
	var z := face - 0.2
	var dark := _dark(col)
	box(x, y, z - 0.04, w, h, 0.04, "w%d" % col)
	var leaves := 2 if w > 1.15 else 1
	for l in range(leaves):
		var lx := x + l * w / leaves + 0.08
		var lw := w / leaves - 0.16
		box(lx, y + 0.12, z, lw, h * 0.34, 0.015, dark)
		box(lx, y + 0.12 + h * 0.4, z, lw, h * 0.48, 0.015, dark)
	box(x + w * (0.5 if leaves == 2 else 0.86) - 0.03, y + h * 0.47, z + 0.015, 0.06, 0.06, 0.03, 0xd8c04a)
	box(x - 0.04, y, z - 0.02, 0.04, h, 0.1, dark)
	box(x + w, y, z - 0.02, 0.04, h, 0.1, dark)

func _opening(kind: String, r: Rect2, o: Dictionary, face: float, y: float) -> void:
	var x := r.position.x
	var w := r.size.x
	match kind:
		"win", "bal":
			window(x, r.position.y, w, r.size.y, face, float(o.get("d", 0.7)), int(o.get("f", 0xf1eee6)), int(o.get("b", 0xf1eee6)))
			match String(o.get("g", "")):
				"bars":
					grille(x - 0.06, r.position.y - 0.08, w + 0.12, r.size.y + 0.14, face)
					if o.get("rem", false):
						crest(x + w / 2.0, r.end.y + 0.06, w + 0.12, face + 0.07)
				"lattice":
					lattice(x, r.position.y, w, r.size.y, face)
				"tijera":
					tijera(x - 0.03, r.position.y - 0.03, w + 0.06, r.size.y + 0.06, face)
			if o.has("s"):
				surround(r, face, _mat(o["s"]), float(o.get("sb", 0.13)), kind == "bal")
			if String(o.get("l", "")) == "brick":
				lintel(x + w / 2.0, r.end.y + 0.03, w + 0.45, face)
			if o.has("fr"):
				pediment(x + w / 2.0, r.end.y + (0.3 if o.get("rem", false) else 0.04), w + 0.3, face, _mat(o["fr"]))
			if kind == "bal":
				if not o.get("nb", false):
					balcony(x + w / 2.0, y + 0.02, float(o.get("bw", w + 0.7)), face, 0.38, 0xe8e8e4 if String(o.get("k", "")) == "white" else 0x24221f)
			elif o.has("bal"):
				rail(x + w / 2.0, r.position.y, w + 0.3, face, 0.5, String(o["bal"]) == "white")
		"arc":                                   # an arched bay set into the wall (a loggia): its back in shadow, a ring of brick round its top
			var sy := r.position.y
			var rr := w / 2.0
			var spring := r.end.y - rr
			var cx := x + rr
			var dd := float(o.get("d", 1.1))
			var wk = o.get("_wall", "r%d" % 0xf2efe6)
			box(x, sy, face - dd - 0.04, w, r.size.y, 0.04, int(o.get("c", 0x4a3c34)))          # the back of the bay, in shadow
			box(x - 0.05, sy, face - dd, 0.05, r.size.y, dd, wk)                                   # its sides, as deep as it goes
			box(x + w, sy, face - dd, 0.05, r.size.y, dd, wk)
			box(x - 0.04, sy - 0.06, face - dd, w + 0.08, 0.06, dd + 0.2, 0xd9d2c2)               # its floor, a little out over the front
			var n := 16
			for k in range(n):                   # the round top: the wall filled back above the curve, a strip at a time
				var xa := x + w * k / float(n)
				var dx := xa + w / (2.0 * n) - cx
				var yc := spring + sqrt(maxf(0.0, rr * rr - dx * dx))
				box(xa, yc, face - dd, w / float(n) + 0.002, r.end.y - yc + 0.01, dd, wk)
			var ring = _mat(o.get("s", "brick"))
			var sb := float(o.get("sb", 0.16))
			var zr := face + 0.03
			for k in range(n):                   # the ring round it
				var t0 := PI * k / float(n)
				var t1 := PI * (k + 1) / float(n)
				quad(Vector3(cx + rr * cos(t0), spring + rr * sin(t0), zr), Vector3(cx + (rr + sb) * cos(t0), spring + (rr + sb) * sin(t0), zr),
					Vector3(cx + (rr + sb) * cos(t1), spring + (rr + sb) * sin(t1), zr), Vector3(cx + rr * cos(t1), spring + rr * sin(t1), zr), ring, Vector3(0, 0, 1))
			box(x - sb, sy, face - 0.02, sb, spring - sy, 0.05, ring)
			box(x + w, sy, face - 0.02, sb, spring - sy, 0.05, ring)
			if o.has("bal"):
				rail(cx, sy, w + 0.1, face, 0.5, String(o["bal"]) == "white")
			if o.has("f"):                       # a window of wood inside it: its frame, set back behind the iron
				arch_frame(x, sy, w, spring, face - minf(dd, 0.3) + 0.08, int(o["f"]))
			if String(o.get("g", "")) == "bars":
				arch_grille(x, sy, w, spring, face - 0.06, o.get("rem", false))
		"door":
			var h := r.end.y - y
			match String(o.get("k", "wood")):
				"curtain":
					curtain_door(x, y, w, h, face, o)
				"metal":
					sheet_door(x, y, w, h, face, int(o.get("c", 0x6a7278)), 0.28)
				_:
					panel_door(x, y, w, h, face, int(o.get("c", 0x6b4424)))
			if String(o.get("g", "")) == "tijera":
				tijera(x, y, w, h, face)
			box(x - 0.05, y - 0.6, face - 0.3, w + 0.1, 0.65, 0.42, 0xb9b2a6)                 # the doorstep
			if o.has("s"):
				surround(Rect2(x, y, w, h), face, _mat(o["s"]), float(o.get("sb", 0.13)), true)
		"shop":
			var fr: int = o.get("f", 0x2a2c30)
			var z := face - 0.16
			box(x, r.position.y, z - 0.03, w, r.size.y, 0.03, 0x24384a)                 # the glass, dark with what is behind it
			box(x, r.position.y + r.size.y * 0.45, z, w * 0.5, r.size.y * 0.5, 0.004, 0x35506a)       # a little sky in it
			for e in [[x, r.position.y, 0.07, r.size.y], [x + w - 0.07, r.position.y, 0.07, r.size.y], [x, r.position.y, w, 0.07], [x, r.end.y - 0.09, w, 0.09]]:
				box(e[0], e[1], z, e[2], e[3], 0.06, fr)
			for i in range(1, int(round(w / 1.4))):
				box(x + w * i / round(w / 1.4) - 0.03, r.position.y, z, 0.06, r.size.y, 0.06, fr)
			box(x - 0.03, r.position.y - 0.06, face - 0.16, w + 0.06, 0.06, 0.22, 0xb9b2a6)
		"gar":
			var gh := r.end.y - y
			if String(o.get("k", "")) == "hueco":            # the hole left as it is: what fills it is built by whoever has the place
				return
			if String(o.get("k", "")) == "void":             # a way through under the house: nothing but the dark of it
				box(x, y, face - 0.3, w, gh, 0.02, 0x15161a)
				box(x, y - 0.6, face - 0.3, w, 0.62, 0.34, 0x8a8480)
				if String(o.get("g", "")) == "bars":         # ...shut off by an iron gate (a porch behind a railing)
					grille(x + 0.03, y + 0.02, w - 0.06, gh - 0.08, face - 0.14, 0.02)
				return
			match String(o.get("k", "planks")):
				"planks":
					plank_doors(x, w, gh, face, int(o.get("c", 0x6b4424)))
				"roller":
					roller_door(x, y, w, gh, face, int(o.get("c", 0x7a5a40)))
				"sect":
					sect_door(x, y, w, gh, face, int(o.get("c", 0x7a5a40)))
				_:
					sheet_door(x, y, w, gh, face, int(o.get("c", 0x6a7278)), 0.35)
			box(x - 0.05, y - 0.6, face - 0.3, w + 0.1, 0.6, 0.4, 0x9a958c)                   # its threshold
			if o.has("s"):
				surround(Rect2(x, y, w, gh), face, _mat(o["s"]), float(o.get("sb", 0.15)), true)

## the windows of a wall that gives on to another street: the house's own, in a plain row
func _rhythm(f: Dictionary, L: float, ground: bool) -> Array:
	if L < 2.6:
		return []
	var tmpl: Array = []
	for op in f.get("open", []):
		if op[0] == "win":
			tmpl = op
			break
		if op[0] == "bal" and tmpl.is_empty():
			tmpl = ["win", 0.0, op[2], 1.0, 1.2, op[-1] if op[-1] is Dictionary else {}]
	if tmpl.is_empty():
		tmpl = ["win", 0.0, 1.1, 1.0, 1.2, {}]
	var o: Dictionary = (tmpl[-1] as Dictionary).duplicate() if tmpl[-1] is Dictionary else {}
	o.erase("bal")
	if ground and not o.has("g"):
		o["g"] = "bars"
	var n := maxi(1, int(round(L / 3.8)))
	var res: Array = []
	for k in range(n):
		res.append(["win", (k + 0.5) / n, tmpl[2], tmpl[3], tmpl[4], o])
	return res

## one front, `L` long, in the frame that is set: returns how far its top floor stands out
func _facade(L: float, spec: Dictionary, side := false) -> float:
	var floors: Array = spec["floors"]
	var n := floors.size()
	var gh: float = top if n == 1 else float(floors[0].get("h", 3.0))
	var y := 0.0
	var prev_fly := 0.0
	for i in range(n):
		var f: Dictionary = floors[i]
		var h: float = gh if i == 0 else (top - gh) / float(n - 1)
		var fly: float = 0.0 if side else float(f.get("fly", prev_fly))
		var ops: Array = _rhythm(f, L, i == 0) if side else f.get("open", [])
		var panels: Array = [] if side else f.get("panels", [])
		if side and _flank and spec.has("flank") and i < (spec["flank"] as Array).size():
			f = f.duplicate()                    # (the long side as it is in the photos: its own openings, render, foot)
			f.merge(spec["flank"][i], true)
			ops = f.get("open", [])
			panels = (spec["flank"][i] as Dictionary).get("panels", [])
		var holes: Array = []
		var items: Array = []
		for op in ops:
			var kind: String = op[0]
			var w: float = op[2]
			var xc: float = float(op[1]) * L
			var o: Dictionary = op[-1] if op[-1] is Dictionary else {}
			var r := Rect2()
			match kind:
				"win", "arc":
					r = Rect2(xc - w / 2.0, y + float(op[3]), w, float(op[4]))
				"bal":
					r = Rect2(xc - w / 2.0, y + 0.04, w, float(op[3]))
				"shop":
					r = Rect2(xc - w / 2.0, y + 0.45, w, float(op[3]) - 0.45)
				_:
					r = Rect2(xc - w / 2.0, y - 0.6, w, float(op[3]) + 0.6)
			holes.append(r)
			items.append([kind, r, o])
		var key = _mat(f.get("wall", spec.get("wall", 0xf2efe6)))
		var thick := fly + 0.3
		var y0 := -1.4 if i == 0 else y
		var pl = f.get("plinth", null)
		var cuts: Array = [[0.0, L, key, pl, 0.0, 0.0]]       # its stretches: its own render, and any paño of another
		for pn in panels:
			var a0 := clampf(float(pn[0]) * L, 0.0, L)
			var a1 := clampf(float(pn[1]) * L, 0.0, L)
			if a1 - a0 < 0.05:
				continue
			var rest: Array = []
			for c in cuts:
				if c[1] <= a0 or c[0] >= a1:
					rest.append(c)
					continue
				if c[0] < a0:
					rest.append([c[0], a0, c[2], c[3], c[4], c[5]])
				if c[1] > a1:
					rest.append([a1, c[1], c[2], c[3], c[4], c[5]])
			rest.append([a0, a1, _mat(pn[2]), pl if (pn[3] is String) else pn[3], float(pn[4]) if pn.size() > 4 else 0.0, float(pn[5]) if pn.size() > 5 else 0.0])
			cuts = rest
		for c in cuts:
			var cpl = c[3]
			var co: float = c[4]                     # (out=: a body that stands out of the wall, a bay of brick up the front)
			var cr: float = minf(float(c[5]), co) if co > 0.0 else 0.0      # (r=: its two front corners rounded)
			if cpl != null:
				wall(c[0] + cr, c[1] - cr, y0, y + float(cpl[0]), fly + co + 0.035, thick + co + 0.035, holes, _mat(cpl[1]))
				wall(c[0] + cr, c[1] - cr, y + float(cpl[0]), y + h, fly + co, thick + co, holes, c[2])
			else:
				wall(c[0] + cr, c[1] - cr, y0, y + h, fly + co, thick + co, holes, c[2])
			if cr > 0.0:
				var bands: Array = [[y0, y + h, c[2], 0.0]] if cpl == null else [[y0, y + float(cpl[0]), _mat(cpl[1]), 0.035], [y + float(cpl[0]), y + h, c[2], 0.0]]
				for bd in bands:
					var e: float = bd[3]
					_round(c[0] + cr, fly + co - cr, cr + e, 180.0, 90.0, bd[0], bd[1], bd[2])
					_round(c[1] - cr, fly + co - cr, cr + e, 90.0, 0.0, bd[0], bd[1], bd[2])
					box(c[0] - e, bd[0], -0.3, cr + e, bd[1] - bd[0], fly + co - cr + 0.3, bd[2])      # (the wall's thickness behind each round)
					box(c[1] - cr, bd[0], -0.3, cr + e, bd[1] - bd[0], fly + co - cr + 0.3, bd[2])
			if co > 0.0 and i == n - 1:              # ...its top under the eaves: a little roof of its own
				box(c[0] - 0.05, y + h - 0.02, fly, c[1] - c[0] + 0.1, 0.1, co + 0.14, 0xb0603e)
		if i > 0 and fly > prev_fly + 0.05:                   # this floor comes out over the one below: what you see of it from underneath
			box(0.0, y - 0.2, prev_fly, L, 0.2, fly - prev_fly, _mat(spec.get("trim", 0xe9dcc0)))
		if f.has("band"):
			box(0.0, y - 0.07, fly, L, 0.14, 0.04, _mat(f["band"]))
		if not side:
			for pt in f.get("patches", []):          # a window walled up, a mended stretch: laid on the face of the wall
				var px0: float = float(pt[0]) * L - float(pt[1]) / 2.0
				box(px0, y + float(pt[2]), fly - 0.01, pt[1], pt[3], 0.025, _mat(pt[4]))
				if pt.size() > 5 and pt[5] == "chapa" and pt[4] is int:      # (k=chapa: corrugated sheet, its ribs)
					for k in range(1, int(float(pt[1]) / 0.19) + 1):
						box(px0 + k * 0.19 - 0.025, y + float(pt[2]), fly + 0.015, 0.06, pt[3], 0.03, _dark(int(pt[4]), 0.32))
		for it in items:
			if it[0] == "arc":
				it[2]["_wall"] = key                 # (an arched bay fills its round top back with the floor's own wall)
			var oface := fly
			for c in cuts:                           # (an opening in a body that stands out is set in its face)
				if float(c[4]) > 0.0 and (it[1] as Rect2).get_center().x > float(c[0]) and (it[1] as Rect2).get_center().x < float(c[1]):
					oface = fly + float(c[4])
			_opening(it[0], it[1], it[2], oface, y)
		# what hangs on the wall: the front's own, or on the long side to another street what its "lado" lines say
		var deco: Dictionary = f if not side else ((spec["flank"][i] as Dictionary) if _flank and spec.has("flank") and i < (spec["flank"] as Array).size() else {})
		if not deco.is_empty():
			for sg in deco.get("signs", []):         # the board over a shop, and what it says on it
				var sx0: float = float(sg[0]) * L
				var sw: float = (float(sg[1]) - float(sg[0])) * L
				box(sx0, y + 2.66, fly, sw, 0.46, 0.07, int(sg[2]))
				var word := Label3D.new()
				word.text = String(sg[3])
				word.font_size = 64
				word.pixel_size = minf(0.0052, sw * 0.86 / maxf(1.0, String(sg[3]).length() * 40.0))
				word.modulate = Parts.col(int(sg[4]))
				word.outline_size = 0
				word.transform = _xf * Transform3D(Basis.IDENTITY, Vector3(sx0 + sw / 2.0, y + 2.89, fly + 0.075))      # (_xf: the long side's frame)
				add_child(word)
			for aw in deco.get("awnings", []):          # an awning let down over a shop window
				var ax0: float = float(aw[0]) * L
				var aww: float = (float(aw[1]) - float(aw[0])) * L
				for k in range(5):                    # (it slopes: five strips, each a little lower and further out)
					box(ax0, y + 2.56 - k * 0.07, fly + k * 0.19, aww, 0.04, 0.2, int(aw[2]))
				box(ax0, y + 2.1, fly + 0.93, aww, 0.2, 0.025, _dark(int(aw[2]), 0.12))
			for gl in deco.get("galleries", []):        # a glazed gallery (a mirador): thin frames, pale glass, curtains, a little roof
				_gallery(float(gl[0]) * L, float(gl[1]) * L, float(gl[2]), int(gl[3]), y, h, fly)
			for tg in deco.get("tags", []):          # where the photo shows graffiti: the wall is handed to props.gd for a peña's tag
				if not side and W != null and "hand_tags" in W:
					W.hand_tags.append([spot(float(tg[0]) * L, fly), out, float(tg[1]), base + y])
			for tj in deco.get("tejas", []):            # a tejadillo: a strip of tiled roof leaning out over the doors
				var tx0: float = float(tj[0]) * L
				var tx1: float = float(tj[1]) * L
				var td: float = tj[2]
				var ty: float = y + (float(tj[3]) if float(tj[3]) > 0.0 else h - 0.2)
				var drop := td * 0.42
				quad(Vector3(tx0, ty - drop, fly + td), Vector3(tx1, ty - drop, fly + td), Vector3(tx1, ty, fly), Vector3(tx0, ty, fly), "tiles", Vector3(0, 1, 0.42),
					[Vector2(tx0 / 1.6, td / 1.6), Vector2(tx1 / 1.6, td / 1.6), Vector2(tx1 / 1.6, 0), Vector2(tx0 / 1.6, 0)])
				box(tx0, ty - drop - 0.1, fly + td - 0.06, tx1 - tx0, 0.1, 0.08, 0x9c5236)       # the row of tile ends along its edge
				box(tx0, ty - drop - 0.04, fly, tx1 - tx0, 0.03, td - 0.04, 0x8a4a32)             # its underside, seen from the pavement
			for es in deco.get("stairs", []):          # an outside stair, from this floor up to the one above
				_stair(float(es[0]) * L, float(es[1]) * L, y, h, fly, float(es[2]), int(es[3]), key)
		if not side or _flank:
			for nt in f.get("plates", []):           # the notices people put up: for sale, a garage way, no parking
				if (nt.size() > 6 and int(nt[6]) == 1) == side:     # (lado=1: on the long side to another street, not on the front)
					_plate(float(nt[0]) * L, y + float(nt[1]), fly + float(nt[3]), String(nt[2]), int(nt[4]) if nt.size() > 4 else -1, int(nt[5]) if nt.size() > 5 else 0)
		var own: Dictionary = f if not side else ((spec["flank"][i] as Dictionary) if _flank and spec.has("flank") and i < (spec["flank"] as Array).size() else {})
		if own.has("terrace"):                   # (a long balcony: the front's, or the long side's own as the photos show it)
			var tr: Array = own["terrace"]
			var tx: float = float(tr[0]) * L
			var tw: float = (float(tr[1]) - float(tr[0])) * L
			var td: float = tr[2]
			box(tx, y - 0.2, fly, tw, 0.12, td, 0xe9e4d8)
			balcony(tx + tw / 2.0, y + 0.02, tw, fly, td, int(tr[4]) if tr.size() > 4 else 0x24221f)
			if int(tr[3]) >= 0:
				box(tx, y + 2.3, fly, tw, 0.05, td + 0.25, int(tr[3]))
				box(tx, y + 2.1, fly + td + 0.22, tw, 0.2, 0.03, _dark(int(tr[3]), 0.12))
		y += h
		prev_fly = fly
	return prev_fly

## A notice on the front, its middle at (x, y) and `z` out from the wall, in the frame of the front being built.
## The words are generic: no real licence, and where the telephone number goes, a scribble (the user, 14 November 2026).
func _plate(x: float, y: float, z: float, kind: String, colour := -1, style := 0) -> void:
	var n := Node3D.new()
	n.transform = _xf * Transform3D(Basis(), Vector3(x, y, z))
	add_child(n)
	var words := "SE VENDE" if kind != "sealquila" else "SE ALQUILA"
	match kind:
		"sevende", "sealquila":
			if style == 1:                   # an agency's board: white, the words big in its colour (black, blue...)
				var ink: int = colour if colour >= 0 else 0x1c1c1e
				n.add_child(Parts.part("box", 0xf6f5f0, Vector3(0, 0, 0), Vector3(0.7, 0.48, 0.012)))
				n.add_child(Parts.part("box", ink, Vector3(0, 0.205, 0.008), Vector3(0.7, 0.05, 0.004)))
				_words(n, words, Vector3(0, 0.05, 0.009), 64, ink, 0.0023 if kind == "sevende" else 0.002, 0.62)
				_scribble(x, y - 0.14, z + 0.009, 0.5, 0.08, ink, absi(hash(id)) + int(x * 100.0))
			else:                            # a printed board: a band with the words in white, white below for the phone
				var band: int = colour if colour >= 0 else (0xc8202a if kind == "sevende" else 0x1f55c4)
				n.add_child(Parts.part("box", 0xf4f2ec, Vector3(0, 0, 0), Vector3(0.66, 0.44, 0.012)))
				n.add_child(Parts.part("box", band, Vector3(0, 0.09, 0.008), Vector3(0.62, 0.2, 0.004)))
				_words(n, words, Vector3(0, 0.09, 0.012), 64, 0xffffff, 0.0021 if kind == "sevende" else 0.0019, 0.56)
				_words(n, "TEL.", Vector3(-0.2, -0.11, 0.009), 40, 0x1c1c1e, 0.0018, 0.2)
				_scribble(x + 0.07, y - 0.11, z + 0.009, 0.4, 0.065, 0x1c1c1e, absi(hash(id)) + int(x * 100.0))
			for sx in [-0.28, 0.28]:         # the wire it hangs by
				n.add_child(Parts.part("box", 0x6a6a6a, Vector3(sx, 0.26, -0.02), Vector3(0.006, 0.08, 0.006)))
		"vado":                              # the town's plate, as they are here: the council over the disc, the yellow licence band
			n.add_child(Parts.part("box", 0xf4f4f0, Vector3(0, 0, 0), Vector3(0.32, 0.5, 0.012)))
			n.add_child(Parts.part("box", 0x3a3c40, Vector3(0, 0, -0.003), Vector3(0.335, 0.515, 0.008)))
			_words(n, "AYUNTAMIENTO", Vector3(0, 0.205, 0.008), 32, 0x1c1c1e, 0.0011, 0.28)
			for layer in [[0xc8202a, 0.12, 0.008], [0x1f55c4, 0.094, 0.011]]:
				var disc := Parts.part("cyl", layer[0], Vector3(0, 0.05, layer[2]), Vector3(layer[1], 0.004, layer[1]))
				disc.rotation.x = PI / 2.0
				n.add_child(disc)
			var bar := Parts.part("box", 0xc8202a, Vector3(0, 0.05, 0.014), Vector3(0.22, 0.028, 0.003))
			bar.rotation.z = -PI / 4.0
			n.add_child(bar)
			n.add_child(Parts.part("box", 0xf4f4f0, Vector3(0, 0.05, 0.017), Vector3(0.21, 0.045, 0.002)))
			_words(n, "VADO PERMANENTE", Vector3(0, 0.05, 0.019), 28, 0xa81c24, 0.00095, 0.19)
			n.add_child(Parts.part("box", 0xf0c419, Vector3(0, -0.17, 0.008), Vector3(0.3, 0.12, 0.003)))
			_words(n, "LICENCIA MUNICIPAL", Vector3(0, -0.14, 0.011), 28, 0x1c1c1e, 0.00095, 0.27)
			_words(n, "Nº %d" % (100 + absi(hash(id)) % 800), Vector3(0, -0.19, 0.011), 36, 0x1c1c1e, 0.0014, 0.27)
		"noaparcar":                         # painted on a yellow board by whoever owns the gate
			n.add_child(Parts.part("box", 0xf0c419, Vector3(0, 0, 0), Vector3(0.6, 0.42, 0.012)))
			_words(n, "NO APARCAR", Vector3(0, 0.1, 0.008), 64, 0xc8202a, 0.0021, 0.54)
			_words(n, "SALIDA DE
VEHÍCULOS", Vector3(0, -0.1, 0.008), 40, 0x1c1c1e, 0.0018, 0.54)
		"papel":                             # a sheet of paper taped on, written with a marker, a little askew
			n.rotation.z = 0.05
			n.add_child(Parts.part("box", 0xf2f0e8, Vector3(0, 0, 0), Vector3(0.3, 0.21, 0.004)))
			_words(n, "NO APARCAR", Vector3(0, 0.035, 0.004), 48, 0x22305a, 0.001, 0.27)
			_words(n, "SALIDA DE COCHES", Vector3(0, -0.04, 0.004), 32, 0x22305a, 0.00085, 0.27)
			for c in [Vector2(-0.14, 0.095), Vector2(0.14, 0.095), Vector2(-0.14, -0.095), Vector2(0.14, -0.095)]:
				n.add_child(Parts.part("box", 0xd9d6c8, Vector3(c.x, c.y, 0.003), Vector3(0.045, 0.02, 0.002)))

## where a telephone number would be, a hurried scribble: a figure, then two groups of three, each a line that goes up
## and down, `w` wide and `h` high round (x, y) in the frame of the front being built, `z` out
func _scribble(x: float, y: float, z: float, w: float, h: float, ink: int, seed_: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var gap := w * 0.06
	var x0 := x - w / 2.0
	for g in [0.12, 0.44, 0.44]:
		var gw: float = (w - gap * 2.0) * g
		var n := maxi(3, int(round(gw / 0.02)))
		var prev := Vector2(x0, y + rng.randf_range(-h, h) * 0.5)
		for i in range(1, n + 1):
			var q := Vector2(x0 + gw * i / n, y + rng.randf_range(0.2, 1.0) * h * 0.5 * (1.0 if i % 2 == 0 else -1.0))
			_bar(prev, q, z, 0.008, ink)
			prev = q
		x0 += gw + gap

## words on a notice, their middle at `at`, `size` metres to a pixel of a `px` font; smaller if need be, so that they
## are no wider than `fit` (the board they are written on)
func _words(on: Node3D, text: String, at: Vector3, px: int, hex: int, size: float, fit: float) -> void:
	var wide: float = ThemeDB.fallback_font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, px).x
	var l := Label3D.new()
	l.text = text
	l.font_size = px
	l.pixel_size = minf(size, fit / maxf(1.0, wide))
	l.modulate = Parts.col(hex)
	l.outline_size = 0
	l.shaded = false
	l.double_sided = false
	l.position = at
	on.add_child(l)

## the edge of the roof over a front `L` long whose top floor stands `zf` out: returns how far out the roof's edge is
func _eaves(L: float, zf: float, kind: String) -> float:
	match kind:
		"brackets":
			for i in range(int(L / 0.56) + 1):
				box(0.12 + i * 0.56, top, zf, 0.09, 0.17, 0.62, 0x5a3a22)
			box(-0.15, top + 0.17, zf - 0.1, L + 0.3, 0.05, 0.8, 0x9c5a3e)
			box(-0.18, top + 0.2, zf + 0.64, L + 0.36, 0.09, 0.08, 0xb0603e)
			return zf + 0.7
		"cornice":
			box(0.0, top - 0.24, zf, L, 0.24, 0.1, 0xf4f0e6)
			box(-0.05, top - 0.09, zf, L + 0.1, 0.15, 0.24, 0xf4f0e6)
			box(-0.08, top + 0.06, zf + 0.2, L + 0.16, 0.09, 0.08, 0xb0603e)
			return zf + 0.28
		"flat":
			box(-0.03, top - 0.02, zf - 0.28, L + 0.06, 0.1, 0.34, 0xd9d4c8)       # the coping of its parapet
			return zf
		"dientes":                               # a toothed course of brick under the tiles: bricks set out one by one, a band over them
			for i in range(int((L - 0.1) / 0.24) + 1):
				box(0.05 + i * 0.24, top - 0.24, zf, 0.12, 0.12, 0.1, "brick_red")
			box(-0.05, top - 0.12, zf, L + 0.1, 0.12, 0.16, "brick_red")
			box(-0.1, top, zf + 0.1, L + 0.2, 0.1, 0.14, 0xb0603e)
			return zf + 0.24
	box(-0.08, top - 0.05, zf, L + 0.16, 0.11, 0.2, 0xc9a07a)                     # a course of tiles on edge under the first row
	box(-0.1, top + 0.06, zf + 0.18, L + 0.2, 0.09, 0.1, 0xb0603e)
	return zf + 0.3

func _roof_y(z: float) -> float:
	if _flat_roof:
		return top - 0.3
	if z >= _rz:
		return _ey + (_ez - z) * SLOPE
	return maxf(top + 0.12, _ey + (_ez - _rz) * SLOPE - (_rz - z) * SLOPE)

func _on_front(p: Vector2, tol: float) -> bool:
	return absf(p.y) < tol and p.x > -0.6 and p.x < length + 0.6

## A piece of the plot's edges. One that runs along the line of the front but on past its ends is cut down to what lies
## beyond them: the stretch in front of the front is the front, and drawn a second time as a wall of its own it walls
## up the doors and windows (the plot is often a little wider than the front taken for it). The pieces left are marked
## (a fifth value), so that one that ends within a hand's breadth of the front is still drawn.
func _edges(pc: Dictionary, tol: float) -> Array:
	var res: Array = []
	for e in pc["edges"]:
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		if absf(a.y) < tol and absf(b.y) < tol and absf(b.x - a.x) > 0.05 and maxf(a.x, b.x) > 0.3 and minf(a.x, b.x) < length - 0.3 \
				and (minf(a.x, b.x) < -0.05 or maxf(a.x, b.x) > length + 0.05):
			for lim in [0.0, length]:
				var out_a: bool = a.x < lim if lim == 0.0 else a.x > lim
				var out_b: bool = b.x < lim if lim == 0.0 else b.x > lim
				if out_a == out_b:
					continue
				var m: Vector2 = a.lerp(b, (lim - a.x) / (b.x - a.x))
				var piece: Array = [a, m] if out_a else [m, b]
				if (piece[0] as Vector2).distance_to(piece[1]) > 0.1:
					res.append([piece[0], piece[1], e[2], e[3], true])
			continue
		res.append(e)
	return res

## a plain wall along the plot's edge from a to b, a hand's breadth inside it, from y0 up to the roof
func _plain(a: Vector2, b: Vector2, nrm: Vector2, y0: float, key, cap := 1e9) -> void:
	var pts: Array = [a]
	if (a.y - _rz) * (b.y - _rz) < 0.0:
		pts.append(a.lerp(b, (a.y - _rz) / (a.y - b.y)))
	pts.append(b)
	var n3 := Vector3(nrm.x, 0.0, nrm.y)
	for i in range(pts.size() - 1):
		var p: Vector2 = pts[i] - nrm * 0.05
		var q: Vector2 = pts[i + 1] - nrm * 0.05
		var py: float = minf(cap, _roof_y(pts[i].y) - 0.04)
		var qy: float = minf(cap, _roof_y(pts[i + 1].y) - 0.04)
		if maxf(py, qy) <= y0 + 0.02:
			continue
		quad(Vector3(p.x, y0, p.y), Vector3(q.x, y0, q.y), Vector3(q.x, maxf(qy, y0), q.y), Vector3(p.x, maxf(py, y0), p.y), key, n3)

## a piece of the ground floor that stands `z` in front of the front, from x0 to x1: the front's own openings there
func _step(x0: float, x1: float, z: float, gh: float, spec: Dictionary) -> void:
	var f: Dictionary = spec["floors"][0]
	var holes: Array = []
	var items: Array = []
	for op in f.get("open", []):
		var kind: String = op[0]
		var w: float = op[2]
		var xc: float = float(op[1]) * length
		if xc - w / 2.0 < x0 + 0.15 or xc + w / 2.0 > x1 - 0.15:
			continue
		var o: Dictionary = op[-1] if op[-1] is Dictionary else {}
		var r := Rect2()
		match kind:
			"win":
				r = Rect2(xc - w / 2.0, float(op[3]), w, float(op[4]))
			"bal":
				r = Rect2(xc - w / 2.0, 0.04, w, float(op[3]))
			"shop":
				r = Rect2(xc - w / 2.0, 0.45, w, float(op[3]) - 0.45)
			_:
				r = Rect2(xc - w / 2.0, -0.6, w, float(op[3]) + 0.6)
		holes.append(r)
		items.append([kind, r, o])
	var key = _mat(f.get("wall", spec.get("wall", 0xf2efe6)))
	var pl = f.get("plinth", null)
	if pl != null:
		wall(x0, x1, -1.4, float(pl[0]), z + 0.035, 0.335, holes, _mat(pl[1]))
		wall(x0, x1, float(pl[0]), gh, z, 0.3, holes, key)
	else:
		wall(x0, x1, -1.4, gh, z, 0.3, holes, key)
	for it in items:
		_opening(it[0], it[1], it[2], z, 0.0)
	box(x0 - 0.05, gh - 0.02, -0.05, x1 - x0 + 0.1, 0.16, z + 0.15, 0xd9d2c2)          # its flat top: the floor of the terrace above

## The pavement in front of a front `L` long (in the frame that is set): slabs from the foot of the wall out to the
## edge of the road, however far that is (the town's own pavements are a strip of fixed width along each street, and
## a wide street leaves bare earth between it and the houses), lying on the ground as it rises and falls, and a line
## of kerb stones where it meets the road.
func _acera(L: float) -> void:
	if not _mats.has("acera"):
		if slow:
			var old_st := SurfaceTool.new()
			old_st.begin(Mesh.PRIMITIVE_TRIANGLES)
			_tools["acera"] = old_st
		else:
			_tools["acera"] = Acc.new()
		_mats["acera"] = W._tmat(0xdcd5c8, "pavement", 2.0)
	var n := maxi(1, int(ceil(L / 2.0)))
	var xs: Array = []
	var deep: Array = []
	for i in range(n + 1):
		var x := L * i / n
		var at := _on_map(x, 0.3)
		var d: float = MapData.road_edge_dist(at) + 0.3
		if _in_old_bed(at):                 # (the bed the old bridge crosses, and its raised pavements, are puente.gd's to pave)
			d = 0.0
		xs.append(x)
		deep.append(d if d > 0.5 and d < 11.0 else 0.0)
	for i in range(n):
		if deep[i] <= 0.0 or deep[i + 1] <= 0.0:
			continue
		var a := _ground(xs[i], -0.02, 0.03)
		var b := _ground(xs[i + 1], -0.02, 0.03)
		var c := _ground(xs[i + 1], deep[i + 1] - 0.2, 0.03)
		var d2 := _ground(xs[i], deep[i] - 0.2, 0.03)
		quad(a, b, c, d2, "acera", Vector3.UP)
		quad(_ground(xs[i], deep[i] - 0.2, 0.05), _ground(xs[i + 1], deep[i + 1] - 0.2, 0.05), _ground(xs[i + 1], deep[i + 1] + 0.02, 0.05), _ground(xs[i], deep[i] + 0.02, 0.05), 0xb9b4a8, Vector3.UP)       # the kerb
		pavement += 1

## whether a spot is in the stretch of the Arroyuelo Medio that is still the bed of the stream, wall to wall (puente.gd)
func _in_old_bed(at: Vector2) -> bool:
	var pu: Dictionary = MapData.puente
	if pu.is_empty():
		return false
	var along := Vector2(pu["u"][0], pu["u"][1])
	var rel: Vector2 = at - Vector2(pu["o"][0], pu["o"][1])
	return absf(rel.dot(Vector2(along.y, -along.x))) < 8.0 and rel.dot(along) > -45.0 and rel.dot(along) < 8.0

## where a point of the frame that is set is on the map
func _on_map(x: float, z: float) -> Vector2:
	var q: Vector3 = _xf * Vector3(x, 0.0, z)
	return spot(q.x, q.z)

## a point of the frame that is set, on the ground there (`lift` above it)
func _ground(x: float, z: float, lift: float) -> Vector3:
	var q: Vector3 = _xf * Vector3(x, 0.0, z)          # (a frame only turns about the upright: heights are the same in it)
	return Vector3(x, MapData.height(spot(q.x, q.z)) - base + lift, z)

func _from_spec(spec: Dictionary) -> void:
	var L := length
	var eaves := String(spec.get("eaves", "tiles"))
	_flat_roof = eaves == "flat"
	var zf := _facade(L, spec)
	_acera(L)
	_ez = _eaves(L, zf, eaves)
	_ey = top + 0.26
	var tol: float = spec.get("tol", 0.6)
	var floors: Array = spec["floors"]
	var side_key = _mat(spec.get("side", floors[-1].get("wall", spec.get("wall", 0xf2efe6))))
	var flank := 0.0                                          # the longest wall that gives on to another street
	for pc in pieces:
		for e in _edges(pc, tol):
			var a: Vector2 = e[0]
			var b: Vector2 = e[1]
			if (_on_front(a, tol) and _on_front(b, tol)) or e[2] or not e[3]:
				continue
			if minf(a.y, b.y) > -0.05 and maxf(a.y, b.y) > 0.3 and maxf(a.x, b.x) < L + 0.6 and minf(a.x, b.x) > -0.6:
				continue
			var ln0 := a.distance_to(b)
			var off := maxf(absf(a.y), absf(b.y))
			if absf(b.x - a.x) > 0.9 * ln0 and (off < 1.6 or (off < 2.0 and minf(a.x, b.x) > -1.0 and maxf(a.x, b.x) < L + 1.0)):
				continue                             # (just in front of or behind the front and along it: the front set out or in, not a side)
			flank = maxf(flank, ln0)
	for pc in pieces:
		var ring: PackedVector2Array = pc["ring"]
		var zmin := 0.0
		for q in ring:
			zmin = minf(zmin, q.y)
		_rz = maxf(zmin / 2.0, -6.5)
		# --- the walls that are not the front ---
		for e in _edges(pc, tol):
			var a: Vector2 = e[0]
			var b: Vector2 = e[1]
			if e.size() < 5 and _on_front(a, tol) and _on_front(b, tol):
				continue
			var ln := a.distance_to(b)
			var d := (b - a) / ln
			var nrm := Vector2(d.y, -d.x)                     # outwards (the outline runs counter-clockwise)
			var gh: float = top if floors.size() == 1 else float(floors[0].get("h", 3.0))
			if minf(a.y, b.y) > -0.05 and maxf(a.y, b.y) > 0.3 and maxf(a.x, b.x) < L + 0.6 and minf(a.x, b.x) > -0.6:
				# The ground floor steps out here in front of the line of the front (a low piece with the terrace on top
				# of it). Along the street it carries the openings the front has at that place; its ends are plain.
				if absf(d.x) > 0.97 and not e[2]:
					_step(minf(a.x, b.x), maxf(a.x, b.x), (a.y + b.y) / 2.0, gh, spec)
				elif not e[2]:
					_plain(a, b, nrm, -1.4, _mat(floors[0].get("wall", spec.get("wall", 0xf2efe6))), gh)
				continue
			if e[2]:                                          # a neighbour as tall stands against it: only what shows above
				_plain(a, b, nrm, top - 0.02, side_key)
			elif e[3] and ln >= 3.0:                          # it gives on to another street: a front of its own
				_xf = Transform3D(Basis(Vector3(-d.x, 0.0, -d.y), Vector3.UP, Vector3(nrm.x, 0.0, nrm.y)), Vector3(b.x, 0.0, b.y))
				_flank = ln >= flank - 0.001
				_facade(ln, spec, true)
				_flank = false
				_acera(ln)
				if not _flat_roof:
					box(-0.05, top - 0.05, 0.0, ln + 0.1, 0.11, 0.14, 0xc9a07a)
				_xf = Transform3D.IDENTITY
				_plain(a, b, nrm, top - 0.02, side_key)
			else:
				_plain(a, b, nrm, -1.4, side_key)
		# --- the roof over this piece of the plot ---
		if _flat_roof:
			var idx := Geometry2D.triangulate_polygon(ring)
			for t in range(0, idx.size(), 3):
				var p0: Vector2 = ring[idx[t]]; var p1: Vector2 = ring[idx[t + 1]]; var p2: Vector2 = ring[idx[t + 2]]
				tri(Vector3(p0.x, top - 0.3, p0.y), Vector3(p1.x, top - 0.3, p1.y), Vector3(p2.x, top - 0.3, p2.y), 0x9a9ea2, Vector3.UP)
			continue
		var big := 500.0
		for band in [[_rz, 0.02], [-big, _rz]]:              # (not over what steps out in front of the front: that has its own flat top)
			var clip := PackedVector2Array([Vector2(-big, band[0]), Vector2(big, band[0]), Vector2(big, band[1]), Vector2(-big, band[1])])
			for poly in Geometry2D.intersect_polygons(ring, clip):
				var idx2 := Geometry2D.triangulate_polygon(poly)
				for t in range(0, idx2.size(), 3):
					var v: Array = []
					var uv: Array = []
					for k in range(3):
						var q2: Vector2 = poly[idx2[t + k]]
						v.append(Vector3(q2.x, _roof_y(q2.y), q2.y))
						uv.append(Vector2(q2.x, absf(q2.y - _rz)) / 1.6)
					tri(v[0], v[1], v[2], "tiles", Vector3(0.0, 1.0, 0.0), uv)
	if not _flat_roof:                                        # ...and out over the front wall to the edge of the eaves
		var y_wall := _ey + (_ez + 0.1) * SLOPE
		var run := (_ez + 0.1) / 1.6
		quad(Vector3(-0.12, _ey, _ez), Vector3(L + 0.12, _ey, _ez), Vector3(L + 0.12, y_wall, -0.1), Vector3(-0.12, y_wall, -0.1), "tiles", Vector3(0.0, 1.0, 0.2),
			[Vector2(-0.12 / 1.6, run), Vector2((L + 0.12) / 1.6, run), Vector2((L + 0.12) / 1.6, 0.0), Vector2(-0.12 / 1.6, 0.0)])
	else:                                                     # a flat roof: its parapet along the front
		box(0.0, top - 0.3, zf - 0.25, L, 0.3, 0.25, side_key)

# The houses of Calle de Alemania, each from Catastro's record and its photo of the front (tools/casas/<reference>/).
# Where Catastro's photo shows the house's other street (it stands on a corner, or backs on to this one), the front
# on Calle de Alemania keeps the photo's materials and the openings are the ones it has on this side.
## The house you inherit, Calle de Alemania 5: old, low, the lime coming away from the adobe, a corral gate beside the
## door, and a roof that is there in places. (Catastro has the plot as bare ground: this one is made up.)
## One of the twenty-four terraced houses of 2009 (Calle de los Segadores, Calle de los Labradores), from Catastro's
## photos and parts. Its front is the whole width of its plot, on the line of the garage door. On one side (`side`:
## "L" or "R" as you face it) the garage stands forward to the pavement, a terrace with a white rail on top of it;
## beside it the house stands 4 m back behind a little garden and its low wall and white railing, a tiled porch over
## the door; two floors of ochre render, white blinds, a white grille on the ground-floor window; a tiled roof.
func _adosado(side: String) -> void:
	var W: float = length
	var H: float = top
	var wall_k := "r%d" % 0xe4b25a
	var gar_k := "r%d" % 0xd39a40
	var foot_k := "r%d" % 0xc48f62
	var white := 0xf4f2ec
	var gw := 3.25
	var left: bool = side == "L"
	var gx: float = 0.0 if left else W - gw             # the garage
	var hx0: float = gw if left else 0.0                # the stretch of the house that shows beside it
	var hx1: float = W if left else W - gw
	var F := -4.15                                      # the house's own front
	var back := -14.4
	var gh := 2.95                                      # the garage, and the floor of the terrace
	var f1 := 3.0
	# --- the house: ground floor behind the garden, the upper floor right across ---
	var door_x: float = (hx0 + 0.35) if left else (hx1 - 1.3)
	var win_x: float = (hx0 + 2.3) if left else (hx0 + 0.9)
	wall(hx0, hx1, -1.4, f1, F, 0.25, [Rect2(door_x, 0.0, 0.95, 2.1), Rect2(win_x, 1.0, 1.5, 1.15)], wall_k)
	panel_door(door_x, 0.0, 0.95, 2.1, F, 0x6a4a2e)
	window(win_x, 1.0, 1.5, 1.15, F, 0.55, white, white)
	grille(win_x, 1.0, 1.5, 1.15, F)
	box(hx0, 0.0, F, hx1 - hx0, 0.45, 0.03, foot_k)
	var up_a: float = hx0 + (hx1 - hx0) * 0.24 - 0.6
	var up_b: float = hx0 + (hx1 - hx0) * 0.74 - 0.6
	var tdoor: float = gx + gw / 2.0 - 0.45
	wall(0.0, W, f1, H, F, 0.25, [Rect2(up_a, f1 + 1.0, 1.2, 1.1), Rect2(up_b, f1 + 1.0, 1.2, 1.1), Rect2(tdoor, f1 + 0.05, 0.9, 2.05)], wall_k)
	window(up_a, f1 + 1.0, 1.2, 1.1, F, 0.7, white, white)
	window(up_b, f1 + 1.0, 1.2, 1.1, F, 0.35, white, white)
	window(tdoor, f1 + 0.05, 0.9, 2.05, F, 0.25, white, white)
	# where one house ends and the next begins: a dark line down the front, and down the garage's outer corner
	for x in [-0.02, W - 0.02]:
		box(x, -1.4, F, 0.04, H + 1.4, 0.02, 0x2a2420)
	box((-0.02) if left else (W - 0.02), -1.4, 0.0, 0.04, gh + 1.7, 0.02, 0x2a2420)
	# its ends and its back, with their gables; the roof, its ridge along the street
	var ridge_z: float = (F + back) / 2.0
	var ridge_y: float = H + 1.45
	for x in [0.0, W]:
		var n := Vector3(-1.0 if x == 0.0 else 1.0, 0, 0)
		quad(Vector3(x, -1.4, back), Vector3(x, -1.4, F), Vector3(x, H, F), Vector3(x, H, back), wall_k, n)
		tri(Vector3(x, H, back), Vector3(x, H, F), Vector3(x, ridge_y, ridge_z), wall_k, n)
	quad(Vector3(0, -1.4, back), Vector3(W, -1.4, back), Vector3(W, H, back), Vector3(0, H, back), wall_k, Vector3(0, 0, -1))
	boxes += 3
	var eave := 0.4
	var run: float = (F + eave - ridge_z) / 1.6
	quad(Vector3(0, H - 0.08, F + eave), Vector3(W, H - 0.08, F + eave), Vector3(W, ridge_y, ridge_z), Vector3(0, ridge_y, ridge_z), "tiles", Vector3(0, 1, 0.3),
		[Vector2(0, run), Vector2(W / 1.6, run), Vector2(W / 1.6, 0), Vector2(0, 0)])
	quad(Vector3(0, H - 0.08, back - eave), Vector3(W, H - 0.08, back - eave), Vector3(W, ridge_y, ridge_z), Vector3(0, ridge_y, ridge_z), "tiles", Vector3(0, 1, -0.3),
		[Vector2(0, run), Vector2(W / 1.6, run), Vector2(W / 1.6, 0), Vector2(0, 0)])
	box(0.0, H - 0.16, F, W, 0.1, eave, 0xc9a07a)
	box(W * 0.5 - 0.3, ridge_y - 0.5, ridge_z - 1.6, 0.6, 1.1, 0.6, wall_k)                # the chimney, and its cap
	box(W * 0.5 - 0.36, ridge_y + 0.6, ridge_z - 1.66, 0.72, 0.08, 0.72, 0xb0603e)
	# --- the garage, standing forward to the pavement; its door; the terrace on top, railed in white ---
	wall(gx, gx + gw, -1.4, gh, 0.0, 0.25, [Rect2(gx + 0.33, 0.0, gw - 0.66, 2.3)], gar_k)
	sect_door(gx + 0.33, 0.0, gw - 0.66, 2.3, 0.0, white)
	for x in [gx, gx + gw - 0.22]:
		box(x, -1.4, F, 0.22, gh + 1.4, -F - 0.25, gar_k)
	box(gx, gh - 0.16, F, gw, 0.16, -F, 0xc9c4b8)
	box(gx, gh, -0.24, gw, 0.3, 0.24, gar_k)                                              # a low kerb round the terrace
	rail(gx + gw / 2.0, gh + 0.3, gw - 0.1, -0.3, 0.7, true)
	var open_x: float = (gx + gw - 0.2) if left else gx                                 # its side over the garden: railed too
	box(open_x, gh, F, 0.2, 0.3, -F, gar_k)
	var zz: float = F + 0.3
	while zz < -0.4:
		box(open_x + 0.07, gh + 0.3, zz, 0.06, 0.7, 0.06, 0xe8e4d8)
		zz += 0.17
	box(open_x + 0.06, gh + 0.96, F + 0.25, 0.08, 0.05, -F - 0.45, 0xe8e4d8)
	box((gx + gw + 0.02) if left else (gx - 0.1), 0.0, -0.12, 0.08, gh + 0.2, 0.08, white)       # the rainwater pipe down its corner
	# --- the porch: a strip of tiled roof over the door, from the house out ---
	var py := 2.86
	var pd := 1.75
	quad(Vector3(hx0, py - 0.42, F + pd), Vector3(hx1, py - 0.42, F + pd), Vector3(hx1, py, F), Vector3(hx0, py, F), "tiles", Vector3(0, 1, 0.3),
		[Vector2(hx0 / 1.6, pd / 1.6), Vector2(hx1 / 1.6, pd / 1.6), Vector2(hx1 / 1.6, 0), Vector2(hx0 / 1.6, 0)])
	box(hx0, py - 0.52, F + pd - 0.06, hx1 - hx0, 0.1, 0.08, 0x8a5a3a)
	boxes += 1
	# --- the garden: paved; a low wall and a white railing along the pavement, a gate by the garage, the meter box ---
	box(hx0, -1.4, F, hx1 - hx0, 1.44, -F - 0.2, 0xc99270)             # (a solid floor: the street may fall away under it)
	var gate0: float = hx0 + 0.15 if left else hx1 - 1.15
	var w0: float = (gate0 + 1.0) if left else hx0
	var w1: float = hx1 if left else gate0
	box(hx0, -1.4, -0.22, hx1 - hx0, 1.44, 0.2, foot_k)
	box(w0, 0.0, -0.22, w1 - w0, 0.55, 0.2, foot_k)
	rail((w0 + w1) / 2.0, 0.6, w1 - w0 - 0.7, -0.28, 0.6, true)
	var meter: float = (w1 - 0.62) if left else w0 + 0.05
	box(meter, 0.55, -0.26, 0.56, 0.86, 0.28, white)
	box(meter + 0.06, 0.62, 0.02, 0.44, 0.72, 0.012, 0xdad6cc)
	for gp in [gate0, gate0 + 0.94]:
		box(gp, 0.0, -0.2, 0.06, 1.15, 0.06, 0xe8e4d8)
	for k in range(6):
		box(gate0 + 0.1 + k * 0.15, 0.1, -0.19, 0.04, 1.0, 0.04, 0xe8e4d8)
	box(gate0, 1.06, -0.2, 1.0, 0.05, 0.05, 0xe8e4d8)
	_acera(W)

## One of the ochre terraced houses of 1999-2000 in the Calle de la Rosa de Santa María (Catastro's "CL ROSA"), after
## Catastro's parts, its photos and Street View 2024, built the way the Segadores ones are (_adosado). Its front, `length`
## wide, is the line of its yard's low wall at the pavement. Behind the yard, on one side (p[0]: "L" or "R" as you face
## it) a block of three floors stands forward, its face p[2] in from the wall; on the other side, from the split p[1]
## (from the left end), the house goes back to p[3]: a recess of darker render where a stair climbs to the door. p[4] is
## where the house ends behind. Over a garage half below the street, two floors of ochre with white blinds and white
## balustrades; deep eaves on wooden brackets; one roof with its ridge along the street. In the yard: a paved floor,
## its low terracotta wall with white railing gates, a tiled pergola over the gate to the stair.
func _rosa(p: Array) -> void:
	var W: float = length
	var H: float = top
	var left: bool = String(p[0]) == "L"
	var xs: float = float(p[1])
	var Ff: float = float(p[2])
	var Fr: float = float(p[3])
	var back: float = float(p[4])
	var och := "r%d" % 0xdf9f48
	var ter := "r%d" % 0xc46a3c
	var foot := "r%d" % 0xb05a36
	var white := 0xf4f2ec
	var rail_c := 0xe8e4d8
	var fx0: float = 0.0 if left else xs              # the block that stands forward...
	var fx1: float = xs if left else W
	var rx0: float = xs if left else 0.0              # ...and the recess beside it
	var rx1: float = W if left else xs
	var fw: float = fx1 - fx0
	var rw: float = rx1 - rx0
	var f1 := 2.8
	var f2 := 5.6
	# --- the block that stands forward: the garage half below the street, two floors of windows ---
	var gw: float = clampf(fw - 1.0, 1.6, 2.4)
	var gx: float = fx0 + (fw - gw) / 2.0
	var wa: float = fx0 + fw * 0.27 - 0.5
	var wb: float = fx0 + fw * 0.73 - 0.5
	var holes := [Rect2(gx, 0.0, gw, 2.1), Rect2(wa, f1 + 0.9, 1.0, 1.2), Rect2(wb, f1 + 0.9, 1.0, 1.2), Rect2(wa, f2 + 0.5, 1.0, 1.4), Rect2(wb, f2 + 0.5, 1.0, 1.4)]
	wall(fx0, fx1, -1.4, 0.55, Ff, 0.25, holes, foot)
	wall(fx0, fx1, 0.55, H, Ff, 0.25, holes, och)
	sheet_door(gx, 0.0, gw, 2.1, Ff, 0x6a4a34, 0.3)
	for x in [wa, wb]:
		window(x, f1 + 0.9, 1.0, 1.2, Ff, 0.55, white, white)
		window(x, f2 + 0.5, 1.0, 1.4, Ff, 0.4, white, white)
		rail(x + 0.5, f2 + 0.5, 1.15, Ff, 0.85, true)
	box(fx0, f1 - 0.05, Ff, fw, 0.1, 0.06, foot)                                  # a band of the darker render between the floors
	# --- the recess: darker render, the door up a stair, a window over it, a balustraded one at the top ---
	var dx: float = rx0 + (rw - 0.95) / 2.0
	var mx: float = rx0 + (rw - 0.8) / 2.0
	var tx: float = rx0 + (rw - 1.0) / 2.0
	var holes2 := [Rect2(dx, 1.1, 0.95, 2.1), Rect2(mx, 4.1, 0.8, 1.0), Rect2(tx, f2 + 0.5, 1.0, 1.4)]
	wall(rx0, rx1, -1.4, H, Fr, 0.25, holes2, ter)
	panel_door(dx, 1.1, 0.95, 2.1, Fr, 0x6a4428)
	window(mx, 4.1, 0.8, 1.0, Fr, 0.5, white, white)
	window(tx, f2 + 0.5, 1.0, 1.4, Fr, 0.4, white, white)
	rail(tx + 0.5, f2 + 0.5, 1.15, Fr, 0.85, true)
	for k in range(5):                                                             # the stair up to the door
		box(dx - 0.15, -1.4, Fr, 1.25, 1.4 + 0.22 * (k + 1), 0.32 * (5 - k), 0xc9b4a0)
	box(dx - 0.2, 0.0, Fr, 0.05, 1.95, 1.6, rail_c)                                # its white handrail
	# the side of the forward block, over the recess
	var sn := Vector3(1.0 if left else -1.0, 0, 0)
	quad(Vector3(xs, -1.4, Fr), Vector3(xs, -1.4, Ff), Vector3(xs, H, Ff), Vector3(xs, H, Fr), och, sn)
	# --- its ends against the neighbours, its back, the gables; the roof ---
	var ridge_z: float = minf((Fr + back) / 2.0, Fr - 1.0)
	var ridge_y: float = H + 1.45
	for x in [0.0, W]:
		var n := Vector3(-1.0 if x == 0.0 else 1.0, 0, 0)
		var zf: float = Ff if ((x == 0.0) == left) else Fr
		quad(Vector3(x, -1.4, back), Vector3(x, -1.4, zf), Vector3(x, H, zf), Vector3(x, H, back), och, n)
		tri(Vector3(x, H, back), Vector3(x, H, zf), Vector3(x, ridge_y, ridge_z), och, n)
		box(x - 0.02, -1.4, zf, 0.04, H + 1.4, 0.02, 0x3a2a20)                    # where one house ends and the next begins
	quad(Vector3(0, -1.4, back), Vector3(W, -1.4, back), Vector3(W, H, back), Vector3(0, H, back), och, Vector3(0, 0, -1))
	tri(Vector3(xs, H, Ff), Vector3(xs, H, Fr), Vector3(xs, ridge_y, ridge_z), och, sn)     # (between the two front slopes)
	boxes += 4
	var eave := 0.45
	for part in [[fx0, fx1, Ff], [rx0, rx1, Fr]]:
		var a0: float = part[0]
		var a1: float = part[1]
		var zf: float = part[2]
		var run: float = (zf + eave - ridge_z) / 1.6
		quad(Vector3(a0, H - 0.08, zf + eave), Vector3(a1, H - 0.08, zf + eave), Vector3(a1, ridge_y, ridge_z), Vector3(a0, ridge_y, ridge_z), "tiles", Vector3(0, 1, 0.3),
			[Vector2(a0 / 1.6, run), Vector2(a1 / 1.6, run), Vector2(a1 / 1.6, 0), Vector2(a0 / 1.6, 0)])
		box(a0, H - 0.16, zf, a1 - a0, 0.1, eave, 0xc9a07a)
		var bx: float = a0 + 0.12
		while bx < a1 - 0.15:                                                      # the wooden brackets under the eaves
			box(bx, H - 0.42, zf, 0.09, 0.27, eave - 0.06, 0x6a3422)
			bx += 0.42
	var runb: float = (ridge_z - back + eave) / 1.6
	quad(Vector3(0, H - 0.08, back - eave), Vector3(W, H - 0.08, back - eave), Vector3(W, ridge_y, ridge_z), Vector3(0, ridge_y, ridge_z), "tiles", Vector3(0, 1, -0.3),
		[Vector2(0, runb), Vector2(W / 1.6, runb), Vector2(W / 1.6, 0), Vector2(0, 0)])
	var cx: float = (fx0 + fx1) / 2.0
	box(cx - 0.3, ridge_y - 0.6, ridge_z - 0.9, 0.6, 1.3, 0.6, ter)                  # the chimney and its cap
	box(cx - 0.36, ridge_y + 0.7, ridge_z - 0.96, 0.72, 0.08, 0.72, 0xb0603e)
	# --- the yard: paved, a low wall to each neighbour, its front wall at the pavement with two white gates ---
	box(fx0, -1.4, Ff, fw, 1.44, -Ff - 0.2, 0xc99270)
	box(rx0, -1.4, Fr, rw, 1.44, -Fr - 0.2, 0xc99270)
	box(0.0, -1.4, Ff if left else Fr, 0.12, 2.5, -(Ff if left else Fr) - 0.2, ter)
	box(W - 0.12, -1.4, Fr if left else Ff, 0.12, 2.5, -(Fr if left else Ff) - 0.2, ter)
	var cg0: float = gx - 0.15                                                     # the car's gate, before the garage...
	var cg1: float = gx + gw + 0.15
	var pg0: float = dx - 0.05                                                     # ...and the one to the stair
	var pg1: float = dx + 1.0
	var gates := [[cg0, cg1], [pg0, pg1]]
	gates.sort_custom(func(u, v): return u[0] < v[0])
	var at := 0.0
	for g in gates + [[W, W]]:
		if g[0] - at > 0.05:
			box(at, -1.4, -0.22, g[0] - at, 2.5, 0.2, ter)
			box(at, 1.1, -0.25, g[0] - at, 0.06, 0.26, 0xd9c8b0)                    # its coping
		at = maxf(at, g[1])
	for g in gates:
		for e in [g[0] - 0.3, g[1]]:                                                # the pillars either side
			box(e, -1.4, -0.26, 0.3, 2.85, 0.28, ter)
		var x: float = g[0] + 0.04
		while x < g[1] - 0.04:
			box(x, 0.02, -0.17, 0.035, 1.3, 0.035, rail_c)
			x += 0.12
		box(g[0], 0.05, -0.18, g[1] - g[0], 0.05, 0.05, rail_c)
		box(g[0], 1.28, -0.18, g[1] - g[0], 0.05, 0.05, rail_c)
	box(pg1 + 0.05, 0.35, -0.27, 0.5, 0.75, 0.12, white)                           # the meter box in the wall
	# --- the pergola over the gate to the stair: white posts, a strip of tiles ---
	var q0: float = pg0 - 0.45
	var q1: float = pg1 + 0.45
	for x in [q0, q1 - 0.12]:
		for z in [-0.28, -2.2]:
			box(x, 0.0, z - 0.12, 0.12, 2.8, 0.12, rail_c)
	for z in [-0.4, -2.32]:                                                       # its two beams, the posts' tops joined
		box(q0, 2.7, z, q1 - q0, 0.12, 0.12, rail_c)
	for k in range(5):                                                             # the rafters under the tiles
		box(q0 + 0.05 + (q1 - q0 - 0.1) * k / 4.0, 2.82, -2.32, 0.06, 0.08, 2.0, rail_c)
	quad(Vector3(q0 - 0.1, 2.82, 0.05), Vector3(q1 + 0.1, 2.82, 0.05), Vector3(q1 + 0.1, 3.12, -2.45), Vector3(q0 - 0.1, 3.12, -2.45), "tiles", Vector3(0, 1, 0.12),
		[Vector2(q0 / 1.6, 1.6), Vector2(q1 / 1.6, 1.6), Vector2(q1 / 1.6, 0), Vector2(q0 / 1.6, 0)])
	boxes += 2
	_acera(W)

## a bar from one point to another (the lattice of a mast), as a node of its own
func _strut(a: Vector3, b: Vector3, thick: float, hex: int) -> void:
	var d := b - a
	if d.length() < 0.01:
		return
	var m := Parts.part("box", hex, (a + b) / 2.0, Vector3(thick, d.length(), thick))
	var up := d.normalized()
	var side := up.cross(Vector3.RIGHT if absf(up.x) < 0.9 else Vector3.FORWARD).normalized()
	m.basis = Basis(side, up, side.cross(up)) * Basis.from_scale(Vector3(thick, d.length(), thick))
	add_child(m)

## The communications tower, between the Calle de la Cruz and the Calle de la Virgen de Gracia, from the user's photos
## of 12 November 2026 (referencias/torre_comunicaciones) and Catastro's parts: a tall blank building of pale brick
## that fills its plot, redder brick below a dark joint, a strip of rusty steel up each corner, a band of glass blocks
## high on its long walls and red louvres low down, a black gate at its east end; on its roof, by the Virgen de Gracia
## side, a square concrete shaft with a platform that overhangs it, and on that a red-and-white lattice mast full of
## aerials and dishes, a red light on its tip.
func _central() -> void:
	_flat_roof = true
	var H: float = top
	var low := 3.3
	var rust := 0x5e2e1c
	var red := 0x8a2a22
	var glass := 0xc3ced0
	for pc in pieces:
		var ring: PackedVector2Array = pc["ring"]
		var n := ring.size()
		var area := 0.0
		for i in range(n):
			area += ring[i].x * ring[(i + 1) % n].y - ring[(i + 1) % n].x * ring[i].y
		var sgn := 1.0 if area > 0.0 else -1.0
		for i in range(n):
			var a: Vector2 = ring[i]
			var b: Vector2 = ring[(i + 1) % n]
			var ln := a.distance_to(b)
			if ln < 0.05:
				continue
			var d := (b - a) / ln
			var nrm := Vector2(d.y, -d.x) * sgn
			var n3 := Vector3(nrm.x, 0, nrm.y)
			var face := func(s0: float, s1: float, y0: float, y1: float, lift: float, key) -> void:
				var p: Vector2 = a + d * s0 + nrm * lift
				var q: Vector2 = a + d * s1 + nrm * lift
				quad(Vector3(p.x, y0, p.y), Vector3(q.x, y0, q.y), Vector3(q.x, y1, q.y), Vector3(p.x, y1, p.y), key, n3)
				boxes += 1
			face.call(0.0, ln, -1.5, low, 0.0, "brick_salmon")
			face.call(0.0, ln, low, H + 0.5, 0.0, "brick_pale")
			face.call(0.0, ln, low - 0.05, low + 0.05, 0.015, 0x4a3a30)
			face.call(0.0, ln, H + 0.42, H + 0.5, 0.02, 0x9a958c)                      # the coping
			var end_wall: bool = absf(nrm.x) > 0.8
			if ln > 9.0 and not end_wall:
				# the band of glass blocks, in its red frame
				var g0: float = ln * 0.06
				var g1: float = ln * 0.94
				face.call(g0, g1, H - 3.3, H - 2.3, 0.02, glass)
				face.call(g0, g1, H - 3.38, H - 3.3, 0.03, red)
				face.call(g0, g1, H - 2.3, H - 2.22, 0.03, red)
				var s: float = g0
				while s < g1 - 0.2:
					face.call(s, s + 0.06, H - 3.3, H - 2.3, 0.03, red if int(round((s - g0) / 1.2)) % 5 == 0 else 0xe6eef0)
					s += 1.2
				# red louvres low down
				var count := int(ln / 8.0)
				for k in range(count):
					var c: float = ln * (k + 0.5) / count
					face.call(c - 1.7, c + 1.7, 1.95, 3.0, 0.02, 0x3a1614)
					var bar: float = c - 1.7
					while bar < c + 1.65:
						face.call(bar, bar + 0.09, 1.95, 3.0, 0.05, red)
						bar += 0.22
					face.call(c - 1.75, c + 1.75, 3.0, 3.07, 0.05, red)
					face.call(c - 1.75, c + 1.75, 1.88, 1.95, 0.05, red)
			elif ln > 7.0 and end_wall and a.x + b.x < length:               # its east end: the black gate, and a vent
				var gc: float = ln * 0.42
				face.call(gc - 1.9, gc + 1.9, 0.0, 3.25, 0.03, 0x1b1b1f)
				var rib: float = gc - 1.85
				while rib < gc + 1.85:
					face.call(rib, rib + 0.05, 0.0, 3.25, 0.045, 0x2c2c32)
					rib += 0.24
				face.call(gc - 2.0, gc + 2.0, 3.25, 3.4, 0.05, 0x8a8478)
				face.call(gc + 3.0, gc + 3.7, 3.7, 4.4, 0.03, 0xb9b4a8)
		# a strip of rusty steel up each outer corner
		for i in range(n):
			var prev: Vector2 = ring[(i + n - 1) % n]
			var here: Vector2 = ring[i]
			var next: Vector2 = ring[(i + 1) % n]
			if prev.distance_to(here) < 6.0 or here.distance_to(next) < 6.0:
				continue
			if (here - prev).cross(next - here) * sgn > 0.0:
				box(here.x - 0.36, -1.5, here.y - 0.36, 0.72, H + 2.2, 0.72, rust)
		# the roof
		var flat := Geometry2D.triangulate_polygon(ring)
		for k in range(0, flat.size(), 3):
			tri(Vector3(ring[flat[k]].x, H, ring[flat[k]].y), Vector3(ring[flat[k + 1]].x, H, ring[flat[k + 1]].y), Vector3(ring[flat[k + 2]].x, H, ring[flat[k + 2]].y), 0x8f8a80, Vector3.UP)
	# what stands on the roof (where Catastro has it): the stair head, the shaft, and its platform
	var concrete := 0xb9b2a4
	box(21.6, H, -13.2, 2.4, 3.4, 6.0, 0xa8a294)
	box(23.8, H, -12.0, 3.2, 8.2, 5.6, concrete)
	var py: float = H + 8.2
	box(22.5, py, -13.3, 5.8, 0.5, 8.2, 0xa39c8e)
	for e in [[22.5, -13.3, 5.8, 0.06], [22.5, -5.16, 5.8, 0.06], [22.5, -13.3, 0.06, 8.2], [28.24, -13.3, 0.06, 8.2]]:
		box(e[0], py + 1.45, e[1], e[2], 0.06, e[3], rust)
		box(e[0], py + 0.95, e[1], e[2], 0.04, e[3], rust)
	for cx in [22.5, 25.4, 28.24]:
		for cz in [-13.3, -9.2, -5.16]:
			if cx != 25.4 or cz != -9.2:
				box(cx, py + 0.5, cz, 0.06, 1.0, 0.06, rust)
	# the mast: four legs that close in as they rise, banded red and white, braced on every face
	var foot := Vector3(25.4, py + 0.5, -9.2)
	var bands := 7
	var rise := 2.7
	var paint: Array = [0xd42a2a, 0xf4f2ea]
	var half := func(k: int) -> float:
		return lerpf(1.9, 0.5, float(k) / bands)
	for k in range(bands):
		var h0: float = half.call(k)
		var h1: float = half.call(k + 1)
		var y0: float = foot.y + k * rise
		var y1: float = y0 + rise
		var col: int = paint[k % 2]
		var corners0: Array = []
		var corners1: Array = []
		for q in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			corners0.append(Vector3(foot.x + q.x * h0, y0, foot.z + q.y * h0))
			corners1.append(Vector3(foot.x + q.x * h1, y1, foot.z + q.y * h1))
		for c in range(4):
			_strut(corners0[c], corners1[c], 0.13, col)
			_strut(corners1[c], corners1[(c + 1) % 4], 0.07, col)
			_strut(corners0[c], corners1[(c + 1) % 4] if k % 2 == 0 else corners0[(c + 1) % 4].lerp(corners1[(c + 1) % 4], 1.0), 0.05, col)
	var tip: float = foot.y + bands * rise
	_strut(Vector3(foot.x, tip, foot.z), Vector3(foot.x, tip + 3.6, foot.z), 0.09, 0xf4f2ea)
	_strut(Vector3(foot.x - 1.1, tip + 1.2, foot.z), Vector3(foot.x + 1.1, tip + 1.2, foot.z), 0.05, 0x9aa0a6)
	_strut(Vector3(foot.x, tip + 2.2, foot.z - 0.8), Vector3(foot.x, tip + 2.2, foot.z + 0.8), 0.05, 0x9aa0a6)
	var lamp := Parts.part("ball", 0xff3a2a, Vector3(foot.x, tip + 3.7, foot.z), Vector3.ONE * 0.14)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1.0, 0.2, 0.15)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.15, 0.1)
	glow.emission_energy_multiplier = 2.5
	lamp.material_override = glow
	add_child(lamp)
	# aerials: white panels standing off the legs at three heights, and a few drums
	for level in [[2, 0.0], [4, 0.6], [5, 0.2], [6, 0.9]]:
		var k: int = level[0]
		var y: float = foot.y + k * rise + 0.9
		var r: float = float(half.call(k)) + 0.45
		for s in range(3):
			var ang: float = float(level[1]) + s * TAU / 3.0
			var at := Vector3(foot.x + sin(ang) * r, y, foot.z + cos(ang) * r)
			var panel := Parts.part("box", 0xf1f1ee, at, Vector3(0.3, 1.7, 0.14))
			panel.rotation.y = ang
			add_child(panel)
			_strut(Vector3(foot.x, y, foot.z), at, 0.04, 0x9aa0a6)
	for drum in [[1, 0.4, 0.62], [3, 2.6, 0.5], [3, 4.4, 0.4], [5, 1.5, 0.34]]:
		var k2: int = drum[0]
		var ang2: float = drum[1]
		var r2: float = float(half.call(k2)) + 0.5
		var at2 := Vector3(foot.x + sin(ang2) * r2, foot.y + k2 * rise + 1.3, foot.z + cos(ang2) * r2)
		var dish := Parts.part("cyl", 0xe9e9e4, at2, Vector3(float(drum[2]), 0.3, float(drum[2])))
		dish.rotation = Vector3(PI / 2.0, ang2, 0)
		add_child(dish)
		_strut(Vector3(foot.x, at2.y, foot.z), at2, 0.05, 0x9aa0a6)
	# on the walls: the lamp over the Virgen de Gracia side, a drainpipe; and the pavement along the front
	box(length * 0.4, 6.4, 0.0, 0.06, 0.06, 1.3, 0x8a8f96)
	box(length * 0.4 - 0.12, 6.3, 1.3, 0.3, 0.1, 0.5, 0x9aa0a6)
	_acera(length)

func _alemania_5() -> void:
	_from_spec(SPECS["alemania_5"])
	var L := length
	for patch in [[1.2, 0.5, 1.1, 0.9], [4.3, 1.7, 0.9, 1.2], [5.6, 0.45, 0.8, 0.7]]:      # where the lime has come away: adobe
		box(patch[0], patch[1], 0.0, patch[2], patch[3], 0.012, "brick_orange")
		box(patch[0] + 0.25, patch[1] + patch[3], 0.0, patch[2] * 0.5, 0.2, 0.012, "brick_orange")
	for i in range(3):                                                                   # the window nobody opens: boarded up
		box(3.25, 1.2 + i * 0.36, 0.03, 1.2, 0.2, 0.03, 0x7a6248)
	box(L * 0.3, top + 0.3, -2.6, 1.9, 0.5, 1.6, 0x2a221c)                               # the hole in the roof
	box(L * 0.3 - 0.2, top + 0.5, -2.75, 0.5, 0.06, 0.4, 0xb0603e)                       # a tile or two, slipped
	box(L * 0.3 + 1.5, top + 0.62, -1.3, 0.45, 0.06, 0.35, 0xb0603e)

const W1 := 0xf1eee6            # white blinds and frames
const SPECS := {
	# --- the odd side ---
	"alemania_19": {"eaves": "tiles", "floors": [          # 1970: taupe render; lattices shut over the windows, a curtain at the door; white balustrades upstairs
		{"wall": 0x9a9284, "open": [["win", 0.2, 1.5, 0.8, 1.6, {"g": "lattice"}], ["win", 0.54, 1.3, 0.8, 1.6, {"g": "lattice"}], ["door", 0.86, 1.0, 2.2, {"k": "curtain", "s": 0x8a8274}]]},
		{"wall": 0x9a9284, "open": [["win", 0.3, 1.2, 0.95, 1.25, {"bal": "white", "s": 0x8a8274, "d": 0.85}], ["win", 0.72, 1.2, 0.95, 1.25, {"bal": "white", "s": 0x8a8274, "d": 0.85}]]}]},
	"alemania_17": {"eaves": "tiles", "floors": [          # 1970: on the street, a dark door between its neighbours and a balcony over it
		{"wall": 0xe0b65a, "plinth": [1.0, 0x5a3a30], "open": [["door", 0.5, 1.0, 2.2, {"c": 0x3a2a20}]]},
		{"wall": 0xe0b65a, "open": [["win", 0.5, 1.0, 0.95, 1.25, {"b": 0x8a7a60, "bal": "iron"}]]}]},
	"alemania_15": {"eaves": "tiles", "floors": [          # 1960: yellow over a dark skirting; a wooden door, an iron grille, a doorway behind its curtain
		{"wall": 0xe0b65a, "plinth": [1.0, 0x5a3a30], "open": [["door", 0.14, 1.0, 2.25, {"c": 0x9a6a3a}], ["win", 0.48, 1.3, 0.9, 1.5, {"g": "bars", "f": 0x3a3030}], ["door", 0.82, 1.1, 2.3, {"k": "curtain"}]]},
		{"wall": 0xe0b65a, "open": [["win", 0.3, 1.2, 1.0, 1.2, {"b": 0x8a7a60, "bal": "iron"}], ["win", 0.74, 1.2, 1.0, 1.2, {"b": 0x8a7a60, "bal": "iron"}]]}]},
	"alemania_13": {"eaves": "tiles", "floors": [          # 1960: sand render on a grey skirting; a steel door for the cart, grilles, the curtain in its granite frame
		{"wall": 0xc9a86a, "plinth": [0.9, 0x8a8680], "open": [["gar", 0.12, 2.6, 2.6, {"k": "metal", "c": 0x6a7278, "s": 0x8a8680}], ["win", 0.32, 0.9, 1.0, 1.2, {"g": "bars", "s": 0x8a8680, "f": 0x3a3d40}],
			["door", 0.5, 1.15, 2.3, {"k": "curtain", "s": 0x8a8680}], ["win", 0.68, 0.9, 1.0, 1.2, {"g": "bars", "s": 0x8a8680, "f": 0x3a3d40}], ["door", 0.93, 0.85, 2.1, {"c": 0x8a5a2a}]]},
		{"wall": 0xc9a86a, "open": [["win", 0.27, 1.2, 0.95, 1.2, {"b": 0x8a6a4a, "s": 0x9a958c, "bal": "iron"}], ["win", 0.5, 1.2, 0.95, 1.2, {"b": 0x8a6a4a, "s": 0x9a958c, "bal": "iron"}], ["win", 0.73, 1.2, 0.95, 1.2, {"s": 0x9a958c, "bal": "iron", "d": 0.2}]]}]},
	"alemania_11": {"eaves": "tiles", "tol": 0.9, "trim": 0xcbbd9f, "floors": [          # 2006 (Street View, Nov 2024): cream render; a brick arch round the wooden garage door; the floors above stand out on an apron of brick, dark blue frames
		{"wall": 0xe9dcc0, "plinth": [0.5, 0xcbbd9f], "open": [["gar", 0.3, 2.8, 2.55, {"k": "sect", "c": 0xb98a4a, "s": "brick_red", "sb": 0.3}], ["door", 0.75, 1.1, 2.35, {"c": 0x5a3a22, "s": "brick_red", "sb": 0.3}]]},
		{"wall": 0xe9dcc0, "fly": 0.7, "plinth": [1.05, "brick_red"], "open": [["win", 0.2, 0.6, 1.25, 1.45, {"f": 0x1f2c55, "d": 0.0}], ["win", 0.32, 0.6, 1.25, 1.45, {"f": 0x1f2c55, "d": 0.0}], ["win", 0.68, 1.4, 1.25, 1.45, {"f": 0x1f2c55, "d": 0.5}]]},
		{"wall": 0xe9dcc0, "fly": 0.7, "open": [["win", 0.22, 0.9, 1.0, 1.3, {"f": 0x1f2c55, "d": 0.3}], ["win", 0.62, 1.1, 1.0, 1.3, {"f": 0x1f2c55, "d": 0.0}]]}]},
	"alemania_nave": {"eaves": "tiles", "floors": [        # the shed (Street View, Nov 2024): rough grey render and a grey gate of sheet metal in a pale frame
		{"wall": 0xb3a894, "plinth": [0.4, 0x9a9080], "open": [["gar", 0.55, 3.6, 2.9, {"k": "metal", "c": 0x8a9094, "s": 0xd9d4c8, "sb": 0.2}]]}]},
	"alemania_tapia": {"eaves": "tiles", "floors": [       # 1950 (Street View, Nov 2024): an old house of rough grey-brown render under its tiles, three barred windows (one in a red frame), the gable of a taller part behind
		{"wall": 0xb3a894, "plinth": [0.5, 0x9a9080], "open": [["win", 0.22, 1.0, 1.0, 1.2, {"g": "bars", "f": 0x3a3d40, "d": 0.0}], ["win", 0.36, 1.0, 1.0, 1.2, {"g": "bars", "f": 0x3a3d40, "d": 0.0}],
			["win", 0.68, 0.9, 1.0, 1.3, {"g": "bars", "f": 0x8a3a2a, "d": 0.0}]]},
		{"wall": 0xb3a894}],
		"flank": [                                       # its long side on the Travesía de Alemania (Street View, Nov 2024): a whitewashed house, barred window, curtained door, barred window, small iron balconies above (its spacing beyond the door is a guess: the panoramas there are a few metres off)
			{"wall": 0xe8e4d8, "plinth": [0.5, 0xa8a49a], "open": [["win", 0.12, 1.2, 1.0, 1.2, {"g": "bars", "s": 0xb8a890, "sb": 0.15}], ["door", 0.40, 1.2, 2.3, {"k": "curtain", "c": 0xb87a6a, "s": 0xb8a890, "sb": 0.15}], ["win", 0.70, 1.2, 1.0, 1.2, {"g": "bars", "s": 0xb8a890, "sb": 0.15}]]},
			{"wall": 0xe8e4d8, "open": [["win", 0.12, 0.9, 0.9, 1.1, {"bal": "iron", "s": 0xb8a890, "sb": 0.12, "b": 0xf0ece4, "d": 0.6}], ["win", 0.40, 0.9, 0.9, 1.1, {"bal": "iron", "s": 0xb8a890, "sb": 0.12, "b": 0xf0ece4, "d": 0.6}], ["win", 0.70, 0.9, 0.9, 1.1, {"bal": "iron", "s": 0xb8a890, "sb": 0.12}]]}]},
	"alemania_9": {"eaves": "cornice", "tol": 1.1, "floors": [       # 2009: cream render framed in oxide red on a skirting of tiles; mottled brown brick upstairs
		{"wall": 0xe6cf9f, "plinth": [0.8, "tile_tan"], "open": [["win", 0.1, 1.1, 0.9, 1.45, {"g": "bars", "s": 0x8a5a48}], ["door", 0.3, 1.15, 2.3, {"k": "curtain", "c": 0xc9b89a, "s": 0x8a5a48}],
			["win", 0.54, 1.1, 0.9, 1.45, {"g": "bars", "s": 0x8a5a48}], ["win", 0.8, 1.1, 0.9, 1.45, {"g": "bars", "s": 0x8a5a48}]]},
		{"wall": "brick_brown", "band": 0x8a5a48, "open": [["win", 0.2, 1.1, 1.0, 1.2, {}], ["win", 0.44, 1.1, 1.0, 1.2, {}], ["bal", 0.74, 1.1, 2.1, {}]]}],
		"flank": [                                       # its long side on the Travesía (Street View, Nov 2024): the same cream framed in brown below, one barred window; brown brick above with an iron balcony (the far half was not in view: left plain)
			{"wall": 0xe6cf9f, "plinth": [0.8, "tile_tan"], "open": [["win", 0.38, 1.2, 0.9, 1.45, {"g": "bars", "s": 0x8a5a48}]]},
			{"wall": "brick_brown", "band": 0x8a5a48, "open": [["bal", 0.42, 1.1, 2.1, {"bw": 1.6}]]}]},
	"alemania_3": {"eaves": "brackets", "floors": [        # 1994 (Street View, Nov 2024): chocolate brick in a chequer of white panels round every opening; four arched balconies, a maroon gate, a pink curtain
		{"wall": "brick_dark", "plinth": [0.8, "stone"], "open": [["gar", 0.16, 3.4, 2.9, {"k": "planks", "c": 0x6a2a3a, "s": W1, "sb": 0.4}], ["win", 0.45, 1.2, 1.0, 1.3, {"g": "bars", "s": W1, "sb": 0.5, "b": 0x4a3428}],
			["door", 0.65, 1.1, 2.3, {"k": "curtain", "c": 0xc9a090, "s": W1, "sb": 0.45}], ["win", 0.85, 1.2, 1.0, 1.3, {"g": "bars", "s": W1, "sb": 0.5, "b": 0x4a3428}]]},
		{"wall": "brick_dark", "open": [["bal", 0.15, 1.2, 2.2, {"s": W1, "sb": 0.5, "b": 0x3a2a24, "bw": 2.0}], ["bal", 0.39, 1.2, 2.2, {"s": W1, "sb": 0.5, "b": 0x3a2a24, "bw": 2.0}],
			["bal", 0.62, 1.2, 2.2, {"s": W1, "sb": 0.5, "b": 0x3a2a24, "bw": 2.0}], ["bal", 0.85, 1.2, 2.2, {"s": W1, "sb": 0.5, "b": 0x3a2a24, "bw": 2.0}]]}]},
	"alemania_1": {"eaves": "brackets", "floors": [        # tan brick on a foot of white stone, long: little barred windows, the porch door, the great brown garage door
		{"wall": "brick", "plinth": [0.7, 0xe6e0d2], "open": [["win", 0.07, 0.8, 1.15, 1.0, {"g": "bars", "f": 0x3a3028, "d": 0.0}], ["win", 0.15, 0.8, 1.15, 1.0, {"g": "bars", "f": 0x3a3028, "d": 0.0}],
			["win", 0.23, 0.8, 1.15, 1.0, {"g": "bars", "f": 0x3a3028, "d": 0.0}], ["door", 0.41, 1.3, 2.4, {"c": 0x3a2a20, "s": 0xd9cdb0, "sb": 0.25}], ["gar", 0.78, 5.0, 2.7, {"k": "sect", "c": 0x4a2e24}]]},
		{"wall": "brick", "fly": 0.3, "open": [["bal", 0.08, 1.0, 2.1, {"b": 0x3a2a24, "bw": 1.6}], ["bal", 0.2, 1.0, 2.1, {"b": 0x3a2a24, "bw": 1.6}], ["bal", 0.37, 1.1, 2.1, {"b": 0x3a2a24, "bw": 1.8}],
			["bal", 0.6, 1.1, 2.1, {"b": 0x3a2a24, "bw": 1.8}], ["bal", 0.82, 1.3, 2.1, {"b": 0x3a2a24, "bw": 2.6}]]}],
		"flank": [                                       # its long side on Calle de Madrid (Street View, Nov 2024): the same tan brick on white stone, three barred windows below, two balconies and a window above
			{"wall": "brick", "plinth": [0.7, 0xe6e0d2], "open": [["win", 0.155, 1.3, 1.1, 1.1, {"g": "bars", "f": 0x3a3028, "d": 0.5, "b": 0x3a2a24}], ["win", 0.385, 1.3, 1.1, 1.1, {"g": "bars", "f": 0x3a3028, "d": 0.5, "b": 0x3a2a24}], ["win", 0.72, 1.3, 1.1, 1.1, {"g": "bars", "f": 0x3a3028, "d": 0.5, "b": 0x3a2a24}]]},
			{"wall": "brick", "open": [["bal", 0.13, 1.1, 2.1, {"b": 0x3a2a24, "bw": 1.9}], ["bal", 0.37, 1.1, 2.1, {"b": 0x3a2a24, "bw": 1.9}], ["win", 0.75, 1.3, 1.0, 1.2, {"b": 0x3a2a24, "d": 0.6}]]}]},
	"alemania_5": {"eaves": "tiles", "floors": [           # the house you inherit: old lime on a worn foot, a door, a window, the corral gate
		{"wall": 0xe4dccb, "plinth": [0.55, 0xb8ab98], "open": [["door", 0.2, 1.0, 2.1, {"c": 0x5a3a22, "s": 0xf4f0e6, "sb": 0.16}], ["win", 0.36, 0.9, 1.15, 1.0, {"f": 0x5a3a22, "d": 1.0, "b": 0x6a5a48}],
			["gar", 0.74, 2.8, 2.5, {"k": "planks", "c": 0x6a5238}]]}]},
	# --- Calle Real, from the square (Catastro's photos of the fronts; the shops' signs say what they sell, not their real names) ---
	"real_1": {"eaves": "tiles", "floors": [               # 1980: stone-faced shops below, a long wooden balcony above
		{"wall": "slab", "h": 3.2, "plinth": [0.45, 0xb9b2a6], "open": [["shop", 0.24, 4.0, 2.5, {"f": 0x8a8f96}], ["door", 0.56, 1.1, 2.4, {"c": 0x3a3028, "s": 0xd9cdb8}], ["shop", 0.82, 2.6, 2.4, {"f": 0x8a8f96}]],
			"signs": [[0.07, 0.41, 0x8a2a2a, "CHUCHES", 0xf4f0e6]], "awnings": [[0.69, 0.95, 0xd9682a]]},
		{"wall": 0xd9c9a8, "terrace": [0.04, 0.7, 1.0, -1, 0x6a4a30], "open": [["bal", 0.2, 1.6, 2.2, {"nb": true, "d": 0.4}], ["bal", 0.52, 1.4, 2.2, {"nb": true, "d": 0.6}], ["win", 0.86, 1.6, 0.9, 1.5, {"d": 0.3}]]}]},
	"real_3": {"eaves": "brackets", "floors": [            # 1965: a bar behind big windows framed in varnished wood; two balconies over it
		{"wall": "brick_brown", "h": 3.2, "open": [["shop", 0.2, 2.6, 2.5, {"f": 0xb9802f}], ["door", 0.5, 1.2, 2.45, {"c": 0xb9802f}], ["shop", 0.79, 2.4, 2.5, {"f": 0xb9802f}]],
			"signs": [[0.14, 0.86, 0x4a2e1c, "BAR", 0xf2e6c4]]},
		{"wall": 0xc9a878, "open": [["bal", 0.42, 1.2, 2.2, {"bw": 2.0, "d": 0.6}], ["bal", 0.8, 1.0, 2.1, {"bw": 1.6, "d": 0.5}]]}]},
	"real_5": {"eaves": "flat", "floors": [                # 1980: grey render, an office behind dark glass; upstairs a terrace set into the front
		{"wall": 0xa9a9a3, "h": 3.2, "open": [["gar", 0.15, 2.2, 2.7, {"k": "roller", "c": 0x3a2e28}], ["shop", 0.56, 2.8, 2.75, {"f": 0x22262c}], ["win", 0.9, 1.0, 1.2, 1.2, {"f": 0x22262c, "d": 0.0}]]},
		{"wall": 0xa9a9a3, "terrace": [0.38, 0.86, 0.9, -1, 0x3a3d40], "open": [["win", 0.16, 2.2, 0.6, 1.9, {"b": 0xb9b6ae, "d": 1.0}], ["bal", 0.62, 2.4, 2.2, {"nb": true, "f": 0x22262c, "d": 0.2}]]}]},
	"real_7": {"eaves": "tiles", "floors": [               # brown brick over white: a shop, the way through under the house to the next street, two barred windows
		{"wall": 0xe9e4d8, "h": 3.3, "plinth": [0.9, 0x4a4d52], "open": [["gar", 0.13, 3.0, 2.7, {"k": "roller", "c": 0x8a8f96}], ["gar", 0.42, 3.2, 3.0, {"k": "void"}],
			["win", 0.68, 1.4, 1.0, 1.3, {"g": "bars"}], ["win", 0.88, 1.4, 1.0, 1.3, {"g": "bars"}]], "signs": [[0.02, 0.3, 0xc0392b, "TIENDA", 0xf4f0e6]]},
		{"wall": "brick_brown", "open": [["win", 0.12, 1.3, 0.95, 1.2, {}], ["win", 0.37, 1.3, 0.95, 1.2, {"d": 0.4}], ["win", 0.62, 1.3, 0.95, 1.2, {}], ["win", 0.87, 1.3, 0.95, 1.2, {"d": 0.9}]]},
		{"wall": "brick_brown", "open": [["win", 0.12, 1.3, 0.95, 1.2, {"d": 0.5}], ["win", 0.37, 1.3, 0.95, 1.2, {}], ["win", 0.62, 1.3, 0.95, 1.2, {"d": 0.3}], ["win", 0.87, 1.3, 0.95, 1.2, {}]]}]},
	"real_9": {"eaves": "tiles", "floors": [               # three floors of brown brick; below, a phone shop, the garage, the street door and another shop
		{"wall": 0xd9a888, "h": 3.2, "plinth": [0.8, 0x6a7a8a], "open": [["shop", 0.16, 4.2, 2.6, {"f": 0x1c1a18}], ["gar", 0.46, 2.8, 2.6, {"k": "sect", "c": 0x4a2e24}], ["door", 0.64, 1.1, 2.4, {"c": 0x4a2e24, "s": 0xb9b2a6}],
			["shop", 0.85, 3.0, 2.5, {"f": 0x3a3028}]], "signs": [[0.03, 0.3, 0x1c1a18, "MÓVILES", 0xf4f0e6], [0.76, 0.95, 0xd9a41a, "REGALOS", 0x2a221c]]},
		{"wall": "brick_brown", "open": [["win", 0.15, 2.0, 0.9, 1.3, {}], ["win", 0.45, 1.2, 0.95, 1.2, {"d": 0.5}], ["win", 0.65, 1.2, 0.95, 1.2, {}], ["win", 0.87, 1.2, 0.95, 1.2, {"d": 0.9}]]},
		{"wall": "brick_brown", "open": [["win", 0.15, 2.0, 0.9, 1.3, {"d": 0.3}], ["win", 0.45, 1.2, 0.95, 1.2, {}], ["win", 0.65, 1.2, 0.95, 1.2, {"d": 0.6}], ["win", 0.87, 1.2, 0.95, 1.2, {}]]}]},
	"real_4": {"eaves": "cornice", "floors": [             # 1920: an old house, its ochre render flaking; the shop below shut behind its blinds
		{"wall": 0xd9c24a, "h": 3.4, "open": [["gar", 0.2, 2.8, 2.7, {"k": "roller", "c": 0x3a3d40}], ["gar", 0.52, 2.8, 2.7, {"k": "roller", "c": 0x3a3d40}], ["door", 0.85, 1.3, 2.7, {"c": 0x8a6a40, "s": 0xd9cdb0}]],
			"signs": [[0.36, 0.68, 0x3a3028, "SE TRASPASA", 0xf2e6c4]]},
		{"wall": 0xc9b060, "open": [["bal", 0.2, 1.1, 2.3, {"s": 0xd9cdb0, "b": 0x5a5a58, "bw": 1.7, "d": 0.5}], ["bal", 0.5, 1.1, 2.3, {"s": 0xd9cdb0, "b": 0x5a5a58, "bw": 1.7, "d": 0.9}], ["bal", 0.8, 1.1, 2.3, {"s": 0xd9cdb0, "b": 0x5a5a58, "bw": 1.7, "d": 0.3}]]}]},
	"real_6": {"eaves": "brackets", "floors": [            # tan brick, the windows framed in pale stone, long iron balconies (the photo shows only the upper floors: the shops are a guess)
		{"wall": "slab", "h": 3.3, "plinth": [0.6, 0x9a8c78], "open": [["shop", 0.2, 3.2, 2.6, {}], ["door", 0.5, 1.3, 2.6, {"c": 0x5a3a22, "s": 0xe9dfc8}], ["shop", 0.8, 3.2, 2.6, {}]]},
		{"wall": "brick", "open": [["bal", 0.2, 1.1, 2.2, {"s": 0xe9dfc8, "b": 0x8a5a40, "bw": 2.4}], ["bal", 0.5, 1.1, 2.2, {"s": 0xe9dfc8, "b": 0x8a5a40, "bw": 2.4, "d": 0.4}], ["bal", 0.8, 1.1, 2.2, {"s": 0xe9dfc8, "b": 0x8a5a40, "bw": 2.4}]]},
		{"wall": "brick", "open": [["bal", 0.2, 1.1, 2.2, {"s": 0xe9dfc8, "b": 0x8a5a40, "bw": 2.4, "d": 0.5}], ["bal", 0.5, 1.1, 2.2, {"s": 0xe9dfc8, "b": 0x8a5a40, "bw": 2.4}], ["bal", 0.8, 1.1, 2.2, {"s": 0xe9dfc8, "b": 0x8a5a40, "bw": 2.4, "d": 0.9}]]}]},
	"real_8": {"eaves": "cornice", "floors": [             # the long new block: shops in dark cladding below, white floors with iron balconies above
		{"wall": 0x4a4642, "h": 3.3, "open": [["shop", 0.09, 5.4, 2.6, {"f": 0x1c1a18}], ["shop", 0.3, 5.4, 2.6, {"f": 0x5a3a2a}], ["door", 0.47, 1.4, 2.5, {"c": 0x3a3028, "s": 0xe9dfc8, "sb": 0.3}],
			["shop", 0.61, 4.6, 2.6, {"f": 0x3a3028}], ["gar", 0.77, 3.0, 2.6, {"k": "roller", "c": 0x8a8f96}], ["shop", 0.91, 4.2, 2.6, {"f": 0x3a3028}]],
			"signs": [[0.02, 0.16, 0x1c1a18, "TELÉFONOS", 0xf28a2a], [0.23, 0.37, 0x2a8ab8, "ORTOPEDIA", 0xf4f0e6]]},
		{"wall": W1, "band": 0x8a5a48, "open": [["bal", 0.07, 1.4, 2.2, {"bw": 2.8}], ["bal", 0.19, 1.4, 2.2, {"bw": 2.8, "d": 0.4}], ["bal", 0.31, 1.4, 2.2, {"bw": 2.8}], ["bal", 0.43, 1.4, 2.2, {"bw": 2.8, "d": 0.9}],
			["bal", 0.56, 1.4, 2.2, {"bw": 2.8}], ["bal", 0.68, 1.4, 2.2, {"bw": 2.8, "d": 0.5}], ["bal", 0.8, 1.4, 2.2, {"bw": 2.8}], ["bal", 0.92, 1.4, 2.2, {"bw": 2.8, "d": 0.3}]]},
		{"wall": W1, "open": [["bal", 0.07, 1.4, 2.2, {"bw": 2.8, "d": 0.5}], ["bal", 0.19, 1.4, 2.2, {"bw": 2.8}], ["bal", 0.31, 1.4, 2.2, {"bw": 2.8, "d": 0.9}], ["bal", 0.43, 1.4, 2.2, {"bw": 2.8}],
			["bal", 0.56, 1.4, 2.2, {"bw": 2.8, "d": 0.4}], ["bal", 0.68, 1.4, 2.2, {"bw": 2.8}], ["bal", 0.8, 1.4, 2.2, {"bw": 2.8, "d": 0.6}], ["bal", 0.92, 1.4, 2.2, {"bw": 2.8}]]}]},
	"real_10": {"eaves": "brackets", "floors": [           # 1992: a white house in the old manner: windows framed in brick red, ornate grilles, three balconies
		{"wall": W1, "plinth": [0.7, 0xb9b2a6], "open": [["win", 0.14, 1.1, 1.0, 1.4, {"g": "bars", "s": 0x8a5a48}], ["door", 0.4, 1.2, 2.4, {"c": 0x4a2e1c, "s": 0x8a5a48}],
			["win", 0.65, 1.1, 1.0, 1.4, {"g": "bars", "s": 0x8a5a48}], ["win", 0.88, 1.1, 1.0, 1.4, {"g": "bars", "s": 0x8a5a48}]]},
		{"wall": W1, "open": [["bal", 0.16, 1.1, 2.2, {"s": 0x8a5a48, "b": 0x4a3428, "bw": 1.8}], ["bal", 0.46, 1.1, 2.2, {"s": 0x8a5a48, "b": 0x4a3428, "bw": 1.8}], ["bal", 0.76, 1.1, 2.2, {"s": 0x8a5a48, "b": 0x4a3428, "bw": 1.8}]]}]},
	# --- the even side ---
	"alemania_bloque": {"eaves": "tiles", "floors": [      # the block of flats: a yellow ground floor on a foot of slate, three floors of red brick with their balconies
		{"wall": 0xe0a830, "plinth": [1.0, "stone"], "h": 3.4, "open": [["win", 0.08, 0.7, 1.4, 1.1, {"g": "bars", "f": 0x7a4a34, "d": 0.0}], ["win", 0.26, 0.7, 1.4, 1.1, {"g": "bars", "f": 0x7a4a34, "d": 0.0}],
			["gar", 0.52, 3.2, 3.0, {"k": "planks", "c": 0x8a3a2a}], ["win", 0.76, 0.7, 1.4, 1.1, {"g": "bars", "f": 0x7a4a34, "d": 0.0}], ["win", 0.92, 0.7, 1.4, 1.1, {"g": "bars", "f": 0x7a4a34, "d": 0.0}]]},
		{"wall": "brick_red", "band": 0xd9cdb8, "open": [["bal", 0.1, 1.3, 2.2, {"k": "white", "bw": 2.6}], ["win", 0.25, 1.1, 1.0, 1.2, {}], ["bal", 0.42, 1.3, 2.2, {"k": "white", "bw": 2.6}], ["win", 0.58, 1.1, 1.0, 1.2, {}], ["bal", 0.74, 1.3, 2.2, {"k": "white", "bw": 2.6}], ["win", 0.9, 1.1, 1.0, 1.2, {}]]},
		{"wall": "brick_red", "band": 0xd9cdb8, "open": [["bal", 0.1, 1.3, 2.2, {"k": "white", "bw": 2.6}], ["win", 0.25, 1.1, 1.0, 1.2, {"d": 0.4}], ["bal", 0.42, 1.3, 2.2, {"k": "white", "bw": 2.6}], ["win", 0.58, 1.1, 1.0, 1.2, {}], ["bal", 0.74, 1.3, 2.2, {"k": "white", "bw": 2.6}], ["win", 0.9, 1.1, 1.0, 1.2, {"d": 0.3}]]},
		{"wall": "brick_red", "band": 0xd9cdb8, "open": [["bal", 0.1, 1.3, 2.2, {"k": "white", "bw": 2.6}], ["win", 0.25, 1.1, 1.0, 1.2, {}], ["bal", 0.42, 1.3, 2.2, {"k": "white", "bw": 2.6}], ["win", 0.58, 1.1, 1.0, 1.2, {"d": 0.5}], ["bal", 0.74, 1.3, 2.2, {"k": "white", "bw": 2.6}], ["win", 0.9, 1.1, 1.0, 1.2, {}]]}],
		"flank": [                                       # its long side on the Avenida (Street View, Nov 2024): the yellow ground floor with red gates, a red door, a blue curtain, a side door by the corner; red brick above with white-framed windows (approximate past the middle: the panoramas there are a few metres off)
			{"wall": 0xe0a830, "plinth": [1.0, "stone"], "h": 3.4, "open": [["gar", 0.14, 2.6, 2.8, {"k": "planks", "c": 0x9a3a2a}], ["door", 0.32, 0.9, 2.3, {"c": 0x9a3a2a}], ["door", 0.415, 1.4, 2.3, {"k": "curtain", "c": 0x4a6ab8}], ["gar", 0.55, 2.8, 2.8, {"k": "planks", "c": 0x9a3a2a}], ["door", 0.85, 0.9, 2.2, {"c": 0x6a4a34}]]},
			{"wall": "brick_red", "band": 0xd9cdb8, "open": [["win", 0.2, 1.2, 1.0, 1.2, {"f": 0xf0ece4}], ["win", 0.42, 1.2, 1.0, 1.2, {"f": 0xf0ece4}], ["win", 0.56, 1.4, 1.0, 1.2, {"f": 0xf0ece4}], ["win", 0.72, 1.2, 1.0, 1.2, {"f": 0xf0ece4}], ["bal", 0.86, 1.2, 2.1, {"k": "white", "bw": 1.8}]]},
			{"wall": "brick_red", "band": 0xd9cdb8, "open": [["win", 0.2, 1.2, 1.0, 1.2, {"f": 0xf0ece4}], ["win", 0.42, 1.2, 1.0, 1.2, {"f": 0xf0ece4}], ["win", 0.56, 1.4, 1.0, 1.2, {"f": 0xf0ece4}], ["win", 0.72, 1.2, 1.0, 1.2, {"f": 0xf0ece4}], ["bal", 0.86, 1.2, 2.1, {"k": "white", "bw": 1.8}]]},
			{"wall": "brick_red", "band": 0xd9cdb8, "open": [["win", 0.2, 1.2, 1.0, 1.2, {"f": 0xf0ece4}], ["win", 0.42, 1.2, 1.0, 1.2, {"f": 0xf0ece4}], ["win", 0.56, 1.4, 1.0, 1.2, {"f": 0xf0ece4}], ["win", 0.72, 1.2, 1.0, 1.2, {"f": 0xf0ece4}], ["bal", 0.86, 1.2, 2.1, {"k": "white", "bw": 1.8}]]}]},
	"alemania_c65": {"eaves": "tiles", "floors": [         # 1992 (Catastro has no photo of it): plain cream, its back to this street
		{"wall": 0xe3d2a8, "plinth": [0.5, 0xa8a096], "open": [["door", 0.15, 1.0, 2.2, {"c": 0x6b4424}], ["win", 0.45, 1.1, 1.0, 1.25, {"g": "bars"}], ["gar", 0.78, 2.2, 2.3, {"k": "roller", "c": 0x7a5a40}]]},
		{"wall": 0xe3d2a8, "open": [["win", 0.25, 1.1, 1.0, 1.25, {}], ["win", 0.7, 1.1, 1.0, 1.25, {}]]}],
		"flank": [                                       # its long side on the Avenida de la Constitución (Street View, Nov 2024): cream on a foot of rubble stone, a barred window, a wooden door in a stone frame, three windows above
			{"wall": 0xdccaa4, "plinth": [1.0, "stone"], "open": [["win", 0.165, 0.9, 1.1, 1.0, {"g": "bars"}], ["door", 0.72, 0.9, 2.2, {"c": 0x6a3a26, "s": 0xa8a29a, "sb": 0.2}]]},
			{"wall": 0xdccaa4, "open": [["win", 0.15, 1.1, 0.9, 1.1, {"b": 0xf0ece4, "d": 0.8}], ["win", 0.58, 1.1, 0.9, 1.1, {"b": 0xf0ece4, "d": 0.8}], ["win", 0.86, 1.1, 0.9, 1.1, {"b": 0xf0ece4, "d": 0.8}]]}]},
	"alemania_c63": {"eaves": "tiles", "tol": 0.8, "trim": 0xb9b0a0, "floors": [         # 2007: white tiles below, and above them a box of red brick that stands out, one wide dark window in it
		{"wall": 0xf1efe8, "plinth": [0.5, 0xb9b6ae], "open": [["win", 0.4, 1.4, 0.9, 1.5, {"g": "bars", "f": 0x3a3028, "d": 0.0}]]},
		{"wall": "brick_red", "fly": 0.6, "open": [["win", 0.5, 2.0, 0.9, 1.5, {"f": 0x3a3028, "d": 0.0}]]},
		{"wall": "brick_red", "fly": 0.6}],
		"flank": [                                       # its long side on the Avenida (Street View, Nov 2024): the white tiles with a wide barred window and a curtained door, the red brick above
			{"wall": 0xf1efe8, "plinth": [0.5, 0xb9b6ae], "open": [["win", 0.45, 1.4, 0.9, 1.5, {"g": "bars", "f": 0x3a3028, "d": 0.0}], ["door", 0.87, 1.0, 2.3, {"k": "curtain", "c": 0xb89878}]]},
			{"wall": "brick_red", "open": [["win", 0.45, 1.4, 0.9, 1.3, {"f": 0x3a3028, "d": 0.3}]]},
			{"wall": "brick_red"}]},
	"alemania_t10": {"eaves": "brackets", "floors": [      # 1980: sand render, the windows framed in brown, a skirting of brown tiles (its front is on the Travesía)
		{"wall": 0xd9b98a, "plinth": [0.9, "tile_brown"], "open": [["win", 0.5, 1.1, 1.0, 1.3, {"g": "bars", "s": 0x8a4a38}]]},
		{"wall": 0xd9b98a, "open": [["win", 0.5, 1.1, 1.0, 1.2, {"s": 0x8a4a38, "bal": "iron"}]]}],
		"flank": [                                       # its long side on the Travesía (Street View, Nov 2024): the long face of the house: a door and a wide barred window with the for-sale board on its grille, framed in brown; two windows with iron rails above
			{"wall": 0xd9b98a, "plinth": [0.9, "tile_brown"], "open": [["door", 0.34, 1.1, 2.3, {"c": 0x6a4a34, "s": 0x8a4a38}], ["win", 0.755, 1.6, 1.0, 1.3, {"g": "bars", "s": 0x8a4a38}]], "plates": [[0.755, 2.05, "sevende", 0.12, -1, 0, 1]]},
			{"wall": 0xd9b98a, "open": [["win", 0.48, 1.2, 1.0, 1.2, {"s": 0x8a4a38, "bal": "iron"}], ["win", 0.81, 1.2, 1.0, 1.2, {"s": 0x8a4a38, "bal": "iron"}]]}]},
	"alemania_16": {"eaves": "brackets", "floors": [       # 1998: red brick on a foot of stone; a curtain at the door, an iron grille, the brown doors of the store
		{"wall": "brick_red", "plinth": [1.0, "stone"], "open": [["door", 0.1, 1.0, 2.2, {"k": "curtain"}], ["win", 0.38, 1.3, 1.0, 1.3, {"g": "bars", "b": 0x8a6a4a}], ["gar", 0.74, 3.2, 2.8, {"k": "planks", "c": 0x6a3a30}]]},
		{"wall": "brick_red", "fly": 0.3, "open": [["bal", 0.14, 1.0, 2.1, {"b": 0x8a6a4a, "bw": 1.5}], ["win", 0.42, 1.2, 1.0, 1.2, {"b": 0x8a6a4a, "bal": "iron"}], ["bal", 0.74, 1.6, 2.1, {"bw": 2.4}]]}]},
	"alemania_14": {"eaves": "flat", "floors": [           # 1970 (Street View, Nov 2024): little tiles in a brown diamond pattern below, a pale curtain in a grey frame; brick above, one long balcony under a striped beige awning
		{"wall": "tile_brown", "open": [["win", 0.25, 1.2, 0.9, 1.5, {"g": "bars"}], ["door", 0.7, 1.8, 2.6, {"k": "curtain", "c": 0xe9e2d4, "s": 0x8a8680, "sb": 0.18}]]},
		{"wall": "brick_brown", "terrace": [0.04, 0.96, 0.9, 0xc9b08a], "open": [["bal", 0.3, 1.2, 2.1, {"nb": true, "d": 0.3}], ["bal", 0.7, 1.2, 2.1, {"nb": true, "d": 0.5}]]}]},
	"alemania_12": {"eaves": "tiles", "floors": [          # 1970 (Street View, Nov 2024): an old low house: cream lime, worn, on a foot of blue-grey cement; a grille with a diamond in it, a varnished wooden door up a step
		{"wall": 0xe9dfa8, "plinth": [1.0, 0x7a8288], "open": [["win", 0.3, 1.0, 1.1, 1.2, {"g": "bars", "d": 0.0}], ["door", 0.64, 1.1, 2.2, {"c": 0x8a5a2a}]]}]},
	"alemania_10": {"eaves": "brackets", "floors": [       # 1960: pebble-dash on a foot of dark brick; dark brick above, a long balcony under a striped awning
		{"wall": 0x9a8c7c, "plinth": [0.8, "brick_dark"], "open": [["win", 0.06, 0.7, 1.0, 1.3, {"g": "bars"}], ["door", 0.2, 1.1, 2.3, {"k": "curtain", "c": 0xd9c4a8, "s": 0x6a4a3a}], ["win", 0.42, 1.2, 1.0, 1.3, {"g": "bars", "b": 0xb8a070, "d": 1.0}],
			["gar", 0.68, 2.8, 2.6, {"k": "roller", "c": 0xb8a878}], ["win", 0.92, 0.7, 1.0, 1.3, {"g": "bars"}]]},
		{"wall": "brick_dark", "terrace": [0.03, 0.97, 1.0, 0xa85a30], "open": [["win", 0.2, 1.0, 1.0, 1.0, {"b": 0xb8a070, "d": 1.0}], ["bal", 0.5, 2.0, 2.2, {"b": 0xb8a070, "d": 1.0, "nb": true}], ["win", 0.8, 1.0, 1.0, 1.0, {"b": 0xb8a070, "d": 1.0}]]}]},
	"alemania_8": {"eaves": "cornice", "floors": [         # 2001 (Street View, Nov 2024): tan brick, every opening framed in white render; an iron gate at the door, a wide brown gate with a grille along its top
		{"wall": "brick", "open": [["door", 0.22, 1.2, 2.4, {"k": "metal", "c": 0x3a2a24, "s": "brick", "sb": 0.25}], ["gar", 0.66, 3.4, 2.9, {"k": "metal", "c": 0x6a4a30, "s": "brick", "sb": 0.25}]]},
		{"wall": "brick", "open": [["bal", 0.32, 1.2, 2.1, {"s": W1, "sb": 0.3}], ["bal", 0.68, 1.2, 2.1, {"s": W1, "sb": 0.3}]]}]},
	"alemania_6": {"eaves": "tiles", "floors": [           # 1900: a store: bare cement and a green gate
		{"wall": 0xa89c88, "open": [["gar", 0.62, 2.8, 3.0, {"k": "metal", "c": 0x2f6a3a}]]}]},
	"alemania_4": {"eaves": "tiles", "floors": [           # 1976: grey cement, a red gate, one window over it
		{"wall": 0x9a968c, "open": [["gar", 0.5, 3.0, 2.5, {"k": "metal", "c": 0x9a3a2a}]]},
		{"wall": 0x9a968c, "open": [["win", 0.5, 1.3, 1.0, 1.1, {"f": 0x5a3a2a, "d": 0.0}]]}]},
	"alemania_m11": {"eaves": "tiles", "floors": [         # 1970: cream over a skirting of orange (its front, with the long balcony, is on Calle de Madrid)
		{"wall": 0xe9d9a8, "plinth": [0.9, 0xc9702a], "open": [["gar", 0.1, 2.4, 2.4, {"k": "metal", "c": 0x4a3a34}], ["win", 0.27, 1.0, 1.0, 1.2, {"g": "bars"}], ["win", 0.5, 1.2, 0.9, 1.5, {"g": "bars"}],
			["door", 0.68, 1.1, 2.3, {"k": "curtain"}], ["win", 0.86, 1.2, 0.9, 1.5, {"g": "bars"}]]},
		{"wall": 0xe9d9a8, "open": [["win", 0.12, 1.4, 1.0, 1.2, {}], ["bal", 0.5, 1.0, 2.1, {}], ["bal", 0.8, 1.0, 2.1, {}]]}],
		"flank": [                                       # its long side on Calle de Madrid (Street View, Nov 2024): a wide barred window, a wooden door, a small one; one long balcony the length of it above
			{"wall": 0xe9d9a8, "plinth": [0.9, 0xc9702a], "open": [["win", 0.25, 1.4, 0.9, 1.4, {"g": "bars", "d": 0.0}], ["door", 0.51, 0.9, 2.2, {"c": 0x8a4a28}], ["win", 0.75, 0.6, 1.1, 1.0, {"g": "bars"}]]},
			{"wall": 0xe9d9a8, "terrace": [0.08, 0.98, 0.8, -1, 0xe8e2d0], "open": [["bal", 0.24, 1.1, 2.1, {"nb": true, "b": 0xe8e4dc, "d": 0.6}], ["win", 0.72, 1.0, 1.0, 1.1, {}]]}]},
}
