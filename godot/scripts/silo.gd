extends "res://scripts/obra.gd"
## The Silo del Tío Anaranjao (the user, 21 November 2026: "el silo del tío colorao (que lo llamaremos silo del tío
## anaranjao). Aparte de la fachada quiero que se pueda visitar por dentro"): the real Silo del Tío Colorao, a museum
## of the houses dug under the ground of La Mancha, at the point of the block between the Calle de San Agustín, the
## Calle de la Paz and the Calle de las Navas de Tolosa.
##
## What is built here is what the street sees (Street View, November 2024; the orthophoto tools/ign/silo.jpg):
##   - the yard's wall: whitewashed, a man and a half high, under a coping of curved tiles, following the pavement round
##     the corner in one curve from the big building on the north-west to the house on the Navas de Tolosa;
##   - in it the gate, two leaves of dark wood studded with nails, its board ("SILO DEL TÍO ANARANJAO": the user's name
##     for it) beside it, and barred windows through which the yard is seen;
##   - inside, the yard of bare earth, and in it the "caño": the way down, seen from above as its two low white walls
##     and its end, a flight of steps and the dark between them; and the white chimneys of the kitchens under the yard.
## The inside is a set apart (silo_dentro.gd), entered by the green arrow at the gate (entradas.gd).
##
## No rebake: the map has no house on this lot (bare ground between Catastro's 4789011 and 4789013). The game's Calle de
## San Agustín is wider than the real one (the real gate would stand on its asphalt), so the wall is found at load: from
## a spot in the yard, a ray every few degrees out to where the pavement ends, or to a neighbour's wall.
## The frame: the map's own axes, from that spot.

const DentroS = preload("res://scripts/silo_dentro.gd")

const C0 := Vector2(517.5, 313.3)       # a spot in the middle of the yard: the frame's origin
const FROM := 300.0                     # from it, the bearings (degrees from north, clockwise) the wall is looked for along:
const TO := 118.0                       # ...from the building on the north-west round through the south to the house on the east
const STEP := 5.0
const BACK := 1.75                      # the wall stands this far past the asphalt's edge (the pavement's width, and a hand)
const WALL_H := 2.3
const THICK := 0.4
const GATE_B := 240.0                   # the gate lies this way from the spot
const GATE_W := 2.3
const GATE_H := 2.2
const TRENCH_L := 8.6
const TRENCH_W := 1.32                  # half its width, between its low walls (wider than the gate: its open leaves stand within)
const WHITE := "white"
const TILE := 0xb5653f

var dentro                              # its inside, a set apart (silo_dentro.gd), entered by the green arrow at the gate
var wall: Array = []                    # the wall's line, on the map, from the north-west round to the east
var gate := Vector2.ZERO                # the gate's middle, on the map
var gate_out := Vector2.ZERO            # the way out of it, into the street
var windows := 0                        # its barred windows
var board: Label3D           # the name on the gate's board

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"puerta":           # the gate's dark old wood
			m = Tex.mat("old_planks_02", Color(0.42, 0.3, 0.2))
		"hueco":            # the dark of the way down
			var hm := StandardMaterial3D.new()
			hm.albedo_color = Color(0.1, 0.09, 0.08)
			hm.roughness = 1.0
			m = hm
		"escalon":          # its steps, going down into the shade
			var sm := StandardMaterial3D.new()
			sm.albedo_color = Color(0.5, 0.42, 0.32)
			sm.roughness = 1.0
			m = sm
		"guijarro":         # the cobbles inside the gate: the set's own
			m = dentro._material("guijarro_sol") if dentro != null else Parts.mat(0xb8915a)
		"cartel":           # the board's dark brown
			var cm := StandardMaterial3D.new()
			cm.albedo_color = Color(0.36, 0.2, 0.1)
			cm.roughness = 0.8
			m = cm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	level = MapData.height(C0)
	transform = Transform3D(Basis.IDENTITY, Vector3(C0.x, level, C0.y))
	W.add_child(self)
	_line()
	if wall.size() < 6:
		return
	_wall()
	_yard()
	dentro = DentroS.new()                              # (before this is made into meshes: the cobbles inside the gate are the set's)
	dentro.build(W, gate + gate_out * 0.3, gate + gate_out * 2.0, atan2(gate_out.x, gate_out.y))
	_commit()

