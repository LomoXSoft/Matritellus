extends Node3D
## V.I.P. ("Vendo e Instalo"; what the P stands for, Fonsi tells you when you cannot pay), the computer and phone shop at Calle de Santa Ana 14.
## The shopfront is laid over the real facade of that plot (Catastro), loosely after the real shop that stands there:
## a long blue sign, a big window, a glass door, a small window, and the neighbour's barred window with its brown plinth.
## The name, the lettering and everything inside are made up.
##
## The inside (shop, and a back room with a boxing ring) is a set built far out in the fields: you walk into the
## door on the street and come out of the door of the set, and the other way round.

const Parts = preload("res://scripts/parts.gd")

const WALL_A := Vector2(188.33, 81.82)       # the street facade of number 14
const WALL_B := Vector2(202.89, 86.97)
const STREET := Vector2(195.2, 79.5)         # a point on the street, to know which side is outside
const INSIDE := Vector2(1800.0, -1350.0)     # where the set is (nothing within 300 m)
const DOOR_X := -0.3                         # door centre along the facade, from the middle of the wall
const SHOP_W := 4.5                          # half width of the shop
const SHOP_D := 7.5
const SHOP_H := 3.3
const BACK_W := 6.8                          # half width of the back room
const BACK_END := 21.5
const BACK_H := 4.8
const RING := Vector2(0.0, 14.4)             # centre of the ring, in the set's own metres
const RING_HALF := 3.1
const RING_H := 0.4

var door_out: Vector2          # the door on the street
var out_spawn: Vector2         # where you stand when you come out
var out_h := 0.0
var in_door: Vector2           # the same door seen from inside
var in_spawn: Vector2
var counter_front: Vector2     # where a customer stands
var keeper_spot: Vector2       # where Fonsi stands
var ring_me: Vector2
var ring_foe: Vector2
var crowd_spots: Array = []    # Vector2: around three sides of the ring
var open := 0.0                # 0 shut .. 1 wide open
var _leaf: Node3D
var _room: Node3D
var _body: StaticBody3D

func build() -> void:
	_front()
	_inside()

func tick(dt: float, near: bool) -> void:
	open = move_toward(open, 1.0 if near else 0.0, dt * 2.6)
	_leaf.rotation.y = -1.45 * smoothstep(0.0, 1.0, open)

# ---------------- helpers ----------------
func _box(parent: Node3D, hex: int, pos: Vector3, size: Vector3, solid := false) -> MeshInstance3D:
	var mi := Parts.part("box", hex, pos, size)
	parent.add_child(mi)
	if solid:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		cs.position = pos
		_body.add_child(cs)
	return mi

func _text(parent: Node3D, s: String, pos: Vector3, px: int, hex: int, turn := 0.0) -> Label3D:
	var l := Label3D.new()
	l.text = s
	l.font_size = px
	l.pixel_size = 0.004
	l.modulate = Parts.col(hex)
	l.outline_size = 0
	l.position = pos
	l.rotation.y = turn
	parent.add_child(l)
	return l

func _glow(hex: int, energy := 1.2) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Parts.col(hex)
	m.emission_enabled = true
	m.emission = Parts.col(hex)
	m.emission_energy_multiplier = energy
	return m

func _checker(a: int, b: int, metres: float) -> StandardMaterial3D:
	var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
	img.set_pixel(0, 0, Parts.col(a)); img.set_pixel(1, 1, Parts.col(a))
	img.set_pixel(1, 0, Parts.col(b)); img.set_pixel(0, 1, Parts.col(b))
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / (metres * 2.0)
	m.roughness = 1.0
	return m

func _lamp(parent: Node3D, pos: Vector3, energy: float, reach: float, hex := 0xfff1d6) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_energy = energy
	l.omni_range = reach
	l.light_color = Parts.col(hex)
	l.shadow_enabled = false
	parent.add_child(l)

## the stock in a window or on a shelf: little coloured boxes in rows
func _stock(parent: Node3D, from: Vector3, step: Vector3, n: int, rng: RandomNumberGenerator, size := Vector3(0.26, 0.2, 0.05)) -> void:
	var cols := [0xe23b3b, 0xf2c230, 0x2f7fe0, 0x3fa34d, 0xf4f1e8, 0x26262b, 0xef7f1a, 0x9d4edd]
	for i in range(n):
		var s := size * rng.randf_range(0.8, 1.2)
		_box(parent, cols[rng.randi() % cols.size()], from + step * i + Vector3(0, s.y / 2.0, 0), s)

