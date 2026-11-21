extends "res://scripts/obra.gd"
## The Cafetería Rize and its alley, off the Avenida de Juan Carlos I (the user, 21 November 2026: "El siguiente
## objetivo es la cafetería rice con todo su callejón incluido. Hay una foto 360° dentro del callejón", and then "Lo
## llamaremos al local Rize en vez de Rice"). Built by hand from Catastro (the café is 4091010VJ5649S, a shop of one
## floor of 1975; the little garage opposite, 4091028), a person's 360 photo from the alley's end (February 2020) and
## Street View from the avenue (November 2024); referencias/rice/, tools/rice/.
##
## The alley goes in northwards from the avenue between two brick houses (Texturas's juancarlos_10 on the left,
## juancarlos_4 on the right), 4 m wide, paved in grey setts (the bake closes it to traffic), and rises a metre to its
## end, where it widens. Then:
##   - on the right, the café: a long white wall over a foot of grey granite tiles, under a dark eave; three windows
##     set on their corners, like diamonds, behind black bars; its door up three steps of stone under an awning with
##     its name; spotlights along the wall; its tables and chairs out along the wall, the crates of empties, the
##     stacked chairs and a keg in the corner by the end;
##   - across the end, an old wall of rendered earth with a big green door of two leaves, a jar of sand by it for the
##     cigarette ends, the closed parasols leaning against it;
##   - on the left, a low white garage under corrugated sheet: an emblem painted on its wall (the game's own: a
##     yellow shield, a black quiff and a black moustache, SIEMPRE DE FIESTA; the real one is a peña's) and branches in
##     flower painted on its white door; then a grey house with openings framed in pale stone and a wide white garage
##     door -- a skin of mine over the side of Texturas's juancarlos_10, whose own side is plain brick;
##   - at the alley's mouth, while the café is open, its blackboard: RIZE, ¡ABIERTO!, Tapas, Raciones, Menú diario.
## Open as the real one: shut on Mondays; Tuesdays and Wednesdays from 9 to 5; Thursdays to Sundays from 9 to 7.
## Open: the awning out, the door in, the blackboard out. No inside yet.
## Before the café, by the emblem, is where Marciano stands (the user's: a stout man with a moustache and a black
## quiff, who talks of the parties of the eighties): Sistemas places him at `marciano_spot`; nobody is modelled here.
## A saffron flower is hidden behind the crates in the corner (the user: one in every special place).
##
## Frame: the map's own; y = 0 the alley before the café's middle.

const READY := true
const NAME := "Cafetería Rize"
const DIR := "res://assets/rize/"
const CN := Vector2(-196.82, 85.25)       # the café's wall on the alley: its north end (the corner with the end wall)...
const CS := Vector2(-195.03, 99.70)       # ...and its south end (where the brick house begins)
const CAFE := [Vector2(-196.82, 85.25), Vector2(-189.41, 84.91), Vector2(-179.58, 83.80), Vector2(-179.26, 98.75), Vector2(-184.38, 99.06), Vector2(-195.03, 99.70)]
const EW := Vector2(-203.05, 85.53)       # the end wall's west end: the garage's corner
const GS := Vector2(-201.61, 90.97)       # the garage's south corner on the alley
const GARAGE := [Vector2(-203.05, 85.53), Vector2(-201.61, 90.97), Vector2(-208.50, 91.51), Vector2(-208.56, 85.78)]
const HS := Vector2(-199.24, 99.89)       # the grey house: the south end of its stretch of the alley
const MOUTH := Vector2(-196.3, 111.6)     # where the blackboard stands, by the left wall at the alley's mouth
const EAVE := 4.3                         # the café's eave, over the alley at its north end
const DIAMONDS := [3.4, 5.75, 8.1]        # the three windows: their middles, metres along the wall from its north end
const DOOR := [10.3, 12.1]                # the way in
const HOURS := {1: Vector2(9.0, 17.0), 2: Vector2(9.0, 17.0), 3: Vector2(9.0, 19.0), 4: Vector2(9.0, 19.0), 5: Vector2(9.0, 19.0), 6: Vector2(9.0, 19.0)}      # day (0 Monday ... 6 Sunday): from when to when. Mondays shut
const DOWN := -3.0
const IRON_HEX := 0x1c1c1e

