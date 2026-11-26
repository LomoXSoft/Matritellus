extends "res://scripts/obra.gd"
## The old bullring ("Antigua Plaza de Toros"), between the Calle de la Prensa, Bienvenida, San Agustín and Vista
## Alegre, built by hand in TWO states (the user, 15 November 2026: it was restored between 2009 and 2013, and
## restoring it is to be something the player does):
##   the ruin        as the game begins: buttresses and wall of bare earth and rubble, the lime gone in patches, their
##                   tops eaten away; the stands a slope of earth; weeds in the ring; a low peeling shed against it; the
##                   lot in front fenced off with wire (a gate left open).
##   restored        a plain white drum with its seventy buttresses, a wooden door on the south-east that stands open,
##                   stands of concrete, the ring of sand inside its red barrier; young trees in rows in front.
## set_restored(true / false) shows one or the other (and its own solids). From Catastro, the IGN's aerial photographs
## of 2006 to now and Street View of 2009, 2013 and 2024 (referencias/plaza_toros/, tools/toros/).
##
## Its frame: the middle of the ring; the map's own axes (+x east, +z south); y = 0 the ground of the lot. Angles are
## counted from the east towards the south (90 degrees: south, the Calle Vista Alegre).

const READY := true                                # (tools/bake_godot.py looks for this)
const O := Vector2(476.3, 548.5)                   # the middle of the ring, on the map
const N := 70                                      # buttresses in the whole round (one every 2.44 m)
const R := 27.2                                    # the outer face of the wall
const THICK := 0.6
const H := 5.35
const R_STAND := 20.6                              # where the stands begin
const R_RING := 19.0                               # the barrier round the sand
const DOOR := 52.0                                 # where the door is (degrees)
const PENS := 150.0                                # ...and the block of the bull pens, across the stands
const WEST_A := Vector2(-19.6, -28.0)              # the old wall along the Calle de la Prensa
const WEST_B := Vector2(-42.5, 27.4)                # ...as far as the corner of Vista Alegre (six metres in from the middle of each street)
const SOUTH_B := Vector2(18.5, 65.8)               # the corner of Vista Alegre and San Agustín (the fence's)
const EAST_N := Vector2(47.1, -14.5)               # where the fence of San Agustín ends, at the houses' yards
# The restored stands, walked on (the user, 25 November 2026: "Se puede visitar la plaza de toros? Estaria bien poder
# visitarla por dentro. Te adjunto referencias de como se vería": referencias/plaza_toros/usuario_02_ruedo.png and
# usuario_03_galeria.png). From those two pictures: the two white rings on the sand, the barrier of red boards between
# white posts, flights of steps up the stands, a box with a tiled roof on red posts and its red railing.
const FRONT := 1.6                                 # the stands' front wall
const TIER := Vector2(1.2, 0.6)                    # each of its five steps: how deep, how high
const TOP := 4.0                                   # the last of them (FRONT + 4 * TIER.y)...
const R_TOP := 25.4                                # ...which begins here
const STAIRS := [12, 45, 62]                       # the stretches that are a flight of steps from the alley up to the last tier
const FLIGHT := 20                                 # the steps of each
const PENS_TOP := 3.3                              # the pens' flat roof: the floor of the box
const RED := 0x8c1f1a
const PAINT := 0xf2efe6

var restored := false
var _state := {}                                   # "viejo" / "nuevo" -> {node, first, last (its solids among the body's)}
var _stand_decks: Array = []                       # the restored stands' floors: in MapData.decks only while it is restored

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"tapial":           # rammed earth and rubble with what is left of its lime
			m = Tex.mat("plaster_stone_wall_02@3.0", Color(0.93, 0.85, 0.74), false)
		"cal_vieja":        # old lime-wash, lumpy and flaking
			m = _glow(Tex.mat("plastered_wall_04@2.6", Color(1.0, 0.98, 0.94), false), 0.12)
		"tierra":
			m = W._tmat(0xb9a482, "earth", 2.4)
		"albero":           # the yellow sand of a bullring
			m = W._tmat(0xd9b062, "earth", 2.0)
		"hormigon":
			m = Tex.mat("granular_concrete", Color(0.95, 0.94, 0.9), false)
		"leaf":
			m = W._tmat(0x4f8a48, "leaf", 1.1)
		"mata":             # weeds gone dry
			m = W._tmat(0x8b9450, "leaf", 0.9)
		"malla":            # wire netting
			var wm := StandardMaterial3D.new()
			wm.albedo_color = Color(0.72, 0.75, 0.78, 0.3)
			wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			wm.cull_mode = BaseMaterial3D.CULL_DISABLED
			wm.roughness = 1.0
			m = wm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	level = MapData.height(O)
	transform = Transform3D(Basis(), Vector3(O.x, level, O.y))
	W.add_child(self)
	_lot()
	home()
	_commit()
	for st in ["viejo", "nuevo"]:
		var node := Node3D.new()
		add_child(node)
		_tools = {}
		var first: int = _solids().get_child_count()
		_ring(st == "nuevo")
		if st == "nuevo":
			_trees()
		else:
			_wasteland()
		home()
		for key in _tools:
			var mi := MeshInstance3D.new()
			mi.mesh = (_tools[key] as SurfaceTool).commit()
			mi.material_override = _material(key)
			node.add_child(mi)
		_tools = {}
		_state[st] = {"node": node, "first": first, "last": _solids().get_child_count()}
	_tell_map()
	set_restored(OS.get_cmdline_user_args().has("--toros-restaurada"))

