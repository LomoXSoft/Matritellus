extends "res://scripts/obra.gd"
## The inside of the Polideportivo Municipal (polideportivo.gd builds the hall itself). The user, 28 November 2026,
## with four photographs of it: "Te paso imágenes por dentro. Quiero que se pueda acceder". A set built far out in
## the fields, like the other places you go into by the green arrow before their doors (entradas.gd); always open (no
## hours were asked for).
##
## What it is (the user's photographs): one great room under the four broken roofs of ribbed sheet, strips of
## translucent sheet in them, white walls over a blue dado.
##   - the stand along the door's side: five rows of red seats on concrete steps over a blue front, a walkway behind
##     them with a white railing, the row of little windows over it, an arch at either end (the high doors of the
##     outside stairs); the way in passes through the middle of it, under the walkway: the two glass doors of red
##     panels and, between them, a green double door with two portholes;
##   - a stair either side of that passage, up to the walkway: you can climb them and look at the court from above
##     (each half of the walkway has its own; the bridge over the passage is railed off);
##   - the court: blue, 40 x 20, the handball lines in white, the basketball ones in dark blue, the volleyball ones in
##     yellow, an orange border; a goal of red and white posts at either end and a basket hung from the roof over each;
##   - on the far wall the scoreboard, a white sheet door (the one on the hall's west side) and two clusters of
##     advert boards: the game's own shops (AHORROS RURALES in green where the real wall has the savings bank's), no
##     telephone or address on any; loudspeakers; grey louvres on the end walls; red benches and yellow chairs at the
##     stand's foot.
## Nobody in it (the user decides the figures). Everything is made here, of the kit's pieces and
## tools/polideportivo/'s pictures.
##
## What a place you go into has to give (game.gd _use_door): `door_out`, `out_spawn`, `out_h` in the street; `in_door`
## and `in_spawn` in the set; `open`. `room_at` tells entradas.gd's camera where you are: the lobby under the walkway,
## the court (the camera goes along with you by the stand's foot) or the stand (from behind you, over the court).
## The set's frame: +z deeper in (to the west), the doors' wall at z = 0; looking in, +x is on your left (the south);
## y = 0 the floor.

const INSIDE := Vector2(1050.0, -1550.0)        # where the set is: no street within 235 m, no tree of the map within
                                                # 165 m of its walls, the other sets 390 m off or more
const HALF := 22.0                              # half its length
const D := 28.0                                 # from the doors' wall to the far one
const TALL := 7.4                               # its walls, up to the roofs' feet
const STAND := 5.5                              # how far the stand comes out
const WALK := 1.75                              # the walkway at its top
const ROWS := 5
const TREAD := 0.75
const RISE := 0.42
const FIRST := 1.1                              # the first row's height
const TOP := 3.2                                # the walkway's (FIRST + ROWS * RISE)
const CUT := 2.6                                # half the width of the way in through the stand
const AISLE := 1.2                              # the stairs beside it
const BOX := 0.55                               # how far the green door's box stands out between the two glass doors
const FOOT := 6.9                               # where those stairs begin, and the court's near line
const COURT := Rect2(-20.0, 6.9, 40.0, 20.0)
const DIR := "res://assets/polideportivo/"
const BAYS: Array = [-22.2, -10.8, 0.0, 10.8, 22.2]      # the four roofs, from the north (as outside)
const ROOF: Array = [[0.0, 7.6], [0.12, 9.3], [0.53, 9.9], [1.0, 7.6]]      # each one's line: how far across it, how high

