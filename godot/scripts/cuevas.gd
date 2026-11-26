extends "res://scripts/obra.gd"
## The dance hall of the old Madrid-Cádiz road, 140 m south of the Mercamona (the real "Sala Cuevas KUE", in the game
## "Sala Cavernas KAE": the user's name for it; the user, 25 November
## 2026: "voy a necesitar dos modelos. Uno con todo bien y otro con la pintura desgastada, tablones en las puertas y
## cosas medio rotas, que parezca desgastado. Ya que es otro de los edificios que «arreglaremos» dentro del juego"),
## built by hand in TWO states, like the old bullring (toros.gd):
##   worn            as the game begins: the dark paint of its long front gone pale and flaked, half its coloured slats
##                   gone or hanging, the doors boarded up, the lattice of its arches broken, weeds, tags, the sign half
##                   erased, the bar's canopy and the car shelter with sheets missing, the terrace's white gone grey.
##   restored        black again with all its slats, the sign lit, the red doors clean, the terrace white, its string of
##                   bulbs and its awning up, the three lamps of the front lit at dusk.
## set_restored(true / false) shows one or the other. From Catastro (5187003VJ5658N), the IGN's aerial photograph and
## Street View of 2012, 2015, 2019 and 2024 from the old road (referencias/cuevas/, tools/cuevas/).
##
## Its own frame (P(x, z), _front()): x along its front from Catastro's north-west corner towards the south, z out of
## the front towards the road, y = 0 its floor (the highest ground along the front: nothing here is terraced, the walls
## go down into the slope). The node itself keeps the map's axes, so a spot of the map is a spot of the node.

const READY := true                                # (tools/bake_godot.py looks for this)
const DIR := "res://assets/cuevas/"
const Matojos = preload("res://scripts/matojos.gd")      # (the fields' tufts of dry grass: the worn hall's weeds)
const DentroS = preload("res://scripts/cuevas_dentro.gd")      # its inside: a set of its own (the user, 25 November 2026: "Me gustaría que se pudiera pasar")
const O := Vector2(898.35, 399.28)                 # Catastro's north-west corner of the hall, on the map
const U := Vector2(-0.23202, 0.97272)              # along its front, from north to south
const OUT := Vector2(-0.97272, -0.23202)           # out of the front, towards the old road
const NAME := "SALA CAVERNAS"                      # (the user's name for it, 25 November 2026: «Sala Cavernas KAE»; never the real hall's)
const NAME_SHORT := "KAE"
const SAFFRON := Vector2(43.55, 2.85)              # where its hidden saffron grows: the corner between the bar and the foot of the ramp
const SAFFRON_ROOF := Vector2(37.7, -19.8)         # ...and another up on its roof: behind the water tank, as you come from the stair hut
const X0 := 4.2                                    # where the dark front begins (north of it, the gate of the side passage)
const X1 := 38.7                                   # ...and ends, against the bar
const XS := 41.6                                   # the hall's south wall
const BACK := -23.2                                # its east wall
const H := 3.84                                    # the front's top
const H_EAVES := 3.45
const H_RIDGE := 5.0
const PITCH := 3.63                                # from one arch to the next
const PIER := 0.44
const NICHE0 := 5.95                               # the first of the five blind arches
const NICHES := 5
const DOOR0 := 32.5                                # the arch of the doors; the last one after it is cut by the bar
const SPRING := 1.66                               # where an arch begins
const CROWN := 2.18
const TOPA := 2.32                                 # the band over the arches begins
const ND := 0.9                                    # how deep the arches are
const SILL := 0.28                                 # the kerb of the beds in the blind arches
const DOWN := -6.0                                 # how far the walls go into the ground
const BAR_X := 43.2                                # the bar's south wall
const BAR_Z := 5.0                                 # ...and its front
const BAR_H := 4.0
const WALL_Z := 0.7                                # the terrace's wall on the road side
const DECK := 0.9                                  # the terrace's floor
const WT := 4.0                                    # the top of its walls
const TER_S := 69.6                                # its south end (the aerial photograph: Catastro stops 5 m short)
const TER_E := -26.0                               # its east side
const SHELTER_Z := 8.1                             # the car shelter's eaves
const POSTS := 7                                   # ...and how many posts hold it
const YARD_S := 104.0                              # the south end of the yard beyond the terrace
const LAMPS := [4.45, 20.2, 35.95]                 # the three lamp posts of the front
const SLATS := [0xe8c832, 0xe9e6dd, 0x58a8d8, 0xd8589a, 0x4a9a58, 0xe07a30, 0x8a5ab8, 0xe8907a]
const TAGS := ["bordillo", "nietos", "al_prao"]    # (the peñas' tags: assets/penas/)
const OPEN_FROM := 23.0                            # restored, it opens at night: from this hour...
const OPEN_TO := 6.0                               # ...to this one of the morning (the user to Sistemas, 25 Nov 2026, of the people in it: "cuando esté arreglado de 23:00-06:00")
const OPEN_DAYS := [3, 4, 5, 6]                    # ...the nights of these days (0 = Monday): the user, 25 Nov 2026, "que solo abra jueves, viernes, sábados y domingos"
const BILL := "DE JUEVES\nA DOMINGO"               # what the board by its doors says
const RIDGE_Z := BACK / 2.0                        # the ridge of the hall's roof
const ROOF_LIFT := 0.03                            # how far over its sheets you walk
const ROOF_IN := 0.3                               # how far in from its edge you are stopped
const HUT := Rect2(10.0, -16.4, 3.0, 3.0)          # the stair hut on it (x, z; along the front, deep), behind the ridge
const HUT_TOP := 7.15
const HUT_DOOR_Z := -14.9                          # its door, in its south side: out of it you face the road and the town, and the camera behind you is over the open roof (not over the hut: the first try, its door to the road)
const TURBINES := [8.0, 18.0, 28.0, 38.0]          # the spinning vents on the ridge
const AC_ROW := [[7.0, 2], [8.5, 2], [10.0, 2], [11.6, 1], [13.0, 1]]      # the air conditioners behind the front's parapet: where along it, how many fans
const DOOR_X := DOOR0 + PIER / 2.0 + 0.1 + 1.025   # the middle of its doors, along the front

var restored := false
var saffron_spot: Vector2                           # where its hidden saffron flower grows, on the map
var saffron_roof: Vector2                           # ...and the one on its roof (in the game's flowers, "id": "cuevas_azotea")
var lamps: Array = []                              # the lamps of the front, in the world (lit only when restored)
var slats_whole := 0                               # how many coloured slats the restored front has...
var slats_left := 0                                # ...and how many are still up on the worn one
var boards := 0                                    # planks nailed over doors (worn)
var dentro                                         # its inside (cuevas_dentro.gd): walked into only when restored and open
var is_open := false                               # restored, and at night: its doors open, the arrow before them, the music heard from the road
var roof_ring: PackedVector2Array                  # the roof you can walk on, on the map
var acs := 0                                       # air conditioners on the roof (each state has the same)
var aerials := 0                                   # ...and aerials and dishes
var rails: StaticBody3D                            # what keeps you on the roof: seen by nobody, and not by the camera
var _roof_lamps: Array = []                        # the roof's lamps (restored): lit at night
var _door_shut: Node3D                             # the restored hall's doors, shut...
var _door_open: Node3D                             # ...and open, the light of the party in the doorway
var _state := {}                                   # "viejo" / "nuevo" -> its node
var _into: Node3D                                  # the node of the state being built
var _turn := 0.0
var _tufts: Array = []                             # the weeds of the state being built: [where, how big]

func _own(file: String, metres: float, tint := Color.WHITE) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = Parts.texture(DIR + file)
	m.albedo_color = tint
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE / metres
	m.roughness = 1.0
	m.metallic_specular = 0.0
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m

func _cut(path: String, tint := Color.WHITE, lit := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = Parts.texture(path)
	m.albedo_color = tint
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.4
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 1.0
	m.metallic_specular = 0.0
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if lit:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func _sheet(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.55
	m.metallic = 0.3
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	var k: String = String(key) if key is String else ""
	match k:
		"negro":            # the front, freshly painted: anthracite on rough render, its grain showing (flat black hid the shapes and the outlines: the user)
			m = _own("pintura_nueva.png", 4.0)
		"viejo":            # ...and as the years have left it
			m = _own("pintura_vieja.png", 4.0)
		"crema":
			m = Tex.mat("painted_plaster_wall", Color(0.94, 0.88, 0.72))
		"crema_vieja":
			m = Tex.mat("plastered_wall_04@2.6", Color(0.86, 0.8, 0.66), false)
		"blanco_viejo":
			m = _own("blanco_viejo.png", 4.0)
		"gris":             # the render of its back walls
			m = Tex.mat("granular_concrete", Color(0.8, 0.79, 0.76))
		"gris_viejo":
			m = Tex.mat("plastered_wall_04@3.0", Color(0.66, 0.65, 0.62), false)
		"panel":            # the precast panels of the fence north of it
			m = Tex.mat("granular_concrete", Color(0.9, 0.89, 0.86))
		"chapa":
			m = _sheet(Color(0.66, 0.69, 0.71))
		"chapa_vieja":
			m = _sheet(Color(0.5, 0.44, 0.38))
		"acera":
			m = W._tmat(0xd2cdc2, "pavement", 2.0)
		"solado":
			m = Tex.mat("granular_concrete", Color(0.86, 0.83, 0.78))
		"piedra":
			m = Tex.mat("rock_wall", Color(0.9, 0.86, 0.8))
		"tablon":
			m = Tex.mat("weathered_planks", Color(0.86, 0.8, 0.7))
		"celosia":
			m = _cut(DIR + "celosia.png", Color(0.36, 0.36, 0.4))
		"celosia_vieja":
			m = _cut(DIR + "celosia.png", Color(0.5, 0.5, 0.53))
		"marca":
			m = _cut(DIR + "marca.png", Color.WHITE, true)
		"marca_vieja":
			m = _cut(DIR + "marca_vieja.png", Color(0.75, 0.75, 0.73))
		"leaf":
			m = W._tmat(0x4f8a48, "leaf", 1.1)
		"mata":             # weeds gone dry
			m = W._tmat(0x8b9450, "leaf", 0.9)
		"cipres":
			m = W._tmat(0x36573b, "leaf", 1.2)
		"tierra":
			m = W._tmat(0x8a6f50, "earth", 2.0)
		"puerta_luz":       # the doorway, open at night: the party's light, brighter towards the floor
			var gr := Gradient.new()
			gr.set_color(0, Color(0.14, 0.03, 0.2))
			gr.set_color(1, Color(0.95, 0.25, 0.75))
			var gt := GradientTexture2D.new()
			gt.gradient = gr
			gt.width = 8
			gt.height = 64
			gt.fill_from = Vector2(0.5, 0.0)
			gt.fill_to = Vector2(0.5, 1.0)
			var dm := StandardMaterial3D.new()
			dm.albedo_texture = gt
			dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m = dm
		"cristal":
			var gm := StandardMaterial3D.new()
			gm.albedo_color = Color(0.08, 0.1, 0.12)
			gm.roughness = 0.25
			m = gm
		_:
			if k.begins_with("tag_"):            # a peña's tag on the wall, as old as the wall
				m = _cut("res://assets/penas/%s.png" % k.substr(4), Color(0.82, 0.8, 0.78))
			elif k.begins_with("luz_"):          # a bulb: bright by itself
				var lm := StandardMaterial3D.new()
				lm.albedo_color = Parts.col(k.substr(4).hex_to_int())
				lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				m = lm
			else:
				return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	_turn = atan2(-U.y, U.x)
	var top := -1e9
	for i in range(18):
		top = maxf(top, MapData.height(P(X0 + i * 2.03, 0.3)))
	level = top + 0.03
	transform = Transform3D(Basis.IDENTITY, Vector3(0, level, 0))
	W.add_child(self)
	_solid_parts()
	_roof_floor()
	for st in ["viejo", "nuevo"]:
		var fine: bool = st == "nuevo"
		_into = Node3D.new()
		_into.name = st
		add_child(_into)
		_tools = {}
		_hall(fine)
		_front_wall(fine)
		_slats(fine)
		_sign(fine)
		_posts(fine)
		_billboard(fine)
		_roof_top(fine)
		_north(fine)
		_bar(fine)
		_terrace(fine)
		_shelter(fine)
		_ramp(fine)
		_crates(fine)
		_yard(fine)
		_back(fine)
		_pavement(fine)
		for key in _tools:
			var mi := MeshInstance3D.new()
			var tool: SurfaceTool = _tools[key]
			if key is String and (key as String).begins_with("tiles"):
				tool.generate_tangents()
			mi.mesh = tool.commit()
			mi.material_override = _material(key)
			_into.add_child(mi)
		_tools = {}
		_grow()
		if fine:
			_door_states()
		_state[st] = _into
	_tell_map()
	_saffron()
	_saffron_roof()
	dentro = DentroS.new()                             # (its doors on the way in: the arrow stands before them)
	dentro.build(world, P(DOOR_X, -0.6), P(DOOR_X, 1.9), atan2(OUT.x, OUT.y),
		P(HUT.end.x + 0.1, HUT_DOOR_Z), P(HUT.end.x + 2.6, HUT_DOOR_Z), atan2(OUT.x, OUT.y))      # (...and the stair hut's door up on the roof: from the DJ's mezzanine)
	set_restored(OS.get_cmdline_user_args().has("--cuevas-arreglada"))

## worn, or as the works leave it: what is seen, and whether its lamps are the town's to light at dusk
func set_restored(on: bool) -> void:
	restored = on
	for st in _state:
		(_state[st] as Node3D).visible = (st == "nuevo") == on
	for p in lamps:
		if on and not W.lamp_spots.has(p):
			W.lamp_spots.append(p)
		elif not on:
			W.lamp_spots.erase(p)
	set_open(on and opens(_day(), _hour()))

## Whether it is open on that day of the week (0 = Monday) at that hour, once restored: the nights of Thursday, Friday,
## Saturday and Sunday (the user, 25 November 2026). A night is its day's: after midnight it is still last night's, so
## it is open on Monday until six and shut on Thursday until eleven at night.
static func opens(day: int, hour: float) -> bool:
	if hour >= OPEN_FROM:
		return posmod(day, 7) in OPEN_DAYS
	if hour < OPEN_TO:
		return posmod(day - 1, 7) in OPEN_DAYS
	return false

func _hour() -> float:
	var game = W.get_parent() if W != null else null
	return float(game.clock) if game != null and "clock" in game else 12.0

func _day() -> int:
	var game = W.get_parent() if W != null else null
	return int(game.weekday) if game != null and "weekday" in game else 3

## its doors open or shut (only the restored hall's: worn, they are boarded up), and with them the way in
func set_open(on: bool) -> void:
	is_open = on and restored
	if dentro != null:
		dentro.open = is_open
	if _door_shut != null:
		_door_shut.visible = not is_open
		_door_open.visible = is_open

func _process(_delta: float) -> void:
	var hour := _hour()
	var want: bool = restored and opens(_day(), hour)
	if want != is_open:
		set_open(want)
	var dark: bool = hour >= 20.0 or hour < 7.5
	for l: OmniLight3D in _roof_lamps:
		if l.visible != dark:
			l.visible = dark
	# the way down from the roof: its arrow only while you are up there (it is not to be seen from the street)
	if dentro != null and dentro.azotea != null:
		var game = W.get_parent() if W != null else null
		var up: bool = game != null and game.get("player") != null and not bool(game.indoors) and on_roof(game.player.p)
		if dentro.azotea.open != up:
			dentro.azotea.open = up

## is this spot of the map on the hall's roof?
func on_roof(p: Vector2) -> bool:
	return p.distance_squared_to(P((X0 + XS) / 2.0, RIDGE_Z)) < 500.0 and Geometry2D.is_point_in_polygon(p, roof_ring)

# ---------------- helpers ----------------
## a spot of the hall on the map: x along its front, z out of it
func P(x: float, z: float) -> Vector2:
	return O + U * x + OUT * z

## the ground at a spot of the map, as a height in this place
func gr(p: Vector2) -> float:
	return MapData.height(p) - level

## ...and at a spot of the hall
func g(x: float, z: float) -> float:
	return gr(P(x, z))

func _front() -> void:
	_xf = Transform3D(Basis(Vector3(U.x, 0, U.y), Vector3.UP, Vector3(OUT.x, 0, OUT.y)), Vector3(O.x, 0, O.y))

## (the kit's helpers go back to the front's frame, not to the map's)
func home() -> void:
	_front()

## the frame of a wall from a to b (spots of the hall), seen from outside: x along it, z out of it
func wall(a: Vector2, b: Vector2) -> float:
	return face(P(a.x, a.y), P(b.x, b.y))

## a number between 0 and 1, always the same for the same k (it is worn the same every time)
func _roll(k: int, salt := 0) -> float:
	return fposmod(sin(k * 12.9898 + salt * 78.233) * 43758.5453, 1.0)

func _fade(hex: int, how: float) -> Color:
	var c: Color = Parts.col(hex)
	var grey := c.get_luminance() * 0.9 + 0.12
	return c.lerp(Color(grey, grey, grey * 1.03), how)

## a flat piece of wall on the plane z of the frame being built
func _rect(x0: float, x1: float, y0: float, y1: float, z: float, key) -> void:
	if x1 - x0 < 0.001 or y1 - y0 < 0.001:
		return
	pieces += 1
	quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1))

