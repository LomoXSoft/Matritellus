extends "res://scripts/obra.gd"
## The Colegio Público (the user, 27 Nov 2026: "Podrías ponerte con el colegio público Garcilaso de la vega (creo que
## con llamarlo colegio público es suficiente). Ocupa más o menos la zona en rojo. Está construido sobre las ruinas del
## antiguo cementerio. Así que si quieres poner algunos huesos o calaveras en algún sitio como easter egg estaría
## guay"): the primary school of the block between the Calle de los Huertos (west), the Calle del Socorro (north), the
## lane on its east and the backs of the houses of the Calle del Santo (south). Built by hand from the outlines of
## OpenStreetMap (they agree with the IGN's orthophoto; Google's aerial pictures are oblique and put the roofs a metre
## north for every metre of height), Google's aerial pictures for what lies on the ground, and Street View from the
## streets round it. What none of them shows is made in keeping with what they do.
##
## Inside its fence: the two-storey wings of pale precast panels, the north one and the east one, with the way in on
## the east one's east side near their corner and the school's name round the corner, high on its north side; behind them the one-storey classrooms round a narrow light well and a
## small patio on the west, solar panels on their roof; the porch on the south over the sandy yard of the little ones;
## the gym and its annex on the north; the concrete playground on the west with its futsal pitch, its hoops and its
## floodlights by the Calle de los Huertos; the car park on the east; the vegetable beds in the earth of the north.
## The fence: a low wall with a mesh over it on the streets, a tall white wall with a mesh over it along the playground,
## a white wall along the backs of the houses. And the old cemetery's bones, here and there (the easter egg).
##
## The map has nothing in this block (no rebake). Frame (u, v): u along the north wing to the east-south-east, v across
## it to the south-south-west, from the north-west corner of the north wing (A); y = 0 the ground under the middle of
## the buildings. Each building stands on its own floor; the yards lie on the ground as the relief has it.

const NAME := "COLEGIO PÚBLICO"
const A := Vector2(-136.4, -560.2)
const EU := Vector2(0.9572344, 0.2893134)
const EV := Vector2(-0.2893134, 0.9572344)
const DOWN := -4.0
const PARA := 0.6                  # how far the parapets stand over the flat roofs
const COPE := 0.3                  # how wide their coping is
const BONES := "res://assets/colegiopub/calavera.glb"   # the skull and the long bone (tools/blender/calavera.py, made here)
const ALU := 0x8f969b
const GLASS := 0x2a3742
const WHITE := 0xf2f0ea
const MESH := 0x9aa0a4
const WOOD := 0x8a6a48
## the fence round it all, on the map, from the south-east corner: up the lane (north), along the Socorro (west),
## down the Huertos (south), along the backs of the houses of the Calle del Santo and the end of that street (east)
const FENCE: Array = [Vector2(-101.64, -480.72), Vector2(-99.4, -481.08), Vector2(-97.92, -482.98), Vector2(-65.88, -559.33),
	Vector2(-93.78, -567.34), Vector2(-178.52, -595.47), Vector2(-178.93, -595.16), Vector2(-177.6, -508.2), Vector2(-163.63, -506.34),
	Vector2(-163.35, -506.01), Vector2(-163.56, -505.17), Vector2(-152.69, -503.13), Vector2(-149.3, -501.59), Vector2(-149.4, -500.01),
	Vector2(-147.66, -499.2), Vector2(-147.42, -500.43), Vector2(-147.02, -500.64), Vector2(-139.0, -496.99), Vector2(-139.26, -495.31),
	Vector2(-138.47, -494.94), Vector2(-138.69, -493.76), Vector2(-138.14, -493.0), Vector2(-120.23, -486.67)]
const PITCH := Rect2(-168.3, -567.2, 20.0, 40.0)      # the futsal pitch, square to the map (its long side north to south)
const SANDBOX := Rect2(23.0, 53.0, 3.0, 3.0)          # the little ones' sandbox, in the sandy yard (u, v)
## its children's three yards (ninos.gd makes them, as in the nursery school's: the user, 27 Nov 2026, "que funcione como
## Calasanz, niños jugando y dando vueltas durante el horario escolar", and "Horario escolar 9 a 14", ninos.gd SCHOOL): [its name, the spots they run between (u, v), how
## big they are, where its picture is taken from (u, v)]. The spots clear of the trees, the goals, the walls and the fence,
## and out of the sandbox (where the skull is); the little ones in their sandy yard, the bigger ones on the pitch and all
## over the playground round it.
const KID_YARDS := [
	["colegiopub_arena", [Vector2(21.8, 55.0), Vector2(3.5, 48.5), Vector2(38.5, 63.5), Vector2(38.5, 48.5), Vector2(13.5, 58.5),
		Vector2(15.5, 48.5), Vector2(4.5, 57.5), Vector2(29.5, 62.5), Vector2(20.5, 62.5)], Vector2(0.5, 0.58), Vector2(30.0, 50.5)],
	["colegiopub_pista", [Vector2(-22.5, 3.5), Vector2(-19.5, 36.5), Vector2(-8.5, 19.5), Vector2(-25.5, 19.5), Vector2(-6.5, 32.5),
		Vector2(-12.5, 8.5), Vector2(-16.5, 26.5), Vector2(-27.5, 10.5), Vector2(-17.5, 15.5)], Vector2(0.6, 0.74), Vector2(-1.0, 20.0)],
	["colegiopub_patio", [Vector2(-10.5, 49.5), Vector2(-42.5, -3.5), Vector2(-1.5, 7.5), Vector2(-32.5, 26.5), Vector2(-0.5, 29.5),
		Vector2(-20.5, -3.5), Vector2(-27.5, 43.5), Vector2(-32.5, 9.5), Vector2(-22.5, 58.5)], Vector2(0.6, 0.74), Vector2(-14.0, 54.0)]]

var blocks: Array = []             # [outline on the map, its top in the world]: every building (the self-test, the map)
var lamps: Array = []
var door: Vector2                  # before the way in, on the map
var bones: Array = []              # where the old cemetery's skulls lie, on the map
var saffron_spot: Vector2          # its hidden saffron, in the sandbox's bucket (in the game's flowers, "id": "colegiopub")
var fl2 := 0.0                     # the floor of the two wings of two storeys, in the frame
var _south: Array = []             # [u0, u1, floor]: the two parts of the classrooms on the south, for the porch before them
var _runs := 0                     # (every other run of the fence a little higher, where two meet)

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"panel":            # the pale precast panels of the walls
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.94, 0.94, 0.91)), 0.16)
		"zocalo":
			m = Tex.mat("granular_concrete", Color(0.62, 0.62, 0.6))
		"muro":             # the low walls of the fence
			m = Tex.mat("granular_concrete", Color(0.84, 0.83, 0.8))
		"blanco":           # the white walls of the fence
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.99, 0.96)), 0.14)
		"cubierta":
			m = W._tmat(0x9c9a94, "asphalt", 3.0)
		"patio":
			m = W._tmat(0xb4b1aa, "asphalt", 4.0)
		"pista":
			m = W._tmat(0x9a8f86, "asphalt", 4.0)
		"losa":
			m = W._tmat(0xd2ccc0, "pavement", 1.2)
		"acera":
			m = W._tmat(0xc9c3b7, "pavement", 1.0)
		"asfalto":
			m = W._tmat(0x6f6c73, "asphalt", 3.0)
		"tierra":
			m = W._tmat(0xc9ab7c, "earth", 4.0)
		"huerto":
			m = W._tmat(0x7a5a3c, "earth", 2.0)
		"arena":
			m = W._tmat(0xdcc8a0, "earth", 2.5)
		"arenero":         # the sandbox's finer sand
			m = W._tmat(0xcdb68a, "earth", 1.5)
		"grava":
			m = W._tmat(0xb9b2a6, "earth", 1.2)
		"cesped":
			m = W._tmat(0x6f8f45, "grass", 2.0)
		"hoja":
			m = W._tmat(0x5f8a3e, "leaf", 1.5)
		"lechuga":
			m = W._tmat(0x7fae4a, "leaf", 0.6)
		"chapa":            # the gym's roof of grey sheet
			m = Parts.mat(0xb9bdc0)
		"junta":            # the joints between the panels
			m = Parts.mat(0xb3b3ae)
		"solar":
			var sm := StandardMaterial3D.new()
			sm.albedo_color = Color(0.11, 0.16, 0.27)
			sm.roughness = 0.3
			sm.metallic_specular = 0.6
			m = sm
		"cristal":
			var gm := StandardMaterial3D.new()
			gm.albedo_color = Color(0.5, 0.6, 0.66)
			gm.roughness = 0.3
			gm.metallic_specular = 0.4
			m = gm
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

