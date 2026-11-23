extends "res://scripts/esquina.gd"
## The clothes and home-textile shop "MaxiPrecio" of the Calle de los Arcos, on its corners with the Calle del Molino
## (north) and the Calle de Granada (south): the real HiperTextil Miniprecio (the user, 23 November 2026: "Vamos con el
## HiperTextil Miniprecio (que llamaremos MaxiPrecio). Necesitará tener un interior (hay fotos en maps) y su horario
## comercial"). Built by hand on Texturas's house of the map (mol_b301, handed over as ["obra"] in casas_calles.gd), with
## no rebake; referencias/maxiprecio/. From Street View of November 2024.
##
## A block of flats of the nineties, a ground floor and two floors over it under a flat roof, of salmon brick:
##   - to the Arcos (west, 18.7 m), the shop: a window at each end behind a drop awning of blue and white stripes, the
##     brick piers between; in the middle the shop's front comes out in a V under two boards (the game's own: blue and
##     white stripes, "Hiper Textil", two peaches with "Maxi Precio" across them), two awnings in a V under them; at the
##     point of the V a round cream pillar (tagged: dirty stays dirty) and three granite steps up to the porch, whose
##     sides are of glass over blue tiles and whose glass door is at the back; a cream band over the ground floor;
##   - above, two wings with long balconies on both floors behind light grey rails, their slabs edged in cream, the roof's
##     deep eaves over them, turning the corners on to the Molino and the Granada; between the wings a bow of brick, two
##     windows on each floor behind little rails, cream bands at its floors, a rail round its top and an iron pergola
##     over it; a strip of white render at each side of the bow;
##   - to the Granada and the Molino the shop's walls are white, painted with blue stripes slanting up to the right and
##     the badge ("Hiper Textil" and the peaches); air conditioners over them, the cables; above, brick, windows in
##     cream frames behind little rails, blinds half down. At the east end of the Granada the flats' doorway, clad in
##     granite, its glass door behind grey gates. The east part of the Molino (Catastro's part 3) is another house: its
##     foot of rough brick never rendered (smears of mortar, holes along its top), a grey band, brick above, a white
##     balcony at its end.
## The real shop's badge is two cherries; ours is two peaches (the user, 23 Nov 2026: "Como el logo original son dos
## cerezas que el nuestro sean dos melocotones"). No number on it, no telephone, no social network (the game shows none). No saffron hidden here: one is proposed and
## the user says whether it goes in.
##
## Its hours are the real shop's (Google Maps, 23 November 2026): Monday to Friday from half past nine to two and from
## five to nine, Saturdays from half past nine to two, shut on Sundays. A card on the porch's glass says so. Open: the
## awnings down, the door in, light inside. Shut: the awnings rolled up, the door shut, the inside dark. Its inside is a
## set of its own (maxiprecio_dentro.gd), walked into by the green arrow before its steps (entradas.gd).
##
## Frame: the map's own (x east, z south), y = 0 the pavement before its steps. Each front is built in its own frame
## (obra.face: +x along it, its left end seen from the street first; +z out of it).

const READY := true
const HOUSE := "mol_b301"
const NAME := "MaxiPrecio"                       # what the shop is called in the game (the user, 23 Nov 2026)
const DIR := "res://assets/maxiprecio/"
const DentroS = preload("res://scripts/maxiprecio_dentro.gd")
const ManiquiS = preload("res://scripts/maniqui.gd")
## the mannequin at its door (the user, 23 Nov 2026: "Ponle un maniquí con ropa y sombrero en la puerta ..., que sea
## rompible y que cambie cada día aleatoriamente"; out "Solo mientras la tienda está abierta"): on the pavement at the right of the steps as you look at the shop,
## before the V's glass (along the Arcos from the Molino's corner, out); turned a little towards the Molino
const MANIQUI := Vector2(11.0, 0.95)

# its outline on the map (Catastro 3692101VJ5639S: the shop's building and, along the Molino, part 3), in the ring's order
const SW := Vector2(119.37, 247.09)              # the corner of the Arcos and the Granada
const NW := Vector2(121.25, 228.48)              # the corner of the Arcos and the Molino
const MS := Vector2(141.83, 233.12)              # where the shop's building ends on the Molino and part 3 begins
const NE := Vector2(154.98, 236.09)              # where part 3 ends on the Molino
const E1 := Vector2(153.39, 239.69)
const E2 := Vector2(141.04, 237.18)
const SE := Vector2(138.56, 250.95)              # where it ends on the Granada (the flats' doorway at that end)

const FLOOR := 0.45             # the shop's floor over the pavement before the steps (three steps)
const SILL := 0.62              # the ground floor's windows, from here...
const HEAD := 3.45              # ...to here
const BAND := 4.45              # the first floor's slab (the cream band over the ground floor ends here)
const F1 := 4.6                 # the first floor
const F2 := 7.7                 # the second
const TOP := 10.65              # the roof
const PARAPET := 11.4           # the top of its parapets
const OUT := 1.0                # how far the balconies of the Arcos come out...
const WRAP := 2.6               # ...and how far they turn round the corners
const WIN_N := Rect2(0.45, SILL, 3.3, HEAD - SILL)       # the Arcos's windows (x from its north end)
const WIN_S := Rect2(13.25, SILL, 4.7, HEAD - SILL)
const BAY := Vector2(4.4, 12.75)                         # the shop's front, between the piers
const V0 := 5.9                                          # the V of boards: from the wall here...
const APEX := Vector2(8.65, 0.9)                         # ...out to its point...
const V1 := 11.4                                         # ...and back
const PORCH := Vector2(7.75, 9.55)                       # where the V is cut for the porch
const DOOR_Z := -0.3                                     # the glass door at the porch's back...
const DOOR := Vector2(8.15, 9.15)                        # ...between these
const PILLAR := Vector2(8.65, 0.72)
const BOW := Vector2(8.65, -0.55)                        # the bow over it: its centre (behind the wall's line)...
const BOW_R := 1.55                                      # ...its radius...
const BOW_HALF := 1.45                                   # ...half its width on the wall
const WIN_G := Rect2(0.5, SILL, 2.8, HEAD - SILL)        # the Granada's window by the corner (x from the corner)
const PORTAL := Rect2(17.55, 0.0, 1.4, 2.45)             # the flats' door, at the Granada's east end
const WIN_M := Rect2(17.9, SILL, 2.7, HEAD - SILL)       # the Molino's window by the corner (x from part 3)
const HOURS := {0: [Vector2(9.5, 14.0), Vector2(17.0, 21.0)], 1: [Vector2(9.5, 14.0), Vector2(17.0, 21.0)],
	2: [Vector2(9.5, 14.0), Vector2(17.0, 21.0)], 3: [Vector2(9.5, 14.0), Vector2(17.0, 21.0)],
	4: [Vector2(9.5, 14.0), Vector2(17.0, 21.0)], 5: [Vector2(9.5, 14.0)]}      # the day (0 Monday ... 6 Sunday) and from when to when; Sundays shut
const ALU := 0xdcdcd8           # the shop's aluminium
const CASE := 0xe8e8e4          # the awnings' cases
const BLIND := 0xe6dfcf         # the blinds of the flats
const GLASS := 0x26313a         # the flats' windows (dark: nothing is built behind them)
const AC := 0xe9e9e5
const PILES := [0x2f4f8f, 0xb03a3a, 0xe8d8b0, 0x3f7f5f, 0xd88a3a, 0x8a5a9a, 0xe4e4df, 0x5a8ab8, 0xc85a7a, 0x3a3a40]   # the goods behind the glass
const RAIL := 0xc9cac6          # the flats' rails: light grey (Street View)
const BLUE := 0x2a5ab0