## ...wearing a picture that repeats every `metres`
func _tile(x0: float, x1: float, y0: float, y1: float, z: float, key, metres: float) -> void:
	pieces += 1
	var uv := [Vector2(x0, -y0) / metres, Vector2(x1, -y0) / metres, Vector2(x1, -y1) / metres, Vector2(x0, -y1) / metres]
	quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1), uv)

## ...wearing one picture, whole
func _pic(x0: float, x1: float, y0: float, y1: float, z: float, key) -> void:
	pieces += 1
	quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

## a plate of this outline (x, y) between the planes z0 and z1 of the frame being built: both faces and its edge
func _plate(pts: PackedVector2Array, z0: float, z1: float, key) -> void:
	pieces += 1
	var idx := Geometry2D.triangulate_polygon(pts)
	for t in range(0, idx.size(), 3):
		var a: Vector2 = pts[idx[t]]
		var b: Vector2 = pts[idx[t + 1]]
		var c: Vector2 = pts[idx[t + 2]]
		tri(Vector3(a.x, a.y, z1), Vector3(b.x, b.y, z1), Vector3(c.x, c.y, z1), key, Vector3(0, 0, 1))
		tri(Vector3(a.x, a.y, z0), Vector3(b.x, b.y, z0), Vector3(c.x, c.y, z0), key, Vector3(0, 0, -1))
	var area := 0.0
	for i in range(pts.size()):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		area += a.x * b.y - b.x * a.y
	var side := 1.0 if area > 0.0 else -1.0
	for i in range(pts.size()):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		var d: Vector2 = (b - a).normalized()
		quad(Vector3(a.x, a.y, z0), Vector3(b.x, b.y, z0), Vector3(b.x, b.y, z1), Vector3(a.x, a.y, z1), key, Vector3(d.y, -d.x, 0.0) * side)

## the walls round this outline (spots of the hall), from y0 to y1, facing out
func _ring_walls(pts: Array, y0: float, y1: float, key, skip: Array = []) -> void:
	var area := 0.0
	for i in range(pts.size()):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		area += a.x * b.y - b.x * a.y
	for i in range(pts.size()):
		if skip.has(i):
			continue
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		var ln: float = wall(b, a) if area > 0.0 else wall(a, b)
		_rect(0.0, ln, y0, y1, 0.0, key)
	_front()

## a wall standing on its own from a to b (spots of the hall), `tall` over the ground and following it
func _fence(a: Vector2, b: Vector2, tall: float, key, thick := 0.2, step := 2.5) -> void:
	var ln := wall(a, b)
	var n := maxi(1, int(ceil(ln / step)))
	for i in range(n):
		var xa := ln * i / n
		var xb := ln * (i + 1) / n
		var ya: float = gr(P(lerpf(a.x, b.x, float(i) / n), lerpf(a.y, b.y, float(i) / n))) + tall
		var yb: float = gr(P(lerpf(a.x, b.x, float(i + 1) / n), lerpf(a.y, b.y, float(i + 1) / n))) + tall
		pieces += 1
		quad(Vector3(xa, DOWN, 0), Vector3(xb, DOWN, 0), Vector3(xb, yb, 0), Vector3(xa, ya, 0), key, Vector3(0, 0, 1))
		quad(Vector3(xa, DOWN, -thick), Vector3(xb, DOWN, -thick), Vector3(xb, yb, -thick), Vector3(xa, ya, -thick), key, Vector3(0, 0, -1))
		quad(Vector3(xa, ya, 0), Vector3(xb, yb, 0), Vector3(xb, yb, -thick), Vector3(xa, ya, -thick), key, Vector3.UP)
	quad(Vector3(0, DOWN, -thick), Vector3(0, DOWN, 0), Vector3(0, gr(P(a.x, a.y)) + tall, 0), Vector3(0, gr(P(a.x, a.y)) + tall, -thick), key, Vector3(-1, 0, 0))
	quad(Vector3(ln, DOWN, -thick), Vector3(ln, DOWN, 0), Vector3(ln, gr(P(b.x, b.y)) + tall, 0), Vector3(ln, gr(P(b.x, b.y)) + tall, -thick), key, Vector3(1, 0, 0))
	var mid: Vector2 = P((a.x + b.x) / 2.0, (a.y + b.y) / 2.0)
	yard.append(mid)
	_front()

## a solid box given in the hall's frame
func _sol(x0: float, x1: float, y0: float, y1: float, z0: float, z1: float) -> void:
	var m := P((x0 + x1) / 2.0, (z0 + z1) / 2.0)
	solid(Vector3(m.x, (y0 + y1) / 2.0, m.y), Vector3(x1 - x0, y1 - y0, z1 - z0), _turn)

## a solid of this outline (spots of the hall)
func _sol_ring(pts: Array, y0: float, y1: float) -> void:
	var mp: Array = []
	for q: Vector2 in pts:
		mp.append(P(q.x, q.y))
	_prism(mp, y0, y1)

func _ccw(p: PackedVector2Array) -> PackedVector2Array:
	if Geometry2D.is_polygon_clockwise(p):
		p.reverse()
	return p

func _facets(box_: Rect2) -> Array:
	var out: Array = []
	var rg: float = MapData.rg
	for i in range(int(floor((box_.position.x - MapData.rx0) / rg)), int(floor((box_.end.x - MapData.rx0) / rg)) + 1):
		for j in range(int(floor((box_.position.y - MapData.rz0) / rg)), int(floor((box_.end.y - MapData.rz0) / rg)) + 1):
			var a := Vector2(MapData.rx0 + i * rg, MapData.rz0 + j * rg)
			out.append(_ccw(PackedVector2Array([a, a + Vector2(rg, 0), a + Vector2(rg, rg)])))
			out.append(_ccw(PackedVector2Array([a, a + Vector2(rg, rg), a + Vector2(0, rg)])))
	return out

## a flat piece of this outline (spots of the hall) laid on the ground `lift` over it, cut along the relief's facets
func _lay(pts: Array, lift: float, key) -> void:
	pieces += 1
	var keep := _xf
	_xf = Transform3D.IDENTITY
	var raw := PackedVector2Array()
	for q: Vector2 in pts:
		raw.append(P(q.x, q.y))
	var mp := _ccw(raw)
	var bx := Rect2(mp[0], Vector2.ZERO)
	for q in mp:
		bx = bx.expand(q)
	for facet: PackedVector2Array in _facets(bx):
		for piece in Geometry2D.intersect_polygons(mp, facet):
			if piece.size() < 3 or Geometry2D.is_polygon_clockwise(piece):
				continue
			var idx := Geometry2D.triangulate_polygon(piece)
			for t in range(0, idx.size(), 3):
				var a: Vector2 = piece[idx[t]]
				var b: Vector2 = piece[idx[t + 1]]
				var c: Vector2 = piece[idx[t + 2]]
				tri(Vector3(a.x, gr(a) + lift, a.y), Vector3(b.x, gr(b) + lift, b.y), Vector3(c.x, gr(c) + lift, c.y), key, Vector3.UP)
	_xf = keep

## words on the wall being built, in the node of the state being built (`lit`: bright by night too)
func _word(s: String, at: Vector3, px: int, hex: int, pixel: float, lit: bool, bold := 0) -> Label3D:
	var l := Label3D.new()
	l.text = s
	l.font_size = px
	l.pixel_size = pixel
	l.modulate = Parts.col(hex)
	l.outline_size = bold
	l.outline_modulate = Parts.col(hex)
	l.shaded = not lit
	l.transform = _xf * Transform3D(Basis(), at)
	_into.add_child(l)
	return l

## a shrub; or, dry ("mata"), a clump of weeds: one of the fields' own tufts
func _bush(at: Vector3, r: float, key) -> void:
	if key is String and key == "mata":
		_tufts.append([_xf * at, r * 2.4])
		return
	ball(at + Vector3(0, r * 0.55, 0), r, key, 0.75, 8, 5)

## the weeds of the state just built: the fields' own tufts of dead grass (matojos.gd's), as it shows them
func _grow() -> void:
	if _tufts.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = Matojos._tuft_mesh()
	mm.instance_count = _tufts.size()
	var straw: Array = [Color(1.0, 0.97, 0.9), Color(0.9, 0.84, 0.72), Color(0.82, 0.77, 0.7), Color(1.0, 0.9, 0.74)]
	for k in range(_tufts.size()):
		var at: Vector3 = _tufts[k][0]
		var sc: float = _tufts[k][1]
		var b := Basis(Vector3.UP, _roll(k, 71) * TAU).scaled(Vector3(sc * (0.85 + _roll(k, 73) * 0.35), sc, sc * (0.85 + _roll(k, 75) * 0.35)))
		mm.set_instance_transform(k, Transform3D(b, at - Vector3(0, 0.02, 0)))
		var tint: Color = straw[k % straw.size()]
		mm.set_instance_color(k, tint * (0.88 + _roll(k, 77) * 0.17))
	var grass := MultiMeshInstance3D.new()
	grass.multimesh = mm
	var gm := StandardMaterial3D.new()
	gm.vertex_color_use_as_albedo = true
	gm.cull_mode = BaseMaterial3D.CULL_DISABLED
	gm.roughness = 1.0
	grass.material_override = gm
	_into.add_child(grass)
	_tufts = []

## planks nailed across an opening of the wall being built (x0..x1, round the height y), z out of it
func _planks(x0: float, x1: float, ys: Array, z: float, k: int) -> void:
	for i in range(ys.size()):
		var y: float = ys[i]
		var tilt: float = (_roll(k + i, 31) - 0.5) * 0.5
		var a := Vector3(x0 - 0.12, y - tilt * (x1 - x0) / 2.0, z)
		var b := Vector3(x1 + 0.12, y + tilt * (x1 - x0) / 2.0, z)
		bar(a, b, 0.03, 0.19, "tablon")
		boards += 1

## A saffron flower hidden under the car shelter, in the corner between the bar's wall and the foot of the ramp, behind
## the stack of crates as you come from the road (the user, 25 November 2026, choosing where: «Azafrán bajo el
## cobertizo»). The flower is the game's to take away; it counts once a game, as the other hidden ones. It is there
## whether the hall is worn or restored.
func _saffron() -> void:
	var at := P(SAFFRON.x, SAFFRON.y)
	var flower := Node3D.new()
	flower.add_child(Parts.part("cyl", 0x5f9c4a, Vector3(0, 0.3, 0), Vector3(0.03, 0.6, 0.03)))
	for k in range(5):
		flower.add_child(Parts.part("ball", 0x9b5de5, Vector3(cos(k * 1.257) * 0.12, 0.66, sin(k * 1.257) * 0.12), Vector3(0.11, 0.2, 0.11)))
	flower.add_child(Parts.part("ball", 0xe63946, Vector3(0, 0.74, 0), Vector3(0.05, 0.13, 0.05)))
	flower.position = Vector3(at.x, gr(at) - 0.06, at.y)
	add_child(flower)
	saffron_spot = at
	var game = W.get_parent()                           # (the game: the world is its child)
	if game != null and game.get("flowers") != null:
		(game.flowers as Array).append({"node": flower, "p": saffron_spot, "id": "cuevas", "hidden": true})      # (hidden: Sistemas keeps count of these)

