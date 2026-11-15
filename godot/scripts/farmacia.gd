extends "res://scripts/obra.gd"
## The pharmacy of the Calle Real and its two neighbours, built by hand (the user, 15 November 2026: "Siguiente
## edificio. farmacia calle real, y los dos edificios colindantes. Una droguería y una casa de fachada de ladrillo,
## blanca y piedra"; referencias/farmacia_real/, tools/farmacia/).
##
## As Street View has the east side of the street in November 2024, going south to the crossroads with the Calle de
## Colón: a brick house -- white below on a foot of rubble, a balcony of brick above under a jutting roof --; the
## pharmacy, a new block of three floors in cream render, its shop front clad in white with great windows, its upper
## floors out over the pavement at the southern end with terraces behind brown lattice; and on the corner the old
## chemist's-and-perfume shop: big blocks drawn in the plaster below, folding grilles, yellow signs, windows framed in
## terracotta above, a balustrade along the roof.
## Between the pharmacy and the corner the real street has one more house, narrow and old: the user had it left out
## ("Si eliminamos esta casa vieja y pequeña..."), because in the game the Calle de Colón runs three metres further
## north than the real one and the corner shop had lost half its front; it has that house's room now.
##
## Frame: origin at the north end of the brick house's front; +x along the fronts towards the Calle de Colón, +z out
## into the Calle Real; y = 0 the pavement at the street's lowest point in front of the pharmacy.
## The four houses' plots are still the map's (MapData.houses: solid blocks); casas.gd draws nothing for them
## (casas_calles.gd marks them "obra") and this builds their walls and roofs as well as their fronts.
## Signs say what is sold, never the real names; no house wears its number.

const READY := true
const O := Vector2(-61.17, -89.09)
const U := Vector2(-0.1835, 0.9830)
const IDS := {"real_30": [6.5, "cal"], "real_26": [9.5, "crema"], "real_24": [5.72, "cal"], "real_22": [5.72, "cal"]}     # each house: how high its walls go, of what
const X_PH := 5.33                              # where the pharmacy begins...
const X_UP := 15.0                              # ...where its upper floors come out over the pavement...
const X_DR := 23.55                             # ...and where the chemist's begins
const X_CO := 29.38                             # the corner with the Calle de Colón (the map's, not the real one)
const SIDE := Vector2(33.76, -11.2)             # the far end of the chemist's side on Colón
const OUT := 0.6                                # how far the pharmacy's upper floors come out
const PH_TOP := 9.5
const DR := 0.2                                 # the chemist's floor
const BROWN := 0x6a4632
const LATTICE := 0x5a3b2c
const YELLOW := 0xe9d21c
const TERRA := 0xdba878

var door: Vector2               # in front of the pharmacy's door, on the map

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"crema":            # the pharmacy's render
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.97, 0.89, 0.75)), 0.46)
		"panel":            # its shop front: smooth white cladding
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.99, 0.97)), 0.62)
		"cal":              # old lime white gone a little cream
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.99, 0.96, 0.89)), 0.52)
		"junta":            # ...and what shows in the joints of the blocks drawn in it
			m = Tex.mat("painted_plaster_wall", Color(0.78, 0.76, 0.7))
		"rosa":             # the chemist's side on Colón
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.98, 0.91, 0.8)), 0.38)
		"blanco":
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.985, 0.95)), 0.55)
		"ladrillo":         # the red facing brick of the house to the north
			m = Tex.mat("brick_wall_003", Color(1.05, 0.72, 0.6))
		"rubble":
			m = Tex.mat("stone_wall")
		"acera":
			m = W._tmat(0xdcd5c8, "pavement", 2.0)
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	var out := Vector2(-U.y, U.x)
	level = MapData.height(O + U * 18.0)
	transform = Transform3D(Basis(Vector3(U.x, 0, U.y), Vector3.UP, Vector3(out.x, 0, out.y)), Vector3(O.x, level, O.y))
	W.add_child(self)
	door = spot(18.1, 1.0)
	_bodies()
	_brick_house()
	_pharmacy()
	_chemist()
	_pavement()
	home()
	_commit()

# ---------------- what is behind the fronts ----------------
func _two_sided(a: Vector2, b: Vector2, y0: float, y1: float, key) -> void:
	_plain(a, b, y0, y1, key)
	_plain(b, a, y0, y1, key)

func _is_front(a: Vector2, b: Vector2) -> bool:
	if absf(a.y) < 0.3 and absf(b.y) < 0.3:
		return true
	var c := Vector2(X_CO, 0.0)
	var d := (SIDE - c).normalized()
	return absf((a - c).cross(d)) < 0.4 and absf((b - c).cross(d)) < 0.4

