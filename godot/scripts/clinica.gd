extends "res://scripts/esquina.gd"
## The dental clinic of the crossroads of the traffic lights: the corner of the Calle Cervantes and the Calle de los
## Arcos, opposite "Seguros Sopiss". The user, 22 November 2026: "Vamos con el dentista. Lo llamaremos \"Clínica Dental\"
## y \"Dr. Josué Escudero\"". Built by hand from Street View (November 2024, from the three streets it is seen from:
## tools/cruce/capturas.py, the d_ pictures) on the house `arcos_2` of the map (casas_calles.gd marks it "obra"), with
## no rebake; referencias/cruce/LEEME.md.
##
## Two floors, 6.75 m to its eaves:
##   - below, dark brown stone in big tiles with thin steel strips across it; raised letters of pale steel, CLÍNICA
##     DENTAL (one line to the Calle Cervantes, two to the Arcos) and "Dr. Josué Escudero" under them; windows of mirror
##     glass with the clinic's words on them in green and white; to the Calle Cervantes the grey louvred doors of a plant
##     room and the glass door of the clinic; to the Arcos, past the stone, the house's own doorway between grey granite
##     piers in a wall of cream tiles, behind a pink curtain;
##   - above, cream render: one long balcony of ribbed dark sheet round the corner, three of wrought iron, white
##     blinds; wooden eaves on close-set rafters, old tiles, the corner hipped.
## Nobody gets in and nothing shows through its glass. Its windows glow while it is open (the real clinic's hours) and its
## letters are lit by night. No real name on it. No saffron hidden here: one stood in the house's doorway and the user
## had it taken away (22 November 2026: "Quita ese azafrán escondido, sigue proponiendolos y yo te digo en cada proyecto
## si lo añadimos o lo quitamos").
##
## Frame: the map's own (x east, z south), y = 0 the pavement at the corner. Each front is built in its own frame
## (obra.face: x along it seen from the street, z out of it). The roof, the eaves, the shared walls and the solids are
## esquina.gd's.

const HOUSE := "arcos_2"
const NAME := "Clínica Dental"
const DOCTOR := "Dr. Josué Escudero"
const DIR := "res://assets/clinica/"

# its corners on the map (Catastro 4390018VJ5649S: the house's own ring, its corner drawn sharp as it is built)
const NW := Vector2(96.54, 79.20)            # where it ends on the Calle Cervantes
const X := Vector2(109.115, 77.683)          # the corner of the Calle Cervantes and the Arcos
const SE := Vector2(109.06, 86.65)           # where it ends on the Arcos
const SW := Vector2(97.23, 88.39)            # the corner at its back

const SILL := 0.7                   # the windows' sill
const HEAD := 2.75                  # the top of the openings below
const STONE_TOP := 3.75             # the top of the dark stone
const F1 := 4.0                     # the floor above: the balconies' floor
const DOOR_H := 2.1                 # how tall the balconies' doors are
const TOP := 6.75                   # the top of the walls
const EAVE := 0.6
const PITCH := 0.33
const RISE0 := 0.2                  # (EAVE * PITCH)
const CORNER_OUT := 0.8             # how far the corner's balcony stands out
const BALC_OUT := 0.5               # and the others
const TILE := 0.6                   # the dark stone's tiles
const HOURS := {0: [[9.0, 13.5], [16.5, 20.0]], 1: [[9.0, 13.5], [16.5, 20.0]], 2: [[9.0, 13.5], [16.5, 20.0]], 3: [[9.0, 13.5], [16.5, 20.0]],
	4: [[9.0, 13.5], [16.5, 20.0]]}      # day (0 Monday ... 6 Sunday): from when to when (the real clinic's, from Google Maps). Shut on Saturdays and Sundays
const STEEL := 0xb9b6ae             # the strips across the stone, the windows' frames
const SHEET := 0x26262a             # the corner balcony's ribbed sheet, the iron of the others
const WHITE := 0xf4f2ec             # the frames of the floor above
const GLASS := 0x1f2a33

var door: Vector2                   # before the clinic's door, on the Calle Cervantes (the self-test)
var house_door: Vector2             # before the house's own doorway, on the Arcos
var is_open := false
var night := 0.0                    # how much its letters are lit (0 by day ... 1 at night)
var openings := 0                   # windows and doors (the self-test)
var balconies := 0