## Another saffron flower up on the roof (the user, 26 November 2026: «Pon un azafrán en la azotea y otro en la
## Kueva»): in an old flower pot behind the water tank, at the south end of the back slope -- the tank hides it as you
## come out of the stair hut. There in both states (the roof is reached only with the hall restored and open); it
## counts once a game, as the other hidden ones.
func _saffron_roof() -> void:
	var at := P(SAFFRON_ROOF.x, SAFFRON_ROOF.y)
	var top := roof_y(SAFFRON_ROOF.y) + ROOF_LIFT
	var tiesto := Node3D.new()                          # (apart from the flower: the game makes the flower float and turn)
	tiesto.add_child(Parts.part("cyl", 0xa85a36, Vector3(0, 0.1, 0), Vector3(0.3, 0.24, 0.3)))
	tiesto.add_child(Parts.part("cyl", 0x8a4628, Vector3(0, 0.215, 0), Vector3(0.34, 0.04, 0.34)))
	tiesto.add_child(Parts.part("cyl", 0x3a2a1e, Vector3(0, 0.238, 0), Vector3(0.28, 0.012, 0.28)))
	tiesto.position = Vector3(at.x, top - 0.04, at.y)
	add_child(tiesto)
	var flower := Node3D.new()
	flower.add_child(Parts.part("cyl", 0x5f9c4a, Vector3(0, 0.3, 0), Vector3(0.03, 0.6, 0.03)))
	for k in range(5):
		flower.add_child(Parts.part("ball", 0x9b5de5, Vector3(cos(k * 1.257) * 0.12, 0.66, sin(k * 1.257) * 0.12), Vector3(0.11, 0.2, 0.11)))
	flower.add_child(Parts.part("ball", 0xe63946, Vector3(0, 0.74, 0), Vector3(0.05, 0.13, 0.05)))
	flower.position = Vector3(at.x, top + 0.16, at.y)
	add_child(flower)
	saffron_roof = at
	var game = W.get_parent()                           # (the game: the world is its child)
	if game != null and game.get("flowers") != null:
		(game.flowers as Array).append({"node": flower, "p": saffron_roof, "id": "cuevas_azotea", "hidden": true})      # (hidden: Sistemas keeps count of these)

## the bar's empty crates stacked against its side wall, under the shelter (they hide the saffron from the road)
func _crates(fine: bool) -> void:
	_front()
	var cols: Array = [0xc23b32, 0x2f55a8, 0xd9a520, 0xc23b32, 0x3f8a4f]
	var k := 0
	for stack in [[43.42, 3.55, 3], [43.42, 4.02, 2], [43.86, 3.7, 1]]:
		var sx: float = stack[0]
		var sz: float = stack[1]
		var gy := g(sx, sz)
		for j in range(int(stack[2])):
			var hex: int = cols[k % cols.size()]
			var tilt := 0.0 if fine else (_roll(k, 91) - 0.5) * 0.5
			var col: int = hex if fine else (_fade(hex, 0.55).to_rgba32() >> 8)
			tbox(Transform3D(Basis(Vector3.UP, tilt).scaled_local(Vector3(0.4, 0.27, 0.3)), Vector3(sx, gy + 0.145 + j * 0.28, sz)), col)
			tbox(Transform3D(Basis(Vector3.UP, tilt).scaled_local(Vector3(0.34, 0.02, 0.24)), Vector3(sx, gy + 0.285 + j * 0.28, sz)), 0x1c1c1f)
			k += 1

# ---------------- what stops you (the same in both states) ----------------
func _solid_parts() -> void:
	_sol(X0, XS, DOWN, 3.3, BACK, 0.0)                                 # the hall (as high as anybody in the street reaches: its roof is walked on, _roof_floor)
	_sol(HUT.position.x, HUT.end.x, 3.3, HUT_TOP, HUT.position.y, HUT.end.y)       # on its roof: the stair hut...
	_sol(6.4, 13.7, 3.3, roof_y(-3.25) + 1.75, -3.75, -2.75)           # ...the row of air conditioners
	_sol(26.4, 29.2, 3.3, 6.5, -17.3, -15.8)                           # ...the big one and its duct
	_sol(27.4, 28.2, 3.3, 5.7, -15.8, -13.4)
	for tx: float in TURBINES:
		_sol(tx - 0.36, tx + 0.36, 3.3, 6.1, RIDGE_Z - 0.36, RIDGE_Z + 0.36)
	_sol(35.3, 36.7, 3.3, 6.3, -20.2, -18.8)                           # ...the water tank
	_sol(24.3, 32.2, 3.3, 6.4, -4.75, -2.35)                           # ...the hoarding's frame
	_sol(39.25, 39.75, 3.3, 5.6, -4.75, -4.25)                         # ...the aerial's mast
	_sol(19.0, 21.3, 3.3, roof_y(-1.5) + 0.95, -2.0, -1.0)             # ...the chairs by the parapet
	_sol(-13.2, X0, DOWN, 2.4, -0.2, 0.0)                              # the fence and the gate north of it
	_sol(X1, BAR_X, DOWN, BAR_H, 0.0, BAR_Z)                           # the bar
	_sol(BAR_X, TER_S, DOWN, WT, TER_E, WALL_Z)                        # the terrace
	_sol(XS, BAR_X, DOWN, WT, TER_E, 0.0)
	for i in range(4):                                                 # the ramp, in steps
		var x := 43.6 + i * 2.35
		_sol(x, x + 2.35 if i < 3 else 55.2, DOWN, lerpf(g(43.6, 1.5), DECK, (i + 1) / 4.0), WALL_Z, 2.35)
	for i in range(POSTS):                                             # the shelter's posts
		var px := 43.9 + i * 4.0
		_sol(px - 0.08, px + 0.08, DOWN, 2.3, SHELTER_Z - 0.28, SHELTER_Z - 0.12)
		yard.append(P(px, SHELTER_Z - 0.2))
	for x: float in LAMPS:                                             # the lamp posts
		_sol(x - 0.09, x + 0.09, DOWN, 3.0, 0.1, 0.28)
	_sol(30.4, 32.3, DOWN, 0.6, 0.0, 1.0)                              # the stone planter by the doors
	_sol(38.95, 39.07, DOWN, 2.6, 7.4, 7.52)                           # the post of the bar's canopy
	yard.append(P(39.0, 7.46))
	_sol_ring(_shed_ring(), DOWN, 3.3)                                 # the sheds behind
	_sol(51.0, 58.2, DOWN, 2.0, -33.0, TER_E)
	var north := _north_ring()                                         # the plot's wall on its north side
	for i in range(north.size() - 1):
		_sol_wall(north[i], north[i + 1], 2.4)
	var south := _yard_ring()                                          # ...and round the yard at its south end
	for i in range(south.size() - 1):
		_sol_wall(south[i], south[i + 1], 0.5)
	_sol(87.0, 95.0, DOWN, 1.5, -17.0, -9.0)                           # the white house in the yard

func _north_ring() -> Array:
	return [Vector2(0.0, 0.0), Vector2(0.0, BACK), Vector2(8.77, -35.29), Vector2(10.55, -42.37)]

func _yard_ring() -> Array:
	return [Vector2(TER_S, WALL_Z), Vector2(YARD_S, WALL_Z), Vector2(YARD_S, -20.0), Vector2(66.0, -30.0), Vector2(58.2, -33.0)]

## a wall that stops you, from a to b (spots of the hall), up to `top`
func _sol_wall(a: Vector2, b: Vector2, top: float) -> void:
	var pa := P(a.x, a.y)
	var pb := P(b.x, b.y)
	var d := (pb - pa).normalized()
	var m := (pa + pb) / 2.0
	solid(Vector3(m.x, (DOWN + top) / 2.0, m.y), Vector3(pa.distance_to(pb), top - DOWN, 0.3), atan2(-d.y, d.x))

func _shed_ring() -> Array:
	return [Vector2(8.77, -35.29), Vector2(32.48, -30.88), Vector2(33.6, BACK), Vector2(XS, BACK), Vector2(41.26, -26.76), Vector2(49.99, -26.48), Vector2(49.11, -33.28), Vector2(10.55, -42.37)]

func _tell_map() -> void:
	var rings: Array = [[Vector2(X0, 0.0), Vector2(X1, 0.0), Vector2(X1, BAR_Z), Vector2(BAR_X, BAR_Z), Vector2(BAR_X, WALL_Z), Vector2(TER_S, WALL_Z), Vector2(TER_S, TER_E), Vector2(XS, TER_E), Vector2(XS, BACK), Vector2(X0, BACK)], _shed_ring()]
	for ring: Array in rings:
		var pts := PackedVector2Array()
		for q: Vector2 in ring:
			pts.append(P(q.x, q.y))
		MapData.outlines.append(pts)
		if not MapData._wall_grid.is_empty():
			for i in range(pts.size()):
				var a: Vector2 = pts[i]
				var b: Vector2 = pts[(i + 1) % pts.size()]
				MapData._grid_add(MapData._wall_grid, a.min(b), a.max(b), [a, b])

# ---------------- the hall ----------------
func _hall(fine: bool) -> void:
	_front()
	var wk = "gris" if fine else "gris_viejo"
	var rk = "chapa" if fine else "chapa_vieja"
	_ring_walls([Vector2(X0, 0.0), Vector2(X0, BACK), Vector2(XS, BACK), Vector2(XS, 0.0)], DOWN, H_EAVES + 0.1, wk, [3])
	for end: float in [X0, XS]:                                        # its two gables
		var sgn := -1.0 if end == X0 else 1.0
		pieces += 1
		tri(Vector3(end, H_EAVES, 0.0), Vector3(end, H_EAVES, BACK), Vector3(end, H_RIDGE, BACK / 2.0), wk, Vector3(sgn, 0, 0))
	box(X0, 3.2, -0.3, XS - X0, H - 3.2, 0.29, wk)                     # the back of the front's parapet
	var ridge_a := Vector3(X0, H_RIDGE, BACK / 2.0)
	var ridge_b := Vector3(XS, H_RIDGE, BACK / 2.0)
	pieces += 2
	quad(Vector3(X0, H_EAVES, -0.3), Vector3(XS, H_EAVES, -0.3), ridge_b, ridge_a, rk, Vector3(0, 0.99, 0.13))
	quad(Vector3(XS, H_EAVES, BACK - 0.25), Vector3(X0, H_EAVES, BACK - 0.25), ridge_a, ridge_b, rk, Vector3(0, 0.99, -0.13))
	bar(ridge_a, ridge_b, 0.4, 0.08, 0x8d9196 if fine else 0x6f5f52)
	if fine:
		return
	for k in range(7):                                                 # sheets of the roof gone to rust
		var x := X0 + 3.0 + _roll(k, 2) * (XS - X0 - 8.0)
		var z := -2.0 - _roll(k, 4) * 8.5
		var y := H_EAVES + (H_RIDGE - H_EAVES) * (-z - 0.3) / (-BACK / 2.0 - 0.3) + 0.02
		tbox(Transform3D(Basis(Vector3.RIGHT, -0.134).scaled_local(Vector3(1.1, 0.02, 2.2 + _roll(k, 6) * 1.5)), Vector3(x, y, z)), 0x7a4a30)

func _arch(xa: float, xb: float, cut: float, n := 10) -> PackedVector2Array:
	var c := xb - xa
	var s := CROWN - SPRING
	var r := (c * c / 4.0 + s * s) / (2.0 * s)
	var cx := (xa + xb) / 2.0
	var cy := CROWN - r
	var th := asin(c / 2.0 / r)
	var pts := PackedVector2Array()
	for i in range(n + 1):
		var a := -th + 2.0 * th * i / n
		var q := Vector2(cx + r * sin(a), cy + r * cos(a))
		if q.x > cut + 0.001:
			var p: Vector2 = pts[pts.size() - 1]
			pts.append(p.lerp(q, (cut - p.x) / (q.x - p.x)))
			break
		pts.append(q)
	return pts

func _front_wall(fine: bool) -> void:
	_front()
	var wk = "negro" if fine else "viejo"
	var dark: int = 0x0e0e11 if fine else 0x191a1f
	_rect(X0, X1, TOPA, H, 0.0, wk)
	box(X0, H, -0.3, X1 - X0, 0.05, 0.34, 0x5a5b62 if fine else 0x4a4b50)        # its coping
	var bays: Array = []                                               # [where it begins, what it is: 0 a blind arch, 1 the doors, 2 lattice]
	for i in range(NICHES):
		bays.append([NICHE0 + i * PITCH, 0])
	bays.append([DOOR0, 1])
	bays.append([DOOR0 + PITCH, 2])
	var at := X0
	for bi in range(bays.size()):
		var b0: float = bays[bi][0]
		var kind: int = bays[bi][1]
		var xa := b0 + PIER / 2.0
		var xb := b0 + PITCH - PIER / 2.0
		var xe := minf(xb, X1)
		_rect(at, xa, DOWN, TOPA, 0.0, wk)
		at = xe
		var curve := _arch(xa, xb, X1)
		var over := PackedVector2Array([Vector2(xa, TOPA)])
		over.append_array(curve)
		over.append(Vector2(xe, TOPA))
		slab(over, 0.0, 0.0, wk)
		var mid := Vector2((xa + xb) / 2.0, CROWN - 3.0)
		for i in range(curve.size() - 1):                              # the underside of the arch
			var p: Vector2 = curve[i]
			var q: Vector2 = curve[i + 1]
			var nn: Vector2 = (mid - (p + q) / 2.0).normalized()
			quad(Vector3(p.x, p.y, -ND), Vector3(q.x, q.y, -ND), Vector3(q.x, q.y, 0), Vector3(p.x, p.y, 0), wk, Vector3(nn.x, nn.y, 0))
		pieces += 3
		quad(Vector3(xa, DOWN, -ND), Vector3(xa, DOWN, 0), Vector3(xa, SPRING, 0), Vector3(xa, SPRING, -ND), wk, Vector3(1, 0, 0))
		if xb <= X1:
			quad(Vector3(xb, DOWN, -ND), Vector3(xb, DOWN, 0), Vector3(xb, SPRING, 0), Vector3(xb, SPRING, -ND), wk, Vector3(-1, 0, 0))
		_rect(xa, xe, DOWN, TOPA, -ND, dark)                             # its back
		if kind == 0:
			_niche(fine, bi, xa, xe, wk)
		elif kind == 1:
			_doors(fine, xa, xe)
		else:
			_lattice(fine, 40 + bi, xa + 0.1, xe, 0.02, 1.95)
			quad(Vector3(xa, 0.0, -ND), Vector3(xe, 0.0, -ND), Vector3(xe, 0.0, 0), Vector3(xa, 0.0, 0), "solado", Vector3.UP)
			_rect(xa, xe, DOWN, 0.0, 0.0, wk)
	_rect(at, X1, DOWN, TOPA, 0.0, wk)
	# the stone planter by the doors
	box(30.4, DOWN, 0.0, 1.9, 0.6 - DOWN, 1.0, "piedra")
	box(30.5, 0.56, 0.1, 1.7, 0.06, 0.8, "tierra")
	if fine:
		_bush(Vector3(31.0, 0.55, 0.5), 0.5, "leaf")
		_bush(Vector3(31.8, 0.55, 0.5), 0.38, "leaf")
	else:
		_bush(Vector3(31.2, 0.55, 0.5), 0.42, "mata")
		for k in range(3):                                               # stones fallen off its corner
			cbox(Vector3(32.45 + k * 0.22, g(32.5, 1.2) + 0.09, 1.15 + _roll(k, 8) * 0.3), Vector3(0.24, 0.16, 0.2), "piedra")

