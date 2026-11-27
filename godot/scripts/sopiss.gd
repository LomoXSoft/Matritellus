extends "res://scripts/esquina.gd"
## "Seguros Sopiss": the red corner building of the crossroads of the traffic lights ("el cruce de los semáforos", "las
## cuatro esquinas"), where the Avenida de la Constitución, the Calle de Santa Ana, the Calle de los Arcos, the Calle
## Cervantes and the Calle del Salvador meet. The user, 21 November 2026: "empezar por el edificio de soliss seguros
## (última foto) y que llamaremos seguros sopiss, tendrá luces de apagado o encendido según su horario y en su interior
## saldrán dos NPCs genéricos hablando de seguros cuando abierto, y una señora de la limpieza cuando cerrado. Se podrá
## ver desde fuera, pero no pasar." Built by hand from Street View (November 2024, from all five streets:
## tools/cruce/capturas.py) on the house `salvador_24` of the map (casas_calles.gd marks it "obra"), with no rebake;
## referencias/cruce/LEEME.md.
##
## Three floors of oxblood render with cream bands and frames, 10.9 m to its eaves (measured: tools/cruce/mide.py):
##   - to the avenue (east, 8.5 m): a shop window and the glazed entrance up two steps, under a magenta fascia with the
##     name; two balconies on each floor above, a blue script name between the top ones;
##   - to the Calle Cervantes (south, 5.1 m): one shop window under the fascia, one balcony on each floor;
##   - to the Calle del Salvador (north, 16.4 m): a corner window under the end of the fascia, a big window, a frosted
##     one, the flats' iron door; above, on each floor, three balconies, a barred window and a little square one;
##   - a hipped roof of old tiles on wide wooden eaves, a brick chimney, an old hoarding.
## The windows of the office are real glass: its room is built behind them (counter, desks, waiting chairs, its name on
## a partition) and nobody gets in. Its lamps, its sign's glow and the card on its door follow its opening hours.
## No real name, logo or slogan: "SOPISS", "Seguros de toda la vida"; the script name above is "Salamanquesa". That
## name is a neon: blue by day, and by night it shines yellow (the user, 22 November 2026: "El neon de salamanquesa podría
## brillar en amarillo por la noche"), whether the office is open or not.
##
## For Sistemas (the people are its own; none is made here): `agent_spot`/`agent_h` and `client_spot`/`client_h` (the
## two who talk about insurance while it is open, face to face across the counter), `clean_spots` (a round for the
## cleaning lady while it is shut), `floor_h` (the height of the office's floor; it is in MapData.decks too),
## `is_open`, `open_at(day, hour)`, `set_open(on)`; `desk_spots` is [agent_spot, client_spot].
##
## Frame: the map's own (x east, z south), y = 0 the pavement before the avenue's front. Each front is built in its own
## frame (obra.face: x along it seen from the street, z out of it). What it shares with the other corners of the
## crossroads (the roof, the eaves, the shared walls, the solids) is esquina.gd's.

const HOUSE := "salvador_24"
const NAME := "Seguros Sopiss"
const DIR := "res://assets/sopiss/"

# its corners on the map (Catastro 4391002VJ5649S, part 1: the house's own ring)
const NW := Vector2(92.34, 58.42)            # where it ends on the Salvador
const NE := Vector2(108.32, 62.26)           # the corner of the Salvador and the avenue
const SE := Vector2(108.56, 70.77)           # the corner of the avenue and the Calle Cervantes
const SW := Vector2(103.82, 72.76)           # where it ends on the Calle Cervantes
const P1 := Vector2(103.70, 68.43)           # the party walls behind, back to NW
const P2 := Vector2(96.95, 68.56)
const P3 := Vector2(92.40, 67.64)

const SILL := 0.62                  # the avenue window's sill
const PLINTH := 0.95                # the cream stone at the foot of the piers
const HEAD := 3.1                   # the top of the office's openings
const FASCIA0 := 3.3                # the magenta fascia: its foot...
const FASCIA1 := 4.05               # ...its top...
const FASCIA_OUT := 0.3             # ...and how far it stands out
const F1 := 4.55                    # the first floor: the top of the cream band, the balconies' floor
const F2 := 7.9                     # the second floor
const OPEN_H := 2.45                # how tall the balconies' doors are
const FRAME := 0.3                  # the cream frames round them
const TOP := 10.9                   # the top of the walls
const EAVE := 0.85                  # how far the eaves come out
const PITCH := 0.33                 # the roof's slope
const RISE0 := 0.28                 # the tiles over the wall's line (EAVE * PITCH: the eaves' edge is level with TOP)
const BALC_OUT := 0.42
const FLOOR := 0.33                 # the office's floor over the pavement (two steps)
const CEIL := 3.2                   # its ceiling
const BACK := 4.4                   # its back wall: this far along the Salvador from the house's west end
const HOURS := {0: [[9.0, 14.0], [17.0, 20.0]], 1: [[9.0, 14.0], [17.0, 20.0]], 2: [[9.0, 14.0], [17.0, 20.0]], 3: [[9.0, 14.0], [17.0, 20.0]],
	4: [[9.0, 14.0], [17.0, 20.0]]}      # day (0 Monday ... 6 Sunday): from when to when. Shut on Saturdays and Sundays
const DIM := 0.34                   # what is left of the room's colours with its lamps off
const NEON_W := 2.5                               # how wide the script name is (its picture is 4 : 1)
const NEON_DAY := Color(0.29, 0.49, 0.84)        # the script name by day: blue...
const NEON_NIGHT := Color(1.0, 0.84, 0.16)       # ...and by night: yellow light
const BLIND := 0x7d5a44             # the brown blinds
const WOOD := 0x5a3b28              # the entrance's wooden frames
const DARK := 0x33302e              # the windows' dark frames
const GLASS := 0x1f2a33             # the glass of the floors above (nothing is built behind it)
const RAIL := 0x26262a

var door: Vector2                   # before the office's door, on the avenue's pavement (the self-test)
var portal: Vector2                 # before the flats' door, on the Salvador
var agent_spot: Vector2             # behind the counter, on the map...
var agent_h := 0.0                  # ...and which way it faces (atan2(x, z) of where it looks)
var client_spot: Vector2            # before the counter
var client_h := 0.0
var desk_spots: Array = []          # Vector2: [agent_spot, client_spot] (what Sistemas's sopiss_gente.gd reads)
var clean_spots: Array = []         # Vector2: a round of the office for whoever cleans it
var floor_h := 0.0                  # the height of the office's floor, in the world
var room := PackedVector2Array()    # the office's floor, on the map
var is_open := false
var saffron_spot: Vector2
var openings := 0                   # windows and doors (the self-test)
var balconies := 0
var sign_open: Label3D              # the card on the door: ABIERTO...
var sign_shut: Label3D              # ...or CERRADO
var lamps: Array = []               # the office's lights (no shadows)
var neon := 0.0                     # how much the script name shines (0 by day ... 1 at night)
var neon_lamp: OmniLight3D          # the yellow it throws on the wall round it (no shadows)

