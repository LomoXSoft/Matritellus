extends "res://scripts/obra.gd"
## The roundabout before the Tricornios' barracks (the user, 17 November 2026: "Vamos a trabajar en esta rotonda ...
## han construido varias cosas dentro en los últimos años. Como una bandera gigante y un monolito tributo a la guardia
## civil (tricornios). El monolito de piedra tiene el escudo en metal forjado arriba y una placa conmemorativa con el
## escudo del pueblo y de la guardia civil de nuevo"), where the Avenida de la Constitución, the Avenida de Martín
## Descalzo, the Calle del Santo and the Calle de Víctor Pradera meet. Built by hand from Street View (November 2024:
## the island as it was before the flag) and the user's photos of the flag and the monolith.
##
## A round island behind a kerb painted red and white: white gravel, beds of dark bark along its west side, rounded
## green bushes, small trees of purple leaf, the black hoses of its watering; the tall grey mast of its two lamps in the
## middle; the blue signs of the roundabout at its edge. Beside the mast the white pole of the great flag, and before
## it the monolith of granite looking south, to the barracks: the Tricornios' emblem in wrought iron on top (ours: a
## crown over the tricorn of their badge, a sword and a baton crossed behind it), the plaque with the town's crest and
## their badge, a bed of red and yellow flowers before it and two big bushes either side.
##
## No rebake: the island is the inside of the ring road the map already has there (its middle and size are read from
## that ring at load time); an apron of asphalt covers what the world drew there (a pale ring round a patch of sand).
## The island lies on the ground as the relief has it, cut along the relief's facets (as toledano.gd). Frame: map metres
## from the island's middle, north up the map (-z); y = 0 the ground there.