var door: Vector2                         # before the café's door, in the alley
var marciano_spot: Vector2                # where Marciano stands, opposite the café, by the emblem
var marciano_h := 0.0                     # ...and which way he looks (at the café)
var saffron_spot: Vector2
var is_open := false
var outlines: Array = []
var lamps: Array = []
var _shut: Node3D
var _open: Node3D

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"granito":          # the café's foot: grey granite tiles
			m = Tex.mat("granular_concrete", Color(0.62, 0.63, 0.65))
		"tapia":            # the end wall's old render, the colour of the earth under it
			m = Tex.mat("painted_plaster_wall", Color(0.82, 0.72, 0.56))
		"cal_vieja":        # its whitewashed foot, flaking
			m = Tex.mat("painted_plaster_wall", Color(0.94, 0.93, 0.9))
		"gris":             # the grey house's render
			m = Tex.mat("painted_plaster_wall", Color(0.52, 0.53, 0.55))
		"travertino":       # its frames and its foot: pale stone
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.9, 0.7)), 0.2)      # (so it reads cream in the shade of the alley too)
		"verde":            # the big door: old green paint on planks
			m = Tex.mat("old_planks_02", Color(0.24, 0.6, 0.26))
		"adoquin":          # the alley's grey setts, as empedrado.gd lays them along it
			var am := StandardMaterial3D.new()
			am.albedo_texture = load("res://assets/empedrado/adoquin_gris.png")
			am.uv1_triplanar = true
			am.uv1_world_triplanar = true
			am.uv1_scale = Vector3.ONE / 2.0
			am.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			m = am
		"uralita":          # the garage's corrugated sheet
			var um := StandardMaterial3D.new()
			um.albedo_texture = load("res://assets/masahorro/chapa.png")
			um.albedo_color = Color(0.5, 0.52, 0.55)
			um.uv1_triplanar = true
			um.uv1_scale = Vector3.ONE * 1.5
			um.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = um
		"cristal":
			var gm := StandardMaterial3D.new()
			gm.albedo_color = Color(0.12, 0.16, 0.19)
			gm.roughness = 0.12
			gm.metallic_specular = 0.7
			m = gm
		"toldo":            # the awning's cloth
			var tm := StandardMaterial3D.new()
			tm.albedo_color = Color(0.12, 0.2, 0.47)
			tm.roughness = 1.0
			tm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = tm
		"luz":
			var lm := StandardMaterial3D.new()
			lm.albedo_color = Color(1.0, 0.97, 0.88)
			lm.emission_enabled = true
			lm.emission = Color(1.0, 0.95, 0.82)
			lm.emission_energy_multiplier = 1.4
			m = lm
		"mural", "ramas", "pizarra", "rotulo":
			var pm := StandardMaterial3D.new()
			pm.albedo_texture = load(DIR + String(key) + ".png")
			pm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			pm.roughness = 0.9
			if key == "mural" or key == "ramas":
				pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				pm.alpha_scissor_threshold = 0.5
			m = pm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	level = MapData.height(Vector2(-198.6, 92.0))
	transform = Transform3D(Basis.IDENTITY, Vector3(0, level, 0))
	W.add_child(self)
	var d := (CS - CN).normalized()
	door = CN + d * ((DOOR[0] + DOOR[1]) / 2.0) + Vector2(-d.y, d.x) * 1.9
	marciano_spot = GS.lerp(EW, 0.3) + Vector2(0.97, -0.26) * 0.9
	marciano_h = atan2(1.0, 0.25)                    # (looking across the alley at the café)
	_floor()
	_cafe()
	_end_wall()
	_garage()
	_grey_house()
	_terrace()
	_saffron(CN + d * 0.17 + Vector2(-d.y, d.x) * 0.18)
	home()
	_commit()
	_states()
	_tell_map()
	set_open(open_at(1, 12.0))

## whether the café is open then (day: 0 Monday ... 6 Sunday)
func open_at(day: int, hour: float) -> bool:
	var d := posmod(day, 7)
	if not HOURS.has(d):
		return false
	var h: Vector2 = HOURS[d]
	return hour >= h.x and hour < h.y

# ---------------- helpers ----------------
func gr(p: Vector2) -> float:
	return MapData.height(p) - level

## the ground before a wall (face(a, b)), x metres along it, `out` metres out of it
func _g(a: Vector2, b: Vector2, x: float, out := 0.5) -> float:
	var d := (b - a).normalized()
	return gr(a + d * x + Vector2(-d.y, d.x) * out)

## a flat picture (x0..x1, y0..y1) on the plane z of the frame being built, facing +z
func _picture(x0: float, x1: float, y0: float, y1: float, z: float, key) -> void:
	pieces += 1
	quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

## a foot along the wall being built (face(a, b)) that follows the ground: from x0 to x1, h over the ground
func _foot(a: Vector2, b: Vector2, x0: float, x1: float, h: float, key, proud := 0.03, step := 1.5) -> void:
	var n := maxi(1, int(ceil((x1 - x0) / step)))
	for i in range(n):
		var xa := lerpf(x0, x1, float(i) / n)
		var xb := lerpf(x0, x1, float(i + 1) / n)
		plinth(xa, xb, _g(a, b, xa) + h, _g(a, b, xb) + h, key, proud, DOWN)

## what has been built since the last commit becomes meshes under `node`: a part that can be shown and hidden
func _commit_to(node: Node3D) -> void:
	for key in _tools:
		var mi := MeshInstance3D.new()
		mi.mesh = (_tools[key] as SurfaceTool).commit()
		mi.material_override = _material(key)
		node.add_child(mi)
	_tools.clear()

func _ccw(p: PackedVector2Array) -> PackedVector2Array:
	if Geometry2D.is_polygon_clockwise(p):
		p.reverse()
	return p

func _facets(box_: Rect2) -> Array:
	var out: Array = []
	var g: float = MapData.rg
	for i in range(int(floor((box_.position.x - MapData.rx0) / g)), int(floor((box_.end.x - MapData.rx0) / g)) + 1):
		for j in range(int(floor((box_.position.y - MapData.rz0) / g)), int(floor((box_.end.y - MapData.rz0) / g)) + 1):
			var a := Vector2(MapData.rx0 + i * g, MapData.rz0 + j * g)
			out.append(_ccw(PackedVector2Array([a, a + Vector2(g, 0), a + Vector2(g, g)])))
			out.append(_ccw(PackedVector2Array([a, a + Vector2(g, g), a + Vector2(0, g)])))
	return out

## a flat piece of this outline (on the map) laid on the ground `lift` over it, cut along the relief's facets
func _lay(pts: Array, lift: float, key) -> void:
	pieces += 1
	var keep := _xf
	home()
	var mp := _ccw(PackedVector2Array(pts))
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

## an outline as solids (it need not be convex) and as one of the map's
func _mass(pts: Array, top: float) -> void:
	for part in Geometry2D.decompose_polygon_in_convex(PackedVector2Array(pts)):
		var conv: Array = []
		for q: Vector2 in part:
			conv.append(q)
		_prism(conv, DOWN, top)
	outlines.append(PackedVector2Array(pts))

