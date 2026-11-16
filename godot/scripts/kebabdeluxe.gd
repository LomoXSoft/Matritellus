extends "res://scripts/obra.gd"
## Kebab Deluxe (the user's name for it, 13 November 2026), the kebab house of the Avenida de Castilla-La Mancha, built
## by hand (the user, 16 November 2026: "Ponte ahora con Kebab Deluxe ... Arquitectónicamente y colores es exactamente
## el mismo [que La Meseta], solo quitaron los logos ... y pusieron su cartel en la fachada"). From Street View
## (November 2024, when it was still La Meseta) and the user's photo of it now.
##
## A narrow front of two floors painted midnight blue. Below, the shopfront in white: the glazed door of the stairs
## up, the double door under a transom of four pictures of burgers (one leaf open, as in the photo), a shallow bay of
## glass with the menus stuck inside; over it all the lit board with the name, what it sells and two telephone numbers
## (scribbles), and its lit sign hanging out over the pavement. Above, the great round-headed window in white; on the
## roof a terrace behind a steel rail and, at the left, the box of the stairs. Behind the glass the room, as the photo
## shows it: wooden floor, red benches, a television, the counter at the back. A bar stool by the door.
##
## It is the house `castilla_17` of the map (casas_calles.gd marks it "obra": casas.gd draws nothing of it). Frame:
## the house's own -- x along the front from its left end (seen from the avenue), z out to the avenue, y = 0 the
## pavement before its middle. The first stop of Don Luis's sabotage (sabotaje.gd) reads that house of the map: its
## pavement, up to 2.1 m out from the middle of the front, is left clear.

const HOUSE := "castilla_17"
const NAME := "Kebab Deluxe"
const SELLS := "PIZZAS · TACOS · POLLO ASADO"
const DIR := "res://assets/kebabdeluxe/"
const SHOP := 2.95                  # the top of the shopfront
const BOARD := 3.78                 # the top of the lit board over it
const SILL := 4.3                   # the great window: its foot...
const SPRING := 4.75                # ...where its round head begins...
const R := 2.15                     # ...and its radius
const CX := 2.85                    # ...and its middle
const TOP := 7.45                   # the top of the front
const TOWER := 9.7                  # the box of the stairs on the roof
const GLASS := -0.2                 # the shopfront's plane
const FLOOR := 0.12                 # the shop's floor, a step up
const NAVY := 0x232a3a
const WHITE := 0xf1eee6
const STEEL := 0xd9dcdf
const BLACK := 0x1a1a1c
const OPENS := 13.0                 # its hours (the user, 16 November 2026): from one in the afternoon every day...
const SHUTS := [1.5, 1.5, 1.5, 1.5, 2.0, 2.0, 2.0]      # ...to half past one in the night after Monday to Thursday, two after Friday to Sunday

