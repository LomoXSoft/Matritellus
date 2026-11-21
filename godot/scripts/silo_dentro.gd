extends "res://scripts/obra.gd"
## The inside of the Silo del Tío Anaranjao (silo.gd builds its wall and its gate on the Calle de San Agustín). The
## user, 21 November 2026: "Aparte de la fachada quiero que se pueda visitar por dentro (hay varias fotos 360 por
## dentro), con sus muebles y utensilios de como vivía antes la gente bajo tierra en la mancha". A set built far out in
## the fields, like the other places you go into by the green arrow (entradas.gd).
##
## What it is (the real Silo del Tío Colorao, from the 38 photos of its virtual tour of September 2019:
## tools/silo/tour360.py, referencias/silo/LEEME.md): a "silo" of La Mancha, houses dug into the ground. Inside the gate a
## long flight of cobbled steps (the "caño"; the real one is steps and then a ramp) goes down between whitewashed walls, a
## rope for a handrail on each, to a sunk court; round it, under the yard:
##   - on the left the stable (straw, a manger, harness, a yoke, baskets of esparto, tools of the field);
##   - at the end the first house: a cobbled hall, a kitchen with its tiled hearth under a valance of red gingham, a
##     pantry with its pots and pans, a bedroom of three beds under flowered bedspreads;
##   - on the right the second: a kitchen with its hearth under blue gingham and mats of esparto, an alcove with a
##     yellow bed behind a striped curtain, and a bedroom with a blue iron bed;
##   - a niche for firewood in the stairs' wall;
##   - a saffron flower in a pot, to be found in the last room.
## Nobody in it (the user polishes the characters himself). Everything is made here, of the kit's pieces.
##
## What a place you go into has to give (game.gd _use_door): `door_out`, `out_spawn`, `out_h` in the street; `in_door`
## and `in_spawn` in the set; `open`. It has several rooms: `room_at` tells entradas.gd's camera which one you are in.
## The set's frame: x to the right as you come in, +z deeper in, the gate at z = 0; y = 0 is the court's floor.

const INSIDE := Vector2(1560.0, -1120.0)        # where the set is (no street within 400 m; the other sets 330 m off or more)
const H0 := 4.6                                 # the yard, the street and the gate's landing over the court's floor (deep: the user, "hacer la cueva un poco más profunda")
const TW := 1.5                                 # half the width of the way down
const Z_LAND := 2.2                             # the landing inside the gate, to here
const Z_RAMP := 11.4                            # the stairs, to here: STEPS of them, cobbled, all the way down
const STEPS := 23
const Z_END := 15.4                             # the court, to here
const PARAPET := 0.7                            # the walls of the way down, over the yard
const YARD := Rect2(-10.0, -0.3, 22.0, 27.6)    # the yard over it all (x, z, wide, deep)

## the rooms: [name, x0, x1, z0, z1, how tall, floor, the wall the camera hangs on ("x0", "x1", "z0", "z1")]
const ROOMS: Array = [
	["rampa", -1.5, 1.5, 0.0, 11.4, 3.9, "", "z0"],
	["patio", -1.5, 1.5, 11.4, 15.4, 3.9, "", "z0"],
	["cuadra", -5.9, -1.9, 8.2, 12.8, 4.0, "tierra", "x1"],
	["portal", -2.2, 2.2, 15.8, 20.4, 4.15, "guijarro", "z0"],
	["cocina", -2.2, 2.2, 20.8, 24.8, 4.15, "barro", "z0"],
	["despensa", -5.2, -2.6, 21.0, 23.6, 3.95, "barro", "x1"],
	["alcoba", -6.4, -2.6, 13.8, 20.4, 4.1, "barro", "x1"],
	["cocina2", 1.9, 6.1, 11.1, 14.7, 4.1, "tierra", "x0"],
	["alcoba2", 6.5, 9.5, 11.3, 14.5, 4.0, "tierra", "x0"],
	["alcoba3", 6.2, 9.6, 14.9, 18.2, 4.0, "tierra", "z0"]]
## the ways between them: [room, wall, from, to (along the wall), how high, how thick the wall is there]
const DOORS: Array = [
	["cuadra", "x1", 11.5, 12.6, 1.95, 0.4],          # the stable, from the court
	["portal", "z0", 0.0, 1.0, 1.95, 0.4],            # the first house, at the court's end
	["portal", "x0", 18.4, 19.4, 1.95, 0.4],          # ...its bedroom
	["portal", "z1", -0.6, 0.6, 2.0, 0.4],            # ...its kitchen
	["cocina", "x0", 21.6, 22.6, 1.9, 0.4],           # ...its pantry
	["cocina2", "x0", 12.6, 13.6, 1.95, 0.4],         # the second house, from the court
	["cocina2", "x1", 12.2, 13.4, 1.95, 0.4],         # ...its alcove
	["alcoba2", "z1", 7.2, 8.2, 1.95, 0.4]]           # ...its bedroom

var door_out: Vector2
var out_spawn: Vector2
var out_h := 0.0
var in_door: Vector2
var in_spawn: Vector2
var open := true                # (a museum with its gate open: no hours for now)
var props := 0                  # how many pieces of furniture and tools it has (the self-test)
var saffron_spot := Vector2.ZERO        # the saffron flower hidden in its last room, on the map (ZERO: none)
var lamps := 0                  # its bulbs
var _sun: Array = []            # the materials of what stands in the open air (the sun lights those)

# ---------------- materials ----------------
func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: StandardMaterial3D = null
	var name: String = String(key) if key is String else ""
	match name:
		"cal", "cal_sol":   # whitewash, lumpy
			m = _glow(W._tmat(0xf7f5ef, "plaster", 2.4), 0.3 if name == "cal" else 0.12)
		"guijarro", "guijarro_sol":     # cobbles of the river, ochre and brown
			m = _glow(_cloth(_cobbles(), 0.8), 0.3 if name == "guijarro" else 0.05)
		"barro":            # floor tiles of fired clay
			m = _glow(_cloth(_tiles(), 0.6), 0.3)
		"tierra":           # beaten earth
			m = _glow(W._tmat(0xc9a878, "earth", 1.6), 0.3)
		"tierra_sol":       # the yard's earth
			m = W._tmat(0xc7a56f, "earth", 2.4)
		"paja":
			m = _glow(W._tmat(0xd9bd62, "earth", 0.5), 0.3)
		"esparto":
			m = _glow(_cloth(_weave(0xc9b274, 0xa89050), 0.16), 0.3)
		"vichy_rojo":
			m = _glow(_cloth(_checks(0xc8323a, 0xf4f0ea), 0.12), 0.35)
		"vichy_azul":
			m = _glow(_cloth(_checks(0x3f6fc0, 0xf4f0ea), 0.12), 0.35)
		"mantel":           # the kitchen's cloth: yellow and blue checks
			m = _glow(_cloth(_checks(0x6f8fc0, 0xf0e2a0), 0.16), 0.35)
		"rosas":            # the flowered bedspreads and cloths: roses on cream
			m = _glow(_cloth(_flowers(0xf6ecd8, 0xd8526a, 0x7a9a5a), 0.5), 0.35)
		"rosas_cortina":    # the flowered curtains
			m = _glow(_cloth(_flowers(0xefe6cc, 0xc85a78, 0x6f8f5a), 0.4), 0.35)
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"colcha_azul":      # the blue bed's spread: blue sprigs on white
			m = _glow(_cloth(_flowers(0xf2f2f4, 0x3a5aa8, 0x3a5aa8), 0.3), 0.35)
		"rayas":            # the striped curtain: pink and cream
			m = _glow(_cloth(_stripes(0xe9b0a8, 0xf4ead8), 0.24), 0.35)
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"damasco":          # the red curtain and the red covers
			m = _glow(_cloth(_flowers(0xb8283a, 0xe07a86, 0xe07a86), 0.3), 0.35)
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"azulejo":          # the hearth's tiles: white with yellow and blue points
			m = _glow(_cloth(_hearth_tiles(), 0.3), 0.35)
		"madera":
			m = _glow(Tex.mat("old_planks_02", Color(0.62, 0.44, 0.28)), 0.3)
		"madera_sol":       # the gates, in the open air
			m = Tex.mat("old_planks_02", Color(0.5, 0.36, 0.24))
		"calle":            # the street's light beyond the gate
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.86, 0.93, 1.0)
			m.emission_enabled = true
			m.emission = Color(0.86, 0.93, 1.0)
			m.emission_energy_multiplier = 1.2
		"luz":              # a lit bulb
			m = StandardMaterial3D.new()
			m.albedo_color = Color(1.0, 0.95, 0.8)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.9, 0.65)
			m.emission_energy_multiplier = 2.2
		"brasa":            # the embers
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.9, 0.3, 0.1)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.4, 0.1)
			m.emission_energy_multiplier = 1.4
		_:
			var pm := Parts.mat(int(key)).duplicate() as StandardMaterial3D      # (plain colours: they show in the dark of the caves too)
			pm.emission_enabled = true
			pm.emission = pm.albedo_color
			pm.emission_energy_multiplier = 0.28
			_mats[key] = pm
			return pm
	_mats[key] = m
	if name.ends_with("_sol") or name == "calle":
		_sun.append(m)
	return m