var door_out: Vector2
var out_spawn: Vector2
var out_h := 0.0
var in_door: Vector2
var in_spawn: Vector2
var open := true
var props := 0                  # pieces of furniture and fittings (the self-test)
var seats := 0
var boards := 0                 # advert boards on the far wall
var lamps := 0
var saffron_spot := Vector2.ZERO        # where its hidden saffron is, on the map

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: StandardMaterial3D = null
	var kind: String = String(key) if key is String else ""
	match kind:
		"pared":
			m = _lit(Color(0.95, 0.91, 0.8), 0.3)        # (cream, the user's photographs)
		"zocalo":           # the blue dado
			m = _lit(Color(0.16, 0.5, 0.64), 0.28)
		"grada":            # the stand's concrete
			m = _lit(Color(0.74, 0.74, 0.71), 0.26)
		"asiento":
			m = _lit(Color(0.8, 0.14, 0.1), 0.24)
		"amarillo":
			m = _lit(Color(0.92, 0.78, 0.2), 0.24)
		"tubo":             # the white railings
			m = _lit(Color(0.95, 0.95, 0.93), 0.34)
		"viga":
			m = _lit(Color(0.92, 0.89, 0.8), 0.28)
		"naranja":          # the floor's border, where the picture does not reach
			m = _lit(Color(0.86, 0.4, 0.13), 0.3)
			m.roughness = 0.3
		"verde":            # the green door of the lobby
			m = _lit(Color(0.2, 0.56, 0.32), 0.26)
		"granate":          # the red panels of the glass doors
			m = _lit(Color(0.62, 0.23, 0.14), 0.25)
		"negro":
			m = _lit(Color(0.1, 0.1, 0.11), 0.05)
		"gris":
			m = _lit(Color(0.6, 0.62, 0.62), 0.2)
		"poste_rojo":
			m = _lit(Color(0.85, 0.12, 0.1), 0.26)
		"calle":            # daylight through the doors' glass
			m = _lit(Color(0.9, 0.94, 1.0), 1.3)
		"ventana":          # ...and through the little windows over the walkway
			m = _lit(Color(0.88, 0.94, 1.0), 1.5)
		"arco":             # the landings behind the two arches, lit warm
			m = _lit(Color(1.0, 0.82, 0.5), 0.9)
		"luz":
			m = _lit(Color(1.0, 0.99, 0.95), 1.9)
		"baldosa":          # the lobby's grey tiles
			var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
			for y in range(32):
				for x in range(32):
					img.set_pixel(x, y, Color(0.6, 0.6, 0.59) if x == 0 or y == 0 else Color(0.72, 0.72, 0.7))
			m = _pattern(img, 0.5, 0.25)
		"azul":             # the little blue tiles of the stand's front
			var img := Image.create(8, 8, false, Image.FORMAT_RGB8)
			for y in range(8):
				for x in range(8):
					img.set_pixel(x, y, Color(0.3, 0.6, 0.72) if x == 0 or y == 0 else Color(0.2, 0.52, 0.66))
			m = _pattern(img, 0.2, 0.28)
		"techo":            # the ribbed sheet of the roofs, from below: the ribs run down each slope
			var img := Image.create(2, 8, false, Image.FORMAT_RGB8)
			for y in range(8):
				var c := Color(0.5, 0.52, 0.54) if y == 0 else (Color(0.66, 0.68, 0.7) if y == 1 or y == 7 else Color(0.74, 0.76, 0.78))
				img.set_pixel(0, y, c)
				img.set_pixel(1, y, c)
			m = _pattern(img, 0.3, 0.3)
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			m.metallic = 0.3
			m.roughness = 0.5
		"lucernario":       # the strips of translucent sheet, the day behind them
			var img := Image.create(16, 16, false, Image.FORMAT_RGB8)
			for y in range(16):
				for x in range(16):
					var c := Color(0.97, 0.95, 0.82).darkened(0.05 * ((x / 4 + y / 8) % 2))
					if x == 0 or y == 0:
						c = Color(0.62, 0.6, 0.5)
					img.set_pixel(x, y, c)
			m = _pattern(img, 1.6, 1.25)
		"pista", "anuncios", "marcador":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(DIR + kind + ".png")
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			m.roughness = 0.28 if kind == "pista" else 0.8
			m.emission_enabled = true
			m.emission_texture = m.albedo_texture
			m.emission = Color.WHITE
			m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY      # (the picture's own colours, with no grey veil over them)
			m.emission_energy_multiplier = 0.8 if kind == "marcador" else 0.4
		"tablero":          # the baskets' clear boards
			m = StandardMaterial3D.new()
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.9, 0.94, 0.96, 0.3)
			m.roughness = 0.1
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
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

## a little picture laid on a floor, a wall or a ceiling by the world's own axes: `metres` a repeat
func _pattern(img: Image, metres: float, how: float) -> StandardMaterial3D:
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / metres
	m.roughness = 1.0
	if how > 0.0:
		m.emission_enabled = true
		m.emission_texture = m.albedo_texture
		m.emission = Color.WHITE
		m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
		m.emission_energy_multiplier = how
	return m

