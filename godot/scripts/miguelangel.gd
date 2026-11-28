extends "res://scripts/obra.gd"
## The Burger Pizzería Miguel Ángel of the Calle de Tembleque (the user, 27 November 2026: "Pizzería Michelangelo (que
## llamaremos Pizzeria Miguel Ángel)", and "En el cartel que ponga Burger Pizzería Miguel Ángel"), built by hand on Texturas's house of the map tembleque_8 (handed over as
## ["obra"] in casas_calles.gd); referencias/pizzeria_miguelangel/, tools/miguelangel/. Measures: Catastro (3993742,
## its photograph of the front) and Street View 2024 (the roller down: it opens at night); how it is when open, a
## photograph of June 2025 (Google Maps).
##
## The front (from its north end, the left seen from the street):
##   - the ground floor of tan facing brick over a foot of terracotta tiles with a cream lattice; the old garage's bay,
##     where the pizzeria is: shut by a beige roller; open (its hours), the roller up and a porch 1.2 m deep behind it,
##     its brick sides and its wooden ceiling, a screen of varnished wood and glass (two doors in the middle), and the
##     dining room behind, lit: tables with red and white chequered cloths, the counter, the oven's mouth glowing;
##   - two lanterns, the white box of the meters, the alarm's box, the box sign standing out from the wall over the
##     second lantern, as the real one (the user, 27 Nov 2026, with its photograph: "Que se parezca más en estilo al
##     original"), with the user's words: BURGER / PIZZERÍA in crimson, Miguel Ángel under them in pale blue, a frame
##     of aluminium;
##   - the flats' door, deep in its brick with a flat arch over it, a striped curtain in its doorway;
##   - a band of brick, then the floor above of cream render, its two windows framed in toothed brick (white frames,
##     their white blinds part down), toothed brick at its two corners; a brick frieze and cornice under the eaves; the
##     tiled roof falling to the street; the cables across.
## No house numbers, telephones or web addresses (the game shows none).
## Hours (Google Maps): Monday 18:00-23:30, Thursday to Sunday 19:00-23:30, shut on Tuesdays and Wednesdays.
##
## Frame: origin at the front's north end, on the party wall with tembleque_10; +x along the front (to the south),
## +z out of it, towards the street; y = 0 the pizzeria's floor.

const READY := true
const HOUSE := "tembleque_8"
const DIR := "res://assets/miguelangel/"
const NAME := "Burger Pizzería Miguel Ángel"            # (the user's name, 27 Nov 2026: "En el cartel que ponga Burger Pizzería Miguel Ángel")
const SIGN := ["BURGER", "PIZZERÍA", "Miguel Ángel"]    # what its box sign reads (letrero.png)
const GAR := Rect2(0.68, -0.05, 2.75, 2.65)             # the old garage's bay: the pizzeria's way in (its foot under the porch's floor)
const PORCH := 1.2                                      # how deep its porch is, to the screen of wood and glass
const DOOR_X := 5.35                                    # the flats' door: from here...
const DOOR_W := 1.0                                     # ...this wide...
const DOOR_H := 2.3                                     # ...and this high over its step
const METER := Rect2(3.95, 0.9, 0.75, 0.8)
const SKIRT := 0.8                                      # the foot of tiles, over the pavement
const G1 := 3.3                                         # the ground floor's brick ends (a band) and the render begins
const WIN := [Rect2(1.33, 4.2, 1.2, 1.05), Rect2(4.56, 4.2, 1.2, 1.05)]
const BLINDS := [0.62, 0.4]                             # how far down their blinds are
const FRIEZE := 5.75                                    # the brick under the eaves begins...
const EAVES := 6.2                                      # ...and ends
const BAY := 4.4                                        # the front bay's depth (Catastro): its roof falls from there to the street
const ROOF_K := 0.3                                     # (its pitch)
const FLAT := 6.0                                       # the flat roof of the rest of the house, behind
const SIGN_X := 3.75                                    # the box sign stands out here...
const SIGN_Y := 3.62                                    # ...from this height...
const SIGN_W := 1.0                                     # ...this far out...
const SIGN_H := 0.7                                     # ...this high...
const SIGN_T := 0.14                                    # ...this thick
const SIGN_OFF := 0.14                                  # (its gap to the wall, on its two arms)
const LAMPS := [0.34, 3.72]                             # the lanterns
const LAMP_Y := 2.78
const ROOM := Rect2(0.12, -8.0, 4.8, 8.0 - PORCH - 0.02)   # the dining room seen through the glass (x, z)
const HOURS := {0: [Vector2(18.0, 23.5)], 3: [Vector2(19.0, 23.5)], 4: [Vector2(19.0, 23.5)], 5: [Vector2(19.0, 23.5)],
	6: [Vector2(19.0, 23.5)]}                          # the day (0 Monday ... 6 Sunday) and from when to when
const WOOD := 0x9a6638                                  # the varnished wood of the screen
const ALU := 0xb4b8be

