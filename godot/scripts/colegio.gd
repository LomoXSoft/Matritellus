extends "res://scripts/obra.gd"
## The old school of the Avenida de Juan Carlos I ("el viejo colegio", the user's words, 16 November 2026: "Pasamos al
## siguiente edificio: el viejo colegio"; referencias/colegio_viejo/, tools/colegio/).
##
## As Street View has it (November 2024; March 2013 for what the trees hide): a school of the 1920s in the brick and
## stone of Toledo -- buff brick with boxes of pale rubble between its courses -- set back from the avenue behind its
## court. Two square towers at its corners, each with a barred window, a window over it and three little arches under
## wide eaves; between them the body of two floors, three windows each side of the door on either floor, the door a
## round arch of pale stone in a panel of brick lattice, a balcony with its flagpoles over it; friezes of saw-tooth
## brick between the floors and under the eaves; dark red windows of small panes; old tiles. Its east wing runs along
## the Calle de Santa Clara with a great stone doorway of its own; its west end gives on to the Calle del Peso.
## Before it the court, painted red, with its basket hoops and floodlights, shut in by a fence of iron bars on a low
## brick wall, a gate to each side street, and a row of trees along the avenue.
##
## Frame: origin at the south-west corner of the west tower (on the Calle del Peso); +x along the front towards the
## Calle de Santa Clara; +z out of it, towards the court and the avenue; y = 0 the court before the door.
## The court is one flat floor laid over the ground: the plane that fits it best along the front and the fence, no
## steeper than a court can be, lifted clear of it; the wall under the fence takes up what is left (the game's
## ground falls two and a half times what the real one does).
## Catastro's parcel 3891715VJ5639S is not raised by the bake (tools/bake_godot.py, COLEGIO): this builds it.
## Nobody goes in, and the gates are shut. No people in it.
## The user, on seeing it ("Increíble. Solo dos notas"): the floodlights stand against the fence, not in the middle
## of the court; and the bus shelter of the pavement goes in too, "la blanca y azul" (it is in his pictures of 2013).
## And on seeing that: "Quita el 'Castilla', deja solo 'La Mancha' y céntrala. Pega dentro un cartel de Roster torcido"
## (his own poster of a drink that does not exist, the one on the grocer's door: chinos.gd, tools/chinos/poster.py).
## And last, with his photograph of the real name plate of tiles over the door: "Creo que podríamos dejarla y usar su
## nombre, total, lleva años cerrado". So this one place carries its real name, on that plate (tools/colegio/placa.py
## paints it); and the panel of lattice the door stands in follows that photograph: its stepped frame, its shields.

const READY := true                             # (tools/bake_godot.py looks for this: with it, Catastro's block is not raised)
const O := Vector2(-427.35, 121.61)
const U := Vector2(0.9706, -0.2407)
const NAME := "INSTITUTO GARCILASO DE LA VEGA"       # its real name, at the user's word (see above): on its tiled plate
const PLATE := "res://assets/colegio/placa_instituto.png"       # painted by tools/colegio/placa.py
const POSTER := "res://assets/chinos/poster_roster.png"         # the user's poster, redrawn by tools/chinos/poster.py
const X1 := 7.5                                 # where the west tower ends and the body begins...
const X2 := 32.64                               # ...where the body ends and the east tower begins...
const X3 := 40.35                               # ...and the east tower's outer corner
const OUTZ := 1.88                              # how far the towers stand out before the body
const AXIS := 20.07                             # the middle of the front: the door
const TDW := 7.5                                # how deep the west tower is...
const TDE := 7.7                                # ...and the east one
const WEST_END := -13.3                         # the north end of the west block, on the Calle del Peso...
const EAST_END := -21.7                         # ...and of the east wing, on the Calle de Santa Clara
const BODY_BACK := -9.13                        # the back of the body between the towers
const BACK_END := -20.5                         # the back of what stands behind it
const PLINTH := 1.15                            # the foot of dark rubble and its band of stone
const SILL0 := 2.55                             # the ground floor's windows...
const HEAD0 := 4.58
const BAND := 6.3                               # the frieze between the floors: its top
const SILL1 := 6.8                              # the upper floor's windows...
const HEAD1 := 8.7
const HB := 10.6                                # the top of the body's walls
const STRING := 11.4                            # the frieze under the towers' arches
const ARC0 := 12.0                              # the arches: their sills...
const ARC_SPRING := 13.45                       # ...where they spring...
const ARC_R := 0.42                             # ...and their radius
const HT := 15.3                                # the top of the towers' walls
const BAYS: Array = [8.70, 11.42, 14.13, 26.01, 28.72, 31.44]       # the body's windows: their middles
const DOWN := -4.5                              # well under any ground
const MAROON := 0x8a2c2a                        # its windows
const OLD_WOOD := 0x4a382c
const GLASS := 0x3a4652
const BARS := 0x2a2a2e
const COURT := 0x7e3a30
const BODY: Array = [Vector2(7.5, -1.88), Vector2(32.64, -1.88), Vector2(32.64, -9.13), Vector2(7.5, -9.13)]
const WEST: Array = [Vector2(0, -7.5), Vector2(7.5, -7.5), Vector2(7.5, -13.3), Vector2(0, -13.3)]
const WING: Array = [Vector2(32.64, -7.7), Vector2(40.35, -7.7), Vector2(40.35, -21.7), Vector2(32.64, -21.7)]
const BACK: Array = [Vector2(7.5, -9.13), Vector2(32.64, -9.13), Vector2(32.64, -20.5), Vector2(12.2, -20.5), Vector2(12.2, -13.3), Vector2(7.5, -13.3)]
const TOWER_W: Array = [Vector2(0, 0), Vector2(7.5, 0), Vector2(7.5, -7.5), Vector2(0, -7.5)]
const TOWER_E: Array = [Vector2(32.64, 0), Vector2(40.35, 0), Vector2(40.35, -7.7), Vector2(32.64, -7.7)]
const FENCE: Array = [Vector2(0.15, 0.25), Vector2(0.43, 18.85), Vector2(35.0, 22.6), Vector2(37.1, 21.2), Vector2(40.3, 5.4), Vector2(40.3, 0.25)]      # the court's fence: Peso, the avenue, its corner, Santa Clara
const GATE_W := Vector2(11.2, 14.4)             # the gate on the Calle del Peso: from where to where along that side of the fence...
const GATE_E := Vector2(4.2, 7.4)               # ...and the one on the Calle de Santa Clara, along the stretch of it after the corner