## The four plots as the map has them: their walls (all but the fronts) and their flat roofs; and the pharmacy's
## northern half, which Catastro does not have yet (it stands where there was a yard open to the street).
func _bodies() -> void:
	var inv := transform.affine_inverse()
	for hd in MapData.houses:
		var id := String(hd["id"])
		if not IDS.has(id):
			continue
		var top: float = IDS[id][0]
		for pc in hd.get("pieces", []):
			var raw: Array = pc["ring"]
			var ring := PackedVector2Array()
			for i in range(0, raw.size(), 2):
				var q: Vector3 = inv * Vector3(float(raw[i]), level, float(raw[i + 1]))
				ring.append(Vector2(q.x, q.z))
			for i in range(ring.size()):
				var a := ring[i]
				var b := ring[(i + 1) % ring.size()]
				if not _is_front(a, b):
					_two_sided(a, b, -3.0, top, IDS[id][1])
			flat(ring, top, 0xa8674a if id != "real_26" else 0x9a958c)
	var nb := PackedVector2Array([Vector2(X_PH, 0), Vector2(13.51, 0), Vector2(13.51, -11.4), Vector2(9.4, -11.4), Vector2(9.4, -4.15), Vector2(X_PH + 0.1, -4.15)])
	for i in range(1, nb.size()):
		_two_sided(nb[i], nb[(i + 1) % nb.size()], -3.0, PH_TOP, "crema")
	flat(nb, PH_TOP, 0x9a958c)
	solid(Vector3(9.42, 4.0, -2.1), Vector3(8.18, 12.0, 4.1))
	solid(Vector3(11.45, 4.0, -7.75), Vector3(4.1, 12.0, 7.3))
	var pts := PackedVector2Array()
	for q in nb:
		pts.append(spot(q.x, q.y))
		yard.append(spot(q.x, q.y))
	MapData.outlines.append(pts)
	if not MapData._wall_grid.is_empty():
		for i in range(pts.size()):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % pts.size()]
			MapData._grid_add(MapData._wall_grid, a.min(b), a.max(b), [a, b])

## the pavement along the fronts, as the other houses of the street lay theirs
func _pavement() -> void:
	var n := 15
	for i in range(n):
		var xa: float = X_CO * i / n
		var xb: float = X_CO * (i + 1) / n
		var da: float = MapData.road_edge_dist(spot(xa, 0.3)) + 0.3
		var db: float = MapData.road_edge_dist(spot(xb, 0.3)) + 0.3
		if da < 0.5 or db < 0.5:
			continue
		quad(Vector3(xa, ground(xa, 0.0) + 0.03, -0.02), Vector3(xb, ground(xb, 0.0) + 0.03, -0.02), Vector3(xb, ground(xb, db) + 0.03, db), Vector3(xa, ground(xa, da) + 0.03, da), "acera", Vector3.UP)
		quad(Vector3(xa, ground(xa, da) + 0.05, da - 0.2), Vector3(xb, ground(xb, db) + 0.05, db - 0.2), Vector3(xb, ground(xb, db) + 0.05, db + 0.02), Vector3(xa, ground(xa, da) + 0.05, da + 0.02), 0xb9b4a8, Vector3.UP)

# ---------------- little things many fronts share ----------------
## an iron rail on the wall being built: from x0 to x1, between y0 and y1, `z` out
func _rail(x0: float, x1: float, y0: float, y1: float, z: float, hex := IRON) -> void:
	box(x0, y1 - 0.03, z - 0.015, x1 - x0, 0.03, 0.03, hex)
	box(x0, y0, z - 0.012, x1 - x0, 0.024, 0.024, hex)
	var n := maxi(2, int(round((x1 - x0) / 0.12)))
	for i in range(n + 1):
		box(x0 + (x1 - x0) * i / n - 0.009, y0, z - 0.009, 0.018, y1 - y0, 0.018, hex)

## a panel of brown lattice (the pharmacy's balconies), standing on y0
func _lattice(x0: float, x1: float, y0: float, y1: float, z: float) -> void:
	box(x0, y0, z - 0.03, x1 - x0, y1 - y0, 0.03, LATTICE)
	for q in [[x0, y0, 0.05, y1 - y0], [x1 - 0.05, y0, 0.05, y1 - y0], [x0, y1 - 0.05, x1 - x0, 0.05], [x0, y0, x1 - x0, 0.05]]:
		box(q[0], q[1], z - 0.035, q[2], q[3], 0.045, 0x4a3024)
	var n := maxi(2, int(round((x1 - x0) / 0.14)))
	for i in range(1, n):
		box(x0 + (x1 - x0) * i / n - 0.008, y0 + 0.05, z, 0.016, y1 - y0 - 0.1, 0.006, 0x7a5540)
	var m := maxi(2, int(round((y1 - y0) / 0.14)))
	for j in range(1, m):
		box(x0 + 0.05, y0 + (y1 - y0) * j / m - 0.008, z, x1 - x0 - 0.1, 0.016, 0.006, 0x7a5540)

## a roller blind let part of the way down a hole
func _blind(r: Rect2, part: float, hex: int) -> void:
	var h: float = r.size.y * part
	box(r.position.x + 0.03, r.end.y - h, -DEEP + 0.1, r.size.x - 0.06, h, 0.05, hex)
	var n := int(h / 0.07)
	for j in range(1, n):
		box(r.position.x + 0.03, r.end.y - h + j * 0.07, -DEEP + 0.15, r.size.x - 0.06, 0.008, 0.004, Parts.col(hex).darkened(0.18).to_rgba32() >> 8)

