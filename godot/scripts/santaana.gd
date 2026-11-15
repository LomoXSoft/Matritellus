extends "res://scripts/obra.gd"
## The convent of Santa Ana, the Poor Clares', built by hand (the user, 15 November 2026: "Pasemos al convento de santa
## Ana. La calle está empedrada pero no es peatonal"; referencias/convento_santa_ana/, tools/santaana/).
##
## On the corner of the Calle de las Monjas and the Calle de Santiago Apóstol, as Street View has it in November 2024.
## Along the Calle de las Monjas, from south to north: the convent's front -- two tall floors of pale brick with boxes
## of rubble between courses ("aparejo toledano"), every window behind a grey wrought-iron grille with its crest, a
## little door, a great arched one of brick under its own cornice, a carved stone, iron lanterns, a brick cornice under
## the tiles --; behind it a square brick tower with arched openings; then the front steps back round a little paved
## court with two cypresses, where the church's doorway is: a round arch of golden stone between pilasters, and over
## it a niche between two shields under a cross; then the church's tall end, brick and rubble with stone at its
## corner. On the Calle de Santiago Apóstol, the church's brick end and a long cream wall with high barred windows.
##
## Frame: origin at the south end of the convent's front; +x along the front (north), +z out into the Calle de las
## Monjas (east); y = 0 the convent's floor, the street at its great door.
## The game's Calle de Santiago Apóstol runs some three metres south of the real one, through where the church's north
## end really stands: the church and the north range are cut back to the game's street (`CHURCH`, `RANGE`).
## Nobody goes in: it is an enclosed convent. On the pedestal in the court stands the friar, as the user asked for him
## (15 November 2026: "Pon una figura de un fraile, que tenga el estilo de nuestros NPCs pero completamente en
## bronce"): one of the game's own figures (chara.gd) in a habit, cast whole in bronze, his arms open.

const READY := true                             # (tools/bake_godot.py looks for this: with it, Catastro's block is not raised here)
const O := Vector2(-501.6, -33.6)
const U := Vector2(0.2425, -0.9701)
const LF := 28.48                               # the convent's front
const EAVES := 8.0
const BAND := 4.45                              # the course between its two floors
const CH := 10.6                                # the church's walls, over its floor
const BAYS: Array = [1.2, 5.9, 9.2, 11.7, 15.75, 18.2, 21.0, 23.6]      # the bays of the front: their middles
const SMALL_DOOR := 2                           # the bay of the little door...
const GREAT_DOOR := 4                           # ...and of the great arched one
const WING: Array = [Vector2(0, 0), Vector2(28.48, 0), Vector2(28.48, -9.0), Vector2(0, -9.0)]
const BACK: Array = [Vector2(7.4, -9.0), Vector2(24.5, -9.0), Vector2(24.9, -24.8), Vector2(7.4, -25.6)]
const CHURCH: Array = [Vector2(28.5, -3.0), Vector2(36.44, -4.23), Vector2(36.92, -1.15), Vector2(45.59, -2.5), Vector2(43.38, -13.0), Vector2(28.5, -12.5)]
const RANGE: Array = [Vector2(24.7, -12.5), Vector2(43.38, -13.0), Vector2(38.65, -40.1), Vector2(24.7, -37.8)]
const LOW: Array = [Vector2(3.4, -18.9), Vector2(7.4, -18.9), Vector2(7.5, -36.9), Vector2(4.1, -36.7)]
const GARDEN: Array = [Vector2(38.65, -40.1), Vector2(37.25, -49.5), Vector2(9.0, -49.5), Vector2(7.5, -36.9)]
const TOWER := Rect2(5.3, -6.7, 6.4, 6.0)       # x, z, how long, how deep
const TOWER_TOP := 15.0
const GREY := 0xa9afb6                          # its grilles, painted grey
const PAVERS := "res://assets/empedrado/ladrillo.png"
const Chara = preload("res://scripts/chara.gd")