var _lit: Array = []                # [material, its emission while the office is open, its colour then, how much of that colour is left with the lamps off]
var _inner: Array = []              # the house's ring, set in by its walls' thickness
var _un: Vector2                    # along the Salvador, from the house's west end
var _vn: Vector2                    # across the house from the Salvador, into it

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	var name_ := String(key) if key is String else ""
	if name_.begins_with("i:"):         # what is inside the office: plain colours that glow while its lamps are on
		var im := StandardMaterial3D.new()
		im.albedo_color = Parts.col(name_.substr(2).hex_to_int())
		im.roughness = 0.85
		im.emission_enabled = true
		im.emission = im.albedo_color
		im.emission_energy_multiplier = 0.0
		_lit.append([im, 0.22, im.albedo_color, DIM])
		_mats[key] = im
		return im
	match name_:
		"rojo":             # the oxblood render (Street View 2024: about 190, 85, 68 in the sun)
			m = Tex.mat("painted_plaster_wall", Color(0.83, 0.5, 0.42))
		"crema":            # the bands and frames
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.98, 0.91, 0.78)), 0.14)
		"piedra":           # the cream stone at its foot
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.93, 0.86, 0.73)), 0.12)
		"medianera":        # the bare render of the walls it shares
			m = Tex.mat("painted_plaster_wall", Color(0.8, 0.76, 0.68))
		"fucsia":           # the fascia
			var fm := StandardMaterial3D.new()
			fm.albedo_color = Color(0.8, 0.11, 0.44)
			fm.roughness = 0.5
			fm.emission_enabled = true
			fm.emission = Color(0.8, 0.11, 0.44)
			fm.emission_energy_multiplier = 0.0
			_lit.append([fm, 0.35, fm.albedo_color, 1.0])
			m = fm
		"vidrio":
			var gm := StandardMaterial3D.new()
			gm.albedo_color = Color(0.62, 0.76, 0.8, 0.2)
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.roughness = 0.06
			gm.metallic_specular = 0.8
			gm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = gm
		"esmerilado":       # the frosted window: white film on the glass
			var em := StandardMaterial3D.new()
			em.albedo_color = Color(0.86, 0.9, 0.9, 0.93)
			em.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			em.roughness = 0.6
			em.cull_mode = BaseMaterial3D.CULL_DISABLED
			em.emission_enabled = true
			em.emission = Color(0.9, 0.92, 0.88)
			em.emission_energy_multiplier = 0.0
			_lit.append([em, 0.45, em.albedo_color, 0.5])
			m = em
		"i_luz":            # the lamps in the ceiling
			var lm := StandardMaterial3D.new()
			lm.albedo_color = Color(0.86, 0.86, 0.84)
			lm.emission_enabled = true
			lm.emission = Color(1.0, 0.97, 0.9)
			lm.emission_energy_multiplier = 0.0
			_lit.append([lm, 1.8, lm.albedo_color, 0.6])
			m = lm
		"salamanquesa":     # the script name: a neon, drawn in white and coloured here (set_neon)
			var nm := StandardMaterial3D.new()
			nm.albedo_texture = load(DIR + "salamanquesa.png")
			nm.albedo_color = NEON_DAY
			nm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			nm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			nm.alpha_scissor_threshold = 0.5
			nm.roughness = 0.6
			nm.emission_enabled = true
			nm.emission = NEON_NIGHT
			nm.emission_texture = nm.albedo_texture
			nm.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			nm.emission_energy_multiplier = 0.0
			m = nm
		"rotulo", "cartel_coche", "cartel_casa", "mutua", "lista", "placa_avenida", "placa_cervantes", "valla", "logo_pared":
			var pm := StandardMaterial3D.new()
			pm.albedo_texture = load(DIR + name_ + ".png")
			pm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			pm.roughness = 0.85
			if not (name_ in ["mutua", "placa_avenida", "placa_cervantes", "valla"]):
				pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				pm.alpha_scissor_threshold = 0.5
			if name_ in ["rotulo", "logo_pared"]:      # (lit with the office)
				pm.emission_enabled = true
				pm.emission = Color.WHITE
				pm.emission_texture = pm.albedo_texture
				pm.emission_energy_multiplier = 0.0
				_lit.append([pm, 0.4 if name_ == "rotulo" else 0.12, Color.WHITE, 1.0 if name_ == "rotulo" else DIM])
			m = pm
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world, _hd: Dictionary) -> void:
	W = world
	level = MapData.height((NE + SE) / 2.0 + _outward(SE, NE) * 1.0)
	transform = Transform3D(Basis.IDENTITY, Vector3(0.0, level, 0.0))
	W.add_child(self)
	wall_top = TOP
	eave_out = EAVE
	roof_pitch = PITCH
	roof_rise0 = RISE0
	_plan()
	_east()
	_south()
	_north()
	_party()
	_roof_over([NW, NE, SE, SW, P1, P2, P3], [-EAVE, -EAVE, -EAVE, 0.0, 0.0, 0.0, 0.0])      # (four slopes: each front's, and the one that falls to the back)
	_roof_things()
	_office()
	_furniture()
	_saffron()
	home()
	_commit()
	_ring_solids([NW, NE, SE, SW, P1, P2, P3])
	_lamps()
	floor_h = level + FLOOR
	MapData.decks = [_poly_deck(room, floor_h)] + MapData.decks
	door = _along(SE, NE, 5.77) + _outward(SE, NE) * 1.3
	portal = _along(NE, NW, 14.12) + _outward(NE, NW) * 1.2
	set_open(open_at(0, 12.0))

## whether the office is open then (day: 0 Monday ... 6 Sunday)
func open_at(day: int, hour: float) -> bool:
	var d := posmod(day, 7)
	if not HOURS.has(d):
		return false
	for h in HOURS[d]:
		if hour >= float(h[0]) and hour < float(h[1]):
			return true
	return false

## Open: the lamps on, the room and the sign lit, ABIERTO on the door. Shut: the room dim, the sign unlit, CERRADO.
## (The game's own light reaches indoors by day and by night, so a room with its lamps off is drawn darker: without
## that, open and shut looked the same through the glass.)
func set_open(on: bool) -> void:
	is_open = on
	for q in _lit:
		var m := q[0] as StandardMaterial3D
		var base: Color = q[2]
		var k := 1.0 if on else float(q[3])
		m.emission_energy_multiplier = float(q[1]) if on else 0.0
		m.albedo_color = Color(base.r * k, base.g * k, base.b * k, base.a)
	for l in lamps:
		(l as Light3D).visible = on
	if sign_open != null:
		sign_open.visible = on
		sign_shut.visible = not on