## the ruin, or the bullring as it was left by the works: what is seen and what stops you
func set_restored(on: bool) -> void:
	restored = on
	for st in _state:
		var mine: bool = (st == "nuevo") == on
		(_state[st]["node"] as Node3D).visible = mine
		for i in range(int(_state[st]["first"]), int(_state[st]["last"])):
			(body.get_child(i) as CollisionShape3D).set_deferred("disabled", not mine)
	var has: bool = MapData.decks.any(func(d): return d.has("toros"))
	if on and not has:                               # (the stands are floors only when there are stands)
		MapData.decks = _stand_decks + MapData.decks
	elif not on and has:
		MapData.decks = MapData.decks.filter(func(d): return not d.has("toros"))

## a floor of the stands for MapData.decks: its outline in the ring's frame, its height over the lot; `grad` (how much
## it rises to the metre, as a vector) makes it a slope, and then y is its height at `at`
func _deck(pts: Array, y: float, at = null, grad = null) -> Dictionary:
	var poly := PackedVector2Array()
	var mid := Vector2.ZERO
	for q in pts:
		poly.append(spot(q.x, q.y))
		mid += q / float(pts.size())
	var o: Vector2 = spot(at.x, at.y) if at != null else spot(mid.x, mid.y)
	var r2 := 0.0
	for q in poly:
		r2 = maxf(r2, o.distance_squared_to(q))
	var d := {"o": o, "poly": poly, "r2": r2 + 0.5, "top": level + y, "toros": true}
	if grad != null:
		d["grad"] = grad                             # (the ring's axes are the map's)
	return d

## the floors of the restored stands: the flights of steps first (they lie before the floors they join), then each
## tier in lengths of six stretches, then the pens' roof
func _note_floors(door_k: int, pens_k: int) -> void:
	var step := 360.0 / N
	for k in STAIRS:
		var am: float = (k + 0.5) * step
		_stand_decks.append(_deck([_p(k * step, R_STAND), _p((k + 1) * step, R_STAND), _p((k + 1) * step, R_TOP), _p(k * step, R_TOP)],
			TOP / 2.0, _p(am, (R_STAND + R_TOP) / 2.0), _p(am, 1.0) * (TOP / (R_TOP - R_STAND))))
	for j in range(5):
		var r0: float = R_STAND + TIER.x * j
		var r1: float = r0 + TIER.x if j < 4 else R - THICK
		var run: Array = []
		for k in range(N + 1):
			var tier: bool = k < N and k != door_k and k != pens_k and k != pens_k + 1 and (j == 4 or not (k in STAIRS))
			if tier:
				run.append(k)
			if (not tier or run.size() == 6) and not run.is_empty():
				var pts: Array = []
				for q in range(int(run[0]), int(run[-1]) + 2):
					pts.append(_p(q * step, r0))
				for q in range(int(run[-1]) + 1, int(run[0]) - 1, -1):
					pts.append(_p(q * step, r1))
				_stand_decks.append(_deck(pts, FRONT + TIER.y * j))
				run = []
	var b0: float = pens_k * step
	_stand_decks.append(_deck([_p(b0, R_STAND - 0.2), _p(b0 + step, R_STAND - 0.2), _p(b0 + 2.0 * step, R_STAND - 0.2),
		_p(b0 + 2.0 * step, R - THICK), _p(b0 + step, R - THICK), _p(b0, R - THICK)], PENS_TOP))

# ---------------- helpers ----------------
func _p(deg: float, r: float) -> Vector2:
	return Vector2(cos(deg_to_rad(deg)), sin(deg_to_rad(deg))) * r

func _up(q: Vector2, y: float) -> Vector3:
	return Vector3(q.x, y, q.y)

