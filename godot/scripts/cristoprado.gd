extends "res://scripts/obra.gd"
## The hermitage of the Santísimo Cristo del Prado, on the Paseo del Cristo, built by hand (the user, 21 November 2026:
## "Siguiente proyecto la Ermita del Cristo del Prado (junto a la residencia, en la misma manzana)"; referencias/
## cristoprado/, tools/cristoprado/).
##
## Of 1660, of brick with panels of rubble ("aparejo toledano"), pale and golden. Catastro has it and the old people's
## home beside it as one building (4587301): its nave, the tall square body over the crossing and the lower body at the
## east end are the hermitage; the rest is the home, which stays as the bake raises it. The orthophoto (PNOA), the town's
## own photos of its front (madridejos.es) and Street View from the street (2024, 2021, 2019, 2013 and 2009) for the rest:
##   - the front to the west, on its little square: brick piers at its corners and a panel of rubble between, the
##     doorway of pale stone (two Tuscan columns on pedestals, a round arch, an entablature, a broken pediment with a red
##     tablet in it, a window framed in stone with its own pediment, two little pyramids and a cross), two lanterns;
##   - the bell tower on the front: brick, an arch on each side with its bell, a spire of slate with a ball, a needle,
##     a cross and a vane;
##   - the nave to the east, eleven metres to the eaves, a hipped roof of tiles with a little dormer; its side door to
##     the Paseo, framed in stone, a little window over it;
##   - the square body over the crossing (the dome inside), higher, with a window to the Paseo and a pyramid of tiles;
##   - the body at the east end: a gate under a round arch of stone to the Paseo, a foot of ashlar to the Calle del
##     Cristo with a blind arch, windows behind grilles with crests of iron, its many-sided back to the north;
##   - round it: the pale paving along the south side and the red and white chequers to the kerb, old elms in a row, the
##     stone posts with their urns, the paved square before the front, the railed strip with its cypress by the Calle
##     del Cristo; and in the park to the west, the calvario: three crosses of stone on a block of rubble.
##
## Frame: origin at the nave's south-west corner (the front's south end); +x along the south side, eastwards (east-
## south-east); +z out of the south side, towards the Paseo; y = 0 the ground before the main door. The game's ground
## falls to the east (0.8 m along the hermitage): its walls go down into it, the paving is laid over it as it lies.

const READY := true                             # (tools/bake_godot.py looks for this: with it, the hermitage's parts of Catastro's building are not raised)
const O := Vector2(299.14, 503.37)              # (the nave's south-west corner, and the south side's way, if the map gives none)
const U := Vector2(0.894309, 0.44745)

# the nave (Catastro: a piece of part 4)
const NX := 16.94
const NW := 9.62                                # (z from 0 to -NW)
const N_EAVES := 11.0
const N_RIDGE := 13.2
# the square body over the crossing (part 3): out of the nave's line on both sides
const TX0 := 16.94
const TX1 := 27.98
const TZ0 := 0.77
const TZ1 := -10.37
const T_EAVES := 15.0
const T_TOP := 17.4
# the body at the east end (part 1): its block on the Paseo and its many sides to the north, round from the crossing
const EB: Array = [Vector2(27.98, -1.27), Vector2(36.42, -1.28), Vector2(36.43, -7.78), Vector2(34.20, -7.79), Vector2(32.37, -12.62),
	Vector2(28.33, -16.0), Vector2(24.86, -15.99), Vector2(24.84, -10.37), Vector2(27.99, -10.37)]
const E_EAVES := 8.9
# the bell tower over the front
const BX0 := 0.45
const BZ0 := -6.04
const BS := 2.46
const B_TOP := 15.6
# the main door, the side door (x along the south side)
const DOOR_S := 4.81                            # (along the front, from its north end)
const SIDE_X := 10.0
# the paving: where the pale paving along the south side ends and the chequers begin
const PAVE_Z := 4.8
const KERB_Z := 8.3                             # (the kerb of the Paseo: beyond it the cars park, to the map's asphalt)
const EX := 40.0                                # the east edge of the pale paving, on the Calle del Cristo...
const EXN := Vector2(EX, -5.6)                  # ...to here, then slanting back to EXW along the street, which cuts the corner
const EXW := Vector2(38.0, -7.78)
const PLAT_X := 16.0                            # from here east the pale paving stays level and its little wall rises from the street
const PARK_X := 30.0                            # (the cars park along the Paseo up to here; the chequers go round the corner to the asphalt)
const SQ_X := -15.5                             # the little square's west edge (the street ends there)
# the calvario in the park, on the map, and its long way
const CALV := Vector2(268.1, 495.8)
const CALV_AX := Vector2(0.902, -0.432)

var door: Vector2                               # before the main door, on the map (the self-test)
var side_door: Vector2
var calvario: Vector2
var openings := 0

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"ladrillo":         # the pale golden brick of the hermitage
			m = Tex.mat("brick_wall_003", Color(1.05, 1.22, 1.36))
		"mamposteria":      # the rubble of its panels: grey and brown stones in pale lime
			m = Tex.mat("stone_wall", Color(1.2, 1.14, 1.04))
		"zocalo":           # the rubble of its foot, darker
			m = Tex.mat("stone_wall", Color(0.88, 0.82, 0.74))
		"caliza":           # the doorway's pale stone, a little cream
			m = _glow(Tex.mat("white_plaster_02", Color(1.02, 0.93, 0.8)), 0.12)
		"sillar":           # the ashlar of the east body's foot
			m = Tex.mat("medieval_blocks_03", Color(1.12, 1.02, 0.86))
		"losa":             # the pale paving along the south side and on the square
			m = W._tmat(0xd8d0c2, "pavement", 1.2)
		"gris":             # the square's grey stone
			m = W._tmat(0xa9a59c, "pavement", 1.0)
		"leaf":
			m = W._tmat(0x86a656, "leaf", 1.3)
		"cipres":
			m = W._tmat(0x2f5a36, "leaf", 1.0)
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
	var data: Dictionary = MapData.cristoprado
	var o := Vector2(data["o"][0], data["o"][1]) if data.has("o") else O
	var u := Vector2(data["u"][0], data["u"][1]) if data.has("u") else U
	var out := Vector2(-u.y, u.x)
	level = MapData.height(o - u * 1.0 - out * DOOR_S)
	transform = Transform3D(Basis(Vector3(u.x, 0, u.y), Vector3.UP, Vector3(out.x, 0, out.y)), Vector3(o.x, level, o.y))
	W.add_child(self)
	door = spot(-1.6, -DOOR_S)
	side_door = spot(SIDE_X, 1.6)
	calvario = CALV
	_front()
	_nave()
	_campanario()
	_crucero()
	_cabecera()
	_paving()
	_alrededor()
	_calvario()
	home()
	_commit()
	_prism([Vector2(0, 0), Vector2(NX, 0), Vector2(NX, -NW), Vector2(0, -NW)], -2.0, N_EAVES)
	_prism([Vector2(TX0, TZ0), Vector2(TX1, TZ0), Vector2(TX1, TZ1), Vector2(TX0, TZ1)], -2.0, T_EAVES)
	var ring := PackedVector2Array()
	for q: Vector2 in EB:
		ring.append(q)
	for part in Geometry2D.decompose_polygon_in_convex(ring):
		var pts: Array = []
		for q: Vector2 in part:
			pts.append(q)
		_prism(pts, -2.0, E_EAVES)
	_tell_map()
	MapData.decks = _decks + MapData.decks

