extends "res://scripts/obra.gd"
## The people's university of the Calle de los Arcos -- "Universidad Comunal" in the game -- and the stationer's beside
## it -- "Papelería Rocas" -- built by hand, together (the user, 16 November 2026: "La Universidad Popular (que
## llamaremos Universidad Comunal) y la Papelería Arcos (que llamaremos Papelería Flechas). Son dos edificios que están
## pegados, así mejor hacerlos juntos"; referencias/universidad_comunal/, tools/comunal/).
##
## As Street View has it in November 2024: an old school of one tall floor in orange-tan brick under a roof of old
## tiles, set back three metres behind a low wall of golden rubble with a hedge of ivy on it. In the middle of that
## wall, on the street, a porch of two brick pillars under its own tiled roof carries the white board with its name in
## red, over an iron gate of two leaves; a notice board on two red posts stands beside it on the pavement, and a road
## sign with its mirror before the hedge. Behind, the front: five tall white windows each side of the door, the last
## one behind a wooden shutter, the old tiled plate of the schools over one of them, a saw-tooth cornice, a chimney.
## Against its south end, on the street line, the stationer's: three metres of white front, all of it a round arch shut
## by a mesh of wire with the shop window behind, a band of brick, a balcony with its pots before a wooden door, eaves
## on wooden brackets, and its green sign hanging out over the pavement. Its plot runs through to the Calle Cervantes,
## where it is three floors of bare brick nobody finished: built so.
##
## They are the houses `arcos_10`, `arcos_10t` (the garden wall) and `arcos_12` of the map (casas_calles.gd marks them
## "obra": casas.gd draws nothing of them). Frame: that of `arcos_10` -- origin at the south end of the university's
## front, +x along it northwards, +z out of it towards the street (east); y = 0 the pavement before the porch. The
## street falls southwards: the garden wall follows the ground, and the stationer's stands on its own.
## The names are the user's. The old plate says only "ESCUELAS NACIONALES" (the real one goes on to a man's name).
## The stationer's was first "Flechas"; on seeing it the user: "Cámbiale el nombre a Papelería Rocas y ponle este horario
## comercial" -- Monday to Friday 10 to 2 and 5:30 to 9, Saturday 10 to 2, Sunday shut -- "Además necesitamos que parezca
## que se puede pasar, ahora mismo hay una pared que bloquea y no da esa impresión". So: shut, its mesh of wire is down
## over the arch; open, the arch is an open doorway on to the whole shop -- its floor running in from the pavement,
## shelves down both walls, the counter at the far end, its lamps lit. (Nobody goes in yet, there or at the
## university, whose gate is shut: the fronts are still solid.)

const HOUSE := "arcos_10"
const WALL := "arcos_10t"
const SHOP := "arcos_12"
const NAME := "UNIVERSIDAD COMUNAL"
const SHOP_NAME := "Rocas"
const MORNING := Vector2(10.0, 14.0)            # the stationer's hours: Monday to Saturday in the morning...
const EVENING := Vector2(17.5, 21.0)            # ...and Monday to Friday in the evening; Sunday shut
const PLATE := "ESCUELAS\nNACIONALES"
const EAVE := 4.1                               # the top of the university's walls
const RIDGE := 6.2
const DEPTH := 7.2                              # its main body, front to back
const SILL := 1.27                              # its windows
const HEAD := 3.14
const WW := 1.1
const NORTH: Array = [12.18, 13.7, 15.25, 16.87, 18.48]      # its windows north of the door: their middles (those south of it mirror them)
const DOOR_X := 9.93
const P0 := 6.25                                # the porch, on the street: from...
const P1 := 10.58                               # ...to
const PILLAR := 0.65
const PORCH := 4.25                             # the top of its pillars
const SHOP_TOP := 6.5                           # the stationer's walls, over its own pavement
const BACK_TOP := 9.3                           # the bare block on the Calle Cervantes, over its ground
const DOWN := -4.0                              # well under any ground
const WHITE := 0xf4f3ee
const GLASS := 0x2c3640
const GATE := 0x8a5a50
const RED := 0x8a1c2c
const GREEN := 0x2f7a44
const WOOD := 0x7a4a2a
const RocasS = preload("res://scripts/rocas.gd")

var len_front := 19.87
var door: Vector2               # before the porch's gate, on the map
var shop_door: Vector2          # before the stationer's arch, on the map
var has_shop := false
var is_open := false            # the stationer's
var tienda                      # its inside, a set built apart (rocas.gd): what you go into from its door
var _shut: Node3D               # what shows only while it is shut: the mesh of wire down over its arch
var _open: Node3D               # what shows only while it is open: its lamp lit
var _lights: Array = []
var _arch := {}                 # the arch's measures and the frame it was built in, kept for those two

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"ladrillo":         # orange-tan brick
			m = Tex.mat("brick_wall_003@1.15", Color(1.02, 0.9, 0.82))
		"tosco":            # the bare red brick of what nobody finished
			m = Tex.mat("medieval_red_brick", Color(1.0, 0.82, 0.74))
		"rubble":           # the golden rubble of the garden wall
			m = Tex.mat("stone_wall", Color(1.38, 1.16, 0.84))
		"blanco":
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.1, 1.09, 1.04)), 0.45)
		"tiles":            # old tiles, gone brown (its UVs are in units of 1.6 m, running down the slope)
			var tm: StandardMaterial3D = Tex.mat(Tex.pick("tiles") if Tex.pick("tiles") != "" else "clay_roof_tiles_02", Color(0.46, 0.41, 0.39), true, 1.6)
			tm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = tm
		"hiedra":
			m = W._tmat(0x2f5e34, "leaf", 0.8)
		"interior":         # what is inside the shop
			var im := StandardMaterial3D.new()
			im.albedo_color = Color(0.9, 0.86, 0.76)
			im.emission_enabled = true
			im.emission = Color(0.9, 0.84, 0.7)
			im.emission_energy_multiplier = 0.25
			m = im
		"luz":
			var lm := StandardMaterial3D.new()
			lm.albedo_color = Color(1.0, 0.98, 0.9)
			lm.emission_enabled = true
			lm.emission = Color(1.0, 0.95, 0.82)
			lm.emission_energy_multiplier = 2.2
			m = lm
		_:
			return super(key)
	_mats[key] = m
	return m

