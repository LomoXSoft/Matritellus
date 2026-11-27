extends "res://scripts/obra.gd"
## The house on the corner of the Calle del Salvador and the Calle de Ramón y Cajal, beside the Pizzería Toti (the
## user, 17 November 2026: "Puedes ponerte con Salvador 2. La casa pegada a toti con dos entradas que hace esquina en
## la calle"), built by hand from Street View (November 2024 and 2021, 2019, 2013, 2009 from the crossroads and from Ramón
## y Cajal; along the Salvador only March 2013). Its address is never shown.
##
## Three floors. Below, white tiles set as diamonds over a foot of grey granite: on the Ramón y Cajal a barred window
## with its air conditioner over it and, in a bay of the dark brick, the flats' door behind a striped curtain; on the
## corner's cut a glazed door behind a scissor gate, the signs of the street over it (one way, no entry but for those who
## live there); on the Salvador the other door and a big barred window. Above, dark brown brick: on the corner a bay
## standing out on both floors with its wide windows and their cream blinds; balconies with white railings and striped
## awnings, one on each floor on the Ramón y Cajal, a long one on each floor on the Salvador; white slabs. A planter by
## the corner.
##
## It is the house `cajal_1` of the map (casas_calles.gd marks it "obra"). Frame: the map's own (x east, z south), y = 0
## the pavement at the corner. Each front is built in its own frame (obra.face: x along it seen from the street, z out).

const HOUSE := "cajal_1"
const K_S := Vector2(-148.74, 14.86)         # the Ramón y Cajal front's south end (where the Toti begins)
const C1 := Vector2(-147.23, 7.886)          # the corner's cut: its end on the Ramón y Cajal...
const C2 := Vector2(-145.67, 6.66)           # ...and on the Salvador
const S_E := Vector2(-136.75, 5.95)          # the Salvador front's east end
const BACK: Array = [Vector2(-136.8, 16.61), Vector2(-138.42, 16.45), Vector2(-138.44, 13.76), Vector2(-139.45, 13.77),
	Vector2(-139.89, 16.29), Vector2(-141.34, 16.14), Vector2(-141.89, 15.6)]      # Catastro's outline behind, back to K_S
const SLAB := 3.5                   # the first floor's slab
const FLOOR_H := 2.9                # floor to floor above
const TOP := 9.6                    # the parapet's top
const BAY := 1.9                    # the corner's bay: how far along each front it comes...
const BAY_OUT := 0.55               # ...and how far out
const BALC_OUT := 0.55              # the balconies' depth
const PLINTH := 0.55                # the granite foot's height
const WHITE := 0xeeece6
const RAIL := 0xf2f2ee