## What stands here, for whoever asks the map how much room there is and for the little map.
func _tell_map() -> void:
	var ring: Array = [Vector2(0, 0), Vector2(TX0, 0), Vector2(TX0, TZ0), Vector2(TX1, TZ0)] + EB.slice(0, 8) + [Vector2(TX0, TZ1), Vector2(TX0, -NW), Vector2(0, -NW)]
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

## The panels of rubble of a wall of "aparejo toledano": rows of boxes of rubble with brick between, clear of `holes`.
func _cajones(x0: float, x1: float, y0: float, y1: float, holes: Array, w := 1.3, h := 0.85, gap := 0.28, margin := 0.3) -> Array:
	var res: Array = []
	var y := y0 + gap
	var row := 0
	while y + h <= y1 - gap * 0.5:
		var x := x0 + gap + (0.0 if row % 2 == 0 else (w + gap) * 0.5)
		while x + w <= x1 - gap:
			var r := Rect2(x, y, w, h)
			var clear := true
			for hr: Rect2 in holes:
				if r.intersects(hr.grow(margin)):
					clear = false
					break
			if clear:
				res.append(r)
			x += w + gap
		y += h + gap
		row += 1
	return res

## A wall of the hermitage from a to b (seen from a's left), from under the ground up to `top`: brick with `panels` of
## rubble and `holes`; its foot of dark rubble a metre over the ground as it lies, cut at the doors. Returns its length.
func _muro(a: Vector2, b: Vector2, top: float, holes: Array = [], panels: Array = [], foot := 1.0) -> float:
	var ln := face(a, b)
	masonry(0.0, ln, -2.5, top, holes, panels, "ladrillo", "mamposteria")
	if foot > 0.0:
		var cuts: Array = [0.0]
		for hr: Rect2 in holes:
			if hr.position.y < 0.5:
				cuts.append(hr.position.x)
				cuts.append(hr.end.x)
		cuts.append(ln)
		for k in range(0, cuts.size(), 2):
			var t0: float = cuts[k]
			var t1: float = cuts[k + 1]
			if t1 - t0 < 0.05:
				continue
			var n: int = maxi(1, int(ceil((t1 - t0) / 3.0)))
			for i in range(n):
				var s0: float = lerpf(t0, t1, float(i) / n)
				var s1: float = lerpf(t0, t1, float(i + 1) / n)
				var p0: Vector2 = a.lerp(b, s0 / ln)
				var p1: Vector2 = a.lerp(b, s1 / ln)
				plinth(s0, s1, ground(p0.x, p0.y) + foot, ground(p1.x, p1.y) + foot, "zocalo", 0.05, -2.5)
	return ln

## a lantern on a wall: an iron arm and its glass
func _farol(x: float, y: float) -> void:
	box(x - 0.02, y + 0.42, 0.0, 0.04, 0.04, 0.34, IRON)
	box(x - 0.11, y, 0.22, 0.22, 0.34, 0.22, "farol")
	box(x - 0.14, y + 0.34, 0.19, 0.28, 0.06, 0.28, IRON)
	box(x - 0.12, y - 0.05, 0.2, 0.24, 0.05, 0.24, IRON)
	cbox(Vector3(x, y + 0.46, 0.31), Vector3(0.08, 0.1, 0.08), IRON)

## a crest of wrought iron over a window: a cross on an upright, two scrolls
func _copete(cx: float, y: float, tall := 0.8) -> void:
	box(cx - 0.015, y, 0.04, 0.03, tall, 0.03, IRON)
	box(cx - 0.12, y + tall * 0.72, 0.04, 0.24, 0.03, 0.03, IRON)
	for s in [-1.0, 1.0]:
		var c := Vector3(cx + s * 0.22, y + tall * 0.3, 0.055)
		for k in range(6):
			var a0: float = PI * k / 6.0
			var a1: float = PI * (k + 1) / 6.0
			bar(c + Vector3(cos(a0) * 0.16 * s, sin(a0) * 0.16, 0), c + Vector3(cos(a1) * 0.16 * s, sin(a1) * 0.16, 0), 0.025, 0.025, IRON)
		bar(Vector3(cx, y + 0.02, 0.055), c + Vector3(0.16 * s, 0.0, 0), 0.025, 0.025, IRON)

## a window behind a grille of iron, its crest over it
func _ventana_reja(r: Rect2, crest := true) -> void:
	window(r, 0x3a2a1e, 0x24303a, 1)
	box(r.position.x - 0.08, r.position.y - 0.06, 0.0, r.size.x + 0.16, 0.06, 0.1, 0xb9ad98)
	grille(r, 0.12, IRON)
	if crest:
		_copete(r.position.x + r.size.x / 2.0, r.end.y + 0.08, 0.7)
	openings += 1

## an old door of two leaves of dark wood with its studs, in a rectangle, `z` back in the wall
func _puerta(r: Rect2, z := -0.28) -> void:
	box(r.position.x, r.position.y, z, r.size.x, r.size.y, 0.06, 0x3e2418)
	studs(r.position.x + 0.1, r.end.x - 0.1, r.position.y + 0.2, r.end.y - 0.15, z + 0.06, 7, 9, 0x8a8478)
	box(r.position.x + r.size.x / 2.0 - 0.015, r.position.y, z + 0.06, 0.03, r.size.y, 0.02, 0x22140c)
	openings += 1

## a column of pale stone (Tuscan) on its pedestal, standing out of the wall being built: `at` its foot
func _columna(at: Vector3, top: float) -> void:
	var ped := 1.37
	cbox(at + Vector3(0, ped / 2.0, 0), Vector3(0.9, ped, 0.9), "caliza")
	cbox(at + Vector3(0, ped - 0.05, 0), Vector3(1.0, 0.1, 1.0), "caliza")
	cbox(at + Vector3(0, 0.08, 0), Vector3(1.02, 0.16, 1.02), "caliza")
	drum(at + Vector3(0, ped, 0), 0.32, 0.27, 0.14, "caliza", 14)
	drum(at + Vector3(0, ped + 0.14, 0), 0.24, 0.21, top - ped - 0.42, "caliza", 14)
	drum(at + Vector3(0, top - 0.28, 0), 0.22, 0.3, 0.12, "caliza", 14)
	cbox(at + Vector3(0, top - 0.08, 0), Vector3(0.7, 0.16, 0.7), "caliza")

