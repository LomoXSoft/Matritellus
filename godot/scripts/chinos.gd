extends "res://scripts/obra.gd"
## The grocer's at the point where the Calle de San José and the Calle de Santo Domingo part ("los chinos del
## Arroyuelo", the user's words, 15 November 2026: "El siguiente será los chinos del arroyuelo. Texturas ha hecho una
## buena base pero tú vas más al detalle"; referencias/chinos_arroyuelo/, tools/chinos/).
##
## As Street View has it in November 2024 from the three streets round it: a wedge of red pressed brick, two floors,
## twenty metres long and three wide at its point, under a great flat eave with a rim of tiles. Between the floors, all
## round, a course of bricks stood on end. At the point, the shop: its carved wooden board ("ALIMENTACIÓN", and what it
## sells), a white awning, a glazed door of slanting bars beside the open one, a window full of toys, a column of
## posters; over it a balcony of brick with its iron rail, a window of four leaves under a green striped awning, and
## on the roof a cage of iron bars. Along San José: three barred windows on a foot of stone that grows as the street
## falls, a vent, the tall arched window of the stairs, and two folding gates of lattice. Along Santo Domingo: a gate
## of lattice, an iron door, the door of the house in embossed bronze-green metal, two arched windows, three barred
## ones and the shop's own, with its posters; air conditioners, meter boxes, cables. On the roof, a hut under a sheet
## of corrugated iron.
##
## It is the house `sanjose_1` of the map (casas_calles.gd marks it "obra": casas.gd draws nothing of it). Frame: the
## house's own -- origin at the north corner of the point, +x along the Calle de San José (west), +z out into it --
## but y = 0 is the slab between the floors (the foot of that course of bricks), which is level; the streets fall
## towards the point and every door stands on its own ground.
## Its sign says only what is sold, as the real one does. Nobody goes in. No people in it, and none of the two little
## statues of the real roof (the user: "Sin figuras en la azotea").
## It keeps hours (the user, the same day: "su horario comercial de 7:00-21:00 entre semana y de 6:00-2:00 fines de
## semana"; and, asked how it should shut: "Puertas abiertas y cerradas, luces encendidas y apagadas"): open, its
## second door leaf stands open and its lamps are lit; shut, both leaves are shut, every lamp is out and its metal
## shutter is down over the shop front (the user again, once he had seen it: "Deja otro par pegados torcidos en la
## verja metálica de cuando cierran": two more of his posters are stuck on that shutter, askew). And its awning ("Extendido
## al abrir y recogido al cerrar"): out while it is open, rolled up while it is shut.
## On its door, small and askew, the poster of an energy drink that does not exist, "Roster Energy": the user's own
## picture ("En la puerta suele tener posters de bebidas energéticas. He hecho este por si lo podemos poner en pequeño
## torcido en la puerta. Cámbialo un poco para que pegue con la estética del juego"), redrawn in flat colours by
## tools/chinos/poster.py.

const HOUSE := "sanjose_1"
const NAME := "ALIMENTACIÓN"
const DentroS = preload("res://scripts/chinos_dentro.gd")
const POSTER := "res://assets/chinos/poster_roster.png"         # the user's poster, redrawn by tools/chinos/poster.py
const SLAB_UP := 2.97                           # the slab over the street at the west end (measured: 2.96 to 2.99 m on both streets)
const TOP := 2.8                                # the top of the walls, over the slab
const BAND := 0.25                              # the course of bricks stood on end: a brick is 24 cm long
const SILL := 1.15                              # the upper windows: their sills...
const HEAD := 2.3                               # ...and their heads
const WIN_LO := -2.45                           # the ground floor's windows
const WIN_HI := -0.95
const FOOT := -2.5                              # the top of the foot of stone
const DOWN := -7.0                              # well under any ground
const EAVE := 0.6                               # how far the eave comes out
const RIM := 0.55                               # its rim of tiles
const BAL := 0.75                               # how far the balcony comes out at the point
const WHITE := 0xf1f0ea
const BLIND := 0xe4dcc6
const GLASS := 0x1f2a33
const BARS := 0x2a2a2e
const LATTICE := 0xa9adb0
const GOLD := 0xe6b64a
const WOODEN := 0x7a5230
const WEEK := Vector2(7.0, 21.0)                # Monday to Friday: from seven in the morning to nine at night
const WEEKEND := Vector2(6.0, 26.0)             # Saturday and Sunday: from six in the morning to two of the morning after

var len_n := 19.77              # the wall of San José
var len_s := 20.0               # the wall of Santo Domingo
var len_p := 3.1                # the point
var PN := Vector2.ZERO          # the plot's corners, in the frame: the point's north corner...
var PS: Vector2                 # ...its south one...
var WN: Vector2                 # ...and the west end, north, middle and south
var WM: Vector2
var WS: Vector2
var ds: Vector2                 # along Santo Domingo, towards the point
var ns: Vector2                 # out of that wall
var dp: Vector2                 # along the point, south to north
var np: Vector2                 # out of it
var PNb: Vector2                # the balcony's two outer corners
var PSb: Vector2
var door: Vector2               # in front of the shop's door, on the map
var tienda                      # its inside, a set apart (chinos_dentro.gd)
var posts: Array = []           # where the two road signs stand, on the map
var is_open := false
var poster := false              # whether the poster is on the door (its picture was found)
var on_shutter := 0             # how many more of them are stuck on the shutter
var _shut: Node3D               # what shows only while it is shut: the second door leaf shut, the shutter down with its posters, the awning rolled up
var _open: Node3D               # what shows only while it is open: that leaf swung in, the awning out, the lamps lit
var _lights: Array = []
var _sf := {}                   # the shop front's measures, kept for those two

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	var red := "brick_wall_003@1.15"                # (the town's facing brick: smooth and even, as pressed brick is; the red one of the old houses is too rough for it)
	var tint := Color(1.04, 0.76, 0.67)
	match (String(key) if key is String else ""):
		"ladrillo":         # red pressed brick
			m = Tex.mat(red, tint)
		"sardinel":         # the same brick stood on end (its UVs: metres, up the wall first)
			m = Tex.mat(red, tint, true, 1.0)
		"piedra":           # the foot of pale stone
			m = Tex.mat("granular_concrete", Color(1.24, 1.19, 1.07), false)
		"blanco":           # the eave's underside
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.985, 0.95)), 0.4)
		"medianera":        # the walls it shares with its neighbours
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.86, 0.82, 0.74)), 0.25)
		"interior":
			var im := StandardMaterial3D.new()
			im.albedo_color = Color(0.9, 0.86, 0.76)
			im.emission_enabled = true
			im.emission = Color(0.9, 0.84, 0.7)
			im.emission_energy_multiplier = 0.4
			m = im
		"cartel":           # the poster on the door: printed paper, bright in the shade too
			var pm := StandardMaterial3D.new()
			pm.albedo_texture = Parts.texture(POSTER)
			pm.roughness = 1.0
			m = _glow(pm, 0.3)
		"luz":              # a lamp, lit
			var lm := StandardMaterial3D.new()
			lm.albedo_color = Color(1.0, 0.98, 0.9)
			lm.emission_enabled = true
			lm.emission = Color(1.0, 0.95, 0.82)
			lm.emission_energy_multiplier = 2.2
			m = lm
		"vidrio":
			var gm := StandardMaterial3D.new()
			gm.albedo_color = Color(0.62, 0.76, 0.8, 0.3)
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.roughness = 0.08
			gm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = gm
		"toldo":            # canvas, seen from both sides
			var cm := StandardMaterial3D.new()
			cm.albedo_color = Color(0.95, 0.93, 0.87)
			cm.cull_mode = BaseMaterial3D.CULL_DISABLED
			cm.roughness = 1.0
			m = cm
		"toldo_verde":
			var vm := StandardMaterial3D.new()
			vm.albedo_color = Color(0.25, 0.48, 0.3)
			vm.cull_mode = BaseMaterial3D.CULL_DISABLED
			vm.roughness = 1.0
			m = vm
		_:
			return super(key)
	_mats[key] = m
	return m

func _loc(p: Vector2) -> Vector2:
	var q: Vector3 = transform.affine_inverse() * Vector3(p.x, level, p.y)
	return Vector2(q.x, q.z)

## the ground under a spot of the wall of Santo Domingo (x along it from the west end, z out of it), from the slab
func _gs(x: float, z: float) -> float:
	var p: Vector2 = WS + ds * x + ns * z
	return ground(p.x, p.y)

## ...and under a spot of the point (x along it from its south corner, z out of it)
func _gp(x: float, z: float) -> float:
	var p: Vector2 = PS + dp * x + np * z
	return ground(p.x, p.y)