var door_cajal: Vector2             # before its two doors, on the map
var door_salvador: Vector2
var bays := 0                       # (the self-test: the bay's windows, the balconies)
var balconies := 0
var _out_rc := Vector2.ZERO         # outward normals of the three fronts
var _out_ch := Vector2.ZERO
var _out_sv := Vector2.ZERO

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"ladrillo":         # the dark brown facing brick (casas.gd's "brick_dark")
			var pick: String = Tex.pick("brick_dark")
			if pick != "":
				m = Tex.mat(pick, Color(0.6, 0.48, 0.44) if Tex.info(pick.get_slice("@", 0))["tint"] else Color.WHITE)
			else:
				var bm: StandardMaterial3D = W._tmat(0xffffff, "brick", 1.15)
				bm.albedo_color = Color(0.6, 0.48, 0.44)
				m = bm
		"azulejo":          # white tiles set as diamonds
			var img := Image.create(16, 16, false, Image.FORMAT_RGB8)
			img.fill(Parts.col(0xf3f3f0))
			for i in range(16):
				img.set_pixel(i, i, Parts.col(0xc8cac8))
				img.set_pixel(i, 15 - i, Parts.col(0xc8cac8))
			var tm := StandardMaterial3D.new()
			tm.albedo_texture = ImageTexture.create_from_image(img)
			tm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			tm.uv1_triplanar = true
			tm.uv1_world_triplanar = true
			tm.uv1_scale = Vector3.ONE / 0.42
			tm.emission_enabled = true
			tm.emission = Color(0.95, 0.95, 0.94)
			tm.emission_energy_multiplier = 0.12
			m = tm
		"granito":
			m = Tex.mat("granite_tile_04@1.2", Color(0.66, 0.66, 0.68))
		"rayas":            # the awnings' and the curtain's stripes, cream and brown (u: one pair of stripes a unit)
			var img := Image.create(2, 1, false, Image.FORMAT_RGB8)
			img.set_pixel(0, 0, Parts.col(0xe6dcc2))
			img.set_pixel(1, 0, Parts.col(0x8a5a3a))
			var sm := StandardMaterial3D.new()
			sm.albedo_texture = ImageTexture.create_from_image(img)
			sm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			sm.cull_mode = BaseMaterial3D.CULL_DISABLED
			sm.roughness = 1.0
			m = sm
		"persiana":         # cream roller blinds
			var pm := StandardMaterial3D.new()
			pm.albedo_color = Color(0.9, 0.85, 0.7)
			pm.emission_enabled = true
			pm.emission = Color(0.9, 0.85, 0.7)
			pm.emission_energy_multiplier = 0.1
			m = pm
		"ventana":
			var wm := StandardMaterial3D.new()
			wm.albedo_color = Color(0.17, 0.22, 0.27)
			wm.roughness = 0.25
			wm.metallic_specular = 0.5
			m = wm
		"sofito":           # the wooden slats under the slabs
			m = Tex.mat("brown_planks_03", Color(0.7, 0.5, 0.34))
		"seto":
			m = W._tmat(0x3f6a34, "leaf", 0.8)
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world, _hd: Dictionary) -> void:
	W = world
	_out_rc = _outward(C1, K_S)
	_out_ch = _outward(C2, C1)
	_out_sv = _outward(S_E, C2)
	var corner := (C1 + C2) / 2.0
	level = MapData.height(corner + _out_ch * 1.0)
	transform = Transform3D(Basis.IDENTITY, Vector3(0.0, level, 0.0))
	W.add_child(self)
	door_cajal = _along(C1, K_S, 5.85) + _out_rc * 1.0
	door_salvador = _along(S_E, C2, 2.45) + _out_sv * 1.0
	var ring: Array = [K_S, C1, C2, S_E] + BACK
	_body(ring)
	_cajal()
	_chamfer()
	_salvador()
	_bay()
	_bands()
	_signs()
	home()
	_commit()
	for part in Geometry2D.decompose_polygon_in_convex(PackedVector2Array(ring)):
		var pts: Array = []
		for q: Vector2 in part:
			pts.append(q)
		_prism(pts, -2.0, TOP)

# ---------------- helpers ----------------
## the outward normal of a front built from a to b (obra.face's +z)
func _outward(a: Vector2, b: Vector2) -> Vector2:
	var d := (b - a).normalized()
	return Vector2(-d.y, d.x)

func _along(a: Vector2, b: Vector2, s: float) -> Vector2:
	return a + (b - a).normalized() * s

## the ground at a spot of a front, s along it, a little out (this frame's y)
func _gf(a: Vector2, b: Vector2, s: float) -> float:
	return ground(_along(a, b, s).x + _outward(a, b).x * 0.3, _along(a, b, s).y + _outward(a, b).y * 0.3)

## a flat piece facing down at height y
func _flat_down(pts: PackedVector2Array, y: float, key) -> void:
	pieces += 1
	var idx := Geometry2D.triangulate_polygon(pts)
	for t in range(0, idx.size(), 3):
		var a := pts[idx[t]]
		var b := pts[idx[t + 1]]
		var c := pts[idx[t + 2]]
		tri(Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y), key, Vector3.DOWN)