var door: Vector2               # in front of its door, on the map
var gates: Array = []           # the middle of each gate, on the map
var trees := 0
var shelter: Vector2            # the bus shelter on the avenue's pavement, on the map
var poster := false              # whether the poster is stuck inside it (its picture was found)
var plate := false               # whether its name plate of tiles is over the door (its picture was found)
var sx := 0.0                   # how the court's floor falls in a metre: along the front...
var sz := 0.0                   # ...and out, towards the avenue

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"ladrillo":         # buff brick, gone golden
			m = Tex.mat("brick_wall_003@1.15", Color(1.2, 1.24, 1.28))
		"rubble":           # the boxes of pale stone between its courses
			m = Tex.mat("stone_wall", Color(1.42, 1.4, 1.36))
		"zocalo":           # the foot of darker rubble
			m = Tex.mat("stone_wall", Color(0.98, 0.95, 0.9))
		"piedra":           # the pale stone of the doorways and of the bands
			m = _glow(Tex.mat("granular_concrete", Color(1.14, 1.05, 0.86), false), 0.12)
		"tiles":            # old tiles, weathered (its UVs are in units of 1.6 m, running down the slope)
			var tm: StandardMaterial3D = Tex.mat(Tex.pick("tiles") if Tex.pick("tiles") != "" else "clay_roof_tiles_02", Color(0.7, 0.66, 0.62), true, 1.6)
			tm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = tm
		"medianera":        # the walls it shares with its neighbours
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.86, 0.82, 0.74)), 0.25)
		"leaf":
			m = W._tmat(0x5a9a48, "leaf", 1.3)
		"placa":            # the name plate: glazed tiles, white in the shade too
			var tm2 := StandardMaterial3D.new()
			tm2.albedo_texture = Parts.texture(PLATE)
			tm2.roughness = 1.0
			m = _glow(tm2, 0.32)
		"cartel":           # the poster in the bus shelter: printed paper, bright in the shade too
			var pm := StandardMaterial3D.new()
			pm.albedo_texture = Parts.texture(POSTER)
			pm.roughness = 1.0
			m = _glow(pm, 0.3)
		"damero":           # the pavement of the avenue before it: red and cream tiles, in chequers
			var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
			for i in range(2):
				for j in range(2):
					img.set_pixel(i, j, Color(0.8, 0.76, 0.68) if (i + j) % 2 == 0 else Color(0.6, 0.36, 0.3))
			var dm := StandardMaterial3D.new()
			dm.albedo_texture = ImageTexture.create_from_image(img)
			dm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			dm.uv1_triplanar = true
			dm.uv1_world_triplanar = true
			dm.uv1_scale = Vector3.ONE / 0.6
			dm.roughness = 1.0
			m = dm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	var data: Dictionary = MapData.colegio
	var o := Vector2(data["o"][0], data["o"][1]) if data.has("o") else O
	var u := Vector2(data["u"][0], data["u"][1]) if data.has("u") else U
	var out := Vector2(-u.y, u.x)
	# the court's floor: the plane that best fits the ground at the foot of the front and along the fence, then lifted clear of it
	var at: Array = []
	for x in [0.5, 7.5, 14.0, AXIS, 26.0, 32.6, 39.8]:
		at.append(Vector2(x, 0.4))
	for i in range(FENCE.size() - 1):
		at.append(FENCE[i])
		at.append(((FENCE[i] as Vector2) + FENCE[i + 1]) / 2.0)
	var hs: Array = []
	for q: Vector2 in at:
		hs.append(MapData.height(o + u * q.x + out * q.y))
	var fall: Vector2 = _fit(at, hs)
	sx = clampf(fall.x, -0.02, 0.02)
	sz = clampf(fall.y, -0.065, 0.0)
	level = -1e9
	for i in range(at.size()):
		level = maxf(level, float(hs[i]) + 0.12 - sx * ((at[i] as Vector2).x - AXIS) - sz * (at[i] as Vector2).y)
	transform = Transform3D(Basis(Vector3(u.x, 0, u.y), Vector3.UP, Vector3(out.x, 0, out.y)), Vector3(o.x, level, o.y))
	W.add_child(self)
	door = spot(AXIS, 0.6)
	_front()
	_tower(TOWER_W, [0, 3])
	_tower(TOWER_E, [0, 1])
	_peso()
	_santa_clara()
	_back()
	_roofs()
	_court()
	_fence()
	_things()
	home()
	_commit()
	_solid_walls()
	_tell_map()

## What stands here, for whoever asks the map how much room there is and for the little map.
func _tell_map() -> void:
	for ring in [BODY, WEST, WING, BACK, TOWER_W, TOWER_E]:
		var pts := PackedVector2Array()
		for q: Vector2 in ring:
			pts.append(spot(q.x, q.y))
		MapData.outlines.append(pts)
		if not MapData._wall_grid.is_empty():
			for i in range(pts.size()):
				var a: Vector2 = pts[i]
				var b: Vector2 = pts[(i + 1) % pts.size()]
				MapData._grid_add(MapData._wall_grid, a.min(b), a.max(b), [a, b])

## its bodies, solid
func _solid_walls() -> void:
	for ring in [BODY, WEST, WING, TOWER_W, TOWER_E]:
		_prism(ring, DOWN, HB)
	_prism([Vector2(7.5, -9.13), Vector2(32.64, -9.13), Vector2(32.64, -20.5), Vector2(12.2, -20.5)], DOWN, HB)
	_prism([Vector2(7.5, -9.13), Vector2(12.2, -9.13), Vector2(12.2, -13.3), Vector2(7.5, -13.3)], DOWN, HB)

# ---------------- helpers ----------------
## the court's floor at a spot of it, over the frame's zero
func _cy(q: Vector2) -> float:
	return sx * (q.x - AXIS) + sz * q.y

## the slopes (along x, along z) of the plane that fits these heights best at these spots
func _fit(at: Array, hs: Array) -> Vector2:
	var n: float = at.size()
	var mx := 0.0
	var mz := 0.0
	var mh := 0.0
	for i in range(at.size()):
		mx += (at[i] as Vector2).x / n
		mz += (at[i] as Vector2).y / n
		mh += float(hs[i]) / n
	var sxx := 0.0
	var szz := 0.0
	var sxz := 0.0
	var sxh := 0.0
	var szh := 0.0
	for i in range(at.size()):
		var dx: float = (at[i] as Vector2).x - mx
		var dz: float = (at[i] as Vector2).y - mz
		var dh: float = float(hs[i]) - mh
		sxx += dx * dx
		szz += dz * dz
		sxz += dx * dz
		sxh += dx * dh
		szh += dz * dh
	var det: float = sxx * szz - sxz * sxz
	if absf(det) < 0.001:
		return Vector2.ZERO
	return Vector2((sxh * szz - szh * sxz) / det, (szh * sxx - sxh * sxz) / det)

## The boxes of rubble of a stretch of wall ("cajones"): rows of them from y0 to y1 with a course of brick between one
## row and the next, and in each row a box every `wide` or so with a pier of brick between one and the next.
func _boxes(x0: float, x1: float, y0: float, y1: float, tall := 0.74, course := 0.13, wide := 1.35, pier := 0.24) -> Array:
	var rows: Array = []
	var n: int = maxi(1, int(round((x1 - x0 + pier) / (wide + pier))))
	var w: float = (x1 - x0 - (n - 1) * pier) / n
	var y := y0
	while y + 0.32 < y1:
		var h: float = minf(tall, y1 - y)
		for i in range(n):
			rows.append(Rect2(x0 + i * (w + pier), y, w, h))
		y += h + course
	return rows

## the brick left whole round an opening: its hole grown by `by`
func _round(r: Rect2, by := 0.22) -> Rect2:
	return r.grow(by)

## The wall of a front, on the frame being built, from 0 to `ln`: brick with its boxes of rubble on both floors, the
## holes left open, the foot of dark rubble under its band of stone, the frieze between the floors and the one under
## the eaves at `top`. `gaps`: from where to where along it there is a doorway, which its foot leaves free.
func _wall(ln: float, top: float, holes: Array, gaps: Array = []) -> void:
	var panels: Array = _boxes(0.5, ln - 0.5, PLINTH + 0.3, BAND - 0.75)
	panels.append_array(_boxes(0.5, ln - 0.5, BAND + 0.2, (STRING - 0.5) if top > HB + 1.0 else (top - 0.62)))
	var over: Array = []
	for r: Rect2 in holes:
		over.append(_round(r))
	masonry(0.0, ln, DOWN, top, holes, panels, "ladrillo", "rubble", over)
	var from := 0.0
	var stops: Array = gaps.duplicate()
	stops.append(Vector2(ln, ln))
	for gap: Vector2 in stops:
		if gap.x - from > 0.05:
			plinth(from, gap.x, PLINTH - 0.15, PLINTH - 0.15, "zocalo", 0.06, DOWN)
			box(from - (0.02 if from < 0.01 else 0.0), PLINTH - 0.15, 0.0, gap.x - from + (0.02 if from < 0.01 else 0.0) + (0.02 if gap.x > ln - 0.01 else 0.0), 0.15, 0.11, "piedra")
		from = gap.y
	_frieze(0.0, ln, BAND)
	cornice(0.0, ln, top + 0.3, true, "ladrillo", 1.0)