func _cross(a: Vector2, da: Vector2, b: Vector2, db: Vector2) -> Vector2:
	var hit = Geometry2D.line_intersects_line(a, da, b, db)
	return hit if hit != null else a

func build(world, hd: Dictionary) -> void:
	W = world
	var o := Vector2(hd["o"][0], hd["o"][1])
	var u := Vector2(hd["u"][0], hd["u"][1])
	var out := Vector2(-u.y, u.x)
	len_n = float(hd["len"])
	# the plot's corners on the map: the ring runs round it, the point's two corners next to one another
	var raw: Array = hd["pieces"][0]["ring"]
	var ring: Array = []
	for i in range(0, raw.size(), 2):
		ring.append(Vector2(float(raw[i]), float(raw[i + 1])))
	var n := ring.size()
	var i_pn := 0
	var i_wn := 0
	for i in range(n):
		if (ring[i] as Vector2).distance_to(o) < (ring[i_pn] as Vector2).distance_to(o):
			i_pn = i
		if (ring[i] as Vector2).distance_to(o + u * len_n) < (ring[i_wn] as Vector2).distance_to(o + u * len_n):
			i_wn = i
	var step: int = 1 if (i_pn + n - 1) % n == i_wn else -1          # away from the Calle de San José
	var ps_map: Vector2 = ring[(i_pn + step + n) % n]
	var ws_map: Vector2 = ring[(i_pn + 2 * step + 2 * n) % n]
	var wm_map: Vector2 = ring[(i_pn + 3 * step + 3 * n) % n] if n >= 5 else (ws_map + o + u * len_n) / 2.0
	level = (MapData.height(o + u * len_n) + MapData.height(ws_map)) / 2.0 + SLAB_UP
	transform = Transform3D(Basis(Vector3(u.x, 0, u.y), Vector3.UP, Vector3(out.x, 0, out.y)), Vector3(o.x, level, o.y))
	W.add_child(self)
	WN = Vector2(len_n, 0.0)
	PS = _loc(ps_map)
	WS = _loc(ws_map)
	WM = _loc(wm_map)
	len_s = WS.distance_to(PS)
	len_p = PS.distance_to(PN)
	ds = (PS - WS).normalized()
	ns = Vector2(-ds.y, ds.x)
	dp = (PN - PS).normalized()
	np = Vector2(-dp.y, dp.x)
	PNb = PN + Vector2(-1.0, 0.0) * (BAL / Vector2(-1.0, 0.0).dot(np))
	PSb = PS + ds * (BAL / ds.dot(np))
	_north()
	_south()
	_point()
	_balcony()
	_west()
	_roof()
	_street()
	home()
	_commit()
	_states()
	var mid_pt: Vector2 = PS + dp * (float(_sf["mid"]) - float(_sf["leaf"]) / 2.0)
	var out_v: Vector3 = transform.basis * Vector3(np.x, 0.0, np.y)
	tienda = DentroS.new()
	tienda.build(world, NAME, spot(mid_pt.x + np.x * 0.15, mid_pt.y + np.y * 0.15), spot(mid_pt.x + np.x * 1.45, mid_pt.y + np.y * 1.45), atan2(out_v.x, out_v.z))
	tienda.open = is_open

# ---------------- pieces every wall has ----------------
## a course of bricks stood on end, standing a little proud of the wall being built
func _soldier(x0: float, x1: float, y0: float, y1: float, proud := 0.03) -> void:
	box(x0, y0, 0.0, x1 - x0, y1 - y0, proud, "ladrillo")
	box(x0, y0 - 0.014, 0.0, x1 - x0, 0.014, proud + 0.006, 0x8f5a48)                     # (the joint under it, in shadow)
	quad(Vector3(x0, y0, proud + 0.002), Vector3(x1, y0, proud + 0.002), Vector3(x1, y1, proud + 0.002), Vector3(x0, y1, proud + 0.002), "sardinel", Vector3(0, 0, 1),
		[Vector2(y0, x0), Vector2(y0, x1), Vector2(y1, x1), Vector2(y1, x0)])

## The foot of pale stone of the wall being built, from x0 to x1: level on top, the street falling along it; its
## slabs' joints.
func _foot(x0: float, x1: float) -> void:
	if x1 - x0 < 0.05:
		return
	plinth(x0, x1, FOOT, FOOT, "piedra", 0.04, DOWN)
	var n := int((x1 - x0) / 0.95)
	for i in range(1, n):
		box(x0 + i * (x1 - x0) / n - 0.005, FOOT - 2.2, 0.04, 0.01, 2.2, 0.003, 0xa8a294)

## what fills a window's hole: glass, its white frame, its uprights; `blind`: how much of it the blind covers, from the top
func _win(r: Rect2, panes := 2, blind := 0.0, frame := WHITE) -> void:
	var z: float = -DEEP + 0.08
	box(r.position.x + 0.05, r.position.y + 0.05, z - 0.04, r.size.x - 0.1, r.size.y - 0.1, 0.025, GLASS)
	for q in [[r.position.x, r.position.y, 0.06, r.size.y], [r.end.x - 0.06, r.position.y, 0.06, r.size.y], [r.position.x, r.position.y, r.size.x, 0.06], [r.position.x, r.end.y - 0.06, r.size.x, 0.06]]:
		box(q[0], q[1], z - 0.02, q[2], q[3], 0.06, frame)
	for i in range(1, panes):
		box(r.position.x + r.size.x * i / panes - 0.03, r.position.y, z - 0.02, 0.06, r.size.y, 0.06, frame)
	if blind > 0.0:
		var h: float = (r.size.y - 0.1) * blind
		box(r.position.x + 0.05, r.end.y - 0.05 - h, z + 0.04, r.size.x - 0.1, h, 0.03, BLIND)
		var rows := int(h / 0.09)
		for j in range(1, rows):
			box(r.position.x + 0.05, r.end.y - 0.05 - j * h / rows, z + 0.07, r.size.x - 0.1, 0.008, 0.004, 0xc4bca4)

## its sill of pale stone
func _sill(r: Rect2) -> void:
	box(r.position.x - 0.07, r.position.y - 0.07, 0.0, r.size.x + 0.14, 0.07, 0.08, 0xdcd6c6)

## an iron grille before a window, with its crest: a spike between two curls
func _reja(r: Rect2, out := 0.16) -> void:
	grille(r, out, BARS)
	var cx: float = r.position.x + r.size.x / 2.0
	var y: float = r.end.y + 0.05
	box(cx - 0.012, y, out - 0.012, 0.024, 0.24, 0.024, BARS)
	cbox(Vector3(cx, y + 0.26, out), Vector3(0.05, 0.05, 0.03), BARS)
	for s in [-1.0, 1.0]:
		bar(Vector3(cx + s * 0.03, y + 0.02, out), Vector3(cx + s * 0.16, y + 0.12, out), 0.016, 0.016, BARS)
		bar(Vector3(cx + s * 0.16, y + 0.12, out), Vector3(cx + s * 0.1, y + 0.17, out), 0.016, 0.016, BARS)
		bar(Vector3(r.position.x - 0.06 if s < 0.0 else r.end.x + 0.06, y, out), Vector3(cx + s * 0.05, y + 0.1, out), 0.012, 0.012, BARS)
		cbox(Vector3(r.position.x - 0.06 if s < 0.0 else r.end.x + 0.06, y + 0.05, out), Vector3(0.04, 0.05, 0.03), BARS)

## a window of the upper floor in its hole: sill, blind, and its cage of bars standing well out
func _upper(r: Rect2, panes: int, blind: float) -> void:
	_win(r, panes, blind)
	_sill(r)
	_reja(r, 0.24)

## a barred window of the ground floor, its bricks on end over it
func _lower(r: Rect2, panes: int, curtain := false) -> void:
	_soldier(r.position.x - 0.12, r.end.x + 0.12, r.end.y, r.end.y + 0.24)
	_win(r, panes)
	if curtain:                                     # net curtains behind the glass
		for i in range(panes):
			box(r.position.x + r.size.x * i / panes + 0.09, r.position.y + 0.08, -DEEP + 0.075, r.size.x / panes - 0.18, r.size.y - 0.2, 0.006, 0xcfd6c8)
	_sill(r)
	_reja(r, 0.15)

