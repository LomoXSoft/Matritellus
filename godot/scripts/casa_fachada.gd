extends "res://scripts/obra.gd"
## One of the six fronts of the house you inherit, Calle de Alemania 5 (casa_fuera.gd keeps the six and shows one). The
## user, 21 November 2026, through Sistemas, for the missions of the house: the house goes from a wreck to a house of
## two floors as you pay for the works, and "cada ampliación mejora también la fachada; la final le añade el segundo
## piso". Catastro has the plot as bare ground: the house is made up, and so are its works.
##
##   0  as you inherit it: old lime coming away from the adobe, a worn foot, an old door, a window behind its blind, the
##      corral's gate of grey planks, and a roof that is there in places;
##   1  done up: the same house whitewashed, its foot painted, the door and the window green, a grille, the gate
##      mended, the roof whole, a lantern by the door, a geranium on the sill;
##   2  the first enlargement: the indigo skirting of La Mancha, the openings framed in white (the gate too, of two
##      leaves now), more pots;
##   3  a room more on the left: a little barred window at that end, a bench of masonry by the door, a second lantern;
##   4  a room more on the right: a new barred window between the old one and the gate, which is a garage door now in
##      a frame of brick under its own little roof of tiles, and a cornice of brick under the eaves. (The brick round
##      the gate came with state 2 at first and went with the garage; the user wanted the contrary: "añádela en la 4
##      y mantenla en la 5". The eaves' cornice came with state 2 too; it is from 4 in the pictures he approved.)
##   5  the upper floor: three balconies behind their iron rails, the indigo band under the eaves, the cornice still, a
##      chimney, and more pots (no climber and not too many flowers: the user's word).
## The street door never moves (2.14 m along the front, 1.0 x 2.1): game.gd's HOME_DOOR, the Padrón's tile over it,
## the green arrow before it and your peña's graffiti over its lintel all hang on it.
##
## Frame: origin at the front's left end as seen from the street, +x along the front, +z out of it; y = 0 the pavement.

const FRONT := 10.7                 # the front (the plot's, from the map)
const DEEP_PLOT := 7.0              # how deep the plot is
const EAVES := 3.5                  # the eaves of the house as inherited
const UPPER := 6.5                  # ...with its upper floor
const DOOR := Rect2(1.64, 0.0, 1.0, 2.1)
const WIN := Rect2(3.4, 1.15, 0.9, 1.0)
const GATE := Rect2(6.52, 0.0, 2.8, 2.5)
const WIN_L := Rect2(0.45, 1.25, 0.7, 0.9)          # (state 3 on)
const WIN_R := Rect2(4.9, 1.15, 0.9, 1.0)           # (state 4 on)
const GARAGE := Rect2(6.72, 0.0, 2.6, 2.4)          # (state 4 on: the gate's place)
const ANIL := 0.9                   # how high the indigo skirting goes

var state := 0
var top := EAVES
var lanterns: Array = []            # where its lanterns hang, in the world (casa_fuera.gd gives the town's lights the shown front's)

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"cal_vieja":        # old lime, yellowed and dirty
			m = Tex.mat("painted_plaster_wall", Color(0.9, 0.85, 0.74))
		"adobe":            # where it has come away: the mud wall
			m = W._tmat(0xa8845a, "earth", 1.1)
		"anil":             # the indigo of the skirtings
			m = Tex.mat("painted_plaster_wall", Color(0.3, 0.46, 0.95))
		"zocalo_viejo":
			m = Tex.mat("granular_concrete", Color(0.86, 0.8, 0.7))
		"zocalo":
			m = Tex.mat("granular_concrete", Color(0.72, 0.72, 0.7))
		"madera_vieja":     # grey planks, years in the sun
			m = Tex.mat("old_planks_02", Color(0.62, 0.56, 0.5))
		"madera":           # mended and oiled
			m = Tex.mat("old_planks_02", Color(0.56, 0.36, 0.2))
		"ladrillo":
			m = Tex.mat("medieval_red_brick", Color(1.0, 0.92, 0.86))
		"hueco":            # the dark under a hole in the roof
			var hm := StandardMaterial3D.new()
			hm.albedo_color = Color(0.09, 0.08, 0.07)
			m = hm
		"farol":            # a lantern's glass
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