## The script name's neon: 0, blue paint in daylight; 1, yellow light, and a little of it on the wall round it.
func set_neon(k: float) -> void:
	neon = clampf(k, 0.0, 1.0)
	var nm := _material("salamanquesa") as StandardMaterial3D
	nm.albedo_color = NEON_DAY.lerp(NEON_NIGHT, neon)
	nm.emission_energy_multiplier = 3.2 * neon
	if neon_lamp != null:
		neon_lamp.visible = neon > 0.02
		neon_lamp.light_energy = 0.6 * neon

func _process(_delta: float) -> void:
	var game = W.get_parent() if W != null else null
	if game != null and "clock" in game and "weekday" in game:
		var want: bool = open_at(int(game.weekday), float(game.clock))
		if want != is_open:
			set_open(want)
	var sky = game.get("sky_fx") if game != null else null          # (the neon comes on as the sky darkens, like the street's lamps)
	if sky != null and "night" in sky:
		var k := smoothstep(0.15, 0.55, float(sky.night))
		if absf(k - neon) > 0.01 or (k == 0.0) != (neon == 0.0):
			set_neon(k)

# ---------------- helpers ----------------

## a spot of the office, a along the Salvador from the house's west end and b in from that front, on the map
func _rm(a: float, b: float) -> Vector2:
	return NW + _un * a + _vn * b

## What everything else is set out from: the walls' inner line, the office's floor, the roof's slopes.
func _plan() -> void:
	_un = (NE - NW).normalized()
	_vn = Vector2(-_un.y, _un.x)
	var ring: Array = [NW, NE, SE, SW, P1, P2, P3]
	_inner = _inset(ring, [DEEP, DEEP, DEEP, 0.2, 0.2, 0.2, 0.2])
	room = _clip(PackedVector2Array(_inner), _un, NW.dot(_un) + BACK)
	var on := _outward(NE, NW)
	var oe := _outward(SE, NE)
	var os := _outward(SW, SE)
	_planes = [[on, NE.dot(on)], [oe, NE.dot(oe)], [os, SE.dot(os)], [-on, SW.dot(-on)]]      # the Salvador's, the avenue's, the Calle Cervantes's, and the one that falls to the back
	agent_spot = _rm(13.15, 3.0)
	agent_h = atan2(_un.x, _un.y)
	client_spot = _rm(15.35, 3.0)
	client_h = atan2(-_un.x, -_un.y)
	desk_spots = [agent_spot, client_spot]
	for q in [Vector2(16.0, 5.0), Vector2(12.9, 5.6), Vector2(9.3, 4.4), Vector2(6.3, 3.6), Vector2(6.4, 6.0), Vector2(11.3, 5.8)]:
		clean_spots.append(_rm(q.x, q.y))

# ---------------- what the fronts share ----------------
## the cream stone at the foot of a stretch of the front being built
func _foot(x0: float, x1: float, top := PLINTH) -> void:
	box(x0, -0.7, 0.0, x1 - x0, 0.7 + top, 0.05, "piedra")

## a cream band along the front being built (e0, e1: how much further it runs to meet the next front's)
func _band(ln: float, y0: float, y1: float, e0: float, e1: float) -> void:
	box(-e0, y0, 0.0, ln + e0 + e1, y1 - y0, 0.06, "crema")
	box(-e0, y1 - 0.05, 0.0, ln + e0 + e1, 0.05, 0.09, "crema")           # (its top course, a little prouder)

## the two bands of a front, and the frames of the openings above (holes: Rect2)
func _dress(ln: float, e0: float, e1: float, doors: Array) -> void:
	_band(ln, FASCIA1, F1, e0, e1)
	_band(ln, F1 + OPEN_H + FRAME, F2, e0, e1)
	for r: Rect2 in doors:
		box(r.position.x - FRAME, r.position.y, 0.0, FRAME, r.size.y + FRAME, 0.05, "crema")
		box(r.end.x, r.position.y, 0.0, FRAME, r.size.y + FRAME, 0.05, "crema")
		box(r.position.x, r.end.y, 0.0, r.size.x, FRAME, 0.05, "crema")

## the fascia from x0 to x1 of the front being built
func _fascia(x0: float, x1: float) -> void:
	box(x0, FASCIA0, 0.0, x1 - x0, FASCIA1 - FASCIA0, FASCIA_OUT, "fucsia")
	box(x0, FASCIA0 - 0.03, 0.0, x1 - x0, 0.03, FASCIA_OUT - 0.02, 0x8a1450)     # (its shadowed foot)

## the name on the fascia, centred on cx
func _name(cx: float, wide := 2.5) -> void:
	_picture(cx - wide / 2.0, cx + wide / 2.0, (FASCIA0 + FASCIA1) / 2.0 - wide / 8.0, (FASCIA0 + FASCIA1) / 2.0 + wide / 8.0, FASCIA_OUT + 0.014, "rotulo")

## A balcony's door in its hole: brown frame, dark glass, its brown blind down `blind` of it (1: all of it). `bars`:
## white glazing bars across the glass (the wide one over the Salvador).
func _door_up(r: Rect2, blind: float, bars := false) -> void:
	openings += 1
	var z := -DEEP + 0.08
	box(r.position.x, r.position.y, z - 0.05, r.size.x, r.size.y, 0.03, GLASS)
	var fr: int = 0xe8e4da if bars else 0x6a4a36
	for q in [[r.position.x, r.position.y, 0.07, r.size.y], [r.end.x - 0.07, r.position.y, 0.07, r.size.y], [r.position.x, r.position.y, r.size.x, 0.1], [r.position.x, r.end.y - 0.07, r.size.x, 0.07]]:
		box(q[0], q[1], z - 0.02, q[2], q[3], 0.06, fr)
	box((r.position.x + r.end.x) / 2.0 - 0.035, r.position.y, z - 0.02, 0.07, r.size.y, 0.065, fr)
	if bars:
		for k in range(1, 5):
			box(r.position.x, r.position.y + r.size.y * k / 5.0 - 0.012, z - 0.015, r.size.x, 0.024, 0.05, fr)
		for k in [0.25, 0.75]:
			box(r.position.x + r.size.x * k - 0.012, r.position.y, z - 0.015, 0.024, r.size.y, 0.05, fr)
	if blind > 0.0:
		var drop := r.size.y * blind
		var zb := -0.1                                             # (in the outer part of the reveal, over the door behind)
		box(r.position.x + 0.03, r.end.y - drop, zb, r.size.x - 0.06, drop, 0.025, BLIND)
		var n := int(drop / 0.09)
		for i in range(1, n):                                      # (its slats)
			box(r.position.x + 0.03, r.end.y - i * 0.09, zb + 0.025, r.size.x - 0.06, 0.012, 0.005, 0x654635)
		box(r.position.x + 0.03, r.end.y - drop, zb, r.size.x - 0.06, 0.04, 0.04, 0x654635)
	box(r.position.x, r.end.y - 0.2, -0.16, r.size.x, 0.2, 0.16, BLIND)      # (the blind's box, under the lintel)

