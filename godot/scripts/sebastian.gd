extends "res://scripts/obra.gd"
## The hermitage of San Sebastián and the park round it, built by hand (the user, 18 November 2026: "La hermita de san
## Sebastián y el parque que la rodea"; referencias/sebastian/, tools/sebastian/).
##
## Between the Calle del Santo (east and south), its loop (west) and the street north of the park. Catastro's parcel
## 4297712 (three parts) for the hermitage; the orthophoto (PNOA) and OpenStreetMap's paths for the park; Street View from
## the car (November 2024, 2021 and 2009 up the Calle del Santo and round the park) and a round picture taken by the
## porch, for the rest:
##   - the hermitage, white with a salmon foot, its nave higher than its two aisles with little windows up in the nave's
##     walls; its front to the south-south-west, the great door of panelled wood between two lanterns, under a porch on
##     two thick columns of granite with a roof of tiles on bare timber; the bell-gable over the front's ridge;
##   - the lower body at its north-east corner, on the street; the little square chapel on the terrace by the street,
##     its corners on columns of granite, a lattice of tiles in its walls, its wooden door to the south;
##   - the terrace along the street, raised over it on a salmon wall with iron railings, its steps, benches, a cypress;
##   - the paved front, and from the porch westwards the covered walk of granite columns and slats that bends round the
##     north of the round square, ivy grown into pillars at its ends;
##   - the round square: grey paving in a ring of red, the low round fountain in the middle, steps up to the front on
##     its north side and down to the paths on its south side;
##   - the park: lawns and earth paths (the map's own), white poplars, pines, palms, olives, lamps and benches, the
##     stone fountain, the monument and the flag by the corner.
##
## Frame: origin at the front's south-west corner; +x along the front (east-south-east), +z out of it (south-south-
## west); y = 0 the ground before the door. The game's ground falls south and east (it rises 1.5 m along the nave): the
## hermitage's walls go down into it; the front is laid over the ground as it lies; the porch and the round square are
## level, with steps; the terrace by the street rises with the street, 0.8 m over it.

const READY := true                             # (tools/bake_godot.py looks for this: with it, Catastro's parcel is not raised here)
const O := Vector2(-95.63, -462.01)             # (the front's south-west corner, and the front's way, if the map gives none)
const U := Vector2(0.93637, 0.35102)

# the hermitage (Catastro's part 1): its front, its east side by the terrace, the body at the north-east, its north side
const B := Vector2(0.0, 0.0)
const H := Vector2(11.57, 0.0)
const G := Vector2(12.90, -21.66)
const F := Vector2(19.50, -21.34)
const E := Vector2(20.24, -24.20)
const D := Vector2(20.99, -27.16)
const C := Vector2(0.28, -26.46)
const NAVE0 := 2.9                              # the nave between its aisles
const NAVE1 := 9.5
const FE := 0.12                                # the floor at the door
const AISLE := 3.42                             # the aisles' eaves
const CLEAR := 4.6                              # where the nave's walls rise over the aisles' roofs
const EAVES := 6.1                              # the nave's eaves
const RIDGE := 7.75
const PORCH := Rect2(3.86, 0.0, 4.63, 6.33)     # (x, z, wide, deep) Catastro's part 3
# the little chapel on the terrace (Catastro's part 2), its corners: south-east, south-west, north-west, north-east
const CHAPEL: Array = [Vector2(17.42, -9.72), Vector2(13.36, -10.13), Vector2(14.04, -16.17), Vector2(18.12, -15.75)]
# the terrace by the street: its edge over the street, south and north
const T_S := Vector2(16.2, 0.6)
const T_N := Vector2(18.8, -21.3)
# the park: the round square's middle and its paving
const SQ := Vector2(-11.46, 16.17)
const SQ_R := 9.5

var door: Vector2                               # before the hermitage's door, on the map (the self-test)
var plaza: Vector2                              # the round square's middle, on the map
var pl := 0.0                                   # the round square's floor
var openings := 0
var _floor_decks: Array = []
var _lamp_spots: Array = []

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"cal":              # the lime-white walls
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.975, 0.93)), 0.35)
		"zocalo":           # their salmon foot
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.95, 0.68, 0.56)), 0.25)
		"granito":
			m = Tex.mat("granular_concrete", Color(0.8, 0.79, 0.76), false)
		"muro":             # the terrace's wall along the front: a rough render of stone colour
			m = Tex.mat("plaster_stone_wall_02", Color(0.86, 0.8, 0.7))
		"columna":          # the porch's and the walk's columns: pale granite, worn
			m = _glow(Tex.mat("granular_concrete", Color(0.95, 0.93, 0.88), false), 0.2)
		"losa":             # the front's paving: pale tiles with a pattern in relief
			m = W._tmat(0xd9d2c6, "pavement", 1.2)
		"gris":             # the round square's grey paving
			m = W._tmat(0xc6c0b6, "pavement", 1.4)
		"roja":             # its ring of red
			m = W._tmat(0xa65a44, "pavement", 1.0)
		"terraza":          # the terrace's floor
			m = W._tmat(0xc9bba6, "pavement", 1.1)
		"mantillo":         # the beds of bark
			m = W._tmat(0x5e3e28, "earth", 1.0)
		"leaf":
			m = W._tmat(0x5f9a48, "leaf", 1.3)
		"alamo":            # the white poplars' leaves
			m = W._tmat(0x86a85a, "leaf", 1.3)
		"pino":
			m = W._tmat(0x3f6a3c, "leaf", 1.1)
		"olivo":
			m = W._tmat(0x8c9c72, "leaf", 1.2)
		"palma":
			m = W._tmat(0x5c8c3e, "leaf", 1.0)
		"cipres":
			m = W._tmat(0x2f5a36, "leaf", 1.0)
		"hiedra":
			m = W._tmat(0x355e2e, "leaf", 0.8)
		"corteza":          # the white poplars' bark
			m = _glow(Tex.mat("granular_concrete", Color(0.95, 0.94, 0.9), false), 0.2)
		"agua":
			var wm := StandardMaterial3D.new()
			wm.albedo_color = Color(0.34, 0.56, 0.66)
			wm.roughness = 0.12
			wm.emission_enabled = true
			wm.emission = Color(0.25, 0.45, 0.55)
			wm.emission_energy_multiplier = 0.2
			m = wm
		"farol":            # the lanterns' glass, lit a little
			var fm := StandardMaterial3D.new()
			fm.albedo_color = Color(0.98, 0.94, 0.8)
			fm.emission_enabled = true
			fm.emission = Color(1.0, 0.86, 0.55)
			fm.emission_energy_multiplier = 0.6
			m = fm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	var data: Dictionary = MapData.sebastian
	var o := Vector2(data["o"][0], data["o"][1]) if data.has("o") else O
	var u := Vector2(data["u"][0], data["u"][1]) if data.has("u") else U
	var out := Vector2(-u.y, u.x)
	level = MapData.height(o + u * 6.2 + out * 1.0)
	transform = Transform3D(Basis(Vector3(u.x, 0, u.y), Vector3.UP, Vector3(out.x, 0, out.y)), Vector3(o.x, level, o.y))
	W.add_child(self)
	door = spot(6.2, 2.5)
	plaza = spot(SQ.x, SQ.y)
	_plan_square()
	_front()
	_nave()
	_espadana()
	_porch()
	_north_body()
	_terrace()
	_chapel()
	_walk()
	_square()
	_park()
	home()
	_commit()
	_tell_map()
	MapData.decks = _decks + _floor_decks + MapData.decks

## What stands here, for whoever asks the map how much room there is and for the little map.
func _tell_map() -> void:
	for ring in [[B, H, G, F, E, D, C], CHAPEL]:
		var pts := PackedVector2Array()
		for q: Vector2 in ring:
			pts.append(spot(q.x, q.y))
		MapData.outlines.append(pts)
		if not MapData._wall_grid.is_empty():
			for i in range(pts.size()):
				var a: Vector2 = pts[i]
				var b: Vector2 = pts[(i + 1) % pts.size()]
				MapData._grid_add(MapData._wall_grid, a.min(b), a.max(b), [a, b])

# ---------------- helpers ----------------
## a spot of the map in this frame
func _loc(p: Vector2) -> Vector2:
	var t := transform.affine_inverse() * Vector3(p.x, 0.0, p.y)
	return Vector2(t.x, t.z)

## the terrace's floor at z: it rises with the street, 0.8 m over it
func tl(z: float) -> float:
	return 0.53 + 0.0461 * (0.6 - z)

## where the terrace's edge over the street is at z
func edge_x(z: float) -> float:
	return T_S.x + (T_N.x - T_S.x) * (T_S.y - z) / (T_S.y - T_N.y)

