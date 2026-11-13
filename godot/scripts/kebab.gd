extends Node3D
## Kebab Luis: a kebab house that does not exist, on an empty plot of the Calle de los Segadores (the user's idea,
## 12 November 2026; referencias/kebab_luis/). The whole plot is paved in brick; the house stands well back in it and
## the terrace goes round it in a U. You walk in through the old yellow gate of the plot, left open; the door of the
## house has no leaf: inside, a few tables, the bar, and behind it Don Luis at his stove with the kebab turning by the
## fire.
##
## The house, the paving and the walls are built here; the furniture and the food are Kenney's Furniture Kit and Food
## Kit (CC0: godot/assets/kebab/CREDITOS.txt).
##
## Its frame: x along the front from its left end as you face the plot from the street (0..WIDE), y up from the
## paving, z out towards the street (0 at the pavement line; the plot is z < 0).

const Parts = preload("res://scripts/parts.gd")
const Tex = preload("res://scripts/texturas.gd")
const Tela = preload("res://scripts/tela.gd")
const Chara = preload("res://scripts/chara.gd")
const DIR := "res://assets/kebab/"

const CORNER := Vector2(-863.3, -421.6)      # the plot's left corner on the street, as you face it (by the white shed)
const ALONG := Vector2(-0.797, -0.604)       # along the street, to your right
const WIDE := 22.0
const DEEP := 21.0
# the house
const X0 := 6.0
const X1 := 16.0
const FRONT := -11.5
const BACK := -19.5
const TALL := 3.3
const GATE := Vector2(7.6, 14.4)             # the way in from the street (x from, x to)

var W                           # the world (for its textures)
var G                           # the game (for its neighbours' looks)
var u := ALONG
var out := Vector2.ZERO
var base := 0.0
var door: Vector2               # the doorway of the house (on the map)
var keeper: Vector2             # where Don Luis stands
var facing := 0.0               # the heading that looks out of the house, towards the street
var lamps: Array = []           # Vector3: where its lights hang (the game lights them at dusk)
var seated := 0                 # how many people are sitting at its tables
var props := 0                  # how many pieces of furniture and food were set out
var _body: StaticBody3D
var _spit: Node3D
var _durum_spin: Node3D
var tables: Array = []          # every table: {t: its node, yaw, seats: [[where, turned], ...]}
var busy := -1                  # which of them has people at it today
var _today: Node3D              # those people, and what they are eating
var _fire: OmniLight3D
var _t := 0.0

func spot(x: float, z: float) -> Vector2:
	return CORNER + u * x + out * z

func build(world, game) -> void:
	W = world
	G = game
	out = Vector2(-u.y, u.x)
	base = MapData.height(spot(WIDE / 2.0, 0.3)) + 0.05
	position = Vector3(CORNER.x, base, CORNER.y)
	rotation.y = atan2(-u.y, u.x)
	_body = StaticBody3D.new()
	add_child(_body)
	door = spot(8.0, FRONT)
	keeper = spot(11.3, -17.0)
	facing = atan2(out.x, out.y)
	# the paving is a floor of its own: level, whatever the ground under it does
	var ring := PackedVector2Array([spot(0.0, 0.0), spot(WIDE, 0.0), spot(WIDE, -DEEP), spot(0.0, -DEEP)])
	var mid := spot(WIDE / 2.0, -DEEP / 2.0)
	MapData.decks = [{"o": mid, "r2": mid.distance_squared_to(ring[0]) + 1.0, "poly": ring, "top": base}] + MapData.decks
	_plot()
	_house()
	_inside()
	_terrace()
	seat_day(int(G.day_n))

func _process(delta: float) -> void:
	_t += delta
	if _spit != null:
		_spit.rotate_y(delta * 1.1)
	if _durum_spin != null:
		_durum_spin.rotate_y(delta * 0.5)
	if _fire != null:
		_fire.light_energy = 1.5 + 0.35 * sin(_t * 9.0) + 0.2 * sin(_t * 23.0)