## a stone post with its urn, as the Paseo has along the pavement
func _pilon(at: Vector2, y := -99.0) -> void:
	var g: float = (ground(at.x, at.y) + 0.06) if y < -90.0 else y
	cbox(Vector3(at.x, g + 0.1, at.y), Vector3(0.46, 0.2, 0.46), "caliza")
	cbox(Vector3(at.x, g + 0.55, at.y), Vector3(0.32, 0.7, 0.32), "caliza")
	cbox(Vector3(at.x, g + 0.94, at.y), Vector3(0.4, 0.08, 0.4), "caliza")
	drum(Vector3(at.x, g + 0.98, at.y), 0.08, 0.15, 0.16, "caliza", 10)
	ball(Vector3(at.x, g + 1.2, at.y), 0.13, "caliza", 0.9, 10, 6)
	drum(Vector3(at.x, g + 1.3, at.y), 0.05, 0.02, 0.12, "caliza", 8)
	solid(Vector3(at.x, g + 0.6, at.y), Vector3(0.45, 1.2, 0.45))
	yard.append(spot(at.x, at.y))

## an old elm of the Paseo: a clear trunk forking into limbs, light crowns up high (`hollow`: the old one, stout and split)
func _olmo(at: Vector2, tall: float, hollow := false) -> void:
	var g: float = ground(at.x, at.y)
	var r0: float = 0.48 if hollow else 0.17
	var fork: float = tall * (0.36 if hollow else 0.42)
	drum(Vector3(at.x, g - 0.3, at.y), r0, r0 * 0.8, fork + 0.3, 0x6b5a45, 9)
	var top := Vector3(at.x, g + fork, at.y)
	var crown: float = tall * (0.2 if hollow else 0.17)
	var limbs: Array = [Vector3(1.0, 0.0, 0.3), Vector3(-0.7, 0.0, 0.8), Vector3(-0.4, 0.0, -0.9)]
	for k in range(limbs.size()):
		var d: Vector3 = limbs[k] * crown * 0.9 + Vector3(0, tall * 0.2, 0)
		bar(top, top + d, r0 * 0.9, r0 * 0.9, 0x6b5a45)
		ball(top + d + Vector3(0, crown * 0.35, 0), crown * (1.0 if k == 0 else 0.85), "leaf", 0.78, 9, 5)
	ball(top + Vector3(0, tall * 0.42, 0), crown * 1.05, "leaf", 0.75, 10, 6)
	box(at.x - 0.6, g + 0.02, at.y - 0.6, 1.2, 0.07, 1.2, 0x8a7a64)          # (its square pit, edged)
	solid(Vector3(at.x, g + 1.2, at.y), Vector3(r0 * 2.2, 2.4, r0 * 2.2))
	yard.append(spot(at.x, at.y))

## a cypress
func _cipres(at: Vector2, tall: float) -> void:
	var g: float = ground(at.x, at.y)
	drum(Vector3(at.x, g, at.y), 0.16, 0.12, 1.0, 0x5a4636, 7)
	drum(Vector3(at.x, g + 0.8, at.y), 0.85, 0.7, tall * 0.45, "cipres", 9)
	drum(Vector3(at.x, g + 0.8 + tall * 0.45, at.y), 0.7, 0.06, tall * 0.55 - 0.8, "cipres", 9)
	solid(Vector3(at.x, g + 1.2, at.y), Vector3(0.5, 2.4, 0.5))
	yard.append(spot(at.x, at.y))

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

# ---------------- the hermitage ----------------
## The front, to the west on its square: brick piers at the corners and a panel of rubble between; the doorway of pale
## stone up the middle; two lanterns; the cornice of brick under the eaves.
func _front() -> void:
	var c := DOOR_S
	var dr := Rect2(c - 1.08, 0.0, 2.16, 3.94)
	var spring := 2.86
	var win := Rect2(c - 0.4, 6.7, 0.8, 1.2)
	var ln := _muro(Vector2(0, -NW), Vector2(0, 0), N_EAVES, [dr, win], [Rect2(1.5, 1.05, NW - 3.0, N_EAVES - 1.95)])
	cornice(-0.05, ln + 0.05, N_EAVES, false, "ladrillo", 1.35)
	# the doorway: the arch's voussoirs on their jambs, the leaves of studded wood
	spandrels(c, spring, 1.08, 0.0, "caliza")
	ring(c, spring, 1.08, 1.38, 0.06, DEEP, "caliza", 11)
	for s in [-1.0, 1.0]:
		box(c + s * 1.23 - 0.15, 0.0, 0.0, 0.3, spring, 0.06, "caliza")
	box(dr.position.x, 0.0, -0.28, dr.size.x, spring, 0.06, 0x3e2418)
	arched(c, spring - 0.01, spring, 1.08, -0.22, 0x3e2418)
	studs(c - 0.95, c + 0.95, 0.25, spring - 0.1, -0.22, 7, 8, 0x8a8478)
	box(c - 0.015, 0.0, -0.22, 0.03, 3.9, 0.02, 0x22140c)
	box(dr.position.x, -0.12, -0.3, dr.size.x, 0.12, 0.5, "caliza")      # (the step of the threshold)
	openings += 1
	# the columns on their pedestals, the entablature on them, the broken pediment with the red tablet between
	for s in [-1.0, 1.0]:
		_columna(Vector3(c + s * 1.75, 0.0, 0.42), 4.45)
	box(c - 2.3, 4.45, 0.0, 4.6, 0.82, 0.85, "caliza")
	box(c - 2.42, 5.12, 0.0, 4.84, 0.15, 0.97, "caliza")
	for s in [-1.0, 1.0]:
		bar(Vector3(c + s * 2.35, 5.36, 0.42), Vector3(c + s * 1.0, 5.98, 0.42), 0.8, 0.18, "caliza")
	box(c - 0.34, 5.42, 0.0, 0.68, 1.15, 0.12, 0x9a4e3e)
	box(c - 0.04, 5.58, 0.12, 0.08, 0.8, 0.03, 0x7a3a2e)
	box(c - 0.2, 6.05, 0.12, 0.4, 0.08, 0.03, 0x7a3a2e)
	# the window over it, framed in stone, its pediment, the two little pyramids and the cross
	window(win, 0x2a2622, 0x2a3a46, 1)
	openings += 1
	for s in [-1.0, 1.0]:
		box(c + s * 0.6 - 0.18, 6.55, 0.0, 0.36, 1.45, 0.12, "caliza")
	box(c - 0.96, 6.46, 0.0, 1.92, 0.12, 0.2, "caliza")
	box(c - 1.0, 7.9, 0.0, 2.0, 0.28, 0.2, "caliza")
	slab(PackedVector2Array([Vector2(c - 0.96, 8.18), Vector2(c + 0.96, 8.18), Vector2(c, 8.75)]), 0.17, 0.17, "caliza")
	for s in [-1.0, 1.0]:
		cbox(Vector3(c + s * 0.86, 8.24, 0.1), Vector3(0.18, 0.12, 0.18), "caliza")
		drum(Vector3(c + s * 0.86, 8.3, 0.1), 0.08, 0.0, 0.4, "caliza", 4)
	box(c - 0.05, 8.7, 0.04, 0.1, 0.85, 0.1, "caliza")
	box(c - 0.27, 9.15, 0.04, 0.54, 0.1, 0.1, "caliza")
	_farol(c - 2.8, 4.75)
	_farol(c + 2.8, 4.75)
	home()
	for s in [-1.0, 1.0]:                                                  # (the pedestals stop you; the front's frame: out of it is -x)
		solid(Vector3(-0.42, 1.5, -NW + c + s * 1.75), Vector3(0.95, 3.0, 0.95))
	yard.append(spot(0.0, 0.0))
	yard.append(spot(0.0, -NW))

