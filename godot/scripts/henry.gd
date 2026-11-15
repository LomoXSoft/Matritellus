extends Node3D
## La Cocina de Henry: roasts and home cooking to take away, on the Calle de la Palma.
## The shopfront is laid over a real house front there (Catastro), loosely after the take-away that stands in that
## street: dark stone below, a big wooden-framed opening with a curtained door and window, reed blinds folded back at
## the sides, and a yellow sign box over it. The name, the lettering and the ham on the sign are made up.

const Parts = preload("res://scripts/parts.gd")

const WALL_A := Vector2(-86.94, -69.88)      # the narrow pink house next to the tobacconist (Palma 3 B, Catastro 4192004): the
const WALL_B := Vector2(-90.04, -73.01)      # user, 15 November 2026, with a Street View photo (it had been put two doors on)
const STREET := Vector2(-85.6, -74.3)        # a point out in the street, to know which side is outside

var door: Vector2             # the doorway
var spot: Vector2             # where Henry stands, by the door

func _box(parent: Node3D, hex: int, pos: Vector3, size: Vector3) -> MeshInstance3D:
	var mi := Parts.part("box", hex, pos, size)
	parent.add_child(mi)
	return mi

func _text(parent: Node3D, s: String, pos: Vector3, px: int, hex: int) -> Label3D:
	var l := Label3D.new()
	l.text = s
	l.font_size = px
	l.pixel_size = 0.004
	l.modulate = Parts.col(hex)
	l.outline_size = 0
	l.position = pos
	parent.add_child(l)
	return l

func build() -> void:
	var mid := (WALL_A + WALL_B) / 2.0
	var along := (WALL_B - WALL_A).normalized()
	var out := Vector2(-along.y, along.x)
	if out.dot(STREET - mid) < 0.0:
		out = -out
	var half := WALL_A.distance_to(WALL_B) / 2.0
	var sq := minf(1.0, (half * 2.0 - 0.3) / 6.5)  # the shopfront is drawn for a front of 6.5 m or more: narrower, it is squeezed sideways
	var lx := Vector2(out.y, -out.x)           # the facade's own +x (to your right as you face it)
	door = mid + lx * (-1.9 * sq) + out * 0.2
	spot = mid + lx * (-3.1 * sq) + out * 1.0
	var f := Node3D.new()                      # +x along the wall, +z out into the street
	f.position = MapData.at(mid, -0.06)
	f.rotation.y = atan2(out.x, out.y)
	add_child(f)
	var stone := 0x33363b
	var wood := 0x6b4028
	var reed := 0x8a6a48
	var linen := 0xf1ede2
	_box(f, 0xd9a09a, Vector3(0, 1.75, 0.02), Vector3(half * 2.0, 3.5, 0.05))                 # the pink of the house
	_box(f, stone, Vector3(0, 1.55, 0.05), Vector3(half * 2.0, 3.1, 0.08))                    # dark stone round the shop
	_box(f, 0x26282c, Vector3(0, 3.14, 0.08), Vector3(half * 2.0, 0.12, 0.14))
	var shop := Node3D.new()                   # (what follows, squeezed by sq along the front)
	shop.scale = Vector3(sq, 1.0, 1.0)
	f.add_child(shop)
	# the opening: one wooden frame, door on the left, window on the right
	_box(shop, wood, Vector3(-0.2, 1.55, 0.1), Vector3(5.2, 2.5, 0.08))
	_box(shop, 0x191a1d, Vector3(-1.9, 1.3, 0.13), Vector3(1.1, 2.0, 0.03))                      # the doorway, dark inside
	for k in range(7):                                                                         # its curtain of strips
		_box(shop, [0xd8d2c2, 0xbdb6a6][k % 2], Vector3(-2.38 + k * 0.16, 1.32, 0.16), Vector3(0.11, 1.96, 0.02))
	_box(shop, linen, Vector3(-0.95, 1.4, 0.15), Vector3(0.5, 1.5, 0.03))                        # the glazed panel beside it
	_box(shop, 0x23303d, Vector3(0.9, 1.5, 0.13), Vector3(2.5, 1.7, 0.03))                       # the window
	for sx in [-1.0, 1.0]:
		_box(shop, linen, Vector3(0.9 + sx * 0.62, 1.52, 0.155), Vector3(1.16, 1.6, 0.02))        # white curtains
	_box(shop, 0xfaf8f2, Vector3(1.35, 1.5, 0.17), Vector3(0.3, 0.42, 0.01))                     # the menu, taped up
	for x in [-2.5, -1.3, -0.6, 2.2]:
		_box(shop, wood, Vector3(x, 1.4, 0.16), Vector3(0.1, 2.2, 0.06))
	for y in [0.32, 2.42, 2.74]:
		_box(shop, wood, Vector3(-0.2, y, 0.16), Vector3(5.2, 0.1, 0.06))
	_box(shop, 0x23303d, Vector3(-0.2, 2.58, 0.13), Vector3(5.0, 0.24, 0.03))                    # the fanlights along the top
	for sx in [-1.0, 1.0]:                                                                     # reed blinds, folded back
		_box(shop, reed, Vector3(-0.2 + sx * 2.95, 1.5, 0.14), Vector3(0.55, 2.5, 0.06))
		for k in range(6):
			_box(shop, 0x6b5238, Vector3(-0.2 + sx * 2.95, 0.45 + k * 0.42, 0.175), Vector3(0.55, 0.03, 0.01))
	_box(shop, 0x2a2c30, Vector3(-1.9, 0.06, 0.45), Vector3(1.4, 0.12, 0.7))                     # the step
	# the sign box: yellow, with the ham that made the house famous
	var sign := Node3D.new()
	sign.position = Vector3(0.3 * sq, 3.95, 0.35)
	sign.scale = Vector3.ONE * minf(1.0, half * 2.0 / 5.2)
	sign.rotation.x = 0.16
	f.add_child(sign)
	_box(sign, 0x2a2c30, Vector3(0, 0, -0.06), Vector3(4.9, 1.15, 0.5))
	_box(sign, 0xf2a900, Vector3(0, 0, 0.2), Vector3(4.7, 1.0, 0.03))
	_box(sign, 0x2a2c30, Vector3(0.75, 0.12, 0.215), Vector3(2.9, 0.5, 0.01))
	_text(sign, "ASADOS Y COMIDAS CASERAS", Vector3(0.75, 0.2, 0.225), 44, 0xfff6e0)
	_text(sign, "para llevar (o pa comer en el coche)", Vector3(0.75, 0.02, 0.225), 26, 0xfff6e0)
	_text(sign, "LA COCINA DE HENRY", Vector3(0.75, -0.3, 0.225), 62, 0x2a2c30)
	var plate := Parts.part("cyl", 0xfaf8f2, Vector3(-1.6, 0.0, 0.215), Vector3(0.42, 0.02, 0.42))
	plate.rotation.x = PI / 2.0
	sign.add_child(plate)
	sign.add_child(Parts.part("ball", 0x9a4a2a, Vector3(-1.66, -0.02, 0.25), Vector3(0.25, 0.18, 0.05)))     # the ham
	sign.add_child(Parts.part("ball", 0xc9683a, Vector3(-1.7, 0.02, 0.265), Vector3(0.14, 0.09, 0.04)))
	var bone := Parts.part("box", 0xfaf8f2, Vector3(-1.38, 0.1, 0.25), Vector3(0.2, 0.05, 0.03))
	bone.rotation.z = 0.5
	sign.add_child(bone)
	sign.add_child(Parts.part("ball", 0xfaf8f2, Vector3(-1.28, 0.16, 0.25), Vector3.ONE * 0.045))