## a see-through concrete lattice at the back of an arch; worn, with blocks knocked out of it
func _lattice(fine: bool, k: int, x0: float, x1: float, y0: float, y1: float) -> void:
	var z := -ND + 0.06
	if fine:
		_tile(x0, x1, y0, y1, z, "celosia", 0.8)
		return
	var n := maxi(1, int(round((x1 - x0) / 0.4)))
	for i in range(n):
		var xa := lerpf(x0, x1, float(i) / n)
		var xb := lerpf(x0, x1, float(i + 1) / n)
		var top := y1
		var gone := _roll(k * 17 + i, 3)
		if gone > 0.74:                                                # (a whole column of blocks out)
			top = y0 + 0.4 * floorf(_roll(k * 17 + i, 5) * 2.0)
		elif gone > 0.5:
			top = y1 - 0.4 * (1.0 + floorf(_roll(k * 17 + i, 7) * 2.0))
		if top > y0 + 0.01:
			_tile(xa, xb, y0, top, z, "celosia_vieja", 0.8)

func _niche(fine: bool, k: int, xa: float, xb: float, wk) -> void:
	_rect(xa, xb, DOWN, SILL, 0.0, wk)                                 # the kerb of its bed
	pieces += 2
	quad(Vector3(xa, SILL, -0.12), Vector3(xb, SILL, -0.12), Vector3(xb, SILL, 0), Vector3(xa, SILL, 0), wk, Vector3.UP)
	quad(Vector3(xa, SILL - 0.08, -ND), Vector3(xb, SILL - 0.08, -ND), Vector3(xb, SILL - 0.08, -0.12), Vector3(xa, SILL - 0.08, -0.12), "tierra", Vector3.UP)
	_rect(xa, xb, 0.0, SILL, -0.12, wk)
	_lattice(fine, k, xa + 0.12, xb - 0.12, SILL + 0.12, 1.92)
	var mx := (xa + xb) / 2.0
	if fine:
		for j in range(3):                                               # a row of shrubs, clipped
			_bush(Vector3(xa + 0.55 + j * (xb - xa - 1.1) / 2.0, SILL - 0.1, -0.45), 0.36, "leaf")
	else:
		if _roll(k, 11) > 0.35:
			_bush(Vector3(mx + (_roll(k, 12) - 0.5) * 1.6, SILL - 0.1, -0.5), 0.3 + _roll(k, 13) * 0.25, "mata")
		if k % 2 == 1:                                                   # a peña has left its name in there
			_pic(mx - 0.75, mx + 0.75, 0.55, 1.75, -ND + 0.1, "tag_%s" % TAGS[(k / 2) % TAGS.size()])
	# a tub on the pavement before the pier north of it
	var tx := xa - PIER / 2.0
	var ty := g(tx, 0.55)
	if fine or _roll(k, 15) > 0.3:
		drum(Vector3(tx, ty, 0.55), 0.33, 0.4, 0.5, 0x2c2c30 if fine else 0x4c4d52, 10)
		_bush(Vector3(tx, ty + 0.42, 0.55), 0.3 if fine else 0.22, "leaf" if fine else "mata")
	else:                                                              # (knocked over, its earth spilt)
		var keep := _xf
		_xf = _xf * Transform3D(Basis(Vector3(0, 0, 1), -1.4), Vector3(tx - 0.1, ty + 0.35, 0.78))
		drum(Vector3.ZERO, 0.33, 0.4, 0.5, 0x4c4d52, 10)
		_xf = keep
		cbox(Vector3(tx + 0.78, ty + 0.05, 0.82), Vector3(0.7, 0.1, 0.6), "tierra")
		_bush(Vector3(tx + 0.9, ty + 0.08, 0.9), 0.2, "mata")

func _doors(fine: bool, xa: float, xb: float) -> void:
	var z := -ND + 0.04
	var wk = "negro" if fine else "viejo"
	_rect(xa, xb, DOWN, 0.0, 0.0, wk)                                  # the step
	pieces += 1
	quad(Vector3(xa, 0.0, -ND), Vector3(xb, 0.0, -ND), Vector3(xb, 0.0, 0), Vector3(xa, 0.0, 0), "solado", Vector3.UP)
	var red: Color = Parts.col(0x7a1f26) if fine else _fade(0x6a2a2e, 0.45)
	var d0 := xa + 0.1
	var d1 := d0 + 2.05
	box(d0 - 0.06, 0.0, z - 0.03, d1 - d0 + 0.12, 2.16, 0.03, 0x1a1a1c)           # its frame
	if not fine:                                                       # (the restored hall's leaves open and shut: _door_states)
		_leaves(d0, d1, z, red, false)
	# the bill board beside them
	var b0 := d1 + 0.14
	var b1 := xb - 0.1
	box(b0, 0.8, z - 0.01, b1 - b0, 1.05, 0.05, 0xd8cfae if fine else 0x9c9684)
	box(b0 - 0.03, 0.77, z - 0.01, b1 - b0 + 0.06, 0.03, 0.07, 0x2a2a2e)
	box(b0 - 0.03, 1.85, z - 0.01, b1 - b0 + 0.06, 0.03, 0.07, 0x2a2a2e)
	if fine:
		_word(BILL, Vector3((b0 + b1) / 2.0, 1.5, z + 0.05), 40, 0x7a1f26, 0.0031, false, 6)      # (smaller than the name under it: «A DOMINGO» is wider than the board at that size)
		_word(NAME_SHORT, Vector3((b0 + b1) / 2.0, 1.0, z + 0.05), 40, 0x1a1a1c, 0.0038, false, 6)
	else:
		box(b0 + 0.08, 1.2, z + 0.04, (b1 - b0) * 0.5, 0.5, 0.004, 0xc9c1a4)         # what is left of the last bill
		_planks(d0 - 0.2, d1 + 0.2, [0.55, 1.15, 1.75], z + 0.1, 3)                  # the doors, boarded up
		bar(Vector3(d0, 0.1, z + 0.13), Vector3(d1, 2.0, z + 0.13), 0.03, 0.17, "tablon")
		boards += 1
		_planks(b0 - 0.05, b1 + 0.05, [1.35], z + 0.08, 9)

## the two leaves of the doors, shut
func _leaves(d0: float, d1: float, z: float, red: Color, fine: bool) -> void:
	for leaf in range(2):
		var l0 := d0 + leaf * (d1 - d0) / 2.0
		box(l0 + 0.012, 0.0, z, (d1 - d0) / 2.0 - 0.024, 2.1, 0.045, red.to_rgba32() >> 8)
		box(l0 + 0.14, 0.12, z + 0.045, (d1 - d0) / 2.0 - 0.28, 0.75, 0.012, red.darkened(0.18).to_rgba32() >> 8)      # its two panels
		box(l0 + 0.14, 1.0, z + 0.045, (d1 - d0) / 2.0 - 0.28, 0.95, 0.012, red.darkened(0.18).to_rgba32() >> 8)
		var hx := (d0 + d1) / 2.0 + (0.13 if leaf == 1 else -0.17)
		box(hx, 0.85, z + 0.05, 0.04, 0.5, 0.05, 0xc9a24a if fine else 0x6f6a5c)         # the pull

## The restored hall's doors, shut and open: two nodes of the restored state, one seen at a time (set_open). Open, the
## leaves stand back against the sides of their arch, the doorway is full of the party's light and a little of it
## falls on the pavement (a lamp with no shadows, lit only while the hall is open).
func _door_states() -> void:
	var d0 := DOOR0 + PIER / 2.0 + 0.1
	var d1 := d0 + 2.05
	var z := -ND + 0.04
	var w := (d1 - d0) / 2.0
	var red: Color = Parts.col(0x7a1f26)
	for on in [false, true]:
		var node := Node3D.new()
		node.name = "puertas_abiertas" if on else "puertas_cerradas"
		_into.add_child(node)
		_tools = {}
		_front()
		if not on:
			_leaves(d0, d1, z, red, true)
			_door_shut = node
		else:
			for leaf in range(2):
				var hx := (d0 - 0.045) if leaf == 0 else d1
				box(hx, 0.0, z, 0.045, 2.1, w - 0.03, red.to_rgba32() >> 8)
				var px := d0 if leaf == 0 else d1 - 0.012
				box(px, 0.12, z + 0.14, 0.012, 0.75, w - 0.31, red.darkened(0.18).to_rgba32() >> 8)
				box(px, 1.0, z + 0.14, 0.012, 0.95, w - 0.31, red.darkened(0.18).to_rgba32() >> 8)
				box(px - (0.0 if leaf == 0 else 0.038), 0.85, z + w - 0.2, 0.05, 0.5, 0.04, 0xc9a24a)
			quad(Vector3(d0, 0.0, z + 0.004), Vector3(d1, 0.0, z + 0.004), Vector3(d1, 2.1, z + 0.004), Vector3(d0, 2.1, z + 0.004), "puerta_luz", Vector3(0, 0, 1),
				[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
			var at := P(DOOR_X, 0.5)
			var lamp := OmniLight3D.new()
			lamp.position = Vector3(at.x, 1.5, at.y)
			lamp.light_color = Color(1.0, 0.35, 0.8)
			lamp.omni_range = 6.0
			lamp.light_energy = 1.1
			lamp.shadow_enabled = false
			node.add_child(lamp)
			_door_open = node
		for key in _tools:
			var mi := MeshInstance3D.new()
			mi.mesh = (_tools[key] as SurfaceTool).commit()
			mi.material_override = _material(key)
			node.add_child(mi)
		_tools = {}

# ---------------- the coloured slats, the sign, the lamps, the hoarding on the roof ----------------
func _slats(fine: bool) -> void:
	_front()
	var k := 0
	var whole := 0
	var left := 0
	for grp in [[6.2, 16.5, 0.47], [25.2, 30.3, 0.425]]:
		var x: float = grp[0]
		while x < float(grp[1]):
			k += 1
			var tall := 1.02 + _roll(k, 1) * 0.5
			var y0 := 2.42 + _roll(k, 2) * 0.22
			var hex: int = SLATS[(k * 3 + int(_roll(k, 3) * 3.0)) % SLATS.size()]
			whole += 1
			if fine:
				box(x - 0.08, y0, 0.0, 0.16, tall, 0.045, hex)
			else:
				var fate := _roll(k, 5)
				var col: int = _fade(hex, 0.5).to_rgba32() >> 8
				if fate < 0.36:                                            # gone: the paler mark it left
					box(x - 0.08, y0, 0.0, 0.16, tall, 0.004, 0x5d5f6a)
					if fate < 0.07:                                        # ...and the slat itself, lying at the foot of the wall
						var gy := g(x, 0.9)
						tbox(Transform3D(Basis(Vector3.UP, _roll(k, 7) * 2.0).scaled_local(Vector3(0.16, 0.045, tall)), Vector3(x + 0.3, gy + 0.08, 0.7 + _roll(k, 9) * 0.6)), col)
				elif fate < 0.52:                                          # hanging by one fixing
					var lean := (0.25 + _roll(k, 11) * 0.9) * (1.0 if _roll(k, 13) > 0.5 else -1.0)
					var top := Vector3(x, y0 + tall, 0.03)
					tbox(Transform3D(Basis(Vector3(0, 0, 1), lean).scaled_local(Vector3(0.16, tall, 0.045)), top - Basis(Vector3(0, 0, 1), lean) * Vector3(0, tall / 2.0, 0)), col)
					left += 1
				else:
					box(x - 0.08, y0, 0.0, 0.16, tall, 0.045, col)
					left += 1
			x += float(grp[2])
	if fine:
		slats_whole = whole
	else:
		slats_left = left

func _sign(fine: bool) -> void:
	_front()
	var x0 := 33.4
	var x1 := 34.9
	var mx := (x0 + x1) / 2.0
	box(x0, 2.2, 0.02, x1 - x0, 2.9, 0.2, 0x303237 if fine else 0x55575d)
	box(x0 - 0.04, 2.16, 0.02, x1 - x0 + 0.08, 0.05, 0.24, 0x1c1c1f)
	box(x0 - 0.04, 5.09, 0.02, x1 - x0 + 0.08, 0.05, 0.24, 0x1c1c1f)
	_pic(mx - 0.6, mx + 0.6, 3.72, 4.92, 0.228, "marca" if fine else "marca_vieja")
	if fine:
		_word(NAME.replace(" ", "\n"), Vector3(mx, 3.3, 0.23), 30, 0xdedcd6, 0.0052, true)
		_word(NAME_SHORT, Vector3(mx, 2.62, 0.23), 64, 0xffffff, 0.0058, true, 10)
	else:
		_word("SA A\nCAV RN S", Vector3(mx, 3.3, 0.23), 30, 0x8f8f8c, 0.0052, false)
		_word("K E", Vector3(mx, 2.62, 0.23), 64, 0x9a9a96, 0.0058, false, 10)
		tbox(Transform3D(Basis(Vector3(0, 0, 1), 0.5).scaled_local(Vector3(0.5, 0.36, 0.01)), Vector3(x0 + 0.22, 2.42, 0.232)), 0x3a3c41)      # a sheet of it peeling

func _posts(fine: bool) -> void:
	_front()
	var steel: int = 0x7d8388 if fine else 0x6a6259
	for i in range(LAMPS.size()):
		var x: float = LAMPS[i]
		var gy := g(x, 0.19)
		drum(Vector3(x, gy, 0.19), 0.085, 0.06, 6.6 - gy, steel, 8)
		var bent: bool = not fine and i == 1
		var tip := Vector3(x, 6.25, 0.75) if bent else Vector3(x, 6.95, 1.05)
		bar(Vector3(x, 6.58, 0.19), tip, 0.07, 0.07, steel)
		var head := Transform3D(Basis(Vector3.RIGHT, 1.1 if bent else 0.18).scaled_local(Vector3(0.24, 0.1, 0.56)), tip + (Vector3(0, -0.22, 0.12) if bent else Vector3(0, 0.0, 0.26)))
		tbox(head, 0x3a3c40)
		if fine:
			tbox(Transform3D(Basis(Vector3.RIGHT, 0.18).scaled_local(Vector3(0.18, 0.03, 0.4)), tip + Vector3(0, -0.06, 0.27)), "luz_fff1c4")
			lamps.append(transform * (_xf * (tip + Vector3(0, -0.2, 0.3))))

func _billboard(fine: bool) -> void:
	_front()
	var steel: int = 0x8d9196 if fine else 0x7a5a40
	var x0 := 24.4
	var x1 := 32.1
	var z := -2.5
	var y0 := H_EAVES + (H_RIDGE - H_EAVES) * 2.2 / 11.3
	var y1 := H + 1.55
	for i in range(9):
		var x := lerpf(x0, x1, i / 8.0)
		if not fine and i == 6:                                        # (an upright come loose, lying on the roof)
			bar(Vector3(x, y0 + 0.1, z - 0.3), Vector3(x + 1.4, y0 + 0.35, z - 2.0), 0.05, 0.05, steel)
			continue
		bar(Vector3(x, y0 - 0.1, z), Vector3(x, y1, z), 0.05, 0.05, steel)
		if i % 2 == 0:
			bar(Vector3(x, y1 - 0.1, z), Vector3(x, y0 + 0.4, z - 2.1), 0.04, 0.04, steel)
	for j in range(3):
		var y := lerpf(H + 0.1, y1, j / 2.0)
		bar(Vector3(x0, y, z), Vector3(x1, y, z), 0.05, 0.05, steel)
	if fine:                                                           # the hoarding on it again
		box(x0 + 0.1, H + 0.14, z + 0.03, x1 - x0 - 0.2, y1 - H - 0.2, 0.04, 0x17171a)
		_word(NAME, Vector3((x0 + x1) / 2.0, (H + 0.14 + y1 - 0.06) / 2.0, z + 0.08), 96, 0xffffff, 0.0075, true, 8)

# ---------------- the roof: walked on, and what stands on it ----------------
## The user, 25 November 2026: "Al altillo molaría poder subir y ver el pueblo desde ahí. Pon aires acondicionados
## antenas y eso". From the DJ's mezzanine (cuevas_dentro.gd) a door marked AZOTEA takes you up here: you come out of
## the stair hut by its side door, behind the ridge, the old road and the town beyond it before you.

## how high the hall's roof is at a spot of it (z: out of the front), in this place's frame
func roof_y(z: float) -> float:
	if z > RIDGE_Z:
		return lerpf(H_EAVES, H_RIDGE, (-0.3 - z) / (-0.3 - RIDGE_Z))
	return lerpf(H_RIDGE, H_EAVES, (RIDGE_Z - z) / (RIDGE_Z - BACK + 0.25))

## The roof as a floor (MapData.decks: two sloping ones, the front's first -- it reaches a hand over the ridge, so that
## nobody on the ridge is on neither), and what keeps you on it: walls nobody sees, a step in from its four edges, on
## the street furniture's layer -- you stop at them, the camera does not take them for a house, nothing stands on them.
func _roof_floor() -> void:
	var x0 := X0 + 0.02
	var x1 := XS - 0.02
	var zf := -0.02
	var zb := BACK + 0.02
	var slope_f := (H_RIDGE - H_EAVES) / (-0.3 - RIDGE_Z)
	var slope_b := (H_RIDGE - H_EAVES) / (RIDGE_Z - BACK + 0.25)
	var front := PackedVector2Array([P(x0, zf), P(x1, zf), P(x1, RIDGE_Z - 0.1), P(x0, RIDGE_Z - 0.1)])
	MapData.decks.append({"o": P((x0 + x1) / 2.0, (zf + RIDGE_Z) / 2.0), "poly": front, "r2": 420.0, "top": level + roof_y((zf + RIDGE_Z) / 2.0) + ROOF_LIFT, "grad": -OUT * slope_f})
	var back := PackedVector2Array([P(x0, RIDGE_Z), P(x1, RIDGE_Z), P(x1, zb), P(x0, zb)])
	MapData.decks.append({"o": P((x0 + x1) / 2.0, (RIDGE_Z + zb) / 2.0), "poly": back, "r2": 420.0, "top": level + roof_y((RIDGE_Z + zb) / 2.0) + ROOF_LIFT, "grad": OUT * slope_b})
	roof_ring = PackedVector2Array([P(x0, zf), P(x1, zf), P(x1, zb), P(x0, zb)])
	rails = StaticBody3D.new()
	rails.collision_layer = 16
	rails.collision_mask = 0
	W.add_child(rails)
	var sides: Array = [Rect2(X0, -ROOF_IN, XS - X0, ROOF_IN), Rect2(X0, BACK, XS - X0, ROOF_IN), Rect2(X0, BACK, ROOF_IN, -BACK), Rect2(XS - ROOF_IN, BACK, ROOF_IN, -BACK)]
	for r: Rect2 in sides:
		var m := P(r.position.x + r.size.x / 2.0, r.position.y + r.size.y / 2.0)
		var cs := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = Vector3(r.size.x, 4.6, r.size.y)
		cs.shape = b
		cs.transform = transform * Transform3D(Basis(Vector3.UP, _turn), Vector3(m.x, 5.5, m.y))      # (from 3.2 m to 7.8 m: over a jump from the ridge)
		rails.add_child(cs)

## a level bench of angle iron on the sloping sheets, for something to stand on: the height of its top
func _bench(x0: float, x1: float, z0: float, z1: float, steel: int) -> float:
	var top := maxf(roof_y(z0), roof_y(z1)) + 0.14
	var feet: Array = [Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)]
	for i in range(4):
		var v: Vector2 = feet[i]
		var w: Vector2 = feet[(i + 1) % 4]
		bar(Vector3(v.x, roof_y(v.y) - 0.02, v.y), Vector3(v.x, top, v.y), 0.05, 0.05, steel)
		bar(Vector3(v.x, top - 0.025, v.y), Vector3(w.x, top - 0.025, w.y), 0.05, 0.05, steel)
	return top

## An air conditioner's outdoor unit, standing where `xf` puts its foot's middle, its fans looking out along +z: a
## box with a round grille for each fan, louvres down its side, feet. Worn: gone yellow, rust running down it, a
## grille missing.
func _ac(xf: Transform3D, fans: int, fine: bool, k: int) -> void:
	var keep := _xf
	var here := keep * xf
	_xf = here
	var w := 0.98
	var d := 0.42
	var h := 0.72 if fans == 1 else 1.32
	var skin: int = 0xdcdcd4 if fine else (0xb9b09c if _roll(k, 41) > 0.4 else 0xa59880)
	var wire: int = 0x8a8e92 if fine else 0x6f5a48
	box(-w / 2.0, 0.06, -d / 2.0, w, h, d, skin)
	box(-w / 2.0 - 0.01, 0.0, -d / 2.0 - 0.01, 0.12, 0.06, d + 0.02, 0x3a3c40)
	box(w / 2.0 - 0.11, 0.0, -d / 2.0 - 0.01, 0.12, 0.06, d + 0.02, 0x3a3c40)
	box(-w / 2.0 - 0.012, 0.06 + h - 0.05, -d / 2.0 - 0.012, w + 0.024, 0.05, d + 0.024, 0xc4c4bc if fine else 0x8f8570)      # its lid
	for f in range(fans):
		var cy := 0.42 + f * 0.62
		var gone: bool = not fine and (k + f) % 3 == 0
		_xf = here * Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(-0.14, cy, d / 2.0))      # (a drum lying on its side: the fan's round mouth)
		drum(Vector3.ZERO, 0.27, 0.27, 0.006, 0x1c1c20, 14)
		if not gone:
			drum(Vector3(0, 0.006, 0), 0.07, 0.07, 0.012, wire, 8)
		_xf = here
		if gone:
			continue
		for j in range(5):                                                     # the bars of its grille
			var gy := cy - 0.22 + j * 0.11
			var half := sqrt(maxf(0.0, 0.27 * 0.27 - (gy - cy) * (gy - cy)))
			box(-0.14 - half, gy - 0.006, d / 2.0 + 0.012, 2.0 * half, 0.012, 0.008, wire)
		box(-0.146, cy - 0.27, d / 2.0 + 0.014, 0.012, 0.54, 0.008, wire)
	for j in range(int(h / 0.09) - 2):                                         # the louvres down its side
		box(0.26, 0.2 + j * 0.09, d / 2.0 + 0.002, 0.18, 0.02, 0.008, 0xa8a8a0 if fine else 0x8a7e68)
	if not fine:
		for j in range(3):
			var rx := -w / 2.0 + 0.1 + _roll(k * 7 + j, 43) * (w - 0.3)
			var run := 0.2 + 0.3 * _roll(k * 7 + j, 44)
			box(rx, 0.06 + h - 0.05 - run, d / 2.0 + 0.003, 0.05 + 0.08 * _roll(k * 7 + j, 45), run, 0.004, 0x7a4a30)
	_xf = keep
	acs += 1