## a little picture made into a cloth or a floor: `metres` a repeat, laid by the world's own axes
func _cloth(img: Image, metres: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / metres
	m.roughness = 1.0
	return m

func _checks(a: int, b: int) -> Image:
	var img := Image.create(4, 4, false, Image.FORMAT_RGB8)
	var mix: Color = Parts.col(a).lerp(Parts.col(b), 0.5)
	for y in range(4):
		for x in range(4):
			var dark := (x < 2) and (y < 2)
			var pale := (x >= 2) and (y >= 2)
			img.set_pixel(x, y, Parts.col(a) if dark else (Parts.col(b) if pale else mix))
	img.generate_mipmaps()
	return img

func _stripes(a: int, b: int) -> Image:
	var img := Image.create(8, 2, false, Image.FORMAT_RGB8)
	for x in range(8):
		for y in range(2):
			img.set_pixel(x, y, Parts.col(a) if x in [0, 1, 4] else Parts.col(b))
	img.generate_mipmaps()
	return img

func _weave(a: int, b: int) -> Image:
	var img := Image.create(8, 8, false, Image.FORMAT_RGB8)
	for y in range(8):
		for x in range(8):
			img.set_pixel(x, y, Parts.col(a) if ((x >> 1) + (y >> 1)) % 2 == 0 else Parts.col(b))
	img.generate_mipmaps()
	return img

func _flowers(ground: int, flower: int, leaf: int) -> Image:
	var img := Image.create(16, 16, false, Image.FORMAT_RGB8)
	img.fill(Parts.col(ground))
	for f in [[3, 3], [11, 5], [6, 11], [13, 13]]:
		var fx: int = f[0]
		var fy: int = f[1]
		for d in [[0, 0], [1, 0], [0, 1], [-1, 0], [0, -1]]:
			img.set_pixel((fx + int(d[0]) + 16) % 16, (fy + int(d[1]) + 16) % 16, Parts.col(flower))
		img.set_pixel((fx + 2) % 16, (fy + 1) % 16, Parts.col(leaf))
		img.set_pixel((fx + 15) % 16, (fy + 2) % 16, Parts.col(leaf))
	img.generate_mipmaps()
	return img

func _tiles() -> Image:
	var img := Image.create(16, 16, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for ty in range(2):
		for tx in range(2):
			var c: Color = Parts.col(0xb8683e).lerp(Parts.col(0xd08a58), rng.randf())
			for y in range(8):
				for x in range(8):
					img.set_pixel(tx * 8 + x, ty * 8 + y, Parts.col(0x8a6248) if (x == 0 or y == 0) else c.darkened(rng.randf() * 0.06))
	img.generate_mipmaps()
	return img

func _cobbles() -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	img.fill(Parts.col(0x7a6044))
	for gy in range(8):
		for gx in range(8):
			var c: Color = [Parts.col(0xc9a25c), Parts.col(0xb8864a), Parts.col(0xa8763e), Parts.col(0xd4b478), Parts.col(0xbf9456)][rng.randi() % 5]
			var ox := gx * 4 + (2 if gy % 2 == 1 else 0)
			var oy := gy * 4
			for y in range(3):
				for x in range(3):
					img.set_pixel((ox + x) % 32, (oy + y) % 32, c.darkened(rng.randf() * 0.12))
	img.generate_mipmaps()
	return img

func _hearth_tiles() -> Image:
	var img := Image.create(8, 8, false, Image.FORMAT_RGB8)
	img.fill(Parts.col(0xf2f0ea))
	for i in range(4):
		for j in range(i + 1):
			img.set_pixel(j, 7 - i + j if 7 - i + j < 8 else 7, Parts.col(0xe0b83a))
			img.set_pixel(7 - j, i - j, Parts.col(0x3a62b0))
	for i in range(8):
		img.set_pixel(i, 0, Parts.col(0xd0ccc4))
		img.set_pixel(0, i, Parts.col(0xd0ccc4))
	img.generate_mipmaps()
	return img

# ---------------- building it ----------------
## its gate in the street, where you come out to and which way you face there
func build(world, at: Vector2, out: Vector2, heading: float) -> void:
	W = world
	door_out = at
	out_spawn = out
	out_h = heading
	var top := -1e9
	for dx in range(int(YARD.position.x) - 2, int(YARD.end.x) + 3, 3):
		for dz in range(int(YARD.position.y) - 2, int(YARD.end.y) + 3, 3):
			top = maxf(top, MapData.height(INSIDE + Vector2(dx, dz)))
	level = top + 0.03
	# what is walked on: the landing, the steps and the ramp (each sloping its own way), then the floor of it all
	var o := INSIDE
	_deck(Rect2(-TW, -0.3, 2.0 * TW, Z_LAND + 0.3), H0, Vector2.ZERO)
	_deck(Rect2(-TW, Z_LAND, 2.0 * TW, Z_RAMP - Z_LAND), H0 - H0 / STEPS / 2.0, Vector2(0.0, -H0 / (Z_RAMP - Z_LAND)))      # (half a step low: the slope runs through the steps' middles)
	_deck(YARD.grow(1.0), 0.0, Vector2.ZERO)
	transform = Transform3D(Basis.IDENTITY, Vector3(o.x, level, o.y))
	W.add_child(self)
	in_door = o + Vector2(0.0, 0.45)
	in_spawn = o + Vector2(0.0, 1.7)
	_yard()
	_way_down()
	for r in ROOMS:
		if String(r[6]) != "":
			_room(r)
	for d in DOORS:
		_passage(d)
	_stable()
	_hall()
	_kitchen()
	_pantry()
	_bedroom()
	_kitchen2()
	_alcove2()
	_bedroom3()
	home()
	_commit()
	_indoors(self)

## a floor to walk on: a rectangle of the set (x, z), `top` over the court's floor at its near edge, sloping by `grad`
func _deck(r: Rect2, top: float, grad: Vector2) -> void:
	var a := INSIDE + r.position
	var ring := PackedVector2Array([a, a + Vector2(r.size.x, 0), a + r.size, a + Vector2(0, r.size.y)])
	var d := {"o": a, "poly": ring, "r2": r.size.length_squared() + 4.0, "top": level + top}
	if grad != Vector2.ZERO:
		d["grad"] = grad
	MapData.decks.append(d)

## everything but what stands in the open air is indoors: no sun on it (game.gd's render layer 11)
func _indoors(n: Node) -> void:
	if n is MeshInstance3D and not ((n as MeshInstance3D).material_override in _sun):
		(n as MeshInstance3D).layers = 1 << 10
	for c in n.get_children():
		_indoors(c)

## the room you are in, for entradas.gd's camera: the middle of the wall it hangs on, which way it looks, how big
func room_at(pp: Vector2) -> Dictionary:
	var p := pp - INSIDE
	var best: Array = []
	var bd := 1e9
	for r in ROOMS:
		var mid := Vector2((float(r[1]) + float(r[2])) / 2.0, (float(r[3]) + float(r[4])) / 2.0)
		var half := Vector2((float(r[2]) - float(r[1])) / 2.0, (float(r[4]) - float(r[3])) / 2.0)
		var q := (p - mid).abs() - half
		var d := maxf(q.x, q.y)                         # (how far outside it: below zero, inside)
		if d < bd:
			bd = d
			best = r
	var x0: float = best[1]
	var x1: float = best[2]
	var z0: float = best[3]
	var z1: float = best[4]
	var fwd := Vector2(0, 1)
	var at := Vector2((x0 + x1) / 2.0, z0)
	var half_w := (x1 - x0) / 2.0
	var deep := z1 - z0
	match String(best[7]):
		"z1":
			fwd = Vector2(0, -1); at = Vector2((x0 + x1) / 2.0, z1)
		"x0":
			fwd = Vector2(1, 0); at = Vector2(x0, (z0 + z1) / 2.0); half_w = (z1 - z0) / 2.0; deep = x1 - x0
		"x1":
			fwd = Vector2(-1, 0); at = Vector2(x1, (z0 + z1) / 2.0); half_w = (z1 - z0) / 2.0; deep = x1 - x0
	if String(best[0]) == "rampa":                  # (the stairs: the camera comes down them after you, a few steps behind and over the steps there)
		at = Vector2(0.0, clampf(p.y - 4.2, 0.0, Z_RAMP - 4.2))
		deep = 7.0
	return {"o": INSIDE + at, "fwd": fwd, "side": Vector2(-fwd.y, fwd.x), "half": half_w, "deep": deep, "tall": float(best[5]), "name": String(best[0])}

## how high the way down's floor is at z (over the court's)
func way_y(z: float) -> float:
	if z <= Z_LAND:
		return H0
	if z <= Z_RAMP:
		return H0 * (1.0 - (z - Z_LAND) / (Z_RAMP - Z_LAND))
	return 0.0

# ---------------- the yard and the way down ----------------
## The yard over it all: earth, the white wall round it under its coping of tiles, the gate behind you with its leaves
## open on the street's light; two chimneys of the kitchens below.
func _yard() -> void:
	var x0 := YARD.position.x
	var x1 := YARD.end.x
	var z0 := YARD.position.y
	var z1 := YARD.end.y
	var e := TW + 0.4                               # (the way down's walls are 0.4 thick)
	for q in [[x0, -e, z0, z1], [e, x1, z0, z1], [-e, e, Z_END + 0.4, z1], [-e, e, z0, 0.0]]:
		quad(Vector3(q[0], H0, q[2]), Vector3(q[1], H0, q[2]), Vector3(q[1], H0, q[3]), Vector3(q[0], H0, q[3]), "tierra_sol", Vector3.UP)
	var tall := 2.4
	for w in [[Vector2(x0, z1), Vector2(x1, z1)], [Vector2(x0, z0), Vector2(x0, z1)], [Vector2(x1, z0), Vector2(x1, z1)], [Vector2(x0, z0), Vector2(-1.15, z0)], [Vector2(1.15, z0), Vector2(x1, z0)]]:
		var a: Vector2 = w[0]
		var b: Vector2 = w[1]
		var mid := (a + b) / 2.0
		var size := Vector3(absf(b.x - a.x) + 0.3, tall, absf(b.y - a.y) + 0.3)
		cbox(Vector3(mid.x, H0 + tall / 2.0, mid.y), size, "cal_sol")
		cbox(Vector3(mid.x, H0 + tall + 0.06, mid.y), size * Vector3(1, 0, 1) + Vector3(0.16, 0.12, 0.16), 0xb5653f)      # (its coping of tiles)
		solid(Vector3(mid.x, H0 + tall / 2.0, mid.y), size)
	cbox(Vector3(0.0, H0 + 2.35, z0), Vector3(2.6, 0.1 + tall - 2.25 + 0.0, 0.3), "cal_sol")                     # (over the gate)
	box(-1.15, H0, z0 - 0.18, 2.3, 2.25, 0.02, "calle")                                                       # the street's light
	solid(Vector3(0.0, H0 + 1.2, z0 - 0.3), Vector3(2.6, 2.4, 0.3))
	for sx in [-1.0, 1.0]:                           # the leaves of the gate, open against the wall: planks and nails
		var keep := _xf
		_xf = Transform3D(Basis(Vector3.UP, sx * 1.35), Vector3(sx * 1.15, H0, z0 + 0.12))
		box(-1.12 if sx > 0 else 0.0, 0.03, -0.04, 1.12, 2.2, 0.07, "madera_sol")
		for i in range(4):
			for j in range(5):
				ball(Vector3((-0.98 + i * 0.28) if sx > 0 else (0.14 + i * 0.28), 0.3 + j * 0.42, 0.045), 0.022, 0x2a2622, 1.0, 6, 3)
		_xf = keep
	for c in [Vector2(0.4, 24.4), Vector2(4.6, 14.6)]:                # the kitchens' chimneys
		var cc: Vector2 = c
		drum(Vector3(cc.x, H0, cc.y), 0.42, 0.3, 1.5, "cal_sol", 10)
		drum(Vector3(cc.x, H0 + 1.5, cc.y), 0.36, 0.36, 0.08, 0xb5653f, 10)
		solid(Vector3(cc.x, H0 + 0.8, cc.y), Vector3(0.7, 1.6, 0.7))

## The way down: the landing, a long flight of cobbled steps and the court, between white walls that rise as it sinks,
## a low wall over them in the yard; a rope on rings along each; the doors' frames, the window, the firewood, the trough.
func _way_down() -> void:
	var top := H0 + PARAPET
	# the floor: landing, steps, court
	quad(Vector3(-TW, H0, 0), Vector3(TW, H0, 0), Vector3(TW, H0, Z_LAND), Vector3(-TW, H0, Z_LAND), "guijarro_sol", Vector3.UP)
	for i in range(STEPS):
		var za := Z_LAND + (Z_RAMP - Z_LAND) * i / STEPS
		var zb := Z_LAND + (Z_RAMP - Z_LAND) * (i + 1) / STEPS
		var y := H0 * (1.0 - float(i + 1) / STEPS)
		box(-TW, y - 0.5, za, 2.0 * TW, 0.5, zb - za, "cal_sol")
		box(-TW, y, za + 0.03, 2.0 * TW, 0.012, zb - za - 0.03, "guijarro_sol")
	quad(Vector3(-TW, 0, Z_RAMP), Vector3(TW, 0, Z_RAMP), Vector3(TW, 0, Z_END), Vector3(-TW, 0, Z_END), "guijarro_sol", Vector3.UP)
	# its walls: each side in stretches, from the floor there to the top, leaving the doors, the window and the niche
	var holes := {-1.0: [[11.5, 12.6, 1.95], [14.0, 14.6, -1.0]], 1.0: [[9.5, 10.7, 1.5], [12.6, 13.6, 1.95]]}
	for sx in [-1.0, 1.0]:
		var x: float = sx * TW
		var marks: Array = [Z_LAND, Z_RAMP, Z_END]            # (where a stretch of wall ends: every 0.6 m, and at each hole's edge)
		for h in holes[sx]:
			marks.append(float(h[0]))
			marks.append(float(h[1]))
		var zm := 0.0
		while zm < Z_END:
			marks.append(zm)
			zm += 0.6
		marks.sort()
		for mi in range(marks.size() - 1):
			var z: float = marks[mi]
			var zb: float = marks[mi + 1]
			if zb - z < 0.005:
				continue
			var ya := way_y(z) - 0.02
			var yb := way_y(zb) - 0.02
			var low := 0.0                             # (a hole in this stretch: up to where)
			var sill := 0.0
			for h in holes[sx]:
				if (z + zb) / 2.0 > float(h[0]) and (z + zb) / 2.0 < float(h[1]):
					low = absf(float(h[2])) if float(h[2]) > 0.0 else 1.75
					sill = 0.0 if float(h[2]) > 0.0 else 1.1
			var base_a := ya + low if low > 0.0 else ya
			var base_b := yb + low if low > 0.0 else yb
			quad(Vector3(x, base_a, z), Vector3(x, base_b, zb), Vector3(x, top, zb), Vector3(x, top, z), "cal_sol", Vector3(-sx, 0, 0))
			if sill > 0.0:
				quad(Vector3(x, ya, z), Vector3(x, yb, zb), Vector3(x, yb + sill, zb), Vector3(x, ya + sill, z), "cal_sol", Vector3(-sx, 0, 0))
			if low <= 0.0 or sill > 0.0:
				solid(Vector3(x + sx * 0.2, (minf(ya, yb) + top) / 2.0, (z + zb) / 2.0), Vector3(0.4, top - minf(ya, yb), zb - z + 0.02))
		box(x if sx > 0 else x - 0.4, H0, 0.0, 0.4, PARAPET, Z_END + 0.4, "cal_sol")           # the low wall in the yard, its top rounded
		var keep := _xf
		_xf = Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(x + sx * 0.2, top, 0.0))
		drum(Vector3.ZERO, 0.2, 0.2, Z_END + 0.4, "cal_sol", 8)
		_xf = keep
		# the rope, hung on iron rings a hand above the hip
		var prev := Vector3.ZERO
		var first := true
		var zz := 2.4
		while zz <= 11.2:
			var ring := Vector3(x - sx * 0.06, way_y(zz) + 1.0, zz)
			drum(Vector3(ring.x, ring.y - 0.03, ring.z), 0.05, 0.05, 0.03, 0x2a2826, 6)
			if not first:
				var m := (prev + ring) / 2.0 - Vector3(0, 0.14, 0)
				bar(prev, m, 0.035, 0.035, 0xb89a62)
				bar(m, ring, 0.035, 0.035, 0xb89a62)
			prev = ring
			first = false
			zz += 2.2
	# the end wall, over the first house's door
	quad(Vector3(-TW, 0, Z_END), Vector3(0.0, 0, Z_END), Vector3(0.0, top, Z_END), Vector3(-TW, top, Z_END), "cal_sol", Vector3(0, 0, -1))
	quad(Vector3(1.0, 0, Z_END), Vector3(TW, 0, Z_END), Vector3(TW, top, Z_END), Vector3(1.0, top, Z_END), "cal_sol", Vector3(0, 0, -1))
	quad(Vector3(0.0, 1.95, Z_END), Vector3(1.0, 1.95, Z_END), Vector3(1.0, top, Z_END), Vector3(0.0, top, Z_END), "cal_sol", Vector3(0, 0, -1))
	box(-TW - 0.4, H0, Z_END, 2.0 * TW + 0.8, PARAPET, 0.4, "cal_sol")
	solid(Vector3(-0.75, top / 2.0, Z_END + 0.2), Vector3(1.5, top, 0.4))
	solid(Vector3(1.25, top / 2.0, Z_END + 0.2), Vector3(0.5, top, 0.4))
	# the window's grille and its tunnel to the bedroom; the frames of the doors
	for i in range(4):
		box(-TW + 0.02, 1.1, 14.06 + i * 0.16, 0.02, 0.65, 0.02, 0x2a2826)
	for j in range(3):
		box(-TW + 0.02, 1.2 + j * 0.22, 14.0, 0.02, 0.02, 0.6, 0x2a2826)
	box(-TW - 1.1, 1.1, 14.0, 1.1, 0.02, 0.6, "cal_sol")
	box(-TW - 1.1, 1.75, 14.0, 1.1, 0.02, 0.6, "cal_sol")
	for z in [14.0 - 0.02, 14.6]:
		box(-TW - 1.1, 1.1, z, 1.1, 0.67, 0.02, "cal_sol")
	for f in [[-TW, 11.5, 12.6], [TW, 12.6, 13.6]]:
		var fx: float = f[0]
		for z in [float(f[1]), float(f[2]) - 0.07]:
			box(fx - 0.04, 0.0, z, 0.08, 1.95, 0.07, "madera_sol")
		box(fx - 0.04, 1.9, float(f[1]), 0.08, 0.08, float(f[2]) - float(f[1]), "madera_sol")
	# the niche of the firewood, and its logs
	var ny := way_y(10.1)
	box(TW, ny, 9.5, 0.9, 0.02, 1.2, "tierra_sol")
	box(TW + 0.9, ny, 9.5, 0.02, 1.5, 1.2, "cal_sol")
	box(TW, ny + 1.5, 9.5, 0.9, 0.02, 1.2, "cal_sol")
	for z in [9.5 - 0.02, 10.7]:
		box(TW, ny, z, 0.9, 1.5, 0.02, "cal_sol")
	for i in range(9):
		var lz := 9.62 + (i % 3) * 0.36
		var ly := ny + 0.08 + floorf(i / 3.0) * 0.15
		bar(Vector3(TW + 0.1, ly, lz + 0.05 * (i % 2)), Vector3(TW + 0.8, ly + 0.02, lz + 0.1), 0.13, 0.13, 0x8a6a48 if i % 2 == 0 else 0x9a7a55, 0.4 * i)
	solid(Vector3(TW + 0.45, ny + 0.4, 10.1), Vector3(0.9, 0.9, 1.2))
	props += 1
	# the low round wall by the door at the end (a little trough)
	_arc_wall(Vector2(-1.0, Z_END), 0.5, PI, TAU, 0.0, 0.42, "cal_sol")
	solid(Vector3(-1.0, 0.2, Z_END - 0.3), Vector3(1.0, 0.42, 0.6))

## a low curved wall about c from angle a0 to a1 (radians from +x towards +z), 0.12 thick
func _arc_wall(c: Vector2, r: float, a0: float, a1: float, y0: float, y1: float, key) -> void:
	pieces += 1
	var n := 10
	for i in range(n):
		var t0 := lerpf(a0, a1, float(i) / n)
		var t1 := lerpf(a0, a1, float(i + 1) / n)
		var o0 := c + Vector2(cos(t0), sin(t0)) * r
		var o1 := c + Vector2(cos(t1), sin(t1)) * r
		var i0 := c + Vector2(cos(t0), sin(t0)) * (r - 0.12)
		var i1 := c + Vector2(cos(t1), sin(t1)) * (r - 0.12)
		var nm := Vector3(cos((t0 + t1) / 2.0), 0, sin((t0 + t1) / 2.0))
		quad(Vector3(o0.x, y0, o0.y), Vector3(o1.x, y0, o1.y), Vector3(o1.x, y1, o1.y), Vector3(o0.x, y1, o0.y), key, nm)
		quad(Vector3(i0.x, y0, i0.y), Vector3(i1.x, y0, i1.y), Vector3(i1.x, y1, i1.y), Vector3(i0.x, y1, i0.y), key, -nm)
		quad(Vector3(i0.x, y1, i0.y), Vector3(i1.x, y1, i1.y), Vector3(o1.x, y1, o1.y), Vector3(o0.x, y1, o0.y), key, Vector3.UP)

# ---------------- the rooms ----------------
## the holes in a room's wall: [[from, to, how high], ...]
func _holes(room: String, wall: String) -> Array:
	var out: Array = []
	for d in DOORS:
		if String(d[0]) == room and String(d[1]) == wall:
			out.append([float(d[2]), float(d[3]), float(d[4])])
	# the other side of a way through: the room it leads to has the hole too
	var r := _rect(room)
	for d in DOORS:
		var other := _rect(String(d[0]))
		var w := String(d[1])
		if String(d[0]) == room:
			continue
		var th: float = d[5]
		if w == "x1" and wall == "x0" and absf(other.end.x + th - r.position.x) < 0.05:
			out.append([float(d[2]), float(d[3]), float(d[4])])
		elif w == "x0" and wall == "x1" and absf(other.position.x - th - r.end.x) < 0.05:
			out.append([float(d[2]), float(d[3]), float(d[4])])
		elif w == "z1" and wall == "z0" and absf(other.end.y + th - r.position.y) < 0.05:
			out.append([float(d[2]), float(d[3]), float(d[4])])
		elif w == "z0" and wall == "z1" and absf(other.position.y - th - r.end.y) < 0.05:
			out.append([float(d[2]), float(d[3]), float(d[4])])
	var lo := r.position.y if wall in ["x0", "x1"] else r.position.x        # (only the ones that fall within this wall)
	var hi := r.end.y if wall in ["x0", "x1"] else r.end.x
	return out.filter(func(h): return float(h[0]) > lo + 0.01 and float(h[1]) < hi - 0.01)

func _rect(room: String) -> Rect2:
	for r in ROOMS:
		if String(r[0]) == room:
			return Rect2(float(r[1]), float(r[3]), float(r[2]) - float(r[1]), float(r[4]) - float(r[3]))
	return Rect2()

## A room dug out of the ground: its floor, its four walls with their ways through, a ceiling with its long sides
## rounded off, all whitewashed; solids behind the walls.
func _room(r: Array) -> void:
	var name: String = r[0]
	var x0: float = r[1]
	var x1: float = r[2]
	var z0: float = r[3]
	var z1: float = r[4]
	var tall: float = r[5]
	quad(Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3(x1, 0, z1), Vector3(x0, 0, z1), String(r[6]), Vector3.UP)
	var c := 1.0                                        # (how much of the ceiling's edge is rounded off: a vault, high over whoever looks down from under it)
	var along_z := (z1 - z0) >= (x1 - x0)               # (the vault runs along the longer side)
	if along_z:
		quad(Vector3(x0 + c, tall, z0), Vector3(x1 - c, tall, z0), Vector3(x1 - c, tall, z1), Vector3(x0 + c, tall, z1), "cal", Vector3.DOWN)
		quad(Vector3(x0, tall - c, z0), Vector3(x0 + c, tall, z0), Vector3(x0 + c, tall, z1), Vector3(x0, tall - c, z1), "cal", Vector3(1, -1, 0).normalized())
		quad(Vector3(x1, tall - c, z0), Vector3(x1 - c, tall, z0), Vector3(x1 - c, tall, z1), Vector3(x1, tall - c, z1), "cal", Vector3(-1, -1, 0).normalized())
	else:
		quad(Vector3(x0, tall, z0 + c), Vector3(x1, tall, z0 + c), Vector3(x1, tall, z1 - c), Vector3(x0, tall, z1 - c), "cal", Vector3.DOWN)
		quad(Vector3(x0, tall - c, z0), Vector3(x1, tall - c, z0), Vector3(x1, tall, z0 + c), Vector3(x0, tall, z0 + c), "cal", Vector3(0, -1, 1).normalized())
		quad(Vector3(x0, tall - c, z1), Vector3(x1, tall - c, z1), Vector3(x1, tall, z1 - c), Vector3(x0, tall, z1 - c), "cal", Vector3(0, -1, -1).normalized())
	_side(Vector2(x0, z0), Vector2(x1, z0), H0, Vector3(0, 0, 1), _holes(name, "z0"), true)       # (on up to the yard: the ceiling hides that from below, and from above no gap is left)
	_side(Vector2(x0, z1), Vector2(x1, z1), H0, Vector3(0, 0, -1), _holes(name, "z1"), true)
	_side(Vector2(x0, z0), Vector2(x0, z1), H0, Vector3(1, 0, 0), _holes(name, "x0"), false)
	_side(Vector2(x1, z0), Vector2(x1, z1), H0, Vector3(-1, 0, 0), _holes(name, "x1"), false)
	solid(Vector3((x0 + x1) / 2.0, tall + 0.15, (z0 + z1) / 2.0), Vector3(x1 - x0, 0.3, z1 - z0))

## one wall of a room from a to b, facing `n`, with its holes (given along x if `along_x`, along z if not)
func _side(a: Vector2, b: Vector2, tall: float, n: Vector3, holes: Array, along_x: bool) -> void:
	var from := a.x if along_x else a.y
	var to := b.x if along_x else b.y
	var cuts: Array = [from]
	holes.sort_custom(func(p, q): return float(p[0]) < float(q[0]))
	for h in holes:
		cuts.append(float(h[0]))
		cuts.append(float(h[1]))
	cuts.append(to)
	for i in range(cuts.size() - 1):
		var s0: float = cuts[i]
		var s1: float = cuts[i + 1]
		if s1 - s0 < 0.01:
			continue
		var y0 := 0.0
		if i % 2 == 1:                                  # (a hole: only what is over it)
			y0 = float(holes[i >> 1][2])
		var p0 := Vector3(s0, y0, a.y) if along_x else Vector3(a.x, y0, s0)
		var p1 := Vector3(s1, y0, a.y) if along_x else Vector3(a.x, y0, s1)
		quad(p0, p1, p1 + Vector3(0, tall - y0, 0), p0 + Vector3(0, tall - y0, 0), "cal", n)
		if i % 2 == 0:
			var mid := (p0 + p1) / 2.0 - n * 0.2
			solid(Vector3(mid.x, tall / 2.0, mid.z), Vector3((s1 - s0) if along_x else 0.4, tall, 0.4 if along_x else (s1 - s0)))

## the way through a wall: its floor, its two cheeks and what is over it
func _passage(d: Array) -> void:
	var r := _rect(String(d[0]))
	var wall: String = d[1]
	var s0: float = d[2]
	var s1: float = d[3]
	var h: float = d[4]
	var th: float = d[5]
	var x0 := s0
	var x1 := s1
	var z0 := 0.0
	var z1 := 0.0
	match wall:
		"z0":
			z0 = r.position.y - th; z1 = r.position.y
		"z1":
			z0 = r.end.y; z1 = r.end.y + th
		"x0":
			x0 = r.position.x - th; x1 = r.position.x; z0 = s0; z1 = s1
		"x1":
			x0 = r.end.x; x1 = r.end.x + th; z0 = s0; z1 = s1
	var key := "guijarro" if String(d[0]) == "portal" and wall == "z0" else "barro"
	if String(d[0]) in ["cuadra", "cocina2", "alcoba2"]:
		key = "tierra"
	quad(Vector3(x0, 0.004, z0), Vector3(x1, 0.004, z0), Vector3(x1, 0.004, z1), Vector3(x0, 0.004, z1), key, Vector3.UP)
	quad(Vector3(x0, h, z0), Vector3(x1, h, z0), Vector3(x1, h, z1), Vector3(x0, h, z1), "cal", Vector3.DOWN)
	if wall in ["z0", "z1"]:
		quad(Vector3(x0, 0, z0), Vector3(x0, 0, z1), Vector3(x0, h, z1), Vector3(x0, h, z0), "cal", Vector3(1, 0, 0))
		quad(Vector3(x1, 0, z0), Vector3(x1, 0, z1), Vector3(x1, h, z1), Vector3(x1, h, z0), "cal", Vector3(-1, 0, 0))
	else:
		quad(Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3(x1, h, z0), Vector3(x0, h, z0), "cal", Vector3(0, 0, 1))
		quad(Vector3(x0, 0, z1), Vector3(x1, 0, z1), Vector3(x1, h, z1), Vector3(x0, h, z1), "cal", Vector3(0, 0, -1))

# ---------------- furniture and tools ----------------
## where a piece stands: `at` its foot, turned `yaw` about the upright (until home())
func _put(at: Vector3, yaw := 0.0) -> void:
	_xf = Transform3D(Basis(Vector3.UP, yaw), at)
	props += 1

## a chair of turned wood with a seat of rush: `low` for the ones by the fire
func _chair(at: Vector3, yaw: float, low := false, wood := 0x9a6a3a) -> void:
	_put(at, yaw)
	var sh := 0.3 if low else 0.44
	var bh := 0.72 if low else 0.95
	for sx in [-0.19, 0.19]:
		box(sx - 0.02, 0.0, -0.19, 0.04, sh, 0.04, wood)
		box(sx - 0.02, 0.0, 0.15, 0.04, bh, 0.04, wood)
		box(sx - 0.015, sh * 0.45, -0.17, 0.03, 0.03, 0.34, wood)
	box(-0.19, sh * 0.45, -0.185, 0.38, 0.03, 0.03, wood)
	box(-0.21, sh, -0.21, 0.42, 0.04, 0.4, 0xd9c27a)                 # (the rush)
	for y in [sh + 0.16, sh + 0.3, bh - 0.06]:
		if y < bh:
			box(-0.19, y, 0.155, 0.38, 0.05, 0.025, wood)
	home()
	solid(at + Vector3(0, 0.3, 0), Vector3(0.45, 0.6, 0.45))

## a table under its cloth, which hangs half way down
func _table(at: Vector3, yaw: float, w: float, d: float, h: float, cloth) -> void:
	_put(at, yaw)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			box(sx * (w / 2.0 - 0.06) - 0.025, 0.0, sz * (d / 2.0 - 0.06) - 0.025, 0.05, h, 0.05, 0x7a5232)
	box(-w / 2.0, h - 0.04, -d / 2.0, w, 0.04, d, 0x8a6240)
	var o := 0.05
	box(-w / 2.0 - o, h, -d / 2.0 - o, w + 2.0 * o, 0.012, d + 2.0 * o, cloth)
	box(-w / 2.0 - o, h - 0.32, -d / 2.0 - o, w + 2.0 * o, 0.32, 0.012, cloth)
	box(-w / 2.0 - o, h - 0.32, d / 2.0 + o - 0.012, w + 2.0 * o, 0.32, 0.012, cloth)
	box(-w / 2.0 - o, h - 0.32, -d / 2.0 - o, 0.012, 0.32, d + 2.0 * o, cloth)
	box(w / 2.0 + o - 0.012, h - 0.32, -d / 2.0 - o, 0.012, 0.32, d + 2.0 * o, cloth)
	home()
	solid(at + Vector3(0, h / 2.0, 0), Vector3(w, h, d), yaw)

## A bed of iron: its head at -z of its own frame, w wide and l long; the rails of head and foot, the mattress, the
## spread hanging at the sides, the pillow.
func _bed(at: Vector3, yaw: float, w: float, l: float, iron, spread, brass := false) -> void:
	_put(at, yaw)
	var knob = 0xc9a23a if brass else iron
	for e in [[-l / 2.0, 1.15], [l / 2.0, 0.8]]:
		var z: float = e[0]
		var hh: float = e[1]
		for sx in [-1.0, 1.0]:
			box(sx * (w / 2.0) - 0.02, 0.0, z - 0.02, 0.04, hh, 0.04, iron)
			ball(Vector3(sx * (w / 2.0), hh + 0.03, z), 0.04, knob, 1.0, 6, 4)
		box(-w / 2.0, hh - 0.06, z - 0.015, w, 0.03, 0.03, knob)
		box(-w / 2.0, 0.5, z - 0.015, w, 0.03, 0.03, iron)
		var n := int(w / 0.14)
		for i in range(1, n):
			box(-w / 2.0 + i * w / n - 0.008, 0.5, z - 0.008, 0.016, hh - 0.56, 0.016, iron)
	box(-w / 2.0 + 0.02, 0.3, -l / 2.0 + 0.03, w - 0.04, 0.2, l - 0.06, 0xf2efe8)           # (the mattress)
	box(-w / 2.0 - 0.03, 0.2, -l / 2.0 + 0.5, w + 0.06, 0.32, l - 0.52, spread)             # (the spread, down the sides)
	box(-w / 2.0 + 0.08, 0.5, -l / 2.0 + 0.08, w - 0.16, 0.1, 0.38, 0xfbfaf6)                # (the pillow)
	home()
	solid(at + Vector3(0, 0.35, 0), Vector3(w + 0.1, 0.7, l + 0.06), yaw)

## a chest of wood, a cloth over it
func _chest(at: Vector3, yaw: float, w: float, d: float, h: float, cover = null) -> void:
	_put(at, yaw)
	box(-w / 2.0, 0.06, -d / 2.0, w, h - 0.06, d, 0x6f4a2c)
	for sx in [-1.0, 1.0]:
		box(sx * (w / 2.0 - 0.05) - 0.04, 0.0, -d / 2.0 + 0.02, 0.08, 0.06, d - 0.04, 0x4f3420)
	box(-w / 2.0 - 0.01, h * 0.45, -d / 2.0 - 0.01, w + 0.02, 0.03, d + 0.02, 0x3a2a1c)
	if cover != null:
		box(-w / 2.0 - 0.03, h, -d / 2.0 - 0.03, w + 0.06, 0.02, d + 0.06, cover)
		box(-w / 2.0 - 0.03, h - 0.22, -d / 2.0 - 0.03, w + 0.06, 0.22, 0.012, cover)
	home()
	solid(at + Vector3(0, h / 2.0, 0), Vector3(w, h, d), yaw)

## a washstand: three legs of iron, the white basin in its ring, the jug under it
func _washstand(at: Vector3) -> void:
	_put(at)
	for k in range(3):
		var a := TAU * k / 3.0
		bar(Vector3(cos(a) * 0.2, 0.0, sin(a) * 0.2), Vector3(cos(a) * 0.14, 0.74, sin(a) * 0.14), 0.02, 0.02, 0x2a2826)
	drum(Vector3(0, 0.72, 0), 0.12, 0.2, 0.1, 0xf6f4ee, 12)
	drum(Vector3(0, 0.815, 0), 0.17, 0.17, 0.006, 0xdfe8ea, 12)
	drum(Vector3(0, 0.12, 0), 0.07, 0.1, 0.16, 0xf6f4ee, 10)
	drum(Vector3(0, 0.28, 0), 0.1, 0.05, 0.1, 0xf6f4ee, 10)
	home()
	solid(at + Vector3(0, 0.4, 0), Vector3(0.4, 0.8, 0.4))

## a pot with its lid and two ears, or a deep pan
func _pot(at: Vector3, r: float, h: float, hex, lid := true) -> void:
	_put(at)
	drum(Vector3.ZERO, r * 0.92, r, h, hex, 12)
	if lid:
		drum(Vector3(0, h, 0), r * 1.03, r * 0.5, h * 0.22, hex, 12)
		ball(Vector3(0, h * 1.28, 0), r * 0.16, 0x1e1c1a, 1.0, 6, 3)
	for sx in [-1.0, 1.0]:
		box(sx * r - 0.02, h * 0.7, -0.03, 0.04, 0.02, 0.06, 0x1e1c1a)
	home()

## a bowl or a dish of clay, open
func _bowl(at: Vector3, r: float, h: float, hex) -> void:
	_put(at)
	drum(Vector3.ZERO, r * 0.5, r, h, hex, 12)
	drum(Vector3(0, h - 0.012, 0), r * 0.88, r * 0.88, 0.006, Parts.col(hex).darkened(0.25).to_rgba32() >> 8 if hex is int else hex, 12)
	home()

## a jar of clay for water, two ears
func _jar(at: Vector3, tall: float, hex) -> void:
	_put(at)
	drum(Vector3.ZERO, tall * 0.16, tall * 0.3, tall * 0.45, hex, 10)
	drum(Vector3(0, tall * 0.45, 0), tall * 0.3, tall * 0.12, tall * 0.33, hex, 10)
	drum(Vector3(0, tall * 0.78, 0), tall * 0.1, tall * 0.13, tall * 0.22, hex, 10)
	for sx in [-1.0, 1.0]:
		bar(Vector3(sx * tall * 0.13, tall * 0.9, 0), Vector3(sx * tall * 0.27, tall * 0.62, 0), 0.03, 0.03, hex)
	home()

## a basket of esparto with its two handles
func _basket(at: Vector3, r: float, h: float) -> void:
	_put(at)
	drum(Vector3.ZERO, r * 0.8, r, h, "esparto", 10)
	drum(Vector3(0, h - 0.02, 0), r * 0.9, r * 0.9, 0.01, 0x8a7440, 10)
	for sx in [-1.0, 1.0]:
		bar(Vector3(sx * r, h, -0.08), Vector3(sx * r * 1.05, h + 0.1, 0.0), 0.025, 0.025, 0xb89a62)
		bar(Vector3(sx * r * 1.05, h + 0.1, 0.0), Vector3(sx * r, h, 0.08), 0.025, 0.025, 0xb89a62)
	home()

## a picture on a wall: `at` its middle, `n` the way it faces
func _picture(at: Vector3, n: Vector3, w: float, h: float, frame, inside) -> void:
	_put(at, atan2(n.x, n.z))
	box(-w / 2.0, -h / 2.0, 0.0, w, h, 0.03, frame)
	box(-w / 2.0 + 0.04, -h / 2.0 + 0.04, 0.03, w - 0.08, h - 0.08, 0.004, inside)
	home()

## clothes on a nail: a coat or a smock hanging flat against the wall
func _coat(at: Vector3, n: Vector3, hex, long := 0.8) -> void:
	_put(at, atan2(n.x, n.z))
	box(-0.02, 0.0, 0.0, 0.04, 0.04, 0.05, 0x2a2826)
	box(-0.17, -0.2, 0.02, 0.34, 0.2, 0.07, hex)
	box(-0.21, -long, 0.02, 0.42, long - 0.2, 0.09, hex)
	home()

## a curtain on its rod across a way through, from a to b at the top: drawn to the sides in two bunches, or one
func _curtain(a: Vector3, b: Vector3, drop: float, key, one_side := false) -> void:
	props += 1
	bar(a, b, 0.025, 0.025, 0x2a2826)
	var run := b - a
	var ln := run.length()
	var u := run / ln
	var w := ln * (0.42 if one_side else 0.26)
	for e in ([0.0] if one_side else [0.0, 1.0]):
		var s: float = e
		var p := a + u * (s * (ln - w))
		for k in range(4):                                 # (its folds)
			var q := p + u * (w * k / 4.0)
			var out := Vector3(-u.z, 0, u.x) * (0.03 if k % 2 == 0 else -0.03)
			quad(q + out - Vector3(0, 0.02, 0), q + u * (w / 4.0) - out - Vector3(0, 0.02, 0), q + u * (w / 4.0) - out - Vector3(0, drop, 0), q + out - Vector3(0, drop, 0), key, Vector3(-u.z, 0, u.x))

## a bare bulb on its flex, lit, and the light it gives
func _bulb(at: Vector3, reach := 5.5) -> void:
	bar(at + Vector3(0, 0.02, 0), at + Vector3(0, 2.3, 0), 0.012, 0.012, 0x2a2826)       # (its flex, from the vault: black, as the user wants it)
	ball(at, 0.05, "luz", 1.2, 8, 5)
	var lamp := OmniLight3D.new()
	lamp.position = at - Vector3(0, 0.15, 0)
	lamp.light_color = Color(1.0, 0.9, 0.72)
	lamp.omni_range = reach
	lamp.light_energy = 0.55
	lamp.shadow_enabled = false
	lamp.light_cull_mask = 1 << 10
	add_child(lamp)
	lamps += 1

## A hearth against a wall: `at` the middle of its foot on the wall, facing `yaw`. The stone before it, the black of the
## fire's place between two jambs (tiled, or whitewashed), the hood over it with its shelf and its valance of gingham,
## plates on the shelf; the trivet, the pot, the tongs, the embers.
func _hearth(at: Vector3, yaw: float, valance, tiled: bool) -> void:
	_put(at, yaw)
	var jamb = "azulejo" if tiled else "cal"
	box(-0.95, 0.0, 0.0, 1.9, 0.07, 0.95, 0x8a8076)                        # the hearthstone
	box(-0.42, 0.07, 0.0, 0.84, 1.25, 0.03, 0x1a1816)                      # the fire's place, black with soot
	for sx in [-1.0, 1.0]:
		box(sx * 0.56 - 0.14, 0.07, 0.0, 0.28, 1.25, 0.36, jamb)
	box(-0.8, 1.32, 0.0, 1.6, 0.9, 0.34, "cal")                             # the hood
	box(-0.45, 2.2, 0.0, 0.9, 2.3, 0.3, "cal")                              # (its flue, on up through the vault)
	box(-0.86, 1.3, 0.0, 1.72, 0.05, 0.46, 0x7a5232)                        # its shelf
	box(-0.86, 1.14, 0.45, 1.72, 0.17, 0.012, valance)                      # the valance
	box(-0.86, 1.14, 0.0, 0.012, 0.17, 0.46, valance)
	box(0.848, 1.14, 0.0, 0.012, 0.17, 0.46, valance)
	for i in range(4):                                                      # plates stood on the shelf
		var px := -0.6 + i * 0.4
		var keep := _xf
		_xf = _xf * Transform3D(Basis(Vector3.RIGHT, PI / 2.0 - 0.25), Vector3(px, 1.52, 0.2))
		drum(Vector3.ZERO, 0.15, 0.13, 0.02, 0xf4f1e8 if i % 2 == 0 else 0xe9dcc0, 12)
		drum(Vector3(0, 0.021, 0), 0.08, 0.08, 0.002, 0x4a6aa8 if i % 2 == 0 else 0xb0562c, 10)
		_xf = keep
	for k in range(3):                                                      # the trivet
		var a := TAU * k / 3.0 + 0.3
		box(cos(a) * 0.15 - 0.012, 0.07, 0.42 + sin(a) * 0.15 - 0.012, 0.024, 0.16, 0.024, 0x1e1c1a)
	drum(Vector3(0, 0.23, 0.42), 0.17, 0.17, 0.012, 0x1e1c1a, 10)
	drum(Vector3(0, 0.242, 0.42), 0.1, 0.15, 0.2, 0x8a4a2c, 10)             # the pot of clay on it
	drum(Vector3(0, 0.44, 0.42), 0.12, 0.09, 0.05, 0x8a4a2c, 10)
	for k in range(3):                                                      # the embers and two logs
		ball(Vector3(-0.1 + k * 0.1, 0.1, 0.22 + 0.03 * k), 0.05, "brasa", 0.6, 6, 3)
	bar(Vector3(-0.3, 0.12, 0.16), Vector3(0.25, 0.15, 0.24), 0.09, 0.09, 0x4a3626)
	bar(Vector3(-0.2, 0.12, 0.3), Vector3(0.3, 0.13, 0.14), 0.08, 0.08, 0x3a2a1e)
	bar(Vector3(0.62, 0.07, 0.4), Vector3(0.72, 0.75, 0.37), 0.02, 0.02, 0x1e1c1a)       # the tongs, leant on the jamb
	bar(Vector3(0.66, 0.07, 0.44), Vector3(0.74, 0.75, 0.37), 0.02, 0.02, 0x1e1c1a)
	home()
	var f := Vector3(sin(yaw), 0, cos(yaw))
	solid(at + f * 0.25 + Vector3(0, 1.1, 0), Vector3(1.9, 2.2, 0.5), yaw)

## a shelf on the wall with its edging of gingham: `at` the middle of its back edge
func _shelf(at: Vector3, yaw: float, w: float, d: float, edging) -> void:
	_put(at, yaw)
	box(-w / 2.0, 0.0, 0.0, w, 0.03, d, 0xf0ece4)
	box(-w / 2.0, -0.09, d, w, 0.1, 0.01, edging)
	home()

## a mat of esparto on the floor
func _mat(x0: float, z0: float, w: float, d: float) -> void:
	props += 1
	box(x0, 0.0, z0, w, 0.014, d, "esparto")

## a round mat
func _round_mat(at: Vector2, r: float) -> void:
	props += 1
	drum(Vector3(at.x, 0.0, at.y), r, r, 0.014, "esparto", 14)

# ---------------- the stable ----------------
func _stable() -> void:
	var r := _rect("cuadra")
	var x0 := r.position.x
	var z0 := r.position.y
	var z1 := r.end.y
	# straw on the floor, a heap of it
	box(x0 + 0.3, 0.0, z0 + 0.4, 1.6, 0.03, 2.2, "paja")
	_put(Vector3(x0 + 1.0, 0.0, z0 + 1.0))
	ball(Vector3(0, 0.1, 0), 0.7, "paja", 0.7, 10, 5)
	home()
	solid(Vector3(x0 + 1.0, 0.2, z0 + 1.0), Vector3(1.0, 0.4, 1.0))
	# the manger along the far wall: whitewashed masonry, straw in it
	box(x0, 0.0, z0 + 1.9, 0.6, 0.75, 2.2, "cal")
	box(x0 + 0.08, 0.72, z0 + 1.98, 0.44, 0.04, 2.04, "paja")
	solid(Vector3(x0 + 0.3, 0.4, z0 + 3.0), Vector3(0.6, 0.8, 2.2))
	for z in [z0 + 2.3, z0 + 3.7]:                     # the rings the animals were tied to
		drum(Vector3(x0 + 0.02, 1.15, z), 0.06, 0.06, 0.02, 0x2a2826, 8)
	# a bench of masonry by the door wall, a stone trough, a low stool
	box(r.end.x - 1.5, 0.0, z0, 1.5, 0.42, 0.45, "cal")
	solid(Vector3(r.end.x - 0.75, 0.21, z0 + 0.22), Vector3(1.5, 0.42, 0.45))
	box(x0 + 2.0, 0.0, z1 - 0.55, 0.9, 0.32, 0.45, 0x9a948a)
	box(x0 + 2.06, 0.3, z1 - 0.49, 0.78, 0.03, 0.33, 0x6a6660)
	solid(Vector3(x0 + 2.45, 0.16, z1 - 0.32), Vector3(0.9, 0.32, 0.45))
	_put(Vector3(x0 + 2.6, 0.0, z0 + 1.4))
	for k in range(3):
		var a := TAU * k / 3.0
		bar(Vector3(cos(a) * 0.16, 0.0, sin(a) * 0.16), Vector3(cos(a) * 0.1, 0.26, sin(a) * 0.1), 0.035, 0.035, 0x7a5232)
	drum(Vector3(0, 0.26, 0), 0.17, 0.17, 0.04, 0x8a6240, 10)
	home()
	# baskets: two big panniers of esparto, a wide one, a basket hung on the wall
	_basket(Vector3(x0 + 0.5, 0.0, z0 + 4.25), 0.3, 0.5)
	_basket(Vector3(x0 + 1.2, 0.0, z0 + 4.2), 0.27, 0.42)
	_basket(Vector3(x0 + 3.4, 0.0, z0 + 0.9), 0.36, 0.22)
	_put(Vector3(x0 + 1.6, 1.25, z0 + 0.05))
	drum(Vector3(0, 0, 0.12), 0.2, 0.26, 0.3, "esparto", 10)
	box(-0.02, 0.3, 0.0, 0.04, 0.2, 0.04, 0x2a2826)
	home()
	# harness on the wall: two collars, bridles and their straps
	for k in range(2):
		_put(Vector3(x0 + 2.4 + k * 0.7, 1.2, z0 + 0.03))
		for i in range(8):
			var a0 := TAU * i / 8.0
			var a1 := TAU * (i + 1) / 8.0
			bar(Vector3(cos(a0) * 0.2, sin(a0) * 0.27, 0.05), Vector3(cos(a1) * 0.2, sin(a1) * 0.27, 0.05), 0.07, 0.07, 0x5a3a24 if k == 0 else 0x3a2a1e)
		bar(Vector3(0.1, -0.25, 0.05), Vector3(0.16, -0.75, 0.05), 0.02, 0.02, 0x2a1e16)
		bar(Vector3(-0.1, -0.25, 0.05), Vector3(-0.14, -0.7, 0.05), 0.02, 0.02, 0x2a1e16)
		home()
	# the yoke leant in the corner, a fork, a rake, sickles and a sieve on the wall
	_put(Vector3(x0 + 0.25, 0.0, z0 + 0.3))
	bar(Vector3(0, 0.0, 0), Vector3(0.25, 1.5, 0.1), 0.09, 0.07, 0x8a6240)
	bar(Vector3(0.2, 1.25, 0.08), Vector3(0.55, 1.2, 0.3), 0.08, 0.06, 0x8a6240)
	home()
	_put(Vector3(x0 + 3.85, 0.0, z0 + 0.25))
	bar(Vector3(0, 0, 0), Vector3(-0.2, 1.7, 0.0), 0.035, 0.035, 0xb89a62)
	for k in range(3):
		bar(Vector3(-0.2, 1.7, 0), Vector3(-0.32 + k * 0.1, 2.05, 0.0), 0.025, 0.025, 0xb89a62)
	home()
	_put(Vector3(x0 + 0.05, 1.5, z0 + 1.2), PI / 2.0)
	for k in range(2):                                  # (sickles: a handle and its hooked blade)
		var sx := k * 0.5
		bar(Vector3(sx, -0.2, 0.02), Vector3(sx, 0.0, 0.02), 0.035, 0.035, 0x7a5232)
		for i in range(5):
			var a0 := PI * i / 5.0
			var a1 := PI * (i + 1) / 5.0
			bar(Vector3(sx + 0.15 - cos(a0) * 0.15, sin(a0) * 0.2, 0.02), Vector3(sx + 0.15 - cos(a1) * 0.15, sin(a1) * 0.2, 0.02), 0.03, 0.012, 0x6a6a6e)
	home()
	_put(Vector3(x0 + 3.2, 1.45, z1 - 0.03), PI)
	drum(Vector3(0, 0, 0), 0.01, 0.01, 0.001, 0x2a2826, 4)
	var keep := _xf
	_xf = _xf * Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, 0, 0.0))
	drum(Vector3.ZERO, 0.24, 0.24, 0.07, 0xb89a62, 14)                    # (the sieve)
	drum(Vector3(0, 0.071, 0), 0.21, 0.21, 0.002, 0xd9c9a0, 14)
	_xf = keep
	home()
	props += 6
	_bulb(Vector3((r.position.x + r.end.x) / 2.0, 2.0, (z0 + z1) / 2.0))

