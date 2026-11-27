extends "res://scripts/obra.gd"
## The Pizzería Toti (the user's name for it, 17 November 2026: "Tu siguiente objetivo es la pizzería ... Con su terraza y
## todo", and "La llamaremos Pizzeria Toti"), the pizzeria of the Calle de Ramón y Cajal, south of its corner with the
## Calle del Salvador, built by hand from Street View (November 2024, with April 2021, October 2019 and March 2013 at the
## same spots; Google's cameras there stand some 2.6 m south of where it says and 1.9 m further from the front: fitted
## between the house's two ends, tools/toti/LEEME in referencias/toti/).
##
## A block of three floors. The two upper ones of orange facing brick standing out a little over the street, three
## columns of wide windows with their white roller blinds (one with dark frames and net curtains). Below, the pizzeria in
## a frame of grey granite: its glazed door and a glass panel, the big window, a third opening behind a scissor gate;
## over them a maroon awning in two lengths with the telephone numbers (scribbles) and the name on its valance, and over
## the awning the white box board with the name, two air conditioners, an oval lit sign of beer, the electricity's boxes.
## Then white tiles: the flats' carved wooden door with its grille over it, and a garage of boards. Behind the glass
## its room, lit while it is open. Out on the pavement before it its terrace: tables and chairs inside a black railing
## and a low wooden fence, white chairs stacked against the wall (props.gd lays out the tables and chairs: they break).
##
## It is the house `cajal_3` of the map (casas_calles.gd marks it "obra": casas.gd draws nothing of it). Frame: the
## house's own -- x along the front from its north end (seen from the street, its left), z out to the street, y = 0 the
## pavement before its middle.

const HOUSE := "cajal_3"
const DIR := "res://assets/toti/"
const SOFFIT := 3.7                 # the ground floor's top: where the brick of the floors above begins...
const PROUD := 0.3                  # ...standing this far out over the street
const TOP := 9.3                    # the top of the front
const PIZZA := 9.6                  # the pizzeria's front: from the north end to here (then the flats' door and the garage)
const GLASS := -0.16                # the shopfront's plane, set back in its granite
const MAROON := 0x7a1a26
const ALU := 0x2b2d31               # the dark aluminium of the shopfront's frames
const COLS := [[2.85, 5.1, "persiana"], [8.15, 10.6, "visillo"], [13.5, 16.05, "persiana"]]   # the windows of the floors above: from, to, what is behind the glass
const FLOORS := [4.55, 7.25]        # their sills, first floor and second
const WIN_H := 1.3
const OPENS := 16.0                 # its hours (the user, 17 Nov 2026, from Google Maps): from four in the afternoon...
const SHUTS := [0.0, 0.0, 23.0, 23.0, 24.0, 24.0, 23.0]     # ...to eleven, or midnight on Friday and Saturday; shut on Monday and Tuesday (0 Monday ... 6 Sunday)

