extends "res://scripts/obra.gd"
## The nursery school of the Calle del Palo, built by hand (the user, 15 November 2026: "El centro de educación infantil
## ... al que llamaremos José de Calasanz en nuestra versión, igual que se llamaba antiguamente. Da prioridad a las
## fotos de 2009. Ya que entonces era más colorido, con más juegos. Más infantil."; referencias/escuela_calasanz/,
## tools/calasanz/).
##
## As Street View has it in May 2009 (its yard) and March 2013 (its front, with the trees bare): a long house of two
## floors of 1975, white with its corners, its courses and the frames of its windows in brick, under a hipped roof of
## tiles; in the middle a brick arch into a porch painted from floor to ceiling, and over it the school's name in a
## black scroll; six windows each side of it on each floor, the lower ones behind red bars. The yard is a step above
## the street, held by a wall of rubble with railings on it painted by stretches in yellow, blue, red and green; a
## green gate between two pillars capped in brick; big trees along the railings. To the left of the house, towards
## the Arroyuelo, what the children play on: a wooden tower painted in every colour with its slide, tyres half sunk
## in the ground, a little house; to the right, a white cabin put there for one more classroom, and a landscape
## painted on the end wall.
##
## Frame: origin at the left end of the front seen from the street (its north-west corner), on the yard's floor;
## +x along the front, +z out of it towards the Calle del Palo.
## There is no going in: the gate is shut. No children are put in it (the user: no new characters for now).

const READY := true                             # (tools/bake_godot.py looks for this: with it, Catastro's block is not raised here)
const O := Vector2(-109.41, -217.17)
const U := Vector2(0.6862, 0.7273)              # along the front
const L := 23.36                                # the front
const D := 6.78                                 # how deep the house is
const EAVES := 7.3
const BAND := 3.42                              # the brick course between the two floors
const RAISE := 0.6                              # the yard over the street
const FENCE_Z := 4.3                            # the line of the railings on the Calle del Palo
const PLOT: Array = [Vector2(-8.5, 4.3), Vector2(38.3, 4.3), Vector2(28.8, -17.6), Vector2(-11.3, -8.4)]
const GATE := Vector2(9.6, 12.2)                # the gate, along the front
const COLS: Array = [3.25, 4.55, 5.85, 7.15, 8.45, 9.75]       # the windows: how far each side of the middle of the front
const PAINT: Array = [0xe8c020, 0x2a62c8, 0xc8323a, 0x2f9a4a]  # the railings: yellow, blue, red, green
const PLAY_SET := "res://assets/parque/juegos.glb"

var door: Vector2               # in front of its gate, on the map

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"brick":            # the smooth orange brick of a school of the seventies
			m = Tex.mat("brick_wall_003", Color(1.0, 0.96, 0.92))
		"white":            # its render: white in the shade of its trees too
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.985, 0.95)), 0.34)
		"rubble":
			m = Tex.mat("stone_wall")
		"hormigon":
			m = Tex.mat("granular_concrete", Color(0.86, 0.84, 0.8), false)
		"patio":            # the yard's floor
			m = Tex.mat("granular_concrete@1.6", Color(0.82, 0.79, 0.75), false)
		"leaf":
			m = W._tmat(0x5a9a48, "leaf", 1.3)
		"soil":
			m = W._tmat(0x6f5d4a, "earth", 1.6)
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	var data: Dictionary = MapData.calasanz
	var o := Vector2(data["o"][0], data["o"][1]) if data.has("o") else O
	var u := Vector2(data["u"][0], data["u"][1]) if data.has("u") else U
	level = MapData.height(o + u * (L / 2.0) + Vector2(-u.y, u.x) * 7.0) + RAISE        # (the street in front of it, and a step up)
	transform = Transform3D(Basis(Vector3(u.x, 0, u.y), Vector3.UP, Vector3(-u.y, 0, u.x)), Vector3(o.x, level, o.y))
	W.add_child(self)
	door = spot((GATE.x + GATE.y) / 2.0, FENCE_Z + 1.2)
	_yard()
	_house()
	_fences()
	_trees()
	_play()
	_cabin()
	home()
	_commit()
	_tell_map()

## What stands here, for whoever asks the map how much room there is and for the little map.
func _tell_map() -> void:
	var pts := PackedVector2Array()
	for q: Vector2 in PLOT:
		pts.append(spot(q.x, q.y))
	MapData.outlines.append(pts)
	if not MapData._wall_grid.is_empty():
		for i in range(pts.size()):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % pts.size()]
			MapData._grid_add(MapData._wall_grid, a.min(b), a.max(b), [a, b])

