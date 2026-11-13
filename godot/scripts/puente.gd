extends Node3D
## The old bridge over the Calle del Arroyuelo Medio: a hundred years and more of it, a slab on two abutments and a
## pier in the middle, low over what was the bed of the stream and is now the street. People cross on top; a car does
## not get under it, which is why the town hall wants it down ("a wide street for the cars") -- with the Calle de
## Matías Pérez, just as wide, twenty metres away. It stands where the real one stood: a little way up the street
## from that corner.
##
## Local frame: +x across the street (the way the deck runs), +z along the street, origin on the street's centre line.
## Also here, and taken away again when the mission is over: the dressing of the demonstration (banner, table).

const Parts = preload("res://scripts/parts.gd")
const AT := Vector2(-148.4, -265.4)
const DECK := 0.9               # the top of the deck over the street
const WIDE := 3.0               # the deck, along the street
const RAMP := 1.2               # the three steps at each end
const STONE := 0xb9ad96

var p: Vector2                  # its middle, on the street
var u: Vector2                  # along the street
var across: Vector2             # along the deck
var hw := 3.75                  # half the bed of the old stream (what the bridge crosses)
var half := 4.1                 # half the deck, steps and all
var open := 1.0                 # which end has a pavement to step down on to (+1 or -1 along `across`); the other is against the houses
var seg                         # the stretch of street it stands on (closed to cars)
var top := 0.0                  # the deck's height in the world
var dressing: Node3D            # the demonstration's things (null when there is no demonstration)
var _world

func build(game, world) -> void:
	_world = world
	var r: Dictionary = MapData.nearest_road(AT)
	var c0: Vector2 = r["p"]
	u = r["u"]
	across = Vector2(u.y, -u.x)                  # (this node's own +x)
	seg = r["seg"]
	# The street as the map has it is a narrow strip against the houses on one side; the real one fills the gap
	# between the two rows of houses, and that is what the bridge crosses. So: how far is it to a wall each way?
	var room := [0.0, 0.0]
	for k in range(2):
		var dir: Vector2 = across * (1.0 if k == 0 else -1.0)
		while room[k] < 9.0 and MapData.room_at(c0 + dir * (room[k] + 0.2)) > 0.3:
			room[k] += 0.2
	open = 1.0 if room[0] >= room[1] else -1.0
	var wide_side: float = minf(maxf(room[0], room[1]) - 1.7, 6.0)      # leave a pavement on the open side...
	var tight_side: float = minf(room[0], room[1]) - 0.35                # ...and go right up to the houses on the other
	hw = (wide_side + tight_side) / 2.0
	p = c0 + across * open * (wide_side - tight_side) / 2.0
	half = hw + 0.35
	top = MapData.height(p) + DECK
	position = MapData.at(p)
	rotation.y = atan2(u.x, u.y)
	game.add_child(self)
	MapData.block(seg)                           # no way through for a car
	_bed(world)
	MapData.decks.append({"o": p, "ax": across, "half": half, "wide": WIDE / 2.0 - 0.15, "top": top, "ramp": RAMP})
	var brick: StandardMaterial3D = world._tmat(0xffffff, "brick", 1.4)
	var flat := half - RAMP                      # half the level part of the deck
	# the slab, its brick faces and a low kerb along each edge
	_box(STONE, Vector3(0, DECK - 0.14, 0), Vector3(flat * 2.0, 0.28, WIDE))
	for sz in [-1.0, 1.0]:
		_box(brick, Vector3(0, DECK - 0.2, sz * (WIDE / 2.0 + 0.04)), Vector3(half * 2.0, 0.42, 0.1))
		_box(0x9c917b, Vector3(0, DECK + 0.09, sz * (WIDE / 2.0 - 0.1)), Vector3(flat * 2.0 + 0.4, 0.18, 0.22))
	# the abutments and the pier: stone, a little wider at the foot, a century of damp up them
	for sx in [-1.0, 0.0, 1.0]:
		var wide := 0.8 if sx == 0.0 else 0.6
		_box(STONE, Vector3(sx * (flat - 0.3), (DECK - 0.28) / 2.0, 0), Vector3(wide, DECK - 0.28, WIDE - 0.3))
		_box(0x8f8672, Vector3(sx * (flat - 0.3), 0.09, 0), Vector3(wide + 0.3, 0.18, WIDE))
	# three steps down to the pavement at each end
	for sx in [-1.0, 1.0]:
		for k in range(3):
			var tread := RAMP / 3.0
			var rise := DECK * (3 - k) / 3.0 - DECK / 6.0
			_box(STONE, Vector3(sx * (flat + tread * (k + 0.5)), rise / 2.0, 0), Vector3(tread, rise, WIDE - 0.2))
	# the year, cut in the keystone of the face you see as you come down the street
	for sz in [-1.0, 1.0]:
		var stone := _box(0xd9cfbc, Vector3(0, DECK - 0.2, sz * (WIDE / 2.0 + 0.1)), Vector3(0.9, 0.34, 0.04))
		var year := Label3D.new()
		year.text = "1911"
		year.font_size = 56
		year.pixel_size = 0.004
		year.modulate = Color("5a4632")
		year.outline_size = 0
		year.position = Vector3(0, DECK - 0.2, sz * (WIDE / 2.0 + 0.13))
		year.rotation.y = 0.0 if sz > 0.0 else PI
		add_child(year)
	# what stops a car (and keeps whoever is on top, on top): a wall down each long side
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for sz in [-1.0, 1.0]:
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(half * 2.0, DECK + 1.3, 0.3)
		cs.shape = shape
		cs.position = Vector3(0, (DECK + 1.3) / 2.0 - 0.5, sz * WIDE / 2.0)
		body.add_child(cs)