# ---------------- the floor ----------------
## The setts of the alley's end: the bake's paving follows the road to its last point, two metres short of the end
## wall and narrower than the alley is there.
func _floor() -> void:
	_lay([EW + Vector2(0.0, -0.1), CN + Vector2(0.0, -0.1), CN.lerp(CS, 0.5), GS.lerp(HS, 0.6), GS], 0.012, "adoquin")

# ---------------- the café ----------------
func _cafe() -> void:
	var ln := face(CN, CS)
	var g0 := _g(CN, CS, 0.0)
	var eave := g0 + EAVE
	# the wall, cut at the diamonds and the door
	var d0: float = DOOR[0]
	var d1: float = DOOR[1]
	var gd := _g(CN, CS, (d0 + d1) / 2.0)
	var floor_in := gd + 0.51                       # (three steps up)
	var door_top := floor_in + 2.35
	var half := 1.05
	var cy := 2.35
	var x := 0.0
	for i in range(DIAMONDS.size() + 1):            # plain wall between the squares the diamonds stand in
		var to: float = (float(DIAMONDS[i]) - half) if i < DIAMONDS.size() else d0
		if to > x:
			quad(Vector3(x, DOWN, 0), Vector3(to, DOWN, 0), Vector3(to, eave, 0), Vector3(x, eave, 0), "white", Vector3(0, 0, 1))
		if i < DIAMONDS.size():
			_diamond(float(DIAMONDS[i]), _g(CN, CS, float(DIAMONDS[i])) + cy, half, eave)
			x = float(DIAMONDS[i]) + half
	quad(Vector3(d0, door_top, 0), Vector3(d1, door_top, 0), Vector3(d1, eave, 0), Vector3(d0, eave, 0), "white", Vector3(0, 0, 1))
	quad(Vector3(d1, DOWN, 0), Vector3(ln, DOWN, 0), Vector3(ln, eave, 0), Vector3(d1, eave, 0), "white", Vector3(0, 0, 1))
	_foot(CN, CS, 0.0, d0 - 0.45, 1.0, "granito")
	_foot(CN, CS, d1 + 0.45, ln, 1.0, "granito")
	for xj in range(1, int(d0 / 0.6)):                 # the joints of its tiles
		box(xj * 0.6 - 0.005, _g(CN, CS, xj * 0.6) - 0.1, 0.0, 0.01, 1.1, 0.033, 0x55585c)
	for k in range(2):
		box(0.0, g0 - 0.5 + 0.34 * (k + 1), 0.0, d0 - 0.45, 0.01, 0.033, 0x55585c)
	box(d1 + 0.45, gd + 1.0, 0.0, ln - d1 - 0.45, 0.75, 0.012, 0x9a9c9e)                    # (the grey painted over the foot, south of the door)
	# the eave: a dark board and gutter along the wall, the tiles over it
	box(-0.2, eave, 0.0, ln + 0.4, 0.22, 0.32, 0x2a221e)
	box(-0.2, eave - 0.06, 0.26, ln + 0.4, 0.1, 0.1, 0x1c1c1e)
	# the door: its recess, the steps of pale stone, the frame, the glass leaves (shut ones in _states)
	for sx in [d0, d1]:
		quad(Vector3(sx, gd, 0), Vector3(sx, gd, -0.7), Vector3(sx, door_top, -0.7), Vector3(sx, door_top, 0), "white", Vector3(1 if sx == d0 else -1, 0, 0))
	quad(Vector3(d0, door_top, 0), Vector3(d1, door_top, 0), Vector3(d1, door_top, -0.7), Vector3(d0, door_top, -0.7), "white", Vector3.DOWN)
	quad(Vector3(d0, floor_in, 0), Vector3(d1, floor_in, 0), Vector3(d1, floor_in, -0.7), Vector3(d0, floor_in, -0.7), 0xd8ccb4, Vector3.UP)
	quad(Vector3(d0, floor_in, -0.7), Vector3(d1, floor_in, -0.7), Vector3(d1, door_top, -0.7), Vector3(d0, door_top, -0.7), 0x2a2420, Vector3(0, 0, 1))
	for k in range(3):
		box(d0 - 0.35, gd - 0.3, 0.0, d1 - d0 + 0.7, 0.3 + 0.17 * (3 - k), 0.3 * (k + 1), 0xd8ccb4)
	for sx in [d0, d1 - 0.08]:
		box(sx, floor_in, -0.12, 0.08, 2.35, 0.1, 0x3a322c)
	box(d0, door_top - 0.08, -0.12, d1 - d0, 0.08, 0.1, 0x3a322c)
	# the awning's box over the door, a lamp by it, the spotlights along the wall, a cable
	box(d0 - 0.5, door_top + 0.25, 0.0, d1 - d0 + 1.0, 0.18, 0.2, 0x2a2c30)
	for sx in [1.2, 4.6, 6.9, 9.3]:
		box(sx - 0.05, eave - 0.55, 0.0, 0.1, 0.06, 0.2, IRON_HEX)
		box(sx - 0.1, eave - 0.66, 0.16, 0.2, 0.12, 0.1, IRON_HEX)
		box(sx - 0.08, eave - 0.67, 0.18, 0.16, 0.012, 0.07, "luz")
	for sx in [4.6, 9.3]:
		var lamp: Vector3 = transform * (_xf * Vector3(sx, eave - 0.9, 1.2))
		W.lamp_spots.append(lamp)
		lamps.append(lamp)
	bar(Vector3(0.0, eave - 0.35, 0.03), Vector3(ln, eave - 0.35, 0.03), 0.025, 0.025, IRON_HEX)
	box(ln - 1.2, gd + 1.5, 0.0, 0.3, 0.42, 0.1, 0xe6e6e0)
	home()
	# its other walls, plain; its roof of tiles, a ridge along its middle
	for i in range(1, CAFE.size() - 1):
		var a: Vector2 = CAFE[i]
		var b: Vector2 = CAFE[i + 1]
		_plain(a, b, DOWN, eave, "white")
		_plain(b, a, DOWN, eave, "white")
	_plain(CAFE[0], CAFE[1], DOWN, eave, "white")
	_plain(CAFE[1], CAFE[0], DOWN, eave, "white")
	var w0 := Vector2(-0.992, 0.123) * 0.32
	var ridge_n: Vector2 = (CAFE[0] + CAFE[2]) / 2.0
	var ridge_s: Vector2 = (CAFE[5] + CAFE[3]) / 2.0
	roof([Vector3(CN.x + w0.x, eave + 0.2, CN.y + w0.y), Vector3(CS.x + w0.x, eave + 0.2, CS.y + w0.y), Vector3(ridge_s.x, eave + 2.0, ridge_s.y), Vector3(ridge_n.x, eave + 2.0, ridge_n.y)])
	roof([Vector3(ridge_n.x, eave + 2.0, ridge_n.y), Vector3(ridge_s.x, eave + 2.0, ridge_s.y), Vector3(CAFE[3].x, eave, CAFE[3].y), Vector3(CAFE[2].x, eave, CAFE[2].y)])
	ridge(Vector3(ridge_n.x, eave + 2.0, ridge_n.y), Vector3(ridge_s.x, eave + 2.0, ridge_s.y))
	tri(Vector3(CAFE[0].x, eave, CAFE[0].y), Vector3(CAFE[2].x, eave, CAFE[2].y), Vector3(ridge_n.x, eave + 2.0, ridge_n.y), "white", Vector3(0, 0, -1))
	tri(Vector3(CAFE[5].x, eave, CAFE[5].y), Vector3(CAFE[3].x, eave, CAFE[3].y), Vector3(ridge_s.x, eave + 2.0, ridge_s.y), "white", Vector3(0, 0, 1))
	_mass(CAFE, eave)