# ---------------- the first house ----------------
## The hall: cobbles, the studded door open against the wall, chairs, the table under its flowered cloth, the meat safe
## on the wall, a string of peppers.
func _hall() -> void:
	var r := _rect("portal")
	var x0 := r.position.x
	var x1 := r.end.x
	var z0 := r.position.y
	var z1 := r.end.y
	_put(Vector3(1.02, 0.0, z0 + 0.02), -1.25)          # the door, open: planks, nails, its bar
	box(0.0, 0.02, 0.0, 0.98, 1.9, 0.06, "madera")
	for i in range(3):
		for j in range(5):
			ball(Vector3(0.16 + i * 0.33, 0.25 + j * 0.36, 0.065), 0.022, 0x2a2622, 1.0, 6, 3)
	box(0.1, 1.0, 0.065, 0.78, 0.05, 0.02, 0x2a2622)
	home()
	_table(Vector3(x1 - 0.75, 0.0, z0 + 2.3), 0.0, 0.9, 0.7, 0.74, "rosas")
	_chair(Vector3(x1 - 0.4, 0.0, z0 + 1.35), PI)
	_chair(Vector3(x1 - 0.4, 0.0, z0 + 3.3), 0.0)
	_chair(Vector3(x0 + 0.45, 0.0, z0 + 0.9), -PI / 2.0)
	_chair(Vector3(x0 + 0.45, 0.0, z0 + 1.8), -PI / 2.0)
	_put(Vector3(x0 + 0.45, 0.48, z0 + 1.8))            # a blue cloth folded on the chair
	box(-0.17, 0.0, -0.17, 0.34, 0.07, 0.34, 0x8aa8d0)
	home()
	_put(Vector3(x1 - 0.03, 1.6, z0 + 0.9), -PI / 2.0)  # the meat safe: a little cupboard of wood and wire
	box(-0.25, -0.3, 0.0, 0.5, 0.6, 0.28, 0x8a6240)
	box(-0.2, -0.25, 0.28, 0.4, 0.5, 0.004, 0xcfcab8)
	home()
	_put(Vector3(x0 + 0.03, 1.75, z0 + 2.3), PI / 2.0)  # the peppers, dried
	for k in range(6):
		ball(Vector3(0.03 * (k % 2), -k * 0.09, 0.05), 0.045, 0xa8281e, 1.5, 6, 4)
	home()
	_picture(Vector3(x0 + 0.02, 1.55, z0 + 1.35), Vector3(1, 0, 0), 0.3, 0.38, 0x7a5232, 0xd8c8a8)
	_jar(Vector3(-1.5, 0.0, z1 - 0.35), 0.55, 0xb0623a)
	_bulb(Vector3(0.0, 2.1, (z0 + z1) / 2.0))