var door: Vector2                               # before the shop's steps, on the pavement
var maniqui                                     # the mannequin at the door (maniqui.gd): street furniture, dressed anew each day
var side_spot: Vector2                          # before the Granada's painted wall
var molino_spot: Vector2                        # before the Molino's
var dentro                                      # its inside (maxiprecio_dentro.gd)
var is_open := false
var openings := 0
var balconies := 0
var len_arcos := 0.0
var _shut: Node3D
var _open: Node3D
var _lights: Array = []
var _na: Vector2                                # the outward normals of the Arcos, the Molino and the Granada
var _nm: Vector2
var _ng: Vector2

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"ladrillo":         # the salmon brick of the whole block (Street View 2024: about 215, 150, 120 in the sun)
			m = _glow(Tex.mat("brick_wall_003@1.15", Color(1.12, 1.12, 1.42)), 0.1)    # (pale salmon, measured on Street View: pushing up the blue takes the orange out)
		"tosco":            # part 3's foot: rough red brick, never rendered
			m = Tex.mat("red_brick_03", Color(1.05, 0.86, 0.8))
		"crema":            # the cream of the slabs, the bands, the pillar
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.85, 0.68)), 0.22)
		"blanco":           # the white render beside the bow and of part 3's balcony
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.0, 0.99, 0.97)), 0.2)
		"medianera":        # what looks on to the plot east of it
			m = Tex.mat("painted_plaster_wall", Color(0.84, 0.78, 0.7))
		"granito":          # the foot under the windows, the steps, the flats' doorway
			m = Tex.mat("granite_tile_03", Color(0.95, 0.95, 0.95))
		"hormigon":         # part 3's grey band
			m = Tex.mat("granular_concrete", Color(0.66, 0.66, 0.65))
		"azotea":           # the flat roof
			m = Tex.mat("granular_concrete", Color(0.62, 0.6, 0.57))
		"rayas", "mural", "rotulo", "horario":
			var tm := StandardMaterial3D.new()
			tm.albedo_texture = load(DIR + String(key) + ".png")
			tm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			tm.roughness = 1.0
			tm.metallic_specular = 0.0          # (a shine picks up the sky and greys the blue)
			tm.emission_enabled = true          # (white walls read white in the shade of the narrow streets too)
			tm.emission_texture = tm.albedo_texture
			tm.emission = Color.WHITE
			tm.emission_energy_multiplier = 0.05            # (little: a white wall in the sun is over the glow's threshold already, and its glow greys the blue)
			if key == "mural":
				tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				tm.alpha_scissor_threshold = 0.5
			m = tm
		"toldo":            # the awnings' cloth: blue and white stripes, 12 cm each, running down the fall
			var img := Image.create(16, 4, false, Image.FORMAT_RGB8)
			for x in range(16):
				for y in range(4):
					img.set_pixel(x, y, Parts.col(0x1a3f9e) if x < 8 else Color(0.97, 0.97, 0.95))
			var am := StandardMaterial3D.new()
			am.albedo_texture = ImageTexture.create_from_image(img)
			am.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			am.roughness = 1.0
			am.metallic_specular = 0.0
			am.cull_mode = BaseMaterial3D.CULL_DISABLED
			am.emission_enabled = true          # (the sun comes through the cloth)
			am.emission_texture = am.albedo_texture
			am.emission = Color.WHITE
			am.emission_energy_multiplier = 0.06
			m = am
		"azulejo":          # the porch's tiles: white, with a blue one here and there
			var timg := Image.create(8, 8, false, Image.FORMAT_RGB8)
			for y in range(8):
				for x in range(8):
					var c := 0xf0f0ec
					if x % 4 == 0 or y % 4 == 0:
						c = 0xc8ccd0
					elif ((x / 4) + (y / 4)) % 2 == 1:
						c = 0x3a64b4
					timg.set_pixel(x, y, Parts.col(c))
			var zm := StandardMaterial3D.new()
			zm.albedo_texture = ImageTexture.create_from_image(timg)
			zm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			zm.uv1_triplanar = true
			zm.uv1_scale = Vector3.ONE / 0.3
			zm.roughness = 0.4
			m = zm
		"vidrio":
			var gm := StandardMaterial3D.new()
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.albedo_color = Color(0.55, 0.68, 0.72, 0.28)
			gm.roughness = 0.12
			gm.metallic_specular = 0.7
			gm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = gm
		"interior":         # what shows through the shop's glass: dark when shut, lit when open
			var im := StandardMaterial3D.new()
			im.albedo_color = Color(0.13, 0.135, 0.15)
			im.emission_enabled = true
			im.emission = Color(1.0, 0.97, 0.9)
			im.emission_energy_multiplier = 0.05
			m = im
		"luz":
			var lm := StandardMaterial3D.new()
			lm.albedo_color = Color(1.0, 0.99, 0.95)
			lm.emission_enabled = true
			lm.emission = Color(1.0, 0.98, 0.92)
			lm.emission_energy_multiplier = 1.6
			m = lm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world, _hd: Dictionary) -> void:
	W = world
	_na = _outward(NW, SW)
	_nm = _outward(MS, NW)
	_ng = _outward(SW, SE)
	var front := _along(NW, SW, APEX.x) + _na * 2.2
	level = MapData.height(front)
	transform = Transform3D(Basis.IDENTITY, Vector3(0.0, level, 0.0))
	W.add_child(self)
	_arcos()
	_shopfront()
	_bow()
	_molino()
	_part3()
	_granada()
	_corners()
	_back_and_roof()
	home()
	_commit()
	_states()
	_ring_solids([SW, NW, NE, E1, E2, SE], 14.0)
	face(NW, SW)
	for q in [[Vector2(V0, 0.0), Vector2(PORCH.x, _vz(PORCH.x))], [Vector2(PORCH.y, _vz(PORCH.y)), Vector2(V1, 0.0)]]:      # the V of glass stops you; the steps too
		_seg_solid(q[0], q[1], 3.6)
	_seg_solid(Vector2(7.0, 1.2), Vector2(10.3, 1.2), 1.0, 0.6)
	_seg_solid(Vector2(PILLAR.x - 0.2, PILLAR.y), Vector2(PILLAR.x + 0.2, PILLAR.y), 3.6, 0.4)
	home()
	door = _along(NW, SW, APEX.x) + _na * 2.2
	side_spot = _along(SW, SE, 10.1) + _ng * 1.6
	molino_spot = _along(MS, NW, 14.2) + _nm * 1.6
	dentro = DentroS.new()                          # (its door at the top of the steps: the arrow stands before them)
	dentro.build(world, _along(NW, SW, APEX.x) + _na * 1.25, _along(NW, SW, APEX.x) + _na * 3.2, atan2(_na.x, _na.y))
	var mp := _along(NW, SW, MANIQUI.x) + _na * MANIQUI.y
	maniqui = ManiquiS.new()
	maniqui.setup(world, mp, atan2(_na.x, _na.y) - 0.35, MapData.foot(mp) - level)
	add_child(maniqui)
	set_open(open_at(0, 12.0))

## whether it is open then (day: 0 Monday ... 6 Sunday)
func open_at(day: int, hour: float) -> bool:
	var d := posmod(day, 7)
	if not HOURS.has(d):
		return false
	for h: Vector2 in HOURS[d]:
		if hour >= h.x and hour < h.y:
			return true
	return false

# ---------------- pieces ----------------
func _v3(p: Vector2, y: float) -> Vector3:
	return Vector3(p.x, y, p.y)

## how far out the V of boards is at x (the Arcos front's frame)
func _vz(x: float) -> float:
	if x <= APEX.x:
		return APEX.y * (x - V0) / (APEX.x - V0)
	return APEX.y * (V1 - x) / (V1 - APEX.x)

## something that repeats every sx by sy metres (the painted stripes), facing +z on the plane z
func _tiled(x0: float, x1: float, y0: float, y1: float, z: float, key, sx := 0.9, sy := 1.8) -> void:
	pieces += 1
	quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1),
		[Vector2(x0 / sx, -y0 / sy), Vector2(x1 / sx, -y0 / sy), Vector2(x1 / sx, -y1 / sy), Vector2(x0 / sx, -y1 / sy)])