func build(world, hd: Dictionary, which: int) -> void:
	W = world
	state = which
	top = UPPER if state >= 5 else EAVES
	var o := Vector2(hd["o"][0], hd["o"][1])
	var u := Vector2(hd["u"][0], hd["u"][1]).normalized()
	var out := Vector2(-u.y, u.x)
	level = float(hd.get("base", MapData.height(o + u * (FRONT / 2.0) + out * 1.0)))
	transform = Transform3D(Basis(Vector3(u.x, 0, u.y), Vector3.UP, Vector3(out.x, 0, out.y)), Vector3(o.x, level, o.y))
	W.add_child(self)
	_front()
	_body()
	_roof()
	home()
	_commit()
	_prism([Vector2(0, 0), Vector2(FRONT, 0), Vector2(FRONT, -DEEP_PLOT), Vector2(0, -DEEP_PLOT)], -2.0, top)

## the openings of the front in this state: [rect, what]
func openings() -> Array:
	var out: Array = [[DOOR, "door"], [WIN, "win"]]
	if state >= 3:
		out.append([WIN_L, "win"])
	if state >= 4:
		out.append([WIN_R, "win"])
		out.append([GARAGE, "garage"])
	else:
		out.append([GATE, "gate"])
	return out

# ---------------- the front ----------------
func _front() -> void:
	var old := state == 0
	var wall = "cal_vieja" if old else "white"
	var holes: Array = []
	for op in openings():
		holes.append(op[0])
	var ups: Array = []                             # the balconies' doors, upstairs
	if state >= 5:
		for cx in [2.14, 5.35, 8.4]:
			ups.append(Rect2(cx - 0.55, EAVES + 0.25, 1.1, 2.1))
		holes.append_array(ups)
	masonry(0.0, FRONT, -1.0, top, holes, [], wall, wall)
	for h: Rect2 in holes:                           # the depth of each opening: its cheeks, its head, its sill
		for x in [h.position.x, h.end.x]:
			quad(Vector3(x, h.position.y, 0), Vector3(x, h.position.y, -DEEP), Vector3(x, h.end.y, -DEEP), Vector3(x, h.end.y, 0), wall, Vector3(1 if x == h.position.x else -1, 0, 0))
		quad(Vector3(h.position.x, h.end.y, 0), Vector3(h.end.x, h.end.y, 0), Vector3(h.end.x, h.end.y, -DEEP), Vector3(h.position.x, h.end.y, -DEEP), wall, Vector3.DOWN)
		if h.position.y > 0.01:
			quad(Vector3(h.position.x, h.position.y, 0), Vector3(h.end.x, h.position.y, 0), Vector3(h.end.x, h.position.y, -DEEP), Vector3(h.position.x, h.position.y, -DEEP), wall, Vector3.UP)
	# the foot of the wall: worn, painted grey, or the indigo skirting; cut at what reaches the ground
	var foot_h := 0.55 if state < 2 else ANIL
	var foot = "zocalo_viejo" if old else ("zocalo" if state < 2 else "anil")
	var cuts: Array = [0.0]
	var doors: Array = []
	for op in openings():
		var r: Rect2 = op[0]
		if r.position.y < 0.01:
			doors.append(r)
	doors.sort_custom(func(a, b): return (a as Rect2).position.x < (b as Rect2).position.x)
	for r: Rect2 in doors:
		cuts.append(r.position.x)
		cuts.append(r.end.x)
	cuts.append(FRONT)
	for i in range(0, cuts.size(), 2):
		box(float(cuts[i]), -1.0, 0.0, float(cuts[i + 1]) - float(cuts[i]), 1.0 + foot_h, 0.03, foot)
	if state >= 2:                                   # a thin white line over the indigo
		for i in range(0, cuts.size(), 2):
			box(float(cuts[i]), ANIL, 0.0, float(cuts[i + 1]) - float(cuts[i]), 0.035, 0.035, 0xf4f1ea)
	if old:
		_wear()
	for op in openings():
		var r: Rect2 = op[0]
		match String(op[1]):
			"door":
				_door(r)
			"win":
				_window(r)
			"gate":
				_gate(r)
			"garage":
				_garage(r)
	for r: Rect2 in ups:
		_balcony(r)
	if state >= 1:
		_lantern(DOOR.end.x + 0.45)
	if state >= 3:
		_lantern(GATE.position.x - 0.5)
		box(DOOR.end.x + 0.15, 0.0, 0.0, 0.6, 0.42, 0.38, "white")          # the bench of masonry by the door
		box(DOOR.end.x + 0.13, 0.42, 0.0, 0.64, 0.04, 0.4, 0xb5653f)
	if state >= 5:
		_plants(ups)
	elif state >= 2:
		for x in ([0.9, 5.0, 5.6] if state < 4 else [9.9, 10.32]):
			_pot(Vector3(x, 0.0, 0.3), 0.16, state)
	# the eaves: bare tiles, or from the fourth state a cornice of brick under them (approved so by the user)
	if state >= 4:
		box(0.0, top - 0.24, 0.0, FRONT, 0.08, 0.06, "ladrillo")
		box(0.0, top - 0.16, 0.0, FRONT, 0.08, 0.12, "ladrillo")
		box(0.0, top - 0.08, 0.0, FRONT, 0.08, 0.18, "ladrillo")
	if state >= 5:                                   # the indigo again, a band under the upper floor
		box(0.0, EAVES - 0.1, 0.0, FRONT, 0.22, 0.04, "anil")