var L := 7.83
var EU := Vector2(-0.3459, 0.9383)
var EV := Vector2(-0.9383, -0.3459)
var A := Vector2(-413.75, -99.73)
var outline: Array = []                                    # the house's outline, in the frame
var door_r: Rect2                                       # the flats' door, its step known
var door: Vector2                                       # before the pizzeria's way in, on the pavement (the self-test)
var sign_at: Vector3                                    # the middle of its box sign, in the world (the self-test)
var is_open := false
var openings := 0
var decks: Array = []                                   # its porch and the ramp before it, as given to the map
var _shut: Node3D
var _lit: Node3D

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"ladrillo":         # the tan facing brick (Catastro's photograph and June 2025's: about 190, 150, 110 in the sun)
			m = Tex.mat("brick_wall_003@0.9", Color(1.0, 1.12, 1.22))
		"revoco":           # the cream render of the floor above
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.95, 0.9, 0.8)), 0.08)
		"azotea":           # the flat roof behind
			m = Tex.mat("granular_concrete", Color(0.66, 0.62, 0.58))
		"cemento":          # the ramp before the bay
			m = Tex.mat("granular_concrete", Color(0.78, 0.76, 0.72))
		"suelo":            # the porch's floor and the dining room's: terracotta tiles
			m = Tex.mat("granular_concrete", Color(0.72, 0.46, 0.34))
		"baldosa", "cortina":
			var tm := StandardMaterial3D.new()
			tm.albedo_texture = load(DIR + String(key) + ".png")
			tm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			tm.roughness = 0.55 if String(key) == "baldosa" else 0.95
			m = tm
		"letrero":          # the box sign's faces: lit from inside (a little by day, more when open)
			var lm := StandardMaterial3D.new()
			lm.albedo_texture = load(DIR + "letrero.png")
			lm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			lm.roughness = 0.7
			lm.metallic_specular = 0.0          # (no shine: a lit box)
			lm.emission_enabled = true
			lm.emission_texture = lm.albedo_texture
			lm.emission = Color.BLACK           # (Godot adds this colour to the picture before the energy: white here whitened the whole blue-black face)
			lm.emission_energy_multiplier = 0.12
			m = lm
		"persiana":         # the beige roller: slats one to the picture, its UVs in slats
			var img := Image.create(4, 16, false, Image.FORMAT_RGB8)
			for y in range(16):
				var k := 0.5 + 0.5 * sin(y / 16.0 * TAU)
				for x in range(4):
					img.set_pixel(x, y, Color(0.5, 0.42, 0.29).lerp(Color(0.8, 0.69, 0.5), k if y > 1 else 0.0))
			var sm := StandardMaterial3D.new()
			sm.albedo_texture = ImageTexture.create_from_image(img)
			sm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			sm.roughness = 0.6
			sm.metallic = 0.2
			m = sm
		"persiana_blanca":  # the blinds of the windows above
			var img2 := Image.create(4, 8, false, Image.FORMAT_RGB8)
			for y in range(8):
				for x in range(4):
					img2.set_pixel(x, y, Color(0.93, 0.93, 0.91) if y > 0 else Color(0.7, 0.7, 0.7))
			var bm := StandardMaterial3D.new()
			bm.albedo_texture = ImageTexture.create_from_image(img2)
			bm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			bm.roughness = 0.7
			m = bm
		"mantel":           # red and white check
			var img3 := Image.create(8, 8, false, Image.FORMAT_RGB8)
			for y in range(8):
				for x in range(8):
					var r := (x < 4) != (y < 4)
					var both := x < 4 and y < 4
					img3.set_pixel(x, y, Color(0.72, 0.1, 0.1) if both else (Color(0.9, 0.55, 0.55) if r else Color(0.97, 0.96, 0.94)))
			var cm := StandardMaterial3D.new()
			cm.albedo_texture = ImageTexture.create_from_image(img3)
			cm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			cm.roughness = 0.9
			cm.emission_enabled = true
			cm.emission_texture = cm.albedo_texture
			cm.emission = Color(1.0, 0.9, 0.75)
			cm.emission_energy_multiplier = 0.15
			m = cm
		"vidrio":
			var vm := StandardMaterial3D.new()
			vm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			vm.albedo_color = Color(0.5, 0.58, 0.6, 0.26)
			vm.roughness = 0.1
			vm.metallic_specular = 0.75
			m = vm
		"interior":         # the dining room's walls: warm, lit when open
			var im := StandardMaterial3D.new()
			im.albedo_color = Color(0.86, 0.72, 0.5)
			im.emission_enabled = true
			im.emission = Color(1.0, 0.82, 0.58)
			im.emission_energy_multiplier = 0.02
			m = im
		"horno":            # the oven's mouth
			var hm := StandardMaterial3D.new()
			hm.albedo_color = Color(0.2, 0.08, 0.02)
			hm.emission_enabled = true
			hm.emission = Color(1.0, 0.45, 0.12)
			hm.emission_energy_multiplier = 0.1
			m = hm
		"farol":            # the lanterns' glass, lit a little
			var fm := StandardMaterial3D.new()
			fm.albedo_color = Color(0.98, 0.94, 0.8)
			fm.emission_enabled = true
			fm.emission = Color(1.0, 0.86, 0.55)
			fm.emission_energy_multiplier = 0.5
			m = fm
		"luz":              # the dining room's ceiling lamps
			var l2 := StandardMaterial3D.new()
			l2.albedo_color = Color(1.0, 0.95, 0.85)
			l2.emission_enabled = true
			l2.emission = Color(1.0, 0.9, 0.7)
			l2.emission_energy_multiplier = 2.0
			m = l2
		_:
			return super(key)
	_mats[key] = m
	return m