## The bed of the old stream: concrete from wall to wall along this stretch of street, and a low stone kerb between
## it and the pavement on the open side (with a gap where the steps of the bridge come down).
func _bed(world) -> void:
	var from: float = (seg.a - p).dot(u) + 2.0
	var to: float = (seg.b - p).dot(u) - 2.0
	var v := PackedVector3Array()
	for q in [spot(-hw, from), spot(hw, from), spot(hw, to), spot(-hw, to)]:
		v.append(Vector3(q.x, 0.0, q.y))
	world._flat(v, PackedInt32Array([0, 1, 2, 0, 2, 3]), 0xb7b0a1, 0.012, null, "asphalt", 5.0)
	var z := from
	while z < to - 0.5:
		var run := minf(2.0, to - z)
		if absf(z + run / 2.0) > WIDE / 2.0 + 1.1:
			var at: Vector2 = spot(open * (hw + 0.2), z + run / 2.0)
			var kerb := _box(0x9c917b, Vector3.ZERO, Vector3(0.4, 0.5, run + 0.05))
			kerb.top_level = true
			kerb.global_transform = Transform3D(Basis(Vector3.UP, atan2(u.x, u.y)) * Basis.from_scale(Vector3(0.4, 0.5, run + 0.05)), MapData.at(at, 0.2))
		z += run