## a box along a line of the frame being built (a, b: on its floor plan; a is its left end seen from outside), from
## y0 to y1, `t` thick behind the line
func _seg(a: Vector2, b: Vector2, y0: float, y1: float, t: float, key) -> void:
	var ln := a.distance_to(b)
	if ln < 0.001 or y1 <= y0:
		return
	var d := (b - a) / ln
	var n := Vector2(-d.y, d.x)
	var mid := (a + b) / 2.0 - n * (t / 2.0)
	tbox(Transform3D(Basis(Vector3(d.x, 0, d.y) * ln, Vector3.UP * (y1 - y0), Vector3(n.x, 0, n.y) * t), Vector3(mid.x, (y0 + y1) / 2.0, mid.y)), key)

## a flat pane along a line of the frame being built, facing out of it (`off` in front of the line)
func _pane(a: Vector2, b: Vector2, y0: float, y1: float, key, off := 0.0, uvs := true) -> void:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x)
	var p := a + n * off
	var q := b + n * off
	pieces += 1
	quad(_v3(p, y0), _v3(q, y0), _v3(q, y1), _v3(p, y1), key, Vector3(n.x, 0, n.y),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)] if uvs else null)

## a solid along a line of the frame being built
func _seg_solid(a: Vector2, b: Vector2, tall: float, t := 0.3) -> void:
	var p: Vector3 = _xf * Vector3((a.x + b.x) / 2.0, tall / 2.0 - 0.5, (a.y + b.y) / 2.0)
	var d: Vector3 = _xf.basis * Vector3(b.x - a.x, 0, b.y - a.y)
	solid(p, Vector3(a.distance_to(b), tall + 1.0, t), atan2(-d.z, d.x))

## what has been built since the last commit becomes meshes under `node`: a part that can be shown and hidden
func _commit_to(node: Node3D) -> void:
	for key in _tools:
		var mi := MeshInstance3D.new()
		mi.mesh = (_tools[key] as SurfaceTool).commit()
		mi.material_override = _material(key)
		node.add_child(mi)
	_tools.clear()

## an iron rail along a line of the frame being built, standing on y: bars every 11 cm, a handrail, a rail low down
func _railing(a: Vector2, b: Vector2, y: float, h := 1.0, step := 0.11, col = RAIL) -> void:
	var ln := a.distance_to(b)
	if ln < 0.05:
		return
	var n := maxi(2, int(round(ln / step)))
	for k in range(n + 1):
		var p := a.lerp(b, float(k) / n)
		box(p.x - 0.008, y, p.y - 0.008, 0.016, h, 0.016, col)
	bar(_v3(a, y + h), _v3(b, y + h), 0.045, 0.03, col)
	bar(_v3(a, y + 0.1), _v3(b, y + 0.1), 0.025, 0.02, col)

## a long balcony on the front being built: its slab, cream-edged, `out` deep, the rail along its edge and at the ends
## that do not turn a corner
func _balcony(x0: float, x1: float, top: float, end0: bool, end1: bool, out := OUT) -> void:
	balconies += 1
	box(x0, top - 0.35, 0.0, x1 - x0, 0.35, out, "crema")
	_railing(Vector2(x0, out - 0.05), Vector2(x1, out - 0.05), top)
	if end0:
		_railing(Vector2(x0 + 0.04, 0.03), Vector2(x0 + 0.04, out - 0.05), top)
	if end1:
		_railing(Vector2(x1 - 0.04, 0.03), Vector2(x1 - 0.04, out - 0.05), top)

## the roof's deep eaves over a balcony, with little blocks along its top
func _eave(x0: float, x1: float, out := OUT) -> void:
	box(x0, TOP - 0.25, 0.0, x1 - x0, 0.75, out, "crema")
	var n := maxi(1, int(round((x1 - x0) / 1.25)))
	for i in range(n):
		box(lerpf(x0, x1, (i + 0.5) / n) - 0.13, TOP + 0.5, out - 0.32, 0.26, 0.2, 0.26, "crema")

## the cornice where there are no balconies, and the parapet over it
func _top(x0: float, x1: float) -> void:
	box(x0, TOP - 0.25, 0.0, x1 - x0, 0.4, 0.3, "crema")
	box(x0, TOP + 0.15, -0.25, x1 - x0, PARAPET - TOP - 0.15, 0.25, "ladrillo")
	box(x0 - 0.02, PARAPET, -0.27, x1 - x0 + 0.04, 0.06, 0.31, "blanco")

## a big window of a wing, behind its balcony: white aluminium, its blind part of the way down, the blind's case over it
func _big_window(r: Rect2, down: float) -> void:
	openings += 1
	window(r, 0xeeeeea, GLASS, 0)
	box(r.position.x + 0.04, r.end.y - down, -DEEP + 0.1, r.size.x - 0.08, down, 0.02, BLIND)
	for i in range(1, int(down / 0.08)):
		box(r.position.x + 0.04, r.end.y - i * 0.08, -DEEP + 0.12, r.size.x - 0.08, 0.01, 0.005, 0xcfc8b6)
	box(r.position.x - 0.08, r.end.y, 0.0, r.size.x + 0.16, 0.24, 0.1, "blanco")

## a window of the flats over the side streets: a cream frame round it, white aluminium, the blind part of the way
## down, a little rail across its lower half (they go down to the floor)
func _flat_window(r: Rect2, down: float, rail := true) -> void:
	openings += 1
	window(r, 0xeeeeea, GLASS, 0)
	box(r.position.x + 0.04, r.end.y - down, -DEEP + 0.1, r.size.x - 0.08, down, 0.02, BLIND)
	for i in range(1, int(down / 0.08)):
		box(r.position.x + 0.04, r.end.y - i * 0.08, -DEEP + 0.12, r.size.x - 0.08, 0.01, 0.005, 0xcfc8b6)
	stone_frame(r, 0.11, 0.05, "crema")
	if rail:
		_railing(Vector2(r.position.x + 0.03, -0.06), Vector2(r.end.x - 0.03, -0.06), r.position.y, 0.95, 0.12)

## a window of the shop's: aluminium round glass, the lit shop behind
func _shop_window(r: Rect2) -> void:
	openings += 1
	var z := -DEEP + 0.08
	var a := r.position
	var b := r.end
	quad(Vector3(a.x, a.y, z), Vector3(b.x, a.y, z), Vector3(b.x, b.y, z), Vector3(a.x, b.y, z), "vidrio", Vector3(0, 0, 1))
	for q in [[a.x, a.y, 0.06, r.size.y], [b.x - 0.06, a.y, 0.06, r.size.y], [a.x, a.y, r.size.x, 0.07], [a.x, b.y - 0.06, r.size.x, 0.06]]:
		box(q[0], q[1], z - 0.03, q[2], q[3], 0.05, ALU)
	var k := maxi(1, int(round(r.size.x / 1.4)))
	for i in range(1, k):
		box(a.x + r.size.x * i / k - 0.03, a.y, z - 0.03, 0.06, r.size.y, 0.05, ALU)
	_room(a.x, b.x, a.y, b.y, z - 0.04, -1.8)