var _lit: Array = []                # [material, its emission while the clinic is open]
var _floodlit: Array = []           # the letters' materials

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	var name_ := String(key) if key is String else ""
	match name_:
		"piedra_oscura":    # the dark brown stone (Street View 2024: about 75, 55, 48, mottled)
			m = Tex.mat("granular_concrete", Color(0.46, 0.32, 0.26))
		"azulejo":          # the cream tiles round the house's doorway
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.95, 0.82)), 0.22)
		"crema":            # the render above
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.9, 0.68)), 0.18)
		"losa":             # the balconies' slabs
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.98, 0.94, 0.86)), 0.14)
		"medianera":
			m = Tex.mat("painted_plaster_wall", Color(0.8, 0.76, 0.68))
		"espejo":           # the windows' mirror glass: nothing shows through it; a warm light in it while the clinic is open
			var gm := StandardMaterial3D.new()
			gm.albedo_color = Color(0.2, 0.3, 0.33)
			gm.metallic = 0.5
			gm.roughness = 0.1
			gm.emission_enabled = true
			gm.emission = Color(1.0, 0.93, 0.78)
			gm.emission_energy_multiplier = 0.0
			_lit.append([gm, 0.07])
			m = gm
		"puerta":           # the glass of the clinic's door, darker
			var dm := StandardMaterial3D.new()
			dm.albedo_color = Color(0.13, 0.19, 0.21)
			dm.metallic = 0.3
			dm.roughness = 0.14
			dm.emission_enabled = true
			dm.emission = Color(1.0, 0.93, 0.78)
			dm.emission_energy_multiplier = 0.0
			_lit.append([dm, 0.06])
			m = dm
		"rotulo_largo", "rotulo_corto", "doctor", "logo":       # the raised letters: lit from above by night
			var pm := StandardMaterial3D.new()
			pm.albedo_texture = load(DIR + name_ + ".png")
			pm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			pm.alpha_scissor_threshold = 0.5
			pm.roughness = 0.5
			pm.emission_enabled = true
			pm.emission = Color(1.0, 0.95, 0.85)
			pm.emission_texture = pm.albedo_texture
			pm.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			pm.emission_energy_multiplier = 0.0
			_floodlit.append(pm)
			m = pm
		"vinilo", "vinilo2":                                    # the words stuck on the mirror glass
			var vm := StandardMaterial3D.new()
			vm.albedo_texture = load(DIR + name_ + ".png")
			vm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			vm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			vm.roughness = 0.6
			m = vm
		"placa_arcos":
			var tm := StandardMaterial3D.new()
			tm.albedo_texture = load(DIR + name_ + ".png")
			tm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			tm.roughness = 0.85
			m = tm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world, _hd: Dictionary) -> void:
	W = world
	var on := _outward(X, NW)
	var oe := _outward(SE, X)
	level = MapData.height(X + (on + oe) * 0.7)
	transform = Transform3D(Basis.IDENTITY, Vector3(0.0, level, 0.0))
	W.add_child(self)
	wall_top = TOP
	eave_out = EAVE
	roof_pitch = PITCH
	roof_rise0 = RISE0
	var os := -_outward(SE, SW)                              # (the wall it shares to the south looks that way)
	_planes = [[on, X.dot(on)], [oe, X.dot(oe)], [os, SE.dot(os)]]      # the roof: a slope to each street, and one that falls to the back
	_north()
	_east()
	_corner_balcony()
	_party_wall(SE, SW)
	_party_wall(SW, NW)
	_roof_over([NW, X, SE, SW], [-EAVE, -EAVE, 0.0, 0.0])
	home()
	_commit()
	_ring_solids([NW, X, SE, SW], 9.0)
	door = _along(X, NW, 3.83) + on * 1.2
	house_door = _along(SE, X, 2.78) + oe * 1.2
	set_open(open_at(0, 12.0))

## whether the clinic is open then (day: 0 Monday ... 6 Sunday)
func open_at(day: int, hour: float) -> bool:
	var d := posmod(day, 7)
	if not HOURS.has(d):
		return false
	for h in HOURS[d]:
		if hour >= float(h[0]) and hour < float(h[1]):
			return true
	return false

## Open: a warm light in its mirror glass. Shut: none.
func set_open(on: bool) -> void:
	is_open = on
	for q in _lit:
		(q[0] as StandardMaterial3D).emission_energy_multiplier = float(q[1]) if on else 0.0