## One of the café's windows: a square set on its corner, `half` from its middle (cx, cy) to each corner, in the wall
## being built; the wall round it within its bounding square, its glass set back, its frame and its black bars.
func _diamond(cx: float, cy: float, half: float, eave: float) -> void:
	pieces += 1
	var top := Vector3(cx, cy + half, 0)
	var bot := Vector3(cx, cy - half, 0)
	var lft := Vector3(cx - half, cy, 0)
	var rgt := Vector3(cx + half, cy, 0)
	var n := Vector3(0, 0, 1)
	# the wall round it: the four corners of its square, and above and below
	tri(Vector3(cx - half, cy + half, 0), lft, top, "white", n)
	tri(Vector3(cx + half, cy + half, 0), top, rgt, "white", n)
	tri(Vector3(cx - half, cy - half, 0), bot, lft, "white", n)
	tri(Vector3(cx + half, cy - half, 0), rgt, bot, "white", n)
	quad(Vector3(cx - half, cy + half, 0), Vector3(cx + half, cy + half, 0), Vector3(cx + half, eave, 0), Vector3(cx - half, eave, 0), "white", n)
	quad(Vector3(cx - half, DOWN, 0), Vector3(cx + half, DOWN, 0), Vector3(cx + half, cy - half, 0), Vector3(cx - half, cy - half, 0), "white", n)
	# its reveals and its glass
	var back := Vector3(0, 0, -0.3)
	for e in [[lft, top], [top, rgt], [rgt, bot], [bot, lft]]:
		var a: Vector3 = e[0]
		var b: Vector3 = e[1]
		var mid := (a + b) / 2.0
		quad(a, b, b + back, a + back, "white", (Vector3(cx, cy, 0) - mid).normalized())
		bar(a + Vector3(0, 0, 0.02), b + Vector3(0, 0, 0.02), 0.06, 0.06, IRON_HEX)
	quad(lft + back, bot + back, rgt + back, top + back, "cristal", n)
	# its bars: upright, from edge to edge of the diamond
	for k in range(-3, 4):
		var bx := cx + k * half / 3.6
		var reach := half - absf(bx - cx)
		box(bx - 0.012, cy - reach, 0.02, 0.024, 2.0 * reach, 0.024, IRON_HEX)