## its house of the map, if Texturas has handed it over (or empty)
## (`anyway`: the house as it is even if not handed over yet -- the self-test's --miguelangel, to see it before then)
static func handed_over(anyway := false) -> Dictionary:
	var short = preload("res://scripts/casas_calles.gd").HOUSES
	for hd in MapData.houses:
		if String(hd["id"]) == HOUSE:
			var line = short.get(HOUSE, [])
			if anyway or (line is Array and (line as Array).size() == 1 and String(line[0]) == "obra"):
				return hd
			return {}
	return {}

func build(world, hd: Dictionary) -> void:
	W = world
	A = Vector2(hd["o"][0], hd["o"][1])
	EU = Vector2(hd["u"][0], hd["u"][1]).normalized()
	EV = Vector2(-EU.y, EU.x)
	L = float(hd["len"])
	var r: Array = hd["pieces"][0]["ring"]
	outline.clear()
	for i in range(0, r.size(), 2):
		outline.append(to_uv(Vector2(r[i], r[i + 1])))
	# its floor: the house's, or a little over the street before the bay where the street is higher (it rises north)
	level = float(hd.get("base", MapData.height(map_at(L / 2.0, 0.2))))
	var top := -INF
	for k in range(6):
		top = maxf(top, MapData.height(map_at(lerpf(GAR.position.x, GAR.end.x, k / 5.0), 0.1)))
	level = maxf(level, top + 0.08)
	transform = Transform3D(Basis(Vector3(EU.x, 0, EU.y), Vector3.UP, Vector3(EV.x, 0, EV.y)), Vector3(A.x, level, A.y))
	W.add_child(self)
	var dy := ground(DOOR_X + DOOR_W / 2.0, 0.1) + 0.12          # (its step over the street, which falls to the south)
	door_r = Rect2(DOOR_X, dy, DOOR_W, DOOR_H)
	door = spot(GAR.get_center().x, 1.0)
	_ground_floor()
	_porch()
	_inside()
	_upper()
	_roof()
	_sign()
	home()
	_commit()
	_states()
	_solids_all()
	set_open(open_at(0, 20.0))

func map_at(u: float, v: float) -> Vector2:
	return A + EU * u + EV * v

func to_uv(p: Vector2) -> Vector2:
	var d := p - A
	return Vector2(d.dot(EU), d.dot(EV))

func open_at(day: int, hour: float) -> bool:
	var d := posmod(day, 7)
	if not HOURS.has(d):
		return false
	for h: Vector2 in HOURS[d]:
		if hour >= h.x and hour < h.y:
			return true
	return false

# ---------------- pieces ----------------
## something that repeats every `step` metres across and `stepy` up (tiles, slats), facing +z
func _tiled(x0: float, x1: float, y0: float, y1: float, z: float, key, step := 0.2, stepy := 0.2) -> void:
	pieces += 1
	quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1),
		[Vector2(x0 / step, -y0 / stepy), Vector2(x1 / step, -y0 / stepy), Vector2(x1 / step, -y1 / stepy), Vector2(x0 / step, -y1 / stepy)])

## A piece of floor that people walk on: its corners (x, y, z) in order round it, all in one plane. Its top, its sides
## down into the ground, what holds it up, and the map told (a sloping one with its "grad").
func _deck(pts: Array, key, sides: bool) -> void:
	pieces += 1
	var flatp := PackedVector2Array()
	var mid := 0.0
	for q: Vector3 in pts:
		flatp.append(Vector2(q.x, q.z))
		mid += q.y / float(pts.size())
	var uv: Array = []
	for q: Vector3 in pts:
		uv.append(Vector2(q.x, q.z) / 1.6)
	quad(pts[0], pts[1], pts[2], pts[3], key, Vector3.UP, uv)
	if sides:
		for i in [1, 3]:
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[(i + 1) % 4]
			var ga := ground(a.x, a.z) - 0.3
			var gb := ground(b.x, b.z) - 0.3
			quad(Vector3(a.x, ga, a.z), Vector3(b.x, gb, b.z), b, a, key, Vector3(1 if i == 1 else -1, 0, 0))
	var all: Array = []
	for q: Vector3 in pts:
		all.append(q)
		all.append(Vector3(q.x, minf(q.y, ground(q.x, q.z)) - 0.6, q.z))
	_hull(all)
	var n: Vector3 = ((pts[1] as Vector3) - (pts[0] as Vector3)).cross((pts[2] as Vector3) - (pts[0] as Vector3))
	if n.y < 0.0:
		n = -n
	var dk := _poly_deck(flatp, level + mid)
	if absf(n.x) > 0.00001 or absf(n.z) > 0.00001:
		dk["grad"] = EU * (-n.x / n.y) + EV * (-n.z / n.y)
	decks.append(dk)
	MapData.decks.append(dk)

## a run of the foot of tiles, its top 0.8 m over the pavement at each end (the street falls to the south)
func _skirt(x0: float, x1: float) -> void:
	var t0 := ground(x0, 0.1) + SKIRT
	var t1 := ground(x1, 0.1) + SKIRT
	var z := 0.014
	pieces += 1
	quad(Vector3(x0, -0.6, z), Vector3(x1, -0.6, z), Vector3(x1, t1, z), Vector3(x0, t0, z), "baldosa", Vector3(0, 0, 1),
		[Vector2(x0 / 0.4, 0.6 / 0.4), Vector2(x1 / 0.4, 0.6 / 0.4), Vector2(x1 / 0.4, -t1 / 0.4), Vector2(x0 / 0.4, -t0 / 0.4)])
	bar(Vector3(x0, t0 + 0.012, 0.02), Vector3(x1, t1 + 0.012, 0.02), 0.04, 0.025, 0xa8684a)      # (its edge)