## A wall of lime from under the ground up to `top` between a and b (seen from a's left), its salmon foot following
## the ground (or `floor` if given: the foot measured from there), with openings `holes` (Rect2 in the wall's frame).
func _wall(a: Vector2, b: Vector2, top: float, holes: Array = [], floor_y := -99.0, foot := 0.95) -> float:
	var ln := face(a, b)
	masonry(0.0, ln, -2.6, top, holes, [], "cal")
	var parts: int = maxi(1, int(ceil(ln / 2.0)))
	for k in range(parts):
		var t0: float = ln * k / parts
		var t1: float = ln * (k + 1) / parts
		var pm: Vector2 = a.lerp(b, (t0 + t1) / 2.0 / ln)
		var base: float = floor_y if floor_y > -90.0 else ground(pm.x, pm.y)
		var cut0 := t0
		for hr: Rect2 in holes:                          # (the foot is cut at a door)
			if hr.position.y < base + foot and hr.end.x > t0 and hr.position.x < t1:
				if hr.position.x > cut0:
					box(cut0, -2.6, 0.0, hr.position.x - cut0, base + foot + 2.6, 0.012, "zocalo")
				cut0 = maxf(cut0, hr.end.x)
		if t1 > cut0:
			box(cut0, -2.6, 0.0, t1 - cut0, base + foot + 2.6, 0.012, "zocalo")
	return ln

## a window of the nave or the aisles: a dark frame in its hole, a white sill
func _ventana(r: Rect2) -> void:
	window(r, 0x3a2a1e, 0x24303a, 0)
	box(r.position.x - 0.06, r.position.y - 0.05, 0.0, r.size.x + 0.12, 0.05, 0.08, 0xeeeae2)
	openings += 1

## a lattice of white tiles in a square hole (the little chapel's)
func _celosia(r: Rect2) -> void:
	box(r.position.x, r.position.y, -DEEP, r.size.x, r.size.y, 0.04, 0x2a2622)
	var n := 4
	for i in range(n + 1):
		box(r.position.x + r.size.x * i / n - 0.03, r.position.y, -0.12, 0.06, r.size.y, 0.12, 0xf2eee6)
	for j in range(n + 2):
		box(r.position.x, r.position.y + r.size.y * j / (n + 1) - 0.03, -0.12, r.size.x, 0.06, 0.12, 0xf2eee6)
	openings += 1

## a lantern on a wall: an iron arm and its glass
func _farol(x: float, y: float) -> void:
	box(x - 0.02, y + 0.42, 0.0, 0.04, 0.04, 0.34, IRON)
	box(x - 0.11, y, 0.22, 0.22, 0.34, 0.22, "farol")
	box(x - 0.14, y + 0.34, 0.19, 0.28, 0.06, 0.28, IRON)
	box(x - 0.12, y - 0.05, 0.2, 0.24, 0.05, 0.24, IRON)
	cbox(Vector3(x, y + 0.46, 0.31), Vector3(0.08, 0.1, 0.08), IRON)

## a granite column on its block, its foot at y: returns its top
func _columna(at: Vector2, y: float, shaft: float, r := 0.27) -> float:
	cbox(Vector3(at.x, y + 0.025, at.y), Vector3(r * 2.4, 0.85, r * 2.4), "columna")
	var top: float = y + 0.45
	drum(Vector3(at.x, top, at.y), r * 1.3, r * 1.12, 0.14, "columna", 14)
	drum(Vector3(at.x, top + 0.14, at.y), r, r * 0.86, shaft, "columna", 14)
	drum(Vector3(at.x, top + 0.14 + shaft, at.y), r * 0.9, r * 1.22, 0.12, "columna", 14)
	cbox(Vector3(at.x, top + 0.26 + shaft + 0.06, at.y), Vector3(r * 2.7, 0.12, r * 2.7), "columna")
	solid(Vector3(at.x, y + 1.6, at.y), Vector3(r * 2.4, 3.2, r * 2.4))
	yard.append(spot(at.x, at.y))
	return top + 0.38 + shaft

## a level floor people walk on, with what holds it up, and the map told
func _floor(pts: Array, y: float, key) -> void:
	var flatp := PackedVector2Array()
	var low := 99.0
	var all: Array = []
	for q: Vector2 in pts:
		flatp.append(q)
		low = minf(low, ground(q.x, q.y))
		all.append(Vector3(q.x, y, q.y))
	flat(flatp, y, key)
	for q: Vector2 in pts:
		all.append(Vector3(q.x, low - 1.0, q.y))
	_hull(all)
	_floor_decks.append(_poly_deck(flatp, level + y))

## a piece of ground laid over the ground as it lies (each corner at its own height), a hand above it
func _drape(pts: Array, key, lift := 0.05) -> void:
	var c := Vector2.ZERO
	for q: Vector2 in pts:
		c += q / pts.size()
	var cc := Vector3(c.x, ground(c.x, c.y) + lift, c.y)
	for i in range(pts.size()):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		tri(cc, Vector3(a.x, ground(a.x, a.y) + lift, a.y), Vector3(b.x, ground(b.x, b.y) + lift, b.y), key, Vector3.UP)
	pieces += 1

## a flight of steps coming down from `edge` (the middle of its top edge, at height y) towards `down`
func _flight(edge: Vector2, y: float, down: Vector2, wide: float, drop: float, key = "granito") -> void:
	if drop < 0.1:
		return
	down = down.normalized()
	var n: int = maxi(2, int(round(drop / 0.16)))
	var tread := 0.34
	var rise: float = drop / n
	var keep := _xf
	_xf = Transform3D(Basis(Vector3(down.y, 0, -down.x), Vector3.UP, Vector3(down.x, 0, down.y)), Vector3(edge.x, y, edge.y))
	for k in range(1, n):
		box(-wide / 2.0, -drop - 0.5, (k - 1) * tread, wide, drop + 0.5 - k * rise, tread, key)
	_xf = keep
	var run: float = tread * (n - 1)
	var mid: Vector2 = edge + down * run / 2.0
	var up_axis: Vector2 = (spot(0.0, 0.0) - spot(down.x, down.y)).normalized()
	_decks.append({"o": spot(mid.x, mid.y), "ax": up_axis, "half": run / 2.0, "wide": wide / 2.0, "top": level + y, "ramp": run, "low": level + y - drop})

## a bench of iron and wooden slats, facing `faces` (a way on the floor plan)
func _bench(at: Vector2, y: float, faces: Vector2) -> void:
	var along := Vector2(-faces.y, faces.x).normalized()
	var keep := _xf
	_xf = Transform3D(Basis(Vector3(along.x, 0, along.y), Vector3.UP, Vector3(faces.normalized().x, 0, faces.normalized().y)), Vector3(at.x, y, at.y))
	for i in range(4):
		box(-0.85, 0.42, -0.2 + i * 0.11, 1.7, 0.03, 0.09, 0x8a5a34)
	for i in range(3):
		box(-0.85, 0.52 + i * 0.13, -0.27, 1.7, 0.09, 0.03, 0x8a5a34)
	for s in [-0.8, 0.74]:
		box(s, 0.0, -0.27, 0.06, 0.92, 0.05, 0x2a2a2c)
		box(s, 0.0, -0.22, 0.06, 0.42, 0.46, 0x2a2a2c)
	_xf = keep
	solid(Vector3(at.x, y + 0.25, at.y), Vector3(1.8, 0.5, 0.5), atan2(-along.y, along.x))
	yard.append(spot(at.x, at.y))

## a park lamp: a dark post, its lantern on top, lit a little at night (no light of its own)
func _lamp(at: Vector2, y := -99.0) -> void:
	var g: float = ground(at.x, at.y) if y < -90.0 else y
	drum(Vector3(at.x, g, at.y), 0.1, 0.07, 0.5, 0x232527, 8)
	drum(Vector3(at.x, g + 0.5, at.y), 0.06, 0.045, 3.1, 0x232527, 7)
	drum(Vector3(at.x, g + 3.6, at.y), 0.1, 0.17, 0.12, 0x232527, 8)
	drum(Vector3(at.x, g + 3.72, at.y), 0.17, 0.2, 0.42, "farol", 8)
	drum(Vector3(at.x, g + 4.14, at.y), 0.24, 0.05, 0.22, 0x232527, 8)
	solid(Vector3(at.x, g + 1.5, at.y), Vector3(0.2, 3.0, 0.2))
	yard.append(spot(at.x, at.y))
	_lamp_spots.append(at)