# ---------------- the yard ----------------
func _yard() -> void:
	var pts := PackedVector2Array()
	for q: Vector2 in PLOT:
		pts.append(q)
	flat(pts, 0.0, "patio")
	_prism([PLOT[0], PLOT[1], PLOT[2], PLOT[3]], -RAISE - 0.6, 0.0)
	# what the children have painted on its floor: a hopscotch by the cabin
	var at := Vector2(27.0, 2.3)
	var tints := [0xe8c020, 0x2a62c8, 0xc8323a, 0x2f9a4a, 0xe07a2a]
	var cells: Array = [Vector2(0, 0), Vector2(1, 0), Vector2(2, -0.5), Vector2(2, 0.5), Vector2(3, 0), Vector2(4, -0.5), Vector2(4, 0.5), Vector2(5, 0)]
	for k in range(cells.size()):
		var c: Vector2 = at + Vector2((cells[k] as Vector2).x * 0.62, (cells[k] as Vector2).y * 0.62)
		flat(PackedVector2Array([c + Vector2(-0.29, -0.29), c + Vector2(0.29, -0.29), c + Vector2(0.29, 0.29), c + Vector2(-0.29, 0.29)]), 0.006, tints[k % tints.size()])
		var n := Label3D.new()
		n.text = str(k + 1)
		n.font_size = 64
		n.pixel_size = 0.0045
		n.modulate = Color("fdfcf8")
		n.outline_size = 0
		n.position = Vector3(c.x, 0.012, c.y)
		n.rotation = Vector3(-PI / 2.0, PI / 2.0, 0.0)
		add_child(n)

# ---------------- the house ----------------
func _house() -> void:
	var mid: float = L / 2.0
	var win_g := Vector2(1.0, 2.6)              # the ground floor's windows: sill and head
	var win_u := Vector2(4.5, 6.2)              # the upper floor's
	# --- the front ---
	face(Vector2(0, 0), Vector2(L, 0))
	var holes: Array = []
	var brick: Array = [Rect2(0, 0, 0.45, EAVES), Rect2(L - 0.45, 0, 0.45, EAVES), Rect2(0, BAND, L, 0.16), Rect2(0, EAVES - 0.3, L, 0.3)]
	var first: float = mid - float(COLS[COLS.size() - 1]) - 0.45 - 0.22
	var last: float = mid - float(COLS[0]) + 0.45 + 0.22
	brick.append(Rect2(first, win_g.x - 0.1, last - first, win_g.y - win_g.x + 0.32))
	brick.append(Rect2(L - last, win_g.x - 0.1, last - first, win_g.y - win_g.x + 0.32))
	brick.append(Rect2(first, win_u.x - 0.1, L - 2.0 * first, win_u.y - win_u.x + 0.32))
	var wins: Array = []                        # [hole, upstairs?]
	for side in [-1.0, 1.0]:
		for c in COLS:
			var x: float = mid + side * float(c) - 0.45
			wins.append([Rect2(x, win_g.x, 0.9, win_g.y - win_g.x), false])
			wins.append([Rect2(x, win_u.x, 0.9, win_u.y - win_u.x), true])
	for x in [mid - 1.25, mid + 0.1]:           # the wide pair over the arch
		wins.append([Rect2(x, win_u.x, 1.15, win_u.y - win_u.x), true])
	for w in wins:
		holes.append(w[0])
	var spring := 1.55                          # the arch: where it begins, and its radius
	var r := 1.7
	holes.append(Rect2(mid - r, 0.0, 2.0 * r, spring + r))
	masonry(0.0, L, 0.0, EAVES, holes, brick, "white", "brick")
	for w in wins:
		_window(w[0], w[1])
	spandrels(mid, spring, r, 0.0, "white")
	ring(mid, spring, r, r + 0.34, 0.03, 0.34, "brick")
	for s in [-1.0, 1.0]:                       # the arch's jambs
		box(mid + s * r - (0.0 if s < 0.0 else 0.34), 0.0, 0.0, 0.34, spring, 0.03, "brick")
	cornice(0.0, L, EAVES + 0.42, true, "brick")
	_scroll(mid, 3.98)
	_porch(mid, r, spring)
	box(-0.03, 0.0, 0.0, L + 0.06, 0.12, 0.05, 0x9a958c)                        # a grey foot along the wall
	home()
	# --- its two ends ---
	for end in [0, 1]:
		if end == 0:
			face(Vector2(0, -D), Vector2(0, 0))
		else:
			face(Vector2(L, 0), Vector2(L, -D))
		var eh: Array = []
		var eb: Array = [Rect2(0, 0, 0.45, EAVES), Rect2(D - 0.45, 0, 0.45, EAVES), Rect2(0, BAND, D, 0.16), Rect2(0, EAVES - 0.3, D, 0.3)]
		var ew: Array = []
		for x in [D * 0.3 - 0.45, D * 0.7 - 0.45]:
			ew.append([Rect2(x, win_u.x, 0.9, win_u.y - win_u.x), true])
			if end == 0:
				ew.append([Rect2(x, win_g.x, 0.9, win_g.y - win_g.x), false])
		eb.append(Rect2(D * 0.3 - 0.67, win_u.x - 0.1, D * 0.4 + 1.34, win_u.y - win_u.x + 0.32))
		if end == 0:
			eb.append(Rect2(D * 0.3 - 0.67, win_g.x - 0.1, D * 0.4 + 1.34, win_g.y - win_g.x + 0.32))
		for w in ew:
			eh.append(w[0])
		masonry(0.0, D, 0.0, EAVES, eh, eb, "white", "brick")
		for w in ew:
			_window(w[0], w[1])
		cornice(0.0, D, EAVES + 0.42, true, "brick")
		if end == 1:
			_landscape(0.5, D - 0.5, 0.25, 3.3)
		home()
	# --- its back, and the wing behind it ---
	_plain(Vector2(L, -D), Vector2(0, -D), 0.0, EAVES, "white")
	box(9.68, 0.0, -12.73, 4.37, EAVES - 0.5, 5.95, "white")
	_hip(9.68, 14.05, -12.73, -D, EAVES - 0.5, 1.0, 0.35)
	solid(Vector3(L / 2.0, EAVES / 2.0, -D / 2.0), Vector3(L, EAVES, D))
	solid(Vector3(11.86, EAVES / 2.0, -9.75), Vector3(4.37, EAVES, 5.95))
	# --- its roof: four slopes of tiles, the ridge along the front ---
	var out := 0.6
	var y: float = EAVES + 0.42
	var rise := 1.75
	var a := Vector3(-out, y, out)
	var b := Vector3(L + out, y, out)
	var c := Vector3(L + out, y, -D - out)
	var d := Vector3(-out, y, -D - out)
	var r0 := Vector3(D / 2.0, y + rise, -D / 2.0)
	var r1 := Vector3(L - D / 2.0, y + rise, -D / 2.0)
	roof([a, b, r1, r0])
	roof([c, d, r0, r1])
	roof([d, a, r0])
	roof([b, c, r1])
	for q in [[a, r0], [d, r0], [b, r1], [c, r1], [r0, r1]]:
		ridge(q[0], q[1])
	for q in [Vector2(0, 0), Vector2(L, 0), Vector2(L, -D), Vector2(0, -D)]:
		yard.append(spot(q.x, q.y))