var door: Vector2               # in front of its great door, on the map
var yc := 0.0                   # the church's floor, over the convent's
var friar: Node3D               # the bronze friar on his pedestal

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"ladrillo":         # the pale pinkish brick of Toledo
			m = Tex.mat("brick_wall_003", Color(1.21, 1.32, 1.5))
		"rubble":
			m = Tex.mat("stone_wall", Color(1.5, 1.42, 1.34))
		"piedra":           # the golden stone of the doorway and the corner
			m = _glow(Tex.mat("granular_concrete", Color(1.3, 1.08, 0.74), false), 0.24)
		"crema":
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.97, 0.9, 0.76)), 0.38)
		"solado":           # the little court's floor: the street's own brick pavers
			var sm := StandardMaterial3D.new()
			sm.albedo_texture = load(PAVERS) if ResourceLoader.exists(PAVERS) else null
			sm.albedo_color = Color.WHITE if sm.albedo_texture != null else Color(0.66, 0.42, 0.34)
			sm.uv1_triplanar = true
			sm.uv1_world_triplanar = true
			sm.uv1_scale = Vector3.ONE / 2.0
			m = sm
		"cipres":
			m = W._tmat(0x2f5a36, "leaf", 1.0)
		"leaf":
			m = W._tmat(0x5a9a48, "leaf", 1.3)
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	var data: Dictionary = MapData.santaana
	var o := Vector2(data["o"][0], data["o"][1]) if data.has("o") else O
	var u := Vector2(data["u"][0], data["u"][1]) if data.has("u") else U
	var out := Vector2(-u.y, u.x)
	level = MapData.height(o + u * float(BAYS[GREAT_DOOR]) + out * 0.6)
	transform = Transform3D(Basis(Vector3(u.x, 0, u.y), Vector3.UP, Vector3(out.x, 0, out.y)), Vector3(o.x, level, o.y))
	W.add_child(self)
	door = spot(float(BAYS[GREAT_DOOR]), 1.2)
	yc = ground(31.4, -1.5)
	_front()
	_wing()
	_tower()
	_church()
	_court()
	_north()
	_garden()
	home()
	_commit()
	_tell_map()

## What stands here, for whoever asks the map how much room there is and for the little map.
func _tell_map() -> void:
	for ring in [WING, BACK, CHURCH, RANGE, LOW]:
		var pts := PackedVector2Array()
		for q: Vector2 in ring:
			pts.append(spot(q.x, q.y))
			yard.append(spot(q.x, q.y))
		MapData.outlines.append(pts)
		if not MapData._wall_grid.is_empty():
			for i in range(pts.size()):
				var a: Vector2 = pts[i]
				var b: Vector2 = pts[(i + 1) % pts.size()]
				MapData._grid_add(MapData._wall_grid, a.min(b), a.max(b), [a, b])

# ---------------- helpers ----------------
## the boxes of rubble of a stretch of wall: rows of them from y0 to y1, a course of brick between one and the next
func _boxes(x0: float, x1: float, y0: float, y1: float, tall := 0.72, course := 0.13) -> Array:
	var rows: Array = []
	var y := y0
	while y + 0.32 < y1:
		var h: float = minf(tall, y1 - y)
		rows.append(Rect2(x0, y, x1 - x0, h))
		y += h + course
	return rows

## a wrought-iron grille standing out before a window, painted grey, with the scrolls and the finial of its crest
func _reja(r: Rect2, out: float, hex := GREY) -> void:
	grille(r, out, hex)
	var cx: float = r.position.x + r.size.x / 2.0
	var y: float = r.end.y + 0.05
	for s in [-1.0, 1.0]:
		bar(Vector3(cx + s * r.size.x * 0.5, y, out), Vector3(cx + s * 0.1, y + 0.3, out), 0.025, 0.025, hex)
		bar(Vector3(cx + s * r.size.x * 0.27, y, out), Vector3(cx + s * 0.08, y + 0.17, out), 0.02, 0.02, hex)
	cbox(Vector3(cx, y + 0.32, out), Vector3(0.15, 0.2, 0.03), hex)
	cbox(Vector3(cx, y + 0.5, out), Vector3(0.03, 0.18, 0.03), hex)

## an iron lantern on its scrolled bracket, on the wall being built
func _farol(x: float, y: float) -> void:
	box(x - 0.02, y + 0.42, 0.0, 0.04, 0.04, 0.5, IRON)
	bar(Vector3(x, y, 0.02), Vector3(x, y + 0.42, 0.42), 0.03, 0.03, IRON)
	box(x - 0.13, y - 0.02, 0.36, 0.26, 0.4, 0.26, 0xf2e6b8)
	box(x - 0.16, y + 0.38, 0.33, 0.32, 0.06, 0.32, IRON)
	box(x - 0.1, y - 0.07, 0.39, 0.2, 0.05, 0.2, IRON)
	box(x - 0.03, y + 0.44, 0.46, 0.06, 0.1, 0.06, IRON)