## A balcony of wrought iron on the front being built: a thin dark slab on brown boards, straight bars, a band of
## crossed ones at its foot.
func _balcony(x0: float, x1: float, y: float) -> void:
	balconies += 1
	var out := BALC_OUT
	box(x0, y - 0.055, 0.0, x1 - x0, 0.07, out, 0x3c3a38)
	box(x0 + 0.03, y - 0.085, 0.0, x1 - x0 - 0.06, 0.03, out - 0.03, 0x8a5a3a)
	var z := out - 0.035
	var n := maxi(4, int((x1 - x0) / 0.115))
	for k in range(n + 1):
		box(x0 + 0.03 + (x1 - x0 - 0.06) * k / n - 0.008, y + 0.3, z - 0.008, 0.016, 0.75, 0.016, RAIL)
	box(x0 + 0.02, y + 1.03, z - 0.025, x1 - x0 - 0.04, 0.04, 0.05, RAIL)
	box(x0 + 0.02, y + 0.28, z - 0.012, x1 - x0 - 0.04, 0.024, 0.024, RAIL)
	box(x0 + 0.02, y + 0.05, z - 0.012, x1 - x0 - 0.04, 0.024, 0.024, RAIL)
	var m := maxi(3, int((x1 - x0) / 0.23))
	for k in range(m):                                             # (the band of crossed bars)
		var a := x0 + 0.03 + (x1 - x0 - 0.06) * k / m
		var b := x0 + 0.03 + (x1 - x0 - 0.06) * (k + 1) / m
		bar(Vector3(a, y + 0.06, z), Vector3(b, y + 0.28, z), 0.014, 0.014, RAIL)
		bar(Vector3(a, y + 0.28, z), Vector3(b, y + 0.06, z), 0.014, 0.014, RAIL)
	for x in [x0 + 0.03, x1 - 0.03]:                               # (its sides)
		for k in range(4):
			box(x - 0.008, y + 0.05, 0.05 + k * (out - 0.09) / 4.0, 0.016, 1.0, 0.016, RAIL)
		box(x - 0.02, y + 1.03, 0.0, 0.04, 0.04, out, RAIL)
		box(x - 0.012, y + 0.05, 0.0, 0.024, 0.024, out, RAIL)

## A shop window in its hole: the glass near the wall's face in a dark frame, a cream sill; a poster stuck inside it.
func _shop_window(r: Rect2, poster = null, at := 0.5, frosted := false) -> void:
	openings += 1
	var z := -0.12
	pieces += 1
	quad(Vector3(r.position.x, r.position.y, z), Vector3(r.end.x, r.position.y, z), Vector3(r.end.x, r.end.y, z), Vector3(r.position.x, r.end.y, z),
		"esmerilado" if frosted else "vidrio", Vector3(0, 0, 1))
	for q in [[r.position.x, r.position.y, 0.06, r.size.y], [r.end.x - 0.06, r.position.y, 0.06, r.size.y], [r.position.x, r.position.y, r.size.x, 0.06], [r.position.x, r.end.y - 0.06, r.size.x, 0.06]]:
		box(q[0], q[1], z - 0.03, q[2], q[3], 0.06, DARK)
	box(r.position.x - 0.04, r.position.y - 0.06, 0.0, r.size.x + 0.08, 0.06, 0.09, "piedra")
	if poster != null:
		var cx := r.position.x + r.size.x * at
		_picture(cx - 0.42, cx + 0.42, r.position.y + 0.55, r.position.y + 0.55 + 1.12, z - 0.012, poster)

## the inside face of the front being built, from x0 to x1 between the office's floor and its ceiling, round its openings
func _inner_face(x0: float, x1: float, holes: Array) -> void:
	var xs := [x0, x1]
	var ys := [FLOOR - 0.02, CEIL]
	for r: Rect2 in holes:
		for v in [r.position.x, r.end.x]:
			if v > x0 + 0.001 and v < x1 - 0.001:
				xs.append(v)
		for v in [r.position.y, r.end.y]:
			if v > FLOOR and v < CEIL - 0.001:
				ys.append(v)
	xs.sort()
	ys.sort()
	for i in range(xs.size() - 1):
		for j in range(ys.size() - 1):
			var c := Vector2((xs[i] + xs[i + 1]) / 2.0, (ys[j] + ys[j + 1]) / 2.0)
			var open := false
			for r: Rect2 in holes:
				if r.has_point(c):
					open = true
			if not open:
				pieces += 1
				quad(Vector3(xs[i], ys[j], -DEEP), Vector3(xs[i + 1], ys[j], -DEEP), Vector3(xs[i + 1], ys[j + 1], -DEEP), Vector3(xs[i], ys[j + 1], -DEEP), "i:ebe7dc", Vector3(0, 0, -1))