## A window under a round arch, in its square hole `r`: the brick left in the corners, the glass, its frame, the
## arch of bricks on end and the grille that follows it.
func _arch(r: Rect2) -> void:
	var rad: float = r.size.x / 2.0
	var cx: float = r.position.x + rad
	var spring: float = r.end.y - rad
	spandrels(cx, spring, rad, 0.0, "ladrillo")
	var z: float = -DEEP + 0.08
	arched(cx, r.position.y, spring, rad, z - 0.04, GLASS)
	box(r.position.x, r.position.y, z - 0.02, 0.05, spring - r.position.y, 0.05, WHITE)
	box(r.end.x - 0.05, r.position.y, z - 0.02, 0.05, spring - r.position.y, 0.05, WHITE)
	box(r.position.x, r.position.y, z - 0.02, r.size.x, 0.05, 0.05, WHITE)
	box(r.position.x, spring - 0.025, z - 0.02, r.size.x, 0.05, 0.05, WHITE)
	box(cx - 0.025, r.position.y, z - 0.02, 0.05, spring - r.position.y, 0.05, WHITE)
	ring(cx, spring, rad, rad + 0.22, 0.03, 0.03, "ladrillo", 14)
	_sill(Rect2(r.position.x, r.position.y, r.size.x, 0.1))
	# its grille: uprights up to the arch, the arch itself in short bars, its crest
	var out := 0.13
	var g: float = rad + 0.07
	var nb := 7
	for i in range(nb + 1):
		var x: float = cx - g + 2.0 * g * i / nb
		var top: float = spring + sqrt(maxf(0.0, g * g - (x - cx) * (x - cx)))
		box(x - 0.01, r.position.y - 0.05, out - 0.01, 0.02, top - r.position.y + 0.05, 0.02, BARS)
	for i in range(12):
		var a0: float = PI * i / 12.0
		var a1: float = PI * (i + 1) / 12.0
		bar(Vector3(cx + g * cos(a0), spring + g * sin(a0), out), Vector3(cx + g * cos(a1), spring + g * sin(a1), out), 0.02, 0.02, BARS)
	for y in [r.position.y - 0.05, r.position.y + (spring - r.position.y) * 0.5, spring]:
		box(cx - g, y - 0.006, out - 0.02, 2.0 * g, 0.012, 0.04, BARS)
	box(cx - 0.012, spring + g, out - 0.012, 0.024, 0.2, 0.024, BARS)
	for s in [-1.0, 1.0]:
		bar(Vector3(cx + s * 0.02, spring + g + 0.02, out), Vector3(cx + s * 0.13, spring + g + 0.1, out), 0.014, 0.014, BARS)

## A folding gate of lattice ("de tijera") shut across its hole: the dark behind it, its frame, the slanting bars.
func _lattice(x0: float, x1: float, y0: float, y1: float) -> void:
	box(x0, y0, -DEEP, x1 - x0, y1 - y0, 0.04, 0x1a1a1c)
	var z := -0.1
	for q in [[x0, y0, 0.05, y1 - y0], [x1 - 0.05, y0, 0.05, y1 - y0], [x0, y1 - 0.05, x1 - x0, 0.05], [x0, y0, x1 - x0, 0.04], [(x0 + x1) / 2.0 - 0.025, y0, 0.05, y1 - y0]]:
		box(q[0], q[1], z - 0.02, q[2], q[3], 0.05, LATTICE)
	var cell := 0.17
	var half: float = (y1 - y0) / 2.0
	var c: float = x0 - half
	while c < x1 + half:                        # one bar leaning each way from every step along the foot, cut to the gate
		var r0: float = maxf(0.0, x0 - c)
		var r1: float = minf(half, x1 - c)
		if r1 - r0 > 0.03:
			bar(Vector3(c + r0, y0 + 2.0 * r0, z), Vector3(c + r1, y0 + 2.0 * r1, z), 0.022, 0.012, LATTICE)
		var l0: float = maxf(0.0, c - x1)
		var l1: float = minf(half, c - x0)
		if l1 - l0 > 0.03:
			bar(Vector3(c - l0, y0 + 2.0 * l0, z), Vector3(c - l1, y0 + 2.0 * l1, z), 0.022, 0.012, LATTICE)
		c += cell

## an air conditioner on its brackets: `r` on the wall being built, standing `deep` out
func _air(r: Rect2, deep := 0.34) -> void:
	box(r.position.x, r.position.y, 0.12, r.size.x, r.size.y, deep, 0xf1f0ea)
	var rad: float = minf(r.size.x * 0.3, r.size.y * 0.4)
	slab(oval(r.position.x + r.size.x * 0.38, r.position.y + r.size.y * 0.5, rad, rad, 14), 0.12 + deep + 0.006, 0.0, 0xb4b8bc)
	slab(oval(r.position.x + r.size.x * 0.38, r.position.y + r.size.y * 0.5, rad * 0.25, rad * 0.25, 8), 0.12 + deep + 0.01, 0.0, 0x8a8f94)
	for i in range(5):
		box(r.end.x - r.size.x * 0.2, r.position.y + r.size.y * (0.2 + 0.13 * i), 0.12 + deep, r.size.x * 0.14, 0.012, 0.004, 0xb4b8bc)
	for x in [r.position.x + 0.08, r.end.x - 0.12]:
		box(x, r.position.y - 0.04, 0.0, 0.04, 0.04, 0.12 + deep, 0xd9d9d4)
		bar(Vector3(x + 0.02, r.position.y - 0.3, 0.02), Vector3(x + 0.02, r.position.y - 0.04, 0.1 + deep), 0.03, 0.03, 0xd9d9d4)

## bright posters behind a window's glass: what the shop sells, in pictures and no names
func _posters(r: Rect2, seed: int) -> void:
	var z: float = -DEEP + 0.13
	var tints: Array = [0xf2c230, 0x3a9a4a, 0x2a82d8, 0xe8322a, 0xf07a22, 0xfdfcf8, 0x8a5ad0, 0xe85aa8]
	var n := maxi(2, int(r.size.x / 0.62))
	for i in range(n):
		var x: float = r.position.x + 0.08 + i * (r.size.x - 0.16) / n
		var w: float = (r.size.x - 0.16) / n - 0.04
		var h: float = r.size.y * (0.5 + 0.12 * ((i + seed) % 3))
		var c: int = tints[(i * 3 + seed) % tints.size()]
		box(x, r.position.y + 0.08, z, w, h, 0.01, c)
		box(x + 0.05, r.position.y + 0.08 + h * 0.62, z + 0.01, w - 0.1, h * 0.2, 0.004, tints[(i * 5 + seed + 2) % tints.size()])
		slab(oval(x + w * 0.5, r.position.y + 0.08 + h * 0.3, w * 0.28, h * 0.16, 12), z + 0.016, 0.0, tints[(i + seed + 4) % tints.size()])

func _down(pts: PackedVector2Array, y: float, key) -> void:
	var idx := Geometry2D.triangulate_polygon(pts)
	for t in range(0, idx.size(), 3):
		var a := pts[idx[t]]
		var b := pts[idx[t + 1]]
		var c := pts[idx[t + 2]]
		tri(Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y), key, Vector3.DOWN)

## a cable slung along the wall being built
func _cable(pts: Array) -> void:
	for i in range(pts.size() - 1):
		bar(pts[i], pts[i + 1], 0.02, 0.02, 0x1c1c1e)