## Its letters by night: lit from above (0: daylight ... 1: night).
func set_night(k: float) -> void:
	night = clampf(k, 0.0, 1.0)
	for m: StandardMaterial3D in _floodlit:
		m.emission_energy_multiplier = 0.85 * night

func _process(_delta: float) -> void:
	var game = W.get_parent() if W != null else null
	if game != null and "clock" in game and "weekday" in game:
		var want: bool = open_at(int(game.weekday), float(game.clock))
		if want != is_open:
			set_open(want)
	var sky = game.get("sky_fx") if game != null else null
	if sky != null and "night" in sky:
		var k := smoothstep(0.15, 0.55, float(sky.night))
		if absf(k - night) > 0.01 or (k == 0.0) != (night == 0.0):
			set_night(k)

# ---------------- what the fronts share ----------------
## whether a spot of the front being built falls in one of its openings
func _in_hole(p: Vector2, holes: Array) -> bool:
	for r: Rect2 in holes:
		if r.grow(0.01).has_point(p):
			return true
	return false

## The dark stone's joints over a stretch of the front being built (its tiles TILE square), and the thin steel strips
## across it at the heights `strips`; neither crosses an opening.
func _stone_lines(x0: float, x1: float, holes: Array, strips: Array) -> void:
	var nx := int(ceil((x1 - x0) / TILE))
	var ny := int(ceil(STONE_TOP / TILE))
	for i in range(1, nx):                                   # (upright joints, tile by tile)
		var x := x0 + i * TILE
		for j in range(ny):
			var ya := j * TILE
			var yb := minf(STONE_TOP, ya + TILE)
			if not _in_hole(Vector2(x, (ya + yb) / 2.0), holes):
				box(x - 0.006, ya, 0.0, 0.012, yb - ya, 0.004, 0x2b1f1a)
	for j in range(1, ny):                                   # (level joints)
		var y := j * TILE
		for i in range(nx):
			var xa := x0 + i * TILE
			var xb := minf(x1, xa + TILE)
			if not _in_hole(Vector2((xa + xb) / 2.0, y), holes):
				box(xa, y - 0.006, 0.0, xb - xa, 0.012, 0.004, 0x2b1f1a)
	for y: float in strips:
		var n := int(ceil((x1 - x0) / 0.2))
		for i in range(n):
			var xa := x0 + (x1 - x0) * i / n
			var xb := x0 + (x1 - x0) * (i + 1) / n
			if not _in_hole(Vector2((xa + xb) / 2.0, y), holes):
				box(xa, y - 0.013, 0.0, xb - xa, 0.026, 0.014, STEEL)

## A window of mirror glass in its hole: a steel frame, a sill; `words`: what is stuck on it.
func _mirror_window(r: Rect2, words = null) -> void:
	openings += 1
	var z := -0.1
	pieces += 1
	quad(Vector3(r.position.x, r.position.y, z), Vector3(r.end.x, r.position.y, z), Vector3(r.end.x, r.end.y, z), Vector3(r.position.x, r.end.y, z), "espejo", Vector3(0, 0, 1))
	for q in [[r.position.x, r.position.y, 0.06, r.size.y], [r.end.x - 0.06, r.position.y, 0.06, r.size.y], [r.position.x, r.position.y, r.size.x, 0.06], [r.position.x, r.end.y - 0.06, r.size.x, 0.06]]:
		box(q[0], q[1], z - 0.02, q[2], q[3], 0.06, 0xc8c6c0)
	box(r.position.x - 0.03, r.position.y - 0.05, 0.0, r.size.x + 0.06, 0.05, 0.05, STEEL)
	if words != null:
		var h := r.size.y - 0.3
		var w := minf(r.size.x - 0.24, h * (1024.0 / 768.0 if String(words) == "vinilo" else 1.0))
		h = w / (1024.0 / 768.0 if String(words) == "vinilo" else 1.0)
		var cx := r.get_center().x
		var cy := r.get_center().y
		_picture(cx - w / 2.0, cx + w / 2.0, cy - h / 2.0, cy + h / 2.0, z + 0.006, words)