## The nave: its south side on the Paseo with the side door framed in stone and a little window over it, its north side
## over the home's roofs; the roof of tiles on four sides, hipped over the front, running into the crossing; the dormer.
func _nave() -> void:
	var gz: float = ground(SIDE_X, 0.3)
	var dr := Rect2(SIDE_X - 1.05, gz, 2.1, 3.3 - gz)
	var hi := Rect2(SIDE_X - 0.4, 7.4, 0.8, 1.05)
	var frame := Rect2(SIDE_X - 1.5, gz, 3.0, 4.6 - gz)
	var ln := _muro(Vector2(0, 0), Vector2(NX, 0), N_EAVES, [dr, hi], _cajones(1.5, NX - 0.2, 1.0, N_EAVES - 0.8, [frame, hi], 1.7, 0.9, 0.22))
	cornice(-0.05, ln, N_EAVES, false, "ladrillo", 1.35)
	for s in [-1.0, 1.0]:                                                  # (the door's frame of stone: its jambs, its lintel and cornice)
		box(SIDE_X + s * 1.2 - 0.15, gz, 0.0, 0.3, 3.3 - gz, 0.08, "caliza")
	box(SIDE_X - 1.35, 3.3, 0.0, 2.7, 0.34, 0.1, "caliza")
	box(SIDE_X - 1.5, 3.64, 0.0, 3.0, 0.2, 0.26, "caliza")
	box(SIDE_X - 1.3, 3.84, 0.0, 2.6, 0.14, 0.16, "caliza")
	_puerta(dr)
	box(dr.position.x, gz - 0.1, -0.3, dr.size.x, 0.12, 0.55, "caliza")
	window(hi, 0x2a2622, 0x2a3a46, 0)
	box(hi.position.x - 0.08, hi.position.y - 0.06, 0.0, hi.size.x + 0.16, 0.06, 0.1, 0xb9ad98)
	openings += 1
	home()
	var ln2 := _muro(Vector2(NX, -NW), Vector2(0, -NW), N_EAVES, [], _cajones(0.6, NX - 0.6, 5.0, N_EAVES - 0.8, [], 1.7, 0.9, 0.22), 0.0)
	cornice(0.0, ln2 + 0.05, N_EAVES, false, "ladrillo", 1.35)
	home()
	# the roof: two long slopes to the ridge, the hip over the front
	var oh := 0.45
	var e := N_EAVES - 0.05
	var m := -NW / 2.0
	var hx: float = NW / 2.0
	roof([Vector3(-oh, e, oh), Vector3(NX, e, oh), Vector3(NX, N_RIDGE, m), Vector3(hx, N_RIDGE, m)])
	roof([Vector3(NX, e, -NW - oh), Vector3(-oh, e, -NW - oh), Vector3(hx, N_RIDGE, m), Vector3(NX, N_RIDGE, m)])
	roof([Vector3(-oh, e, -NW - oh), Vector3(-oh, e, oh), Vector3(hx, N_RIDGE, m)])
	ridge(Vector3(hx, N_RIDGE, m), Vector3(NX, N_RIDGE, m))
	ridge(Vector3(-oh, e, oh), Vector3(hx, N_RIDGE, m))
	ridge(Vector3(-oh, e, -NW - oh), Vector3(hx, N_RIDGE, m))
	# the little dormer on the south slope, over the side door: brick, a dark opening, its own two slopes
	var dz := -1.5
	var dy: float = e + (N_RIDGE - e) * (oh - dz) / (oh - m)
	box(SIDE_X - 0.5, dy - 0.5, dz - 0.6, 1.0, 1.25, 0.6, "ladrillo")
	box(SIDE_X - 0.25, dy + 0.0, dz + 0.0, 0.5, 0.55, 0.02, 0x2a2622)
	roof([Vector3(SIDE_X - 0.65, dy + 0.72, dz + 0.15), Vector3(SIDE_X, dy + 1.05, dz + 0.15), Vector3(SIDE_X, dy + 1.05, dz - 1.2), Vector3(SIDE_X - 0.65, dy + 0.72, dz - 1.2)])
	roof([Vector3(SIDE_X, dy + 1.05, dz + 0.15), Vector3(SIDE_X + 0.65, dy + 0.72, dz + 0.15), Vector3(SIDE_X + 0.65, dy + 0.72, dz - 1.2), Vector3(SIDE_X, dy + 1.05, dz - 1.2)])
	slab(PackedVector2Array([Vector2(SIDE_X - 0.5, dy + 0.75), Vector2(SIDE_X + 0.5, dy + 0.75), Vector2(SIDE_X, dy + 1.02)]), dz + 0.0, 0.0, "ladrillo")
	yard.append(spot(NX, 0.0))