const NEAR := Vector2(25.5, -566.2)          # where to look for the ring
const R := 6.0                               # the island's radius, to the outside of its kerb (the orthophoto)
const KERB := 0.15
const STEP := 0.4
const MAST := Vector2(25.61, -566.30)        # the lamps' mast (four cameras' bearings agree to 25 cm)
const POLE := Vector2(27.1, -565.95)         # the flag's pole: beside the mast, to the east (the user's photos)
const FACE := 165.0                          # the monolith looks south-south-east, to the barracks (bearing, degrees)
const POLE_H := 16.0
const FLAG := Vector2(3.6, 2.4)
const MAST_H := 10.2
const RED := 0xc0392b
const WHITE := 0xf0eee8
const PURPLE := 0x74403e
const Y_SIGN := 0.68                         # the blue signs' middle, over the island
const SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D tex : source_color;
uniform float amp = 0.32;
void vertex() {
	float t = UV.x;
	VERTEX.z += sin(UV.x * 7.0 - TIME * 3.1) * amp * t + sin(UV.y * 3.0 + TIME * 1.7) * 0.05 * t;
	VERTEX.y -= t * t * 0.25;
}
void fragment() {
	ALBEDO = texture(tex, UV).rgb;
	ROUGHNESS = 1.0;
}
"""

var mid := Vector2.ZERO                      # the island's middle, on the map
var outline := PackedVector2Array()          # its kerb's outside
var ring_r := 0.0                            # the ring road's middle line, its radius
var ring_hw := 0.0                           # ...and its half width
var things: Array = []                       # where what stands on it is, on the map (the self-test)
var decks := 0
var lamps: Array = []                        # its two lamps, in the world
var flag: MeshInstance3D
var mono := Vector2.ZERO                     # the monolith, on the map
var _look := Vector2.ZERO                    # the way it looks

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"grava", "mantillo":
			var gm := StandardMaterial3D.new()
			gm.albedo_texture = load("res://assets/rotonda/" + String(key) + ".png")
			gm.uv1_triplanar = true
			gm.uv1_world_triplanar = true
			gm.uv1_scale = Vector3.ONE / (1.2 if key == "grava" else 1.6)
			gm.roughness = 1.0
			m = gm
		"asfalto":
			m = W._tmat(0x77727a, "asphalt", 3.0)
		"bordillo":
			m = Tex.mat("granular_concrete", Color(0.8, 0.8, 0.78))
		"granito":
			m = Tex.mat("granular_concrete", Color(0.98, 0.98, 0.97))
		"seto":
			m = W._tmat(0x3f6a34, "leaf", 1.1)
		"seto2":
			m = W._tmat(0x557a3a, "leaf", 1.3)
		"morado":
			m = W._tmat(PURPLE, "leaf", 1.2)
		"placa":
			var pm := StandardMaterial3D.new()
			pm.albedo_texture = load("res://assets/rotonda/placa.png")
			pm.roughness = 0.6
			m = pm
		"emblema":
			var em := StandardMaterial3D.new()
			em.albedo_texture = load("res://assets/rotonda/emblema.png")
			em.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			em.alpha_scissor_threshold = 0.5
			em.cull_mode = BaseMaterial3D.CULL_DISABLED
			em.metallic = 0.4
			em.roughness = 0.55
			m = em
		"foco":
			var fm := StandardMaterial3D.new()
			fm.albedo_color = Color(1.0, 0.98, 0.92)
			fm.emission_enabled = true
			fm.emission = Color(1.0, 0.96, 0.86)
			fm.emission_energy_multiplier = 1.5
			m = fm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> bool:
	W = world
	if not _ring():
		return false
	level = MapData.height(mid)
	transform = Transform3D(Basis.IDENTITY, Vector3(mid.x, level, mid.y))
	W.add_child(self)
	for i in range(48):
		outline.append(mid + Vector2(cos(TAU * i / 48.0), sin(TAU * i / 48.0)) * R)
	var b := deg_to_rad(FACE)
	_look = Vector2(sin(b), -cos(b))
	mono = POLE + _look * 0.6
	_floor()
	_kerb()
	_walkable()
	_beds()
	_mast()
	_pole()
	_monolith()
	_plants()
	_hoses()
	_signs()
	home()
	_commit()
	return true

## The ring road of the map round NEAR: the island's middle is the middle of its nodes
func _ring() -> bool:
	for r in MapData.roads:
		var p: PackedInt32Array = r["p"]
		if int(r["k"]) != 0 or p.size() < 8 or p[0] != p[p.size() - 1]:
			continue
		var c := Vector2.ZERO
		for i in range(p.size() - 1):
			c += (MapData.nodes[p[i]] as Vector2) / (p.size() - 1)
		if c.distance_to(NEAR) > 6.0:
			continue
		var rr := 0.0
		for i in range(p.size() - 1):
			rr += (MapData.nodes[p[i]] as Vector2).distance_to(c) / (p.size() - 1)
		mid = c
		ring_r = rr
		ring_hw = float(r["w"]) / 2.0
		return true
	return false

# ---------------- laying things on the ground (as toledano.gd) ----------------
func _ccw(p: PackedVector2Array) -> PackedVector2Array:
	if Geometry2D.is_polygon_clockwise(p):
		p.reverse()
	return p

func _p3(q: Vector2, lift: float) -> Vector3:
	return Vector3(q.x - mid.x, MapData.height(q) - level + lift, q.y - mid.y)

func _gy(q: Vector2) -> float:
	return MapData.height(q) - level + KERB

func _facets(box: Rect2) -> Array:
	var out: Array = []
	var g: float = MapData.rg
	for i in range(int(floor((box.position.x - MapData.rx0) / g)), int(floor((box.end.x - MapData.rx0) / g)) + 1):
		for j in range(int(floor((box.position.y - MapData.rz0) / g)), int(floor((box.end.y - MapData.rz0) / g)) + 1):
			var a := Vector2(MapData.rx0 + i * g, MapData.rz0 + j * g)
			out.append(_ccw(PackedVector2Array([a, a + Vector2(g, 0), a + Vector2(g, g)])))
			out.append(_ccw(PackedVector2Array([a, a + Vector2(g, g), a + Vector2(0, g)])))
	return out

func _box_of(poly: PackedVector2Array) -> Rect2:
	var box := Rect2(poly[0], Vector2.ZERO)
	for q in poly:
		box = box.expand(q)
	return box

## a flat piece of this outline (on the map) laid on the ground `lift` over it, cut along the relief's facets
func _lay(poly: PackedVector2Array, lift: float, key) -> void:
	if poly.size() < 3:
		return
	pieces += 1
	poly = _ccw(poly)
	for facet: PackedVector2Array in _facets(_box_of(poly)):
		for piece in Geometry2D.intersect_polygons(poly, facet):
			if piece.size() < 3 or Geometry2D.is_polygon_clockwise(piece):
				continue
			var idx := Geometry2D.triangulate_polygon(piece)
			for t in range(0, idx.size(), 3):
				tri(_p3(piece[idx[t]], lift), _p3(piece[idx[t + 1]], lift), _p3(piece[idx[t + 2]], lift), key, Vector3.UP)

## a piece of a ring round the middle: from radius r0 to r1, from bearing a0 to a1 (radians, map angles)
func _band(r0: float, r1: float, a0: float, a1: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := maxi(2, int(ceil((a1 - a0) / 0.12)))
	for i in range(n + 1):
		var a: float = lerpf(a0, a1, float(i) / n)
		pts.append(mid + Vector2(cos(a), sin(a)) * r1)
	for i in range(n, -1, -1):
		var a: float = lerpf(a0, a1, float(i) / n)
		pts.append(mid + Vector2(cos(a), sin(a)) * r0)
	return pts

# ---------------- the island ----------------
## the apron of asphalt round it, the gravel over it
func _floor() -> void:
	for k in range(12):
		_lay(_band(R - 0.1, R + 2.6, TAU * k / 12.0, TAU * (k + 1) / 12.0), 0.006, "asfalto")
	var inner := PackedVector2Array()
	for i in range(48):
		inner.append(mid + Vector2(cos(TAU * i / 48.0), sin(TAU * i / 48.0)) * (R - 0.22))
	_lay(inner, KERB - 0.01, "grava")

## the kerb: its top and its face painted in turns of red and white, following the ground; and what stops a car, with
## a chamfer so that it rides up on to it rather than into it
func _kerb() -> void:
	var n := 42
	for k in range(n):
		var a0: float = TAU * k / n
		var a1: float = TAU * (k + 1) / n
		var key = RED if k % 2 == 0 else WHITE
		_lay(_band(R - 0.24, R, a0, a1), KERB + 0.002, key)
		var p := mid + Vector2(cos(a0), sin(a0)) * R
		var q := mid + Vector2(cos(a1), sin(a1)) * R
		var out := Vector3(cos((a0 + a1) / 2.0), 0, sin((a0 + a1) / 2.0))
		quad(_p3(p, -0.12), _p3(q, -0.12), _p3(q, KERB), _p3(p, KERB), key, out)
	var pts: Array = []
	for q in outline:
		pts.append(_p3(q, KERB))
		pts.append(_p3(q, -1.0))
	for i in range(48):
		var q := mid + Vector2(cos(TAU * i / 48.0), sin(TAU * i / 48.0)) * (R + 0.3)
		pts.append(_p3(q, 0.0))
		pts.append(_p3(q, -1.0))
	_hull(pts)

## whoever walks on it stands on its floor: one sloping deck for each facet of the relief under it
func _walkable() -> void:
	var wide := PackedVector2Array()
	for i in range(48):
		wide.append(mid + Vector2(cos(TAU * i / 48.0), sin(TAU * i / 48.0)) * (R + STEP))
	wide = _ccw(wide)
	for facet: PackedVector2Array in _facets(_box_of(wide)):
		var pa: Vector2 = facet[0] * 0.98 + (facet[1] + facet[2]) * 0.01
		var pb: Vector2 = facet[1] * 0.98 + (facet[0] + facet[2]) * 0.01
		var pc: Vector2 = facet[2] * 0.98 + (facet[0] + facet[1]) * 0.01
		var ha: float = MapData.height(pa)
		var v1: Vector2 = pb - pa
		var v2: Vector2 = pc - pa
		var hb: float = MapData.height(pb) - ha
		var hc: float = MapData.height(pc) - ha
		var det: float = v1.x * v2.y - v1.y * v2.x
		var grad := Vector2((hb * v2.y - hc * v1.y) / det, (v1.x * hc - v2.x * hb) / det)
		for piece in Geometry2D.intersect_polygons(wide, facet):
			if piece.size() < 3 or Geometry2D.is_polygon_clockwise(piece):
				continue
			var o := Vector2.ZERO
			for q in piece:
				o += q / piece.size()
			var r2 := 0.0
			for q in piece:
				r2 = maxf(r2, o.distance_squared_to(q))
			MapData.decks.append({"o": o, "poly": piece, "r2": r2 + 1.0, "top": ha + grad.dot(o - pa) + KERB, "grad": grad})
			decks += 1

## the beds of dark bark along the west side, inside the kerb, and round the flowers
func _beds() -> void:
	_lay(_band(R - 1.5, R - 0.24, deg_to_rad(110.0), deg_to_rad(250.0)), KERB + 0.008, "mantillo")
	_lay(_band(1.0, 2.2, deg_to_rad(200.0), deg_to_rad(250.0)), KERB + 0.008, "mantillo")

func _stand(at: Vector2) -> Vector3:
	things.append(at)
	yard.append(at)
	return Vector3(at.x - mid.x, _gy(at), at.y - mid.y)

# ---------------- what stands on it ----------------
## the mast of galvanised steel, its two lamps on short arms at the top (lights.gd lights them at dusk)
func _mast() -> void:
	var o := _stand(MAST)
	drum(o - Vector3(0, 0.05, 0), 0.24, 0.24, 0.1, 0x8a8d90, 10)
	drum(o, 0.11, 0.065, MAST_H, 0x9aa0a4, 10)
	for s in [-1.0, 1.0]:
		var tip := o + Vector3(0.25 * s, MAST_H + 0.25, -0.55 * s)
		bar(o + Vector3(0, MAST_H - 0.1, 0), tip, 0.06, 0.06, 0x9aa0a4)
		var head := Transform3D(Basis(Vector3.UP, atan2(0.25 * s, -0.55 * s)).rotated(Vector3(-s * 0.9, 0, 0.4).normalized(), 0.25), tip)
		tbox(head * Transform3D(Basis.from_scale(Vector3(0.36, 0.08, 0.62)), Vector3(0, 0, 0.2)), 0x6a6d70)
		tbox(head * Transform3D(Basis.from_scale(Vector3(0.3, 0.02, 0.52)), Vector3(0, -0.05, 0.2)), "foco")
		var w: Vector3 = transform * (head * Vector3(0, -0.1, 0.2))
		W.lamp_spots.append(w)
		lamps.append(w)
	solid(o + Vector3(0, 2.0, 0), Vector3(0.3, 4.0, 0.3))

## the white pole of the great flag, its gilt ball, and the flag flying from it (a cloth that moves)
func _pole() -> void:
	var o := _stand(POLE)
	drum(o - Vector3(0, 0.02, 0), 0.32, 0.32, 0.08, 0xd9d6cc, 12)
	drum(o, 0.11, 0.06, POLE_H, 0xf6f5f0, 12)
	ball(o + Vector3(0, POLE_H + 0.1, 0), 0.12, 0xd9b84a, 1.0, 10, 6)
	solid(o + Vector3(0, 2.0, 0), Vector3(0.3, 4.0, 0.3))
	var mesh := QuadMesh.new()
	mesh.size = FLAG
	mesh.subdivide_width = 18
	mesh.subdivide_depth = 6
	var sm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SHADER
	sm.shader = sh
	sm.set_shader_parameter("tex", load("res://assets/rotonda/bandera.png"))
	flag = MeshInstance3D.new()
	flag.mesh = mesh
	flag.material_override = sm
	var holder := Node3D.new()
	holder.position = o + Vector3(0, POLE_H - 0.25 - FLAG.y / 2.0, 0)
	holder.rotation.y = PI * 0.92                    # (it flies out to the west)
	flag.position = Vector3(FLAG.x / 2.0 + 0.08, 0, 0)
	holder.add_child(flag)
	add_child(holder)
	for y in [POLE_H - 0.25, POLE_H - 0.25 - FLAG.y]:          # its two cords to the pole
		cbox(o + Vector3(0, y, 0), Vector3(0.24, 0.03, 0.03), 0xd9d6cc)

## The monolith: a block of pale granite on a plinth, the plaque on its face, the emblem of wrought iron on top,
## looking the same way.
func _monolith() -> void:
	var o := _stand(mono)
	var keep := _xf
	_xf = Transform3D(Basis(Vector3(_look.y, 0, -_look.x), Vector3.UP, Vector3(_look.x, 0, _look.y)), o)      # (x to its right as you read it: not a mirror)
	box(-0.42, -0.05, -0.32, 0.84, 0.12, 0.64, "granito")
	box(-0.37, 0.07, -0.27, 0.74, 1.38, 0.54, "granito")
	box(-0.39, 1.45, -0.29, 0.78, 0.04, 0.58, "granito")
	quad(Vector3(-0.25, 0.86, 0.277), Vector3(0.25, 0.86, 0.277), Vector3(0.25, 1.185, 0.277), Vector3(-0.25, 1.185, 0.277), "placa", Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	box(-0.26, 0.85, 0.27, 0.52, 0.345, 0.004, 0x3a3024)
	# the emblem: a cut-out of iron, three sheets thick, on a short iron foot
	box(-0.04, 1.49, -0.04, 0.08, 0.12, 0.08, IRON)
	var e0 := Vector3(-0.42, 1.55, 0.0)
	for z in [-0.012, 0.0, 0.012]:
		quad(e0 + Vector3(0, 0, z), e0 + Vector3(0.84, 0, z), e0 + Vector3(0.84, 0.92, z), e0 + Vector3(0, 0.92, z), "emblema", Vector3(0, 0, 1),
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	_xf = keep
	solid(o + Vector3(0, 0.75, 0), Vector3(0.8, 1.5, 0.8), atan2(-_look.x, _look.y))

## a rounded bush, a few balls of leaves
func _bush(at: Vector2, r: float, tall: float, key = "seto") -> void:
	var o := _stand(at)
	ball(o + Vector3(0, tall * 0.48, 0), r, key, tall / (2.0 * r), 10, 6)
	ball(o + Vector3(r * 0.45, tall * 0.4, r * 0.25), r * 0.7, key, tall / (2.0 * r), 8, 5)
	ball(o + Vector3(-r * 0.4, tall * 0.38, -r * 0.3), r * 0.72, key, tall / (2.0 * r), 8, 5)

## a small tree of purple leaf: a few thin stems from the ground, its crown in loose balls
func _plum(at: Vector2, tall: float) -> void:
	var o := _stand(at)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(at.x * 100.0) ^ int(at.y * 37.0)
	for k in range(4):                                 # (a loose vase of thin stems, leafy from half way up)
		var a: float = TAU * k / 4.0 + rng.randf()
		bar(o, o + Vector3(cos(a) * 0.45, tall * 0.7, sin(a) * 0.45), 0.04, 0.04, 0x4a3a34)
	for k in range(26):                                 # (small loose tufts: light, see-through, not a ball)
		var a: float = rng.randf() * TAU
		var h: float = rng.randf_range(0.35, 1.0)
		var r: float = rng.randf_range(0.1, 0.7) * (0.5 + 0.7 * h)
		ball(o + Vector3(cos(a) * r, tall * h, sin(a) * r), rng.randf_range(0.13, 0.24), "morado", 1.2, 6, 4)
	solid(o + Vector3(0, 1.0, 0), Vector3(0.3, 2.0, 0.3))

## the flowers before the monolith: red and yellow in a half moon, their leaves under them
func _flowers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1210
	var side := Vector2(-_look.y, _look.x)
	var pts := PackedVector2Array()
	for i in range(13):
		var a: float = lerpf(-1.45, 1.45, i / 12.0)
		pts.append(mono + (_look * cos(a) + side * sin(a)) * 1.55)
	for i in range(12, -1, -1):
		var a: float = lerpf(-1.45, 1.45, i / 12.0)
		pts.append(mono + (_look * cos(a) + side * sin(a)) * 0.6)
	_lay(pts, KERB + 0.01, "mantillo")
	for k in range(90):
		var a: float = rng.randf_range(-1.35, 1.35)
		var r: float = rng.randf_range(0.7, 1.45)
		var q: Vector2 = mono + (_look * cos(a) + side * sin(a)) * r
		var o := Vector3(q.x - mid.x, _gy(q), q.y - mid.y)
		ball(o + Vector3(0, 0.08, 0), 0.1, 0x3f6a34, 0.7, 6, 3)
		ball(o + Vector3(rng.randf_range(-0.04, 0.04), 0.16, rng.randf_range(-0.04, 0.04)), 0.055, [0xd8243a, 0xf2c230, 0xe83a4a, 0xf6d84a][k % 4], 0.8, 6, 3)

func _plants() -> void:
	_flowers()
	var side := Vector2(-_look.y, _look.x)
	for s in [-1.0, 1.0]:                              # the two big bushes either side of the monolith
		_bush(mono + side * s * 1.35 - _look * 0.35, 0.85, 1.6)
	var polar := func(r: float, deg: float) -> Vector2:     # (a bearing from north, clockwise, and a distance from the middle)
		var b := deg_to_rad(deg)
		return mid + Vector2(sin(b), -cos(b)) * r
	for q in [[4.3, 20.0, 2.9], [4.1, 205.0, 3.4], [4.4, 255.0, 2.8], [3.9, 300.0, 3.0], [4.6, 160.0, 2.6]]:
		_plum(polar.call(q[0], q[1]), q[2])
	for q in [[3.0, 330.0, 0.7, 1.1], [4.2, 345.0, 0.55, 0.9], [2.6, 20.0, 0.6, 1.0], [4.4, 60.0, 0.6, 1.0], [3.4, 75.0, 0.5, 0.8],
			[4.7, 280.0, 0.55, 0.9], [4.8, 230.0, 0.5, 0.8], [2.8, 250.0, 0.45, 0.7], [4.9, 120.0, 0.45, 0.7]]:
		_bush(polar.call(q[0], q[1]), q[2], q[3], "seto" if int(q[1]) % 2 == 0 else "seto2")

## the black hoses of the watering, lying on the gravel from bush to bush
func _hoses() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for k in range(3):
		var a: float = TAU * k / 3.0 + 0.4
		var prev: Vector2 = mid + Vector2(cos(a), sin(a)) * 4.9
		for j in range(1, 9):
			var b: float = a + j * 0.22
			var q: Vector2 = mid + Vector2(cos(b), sin(b)) * (4.9 + rng.randf_range(-0.5, 0.5) - j * 0.18)
			bar(_p3(prev, KERB + 0.02), _p3(q, KERB + 0.02), 0.018, 0.018, 0x1a1a1c)
			prev = q

## the blue signs of the roundabout at its edge, one before each street that comes into it, looking out at it
func _signs() -> void:
	var ways: Array = []
	for r in MapData.roads:
		var p: PackedInt32Array = r["p"]
		if int(r["k"]) != 0 or p[0] == p[p.size() - 1]:
			continue
		for i in [0, p.size() - 1]:
			var n: Vector2 = MapData.nodes[p[i]]
			var d: float = n.distance_to(mid)
			if absf(d - ring_r) > 2.5:
				continue
			var j: int = 1 if i == 0 else p.size() - 2
			var away: Vector2 = (MapData.nodes[p[j]] as Vector2) - mid
			if away.length() < d + 3.0:              # (it must run away from the ring)
				continue
			var a: float = (n - mid).angle()
			var dup := false
			for w in ways:
				if absf(angle_difference(float(w), a)) < deg_to_rad(35.0):
					dup = true
			if not dup:
				ways.append(a)
	for a in ways:
		var dir := Vector2(cos(a), sin(a))
		var at: Vector2 = mid + dir * (R - 0.45)
		var o := _stand(at)
		var keep := _xf
		_xf = Transform3D(Basis(Vector3(dir.y, 0, -dir.x), Vector3.UP, Vector3(dir.x, 0, dir.y)), o)
		box(-0.03, 0.0, -0.03, 0.06, 0.45, 0.06, 0x9a9da0)          # (low, as they are: a hand over the bushes)
		slab(oval(0.0, Y_SIGN, 0.22, 0.22, 20), 0.04, 0.015, 0x1f5fb0)
		slab(oval(0.0, Y_SIGN, 0.2, 0.2, 20), 0.056, 0.0, 0x2a6ec8)
		for k in range(3):                         # its three white arrows chasing round
			var a0: float = TAU * k / 3.0
			for m in range(4):
				var u0: float = a0 + m * 0.32
				var u1: float = u0 + 0.32
				bar(Vector3(cos(u0) * 0.12, Y_SIGN + sin(u0) * 0.12, 0.06), Vector3(cos(u1) * 0.12, Y_SIGN + sin(u1) * 0.12, 0.06), 0.028, 0.01, 0xfdfcf8)
			var tip := Vector3(cos(a0 + 1.28) * 0.12, Y_SIGN + sin(a0 + 1.28) * 0.12, 0.06)
			bar(tip, tip + Vector3(cos(a0 + 1.28 - 2.4) * 0.055, sin(a0 + 1.28 - 2.4) * 0.055, 0), 0.025, 0.01, 0xfdfcf8)
			bar(tip, tip + Vector3(cos(a0 + 1.28 + 2.2) * 0.055, sin(a0 + 1.28 + 2.2) * 0.055, 0), 0.025, 0.01, 0xfdfcf8)
		_xf = _xf * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)       # its back, grey
		slab(oval(0.0, Y_SIGN, 0.22, 0.22, 20), -0.035, 0.0, 0x9a9da0)
		_xf = keep
		solid(o + Vector3(0, 0.4, 0), Vector3(0.2, 0.8, 0.2))
