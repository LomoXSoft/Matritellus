extends "res://scripts/obra.gd"
## The Plaza del Ayuntamiento and the town hall, built by hand over Catastro's footprint from Street View (the panoramas
## taken inside the square in March 2013 and January 2020, and those of November 2024 from the three streets round
## it), the IGN's aerial photographs of 2006 to 2024, and OpenStreetMap. Second version, 14 November 2026: the user
## asked for it to be done over "de la misma manera que el Petril" (the first one was laid out by eye).
##
## What it is. On the north side the town hall: a covered walk of twenty brick arches on piers with stone feet and
## imposts, a white upper floor with a stone-framed window to each arch, a balcony with its flags over the two middle
## ones and over them a low gable carrying the town's crest, the words CASA AYUNTAMIENTO and the clock (the town's
## clock: world.gd turns its hands). In front of it an open paved floor with two giant chessboards and the town's
## crest laid in the paving between them. Beyond, the garden: big planters walled with stone seats under plane
## trees, the round stone fountain ringed with coloured paving, lawns with cedars and the tall stone column, the
## fenced playground, the kiosk bar with its terrace, the brick bandstand, a row of little round planters and white
## stone benches along the Calle de Zaragoza. On the west the square stands two metres over the Arroyuelo (the bake
## cuts that street down: SUNK), behind a white wall with a railing, a raised pavement of chequered tiles on a rubble
## wall, and flights of steps up from it.
##
## Its own frame (MapData.townhall): the origin is the middle of the town hall's front at the level of the square,
## +x (called u in the notes) runs along that front towards the Calle de Zaragoza, +z (n) points out of it into the
## square. Measures and sources: referencias/plaza_ayuntamiento/LEEME.md.

const Tela = preload("res://scripts/tela.gd")

# ---------------- the town hall (Catastro 4193609VJ5649S: the walk 3.2 m deep, the body 5 m behind it) ----------------
const HALF := 31.7              # half its length
const BAYS := 20                # arches along the front, 3 m each; a wide pier at each end
const BAY := 3.0
const PIER := 0.8
const ARCADE := 3.2             # how deep the covered walk is
const DEPTH := 8.2
const SPRING := 2.55            # where the arches start
const ARCH := 1.1               # ...and their radius
const H1 := 4.15                # the top of the brick storey
const SILL := 5.25              # the upper windows
const HEAD := 6.75
const H2 := 8.6                 # the eaves (the top of the brick cornice)
const DOORS: Array = [2, 11, 17]                # the arches with a door in the back wall of the walk (0 = the first at the Arroyuelo end)
const BOARDS: Array = [10, 14]                   # ...with a noticeboard
const SEATS: Array = [4, 7, 12, 14, 18]         # ...with a wooden bench under the window

# ---------------- the square ----------------
const FOUNTAIN := Vector2(2.5, 53.4)
const BASIN := 4.7              # the outside of its wall (the water is 8.2 m across in the aerial photograph)
const RINGS := 10.0             # how far the rings of coloured paving go: twelve of them
const COLUMN := Vector2(22.5, 48.3)
const PLAY := Vector2(-17.2, 33.5)              # the playground: a fenced circle
const PLAY_R := 8.4
const PLAY_SET := "res://assets/parque/juegos.glb"       # what is played on there (see _playground)
const KIOSK := Rect2(-30.0, 49.6, 10.0, 12.3)   # the bar: its walls (its roof, 10.9 m by 13.5 m in the aerial photograph, overhangs them)
const STAND := Vector2(-20.5, 76.3)             # the bandstand: the middle of its floor
const STAND_TURN := 0.355                       # ...and how far it is turned from the town hall's line (it looks up the square)
const STALL := Vector2(26.4, 60.6)              # the sweets stall

var hall_door: Vector2          # in front of the town hall's main door, on the map
var water: Vector2              # the fountain, on the map
var _low := 0.0                 # the Arroyuelo, from the square's level (about -SUNK; near 0 on a map baked before that)
var _lamps: Array = []

func build(world) -> void:
	W = world
	var th: Dictionary = MapData.townhall
	if th.is_empty():
		return
	var u := Vector2(th["u"][0], th["u"][1])
	var m := Vector2(th["m"][0], th["m"][1])
	# (The square's own level is taken well away from the Arroyuelo: the cut the bake makes for that street reaches,
	# fading, as far as the town hall's door, and a square hung from the door's height sat a hand's breadth into the
	# ground on its other side -- the grass of the map's generic park showed through its paving.)
	var n := Vector2(-u.y, u.x)
	level = MapData.height(m + u * 28.0 + n * 30.0)
	transform = Transform3D(Basis(Vector3.UP, atan2(-u.y, u.x)), Vector3(m.x, level, m.y))
	W.add_child(self)
	_low = MapData.height(spot(-39.6, 40.0)) - level
	hall_door = spot(1.5, 2.0)
	water = spot(FOUNTAIN.x, FOUNTAIN.y)
	_hall()
	_floors()
	_fountain()
	_garden()
	_playground()
	_kiosk()
	_bandstand()
	_furniture()
	_sunk_side()
	home()
	_commit()
	_sweets_stall(STALL, -0.42)
	_occluders()
	MapData.decks = _decks + _floor_decks + MapData.decks

# ---------------- materials ----------------
const MULTI_SHADER := "
shader_type spatial;
render_mode cull_disabled;
varying vec3 at;
void vertex() {
	at = VERTEX;
}
void fragment() {
	vec2 q = vec2(at.x + at.z, at.x - at.z) * 0.7071 / 0.21;          // pavers of a span, laid cornerwise
	vec2 cell = floor(q);
	vec2 f = fract(q);
	float joint = step(0.07, f.x) * step(0.07, f.y);
	float h = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	vec3 c = h < 0.22 ? vec3(0.58, 0.33, 0.31) : (h < 0.44 ? vec3(0.70, 0.60, 0.34) : (h < 0.74 ? vec3(0.33, 0.46, 0.62) : vec3(0.38, 0.52, 0.40)));
	float wear = fract(h * 7.31);
	ALBEDO = mix(vec3(0.36, 0.35, 0.33), c * (0.86 + 0.24 * wear), joint);
	ROUGHNESS = 1.0;
}
"

const RING_SHADER := "
shader_type spatial;
render_mode cull_disabled;
uniform vec2 centre;
uniform float r0 = 5.0;
uniform float band = 0.57;
uniform float last = 11.0;       // the outermost ring
uniform float fade = 0.0;        // how much of their colour they have lost
varying vec3 at;
void vertex() {
	at = VERTEX;
}
void fragment() {
	vec2 d = at.xz - centre;
	float r = length(d);
	float t = (r - r0) / band;
	float k = floor(t);
	float along = atan(d.y, d.x) * (r0 + (k + 0.5) * band) / 0.2;          // the pavers of a ring, one after another
	float joint = step(0.08, fract(along)) * step(0.05, fract(t * 2.85));
	float h = fract(sin(dot(vec2(floor(along), floor(t * 2.85)), vec2(12.9898, 78.233))) * 43758.5453);
	float i = mod(last - k, 4.0);
	vec3 c = i < 0.5 ? vec3(0.58, 0.26, 0.24) : (i < 1.5 ? vec3(0.33, 0.50, 0.35) : (i < 2.5 ? vec3(0.74, 0.60, 0.26) : vec3(0.27, 0.42, 0.60)));
	c = mix(c, vec3(0.60, 0.59, 0.56), fade);
	ALBEDO = mix(mix(vec3(0.34, 0.32, 0.30), vec3(0.47, 0.46, 0.44), fade), c * (0.86 + 0.22 * h), joint);
	ROUGHNESS = 1.0;
}
"

const TILE_SHADER := "
shader_type spatial;
render_mode cull_disabled;
varying vec3 at;
void vertex() {
	at = VERTEX;
}
void fragment() {
	vec2 g = at.xz / 0.42;
	vec2 cell = floor(g);
	vec2 f = fract(g);
	float joint = step(0.045, f.x) * step(0.045, f.y);
	float wear = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	vec3 tile = mix(vec3(0.84, 0.78, 0.66), vec3(0.60, 0.36, 0.31), mod(cell.x + cell.y, 2.0)) * (0.9 + 0.14 * wear);
	ALBEDO = mix(vec3(0.5, 0.47, 0.43), tile, joint);
	ROUGHNESS = 1.0;
}
"

## The water of the fountain: clean (the user: the real one is green with algae; in the game, clean water), never
## still -- little waves crossing it and rings spreading from where the jet falls.
const WATER_SHADER := "
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_always, shadows_disabled;
uniform vec2 centre;
varying vec3 at;
void vertex() {
	at = VERTEX;
}
void fragment() {
	vec2 d = at.xz - centre;
	float r = length(d);
	float w = sin(at.x * 3.1 + TIME * 1.3) * sin(at.z * 2.7 - TIME * 1.1) + 0.5 * sin((at.x + at.z) * 5.3 + TIME * 2.1);
	float rip = sin(r * 7.5 - TIME * 4.6) * exp(-r * 0.5);
	vec2 dir = d / max(r, 0.01);
	vec3 n = normalize(vec3(w * 0.05 + rip * 0.22 * dir.x, 1.0, w * 0.05 + rip * 0.22 * dir.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(mat3(MODEL_MATRIX) * n, 0.0)).xyz);
	float deep = smoothstep(0.0, 4.2, r);
	ALBEDO = mix(vec3(0.42, 0.78, 0.84), vec3(0.20, 0.58, 0.70), deep) * (0.92 + 0.08 * w + 0.1 * rip);
	ALPHA = 0.78;
	ROUGHNESS = 0.12;
	SPECULAR = 0.55;
}
"

const JET_SHADER := "
shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded, shadows_disabled;
void fragment() {
	float run = fract(UV.y * 3.0 + TIME * 2.6);
	float streak = 0.55 + 0.45 * sin(UV.x * 40.0 + TIME * 9.0 + UV.y * 23.0);
	ALBEDO = vec3(0.86, 0.95, 0.98);
	ALPHA = (0.35 + 0.4 * run * streak) * smoothstep(0.0, 0.08, UV.y) * (1.0 - 0.5 * UV.y);
}
"

func _shader(code: String) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	return m

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"brick":            # the facing brick of the walk: the town's own brick set, a little pinker and paler
			m = Tex.mat("brick_wall_003", Color(0.96, 1.15, 1.46))
		"arch":             # ...and the two rings of brick on edge round every arch, a shade darker
			m = Tex.mat("brick_wall_003@0.9", Color(0.9, 1.08, 1.38))
		"cream":            # the back wall of the walk and the two ends: ivory render
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.96, 0.88)), 0.16)
		"eaves":            # the brick cornice, in the shade of the tiles
			m = Tex.mat("brick_wall_003", Color(0.66, 0.72, 0.85))
		"caliza":           # pale dressed stone: window frames, imposts, the feet of the piers, the string course
			m = _glow(Tex.mat("granular_concrete", Color(1.02, 0.97, 0.86)), 0.12)
		"seat":             # the cream stone of the seats that wall the planters, of the fountain and of the benches
			m = _glow(Tex.mat("granular_concrete@1.6", Color(1.08, 1.0, 0.86)), 0.12)
		"paver":            # the grey-pink pavers of the open floor
			m = W._tmat(0xa6a29c, "pavement", 1.3)
		"band":             # ...and the bands of red ones across them
			m = W._tmat(0x9c6a5c, "pavement", 1.3)
		"dark_sq":
			m = W._tmat(0x74767b, "pavement", 2.3)
		"light_sq":
			m = W._tmat(0xc9c5bc, "pavement", 2.3)
		"multi":
			m = _shader(MULTI_SHADER)
		"tiling":
			m = _shader(TILE_SHADER)
		"grass":
			m = W._tmat(0x8fc866, "grass", 3.0)
		"soil":
			m = W._tmat(0x6f5d4a, "earth", 1.6)
		"bush":
			m = W._tmat(0x4f8a48, "leaf", 1.1)
		"rubber":           # the soft floor of the playground
			m = W._tmat(0x55665c, "asphalt", 2.0)
		"tiles_pale":       # the bar's roof: the same tiles bleached to the colour of sand (as the aerial photographs have it)
			var tp: StandardMaterial3D = Tex.mat(Tex.pick("tiles") if Tex.pick("tiles") != "" else "clay_roof_tiles_02", Color(1.0, 1.4, 1.7), true, 1.6)
			tp.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = tp
		"rubble":           # the foot of the bandstand
			m = Tex.mat("stone_wall")
		_:
			return super(key)
	_mats[key] = m
	return m

# ---------------- outlines ----------------
## a rectangle with its corners rounded, going round anticlockwise seen from above (x to the right, z down)
func _rounded(x0: float, z0: float, x1: float, z1: float, r: float, seg := 5) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for corner in [[x1 - r, z0 + r, -PI / 2.0], [x1 - r, z1 - r, 0.0], [x0 + r, z1 - r, PI / 2.0], [x0 + r, z0 + r, PI]]:
		for k in range(seg + 1):
			var a: float = corner[2] + PI / 2.0 * k / seg
			pts.append(Vector2(corner[0] + cos(a) * r, corner[1] + sin(a) * r))
	return pts

func _circle(c: Vector2, r: float, n := 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in range(n):
		pts.append(c + Vector2(cos(TAU * k / n), sin(TAU * k / n)) * r)
	return pts

## the points of an arc round `c`, from angle a0 to a1 (radians, measured from +x towards +z)
func _arc(c: Vector2, r: float, a0: float, a1: float, n := 10) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in range(n + 1):
		var a: float = lerpf(a0, a1, float(k) / n)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts

## that outline moved `by` metres inwards (each corner along the line that halves it)
func _inset(pts: PackedVector2Array, by: float) -> PackedVector2Array:
	var mid := Vector2.ZERO
	for q in pts:
		mid += q / pts.size()
	var out := PackedVector2Array()
	var n := pts.size()
	for i in range(n):
		var a: Vector2 = pts[(i + n - 1) % n]
		var b: Vector2 = pts[i]
		var c: Vector2 = pts[(i + 1) % n]
		var d0: Vector2 = (b - a).normalized()
		var d1: Vector2 = (c - b).normalized()
		var n0 := Vector2(-d0.y, d0.x)
		var n1 := Vector2(-d1.y, d1.x)
		var bis: Vector2 = (n0 + n1).normalized()
		if bis.length() < 0.5:
			bis = n0
		var reach: float = by / maxf(0.5, bis.dot(n0))
		var p: Vector2 = b + bis * reach
		if (p - mid).length() > (b - mid).length() and (b - bis * reach - mid).length() < (b - mid).length():
			p = b - bis * reach             # (the outline ran the other way round)
		out.append(p)
	return out

## A planter: the stone seat that walls it (this outline is its outside), what fills it, and solids along its wall.
## `fill`: "soil", "grass" or "" (nothing: something else lies inside, like the fountain's water).
func _planter(pts: PackedVector2Array, fill := "soil", h := 0.46, thick := 0.42, key = "seat") -> PackedVector2Array:
	var inner := _inset(pts, thick)
	var n := pts.size()
	pieces += n
	for i in range(n):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % n]
		var ia: Vector2 = inner[i]
		var ib: Vector2 = inner[(i + 1) % n]
		var d: Vector2 = (b - a).normalized()
		var out := Vector3(d.y, 0, -d.x)
		if out.dot(Vector3(a.x - ia.x, 0, a.y - ia.y)) < 0.0:
			out = -out
		quad(Vector3(a.x, -0.1, a.y), Vector3(b.x, -0.1, b.y), Vector3(b.x, h, b.y), Vector3(a.x, h, a.y), key, out)
		quad(Vector3(ia.x, 0.0, ia.y), Vector3(ib.x, 0.0, ib.y), Vector3(ib.x, h, ib.y), Vector3(ia.x, h, ia.y), key, -out)
		quad(Vector3(a.x, h, a.y), Vector3(b.x, h, b.y), Vector3(ib.x, h, ib.y), Vector3(ia.x, h, ia.y), key, Vector3.UP)
		var mid: Vector2 = (a + b + ia + ib) / 4.0
		solid(Vector3(mid.x, h / 2.0, mid.y), Vector3(a.distance_to(b) + 0.05, h, thick), atan2(-d.y, d.x))
		if i % 4 == 0:
			yard.append(spot(a.x, a.y))
	if fill != "":
		flat(inner, h - 0.12, fill)
	return inner