# ---------------- the front to the avenue (east) ----------------
func _east() -> void:
	var L := face(SE, NE)
	var oe := _outward(SE, NE)
	var e0 := _miter(_outward(SW, SE), oe, 1.0)          # (per metre of standing out: at the Calle Cervantes's corner...)
	var e1 := _miter(oe, _outward(NE, NW), 1.0)          # (...and at the Salvador's)
	var win := Rect2(0.7, SILL, 2.23, HEAD - SILL)
	var bay := Rect2(3.89, -0.3, 3.76, HEAD + 0.3)
	var ups: Array = []
	for f in [F1, F2]:
		ups.append(Rect2(1.38, f, 1.6, OPEN_H))
		ups.append(Rect2(5.49, f, 1.56, OPEN_H))
	masonry(0.0, L, -0.7, TOP, [win, bay] + ups, [], "rojo")
	_foot(-e0 * 0.05, win.position.x)
	_foot(win.position.x, win.end.x, SILL - 0.06)
	_foot(win.end.x, bay.position.x)
	_foot(bay.end.x, L + e1 * 0.05)
	_shop_window(win, "cartel_coche", 0.52)
	# the white panel on the pier between the window and the door
	box(win.end.x + 0.06, PLINTH, 0.0, bay.position.x - win.end.x - 0.12, HEAD - PLINTH, 0.03, 0xecece8)
	_picture(win.end.x + 0.06, bay.position.x - 0.06, PLINTH + 0.05, PLINTH + 0.05 + (bay.position.x - win.end.x - 0.12) * 2.5, 0.044, "mutua")
	_entrance(bay)
	# the street's tile, an alarm's sticker under it
	_picture(bay.end.x + 0.14, bay.end.x + 0.72, 2.5, 2.95, 0.012, "placa_avenida")
	box(bay.end.x + 0.24, 1.95, 0.0, 0.36, 0.42, 0.012, 0xe8e4dc)
	box(bay.end.x + 0.27, 2.2, 0.012, 0.3, 0.12, 0.003, 0xb4282a)
	_fascia(-e0 * FASCIA_OUT, L + e1 * FASCIA_OUT)
	_name(win.get_center().x + 0.2)
	_name(bay.get_center().x)
	_dress(L, e0 * 0.06, e1 * 0.06, ups)
	for i in range(ups.size()):
		var r: Rect2 = ups[i]
		_door_up(r, [1.0, 0.42, 0.8, 0.72][i])
		_balcony(r.position.x - 0.2, r.end.x + 0.2, r.position.y)
	_picture(4.235 - NEON_W / 2.0, 4.235 + NEON_W / 2.0, F2 + 1.78 - NEON_W / 8.0, F2 + 1.78 + NEON_W / 8.0, 0.075, "salamanquesa")      # (its tubes stand off the wall, over the frames' edges)
	for x in [4.235 - NEON_W * 0.4, 4.235, 4.235 + NEON_W * 0.4]:        # (what holds them)
		box(x - 0.012, F2 + 1.74, 0.0, 0.024, 0.024, 0.075, 0x3a3a3c)
	_eaves(L, e0 * EAVE, e1 * EAVE)
	home()
	# inside: the wall round the window and the door
	face(SE, NE)
	var x0 := ((_inner[2] as Vector2) - SE).dot((NE - SE).normalized())
	var x1 := ((_inner[1] as Vector2) - SE).dot((NE - SE).normalized())
	_inner_face(x0, x1, [win, Rect2(bay.position.x, FLOOR - 0.02, bay.size.x, HEAD - FLOOR + 0.02)])
	home()
	yard.append(_along(SE, NE, bay.position.x + 0.06) + oe * 0.32)           # (the step on the pavement: its two ends)
	yard.append(_along(SE, NE, bay.end.x - 0.06) + oe * 0.32)

## The office's entrance in its bay: two steps of cream stone, a glass pane on each side, two glazed leaves in wooden
## frames under a fanlight; the card that says whether it is open.
func _entrance(bay: Rect2) -> void:
	openings += 1
	var z := -DEEP + 0.05
	box(bay.position.x, -0.3, -DEEP, bay.size.x, 0.3 + FLOOR, DEEP, "piedra")                  # (the threshold, level with the office's floor)
	box(bay.position.x + 0.06, -0.3, 0.0, bay.size.x - 0.12, 0.3 + FLOOR / 2.0, 0.32, "piedra")      # (the step before it, on the pavement)
	var d0 := bay.position.x + 1.06                    # the door's left edge...
	var d1 := bay.end.x - 1.06                         # ...and its right one
	var top := FLOOR + 2.3                             # the leaves' top (the fanlight's foot)
	pieces += 1
	quad(Vector3(bay.position.x, FLOOR, z), Vector3(bay.end.x, FLOOR, z), Vector3(bay.end.x, HEAD, z), Vector3(bay.position.x, HEAD, z), "vidrio", Vector3(0, 0, 1))
	for x in [bay.position.x, d0 - 0.045, d1 - 0.045, bay.end.x - 0.09]:                    # (the posts)
		box(x, FLOOR, z - 0.04, 0.09, HEAD - FLOOR, 0.09, WOOD)
	box(bay.position.x, HEAD - 0.09, z - 0.04, bay.size.x, 0.09, 0.09, WOOD)
	box(d0, top, z - 0.04, d1 - d0, 0.08, 0.09, WOOD)
	for x in [bay.position.x, d1]:                     # (the side panes' foot)
		box(x, FLOOR, z - 0.04, d0 - bay.position.x, 0.14, 0.085, WOOD)
	var mid := (d0 + d1) / 2.0
	for k in range(2):                                 # (the two leaves: stiles, rails, a steel handle)
		var a := d0 + 0.045 if k == 0 else mid + 0.01
		var b := mid - 0.01 if k == 0 else d1 - 0.045
		box(a, FLOOR + 0.01, z - 0.02, 0.08, top - FLOOR - 0.01, 0.06, WOOD)
		box(b - 0.08, FLOOR + 0.01, z - 0.02, 0.08, top - FLOOR - 0.01, 0.06, WOOD)
		box(a, FLOOR + 0.01, z - 0.02, b - a, 0.22, 0.06, WOOD)
		box(a, top - 0.1, z - 0.02, b - a, 0.1, 0.06, WOOD)
		var hx := b - 0.13 if k == 0 else a + 0.11
		box(hx, FLOOR + 0.95, z + 0.04, 0.025, 0.45, 0.025, 0xb8b8b4)
		box(hx, FLOOR + 0.98, z + 0.0, 0.025, 0.025, 0.05, 0xb8b8b4)
		box(hx, FLOOR + 1.34, z + 0.0, 0.025, 0.025, 0.05, 0xb8b8b4)
	_picture(d1 + 0.2, d1 + 0.2 + 0.72, FLOOR + 0.75, FLOOR + 0.75 + 0.72 * 1.6, z + 0.014, "lista")
	# the card hanging in the left leaf
	box(mid - 0.62, FLOOR + 1.42, z + 0.012, 0.44, 0.2, 0.006, 0xf4f2ea)
	sign_open = _text("ABIERTO", Vector3(mid - 0.4, FLOOR + 1.52, z + 0.022), 44, 0x1f7a3a, 0.0019)
	sign_shut = _text("CERRADO", Vector3(mid - 0.4, FLOOR + 1.52, z + 0.022), 44, 0xb4282a, 0.0019)
	for l: Label3D in [sign_open, sign_shut]:
		l.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	# the mat inside
	box(d0, FLOOR, -DEEP - 1.25, d1 - d0, 0.015, 1.1, "i:4a4a4e")

# ---------------- the front to the Calle Cervantes (south) ----------------
func _south() -> void:
	var L := face(SW, SE)
	var e1 := _miter(_outward(SW, SE), _outward(SE, NE), 1.0)
	var win := Rect2(2.19, 1.0, 2.31, HEAD - 1.0)
	var ups: Array = [Rect2(2.5, F1, 1.2, OPEN_H), Rect2(2.5, F2, 1.2, OPEN_H)]
	masonry(0.0, L, -0.7, TOP, [win] + ups, [], "rojo")
	_foot(0.0, win.position.x, 1.0)
	_foot(win.position.x, win.end.x, 0.94)
	_foot(win.end.x, L + e1 * 0.05, 1.0)
	_shop_window(win, "cartel_casa", 0.42)
	_picture(win.end.x + 0.07, win.end.x + 0.57, 2.5, 2.89, 0.012, "placa_cervantes")
	_fascia(0.0, L + e1 * FASCIA_OUT)
	_name(2.45, 2.3)
	_dress(L, 0.0, e1 * 0.06, ups)
	_door_up(ups[0], 0.5)
	_door_up(ups[1], 0.62)
	for r: Rect2 in ups:
		_balcony(r.position.x - 0.2, r.end.x + 0.2, r.position.y)
	_eaves(L, 0.0, e1 * EAVE)
	home()
	face(SW, SE)
	var d := (SE - SW).normalized()
	_inner_face(((_inner[3] as Vector2) - SW).dot(d), ((_inner[2] as Vector2) - SW).dot(d), [win])
	home()

