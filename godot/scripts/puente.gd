extends "res://scripts/obra.gd"
## The old bridge of the Calle del Arroyuelo Medio and the stretch of the old stream's bed it crosses, built by hand
## (the user, 15 November 2026: "reworkear el puente de arroyuelo medio"; referencias/puente_arroyuelo/, tools/puente/).
##
## As it stood until about 2010 (Street View of May 2009, the IGN's aerial photographs of 2006 and 2009, a film of
## 1984): from the Calle del Santo down to the corner of Matías Pérez the street was still the bed of the stream, a
## floor of concrete between two raised pavements of chequered tiles on walls of rubble; at its lower end a little
## bridge went from one pavement to the other -- a slab on a pier in the middle, a low parapet of brick each side with
## its top and its ends rounded -- and nothing wider than a dog got under it. Past it the pavement on the side of the
## even numbers came down a few steps; on the other side was the paved corner between the bed and Matías Pérez, with
## its tree.
##
## In the game the town hall wants it down ("a wide street for the cars"), and until the neighbours' signatures stop
## that, the works are waiting round it: an excavator with its arm over the parapet, another and a tipper truck parked
## in the bed, a skip, barriers and boards of danger (set_works). The morning after the signatures are handed in, with
## the player far away and not looking, all of that is gone.
##
## Frame: origin in the middle of the bridge, at the level of its deck and of the pavements beside it; +x across the
## bed (the way the deck runs) towards the houses of the even numbers, +z down the bed towards the crossroads.
## For the rest of the game it is what it was: p, u, across, hw, half, open, seg, top, spot(), kerb(), the
## demonstration's dressing (dress) and the council's tape until the town makes it its own (close_off).

const READY := true                             # (tools/bake_godot.py looks for this: with it, the houses of that row are set level with the pavement)
const AT := Vector2(-149.61, -261.23)           # its middle, on the map (the bake hands over the same: MapData.puente)
const ALONG := Vector2(0.443, 0.896)            # down the bed
const HW := 3.225                               # half the bed, from wall to wall
const WIDE := 2.6                               # the bridge, parapets and all (the real one was nearer 2 m: wider so that two can pass on it)
const PARAPET := 0.28                           # how thick its parapets are
const RAIL := 0.56                              # ...and how high over the deck
const SLAB := 0.2
const REST := 0.3                               # how far the slab goes on to each pavement
const ENDS := 0.35                              # the rounded ends of the parapets, beyond that
const RISE := 1.05                              # the deck over the bed
const FLAT_N := -14.6                           # from here to FLAT_S the pavements are level with the deck...
const FLAT_S := 3.6                             # (where the steps of the east pavement begin: they end at the jamb of the brick house's garage)
const NORTH: Array = [[-27.0, 0.55], [-40.0, 0.55]]     # ...and further up they follow the bed, this far over it
const EAST_OUT: Array = [[-36.5, 7.6], [-28.2, 7.0], [-20.6, 6.3], [-14.6, 5.9], [3.6, 5.5]]      # the back of the east pavement (a hand's breadth inside the houses)
const WEST_OUT := -4.9
const WORKS_SET := "res://assets/obra/obra.glb"  # the machines (tools/blender/obra.py)

const TILES := "
shader_type spatial;
render_mode cull_disabled;
varying vec3 at;
void vertex() {
	at = VERTEX;
}
void fragment() {
	vec2 g = at.xz / 0.4;
	vec2 cell = floor(g);
	vec2 f = fract(g);
	float joint = step(0.04, f.x) * step(0.04, f.y);
	float wear = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	vec3 tile = mix(vec3(0.83, 0.78, 0.68), vec3(0.56, 0.33, 0.31), mod(cell.x + cell.y, 2.0)) * (0.88 + 0.16 * wear);
	ALBEDO = mix(vec3(0.5, 0.47, 0.43), tile, joint);
	ROUGHNESS = 1.0;
}
"

