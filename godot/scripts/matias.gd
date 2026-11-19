extends "res://scripts/obra.gd"
## The house of the Calle de Matías Pérez (the user, 17 November 2026: "Nuevo proyecto. Matias Pérez 16", with his
## picture of its front from Street View, November 2024), built by hand on Texturas's house of the map (matias_16,
## handed over as ["obra"] in casas_calles.gd); referencias/matias/, tools/matias/.
##
## Two floors of red pressed brick, some of it darker, in a front of 6.9 m (Catastro's; its bricks, 25 cm a piece in his
## picture, give the same):
##   - below, a wide doorway behind two curtains printed with flowers, the house door behind a white curtain, a window
##     behind a cage of white flat bars with its blind half down; over each opening a lintel of bricks on end, and over
##     them all a band of bricks on end along the whole front;
##   - a black cable along the front under the windows above; a little grey box by its east end;
##   - above, two windows (the west one bigger) in raised frames of brick, their white blinds down, a little white railing
##     on a white sill under each;
##   - a cornice of brick courses stepping out under the tiles.
## No house number (the game shows none).
##
## Frame: origin at the front's west end (its left, seen from the street), +x along the front, +z out of it, towards the
## street; y = 0 the pavement before its middle.

const HOUSE := "matias_16"
const TOP := 6.25                   # the eaves (the cornice's top)
const RIDGE := 7.6

var door: Vector2                   # before its door, on the map (the self-test)
var len_front := 6.9
var openings := 0

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"ladrillo":         # red pressed brick, some darker
			m = Tex.mat("brick_wall_006", Color(1.02, 0.9, 0.84))
		"llaga":            # the mortar behind the bricks on end
			m = Tex.mat("granular_concrete", Color(0.78, 0.7, 0.62), false)
		"cortina_flores":   # the wide doorway's curtains: pale, printed with grey-violet flowers, hanging in folds
			m = _cloth(Color(0.9, 0.86, 0.8), true)
		"cortina_blanca":   # the door's curtain
			m = _cloth(Color(0.95, 0.94, 0.9), false)
		"persiana":         # the white blinds of the windows above (rolled down: their slats)
			m = _slats(Color(0.95, 0.95, 0.93), Color(0.78, 0.78, 0.76))
		"persiana_parda":   # the blind behind the bars below: pale brown slats
			m = _slats(Color(0.72, 0.6, 0.46), Color(0.55, 0.45, 0.34))
		_:
			return super(key)
	_mats[key] = m
	return m

## a curtain's cloth: folds (light and shade in columns) and, if `flowers`, a print of little grey-violet flowers
func _cloth(base: Color, flowers: bool) -> StandardMaterial3D:
	var img := Image.create(96, 128, false, Image.FORMAT_RGB8)
	for x in range(96):
		var fold := 0.86 + 0.14 * sin(x / 96.0 * TAU * 6.0)
		for y in range(128):
			img.set_pixel(x, y, base * fold)
	if flowers:
		var rng := RandomNumberGenerator.new()
		rng.seed = 16
		for k in range(46):
			var cx := rng.randi_range(4, 91)
			var cy := rng.randi_range(4, 123)
			var col := Color(0.55, 0.5, 0.66) if k % 3 != 0 else Color(0.48, 0.52, 0.5)
			for p in range(5):                                            # five petals round a middle
				var a := TAU * p / 5.0 + k
				var px := cx + int(round(cos(a) * 2.6))
				var py := cy + int(round(sin(a) * 2.6))
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						var qx := clampi(px + dx, 0, 95)
						var qy := clampi(py + dy, 0, 127)
						var fold := 0.86 + 0.14 * sin(qx / 96.0 * TAU * 6.0)
						img.set_pixel(qx, qy, col * fold)
			img.set_pixel(cx, cy, Color(0.75, 0.7, 0.55))
	var sm := StandardMaterial3D.new()
	sm.albedo_texture = ImageTexture.create_from_image(img)
	sm.roughness = 0.95
	return sm

## a blind's slats: light bands with a darker line between each
func _slats(light: Color, dark: Color) -> StandardMaterial3D:
	var img := Image.create(4, 32, false, Image.FORMAT_RGB8)
	for y in range(32):
		for x in range(4):
			img.set_pixel(x, y, dark if y % 4 == 3 else light)
	var sm := StandardMaterial3D.new()
	sm.albedo_texture = ImageTexture.create_from_image(img)
	sm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	return sm