## what the years have done to the front as you inherit it: the lime gone in patches down to the adobe, a crack, damp
func _wear() -> void:
	for p in [[0.2, 0.7, 1.1, 0.9], [2.9, 0.6, 0.5, 0.5], [4.6, 0.75, 1.4, 1.5], [5.4, 2.4, 0.8, 0.7], [9.5, 0.6, 1.0, 1.3], [0.5, 2.5, 0.9, 0.6], [9.6, 2.6, 0.7, 0.5]]:
		box(float(p[0]), float(p[1]), 0.0, float(p[2]), float(p[3]), 0.012, "adobe")
		box(float(p[0]) + 0.1, float(p[1]) + float(p[3]), 0.0, float(p[2]) * 0.5, 0.12, 0.012, "adobe")
	for k in range(6):                               # a crack down from the eaves
		bar(Vector3(4.55 + 0.06 * (k % 2), 3.3 - k * 0.3, 0.014), Vector3(4.55 + 0.06 * ((k + 1) % 2), 3.0 - k * 0.3, 0.014), 0.025, 0.01, 0x4a4036)
	box(0.0, 0.55, 0.0, FRONT * 0.3, 0.2, 0.008, 0xb8a888)                           # the damp over the foot

func _door(r: Rect2) -> void:
	var old := state == 0
	var leaf = "madera_vieja" if old else 0x2f5a3a
	if state >= 2:                                   # a white surround, raised
		for x in [r.position.x - 0.16, r.end.x]:
			box(x, 0.0, 0.0, 0.16, r.size.y + 0.16, 0.04, 0xf4f1ea)
		box(r.position.x - 0.16, r.size.y, 0.0, r.size.x + 0.32, 0.16, 0.04, 0xf4f1ea)
	box(r.position.x, 0.0, -DEEP + 0.04, r.size.x, r.size.y, 0.06, leaf)
	for k in range(1, 4):
		box(r.position.x + r.size.x * k / 4.0 - 0.006, 0.05, -DEEP + 0.1, 0.012, r.size.y - 0.1, 0.006, 0x2a2018 if old else 0x1f3f28)
	box(r.end.x - 0.2, 1.0, -DEEP + 0.1, 0.05, 0.14, 0.05, 0x26262a if old else 0xc9a23a)       # the latch, or a knob of brass
	box(r.position.x - 0.05, 0.0, -0.03, r.size.x + 0.1, 0.06, 0.2, 0x9a948a)                    # the step
	if old:
		box(r.position.x + 0.05, 0.02, -DEEP + 0.1, r.size.x - 0.1, 0.25, 0.01, 0x8a7a66)       # (its foot, rotted pale)