var p: Vector2                  # its middle, on the street
var u: Vector2                  # along the street
var across: Vector2             # along the deck
var hw := HW                    # half the bed of the old stream (what the bridge crosses)
var half := 2.6                 # how far from its middle the game takes its ends to be (the pavement begins a little further out)
var open := 1.0                 # the side whose pavement the game uses (+1: the even numbers')
var seg                         # the stretch of street it stands on (closed to cars)
var top := 0.0                  # the deck's height in the world
var dressing: Node3D            # the demonstration's things (null when there is no demonstration)
var fence: Node3D               # the council's tape (null when it is not fenced off)
var works := false              # whether the demolition works are waiting round it
var auto := true                # whether it takes the works away by itself, the morning after the signatures
var _game
var _pav: Array = []            # Vector2(z, height from the deck's level): the pavements' profile along the bed
var _floor_decks: Array = []
var _works_node: Node3D
var _works_solids := Vector2i.ZERO
var _done_h := -1.0

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"brick":            # old brick, gone orange and grey
			m = Tex.mat("medieval_red_brick", Color(0.9, 0.86, 0.8))
		"sardinel":         # the rounded course on top of the parapets
			m = Tex.mat("medieval_red_brick@0.8", Color(0.84, 0.79, 0.73))
		"rubble":           # the walls that hold the pavements up
			m = Tex.mat("stone_wall")
		"hormigon":         # copings, steps, the slab
			m = Tex.mat("granular_concrete", Color(0.86, 0.84, 0.8), false)
		"losa":             # what is walked on, on the bridge
			m = Tex.mat("granular_concrete@1.4", Color(0.78, 0.75, 0.7), false)
		"piedra":
			m = Tex.mat("granular_concrete", Color(0.95, 0.9, 0.8), false)
		"tiling":
			var sh := Shader.new()
			sh.code = TILES
			var sm := ShaderMaterial.new()
			sm.shader = sh
			m = sm
		"soil":
			m = W._tmat(0x6f5d4a, "earth", 1.6)
		"leaf":
			m = W._tmat(0x4f8a48, "leaf", 1.1)
		"malla":            # the mesh of a site fence
			var wm := StandardMaterial3D.new()
			wm.albedo_color = Color(0.74, 0.77, 0.8, 0.32)
			wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			wm.cull_mode = BaseMaterial3D.CULL_DISABLED
			wm.roughness = 1.0
			m = wm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(game, world) -> void:
	_game = game
	W = world
	var data: Dictionary = MapData.puente if "puente" in MapData else {}
	p = Vector2(data["o"][0], data["o"][1]) if data.has("o") else AT
	u = Vector2(data["u"][0], data["u"][1]) if data.has("u") else ALONG
	across = Vector2(u.y, -u.x)                  # (this node's own +x)
	if data.has("top"):                          # (the bake has set the houses of the row to these levels)
		top = float(data["top"])
		for q in data["pav"]:
			_pav.append(Vector2(float(q[0]), float(q[1]) - top))
	else:
		top = MapData.height(p) + RISE
		for k in range(NORTH.size() - 1, -1, -1):
			_pav.append(Vector2(NORTH[k][0], MapData.height(p + u * float(NORTH[k][0])) + float(NORTH[k][1]) - top))
		_pav.append(Vector2(FLAT_N, 0.0))
		_pav.append(Vector2(FLAT_S, 0.0))
	level = top
	transform = Transform3D(Basis(Vector3(across.x, 0, across.y), Vector3.UP, Vector3(u.x, 0, u.y)), Vector3(p.x, top, p.y))
	game.add_child(self)
	# the stretch under it is closed to cars, and nothing drives up the bed to it from the Calle del Santo either
	seg = MapData.nearest_road(p, true)["seg"]
	MapData.block(seg)
	for s in MapData.segs:
		if s != seg and (s.na == seg.na or s.nb == seg.na) and (s.road["n"] as String) == (seg.road["n"] as String):
			MapData._blocked[s] = true
	_bed()
	_pavements()
	_corner()
	_bridge()
	_garage()
	home()
	_commit()
	MapData.decks = _decks + _floor_decks + MapData.decks
	_build_works()
	if OS.get_cmdline_user_args().has("--puente-limpio"):      # (to look at it, or photograph it, without the works: they stay away)
		auto = false
		set_works(false)
	else:
		set_works(true)

# ---------------- the profile ----------------
## how high the pavements are at a place along the bed, from the level of the deck
func pav(z: float) -> float:
	if z <= _pav[0].x:                           # (beyond its last mark it goes on as it was going)
		var a0: Vector2 = _pav[0]
		var a1: Vector2 = _pav[1]
		return a0.y + (z - a0.x) * (a1.y - a0.y) / (a1.x - a0.x)
	for k in range(_pav.size() - 1):
		var a: Vector2 = _pav[k]
		var b: Vector2 = _pav[k + 1]
		if z <= b.x:
			return lerpf(a.y, b.y, (z - a.x) / (b.x - a.x))
	return _pav[_pav.size() - 1].y

func _east_out(z: float) -> float:
	for k in range(EAST_OUT.size() - 1):
		if z <= float(EAST_OUT[k + 1][0]):
			return lerpf(float(EAST_OUT[k][1]), float(EAST_OUT[k + 1][1]), clampf((z - float(EAST_OUT[k][0])) / (float(EAST_OUT[k + 1][0]) - float(EAST_OUT[k][0])), 0.0, 1.0))
	return float(EAST_OUT[EAST_OUT.size() - 1][1])

## a spot given in the bridge's own terms (metres across the street, metres along it), as a place in the town
## (obra.gd's own spot() does this; kept by name for the rest of the game)

## how far out from the middle of the bridge the game puts people on the pavement
func kerb() -> float:
	return hw + 0.75

# ---------------- the bed and its pavements ----------------
## The bed of the old stream: concrete from wall to wall, from the Calle del Santo to past the bridge.
func _bed() -> void:
	var v := PackedVector3Array()
	for q in [spot(-hw, -44.0), spot(hw, -44.0), spot(hw, 11.6), spot(-2.3, 8.0), spot(-hw, 7.2)]:      # (below the bridge: as far as the asphalt of Matías Pérez)
		v.append(Vector3(q.x, 0.0, q.y))
	W._flat(v, PackedInt32Array([0, 1, 2, 0, 2, 3, 0, 3, 4]), 0xb7b0a1, 0.012, null, "asphalt", 5.0)

## a wall of rubble from a to b on the floor plan, its top at ya and yb, faced on the side `out`, under its coping
func _wall(a: Vector2, b: Vector2, ya: float, yb: float, out: Vector2, coping := true) -> void:
	var ga: float = minf(ground(a.x + out.x * 0.3, a.y + out.y * 0.3), ground(a.x, a.y)) - 0.5
	var gb: float = minf(ground(b.x + out.x * 0.3, b.y + out.y * 0.3), ground(b.x, b.y)) - 0.5
	pieces += 1
	quad(Vector3(a.x, ga, a.y), Vector3(b.x, gb, b.y), Vector3(b.x, yb, b.y), Vector3(a.x, ya, a.y), "rubble", Vector3(out.x, 0, out.y))
	if coping:
		var inn: Vector2 = -out * 0.1
		bar(Vector3(a.x + inn.x, ya - 0.03, a.y + inn.y), Vector3(b.x + inn.x, yb - 0.03, b.y + inn.y), 0.34, 0.1, "hormigon")
	yard.append(spot(a.x, a.y))