## a spot on the map, in this frame (the map's own axes)
func _loc(p: Vector2) -> Vector2:
	return p - C0

## how far a spot on the map is past the edge of the nearest street's asphalt, as the game lays it
func car_dist(p: Vector2) -> float:
	var best := 99.0
	var list = MapData._seg_grid.get(Vector2i(MapData._cell(p.x), MapData._cell(p.y)))
	if list != null:
		for sg in list:
			if int(sg.road["k"]) != 0:
				continue
			best = minf(best, MapData.seg_point(sg, p).distance_to(p) - MapData.fitted_hw(sg))
	return best

static func _dir(bearing: float) -> Vector2:
	var a := deg_to_rad(bearing)
	return Vector2(sin(a), -cos(a))

## Where the wall goes: from the spot in the yard, out along each bearing to where the pavement ends (the wall) or to a
## neighbour's wall (there it ends). The run of rays that reached the street, with the neighbours' walls at its two ends.
func _line() -> void:
	var hits: Array = []                                # [spot, "calle" | "casa" | ""]
	var b := FROM
	while b >= TO - 0.01:
		var d := _dir(b)
		var r := 1.5
		var what := ""
		while r < 18.0:
			var p := C0 + d * r
			if car_dist(p) < BACK:
				what = "calle"
				break
			if MapData.room_at(p) < 0.15:
				what = "casa"
				break
			r += 0.1
		hits.append([C0 + d * r, what])
		b -= STEP
	var first := -1
	var last := -1
	var run0 := -1
	for i in range(hits.size() + 1):                    # the longest run of rays that reached the street
		var on: bool = i < hits.size() and String(hits[i][1]) == "calle"
		if on and run0 < 0:
			run0 = i
		if not on and run0 >= 0:
			if i - run0 > last - first + 1 or first < 0:
				first = run0
				last = i - 1
			run0 = -1
	if first < 0:
		return
	if first > 0 and String(hits[first - 1][1]) == "casa":
		wall.append(hits[first - 1][0])
	for i in range(first, last + 1):
		wall.append(hits[i][0])
	if last + 1 < hits.size() and String(hits[last + 1][1]) == "casa":
		wall.append(hits[last + 1][0])
	# the gate: where the ray of its bearing meets the wall
	var gd := _dir(GATE_B)
	var bestd := 1e9
	for i in range(wall.size() - 1):
		var a: Vector2 = wall[i]
		var c: Vector2 = wall[i + 1]
		var hit = Geometry2D.segment_intersects_segment(C0, C0 + gd * 30.0, a, c)
		if hit != null and (hit as Vector2).distance_to(C0) < bestd:
			bestd = (hit as Vector2).distance_to(C0)
			gate = hit
			gate_out = Vector2((c - a).y, -(c - a).x).normalized()
			if gate_out.dot(gate - C0) < 0.0:
				gate_out = -gate_out
	if bestd > 1e8:
		wall.clear()

# ---------------- the wall ----------------
## how far along the wall each of its corners is
func _lengths() -> PackedFloat32Array:
	var out := PackedFloat32Array([0.0])
	for i in range(wall.size() - 1):
		out.append(out[i] + (wall[i] as Vector2).distance_to(wall[i + 1]))
	return out

## the spot on the wall's line `s` metres along it, and which way it runs there
func _at(s: float, lens: PackedFloat32Array) -> Array:
	for i in range(wall.size() - 1):
		if s <= lens[i + 1] or i == wall.size() - 2:
			var a: Vector2 = wall[i]
			var b: Vector2 = wall[i + 1]
			var u := (b - a).normalized()
			return [a + u * (s - lens[i]), u]
	return [wall[0], Vector2.RIGHT]