## one of the spinning vents on the ridge: a saddle, a neck, a ribbed head. Worn: rusty, and one has lost its head.
func _turbine(x: float, fine: bool, k: int) -> void:
	var steel: int = 0xb8bcc0 if fine else 0x8a6a50
	box(x - 0.34, H_RIDGE - 0.12, RIDGE_Z - 0.34, 0.68, 0.16, 0.68, steel)
	drum(Vector3(x, H_RIDGE + 0.04, RIDGE_Z), 0.2, 0.2, 0.3, steel, 10)
	if not fine and k == 2:
		return
	ball(Vector3(x, H_RIDGE + 0.57, RIDGE_Z), 0.3, steel, 0.8, 12, 6)
	for j in range(12):                                                        # its vanes
		var a := TAU * j / 12.0
		tbox(Transform3D(Basis(Vector3.UP, 0.5 - a).scaled_local(Vector3(0.02, 0.4, 0.16)), Vector3(x + cos(a) * 0.3, H_RIDGE + 0.57, RIDGE_Z + sin(a) * 0.3)), 0x8a8e92 if fine else 0x6f5340)
	drum(Vector3(x, H_RIDGE + 0.8, RIDGE_Z), 0.12, 0.03, 0.06, steel, 10)

## A TV aerial on its mast, the mast's foot at `foot`, the aerial looking along `yaw`: the long one with its many
## elements and its reflector, a short one under it. Worn, the mast leans and the short one has swung down.
func _aerial(foot: Vector3, tall: float, yaw: float, fine: bool, k: int) -> void:
	var steel: int = 0x9a9ea2 if fine else 0x7a6a58
	var lean := Basis.IDENTITY if fine else Basis(Vector3(0, 0, 1), 0.18 + 0.16 * _roll(k, 51))
	var keep := _xf
	_xf = keep * Transform3D(Basis(Vector3.UP, yaw) * lean, foot)
	drum(Vector3.ZERO, 0.028, 0.022, tall, steel, 6)
	var by := tall - 0.22
	bar(Vector3(-0.22, by, 0.0), Vector3(1.3, by, 0.0), 0.025, 0.025, steel)
	for j in range(9):
		var half := 0.3 - j * 0.02
		bar(Vector3(-0.05 + j * 0.15, by + 0.02, -half), Vector3(-0.05 + j * 0.15, by + 0.02, half), 0.012, 0.012, steel)
	for sy: float in [-1.0, 1.0]:                                              # its reflector, in a V
		bar(Vector3(-0.2, by, 0.0), Vector3(-0.34, by + sy * 0.3, 0.0), 0.015, 0.015, steel)
		bar(Vector3(-0.34, by + sy * 0.3, -0.3), Vector3(-0.34, by + sy * 0.3, 0.3), 0.012, 0.012, steel)
	var by2 := tall - 0.95
	var drop := 0.0 if fine else -0.45
	bar(Vector3(0.0, by2, 0.0), Vector3(0.0, by2 + drop, 0.6), 0.02, 0.02, steel)
	for j in range(4):
		var t := (0.12 + j * 0.15) / 0.6
		bar(Vector3(-0.24, by2 + drop * t, 0.12 + j * 0.15), Vector3(0.24, by2 + drop * t, 0.12 + j * 0.15), 0.012, 0.012, steel)
	_xf = keep
	aerials += 1

## a satellite dish on its arm, at `at`, looking along `yaw` and up at the sky. Worn: hanging face down.
func _dish(at: Vector3, yaw: float, fine: bool) -> void:
	var keep := _xf
	var white: int = 0xe4e4de if fine else 0xa9a08c
	_xf = keep * Transform3D(Basis(Vector3.UP, yaw), at)
	bar(Vector3(0, -0.5, -0.12), Vector3(0, 0.0, -0.12), 0.04, 0.04, 0x8a8e92 if fine else 0x6f5a48)
	_xf = keep * Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, deg_to_rad(62.0 if fine else 150.0)), at)
	drum(Vector3(0, -0.02, 0), 0.08, 0.4, 0.09, white, 14)
	drum(Vector3(0, 0.068, 0), 0.4, 0.4, 0.006, 0xcfcfc8 if fine else 0x8f8674, 14)
	bar(Vector3(0, 0.07, -0.36), Vector3(0, 0.46, 0.0), 0.018, 0.018, 0x8a8e92)      # the arm of its eye
	box(-0.04, 0.44, -0.04, 0.08, 0.1, 0.08, 0x3a3c40)
	_xf = keep
	aerials += 1

## a handrail of tube from a to b (spots of the roof: x, z), a post every couple of metres, following the sheets
func _rail(a: Vector2, b: Vector2, steel: int) -> void:
	var n := maxi(1, int(round(a.distance_to(b) / 2.3)))
	for i in range(n + 1):
		var q := a.lerp(b, float(i) / n)
		var foot := Vector3(q.x, roof_y(q.y) - 0.02, q.y)
		bar(foot, foot + Vector3(0, 1.02, 0), 0.04, 0.04, steel)
		if i == n:
			break
		var q2 := a.lerp(b, float(i + 1) / n)
		var foot2 := Vector3(q2.x, roof_y(q2.y) - 0.02, q2.y)
		for ry: float in [0.52, 1.0]:
			bar(foot + Vector3(0, ry, 0), foot2 + Vector3(0, ry, 0), 0.035, 0.035, steel)

## a white plastic chair, its foot's middle at `at`, turned `yaw` (its back away from +z)
func _chair(at: Vector3, yaw: float) -> void:
	var keep := _xf
	_xf = keep * Transform3D(Basis(Vector3.UP, yaw), at)
	for q in [Vector2(-0.2, -0.2), Vector2(0.2, -0.2), Vector2(0.2, 0.2), Vector2(-0.2, 0.2)]:
		var v: Vector2 = q
		box(v.x - 0.02, 0.0, v.y - 0.02, 0.04, 0.42, 0.04, 0xeeeee8)
	box(-0.24, 0.42, -0.24, 0.48, 0.035, 0.48, 0xeeeee8)
	tbox(Transform3D(Basis(Vector3.RIGHT, -0.16).scaled_local(Vector3(0.48, 0.42, 0.03)), Vector3(0.0, 0.68, -0.25)), 0xeeeee8)
	for sx: float in [-1.0, 1.0]:
		box(sx * 0.24 - 0.02, 0.42, -0.22, 0.04, 0.2, 0.04, 0xeeeee8)
		box(sx * 0.24 - 0.025, 0.61, -0.24, 0.05, 0.03, 0.42, 0xeeeee8)
	_xf = keep

## a lamp of the roof: lit at night, only on the restored hall (no shadows)
func _roof_lamp(at: Vector3, c: Color, reach: float, how: float) -> void:
	var lamp := OmniLight3D.new()
	lamp.light_color = c
	lamp.omni_range = reach
	lamp.light_energy = how
	lamp.shadow_enabled = false
	lamp.position = _xf * at                       # (the state's node keeps the place's own frame)
	_into.add_child(lamp)
	_roof_lamps.append(lamp)