## what shows in a shop window: the lit back of the shop, shelves, rows of little boxes and bottles
func _display(r: Rect2) -> void:
	box(r.position.x, r.position.y, -DEEP - 0.02, r.size.x, r.size.y, 0.03, 0xefe9dc)
	var rows := maxi(2, int(r.size.y / 0.45))
	var tints := [0xfdfcf8, 0x6fb0e0, 0x8fd0a0, 0xf2b05a, 0xfdfcf8, 0xe890a8, 0xf4e08a, 0x9ab0d8]
	for j in range(rows):
		var y: float = r.position.y + 0.14 + j * (r.size.y - 0.25) / rows
		box(r.position.x + 0.06, y, -DEEP + 0.02, r.size.x - 0.12, 0.03, 0.2, 0xf8f6f0)
		var n := int((r.size.x - 0.24) / 0.17)
		for i in range(n):
			var hh: float = 0.13 + 0.07 * ((i * 7 + j * 3) % 3)
			box(r.position.x + 0.12 + i * 0.17, y + 0.03, -DEEP + 0.06, 0.12, hh, 0.1, tints[(i * 3 + j * 2) % tints.size()])
	for q in [[r.position.x, r.position.y, 0.05, r.size.y], [r.end.x - 0.05, r.position.y, 0.05, r.size.y], [r.position.x, r.end.y - 0.05, r.size.x, 0.05], [r.position.x, r.position.y, r.size.x, 0.05]]:
		box(q[0], q[1], -0.07, q[2], q[3], 0.05, 0xd9dde0)

## Big blocks drawn in the plaster of a ground floor, from x0 to x1 and y0 to y1, leaving the holes of `skip` alone.
func _blocks(x0: float, x1: float, y0: float, y1: float, skip: Array, key) -> void:
	var rows := maxi(1, int(round((y1 - y0) / 0.42)))
	var hh: float = (y1 - y0) / rows
	for j in range(rows):
		var ya: float = y0 + j * hh
		var free: Array = [Vector2(x0, x1)]
		for r: Rect2 in skip:
			if r.position.y < ya + hh - 0.02 and r.end.y > ya + 0.02:
				var next: Array = []
				for f: Vector2 in free:
					if r.end.x <= f.x or r.position.x >= f.y:
						next.append(f)
					else:
						if r.position.x - f.x > 0.1:
							next.append(Vector2(f.x, r.position.x))
						if f.y - r.end.x > 0.1:
							next.append(Vector2(r.end.x, f.y))
				free = next
		for f: Vector2 in free:
			var n := maxi(1, int(round((f.y - f.x) / 0.85)))
			var ww: float = (f.y - f.x) / n
			for i in range(n):
				box(f.x + i * ww + 0.012, ya + 0.012, 0.0, ww - 0.024, hh - 0.024, 0.045, key)

## a folding grille drawn shut across a shop's opening, and the dark of the shop behind it
func _scissor(r: Rect2) -> void:
	box(r.position.x, r.position.y, -DEEP - 0.02, r.size.x, r.size.y, 0.03, 0x39443f)
	box(r.position.x + 0.1, r.position.y, -DEEP + 0.02, r.size.x - 0.2, r.size.y * 0.8, 0.02, 0x8fa08a)          # a faded green curtain inside
	var z := -0.12
	var n := maxi(4, int(round(r.size.x / 0.11)))
	for i in range(n + 1):
		box(r.position.x + r.size.x * i / n - 0.009, r.position.y, z - 0.009, 0.018, r.size.y, 0.018, 0x3a3c3e)
	for j in range(3):
		var y0: float = r.position.y + r.size.y * (0.12 + 0.3 * j)
		var y1: float = y0 + r.size.y * 0.16
		for i in range(n):
			var xa: float = r.position.x + r.size.x * i / n
			var xb: float = r.position.x + r.size.x * (i + 1) / n
			bar(Vector3(xa, y0 if i % 2 == 0 else y1, z), Vector3(xb, y1 if i % 2 == 0 else y0, z), 0.012, 0.012, 0x3a3c3e)
	box(r.position.x - 0.02, r.end.y - 0.07, z - 0.03, r.size.x + 0.04, 0.07, 0.06, 0x3a3c3e)

## a painted board with a word on it (what the shop sells), on the wall being built
func _sign(x: float, y: float, w: float, h: float, words: String, pixel := 0.0062) -> void:
	box(x, y, 0.0, w, h, 0.07, YELLOW)
	box(x - 0.02, y - 0.02, 0.0, w + 0.04, h + 0.04, 0.05, 0xf4f2ec)
	_text(words, Vector3(x + w / 2.0, y + h / 2.0, 0.085), 64, 0x1c1c1e, pixel)