func _loc(p: Vector2) -> Vector2:
	var q: Vector3 = transform.affine_inverse() * Vector3(p.x, level, p.y)
	return Vector2(q.x, q.z)

## a house's outline(s) on the map, in this frame
func _rings(hd: Dictionary) -> Array:
	var out: Array = []
	for pc in hd.get("pieces", []):
		var raw: Array = pc["ring"]
		var ring: Array = []
		for i in range(0, raw.size(), 2):
			ring.append(_loc(Vector2(float(raw[i]), float(raw[i + 1]))))
		out.append(ring)
	return out

## how far out of the university's front the garden wall is, x metres along it
func _zw(x: float) -> float:
	return lerpf(3.5, 4.4, clampf(x / len_front, 0.0, 1.0))

func build(world, hd: Dictionary, shop: Dictionary) -> void:
	W = world
	var o := Vector2(hd["o"][0], hd["o"][1])
	var u := Vector2(hd["u"][0], hd["u"][1])
	var out := Vector2(-u.y, u.x)
	len_front = float(hd["len"])
	level = MapData.height(o + u * ((P0 + P1) / 2.0) + out * 4.8)
	transform = Transform3D(Basis(Vector3(u.x, 0, u.y), Vector3.UP, Vector3(out.x, 0, out.y)), Vector3(o.x, level, o.y))
	W.add_child(self)
	ridge_hex = 0x7a5a48                           # (old tiles: their ridges too)
	door = spot((P0 + P1) / 2.0, _zw(8.4) + 1.3)
	_front()
	_body(hd)
	_porch()
	_garden()
	_street()
	if not shop.is_empty():
		has_shop = true
		_shop(shop)
	home()
	_commit()
	if has_shop:
		var front: Transform3D = transform * (_arch["xf"] as Transform3D)      # the arch, on the map: its inside is a set apart
		var cx: float = _arch["cx"]
		var a: Vector3 = front * Vector3(cx, 0.0, 0.35)
		var b: Vector3 = front * Vector3(cx, 0.0, 1.5)
		tienda = RocasS.new()
		tienda.build(world, SHOP_NAME, Vector2(a.x, a.z), Vector2(b.x, b.z), atan2(front.basis.z.x, front.basis.z.z))
		_states()

# ---------------- helpers ----------------
## a stretch of wall from p to q (on the floor plan), `thick` wide, from `low` up to `top`
func _wall_piece(p: Vector2, q: Vector2, thick: float, low: float, top: float, key) -> void:
	pieces += 1
	var d: Vector2 = (q - p).normalized()
	var n := Vector2(-d.y, d.x) * thick / 2.0
	var a := [p - n, q - n, q + n, p + n]
	for s in [[0, 1, -1.0], [3, 2, 1.0]]:
		var u0: Vector2 = a[s[0]]
		var u1: Vector2 = a[s[1]]
		quad(Vector3(u0.x, low, u0.y), Vector3(u1.x, low, u1.y), Vector3(u1.x, top, u1.y), Vector3(u0.x, top, u0.y), key, Vector3(n.x, 0, n.y).normalized() * float(s[2]))
	quad(Vector3(a[0].x, top, a[0].y), Vector3(a[1].x, top, a[1].y), Vector3(a[2].x, top, a[2].y), Vector3(a[3].x, top, a[3].y), key, Vector3.UP)
	quad(Vector3(a[0].x, low, a[0].y), Vector3(a[3].x, low, a[3].y), Vector3(a[3].x, top, a[3].y), Vector3(a[0].x, top, a[0].y), key, Vector3(-d.x, 0, -d.y))
	quad(Vector3(a[1].x, low, a[1].y), Vector3(a[2].x, low, a[2].y), Vector3(a[2].x, top, a[2].y), Vector3(a[1].x, top, a[1].y), key, Vector3(d.x, 0, d.y))

## the walls of an outline no street sees from in front: every side but those in `skip`, seen from both sides
func _ring_walls(ring: Array, low: float, top: float, key, skip: Array = []) -> void:
	for i in range(ring.size()):
		if skip.has(i):
			continue
		var a: Vector2 = ring[i]
		var b: Vector2 = ring[(i + 1) % ring.size()]
		if a.distance_to(b) < 0.05:
			continue
		_plain(a, b, low, top, key)
		_plain(b, a, low, top, key)

## what fills a window's hole: glass, a white frame of two leaves under a fixed light, a sill of brick
func _win(r: Rect2) -> void:
	var z: float = -DEEP + 0.08
	box(r.position.x, r.position.y, z - 0.04, r.size.x, r.size.y, 0.03, GLASS)
	for q in [[r.position.x, r.position.y, 0.07, r.size.y], [r.end.x - 0.07, r.position.y, 0.07, r.size.y], [r.position.x, r.position.y, r.size.x, 0.07], [r.position.x, r.end.y - 0.07, r.size.x, 0.07],
			[r.position.x + r.size.x / 2.0 - 0.03, r.position.y, 0.06, r.size.y * 0.72], [r.position.x, r.position.y + r.size.y * 0.72, r.size.x, 0.06]]:
		box(q[0], q[1], z - 0.02, q[2], q[3], 0.06, WHITE)
	box(r.position.x + 0.07, r.position.y + 0.07, z - 0.03, r.size.x - 0.14, r.size.y * 0.5, 0.012, 0xe9e6dc)        # (its net curtain)
	box(r.position.x - 0.1, r.position.y - 0.08, 0.0, r.size.x + 0.2, 0.08, 0.07, "ladrillo")

## words on a board that stands across the wall being built: `turn` about y
func _label(s: String, at: Vector3, turn: float, px: int, hex: int, pixel: float) -> Label3D:
	var l := Label3D.new()
	l.text = s
	l.font_size = px
	l.pixel_size = pixel
	l.modulate = Parts.col(hex)
	l.outline_size = 0
	l.double_sided = false
	l.transform = _xf * Transform3D(Basis(Vector3.UP, turn), at)
	add_child(l)
	return l