## a number between 0 and 1 that is always the same for the same k (the ruin is eaten away the same every time)
func _roll(k: int, salt := 0) -> float:
	return fposmod(sin(k * 12.9898 + salt * 78.233) * 43758.5453, 1.0)

func _in_arc(deg: float, from: float, to: float) -> bool:
	return fposmod(deg - from, 360.0) <= fposmod(to - from, 360.0)

func _circle(r: float, n := 48) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in range(n):
		pts.append(Vector2(cos(TAU * k / n), sin(TAU * k / n)) * r)
	return pts

func _lot_outline() -> PackedVector2Array:
	return PackedVector2Array([WEST_A, WEST_B, SOUTH_B, EAST_N, _p(-30.0, R + 0.4), _p(-90.0, R + 1.3), _p(-140.0, R + 0.4)])

# ---------------- what both states share ----------------
func _lot() -> void:
	flat(_lot_outline(), 0.02, "tierra")
	# the old wall along the Calle de la Prensa: lime-washed, its top eaten away (it has not been touched to this day)
	var ln := face(WEST_A, WEST_B)
	var x := 0.0
	var k := 0
	while x < ln - 0.1:
		var w: float = minf(2.6, ln - x)
		var h: float = 2.55 + 0.6 * _roll(k, 3)
		box(x, -0.3, -0.5, w, h + 0.3, 0.5, "cal_vieja")
		if _roll(k, 5) > 0.45:                       # (where the lime has gone from the top: the earth of the wall)
			box(x, h, -0.47, w, 0.14 + 0.25 * _roll(k, 7), 0.44, "tapial")
		x += w
		k += 1
	var mid: Vector2 = (WEST_A + WEST_B) / 2.0
	var d: Vector2 = (WEST_B - WEST_A).normalized()
	solid(Vector3(mid.x + d.y * 0.25, 1.5, mid.y - d.x * 0.25), Vector3(ln, 3.0, 0.5), atan2(-d.y, d.x))
	home()
	# the rough wall that closes the lot towards the houses' yards, north-east
	var ne: Vector2 = _p(-30.0, R + 0.4)
	ln = face(ne, EAST_N)
	box(0.0, -0.3, -0.45, ln, 3.5, 0.45, "cal_vieja")
	home()
	solid(_up((ne + EAST_N) / 2.0, 1.6), Vector3(ln, 3.2, 0.5), atan2(-(EAST_N - ne).y, (EAST_N - ne).x))
	for q in [WEST_A, WEST_B, EAST_N, ne]:
		yard.append(spot(q.x, q.y))
	# the electricity tower at the corner of the two streets: four legs of iron lattice
	var foot := _up(SOUTH_B + Vector2(-3.0, -5.0), 0.0)
	var tall := 10.5
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			bar(foot + Vector3(sx * 0.75, 0, sz * 0.75), foot + Vector3(sx * 0.22, tall, sz * 0.22), 0.07, 0.07, 0x6a6e72)
	for j in range(7):
		var y0: float = tall * j / 7.0
		var y1: float = tall * (j + 1) / 7.0
		var r0: float = lerpf(0.75, 0.22, j / 7.0)
		var r1: float = lerpf(0.75, 0.22, (j + 1) / 7.0)
		for s in range(4):
			var a := Vector3([1, 1, -1, -1][s] * r0, y0, [1, -1, -1, 1][s] * r0)
			var b := Vector3([1, -1, -1, 1][s] * r1, y1, [-1, -1, 1, 1][s] * r1)
			bar(foot + a, foot + b, 0.035, 0.035, 0x6a6e72)
	for s in [-1.0, 1.0]:
		bar(foot + Vector3(-1.5, tall - 0.6, s * 0.2), foot + Vector3(1.5, tall - 0.6, s * 0.2), 0.05, 0.05, 0x6a6e72)
	solid(foot + Vector3(0, 2.0, 0), Vector3(1.6, 4.0, 1.6))
	yard.append(spot(foot.x, foot.z))

## What stands here, for whoever asks the map how much room there is and for the little map.
func _tell_map() -> void:
	var rings: Array = [_circle(R + 0.6, 24), PackedVector2Array([WEST_A, WEST_B, WEST_B + Vector2(0.5, 0.2), WEST_A + Vector2(0.5, 0.2)])]
	for ring in rings:
		var pts := PackedVector2Array()
		for q in ring:
			pts.append(spot(q.x, q.y))
		MapData.outlines.append(pts)
		if not MapData._wall_grid.is_empty():
			for i in range(pts.size()):
				var a: Vector2 = pts[i]
				var b: Vector2 = pts[(i + 1) % pts.size()]
				MapData._grid_add(MapData._wall_grid, a.min(b), a.max(b), [a, b])

