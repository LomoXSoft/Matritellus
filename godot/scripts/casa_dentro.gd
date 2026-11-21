extends "res://scripts/obra.gd"
## Inside the house you inherit, Calle de Alemania 5 (the user, 16 November 2026: "La puerta de nuestra casa pasará a
## ser un acceso a interiores. De momento una habitación cuadrada básica con una cama y un armario, la cama para dormir
## y el armario para cambiar las pintas"; and "Que aparezca en la pared de detrás el grafiti de la peña que tengas
## seleccionada, así habrá un indicador visual").
##
## A set built far out in the fields, like the shops' (vipshop.gd, rocas.gd): the green arrow at the door takes you in
## (entradas.gd), the one inside takes you out with the action button. What a place you go into has to give
## (game.gd _use_door): `door_out`, `out_spawn`, `out_h` on the street; `in_door`, `in_spawn` in the set; `open` (true:
## it is your house, it is always open).
##
## The room: a square of 6 m, +z deeper in, the street door at z = 0, y = 0 its floor. An old Manchego room: lime-washed
## walls over a band of añil blue, a floor of fired clay tiles, the beams of the ceiling showing, one bare bulb. The bed
## against the back wall with your peña's graffiti over it; the wardrobe on the left as you come in; a bedside table and
## a rug. The bed, the table and the wardrobe are Kenney's "Furniture Kit" (CC0; assets/casa/CREDITOS.txt), readied by
## tools/creador/muebles_casa.py.

const PropsS = preload("res://scripts/props.gd")
const Casas = preload("res://scripts/casas.gd")
const Creator = preload("res://scripts/creator.gd")
const EstadoS = preload("res://scripts/casa_estado.gd")   # the house after each of its works (states 1 to 5; this room is state 0)

const INSIDE := Vector2(-1800.0, -1450.0)       # where the set is (V.I.P.'s at (1800, -1350), the Recress's at (-1500, -1650), the Rocas's at (-1800, -1800): 350 m away)
const HALF := 3.0                               # half its width
const D := 6.0                                  # how deep it is
const TALL := 2.8
const DIR := "res://assets/casa/"
const ROCAS := "res://assets/rocas/"
const BED := Vector3(-0.7, 0.0, D)              # the middle of the bed's head, against the back wall (where the camera by the door looks)
const BED_W := 1.74                             # how wide the bed is (the late Eufrasia's: a double)
const BED_L := 2.05                             # ...and how long
const WARDROBE := Vector3(-HALF, 0.0, 3.3)      # the middle of the wardrobe's back, against the left wall
const WARDROBE_W := 1.9
const TAG_MID := Vector3(-0.7, 1.62, D)         # the middle of the graffiti on the back wall, over the bed (low enough for the camera by the door to take it in)
const TAG_H := 1.3                              # how tall it is painted

var door_out: Vector2           # the door on the street
var out_spawn: Vector2          # where you stand when you come out
var out_h := 0.0
var in_door: Vector2            # the same door seen from inside
var in_spawn: Vector2
var open := true                # (your own house: always)
var bed_spot: Vector2           # by the bed, where you lie down from
var wardrobe_spot: Vector2      # in front of the wardrobe
var props := 0                  # how many pieces of the kit were set out
var state := 0                  # which of its six states it is in (set_state): 0 as inherited ... 5 with its upper floor
var estados: Array = []         # the house after each work (casa_estado.gd), states 1 to 5 in order
var back_door := Vector2.ZERO   # state 5: before the door at the back, in the room (ZERO in the others)
var back_spawn := Vector2.ZERO  # state 5: at the top of the stairs behind it, on the upper floor
var _base_meshes: Array = []    # this room's own walls, floor and ceiling (the house as inherited): hidden from state 1 on
var pena := -1                  # whose graffiti is on the wall now
var G
var _tag: MeshInstance3D
var _tag_mat: ShaderMaterial
var _tag_tex: Array = []
var _check := 0.0
var _front: MeshInstance3D           # your peña's graffiti on the front of the house, over the door
var _front_wait := 0

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: StandardMaterial3D = null
	match (String(key) if key is String else ""):
		"cal":              # lime wash
			m = _lit(Color(0.97, 0.97, 0.96), 0.22)
		"anil":             # the band of añil blue round the foot of the walls
			m = _lit(Color(0.2, 0.33, 0.62), 0.18)
		"techo":
			m = _lit(Color(0.96, 0.96, 0.95), 0.3)
		"viga":
			m = _lit(Color(0.36, 0.25, 0.16), 0.12)
		"barro":            # fired clay tiles, two tones
			var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
			img.set_pixel(0, 0, Parts.col(0xb4643e)); img.set_pixel(1, 1, Parts.col(0xb4643e))
			img.set_pixel(1, 0, Parts.col(0xa6593a)); img.set_pixel(0, 1, Parts.col(0xa6593a))
			m = StandardMaterial3D.new()
			m.albedo_texture = ImageTexture.create_from_image(img)
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE / 0.66
			m.roughness = 1.0
			m.emission_enabled = true
			m.emission = Color(0.7, 0.4, 0.26)
			m.emission_energy_multiplier = 0.12
		"bombilla":
			m = _lit(Color(1.0, 0.95, 0.8), 3.0)
		"dia":              # the day through the window: all light
			m = _lit(Color(0.86, 0.93, 1.0), 1.4)
		_:
			return super(key)
	_mats[key] = m
	return m