func _window(r: Rect2) -> void:
	var old := state == 0
	var frame := 0x5a3a22 if old else 0x2f5a3a
	if state >= 2:
		stone_frame(r, 0.13, 0.04, 0xf4f1ea)
	window(r, frame, 0x1f2a33, 1)
	if old:                                          # its blind, half down and hanging askew
		box(r.position.x + 0.06, r.position.y + r.size.y * 0.45, -DEEP + 0.1, r.size.x - 0.12, r.size.y * 0.5, 0.02, 0x6a5a48)
	else:
		grille(r.grow(0.06), 0.16, 0x26262a)
		box(r.position.x - 0.1, r.position.y - 0.07, 0.0, r.size.x + 0.2, 0.07, 0.2, 0xd8d2c4)   # the sill
		_pot(Vector3(r.position.x + r.size.x / 2.0, r.position.y, 0.09), 0.1, state)

## the corral's gate: grey planks hanging tired on their hinges, then mended and oiled, then a gate of two leaves
## framed in white like the door and the window
func _gate(r: Rect2) -> void:
	var old := state == 0
	var key = "madera_vieja" if old else "madera"
	if state >= 2:
		stone_frame(r, 0.15, 0.04, 0xf4f1ea)
	var keep := _xf
	if old:                                          # (hanging a little out of true)
		_xf = _xf * Transform3D(Basis(Vector3(0, 0, 1), -0.02), Vector3(0.0, 0.05, 0.0))
	box(r.position.x, 0.06, -DEEP + 0.06, r.size.x, r.size.y - 0.08, 0.06, key)
	var n := 9
	for k in range(1, n):
		box(r.position.x + r.size.x * k / n - 0.008, 0.08, -DEEP + 0.12, 0.016, r.size.y - 0.12, 0.006, 0x3a3028)
	if state >= 2:
		box(r.position.x + r.size.x / 2.0 - 0.02, 0.06, -DEEP + 0.12, 0.04, r.size.y - 0.08, 0.02, 0x3a2a1e)      # (where its two leaves meet)
	for y in [0.5, r.size.y - 0.55]:                 # its cross-bars, or its straps of iron
		box(r.position.x + 0.05, y, -DEEP + 0.12, r.size.x - 0.1, 0.12 if old else 0.06, 0.03, key if old else 0x26262a)
	if old:
		bar(Vector3(r.position.x + 0.1, 0.55, -DEEP + 0.14), Vector3(r.end.x - 0.1, r.size.y - 0.5, -DEEP + 0.14), 0.03, 0.1, key)
	_xf = keep

## the garage's door, from the fourth state: in a frame of brick under its own little roof of tiles
func _garage(r: Rect2) -> void:
	for x in [r.position.x - 0.3, r.end.x]:
		box(x, 0.0, 0.0, 0.3, r.size.y + 0.25, 0.06, "ladrillo")
	box(r.position.x - 0.3, r.size.y, 0.0, r.size.x + 0.6, 0.25, 0.06, "ladrillo")
	roof([Vector3(r.position.x - 0.45, r.size.y + 0.62, 0.0), Vector3(r.end.x + 0.45, r.size.y + 0.62, 0.0), Vector3(r.end.x + 0.45, r.size.y + 0.36, 0.55), Vector3(r.position.x - 0.45, r.size.y + 0.36, 0.55)])
	box(r.position.x - 0.45, r.size.y + 0.25, 0.0, r.size.x + 0.9, 0.1, 0.5, 0x7a5232)
	box(r.position.x, 0.0, -DEEP + 0.06, r.size.x, r.size.y, 0.05, 0x6a4628)
	for k in range(1, 6):
		box(r.position.x, r.size.y * k / 6.0 - 0.01, -DEEP + 0.11, r.size.x, 0.02, 0.008, 0x4a3020)
	box(r.position.x + r.size.x / 2.0 - 0.08, 0.9, -DEEP + 0.11, 0.16, 0.05, 0.04, 0x26262a)
	box(r.position.x - 0.05, 0.0, -0.03, r.size.x + 0.1, 0.04, 0.25, 0x9a948a)

