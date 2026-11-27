extends "res://scripts/obra.gd"
## The corner house of the Calle del Teniente Infante and the Calle de San Francisco, and the three shops on its ground
## floor (the user, 17 November 2026: "la copistería xijote (que llamaremos copistería Sancho panza) y el banco
## Santander (que llamaremos banco Cantabria). Ambos comparten C. Teniente Infante, 8 ... partiendo la planta baja,
## debajo de unos pisos"; and, with his picture marked 1, 2, 3: the bank, the copy shop, the electrician's).
## Texturas's house sfran_b004 (Catastro 4190004VJ5649S), handed over to be built by hand.
##
## Three floors of cream render, the two upper ones standing a metre out over the pavement on both streets, windows in
## white frames with their roller blinds, small iron balconies, a balcony swelling round the corner on each floor. On
## the ground floor, from the corner: the bank in grey granite under its red band (our name and our emblem: a ring with
## the waves of the sea), its windows of posters, its door, its cash machine, the red box sign at the corner; the copy
## shop in bare brick under low arches -- the wooden door of the flats, its glass door, its window with its panel and a
## donkey of our own; the electrician's in white with his signs (what he does, no name). On the Calle de San Francisco,
## past the bank, the flats' other door, a door of mesh under two air conditioners, a barred window.
## Hours (the user, 17 Nov 2026: "Esos horarios están bien"): the bank Monday to Friday 8:30 to 14:30; the copy shop Monday to
## Friday 9:30 to 14:00 and 17:00 to 20:30, Saturday 10:00 to 13:30; the electrician Monday to Friday 9:00 to 14:00 and
## 17:00 to 20:00. Open: lit inside, the copy shop's "ABIERTO"; shut: dark, "CERRADO". The cash machine is always lit.
##
## Frame: origin at the corner, +x along the Teniente Infante westwards, +z out of it (north). y = 0 the bank's floor.
## Measured: referencias/bancosancho/LEEME.md, tools/bancosancho/.

const HOUSE := "sfran_b004"
const DentroS = preload("res://scripts/copisteria_dentro.gd")
const BancoS = preload("res://scripts/banco_dentro.gd")
const BANK := "Banco Cantabria"
const SHOP := "Copistería Sancho Panza"
const DIR := "res://assets/bancosancho/"
const O := Vector2(-92.48, 107.84)        # the corner (Catastro)
const U := Vector2(-0.99293, 0.11946)     # along the Teniente Infante, westwards
const LONG := 31.14                       # the front on the Teniente Infante
const SF_END := Vector2(3.27, -16.0)      # the south end of its front on the San Francisco, in this frame
const FLY := 0.97                         # the upper floors stand this far out over the pavement
const GF := 3.25                          # the underside of the upper floors
const F1 := 3.55
const F2 := 6.45
const TOP := 9.3
const DOWN := -3.0
# the ground floor along the Teniente Infante, metres from the corner
const BANK_END := 15.6                    # the granite...
const BAND_END := 14.8                    # ...its red band
const BRICK_END := 24.0                   # the copy shop's brick
const WOOD_DOOR := [16.3, 18.3]
const GLASS_DOOR := [19.4, 20.8]
const SHOP_WIN := [21.5, 23.6]
const BANK_DOOR := [6.4, 8.7]
const BANK_WINS: Array = [[1.9, 3.7], [10.2, 12.2]]
# windows of the two upper floors: their middles along the Teniente Infante, along the San Francisco (from the corner);
# a "b" is a balcony
const TI_WINS: Array = [[3.5, ""], [7.2, ""], [10.5, ""], [13.9, "b"], [17.3, ""], [20.8, ""], [24.0, ""], [27.2, "b"], [30.0, ""]]
const SF_WINS: Array = [[4.6, ""], [8.0, ""], [11.3, "b"], [14.6, ""]]
const RED := 0xda2226
const WHITE := 0xf2f0ea
const HIERRO := 0x26262a
const WOOD := 0x5a3a24
const BLIND := 0x7a6a5a