## a cypress
func _cipres(at: Vector2, tall: float) -> void:
	var g: float = ground(at.x, at.y)
	drum(Vector3(at.x, g, at.y), 0.14, 0.1, 1.0, 0x5a4636, 7)
	drum(Vector3(at.x, g + 0.7, at.y), 0.8, 0.65, tall * 0.45, "cipres", 9)
	drum(Vector3(at.x, g + 0.7 + tall * 0.45, at.y), 0.65, 0.06, tall * 0.55 - 0.7, "cipres", 9)
	solid(Vector3(at.x, g + 1.2, at.y), Vector3(0.5, 2.6, 0.5))
	yard.append(spot(at.x, at.y))

## A roof of tiles over any outline: every eave runs up to the nearer end of the ridge (r0 -- r1).
func _tent(ring: Array, r0: Vector2, r1: Vector2, ye: float, yr: float, out := 0.5) -> void:
	var c := Vector2.ZERO
	for q: Vector2 in ring:
		c += q / ring.size()
	var a0 := Vector3(r0.x, yr, r0.y)
	var a1 := Vector3(r1.x, yr, r1.y)
	var n := ring.size()
	for i in range(n):
		var a: Vector2 = ring[i] + (ring[i] - c).normalized() * out
		var b: Vector2 = ring[(i + 1) % n] + (ring[(i + 1) % n] - c).normalized() * out
		var ra: Vector3 = a0 if a.distance_to(r0) <= a.distance_to(r1) else a1
		var rb: Vector3 = a0 if b.distance_to(r0) <= b.distance_to(r1) else a1
		var pa := Vector3(a.x, ye, a.y)
		var pb := Vector3(b.x, ye, b.y)
		if ra == rb:
			roof([pa, pb, ra])
		else:
			roof([pa, pb, rb])
			roof([pa, rb, ra])
		ridge(pa, ra)
	ridge(a0, a1)

## the plain walls of a body: every side of its outline but those in `skip`, from under the ground up to `top`
func _walls(ring: Array, top: float, key, skip: Array = []) -> void:
	for i in range(ring.size()):
		if not skip.has(i):
			_plain(ring[i], ring[(i + 1) % ring.size()], -3.0, top, key)