## a frieze on the wall being built, its top at y: a course of brick, a row of bricks set cornerwise, another course
func _frieze(x0: float, x1: float, y: float) -> void:
	box(x0, y - 0.34, 0.0, x1 - x0, 0.07, 0.05, "ladrillo")
	box(x0, y - 0.27, 0.0, x1 - x0, 0.2, 0.012, 0x8a6a4c)
	var n := int((x1 - x0) / 0.17)
	for i in range(n):
		tbox(Transform3D(Basis(Vector3.UP, PI / 4.0).scaled_local(Vector3(0.1, 0.18, 0.1)), Vector3(x0 + (i + 0.5) * (x1 - x0) / n, y - 0.17, 0.035)), "ladrillo")
	box(x0, y - 0.07, 0.0, x1 - x0, 0.07, 0.07, "ladrillo")

## what fills a window's hole: glass, its frame, two leaves of small panes, and its sill of brick
func _win(r: Rect2, frame := MAROON) -> void:
	var z: float = -DEEP + 0.08
	box(r.position.x, r.position.y, z - 0.04, r.size.x, r.size.y, 0.03, GLASS)
	for q in [[r.position.x, r.position.y, 0.08, r.size.y], [r.end.x - 0.08, r.position.y, 0.08, r.size.y], [r.position.x, r.position.y, r.size.x, 0.08], [r.position.x, r.end.y - 0.08, r.size.x, 0.08],
			[r.position.x + r.size.x / 2.0 - 0.04, r.position.y, 0.08, r.size.y]]:
		box(q[0], q[1], z - 0.02, q[2], q[3], 0.06, frame)
	for j in range(1, 4):                           # the bars of its panes: three across each leaf, one up it
		box(r.position.x + 0.08, r.position.y + j * r.size.y / 4.0 - 0.012, z - 0.015, r.size.x - 0.16, 0.024, 0.04, frame)
	for s in [0.25, 0.75]:
		box(r.position.x + r.size.x * s - 0.012, r.position.y + 0.08, z - 0.015, 0.024, r.size.y - 0.16, 0.04, frame)
	box(r.position.x - 0.14, r.position.y - 0.1, 0.0, r.size.x + 0.28, 0.1, 0.09, "ladrillo")

## an iron grille before a window, with its crest and the little roof of brick the barred windows have over them
func _reja(r: Rect2, out := 0.17) -> void:
	grille(r, out, BARS)
	var cx: float = r.position.x + r.size.x / 2.0
	var y: float = r.end.y + 0.05
	for s in [-1.0, 1.0]:
		bar(Vector3(cx + s * r.size.x * 0.5, y, out), Vector3(cx + s * 0.1, y + 0.3, out), 0.022, 0.022, BARS)
		bar(Vector3(cx + s * r.size.x * 0.27, y, out), Vector3(cx + s * 0.08, y + 0.17, out), 0.018, 0.018, BARS)
	cbox(Vector3(cx, y + 0.34, out), Vector3(0.14, 0.18, 0.03), BARS)
	box(r.position.x - 0.2, r.end.y + 0.55, 0.0, r.size.x + 0.4, 0.09, 0.12, "ladrillo")
	box(r.position.x - 0.12, r.end.y + 0.64, 0.0, r.size.x + 0.24, 0.07, 0.08, "ladrillo")

## A panel of terracotta lattice on the wall being built: slanting bars over the dark of its holes. The pattern is
## the wall's, not the panel's: two panels side by side carry on one another's lines.
func _lattice(r: Rect2, step := 0.15) -> void:
	if r.size.x < 0.1 or r.size.y < 0.1:
		return
	box(r.position.x, r.position.y, 0.0, r.size.x, r.size.y, 0.03, 0x4a2e22)
	var z := 0.045
	var k0: int = int(floor((r.position.x - r.end.y) / step))
	var k1: int = int(ceil((r.end.x - r.position.y) / step))
	for k in range(k0, k1 + 1):                    # the bars that climb to the right: y = x - c
		var c: float = k * step
		var x0: float = maxf(r.position.x, r.position.y + c)
		var x1: float = minf(r.end.x, r.end.y + c)
		if x1 - x0 > 0.03:
			bar(Vector3(x0, x0 - c, z), Vector3(x1, x1 - c, z), 0.03, 0.05, 0xc88c5c)
	k0 = int(floor((r.position.x + r.position.y) / step))
	k1 = int(ceil((r.end.x + r.end.y) / step))
	for k in range(k0, k1 + 1):                    # ...and those that climb to the left: y = c - x
		var c: float = k * step
		var x0: float = maxf(r.position.x, c - r.end.y)
		var x1: float = minf(r.end.x, c - r.position.y)
		if x1 - x0 > 0.03:
			bar(Vector3(x0, c - x0, z), Vector3(x1, c - x1, z), 0.03, 0.05, 0xc88c5c)

## A round-arched doorway of pale stone on the wall being built: its hole `r` (up to where the arch springs), the
## spandrels, the great stones of its arch out to `r1`, its jambs, and the leaf in it; the stone stands `proud` of the wall.
func _doorway(r: Rect2, r1: float, leaf: int, proud := 0.05) -> void:
	var rad: float = r.size.x / 2.0
	var cx: float = r.position.x + rad
	var spring: float = r.end.y
	ring(cx, spring, rad, r1, proud, DEEP + proud, "piedra", 14)
	for s in [-1.0, 1.0]:                           # its jambs
		box(cx + s * (rad + (r1 - rad) / 2.0) - (r1 - rad) / 2.0, r.position.y, 0.0, r1 - rad, spring - r.position.y, proud, "piedra")
	arched(cx, r.position.y, spring, rad, -DEEP + 0.03, leaf, 14)
	box(cx - 0.02, r.position.y, -DEEP + 0.03, 0.04, spring - r.position.y + rad * 0.98, 0.03, 0x2a1a16)
	for j in range(3):                              # the panels of its two leaves
		for s in [-1.0, 1.0]:
			box(cx + s * rad * 0.5 - rad * 0.36, r.position.y + 0.25 + j * (spring - r.position.y) / 3.0, -DEEP + 0.035, rad * 0.72, (spring - r.position.y) / 3.0 - 0.2, 0.02, 0x6a221e if leaf == MAROON else 0x3a2a20)