func build(world, hd: Dictionary) -> void:
	W = world
	var o := Vector2(hd["o"][0], hd["o"][1])
	var u := Vector2(hd["u"][0], hd["u"][1])
	var out := Vector2(-u.y, u.x)
	len_front = float(hd["len"])
	level = MapData.height(o + u * (len_front / 2.0) + out * 1.0)
	transform = Transform3D(Basis(Vector3(u.x, 0, u.y), Vector3.UP, Vector3(out.x, 0, out.y)), Vector3(o.x, level, o.y))
	W.add_child(self)
	var raw: Array = hd["pieces"][0]["ring"]
	var ring: Array = []
	for i in range(0, raw.size(), 2):
		var q: Vector3 = transform.affine_inverse() * Vector3(float(raw[i]), level, float(raw[i + 1]))
		ring.append(Vector2(q.x, q.z))
	_front()
	_body(ring)
	home()
	_commit()
	for part in Geometry2D.decompose_polygon_in_convex(PackedVector2Array(ring)):
		var pts: Array = []
		for q: Vector2 in part:
			pts.append(q)
		_prism(pts, -2.0, TOP)
	door = spot(4.19, 1.2)

## the back and sides of the house (brick, plain), its roof of tiles: a slope from the front's eaves up to a ridge, and
## down to the back
func _body(ring: Array) -> void:
	var back := 0.0
	for q: Vector2 in ring:
		back = minf(back, q.y)
	for i in range(ring.size()):
		var a: Vector2 = ring[i]
		var b: Vector2 = ring[(i + 1) % ring.size()]
		if absf(a.y) < 0.05 and absf(b.y) < 0.05:                       # (the front: built on its own)
			continue
		if a.distance_to(b) < 0.05:
			continue
		_plain(a, b, -3.0, TOP, "ladrillo")
		_plain(b, a, -3.0, TOP, "ladrillo")
	home()
	var depth: float = minf(-back, 12.0)
	var zr := -minf(4.2, depth / 2.0)
	var o := 0.4
	roof([Vector3(-0.02, TOP - 0.1, o), Vector3(len_front + 0.02, TOP - 0.1, o), Vector3(len_front + 0.02, RIDGE, zr), Vector3(-0.02, RIDGE, zr)])
	roof([Vector3(len_front + 0.02, RIDGE, zr), Vector3(-0.02, RIDGE, zr), Vector3(-0.02, TOP - 0.3, -depth), Vector3(len_front + 0.02, TOP - 0.3, -depth)])
	ridge(Vector3(0.0, RIDGE, zr), Vector3(len_front, RIDGE, zr))
	for x in [0.0, len_front]:                                           # (the gables over the neighbours' party walls)
		tri(Vector3(x, TOP - 0.1, 0.0), Vector3(x, RIDGE, zr), Vector3(x, TOP - 0.3, -depth), "ladrillo", Vector3(-1 if x == 0.0 else 1, 0, 0))