func build(world) -> void:
	W = world
	level = MapData.height(map_at(28.0, 20.0))
	transform = Transform3D(Basis(Vector3(EU.x, 0, EU.y), Vector3.UP, Vector3(EV.x, 0, EV.y)), Vector3(A.x, level, A.y))
	W.add_child(self)
	door = map_at(59.5, 4.5)
	_grounds()
	_buildings()
	_gym()
	_porch()
	_courts()
	_yards()
	_park()
	_fences()
	_street_side()
	home()
	_commit()
	_bones()
	_saffron()
	_tell_map()

# ---------------- the frame ----------------
## a spot of the school (u, v) on the map
func map_at(u: float, v: float) -> Vector2:
	return A + EU * u + EV * v

## a spot of the map in the school's frame
func to_uv(p: Vector2) -> Vector2:
	var d := p - A
	return Vector2(d.dot(EU), d.dot(EV))

## the turn about the upright that sends the frame's +x along this way of the map (for things square to the map)
func _turn_of(dir: Vector2) -> float:
	var l := Vector2(dir.dot(EU), dir.dot(EV))
	return atan2(-l.y, l.x)

## where a spot of the wall being built (x along it, z out of it) is, in the frame (u, v)
func _fspot(x: float, z: float) -> Vector2:
	var p := _xf * Vector3(x, 0.0, z)
	return Vector2(p.x, p.z)

func _rnd(i: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + 4.1) * 43758.5453, 1.0)

# ---------------- laying things on the ground ----------------
## a flat thing lying on the ground with this outline (u, v), `lift` over it, cut along the relief's facets
func _lay(uv_pts: Array, lift: float, key) -> void:
	var wpoly := PackedVector2Array()
	for q: Vector2 in uv_pts:
		wpoly.append(map_at(q.x, q.y))
	_lay_map(wpoly, lift, key)

## the same, only what of it is inside the fence
func _lay_in(uv_pts: Array, lift: float, key) -> void:
	var wpoly := PackedVector2Array()
	for q: Vector2 in uv_pts:
		wpoly.append(map_at(q.x, q.y))
	for piece in Geometry2D.intersect_polygons(wpoly, PackedVector2Array(FENCE)):
		if piece.size() >= 3:
			_lay_map(piece, lift, key)

## the same, its outline on the map
func _lay_map(wpoly: PackedVector2Array, lift: float, key) -> void:
	if wpoly.size() < 3:
		return
	pieces += 1
	if Geometry2D.is_polygon_clockwise(wpoly):
		wpoly.reverse()
	var bx := Rect2(wpoly[0], Vector2.ZERO)
	for q in wpoly:
		bx = bx.expand(q)
	var g: float = MapData.rg
	for i in range(int(floor((bx.position.x - MapData.rx0) / g)), int(floor((bx.end.x - MapData.rx0) / g)) + 1):
		for j in range(int(floor((bx.position.y - MapData.rz0) / g)), int(floor((bx.end.y - MapData.rz0) / g)) + 1):
			var cell := Vector2(MapData.rx0 + i * g, MapData.rz0 + j * g)
			for facet in [PackedVector2Array([cell, cell + Vector2(g, 0), cell + Vector2(g, g)]), PackedVector2Array([cell, cell + Vector2(g, g), cell + Vector2(0, g)])]:
				if Geometry2D.is_polygon_clockwise(facet):
					facet.reverse()
				for piece in Geometry2D.intersect_polygons(wpoly, facet):
					if piece.size() < 3 or Geometry2D.is_polygon_clockwise(piece):
						continue
					var idx := Geometry2D.triangulate_polygon(piece)
					for t in range(0, idx.size(), 3):
						tri(_on(piece[idx[t]], lift), _on(piece[idx[t + 1]], lift), _on(piece[idx[t + 2]], lift), key, Vector3.UP)

## a spot on the map as a point of the frame, `lift` over the ground there
func _on(w: Vector2, lift: float) -> Vector3:
	var f := to_uv(w)
	return Vector3(f.x, MapData.height(w) - level + lift, f.y)

func _rect(u0: float, v0: float, u1: float, v1: float) -> Array:
	return [Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1)]

## a thin line painted on the ground from a to b (on the map)
func _line(a: Vector2, b: Vector2, lift: float, w := 0.08) -> void:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x) * w / 2.0
	_lay_map(PackedVector2Array([a - n, b - n, b + n, a + n]), lift, WHITE)

# ---------------- the ground inside the fence ----------------
func _grounds() -> void:
	_lay_map(PackedVector2Array(FENCE), 0.03, "patio")                              # concrete all over
	_lay_in(_rect(-1.0, -22.0, 72.0, 0.0), 0.05, "tierra")                        # the earth north of the wings
	_lay_in(_rect(56.0, 0.0, 72.0, 29.0), 0.05, "tierra")                         # ...and east of the east wing
	_lay_in([Vector2(57.5, -22.0), Vector2(63.5, -22.0), Vector2(63.5, 6.5), Vector2(56.0, 6.5), Vector2(56.0, 2.0), Vector2(57.5, 2.0)], 0.065, "losa")   # the way to the door
	_lay_in(_rect(1.5, -22.0, 9.5, -17.0), 0.065, "losa")                        # inside the other gate on the Socorro
	_lay([Vector2(2.0, 11.4), Vector2(45.8, 11.4), Vector2(45.8, 13.75), Vector2(16.8, 13.75), Vector2(16.8, 16.0), Vector2(2.0, 16.0)], 0.05, "grava")   # the light well
	_lay_in(_rect(2.0, 47.4, 40.0, 72.0), 0.05, "arena")                         # the little ones' yard
	_lay_in(_rect(40.5, 47.4, 45.8, 72.0), 0.05, "asfalto")                      # the path from the south gate
	_lay(_rect(2.4, 44.6, 45.8, 47.4), 0.05, "losa")                             # under the porch
	_lay_map(PackedVector2Array([PITCH.position, Vector2(PITCH.end.x, PITCH.position.y), PITCH.end, Vector2(PITCH.position.x, PITCH.end.y)]), 0.05, "pista")

# ---------------- the buildings ----------------
## the floor of a building over these rectangles [u0, v0, u1, v1]: half way between the ground's middle and its highest,
## and never more than 30 cm under the ground anywhere (the rest shows as a plinth: the street falls away)
func _floor_of(rects: Array) -> float:
	var sum := 0.0
	var n := 0
	var top := -1e9
	for r in rects:
		for i in range(5):
			for j in range(5):
				var g: float = ground(lerpf(r[0], r[2], i / 4.0), lerpf(r[1], r[3], j / 4.0))
				sum += g
				n += 1
				top = maxf(top, g)
	return maxf(sum / n + 0.15, top - 0.3)

## the windows of one side of a building, by its look, between x0 and x1 along it
func _holes(kind: String, fl: float, x0: float, x1: float) -> Array:
	var out: Array = []
	match kind:
		"aulas2", "aulas2f":                     # the classrooms' windows, on two floors
			var n := int(floor((x1 - x0 - 1.0) / 3.6))
			if n < 1:
				return out
			var step: float = (x1 - x0 - 1.0) / n
			for i in range(n):
				var cx: float = x0 + 0.5 + step * (i + 0.5)
				for y in [fl + 1.0, fl + 4.6]:
					out.append(Rect2(cx - 1.2, y, 2.4, 1.6))
		"banda1", "banda2":                      # a band of windows side by side, on one floor or two
			var n := int(floor((x1 - x0 - 0.8) / 2.1))
			if n < 1:
				return out
			var step: float = (x1 - x0 - 0.8) / n
			var rows: Array = [fl + 1.0] if kind == "banda1" else [fl + 1.0, fl + 4.6]
			for i in range(n):
				for y in rows:
					out.append(Rect2(x0 + 0.4 + step * i + 0.15, y, step - 0.3, 1.5))
		"huecos2":                               # the north side: small square windows and narrow slits here and there
			var x: float = x0 + 1.4
			var i := 0
			while x < x1 - 1.6:
				var r := _rnd(i)
				var up := _rnd(i + 31) > 0.45
				if r < 0.3:
					out.append(Rect2(x, fl + (4.4 if up else 0.9), 0.35, 1.9))
					x += 0.35
				else:
					out.append(Rect2(x, fl + (4.9 if up else 1.3), 0.95, 0.95))
					x += 0.95
				x += 1.6 + 2.2 * _rnd(i + 17)
				i += 1
		"rejilla":                               # a louvre (the annex's machines)
			out.append(Rect2((x0 + x1) / 2.0 - 1.5, fl + 2.4, 3.0, 1.3))
	return out