var len_front := 16.48
var door: Vector2                   # before its door, on the map
var sign_at: Vector3                # the middle of its box board, in the world (the self-test)
var terrace_mid: Vector2            # the middle of its terrace, on the map (the self-test)
var terrace_deep := 0.0             # how far out from the front its terrace comes
var tables := 0
var is_open := true
var _lights: Array = []

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"ladrillo":         # the orange facing brick (casas.gd's "brick_orange", so that it matches the street)
			var pick: String = Tex.pick("brick_orange")
			if pick != "":
				m = Tex.mat(pick, Color(1.18, 0.95, 0.78) if Tex.info(pick.get_slice("@", 0))["tint"] else Color.WHITE)
			else:
				var bm: StandardMaterial3D = W._tmat(0xffffff, "brick", 1.15)
				bm.albedo_color = Color(1.18, 0.95, 0.78)
				m = bm
		"granito":          # the grey granite round the shopfront, in slabs
			m = Tex.mat("granite_tile_04@1.2", Color(0.66, 0.66, 0.68))
		"azulejo":          # the white square tiles of the flats' part
			var img := Image.create(8, 8, false, Image.FORMAT_RGB8)
			img.fill(Parts.col(0xf2f2ef))
			for i in range(8):
				img.set_pixel(i, 0, Parts.col(0xc9cbc8))
				img.set_pixel(0, i, Parts.col(0xc9cbc8))
			var tm := StandardMaterial3D.new()
			tm.albedo_texture = ImageTexture.create_from_image(img)
			tm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			tm.uv1_triplanar = true
			tm.uv1_scale = Vector3.ONE / 0.3
			tm.emission_enabled = true                  # (white in the shade too)
			tm.emission = Color(0.95, 0.95, 0.94)
			tm.emission_energy_multiplier = 0.12
			m = tm
		"rotulo", "cerveza":
			var sm := StandardMaterial3D.new()
			var t: Texture2D = load(DIR + String(key) + ".png")
			sm.albedo_texture = t
			sm.emission_enabled = true
			sm.emission_texture = t
			sm.emission = Color.WHITE
			sm.emission_energy_multiplier = 0.3
			sm.roughness = 1.0
			if key == "cerveza":
				sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				sm.alpha_scissor_threshold = 0.5
				sm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = sm
		"toldo":            # the awning's valance: the name, scalloped at its foot
			var vm := StandardMaterial3D.new()
			vm.albedo_texture = load(DIR + "toldo.png")
			vm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			vm.alpha_scissor_threshold = 0.5
			vm.cull_mode = BaseMaterial3D.CULL_DISABLED
			vm.roughness = 1.0
			m = vm
		"lona":             # its canvas
			var lm := StandardMaterial3D.new()
			lm.albedo_color = Parts.col(MAROON)
			lm.cull_mode = BaseMaterial3D.CULL_DISABLED
			lm.roughness = 1.0
			m = lm
		"cristal":
			var gm := StandardMaterial3D.new()
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.albedo_color = Color(0.7, 0.8, 0.86, 0.22)
			gm.roughness = 0.5
			gm.metallic_specular = 0.15
			gm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = gm
		"ventana":          # the glass of the flats' windows: dark, a little sky in it
			var wm := StandardMaterial3D.new()
			wm.albedo_color = Color(0.17, 0.22, 0.27)
			wm.roughness = 0.25
			wm.metallic_specular = 0.5
			m = wm
		"persiana":         # a white roller blind, nearly down
			var pm := StandardMaterial3D.new()
			pm.albedo_color = Color(0.93, 0.91, 0.86)
			pm.emission_enabled = true
			pm.emission = Color(0.93, 0.91, 0.86)
			pm.emission_energy_multiplier = 0.12
			m = pm
		"sala":             # the room's walls, warm, lit
			var im := StandardMaterial3D.new()
			im.albedo_color = Color(0.95, 0.86, 0.7)
			im.emission_enabled = true
			im.emission = Color(0.95, 0.84, 0.66)
			im.emission_energy_multiplier = 0.35
			m = im
		"suelo":            # its floor of terracotta tiles
			var fm := StandardMaterial3D.new()
			fm.albedo_color = Color(0.72, 0.42, 0.3)
			fm.emission_enabled = true
			fm.emission = Color(0.72, 0.42, 0.3)
			fm.emission_energy_multiplier = 0.2
			m = fm
		"luz":
			var em := StandardMaterial3D.new()
			em.albedo_color = Color(1.0, 0.96, 0.86)
			em.emission_enabled = true
			em.emission = Color(1.0, 0.92, 0.76)
			em.emission_energy_multiplier = 2.0
			m = em
		"horno":            # the pizza oven's mouth, glowing
			var hm := StandardMaterial3D.new()
			hm.albedo_color = Color(0.9, 0.42, 0.12)
			hm.emission_enabled = true
			hm.emission = Color(1.0, 0.45, 0.1)
			hm.emission_energy_multiplier = 1.5
			m = hm
		"cochera":          # the garage's boards
			m = Tex.mat("weathered_planks", Color(0.62, 0.42, 0.28))
		"silla":            # the terrace's white plastic chairs, stacked
			var cm := StandardMaterial3D.new()
			cm.albedo_color = Color(0.96, 0.96, 0.94)
			cm.emission_enabled = true
			cm.emission = Color(0.9, 0.9, 0.88)
			cm.emission_energy_multiplier = 0.1
			m = cm
		"valla":            # the low wooden fence
			m = Tex.mat("old_planks_02", Color(0.62, 0.4, 0.26))
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world, hd: Dictionary) -> void:
	W = world
	var o := Vector2(hd["o"][0], hd["o"][1])
	var u := Vector2(hd["u"][0], hd["u"][1])
	var out := Vector2(-u.y, u.x)
	len_front = float(hd["len"])
	level = MapData.height(o + u * (len_front / 2.0) + out * 1.0)
	transform = Transform3D(Basis(Vector3(u.x, 0, u.y), Vector3.UP, Vector3(out.x, 0, out.y)), Vector3(o.x, level, o.y))
	W.add_child(self)
	door = spot(0.7, 1.0)
	var raw: Array = hd["pieces"][0]["ring"]
	var ring: Array = []
	for i in range(0, raw.size(), 2):
		var q: Vector3 = transform.affine_inverse() * Vector3(float(raw[i]), level, float(raw[i + 1]))
		ring.append(Vector2(q.x, q.z))
	_body(ring)
	_ground_floor()
	_shopfront()
	_portal()
	_upper()
	_boards()
	_awning()
	_inside()
	_terrace()
	home()
	_commit()
	for part in Geometry2D.decompose_polygon_in_convex(PackedVector2Array(ring)):
		var pts: Array = []
		for q: Vector2 in part:
			pts.append(Vector2(q.x, q.y))
		_prism_local(pts, -2.0, TOP)
	set_open(open_at(2, 20.0))