## The kitchen: floor of fired clay, the hearth with its tiled jambs under red gingham, low chairs before it, the table
## under its checked cloth, a niche of plates, a holy picture, an apron on its nail.
func _kitchen() -> void:
	var r := _rect("cocina")
	var x0 := r.position.x
	var x1 := r.end.x
	var z0 := r.position.y
	var z1 := r.end.y
	_hearth(Vector3(-0.3, 0.0, z1), PI, "vichy_rojo", true)
	_chair(Vector3(-1.45, 0.0, z1 - 0.75), PI - 0.5, true)
	_chair(Vector3(0.85, 0.0, z1 - 0.75), PI + 0.5, true)
	_put(Vector3(-1.9, 0.0, z1 - 1.5), 0.2)             # a low bench of wood
	box(-0.3, 0.2, -0.13, 0.6, 0.04, 0.26, 0x9a6a3a)
	for sx in [-0.24, 0.2]:
		box(sx, 0.0, -0.1, 0.04, 0.2, 0.2, 0x9a6a3a)
	home()
	_table(Vector3(x1 - 0.7, 0.0, z1 - 1.3), 0.0, 0.8, 0.95, 0.74, "mantel")
	_bowl(Vector3(x1 - 0.7, 0.755, z1 - 1.3), 0.17, 0.09, 0xb0562c)
	_jar(Vector3(x1 - 0.85, 0.755, z1 - 1.65), 0.26, 0xf0ece4)
	# the niche of plates in the right wall, the cutlery rack beside it
	box(x1 - 0.02, 1.25, z1 - 1.75, 0.03, 0.55, 0.9, 0xe9e4da)
	_shelf(Vector3(x1 - 0.02, 1.27, z1 - 1.3), -PI / 2.0, 0.86, 0.18, "vichy_rojo")
	for i in range(3):
		_put(Vector3(x1 - 0.12, 1.3, z1 - 1.6 + i * 0.3), -PI / 2.0)
		var keep := _xf
		_xf = _xf * Transform3D(Basis(Vector3.RIGHT, PI / 2.0 - 0.2), Vector3(0, 0.14, 0.0))
		drum(Vector3.ZERO, 0.13, 0.11, 0.02, [0xf4f1e8, 0x3a62b0, 0xb0562c][i], 12)
		_xf = keep
		home()
	_put(Vector3(x1 - 0.03, 1.5, z1 - 2.7), -PI / 2.0)
	box(-0.3, 0.0, 0.0, 0.6, 0.05, 0.03, 0x8a6240)
	for i in range(6):
		box(-0.26 + i * 0.1, -0.2, 0.03, 0.02, 0.2, 0.012, 0xb8b8b4)
	home()
	_picture(Vector3(x0 + 0.02, 1.5, z1 - 1.9), Vector3(1, 0, 0), 0.34, 0.46, 0xc9b890, 0xd0b48a)
	_coat(Vector3(x0 + 0.02, 1.55, z1 - 1.2), Vector3(1, 0, 0), 0x6f8fc0, 0.6)
	_coat(Vector3(x1 - 0.02, 1.7, z0 + 0.7), Vector3(-1, 0, 0), 0x3a3a44, 0.95)
	_put(Vector3(x1 - 0.5, 0.0, z0 + 0.45))             # a stool under a blue checked cloth
	drum(Vector3.ZERO, 0.24, 0.24, 0.5, 0x8a6240, 10)
	drum(Vector3(0, 0.5, 0), 0.28, 0.3, 0.02, "vichy_azul", 10)
	home()
	solid(Vector3(x1 - 0.5, 0.25, z0 + 0.45), Vector3(0.5, 0.5, 0.5))
	_bulb(Vector3(0.0, 2.1, (z0 + z1) / 2.0))