# ---------------- the ring ----------------
## `fine`: restored (white, whole, the door open, stands and barrier); otherwise the ruin
func _ring(fine: bool) -> void:
	var step := 360.0 / N
	var door_k: int = int(floor(DOOR / step))
	var pens_k: int = int(floor(PENS / step))
	for k in range(N):
		var a0: float = k * step
		var a1: float = (k + 1) * step
		var am: float = (a0 + a1) / 2.0
		var old: bool = not fine or _in_arc(am, 165.0, 225.0)            # (the west arc was never restored)
		var skin = "white"
		if old:
			skin = "cal_vieja" if _roll(k, 30) < 0.25 else "tapial"
		var top: float = H if not old else H - 0.15 - 1.1 * _roll(k) * _roll(k, 2)
		var o0: Vector2 = _p(a0, R)
		var o1: Vector2 = _p(a1, R)
		var i0: Vector2 = _p(a0, R - THICK)
		var i1: Vector2 = _p(a1, R - THICK)
		# the wall: its two faces and its top (the door's stretch has a hole in it)
		if k == door_k:
			var ln := face(o1, o0)
			masonry(0.0, ln, -0.3, top, [Rect2(ln / 2.0 - 0.95, -0.3, 1.9, 2.95)], [], skin, skin)
			if fine:
				for s in [-1.0, 1.0]:                # (its two leaves, folded back inside)
					tbox(Transform3D(Basis(Vector3.UP, s * 1.35).scaled_local(Vector3(0.95, 2.6, 0.06)), Vector3(ln / 2.0 + s * 1.2, 1.3, -THICK - 0.42)), 0x6b4a30)
				box(ln / 2.0 - 1.05, 2.65, -0.02, 2.1, 0.22, 0.08, 0x8a5a3c)
			else:                                    # (boarded up)
				box(ln / 2.0 - 0.95, 0.0, -0.2, 1.9, 2.65, 0.08, 0x7a6a55)
				for j in range(3):
					box(ln / 2.0 - 1.05, 0.5 + j * 0.85, -0.12, 2.1, 0.16, 0.05, 0x5c4f3f)
			home()
			_plain(i0, i0.lerp(i1, 0.1), 0.0, top, skin)
			_plain(i0.lerp(i1, 0.9), i1, 0.0, top, skin)
			_plain(i0.lerp(i1, 0.1), i0.lerp(i1, 0.9), 2.65, top, skin)
		else:
			_plain(o1, o0, -0.3, top, skin)
			_plain(i0, i1, 0.0, top, skin)
		flat(PackedVector2Array([o0, o1, i1, i0]), top, skin)
		# its buttress: none on the north, where the houses' yards come up against the wall
		if not _in_arc(a0, 232.0, 338.0):
			var out: float = 1.4 if not old else 1.1 + 0.6 * _roll(k, 4)
			var h: float = top - 0.02 if not old else top - 1.5 * _roll(k, 6) * _roll(k, 8)
			if old:                                  # (what is left of the lime below, the earth of it showing above)
				var lip: float = 0.2 + 0.3 * _roll(k, 9)
				var cut: float = h * (0.72 + 0.26 * _roll(k, 10))
				var part: float = lerpf(out, lip, cut / h)
				_buttress(a0, out, part, -0.3, cut, "cal_vieja")
				_buttress(a0, part, lip, cut, h, "tapial")
			else:
				_buttress(a0, out, 0.4, -0.3, h, skin)
			if old and _roll(k, 11) > 0.55:          # (a tuft growing out of its top)
				ball(_up(_p(a0, R + 0.25), h + 0.12), 0.28 + 0.2 * _roll(k, 12), "mata", 0.7, 6, 4)
		# what stops you: the wall (and the door, shut, in the ruin)
		if k != door_k or not fine:
			var mid: Vector2 = _p(am, R - THICK / 2.0 + 0.2)
			solid(_up(mid, top / 2.0), Vector3(1.4, top, 2.6), -deg_to_rad(am))
		# the stands
		if k == door_k and fine:
			for a in [a0, a1]:                       # (the way in between two walls)
				var side: Array = [_p(a, R_STAND), _p(a, R - THICK)]
				_plain(side[0], side[1], 0.0, 4.0, "white")
				_plain(side[1], side[0], 0.0, 4.0, "white")
				solid(_up(_p(a, (R_STAND + R) / 2.0), 2.9), Vector3(R - R_STAND, 5.8, 0.3), -deg_to_rad(a))      # (as tall as stops who walks the last tier)
				for y in [TOP + 0.45, TOP + 0.9]:    # (and a red rail along the top of each)
					bar(_up(_p(a, R_STAND + 0.1), y), _up(_p(a, R - THICK - 0.1), y), 0.07, 0.07, RED)
				for i in range(5):
					drum(_up(_p(a, R_STAND + 0.1 + i * (R - THICK - R_STAND - 0.2) / 4.0), TOP), 0.04, 0.04, 0.9, RED, 6)
		elif k == pens_k or k == pens_k + 1:
			_pens_block(a0, a1, fine, k == pens_k)
		elif fine and k in STAIRS:
			_stairs(a0, a1)
		elif fine:
			_tiers(a0, a1)
		else:
			_slope(a0, a1, k)
		if not fine:
			solid(_up(_p(am, R_STAND + 0.3), 0.8), Vector3(0.6, 1.6, 2.0), -deg_to_rad(am))
		elif k != door_k and not (k in STAIRS):      # (tall enough to stop who stands on the first tier, or on the pens' roof, too)
			solid(_up(_p(am, R_STAND + 0.12), 2.6), Vector3(0.3, 5.2, 2.0), -deg_to_rad(am))
	# the floor of the ring, and what is in it
	if fine:
		flat(_circle(R_STAND, 56), 0.035, "albero")
		_barrier(door_k * step + step / 2.0)
		_circles()
		_palco(pens_k * step, (pens_k + 2) * step)
		_note_floors(door_k, pens_k)
	else:
		flat(_circle(R_STAND, 56), 0.035, "tierra")
		for j in range(46):                          # (weeds, thick in the middle of it)
			var q: Vector2 = _p(_roll(j, 21) * 360.0, R_STAND * sqrt(_roll(j, 22)) * 0.95)
			ball(_up(q, 0.12), 0.35 + 0.5 * _roll(j, 23), "mata" if j % 3 else "leaf", 0.5, 6, 4)
	yard.append(spot(0.0, 0.0))