## A window in its hole: white frames, the glass, a white blind part of the way down; downstairs, red bars over it.
func _window(r: Rect2, upstairs: bool) -> void:
	window(r, 0xf1f0ea, 0x39566a, 1)
	var blind: float = r.size.y * (0.38 if upstairs else 0.22)
	box(r.position.x + 0.03, r.end.y - blind, -DEEP + 0.1, r.size.x - 0.06, blind, 0.04, 0xf4f2ec)
	box(r.position.x - 0.08, r.position.y - 0.07, 0.0, r.size.x + 0.16, 0.07, 0.06, "hormigon")      # its sill
	if not upstairs:
		grille(r, 0.1, 0xb23a34)

## The school's name in its scroll, painted over the arch (the real one's old name, as its wall still has it).
func _scroll(cx: float, cy: float) -> void:
	var w := 3.5
	var h := 0.54
	var pts := PackedVector2Array([Vector2(cx - w / 2.0, cy), Vector2(cx - w / 2.0 + 0.2, cy - h / 2.0), Vector2(cx + w / 2.0 - 0.2, cy - h / 2.0),
		Vector2(cx + w / 2.0, cy), Vector2(cx + w / 2.0 - 0.2, cy + h / 2.0), Vector2(cx - w / 2.0 + 0.2, cy + h / 2.0)])
	slab(pts, 0.012, 0.0, 0x1c1c1e)
	var inner := PackedVector2Array()
	for q in pts:
		inner.append(Vector2(cx + (q.x - cx) * 0.965, cy + (q.y - cy) * 0.8))
	slab(inner, 0.02, 0.0, 0xf4f2ec)
	_text("S. JOSE DE CALASANZ", Vector3(cx, cy, 0.03), 64, 0x1c1c1e, 0.0041)