## A building: walls of pale panels on a grey plinth, its windows by `looks` (side "n", "e", "s" or "w" -> its look, or
## [look, from, to] along the side (to < 0: its end), or [look, from, to, y0]: only from y0 up, where a lower building
## stands against it; a side left out stands against a building as tall or taller and is not built), its
## doors and big windows `extra` (side -> [[Rect2, "puerta" or "vidriera"]]), a flat roof behind a parapet with its
## coping; solid. Returns its top (the roof).
func _block(u0: float, v0: float, u1: float, v1: float, fl: float, h: float, looks: Dictionary, extra := {}) -> float:
	var top := fl + h
	var two := h > 6.0
	var sides := {"n": [Vector2(u1, v0), Vector2(u0, v0)], "e": [Vector2(u1, v1), Vector2(u1, v0)], "s": [Vector2(u0, v1), Vector2(u1, v1)], "w": [Vector2(u0, v0), Vector2(u0, v1)]}
	for k in ["n", "e", "s", "w"]:
		if not looks.has(k):
			continue
		var ln: float = face(sides[k][0], sides[k][1])
		var look = looks[k]
		var kind: String = look if look is String else String(look[0])
		var x0: float = 0.0 if look is String else float(look[1])
		var x1: float = ln if look is String or float(look[2]) < 0.0 else float(look[2])
		var y0: float = DOWN if look is String or look.size() < 4 else float(look[3])
		var holes: Array = _holes(kind, fl, x0, x1)
		var more: Array = extra.get(k, [])
		for e in more:
			var er: Rect2 = (e[0] as Rect2).grow(0.3)
			holes = holes.filter(func(r: Rect2) -> bool: return not r.intersects(er))
		var all_holes: Array = holes.duplicate()
		for e in more:
			all_holes.append(e[0])
		masonry(0.0, ln, y0, top + PARA, all_holes, [], "panel")
		quad(Vector3(ln, top, -COPE), Vector3(0, top, -COPE), Vector3(0, top + PARA, -COPE), Vector3(ln, top + PARA, -COPE), "panel", Vector3(0, 0, -1))
		# the plinth, broken at the doors
		var cuts: Array = []
		for e in more:
			var er: Rect2 = e[0]
			if er.position.y < fl + 0.4:
				var cut: float = maxf(0.1, _step_wide(er, fl) + 0.03)
				cuts.append(Vector2(er.position.x - cut, er.end.x + cut))
		cuts.sort_custom(func(p: Vector2, q: Vector2) -> bool: return p.x < q.x)
		var from := 0.0
		for c: Vector2 in cuts + [Vector2(ln, ln)]:
			if c.x - from > 0.01 and y0 < fl:
				box(from, DOWN, 0.0, c.x - from, fl + 0.35 - DOWN, 0.03, "zocalo")
			from = c.y
		# the joints of the panels
		if two:                                   # the band between the floors (broken where the fins stand out)
			var at := 0.0
			if kind == "aulas2f":
				var nf := int(floor((x1 - x0 - 1.0) / 3.6))
				var sf: float = (x1 - x0 - 1.0) / maxf(nf, 1)
				for i in range(nf + 1):
					var fx: float = x0 + 0.5 + sf * i
					box(at, fl + 3.72, 0.0, fx - 0.08 - at, 0.08, 0.022, "junta")
					at = fx + 0.08
			box(at, fl + 3.72, 0.0, ln - at, 0.08, 0.022, "junta")
		if (kind == "liso" or kind == "huecos2") and y0 < fl:      # ("oculto": a side mostly hidden, plain)
			var x := 2.4
			while x < ln - 0.5:
				var clear := true
				for r: Rect2 in all_holes:
					if x > r.position.x - 0.12 and x < r.end.x + 0.12:
						clear = false
				if clear and two:
					box(x - 0.015, fl + 0.35, 0.0, 0.03, 3.37, 0.012, "junta")
					box(x - 0.015, fl + 3.8, 0.0, 0.03, top + PARA - fl - 3.85, 0.012, "junta")
				elif clear:
					box(x - 0.015, fl + 0.35, 0.0, 0.03, top + PARA - fl - 0.4, 0.012, "junta")
				x += 2.4
		# its windows
		for r: Rect2 in holes:
			if kind == "rejilla":
				box(r.position.x, r.position.y, -0.2, r.size.x, r.size.y, 0.02, 0x3a3e42)
				for j in range(int(r.size.y / 0.13)):
					tbox(Transform3D(Basis(Vector3.RIGHT, 0.6).scaled_local(Vector3(r.size.x - 0.04, 0.02, 0.14)), Vector3(r.position.x + r.size.x / 2.0, r.position.y + 0.08 + j * 0.13, -0.1)), ALU)
			else:
				window(r, ALU, GLASS, 0)
			box(r.position.x - 0.05, r.position.y - 0.06, 0.0, r.size.x + 0.1, 0.06, 0.1, "zocalo")
		if kind == "aulas2f":                     # the fins between the windows
			var n := int(floor((x1 - x0 - 1.0) / 3.6))
			var step: float = (x1 - x0 - 1.0) / maxf(n, 1)
			for i in range(n + 1):
				box(x0 + 0.5 + step * i - 0.08, fl + 0.35, 0.0, 0.16, h - 0.55, 0.45, "panel")
		# its doors and big windows
		for e in more:
			var r: Rect2 = e[0]
			if e[1] == "puerta":
				box(r.position.x, r.position.y, -0.22, r.size.x, r.size.y, 0.03, GLASS)
				for x in [r.position.x, r.position.x + r.size.x / 2.0 - 0.04, r.end.x - 0.08]:
					box(x, r.position.y, -0.2, 0.08, r.size.y, 0.06, ALU)
				box(r.position.x, r.end.y - 0.12, -0.2, r.size.x, 0.12, 0.06, ALU)
				box(r.position.x, r.position.y + 1.0, -0.2, r.size.x, 0.06, 0.06, ALU)
				_surround(r)
				_steps(r, fl)
			else:
				box(r.position.x, r.position.y, -0.2, r.size.x, r.size.y, 0.03, GLASS)
				var n := maxi(2, int(round(r.size.x / 1.2)))
				for i in range(n + 1):
					box(r.position.x + r.size.x * i / n - 0.04, r.position.y, -0.18, 0.08, r.size.y, 0.06, ALU)
				box(r.position.x, r.position.y + r.size.y / 2.0 - 0.03, -0.18, r.size.x, 0.06, 0.06, ALU)
				_surround(r)
	home()
	# the coping all round what is built: the north and south strips whole, the east and west ones between them
	var o := 0.03
	var cw: bool = looks.has("w")
	var ce: bool = looks.has("e")
	var cn: bool = looks.has("n")
	var cs: bool = looks.has("s")
	var ua: float = u0 - (o if cw else 0.0)
	var ub: float = u1 + (o if ce else 0.0)
	if cn:
		box(ua, top + PARA, v0 - o, ub - ua, 0.1, COPE + o, 0xd9d8d2)
	if cs:
		box(ua, top + PARA, v1 - COPE, ub - ua, 0.1, COPE + o, 0xd9d8d2)
	var va: float = v0 + (COPE if cn else 0.0)
	var vb: float = v1 - (COPE if cs else 0.0)
	if cw:
		box(u0 - o, top + PARA, va, COPE + o, 0.1, vb - va, 0xd9d8d2)
	if ce:
		box(u1 - COPE, top + PARA, va, COPE + o, 0.1, vb - va, 0xd9d8d2)
	flat(PackedVector2Array([Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1)]), top, "cubierta")
	_prism(_rect(u0, v0, u1, v1), DOWN, top + PARA)
	blocks.append([PackedVector2Array([map_at(u0, v0), map_at(u1, v0), map_at(u1, v1), map_at(u0, v1)]), level + top + PARA])
	return top