## a buttress at this angle, or a length of one: a pier that comes `out` at the height y0 and `lip` at y1, with a
## sloping face
func _buttress(deg: float, out: float, lip: float, y0: float, y1: float, key) -> void:
	var e: Vector2 = _p(deg, 1.0)
	var t := Vector2(-e.y, e.x) * 0.36
	var b0: Vector2 = e * (R - 0.05)
	var f0: Vector2 = e * (R + out)
	var f1: Vector2 = e * (R + lip)
	pieces += 1
	quad(_up(f0 - t, y0), _up(f0 + t, y0), _up(f1 + t, y1), _up(f1 - t, y1), key, Vector3(e.x, 0.25, e.y).normalized())
	quad(_up(b0 + t, y0), _up(f0 + t, y0), _up(f1 + t, y1), _up(b0 + t, y1), key, Vector3(t.x, 0, t.y).normalized())
	quad(_up(b0 - t, y0), _up(f0 - t, y0), _up(f1 - t, y1), _up(b0 - t, y1), key, Vector3(-t.x, 0, -t.y).normalized())
	quad(_up(b0 - t, y1), _up(b0 + t, y1), _up(f1 + t, y1), _up(f1 - t, y1), key, Vector3.UP)

## the stands of one stretch, restored: a front wall and five steps of concrete up to the foot of the parapet
func _tiers(a0: float, a1: float) -> void:
	_plain(_p(a0, R_STAND), _p(a1, R_STAND), 0.0, 1.6, "white")
	for j in range(5):
		var r0: float = R_STAND + 1.2 * j
		var r1: float = r0 + 1.2 if j < 4 else R - THICK
		var y: float = 1.6 + 0.6 * j
		flat(PackedVector2Array([_p(a0, r0), _p(a1, r0), _p(a1, r1), _p(a0, r1)]), y, "hormigon")
		if j > 0:
			_plain(_p(a0, r0), _p(a1, r0), y - 0.6, y, "hormigon")