## The bell tower on the front: brick, an arch on each side with the bell inside, the cornice, the spire of slate with
## its ball, its needle, its cross and its vane (the town's photos: twenty metres to the cross).
func _campanario() -> void:
	var x0 := BX0
	var z0 := BZ0
	var x1 := BX0 + BS
	var z1 := BZ0 + BS
	var y0 := 11.0
	var cy := 15.2
	var sides: Array = [[Vector2(x0, z0), Vector2(x0, z1)], [Vector2(x0, z1), Vector2(x1, z1)], [Vector2(x1, z1), Vector2(x1, z0)], [Vector2(x1, z0), Vector2(x0, z0)]]
	for sd in sides:
		face(sd[0], sd[1])
		var hole := Rect2(BS / 2.0 - 0.315, 13.2, 0.63, 1.45)
		masonry(0.0, BS, y0, cy, [hole], [], "ladrillo")
		spandrels(BS / 2.0, 14.335, 0.315, 0.0, "ladrillo")
		# (the inside of the wall round the arch, so the far side is not seen through)
		box(0.0, 13.2, -DEEP - 0.03, BS / 2.0 - 0.315, 1.45, 0.03, "ladrillo")
		box(BS / 2.0 + 0.315, 13.2, -DEEP - 0.03, BS / 2.0 - 0.315, 1.45, 0.03, "ladrillo")
		box(0.0, 12.95, -DEEP - 0.03, BS, 0.25, 0.03, "ladrillo")
		cornice(0.0, BS, B_TOP, false, "ladrillo", 0.9)
		home()
	box(x0 + DEEP, 13.18, z0 + DEEP, BS - 2.0 * DEEP, 0.04, BS - 2.0 * DEEP, 0x6a5a4a)    # (the floor of the bells)
	box(x0 + DEEP, 14.6, z0 + DEEP, BS - 2.0 * DEEP, 0.04, BS - 2.0 * DEEP, 0x4a3e34)
	var bc := Vector3(x0 + BS / 2.0, 13.85, z0 + BS / 2.0)
	drum(bc - Vector3(0, 0.42, 0), 0.36, 0.2, 0.5, 0x6a5a34, 12)
	ball(bc + Vector3(0, 0.1, 0), 0.2, 0x6a5a34, 0.9, 10, 5)
	cbox(bc + Vector3(0, 0.5, 0), Vector3(0.5, 0.08, 0.08), 0x4a3a24)
	# the spire: a pyramid of slate, a ball, the needle, the cross and the vane
	var t := Vector3(x0 + BS / 2.0, 17.05, z0 + BS / 2.0)
	var e := B_TOP
	var corners := [Vector3(x0 - 0.12, e, z0 - 0.12), Vector3(x1 + 0.12, e, z0 - 0.12), Vector3(x1 + 0.12, e, z1 + 0.12), Vector3(x0 - 0.12, e, z1 + 0.12)]
	for i in range(4):
		var a: Vector3 = corners[i]
		var b: Vector3 = corners[(i + 1) % 4]
		tri(a, b, t, 0x5b6268, (b - a).cross(t - a).normalized() * (-1.0 if ((b - a).cross(t - a)).y < 0.0 else 1.0))
	ball(t + Vector3(0, 0.15, 0), 0.2, 0x6f7376, 0.9, 10, 6)
	drum(t + Vector3(0, 0.3, 0), 0.13, 0.025, 1.6, 0x6f7376, 8)
	ball(t + Vector3(0, 1.9, 0), 0.08, 0x9a8a5a, 1.0, 8, 5)
	cbox(t + Vector3(0, 2.45, 0), Vector3(0.04, 1.1, 0.04), IRON)
	cbox(t + Vector3(0, 2.7, 0), Vector3(0.55, 0.04, 0.04), IRON)
	cbox(t + Vector3(0.15, 2.05, 0), Vector3(0.32, 0.22, 0.02), 0xdcdad2)    # (the vane: a white cock)
	# the little chimney of brick by it, to the south
	box(1.4, 11.4, -3.62, 0.5, 1.95, 0.5, 0xa0583a)
	box(1.32, 13.35, -3.7, 0.66, 0.08, 0.66, 0x8a4a30)

## The square body over the crossing: brick piers at its corners, panels of rubble between, a window to the Paseo; the
## cornice; a pyramid of tiles with a rod and a little cross.
func _crucero() -> void:
	var w := TX1 - TX0
	var win := Rect2(4.96 - 0.5, 7.2, 1.0, 2.0)
	var pan_s := _cajones(1.96, 7.96, 1.0, T_EAVES - 0.8, [win], 1.7, 0.9, 0.22)
	var ln := _muro(Vector2(TX0, TZ0), Vector2(TX1, TZ0), T_EAVES, [win], pan_s)
	var gq: float = ground(TX1 - 0.8, TZ0) + 1.0
	box(9.46, gq, 0.0, w - 9.46, T_EAVES - 0.6 - gq, 0.1, "ladrillo")         # (the east pier, a step proud, over the foot)
	window(win, 0x3a2a1e, 0x24303a, 1)
	box(win.position.x - 0.08, win.position.y - 0.06, 0.0, win.size.x + 0.16, 0.06, 0.1, 0xb9ad98)
	openings += 1
	cornice(-0.05, ln + 0.05, T_EAVES, false, "ladrillo", 1.35)
	home()
	var deep := TZ0 - TZ1
	_muro(Vector2(TX0, TZ1), Vector2(TX0, TZ0), T_EAVES, [], _cajones(1.0, deep - 1.0, N_EAVES + 0.4, T_EAVES - 0.8, [], 1.7, 0.9, 0.22), 1.0)
	cornice(-0.05, deep + 0.05, T_EAVES, false, "ladrillo", 1.35)
	home()
	_muro(Vector2(TX1, TZ1), Vector2(TX0, TZ1), T_EAVES, [], _cajones(1.4, w - 1.4, 7.6, T_EAVES - 0.8, [], 1.7, 0.9, 0.22), 0.0)
	cornice(-0.05, w + 0.05, T_EAVES, false, "ladrillo", 1.35)
	home()
	_muro(Vector2(TX1, TZ0), Vector2(TX1, TZ1), T_EAVES, [], _cajones(1.5, deep - 1.5, E_EAVES + 0.6, T_EAVES - 0.8, [], 1.7, 0.9, 0.22), 1.0)
	cornice(-0.05, deep + 0.05, T_EAVES, false, "ladrillo", 1.35)
	home()
	var top := _hip(TX0, TX1, TZ1, TZ0, T_EAVES - 0.05, T_TOP - T_EAVES, 0.5)
	cbox(top + Vector3(0, 0.1, 0), Vector3(0.36, 0.2, 0.36), 0xa8623f)
	cbox(top + Vector3(0, 0.95, 0), Vector3(0.035, 1.7, 0.035), IRON)
	cbox(top + Vector3(0, 1.55, 0), Vector3(0.36, 0.035, 0.035), IRON)
	yard.append(spot(TX0, TZ0))
	yard.append(spot(TX1, TZ0))