var len_front := 5.75
var door: Vector2                   # before its door, on the map
var sign_at: Vector3                # the middle of its board, in the world (the self-test)
var is_open := true
var _shut: Node3D                   # what shows only while it is shut: the right leaf of the door, shut
var _open: Node3D                   # ...and while it is open: that leaf swung in
var _lights: Array = []
var _leaf := {}                     # where the door is, for _states

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"azul":             # the midnight-blue paint over the render
			m = Tex.mat("painted_plaster_wall", Color(0.26, 0.3, 0.42))
		"rotulo", "bandera", "montante":
			var sm := StandardMaterial3D.new()
			var t: Texture2D = load(DIR + String(key) + ".png")
			sm.albedo_texture = t
			sm.emission_enabled = true
			sm.emission_texture = t
			sm.emission = Color.WHITE
			sm.emission_energy_multiplier = 0.35 if key != "montante" else 0.25      # (lit, but it must keep its colours in the sun)
			sm.roughness = 1.0
			m = sm
		"cristal":
			var gm := StandardMaterial3D.new()
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.albedo_color = Color(0.72, 0.82, 0.88, 0.2)
			gm.roughness = 0.5
			gm.metallic_specular = 0.15      # (shiny glass shows the sky, and the window looks empty)
			gm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = gm
		"sala":             # the walls inside, lit
			var im := StandardMaterial3D.new()
			im.albedo_color = Color(0.93, 0.9, 0.84)
			im.emission_enabled = true
			im.emission = Color(0.95, 0.88, 0.76)
			im.emission_energy_multiplier = 0.35
			m = im
		"tarima":           # its wooden floor
			var fm := StandardMaterial3D.new()
			fm.albedo_color = Color(0.84, 0.7, 0.54)
			fm.emission_enabled = true
			fm.emission = Color(0.84, 0.7, 0.54)
			fm.emission_energy_multiplier = 0.25
			m = fm
		"rojo":             # the benches' red leatherette
			var rm := StandardMaterial3D.new()
			rm.albedo_color = Color(0.78, 0.1, 0.12)
			rm.emission_enabled = true
			rm.emission = Color(0.6, 0.06, 0.08)
			rm.emission_energy_multiplier = 0.3
			m = rm
		"luz":
			var lm := StandardMaterial3D.new()
			lm.albedo_color = Color(1.0, 0.97, 0.88)
			lm.emission_enabled = true
			lm.emission = Color(1.0, 0.94, 0.8)
			lm.emission_energy_multiplier = 2.0
			m = lm
		"pantalla":
			var pm := StandardMaterial3D.new()
			pm.albedo_color = Color(0.2, 0.45, 0.85)
			pm.emission_enabled = true
			pm.emission = Color(0.3, 0.55, 1.0)
			pm.emission_energy_multiplier = 1.2
			m = pm
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
	level = MapData.height(o + u * (len_front / 2.0) + out * 1.5)
	transform = Transform3D(Basis(Vector3(u.x, 0, u.y), Vector3.UP, Vector3(out.x, 0, out.y)), Vector3(o.x, level, o.y))
	W.add_child(self)
	door = spot(2.1, 1.4)
	var raw: Array = hd["pieces"][0]["ring"]
	var ring: Array = []
	for i in range(0, raw.size(), 2):
		var q: Vector3 = transform.affine_inverse() * Vector3(float(raw[i]), level, float(raw[i + 1]))
		ring.append(Vector2(q.x, q.z))
	_body(ring)
	_front()
	_shopfront()
	_boards()
	_window()
	_roof(ring)
	_inside()
	_street()
	home()
	_commit()
	_states()

# ---------------- the house ----------------
## its walls other than the front, from well under the ground to its top, and its flat roof
func _body(ring: Array) -> void:
	for i in range(ring.size()):
		var a: Vector2 = ring[i]
		var b: Vector2 = ring[(i + 1) % ring.size()]
		if absf(a.y) < 0.05 and absf(b.y) < 0.05:          # (the front: built on its own)
			continue
		if a.distance_to(b) < 0.05:
			continue
		_plain(a, b, -4.0, TOP, "azul")
		_plain(b, a, -4.0, TOP, "azul")
	home()
	var pts := PackedVector2Array()
	for q: Vector2 in ring:
		pts.append(q)
	flat(pts, TOP - 0.02, 0x8a8680)

## the front: the paint all over, with the shopfront's hole, the round-headed window's, and a blue plinth
func _front() -> void:
	home()
	masonry(0.0, len_front, -4.0, TOP, [Rect2(0.25, -4.0, 4.95, SHOP + 4.0), Rect2(CX - R, SILL, 2.0 * R, SPRING - SILL), Rect2(CX - R, SPRING, 2.0 * R, R)], [], "azul")
	spandrels(CX, SPRING, R, 0.0, "azul")
	box(-0.02, TOP - 0.08, -0.02, len_front + 0.04, 0.1, 0.12, 0x1c2230)            # its coping
	box(-0.01, -0.3, 0.0, 0.26, 0.42, 0.03, 0x1c2230)                                 # (a darker foot, where the paint is scuffed)
	box(5.2, -0.3, 0.0, len_front - 5.2, 0.42, 0.03, 0x1c2230)