## The pantry: two shelves in a round niche edged with red gingham and loaded with pots, pans hung on a cloth, the
## green can, bowls and pans of clay on the floor, a basket, a sieve, peppers.
func _pantry() -> void:
	var r := _rect("despensa")
	var x0 := r.position.x
	var x1 := r.end.x
	var z0 := r.position.y
	var z1 := r.end.y
	box(x0 + 0.5, 0.95, z1 - 0.03, 1.5, 0.95, 0.03, 0xe9e4da)          # the niche (a shade darker)
	for y in [1.05, 1.5]:
		_shelf(Vector3(x0 + 1.25, y, z1 - 0.03), PI, 1.5, 0.3, "vichy_rojo")
	for i in range(4):
		_pot(Vector3(x0 + 0.7 + i * 0.36, 1.53, z1 - 0.18), 0.1, 0.13, 0xb02a26)
	for i in range(3):
		_bowl(Vector3(x0 + 0.8 + i * 0.42, 1.08, z1 - 0.18), 0.14, 0.05, [0xf4f1e8, 0xe9dcc0, 0xf4f1e8][i])
	# pans on their cloth of gingham, on the left wall
	box(x0 + 0.012, 1.0, z0 + 0.5, 0.012, 0.75, 1.2, "vichy_rojo")
	for i in range(4):
		_put(Vector3(x0 + 0.05, 1.5 - (i % 2) * 0.2, z0 + 0.7 + i * 0.28), PI / 2.0)
		var keep := _xf
		_xf = _xf * Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO)
		drum(Vector3.ZERO, 0.11, 0.09, 0.04, 0x1e1c1a if i % 2 == 0 else 0xb02a26, 10)
		_xf = keep
		box(-0.015, 0.1, 0.0, 0.03, 0.22, 0.02, 0x1e1c1a)
		home()
	# on the floor: pans, a pot, the green can, a jar, bowls of clay, a basket, a tub
	_put(Vector3(x0 + 0.45, 0.0, z1 - 0.5))
	drum(Vector3.ZERO, 0.18, 0.2, 0.05, 0x1e1c1a, 12)
	home()
	_pot(Vector3(x0 + 0.95, 0.0, z1 - 0.45), 0.17, 0.12, 0xb02a26)
	_pot(Vector3(x0 + 1.4, 0.0, z1 - 0.45), 0.15, 0.13, 0xb02a26)
	_pot(Vector3(x0 + 1.75, 0.0, z1 - 0.7), 0.16, 0.42, 0x2f8a4a)
	_put(Vector3(x0 + 1.75, 0.5, z1 - 0.7))
	drum(Vector3.ZERO, 0.12, 0.12, 0.012, "vichy_rojo", 8)
	home()
	_jar(Vector3(x0 + 2.2, 0.0, z1 - 0.4), 0.34, 0x8a4a2c)
	_bowl(Vector3(x0 + 0.5, 0.0, z0 + 0.5), 0.26, 0.11, 0xb0562c)
	_bowl(Vector3(x0 + 1.15, 0.0, z0 + 0.4), 0.2, 0.1, 0xa04a26)
	_basket(Vector3(x0 + 1.8, 0.0, z0 + 0.45), 0.22, 0.26)
	_put(Vector3(x0 + 0.5, 0.0, z0 + 1.3))
	drum(Vector3.ZERO, 0.24, 0.3, 0.16, 0x7a8088, 12)
	home()
	_put(Vector3(x0 + 2.0, 1.75, z1 - 0.03), PI)        # the peppers and the garlic
	for k in range(6):
		ball(Vector3(0.03 * (k % 2), -k * 0.08, 0.05), 0.04, 0xa8281e, 1.5, 6, 4)
		ball(Vector3(0.25 + 0.03 * (k % 2), -k * 0.07, 0.05), 0.035, 0xe9e0c8, 1.0, 6, 4)
	home()
	_put(Vector3(x0 + 0.28, 1.85, z1 - 0.03), PI)
	var keep2 := _xf
	_xf = _xf * Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO)
	drum(Vector3.ZERO, 0.19, 0.19, 0.06, 0xb89a62, 12)
	_xf = keep2
	home()
	_bulb(Vector3((x0 + x1) / 2.0, 1.95, (z0 + z1) / 2.0), 4.0)