## a room of light behind the glass (what shows of the shop from the street): its faces looking in
func _room(x0: float, x1: float, y0: float, y1: float, zf: float, zb: float) -> void:
	pieces += 1
	quad(Vector3(x0, y0, zb), Vector3(x1, y0, zb), Vector3(x1, y1, zb), Vector3(x0, y1, zb), "interior", Vector3(0, 0, 1))
	quad(Vector3(x0, y0, zb), Vector3(x0, y0, zf), Vector3(x0, y1, zf), Vector3(x0, y1, zb), "interior", Vector3(1, 0, 0))
	quad(Vector3(x1, y0, zb), Vector3(x1, y0, zf), Vector3(x1, y1, zf), Vector3(x1, y1, zb), "interior", Vector3(-1, 0, 0))
	quad(Vector3(x0, y0, zb), Vector3(x1, y0, zb), Vector3(x1, y0, zf), Vector3(x0, y0, zf), "interior", Vector3.UP)
	quad(Vector3(x0, y1, zb), Vector3(x1, y1, zb), Vector3(x1, y1, zf), Vector3(x0, y1, zf), "interior", Vector3.DOWN)
	var rng := RandomNumberGenerator.new()                     # its shelves along the back, with piles of folded goods
	rng.seed = int(x0 * 100.0) + 7
	for row in range(3):
		var y := y0 + 0.25 + row * 0.85
		if y + 0.55 > y1:
			break
		box(x0 + 0.05, y - 0.04, zb + 0.02, x1 - x0 - 0.1, 0.04, 0.45, 0xb8b4ac)
		var x := x0 + 0.1
		while x < x1 - 0.35:
			var w := rng.randf_range(0.25, 0.5)
			box(x, y, zb + 0.06, minf(w, x1 - 0.1 - x), rng.randf_range(0.2, 0.45), 0.36, PILES[rng.randi() % PILES.size()])
			x += w + 0.04

## a drop awning before a window: its case over it (always), and, when `cloth`, the striped cloth down to below the
## window's middle with its bottom bar a little out, its valance, its two arms
func _drop_awning(x0: float, x1: float, cloth: bool) -> void:
	if not cloth:
		box(x0 - 0.06, HEAD + 0.02, 0.0, x1 - x0 + 0.12, 0.2, 0.22, CASE)
		return
	var yb := 1.05
	var zb := 0.5
	pieces += 1
	quad(Vector3(x0, HEAD + 0.05, 0.14), Vector3(x1, HEAD + 0.05, 0.14), Vector3(x1, yb, zb), Vector3(x0, yb, zb), "toldo", Vector3(0, 0.15, 1).normalized(),
		[Vector2(x0 / 0.24, 0), Vector2(x1 / 0.24, 0), Vector2(x1 / 0.24, 1), Vector2(x0 / 0.24, 1)])
	quad(Vector3(x0, yb - 0.22, zb + 0.01), Vector3(x1, yb - 0.22, zb + 0.01), Vector3(x1, yb, zb + 0.01), Vector3(x0, yb, zb + 0.01), "toldo", Vector3(0, 0, 1),
		[Vector2(x0 / 0.24, 0.8), Vector2(x1 / 0.24, 0.8), Vector2(x1 / 0.24, 1), Vector2(x0 / 0.24, 1)])
	bar(Vector3(x0, yb, zb), Vector3(x1, yb, zb), 0.04, 0.04, ALU)
	for x in [x0 + 0.03, x1 - 0.03]:
		bar(Vector3(x, yb + 0.9, 0.02), Vector3(x, yb, zb - 0.02), 0.025, 0.025, ALU)

## the cables along the front being built at height y, from x0 to x1, in their clips
func _cables(y: float, x0: float, x1: float) -> void:
	var n := maxi(2, int(round((x1 - x0) / 1.1)))
	for k in range(n):
		var xa := lerpf(x0, x1, float(k) / n)
		var xb := lerpf(x0, x1, float(k + 1) / n)
		var ya := y - 0.025 * (k % 2)
		var yb := y - 0.025 * ((k + 1) % 2)
		bar(Vector3(xa, ya, 0.035), Vector3(xb, yb, 0.035), 0.035, 0.035, 0x2c2c2e)
		bar(Vector3(xa, ya - 0.06, 0.03), Vector3(xb, yb - 0.06, 0.03), 0.026, 0.026, 0x1e1e20)
		box(xa - 0.01, ya - 0.09, 0.0, 0.02, 0.13, 0.05, 0x8a8a86)

## an air conditioner on the wall being built: its box, its grille, its pipe down
func _ac(x: float, y: float) -> void:
	box(x, y, 0.0, 0.82, 0.56, 0.28, AC)
	box(x + 0.08, y + 0.08, 0.28, 0.42, 0.4, 0.01, 0x9a9c9e)
	for i in range(6):
		box(x + 0.1, y + 0.1 + i * 0.065, 0.285, 0.38, 0.012, 0.01, 0x6a6c70)
	box(x + 0.6, y + 0.12, 0.28, 0.14, 0.3, 0.01, 0xd0d0cc)
	bar(Vector3(x + 0.88, y + 0.2, 0.04), Vector3(x + 0.88, y + 0.56, 0.04), 0.04, 0.04, 0xf0f0ec)
	bar(Vector3(x + 0.88, y + 0.56, 0.04), Vector3(x + 0.88, BAND - 0.15, 0.04), 0.04, 0.04, 0xf0f0ec)

## how high the ground is before a spot of a front (this frame's y)
func _g(a: Vector2, b: Vector2, x: float) -> float:
	var p := _along(a, b, x) + _outward(a, b) * 0.5
	return ground(p.x, p.y)

# ---------------- the Calle de los Arcos (west) ----------------
func _arcos() -> void:
	var ln := face(NW, SW)
	len_arcos = ln
	# the ground floor: brick piers, the two windows, the shop's front between them; a cream band over them all
	masonry(0.0, ln, -2.0, BAND, [WIN_N, WIN_S, Rect2(BAY.x, FLOOR, BAY.y - BAY.x, HEAD - FLOOR)],
		[Rect2(WIN_N.position.x, HEAD, WIN_N.size.x, BAND - HEAD), Rect2(BAY.x, HEAD, BAY.y - BAY.x, BAND - HEAD), Rect2(WIN_S.position.x, HEAD, WIN_S.size.x, BAND - HEAD),
		Rect2(WIN_N.position.x, -2.0, WIN_N.size.x, SILL + 2.0), Rect2(WIN_S.position.x, -2.0, WIN_S.size.x, SILL + 2.0), Rect2(BAY.x, -2.0, BAY.y - BAY.x, FLOOR + 2.0)], "ladrillo", "crema")
	for r: Rect2 in [WIN_N, WIN_S]:
		plinth(r.position.x, r.end.x, SILL, SILL, "granito", 0.04, -2.0)
		for k in range(int(r.size.x / 1.2)):                      # (vents in the granite)
			box(r.position.x + 0.35 + k * 1.2, 0.2, 0.04, 0.3, 0.14, 0.012, 0x3a3a3c)
		_shop_window(r)
		_drop_awning(r.position.x, r.end.x, false)
	# above: the north wing, the white strips at each side of the bow, the south wing
	var holes: Array = []
	for y in [F1, F2]:
		holes.append(Rect2(1.5, y, 2.4, 2.3))
		holes.append(Rect2(13.6, y, 2.8, 2.3))
	masonry(0.0, 6.0, BAND, TOP, holes, [], "ladrillo")
	masonry(11.2, ln, BAND, TOP, holes, [], "ladrillo")
	for q in [[6.0, BOW.x - BOW_HALF], [BOW.x + BOW_HALF, 11.2]]:
		masonry(q[0], q[1], BAND, TOP + 0.35, [], [], "blanco")
		for y in [BAND - 0.15, F2 - 0.3]:
			box(q[0], y, 0.0, q[1] - q[0], 0.35, 0.14, "crema")
		box(q[0], TOP - 0.25, 0.0, q[1] - q[0], 0.6, 0.16, "crema")
		box(q[0] - 0.02, TOP + 0.35, -0.3, q[1] - q[0] + 0.04, 0.08, 0.48, "blanco")
	var downs := [1.1, 0.5, 0.8, 1.5]
	for i in range(holes.size()):
		_big_window(holes[i], downs[i])
	_ac(6.15, F1 + 0.3)
	# the balconies, their deep eaves: they turn the corners (_corners)
	for y in [F1 + 0.05, F2 + 0.05]:
		_balcony(0.0, 6.0, y, false, true)
		_balcony(11.2, ln, y, true, false)
	_eave(0.0, 6.0)
	_eave(11.2, ln)
	box(0.0, TOP + 0.15, -0.25, ln, PARAPET - TOP - 0.15, 0.25, "ladrillo")
	box(0.0, PARAPET, -0.27, ln, 0.06, 0.31, "blanco")
	home()