# ---------------- the front, between the towers ----------------
func _front() -> void:
	var ln: float = face(Vector2(X1, -OUTZ), Vector2(X2, -OUTZ))
	var mid: float = AXIS - X1
	var holes: Array = []
	var lower: Array = []
	var upper: Array = []
	for c in BAYS:
		lower.append(Rect2(float(c) - X1 - 0.75, SILL0, 1.5, HEAD0 - SILL0))
		upper.append(Rect2(float(c) - X1 - 0.75, SILL1, 1.5, HEAD1 - SILL1))
	holes.append_array(lower)
	holes.append_array(upper)
	var way := Rect2(mid - 0.95, DOWN, 1.9, 2.32 - DOWN)             # the door: up to where its arch springs
	var crown := Rect2(mid - 0.95, 2.32, 1.9, 0.95)
	var balcony := Rect2(mid - 0.78, 6.43, 1.56, HEAD1 - 6.43)
	holes.append_array([way, crown, balcony])
	_wall(ln, HB, holes, [Vector2(mid - 2.57, mid + 2.57)])
	for r: Rect2 in lower:
		_win(r)
	for r: Rect2 in upper:
		_win(r)
	# The door, as the user's photograph has it: a panel of terracotta lattice ("alfiz") in a moulded frame of stone, a
	# step higher in its middle; in it the round arch of pale stone -- a ring of voussoirs round a ring of greater
	# stones --, a blank shield of stone in each upper corner, and over the arch the name plate of tiles.
	var side := 4.89                                # the panel's top at its sides...
	var top := 5.33                                 # ...and in its middle
	spandrels(mid, 2.32, 0.95, 0.0, "ladrillo")
	for q in [Rect2(mid - 2.42, PLINTH - 0.15, 0.32, side - PLINTH + 0.15), Rect2(mid + 2.1, PLINTH - 0.15, 0.32, side - PLINTH + 0.15),      # beside the jambs
			Rect2(mid - 2.1, 2.32, 1.15, 1.83), Rect2(mid + 0.95, 2.32, 1.15, 1.83),      # the corners over the arch (the arch itself hides the rest of them)
			Rect2(mid - 2.1, 4.15, 4.2, side - 4.15), Rect2(mid - 1.4, side, 2.8, top - side)]:      # over it, and the step in the middle
		_lattice(q)
	var fw := 0.15                                  # its frame
	for q in [[mid - 2.42 - fw, 0.0, fw, side + fw], [mid + 2.42, 0.0, fw, side + fw], [mid - 2.42 - fw, side, 2.42 + fw - 1.4, fw], [mid + 1.4, side, 2.42 + fw - 1.4, fw],
			[mid - 1.4 - fw, side, fw, top - side + fw], [mid + 1.4, side, fw, top - side + fw], [mid - 1.4 - fw, top, 2.8 + 2.0 * fw, fw]]:
		box(q[0], q[1], 0.0, q[2], q[3], 0.1, "piedra")
		box(q[0] + 0.035, q[1] + (0.035 if q[3] < 0.3 else 0.0), 0.1, maxf(0.02, q[2] - 0.07), maxf(0.02, q[3] - (0.07 if q[3] < 0.3 else 0.0)), 0.025, "piedra")
	var out := 0.09
	_doorway(Rect2(mid - 0.95, 0.0, 1.9, 2.32), 2.1, MAROON, out)
	var joint := 0xb3a78c                           # the joints of its stones: between the two rings, between one stone and the next, up the jambs
	for i in range(24):
		var a0: float = PI * i / 24.0
		var a1: float = PI * (i + 1) / 24.0
		bar(Vector3(mid + cos(a0) * 1.74, 2.32 + sin(a0) * 1.74, out + 0.002), Vector3(mid + cos(a1) * 1.74, 2.32 + sin(a1) * 1.74, out + 0.002), 0.004, 0.018, joint)
	for i in range(1, 11):
		var a: float = PI * i / 11.0
		bar(Vector3(mid + cos(a) * 1.74, 2.32 + sin(a) * 1.74, out + 0.002), Vector3(mid + cos(a) * 2.1, 2.32 + sin(a) * 2.1, out + 0.002), 0.004, 0.016, joint)
	for i in range(1, 6):
		var a: float = PI * i / 6.0
		bar(Vector3(mid + cos(a) * 0.95, 2.32 + sin(a) * 0.95, out + 0.002), Vector3(mid + cos(a) * 1.74, 2.32 + sin(a) * 1.74, out + 0.002), 0.004, 0.016, joint)
	for sd in [-1.0, 1.0]:
		for j in range(1, 5):
			box(mid + sd * 1.525 - 0.575, j * 0.58, out, 1.15, 0.014, 0.003, joint)
		box(mid + sd * 1.74 - 0.007, 0.0, out, 0.014, 2.32, 0.003, joint)
		# its two shields: blank stone, pointed below
		var sx: float = mid + sd * 1.9
		slab(PackedVector2Array([Vector2(sx - 0.25, 4.64), Vector2(sx + 0.25, 4.64), Vector2(sx + 0.25, 3.98), Vector2(sx + 0.17, 3.84), Vector2(sx, 3.76), Vector2(sx - 0.17, 3.84), Vector2(sx - 0.25, 3.98)]), 0.105, 0.04, "piedra")
	# the name plate: glazed tiles in a thin frame of terracotta (or, should its picture be missing, plain white with the name)
	var pw := 2.07
	var ph := 0.49
	var py := 4.59
	box(mid - pw / 2.0 - 0.05, py - 0.05, 0.0, pw + 0.1, ph + 0.1, 0.075, 0xb9774c)
	if Parts.texture(PLATE) != null:
		plate = true
		quad(Vector3(mid - pw / 2.0, py, 0.08), Vector3(mid + pw / 2.0, py, 0.08), Vector3(mid + pw / 2.0, py + ph, 0.08), Vector3(mid - pw / 2.0, py + ph, 0.08), "placa", Vector3(0, 0, 1),
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	else:
		box(mid - pw / 2.0, py, 0.075, pw, ph, 0.006, 0xf4f1e6)
		_text(NAME, Vector3(mid, py + ph / 2.0, 0.085), 48, 0x1c286e, 0.0024)
	box(mid - 1.3, -0.1, 0.0, 2.6, 0.22, 0.5, "piedra")                                 # its step
	# the balcony over it: a slab of stone on its brackets, an iron rail, three bare flagpoles
	var by := 6.2
	box(mid - 2.0, by, 0.0, 4.0, 0.2, 0.85, "piedra")
	for s in [-1.5, 0.0, 1.5]:
		box(mid + s - 0.1, by - 0.4, 0.0, 0.2, 0.4, 0.6, "piedra")
	var keep := _xf
	_xf = keep * Transform3D(Basis(), Vector3(0, 0, 0.8))
	box(mid - 1.97, by + 1.2, -0.02, 3.94, 0.04, 0.04, BARS)
	box(mid - 1.97, by + 0.28, -0.015, 3.94, 0.03, 0.03, BARS)
	for i in range(29):
		box(mid - 1.96 + i * 0.14 - 0.008, by + 0.2, -0.008, 0.016, 1.0, 0.016, BARS)
	_xf = keep
	for s in [-1.0, 1.0]:
		for i in range(6):
			box(mid + s * 1.96 - 0.008, by + 0.2, 0.08 + i * 0.14, 0.016, 1.0, 0.016, BARS)
		box(mid + s * 1.96 - 0.02, by + 1.2, 0.0, 0.04, 0.04, 0.8, BARS)
	box(balcony.position.x, balcony.position.y, -DEEP + 0.04, balcony.size.x, balcony.size.y, 0.03, GLASS)
	for q in [[balcony.position.x, 0.08], [balcony.end.x - 0.08, 0.08], [mid - 0.04, 0.08]]:
		box(q[0], balcony.position.y, -DEEP + 0.06, q[1], balcony.size.y, 0.06, MAROON)
	box(balcony.position.x, balcony.end.y - 0.08, -DEEP + 0.06, balcony.size.x, 0.08, 0.06, MAROON)
	box(balcony.position.x, balcony.position.y, -DEEP + 0.07, balcony.size.x, 0.75, 0.03, MAROON)
	for s in [-0.6, 0.0, 0.6]:                      # the flagpoles, leaning out
		bar(Vector3(mid + s, by + 1.15, 0.78), Vector3(mid + s * 1.5, by + 3.2, 1.35), 0.035, 0.035, 0xd9dde0)
	home()

# ---------------- the towers ----------------
## A tower on its square `sq` (its corners: front left, front right, back right, back left): four walls with the
## three little arches at the top of each, under wide eaves and a roof to a point; `open`: which of its faces (0 the
## front, 1 the east, 2 the back, 3 the west) have its two windows, the lower one barred.
func _tower(sq: Array, open: Array) -> void:
	var x0: float = sq[0].x
	var x1: float = sq[1].x
	var z1: float = sq[0].y
	var z0: float = sq[2].y
	var sides: Array = [[Vector2(x0, z1), Vector2(x1, z1)], [Vector2(x1, z1), Vector2(x1, z0)], [Vector2(x1, z0), Vector2(x0, z0)], [Vector2(x0, z0), Vector2(x0, z1)]]
	for k in range(4):
		var ln: float = face(sides[k][0], sides[k][1])
		var c: float = ln / 2.0
		var holes: Array = []
		var low := Rect2(c - 0.7, 2.45, 1.4, 2.1)
		var high := Rect2(c - 0.72, SILL1, 1.44, HEAD1 - SILL1)
		if open.has(k):
			holes.append_array([low, high])
		var arcs: Array = []
		for i in range(3):
			arcs.append(Rect2(c + (i - 1) * 1.22 - ARC_R, ARC0, 2.0 * ARC_R, ARC_SPRING - ARC0))
			holes.append(Rect2(c + (i - 1) * 1.22 - ARC_R, ARC0, 2.0 * ARC_R, ARC_SPRING - ARC0 + ARC_R))
		_wall(ln, HT, holes)
		_frieze(0.0, ln, STRING)
		if open.has(k):
			_win(low)
			_reja(low)
			_win(high)
		# the three arches in their sunk panel: glass, the bricks of each arch, a sill, the frame of the panel
		for r: Rect2 in arcs:
			var cx: float = r.position.x + ARC_R
			spandrels(cx, ARC_SPRING, ARC_R, 0.0, "ladrillo")
			arched(cx, ARC0, ARC_SPRING, ARC_R, -DEEP + 0.04, GLASS, 10)
			ring(cx, ARC_SPRING, ARC_R, ARC_R + 0.13, 0.03, 0.03, "ladrillo", 10)
			box(r.position.x, ARC0, -DEEP + 0.06, 0.05, ARC_SPRING - ARC0, 0.05, MAROON)
			box(r.end.x - 0.05, ARC0, -DEEP + 0.06, 0.05, ARC_SPRING - ARC0, 0.05, MAROON)
			box(r.position.x, ARC_SPRING - 0.03, -DEEP + 0.06, r.size.x, 0.05, 0.05, MAROON)
			box(cx - 0.02, ARC0, -DEEP + 0.06, 0.04, ARC_SPRING - ARC0 + ARC_R * 0.95, 0.04, MAROON)
		box(c - 2.05, ARC0 - 0.12, 0.0, 4.1, 0.12, 0.1, "ladrillo")
		box(c - 2.05, ARC0 - 0.12, 0.0, 0.14, 2.5, 0.05, "ladrillo")
		box(c + 1.91, ARC0 - 0.12, 0.0, 0.14, 2.5, 0.05, "ladrillo")
		box(c - 2.05, ARC0 + 2.3, 0.0, 4.1, 0.12, 0.06, "ladrillo")
		_lattice(Rect2(c - 1.9, ARC0 - 0.5, 3.8, 0.34))
		var nb := int(ln / 0.62)                    # the brackets of its eaves
		for i in range(nb + 1):
			box(i * (ln - 0.12) / nb, HT + 0.3, 0.0, 0.12, 0.2, 0.95, 0x6a4a30)
		home()
	var top: Vector3 = _hip(x0, x1, z0, z1, HT + 0.5, 2.1, 1.1)
	cbox(top + Vector3(0, 1.0, 0), Vector3(0.04, 2.0, 0.04), BARS)                      # its lightning rod
	ball(top + Vector3(0, 0.12, 0), 0.14, 0x7d6a45, 1.0, 8, 5)

# ---------------- the Calle del Peso ----------------
## The west block north of its tower: two floors on the street, an old window of dark wood on each; its end wall
## against the neighbour.
func _peso() -> void:
	var ln: float = face(Vector2(0, WEST_END), Vector2(0, -TDW))
	var low := Rect2(ln / 2.0 - 0.85, 2.3, 1.7, 2.25)
	var high := Rect2(ln / 2.0 - 0.85, SILL1, 1.7, HEAD1 - SILL1)
	_wall(ln, HB, [low, high])
	_win(low, OLD_WOOD)
	_win(high, OLD_WOOD)
	home()
	_plain(Vector2(7.5, WEST_END), Vector2(0, WEST_END), DOWN, HB + 0.3, "medianera")

# ---------------- the Calle de Santa Clara ----------------
## The east wing north of its tower: a barred window, the great doorway of stone in its panel of lattice, another
## barred window, and three windows over them; its end wall against the neighbour.
func _santa_clara() -> void:
	var ln: float = face(Vector2(X3, -TDE), Vector2(X3, EAST_END))
	var gd: float = ground(X3 + 0.5, -TDE - 6.3)   # the doorway stands on the street's own ground
	var w1 := Rect2(1.5, 2.45, 1.4, 2.1)
	var w2 := Rect2(10.7, 2.45, 1.4, 2.1)
	var way := Rect2(6.3 - 0.85, DOWN, 1.7, gd + 2.05 - DOWN)
	var crown := Rect2(6.3 - 0.85, gd + 2.05, 1.7, 0.85)
	var ups: Array = []
	for c in [2.6, 6.3, 11.4]:
		ups.append(Rect2(float(c) - 0.72, SILL1, 1.44, HEAD1 - SILL1))
	var holes: Array = [w1, w2, way, crown]
	holes.append_array(ups)
	_wall(ln, HB, holes, [Vector2(6.3 - 2.65, 6.3 + 2.65)])
	_win(w1)
	_reja(w1)
	_win(w2)
	_reja(w2)
	for r: Rect2 in ups:
		_win(r)
	spandrels(6.3, gd + 2.05, 0.85, 0.0, "ladrillo")
	_lattice(Rect2(6.3 - 2.65, gd + 0.3, 1.0, 4.3))
	_lattice(Rect2(6.3 + 1.65, gd + 0.3, 1.0, 4.3))
	_lattice(Rect2(6.3 - 1.65, gd + 3.72, 3.3, 0.88))
	_doorway(Rect2(6.3 - 0.85, gd, 1.7, 2.05), 1.65, OLD_WOOD)
	box(6.3 - 2.65, gd + 4.6, 0.0, 5.3, 0.1, 0.07, "ladrillo")
	home()
	_plain(Vector2(X3, EAST_END), Vector2(X2, EAST_END), DOWN, HB + 0.3, "medianera")
	_plain(Vector2(X2, EAST_END), Vector2(X2, BACK_END), DOWN, HB + 0.3, "medianera")

# ---------------- what is behind ----------------
## What no street sees: the back of the body and what stands behind it, in plain render.
func _back() -> void:
	for i in range(2, BACK.size()):                 # (its first two sides are the body's own back and the wing)
		_plain(BACK[i], BACK[(i + 1) % BACK.size()], DOWN, HB - 0.4, "medianera")

# ---------------- its roofs ----------------
## A roof of tiles over any outline: every eave runs up to the nearer end of the ridge (r0 -- r1).
func _tent(pts: Array, r0: Vector2, r1: Vector2, ye: float, yr: float, out := 0.7) -> void:
	var c := Vector2.ZERO
	for q: Vector2 in pts:
		c += q / pts.size()
	var a0 := Vector3(r0.x, yr, r0.y)
	var a1 := Vector3(r1.x, yr, r1.y)
	var n := pts.size()
	for i in range(n):
		var a: Vector2 = pts[i] + (pts[i] - c).normalized() * out
		var b: Vector2 = pts[(i + 1) % n] + (pts[(i + 1) % n] - c).normalized() * out
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

func _roofs() -> void:
	_tent(BODY, Vector2(X1 + 1.0, -5.5), Vector2(X2 - 1.0, -5.5), HB + 0.5, HB + 2.1)
	_tent(WING, Vector2(36.5, -9.0), Vector2(36.5, -19.5), HB + 0.5, HB + 2.2)
	_tent(WEST, Vector2(2.2, -10.4), Vector2(5.3, -10.4), HB + 0.5, HB + 1.8)
	_tent([Vector2(7.5, -9.13), Vector2(32.64, -9.13), Vector2(32.64, -20.5), Vector2(12.2, -20.5)], Vector2(15.0, -14.8), Vector2(30.0, -14.8), HB + 0.1, HB + 2.0, 0.3)
	face(Vector2(X1, -OUTZ), Vector2(X2, -OUTZ))   # the brackets of the body's eaves
	var ln: float = X2 - X1
	var nb := int(ln / 0.62)
	for i in range(nb + 1):
		box(i * (ln - 0.12) / nb, HB + 0.3, 0.0, 0.12, 0.2, 0.62, 0x6a4a30)
	home()

# ---------------- the court ----------------
## a piece of the court's floor: flat, falling towards the avenue with the rest of it
func _floor(pts: PackedVector2Array, key, up := 0.0) -> void:
	pieces += 1
	var idx := Geometry2D.triangulate_polygon(pts)
	for t in range(0, idx.size(), 3):
		var a := pts[idx[t]]
		var b := pts[idx[t + 1]]
		var c := pts[idx[t + 2]]
		tri(Vector3(a.x, _cy(a) + up, a.y), Vector3(b.x, _cy(b) + up, b.y), Vector3(c.x, _cy(c) + up, c.y), key, Vector3.UP)

## a line painted on it, from a to b
func _line(a: Vector2, b: Vector2, wide := 0.07) -> void:
	var d: Vector2 = (b - a).normalized()
	var n := Vector2(-d.y, d.x) * wide / 2.0
	_floor(PackedVector2Array([a - n, b - n, b + n, a + n]), 0xf1efe6, 0.012)

func _court() -> void:
	var edge: Array = [Vector2(0.15, 0.0), Vector2(X1, 0.0), Vector2(X1, -OUTZ), Vector2(X2, -OUTZ), Vector2(X2, 0.0), Vector2(40.3, 0.0)]
	for i in range(FENCE.size() - 2, 0, -1):
		edge.append(FENCE[i])
	_floor(PackedVector2Array(edge), COURT)
	# the basket court painted on its east half: its lines, the circle in the middle, the two keys
	var c0 := Vector2(24.2, 2.6)
	var cw := 11.0
	var cl := 16.0
	for q in [[Vector2(0, 0), Vector2(cw, 0)], [Vector2(cw, 0), Vector2(cw, cl)], [Vector2(cw, cl), Vector2(0, cl)], [Vector2(0, cl), Vector2(0, 0)], [Vector2(0, cl / 2.0), Vector2(cw, cl / 2.0)]]:
		_line(c0 + q[0], c0 + q[1])
	for i in range(20):
		var a0: float = TAU * i / 20.0
		var a1: float = TAU * (i + 1) / 20.0
		_line(c0 + Vector2(cw / 2.0, cl / 2.0) + Vector2(cos(a0), sin(a0)) * 1.5, c0 + Vector2(cw / 2.0, cl / 2.0) + Vector2(cos(a1), sin(a1)) * 1.5)
	for e in [0.0, 1.0]:
		var zz: float = cl * e
		var s: float = 1.0 if e == 0.0 else -1.0
		for q in [[Vector2(cw / 2.0 - 1.8, zz), Vector2(cw / 2.0 - 1.8, zz + s * 4.6)], [Vector2(cw / 2.0 + 1.8, zz), Vector2(cw / 2.0 + 1.8, zz + s * 4.6)], [Vector2(cw / 2.0 - 1.8, zz + s * 4.6), Vector2(cw / 2.0 + 1.8, zz + s * 4.6)]]:
			_line(c0 + q[0], c0 + q[1])
		_hoop(c0 + Vector2(cw / 2.0, zz - s * 0.5), s)
	_hoop(Vector2(13.6, 0.9), 1.0)                  # and a hoop on its own before the west windows

## a basket hoop on its post: `s` = 1 looks towards the avenue, -1 towards the school
func _hoop(at: Vector2, s: float) -> void:
	var y: float = _cy(at)
	cbox(Vector3(at.x, y + 1.6, at.y), Vector3(0.1, 3.2, 0.1), 0x4a4d52)
	bar(Vector3(at.x, y + 3.1, at.y), Vector3(at.x, y + 3.25, at.y + s * 1.0), 0.08, 0.08, 0x4a4d52)
	cbox(Vector3(at.x, y + 3.35, at.y + s * 1.05), Vector3(1.5, 1.0, 0.04), 0xf4f4f0)
	cbox(Vector3(at.x, y + 3.2, at.y + s * 1.075), Vector3(0.55, 0.42, 0.01), 0x8a2c2a)
	cbox(Vector3(at.x, y + 3.2, at.y + s * 1.08), Vector3(0.45, 0.32, 0.012), 0xf4f4f0)
	for i in range(10):
		var a0: float = TAU * i / 10.0
		var a1: float = TAU * (i + 1) / 10.0
		bar(Vector3(at.x + cos(a0) * 0.23, y + 3.05, at.y + s * 1.32 + sin(a0) * 0.23), Vector3(at.x + cos(a1) * 0.23, y + 3.05, at.y + s * 1.32 + sin(a1) * 0.23), 0.025, 0.025, 0xd8521e)
	solid(Vector3(at.x, y + 1.5, at.y), Vector3(0.2, 3.0, 0.2))

# ---------------- its fence ----------------
## a stretch of wall from p to q (on the frame's floor plan), `thick` wide, from `low` up to t0 at p and t1 at q
func _wall_piece(p: Vector2, q: Vector2, thick: float, low: float, t0: float, t1: float, key) -> void:
	pieces += 1
	var d: Vector2 = (q - p).normalized()
	var n := Vector2(-d.y, d.x) * thick / 2.0
	var a := [p - n, q - n, q + n, p + n]
	for s in [[0, 1, -1.0], [3, 2, 1.0]]:           # its two faces
		var u0: Vector2 = a[s[0]]
		var u1: Vector2 = a[s[1]]
		quad(Vector3(u0.x, low, u0.y), Vector3(u1.x, low, u1.y), Vector3(u1.x, t1, u1.y), Vector3(u0.x, t0, u0.y), key, Vector3(n.x, 0, n.y).normalized() * float(s[2]))
	quad(Vector3(a[0].x, t0, a[0].y), Vector3(a[1].x, t1, a[1].y), Vector3(a[2].x, t1, a[2].y), Vector3(a[3].x, t0, a[3].y), key, Vector3.UP)
	quad(Vector3(a[0].x, low, a[0].y), Vector3(a[3].x, low, a[3].y), Vector3(a[3].x, t0, a[3].y), Vector3(a[0].x, t0, a[0].y), key, Vector3(-d.x, 0, -d.y))
	quad(Vector3(a[1].x, low, a[1].y), Vector3(a[2].x, low, a[2].y), Vector3(a[2].x, t1, a[2].y), Vector3(a[1].x, t1, a[1].y), key, Vector3(d.x, 0, d.y))

## A stretch of the fence from p to q: the low wall of brick under its coping, down to the ground outside, and the
## iron bars on it between their posts. `gate`: from where to where along it there is a gate instead, shut.
func _fence_run(p: Vector2, q: Vector2, gate := Vector2(-1.0, -1.0)) -> void:
	var ln: float = p.distance_to(q)
	var d: Vector2 = (q - p) / ln
	var n := int(ceil(ln / 2.4))
	var g_from := 1e9
	var g_to := -1e9
	for i in range(n):
		var t0: float = ln * i / n
		var t1: float = ln * (i + 1) / n
		var a: Vector2 = p + d * t0
		var b: Vector2 = p + d * t1
		var in_gate: bool = gate.x >= 0.0 and (t0 + t1) / 2.0 > gate.x and (t0 + t1) / 2.0 < gate.y
		var ya: float = _cy(a)
		var yb: float = _cy(b)
		var low: float = minf(minf(ground(a.x, a.y), ground(b.x, b.y)), minf(ya, yb)) - 0.6
		if in_gate:                                 # a leaf of the gate: taller bars in a frame, no wall under it
			_wall_piece(a, b, 0.2, low, ya + 0.04, yb + 0.04, "piedra")
			bar(Vector3(a.x, ya + 0.12, a.y), Vector3(b.x, yb + 0.12, b.y), 0.05, 0.05, BARS)
			bar(Vector3(a.x, ya + 2.25, a.y), Vector3(b.x, yb + 2.25, b.y), 0.05, 0.05, BARS)
			var gp := int((t1 - t0) / 0.13)
			for j in range(gp + 1):
				var g: Vector2 = a.lerp(b, float(j) / gp)
				cbox(Vector3(g.x, lerpf(ya, yb, float(j) / gp) + 1.18, g.y), Vector3(0.022, 2.14, 0.022), BARS)
		else:
			_wall_piece(a, b, 0.26, low, ya + 0.45, yb + 0.45, "ladrillo")
			_wall_piece(a, b, 0.34, ya + 0.45, ya + 0.52, yb + 0.52, 0xb98e68)
			bar(Vector3(a.x, ya + 0.62, a.y), Vector3(b.x, yb + 0.62, b.y), 0.035, 0.035, BARS)
			bar(Vector3(a.x, ya + 2.0, a.y), Vector3(b.x, yb + 2.0, b.y), 0.04, 0.04, BARS)
			var np := int((t1 - t0) / 0.13)
			for j in range(1, np):
				var g: Vector2 = a.lerp(b, float(j) / np)
				cbox(Vector3(g.x, lerpf(ya, yb, float(j) / np) + 1.27, g.y), Vector3(0.02, 1.5, 0.02), BARS)
			cbox(Vector3(a.x, ya + 1.27, a.y), Vector3(0.06, 1.56, 0.06), BARS)
		if in_gate:
			g_from = minf(g_from, t0)
			g_to = maxf(g_to, t1)
	if g_to > g_from:                           # the brick pier at each side of the gate, and steps down to the street if it stands over it
		_pier(p + d * g_from)
		_pier(p + d * g_to)
		var away := Vector2(-d.y, d.x)
		var g0: Vector2 = p + d * (g_from + 0.3)
		var g1: Vector2 = p + d * (g_to - 0.3)
		var top: float = minf(_cy(g0), _cy(g1))
		var drop: float = top - minf(ground((g0 + away * 0.8).x, (g0 + away * 0.8).y), ground((g1 + away * 0.8).x, (g1 + away * 0.8).y))
		var steps: int = clampi(int(ceil(drop / 0.19)), 0, 5) if drop > 0.2 else 0
		for k in range(steps):
			var run: float = 0.28 * (steps - k)
			var ring: Array = [g0 + away * 0.1, g1 + away * 0.1, g1 + away * (0.1 + run), g0 + away * (0.1 + run)]
			_step(ring, top - drop - 0.5, top - drop * float(k) / steps - drop / steps)
			if k == 0:
				yard.append(spot(ring[2].x, ring[2].y))
				yard.append(spot(ring[3].x, ring[3].y))
		var gm: Vector2 = p + d * (g_from + g_to) / 2.0
		gates.append(spot(gm.x, gm.y))
	var mid: Vector2 = (p + q) / 2.0
	solid(Vector3(mid.x, _cy(mid) + 0.4, mid.y), Vector3(ln, 4.2, 0.3), atan2(-d.y, d.x))

## a block of stone on this outline (x, z) from y0 up to y1: a step
func _step(pts: Array, y0: float, y1: float) -> void:
	pieces += 1
	quad(Vector3(pts[0].x, y1, pts[0].y), Vector3(pts[1].x, y1, pts[1].y), Vector3(pts[2].x, y1, pts[2].y), Vector3(pts[3].x, y1, pts[3].y), "piedra", Vector3.UP)
	for i in range(4):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % 4]
		var e: Vector2 = (b - a).normalized()
		var mid := Vector2.ZERO
		for q: Vector2 in pts:
			mid += q / 4.0
		var nn := Vector2(e.y, -e.x)
		if nn.dot((a + b) / 2.0 - mid) < 0.0:
			nn = -nn
		quad(Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y), "piedra", Vector3(nn.x, 0, nn.y))