## The bedroom: three beds under their flowered spreads (the big one with knobs of brass), the chest under its red
## cover, chairs, the washstand, a bedside table, pictures, clothes on their nails, the flowered curtains of its door,
## the little window with its shutters.
func _bedroom() -> void:
	var r := _rect("alcoba")
	var x0 := r.position.x
	var x1 := r.end.x
	var z0 := r.position.y
	var z1 := r.end.y
	_bed(Vector3(x0 + 1.0, 0.0, z1 - 1.05), PI, 1.35, 1.95, 0x1e1c1a, "rosas", true)
	_bed(Vector3(x0 + 0.62, 0.0, z0 + 3.2), 0.0, 0.95, 1.9, 0x1e1c1a, "rosas")
	_bed(Vector3(x0 + 1.9, 0.0, z0 + 0.72), PI / 2.0, 1.2, 1.9, 0x1e1c1a, "rosas", true)
	_chest(Vector3(x1 - 0.32, 0.0, z0 + 4.05), PI / 2.0, 0.95, 0.5, 0.48, "damasco")
	_put(Vector3(x0 + 0.3, 0.0, z1 - 2.35))             # the bedside table, dark
	box(-0.2, 0.0, -0.2, 0.4, 0.62, 0.4, 0x3a2a22)
	box(-0.22, 0.62, -0.22, 0.44, 0.03, 0.44, 0x2a1e18)
	home()
	solid(Vector3(x0 + 0.3, 0.3, z1 - 2.35), Vector3(0.4, 0.62, 0.4))
	_chair(Vector3(x1 - 0.4, 0.0, z0 + 2.2), PI / 2.0)
	_chair(Vector3(x1 - 0.4, 0.0, z1 - 0.5), PI / 2.0)
	_chair(Vector3(x0 + 0.4, 0.0, z0 + 1.85), -PI / 2.0, true)
	_washstand(Vector3(x1 - 0.42, 0.0, z0 + 3.1))
	_picture(Vector3(x0 + 1.0, 1.75, z1 - 0.02), Vector3(0, 0, -1), 0.55, 0.36, 0x7a5232, 0x6a8a6a)
	_picture(Vector3(x0 + 0.02, 1.6, z0 + 3.2), Vector3(1, 0, 0), 0.36, 0.46, 0x3a2a22, 0xcfc4b0)
	_picture(Vector3(x0 + 0.02, 1.6, z0 + 5.0), Vector3(1, 0, 0), 0.26, 0.3, 0x7a5232, 0xd8c8a8)
	_picture(Vector3(x1 - 0.02, 1.65, z0 + 2.9), Vector3(-1, 0, 0), 0.4, 0.3, 0x3a2a22, 0xb8c0c4)
	_coat(Vector3(x0 + 0.02, 1.7, z0 + 4.3), Vector3(1, 0, 0), 0x3a4a6a, 0.85)
	_coat(Vector3(x0 + 0.02, 1.7, z0 + 4.7), Vector3(1, 0, 0), 0x1e1e26, 0.7)
	_coat(Vector3(x1 - 0.02, 1.7, z0 + 1.2), Vector3(-1, 0, 0), 0x4a5a8a, 0.9)
	_curtain(Vector3(x1 + 0.2, 1.93, 18.4), Vector3(x1 + 0.2, 1.93, 19.4), 1.9, "rosas_cortina")
	# the window to the court, its shutters of wood open inwards
	box(x1 - 0.012, 1.1, 14.0, 0.012, 0.65, 0.6, 0x9ab8d0)
	for z in [13.72, 14.6]:
		box(x1 - 0.05, 1.08, z, 0.03, 0.7, 0.28, 0x6f4a2c)
	# the corner for washing: a basket, slippers, a mat
	_basket(Vector3(x1 - 0.5, 0.0, z0 + 0.45), 0.24, 0.3)
	_put(Vector3(x1 - 1.1, 0.0, z0 + 0.4))
	box(-0.12, 0.0, -0.05, 0.1, 0.05, 0.24, 0x4a3a2e)
	box(0.03, 0.0, -0.02, 0.1, 0.05, 0.24, 0x4a3a2e)
	home()
	_bulb(Vector3((x0 + x1) / 2.0, 2.05, z0 + 1.8))
	_bulb(Vector3((x0 + x1) / 2.0, 2.05, z1 - 1.8))