## The body at the east end: to the Paseo the gate under its arch of stone, ashlar at its foot to the corner, a little
## window behind a grille; to the Calle del Cristo the ashlar foot with a blind arch, a string course, the great window
## behind its grille with a crest; its many sides to the north with their windows; the cornice; a roof of tiles.
func _cabecera() -> void:
	var e := E_EAVES
	# to the Paseo: rubble and brick at its west end, ashlar round the gate to the corner, brick over the string course
	var p0: Vector2 = EB[0]
	var p1: Vector2 = EB[1]
	var gl: float = _pz(34.0)                                               # (the gate opens on the level paving)
	var gc := 4.68 + 1.385
	var gr := 1.385
	var gs: float = gl + 1.75
	var gate := Rect2(gc - gr, gl, 2.0 * gr, gs + gr - gl)
	var sw := Rect2(5.66, 4.6, 0.75, 1.0)
	var ln := face(p0, p1)
	masonry(0.0, 3.4, -2.5, e, [], _cajones(0.0, 3.4, 1.0, e - 0.8, [], 1.7, 0.9, 0.22), "ladrillo", "mamposteria")
	masonry(3.4, ln, 3.6, e, [sw], [], "ladrillo")
	masonry(3.4, ln, -2.5, 3.6, [gate], [], "sillar")
	plinth(0.0, 3.4, ground(p0.x, p0.y) + 1.0, ground(p0.lerp(p1, 0.4).x, p0.lerp(p1, 0.4).y) + 1.0, "zocalo", 0.05, -2.5)
	box(0.0, 3.6, 0.0, ln, 0.2, 0.12, "sillar")                              # (the string course)
	spandrels(gc, gs, gr, 0.0, "sillar")
	ring(gc, gs, gr, gr + 0.4, 0.08, DEEP, "sillar", 11)
	_reja_arco(gc, gl, gs, gr)
	_ventana_reja(sw, false)
	cornice(-0.05, ln + 0.05, e, false, "ladrillo", 1.2)
	home()
	# to the Calle del Cristo: ashlar to the string course, a blind arch in it walled up with brick; brick over it
	var q0: Vector2 = EB[1]
	var q1: Vector2 = EB[2]
	var ln2 := face(q0, q1)
	var bw := Rect2(ln2 / 2.0 - 0.75, 4.3, 1.5, 2.3)
	masonry(0.0, ln2, -2.5, 3.6, [], [], "sillar")
	masonry(0.0, ln2, 3.6, e, [bw], [], "ladrillo")
	box(-0.05, 3.6, 0.0, ln2 + 0.1, 0.2, 0.12, "sillar")
	var ac := ln2 / 2.0
	var ag: float = _pz(EX)
	ring(ac, ag + 1.5, 1.25, 1.6, 0.06, 0.08, "sillar", 11)                 # (the blind arch, walled up with brick, three slits)
	arched(ac, ag + 0.3, ag + 1.5, 1.25, 0.03, "ladrillo")
	box(ac - 1.25, ag + 0.3, 0.0, 2.5, 1.2, 0.03, "ladrillo")
	for k in [-0.5, 0.0, 0.5]:
		box(ac + k - 0.03, ag + 1.9, 0.031, 0.06, 0.4, 0.01, 0x2a2622)
	_ventana_reja(bw)
	cornice(-0.05, ln2 + 0.05, e, false, "ladrillo", 1.2)
	home()
	# the many sides to the north: the step back, the two slanting sides with a window each, the north side, the side on the home
	for i in range(2, 7):
		var a: Vector2 = EB[i]
		var b: Vector2 = EB[i + 1]
		var lk := a.distance_to(b)
		var holes: Array = []
		if i == 3 or i == 4:
			holes.append(Rect2(lk / 2.0 - 0.45, 4.4, 0.9, 1.3))
		_muro(a, b, e, holes, [], 1.0 if i < 6 else 0.0)
		for r: Rect2 in holes:
			_ventana_reja(r)
		cornice(-0.05, lk + 0.05, e, false, "ladrillo", 1.2)
		home()
	_tent(EB, Vector2(32.2, -4.6), Vector2(29.6, -11.6), e - 0.05, e + 2.1, 0.45)
	for q: Vector2 in [EB[1], EB[2], EB[4], EB[5]]:
		yard.append(spot(q.x, q.y))

## the gate under a round arch: its dark inside, a grille of iron bars up to the arch, two bars across
func _reja_arco(cx: float, y0: float, spring: float, r: float) -> void:
	box(cx - r, y0, -DEEP - 0.02, 2.0 * r, spring - y0, 0.02, 0x2a2622)
	arched(cx, spring - 0.01, spring, r, -DEEP - 0.01, 0x2a2622)
	var n := 13
	for i in range(n + 1):
		var x: float = cx - r + 2.0 * r * i / n
		var dx: float = x - cx
		var top: float = spring + sqrt(maxf(0.0, r * r - dx * dx))
		box(x - 0.012, y0, -0.2, 0.024, top - y0, 0.024, IRON)
	for y in [y0 + 0.12, y0 + 1.0, spring]:
		box(cx - r, y, -0.21, 2.0 * r, 0.04, 0.03, IRON)
	openings += 1

# ---------------- round it ----------------
## the wall line of the south side at x (the crossing stands out of it, the east body back from it)
func _wall_z(x: float) -> float:
	if x > TX1:
		return EB[0].y
	if x > TX0:
		return TZ0
	return 0.0

## where the Paseo's asphalt begins at x (the map's own street), a little short of it
func _kerb_z(x: float) -> float:
	for z in range(int(PAVE_Z * 4.0) + 2, 60):
		var p := spot(x, float(z) * 0.25)
		if MapData.road_edge_dist(p) < 0.25:
			return float(z) * 0.25 - 0.25
	return 11.0

## the edge of the paving to the north at x: the wall of the south side, or before the front the home's low wing
func _north_z(x: float) -> float:
	if x < 0.0:
		return -9.55 - x * 0.0832
	return _wall_z(x)

## the pale paving's top at x: over the ground at the west, level from the crossing on (the street falls away east)
func _pz(x: float) -> float:
	var follow: float = ground(minf(x, PLAT_X), PAVE_Z) + 0.07
	return maxf(follow, ground(x, PAVE_Z) + 0.07)

## a piece of the little stone wall that holds the pale paving, from a to b on the floor plan (its face towards `out`),
## from the street up to the paving's top (ya at a, yb at b), its coping on it
func _murete(a: Vector2, b: Vector2, ya: float, yb: float, out: Vector2) -> void:
	var ga: float = ground(a.x + out.x * 0.3, a.y + out.y * 0.3) - 0.2
	var gb: float = ground(b.x + out.x * 0.3, b.y + out.y * 0.3) - 0.2
	var n := Vector3(out.x, 0, out.y)
	var o := out * 0.05
	quad(Vector3(a.x + o.x, ga, a.y + o.y), Vector3(b.x + o.x, gb, b.y + o.y), Vector3(b.x + o.x, yb, b.y + o.y), Vector3(a.x + o.x, ya, a.y + o.y), "caliza", n)
	var i := -out * 0.3
	quad(Vector3(a.x + i.x, ya + 0.08, a.y + i.y), Vector3(b.x + i.x, yb + 0.08, b.y + i.y), Vector3(b.x + o.x, yb + 0.08, b.y + o.y), Vector3(a.x + o.x, ya + 0.08, a.y + o.y), "caliza", Vector3.UP)
	quad(Vector3(a.x + o.x, ya, a.y + o.y), Vector3(b.x + o.x, yb, b.y + o.y), Vector3(b.x + o.x, yb + 0.08, b.y + o.y), Vector3(a.x + o.x, ya + 0.08, a.y + o.y), "caliza", n)
	pieces += 1