var door: Vector2                         # before the copy shop's door, on the map (the Recress mission's copy shop)
var bank_door: Vector2
var cajero_spot: Vector2                  # the bank's cash machine: where you stand at it, on the map...
var cajero_face := 0.0                    # ...which way you look there (a heading, as out_h: atan2(x, z))...
var cajero_at: Vector3                    # ...and where its screen is, in the world
var bank_open := true
var shop_open := true
var elec_open := true
var outline: PackedVector2Array
var tienda                                # the copy shop's inside, a set apart (copisteria_dentro.gd): what you go into from its glass door
var banco                                 # the bank's inside, a set apart (banco_dentro.gd): what you go into from its glass door, in its hours
var _rooms := {}                          # "banco"/"copia"/"elec" -> Node3D of what shows only while open
var _shut := {}                           # ...and only while shut

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"crema":
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.1, 1.04, 0.94)), 0.28)      # (pale cream: it must read so in the shade of the Teniente Infante)
		"blanco":
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 1.0, 0.98)), 0.22)
		"granito":          # the bank's grey granite
			m = Tex.mat("granular_concrete", Color(1.04, 1.04, 1.03))                       # (a pale grey, as it is)
		"ladrillo":         # the copy shop's bare brick: pale, more salmon than orange
			m = Tex.mat("brick_wall_003@1.15", Color(1.24, 1.2, 1.24))                       # (pushing up the blue takes the orange out)
		"banco", "banco_cubo", "cartel_banco", "copisteria", "electricidad", "energia", "cajero":
			var tm := StandardMaterial3D.new()
			tm.albedo_texture = load(DIR + String(key) + ".png")
			tm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			tm.roughness = 0.6
			if key == "cajero":
				tm.emission_enabled = true
				tm.emission_texture = tm.albedo_texture
				tm.emission = Color.WHITE
				tm.emission_energy_multiplier = 0.6
			m = tm
		"cristal":
			var gm := StandardMaterial3D.new()
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.albedo_color = Color(0.3, 0.36, 0.38, 0.45)
			gm.roughness = 0.3                       # (not a mirror of the sky: the bank's posters show through it)
			gm.metallic_specular = 0.35
			gm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = gm
		"sala_banco", "sala_copia", "sala_elec":       # the rooms behind the glass, lit while open
			var sm := StandardMaterial3D.new()
			sm.albedo_color = Color(0.82, 0.82, 0.8)
			sm.emission_enabled = true
			sm.emission = Color(0.96, 0.95, 0.9)
			sm.emission_energy_multiplier = 0.35
			m = sm
		"pantalla":         # the cash machine's screen, lit
			var pm := StandardMaterial3D.new()
			pm.albedo_color = Color(0.16, 0.36, 0.62)
			pm.emission_enabled = true
			pm.emission = Color(0.2, 0.45, 0.8)
			pm.emission_energy_multiplier = 0.9
			m = pm
		"luz_verde":        # the light over its card slot
			var vl := StandardMaterial3D.new()
			vl.albedo_color = Color(0.3, 0.95, 0.4)
			vl.emission_enabled = true
			vl.emission = Color(0.3, 1.0, 0.4)
			vl.emission_energy_multiplier = 1.6
			m = vl
		"luz":
			var lm := StandardMaterial3D.new()
			lm.albedo_color = Color(1.0, 0.98, 0.93)
			lm.emission_enabled = true
			lm.emission = Color(1.0, 0.97, 0.9)
			lm.emission_energy_multiplier = 1.5
			m = lm
		"visillo":
			var vm := StandardMaterial3D.new()
			vm.albedo_color = Color(0.9, 0.9, 0.88)
			m = vm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	_frame(0.0)
	var top := -1e9
	for x in [1.0, 5.0, 9.0, 13.0]:
		top = maxf(top, MapData.height(spot(x, 0.6)))
	level = top + 0.1
	_frame(level)
	W.add_child(self)
	door = spot((GLASS_DOOR[0] + GLASS_DOOR[1]) / 2.0, 1.0)
	bank_door = spot((BANK_DOOR[0] + BANK_DOOR[1]) / 2.0, 1.0)
	cajero_spot = spot(CAJERO_X + CAJERO_W / 2.0, 0.8)
	cajero_face = atan2(U.y, -U.x)                        # (into the wall: the frame's -z)
	cajero_at = transform * Vector3(CAJERO_X + CAJERO_W / 2.0, 1.56, 0.1)
	_upper_ti()
	_upper_sf()
	_corner()
	_bank()
	_brick()
	_electrician()
	_sf_ground()
	_body()
	home()
	_commit()
	_states()
	var gx: float = (GLASS_DOOR[0] + GLASS_DOOR[1]) / 2.0
	var n := Vector2(-U.y, U.x)
	tienda = DentroS.new()                                # (its door a little inside the glass: the arrow 1.1 m out stays on the narrow pavement)
	tienda.build(world, spot(gx, -0.45), spot(gx, 1.2), atan2(n.x, n.y))
	var bx: float = (BANK_DOOR[0] + BANK_DOOR[1]) / 2.0
	banco = BancoS.new()                                  # (the same: its door a little inside the glass)
	banco.build(world, spot(bx, -0.45), spot(bx, 1.2), atan2(n.x, n.y))
	_tell_map()
	set_open(open_at("banco", 0, 11.0), open_at("copia", 0, 11.0), open_at("elec", 0, 11.0))

func _frame(y: float) -> void:
	transform = Transform3D(Basis(Vector3(U.x, 0, U.y), Vector3.UP, Vector3(-U.y, 0, U.x)), Vector3(O.x, y, O.y))

func _fr(p: Vector2) -> Vector2:
	var r := p - O
	return Vector2(r.dot(U), r.dot(Vector2(-U.y, U.x)))

## the pavement under the Teniente Infante's front, at x: how far below the floor
func _foot(x: float) -> float:
	return minf(ground(x, 0.3), ground(x, 0.9))

func _picture(x0: float, x1: float, y0: float, y1: float, z: float, key) -> void:
	pieces += 1
	quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

func _solid(x0: float, y0: float, z0: float, x1: float, y1: float, z1: float) -> void:
	solid(Vector3((x0 + x1) / 2.0, (y0 + y1) / 2.0, (z0 + z1) / 2.0), Vector3(absf(x1 - x0), absf(y1 - y0), absf(z1 - z0)))

# ---------------- the upper floors ----------------
## one window of the upper floors on the face being built: a white frame, the glass, the blind half down, its sill;
## with `bal`, a door on to a little iron balcony
func _window(cx: float, y: float, bal: bool) -> void:
	var w := 1.0 if bal else 1.1
	var y0: float = y + (0.05 if bal else 0.95)
	var y1: float = y + 2.3
	box(cx - w / 2.0 - 0.14, y0 - 0.1, 0.0, w + 0.28, 0.12, 0.08, WHITE)                  # its frame of white
	box(cx - w / 2.0 - 0.14, y1, 0.0, w + 0.28, 0.14, 0.06, WHITE)
	box(cx - w / 2.0 - 0.14, y0, 0.0, 0.14, y1 - y0, 0.06, WHITE)
	box(cx + w / 2.0, y0, 0.0, 0.14, y1 - y0, 0.06, WHITE)
	box(cx - w / 2.0, y0, -0.18, w, y1 - y0, 0.02, "visillo")
	box(cx - 0.02, y0, -0.16, 0.04, y1 - y0, 0.04, 0xf4f2ec)
	var blind: float = (y1 - y0) * (0.45 if not bal else 0.35)
	box(cx - w / 2.0, y1 - blind, -0.12, w, blind, 0.03, BLIND)
	for k in range(int(blind / 0.08)):
		box(cx - w / 2.0, y1 - blind + k * 0.08, -0.09, w, 0.012, 0.01, 0x5a4a3c)
	if bal:
		box(cx - 0.85, y, 0.0, 1.7, 0.12, 0.5, 0xd9d4c8)                                  # the slab and its railing
		for x in [cx - 0.82, cx + 0.79]:
			box(x, y + 0.12, 0.0, 0.03, 0.95, 0.47, HIERRO)
		box(cx - 0.85, y + 1.05, 0.44, 1.7, 0.04, 0.04, HIERRO)
		box(cx - 0.85, y + 1.05, 0.0, 0.04, 0.04, 0.47, HIERRO)
		box(cx + 0.81, y + 1.05, 0.0, 0.04, 0.04, 0.47, HIERRO)
		var bx: float = cx - 0.8
		while bx < cx + 0.8:
			box(bx, y + 0.12, 0.45, 0.018, 0.93, 0.018, HIERRO)
			bx += 0.11
	else:
		box(cx - w / 2.0 - 0.18, y0 - 0.14, 0.0, w + 0.36, 0.05, 0.14, WHITE)