## The porch behind the arch: painted from the floor up -- big flowers and flames of red and orange on blue --, the
## school's door at the back.
func _porch(cx: float, r: float, spring: float) -> void:
	var deep := 2.2
	var top: float = spring + r
	box(cx - r, top, -deep, 2.0 * r, 0.06, deep, 0xf1eee6)                      # its ceiling
	quad(Vector3(cx - r, 0, -deep), Vector3(cx + r, 0, -deep), Vector3(cx + r, top, -deep), Vector3(cx - r, top, -deep), 0x2a4f9a, Vector3(0, 0, 1))
	quad(Vector3(cx - r, 0, -deep), Vector3(cx - r, 0, 0), Vector3(cx - r, top, 0), Vector3(cx - r, top, -deep), 0x2a4f9a, Vector3(1, 0, 0))
	quad(Vector3(cx + r, 0, -deep), Vector3(cx + r, 0, 0), Vector3(cx + r, top, 0), Vector3(cx + r, top, -deep), 0x2a4f9a, Vector3(-1, 0, 0))
	# on the back wall: the door, and round it what was painted
	var z := -deep + 0.012
	var warm := [0xd8382c, 0xf07a22, 0xf2c230, 0xe85a8a]
	var k := 0
	for q in [[-1.15, 2.55, 0.62, 0.34], [-0.35, 2.85, 0.7, 0.3], [0.55, 2.7, 0.66, 0.36], [1.2, 2.3, 0.4, 0.5], [-1.3, 1.5, 0.3, 0.52], [1.32, 1.2, 0.26, 0.5], [-1.25, 0.55, 0.34, 0.34], [1.25, 0.5, 0.3, 0.3]]:
		slab(oval(cx + q[0], q[1], q[2], q[3], 14), z + 0.004 * (k % 3), 0.0, warm[k % warm.size()])
		k += 1
	for q in [[-1.25, 0.55], [1.25, 0.5], [-0.35, 2.85]]:
		slab(oval(cx + q[0], q[1], 0.12, 0.12, 10), z + 0.016, 0.0, 0xfdf6d8)
	for q in [[-1.0, 1.0, 0.2, 0.36], [0.95, 1.75, 0.2, 0.34], [-0.75, 2.2, 0.26, 0.16]]:
		slab(oval(cx + q[0], q[1], q[2], q[3], 10), z + 0.01, 0.0, 0x3f9a4a)
	box(cx - 0.85, 0.0, -deep, 1.7, 2.25, 0.05, 0x2d5fa8)                       # the door: two blue leaves, glass above, bars
	box(cx - 0.02, 0.0, -deep + 0.05, 0.04, 2.25, 0.012, 0x1f447c)
	for s in [-1.0, 1.0]:
		box(cx + s * 0.43 - 0.3, 1.2, -deep + 0.05, 0.6, 0.8, 0.012, 0x39566a)
		for i in range(4):
			box(cx + s * 0.43 - 0.3 + 0.15 * i + 0.07, 1.2, -deep + 0.062, 0.02, 0.8, 0.012, 0xf1f0ea)
	# on the side walls: a flame of colour up each
	for s in [-1.0, 1.0]:
		var keep := _xf
		_xf = _xf * Transform3D(Basis(Vector3(0, 0, -s), Vector3.UP, Vector3(s, 0, 0)), Vector3(cx - s * (r - 0.012), 0, 0.0 if s > 0.0 else -deep))      # (the wall seen from inside the porch: its own x runs along it)
		var j := 0
		for q in [[0.5, 0.7, 0.34, 0.55], [1.1, 1.5, 0.4, 0.6], [1.6, 0.8, 0.3, 0.5], [0.8, 2.4, 0.5, 0.36], [1.7, 2.3, 0.3, 0.44]]:
			slab(oval(q[0], q[1], q[2], q[3], 12), 0.004 * (j % 3), 0.0, warm[(j + 1) % warm.size()])
			j += 1
		for q in [[1.3, 2.75, 0.3, 0.14], [0.45, 1.6, 0.16, 0.3]]:
			slab(oval(q[0], q[1], q[2], q[3], 10), 0.012, 0.0, 0x3f9a4a)
		_xf = keep