## the stair hut: rendered walls, a slab over them, its metal door in its south side
func _hut(fine: bool) -> void:
	_front()
	var wk = "crema" if fine else "crema_vieja"
	var x0 := HUT.position.x
	var x1 := HUT.end.x
	var z0 := HUT.position.y
	var z1 := HUT.end.y
	var zc := HUT_DOOR_Z
	var sill := roof_y(zc + 0.53) + 0.02                                       # (level with the sheets at its upper jamb)
	_ring_walls([Vector2(x0, z1), Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1)], roof_y(z0) - 0.2, HUT_TOP, wk)
	box(x0 - 0.15, HUT_TOP, z0 - 0.15, x1 - x0 + 0.75, 0.1, z1 - z0 + 0.3, 0x8d8d8a if fine else 0x77736a)      # its slab, over the door too
	var green: int = 0x55685c if fine else (_fade(0x55685c, 0.5).to_rgba32() >> 8)
	box(x1, sill - 0.02, zc - 0.53, 0.03, 2.12, 1.06, 0x1c1c1f)                # the door's frame, its leaf, its handle
	box(x1 + 0.02, sill, zc - 0.45, 0.035, 2.02, 0.9, green)
	box(x1 + 0.055, sill + 1.25, zc - 0.31, 0.008, 0.5, 0.62, 0x3f4f45 if fine else 0x6b7269)
	box(x1 + 0.055, sill + 0.95, zc + 0.3, 0.05, 0.16, 0.05, 0x8d9196)
	var step_y := roof_y(zc - 0.7) - 0.05
	box(x1, step_y, zc - 0.7, 0.6, sill - 0.03 - step_y, 1.4, 0x8d8d8a if fine else 0x77736a)      # its step, level on the slope
	if fine:
		box(x1 + 0.02, sill + 2.2, zc - 0.12, 0.1, 0.1, 0.24, 0x3a3c40)        # the lamp over it
		box(x1 + 0.03, sill + 2.17, zc - 0.1, 0.08, 0.03, 0.2, "luz_ffe9b0")
		_roof_lamp(Vector3(x1 + 0.6, sill + 2.0, zc), Color(1.0, 0.86, 0.62), 7.5, 1.3)
	else:
		for j in range(2):                                                     # two planks nailed across it
			var py: float = sill + 0.7 + 0.75 * j
			var tilt: float = (_roll(61 + j, 31) - 0.5) * 0.25
			bar(Vector3(x1 + 0.09, py - tilt, zc - 0.62), Vector3(x1 + 0.09, py + tilt, zc + 0.62), 0.03, 0.19, "tablon")
			boards += 1
		for j in range(4):                                                     # damp running down its walls
			box(x0 + 0.3 + j * 0.7, HUT_TOP - 0.5 - 0.5 * _roll(j, 63), z1 + 0.004, 0.1 + 0.2 * _roll(j, 64), 0.5 + 0.5 * _roll(j, 63), 0.004, 0x6f6a5c)
	# on its slab: the aerial and the dish
	_aerial(Vector3(x1 - 0.5, HUT_TOP + 0.1, z0 + 0.6), 3.3, -PI / 2.0, fine, 1)      # (looking over the road)
	_dish(Vector3(x0 + 0.6, HUT_TOP + 0.62, z0 + 0.5), PI / 2.0, fine)
	if fine:                                                                   # the mast's stays
		for q in [Vector3(x1 - 0.1, HUT_TOP + 0.1, z0 + 0.1), Vector3(x1 - 0.1, HUT_TOP + 0.1, z1 - 0.1), Vector3(x0 + 1.2, HUT_TOP + 0.1, z0 + 0.3)]:
			var v: Vector3 = q
			bar(Vector3(x1 - 0.5, HUT_TOP + 2.2, z0 + 0.6), v, 0.01, 0.01, 0x9a9ea2)

## what stands on the roof, in one state or the other
func _roof_top(fine: bool) -> void:
	_front()
	acs = 0
	aerials = 0
	var steel: int = 0x8d9196 if fine else 0x7a5a40
	_hut(fine)
	_front()
	# the air conditioners, in a row on their bench behind the front's parapet, their fans to the road
	var bz := -3.25
	var top := _bench(6.5, 13.6, bz - 0.3, bz + 0.3, steel)
	for i in range(AC_ROW.size()):
		var ax: float = AC_ROW[i][0]
		var fans: int = AC_ROW[i][1]
		if not fine and i == 3:                                                # (one has come off the bench and lies on the sheets)
			_ac(Transform3D(Basis(Vector3.UP, 0.4) * Basis(Vector3.RIGHT, -PI / 2.0), Vector3(ax + 0.2, roof_y(bz + 1.3) + 0.25, bz + 1.3)), fans, fine, i)
		else:
			_ac(Transform3D(Basis.IDENTITY, Vector3(ax, top, bz)), fans, fine, i)
			var py := top + (0.5 if fans == 1 else 0.9)                         # its pipes: out of its side, down, along the sheets to where they go in
			bar(Vector3(ax + 0.49, py, bz - 0.1), Vector3(ax + 0.62, py, bz - 0.1), 0.045, 0.045, 0xe8e8e2 if fine else 0xa8a294)
			bar(Vector3(ax + 0.62, py, bz - 0.1), Vector3(ax + 0.62, roof_y(bz - 0.5) + 0.04, bz - 0.5), 0.045, 0.045, 0xe8e8e2 if fine else 0xa8a294)
			bar(Vector3(ax + 0.62, roof_y(bz - 0.5) + 0.04, bz - 0.5), Vector3(ax + 0.62, roof_y(bz - 1.9) + 0.04, bz - 1.9), 0.045, 0.045, 0xe8e8e2 if fine else 0xa8a294)
			box(ax + 0.52, roof_y(bz - 1.9), bz - 2.05, 0.2, 0.1, 0.2, 0x3a3c40)
	# the big one on the back slope, with its hood and its duct going up the sheets and in
	var u0 := 26.5
	var utop := _bench(u0, u0 + 2.6, -17.2, -15.9, steel)
	var grey: int = 0xcfd2d0 if fine else 0x9f9684
	box(u0, utop, -17.2, 2.6, 1.3, 1.3, grey)
	box(u0 - 0.02, utop + 1.3, -17.22, 2.64, 0.06, 1.34, 0xb9bcba if fine else 0x857a66)
	for j in range(9):                                                         # the louvres of its long side
		box(u0 + 0.15, utop + 0.2 + j * 0.1, -15.9, 1.4, 0.03, 0.012, 0x6a6e72 if fine else 0x6f5a48)
	box(u0 + 1.75, utop + 0.25, -15.9, 0.7, 0.8, 0.012, 0xb9bcba if fine else 0x857a66)      # its hatch
	box(u0 + 2.25, utop + 0.6, -15.89, 0.05, 0.12, 0.03, 0x3a3c40)
	drum(Vector3(u0 + 0.7, utop + 1.36, -16.55), 0.42, 0.42, 0.05, 0x3a3c40, 16)      # the fan in its lid, lying flat
	drum(Vector3(u0 + 0.7, utop + 1.41, -16.55), 0.36, 0.36, 0.006, 0x1c1c20, 16)
	bar(Vector3(u0 + 0.7, utop + 1.425, -16.91), Vector3(u0 + 0.7, utop + 1.425, -16.19), 0.014, 0.014, 0x8a8e92)
	bar(Vector3(u0 + 0.34, utop + 1.425, -16.55), Vector3(u0 + 1.06, utop + 1.425, -16.55), 0.014, 0.014, 0x8a8e92)
	var duct: int = 0xb4b8bc if fine else 0x8a8478
	var d0 := Vector3(u0 + 1.3, utop + 0.75, -15.9)                            # the duct: out of its side, up the slope on two rests, down into the roof
	var d1 := Vector3(u0 + 1.3, roof_y(-13.9) + 0.5, -13.9)
	bar(d0, d1, 0.62, 0.42, duct)
	box(u0 + 0.99, roof_y(-13.6) - 0.05, -13.95, 0.62, 0.8, 0.45, duct)
	for dz: float in [-15.2, -14.4]:
		box(u0 + 0.95, roof_y(dz), dz - 0.03, 0.7, lerpf(d0.y, d1.y, (dz + 15.9) / 2.0) - 0.22 - roof_y(dz), 0.06, steel)
	acs += 1
	# the spinning vents along the ridge
	for i in range(TURBINES.size()):
		_turbine(float(TURBINES[i]), fine, i)
	# the water tank at the south end of the back slope, on its bench
	var ttop := _bench(35.4, 36.6, -20.1, -18.9, steel)
	drum(Vector3(36.0, ttop, -19.5), 0.58, 0.58, 1.2, 0xb9b9b2 if fine else 0x9a958a, 14)
	drum(Vector3(36.0, ttop + 1.2, -19.5), 0.61, 0.5, 0.1, 0xa9a9a2 if fine else 0x8a857a, 14)
	bar(Vector3(36.58, ttop + 0.2, -19.5), Vector3(36.58, roof_y(-19.5), -19.5), 0.04, 0.04, 0x5d6166)
	# the skylights: sheets of pale plastic among the steel ones, on both slopes
	var k := 0
	for sx: float in [16.0, 24.0, 32.0, 38.0]:
		for zc: float in [-7.4, -17.9]:
			k += 1
			var lean := -atan((H_RIDGE - H_EAVES) / (-0.3 - RIDGE_Z)) if zc > RIDGE_Z else atan((H_RIDGE - H_EAVES) / (RIDGE_Z - BACK + 0.25))
			var broken: bool = not fine and k == 3
			tbox(Transform3D(Basis(Vector3.RIGHT, lean).scaled_local(Vector3(1.05, 0.02, 3.0)), Vector3(sx, roof_y(zc) + 0.022, zc)), 0x2a2c30 if broken else (0xd3dbd6 if fine else 0xa3a996))
			for e: float in [-0.53, 0.53]:
				tbox(Transform3D(Basis(Vector3.RIGHT, lean).scaled_local(Vector3(0.04, 0.035, 3.04)), Vector3(sx + e, roof_y(zc) + 0.03, zc)), steel)
	# a second aerial at the south end, by the bar
	_aerial(Vector3(39.5, roof_y(-4.5) - 0.02, -4.5), 3.0, -PI / 2.0 + 0.3, fine, 2)
	for q in [Vector3(39.5, 0, -3.6), Vector3(38.7, 0, -5.0), Vector3(40.3, 0, -5.0)]:      # its three legs
		var v: Vector3 = q
		bar(Vector3(v.x, roof_y(v.z), v.z), Vector3(39.5, roof_y(-4.5) + 0.9, -4.5), 0.02, 0.02, steel)
	if not fine:
		return
	# restored: a handrail round the sides and the back (the front has its parapet), the staff's corner by the
	# parapet -- two chairs and a crate looking at the town --, a lamp on a pole there
	var in_ := 0.12
	for ex: float in [X0 + in_, XS - in_]:
		_rail(Vector2(ex, -0.35), Vector2(ex, RIDGE_Z), 0x9a9ea2)
		_rail(Vector2(ex, RIDGE_Z), Vector2(ex, BACK + in_), 0x9a9ea2)
	_rail(Vector2(X0 + in_, BACK + in_), Vector2(XS - in_, BACK + in_), 0x9a9ea2)
	var cy := roof_y(-1.5)
	_chair(Vector3(19.5, cy, -1.5), 0.2)
	_chair(Vector3(20.9, cy, -1.5), -0.25)
	tbox(Transform3D(Basis(Vector3.UP, 0.3).scaled_local(Vector3(0.4, 0.27, 0.3)), Vector3(20.2, cy + 0.14, -1.35)), 0xc23b32)      # a crate turned over: their table
	drum(Vector3(20.15, cy + 0.275, -1.38), 0.05, 0.06, 0.03, 0x8a8e92, 8)                 # the ashtray
	drum(Vector3(20.3, cy + 0.275, -1.3), 0.03, 0.03, 0.16, 0x3a7a3a, 6)
	drum(Vector3(20.3, cy + 0.435, -1.3), 0.03, 0.012, 0.06, 0x3a7a3a, 6)
	bar(Vector3(18.6, roof_y(-1.0), -1.0), Vector3(18.6, roof_y(-1.0) + 2.3, -1.0), 0.04, 0.04, 0x5d6166)
	bar(Vector3(18.6, roof_y(-1.0) + 2.3, -1.0), Vector3(19.1, roof_y(-1.0) + 2.3, -1.2), 0.03, 0.03, 0x5d6166)
	box(19.02, roof_y(-1.0) + 2.16, -1.28, 0.16, 0.12, 0.16, "luz_ffe9b0")
	_roof_lamp(Vector3(19.1, roof_y(-1.0) + 2.1, -1.2), Color(1.0, 0.86, 0.62), 7.0, 1.1)

# ---------------- north of the front: the gate of the side passage and the neighbour's fence ----------------
func _north(fine: bool) -> void:
	_front()
	var gk = "gris" if fine else "gris_viejo"
	var blue: int = 0x2f55a8 if fine else (_fade(0x2f55a8, 0.5).to_rgba32() >> 8)
	_rect(0.0, 2.3, DOWN, 2.4, 0.0, gk)                                # the grey wall with the gate in it
	_rect(3.6, X0, DOWN, 2.4, 0.0, gk)
	_rect(2.3, 3.6, 2.1, 2.4, 0.0, gk)
	box(0.0, 2.4, -0.2, X0, 0.05, 0.22, 0x8d8d8a)
	var gy := g(2.95, 0.3)
	_rect(2.3, 3.6, DOWN, gy, 0.0, gk)
	box(2.3, gy, -0.06, 1.3, 2.1 - gy, 0.05, blue)                     # the gate, of blue sheet
	box(2.36, gy + 0.9, -0.01, 1.18, 0.05, 0.02, 0x1d2f5c)
	box(3.42, gy + 0.95, -0.01, 0.05, 0.16, 0.05, 0x8d9196)
	# the fence of precast panels beyond it
	var px := 0.0
	var k := 0
	while px > -12.9:
		var p0 := px - 2.15
		var fy := g((px + p0) / 2.0, 0.3)
		var down_it: bool = not fine and k == 3                         # (one panel has come out and lies broken)
		box(px - 0.09, DOWN, -0.2, 0.18, fy + 2.3 - DOWN, 0.2, 0xa9a9a4)
		if down_it:
			tbox(Transform3D(Basis(Vector3.RIGHT, 1.35).scaled_local(Vector3(1.9, 1.0, 0.07)), Vector3((px + p0) / 2.0, fy + 0.25, 0.55)), "panel")
			box(p0 + 0.09, DOWN, -0.13, 1.97, fy + 0.55 - DOWN, 0.07, "panel")
		else:
			box(p0 + 0.09, DOWN, -0.13, 1.97, fy + 2.15 - DOWN, 0.07, "panel")
			if not fine and k % 2 == 0:
				_pic((px + p0) / 2.0 - 0.85, (px + p0) / 2.0 + 0.85, fy + 0.5, fy + 1.9, -0.05, "tag_%s" % TAGS[(k / 2 + 1) % TAGS.size()])
		px = p0
		k += 1
	box(px - 0.09, DOWN, -0.2, 0.18, g(px, 0.3) + 2.3 - DOWN, 0.2, 0xa9a9a4)
	if not fine:
		_pic(0.2, 2.1, 0.75, 2.05, 0.012, "tag_%s" % TAGS[0])
		_planks(2.25, 3.65, [gy + 1.2], 0.03, 21)
	# the back of the passage: the plot's wall on its north side, as far as the sheds
	var north := _north_ring()
	for i in range(north.size() - 1):
		_fence(north[i], north[i + 1], 2.4, gk)