func _box(material, pos: Vector3, size: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var mi := Parts.part("box", 0xffffff, pos, size)
	mi.material_override = material if material is Material else Parts.mat(material)
	(parent if parent != null else self).add_child(mi)
	return mi

## a spot given in the bridge's own terms (metres across the street, metres along it), as a place in the town
## Until the town has made it its own (the player spends Puntos Cívicos on it: game.gd, _unlock_bridge) the council
## has it fenced off: nobody walks over it. A barrier of red and white tape and a notice at each end, and -- unseen --
## a wall round the deck.
var fence: Node3D

func closed() -> bool:
	return fence != null

func close_off(on: bool) -> void:
	if on == (fence != null):
		return
	if not on:
		fence.queue_free()
		fence = null
		return
	fence = Node3D.new()
	add_child(fence)
	var body := StaticBody3D.new()
	body.collision_layer = 8                     # (as a tree is: people stop at it, and the camera does not take it for a house)
	body.collision_mask = 0
	fence.add_child(body)
	var flat := half - RAMP
	for wall in [[Vector3(half + 0.15, 1.2, 0.0), Vector3(0.2, 2.6, WIDE + 0.6)], [Vector3(-half - 0.15, 1.2, 0.0), Vector3(0.2, 2.6, WIDE + 0.6)],
			[Vector3(0.0, 1.2, WIDE / 2.0 + 0.2), Vector3(half * 2.0, 2.6, 0.2)], [Vector3(0.0, 1.2, -WIDE / 2.0 - 0.2), Vector3(half * 2.0, 2.6, 0.2)]]:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = wall[1]
		cs.shape = bs
		cs.position = wall[0]
		body.add_child(cs)
	for end in [-1.0, 1.0]:                          # what is seen of it: two posts, two runs of tape, a notice
		var x: float = end * (flat + 0.25)
		for sz in [-1.0, 1.0]:
			_box(0xd9d4c8, Vector3(x, DECK + 0.55, sz * (WIDE / 2.0 - 0.12)), Vector3(0.08, 1.1, 0.08), fence)
		for row in range(2):
			for k in range(8):
				_box(0xc8102e if k % 2 == 0 else 0xf4f1e8, Vector3(x, DECK + 0.55 + row * 0.4, -WIDE / 2.0 + 0.3 + k * (WIDE - 0.6) / 7.0), Vector3(0.02, 0.09, (WIDE - 0.6) / 7.0), fence)
		_box(0xf4f1e8, Vector3(x + end * 0.03, DECK + 0.75, 0.0), Vector3(0.03, 0.42, 1.25), fence)
		var notice := Label3D.new()
		notice.text = "AYUNTAMIENTO\nPROHIBIDO EL PASO"
		notice.font_size = 44
		notice.pixel_size = 0.0034
		notice.modulate = Parts.col(0xc8102e)
		notice.outline_size = 0
		notice.position = Vector3(x + end * 0.05, DECK + 0.75, 0.0)
		notice.rotation.y = end * PI / 2.0
		fence.add_child(notice)

func spot(x: float, z: float) -> Vector2:
	return p + across * x + u * z

## how far out from the middle of the bridge the pavement is (on the open side: the other side has none)
func kerb() -> float:
	return hw + 1.0

## puts up (or takes down) what the demonstration has brought: the banner across the street, the table with the sheets
func dress(on: bool) -> void:
	if not on:
		if dressing != null:
			dressing.queue_free()
			dressing = null
		return
	if dressing != null:
		return
	dressing = Node3D.new()
	add_child(dressing)
	var reach := hw - 0.1
	for sx in [-1.0, 1.0]:                        # the banner, strung between two poles up the street from the bridge
		dressing.add_child(Parts.part("cyl", 0x6b4a34, Vector3(sx * reach, 2.4, -6.5), Vector3(0.06, 4.8, 0.06)))
	_box(0xf4f1e8, Vector3(0, 4.25, -6.5), Vector3(reach * 2.0, 0.95, 0.03), dressing)
	for face in [1.0, -1.0]:
		var text := Label3D.new()
		text.text = Loc.t("bridge_banner")
		text.font_size = 100
		text.pixel_size = 0.0052
		text.modulate = Color("b23a3a")
		text.outline_size = 0
		text.position = Vector3(0, 4.25, -6.5 + 0.03 * face)
		text.rotation.y = 0.0 if face > 0.0 else PI
		dressing.add_child(text)
	var tx := open * (hw + 1.15)                  # the table with the signature sheets and the collection tin, on the pavement
	_box(0xd8d2c2, Vector3(tx, 0.74, -3.6), Vector3(0.8, 0.05, 1.5), dressing)
	for q in [Vector2(-0.3, -0.6), Vector2(0.3, -0.6), Vector2(-0.3, 0.6), Vector2(0.3, 0.6)]:
		_box(0x8d99ae, Vector3(tx + q.x, 0.37, -3.6 + q.y), Vector3(0.04, 0.74, 0.04), dressing)
	_box(0xfaf8f2, Vector3(tx, 0.775, -3.4), Vector3(0.3, 0.01, 0.42), dressing)
	_box(0xfaf8f2, Vector3(tx + 0.1, 0.78, -4.0), Vector3(0.3, 0.01, 0.42), dressing)
	dressing.add_child(Parts.part("cyl", 0xd23b3b, Vector3(tx - 0.15, 0.86, -3.05), Vector3(0.09, 0.18, 0.09)))
	var bunting := [0xb23a3a, 0xf2c230, 0x2f8f5b, 0x3b5fa8]      # a string of little flags along the bridge
	for k in range(11):
		var flag := _box(bunting[k % 4], Vector3(-half + 0.4 + k * (half * 2.0 - 0.8) / 10.0, DECK + 0.02, WIDE / 2.0 + 0.11), Vector3(0.24, 0.3, 0.012), dressing)
		flag.rotation.z = 0.12 if k % 2 == 0 else -0.12

## a placard for one of the demonstrators to hold: a stick and a board with something painted on it
static func placard(text: String, hex: int) -> Node3D:
	var g := Node3D.new()
	g.position = Vector3(0.52, 0.0, 0.12)
	g.rotation.z = -0.08
	g.add_child(Parts.part("cyl", 0x8a6a48, Vector3(0, 1.55, 0), Vector3(0.035, 2.2, 0.035)))
	g.add_child(Parts.part("box", hex, Vector3(0, 2.75, 0), Vector3(1.15, 0.72, 0.03)))
	for face in [1.0, -1.0]:
		var l := Label3D.new()
		l.text = text
		l.font_size = 30
		l.pixel_size = 0.0045
		l.modulate = Color("26221e")
		l.outline_size = 0
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.width = 240.0
		l.line_spacing = -3.0
		l.position = Vector3(0, 2.75, 0.02 * face)
		l.rotation.y = 0.0 if face > 0.0 else PI
		g.add_child(l)
	return g