## the ground under a spot of the front (y of this frame)
func _g(x: float, z := 0.5) -> float:
	return ground(x, z)

## a solid with this outline (this frame) between two heights
func _prism_local(pts: Array, y0: float, y1: float) -> void:
	var v: Array = []
	for q: Vector2 in pts:
		v.append(transform * Vector3(q.x, y0, q.y))
		v.append(transform * Vector3(q.x, y1, q.y))
	var shape := ConvexPolygonShape3D.new()
	shape.points = PackedVector3Array(v)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	_solids().add_child(cs)

# ---------------- the house ----------------
## its walls other than the front (brick, both faces: the yard behind is seen from the houses round it), its flat roof
func _body(ring: Array) -> void:
	for i in range(ring.size()):
		var a: Vector2 = ring[i]
		var b: Vector2 = ring[(i + 1) % ring.size()]
		if absf(a.y) < 0.05 and absf(b.y) < 0.05:          # (the front: built on its own)
			continue
		if a.distance_to(b) < 0.05:
			continue
		_plain(a, b, -3.0, TOP, "ladrillo")
		_plain(b, a, -3.0, TOP, "ladrillo")
	home()
	var pts := PackedVector2Array()
	for q: Vector2 in ring:
		pts.append(q)
	flat(pts, TOP - 0.02, 0x8a8680)

## The ground floor's face: grey granite round the pizzeria (with its three openings), white tiles round the flats'
## door and the garage, a grey foot; each opening down to the pavement where it stands.
func _ground_floor() -> void:
	home()
	var holes := [Rect2(0.25, _g(0.7), 1.45, 2.45 - _g(0.7)), Rect2(2.15, 0.3, 4.2, 2.15), Rect2(6.95, _g(8.1), 2.25, 2.45 - _g(8.1))]
	masonry(0.0, PIZZA, -3.0, SOFFIT, holes, [], "granito", "granito")
	var doors := [Rect2(10.4, _g(11.2), 1.55, 2.5 - _g(11.2)), Rect2(13.3, _g(14.6), 2.7, 2.6 - _g(14.6))]
	masonry(PIZZA, len_front, -3.0, SOFFIT, doors, [], "azulejo", "azulejo")
	for run in [[PIZZA, 10.4], [11.95, 13.3], [16.0, len_front]]:                     # the tiles' grey foot
		box(float(run[0]), _g(float(run[0])) - 0.4, 0.0, float(run[1]) - float(run[0]), 0.72, 0.02, 0x9c9a96)
	box(0.0, SOFFIT - 0.06, 0.0, len_front, 0.06, 0.03, 0xb8b6b0)                      # (the edge under the brick)

## a frame of dark aluminium round a pane of glass: `r` on the plane z, `cols` its uprights
func _pane(r: Rect2, z: float, cols := 1, frame := 0.06) -> void:
	box(r.position.x, r.position.y, z - 0.01, r.size.x, r.size.y, 0.008, "cristal")
	for q in [[r.position.x, r.position.y, frame, r.size.y], [r.end.x - frame, r.position.y, frame, r.size.y], [r.position.x, r.position.y, r.size.x, frame], [r.position.x, r.end.y - frame, r.size.x, frame]]:
		box(q[0], q[1], z - 0.03, q[2], q[3], 0.06, ALU)
	for c in range(1, cols):
		box(r.position.x + r.size.x * c / cols - 0.025, r.position.y, z - 0.025, 0.05, r.size.y, 0.05, ALU)

