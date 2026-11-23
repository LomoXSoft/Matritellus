extends "res://scripts/obra.gd"
## The two signs at the town's north entrance, by the old Madrid-Cádiz road, on the bare ground west of it before the
## roundabout of the Avenida de la Constitución (the user, 23 November 2026, with three Street View captures of
## November 2024: "Hay dos carteles en la entrada de Madridejos que me gustaría añadir"):
##
## - the welcome wall: a whitewashed wall 5 m long and 3 m high, its top waved like a ruin and capped with rough brown
##   stones, dark stones set in its face, on a plinth; two glazed tiles, "Un lugar de la Mancha" and the town's name
##   (MADRIDEJOS, as the real one), and Don Quixote on Rocinante in a sheet of rusty steel, his lance over the top of the wall;
## - the twinning sign on two posts nearer the road: white gone yellow, a red border, the town's crest and its name,
##   "HERMANADO CON LA VILLA DE", a blue shield and NÉRAC (FRANCE). The crests are ours (tools/entrada/dibujos.py);
##   the words are the real ones (the town keeps its name: Matritellus is the game's title, its old Latin name).
##
## Where they stand: six Street View cameras along the road, their bearings to each sign (they agree within half a
## metre), and the PNOA orthophoto for the wall's line. The wall's face looks north-north-east, to who comes from the
## north; so does the sign. Measures from a picture that sees the wall square on (from 43 m): 5.10 m long, 3.18 m to
## the top of its highest hump, the plinth 0.72 m. The Quixote's outline was traced from it (tools/entrada/silueta.py
## -> data/quijote.json). No rebake: both stand on bare ground, each a place of its own (so the dry plants keep off
## them but not off the field between).
##
## Frame of the wall: +x along it, from its left end as seen from the road, +y up, +z out of its face; y = 0 the
## ground at its middle. The sign is a second node of this same script, in its own frame (+z out of its face).
##
## A saffron flower is hidden at the wall's back foot, in dry grass (the user's choice, 24 Nov 2026: _saffron).

const Matojos = preload("res://scripts/matojos.gd")
const WALL := Vector2(258.5, -1625.1)          # the middle of its face, on the map
const FACE := 12.0                             # the way its face looks (bearing, degrees)
const WIDE := 5.10
const TALL := 3.18
const THICK := 0.5
const PLINTH := 0.72
const SINK := -1.0                             # the plinth goes this far into the ground
const DRAWN := 0.18                            # the bare ground is drawn this far under the physics one (world.gd ROAD_Y)
## its top, from the left end to the right: [part of the length, part of TALL]
const TOP := [[0.0, 0.86], [0.03, 0.93], [0.1, 1.0], [0.28, 0.99], [0.4, 0.973], [0.51, 0.94], [0.58, 0.907],
	[0.63, 0.882], [0.645, 0.886], [0.66, 0.92], [0.72, 0.955], [0.81, 0.967], [0.92, 0.967], [0.97, 0.927], [1.0, 0.86]]
## the dark stones set in the whitewash: [x, y] in metres (the picture square on)
const STONES := [[0.14, 1.02], [0.33, 1.85], [0.69, 1.27], [0.74, 1.95], [0.81, 2.67], [1.2, 1.13], [1.26, 2.22],
	[1.43, 1.7], [1.72, 1.02], [1.81, 1.98], [2.0, 1.4], [2.28, 1.7], [2.56, 2.04], [2.62, 1.15], [2.98, 1.37],
	[3.3, 2.22], [3.77, 1.15], [4.26, 2.57], [4.43, 2.13], [4.97, 1.85], [0.3, 2.45], [4.6, 1.2]]
const LUGAR := Rect2(0.86, 2.27, 1.96, 0.26)  # the tile "Un lugar de la Mancha" (x, y, wide, high)
const NOMBRE := Rect2(0.57, 1.35, 1.40, 0.26) # the tile with the town's name
const OFF := 0.045                             # how far the steel sheet stands off the whitewash
const SHEET := 0.012