# ---------------- the front ----------------
func _front() -> void:
	var L := len_front
	face(Vector2(0, 0), Vector2(L, 0))
	var gate := Rect2(0.35, 0.0, 2.6, 2.2)            # the wide doorway behind the flowered curtains
	var dr := Rect2(3.59, 0.0, 1.2, 2.2)              # the house door behind its white curtain
	var win := Rect2(5.17, 0.55, 1.25, 1.65)          # the window behind white bars
	var up_w := Rect2(1.33, 3.85, 1.35, 1.3)          # the windows above: the west one bigger...
	var up_e := Rect2(4.8, 3.85, 0.95, 1.15)          # ...the east one
	var holes: Array = [gate, dr, win, up_w, up_e]
	masonry(0.0, L, -2.5, TOP, holes, [], "ladrillo")
	box(0.0, -0.6, 0.0, gate.position.x, 0.85, 0.02, 0x9a958c)            # (a foot of cement where the brick meets the pavement)
	box(gate.end.x, -0.6, 0.0, dr.position.x - gate.end.x, 0.85, 0.02, 0x9a958c)
	box(dr.end.x, -0.6, 0.0, L - dr.end.x, 0.85, 0.02, 0x9a958c)
	# the openings below, their lintels of bricks on end
	for r: Rect2 in [gate, dr, win]:
		_sardinel(r.position.x - 0.12, r.end.x + 0.12, 2.2, 0.25)
	_sardinel(0.0, L, 2.75, 0.25)                                         # the band along the whole front
	# the wide doorway: two curtains, parted a little, a dark room behind
	box(gate.position.x, 0.0, -DEEP - 0.6, gate.size.x, gate.size.y, 0.02, 0x2a2420)
	for k in range(2):
		var x0: float = gate.position.x + 0.04 + k * (gate.size.x / 2.0 + 0.02)
		_curtain(Rect2(x0, 0.05, gate.size.x / 2.0 - 0.08, gate.size.y - 0.08), -DEEP + 0.12, "cortina_flores")
	box(gate.position.x, gate.end.y - 0.06, -DEEP + 0.08, gate.size.x, 0.04, 0.04, 0x8a8a86)      # (the curtains' rail)
	openings += 1
	# the door: a white curtain over the doorway
	box(dr.position.x, 0.0, -DEEP - 0.5, dr.size.x, dr.size.y, 0.02, 0x2a2420)
	_curtain(Rect2(dr.position.x + 0.03, 0.04, dr.size.x - 0.06, dr.size.y - 0.07), -DEEP + 0.14, "cortina_blanca")
	box(dr.position.x, 0.0, -DEEP + 0.02, dr.size.x, 0.04, DEEP - 0.02, 0x8a8680)                  # (its threshold)
	openings += 1
	# the window below: its brown blind half down, a cage of white flat bars standing out a little
	window(win, 0x5a4636, 0x2a3640, 0)
	quad(Vector3(win.position.x + 0.05, win.end.y - 0.85, -DEEP + 0.03), Vector3(win.end.x - 0.05, win.end.y - 0.85, -DEEP + 0.03),
		Vector3(win.end.x - 0.05, win.end.y - 0.05, -DEEP + 0.03), Vector3(win.position.x + 0.05, win.end.y - 0.05, -DEEP + 0.03), "persiana_parda", Vector3(0, 0, 1),
		[Vector2(0, 0.85 / 0.32), Vector2(1, 0.85 / 0.32), Vector2(1, 0), Vector2(0, 0)])
	_bars(win)
	box(win.position.x - 0.06, win.position.y - 0.05, 0.0, win.size.x + 0.12, 0.05, 0.08, 0xd8d4cc)
	openings += 1
	# the windows above: raised frames of brick, white blinds down, a white sill and a little white railing on it
	for r: Rect2 in [up_w, up_e]:
		var fr := 0.12
		box(r.position.x - fr, r.position.y - 0.02, 0.0, fr, r.size.y + fr + 0.02, 0.035, "ladrillo")
		box(r.end.x, r.position.y - 0.02, 0.0, fr, r.size.y + fr + 0.02, 0.035, "ladrillo")
		box(r.position.x - fr, r.end.y, 0.0, r.size.x + 2.0 * fr, fr, 0.035, "ladrillo")
		_sardinel(r.position.x - fr, r.end.x + fr, r.end.y + fr, 0.24, 0.05)
		window(r, 0x8a6a4a, 0x2a3640, 0)
		quad(Vector3(r.position.x + 0.05, r.position.y + 0.04, -DEEP + 0.035), Vector3(r.end.x - 0.05, r.position.y + 0.04, -DEEP + 0.035),
			Vector3(r.end.x - 0.05, r.end.y - 0.04, -DEEP + 0.035), Vector3(r.position.x + 0.05, r.end.y - 0.04, -DEEP + 0.035), "persiana", Vector3(0, 0, 1),
			[Vector2(0, r.size.y / 0.32), Vector2(1, r.size.y / 0.32), Vector2(1, 0), Vector2(0, 0)])
		box(r.position.x - 0.18, r.position.y - 0.06, 0.0, r.size.x + 0.36, 0.06, 0.24, 0xeeece6)
		_railing(Rect2(r.position.x - 0.14, r.position.y, r.size.x + 0.28, 0.38), 0.2)
		openings += 1
	# the black cable along the front, its clips; the little grey box by its east end
	var cy := 3.55
	for k in range(8):
		var x0 := L * k / 8.0
		var x1 := L * (k + 1) / 8.0
		bar(Vector3(x0, cy - 0.03 * sin(PI * k / 8.0), 0.03), Vector3(x1, cy - 0.03 * sin(PI * (k + 1) / 8.0), 0.03), 0.025, 0.025, 0x1a1a1c)
	for k in range(1, 8):
		box(L * k / 8.0 - 0.015, cy - 0.04, 0.0, 0.03, 0.06, 0.05, 0x2a2a2c)
	box(L - 0.42, 3.95, 0.0, 0.2, 0.26, 0.1, 0xb8b4aa)
	box(L - 0.4, 3.97, 0.1, 0.16, 0.02, 0.005, 0x8a867e)
	# the cornice: three courses of brick stepping out, under the tiles
	var at := TOP - 0.36
	var outv := 0.0
	for st in [[0.08, 0.05], [0.08, 0.1], [0.1, 0.16]]:
		outv = st[1]
		box(-0.02, at, 0.0, L + 0.04, st[0], outv, "ladrillo")
		at += st[0]
	box(-0.02, at, 0.0, L + 0.04, TOP - at, outv + 0.05, 0x8a5a44)
	home()
	yard.append(spot(0.0, 0.3))
	yard.append(spot(L, 0.3))