# ---------------- the end wall ----------------
func _end_wall() -> void:
	var ln := face(EW, CN)
	var g := _g(EW, CN, ln / 2.0)
	var top := g + 6.0
	var d0 := 0.75
	var d1 := 4.15
	var dh := g + 3.35
	masonry(0.0, ln, DOWN, top, [Rect2(d0, DOWN, d1 - d0, dh - DOWN)], [], "tapia", "tapia")
	quad(Vector3(d1, g, 0.012), Vector3(ln, g, 0.012), Vector3(ln, g + 3.6, 0.012), Vector3(d1, g + 3.6, 0.012), "cal_vieja", Vector3(0, 0, 1))
	quad(Vector3(0.0, g, 0.012), Vector3(d0, g, 0.012), Vector3(d0, g + 3.6, 0.012), Vector3(0.0, g + 3.6, 0.012), "cal_vieja", Vector3(0, 0, 1))
	for q in [[4.5, 0.4, 0.5, 0.35], [5.1, 1.2, 0.3, 0.5], [4.4, 2.1, 0.4, 0.3], [5.5, 0.2, 0.4, 0.3]]:        # where the whitewash has come away
		box(q[0], g + q[1], 0.0, q[2], q[3], 0.016, 0xc8b08a)
	box(d0 - 0.15, dh, 0.0, d1 - d0 + 0.3, 0.2, 0.06, 0x9a8a70)                    # the lintel
	bar(Vector3(d1 + 0.1, g + 3.62, 0.06), Vector3(ln, g + 3.62, 0.06), 0.07, 0.07, IRON_HEX)      # a black pipe along it
	# the door: two leaves of old green planks, a wicket in the right one, studs, the sign that says to keep it clear
	box(d0, g, -DEEP + 0.06, d1 - d0, dh - g, 0.08, "verde")
	box((d0 + d1) / 2.0 - 0.015, g, -DEEP + 0.14, 0.03, dh - g, 0.012, 0x1f4a1f)
	for k in range(1, 8):
		box(d0 + (d1 - d0) * k / 8.0 - 0.006, g + 0.05, -DEEP + 0.14, 0.012, dh - g - 0.1, 0.006, 0x235a23)
	for q in [[0.55, 0.0, 0.012, 1.75], [0.55, 1.75, 1.0, 0.012], [1.55, 0.0, 0.012, 1.75]]:               # the wicket
		box((d0 + d1) / 2.0 + q[0], g + q[1] + 0.05, -DEEP + 0.145, q[2], q[3], 0.008, 0x1a3a1a)
	for row in range(4):
		for col in range(9):
			cbox(Vector3(d0 + 0.2 + col * (d1 - d0 - 0.4) / 8.0, g + 0.5 + row * 0.8, -DEEP + 0.15), Vector3(0.035, 0.035, 0.02), 0x2a2a2c)
	box((d0 + d1) / 2.0 - 0.75, g + 2.0, -DEEP + 0.145, 0.32, 0.42, 0.01, 0xf0e8c0)
	_disc(Vector3((d0 + d1) / 2.0 - 0.59, g + 2.28, -DEEP + 0.156), 0.1, 0x2a4aa8)
	_disc(Vector3((d0 + d1) / 2.0 - 0.59, g + 2.28, -DEEP + 0.158), 0.085, 0xc8281e, 0.004)
	# the jar of sand by the door, the closed parasols leaning against the wall
	drum(Vector3(d0 + 0.5, g, 0.45), 0.2, 0.26, 0.55, 0xf0f0ec, 12)
	drum(Vector3(d0 + 0.5, g + 0.18, 0.45), 0.262, 0.262, 0.1, 0x2a4aa8, 12)
	drum(Vector3(d0 + 0.5, g + 0.55, 0.45), 0.26, 0.18, 0.1, 0xf0f0ec, 12)
	drum(Vector3(d0 + 0.5, g + 0.63, 0.45), 0.17, 0.17, 0.02, 0xc8b890, 12)
	for sx in [d1 - 0.9, d1 - 0.35]:
		bar(Vector3(sx, g, 0.5), Vector3(sx + 0.05, g + 2.5, 0.12), 0.05, 0.05, 0xd8d8d4)
		bar(Vector3(sx + 0.01, g + 0.95, 0.44), Vector3(sx + 0.05, g + 2.4, 0.15), 0.14, 0.14, 0xf2f2ee)
		bar(Vector3(sx + 0.05, g + 2.4, 0.15), Vector3(sx + 0.05, g + 2.55, 0.11), 0.07, 0.07, 0xd8d8d4)
	home()
	var o := Vector2(0.045, 0.999)
	_plain(CN, EW, DOWN, top, "tapia")                                              # (its back, towards the fields)
	var m := (EW + CN) / 2.0 - o * 0.2
	var d := (CN - EW).normalized()
	solid(Vector3(m.x, top / 2.0, m.y), Vector3(EW.distance_to(CN), top + 4.0, 0.4), atan2(-d.y, d.x))
	outlines.append(PackedVector2Array([EW, CN, CN - o * 0.4, EW - o * 0.4]))

## a round thing lying on the wall being built
func _disc(at: Vector3, r: float, key, deep := 0.006) -> void:
	var keep := _xf
	_xf = keep * Transform3D(Basis(Vector3.RIGHT, PI / 2.0), at)
	drum(Vector3.ZERO, r, r, deep, key, 14)
	_xf = keep

# ---------------- the garage with the emblem ----------------
func _garage() -> void:
	var ln := face(GS, EW)
	var g := _g(GS, EW, ln / 2.0)
	var top := g + 2.9
	var d0 := 2.3
	var d1 := 5.3
	var dh := g + 2.6
	masonry(0.0, ln, DOWN, top, [Rect2(d0, DOWN, d1 - d0, dh - DOWN)], [], "white", "white")
	_picture(0.3, 2.0, g + 0.25, g + 2.35, 0.015, "mural")
	box(d0, g, -0.12, d1 - d0, dh - g, 0.05, 0xf2f2ee)                             # the white door of sheet, in two leaves
	for k in range(1, 12):
		box(d0 + (d1 - d0) * k / 12.0 - 0.004, g + 0.04, -0.07, 0.008, dh - g - 0.08, 0.004, 0xd8d8d2)
	box((d0 + d1) / 2.0 - 0.012, g, -0.07, 0.024, dh - g, 0.008, 0xb8b8b2)
	_picture(d0, d1, g, dh, -0.06, "ramas")
	box(0.5, g, 0.05, 1.3, 0.22, 0.28, 0xd8b020)                                   # the yellow planter at its foot
	for k in range(5):
		ball(Vector3(0.65 + k * 0.25, g + 0.3, 0.19), 0.13, 0x3f6a32 if k % 2 == 0 else 0x4a7a3a, 0.8, 6, 4)
	var keep := _xf                                                                 # ...and another across the corner by the end wall
	_xf = keep * Transform3D(Basis(Vector3.UP, -0.5), Vector3(5.15, _g(GS, EW, 5.15), 0.36))
	box(-0.4, 0.0, -0.12, 0.8, 0.2, 0.24, 0xd8b020)
	for k in range(3):
		ball(Vector3(-0.25 + k * 0.25, 0.27, 0.0), 0.12, 0x3f6a32 if k % 2 == 0 else 0x4a7a3a, 0.8, 6, 4)
	bar(Vector3(0.1, 0.2, 0.0), Vector3(0.16, 0.75, -0.04), 0.03, 0.03, 0x4a7a3a)
	_xf = keep
	# its corrugated roof: one slope down towards the alley, its edge out over the wall
	home()
	var ridge_h := top + 0.7
	pieces += 1
	var o := Vector2(0.966, -0.256) * 0.3
	quad(Vector3(GS.x + o.x, top + 0.02, GS.y + o.y), Vector3(EW.x + o.x, top + 0.02, EW.y + o.y), Vector3(GARAGE[3].x, ridge_h, GARAGE[3].y), Vector3(GARAGE[2].x, ridge_h, GARAGE[2].y), "uralita", Vector3(0.2, 1, 0))
	for i in range(1, GARAGE.size()):
		var a: Vector2 = GARAGE[i]
		var b: Vector2 = GARAGE[(i + 1) % GARAGE.size()]
		_plain(a, b, DOWN, ridge_h, "white")
		_plain(b, a, DOWN, ridge_h, "white")
	_mass(GARAGE, top)

