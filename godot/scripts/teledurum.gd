extends "res://scripts/obra.gd"
## The kebab house of the Calle de Santa Ana, "Tele Dürum" in the game, built by hand (the user, 15 November 2026: "Podemos
## proseguir con el Kebab de la calle santa ana, el Tele Kebab, lo llamaremos Tele Dürum. Tiene una máquina de bolas en
## la entrada"; referencias/tele_durum/, tools/teledurum/).
##
## As Street View has it in November 2024: a house of two floors between its neighbours. Below, brown brick on a foot
## of pale tiles: a wooden door with a grille over it at the left, a window, the shop's way in -- glass doors set back,
## a menu on the jamb -- and a wider window; each of the three under its grey shutter (see its hours, below).
## Over the way in, the red board with its name, a pizza at one end and the spit at the other; beside it a smaller
## cream sign; an air conditioner, the meter boxes. The upper floor comes out over the pavement: cream render gone
## grey in streaks, three windows framed in brick behind brown blinds, another air conditioner, a brick cornice, tiles.
## And at the door, on the pavement, the gumball machine: red, on its stand, its globe full of coloured balls.
##
## It is the house `stana_44` of the map (casas_calles.gd marks it "obra": casas.gd draws nothing of it); the kebab
## lorry's mission (sabotaje.gd) goes on finding it by that name. Frame: the house's own -- origin at the left end of
## its front seen from the street (east), +x along the front, +z out into the street, y = 0 its floor.
## It keeps hours (the user, the same day: "Podríamos abrir el negocio de 18:00 a 04:00 (puertas abiertas y luces
## encendidas) además de añadir el kebab girando que ya tenemos hecho en kebab luis. Y verjas de las ventanas subidas
## cuando abierto y bajadas cuando cerrado"): shut, every shutter is down; open, they are rolled up, the glass doors
## stand open, the lights are on and the spit -- Kebab Luis's own (kebab.gd), piece for piece -- turns before its fire.
## Nobody goes in: you look in from the street.

const GachaS = preload("res://scripts/gacha.gd")
const HOUSE := "stana_44"
const NAME := "TELE DÜRUM"
const FLOOR := 4.1                              # where the upper floor begins
const BAY := 0.45                               # how far it comes out over the pavement
const RED := 0xd0202a
const BRONZE := 0x6a5a40
const OPENS := 18.0                              # it opens at six in the evening...
const SHUTS := 4.0                               # ...and shuts at four in the morning
const SHUTTER := 0x9a9c9a
const DOOR := Rect2(0.15, 0.0, 0.95, 2.2)       # the house's own door (x, y, wide, tall)
const WIN_A := Rect2(1.35, 0.85, 1.75, 1.9)     # the window by the door
const WAY_IN := Rect2(3.55, 0.0, 2.6, 2.75)     # the shop's way in
const WIN_C := Rect2(6.7, 0.85, 3.4, 1.9)       # the wide window
const SPIT_X := 5.3                             # where the spit stands, along the front: seen through the open doors