## a band of bricks on end (a "sardinel"): each brick a little proud of its mortar, red in three shades
func _sardinel(x0: float, x1: float, y: float, tall: float, proud := 0.02) -> void:
	box(x0, y, 0.0, x1 - x0, tall, proud * 0.5, "llaga")
	var n := maxi(2, int((x1 - x0) / 0.075))
	var cols := [0x9e5a42, 0xb06a4c, 0x8a4c38]
	for i in range(n):
		var a := lerpf(x0, x1, float(i) / n)
		var b := lerpf(x0, x1, float(i + 1) / n)
		box(a + 0.006, y + 0.006, 0.0, b - a - 0.012, tall - 0.012, proud, cols[(i * 7) % 3])

## a curtain in folds hanging in an opening at depth z: a few panels set at angles
func _curtain(r: Rect2, z: float, key) -> void:
	var n := maxi(4, int(r.size.x / 0.12))
	for i in range(n):
		var a := r.position.x + r.size.x * i / n
		var b := r.position.x + r.size.x * (i + 1) / n
		var za := z + (0.03 if i % 2 == 0 else -0.01)
		var zb := z + (-0.01 if i % 2 == 0 else 0.03)
		quad(Vector3(a, r.position.y, za), Vector3(b, r.position.y, zb), Vector3(b, r.end.y, zb), Vector3(a, r.end.y, za), key, Vector3(0, 0, 1),
			[Vector2(float(i) / n, 1), Vector2(float(i + 1) / n, 1), Vector2(float(i + 1) / n, 0), Vector2(float(i) / n, 0)])
	pieces += 1

## the cage of white flat bars before the window below
func _bars(r: Rect2) -> void:
	var out := 0.1
	var x0 := r.position.x - 0.05
	var x1 := r.end.x + 0.05
	var y0 := r.position.y - 0.04
	var y1 := r.end.y + 0.04
	var n := 7
	for i in range(n + 1):
		box(x0 + (x1 - x0) * i / n - 0.02, y0, out - 0.012, 0.04, y1 - y0, 0.012, 0xe8e8e4)
	for y in [y0, y1 - 0.03, (y0 + y1) / 2.0]:
		box(x0, y, out - 0.02, x1 - x0, 0.03, 0.02, 0xe8e8e4)
	for x in [x0, x1 - 0.03]:
		for y in [y0, y1 - 0.03]:
			box(x, y, 0.0, 0.03, 0.03, out, 0xe8e8e4)

## a little railing of white tube on a sill: its rails, its uprights, its returns to the wall
func _railing(r: Rect2, out: float) -> void:
	var x0 := r.position.x
	var x1 := r.end.x
	var y0 := r.position.y
	var y1 := r.end.y
	bar(Vector3(x0, y1, out), Vector3(x1, y1, out), 0.035, 0.035, 0xf2f2ee)
	bar(Vector3(x0, y0 + 0.05, out), Vector3(x1, y0 + 0.05, out), 0.025, 0.025, 0xf2f2ee)
	var n := maxi(3, int((x1 - x0) / 0.11))
	for i in range(n + 1):
		var x := lerpf(x0, x1, float(i) / n)
		bar(Vector3(x, y0, out), Vector3(x, y1, out), 0.018, 0.018, 0xf2f2ee)
	for x in [x0, x1]:
		bar(Vector3(x, y1, 0.0), Vector3(x, y1, out), 0.03, 0.03, 0xf2f2ee)
		bar(Vector3(x, y0 + 0.05, 0.0), Vector3(x, y0 + 0.05, out), 0.02, 0.02, 0xf2f2ee)