## A door or window of the floor above in its hole: white frame, dark glass, its white blind down `blind` of it.
func _white_opening(r: Rect2, blind: float) -> void:
	openings += 1
	var z := -DEEP + 0.08
	box(r.position.x, r.position.y, z - 0.05, r.size.x, r.size.y, 0.03, GLASS)
	for q in [[r.position.x, r.position.y, 0.07, r.size.y], [r.end.x - 0.07, r.position.y, 0.07, r.size.y], [r.position.x, r.position.y, r.size.x, 0.08], [r.position.x, r.end.y - 0.07, r.size.x, 0.07]]:
		box(q[0], q[1], z - 0.02, q[2], q[3], 0.06, WHITE)
	if r.size.x > 0.8:
		box(r.get_center().x - 0.03, r.position.y, z - 0.02, 0.06, r.size.y, 0.065, WHITE)
	if blind > 0.0:
		var drop := r.size.y * blind
		var zb := -0.1
		box(r.position.x + 0.03, r.end.y - drop, zb, r.size.x - 0.06, drop, 0.025, 0xeceae2)
		for i in range(1, int(drop / 0.09)):
			box(r.position.x + 0.03, r.end.y - i * 0.09, zb + 0.025, r.size.x - 0.06, 0.012, 0.005, 0xd2d0c8)
	box(r.position.x, r.end.y - 0.18, -0.15, r.size.x, 0.18, 0.15, WHITE)          # (the blind's box)

## a balcony's slab on the front being built: cream, thick, a line of red tile under its edge
func _slab(x0: float, x1: float, out: float) -> void:
	box(x0, F1 - 0.24, 0.0, x1 - x0, 0.24, out, "losa")
	box(x0 - 0.02, F1 - 0.07, 0.0, x1 - x0 + 0.04, 0.07, out + 0.03, "losa")
	box(x0 - 0.01, F1 - 0.27, out - 0.03, x1 - x0 + 0.02, 0.03, 0.045, 0xa8523c)             # (the line of red tile under its edge)
	for x in [x0 - 0.01, x1 - 0.035]:
		box(x, F1 - 0.27, 0.0, 0.045, 0.03, out - 0.03, 0xa8523c)

## A balcony of wrought iron, a dark sheet behind its scrolls (the two on the Calle Cervantes, the one on the Arcos).
func _iron_balcony(x0: float, x1: float) -> void:
	balconies += 1
	var out := BALC_OUT
	_slab(x0, x1, out)
	var y := F1
	var z := out - 0.05
	box(x0 + 0.04, y + 0.04, z - 0.03, x1 - x0 - 0.08, 0.98, 0.008, 0x1c1c20)      # (the sheet)
	box(x0 + 0.02, y + 1.02, z - 0.025, x1 - x0 - 0.04, 0.04, 0.05, SHEET)
	box(x0 + 0.02, y + 0.03, z - 0.012, x1 - x0 - 0.04, 0.024, 0.024, SHEET)
	var n := maxi(3, int((x1 - x0) / 0.3))
	for k in range(n):                                         # (the scrolls: two rows of crossed bars, an upright between each pair)
		var a := x0 + 0.04 + (x1 - x0 - 0.08) * k / n
		var b := x0 + 0.04 + (x1 - x0 - 0.08) * (k + 1) / n
		for row in range(2):
			var ya := y + 0.05 + row * 0.485
			bar(Vector3(a, ya, z), Vector3(b, ya + 0.485, z), 0.016, 0.016, 0x3a3a40)
			bar(Vector3(a, ya + 0.485, z), Vector3(b, ya, z), 0.016, 0.016, 0x3a3a40)
		box(a - 0.009, y + 0.03, z - 0.009, 0.018, 1.0, 0.018, SHEET)
	box(x1 - 0.049, y + 0.03, z - 0.009, 0.018, 1.0, 0.018, SHEET)
	for x in [x0 + 0.03, x1 - 0.03]:                           # (its sides)
		box(x - 0.004, y + 0.04, 0.02, 0.008, 0.98, out - 0.07, 0x1c1c20)
		box(x - 0.02, y + 1.02, 0.0, 0.04, 0.04, out, SHEET)