# ---------------- the Calle de San José ----------------
## Its north wall, from the point (x = 0) to the neighbour's: on the ground floor three barred windows, a vent, and
## at the far end the two gates of lattice with a stone post between them; upstairs four windows in their cages and
## the tall arched window of the stairs.
func _north() -> void:
	var ln: float = face(PN, WN)
	var k: float = ln / 19.77
	var gates: float = clampf(ground(16.5 * k, 0.4) + 2.25, -0.95, -0.55)       # the gates stand on their own ground
	var g1 := Rect2(1.70 * k, WIN_LO, 1.76, WIN_HI - WIN_LO)
	var g2 := Rect2(5.63 * k, WIN_LO, 2.36, WIN_HI - WIN_LO)
	var g3 := Rect2(9.93 * k, WIN_LO, 1.52, WIN_HI - WIN_LO)
	var vent := Rect2(11.68 * k, -0.6, 0.98, 0.37)
	var gate1 := Rect2(15.0 * k, DOWN, 2.23, gates - DOWN)
	var gate2 := Rect2(17.47 * k, DOWN, 2.05, gates - DOWN)
	var u1 := Rect2(1.75 * k, SILL, 2.15, HEAD - SILL)
	var u2 := Rect2(5.94 * k, SILL, 2.14, HEAD - SILL)
	var u3 := Rect2(9.95 * k, SILL, 1.46, HEAD - SILL)
	var stairs := Rect2(13.2 * k, 0.38, 0.9, 2.1)
	var u5 := Rect2(16.0 * k, SILL, 2.23, HEAD - SILL)
	masonry(0.0, ln, DOWN, 0.0, [g1, g2, g3, vent, gate1, gate2], [], "ladrillo")
	masonry(0.0, ln, 0.0, TOP, [u1, u2, u3, stairs, u5], [], "ladrillo")
	_soldier(0.0, ln, 0.0, BAND)
	_foot(0.0, gate1.position.x - 0.12)
	_lower(g1, 2)
	_posters(g1, 1)
	_lower(g2, 3, true)
	_lower(g3, 2, true)
	box(vent.position.x, vent.position.y, -0.12, vent.size.x, vent.size.y, 0.03, 0x1c1c1e)       # the vent: two panes of dark slats in a grey frame
	for q in [[vent.position.x, vent.position.y, 0.04, vent.size.y], [vent.end.x - 0.04, vent.position.y, 0.04, vent.size.y], [vent.position.x + vent.size.x / 2.0 - 0.02, vent.position.y, 0.04, vent.size.y],
			[vent.position.x, vent.position.y, vent.size.x, 0.03], [vent.position.x, vent.end.y - 0.03, vent.size.x, 0.03]]:
		box(q[0], q[1], -0.1, q[2], q[3], 0.1, 0x8f9498)
	for j in range(1, 6):
		box(vent.position.x + 0.04, vent.position.y + j * vent.size.y / 6.0, -0.09, vent.size.x - 0.08, 0.012, 0.03, 0x3a3d40)
	# the two gates under one run of bricks on end, the stone post between them, a strip of stone at each side
	_soldier(gate1.position.x - 0.15, minf(ln, gate2.end.x + 0.15), gates, gates + 0.3)
	_lattice(gate1.position.x, gate1.end.x, ground(gate1.position.x + 1.0, 0.3), gates)
	_lattice(gate2.position.x, gate2.end.x, ground(gate2.position.x + 1.0, 0.3), gates)
	box(gate1.end.x, DOWN, 0.014, gate2.position.x - gate1.end.x, gates - DOWN, 0.03, "piedra")
	box(gate1.position.x - 0.1, DOWN, 0.014, 0.1, gates - DOWN, 0.02, "piedra")
	# upstairs
	_upper(u1, 2, 0.75)
	_upper(u2, 2, 0.85)
	_upper(u3, 2, 0.6)
	_upper(u5, 2, 0.8)
	_arch(stairs)
	_air(Rect2(11.62 * k, 0.38, 0.8, 0.55), 0.3)                                              # an air conditioner over the vent...
	_air(Rect2(0.3, 0.42, 0.8, 0.55), 0.3)                                                   # ...and another by the point
	bar(Vector3(12.45 * k, 0.4, 0.06), Vector3(12.45 * k, -0.25, 0.06), 0.03, 0.03, 0xe9e6dc)
	box(0.58, -0.3, 0.0, 0.2, 0.27, 0.08, 0xeeeade)                                     # a meter box under the bricks on end, a white pipe down from it
	box(1.19, -0.93, 0.0, 0.04, 0.9, 0.04, 0xe9e6dc)
	_cable([Vector3(0.3, 0.42, 0.05), Vector3(1.2, 0.3, 0.05), Vector3(4.0, 0.16, 0.05), Vector3(8.5, 0.31, 0.05), Vector3(11.5, 0.2, 0.05), Vector3(15.0, 0.29, 0.05), Vector3(ln - 0.1, 0.33, 0.05)])
	_cable([Vector3(0.68, -0.03, 0.05), Vector3(0.68, 0.36, 0.05)])
	home()

# ---------------- the Calle de Santo Domingo ----------------
## Its south wall, from the neighbour's (x = 0) to the point: a gate of lattice and an iron door between posts of
## stone, the house's door of embossed metal in its pale frame, two arched windows, three barred ones and the shop's
## own with its posters under an air conditioner; upstairs six windows in their cages.
func _south() -> void:
	var ln: float = face(WS, PS)
	var k: float = ln / 19.97
	var low: float = clampf(_gs(1.2, 0.4) + 2.34, -1.0, -0.6)                        # the gate and the iron door, on their own ground
	var tall: float = clampf(_gs(4.85 * k, 0.4) + 2.7, -0.9, -0.4)                   # the house's door
	var gate := Rect2(0.33, DOWN, 1.64, low - DOWN)
	var iron := Rect2(2.15, DOWN, 0.62, low - DOWN)
	var main := Rect2(4.24 * k, DOWN, 1.23, tall - DOWN)
	var a1 := Rect2(6.7 * k, -2.2, 0.8, 1.45)
	var a2 := Rect2(8.07 * k, -2.2, 0.8, 1.45)
	var w3 := Rect2(10.07 * k, WIN_LO, 2.34, WIN_HI - WIN_LO)
	var w4 := Rect2(13.71 * k, WIN_LO, 0.8, WIN_HI - WIN_LO)
	var w5 := Rect2(15.38 * k, WIN_LO, 0.66, WIN_HI - WIN_LO)
	var shop := Rect2(17.27 * k, WIN_LO, 2.13, WIN_HI - WIN_LO)
	var u1 := Rect2(0.87, 1.0, 1.35, HEAD - 1.0)
	var u2 := Rect2(4.15 * k, SILL, 1.4, HEAD - SILL)
	var u3 := Rect2(8.1 * k, SILL, 0.7, HEAD - SILL)
	var u4 := Rect2(10.07 * k, SILL, 2.46, HEAD - SILL)
	var u5 := Rect2(13.6 * k, SILL, 1.0, HEAD - SILL)
	var u6 := Rect2(17.12 * k, SILL, 2.4, HEAD - SILL)
	masonry(0.0, ln, DOWN, 0.0, [gate, iron, main, a1, a2, w3, w4, w5, shop], [], "ladrillo")
	masonry(0.0, ln, 0.0, TOP, [u1, u2, u3, u4, u5, u6], [], "ladrillo")
	_soldier(0.0, ln, 0.0, BAND)
	_foot(main.end.x + 0.16, ln)
	# the gate of lattice and the iron door, each between posts of stone, under one run of bricks on end
	_soldier(0.0, iron.end.x + 0.3, low, low + 0.3)
	var g0: float = _gs(1.2, 0.3)
	_lattice(gate.position.x, gate.end.x, g0, low)
	for q in [[gate.position.x - 0.16, gate.position.x], [gate.end.x, iron.position.x], [iron.end.x, iron.end.x + 0.16]]:
		box(q[0], DOWN, 0.014, q[1] - q[0], low - DOWN, 0.03, "piedra")
	box(iron.position.x, g0, -0.12, iron.size.x, low - g0, 0.03, 0x1a1a1c)               # the iron door: a frame, uprights, a plate at its foot
	for i in range(6):
		box(iron.position.x + 0.04 + i * (iron.size.x - 0.1) / 5.0, g0, -0.08, 0.02, low - g0, 0.02, 0x3a3d40)
	for y in [g0 + 0.02, g0 + 1.05, low - 0.05]:
		box(iron.position.x, y, -0.09, iron.size.x, 0.04, 0.03, 0x3a3d40)
	box(iron.position.x + 0.03, g0 + 0.04, -0.085, iron.size.x - 0.06, 0.5, 0.012, 0x3a3d40)
	box(3.5 * k, g0 + 1.35, 0.0, 0.26, 0.36, 0.07, 0xe9e6dc)                             # a meter box, and a smaller one under the bricks on end
	box(3.72 * k, -0.3, 0.0, 0.16, 0.26, 0.07, 0xeeeade)
	# the door of the house: two leaves of embossed metal, bronze gone green, in a pale frame
	var d0: float = _gs(main.position.x + 0.6, 0.3)
	_house_door(main, d0, tall)
	cbox(Vector3(main.end.x + 0.42, d0 + 1.55, 0.07), Vector3(0.24, 0.3, 0.14), 0x3a4654)      # the letter box, its little roof
	bar(Vector3(main.end.x + 0.28, d0 + 1.7, 0.07), Vector3(main.end.x + 0.42, d0 + 1.78, 0.07), 0.16, 0.02, 0x3a4654)
	bar(Vector3(main.end.x + 0.42, d0 + 1.78, 0.07), Vector3(main.end.x + 0.56, d0 + 1.7, 0.07), 0.16, 0.02, 0x3a4654)
	cbox(Vector3(main.end.x + 0.42, d0 + 1.58, 0.145), Vector3(0.16, 0.03, 0.006), 0xd9c9a0)
	_arch(a1)
	_arch(a2)
	_lower(w3, 3, true)
	_lower(w4, 1)
	box(w4.position.x + 0.07, w4.position.y + 0.1, -DEEP + 0.13, w4.size.x - 0.14, w4.size.y * 0.72, 0.012, 0xe9e7df)      # (a sheet hung behind its glass, as it is)
	box(w4.position.x + 0.12, w4.position.y + 0.3, -DEEP + 0.145, w4.size.x - 0.3, 0.012, 0.004, 0xc9c6bb)
	_lower(w5, 1)
	_lower(shop, 3)
	_posters(shop, 3)
	_air(Rect2(17.0 * k, -0.72, 1.15, 0.94), 0.42)                                      # the great air conditioner over the shop's window, its pipe
	_cable([Vector3(17.25 * k, -0.76, 0.2), Vector3(17.2 * k, -1.3, 0.06), Vector3(17.2 * k, -2.3, 0.06)])
	_upper(u1, 2, 0.9)
	_upper(u2, 2, 0.85)
	_upper(u3, 1, 0.9)
	_upper(u4, 2, 0.7)
	_upper(u5, 1, 0.85)
	_upper(u6, 2, 0.8)
	_cable([Vector3(0.1, 0.5, 0.05), Vector3(3.0, 0.3, 0.05), Vector3(7.5, 0.16, 0.05), Vector3(12.0, 0.3, 0.05), Vector3(16.5 * k, 0.34, 0.05)])
	_cable([Vector3(0.2, 2.1, 0.05), Vector3(3.6, 0.9, 0.05), Vector3(3.8 * k, -0.04, 0.05)])
	home()