# ---------------- the shopfront ----------------
## a frame of white round a pane: `r` on the plane z, `bars` its glazing bars (columns, rows)
func _pane(r: Rect2, z: float, cols: int, rows: int, frame := 0.07) -> void:
	box(r.position.x, r.position.y, z - 0.01, r.size.x, r.size.y, 0.008, "cristal")
	for q in [[r.position.x, r.position.y, frame, r.size.y], [r.end.x - frame, r.position.y, frame, r.size.y], [r.position.x, r.position.y, r.size.x, frame], [r.position.x, r.end.y - frame, r.size.x, frame]]:
		box(q[0], q[1], z - 0.03, q[2], q[3], 0.06, WHITE)
	for c in range(1, cols):
		box(r.position.x + r.size.x * c / cols - 0.018, r.position.y, z - 0.02, 0.036, r.size.y, 0.04, WHITE)
	for k in range(1, rows):
		box(r.position.x, r.position.y + r.size.y * k / rows - 0.018, z - 0.02, r.size.x, 0.036, 0.04, WHITE)

func _shopfront() -> void:
	var g := GLASS
	box(0.25, -0.3, g - 0.05, 4.95, FLOOR + 0.3, 0.3, 0x8a8680)                     # the step, its black nosing
	box(0.25, FLOOR - 0.02, g + 0.2, 4.95, 0.025, 0.06, BLACK)
	box(0.25, SHOP - 0.12, g - 0.04, 4.95, 0.12, 0.1, WHITE)                          # the head of the frame
	for x in [0.25, 1.17, 3.0, 5.12]:                                                # its posts
		box(x, FLOOR, g - 0.04, 0.08, SHOP - FLOOR, 0.1, WHITE)
	# the door of the stairs: tall, glazed in small panes, a white panel at its foot
	_pane(Rect2(0.33, FLOOR + 0.42, 0.84, 2.3 - 0.42), g, 3, 5)
	box(0.33, FLOOR, g - 0.03, 0.84, 0.42, 0.05, WHITE)
	_pane(Rect2(0.33, FLOOR + 2.3, 0.84, SHOP - 0.12 - FLOOR - 2.3), g, 1, 1)
	box(1.05, FLOOR + 1.0, g + 0.03, 0.03, 0.22, 0.03, 0x8a8d90)
	# the double door: the left leaf shut, the right one open into the shop, as the photo has them
	var dx0 := 1.25
	var leaf := 0.86
	_pane(Rect2(dx0, FLOOR + 0.12, leaf, 2.2), g, 2, 4)
	box(dx0, FLOOR, g - 0.03, leaf, 0.12, 0.05, WHITE)
	box(dx0 + leaf - 0.1, FLOOR + 0.95, g + 0.04, 0.03, 0.4, 0.03, 0x26262a)
	_leaf = {"x": dx0 + 2.0 * leaf, "w": leaf, "g": g}       # (its right leaf: shut, or swung in -- _states)
	# the transom over the doors: four pictures of burgers behind the glass
	var t0 := FLOOR + 2.32
	var t1 := SHOP - 0.12
	quad(Vector3(dx0, t0, g - 0.04), Vector3(dx0 + 2.0 * leaf, t0, g - 0.04), Vector3(dx0 + 2.0 * leaf, t1, g - 0.04), Vector3(dx0, t1, g - 0.04), "montante", Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	_pane(Rect2(dx0, t0, 2.0 * leaf, t1 - t0), g + 0.01, 4, 1)
	# the bay: three tall panes coming out a hand from the front, a low white panel under them, the menus inside
	var b0 := 3.08
	var b1 := 5.12
	var out := 0.24
	box(b0, FLOOR, g + out - 0.05, b1 - b0, 0.55, 0.06, WHITE)
	for k in range(3):
		var x0: float = b0 + k * (b1 - b0) / 3.0
		_pane(Rect2(x0, FLOOR + 0.55, (b1 - b0) / 3.0, 1.8), g + out, 1, 3)
		_pane(Rect2(x0, FLOOR + 2.35, (b1 - b0) / 3.0, SHOP - 0.12 - FLOOR - 2.35), g + out, 1, 1)
	for x in [b0, b1 - 0.07]:                                                        # its returns to the front
		box(x, FLOOR, g, 0.07, SHOP - 0.12 - FLOOR, out, WHITE)
	box(b0, SHOP - 0.14, g, b1 - b0, 0.08, out, WHITE)
	for q in [[3.25, 1.2, 0.36, 0.5], [3.7, 1.35, 0.3, 0.42], [4.35, 1.0, 0.42, 0.6], [4.8, 1.5, 0.22, 0.3]]:      # the menus and posters stuck inside
		quad(Vector3(q[0], FLOOR + q[1], g + out - 0.03), Vector3(q[0] + q[2], FLOOR + q[1], g + out - 0.03), Vector3(q[0] + q[2], FLOOR + q[1] + q[3], g + out - 0.03), Vector3(q[0], FLOOR + q[1] + q[3], g + out - 0.03),
			"montante", Vector3(0, 0, 1), [Vector2(0.25 * (int(q[0] * 10) % 4), 1), Vector2(0.25 * (int(q[0] * 10) % 4) + 0.25, 1), Vector2(0.25 * (int(q[0] * 10) % 4) + 0.25, 0), Vector2(0.25 * (int(q[0] * 10) % 4), 0)])
	solid(Vector3((b0 + b1) / 2.0, 1.2, g + out / 2.0), Vector3(b1 - b0, 2.4, out + 0.1))
	solid(Vector3(len_front / 2.0, 1.4, g - 0.1), Vector3(len_front, 2.8, 0.2))
	# the light in the ceiling of the doorway
	drum(Vector3(2.1, SHOP - 0.03, g + 0.12), 0.12, 0.12, 0.02, "luz", 10)

# ---------------- the boards ----------------
func _boards() -> void:
	var x0 := 0.15
	var x1 := len_front - 0.25
	box(x0, SHOP, 0.0, x1 - x0, BOARD - SHOP, 0.14, BLACK)
	quad(Vector3(x0 + 0.04, SHOP + 0.04, 0.142), Vector3(x1 - 0.04, SHOP + 0.04, 0.142), Vector3(x1 - 0.04, BOARD - 0.04, 0.142), Vector3(x0 + 0.04, BOARD - 0.04, 0.142), "rotulo", Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	sign_at = transform * Vector3((x0 + x1) / 2.0, (SHOP + BOARD) / 2.0, 0.14)
	# the sign hanging out over the pavement at the right, lit on both faces, on its bracket
	var x := len_front - 0.12
	var y0 := 3.12
	var y1 := 3.72
	var z0 := 0.22
	var z1 := 1.12
	box(x - 0.04, y0 - 0.02, z0 - 0.02, 0.08, y1 - y0 + 0.04, z1 - z0 + 0.04, BLACK)
	box(x - 0.02, y1 + 0.02, 0.0, 0.04, 0.04, z1 - 0.05, BLACK)
	var uv := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	quad(Vector3(x + 0.041, y0, z1), Vector3(x + 0.041, y0, z0), Vector3(x + 0.041, y1, z0), Vector3(x + 0.041, y1, z1), "bandera", Vector3(1, 0, 0), uv)
	quad(Vector3(x - 0.041, y0, z0), Vector3(x - 0.041, y0, z1), Vector3(x - 0.041, y1, z1), Vector3(x - 0.041, y1, z0), "bandera", Vector3(-1, 0, 0), uv)
	# the floodlight over the board at the left, and the bundle of cables along its top, as dirty as it is
	box(0.35, BOARD + 0.12, 0.0, 0.05, 0.05, 0.3, BLACK)
	cbox(Vector3(0.38, BOARD + 0.1, 0.32), Vector3(0.2, 0.14, 0.08), 0x2a2a2c)
	bar(Vector3(-0.3, BOARD + 0.08, 0.03), Vector3(len_front + 0.3, BOARD + 0.05, 0.03), 0.05, 0.05, BLACK)
	bar(Vector3(len_front - 0.4, BOARD + 0.05, 0.03), Vector3(len_front - 0.6, BOARD + 0.55, 0.03), 0.03, 0.03, BLACK)

# ---------------- upstairs ----------------
## the great window: glass, a white frame round its foot and its round head, white bars clipped to it, a panel of
## white across its foot
func _window() -> void:
	var z := -DEEP + 0.08
	arched(CX, SILL, SPRING, R, z - 0.02, "cristal")
	box(CX - R, SILL, z - 0.02, 2.0 * R, SPRING - SILL, 0.01, "cristal")
	box(CX - R, SILL, z - 0.03, 2.0 * R, 0.36, 0.06, WHITE)
	ring(CX, SPRING, R - 0.09, R, z, 0.1, WHITE, 18)
	for x in [CX - R, CX + R - 0.09]:
		box(x, SILL, z - 0.03, 0.09, SPRING - SILL, 0.08, WHITE)
	for k in range(1, 8):                                                             # its uprights, up to the arch
		var x: float = CX - R + 2.0 * R * k / 8.0
		var top: float = SPRING + sqrt(maxf(R * R - (x - CX) * (x - CX), 0.0)) - 0.06
		box(x - 0.025, SILL + 0.36, z - 0.02, 0.05, top - SILL - 0.36, 0.05, WHITE)
	for y in [SILL + 0.36, SPRING + 0.35, SPRING + 1.2]:                               # and across
		var half: float = sqrt(maxf(R * R - maxf(y - SPRING, 0.0) * maxf(y - SPRING, 0.0), 0.0)) - 0.06
		box(CX - half, y - 0.025, z - 0.02, 2.0 * half, 0.05, 0.05, WHITE)
	box(CX - R - 0.05, SILL - 0.06, 0.0, 2.0 * R + 0.1, 0.06, 0.1, 0x1c2230)             # its sill
	# what is behind it: the room upstairs, lit a little
	box(CX - R, SILL - 0.4, -2.4, 2.0 * R, SPRING + R - SILL + 0.4, 0.02, "sala")
	box(CX - R, SILL - 0.05, -2.4, 2.0 * R, 0.05, 2.4 - DEEP, "tarima")

## the roof: the terrace behind a steel rail along the front and the right, and the box of the stairs at the left
func _roof(ring: Array) -> void:
	var back := -4.6
	var tx := 1.5
	box(0.0, TOP, back, tx, TOWER - TOP, -back, "azul")
	box(-0.02, TOWER - 0.06, back - 0.02, tx + 0.04, 0.08, -back + 0.04, 0x1c2230)
	box(tx - 0.02, TOP, -3.2, 0.03, 2.1, 0.9, WHITE)                                   # its door on to the terrace
	solid(Vector3(tx / 2.0, (TOP + TOWER) / 2.0, back / 2.0), Vector3(tx, TOWER - TOP, -back))
	var right: float = 0.0                                                          # where the right-hand wall is, that deep
	for i in range(ring.size()):
		var a: Vector2 = ring[i]
		var b: Vector2 = ring[(i + 1) % ring.size()]
		if a.x > len_front - 0.3 and a.y > -0.05 and b.y < a.y:
			right = lerpf(a.x, b.x, clampf(back / (b.y - a.y), 0.0, 1.0))
	if right <= 0.0:
		right = len_front
	var runs: Array = [[Vector3(tx, TOP, -0.08), Vector3(len_front - 0.08, TOP, -0.08)], [Vector3(len_front - 0.08, TOP, -0.08), Vector3(right - 0.08, TOP, back)], [Vector3(right - 0.08, TOP, back), Vector3(tx, TOP, back)]]
	for run in runs:
		var a: Vector3 = run[0]
		var b: Vector3 = run[1]
		var n := maxi(1, int(ceil(a.distance_to(b) / 1.2)))
		for k in range(n + 1):
			var p: Vector3 = a.lerp(b, float(k) / n)
			box(p.x - 0.02, TOP, p.z - 0.02, 0.04, 1.05, 0.04, STEEL)
		for y in [0.45, 1.03]:
			bar(a + Vector3(0, y, 0), b + Vector3(0, y, 0), 0.035, 0.035, STEEL)

# ---------------- inside, as seen through the glass ----------------
func _inside() -> void:
	var back := -6.5
	var c := SHOP + 0.05
	var x0 := 1.24
	var x1 := 5.18
	quad(Vector3(x0, FLOOR, back), Vector3(x1, FLOOR, back), Vector3(x1, FLOOR, GLASS), Vector3(x0, FLOOR, GLASS), "tarima", Vector3.UP)
	for k in range(1, 18):                                                            # its boards
		box(x0, FLOOR, back + k * 0.36, x1 - x0, 0.004, 0.01, 0xa88a68)
	quad(Vector3(x0, c, back), Vector3(x1, c, back), Vector3(x1, c, GLASS), Vector3(x0, c, GLASS), "sala", Vector3.DOWN)
	quad(Vector3(x0, FLOOR, back), Vector3(x1, FLOOR, back), Vector3(x1, c, back), Vector3(x0, c, back), "sala", Vector3(0, 0, 1))
	quad(Vector3(x0, FLOOR, back), Vector3(x0, FLOOR, GLASS), Vector3(x0, c, GLASS), Vector3(x0, c, back), "sala", Vector3(1, 0, 0))
	quad(Vector3(x1, FLOOR, back), Vector3(x1, FLOOR, GLASS), Vector3(x1, c, GLASS), Vector3(x1, c, back), "sala", Vector3(-1, 0, 0))
	for z in [-1.4, -3.4]:                                                          # its lamps
		cbox(Vector3((x0 + x1) / 2.0, c - 0.03, z), Vector3(0.5, 0.04, 0.5), "luz")
	# the red benches along the right-hand wall, back to back, a dark table between each pair
	for k in range(3):
		var z: float = -1.3 - k * 1.65
		for side in [-1.0, 1.0]:
			var bz: float = z + side * 0.55
			box(x1 - 1.3, FLOOR, bz - 0.22, 1.3, 0.45, 0.44, "rojo")
			box(x1 - 1.3, FLOOR + 0.45, bz + side * 0.2 - 0.06, 1.3, 0.6, 0.12, "rojo")
			box(x1 - 1.3, FLOOR, bz - 0.22, 1.3, 0.12, 0.44, 0x6a4a3a)
		box(x1 - 1.2, FLOOR + 0.72, z - 0.33, 1.1, 0.04, 0.66, 0x3a3030)
		box(x1 - 0.68, FLOOR, z - 0.04, 0.08, 0.72, 0.08, 0x26262a)
	# the counter across the back, black, with the bright boards of the menu over it
	box(x0, FLOOR, back + 0.3, 2.3, 1.05, 0.6, BLACK)
	box(x0, FLOOR + 1.05, back + 0.25, 2.3, 0.04, 0.7, 0x8a8680)
	for k in range(3):
		quad(Vector3(x0 + 0.1 + k * 0.75, FLOOR + 1.75, back + 0.02), Vector3(x0 + 0.75 + k * 0.75, FLOOR + 1.75, back + 0.02), Vector3(x0 + 0.75 + k * 0.75, FLOOR + 2.4, back + 0.02), Vector3(x0 + 0.1 + k * 0.75, FLOOR + 2.4, back + 0.02),
			"montante", Vector3(0, 0, 1), [Vector2(0.25 * k, 1), Vector2(0.25 * k + 0.25, 1), Vector2(0.25 * k + 0.25, 0), Vector2(0.25 * k, 0)])
	# the television up on the left-hand wall, playing
	box(x0 + 0.02, FLOOR + 1.85, -1.9, 0.08, 0.5, 0.85, BLACK)
	box(x0 + 0.105, FLOOR + 1.88, -1.87, 0.005, 0.44, 0.79, "pantalla")
	# behind the door of the stairs: the steps going up and away, between white walls
	for k in range(14):
		box(0.33, FLOOR + k * 0.18, -0.6 - k * 0.27, 0.84, 0.18, 0.27 + 0.02, 0x9a958c)
	quad(Vector3(0.3, FLOOR, -5.0), Vector3(0.3, FLOOR, GLASS), Vector3(0.3, c + 2.5, GLASS), Vector3(0.3, c + 2.5, -5.0), "sala", Vector3(1, 0, 0))
	quad(Vector3(1.2, FLOOR, -5.0), Vector3(1.2, FLOOR, GLASS), Vector3(1.2, c + 2.5, GLASS), Vector3(1.2, c + 2.5, -5.0), "sala", Vector3(-1, 0, 0))
	quad(Vector3(0.3, c - 0.02, -0.5), Vector3(1.2, c - 0.02, -0.5), Vector3(1.2, c - 0.02, GLASS), Vector3(0.3, c - 0.02, GLASS), "sala", Vector3.DOWN)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3((x0 + x1) / 2.0, 2.4, -2.5)
	lamp.light_color = Color(1.0, 0.92, 0.8)
	lamp.omni_range = 5.0
	lamp.light_energy = 0.7
	lamp.shadow_enabled = false
	add_child(lamp)
	_lights.append(lamp)

## the bar stool by the door, at the left (out of the way of what is brought to the door)
func _street() -> void:
	var o := Vector3(0.55, 0.0, 0.42)
	for k in range(4):
		var a: float = TAU * k / 4.0 + PI / 4.0
		bar(o + Vector3(cos(a) * 0.17, 0, sin(a) * 0.17), o + Vector3(cos(a) * 0.1, 0.7, sin(a) * 0.1), 0.025, 0.025, BLACK)
	drum(o + Vector3(0, 0.25, 0), 0.15, 0.15, 0.02, BLACK, 10)
	drum(o + Vector3(0, 0.7, 0), 0.18, 0.18, 0.06, 0x2a2a2c, 12)
	bar(o + Vector3(-0.14, 0.72, -0.12), o + Vector3(-0.14, 1.05, -0.14), 0.025, 0.025, BLACK)
	bar(o + Vector3(0.14, 0.72, -0.12), o + Vector3(0.14, 1.05, -0.14), 0.025, 0.025, BLACK)
	bar(o + Vector3(-0.14, 1.0, -0.14), o + Vector3(0.14, 1.0, -0.14), 0.05, 0.08, 0x2a2a2c)
	solid(o + Vector3(0, 0.5, 0), Vector3(0.4, 1.0, 0.4))
	yard.append(spot(o.x, o.z))

# ---------------- open and shut ----------------
## what has been built since the last commit becomes meshes under `node`: a part that can be shown and hidden
func _commit_to(node: Node3D) -> void:
	for key in _tools:
		var mi := MeshInstance3D.new()
		mi.mesh = (_tools[key] as SurfaceTool).commit()
		mi.material_override = _material(key)
		node.add_child(mi)
	_tools.clear()

## the right leaf of the door: shut in its frame, or swung in against the bay, as in the user's photo
func _states() -> void:
	var x: float = _leaf["x"]
	var w: float = _leaf["w"]
	var g: float = _leaf["g"]
	_shut = Node3D.new()
	add_child(_shut)
	home()
	_xf = Transform3D(Basis(), Vector3(x, 0.0, g))
	_pane(Rect2(-w, FLOOR + 0.12, w, 2.2), 0.0, 2, 4)
	box(-w, FLOOR, -0.03, w, 0.12, 0.05, WHITE)
	box(-w + 0.08, FLOOR + 0.95, 0.03, 0.03, 0.4, 0.03, 0x26262a)
	home()
	_commit_to(_shut)
	_open = Node3D.new()
	add_child(_open)
	_xf = Transform3D(Basis(Vector3.UP, 1.25), Vector3(x, 0.0, g))
	_pane(Rect2(-w, FLOOR + 0.12, w, 2.2), 0.0, 2, 4)
	box(-w, FLOOR, -0.03, w, 0.12, 0.05, WHITE)
	box(-w + 0.08, FLOOR + 0.95, 0.03, 0.03, 0.4, 0.03, 0x26262a)
	home()
	_commit_to(_open)
	set_open(open_at(0, 14.0))

## whether it is open on that day of the week (0 Monday ... 6 Sunday) at that hour (the small hours belong to the
## day before: at one in the night of a Tuesday it is still Monday's opening)
func open_at(day: int, hour: float) -> bool:
	if hour >= OPENS:
		return true
	return hour < float(SHUTS[posmod(day - 1, 7)])

func _process(_delta: float) -> void:
	var game = W.get_parent() if W != null else null
	if game != null and "clock" in game and "weekday" in game:
		var want: bool = open_at(int(game.weekday), float(game.clock))
		if want != is_open:
			set_open(want)

## open: the leaf swung in, the lights on, the boards lit; shut: the door shut and everything dark
func set_open(on: bool) -> void:
	is_open = on
	if _shut != null:
		_shut.visible = not on
		_open.visible = on
	for lamp in _lights:
		(lamp as Light3D).visible = on
	for key in ["rotulo", "bandera"]:           # lit: its own colours whatever the light (glowing on top of the sun only washes them out); off: lit like the wall
		if _mats.has(key):
			var bm := _mats[key] as StandardMaterial3D
			bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if on else BaseMaterial3D.SHADING_MODE_PER_PIXEL
			bm.emission_energy_multiplier = 0.0
	for q in [["montante", 0.25], ["sala", 0.35], ["tarima", 0.25], ["rojo", 0.3], ["luz", 2.0], ["pantalla", 1.2]]:
		if _mats.has(q[0]):
			(_mats[q[0]] as StandardMaterial3D).emission_energy_multiplier = float(q[1]) if on else 0.0