# ---------------- the shopfront, on the street ----------------
func _front() -> void:
	var mid := (WALL_A + WALL_B) / 2.0
	var along := (WALL_B - WALL_A).normalized()
	var out := Vector2(-along.y, along.x)
	if out.dot(STREET - mid) < 0.0:
		out = -out
	var half := WALL_A.distance_to(WALL_B) / 2.0
	var lx := Vector2(out.y, -out.x)           # the facade's own +x (to your right as you face it from the street)
	door_out = mid + lx * DOOR_X + out * 0.1
	out_spawn = mid + lx * DOOR_X + out * 2.0
	out_h = atan2(out.x, out.y)
	var f := Node3D.new()                      # +x along the wall, +z out into the street
	f.position = MapData.at(mid, -0.06)       # pavement level
	f.rotation.y = out_h
	add_child(f)
	var rng := RandomNumberGenerator.new()
	rng.seed = 14
	var cream := 0xecdcb6
	var stone := 0xd6ba84
	var white := 0xf6f4ee
	var glass := 0x24364a
	_box(f, cream, Vector3(0, 1.72, 0.03), Vector3(half * 2.0, 3.44, 0.06))              # ground floor render
	_box(f, 0xdcc79c, Vector3(0, 3.47, 0.07), Vector3(half * 2.0, 0.1, 0.14))            # the line under the first floor
	# the sign
	_box(f, 0x1d3aa8, Vector3(-0.55, 2.98, 0.1), Vector3(9.7, 0.62, 0.12))
	_text(f, "VENDO E INSTALO", Vector3(-3.35, 3.1, 0.17), 46, 0xffffff)
	_text(f, "TELEFONÍA  -  SERVICIO TÉCNICO", Vector3(-3.35, 2.85, 0.17), 40, 0xffffff)
	var big := _text(f, "V.I.P.", Vector3(0.75, 2.97, 0.17), 124, 0xffffff)
	big.outline_size = 10
	big.outline_modulate = Color("f2c230")
	_text(f, "INFORMÁTICA", Vector3(3.15, 2.93, 0.17), 44, 0xffffff)
	_box(f, 0xf2c230, Vector3(-5.05, 2.3, 0.08), Vector3(0.42, 0.46, 0.04))               # the little yellow plate
	# stone plinth either side of the door
	_box(f, stone, Vector3(-3.15, 0.37, 0.1), Vector3(4.5, 0.74, 0.18))
	_box(f, stone, Vector3(2.3, 0.37, 0.1), Vector3(4.0, 0.74, 0.18))
	_box(f, 0xc9ab72, Vector3(-3.15, 0.76, 0.12), Vector3(4.56, 0.06, 0.24))
	_box(f, 0xc9ab72, Vector3(2.3, 0.76, 0.12), Vector3(4.06, 0.06, 0.24))
	# the big window, full of stock
	_box(f, white, Vector3(-3.2, 1.57, 0.07), Vector3(3.56, 1.62, 0.1))
	_box(f, glass, Vector3(-3.2, 1.57, 0.125), Vector3(3.36, 1.42, 0.02))
	for row in range(3):
		_stock(f, Vector3(-4.65, 0.9 + row * 0.42, 0.15), Vector3(0.42, 0, 0), 5 if row < 2 else 7, rng)
	var disc := Parts.part("cyl", 0x2f7fe0, Vector3(-2.1, 1.95, 0.15), Vector3(0.36, 0.03, 0.36))
	disc.rotation.x = PI / 2.0
	f.add_child(disc)
	_text(f, "3G", Vector3(-2.1, 1.95, 0.175), 60, 0xffffff)
	# the door: a dark way in, a white frame and a glass leaf that swings out
	_box(f, 0x15161a, Vector3(DOOR_X, 1.12, 0.05), Vector3(1.3, 2.24, 0.06))
	_box(f, white, Vector3(DOOR_X, 2.3, 0.1), Vector3(1.46, 0.12, 0.14))
	for sx in [-1.0, 1.0]:
		_box(f, white, Vector3(DOOR_X + sx * 0.69, 1.15, 0.1), Vector3(0.08, 2.3, 0.14))
	_leaf = Node3D.new()
	_leaf.position = Vector3(DOOR_X - 0.62, 0.0, 0.14)
	f.add_child(_leaf)
	_box(_leaf, 0x7fa9c4, Vector3(0.62, 1.12, 0), Vector3(1.2, 2.12, 0.04))
	for y in [0.08, 2.14]:
		_box(_leaf, white, Vector3(0.62, y, 0), Vector3(1.24, 0.1, 0.06))
	for x in [0.03, 1.21]:
		_box(_leaf, white, Vector3(x, 1.12, 0), Vector3(0.07, 2.2, 0.06))
	_box(_leaf, 0x2f7fe0, Vector3(0.62, 0.75, 0.03), Vector3(0.55, 0.7, 0.02))             # a poster on the glass
	_box(_leaf, 0x26262b, Vector3(1.08, 1.1, 0.05), Vector3(0.05, 0.3, 0.05))              # handle
	_box(f, 0x26262b, Vector3(-1.25, 1.75, 0.08), Vector3(0.3, 0.42, 0.04))                # opening hours
	_box(f, 0xe2562c, Vector3(-1.25, 2.12, 0.08), Vector3(0.22, 0.2, 0.04))
	# the small window
	_box(f, white, Vector3(1.45, 1.57, 0.07), Vector3(1.66, 1.62, 0.1))
	_box(f, glass, Vector3(1.45, 1.57, 0.125), Vector3(1.46, 1.42, 0.02))
	for row in range(3):
		_stock(f, Vector3(0.95, 0.9 + row * 0.42, 0.15), Vector3(0.36, 0, 0), 3, rng)
	var dot := Parts.part("cyl", 0xef7f1a, Vector3(1.85, 2.1, 0.15), Vector3(0.2, 0.03, 0.2))
	dot.rotation.x = PI / 2.0
	f.add_child(dot)
	_box(f, 0x8d99ae, Vector3(2.5, 0.75, 0.3), Vector3(0.34, 1.5, 0.3))                   # the rack of leaflets by the door
	# terracotta tiles at the doorstep
	_box(f, 0xb5683f, Vector3(DOOR_X, 0.02, 0.85), Vector3(2.5, 0.05, 1.6))
	# next door: brown plinth and a window with bars
	var rest := half - 4.6
	if rest > 1.8:
		var cx := 4.6 + rest / 2.0
		_box(f, 0x9a5a48, Vector3(cx, 0.5, 0.08), Vector3(rest, 1.0, 0.12))
		_box(f, white, Vector3(cx, 1.85, 0.07), Vector3(1.4, 1.3, 0.08))
		_box(f, glass, Vector3(cx, 1.85, 0.115), Vector3(1.2, 1.1, 0.02))
		for i in range(5):
			_box(f, 0x1b1b1f, Vector3(cx - 0.52 + i * 0.26, 1.85, 0.17), Vector3(0.035, 1.24, 0.035))
		for y in [1.35, 1.85, 2.35]:
			_box(f, 0x1b1b1f, Vector3(cx, y, 0.17), Vector3(1.34, 0.035, 0.035))