## a pier of brick with its cap of stone
func _pier(at: Vector2) -> void:
	var y: float = _cy(at)
	var low: float = minf(ground(at.x, at.y), y) - 0.6
	cbox(Vector3(at.x, (low + y + 2.5) / 2.0, at.y), Vector3(0.52, y + 2.5 - low, 0.52), "ladrillo")
	cbox(Vector3(at.x, y + 2.55, at.y), Vector3(0.62, 0.1, 0.62), "piedra")

func _fence() -> void:
	_fence_run(FENCE[0], FENCE[1], GATE_W)
	_fence_run(FENCE[1], FENCE[2])
	_fence_run(FENCE[2], FENCE[3])
	_fence_run(FENCE[3], FENCE[4], GATE_E)
	_fence_run(FENCE[4], FENCE[5])
	for q: Vector2 in FENCE:
		yard.append(spot(q.x, q.y))

# ---------------- what stands in the court ----------------
## a tree of the court: its trunk forking, a round crown
func _tree(at: Vector2, tall: float) -> void:
	var y: float = _cy(at)
	var crown: float = tall * 0.23
	drum(Vector3(at.x, y - 0.3, at.y), 0.28, 0.2, tall * 0.5, 0x6b5a45, 8)
	bar(Vector3(at.x, y + tall * 0.4, at.y), Vector3(at.x + crown * 0.5, y + tall * 0.62, at.y - crown * 0.2), 0.16, 0.16, 0x6b5a45)
	bar(Vector3(at.x, y + tall * 0.4, at.y), Vector3(at.x - crown * 0.45, y + tall * 0.64, at.y + crown * 0.25), 0.16, 0.16, 0x6b5a45)
	ball(Vector3(at.x, y + tall * 0.74, at.y), crown, "leaf", 0.88, 10, 6)
	ball(Vector3(at.x + crown * 0.62, y + tall * 0.62, at.y - crown * 0.3), crown * 0.72, "leaf", 0.88, 9, 5)
	ball(Vector3(at.x - crown * 0.58, y + tall * 0.64, at.y + crown * 0.3), crown * 0.7, "leaf", 0.88, 9, 5)
	cbox(Vector3(at.x, y + 0.01, at.y), Vector3(1.2, 0.03, 1.2), 0x6a5a48)                # the square of earth it grows in
	solid(Vector3(at.x, y + 1.2, at.y), Vector3(0.5, 2.6, 0.5))
	yard.append(spot(at.x, at.y))
	trees += 1