# ---------------- the bar at the corner ----------------
func _bar(fine: bool) -> void:
	_front()
	var ck = "crema" if fine else "crema_vieja"
	var wk = "negro" if fine else "viejo"
	var blue: int = 0x2f55a8 if fine else (_fade(0x2f55a8, 0.5).to_rgba32() >> 8)
	wall(Vector2(X1, 0.0), Vector2(X1, BAR_Z))                         # its side on the hall's doors: dark, like the hall
	_rect(0.0, BAR_Z, DOWN, BAR_H, 0.0, wk)
	wall(Vector2(BAR_X, BAR_Z), Vector2(BAR_X, 0.0))
	_rect(0.0, BAR_Z, DOWN, BAR_H, 0.0, ck)
	_front()
	_rect(X1, BAR_X, DOWN, BAR_H, BAR_Z, ck)
	pieces += 1
	quad(Vector3(X1, BAR_H, 0.0), Vector3(BAR_X, BAR_H, 0.0), Vector3(BAR_X, BAR_H, BAR_Z), Vector3(X1, BAR_H, BAR_Z), "gris", Vector3.UP)
	box(X1 - 0.03, BAR_H, BAR_Z - 0.05, BAR_X - X1 + 0.06, 0.08, 0.1, 0xb9b3a0)
	box(X1, DOWN, BAR_Z, BAR_X - X1, 0.6 - DOWN, 0.03, 0x8f8a7c if fine else 0x77736a)      # the foot of its front
	# its door, blue
	var d0 := 39.7
	var d1 := 41.1
	var gy := g(40.4, BAR_Z + 0.4)
	box(d0 - 0.08, DOWN, BAR_Z, d1 - d0 + 0.16, 2.3 - DOWN, 0.04, 0xe9e4d6 if fine else 0xa9a493)
	box(d0, gy + 0.02, BAR_Z + 0.03, d1 - d0, 2.2 - gy, 0.04, blue)
	box(d0 + 0.1, 1.2, BAR_Z + 0.07, d1 - d0 - 0.2, 0.75, 0.01, 0x1d2f5c if fine else 0x56627e)
	box(d1 - 0.2, 0.95, BAR_Z + 0.07, 0.05, 0.16, 0.05, 0x8d9196)
	box(41.5, 1.25, BAR_Z + 0.01, 1.3, 0.95, 0.03, "cristal")           # the window beside it
	for q in [[41.45, 1.2, 1.4, 0.06], [41.45, 2.18, 1.4, 0.06], [41.45, 1.2, 0.06, 1.04], [42.79, 1.2, 0.06, 1.04]]:
		box(q[0], q[1], BAR_Z + 0.01, q[2], q[3], 0.06, 0xe9e4d6 if fine else 0xa9a493)
	# the round canopy over the door, on its post
	var sheet = "chapa" if fine else "chapa_vieja"
	var c0 := 38.9
	var c1 := 42.9
	var cz := 7.55
	var n := 8
	for i in range(n):
		var a0 := PI * i / n
		var a1 := PI * (i + 1) / n
		var p0 := Vector3(lerpf(c0, c1, 0.5 - cos(a0) / 2.0), 2.6 + sin(a0) * 0.72, 0)
		var p1 := Vector3(lerpf(c0, c1, 0.5 - cos(a1) / 2.0), 2.6 + sin(a1) * 0.72, 0)
		bar(p0 + Vector3(0, 0, cz), p1 + Vector3(0, 0, cz), 0.05, 0.05, 0x5d6166)
		bar(p0 + Vector3(0, 0, BAR_Z + 0.04), p1 + Vector3(0, 0, BAR_Z + 0.04), 0.05, 0.05, 0x5d6166)
		if not fine and (i == 2 or i == 5 or i == 6):                   # (sheets of it gone)
			continue
		pieces += 1
		var nn := Vector3(-cos((a0 + a1) / 2.0), sin((a0 + a1) / 2.0), 0)
		quad(p0 + Vector3(0, 0, BAR_Z + 0.04), p1 + Vector3(0, 0, BAR_Z + 0.04), p1 + Vector3(0, 0, cz), p0 + Vector3(0, 0, cz), sheet, nn)
	bar(Vector3(c0, 2.6, BAR_Z), Vector3(c0, 2.6, cz), 0.06, 0.06, 0x5d6166)
	bar(Vector3(c1, 2.6, BAR_Z), Vector3(c1, 2.6, cz), 0.06, 0.06, 0x5d6166)
	var py := g(39.0, 7.46)
	drum(Vector3(39.01, py, 7.46), 0.05, 0.05, 2.6 - py, 0x5d6166, 8)
	# its board on the roof, turned towards the road
	var keep := _xf
	if fine:
		_xf = _xf * Transform3D(Basis(Vector3.UP, 0.35), Vector3(40.9, BAR_H + 0.08, 4.3))
		box(-1.7, 0.0, 0.0, 3.4, 0.95, 0.06, 0xf1efe8)
		bar(Vector3(-1.4, 0.0, 0.0), Vector3(-1.4, 0.8, -0.9), 0.04, 0.04, 0x5d6166)
		bar(Vector3(1.4, 0.0, 0.0), Vector3(1.4, 0.8, -0.9), 0.04, 0.04, 0x5d6166)
		_word("BAR RESTAURANTE", Vector3(0.0, 0.5, 0.07), 72, 0x2f55a8, 0.0042, false, 8)
	else:                                                              # (fallen on its face, half over the edge)
		_xf = _xf * Transform3D(Basis(Vector3.UP, 0.5) * Basis(Vector3.RIGHT, -1.25), Vector3(40.7, BAR_H + 0.12, 4.75))
		box(-1.7, 0.0, 0.0, 3.4, 0.95, 0.06, 0xb9b6ac)
		_word("BAR RE TAUR NTE", Vector3(0.0, 0.5, 0.07), 72, 0x7483a3, 0.0042, false, 8)
	_xf = keep
	if not fine:
		_planks(d0 - 0.15, d1 + 0.15, [gy + 0.7, gy + 1.5], BAR_Z + 0.1, 5)
		_planks(41.4, 42.9, [1.5, 1.95], BAR_Z + 0.09, 7)

# ---------------- the summer terrace: white walls with their sails and pillars ----------------
func _terrace(fine: bool) -> void:
	_front()
	var wk = "white" if fine else "blanco_viejo"
	var base = "gris" if fine else "gris_viejo"
	var blue: int = 0x2f55a8 if fine else (_fade(0x2f55a8, 0.5).to_rgba32() >> 8)
	var ring := [Vector2(BAR_X, WALL_Z), Vector2(TER_S, WALL_Z), Vector2(TER_S, TER_E), Vector2(XS, TER_E)]
	for i in range(3):                                                 # its three walls: white over a grey foot where the ground falls away
		var a: Vector2 = ring[i]
		var b: Vector2 = ring[i + 1]
		var ln := wall(a, b)
		var foot := minf(gr(P(a.x, a.y)), gr(P(b.x, b.y)))
		var split := DECK - 0.25 if foot < DECK - 1.6 else DOWN
		if split > DOWN:
			_rect(0.0, ln, DOWN, split, 0.0, base)
			box(0.0, split - 0.06, 0.0, ln, 0.06, 0.04, 0x9a9892)
		_rect(0.0, ln, split, WT, 0.0, wk)
		_rect(0.0, ln, DECK, WT, -0.3, wk)                              # (what you would see of it from inside)
		pieces += 1
		quad(Vector3(0, WT, -0.3), Vector3(ln, WT, -0.3), Vector3(ln, WT, 0), Vector3(0, WT, 0), wk, Vector3.UP)
	_front()
	flat(PackedVector2Array([Vector2(XS, TER_E), Vector2(TER_S, TER_E), Vector2(TER_S, WALL_Z), Vector2(BAR_X, WALL_Z), Vector2(BAR_X, 0.0), Vector2(XS, 0.0)]), DECK, "solado")
	_rect(BAR_X, TER_S, DECK, WT, WALL_Z - 0.3, wk)
	flat(PackedVector2Array([Vector2(48.0, -13.0), Vector2(TER_S - 0.4, -13.0), Vector2(TER_S - 0.4, -1.0), Vector2(48.0, -1.0)]), DECK + 0.012, 0x8f8c86 if fine else 0x7b7872)      # the dance floor
	# the sails and pillars standing on the wall of the road side
	var z0 := WALL_Z - 0.3
	_plate(PackedVector2Array([Vector2(44.1, WT), Vector2(47.4, WT), Vector2(47.4, 6.6)]), z0, WALL_Z, wk)
	box(47.4, WT, z0, 0.55, 3.3, 0.3, wk)
	var hole := Vector2(51.95, 5.25)                                   # the sail with the round window, in two pieces round it
	var left := PackedVector2Array([Vector2(50.8, WT), Vector2(hole.x, WT)])
	var right := PackedVector2Array([Vector2(hole.x, WT), Vector2(54.3, WT), Vector2(hole.x, 6.34)])
	for i in range(9):
		var a := -PI / 2.0 - PI * i / 8.0
		left.append(hole + Vector2(cos(a), sin(a)) * 0.46)
	left.append(Vector2(hole.x, 6.34))
	left.append(Vector2(51.3, 6.8))
	left.append(Vector2(50.8, 6.8))
	for i in range(9):
		var a := PI / 2.0 - PI * i / 8.0
		right.append(hole + Vector2(cos(a), sin(a)) * 0.46)
	_plate(left, z0, WALL_Z, wk)
	_plate(right, z0, WALL_Z, wk)
	box(54.6, WT, z0, 0.5, 4.0, 0.3, wk)                                # the tall pillar
	box(58.6, WT, z0 - 0.3, 0.9, 3.8 if fine else 3.1, 0.6, wk)         # ...and the thick one by the cabin
	if not fine:                                                       # (its top broken off: the bricks show)
		box(58.62, WT + 3.1, z0 - 0.28, 0.86, 0.14, 0.56, "brick")
		cbox(Vector3(58.3, g(58.3, 1.6) + 0.12, 1.6), Vector3(0.6, 0.24, 0.45), wk)
		cbox(Vector3(59.2, g(59.2, 1.9) + 0.1, 1.9), Vector3(0.4, 0.2, 0.35), "brick")
	# the cabin over the south end, with its long window
	var c0 := TER_S - 4.7
	box(c0, 4.9, z0 - 2.5, TER_S - c0, 1.7, 2.8, wk)
	box(c0 - 0.1, 6.6, z0 - 2.6, TER_S - c0 + 0.2, 0.1, 3.0, 0xc9c6bd if fine else 0x8f8c84)
	box(c0 + 0.4, 5.5, WALL_Z, TER_S - c0 - 0.8, 0.72, 0.02, "cristal")
	if not fine:
		_planks(c0 + 0.35, c0 + 2.2, [5.7, 6.05], WALL_Z + 0.04, 13)
	box(c0 + 0.8, DECK, z0 - 0.5, 0.3, 4.0, 0.3, wk)
	_plate(PackedVector2Array([Vector2(TER_S - 2.4, 6.7), Vector2(TER_S, 6.7), Vector2(TER_S, 7.9)]), z0, WALL_Z, wk)
	# two more on the far side, and one on the south wall
	var ln2 := wall(Vector2(TER_S, TER_E), Vector2(XS, TER_E))
	_plate(PackedVector2Array([Vector2(3.0, WT), Vector2(7.0, WT), Vector2(3.0, 6.7)]), -0.3, 0.0, wk)
	box(2.5, WT, -0.3, 0.5, 3.6, 0.3, wk)
	_plate(PackedVector2Array([Vector2(10.5, WT), Vector2(14.5, WT), Vector2(14.5, 6.2)]), -0.3, 0.0, wk)
	wall(Vector2(TER_S, WALL_Z), Vector2(TER_S, TER_E))
	_plate(PackedVector2Array([Vector2(9.0, WT), Vector2(13.5, WT), Vector2(9.0, 6.4)]), -0.3, 0.0, wk)
	box(8.45, WT, -0.3, 0.55, 3.4, 0.3, wk)
	_front()
	# the gate of the store under it, on the road side
	var gy := g(59.4, WALL_Z + 0.3)
	if gy < DECK - 2.0:
		box(58.1, gy, WALL_Z, 2.6, 2.05, 0.05, blue)
		box(59.38, gy, WALL_Z + 0.05, 0.04, 2.05, 0.02, 0x1d2f5c)
		for j in range(4):
			box(58.1, gy + 0.2 + j * 0.55, WALL_Z + 0.05, 2.6, 0.03, 0.015, 0x1d2f5c)
		if not fine:
			_planks(58.0, 60.8, [gy + 0.6, gy + 1.4], WALL_Z + 0.09, 17)
	# what stands on its floor: the awning over the dance floor, the string of bulbs on its poles
	var poles: Array = [Vector2(45.0, -1.2), Vector2(53.5, -1.2), Vector2(TER_S - 1.7, -1.6), Vector2(TER_S - 1.7, -13.0), Vector2(TER_S - 1.7, -24.5), Vector2(53.0, -24.8), Vector2(44.0, -24.8), Vector2(43.0, -12.5)]
	var steel: int = 0x8d9196 if fine else 0x6a6259
	for i in range(poles.size()):
		var q: Vector2 = poles[i]
		var lean := Vector3.ZERO if fine or i % 3 != 1 else Vector3(0.9, -0.3, 0.6)
		bar(Vector3(q.x, DECK, q.y), Vector3(q.x, DECK + 5.6, q.y) + lean, 0.07, 0.07, steel)
		var r: Vector2 = poles[(i + 1) % poles.size()]
		var top_a := Vector3(q.x, DECK + 5.5, q.y) + lean
		var top_b := Vector3(r.x, DECK + 5.5, r.y) + (Vector3.ZERO if fine or (i + 1) % 3 != 1 else Vector3(0.9, -0.3, 0.6))
		if not fine and i % 3 == 0:                                    # (a string down, trailing on the floor)
			bar(top_a, Vector3(lerpf(q.x, r.x, 0.5), DECK + 0.05, lerpf(q.y, r.y, 0.5)), 0.015, 0.015, 0x202022)
			continue
		var steps := 8
		for s in range(steps):
			var f0 := float(s) / steps
			var f1 := float(s + 1) / steps
			var sag0 := 4.0 * f0 * (1.0 - f0) * 0.7
			var sag1 := 4.0 * f1 * (1.0 - f1) * 0.7
			var a := top_a.lerp(top_b, f0) - Vector3(0, sag0, 0)
			var b := top_a.lerp(top_b, f1) - Vector3(0, sag1, 0)
			bar(a, b, 0.015, 0.015, 0x202022)
			if fine:
				cbox(b - Vector3(0, 0.07, 0), Vector3(0.09, 0.11, 0.09), "luz_%06x" % SLATS[(i * steps + s) % SLATS.size()])
	var aw := Vector2(56.4, -9.0)                                      # the awning: four posts and its canvas
	for sx in [-3.2, 3.2]:
		for sz in [-3.2, 3.2]:
			bar(Vector3(aw.x + sx, DECK, aw.y + sz), Vector3(aw.x + sx, DECK + 2.9, aw.y + sz), 0.08, 0.08, steel)
	for sx in [-3.2, 3.2]:
		bar(Vector3(aw.x + sx, DECK + 2.9, aw.y - 3.2), Vector3(aw.x + sx, DECK + 2.9, aw.y + 3.2), 0.06, 0.06, steel)
		bar(Vector3(aw.x - 3.2, DECK + 2.9, aw.y + sx), Vector3(aw.x + 3.2, DECK + 2.9, aw.y + sx), 0.06, 0.06, steel)
	var top := Vector3(aw.x, DECK + 3.7, aw.y)
	var cs: Array = [Vector3(aw.x - 3.3, DECK + 2.95, aw.y - 3.3), Vector3(aw.x + 3.3, DECK + 2.95, aw.y - 3.3), Vector3(aw.x + 3.3, DECK + 2.95, aw.y + 3.3), Vector3(aw.x - 3.3, DECK + 2.95, aw.y + 3.3)]
	for i in range(4):
		if not fine and i != 2:                                        # (only a rag of it left)
			bar(cs[i], top, 0.04, 0.04, steel)
			continue
		pieces += 1
		var c0v: Vector3 = cs[i]
		var c1v: Vector3 = cs[(i + 1) % 4]
		var nn: Vector3 = (c1v - c0v).cross(top - c0v).normalized()
		if nn.y < 0.0:
			nn = -nn
		tri(c0v, c1v, top, 0xf3f1ea if fine else 0xb5b0a2, nn)
		tri(c0v, c1v, top, 0xf3f1ea if fine else 0xb5b0a2, -nn)
	box(44.5, DECK, -22.5, 7.0, 1.1, 0.7, wk)                          # the bar of the terrace, against its far wall
	box(44.4, DECK + 1.1, -22.6, 7.2, 0.06, 0.9, 0x5a4636 if fine else 0x6f675c)