## The wall, stretch by stretch: whitewash on both faces, the coping of tiles in two slopes; the gate's hole and the
## windows' left in it. Then the gate and the windows themselves.
func _wall() -> void:
	var lens := _lengths()
	var total := lens[lens.size() - 1]
	var gs := 0.0                                       # how far along the gate's middle is
	var best := 1e9
	var s := 0.0
	while s <= total:
		var p: Vector2 = _at(s, lens)[0]
		if p.distance_to(gate) < best:
			best = p.distance_to(gate)
			gs = s
		s += 0.05
	# the holes: the gate, and the barred windows either side of it and along the south side
	var holes: Array = [[gs - GATE_W / 2.0, gs + GATE_W / 2.0, 0.0, GATE_H, "gate"]]
	for w in [[gs - 3.6, 1.2], [gs + 2.5, 0.7], [gs + 6.2, 1.1], [gs + 9.0, 1.1], [gs + 12.4, 1.1]]:
		var ws: float = w[0]
		var ww: float = w[1]
		if ws - ww / 2.0 > 0.8 and ws + ww / 2.0 < total - 0.8:
			holes.append([ws - ww / 2.0, ws + ww / 2.0, 1.0, 1.0 + minf(ww, 1.1), "window"])
			windows += 1
	var marks: Array = [0.0, total]
	for i in range(1, lens.size() - 1):
		marks.append(lens[i])
	for h in holes:
		marks.append(float(h[0]))
		marks.append(float(h[1]))
	marks.sort()
	for i in range(marks.size() - 1):
		var s0: float = marks[i]
		var s1: float = marks[i + 1]
		if s1 - s0 < 0.02:
			continue
		var pa: Array = _at(s0 + 0.001, lens)
		var u: Vector2 = pa[1]
		var a2: Vector2 = _loc(pa[0]) - u * 0.001
		var b2: Vector2 = a2 + u * (s1 - s0)
		var n := Vector2(u.y, -u.x)
		if n.dot(a2) < 0.0:                             # (out, away from the yard's middle)
			n = -n
		var ga := ground(a2.x, a2.y)
		var gb := ground(b2.x, b2.y)
		var lo := 0.0
		var hi := 0.0
		for h in holes:
			if (s0 + s1) / 2.0 > float(h[0]) and (s0 + s1) / 2.0 < float(h[1]):
				lo = float(h[2])
				hi = float(h[3])
		var top_a := ga + WALL_H
		var top_b := gb + WALL_H
		for side in [1.0, -1.0]:                        # its two faces
			var o: Vector2 = n * (THICK / 2.0) * side
			var nn := Vector3(n.x * side, 0, n.y * side)
			if hi <= 0.0:
				quad(Vector3(a2.x + o.x, ga - 0.4, a2.y + o.y), Vector3(b2.x + o.x, gb - 0.4, b2.y + o.y), Vector3(b2.x + o.x, top_b, b2.y + o.y), Vector3(a2.x + o.x, top_a, a2.y + o.y), WHITE, nn)
			else:
				quad(Vector3(a2.x + o.x, ga + hi, a2.y + o.y), Vector3(b2.x + o.x, gb + hi, b2.y + o.y), Vector3(b2.x + o.x, top_b, b2.y + o.y), Vector3(a2.x + o.x, top_a, a2.y + o.y), WHITE, nn)
				if lo > 0.0:
					quad(Vector3(a2.x + o.x, ga - 0.4, a2.y + o.y), Vector3(b2.x + o.x, gb - 0.4, b2.y + o.y), Vector3(b2.x + o.x, gb + lo, b2.y + o.y), Vector3(a2.x + o.x, ga + lo, a2.y + o.y), WHITE, nn)
		if hi > 0.0:                                    # the hole's sill and its head, through the wall
			for y in ([lo, hi] if lo > 0.0 else [hi]):
				var yy: float = y
				quad(Vector3(a2.x - n.x * 0.2, ga + yy, a2.y - n.y * 0.2), Vector3(b2.x - n.x * 0.2, gb + yy, b2.y - n.y * 0.2), Vector3(b2.x + n.x * 0.2, gb + yy, b2.y + n.y * 0.2), Vector3(a2.x + n.x * 0.2, ga + yy, a2.y + n.y * 0.2), WHITE, Vector3.UP if yy == lo else Vector3.DOWN)
		for e in [[a2, ga, s0, -1.0], [b2, gb, s1, 1.0]]:      # the cheeks of a hole, where this stretch meets one
			var es: float = e[2]
			var edge := false
			for h in holes:
				if absf(es - float(h[0])) < 0.001 or absf(es - float(h[1])) < 0.001:
					edge = true
			if edge and hi <= 0.0:
				var ep: Vector2 = e[0]
				var eg: float = e[1]
				quad(Vector3(ep.x - n.x * 0.2, eg - 0.4, ep.y - n.y * 0.2), Vector3(ep.x + n.x * 0.2, eg - 0.4, ep.y + n.y * 0.2), Vector3(ep.x + n.x * 0.2, eg + WALL_H, ep.y + n.y * 0.2), Vector3(ep.x - n.x * 0.2, eg + WALL_H, ep.y - n.y * 0.2), WHITE, Vector3(u.x, 0, u.y) * float(e[3]))
		# the coping: two slopes of tiles, a hand out over each face
		var ridge_a := Vector3(a2.x, top_a + 0.17, a2.y)
		var ridge_b := Vector3(b2.x, top_b + 0.17, b2.y)
		for side in [1.0, -1.0]:
			var o2: Vector2 = n * 0.32 * side
			roof([ridge_a, ridge_b, Vector3(b2.x + o2.x, top_b, b2.y + o2.y), Vector3(a2.x + o2.x, top_a, a2.y + o2.y)])
		if hi <= 0.0 or lo > 0.0:
			var mid := (a2 + b2) / 2.0
			solid(Vector3(mid.x, (ga + gb) / 2.0 + WALL_H / 2.0, mid.y), Vector3(s1 - s0 + 0.05, WALL_H + 0.6, THICK), -atan2(u.y, u.x))
			if i % 3 == 0:
				yard.append(spot(mid.x, mid.y) + n * 0.1)
	for h in holes:
		var pm: Array = _at((float(h[0]) + float(h[1])) / 2.0, lens)
		var u2: Vector2 = pm[1]
		var n2 := Vector2(u2.y, -u2.x)
		var mid2: Vector2 = _loc(pm[0])
		if n2.dot(mid2) < 0.0:
			n2 = -n2
		if String(h[4]) == "gate":
			_gate(mid2, u2, n2)
		else:
			_window(mid2, u2, n2, float(h[1]) - float(h[0]), float(h[2]), float(h[3]))