## the upper floors' face on the Teniente Infante: a metre out, render between its floors' moulded bands
func _upper_ti() -> void:
	var a := Vector2(-0.31, FLY)
	var b := Vector2(LONG + 0.01, FLY)
	var ln: float = face(a, b)
	box(0.0, GF, -0.25, ln, TOP - GF, 0.25, "crema")
	box(-0.02, GF, 0.0, ln + 0.04, 0.3, 0.1, WHITE)                                        # the band under it, moulded
	box(-0.02, GF - 0.05, -FLY, ln + 0.04, 0.05, FLY, 0xd9d4c8)                           # its underside
	box(-0.02, F2 - 0.04, 0.0, ln + 0.04, 0.08, 0.05, 0xdcd2c0)
	box(-0.03, TOP, -0.3, ln + 0.06, 0.25, 0.4, WHITE)                                    # the cornice and its parapet
	box(0.0, TOP + 0.25, -0.25, ln, 0.5, 0.25, "crema")
	box(-0.02, TOP + 0.75, -0.27, ln + 0.04, 0.05, 0.29, 0xd9d4c8)
	for w in TI_WINS:
		var x: float = float(w[0]) + 0.31
		for y in [F1, F2]:
			_window(x, y, String(w[1]) == "b")
	home()
	_solid(-0.31, GF, -0.4, LONG, TOP, FLY)

## the same on the San Francisco
func _upper_sf() -> void:
	var a := SF_END + Vector2(-0.87, -0.18)
	var b := Vector2(-0.93, 0.13)
	var ln: float = face(a, b)
	box(0.0, GF, -0.25, ln, TOP - GF, 0.25, "crema")
	box(-0.02, GF, 0.0, ln + 0.04, 0.3, 0.1, WHITE)
	box(-0.02, GF - 0.05, -0.9, ln + 0.04, 0.05, 0.9, 0xd9d4c8)
	box(-0.02, F2 - 0.04, 0.0, ln + 0.04, 0.08, 0.05, 0xdcd2c0)
	box(-0.03, TOP, -0.3, ln + 0.06, 0.25, 0.4, WHITE)
	box(0.0, TOP + 0.25, -0.25, ln, 0.5, 0.25, "crema")
	for w in SF_WINS:
		var x: float = ln - float(w[0])
		for y in [F1, F2]:
			_window(x, y, String(w[1]) == "b")
	home()

## the corner: the short wall cut across it, and on each floor a balcony swelling round it, a door on to it
func _corner() -> void:
	var a := Vector2(-0.93, 0.13)
	var b := Vector2(-0.31, FLY)
	var ln: float = face(a, b)
	box(-0.05, GF, -0.25, ln + 0.1, TOP + 0.75 - GF, 0.25, "crema")
	box(-0.05, TOP, -0.3, ln + 0.1, 0.25, 0.4, WHITE)
	for y in [F1, F2]:
		box(ln / 2.0 - 0.45, y + 0.05, -0.18, 0.9, 2.2, 0.02, "visillo")
		box(ln / 2.0 - 0.5, y + 0.05, 0.0, 0.08, 2.25, 0.05, WHITE)
		box(ln / 2.0 + 0.42, y + 0.05, 0.0, 0.08, 2.25, 0.05, WHITE)
		box(ln / 2.0 - 0.45, y + 1.5, -0.12, 0.9, 0.75, 0.03, BLIND)
	home()
	# the balcony round the corner: its outline in this frame, filleted round the corner's turn
	var k := Vector2(-2.204, 1.87)
	var t1 := Vector2(-0.614, 1.87)
	var t2 := Vector2(-1.886, 0.312)
	var c := Vector2(-0.614, 0.57)
	var sfd := Vector2(0.2002, -0.9798)
	var outer: Array = [Vector2(3.2, 1.87), t1]
	var a1: float = (t1 - c).angle()
	var a2: float = (t2 - c).angle()
	if a2 < a1:
		a2 += TAU
	for i in range(1, 12):
		outer.append(c + Vector2(cos(lerpf(a1, a2, i / 12.0)), sin(lerpf(a1, a2, i / 12.0))) * 1.3)
	outer.append(t2)
	outer.append(t2 + sfd * 1.4)
	var inner: Array = [Vector2(3.2, FLY), Vector2(-0.31, FLY), Vector2(-0.93, 0.13), Vector2(-0.93, 0.13) + sfd * 1.0]
	var ring := PackedVector2Array()
	for p: Vector2 in outer:
		ring.append(p)
	for i in range(inner.size() - 1, -1, -1):
		ring.append(inner[i])
	if Geometry2D.is_polygon_clockwise(ring):
		ring.reverse()
	for y in [F1, F2]:
		var yy: float = y
		flat(ring, yy + 0.14, 0xd9d4c8)
		var idx := Geometry2D.triangulate_polygon(ring)
		for t in range(0, idx.size(), 3):
			var p: Vector2 = ring[idx[t]]
			var q: Vector2 = ring[idx[t + 1]]
			var r: Vector2 = ring[idx[t + 2]]
			tri(Vector3(p.x, yy, p.y), Vector3(q.x, yy, q.y), Vector3(r.x, yy, r.y), WHITE, Vector3.DOWN)
		for i in range(outer.size() - 1):
			var p: Vector2 = outer[i]
			var q: Vector2 = outer[i + 1]
			var d := (q - p).normalized()
			var n := Vector3(-d.y, 0, d.x)
			if n.dot(Vector3(p.x - 1.0, 0, p.y - 0.3)) < 0.0:
				n = -n
			quad(Vector3(p.x, yy, p.y), Vector3(q.x, yy, q.y), Vector3(q.x, yy + 0.14, q.y), Vector3(p.x, yy + 0.14, p.y), WHITE, n)
			bar(Vector3(p.x, yy + 1.1, p.y), Vector3(q.x, yy + 1.1, q.y), 0.045, 0.04, HIERRO)          # the railing
			bar(Vector3(p.x, yy + 0.2, p.y), Vector3(q.x, yy + 0.2, q.y), 0.025, 0.025, HIERRO)
			var s := 0.0
			var lnq: float = p.distance_to(q)
			while s < lnq:
				var m: Vector2 = p.lerp(q, s / lnq)
				bar(Vector3(m.x, yy + 0.14, m.y), Vector3(m.x, yy + 1.1, m.y), 0.018, 0.018, HIERRO)
				s += 0.12