## a run of the corner balcony's railing on the front being built, from x0 to x1 at `out` from the wall: dark sheet
## with upright ribs, a rail on it, a post at each end
func _sheet_rail(x0: float, x1: float, out: float) -> void:
	var y := F1
	var z := out - 0.05
	box(x0, y + 0.06, z - 0.012, x1 - x0, 1.02, 0.012, SHEET)
	var n := maxi(2, int(round((x1 - x0) / 0.13)))
	for k in range(n + 1):
		box(lerpf(x0, x1 - 0.02, float(k) / n), y + 0.06, z, 0.02, 1.02, 0.012, 0x34343a)
	box(x0, y + 1.08, z - 0.03, x1 - x0, 0.045, 0.06, 0x1e1e22)
	box(x0, y + 0.02, z - 0.02, x1 - x0, 0.04, 0.035, 0x1e1e22)

## The long balcony round the corner: its slab along both fronts, its railing of ribbed dark sheet.
func _corner_balcony() -> void:
	balconies += 1
	var on := _outward(X, NW)
	var oe := _outward(SE, X)
	var e := _miter(oe, on, 1.0)                               # (per metre of standing out, to meet round the corner)
	face(X, NW)                                                # the Calle Cervantes's part: from the corner to 4.6 m along
	_slab(-e * CORNER_OUT, 4.6, CORNER_OUT)
	_sheet_rail(-e * (CORNER_OUT - 0.05), 4.6, CORNER_OUT)
	box(4.56, F1 + 0.06, 0.0, 0.012, 1.02, CORNER_OUT - 0.05, SHEET)        # (its end)
	box(4.54, F1 + 1.08, 0.0, 0.05, 0.045, CORNER_OUT, 0x1e1e22)
	home()
	var le := face(SE, X)                                      # the Arcos's part: the last 3.3 m before the corner
	_slab(le - 3.27, le + e * CORNER_OUT, CORNER_OUT)
	_sheet_rail(le - 3.27, le + e * (CORNER_OUT - 0.05), CORNER_OUT)
	box(le - 3.27, F1 + 0.06, 0.0, 0.012, 1.02, CORNER_OUT - 0.05, SHEET)
	box(le - 3.28, F1 + 1.08, 0.0, 0.05, 0.045, CORNER_OUT, 0x1e1e22)
	home()