# ---------------- the hermitage ----------------
## Its front: the aisles' ends low on either side, the nave's gable between them, the door in the middle under the
## porch, its lanterns, a little window high up under the bell-gable; the foot of salmon paint.
func _front() -> void:
	var dr := Rect2(5.2, FE, 2.0, 3.0)
	var hi := Rect2(5.6, 5.0, 1.2, 0.45)
	var lo_w := Rect2(1.0, 1.7, 0.8, 0.8)
	var lo_e := Rect2(10.15, 1.7, 0.8, 0.8)
	var ln := _wall(B, H, AISLE, [dr, lo_w, lo_e], FE)
	slab(PackedVector2Array([Vector2(0, AISLE), Vector2(NAVE0, CLEAR), Vector2(NAVE0, EAVES), Vector2(6.2, RIDGE), Vector2(NAVE1, EAVES), Vector2(NAVE1, CLEAR), Vector2(ln, AISLE)]), 0.0, 0.0, "cal")
	box(hi.position.x, hi.position.y, 0.0, hi.size.x, hi.size.y, 0.02, 0x24303a)
	for xx in [hi.position.x, hi.end.x - 0.05]:
		box(xx, hi.position.y, 0.0, 0.05, hi.size.y, 0.035, 0x3a2a1e)
	box(hi.position.x - 0.06, hi.position.y - 0.05, 0.0, hi.size.x + 0.12, 0.05, 0.08, 0xeeeae2)
	for r: Rect2 in [lo_w, lo_e]:
		_ventana(r)
	# the door: two leaves of panelled wood, warm brown, in a reveal
	box(dr.position.x, dr.position.y, -0.32, dr.size.x, dr.size.y, 0.06, 0x7a4a28)
	for s in [0, 1]:
		for j in range(5):
			for i in range(2):
				box(dr.position.x + 0.12 + s * 1.0 + i * 0.4, dr.position.y + 0.18 + j * 0.56, -0.26, 0.32, 0.46, 0.035, 0x8a5732)
	box(dr.position.x + 0.99, dr.position.y, -0.27, 0.02, dr.size.y, 0.02, 0x3a2414)
	openings += 1
	_farol(4.6, 2.3)
	_farol(7.8, 2.3)
	box(7.55, 1.45, 0.0, 0.3, 0.22, 0.02, 0xf2efe6)                            # (a little tile with the hermitage's name, too small to read)
	home()
	solid(Vector3(6.0, 3.0, -13.0), Vector3(12.4, 8.0, 26.0))

## The nave and its aisles: the aisles' long walls with their foot and a window or two, the nave's walls over the
## aisles' roofs with their little windows, the north end; the roofs of tiles.
func _nave() -> void:
	# the west aisle's wall (from the north end to the front), the east aisle's (from the front to the north body)
	_wall(C, B, AISLE)                                                      # (no windows low down: Street View c2 and n1)
	home()
	_wall(H, G, AISLE)
	home()
	# the nave's walls over the aisles' roofs: four little windows each
	var zs := [-4.5, -10.0, -15.5, -21.0]
	for side in [[Vector2(NAVE1, 0.0), Vector2(NAVE1, -26.6)], [Vector2(NAVE0, -26.6), Vector2(NAVE0, 0.0)]]:
		var ln := face(side[0], side[1])
		var wins: Array = []
		for z: float in zs:
			var x: float = absf(z) if side[0].y == 0.0 else 26.6 - absf(z)
			wins.append(Rect2(x - 0.45, CLEAR + 0.45, 0.9, 0.55))
		masonry(0.0, ln, CLEAR - 0.6, EAVES, wins, [], "cal")
		for r: Rect2 in wins:
			_ventana(r)
		cornice(-0.1, ln + 0.1, EAVES + 0.05, false, 0xb05a3c, 0.45)
		home()
	# the north end: the aisles' ends and the nave's gable, over the body behind
	var ln2 := face(Vector2(13.1, -26.6), C)
	quad(Vector3(0, -2.6, 0), Vector3(ln2, -2.6, 0), Vector3(ln2, AISLE, 0), Vector3(0, AISLE, 0), "cal", Vector3(0, 0, 1))
	home()
	face(Vector2(NAVE1, -26.6), Vector2(NAVE0, -26.6))
	slab(PackedVector2Array([Vector2(-3.6, AISLE), Vector2(0, CLEAR), Vector2(0, EAVES), Vector2(3.3, RIDGE), Vector2(6.6, EAVES), Vector2(6.6, CLEAR), Vector2(9.2, AISLE)]), 0.0, 0.0, "cal")
	home()
	# the roofs: the nave's two slopes, each aisle's lean-to
	var zf := 0.35
	var zb := -26.95
	roof([Vector3(6.2, RIDGE + 0.05, zf), Vector3(6.2, RIDGE + 0.05, zb), Vector3(NAVE1 + 0.45, EAVES - 0.22, zb), Vector3(NAVE1 + 0.45, EAVES - 0.22, zf)])
	roof([Vector3(6.2, RIDGE + 0.05, zb), Vector3(6.2, RIDGE + 0.05, zf), Vector3(NAVE0 - 0.45, EAVES - 0.22, zf), Vector3(NAVE0 - 0.45, EAVES - 0.22, zb)])
	ridge(Vector3(6.2, RIDGE + 0.05, zf), Vector3(6.2, RIDGE + 0.05, zb))
	roof([Vector3(NAVE0, CLEAR + 0.05, zf), Vector3(NAVE0, CLEAR + 0.05, zb), Vector3(-0.45, AISLE - 0.2, zb + 0.02), Vector3(-0.45, AISLE - 0.2, zf)])
	roof([Vector3(NAVE1, CLEAR + 0.05, zb), Vector3(NAVE1, CLEAR + 0.05, zf), Vector3(H.x + 0.45, AISLE - 0.2, zf), Vector3(13.55, AISLE - 0.2, zb)])
	for x in [NAVE0 - 0.45, NAVE1 + 0.45]:                                   # (the nave's eaves: a row of bricks)
		box(x - 0.08, EAVES - 0.3, zb, 0.16, 0.1, zf - zb, 0xb05a3c)
	yard.append(spot(B.x, B.y))
	yard.append(spot(C.x, C.y))
	yard.append(spot(G.x, G.y))

## The bell-gable over the front's ridge: a tower of lime with its arch, its bell, its little roof and its vane.
func _espadana() -> void:
	var x := 6.2
	var z := -0.25
	var y0 := RIDGE - 0.6
	var y1 := RIDGE + 1.75
	box(x - 0.8, y0, z - 0.4, 0.42, y1 - y0, 0.8, "cal")
	box(x + 0.38, y0, z - 0.4, 0.42, y1 - y0, 0.8, "cal")
	box(x - 0.38, y0, z - 0.4, 0.76, RIDGE + 0.45 - y0, 0.8, "cal")
	box(x - 0.38, RIDGE + 1.35, z - 0.4, 0.76, y1 - RIDGE - 1.35, 0.8, "cal")
	for k in range(7):                                                       # (the arch's head)
		var a0 := PI * k / 7.0
		var a1 := PI * (k + 1) / 7.0
		var c := Vector2(x, RIDGE + 1.1)
		quad(Vector3(c.x + cos(a0) * 0.38, c.y + sin(a0) * 0.25, z + 0.4), Vector3(c.x + cos(a1) * 0.38, c.y + sin(a1) * 0.25, z + 0.4),
			Vector3(c.x + cos(a1) * 0.38, RIDGE + 1.35, z + 0.4), Vector3(c.x + cos(a0) * 0.38, RIDGE + 1.35, z + 0.4), "cal", Vector3(0, 0, 1))
	ball(Vector3(x, RIDGE + 0.85, z), 0.22, 0x6a5a34, 1.2, 8, 5)
	cbox(Vector3(x, RIDGE + 1.07, z), Vector3(0.04, 0.2, 0.04), IRON)
	var t := _hip(x - 0.8, x + 0.8, z - 0.4, z + 0.4, y1, 0.42, 0.18)
	cbox(t + Vector3(0, 0.55, 0), Vector3(0.04, 1.1, 0.04), IRON)          # the cross and the vane
	cbox(t + Vector3(0, 0.8, 0), Vector3(0.36, 0.04, 0.04), IRON)
	cbox(t + Vector3(0.14, 0.98, 0), Vector3(0.36, 0.14, 0.02), IRON)