## a stretch of raised pavement between two places along the bed: its floor (sloping with the bed where the bed
## slopes), what is solid under it, and where people stand on it
func _pavement(z0: float, z1: float, in0: float, out0: float, in1: float, out1: float) -> void:
	var y0: float = pav(z0)
	var y1: float = pav(z1)
	var a := Vector3(in0, y0, z0)
	var b := Vector3(out0, y0, z0)
	var c := Vector3(out1, y1, z1)
	var d := Vector3(in1, y1, z1)
	pieces += 1
	quad(a, b, c, d, "tiling", Vector3.UP)
	var low: float = minf(minf(ground(in0, z0), ground(in1, z1)), minf(ground(out0, z0), ground(out1, z1))) - 0.8
	_hull([a, b, c, d, Vector3(a.x, low, a.z), Vector3(b.x, low, b.z), Vector3(c.x, low, c.z), Vector3(d.x, low, d.z)])
	var deck := _poly_deck(PackedVector2Array([Vector2(in0, z0), Vector2(out0, z0), Vector2(out1, z1), Vector2(in1, z1)]), level + (y0 + y1) / 2.0)
	if absf(y1 - y0) > 0.001:
		deck["grad"] = u * ((y1 - y0) / (z1 - z0))        # (how much it rises to the metre, on the map)
	_floor_decks.append(deck)

## A flight of steps coming down from `edge` (the middle of its top edge, on the floor plan, at height y) towards
## `down`: `n` risers to drop `drop`, `wide` across.
func _flight(edge: Vector2, y: float, down: Vector2, wide: float, drop: float, n: int, tread := 0.3) -> void:
	down = down.normalized()
	var rise: float = drop / n
	var keep := _xf
	_xf = Transform3D(Basis(Vector3(down.y, 0, -down.x), Vector3.UP, Vector3(down.x, 0, down.y)), Vector3(edge.x, y, edge.y))
	for k in range(1, n):
		box(-wide / 2.0, -drop - 0.4, (k - 1) * tread, wide, drop + 0.4 - k * rise, tread, "hormigon")
	_xf = keep
	var run: float = tread * (n - 1)
	var foot: Vector2 = edge + down * (run + 0.3)
	var corners: Array = []
	for q in [edge + Vector2(down.y, -down.x) * wide / 2.0, edge - Vector2(down.y, -down.x) * wide / 2.0, foot - Vector2(down.y, -down.x) * wide / 2.0, foot + Vector2(down.y, -down.x) * wide / 2.0]:
		corners.append(q)
	_hull([Vector3(corners[0].x, y, corners[0].y), Vector3(corners[1].x, y, corners[1].y), Vector3(corners[2].x, y - drop - 0.04, corners[2].y), Vector3(corners[3].x, y - drop - 0.04, corners[3].y),
		Vector3(corners[0].x, y - drop - 0.4, corners[0].y), Vector3(corners[1].x, y - drop - 0.4, corners[1].y), Vector3(corners[2].x, y - drop - 0.4, corners[2].y), Vector3(corners[3].x, y - drop - 0.4, corners[3].y)])
	var mid: Vector2 = edge + down * run / 2.0
	var up_axis: Vector2 = (spot(0.0, 0.0) - spot(down.x, down.y)).normalized()
	_decks.append({"o": spot(mid.x, mid.y), "ax": up_axis, "half": run / 2.0 + 0.25, "wide": wide / 2.0, "top": level + y, "ramp": run, "low": level + y - drop})

func _pavements() -> void:
	# --- the side of the even numbers (east): from the corner of the block near the Calle del Santo to the steps past the bridge ---
	var marks: Array = [-36.5, -27.0, FLAT_N, FLAT_S]
	for k in range(marks.size() - 1):
		var z0: float = marks[k]
		var z1: float = marks[k + 1]
		_pavement(z0, z1, hw, _east_out(z0), hw, _east_out(z1))
		_wall(Vector2(hw, z0), Vector2(hw, z1), pav(z0), pav(z1), Vector2(-1, 0))
	var drop_n: float = pav(-36.5) - ground(hw + 2.0, -37.6)
	_flight(Vector2((hw + _east_out(-36.5)) / 2.0, -36.5), pav(-36.5), Vector2(0, -1), _east_out(-36.5) - hw, drop_n, maxi(2, int(round(drop_n / 0.18))))
	var drop_s: float = -ground(hw + 0.8, FLAT_S + 1.7)
	var n_s: int = maxi(3, int(round(drop_s / 0.18)))
	_flight(Vector2((hw + 5.0) / 2.0, FLAT_S), 0.0, Vector2(0, 1), 5.0 - hw, drop_s, n_s)
	_wall(Vector2(hw, FLAT_S), Vector2(hw, FLAT_S + 0.3 * (n_s - 1)), 0.0, -drop_s + 0.1, Vector2(-1, 0))
	# --- the other side (west): from the point by the Calle del Santo, with its tree, to the paved corner ---
	var tip := -40.0                             # (the real point ran on a few metres more: in the game the Calle del Santo passes there)
	_pavement(tip, -38.5, -hw, -4.6, -hw, -6.2)
	_pavement(-38.5, -27.0, -hw, WEST_OUT, -hw, WEST_OUT)
	_pavement(-27.0, FLAT_N, -hw, WEST_OUT, -hw, WEST_OUT)
	_pavement(FLAT_N, -0.6, -hw, WEST_OUT, -hw, WEST_OUT)
	for q in [[tip, -38.5], [-38.5, -27.0], [-27.0, FLAT_N], [FLAT_N, -0.6]]:
		_wall(Vector2(-hw, q[0]), Vector2(-hw, q[1]), pav(q[0]), pav(q[1]), Vector2(1, 0))
	_wall(Vector2(-4.6, tip), Vector2(-hw, tip), pav(tip), pav(tip), Vector2(0, -1))
	_wall(Vector2(-6.2, -38.5), Vector2(-4.6, tip), pav(-38.5), pav(tip), Vector2(-0.685, -0.73))
	var drop_t: float = pav(-39.3) - ground(-hw + 0.8, -39.3)      # a few steps down into the bed, at its mouth
	_flight(Vector2(-hw, -39.3), pav(-39.3), Vector2(1, 0), 1.2, drop_t, maxi(2, int(round(drop_t / 0.18))))
	_tree(Vector2(-4.6, -39.0), pav(-39.0), 2.1, 0.8)