# ---------------- the university's front ----------------
func _front() -> void:
	var ln: float = face(Vector2(0, 0), Vector2(len_front, 0))
	var wins: Array = []
	for c in NORTH:
		wins.append(Rect2(float(c) - WW / 2.0, SILL, WW, HEAD - SILL))
		wins.append(Rect2(ln - float(c) - WW / 2.0, SILL, WW, HEAD - SILL))
	var way := Rect2(DOOR_X - 0.75, DOWN, 1.5, 2.95 - DOWN)
	var holes: Array = wins.duplicate()
	holes.append(way)
	masonry(0.0, ln, DOWN, EAVE, holes, [], "ladrillo")
	for r: Rect2 in wins:
		if r.position.x > 17.5:                     # the last one, behind its wooden shutter and its bars
			box(r.position.x, r.position.y, -DEEP + 0.04, r.size.x, r.size.y, 0.04, 0x4a3426)
			for j in range(1, 8):
				box(r.position.x, r.position.y + j * r.size.y / 8.0, -DEEP + 0.08, r.size.x, 0.02, 0.012, 0x3a2a1e)
			grille(r, 0.12, 0x2a2622)
			box(r.position.x - 0.1, r.position.y - 0.08, 0.0, r.size.x + 0.2, 0.08, 0.07, "ladrillo")
		else:
			_win(r)
	# the door: two white leaves, glazed, under a fixed light
	var z: float = -DEEP + 0.06
	box(way.position.x, 0.0, z - 0.04, 1.5, 2.95, 0.03, GLASS)
	for q in [[way.position.x, 0.0, 0.08, 2.95], [way.end.x - 0.08, 0.0, 0.08, 2.95], [DOOR_X - 0.04, 0.0, 0.08, 2.2], [way.position.x, 2.2, 1.5, 0.08], [way.position.x, 2.87, 1.5, 0.08]]:
		box(q[0], q[1], z - 0.02, q[2], q[3], 0.06, WHITE)
	for s in [-1.0, 1.0]:
		box(DOOR_X + s * 0.37 - 0.29, 0.0, z - 0.02, 0.58, 0.9, 0.04, WHITE)
	box(way.position.x - 0.15, -0.3, 0.0, 1.8, 0.32, 0.3, 0xb8a58c)                     # its step
	# the old plate of the schools, over the first window north of the door; two round lamps
	var pc: float = float(NORTH[0])
	box(pc - 0.73, 3.25, 0.0, 1.46, 0.52, 0.03, 0x2a3a6a)
	box(pc - 0.7, 3.28, 0.03, 1.4, 0.46, 0.006, 0xf4f1e6)
	_text(PLATE, Vector3(pc, 3.51, 0.045), 32, 0x26262a, 0.0036)
	for x in [3.4, 15.3]:
		slab(oval(x, 3.8, 0.11, 0.11, 10), 0.07, 0.05, 0xf1f0ea)
	cornice(0.0, ln, EAVE + 0.3, true, "ladrillo", 0.8)
	home()

## Its other walls, as the map has its plot, and its roofs: one ridge along the street, hipped at the north end; its
## wing behind; the chimney.
func _body(hd: Dictionary) -> void:
	for ring: Array in _rings(hd):
		var skip: Array = []
		for i in range(ring.size()):
			var a: Vector2 = ring[i]
			var b: Vector2 = ring[(i + 1) % ring.size()]
			if absf(a.y) < 0.3 and absf(b.y) < 0.3:
				skip.append(i)                      # (the front: _front draws it)
		_ring_walls(ring, DOWN, EAVE + 0.3, "ladrillo", skip)
	var ye: float = EAVE + 0.3
	var ln: float = len_front
	var zr: float = -DEPTH / 2.0
	roof([Vector3(0, ye, 0.45), Vector3(ln + 0.3, ye, 0.45), Vector3(ln - 3.3, RIDGE, zr), Vector3(0, RIDGE, zr)])
	roof([Vector3(0, ye, -DEPTH - 0.3), Vector3(ln + 0.3, ye, -DEPTH - 0.3), Vector3(ln - 3.3, RIDGE, zr), Vector3(0, RIDGE, zr)])
	roof([Vector3(ln + 0.3, ye, 0.45), Vector3(ln + 0.3, ye, -DEPTH - 0.3), Vector3(ln - 3.3, RIDGE, zr)])
	ridge(Vector3(0, RIDGE, zr), Vector3(ln - 3.3, RIDGE, zr))
	ridge(Vector3(ln + 0.3, ye, 0.45), Vector3(ln - 3.3, RIDGE, zr))
	ridge(Vector3(ln + 0.3, ye, -DEPTH - 0.3), Vector3(ln - 3.3, RIDGE, zr))
	for n in [1.0, -1.0]:                           # its south gable (the stationer's stands against it, taller)
		tri(Vector3(0, ye, 0.3), Vector3(0, ye, -DEPTH), Vector3(0, RIDGE, zr), "ladrillo", Vector3(n, 0, 0))
	# the wing behind: its own ridge, running back
	roof([Vector3(6.4, ye, -13.0), Vector3(6.4, ye, -6.6), Vector3(9.95, ye + 1.5, -6.6), Vector3(9.95, ye + 1.5, -13.0)])
	roof([Vector3(13.5, ye, -13.0), Vector3(13.5, ye, -6.6), Vector3(9.95, ye + 1.5, -6.6), Vector3(9.95, ye + 1.5, -13.0)])
	for n in [1.0, -1.0]:
		tri(Vector3(6.7, ye, -12.7), Vector3(13.2, ye, -12.7), Vector3(9.95, ye + 1.4, -12.7), "ladrillo", Vector3(0, 0, n))
	quad(Vector3(-0.1, ye, -9.3), Vector3(3.8, ye, -9.3), Vector3(3.8, ye, -7.2), Vector3(-0.1, ye, -7.2), 0x8a8478, Vector3.UP)
	cbox(Vector3(13.8, RIDGE + 0.45, zr + 0.5), Vector3(0.5, 1.5, 0.5), "ladrillo")     # the chimney, and its cap
	cbox(Vector3(13.8, RIDGE + 1.24, zr + 0.5), Vector3(0.62, 0.08, 0.62), 0xb9a58c)