# ---------------- the ground floor ----------------
## the bank: grey granite from the corner, its red band with our name and our emblem, the red box at its end, windows
## of posters, its door, the cash machine near the corner, and round the corner on the San Francisco
func _bank() -> void:
	home()
	var g: float = minf(_foot(0.0), _foot(BANK_END))
	var holes: Array = [Rect2(BANK_DOOR[0], 0.0, BANK_DOOR[1] - BANK_DOOR[0], 2.55)]
	for w in BANK_WINS:
		holes.append(Rect2(w[0], 0.55, w[1] - w[0], 2.0))
	masonry(0.0, BANK_END, g - 0.5, GF, holes, [], "granito")
	box(0.0, g - 0.5, -0.4, 0.01, GF - g + 0.5, 0.4, "granito")
	# the red band, the name on it facing the street, the box at its end
	box(-0.02, 2.62, 0.0, BAND_END + 0.02, 0.58, 0.14, RED)
	_picture(1.0, 1.0 + 3.9, 2.66, 2.66 + 0.585, 0.154, "banco")
	_picture(8.8, 8.8 + 3.9, 2.66, 2.66 + 0.585, 0.154, "banco")
	box(BAND_END - 0.5, 2.5, 0.0, 0.5, 0.69, 0.5, RED)
	var keep := _xf
	_xf = _xf * Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(BAND_END + 0.014, 0.0, 0.0))     # (on its side facing west, along the street)
	_picture(-0.47, -0.05, 2.6, 3.2, 0.0, "banco_cubo")
	_xf = keep
	# its windows: glass, a poster behind each
	for w in BANK_WINS:
		var x0: float = w[0]
		var x1: float = w[1]
		_picture(x0, x1, 0.55, 2.55, -0.25, "cristal")
		_picture(x0 + 0.15, x0 + 0.15 + 1.1, 0.65, 0.65 + 1.76, -0.3, "cartel_banco")
		box(x0, 0.5, -0.3, x1 - x0, 0.06, 0.32, 0x9a9a98)
	# its door: glass in a dark frame, a red sticker
	_picture(BANK_DOOR[0], BANK_DOOR[1], 0.0, 2.55, -0.25, "cristal")
	for x in [BANK_DOOR[0], (BANK_DOOR[0] + BANK_DOOR[1]) / 2.0 - 0.03, BANK_DOOR[1] - 0.06]:
		box(x, 0.0, -0.3, 0.06, 2.55, 0.08, 0x2a2a2c)
	box(BANK_DOOR[0], 2.48, -0.3, BANK_DOOR[1] - BANK_DOOR[0], 0.08, 0.08, 0x2a2a2c)
	box(BANK_DOOR[0] - 0.55, 1.2, 0.0, 0.3, 0.3, 0.01, RED)
	_cajero()
	_solid(0.0, g, -0.5, BANK_END, GF, 0.0)