## a stretch of the restored stands that is a flight of steps: from the alley, through the front wall, up to the last
## tier, between two stepped walls with a red handrail
func _stairs(a0: float, a1: float) -> void:
	var going: float = (R_TOP - R_STAND) / FLIGHT
	var rise: float = TOP / FLIGHT
	for i in range(FLIGHT):
		var r0: float = R_STAND + going * i
		flat(PackedVector2Array([_p(a0, r0), _p(a1, r0), _p(a1, r0 + going), _p(a0, r0 + going)]), rise * (i + 1), "hormigon")
		_plain(_p(a0, r0), _p(a1, r0), rise * i, rise * (i + 1), PAINT)
	flat(PackedVector2Array([_p(a0, R_TOP), _p(a1, R_TOP), _p(a1, R - THICK), _p(a0, R - THICK)]), TOP, "hormigon")
	for a in [a0, a1]:
		for j in range(4):                           # (as high as the tier beside it or as the steps, whichever is the higher)
			var r0: float = R_STAND + TIER.x * j
			var top: float = maxf(FRONT + TIER.y * j, TOP * TIER.x * (j + 1) / (R_TOP - R_STAND)) + 0.14
			_plain(_p(a, r0), _p(a, r0 + TIER.x), 0.0, top, "white")
			_plain(_p(a, r0 + TIER.x), _p(a, r0), 0.0, top, "white")
		bar(_up(_p(a, R_STAND + 0.1), 1.05), _up(_p(a, R_TOP - 0.1), TOP + 0.95), 0.07, 0.07, RED)
		for i in range(5):
			var f: float = i / 4.0
			drum(_up(_p(a, lerpf(R_STAND + 0.1, R_TOP - 0.1, f)), TOP * f), 0.04, 0.04, lerpf(1.05, 0.95, f), RED, 6)
		solid(_up(_p(a, (R_STAND + R_TOP) / 2.0), 2.9), Vector3(R_TOP - R_STAND, 5.8, 0.2), -deg_to_rad(a))

## the two white rings painted on the sand
func _circles() -> void:
	for r in [13.2, 10.4]:
		for i in range(72):
			var b0: float = 5.0 * i
			flat(PackedVector2Array([_p(b0, r), _p(b0 + 5.0, r), _p(b0 + 5.0, r + 0.18), _p(b0, r + 0.18)]), 0.05, PAINT)

## The box over the bull pens: on their flat roof, a railing and three posts of red wood, a lean-to roof of tiles from
## them up to the drum's wall, raised to carry it (the one thing of all this that is seen from the street).
func _palco(a0: float, a2: float) -> void:
	var am: float = (a0 + a2) / 2.0
	var keep := _xf
	_xf = Transform3D(Basis(Vector3.UP, PI / 2.0 - deg_to_rad(am)), _up(_p(am, R_STAND - 0.2), 0.0))       # (+z: out from the ring)
	var deep: float = R - THICK - (R_STAND - 0.2)
	var fy := PENS_TOP
	for x in [-1.7, -0.06, 1.58]:
		box(x, fy, 0.1, 0.12, 2.2, 0.12, RED)
	box(-1.8, fy + 2.2, 0.06, 3.6, 0.16, 0.2, RED)
	box(-1.7, fy + 0.88, 0.12, 3.4, 0.07, 0.08, RED)
	box(-1.7, fy + 0.12, 0.13, 3.4, 0.05, 0.06, RED)
	for i in range(16):
		box(-1.5 + i * 0.2, fy + 0.17, 0.14, 0.04, 0.71, 0.04, RED)
	box(-2.5, H - 0.05, deep - 0.05, 5.0, 1.55, THICK + 0.1, "white")
	var low := fy + 2.4
	var high := H + 1.6
	var eave: Array = [Vector3(-2.2, low, -0.35), Vector3(2.2, low, -0.35), Vector3(2.55, high, deep + 0.35), Vector3(-2.55, high, deep + 0.35)]
	roof(eave)
	var under := Vector3(0, 0.05, 0)
	quad(eave[0] - under, eave[1] - under, eave[2] - under, eave[3] - under, 0x7a5a40, Vector3(0, -1, 0))
	for x in [-1.64, 0.0, 1.64]:                     # (its rafters)
		bar(Vector3(x, low - 0.12, -0.3), Vector3(x * 1.15, high - 0.12, deep), 0.09, 0.12, RED)
	_xf = keep

## the same stretch in the ruin: a slope of earth behind what is left of the front wall
func _slope(a0: float, a1: float, k: int) -> void:
	var y0: float = 0.7 + 0.7 * _roll(k, 14)
	var y1: float = 3.2 + 0.8 * _roll(k, 15)
	_plain(_p(a0, R_STAND), _p(a1, R_STAND), 0.0, y0, "tapial")
	pieces += 1
	quad(_up(_p(a0, R_STAND), y0), _up(_p(a1, R_STAND), y0), _up(_p(a1, R - THICK), y1), _up(_p(a0, R - THICK), y1), "tierra", Vector3.UP)
	if _roll(k, 16) > 0.6:
		ball(_up(_p((a0 + a1) / 2.0, lerpf(R_STAND, R, 0.3 + 0.5 * _roll(k, 17))), lerpf(y0, y1, 0.5) + 0.1), 0.3 + 0.3 * _roll(k, 18), "mata", 0.6, 6, 4)