var len_front := 10.36
var top := 6.4
var door: Vector2               # in front of the shop's way in, on the map
var gumball: Vector2            # where the gumball machine stands, on the map
var gumball_node: Node3D        # the machine itself (gacha.gd)
var is_open := false
var _shut: Node3D               # what shows only while it is shut: the shutters down
var _open: Node3D               # what shows only while it is open: the shutters rolled up, the doors open, the lamps, the fire's glow
var _spit: Node3D               # the meat on its spit
var _lights: Array = []

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"ladrillo":         # brown-red facing brick
			m = Tex.mat("brick_wall_003", Color(0.72, 0.7, 0.72))
		"crema":            # the upper floor's render
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.94, 0.9, 0.8)), 0.32)
		"azulejo":          # the foot of pale tiles
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.95, 0.94, 0.9)), 0.3)
		"interior":
			var im := StandardMaterial3D.new()
			im.albedo_color = Color(0.93, 0.86, 0.72)
			im.emission_enabled = true
			im.emission = Color(0.9, 0.82, 0.66)
			im.emission_energy_multiplier = 0.42
			m = im
		"brasa":            # the fire behind the spit
			var bm := StandardMaterial3D.new()
			bm.albedo_color = Color(1.0, 0.42, 0.1)
			bm.emission_enabled = true
			bm.emission = Color(1.0, 0.42, 0.1)
			bm.emission_energy_multiplier = 1.5
			m = bm
		"luz":              # a lamp, lit
			var lm := StandardMaterial3D.new()
			lm.albedo_color = Color(1.0, 0.98, 0.9)
			lm.emission_enabled = true
			lm.emission = Color(1.0, 0.96, 0.86)
			lm.emission_energy_multiplier = 2.0
			m = lm
		"vidrio":
			var gm := StandardMaterial3D.new()
			gm.albedo_color = Color(0.66, 0.8, 0.84, 0.26)
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.roughness = 0.06
			gm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = gm
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
	top = maxf(float(hd.get("h", 6.4)), 7.3)
	level = float(hd["base"])
	transform = Transform3D(Basis(Vector3(u.x, 0, u.y), Vector3.UP, Vector3(out.x, 0, out.y)), Vector3(o.x, level, o.y))
	W.add_child(self)
	door = spot(WAY_IN.position.x + WAY_IN.size.x / 2.0, 1.2)
	_body(hd)
	_ground_floor()
	_way_in()
	_signs()
	_upper_floor()
	_gumball(Vector2(WAY_IN.position.x + 0.22, 0.24))      # (at the left of the way in, close to the wall: the pavement is half a metre wide here)
	_bin(Vector2(len_front - 0.25, 0.14))
	home()
	_commit()
	_states()