# ---------------- the shop's front, in the V under the bow ----------------
func _shopfront() -> void:
	face(NW, SW)
	var a0 := Vector2(BAY.x, 0.0)
	var a1 := Vector2(V0, 0.0)
	var l := Vector2(PORCH.x, _vz(PORCH.x))
	var r := Vector2(PORCH.y, _vz(PORCH.y))
	var b1 := Vector2(V1, 0.0)
	var b0 := Vector2(BAY.y, 0.0)
	var pl := Vector2(DOOR.x, DOOR_Z)
	var pr := Vector2(DOOR.y, DOOR_Z)
	# the glass, on a low wall of brick capped in cream, flat at each end and slanting out to the porch
	for q in [[a0, a1], [a1, l], [r, b1], [b1, b0]]:
		var p: Vector2 = q[0]
		var e: Vector2 = q[1]
		_seg(p, e, -1.0, SILL, 0.22, "ladrillo")
		_seg(p - (e - p).normalized() * 0.02, e + (e - p).normalized() * 0.02, SILL, SILL + 0.07, 0.3, "crema")
		_pane(p, e, SILL + 0.07, 3.6, "vidrio", -0.08, false)
		var d := (e - p).normalized()
		var n := Vector2(-d.y, d.x)
		for k in range(3):
			var at: Vector2 = p.lerp(e, k / 2.0) - n * 0.06
			box(at.x - 0.03, SILL + 0.07, at.y - 0.03, 0.06, 3.6 - SILL - 0.07, 0.06, ALU)
		_seg(p - n * 0.03, e - n * 0.03, 3.52, 3.6, 0.06, ALU)
		_seg(p - n * 0.03, e - n * 0.03, SILL + 0.07, SILL + 0.13, 0.06, ALU)
	_room(BAY.x, BAY.y, FLOOR, HEAD, -DEEP, -6.0)
	var xl := l.lerp(pl, l.y / (l.y - pl.y))                                       # (the shop's floor out to the slanting glass)
	var xr := r.lerp(pr, r.y / (r.y - pr.y))
	flat(PackedVector2Array([a1, l, xl]), FLOOR, "interior")
	flat(PackedVector2Array([xr, r, b1]), FLOOR, "interior")
	# the porch: granite underfoot, its sides of glass over blue tiles, the glass door at its back
	flat(PackedVector2Array([l, r, pr, pl]), FLOOR + 0.005, "granito")
	for q in [[l, pl], [pr, r]]:
		_seg(q[0], q[1], FLOOR, 1.0, 0.08, "azulejo")
		_pane(q[0], q[1], 1.0, 3.6, "vidrio", -0.04, false)
		box((q[0] as Vector2).x - 0.03, FLOOR, (q[0] as Vector2).y - 0.03, 0.06, 3.6 - FLOOR, 0.06, ALU)
	_seg(Vector2(DOOR.x - 0.12, DOOR_Z - 0.02), Vector2(DOOR.x, DOOR_Z - 0.02), FLOOR, 3.6, 0.1, ALU)
	_seg(Vector2(DOOR.y, DOOR_Z - 0.02), Vector2(DOOR.y + 0.12, DOOR_Z - 0.02), FLOOR, 3.6, 0.1, ALU)
	_seg(Vector2(DOOR.x, DOOR_Z - 0.02), Vector2(DOOR.y, DOOR_Z - 0.02), FLOOR + 2.5, HEAD, 0.1, "azulejo")
	var card_at: Vector2 = l.lerp(pl, 0.45)                                         # the card of its hours, on the porch's glass
	var cd := (pl - l).normalized()
	var cn := Vector2(-cd.y, cd.x)
	_pane(card_at - cd * 0.15 + cn * 0.01, card_at + cd * 0.15 + cn * 0.01, 1.25, 1.65, "horario")
	# the steps, the pillar at the V's point (its tags), the blue post
	for s in [[7.0, 10.3, 1.2, 1.5, 0.15], [7.25, 10.05, 0.9, 1.2, 0.3], [7.5, 9.8, 0.3, 0.9, FLOOR]]:
		box(s[0], -0.6, s[2], s[1] - s[0], s[4] + 0.6, s[3] - s[2], "granito")
	drum(Vector3(PILLAR.x, -0.5, PILLAR.y), 0.2, 0.2, 4.1, "crema", 16)
	for t in [[0.3, 1.1, -0.2, 1.3], [-0.4, 1.5, 0.1, 1.2], [0.1, 1.65, 0.5, 1.75], [-0.6, 0.9, -0.2, 0.75], [0.2, 2.0, -0.3, 2.2]]:
		bar(Vector3(PILLAR.x + 0.205 * sin(t[0]), t[1], PILLAR.y + 0.205 * cos(t[0])), Vector3(PILLAR.x + 0.205 * sin(t[2]), t[3], PILLAR.y + 0.205 * cos(t[2])), 0.018, 0.006, 0x18181a)
	bar(Vector3(8.2, 0.3, 1.3), Vector3(8.2, 1.3, 1.3), 0.05, 0.05, BLUE)
	box(8.17, 0.95, 1.33, 0.06, 0.16, 0.05, 0x1a1a1c)
	# the V of boards under the bow: its two boards, its cream soffit and top, aluminium edges
	var apex := APEX
	_pane(a1, apex, 3.6, BAND, "rotulo")
	_pane(apex, b1, 3.6, BAND, "rotulo")
	_flat_down(PackedVector2Array([a1, apex, b1]), 3.6, "crema")
	flat(PackedVector2Array([a1, apex, b1]), BAND, "crema")
	for q in [[a1, apex], [apex, b1]]:
		var qa: Vector2 = q[0]
		var qb: Vector2 = q[1]
		var qd := (qb - qa).normalized()
		var qn := Vector2(-qd.y, qd.x) * 0.015
		for y in [3.6, BAND - 0.03]:
			bar(_v3(qa + qn, y), _v3(qb + qn, y), 0.03, 0.05, ALU)
	# the cases of the two awnings in a V, under the boards
	for q in [[Vector2(4.5, 0.05), Vector2(APEX.x, APEX.y + 0.04)], [Vector2(APEX.x, APEX.y + 0.04), Vector2(12.65, 0.05)]]:
		bar(_v3(q[0], 3.5), _v3(q[1], 3.5), 0.16, 0.16, CASE)
	# the street's name tiles are Texturas's; the alarm box over the bay
	box(4.55, 3.7, 0.0, 0.3, 0.36, 0.1, 0xe8e8e4)
	box(4.6, 3.95, 0.1, 0.2, 0.06, 0.01, 0x2a5ab0)
	home()