## a window framed in terracotta with its cane blind down and its little iron balcony (the chemist's upper floor)
func _framed(r: Rect2) -> void:
	for q in [[r.position.x - 0.17, r.position.y - 0.17, 0.17, r.size.y + 0.34], [r.end.x, r.position.y - 0.17, 0.17, r.size.y + 0.34],
			[r.position.x - 0.17, r.end.y, r.size.x + 0.34, 0.17], [r.position.x - 0.17, r.position.y - 0.17, r.size.x + 0.34, 0.17]]:
		box(q[0], q[1], 0.0, q[2], q[3], 0.035, TERRA)
	window(r, 0x8a8478, 0x39566a, 1)
	_blind(r, 0.86, 0xe6dfc8)
	_rail(r.position.x - 0.05, r.end.x + 0.05, r.position.y - 0.1, r.position.y + 0.32, 0.16)
	box(r.position.x - 0.05, r.position.y - 0.12, 0.0, r.size.x + 0.1, 0.03, 0.17, IRON)

## The moulded cornice and the balustrade on top of it, along the wall being built from x0 to x1; `y`: the cornice's top.
func _balustrade(x0: float, x1: float, y: float) -> void:
	cornice(x0, x1, y, true, 0xe9c9a8, 1.25)
	box(x0, y, 0.0, x1 - x0, 0.09, 0.2, 0xf1ece0)
	var n := maxi(2, int(round((x1 - x0) / 0.24)))
	for i in range(n):
		var x: float = x0 + (x1 - x0) * (i + 0.5) / n
		if i % 11 == 0:
			box(x - 0.11, y + 0.09, 0.02, 0.22, 0.47, 0.16, 0xf1ece0)          # a little pier now and then
		else:
			box(x - 0.03, y + 0.09, 0.07, 0.06, 0.47, 0.06, 0xf1ece0)
			box(x - 0.055, y + 0.2, 0.045, 0.11, 0.17, 0.11, 0xf1ece0)
	box(x0, y + 0.56, 0.0, x1 - x0, 0.1, 0.2, 0xf1ece0)

# ---------------- the brick house ----------------
func _brick_house() -> void:
	var w := X_PH
	var yb: float = ground(w / 2.0, 0.3)
	face(Vector2(0, 0), Vector2(w, 0), yb)
	var win := Rect2(1.97, 0.85, 1.47, 1.2)
	var dr := Rect2(3.69, 0.0, 0.92, 2.3)
	var up := Rect2(2.03, 3.0, 2.77, 2.0)
	masonry(0.0, w, -1.2, 6.3, [win, dr, up], [Rect2(0, 2.8, w, 3.5)], "blanco", "ladrillo")
	box(0.0, -1.2, 0.0, dr.position.x - 0.05, 1.9, 0.05, "rubble")                 # the foot of rubble
	box(dr.end.x + 0.05, -1.2, 0.0, w - dr.end.x - 0.05, 1.9, 0.05, "rubble")
	window(win, 0xf1f0ea, 0x39566a, 1)
	grille(win, 0.14, 0x1c1c1e)
	box(dr.position.x, 0.0, -DEEP, dr.size.x, dr.size.y, 0.03, 0x3a2a20)
	for i in range(9):                              # its door curtain, in a brown pattern
		box(dr.position.x + 0.02 + i * (dr.size.x - 0.04) / 9.0, 0.03, -0.1, (dr.size.x - 0.04) / 9.0 - 0.01, dr.size.y - 0.08, 0.02, 0x8a5a48 if i % 2 == 0 else 0xcbb8a0)
	box(up.position.x, up.position.y, -DEEP, up.size.x, up.size.y, 0.03, 0x39566a)
	for q in [[up.position.x + 0.04, 1.8], [up.position.x + 1.88, 0.85]]:           # two white blinds, down
		var r := Rect2(q[0], up.position.y, q[1], up.size.y)
		_blind(r, 0.97, 0xf1f0ea)
	# the balcony: a box of brick out over the street, an iron rail on it
	var b0 := 1.6
	var deep := 0.75
	box(b0, 2.68, 0.0, w - b0, 0.12, deep + 0.05, 0xefeae0)
	box(b0, 2.8, deep - 0.12, w - b0, 0.95, 0.12, "ladrillo")
	box(b0, 2.8, 0.0, 0.12, 0.95, deep - 0.12, "ladrillo")
	box(w - 0.12, 2.8, 0.0, 0.12, 0.95, deep - 0.12, "ladrillo")
	_rail(b0 + 0.04, w - 0.04, 3.75, 4.15, deep - 0.06)
	box(2.0, 5.12, 0.0, 2.9, 0.16, 0.24, 0x2f7a4a)                                  # the awning, rolled up
	for i in range(6):
		box(2.05 + i * 0.5, 5.11, 0.0, 0.12, 0.18, 0.25, 0xf1eee2)
	# the roof: a slab out over the balcony, its edge of brick
	box(-0.05, 6.0, 0.0, w + 0.05, 0.14, 0.95, 0xefeae0)
	box(-0.05, 6.14, 0.0, w + 0.05, 0.3, 0.98, "ladrillo")
	box(w - 0.16, 0.2, 0.0, 0.09, 5.8, 0.09, 0xe8e6e0)                              # a downpipe at the party wall
	home()
	yard.append(spot(0.0, 0.0))