## the block of the bull pens across the stands (two stretches wide): a flat roof, a gate on to the ring
func _pens_block(a0: float, a1: float, fine: bool, first: bool) -> void:
	var skin = "white" if fine else "tapial"
	var top := 3.3
	flat(PackedVector2Array([_p(a0, R_STAND - 0.2), _p(a1, R_STAND - 0.2), _p(a1, R - THICK), _p(a0, R - THICK)]), top, "hormigon" if fine else "tierra")
	_plain(_p(a0, R_STAND - 0.2), _p(a1, R_STAND - 0.2), 0.0, top, skin)
	var a: float = a0 if first else a1
	if first:
		_plain(_p(a, R - THICK), _p(a, R_STAND - 0.2), 0.0, top, skin)
	else:
		_plain(_p(a, R_STAND - 0.2), _p(a, R - THICK), 0.0, top, skin)
	if fine:                                         # (the ends of the two tiers that come up higher than its roof)
		for j in [3, 4]:
			var r0: float = R_STAND + TIER.x * j
			var r1: float = r0 + TIER.x if j < 4 else R - THICK
			_plain(_p(a, r0), _p(a, r1), top, FRONT + TIER.y * j, "white")
			_plain(_p(a, r1), _p(a, r0), top, FRONT + TIER.y * j, "white")
	if first:                                        # (the gate, in the middle of the two)
		var g0: Vector2 = _p(a1 - 3.0, R_STAND - 0.26)
		var g1: Vector2 = _p(a1 + 3.0, R_STAND - 0.26)
		_plain(g0, g1, 0.0, 2.3, 0x8c1f1a if fine else 0x5c4f3f)

## the red barrier round the sand, with its four ways through and the little wall in front of each
func _barrier(door_deg: float) -> void:
	var red := 0x8c1f1a
	var n := 60
	var gaps: Array = [door_deg, door_deg + 90.0, door_deg + 180.0, door_deg + 270.0]
	for k in range(n):
		var a0: float = 360.0 * k / n
		var a1: float = 360.0 * (k + 1) / n
		var am: float = (a0 + a1) / 2.0
		var open := false
		for g in gaps:
			open = open or absf(angle_difference(deg_to_rad(am), deg_to_rad(g))) < deg_to_rad(3.1)
		if open:
			continue
		bar(_up(_p(a0, R_RING), 0.72), _up(_p(a1, R_RING), 0.72), 0.09, 1.45, red)
		bar(_up(_p(a0, R_RING), 1.47), _up(_p(a1, R_RING), 1.47), 0.13, 0.06, 0xf2efe6)
		bar(_up(_p(a0, R_RING + 0.07), 0.35), _up(_p(a1, R_RING + 0.07), 0.35), 0.05, 0.1, 0x6e1713)       # (the step the men vault from)
		for y in [0.5, 0.98]:                        # (the joints of its boards, on the side of the sand)
			bar(_up(_p(a0, R_RING - 0.045), y), _up(_p(a1, R_RING - 0.045), y), 0.02, 0.03, 0x6e1713)
		for a in [a0, a1]:                           # (and a white post at each end of it)
			drum(_up(_p(a, R_RING - 0.06), 0.0), 0.055, 0.055, 1.5, PAINT, 6)
		solid(_up(_p(am, R_RING), 0.75), Vector3(0.2, 1.5, 2.05), -deg_to_rad(am))
	for g in gaps:                                   # the "burladeros"
		var c: Vector2 = _p(g, R_RING - 0.75)
		var t := Vector2(-sin(deg_to_rad(g)), cos(deg_to_rad(g)))
		bar(_up(c - t * 1.0, 0.72), _up(c + t * 1.0, 0.72), 0.08, 1.45, red)
		bar(_up(c - t * 1.0, 1.47), _up(c + t * 1.0, 1.47), 0.12, 0.06, 0xf2efe6)
		solid(_up(c, 0.75), Vector3(0.2, 1.5, 2.0), -deg_to_rad(g))

# ---------------- in front of it ----------------
## restored: young trees in rows on the levelled ground, each with its ring of soil
func _trees() -> void:
	var along := (SOUTH_B - WEST_B).normalized()
	var across := Vector2(along.y, -along.x)             # (towards the ring)
	var lot := _lot_outline()
	for row in range(2):
		for j in range(8):
			var q: Vector2 = WEST_B + along * (8.0 + j * 8.4 + row * 3.0) + across * (6.0 + row * 10.0)
			if q.length() < R + 5.0 or not Geometry2D.is_point_in_polygon(q, lot) or q.distance_to(SOUTH_B) < 9.0:
				continue
			flat(PackedVector2Array([q + Vector2(-0.7, -0.7), q + Vector2(0.7, -0.7), q + Vector2(0.7, 0.7), q + Vector2(-0.7, 0.7)]), 0.04, 0x8a7a62)
			drum(_up(q, 0.0), 0.05, 0.04, 1.9, 0x6b5442, 6)
			var s: float = 0.8 + 0.4 * _roll(row * 9 + j, 31)
			ball(_up(q, 1.9 + 0.6 * s), 0.7 * s, "leaf", 1.25, 8, 5)
			solid(_up(q, 1.1), Vector3(0.3, 2.2, 0.3))
			yard.append(spot(q.x, q.y))