## The shopfront: the glazed door and its panel of glass at the north end, the big window in three panes, and the third
## opening shut behind its scissor gate (a glazed door behind it).
func _shopfront() -> void:
	home()
	var g := GLASS
	var gd := _g(0.7)
	_pane(Rect2(0.25, gd, 0.95, 2.45 - gd), g)                                      # the door...
	box(0.28, gd + 1.0, g + 0.02, 0.04, 0.3, 0.04, 0xc8ccd0)                         # ...its handle
	_pane(Rect2(1.2, gd, 0.5, 2.45 - gd), g)                                        # ...the panel beside it
	_xf = Transform3D(Basis(Vector3.BACK, PI / 4.0), Vector3(1.45, gd + 1.55, g + 0.012))     # (a menu stuck on the glass, white, square-on-corner)
	box(-0.17, -0.17, 0.0, 0.34, 0.34, 0.004, 0xf4f2ec)
	box(-0.12, -0.12, 0.003, 0.24, 0.24, 0.002, 0xb33a3a)
	home()
	_pane(Rect2(2.15, 0.3, 4.2, 2.15), g, 3)                                       # the big window
	box(2.15, 0.0, -0.02, 4.2, 0.3, 0.035, 0x7c7c80)                                 # (its dark granite sill)
	var gg := _g(8.1)                                                                 # behind the gate: a glazed door, a panel
	_pane(Rect2(6.95, gg, 2.25, 2.45 - gg), g - 0.12, 2)
	var n := 13                                                                       # the scissor gate: crossed bars, a rail at top and foot
	for k in range(n):
		var x0: float = 6.98 + (2.2 / n) * k
		var x1: float = x0 + 2.2 / n
		bar(Vector3(x0, gg + 0.05, -0.06), Vector3(x1, gg + 2.35, -0.06), 0.022, 0.012, 0x5a5d62)
		bar(Vector3(x1, gg + 0.05, -0.06), Vector3(x0, gg + 2.35, -0.06), 0.022, 0.012, 0x5a5d62)
		box(x0 - 0.012, gg, -0.075, 0.024, 2.42, 0.03, 0x4a4d52)
	box(6.95, gg + 2.32, -0.08, 2.25, 0.1, 0.05, 0x4a4d52)
	box(6.95, gg, -0.08, 2.25, 0.06, 0.05, 0x4a4d52)
	solid(Vector3(8.07, gg + 1.2, -0.1), Vector3(2.25, 2.4, 0.12))

## The flats' door: two leaves of carved wood under a grille, a brass knob; the garage of boards, its sign of no parking.
func _portal() -> void:
	home()
	var gd := _g(11.2)
	var h := 2.5 - gd
	var x0 := 10.4
	for k in range(2):                                                                # its two leaves, each with three raised panels
		var lx: float = x0 + 0.03 + k * 0.76
		box(lx, gd, -0.2, 0.73, h - 0.45, 0.06, "wood")
		for j in range(3):
			var py: float = gd + 0.2 + j * (h - 0.75) / 3.0
			box(lx + 0.1, py, -0.15, 0.53, (h - 0.75) / 3.0 - 0.14, 0.03, 0x6a4026)
	box(x0, gd + h - 0.45, -0.2, 1.55, 0.45, 0.02, 0x241a14)                           # its grille over the leaves
	for k in range(9):
		box(x0 + 0.08 + k * 0.17, gd + h - 0.43, -0.17, 0.03, 0.41, 0.03, 0x1d1e20)
	drum(Vector3(x0 + 0.72, gd + 1.05, -0.14), 0.035, 0.035, 0.05, 0xc8a24a, 8)
	var gc := _g(14.6)                                                                # the garage: upright boards, two leaves
	var gh := 2.6 - gc
	box(13.3, gc, -0.22, 2.7, gh, 0.05, "cochera")
	for k in range(1, 18):
		box(13.3 + k * 0.15, gc, -0.165, 0.012, gh, 0.005, 0x4a3020)
	box(14.64, gc, -0.165, 0.02, gh, 0.01, 0x2a1a12)
	box(13.3, gc + gh - 0.5, -0.17, 2.7, 0.04, 0.01, 0x4a3020)
	box(12.8, 1.2, 0.0, 0.3, 0.44, 0.02, 0xf2f2ee)                                     # (its plate: no parking, a garage way)
	box(12.84, 1.42, 0.02, 0.22, 0.2, 0.004, 0xcc2a2a)
	box(12.87, 1.45, 0.025, 0.16, 0.14, 0.004, 0x1b4f9a)
	tbox(Transform3D(Basis(Vector3.BACK, 0.8) * Basis.from_scale(Vector3(0.24, 0.025, 0.004)), Vector3(12.95, 1.52, 0.03)), 0xcc2a2a)
	box(12.84, 1.26, 0.02, 0.22, 0.1, 0.004, 0x3a3c40)