# ---------------- what is not its front ----------------
## Its other walls, as the map has its plot, and its roof of tiles: one ridge along the street.
func _body(hd: Dictionary) -> void:
	var inv := transform.affine_inverse()
	var deep := 0.0
	for pc in hd.get("pieces", []):
		var raw: Array = pc["ring"]
		var ring: Array = []
		for i in range(0, raw.size(), 2):
			var q: Vector3 = inv * Vector3(float(raw[i]), level, float(raw[i + 1]))
			ring.append(Vector2(q.x, q.z))
			deep = minf(deep, q.z)
		for i in range(ring.size()):
			var a: Vector2 = ring[i]
			var b: Vector2 = ring[(i + 1) % ring.size()]
			if absf(a.y) < 0.3 and absf(b.y) < 0.3:
				continue
			_plain(a, b, -2.0, top, "crema")
			_plain(b, a, -2.0, top, "crema")
	var ye: float = top + 0.42
	var zf: float = BAY + 0.35
	var zr: float = maxf(deep / 2.0, -6.0)
	var yr: float = ye + (zf - zr) * 0.36
	var yb: float = maxf(top - 0.4, yr - (zr - deep) * 0.36)
	var x0 := -0.05
	var x1: float = len_front + 0.05
	roof([Vector3(x0, ye, zf), Vector3(x1, ye, zf), Vector3(x1, yr, zr), Vector3(x0, yr, zr)])
	roof([Vector3(x1, yb, deep), Vector3(x0, yb, deep), Vector3(x0, yr, zr), Vector3(x1, yr, zr)])
	ridge(Vector3(x0, yr, zr), Vector3(x1, yr, zr))
	for x in [x0 + 0.05, x1 - 0.05]:                # its two gables, over the neighbours' roofs
		for n in [Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
			tri(Vector3(x, top, 0.0), Vector3(x, top, deep), Vector3(x, yr, zr), "crema", n)
			tri(Vector3(x, top, 0.0), Vector3(x, ye, zf), Vector3(x, yr, zr), "crema", n)

# ---------------- the ground floor ----------------
## a shutter of grey slats filling a hole of the wall being built, from `from_y` up (all of it if not given), under its box
func _shutter(r: Rect2, from_y := -1.0) -> void:
	var y0: float = r.position.y if from_y < 0.0 else from_y
	box(r.position.x, y0, -0.14, r.size.x, r.end.y - y0, 0.05, SHUTTER)
	var n := int((r.end.y - y0) / 0.11)
	for j in range(1, n):
		box(r.position.x, y0 + j * 0.11, -0.09, r.size.x, 0.012, 0.004, 0x7c7e7c)
	box(r.position.x - 0.04, r.end.y - 0.02, -0.16, r.size.x + 0.08, 0.14, 0.2, 0x8a8c8a)      # its box

func _ground_floor() -> void:
	var ln: float = len_front
	face(Vector2(0, 0), Vector2(ln, 0))
	var grille := Rect2(DOOR.position.x, DOOR.end.y + 0.08, DOOR.size.x, 0.36)
	masonry(0.0, ln, -1.5, FLOOR, [DOOR, grille, WIN_A, WAY_IN, WIN_C], [], "ladrillo")
	# the foot of pale tiles, between the door and the way in and beyond it
	for q in [[0.0, DOOR.position.x - 0.12], [DOOR.end.x + 0.12, WAY_IN.position.x - 0.02], [WAY_IN.end.x + 0.02, ln]]:
		box(q[0], -1.5, 0.0, q[1] - q[0], 2.3, 0.035, "azulejo")
		var n := int((q[1] - q[0]) / 0.4)
		for i in range(1, n):
			box(q[0] + i * (q[1] - q[0]) / n - 0.004, 0.0, 0.035, 0.008, 0.8, 0.003, 0xcfcabf)
		box(q[0], 0.4, 0.035, q[1] - q[0], 0.008, 0.003, 0xcfcabf)
	box(7.2, 0.15, 0.036, 0.4, 0.25, 0.01, 0x8a8f96)                                    # a vent in it
	# the house's door: panelled wood, a turned grille over it
	box(DOOR.position.x, 0.0, -DEEP, DOOR.size.x, DOOR.size.y, 0.05, 0x7a4a26)
	for i in range(2):
		for j in range(3):
			box(DOOR.position.x + 0.07 + i * (DOOR.size.x / 2.0 - 0.02), 0.12 + j * 0.7, -DEEP + 0.05, DOOR.size.x / 2.0 - 0.12, 0.58, 0.02, 0x8f5a30)
	box(grille.position.x, grille.position.y, -DEEP, grille.size.x, grille.size.y, 0.03, 0x2a2622)
	for i in range(8):
		box(grille.position.x + 0.05 + i * (grille.size.x - 0.14) / 7.0, grille.position.y, -DEEP + 0.04, 0.035, grille.size.y, 0.035, 0x7a4a26)
	box(DOOR.end.x + 0.04, 1.25, 0.0, 0.17, 0.3, 0.05, 0xe9e6dc)                        # the entry phone
	# the two windows: glass in bronze frames (behind their shutters while the shop is shut)
	for w: Rect2 in [WIN_A, WIN_C]:
		quad(Vector3(w.position.x, w.position.y, -DEEP + 0.08), Vector3(w.end.x, w.position.y, -DEEP + 0.08), Vector3(w.end.x, w.end.y, -DEEP + 0.08), Vector3(w.position.x, w.end.y, -DEEP + 0.08), "vidrio", Vector3(0, 0, 1))
		var panes: int = 2 if w.size.x < 2.5 else 3
		for i in range(panes + 1):
			box(w.position.x + i * (w.size.x - 0.06) / panes, w.position.y, -DEEP + 0.05, 0.06, w.size.y, 0.07, BRONZE)
		box(w.position.x, w.position.y, -DEEP + 0.05, w.size.x, 0.06, 0.07, BRONZE)
		box(w.position.x, w.end.y - 0.06, -DEEP + 0.05, w.size.x, 0.06, 0.07, BRONZE)
		box(w.position.x - 0.05, w.position.y - 0.06, 0.0, w.size.x + 0.1, 0.06, 0.07, 0xd9d4c8)
	# the air conditioner at the far end, the meter boxes, the wires
	box(ln - 1.05, 2.98, 0.0, 0.85, 0.62, 0.3, 0xf1f0ea)
	slab(oval(ln - 0.72, 3.29, 0.24, 0.24, 12), 0.31, 0.0, 0x9a9c9e)
	box(WAY_IN.position.x - 0.42, 2.98, 0.0, 0.26, 0.42, 0.1, 0xf1f0ea)
	box(1.6, 3.1, 0.0, 0.2, 0.3, 0.08, 0xe9e6dc)
	bar(Vector3(1.7, 3.34, 0.05), Vector3(WAY_IN.position.x - 0.3, 3.3, 0.05), 0.02, 0.02, 0x2a2a2c)
	home()

## The way in -- the doors of glass set back in their gold frames, the menu on the jamb -- and the shop itself, seen
## through doors and windows: the counter and the lit menu over it, the stand of the spit, tables and stools.
func _way_in() -> void:
	var a: float = WAY_IN.position.x
	var b: float = WAY_IN.end.x
	var h: float = WAY_IN.end.y
	var inn := 0.7
	for n in [1.0, -1.0]:                           # the sides of the recess, seen from the door and from inside
		quad(Vector3(a, 0, -inn), Vector3(a, 0, -DEEP), Vector3(a, h, -DEEP), Vector3(a, h, -inn), "azulejo", Vector3(n, 0, 0))
		quad(Vector3(b, 0, -inn), Vector3(b, 0, -DEEP), Vector3(b, h, -DEEP), Vector3(b, h, -inn), "azulejo", Vector3(-n, 0, 0))
	quad(Vector3(a, h, -inn), Vector3(b, h, -inn), Vector3(b, h, -DEEP), Vector3(a, h, -DEEP), 0x8a8478, Vector3(0, -1, 0))
	quad(Vector3(a, 0.02, -inn), Vector3(b, 0.02, -inn), Vector3(b, 0.02, 0.0), Vector3(a, 0.02, 0.0), 0xb9a58c, Vector3.UP)
	# the door's frame of gold aluminium: a fixed pane at the left, the two leaves' opening, glass over it all
	var gold := 0xa98a4a
	var fx: float = a + 0.72
	quad(Vector3(a, 0, -inn), Vector3(fx, 0, -inn), Vector3(fx, h, -inn), Vector3(a, h, -inn), "vidrio", Vector3(0, 0, 1))
	quad(Vector3(fx, 2.1, -inn), Vector3(b, 2.1, -inn), Vector3(b, h, -inn), Vector3(fx, h, -inn), "vidrio", Vector3(0, 0, 1))
	for q in [a + 0.012, fx, b - 0.072]:
		box(q, 0.0, -inn, 0.06, h, 0.06, gold)
	for y in [2.1, h - 0.06]:
		box(a, y, -inn, b - a, 0.06, 0.06, gold)
	box(a, 0.0, -inn, fx - a, 0.06, 0.06, gold)
	# the menu on the right jamb: a board of pictures
	var keep := _xf
	_xf = keep * Transform3D(Basis(Vector3.UP, -PI / 2.0), Vector3(b - 0.01, 0.0, -0.68))
	box(0.05, 0.75, 0.0, 0.5, 1.15, 0.015, 0xfdf2c8)
	for j in range(4):
		for i in range(2):
			slab(oval(0.18 + i * 0.24, 0.92 + j * 0.27, 0.085, 0.085, 10), 0.02, 0.0, [0xd9a25a, 0xc8502a, 0xf2c94a, 0x8a5a36][(i + j) % 4])
	_xf = keep
	# the shop: its walls, floor and ceiling, from beside the house's door to the far end
	var x0: float = DOOR.end.x + 0.2
	var x1: float = len_front - 0.2
	var back := -4.2
	var zi: float = -DEEP - 0.02
	quad(Vector3(x0, 0, back), Vector3(x1, 0, back), Vector3(x1, h, back), Vector3(x0, h, back), "interior", Vector3(0, 0, 1))
	quad(Vector3(x0, 0, back), Vector3(x0, 0, zi), Vector3(x0, h, zi), Vector3(x0, h, back), "interior", Vector3(1, 0, 0))
	quad(Vector3(x1, 0, back), Vector3(x1, 0, zi), Vector3(x1, h, zi), Vector3(x1, h, back), "interior", Vector3(-1, 0, 0))
	quad(Vector3(x0, h, back), Vector3(x1, h, back), Vector3(x1, h, -inn), Vector3(x0, h, -inn), "interior", Vector3(0, -1, 0))
	quad(Vector3(x0, 0.02, back), Vector3(x1, 0.02, back), Vector3(x1, 0.02, -inn), Vector3(x0, 0.02, -inn), 0xb9774f, Vector3.UP)
	for q in [[x0, WIN_A.position.x, 0.0, h], [WIN_A.end.x, a, 0.0, h], [b, WIN_C.position.x, 0.0, h], [WIN_C.end.x, x1, 0.0, h],      # the inside of the front wall
			[WIN_A.position.x, WIN_A.end.x, 0.0, WIN_A.position.y], [WIN_C.position.x, WIN_C.end.x, 0.0, WIN_C.position.y]]:
		quad(Vector3(q[0], q[2], zi), Vector3(q[1], q[2], zi), Vector3(q[1], q[3], zi), Vector3(q[0], q[3], zi), "interior", Vector3(0, 0, -1))
	box(x0 + 0.5, 0.0, -3.3, 6.0, 1.05, 0.6, RED)                                       # the counter
	box(x0 + 0.4, 1.05, -3.4, 6.2, 0.05, 0.8, 0xf4f1e8)
	for i in range(2):                              # the menu over it, lit
		box(x0 + 0.6 + i * 1.7, 1.7, back + 0.01, 1.5, 0.62, 0.03, 0xfdf2c8)
		for j in range(3):
			box(x0 + 0.7 + i * 1.7, 1.8 + j * 0.17, back + 0.04, 0.95, 0.03, 0.006, 0x8a2a1e if j == 2 else 0x4a3a2a)
	cbox(Vector3(SPIT_X, 0.52, back + 0.45), Vector3(0.9, 1.04, 0.5), 0x9a9da0)          # the steel stand of the spit, its back plate
	cbox(Vector3(SPIT_X, 1.85, back + 0.12), Vector3(0.9, 1.7, 0.06), 0x8f9498)
	cbox(Vector3(SPIT_X, 2.66, back + 0.4), Vector3(1.0, 0.06, 0.6), 0x8f9498)
	box(x1 - 0.95, 0.0, back + 0.02, 0.8, 1.9, 0.6, 0x2a2a2c)                           # the fridge of drinks
	box(x1 - 0.89, 0.2, back + 0.62, 0.68, 1.6, 0.01, 0xbfe0ea)
	for t in [Vector2(2.2, -1.5), Vector2(7.7, -1.5), Vector2(9.2, -1.5)]:              # tables by the windows
		cbox(Vector3(t.x, 0.74, t.y), Vector3(0.7, 0.04, 0.7), 0xf4f1e8)
		cbox(Vector3(t.x, 0.37, t.y), Vector3(0.08, 0.72, 0.08), 0x4a4d52)
		for s2 in [-1.0, 1.0]:
			cbox(Vector3(t.x, 0.23, t.y + s2 * 0.62), Vector3(0.34, 0.46, 0.34), RED)

# ---------------- shut and open ----------------
## whether it is open at that hour of the day
func open_at(hour: float) -> bool:
	return hour >= OPENS or hour < SHUTS

## what has been built since the last commit becomes meshes under `node`: a part that can be shown and hidden
func _commit_to(node: Node3D) -> void:
	for key in _tools:
		var mi := MeshInstance3D.new()
		mi.mesh = (_tools[key] as SurfaceTool).commit()
		mi.material_override = _material(key)
		node.add_child(mi)
	_tools.clear()

## The two faces of it. Shut: every shutter down. Open: the shutters rolled up into their boxes, the two glass leaves
## swung in, lamps lit on the ceiling and over the door, the fire glowing behind the spit; and the spit itself.
func _states() -> void:
	var a: float = WAY_IN.position.x
	var b: float = WAY_IN.end.x
	var h: float = WAY_IN.end.y
	var holes: Array = [WIN_A, WIN_C, Rect2(a, 0.0, b - a, h)]
	_shut = Node3D.new()
	add_child(_shut)
	face(Vector2(0, 0), Vector2(len_front, 0))
	for r: Rect2 in holes:
		_shutter(r)
	home()
	_commit_to(_shut)
	_open = Node3D.new()
	add_child(_open)
	face(Vector2(0, 0), Vector2(len_front, 0))
	for r: Rect2 in holes:
		_shutter(r, r.end.y - 0.2)
	home()
	var gold := 0xa98a4a
	for hx in [a + 0.75, b - 0.09]:                 # the two leaves, open: back against the walls of the shop
		quad(Vector3(hx, 0.06, -0.7), Vector3(hx, 0.06, -1.6), Vector3(hx, 2.1, -1.6), Vector3(hx, 2.1, -0.7), "vidrio", Vector3(1, 0, 0))
		for q in [-0.76, -1.6]:
			box(hx - 0.03, 0.0, q, 0.06, 2.1, 0.06, gold)
		for y in [0.0, 2.04]:
			box(hx - 0.03, y, -1.6, 0.06, 0.06, 0.9, gold)
	var back := -4.2
	for x in [2.4, 4.85, 7.3, 9.2]:                 # the strip lamps on the ceiling
		cbox(Vector3(x, h - 0.04, -2.2), Vector3(1.2, 0.05, 0.14), "luz")
	for i in range(4):                              # the fire behind the spit
		cbox(Vector3(SPIT_X, 1.25 + i * 0.36, back + 0.17), Vector3(0.7, 0.22, 0.03), "brasa")
	cbox(Vector3(a + (b - a) / 2.0, h + 0.02, 0.12), Vector3(0.5, 0.06, 0.12), "luz")       # the lamp over the door
	_commit_to(_open)
	for q in [[Vector3(4.85, 2.3, -2.2), Color(1.0, 0.93, 0.8), 6.5, 0.7], [Vector3(8.4, 2.3, -2.0), Color(1.0, 0.93, 0.8), 5.0, 0.5],
			[Vector3(a + (b - a) / 2.0, 2.5, 0.7), Color(1.0, 0.92, 0.78), 4.5, 0.9], [Vector3(SPIT_X, 1.8, back + 1.2), Color(1.0, 0.55, 0.25), 2.2, 0.35]]:
		var lamp := OmniLight3D.new()
		lamp.position = q[0]
		lamp.light_color = q[1]
		lamp.omni_range = q[2]
		lamp.light_energy = q[3]
		add_child(lamp)
		_lights.append(lamp)
	# the meat on its spit: Kebab Luis's own (kebab.gd), piece for piece
	_spit = Node3D.new()
	_spit.position = Vector3(SPIT_X, 1.05, back + 0.5)
	_spit.scale = Vector3(1.15, 1.0, 1.15)
	add_child(_spit)
	_spit.add_child(Parts.part("cyl", 0xcfd3d6, Vector3(0, 0.72, 0), Vector3(0.018, 1.46, 0.018)))
	var meat := [0x9a5a2c, 0xa8662f, 0x8a4c24, 0xb0703a]
	for i in range(11):                             # slabs one on another, fatter at the top, none quite true
		var f := i / 10.0
		var r := lerpf(0.13, 0.27, f) * (1.0 + 0.06 * sin(i * 2.3))
		_spit.add_child(Parts.part("cyl", meat[i % 4], Vector3(0.012 * sin(i * 1.7), 0.14 + i * 0.105, 0.012 * cos(i * 2.1)), Vector3(r, 0.11, r)))
		if i % 3 == 0:                              # a charred patch, so that the turning shows
			_spit.add_child(Parts.part("box", 0x4a2a16, Vector3(r * 0.86, 0.14 + i * 0.105, 0.0), Vector3(0.05, 0.1, 0.16)))
	_spit.add_child(Parts.part("cone", 0xd9c7a0, Vector3(0, 1.36, 0), Vector3(0.1, 0.16, 0.1)))       # the onion on top
	_spit.add_child(Parts.part("cyl", 0x8f9498, Vector3(0, 0.03, 0), Vector3(0.3, 0.04, 0.3)))        # the dish that takes the dripping
	set_open(false)

func set_open(on: bool) -> void:
	is_open = on
	if _shut != null:
		_shut.visible = not on
		_open.visible = on
	for lamp in _lights:
		(lamp as Light3D).visible = on

func _process(delta: float) -> void:
	var game = W.get_parent() if W != null else null
	if game != null and "clock" in game:
		var want: bool = open_at(float(game.clock))
		if want != is_open:
			set_open(want)
	turn(delta)

## the spit goes round while the shop is open
func turn(delta: float) -> void:
	if is_open and _spit != null:
		_spit.rotate_y(delta * 1.1)

# ---------------- its signs ----------------
func _signs() -> void:
	face(Vector2(0, 0), Vector2(len_front, 0))
	var x0: float = WAY_IN.position.x
	var w: float = WAY_IN.size.x
	var y0 := 2.88
	var hh := 1.0
	box(x0 - 0.03, y0 - 0.03, 0.0, w + 0.06, hh + 0.06, 0.07, 0xf4f1e8)                 # the red board, its white edge
	box(x0, y0, 0.07, w, hh, 0.02, RED)
	_text("PIZZERÍA", Vector3(x0 + w * 0.5, y0 + hh * 0.76, 0.1), 32, 0x1c1c1e, 0.0066)
	var big := _text(NAME, Vector3(x0 + w * 0.5, y0 + hh * 0.34, 0.1), 64, 0xfdfcf8, 0.004)
	big.outline_size = 10
	big.outline_modulate = Color(0.1, 0.08, 0.08)
	# a pizza at one end...
	var px: float = x0 + 0.27
	var py: float = y0 + hh * 0.5
	py = y0 + hh * 0.66
	slab(oval(px, py, 0.24, 0.24, 16), 0.095, 0.0, 0xd9a25a)
	slab(oval(px, py, 0.195, 0.195, 16), 0.1, 0.0, 0xf2c94a)
	for k in range(5):
		slab(oval(px + cos(TAU * k / 5.0) * 0.1, py + sin(TAU * k / 5.0) * 0.1, 0.035, 0.035, 8), 0.105, 0.0, 0xb8281e)
	# ...and the spit at the other
	var sx: float = x0 + w - 0.24
	slab(PackedVector2Array([Vector2(sx - 0.07, y0 + 0.12), Vector2(sx + 0.07, y0 + 0.12), Vector2(sx + 0.13, y0 + hh - 0.1), Vector2(sx - 0.13, y0 + hh - 0.1)]), 0.095, 0.0, 0x8a4a26)
	for j in range(4):
		box(sx - 0.1, y0 + 0.17 + j * 0.09, 0.096, 0.2, 0.012, 0.004, 0x6a3418)
	box(sx - 0.012, y0 + 0.04, 0.094, 0.024, hh - 0.08, 0.004, 0xd9dde0)
	# the smaller sign beside it: cream, its name again and where the number goes
	var cx: float = WAY_IN.end.x + 0.18
	box(cx, 2.95, 0.0, 0.66, 0.8, 0.14, 0xf6efdc)
	_text("Tele\nDürum", Vector3(cx + 0.33, 3.46, 0.15), 32, 0xb8281e, 0.0048)
	for i in range(6):                              # a scribble where the telephone number goes
		box(cx + 0.1 + i * 0.075, 3.06 + 0.02 * (i % 2), 0.14, 0.055, 0.03, 0.005, 0x1c1c1e)
	home()

# ---------------- the upper floor ----------------
func _upper_floor() -> void:
	var ln: float = len_front
	quad(Vector3(0, FLOOR, 0), Vector3(ln, FLOOR, 0), Vector3(ln, FLOOR, BAY), Vector3(0, FLOOR, BAY), 0x6a5a4c, Vector3(0, -1, 0))      # what you see of it from below
	for x in [0.0, ln]:
		for n in [Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
			quad(Vector3(x, FLOOR, 0), Vector3(x, FLOOR, BAY), Vector3(x, top, BAY), Vector3(x, top, 0), "crema", n)
	face(Vector2(0, BAY), Vector2(ln, BAY))
	var wins: Array = []
	for c in [1.75, ln * 0.5, ln - 1.75]:
		wins.append(Rect2(c - 0.65, 5.25, 1.3, 1.3))
	masonry(0.0, ln, FLOOR, top, wins, [], "crema")
	box(0.0, FLOOR, 0.0, ln, 0.14, 0.05, 0x8a7a6a)                                      # the moulding at its foot
	var k := 0
	for w: Rect2 in wins:
		for q in [[w.position.x - 0.22, w.position.y - 0.22, 0.22, w.size.y + 0.44], [w.end.x, w.position.y - 0.22, 0.22, w.size.y + 0.44],
				[w.position.x - 0.22, w.end.y, w.size.x + 0.44, 0.22], [w.position.x - 0.22, w.position.y - 0.22, w.size.x + 0.44, 0.22]]:
			box(q[0], q[1], 0.0, q[2], q[3], 0.04, "ladrillo")
		window(w, 0x5a4636, 0x39566a, 0)
		var down: float = [0.55, 1.0, 0.5][k]            # its brown blind: how far down
		box(w.position.x + 0.04, w.end.y - w.size.y * down, -DEEP + 0.1, w.size.x - 0.08, w.size.y * down - 0.02, 0.05, 0x6a4636)
		for s in [0.25, 0.6]:                           # where the rain has run down the render under it
			box(w.position.x + w.size.x * s, FLOOR + 0.14, 0.0, 0.14, w.position.y - 0.36 - FLOOR, 0.004, 0xcfc8b8)
		k += 1
	box(wins[0].end.x + 0.75, 5.4, 0.0, 0.85, 0.6, 0.3, 0xf1f0ea)                       # an air conditioner on its bracket
	slab(oval(wins[0].end.x + 1.08, 5.7, 0.23, 0.23, 12), 0.31, 0.0, 0x9a9c9e)
	cornice(0.0, ln, top + 0.42, true, "ladrillo")
	home()

# ---------------- on the pavement ----------------
## The gumball machine by the door: a red foot and stand, the red box of its coin slot, a globe of glass full of
## coloured balls, a red cap. (No free model of one was to be had: it is made in the game's own toy-like way.) It is a
## node of its own, drawn by gacha.gd, so that it can shake when a euro goes in (the user's "gacha", 16 Nov 2026).
func _gumball(at: Vector2) -> void:
	gumball = spot(at.x, at.y)
	var g: float = ground(at.x, at.y)
	gumball_node = GachaS.machine()
	gumball_node.position = Vector3(at.x, g, at.y)       # (its slot towards +z: the street)
	add_child(gumball_node)
	solid(Vector3(at.x, g + 0.7, at.y), Vector3(0.44, 1.4, 0.44))
	yard.append(gumball)

## the street's litter bin on its post
func _bin(at: Vector2) -> void:
	var g: float = ground(at.x, at.y)
	cbox(Vector3(at.x, g + 0.55, at.y), Vector3(0.05, 1.1, 0.05), 0x2a2a2c)
	drum(Vector3(at.x, g + 0.5, at.y + 0.18), 0.15, 0.18, 0.5, 0x1c1c1e, 10)
	solid(Vector3(at.x, g + 0.6, at.y + 0.1), Vector3(0.4, 1.2, 0.5))
	yard.append(spot(at.x, at.y))