# ---------------- the convent's front, on the Calle de las Monjas ----------------
func _front() -> void:
	face(Vector2(0, 0), Vector2(LF, 0))
	var small := Rect2(float(BAYS[SMALL_DOOR]) - 0.47, 0.0, 0.94, 2.3)
	var r := 1.12
	var spring := 1.72
	var cx: float = BAYS[GREAT_DOOR]
	var great := Rect2(cx - r, 0.0, 2.0 * r, spring + r)
	var low: Array = []
	var high: Array = []
	for k in range(BAYS.size()):
		var c: float = BAYS[k]
		high.append(Rect2(c - 0.52, 4.95, 1.04, 1.65))
		if k != SMALL_DOOR and k != GREAT_DOOR:
			low.append(Rect2(c - 0.6, 1.22, 1.2, 1.88))
	var holes: Array = [small, great]
	holes.append_array(low)
	holes.append_array(high)
	var over: Array = [Rect2(cx - r - 0.8, 0.0, 2.0 * r + 1.6, BAND)]         # (the great door stands in plain brick up to its cornice)
	for h: Rect2 in holes:
		over.append(h.grow(0.26))
	var panels: Array = []
	var edges: Array = [0.0]
	edges.append_array(BAYS)
	edges.append(LF)
	for k in range(edges.size() - 1):
		var x0: float = float(edges[k]) + (0.98 if k > 0 else 0.3)
		var x1: float = float(edges[k + 1]) - (0.98 if k < edges.size() - 2 else 0.3)
		if x1 - x0 < 0.8:
			continue
		panels.append_array(_boxes(x0, x1, 0.6, BAND - 0.2))
		panels.append_array(_boxes(x0, x1, BAND + 0.32, EAVES - 0.5))
	masonry(0.0, LF, -1.6, EAVES, holes, panels, "ladrillo", "rubble", over)
	for q in [[0.0, small.position.x - 0.2], [small.end.x + 0.2, great.position.x - 0.35], [great.end.x + 0.35, LF]]:      # its foot of rubble
		box(q[0], -1.6, 0.0, q[1] - q[0], 2.1, 0.05, "rubble")
	box(0.0, BAND - 0.06, 0.0, LF, 0.12, 0.035, "ladrillo")                     # the course between the floors
	for w: Rect2 in low:
		window(w, 0xe9e6dc, 0x39566a, 2)
		box(w.position.x + 0.05, w.position.y + w.size.y * 0.42, -DEEP + 0.1, w.size.x - 0.1, w.size.y * 0.58 - 0.05, 0.04, 0xd6d0c0)
		_reja(Rect2(w.position.x, w.position.y - 0.3, w.size.x, w.size.y + 0.4), 0.27)
	for w: Rect2 in high:
		window(w, 0xe9e6dc, 0x39566a, 1)
		box(w.position.x + 0.05, w.position.y + w.size.y * 0.5, -DEEP + 0.1, w.size.x - 0.1, w.size.y * 0.5 - 0.05, 0.04, 0xd6d0c0)
		_reja(w, 0.2)
	# the little door: dark wood under a flat arch of bricks on end, a stone step
	box(small.position.x, 0.0, -DEEP, small.size.x, small.size.y, 0.05, 0x3f2a1e)
	box(small.position.x + 0.1, 0.15, -DEEP + 0.05, small.size.x - 0.2, 0.9, 0.02, 0x4a3324)
	box(small.position.x + 0.1, 1.2, -DEEP + 0.05, small.size.x - 0.2, 0.95, 0.02, 0x4a3324)
	for i in range(8):
		box(small.position.x - 0.28 + i * 0.19, small.size.y, 0.0, 0.16, 0.42, 0.03, 0xc9a58e)
	box(small.position.x - 0.2, -0.5, 0.0, small.size.x + 0.4, 0.5, 0.42, "piedra")
	# the great door: an arch of brick three bricks thick, two leaves of old wood, and over it a cornice of its own
	spandrels(cx, spring, r, 0.0, "ladrillo")
	ring(cx, spring, r, r + 0.62, 0.045, 0.34, 0xc29a82, 16)
	ring(cx, spring, r + 0.62, r + 0.68, 0.05, 0.0, 0xb98f78, 16)
	arched(cx, 0.0, spring, r, -DEEP + 0.04, 0x36251c)
	box(cx - 0.015, 0.0, -DEEP + 0.05, 0.03, spring + r - 0.05, 0.02, 0x2a180f)
	for s in [-1.0, 1.0]:
		for j in range(3):
			box(cx + s * 0.56 - 0.4, 0.2 + j * 0.62, -DEEP + 0.05, 0.8, 0.5, 0.025, 0x42301f)
	box(cx - r - 0.2, -0.4, 0.0, 2.0 * r + 0.4, 0.4, 0.3, "piedra")
	cornice(cx - r - 0.95, cx + r + 0.95, BAND + 0.12, true, "ladrillo")
	box(cx - r - 1.05, BAND + 0.12, 0.0, 2.0 * r + 2.1, 0.07, 0.4, 0xb08a72)
	# a carved stone between the two doors, and the lanterns
	box(float(BAYS[3]) - 0.3, 3.3, 0.0, 0.6, 0.95, 0.07, "piedra")
	slab(oval(float(BAYS[3]), 3.78, 0.2, 0.3, 12), 0.085, 0.0, 0xc9b48e)
	for x in [0.45, 13.4, 27.75]:
		_farol(x, 3.85)
	cornice(0.0, LF, EAVES + 0.42, true, "ladrillo")
	home()