# ---------------- the front to the Calle del Salvador (north) ----------------
func _north() -> void:
	var L := face(NE, NW)
	var e0 := _miter(_outward(SE, NE), _outward(NE, NW), 1.0)
	var corner := Rect2(1.25, 0.9, 2.16, HEAD - 0.9)             # the window by the corner, under the fascia's end
	var big := Rect2(4.63, 0.9, 3.33, 2.05)                     # the big one
	var frost := Rect2(8.93, 0.9, 2.66, 2.05)                   # the frosted one
	var gate := Rect2(13.45, -0.5, 1.34, 3.1)                   # the flats' door
	var doors: Array = []
	var wins: Array = []
	for f in [F1, F2]:
		doors.append(Rect2(1.73, f, 1.2, OPEN_H))
		wins.append(Rect2(4.98, f + 0.75, 0.9, 1.45))             # (the barred window)
		wins.append(Rect2(7.5, f + 1.72, 0.46, 0.46))             # (the little square one)
		doors.append(Rect2(9.03, f, 1.6, OPEN_H))
		doors.append(Rect2(12.72, f, 1.3, OPEN_H))
	masonry(0.0, L, -0.9, TOP, [corner, big, frost, gate] + doors + wins, [], "rojo")
	var cuts := [0.0 - e0 * 0.05, corner.position.x, corner.end.x, big.position.x, big.end.x, frost.position.x, frost.end.x, gate.position.x - 0.16]
	for i in range(0, cuts.size(), 2):
		_foot(cuts[i], cuts[i + 1], 0.9)
	for r: Rect2 in [corner, big, frost]:
		box(r.position.x, -0.9, 0.0, r.size.x, 0.9 + 0.84, 0.05, "piedra")
	_foot(gate.end.x + 0.16, L, 0.9)
	_shop_window(corner, "cartel_casa", 0.5)
	_shop_window(big, "cartel_coche", 0.3)
	_shop_window(frost, null, 0.5, true)
	_gate(gate)
	_fascia(-e0 * FASCIA_OUT, 3.55)
	_name(1.72, 2.3)
	_dress(L, e0 * 0.06, 0.0, doors)
	var blinds := [0.35, 0.0, 0.9, 0.55, 0.3, 0.8]
	for i in range(doors.size()):
		var r: Rect2 = doors[i]
		_door_up(r, blinds[i], i == 1)
		_balcony(r.position.x - 0.22, r.end.x + 0.22, r.position.y)
	for i in range(wins.size()):
		var r: Rect2 = wins[i]
		openings += 1
		if i % 2 == 0:                                            # (barred: brown frame, an iron cage, a cream frame all round)
			window(r, 0x6a4a36, GLASS, 2)
			grille(r, 0.14, RAIL)
			stone_frame(r, 0.17, 0.05, "crema")
		else:                                                     # (the little one: a lattice of red clay)
			box(r.position.x, r.position.y, -DEEP + 0.03, r.size.x, r.size.y, 0.03, GLASS)
			for k in [0.0, 0.5, 1.0]:
				box(r.position.x + (r.size.x - 0.06) * k, r.position.y, -0.14, 0.06, r.size.y, 0.06, 0xa8503c)
				box(r.position.x, r.position.y + (r.size.y - 0.06) * k, -0.14, r.size.x, 0.06, 0.06, 0xa8503c)
			stone_frame(r, 0.08, 0.04, "crema")
	# the black cable under the band, its clips; the meter's box and the drainpipe at the west end
	var cy := FASCIA1 - 0.08
	for k in range(12):
		var xa := 3.6 + (L - 3.7) * k / 12.0
		var xb := 3.6 + (L - 3.7) * (k + 1) / 12.0
		bar(Vector3(xa, cy - 0.05 * sin(PI * (k % 3) / 3.0), 0.035), Vector3(xb, cy - 0.05 * sin(PI * ((k % 3) + 1) / 3.0), 0.035), 0.03, 0.03, 0x1a1a1c)
	box(15.15, 2.45, 0.0, 0.5, 0.75, 0.2, 0xe6e4de)
	box(15.19, 2.5, 0.2, 0.42, 0.65, 0.006, 0xd2d0c8)
	for q in [[15.3, 2.2], [15.42, 2.05]]:
		box(q[0], q[1], 0.0, 0.035, 2.45 - float(q[1]), 0.04, 0x2a2a2c)
	drum(Vector3(L - 0.22, -0.9, 0.07), 0.05, 0.05, TOP + 0.9, 0x9a5a40, 8)
	box(L - 0.3, TOP - 0.25, 0.0, 0.16, 0.22, 0.16, 0x9a5a40)
	_eaves(L, e0 * EAVE, 0.0)
	home()
	face(NE, NW)
	var d := (NW - NE).normalized()
	_inner_face(((_inner[1] as Vector2) - NE).dot(d), L - BACK, [corner, big, frost])
	home()