# ---------------- the front to the Calle Cervantes (north) ----------------
func _north() -> void:
	var L := face(X, NW)
	var e0 := _miter(_outward(SE, X), _outward(X, NW), 1.0)
	var louvre := Rect2(1.69, 0.1, 1.53, 1.97)                  # the plant room's doors
	var entry := Rect2(3.3, -0.3, 1.06, HEAD + 0.3)            # the clinic's door, set back
	var big := Rect2(5.43, SILL, 2.44, HEAD - SILL)
	var small := Rect2(9.03, SILL, 2.24, HEAD - SILL)
	var low: Array = [louvre, entry, big, small]
	var ups: Array = [Rect2(0.9, F1, 1.5, DOOR_H), Rect2(3.25, F1, 0.9, DOOR_H), Rect2(6.1, F1, 1.0, DOOR_H), Rect2(10.05, F1, 1.0, DOOR_H)]
	masonry(0.0, L, -0.7, STONE_TOP, low, [], "piedra_oscura")
	masonry(0.0, L, STONE_TOP, TOP, ups, [], "crema")
	_stone_lines(0.0, L, low, [0.72, 2.84])
	box(-e0 * 0.05, STONE_TOP - 0.02, 0.0, L + e0 * 0.05, 0.12, 0.05, "losa")      # (where the stone ends)
	# the plant room's louvred doors: two grey leaves of slats
	openings += 1
	box(louvre.position.x, louvre.position.y, -0.1, louvre.size.x, louvre.size.y, 0.03, 0x6f7478)
	for k in range(2):
		var a := louvre.position.x + 0.03 + k * (louvre.size.x / 2.0)
		var w := louvre.size.x / 2.0 - 0.06
		for q in [[a, louvre.position.y, 0.05, louvre.size.y], [a + w - 0.05, louvre.position.y, 0.05, louvre.size.y], [a, louvre.position.y, w, 0.05], [a, louvre.end.y - 0.05, w, 0.05]]:
			box(q[0], q[1], -0.07, q[2], q[3], 0.05, 0x8f9498)
		for i in range(int((louvre.size.y - 0.1) / 0.065)):
			box(a + 0.05, louvre.position.y + 0.06 + i * 0.065, -0.075, w - 0.1, 0.04, 0.03, 0x9da2a6)
	# the clinic's door: glass in a steel frame, a green stroke across it, a fanlight over it; its mat
	openings += 1
	var z := -DEEP + 0.04
	box(entry.position.x, -0.3, -DEEP, entry.size.x, 0.3 + 0.03, DEEP, 0x4a4442)
	pieces += 1
	quad(Vector3(entry.position.x, 0.03, z), Vector3(entry.end.x, 0.03, z), Vector3(entry.end.x, HEAD, z), Vector3(entry.position.x, HEAD, z), "puerta", Vector3(0, 0, 1))
	for q in [[entry.position.x, 0.03, 0.06, HEAD - 0.03], [entry.end.x - 0.06, 0.03, 0.06, HEAD - 0.03], [entry.position.x, HEAD - 0.06, entry.size.x, 0.06], [entry.position.x, 2.13, entry.size.x, 0.06], [entry.position.x, 0.03, entry.size.x, 0.1]]:
		box(q[0], q[1], z - 0.02, q[2], q[3], 0.06, 0xc8c6c0)
	pieces += 1
	quad(Vector3(entry.position.x + 0.08, 0.45, z + 0.008), Vector3(entry.end.x - 0.08, 1.7, z + 0.008), Vector3(entry.end.x - 0.08, 1.88, z + 0.008), Vector3(entry.position.x + 0.08, 0.63, z + 0.008), 0x78be3c, Vector3(0, 0, 1))
	box(entry.end.x - 0.2, 0.95, z + 0.04, 0.03, 0.4, 0.03, 0xb8b8b4)
	box(entry.end.x + 0.18, 1.25, 0.0, 0.16, 0.26, 0.02, 0xb8b8b4)                # (the entry phone, on the stone)
	_mirror_window(big, "vinilo")
	_mirror_window(small, "vinilo2")
	# the name in raised letters, the doctor's under it; the mark by the corner
	_picture(3.6, 8.4, 3.12, 3.72, 0.03, "rotulo_largo")
	_picture(7.05, 8.75, 2.88, 3.09, 0.02, "doctor")
	_picture(0.4, 1.3, 1.7, 2.6, 0.02, "logo")
	for x in [4.6, 7.4]:                                         # (the lamps that light the letters: black, on little arms)
		box(x - 0.012, STONE_TOP - 0.1, 0.0, 0.024, 0.024, 0.3, 0x1a1a1c)
		box(x - 0.07, STONE_TOP - 0.19, 0.24, 0.14, 0.1, 0.1, 0x1a1a1c)
	# above: the doors of the corner's balcony, two balconies of wrought iron
	var blinds := [0.45, 1.0, 0.25, 0.6]
	for i in range(ups.size()):
		_white_opening(ups[i], blinds[i])
	_iron_balcony(5.55, 7.65)
	_iron_balcony(9.45, 11.65)
	_eaves(L, e0 * EAVE, 0.0, 0.34)
	home()