## a low iron rail on little posts round the inside of a planter
func _low_rail(inner: PackedVector2Array, h := 0.5, tall := 0.34) -> void:
	var pts := _inset(inner, 0.12)
	var n := pts.size()
	for i in range(n):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % n]
		bar(Vector3(a.x, h + tall, a.y), Vector3(b.x, h + tall, b.y), 0.03, 0.03, IRON)
		if i % 2 == 0:
			cbox(Vector3(a.x, h + tall / 2.0 - 0.1, a.y), Vector3(0.03, tall + 0.2, 0.03), IRON)

## bushes scattered inside an outline (the same every time: `seed`)
func _bushes(inner: PackedVector2Array, count: int, seed_n: int, h := 0.4, size := 0.5) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_n
	var lo := inner[0]
	var hi := inner[0]
	for q in inner:
		lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y))
		hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
	var keep := _inset(inner, 0.5)
	var done := 0
	var tries := 0
	while done < count and tries < count * 30:
		tries += 1
		var p := Vector2(rng.randf_range(lo.x, hi.x), rng.randf_range(lo.y, hi.y))
		if not Geometry2D.is_point_in_polygon(p, keep):
			continue
		var s: float = size * rng.randf_range(0.7, 1.25)
		ball(Vector3(p.x, h + s * 0.45, p.y), s, "bush", 0.75, 7, 4)
		done += 1

# ---------------- the town hall ----------------
func _bay_x(i: int) -> float:
	return -BAY * BAYS / 2.0 + BAY * (i + 0.5)

func _hall() -> void:
	var first := -BAY * BAYS / 2.0              # the middle of the first pier
	# --- the covered walk: brick piers on stone feet, a stone impost where each arch starts, the arches ---
	for i in range(BAYS + 1):
		var px: float = first + i * BAY
		var x0: float = px - PIER / 2.0
		var x1: float = px + PIER / 2.0
		if i == 0:
			x0 = -HALF                          # (the two at the ends are wide: they are the corners of the building)
		if i == BAYS:
			x1 = HALF
		box(maxf(x0, -HALF + 0.015), 0.0, -PIER, minf(x1, HALF - 0.015) - maxf(x0, -HALF + 0.015), SPRING + ARCH, PIER, "brick")
		box(x0 - 0.07, 0.0, -PIER - 0.07, x1 - x0 + 0.14, 0.5, PIER + 0.14, "caliza")
		box(x0 - 0.06, SPRING - 0.16, -PIER - 0.06, x1 - x0 + 0.12, 0.16, PIER + 0.12, "caliza")
		solid(Vector3((x0 + x1) / 2.0, 2.2, -PIER / 2.0), Vector3(x1 - x0, 4.4, PIER))
		yard.append(spot((x0 + x1) / 2.0, -PIER / 2.0))
	box(-HALF + 0.015, SPRING + ARCH, -PIER, 2.0 * HALF - 0.03, H1 - SPRING - ARCH, PIER, "brick")          # the wall over the arches
	for i in range(BAYS):
		var cx: float = _bay_x(i)
		spandrels(cx, SPRING, ARCH, 0.0, "brick")
		ring(cx, SPRING, ARCH, ARCH + 0.3, 0.02, PIER + 0.02, "arch", 14)
		var keep := _xf
		_xf = _xf * Transform3D(Basis(Vector3.UP, PI), Vector3(2.0 * cx, 0, -PIER))      # (the same, seen from inside the walk)
		spandrels(cx, SPRING, ARCH, 0.0, "brick")
		ring(cx, SPRING, ARCH, ARCH + 0.3, 0.02, 0.0, "arch", 14)
		_xf = keep
	box(-HALF - 0.05, H1, -0.12, 2.0 * HALF + 0.1, 0.17, 0.2, "caliza")                     # the stone course between the two floors
	# its floor of chequered tiles, its ceiling, and its back wall: ivory, a barred window or a door to each arch
	flat(PackedVector2Array([Vector2(-HALF, -ARCADE), Vector2(HALF, -ARCADE), Vector2(HALF, 0.0), Vector2(-HALF, 0.0)]), 0.04, "tiling")
	quad(Vector3(-HALF, H1 - 0.02, -ARCADE), Vector3(HALF, H1 - 0.02, -ARCADE), Vector3(HALF, H1 - 0.02, -PIER), Vector3(-HALF, H1 - 0.02, -PIER), "white", Vector3.DOWN)
	var holes: Array = []
	for i in range(BAYS):
		var cx: float = _bay_x(i)
		if i in DOORS:
			holes.append(Rect2(cx - 0.8, -0.3, 1.6, 2.95))
		elif not (i in BOARDS):
			holes.append(Rect2(cx - 0.62, 1.05, 1.24, 1.65))
	_xf = Transform3D(Basis(), Vector3(0, 0, -ARCADE))
	masonry(-HALF, HALF, -1.0, H1, holes, [], "cream", "cream")
	var skirt_from := -HALF                                                                  # (its grey skirting, broken at the doors)
	for i in DOORS:
		box(skirt_from, 0.0, 0.0, _bay_x(i) - 0.8 - skirt_from, 0.55, 0.03, 0xb9b2a6)
		skirt_from = _bay_x(i) + 0.8
	box(skirt_from, 0.0, 0.0, HALF - skirt_from, 0.55, 0.03, 0xb9b2a6)
	for i in range(BAYS):
		var cx: float = _bay_x(i)
		if i in DOORS:
			var open: bool = i == 11                                                        # the main door stands open
			box(cx - 0.8, 0.0, -DEEP + 0.04, 1.6, 2.65, 0.05, 0x241a14 if open else 0x5a3a22)
			for s in [-1.0, 1.0]:
				if open:
					box(cx + s * 0.8 - (0.06 if s > 0.0 else 0.0), 0.0, -DEEP + 0.06, 0.06, 2.6, 0.72, 0x5a3a22)      # (its leaves, folded back)
				else:
					for q in [[0.2, 0.75], [1.1, 1.3]]:
						box(cx + s * 0.4 - 0.3, q[0], -DEEP + 0.09, 0.6, q[1], 0.012, 0x6b4428)
			box(cx - 0.95, 2.65, 0.0, 1.9, 0.16, 0.06, "caliza")
			if i == 2:
				box(cx - 0.75, 2.95, 0.0, 1.5, 0.32, 0.03, 0x1f3f7a)
				_text("POLICÍA LOCAL", Vector3(cx, 3.11, 0.04), 44, 0xf4f4f0, 0.0026)
		elif i in BOARDS:
			box(cx - 0.95, 1.1, 0.0, 1.9, 1.25, 0.06, 0x4a3324)                              # a noticeboard behind glass
			box(cx - 0.88, 1.17, 0.06, 1.76, 1.11, 0.006, 0xe9e2d0)
			for k in range(6):
				box(cx - 0.8 + (k % 3) * 0.56, 1.25 + (k / 3) * 0.52, 0.066, 0.44, 0.42, 0.004, [0xf1e9d4, 0xd9a441, 0xc9d9e6, 0xe8b9a8, 0xf4f4f0, 0xb9d3a4][k])
		else:
			var r := Rect2(cx - 0.62, 1.05, 1.24, 1.65)
			window(r, 0x2f2a26, 0x1c2630, 1)
			grille(r, 0.1)
			box(r.position.x - 0.1, r.position.y - 0.09, 0.0, r.size.x + 0.2, 0.09, 0.07, "caliza")
		if i in SEATS:                                                                      # a wooden bench against the wall
			box(cx - 0.9, 0.42, 0.06, 1.8, 0.06, 0.42, "wood")
			box(cx - 0.9, 0.55, 0.04, 1.8, 0.34, 0.05, "wood")
			for s in [-0.75, 0.75]:
				box(cx + s - 0.04, 0.0, 0.08, 0.08, 0.42, 0.38, 0x26262a)
		if i % 3 == 1:                                                                      # an iron lantern hanging in the arch
			cbox(Vector3(cx, H1 - 0.3, ARCADE - PIER / 2.0), Vector3(0.02, 0.6, 0.02), IRON)
			cbox(Vector3(cx, H1 - 0.78, ARCADE - PIER / 2.0), Vector3(0.2, 0.34, 0.2), IRON)
			cbox(Vector3(cx, H1 - 0.78, ARCADE - PIER / 2.0), Vector3(0.14, 0.24, 0.14), 0xfff1c4)          # (this colour's glass is what lights.gd lights at dusk, with the lamp posts')
	home()
	solid(Vector3(0, 4.5, -(ARCADE + DEPTH) / 2.0), Vector3(2.0 * HALF, 15.0, DEPTH - ARCADE))          # (from well under the ground: at its Arroyuelo end the street is two metres down)

	# --- the upper floor: white, a stone-framed window with its brown blind over every arch; two doors to the balcony ---
	holes = []
	for i in range(BAYS):
		var cx: float = _bay_x(i)
		if i == 9 or i == 10:
			holes.append(Rect2(cx - 0.55, H1 + 0.12, 1.1, HEAD - H1 - 0.12))
		else:
			holes.append(Rect2(cx - 0.5, SILL, 1.0, HEAD - SILL))
	masonry(-HALF, HALF, H1 + 0.17, H2 - 0.25, holes, [], "white", "white")
	for i in range(BAYS):
		var r: Rect2 = holes[i]
		var z: float = -DEEP + 0.06
		box(r.position.x, r.position.y, z - 0.05, r.size.x, r.size.y, 0.03, 0x1c2630)
		box(r.position.x + 0.02, r.end.y - r.size.y * 0.42, z - 0.015, r.size.x - 0.04, r.size.y * 0.42, 0.035, 0x7a4a2c)      # the blind, half way down
		for q in [[r.position.x, 0.07], [r.end.x - 0.07, 0.07], [r.position.x + r.size.x / 2.0 - 0.03, 0.06]]:
			box(q[0], r.position.y, z - 0.02, q[1], r.size.y, 0.06, 0x4a2f1f)
		stone_frame(r, 0.24, 0.045, "caliza")
		box(r.position.x + r.size.x / 2.0 - 0.22, r.end.y + 0.24, 0.0, 0.44, 0.16, 0.06, "caliza")             # (the block over its lintel)
		if i == 9 or i == 10:
			box(r.position.x, r.position.y, z - 0.02, r.size.x, 0.9, 0.05, 0x4a2f1f)                     # (the foot of the balcony door)
	cornice(-HALF, HALF, H2, true, "eaves", 1.5)

	# --- the balcony over the two middle arches, its railing, its flags ---
	var bw := 6.3
	var by: float = H1 + 0.1                    # its floor
	box(-bw / 2.0, by - 0.13, 0.0, bw, 0.13, 0.95, "caliza")
	for s in [-1.0, 0.0, 1.0]:                                                                 # (the iron brackets under it)
		bar(Vector3(s * (bw / 2.0 - 0.25), by - 0.85, 0.03), Vector3(s * (bw / 2.0 - 0.25), by - 0.13, 0.85), 0.05, 0.05, IRON)
	var top: float = by + 1.0
	for z in [0.92]:
		box(-bw / 2.0, top, z - 0.02, bw, 0.05, 0.05, IRON)
		box(-bw / 2.0, by + 0.06, z - 0.015, bw, 0.03, 0.03, IRON)
	for s in [-1.0, 1.0]:
		box(s * bw / 2.0 - 0.025, top, 0.0, 0.05, 0.05, 0.94, IRON)
		box(s * bw / 2.0 - 0.015, by + 0.06, 0.0, 0.03, 0.03, 0.94, IRON)
		for k in range(7):
			box(s * bw / 2.0 - 0.012, by, 0.06 + k * 0.135, 0.024, 1.0, 0.024, IRON)
	var nb := int(bw / 0.135)
	for k in range(nb + 1):
		box(-bw / 2.0 + bw * k / nb - 0.012, by, 0.908, 0.024, 1.0, 0.024, IRON)
	var flags: Array = [[-bw / 2.0 + 0.12, [0x9b1b30, 0xf4f4f0], false], [0.0, [0xc8102e, 0xf1bf00, 0xf1bf00, 0xc8102e], true], [bw / 2.0 - 0.12, [0x7a2030], false]]
	for i in range(flags.size()):
		var pole := Node3D.new()
		pole.position = Vector3(flags[i][0], H1 + 1.05, 0.9)
		pole.rotation.x = 0.5
		add_child(pole)
		pole.add_child(Parts.part("cyl", 0x3a3a3a, Vector3(0, 1.2, 0), Vector3(0.025, 2.4, 0.025)))
		var stripes: Array = flags[i][1]
		var across: bool = flags[i][2]              # bands one over another, or halves side by side
		var paint := func(a: float, d: float) -> Color:
			return Parts.col(stripes[mini(stripes.size() - 1, int((d if across else a) * stripes.size()))])
		var fst := Tela.begin()                     # cloth: it waves in the wind (tela.gd)
		Tela.sheet(fst, Vector3(0.02, 2.36, 0.0), Vector3(1.25, 0.0, 0.0), Vector3(0.0, -0.8, 0.0), false, paint, 0.2, i * 0.27 + 0.1, 0.0, 14, 6)
		var cloth := MeshInstance3D.new()
		cloth.mesh = fst.commit()
		cloth.material_override = Tela.material()
		cloth.extra_cull_margin = 1.5
		pole.add_child(cloth)

	# --- the gable over it: the words, the crest, the clock; brick copings and four brick pinnacles with stone balls ---
	var gy: float = H2 + 0.18
	var gw := 4.0                               # half the gable; then half the block the clock is in, and where that block begins and ends
	var cw := 0.8
	var c0: float = gy + 1.75
	var c1: float = gy + 2.7
	var outline := PackedVector2Array([Vector2(-gw, gy), Vector2(gw, gy), Vector2(gw, gy + 0.45), Vector2(cw, c0), Vector2(cw, c1)])
	for k in range(1, 12):
		outline.append(Vector2(cos(PI * k / 12.0) * cw, c1 + sin(PI * k / 12.0) * 0.5))
	outline.append(Vector2(-cw, c1))
	outline.append(Vector2(-cw, c0))
	outline.append(Vector2(-gw, gy + 0.45))
	slab(outline, 0.1, 0.5, "white")
	for s in [-1.0, 1.0]:
		bar(Vector3(s * (gw + 0.06), gy + 0.5, -0.15), Vector3(s * cw, c0 + 0.08, -0.15), 0.6, 0.14, "brick")              # the copings of its slopes
		for pin in [[gw, 0.45, 0.75, 0.2], [cw + 0.12, 2.7, 0.36, 0.13]]:
			var pw: float = pin[3]
			box(s * pin[0] - pw, gy + pin[1], -0.15 - pw, 2.0 * pw, pin[2], 2.0 * pw, "brick")
			box(s * pin[0] - pw - 0.05, gy + pin[1] + pin[2], -0.2 - pw, 2.0 * pw + 0.1, 0.07, 2.0 * pw + 0.1, "caliza")
			ball(Vector3(s * pin[0], gy + pin[1] + pin[2] + pw + 0.04, -0.15), pw, "caliza", 1.0, 10, 6)
	for k in range(12):                                                                                           # the brick arch over the clock
		var a0: float = PI * k / 12.0
		var a1: float = PI * (k + 1) / 12.0
		bar(Vector3(cos(a0) * (cw + 0.03), c1 + sin(a0) * 0.53, -0.15), Vector3(cos(a1) * (cw + 0.03), c1 + sin(a1) * 0.53, -0.15), 0.6, 0.12, "brick")
	box(-2.3, gy + 0.03, 0.1, 4.6, 0.4, 0.03, 0xefe9da)                                                           # the words
	_text("CASA  AYUNTAMIENTO", Vector3(0, gy + 0.23, 0.14), 64, 0x2a221c, 0.0046)
	var cy: float = gy + 2.5                                                                                     # the clock
	slab(oval(0.0, cy, 0.56, 0.56, 24), 0.13, 0.03, 0x4a3424)
	slab(oval(0.0, cy, 0.49, 0.49, 24), 0.14, 0.0, 0xfffaf0)
	for k in range(12):
		tbox(Transform3D(Basis(Vector3(0, 0, 1), -k * TAU / 12.0).scaled_local(Vector3(0.03, 0.08, 0.01)), Vector3(sin(k * TAU / 12.0) * 0.41, cy + cos(k * TAU / 12.0) * 0.41, 0.15)), 0x1b1b1f)
	var pair: Array = []
	for hand in [[0.075, 0.28], [0.05, 0.42]]:
		var pivot := Node3D.new()
		pivot.position = Vector3(0, cy, 0.16)
		var arm := Parts.part("box", 0x1b1b1f, Vector3(0, hand[1] / 2.0 - 0.05, 0), Vector3(hand[0], hand[1] + 0.1, 0.02))
		arm.visibility_range_end = 900.0          # (small as they are, they are the clock: Parts.thin would stop drawing them past 32 m, and the face was left bare)
		arm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pivot.add_child(arm)
		add_child(pivot)
		pair.append(pivot)
	W._hands = [pair]
	slab(oval(0.0, gy + 0.93, 0.62, 0.62, 20), 0.12, 0.02, "brick")                                              # the crest in its round frame
	slab(oval(0.0, gy + 0.93, 0.52, 0.52, 20), 0.13, 0.0, 0xf3efe4)
	var logo := Parts.texture("res://assets/logo.png")
	if logo != null:
		var crest := Sprite3D.new()
		crest.texture = logo
		crest.pixel_size = 0.8 / logo.get_width()
		crest.position = Vector3(0, gy + 0.93, 0.15)
		crest.shaded = false
		add_child(crest)

	# --- iron lanterns on brackets: at the two corners and on every fourth pier ---
	for i in [0, 4, 8, 12, 16, 20]:
		var lx: float = first + i * BAY
		lx = clampf(lx, -HALF + 0.5, HALF - 0.5)
		bar(Vector3(lx, 3.72, 0.0), Vector3(lx, 3.72, 0.55), 0.04, 0.04, IRON)
		bar(Vector3(lx, 3.3, 0.02), Vector3(lx, 3.7, 0.4), 0.03, 0.03, IRON)
		cbox(Vector3(lx, 3.42, 0.55), Vector3(0.24, 0.4, 0.24), IRON)
		cbox(Vector3(lx, 3.42, 0.55), Vector3(0.17, 0.28, 0.17), 0xfff1c4)
		drum(Vector3(lx, 3.62, 0.55), 0.2, 0.03, 0.16, IRON, 8)
		_lamps.append(Vector3(lx, 3.4, 0.9))

	# --- its two ends: ivory below, white above; the walk comes out through an arch at each ---
	for end in [[Vector2(-HALF, -DEPTH), Vector2(-HALF, 0.0), DEPTH - 2.95, false], [Vector2(HALF, 0.0), Vector2(HALF, -DEPTH), 0.65, true]]:
		var ln := face(end[0], end[1])
		var ax: float = end[2]                      # where the arch begins along this wall
		var mural: bool = end[3]
		var arch_hole := Rect2(ax, -1.5, 2.3, SPRING + 1.15 + 1.5)
		var win_x: float = (ln - 2.3) if mural else 1.6
		var up_win := Rect2(ln / 2.0 - 0.475, SILL, 0.95, HEAD - SILL)
		var low_holes: Array = [arch_hole]
		if not mural:
			low_holes.append(Rect2(win_x - 0.55, 1.2, 1.1, 1.5))
		masonry(0.0, ln, -3.0, H1, low_holes, [], "cream", "cream")
		spandrels(ax + 1.15, SPRING, 1.15, 0.0, "cream")
		for q in [[0.0, ax], [ax + 2.3, ln]]:                                                # brick at its two corners, as round the front
			if q[1] - q[0] < 1.0:
				box(q[0], -3.0, 0.0, q[1] - q[0], H1 + 3.0, 0.03, "brick")
		box(-0.05, H1, -0.02, ln + 0.1, 0.17, 0.1, "caliza")
		masonry(0.0, ln, H1 + 0.17, H2 - 0.25, [up_win], [], "white", "white")
		box(up_win.position.x, up_win.position.y, -DEEP + 0.01, up_win.size.x, up_win.size.y, 0.03, 0x1c2630)
		box(up_win.position.x, up_win.end.y - 0.65, -DEEP + 0.06, up_win.size.x, 0.65, 0.04, 0x7a4a2c)
		stone_frame(up_win, 0.17, 0.04, "caliza")
		cornice(0.0, ln, H2, true, "eaves", 1.5)
		if mural:
			_mural(3.5, ln - 0.3)
		else:
			var r := Rect2(win_x - 0.55, 1.2, 1.1, 1.5)
			window(r, 0x2f2a26, 0x1c2630, 1)
			grille(r, 0.1)
		home()
	_plain(Vector2(HALF, -DEPTH), Vector2(-HALF, -DEPTH), -3.0, H2, "white")                # (its back, on to the yards behind)

	# --- the roof: two long slopes of the town's tiles, hipped at the ends ---
	var e := 0.5
	var mid_z: float = -DEPTH / 2.0
	var ry: float = H2 + 1.85
	var hip := 3.2
	var a := Vector3(-HALF - e, H2, e)
	var b := Vector3(HALF + e, H2, e)
	var c := Vector3(HALF + e, H2, -DEPTH - e)
	var d := Vector3(-HALF - e, H2, -DEPTH - e)
	var r0 := Vector3(-HALF + hip, ry, mid_z)
	var r1 := Vector3(HALF - hip, ry, mid_z)
	roof([a, b, r1, r0])
	roof([c, d, r0, r1])
	roof([d, a, r0])
	roof([b, c, r1])
	for q in [[r0, r1], [a, r0], [d, r0], [b, r1], [c, r1]]:
		ridge(q[0], q[1])