# ---------------- the porch on the street ----------------
func _porch() -> void:
	var zf: float = _zw((P0 + P1) / 2.0) + 0.3      # its front
	var xc: float = (P0 + P1) / 2.0
	for x in [P0, P1 - PILLAR]:
		box(x, DOWN, zf - PILLAR, PILLAR, PORCH - DOWN, PILLAR, "ladrillo")
		box(x - 0.04, PORCH - 0.12, zf - PILLAR - 0.04, PILLAR + 0.08, 0.12, PILLAR + 0.08, "ladrillo")
	var tan := 0xd9b48c                             # its beams: over the board, and from each pillar back to the house
	box(P0, 3.9, zf - 0.5, P1 - P0, 0.4, 0.4, tan)
	for x in [P0 + 0.12, P1 - 0.52]:
		box(x, 3.9, 0.0, 0.4, 0.4, zf - PILLAR, tan)
	quad(Vector3(P0, 4.3, 0.0), Vector3(P1, 4.3, 0.0), Vector3(P1, 4.3, zf), Vector3(P0, 4.3, zf), 0xe6dccb, Vector3.DOWN)
	quad(Vector3(P0, 0.03, 0.0), Vector3(P1, 0.03, 0.0), Vector3(P1, 0.03, zf), Vector3(P0, 0.03, zf), 0xb8a58c, Vector3.UP)
	# the board with its name: white, red letters, its badge (a ring) at the left
	var b0: float = P0 + PILLAR - 0.06
	var b1: float = P1 - PILLAR + 0.06
	box(b0, 3.22, zf - 0.1, b1 - b0, 0.66, 0.06, 0xf7f5ee)
	slab(oval(b0 + 0.3, 3.55, 0.17, 0.17, 16), zf - 0.03, 0.0, 0xb8242c)
	slab(oval(b0 + 0.3, 3.55, 0.11, 0.11, 16), zf - 0.026, 0.0, 0xf7f5ee)
	slab(oval(b0 + 0.3, 3.55, 0.05, 0.05, 10), zf - 0.022, 0.0, 0xb8242c)
	var name := _text(NAME, Vector3((b0 + 0.5 + b1) / 2.0, 3.55, zf - 0.03), 64, 0xb8242c, 0.003)
	name.outline_size = 6
	name.outline_modulate = Parts.col(0xb8242c)
	cbox(Vector3(P0 + 0.95, 4.06, zf + 0.06), Vector3(0.36, 0.26, 0.2), 0x1c1c1e)       # two floodlights over it
	cbox(Vector3(P1 - 0.75, 4.02, zf + 0.06), Vector3(0.24, 0.18, 0.16), 0xb9bcc0)
	# its roof of tiles: a hip to the street, running back into the house's
	var o := 0.38
	var pe: float = PORCH + 0.08
	var pr: float = pe + 1.0
	var k: float = (RIDGE - EAVE - 0.3) / (0.45 + DEPTH / 2.0)                          # how steep the house's roof is
	var zc: float = 0.45 - (pr - EAVE - 0.3) / k                                        # where this ridge runs into it
	var apex := Vector3(xc, pr, zf - 1.9)
	roof([Vector3(P0 - o, pe, zf + o), Vector3(P1 + o, pe, zf + o), apex])
	roof([Vector3(P0 - o, pe, zf + o), Vector3(P0 - o, pe, 0.45), Vector3(xc, pr, zc), apex])
	roof([Vector3(P1 + o, pe, zf + o), Vector3(P1 + o, pe, 0.45), Vector3(xc, pr, zc), apex])
	ridge(apex, Vector3(xc, pr, zc))
	ridge(Vector3(P0 - o, pe, zf + o), apex)
	ridge(Vector3(P1 + o, pe, zf + o), apex)
	# the gate: two leaves of iron bars over a sheet, shut
	var zg: float = zf - PILLAR / 2.0
	var g0: float = P0 + PILLAR
	var g1: float = P1 - PILLAR
	box(g0, 0.03, zg - 0.02, g1 - g0, 0.82, 0.04, GATE)
	for y in [0.85, 1.55, 2.25]:
		box(g0, y, zg - 0.02, g1 - g0, 0.05, 0.04, GATE)
	var n := int((g1 - g0) / 0.12)
	for i in range(n + 1):
		var x: float = g0 + i * (g1 - g0 - 0.025) / n
		box(x, 0.85, zg - 0.0125, 0.025, 1.45, 0.025, GATE)
	box((g0 + g1) / 2.0 - 0.03, 0.03, zg - 0.03, 0.06, 2.27, 0.06, GATE)
	cbox(Vector3((g0 + g1) / 2.0 + 0.12, 1.1, zg + 0.04), Vector3(0.14, 0.2, 0.04), 0x5a3a34)

# ---------------- the garden and its wall ----------------
## A stretch of the garden wall from x0 to x1 along the front: golden rubble under a coping of brick, and the hedge of
## ivy on it. It follows the ground.
func _hedge(x0: float, x1: float) -> void:
	var n := maxi(1, int(ceil((x1 - x0) / 1.9)))
	for i in range(n):
		var a := Vector2(lerpf(x0, x1, float(i) / n), 0.0)
		var b := Vector2(lerpf(x0, x1, float(i + 1) / n), 0.0)
		a.y = _zw(a.x)
		b.y = _zw(b.x)
		var g: float = maxf(ground(a.x, a.y + 0.5), ground(b.x, b.y + 0.5))
		var low: float = minf(ground(a.x, a.y + 0.5), ground(b.x, b.y + 0.5)) - 0.6
		_wall_piece(a, b, 0.4, low, g + 0.8, "rubble")
		_wall_piece(a, b, 0.48, g + 0.8, g + 0.88, "ladrillo")
		_wall_piece(a, b, 0.72 + 0.12 * (i % 2), g + 0.84, g + 2.5 + 0.12 * ((i * 7) % 3), "hiedra")
		var mid: Vector2 = (a + b) / 2.0
		ball(Vector3(mid.x, g + 2.5, mid.y + 0.06), 0.95, "hiedra", 0.3, 8, 5)       # (it spills over the top)