## A landscape painted on the wall being built, from x0 to x1 and y0 to y1: sky, hills, a sun, a rainbow, flowers.
func _landscape(x0: float, x1: float, y0: float, y1: float) -> void:
	var w: float = x1 - x0
	var h: float = y1 - y0
	box(x0, y0, 0.0, w, h, 0.012, 0x7fc0ee)
	slab(oval(x0 + w * 0.82, y1 - h * 0.2, h * 0.14, h * 0.14, 14), 0.016, 0.0, 0xf2c230)
	var bow := [0xd8382c, 0xf07a22, 0xf2c230, 0x3f9a4a, 0x2a62c8]
	for i in range(bow.size()):
		ring(x0 + w * 0.36, y0 + h * 0.3, h * (0.42 - i * 0.045), h * (0.465 - i * 0.045), 0.018, 0.0, bow[i], 14)
	for q in [[0.24, 0.24, 0.26, 0x4faa4a], [0.62, 0.3, 0.2, 0x3f8f3a], [0.84, 0.16, 0.24, 0x58b452]]:
		var hill := PackedVector2Array()
		for i in range(13):
			var a: float = PI * i / 12.0
			hill.append(Vector2(x0 + w * (q[0] + q[1] * cos(a)), y0 + h * q[2] * sin(a) * 1.4))
		slab(hill, 0.024, 0.0, q[3])
	for i in range(6):
		var fx: float = x0 + w * (0.08 + i * 0.165)
		var fy: float = y0 + h * (0.2 + 0.07 * (i % 2))
		box(fx - 0.02, y0, 0.026, 0.04, fy - y0, 0.004, 0x2f7a3a)
		slab(oval(fx, fy, 0.16, 0.16, 8), 0.032, 0.0, [0xd8382c, 0xfdfcf8, 0xe85a8a][i % 3])
		slab(oval(fx, fy, 0.06, 0.06, 8), 0.036, 0.0, 0xf2c230)

# ---------------- walls and railings ----------------
func _fences() -> void:
	# along the Calle del Palo, with the gate; round the corner on each side; and a plain wall at the back
	var runs: Array = [[PLOT[0], PLOT[1], GATE - Vector2(PLOT[0].x, PLOT[0].x)], [PLOT[1], PLOT[2], Vector2.ZERO], [PLOT[3], PLOT[0], Vector2.ZERO]]
	var tint := 0
	for run in runs:
		var a: Vector2 = run[0]
		var b: Vector2 = run[1]
		var gap: Vector2 = run[2]                # where the gate is, along this run (nothing: no gate)
		var ln: float = face(a, b)
		var spans: Array = [Vector2(0.0, ln)] if gap == Vector2.ZERO else [Vector2(0.0, gap.x - 0.55), Vector2(gap.y + 0.55, ln)]
		for sp: Vector2 in spans:
			box(sp.x, -RAISE - 0.5, -0.42, sp.y - sp.x, RAISE + 0.62, 0.42, "rubble")
			box(sp.x - 0.02, 0.12, -0.46, sp.y - sp.x + 0.04, 0.07, 0.5, "hormigon")
			var count: int = maxi(1, int(round((sp.y - sp.x) / 3.3)))
			var each: float = (sp.y - sp.x) / count
			for k in range(count):
				_railing(sp.x + k * each, each, PAINT[tint % PAINT.size()])
				tint += 1
		if gap != Vector2.ZERO:
			_gate(gap)
		home()
		var d: Vector2 = (b - a).normalized()
		var outv := Vector2(-d.y, d.x)
		var mid: Vector2 = (a + b) / 2.0 - outv * 0.21
		solid(Vector3(mid.x, 0.45, mid.y), Vector3(ln, 2.6, 0.42), atan2(-d.y, d.x))
		for q in [a, b, (a + b) / 2.0]:
			yard.append(spot(q.x, q.y))
	var back_a: Vector2 = (PLOT[2] as Vector2) + Vector2(0.11, 0.49)      # (half a metre this side of the neighbours' wall, which stands on the line)
	var back_b: Vector2 = (PLOT[3] as Vector2) + Vector2(0.11, 0.49)
	var bl: float = face(back_b, back_a)         # (seen from the yard: its near face)
	box(0.0, -RAISE - 0.5, -0.2, bl, RAISE + 3.1, 0.2, "white")
	box(-0.02, 2.6, -0.24, bl + 0.04, 0.07, 0.28, "hormigon")
	_landscape(1.0, 10.4, 0.2, 2.4)              # behind the play things: another painted wall
	home()

## a stretch of railing on the wall being built, from x on, `w` long, all of one colour
func _railing(x: float, w: float, hex: int) -> void:
	var y0 := 0.19
	var y1 := 1.42
	for q in [x + 0.03, x + w - 0.03]:
		box(q - 0.03, y0, -0.24, 0.06, y1 - y0 + 0.06, 0.06, hex)
	box(x, y0 + 0.08, -0.225, w, 0.035, 0.035, hex)
	box(x, y1 - 0.1, -0.225, w, 0.035, 0.035, hex)
	var n: int = maxi(2, int(round(w / 0.13)))
	for i in range(1, n):
		box(x + w * i / n - 0.012, y0, -0.222, 0.024, y1 - y0, 0.024, hex)