## The paved corner between the bed and the Calle de Matías Pérez, level with the bridge: a wall of rubble round it,
## a few steps down to that street beside the low house, its tree.
func _corner() -> void:
	var pts := PackedVector2Array([Vector2(-6.0, -0.6), Vector2(-hw, -0.6), Vector2(-hw, 6.5), Vector2(-3.55, 6.5), Vector2(-6.0, 0.8)])
	flat(pts, 0.0, "tiling")
	var low: float = ground(-hw, 6.5) - 0.8
	_prism([pts[0], pts[1], pts[2], pts[3], pts[4]], low, 0.0)
	_floor_decks.append(_poly_deck(pts, level))
	_wall(Vector2(-hw, 1.3), Vector2(-hw, 6.5), 0.0, 0.0, Vector2(1, 0))
	_wall(Vector2(-hw, 6.5), Vector2(-3.55, 6.5), 0.0, 0.0, Vector2(0, 1))
	_wall(Vector2(-3.55, 6.5), Vector2(-6.0, 0.8), 0.0, 0.0, Vector2(-0.919, 0.395))
	var drop: float = -ground(-7.0, 0.1)
	_flight(Vector2(-6.0, 0.1), 0.0, Vector2(-1, 0), 1.4, drop, maxi(3, int(round(drop / 0.2))), 0.28)
	_tree(Vector2(-4.4, 2.5), 0.0, 2.4, 1.5)

## a little tree in its square of earth
func _tree(at: Vector2, y: float, trunk: float, crown: float) -> void:
	flat(PackedVector2Array([at + Vector2(-0.45, -0.45), at + Vector2(0.45, -0.45), at + Vector2(0.45, 0.45), at + Vector2(-0.45, 0.45)]), y + 0.012, "soil")
	drum(Vector3(at.x, y, at.y), 0.1, 0.07, trunk, 0x6b5a45, 8)
	ball(Vector3(at.x, y + trunk + crown * 0.55, at.y), crown, "leaf", 0.85, 10, 6)
	solid(Vector3(at.x, y + 1.0, at.y), Vector3(0.24, 2.0, 0.24))
	yard.append(spot(at.x, at.y))

# ---------------- the bridge ----------------
func _bridge() -> void:
	var reach: float = hw + REST                 # half the slab
	var bed: float = ground(0.0, 0.0)            # the bed under it
	# the slab, and what is walked on between the parapets
	box(-reach, -SLAB, -WIDE / 2.0, 2.0 * reach, SLAB - 0.004, WIDE, "hormigon")
	flat(PackedVector2Array([Vector2(-reach, -WIDE / 2.0 + PARAPET), Vector2(reach, -WIDE / 2.0 + PARAPET), Vector2(reach, WIDE / 2.0 - PARAPET), Vector2(-reach, WIDE / 2.0 - PARAPET)]), 0.012, "losa")
	_prism([Vector2(-reach, -WIDE / 2.0), Vector2(reach, -WIDE / 2.0), Vector2(reach, WIDE / 2.0), Vector2(-reach, WIDE / 2.0)], -SLAB, 0.0)
	_floor_decks.append(_poly_deck(PackedVector2Array([Vector2(-reach - 0.2, -WIDE / 2.0 + PARAPET), Vector2(reach + 0.2, -WIDE / 2.0 + PARAPET), Vector2(reach + 0.2, WIDE / 2.0 - PARAPET), Vector2(-reach - 0.2, WIDE / 2.0 - PARAPET)]), level))
	# its two parapets of brick: rounded on top, and their ends coming down to the pavement in a quarter of a circle
	var body: float = RAIL - 0.1
	var outline := PackedVector2Array([Vector2(-reach - ENDS, 0.0), Vector2(reach + ENDS, 0.0)])
	for i in range(1, 7):
		var a: float = PI / 2.0 * i / 6.0
		outline.append(Vector2(reach + ENDS * cos(a), body * sin(a)))
	for i in range(6, 0, -1):
		var a: float = PI / 2.0 * i / 6.0
		outline.append(Vector2(-reach - ENDS * cos(a), body * sin(a)))
	for side in [-1.0, 1.0]:
		var z_out: float = side * WIDE / 2.0
		var z_in: float = side * (WIDE / 2.0 - PARAPET)
		pieces += 1
		_sheet(outline, z_out, Vector3(0, 0, side), "brick")
		_sheet(outline, z_in, Vector3(0, 0, -side), "brick")
		for i in range(6):                       # the rounded ends, from the pavement up
			var a0: float = PI / 2.0 * i / 6.0
			var a1: float = PI / 2.0 * (i + 1) / 6.0
			for e in [-1.0, 1.0]:
				var q0 := Vector2(e * (reach + ENDS * cos(a0)), body * sin(a0))
				var q1 := Vector2(e * (reach + ENDS * cos(a1)), body * sin(a1))
				quad(Vector3(q0.x, q0.y, z_out), Vector3(q0.x, q0.y, z_in), Vector3(q1.x, q1.y, z_in), Vector3(q1.x, q1.y, z_out), "sardinel", Vector3(e * cos((a0 + a1) / 2.0), sin((a0 + a1) / 2.0), 0))
		var zc: float = (z_out + z_in) / 2.0     # the course of brick on edge along the top, rounded
		for i in range(6):
			var a0: float = PI * i / 6.0
			var a1: float = PI * (i + 1) / 6.0
			quad(Vector3(-reach, body + 0.1 * sin(a0), zc + PARAPET / 2.0 * cos(a0)), Vector3(reach, body + 0.1 * sin(a0), zc + PARAPET / 2.0 * cos(a0)),
				Vector3(reach, body + 0.1 * sin(a1), zc + PARAPET / 2.0 * cos(a1)), Vector3(-reach, body + 0.1 * sin(a1), zc + PARAPET / 2.0 * cos(a1)), "sardinel", Vector3(0, sin((a0 + a1) / 2.0), cos((a0 + a1) / 2.0)))
		# (what stops a car, and keeps whoever is on top, on top: solid from under the bed to the top of the parapet)
		solid(Vector3(0, (RAIL + bed - 0.4) / 2.0, zc), Vector3(2.0 * (reach + ENDS), RAIL - bed + 0.4, PARAPET))
		# the year, cut in a stone in the middle of each face
		box(-0.45, 0.1, z_out if side > 0.0 else z_out - 0.035, 0.9, 0.32, 0.035, 0xd9cfbc)
		var year := Label3D.new()
		year.text = "1911"
		year.font_size = 56
		year.pixel_size = 0.004
		year.modulate = Color("5a4632")
		year.outline_size = 0
		year.position = Vector3(0, 0.26, z_out + side * 0.04)
		year.rotation.y = 0.0 if side > 0.0 else PI
		add_child(year)
	# the pier in the middle: brick on a block of stone half sunk in the concrete of the bed
	cbox(Vector3(0, bed + 0.02, 0), Vector3(1.05, 0.5, WIDE + 0.25), "piedra")
	box(-0.31, bed + 0.27, -WIDE / 2.0 + 0.2, 0.62, -SLAB - bed - 0.27, WIDE - 0.4, "brick")
	# where the slab rests on each wall, in the dark under it
	for e in [-1.0, 1.0]:
		box(e * hw - (0.03 if e > 0.0 else 0.0), -SLAB - 0.5, -WIDE / 2.0 + 0.3, 0.03, 0.5, WIDE - 0.6, 0x24211e)
	yard.append(spot(0.0, 0.0))