## the frame of a piece of the wall: x along it, y up from the ground there, z out of it into the street
func _face(mid: Vector2, u: Vector2, n: Vector2) -> void:
	_xf = Transform3D(Basis(Vector3(u.x, 0, u.y), Vector3.UP, Vector3(n.x, 0, n.y)), Vector3(mid.x, ground(mid.x, mid.y), mid.y))
	if _xf.basis.determinant() < 0.0:                   # (keep it right-handed: the wall may run either way)
		_xf.basis.x = -_xf.basis.x

## The gate: two leaves of dark planks studded with nails in their frame, open inwards (the user, 21 November 2026:
## "dejar las puertas abiertas para que se vea un poco el modelo de la entrada desde fuera"); the board with the name
## beside it. Nobody walks through: the green arrow before it takes you in (the solid stays).
func _gate(mid: Vector2, u: Vector2, n: Vector2) -> void:
	_face(mid, u, n)
	var hw := GATE_W / 2.0
	var face := _xf
	for sx in [-1.0, 1.0]:
		box(sx * hw - 0.05, 0.0, -THICK / 2.0 - 0.02, 0.1, GATE_H + 0.05, THICK + 0.04, 0x3a2a1e)        # (the frame's posts)
		_xf = face * Transform3D(Basis(Vector3.UP, (PI - 1.5) if sx > 0.0 else 1.5), Vector3(sx * (hw - 0.03), 0.0, -THICK / 2.0))      # (open, all but square to the wall)
		box(0.0, 0.03, -0.035, hw - 0.04, GATE_H - 0.05, 0.07, "puerta")
		for side in [-1.0, 1.0]:
			for i in range(4):
				for j in range(6):
					ball(Vector3(0.14 + i * 0.27, 0.22 + j * 0.35, side * 0.04), 0.024, 0x1e1a16, 0.8, 6, 3)
			for y in [0.5, 1.6]:                          # (its straps of iron)
				box(0.02, y, side * 0.036 - 0.006, hw - 0.14, 0.05, 0.012, 0x1e1a16)
		_xf = face
	box(-hw - 0.05, GATE_H, -THICK / 2.0 - 0.02, GATE_W + 0.1, 0.09, THICK + 0.04, 0x3a2a1e)
	box(-hw, -0.1, -THICK / 2.0, GATE_W, 0.13, THICK + 0.1, 0x8a8076)            # the sill (a finger over the pavement, level with the cobbles within)
	# the board: dark wood, the name in yellow
	var bx := -hw - 1.25
	box(bx, 1.5, THICK / 2.0, 0.95, 0.42, 0.03, "cartel")
	board = _text("SILO DEL\nTÍO ANARANJAO", Vector3(bx + 0.475, 1.71, THICK / 2.0 + 0.034), 30, 0xf0c838, 0.0036)
	board.line_spacing = -6.0
	home()
	solid(Vector3(mid.x, ground(mid.x, mid.y) + GATE_H / 2.0, mid.y), Vector3(GATE_W, GATE_H + 0.8, THICK), -atan2(u.y, u.x))
	yard.append(spot(mid.x, mid.y) + n * 0.1)