## What somebody painted on the end of the town hall that looks on to the Calle de Zaragoza (the real wall has a mural
## about the town's Quixote days; this is a picture of the game's own): a hill, a windmill, a rider and the sun.
func _mural(x0: float, x1: float) -> void:
	var w: float = x1 - x0
	var z := 0.012
	box(x0, 0.55, 0.0, w, 3.2, z, 0xefe6cf)
	slab(PackedVector2Array([Vector2(x0, 0.55), Vector2(x1, 0.55), Vector2(x1, 1.25), Vector2(x0 + w * 0.6, 1.7), Vector2(x0 + w * 0.25, 1.35), Vector2(x0, 1.5)]), z + 0.01, 0.0, 0xc9a45a)      # the hill
	var mx: float = x0 + w * 0.62
	slab(PackedVector2Array([Vector2(mx - 0.34, 1.6), Vector2(mx + 0.34, 1.6), Vector2(mx + 0.26, 2.75), Vector2(mx - 0.26, 2.75)]), z + 0.02, 0.0, 0xf6f3ea)      # the mill
	slab(PackedVector2Array([Vector2(mx - 0.34, 2.75), Vector2(mx + 0.34, 2.75), Vector2(mx, 3.2)]), z + 0.02, 0.0, 0x4a3324)
	for k in range(4):
		var ang: float = 0.5 + k * PI / 2.0
		tbox(Transform3D(Basis(Vector3(0, 0, 1), ang).scaled_local(Vector3(0.09, 1.0, 0.01)), Vector3(mx + cos(ang + PI / 2.0) * 0.5, 2.78 + sin(ang + PI / 2.0) * 0.5, z + 0.032)), 0x3a2a1e)
	slab(oval(x0 + w * 0.2, 3.15, 0.3, 0.3, 14), z + 0.02, 0.0, 0xe2a03a)                                              # the sun
	var hx: float = x0 + w * 0.27                                                                                      # the rider
	slab(PackedVector2Array([Vector2(hx - 0.4, 1.85), Vector2(hx + 0.38, 1.85), Vector2(hx + 0.5, 2.15), Vector2(hx + 0.42, 2.38), Vector2(hx + 0.28, 2.12), Vector2(hx - 0.36, 2.1)]), z + 0.022, 0.0, 0x2a2420)
	for q in [-0.3, -0.2, 0.24, 0.32]:
		box(hx + q - 0.025, 1.4, z + 0.018, 0.05, 0.5, 0.01, 0x2a2420)
	slab(PackedVector2Array([Vector2(hx - 0.1, 2.1), Vector2(hx + 0.08, 2.1), Vector2(hx + 0.05, 2.62), Vector2(hx - 0.07, 2.62)]), z + 0.032, 0.0, 0x2a2420)
	slab(oval(hx - 0.01, 2.72, 0.09, 0.1, 10), z + 0.032, 0.0, 0x2a2420)
	bar(Vector3(hx + 0.1, 2.2, z + 0.04), Vector3(hx + 0.55, 3.3, z + 0.04), 0.03, 0.01, 0x2a2420)

## What hides what (the occlusion culling of game.gd takes its occluders from the map's generic walls, and the town
## hall has none there): its own long walls, a hand's breadth inside themselves.
func _occluders() -> void:
	var verts := PackedVector3Array()
	var idx := PackedInt32Array()
	for q in [[Vector2(-HALF + 0.4, -ARCADE - 0.2), Vector2(HALF - 0.4, -ARCADE - 0.2), 0.4, H2 - 0.8], [Vector2(-HALF + 0.4, -DEPTH + 0.2), Vector2(HALF - 0.4, -DEPTH + 0.2), 0.4, H2 - 0.8],
			[Vector2(-HALF + 0.4, -0.2), Vector2(HALF - 0.4, -0.2), H1 + 0.4, H2 - 0.8]]:
		var a: Vector2 = q[0]
		var b: Vector2 = q[1]
		var k := verts.size()
		verts.append_array([Vector3(a.x, q[2], a.y), Vector3(b.x, q[2], b.y), Vector3(b.x, q[3], b.y), Vector3(a.x, q[3], a.y)])
		idx.append_array([k, k + 1, k + 2, k, k + 2, k + 3])
	var shape := ArrayOccluder3D.new()
	shape.set_arrays(verts, idx)
	var oc := OccluderInstance3D.new()
	oc.occluder = shape
	add_child(oc)

# ---------------- the floor of the square ----------------
const EDGE := -30.2             # where the square ends above the Arroyuelo
const SW_END := 89.45           # ...and where that edge meets the Calle de la Plaza

## the square's own outline: the town hall's front, the Calle de Zaragoza, the Calle de la Plaza, the wall over the Arroyuelo
func _outline() -> PackedVector2Array:
	return PackedVector2Array([Vector2(EDGE, 0.0), Vector2(HALF, 0.0), Vector2(34.47, 56.57), Vector2(27.96, 61.06), Vector2(16.77, 67.44), Vector2(EDGE, SW_END)])

## a flat ring (or a disc, r0 = 0) with a material of its own
func _disc_mesh(c: Vector2, r0: float, r1: float, y: float, material: Material, n := 48) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(n):
		var a0: float = TAU * k / n
		var a1: float = TAU * (k + 1) / n
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var o := Vector3(c.x, y, c.y)
		for q in [o + d0 * r0, o + d1 * r1, o + d0 * r1, o + d0 * r0, o + d1 * r0, o + d1 * r1]:
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(q.x, q.z))
			st.add_vertex(q)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi

func _rings(c: Vector2, r0: float, r1: float, y: float, band := 0.57, fade := 0.0) -> void:
	var m := _shader(RING_SHADER)
	m.set_shader_parameter("centre", c)
	m.set_shader_parameter("r0", r0)
	m.set_shader_parameter("band", band)
	m.set_shader_parameter("last", round((r1 - r0) / band) - 1.0)
	m.set_shader_parameter("fade", fade)
	_disc_mesh(c, r0, r1, y, m)

func _strip(a: Vector2, b: Vector2, wide: float, y: float, key) -> void:
	var d: Vector2 = (b - a).normalized()
	var s := Vector2(-d.y, d.x) * wide / 2.0
	flat(PackedVector2Array([a - s, b - s, b + s, a + s]), y, key)

func _floors() -> void:
	var y := 0.02
	flat(_outline(), y, "paver")
	# the open floor in front of the town hall: grey pavers crossed by bands of red ones; two giant chessboards
	for n in [2.2, 17.6]:
		_strip(Vector2(EDGE + 0.4, n), Vector2(HALF + 0.6, n), 0.55, y + 0.012, "band")
	for u in [-27.0, -9.6, 11.0, 26.2]:
		_strip(Vector2(u, 2.2), Vector2(u, 20.4), 0.55, y + 0.012, "band")
	for c in [Vector2(-17.0, 9.6), Vector2(18.4, 9.6)]:
		_checker(c, 10.0, y + 0.024)
	# the town's crest laid into the paving in front of the main doors, inside a ring
	_floor_crest(Vector2(0.6, 9.3), 8.2, y + 0.028)
	for k in range(40):
		var a0: float = TAU * k / 40.0
		var a1: float = TAU * (k + 1) / 40.0
		var o := Vector2(0.6, 9.3)
		flat(PackedVector2Array([o + Vector2(cos(a0), sin(a0)) * 4.7, o + Vector2(cos(a1), sin(a1)) * 4.7, o + Vector2(cos(a1), sin(a1)) * 5.15, o + Vector2(cos(a0), sin(a0)) * 5.15]), y + 0.016, "band")
	# the south-west of the square was repaved in pavers of four colours, and round the fountain they go in rings
	flat(PackedVector2Array([Vector2(EDGE, 36.0), Vector2(-9.0, 36.0), Vector2(6.5, 40.0), Vector2(12.6, 47.0), Vector2(13.0, 53.0), Vector2(10.6, 60.0), Vector2(4.0, 63.6),
		Vector2(-3.5, 63.6), Vector2(-3.5, 76.9), Vector2(EDGE, SW_END)]), y + 0.014, "multi")
	_strip(Vector2(-20.0, 45.1), Vector2(2.2, 42.6), 0.22, y + 0.026, 0x3a3a3c)              # (the drain that crosses them)
	_rings(FOUNTAIN, BASIN - 0.08, RINGS, y + 0.028, (RINGS - BASIN + 0.08) / 12.0)

func _checker(centre: Vector2, side: float, y: float) -> void:
	var cells := 8
	var sq: float = side / cells
	var x0: float = centre.x - side / 2.0
	var z0: float = centre.y - side / 2.0
	flat(PackedVector2Array([Vector2(x0 - 0.35, z0 - 0.35), Vector2(x0 + side + 0.35, z0 - 0.35), Vector2(x0 + side + 0.35, z0 + side + 0.35), Vector2(x0 - 0.35, z0 + side + 0.35)]), y - 0.012, 0x6f6c6c)
	for i in range(cells):
		for k in range(cells):
			flat(PackedVector2Array([Vector2(x0 + i * sq, z0 + k * sq), Vector2(x0 + (i + 1) * sq, z0 + k * sq), Vector2(x0 + (i + 1) * sq, z0 + (k + 1) * sq), Vector2(x0 + i * sq, z0 + (k + 1) * sq)]),
				y, "light_sq" if (i + k) % 2 == 0 else "dark_sq")