## The two floors above: the orange brick standing out over the street, three columns of windows on each (white
## blinds nearly down; the middle one dark-framed with net curtains below), their sills, an air conditioner; the brick's
## underside; its end where the next house does not stand out; the parapet's coping.
func _upper() -> void:
	_xf = Transform3D(Basis.IDENTITY, Vector3(0, 0, PROUD))
	var holes: Array = []
	for f in FLOORS:
		for c in COLS:
			holes.append(Rect2(float(c[0]), float(f), float(c[1]) - float(c[0]), WIN_H))
	masonry(0.0, len_front, SOFFIT, TOP, holes, [], "ladrillo", "ladrillo")
	for fi in range(FLOORS.size()):
		var f: float = FLOORS[fi]
		for ci in range(COLS.size()):
			var c: Array = COLS[ci]
			var r := Rect2(float(c[0]), f, float(c[1]) - float(c[0]), WIN_H)
			var dark: bool = String(c[2]) == "visillo"
			window(r, ALU if dark else 0xece8de, 0x1f2a33, 1)
			box(r.position.x + 0.06, r.position.y + 0.06, -DEEP + 0.055, r.size.x - 0.12, r.size.y - 0.12, 0.01, "ventana")
			if String(c[2]) == "persiana" or (dark and fi == 1):                  # the blind's box over it, the blind nearly down
				var down: float = 0.85 if not dark else 0.25
				box(r.position.x, r.end.y - r.size.y * down, -DEEP + 0.13, r.size.x, r.size.y * down, 0.02, "persiana")
				for k in range(int(r.size.y * down / 0.06)):
					box(r.position.x, r.end.y - r.size.y * down + k * 0.06, -DEEP + 0.15, r.size.x, 0.006, 0.004, 0xc9c5ba)
			if dark and fi == 0:                                                     # net curtains behind the glass
				box(r.position.x + 0.08, r.position.y + 0.05, -DEEP + 0.072, r.size.x - 0.16, r.size.y - 0.1, 0.01, 0xd9d6cc)
			box(r.position.x - 0.06, r.position.y - 0.065, -0.02, r.size.x + 0.12, 0.05, 0.1, 0xd8d2c4)      # the sill
	box(11.7, 6.95, 0.0, 0.78, 0.52, 0.28, 0xe9e9e6)                                    # an air conditioner on the brick, between floors
	box(11.74, 7.0, 0.281, 0.7, 0.42, 0.002, 0x9a9c9e)
	home()
	quad(Vector3(0, SOFFIT, 0), Vector3(len_front, SOFFIT, 0), Vector3(len_front, SOFFIT, PROUD), Vector3(0, SOFFIT, PROUD), 0xd9d5cc, Vector3.DOWN)
	quad(Vector3(len_front, SOFFIT, 0), Vector3(len_front, SOFFIT, PROUD), Vector3(len_front, TOP, PROUD), Vector3(len_front, TOP, 0), "ladrillo", Vector3(1, 0, 0))
	quad(Vector3(0, SOFFIT, 0), Vector3(0, SOFFIT, PROUD), Vector3(0, TOP, PROUD), Vector3(0, TOP, 0), "ladrillo", Vector3(-1, 0, 0))     # (neither of its neighbours stands out)
	box(-0.02, TOP - 0.06, -0.3, len_front + 0.04, 0.1, PROUD + 0.34, 0xc9c2b4)          # the coping
	for k in range(int(len_front / 0.24)):                                            # a course of bricks on end under it
		box(k * 0.24 + 0.02, TOP - 0.3, PROUD, 0.2, 0.22, 0.015, "ladrillo")

## Over the awning: the white box board with the name (lit while open), two air conditioners, the oval sign of beer,
## the electricity's grey boxes.
func _boards() -> void:
	home()
	box(0.4, 3.12, 0.0, 2.45, 0.56, 0.16, 0xe8e8e4)
	_picture(0.42, 2.83, 3.14, 3.66, 0.165, "rotulo")
	sign_at = transform * Vector3(1.62, 3.4, 0.17)
	for x in [3.3, 5.0]:
		box(x, 2.95, 0.0, 0.95, 0.62, 0.3, 0xebebe8)
		slab(oval(x + 0.62, 3.26, 0.22, 0.22, 16), 0.302, 0.0, 0x8a8c8e)              # its fan's grille, round, square to the street
		slab(oval(x + 0.62, 3.26, 0.07, 0.07, 10), 0.304, 0.0, 0x5a5c5e)
		for k in range(5):
			box(x + 0.05, 3.0 + k * 0.1, 0.301, 0.3, 0.012, 0.003, 0xb0b2b4)
	box(6.92, 3.25, 0.0, 0.04, 0.04, 0.3, 0x5a5d62)                                     # the oval of beer on its arm, square to the street
	var keep := _xf
	_xf = Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(6.94, 0.0, 0.32))
	_picture(-0.24, 0.24, 2.92, 3.6, 0.0, "cerveza")
	_xf = Transform3D(Basis(Vector3.UP, -PI / 2.0), Vector3(6.94, 0.0, 0.32))
	_picture(-0.24, 0.24, 2.92, 3.6, 0.0, "cerveza")
	_xf = keep
	box(7.35, 3.05, 0.0, 0.62, 0.26, 0.12, 0xd5d6d2)
	box(8.5, 2.98, 0.0, 0.3, 0.44, 0.14, 0xd5d6d2)
	bar(Vector3(8.65, 2.98, 0.07), Vector3(8.65, 0.4, 0.07), 0.03, 0.03, 0x9a9c9e)      # (its pipe down)