## a balcony upstairs: its glazed door, a slab on two brackets, an iron rail
func _balcony(r: Rect2) -> void:
	stone_frame(r, 0.13, 0.04, 0xf4f1ea)
	window(r, 0x2f5a3a, 0x1f2a33, 2)
	var x0 := r.position.x - 0.35
	var w := r.size.x + 0.7
	var y := r.position.y - 0.12
	box(x0, y, 0.0, w, 0.12, 0.55, 0xd8d2c4)
	for x in [x0 + 0.1, x0 + w - 0.18]:
		box(x, y - 0.2, 0.0, 0.08, 0.2, 0.3, 0xd8d2c4)
	var n := int(w / 0.11)
	for i in range(n + 1):
		box(x0 + i * w / n - 0.008, y + 0.12, 0.52, 0.016, 0.9, 0.016, 0x26262a)
	for z in [0.0, 0.26]:
		for sx in [x0, x0 + w - 0.016]:
			box(sx, y + 0.12, z + 0.02, 0.016, 0.9, 0.016, 0x26262a)
	box(x0, y + 1.0, 0.5, w, 0.035, 0.04, 0x26262a)
	for sx in [x0, x0 + w - 0.03]:
		box(sx, y + 1.0, 0.0, 0.03, 0.035, 0.54, 0x26262a)
	_pot(Vector3(r.position.x + 0.1, y + 0.12, 0.38), 0.11, 5)

## a lantern on its bracket by a door
func _lantern(x: float) -> void:
	box(x - 0.02, 2.3, 0.0, 0.04, 0.04, 0.28, 0x26262a)
	box(x - 0.09, 2.02, 0.2, 0.18, 0.28, 0.18, "farol")
	box(x - 0.11, 2.3, 0.18, 0.22, 0.03, 0.22, 0x26262a)
	box(x - 0.11, 1.99, 0.18, 0.22, 0.03, 0.22, 0x26262a)
	lanterns.append(transform * Vector3(x, 2.15, 0.3))

## a pot of clay with its geranium
func _pot(at: Vector3, r: float, seed_: int) -> void:
	drum(at, r * 0.7, r, r * 1.3, 0xb0623a, 8)
	ball(at + Vector3(0, r * 1.9, 0), r * 1.25, 0x3f7a3a, 0.8, 7, 4)
	for k in range(3):
		var a := TAU * k / 3.0 + seed_
		ball(at + Vector3(cos(a) * r * 0.7, r * 2.5, sin(a) * r * 0.7), r * 0.42, 0xd8324a if (k + seed_) % 2 == 0 else 0xe86a8a, 0.8, 6, 3)

## a big pot with a green plant and no flowers: the aspidistra of every doorway
func _shrub(at: Vector3, r: float) -> void:
	drum(at, r * 0.72, r, r * 1.5, 0xb0623a, 10)
	ball(at + Vector3(0, r * 2.6, 0), r * 1.25, 0x2f6a32, 1.35, 7, 4)
	for k in range(4):
		var a := TAU * k / 4.0 + 0.6
		ball(at + Vector3(cos(a) * r * 0.9, r * 2.2, sin(a) * r * 0.9), r * 0.7, 0x3f7a3a, 1.2, 6, 3)