## The porch before the door: its floor a step up from the front, two thick columns of granite, a frame of timber, a
## roof of tiles coming down on three sides from the wall, its rafters bare underneath; steps down from it.
func _porch() -> void:
	var x0 := PORCH.position.x
	var x1 := PORCH.end.x
	var zf := PORCH.end.y
	var pts: Array = [Vector2(x0, 0.0), Vector2(x1, 0.0), Vector2(x1, zf), Vector2(x0, zf)]
	_floor(pts, FE, "losa")
	box(x0, FE - 0.06, zf - 0.02, x1 - x0, 0.08, 0.12, "granito")
	var gf: float = ground((x0 + x1) / 2.0, zf + 0.5)
	_flight(Vector2((x0 + x1) / 2.0, zf + 0.06), FE, Vector2(0, 1), x1 - x0, FE - gf - 0.05)
	var cols: Array = [Vector2(x0 + 0.45, zf - 0.45), Vector2(x1 - 0.45, zf - 0.45)]
	var top := 0.0
	for c: Vector2 in cols:
		top = _columna(c, FE, 2.25, 0.28)
	box(x0 - 0.1, top, zf - 0.6, x1 - x0 + 0.2, 0.26, 0.3, 0x5a3a24)          # the frame: the beam on the columns, the side beams to the wall
	for xx in [x0 + 0.3, x1 - 0.6]:
		box(xx, top, 0.0, 0.3, 0.24, zf - 0.3, 0x5a3a24)
	var ye := top + 0.24
	var yr := ye + 1.3
	var a := Vector3(x0 - 0.35, ye, zf + 0.35)
	var b := Vector3(x1 + 0.35, ye, zf + 0.35)
	var r0 := Vector3((x0 + x1) / 2.0, yr, 0.0)
	var r1 := Vector3((x0 + x1) / 2.0, yr, zf - 2.2)
	roof([a, b, r1])
	roof([Vector3(x1 + 0.35, ye, 0.0), r0, r1, b])
	roof([Vector3(x0 - 0.35, ye, 0.0), a, r1, r0])
	for q in [[a, r1], [b, r1], [r0, r1]]:
		ridge(q[0], q[1])
	var uh := 0x6a4a30                                                      # (its underside: boards on rafters)
	tri(a - Vector3(0, 0.05, 0), b - Vector3(0, 0.05, 0), r1 - Vector3(0, 0.07, 0), uh, Vector3.DOWN)
	quad(Vector3(x1 + 0.35, ye - 0.05, 0.0), r0 - Vector3(0, 0.07, 0), r1 - Vector3(0, 0.07, 0), b - Vector3(0, 0.05, 0), uh, Vector3.DOWN)
	quad(Vector3(x0 - 0.35, ye - 0.05, 0.0), a - Vector3(0, 0.05, 0), r1 - Vector3(0, 0.07, 0), r0 - Vector3(0, 0.07, 0), uh, Vector3.DOWN)
	for k in range(9):                                                      # rafters, fanning from the ridge
		var t := float(k) / 8.0
		var foot := Vector3(lerpf(x0 - 0.3, x1 + 0.3, t), ye - 0.1, zf + 0.3)
		bar(r1 - Vector3(0, 0.14, 0), foot, 0.07, 0.09, 0x4a3020)
	for k in range(6):
		var t := float(k + 1) / 7.0
		for s in [-1.0, 1.0]:
			var fx: float = (x0 - 0.3) if s < 0.0 else (x1 + 0.3)
			bar(Vector3((x0 + x1) / 2.0, yr - 0.14, lerpf(0.0, zf - 2.2, t)), Vector3(fx, ye - 0.1, lerpf(0.0, zf, t)), 0.07, 0.09, 0x4a3020)
	# an iron bench of scrolls against the front, west of the door
	_bench(Vector2(x0 + 0.95, 0.55), FE, Vector2(0, 1))
	yard.append(spot(x0, zf))
	yard.append(spot(x1, zf))

## The lower body at the north-east corner, by the street: lime walls with their foot, a door to the terrace, a window
## to the street; a roof of tiles on four sides.
func _north_body() -> void:
	var fl: float = tl(-21.3)
	var top: float = fl + 3.0
	var dr := Rect2(2.4, fl, 1.1, 2.3)
	_wall(G, F, top, [dr], fl)
	box(dr.position.x, dr.position.y, -0.32, dr.size.x, dr.size.y, 0.06, 0x6a3e22)
	openings += 1
	home()
	var wr := Rect2(1.2, ground(19.9, -23.0) + 1.3, 1.0, 1.1)
	_wall(F, E, top, [])
	home()
	_wall(E, D, top, [wr])
	_ventana(wr)
	grille(wr, 0.12, IRON)
	home()
	_wall(D, Vector2(13.1, -26.9), top)
	home()
	_tent([G, F, E, D, Vector2(13.1, -26.9)], Vector2(15.0, -24.3), Vector2(18.0, -24.4), top + 0.05, top + 1.2, 0.4)
	solid(Vector3(16.8, top - 2.0, -24.3), Vector3(7.6, 6.0, 5.4))
	yard.append(spot(F.x, F.y))
	yard.append(spot(D.x, D.y))

## A roof of tiles over any outline: every eave runs up to the nearer end of the ridge (r0 -- r1).
func _tent(ring: Array, r0: Vector2, r1: Vector2, ye: float, yr: float, out := 0.45) -> void:
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

# ---------------- the terrace by the street ----------------
## Raised over the street on a salmon wall with a coping and iron railings; its floor rises with the street; three
## steps up to it from the front; benches, a cypress, two pots; and, on the pavement below it, a bed of roses.
func _terrace() -> void:
	var zs := T_S.y
	var zn := T_N.y
	# its floor, in strips (it slopes): from the hermitage's wall to the edge
	var steps := 6
	for k in range(steps):
		var za: float = lerpf(zs, -21.3, float(k) / steps)
		var zb: float = lerpf(zs, -21.3, float(k + 1) / steps)
		var wa: float = lerpf(H.x, G.x, clampf(-za / 21.66, 0.0, 1.0))
		var wb: float = lerpf(H.x, G.x, clampf(-zb / 21.66, 0.0, 1.0))
		quad(Vector3(wa, tl(za), za), Vector3(edge_x(za), tl(za), za), Vector3(edge_x(zb), tl(zb), zb), Vector3(wb, tl(zb), zb), "terraza", Vector3.UP)
		var lo: float = minf(ground(wa, za), ground(edge_x(zb), zb)) - 1.0
		_hull([Vector3(wa, tl(za), za), Vector3(edge_x(za), tl(za), za), Vector3(edge_x(zb), tl(zb), zb), Vector3(wb, tl(zb), zb),
			Vector3(wa, lo, za), Vector3(edge_x(za), lo, za), Vector3(edge_x(zb), lo, zb), Vector3(wb, lo, zb)])
		var deck := _poly_deck(PackedVector2Array([Vector2(wa, za), Vector2(edge_x(za), za), Vector2(edge_x(zb), zb), Vector2(wb, zb)]), level + tl((za + zb) / 2.0))
		var mid := Vector2((wa + edge_x(za)) / 2.0, (za + zb) / 2.0)
		deck["o"] = spot(mid.x, mid.y)
		deck["top"] = level + tl(mid.y)
		deck["grad"] = (spot(0.0, -1.0) - spot(0.0, 0.0)) * 0.0461
		_floor_decks.append(deck)
	# its wall over the street, salmon, with its coping and its railing; broken where the chapel stands on it
	var pieces_at: Array = [[zs, CHAPEL[0].y + 0.05], [CHAPEL[3].y - 0.05, zn]]
	for q in pieces_at:
		var a := Vector2(edge_x(q[0]), q[0])
		var b := Vector2(edge_x(q[1]), q[1])
		var ln := face(a, b)
		var g0: float = minf(ground(a.x + 0.6, a.y), ground(b.x + 0.6, b.y)) - 1.0
		var t0: float = tl(q[0]) + 0.35
		var t1: float = tl(q[1]) + 0.35
		var skin: String = "muro" if q[0] > 0.0 else "zocalo"                 # (along the front, rendered stone; by the chapel and on, salmon: c2, c3)
		quad(Vector3(0, g0, 0), Vector3(ln, g0, 0), Vector3(ln, t1, 0), Vector3(0, t0, 0), skin, Vector3(0, 0, 1))
		quad(Vector3(ln, g0, -0.4), Vector3(0, g0, -0.4), Vector3(0, t0, -0.4), Vector3(ln, t1, -0.4), skin, Vector3(0, 0, -1))
		quad(Vector3(0, t0, -0.42), Vector3(ln, t1, -0.42), Vector3(ln, t1, 0.03), Vector3(0, t0, 0.03), "granito", Vector3.UP)
		var n := maxi(2, int(round(ln / 0.14)))
		for i in range(n + 1):
			var t := float(i) / n
			box(ln * t - 0.01, lerpf(t0, t1, t), -0.21, 0.02, 1.0, 0.02, IRON)
		bar(Vector3(0, t0 + 1.0, -0.2), Vector3(ln, t1 + 1.0, -0.2), 0.04, 0.04, IRON)
		bar(Vector3(0, t0 + 0.1, -0.2), Vector3(ln, t1 + 0.1, -0.2), 0.03, 0.03, IRON)
		for i in range(int(ln / 2.2) + 1):                                    # (its little scrolls along the foot of the railing)
			var t := clampf((i + 0.5) * 2.2 / ln, 0.0, 1.0)
			ball(Vector3(ln * t, lerpf(t0, t1, t) + 0.25, -0.2), 0.09, IRON, 1.0, 6, 3)
		home()
		var d := (b - a).normalized()
		var mid := (a + b) / 2.0 + Vector2(d.y, -d.x) * 0.2
		solid(Vector3(mid.x, (g0 + t0 + 1.0) / 2.0, mid.y), Vector3(ln, t0 + 1.0 - g0 + 0.5, 0.4), atan2(-d.y, d.x))
		yard.append(spot(a.x, a.y))
		yard.append(spot(b.x, b.y))
		# a bed of roses along its foot, on the pavement's side
		face(a, b)
		for i in range(int(ln / 1.6)):
			var x := 0.8 + i * 1.6
			var p: Vector2 = a.lerp(b, x / ln)
			var gy: float = ground(p.x + 0.4, p.y)
			ball(Vector3(x, gy + 0.32, 0.32), 0.3, "leaf", 0.9, 7, 4)
			ball(Vector3(x + 0.12, gy + 0.55, 0.36), 0.07, 0xd84a5a, 1.0, 5, 3)
		box(0.0, ground(a.x + 0.3, a.y) - 0.3, 0.0, ln, 0.38, 0.6, 0x9a9488)
		home()
	# its south side to the front: a railing on a low wall, and three steps up at its east end
	var sw := Vector2(H.x, zs)
	var se := Vector2(edge_x(zs) - 1.9, zs)
	var ln2 := face(sw, se)
	box(0.0, ground(se.x, se.y + 0.5) - 0.5, -0.35, ln2, tl(zs) + 0.35 - ground(se.x, se.y + 0.5) + 0.5, 0.35, "zocalo")
	box(0.0, tl(zs) + 0.35, -0.37, ln2, 0.06, 0.39, "granito")
	var n2 := maxi(2, int(round(ln2 / 0.14)))
	for i in range(n2 + 1):
		box(ln2 * i / n2 - 0.01, tl(zs) + 0.4, -0.19, 0.02, 0.95, 0.02, IRON)
	box(0.0, tl(zs) + 1.33, -0.2, ln2, 0.04, 0.04, IRON)
	home()
	solid(Vector3((se.x + sw.x) / 2.0, tl(zs) + 0.4, zs - 0.18), Vector3(ln2, 1.6, 0.36))
	var st := Vector2(edge_x(zs) - 0.95, zs + 0.05)
	_flight(st, tl(zs), Vector2(0, 1), 1.7, tl(zs) - ground(st.x, st.y + 0.8) - 0.04, 0xeeeae2)
	# benches against the hermitage, a cypress, two pots of geraniums
	_bench(Vector2(12.6, -3.2), tl(-3.2), Vector2(1, 0.06))
	_bench(Vector2(13.0, -18.5), tl(-18.5), Vector2(1, 0.06))
	_cypress(Vector2(16.4, -18.6), 10.5, tl(-18.6))
	for p in [Vector2(15.6, -7.6), Vector2(16.7, -19.9)]:
		drum(Vector3(p.x, tl(p.y), p.y), 0.24, 0.3, 0.45, 0x9a5a3a, 10)
		ball(Vector3(p.x, tl(p.y) + 0.6, p.y), 0.32, "leaf", 0.8, 7, 4)
		ball(Vector3(p.x + 0.1, tl(p.y) + 0.82, p.y), 0.08, 0xd8303a, 1.0, 5, 3)