## a window of the floors above in its hole: white frame, dark glass, the cream blind down to `down` of it
func _flat_window(r: Rect2, down: float) -> void:
	window(r, 0xece8de, 0x1f2a33, 1)
	box(r.position.x, r.position.y, -DEEP + 0.045, r.size.x, r.size.y, 0.01, "ventana")
	if down > 0.0:
		box(r.position.x, r.end.y - r.size.y * down, -DEEP + 0.13, r.size.x, r.size.y * down, 0.02, "persiana")
		for k in range(int(r.size.y * down / 0.06)):
			box(r.position.x, r.end.y - r.size.y * down + k * 0.06, -DEEP + 0.15, r.size.x, 0.006, 0.004, 0xb8ac90)

## an iron grille of upright bars in front of a ground-floor window
func _bars(r: Rect2) -> void:
	var n := maxi(3, int(r.size.x / 0.13))
	for k in range(n + 1):
		box(r.position.x + r.size.x * k / n - 0.012, r.position.y - 0.04, 0.02, 0.024, r.size.y + 0.08, 0.024, 0x1d1e20)
	for y in [r.position.y, r.end.y, r.position.y + r.size.y * 0.5]:
		box(r.position.x - 0.03, y - 0.015, 0.015, r.size.x + 0.06, 0.03, 0.03, 0x1d1e20)

## a striped awning over a balcony's door, sloping out from the wall: x0..x1, its top y on the wall, `out` its reach
func _awning(x0: float, x1: float, y: float, out := 0.8) -> void:
	var w := x1 - x0
	var uvs := [Vector2(0, 0), Vector2(w / 0.24, 0), Vector2(w / 0.24, 1), Vector2(0, 1)]
	quad(Vector3(x0, y, 0.02), Vector3(x1, y, 0.02), Vector3(x1, y - 0.5, out), Vector3(x0, y - 0.5, out), "rayas", Vector3(0, 0.85, 0.5).normalized(), uvs)
	quad(Vector3(x0, y - 0.5, out), Vector3(x1, y - 0.5, out), Vector3(x1, y - 0.7, out), Vector3(x0, y - 0.7, out), "rayas", Vector3(0, 0, 1), uvs)
	box(x0, y - 0.03, 0.0, w, 0.06, 0.08, 0x6a4a34)
	for x in [x0 + 0.05, x1 - 0.05]:
		bar(Vector3(x, y - 1.0, 0.02), Vector3(x, y - 0.5, out - 0.02), 0.025, 0.025, 0x3a3c40)

## a balcony on a front (frame of that front): x0..x1, its floor at y; a white slab with its wooden soffit, a white
## railing round it
func _balcony(x0: float, x1: float, y: float) -> void:
	balconies += 1
	box(x0, y - 0.135, 0.0, x1 - x0, 0.135, BALC_OUT, WHITE)
	box(x0, y - 0.15, 0.0, x1 - x0, 0.015, BALC_OUT, "sofito")
	var z := BALC_OUT - 0.05
	var n := int((x1 - x0) / 0.11)
	for k in range(n + 1):
		box(x0 + 0.03 + (x1 - x0 - 0.06) * k / n - 0.01, y, z - 0.01, 0.02, 0.95, 0.02, RAIL)
	box(x0 + 0.02, y + 0.95, z - 0.03, x1 - x0 - 0.04, 0.05, 0.06, RAIL)
	box(x0 + 0.02, y + 0.12, z - 0.02, x1 - x0 - 0.04, 0.03, 0.04, RAIL)
	for x in [x0 + 0.03, x1 - 0.05]:                                               # its sides
		for k in range(5):
			box(x, y, 0.08 + k * 0.09, 0.02, 0.95, 0.02, RAIL)
		box(x - 0.01, y + 0.95, 0.0, 0.04, 0.05, BALC_OUT, RAIL)