## The house's door in its hole `r`, from the ground `g` to `head`: a pale frame, a fixed light over two leaves,
## each with three raised panels -- a rose with its knocker, a rose, a lozenge.
func _house_door(r: Rect2, g: float, head: float) -> void:
	var metal := 0x5e5b45
	var dark := 0x3c3a2b
	var lit := 0x7c7858
	for x in [r.position.x - 0.13, r.end.x]:
		box(x, DOWN, 0.0, 0.13, head - DOWN, 0.035, 0xe6e0d0)
	box(r.position.x - 0.13, head, 0.0, r.size.x + 0.26, 0.13, 0.035, 0xe6e0d0)
	box(r.position.x - 0.2, DOWN, 0.0, r.size.x + 0.4, g + 0.1 - DOWN, 0.2, "piedra")                # its step
	var z: float = -DEEP + 0.1
	var leaf: float = r.size.x / 2.0
	box(r.position.x, g + 0.1, z - 0.04, r.size.x, head - g - 0.1, 0.04, metal)
	box(r.position.x + leaf - 0.012, g + 0.1, z, 0.024, head - g - 0.1, 0.012, dark)
	var h: float = head - g - 0.1
	for i in range(2):
		var x0: float = r.position.x + i * leaf + 0.07
		var w: float = leaf - 0.14
		var parts: Array = [[0.04, 0.3], [0.37, 0.27], [0.67, 0.29]]                  # each panel: where it begins and how tall it is, as parts of the leaf
		for j in range(3):
			var y0: float = g + 0.1 + h * float(parts[j][0])
			var ph: float = h * float(parts[j][1])
			for q in [[x0, y0, w, 0.03], [x0, y0 + ph - 0.03, w, 0.03], [x0, y0, 0.03, ph], [x0 + w - 0.03, y0, 0.03, ph]]:
				box(q[0], q[1], z, q[2], q[3], 0.018, lit)
			var mid := Vector2(x0 + w / 2.0, y0 + ph / 2.0)
			if j == 0:                              # a lozenge, at the foot
				tbox(Transform3D(Basis(Vector3(0, 0, 1), PI / 4.0).scaled_local(Vector3(w * 0.42, w * 0.42, 0.02)), Vector3(mid.x, mid.y, z + 0.01)), lit)
				tbox(Transform3D(Basis(Vector3(0, 0, 1), PI / 4.0).scaled_local(Vector3(w * 0.24, w * 0.24, 0.03)), Vector3(mid.x, mid.y, z + 0.015)), dark)
			else:                                   # a rose of eight petals
				for p in range(8):
					var a: float = TAU * p / 8.0
					slab(oval(mid.x + cos(a) * w * 0.17, mid.y + sin(a) * w * 0.17, w * 0.09, w * 0.09, 8), z + 0.016, 0.0, lit)
				slab(oval(mid.x, mid.y, w * 0.1, w * 0.1, 10), z + 0.024, 0.0, dark)
			if j == 2:                              # the knocker: a ring on its boss
				slab(oval(mid.x, mid.y + ph * 0.3, 0.05, 0.05, 10), z + 0.03, 0.02, dark)
				for p in range(8):
					var a0: float = TAU * p / 8.0
					var a1: float = TAU * (p + 1) / 8.0
					bar(Vector3(mid.x + cos(a0) * 0.06, mid.y + ph * 0.24 + sin(a0) * 0.06, z + 0.04), Vector3(mid.x + cos(a1) * 0.06, mid.y + ph * 0.24 + sin(a1) * 0.06, z + 0.04), 0.014, 0.014, dark)