# ---------------- the little chapel ----------------
## Square, on the terrace by the street: lime walls with their salmon foot (down to the street on its east side),
## columns of granite set in its corners and in the middle of its long sides, a lattice in its walls, the wooden door
## to the south; a roof of tiles on four sides on bare rafters.
func _chapel() -> void:
	var fl: float = tl((CHAPEL[0].y + CHAPEL[2].y) / 2.0)
	var top: float = fl + 3.6
	var walls: Array = [[CHAPEL[1], CHAPEL[0]], [CHAPEL[0], CHAPEL[3]], [CHAPEL[3], CHAPEL[2]], [CHAPEL[2], CHAPEL[1]]]
	for i in range(4):
		var a: Vector2 = walls[i][0]
		var b: Vector2 = walls[i][1]
		var ln: float = a.distance_to(b)
		var holes: Array = []
		if i == 0:                                                           # south: the door, a lattice
			holes = [Rect2(ln / 2.0 - 0.15, fl, 1.5, 2.45), Rect2(0.9, fl + 1.3, 0.55, 0.75)]
		elif i == 1:                                                         # east, over the street: one lattice, in its north half (c3)
			holes = [Rect2(ln - 1.7, fl + 1.5, 0.55, 0.8)]
		elif i == 3:
			holes = [Rect2(ln / 2.0 - 0.3, fl + 1.3, 0.55, 0.75)]
		var foot_from: float = fl if i != 1 else -99.0
		_wall(a, b, top, holes, foot_from, 0.95 if i != 1 else tl(a.y) - ground(a.x + 0.8, a.y) + 0.95)
		for hr: Rect2 in holes:
			if hr.size.y > 2.0:
				box(hr.position.x, hr.position.y, -0.32, hr.size.x, hr.size.y, 0.06, 0x6a3e22)
				for j in range(6):
					box(hr.position.x + 0.1, hr.position.y + 0.2 + j * 0.37, -0.26, hr.size.x - 0.2, 0.025, 0.02, 0x4a2a16)
				openings += 1
			else:
				_celosia(hr)
		for x in ([0.0, ln] if i != 1 else [0.0, ln / 2.0, ln]):              # its columns, set in the wall
			var gy: float = fl if i != 1 else fl
			box(x - 0.2, gy, -0.2, 0.4, 0.45, 0.42, "columna")
			drum(Vector3(x, gy + 0.45, 0.02), 0.17, 0.15, top - gy - 0.75, "columna", 10)
			box(x - 0.2, top - 0.3, -0.2, 0.4, 0.3, 0.42, "columna")
		box(-0.25, top - 0.05, -0.1, ln + 0.5, 0.2, 0.35, 0x5a3a24)            # the beam under the eaves
		home()
	_tent(CHAPEL, (CHAPEL[0] + CHAPEL[1]) / 2.0 * 0.5 + (CHAPEL[2] + CHAPEL[3]) / 2.0 * 0.5, (CHAPEL[0] + CHAPEL[1]) / 2.0 * 0.5 + (CHAPEL[2] + CHAPEL[3]) / 2.0 * 0.5,
		top + 0.15, top + 1.45, 0.55)
	var c := (CHAPEL[0] + CHAPEL[1] + CHAPEL[2] + CHAPEL[3]) / 4.0
	_prism([CHAPEL[0], CHAPEL[1], CHAPEL[2], CHAPEL[3]], fl - 2.0, top)
	_finial(Vector3(c.x, top + 1.45, c.y), 0.5)
	for q: Vector2 in CHAPEL:
		yard.append(spot(q.x, q.y))