## a lantern on the wall: an iron arm and its glass
func _farol(x: float, y: float) -> void:
	box(x - 0.02, y + 0.42, 0.0, 0.04, 0.04, 0.34, IRON)
	box(x - 0.11, y, 0.22, 0.22, 0.34, 0.22, "farol")
	box(x - 0.14, y + 0.34, 0.19, 0.28, 0.06, 0.28, IRON)
	box(x - 0.12, y - 0.05, 0.2, 0.24, 0.05, 0.24, IRON)
	cbox(Vector3(x, y + 0.46, 0.31), Vector3(0.08, 0.1, 0.08), IRON)
	for k in [-0.122, 0.102]:                                  # (the iron at its corners, a little proud of the glass)
		box(x + k, y, 0.208, 0.02, 0.34, 0.02, IRON)
		box(x + k, y, 0.432, 0.02, 0.34, 0.02, IRON)

## a column of toothed brick: courses 15 cm high, wide and narrow in turn, from y0 to y1, out from x (`dir` +1: to the
## right of it; -1: to the left)
func _teeth(x: float, y0: float, y1: float, wide: float, narrow: float, dir: float, first_wide := true) -> void:
	var y := y0
	var k := 0 if first_wide else 1
	while y < y1 - 0.01:
		var h := minf(0.15, y1 - y)
		var w := wide if k % 2 == 0 else narrow
		var x0 := x if dir > 0.0 else x - w
		box(x0, y, 0.0, w, h, 0.022, "ladrillo")
		y += h
		k += 1