## the pale paving's north edge east of the east body: along its back, then slanting with the street
func _north_edge(x: float) -> float:
	if x <= EXW.x:
		return -7.78
	return lerpf(EXW.y, EXN.y, (x - EXW.x) / (EXN.x - EXW.x))

## where the tiles of the pavement go: south of the pale paving, and round its corner on the Calle del Cristo
func _tile_zone(c: Vector2) -> bool:
	if c.y > PAVE_Z:
		return c.x > SQ_X and c.x < 46.0
	return c.x > EX and c.y > -8.5

## The paving: the pale stone along the south side and round the east end, held by its little wall of stone (a kerb
## at the front, half a metre over the street at the corner); the red and white chequers from there to the kerb of the
## Paseo, where the cars park, and round the corner to the asphalt of both streets; the paved square before the front.
func _paving() -> void:
	var xs: Array = []
	var x := SQ_X
	while x < -0.01:
		xs.append(x)
		x += 2.0
	for stop in [0.0, TX0, TX1, 36.42, EXW.x, EX]:
		while x < stop - 0.01:
			xs.append(x)
			x += 2.0
		xs.append(stop)
		x = stop + 2.0
	for i in range(xs.size() - 1):
		var xa: float = xs[i]
		var xb: float = xs[i + 1]
		if xb - xa < 0.01:
			continue
		var mid: float = (xa + xb) / 2.0
		if mid < 0.0:                                                          # (the square: laid over the ground)
			_drape([Vector2(xa, _north_z(xa + 0.001)), Vector2(xb, _north_z(xb - 0.001)), Vector2(xb, PAVE_Z), Vector2(xa, PAVE_Z)], "losa", 0.07)
			_murete(Vector2(xa, PAVE_Z), Vector2(xb, PAVE_Z), ground(xa, PAVE_Z) + 0.07, ground(xb, PAVE_Z) + 0.07, Vector2(0, 1))
			continue
		var za: float = _north_edge(xa) if mid > 36.42 else _wall_z(mid)
		var zb: float = _north_edge(xb) if mid > 36.42 else _wall_z(mid)
		var ya: float = _pz(xa)
		var yb: float = _pz(xb)
		quad(Vector3(xa, ya, za), Vector3(xb, yb, zb), Vector3(xb, yb, PAVE_Z), Vector3(xa, ya, PAVE_Z), "losa", Vector3.UP)
		pieces += 1
		_murete(Vector2(xa, PAVE_Z), Vector2(xb, PAVE_Z), ya, yb, Vector2(0, 1))
	var ye: float = _pz(EX)
	_murete(Vector2(EX, PAVE_Z), EXN, ye, ye, Vector2(1, 0))                    # (round the corner, along the Calle del Cristo)
	_murete(EXN, EXW, ye, ye, Vector2(EXW.y - EXN.y, EXN.x - EXW.x).normalized())
	_murete(EXW, Vector2(36.42, -7.78), ye, ye, Vector2(0, -1))
	# the floor under it all, for whoever walks on it
	var top := PackedVector2Array([Vector2(PLAT_X, _wall_z(PLAT_X)), Vector2(TX0, 0.0), Vector2(TX0, TZ0), Vector2(TX1, TZ0), Vector2(TX1, EB[0].y),
		Vector2(36.42, EB[0].y), Vector2(36.42, -7.78), EXW, EXN, Vector2(EX, PAVE_Z), Vector2(PLAT_X, PAVE_Z)])
	_decks.append(_poly_deck(top, level + ye + 0.0))
	# the tiles, half a metre a square, on one grid: the chequers, and grey where the cars park along the Paseo
	var t := 0.5
	var ix := 0
	while SQ_X + ix * t < 46.0:
		var x0: float = SQ_X + ix * t
		var kz: float = _kerb_z(x0 + t / 2.0)
		var iz := 0
		while -8.5 + iz * t < 14.0:
			var z0: float = -8.5 + iz * t
			var cc := Vector2(x0 + t / 2.0, z0 + t / 2.0)
			iz += 1
			if not _tile_zone(cc):
				continue
			if MapData.road_edge_dist(spot(cc.x, cc.y)) < 0.25:
				continue
			var parked: bool = cc.x < PARK_X and cc.y > KERB_Z
			var hexc: int = 0x5e5e62 if parked else (0xac5e48 if (ix + iz) % 2 == 0 else 0xe4dccd)
			_drape([Vector2(x0, z0), Vector2(x0 + t, z0), Vector2(x0 + t, z0 + t), Vector2(x0, z0 + t)], hexc, 0.015 if parked else 0.04)
		if x0 + t <= PARK_X and kz > KERB_Z + 0.2:                               # (the kerb between the chequers and the cars)
			var g0: float = ground(x0, KERB_Z)
			var g1: float = ground(x0 + t, KERB_Z)
			quad(Vector3(x0, g0 - 0.1, KERB_Z), Vector3(x0 + t, g1 - 0.1, KERB_Z), Vector3(x0 + t, g1 + 0.06, KERB_Z), Vector3(x0, g0 + 0.06, KERB_Z), 0xb8b2a6, Vector3(0, 0, 1))
		ix += 1
	# the ring of grey stone in the square
	var c := Vector2(-7.6, -4.2)
	var n := 28
	for k in range(n):
		var a0 := TAU * k / n
		var a1 := TAU * (k + 1) / n
		_drape([c + Vector2(cos(a0), sin(a0)) * 2.8, c + Vector2(cos(a1), sin(a1)) * 2.8, c + Vector2(cos(a1), sin(a1)) * 3.1, c + Vector2(cos(a0), sin(a0)) * 3.1], "gris", 0.08)
	_drape([c + Vector2(-0.35, -0.35), c + Vector2(0.35, -0.35), c + Vector2(0.35, 0.35), c + Vector2(-0.35, 0.35)], 0x6a6660, 0.09)