## the ruin: weeds all over the lot, the peeling shed against the ring, the wire fence along the two streets
func _wasteland() -> void:
	var lot := _lot_outline()
	for j in range(26):                              # (patches of grass over the bare earth)
		var c0 := Vector2(lerpf(-40.0, 44.0, _roll(j, 51)), lerpf(-10.0, 66.0, _roll(j, 52)))
		if c0.length() < R + 5.0 or not Geometry2D.is_point_in_polygon(c0, lot):
			continue
		var patch := PackedVector2Array()
		var rr: float = 2.5 + 4.0 * _roll(j, 53)
		for i in range(9):
			var a: float = TAU * i / 9.0
			var q0: Vector2 = c0 + Vector2(cos(a), sin(a) * 0.7) * rr * (0.75 + 0.35 * _roll(j * 9 + i, 54))
			patch.append(q0 if Geometry2D.is_point_in_polygon(q0, lot) and q0.length() > R + 1.6 else c0.lerp(q0, 0.35))
		flat(patch, 0.03 + 0.002 * (j % 4), "mata")
	for j in range(120):
		var q := Vector2(lerpf(-44.0, 46.0, _roll(j, 41)), lerpf(-14.0, 70.0, _roll(j, 42)))
		if q.length() < R + 2.2 or not Geometry2D.is_point_in_polygon(q, lot):
			continue
		ball(_up(q, 0.1), 0.3 + 0.55 * _roll(j, 43), "mata" if j % 4 else "leaf", 0.45, 6, 4)
	# the shed, against the ring on the side of the Calle Vista Alegre
	var c: Vector2 = _p(121.0, R + 4.6)              # (south-south-west of the ring, where the photographs of 2006 and 2009 have it)
	var turn: float = -deg_to_rad(121.0) + PI / 2.0
	var keep := _xf
	_xf = Transform3D(Basis(Vector3.UP, turn), _up(c, 0.0))
	box(-5.0, -0.2, -2.6, 10.0, 3.1, 5.2, "cal_vieja")
	box(-5.15, 2.9, -2.75, 10.3, 0.14, 5.5, 0x9a6a4c)
	box(-0.6, 0.0, 2.6, 1.2, 2.0, 0.05, 0x5c4f3f)
	box(2.2, 1.2, 2.6, 0.7, 0.6, 0.05, 0x2f2a26)
	_xf = keep
	solid(_up(c, 1.5), Vector3(10.0, 3.0, 5.2), turn)
	yard.append(spot(c.x, c.y))
	# the fence: posts with their props, wire netting; the gate on Vista Alegre left open
	for line in [[WEST_B, SOUTH_B, 0.42, 0.5], [SOUTH_B, EAST_N, -1.0, -1.0]]:
		var a: Vector2 = line[0]
		var b: Vector2 = line[1]
		var ln: float = a.distance_to(b)
		var d: Vector2 = (b - a) / ln
		var posts: int = int(ln / 2.6)
		for j in range(posts + 1):
			var f: float = j / float(posts)
			var q: Vector2 = a.lerp(b, f)
			drum(_up(q, 0.0), 0.03, 0.03, 2.0, 0x8a8f94, 6)
			if j % 4 == 0:
				bar(_up(q, 1.9), _up(q + d * 0.9, 0.0), 0.03, 0.03, 0x8a8f94)
			if j == posts:
				break
			var f1: float = (j + 1) / float(posts)
			if f >= float(line[2]) - 0.001 and f1 <= float(line[3]) + 0.001:        # (the gate: open)
				continue
			var q1: Vector2 = a.lerp(b, f1)
			pieces += 1
			quad(_up(q, 0.05), _up(q1, 0.05), _up(q1, 1.95), _up(q, 1.95), "malla", Vector3(-d.y, 0, d.x))
			bar(_up(q, 1.95), _up(q1, 1.95), 0.02, 0.02, 0x8a8f94)
			var m: Vector2 = (q + q1) / 2.0
			solid(_up(m, 1.0), Vector3(q.distance_to(q1), 2.0, 0.12), atan2(-d.y, d.x))
		yard.append(spot(a.x, a.y))