func _garden() -> void:
	# its ground, between the house and the wall: beaten earth
	var pts := PackedVector2Array([Vector2(0.0, 0.0), Vector2(len_front, 0.0), Vector2(len_front, _zw(len_front)), Vector2(0.0, _zw(0.0))])
	var idx := Geometry2D.triangulate_polygon(pts)
	for t in range(0, idx.size(), 3):
		var a := pts[idx[t]]
		var b := pts[idx[t + 1]]
		var c := pts[idx[t + 2]]
		tri(Vector3(a.x, maxf(0.0, ground(a.x, a.y)) + 0.04, a.y), Vector3(b.x, maxf(0.0, ground(b.x, b.y)) + 0.04, b.y), Vector3(c.x, maxf(0.0, ground(c.x, c.y)) + 0.04, c.y), 0xa89a82, Vector3.UP)
	# the brick pier at its south end, by the stationer's corner, with the meter box beside it
	var g: float = ground(0.3, _zw(0.3) + 0.5)
	box(0.0, DOWN, _zw(0.0) - 0.5, 0.55, g + 2.3 - DOWN, 0.5, "ladrillo")
	_hedge(0.55, P0)
	_hedge(P1, len_front - 0.45)
	box(len_front - 0.45, DOWN, _zw(len_front) - 0.5, 0.45, ground(len_front, 5.0) + 2.3 - DOWN, 0.5, "ladrillo")
	box(0.62, g + 0.95, _zw(0.8) + 0.3, 0.6, 0.42, 0.14, 0xe9e2cc)

# ---------------- on the pavement ----------------
## The notice board on its two red posts, beside the porch; and before the hedge the road sign -- this way only --
## with its mirror.
func _street() -> void:
	var zb: float = _zw(11.4) + 0.42          # (close to the wall: the game's pavement is narrow here)
	var g: float = ground(11.4, zb)
	for x in [10.78, 12.04]:
		drum(Vector3(x, g, zb), 0.1, 0.05, 0.22, RED, 8)
		drum(Vector3(x, g + 0.2, zb), 0.045, 0.045, 2.5, RED, 8)
		ball(Vector3(x, g + 2.76, zb), 0.075, RED, 1.0, 6, 4)
		yard.append(spot(x, zb))
	box(10.84, g + 0.75, zb - 0.05, 1.14, 1.48, 0.1, RED)
	box(10.9, g + 0.81, zb + 0.05, 1.02, 1.36, 0.01, 0xe9e2cc)
	for q in [[10.98, 1.5, 0.36, 0.55, 0xf4f1e6], [11.4, 1.62, 0.42, 0.4, 0xe6c8c8], [11.02, 0.95, 0.3, 0.42, 0xf4f1e6], [11.42, 0.98, 0.4, 0.5, 0xd9e2ea]]:      # what is pinned on it
		box(q[0], g + q[1], zb + 0.06, q[2], q[3], 0.004, q[4])
		box(q[0] + 0.04, g + q[1] + q[3] - 0.1, zb + 0.065, q[2] - 0.08, 0.04, 0.003, 0x8a2a2a)
	solid(Vector3(11.41, g + 1.2, zb), Vector3(1.4, 2.6, 0.2))
	var at := Vector2(2.7, _zw(2.7) + 0.44)
	var gs: float = ground(at.x, at.y)
	cbox(Vector3(at.x, gs + 1.45, at.y), Vector3(0.06, 2.9, 0.06), 0x9a9da0)
	slab(oval(at.x, gs + 1.95, 0.3, 0.3, 20), at.y + 0.05, 0.03, 0x1f4fb0)
	box(at.x - 0.17, gs + 1.92, at.y + 0.05, 0.26, 0.06, 0.005, 0xfdfcf8)                 # its arrow, pointing north
	slab(PackedVector2Array([Vector2(at.x + 0.07, gs + 2.07), Vector2(at.x + 0.2, gs + 1.95), Vector2(at.x + 0.07, gs + 1.83)]), at.y + 0.056, 0.0, 0xfdfcf8)
	slab(oval(at.x - 0.28, gs + 2.62, 0.26, 0.3, 16), at.y + 0.08, 0.04, 0x3a3d40)        # the mirror, in its dark rim
	slab(oval(at.x - 0.28, gs + 2.62, 0.22, 0.26, 16), at.y + 0.084, 0.0, 0xb8c4cc)
	solid(Vector3(at.x, gs + 1.2, at.y), Vector3(0.16, 2.6, 0.16))
	yard.append(spot(at.x, at.y))

# ---------------- the stationer's ----------------
## whether a point of the wall being built is in a round-headed opening (its middle, its foot, where it springs, its radius)
func _in_arch(p: Vector2, cx: float, y0: float, spring: float, r: float) -> bool:
	if absf(p.x - cx) > r or p.y < y0:
		return false
	return p.y <= spring or p.distance_to(Vector2(cx, spring)) <= r

## a mesh of wire across such an opening, on the plane z
func _mesh(cx: float, y0: float, spring: float, r: float, z: float, hex: int) -> void:
	var seg := 0.09
	for way in [1.0, -1.0]:
		var c: float = -r - (spring + r - y0)
		while c < r + (spring + r - y0):
			var t := 0.0
			var from := -1.0
			while t <= spring + r - y0 + seg:
				var inside: bool = _in_arch(Vector2(cx + c + way * (t + seg / 2.0), y0 + t + seg / 2.0), cx, y0, spring, r)
				if inside and from < 0.0:
					from = t
				if not inside and from >= 0.0:
					bar(Vector3(cx + c + way * from, y0 + from, z), Vector3(cx + c + way * t, y0 + t, z), 0.008, 0.016, hex)
					from = -1.0
				t += seg
			c += 0.17