## the aluminium surround of a door or a big window: its jambs wrap 2 cm into the hole, its head a little prouder and
## 2 cm down into it (so that no face of it lies on the hole's own: the kit's door_frame lays its head on the top of
## the reveal)
func _surround(r: Rect2) -> void:
	box(r.position.x - 0.08, r.position.y, -0.02, 0.1, r.size.y - 0.02, 0.05, ALU)
	box(r.end.x - 0.02, r.position.y, -0.02, 0.1, r.size.y - 0.02, 0.05, ALU)
	box(r.position.x - 0.08, r.end.y - 0.02, -0.02, r.size.x + 0.16, 0.1, 0.055, ALU)

## how far the widest of a door's steps reaches beyond its sides (0: it has none)
func _step_wide(r: Rect2, fl: float) -> float:
	var at := _fspot(r.get_center().x, 0.3)
	var rise: float = fl - ground(at.x, at.y)
	if rise < 0.05:
		return 0.0
	return 0.2 + 0.02 * (maxi(1, int(ceil(rise / 0.16))) - 1)

## the steps up to a door from the ground before it (the wall being built), solid
func _steps(r: Rect2, fl: float) -> void:
	var at := _fspot(r.get_center().x, 0.3)
	var g: float = ground(at.x, at.y)
	var rise := fl - g
	if rise < 0.05:
		return
	var n := maxi(1, int(ceil(rise / 0.16)))
	for k in range(n):
		var y: float = fl - rise * k / n
		var wide: float = 0.2 + 0.02 * k
		box(r.position.x - wide, g - 0.3, 0.0, r.size.x + 2.0 * wide, y - (g - 0.3), 0.9 + 0.32 * k, "losa")
	var mid := _xf * Vector3(r.get_center().x, (fl + g - 0.3) / 2.0, (0.9 + 0.32 * (n - 1)) / 2.0)
	solid(mid, Vector3(r.size.x + 0.4, fl - g + 0.3, 0.9 + 0.32 * (n - 1)), -atan2(_xf.basis.x.z, _xf.basis.x.x))

func _buildings() -> void:
	# the two wings of two storeys, on one floor: the north one along the Socorro side, the east one by the car park,
	# the way in on its east side by the corner, under a canopy, and the name round the corner, on its north side
	fl2 = _floor_of([[0.0, 0.0, 45.8, 11.4], [45.8, 0.0, 56.0, 29.2]])
	_block(0.0, 0.0, 45.8, 11.4, fl2, 7.8, {"n": "huecos2", "s": "aulas2f", "w": "aulas2"})
	var east_door := Rect2(22.7, fl2, 3.0, 2.6)
	_block(45.8, 0.0, 56.0, 29.2, fl2, 7.8, {"n": "huecos2", "e": "aulas2", "s": "banda2", "w": "liso"},
		{"e": [[east_door, "puerta"], [Rect2(19.7, fl2 + 4.2, 7.0, 2.2), "vidriera"]]})
	face(Vector2(56.0, 29.2), Vector2(56.0, 0.0))
	box(east_door.position.x - 1.0, fl2 + 2.85, 0.0, east_door.size.x + 2.0, 0.25, 2.2, 0xd9d8d2)       # the canopy over the door
	box(east_door.position.x - 1.02, fl2 + 2.83, 2.2, east_door.size.x + 2.04, 0.29, 0.03, 0x5a5f63)
	solid(_xf * Vector3(east_door.get_center().x, fl2 + 2.97, 1.1), Vector3(east_door.size.x + 2.0, 0.25, 2.2), -atan2(_xf.basis.x.z, _xf.basis.x.x))
	home()
	face(Vector2(56.0, 0.0), Vector2(45.8, 0.0))                                            # the name, on the north side
	for k in range(2):
		var l := _text(NAME, Vector3(5.1, fl2 + 6.75, 0.035 + 0.025 * k), 120, 0x3b4656 if k == 0 else 0x56657c, 0.0042)
		l.outline_size = 12
		l.outline_modulate = l.modulate
	home()
	# the classrooms of one storey behind them, round the light well and the small patio on the west
	var m1 := _floor_of([[2.0, 16.0, 16.8, 29.2]])
	var m2 := _floor_of([[16.8, 13.75, 45.8, 29.2]])
	var top2 := _block(16.8, 13.75, 45.8, 29.2, m2, 4.6, {"n": "banda1", "s": "oculto", "w": "liso"})
	if m1 + 4.6 > top2:
		m1 = top2 - 4.6
	_block(2.0, 16.0, 16.8, 29.2, m1, 4.6, {"n": "banda1", "w": "banda1", "s": ["banda1", 0.0, 9.6]})
	var lk := _floor_of([[11.6, 29.2, 45.8, 35.6]])
	lk = minf(lk, minf(m1, m2) - 0.1)
	var s1 := _floor_of([[2.4, 35.6, 20.0, 44.6]])
	var s2 := _floor_of([[20.0, 35.6, 45.8, 44.6]])
	s1 = minf(s1, s2 - 0.05)
	s2 = minf(s2, lk + 4.4 - 4.2 - 0.05)
	s1 = minf(s1, s2 - 0.05)
	_block(11.6, 29.2, 45.8, 35.6, lk, 4.4, {"e": "banda1", "s": ["liso", 0.0, -1.0, s1 + 4.2], "w": "banda1"}, {"e": [[Rect2(1.6, lk, 1.8, 2.4), "puerta"]]})
	_block(20.0, 35.6, 45.8, 44.6, s2, 4.2, {"n": "oculto", "e": "banda1", "s": "banda1", "w": "oculto"},
		{"s": [[Rect2(4.0, s2, 1.8, 2.4), "puerta"], [Rect2(15.5, s2, 1.8, 2.4), "puerta"]]})
	_block(2.4, 35.6, 20.0, 44.6, s1, 4.2, {"n": ["banda1", 8.4, 17.6], "s": "banda1", "w": "banda1"},
		{"s": [[Rect2(7.0, s1, 1.8, 2.4), "puerta"]]})
	_south = [[2.4, 20.0, s1], [20.0, 45.8, s2]]
	# on the roofs: the solar panels over the classrooms, the machines at the south end of the east wing
	var y2: float = top2 + 0.15
	for v in [15.4, 18.2, 21.0, 23.8, 26.6]:
		for k in range(2):
			var ua: float = 18.6 + k * 13.2
			tbox(Transform3D(Basis(Vector3.RIGHT, deg_to_rad(20.0)).scaled_local(Vector3(12.4, 0.05, 1.1)), Vector3(ua + 6.2, y2 + 0.2, v)), "solar")
			for uu in [ua + 0.4, ua + 6.2, ua + 12.0]:
				cbox(Vector3(uu, (top2 + y2 + 0.36) / 2.0, v - 0.45), Vector3(0.05, y2 + 0.36 - top2, 0.05), ALU)
	for q in [Vector2(48.6, 24.5), Vector2(51.8, 24.5), Vector2(48.6, 26.9)]:
		cbox(Vector3(q.x, fl2 + 7.8 + 0.5, q.y), Vector3(2.2, 1.0, 1.6), 0xc9cbcc)
		cbox(Vector3(q.x, fl2 + 7.8 + 1.02, q.y), Vector3(0.8, 0.04, 0.8), 0x5a5f63)