## The flats' door on the Salvador: black wrought iron over dark glass, a step of cream stone, stone at the jambs' feet.
func _gate(r: Rect2) -> void:
	openings += 1
	var g := ground(_along(NE, NW, r.get_center().x).x + _outward(NE, NW).x * 0.4, _along(NE, NW, r.get_center().x).y + _outward(NE, NW).y * 0.4)
	var sill := g + 0.14
	box(r.position.x, -0.9, -DEEP, r.size.x, 0.9 + sill, DEEP, "piedra")
	var z := -DEEP + 0.1
	box(r.position.x, sill, z - 0.06, r.size.x, r.end.y - sill, 0.04, 0x14161a)
	for q in [[r.position.x, 0.08], [r.end.x - 0.08, 0.08], [r.get_center().x - 0.03, 0.06]]:
		box(q[0], sill, z - 0.03, q[1], r.end.y - sill, 0.07, 0x1e1c1c)
	box(r.position.x, r.end.y - 0.08, z - 0.03, r.size.x, 0.08, 0.07, 0x1e1c1c)
	box(r.position.x, sill + 2.12, z - 0.03, r.size.x, 0.06, 0.07, 0x1e1c1c)                  # (the fanlight's foot)
	box(r.position.x, sill, z - 0.03, r.size.x, 0.42, 0.06, 0x1e1c1c)                         # (the kick plates)
	for k in range(2):
		var a := r.position.x + 0.1 + k * (r.size.x / 2.0 - 0.03)
		var b := a + r.size.x / 2.0 - 0.17
		for i in range(6):                                                                    # (the bars of each leaf)
			box(lerpf(a, b, (i + 0.5) / 6.0) - 0.011, sill + 0.42, z, 0.022, 1.7, 0.022, 0x2c2a2a)
		box(a, sill + 1.25, z + 0.005, b - a, 0.03, 0.02, 0x2c2a2a)
		box(lerpf(a, b, 0.9 if k == 0 else 0.1) - 0.02, sill + 1.0, z + 0.025, 0.04, 0.16, 0.03, 0xb49a4a)      # (a brass handle)
	for x in [r.position.x - 0.16, r.end.x]:
		box(x, -0.9, 0.0, 0.16, 0.9 + sill + 0.55, 0.07, "piedra")
	box(r.position.x - 0.42, 1.25, 0.0, 0.14, 0.24, 0.02, 0xb8b8b4)                           # (the entry phone)

# ---------------- the walls it shares ----------------

func _party() -> void:
	_party_wall(SW, P1)
	_party_wall(P1, P2)
	_party_wall(P2, P3)
	_party_wall(P3, NW)

# ---------------- the roof ----------------

## the chimney of red brick, and the old hoarding on its steel frame, facing the Calle de Santa Ana
func _roof_things() -> void:
	home()
	var c := Vector2(105.7, 69.5)
	var y := _roof_y(c)
	box(c.x - 0.3, y - 0.4, c.y - 0.3, 0.6, 1.75, 0.6, "brick")
	box(c.x - 0.36, y + 1.35, c.y - 0.36, 0.72, 0.08, 0.72, 0x8a6a58)
	box(c.x - 0.24, y + 1.43, c.y - 0.24, 0.48, 0.2, 0.48, 0x5a4a44)
	box(c.x - 0.34, y + 1.63, c.y - 0.34, 0.68, 0.06, 0.68, 0x8a6a58)
	face(SE, NE)
	var oe := _outward(SE, NE)
	var zb := -5.3                                       # (how far behind the avenue's front it stands)
	var x0 := 2.7
	var x1 := 7.7
	var foot := ridge_top + 0.35
	box(x0, foot, zb - 0.03, x1 - x0, 1.25, 0.06, 0x8a8f96)
	_picture(x0, x1, foot, foot + 1.25, zb + 0.044, "valla")
	for k in range(4):
		var x := lerpf(x0 + 0.15, x1 - 0.15, k / 3.0)
		var p := _along(SE, NE, x) + oe * (zb - 0.1)
		var q := _along(SE, NE, x) + oe * (zb - 1.7)
		box(x - 0.04, _roof_y(p) - 0.1, zb - 0.14, 0.08, foot + 1.25 - _roof_y(p) + 0.1, 0.08, 0x5c6168)
		bar(Vector3(x, foot + 1.1, zb - 0.1), Vector3(x, _roof_y(q), zb - 1.7), 0.05, 0.05, 0x5c6168)
	for yy in [foot + 0.1, foot + 1.15]:
		box(x0, yy, zb - 0.1, x1 - x0, 0.05, 0.05, 0x5c6168)
	home()

# ---------------- the office ----------------
## Its floor, its ceiling and the lamps in it, the walls it has of its own (the shared ones, and the one at its back).
func _office() -> void:
	home()
	flat(room, FLOOR, "i:b9b4a9")
	_flat_down(room, CEIL, "i:f6f5f1")
	var n := room.size()
	for i in range(n):
		var a := room[i]
		var b := room[(i + 1) % n]
		var mid := (a + b) / 2.0
		var street := false                                  # (the fronts' own inside faces are built with them)
		for e in [[NE, NW], [SE, NE], [SW, SE]]:
			var o := _outward(e[0], e[1])
			if absf((mid - (e[0] as Vector2)).dot(o) + DEEP) < 0.02:
				street = true
		if street or a.distance_to(b) < 0.02:
			continue
		var ln := face(a, b)
		pieces += 1
		quad(Vector3(0, FLOOR - 0.02, 0), Vector3(ln, FLOOR - 0.02, 0), Vector3(ln, CEIL, 0), Vector3(0, CEIL, 0), "i:ebe7dc", Vector3(0, 0, 1))
		box(0.0, FLOOR, 0.0, ln, 0.09, 0.015, "i:8a8a8e")                                     # (its skirting)
		home()
	# the lamps: panels in the ceiling
	face(NW, NE)
	for a in [6.0, 8.6, 11.2, 13.8, 16.4]:
		for b in [2.0, 4.6, 7.0]:
			var ok := true
			for q in [Vector2(-0.7, -0.4), Vector2(0.7, -0.4), Vector2(0.7, 0.4), Vector2(-0.7, 0.4)]:
				if not Geometry2D.is_point_in_polygon(_rm(a + q.x, b + q.y), room):
					ok = false
			if ok:
				box(a - 0.6, CEIL - 0.04, b - 0.3, 1.2, 0.025, 0.6, "i_luz")
				box(a - 0.63, CEIL - 0.03, b - 0.33, 1.26, 0.03, 0.66, "i:d8d8d4")
	home()