## The gate, on the wall being built, between `gap.x` and `gap.y`: two pillars of concrete capped in brick with a
## stone on top, two green leaves -- sheet below, bars above --, the noticeboard beside it.
func _gate(gap: Vector2) -> void:
	var low: float = -RAISE
	for q in [gap.x - 0.5, gap.y]:
		box(q, low - 0.4, -0.46, 0.5, 2.5 + RAISE, 0.5, "hormigon")
		for k in range(3):
			box(q - 0.03 * (3 - k), 2.1 + k * 0.07, -0.46 - 0.03 * (3 - k), 0.5 + 0.06 * (3 - k), 0.07, 0.5 + 0.06 * (3 - k), "brick")
		var keep := _xf
		_xf = _xf * Transform3D(Basis(), Vector3(q + 0.25, 2.31, -0.21))
		drum(Vector3.ZERO, 0.2, 0.03, 0.26, 0x9a958c, 4)
		_xf = keep
	var w: float = gap.y - gap.x
	var green := 0x2f8f42
	for s in [0, 1]:
		var x: float = gap.x + s * w / 2.0
		box(x + 0.02, low + 0.04, -0.26, w / 2.0 - 0.04, 1.05, 0.04, green)
		for q in [x + 0.02, x + w / 2.0 - 0.07]:
			box(q, low + 0.04, -0.27, 0.05, 2.0, 0.06, green)
		box(x + 0.02, low + 1.99, -0.27, w / 2.0 - 0.04, 0.05, 0.06, green)
		for i in range(1, 9):
			box(x + (w / 2.0) * i / 9.0 - 0.012, low + 1.09, -0.25, 0.024, 0.9, 0.024, green)
	box(gap.y + 0.52, 0.3, 0.0, 1.0, 0.9, 0.05, 0xf4f1e8)                       # the noticeboard: the children's drawings pinned on it
	box(gap.y + 0.5, 0.28, 0.0, 1.04, 0.94, 0.03, 0x8a8f96)
	var sheets := [0xe85a3a, 0xf2c230, 0x4f9ad8, 0x58b452, 0xfdfcf8, 0xe85a8a]
	for i in range(6):
		box(gap.y + 0.58 + (i % 3) * 0.31, 0.36 + (i / 3) * 0.42, 0.05, 0.26, 0.36, 0.006, sheets[i])
	# the little barrier inside, half yellow and half blue, that keeps the smallest from the gate
	for s in [0, 1]:
		var x: float = gap.x + s * w / 2.0
		var hex: int = PAINT[s]
		box(x + 0.03, 0.75, -1.9, w / 2.0 - 0.06, 0.04, 0.04, hex)
		box(x + 0.03, 0.12, -1.9, w / 2.0 - 0.06, 0.04, 0.04, hex)
		for i in range(8):
			box(x + 0.05 + (w / 2.0 - 0.1) * i / 7.0 - 0.012, 0.0, -1.895, 0.024, 0.78, 0.024, hex)
	yard.append(spot(gap.x, 0.0))

# ---------------- trees ----------------
func _trees() -> void:
	for q in [[-5.4, 1.6, 7.6, 2.2], [0.6, 2.9, 8.6, 2.2], [6.4, 3.0, 8.2, 2.0], [14.6, 3.0, 8.8, 2.2], [20.2, 3.0, 8.4, 2.1], [30.4, -9.2, 8.0, 2.8], [34.2, -1.2, 7.4, 2.3]]:      # (thinner than those of May 2009, which hid the house)
		var at := Vector2(q[0], q[1])
		var tall: float = q[2]
		var crown: float = q[3]
		flat(PackedVector2Array([at + Vector2(-0.6, -0.6), at + Vector2(0.6, -0.6), at + Vector2(0.6, 0.6), at + Vector2(-0.6, 0.6)]), 0.008, "soil")
		drum(Vector3(at.x, 0, at.y), 0.2, 0.13, tall - crown * 0.9, 0x6b5a45, 8)
		ball(Vector3(at.x, tall - crown * 0.25, at.y), crown, "leaf", 0.82, 10, 6)
		ball(Vector3(at.x + crown * 0.55, tall - crown * 0.6, at.y - crown * 0.3), crown * 0.72, "leaf", 0.85, 9, 5)
		ball(Vector3(at.x - crown * 0.5, tall - crown * 0.55, at.y + crown * 0.25), crown * 0.68, "leaf", 0.85, 9, 5)