## a balcony's door in its hole: white frame, glass, its blind half down
func _balcony_door(x0: float, x1: float, y: float) -> void:
	_flat_window(Rect2(x0, y, x1 - x0, 2.2), 0.45)

# ---------------- the house ----------------
## its walls other than the fronts (brick both faces), its flat roof
func _body(ring: Array) -> void:
	for i in range(ring.size()):
		var a: Vector2 = ring[i]
		var b: Vector2 = ring[(i + 1) % ring.size()]
		if (a == K_S and b == C1) or (a == C1 and b == C2) or (a == C2 and b == S_E):
			continue
		if a.distance_to(b) < 0.05:
			continue
		_plain(a, b, -3.0, TOP, "ladrillo")
		_plain(b, a, -3.0, TOP, "ladrillo")
	home()
	var pts := PackedVector2Array()
	for q: Vector2 in ring:
		pts.append(q)
	flat(pts, TOP - 0.25, 0x8a8680)

## The Ramón y Cajal front (from the corner's cut to the Toti): below, the tiles with the barred window, then a bay of
## brick with the flats' door behind its striped curtain; above, brick with a balcony on each floor (its door, its
## awning) and the bay of the corner at the north end.
func _cajal() -> void:
	var L := face(C1, K_S, 0.0)
	var gw := _gf(C1, K_S, 2.1)
	var win := Rect2(1.0, gw + 0.9, 2.3, 1.55)
	masonry(0.0, 4.6, -3.0, SLAB, [win], [], "azulejo", "azulejo")
	var gd := _gf(C1, K_S, 5.85)
	var dr := Rect2(5.2, gd, 1.3, 2.45)
	masonry(4.6, L, -3.0, SLAB, [dr], [], "ladrillo", "ladrillo")
	box(0.0, gw - 0.6, 0.0, 4.6, PLINTH + 0.6, 0.03, "granito")
	box(win.position.x, win.position.y - 0.04, 0.0, win.size.x, 0.04, 0.08, 0xc8c6c0)        # the window's sill
	window(win, 0xe8e6e0, 0x1f2a33, 1)
	box(win.position.x, win.position.y, -DEEP + 0.12, win.size.x, win.size.y * 0.8, 0.02, "persiana")
	_bars(win)
	box(2.0, 2.65, 0.0, 0.8, 0.5, 0.26, 0xebebe8)                                     # its air conditioner over it
	slab(oval(2.55, 2.9, 0.18, 0.18, 14), 0.262, 0.0, 0x8a8c8e)
	# the flats' door: carved wood behind a curtain of cream and brown stripes hung in its frame
	box(dr.position.x, dr.position.y, -0.24, dr.size.x, dr.size.y, 0.06, "wood")
	var uvs := [Vector2(0, 1), Vector2(dr.size.x / 0.2, 1), Vector2(dr.size.x / 0.2, 0), Vector2(0, 0)]
	quad(Vector3(dr.position.x, dr.position.y + 0.04, -0.05), Vector3(dr.end.x, dr.position.y + 0.04, -0.05), Vector3(dr.end.x, dr.end.y, -0.05), Vector3(dr.position.x, dr.end.y, -0.05), "rayas", Vector3(0, 0, 1), uvs)
	box(dr.position.x - 0.05, dr.end.y - 0.04, -0.08, dr.size.x + 0.1, 0.05, 0.06, 0x3a3c40)    # (the curtain's rail)
	box(dr.position.x - 0.12, dr.position.y, 0.0, 0.12, dr.size.y + 0.12, 0.04, 0xc9c2b4)       # a frame of stone round it
	box(dr.end.x, dr.position.y, 0.0, 0.12, dr.size.y + 0.12, 0.04, 0xc9c2b4)
	box(dr.position.x - 0.12, dr.end.y, 0.0, dr.size.x + 0.24, 0.12, 0.04, 0xc9c2b4)
	# above: brick, a balcony on each floor
	var holes: Array = []
	for k in range(2):
		holes.append(Rect2(3.05, SLAB + k * FLOOR_H + 0.15, 1.4, 2.2))
	masonry(0.0, L, SLAB, TOP, holes, [], "ladrillo", "ladrillo")
	for k in range(2):
		var y: float = SLAB + k * FLOOR_H + 0.15
		_balcony_door(3.05, 4.45, y)
		_balcony(2.45, 5.05, y)
		_awning(2.85, 4.65, y + 2.55)
	box(5.4, SLAB + 2.3, 0.0, 0.75, 0.45, 0.25, 0xebebe8)                             # an air conditioner by the balcony
	box(2.0, SLAB + FLOOR_H + 2.2, 0.0, 0.75, 0.45, 0.25, 0xebebe8)
	home()