# ---------------- the grey house: a skin over the side of Texturas's brick house ----------------
const JOINT := 0xb09c7c

## the joints of a stone frame's blocks, across its lintel and its jambs
func _joints(r: Rect2, w: float, proud: float) -> void:
	var across := r.size.x + 2.0 * w
	var n := maxi(1, int(round(across / 0.6)))
	for k in range(1, n):
		box(r.position.x - w + across * k / n - 0.003, r.end.y, proud - 0.002, 0.006, w, 0.004, JOINT)
	var rows := maxi(1, int(round(r.size.y / 0.5)))
	for k in range(1, rows + 1):
		var y: float = r.position.y + r.size.y * k / rows
		for x: float in [r.position.x - w, r.end.x]:
			box(x, y - 0.003, proud - 0.002, w, 0.006, 0.004, JOINT)

func _grey_house() -> void:
	var ln := face(HS, GS)
	var top := _g(HS, GS, ln / 2.0) + 5.6
	for hd in MapData.houses:                       # (as high as the brick house it covers: its own wall, from its own floor at the avenue)
		if String(hd["id"]) == "juancarlos_10":
			top = float(hd.get("base", 0.0)) + float(hd.get("h", 6.4)) - level - 0.02
	var z := 0.22                                   # (proud of the brick wall and of the grilles of its windows)
	var keep := _xf
	_xf = keep * Transform3D(Basis.IDENTITY, Vector3(0, 0, z))
	var holes: Array = []
	var gdoor := _g(HS, GS, 1.25)
	var gwin := _g(HS, GS, 3.2)
	var ggar := _g(HS, GS, 6.9)
	var door_r := Rect2(0.8, DOWN, 0.9, gdoor + 2.2 - DOWN)
	var win_r := Rect2(2.55, gwin + 1.0, 1.3, 1.3)
	var gar_r := Rect2(5.2, DOWN, 3.4, ggar + 2.6 - DOWN)
	var up: Array = [Rect2(0.95, top - 1.8, 0.6, 0.7), Rect2(2.8, top - 2.4, 0.85, 1.45), Rect2(6.05, top - 2.35, 1.7, 1.25)]
	holes.append(door_r)
	holes.append(win_r)
	holes.append(gar_r)
	holes.append_array(up)
	masonry(0.0, ln, DOWN, top, holes, [], "gris", "gris")
	_foot(HS, GS, 0.0, door_r.position.x - 0.2, 0.9, "travertino")
	_foot(HS, GS, door_r.end.x + 0.2, gar_r.position.x - 0.3, 0.9, "travertino")
	_foot(HS, GS, gar_r.end.x + 0.3, ln, 0.9, "travertino")
	for span in [[0.0, door_r.position.x - 0.2], [door_r.end.x + 0.2, gar_r.position.x - 0.3], [gar_r.end.x + 0.3, ln]]:      # (the joints of its blocks)
		var xs: float = float(span[0]) + 0.6
		while xs < float(span[1]) - 0.1:
			box(xs - 0.003, _g(HS, GS, xs) - 0.1, 0.0, 0.006, 1.0, 0.033, JOINT)
			xs += 0.6
	# the frames of pale stone, and what is in them (12 cm back: the skin is 22 cm thick, and the brick wall is behind)
	var back := -0.16
	stone_frame(Rect2(door_r.position.x, gdoor, door_r.size.x, 2.2), 0.2, 0.04, "travertino")
	_joints(Rect2(door_r.position.x, gdoor, door_r.size.x, 2.2), 0.2, 0.04)
	box(door_r.position.x, gdoor, back, door_r.size.x, 2.2, 0.04, 0xf2f2ee)
	for k in range(1, 14):
		box(door_r.position.x, gdoor + k * 0.155, back + 0.04, door_r.size.x, 0.008, 0.004, 0xd4d4ce)
	stone_frame(win_r, 0.2, 0.04, "travertino")
	_joints(win_r, 0.2, 0.04)
	box(win_r.position.x, win_r.position.y, back, win_r.size.x, win_r.size.y, 0.04, 0xe8e6de)
	grille(win_r, 0.1, 0xf2f2ee)
	stone_frame(Rect2(gar_r.position.x, ggar, gar_r.size.x, 2.6), 0.3, 0.05, "travertino")
	_joints(Rect2(gar_r.position.x, ggar, gar_r.size.x, 2.6), 0.3, 0.05)
	box(gar_r.position.x, ggar, back, gar_r.size.x, 2.6, 0.04, 0xf4f4f0)
	for k in range(1, 7):
		box(gar_r.position.x, ggar + k * 0.37, back + 0.04, gar_r.size.x, 0.012, 0.004, 0xd4d4ce)
	for r: Rect2 in up:
		stone_frame(r, 0.18, 0.04, "travertino")
		_joints(r, 0.18, 0.04)
		box(r.position.x, r.position.y, back, r.size.x, r.size.y, 0.04, 0xe8e6de)
		for k in range(1, 8):
			box(r.position.x, r.position.y + k * r.size.y / 8.0, back + 0.04, r.size.x, 0.008, 0.004, 0xcfccc2)
	# its ends and its top: the thickness of it
	for x in [0.0, ln]:
		quad(Vector3(x, DOWN, -z), Vector3(x, DOWN, 0), Vector3(x, top, 0), Vector3(x, top, -z), "gris", Vector3(-1 if x == 0.0 else 1, 0, 0))
	quad(Vector3(0, top, -z), Vector3(ln, top, -z), Vector3(ln, top, 0), Vector3(0, top, 0), "gris", Vector3.UP)
	_xf = keep
	home()