# ---------------- building it ----------------
func build(world, at: Vector2, out: Vector2, heading: float) -> void:
	W = world
	door_out = at
	out_spawn = out
	out_h = heading
	var top := -1e9
	for dx in range(-int(HALF) - 2, int(HALF) + 3, 4):
		for dz in range(-2, int(D) + 3, 4):
			top = maxf(top, MapData.height(INSIDE + Vector2(dx, dz)))
	level = top + 0.03
	# the floors, the first that holds you wins: the two stairs, the two halves of the walkway, then the hall's floor
	for s in [-1.0, 1.0]:
		var run := FOOT - WALK
		MapData.decks.append({"o": INSIDE + Vector2(s * (CUT + AISLE / 2.0), (FOOT + WALK) / 2.0), "ax": Vector2(0, -1), "half": run / 2.0, "wide": AISLE / 2.0,
			"top": level + TOP, "low": level, "ramp": run})
	for s in [-1.0, 1.0]:
		var a := INSIDE + Vector2(s * CUT, -0.6)
		var b := INSIDE + Vector2(s * (HALF + 0.6), WALK)
		var up := PackedVector2Array([Vector2(minf(a.x, b.x), a.y), Vector2(maxf(a.x, b.x), a.y), Vector2(maxf(a.x, b.x), b.y), Vector2(minf(a.x, b.x), b.y)])
		MapData.decks.append({"o": (a + b) / 2.0, "poly": up, "r2": 14.0 * 14.0, "top": level + TOP})
	var ring := PackedVector2Array([INSIDE + Vector2(-HALF - 0.6, -0.6), INSIDE + Vector2(HALF + 0.6, -0.6), INSIDE + Vector2(HALF + 0.6, D + 0.6), INSIDE + Vector2(-HALF - 0.6, D + 0.6)])
	MapData.decks.append({"o": INSIDE + Vector2(0.0, D / 2.0), "poly": ring, "r2": (HALF + 2.0) * (HALF + 2.0) + (D / 2.0 + 2.0) * (D / 2.0 + 2.0), "top": level})
	transform = Transform3D(Basis.IDENTITY, Vector3(INSIDE.x, level, INSIDE.y))
	W.add_child(self)
	in_door = INSIDE + Vector2(1.39, 0.45)
	in_spawn = INSIDE + Vector2(1.6, 1.7)
	_shell()
	_roof()
	_stand()
	_lobby()
	_court()
	_far_wall()
	_lamps()
	home()
	_commit()
	_saffron(Vector3(-HALF + 0.5, TOP, 0.38))      # (before _indoors: it takes the set's layer with everything else)
	_indoors(self)

## Its hidden saffron (the user, 28 Nov 2026: «Si»): up on the stand, in the corner at the north end of the walkway,
## behind the last row of seats and beside the arch of the outside stair. You have to climb the stand and walk its
## whole length to come upon it; from the court the seats hide it.
func _saffron(at: Vector3) -> void:
	props += 1
	var flower := Node3D.new()
	flower.add_child(Parts.part("cyl", 0x5f9c4a, Vector3(0, 0.22, 0), Vector3(0.025, 0.44, 0.025)))
	for k in range(5):
		flower.add_child(Parts.part("ball", 0x9b5de5, Vector3(cos(k * 1.257) * 0.09, 0.48, sin(k * 1.257) * 0.09), Vector3(0.085, 0.15, 0.085)))
	flower.add_child(Parts.part("ball", 0xe63946, Vector3(0, 0.54, 0), Vector3(0.04, 0.1, 0.04)))
	flower.position = at
	flower.scale = Vector3.ONE * 0.8
	add_child(flower)
	saffron_spot = INSIDE + Vector2(at.x, at.z)
	var game = W.get_parent()                           # (the game: the world is its child)
	if game != null and game.get("flowers") != null:
		(game.flowers as Array).append({"node": flower, "p": saffron_spot, "id": "polideportivo", "hidden": true})      # (hidden: Sistemas keeps count of these)

## everything is indoors: no sun on it (game.gd's render layer 11)
func _indoors(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).layers = 1 << 10
	for c in n.get_children():
		_indoors(c)

## where you are, for entradas.gd's camera: the middle of the wall it hangs on, which way it looks, how big
func room_at(pp: Vector2) -> Dictionary:
	var p := pp - INSIDE
	var fwd := Vector2(0, 1)
	var side := Vector2(-1, 0)
	var up: bool = MapData.foot(pp) > level + 1.6
	if up:                  # on the stand: from behind you, against the doors' wall, the court beyond
		return {"o": INSIDE + Vector2(clampf(p.x, -15.0, 15.0), 0.0), "fwd": fwd, "side": side, "half": 9.0, "deep": D, "tall": 3.4, "name": "grada"}      # (3.15 m over the walkway: under the trusses, which begin 3.55 m over it)
	if absf(p.x) < CUT and p.y < STAND:            # the way in through the stand: from past the bridge, across the passage from you
		var across := Vector2(1, 0) if p.x >= 0.0 else Vector2(-1, 0)      # (hung on your own side it sat on your head: the passage is 1.6 m wide there)
		return {"o": INSIDE + Vector2(0.0, WALK), "fwd": fwd, "side": across, "half": CUT, "deep": STAND - WALK, "tall": 3.5, "name": "vestibulo"}
	return {"o": INSIDE + Vector2(clampf(p.x, -15.0, 15.0), STAND + 0.3), "fwd": fwd, "side": side, "half": 9.0, "deep": D - STAND - 0.3, "tall": TALL, "name": "pista"}