## The corner's cut: the glazed door behind its scissor gate, tiles round it, the granite foot.
func _chamfer() -> void:
	var L := face(C2, C1, 0.0)
	var g := _gf(C2, C1, L / 2.0)
	var dr := Rect2(0.4, g, 1.2, 2.45)
	masonry(0.0, L, -3.0, SLAB, [dr], [], "azulejo", "azulejo")
	box(0.0, g - 0.6, 0.0, 0.4, PLINTH + 0.6, 0.03, "granito")
	box(1.6, g - 0.6, 0.0, L - 1.6, PLINTH + 0.6, 0.03, "granito")
	box(dr.position.x, dr.position.y, -0.28, dr.size.x, dr.size.y, 0.008, "ventana")
	box(dr.position.x, dr.position.y, -0.3, 0.05, dr.size.y, 0.05, 0x3a3c40)
	box(dr.end.x - 0.05, dr.position.y, -0.3, 0.05, dr.size.y, 0.05, 0x3a3c40)
	var n := 8                                                                      # the scissor gate
	for k in range(n):
		var x0: float = dr.position.x + dr.size.x * k / n
		var x1: float = dr.position.x + dr.size.x * (k + 1) / n
		bar(Vector3(x0, g + 0.05, -0.08), Vector3(x1, g + 2.4, -0.08), 0.022, 0.012, 0x2e3a34)
		bar(Vector3(x1, g + 0.05, -0.08), Vector3(x0, g + 2.4, -0.08), 0.022, 0.012, 0x2e3a34)
		box(x0 - 0.012, g, -0.095, 0.024, 2.45, 0.03, 0x26302b)
	box(dr.position.x, g + 2.38, -0.1, dr.size.x, 0.08, 0.05, 0x26302b)
	solid(Vector3(_along(C2, C1, L / 2.0).x, g + 1.2, _along(C2, C1, L / 2.0).y), Vector3(L, 2.4, 0.3), -atan2((C1 - C2).y, (C1 - C2).x))
	home()