const SIGN := Vector2(263.0, -1650.9)          # the twinning sign: the middle between its posts, on the map
const SIGN_FACE := 30.0
const PLATE := Vector2(1.2, 0.87)
const PLATE_LOW := 2.25                        # its bottom edge over the ground (two cameras: its middle 2.7 m over the road)
const POSTS := 0.33                            # each post this far from its middle
const SAFFRON := Vector2(3.9, -0.95)           # the hidden saffron, in the wall's frame: behind it, at its foot

var cartel                                     # the twinning sign (this same script, another node)
var kind := "muro"
var sheet := 0                                 # pieces of the steel sheet (the self-test)
var lance_tip := Vector3.ZERO                  # in the wall's frame
var top_at := 0.0                              # how high the wall's top is under the lance's point
var saffron_spot: Vector2                      # where its hidden saffron flower grows (in the game's flowers, "id": "entrada")

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"cal":              # (fresh lime: clean white, as the photos show it)
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.985, 0.95)), 0.18)
		"zocalo":
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.88, 0.87, 0.84)), 0.1)
		"remate":
			m = Tex.mat("rock_wall", Color(0.8, 0.64, 0.46))
		"piedra":           # (brown and grey field stones)
			m = Tex.mat("rock_wall", Color(0.68, 0.58, 0.5))
		"corten":
			var cm := StandardMaterial3D.new()
			cm.albedo_color = Parts.col(0x74422a)
			cm.metallic = 0.3
			cm.roughness = 0.85
			m = cm
		"lugar", "nombre", "hermanado":
			var pm := StandardMaterial3D.new()
			pm.albedo_texture = load("res://assets/entrada/%s.png" % key)
			pm.roughness = 0.6 if key == "hermanado" else 0.3
			m = pm
		"azulejo":
			m = Parts.mat(0xf0efe9)
		"poste", "dorso":
			var gm := StandardMaterial3D.new()
			gm.albedo_color = Parts.col(0xa6aaad if key == "poste" else 0x8f9396)
			gm.metallic = 0.6
			gm.roughness = 0.45
			m = gm
		_:
			return super(key)
	_mats[key] = m
	return m

## a frame on the map: origin at `at` on the ground, +z out of a face looking `bearing`, +x to the right of who
## looks at that face (x = UP x z, so nothing comes out mirrored)
static func _frame(at: Vector2, bearing: float, y: float) -> Transform3D:
	var h := deg_to_rad(bearing)
	var z := Vector3(sin(h), 0.0, -cos(h))
	return Transform3D(Basis(Vector3.UP.cross(z), Vector3.UP, z), Vector3(at.x, y, at.y))

func build(world) -> void:
	W = world
	var t := _frame(WALL, FACE, 0.0)
	level = 1e9                                          # (its floor: the lowest ground under it, as it is drawn)
	for x in [-WIDE / 2.0 - 0.07, 0.0, WIDE / 2.0 + 0.07]:
		for z in [0.07, -THICK - 0.07]:
			var q: Vector3 = t * Vector3(x, 0.0, z)
			level = minf(level, MapData.height(Vector2(q.x, q.z)) - DRAWN)
	transform = Transform3D(t.basis, Vector3(t.origin.x, level, t.origin.z) - t.basis.x * (WIDE / 2.0))     # (x = 0 its left end)
	name = "EntradaMuro"
	W.add_child(self)
	_wall()
	_cap()
	_stones()
	_tiles()
	_quijote()
	_saffron()
	solid(Vector3(WIDE / 2.0, (TALL + SINK) / 2.0, -THICK / 2.0), Vector3(WIDE + 0.14, TALL - SINK, THICK + 0.14))
	for x in [0.0, WIDE / 2.0, WIDE]:
		yard.append(spot(x, -THICK / 2.0))
	home()
	_commit()
	cartel = get_script().new()
	cartel.kind = "cartel"
	cartel._sign(world)