## a stretch of wall seen from the room: from `a` (its left end) to `b`, from y0 to y1
func _w(a: Vector2, b: Vector2, y0: float, y1: float, key) -> void:
	var ln := face(a, b)
	pieces += 1
	quad(Vector3(0, y0, 0), Vector3(ln, y0, 0), Vector3(ln, y1, 0), Vector3(0, y1, 0), key, Vector3(0, 0, 1))
	home()

## a picture on the wall being built: its left, its foot, how wide and high, the part of the picture across (u0, u1)
func _picture(x: float, y: float, w: float, h: float, key, u0 := 0.0, u1 := 1.0, out := 0.03) -> void:
	pieces += 1
	quad(Vector3(x, y, out), Vector3(x + w, y, out), Vector3(x + w, y + h, out), Vector3(x, y + h, out), key, Vector3(0, 0, 1),
		[Vector2(u0, 1), Vector2(u1, 1), Vector2(u1, 0), Vector2(u0, 0)])

## how high the roofs are over a spot along the hall (x)
func _roof_at(x: float) -> float:
	for b in range(4):
		var x0: float = BAYS[b]
		var x1: float = BAYS[b + 1]
		if x <= x1 or b == 3:
			var t := clampf((x - x0) / (x1 - x0), 0.0, 1.0)
			for i in range(3):
				var t0: float = ROOF[i][0]
				var t1: float = ROOF[i + 1][0]
				if t <= t1:
					return lerpf(float(ROOF[i][1]), float(ROOF[i + 1][1]), (t - t0) / (t1 - t0))
	return TALL