# ---------------- the front to the Calle de los Arcos (east) ----------------
func _east() -> void:
	var L := face(SE, X)
	var e1 := _miter(_outward(SE, X), _outward(X, NW), 1.0)
	var split := 4.24                                           # where the cream tiles end and the dark stone begins
	var gate := Rect2(2.14, -0.3, 1.27, 2.85 + 0.3)             # the house's own doorway
	var win := Rect2(5.33, SILL, 2.39, HEAD - SILL)
	var low: Array = [gate, win]
	var ups: Array = [Rect2(2.05, F1, 1.1, DOOR_H), Rect2(4.47, F1 + 1.0, 0.6, 0.75), Rect2(6.4, F1, 1.4, DOOR_H)]
	masonry(0.0, L, -0.7, STONE_TOP, low, [Rect2(0.0, -0.7, split, STONE_TOP + 0.7)], "piedra_oscura", "azulejo")
	masonry(0.0, L, STONE_TOP, TOP, ups, [], "crema")
	_stone_lines(split, L, low, [0.72, 2.84])
	box(0.0, STONE_TOP - 0.02, 0.0, L + e1 * 0.05, 0.12, 0.05, "losa")
	# the cream tiles: their joints; the grey granite piers of the doorway and its lintel
	for i in range(1, int(split / 0.42) + 1):
		var x := i * 0.42
		if x < 1.11:
			box(x - 0.004, 0.0, 0.0, 0.008, STONE_TOP, 0.003, 0xbdb6a6)
		elif x < split:
			box(x - 0.004, 2.98, 0.0, 0.008, STONE_TOP - 2.98, 0.003, 0xbdb6a6)
	for y in [0.62, 1.24, 1.86, 2.48]:
		box(0.0, y - 0.004, 0.0, 1.11, 0.008, 0.003, 0xbdb6a6)
	box(0.0, 3.36, 0.0, split, 0.008, 0.003, 0xbdb6a6)
	box(1.11, -0.7, 0.0, gate.position.x - 1.11, 0.7 + 2.98, 0.04, "granite")
	box(gate.end.x, -0.7, 0.0, split - gate.end.x, 0.7 + 2.98, 0.04, "granite")
	box(gate.position.x, 2.85, 0.0, gate.size.x, 0.13, 0.04, "granite")
	_house_door(gate)
	box(1.72, 1.2, 0.04, 0.2, 0.3, 0.07, 0x2a2a2c)                                 # (its letter box)
	box(3.62, 0.95, 0.04, 0.5, 0.36, 0.05, 0xe8e2d2)                               # (the meters' little door)
	box(3.68, 1.01, 0.09, 0.16, 0.24, 0.004, 0x9a968c)
	box(3.9, 1.01, 0.09, 0.16, 0.24, 0.004, 0x9a968c)
	# the dark stone: a flush hatch, the window, the name in two lines over it, the street's tile by the corner
	for q in [[4.61, 1.0, 0.5, 0.02], [4.61, 1.53, 0.5, 0.02], [4.61, 1.0, 0.02, 0.55], [5.09, 1.0, 0.02, 0.55]]:
		box(q[0], q[1], 0.0, q[2], q[3], 0.012, STEEL)
	_mirror_window(win)
	_picture(5.5, 7.5, 2.87, 2.87 + 2.0 * 512.0 / 1216.0, 0.03, "rotulo_corto")
	_picture(8.3, 8.82, 3.2, 3.6, 0.012, "placa_arcos")
	box(6.5 - 0.012, STONE_TOP - 0.1, 0.0, 0.024, 0.024, 0.3, 0x1a1a1c)             # (the lamp that lights the letters)
	box(6.5 - 0.07, STONE_TOP - 0.19, 0.24, 0.14, 0.1, 0.1, 0x1a1a1c)
	# above: a balcony of wrought iron, a little window on a sill of red brick, the door of the corner's balcony
	_white_opening(ups[0], 0.35)
	_iron_balcony(1.5, 3.7)
	_white_opening(ups[1], 0.5)
	box(4.41, F1 + 0.93, 0.0, 0.72, 0.07, 0.07, 0xb5563c)
	_white_opening(ups[2], 0.3)
	_eaves(L, 0.0, e1 * EAVE, 0.34)
	home()

## The house's own doorway on the Arcos: a dark hall behind a pink curtain that hangs from a rail, a grille of wooden
## bars over it.
func _house_door(r: Rect2) -> void:
	openings += 1
	box(r.position.x, -0.3, -DEEP, r.size.x, 0.3 + 0.04, DEEP, 0x8a8680)                # (its step)
	box(r.position.x, 0.04, -DEEP - 0.02, r.size.x, r.end.y - 0.04, 0.02, 0x241c18)     # (the hall behind)
	var top := 2.42
	for i in range(int(r.size.x / 0.09)):                                             # (the grille of wooden bars over it)
		box(r.position.x + 0.03 + i * 0.09, top + 0.03, -0.2, 0.04, r.end.y - top - 0.03, 0.04, 0x6a4630)
	box(r.position.x, top, -0.22, r.size.x, 0.05, 0.08, 0x6a4630)
	var x0 := r.position.x + 0.03
	var x1 := r.end.x - 0.03
	var n := 12
	for i in range(n):                                                                # (the curtain: folds)
		var a := lerpf(x0, x1, float(i) / n)
		var b := lerpf(x0, x1, float(i + 1) / n)
		var za := -0.2 + (0.03 if i % 2 == 0 else -0.01)
		var zb := -0.2 + (-0.01 if i % 2 == 0 else 0.03)
		pieces += 1
		quad(Vector3(a, 0.06, za), Vector3(b, 0.06, zb), Vector3(b, top, zb), Vector3(a, top, za), 0xdba091 if i % 2 == 0 else 0xcf9384, Vector3(0, 0, 1))