## The cash machine near the corner (the user, 21 November 2026, through Sistemas: a modelled one before each bank; it
## was a picture on the wall): in its red frame, the dark face of the machine with its lit screen and the keys at its
## sides, the shelf of the keypad, the slots of the card (a green light over it), the receipt and the notes; a red hood
## over it with its light, and a screen at each side for whoever is at it. `cajero_spot` and `cajero_face` (build): where
## you stand at it and which way you look; `cajero_at`: its screen.
const CAJERO_X := 0.35
const CAJERO_W := 0.85
func _cajero() -> void:
	var x0 := CAJERO_X
	var w := CAJERO_W
	box(x0, 0.6, 0.0, w, 1.4, 0.06, RED)
	box(x0 + 0.07, 0.67, 0.06, w - 0.14, 1.26, 0.03, 0x3a3c42)                # the machine's face
	box(x0 + 0.07, 1.83, 0.09, w - 0.14, 0.1, 0.006, RED)                      # the bank's band on it
	box(x0 + 0.16, 1.36, 0.09, 0.53, 0.4, 0.015, "pantalla")                   # the screen
	_text("Bienvenido", Vector3(x0 + w / 2.0, 1.62, 0.107), 30, 0xffffff, 0.0022)
	_text("Introduzca su tarjeta", Vector3(x0 + w / 2.0, 1.49, 0.107), 30, 0xffffff, 0.0011)
	for i in range(4):                                                          # the keys beside it
		for sx in [x0 + 0.09, x0 + w - 0.14]:
			box(sx, 1.4 + i * 0.09, 0.09, 0.05, 0.045, 0.012, 0x9a9ca0)
	box(x0 + 0.1, 1.0, 0.09, w - 0.2, 0.05, 0.2, 0x55585e)                     # the keypad's shelf, its keys
	for r in range(4):
		for c in range(3):
			box(x0 + 0.2 + c * 0.065, 1.05, 0.12 + r * 0.04, 0.045, 0.01, 0.028, 0xd2d4d6)
		box(x0 + 0.42, 1.05, 0.12 + r * 0.04, 0.07, 0.01, 0.028, [0xc0392b, 0xe0b020, 0x2e9a4a, 0x8a8c90][r])
	box(x0 + 0.5, 1.22, 0.09, 0.2, 0.022, 0.012, 0x101012)                     # the card's slot, its green light
	box(x0 + 0.5, 1.25, 0.09, 0.2, 0.012, 0.01, "luz_verde")
	box(x0 + 0.14, 1.22, 0.09, 0.22, 0.014, 0.012, 0x101012)                   # the receipt's
	box(x0 + 0.12, 0.8, 0.09, w - 0.24, 0.07, 0.02, 0x121316)                  # the notes'
	box(x0 + 0.12, 0.77, 0.09, w - 0.24, 0.03, 0.06, 0x767a80)
	box(x0 - 0.04, 2.0, 0.0, w + 0.08, 0.07, 0.32, RED)                        # the hood, a light under it
	box(x0 + 0.1, 1.985, 0.1, w - 0.2, 0.015, 0.12, "luz")
	for sx in [x0 - 0.04, x0 + w + 0.01]:                                       # the screens at its sides
		box(sx, 1.0, 0.0, 0.03, 1.0, 0.28, 0x2c2e33)

## the copy shop's stretch of bare brick: the flats' wooden door, its glass door, its window, each under a low arch
func _brick() -> void:
	home()
	var g: float = minf(_foot(BANK_END), _foot(BRICK_END))
	var holes: Array = [Rect2(WOOD_DOOR[0], DOWN, WOOD_DOOR[1] - WOOD_DOOR[0], 2.5 - DOWN), Rect2(GLASS_DOOR[0], DOWN, GLASS_DOOR[1] - GLASS_DOOR[0], 2.45 - DOWN),
		Rect2(SHOP_WIN[0], 0.5, SHOP_WIN[1] - SHOP_WIN[0], 1.95)]
	masonry(BANK_END, BRICK_END, DOWN, GF, holes, [], "ladrillo")
	for o in [[WOOD_DOOR, 2.5], [GLASS_DOOR, 2.45], [SHOP_WIN, 2.45]]:          # the low arches over them, their bricks on end
		var x0: float = o[0][0]
		var x1: float = o[0][1]
		var top: float = o[1]
		var n := 9
		for k in range(n):
			var t: float = (k + 0.5) / n
			var x: float = lerpf(x0 - 0.2, x1 + 0.2, t)
			var rise: float = 0.18 * sin(PI * t)
			tbox(Transform3D(Basis(Vector3.BACK, (t - 0.5) * 0.5) * Basis.from_scale(Vector3((x1 - x0 + 0.4) / n - 0.02, 0.26, 0.03)), Vector3(x, top + 0.18 + rise, 0.02)), 0x9e6450)
	# the flats' door: two leaves of dark wood in panels, iron scrolls in their glass at the top, a knocker
	var wz := -0.2
	var w0: float = WOOD_DOOR[0]
	var w1: float = WOOD_DOOR[1]
	box(w0, g, wz - 0.05, w1 - w0, 2.5 - g, 0.05, WOOD)
	box(w0 - 0.04, g, wz, 0.06, 2.5 - g, 0.2, 0x4a3020)
	box(w1 - 0.02, g, wz, 0.06, 2.5 - g, 0.2, 0x4a3020)
	for leaf in [[w0 + 0.06, (w0 + w1) / 2.0 - 0.03], [(w0 + w1) / 2.0 + 0.03, w1 - 0.06]]:
		box(leaf[0], 2.0, wz + 0.005, leaf[1] - leaf[0], 0.4, 0.01, 0x1c1c1e)
		for k in range(3):
			ball(Vector3(lerpf(leaf[0] + 0.15, leaf[1] - 0.15, k / 2.0), 2.2, wz + 0.02), 0.06, HIERRO, 0.4, 8, 4)
		for k in range(2):
			box(leaf[0] + 0.08, 0.3 + k * 0.85, wz + 0.005, leaf[1] - leaf[0] - 0.16, 0.7, 0.02, 0x6a4430)
	box((w0 + w1) / 2.0 + 0.12, 1.25, wz + 0.02, 0.05, 0.16, 0.04, 0xb9a060)
	box(w0 - 0.1, g - 0.3, -0.25, w1 - w0 + 0.2, 0.3 - g, 0.3, 0xc9c4ba)
	# the copy shop's glass door: aluminium, its notices stuck on it, "ABIERTO" / "CERRADO" hung inside
	var gz := -0.18
	var g0: float = GLASS_DOOR[0]
	var g1: float = GLASS_DOOR[1]
	_picture(g0, g1, 0.0, 2.45, gz, "cristal")
	box(g0, 0.0, gz - 0.04, 0.06, 2.45, 0.08, 0x9a9da0)
	box(g1 - 0.06, 0.0, gz - 0.04, 0.06, 2.45, 0.08, 0x9a9da0)
	box(g0, 2.0, gz - 0.04, g1 - g0, 0.06, 0.08, 0x9a9da0)
	box(g0, 0.0, gz - 0.04, g1 - g0, 0.08, 0.08, 0x9a9da0)
	box(g0 + 0.2, 0.8, gz - 0.05, 0.38, 0.5, 0.005, 0xf4f2ec)                             # its notices
	box(g0 + 0.75, 0.5, gz - 0.05, 0.4, 1.0, 0.005, 0xe8a0c8)
	box(g0 + 0.15, 1.45, gz - 0.05, 0.32, 0.3, 0.005, 0xf2e6a0)
	box(g1 - 0.32, 1.0, gz - 0.06, 0.06, 0.2, 0.06, 0x3a3a3c)                              # its handle
	box(g0 - 0.05, g - 0.3, -0.25, g1 - g0 + 0.1, 0.3 - g, 0.3, 0xc9c4ba)
	# its window: the panel with the name and the donkey at the top, shelves of paper and books behind
	var s0: float = SHOP_WIN[0]
	var s1: float = SHOP_WIN[1]
	_picture(s0, s1, 0.5, 2.45, -0.15, "cristal")
	_picture(s0 + 0.05, s1 - 0.05, 1.45, 1.45 + (s1 - s0 - 0.1) * 500.0 / 900.0, -0.18, "copisteria")
	box(s0, 0.45, -0.25, s1 - s0, 0.06, 0.3, 0xc9c4ba)
	_solid(BANK_END, g, -0.5, BRICK_END, GF, 0.0)