## The hidden saffron (the user, 24 November 2026, choosing where: «Esconde azafrán en la opción 1», at the foot of the
## wall on its back, in the dry grass): a flower behind the wall, where who comes from the north cannot see it, among
## tufts of dry grass all along the back foot (the fields' own dry plants keep a metre off a hand-built place). The
## flower is the game's to take away; it counts once a game, as the other hidden ones.
func _saffron() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2411
	var tufts: Array = []
	for x in [0.35, 1.2, 2.1, 2.9, 4.7]:                 # (along the back foot)
		tufts.append(Vector2(x + rng.randf_range(-0.2, 0.2), -THICK - rng.randf_range(0.2, 0.45)))
	for k in range(9):                                   # (round the flower, thicker)
		var a := TAU * k / 7.0 + rng.randf_range(-0.3, 0.3)
		var d := rng.randf_range(0.3, 0.65)
		tufts.append(SAFFRON + Vector2(cos(a) * d, minf(sin(a) * d * 0.7, -THICK - 0.2 - SAFFRON.y)))      # (none nearer the wall than 0.2)
	var mm := MultiMesh.new()                            # (the very tufts of the fields: matojos.gd's, and as it shows them)
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = Matojos._tuft_mesh()
	mm.instance_count = tufts.size()
	var straw := [Color(1.0, 0.97, 0.9), Color(0.9, 0.84, 0.72), Color(0.82, 0.77, 0.7), Color(1.0, 0.9, 0.74)]
	for k in range(tufts.size()):
		var t: Vector2 = tufts[k]
		var sc := rng.randf_range(0.42, 0.66)
		var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(sc * rng.randf_range(0.85, 1.2), sc, sc * rng.randf_range(0.85, 1.2)))
		mm.set_instance_transform(k, Transform3D(b, Vector3(t.x, ground(t.x, t.y) - DRAWN - 0.02, t.y)))
		mm.set_instance_color(k, straw[rng.randi() % straw.size()] * rng.randf_range(0.88, 1.05))
	var grass := MultiMeshInstance3D.new()
	grass.multimesh = mm
	var gm := StandardMaterial3D.new()
	gm.vertex_color_use_as_albedo = true
	gm.cull_mode = BaseMaterial3D.CULL_DISABLED
	gm.roughness = 1.0
	grass.material_override = gm
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(grass)
	var flower := Node3D.new()
	flower.add_child(Parts.part("cyl", 0x5f9c4a, Vector3(0, 0.3, 0), Vector3(0.03, 0.6, 0.03)))
	for k in range(5):
		flower.add_child(Parts.part("ball", 0x9b5de5, Vector3(cos(k * 1.257) * 0.12, 0.66, sin(k * 1.257) * 0.12), Vector3(0.11, 0.2, 0.11)))
	flower.add_child(Parts.part("ball", 0xe63946, Vector3(0, 0.74, 0), Vector3(0.05, 0.13, 0.05)))
	flower.position = Vector3(SAFFRON.x, ground(SAFFRON.x, SAFFRON.y) - DRAWN - 0.03, SAFFRON.y)
	add_child(flower)
	saffron_spot = spot(SAFFRON.x, SAFFRON.y)
	var game = W.get_parent()                           # (the game: the world is its child)
	if game != null and game.get("flowers") != null:
		(game.flowers as Array).append({"node": flower, "p": saffron_spot, "id": "entrada", "hidden": true})      # (hidden: Sistemas keeps count of these)

## the wall: its whitewashed body on its plinth
func _wall() -> void:
	box(-0.07, SINK, -THICK - 0.07, WIDE + 0.14, PLINTH - SINK, THICK + 0.14, "zocalo")
	var pts := PackedVector2Array([Vector2(0.0, PLINTH)])
	for q in TOP:
		pts.append(Vector2(q[0] * WIDE, q[1] * TALL))
	pts.append(Vector2(WIDE, PLINTH))
	slab(pts, 0.0, THICK, "cal")
	_back(pts, -THICK, "cal")