# ---------------- the point ----------------
## The shop's front, between a pier of brick and one of posters: its carved board, its awning, the glazed door of
## slanting bars beside the open one, the window full of toys; and what shows of the shop through them.
func _point() -> void:
	var ln: float = face(PS, PN)
	var g: float = _gp(ln * 0.42, 0.45) - 0.1       # the pavement before the doors (its step is 14 cm: a kerb's worth over it)
	var x0: float = ln * 0.19                       # the shop front, from its brick pier...
	var x1: float = ln * 0.805                      # ...to its pier of posters
	var head := -0.75                               # under the board
	var lintel: float = g + 2.3                     # over the doors
	var front := Rect2(x0, DOWN, x1 - x0, head - DOWN)
	masonry(0.0, ln, DOWN, 0.0, [front], [], "ladrillo")
	# the pier of posters: tiles at its foot, then a board of what is sold
	var foot: float = minf(g + 0.95, head - 1.95)
	box(x1, DOWN, 0.014, ln - x1, foot - DOWN, 0.04, "piedra")
	box(x1 + 0.02, foot, 0.0, ln - x1 - 0.04, head - foot, 0.03, 0x2f6a3a)
	var px: float = (x1 + ln) / 2.0
	var yellow := 0xf4d23a
	_text("ALIMENTACIÓN\nY BEBIDAS\nDE RUMANÍA", Vector3(px, head - 0.26, 0.04), 32, yellow, 0.0024)
	var flag: float = head - 0.56
	for i in range(3):
		box(x1 + 0.04 + i * (ln - x1 - 0.08) / 3.0, flag, 0.03, (ln - x1 - 0.08) / 3.0, 0.1, 0.004, [0x1f3f9a, 0xf4d23a, 0xc8281e][i])
	_text("GOLOSINAS", Vector3(px, flag - 0.14, 0.04), 32, yellow, 0.0026)
	_text("BOLLERÍA", Vector3(px, flag - 0.34, 0.04), 32, yellow, 0.0026)
	_text("BEBIDAS", Vector3(px, flag - 0.54, 0.04), 32, yellow, 0.0026)
	for i in range(2):                              # two posters stuck on it, and what else it does
		box(x1 + 0.05 + i * (ln - x1 - 0.1) / 2.0, flag - 0.98, 0.03, (ln - x1 - 0.14) / 2.0, 0.3, 0.005, [0xe8322a, 0x2a82d8][i])
		box(x1 + 0.08 + i * (ln - x1 - 0.1) / 2.0, flag - 0.9, 0.035, (ln - x1 - 0.26) / 2.0, 0.1, 0.004, [0xfdfcf8, 0xf2c230][i])
	_text("RECARGA\nDE MÓVILES", Vector3(px, head - 1.76, 0.04), 32, yellow, 0.0022)
	# the frame of wood: posts, the beam over the doors, the lights over it full of posters
	var a: float = x0 + 0.07
	var mid: float = x0 + (x1 - x0) * 0.55          # between the doors and the window
	var z: float = -0.22
	box(x0 - 0.02, DOWN, 0.0, x1 - x0 + 0.04, g + 0.14 - DOWN, 0.22, "piedra")          # the step
	for x in [x0, mid - 0.04, x1 - 0.07]:
		box(x, g + 0.14, z - 0.04, 0.07, head - g - 0.14, 0.1, WOODEN)
	box(x0, lintel, z - 0.04, x1 - x0, 0.09, 0.1, WOODEN)
	box(x0, head - 0.07, z - 0.04, x1 - x0, 0.07, 0.1, WOODEN)
	quad(Vector3(x0, lintel, z), Vector3(x1, lintel, z), Vector3(x1, head, z), Vector3(x0, head, z), "vidrio", Vector3(0, 0, 1))
	var tints: Array = [0xf2c230, 0x3a9a4a, 0x2a82d8, 0xe8322a, 0xf07a22, 0xfdfcf8, 0x8a5ad0, 0xe85aa8]
	for i in range(6):
		box(x0 + 0.1 + i * (x1 - x0 - 0.2) / 6.0, lintel + 0.13, z - 0.03, (x1 - x0 - 0.2) / 6.0 - 0.03, head - lintel - 0.24, 0.01, tints[(i * 3 + 1) % tints.size()])
	# the fixed leaf (the other one, shut or standing open, is the hour's business: _states)
	var leaf: float = (mid - 0.04 - a) / 2.0
	_leaf(a, leaf, g + 0.14, lintel, z)
	if Parts.texture(POSTER) != null:               # the poster on that leaf: small, stuck on askew
		poster = true
		_poster(Vector3(a + leaf * 0.52, g + 1.4, z + 0.016), -0.13, 0.27)
	# the window: a low panel of wood, and behind the glass every toy and packet the shop has
	var w0: float = mid + 0.03
	var w1: float = x1 - 0.07
	box(w0, g + 0.14, z - 0.04, w1 - w0, 0.5, 0.08, WOODEN)
	quad(Vector3(w0, g + 0.64, z), Vector3(w1, g + 0.64, z), Vector3(w1, lintel, z), Vector3(w0, lintel, z), "vidrio", Vector3(0, 0, 1))
	var cols := 5
	var rows := 7
	for j in range(rows):
		for i in range(cols):
			var c: int = tints[(i * 5 + j * 3 + (i * j) % 4) % tints.size()]
			box(w0 + 0.03 + i * (w1 - w0 - 0.06) / cols, g + 0.68 + j * (lintel - g - 0.72) / rows, z - 0.07, (w1 - w0 - 0.06) / cols - 0.02, (lintel - g - 0.72) / rows - 0.02, 0.03, c)
	# the shop, seen through its doors: floor, walls, shelves of goods, a lamp
	var back := -3.6
	var r0: float = 0.12
	var r1: float = ln - 0.12
	var zi: float = -DEEP - 0.02
	quad(Vector3(r0, g, back), Vector3(r1, g, back), Vector3(r1, head, back), Vector3(r0, head, back), "interior", Vector3(0, 0, 1))
	quad(Vector3(r0, g, back), Vector3(r0, g, zi), Vector3(r0, head, zi), Vector3(r0, head, back), "interior", Vector3(1, 0, 0))
	quad(Vector3(r1, g, back), Vector3(r1, g, zi), Vector3(r1, head, zi), Vector3(r1, head, back), "interior", Vector3(-1, 0, 0))
	quad(Vector3(r0, head, back), Vector3(r1, head, back), Vector3(r1, head, zi), Vector3(r0, head, zi), "interior", Vector3(0, -1, 0))
	quad(Vector3(r0, g + 0.14, back), Vector3(r1, g + 0.14, back), Vector3(r1, g + 0.14, zi), Vector3(r0, g + 0.14, zi), 0xa89a86, Vector3.UP)
	for j in range(5):
		box(r0 + 0.1, g + 0.5 + j * 0.42, back + 0.02, r1 - r0 - 0.2, 0.03, 0.3, 0xd9d4c8)
		for i in range(9):
			box(r0 + 0.14 + i * (r1 - r0 - 0.3) / 9.0, g + 0.53 + j * 0.42, back + 0.06, (r1 - r0 - 0.3) / 9.0 - 0.03, 0.2 + 0.06 * ((i + j) % 3), 0.2, tints[(i * 3 + j * 5) % tints.size()])
	cbox(Vector3((r0 + r1) / 2.0, head - 0.04, back * 0.5), Vector3(0.14, 0.05, 1.2), 0xfdfaf0)
	door = spot(PS.x + dp.x * (mid - leaf / 2.0) + np.x * 1.1, PS.y + dp.y * (mid - leaf / 2.0) + np.y * 1.1)
	# its board of carved wood under the balcony: what it sells, in gold; peaks cut at one end, an ice at the other
	var b0: float = ln * 0.06
	var b1: float = ln * 0.94
	box(b0, head + 0.03, 0.0, b1 - b0, 0.52, 0.05, 0xd8c79a)
	box(b0 + 0.04, head + 0.07, 0.05, b1 - b0 - 0.08, 0.44, 0.012, 0x8a5a30)
	var big := _text(NAME, Vector3((b0 + b1) / 2.0, head + 0.36, 0.07), 64, GOLD, 0.0039 * ln / 3.1)
	big.outline_size = 8
	big.outline_modulate = Color(0.32, 0.2, 0.1)
	var small := _text("PAN · BEBIDAS · FRUTOS SECOS", Vector3((b0 + b1) / 2.0, head + 0.15, 0.07), 32, GOLD, 0.0036 * ln / 3.1)
	small.outline_size = 5
	small.outline_modulate = Color(0.32, 0.2, 0.1)
	for i in range(3):
		slab(PackedVector2Array([Vector2(b0 + 0.07 + i * 0.09, head + 0.1), Vector2(b0 + 0.19 + i * 0.09, head + 0.1), Vector2(b0 + 0.16 + i * 0.09, head + 0.44 - i * 0.07)]), 0.066 + i * 0.002, 0.0, 0xc89a44)
	var ix: float = b1 - 0.16
	slab(PackedVector2Array([Vector2(ix - 0.055, head + 0.3), Vector2(ix + 0.055, head + 0.3), Vector2(ix, head + 0.1)]), 0.066, 0.0, 0xc89a44)
	slab(oval(ix, head + 0.34, 0.06, 0.06, 10), 0.068, 0.0, GOLD)
	slab(oval(ix, head + 0.41, 0.045, 0.045, 10), 0.07, 0.0, GOLD)
	# the awning's roller (the canvas, out or rolled up, is the hour's business: _states)
	var w: float = ln * 0.84
	var ax: float = (ln - w) / 2.0
	box(ax, head - 0.05, 0.0, w, 0.09, 0.1, 0xe9e6dc)
	_sf = {"ln": ln, "g": g, "x0": x0, "x1": x1, "head": head, "lintel": lintel, "a": a, "mid": mid, "leaf": leaf, "z": z, "ax": ax, "w": w, "back": back}
	# a little board with an ice on it and a paper cone hanging by the door; a lamp over each end of the board
	var ex: float = x0 - 0.04
	box(ex - 0.2, g + 2.05, 0.02, 0.4, 0.36, 0.02, 0xfdfcf8)
	slab(PackedVector2Array([Vector2(ex - 0.06, g + 2.26), Vector2(ex + 0.06, g + 2.26), Vector2(ex, g + 2.1)]), 0.045, 0.0, 0xd9a25a)
	slab(oval(ex, g + 2.3, 0.07, 0.06, 10), 0.047, 0.0, 0xe85aa8)
	slab(PackedVector2Array([Vector2(ex + 0.26, g + 2.42), Vector2(ex + 0.5, g + 2.42), Vector2(ex + 0.38, g + 2.02)]), 0.03, 0.0, 0xf4e6b0)
	slab(oval(ex + 0.38, g + 2.44, 0.11, 0.07, 10), 0.034, 0.0, 0x3a9a4a)
	for x in [ln * 0.3, ln * 0.7]:
		cbox(Vector3(x, -0.07, 0.3), Vector3(0.1, 0.12, 0.1), 0x1c1c1e)
	box(ln * 0.07, g + 1.05, 0.0, 0.3, 0.42, 0.006, 0xc9b5a4)                           # (what is left of a sticker on the brick pier)
	home()