## The front wing behind that wall, its end on the little court, and the ranges behind it.
func _wing() -> void:
	_walls(WING, EAVES, "ladrillo", [0, 1])
	# its north end, on the court: brick and rubble, a small door with its plate
	face(Vector2(LF, 0), Vector2(LF, -3.0))
	var dr := Rect2(1.1, yc, 0.9, 2.1)
	masonry(0.0, 3.0, -1.6, EAVES, [dr], _boxes(0.3, 0.8, 0.6, EAVES - 0.5), "ladrillo", "rubble")
	box(dr.position.x, dr.position.y, -DEEP, dr.size.x, dr.size.y, 0.05, 0x2f2a26)
	box(dr.end.x + 0.25, yc + 1.25, 0.0, 0.42, 0.3, 0.03, 0xf1eee6)
	cornice(0.0, 3.0, EAVES + 0.42, true, "ladrillo")
	home()
	_plain(Vector2(LF, -3.0), Vector2(LF, -9.0), -1.0, EAVES, "ladrillo")
	_tent(WING, Vector2(4.5, -4.5), Vector2(LF - 4.5, -4.5), EAVES + 0.42, EAVES + 2.0)
	_prism(WING, -3.0, EAVES + 1.0)
	_walls(BACK, EAVES - 0.5, "crema")
	_tent(BACK, Vector2(12.0, -17.0), Vector2(20.0, -17.0), EAVES - 0.4, EAVES + 1.9)
	_prism(BACK, -3.0, EAVES)
	_walls(LOW, 3.4, "crema")
	_tent(LOW, Vector2(5.5, -21.0), Vector2(5.8, -35.0), 3.45, 4.5, 0.3)
	_prism(LOW, -3.0, 3.4)
	# the little belfry astride the end of the roof, by the church
	var bx := 27.0
	var bz := -2.3
	var by: float = EAVES + 0.9
	cbox(Vector3(bx, by + 1.3, bz), Vector3(2.5, 2.6, 2.5), "ladrillo")
	for s in [-1.0, 1.0]:
		cbox(Vector3(bx, by + 1.7, bz + s * 1.26), Vector3(0.7, 1.1, 0.03), 0x2a2622)
		cbox(Vector3(bx + s * 1.26, by + 1.7, bz), Vector3(0.03, 1.1, 0.7), 0x2a2622)
	cbox(Vector3(bx, by + 2.66, bz), Vector3(2.7, 0.12, 2.7), 0xc9a58e)
	_hip(bx - 1.25, bx + 1.25, bz - 1.25, bz + 1.25, by + 2.72, 0.9, 0.25)
	box(bx - 0.02, by + 3.5, bz - 0.02, 0.04, 0.8, 0.04, IRON)
	box(bx - 0.2, by + 4.0, bz - 0.02, 0.4, 0.04, 0.04, IRON)

## The tower behind the front: square, of brick with boxes of rubble, arched openings under its tiles.
func _tower() -> void:
	var x0: float = TOWER.position.x
	var x1: float = TOWER.end.x
	var z0: float = TOWER.position.y
	var z1: float = TOWER.end.y
	var sides: Array = [[Vector2(x0, z1), Vector2(x1, z1)], [Vector2(x1, z1), Vector2(x1, z0)], [Vector2(x1, z0), Vector2(x0, z0)], [Vector2(x0, z0), Vector2(x0, z1)]]
	for k in range(4):
		var ln: float = face(sides[k][0], sides[k][1])
		var mids: Array = [ln * 0.29, ln * 0.71] if k % 2 == 0 else [ln * 0.5]
		var holes: Array = []
		for c in mids:
			holes.append(Rect2(float(c) - 0.62, 12.0, 1.24, 1.9))
		var panels: Array = _boxes(0.6, ln - 0.6, EAVES + 0.9, 11.4)
		masonry(0.0, ln, EAVES - 1.5, TOWER_TOP, holes, panels, "ladrillo", "rubble")
		for c in mids:
			spandrels(float(c), 13.28, 0.62, 0.0, "ladrillo")
			arched(float(c), 12.0, 13.28, 0.62, -DEEP + 0.02, 0x2a2622 if k != 3 else 0x7a3a2a)
			box(float(c) - 0.72, 11.9, 0.0, 1.44, 0.1, 0.06, 0xc9a58e)
		cornice(0.0, ln, TOWER_TOP + 0.42, true, "ladrillo")
		home()
	_hip(x0, x1, z0, z1, TOWER_TOP + 0.42, 1.5, 0.45)