# ---------------- the second house ----------------
## Its kitchen: beaten earth and mats of esparto, the hearth under blue gingham, the table under its blue checked cloth
## with the white basin, low chairs, jars and bowls, a board with its almanac, things hung on the wall.
func _kitchen2() -> void:
	var r := _rect("cocina2")
	var x0 := r.position.x
	var x1 := r.end.x
	var z0 := r.position.y
	var z1 := r.end.y
	_mat(x0 + 0.2, 12.7, 2.6, 0.8)
	_mat(x1 - 1.9, z1 - 1.6, 1.3, 0.9)
	_hearth(Vector3(x1 - 1.2, 0.0, z1), PI, "vichy_azul", false)
	_put(Vector3(x1 - 2.45, 0.0, z1 - 0.45), 0.15)      # a low bench by the fire
	box(-0.35, 0.18, -0.12, 0.7, 0.04, 0.24, 0x9a6a3a)
	for sx in [-0.3, 0.26]:
		box(sx, 0.0, -0.1, 0.04, 0.18, 0.2, 0x9a6a3a)
	home()
	_put(Vector3(x1 - 0.25, 1.1, z1 - 0.03), PI)        # the bellows on its nail
	box(-0.1, -0.25, 0.0, 0.2, 0.3, 0.06, 0x7a4a2c)
	box(-0.02, -0.42, 0.01, 0.04, 0.18, 0.03, 0x2a2826)
	home()
	_table(Vector3(x0 + 1.5, 0.0, z0 + 0.75), 0.0, 0.85, 0.6, 0.55, "vichy_azul")
	_bowl(Vector3(x0 + 1.5, 0.565, z0 + 0.75), 0.2, 0.08, 0xf6f4ee)
	_chair(Vector3(x0 + 0.6, 0.0, z0 + 0.7), -PI / 2.0, true)
	_chair(Vector3(x0 + 2.45, 0.0, z0 + 0.95), PI / 2.0 + 0.3, true)
	_jar(Vector3(x0 + 2.0, 0.0, z0 + 0.35), 0.42, 0xb0623a)
	_jar(Vector3(x0 + 2.45, 0.0, z0 + 0.3), 0.3, 0x8a4a2c)
	_bowl(Vector3(x0 + 2.95, 0.0, z0 + 0.4), 0.2, 0.2, 0x9a5a34)
	_basket(Vector3(x0 + 1.0, 0.0, z0 + 0.3), 0.18, 0.2)
	# on the wall over the table: a round board, dried flowers, a blue checked cloth, the almanac, a black apron
	_put(Vector3(x0 + 2.2, 1.45, z0 + 0.03))
	var keep := _xf
	_xf = _xf * Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO)
	drum(Vector3.ZERO, 0.14, 0.14, 0.03, 0xb88a52, 12)
	_xf = keep
	box(-0.02, -0.35, 0.0, 0.04, 0.22, 0.03, 0xb88a52)
	home()
	_put(Vector3(x0 + 2.75, 1.5, z0 + 0.03))
	for k in range(5):
		ball(Vector3(0.04 * (k % 2), -k * 0.08, 0.05), 0.05, 0x9a7a3a, 1.3, 6, 4)
	home()
	box(x0 + 3.1, 1.15, z0 + 0.012, 0.42, 0.42, 0.012, "vichy_azul")
	_picture(Vector3(x0 + 0.5, 1.6, z0 + 0.02), Vector3(0, 0, 1), 0.3, 0.38, 0xf0ece4, 0x6a9ac0)
	_coat(Vector3(x0 + 0.02, 1.6, z0 + 0.6), Vector3(1, 0, 0), 0x1e1c1e, 0.75)
	# the shelf of jugs and the holy picture, between the alcove's way and the hearth
	_shelf(Vector3(x1 - 0.02, 1.4, z1 - 0.75), -PI / 2.0, 0.7, 0.18, "vichy_azul")
	_jar(Vector3(x1 - 0.12, 1.43, z1 - 0.9), 0.2, 0x8a4a2c)
	_pot(Vector3(x1 - 0.12, 1.43, z1 - 0.6), 0.07, 0.1, 0xd8c8a0, false)
	_picture(Vector3(x1 - 0.02, 0.95, z1 - 0.75), Vector3(-1, 0, 0), 0.34, 0.44, 0xc9a23a, 0xc8563a)
	_curtain(Vector3(x1 + 0.2, 1.93, 12.2), Vector3(x1 + 0.2, 1.93, 13.4), 1.9, "rayas", true)
	_put(Vector3(x0 + 0.03, 0.0, 12.56), PI / 2.0 - 0.2)      # the door, open against the wall
	box(0.0, 0.02, 0.0, 0.98, 1.9, 0.06, "madera")
	for i in range(3):
		for j in range(5):
			ball(Vector3(0.16 + i * 0.33, 0.25 + j * 0.36, 0.065), 0.022, 0x2a2622, 1.0, 6, 3)
	home()
	_bulb(Vector3((x0 + x1) / 2.0 - 0.3, 2.05, (z0 + z1) / 2.0))