# ---------------- the pharmacy ----------------
func _pharmacy() -> void:
	var ln: float = X_DR - X_PH
	# --- its ground floor, one wall from end to end: cream to the north, with the way up to the flats; then the shop ---
	face(Vector2(X_PH, 0), Vector2(X_DR, 0))
	var clad := 12.45 - X_PH                        # where the white cladding begins
	var studded := Rect2(10.35 - X_PH, 0.0, 1.3, 2.35)
	var atm := Rect2(12.9 - X_PH, 0.55, 0.95, 1.85)
	var shop := Rect2(14.2 - X_PH, 0.55, 1.9, 1.85)
	var way_in := Rect2(16.9 - X_PH, 0.0, 2.4, 2.45)
	var big := Rect2(19.9 - X_PH, 0.55, 3.1, 1.9)
	masonry(0.0, ln, -1.2, 3.05, [studded, atm, shop, way_in, big], [Rect2(clad, -1.2, ln - clad, 4.25)], "crema", "panel")
	box(0.0, -1.2, 0.0, studded.position.x - 0.12, 1.7, 0.03, 0xd9c9a6)            # a foot of cream stone under the render
	box(studded.end.x + 0.12, -1.2, 0.0, clad - studded.end.x - 0.12, 1.7, 0.03, 0xd9c9a6)
	# the door to the flats: dark wood, studded, a cross on it
	box(studded.position.x, 0.0, -DEEP, studded.size.x, studded.size.y, 0.06, 0x4a2c1c)
	for q in [[studded.position.x - 0.1, 0.0, 0.1, studded.size.y + 0.1], [studded.end.x, 0.0, 0.1, studded.size.y + 0.1], [studded.position.x - 0.1, studded.size.y, studded.size.x + 0.2, 0.1]]:
		box(q[0], q[1], -0.2, q[2], q[3], 0.22, 0x3a2216)
	for s in [0, 1]:
		var x0: float = studded.position.x + 0.06 + s * (studded.size.x / 2.0)
		for j in range(3):
			box(x0, 0.12 + j * 0.74, -DEEP + 0.06, studded.size.x / 2.0 - 0.12, 0.62, 0.025, 0x5a3622)
		for j in range(7):
			for i in range(2):
				box(x0 + 0.06 + i * (studded.size.x / 2.0 - 0.28), 0.2 + j * 0.31, -DEEP + 0.085, 0.045, 0.045, 0.02, 0xb9a070)
	box(studded.position.x + studded.size.x / 2.0 - 0.02, 1.25, -DEEP + 0.09, 0.04, 0.5, 0.02, 0xb9a070)
	box(studded.position.x + studded.size.x / 2.0 - 0.15, 1.55, -DEEP + 0.09, 0.3, 0.04, 0.02, 0xb9a070)
	# the shop's windows
	_display(shop)
	_display(big)
	box(atm.position.x, atm.position.y, -DEEP - 0.02, atm.size.x, atm.size.y, 0.03, 0xdfe6e8)
	box(atm.position.x + 0.22, atm.position.y + 0.25, -DEEP + 0.02, 0.5, 1.15, 0.22, 0xe9eaec)        # the machine that sells at night
	box(atm.position.x + 0.28, atm.position.y + 0.95, -DEEP + 0.24, 0.38, 0.3, 0.01, 0x2a3a4a)
	box(atm.position.x + 0.3, atm.position.y + 0.5, -DEEP + 0.24, 0.34, 0.2, 0.01, 0x8a8f96)
	# the way in: set back, two glass leaves in blue frames, a chequered floor
	var inn := 1.0
	var a := way_in.position.x
	var b := way_in.end.x
	quad(Vector3(a, 0, -inn), Vector3(b, 0, -inn), Vector3(b, way_in.end.y, -inn), Vector3(a, way_in.end.y, -inn), 0x2a3640, Vector3(0, 0, 1))
	quad(Vector3(a, 0, -inn), Vector3(a, 0, -DEEP), Vector3(a, way_in.end.y, -DEEP), Vector3(a, way_in.end.y, -inn), "panel", Vector3(1, 0, 0))
	quad(Vector3(b, 0, -inn), Vector3(b, 0, -DEEP), Vector3(b, way_in.end.y, -DEEP), Vector3(b, way_in.end.y, -inn), "panel", Vector3(-1, 0, 0))
	quad(Vector3(a, way_in.end.y, -inn), Vector3(b, way_in.end.y, -inn), Vector3(b, way_in.end.y, -DEEP), Vector3(a, way_in.end.y, -DEEP), "panel", Vector3(0, -1, 0))
	for i in range(6):
		for j in range(3):
			box(a + i * 0.4, 0.0, -inn + j * 0.4 - 0.2, 0.4, 0.035, 0.4, 0xb5553f if (i + j) % 2 == 0 else 0xe9e4d8)
	for q in [a + 0.02, a + 0.62, a + 1.2, a + 1.78, b - 0.08]:
		box(q, 0.0, -inn + 0.02, 0.06, way_in.end.y - 0.02, 0.06, 0x2a62c8)
	box(a, way_in.end.y - 0.3, -inn + 0.02, way_in.size.x, 0.06, 0.06, 0x2a62c8)
	box(a + 0.08, 0.1, -inn + 0.03, 0.54, 2.0, 0.02, 0xe07a2a)                      # a poster in the fixed pane
	box(a + 0.68, 0.0, -inn + 0.03, 1.1, 2.1, 0.015, 0x55707f)
	# its name: only what it is
	_text("FARMACIA", Vector3(18.1 - X_PH, 2.73, 0.02), 64, 0x6f8090, 0.0072)
	box(19.42 - X_PH, 1.0, 0.0, 0.36, 0.5, 0.02, 0xfdfcf8)                           # a white board by the door, a green cross on it
	box(19.57 - X_PH, 1.08, 0.02, 0.06, 0.34, 0.006, 0x1f9a4a)
	box(19.46 - X_PH, 1.22, 0.02, 0.28, 0.06, 0.006, 0x1f9a4a)
	# the dark strip under the floors that come out, with its lamps
	box(X_UP - X_PH, 3.0, 0.0, X_DR - X_UP, 0.1, OUT + 0.02, 0x4a3628)
	for i in range(7):
		box(X_UP - X_PH + 0.7 + i * 1.15, 2.9, OUT - 0.2, 0.14, 0.1, 0.14, 0x2a2a2c)
	# --- the two floors above the northern half: flush with the street ---
	var up_n: float = X_UP - X_PH
	var holes: Array = []
	var small: Array = []
	var tall: Array = []
	var stair: Array = []
	for f in range(2):
		var y: float = 3.38 + f * 2.93
		stair.append(Rect2(0.52, y - 0.05, 0.92, 2.45))
		for q in [10.4, 11.4]:
			small.append(Rect2(q - X_PH, y + 1.1, 0.62, 1.05))
		for q in [12.55, 13.8]:
			tall.append(Rect2(q - X_PH, y, 1.0, 2.15))
	holes.append_array(stair); holes.append_array(small); holes.append_array(tall)
	masonry(0.0, up_n, 3.05, PH_TOP, holes, [], "crema")
	for r: Rect2 in stair:
		window(r, BROWN, 0x8fa3a8, 0)
	for r: Rect2 in small:
		window(r, BROWN, 0x39566a, 0)
		_blind(r, 0.4, BROWN)
	for r: Rect2 in tall:
		window(r, BROWN, 0x4f7fb0, 0)
		_lattice(r.position.x - 0.03, r.end.x + 0.03, r.position.y - 0.03, r.position.y + 0.95, 0.05)
	box(0.0, PH_TOP, -0.25, up_n, 0.12, 0.3, 0xe6d6ba)                              # the coping
	home()
	# --- the two floors above the shop: out over the pavement, a window and then the terraces ---
	face(Vector2(X_UP, OUT), Vector2(X_DR, OUT))
	var up_s: float = X_DR - X_UP
	var french: Array = []
	var bays: Array = []
	for f in range(2):
		var y: float = 3.42 + f * 2.93
		french.append(Rect2(16.3 - X_UP, y, 1.4, 2.25))
		bays.append(Rect2(18.96 - X_UP, y, 4.32, 2.5))
	var both: Array = french.duplicate()
	both.append_array(bays)
	masonry(0.0, up_s, 3.1, PH_TOP, both, [], "crema")
	for r: Rect2 in french:
		window(r, BROWN, 0x39566a, 0)
		_blind(r, 0.55, BROWN)
		_lattice(r.position.x - 0.03, r.end.x + 0.03, r.position.y - 0.03, r.position.y + 0.95, 0.05)
	var back := -1.45                               # how far in the terraces go
	for r: Rect2 in bays:
		var x0 := r.position.x
		var x1 := r.end.x
		quad(Vector3(x0, r.position.y, back), Vector3(x1, r.position.y, back), Vector3(x1, r.end.y, back), Vector3(x0, r.end.y, back), "crema", Vector3(0, 0, 1))
		quad(Vector3(x0, r.position.y, back), Vector3(x0, r.position.y, -DEEP), Vector3(x0, r.end.y, -DEEP), Vector3(x0, r.end.y, back), "crema", Vector3(1, 0, 0))
		quad(Vector3(x1, r.position.y, back), Vector3(x1, r.position.y, -DEEP), Vector3(x1, r.end.y, -DEEP), Vector3(x1, r.end.y, back), "crema", Vector3(-1, 0, 0))
		quad(Vector3(x0, r.end.y, back), Vector3(x1, r.end.y, back), Vector3(x1, r.end.y, -DEEP), Vector3(x0, r.end.y, -DEEP), "crema", Vector3(0, -1, 0))
		quad(Vector3(x0, r.position.y, back), Vector3(x1, r.position.y, back), Vector3(x1, r.position.y, -DEEP), Vector3(x0, r.position.y, -DEEP), 0xb9a58c, Vector3(0, 1, 0))
		box(x0 + 1.15, r.position.y, back, 1.85, 1.95, 0.05, BROWN)                 # the shutter of its door, down
		for j in range(1, 24):
			box(x0 + 1.15, r.position.y + j * 0.08, back + 0.05, 1.85, 0.008, 0.004, 0x553626)
		_lattice(x0, x1, r.position.y, r.position.y + 0.98, 0.0)
	box(0.0, PH_TOP, -OUT - 0.25, up_s, 0.12, OUT + 0.3, 0xe6d6ba)
	quad(Vector3(0, PH_TOP, -OUT), Vector3(up_s, PH_TOP, -OUT), Vector3(up_s, PH_TOP, 0), Vector3(0, PH_TOP, 0), 0x9a958c, Vector3.UP)
	home()
	_two_sided(Vector2(X_UP, 0.0), Vector2(X_UP, OUT), 3.1, PH_TOP, "crema")       # the cheeks of what comes out
	_two_sided(Vector2(X_DR, 0.0), Vector2(X_DR, OUT), 3.1, PH_TOP, "crema")
	_two_sided(Vector2(X_DR, 0.0), Vector2(X_DR, -4.0), 5.5, PH_TOP, "crema")      # what shows of its side over the chemist's roof
	# the green cross, out from the wall on its arm
	box(X_DR - 0.5, 5.25, OUT, 0.06, 0.06, 1.0, 0x2a2a2c)
	for q in [[0.3, 0.95], [0.95, 0.3]]:
		box(X_DR - 0.52, 5.3 - q[1] / 2.0, OUT + 0.95 - q[0] / 2.0, 0.1, q[1], q[0], 0x1fa84a)
		box(X_DR - 0.535, 5.3 - q[1] / 2.0 + 0.05, OUT + 0.95 - q[0] / 2.0 + 0.05, 0.13, q[1] - 0.1, q[0] - 0.1, 0x7fe08a)
	yard.append(spot(X_PH, 0.0))
	yard.append(spot(X_DR, 0.0))