# ---------------- the covered walk ----------------
## From the porch westwards along the front, then round the north of the round square: two rows of granite columns
## every three metres, beams along each row and across, slats over the walk; ivy grown into pillars here and there.
func _walk() -> void:
	var inner: Array = []
	var outer: Array = []
	for x in [3.2, 0.2, -2.8, -5.8, -8.8]:                                    # the straight stretch
		inner.append(Vector2(x, 4.1))
		outer.append(Vector2(x, 1.5))
	var r_in: float = SQ.y - 4.1
	var r_out: float = SQ.y - 1.5
	for k in range(6):                                                      # ...and round the square, from its north nearly to its west (it stops short of the west path)
		var a: float = deg_to_rad(-90.0 - 14.0 * k)
		var dir := Vector2(cos(a), sin(a))
		inner.append(SQ + dir * r_in)
		outer.append(SQ + dir * r_out)
	var tops_in: Array = []
	var tops_out: Array = []
	for i in range(inner.size()):
		var pi_: Vector2 = inner[i]
		var po: Vector2 = outer[i]
		var lift := 0.05 if pi_.x > -10.0 else 0.0                        # (along the front: on its paving)
		var yi: float = ground(pi_.x, pi_.y) + lift
		var yo: float = ground(po.x, po.y) + lift
		tops_in.append(_columna(pi_, yi, 2.3, 0.19))
		tops_out.append(_columna(po, yo, 2.3, 0.19))
	for i in range(inner.size()):                                           # beams across, at each pair
		var a := Vector3(inner[i].x, tops_in[i], inner[i].y)
		var b := Vector3(outer[i].x, tops_out[i], outer[i].y)
		var dd := (b - a).normalized()
		bar(a - dd * 0.45, b + dd * 0.45, 0.16, 0.24, 0x6a4a30)
	for row in [[inner, tops_in], [outer, tops_out]]:                       # beams along each row
		var pts: Array = row[0]
		var tops: Array = row[1]
		for i in range(pts.size() - 1):
			bar(Vector3(pts[i].x, tops[i] + 0.24, pts[i].y), Vector3(pts[i + 1].x, tops[i + 1] + 0.24, pts[i + 1].y), 0.14, 0.2, 0x6a4a30)
	for i in range(inner.size() - 1):                                       # the slats across, every 0.4 m
		var a0 := Vector3(inner[i].x, tops_in[i] + 0.44, inner[i].y)
		var a1 := Vector3(inner[i + 1].x, tops_in[i + 1] + 0.44, inner[i + 1].y)
		var b0 := Vector3(outer[i].x, tops_out[i] + 0.44, outer[i].y)
		var b1 := Vector3(outer[i + 1].x, tops_out[i + 1] + 0.44, outer[i + 1].y)
		var n := maxi(2, int(a0.distance_to(a1) / 0.42))
		for k in range(1, n):
			var t := float(k) / n
			var p := a0.lerp(a1, t)
			var q := b0.lerp(b1, t)
			var dd := (q - p).normalized()
			bar(p - dd * 0.35, q + dd * 0.35, 0.06, 0.13, 0x7a5638)
	# ivy grown into pillars: by the porch, at the bend, at the end
	for p in [outer[0], outer[4], inner[8], outer[outer.size() - 1]]:
		var gy: float = ground(p.x, p.y)
		drum(Vector3(p.x, gy, p.y), 0.75, 0.7, 3.6, "hiedra", 10)
		ball(Vector3(p.x, gy + 3.6, p.y), 0.72, "hiedra", 0.6, 10, 5)
		solid(Vector3(p.x, gy + 1.8, p.y), Vector3(1.3, 3.6, 1.3))
		yard.append(spot(p.x, p.y))

# ---------------- the round square ----------------
## The game's ground falls nearly two metres across the square (its relief is exaggerated), so a level floor was buried
## by the grass on its north side (the user, 17 Nov: "Aquí el césped clippea un poco"). Its floor is a plane that falls
## the same way but less (`SQ_K` of the ground's slope), laid so that it stands over the ground everywhere on it; where
## it stands over the ground, its edge of granite, with steps down where the map's paths come in.
const SQ_K := 0.6
var sq_gx := 0.0                                # the floor's slope along x and z of this frame
var sq_gz := 0.0

## the square's floor at a spot of this frame
func sqy(x: float, z: float) -> float:
	return pl + sq_gx * (x - SQ.x) + sq_gz * (z - SQ.y)

## the square's floor at a spot of the map, in the world (the self-test)
func square_y(p: Vector2) -> float:
	var q := _loc(p)
	return level + sqy(q.x, q.y)

func _plan_square() -> void:
	var gx: float = (ground(SQ.x + 6.0, SQ.y) - ground(SQ.x - 6.0, SQ.y)) / 12.0
	var gz: float = (ground(SQ.x, SQ.y + 6.0) - ground(SQ.x, SQ.y - 6.0)) / 12.0
	sq_gx = gx * SQ_K
	sq_gz = gz * SQ_K
	var top := -99.0
	for i in range(-11, 12):
		for j in range(-11, 12):
			var d := Vector2(i, j)
			if d.length() > SQ_R + 0.5:
				continue
			top = maxf(top, ground(SQ.x + d.x, SQ.y + d.y) - (sq_gx * d.x + sq_gz * d.y))
	for k in range(72):
		var d := Vector2(cos(TAU * k / 72.0), sin(TAU * k / 72.0)) * (SQ_R + 0.35)
		top = maxf(top, ground(SQ.x + d.x, SQ.y + d.y) - (sq_gx * d.x + sq_gz * d.y))
	pl = top + 0.1

## Grey paving in a ring of red, the low round fountain in the middle with its pillar; its edge of granite where it stands
## over the ground, steps down where the four paths come in; benches on the red.
func _square() -> void:
	var n := 48
	var c3 := Vector3(SQ.x, sqy(SQ.x, SQ.y), SQ.y)
	for i in range(n):                                                      # the grey disc and the ring of red
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var d0 := Vector2(cos(a0), sin(a0))
		var d1 := Vector2(cos(a1), sin(a1))
		var q0: Vector2 = SQ + d0 * 7.0
		var q1: Vector2 = SQ + d1 * 7.0
		var r0: Vector2 = SQ + d0 * SQ_R
		var r1: Vector2 = SQ + d1 * SQ_R
		var v0 := Vector3(q0.x, sqy(q0.x, q0.y), q0.y)
		var v1 := Vector3(q1.x, sqy(q1.x, q1.y), q1.y)
		var w0 := Vector3(r0.x, sqy(r0.x, r0.y), r0.y)
		var w1 := Vector3(r1.x, sqy(r1.x, r1.y), r1.y)
		tri(c3, v0, v1, "gris", Vector3.UP)
		quad(v0, v1, w1, w0, "roja", Vector3.UP)
	pieces += 2
	var ring := PackedVector2Array()
	var hull: Array = []
	var low := 99.0
	for i in range(n):
		var a := TAU * i / n
		var q: Vector2 = SQ + Vector2(cos(a), sin(a)) * SQ_R
		ring.append(q)
		low = minf(low, ground(q.x, q.y))
	for q in ring:
		hull.append(Vector3(q.x, sqy(q.x, q.y), q.y))
		hull.append(Vector3(q.x, low - 1.0, q.y))
	_hull(hull)
	var deck := _poly_deck(ring, 0.0)                                       # (one sloping floor: its height at the middle, its slope on the map)
	deck["o"] = spot(SQ.x, SQ.y)
	deck["top"] = level + pl
	var bx := Vector2(transform.basis.x.x, transform.basis.x.z)
	var bz := Vector2(transform.basis.z.x, transform.basis.z.z)
	deck["grad"] = bx * sq_gx + bz * sq_gz
	_floor_decks.append(deck)
	# the fountain: a low ring of granite, its water, a pillar with a little bowl (level, on the floor at its middle)
	var fc := Vector3(SQ.x, pl, SQ.y)
	var down := Vector3(0, -0.2, 0)
	for i in range(24):
		var a0 := TAU * i / 24.0
		var a1 := TAU * (i + 1) / 24.0
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var up := Vector3(0, 0.42, 0)
		var nm := (d0 + d1).normalized()
		quad(fc + d0 * 1.9 + down, fc + d1 * 1.9 + down, fc + d1 * 1.9 + up, fc + d0 * 1.9 + up, "granito", nm)
		quad(fc + d0 * 1.55 + down, fc + d1 * 1.55 + down, fc + d1 * 1.55 + up, fc + d0 * 1.55 + up, "granito", -nm)
		quad(fc + d0 * 1.53 + up, fc + d1 * 1.53 + up, fc + d1 * 1.94 + up + Vector3(0, 0.03, 0), fc + d0 * 1.94 + up + Vector3(0, 0.03, 0), "granito", Vector3.UP)
	flat(oval(SQ.x, SQ.y, 1.56, 1.56, 24), pl + 0.3, "agua")
	drum(fc + down, 0.32, 0.26, 1.1, "granito", 12)
	drum(fc + Vector3(0, 0.9, 0), 0.42, 0.5, 0.18, "granito", 12)
	drum(fc + Vector3(0, 1.08, 0), 0.2, 0.06, 0.3, "granito", 10)
	solid(Vector3(SQ.x, pl + 0.4, SQ.y), Vector3(3.8, 0.8, 3.8))
	yard.append(spot(SQ.x, SQ.y))
	# the edge of granite all round, where the floor stands over the ground; the paths' openings (the map's paths come in
	# at these bearings: east, south-east, south-west, west)
	var gaps: Array = [deg_to_rad(5.0), deg_to_rad(56.0), deg_to_rad(141.0), deg_to_rad(187.0)]
	var ms := 72
	for i in range(ms):
		var a0: float = TAU * i / ms
		var a1: float = TAU * (i + 1) / ms
		var am: float = (a0 + a1) / 2.0
		var gap := false
		for ga: float in gaps:
			if absf(angle_difference(am, ga)) < deg_to_rad(9.0):
				gap = true
		var d0 := Vector2(cos(a0), sin(a0))
		var d1 := Vector2(cos(a1), sin(a1))
		var p0: Vector2 = SQ + d0 * SQ_R
		var p1: Vector2 = SQ + d1 * SQ_R
		var f0: float = sqy(p0.x, p0.y)
		var f1: float = sqy(p1.x, p1.y)
		var g: float = minf(ground(p0.x + d0.x * 0.3, p0.y + d0.y * 0.3), ground(p1.x + d1.x * 0.3, p1.y + d1.y * 0.3))
		var nm := Vector3((d0.x + d1.x) / 2.0, 0, (d0.y + d1.y) / 2.0).normalized()
		quad(Vector3(p0.x, g - 0.3, p0.y), Vector3(p1.x, g - 0.3, p1.y), Vector3(p1.x, f1, p1.y), Vector3(p0.x, f0, p0.y), "granito", nm)
		if not gap:
			var o0: Vector2 = p0 + d0 * 0.3
			var o1: Vector2 = p1 + d1 * 0.3
			quad(Vector3(p0.x, f0 + 0.04, p0.y), Vector3(p1.x, f1 + 0.04, p1.y), Vector3(o1.x, f1 + 0.04, o1.y), Vector3(o0.x, f0 + 0.04, o0.y), "granito", Vector3.UP)
			quad(Vector3(o0.x, g - 0.3, o0.y), Vector3(o1.x, g - 0.3, o1.y), Vector3(o1.x, f1 + 0.04, o1.y), Vector3(o0.x, f0 + 0.04, o0.y), "granito", nm)
	pieces += 1
	for ga: float in gaps:
		var dir := Vector2(cos(ga), sin(ga))
		var e: Vector2 = SQ + dir * (SQ_R + 0.02)
		var foot: Vector2 = e + dir * 1.6
		_flight(e, sqy(e.x, e.y), dir, 3.4, sqy(e.x, e.y) - ground(foot.x, foot.y))
	# benches round it, on the red, facing the fountain
	for deg in [30.0, 100.0, 222.0, 262.0, 305.0]:
		var a := deg_to_rad(deg)
		var p: Vector2 = SQ + Vector2(cos(a), sin(a)) * 8.3
		_bench(p, sqy(p.x, p.y), -Vector2(cos(a), sin(a)))