func _shop(hd: Dictionary) -> void:
	var o := Vector2(hd["o"][0], hd["o"][1])
	var u := Vector2(hd["u"][0], hd["u"][1])
	var a: Vector2 = _loc(o)                        # its south corner on the street (the left one, seen from it)
	var b: Vector2 = _loc(o + u * float(hd["len"]))
	var rings: Array = _rings(hd)
	shop_door = spot((a.x + b.x) / 2.0, (a.y + b.y) / 2.0 + 1.3)
	var g: float = ground((a.x + b.x) / 2.0, (a.y + b.y) / 2.0 + 0.6)       # its own pavement
	var top: float = g + SHOP_TOP
	# its other walls, white, as the map has its plot (the first outline; the second is the block on the Calle Cervantes)
	if rings.size() > 0:
		var ring: Array = rings[0]
		var skip: Array = []
		for i in range(ring.size()):
			var p: Vector2 = ring[i]
			var q: Vector2 = ring[(i + 1) % ring.size()]
			if (p.distance_to(a) < 0.4 and q.distance_to(b) < 0.4) or (p.distance_to(b) < 0.4 and q.distance_to(a) < 0.4):
				skip.append(i)
		_ring_walls(ring, DOWN, top, "blanco", skip)
	if rings.size() > 1:
		_back(rings[1])
	var flank: float = face(b, Vector2(b.x, 0.0))      # its north side, over the university's garden: a band of brick under the roof's slope
	bar(Vector3(0.0, top - 0.42, 0.03), Vector3(minf(flank, 2.6), top + 0.55, 0.03), 0.05, 0.16, "ladrillo")
	bar(Vector3(minf(flank, 2.6), top + 0.55, 0.03), Vector3(flank, top + 0.2, 0.03), 0.05, 0.16, "ladrillo")
	box(0.0, g + 2.98, 0.0, flank, 0.2, 0.05, "ladrillo")
	home()
	var w: float = face(a, b)
	var r := 1.08
	var cx: float = w / 2.0 + 0.08
	var spring: float = g + 1.72
	var bal := Rect2(cx - 0.5, g + 3.6, 1.0, 2.0)
	masonry(0.0, w, DOWN, top, [Rect2(cx - r, DOWN, 2.0 * r, spring - DOWN), Rect2(cx - r, spring, 2.0 * r, r), bal], [], "blanco")
	spandrels(cx, spring, r, 0.0, "blanco")
	box(0.0, DOWN, 0.0, cx - r - 0.12, g + 0.9 - DOWN, 0.025, 0xd9b48c)                  # the tan foot of its south pier
	# The shop behind the arch: a room running back from the pavement -- its floor at the door's own level, shelves of
	# goods down both walls, a stand of cards by the door, the counter across the far end with more shelves behind it.
	var x0: float = cx - 1.32
	var x1: float = cx + 1.32
	var back := -6.4
	var zi := -0.34
	var ceil: float = g + 2.95
	var fl: float = g + 0.03
	quad(Vector3(x0, fl, back), Vector3(x1, fl, back), Vector3(x1, fl, 0.0), Vector3(x0, fl, 0.0), 0xb9a58c, Vector3.UP)
	for i in range(1, 14):                          # the joints of its tiles
		box(x0, fl, back + i * 0.46, x1 - x0, 0.004, 0.012, 0xa08c74)
	quad(Vector3(x0, fl, back), Vector3(x1, fl, back), Vector3(x1, ceil, back), Vector3(x0, ceil, back), "interior", Vector3(0, 0, 1))
	quad(Vector3(x0, fl, back), Vector3(x0, fl, zi), Vector3(x0, ceil, zi), Vector3(x0, ceil, back), "interior", Vector3(1, 0, 0))
	quad(Vector3(x1, fl, back), Vector3(x1, fl, zi), Vector3(x1, ceil, zi), Vector3(x1, ceil, back), "interior", Vector3(-1, 0, 0))
	quad(Vector3(x0, ceil, back), Vector3(x1, ceil, back), Vector3(x1, ceil, zi), Vector3(x0, ceil, zi), "interior", Vector3(0, -1, 0))
	for q in [[x0, cx - r, fl, ceil], [cx + r, x1, fl, ceil], [cx - r, cx + r, spring + r, ceil]]:      # the inside of the front wall, round the arch
		quad(Vector3(q[0], q[2], zi), Vector3(q[1], q[2], zi), Vector3(q[1], q[3], zi), Vector3(q[0], q[3], zi), "interior", Vector3(0, 0, -1))
	var tints: Array = [0xf2c230, 0x3a9a4a, 0x2a82d8, 0xe8322a, 0xf07a22, 0xfdfcf8, 0x8a5ad0, 0xe85aa8]
	for side in [-1.0, 1.0]:                        # the shelves down each wall, from a metre in to the counter
		var sx: float = x0 if side < 0.0 else x1 - 0.3
		for j in range(6):
			var y: float = fl + 0.25 + j * 0.42
			box(sx, y, back + 1.5, 0.3, 0.03, 4.0, 0xd9d4c8)
			for i in range(16):
				box(sx + 0.04, y + 0.03, back + 1.55 + i * 0.245, 0.22, 0.2 + 0.06 * ((i + j) % 3), 0.2, tints[(i * 3 + j * 5 + int(side + 1.0)) % tints.size()])
	box(x0 + 0.15, fl, back + 0.75, x1 - x0 - 0.75, 0.95, 0.5, 0x9a7a5a)                # the counter, its top, the till
	box(x0 + 0.1, fl + 0.95, back + 0.7, x1 - x0 - 0.65, 0.05, 0.6, 0xe9e2cc)
	cbox(Vector3(x0 + 0.6, fl + 1.12, back + 1.0), Vector3(0.36, 0.26, 0.32), 0x3a3d40)
	for j in range(5):                              # the shelves behind it
		var y: float = fl + 0.5 + j * 0.45
		box(x0 + 0.1, y, back + 0.02, x1 - x0 - 0.2, 0.03, 0.26, 0xd9d4c8)
		for i in range(11):
			box(x0 + 0.14 + i * (x1 - x0 - 0.3) / 11.0, y + 0.03, back + 0.05, (x1 - x0 - 0.3) / 11.0 - 0.03, 0.22 + 0.06 * ((i + j) % 3), 0.18, tints[(i * 5 + j * 3) % tints.size()])
	cbox(Vector3(x1 - 0.62, fl + 0.8, -0.95), Vector3(0.05, 1.6, 0.05), 0x4a4d52)       # the stand of cards by the door
	for j in range(4):
		for k in range(4):
			var turn: float = TAU * k / 4.0
			cbox(Vector3(x1 - 0.62 + cos(turn) * 0.14, fl + 0.5 + j * 0.3, -0.95 + sin(turn) * 0.14), Vector3(0.14, 0.2, 0.14), tints[(j * 3 + k * 5) % tints.size()])
	box(cx - 0.6, fl, -0.3, 1.2, 0.012, 0.75, 0x6a4a3a)                                 # the mat at the door
	_arch = {"xf": _xf, "cx": cx, "g": g, "spring": spring, "r": r, "back": back, "ceil": ceil}
	# the band of brick between its floors; the balcony on its slab, its iron rail, its pots
	cornice(0.0, w, g + 3.2, true, "ladrillo", 0.55)
	var yb: float = g + 3.5
	box(cx - 0.8, yb - 0.02, 0.0, 1.6, 0.12, 0.5, 0xd9d4c8)
	for y in [yb + 0.18, yb + 1.05]:
		box(cx - 0.78, y, 0.45, 1.56, 0.03, 0.03, IRON)
		for sx in [cx - 0.78, cx + 0.75]:
			box(sx, y, 0.0, 0.03, 0.03, 0.47, IRON)
	for i in range(14):
		box(cx - 0.77 + i * 0.1175, yb + 0.1, 0.455, 0.016, 0.95, 0.016, IRON)
	for sx in [cx - 0.77, cx + 0.754]:
		for i in range(4):
			box(sx, yb + 0.1, 0.06 + i * 0.12, 0.016, 0.95, 0.016, IRON)
	for i in range(3):
		cbox(Vector3(cx - 0.45 + i * 0.45, yb + 0.2, 0.3), Vector3(0.2, 0.18, 0.2), 0xb8623c)
		ball(Vector3(cx - 0.45 + i * 0.45, yb + 0.38, 0.3), 0.14, "hiedra", 0.8, 6, 4)
	# its door on to the balcony: wood, small panes, the box of its blind; a flat arch of brick over it
	var z: float = -DEEP + 0.08
	box(bal.position.x, bal.position.y, z - 0.04, bal.size.x, bal.size.y, 0.03, GLASS)
	for q in [[bal.position.x, bal.position.y, 0.08, bal.size.y], [bal.end.x - 0.08, bal.position.y, 0.08, bal.size.y], [cx - 0.04, bal.position.y, 0.08, bal.size.y], [bal.position.x, bal.position.y, bal.size.x, 0.1]]:
		box(q[0], q[1], z - 0.02, q[2], q[3], 0.06, WOOD)
	for j in range(1, 4):
		box(bal.position.x, bal.position.y + j * 0.42, z - 0.015, bal.size.x, 0.03, 0.04, WOOD)
	box(bal.position.x, bal.end.y - 0.36, z, bal.size.x, 0.36, 0.1, 0x5a3a24)
	box(bal.position.x - 0.2, bal.end.y, 0.0, bal.size.x + 0.4, 0.3, 0.035, "ladrillo")
	# under the eaves: a course of brick, the wooden brackets, the tiles
	box(0.0, top - 0.5, 0.0, w, 0.16, 0.04, "ladrillo")
	for i in range(int(w / 0.34) + 1):
		box(0.05 + i * (w - 0.18) / int(w / 0.34), top - 0.16, 0.0, 0.08, 0.14, 0.55, WOOD)
	roof([Vector3(-0.1, top, 0.62), Vector3(w + 0.1, top, 0.62), Vector3(w + 0.1, top + 1.0, -2.0), Vector3(-0.1, top + 1.0, -2.0)])
	roof([Vector3(-0.1, top + 1.0, -2.0), Vector3(w + 0.1, top + 1.0, -2.0), Vector3(w + 0.1, top - 0.1, -12.9), Vector3(-0.1, top - 0.1, -12.9)])
	ridge(Vector3(-0.1, top + 1.0, -2.0), Vector3(w + 0.1, top + 1.0, -2.0))
	for sx in [0.0, w]:                             # its two gables, over the neighbours' roofs
		for n in [1.0, -1.0]:
			tri(Vector3(sx, top, 0.0), Vector3(sx, top + 1.0, -2.0), Vector3(sx, top, -12.9), "blanco", Vector3(n, 0, 0))
	# its sign: a green board hanging out over the pavement at its south edge, its name on both faces
	var sy: float = g + 4.25
	box(0.2, sy, 0.1, 0.05, 0.98, 0.52, GREEN)
	box(0.2, sy + 0.9, 0.0, 0.05, 0.04, 0.12, IRON)
	box(0.2, sy + 0.1, 0.0, 0.05, 0.04, 0.12, IRON)
	for side in [[0.256, PI / 2.0], [0.194, -PI / 2.0]]:
		_label(SHOP_NAME, Vector3(side[0], sy + 0.78, 0.36), side[1], 48, 0xfdfcf8, 0.0028)
		_label("LIBRERÍA\nPAPELERÍA", Vector3(side[0], sy + 0.42, 0.36), side[1], 32, 0xfdfcf8, 0.0022)
		_label("PRENSA", Vector3(side[0], sy + 0.14, 0.36), side[1], 32, 0xf2e6a0, 0.002)
	cbox(Vector3(w - 0.3, g + 3.0, 0.06), Vector3(0.22, 0.14, 0.1), 0xe9e6dc)           # a box of wires, a lamp on its arm
	bar(Vector3(0.9, top - 0.9, 0.0), Vector3(0.9, top - 0.6, 0.8), 0.04, 0.04, 0x9a9da0)
	cbox(Vector3(0.9, top - 0.6, 0.95), Vector3(0.18, 0.08, 0.42), 0x8a8d90)
	home()