func _picture(x0: float, x1: float, y0: float, y1: float, z: float, key) -> void:
	pieces += 1
	quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

## The awning in two lengths over the pizzeria: its maroon canvas sloping out 1.3 m from its bar on the granite, its
## valance with the telephone numbers and the name, its two arms.
func _awning() -> void:
	home()
	for run in [[0.1, 4.75], [4.85, 9.5]]:
		var x0: float = run[0]
		var x1: float = run[1]
		var y0 := 2.68
		var y1 := 2.28
		var z1 := 1.3
		box(x0, y0 - 0.05, 0.0, x1 - x0, 0.1, 0.1, 0x4a1a1e)                             # its bar
		quad(Vector3(x0, y0, 0.08), Vector3(x1, y0, 0.08), Vector3(x1, y1, z1), Vector3(x0, y1, z1), "lona", Vector3(0, 0.95, 0.3).normalized())
		for x in [x0, x1]:                                                              # its cheeks
			tri(Vector3(x, y0, 0.08), Vector3(x, y1, z1), Vector3(x, y1 - 0.3, z1), "lona", Vector3(1, 0, 0))
		pieces += 1
		quad(Vector3(x0, y1 - 0.3, z1), Vector3(x1, y1 - 0.3, z1), Vector3(x1, y1, z1), Vector3(x0, y1, z1), "toldo", Vector3(0, 0, 1),
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
		for x in [x0 + 0.15, x1 - 0.15]:                                                # its arms
			bar(Vector3(x, 1.95, 0.02), Vector3(x, y1 + 0.02, z1 - 0.05), 0.03, 0.03, 0x3a3c40)

# ---------------- inside, as seen through the glass ----------------
## Its room behind the glass: terracotta floor, warm walls, the counter at the back with the pizza oven glowing in the
## wall behind it, the menu over it; tables with chairs; lamps (all of it lit only while open).
func _inside() -> void:
	home()
	var back := -7.0
	var c := 3.1
	var x0 := 0.2
	var x1 := 9.3
	var f := _g(4.0) + 0.02
	var zf := -DEEP - 0.02                                                              # (just behind the openings' reveals)
	quad(Vector3(x0, f, back), Vector3(x1, f, back), Vector3(x1, f, zf), Vector3(x0, f, zf), "suelo", Vector3.UP)
	quad(Vector3(x0, c, back), Vector3(x1, c, back), Vector3(x1, c, zf), Vector3(x0, c, zf), "sala", Vector3.DOWN)
	quad(Vector3(x0, f, back), Vector3(x1, f, back), Vector3(x1, c, back), Vector3(x0, c, back), "sala", Vector3(0, 0, 1))
	quad(Vector3(x0, f, back), Vector3(x0, f, zf), Vector3(x0, c, zf), Vector3(x0, c, back), "sala", Vector3(1, 0, 0))
	quad(Vector3(x1, f, back), Vector3(x1, f, zf), Vector3(x1, c, zf), Vector3(x1, c, back), "sala", Vector3(-1, 0, 0))
	quad(Vector3(x0, f - 1.0, zf), Vector3(x1, f - 1.0, zf), Vector3(x1, f, zf), Vector3(x0, f, zf), "sala", Vector3(0, 0, 1))      # (under its floor's edge)
	box(x0, f, back + 0.02, x1 - x0, 1.0, 0.01, 0xa04a32)                               # a band of red tiles low round the walls
	# the counter at the back, the oven in the wall behind it, the menu
	box(1.0, f, back + 1.2, 4.2, 1.05, 0.65, 0x5a3a2a)
	box(0.95, f + 1.05, back + 1.15, 4.3, 0.05, 0.75, 0xd8d2c4)
	box(2.4, f + 0.8, back + 0.01, 1.4, 1.1, 0.05, 0xa84a2c)                            # the oven's brick face, its glowing mouth
	_xf = Transform3D(Basis.IDENTITY, Vector3(3.1, f + 1.05, back + 0.07))
	arched(0.0, 0.0, 0.18, 0.32, 0.0, "horno")
	home()
	box(5.6, f + 1.55, back + 0.02, 2.6, 0.9, 0.02, 0x1d1e20)
	for k in range(5):
		box(5.75, f + 1.68 + k * 0.15, back + 0.04, 1.4 + (k % 3) * 0.3, 0.05, 0.005, 0xf2efe6)
	# tables and chairs in the room
	for t in [Vector2(3.0, -2.2), Vector2(5.4, -2.2), Vector2(7.8, -2.2), Vector2(3.0, -4.4), Vector2(7.8, -4.4)]:
		box(t.x - 0.45, f + 0.74, t.y - 0.45, 0.9, 0.04, 0.9, 0xe8e2d4)
		bar(Vector3(t.x, f, t.y), Vector3(t.x, f + 0.74, t.y), 0.06, 0.06, 0x2a2a2c)
		for s in [-1.0, 1.0]:
			var cx: float = t.x + s * 0.65
			box(cx - 0.2, f + 0.44, t.y - 0.2, 0.4, 0.04, 0.4, 0x8a3a2a)
			box(cx + s * 0.18 - 0.02, f + 0.44, t.y - 0.2, 0.04, 0.42, 0.4, 0x8a3a2a)
			for lz in [-0.17, 0.17]:
				bar(Vector3(cx - 0.17, f, t.y + lz), Vector3(cx - 0.17, f + 0.44, t.y + lz), 0.025, 0.025, 0x2a2a2c)
				bar(Vector3(cx + 0.17, f, t.y + lz), Vector3(cx + 0.17, f + 0.44, t.y + lz), 0.025, 0.025, 0x2a2a2c)
	for z in [-1.6, -4.0]:                                                               # its lamps
		for x in [2.4, 5.4, 8.2]:
			cbox(Vector3(x, c - 0.03, z), Vector3(0.45, 0.04, 0.45), "luz")
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(5.0, 2.6, -2.8)
	lamp.light_color = Color(1.0, 0.9, 0.75)
	lamp.omni_range = 6.5
	lamp.light_energy = 0.8
	lamp.shadow_enabled = false
	add_child(lamp)
	_lights.append(lamp)

# ---------------- the terrace ----------------
## Its terrace out on the pavement (the game's pavement there is narrow: the real one takes a little of the street):
## three small tables along the front with a chair either side, a black railing along the pavement's edge with a low
## wooden fence on it, open at the north end by the door; two stacks of white chairs against the gate.
func _terrace() -> void:
	home()
	var deep := 3.0
	for x in [0.5, 3.0, 5.5, 8.0, 9.4]:                                                # as far as the pavement goes (to the asphalt as drawn)
		var p := spot(x, 0.1)
		var e: float = MapData.road_edge_dist(p)
		if MapData.road_hit != null:
			e += MapData.road_hit.hw - MapData.fitted_hw(MapData.road_hit)
		deep = minf(deep, e - 0.15)
	deep = clampf(deep, 1.25, 2.6)
	terrace_deep = deep
	terrace_mid = spot(5.0, deep / 2.0)
	# the railing and its fence along the outer edge, and back to the front at the south end
	var rz := deep - 0.05
	var post := func(x: float, z: float) -> void:
		var g := _g(x, z)
		box(x - 0.03, g, z - 0.03, 0.06, 1.0, 0.06, 0x1d1e20)
	var run: Array = [Vector2(1.5, rz), Vector2(9.35, rz), Vector2(9.35, 0.05)]
	for i in range(run.size() - 1):
		var a: Vector2 = run[i]
		var b: Vector2 = run[i + 1]
		var ln := a.distance_to(b)
		var n := maxi(1, int(ceil(ln / 1.6)))
		for k in range(n + 1):
			var p: Vector2 = a.lerp(b, float(k) / n)
			post.call(p.x, p.y)
		var ga := _g(a.x, a.y)
		var gb := _g(b.x, b.y)
		bar(Vector3(a.x, ga + 0.97, a.y), Vector3(b.x, gb + 0.97, b.y), 0.04, 0.04, 0x1d1e20)
		bar(Vector3(a.x, ga + 0.15, a.y), Vector3(b.x, gb + 0.15, b.y), 0.03, 0.03, 0x1d1e20)
		if i == 0:                                                                     # the wooden fence on the outer run: pickets
			var m := int(ln / 0.14)
			for k in range(m):
				var p: Vector2 = a.lerp(b, (k + 0.5) / m)
				var g := _g(p.x, p.y)
				box(p.x - 0.04, g + 0.12, p.y + 0.03, 0.08, 0.72 + (0.04 if k % 2 == 0 else 0.0), 0.02, "valla")
			bar(Vector3(a.x, ga + 0.6, a.y + 0.045), Vector3(b.x, gb + 0.6, b.y + 0.045), 0.03, 0.06, "valla")
		else:                                                                          # the railing's bars at the south end
			var m := int(ln / 0.12)
			for k in range(m):
				var p: Vector2 = a.lerp(b, (k + 0.5) / m)
				var g := _g(p.x, p.y)
				box(p.x - 0.008, g + 0.15, p.y - 0.008, 0.016, 0.82, 0.016, 0x1d1e20)
		var mid := (a + b) / 2.0
		var d := (b - a).normalized()
		solid(Vector3(mid.x, (ga + gb) / 2.0 + 0.5, mid.y), Vector3(ln + 0.06, 1.0, 0.08), atan2(-d.y, d.x))
		yard.append(spot(mid.x, mid.y))
	# two stacks of white chairs against the scissor gate
	for x in [8.1, 8.85]:
		var g := _g(x, 0.35)
		for k in range(7):
			var y: float = g + k * 0.09
			box(x - 0.22, y + 0.42, 0.13, 0.44, 0.04, 0.42, "silla")
			box(x - 0.22, y + 0.46, 0.1, 0.44, 0.4, 0.04, "silla")
		for lx in [-0.2, 0.18]:
			for lz in [0.14, 0.52]:
				box(x + lx, g, lz, 0.03, 0.44 + 0.54, 0.03, "silla")
		solid(Vector3(x, g + 0.6, 0.35), Vector3(0.5, 1.2, 0.5))
	# the tables and chairs: props.gd lays them out, as it does every terrace (they break), and puts customers by them
	var lay := {"props": [], "gente": []}
	var tz := minf(0.55, deep / 2.0 - 0.05)
	for tx in [2.4, 4.5, 6.6]:
		var tp := spot(tx, tz)
		lay["props"].append(["table", tp, 0.0, tables])
		tables += 1
		for s in [-1.0, 1.0]:
			var cp := spot(tx + s * 0.78, tz)
			var dv: Vector2 = tp - cp
			lay["props"].append(["chair", cp, atan2(dv.x, dv.y), 0])
	lay["gente"] = [spot(0.8, 0.8), spot(9.9, 0.9)]                                  # (by its door, and before the flats' tiles)
	W.extra_terrazas.append([terrace_mid, spot(1.0, 0.0) - spot(0.0, 0.0), lay])

# ---------------- open and shut ----------------
## whether it is open on that day of the week (0 Monday ... 6 Sunday) at that hour
func open_at(day: int, hour: float) -> bool:
	var shuts: float = SHUTS[posmod(day, 7)]
	return shuts > 0.0 and hour >= OPENS and hour < shuts

## whether it is dark enough out for its room's lamp to be a real light (by day the room is lit by its own glow: a real
## light costs, and the night's are few -- Sistemas, 17 Nov 2026: "que no tengan sombra y que se apaguen de día")
static func dark_at(hour: float) -> bool:
	return hour >= 19.5 or hour < 7.5

func _process(_delta: float) -> void:
	var game = W.get_parent() if W != null else null
	if game != null and "clock" in game and "weekday" in game:
		var want: bool = open_at(int(game.weekday), float(game.clock))
		if want != is_open:
			set_open(want)
		var lit: bool = is_open and dark_at(float(game.clock))
		for lamp in _lights:
			if (lamp as Light3D).visible != lit:
				(lamp as Light3D).visible = lit

## open: the room lit, the board and the oval of beer lit; shut: dark (its lamp a real light only at night: _process)
func set_open(on: bool) -> void:
	is_open = on
	for lamp in _lights:
		(lamp as Light3D).visible = on
	for key in ["rotulo", "cerveza"]:
		if _mats.has(key):
			var bm := _mats[key] as StandardMaterial3D
			bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if on else BaseMaterial3D.SHADING_MODE_PER_PIXEL
			bm.emission_energy_multiplier = 0.0
	for q in [["sala", 0.35], ["suelo", 0.2], ["luz", 2.0], ["horno", 1.5]]:
		if _mats.has(q[0]):
			(_mats[q[0]] as StandardMaterial3D).emission_energy_multiplier = float(q[1]) if on else 0.0