# ---------------- what stands about the alley ----------------
func _terrace() -> void:
	var d := (CS - CN).normalized()
	var o := Vector2(-d.y, d.x)                     # out of the café's wall
	# its tables and chairs along the wall, north of the door
	for x in [1.9, 4.3, 6.7, 8.9]:
		var at: Vector2 = CN + d * x + o * 1.05
		var g := gr(at)
		_table(at, g)
		for s in [-1.0, 1.0]:
			_chair(at + d * (s * 0.62), g, atan2(d.x * s, d.y * s))
		solid(Vector3(at.x, g + 0.4, at.y), Vector3(0.75, 0.8, 1.9), atan2(-d.y, d.x) + PI / 2.0)
	# the corner by the end wall: crates of empties, stacked chairs, the keg by the steps
	var c0: Vector2 = CN + d * 0.45 + o * 0.5
	var gc := gr(c0)
	for q in [[0.0, 0.0, 4, 0x2a5ab0], [0.0, 0.45, 3, 0xe8b820], [0.55, 0.0, 3, 0xe8b820], [0.55, 0.45, 4, 0x2a5ab0]]:
		var p: Vector2 = c0 + d * float(q[0]) + o * float(q[1])
		for k in range(int(q[2])):
			cbox(Vector3(p.x, gc + 0.14 + k * 0.28, p.y), Vector3(0.4, 0.26, 0.3), int(q[3]))
			cbox(Vector3(p.x, gc + 0.27 + k * 0.28, p.y), Vector3(0.34, 0.02, 0.24), 0x4a3a20)
	var cs: Vector2 = c0 + d * 1.25 + o * 0.15
	for k in range(6):
		cbox(Vector3(cs.x, gc + 0.42 + k * 0.09, cs.y), Vector3(0.5, 0.05, 0.5), 0x3a3c40)
		cbox(Vector3(cs.x - o.x * 0.22, gc + 0.7 + k * 0.09, cs.y - o.y * 0.22), Vector3(0.5, 0.5, 0.05), 0x3a3c40)
	var cm: Vector2 = c0 + d * 0.6 - o * 0.05
	solid(Vector3(cm.x, gc + 0.5, cm.y), Vector3(0.9, 1.0, 1.9), atan2(-d.y, d.x) + PI / 2.0)
	var keg: Vector2 = CN + d * (float(DOOR[0]) - 0.75) + o * 0.5
	drum(Vector3(keg.x, gr(keg), keg.y), 0.2, 0.2, 0.52, 0xb8bcc0, 12)
	drum(Vector3(keg.x, gr(keg) + 0.52, keg.y), 0.21, 0.21, 0.05, 0x8a8e92, 12)
	solid(Vector3(keg.x, gr(keg) + 0.3, keg.y), Vector3(0.42, 0.6, 0.42))
	# the steps of the door, for whoever walks into them
	var st: Vector2 = CN + d * ((float(DOOR[0]) + float(DOOR[1])) / 2.0) + o * 0.45
	solid(Vector3(st.x, gr(st) + 0.2, st.y), Vector3(0.9, 0.5, 2.5), atan2(-d.y, d.x) + PI / 2.0)

## a small square table of the terrace: a dark top on one leg
func _table(at: Vector2, g: float) -> void:
	drum(Vector3(at.x, g, at.y), 0.22, 0.22, 0.03, 0x2a2c30, 8)
	drum(Vector3(at.x, g, at.y), 0.035, 0.035, 0.72, 0x2a2c30, 6)
	cbox(Vector3(at.x, g + 0.74, at.y), Vector3(0.68, 0.04, 0.68), 0xd6b98a)

## one of its chairs: dark plastic, its back away from the table
func _chair(at: Vector2, g: float, yaw: float) -> void:
	var keep := _xf
	_xf = Transform3D(Basis(Vector3.UP, yaw), Vector3(at.x, g, at.y))
	for sx in [-0.19, 0.19]:
		for sz in [-0.19, 0.19]:
			box(sx - 0.015, 0.0, sz - 0.015, 0.03, 0.44, 0.03, 0x2e3034)
	box(-0.22, 0.44, -0.22, 0.44, 0.035, 0.44, 0x3a3c40)
	box(-0.22, 0.475, 0.19, 0.44, 0.42, 0.03, 0x3a3c40)
	_xf = keep

