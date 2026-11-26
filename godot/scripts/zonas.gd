extends Node3D
## Zones off the map (the user, 25 November 2026, with a picture and a video of Borderlands 2: "Podríamos hacer como en
## el borderlands 2 ... que te acerques al cambio de zona y que un botón te transporte a la siguiente. Así podremos meter
## zonas fuera del pueblo sin ampliar el mapa"; on foot and in a car: "A pie y en coche").
##   - A zone is a place beyond the edge of the built map, at its real place on the land (so that the mountains, the
##     castle of Consuegra and the sun are where they are from there), with its own ground to stand and drive on and its
##     own walls round it. The first is the town's cemetery, 450 m north of the map's edge on the old Madrid-Cádiz road.
##   - The way there is a gate over the road where the map's road ends (a pórtico: two posts, the zone's name on a dark
##     board over them and a curtain of light between them, as the doorways between zones in that game), and another at
##     the zone's end of the road, NÚCLEO URBANO, to come back (the user, 25 Nov: "no hace falta que ponga Madridejos a
##     la hora de volver. Con que ponga Núcleo Urbano me basta. Así distinguimos distintas zonas que siguen siendo
##     Madridejos"). Neither lets you through: stand (or
##     stop your car) before it and the action button takes you, car and all, to the other one.
##   - Not with the police after you, nor in a scene, a conversation, a menu or a game at a machine (_blocked).
##   - Between the two gates the land and the road go on as they are (the road is drawn on, the land is the plain the
##     world draws past its edge), so from the town's end you see the cemetery far off and from the cemetery the town.
## Each zone: its id, the gate on the map (where it stands and the way through it, a bearing), the gate in the zone, the
## circle the zone keeps you in (round its middle, a little past its gate: the user, 25 Nov 2026, "un círculo invisible
## con centro en el cementerio y que llegase poco más lejos que las puertas de zona, para que la gente no se saliese del
## mapa"), the road through it (drawn on to the horizon: "la carretera en el cementerio se corta muy pronto y se nota
## mucho que es una zona aparte"), and the Loc keys of the two prompts.

const ZONES := [
	{"id": "cementerio", "name": "CEMENTERIO",
		"town": Vector2(289.9, -1806.0), "town_b": 8.7,           # on the old road, 18 m short of where the map's road ends
		"zone": Vector2(363.1, -2292.0), "zone_b": 188.56,        # the same road, south of the cemetery, facing back to town
		"centre": Vector2(491.875, -2439.675), "radius": 210.0,  # (the cemetery's middle, its four corners'; its gate is 196 m from it)
		"road_from": Vector2(292.7, -1824.1), "road_to": Vector2(462.9, -2955.0), "road_hw": 5.25,      # (through the middle of its asphalt before the cemetery's gate, PNOA; on north to where it really ends, at the A-4's slip roads: OSM, autovia.gd)
		"go": "p_zona_cementerio", "back": "p_zona_nucleo", "back_name": "NÚCLEO URBANO",
		"night_hush": true, "place": "cementerio", "autovia": true, "lejos": true, "solar": true, "afueras": true},       # (autovia: the A-4 by it, with its traffic: autovia.gd; lejos: the town far off, a picture round the horizon: lejanias.gd)               # (at night: no music on foot, only the wind now and then: hush; world.cementerio keeps its own land clear of the scrub)
]
const POST := 6.5                       # the gate's posts: this far either side of the road's middle
const TALL := 6.2                       # ...this tall; the board over them
const BOARD := 1.3
const NEAR_FOOT := 5.0                  # how close before it you must stand, on foot...
const NEAR_CAR := 9.0                   # ...or in a car (stopped)
const SLOW := 3.0                       # a car going slower than this (m/s) counts as stopped
const ARRIVE := 10.0                    # where you come out: this far from the other gate, facing away from it
const CYAN := Color(0.55, 0.88, 1.0)