# ---------------- the front and the park ----------------
## The paving of the front, laid over the ground; the beds of bark by the walk's end; the park's trees by kind, its
## lamps and benches, the stone fountain, the monument and the flag by the corner.
func _park() -> void:
	_drape([Vector2(-11.5, 0.0), Vector2(PORCH.position.x, 0.0), Vector2(PORCH.position.x, 6.6), Vector2(-11.5, 6.6)], "losa")
	_drape([Vector2(PORCH.end.x, 0.0), Vector2(H.x, 0.0), Vector2(edge_x(0.6) - 1.9, 0.6), Vector2(edge_x(0.6) + 0.6, 0.6), Vector2(edge_x(0.6) + 0.6, 6.6), Vector2(PORCH.end.x, 6.6)], "losa")
	_drape([Vector2(PORCH.position.x, PORCH.end.y + 0.9), Vector2(PORCH.end.x, PORCH.end.y + 0.9), Vector2(PORCH.end.x, 6.6), Vector2(PORCH.position.x, 6.6)], "losa")
	_drape([Vector2(-11.5, -1.6), Vector2(0.0, -1.6), Vector2(0.0, 0.0), Vector2(-11.5, 0.0)], "losa")
	# the beds of bark at the walk's west end, and the old column standing alone in them
	var bed_c: Vector2 = SQ + Vector2(cos(deg_to_rad(196.0)), sin(deg_to_rad(196.0))) * 15.6
	var bed: Array = []
	for i in range(10):
		var a := TAU * i / 10.0
		bed.append(bed_c + Vector2(cos(a) * 3.2, sin(a) * 2.2))
	_drape(bed, "mantillo", 0.06)
	_columna(bed_c + Vector2(1.4, 0.6), ground(bed_c.x + 1.4, bed_c.y + 0.6), 2.3, 0.19)
	# the park's trees (the orthophoto and Street View): white poplars, pines, palms, olives, elms
	var trees: Array = [
		["alamo", Vector2(-126.0, -451.0), 15.0], ["alamo", Vector2(-128.5, -442.5), 14.0], ["alamo", Vector2(-124.0, -436.0), 15.5],
		["alamo", Vector2(-115.0, -441.0), 13.0], ["alamo", Vector2(-133.5, -456.5), 14.0], ["alamo", Vector2(-119.0, -464.5), 13.5],
		["alamo", Vector2(-103.5, -471.0), 12.5], ["alamo", Vector2(-99.0, -469.5), 12.0], ["alamo", Vector2(-108.0, -472.0), 12.0],
		["pino", Vector2(-128.5, -464.5), 12.0], ["pino", Vector2(-115.5, -470.5), 11.0], ["pino", Vector2(-100.5, -427.5), 12.5],
		["pino", Vector2(-124.6, -447.8), 10.5],
		["olmo", Vector2(-88.0, -450.5), 10.0], ["olmo", Vector2(-117.5, -433.5), 9.5], ["olmo", Vector2(-105.0, -440.0), 9.0],
		["olmo", Vector2(-101.8, -426.0), 9.5], ["olmo", Vector2(-135.0, -450.0), 11.0],
		["palmera", Vector2(-95.5, -440.5), 9.0], ["palmera", Vector2(-98.8, -448.2), 7.5],
		["palmito", Vector2(-124.0, -449.0), 5.5], ["palmito", Vector2(-123.5, -453.5), 4.5],
		["olivo", Vector2(-118.0, -461.0), 4.5], ["olivo", Vector2(-109.5, -465.5), 4.2], ["olivo", Vector2(-131.0, -438.0), 4.0]]
	for t in trees:
		var p: Vector2 = _loc(t[1])
		if _too_near(p):
			continue
		match String(t[0]):
			"alamo":
				_alamo(p, t[2])
			"pino":
				_pino(p, t[2])
			"olmo":
				_olmo(p, t[2])
			"palmera":
				_palmera(p, t[2], true)
			"palmito":
				_palmera(p, t[2], false)
			"olivo":
				_olivo(p, t[2])
	# lamps along the paths and round the square; benches along the paths
	for w in [Vector2(-121.0, -452.5), Vector2(-111.5, -440.5), Vector2(-120.5, -440.0), Vector2(-126.2, -461.1),
			Vector2(-97.0, -446.5), Vector2(-104.0, -433.0), Vector2(-113.5, -460.5), Vector2(-90.5, -455.0)]:
		var p: Vector2 = _loc(w)
		if not _too_near(p):
			_lamp(p)
	for w in [[Vector2(-125.0, -447.5), Vector2(0.55, -0.83)], [Vector2(-128.0, -455.0), Vector2(0.9, 0.4)], [Vector2(-110.5, -436.0), Vector2(-0.95, 0.2)],
			[Vector2(-103.0, -435.0), Vector2(-0.9, -0.3)], [Vector2(-94.0, -448.5), Vector2(-0.6, -0.8)]]:
		var p: Vector2 = _loc(w[0])
		var dir: Vector2 = _loc(w[0] + w[1]) - p
		if not _too_near(p):
			_bench(p, ground(p.x, p.y), dir)
	# the stone fountain by the south-west path: a block with a round medallion, its spout and its little basin
	var sf: Vector2 = _loc(Vector2(-123.0, -435.5))
	var gy: float = ground(sf.x, sf.y)
	cbox(Vector3(sf.x, gy + 0.55, sf.y), Vector3(0.5, 1.1, 0.42), "columna")
	ball(Vector3(sf.x, gy + 1.1, sf.y), 0.25, "columna", 0.6, 10, 4)
	cbox(Vector3(sf.x, gy + 0.1, sf.y + 0.4), Vector3(0.6, 0.2, 0.4), "columna")
	solid(Vector3(sf.x, gy + 0.6, sf.y), Vector3(0.6, 1.2, 0.6))
	yard.append(spot(sf.x, sf.y))
	# the monument by the corner: a block of granite on its plinth, a dark plaque
	var mo: Vector2 = _loc(Vector2(-96.5, -433.5))
	var gm: float = ground(mo.x, mo.y)
	cbox(Vector3(mo.x, gm + 0.2, mo.y), Vector3(1.6, 0.4, 1.0), "granito")
	cbox(Vector3(mo.x, gm + 1.05, mo.y), Vector3(1.1, 1.3, 0.55), "columna")
	var toward: Vector2 = (_loc(Vector2(-90.0, -428.0)) - mo).normalized()
	cbox(Vector3(mo.x + toward.x * 0.29, gm + 1.1, mo.y + toward.y * 0.29), Vector3(0.7 * absf(toward.y) + 0.04, 0.6, 0.7 * absf(toward.x) + 0.04), 0x3a3428)
	solid(Vector3(mo.x, gm + 0.8, mo.y), Vector3(1.6, 1.6, 1.0))
	yard.append(spot(mo.x, mo.y))
	# the flag by the corner, on its white mast
	var fp: Vector2 = _loc(Vector2(-92.5, -445.0))
	var gf: float = ground(fp.x, fp.y)
	drum(Vector3(fp.x, gf, fp.y), 0.08, 0.05, 8.5, 0xeeeeea, 8)
	ball(Vector3(fp.x, gf + 8.55, fp.y), 0.08, 0xd8b84a, 1.0, 6, 4)
	var fl := Vector3(fp.x, gf + 6.9, fp.y)
	for k in range(3):
		var col: int = 0xc8222a if k != 1 else 0xf2c419
		var h0 := 1.5 * (0.0 if k == 0 else (0.25 if k == 1 else 0.75))
		var h1 := 1.5 * (0.25 if k == 0 else (0.75 if k == 1 else 1.0))
		quad(fl + Vector3(0.06, 1.5 - h1, 0), fl + Vector3(2.3, 1.5 - h1 - 0.05, 0.25), fl + Vector3(2.3, 1.5 - h0 - 0.05, 0.25), fl + Vector3(0.06, 1.5 - h0, 0), col, Vector3(0, 0, 1))
		quad(fl + Vector3(2.3, 1.5 - h1 - 0.05, 0.25), fl + Vector3(0.06, 1.5 - h1, 0), fl + Vector3(0.06, 1.5 - h0, 0), fl + Vector3(2.3, 1.5 - h0 - 0.05, 0.25), col, Vector3(0, 0, -1))
	solid(Vector3(fp.x, gf + 2.0, fp.y), Vector3(0.2, 4.0, 0.2))
	yard.append(spot(fp.x, fp.y))