## The poster, stuck on the wall being built: `at` its middle, `turn` how far askew it is, `wide` its width; a bit of
## tape on each of its top corners.
func _poster(at: Vector3, turn: float, wide: float) -> void:
	var keep := _xf
	_xf = keep * Transform3D(Basis(Vector3(0, 0, 1), turn), at)
	var ph: float = wide * 414.0 / 314.0
	quad(Vector3(-wide / 2.0, -ph / 2.0, 0), Vector3(wide / 2.0, -ph / 2.0, 0), Vector3(wide / 2.0, ph / 2.0, 0), Vector3(-wide / 2.0, ph / 2.0, 0), "cartel", Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	for sx in [-1.0, 1.0]:
		tbox(Transform3D(Basis(Vector3(0, 0, 1), sx * 0.6).scaled_local(Vector3(0.07, 0.022, 0.002)), Vector3(sx * (wide / 2.0 - 0.01), ph / 2.0 - 0.005, 0.002)), 0xe6dfc4)
	_xf = keep

## a leaf of the shop's door on the plane z of the frame being built: glass in a white frame, three panes each under two slanting bars
func _leaf(x: float, w: float, y0: float, y1: float, z: float) -> void:
	quad(Vector3(x, y0, z), Vector3(x + w, y0, z), Vector3(x + w, y1, z), Vector3(x, y1, z), "vidrio", Vector3(0, 0, 1))
	var r0: float = y0 + 0.91
	var r1: float = y0 + 1.61
	for q in [[x, y0, 0.05, y1 - y0], [x + w - 0.05, y0, 0.05, y1 - y0], [x, y0, w, 0.08], [x, y1 - 0.05, w, 0.05], [x, r0, w, 0.04], [x, r1, w, 0.04]]:
		box(q[0], q[1], z - 0.02, q[2], q[3], 0.04, WHITE)
	for q in [[y0 + 0.08, r0], [r0 + 0.04, r1], [r1 + 0.04, y1 - 0.05]]:
		bar(Vector3(x + 0.05, q[0], z), Vector3(x + w - 0.05, q[1], z), 0.03, 0.02, WHITE)
		bar(Vector3(x + w - 0.05, q[0], z), Vector3(x + 0.05, q[1], z), 0.03, 0.02, WHITE)

# ---------------- shut and open ----------------
## whether it is open on that day of the week (0 Monday ... 6 Sunday) at that hour
func open_at(day: int, hour: float) -> bool:
	var d: int = posmod(day, 7)
	if hour < WEEKEND.y - 24.0 and posmod(d - 1, 7) >= 5:      # the small hours after a Saturday or a Sunday
		return true
	if d >= 5:
		return hour >= WEEKEND.x
	return hour >= WEEK.x and hour < WEEK.y

## what has been built since the last commit becomes meshes under `node`: a part that can be shown and hidden
func _commit_to(node: Node3D) -> void:
	for key in _tools:
		var mi := MeshInstance3D.new()
		mi.mesh = (_tools[key] as SurfaceTool).commit()
		mi.material_override = _material(key)
		node.add_child(mi)
	_tools.clear()

## The two faces of the shop front. Shut: its second door leaf shut and, before both, the shutter of grey slats down
## over the whole front, two posters stuck on it askew, and the awning rolled up. Open: that leaf swung in, the awning
## out, and the lamps lit (the two under the balcony and the one inside).
func _states() -> void:
	var ln: float = _sf["ln"]
	var g: float = _sf["g"]
	var head: float = _sf["head"]
	var lintel: float = _sf["lintel"]
	var a: float = _sf["a"]
	var mid: float = _sf["mid"]
	var leaf: float = _sf["leaf"]
	var z: float = _sf["z"]
	var back: float = _sf["back"]
	var x0: float = _sf["x0"]
	var x1: float = _sf["x1"]
	var ax: float = _sf["ax"]
	var w: float = _sf["w"]
	_shut = Node3D.new()
	add_child(_shut)
	face(PS, PN)
	_leaf(a + leaf, leaf, g + 0.14, lintel, z)
	cbox(Vector3(a + leaf, g + 1.2, z + 0.03), Vector3(0.03, 0.16, 0.03), 0x9a9da0)                 # the handle where the two leaves meet
	var sy: float = g + 0.14                        # the shutter: grey slats from the step to the board, a bar and its lock at the foot
	box(x0 + 0.01, sy, -0.14, x1 - x0 - 0.02, head - sy, 0.04, 0x9a9c9a)
	var slats := int((head - sy) / 0.11)
	for j in range(1, slats):
		box(x0 + 0.01, sy + j * 0.11, -0.1, x1 - x0 - 0.02, 0.012, 0.004, 0x7c7e7c)
	box(x0 + 0.01, sy, -0.1, x1 - x0 - 0.02, 0.07, 0.02, 0x7c7e7c)
	cbox(Vector3((x0 + x1) / 2.0, sy + 0.26, -0.085), Vector3(0.16, 0.05, 0.03), 0x5a5c5e)
	if poster:                                      # two more of the posters, stuck on it askew
		_poster(Vector3(x0 + (x1 - x0) * 0.3, g + 1.58, -0.09), 0.17, 0.36)
		_poster(Vector3(x0 + (x1 - x0) * 0.69, g + 1.22, -0.09), -0.22, 0.31)
		on_shutter = 2
	box(ax + 0.02, head - 0.17, 0.02, w - 0.04, 0.12, 0.12, 0xece8dc)                   # the awning rolled up under its roller, its arms folded
	for x in [ax + 0.06, ax + w - 0.06]:
		bar(Vector3(x, head - 0.75, 0.04), Vector3(x, head - 0.2, 0.07), 0.03, 0.03, 0xd9d9d4)
	home()
	_commit_to(_shut)
	_open = Node3D.new()
	add_child(_open)
	face(PS, PN)
	var keep := _xf
	_xf = keep * Transform3D(Basis(Vector3.UP, PI / 2.0 - 0.25), Vector3(mid - 0.05, 0.0, z))
	_leaf(0.0, leaf, g + 0.14, lintel, 0.0)
	_xf = keep
	var reach := 1.05                               # the awning out: white canvas on its two arms, its scalloped edge
	quad(Vector3(ax, head, 0.08), Vector3(ax + w, head, 0.08), Vector3(ax + w, head - 0.36, reach), Vector3(ax, head - 0.36, reach), "toldo", Vector3(0, 0.94, 0.34))
	box(ax, head - 0.4, reach - 0.02, w, 0.05, 0.05, 0xe9e6dc)
	var scallops := 12
	for i in range(scallops):
		var s0: float = ax + i * w / scallops
		var s1: float = ax + (i + 1) * w / scallops
		quad(Vector3(s0, head - 0.39, reach + 0.03), Vector3(s1, head - 0.39, reach + 0.03), Vector3(s1, head - 0.53, reach + 0.03), Vector3(s0, head - 0.53, reach + 0.03), "toldo", Vector3(0, 0, 1))
		tri(Vector3(s0, head - 0.53, reach + 0.03), Vector3(s1, head - 0.53, reach + 0.03), Vector3((s0 + s1) / 2.0, head - 0.6, reach + 0.03), "toldo", Vector3(0, 0, 1))
	for x in [ax + 0.06, ax + w - 0.06]:
		bar(Vector3(x, head - 0.75, 0.04), Vector3(x, head - 0.4, reach - 0.02), 0.03, 0.03, 0xd9d9d4)
	for x in [ln * 0.3, ln * 0.7]:
		cbox(Vector3(x, -0.136, 0.3), Vector3(0.08, 0.012, 0.08), "luz")
	cbox(Vector3(ln / 2.0, head - 0.072, back * 0.5), Vector3(0.12, 0.012, 1.1), "luz")
	home()
	_commit_to(_open)
	for q in [[Vector3(ln * 0.5, -0.5, 0.75), 4.5, 0.8], [Vector3(ln * 0.5, head - 0.5, -1.6), 4.0, 0.8]]:
		var at: Vector3 = q[0]
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(PS.x + dp.x * at.x + np.x * at.z, at.y, PS.y + dp.y * at.x + np.y * at.z)
		lamp.light_color = Color(1.0, 0.93, 0.8)
		lamp.omni_range = q[1]
		lamp.light_energy = q[2]
		add_child(lamp)
		_lights.append(lamp)
	set_open(false)

func set_open(on: bool) -> void:
	is_open = on
	if tienda != null:
		tienda.open = on
	if _shut != null:
		_shut.visible = not on
		_open.visible = on
	for lamp in _lights:
		(lamp as Light3D).visible = on
	(_material("interior") as StandardMaterial3D).emission_energy_multiplier = 0.4 if on else 0.0        # (what is inside has no light of its own with the lamps out)

func _process(_delta: float) -> void:
	var game = W.get_parent() if W != null else null
	if game != null and "clock" in game and "weekday" in game:
		var want: bool = open_at(int(game.weekday), float(game.clock))
		if want != is_open:
			set_open(want)

## Over the shop: the balcony the upper floor pushes out at the point -- brick, bricks on end at its foot, a rail of
## iron on it -- and the wall behind it with its window of four leaves under a green striped awning.
func _balcony() -> void:
	var ln: float = face(PS, PN)
	var win := Rect2(ln / 2.0 - ln * 0.275, 0.92, ln * 0.55, 1.22)
	masonry(0.0, ln, 0.0, TOP, [win], [], "ladrillo")
	_win(win, 4, 0.55)
	var aw: float = ln * 0.72                       # the awning over it: green and cream
	var a0: float = (ln - aw) / 2.0
	var stripes := 14
	for i in range(stripes):
		var s0: float = a0 + i * aw / stripes
		var s1: float = a0 + (i + 1) * aw / stripes
		var key = "toldo_verde" if i % 2 == 0 else "toldo"
		quad(Vector3(s0, 2.5, 0.03), Vector3(s1, 2.5, 0.03), Vector3(s1, 2.2, 0.5), Vector3(s0, 2.2, 0.5), key, Vector3(0, 0.86, 0.5))
		quad(Vector3(s0, 2.2, 0.5), Vector3(s1, 2.2, 0.5), Vector3(s1, 2.06, 0.5), Vector3(s0, 2.06, 0.5), key, Vector3(0, 0, 1))
	for x in [a0 + 0.02, a0 + aw - 0.02]:
		bar(Vector3(x, 1.6, 0.03), Vector3(x, 2.2, 0.5), 0.02, 0.02, 0x2a2a2e)
	home()
	# its floor, its underside with nothing but two lamps (they hang in _point), and its three walls
	flat(PackedVector2Array([PS, PN, PNb, PSb]), BAND, 0xb9a58c)
	_down(PackedVector2Array([PS, PN, PNb, PSb]), 0.0, "blanco")
	for q in [[PSb, PNb], [PNb, PN], [PS, PSb]]:
		var a: Vector2 = q[0]
		var b: Vector2 = q[1]
		var w: float = face(a, b)
		quad(Vector3(0, 0, 0), Vector3(w, 0, 0), Vector3(w, 0.91, 0), Vector3(0, 0.91, 0), "ladrillo", Vector3(0, 0, 1))
		quad(Vector3(0, BAND, -0.12), Vector3(w, BAND, -0.12), Vector3(w, 0.91, -0.12), Vector3(0, 0.91, -0.12), "ladrillo", Vector3(0, 0, -1))
		_soldier(0.0, w, 0.0, BAND)
		box(-0.02, 0.91, -0.15, w + 0.04, 0.04, 0.19, 0xdcd6c6)
		box(0.0, 1.33, -0.075, w, 0.03, 0.03, BARS)
		box(0.0, 0.99, -0.07, w, 0.02, 0.02, BARS)
		var nb := maxi(2, int(w / 0.11))
		for i in range(nb + 1):
			box(i * (w - 0.016) / nb, 0.95, -0.068, 0.016, 0.4, 0.016, BARS)
		home()

# ---------------- what it shares with its neighbours ----------------
func _west() -> void:
	_plain(WN, WM, DOWN, TOP + 0.6, "medianera")
	_plain(WM, WS, DOWN, TOP + 0.6, "medianera")

# ---------------- its roof ----------------
## The great flat eave, white underneath, with its rim of tiles; the flat roof inside it; the hut under its sheet of
## corrugated iron; and at the point the cage of iron bars.
func _roof() -> void:
	var out_p := BAL + 0.3
	var e1: Vector2 = _cross(Vector2(0.0, EAVE), Vector2(1, 0), PN + np * out_p, dp)
	var e2: Vector2 = _cross(PS + np * out_p, dp, WS + ns * EAVE, ds)
	var w1 := Vector2(len_n, EAVE)
	var w2: Vector2 = WS + ns * EAVE
	var i1: Vector2 = _cross(Vector2(0.0, EAVE - RIM), Vector2(1, 0), PN + np * (out_p - RIM), dp)
	var i2: Vector2 = _cross(PS + np * (out_p - RIM), dp, WS + ns * (EAVE - RIM), ds)
	var v1 := Vector2(len_n, EAVE - RIM)
	var v2: Vector2 = WS + ns * (EAVE - RIM)
	var thick := 0.16
	var y0: float = TOP + thick
	var y1: float = y0 + 0.26
	_down(PackedVector2Array([w1, e1, e2, w2, WS, WM, WN]), TOP, "blanco")
	for q in [[e1, w1], [e2, e1], [w2, e2]]:        # its edge
		_plain(q[0], q[1], TOP, y0, "blanco")
	var up := func(p: Vector2, y: float) -> Vector3:
		return Vector3(p.x, y, p.y)
	roof([up.call(w1, y0), up.call(e1, y0), up.call(i1, y1), up.call(v1, y1)])
	roof([up.call(e1, y0), up.call(e2, y0), up.call(i2, y1), up.call(i1, y1)])
	roof([up.call(e2, y0), up.call(w2, y0), up.call(v2, y1), up.call(i2, y1)])
	flat(PackedVector2Array([v1, i1, i2, v2, WS, WM, WN]), y1, 0x8f8a82)
	# the hut: rendered walls, a door, a sheet of corrugated iron sloping to the street
	var a: Vector2 = WS + ds * 9.4 - ns * 0.7
	var b: Vector2 = WS + ds * 12.2 - ns * 0.7
	var w: float = face(a, b, y1)
	box(0.0, 0.0, -2.3, w, 2.1, 2.3, 0xcfc8b8)
	box(w * 0.55, 0.0, 0.0, 0.8, 1.7, 0.02, 0x6a5a48)
	for n in [1.0, -1.0]:
		quad(Vector3(-0.3, 2.1, 0.5), Vector3(w + 0.3, 2.1, 0.5), Vector3(w + 0.3, 2.7, -2.6), Vector3(-0.3, 2.7, -2.6), 0x8a8d90, Vector3(0, n, n * 0.19))
	for i in range(int((w + 0.6) / 0.19)):
		bar(Vector3(-0.3 + 0.1 + i * 0.19, 2.135, 0.5), Vector3(-0.3 + 0.1 + i * 0.19, 2.735, -2.6), 0.06, 0.03, 0x9a9da0)
	home()
	# the cage at the point: four posts, rails round them, a wire or two
	var iron := 0x3a3d40
	var c0: Vector2 = PS + dp * (len_p * 0.26) - np * 0.25
	var c1: Vector2 = PS + dp * (len_p * 0.74) - np * 0.25
	w = face(c0, c1, y1)
	for x in [0.0, w]:
		for z in [0.0, -1.2]:
			box(x - 0.02, 0.0, z - 0.02, 0.04, 1.3, 0.04, iron)
	for y in [0.35, 0.65, 0.95, 1.27]:
		for z in [0.0, -1.2]:
			box(0.0, y, z - 0.012, w, 0.024, 0.024, iron)
		for x in [0.0, w]:
			box(x - 0.012, y, -1.2, 0.024, 0.024, 1.2, iron)
	bar(Vector3(0.0, 1.3, 0.0), Vector3(w, 0.65, -1.2), 0.008, 0.008, iron)
	bar(Vector3(w, 1.3, 0.0), Vector3(0.0, 0.65, -1.2), 0.008, 0.008, iron)
	home()

# ---------------- on the pavement ----------------
## The two road signs at the point, each on its post: no way in to the Calle de Santo Domingo, and nothing wider than
## 2.7 m into the Calle de San José.
func _street() -> void:
	_post(PS + ns * 0.34 + ds * 0.12, true)
	_post(PN + Vector2(0.18, 0.34), false)

func _post(at: Vector2, no_entry: bool) -> void:
	var g: float = ground(at.x, at.y)
	posts.append(spot(at.x, at.y))
	yard.append(spot(at.x, at.y))
	cbox(Vector3(at.x, g + 1.35, at.y), Vector3(0.06, 2.7, 0.06), 0x9a9da0)
	solid(Vector3(at.x, g + 1.2, at.y), Vector3(0.14, 2.4, 0.14))
	var keep := _xf
	_xf = keep * Transform3D(Basis(Vector3.UP, atan2(np.x, np.y)), Vector3(at.x, g + 2.35, at.y))       # (its face square to the point, towards whoever comes up the street)
	var red := 0xc8281e
	slab(oval(0.0, 0.0, 0.3, 0.3, 20), 0.05, 0.02, red)
	if no_entry:
		box(-0.21, -0.05, 0.05, 0.42, 0.1, 0.004, 0xfdfcf8)
	else:
		slab(oval(0.0, 0.0, 0.235, 0.235, 20), 0.054, 0.0, 0xfdfcf8)
		_text("2,7 m", Vector3(0.0, 0.0, 0.06), 48, 0x1c1c1e, 0.0026)
		for s in [-1.0, 1.0]:
			slab(PackedVector2Array([Vector2(-0.05, s * 0.21), Vector2(0.05, s * 0.21), Vector2(0.0, s * 0.11)]), 0.058, 0.0, 0x1c1c1e)
	_xf = keep * Transform3D(Basis(Vector3.UP, atan2(np.x, np.y) + PI), Vector3(at.x, g + 2.35, at.y))
	slab(oval(0.0, 0.0, 0.3, 0.3, 20), -0.03, 0.0, 0x9a9da0)
	_xf = keep