# ---------------- the gym ----------------
## The gym: a tall hall of the same panels with a band of glass high up on its long sides, a shallow roof of grey
## sheet, its low annex on the east with a louvre
func _gym() -> void:
	var u0 := -28.3
	var v0 := -19.2
	var u1 := -7.0
	var v1 := -6.7
	var fl := _floor_of([[u0, v0, u1, v1]])
	var eave := fl + 8.6
	var ridge := eave + 1.0
	var sides := {"n": [Vector2(u1, v0), Vector2(u0, v0)], "e": [Vector2(u1, v1), Vector2(u1, v0)], "s": [Vector2(u0, v1), Vector2(u1, v1)], "w": [Vector2(u0, v0), Vector2(u0, v1)]}
	for k in ["n", "e", "s", "w"]:
		var ln: float = face(sides[k][0], sides[k][1])
		var holes: Array = []
		if k == "n" or k == "s":
			holes.append(Rect2(0.8, fl + 6.0, ln - 1.6, 1.8))
		if k == "s":
			holes.append(Rect2(ln - 4.2, fl, 2.4, 2.8))
		if k == "w":
			holes.append(Rect2(ln / 2.0 - 1.2, fl, 2.4, 2.8))
		masonry(0.0, ln, DOWN, eave, holes, [], "panel")
		var from := 0.0
		for r: Rect2 in holes:
			if r.position.y < fl + 0.4:
				var cut: float = maxf(0.1, _step_wide(r, fl) + 0.03)
				box(from, DOWN, 0.0, r.position.x - cut - from, fl + 0.35 - DOWN, 0.03, "zocalo")
				from = r.end.x + cut
		box(from, DOWN, 0.0, ln - from, fl + 0.35 - DOWN, 0.03, "zocalo")
		var x := 2.4
		while x < ln - 0.5:
			var clear := true
			for r: Rect2 in holes:
				if x > r.position.x - 0.12 and x < r.end.x + 0.12 and r.position.y < fl + 3.0:
					clear = false
			if clear:
				box(x - 0.015, fl + 0.35, 0.0, 0.03, (fl + 5.95 if k == "n" or k == "s" else eave - 0.05) - fl - 0.35, 0.015, "junta")
			x += 2.4
		for r: Rect2 in holes:
			box(r.position.x, r.position.y, -0.2, r.size.x, r.size.y, 0.03, "cristal" if r.position.y > fl + 1.0 else GLASS)
			if r.position.y > fl + 1.0:
				var n := int(r.size.x / 1.5)
				for i in range(n + 1):
					box(r.position.x + r.size.x * i / n - 0.04, r.position.y, -0.18, 0.08, r.size.y, 0.06, ALU)
				box(r.position.x - 0.05, r.position.y - 0.06, 0.0, r.size.x + 0.1, 0.06, 0.1, "zocalo")
			else:
				box(r.position.x, r.position.y, -0.18, 0.08, r.size.y, 0.06, 0x3c4a5a)
				box(r.end.x - 0.08, r.position.y, -0.18, 0.08, r.size.y, 0.06, 0x3c4a5a)
				box(r.position.x + r.size.x / 2.0 - 0.03, r.position.y, -0.18, 0.06, r.size.y, 0.06, 0x3c4a5a)
				_surround(r)
				_steps(r, fl)
		if k == "n" or k == "s":
			box(-0.05, eave - 0.3, 0.0, ln + 0.1, 0.3, 0.05, 0xd9d8d2)
		else:
			box(0.0, eave - 0.3, 0.0, ln, 0.3, 0.05, 0xd9d8d2)
		if k == "e" or k == "w":                   # the gable ends
			tri(Vector3(0, eave, 0), Vector3(ln, eave, 0), Vector3(ln / 2.0, ridge, 0), "panel", Vector3(0, 0, 1))
	home()
	var vm := (v0 + v1) / 2.0
	roof([Vector3(u0 - 0.3, eave - 0.06, v0 - 0.3), Vector3(u1 + 0.3, eave - 0.06, v0 - 0.3), Vector3(u1 + 0.3, ridge + 0.02, vm), Vector3(u0 - 0.3, ridge + 0.02, vm)], "chapa")
	roof([Vector3(u0 - 0.3, ridge + 0.02, vm), Vector3(u1 + 0.3, ridge + 0.02, vm), Vector3(u1 + 0.3, eave - 0.06, v1 + 0.3), Vector3(u0 - 0.3, eave - 0.06, v1 + 0.3)], "chapa")
	for u in [u0 - 0.3, u1 + 0.3]:                 # the sheet's edges
		bar(Vector3(u, eave - 0.06, v0 - 0.3), Vector3(u, ridge + 0.02, vm), 0.06, 0.12, 0x8c9094)
		bar(Vector3(u, ridge + 0.02, vm), Vector3(u, eave - 0.06, v1 + 0.3), 0.06, 0.12, 0x8c9094)
	_prism(_rect(u0, v0, u1, v1), DOWN, eave)
	_prism([Vector2(u0, vm - 0.5), Vector2(u1, vm - 0.5), Vector2(u1, vm + 0.5), Vector2(u0, vm + 0.5)], eave, ridge)
	blocks.append([PackedVector2Array([map_at(u0, v0), map_at(u1, v0), map_at(u1, v1), map_at(u0, v1)]), level + ridge])
	var fa := _floor_of([[-7.0, v0, -0.8, v1]])
	_block(-7.0, v0, -0.8, v1, fa, 5.0, {"n": "rejilla", "e": "banda1", "s": "liso"}, {"s": [[Rect2(1.6, fa, 1.1, 2.3), "puerta"]]})

# ---------------- the porch ----------------
## along the south of the classrooms of one storey: a flat canopy on slim posts over the paving, a dark edge to it
func _porch() -> void:
	for p in _south:
		var ua: float = p[0]
		var ub: float = p[1]
		var y: float = float(p[2]) + 3.1
		box(ua, y, 44.6, ub - ua, 0.22, 2.8, 0xe2e1dc)
		box(ua - (0.02 if ua < 3.0 else 0.0), y - 0.02, 47.4, ub - ua + (0.02 if ua < 3.0 else 0.0) + (0.02 if ub > 45.0 else 0.0), 0.26, 0.03, 0x5a5f63)
		if ua < 3.0:
			box(ua - 0.02, y - 0.02, 44.6, 0.02, 0.26, 2.83, 0x5a5f63)
		if ub > 45.0:
			box(ub, y - 0.02, 44.6, 0.02, 0.26, 2.83, 0x5a5f63)
		var n := maxi(2, int(round((ub - ua) / 4.4)))
		for i in range(n + 1):
			var u: float = lerpf(ua + 0.3, ub - 0.3, float(i) / n)
			var g: float = ground(u, 47.1)
			cbox(Vector3(u, (g + y) / 2.0, 47.1), Vector3(0.14, y - g, 0.14), ALU)
			solid(Vector3(u, (g + y) / 2.0, 47.1), Vector3(0.18, y - g, 0.18))
			yard.append(map_at(u, 47.1))
	# the three square beds of grass before it, a little tree in each
	for u in [10.2, 22.1, 33.5]:
		_lay(_rect(u - 1.2, 47.8, u + 1.2, 50.2), 0.065, "cesped")
		_tree(Vector2(u, 49.0), 4.2, 1.5)