# ---------------- the front ----------------
func _ground_floor() -> void:
	home()
	masonry(0.0, L, -1.0, G1, [GAR, door_r], [], "ladrillo", "ladrillo")
	openings += 2
	for run in [[0.0, GAR.position.x], [GAR.end.x, door_r.position.x], [door_r.end.x, L]]:
		_skirt(run[0], run[1])
	# the soldier course over the bay, the band at the floor's top with its little drip
	box(GAR.position.x - 0.14, GAR.end.y, 0.0, GAR.size.x + 0.28, 0.22, 0.02, "ladrillo")
	box(0.0, G1 - 0.22, 0.0, L, 0.22, 0.025, "ladrillo")
	box(0.0, G1 - 0.03, 0.0, L, 0.05, 0.055, 0xa8805c)
	# the flats' door: its marble step, the flat arch, the curtain across the doorway, the dark of the stairs behind
	var d := door_r
	box(d.position.x - 0.05, d.position.y - 0.03, -0.012, d.size.x + 0.1, 0.075, 0.07, 0xd8d0c4)
	box(d.position.x - 0.14, d.end.y, 0.0, d.size.x + 0.28, 0.26, 0.022, "ladrillo")
	for i in range(7):                                         # (the arch's bricks fanning, their joints)
		var jx: float = d.position.x - 0.1 + (d.size.x + 0.2) * (i + 0.5) / 7.0
		box(jx - 0.006, d.end.y + 0.02, 0.022, 0.012, 0.22, 0.004, 0x8a6a50)
	pieces += 1
	quad(Vector3(d.position.x + 0.02, d.position.y + 0.06, -0.2), Vector3(d.end.x - 0.02, d.position.y + 0.06, -0.2),
		Vector3(d.end.x - 0.02, d.end.y - 0.04, -0.2), Vector3(d.position.x + 0.02, d.end.y - 0.04, -0.2), "cortina", Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	box(d.position.x, d.end.y - 0.06, -0.24, d.size.x, 0.03, 0.03, 0x8a8a8a)                    # (its rod)
	quad(Vector3(d.position.x, d.position.y, -DEEP + 0.01), Vector3(d.end.x, d.position.y, -DEEP + 0.01),
		Vector3(d.end.x, d.end.y, -DEEP + 0.01), Vector3(d.position.x, d.end.y, -DEEP + 0.01), 0x2a2420, Vector3(0, 0, 1))
	box(d.position.x - 0.3, 1.25, 0.0, 0.12, 0.18, 0.03, 0x9a9a98)                                # (the entryphone)
	# the meters' white box, the grille of the drain in the tiles under it, the alarm's box
	box(METER.position.x, METER.position.y, 0.0, METER.size.x, METER.size.y, 0.16, 0xeeeeea)
	box(METER.position.x + 0.08, METER.position.y + 0.4, 0.16, 0.3, 0.2, 0.012, 0x3a4048)
	box(METER.position.x + 0.15, ground(METER.position.x, 0.1) + 0.2, 0.0, 0.34, 0.3, 0.03, 0x8a8c8e)
	box(4.33, 2.62, 0.0, 0.38, 0.68, 0.12, 0xf2f2ee)
	box(4.38, 2.7, 0.12, 0.28, 0.06, 0.012, 0xc03a2a)
	# the lanterns
	for x in LAMPS:
		_farol(x, LAMP_Y)
	W.lamp_spots.append(transform * Vector3(LAMPS[1], LAMP_Y + 0.15, 0.6))

## the porch behind the bay: its sides of brick carried back, its wooden ceiling, its floor (and the ramp out to the
## pavement, the old garage's), the screen of varnished wood and glass with its two doors
func _porch() -> void:
	home()
	var a := GAR.position
	var b := GAR.end
	quad(Vector3(a.x, -0.05, -PORCH), Vector3(a.x, -0.05, -DEEP), Vector3(a.x, b.y, -DEEP), Vector3(a.x, b.y, -PORCH), "ladrillo", Vector3(1, 0, 0))
	quad(Vector3(b.x, -0.05, -DEEP), Vector3(b.x, -0.05, -PORCH), Vector3(b.x, b.y, -PORCH), Vector3(b.x, b.y, -DEEP), "ladrillo", Vector3(-1, 0, 0))
	quad(Vector3(a.x, b.y, -PORCH), Vector3(b.x, b.y, -PORCH), Vector3(b.x, b.y, -DEEP), Vector3(a.x, b.y, -DEEP), 0x7a5232, Vector3(0, -1, 0))
	for k in range(5):                                         # (the boards of its ceiling)
		box(a.x, b.y - 0.012, -PORCH + 0.02 + k * 0.17, GAR.size.x, 0.012, 0.012, 0x5a3a22)
	_deck([Vector3(a.x, 0.0, -PORCH), Vector3(b.x, 0.0, -PORCH), Vector3(b.x, 0.0, 0.0), Vector3(a.x, 0.0, 0.0)], "suelo", false)
	# the old garage's ramp down to the pavement, in three strips (each one plane: the street falls along the front)
	var zr := 0.45
	for k in range(3):
		var s0 := lerpf(a.x, b.x, k / 3.0)
		var s1 := lerpf(a.x, b.x, (k + 1) / 3.0)
		var gy := (ground(s0, zr) + ground(s1, zr)) / 2.0 + 0.02
		_deck([Vector3(s0, 0.0, 0.0), Vector3(s1, 0.0, 0.0), Vector3(s1, gy, zr), Vector3(s0, gy, zr)], "cemento", k == 0 or k == 2)
	yard.append(spot(a.x, zr))
	yard.append(spot(b.x, zr))
	# the screen: a frame of varnished wood, a fixed pane each side, two doors in the middle, a transom over them
	var z := -PORCH
	var x0 := a.x
	var x1 := b.x
	var p1 := x0 + 0.66
	var p2 := x1 - 0.66
	var mid := (x0 + x1) / 2.0
	var top := b.y
	box(x0, 0.0, z - 0.08, x1 - x0, 0.1, 0.1, WOOD)                    # (its foot)
	box(x0, top - 0.1, z - 0.08, x1 - x0, 0.1, 0.1, WOOD)              # (its head)
	box(x0, 2.1, z - 0.08, x1 - x0, 0.08, 0.1, WOOD)                   # (the transom's rail)
	for x in [x0, p1 - 0.08, p2, x1 - 0.08]:                            # (its posts)
		box(x, 0.0, z - 0.08, 0.08, top, 0.1, WOOD)
	for leaf in [[p1, mid], [mid, p2]]:                                 # (the two doors: their stiles and their kick rails)
		var l0: float = leaf[0]
		var l1: float = leaf[1]
		box(l0 + 0.005, 0.1, z - 0.06, 0.07, 2.0, 0.07, WOOD)
		box(l1 - 0.075, 0.1, z - 0.06, 0.07, 2.0, 0.07, WOOD)
		box(l0 + 0.005, 0.1, z - 0.06, l1 - l0 - 0.01, 0.2, 0.07, WOOD)
	for r in [[x0 + 0.08, p1 - 0.08, 0.1, 2.1], [p2 + 0.08, x1 - 0.08, 0.1, 2.1], [p1 + 0.075, mid - 0.075, 0.3, 2.1], [mid + 0.075, p2 - 0.075, 0.3, 2.1],
			[x0 + 0.08, x1 - 0.08, 2.18, top - 0.1]]:
		pieces += 1
		quad(Vector3(r[0], r[2], z - 0.03), Vector3(r[1], r[2], z - 0.03), Vector3(r[1], r[3], z - 0.03), Vector3(r[0], r[3], z - 0.03), "vidrio", Vector3(0, 0, 1))
	for x in [mid - 0.12, mid + 0.1]:                                   # (their long steel handles)
		box(x, 0.85, z + 0.03, 0.025, 0.8, 0.025, 0xc8ccd0)
		box(x, 0.88, z + 0.02, 0.025, 0.025, 0.02, 0xc8ccd0)
		box(x, 1.6, z + 0.02, 0.025, 0.025, 0.02, 0xc8ccd0)
	openings += 1

## the dining room seen through the glass: warm walls, a terracotta floor, the ceiling with its lamps, three tables
## with their chequered cloths and chairs, the counter at the back and the oven's mouth
func _inside() -> void:
	home()
	var x1 := ROOM.end.x
	var zb := ROOM.position.y
	var zf := -PORCH - 0.02
	var xa := _side_x(true, zf) + ROOM.position.x       # (its north wall runs along the party wall, which slants)
	var xb := _side_x(true, zb) + ROOM.position.x
	flat(PackedVector2Array([Vector2(xa, zf), Vector2(x1, zf), Vector2(x1, zb), Vector2(xb, zb)]), 0.005, "suelo")
	quad(Vector3(xb, 0, zb), Vector3(x1, 0, zb), Vector3(x1, 3.0, zb), Vector3(xb, 3.0, zb), "interior", Vector3(0, 0, 1))
	quad(Vector3(x1, 0, zb), Vector3(x1, 0, zf), Vector3(x1, 3.0, zf), Vector3(x1, 3.0, zb), "interior", Vector3(-1, 0, 0))
	quad(Vector3(xa, 3.0, zf), Vector3(x1, 3.0, zf), Vector3(x1, 3.0, zb), Vector3(xb, 3.0, zb), 0xe8e2d6, Vector3(0, -1, 0))
	box(x1 - 0.01, 0.0, zb, 0.01, 1.0, zf - zb, 0x8a5a3a)               # (a wainscot of brown tiles)
	box(xb, 0.0, zb, x1 - xb, 1.0, 0.01, 0x8a5a3a)
	# the north wall, in its own frame: the wainscot, pictures (the dark frames of photographs, their colours only)
	var ln := face(Vector2(xa, zf), Vector2(xb, zb))
	quad(Vector3(0, 0, 0), Vector3(ln, 0, 0), Vector3(ln, 3.0, 0), Vector3(0, 3.0, 0), "interior", Vector3(0, 0, 1))
	box(0.0, 0.0, 0.0, ln, 1.0, 0.01, 0x8a5a3a)
	for k in range(3):
		var s: float = 1.0 + k * 1.6
		box(s, 1.5, 0.0, 0.7, 0.5, 0.02, 0x3a2a1e)
		box(s + 0.05, 1.55, 0.02, 0.6, 0.4, 0.015, [0x6a7a5a, 0x8a5a3a, 0x4a5a7a][k])
	home()
	for t in [[1.5, -3.0], [3.6, -3.3], [2.5, -5.7]]:
		_table(t[0], t[1])
	# the counter at the back, the oven of brick in its corner with its glowing mouth
	box(1.3, 0.0, zb + 0.15, 2.0, 1.05, 0.55, 0x6a4428)
	box(1.25, 1.05, zb + 0.12, 2.1, 0.05, 0.62, 0xd8d0c0)
	box(1.6, 1.1, zb + 0.3, 0.3, 0.25, 0.2, 0x2a2a2a)                   # (the till)
	var oc := Vector3(x1 - 0.85, 0.0, zb + 0.85)
	box(oc.x - 0.75, 0.0, oc.z - 0.75, 1.5, 1.0, 1.5, "ladrillo")
	ball(oc + Vector3(0, 1.0, 0), 0.72, "ladrillo", 0.62, 12, 5)
	box(oc.x - 0.3, 1.0, oc.z + 0.62, 0.6, 0.32, 0.12, "horno")
	box(oc.x - 0.06, 1.42, oc.z - 0.1, 0.12, 1.6, 0.12, 0x5a5a5a)        # (its flue)
	for lx in [1.3, 3.4]:
		for lz in [-3.0, -5.6]:
			box(lx - 0.2, 2.94, lz - 0.2, 0.4, 0.04, 0.4, "luz")

## a table with its chequered cloth hanging, two chairs
func _table(cx: float, cz: float) -> void:
	var s := 0.42
	var y := 0.76
	pieces += 1
	quad(Vector3(cx - s, y, cz + s), Vector3(cx + s, y, cz + s), Vector3(cx + s, y, cz - s), Vector3(cx - s, y, cz - s), "mantel", Vector3.UP,
		[Vector2(0, 0), Vector2(3, 0), Vector2(3, 3), Vector2(0, 3)])
	for q in [[Vector3(cx - s, y, cz + s), Vector3(cx + s, y, cz + s), Vector3(0, 0, 1)], [Vector3(cx + s, y, cz - s), Vector3(cx - s, y, cz - s), Vector3(0, 0, -1)],
			[Vector3(cx - s, y, cz - s), Vector3(cx - s, y, cz + s), Vector3(-1, 0, 0)], [Vector3(cx + s, y, cz + s), Vector3(cx + s, y, cz - s), Vector3(1, 0, 0)]]:
		var a: Vector3 = q[0]
		var b: Vector3 = q[1]
		quad(a + Vector3(0, -0.26, 0), b + Vector3(0, -0.26, 0), b, a, "mantel", q[2], [Vector2(0, 0.8), Vector2(3, 0.8), Vector2(3, 0), Vector2(0, 0)])
	box(cx - 0.04, 0.0, cz - 0.04, 0.08, y - 0.01, 0.08, 0x3a2a1e)
	for side in [-1.0, 1.0]:
		var chx: float = cx + side * 0.62
		box(chx - 0.2, 0.44, cz - 0.2, 0.4, 0.04, 0.4, 0x7a4a28)
		for lx in [chx - 0.18, chx + 0.15]:
			for lz in [cz - 0.18, cz + 0.15]:
				box(lx, 0.0, lz, 0.03, 0.44, 0.03, 0x5a3a20)
		var bx: float = chx + side * 0.18
		box(bx - 0.015, 0.48, cz - 0.2, 0.03, 0.5, 0.4, 0x7a4a28)

## the floor above: cream render, the two windows framed in toothed brick with their sills, white frames and blinds,
## toothed brick at the corners; the brick frieze and the cornice under the eaves; the cables across
func _upper() -> void:
	home()
	masonry(0.0, L, G1, FRIEZE, WIN, [], "revoco", "revoco")
	masonry(0.0, L, FRIEZE, EAVES, [], [], "ladrillo", "ladrillo")
	openings += 2
	_teeth(0.0, G1, FRIEZE, 0.44, 0.26, 1.0)
	_teeth(L, G1, FRIEZE, 0.44, 0.26, -1.0)
	for i in range(WIN.size()):
		var r: Rect2 = WIN[i]
		_teeth(r.position.x + 0.012, r.position.y - 0.08, r.end.y + 0.08, 0.3, 0.16, -1.0)
		_teeth(r.end.x - 0.012, r.position.y - 0.08, r.end.y + 0.08, 0.3, 0.16, 1.0)
		box(r.position.x - 0.3, r.end.y + 0.08, 0.0, r.size.x + 0.6, 0.16, 0.022, "ladrillo")        # (the lintel's course)
		box(r.position.x - 0.12, r.position.y - 0.06, -0.012, r.size.x + 0.24, 0.105, 0.07, "ladrillo")   # (its sill, 4.5 cm over the hole)
		window(r, 0xf0f0ec, 0x26303a, 0)
		var down: float = BLINDS[i]
		_tiled(r.position.x + 0.04, r.end.x - 0.04, r.end.y - r.size.y * down, r.end.y - 0.02, -DEEP + 0.12, "persiana_blanca", 1.0, 0.05)
		box(r.position.x + 0.02, r.end.y - r.size.y * down - 0.03, -DEEP + 0.11, r.size.x - 0.04, 0.03, 0.04, 0xd8d8d4)
	cornice(0.2, L - 0.2, EAVES, false, "ladrillo", 0.7)
	# the cables: one sagging across the floor above, one down by the south corner
	var pts := [Vector3(-0.2, 5.55, 0.06), Vector3(2.0, 5.3, 0.06), Vector3(4.2, 5.25, 0.06), Vector3(6.4, 5.4, 0.06), Vector3(L + 0.2, 5.62, 0.06)]
	for k in range(pts.size() - 1):
		bar(pts[k], pts[k + 1], 0.018, 0.018, 0x1a1a1a)
	bar(Vector3(L - 0.32, 5.5, 0.06), Vector3(L - 0.3, 2.9, 0.06), 0.018, 0.018, 0x1a1a1a)
	bar(Vector3(L - 0.3, 2.9, 0.06), Vector3(L - 0.05, 2.75, 0.06), 0.018, 0.018, 0x1a1a1a)

## The roof: the front bay's tiles falling to the street from its back wall, the walls round the rest of the house (its
## outline in the map, a little in from the neighbours'), its flat roof, the gable ends over the neighbours.
func _roof() -> void:
	home()
	var z0 := 0.3                                   # the tiles' edge, over the cornice
	var y0 := EAVES + 0.03
	var ridge_y := y0 + (z0 + BAY) * ROOF_K
	var xn := _side_x(true, -BAY)                    # where the party walls are at the bay's back
	var xs := _side_x(false, -BAY)
	roof([Vector3(-0.02, y0, z0), Vector3(L + 0.02, y0, z0), Vector3(xs, ridge_y, -BAY), Vector3(xn, ridge_y, -BAY)])
	ridge(Vector3(xn, ridge_y, -BAY), Vector3(xs, ridge_y, -BAY))
	box(0.0, y0 - 0.05, 0.12, L, 0.06, z0 - 0.1, 0x9a5a3c)                         # (the tiles' lip over the cornice)
	ring_walls(outline, -1.5, FLAT, "revoco", [0])
	flat(PackedVector2Array(outline), FLAT, "azotea")
	# the bay's back wall over the flat roof, the two gable ends (a little in from the neighbours' lines)
	quad(Vector3(xs, FLAT, -BAY), Vector3(xn, FLAT, -BAY), Vector3(xn, ridge_y, -BAY), Vector3(xs, ridge_y, -BAY), "revoco", Vector3(0, 0, -1))
	var yz0 := y0 + z0 * ROOF_K                     # (the tiles' height over the front's line)
	quad(Vector3(0.025, FLAT, 0.0), Vector3(0.025, EAVES, 0.0), Vector3(xn + 0.025, ridge_y, -BAY), Vector3(xn + 0.025, FLAT, -BAY), "revoco", Vector3(-1, 0, 0))
	tri(Vector3(0.025, EAVES, 0.0), Vector3(0.025, yz0, 0.0), Vector3(xn + 0.025, ridge_y, -BAY), "revoco", Vector3(-1, 0, 0))
	quad(Vector3(L - 0.025, FLAT, 0.0), Vector3(xs - 0.025, FLAT, -BAY), Vector3(xs - 0.025, ridge_y, -BAY), Vector3(L - 0.025, EAVES, 0.0), "revoco", Vector3(1, 0, 0))
	tri(Vector3(L - 0.025, EAVES, 0.0), Vector3(xs - 0.025, ridge_y, -BAY), Vector3(L - 0.025, yz0, 0.0), "revoco", Vector3(1, 0, 0))

## where a party wall is (its x) at depth z: the north one (from the front's north corner back) or the south one
func _side_x(north: bool, z: float) -> float:
	var n := outline.size()
	var corner: Vector2 = outline[1] if north else outline[0]
	var nxt: Vector2 = outline[2] if north else outline[n - 1]
	if absf(nxt.y - corner.y) < 0.01:
		return corner.x
	var t := clampf((z - corner.y) / (nxt.y - corner.y), 0.0, 1.0)
	return lerpf(corner.x, nxt.x, t)

## the box sign standing out from the wall on two arms: a frame of aluminium, its two faces (each read the right way
## round from its own side of the street)
func _sign() -> void:
	home()
	var x := SIGN_X
	var y0 := SIGN_Y
	var y1 := SIGN_Y + SIGN_H
	var z0 := SIGN_OFF
	var z1 := SIGN_OFF + SIGN_W
	var t := SIGN_T / 2.0
	box(x - t, y0, z0, SIGN_T, SIGN_H, SIGN_W, ALU)
	var lift := t + 0.014
	pieces += 1
	quad(Vector3(x - lift, y0, z0), Vector3(x - lift, y0, z1), Vector3(x - lift, y1, z1), Vector3(x - lift, y1, z0), "letrero", Vector3(-1, 0, 0),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	quad(Vector3(x + lift, y0, z1), Vector3(x + lift, y0, z0), Vector3(x + lift, y1, z0), Vector3(x + lift, y1, z1), "letrero", Vector3(1, 0, 0),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	for y in [y0 + 0.1, y1 - 0.1]:                                       # (its two arms, their plates on the wall)
		box(x - 0.025, y - 0.025, 0.0, 0.05, 0.05, z0 + 0.02, 0x8a8c90)
		box(x - 0.07, y - 0.07, 0.0, 0.14, 0.14, 0.012, 0x8a8c90)
	sign_at = transform * Vector3(x, (y0 + y1) / 2.0, (z0 + z1) / 2.0)

# ---------------- shut and open ----------------
## what changes with the hours: the roller down or up, its last slat showing under the lintel; the dining
## room's light; the box sign brighter
func _states() -> void:
	var a := GAR.position
	var b := GAR.end
	_shut = Node3D.new()
	add_child(_shut)
	_tiled(a.x + 0.03, b.x - 0.03, 0.0, b.y - 0.02, -0.1, "persiana", 1.0, 0.09)
	box(a.x + 0.03, 0.0, -0.13, b.x - a.x - 0.06, 0.07, 0.05, 0x6a5a40)                 # (its bottom bar)
	box(a.x + 1.25, 0.03, -0.085, 0.24, 0.05, 0.03, 0x4a4a4a)                            # (its lock)
	_commit_to(_shut)
	_lit = Node3D.new()
	add_child(_lit)
	box(a.x + 0.03, b.y - 0.13, -0.13, b.x - a.x - 0.06, 0.11, 0.05, 0x7a6a4a)           # (its last slat, the roller up)
	_commit_to(_lit)
	var warm := OmniLight3D.new()
	warm.position = Vector3(2.5, 2.4, -4.2)
	warm.light_color = Color(1.0, 0.86, 0.64)
	warm.omni_range = 6.0
	warm.light_energy = 0.9
	warm.shadow_enabled = false
	_lit.add_child(warm)
	var porch := OmniLight3D.new()                   # (the porch's own lamp, falling out on the pavement)
	porch.position = Vector3(GAR.get_center().x, 2.4, -0.6)
	porch.light_color = Color(1.0, 0.88, 0.68)
	porch.omni_range = 3.0
	porch.light_energy = 0.4
	porch.shadow_enabled = false
	_lit.add_child(porch)

## what has been built since the last commit becomes meshes under `node`: a part that can be shown and hidden
func _commit_to(node: Node3D) -> void:
	for key in _tools:
		var mi := MeshInstance3D.new()
		mi.mesh = (_tools[key] as SurfaceTool).commit()
		mi.material_override = _material(key)
		node.add_child(mi)
	_tools.clear()

## its solids: the house behind the porch's screen, the front either side of the bay (the porch and the ramp are floors).
## The map's wall round the block (world.gd, MapData.outlines) runs along the front, so the porch is seen through the
## bay, not walked into: opening it to the feet would take a rebake of the block's outline.
func _solids_all() -> void:
	var poly := PackedVector2Array(outline)
	var cut := PackedVector2Array([Vector2(GAR.position.x, 1.0), Vector2(GAR.end.x, 1.0), Vector2(GAR.end.x, -PORCH), Vector2(GAR.position.x, -PORCH)])
	for part: PackedVector2Array in Geometry2D.clip_polygons(poly, cut):
		var idx := Geometry2D.triangulate_polygon(part)
		for k in range(0, idx.size(), 3):
			_prism([part[idx[k]], part[idx[k + 1]], part[idx[k + 2]]], -1.0, FLAT + 0.5)

func set_open(on: bool) -> void:
	is_open = on
	if _shut != null:
		_shut.visible = not on
		_lit.visible = on
	if _mats.has("interior"):
		(_mats["interior"] as StandardMaterial3D).emission_energy_multiplier = 0.3 if on else 0.02
	if _mats.has("horno"):
		(_mats["horno"] as StandardMaterial3D).emission_energy_multiplier = 1.6 if on else 0.1
	if _mats.has("luz"):
		(_mats["luz"] as StandardMaterial3D).emission_energy_multiplier = 2.0 if on else 0.0
	if _mats.has("letrero"):
		(_mats["letrero"] as StandardMaterial3D).emission_energy_multiplier = 0.7 if on else 0.12

func _process(_delta: float) -> void:
	var game = W.get_parent() if W != null else null
	if game != null and "clock" in game and "weekday" in game:
		var o: bool = open_at(int(game.weekday), float(game.clock))
		if o != is_open:
			set_open(o)