# ---------------- the church ----------------
func _church() -> void:
	var n := CHURCH.size()
	for i in range(n):
		var a: Vector2 = CHURCH[i]
		var b: Vector2 = CHURCH[(i + 1) % n]
		var ln: float = face(a, b, yc)
		match i:
			0:      # the wall of its doorway, back from the street
				var pc := 3.1
				var door_hole := Rect2(pc - 1.15, 0.0, 2.3, 3.75)
				var panels: Array = _boxes(6.0, ln - 0.4, 0.7, CH - 0.6)
				panels.append_array(_boxes(0.4, 5.0, 7.9, CH - 0.6))
				masonry(0.0, ln, -1.8, CH, [door_hole], panels, "ladrillo", "rubble")
				_portal(pc)
			1:      # the return of the taller end
				masonry(0.0, ln, -1.8, CH, [], _boxes(0.5, ln - 0.5, 0.7, CH - 0.6), "ladrillo", "rubble")
			2:      # the church's end on the Calle de las Monjas: tall, blind but for one small window
				var win := Rect2(ln * 0.5 - 0.4, 6.7, 0.8, 1.1)
				var p2: Array = _boxes(0.6, ln * 0.5 - 0.9, 1.1, CH - 0.6)
				p2.append_array(_boxes(ln * 0.5 + 0.9, ln - 0.9, 1.1, CH - 0.6))
				masonry(0.0, ln, -1.8, CH, [win], p2, "ladrillo", "rubble")
				box(0.0, -1.8, 0.0, ln, 2.7, 0.06, "rubble")
				window(win, 0x6a5a4a, 0x2a3640, 1)
				_reja(win, 0.12, 0x3a3d40)
				_quoins(ln, -1.0)
			3:      # its end on the Calle de Santiago Apóstol
				var w3 := Rect2(6.6, 1.7, 1.0, 1.5)
				masonry(0.0, ln, -1.8, CH, [w3], [Rect2(5.6, -1.8, 3.6, 6.4)], "ladrillo", "rubble")
				window(w3, 0x6a5a4a, 0x39566a, 1)
				grille(w3, 0.14, 0x4a4d52)
				_quoins(0.0, 1.0)
			_:
				quad(Vector3(0, -1.8, 0), Vector3(ln, -1.8, 0), Vector3(ln, CH, 0), Vector3(0, CH, 0), "ladrillo", Vector3(0, 0, 1))
		cornice(0.0, ln, CH + 0.42, true, "ladrillo")
		home()
	_tent(CHURCH, Vector2(32.0, -8.0), Vector2(40.5, -8.2), yc + CH + 0.42, yc + CH + 3.0)
	_prism([CHURCH[0], CHURCH[1], Vector2(45.2, -4.4), CHURCH[4], CHURCH[5]], -3.0, yc + CH)
	_prism([CHURCH[1], CHURCH[2], CHURCH[3], Vector2(45.2, -4.4)], -3.0, yc + CH)

## blocks of stone up a corner of the wall being built (at x; side: which way they run from it)
func _quoins(x: float, side: float) -> void:
	for j in range(9):
		var w: float = 0.62 if j % 2 == 0 else 0.4
		box(x if side > 0.0 else x - w, -1.2 + j * 0.42, 0.0, w, 0.4, 0.07, "piedra")

## The church's doorway, of golden stone: a round arch between pilasters under a cornice; over it a niche between two
## shields, and a cross on top; two leaves of dark panelled wood.
func _portal(pc: float) -> void:
	var r := 1.15
	var spring := 2.6
	spandrels(pc, spring, r, 0.06, "piedra")
	ring(pc, spring, r, r + 0.34, 0.16, 0.34, "piedra", 14)
	for s in [-1.0, 1.0]:
		box(pc + s * (r + 0.3) - 0.3, 0.0, 0.0, 0.6, spring + r + 0.3, 0.07, "piedra")            # the field beside the arch
		box(pc + s * (r + 1.0) - 0.4, 0.0, 0.0, 0.8, 4.1, 0.24, "piedra")                          # its pilasters
		box(pc + s * (r + 1.0) - 0.46, 0.0, 0.0, 0.92, 0.55, 0.3, "piedra")
		box(pc + s * (r + 1.0) - 0.45, 3.86, 0.0, 0.9, 0.24, 0.3, "piedra")
	box(pc - r, spring + r, 0.0, 2.0 * r, 0.3, 0.07, "piedra")
	box(pc - r - 1.5, 4.1, 0.0, 2.0 * r + 3.0, 0.36, 0.3, "piedra")                                 # the cornice
	box(pc - r - 1.6, 4.46, 0.0, 2.0 * r + 3.2, 0.1, 0.4, "piedra")
	# the upper stage: the niche in its frame under a little pediment, a shield each side, the cross
	box(pc - 0.6, 4.56, 0.0, 1.2, 1.8, 0.2, "piedra")
	box(pc - 0.32, 4.86, 0.2, 0.64, 1.15, 0.012, 0x4a4238)
	box(pc - 0.12, 4.9, 0.21, 0.24, 0.78, 0.07, 0xdccfb4)                                           # (what stands in it: carved stone)
	box(pc - 0.75, 6.36, 0.0, 1.5, 0.1, 0.3, "piedra")
	slab(PackedVector2Array([Vector2(pc - 0.7, 6.46), Vector2(pc + 0.7, 6.46), Vector2(pc, 6.9)]), 0.22, 0.22, "piedra")
	for s in [-1.0, 1.0]:
		box(pc + s * 1.75 - 0.5, 4.72, 0.0, 1.0, 1.15, 0.12, "piedra")
		slab(oval(pc + s * 1.75, 5.3, 0.32, 0.42, 12), 0.135, 0.0, 0xc9b48e)
		box(pc + s * 1.75 - 0.56, 5.87, 0.0, 1.12, 0.09, 0.18, "piedra")
	box(pc - 0.07, 6.9, 0.06, 0.14, 0.95, 0.14, "piedra")
	box(pc - 0.32, 7.4, 0.06, 0.64, 0.14, 0.14, "piedra")
	# the doors
	arched(pc, 0.0, spring, r, -DEEP + 0.04, 0x3f211c)
	box(pc - 0.015, 0.0, -DEEP + 0.05, 0.03, spring + r - 0.1, 0.02, 0x2a120e)
	for s in [-1.0, 1.0]:
		for j in range(5):
			for i in range(2):
				box(pc + s * 0.58 - 0.46 + i * 0.48, 0.18 + j * 0.56, -DEEP + 0.05, 0.42, 0.46, 0.025, 0x4c2a22)