# ---------------- the playground ----------------
## the futsal pitch's lines and goals; two hoops and three floodlights by the wall on the Calle de los Huertos
func _courts() -> void:
	var p0 := PITCH.position + Vector2(0.4, 0.4)
	var p1 := PITCH.end - Vector2(0.4, 0.4)
	var mx := (p0.x + p1.x) / 2.0
	var mz := (p0.y + p1.y) / 2.0
	for ln in [[Vector2(p0.x, p0.y - 0.04), Vector2(p0.x, p1.y + 0.04)], [Vector2(p1.x, p0.y - 0.04), Vector2(p1.x, p1.y + 0.04)],
			[Vector2(p0.x + 0.04, p0.y), Vector2(p1.x - 0.04, p0.y)], [Vector2(p0.x + 0.04, p1.y), Vector2(p1.x - 0.04, p1.y)], [Vector2(p0.x + 0.04, mz), Vector2(p1.x - 0.04, mz)]]:
		_line(ln[0], ln[1], 0.065)
	var ring: Array = []
	for i in range(25):
		ring.append(Vector2(mx, mz) + Vector2(cos(TAU * i / 24.0), sin(TAU * i / 24.0)) * 3.0)
	for i in range(24):
		_line(ring[i], ring[i + 1], 0.08)
	for s in [-1.0, 1.0]:                            # the areas before each goal, and the goals
		var gz: float = p0.y if s < 0.0 else p1.y
		var arc: Array = []
		for i in range(13):
			var t := PI * i / 12.0
			arc.append(Vector2(mx + cos(t) * 6.0, gz - s * sin(t) * 6.0))
		for i in range(12):
			_line(arc[i], arc[i + 1], 0.08)
		var o := to_uv(Vector2(mx, gz))
		var keep := _xf
		_xf = Transform3D(Basis(Vector3.UP, _turn_of(Vector2(0, s))), Vector3(o.x, ground(o.x, o.y), o.y))
		for zz in [-1.5, 1.5]:
			box(-0.04, 0.0, zz - 0.04, 0.08, 2.0, 0.08, WHITE)
			bar(Vector3(0, 2.0, zz), Vector3(0.9, 0.05, zz), 0.03, 0.03, 0xd9d6cc)
		box(-0.04, 1.96, -1.54, 0.08, 0.08, 3.08, WHITE)
		bar(Vector3(0.9, 0.05, -1.5), Vector3(0.9, 0.05, 1.5), 0.03, 0.03, 0xd9d6cc)
		for k in range(1, 6):
			bar(Vector3(0, 2.0, -1.5 + k * 0.5), Vector3(0.9, 0.05, -1.5 + k * 0.5), 0.012, 0.012, 0xd9d6cc)
		var at := _xf * Vector3(0.3, 1.0, 0.0)
		solid(at, Vector3(0.6, 2.0, 3.2), _turn_of(Vector2(0, s)))
		_xf = keep
		yard.append(Vector2(mx, gz))
	var w0: Vector2 = FENCE[6]
	var w1: Vector2 = FENCE[7]
	var wd: Vector2 = (w1 - w0).normalized()
	var inn := Vector2(wd.y, -wd.x)
	if inn.dot(map_at(0.0, 20.0) - w0) < 0.0:
		inn = -inn
	for t in [0.33, 0.6]:                             # the hoops, facing the playground
		var at: Vector2 = w0.lerp(w1, t) + inn * 0.9
		var o := to_uv(at)
		var keep := _xf
		_xf = Transform3D(Basis(Vector3.UP, _turn_of(inn)), Vector3(o.x, ground(o.x, o.y), o.y))
		cbox(Vector3(0, 1.6, 0), Vector3(0.14, 3.2, 0.14), 0x2a5fb0)
		bar(Vector3(0, 3.2, 0), Vector3(0.95, 3.2, 0), 0.1, 0.1, 0x2a5fb0)
		cbox(Vector3(1.0, 3.45, 0), Vector3(0.05, 1.05, 1.8), WHITE)
		cbox(Vector3(1.03, 3.4, 0), Vector3(0.02, 0.45, 0.59), 0xd8243a)
		drum(Vector3(1.3, 3.05, 0), 0.23, 0.23, 0.03, 0xe0602a, 12)
		var at3 := _xf * Vector3(0, 1.6, 0)
		solid(at3, Vector3(0.2, 3.2, 0.2))
		_xf = keep
		yard.append(at)
	for t in [0.18, 0.47, 0.8]:                       # the floodlights
		var at: Vector2 = w0.lerp(w1, t) + inn * 1.3
		var o := to_uv(at)
		var g: float = ground(o.x, o.y)
		var base := Vector3(o.x, g, o.y)
		drum(base, 0.14, 0.09, 10.0, 0x9aa0a4, 8)
		var keep := _xf
		_xf = Transform3D(Basis(Vector3.UP, _turn_of(inn)), base)
		box(-0.15, 9.95, -0.5, 0.3, 0.3, 1.0, 0x5a5d60)
		box(0.15, 9.9, -0.45, 0.02, 0.22, 0.9, "foco")
		_xf = keep
		solid(base + Vector3(0, 2.0, 0), Vector3(0.3, 4.0, 0.3))
		var w: Vector3 = transform * (base + Vector3(0, 9.9, 0))
		W.lamp_spots.append(w)
		lamps.append(w)
		yard.append(at)

# ---------------- the yards ----------------
## the vegetable beds in the earth of the north, the sandbox in the little ones' yard, the trees
func _yards() -> void:
	for r in [[3.0, -12.5, 13.0, -10.0], [3.0, -9.0, 11.0, -7.5]]:
		var u0: float = r[0]
		var v0: float = r[1]
		var u1: float = r[2]
		var v1: float = r[3]
		var g := -1e9
		for q: Vector2 in _rect(u0, v0, u1, v1):
			g = maxf(g, ground(q.x, q.y))
		var y := g + 0.42
		box(u0, g - 0.4, v0, u1 - u0, y - g + 0.4, v1 - v0, "brick")                           # its low wall of brick...
		flat(PackedVector2Array([Vector2(u0 + 0.12, v0 + 0.12), Vector2(u1 - 0.12, v0 + 0.12), Vector2(u1 - 0.12, v1 - 0.12), Vector2(u0 + 0.12, v1 - 0.12)]), y + 0.015, "huerto")   # ...the earth in it...
		var n := int((u1 - u0 - 0.6) / 0.55)
		for i in range(n):
			for j in range(int((v1 - v0 - 0.4) / 0.5)):
				var at := Vector2(u0 + 0.4 + i * 0.55, v0 + 0.35 + j * 0.5)
				if _rnd(i * 7 + j) > 0.2 and at.distance_to(Vector2(11.6, -11.0)) > 0.75:      # (room left round the bone dug up)
					ball(Vector3(u0 + 0.4 + i * 0.55, y + 0.1, v0 + 0.35 + j * 0.5), 0.15, "lechuga", 0.6, 7, 4)   # ...and the lettuces
		_prism(_rect(u0, v0, u1, v1), g - 0.4, y)
		yard.append(map_at((u0 + u1) / 2.0, (v0 + v1) / 2.0))
	# the sandbox: a frame of boards, finer sand in it, a bucket and a spade the little ones left
	var s := SANDBOX
	_lay(_rect(s.position.x + 0.1, s.position.y + 0.1, s.end.x - 0.1, s.end.y - 0.1), 0.068, "arenero")
	for e in [[s.position, Vector2(s.end.x, s.position.y)], [Vector2(s.end.x, s.position.y), s.end], [s.end, Vector2(s.position.x, s.end.y)], [Vector2(s.position.x, s.end.y), s.position]]:
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		var hi: float = 0.005 if absf(a.y - b.y) < 0.01 else 0.0
		bar(Vector3(a.x, ground(a.x, a.y) + 0.09 + hi, a.y), Vector3(b.x, ground(b.x, b.y) + 0.09 + hi, b.y), 0.12, 0.2 + 2.0 * hi, WOOD)
	var bk := Vector2(s.end.x - 0.7, s.position.y + 0.8)
	var by := ground(bk.x, bk.y) + 0.06
	drum(Vector3(bk.x, by, bk.y), 0.09, 0.12, 0.17, 0xd83a2a, 10)
	bar(Vector3(bk.x - 0.11, by + 0.17, bk.y), Vector3(bk.x, by + 0.27, bk.y), 0.012, 0.012, 0xd83a2a)
	bar(Vector3(bk.x, by + 0.27, bk.y), Vector3(bk.x + 0.11, by + 0.17, bk.y), 0.012, 0.012, 0xd83a2a)
	var sp := Vector2(s.position.x + 0.6, s.end.y - 0.6)
	var sy := ground(sp.x, sp.y) + 0.075
	bar(Vector3(sp.x, sy, sp.y), Vector3(sp.x + 0.3, sy + 0.02, sp.y - 0.12), 0.025, 0.025, 0x2a6ad8)
	tbox(Transform3D(Basis(Vector3.UP, 0.38).scaled_local(Vector3(0.14, 0.015, 0.1)), Vector3(sp.x - 0.06, sy - 0.005, sp.y + 0.03)), 0x2a6ad8)
	# the trees: by the lane, in the earth of the north, in the little ones' yard
	for q in [Vector2(62.0, 10.0), Vector2(61.4, 17.0), Vector2(60.8, 24.0), Vector2(25.0, -14.5), Vector2(36.0, -12.0), Vector2(47.0, -15.0)]:
		_tree(q, 5.5, 1.9)
	for q in [Vector2(5.5, 53.0), Vector2(12.0, 57.5), Vector2(17.5, 52.5), Vector2(30.0, 57.0), Vector2(35.5, 52.0), Vector2(38.0, 58.5), Vector2(8.0, 58.5)]:
		_tree(q, 5.0, 1.8)

## a small tree: a trunk, a crown of a few balls (u, v)
func _tree(at: Vector2, tall: float, crown: float, key = "hoja") -> void:
	var o := Vector3(at.x, ground(at.x, at.y), at.y)
	drum(o - Vector3(0, 0.1, 0), 0.15, 0.1, tall * 0.55, 0x6b5a45, 7)
	ball(o + Vector3(0, tall * 0.72, 0), crown, key, 0.85, 9, 5)
	ball(o + Vector3(crown * 0.55, tall * 0.64, -crown * 0.3), crown * 0.7, key, 0.85, 8, 5)
	ball(o + Vector3(-crown * 0.5, tall * 0.62, crown * 0.35), crown * 0.68, key, 0.85, 8, 5)
	solid(o + Vector3(0, 1.0, 0), Vector3(0.3, 2.2, 0.3))
	yard.append(map_at(at.x, at.y))