## the two awnings in a V, out from under the boards, mitred where they meet
func _v_awnings() -> void:
	face(NW, SW)
	var y := 3.48
	var reach := 1.3
	var drop := 0.75
	var t0 := Vector2(4.5, 0.05)
	var t1 := Vector2(APEX.x, APEX.y + 0.04)
	var t2 := Vector2(12.65, 0.05)
	var d0 := (t1 - t0).normalized()
	var d1 := (t2 - t1).normalized()
	var n0 := Vector2(-d0.y, d0.x)
	var n1 := Vector2(-d1.y, d1.x)
	var o0 := t0 + n0 * reach
	var o2 := t2 + n1 * reach
	var hit = Geometry2D.line_intersects_line(o0, d0, o2, d1)
	var q: Vector2 = hit if hit != null else t1 + (n0 + n1).normalized() * reach
	for half in [[t0, t1, q, o0, d0], [t1, t2, o2, q, d1]]:
		var pts: Array = [half[0], half[1], half[2], half[3]]
		var dir: Vector2 = half[4]
		var org: Vector2 = half[0]
		var ys := [y, y, y - drop, y - drop]
		var v: Array = []
		var uv: Array = []
		for k in range(4):
			v.append(_v3(pts[k], ys[k]))
			uv.append(Vector2(((pts[k] as Vector2) - org).dot(dir) / 0.24, 0.0 if k < 2 else 1.0))
		var nrm: Vector3 = ((v[1] as Vector3) - v[0]).cross((v[3] as Vector3) - v[0]).normalized()
		if nrm.y < 0.0:
			nrm = -nrm
		pieces += 1
		quad(v[0], v[1], v[2], v[3], "toldo", nrm, uv)
	for e in [[o0, q, d0, t0], [q, o2, d1, t1]]:
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		var dir: Vector2 = e[2]
		var org: Vector2 = e[3]
		var nn := Vector2(-dir.y, dir.x)
		pieces += 1
		quad(_v3(a, y - drop - 0.25), _v3(b, y - drop - 0.25), _v3(b, y - drop), _v3(a, y - drop), "toldo", Vector3(nn.x, 0, nn.y),
			[Vector2((a - org).dot(dir) / 0.24, 0.8), Vector2((b - org).dot(dir) / 0.24, 0.8), Vector2((b - org).dot(dir) / 0.24, 1.0), Vector2((a - org).dot(dir) / 0.24, 1.0)])
		bar(_v3(a, y - drop), _v3(b, y - drop), 0.045, 0.045, ALU)
	bar(_v3(t0, y - 0.15), _v3(o0, y - drop), 0.035, 0.035, ALU)
	bar(_v3(t2, y - 0.15), _v3(o2, y - drop), 0.035, 0.035, ALU)
	home()

# ---------------- the bow over the shop ----------------
func _bow_at(phi: float, r: float) -> Vector2:
	return Vector2(BOW.x + r * sin(phi), BOW.y + r * cos(phi))

func _bow() -> void:
	face(NW, SW)
	var n := 16
	var phi0 := -asin(BOW_HALF / BOW_R)
	var step := -2.0 * phi0 / n
	var bands := [[BAND - 0.15, F1 + 0.05, false], [F1 + 0.05, F1 + 2.3, true], [F1 + 2.3, F2 + 0.05, false], [F2 + 0.05, F2 + 2.3, true], [F2 + 2.3, TOP, false]]
	var r0 := BOW_R
	var rg := BOW_R - 0.16
	for i in range(n):
		var a0 := phi0 + i * step
		var a1 := a0 + step
		var win := (i >= 3 and i <= 6) or (i >= 9 and i <= 12)
		var p0 := _bow_at(a0, r0)
		var p1 := _bow_at(a1, r0)
		var nm := Vector3(sin((a0 + a1) / 2.0), 0, cos((a0 + a1) / 2.0))
		for b in bands:
			var y0: float = b[0]
			var y1: float = b[1]
			if win and b[2]:
				var g0 := _bow_at(a0, rg)
				var g1 := _bow_at(a1, rg)
				quad(_v3(g0, y0), _v3(g1, y0), _v3(g1, y1), _v3(g0, y1), GLASS, nm)
				quad(_v3(g0, y1), _v3(g1, y1), _v3(p1, y1), _v3(p0, y1), "ladrillo", Vector3.DOWN)
				quad(_v3(g0, y0), _v3(g1, y0), _v3(p1, y0), _v3(p0, y0), "crema", Vector3.UP)
				var bl0 := _bow_at(a0, rg + 0.03)
				var bl1 := _bow_at(a1, rg + 0.03)
				var down := 0.9 if y0 < F2 else 1.3
				quad(_v3(bl0, y1 - down), _v3(bl1, y1 - down), _v3(bl1, y1), _v3(bl0, y1), BLIND, nm)
			else:
				pieces += 1
				quad(_v3(p0, y0), _v3(p1, y0), _v3(p1, y1), _v3(p0, y1), "ladrillo", nm)
		for edge in [[3, a0, 1.0], [9, a0, 1.0], [6, a1, -1.0], [12, a1, -1.0]]:       # the windows' sides
			if i != int(edge[0]):
				continue
			var a: float = edge[1]
			var t := Vector3(cos(a), 0, -sin(a)) * float(edge[2])
			for b in bands:
				if b[2]:
					var e0 := _bow_at(a, r0)
					var e1 := _bow_at(a, rg)
					quad(_v3(e1, b[0]), _v3(e0, b[0]), _v3(e0, b[1]), _v3(e1, b[1]), "ladrillo", t)
		if i in [5, 11]:                                                              # the mullions
			for b in bands:
				if b[2]:
					var m := _bow_at(a0, rg + 0.02)
					bar(_v3(m, b[0]), _v3(m, b[1]), 0.06, 0.05, 0xeeeeea)
	# the windows' little rails, on the slabs
	for y in [F1 + 0.05, F2 + 0.05]:
		for w in [[3, 7], [9, 13]]:
			var pts: Array = []
			for k in range(int(w[0]), int(w[1]) + 1):
				pts.append(_bow_at(phi0 + k * step, r0 + 0.08))
			for k in range(pts.size() - 1):
				_railing(pts[k], pts[k + 1], y, 0.9, 0.11)
	# the cream bands at its floors and its top: each the bow's outline out a little, the wall's line behind
	var outline := PackedVector2Array()
	for k in range(n + 1):
		outline.append(_bow_at(phi0 + k * step, r0 + 0.14))
	outline.append(Vector2(BOW.x + BOW_HALF + 0.14, 0.0))
	outline.append(Vector2(BOW.x - BOW_HALF - 0.14, 0.0))
	for q in [[BAND - 0.15, F1 + 0.05], [F2 - 0.3, F2 + 0.05], [TOP - 0.25, TOP + 0.25]]:
		flat(outline, q[1], "crema")
		_flat_down(outline, q[0], "crema")
		for k in range(n):
			pieces += 1
			var c0: Vector2 = outline[k]
			var c1: Vector2 = outline[k + 1]
			var mid := (phi0 + (k + 0.5) * step)
			quad(_v3(c0, q[0]), _v3(c1, q[0]), _v3(c1, q[1]), _v3(c0, q[1]), "crema", Vector3(sin(mid), 0, cos(mid)))
	# the rail round its top, the iron pergola over it
	var top_rail: Array = []
	for k in range(n + 1):
		top_rail.append(_bow_at(phi0 + k * step, r0 + 0.06))
	for k in range(n):
		_railing(top_rail[k], top_rail[k + 1], TOP + 0.25, 0.95, 0.12, IRON)
	var px := [BOW.x - 1.0, BOW.x + 1.0]
	var pz := [-1.3, 0.5]
	for x in px:
		for z in pz:
			bar(Vector3(x, TOP + 0.25, z), Vector3(x, 13.3, z), 0.07, 0.07, IRON)
	for z in pz:
		bar(Vector3(px[0], 13.3, z), Vector3(px[1], 13.3, z), 0.08, 0.08, IRON)
	for x in px:
		bar(Vector3(x, 13.3, pz[0]), Vector3(x, 13.3, pz[1]), 0.08, 0.08, IRON)
	for k in range(1, 4):
		var x: float = lerpf(px[0], px[1], k / 4.0)
		bar(Vector3(x, 13.32, pz[0]), Vector3(x, 13.32, pz[1]), 0.05, 0.05, IRON)
	home()