## a flat piece with this outline (x, y) in the plane z, facing n
func _sheet(pts: PackedVector2Array, z: float, n: Vector3, key) -> void:
	var idx := Geometry2D.triangulate_polygon(pts)
	for t in range(0, idx.size(), 3):
		var a := pts[idx[t]]
		var b := pts[idx[t + 1]]
		var c := pts[idx[t + 2]]
		tri(Vector3(a.x, a.y, z), Vector3(b.x, b.y, z), Vector3(c.x, c.y, z), key, n)

## The garage of the brick house beside the bridge: the house stands on the raised pavement, its garage opens on the
## street below it. The house leaves the hole; the door, from the street up, is built here.
func _garage() -> void:
	for h in MapData.houses:
		if String(h["id"]) != "arroyuelo_34":
			continue
		var o := Vector2(h["o"][0], h["o"][1])
		var hu := Vector2(h["u"][0], h["u"][1])
		var along: float = float(h["len"]) * 0.75
		var inv := transform.affine_inverse()
		var qa: Vector3 = inv * Vector3((o + hu * (along - 1.4)).x, 0, (o + hu * (along - 1.4)).y)
		var qb: Vector3 = inv * Vector3((o + hu * (along + 1.4)).x, 0, (o + hu * (along + 1.4)).y)
		var a := Vector2(qa.x, qa.z)
		var b := Vector2(qb.x, qb.z)
		if a.y > b.y:                            # (seen from the bed: its left end is the one up the street)
			var t := a
			a = b
			b = t
		var floor_y: float = float(h["base"]) - level
		var foot: float = minf(ground(a.x - 0.4, a.y), ground(b.x - 0.4, b.y)) - 0.05
		var w: float = face(a, b)
		var tall: float = floor_y + 1.9 - foot
		box(0.0, foot, 0.0, w, tall, 0.13, 0xe9e6de)
		for i in range(1, 5):
			box(0.0, foot + tall * i / 5.0, 0.13, w, 0.03, 0.012, 0xbdb9b0)
		for i in range(4):                       # the row of little panes along its top
			box(w * (0.08 + i * 0.22), foot + tall * 0.86, 0.13, w * 0.17, tall * 0.08, 0.014, 0x9fb3bd)
		box(-0.12, foot, 0.0, 0.12, tall + 0.12, 0.16, 0x8a8480)
		box(w, foot, 0.0, 0.12, tall + 0.12, 0.16, 0x8a8480)
		box(-0.12, foot + tall, 0.0, w + 0.24, 0.12, 0.16, 0x8a8480)
		home()
		return

# ---------------- the council's tape ----------------
## Until the town has made it its own (the player spends Puntos Cívicos on it: game.gd, _unlock_bridge) the council
## has it fenced off: nobody walks over it. A barrier of red and white tape and a notice at each end, and -- unseen --
## a wall round the deck.
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
	var body_f := StaticBody3D.new()
	body_f.collision_layer = 8                   # (as a tree is: people stop at it, and the camera does not take it for a house)
	body_f.collision_mask = 0
	fence.add_child(body_f)
	var reach: float = hw + REST
	for wall in [[Vector3(reach + 0.1, 1.2, 0.0), Vector3(0.2, 2.6, WIDE + 0.6)], [Vector3(-reach - 0.1, 1.2, 0.0), Vector3(0.2, 2.6, WIDE + 0.6)],
			[Vector3(0.0, 1.2, WIDE / 2.0 + 0.2), Vector3(reach * 2.0, 2.6, 0.2)], [Vector3(0.0, 1.2, -WIDE / 2.0 - 0.2), Vector3(reach * 2.0, 2.6, 0.2)]]:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = wall[1]
		cs.shape = bs
		cs.position = wall[0]
		body_f.add_child(cs)
	var inside: float = WIDE / 2.0 - PARAPET
	for end in [-1.0, 1.0]:                      # what is seen of it: two posts, two runs of tape, a notice
		var x: float = end * (reach - 0.05)
		for sz in [-1.0, 1.0]:
			_part(0xd9d4c8, Vector3(x, 0.55, sz * (inside - 0.06)), Vector3(0.08, 1.1, 0.08), fence)
		for row in range(2):
			for k in range(8):
				_part(0xc8102e if k % 2 == 0 else 0xf4f1e8, Vector3(x, 0.55 + row * 0.4, -inside + 0.12 + (k + 0.5) * (2.0 * inside - 0.24) / 8.0), Vector3(0.02, 0.09, (2.0 * inside - 0.24) / 8.0), fence)
		_part(0xf4f1e8, Vector3(x + end * 0.03, 0.75, 0.0), Vector3(0.03, 0.42, 1.25), fence)
		var notice := Label3D.new()
		notice.text = "AYUNTAMIENTO\nPROHIBIDO EL PASO"
		notice.font_size = 44
		notice.pixel_size = 0.0034
		notice.modulate = Parts.col(0xc8102e)
		notice.outline_size = 0
		notice.position = Vector3(x + end * 0.05, 0.75, 0.0)
		notice.rotation.y = end * PI / 2.0
		fence.add_child(notice)