# ---------------- the car park ----------------
func _park() -> void:
	_lay_in(_rect(45.8, 29.0, 72.0, 72.0), 0.05, "asfalto")
	for side in [[46.3, 51.3], [54.6, 59.6]]:        # its bays, either side of its lane
		var v := 30.0
		while v < 62.0:
			var a := map_at(side[0], v)
			var b := map_at(side[1], v)
			if Geometry2D.is_point_in_polygon(a, PackedVector2Array(FENCE)) and Geometry2D.is_point_in_polygon(b, PackedVector2Array(FENCE)):
				_line(a, b, 0.065, 0.1)
			v += 2.5

# ---------------- the fence ----------------
## a spot along a straight run of the fence (map) where u, or v, is this
func _at_u(p: Vector2, q: Vector2, u: float) -> Vector2:
	var a := to_uv(p)
	var b := to_uv(q)
	return p.lerp(q, (u - a.x) / (b.x - a.x))

func _at_v(p: Vector2, q: Vector2, v: float) -> Vector2:
	var a := to_uv(p)
	var b := to_uv(q)
	return p.lerp(q, (v - a.y) / (b.y - a.y))

## A run of the fence from p to q (on the map): "malla", a low wall with a mesh over it on posts; "huertos", a tall
## white wall with a mesh over it; "tapia", a white wall with its coping (`odd`: a little higher, where two meet)
func _fence_run(p: Vector2, q: Vector2, kind: String) -> void:
	var a := to_uv(p)
	var b := to_uv(q)
	var ln: float = a.distance_to(b)
	if ln < 0.05:
		return
	var d: Vector2 = (b - a) / ln
	var n := maxi(1, int(ceil(ln / 2.5)))
	_runs += 1
	var wall_h: float = (0.9 if kind == "malla" else (2.3 if kind == "huertos" else 2.4)) + (0.015 if _runs % 2 == 1 else 0.0)
	var mesh_h := 1.6 if kind == "malla" else (3.0 if kind == "huertos" else 0.0)
	for i in range(n):
		var fa: Vector2 = a + d * (ln * i / n)
		var fb: Vector2 = a + d * (ln * (i + 1) / n)
		var ya: float = ground(fa.x, fa.y)
		var yb: float = ground(fb.x, fb.y)
		var low := minf(ya, yb) - 0.5
		_slab_wall(fa, fb, 0.22 if kind == "malla" else 0.25, low, ya + wall_h, yb + wall_h, "muro" if kind == "malla" else "blanco")
		_slab_wall(fa, fb, 0.3, ya + wall_h, ya + wall_h + 0.06, yb + wall_h + 0.06, 0xd9d8d2)
		if mesh_h > 0.0:
			var top := wall_h + 0.06
			cbox(Vector3(fa.x, ya + top + mesh_h / 2.0, fa.y), Vector3(0.06, mesh_h, 0.06), MESH)
			for y in [top + 0.1, top + mesh_h / 2.0, top + mesh_h - 0.04]:
				bar(Vector3(fa.x, ya + y, fa.y), Vector3(fb.x, yb + y, fb.y), 0.025, 0.025, MESH)
			var m := int((ln / n) / 0.25)
			for j in range(1, m):
				var t: float = float(j) / m
				var gq: Vector2 = fa.lerp(fb, t)
				cbox(Vector3(gq.x, lerpf(ya, yb, t) + top + mesh_h / 2.0, gq.y), Vector3(0.012, mesh_h - 0.08, 0.012), MESH)
	if mesh_h > 0.0:
		var ye: float = ground(b.x, b.y)
		cbox(Vector3(b.x, ye + wall_h + 0.06 + mesh_h / 2.0, b.y), Vector3(0.06, mesh_h, 0.06), MESH)
	var mid: Vector2 = (a + b) / 2.0
	var tall: float = wall_h + mesh_h
	solid(Vector3(mid.x, ground(mid.x, mid.y) + tall / 2.0, mid.y), Vector3(ln, tall + 1.0, 0.3), atan2(-d.y, d.x))
	yard.append(p)
	yard.append(q)

func _slab_wall(a: Vector2, b: Vector2, thick: float, low: float, t0: float, t1: float, key) -> void:
	pieces += 1
	var d: Vector2 = (b - a).normalized()
	var n := Vector2(-d.y, d.x) * thick / 2.0
	var c := [a - n, b - n, b + n, a + n]
	for s in [[0, 1, -1.0], [3, 2, 1.0]]:
		var u0: Vector2 = c[s[0]]
		var u1: Vector2 = c[s[1]]
		quad(Vector3(u0.x, low, u0.y), Vector3(u1.x, low, u1.y), Vector3(u1.x, t1, u1.y), Vector3(u0.x, t0, u0.y), key, Vector3(n.x, 0, n.y).normalized() * float(s[2]))
	quad(Vector3(c[0].x, t0, c[0].y), Vector3(c[1].x, t1, c[1].y), Vector3(c[2].x, t1, c[2].y), Vector3(c[3].x, t0, c[3].y), key, Vector3.UP)
	quad(Vector3(c[0].x, low, c[0].y), Vector3(c[3].x, low, c[3].y), Vector3(c[3].x, t0, c[3].y), Vector3(c[0].x, t0, c[0].y), key, Vector3(-d.x, 0, -d.y))
	quad(Vector3(c[1].x, low, c[1].y), Vector3(c[2].x, low, c[2].y), Vector3(c[2].x, t1, c[2].y), Vector3(c[1].x, t1, c[1].y), key, Vector3(d.x, 0, d.y))

## a pier of a gate (u, v), as high as the wall it stands in and a little more
func _pier(at: Vector2, tall: float) -> void:
	var y: float = ground(at.x, at.y)
	cbox(Vector3(at.x, y + (tall - 0.5) / 2.0, at.y), Vector3(0.45, tall + 0.5, 0.45), "muro")
	cbox(Vector3(at.x, y + tall + 0.03, at.y), Vector3(0.52, 0.06, 0.52), 0xd9d8d2)
	solid(Vector3(at.x, y + tall / 2.0, at.y), Vector3(0.45, tall, 0.45))
	yard.append(map_at(at.x, at.y))

## A gate between p and q (map): two leaves of mesh in their frames, standing open against the inside of the fence
## or shut across it
func _gate(p: Vector2, q: Vector2, open: bool) -> void:
	var a := to_uv(p)
	var b := to_uv(q)
	_pier(a, 2.6)
	_pier(b, 2.6)
	var w: float = a.distance_to(b) / 2.0 - 0.25
	var d: Vector2 = (b - a).normalized()
	var inn := Vector2(-d.y, d.x)
	if inn.dot(Vector2(28.0, 25.0) - a) < 0.0:
		inn = -inn
	for k in range(2):
		var hinge: Vector2 = a + d * 0.25 if k == 0 else b - d * 0.25
		var along: Vector2 = d if k == 0 else -d
		var leaf: Vector2 = along
		if open:
			leaf = (along * 0.17 + inn).normalized()
		var g: float = ground(hinge.x, hinge.y)
		var tip: Vector2 = hinge + leaf * w
		var gt: float = ground(tip.x, tip.y)
		var y0: float = maxf(g, gt) + 0.06
		for y in [0.0, 1.0, 2.0]:
			bar(Vector3(hinge.x, y0 + y, hinge.y), Vector3(tip.x, y0 + y, tip.y), 0.05, 0.05, MESH)
		for j in range(int(w / 0.15) + 1):
			var c: Vector2 = hinge.lerp(tip, j / float(int(w / 0.15)))
			cbox(Vector3(c.x, y0 + 1.0, c.y), Vector3(0.02, 2.0, 0.02), MESH)
		var mid: Vector2 = (hinge + tip) / 2.0
		solid(Vector3(mid.x, y0 + 1.0, mid.y), Vector3(w, 2.0, 0.12), atan2(-leaf.y, leaf.x))