# ---------------- what is played on ----------------
## To the left of the house (as Street View had it in May 2009): the wooden tower painted in every colour with its
## slide and its ladder, tyres half sunk in the ground round it, a little house, a yellow table; and from the set of
## the square's playground, two little horses on springs and a seesaw.
func _play() -> void:
	flat(PackedVector2Array([Vector2(-8.0, -7.6), Vector2(-0.6, -7.6), Vector2(-0.6, 0.4), Vector2(-7.4, 0.4)]), 0.004, 0xb5553f)      # (its floor, painted red)
	_tower(Vector2(-4.7, -4.2))
	for k in range(6):                            # a row of tyres along the front of the play floor, and a few more
		_tyre(Vector2(-7.0 + k * 0.72, 0.1), 0.0, 0x1c1c1e if k % 2 == 0 else PAINT[(k / 2) % 4])
	for k in range(4):
		_tyre(Vector2(-1.0, -6.6 + k * 0.72), PI / 2.0, 0x1c1c1e)
	_little_house(Vector2(-2.3, -1.6))
	# a yellow table with its two benches
	var t := Vector2(-6.6, -1.4)
	box(t.x - 0.6, 0.5, t.y - 0.3, 1.2, 0.05, 0.6, 0xe8c020)
	for s in [-1.0, 1.0]:
		box(t.x - 0.6, 0.28, t.y + s * 0.62 - 0.12, 1.2, 0.04, 0.24, 0xe8c020)
		box(t.x + s * 0.5 - 0.03, 0.0, t.y - 0.72, 0.06, 0.5, 1.44, 0xc8323a)
	var kit: Node = (load(PLAY_SET) as PackedScene).instantiate() if ResourceLoader.exists(PLAY_SET) else null
	_toy(kit, "muelle_a", Vector2(-6.5, -6.3), Vector2(0.4, 0.9))
	_toy(kit, "muelle_b", Vector2(-2.6, -6.4), Vector2(-0.5, 0.86))
	_toy(kit, "balancin", Vector2(-2.3, 2.5), Vector2(1.0, 0.0))
	if kit != null:
		kit.free()

func _toy(kit: Node, piece: String, at: Vector2, front: Vector2) -> void:
	var src: Node3D = kit.get_node_or_null(piece) if kit != null else null
	if src == null:
		return
	var n: Node3D = src.duplicate()
	n.transform = Transform3D(Basis(Vector3.UP, atan2(front.x, front.y)), Vector3(at.x, 0.01, at.y))
	add_child(n)
	pieces += 1

## the wooden tower: four red posts, a floor half-way up, slats of blue and green round it, yellow beams on top, a
## ladder at the back and a red slide to the front
func _tower(at: Vector2) -> void:
	var s := 0.8
	var floor_y := 1.25
	for q in [Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s)]:
		cbox(Vector3(at.x + q.x, 1.4, at.y + q.y), Vector3(0.11, 2.8, 0.11), 0xc8323a)
	cbox(Vector3(at.x, floor_y, at.y), Vector3(2.0 * s + 0.1, 0.08, 2.0 * s + 0.1), 0xb98a5a)
	for q in [[Vector2(-s, -s), Vector2(s, -s)], [Vector2(-s, s), Vector2(s, s)]]:
		bar(Vector3(at.x + (q[0] as Vector2).x, 2.74, at.y + (q[0] as Vector2).y), Vector3(at.x + (q[1] as Vector2).x, 2.74, at.y + (q[1] as Vector2).y), 0.1, 0.1, 0xe8c020)
	for side in [[Vector2(-s, -s), Vector2(-s, s)], [Vector2(s, -s), Vector2(s, s)], [Vector2(-s, -s), Vector2(s, -s)]]:      # slats on three sides (the fourth is where the slide leaves)
		var a: Vector2 = side[0]
		var b: Vector2 = side[1]
		bar(Vector3(at.x + a.x, floor_y + 0.86, at.y + a.y), Vector3(at.x + b.x, floor_y + 0.86, at.y + b.y), 0.06, 0.06, 0xe8c020)
		for i in range(1, 10):
			var q: Vector2 = a.lerp(b, i / 10.0)
			if side == [Vector2(-s, -s), Vector2(s, -s)] and i > 3 and i < 7:
				continue                          # (the way in from the ladder)
			cbox(Vector3(at.x + q.x, floor_y + 0.45, at.y + q.y), Vector3(0.09, 0.82, 0.03) if a.y == b.y else Vector3(0.03, 0.82, 0.09), 0x2a62c8 if i % 2 == 0 else 0x2f9a4a)
	for sx in [-0.26, 0.26]:                      # the ladder
		bar(Vector3(at.x + sx, 0.0, at.y - s - 0.75), Vector3(at.x + sx, floor_y, at.y - s), 0.05, 0.07, 0x9a8f80)
	for i in range(1, 5):
		var f: float = i / 5.0
		cbox(Vector3(at.x, floor_y * f, at.y - s - 0.75 * (1.0 - f)), Vector3(0.5, 0.04, 0.07), 0x9a8f80)
	bar(Vector3(at.x, floor_y, at.y + s), Vector3(at.x, 0.12, at.y + s + 2.3), 0.56, 0.05, 0xd8382c)                # the slide
	for sx in [-0.3, 0.3]:
		bar(Vector3(at.x + sx, floor_y + 0.1, at.y + s), Vector3(at.x + sx, 0.22, at.y + s + 2.3), 0.05, 0.16, 0xc8323a)