## The block on the Calle Cervantes, the back of the stationer's plot: three floors of bare brick nobody finished --
## a rendered foot with a green gate and a doorway, a band of brick, and the holes of its windows, empty.
func _back(ring: Array) -> void:
	var front := -1
	for i in range(ring.size()):
		var p: Vector2 = ring[i]
		var q: Vector2 = ring[(i + 1) % ring.size()]
		if p.y < -24.5 and q.y < -24.5 and p.distance_to(q) > 4.0:
			front = i
	var g := 0.0
	for p: Vector2 in ring:
		g = maxf(g, ground(p.x, p.y))
	var top: float = g + BACK_TOP
	_ring_walls(ring, DOWN, top, "tosco", [front] if front >= 0 else [])
	flat(PackedVector2Array(ring), top, 0x8a8478)
	if front < 0:
		return
	var a: Vector2 = ring[front]
	var b: Vector2 = ring[(front + 1) % ring.size()]
	if a.x < b.x:                                   # (seen from the street, its left end is the north one)
		var keep := a
		a = b
		b = keep
	var ln: float = face(a, b)
	var gate := Rect2(0.3, DOWN, 2.3, g + 2.6 - DOWN)
	var way := Rect2(3.4, DOWN, 0.9, g + 2.2 - DOWN)
	var holes: Array = [gate, way]
	for f in range(2):
		holes.append(Rect2(0.6, g + 3.9 + f * 2.8, 1.9, 1.7))
		holes.append(Rect2(3.5, g + 4.2 + f * 2.8, 1.0, 1.3))
	masonry(0.0, ln, DOWN, top, holes, [], "tosco")
	for r: Rect2 in holes:                          # the dark behind each
		box(r.position.x, maxf(r.position.y, g), -DEEP - 0.02, r.size.x, r.end.y - maxf(r.position.y, g), 0.02, 0x1c1a18)
	box(gate.position.x, g, -0.1, gate.size.x, gate.end.y - g, 0.04, 0x3f7a45)          # the gate of green sheet, ribbed
	for i in range(1, int(gate.size.x / 0.14)):
		box(gate.position.x + i * 0.14, g, -0.06, 0.03, gate.end.y - g, 0.012, 0x356a3c)
	var grey := 0x9a948a                            # the render of its foot, round the two ways in
	for q in [[0.0, gate.position.x, DOWN, g + 3.0], [gate.end.x, way.position.x, DOWN, g + 3.0], [way.end.x, ln, DOWN, g + 3.0], [gate.position.x, gate.end.x, gate.end.y, g + 3.0], [way.position.x, way.end.x, way.end.y, g + 3.0]]:
		box(q[0], q[2], 0.0, q[1] - q[0], q[3] - q[2], 0.03, grey)
	box(0.0, g + 3.0, 0.0, ln, 0.24, 0.06, "ladrillo")
	home()