## the electrician's: white, his blue sign over a window of posters, his green sign over the big window and the door
func _electrician() -> void:
	home()
	var g: float = minf(_foot(BRICK_END), _foot(LONG))
	var win1 := [24.9, 26.4]
	var win2 := [27.0, 28.9]
	var door2 := [28.9, 30.4]
	var holes: Array = [Rect2(win1[0], 0.45, win1[1] - win1[0], 1.9), Rect2(win2[0], 0.3, win2[1] - win2[0], 2.05), Rect2(door2[0], DOWN, door2[1] - door2[0], 2.35 - DOWN)]
	masonry(BRICK_END, LONG, DOWN, GF, holes, [], "blanco")
	box(BRICK_END, g - 0.4, 0.0, LONG - BRICK_END, 0.55 - g, 0.04, 0xb9b4aa)
	_picture(24.6, 26.7, 2.4, 2.4 + 0.84, 0.045, "electricidad")
	box(24.6, 2.4, 0.0, 2.1, 0.84, 0.03, 0x1e2a6e)
	box(26.9, 2.42, 0.0, 3.7, 0.12, 0.25, 0xd9d6cc)                                       # the little canopy over the big window
	_picture(26.9, 30.6, 2.56, 2.56 + 0.925, 0.03, "energia")
	for w in [win1, win2]:
		_picture(w[0], w[1], 0.45 if w == win1 else 0.3, 2.35, -0.15, "cristal")
		box(w[0], (0.45 if w == win1 else 0.3) - 0.05, -0.2, w[1] - w[0], 0.05, 0.22, 0xd9d6cc)
	box(win1[0] + 0.1, 0.55, -0.2, 1.3, 1.6, 0.01, 0x2a82c8)                             # posters behind the glass
	box(win1[0] + 0.25, 0.7, -0.19, 1.0, 0.6, 0.01, 0x5aa04a)
	box(win2[0] + 0.1, 0.4, -0.2, 1.7, 1.85, 0.01, 0x3a7a3a)
	ball(Vector3(win2[0] + 0.95, 1.3, -0.19), 0.5, 0xd8e8d0, 0.05, 16, 3)
	_picture(door2[0], door2[1], 0.0, 2.35, -0.15, "cristal")
	for x in [door2[0], door2[1] - 0.06]:
		box(x, 0.0, -0.2, 0.06, 2.35, 0.08, 0x9a9da0)
	box(door2[1] - 0.3, 1.0, -0.12, 0.05, 0.4, 0.06, 0xc9ccd0)
	box(door2[0] - 0.05, g - 0.3, -0.25, door2[1] - door2[0] + 0.1, 0.3 - g, 0.3, 0xc9c4ba)
	_solid(BRICK_END, g, -0.5, LONG, GF, 0.0)

## the ground floor on the San Francisco: the bank round the corner, then the flats' other door, the door of mesh under
## two air conditioners, a barred window
func _sf_ground() -> void:
	var a := SF_END
	var b := Vector2(0.0, 0.0)
	var ln: float = face(a, b)
	var bank0: float = ln - 5.0
	var holes: Array = [Rect2(ln - 3.9, 0.55, 1.8, 2.0), Rect2(ln - 7.7, DOWN, 1.4, 2.45 - DOWN), Rect2(ln - 12.4, DOWN, 1.6, 2.35 - DOWN), Rect2(ln - 15.2, 0.9, 1.0, 1.3)]
	masonry(0.0, bank0, DOWN, GF, holes.slice(1), [], "blanco")       # (white render past the bank, grey frames round its openings: Street View 2024; Catastro's 2018 photo had it all clad)
	masonry(bank0, ln, DOWN, GF, holes.slice(0, 1), [], "granito")
	box(bank0, 2.62, 0.0, 5.0, 0.63, 0.14, RED)
	_picture(ln - 4.6, ln - 0.7, 2.66, 2.66 + 0.585, 0.141, "banco")
	box(bank0 - 0.5, 2.5, 0.0, 0.5, 0.8, 0.5, RED)
	_picture(ln - 3.9, ln - 2.1, 0.55, 2.55, -0.25, "cristal")
	_picture(ln - 3.75, ln - 3.75 + 1.1, 0.65, 0.65 + 1.76, -0.3, "cartel_banco")
	# the flats' other door: a frame of pale stone, an iron grille over glass
	var d0: float = ln - 7.7
	stone_frame(Rect2(d0, 0.0, 1.4, 2.45), 0.3, 0.04, "granito")
	box(d0, DOWN, -0.2, 1.4, 2.45 - DOWN, 0.02, 0x1c1c1e)                                # (down into the ground: the pavement falls along the street)
	for k in range(9):
		box(d0 + 0.05 + k * 0.16, 0.05, -0.17, 0.025, 2.35, 0.025, HIERRO)
	for y in [0.6, 1.4, 2.0]:
		box(d0, y, -0.17, 1.4, 0.04, 0.03, HIERRO)
	# the door of mesh, the two air conditioners over it
	var m0: float = ln - 12.4
	box(m0, DOWN, -0.15, 1.6, 2.35 - DOWN, 0.02, 0x8a8d90)
	for k in range(14):
		bar(Vector3(m0, k * 0.17, -0.12), Vector3(m0 + 1.6, k * 0.17 + 0.6, -0.12), 0.012, 0.012, 0x5a5d60)
	stone_frame(Rect2(m0, 0.0, 1.6, 2.35), 0.25, 0.04, "granito")
	box(m0 - 0.1, 2.7, 0.0, 1.8, 0.4, 0.14, 0xf2f0ea)                                   # a blank sign box over it
	for y in [1.75, 2.45]:                           # the two air conditioners, one on the other, beside its frame (Street View 2024)
		box(m0 + 1.9, y, 0.0, 0.85, 0.6, 0.28, 0xeeeeea)
		drum(Vector3(m0 + 2.18, y + 0.3, 0.29), 0.22, 0.22, 0.005, 0x6a6c6e, 12)
	# the barred window
	var b0: float = ln - 15.2
	box(b0, 0.9, -0.2, 1.0, 1.3, 0.02, "visillo")
	for k in range(6):
		box(b0 + 0.08 + k * 0.17, 0.85, 0.02, 0.025, 1.4, 0.025, HIERRO)
	stone_frame(Rect2(b0, 0.9, 1.0, 1.3), 0.12, 0.03, "granito")
	home()