## a tyre half sunk in the ground, standing
func _tyre(at: Vector2, turn: float, hex: int) -> void:
	var r := 0.3
	var along := Vector3(cos(turn), 0, -sin(turn))
	for i in range(6):
		var a0: float = PI * i / 6.0
		var a1: float = PI * (i + 1) / 6.0
		bar(Vector3(at.x, 0, at.y) + along * r * cos(a0) + Vector3(0, r * sin(a0), 0), Vector3(at.x, 0, at.y) + along * r * cos(a1) + Vector3(0, r * sin(a1), 0), 0.2, 0.13, hex)

## a little house to play in: blue, under a green roof, its door and its window open
func _little_house(at: Vector2) -> void:
	var w := 1.5
	var d := 1.3
	var h := 1.1
	box(at.x - w / 2.0, 0.0, at.y - d / 2.0, w, h, d, 0x3a7fd0)
	box(at.x - 0.28, 0.0, at.y + d / 2.0, 0.56, 0.85, 0.012, 0x1f2a33)
	box(at.x + 0.38, 0.5, at.y + d / 2.0, 0.28, 0.3, 0.012, 0xf2c230)
	box(at.x + 0.42, 0.54, at.y + d / 2.0 + 0.004, 0.2, 0.22, 0.012, 0x1f2a33)
	var e := 0.14
	var top := Vector3(at.x, h + 0.62, at.y)
	for s in [-1.0, 1.0]:
		quad(Vector3(at.x - w / 2.0 - e, h, at.y + s * (d / 2.0 + e)), Vector3(at.x + w / 2.0 + e, h, at.y + s * (d / 2.0 + e)), Vector3(at.x + w / 2.0 + e, top.y, at.y), Vector3(at.x - w / 2.0 - e, top.y, at.y), 0x3f9a4a, Vector3(0, 0.7, s * 0.7))
	for sx in [-1.0, 1.0]:
		tri(Vector3(at.x + sx * w / 2.0, h, at.y - d / 2.0), Vector3(at.x + sx * w / 2.0, h, at.y + d / 2.0), Vector3(at.x + sx * w / 2.0, top.y, at.y), 0x3a7fd0, Vector3(sx, 0, 0))

# ---------------- the cabin ----------------
## The white cabin to the right of the house, put in the yard for one more classroom.
func _cabin() -> void:
	var x0 := 25.4
	var z0 := -1.7
	var w := 6.0
	var d := 2.5
	var h := 2.6
	box(x0, 0.12, z0, w, h, d, 0xdcdedb)
	box(x0 - 0.04, h + 0.12, z0 - 0.04, w + 0.08, 0.1, d + 0.08, 0xb9bcba)
	for i in range(1, 6):
		box(x0 + w * i / 6.0 - 0.015, 0.12, z0 + d, 0.03, h, 0.012, 0xc6c8c5)
	box(x0 + w - 1.25, 0.12, z0 + d, 0.9, 2.05, 0.02, 0xc2c4c1)                  # its door, a little window in it
	box(x0 + w - 1.05, 1.5, z0 + d + 0.01, 0.5, 0.36, 0.014, 0x39566a)
	box(x0 + 0.5, 1.5, z0 + d, 1.1, 0.7, 0.02, 0x39566a)
	for q in [x0 + 0.2, x0 + w - 0.5]:
		box(q, 0.0, z0 + 0.2, 0.3, 0.12, d - 0.4, 0x8f8a80)