# ---------------- the stationer's, shut and open ----------------
## what has been built since the last commit becomes meshes under `node`: a part that can be shown and hidden
func _commit_to(node: Node3D) -> void:
	for key in _tools:
		var mi := MeshInstance3D.new()
		mi.mesh = (_tools[key] as SurfaceTool).commit()
		mi.material_override = _material(key)
		node.add_child(mi)
	_tools.clear()

## whether the stationer's is open on that day of the week (0 Monday ... 6 Sunday) at that hour
func open_at(day: int, hour: float) -> bool:
	var d: int = posmod(day, 7)
	if d == 6:
		return false
	if hour >= MORNING.x and hour < MORNING.y:
		return true
	return d <= 4 and hour >= EVENING.x and hour < EVENING.y

## Shut: the mesh of wire down over the arch, as in the pictures. Open: no mesh -- the arch is an open doorway -- and
## the lamps of the shop lit.
func _states() -> void:
	var cx: float = _arch["cx"]
	var g: float = _arch["g"]
	var spring: float = _arch["spring"]
	var r: float = _arch["r"]
	var back: float = _arch["back"]
	var ceil: float = _arch["ceil"]
	_shut = Node3D.new()
	add_child(_shut)
	_xf = _arch["xf"]
	_mesh(cx, g + 0.03, spring, r - 0.01, -0.12, 0x4a4d52)
	box(cx - r, g + 0.03, -0.14, 2.0 * r, 0.06, 0.05, 0x4a4d52)
	home()
	_commit_to(_shut)
	_open = Node3D.new()
	add_child(_open)
	_xf = _arch["xf"]
	for zl in [-1.6, -3.4, -5.2]:                  # the strip lamps along its ceiling
		cbox(Vector3(cx, ceil - 0.04, zl), Vector3(0.14, 0.05, 1.1), "luz")
	home()
	_commit_to(_open)
	for zl in [-1.4, -4.4]:
		var lamp := OmniLight3D.new()
		lamp.position = (_arch["xf"] as Transform3D) * Vector3(cx, g + 2.3, zl)
		lamp.light_color = Color(1.0, 0.94, 0.82)
		lamp.omni_range = 4.2
		lamp.light_energy = 0.8
		add_child(lamp)
		_lights.append(lamp)
	set_open(false)

func _process(_delta: float) -> void:
	if not has_shop:
		return
	var game = W.get_parent() if W != null else null
	if game != null and "clock" in game and "weekday" in game:
		var want: bool = open_at(int(game.weekday), float(game.clock))
		if want != is_open:
			set_open(want)

func set_open(on: bool) -> void:
	is_open = on
	if tienda != null:
		tienda.open = on
	if _shut != null:
		_shut.visible = not on
		_open.visible = on
	for lamp in _lights:
		(lamp as Light3D).visible = on
	if _mats.has("interior"):
		(_mats["interior"] as StandardMaterial3D).emission_energy_multiplier = 0.5 if on else 0.06