# ---------------- the inside: shop and back room ----------------
func _inside() -> void:
	_room = Node3D.new()                       # +z goes deeper into the shop; the street door is at z = 0
	_room.position = MapData.at(INSIDE)
	add_child(_room)
	_body = StaticBody3D.new()
	_body.collision_layer = 1
	_body.collision_mask = 0
	_room.add_child(_body)
	in_door = INSIDE + Vector2(0.0, 0.45)
	in_spawn = INSIDE + Vector2(0.0, 2.1)
	counter_front = INSIDE + Vector2(-1.0, 3.5)
	keeper_spot = INSIDE + Vector2(-1.0, 6.2)
	ring_me = INSIDE + RING + Vector2(0.0, -0.77)
	ring_foe = INSIDE + RING + Vector2(0.0, 0.78)
	var r := _room
	var rng := RandomNumberGenerator.new()
	rng.seed = 605
	var wall := 0xd9d0b8
	var bare := 0xa39d90
	var white := 0xf6f4ee
	# floors
	var fl := _box(r, 0xffffff, Vector3(0, -0.05, SHOP_D / 2.0), Vector3(SHOP_W * 2.0, 0.1, SHOP_D))
	fl.material_override = _checker(0xc9c2b0, 0xa9a290, 0.6)
	var fl2 := _box(r, 0xffffff, Vector3(0, -0.05, (SHOP_D + BACK_END) / 2.0), Vector3(BACK_W * 2.0, 0.1, BACK_END - SHOP_D))
	fl2.material_override = _checker(0x8f8a80, 0x858076, 1.2)
	# shop walls and ceiling
	for sx in [-1.0, 1.0]:
		_box(r, wall, Vector3(sx * (SHOP_W + 0.15), SHOP_H / 2.0, SHOP_D / 2.0), Vector3(0.3, SHOP_H, SHOP_D + 0.6), true)
		_box(r, wall, Vector3(sx * (SHOP_W + 0.7) / 2.0, SHOP_H / 2.0, -0.15), Vector3(SHOP_W - 0.7, SHOP_H, 0.3), true)    # either side of the street door
	_box(r, wall, Vector3(0, 2.75, -0.15), Vector3(1.4, 1.1, 0.3), true)
	_box(r, 0x7fa9c4, Vector3(0, 1.1, -0.12), Vector3(1.4, 2.2, 0.08), true)             # the glass door, from inside
	_box(r, white, Vector3(0, 2.24, -0.02), Vector3(1.56, 0.1, 0.1))
	for sx in [-1.0, 1.0]:
		_box(r, white, Vector3(sx * 0.74, 1.12, -0.02), Vector3(0.08, 2.24, 0.1))
	_box(r, 0x3a6b4a, Vector3(0, 0.01, 0.75), Vector3(1.4, 0.03, 0.9))                   # doormat
	_box(r, 0xcfc8b4, Vector3(0, SHOP_H + 0.1, SHOP_D / 2.0), Vector3(SHOP_W * 2.0 + 0.6, 0.2, SHOP_D + 0.6), true)
	# the wall between shop and back room, with a doorway on the right (x 2.0 .. 3.6)
	_box(r, wall, Vector3((-BACK_W + 2.0) / 2.0, BACK_H / 2.0, SHOP_D), Vector3(BACK_W + 2.0, BACK_H, 0.3), true)
	_box(r, wall, Vector3((3.6 + BACK_W) / 2.0, BACK_H / 2.0, SHOP_D), Vector3(BACK_W - 3.6, BACK_H, 0.3), true)
	_box(r, wall, Vector3(2.8, (2.3 + BACK_H) / 2.0, SHOP_D), Vector3(1.6, BACK_H - 2.3, 0.3), true)
	for i in range(11):                         # a bead curtain, like every back room in the province
		_box(r, [0xe23b3b, 0xf2c230, 0x3fa34d, 0x2f7fe0][i % 4], Vector3(2.08 + i * 0.145, 1.2, SHOP_D), Vector3(0.05, 2.2, 0.05))
	# back room walls and ceiling
	for sx in [-1.0, 1.0]:
		_box(r, bare, Vector3(sx * (BACK_W + 0.15), BACK_H / 2.0, (SHOP_D + BACK_END) / 2.0), Vector3(0.3, BACK_H, BACK_END - SHOP_D + 0.6), true)
	_box(r, bare, Vector3(0, BACK_H / 2.0, BACK_END + 0.15), Vector3(BACK_W * 2.0 + 0.6, BACK_H, 0.3), true)
	_box(r, 0x6f6a62, Vector3(0, BACK_H + 0.1, (SHOP_D + BACK_END) / 2.0), Vector3(BACK_W * 2.0 + 0.6, 0.2, BACK_END - SHOP_D + 0.6), true)
	# --- the shop ---
	_box(r, 0x2b4fa0, Vector3(-1.0, 0.5, 4.9), Vector3(4.6, 1.0, 0.7), true)             # counter
	_box(r, 0xe9e4d8, Vector3(-1.0, 1.03, 4.9), Vector3(4.8, 0.06, 0.86))
	_box(r, 0x3a3a40, Vector3(0.6, 1.2, 4.95), Vector3(0.5, 0.3, 0.45))                  # till
	_box(r, 0xd8d2c2, Vector3(-2.6, 1.3, 5.0), Vector3(0.55, 0.5, 0.5))                  # his own monitor
	_box(r, 0x1b2a3a, Vector3(-2.6, 1.32, 5.26), Vector3(0.42, 0.34, 0.02))
	_text(r, "V.I.P.", Vector3(-1.0, 2.55, SHOP_D - 0.17), 150, 0x1d3aa8, PI)
	_text(r, "Vendo e Instalo", Vector3(-1.0, 2.05, SHOP_D - 0.17), 44, 0x1b1b1f, PI)
	_box(r, 0xf2c230, Vector3(-3.5, 1.9, SHOP_D - 0.17), Vector3(1.5, 0.9, 0.03))
	_text(r, "MIRAR: 5 €\nPREGUNTAR: 10 €\nPREGUNTAR Y NO COMPRAR: 40 €", Vector3(-3.5, 1.9, SHOP_D - 0.2), 26, 0x1b1b1f, PI)
	for k in range(3):                          # shelves along the left wall
		var y := 0.55 + k * 0.6
		_box(r, 0xb98a52, Vector3(-SHOP_W + 0.25, y, 2.9), Vector3(0.5, 0.05, 3.6))
		_stock(r, Vector3(-SHOP_W + 0.25, y + 0.03, 1.3), Vector3(0, 0, 0.4), 9, rng, Vector3(0.3, 0.26, 0.24))
	_box(r, 0x8d99ae, Vector3(-SHOP_W + 0.25, 0.25, 2.9), Vector3(0.5, 0.5, 3.6), true)
	# the right wall: two old computers. One turns on.
	_box(r, 0xb98a52, Vector3(SHOP_W - 0.5, 0.75, 2.9), Vector3(1.0, 0.08, 3.2))
	_box(r, 0x8a6a48, Vector3(SHOP_W - 0.5, 0.36, 2.9), Vector3(0.9, 0.72, 3.0), true)
	for i in range(2):
		var z := 2.1 + i * 1.6
		_box(r, 0xd8d2c2, Vector3(SHOP_W - 0.45, 1.05, z), Vector3(0.6, 0.52, 0.62))
		var scr := _box(r, 0x10141a, Vector3(SHOP_W - 0.76, 1.07, z), Vector3(0.02, 0.38, 0.46))
		if i == 0:
			scr.material_override = _glow(0x3f8fe0, 1.4)
		else:
			_box(r, 0xf6f4ee, Vector3(SHOP_W - 0.78, 1.07, z), Vector3(0.02, 0.16, 0.3))
			_text(r, "NO VA", Vector3(SHOP_W - 0.795, 1.07, z), 22, 0xb23a3a, -PI / 2.0)
		_box(r, 0xd8d2c2, Vector3(SHOP_W - 0.72, 0.82, z), Vector3(0.2, 0.04, 0.46))      # keyboard
	_lamp(r, Vector3(0, 2.8, 2.4), 0.45, 9.0)
	_lamp(r, Vector3(-1.0, 2.8, 5.6), 0.4, 8.0)
	for z in [2.4, 5.6]:
		_box(r, 0xffffff, Vector3(0, SHOP_H - 0.04, z), Vector3(1.4, 0.06, 0.24)).material_override = _glow(0xfff6e0, 1.5)
	# --- the back room: boxes of stock, and the ring ---
	for i in range(9):
		var s := rng.randf_range(0.6, 1.0)
		var bx := -BACK_W + 0.7 + rng.randf() * 1.2 if i < 5 else BACK_W - 0.7 - rng.randf() * 1.0
		_box(r, [0xb98a52, 0xa67c47, 0xc49a62][i % 3], Vector3(bx, s / 2.0, SHOP_D + 0.8 + (i % 5) * 0.75), Vector3(s, s, s))
	var c := Vector3(RING.x, 0, RING.y)
	_box(r, 0xb23a3a, c + Vector3(0, RING_H / 2.0 - 0.02, 0), Vector3(RING_HALF * 2.0 + 0.5, RING_H - 0.04, RING_HALF * 2.0 + 0.5), true)     # apron
	_box(r, 0x3f6fc0, c + Vector3(0, RING_H - 0.02, 0), Vector3(RING_HALF * 2.0 + 0.3, 0.04, RING_HALF * 2.0 + 0.3))                       # canvas
	_text(r, "V.I.P.", c + Vector3(0, RING_H + 0.005, 0), 220, 0x5f8fd8).rotation = Vector3(-PI / 2.0, PI, 0)
	var corner := [0xe23b3b, 0xf6f4ee, 0x2f7fe0, 0xf6f4ee]
	var k := 0
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var post := Parts.part("cyl", 0x3a3a40, c + Vector3(sx * RING_HALF, RING_H + 0.75, sz * RING_HALF), Vector3(0.08, 1.5, 0.08))
			r.add_child(post)
			_box(r, corner[k], c + Vector3(sx * (RING_HALF - 0.12), RING_H + 1.05, sz * (RING_HALF - 0.12)), Vector3(0.3, 0.75, 0.3))   # corner pad
			k += 1
	for i in range(3):
		var y := RING_H + 0.55 + i * 0.4
		var col: int = [0xe23b3b, 0xf6f4ee, 0x2f7fe0][i]
		for s in [-1.0, 1.0]:
			_box(r, col, c + Vector3(0, y, s * RING_HALF), Vector3(RING_HALF * 2.0, 0.045, 0.045))
			_box(r, col, c + Vector3(s * RING_HALF, y, 0), Vector3(0.045, 0.045, RING_HALF * 2.0))
	# the light over the ring, the bell, the banner
	_box(r, 0x26262b, c + Vector3(0, BACK_H - 0.15, 0), Vector3(0.05, 0.3, 0.05))
	var shade := Parts.part("cone", 0x2f5d3a, c + Vector3(0, BACK_H - 0.5, 0), Vector3(0.9, 0.45, 0.9))
	r.add_child(shade)
	var bulb := Parts.part("ball", 0xffffff, c + Vector3(0, BACK_H - 0.72, 0), Vector3.ONE * 0.14)
	bulb.material_override = _glow(0xfff1c0, 2.5)
	r.add_child(bulb)
	_lamp(r, c + Vector3(0, BACK_H - 0.9, 0), 1.2, 13.0, 0xfff0cf)
	_lamp(r, Vector3(-4.0, 3.6, 9.5), 0.25, 9.0)
	_lamp(r, Vector3(4.0, 3.6, 19.5), 0.25, 9.0)
	_box(r, 0x8a6a48, c + Vector3(RING_HALF + 0.9, 0.55, -RING_HALF - 0.4), Vector3(0.5, 1.1, 0.5), true)      # the bell table
	var bell := Parts.part("dome", 0xe6b422, c + Vector3(RING_HALF + 0.9, 1.12, -RING_HALF - 0.4), Vector3(0.2, 0.18, 0.2))
	r.add_child(bell)
	_box(r, 0xf4f1e8, Vector3(0, 3.5, BACK_END - 0.02), Vector3(8.4, 1.5, 0.04))
	_text(r, "GRAN VELADA V.I.P.", Vector3(0, 3.82, BACK_END - 0.06), 150, 0xb23a3a, PI)
	_text(r, "EL FONSI  contra  EL QUE NO PAGA", Vector3(0, 3.2, BACK_END - 0.06), 72, 0x1b1b1f, PI)
	_text(r, "PROHIBIDO ESCUPIR\n(al dueño)", Vector3(-BACK_W + 0.02, 2.4, 14.4), 54, 0x3a3a40, PI / 2.0)
	for n in r.get_children():                 # indoors: the sun does not reach any of this (the sun's cull mask in game.gd leaves this layer out)
		if n is MeshInstance3D:
			n.layers = 1 << 10
	# where the neighbours stand: the far side and both flanks, never between you and the camera
	var edge := RING_HALF + 1.05
	for i in range(6):
		crowd_spots.append(INSIDE + RING + Vector2(-3.25 + i * 1.3, edge + (0.5 if i % 2 == 1 else 0.0)))
	for i in range(3):
		crowd_spots.append(INSIDE + RING + Vector2(-edge, -0.6 + i * 1.3))
		crowd_spots.append(INSIDE + RING + Vector2(edge, -0.6 + i * 1.3))