## The alcove: the bed under its yellow spread, the trunk open with its linen under a red cover, the washstand, a chair
## with a flowered seat, a cross, clothes, round mats, the red curtain of the way on.
func _alcove2() -> void:
	var r := _rect("alcoba2")
	var x0 := r.position.x
	var x1 := r.end.x
	var z0 := r.position.y
	var z1 := r.end.y
	_bed(Vector3(x1 - 1.05, 0.0, z0 + 0.75), -PI / 2.0, 1.25, 1.9, 0x3a2a22, 0xf0d860)
	_chest(Vector3(x1 - 0.6, 0.0, z1 - 0.4), 0.0, 1.0, 0.5, 0.42)
	_put(Vector3(x1 - 0.6, 0.42, z1 - 0.4))
	box(-0.42, 0.0, -0.18, 0.84, 0.05, 0.36, 0xf4f1ea)
	box(-0.2, 0.05, -0.12, 0.3, 0.04, 0.22, 0x2a2a30)
	box(-0.5, 0.15, 0.2, 1.0, 0.5, 0.03, "damasco")      # (its lid up against the wall, under the red cover)
	home()
	_washstand(Vector3(x0 + 0.45, 0.0, z1 - 0.45))
	_chair(Vector3(x0 + 0.5, 0.0, z0 + 0.5), -PI / 2.0 - 0.4, false, 0x6a3a2a)
	_put(Vector3(x0 + 0.5, 0.48, z0 + 0.5))
	box(-0.18, 0.0, -0.18, 0.36, 0.05, 0.36, "rosas")
	home()
	_put(Vector3(x1 - 0.02, 1.6, z0 + 2.1), -PI / 2.0)  # the cross
	box(-0.02, -0.16, 0.0, 0.04, 0.32, 0.025, 0x4a2e1e)
	box(-0.1, 0.02, 0.0, 0.2, 0.04, 0.025, 0x4a2e1e)
	home()
	_coat(Vector3(x1 - 0.02, 1.75, z1 - 1.1), Vector3(-1, 0, 0), 0x22222c, 0.9)
	_coat(Vector3(x0 + 1.4, 1.75, z0 + 0.02), Vector3(0, 0, 1), 0x2a2a3a, 0.8)
	_round_mat(Vector2(x0 + 1.2, z0 + 2.2), 0.5)
	_round_mat(Vector2(x0 + 0.9, z0 + 1.3), 0.4)
	_curtain(Vector3(7.2, 1.93, z1 + 0.2), Vector3(8.2, 1.93, z1 + 0.2), 1.9, "damasco", true)
	_bulb(Vector3((x0 + x1) / 2.0, 1.95, (z0 + z1) / 2.0), 4.5)

## The last bedroom: the blue iron bed under its spread of blue sprigs, two chairs, a holy picture, a basket, clothes,
## the umbrella on the floor.
func _bedroom3() -> void:
	var r := _rect("alcoba3")
	var x0 := r.position.x
	var x1 := r.end.x
	var z0 := r.position.y
	var z1 := r.end.y
	_bed(Vector3((x0 + x1) / 2.0 + 0.3, 0.0, z1 - 1.05), PI, 1.2, 1.9, 0x2a5aa8, "colcha_azul")
	_chair(Vector3((x0 + x1) / 2.0 - 0.75, 0.0, z1 - 0.4), PI, false, 0x7a4a2a)
	_chair(Vector3((x0 + x1) / 2.0 + 1.3, 0.0, z1 - 0.4), PI, false, 0x3a2a22)
	_picture(Vector3((x0 + x1) / 2.0 + 0.3, 1.65, z1 - 0.02), Vector3(0, 0, -1), 0.28, 0.36, 0x3a2a22, 0xcfc4b0)
	_basket(Vector3(x0 + 0.45, 0.0, z0 + 1.2), 0.22, 0.3)
	_coat(Vector3(x1 - 0.02, 1.7, z0 + 1.0), Vector3(-1, 0, 0), 0xd0b8a0, 0.9)
	_coat(Vector3(x1 - 0.02, 1.7, z0 + 1.45), Vector3(-1, 0, 0), 0x5a6a80, 1.0)
	_put(Vector3(x1 - 0.6, 0.0, z0 + 2.0), 0.6)          # the umbrella
	bar(Vector3(-0.4, 0.06, 0), Vector3(0.3, 0.06, 0), 0.1, 0.1, 0x1e1e24)
	bar(Vector3(0.3, 0.06, 0), Vector3(0.48, 0.1, 0.05), 0.03, 0.03, 0x9a6a3a)
	home()
	_round_mat(Vector2(x0 + 1.1, z0 + 1.1), 0.5)
	_saffron(Vector2(x0 + 0.4, z0 + 2.3))
	_bulb(Vector3((x0 + x1) / 2.0, 1.95, (z0 + z1) / 2.0), 4.5)

## A saffron flower in a little pot of clay, by the wall of the last room (the user, 21 November 2026: "Añade un azafrán
## en una de las habitaciones pequeñas"): the game's own collectible, as the ones by the streets (game.gd `flowers`: walk
## up to it and it is yours), hidden where only who goes through both of the second house's rooms finds it. The flower
## is the game's to take away; the pot stays.
func _saffron(at: Vector2) -> void:
	drum(Vector3(at.x, 0.0, at.y), 0.1, 0.14, 0.16, 0xb0623a, 10)
	drum(Vector3(at.x, 0.15, at.y), 0.12, 0.12, 0.012, 0x5a3a26, 10)
	props += 1
	var flower := Node3D.new()
	flower.add_child(Parts.part("cyl", 0x5f9c4a, Vector3(0, 0.3, 0), Vector3(0.03, 0.6, 0.03)))
	for k in range(5):
		flower.add_child(Parts.part("ball", 0x9b5de5, Vector3(cos(k * 1.257) * 0.12, 0.66, sin(k * 1.257) * 0.12), Vector3(0.11, 0.2, 0.11)))
	flower.add_child(Parts.part("ball", 0xe63946, Vector3(0, 0.74, 0), Vector3(0.05, 0.13, 0.05)))
	flower.position = Vector3(at.x, 0.12, at.y)
	add_child(flower)
	saffron_spot = INSIDE + at
	var game = W.get_parent()                           # (the game: the world is its child)
	if game != null and game.get("flowers") != null:
		(game.flowers as Array).append({"node": flower, "p": saffron_spot, "id": "silo", "hidden": true})      # (hidden: Sistemas keeps count of these, and does not put back one already taken)