## The Salvador front (from its east end to the corner's cut): below, the tiles with the flats' other door and the big
## barred window; above, brick with a long balcony on each floor, two doors on each with their awnings.
func _salvador() -> void:
	var L := face(S_E, C2, 0.0)
	var gd := _gf(S_E, C2, 2.45)
	var dr := Rect2(1.95, gd, 1.0, 2.4)
	var g0 := _gf(S_E, C2, 0.95)
	var win0 := Rect2(0.3, g0 + 0.95, 1.3, 1.5)                                       # a barred window at its east end...
	var gw := _gf(S_E, C2, 5.0)
	var win := Rect2(3.6, gw + 0.85, 2.8, 1.65)                                       # ...the door, then the big barred window
	masonry(0.0, L, -3.0, SLAB, [win0, dr, win], [], "azulejo", "azulejo")
	box(0.0, gd - 0.6, 0.0, 1.95, PLINTH + 0.6, 0.03, "granito")
	box(2.95, gd - 0.6, 0.0, L - 2.95, PLINTH + 0.6, 0.03, "granito")
	box(win0.position.x, win0.position.y - 0.04, 0.0, win0.size.x, 0.04, 0.08, 0xc8c6c0)
	window(win0, 0xe8e6e0, 0x1f2a33, 1)
	box(win0.position.x, win0.position.y, -DEEP + 0.12, win0.size.x, win0.size.y * 0.85, 0.02, "persiana")
	_bars(win0)
	box(dr.position.x, dr.position.y, -0.22, dr.size.x, dr.size.y, 0.05, 0x4a3a30)          # the door: dark, a little grille high in it
	box(dr.position.x + 0.25, dr.position.y + 1.55, -0.17, 0.5, 0.5, 0.01, 0x1d1e20)
	for k in range(5):
		box(dr.position.x + 0.28 + k * 0.1, dr.position.y + 1.55, -0.16, 0.02, 0.5, 0.02, 0x8a8c8e)
	drum(Vector3(dr.position.x + 0.85, dr.position.y + 1.05, -0.165), 0.03, 0.03, 0.04, 0xc8a24a, 8)
	box(win.position.x, win.position.y - 0.04, 0.0, win.size.x, 0.04, 0.08, 0xc8c6c0)
	window(win, 0xe8e6e0, 0x1f2a33, 2)
	box(win.position.x, win.position.y, -DEEP + 0.12, win.size.x, win.size.y * 0.75, 0.02, "persiana")
	_bars(win)
	var holes: Array = []
	for k in range(2):
		for x in [0.6, 3.0]:
			holes.append(Rect2(x, SLAB + k * FLOOR_H + 0.15, 1.3, 2.2))
	masonry(0.0, L, SLAB, TOP, holes, [], "ladrillo", "ladrillo")
	for k in range(2):
		var y: float = SLAB + k * FLOOR_H + 0.15
		for x in [0.6, 3.0]:
			_balcony_door(x, x + 1.3, y)
			_awning(x - 0.15, x + 1.45, y + 2.55)
		_balcony(0.2, 4.95, y)
	home()

## The bay of the corner on both floors above: it stands out from both fronts round the corner's cut, its wide windows
## with their cream blinds all round over a sill of brick, a white slab under each floor with its wooden soffit, a brick
## band over; capped at the roof.
func _bay() -> void:
	var a0 := _along(C1, K_S, BAY)
	var b0 := _along(S_E, C2, C2.distance_to(S_E) - BAY)
	var a1 := a0 + _out_rc * BAY_OUT
	var b1 := b0 + _out_sv * BAY_OUT
	var p1 := C1 + _miter(_out_rc, _out_ch) * BAY_OUT
	var p2 := C2 + _miter(_out_ch, _out_sv) * BAY_OUT
	var outline: Array = [b1, p2, p1, a1]                                          # (round it as the fronts go: the Salvador's, the cut, Ramón y Cajal's)
	var plan := PackedVector2Array([a0, a1, p1, p2, b1, b0, C2, C1])
	for k in range(3):                                                            # its slabs: under each floor, and its roof
		var y: float = SLAB + k * FLOOR_H
		var ring := Geometry2D.offset_polygon(plan, 0.08, Geometry2D.JOIN_MITER)
		var big: PackedVector2Array = ring[0] if ring.size() > 0 else plan
		flat(big, y, WHITE)
		_flat_down(big, y - 0.175, "sofito" if k < 2 else WHITE)
		for i in range(big.size()):
			var p: Vector2 = big[i]
			var q: Vector2 = big[(i + 1) % big.size()]
			var d := (q - p).normalized()
			quad(Vector3(p.x, y - 0.175, p.y), Vector3(q.x, y - 0.175, q.y), Vector3(q.x, y, q.y), Vector3(p.x, y, p.y), WHITE, Vector3(d.y, 0, -d.x))
	for k in range(2):
		var y0: float = SLAB + k * FLOOR_H
		for i in range(outline.size() - 1):                                       # its three faces: sill wall, windows, band
			var p: Vector2 = outline[i]
			var q: Vector2 = outline[i + 1]
			var ln := face(p, q, 0.0)
			masonry(0.0, ln, y0, y0 + FLOOR_H, [Rect2(0.12, y0 + 0.95, ln - 0.24, 1.35)], [], "ladrillo", "ladrillo")
			_flat_window(Rect2(0.12, y0 + 0.95, ln - 0.24, 1.35), 0.7)
			box(0.08, y0 + 0.9, -0.02, ln - 0.16, 0.05, 0.1, 0xd8d2c4)
			bays += 1
		for side in [[a1, a0], [b0, b1]]:                                         # its ends back to the fronts
			face(side[0], side[1], 0.0)
			masonry(0.0, BAY_OUT, y0, y0 + FLOOR_H, [], [], "ladrillo", "ladrillo")
	home()