## the back of a slab: the same outline at z, facing back
func _back(pts: PackedVector2Array, z: float, key) -> void:
	var idx := Geometry2D.triangulate_polygon(pts)
	for t in range(0, idx.size(), 3):
		var a := pts[idx[t]]; var b := pts[idx[t + 1]]; var c := pts[idx[t + 2]]
		tri(Vector3(a.x, a.y, z), Vector3(b.x, b.y, z), Vector3(c.x, c.y, z), key, Vector3(0, 0, -1))

## the wall's top in metres at x
func _top(x: float) -> float:
	var u := clampf(x / WIDE, 0.0, 1.0)
	for i in range(TOP.size() - 1):
		var a: Array = TOP[i]
		var b: Array = TOP[i + 1]
		if u <= float(b[0]):
			return lerpf(a[1], b[1], (u - a[0]) / maxf(b[0] - a[0], 0.0001)) * TALL
	return float(TOP[TOP.size() - 1][1]) * TALL

## its cap of rough brown stones, a band along the top a little proud of both faces, lumps on it
func _cap() -> void:
	var up := PackedVector2Array()
	var low := PackedVector2Array()
	for q in TOP:
		up.append(Vector2(q[0] * WIDE, q[1] * TALL + 0.05))
		low.append(Vector2(q[0] * WIDE, q[1] * TALL - 0.07))
	low.reverse()
	var band := up + low
	slab(band, 0.035, THICK + 0.07, "remate")
	_back(band, -THICK - 0.035, "remate")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1605
	var x := 0.06
	while x < WIDE - 0.05:
		for k in range(2):
			var z := -THICK * (0.25 + 0.5 * k) + rng.randf_range(-0.08, 0.08)
			_lump(Vector3(x, _top(x) + 0.045, z), rng.randf_range(0.05, 0.08), Vector3(1.0, 0.5, 0.9), "remate", rng)
		x += rng.randf_range(0.16, 0.26)

## a rough lump: a ball of few faces, squashed by `scale`, turned at random about `axis`
func _lump(at: Vector3, r: float, scale: Vector3, key, rng: RandomNumberGenerator, axis := Vector3.UP) -> void:
	var keep := _xf
	_xf = _xf * Transform3D(Basis(axis, rng.randf_range(0.0, TAU)) * Basis.from_scale(scale), at)
	ball(Vector3.ZERO, r, key, 1.0, 6, 4)
	_xf = keep

## the dark stones set in the whitewash, standing a little out of it
func _stones() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1890
	for s in STONES:
		var r := rng.randf_range(0.04, 0.075)          # (field stones of every shape, flat to the wall, turned any way in it)
		_lump(Vector3(s[0], s[1], r * 0.05), r, Vector3(rng.randf_range(0.9, 1.7), rng.randf_range(0.6, 1.1), 0.5), "piedra", rng, Vector3.BACK)

