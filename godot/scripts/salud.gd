extends Node3D
## The health centre, hand-built over its real footprint (Catastro) from the user's street photos of 14 November 2026
## (referencias/centro_salud/): between the Calle de Argentina and the Callejón Pando, with the little square and its
## parking along its west side.
##
## What it is: one low block of buff split-faced stone with pairs of brick bands at the sills and the heads of its
## tall narrow windows (each behind a mesh, between brick jambs), a concrete coping with spouts sticking out of it, and
## a taller lantern over the waiting room. The way in is at the corner of the Calle de Argentina and the square, set
## back under a canopy behind a row of white grilles. On the Callejón Pando, at its east end, the casualty wing: white
## and modern, a concrete porch under a floor of wooden louvres.
##
## The signs say what it is (CENTRO DE SALUD, URGENCIAS) and nothing else: no emblem of the real health service.
##
## Its own frame (MapData.salud): the origin is the south-west corner (Callejón Pando and the square), +x runs east
## along the Callejón Pando, +z points south, out into that street: the main block is x 0..36, z -25..0.

const Parts = preload("res://scripts/parts.gd")
const Tex = preload("res://scripts/texturas.gd")
const H := 4.3                  # the walls of the main block, up to the coping
const COPING := 0.55
const LANTERN := 6.3            # the top of the taller part
const UH := 7.6                 # the casualty wing
const PORCH := 3.5              # how far its porch goes in
const BUFF := Color(1.0, 0.84, 0.6)
const CONCRETE := 0xcfc9bb
const WHITE := 0xf4f2ec
const GLASS := 0x27303a
const MESH := 0x66736b

var W
var door: Vector2               # in front of the main entrance, on the map (where somebody brought here would come out)
var casualty: Vector2           # ...and under the porch of the casualty wing
var windows := 0
var furniture := 0              # how many pieces of street furniture it asked props.gd for
var _stone: Material
var _brick: Material

func build(world) -> void:
	W = world
	var c: Dictionary = MapData.salud
	if c.is_empty():
		return
	var u := Vector2(c["u"][0], c["u"][1])
	transform = Transform3D(Basis(Vector3.UP, atan2(-u.y, u.x)), MapData.at(Vector2(c["o"][0], c["o"][1])))
	W.add_child(self)
	var s := Tex.pick("slab")
	_stone = Tex.mat(s, BUFF) if s != "" else Parts.mat(0xd9b98a)
	var b := Tex.pick("brick_red")
	_brick = Tex.mat(b) if b != "" else Parts.mat(0xa8553c)
	door = spot(1.6, -27.6)
	casualty = spot(40.0, -1.6)
	_main()
	_entrance()
	_casualty()
	_street()

## a spot in the building's own frame, as a place in the town
func spot(x: float, z: float) -> Vector2:
	var p := transform * Vector3(x, 0, z)
	return Vector2(p.x, p.z)