# ---------------- shut and open ----------------
## Shut: the awning rolled in its box, the door's two dark leaves closed. Open: the awning out over the steps with the
## café's name on its fall, the leaves swung in, a light in the doorway, the blackboard out at the alley's mouth.
func _states() -> void:
	face(CN, CS)
	var d0: float = DOOR[0]
	var d1: float = DOOR[1]
	var gd := _g(CN, CS, (d0 + d1) / 2.0)
	var floor_in := gd + 0.51
	var door_top := floor_in + 2.35
	_shut = Node3D.new()
	add_child(_shut)
	for k in range(2):
		var x0 := d0 + 0.08 + k * (d1 - d0 - 0.16) / 2.0
		box(x0, floor_in, -0.1, (d1 - d0 - 0.16) / 2.0 - 0.01, 2.27, 0.05, 0x2e2a28)
		box(x0 + 0.08, floor_in + 0.9, -0.05, (d1 - d0 - 0.16) / 2.0 - 0.17, 1.2, 0.006, "cristal")
	home()
	_commit_to(_shut)
	_open = Node3D.new()
	add_child(_open)
	face(CN, CS)
	for sx in [d0 + 0.08, d1 - 0.13]:                                             # the leaves, swung in
		box(sx, floor_in, -0.68, 0.05, 2.27, 0.6, 0x2e2a28)
	cbox(Vector3((d0 + d1) / 2.0, door_top - 0.12, -0.3), Vector3(0.9, 0.05, 0.2), "luz")
	# the awning: its cloth out and down, its two arms, its fall with the name
	var a0 := d0 - 0.45
	var a1 := d1 + 0.45
	var ay := door_top + 0.3
	quad(Vector3(a0, ay, 0.15), Vector3(a1, ay, 0.15), Vector3(a1, ay - 0.5, 1.75), Vector3(a0, ay - 0.5, 1.75), "toldo", Vector3(0, 1, 0.3))
	_picture(a0, a1, ay - 0.5 - (a1 - a0) * 0.14, ay - 0.5, 1.75, "rotulo")
	for sx in [a0 + 0.05, a1 - 0.05]:
		bar(Vector3(sx, ay - 0.1, 0.15), Vector3(sx, ay - 0.5, 1.72), 0.03, 0.03, 0xd8dade)
	home()
	# the blackboard at the alley's mouth: two boards leaning on one another
	var g := gr(MOUTH)
	var keep := _xf
	_xf = Transform3D(Basis(Vector3.UP, 0.25), Vector3(MOUTH.x, g, MOUTH.y))
	for s in [-1.0, 1.0]:
		var lean := Transform3D(Basis(Vector3.RIGHT, s * 0.2), Vector3(0, 0, s * 0.22))
		var k2 := _xf
		_xf = _xf * lean
		box(-0.32, 0.0, -0.015, 0.64, 0.98, 0.03, 0x6a4a30)
		if s > 0.0:
			_picture(-0.28, 0.28, 0.08, 0.93, 0.02, "pizarra")
		else:
			quad(Vector3(0.28, 0.08, -0.02), Vector3(-0.28, 0.08, -0.02), Vector3(-0.28, 0.93, -0.02), Vector3(0.28, 0.93, -0.02), "pizarra", Vector3(0, 0, -1),
				[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
		_xf = k2
	_xf = keep
	_commit_to(_open)

func set_open(on: bool) -> void:
	is_open = on
	if _shut != null:
		_shut.visible = not on
		_open.visible = on

func _process(_delta: float) -> void:
	var game = W.get_parent() if W != null else null
	if game != null and "clock" in game and "weekday" in game:
		var want: bool = open_at(int(game.weekday), float(game.clock))
		if want != is_open:
			set_open(want)

# ---------------- the saffron, and what the map is told ----------------
## A saffron flower in a little pot of clay, behind the crates of empties in the corner of the café and the end wall
## (the user: hide saffron in special places). The flower is the game's to take away; the pot stays.
func _saffron(at: Vector2) -> void:
	var g := gr(at) + 0.02
	drum(Vector3(at.x, g, at.y), 0.1, 0.14, 0.16, 0xb0623a, 10)
	drum(Vector3(at.x, g + 0.15, at.y), 0.12, 0.12, 0.012, 0x5a3a26, 10)
	var flower := Node3D.new()
	flower.add_child(Parts.part("cyl", 0x5f9c4a, Vector3(0, 0.3, 0), Vector3(0.03, 0.6, 0.03)))
	for k in range(5):
		flower.add_child(Parts.part("ball", 0x9b5de5, Vector3(cos(k * 1.257) * 0.12, 0.66, sin(k * 1.257) * 0.12), Vector3(0.11, 0.2, 0.11)))
	flower.add_child(Parts.part("ball", 0xe63946, Vector3(0, 0.74, 0), Vector3(0.05, 0.13, 0.05)))
	flower.position = Vector3(at.x, g + 0.12, at.y)
	add_child(flower)
	saffron_spot = at
	var game = W.get_parent()                           # (the game: the world is its child)
	if game != null and game.get("flowers") != null:
		(game.flowers as Array).append({"node": flower, "p": saffron_spot, "id": "rize", "hidden": true})      # (hidden: Sistemas keeps count of these)

func _tell_map() -> void:
	for outline: PackedVector2Array in outlines:
		MapData.outlines.append(outline)
		if not MapData._wall_grid.is_empty():
			for i in range(outline.size()):
				var a: Vector2 = outline[i]
				var c: Vector2 = outline[(i + 1) % outline.size()]
				MapData._grid_add(MapData._wall_grid, a.min(c), a.max(c), [a, c])