# ---------------- helpers ----------------
## a box: its middle, its size; of a colour (int) or a material; `solid` if nobody walks through it
func _box(mat, pos: Vector3, size: Vector3, solid := false, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = Parts.mesh("box")
	mi.material_override = Parts.mat(int(mat)) if mat is int else mat
	mi.position = pos
	mi.scale = size
	(parent if parent != null else self).add_child(mi)
	if solid:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		cs.position = pos
		_body.add_child(cs)
	return mi

func _text(s: String, pos: Vector3, px: int, hex: int, turn := 0.0) -> Label3D:
	var l := Label3D.new()
	l.text = s
	l.font_size = px
	l.pixel_size = 0.004
	l.modulate = Parts.col(hex)
	l.outline_size = 0
	l.position = pos
	l.rotation.y = turn
	add_child(l)
	return l

func _render(hex: int) -> StandardMaterial3D:       # painted render, as the houses of the town wear it
	var m: StandardMaterial3D = Tex.mat(Tex.pick("render")) if Tex.pick("render") != "" else W._tmat(0xffffff, "plaster", 4.0)
	var c := Parts.col(hex)
	m.albedo_color = Color(c.r * 1.1, c.g * 1.1, c.b * 1.1)
	m.emission_enabled = true
	m.emission = Color(c.r, c.g * 0.97, c.b * 0.9)
	m.emission_energy_multiplier = 0.2
	if Tex.pick("render") != "":
		m.emission_texture = m.albedo_texture
		m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	return m

func _glow(hex: int, energy := 1.4) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Parts.col(hex)
	m.emission_enabled = true
	m.emission = Parts.col(hex)
	m.emission_energy_multiplier = energy
	return m

## where a model's meshes are, in its own space
func _bounds(n: Node, xf: Transform3D, box: Array) -> void:
	var here := xf
	if n is Node3D:
		here = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var ab: AABB = here * (n as MeshInstance3D).mesh.get_aabb()
		box[0] = ab if box[0] == null else (box[0] as AABB).merge(ab)
	for c in n.get_children():
		_bounds(c, here, box)

## the kit's materials made matt, as everything in the town is (a shine picks up the sky and greys the colour)
func _matt(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for si in range(mi.mesh.get_surface_count()):
			var m := mi.mesh.surface_get_material(si)
			if m is BaseMaterial3D:
				var d := (m as BaseMaterial3D).duplicate() as BaseMaterial3D
				d.metallic = 0.0
				d.roughness = 1.0
				d.metallic_specular = 0.0
				d.emission_enabled = true           # (it all stands in the shade -- under parasols, indoors -- where the sky would grey it)
				d.emission = Color(d.albedo_color.r, d.albedo_color.g * 0.97, d.albedo_color.b * 0.9)
				d.emission_energy_multiplier = 0.32
				if d.albedo_texture != null:
					d.emission_texture = d.albedo_texture
					d.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
				mi.set_surface_override_material(si, d)
	for c in n.get_children():
		_matt(c)

## A model of the kit stood on `pos` (the middle of its foot), `tall` metres high (or, with `wide`, that wide along its
## longer side), turned `yaw` about the upright.
func _prop(file: String, pos: Vector3, tall: float, yaw := 0.0, wide := 0.0, parent: Node3D = null) -> Node3D:
	var path := DIR + file + ".glb"
	if not ResourceLoader.exists(path):
		return null
	var model: Node3D = (load(path) as PackedScene).instantiate()
	var box: Array = [null]
	_bounds(model, Transform3D.IDENTITY, box)
	_matt(model)
	if box[0] == null:
		model.free()
		return null
	var ab: AABB = box[0]
	var k := tall / maxf(ab.size.y, 0.001) if wide <= 0.0 else wide / maxf(maxf(ab.size.x, ab.size.z), 0.001)
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation.y = yaw
	var sized := Node3D.new()
	sized.scale = Vector3.ONE * k
	model.position = -Vector3(ab.position.x + ab.size.x / 2.0, ab.position.y, ab.position.z + ab.size.z / 2.0)
	sized.add_child(model)
	holder.add_child(sized)
	(parent if parent != null else self).add_child(holder)
	props += 1
	return holder

## somebody of the town sitting at `pos` (the seat), looking along `yaw`
func _sitter(pos: Vector3, yaw: float, parent: Node3D) -> void:
	var voices: Array = G.NEIGHBOUR_VOICES
	var voice: String = voices[randi() % voices.size()]
	if voice == "kid":
		voice = "adult_f"
	var who = Chara.new()
	var figure: Node3D = who.sit(G._neighbour_look(voice), false)
	who.free()
	var held := Node3D.new()
	held.position = pos
	held.rotation.y = yaw
	held.scale = Vector3.ONE * 0.72
	held.add_child(figure)
	parent.add_child(held)
	seated += 1

# ---------------- the plot: paving, walls, the gate ----------------
func _plot() -> void:
	var paving: StandardMaterial3D = W._tmat(0xffffff, "brickpave", 1.6)
	_box(paving, Vector3(WIDE / 2.0, -1.0, -DEEP / 2.0), Vector3(WIDE, 2.0, DEEP))
	_box(0xb9b4a8, Vector3(WIDE / 2.0, -0.02, 0.1), Vector3(WIDE, 0.06, 0.24))                # the kerb along the street
	var white := _render(0xf4f1e8)
	var cap := 0xb5533a
	var runs := [[Vector3(0.1, 0.5, -DEEP / 2.0), Vector3(0.2, 1.0, DEEP)], [Vector3(WIDE - 0.1, 0.5, -DEEP / 2.0), Vector3(0.2, 1.0, DEEP)],
		[Vector3(WIDE / 2.0, 0.5, -DEEP + 0.1), Vector3(WIDE, 1.0, 0.2)],
		[Vector3(GATE.x / 2.0, 0.5, -0.1), Vector3(GATE.x, 1.0, 0.2)], [Vector3((GATE.y + WIDE) / 2.0, 0.5, -0.1), Vector3(WIDE - GATE.y, 1.0, 0.2)]]
	for r in runs:                                   # a low white wall round it, capped in tile
		_box(white, r[0], r[1], true)
		_box(cap, r[0] + Vector3(0, 0.53, 0), Vector3(r[1].x + 0.08, 0.06, r[1].z + 0.08))
	# the gate of the plot as it was: yellow tube and mesh, its two leaves swung back against the wall
	var yellow := 0xe0b530
	for gx in [GATE.x, GATE.y]:
		_box(yellow, Vector3(gx, 1.3, -0.1), Vector3(0.16, 2.6, 0.16), true)
	for side in [-1.0, 1.0]:
		var leaf := Node3D.new()
		leaf.position = Vector3(GATE.x if side < 0.0 else GATE.y, 0.0, -0.2)
		leaf.rotation.y = side * 1.48
		add_child(leaf)
		var lw := (GATE.y - GATE.x) / 2.0 - 0.1
		var sx: float = side * -1.0                         # (the leaf runs from its post towards the middle of the gate)
		for e in [[lw / 2.0, 0.12, lw, 0.06], [lw / 2.0, 2.0, lw, 0.06], [0.03, 1.06, 0.06, 1.94], [lw - 0.03, 1.06, 0.06, 1.94]]:
			_box(yellow, Vector3(sx * e[0], e[1], 0.0), Vector3(e[2], e[3], 0.05), false, leaf)
		for i in range(1, int(lw / 0.22)):
			_box(yellow, Vector3(sx * i * 0.22, 1.06, 0.0), Vector3(0.012, 1.9, 0.012), false, leaf)
		for i in range(1, 9):
			_box(yellow, Vector3(sx * lw / 2.0, 0.12 + i * 0.21, 0.0), Vector3(lw, 0.012, 0.012), false, leaf)
	# over the gate, the name
	_box(0xb5202a, Vector3((GATE.x + GATE.y) / 2.0, 2.95, -0.1), Vector3(GATE.y - GATE.x + 0.3, 0.75, 0.12))
	_box(yellow, Vector3((GATE.x + GATE.y) / 2.0, 3.36, -0.1), Vector3(GATE.y - GATE.x + 0.4, 0.07, 0.16))
	_box(yellow, Vector3((GATE.x + GATE.y) / 2.0, 2.54, -0.1), Vector3(GATE.y - GATE.x + 0.4, 0.07, 0.16))
	_logo(Vector3((GATE.x + GATE.y) / 2.0, 4.62, -0.1), 3.3, true)           # the house's badge, standing on the beam
	for px in [1.2, 20.8]:                           # a plant in each front corner
		_prop("mueble_pottedPlant", Vector3(px, 0.0, -1.0), 1.5)

## the badge of the house (the user's own pixel-art logo), `wide` metres across, its middle at `pos`
func _logo(pos: Vector3, wide: float, both_sides: bool) -> void:
	var tex := Parts.texture(DIR + "logo_kebab_luis.png")
	if tex == null:
		return
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS      # (pixel art: its squares stay sharp)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED if both_sides else BaseMaterial3D.CULL_BACK
	m.roughness = 1.0
	m.metallic_specular = 0.0
	m.emission_enabled = true
	m.emission_texture = tex
	m.emission_energy_multiplier = 0.45
	var q := QuadMesh.new()
	q.size = Vector2(wide, wide * tex.get_height() / float(tex.get_width()))
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.position = pos
	add_child(mi)

## Over the roof, as the doughnut shops of America have their doughnut: a durum as long as a car, turning on its post
func _durum() -> void:
	var cx := (X0 + X1) / 2.0
	var cz := (FRONT + BACK) / 2.0 - 0.6
	_box(0x4a4d50, Vector3(cx, TALL + 2.2, cz), Vector3(0.26, 4.2, 0.26))
	_box(0x4a4d50, Vector3(cx, TALL + 0.2, cz), Vector3(1.2, 0.16, 1.2))
	_durum_spin = Node3D.new()
	_durum_spin.position = Vector3(cx, TALL + 6.3, cz)
	_durum_spin.scale = Vector3.ONE * 1.5
	add_child(_durum_spin)
	var roll := Node3D.new()                              # the roll itself leans, as one held in the hand
	roll.rotation.z = 0.5
	_durum_spin.add_child(roll)
	roll.add_child(Parts.part("cyl", 0xe9cf9a, Vector3(0, 0.1, 0), Vector3(0.62, 2.6, 0.62)))          # the bread
	for k in range(7):                                    # toasted marks on it
		var a := k * 0.9
		var mark := Parts.part("box", 0xc99a58, Vector3(cos(a) * 0.6, -0.5 + k * 0.28, sin(a) * 0.6), Vector3(0.3, 0.16, 0.3))
		mark.rotation.y = -a
		roll.add_child(mark)
	roll.add_child(Parts.part("cyl", 0xd6dade, Vector3(0, -1.0, 0), Vector3(0.66, 1.3, 0.66)))         # its foil
	var tip := Parts.part("cone", 0xd6dade, Vector3(0, -1.95, 0), Vector3(0.66, 0.6, 0.66))
	tip.rotation.x = PI
	roll.add_child(tip)
	var fill := [[0x8a4c24, 0.0, 0.0], [0x6aa84f, 0.3, 0.9], [0xc8102e, 0.28, 2.2], [0x8a4c24, 0.26, 3.6], [0x6aa84f, 0.3, 4.6], [0xf4f1e8, 0.05, 5.5], [0xc8102e, 0.3, 0.2]]
	for f in fill:                                        # what sticks out of the top: meat, lettuce, tomato, the white sauce
		roll.add_child(Parts.part("ball", f[0], Vector3(cos(f[2]) * f[1] * 1.2, 1.45 + 0.1 * sin(f[2] * 3.0), sin(f[2]) * f[1] * 1.2), Vector3(0.3, 0.24, 0.3)))
	roll.add_child(Parts.part("ball", 0xf4f1e8, Vector3(0.0, 1.62, 0.0), Vector3(0.34, 0.12, 0.2)))
	lamps.append(to_global(Vector3(cx, TALL + 5.0, cz + 2.2)))

# ---------------- the house ----------------
func _house() -> void:
	var wall := _render(0xf6f1e4)
	var red := 0xb5202a
	var th := 0.25
	var doorw := Vector2(7.2, 8.8)                   # the doorway
	var hatch := Vector2(10.2, 15.0)                 # the serving window, open to the terrace
	# the front, round its two openings
	_box(wall, Vector3((X0 + doorw.x) / 2.0, TALL / 2.0, FRONT - th / 2.0), Vector3(doorw.x - X0, TALL, th), true)
	_box(wall, Vector3((doorw.y + hatch.x) / 2.0, TALL / 2.0, FRONT - th / 2.0), Vector3(hatch.x - doorw.y, TALL, th), true)
	_box(wall, Vector3((hatch.y + X1) / 2.0, TALL / 2.0, FRONT - th / 2.0), Vector3(X1 - hatch.y, TALL, th), true)
	_box(wall, Vector3((doorw.x + doorw.y) / 2.0, (2.3 + TALL) / 2.0, FRONT - th / 2.0), Vector3(doorw.y - doorw.x, TALL - 2.3, th))
	_box(wall, Vector3((hatch.x + hatch.y) / 2.0, 0.5, FRONT - th / 2.0), Vector3(hatch.y - hatch.x, 1.0, th), true)
	_box(wall, Vector3((hatch.x + hatch.y) / 2.0, (2.35 + TALL) / 2.0, FRONT - th / 2.0), Vector3(hatch.y - hatch.x, TALL - 2.35, th))
	_box(0x6b4028, Vector3((hatch.x + hatch.y) / 2.0, 1.03, FRONT + 0.05), Vector3(hatch.y - hatch.x + 0.2, 0.06, 0.6))      # its sill, a shelf to lean on
	# the sides and the back
	for wx in [X0 + th / 2.0, X1 - th / 2.0]:
		_box(wall, Vector3(wx, TALL / 2.0, (FRONT + BACK) / 2.0), Vector3(th, TALL, FRONT - BACK), true)
	_box(wall, Vector3((X0 + X1) / 2.0, TALL / 2.0, BACK + th / 2.0), Vector3(X1 - X0, TALL, th), true)
	# a foot of red tiles all round, a red band under the roof, the flat roof and its parapet
	for e in [[Vector3((X0 + doorw.x) / 2.0, 0.45, FRONT + 0.02), Vector3(doorw.x - X0, 0.9, 0.04)], [Vector3((doorw.y + X1) / 2.0, 0.45, FRONT + 0.02), Vector3(X1 - doorw.y, 0.9, 0.04)],
			[Vector3(X0 - 0.02, 0.45, (FRONT + BACK) / 2.0), Vector3(0.04, 0.9, FRONT - BACK)], [Vector3(X1 + 0.02, 0.45, (FRONT + BACK) / 2.0), Vector3(0.04, 0.9, FRONT - BACK)],
			[Vector3((X0 + X1) / 2.0, 0.45, BACK - 0.02), Vector3(X1 - X0, 0.9, 0.04)]]:
		_box(red, e[0], e[1])
	_box(0x9aa0a4, Vector3((X0 + X1) / 2.0, TALL + 0.06, (FRONT + BACK) / 2.0), Vector3(X1 - X0 + 0.3, 0.12, FRONT - BACK + 0.3))
	for e in [[Vector3((X0 + X1) / 2.0, TALL + 0.3, FRONT + 0.05), Vector3(X1 - X0 + 0.3, 0.5, 0.2)], [Vector3((X0 + X1) / 2.0, TALL + 0.3, BACK - 0.05), Vector3(X1 - X0 + 0.3, 0.5, 0.2)],
			[Vector3(X0 - 0.05, TALL + 0.3, (FRONT + BACK) / 2.0), Vector3(0.2, 0.5, FRONT - BACK)], [Vector3(X1 + 0.05, TALL + 0.3, (FRONT + BACK) / 2.0), Vector3(0.2, 0.5, FRONT - BACK)]]:
		_box(red, e[0], e[1])
	# the sign: the badge of the house, standing on the parapet
	_logo(Vector3((X0 + X1) / 2.0, TALL + 2.2, FRONT + 0.2), 4.4, false)
	for sx in [-1.5, 1.5]:
		_box(0x24221f, Vector3((X0 + X1) / 2.0 + sx, TALL + 1.4, FRONT + 0.12), Vector3(0.08, 2.0, 0.08))
	_durum()
	# the awning over the hatch and the door: red and white stripes of cloth that stir in the wind
	var st := Tela.begin()
	var tones := [Parts.col(0xb5202a), Parts.col(0xf6f1e4)]
	var paint := func(a: float, _d: float) -> Color:
		return tones[int(a * 16.0) % 2]
	Tela.sheet(st, Vector3(X0 + 0.6, 2.75, FRONT + 0.02), Vector3(X1 - X0 - 1.2, 0.0, 0.0), Vector3(0.0, -0.55, 1.5), true, paint, 0.06, 0.4, 0.0, 16, 4)
	var aw := MeshInstance3D.new()
	aw.mesh = st.commit()
	aw.material_override = Tela.material()
	aw.extra_cull_margin = 1.0
	add_child(aw)
	for ax in [X0 + 0.6, X1 - 0.6]:                  # (held out on two iron arms)
		var arm := _box(0x24221f, Vector3(ax, 2.47, FRONT + 0.77), Vector3(0.04, 0.04, 1.6))
		arm.rotation.x = atan2(0.55, 1.5)
	lamps.append(to_global(Vector3((X0 + X1) / 2.0, 2.4, FRONT + 1.6)))

# ---------------- inside: the bar, the kitchen, the spit, a couple of tables ----------------
func _inside() -> void:
	var th := 0.25
	_box(0xe9e2d0, Vector3((X0 + X1) / 2.0, 0.01, (FRONT + BACK) / 2.0), Vector3(X1 - X0 - th * 2.0, 0.02, FRONT - BACK - th * 2.0))
	var tiles := [0xb5202a, 0xf6f1e4]
	for i in range(19):                               # a line of red and white tiles in the floor along the bar
		_box(tiles[i % 2], Vector3(X0 + 0.5 + i * 0.5, 0.022, -14.6), Vector3(0.5, 0.004, 0.5))
	_box(0xf1ece0, Vector3((X0 + X1) / 2.0, TALL - 0.03, (FRONT + BACK) / 2.0), Vector3(X1 - X0 - th * 2.0, 0.04, FRONT - BACK - th * 2.0))       # the ceiling
	# the bar: five lengths of it and its rounded end; nobody walks through it
	for i in range(5):
		_prop("mueble_kitchenBar", Vector3(10.15 + i * 0.94, 0.0, -15.7), 0.92)
	_prop("mueble_kitchenBarEnd", Vector3(9.57, 0.0, -15.7), 0.92)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(5.2, 1.1, 0.6)
	cs.shape = bs
	cs.position = Vector3(12.0, 0.55, -15.7)
	_body.add_child(cs)
	for sx in [10.6, 12.0, 13.4]:                     # stools along it
		_prop("mueble_stoolBar", Vector3(sx, 0.0, -14.9), 0.95)
	# on the bar: sauces, a tray of chips, cans
	_prop("comida_bottle_ketchup", Vector3(10.4, 0.92, -15.7), 0.22)
	_prop("comida_bottle_musterd", Vector3(10.6, 0.92, -15.72), 0.22)
	_prop("comida_fries", Vector3(11.7, 0.92, -15.7), 0.16)
	_prop("comida_sub", Vector3(12.9, 0.92, -15.68), 0.0, 0.4, 0.34)
	for i in range(3):
		_prop("comida_soda_can", Vector3(14.2 + i * 0.13, 0.92, -15.7 + (i % 2) * 0.08), 0.13)
	# behind the bar the floor is a step up, on boards: whoever serves is seen over it, apron and all
	_box(0x8a6a48, Vector3(12.3, 0.14, -17.35), Vector3(5.6, 0.28, 2.0))
	for i in range(1, 12):
		_box(0x6f5236, Vector3(9.5 + i * 0.47, 0.283, -17.35), Vector3(0.02, 0.004, 2.0))
	var step := PackedVector2Array([spot(9.5, -16.35), spot(15.1, -16.35), spot(15.1, -18.35), spot(9.5, -18.35)])
	MapData.decks = [{"o": spot(12.3, -17.35), "r2": 12.0, "poly": step, "top": base + 0.28}] + MapData.decks
	# against the back wall: the fridge, the sink, the stove, a cupboard
	_prop("mueble_kitchenFridge", Vector3(X1 - 0.9, 0.0, BACK + 0.65), 2.0)
	_prop("mueble_kitchenSink", Vector3(14.0, 0.0, BACK + 0.8), 1.05)
	_prop("mueble_kitchenStove", Vector3(10.9, 0.0, BACK + 0.8), 0.98)
	_prop("mueble_kitchenCabinet", Vector3(9.8, 0.0, BACK + 0.8), 0.98)
	_prop("comida_cutting_board", Vector3(9.8, 0.98, BACK + 0.8), 0.0, 0.0, 0.4)
	_prop("comida_cooking_knife", Vector3(9.9, 1.0, BACK + 0.75), 0.0, 0.6, 0.3)
	# THE KEBAB: a steel stand, the fire behind it glowing, and on its upright spit the meat, turning
	var kx := 12.45
	var kz := BACK + 0.75
	_box(0x8f9498, Vector3(kx, 0.5, kz), Vector3(0.9, 1.0, 0.75))
	_box(0x6f7478, Vector3(kx, 1.02, kz), Vector3(1.0, 0.05, 0.85))
	_box(0x4a4d50, Vector3(kx, 1.95, kz - 0.3), Vector3(1.0, 1.8, 0.1))                       # the back plate, where the gas burns
	for i in range(4):
		_box(_glow(0xff6a1a, 2.6), Vector3(kx, 1.3 + i * 0.4, kz - 0.24), Vector3(0.8, 0.26, 0.03))
	_box(0x8f9498, Vector3(kx, 2.88, kz - 0.05), Vector3(1.1, 0.06, 0.6))
	_spit = Node3D.new()
	_spit.position = Vector3(kx, 1.05, kz + 0.08)
	_spit.scale = Vector3(1.35, 1.25, 1.35)
	add_child(_spit)
	var steel := Parts.part("cyl", 0xcfd3d6, Vector3(0, 0.72, 0), Vector3(0.018, 1.46, 0.018))
	_spit.add_child(steel)
	var meat := [0x9a5a2c, 0xa8662f, 0x8a4c24, 0xb0703a]
	for i in range(11):                               # the meat: slabs one on another, fatter at the top, none quite true
		var f := i / 10.0
		var r := lerpf(0.13, 0.27, f) * (1.0 + 0.06 * sin(i * 2.3))
		var slab := Parts.part("cyl", meat[i % 4], Vector3(0.012 * sin(i * 1.7), 0.14 + i * 0.105, 0.012 * cos(i * 2.1)), Vector3(r, 0.11, r))
		_spit.add_child(slab)
		if i % 3 == 0:                                # a charred patch, so that the turning shows
			_spit.add_child(Parts.part("box", 0x4a2a16, Vector3(r * 0.86, 0.14 + i * 0.105, 0.0), Vector3(0.05, 0.1, 0.16)))
	_spit.add_child(Parts.part("cone", 0xd9c7a0, Vector3(0, 1.36, 0), Vector3(0.1, 0.16, 0.1)))       # the onion on top
	_spit.add_child(Parts.part("cyl", 0x8f9498, Vector3(0, 0.03, 0), Vector3(0.3, 0.04, 0.3)))        # the dish that takes the dripping
	_fire = OmniLight3D.new()
	_fire.position = Vector3(kx, 1.8, kz + 0.25)
	_fire.light_color = Color(1.0, 0.55, 0.25)
	_fire.omni_range = 4.0
	_fire.light_energy = 1.6
	add_child(_fire)
	# two tables for those who would rather eat indoors
	_table(Vector3(7.6, 0.0, -17.3), 0.0, [true, false, true, false], false)
	_table(Vector3(7.6, 0.0, -13.6), 0.0, [false, true, false, false], false)
	_prop("mueble_trashcan", Vector3(9.0, 0.0, FRONT - 0.7), 0.7)
	_prop("mueble_plantSmall1", Vector3(X0 + 0.55, 0.0, FRONT - 0.6), 0.5)
	for lx in [8.0, 12.5]:
		_prop("mueble_lampSquareCeiling", Vector3(lx, TALL - 0.5, -14.0), 0.46)
	lamps.append(to_global(Vector3(8.0, 2.5, -15.5)))
	lamps.append(to_global(Vector3(12.5, 2.5, -14.2)))
	_text("HOY: KEBAB\nMAÑANA: KEBAB", Vector3(X1 - th - 0.02, 2.2, -13.6), 60, 0x3a2a20, -PI / 2.0)

## A table with its four chairs and, out of doors, its parasol. Nobody is put at it here: see seat_day().
func _table(at: Vector3, yaw: float, _who: Array, outdoors: bool) -> void:
	var t := Node3D.new()
	t.position = at
	t.rotation.y = yaw
	add_child(t)
	_prop("mueble_tableCloth" if outdoors else "mueble_tableCross", Vector3.ZERO, 0.0, 0.0, 1.7, t)
	var seats := [[Vector3(0.0, 0.0, -0.95), 0.0], [Vector3(0.0, 0.0, 0.95), PI], [Vector3(-1.25, 0.0, 0.0), PI / 2.0], [Vector3(1.25, 0.0, 0.0), -PI / 2.0]]
	for i in range(4):
		_prop("mueble_chair", seats[i][0], 1.25, float(seats[i][1]) + CHAIR_TURN, 0.0, t)
	if outdoors:                                      # the parasol: its pole through the table
		t.add_child(Parts.part("cyl", 0xd9d4c8, Vector3(0, 1.3, 0), Vector3(0.025, 2.6, 0.025)))
		t.add_child(Parts.part("cone", [0xb5202a, 0xf6f1e4][int(absf(at.x + at.z)) % 2], Vector3(0, 2.6, 0), Vector3(1.9, 0.5, 1.9)))
	tables.append({"t": t, "yaw": yaw, "seats": seats})

## One table -- another each day -- always has people at it, eating and talking; the rest wait for whoever comes by.
## `day`: any number that changes with the day.
func seat_day(day: int) -> void:
	if tables.is_empty():
		return
	if _today != null:
		_today.queue_free()
	seated = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("kebab %d" % day)
	busy = rng.randi() % tables.size()
	var tb: Dictionary = tables[busy]
	var t: Node3D = tb["t"]
	_today = Node3D.new()
	add_child(_today)
	var on_table := Node3D.new()
	on_table.transform = t.transform
	_today.add_child(on_table)
	var empty := (rng.randi() % 4) if rng.randf() < 0.5 else -1          # three at the table, or all four
	for i in range(4):
		if i == empty:
			continue
		var s: Vector3 = tb["seats"][i][0]
		var turn: float = tb["seats"][i][1]
		_sitter(t.transform * (s + Vector3(0.0, SEAT, 0.0)), float(tb["yaw"]) + turn, _today)
		var plate := s * 0.45 + Vector3(0.0, TABLE_TOP, 0.0)
		_prop("comida_plate", plate, 0.0, 0.0, 0.26, on_table)
		_prop(["comida_sub", "comida_taco", "comida_fries"][(i + day) % 3], plate + Vector3(0.0, 0.015, 0.0), 0.0, turn, 0.2, on_table)
		_prop("comida_soda_can" if i % 2 == 0 else "comida_soda_glass", plate + Vector3(0.2, 0.0, 0.0).rotated(Vector3.UP, turn), 0.13, 0.0, 0.0, on_table)

# ---------------- whoever comes in off the street (clientes.gd) ----------------
## a spot of the map in the plot's own frame: (x along the front, z out towards the street)
func local(p: Vector2) -> Vector2:
	var rel := p - CORNER
	return Vector2(rel.dot(u), rel.dot(out))

## is this spot of the map indoors, inside the house?
func inside(p: Vector2) -> bool:
	var at := local(p)
	return at.x > X0 and at.x < X1 and at.y > BACK and at.y < FRONT

## where a table stands, in the plot's frame
func table_at(ti: int) -> Vector2:
	var t: Node3D = tables[ti]["t"]
	return Vector2(t.position.x, t.position.z)

## where one of its seats is, in the plot's frame
func seat_at(ti: int, si: int) -> Vector2:
	var t: Node3D = tables[ti]["t"]
	var s: Vector3 = t.transform * (tables[ti]["seats"][si][0] as Vector3)
	return Vector2(s.x, s.z)

## somebody with this look sits down on that seat: the figure put there (free it when they get up)
func seat_guest(ti: int, si: int, look: Dictionary) -> Node3D:
	var tb: Dictionary = tables[ti]
	var t: Node3D = tb["t"]
	var who = Chara.new()
	var figure: Node3D = who.sit(look, false)
	who.free()
	var held := Node3D.new()
	held.position = t.transform * ((tb["seats"][si][0] as Vector3) + Vector3(0.0, SEAT, 0.0))
	held.rotation.y = float(tb["yaw"]) + float(tb["seats"][si][1])
	held.scale = Vector3.ONE * 0.72
	held.add_child(figure)
	add_child(held)
	return held

## what they ordered, set down in front of that seat: [everything (free it when they go), the food itself (free it when it is eaten)]
func serve(ti: int, si: int, what: String) -> Array:
	var tb: Dictionary = tables[ti]
	var setting := Node3D.new()
	setting.transform = (tb["t"] as Node3D).transform
	add_child(setting)
	var s: Vector3 = tb["seats"][si][0]
	var turn: float = tb["seats"][si][1]
	var plate := s * 0.45 + Vector3(0.0, TABLE_TOP, 0.0)
	_prop("comida_plate", plate, 0.0, 0.0, 0.26, setting)
	var food := _prop(what, plate + Vector3(0.0, 0.015, 0.0), 0.0, turn, 0.2, setting)
	_prop("comida_soda_can" if si % 2 == 0 else "comida_soda_glass", plate + Vector3(0.2, 0.0, 0.0).rotated(Vector3.UP, turn), 0.13, 0.0, 0.0, setting)
	return [setting, food]

## the same, wrapped, for carrying from the bar to the table (hung on whoever carries it)
func takeaway(what: String, on: Node3D) -> Node3D:
	return _prop(what, Vector3(0.22, 0.72, 0.4), 0.0, 0.0, 0.3, on)

const CHAIR_TURN := 0.0         # how the kit's chair must be turned to face a table that is at its -z
const SEAT := 0.42               # how high above the floor somebody sitting is put
const TABLE_TOP := 0.68          # how high the kit's table comes out when it is 1.25 m long

# ---------------- the terrace, in a U round the house ----------------
func _terrace() -> void:
	var some := [[true, true, false, false], [true, false, true, false], [false, false, false, false], [true, true, true, true], [false, true, false, true], [true, false, false, false]]
	var places: Array = []
	for tz in [-18.2, -14.6, -11.0]:                  # down each side of the house
		places.append(Vector3(3.0, 0.0, tz))
		places.append(Vector3(19.0, 0.0, tz))
	for tx in [3.0, 6.6, 15.4, 19.0]:                 # ...and across the front of it, leaving the way from the gate to the door
		places.append(Vector3(tx, 0.0, -6.2))
	for i in range(places.size()):
		_table(places[i], PI / 2.0 if i < 6 else 0.0, some[i % some.size()], true)
	# a string of bulbs from the gate to the house
	for k in range(9):
		var f := k / 8.0
		var p := Vector3(lerpf((GATE.x + GATE.y) / 2.0, 11.0, f), lerpf(2.6, TALL + 0.2, f) - 0.5 * sin(f * PI), lerpf(-0.3, FRONT + 0.1, f))
		add_child(Parts.part("ball", 0xfff1c4, p, Vector3.ONE * 0.06))
		var bulb := get_child(get_child_count() - 1) as MeshInstance3D
		bulb.material_override = _glow([0xfff1c4, 0xff8a5a, 0xf2c230][k % 3], 1.6)
	lamps.append(to_global(Vector3(3.0, 2.6, -12.0)))
	lamps.append(to_global(Vector3(19.0, 2.6, -12.0)))
	lamps.append(to_global(Vector3(11.0, 2.6, -5.0)))