func _part(material, pos: Vector3, size: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var mi := Parts.part("box", 0xffffff, pos, size)
	mi.material_override = material if material is Material else Parts.mat(material)
	(parent if parent != null else self).add_child(mi)
	return mi

# ---------------- the demonstration ----------------
## puts up (or takes down) what the demonstration has brought: the banner across the bed, the table with the sheets
func dress(on: bool) -> void:
	if on and OS.get_cmdline_user_args().has("--puente-limpio"):      # (to photograph the bridge bare)
		return
	if not on:
		if dressing != null:
			dressing.queue_free()
			dressing = null
		return
	if dressing != null:
		return
	dressing = Node3D.new()
	add_child(dressing)
	var reach := hw - 0.15
	var bed: float = ground(0.0, -6.5)
	for sx in [-1.0, 1.0]:                        # the banner, strung between two poles up the bed from the bridge
		dressing.add_child(Parts.part("cyl", 0x6b4a34, Vector3(sx * reach, bed + 2.5, -6.5), Vector3(0.06, 5.0, 0.06)))
	_part(0xf4f1e8, Vector3(0, bed + 4.45, -6.5), Vector3(reach * 2.0, 0.95, 0.03), dressing)
	for facing in [1.0, -1.0]:
		var text := Label3D.new()
		text.text = Loc.t("bridge_banner")
		text.font_size = 100
		text.pixel_size = 0.0052
		text.modulate = Color("b23a3a")
		text.outline_size = 0
		text.position = Vector3(0, bed + 4.45, -6.5 + 0.03 * facing)
		text.rotation.y = 0.0 if facing > 0.0 else PI
		dressing.add_child(text)
	var tx := open * (hw + 0.78)                  # the table with the signature sheets and the collection tin, on the pavement
	_part(0xd8d2c2, Vector3(tx, 0.74, -3.6), Vector3(0.7, 0.05, 1.5), dressing)
	for q in [Vector2(-0.27, -0.6), Vector2(0.27, -0.6), Vector2(-0.27, 0.6), Vector2(0.27, 0.6)]:
		_part(0x8d99ae, Vector3(tx + q.x, 0.37, -3.6 + q.y), Vector3(0.04, 0.74, 0.04), dressing)
	_part(0xfaf8f2, Vector3(tx, 0.775, -3.4), Vector3(0.3, 0.01, 0.42), dressing)
	_part(0xfaf8f2, Vector3(tx + 0.08, 0.78, -4.0), Vector3(0.3, 0.01, 0.42), dressing)
	dressing.add_child(Parts.part("cyl", 0xd23b3b, Vector3(tx - 0.12, 0.86, -3.05), Vector3(0.09, 0.18, 0.09)))
	var bunting := [0xb23a3a, 0xf2c230, 0x2f8f5b, 0x3b5fa8]      # a string of little flags along each parapet, outside
	var span: float = hw + REST - 0.3
	for side in [-1.0, 1.0]:
		for k in range(11):
			var flag := _part(bunting[k % 4], Vector3(-span + k * span * 2.0 / 10.0, RAIL - 0.3, side * (WIDE / 2.0 + 0.015)), Vector3(0.24, 0.3, 0.012), dressing)
			flag.rotation.z = 0.12 if k % 2 == 0 else -0.12

## a placard for one of the demonstrators to hold: a stick and a board with something painted on it
static func placard(text: String, hex: int) -> Node3D:
	var g := Node3D.new()
	g.position = Vector3(0.52, 0.0, 0.12)
	g.rotation.z = -0.08
	g.add_child(Parts.part("cyl", 0x8a6a48, Vector3(0, 1.55, 0), Vector3(0.035, 2.2, 0.035)))
	g.add_child(Parts.part("box", hex, Vector3(0, 2.75, 0), Vector3(1.15, 0.72, 0.03)))
	for facing in [1.0, -1.0]:
		var l := Label3D.new()
		l.text = text
		l.font_size = 30
		l.pixel_size = 0.0045
		l.modulate = Color("26221e")
		l.outline_size = 0
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.width = 240.0
		l.line_spacing = -3.0
		l.position = Vector3(0, 2.75, 0.02 * facing)
		l.rotation.y = 0.0 if facing > 0.0 else PI
		g.add_child(l)
	return g

# ---------------- the demolition works ----------------
## Everything the works have brought, built once into a node of its own with its own solids: set_works shows it or
## takes it away.
func _build_works() -> void:
	_works_node = Node3D.new()
	add_child(_works_node)
	_tools = {}
	var first: int = _solids().get_child_count()
	var kit: Node = (load(WORKS_SET) as PackedScene).instantiate() if ResourceLoader.exists(WORKS_SET) else null
	# below the bridge: the excavator that is to do it, its arm already over the parapet, shut in by the town hall's barriers
	_machine(kit, "excavadora_b", Vector2(1.0, 6.7), PI / 2.0, [[Vector3(0.2, 1.5, 0.0), Vector3(3.9, 3.0, 2.7)]])
	var south: Array = [Vector2(-3.05, 6.75), Vector2(-0.7, 8.35), Vector2(1.6, 9.9), Vector2(3.9, 11.45)]
	for k in range(south.size() - 1):
		_barrier(south[k], south[k + 1])
	for q in [[Vector2(3.9, 11.3), Vector2(3.9, 8.9)], [Vector2(3.9, 8.75), Vector2(3.9, 6.35)], [Vector2(3.9, 6.2), Vector2(3.9, 5.2)]]:      # (a way is left along the houses, from the foot of the steps)
		_barrier(q[0], q[1])
	_board(Vector2(-0.2, 8.85), Vector2(-0.56, 0.83), "PELIGRO\nDEMOLICIÓN", "PROHIBIDO EL PASO", 1.5, 1.05)
	_board(Vector2(4.05, 7.5), Vector2(1.0, 0.0), "OBRAS", "NO PASAR", 0.9, 0.7)
	for q in [Vector2(-3.4, 7.3), Vector2(4.3, 11.9), Vector2(3.55, 5.5), Vector2(1.9, 10.6)]:
		_cone(kit, q)
	# up the bed, behind a site fence: the other excavator, the tipper truck, a skip, planks
	_site_fence(Vector2(-hw + 0.1, -15.6), Vector2(hw - 0.1, -15.6))
	_board(Vector2(0.0, -15.45), Vector2(0.0, 1.0), "PELIGRO\nDEMOLICIÓN", "PROHIBIDO EL PASO\nA TODA PERSONA AJENA A LA OBRA", 1.7, 1.2, true)
	_machine(kit, "camion", Vector2(1.45, -23.0), 0.0, [[Vector3(0.0, 1.6, 0.0), Vector3(3.1, 3.2, 7.0)]])
	_machine(kit, "contenedor", Vector2(-1.95, -19.4), 0.0, [[Vector3(0.0, 0.66, 0.0), Vector3(1.3, 1.32, 3.0)]])
	_machine(kit, "excavadora_a", Vector2(-1.3, -31.5), 0.0, [[Vector3(0.0, 1.5, -0.4), Vector3(2.6, 3.0, 4.2)], [Vector3(0.0, 1.0, 3.6), Vector3(1.0, 2.0, 3.4)]])
	_machine(kit, "tablones", Vector2(2.1, -31.6), 0.0, [[Vector3(0.0, 0.4, 0.0), Vector3(1.5, 0.8, 4.7)]])
	_machine(kit, "bidon", Vector2(2.55, -17.0), 0.0, [[Vector3(0.0, 0.6, 0.0), Vector3(0.9, 1.2, 0.9)]])
	_machine(kit, "bidon", Vector2(-2.6, -22.6), 0.6, [[Vector3(0.0, 0.6, 0.0), Vector3(0.9, 1.2, 0.9)]])
	_site_fence(Vector2(-hw + 0.1, -37.4), Vector2(hw - 0.1, -37.4))
	_board(Vector2(0.0, -37.55), Vector2(0.0, -1.0), "PELIGRO\nOBRAS", "PROHIBIDO EL PASO\nA TODA PERSONA AJENA A LA OBRA", 1.7, 1.2, true)
	for q in [Vector2(-2.6, -38.4), Vector2(2.6, -38.4), Vector2(-2.7, -14.8), Vector2(2.7, -14.8)]:
		_cone(kit, q)
	if kit != null:
		kit.free()
	home()
	for key in _tools:
		var mi := MeshInstance3D.new()
		mi.mesh = (_tools[key] as SurfaceTool).commit()
		mi.material_override = _material(key)
		_works_node.add_child(mi)
	_tools = {}
	_works_solids = Vector2i(first, _solids().get_child_count())
	works = true

## the works round it, or the bridge as the neighbours want it: what is seen and what stops you
func set_works(on: bool) -> void:
	works = on
	if _works_node == null:
		return
	_works_node.visible = on
	for i in range(_works_solids.x, _works_solids.y):
		(body.get_child(i) as CollisionShape3D).set_deferred("disabled", not on)

## one of the machines of the set, standing on the ground at a place of the frame, turned `turn` (its front, +z, towards
## the crossroads when 0); `blocks`: what of it stops you (middle and size, in its own terms)
func _machine(kit: Node, piece: String, at: Vector2, turn: float, blocks: Array) -> void:
	var src: Node3D = kit.get_node_or_null(piece) if kit != null else null
	if src == null:
		return
	var t := Transform3D(Basis(Vector3.UP, turn), Vector3(at.x, ground(at.x, at.y) + 0.01, at.y))
	var n: Node3D = src.duplicate()
	n.transform = t
	_works_node.add_child(n)
	pieces += 1
	for q in blocks:
		solid(t * (q[0] as Vector3), q[1], turn)

func _cone(kit: Node, at: Vector2) -> void:
	_machine(kit, "cono", at, 0.0, [])

## one of the town hall's yellow steel barriers, from a to b
func _barrier(a: Vector2, b: Vector2) -> void:
	var col := 0xe8b820
	var pa := Vector3(a.x, ground(a.x, a.y), a.y)
	var pb := Vector3(b.x, ground(b.x, b.y), b.y)
	var d: Vector2 = (b - a).normalized()
	var across_b := Vector3(-d.y, 0, d.x)
	bar(pa + Vector3(0, 1.05, 0), pb + Vector3(0, 1.05, 0), 0.045, 0.045, col)
	bar(pa + Vector3(0, 0.2, 0), pb + Vector3(0, 0.2, 0), 0.04, 0.04, col)
	var n: int = maxi(3, int(a.distance_to(b) / 0.19))
	for i in range(n + 1):
		var q: Vector3 = pa.lerp(pb, float(i) / n)
		var thick: float = 0.045 if (i == 0 or i == n) else 0.02
		cbox(q + Vector3(0, 0.625, 0), Vector3(thick, 0.85, thick), col)
	for f in [0.1, 0.9]:
		var q: Vector3 = pa.lerp(pb, f)
		bar(q - across_b * 0.28 + Vector3(0, 0.03, 0), q + across_b * 0.28 + Vector3(0, 0.03, 0), 0.05, 0.05, col)
		cbox(q + Vector3(0, 0.12, 0), Vector3(0.04, 0.2, 0.04), col)
	var mid: Vector3 = (pa + pb) / 2.0
	var turn: float = atan2(-d.y, d.x)
	tbox(Transform3D(Basis(Vector3.UP, turn).scaled_local(Vector3(0.62, 0.26, 0.035)), mid + Vector3(0, 0.74, 0)), 0xf4f1e8)
	for s in [-1.0, 1.0]:
		_words("AYUNTAMIENTO", mid + Vector3(0, 0.74, 0) + across_b * 0.022 * s, atan2(across_b.x * s, across_b.z * s), 20, 0x2a2a2c, 0.0032)
	solid(mid + Vector3(0, 0.55, 0), Vector3(a.distance_to(b), 1.1, 0.14), turn)
	yard.append(spot(mid.x, mid.z))

## a run of site fence from a to b: panels of mesh in a frame of tube, each on two blocks of concrete
func _site_fence(a: Vector2, b: Vector2) -> void:
	var count: int = maxi(1, int(round(a.distance_to(b) / 3.2)))
	var d: Vector2 = (b - a).normalized()
	var turn: float = atan2(-d.y, d.x)
	for k in range(count):
		var q0: Vector2 = a.lerp(b, float(k) / count) + d * 0.04
		var q1: Vector2 = a.lerp(b, float(k + 1) / count) - d * 0.04
		var g0 := Vector3(q0.x, ground(q0.x, q0.y), q0.y)
		var g1 := Vector3(q1.x, ground(q1.x, q1.y), q1.y)
		for h in [0.18, 2.0]:
			bar(g0 + Vector3(0, h, 0), g1 + Vector3(0, h, 0), 0.04, 0.04, 0x9aa0a6)
		for g in [g0, g1]:
			cbox(g + Vector3(0, 1.0, 0), Vector3(0.045, 2.0, 0.045), 0x9aa0a6)
			tbox(Transform3D(Basis(Vector3.UP, turn).scaled_local(Vector3(0.24, 0.14, 0.66)), g + Vector3(0, 0.07, 0)), 0x8f8a80)
		quad(g0 + Vector3(0, 0.18, 0), g1 + Vector3(0, 0.18, 0), g1 + Vector3(0, 2.0, 0), g0 + Vector3(0, 2.0, 0), "malla", Vector3(-d.y, 0, d.x))
		for i in range(1, 4):                    # (a few wires of the mesh, so that it shows from afar)
			bar(g0.lerp(g1, i / 4.0) + Vector3(0, 0.18, 0), g0.lerp(g1, i / 4.0) + Vector3(0, 2.0, 0), 0.012, 0.012, 0x9aa0a6)
		var mid: Vector3 = (g0 + g1) / 2.0
		solid(mid + Vector3(0, 1.0, 0), Vector3(q0.distance_to(q1), 2.0, 0.14), turn)
		yard.append(spot(mid.x, mid.z))

## a board on two posts at a place, looking towards `to`: a red band with its big word, the rest under it
func _board(at: Vector2, to: Vector2, big: String, small: String, w: float, h: float, hung := false) -> void:
	to = to.normalized()
	var turn: float = atan2(to.x, to.y)
	var g: float = ground(at.x, at.y)
	var y0: float = g + (0.55 if hung else 1.0)
	var t := Transform3D(Basis(Vector3.UP, turn), Vector3(at.x, y0, at.y))
	if not hung:
		for s in [-1.0, 1.0]:
			tbox(t * Transform3D(Basis().scaled(Vector3(0.05, 1.0 + h, 0.05)), Vector3(s * (w / 2.0 - 0.06), (h - 1.0) / 2.0, -0.04)), 0x8a8f96)
	tbox(t * Transform3D(Basis().scaled(Vector3(w, h, 0.03)), Vector3(0, h / 2.0, 0)), 0xf4f1e8)
	tbox(t * Transform3D(Basis().scaled(Vector3(w, h * 0.5, 0.034)), Vector3(0, h * 0.75, 0)), 0xc8102e)
	_fit(big, t * Vector3(0, h * 0.75, 0.02), turn, 0xfdfcf8, w * 0.9, h * 0.42)
	_fit(small, t * Vector3(0, h * 0.3, 0.02), turn, 0x1c1c1e, w * 0.9, h * 0.3)
	_fit("AYUNTAMIENTO", t * Vector3(0, h * 0.07, 0.022), turn, 0x1c1c1e, w * 0.5, h * 0.07)
	yard.append(spot(at.x, at.y))

## words as big as fit in a space `w` wide and `h` high
func _fit(s: String, at: Vector3, turn: float, hex: int, w: float, h: float) -> void:
	var lines: PackedStringArray = s.split("\n")
	var longest := 1
	for l in lines:
		longest = maxi(longest, l.length())
	var tall: float = minf(h / (lines.size() * 1.22), w / (longest * 0.6))     # (the height of a line of capitals)
	_words(s, at, turn, 64, hex, tall / 64.0 / 0.95)

func _words(s: String, at: Vector3, turn: float, px: int, hex: int, pixel: float) -> void:
	var l := Label3D.new()
	l.text = s
	l.font_size = px
	l.pixel_size = pixel
	l.modulate = Parts.col(hex)
	l.outline_size = 0
	l.line_spacing = -4.0
	l.position = at
	l.rotation.y = turn
	_works_node.add_child(l)

# ---------------- when the works go ----------------
## The works are there from the start. Once the signatures have been handed in, they leave the first morning after
## it, as soon as the player is far away and not looking (the user, 15 November 2026). A game begun again has them back.
func _process(_dt: float) -> void:
	if not auto or _game == null or _works_node == null:
		return
	var g = _game
	if g.si <= g._idx("alberto_back"):           # (before the signatures are in -- a new game, or a jump back to an earlier step -- they are there)
		_done_h = -1.0
		g.stats.erase("obra_fuera")
		g.stats.erase("obra_h")
		if not works:
			set_works(true)
		return
	if g.stats.has("obra_fuera"):
		if works:
			set_works(false)
		return
	if not works:
		return
	if _done_h < 0.0:
		_done_h = float(g.stats.get("obra_h", g._now_h()))
		g.stats["obra_h"] = _done_h
	var dawn: float = floor(_done_h / 24.0) * 24.0 + float(g.DAWN_AT)
	if dawn <= _done_h:
		dawn += 24.0
	if g._now_h() >= dawn and g.player.p.distance_to(p) > 140.0 and not g.sees(p, 400.0):
		set_works(false)
		g.stats["obra_fuera"] = true