# ---------------- the walls and the floor ----------------
func _shell() -> void:
	var c := [Vector2(-HALF, 0), Vector2(HALF, 0), Vector2(HALF, D), Vector2(-HALF, D)]
	# the doors' wall (white: the stand hides its foot), the two ends and the far wall over their blue dado
	_w(c[0], c[1], 0.0, TALL, "pared")
	for side in [[c[1], c[2]], [c[2], c[3]], [c[3], c[0]]]:
		_w(side[0], side[1], 0.0, 1.5, "zocalo")
		_w(side[0], side[1], 1.5, TALL, "pared")
	# the gables of the two long walls, up to the roofs
	for wall in [[c[0], c[1], 1.0], [c[2], c[3], -1.0]]:
		face(wall[0], wall[1])
		for b in range(4):
			var pts := PackedVector2Array()
			var x0: float = clampf(float(BAYS[b]), -HALF, HALF)
			var x1: float = clampf(float(BAYS[b + 1]), -HALF, HALF)
			var xs: Array = [x0]
			for i in range(1, 3):
				xs.append(lerpf(float(BAYS[b]), float(BAYS[b + 1]), float(ROOF[i][0])))
			xs.append(x1)
			var top: Array = []
			for x: float in xs:
				top.append(Vector2((x + HALF) if float(wall[2]) > 0.0 else (HALF - x), _roof_at(x)))
			if float(wall[2]) < 0.0:
				top.reverse()
			pts.append(Vector2(top[0].x, TALL))
			for q: Vector2 in top:
				pts.append(q)
			pts.append(Vector2(top[top.size() - 1].x, TALL))
			slab(pts, 0.0, 0.0, "pared")
		home()
	# the floor: the court's picture from the stand's foot to the far wall, orange where it does not reach
	pieces += 2
	quad(Vector3(-HALF, 0, 5.9), Vector3(HALF, 0, 5.9), Vector3(HALF, 0, 27.9), Vector3(-HALF, 0, 27.9), "pista", Vector3.UP,
		[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	flat(PackedVector2Array([Vector2(-HALF, STAND), Vector2(HALF, STAND), Vector2(HALF, 5.9), Vector2(-HALF, 5.9)]), 0.0, "naranja")
	flat(PackedVector2Array([Vector2(-HALF, 27.9), Vector2(HALF, 27.9), Vector2(HALF, D), Vector2(-HALF, D)]), 0.0, "naranja")
	flat(PackedVector2Array([Vector2(-CUT, 0), Vector2(CUT, 0), Vector2(CUT, STAND), Vector2(-CUT, STAND)]), 0.0, "baldosa")
	# what stops you: the four walls
	solid(Vector3(0, 4.0, -0.2), Vector3(2.0 * HALF + 0.8, 9.0, 0.4))
	solid(Vector3(0, 4.0, D + 0.2), Vector3(2.0 * HALF + 0.8, 9.0, 0.4))
	solid(Vector3(-HALF - 0.2, 4.0, D / 2.0), Vector3(0.4, 9.0, D))
	solid(Vector3(HALF + 0.2, 4.0, D / 2.0), Vector3(0.4, 9.0, D))
	solid(Vector3(0, 11.0, D / 2.0), Vector3(2.0 * HALF, 0.4, D))

# ---------------- the roofs from below ----------------
func _roof() -> void:
	for b in range(4):
		var x0: float = BAYS[b]
		var x1: float = BAYS[b + 1]
		# its line across the hall: the steep north side of translucent sheet, the gentle slopes of ribbed sheet, a
		# strip of translucent sheet in the long south one
		var line: Array = [[0.0, "lucernario"], [0.12, "techo"], [0.53, "techo"], [0.62, "lucernario"], [0.74, "techo"], [1.0, ""]]
		for i in range(line.size() - 1):
			var xa := clampf(lerpf(x0, x1, float(line[i][0])), -HALF, HALF)
			var xb := clampf(lerpf(x0, x1, float(line[i + 1][0])), -HALF, HALF)
			if xb - xa < 0.01:
				continue
			var ya := _roof_at(xa)
			var yb := _roof_at(xb)
			var n := Vector3(yb - ya, -(xb - xa), 0).normalized()
			pieces += 1
			quad(Vector3(xa, ya, 0), Vector3(xb, yb, 0), Vector3(xb, yb, D), Vector3(xa, ya, D), line[i][1], n)
		if b > 0:                                    # the truss under each valley
			box(x0 - 0.18, 6.75, 0.0, 0.36, 0.85, D, "viga")

# ---------------- the stand ----------------
## the white railing from a to b (x, z) at the height y: posts and two rails, and what stops you
func _rail(a: Vector2, b: Vector2, y: float, hard := true) -> void:
	var ln := a.distance_to(b)
	var n := maxi(1, int(round(ln / 2.0)))
	for i in range(n + 1):
		var p := a.lerp(b, float(i) / n)
		box(p.x - 0.025, y, p.y - 0.025, 0.05, 1.0, 0.05, "tubo")
	for h in [0.5, 1.0]:
		bar(Vector3(a.x, y + h, a.y), Vector3(b.x, y + h, b.y), 0.045, 0.045, "tubo")
	if hard:
		var mid := (a + b) / 2.0
		var d := (b - a).normalized()
		solid(Vector3(mid.x, y + 0.6, mid.y), Vector3(ln, 1.3, 0.08), -atan2(d.y, d.x))

## a red seat on its row: its middle along the row, the row's height, where the row begins (z)
func _seat(x: float, y: float, z: float) -> void:
	box(x - 0.21, y + 0.34, z + 0.1, 0.42, 0.05, 0.4, "asiento")
	box(x - 0.21, y + 0.36, z + 0.06, 0.42, 0.36, 0.05, "asiento")
	box(x - 0.05, y, z + 0.2, 0.1, 0.34, 0.2, "negro")
	seats += 1

func _stand() -> void:
	for s in [-1.0, 1.0]:
		var xa: float = CUT + AISLE              # this half's rows, from the stair to the end wall
		var xb: float = HALF
		var x0 := minf(s * xa, s * xb)
		var w := xb - xa
		for k in range(ROWS):
			var z0 := STAND - TREAD * (k + 1)
			var y := FIRST + RISE * k
			box(x0, 0.0, z0, w, y, TREAD, "grada")
			var x := xa + 0.45
			while x < xb - 0.3:
				if absf(x - 12.0) > 0.75:           # (a way up between the seats, half way along)
					_seat(s * x, y, z0)
				x += 0.55
			box(s * 12.0 - 0.55, y, z0 + TREAD / 2.0, 1.1, RISE / 2.0, TREAD / 2.0, "grada")      # its half steps
		box(x0, 0.0, 0.0, w, TOP, WALK, "grada")                   # the walkway
		box(x0, 0.0, STAND, w, FIRST, 0.02, "azul")                # the blue front
		box(s * 12.0 - 0.55, 0.0, STAND + 0.02, 1.1, FIRST / 2.0, 0.4, "grada")
		solid(Vector3(s * (xa + xb) / 2.0, 1.2, STAND / 2.0), Vector3(w, 3.4, STAND))
		# the walkway's railing, and the one that shuts the bridge over the way in
		_rail(Vector2(s * xa, WALK - 0.06), Vector2(s * (xb - 0.05), WALK - 0.06), TOP)
		_rail(Vector2(s * CUT, 0.1), Vector2(s * CUT, WALK - 0.06), TOP)
		# the stair up, between the way in and the seats
		var n := 18
		var run := (FOOT - WALK) / (n - 1)
		var sx: float = (CUT + 0.07) if s > 0.0 else -xa      # (its steps stop at the wall beside the way in, not inside it)
		for k in range(n - 1):
			var z1 := FOOT - run * k
			box(sx, 0.0, z1 - run, AISLE - 0.07, TOP * (k + 1) / n, run, "grada")
		box(sx, 0.0, 0.0, AISLE - 0.07, TOP, WALK, "grada")
		# the wall between it and the way in, rising with it, and the railing on the seats' side
		for k in range(6):
			var z1 := FOOT - (FOOT - WALK) * k / 6.0
			var z2 := FOOT - (FOOT - WALK) * (k + 1) / 6.0
			var top := TOP * (k + 1) / 6.0 + 0.95
			box(s * CUT - 0.07, 0.0, z2, 0.14, top, z1 - z2, "pared")
		box(s * CUT - 0.07, 0.0, 0.0, 0.14, TOP, WALK, "pared")
		solid(Vector3(s * CUT, 2.2, FOOT / 2.0), Vector3(0.14, 4.6, FOOT))
		bar(Vector3(s * xa, 1.0, FOOT), Vector3(s * xa, TOP + 1.0, WALK), 0.045, 0.045, "tubo")
		bar(Vector3(s * xa, 0.5, FOOT), Vector3(s * xa, TOP + 0.5, WALK), 0.045, 0.045, "tubo")
		for i in range(4):
			var t := float(i) / 3.0
			box(s * xa - 0.025, TOP * t, lerpf(FOOT, WALK, t) - 0.025, 0.05, 1.0, 0.05, "tubo")
		solid(Vector3(s * (xa + 0.04), 2.2, (FOOT + WALK) / 2.0 + 0.1), Vector3(0.08, 4.6, FOOT - WALK - 0.2))
		# the arch at the walkway's end (the high door of the outside stair behind it)
		face(Vector2(s * HALF, D if s < 0.0 else 0.0), Vector2(s * HALF, 0.0 if s < 0.0 else D))
		var ax: float = (D - 0.95) if s < 0.0 else 0.95
		arched(ax, TOP, TOP + 1.5, 0.7, 0.02, "arco", 10)
		home()
		# benches and chairs at its foot
		for bx in [7.2, 15.5]:
			box(s * bx - 1.4, 0.4, STAND + 0.12, 2.8, 0.06, 0.4, "asiento")
			for e in [-1.25, 1.2]:
				box(s * bx + e, 0.0, STAND + 0.16, 0.05, 0.4, 0.32, "asiento")
			solid(Vector3(s * bx, 0.25, STAND + 0.32), Vector3(2.8, 0.5, 0.4))
			props += 1
		for cx in [4.3, 4.95]:
			box(s * cx - 0.2, 0.42, STAND + 0.15, 0.4, 0.04, 0.4, "amarillo")
			box(s * cx - 0.2, 0.46, STAND + 0.12, 0.4, 0.4, 0.04, "amarillo")
			box(s * cx - 0.16, 0.0, STAND + 0.2, 0.32, 0.42, 0.3, "negro")
			props += 1
		solid(Vector3(s * 4.62, 0.4, STAND + 0.33), Vector3(1.1, 0.8, 0.42))
	# the bridge over the way in: the walkway goes on across it, a railing on its edge
	box(-CUT + 0.07, TOP - 0.22, 0.0, 2.0 * CUT - 0.14, 0.22, WALK, "grada")
	_rail(Vector2(-CUT + 0.07, WALK - 0.06), Vector2(CUT - 0.07, WALK - 0.06), TOP, false)
	# the little windows over the walkway, a clock and a row of framed pictures on its wall
	face(Vector2(-HALF, 0), Vector2(HALF, 0))
	var x := 1.3
	while x < 2.0 * HALF - 1.5:
		if fposmod(x, 5.55) > 0.9 and fposmod(x, 5.55) < 4.5:
			box(x, 5.95, 0.0, 0.9, 0.65, 0.03, "tubo")
			box(x + 0.06, 6.01, 0.03, 0.78, 0.53, 0.006, "ventana")
		x += 1.1
	box(HALF - 0.25, 5.0, 0.0, 0.5, 0.5, 0.04, "tubo")
	box(HALF - 0.03, 5.22, 0.04, 0.2, 0.03, 0.006, "negro")
	box(HALF - 0.015, 5.24, 0.046, 0.03, 0.17, 0.006, "negro")
	for i in range(9):
		box(HALF + 3.2 + i * 0.75, 4.55, 0.0, 0.55, 0.42, 0.025, "negro")
		box(HALF + 3.25 + i * 0.75, 4.6, 0.025, 0.45, 0.32, 0.005, "viga" if i % 2 == 0 else "gris")
	home()
	props += 11

# ---------------- the way in ----------------
func _lobby() -> void:
	face(Vector2(-CUT, 0), Vector2(CUT, 0))                     # the doors' wall: the two glass doors of red panels
	for x0 in [CUT - 2.34, CUT + 0.44]:
		box(x0, 0.0, 0.0, 1.9, 2.44, 0.02, "calle")
		for k in range(2):
			var x: float = x0 + 0.95 * k
			box(x, 0.0, 0.023, 0.95, 0.465, 0.012, "granate")      # (a hair before the frame's back, and short of its rails)
			box(x, 1.945, 0.023, 0.95, 0.49, 0.012, "granate")
			for e in [x, x + 0.9]:
				box(e, 0.0, 0.02, 0.05, 2.44, 0.04, "negro")
			for y in [0.0, 0.47, 0.96, 1.45, 1.94, 2.4]:
				box(x + 0.05, y, 0.02, 0.85, 0.04, 0.03, "negro")
		props += 1
	home()
	# between them, before the middle piers: the green double door with its two portholes (shut)
	var pts := PackedVector2Array([Vector2(-0.42, 0.0), Vector2(0.42, 0.0), Vector2(0.95, BOX), Vector2(-0.95, BOX)])
	_w(Vector2(0.95, BOX), Vector2(0.42, 0.0), 0.0, TOP - 0.22, "pared")
	_w(Vector2(-0.42, 0.0), Vector2(-0.95, BOX), 0.0, TOP - 0.22, "pared")
	_w(Vector2(-0.95, BOX), Vector2(0.95, BOX), 0.0, TOP - 0.22, "pared")
	face(Vector2(-0.95, BOX), Vector2(0.95, BOX))
	for k in range(2):
		box(0.1 + 0.86 * k, 0.0, 0.0, 0.84, 2.3, 0.03, "verde")
	for k in range(2):                                       # (the portholes: a pale round pane on each leaf)
		var cx := 0.52 + 0.86 * k
		slab(oval(cx, 1.55, 0.17, 0.17, 14), 0.036, 0.0, "tubo")
		slab(oval(cx, 1.55, 0.13, 0.13, 14), 0.04, 0.0, "ventana")
	home()
	_prism([pts[0], pts[1], pts[2], pts[3]], 0.0, TOP)
	props += 1
	# a lamp under the bridge
	box(-0.6, TOP - 0.25, 0.9, 1.2, 0.025, 0.3, "luz")

# ---------------- the court's things ----------------
func _court() -> void:
	var zc := COURT.position.y + COURT.size.y / 2.0
	for s in [-1.0, 1.0]:
		# the goal: 3 x 2 m, posts in bands of red and white, at the court's end line
		var gx: float = s * COURT.size.x / 2.0
		for pz in [zc - 1.54, zc + 1.5]:
			for k in range(10):
				box(gx - 0.04, 0.2 * k, pz, 0.08, 0.2, 0.08, "poste_rojo" if k % 2 == 0 else "tubo")
		for k in range(15):
			box(gx - 0.04, 2.0, zc - 1.54 + 0.2 * k, 0.08, 0.08, 0.2 + (0.08 if k == 14 else 0.0), "poste_rojo" if k % 2 == 0 else "tubo")
		for pz in [zc - 1.5, zc + 1.5]:                          # its stays, back to the ground
			bar(Vector3(gx, 2.0, pz), Vector3(gx + s * 1.0, 0.0, pz), 0.03, 0.03, "tubo")
		bar(Vector3(gx + s * 1.0, 0.02, zc - 1.5), Vector3(gx + s * 1.0, 0.02, zc + 1.5), 0.03, 0.03, "tubo")
		solid(Vector3(gx + s * 0.5, 1.0, zc - 1.52), Vector3(1.0, 2.0, 0.1))
		solid(Vector3(gx + s * 0.5, 1.0, zc + 1.52), Vector3(1.0, 2.0, 0.1))
		solid(Vector3(gx + s * 1.0, 1.0, zc), Vector3(0.1, 2.0, 3.0))
		# the basket hung from the roof over it: the clear board, its ring, the frame up to the truss
		var bx: float = s * 12.8
		box(bx - 0.02, 2.9, zc - 0.9, 0.04, 1.05, 1.8, "tablero")
		for e in [[2.9, 0.04, 1.8, zc - 0.9], [3.91, 0.04, 1.8, zc - 0.9]]:
			box(bx - 0.03, e[0], e[3], 0.06, e[1], e[2], "tubo")
		for pz in [zc - 0.9, zc + 0.86]:
			box(bx - 0.03, 2.9, pz, 0.06, 1.05, 0.04, "tubo")
		for i in range(10):
			var a0 := TAU * i / 10.0
			var a1 := TAU * (i + 1) / 10.0
			var c := Vector3(bx - s * 0.4, 3.05, zc)
			bar(c + Vector3(cos(a0), 0, sin(a0)) * 0.23, c + Vector3(cos(a1), 0, sin(a1)) * 0.23, 0.025, 0.025, "amarillo")
		for pz in [zc - 0.6, zc + 0.6]:
			bar(Vector3(bx + s * 0.03, 3.9, pz), Vector3(bx + s * 1.9, _roof_at(bx + s * 1.9) - 0.1, pz), 0.06, 0.06, "tubo")
			bar(Vector3(bx + s * 0.03, 3.0, pz), Vector3(bx + s * 1.9, _roof_at(bx + s * 1.9) - 0.1, pz), 0.05, 0.05, "tubo")
		props += 2
		# the grey louvres on the end wall
		face(Vector2(s * HALF, D if s < 0.0 else 0.0), Vector2(s * HALF, 0.0 if s < 0.0 else D))
		for k in range(4):
			var lx := 11.0 + k * 2.1
			box(lx, 2.3, 0.0, 1.6, 0.42, 0.03, "gris")
			for j in range(1, 4):
				box(lx + 0.03, 2.3 + 0.105 * j, 0.03, 1.54, 0.02, 0.01, "negro")
		home()

# ---------------- the far wall ----------------
func _far_wall() -> void:
	face(Vector2(HALF, D), Vector2(-HALF, D))              # (along it x runs from the south end to the north one)
	# the two clusters of advert boards, the scoreboard between them
	_picture(10.5, 3.0, 6.0, 3.0, "anuncios", 0.0, 0.5)
	_picture(27.5, 3.0, 6.0, 3.0, "anuncios", 0.5, 1.0)
	boards = 12
	box(21.15, 4.15, 0.0, 1.7, 1.3, 0.12, "negro")
	_picture(21.2, 4.2, 1.6, 1.2, "marcador", 0.0, 1.0, 0.125)
	# the white sheet door (the hall's west one), shut
	box(23.6, 0.0, 0.0, 2.2, 2.7, 0.03, "gris")
	box(23.7, 0.0, 0.03, 0.98, 2.6, 0.02, "tubo")
	box(24.72, 0.0, 0.03, 0.98, 2.6, 0.02, "tubo")
	# loudspeakers, the fire bell, the way out's sign over the door
	for x in [8.6, 35.2]:
		box(x, 5.2, 0.0, 0.45, 0.7, 0.4, "negro")
	box(20.2, 1.6, 0.0, 0.3, 0.3, 0.08, "poste_rojo")
	box(24.3, 2.8, 0.0, 0.8, 0.28, 0.04, "verde")
	home()
	props += 6

# ---------------- the lamps ----------------
func _lamps() -> void:
	for b in range(4):
		for t in [0.3, 0.72]:
			var x := lerpf(float(BAYS[b]), float(BAYS[b + 1]), t)
			for z in [3.5, 10.0, 16.5, 23.0]:
				var y := _roof_at(x) - 0.9
				box(x - 0.25, y, z - 0.25, 0.5, 0.06, 0.5, "luz")
				box(x - 0.02, y + 0.06, z - 0.02, 0.04, 0.84, 0.04, "gris")
	for at in [Vector3(-16.5, 6.4, 11.0), Vector3(-5.5, 6.4, 11.0), Vector3(5.5, 6.4, 11.0), Vector3(16.5, 6.4, 11.0),
			Vector3(-16.5, 6.4, 22.0), Vector3(-5.5, 6.4, 22.0), Vector3(5.5, 6.4, 22.0), Vector3(16.5, 6.4, 22.0), Vector3(0.0, 2.4, 2.6)]:
		var lamp := OmniLight3D.new()
		lamp.position = at
		lamp.light_color = Color(1.0, 0.98, 0.94)
		lamp.omni_range = 15.0 if at.y > 3.0 else 6.0
		lamp.light_energy = 0.55
		lamp.shadow_enabled = false
		lamp.light_cull_mask = 1 << 10
		add_child(lamp)
		lamps += 1