## What stands in it, in the frame of the Salvador's front seen from inside (x: along it from the house's west end; z:
## in from it). Nobody is made here: the people are Sistemas's.
func _furniture() -> void:
	face(NW, NE)
	var f := FLOOR
	# the partition with the name, behind the counter
	box(12.3, f, 1.3, 0.12, 2.35, 3.4, "i:f4f2ec")
	box(12.29, f + 0.01, 1.29, 0.14, 0.12, 3.42, "i:cc1c70")
	pieces += 1
	quad(Vector3(12.434, f + 1.25, 4.2), Vector3(12.434, f + 1.25, 1.8), Vector3(12.434, f + 2.05, 1.8), Vector3(12.434, f + 2.05, 4.2), "logo_pared", Vector3(1, 0, 0),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	# the counter: white, its front magenta, a grey top; a screen, a tray of leaflets
	box(13.9, f, 1.8, 0.55, 1.02, 2.4, "i:f4f2ec")
	box(14.45, f + 0.1, 1.8, 0.025, 0.84, 2.4, "i:cc1c70")
	box(13.85, f + 1.02, 1.75, 0.68, 0.04, 2.5, "i:a9a7a2")
	_screen(Vector3(14.05, f + 1.06, 3.55), -PI / 2.0)
	box(14.2, f + 1.06, 2.05, 0.24, 0.03, 0.34, "i:5a5a5e")
	for k in range(3):
		box(14.22, f + 1.09, 2.07 + k * 0.105, 0.2, 0.012 + k * 0.004, 0.09, ["i:cc1c70", "i:f4f2ec", "i:3a6ab0"][k])
	# desks: by the big window, behind the frosted one, by the wall at the back
	_desk(9.0, 1.0, false)
	_desk(5.6, 1.0, false)
	_desk(7.0, 7.3, true)
	# filing cabinets against the back wall, a door in it
	for k in range(3):
		box(BACK + 0.02, f, 1.0 + k * 0.82, 0.48, 1.95, 0.8, "i:9da0a4")
		box(BACK + 0.5, f + 0.08, 1.02 + k * 0.82, 0.01, 1.8, 0.76, "i:8a8d92")
		box(BACK + 0.51, f + 0.95, 1.36 + k * 0.82, 0.02, 0.2, 0.03, "i:55585c")
	box(BACK + 0.005, f, 4.5, 0.04, 2.05, 0.9, "i:e0dbd0")
	box(BACK + 0.045, f + 1.0, 5.25, 0.04, 0.03, 0.12, "i:8a8a8e")
	# a plant in the corner by the Salvador's window
	drum(Vector3(15.5, f, 1.0), 0.19, 0.24, 0.42, "i:b0623a", 10)
	for q in [Vector3(0.0, 0.95, 0.0), Vector3(0.18, 0.75, 0.1), Vector3(-0.16, 0.8, -0.1), Vector3(0.05, 1.25, -0.08), Vector3(-0.1, 1.1, 0.14)]:
		ball(Vector3(15.5, f, 1.0) + q, 0.27, "i:3f7a3a", 1.25, 8, 5)
	drum(Vector3(15.5, f + 0.4, 1.0), 0.03, 0.03, 0.5, "i:5a4630", 6)
	home()
	# the row of blue chairs with their backs to the avenue's window, a low table beside them
	face(SE, NE)
	var z0 := -DEEP - 0.2
	for k in range(4):
		var x := 0.82 + k * 0.56
		box(x, FLOOR + 0.4, z0 - 0.5, 0.5, 0.06, 0.48, "i:2f5fb0")
		box(x, FLOOR + 0.46, z0 - 0.07, 0.5, 0.42, 0.06, "i:2f5fb0")
	box(0.8, FLOOR + 0.3, z0 - 0.42, 2.2, 0.05, 0.05, "i:55585c")
	for x in [0.9, 2.85]:
		box(x, FLOOR, z0 - 0.45, 0.05, 0.32, 0.4, "i:55585c")
	home()

## a desk in the office's frame (its left, front corner; `turned`: whoever works at it sits on its far side): a pale
## top on panels, a screen, a keyboard, papers, an office chair
func _desk(a: float, b: float, turned: bool) -> void:
	var f := FLOOR
	box(a, f + 0.72, b, 1.6, 0.035, 0.8, "i:e6e1d6")
	box(a + 0.02, f, b + 0.03, 0.035, 0.72, 0.74, "i:c8c3b8")
	box(a + 1.545, f, b + 0.03, 0.035, 0.72, 0.74, "i:c8c3b8")
	box(a + 0.02, f + 0.25, b + (0.74 if turned else 0.03), 1.56, 0.47, 0.03, "i:c8c3b8")
	_screen(Vector3(a + 0.8, f + 0.755, b + (0.58 if turned else 0.22)), PI if turned else 0.0)
	box(a + 0.58, f + 0.757, b + (0.2 if turned else 0.48), 0.44, 0.018, 0.14, "i:3a3a3e")
	box(a + 1.15, f + 0.757, b + 0.3, 0.26, 0.012, 0.34, "i:f8f8f4")
	var cz := b - 0.5 if turned else b + 1.3
	drum(Vector3(a + 0.8, f, cz), 0.26, 0.26, 0.04, "i:2a2a2e", 8)
	drum(Vector3(a + 0.8, f + 0.04, cz), 0.03, 0.03, 0.4, "i:6a6a6e", 6)
	box(a + 0.57, f + 0.44, cz - 0.23, 0.46, 0.07, 0.46, "i:2c3a52")
	box(a + 0.58, f + 0.5, cz + (-0.25 if turned else 0.19), 0.44, 0.5, 0.06, "i:2c3a52")

## a flat screen on its foot, at `at` (the middle of its foot), turned `yaw` about the upright
func _screen(at: Vector3, yaw: float) -> void:
	var keep := _xf
	_xf = keep * Transform3D(Basis(Vector3.UP, yaw), at)
	box(-0.1, 0.0, -0.07, 0.2, 0.015, 0.14, "i:2a2a2e")
	box(-0.02, 0.0, -0.02, 0.04, 0.16, 0.03, "i:2a2a2e")
	box(-0.26, 0.12, 0.0, 0.52, 0.32, 0.025, "i:1c1c20")
	box(-0.24, 0.14, 0.025, 0.48, 0.28, 0.003, "i:9ec4e8")
	_xf = keep

## the office's lights: two, with no shadows, on only while it is open
func _lamps() -> void:
	for q in [Vector2(14.6, 3.6), Vector2(9.2, 4.2)]:
		var p := _rm(q.x, q.y)
		var l := OmniLight3D.new()
		l.position = Vector3(p.x, CEIL - 0.5, p.y)
		l.omni_range = 7.0
		l.light_energy = 0.7
		l.light_color = Color(1.0, 0.96, 0.88)
		l.shadow_enabled = false
		l.visible = false
		add_child(l)
		lamps.append(l)
	var at := _along(SE, NE, 4.235) + _outward(SE, NE) * 1.0         # (before the script name, up between the top balconies)
	neon_lamp = OmniLight3D.new()
	neon_lamp.position = Vector3(at.x, F2 + 1.78, at.y)
	neon_lamp.omni_range = 4.5
	neon_lamp.omni_attenuation = 1.0
	neon_lamp.light_energy = 0.0
	neon_lamp.light_color = NEON_NIGHT
	neon_lamp.shadow_enabled = false
	neon_lamp.visible = false
	add_child(neon_lamp)

# ---------------- the saffron ----------------
## A saffron flower in a little pot of clay, on the step of the flats' doorway, against its jamb (the user: hide saffron
## in special places). The flower is the game's to take away; the pot stays.
func _saffron() -> void:
	home()
	var at := _along(NE, NW, 14.62) + _outward(NE, NW) * -0.1
	var g := MapData.height(_along(NE, NW, 14.12) + _outward(NE, NW) * 0.4) - level + 0.14
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
		(game.flowers as Array).append({"node": flower, "p": saffron_spot, "id": "sopiss", "hidden": true})      # (hidden: Sistemas keeps count of these)