func _lit(c: Color, how: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = how
	return m

## `game` (for the peña on the wall), the world; then the door on the street, where you come out to and which way you
## face there
func build(game, world, at: Vector2, out: Vector2, heading: float) -> void:
	G = game
	W = world
	door_out = at
	out_spawn = out
	out_h = heading
	var top := -1e9                                  # its floor is a deck at one height, whatever the field under it does
	for dx in range(-int(HALF) - 2, int(HALF) + 3):
		for dz in range(-2, int(D) + 3):
			top = maxf(top, MapData.height(INSIDE + Vector2(dx, dz)))
	level = top + 0.03
	var deck := PackedVector2Array([INSIDE + Vector2(-HALF - 0.6, -0.6), INSIDE + Vector2(HALF + 0.6, -0.6), INSIDE + Vector2(HALF + 0.6, D + 0.6), INSIDE + Vector2(-HALF - 0.6, D + 0.6)])
	MapData.decks.append({"o": INSIDE + Vector2(0.0, D / 2.0), "poly": deck, "r2": (HALF + 2.0) * (HALF + 2.0) + (D / 2.0 + 2.0) * (D / 2.0 + 2.0), "top": level})
	_state_decks()
	transform = Transform3D(Basis.IDENTITY, Vector3(INSIDE.x, level, INSIDE.y))
	W.add_child(self)
	in_door = INSIDE + Vector2(0.0, 0.45)
	in_spawn = INSIDE + Vector2(0.0, 1.8)
	bed_spot = INSIDE + Vector2(BED.x + BED_W / 2.0 + 0.6, BED.z - 1.3)          # (on the rug, on the side of the room)
	wardrobe_spot = INSIDE + Vector2(WARDROBE.x + 0.62 + 0.75, WARDROBE.z)
	_shell()
	_furniture()
	_bulb()
	home()
	_commit()
	for c in get_children():                         # (what was just made into meshes: the room as inherited)
		if c is MeshInstance3D:
			_base_meshes.append(c)
	_graffiti()
	_indoors(self)
	_states()
	set_pena(int(G.look_sel[11]) if G != null and G.get("look_sel") != null and G.look_sel.size() > 11 else 0)

## whose graffiti is on the back wall: the peña you have chosen (it follows the creator, and a loaded game)
func _process(dt: float) -> void:
	if _front == null and _front_wait < 100:
		_front_wait += 1
		if _front_wait > 3:                     # (a few frames in, once the town's walls are solid: its wall is found by a ray)
			_front_tag()
	_check -= dt
	if _check > 0.0 or G == null:
		return
	_check = 0.5
	var mine: int = int(G.look_sel[11]) if G.look_sel.size() > 11 else 0
	if mine != pena:
		set_pena(mine)
	if _mats.has("dia"):                             # the window: day outside, or night
		var hour: float = float(G.get("clock")) if G.get("clock") != null else 12.0
		var day: float = clampf(minf(hour - 6.5, 21.0 - hour), 0.0, 1.0)
		var m: StandardMaterial3D = _mats["dia"]
		var c := Color(0.08, 0.1, 0.2).lerp(Color(0.86, 0.93, 1.0), day)
		if not m.albedo_color.is_equal_approx(c):
			m.albedo_color = c
			m.emission = c
			m.emission_energy_multiplier = lerpf(0.3, 1.4, day)

func set_pena(i: int) -> void:
	pena = clampi(i, 0, Creator.PENA_IDS.size() - 1)
	if _tag == null:
		return
	var tex: Texture2D = _tag_tex[pena]
	_tag_mat.set_shader_parameter("logo", tex)
	var w: float = TAG_H * float(tex.get_width()) / float(tex.get_height())
	(_tag.mesh as QuadMesh).size = Vector2(w, TAG_H)
	if _front != null:
		_front_size()

# ---------------- the house's six states ----------------
## The floors of the house once it has grown (the user's works, through Sistemas, 21 November 2026): the stairs behind
## the back door, the upper floor at their top (further back, not overhead: two floors cannot share a spot), and the
## ground floor of all its rooms. They are there from the start; the walls of each state say how far you get.
func _state_decks() -> void:
	var st: Rect2 = EstadoS.STAIRS
	var up: Rect2 = EstadoS.UPPER
	var a := INSIDE + st.position + Vector2(-0.1, -0.1)
	MapData.decks.append({"o": INSIDE + st.position, "poly": PackedVector2Array([a, a + Vector2(st.size.x + 0.2, 0), a + Vector2(st.size.x + 0.2, st.size.y + 0.2), a + Vector2(0, st.size.y + 0.2)]),
		"r2": st.size.length_squared() + 4.0, "top": level, "grad": Vector2(0.0, EstadoS.UP / st.size.y)})
	var b := INSIDE + up.position + Vector2(-0.6, -0.3)
	MapData.decks.append({"o": b, "poly": PackedVector2Array([b, b + Vector2(up.size.x + 1.2, 0), b + Vector2(up.size.x + 1.2, up.size.y + 0.9), b + Vector2(0, up.size.y + 0.9)]),
		"r2": (up.size + Vector2(2, 2)).length_squared(), "top": level + EstadoS.UP})
	var g := INSIDE + Vector2(EstadoS.LEFT.position.x - 0.6, -0.6)
	var gw: float = EstadoS.RIGHT.end.x + 0.6 - (EstadoS.LEFT.position.x - 0.6)
	MapData.decks.append({"o": g, "poly": PackedVector2Array([g, g + Vector2(gw, 0), g + Vector2(gw, D + 1.2), g + Vector2(0, D + 1.2)]), "r2": gw * gw + 80.0, "top": level})

## the five houses after their works, built once in this same place and hidden; then the house as inherited
func _states() -> void:
	var lend := {"dia": _material("dia"), "solids": [
		[Vector3(BED.x, 0.3, BED.z - BED_L / 2.0), Vector3(BED_W, 0.6, BED_L)],
		[Vector3(BED.x + BED_W / 2.0 + 0.4, 0.3, D - 0.3), Vector3(0.5, 0.6, 0.5)],
		[Vector3(WARDROBE.x + 0.31, 1.0, WARDROBE.z), Vector3(0.62, 2.0, WARDROBE_W)]]}
	for n in range(1, 6):
		var e = EstadoS.new()
		e.build(W, transform, n, lend)
		estados.append(e)
	state = -1
	set_state(0)

## Which of its six states the house is in (Sistemas: G.stats["casa"]["estado"], on loading a game and the morning a
## work is done): 0 as inherited (this room) · 1 done up · 2 enlarged · 3 a bathroom on the left · 4 a sitting room on
## the right · 5 an upper floor behind the door at the back. The bed, the wardrobe, the street door and the graffiti
## over the bed are where they were in all of them.
func set_state(n: int) -> void:
	n = clampi(n, 0, 5)
	if n == state:
		return
	state = n
	for m in _base_meshes:
		(m as MeshInstance3D).visible = n == 0
	if body != null:
		body.collision_layer = 1 if n == 0 else 0
	for i in range(estados.size()):
		var e = estados[i]
		var on: bool = i + 1 == n
		e.visible = on
		if e.body != null:
			(e.body as StaticBody3D).collision_layer = 1 if on else 0
	if n >= 5:
		back_door = INSIDE + Vector2((EstadoS.BACK_DOOR.x + EstadoS.BACK_DOOR.y) / 2.0, D - 0.7)
		back_spawn = INSIDE + Vector2((EstadoS.BACK_DOOR.x + EstadoS.BACK_DOOR.y) / 2.0, EstadoS.UPPER.position.y + 1.0)
	else:
		back_door = Vector2.ZERO
		back_spawn = Vector2.ZERO

## the rooms of the house as it is now: [name, x0, x1, z0, z1, the floor's height, the wall the camera hangs on]
func rooms() -> Array:
	if state >= 1 and state <= estados.size():
		return estados[state - 1].rooms()
	return [["sala", -HALF, HALF, 0.0, D, 0.0, "z0"]]

## the room you are in, for entradas.gd's camera (the house has several once it has grown): the middle of the wall the
## camera hangs on, which way it looks, how big the room is
func room_at(pp: Vector2) -> Dictionary:
	var p := pp - INSIDE
	var best: Array = []
	var bd := 1e9
	for r in rooms():
		var mid := Vector2((float(r[1]) + float(r[2])) / 2.0, (float(r[3]) + float(r[4])) / 2.0)
		var half := Vector2((float(r[2]) - float(r[1])) / 2.0, (float(r[4]) - float(r[3])) / 2.0)
		var q := (p - mid).abs() - half
		var d := maxf(q.x, q.y)
		if d < bd:
			bd = d
			best = r
	var x0: float = best[1]
	var x1: float = best[2]
	var z0: float = best[3]
	var z1: float = best[4]
	var fwd := Vector2(0, 1)
	var at := Vector2((x0 + x1) / 2.0, z0)
	var half_w := (x1 - x0) / 2.0
	var deep := z1 - z0
	match String(best[6]):
		"x0":
			fwd = Vector2(1, 0); at = Vector2(x0, (z0 + z1) / 2.0); half_w = (z1 - z0) / 2.0; deep = x1 - x0
		"x1":
			fwd = Vector2(-1, 0); at = Vector2(x1, (z0 + z1) / 2.0); half_w = (z1 - z0) / 2.0; deep = x1 - x0
	if String(best[0]) == "sala" and x1 - x0 > 2.0 * HALF + 0.5:      # (the enlarged room: the camera keeps to the side you are on)
		at.x = clampf(p.x, x0 + HALF, x1 - HALF)
		half_w = HALF
	return {"o": INSIDE + at, "fwd": fwd, "side": Vector2(-fwd.y, fwd.x), "half": half_w, "deep": deep, "tall": TALL, "name": String(best[0])}

## standing by the bed (a nap: game.gd _can_nap) / in front of the wardrobe
func bed_near(p: Vector2) -> bool:
	return p.distance_to(bed_spot) < 1.0 or _in_rect(p, Vector2(BED.x, BED.z - BED_L / 2.0), Vector2(BED_W / 2.0 + 0.75, BED_L / 2.0 + 0.6))

func wardrobe_near(p: Vector2) -> bool:
	return _in_rect(p, Vector2(WARDROBE.x + 0.95, WARDROBE.z), Vector2(0.75, WARDROBE_W / 2.0 + 0.25))

func _in_rect(p: Vector2, mid: Vector2, half: Vector2) -> bool:
	var q: Vector2 = p - INSIDE - mid
	return absf(q.x) <= half.x and absf(q.y) <= half.y

## indoors: the sun does not reach any of this (its cull mask in game.gd leaves this layer out)
func _indoors(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).layers = 1 << 10
	for c in n.get_children():
		_indoors(c)

# ---------------- the room ----------------
func _shell() -> void:
	const BAND := 0.95                               # how high the blue goes
	quad(Vector3(-HALF, 0, 0), Vector3(HALF, 0, 0), Vector3(HALF, 0, D), Vector3(-HALF, 0, D), "barro", Vector3.UP)
	quad(Vector3(-HALF, TALL, 0), Vector3(HALF, TALL, 0), Vector3(HALF, TALL, D), Vector3(-HALF, TALL, D), "techo", Vector3.DOWN)
	for band in [[0.0, BAND, "anil"], [BAND, TALL, "cal"]]:
		var y0: float = band[0]
		var y1: float = band[1]
		quad(Vector3(-HALF, y0, D), Vector3(HALF, y0, D), Vector3(HALF, y1, D), Vector3(-HALF, y1, D), band[2], Vector3(0, 0, -1))
		quad(Vector3(-HALF, y0, 0), Vector3(-HALF, y0, D), Vector3(-HALF, y1, D), Vector3(-HALF, y1, 0), band[2], Vector3(1, 0, 0))
		quad(Vector3(HALF, y0, 0), Vector3(HALF, y0, D), Vector3(HALF, y1, D), Vector3(HALF, y1, 0), band[2], Vector3(-1, 0, 0))
		quad(Vector3(-HALF, y0, 0), Vector3(HALF, y0, 0), Vector3(HALF, y1, 0), Vector3(-HALF, y1, 0), band[2], Vector3(0, 0, 1))
	for z in [0.0, D - 0.012]:                       # a thin dark line where the blue meets the white
		box(-HALF, BAND - 0.012, z, 2.0 * HALF, 0.024, 0.012, 0x1c2a52)
	for x in [-HALF, HALF - 0.012]:
		box(x, BAND - 0.012, 0.0, 0.012, 0.024, D, 0x1c2a52)
	# a small window on the right-hand wall, its green shutters open against the wall, the day outside
	const WZ0 := 2.75
	const WZ1 := 3.65
	const WY0 := 1.1
	const WY1 := 2.05
	quad(Vector3(HALF - 0.004, WY0, WZ0), Vector3(HALF - 0.004, WY0, WZ1), Vector3(HALF - 0.004, WY1, WZ1), Vector3(HALF - 0.004, WY1, WZ0), "dia", Vector3(-1, 0, 0))
	for b in [[WZ0 - 0.07, 0.07], [WZ1, 0.07], [(WZ0 + WZ1) / 2.0 - 0.025, 0.05]]:            # the frame's sides, and the middle where the two leaves meet
		box(HALF - 0.07, WY0, b[0], 0.07, WY1 - WY0, b[1], 0x5a3a22)
	box(HALF - 0.07, WY1, WZ0 - 0.07, 0.07, 0.07, WZ1 - WZ0 + 0.14, 0x5a3a22)
	box(HALF - 0.07, (WY0 + WY1) / 2.0, WZ0, 0.05, 0.04, WZ1 - WZ0, 0x5a3a22)
	box(HALF - 0.2, WY0 - 0.06, WZ0 - 0.1, 0.2, 0.06, WZ1 - WZ0 + 0.2, "cal")                     # the sill
	for z0 in [WZ0 - 0.5, WZ1 + 0.03]:                                                             # the shutters, open
		box(HALF - 0.04, WY0, z0, 0.03, WY1 - WY0, 0.47, 0x3f6b4a)
		for k in range(4):
			box(HALF - 0.045, WY0 + 0.12 + k * 0.22, z0 + 0.04, 0.008, 0.012, 0.39, 0x2c5038)
	# the street door, shut, seen from inside: its frame and its two boards' worth of leaf
	box(-0.62, 0.0, 0.0, 0.1, 2.25, 0.06, 0x4a2e1c)
	box(0.52, 0.0, 0.0, 0.1, 2.25, 0.06, 0x4a2e1c)
	box(-0.62, 2.15, 0.0, 1.24, 0.1, 0.06, 0x4a2e1c)
	box(-0.52, 0.0, 0.0, 1.04, 2.15, 0.035, 0x5a3a22)
	for k in range(4):
		box(-0.52 + 0.26 * k + 0.12, 0.05, 0.035, 0.012, 2.05, 0.008, 0x40281a)
	box(0.34, 1.0, 0.035, 0.05, 0.14, 0.04, 0x26262a)                                  # the latch
	box(-0.55, 0.0, 0.18, 1.1, 0.012, 0.6, 0x7a5a3a)                                  # the mat by it
	# the beams of the ceiling, across the room
	var z := 0.55
	while z < D:
		box(-HALF, TALL - 0.16, z - 0.07, 2.0 * HALF, 0.16, 0.14, "viga")
		z += 0.95
	# what stops you: the four walls and the ceiling
	solid(Vector3(0, TALL / 2.0, -0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	solid(Vector3(0, TALL / 2.0, D + 0.2), Vector3(2.0 * HALF + 0.8, TALL, 0.4))
	for sx in [-1.0, 1.0]:
		solid(Vector3(sx * (HALF + 0.2), TALL / 2.0, D / 2.0), Vector3(0.4, TALL, D + 0.8))
	solid(Vector3(0, TALL + 0.1, D / 2.0), Vector3(2.0 * HALF + 0.8, 0.2, D + 0.8))

func _furniture() -> void:
	# the bed, its head against the back wall
	var bed := _prop("mueble_bedDouble", Vector3(BED.x, 0.0, BED.z - BED_L / 2.0), 0.0, 0.0, BED_L)      # (the kit's bed has its head to +z)
	if bed == Vector2.ZERO:                          # (no model: a plain bed of boxes, so that there is something to sleep in)
		box(BED.x - BED_W / 2.0, 0.0, BED.z - BED_L, BED_W, 0.42, BED_L, 0x8a6a48)
		box(BED.x - BED_W / 2.0 + 0.04, 0.42, BED.z - BED_L + 0.04, BED_W - 0.08, 0.12, BED_L - 0.08, 0xf4f4f4)
	solid(Vector3(BED.x, 0.3, BED.z - BED_L / 2.0), Vector3(BED_W, 0.6, BED_L))
	# a bedside table by its head, a rug beside it
	_prop("mueble_cabinetBedDrawerTable", Vector3(BED.x + BED_W / 2.0 + 0.4, 0.0, D - 0.3), 0.55, PI)
	solid(Vector3(BED.x + BED_W / 2.0 + 0.4, 0.3, D - 0.3), Vector3(0.5, 0.6, 0.5))
	_prop("mueble_lampRoundTable", Vector3(BED.x + BED_W / 2.0 + 0.4, 0.55, D - 0.3), 0.42, PI)
	_prop("mueble_rugRounded", Vector3(BED.x + BED_W / 2.0 + 0.62, 0.004, D - 1.55), 0.0, PI / 2.0, 1.6)
	# the wardrobe, on the left as you come in, its doors to the room: two of the kit's tall cupboards side by side
	var wr := Vector2.ZERO
	for sz in [-1.0, 1.0]:
		wr = _prop("mueble_bookcaseClosedDoors", Vector3(WARDROBE.x + 0.31, 0.0, WARDROBE.z + sz * WARDROBE_W / 4.0), 2.05, PI / 2.0)
	if wr == Vector2.ZERO:
		box(WARDROBE.x, 0.0, WARDROBE.z - WARDROBE_W / 2.0, 0.6, 2.05, WARDROBE_W, 0x8a6a48)
	box(WARDROBE.x, 2.05, WARDROBE.z - WARDROBE_W / 2.0 - 0.02, 0.66, 0.06, WARDROBE_W + 0.04, 0x8a7a5e)        # a board along the top, joining them
	solid(Vector3(WARDROBE.x + 0.31, 1.0, WARDROBE.z), Vector3(0.62, 2.0, WARDROBE_W))

## the bare bulb in the middle of the ceiling, and the light it gives
func _bulb() -> void:
	bar(Vector3(0.0, TALL - 0.16, D / 2.0), Vector3(0.0, TALL - 0.62, D / 2.0), 0.012, 0.012, 0x1b1b1f)
	ball(Vector3(0.0, TALL - 0.7, D / 2.0), 0.07, "bombilla")
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0.0, TALL - 0.85, D / 2.0)
	lamp.light_color = Color(1.0, 0.95, 0.85)
	lamp.omni_range = 7.0
	lamp.light_energy = 0.7
	lamp.shadow_enabled = false
	add_child(lamp)
	var fill := OmniLight3D.new()                    # (and a little from where the camera stands, so faces are not in the dark)
	fill.position = Vector3(1.6, 2.2, 1.0)
	fill.light_color = Color(1.0, 1.0, 1.0)
	fill.omni_range = 6.0
	fill.light_energy = 0.3
	fill.shadow_enabled = false
	add_child(fill)

## your peña's logo, sprayed on the back wall over the bed (props.gd's graffiti shader: a little worn, as the town's)
func _graffiti() -> void:
	for id in Creator.PENA_IDS:
		_tag_tex.append(load("res://assets/penas/%s.png" % id))
	var sh := Shader.new()
	sh.code = PropsS.TAG_SHADER
	_tag_mat = ShaderMaterial.new()
	_tag_mat.shader = sh
	_tag_mat.set_shader_parameter("wear_tex", load("res://assets/penas/desgaste.png"))
	_tag_mat.set_shader_parameter("opacity", 0.95)
	_tag_mat.set_shader_parameter("wear", 0.35)
	_tag = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(TAG_H, TAG_H)
	_tag.mesh = q
	_tag.material_override = _tag_mat
	_tag.position = TAG_MID + Vector3(0.0, 0.0, -0.012)
	_tag.rotation.y = PI                             # (facing the door)
	_tag.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_tag)

# ---------------- your peña on the front of the house ----------------
## The same logo sprayed on the street front, over the door, always there (the user, 16 November 2026, when the easel
## of the creator went into the wall: "Que tal si ponemos el grafiti en la fachada de la casa, encima de la puerta. Así
## lo podemos dejar pues siempre. Que no cuente para el recuento de grafitis"). It is no wall of the town's (props.gd
## tags): nobody paints over it and it counts for nothing. It sits between the tile with your name over the lintel
## (padron.gd) and the eaves.
const HOME_HOUSE := "alemania_5"
const FRONT_MAX_W := 1.6                        # how wide it may be painted
const FRONT_OFF := 0.04                         # how far in front of the wall it is painted (enough for the wall never to show through)
var _front_out := 0.0
var _front_room := Vector2(1.2, 0.68)           # how much wall there is for it (across, up)
func _front_tag() -> void:
	var hd = null
	for h in MapData.houses:
		if String(h["id"]) == HOME_HOUSE:
			hd = h
	if hd == null or G == null:
		return
	var o := Vector2(hd["o"][0], hd["o"][1])
	var u := Vector2(hd["u"][0], hd["u"][1]).normalized()
	var base: float = float(hd.get("base", MapData.foot(o)))
	var door := o + u * 0.2 * float(hd["len"])
	var door_h := 2.1
	for op in (Casas.SPECS.get(HOME_HOUSE, {}).get("floors", [{}])[0] as Dictionary).get("open", []):
		if String(op[0]) == "door":
			door = o + u * float(op[1]) * float(hd["len"])
			door_h = float(op[3])
			break
	var out: Vector2 = (out_spawn - door_out).normalized()          # (to the street)
	var y0 := base + door_h + 0.34 + 0.17 + 0.06                    # (over the tile with your name)
	var y1 := base + float(hd.get("h", 3.5)) - 0.14                  # (under the eaves)
	_front_room = Vector2(FRONT_MAX_W, maxf(0.4, y1 - y0))
	var mid_y := (y0 + y1) / 2.0
	# How far out from the map's front line: in front of the wall AS DRAWN, whose face is the floor's "fly" out from that
	# line (casas.gd), and in front of what is solid. Until 17 Nov 2026 it went a hand's breadth out from the solid
	# wall, and once the houses' meshes were merged that was the drawn face itself: the wall hid it (the user: "el
	# grafiti de la peña no sale durante el creador de personajes").
	var out3 := Vector3(out.x, 0.0, out.y)
	var on_line := Vector3(door.x, mid_y, door.y)
	var fly := float((Casas.SPECS.get(HOME_HOUSE, {}).get("floors", [{}])[0] as Dictionary).get("fly", 0.0))
	_front_out = fly + FRONT_OFF
	var space: PhysicsDirectSpaceState3D = G.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(on_line + out3 * 3.0, on_line - out3 * 3.0, 1)
	var hit := space.intersect_ray(q)
	if not hit.is_empty():
		_front_out = maxf(_front_out, ((hit["position"] as Vector3) - on_line).dot(out3) + FRONT_OFF)
	_front_out -= fly                                               # (kept as how far it stands off the drawn face: the self-test)
	var at := on_line + out3 * (fly + _front_out)
	var m := ShaderMaterial.new()
	m.shader = _tag_mat.shader
	m.set_shader_parameter("wear_tex", load("res://assets/penas/desgaste.png"))
	m.set_shader_parameter("opacity", 0.93)
	m.set_shader_parameter("wear", 0.6)
	_front = MeshInstance3D.new()
	_front.mesh = QuadMesh.new()
	_front.material_override = m
	_front.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	G.add_child(_front)
	_front.global_position = at
	_front.rotation.y = atan2(out.x, out.y)                         # (its face to the street)
	_front_size()

func _front_size() -> void:
	var tex: Texture2D = _tag_tex[pena]
	(_front.material_override as ShaderMaterial).set_shader_parameter("logo", tex)
	var aspect := float(tex.get_width()) / float(tex.get_height())
	var tall := minf(_front_room.y, _front_room.x / aspect)
	(_front.mesh as QuadMesh).size = Vector2(tall * aspect, tall)

## (the self-test) the graffiti on the front: null until it is painted
func front_tag() -> MeshInstance3D:
	return _front

## (the self-test) how far it stands in front of the wall as drawn (m)
func front_clear() -> float:
	return _front_out

# ---------------- the kit's models ----------------
func _bounds(n: Node, xf: Transform3D, bx: Array) -> void:
	var here := xf
	if n is Node3D:
		here = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var ab: AABB = here * (n as MeshInstance3D).mesh.get_aabb()
		bx[0] = ab if bx[0] == null else (bx[0] as AABB).merge(ab)
	for c in n.get_children():
		_bounds(c, here, bx)

## the kit's materials made matt, with a little light of their own (as in the Rocas: it all stands indoors)
func _matt(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for si in range(mi.mesh.get_surface_count()):
			var m := mi.mesh.surface_get_material(si)
			if m is BaseMaterial3D:
				var d := (m as BaseMaterial3D).duplicate() as BaseMaterial3D
				d.metallic = 0.0
				d.roughness = 1.0
				d.metallic_specular = 0.0
				d.emission_enabled = true
				d.emission = d.albedo_color
				d.emission_energy_multiplier = 0.25
				mi.set_surface_override_material(si, d)
	for c in n.get_children():
		_matt(c)

## A model of the kit stood on `pos` (the middle of its foot), `tall` metres high (or, with `long`, that long along its
## longer side), turned `yaw` about the upright. Returns how wide and deep it came out (x, z, before turning).
func _prop(file: String, pos: Vector3, tall: float, yaw := 0.0, long := 0.0) -> Vector2:
	var path := DIR + file + ".glb"
	if not ResourceLoader.exists(path):
		path = ROCAS + file + ".glb"
		if not ResourceLoader.exists(path):
			return Vector2.ZERO
	var model: Node3D = (load(path) as PackedScene).instantiate()
	var bx: Array = [null]
	_bounds(model, Transform3D.IDENTITY, bx)
	if bx[0] == null:
		model.free()
		return Vector2.ZERO
	_matt(model)
	var ab: AABB = bx[0]
	var k := tall / maxf(ab.size.y, 0.001) if long <= 0.0 else long / maxf(maxf(ab.size.x, ab.size.z), 0.001)
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation.y = yaw
	var sized := Node3D.new()
	sized.scale = Vector3.ONE * k
	model.position = -Vector3(ab.position.x + ab.size.x / 2.0, ab.position.y, ab.position.z + ab.size.z / 2.0)
	sized.add_child(model)
	holder.add_child(sized)
	add_child(holder)
	props += 1
	return Vector2(ab.size.x, ab.size.z) * k