## the line halfway between two outward normals, long enough that a front offset by 1 along each meets there
func _miter(n0: Vector2, n1: Vector2) -> Vector2:
	var m := (n0 + n1).normalized()
	return m / maxf(0.4, m.dot(n1))

## the white bands of the slabs along both fronts where there is neither balcony nor bay, and the parapet's coping
func _bands() -> void:
	for f in [[C1, K_S], [S_E, C2]]:
		var L := face(f[0], f[1], 0.0)
		for k in range(2):
			box(-0.02, SLAB + k * FLOOR_H - 0.16, 0.0, L + 0.04, 0.16, 0.12, WHITE)
		box(-0.02, TOP - 0.08, -0.25, L + 0.04, 0.1, 0.4, 0xc9c2b4)
	face(C2, C1, 0.0)
	box(-0.02, TOP - 0.08, -0.25, C1.distance_to(C2) + 0.04, 0.1, 0.4, 0xc9c2b4)
	home()

## The street's signs on the corner (round blue one way, pointing down Ramón y Cajal; no entry but for those who live
## there), and a planter of clipped green at the corner.
func _signs() -> void:
	face(C1, K_S, 0.0)
	box(0.62, 2.2, 0.0, 0.04, 0.04, 0.08, 0x5a5d62)
	slab(oval(0.64, 2.2, 0.22, 0.22, 18), 0.085, 0.0, 0x1b5aa8)
	slab(PackedVector2Array([Vector2(0.5, 2.17), Vector2(0.7, 2.17), Vector2(0.7, 2.1), Vector2(0.82, 2.2), Vector2(0.7, 2.3), Vector2(0.7, 2.23), Vector2(0.5, 2.23)]), 0.088, 0.0, 0xf6f6f2)
	face(C2, C1, 0.0)
	var L := C1.distance_to(C2)
	box(L - 0.32, 2.62, 0.0, 0.45, 0.45, 0.02, 0xf6f6f2)                              # no entry: a red ring on white, its plate
	slab(oval(L - 0.095, 2.845, 0.2, 0.2, 18), 0.022, 0.0, 0xcc2a2a)
	slab(oval(L - 0.095, 2.845, 0.15, 0.15, 18), 0.024, 0.0, 0xf6f6f2)
	box(L - 0.32, 2.42, 0.0, 0.45, 0.16, 0.02, 0xf6f6f2)
	var lb := _text("EXCEPTO RESIDENTES", Vector3(L - 0.095, 2.5, 0.026), 18, 0x1d1e20, 0.0035)
	lb.outline_size = 0
	home()
	var at: Vector2 = (C1 + C2) / 2.0 + _out_ch * 0.75 + (C1 - C2).normalized() * 0.6     # the planter
	var g := ground(at.x, at.y)
	drum(Vector3(at.x, g, at.y), 0.3, 0.36, 0.45, 0x8a8c8e, 14)
	ball(Vector3(at.x, g + 0.62, at.y), 0.34, "seto", 0.8, 10, 6)
	solid(Vector3(at.x, g + 0.4, at.y), Vector3(0.66, 0.8, 0.66))
	yard.append(at)