## The crest as a mosaic of pavers: the image is read paver by paver (so it has the joints of the paving), in dulled
## colours, and each has lost more or less of its colour.
const CREST_SHADER := "
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform sampler2D crest : source_color, filter_linear;
void fragment() {
	vec2 grid = vec2(46.0, 92.0);                         // pavers across and down
	vec2 g = UV * grid;
	float row = floor(g.y);
	g.x += mod(row, 2.0) * 0.5;                           // every other course is shifted half a paver
	vec2 cell = vec2(floor(g.x), row);
	vec2 at = (cell + vec2(0.5 - mod(row, 2.0) * 0.5, 0.5)) / grid;
	vec4 c = texture(crest, clamp(at, vec2(0.0), vec2(1.0)));
	float wear = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	float patch = 0.5 + 0.5 * sin(cell.x * 0.21 + 1.3) * sin(cell.y * 0.13 + 0.4);      // where everybody walks
	vec2 in_brick = fract(g);
	float joint = step(0.06, in_brick.x) * step(0.1, in_brick.y);
	float grey = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	ALBEDO = mix(vec3(grey), c.rgb, 0.8) * 0.8 + vec3(0.04, 0.02, 0.02);
	ROUGHNESS = 1.0;
	ALPHA = c.a * joint * mix(0.3, 0.75, wear) * mix(0.6, 1.0, patch);
}
"