## a floodlight on its tall post
func _flood(at: Vector2) -> void:
	var y: float = _cy(at)
	cbox(Vector3(at.x, y + 4.4, at.y), Vector3(0.12, 8.8, 0.12), 0x5a5d60)
	cbox(Vector3(at.x, y + 8.95, at.y - 0.12), Vector3(0.6, 0.42, 0.4), 0x2a2c30)
	cbox(Vector3(at.x, y + 8.92, at.y - 0.33), Vector3(0.5, 0.32, 0.02), 0xd9dde0)
	solid(Vector3(at.x, y + 1.5, at.y), Vector3(0.24, 3.0, 0.24))
	yard.append(spot(at.x, at.y))

## A floor laid on the ground itself, following it: this outline (x, z), cut small enough to lie on the map's relief.
func _drape(pts: PackedVector2Array, key, lift := 0.05) -> void:
	pieces += 1
	var idx := Geometry2D.triangulate_polygon(pts)
	var todo: Array = []
	for t in range(0, idx.size(), 3):
		todo.append([pts[idx[t]], pts[idx[t + 1]], pts[idx[t + 2]]])
	while not todo.is_empty():
		var tr: Array = todo.pop_back()
		var a: Vector2 = tr[0]
		var b: Vector2 = tr[1]
		var c: Vector2 = tr[2]
		var ab: float = a.distance_to(b)
		var bc: float = b.distance_to(c)
		var ca: float = c.distance_to(a)
		if maxf(ab, maxf(bc, ca)) > 2.4:              # halve its longest side
			if ab >= bc and ab >= ca:
				todo.append([a, (a + b) / 2.0, c])
				todo.append([(a + b) / 2.0, b, c])
			elif bc >= ca:
				todo.append([a, b, (b + c) / 2.0])
				todo.append([a, (b + c) / 2.0, c])
			else:
				todo.append([a, b, (c + a) / 2.0])
				todo.append([(c + a) / 2.0, b, c])
			continue
		tri(Vector3(a.x, ground(a.x, a.y) + lift, a.y), Vector3(b.x, ground(b.x, b.y) + lift, b.y), Vector3(c.x, ground(c.x, c.y) + lift, c.y), key, Vector3.UP)