## whether a spot of this frame lies on one of its two fronts (the Teniente Infante's, the San Francisco's), on the
## ground floor's line or on the upper floors' a metre out (the map's outline of the house follows the upper floors)
func _on_fronts(p: Vector2) -> bool:
	var on_ti: bool = (absf(p.y) < 0.3 or absf(p.y - FLY) < 0.3) and p.x > -1.2 and p.x < LONG + 0.6
	var q: Vector2 = Geometry2D.get_closest_point_to_segment(p, Vector2.ZERO, SF_END)
	return on_ti or q.distance_to(p) < 1.3

## the same outline with its fronts brought back to the ground floor's lines (what stops you under the upper floors)
func _ground_ring(ring: PackedVector2Array) -> Array:
	var out: Array = []
	for p in ring:
		var q: Vector2 = p
		if absf(p.y - FLY) < 0.15:
			q = Vector2(clampf(p.x, 0.0, LONG), 0.0)
		elif p.x < 0.0 and p.y > -1.0:
			q = Vector2.ZERO
		else:
			var s: Vector2 = Geometry2D.get_closest_point_to_segment(p, Vector2(-0.93, 0.13), SF_END + Vector2(-0.87, -0.18))
			if s.distance_to(p) < 0.15:
				q = Geometry2D.get_closest_point_to_segment(p, Vector2.ZERO, SF_END)
		if out.is_empty() or (out[-1] as Vector2).distance_to(q) > 0.05:
			out.append(q)
	return out

## the rest of the house: its walls on the neighbours and its yard, the flat roof
func _body() -> void:
	var hd: Dictionary = {}
	for h in MapData.houses:
		if String(h["id"]) == HOUSE:
			hd = h
	var ring := PackedVector2Array()
	if not hd.is_empty() and hd.has("pieces"):
		var raw: Array = hd["pieces"][0]["ring"]
		for i in range(0, raw.size(), 2):
			ring.append(_fr(Vector2(float(raw[i]), float(raw[i + 1]))))
	if ring.size() < 3:
		ring = PackedVector2Array([Vector2(0, 0), Vector2(LONG, 0), Vector2(LONG + 0.5, -7.5), Vector2(29.0, -10.0), SF_END])
	outline = PackedVector2Array()
	for p in ring:
		outline.append(spot(p.x, p.y))
	if Geometry2D.is_polygon_clockwise(ring):
		ring.reverse()
	# its back walls (not the two fronts): render, down to the ground, up to the top
	for i in range(ring.size()):
		var a: Vector2 = ring[i]
		var b: Vector2 = ring[(i + 1) % ring.size()]
		if a.distance_to(b) < 0.1:
			continue
		if _on_fronts(a) and _on_fronts(b):
			continue                                    # (its two fronts, built above)
		var ln: float = face(b, a)
		box(0.0, DOWN, -0.25, ln, TOP + 0.75 - DOWN, 0.25, "crema")
	home()
	flat(ring, TOP + 0.6, 0xa8a49c)
	var f: Array = []
	for p in ring:
		f.append(p)
	_prism(_ground_ring(ring), DOWN, GF)
	_prism(f, GF, TOP)