func _fences() -> void:
	var F := FENCE
	# the lane (from the south-east corner northwards), with the car park's gate
	_fence_run(F[0], F[1], "malla")
	_fence_run(F[1], F[2], "malla")
	var c0 := _at_v(F[2], F[3], 43.0)
	var c1 := _at_v(F[2], F[3], 37.0)
	_fence_run(F[2], c0, "malla")
	_gate(c0, c1, false)
	_fence_run(c1, F[3], "malla")
	# the Calle del Socorro, westwards, with its two gates
	var g0 := _at_u(F[3], F[4], 63.0)
	var g1 := _at_u(F[3], F[4], 58.0)
	_fence_run(F[3], g0, "malla")
	_gate(g0, g1, true)
	_fence_run(g1, F[4], "malla")
	var g2 := _at_u(F[4], F[5], 8.0)
	var g3 := _at_u(F[4], F[5], 3.0)
	_fence_run(F[4], g2, "malla")
	_gate(g2, g3, true)
	_fence_run(g3, F[5], "malla")
	_fence_run(F[5], F[6], "malla")
	# the Calle de los Huertos: the tall white wall with its mesh, along the playground
	_fence_run(F[6], F[7], "huertos")
	# the backs of the houses of the Calle del Santo: a white wall a little in from them (where they jut out, along
	# the nearest of them)
	var back: Array = [F[7], F[8], F[11], F[12], F[16], F[17], F[21]]
	var line: Array = []
	for i in range(back.size()):
		var p: Vector2 = back[i]
		var o: Vector2 = to_uv(p)
		line.append(o + Vector2(0.0, -0.3) if i > 0 and i < back.size() - 1 else o)
	line[0] = to_uv(F[7]) + to_uv(F[7]).direction_to(to_uv(F[6])) * 0.3
	line[line.size() - 1] = to_uv(F[21]) + Vector2(-0.3, 0.0)
	for i in range(line.size() - 1):
		var a: Vector2 = line[i]
		var b: Vector2 = line[i + 1]
		var d: Vector2 = (b - a).normalized()
		_fence_run(map_at((a - d * 0.12).x, (a - d * 0.12).y), map_at((b + d * 0.12).x, (b + d * 0.12).y), "tapia")
	# the end of the Calle del Santo: low wall and mesh again, with the little ones' gate
	var s0 := _at_u(F[22], F[0], 41.0)
	var s1 := _at_u(F[22], F[0], 45.0)
	_fence_run(F[21], F[22], "malla")
	_fence_run(F[22], s0, "malla")
	_gate(s0, s1, true)
	_fence_run(s1, F[0], "malla")

# ---------------- outside the fence ----------------
## Between the fence and the streets: a pavement of slabs to the roadway's edge, with its kerb (the map has none here)
func _street_side() -> void:
	var F := FENCE
	var runs: Array = [[F[2], F[3]], [F[3], F[4]], [F[4], F[5]], [F[6], F[7]], [F[21], F[22]], [F[22], F[0]], [F[0], F[1]], [F[1], F[2]]]
	var inside := PackedVector2Array(FENCE)
	for k in range(runs.size()):
		var p: Vector2 = runs[k][0]
		var q: Vector2 = runs[k][1]
		var n := maxi(1, int(ceil(p.distance_to(q) / 2.0)))
		var pts: Array = []
		for i in range(n + 1):
			var at: Vector2 = p.lerp(q, float(i) / n)
			var r: Dictionary = MapData.nearest_road(at)
			if r.is_empty():
				pts.append(null)
				continue
			var on: Vector2 = r["p"]
			var away: Vector2 = (at - on).normalized()
			var edge: Vector2 = on + away * float(r["seg"].hw)
			var gap: float = (at - edge).dot(away)
			if gap < 0.6 or gap > 4.5 or Geometry2D.is_point_in_polygon(edge, inside):
				pts.append(null)
				continue
			pts.append([at + away * 0.17, edge])
		var lift := 0.06 if k % 2 == 0 else 0.075
		for i in range(pts.size() - 1):
			if pts[i] == null or pts[i + 1] == null:
				continue
			var a0: Vector2 = pts[i][0]
			var a1: Vector2 = pts[i][1]
			var b0: Vector2 = pts[i + 1][0]
			var b1: Vector2 = pts[i + 1][1]
			if a1.distance_to(b1) > 3.5 or Geometry2D.segment_intersects_segment(a0, a1, b0, b1) != null:
				continue
			_lay_map(PackedVector2Array([a0, b0, b1, a1]), lift, "acera")
			var ea := to_uv(a1)
			var eb := to_uv(b1)
			bar(Vector3(ea.x, ground(ea.x, ea.y) + 0.06, ea.y), Vector3(eb.x, ground(eb.x, eb.y) + 0.06, eb.y), 0.15, 0.13, 0xa9a7a2)

# ---------------- the old cemetery's bones ----------------
## The easter egg (the user: "Está construido sobre las ruinas del antiguo cementerio. Así que si quieres poner algunos
## huesos o calaveras en algún sitio como easter egg estaría guay"): a skull half buried in the sandbox, looking up, with
## a bone beside it; a long bone dug up in a vegetable bed; a skull and two crossed bones in the light well.
## The hidden saffron (the user, 27 Nov 2026, to "¿Pongo el azafrán escondido dentro del cubo rojo del arenero?": «Si,
## pon uno»): standing up out of the little ones' red bucket in the sandbox, by the skull. The flower is the game's to
## take (game.flowers, "hidden": it counts once per game).
func _saffron() -> void:
	var s := SANDBOX
	var bk := Vector2(s.end.x - 0.7, s.position.y + 0.8)                # (where _yards left the bucket)
	var flower := Node3D.new()
	flower.add_child(Parts.part("cyl", 0x5f9c4a, Vector3(0, 0.16, 0), Vector3(0.02, 0.32, 0.02)))
	for k in range(5):
		flower.add_child(Parts.part("ball", 0x9b5de5, Vector3(cos(k * 1.257) * 0.07, 0.35, sin(k * 1.257) * 0.07), Vector3(0.065, 0.12, 0.065)))
	flower.add_child(Parts.part("ball", 0xe63946, Vector3(0, 0.4, 0), Vector3(0.03, 0.08, 0.03)))
	flower.position = Vector3(bk.x, ground(bk.x, bk.y) + 0.08, bk.y)
	add_child(flower)
	saffron_spot = map_at(bk.x, bk.y)
	var game = W.get_parent()                           # (the game: the world is its child)
	if game != null and game.get("flowers") != null:
		(game.flowers as Array).append({"node": flower, "p": saffron_spot, "id": "colegiopub", "hidden": true})      # (hidden: Sistemas keeps count of these)

func _bones() -> void:
	var ps = load(BONES)
	if not (ps is PackedScene):
		return
	var kit: Node = (ps as PackedScene).instantiate()
	var skull: Node3D = kit.get_node_or_null("calavera")
	var bone: Node3D = kit.get_node_or_null("hueso")
	if skull != null and bone != null:
		var s := SANDBOX
		_put(skull, Vector2(s.position.x + 1.2, s.position.y + 1.6), 0.068 - 0.04, Basis(Vector3.UP, 2.4) * Basis(Vector3.RIGHT, -0.35))
		_put(bone, Vector2(s.position.x + 1.9, s.position.y + 2.2), 0.068 - 0.03, Basis(Vector3.UP, 0.7) * Basis(Vector3.FORWARD, 0.06))
		var bed_y := -1e9
		for q: Vector2 in _rect(3.0, -12.5, 13.0, -10.0):
			bed_y = maxf(bed_y, ground(q.x, q.y))
		_put(bone, Vector2(11.6, -11.0), bed_y + 0.435 - ground(11.6, -11.0) - 0.012, Basis(Vector3.UP, -0.4) * Basis(Vector3.FORWARD, -0.05), true)
		_put(skull, Vector2(31.0, 12.6), 0.05 - 0.01, Basis(Vector3.UP, -PI / 2.0))
		_put(bone, Vector2(30.62, 12.6), 0.05 - 0.004, Basis(Vector3.UP, 0.62))
		_put(bone, Vector2(30.62, 12.6), 0.05 + 0.022, Basis(Vector3.UP, -0.62))
		bones.append(map_at(s.position.x + 1.2, s.position.y + 1.6))
		bones.append(map_at(11.6, -11.0))
		bones.append(map_at(31.0, 12.6))
	kit.free()

## a piece of the kit of bones, its foot at `lift` over the ground at (u, v), turned
func _put(src: Node3D, at: Vector2, lift: float, basis: Basis, _dug := false) -> void:
	var n: Node3D = src.duplicate()
	n.transform = Transform3D(basis, Vector3(at.x, ground(at.x, at.y) + lift, at.y))
	add_child(n)
	pieces += 1

# ---------------- what the map should know ----------------
## its buildings, for the little map and for whoever asks the map how much room there is
func _tell_map() -> void:
	for b in blocks:
		var pts: PackedVector2Array = b[0]
		MapData.outlines.append(pts)
		if not MapData._wall_grid.is_empty():
			for i in range(pts.size()):
				var a: Vector2 = pts[i]
				var c: Vector2 = pts[(i + 1) % pts.size()]
				MapData._grid_add(MapData._wall_grid, a.min(c), a.max(c), [a, c])