## The bus shelter on the avenue's pavement, white and blue: a white roof with its fascia to the street and the
## words "La Mancha" on it in blue, in its middle, blue posts, a white back with its notices, a poster stuck on askew
## and what has been scribbled on it, a white screen at each end, a blue bench. `at`: the middle of its back; `turn`:
## about y.
func _shelter(at: Vector2, turn: float) -> void:
	var blue := 0x1f3f9a
	var white := 0xf1f0ea
	var b := Basis(Vector3.UP, turn)
	var g := -99.0
	for c in [Vector3(-2.0, 0, 0), Vector3(2.0, 0, 0), Vector3(-2.0, 0, 1.45), Vector3(2.0, 0, 1.45)]:
		var q: Vector3 = b * c
		g = maxf(g, ground(at.x + q.x, at.y + q.z))
	g += 0.06
	var keep := _xf
	_xf = keep * Transform3D(b, Vector3(at.x, g, at.y))
	for x in [-1.97, 1.97]:
		box(x - 0.04, -0.7, 1.37, 0.08, 3.1, 0.08, blue)                              # its posts: the two at the front, the two at the back
		box(x - 0.035, -0.7, 0.0, 0.07, 3.0, 0.07, blue)
	box(-2.2, 2.4, -0.15, 4.4, 0.07, 1.78, white)                                   # the roof and its fascia
	box(-2.22, 2.18, 1.57, 4.44, 0.36, 0.06, white)
	for x in [-2.22, 2.16]:
		box(x, 2.18, -0.15, 0.06, 0.36, 1.72, white)
	box(-2.22, 2.18, -0.15, 4.44, 0.36, 0.05, white)
	var name := _text("La Mancha", Vector3(0.0, 2.36, 1.635), 64, blue, 0.004)
	name.outline_size = 12
	name.outline_modulate = Parts.col(blue)
	box(-1.93, 0.32, 0.02, 3.86, 1.84, 0.03, white)                                 # the back
	box(-1.955, 0.32, 0.05, 0.03, 1.84, 0.78, white)                                # the screens at its ends
	box(1.925, 0.32, 0.05, 0.03, 1.84, 0.42, white)
	for y in [0.62, 1.02]:                          # the rails of the west screen
		box(-2.0, y, 0.83, 0.05, 0.05, 0.55, blue)
	box(-2.0, 0.62, 0.83, 0.05, 0.45, 0.05, blue)
	box(-1.5, 1.72, 0.052, 0.2, 0.3, 0.004, 0xdfe6ee)                               # two notices stuck on it
	box(-1.46, 1.84, 0.057, 0.12, 0.1, 0.003, 0x3a6ab0)
	box(-0.82, 1.5, 0.052, 0.3, 0.42, 0.004, 0xe6dcd8)
	box(-0.79, 1.68, 0.057, 0.24, 0.1, 0.003, 0xb8322e)
	box(-0.79, 1.56, 0.057, 0.24, 0.05, 0.003, 0x4a4a52)
	for q in [[-0.5, 1.2, -0.1, 1.32], [-0.1, 1.32, 0.2, 1.22], [-0.45, 1.08, 0.15, 1.12], [-1.3, 0.95, -0.9, 1.05], [-1.25, 0.82, -0.95, 0.8],
			[1.2, 1.7, 1.55, 1.78], [1.25, 1.02, 1.6, 0.94], [0.15, 1.75, 0.4, 1.9], [0.4, 1.9, 0.55, 1.74], [-0.2, 0.7, 0.3, 0.74]]:      # what has been scribbled on it
		bar(Vector3(q[0], q[1], 0.055), Vector3(q[2], q[3], 0.055), 0.004, 0.016, 0x7a808c)
	if Parts.texture(POSTER) != null:               # the poster, stuck on the back askew with two bits of tape
		poster = true
		var inner := _xf
		_xf = inner * Transform3D(Basis(Vector3(0, 0, 1), 0.16), Vector3(0.8, 1.36, 0.058))
		var pw := 0.46
		var ph: float = pw * 414.0 / 314.0
		quad(Vector3(-pw / 2.0, -ph / 2.0, 0), Vector3(pw / 2.0, -ph / 2.0, 0), Vector3(pw / 2.0, ph / 2.0, 0), Vector3(-pw / 2.0, ph / 2.0, 0), "cartel", Vector3(0, 0, 1),
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
		for sx in [-1.0, 1.0]:
			tbox(Transform3D(Basis(Vector3(0, 0, 1), sx * 0.6).scaled_local(Vector3(0.09, 0.028, 0.002)), Vector3(sx * (pw / 2.0 - 0.012), ph / 2.0 - 0.006, 0.002)), 0xe6dfc4)
		_xf = inner
	box(0.1, 0.42, 0.14, 1.75, 0.05, 0.36, blue)                                    # the bench, on its two legs
	for x in [0.32, 1.6]:
		box(x, -0.7, 0.28, 0.05, 1.12, 0.05, blue)
	_xf = keep
	solid(Vector3(at.x, g + 1.2, at.y), Vector3(4.0, 2.6, 0.14), turn)
	var bench: Vector3 = b * Vector3(0.97, 0, 0.32)
	solid(Vector3(at.x + bench.x, g + 0.25, at.y + bench.z), Vector3(1.8, 0.9, 0.4), turn)
	for x in [-1.97, 1.97]:
		var post: Vector3 = b * Vector3(x, 0, 1.41)
		solid(Vector3(at.x + post.x, g + 1.2, at.y + post.z), Vector3(0.14, 2.6, 0.14))
		var corner: Vector3 = b * Vector3(x * 1.13, 0, 1.65)
		yard.append(spot(at.x + corner.x, at.y + corner.z))
	shelter = spot(at.x, at.y)

func _things() -> void:
	var paved := PackedVector2Array([Vector2(-1.2, 18.8), Vector2(35.05, 22.75), Vector2(36.9, 21.5), Vector2(34.6, 27.3), Vector2(-1.4, 24.6)])      # (its east end keeps clear of the game's Calle de Santa Clara, which swings in towards the corner)
	_drape(paved, "damero")
	for q in [paved[0], paved[2], paved[3], paved[4]]:
		yard.append(spot(q.x, q.y))
	_shelter(Vector2(15.8, 24.0), -atan2(paved[3].y - paved[4].y, paved[3].x - paved[4].x))      # (before the door, its back to the school, as in the pictures of 2013)
	for q in [Vector2(3.0, 17.0), Vector2(9.5, 18.0), Vector2(17.5, 18.9), Vector2(25.5, 19.7), Vector2(32.0, 20.4)]:      # the row of trees along the avenue
		_tree(q, 9.0 + fmod(q.x, 1.4))
	for q in [Vector2(2.2, 7.5), Vector2(38.5, 7.6), Vector2(38.0, 11.6)]:              # and those by the two side streets
		_tree(q, 7.5 + fmod(q.x, 1.2))
	var along: Vector2 = ((FENCE[2] as Vector2) - FENCE[1]).normalized()
	for x in [6.0, 13.5, 21.5, 29.0]:               # the floodlights: against the fence of the avenue, between the trees, looking over the court
		var t: float = (x - (FENCE[1] as Vector2).x) / along.x
		_flood((FENCE[1] as Vector2) + along * t + Vector2(along.y, -along.x) * 0.32)
	# the tall mesh that stops the balls, along each side street: posts and a net of wire
	for run in [[Vector2(0.55, 1.0), Vector2(0.7, 10.6)], [Vector2(39.9, 1.0), Vector2(39.3, 9.3)]]:
		var a: Vector2 = run[0]
		var b: Vector2 = run[1]
		var ln: float = a.distance_to(b)
		var n := int(ln / 2.4)
		for i in range(n + 1):
			var g: Vector2 = a.lerp(b, float(i) / n)
			cbox(Vector3(g.x, _cy(g) + 2.6, g.y), Vector3(0.06, 5.2, 0.06), 0x3a3d40)
		var wires := int(ln / 0.4)
		for i in range(wires + 1):
			var g: Vector2 = a.lerp(b, float(i) / wires)
			cbox(Vector3(g.x, _cy(g) + 3.6, g.y), Vector3(0.012, 3.2, 0.012), 0x4a4d52)
		for j in range(9):
			bar(Vector3(a.x, _cy(a) + 2.0 + j * 0.4, a.y), Vector3(b.x, _cy(b) + 2.0 + j * 0.4, b.y), 0.012, 0.012, 0x4a4d52)