## a barred window: a grille of square iron bars in the hole, a sill of stone
func _window(mid: Vector2, u: Vector2, n: Vector2, w: float, lo: float, hi: float) -> void:
	_face(mid, u, n)
	var hw := w / 2.0
	var nx := maxi(3, int(w / 0.16))
	for i in range(1, nx):
		box(-hw + i * w / nx - 0.009, lo, 0.08, 0.018, hi - lo, 0.018, IRON)
	var ny := maxi(3, int((hi - lo) / 0.18))
	for j in range(1, ny):
		box(-hw, lo + j * (hi - lo) / ny - 0.009, 0.08, w, 0.018, 0.018, IRON)
	box(-hw - 0.05, lo - 0.06, -0.05, w + 0.1, 0.06, 0.32, 0xcfc8ba)
	home()

# ---------------- the yard ----------------
## The yard: the way down (its two low white walls, their round tops, the cobbled landing, the steps going down into
## the dark between them, its round end), and the kitchens' chimneys. The ground is the map's own earth.
## It runs straight in from the gate and is wider than it, so that the gate's open leaves stand inside it, clear of
## its walls; and it lies on the ground as the ground lies, piece by piece, so that its floor meets the gate's sill
## (the user, 21 November 2026: "las puertas tienen una textura de suelo clippeada y las paredes interiores atraviesan
## las puertas": it ran askew at the real one's bearing, level at the yard's highest, through the leaves).
func _yard() -> void:
	var u := -gate_out                                  # along the way down, straight in from the gate
	var v := Vector2(-u.y, u.x)
	var g0: Vector2 = _loc(gate) - gate_out * (THICK / 2.0)
	var top := 0.62
	var off := TRENCH_W + 0.2
	var n := int(ceil(TRENCH_L / 0.5))
	for k in range(n):                                  # its two low walls, a piece every half metre, on the ground there
		var s0 := TRENCH_L * k / n
		var s1 := TRENCH_L * (k + 1) / n
		for side in [-1.0, 1.0]:
			var a: Vector2 = g0 + u * s0 + v * off * side
			var b: Vector2 = g0 + u * s1 + v * off * side
			var ya := ground(a.x, a.y)
			var yb := ground(b.x, b.y)
			bar(Vector3(a.x, ya + top / 2.0 - 0.2, a.y), Vector3(b.x, yb + top / 2.0 - 0.2, b.y), 0.4, top + 0.4, WHITE)
			bar(Vector3(a.x, ya + top, a.y), Vector3(b.x, yb + top, b.y), 0.4, 0.4, WHITE, PI / 4.0)          # (its top, rounded off)
	for side in [-1.0, 1.0]:
		var m: Vector2 = g0 + u * (TRENCH_L / 2.0) + v * off * side
		solid(Vector3(m.x, ground(m.x, m.y) + top / 2.0, m.y), Vector3(TRENCH_L, top + 0.6, 0.4), -atan2(u.y, u.x))
		yard.append(spot((g0 + u * TRENCH_L + v * off * side).x, (g0 + u * TRENCH_L + v * off * side).y))
	var e: Vector2 = g0 + u * TRENCH_L                  # its end: half a round
	for i in range(8):
		var t0 := PI * i / 8.0
		var t1 := PI * (i + 1) / 8.0
		var p0: Vector2 = e + (u * sin(t0) - v * cos(t0)) * off
		var p1: Vector2 = e + (u * sin(t1) - v * cos(t1)) * off
		var y0 := ground(p0.x, p0.y)
		var y1 := ground(p1.x, p1.y)
		bar(Vector3(p0.x, y0 + top / 2.0 - 0.2, p0.y), Vector3(p1.x, y1 + top / 2.0 - 0.2, p1.y), 0.4, top + 0.4, WHITE)
		bar(Vector3(p0.x, y0 + top, p0.y), Vector3(p1.x, y1 + top, p1.y), 0.4, 0.4, WHITE, PI / 4.0)
	solid(Vector3((e + u * 0.7).x, ground((e + u * 0.7).x, (e + u * 0.7).y) + top / 2.0, (e + u * 0.7).y), Vector3(1.4, top + 0.6, 2.0 * off + 0.4), -atan2(u.y, u.x))
	# between them, each piece on the ground under its own corners: the landing, cobbled; the steps, each darker
	# than the last (the way goes down out of the light); then the dark
	var q := func(s0: float, s1: float, lift: float, key) -> void:
		var c: Array = [g0 + u * s0 - v * TRENCH_W, g0 + u * s0 + v * TRENCH_W, g0 + u * s1 + v * TRENCH_W, g0 + u * s1 - v * TRENCH_W]
		var pts: Array = []
		for cc in c:
			var w2: Vector2 = cc
			pts.append(Vector3(w2.x, ground(w2.x, w2.y) + lift, w2.y))
		quad(pts[0], pts[1], pts[2], pts[3], key, Vector3.UP)
	var land := 1.6
	var s := 0.0
	while s < land - 0.001:
		q.call(s, minf(s + 0.4, land), 0.035, "guijarro")
		s += 0.4
	for i in range(9):
		var k := i / 8.0
		var col := Color(0.72, 0.57, 0.36).lerp(Color(0.1, 0.09, 0.08), k)
		q.call(land + i * 0.4, land + (i + 1) * 0.4, 0.03, col.to_rgba32() >> 8)
		q.call(land + i * 0.4, land + i * 0.4 + 0.06, 0.034, Color(0.95, 0.94, 0.9).lerp(Color(0.1, 0.09, 0.08), k).to_rgba32() >> 8)     # (its white riser)
	s = land + 3.6
	while s < TRENCH_L + 0.6:
		q.call(s, s + 0.5, 0.03, "hueco")
		s += 0.5
	pieces += 1
	# the chimneys: white, tapering, a cap of tile
	for c in [u * (TRENCH_L + 3.2) + v * 0.6, u * 6.0 + v * 4.6]:
		var cp: Vector2 = g0 + (c as Vector2)
		if MapData.room_at(spot(cp.x, cp.y)) < 0.8 or car_dist(spot(cp.x, cp.y)) < BACK + 0.8:
			continue
		var cg := ground(cp.x, cp.y)
		drum(Vector3(cp.x, cg - 0.2, cp.y), 0.45, 0.3, 1.7, WHITE, 10)
		drum(Vector3(cp.x, cg + 1.5, cp.y), 0.36, 0.36, 0.07, TILE, 10)
		solid(Vector3(cp.x, cg + 0.8, cp.y), Vector3(0.7, 1.7, 0.7))
		yard.append(spot(cp.x, cp.y))