# ---------------- helpers ----------------
func _box(material, pos: Vector3, size: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var mi: MeshInstance3D
	if material is Material:                      # (a photo texture: the box is made at its real size, or the texture would stretch with it)
		mi = MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = size
		mi.mesh = bm
		mi.position = pos
		mi.material_override = material
	else:
		mi = Parts.part("box", 0xffffff, pos, size)
		mi.material_override = Parts.mat(int(material))
	(parent if parent != null else self).add_child(mi)
	return mi

## a block from x0..x1, z0..z1 (z0 < z1), y0..y1
func _vol(material, x0: float, x1: float, z0: float, z1: float, y0: float, y1: float) -> MeshInstance3D:
	return _box(material, Vector3((x0 + x1) / 2.0, (y0 + y1) / 2.0, (z0 + z1) / 2.0), Vector3(x1 - x0, y1 - y0, z1 - z0))

## a frame standing on a wall: +x runs along it (to the right of somebody looking at it), +z comes out of it
func _face(at: Vector3, turn: float) -> Node3D:
	var f := Node3D.new()
	f.position = at
	f.rotation.y = turn
	add_child(f)
	return f

func _text(parent: Node3D, s: String, pos: Vector3, px: int, hex: int) -> Label3D:
	var l := Label3D.new()
	l.text = s
	l.font_size = px
	l.pixel_size = 0.004
	l.modulate = Parts.col(hex)
	l.outline_size = 0
	l.shaded = false
	l.position = pos
	parent.add_child(l)
	return l

## One wall of the main block, dressed: `f` is its frame, `wide` its length; the grey foot, the two pairs of brick
## bands, the coping with its spouts, and a window at each of `at` (metres along it).
func _dress(f: Node3D, wide: float, at: Array, top := H, spouts := true) -> void:
	_box(0x9a958a, Vector3(wide / 2.0, 0.22, 0.03), Vector3(wide + 0.06, 0.44, 0.06), f)
	for y in [1.42, 1.72, 3.02, 3.32]:
		_box(_brick, Vector3(wide / 2.0, y, 0.02), Vector3(wide + 0.04, 0.13, 0.05), f)
	_box(CONCRETE, Vector3(wide / 2.0, top + COPING / 2.0, 0.07), Vector3(wide + 0.3, COPING, 0.16), f)
	_box(0x8f887a, Vector3(wide / 2.0, top - 0.03, 0.04), Vector3(wide + 0.1, 0.06, 0.09), f)
	if spouts:
		var n := maxi(1, int(wide / 4.5))
		for i in range(n):
			_box(CONCRETE, Vector3((i + 0.5) * wide / n, top + 0.1, 0.3), Vector3(0.3, 0.22, 0.5), f)
	for x in at:
		_window(f, float(x))

## a tall narrow window: brick jambs, a stone sill and head, the glass well in, and the mesh over it
func _window(f: Node3D, x: float, w := 0.95, sill := 1.52, h := 1.72) -> void:
	_box(GLASS, Vector3(x, sill + h / 2.0, -0.02), Vector3(w, h, 0.12), f)
	_box(MESH, Vector3(x, sill + h * 0.44, 0.045), Vector3(w + 0.04, h * 0.88, 0.03), f)
	for i in range(1, 6):          # (the mesh: a few lines across it are enough at this size)
		_box(0x4e5a53, Vector3(x, sill + h * 0.88 * i / 6.0, 0.062), Vector3(w + 0.04, 0.02, 0.01), f)
	for sx in [-1.0, 1.0]:
		_box(_brick, Vector3(x + sx * (w / 2.0 + 0.09), sill + h / 2.0, 0.03), Vector3(0.18, h + 0.1, 0.07), f)
	_box(CONCRETE, Vector3(x, sill - 0.05, 0.07), Vector3(w + 0.5, 0.1, 0.16), f)
	_box(CONCRETE, Vector3(x, sill + h + 0.08, 0.04), Vector3(w + 0.4, 0.16, 0.1), f)
	windows += 1

# ---------------- the main block ----------------
func _main() -> void:
	_vol(_stone, -0.7, 35.8, -24.6, 0.0, 0.0, H + COPING - 0.02)           # the body
	_vol(_stone, 4.0, 23.6, -28.6, -24.6, 0.0, H + COPING - 0.02)          # ...and the part that comes forward to the Calle de Argentina
	_vol(0xb9b4a8, -0.5, 35.6, -28.4, -0.2, H + COPING - 0.05, H + COPING) # (the flat roof, seen from the upper floors around)
	# south, on the Callejón Pando
	var at: Array = []
	for i in range(11):
		at.append(2.4 + i * 3.1)
	_dress(_face(Vector3(-0.7, 0, 0.0), 0.0), 36.5, at)
	# west, on the square (its frame runs from the Calle de Argentina end southwards)
	_dress(_face(Vector3(-0.7, 0, -24.6), -PI / 2.0), 24.6, [3.4, 7.2, 11.0, 14.8, 18.6, 22.0])
	# north, on the Calle de Argentina (from its east end westwards): the sign takes the place of the last window
	var nf := _face(Vector3(23.6, 0, -28.6), PI)
	_dress(nf, 19.6, [2.0, 4.6, 7.2, 9.8, 12.4, 15.0])
	_box(WHITE, Vector3(17.6, 3.0, 0.1), Vector3(2.7, 1.5, 0.08), nf)
	_box(0x2a3f8f, Vector3(17.6, 3.2, 0.13), Vector3(2.7, 1.1, 0.04), nf)
	_text(nf, "CENTRO\nDE SALUD", Vector3(17.6, 3.2, 0.16), 72, 0xffffff)
	_text(nf, "La Mancha", Vector3(17.6, 2.45, 0.16), 34, 0x2a3f8f)      # (the user, 16 November 2026: no "Castilla" on the game's signs)
	# the return of that part towards the entrance, and the east ends (seen only over the neighbours' yards)
	_dress(_face(Vector3(4.0, 0, -28.6), -PI / 2.0), 4.0, [], H, false)
	_dress(_face(Vector3(23.6, 0, -24.6), PI / 2.0), 4.0, [], H, false)
	_dress(_face(Vector3(35.8, 0, -24.6), PI), 12.2, [3.0, 6.2, 9.4], H, false)
	_dress(_face(Vector3(35.8, 0, 0.0), PI / 2.0), 24.6, [], H, false)
	for q in [Vector2(4.0, -28.6)]:                # the corner by the entrance is of brick, as a pier
		_vol(_brick, q.x - 0.05, q.x + 0.55, q.y - 0.05, q.y + 0.55, 0.45, H - 0.05)
	# the lantern over the waiting room: taller, with a row of little square windows under its own coping
	_vol(_stone, 3.0, 15.0, -23.4, -13.0, H, LANTERN + COPING - 0.02)
	for side in [[Vector3(15.0, 0, -23.4), PI, 12.0], [Vector3(3.0, 0, -23.4), -PI / 2.0, 10.4], [Vector3(3.0, 0, -13.0), 0.0, 12.0], [Vector3(15.0, 0, -13.0), PI / 2.0, 10.4]]:
		var lf := _face(side[0], side[1])
		var wide: float = side[2]
		_box(CONCRETE, Vector3(wide / 2.0, LANTERN + COPING / 2.0, 0.07), Vector3(wide + 0.3, COPING, 0.16), lf)
		_box(_brick, Vector3(wide / 2.0, H + COPING + 0.25, 0.02), Vector3(wide + 0.04, 0.13, 0.05), lf)
		var n := int(wide / 1.7)
		for i in range(n):
			_box(GLASS, Vector3((i + 0.5) * wide / n, LANTERN - 0.55, 0.02), Vector3(0.62, 0.55, 0.06), lf)
			_box(_brick, Vector3((i + 0.5) * wide / n, LANTERN - 0.88, 0.03), Vector3(0.8, 0.08, 0.07), lf)

# ---------------- the way in, at the corner of the Calle de Argentina and the square ----------------
func _entrance() -> void:
	var f := _face(Vector3(4.0, 0, -24.6), PI)         # the wall the doors are in: it looks north, from x 0 (by the pier) to 4.7
	var wide := 4.7
	_box(GLASS, Vector3(wide / 2.0, 1.5, 0.02), Vector3(wide - 0.3, 3.0, 0.08), f)
	for i in range(4):                                # three bays between white posts
		_box(WHITE, Vector3(0.15 + i * (wide - 0.3) / 3.0, 1.55, 0.09), Vector3(0.1, 3.1, 0.1), f)
	_box(WHITE, Vector3(wide / 2.0, 2.25, 0.09), Vector3(wide - 0.3, 0.08, 0.1), f)
	_box(WHITE, Vector3(wide / 2.0, 3.06, 0.09), Vector3(wide - 0.3, 0.1, 0.1), f)
	var x := 0.3
	while x < wide - 0.25:                            # the grilles: thin white bars, top to bottom
		_box(WHITE, Vector3(x, 1.5, 0.16), Vector3(0.025, 3.0, 0.025), f)
		x += 0.16
	for y in [0.35, 1.2]:
		_box(WHITE, Vector3(wide / 2.0, y, 0.16), Vector3(wide - 0.3, 0.03, 0.03), f)
	_box(_stone, Vector3(wide / 2.0, 3.72, 0.0), Vector3(wide, 1.2, 0.3), f)
	# the canopy: the roof carried on out to the corner, on a brick pier
	_vol(CONCRETE, -0.9, 4.2, -28.8, -24.6, 3.3, 3.55)
	_vol(CONCRETE, -0.9, 4.2, -28.8, -28.55, 3.55, H + COPING)
	_vol(CONCRETE, -0.9, -0.65, -28.8, -24.6, 3.55, H + COPING)
	_vol(_brick, -0.85, -0.35, -28.75, -28.25, 0.0, 3.3)
	_vol(0xb8ab94, -0.9, 4.0, -28.8, -24.6, 0.0, 0.06)            # its paving, a step above the square
	_vol(0xb8ab94, -3.4, -0.9, -28.8, -20.0, 0.0, 0.04)

# ---------------- what stands round it in the photos ----------------
## paint on the ground (x0..x1, z0..z1 in this frame), laid on whatever the ground does there
func _mark(hex: int, x0: float, x1: float, z0: float, z1: float) -> void:
	var y := MapData.height(spot((x0 + x1) / 2.0, (z0 + z1) / 2.0)) - position.y + 0.025
	_box(hex, Vector3((x0 + x1) / 2.0, y, (z0 + z1) / 2.0), Vector3(x1 - x0, 0.02, z1 - z0))

## a piece of street furniture for props.gd to stand there: `face` is the way it looks, in this frame
func _stand(kind: String, x: float, z: float, face: Vector2, variant := 0) -> void:
	var d := (spot(x + face.x, z + face.y) - spot(x, z)).normalized()
	W.extra_props.append([kind, spot(x, z), atan2(d.x, d.y), variant])
	furniture += 1

func _street() -> void:
	# the corner of the Calle de Argentina: the bin for everything, the sign, and no parking along the wall in winter
	_stand("container", -2.4, -27.4, Vector2(-1, 0), 0)
	_stand("sign", -1.4, -29.2, Vector2(-1, 0), 0)
	_stand("noparking", 6.3, -29.0, Vector2(-1, 0), 1)
	# on the square, by the way in: the bay for the disabled with its sign and its yellow posts, and the heart for bottle tops
	_stand("psign", -1.5, -20.6, Vector2(-1, 0), 1)
	_stand("heart", -1.7, -22.6, Vector2(-1, 0), 0)
	for i in range(4):
		_stand("bollard", -1.5, -19.6 + i * 1.1, Vector2(-1, 0), 0)
	_mark(0x2f63b5, -6.2, -1.9, -20.0, -16.6)
	_mark(0xf4f4f0, -4.5, -3.6, -18.9, -17.7)
	# the rest of that side: cars nose to the wall, a bay each
	for i in range(5):
		_mark(0xf1efe6, -6.2, -1.3, -16.5 + i * 2.5 - 0.06, -16.5 + i * 2.5 + 0.06)
	_mark(0xf1efe6, -6.26, -6.14, -16.5, -6.5)
	# the corner of the Callejón Pando: the yellow bins and the blue one, and the posts that keep cars off the pavement
	_stand("container", -2.0, -1.0, Vector2(-1, 0), 1)
	_stand("container", -2.0, -2.7, Vector2(-1, 0), 1)
	_stand("container", -2.0, -4.4, Vector2(-1, 0), 2)
	for i in range(3):
		_stand("bollard", -3.4 - i * 0.9, 0.2, Vector2(0, 1), 1)
	# the casualty wing: nobody parks across its porch
	_stand("noparking", 48.9, 0.35, Vector2(-1, 0), 0)
	_mark(0xe6b422, 35.8, 48.3, 1.0, 1.14)

# ---------------- the casualty wing, on the Callejón Pando ----------------
func _casualty() -> void:
	var x0 := 35.8
	var x1 := 48.3
	_vol(WHITE, x0, x1, -13.0, -PORCH, 0.0, 3.5)                  # the ground floor, behind the porch
	_vol(WHITE, x0, x1, -13.0, 0.0, 3.5, UH)                      # the floor above, out over it
	_vol(WHITE, x0 - 0.3, x1 + 0.3, -13.2, 0.35, UH, UH + 0.22)   # the roof slab
	_vol(WHITE, 48.3, 64.4, -13.0, -4.8, 0.0, 3.8)                # the low rooms behind the neighbour's house
	var f := _face(Vector3(x0, 0, 0.0), 0.0)
	var wide := x1 - x0
	# concrete, with the marks of its formwork: the beam over the porch, the fin at its left, the screen at its right
	_box(CONCRETE, Vector3(wide / 2.0, 3.5, 0.08), Vector3(wide + 0.1, 0.95, 0.3), f)
	_box(CONCRETE, Vector3(0.2, 1.52, -PORCH / 2.0 + 0.1), Vector3(0.4, 3.05, PORCH + 0.2), f)
	_box(CONCRETE, Vector3(wide - 2.0, 1.52, -PORCH + 1.0), Vector3(4.0, 3.05, 0.3), f)
	_box(CONCRETE, Vector3(wide - 0.15, 1.52, -PORCH / 2.0 + 0.1), Vector3(0.3, 3.05, PORCH + 0.2), f)
	for q in [Vector2(wide - 3.0, 1.0), Vector2(wide - 1.0, 1.0), Vector2(wide - 3.0, 2.2), Vector2(wide - 1.0, 2.2)]:
		_box(0x8f897c, Vector3(q.x, q.y, -PORCH + 1.16), Vector3(0.06, 0.06, 0.02), f)
	# under the porch: the glass door, a panel of boards beside it, a louvred door
	_box(GLASS, Vector3(1.3, 1.15, -PORCH + 0.04), Vector3(1.5, 2.3, 0.06), f)
	_box(0xdfe2e4, Vector3(1.3, 2.34, -PORCH + 0.06), Vector3(1.6, 0.08, 0.08), f)
	_box(0xdfe2e4, Vector3(1.3, 1.15, -PORCH + 0.08), Vector3(0.06, 2.3, 0.04), f)
	_box(0xb3946a, Vector3(3.0, 1.5, -PORCH + 0.05), Vector3(1.8, 3.0, 0.1), f)
	for i in range(1, 9):
		_box(0x8f7550, Vector3(3.0, i * 0.33, -PORCH + 0.105), Vector3(1.8, 0.02, 0.01), f)
	_box(0xd4d6d2, Vector3(6.6, 1.2, -PORCH + 0.05), Vector3(1.3, 2.4, 0.08), f)
	for i in range(1, 16):
		_box(0xaeb1ad, Vector3(6.6, i * 0.15, -PORCH + 0.095), Vector3(1.2, 0.03, 0.02), f)
	for i in range(4):                                # the strip lights of its ceiling
		_box(0xf2efe2, Vector3(1.6 + i * 2.6, 2.98, -PORCH / 2.0), Vector3(0.14, 0.08, 1.3), f)
	_box(0xb8ab94, Vector3(wide / 2.0, 0.03, -PORCH / 2.0 + 0.6), Vector3(wide, 0.06, PORCH + 1.2), f)
	# above: wooden louvres between white posts over most of the front, a panel of red stone at the right
	var lw := wide * 0.66
	_box(0x6b5a44, Vector3(0.3 + lw / 2.0, 5.55, 0.0), Vector3(lw, 3.1, 0.06), f)
	for i in range(15):
		var slat := _box(0xb99a6c, Vector3(0.3 + lw / 2.0, 4.12 + i * 0.205, 0.07), Vector3(lw, 0.035, 0.17), f)
		slat.rotation.x = 0.5
	for i in range(7):
		_box(WHITE, Vector3(0.3 + i * lw / 6.0, 5.55, 0.12), Vector3(0.07, 3.1, 0.12), f)
	_box(0xc56f5a, Vector3(0.3 + lw + (wide - lw - 0.5) / 2.0, 5.55, 0.02), Vector3(wide - lw - 0.5, 3.1, 0.06), f)
	for i in range(1, 4):
		_box(0xa85a48, Vector3(0.3 + lw + (wide - lw - 0.5) / 2.0, 4.0 + i * 0.78, 0.055), Vector3(wide - lw - 0.5, 0.015, 0.01), f)
	# its sign: a lit box on the beam
	_box(0x2a3f8f, Vector3(5.2, 4.05, 0.42), Vector3(2.5, 1.1, 0.5), f)
	_box(WHITE, Vector3(5.2, 4.2, 0.68), Vector3(2.3, 0.62, 0.02), f)
	_text(f, "URGENCIAS", Vector3(5.2, 4.2, 0.7), 74, 0x2a3f8f)
	_text(f, "La Mancha", Vector3(5.2, 3.72, 0.68), 34, 0xffffff)