## whether a spot is under the hermitage, the chapel, the porch or the square (a tree or a lamp there is left out)
func _too_near(p: Vector2) -> bool:
	if Geometry2D.is_point_in_polygon(p, PackedVector2Array([B + Vector2(-0.5, 0.5), H + Vector2(0.5, 0.5), Vector2(edge_x(0.6) + 0.5, 0.6), Vector2(edge_x(-21.3) + 0.5, -21.3), D + Vector2(0.5, -0.5), C + Vector2(-0.5, -0.5)])):
		return true
	if p.distance_to(SQ) < SQ_R + 1.0:
		return true
	return PORCH.grow(0.6).has_point(p)

# ---------------- trees ----------------
## a white poplar: a tall pale trunk forking, crowns of light green up it
func _alamo(at: Vector2, tall: float) -> void:
	var g: float = ground(at.x, at.y)
	drum(Vector3(at.x, g - 0.3, at.y), 0.32, 0.22, tall * 0.5, "corteza", 9)
	var fork := Vector3(at.x, g + tall * 0.45, at.y)
	bar(fork, fork + Vector3(0.9, tall * 0.25, 0.4), 0.2, 0.2, "corteza")
	bar(fork, fork + Vector3(-0.7, tall * 0.28, -0.5), 0.2, 0.2, "corteza")
	var cr: float = tall * 0.115
	ball(Vector3(at.x + 0.7, g + tall * 0.8, at.y + 0.3), cr, "alamo", 1.5, 9, 6)
	ball(Vector3(at.x - 0.6, g + tall * 0.84, at.y - 0.4), cr * 0.85, "alamo", 1.6, 9, 6)
	ball(Vector3(at.x + 0.1, g + tall * 0.64, at.y), cr * 0.7, "alamo", 1.3, 8, 5)
	solid(Vector3(at.x, g + 1.2, at.y), Vector3(0.6, 2.4, 0.6))
	yard.append(spot(at.x, at.y))

## a pine: a leaning reddish trunk, a broad flat crown of dark green up high
func _pino(at: Vector2, tall: float) -> void:
	var g: float = ground(at.x, at.y)
	var lean := Vector3(0.8, 0.0, -0.5)
	bar(Vector3(at.x, g - 0.3, at.y), Vector3(at.x, g, at.y) + lean + Vector3(0, tall * 0.68, 0), 0.34, 0.34, 0x7a4a34)
	var c := Vector3(at.x, g, at.y) + lean + Vector3(0, tall * 0.74, 0)
	ball(c, tall * 0.26, "pino", 0.45, 11, 5)
	ball(c + Vector3(1.0, -0.6, 0.7), tall * 0.18, "pino", 0.5, 9, 5)
	ball(c + Vector3(-1.1, -0.4, -0.6), tall * 0.17, "pino", 0.5, 9, 5)
	solid(Vector3(at.x, g + 1.2, at.y), Vector3(0.6, 2.4, 0.6))
	yard.append(spot(at.x, at.y))

## an old elm (or a plane): a stout trunk, a broad round crown
func _olmo(at: Vector2, tall: float) -> void:
	var g: float = ground(at.x, at.y)
	var crown: float = tall * 0.32
	drum(Vector3(at.x, g - 0.3, at.y), 0.34, 0.24, tall * 0.5, 0x6b5a45, 8)
	ball(Vector3(at.x, g + tall * 0.72, at.y), crown, "leaf", 0.82, 10, 6)
	ball(Vector3(at.x + crown * 0.6, g + tall * 0.6, at.y - crown * 0.3), crown * 0.72, "leaf", 0.85, 9, 5)
	ball(Vector3(at.x - crown * 0.55, g + tall * 0.62, at.y + crown * 0.3), crown * 0.7, "leaf", 0.85, 9, 5)
	solid(Vector3(at.x, g + 1.2, at.y), Vector3(0.6, 2.4, 0.6))
	yard.append(spot(at.x, at.y))

## a palm: a Canary palm (a thick trunk, a great head of arching fronds) or a fan palm (thin, a small round head)
func _palmera(at: Vector2, tall: float, canary: bool) -> void:
	var g: float = ground(at.x, at.y)
	var r: float = 0.42 if canary else 0.16
	drum(Vector3(at.x, g, at.y), r * 1.15, r, tall, 0x7a6448, 10)
	var top := Vector3(at.x, g + tall, at.y)
	var n := 26 if canary else 11
	var ln: float = 3.6 if canary else 1.4
	for i in range(n):
		var a := TAU * i / n + 0.3
		var up := 0.35 if (i % 2 == 0) else -0.05                            # (two rings: one rising, one hanging)
		var dir := Vector3(cos(a), 0, sin(a))
		var mid := top + dir * ln * 0.5 + Vector3(0, ln * (0.25 + up * 0.5), 0)
		var tip := top + dir * ln + Vector3(0, -ln * (0.35 - up) if canary else ln * 0.1, 0)
		bar(top, mid, 0.55 if canary else 0.4, 0.06, "palma", 0.0)
		bar(mid, tip, 0.42 if canary else 0.3, 0.05, "palma", 0.0)
	ball(top, r * 1.4, 0x6a5a3a, 0.8, 8, 4)
	solid(Vector3(at.x, g + 1.2, at.y), Vector3(r * 2.4, 2.4, r * 2.4))
	yard.append(spot(at.x, at.y))

## an olive: a short twisted trunk, a low round crown of grey-green
func _olivo(at: Vector2, tall: float) -> void:
	var g: float = ground(at.x, at.y)
	bar(Vector3(at.x, g - 0.2, at.y), Vector3(at.x + 0.3, g + tall * 0.35, at.y + 0.2), 0.3, 0.3, 0x5e5040)
	ball(Vector3(at.x + 0.2, g + tall * 0.62, at.y + 0.1), tall * 0.36, "olivo", 0.75, 10, 5)
	ball(Vector3(at.x - 0.5, g + tall * 0.55, at.y - 0.3), tall * 0.24, "olivo", 0.8, 8, 4)
	solid(Vector3(at.x, g + 0.8, at.y), Vector3(0.5, 1.6, 0.5))
	yard.append(spot(at.x, at.y))

## a cypress, standing at y
func _cypress(at: Vector2, tall: float, y: float) -> void:
	drum(Vector3(at.x, y, at.y), 0.16, 0.12, 1.0, 0x5a4636, 7)
	drum(Vector3(at.x, y + 0.8, at.y), 0.85, 0.65, tall * 0.45, "cipres", 9)
	drum(Vector3(at.x, y + 0.8 + tall * 0.45, at.y), 0.65, 0.06, tall * 0.55 - 0.8, "cipres", 9)
	solid(Vector3(at.x, y + 1.2, at.y), Vector3(0.5, 2.4, 0.5))
	yard.append(spot(at.x, at.y))