func _floor_crest(centre: Vector2, side: float, y: float) -> void:
	var logo := Parts.texture("res://assets/logo.png")
	if logo == null:
		return
	var h: float = side / 2.0
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	# top of the crest towards the town hall, so you read it as you walk up to the doors
	arr[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(centre.x - h, y, centre.y - h), Vector3(centre.x + h, y, centre.y - h), Vector3(centre.x + h, y, centre.y + h), Vector3(centre.x - h, y, centre.y + h)])
	arr[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	arr[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
	arr[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var m := _shader(CREST_SHADER)
	m.set_shader_parameter("crest", logo)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

# ---------------- the fountain ----------------
## The round stone fountain in the middle of the garden (the user, 14 November 2026: "una fuente de piedra... tiene el
## agua verde por las algas, pero estaría bien hacerla con agua limpia"): a wall of cream stone to sit on, clean water
## that never stands still, and in the middle a low stone with its jet.
func _fountain() -> void:
	var c := FOUNTAIN
	_planter(_circle(c, BASIN, 32), "", 0.7, 0.5)
	for k in range(32):                         # (the lip of its coping)
		var a0: float = TAU * k / 32.0
		var a1: float = TAU * (k + 1) / 32.0
		for r in [[BASIN + 0.05, BASIN - 0.55]]:
			var p0 := Vector3(c.x + cos(a0) * r[0], 0.7, c.y + sin(a0) * r[0])
			var p1 := Vector3(c.x + cos(a1) * r[0], 0.7, c.y + sin(a1) * r[0])
			var q0 := Vector3(c.x + cos(a0) * r[1], 0.7, c.y + sin(a0) * r[1])
			var q1 := Vector3(c.x + cos(a1) * r[1], 0.7, c.y + sin(a1) * r[1])
			var up := Vector3(0, 0.07, 0)
			quad(p0 + up, p1 + up, q1 + up, q0 + up, "seat", Vector3.UP)
			quad(p0, p1, p1 + up, p0 + up, "seat", Vector3(cos((a0 + a1) / 2.0), 0, sin((a0 + a1) / 2.0)))
			quad(q0, q1, q1 + up, q0 + up, "seat", -Vector3(cos((a0 + a1) / 2.0), 0, sin((a0 + a1) / 2.0)))
	flat(_circle(c, BASIN - 0.48, 32), 0.1, 0xcfe3e0)                                       # its floor, pale under the water
	var wm := _shader(WATER_SHADER)
	wm.set_shader_parameter("centre", c)
	_disc_mesh(c, 0.0, BASIN - 0.49, 0.54, wm, 40)
	drum(Vector3(c.x, 0.1, c.y), 0.85, 0.7, 0.4, "seat", 16)                                # the stone in the middle
	drum(Vector3(c.x, 0.5, c.y), 0.34, 0.3, 0.42, "seat", 12)
	drum(Vector3(c.x, 0.92, c.y), 0.3, 0.78, 0.2, "seat", 16)
	drum(Vector3(c.x, 1.12, c.y), 0.8, 0.8, 0.05, "seat", 16)
	drum(Vector3(c.x, 1.17, c.y), 0.07, 0.05, 0.14, 0x8a6a3a, 8)
	var jm := _shader(JET_SHADER)                                                           # ...and its jet
	for turn in [0.0, PI / 2.0]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var side := Vector3(cos(turn), 0, sin(turn))
		var foot := Vector3(c.x, 1.28, c.y)
		var top := foot + Vector3(0, 1.45, 0)
		var corners: Array = [[foot - side * 0.08, Vector2(0, 0)], [foot + side * 0.08, Vector2(1, 0)], [top + side * 0.035, Vector2(1, 1)], [top - side * 0.035, Vector2(0, 1)]]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3(-side.z, 0, side.x))
			st.set_uv(corners[k][1])
			st.add_vertex(corners[k][0])
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = jm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	for k in range(10):                         # (what falls back from it, round the bowl)
		var a: float = TAU * k / 10.0
		bar(Vector3(c.x + cos(a) * 0.78, 1.12, c.y + sin(a) * 0.78), Vector3(c.x + cos(a) * 0.86, 0.58, c.y + sin(a) * 0.86), 0.05, 0.012, 0xd9f1f6)

# ---------------- the garden ----------------
func _edge_u(n: float) -> float:                # the Calle de Zaragoza side of the square, at n
	return HALF + (34.47 - HALF) * n / 56.57

func _south_n(u: float) -> float:               # ...and its Calle de la Plaza side, at u
	return 67.44 + (16.77 - u) * (SW_END - 67.44) / (16.77 - EDGE)

func _garden() -> void:
	# --- the two big planters under the plane trees, between the open floor and the fountain: a stone seat all round,
	# a low iron rail behind it, bushes ---
	var big_qs := [[Vector2(2.8, 26.8), 4.7, 11], [Vector2(15.3, 24.7), 4.6, 23]]
	for qi in big_qs.size():
		var q: Array = big_qs[qi]
		var pc: Vector2 = q[0]
		var pr: float = q[1]
		_planter(_circle(pc, pr, 28), "", 0.44, 0.52)                               # the seat
		var back: float = pr - 0.52
		for k in range(4):                                                              # its back, in four lengths; an iron rail in the gaps between them
			var a0: float = TAU * k / 4.0 + deg_to_rad(18.0)
			var a1: float = TAU * (k + 1) / 4.0 - deg_to_rad(18.0)
			for j in range(6):
				var b0: float = lerpf(a0, a1, j / 6.0)
				var b1: float = lerpf(a0, a1, (j + 1) / 6.0)
				var o0 := Vector3(pc.x + cos(b0) * back, 0, pc.y + sin(b0) * back)
				var o1 := Vector3(pc.x + cos(b1) * back, 0, pc.y + sin(b1) * back)
				var i0 := Vector3(pc.x + cos(b0) * (back - 0.26), 0, pc.y + sin(b0) * (back - 0.26))
				var i1 := Vector3(pc.x + cos(b1) * (back - 0.26), 0, pc.y + sin(b1) * (back - 0.26))
				var up := Vector3(0, 0.92, 0)
				var out := Vector3(cos((b0 + b1) / 2.0), 0, sin((b0 + b1) / 2.0))
				quad(o0 + Vector3(0, 0.4, 0), o1 + Vector3(0, 0.4, 0), o1 + up, o0 + up, "seat", out)
				quad(i0 + Vector3(0, 0.3, 0), i1 + Vector3(0, 0.3, 0), i1 + up, i0 + up, "seat", -out)
				quad(o0 + up, o1 + up, i1 + up, i0 + up, "seat", Vector3.UP)
				if j == 0:
					quad(o0 + Vector3(0, 0.4, 0), i0 + Vector3(0, 0.3, 0), i0 + up, o0 + up, "seat", Vector3(sin(b0), 0, -cos(b0)))
				if j == 5:
					quad(o1 + Vector3(0, 0.4, 0), i1 + Vector3(0, 0.3, 0), i1 + up, o1 + up, "seat", Vector3(-sin(b1), 0, cos(b1)))
			var g0: float = a1
			var g1: float = TAU * (k + 1) / 4.0 + deg_to_rad(18.0)
			for h in [0.86, 0.6]:
				bar(Vector3(pc.x + cos(g0) * (back - 0.13), h, pc.y + sin(g0) * (back - 0.13)), Vector3(pc.x + cos(g1) * (back - 0.13), h, pc.y + sin(g1) * (back - 0.13)), 0.035, 0.035, IRON)
			bar(Vector3(pc.x + cos(g0) * (back - 0.13), 0.44, pc.y + sin(g0) * (back - 0.13)), Vector3(pc.x + cos(g1) * (back - 0.13), 0.86, pc.y + sin(g1) * (back - 0.13)), 0.03, 0.03, IRON)
		var bed := _circle(pc, back - 0.26, 28)
		flat(bed, 0.3, "soil")
		_bushes(bed, 20, q[2], 0.3)
		_rings(pc, pr - 0.05, pr + 2.5, 0.062 if qi % 2 == 0 else 0.076, 0.5, 0.72)
		_broad(pc, 6.6, 4.6, 0.3)
	# --- along the Calle de Zaragoza: little round planters, each with its tree inside iron hoops and rings of coloured
	# paving round it, and white stone benches between them ---
	var last := Vector2.ZERO
	var row_ns := [23.0, 30.0, 37.0, 44.0, 51.0]
	for ni in row_ns.size():
		var n: float = row_ns[ni]
		var c := Vector2(_edge_u(n) - 2.2, n)
		_round_planter(c, 1.45)
		_rings(c, 1.5, 3.1, 0.062 if ni % 2 == 0 else 0.076, 0.4, 0.8)
		_ball_tree(c, 0.3)
		if last != Vector2.ZERO:
			_bench((c + last) / 2.0 - Vector2(0.3, 0.0), -PI / 2.0)
		last = c
	var ne := Vector2(27.6, 9.0)                # ...and the one at the corner by the town hall, bigger
	_round_planter(ne, 1.9)
	_ball_tree(ne, 0.3, 2.6, 1.9)
	for q in [[Vector2(27.2, 22.0), -PI / 2.0 + 0.5], [Vector2(24.6, 20.2), PI + 0.4], [Vector2(26.6, 31.0), -PI / 2.0], [Vector2(24.4, 35.4), -0.2]]:
		_bench(q[0], q[1])
	# --- the lawns: one east of the fountain, with the tall stone column; one south of it, down to the street ---
	var f := FOUNTAIN
	var l1 := PackedVector2Array([Vector2(9.5, 36.5), Vector2(26.4, 35.6), Vector2(29.8, 39.6), Vector2(30.2, 54.0), Vector2(25.2, 56.6), Vector2(16.0, 58.2)])
	l1.append_array(_arc(f, 10.3, deg_to_rad(30.0), deg_to_rad(-55.0), 12))
	_planter(l1, "grass", 0.42, 0.4)
	var l2 := _arc(f, 10.3, deg_to_rad(150.0), deg_to_rad(40.0), 14)
	l2.append_array(PackedVector2Array([Vector2(15.0, 60.6), Vector2(15.4, _south_n(15.4) - 0.8), Vector2(-3.2, _south_n(-3.2) - 0.8), Vector2(-4.2, 62.0)]))
	var in2 := _planter(l2, "grass", 0.42, 0.4)
	bar(Vector3(15.0, 0.95, _south_n(15.0) - 1.4), Vector3(-2.8, 0.95, _south_n(-2.8) - 1.4), 0.04, 0.04, IRON)                 # (the rail along the street)
	bar(Vector3(15.0, 0.68, _south_n(15.0) - 1.4), Vector3(-2.8, 0.68, _south_n(-2.8) - 1.4), 0.03, 0.03, IRON)
	for k in range(10):
		var ru: float = lerpf(15.0, -2.8, k / 9.0)
		cbox(Vector3(ru, 0.68, _south_n(ru) - 1.4), Vector3(0.04, 0.56, 0.04), IRON)
	_bushes(in2, 9, 31, 0.36, 0.7)
	_column(COLUMN)
	_broad(Vector2(13.6, 41.4), 6.2, 4.2, 0.3)
	_cedar(Vector2(26.6, 42.0), 10.0, 0.3)
	_broad(Vector2(20.4, 53.4), 6.0, 4.0, 0.3)
	_cypress(Vector2(13.0, 65.6), 11.5, 0.3, 0.13)             # (the big one by the street)
	_cedar(Vector2(5.2, 66.4), 11.0, 0.3)
	_broad(Vector2(-0.6, 67.8), 6.4, 4.0, 0.3)
	_broad(Vector2(8.6, 68.6), 5.8, 3.8, 0.3)
	_broad(Vector2(-1.6, 73.2), 6.0, 3.8, 0.3)
	# --- by the playground and the bar ---
	_cedar(Vector2(-25.5, 41.0), 13.5)                          # (the tall fir between the playground and the steps down to the Arroyuelo)
	for q in [Vector2(-28.9, 9.5), Vector2(-28.9, 15.5)]:
		_bench(q, PI / 2.0)
	for tu in [-6.5, -11.5, -28.6]:
		_ball_tree(Vector2(tu, _south_n(tu) - 1.6), 0.0, 3.0, 2.3)

## a little round planter: a low stone kerb, earth, iron hoops round it
func _round_planter(c: Vector2, r: float) -> void:
	_planter(_circle(c, r, 16), "soil", 0.32, 0.22)
	for k in range(8):
		var a: float = TAU * k / 8.0
		_hoop(Vector3(c.x + cos(a) * (r - 0.3), 0.32, c.y + sin(a) * (r - 0.3)), a + PI / 2.0, 0.42, 0.36)

## an iron hoop standing on the ground at `at`, its plane turned `turn` about the upright
func _hoop(at: Vector3, turn: float, half := 0.48, tall := 0.48) -> void:
	var along := Vector3(cos(turn), 0, sin(turn))
	var last := at - along * half
	for k in range(1, 7):
		var a: float = PI * k / 6.0
		var p: Vector3 = at - along * (cos(a) * half) + Vector3(0, sin(a) * tall, 0)
		bar(last, p, 0.035, 0.035, IRON)
		last = p

## a white stone bench: a slab on two blocks; whoever sits on it looks the way `facing` turns +z
func _bench(at: Vector2, facing: float) -> void:
	var keep := _xf
	_xf = Transform3D(Basis(Vector3.UP, facing), Vector3(at.x, 0, at.y))
	box(-1.0, 0.38, -0.28, 2.0, 0.12, 0.56, "seat")
	box(-1.0, 0.42, -0.4, 2.0, 0.46, 0.13, "seat")                 # (its back)
	for s in [-0.72, 0.72]:
		box(s - 0.13, 0.0, -0.38, 0.26, 0.38, 0.6, "seat")
	_xf = keep
	solid(Vector3(at.x, 0.44, at.y), Vector3(2.0, 0.88, 0.7), facing)
	yard.append(spot(at.x, at.y))

## The tall stone column that stands on the lawn: three steps, a pedestal, a fluted shaft, and on its capital a little
## open temple of six small columns under a cap.
func _column(at: Vector2) -> void:
	var o := Vector3(at.x, 0.3, at.y)
	drum(o, 1.5, 1.5, 0.22, "seat", 8)
	drum(o + Vector3(0, 0.22, 0), 1.15, 1.15, 0.22, "seat", 8)
	cbox(o + Vector3(0, 1.04, 0), Vector3(1.1, 1.2, 1.1), "seat")
	cbox(o + Vector3(0, 1.7, 0), Vector3(1.3, 0.14, 1.3), "seat")
	drum(o + Vector3(0, 1.77, 0), 0.5, 0.4, 5.6, "seat", 16)
	for k in range(8):                          # its fluting
		var a: float = TAU * k / 8.0 + 0.2
		bar(o + Vector3(cos(a) * 0.5, 1.9, sin(a) * 0.5), o + Vector3(cos(a) * 0.4, 7.3, sin(a) * 0.4), 0.05, 0.05, 0xb9ad95)
	drum(o + Vector3(0, 7.37, 0), 0.42, 0.72, 0.36, "seat", 12)
	cbox(o + Vector3(0, 7.8, 0), Vector3(1.5, 0.14, 1.5), "seat")
	for k in range(6):
		var a2: float = TAU * k / 6.0
		drum(o + Vector3(cos(a2) * 0.5, 7.87, sin(a2) * 0.5), 0.07, 0.06, 0.9, "seat", 8)
	drum(o + Vector3(0, 8.77, 0), 0.7, 0.7, 0.14, "seat", 12)
	drum(o + Vector3(0, 8.91, 0), 0.62, 0.05, 0.5, "seat", 12)
	ball(o + Vector3(0, 9.5, 0), 0.12, "seat", 1.0, 8, 5)
	solid(Vector3(at.x, 2.0, at.y), Vector3(1.6, 4.0, 1.6))
	yard.append(spot(at.x, at.y))

# ---------------- trees ----------------
func _trunk(at: Vector2, y0: float, tall: float, r: float, hex := 0x8a7460) -> void:
	add_child(Parts.part("cyl", hex, Vector3(at.x, y0 + tall / 2.0, at.y), Vector3(r, tall, r)))
	solid(Vector3(at.x, 1.6, at.y), Vector3(maxf(0.45, r * 2.2), 3.4, maxf(0.45, r * 2.2)))
	yard.append(spot(at.x, at.y))

func _clump(mid: Vector3, size: Vector3, leaf: Material, kind := "ball") -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = Parts.mesh(kind)
	mi.material_override = leaf
	mi.position = mid
	mi.scale = size
	add_child(mi)

## a big shade tree (plane, elm): a tall trunk, a wide crown of a few clumps
func _broad(at: Vector2, tall: float, crown: float, y0 := 0.0) -> void:
	_trunk(at, y0, tall, 0.3)
	var leaf: Material = W._tmat(0x64a84a, "leaf", 1.8)
	for q in [[0.0, 1.5, 0.0, 1.0], [1.5, 0.9, 0.6, 0.72], [-1.3, 1.0, -0.9, 0.7], [0.3, 0.8, -1.6, 0.66], [-0.6, 0.7, 1.5, 0.68], [0.9, 2.2, -0.5, 0.55]]:
		_clump(Vector3(at.x + q[0] * crown / 3.6, y0 + tall + q[1] * crown / 3.6, at.y + q[2] * crown / 3.6), Vector3(crown, crown * 0.8, crown) * q[3], leaf)

## a little tree clipped round, as the ones in the small planters and on the raised pavement are
func _ball_tree(at: Vector2, y0 := 0.0, tall := 2.3, crown := 1.5) -> void:
	_trunk(at, y0, tall, 0.11, 0x7a6450)
	_clump(Vector3(at.x, y0 + tall + crown * 0.55, at.y), Vector3(crown, crown * 0.85, crown), W._tmat(0x5a9a46, "leaf", 1.4))

## a cedar or a fir: dark, in tiers, coming to a point
func _cedar(at: Vector2, tall: float, y0 := 0.0) -> void:
	_trunk(at, y0, tall * 0.35, 0.22, 0x6b5846)
	var leaf: Material = W._tmat(0x3a6844, "leaf", 1.5)
	for k in range(5):
		var f: float = k / 5.0
		_clump(Vector3(at.x, y0 + tall * (0.2 + f * 0.62) + tall * 0.12, at.y), Vector3(lerpf(tall * 0.24, tall * 0.07, f), tall * 0.26, lerpf(tall * 0.24, tall * 0.07, f)), leaf, "cone")

func _cypress(at: Vector2, tall: float, y0 := 0.0, fat := 0.075) -> void:
	_trunk(at, y0, 0.5, 0.09, 0x5d4630)
	var leaf: Material = W._tmat(0x4a6a3c, "leaf", 1.1)
	var r: float = tall * fat
	_clump(Vector3(at.x, y0 + 0.3 + tall * 0.5, at.y), Vector3(r, tall * 0.5, r), leaf)
	_clump(Vector3(at.x, y0 + 0.3 + tall * 0.32, at.y), Vector3(r * 1.1, tall * 0.3, r * 1.1), leaf)

## a stone pine: a long bare trunk that leans, and a flat dark parasol on top
func _pine(at: Vector2, tall: float, lean: Vector2) -> void:
	var last := Vector3(at.x, -0.2, at.y)
	for k in range(1, 7):                       # (its trunk, in lengths that follow its lean; this goes into the place's own mesh)
		var f: float = k / 6.0
		var p := Vector3(at.x + lean.x * f * f, tall * f, at.y + lean.y * f * f)
		var r: float = lerpf(0.44, 0.26, f)
		bar(last, p + (p - last).normalized() * 0.08, r, r, 0x8a6a52, PI / 4.0 if k % 2 == 0 else 0.0)
		last = p
	solid(Vector3(at.x, 1.6, at.y), Vector3(0.55, 3.4, 0.55))
	yard.append(spot(at.x, at.y))
	var top: Vector2 = at + lean
	var leaf: Material = W._tmat(0x3f6b3f, "leaf", 1.6)
	for q in [[0.0, 0.0, 1.0], [1.6, 0.4, 0.7], [-1.4, -0.6, 0.72], [0.4, -1.5, 0.66], [-0.5, 1.5, 0.7]]:
		_clump(Vector3(top.x + q[0], tall + 0.9, top.y + q[1]), Vector3(3.2, 1.25, 3.2) * q[2], leaf)

# ---------------- the playground ----------------
## A fenced circle of soft floor (black posts, two cream boards between each two) with the trunk somebody carved and the
## stone pine that leans over it. What is played on is bought in: Tiny Treats' "Fun Playground" set (Isa Lousberg, CC0),
## readied by tools/blender/parque.py into PLAY_SET -- the tower under its red roof with the slide, on the side of the
## town hall as the real one; swings, a seesaw, a roundabout, two little horses on springs and an arch of rungs.
func _playground() -> void:
	var c := PLAY
	flat(_circle(c, PLAY_R - 0.05, 36), 0.045, "rubber")
	var posts := 40
	for k in range(posts):
		var a0: float = TAU * k / posts
		var a1: float = TAU * (k + 1) / posts
		var p0 := Vector3(c.x + cos(a0) * PLAY_R, 0, c.y + sin(a0) * PLAY_R)
		var p1 := Vector3(c.x + cos(a1) * PLAY_R, 0, c.y + sin(a1) * PLAY_R)
		cbox(p0 + Vector3(0, 0.55, 0), Vector3(0.09, 1.1, 0.09), 0x1f1f22)
		if k == 39 or k == 0:                   # the gate, on the side of the fountain
			continue
		for h in [0.38, 0.8]:
			bar(p0 + Vector3(0, h, 0), p1 + Vector3(0, h, 0), 0.035, 0.16, 0xe8dcb4)
		var mid: Vector3 = (p0 + p1) / 2.0
		solid(Vector3(mid.x, 0.55, mid.z), Vector3(p0.distance_to(p1), 1.1, 0.1), atan2(-(p1.z - p0.z), p1.x - p0.x))
		if k % 8 == 0:
			yard.append(spot(p0.x, p0.z))
	# what is played on: [piece, where (from the middle of the circle), which way its front looks, what of it stops you]
	var kit: Node = (load(PLAY_SET) as PackedScene).instantiate() if ResourceLoader.exists(PLAY_SET) else null
	_toy(kit, "torre", c + Vector2(-2.6, -4.4), Vector2(0.94, 0.34), [[Vector3(0, 1.3, -0.05), Vector3(2.2, 2.6, 2.1)], [Vector3(0, 0.5, 1.75), Vector3(0.9, 1.0, 1.5)]])
	_toy(kit, "columpios", c + Vector2(-5.4, 0.9), Vector2(-0.986, 0.165), [[Vector3(0, 1.1, 0), Vector3(3.3, 2.2, 1.0)]])
	_toy(kit, "balancin", c + Vector2(-0.6, 0.6), Vector2(0.34, 0.94), [[Vector3(0, 0.3, 0), Vector3(0.6, 0.6, 3.0)]])
	_toy(kit, "tiovivo", c + Vector2(3.3, 4.5), Vector2(0.48, 0.88), [[Vector3(0, 0.6, 0), Vector3(1.7, 1.2, 1.7)]])
	_toy(kit, "muelle_a", c + Vector2(2.4, -4.7), Vector2(-0.45, 0.89), [[Vector3(0, 0.5, 0), Vector3(0.45, 1.0, 1.0)]])
	_toy(kit, "muelle_b", c + Vector2(4.2, -3.4), Vector2(-0.8, 0.6), [[Vector3(0, 0.5, 0), Vector3(0.45, 1.0, 1.0)]])
	_toy(kit, "arco", c + Vector2(-3.4, 5.3), Vector2(0.84, 0.54), [[Vector3(0, 0.8, 0), Vector3(1.1, 1.6, 2.2)]])
	if kit != null:
		kit.free()
	# the green board with the rules, on the fence on the side of the bar
	var ba := deg_to_rad(72.0)
	var bx: float = c.x + cos(ba) * (PLAY_R - 0.3)
	var bz: float = c.y + sin(ba) * (PLAY_R - 0.3)
	for s in [-0.45, 0.45]:
		cbox(Vector3(bx - s * sin(ba), 0.9, bz + s * cos(ba)), Vector3(0.07, 1.8, 0.07), 0x5a4632)
	tbox(Transform3D(Basis(Vector3.UP, PI / 2.0 - ba).scaled_local(Vector3(1.1, 0.75, 0.04)), Vector3(bx, 1.45, bz)), 0x6fb86a)
	# the carved trunk: inside the fence, on the side of the bar
	var t := Vector3(c.x - 0.4, 0.0, c.y + 5.9)
	drum(t, 0.48, 0.36, 2.6, 0xd9c8a6, 10)
	drum(t + Vector3(0, 2.6, 0), 0.36, 0.3, 1.6, 0xd2bf9b, 10)
	ball(t + Vector3(0, 4.4, 0), 0.36, 0xd9c8a6, 1.2, 10, 6)
	for q in [[0.3, 1.2, 0.2], [-0.28, 2.0, 0.24], [0.2, 3.1, 0.18]]:
		ball(t + Vector3(q[0], q[1], 0.26), q[2], 0xc9b592, 1.3, 8, 5)
	solid(Vector3(t.x, 2.3, t.z), Vector3(0.9, 4.6, 0.9))
	yard.append(spot(t.x, t.z))
	_pine(Vector2(-12.4, 32.4), 12.0, Vector2(2.8, -0.6))          # (inside the fence too: its crown is the dark mass the aerial photograph shows over the east of the playground)
	_keep_off.append([Vector2(t.x, t.z), Vector2(0.45, 0.45), 0.0])
	_keep_off.append([Vector2(-12.4, 32.4), Vector2(0.3, 0.3), 0.0])
	for i in range(-8, 9):                                          # where a child can stand
		for j in range(-8, 9):
			var q: Vector2 = c + Vector2(i, j) * 1.1
			if q.distance_to(c) < PLAY_R - 1.1 and not _blocked_at(q, 0.7):
				_free.append(q)

## A piece of the bought-in play equipment (a node of the set `kit`) standing on the soft floor at `at`, its front
## (the foot of a slide, a horse's head) towards `front`; `blocks`: what of it stops you, each [middle, size] in the
## piece's own frame. (Without the set -- a copy of the project nobody has imported -- the floor is left bare.)
func _toy(kit: Node, piece: String, at: Vector2, front: Vector2, blocks: Array) -> void:
	var src: Node3D = kit.get_node_or_null(piece) if kit != null else null
	if src == null:
		return
	var turn: float = atan2(front.x, front.y)
	var t := Transform3D(Basis(Vector3.UP, turn), Vector3(at.x, 0.045, at.y))
	var n: Node3D = src.duplicate()
	n.transform = t
	add_child(n)
	for q in blocks:
		var mid: Vector3 = t * (q[0] as Vector3)
		solid(mid, q[1], turn)
		_keep_off.append([Vector2(mid.x, mid.z), Vector2((q[1] as Vector3).x, (q[1] as Vector3).z) / 2.0, turn])
	_toys[piece] = {"node": n, "at": at, "front": front.normalized()}
	yard.append(spot(at.x, at.y))

## whether something on the soft floor stands within `pad` of this spot (local)
func _blocked_at(q: Vector2, pad: float) -> bool:
	for k in _keep_off:
		var rel: Vector2 = q - (k[0] as Vector2)
		var tn: float = k[2]
		var half: Vector2 = k[1]
		if absf(rel.dot(Vector2(cos(tn), -sin(tn)))) < half.x + pad and absf(rel.dot(Vector2(sin(tn), cos(tn)))) < half.y + pad:
			return true
	return false

# ---------------- children in the playground ----------------
## Children play in the playground at the weekend while it is light, and from Monday to Friday from the afternoon until
## it gets dark; not in the rain (the user, through Sistemas, 15 November 2026). They are neighbours like any other --
## you can talk to them, a punch sends them flying -- made once, when the game starts; out of hours they are at home
## (`away`: nothing in the game sees them). They come out and go home only while nobody is looking at the playground,
## so nobody appears out of thin air. While they play they run from one thing to the next and stand about by it,
## hopping now and then; they ride the roundabout, which turns while anybody is on it, and the little horses on springs.
const KIDS := 6
const KID_LOOK := 3.0                 # seconds between looks at the clock
const RIDE_R := 0.72                  # where the roundabout's riders stand, from its middle
const RIDE_UP := 0.22                 # ...and how high its floor is
const HORSE_UP := 0.3                 # how high a rider of the little horses sits (their legs go into the horse)
const SPIN := 1.5                     # how fast the roundabout turns with somebody on it (radians a second)
var _G = null                         # the game, once it is running
var _kids: Array = []                 # {n, do: stand|run|ride|horse, t, way: [local points], then, a, horse, speed, stuck}
var _kids_out := false
var _kid_t := 0.0
var _toys := {}                       # piece -> {node, at (local), front}
var _keep_off: Array = []             # [middle (local), half size, turn] of what stands on the soft floor
var _free: Array = []                 # spots of the soft floor where a child can stand (local)

func _process(dt: float) -> void:
	if _G == null:
		var g = W.get_parent() if W != null else null
		if g == null or not g.get("_booted") or _free.is_empty() or not _toys.has("tiovivo"):
			return
		_G = g
		_make_kids()
	if _G.paused or _G.phase == "title":
		return
	_kid_t -= dt
	if _kid_t <= 0.0:
		_kid_t = KID_LOOK
		var want := _play_time()
		if want != _kids_out and not _watched():
			_kids_out = want
			for k in _kids:
				_send(k, want)
	if not _kids_out or (_G.player.p as Vector2).distance_squared_to(spot(PLAY.x, PLAY.y)) > 90.0 * 90.0:
		return                            # (nobody about to see them: they wait where they are)
	var riding := false
	for k in _kids:
		_kid(k, dt)
		riding = riding or k["do"] == "ride"
	if riding:
		(_toys["tiovivo"]["node"] as Node3D).rotate_object_local(Vector3.UP, dt * SPIN)

## at the weekend while it is light; from Monday to Friday from the afternoon until dark; never in the rain
func _play_time() -> bool:
	var h: float = _G.clock
	if _G.rain > 0.3 or h < _G.SUNRISE + 0.5 or h > _G.SUNSET - 0.25:
		return false
	return int(_G.weekday) >= 5 or _G.moment == "afternoon" or _G.moment == "evening"

## whether anybody would see children come or go: you are by the playground, or it is in front of the camera
func _watched() -> bool:
	var c: Vector2 = spot(PLAY.x, PLAY.y)
	if (_G.player.p as Vector2).distance_to(c) < PLAY_R + 6.0:
		return true
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return false
	for q in [Vector2.ZERO, Vector2(PLAY_R, 0.0), Vector2(-PLAY_R, 0.0), Vector2(0.0, PLAY_R), Vector2(0.0, -PLAY_R)]:
		var m: Vector2 = spot(PLAY.x + q.x, PLAY.y + q.y)
		var at := Vector3(m.x, level + 0.7, m.y)
		if cam.global_position.distance_to(at) < 150.0 and cam.is_position_in_frustum(at):
			return true
	return false

func _make_kids() -> void:
	var kind: int = _G.NEIGHBOUR_VOICES.find("kid")
	for i in range(KIDS):
		var look: Dictionary = _G._neighbour_look("kid")
		look["voice_i"] = kind
		var at: Vector2 = _free[(i * 7) % _free.size()]
		var n = _G.spawn_neighbour(spot(at.x, at.y), true, look)
		n.set_meta("crio", true)
		_kids.append({"n": n, "do": "stand", "t": 1.0, "way": [], "then": "stand", "a": 0.0, "horse": "", "speed": randf_range(2.4, 3.3), "stuck": 0.0})
	_kids_out = _play_time()
	for k in _kids:
		_send(k, _kids_out)

## out to play (standing somewhere on the soft floor), or home
func _send(k: Dictionary, out: bool) -> void:
	var n = k["n"]
	if not is_instance_valid(n):
		return
	n.y = 0.0
	n.inner.rotation.x = 0.0
	n.inner.position.y = 0.0
	n.away = not out
	n.visible = out
	var at: Vector2 = _free.pick_random()
	n.p = spot(at.x, at.y)
	_stand(k)
	if not out:
		n.state = "busy"
	n.sync()

## a map spot in the square's own frame, and a direction of that frame on the map
func _local(m: Vector2) -> Vector2:
	var l: Vector3 = transform.affine_inverse() * Vector3(m.x, level, m.y)
	return Vector2(l.x, l.z)

func _dir(v: Vector2) -> Vector2:
	return spot(v.x, v.y) - spot(0.0, 0.0)

## standing about where they are, by whatever they are nearest (the game keeps them there, and turns them to you)
func _stand(k: Dictionary) -> void:
	var n = k["n"]
	n.y = 0.0
	n.state = "idle"
	n.home = n.p
	k["do"] = "stand"
	k["t"] = randf_range(2.0, 6.0)
	var here: Vector2 = _local(n.p)
	var best := 1e9
	var face := Vector2.ZERO
	for toy in _toys.values():
		var d: float = here.distance_to(toy["at"])
		if d < best:
			best = d
			face = (toy["at"] as Vector2) - here
	if face.length() > 0.1:
		var m: Vector2 = _dir(face)
		n.h = atan2(m.x, m.y)

## what next: a ride on the roundabout, a go on a little horse, or off to somewhere else to stand about
func _next(k: Dictionary) -> void:
	var r := randf()
	var riders := 0
	var taken: Array = []
	for o in _kids:
		if o["do"] == "ride" or (o["do"] == "run" and o["then"] == "ride"):
			riders += 1
		if o["do"] == "horse" or (o["do"] == "run" and o["then"] == "horse"):
			taken.append(o["horse"])
	var go: Vector2 = _free.pick_random()
	k["then"] = "stand"
	if r < 0.35 and riders < 3:
		var a := randf() * TAU
		go = (_toys["tiovivo"]["at"] as Vector2) + Vector2(sin(a), cos(a)) * 1.6
		k["then"] = "ride"
	elif r < 0.6:
		for horse in ["muelle_a", "muelle_b"]:
			if _toys.has(horse) and not taken.has(horse):
				var hz: Dictionary = _toys[horse]
				var fr: Vector2 = hz["front"]
				go = (hz["at"] as Vector2) + Vector2(fr.y, -fr.x) * (0.85 if randf() < 0.5 else -0.85)
				k["then"] = "horse"
				k["horse"] = horse
				break
	_run_to(k, go)

func _run_to(k: Dictionary, go: Vector2) -> void:
	var n = k["n"]
	var way: Array = []
	if _local(n.p).distance_to(PLAY) > PLAY_R - 0.4:             # (outside the fence, after a fall: in by the gate)
		way.append(PLAY + Vector2(PLAY_R + 1.3, 0.0))
		way.append(PLAY + Vector2(PLAY_R - 1.3, 0.0))
	way.append(go)
	k["way"] = way
	k["do"] = "run"
	k["stuck"] = 0.0
	n.state = "busy"

func _kid(k: Dictionary, dt: float) -> void:
	var n = k["n"]
	if not is_instance_valid(n) or n.away:
		return
	if n.state == "fly" or n.state == "down":           # (sent flying: the game picks them up, and they stand there a while)
		k["do"] = "stand"
		k["t"] = 2.0
		return
	if _G.dlg != null and _G.dlg.get("from") == n:        # (you are talking to them: they stop and listen)
		if k["do"] != "stand":
			_off(k)
			_stand(k)
		k["t"] = maxf(float(k["t"]), 2.0)
		return
	match String(k["do"]):
		"stand":
			if n.state != "idle":
				_stand(k)
			k["t"] = float(k["t"]) - dt
			if randf() < dt * 0.3:
				n.hop()
			if float(k["t"]) <= 0.0:
				_next(k)
		"run":
			var way: Array = k["way"]
			if way.is_empty():
				_arrive(k)
				return
			var goal: Vector2 = spot((way[0] as Vector2).x, (way[0] as Vector2).y)
			var gv: Vector2 = goal - n.p
			if gv.length() < 0.35:
				way.pop_front()
				k["stuck"] = 0.0
				return
			var dir: Vector2 = gv.normalized()
			var was: Vector2 = n.p
			var sp: float = k["speed"]
			n.walk(dir, sp)
			n.h = lerp_angle(n.h, atan2(dir.x, dir.y), 1.0 - exp(-10.0 * dt))
			n.anim(true, dt, sp)
			n.sync()
			k["stuck"] = float(k["stuck"]) + dt if n.p.distance_to(was) < sp * dt * 0.3 else 0.0
			if float(k["stuck"]) > 0.8:                # (something in the way: they stop where they are)
				way.clear()
				k["then"] = "stand"
		"ride":
			k["a"] = float(k["a"]) + dt * SPIN
			_ride(k)
			n.anim(false, dt, 0.0)
			n.sync()
			k["t"] = float(k["t"]) - dt
			if float(k["t"]) <= 0.0:
				_off(k)
				_stand(k)
		"horse":
			var hz: Dictionary = _toys[k["horse"]]
			var rock: float = sin(Time.get_ticks_msec() / 1000.0 * 6.0 + float(k["a"]))
			n.p = spot((hz["at"] as Vector2).x, (hz["at"] as Vector2).y)
			n.y = HORSE_UP + absf(rock) * 0.07
			var f: Vector2 = _dir(hz["front"])
			n.h = atan2(f.x, f.y)
			n.inner.rotation.x = rock * 0.12
			n.anim(false, dt, 0.0)
			n.sync()
			k["t"] = float(k["t"]) - dt
			if float(k["t"]) <= 0.0:
				_off(k)
				_stand(k)

## got where they were going: on to the roundabout, on to a horse, or just there
func _arrive(k: Dictionary) -> void:
	var n = k["n"]
	match String(k["then"]):
		"ride":
			var rel: Vector2 = _local(n.p) - (_toys["tiovivo"]["at"] as Vector2)
			var a: float = atan2(rel.x, rel.y)
			for o in _kids:                           # (not on top of somebody already riding)
				if o != k and o["do"] == "ride" and absf(angle_difference(float(o["a"]), a)) < 1.0:
					a = float(o["a"]) + 1.6
			k["a"] = a
			k["do"] = "ride"
			k["t"] = randf_range(6.0, 13.0)
			n.hop()
			_ride(k)
		"horse":
			k["do"] = "horse"
			k["t"] = randf_range(5.0, 10.0)
			k["a"] = randf() * TAU
			n.hop()
		_:
			_stand(k)

## where a rider of the roundabout is: on its floor, going round with it, looking the way it turns
func _ride(k: Dictionary) -> void:
	var n = k["n"]
	var a: float = k["a"]
	var c: Vector2 = _toys["tiovivo"]["at"]
	var q: Vector2 = c + Vector2(sin(a), cos(a)) * RIDE_R
	n.p = spot(q.x, q.y)
	n.y = RIDE_UP
	var f: Vector2 = _dir(Vector2(cos(a), -sin(a)))
	n.h = atan2(f.x, f.y)

## off the roundabout or the horse, on to the floor beside it (out of its way)
func _off(k: Dictionary) -> void:
	var n = k["n"]
	if k["do"] == "ride":
		var a: float = k["a"]
		var q: Vector2 = (_toys["tiovivo"]["at"] as Vector2) + Vector2(sin(a), cos(a)) * 1.6
		n.p = spot(q.x, q.y)
		n.hop()
	elif k["do"] == "horse":
		var hz: Dictionary = _toys[k["horse"]]
		var fr: Vector2 = hz["front"]
		var q: Vector2 = (hz["at"] as Vector2) + Vector2(fr.y, -fr.x) * 0.85
		n.p = spot(q.x, q.y)
		n.inner.rotation.x = 0.0
		n.hop()
	n.y = 0.0

# ---------------- the kiosk bar ----------------
## The bar in the square: a low pavilion of cream walls under a tiled roof, a canvas awning on wooden posts along the
## side that looks at the fountain, barrels for tables. (Its sign says only what it is: BAR.)
func _kiosk() -> void:
	var k := KIOSK
	var x0: float = k.position.x
	var x1: float = k.end.x
	var z0: float = k.position.y
	var z1: float = k.end.y
	var h := 3.0
	var glass := 0x27323a
	# towards the fountain: a door between two wide windows
	var ln := face(Vector2(x1, z1), Vector2(x1, z0))
	var holes: Array = [Rect2(ln / 2.0 - 4.9, 0.95, 3.2, 1.3), Rect2(ln / 2.0 - 0.9, -0.3, 1.8, 2.55), Rect2(ln / 2.0 + 1.7, 0.95, 3.2, 1.3)]
	masonry(0.0, ln, -0.5, h, holes, [], "cream", "cream")
	for r: Rect2 in holes:
		box(r.position.x, maxf(0.0, r.position.y), -DEEP + 0.02, r.size.x, r.end.y - maxf(0.0, r.position.y), 0.03, glass)
		for q in [r.position.x, r.end.x - 0.07, r.position.x + r.size.x / 2.0 - 0.035]:
			box(q, maxf(0.0, r.position.y), -DEEP + 0.05, 0.07, r.end.y - maxf(0.0, r.position.y), 0.05, 0x4a3324)
		if r.position.y > 0.5:
			box(r.position.x - 0.1, r.position.y - 0.08, 0.0, r.size.x + 0.2, 0.08, 0.3, "wood")              # (a shelf to lean on)
	box(0.0, 0.0, 0.0, ln, 0.6, 0.03, 0x8a6a4a)
	box(ln / 2.0 - 1.3, 2.36, 0.0, 2.6, 0.5, 0.05, 0x2a2420)
	_text("BAR", Vector3(ln / 2.0, 2.61, 0.06), 96, 0xf1e9d4, 0.0038)
	home()
	ln = face(Vector2(x1, z0), Vector2(x0, z0))                         # towards the town hall
	holes = [Rect2(3.2, 0.95, 4.0, 1.3)]
	masonry(0.0, ln, -0.5, h, holes, [], "cream", "cream")
	box(3.2, 0.95, -DEEP + 0.02, 4.0, 1.3, 0.03, glass)
	box(0.0, 0.0, 0.0, ln, 0.6, 0.03, 0x8a6a4a)
	home()
	ln = face(Vector2(x0, z1), Vector2(x1, z1))                         # towards the bandstand
	holes = [Rect2(ln - 2.6, -0.3, 1.1, 2.45)]
	masonry(0.0, ln, -0.5, h, holes, [], "cream", "cream")
	box(ln - 2.6, 0.0, -DEEP + 0.03, 1.1, 2.15, 0.04, 0x4a3324)
	box(0.0, 0.0, 0.0, ln - 2.6, 0.6, 0.03, 0x8a6a4a)
	home()
	_plain(Vector2(x0, z0), Vector2(x0, z1), 1.1, h, "brick")                           # (its back, on the edge of the square: red brick over a white foot, from the Arroyuelo)
	_plain(Vector2(x0, z0), Vector2(x0, z1), -0.5, 1.1, "white")
	box(x0 - 0.25, h - 0.02, z0 - 0.25, x1 - x0 + 0.5, 0.16, z1 - z0 + 0.5, 0xe9dfc6)                        # the board under its eaves
	ridge_hex = 0xc9b594
	var tip := _hip(x0, x1, z0, z1, h + 0.14, 1.9, 0.6, (z1 - z0) - (x1 - x0), "tiles_pale")
	ridge_hex = 0xa8623f
	cbox(tip + Vector3(0, 0.3, 0), Vector3(0.05, 0.9, 0.05), IRON)
	solid(Vector3((x0 + x1) / 2.0, 1.6, (z0 + z1) / 2.0), Vector3(x1 - x0, 3.2, z1 - z0))
	for q in [Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)]:
		yard.append(spot(q.x, q.y))
	# the awning along the side of the fountain: canvas on wooden posts, a scalloped edge
	var ax: float = x1 + 2.4
	for pz in [z0 + 0.6, (z0 + z1) / 2.0, z1 - 0.6]:
		cbox(Vector3(ax, 1.25, pz), Vector3(0.12, 2.5, 0.12), "wood")
		solid(Vector3(ax, 1.25, pz), Vector3(0.2, 2.5, 0.2))
		yard.append(spot(ax, pz))
	bar(Vector3(ax, 2.5, z0 + 0.4), Vector3(ax, 2.5, z1 - 0.4), 0.1, 0.12, "wood")
	var canvas := 0xefe6d2
	for side in [1.0, -1.0]:
		quad(Vector3(x1, 2.95, z0 + 0.3), Vector3(x1, 2.95, z1 - 0.3), Vector3(ax + 0.35, 2.55, z1 - 0.3), Vector3(ax + 0.35, 2.55, z0 + 0.3), canvas, Vector3(0.08, 1, 0).normalized() * side)
	for i in range(10):
		var vz: float = lerpf(z0 + 0.3, z1 - 0.3, i / 10.0)
		box(ax + 0.34, 2.3, vz + 0.04, 0.012, 0.25, (z1 - z0 - 0.6) / 10.0 - 0.08, canvas)
	for q in [Vector2(x1 + 0.75, z0 + 2.6), Vector2(x1 + 0.75, z1 - 2.2)]:                # the barrels
		drum(Vector3(q.x, 0.03, q.y), 0.34, 0.4, 0.46, 0x6b4a30, 12)
		drum(Vector3(q.x, 0.49, q.y), 0.4, 0.34, 0.46, 0x6b4a30, 12)
		for by in [0.14, 0.82]:
			drum(Vector3(q.x, by, q.y), 0.385, 0.385, 0.05, 0x2f2f33, 12)
		solid(Vector3(q.x, 0.5, q.y), Vector3(0.8, 1.0, 0.8))
		yard.append(spot(q.x, q.y))
	# The terrace: square striped awnings of different sizes and heights, none quite in line with the next, a table or
	# two under each. props.gd makes every piece (all of it can be knocked about) and stands it on this floor.
	# (The self-test leans on this terrace: it drives a car into the FIRST thing props.gd puts in the town -- the first
	# awning here, which must stay at spot(-12.5, 56.6) -- from six metres to its map-north, and leaves the car there
	# for a dozen checks more. So that way in is kept as it was: nothing else of the terrace within reach of that car
	# (the other awnings four metres off its line, the tables two), nobody standing by it, and nothing solid of the bar
	# in it either: its own awning is short, its barrels by the wall.)
	var first: Vector2 = spot(-12.5, 56.6)
	var along: Vector2 = spot(-11.5, 56.6) - first
	var square: float = atan2(along.x, along.y) + PI / 2.0
	var lay := {"props": [], "gente": []}
	var rng := RandomNumberGenerator.new()
	rng.seed = 1746
	# each: [its middle, its side and the height of its canvas (decimetres), its turn (degrees), its tables: [where, chairs, somebody standing by it]]
	for a in [
			[Vector2(-12.5, 56.6), 40, 28, 7.0, [[Vector2(-13.1, 55.9), 4, false], [Vector2(-11.6, 57.6), 3, false]]],
			[Vector2(-9.9, 51.4), 34, 29, -11.0, [[Vector2(-9.8, 51.5), 4, true]]],
			[Vector2(-10.3, 61.6), 38, 26, -8.0, [[Vector2(-11.0, 60.9), 3, true], [Vector2(-9.5, 62.4), 3, false]]],
			[Vector2(-14.9, 61.4), 36, 30, 5.0, [[Vector2(-14.9, 61.3), 4, true]]],
			[Vector2(-8.3, 57.3), 30, 27, 16.0, [[Vector2(-8.3, 57.3), 2, false]]],
			[Vector2(-13.6, 46.4), 36, 27, -9.0, [[Vector2(-14.3, 45.8), 3, false], [Vector2(-12.9, 47.1), 2, false]]]]:
		var mid: Vector2 = a[0]
		lay["props"].append(["toldo", spot(mid.x, mid.y), square + deg_to_rad(a[3]), 10000 + int(a[1]) * 100 + int(a[2])])      # (10000: red stripes, as this bar's awning always had)
		for tb in a[4]:
			var tp: Vector2 = spot((tb[0] as Vector2).x, (tb[0] as Vector2).y)
			lay["props"].append(["table", tp, rng.randf() * TAU, lay["props"].size()])
			var seats: int = tb[1]
			var a0: float = rng.randf() * TAU
			for seat in range(seats):
				var ang: float = a0 + seat * TAU / seats + rng.randf_range(-0.2, 0.2)
				lay["props"].append(["chair", tp + Vector2(sin(ang), cos(ang)) * rng.randf_range(0.78, 0.95), ang + PI + rng.randf_range(-0.3, 0.3), 0])
			if tb[2]:
				var ga: float = a0 + PI / seats
				lay["gente"].append(tp + Vector2(sin(ga), cos(ga)) * 1.15)
	W.extra_terrazas.append([first, along, lay])

# ---------------- the bandstand ----------------
## The brick bandstand in the corner by the Calle de la Plaza: a floor a metre up, steps to it in the middle of its
## front, planters of flowers at its corners, and at its back three brick arches with iron lattice, each under its
## own little tiled roof, the middle one taller. It looks up the square, a little askew to the town hall.
func _bandstand() -> void:
	var turn: float = PI - STAND_TURN
	var frame := Transform3D(Basis(Vector3.UP, turn), Vector3(STAND.x, 0, STAND.y))
	_xf = frame
	var hw := 5.6
	var hd := 4.0
	var top := 1.0
	box(-hw, -0.4, -hd, 2.0 * hw, top + 0.4 - 0.08, 2.0 * hd, "brick")
	box(-hw - 0.06, top - 0.08, -hd - 0.06, 2.0 * hw + 0.12, 0.08, 2.0 * hd + 0.12, "caliza")
	quad(Vector3(-hw + 0.2, top + 0.004, -hd + 0.2), Vector3(hw - 0.2, top + 0.004, -hd + 0.2), Vector3(hw - 0.2, top + 0.004, hd - 0.2), Vector3(-hw + 0.2, top + 0.004, hd - 0.2), "band", Vector3.UP)
	var going := 0.3
	for k in range(4):                          # five risers up, in the middle of the front
		var sh: float = top * (k + 1) / 5.0
		box(-1.6, -0.2, hd + (3 - k) * going, 3.2, sh + 0.2, going, "caliza")
	for s in [-1.0, 1.0]:                       # a low wall each side of them, and a planter of flowers at each corner
		box(s * 1.6 - (0.0 if s > 0.0 else 0.3), -0.2, hd, 0.3, top + 0.55, 4.0 * going, "brick")
		box(s * (hw - 1.3) - 1.0, top, hd - 0.75, 2.0, 0.5, 0.7, 0xcfccc4)
		box(s * (hw - 1.3) - 0.9, top + 0.46, hd - 0.68, 1.8, 0.06, 0.56, "soil")
		for j in range(6):
			ball(Vector3(s * (hw - 1.3) - 0.75 + j * 0.3, top + 0.62, hd - 0.4 + (0.1 if j % 2 == 0 else -0.1)), 0.13, [0xd8342c, 0xe85a9f, 0xf2c230, 0xffffff, 0x9b5de5, 0xd8342c][j], 1.0, 6, 4)
	# the three arches at the back
	for i in range(3):
		var cx: float = (i - 1) * 2.75
		var tall: float = 3.5 if i == 1 else 2.6
		var r := 0.85
		var z := -hd + 0.5
		for s in [-1.0, 1.0]:
			box(cx + s * (r + 0.25) - 0.25, top, z - 0.3, 0.5, tall, 0.6, "brick")
		box(cx - r, top + tall - r, z - 0.3, 2.0 * r, r + 0.35, 0.6, "brick")                 # (what is over the arch: the arch itself is cut out of it below)
		box(cx - r - 0.5, top + tall + 0.35, z - 0.36, 2.0 * r + 1.0, 0.1, 0.72, "caliza")
		for s in [-1.0, 1.0]:
			roof([Vector3(cx + s * (r + 0.75), top + tall + 0.45, z - 0.5), Vector3(cx, top + tall + 0.95, z - 0.5), Vector3(cx, top + tall + 0.95, z + 0.5), Vector3(cx + s * (r + 0.75), top + tall + 0.45, z + 0.5)])
		slab(PackedVector2Array([Vector2(cx - r - 0.6, top + tall + 0.45), Vector2(cx + r + 0.6, top + tall + 0.45), Vector2(cx, top + tall + 0.9)]), z + 0.3, 0.6, "brick")
		box(cx - r, top, z - 0.02, 2.0 * r, tall - r, 0.04, 0x2c2f36)                           # the iron lattice
		for flip in [false, true]:
			var keep := _xf
			if flip:
				_xf = _xf * Transform3D(Basis(Vector3.UP, PI), Vector3(2.0 * cx, 0, 2.0 * z))
			var half := PackedVector2Array()
			for j in range(13):
				half.append(Vector2(cx + cos(PI * j / 12.0) * r, top + tall - r + sin(PI * j / 12.0) * r))
			slab(half, z + 0.315, 0.0, 0x2c2f36)
			_xf = keep
		for j in range(1, 5):
			box(cx - r + j * 2.0 * r / 5.0 - 0.015, top, z - 0.02, 0.03, tall - 0.2, 0.03, IRON)
		for j in range(1, 4):
			box(cx - r, top + j * (tall - r) / 3.5, z - 0.02, 2.0 * r, 0.03, 0.03, IRON)
	home()
	# the little brick hut in the corner behind it (the public lavatories): a grey door, a tiled lid
	var hut := Vector2(-27.6, 84.6)
	_xf = Transform3D(Basis(Vector3.UP, -0.47), Vector3(hut.x, 0, hut.y))
	box(-1.4, -0.3, -1.3, 2.8, 2.9, 2.6, "brick")
	box(-1.55, 2.6, -1.45, 3.1, 0.12, 2.9, "caliza")
	roof([Vector3(-1.6, 2.72, -1.5), Vector3(1.6, 2.72, -1.5), Vector3(1.6, 3.15, 1.5), Vector3(-1.6, 3.15, 1.5)])
	box(-0.45, 0.0, 1.3, 0.9, 2.05, 0.03, 0x6f757b)
	box(-0.5, 2.1, 1.3, 1.0, 0.26, 0.03, 0xefe9da)
	_text("ASEOS", Vector3(0.0, 2.23, 1.34), 40, 0x2a221c, 0.004)
	home()
	solid(Vector3(hut.x, 1.3, hut.y), Vector3(2.8, 2.9, 2.6), -0.47)
	yard.append(spot(hut.x, hut.y))
	# solid, and a floor to stand on
	var corners: Array = []
	for q in [Vector3(-hw, 0, -hd), Vector3(hw, 0, -hd), Vector3(hw, 0, hd), Vector3(-hw, 0, hd)]:
		var p: Vector3 = frame * q
		corners.append(Vector2(p.x, p.z))
		yard.append(spot(p.x, p.z))
	_prism(corners, -0.4, top)
	var w0: Vector3 = frame * Vector3(-1.6, 0, hd)
	var w1: Vector3 = frame * Vector3(1.6, 0, hd)
	var w2: Vector3 = frame * Vector3(1.6, 0, hd + 4.0 * going)
	var w3: Vector3 = frame * Vector3(-1.6, 0, hd + 4.0 * going)
	_hull([Vector3(w0.x, top, w0.z), Vector3(w1.x, top, w1.z), Vector3(w2.x, 0, w2.z), Vector3(w3.x, 0, w3.z), Vector3(w0.x, -0.4, w0.z), Vector3(w1.x, -0.4, w1.z), Vector3(w2.x, -0.4, w2.z), Vector3(w3.x, -0.4, w3.z)])
	var mid: Vector3 = frame * Vector3(0, 0, hd + 2.0 * going)
	var back: Vector3 = frame.basis * Vector3(0, 0, -1)
	_decks.append({"o": spot(mid.x, mid.z), "ax": spot(back.x, back.z) - spot(0.0, 0.0), "half": 2.0 * going, "wide": 1.6, "top": level + top, "ramp": 4.0 * going, "low": level})
	var pts := PackedVector2Array()
	for q in corners:
		pts.append(q)
	_floor_decks.append(_poly_deck(pts, level + top))

var _floor_decks: Array = []    # level floors (the flights of steps go before them in MapData.decks: they lie over the floors they join)

# ---------------- what stands about the square ----------------
## an iron lamp post of the old Madrid kind: a fat foot, a thin shaft, a square lantern under a little roof
func _lamp(at: Vector2) -> void:
	var o := Vector3(at.x, 0, at.y)
	drum(o, 0.2, 0.15, 0.55, IRON, 10)
	drum(o + Vector3(0, 0.55, 0), 0.085, 0.06, 2.75, IRON, 8)
	drum(o + Vector3(0, 3.3, 0), 0.12, 0.17, 0.14, IRON, 8)
	cbox(o + Vector3(0, 3.72, 0), Vector3(0.3, 0.54, 0.3), 0xfff1c4)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			cbox(o + Vector3(sx * 0.15, 3.72, sz * 0.15), Vector3(0.03, 0.58, 0.03), IRON)
	drum(o + Vector3(0, 4.0, 0), 0.27, 0.04, 0.26, IRON, 8)
	ball(o + Vector3(0, 4.3, 0), 0.05, IRON, 1.0, 6, 4)
	solid(Vector3(at.x, 2.1, at.y), Vector3(0.36, 4.2, 0.36))
	yard.append(spot(at.x, at.y))
	_lamps.append(Vector3(at.x, 3.72, at.y))

func _bin(at: Vector2) -> void:
	drum(Vector3(at.x, 0.03, at.y), 0.22, 0.26, 0.72, 0x3a3d40, 12)
	drum(Vector3(at.x, 0.75, at.y), 0.28, 0.28, 0.05, 0x26262a, 12)
	solid(Vector3(at.x, 0.4, at.y), Vector3(0.5, 0.8, 0.5))
	yard.append(spot(at.x, at.y))

func _furniture() -> void:
	for q in [Vector2(-8.6, 20.6), Vector2(0.5, 22.0), Vector2(13.4, 20.1), Vector2(-27.6, 20.0), Vector2(28.3, 25.2), Vector2(3.3, 41.3), Vector2(10.6, 34.2), Vector2(-5.6, 57.6),
			Vector2(-11.5, 41.6), Vector2(-8.7, 28.4), Vector2(-19.6, 44.6), Vector2(28.5, 36.4), Vector2(29.0, 47.2), Vector2(27.9, 14.4), Vector2(-2.4, 64.8), Vector2(22.4, 62.4), Vector2(-12.2, 66.6)]:
		_lamp(q)
	for q in [Vector2(-7.5, 0.9), Vector2(7.5, 0.9), Vector2(-22.5, 0.9), Vector2(22.5, 0.9), Vector2(-4.6, 57.0), Vector2(9.4, 32.6), Vector2(-9.6, 44.2)]:
		_bin(q)
	# the yellow letter box by the fountain
	var mb := Vector3(3.8, 0, 46.0)
	drum(mb, 0.34, 0.3, 0.14, 0xb98f1a, 12)
	drum(mb + Vector3(0, 0.14, 0), 0.27, 0.27, 0.95, 0xe6b422, 14)
	ball(mb + Vector3(0, 1.09, 0), 0.27, 0xe6b422, 0.55, 14, 5)
	cbox(mb + Vector3(0, 0.92, 0.265), Vector3(0.26, 0.035, 0.02), 0x2a2420)
	solid(Vector3(mb.x, 0.6, mb.z), Vector3(0.6, 1.2, 0.6))
	yard.append(spot(mb.x, mb.z))
	# a drinking fountain by the big steps, and hoops for bicycles by the corner of the town hall
	var df := Vector3(-28.6, 0, 33.2)
	drum(df, 0.16, 0.12, 0.85, 0x3f5a46, 10)
	drum(df + Vector3(0, 0.85, 0), 0.12, 0.2, 0.1, 0x3f5a46, 10)
	cbox(df + Vector3(0.12, 0.98, 0), Vector3(0.14, 0.04, 0.03), 0x8a8f96)
	solid(Vector3(df.x, 0.5, df.z), Vector3(0.4, 1.0, 0.4))
	yard.append(spot(df.x, df.z))
	for k in range(4):
		_hoop(Vector3(25.0 + k * 0.7, 0.0, 4.2), PI / 2.0, 0.35, 0.8)
	solid(Vector3(26.0, 0.4, 4.2), Vector3(2.6, 0.8, 0.8))
	yard.append(spot(26.0, 4.2))
	for p in _lamps:                            # lights.gd lights them at dusk
		W.lamp_spots.append(transform * (p as Vector3))

## The sweets stall: a blue plastic kiosk that only opens in fine weather. (It is shut: shutters down, last summer's
## ice-cream stickers fading on them.)
func _sweets_stall(at: Vector2, turn: float) -> void:
	var st := Node3D.new()
	st.position = Vector3(at.x, 0, at.y)
	st.rotation.y = turn
	add_child(st)
	var blue := 0x2f86d8
	var deep := 0x2470bd
	var put := func(kind: String, hex: int, pos: Vector3, scl: Vector3) -> MeshInstance3D:
		var mi := Parts.part(kind, hex, pos, scl)
		st.add_child(mi)
		return mi
	put.call("box", blue, Vector3(0, 1.2, 0), Vector3(3.1, 2.4, 3.1))
	put.call("box", deep, Vector3(0, 2.5, 0), Vector3(3.5, 0.22, 3.5))                 # the roof, with its lip
	put.call("box", blue, Vector3(0, 2.72, 0), Vector3(2.9, 0.24, 2.9))
	put.call("box", blue, Vector3(0, 2.92, 0), Vector3(2.0, 0.18, 2.0))
	for face_n in range(4):
		var side := Node3D.new()
		side.rotation.y = face_n * PI / 2.0
		st.add_child(side)
		for sx in [-1.0, 1.0]:                                                           # corner posts
			side.add_child(Parts.part("box", deep, Vector3(sx * 1.55, 1.2, 1.56), Vector3(0.14, 2.4, 0.06)))
		side.add_child(Parts.part("box", deep, Vector3(0, 1.2, 1.56), Vector3(0.1, 2.4, 0.05)))            # the shutter's middle
		side.add_child(Parts.part("box", deep, Vector3(0, 1.0, 1.56), Vector3(3.0, 0.08, 0.05)))
		for sx in [-1.0, 1.0]:                                                           # stickers: an ice cream, a biscuit
			var disc := Parts.part("cyl", 0xf4f4f0, Vector3(sx * 0.75, 1.78, 1.575), Vector3(0.3, 0.02, 0.3))
			disc.rotation.x = PI / 2.0
			side.add_child(disc)
			var dot := Parts.part("cyl", 0xd23b3b, Vector3(sx * 0.75, 1.78, 1.59), Vector3(0.17, 0.02, 0.17))
			dot.rotation.x = PI / 2.0
			side.add_child(dot)
			var pic := Parts.part("cyl", 0x1f4f95, Vector3(sx * 0.75, 0.55, 1.575), Vector3(0.38, 0.02, 0.3))
			pic.rotation.x = PI / 2.0
			side.add_child(pic)
			var biscuit := Parts.part("cyl", 0xc98e4a, Vector3(sx * 0.75, 0.55, 1.59), Vector3(0.2, 0.02, 0.16))
			biscuit.rotation.x = PI / 2.0
			side.add_child(biscuit)
	var sign := Label3D.new()
	sign.text = "CHUCHES · HELADOS\nABIERTO SI HACE BUENO"
	sign.font_size = 54
	sign.pixel_size = 0.0042
	sign.modulate = Color("f4f4f0")
	sign.outline_size = 0
	sign.shaded = true
	sign.position = Vector3(0, 2.5, 1.76)
	st.add_child(sign)
	solid(Vector3(at.x, 1.3, at.y), Vector3(3.3, 2.6, 3.3), turn)
	yard.append(spot(at.x, at.y))

# ---------------- the side of the Arroyuelo ----------------
## The old stream bed runs a good two metres below the square (the bake cuts the street down: SUNK). What holds the
## square up on that side, as the user's photos of 12 November 2026 and Street View show it: a raised pavement of
## chequered tiles on a rubble wall, its kerb painted yellow and grey, iron hoops along its edge, little clipped trees
## on it; behind it the white wall of the square with its railing; a wide flight of steps up to the square by the
## steel bridge, and a narrow one at the end of the town hall that comes up into its covered walk through the arch
## there; a few steps up from the street in front of each.
const PAV := 0.8                # the raised pavement, above the street (the steel bridge's deck is at the same height)
const KERB: Array = [Vector2(-34.45, -4.0), Vector2(-35.45, 40.0), Vector2(-38.15, 90.0)]       # the line of its rubble wall
const BIG_STAIRS := Vector2(35.0, 42.0)         # (n) the wide flight up to the square
const END_STAIRS := Vector2(-2.95, -0.65)       # the narrow one into the covered walk
const ROAD_STEPS: Array = [Vector2(36.5, 40.5), Vector2(-3.4, -0.2)]      # steps up from the street
const BRIDGE_GAP := Vector2(31.9, 34.5)         # where the steel bridge comes ashore (pasarela.gd)
const RISERS := 6

func _kerb_u(n: float) -> float:
	for k in range(KERB.size() - 1):
		var a: Vector2 = KERB[k]
		var b: Vector2 = KERB[k + 1]
		if n <= b.y or k == KERB.size() - 2:
			return lerpf(a.x, b.x, (n - a.y) / (b.y - a.y))
	return KERB[KERB.size() - 1].x

func _in(n: float, span: Vector2) -> bool:
	return n > span.x and n < span.y

func _sunk_side() -> void:
	var sq := _outline()
	var whole := PackedVector2Array([Vector2(-HALF, -ARCADE), Vector2(HALF, -ARCADE), Vector2(HALF, 0.0), sq[2], sq[3], sq[4], sq[5], Vector2(EDGE, 0.0), Vector2(-HALF, 0.0)])
	if _low > -0.6:
		return                  # (a map baked before the street was sunk: the square is at street level, as it was)
	var pav: float = _low + PAV
	var u_axis: Vector2 = spot(1.0, 0.0) - spot(0.0, 0.0)
	var n_axis: Vector2 = spot(0.0, 1.0) - spot(0.0, 0.0)
	var k0: Vector2 = KERB[0]
	var k1: Vector2 = KERB[1]
	var k2: Vector2 = KERB[2]

	# --- the raised pavement, its rubble wall, and a ramp down to the street at each end ---
	var floor_pts := PackedVector2Array([k0, k1, k2, Vector2(EDGE, SW_END), Vector2(EDGE, 0.0), Vector2(-HALF, 0.0), Vector2(-HALF, k0.y)])
	flat(floor_pts, pav, "tiling")
	for k in range(KERB.size() - 1):
		var a: Vector2 = KERB[k]
		var b: Vector2 = KERB[k + 1]
		quad(Vector3(a.x, _low - 0.5, a.y), Vector3(b.x, _low - 0.5, b.y), Vector3(b.x, pav, b.y), Vector3(a.x, pav, a.y), "rubble", Vector3(-1, 0, 0))
	var run := 2.8
	var north: Array = [Vector3(k0.x, pav, k0.y), Vector3(-HALF, pav, k0.y), Vector3(-HALF, _low + 0.03, k0.y - run), Vector3(k0.x, _low + 0.03, k0.y - run)]
	var south: Array = [Vector3(k2.x, pav, k2.y), Vector3(EDGE, pav, SW_END), Vector3(EDGE, _low + 0.03, SW_END + run), Vector3(k2.x, _low + 0.03, k2.y + run)]
	for ramp in [north, south]:
		quad(ramp[0], ramp[1], ramp[2], ramp[3], "tiling", Vector3.UP)
		tri(ramp[0], ramp[3], Vector3((ramp[0] as Vector3).x, _low - 0.5, (ramp[0] as Vector3).z), "rubble", Vector3(-1, 0, 0))
		var r0: Vector3 = ramp[0]
		var r1: Vector3 = ramp[1]
		var r2: Vector3 = ramp[2]
		var r3: Vector3 = ramp[3]
		var ext: Vector3 = (r3 - r0)
		ext.y = 0.0
		ext = ext.normalized() * 0.4
		var f2 := r2 + ext
		var f3 := r3 + ext
		f2.y = minf(_low, ground(f2.x, f2.z)) - 0.05
		f3.y = minf(_low, ground(f3.x, f3.z)) - 0.05
		var rbot := minf(_low, minf(f2.y, f3.y)) - 0.5
		_hull([r0, r1, f2, f3, Vector3(r0.x, rbot, r0.z), Vector3(r1.x, rbot, r1.z), Vector3(f2.x, rbot, f2.z), Vector3(f3.x, rbot, f3.z)])
	_prism([k0, k1, Vector2(EDGE, k1.y), Vector2(EDGE, 0.0), Vector2(-HALF, 0.0), Vector2(-HALF, k0.y)], _low - 0.3, pav)
	_prism([k1, k2, Vector2(EDGE, SW_END), Vector2(EDGE, k1.y)], _low - 0.3, pav)
	_decks.append({"o": spot((k0.x - HALF) / 2.0, k0.y - run / 2.0), "ax": n_axis, "half": run / 2.0 + 0.3, "wide": (-HALF - k0.x) / 2.0, "top": level + pav, "ramp": run, "low": level + _low})
	_decks.append({"o": spot((k2.x + EDGE) / 2.0, k2.y + run / 2.0), "ax": -n_axis, "half": run / 2.0 + 0.3, "wide": (EDGE - k2.x) / 2.0, "top": level + pav, "ramp": run, "low": level + _low})

	# --- its kerb, yellow and grey by turns; iron hoops along it, except where steps or the steel bridge come up ---
	var n: float = k0.y
	var count := 0
	while n < k2.y - 0.01:
		var mid: float = n + 0.5
		var ku: float = _kerb_u(mid)
		cbox(Vector3(ku + 0.13, pav - 0.05, mid), Vector3(0.28, 0.14, 1.0), 0xe6b422 if count % 2 == 0 else 0x8f8a80)
		var open: bool = _in(mid, BRIDGE_GAP)
		for s: Vector2 in ROAD_STEPS:
			open = open or _in(mid, s)
		if not open:
			_hoop(Vector3(ku + 0.3, pav, mid), PI / 2.0)
			solid(Vector3(ku + 0.07, _low + (PAV + 0.95) / 2.0, mid), Vector3(0.14, PAV + 0.95, 1.0))
		n += 1.0
		count += 1

	# --- steps up from the street to the pavement ---
	for s: Vector2 in ROAD_STEPS:
		var mid: float = (s.x + s.y) / 2.0
		var ku: float = _kerb_u(mid)
		for k in range(3):
			var hgt: float = PAV * (k + 1) / 4.0
			cbox(Vector3(ku - (2.5 - k) * 0.3, _low + hgt / 2.0, mid), Vector3(0.3, hgt, s.y - s.x), "caliza")
		var f_u := ku - 1.25
		var fy0 := minf(_low, ground(f_u, s.x)) - 0.05
		var fy1 := minf(_low, ground(f_u, s.y)) - 0.05
		var sbot := minf(_low, minf(fy0, fy1)) - 0.5
		_hull([Vector3(ku + 0.15, pav, s.x), Vector3(ku + 0.15, pav, s.y), Vector3(f_u, fy1, s.y), Vector3(f_u, fy0, s.x),
			Vector3(ku + 0.15, sbot, s.x), Vector3(ku + 0.15, sbot, s.y), Vector3(f_u, sbot, s.y), Vector3(f_u, sbot, s.x)])
		_decks.append({"o": spot(ku - 0.45, mid), "ax": u_axis, "half": 0.75, "wide": (s.y - s.x) / 2.0, "top": level + pav, "ramp": 1.1, "low": level + _low})

	# --- the flights up from the pavement: to the square, and into the covered walk of the town hall ---
	var rise: float = -pav / RISERS
	var going := 0.3
	var flight: float = going * (RISERS - 1)
	for q in [[BIG_STAIRS, EDGE], [END_STAIRS, -HALF]]:
		var span: Vector2 = q[0]
		var top_u: float = q[1]
		var mid: float = (span.x + span.y) / 2.0
		for k in range(RISERS - 1):
			var deep: float = (RISERS - 1 - k) * going
			cbox(Vector3(top_u - deep / 2.0, pav + rise * (k + 1) / 2.0, mid), Vector3(deep, rise * (k + 1), span.y - span.x), "caliza")
		for side in [span.x, span.y]:           # a handrail down each side
			bar(Vector3(top_u - flight, pav + 0.95, side), Vector3(top_u, 0.95, side), 0.05, 0.05, IRON)
			cbox(Vector3(top_u - flight, pav + 0.5, side), Vector3(0.05, 1.0, 0.05), IRON)
			cbox(Vector3(top_u, 0.5, side), Vector3(0.05, 1.0, 0.05), IRON)
		var fu := top_u - flight - 0.3
		_hull([Vector3(top_u + 0.2, 0.0, span.x), Vector3(top_u + 0.2, 0.0, span.y), Vector3(fu, pav - 0.04, span.y), Vector3(fu, pav - 0.04, span.x),
			Vector3(top_u + 0.2, pav - 0.5, span.x), Vector3(top_u + 0.2, pav - 0.5, span.y), Vector3(fu, pav - 0.5, span.y), Vector3(fu, pav - 0.5, span.x)])
		_decks.append({"o": spot(top_u - flight / 2.0, mid), "ax": u_axis, "half": flight / 2.0 + 0.25, "wide": (span.y - span.x) / 2.0, "top": level, "ramp": flight, "low": level + pav})

	# --- the wall that holds the square up, wherever the ground outside is lower: white, a low parapet, a railing ---
	var centre := Vector2(0.0, 35.0)
	for k in range(1, sq.size()):
		var a: Vector2 = sq[k]
		var b: Vector2 = sq[(k + 1) % sq.size()]
		var d: Vector2 = (b - a).normalized()
		var out := Vector2(d.y, -d.x)
		if out.dot((a + b) / 2.0 - centre) < 0.0:
			out = -out
		var turn: float = atan2(-d.y, d.x)
		var count_p: int = maxi(1, int(ceil(a.distance_to(b) / 1.5)))
		var pl: float = a.distance_to(b) / count_p
		var on_edge: bool = absf(a.x - EDGE) < 0.01 and absf(b.x - EDGE) < 0.01
		for j in range(count_p):
			var mid: Vector2 = a + d * (j + 0.5) * pl
			if on_edge and _in(mid.y, BIG_STAIRS):
				continue
			var h: float = MapData.height(spot(mid.x + out.x * 0.6, mid.y + out.y * 0.6)) - level
			if h > -0.12:
				continue
			var at: Vector2 = mid - out * 0.13
			var foot_y: float = h - 0.4
			var p0: Vector2 = at - d * (pl / 2.0 + 0.01)
			var p1: Vector2 = at + d * (pl / 2.0 + 0.01)
			bar(Vector3(p0.x, (0.35 + foot_y) / 2.0, p0.y), Vector3(p1.x, (0.35 + foot_y) / 2.0, p1.y), 0.26, 0.35 - foot_y, "white")
			yard.append(spot(at.x, at.y))
			if h > -0.6:
				continue
			bar(Vector3(p0.x, 1.07, p0.y), Vector3(p1.x, 1.07, p1.y), 0.05, 0.05, IRON)
			bar(Vector3(p0.x, 0.71, p0.y), Vector3(p1.x, 0.71, p1.y), 0.035, 0.035, IRON)
			cbox(Vector3(p0.x, 0.72, p0.y), Vector3(0.05, 0.74, 0.05), IRON)
			solid(Vector3(at.x, (1.1 + h) / 2.0, at.y), Vector3(pl + 0.02, 1.1 - h, 0.26), turn)

	# --- little clipped trees on the raised pavement, each in its square of earth ---
	for tn in [8.5, 16.5, 24.5, 44.6]:
		var tu: float = _kerb_u(tn) + 1.5
		flat(PackedVector2Array([Vector2(tu - 0.5, tn - 0.5), Vector2(tu + 0.5, tn - 0.5), Vector2(tu + 0.5, tn + 0.5), Vector2(tu - 0.5, tn + 0.5)]), pav + 0.008, "soil")
		_ball_tree(Vector2(tu, tn), pav, 2.4, 1.6)

	# --- floors: the square itself (the ground under its west side has gone down with the street), and the pavement ---
	# (solid all the way down to under the street: a thin floor leaves a hollow between itself and the sunk ground, and
	# whatever is put down at ground level there -- car.place() knows only the ground -- is caught between the two)
	_prism([Vector2(EDGE, 0.0), Vector2(16.0, 0.0), Vector2(16.0, 67.7), Vector2(EDGE, SW_END)], _low - 0.6, 0.0)
	_prism([Vector2(-HALF, -ARCADE), Vector2(16.0, -ARCADE), Vector2(16.0, 0.0), Vector2(-HALF, 0.0)], _low - 0.6, 0.0)
	_floor_decks.append(_poly_deck(floor_pts, level + pav))
	_floor_decks.append(_poly_deck(whole, level))