## The little court before the church's door: brick pavers, two cypresses, the pedestal, the board that tells what this is.
func _court() -> void:
	var pts: Array = [Vector2(LF, 0.0), Vector2(28.5, -3.0), Vector2(36.44, -4.23), Vector2(36.92, -1.15), Vector2(37.3, 0.5), Vector2(LF, 0.6)]
	var c := Vector2(32.6, -1.4)
	for i in range(pts.size()):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		tri(Vector3(c.x, ground(c.x, c.y) + 0.035, c.y), Vector3(a.x, ground(a.x, a.y) + 0.035, a.y), Vector3(b.x, ground(b.x, b.y) + 0.035, b.y), "solado", Vector3.UP)
	pieces += 1
	_cipres(Vector2(35.4, -2.9), 9.5)
	_cipres(Vector2(36.1, -0.5), 7.0)
	# the pedestal, and the bronze friar on it
	var p := Vector2(34.3, -0.7)
	var g: float = ground(p.x, p.y)
	cbox(Vector3(p.x, g + 0.1, p.y), Vector3(1.0, 0.2, 1.0), "piedra")
	cbox(Vector3(p.x, g + 0.65, p.y), Vector3(0.72, 0.9, 0.72), "piedra")
	cbox(Vector3(p.x, g + 1.14, p.y), Vector3(0.84, 0.08, 0.84), "piedra")
	solid(Vector3(p.x, g + 1.5, p.y), Vector3(1.0, 3.0, 1.0))
	yard.append(spot(p.x, p.y))
	_friar(Vector3(p.x, g + 1.18, p.y))
	# the board: two grey posts, a red panel with its heading
	var q := Vector2(38.4, -0.55)
	var gq: float = ground(q.x, q.y)
	for s in [-0.42, 0.42]:
		cbox(Vector3(q.x + s, gq + 0.95, q.y), Vector3(0.05, 1.9, 0.05), 0x8a8f96)
	cbox(Vector3(q.x, gq + 1.3, q.y), Vector3(0.8, 1.05, 0.04), 0x8a2a2a)
	cbox(Vector3(q.x, gq + 1.68, q.y + 0.025), Vector3(0.7, 0.18, 0.01), 0xf1eee6)
	cbox(Vector3(q.x, gq + 1.2, q.y + 0.025), Vector3(0.7, 0.6, 0.01), 0xe9e2d0)
	yard.append(spot(q.x, q.y))