# ---------------- the chemist's on the corner ----------------
func _chemist() -> void:
	var w: float = X_CO - X_DR
	var eaves := 5.3                                # the cornice's top, over its floor
	# --- on the Calle Real: its house door, then the shop behind its grille ---
	face(Vector2(X_DR, 0), Vector2(X_CO, 0), DR)
	var dr := Rect2(0.38, 0.0, 1.05, 2.3)
	var shop := Rect2(1.95, 0.0, 3.3, 2.3)
	var up := Rect2(2.95, 3.35, 1.25, 1.0)
	masonry(0.0, w, -1.5, eaves, [dr, shop, up], [Rect2(0, -1.5, w, 4.25)], "cal", "junta")
	_blocks(0.0, w - 0.3, 0.0, 2.72, [dr, shop], "blanco")
	box(0.0, -1.5, 0.0, w - 0.3, 1.5, 0.045, "blanco")
	box(-0.02, 2.72, 0.0, w + 0.04, 0.07, 0.1, "blanco")                            # the shelf over the blocks
	box(-0.02, 2.79, 0.0, w + 0.04, 0.05, 0.06, "blanco")
	box(dr.position.x, 0.0, -DEEP, dr.size.x, dr.size.y, 0.05, 0xa8733a)           # the door: two leaves of varnished wood, panelled
	box(dr.position.x + dr.size.x / 2.0 - 0.012, 0.0, -DEEP + 0.05, 0.024, dr.size.y, 0.012, 0x6a4420)
	for s in [0, 1]:
		for j in range(4):
			box(dr.position.x + 0.07 + s * dr.size.x / 2.0, 0.12 + j * 0.54, -DEEP + 0.05, dr.size.x / 2.0 - 0.14, 0.44, 0.02, 0xc08a48 if j != 1 else 0xb57c3c)
	_scissor(shop)
	_sign(2.05, 2.9, 3.0, 0.5, "Droguería")
	_framed(up)
	box(0.55, 3.25, 0.0, 0.5, 0.3, 0.02, 0xf4f2ec)                                  # the street's name on its tile
	_text("Calle\nReal", Vector3(0.8, 3.4, 0.03), 32, 0x2a3a6a, 0.003)
	_balustrade(0.0, w, eaves)
	home()
	# the round pillar of the corner
	var keep := _xf
	_xf = Transform3D(Basis(), Vector3(X_CO - 0.16, DR - 1.5, -0.14))
	drum(Vector3.ZERO, 0.3, 0.3, 4.22, "blanco", 12)
	for j in range(7):
		drum(Vector3(0, 1.5 + j * 0.39 - 0.012, 0), 0.305, 0.305, 0.024, "junta", 12)
	_xf = keep
	# --- on the Calle de Colón, which climbs: the shop's other window, then the house ---
	var c := Vector2(X_CO, 0.0)
	var ls: float = face(c, SIDE, DR)
	var d := (SIDE - c) / ls
	var nrm := Vector2(-d.y, d.x)
	var rise := func(x: float) -> float:              # the street over the shop's floor, along this wall
		var q: Vector2 = c + d * x + nrm * 0.4
		return ground(q.x, q.y) - DR
	var shop2 := Rect2(0.5, 0.95, 3.7, 1.35)
	var blocks := Rect2(6.5, float(rise.call(6.8)) + 0.95, 0.66, 0.95)
	var dr2 := Rect2(10.2, float(rise.call(10.75)), 1.1, 2.15)
	var ups: Array = [Rect2(1.75, 3.35, 1.25, 1.0), Rect2(5.0, 3.35, 1.25, 1.0), Rect2(8.1, 3.35, 1.25, 1.0)]
	var all: Array = [shop2, blocks, dr2]
	all.append_array(ups)
	masonry(0.0, ls, -1.5, eaves, all, [Rect2(0, -1.5, 5.0, 4.25)], "rosa", "junta")
	_blocks(0.3, 5.0, 0.0, 2.72, [shop2], "blanco")
	box(0.3, -1.5, 0.0, 4.7, 1.5, 0.045, "blanco")
	box(0.0, 2.72, 0.0, 5.05, 0.07, 0.1, "blanco")
	box(0.0, 2.79, 0.0, 5.05, 0.05, 0.06, "blanco")
	_scissor(shop2)
	_sign(1.0, 2.9, 2.7, 0.46, "Perfumería", 0.0054)
	for i in range(7):                              # the terracotta foot of the house, stepping up with the street
		var x0: float = 5.0 + i * (ls - 5.0) / 7.0
		var x1: float = 5.0 + (i + 1) * (ls - 5.0) / 7.0
		if x1 > dr2.position.x - 0.16 and x0 < dr2.end.x + 0.16:
			continue
		box(x0, -1.5, 0.0, x1 - x0, float(rise.call((x0 + x1) / 2.0)) + 0.9 + 1.5, 0.03, 0xc98a6a)
	for q in [[blocks.position.x - 0.15, blocks.position.y - 0.15, 0.15, blocks.size.y + 0.3], [blocks.end.x, blocks.position.y - 0.15, 0.15, blocks.size.y + 0.3],
			[blocks.position.x - 0.15, blocks.end.y, blocks.size.x + 0.3, 0.15], [blocks.position.x - 0.15, blocks.position.y - 0.15, blocks.size.x + 0.3, 0.15]]:
		box(q[0], q[1], 0.0, q[2], q[3], 0.04, TERRA)
	box(blocks.position.x, blocks.position.y, -0.12, blocks.size.x, blocks.size.y, 0.06, 0xbfd3d0)       # a window of glass blocks
	for i in range(1, 4):
		box(blocks.position.x + i * blocks.size.x / 4.0 - 0.008, blocks.position.y, -0.06, 0.016, blocks.size.y, 0.006, 0x8fa5a2)
	for j in range(1, 6):
		box(blocks.position.x, blocks.position.y + j * blocks.size.y / 6.0 - 0.008, -0.06, blocks.size.x, 0.016, 0.006, 0x8fa5a2)
	for q in [[dr2.position.x - 0.15, dr2.position.y, 0.15, dr2.size.y + 0.15], [dr2.end.x, dr2.position.y, 0.15, dr2.size.y + 0.15], [dr2.position.x - 0.15, dr2.end.y, dr2.size.x + 0.3, 0.15]]:
		box(q[0], q[1], 0.0, q[2], q[3], 0.04, TERRA)
	box(dr2.position.x, dr2.position.y, -DEEP, dr2.size.x, dr2.size.y, 0.05, 0x7a4a26)
	for j in range(4):
		box(dr2.position.x + 0.1, dr2.position.y + 0.14 + j * 0.5, -DEEP + 0.05, dr2.size.x - 0.2, 0.4, 0.02, 0x8a5830)
	for r: Rect2 in ups:
		_framed(r)
	_balustrade(0.0, ls, eaves)
	box(7.5, 0.9, 0.0, 0.08, eaves - 1.3, 0.08, 0xe8e6e0)                          # a downpipe
	home()
	# the sign that hangs out from the corner, its letters one under another
	var board := Vector3(X_CO - 0.9, DR + 2.95, 0.05)
	box(board.x, board.y, board.z, 0.09, 2.7, 0.6, YELLOW)
	for s in [-1.0, 1.0]:
		var l := _text("D\nR\nO\nG\nU\nE\nR\nÍ\nA", Vector3.ZERO, 48, 0x1c1c1e, 0.0046)
		l.double_sided = false
		l.line_spacing = -6.0
		l.transform = Transform3D(Basis(Vector3.UP, s * PI / 2.0), Vector3(board.x + 0.045 + s * 0.05, board.y + 1.35, board.z + 0.3))
	yard.append(spot(X_CO, 0.0))
	yard.append(spot(SIDE.x, SIDE.y))