const CURTAIN_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;
uniform vec4 tint : source_color = vec4(0.55, 0.88, 1.0, 1.0);
uniform float across = 12.8;
uniform float tall = 4.9;
void fragment() {
	vec2 m = vec2(UV.x * across, UV.y * tall);                  // in metres
	float s = fract((m.x + m.y) / 1.6 - TIME * 0.25);           // broad diagonal stripes, drifting
	float band = smoothstep(0.0, 0.06, s) * (1.0 - smoothstep(0.44, 0.5, s));
	float foot = smoothstep(0.55, 1.0, UV.y);                   // brighter low down, where it meets the road
	float side = 1.0 - smoothstep(0.0, 0.04, min(UV.x, 1.0 - UV.x));
	ALBEDO = tint.rgb * (1.1 + band * 0.4);
	ALPHA = clamp(0.1 + band * 0.2 + foot * 0.22 + side * 0.4, 0.0, 0.8);
}
"""

var G
var gates: Array = []                   # [{zone, side "town"|"zone", p, out (the way through, unit), node}]
var _here = null                        # the gate you are standing (or stopped) before, for the button
var _spin := 0.0
var _curtain: ShaderMaterial
var _steel: StandardMaterial3D
var _board: StandardMaterial3D
var _diamond: StandardMaterial3D
var _road: Material
var _line: StandardMaterial3D

func setup(game) -> void:
	G = game
	_curtain = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = CURTAIN_SHADER
	_curtain.shader = sh
	_steel = StandardMaterial3D.new()
	_steel.albedo_color = Color(0.2, 0.22, 0.25)
	_steel.roughness = 0.6
	_steel.metallic = 0.3
	_board = StandardMaterial3D.new()
	_board.albedo_color = Color(0.06, 0.07, 0.09)
	_board.roughness = 0.8
	_diamond = StandardMaterial3D.new()
	_diamond.albedo_color = Color(CYAN, 0.85)
	_diamond.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_diamond.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_diamond.cull_mode = BaseMaterial3D.CULL_DISABLED
	_road = G.world._tmat(0x77727a, "asphalt", 3.0) if G.world != null and G.world.has_method("_tmat") else _steel
	_line = StandardMaterial3D.new()
	_line.albedo_color = Color(0.92, 0.92, 0.9)
	_line.roughness = 0.9
	MinimapS.extras = []
	for z in ZONES:
		gates.append(_gate(z, "town", z["town"], _dir(z["town_b"]), z["name"]))
		gates.append(_gate(z, "zone", z["zone"], _dir(z["zone_b"]), z["back_name"]))
		_road_on(z)
		_ground(z)
		if z.get("autovia", false):                  # (before its scrub: that keeps off it)
			var av = AutoviaS.new()
			add_child(av)
			av.setup(G, z)
			autovias[z["id"]] = av
		if z.get("lejos", false):
			var lj = LejaniasS.new()
			add_child(lj)
			lj.setup(G, z)
			lejos.append(lj)
		if z.get("solar", false):                    # (the solar plant across the road: before the scrub, that keeps off its drive and out of its trackers' feet)
			var sp = SolarS.new()
			add_child(sp)
			if sp.build(G, z):
				solares[z["id"]] = sp
			else:
				sp.queue_free()
		if z.get("afueras", false):                  # (the white nave by its gate and the A-4's blue signs: before the scrub too)
			var af = AfuerasS.new()
			add_child(af)
			if af.build(G, z, autovias.get(z["id"])):
				afueras[z["id"]] = af
			else:
				af.queue_free()
		_scrub(z)
		_plan(z)
	if not scrub_trees.is_empty():
		G.world.add_trees(scrub_trees)          # (solid and felled by a car like the town's: before props.gd indexes them)

## What of a zone is drawn on the game's plan, round and whole (minimap.gd `extras`; the user, 25 Nov 2026, of the
## things proposed after the review -- «Minimapa de la zona: ahora sale vacío» --: «Haz las 8»): its road, the A-4 and
## its slip roads past the map's edge, its place's wall and walks, the solar plant's fence, trackers and far fields,
## the nave. Outlines first, the roads over them.
func _plan(z: Dictionary) -> void:
	var list: Array = []
	var place = G.world.get(String(z["place"])) if z.has("place") and G.world != null else null
	if place != null and place.has_method("map_at"):
		list.append([3, _dense(PackedVector2Array([place.NW, place.NE, place.SE, place.SW]), true), 0.0])
	var sp = solares.get(z["id"])
	if sp != null:
		list.append([3, _dense(PackedVector2Array(sp.FENCE), true), 0.0])
		for farm in sp.FARMS:
			list.append([3, _dense(PackedVector2Array(farm), true), 0.0])
		for t in sp.TRACKERS:
			var tp: Vector2 = t
			list.append([3, PackedVector2Array([tp + Vector2(-7, -5), tp + Vector2(7, -5), tp + Vector2(7, 5), tp + Vector2(-7, 5), tp + Vector2(-7, -5)]), 0.0])
	var af = afueras.get(z["id"])
	if af != null:
		for o in af.outlines:
			list.append([3, _dense(o[1], true), 0.0])
	if place != null and place.has_method("map_at"):
		list.append([2, _dense(PackedVector2Array([place.map_at(place.HALL_D, 86.0), place.map_at(place.L_N - 1.0, 86.0)]), false), 1.6])
		list.append([2, _dense(PackedVector2Array([place.map_at(86.75, 44.0), place.map_at(86.75, 125.0)]), false), 3.0])
	if sp != null:
		var gm: Vector2 = ((sp.GATE_S as Vector2) + (sp.GATE_N as Vector2)) / 2.0
		var rd: Vector2 = ((z["road_to"] as Vector2) - (z["road_from"] as Vector2)).normalized()
		list.append([1, PackedVector2Array([gm, gm + Vector2(-rd.y, rd.x) * 11.0]), 2.5])
	var av = autovias.get(z["id"])
	if av != null:
		for key in ["entrada", "salida", "nb", "sb"]:
			var north := PackedVector2Array()
			for q in _dense(av.lines.get(key, PackedVector2Array()), false):
				if q.y < MapData.zmin:                           # (north of the map only: the town's own plan is its own)
					north.append(q)
			if north.size() > 1:
				list.append([0, north, 2.95 if key in ["entrada", "salida"] else 5.35])
	list.append([0, _dense(PackedVector2Array([z["road_from"], z["road_to"]]), false), float(z["road_hw"])])
	MinimapS.extras = MinimapS.extras + list

## a line with a point every `step` metres at the least (and round to its first one again, if closed)
static func _dense(pl: PackedVector2Array, closed: bool, step := 30.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := pl.size()
	if n == 0:
		return out
	for i in range(n if closed else n - 1):
		var a: Vector2 = pl[i]
		var b: Vector2 = pl[(i + 1) % n]
		var k := maxi(1, int(ceil(a.distance_to(b) / step)))
		for j in range(k):
			out.append(a.lerp(b, float(j) / k))
	out.append(pl[0] if closed else pl[n - 1])
	return out

## a bearing (degrees from north, clockwise) as a way on the map (x east, z south)
static func _dir(bearing: float) -> Vector2:
	var b := deg_to_rad(bearing)
	return Vector2(sin(b), -cos(b))

## the game's heading for a way on the map (forward is (sin h, cos h))
static func _heading(d: Vector2) -> float:
	return atan2(d.x, d.y)

## which zone a spot is in, or null (in the town, or in a set of a shop)
func zone_at(p: Vector2):
	for z in ZONES:
		if p.distance_to(z["centre"]) < float(z["radius"]):
			return z
	return null

func in_zone(p: Vector2) -> bool:
	return zone_at(p) != null

# ---------------- the gates ----------------
## A gate over the road at p, its way through `out`: two steel posts, a dark board across their tops with the name of
## where it takes you (on both faces), a curtain of light between them, and a diamond turning in the middle of it, the
## mark of a way to somewhere else. What stops you: the posts, and an unseen wall in the curtain.
func _gate(z: Dictionary, side: String, p: Vector2, out: Vector2, words: String) -> Dictionary:
	var root := Node3D.new()
	root.name = "zona_%s_%s" % [z["id"], side]
	var y := MapData.height(p)
	var zf := Vector3(-out.x, 0.0, -out.y)                 # its face looks back at who comes to it
	var xf := Vector3.UP.cross(zf)                           # (x = up x z: not a mirror)
	root.transform = Transform3D(Basis(xf, Vector3.UP, zf), Vector3(p.x, y, p.y))
	add_child(root)
	for sx in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.7, TALL + 0.6, 0.7)
		post.mesh = bm
		post.material_override = _steel
		post.position = Vector3(sx * POST, (TALL + 0.6) / 2.0 - 0.6, 0.0)      # (sunk a little, for the slope)
		root.add_child(post)
	var board := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(POST * 2.0 + 1.2, BOARD, 0.5)
	board.mesh = bb
	board.material_override = _board
	board.position = Vector3(0.0, TALL - BOARD / 2.0, 0.0)
	root.add_child(board)
	for face in [1.0, -1.0]:                                 # the name, both faces of the board
		var l := Label3D.new()
		l.text = words
		l.font_size = 150
		l.pixel_size = 0.0062
		l.outline_size = 18
		l.modulate = CYAN
		l.outline_modulate = Color(0.02, 0.1, 0.16)
		l.shaded = false
		l.double_sided = false
		l.position = Vector3(0.0, TALL - BOARD / 2.0, face * 0.26)
		l.rotation.y = 0.0 if face > 0.0 else PI
		l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(l)
	var cur := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(POST * 2.0 - 0.7, TALL - BOARD)
	cur.mesh = qm
	cur.material_override = _curtain
	cur.position = Vector3(0.0, (TALL - BOARD) / 2.0, 0.0)
	cur.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(cur)
	var dia := MeshInstance3D.new()
	dia.name = "diamond"
	var pm := PrismMesh.new()                                # two prisms, tip to tip: a diamond
	pm.size = Vector3(0.9, 0.7, 0.18)
	dia.mesh = pm
	dia.material_override = _diamond
	dia.position = Vector3(0.0, 2.6, 0.0)
	dia.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var low := MeshInstance3D.new()
	low.mesh = pm
	low.material_override = _diamond
	low.position = Vector3(0.0, -0.7, 0.0)
	low.rotation.z = PI
	low.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dia.add_child(low)
	root.add_child(dia)
	var body := StaticBody3D.new()                           # the posts, and the curtain as a wall
	root.add_child(body)
	for b in [[Vector3(-POST, TALL / 2.0, 0.0), Vector3(0.7, TALL + 1.0, 0.7)], [Vector3(POST, TALL / 2.0, 0.0), Vector3(0.7, TALL + 1.0, 0.7)],
			[Vector3(0.0, TALL / 2.0, 0.0), Vector3(POST * 2.0, TALL + 1.0, 0.3)]]:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = b[1]
		cs.shape = bs
		cs.position = b[0]
		body.add_child(cs)
	return {"zone": z, "side": side, "p": p, "out": out, "node": root}

## The road on from the map's end to the far end of the zone: drawn over the plain (it is the same road), with its
## white edge lines. Only to look at between the gates (there is no getting on to it); in the zone it is the road.
func _road_on(z: Dictionary) -> void:
	var a: Vector2 = z["road_from"]
	var b: Vector2 = z["road_to"]
	var hw: float = z["road_hw"]
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x)
	var L := a.distance_to(b)
	var k := int(ceil(L / 6.0))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lines := SurfaceTool.new()
	lines.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(k):
		var p0 := a.lerp(b, float(i) / k)
		var p1 := a.lerp(b, float(i + 1) / k)
		_strip(st, p0, p1, n, -hw, hw, 0.02, float(i) * L / k)
		for e in [-hw + 0.25, hw - 0.4]:                    # (the white lines along its edges)
			_strip(lines, p0, p1, n, e, e + 0.15, 0.035, 0.0)
	var s := 0.0
	while s + 3.5 < L:                                       # and the broken one down its middle: 3.5 m on, 9 off
		_strip(lines, a + d * s, a + d * (s + 3.5), n, -0.06, 0.06, 0.035, 0.0)
		s += 12.5
	var mi := MeshInstance3D.new()
	st.generate_normals()
	mi.mesh = st.commit()
	mi.material_override = _road
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	var ml := MeshInstance3D.new()
	lines.generate_normals()
	ml.mesh = lines.commit()
	ml.material_override = _line
	ml.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ml)

## a strip of road from p0 to p1, from e0 to e1 across (n), lift over the ground; uv in metres
func _strip(st: SurfaceTool, p0: Vector2, p1: Vector2, n: Vector2, e0: float, e1: float, lift: float, v0: float) -> void:
	var q := [p0 + n * e0, p0 + n * e1, p1 + n * e1, p1 + n * e0]
	var ln := p0.distance_to(p1)
	var uv := [Vector2(e0, v0), Vector2(e1, v0), Vector2(e1, v0 + ln), Vector2(e0, v0 + ln)]
	for t in [[0, 2, 1], [0, 3, 2]]:
		for i in t:
			var w: Vector2 = q[i]
			st.set_uv(uv[i])
			st.add_vertex(Vector3(w.x, MapData.height(w) + lift, w.y))

## The zone's ground: what the plain past the map's edge is drawn as (the world's land goes on level from its last
## row of heights, world.gd _terrain), made something to stand and drive on -- the world's own ground stops at its
## edge -- and an invisible wall round the zone's circle, as the map's own edge has: boxes standing on its edge, each
## along it, 72 of them.
func _ground(z: Dictionary) -> void:
	var c: Vector2 = z["centre"]
	var rad: float = z["radius"]
	var r := Rect2(c - Vector2(rad, rad), Vector2(rad, rad) * 2.0)
	var body := StaticBody3D.new()
	body.name = "zona_%s_suelo" % z["id"]
	add_child(body)
	var xs: Array = []
	var i0 := int(floor((r.position.x - MapData.rx0) / MapData.rg))
	var i1 := int(ceil((r.end.x - MapData.rx0) / MapData.rg))
	for i in range(i0, i1 + 1):                              # (on the grid's own columns: the plain is straight between them)
		xs.append(MapData.rx0 + i * MapData.rg)
	var z0 := r.position.y - 20.0
	var z1 := r.end.y + 20.0
	var faces := PackedVector3Array()
	for k in range(xs.size() - 1):
		var xa: float = xs[k]
		var xb: float = xs[k + 1]
		var ha := MapData.height(Vector2(xa, z0))
		var hb := MapData.height(Vector2(xb, z0))
		var q := [Vector3(xa, ha, z0), Vector3(xb, hb, z0), Vector3(xb, hb, z1), Vector3(xa, ha, z1)]
		for t in [0, 1, 2, 0, 2, 3]:
			faces.append(q[t])
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	var n := 72
	var piece := 2.0 * (rad + 1.0) * tan(PI / n) + 1.0             # (each a little longer than its share: no gap between them)
	for k in range(n):
		var th := TAU * k / n
		var at := c + Vector2(cos(th), sin(th)) * (rad + 1.0)
		var wc := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(piece, 80.0, 2.0)
		wc.shape = bs
		wc.transform = Transform3D(Basis(Vector3.UP, -th - PI / 2.0), Vector3(at.x, MapData.height(at), at.y))      # (its length along the circle)
		body.add_child(wc)

# ---------------- its land: dry plants and the odd tree ----------------
## The zone's land as the town's bare ground (matojos.gd: the same tufts of dead grass, dry bushes and grey-green
## shrubs, in the same loose patches; the user, 25 Nov 2026: "El suelo está muy plano y vacío. No había cambiado como se
## hace para que salgan malas hierba/arbustos/arboles sueltos de vez en cuando y darle más vida?" -- the town's only grow
## near its blocks of houses, and the zone is 450 m past the last one). Thicker on the road's verges and at the foot of
## the place's wall; and now and then an olive, an almond or a stand of umbrella pines, as round the town. Not only in
## its circle: the plants as far past it as they are drawn from its wall (the farthest draw distance), the trees on to
## where the eye reaches and fewer as they go, so its edge is never seen. Never on the road, by a gate, on the map, or
## on what is the place's own (place.keep_off: the cemetery, its square and its trees). The same ones every time.
const Matojos = preload("res://scripts/matojos.gd")
const PartsZ = preload("res://scripts/parts.gd")
const SCRUB_PAST := 200.0               # dry plants this far past the circle (drawn 120 m away, times 1.6 at the most)...
const SCRUB_FADE := 80.0                # ...thinning out over the last of it
const TREES_TO := 1400.0                # trees out to this far from the zone's middle (the camera sees 1600 m)...
const TREES_FULL := 400.0               # ...as thick as round the town to here, then fewer
const SCRUB_CELL := 64.0                # the squares they are drawn in (as matojos.gd's)
const TREE_GAP := 7.0
const AutoviaS = preload("res://scripts/autovia.gd")
var autovias := {}                      # a zone's id -> its A-4 (autovia.gd), if it has one
const LejaniasS = preload("res://scripts/lejanias.gd")
var lejos: Array = []                   # the pictures of the town far off round the zones' horizons (lejanias.gd)
const SolarS = preload("res://scripts/planta_solar.gd")
var solares := {}                       # a zone's id -> the solar plant in it (planta_solar.gd), if it has one
const AfuerasS = preload("res://scripts/afueras.gd")
const MinimapS = preload("res://scripts/minimap.gd")
var afueras := {}                       # a zone's id -> what else stands by its road (afueras.gd: the white nave, the A-4's signs)
var scrub_n := 0                        # dry plants grown in the zones (the self-test)
var scrub_trees: Array = []             # and trees: [x, z, kind, size, turn] (world.gd add_trees)

## how far a spot is from the edge of the zone's road (negative on it)
func _road_gap(z: Dictionary, p: Vector2) -> float:
	var a: Vector2 = z["road_from"]
	var b: Vector2 = z["road_to"]
	var q: Vector2 = Geometry2D.get_closest_point_to_segment(p, a, b)
	var gap: float = p.distance_to(q) - float(z["road_hw"])
	var av = autovias.get(z["id"])
	if av != null:                                           # (and from the A-4's, its slip roads' and its fence)
		gap = minf(gap, float(av.gap(p)))
	return gap

## inside any of these outlines
static func _in_any(p: Vector2, polys: Array) -> bool:
	for poly in polys:
		if Geometry2D.is_point_in_polygon(p, poly):
			return true
	return false

## the spots of a zone's gates
func _gate_spots(z: Dictionary) -> Array:
	var out: Array = []
	for gt in gates:
		if gt["zone"] == z:
			out.append(gt["p"])
	return out

## where a dry plant may grow in the zone: off the road (its edge), the gates, the map and the place's own
func _plant_ok(z: Dictionary, p: Vector2, off: Array, gate_ps: Array) -> bool:
	if p.y > MapData.zmin - 6.0 or _road_gap(z, p) < 0.6 or _in_any(p, off):
		return false
	for gp in gate_ps:
		if p.distance_to(gp) < 9.0:
			return false
	return true

func _scrub(z: Dictionary) -> void:
	if OS.get_cmdline_user_args().has("--sin-matojos") or G.world == null:      # (as the town's: to compare what they cost)
		return
	var c: Vector2 = z["centre"]
	var rad: float = z["radius"]
	var place = G.world.get(String(z["place"])) if z.has("place") else null
	var keep: bool = place != null and place.has_method("keep_off")
	var off_plant: Array = place.keep_off(false, 0.5) if keep else []
	var foot: Array = place.keep_off(false, 3.0) if keep else []           # (the foot of its wall: thicker there)
	var off_tree: Array = place.keep_off(true, 4.0) if keep else []
	var sp = solares.get(z["id"])
	if sp != null:                                           # (the solar plant's own: its drive and its trackers' feet; no tree in it)
		off_plant = off_plant + (sp.keep_off(false, 0.5) as Array)
		off_tree = off_tree + (sp.keep_off(true, 4.0) as Array)
	var af = afueras.get(z["id"])
	if af != null:                                           # (the nave, its yard and the signs' feet)
		off_plant = off_plant + (af.keep_off(false, 0.5) as Array)
		off_tree = off_tree + (af.keep_off(true, 4.0) as Array)
	var gate_ps: Array = _gate_spots(z)
	var top: float = MapData.zmin - 6.0                  # (north of the map only: the town's own grow on it)
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = 2521
	noise.frequency = 1.0 / 45.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 2511
	# the plants: candidate spots on a jittered grid, kept in loose patches (matojos.gd's rule), then a clump at each
	var reach: float = rad + SCRUB_PAST
	var step := 6.4
	var n := int(ceil(2.0 * reach / step))
	var kept: Array = []
	for i in range(n):
		for j in range(n):
			var p := Vector2(c.x - reach + (i + rng.randf()) * step, c.y - reach + (j + rng.randf()) * step)
			var roll := rng.randf()
			var d := p.distance_to(c)
			if d > reach:
				continue
			var base := clampf((noise.get_noise_2d(p.x, p.y) + 0.15) * 1.1, 0.02, 0.7)
			var near := 0.0
			if _road_gap(z, p) < 6.0:
				near += 0.15                     # the verge
			var by_wall: bool = _in_any(p, foot)
			if by_wall:
				near += 0.3                      # the foot of the wall
			var fade := clampf((reach - d) / SCRUB_FADE, 0.0, 1.0)
			if roll >= (base + near) * fade or not _plant_ok(z, p, off_plant, gate_ps):
				continue
			kept.append([p, by_wall])
	var straw := [Color(1.0, 0.97, 0.9), Color(0.9, 0.84, 0.72), Color(0.82, 0.77, 0.7), Color(1.0, 0.9, 0.74)]
	var greens := [Color(1.0, 1.0, 1.0), Color(0.86, 0.92, 0.84), Color(1.05, 1.0, 0.9), Color(0.78, 0.8, 0.76)]
	var bufs := {}
	var spots := {}                                          # (where each one is, kept by the script: with no window the engine gives no instance back)
	for e in kept:
		var p0: Vector2 = e[0]
		var by_wall: bool = e[1]
		var m := 1 + int(pow(rng.randf(), 1.3) * 8.0)
		for k in range(m):
			var at: Vector2 = p0
			if k > 0:
				at = p0 + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.5, 2.2)
				if not _plant_ok(z, at, off_plant, gate_ps):
					continue
			var r := rng.randf()
			var bush := r < 0.18
			var mata := k == 0 and r > 0.9 and not by_wall            # (one to a clump, in the open)
			var sc := rng.randf_range(0.55, 1.05) if bush else rng.randf_range(0.3, 0.62)
			if mata:
				sc = rng.randf_range(0.6, 1.15)
			var y: float = MapData.height(at) - 0.18 - 0.02             # (world.gd ROAD_Y: the drawn ground lies under the physics one)
			var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(sc * rng.randf_range(0.85, 1.2), sc, sc * rng.randf_range(0.85, 1.2)))
			var col: Color = (greens[rng.randi() % greens.size()] if mata else straw[rng.randi() % straw.size()]) * rng.randf_range(0.88, 1.05)
			var key := Vector3i(floori(at.x / SCRUB_CELL), floori(at.y / SCRUB_CELL), 2 if mata else (1 if bush else 0))
			if not bufs.has(key):
				bufs[key] = []
				spots[key] = []
			(spots[key] as Array).append(at)
			var o := Vector3(at.x - (key.x + 0.5) * SCRUB_CELL, y, at.y - (key.y + 0.5) * SCRUB_CELL)
			(bufs[key] as Array).append_array([b.x.x, b.y.x, b.z.x, o.x, b.x.y, b.y.y, b.z.y, o.y, b.x.z, b.y.z, b.z.z, o.z, col.r, col.g, col.b, 1.0])
	var meshes := [Matojos._tuft_mesh(), Matojos._bush_mesh(), Matojos._mata_mesh()]
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	var holder := Node3D.new()
	holder.name = "zona_%s_matas" % z["id"]
	add_child(holder)
	for key in bufs:
		var kk: Vector3i = key
		var buf := PackedFloat32Array(bufs[key])
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = meshes[kk.z]
		mm.instance_count = buf.size() / 16
		mm.buffer = buf
		scrub_n += mm.instance_count
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3((kk.x + 0.5) * SCRUB_CELL, 0.0, (kk.y + 0.5) * SCRUB_CELL)
		mi.set_meta("ps", PackedVector2Array(spots[key]))        # (its plants' places, in the buffer's order: the self-test)
		holder.add_child(mi)
		PartsZ._range(mi, 120.0)
	# the trees: one try in each square of 32 m (matojos.gd's rule: in stands, with open land between), fewer far off
	var tnoise := FastNoiseLite.new()
	tnoise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	tnoise.seed = 2512
	tnoise.frequency = 1.0 / 140.0
	var taken := {}
	for t in G.world.tree_info:
		var tp: Vector2 = t["p"]
		if tp.distance_to(c) < TREES_TO + 20.0:
			_take_at(taken, tp)
	var cell := 32.0
	var nt := int(ceil(2.0 * TREES_TO / cell))
	for i in range(nt):
		for j in range(nt):
			var p := Vector2(c.x - TREES_TO + (i + rng.randf()) * cell, c.y - TREES_TO + (j + rng.randf()) * cell)
			var roll := rng.randf()
			var kind_roll := rng.randf()
			var size := rng.randf_range(0.8, 1.2)
			var turn := rng.randf() * TAU
			var d := p.distance_to(c)
			if d > TREES_TO or p.y > top:
				continue
			var tn := tnoise.get_noise_2d(p.x, p.y)
			var thin := 1.0 if d < TREES_FULL else lerpf(1.0, 0.35, (d - TREES_FULL) / (TREES_TO - TREES_FULL))
			if roll >= clampf((tn + 0.3) * 0.75, 0.04, 0.5) * thin:
				continue
			if absf(d - rad - 1.0) < 8.0 or _road_gap(z, p) < 5.0 or _in_any(p, off_tree):
				continue                         # (off its wall, the road and the place's own)
			var by_gate := false
			for gp in gate_ps:
				if p.distance_to(gp) < 15.0:
					by_gate = true
			if by_gate or _near_taken(taken, p):
				continue
			var kind := 3 if tn > 0.3 and kind_roll < 0.8 else (1 if kind_roll < 0.7 else 0)      # pines where the stands are thickest; olives most
			scrub_trees.append([p.x, p.y, kind, size, turn])
			_take_at(taken, p)

func _take_at(taken: Dictionary, p: Vector2) -> void:
	var k := Vector2i(floori(p.x / 8.0), floori(p.y / 8.0))
	if not taken.has(k):
		taken[k] = []
	(taken[k] as Array).append(p)

func _near_taken(taken: Dictionary, p: Vector2) -> bool:
	var k := Vector2i(floori(p.x / 8.0), floori(p.y / 8.0))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for q in taken.get(k + Vector2i(dx, dz), []):
				if (q as Vector2).distance_to(p) < TREE_GAP:
					return true
	return false

# ---------------- every frame ----------------
func tick(dt: float) -> void:
	_spin += dt
	for g in gates:
		var dia: Node3D = (g["node"] as Node3D).get_node("diamond")
		dia.rotation.y = _spin * 1.6
		dia.position.y = 2.6 + sin(_spin * 2.2) * 0.12
	for av in autovias.values():                             # (the A-4's traffic, and it shown only from in its zone)
		av.tick(dt)
	for lj in lejos:
		lj.tick(dt)
	for sp in solares.values():                              # (its trackers follow the sun)
		sp.tick(dt)
	for af in afueras.values():                              # (the Recoveco nave's garage: its shutter, its offer to a car in its bay)
		af.tick(dt)
	var cm = G.world.get("cementerio") if G != null and G.get("world") != null and G.world != null else null
	if cm != null:                                           # (its candles' glow at night, the whitewash of a felled tree)
		cm.tick(dt)
	_here = null
	if G == null or G.player == null:
		return
	_tick_wind(dt)
	var pp: Vector2 = G.player.p
	var car = G.in_car
	for g in gates:
		var rel: Vector2 = pp - (g["p"] as Vector2)
		var ahead: float = -rel.dot(g["out"])               # how far before it (on the side you come from)
		var across: float = absf(rel.dot(Vector2(-(g["out"] as Vector2).y, (g["out"] as Vector2).x)))
		var reach := NEAR_CAR if car != null else NEAR_FOOT
		if ahead > -0.5 and ahead < reach and across < POST:
			if car != null and (car.linear_velocity as Vector3).length() > SLOW:
				continue
			_here = g
			break

## At night in a zone that asks for it (the cemetery): game.gd plays no music on foot and none of the town's sounds
## (crickets, dogs), and here the wind blows now and then, low (the user, 25 Nov 2026: "De noche quita la música chill
## que tenemos y deja solo el leve sonido del viento de vez en cuando. Que dé algo de mal rollo"). The car's radio, if
## you put it on, is yours. The gusts are made by tools/cementerio/viento.py (no recording of anyone's).
const WIND := ["res://assets/cementerio/viento_0.wav", "res://assets/cementerio/viento_1.wav", "res://assets/cementerio/viento_2.wav"]
var _wind: AudioStreamPlayer
var _wind_t := 3.0
var _wind_db := -60.0

func hush() -> bool:
	if G == null or G.player == null or String(G.get("moment")) != "night":
		return false
	if not (G.phase == "play" or G.phase == "free" or G.phase == "talking"):
		return false
	var z = zone_at(G.player.p)
	return z != null and bool(z.get("night_hush", false))

func _tick_wind(dt: float) -> void:
	if _wind == null:
		_wind = AudioStreamPlayer.new()
		_wind.bus = "SFX"
		_wind.volume_db = -60.0
		add_child(_wind)
	var held: bool = bool(G.get("paused")) or bool(G.get("map_open"))
	if _wind.playing:
		_wind.stream_paused = held
	if held:
		return
	if not hush():
		if _wind.playing:                                         # (out of it, or day comes: it dies away)
			_wind.volume_db = move_toward(_wind.volume_db, -60.0, 30.0 * dt)
			if _wind.volume_db <= -59.0:
				_wind.stop()
		_wind_t = minf(_wind_t, 3.0)
		return
	if _wind.playing:
		_wind.volume_db = move_toward(_wind.volume_db, _wind_db, 20.0 * dt)
		return
	_wind_t -= dt
	if _wind_t <= 0.0:
		_wind_t = randf_range(8.0, 24.0)                          # (of a while: then a gust, then quiet)
		var s = load(WIND[randi() % WIND.size()])
		if s != null:
			_wind.stream = s
			_wind_db = randf_range(-21.0, -15.0)
			_wind.volume_db = _wind_db
			_wind.pitch_scale = randf_range(0.85, 1.1)
			_wind.play()

## the gate you are before, for the button (null if none, or not now)
func here():
	if _here == null or G._door_cool > 0.0:
		return null
	if not (G.phase == "play" or G.phase == "free") or G.dlg != null or G.cine_lock or G.menu.visible or G.indoors:
		return null
	return _here

## what the button says there
func prompt() -> String:
	var g = here()
	if g == null:
		return ""
	return Loc.t(g["zone"]["go"] if g["side"] == "town" else g["zone"]["back"])

## why you cannot go just now ("" if you can): the police after you, the edge of the map's count-down, the riot, a taxi
## run against the clock, a car being mended, the phone
func _blocked() -> String:
	var pol = G.get("police")
	if pol != null and (float(pol.heat) > 0.0 or bool(pol.chasing) or float(pol.bust_t) > 0.0):      # (bust_t: being taken in)
		return "t_zona_pasma"
	var lim = G.get("limite")
	if lim != null and (bool(lim.warning) or bool(lim.hunting)):
		return "t_zona_pasma"
	var mot = G.get("motin")
	if mot != null and mot.busy():
		return "t_zona_no"
	var kk = G.get("koke")
	if kk != null and kk.running():
		return "t_zona_no"
	if G.get("mending") != null or G.get("phone_call") != null:
		return "t_zona_no"
	var cm = G.get("comida")                                  # (fainting from eating too much: it takes you to your door)
	if cm != null and cm.get("faint") != null:
		return "t_zona_no"
	var sd = G.get("side")                                    # the errands against the clock: every job (Koke's run too), and following the lorry for Don Luis
	if sd != null and String(sd.get("id", "")) == "trabajo":
		return "t_zona_no"
	var sb = G.get("sabotaje")
	if sd != null and String(sd.get("id", "")) == "luis" and sb != null and String(sb.stage) in ["cine_out", "follow", "unload", "window", "act", "cine_go"]:
		return "t_zona_no"
	return ""

## the button pressed before a gate: to the other one, on foot or car and all
func go() -> bool:
	var g = here()
	if g == null:
		return false
	var why := _blocked()
	if why != "":
		G.hud.toast(Loc.t(why), 2.4)
		return false
	var other: Dictionary = _other(g)
	var away: Vector2 = -(other["out"] as Vector2)           # you come out facing away from the other gate
	var to: Vector2 = (other["p"] as Vector2) + away * ARRIVE
	var h := _heading(away)
	G._door_cool = 1.2
	G._blink()
	Sfx.jingle([880, 1175, 1568], 0.12)
	var car = G.in_car
	if car != null:
		car.place(to, h)
		G.player.p = to
		G.player.h = h
		G.player.sync()
	else:
		G.player.p = to
		G.player.h = h
		G.player.sync()
	G.cam_yaw = h
	G.cam_pos = Vector3(to.x - sin(h) * (7.0 if car != null else 1.6), MapData.height(to) + (3.2 if car != null else 2.2), to.y - cos(h) * (7.0 if car != null else 1.6))
	G.cam_look = MapData.at(to, 1.6)
	G.pull = 0.3
	_here = null
	return true

func _other(g: Dictionary) -> Dictionary:
	for o in gates:
		if o["zone"] == g["zone"] and o["side"] != g["side"]:
			return o
	return g

## what the self-test wants to know: the gate of a zone on one side
func gate_of(id: String, side: String):
	for g in gates:
		if g["zone"]["id"] == id and g["side"] == side:
			return g
	return null