## The friar: a figure made as the game's people are (chara.gd) -- the tonsure, the beard, a habit to his feet with its
## hood and its cord, his arms open --, and then every piece of him given the one bronze.
func _friar(at: Vector3) -> void:
	var tone := 0x7a5a36
	var who = Chara.new()
	who.setup({"shirt": tone, "skin": tone, "hair": tone, "shoes": tone, "hair_style": 10, "face": 2, "brows": 0, "top": 0, "eye_color": tone})
	who._add("cyl", tone, Vector3(0, 0.15, 0), Vector3(0.47, 0.3, 0.47))                 # the habit, down to his feet
	who._add("ball", tone, Vector3(0, 1.03, -0.2), Vector3(0.36, 0.2, 0.3))               # its hood, down on his back
	who._band(tone, 0.66, 0.05, 0.02)                                                    # the cord at his waist, and its end hanging
	who._add("cyl", tone, Vector3(0.2, 0.46, 0.34), Vector3(0.025, 0.38, 0.025))
	who._add("ball", tone, Vector3(0.2, 0.26, 0.34), Vector3.ONE * 0.045)
	for sx in [-1.0, 1.0]:                          # his arms open: the hands out and up, a wide sleeve behind each
		var hand: Node3D = who._hl if sx < 0.0 else who._hr
		hand.position = Vector3(sx * 0.66, 0.98, 0.2)
		var sleeve: MeshInstance3D = who._add("cyl", tone, Vector3(sx * 0.5, 0.92, 0.1), Vector3(0.11, 0.34, 0.11))
		sleeve.rotation = Vector3(0.5, 0.0, -sx * 1.15)
	var figure: Node3D = who.vis
	who.remove_child(figure)
	who.free()
	var bronze := StandardMaterial3D.new()
	bronze.albedo_color = Color(0.5, 0.36, 0.2)
	bronze.metallic = 0.7
	bronze.roughness = 0.42
	bronze.rim_enabled = true
	bronze.rim = 0.4
	bronze.emission_enabled = true                   # (so that it reads as bronze in the shade of the church too)
	bronze.emission = Color(0.36, 0.25, 0.13)
	bronze.emission_energy_multiplier = 0.3
	var todo: Array = [figure]
	while not todo.is_empty():
		var n: Node = todo.pop_back()
		if n is MeshInstance3D:
			(n as MeshInstance3D).material_override = bronze
			(n as MeshInstance3D).visible = true
		todo.append_array(n.get_children())
	friar = Node3D.new()
	friar.position = at
	friar.rotation.y = -0.35                         # (he looks down the street, towards whoever comes)
	friar.add_child(figure)
	add_child(friar)
	pieces += 1

# ---------------- the Calle de Santiago Apóstol ----------------
## The north range: a long cream wall on a dark red foot, a few barred windows high up, tiles.
func _north() -> void:
	var a: Vector2 = RANGE[1]
	var b: Vector2 = RANGE[2]
	var ln: float = face(a, b)
	var top := 7.2
	var wins: Array = []
	for k in range(4):
		wins.append(Rect2(3.2 + k * 6.6, 4.3, 1.0, 1.25))
	masonry(0.0, ln, -3.0, top, wins, [], "crema")
	for k in range(6):                              # its foot, following the street as it falls
		var x0: float = ln * k / 6.0
		var x1: float = ln * (k + 1) / 6.0
		var pm: Vector2 = a.lerp(b, (k + 0.5) / 6.0)
		box(x0, -3.0, 0.0, x1 - x0, ground(pm.x + 0.5, pm.y) + 0.5 + 3.0, 0.03, 0x6a2c28)
	for w: Rect2 in wins:
		window(w, 0x7a4a2a, 0x39566a, 1)
		grille(w, 0.14, 0x4a4d52)
	box(0.0, top, 0.0, ln, 0.12, 0.3, 0xc9a58e)
	home()
	_walls(RANGE, top, "crema", [1])
	_tent(RANGE, Vector2(33.5, -18.0), Vector2(31.5, -34.5), top + 0.12, top + 2.0)
	_prism(RANGE, -3.0, top + 0.5)

## The garden behind its walls: only the heads of its trees show from the street.
func _garden() -> void:
	for i in range(GARDEN.size() - 1):
		var a: Vector2 = GARDEN[i]
		var b: Vector2 = GARDEN[i + 1]
		var ln: float = face(a, b)
		var low: float = minf(ground(a.x, a.y), ground(b.x, b.y)) - 1.0
		var top: float = maxf(ground(a.x, a.y), ground(b.x, b.y)) + 3.1
		box(0.0, low, -0.4, ln, top - low, 0.4, "crema")
		box(-0.05, top, -0.5, ln + 0.1, 0.1, 0.6, 0xa8623f)
		home()
		var d: Vector2 = (b - a).normalized()
		var mid: Vector2 = (a + b) / 2.0 + Vector2(d.y, -d.x) * 0.2
		solid(Vector3(mid.x, (low + top) / 2.0, mid.y), Vector3(ln, top - low, 0.4), atan2(-d.y, d.x))
		yard.append(spot(a.x, a.y))
		yard.append(spot(b.x, b.y))
	for q in [Vector2(14.0, -31.0), Vector2(20.5, -41.0), Vector2(30.0, -44.5)]:
		_cipres(q, 8.5)
	for q in [Vector2(12.0, -42.5), Vector2(26.0, -42.0), Vector2(18.0, -34.5)]:
		var g: float = ground(q.x, q.y)
		drum(Vector3(q.x, g, q.y), 0.2, 0.14, 3.0, 0x6b5a45, 8)
		ball(Vector3(q.x, g + 4.6, q.y), 2.3, "leaf", 0.85, 10, 6)