# ---------------- the Calle del Molino (north) ----------------
func _molino() -> void:
	var ln := face(MS, NW)
	_tiled(0.0, 17.3, -2.0, BAND, 0.0, "rayas")
	_picture(12.9, 15.5, 0.9, 3.3, 0.012, "mural")
	masonry(17.3, ln, -2.0, BAND, [WIN_M], [Rect2(WIN_M.position.x, HEAD, WIN_M.size.x, BAND - HEAD), Rect2(WIN_M.position.x, -2.0, WIN_M.size.x, SILL + 2.0)], "ladrillo", "crema")
	plinth(WIN_M.position.x, WIN_M.end.x, SILL, SILL, "granito", 0.04, -2.0)
	_shop_window(WIN_M)
	_drop_awning(WIN_M.position.x, WIN_M.end.x, false)
	_ac(4.0, 3.25)
	_ac(10.6, 3.35)
	_cables(BAND - 0.12, 0.0, 17.3)
	var holes: Array = []
	for y in [F1 + 0.1, F2 + 0.1]:
		for x in [2.6, 6.2, 9.8, 13.4, 16.4]:
			holes.append(Rect2(x - 0.58, y, 1.16, 2.0))
		holes.append(Rect2(19.0, y - 0.05, 1.5, 2.25))
	masonry(0.0, ln, BAND, TOP, holes, [], "ladrillo")
	for i in range(holes.size()):
		var r: Rect2 = holes[i]
		if r.position.x > 18.0:
			_big_window(r, 0.9)
		else:
			_flat_window(r, [0.9, 1.2, 0.6, 1.4, 1.0][i % 6] if i % 6 < 5 else 0.9)
	box(0.0, BAND - 0.15, 0.0, ln - WRAP, 0.18, 0.06, "crema")
	for y in [F1 + 0.05, F2 + 0.05]:
		_balcony(ln - WRAP, ln, y, true, false)
	_eave(ln - WRAP, ln)
	_top(0.0, ln - WRAP)
	box(ln - WRAP, TOP + 0.15, -0.25, WRAP, PARAPET - TOP - 0.15, 0.25, "ladrillo")
	box(ln - WRAP, PARAPET, -0.27, WRAP, 0.06, 0.31, "blanco")
	home()

# ---------------- part 3, the next house along the Molino ----------------
func _part3() -> void:
	var ln := face(NE, MS)
	pieces += 1
	quad(Vector3(0, -2.0, 0), Vector3(ln, -2.0, 0), Vector3(ln, 3.35, 0), Vector3(0, 3.35, 0), "tosco", Vector3(0, 0, 1))
	for k in range(int(ln / 0.95)):                                              # the holes along its top
		box(0.4 + k * 0.95, 3.02, 0.0, 0.13, 0.13, 0.004, 0x141414)
	var rng := RandomNumberGenerator.new()                                       # smears of mortar: blotches of all sizes, more
	rng.seed = 3692101                                                           # of them low down and along the joints
	var greys := [0xd6d0c6, 0xc9c1b5, 0xe0dbd2]
	for k in range(46):
		var bw := rng.randf_range(0.08, 0.55)
		var bh := rng.randf_range(0.06, 0.38) if k % 5 != 0 else rng.randf_range(0.5, 1.4)
		var bx := rng.randf_range(0.1, ln - 0.6)
		var by := rng.randf_range(0.05, 2.6) * (0.55 if k % 3 == 0 else 1.0)
		box(bx, by, 0.0, bw if k % 5 != 0 else 0.07, bh, 0.004 + 0.0015 * (k % 3), greys[k % 3])
	box(0.0, 3.35, 0.0, ln, 0.35, 0.05, "hormigon")
	var holes: Array = []
	for y in [F1 + 0.1, F2 + 0.1]:
		for x in [4.6, 7.6, 10.6]:
			holes.append(Rect2(x - 0.55, y, 1.1, 1.9))
		holes.append(Rect2(0.5, y - 0.05, 1.5, 2.2))
	masonry(0.0, ln, 3.7, TOP, holes, [], "ladrillo")
	for i in range(holes.size()):
		var r: Rect2 = holes[i]
		if r.position.x < 1.0:
			_big_window(r, 1.0)
		else:
			_flat_window(r, [0.7, 1.3, 1.0][i % 4] if i % 4 < 3 else 0.8)
	for y in [F1 + 0.05, F2 + 0.05]:                                              # its white balcony at the east end
		box(0.0, y - 0.3, 0.0, 2.6, 0.3, 0.9, "blanco")
		box(0.0, y, 0.78, 2.6, 0.95, 0.12, "blanco")
		box(2.48, y, 0.0, 0.12, 0.95, 0.8, "blanco")
		box(0.0, y, 0.0, 0.12, 0.95, 0.8, "blanco")
		box(-0.02, y + 0.95, 0.76, 2.64, 0.05, 0.16, "crema")
	_top(0.0, ln)
	home()

# ---------------- the Calle de Granada (south) ----------------
func _granada() -> void:
	var ln := face(SW, SE)
	masonry(0.0, 3.9, -2.0, BAND, [WIN_G], [Rect2(WIN_G.position.x, HEAD, WIN_G.size.x, BAND - HEAD), Rect2(WIN_G.position.x, -2.0, WIN_G.size.x, SILL + 2.0)], "ladrillo", "crema")
	plinth(WIN_G.position.x, WIN_G.end.x, SILL, SILL, "granito", 0.04, -2.0)
	_shop_window(WIN_G)
	_drop_awning(WIN_G.position.x, WIN_G.end.x, false)
	_tiled(3.9, 16.9, -2.0, BAND, 0.0, "rayas")
	_picture(8.8, 11.4, 0.9, 3.3, 0.012, "mural")
	_ac(4.6, 3.35)
	_ac(7.0, 3.5)
	_cables(BAND - 0.12, 3.9, 16.9)
	# the flats' doorway: granite to over its door, the glass door set in, grey gates before it
	masonry(16.9, ln, -2.0, 3.5, [PORTAL], [], "granito")
	masonry(16.9, ln, 3.5, BAND, [], [], "ladrillo")
	var pz := -DEEP + 0.05
	box(PORTAL.position.x, 0.0, pz - 0.05, PORTAL.size.x, PORTAL.size.y, 0.03, GLASS)
	for q in [[PORTAL.position.x, 0.08], [PORTAL.end.x - 0.08, 0.08], [PORTAL.position.x + PORTAL.size.x / 2.0 - 0.03, 0.06]]:
		box(q[0], 0.0, pz - 0.03, q[1], PORTAL.size.y, 0.06, 0x8a8e92)
	box(PORTAL.position.x, PORTAL.size.y - 0.08, pz - 0.03, PORTAL.size.x, 0.08, 0.06, 0x8a8e92)
	box(PORTAL.position.x, 1.0, pz - 0.02, PORTAL.size.x, 0.05, 0.06, 0x8a8e92)
	for k in range(14):                                                             # the gates
		box(PORTAL.position.x + 0.05 + k * 0.1, 0.0, 0.03, 0.02, 2.0, 0.02, 0x9a9ea4)
	for y in [0.1, 1.0, 1.95]:
		box(PORTAL.position.x, y, 0.02, PORTAL.size.x, 0.04, 0.04, 0x9a9ea4)
	box(PORTAL.position.x - 0.2, 0.0, -0.6, PORTAL.size.x + 0.4, 0.12, 0.6, "granito")
	# above: brick, the windows of the flats, the dark strip of the stairs' louvres, the balconies by the corner
	var holes: Array = []
	for y in [F1 + 0.1, F2 + 0.1]:
		for x in [5.2, 8.6, 12.0, 15.2]:
			holes.append(Rect2(x - 0.58, y, 1.16, 2.0))
		holes.append(Rect2(0.55, y - 0.05, 1.5, 2.25))
		holes.append(Rect2(17.8, y + 0.6, 0.85, 1.1))
	holes.append(Rect2(2.8, F1 + 0.2, 0.45, TOP - F1 - 0.8))
	masonry(0.0, ln, BAND, TOP, holes, [], "ladrillo")
	for i in range(holes.size()):
		var r: Rect2 = holes[i]
		if r.size.x < 0.5:
			box(r.position.x, r.position.y, -DEEP + 0.05, r.size.x, r.size.y, 0.03, 0x2e3438)
			for k in range(int(r.size.y / 0.12)):
				box(r.position.x, r.position.y + k * 0.12, -DEEP + 0.08, r.size.x, 0.02, 0.06, 0x4a5258)
		elif r.position.x < 1.0:
			_big_window(r, 0.7)
		else:
			_flat_window(r, [1.0, 0.6, 1.3, 0.8, 0.0, 0.5][i % 6], r.size.x > 1.0)
	box(WRAP, BAND - 0.15, 0.0, ln - WRAP, 0.18, 0.06, "crema")
	for y in [F1 + 0.05, F2 + 0.05]:
		_balcony(0.0, WRAP, y, false, true)
	_eave(0.0, WRAP)
	_top(WRAP, ln)
	box(0.0, TOP + 0.15, -0.25, WRAP, PARAPET - TOP - 0.15, 0.25, "ladrillo")
	box(0.0, PARAPET, -0.27, WRAP, 0.06, 0.31, "blanco")
	home()