## the two glazed tiles
func _tiles() -> void:
	for t in [[LUGAR, "lugar"], [NOMBRE, "nombre"]]:
		var r: Rect2 = t[0]
		box(r.position.x, r.position.y, 0.0, r.size.x, r.size.y, 0.022, "azulejo")
		var z := 0.0225
		quad(Vector3(r.position.x, r.position.y, z), Vector3(r.end.x, r.position.y, z), Vector3(r.end.x, r.end.y, z), Vector3(r.position.x, r.end.y, z),
			t[1], Vector3(0, 0, 1), [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

## Don Quixote on Rocinante: the steel sheet cut to his outline (data/quijote.json), off the wall on hidden brackets,
## and his lance, a bar from his hand up past the top of the wall, its iron point on it
func _quijote() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/quijote.json"))
	if not (data is Dictionary):
		return
	var z0 := OFF
	var z1 := OFF + SHEET
	for pc in data["pieces"]:
		var poly := PackedVector2Array()
		for p in pc:
			poly.append(Vector2(p[0], p[1]))
		var idx := Geometry2D.triangulate_polygon(poly)
		for i in range(0, idx.size(), 3):
			var a := poly[idx[i]]; var b := poly[idx[i + 1]]; var c := poly[idx[i + 2]]
			tri(Vector3(a.x, a.y, z1), Vector3(b.x, b.y, z1), Vector3(c.x, c.y, z1), "corten", Vector3(0, 0, 1))
			tri(Vector3(a.x, a.y, z0), Vector3(b.x, b.y, z0), Vector3(c.x, c.y, z0), "corten", Vector3(0, 0, -1))
		sheet += 1
	for r in [data["outline"]] + data["gaps"]:
		for i in range(r.size()):
			var a: Array = r[i]
			var b: Array = r[(i + 1) % r.size()]
			var d := Vector2(b[0] - a[0], b[1] - a[1])
			if d.length() < 0.0001:
				continue
			quad(Vector3(a[0], a[1], z0), Vector3(b[0], b[1], z0), Vector3(b[0], b[1], z1), Vector3(a[0], a[1], z1), "corten", Vector3(d.y, -d.x, 0).normalized())
	var butt := Vector2(data["lance"][1][0], data["lance"][1][1])
	var tip := Vector2(data["lance"][0][0], data["lance"][0][1])
	var run := (tip - butt).normalized()
	tip = butt + run * ((3.55 - butt.y) / run.y)       # (its point, cut off at the top of the picture: half a metre over the wall)
	var zm := (z0 + z1) / 2.0
	bar(Vector3(butt.x, butt.y, zm), Vector3(tip.x, tip.y, zm), 0.035, SHEET, "corten")
	var side := Vector2(-run.y, run.x) * 0.045
	var mid := tip + run * 0.07
	var point := tip + run * 0.24
	for z in [z0, z1]:                                   # (the iron point: a leaf, both faces)
		var n := Vector3(0, 0, 1) if z == z1 else Vector3(0, 0, -1)
		tri(Vector3(tip.x, tip.y, z), Vector3(mid.x + side.x, mid.y + side.y, z), Vector3(point.x, point.y, z), "corten", n)
		tri(Vector3(tip.x, tip.y, z), Vector3(point.x, point.y, z), Vector3(mid.x - side.x, mid.y - side.y, z), "corten", n)
	lance_tip = Vector3(point.x, point.y, zm)
	top_at = _top(point.x)

## the twinning sign: its plate on two round posts, braced behind
func _sign(world) -> void:
	W = world
	level = MapData.height(SIGN) - DRAWN
	transform = _frame(SIGN, SIGN_FACE, level)
	name = "EntradaCartel"
	W.add_child(self)
	var top := PLATE_LOW + PLATE.y
	for s in [-1.0, 1.0]:
		drum(Vector3(s * POSTS, -0.5, -0.055), 0.03, 0.03, top - 0.04 + 0.5, "poste", 10)
		drum(Vector3(s * POSTS, top - 0.04, -0.055), 0.033, 0.03, 0.025, 0x2a2a2a, 10)
		solid(Vector3(s * POSTS, (top - 0.5) / 2.0, -0.055), Vector3(0.07, top + 0.5, 0.07))
		yard.append(spot(s * POSTS, -0.055))
	for y in [PLATE_LOW + 0.14, top - 0.14]:
		box(-POSTS - 0.06, y - 0.02, -0.035, POSTS * 2.0 + 0.12, 0.04, 0.012, "dorso")
	box(-PLATE.x / 2.0, PLATE_LOW, -0.023, PLATE.x, PLATE.y, 0.014, "dorso")
	var z := -0.0085
	quad(Vector3(-PLATE.x / 2.0, PLATE_LOW, z), Vector3(PLATE.x / 2.0, PLATE_LOW, z), Vector3(PLATE.x / 2.0, top, z), Vector3(-PLATE.x / 2.0, top, z),
		"hermanado", Vector3(0, 0, 1), [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	home()
	_commit()