# ---------------- open and shut ----------------
## what shows only while each shop is open (its room lit behind the glass) and only while shut (its sign "CERRADO")
func _states() -> void:
	for key in ["banco", "copia", "elec"]:
		var on := Node3D.new()
		add_child(on)
		_rooms[key] = on
		var off := Node3D.new()
		add_child(off)
		_shut[key] = off
	home()
	# the bank: its room, desks, a counter, the lights
	_room(1.8, BANK_END - 0.4, -6.0, "sala_banco")          # (from 1.8 m: the San Francisco runs aslant, and from 0.4 it came out through its front)
	for x in [3.0, 11.0]:
		box(x, 0.0, -3.4, 1.6, 0.75, 0.8, 0xf2f0ea)
		box(x + 0.5, 0.75, -3.2, 0.5, 0.35, 0.05, 0x2a2a2c)
		box(x + 0.4, 0.0, -2.4, 0.5, 0.5, 0.5, RED)
	box(5.6, 0.0, -5.0, 4.0, 1.05, 0.7, 0xf2f0ea)
	box(5.6, 1.05, -5.0, 4.0, 0.04, 0.7, RED)
	_commit_to(_rooms["banco"])
	# the copy shop: shelves of paper and books, the copier, the counter
	_room(BANK_END + 3.6, BRICK_END - 0.3, -5.0, "sala_copia")
	for k in range(3):
		box(SHOP_WIN[0] + 0.1 + k * 0.7, 0.0, -1.4, 0.6, 1.8, 0.35, 0xb98a52)
		for j in range(4):
			box(SHOP_WIN[0] + 0.12 + k * 0.7, 0.2 + j * 0.42, -1.36, 0.56, 0.2, 0.3, [0xf4f2ec, 0x2a82d8, 0xe8322a, 0x3a9a4a][(k + j) % 4])
	box(GLASS_DOOR[0] - 0.6, 0.0, -4.4, 1.0, 1.0, 0.7, 0xd9d6cc)                             # the copier
	box(GLASS_DOOR[0] - 0.6, 1.0, -4.4, 1.0, 0.1, 0.7, 0x4a4d52)
	box(GLASS_DOOR[1] + 0.3, 0.0, -3.0, 2.2, 0.95, 0.6, 0x3a7a4a)                          # the counter
	_commit_to(_rooms["copia"])
	# the electrician's: a counter, boxes of material
	_room(BRICK_END + 0.3, LONG - 0.4, -5.0, "sala_elec")
	box(26.0, 0.0, -3.5, 2.5, 1.0, 0.7, 0xf2f0ea)
	for k in range(4):
		box(28.5 + k * 0.5, 0.0, -4.6, 0.45, 0.45 + 0.2 * (k % 2), 0.45, 0xb98a52)
	_commit_to(_rooms["elec"])
	# shut: a card hung in the copy shop's door, the room dark behind the others (nothing to add: they go dark)
	box(GLASS_DOOR[0] + 0.45, 1.45, -0.21, 0.5, 0.22, 0.01, 0xd8243a)
	_commit_to(_shut["copia"])
	var card := _text("CERRADO", Vector3(GLASS_DOOR[0] + 0.7, 1.56, -0.22), 40, 0xfdfcf8, 0.0035)
	card.reparent(_shut["copia"])
	var card2 := _text("ABIERTO", Vector3(GLASS_DOOR[0] + 0.7, 1.56, -0.22), 40, 0xfdfcf8, 0.0035)
	box(GLASS_DOOR[0] + 0.45, 1.45, -0.21, 0.5, 0.22, 0.01, 0x2c8a3a)
	_commit_to(_rooms["copia"])
	card2.reparent(_rooms["copia"])

## a room behind a stretch of the front: floor, ceiling, back and sides, lit, and its lights
func _room(x0: float, x1: float, back: float, key) -> void:
	box(x0, -0.02, back, x1 - x0, 0.02, -back - 0.3, key)
	box(x0, 2.9, back, x1 - x0, 0.05, -back - 0.3, key)
	box(x0, 0.0, back - 0.05, x1 - x0, 2.9, 0.05, key)
	box(x0 - 0.05, 0.0, back, 0.05, 2.9, -back - 0.3, key)
	box(x1, 0.0, back, 0.05, 2.9, -back - 0.3, key)
	var x := x0 + 1.0
	while x < x1 - 0.5:
		box(x - 0.4, 2.88, back / 2.0 - 0.15, 0.8, 0.02, 0.3, "luz")
		x += 2.5

func _commit_to(node: Node3D) -> void:
	for key in _tools:
		var mi := MeshInstance3D.new()
		mi.mesh = (_tools[key] as SurfaceTool).commit()
		mi.material_override = _material(key)
		node.add_child(mi)
	_tools.clear()

## whether that shop is open on that day of the week (0 Monday ... 6 Sunday) at that hour (provisional hours)
func open_at(shop: String, day: int, hour: float) -> bool:
	var d := posmod(day, 7)
	match shop:
		"banco":
			return d <= 4 and hour >= 8.5 and hour < 14.5
		"copia":
			if d <= 4:
				return (hour >= 9.5 and hour < 14.0) or (hour >= 17.0 and hour < 20.5)
			return d == 5 and hour >= 10.0 and hour < 13.5
		"elec":
			return d <= 4 and ((hour >= 9.0 and hour < 14.0) or (hour >= 17.0 and hour < 20.0))
	return false

func _process(_delta: float) -> void:
	var game = W.get_parent() if W != null else null
	if game != null and "clock" in game and "weekday" in game:
		var d := int(game.weekday)
		var h := float(game.clock)
		var b := open_at("banco", d, h)
		var c := open_at("copia", d, h) or for_the_posters(game)
		var e := open_at("elec", d, h)
		if b != bank_open or c != shop_open or e != elec_open:
			set_open(b, c, e)

## the Recress's posters are waiting for you at the copy shop: it is open for them whatever the clock says, and keeps
## its hours the rest of the time (the user, 17 Nov: "La copistería estará abierta durante la misión. Usaremos los
## horarios que has puesto ya")
static func for_the_posters(game) -> bool:
	var R = game.get("recress") if game != null else null
	return R != null and R.active() and R.stage() == "copisteria"

## open: that shop lit behind its glass; shut: dark (the copy shop's card turned round)
func set_open(bank: bool, shop: bool, elec: bool) -> void:
	bank_open = bank
	shop_open = shop
	elec_open = elec
	if tienda != null:
		tienda.open = shop
	if banco != null:
		banco.open = bank
	for q in [["banco", bank, "sala_banco"], ["copia", shop, "sala_copia"], ["elec", elec, "sala_elec"]]:
		if _rooms.has(q[0]):
			(_rooms[q[0]] as Node3D).visible = q[1]
			(_shut[q[0]] as Node3D).visible = not q[1]

func _tell_map() -> void:
	if outline.size() < 3:
		return
	MapData.outlines.append(outline)
	if not MapData._wall_grid.is_empty():
		for i in range(outline.size()):
			var a: Vector2 = outline[i]
			var c: Vector2 = outline[(i + 1) % outline.size()]
			MapData._grid_add(MapData._wall_grid, a.min(c), a.max(c), [a, c])