## the plants of the last state: two pots hung outside each balcony's rail and one on the wall between each two
## balconies, a few along the foot of the front, one on the bench and two big green ones. None of it is solid.
## (It had a bougainvillea up its right end and half as many pots again: too many flowers, the user said.)
func _plants(ups: Array) -> void:
	for r: Rect2 in ups:                             # hung outside each balcony's rail, in their rings of iron
		var x0 := r.position.x - 0.35
		var w := r.size.x + 0.7
		var y := r.position.y + 0.36
		for k in range(2):
			var x := x0 + w * (0.3 + 0.4 * k)
			box(x - 0.1, y + 0.1, 0.5, 0.2, 0.014, 0.16, 0x26262a)
			_pot(Vector3(x, y, 0.65), 0.09, k + int(r.position.x))
	for cx in [3.75, 6.88]:                          # one on the wall between each two balconies
		var at := Vector3(cx, EAVES + 1.25, 0.11)
		box(at.x - 0.11, at.y + 0.1, 0.0, 0.22, 0.014, 0.2, 0x26262a)
		_pot(at, 0.1, int(cx))
	for q in [[1.12, 0.14], [5.12, 0.17], [5.62, 0.13], [9.9, 0.16], [10.32, 0.16]]:     # along the foot of the front
		_pot(Vector3(q[0], 0.0, 0.12 + q[1] * 1.3), q[1], int(q[0] * 7.0))
	_pot(Vector3(3.2, 0.46, 0.2), 0.11, 2)           # one on the bench
	for q in [[0.4, 0.2], [6.1, 0.18]]:
		_shrub(Vector3(q[0], 0.0, 0.34), q[1])

# ---------------- the rest of it ----------------
## its sides and its back: plain, whitewashed or left as they were
func _body() -> void:
	var key = "cal_vieja" if state == 0 else "white"
	var ring: Array = [Vector2(0, 0), Vector2(0, -DEEP_PLOT), Vector2(FRONT, -DEEP_PLOT), Vector2(FRONT, 0)]
	for i in range(3):
		_plain(ring[i], ring[i + 1], -3.0, top, key)
		_plain(ring[i + 1], ring[i], -3.0, top, key)
	home()

## The roof: tiles from the eaves up to a ridge and down to the back. As you inherit it, there in places: stretches of
## it gone, the rafters bare over the dark. With the upper floor, a chimney.
func _roof() -> void:
	var ridge := top + 1.35
	var mid := -DEEP_PLOT / 2.0
	var gone: Array = [2, 5, 6] if state == 0 else []
	var n := 9
	for i in range(n):
		var x0 := -0.15 + (FRONT + 0.3) * i / n
		var x1 := -0.15 + (FRONT + 0.3) * (i + 1) / n
		if i in gone:
			quad(Vector3(x0, top - 0.05, 0.0), Vector3(x1, top - 0.05, 0.0), Vector3(x1, top - 0.05, mid), Vector3(x0, top - 0.05, mid), "hueco", Vector3.UP)
			for k in range(3):                       # (its rafters, bare)
				var xr := lerpf(x0, x1, (k + 0.5) / 3.0)
				bar(Vector3(xr, top + 0.02, 0.2), Vector3(xr, ridge - 0.05, mid), 0.07, 0.09, 0x5a4a3a)
		else:
			roof([Vector3(x0, top, 0.3), Vector3(x1, top, 0.3), Vector3(x1, ridge, mid), Vector3(x0, ridge, mid)])
		roof([Vector3(x0, ridge, mid), Vector3(x1, ridge, mid), Vector3(x1, top, -DEEP_PLOT - 0.2), Vector3(x0, top, -DEEP_PLOT - 0.2)])
	for x in [0.0, FRONT]:                           # the gables
		tri(Vector3(x, top, 0.0), Vector3(x, top, -DEEP_PLOT), Vector3(x, ridge, mid), "cal_vieja" if state == 0 else "white", Vector3(-1 if x == 0.0 else 1, 0, 0))
	if state >= 5:
		box(7.6, ridge - 0.6, mid - 0.9, 0.6, 1.5, 0.6, "white")
		box(7.52, ridge + 0.9, mid - 0.98, 0.76, 0.1, 0.76, 0xb5653f)