## The elms along the Paseo (the old hollow one before the crossing), the stone posts on the kerb of the pale paving,
## the railed strip by the Calle del Cristo with its cypress.
func _alrededor() -> void:
	for t in [[Vector2(-11.4, 6.6), 9.0, false], [Vector2(-4.9, 6.9), 8.5, false], [Vector2(2.0, 7.0), 8.5, false], [Vector2(8.4, 7.0), 9.0, false],
			[Vector2(15.0, 7.2), 9.5, false], [Vector2(21.5, 7.4), 11.0, true], [Vector2(30.5, 7.2), 9.5, false]]:
		var at: Vector2 = t[0]
		if MapData.road_edge_dist(spot(at.x, at.y)) > 0.9:
			_olmo(at, t[1], t[2])
	for p in [Vector2(-0.8, PAVE_Z - 0.15), Vector2(SIDE_X, PAVE_Z - 0.15), Vector2(18.5, PAVE_Z - 0.15), Vector2(27.5, PAVE_Z - 0.15), Vector2(EX - 0.15, PAVE_Z - 0.15),
			Vector2(EX - 0.15, -2.6), Vector2(37.6, -7.6)]:
		_pilon(p, _pz(minf(p.x, EX)) + 0.08)
	_verja([Vector2(36.5, -7.9), Vector2(35.1, -10.6), Vector2(33.4, -12.5), Vector2(32.3, -13.4)])
	_cipres(Vector2(34.6, -9.8), 9.0)

## a railing of black iron on a low kerb of stone, along these points
func _verja(pts: Array) -> void:
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var ln := face(a, b)
		var ga: float = ground(a.x, a.y)
		var gb: float = ground(b.x, b.y)
		var n: int = maxi(2, int(ln / 0.13))
		for k in range(n + 1):
			var s: float = ln * k / n
			var g: float = lerpf(ga, gb, s / ln) + 0.3
			box(s - 0.011, g, -0.011, 0.022, 1.5, 0.022, IRON)
		for hh in [0.38, 1.7]:
			bar(Vector3(0.0, ga + hh, 0.0), Vector3(ln, gb + hh, 0.0), 0.04, 0.03, IRON)
		box(0.0, minf(ga, gb) - 0.3, -0.12, ln, absf(ga - gb) + 0.6, 0.24, "sillar")
		home()
		solid(Vector3((a.x + b.x) / 2.0, (ga + gb) / 2.0 + 0.9, (a.y + b.y) / 2.0), Vector3(ln, 1.8, 0.2), atan2(-(b - a).y, (b - a).x))
		yard.append(spot(a.x, a.y))
	var last: Vector2 = pts[pts.size() - 1]
	yard.append(spot(last.x, last.y))

## a sloping face of stone (the calvario's cap): like roof() but without UVs, for a material laid by its own triplanar
## mapping whose other pieces have none (a mesh cannot mix vertices with and without them)
func _slope(pts: Array, key) -> void:
	var nrm: Vector3 = ((pts[1] as Vector3) - pts[0]).cross((pts[2] as Vector3) - pts[0]).normalized()
	if nrm.y < 0.0:
		nrm = -nrm
	quad(pts[0], pts[1], pts[2], pts[3], key, nrm)
	pieces += 1

## The calvario in the park to the west: a long block of rubble with quoins of ashlar and a sloping cap, three crosses of
## stone on it on their stepped bases, the middle one the tallest.
func _calvario() -> void:
	var c := _loc(CALV)
	var ax: Vector2 = (_loc(CALV + CALV_AX) - c).normalized()
	var g: float = ground(c.x, c.y)
	var keep := _xf
	_xf = Transform3D(Basis(Vector3(ax.x, 0, ax.y), Vector3.UP, Vector3(-ax.y, 0, ax.x)), Vector3(c.x, g, c.y))
	var L := 4.3
	var Wd := 1.7
	var H := 1.35
	box(-L / 2.0, -0.4, -Wd / 2.0, L, H + 0.4, Wd, "zocalo")
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var qx0: float = (L / 2.0 - 0.42) if sx > 0.0 else (-L / 2.0 - 0.01)
			var qz0: float = (Wd / 2.0 - 0.32) if sz > 0.0 else (-Wd / 2.0 - 0.01)
			for j in range(3):
				box(qx0, j * 0.45, qz0, 0.43, 0.43, 0.33, "sillar")
	# the cap: sloping to every side from a flat top
	var top := H + 0.32
	_slope([Vector3(-L / 2.0 - 0.05, H, Wd / 2.0 + 0.05), Vector3(L / 2.0 + 0.05, H, Wd / 2.0 + 0.05), Vector3(L / 2.0 - 0.5, top, 0.25), Vector3(-L / 2.0 + 0.5, top, 0.25)], "caliza")
	_slope([Vector3(L / 2.0 + 0.05, H, -Wd / 2.0 - 0.05), Vector3(-L / 2.0 - 0.05, H, -Wd / 2.0 - 0.05), Vector3(-L / 2.0 + 0.5, top, -0.25), Vector3(L / 2.0 - 0.5, top, -0.25)], "caliza")
	_slope([Vector3(L / 2.0 + 0.05, H, Wd / 2.0 + 0.05), Vector3(L / 2.0 + 0.05, H, -Wd / 2.0 - 0.05), Vector3(L / 2.0 - 0.5, top, -0.25), Vector3(L / 2.0 - 0.5, top, 0.25)], "caliza")
	_slope([Vector3(-L / 2.0 - 0.05, H, -Wd / 2.0 - 0.05), Vector3(-L / 2.0 - 0.05, H, Wd / 2.0 + 0.05), Vector3(-L / 2.0 + 0.5, top, 0.25), Vector3(-L / 2.0 + 0.5, top, -0.25)], "caliza")
	flat(PackedVector2Array([Vector2(-L / 2.0 + 0.5, -0.25), Vector2(L / 2.0 - 0.5, -0.25), Vector2(L / 2.0 - 0.5, 0.25), Vector2(-L / 2.0 + 0.5, 0.25)]), top, "caliza")
	for k in [[-1.25, 2.3], [0.0, 2.9], [1.25, 2.3]]:
		var x: float = k[0]
		var tall: float = k[1]
		cbox(Vector3(x, top + 0.2, 0.0), Vector3(0.95, 0.4, 0.95), "caliza")
		cbox(Vector3(x, top + 0.55, 0.0), Vector3(0.68, 0.3, 0.68), "caliza")
		var y := top + 0.7
		cbox(Vector3(x, y + tall / 2.0, 0.0), Vector3(0.3, tall, 0.3), "caliza")
		cbox(Vector3(x, y + tall * 0.74, 0.0), Vector3(0.95, 0.28, 0.3), "caliza")
	_xf = keep
	solid(Vector3(c.x, g + 1.0, c.y), Vector3(L, 2.0, Wd), atan2(-ax.y, ax.x))
	yard.append(spot(c.x, c.y))