# ---------------- the corners the balconies turn ----------------
## The balconies, their eaves and the cream band over the ground floor turn the two corners of the Arcos: the corner
## piece of each is the four-sided bit between the walls' lines and the lines of the two balconies' edges.
func _corners() -> void:
	for c in [[NW, _na, _nm], [SW, _ng, _na]]:
		var at: Vector2 = c[0]
		var n0: Vector2 = c[1]
		var n1: Vector2 = c[2]
		for y in [F1 + 0.05, F2 + 0.05]:
			_corner(at, n0, n1, y - 0.35, y, OUT, true)
		_corner(at, n0, n1, TOP - 0.25, TOP + 0.5, OUT, false)

func _corner(c: Vector2, n0: Vector2, n1: Vector2, y0: float, y1: float, out: float, rail: bool) -> void:
	home()
	var k := 1.0 + n0.dot(n1)
	var p1 := c + n0 * out
	var p2 := c + (n0 + n1) * out / k
	var p3 := c + n1 * out
	var poly := PackedVector2Array([c, p1, p2, p3])
	flat(poly, y1, "crema")
	_flat_down(poly, y0, "crema")
	pieces += 1
	quad(_v3(p1, y0), _v3(p2, y0), _v3(p2, y1), _v3(p1, y1), "crema", Vector3(n0.x, 0, n0.y))
	quad(_v3(p2, y0), _v3(p3, y0), _v3(p3, y1), _v3(p2, y1), "crema", Vector3(n1.x, 0, n1.y))
	if rail:
		var i1 := c + n0 * (out - 0.05)
		var i2 := c + (n0 + n1) * (out - 0.05) / k
		var i3 := c + n1 * (out - 0.05)
		_railing(i1, i2, y1)
		_railing(i2, i3, y1)

# ---------------- its back, its roof ----------------
func _back_and_roof() -> void:
	for pair in [[E1, NE], [E2, E1], [SE, E2]]:               # (the walls that look on to the plot east of it)
		_plain(pair[0], pair[1], -2.0, PARAPET, "medianera")
	home()
	flat(PackedVector2Array([SW, NW, NE, E1, E2, SE]), TOP, "azotea")
	var ring := [SW, NW, NE, E1, E2, SE]
	for i in range(ring.size()):                               # the parapets' inner faces, round the whole roof
		var a: Vector2 = ring[i]
		var b: Vector2 = ring[(i + 1) % ring.size()]
		var ln := face(b, a)
		box(0.0, TOP, -0.25, ln, PARAPET - TOP, 0.005, "medianera")
	home()
	box(SW.x + 8.0, TOP, SW.y - 9.0, 2.6, 2.4, 2.2, "medianera")                   # the stairs' head on the roof
	box(SW.x + 7.95, TOP + 2.4, SW.y - 9.05, 2.7, 0.1, 2.3, "blanco")

# ---------------- open and shut ----------------
## Open: the awnings down, the door swung in, light inside. Shut: the awnings rolled up in their cases, the door shut.
func _states() -> void:
	_shut = Node3D.new()
	add_child(_shut)
	face(NW, SW)
	_leaf(DOOR.x, DOOR.y, DOOR_Z)
	for r: Rect2 in [WIN_N, WIN_S]:
		box(r.position.x - 0.04, HEAD - 0.12, 0.12, r.size.x + 0.08, 0.14, 0.12, "toldo")        # (the cloth rolled up under the case)
	for q in [[Vector2(4.5, 0.05), Vector2(APEX.x, APEX.y + 0.04)], [Vector2(APEX.x, APEX.y + 0.04), Vector2(12.65, 0.05)]]:
		bar(_v3(q[0], 3.36), _v3(q[1], 3.36), 0.12, 0.12, "toldo")               # (the V's cloth rolled up under its cases)
	face(MS, NW)
	box(WIN_M.position.x - 0.04, HEAD - 0.12, 0.12, WIN_M.size.x + 0.08, 0.14, 0.12, "toldo")
	face(SW, SE)
	box(WIN_G.position.x - 0.04, HEAD - 0.12, 0.12, WIN_G.size.x + 0.08, 0.14, 0.12, "toldo")
	home()
	_commit_to(_shut)
	_open = Node3D.new()
	add_child(_open)
	_v_awnings()
	face(NW, SW)
	for r: Rect2 in [WIN_N, WIN_S]:
		_drop_awning(r.position.x, r.end.x, true)
	var keep := _xf                                                              # the door, swung in against the jamb
	_xf = keep * Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(DOOR.x, 0.0, DOOR_Z))
	_leaf(0.0, DOOR.y - DOOR.x, 0.0)
	_xf = keep
	_seg(Vector2(DOOR.x, DOOR_Z - 0.5), Vector2(DOOR.y, DOOR_Z - 0.5), HEAD - 0.06, HEAD - 0.02, 0.6, "luz")
	face(MS, NW)
	_drop_awning(WIN_M.position.x, WIN_M.end.x, true)
	face(SW, SE)
	_drop_awning(WIN_G.position.x, WIN_G.end.x, true)
	home()
	_commit_to(_open)
	face(NW, SW)
	for q in [[Vector3(APEX.x, 2.6, -1.5), 6.0, 0.8], [Vector3(2.1, 2.4, -1.0), 4.0, 0.5], [Vector3(15.6, 2.4, -1.0), 4.5, 0.5]]:
		var lamp := OmniLight3D.new()
		lamp.position = _xf * (q[0] as Vector3)
		lamp.light_color = Color(1.0, 0.96, 0.88)
		lamp.omni_range = q[1]
		lamp.light_energy = q[2]
		lamp.shadow_enabled = false
		add_child(lamp)
		_lights.append(lamp)
	home()

## the shop's glass door, in its aluminium frame (x0..x1 along its line, at z)
func _leaf(x0: float, x1: float, z: float) -> void:
	var h := 2.5
	for x in [x0, x1 - 0.07]:
		box(x, FLOOR, z - 0.03, 0.07, h, 0.06, ALU)
	for y in [FLOOR, FLOOR + h - 0.07]:
		box(x0, y, z - 0.03, x1 - x0, 0.07 if y > FLOOR else 0.12, 0.06, ALU)
	quad(Vector3(x0 + 0.07, FLOOR + 0.12, z), Vector3(x1 - 0.07, FLOOR + 0.12, z), Vector3(x1 - 0.07, FLOOR + h - 0.07, z), Vector3(x0 + 0.07, FLOOR + h - 0.07, z), "vidrio", Vector3(0, 0, 1))
	box(x1 - 0.16, FLOOR + 0.9, z + 0.03, 0.03, 0.5, 0.05, 0xb8bcc0)

func set_open(on: bool) -> void:
	is_open = on
	if dentro != null:
		dentro.open = on
	if maniqui != null:                 # (the mannequin is out only while it is open: the user, "Solo mientras la tienda está abierta")
		maniqui.set_out(on)
	if _shut != null:
		_shut.visible = not on
		_open.visible = on
	for lamp in _lights:
		(lamp as Light3D).visible = on
	if _mats.has("interior"):
		(_mats["interior"] as StandardMaterial3D).emission_energy_multiplier = 0.14 if on else 0.03

func _process(_delta: float) -> void:
	var game = W.get_parent() if W != null else null
	if game != null and "clock" in game and "weekday" in game:
		var want: bool = open_at(int(game.weekday), float(game.clock))
		if want != is_open:
			set_open(want)