# ---------------- the car shelter before the terrace, and the ramp up to it ----------------
func _shelter(fine: bool) -> void:
	_front()
	var green: int = 0x47684c if fine else (_fade(0x47684c, 0.55).to_rgba32() >> 8)
	var y_wall := 3.4
	var y_eave := 2.3
	var z_in := WALL_Z + 0.05
	var xs: Array = []
	for i in range(POSTS):
		xs.append(43.9 + i * 4.0)
	for i in range(POSTS):
		var x: float = xs[i]
		var gy := g(x, SHELTER_Z - 0.2)
		var broken: bool = not fine and i == POSTS - 1                         # (the last post has given way: that corner sags)
		var sag := 0.75 if broken else 0.0
		if broken:
			bar(Vector3(x, gy, SHELTER_Z - 0.2), Vector3(x + 0.5, gy + 1.5, SHELTER_Z - 0.5), 0.12, 0.12, green)
		else:
			box(x - 0.06, DOWN, SHELTER_Z - 0.26, 0.12, y_eave - DOWN, 0.12, green)
		bar(Vector3(x, y_wall - 0.06, z_in), Vector3(x, y_eave - 0.06 - sag, SHELTER_Z), 0.08, 0.14, "wood")      # the rafter
		if i < POSTS - 1:
			var x2: float = xs[i + 1]
			var sag2 := 0.75 if (not fine and i + 1 == POSTS - 1) else 0.0
			bar(Vector3(x, y_eave - 0.1 - sag, SHELTER_Z - 0.2), Vector3(x2, y_eave - 0.1 - sag2, SHELTER_Z - 0.2), 0.1, 0.14, "wood")
			# its roof over this bay: three strips from the wall down to the eaves
			for s in range(3):
				if not fine and _roll(i * 3 + s, 41) > 0.62:           # (tiles gone: the battens show)
					for bt in range(3):
						var fz := (s + (bt + 0.5) / 3.0) / 3.0
						bar(Vector3(x, lerpf(y_wall, y_eave - sag, fz), lerpf(z_in, SHELTER_Z, fz)), Vector3(x2, lerpf(y_wall, y_eave - sag2, fz), lerpf(z_in, SHELTER_Z, fz)), 0.05, 0.04, "wood")
					continue
				var f0 := s / 3.0
				var f1 := (s + 1) / 3.0
				roof([Vector3(x, lerpf(y_wall, y_eave - sag, f1), lerpf(z_in, SHELTER_Z + 0.25, f1)), Vector3(x2, lerpf(y_wall, y_eave - sag2, f1), lerpf(z_in, SHELTER_Z + 0.25, f1)),
					Vector3(x2, lerpf(y_wall, y_eave - sag2, f0), lerpf(z_in, SHELTER_Z + 0.25, f0)), Vector3(x, lerpf(y_wall, y_eave - sag, f0), lerpf(z_in, SHELTER_Z + 0.25, f0))], "tiles")
	# the gable at its south end, with its timber tie
	var xe: float = xs[POSTS - 1]
	bar(Vector3(xe, y_eave - 0.1 - (0.0 if fine else 0.75), SHELTER_Z - 0.2), Vector3(xe, y_eave - 0.1, z_in), 0.08, 0.12, "wood")

func _ramp(fine: bool) -> void:
	_front()
	var wk = "white" if fine else "blanco_viejo"
	var blue: int = 0x2f55a8 if fine else (_fade(0x2f55a8, 0.5).to_rgba32() >> 8)
	var x0 := 43.6
	var x1 := 53.0
	var x2 := 55.2
	var z1 := 2.35
	var y0 := g(x0, 1.5)
	pieces += 4
	quad(Vector3(x0, y0, WALL_Z), Vector3(x0, y0, z1), Vector3(x1, DECK, z1), Vector3(x1, DECK, WALL_Z), "solado", Vector3.UP)
	quad(Vector3(x1, DECK, WALL_Z), Vector3(x1, DECK, z1), Vector3(x2, DECK, z1), Vector3(x2, DECK, WALL_Z), "solado", Vector3.UP)
	quad(Vector3(x0, DOWN, z1), Vector3(x1, DOWN, z1), Vector3(x1, DECK, z1), Vector3(x0, y0, z1), wk, Vector3(0, 0, 1))
	quad(Vector3(x1, DOWN, z1), Vector3(x2, DOWN, z1), Vector3(x2, DECK, z1), Vector3(x1, DECK, z1), wk, Vector3(0, 0, 1))
	quad(Vector3(x2, DOWN, WALL_Z), Vector3(x2, DOWN, z1), Vector3(x2, DECK, z1), Vector3(x2, DECK, WALL_Z), wk, Vector3(1, 0, 0))
	# its railing, blue
	var n := 9
	for i in range(n + 1):
		var x := lerpf(x0, x2, float(i) / n)
		var y := lerpf(y0, DECK, clampf((x - x0) / (x1 - x0), 0.0, 1.0))
		if not fine and (i == 3 or i == 4):                            # (a stretch of it torn out)
			continue
		box(x - 0.025, y, z1 - 0.06, 0.05, 1.0, 0.05, blue)
		if i < n:
			var xb := lerpf(x0, x2, float(i + 1) / n)
			var yb := lerpf(y0, DECK, clampf((xb - x0) / (x1 - x0), 0.0, 1.0))
			if not fine and i == 2:
				bar(Vector3(x, y + 1.0, z1 - 0.035), Vector3(xb - 0.3, y + 0.25, z1 + 0.4), 0.05, 0.05, blue)      # ...its rail bent down
				continue
			if not fine and i + 1 == 3:
				continue
			bar(Vector3(x, y + 1.0, z1 - 0.035), Vector3(xb, yb + 1.0, z1 - 0.035), 0.06, 0.05, blue)
			bar(Vector3(x, y + 0.5, z1 - 0.035), Vector3(xb, yb + 0.5, z1 - 0.035), 0.04, 0.04, blue)
	# the gate at its head, into the terrace
	box(53.3, DECK, WALL_Z, 1.6, 2.1, 0.05, blue)
	box(54.08, DECK, WALL_Z + 0.05, 0.04, 2.1, 0.02, 0x1d2f5c)
	if not fine:
		_planks(53.2, 55.0, [DECK + 0.7, DECK + 1.45], WALL_Z + 0.09, 19)

# ---------------- south of the terrace: the yard, its little house, the cypresses ----------------
func _yard(fine: bool) -> void:
	_front()
	var wk = "white" if fine else "blanco_viejo"
	var ring := _yard_ring()
	for i in range(ring.size() - 1):
		_fence(ring[i], ring[i + 1], 2.3, wk)
	_lay([Vector2(TER_S, WALL_Z - 0.2), Vector2(YARD_S - 0.2, WALL_Z - 0.2), Vector2(YARD_S - 0.2, -19.9), Vector2(66.0, -29.8), Vector2(58.2, -32.8), Vector2(58.2, TER_E), Vector2(TER_S, TER_E)], 0.04, "solado")
	# the white house with the flat roof at its far end, a little askew, and the hut by the wall
	var c := Vector2(91.0, -13.0)
	var gy := g(c.x, c.y)
	var keep := _xf
	_xf = _xf * Transform3D(Basis(Vector3.UP, -0.26), Vector3(c.x, 0.0, c.y))
	box(-4.0, DOWN, -4.0, 8.0, gy + 3.3 - DOWN, 8.0, wk)
	box(-4.15, gy + 3.3, -4.15, 8.3, 0.1, 8.3, 0xdcdad2 if fine else 0xaaa79c)
	box(-0.6, gy + 0.05, 4.0, 1.1, 2.05, 0.04, 0x2f55a8 if fine else (_fade(0x2f55a8, 0.5).to_rgba32() >> 8))
	box(-3.2, gy + 1.2, 4.0, 1.6, 1.0, 0.03, "cristal")
	_xf = keep
	var hy := g(88.0, -3.5)
	box(86.6, DOWN, -4.8, 2.8, hy + 2.3 - DOWN, 2.6, wk)
	box(86.5, hy + 2.3, -4.9, 3.0, 0.08, 2.8, "chapa" if fine else "chapa_vieja")
	# the pines that show over it all, on the verge and behind the house
	for q in [Vector3(79.0, 4.6, 5.2), Vector3(85.5, 5.6, 6.0), Vector3(91.5, 3.2, 5.4), Vector3(101.0, 6.2, 5.6), Vector3(85.0, -21.0, 5.6), Vector3(89.5, -24.5, 4.8)]:
		var ty := g(q.x, q.y)
		drum(Vector3(q.x, ty, q.y), 0.24, 0.16, q.z + 0.4, 0x5a4636, 7)
		ball(Vector3(q.x, ty + q.z + 1.9, q.y), 3.6 + fposmod(q.x, 1.0), "cipres", 0.62, 10, 6)
		ball(Vector3(q.x + 1.6, ty + q.z + 0.9, q.y - 1.2), 2.4, "cipres", 0.6, 9, 5)
		yard.append(P(q.x, q.y))

# ---------------- behind: the sheds along the plot's far side ----------------
func _back(fine: bool) -> void:
	_front()
	var wk = "gris" if fine else "gris_viejo"
	var rk = "chapa" if fine else "chapa_vieja"
	var ring := _shed_ring()
	_ring_walls(ring, DOWN, 3.2, wk)
	var pts := PackedVector2Array()
	for q: Vector2 in ring:
		pts.append(q)
	flat(pts, 3.2, rk)
	box(51.0, DOWN, -33.0, 7.2, g(54.0, -30.0) + 2.4 - DOWN, 33.0 + TER_E, wk)        # the little store against the terrace
	box(50.9, g(54.0, -30.0) + 2.4, -33.1, 7.4, 0.07, 33.2 + TER_E, rk)

# ---------------- the pavement along the front, and what lies on it ----------------
func _pavement(fine: bool) -> void:
	_front()
	_lay([Vector2(-13.0, 0.0), Vector2(X1, 0.0), Vector2(X1, BAR_Z), Vector2(BAR_X + 0.4, BAR_Z), Vector2(BAR_X + 0.4, 7.9), Vector2(X1 - 0.6, 7.9), Vector2(X1 - 0.6, 2.4), Vector2(-13.0, 2.4)], 0.05, "acera")
	_lay([Vector2(-13.0, 2.4), Vector2(X1 - 0.6, 2.4), Vector2(X1 - 0.6, 2.56), Vector2(-13.0, 2.56)], 0.06, 0x9a968c)
	if fine:
		return
	for k in range(30):                                                # weeds at the foot of the wall, and in the joints
		var x := -11.0 + _roll(k, 51) * (X1 + 10.0)
		var z := 0.18 + _roll(k, 53) * (2.2 if k % 3 == 0 else 0.25)
		_bush(Vector3(x, g(x, z) + 0.05, z), 0.16 + _roll(k, 55) * 0.2, "mata")
	for k in range(18):                                                # ...and of the terrace, the ramp and the shelter's posts
		var x := BAR_X + 0.5 + _roll(k, 81) * (TER_S - BAR_X + 6.0)
		var z := (2.5 if x < 55.2 else WALL_Z + 0.15) + _roll(k, 83) * (0.4 if k % 3 > 0 else 5.0)
		_bush(Vector3(x, g(x, z), z), 0.2 + _roll(k, 85) * 0.26, "mata")
	for k in range(3):                                                 # rubble and rubbish heaped against it
		var x := [22.5, 27.6, 44.6][k] as float
		var z := [0.5, 0.6, 3.4][k] as float
		var gy := g(x, z)
		for j in range(5):
			cbox(Vector3(x + (_roll(k * 5 + j, 57) - 0.5) * 1.3, gy + 0.08 + _roll(k * 5 + j, 59) * 0.14, z + (_roll(k * 5 + j, 61) - 0.5) * 0.7), Vector3(0.3 + _roll(j, 63) * 0.25, 0.18, 0.26), ["piedra", "tablon", "brick", "gris_viejo", "tablon"][j])
