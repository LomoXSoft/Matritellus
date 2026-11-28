extends "res://scripts/obra.gd"
## The Vivero de Empresas of the Avenida de la Reina Sofía (the user, 27 November 2026, with a photograph of its
## front: "Ponte ahora con el Vivero de empresas. Que se pueda pasar y tenga horario"), built by hand on Texturas's
## house of the map rsof_10 (handed over as ["obra"] in casas_calles.gd); referencias/vivero/, tools/vivero/. The old
## health centre of the town (Catastro 4090017VJ5649S, two floors), wrapped about 2014 in a second skin of pale brick
## laid as a lattice, like the cane baskets the bottles were cooled in. Measures: the user's photograph (straight at
## the front) and a photosphere of February 2020 (Google Maps); the architects' published photographs for its inside.
##
## The front (from its west end, the left seen from the street):
##   - the lattice, the whole front, its top in three: lower over the west part (7.23 m), a step up (7.55 m), then
##     a soft fall to the east end (6.93 m). Its holes small and close over most of it, bigger and in a chequer in the
##     band over the gate and before the way in (the porch behind them, lit, shows through);
##   - the blue gate at the west end, VIVE over RO in tall letters and the town's name up its edge (puerta.png): the
##     way in. Open in its hours, swung in against the porch's wall; behind it the porch and the glass doors of the
##     hall. The two white plates by it, the name and the hours;
##   - a thin canopy with a blue edge across the middle, blue tiles in the holes over it;
##   - over the canopy, a window in a navy frame; under it, along the east part, the band of the ground floor's
##     windows, white frosted panes between blue panels, the last pane dark, a long blue panel at the end;
##   - behind the lattice, the old front, white; two of its windows show through the holes;
##   - before it, on the pavement, the sign of the bay for disabled drivers and a young tree by the east end.
## Hours (Google Maps): Monday to Friday 9:00-14:00; shut at the weekend. Its inside is a set of its own
## (vivero_dentro.gd), walked into by the green arrow before the gate (entradas.gd) while it is open.
##
## Frame: origin at the front's west end, on the party wall with rsof_12; +x along the front (to the east), +z out of
## it, towards the street; y = 0 the porch's floor.

const DentroS = preload("res://scripts/vivero_dentro.gd")

const READY := true
const HOUSE := "rsof_10"
const DIR := "res://assets/vivero/"
const NAME := "Vivero de Empresas"
const SHIFT := 0.49                                     # the front's west end is this far before the house's o
const L := 11.85
const T := 0.12                                         # how thick the lattice is
const BACK := 0.45                                      # the old front, this far behind it
const GATE := Rect2(0.5, 0.0, 2.0, 2.05)                # the way in
const PORCH := Rect2(0.35, -2.2, 4.79, 2.08)            # the porch behind the lattice (x, z: from 0.35 to 5.14, from -2.2 to -0.12; the gate's leaf, 1.9 m, swung in along its side)
const PORCH_H := 2.95
const DOORS := Rect2(0.75, 0.0, 1.5, 2.4)               # the hall's glass doors, at the porch's back, before the gate
const OPEN := Rect2(0.3, 0.0, 4.84, 2.95)               # where the lattice lets more through (the gate cut out of it)
const OPENS := [OPEN, Rect2(0.56, 4.06, 2.57, 1.21), Rect2(9.64, 4.06, 0.82, 0.99), Rect2(3.26, 3.0, 5.89, 0.3)]   # ...and before the two windows behind, and the band of blue tiles over the canopy (the photograph)
const TILE := Vector2(0.4, 0.3)                         # the lattice's pictures: how much of it each is (tools/vivero/dibujos.py)
const BAND := Rect2(5.14, 0.72, 6.67, 1.2)              # the ground floor's windows
const UPPER := Rect2(4.8, 4.19, 1.75, 1.21)             # the window over the canopy
const BEHIND := [Rect2(0.56, 4.06, 2.57, 1.21), Rect2(9.64, 4.06, 0.82, 0.99)]   # the old front's windows, seen through the holes
const CANOPY := [3.26, 9.15, 3.05, 2.85, 0.75]          # from x, to x, its top at each end, how far out
const TOP := [[0.0, 7.23], [3.21, 7.23], [3.21, 7.55], [7.47, 7.55], [9.11, 6.93], [L, 6.93]]   # the lattice's top (x, y)
const FLAT := 6.6                                       # the roof behind
const PLATES := Rect2(2.56, 1.3, 0.36, 0.4)             # the two plates by the gate
const VENT := Rect2(10.85, 0.2, 0.35, 0.26)
const HOURS := {0: [Vector2(9.0, 14.0)], 1: [Vector2(9.0, 14.0)], 2: [Vector2(9.0, 14.0)], 3: [Vector2(9.0, 14.0)],
	4: [Vector2(9.0, 14.0)]}                            # the day (0 Monday ... 6 Sunday) and from when to when
const NAVY := 0x1a288c
const BLUE := 0x2436a8
const BRICK_EDGE := 0xf2ceb0

var EU := Vector2(0.9354, 0.3537)
var EV := Vector2(-0.3537, 0.9354)
var A := Vector2(-245.47, 221.13)
var outline: Array = []                                 # the house's outline, in the frame
var door: Vector2                                       # before the gate, on the pavement (the self-test)
var dentro                                              # its inside (vivero_dentro.gd)
var is_open := false
var gate_y := 0.0                                       # the gate's sill and the porch's floor, over the house's own (below zero: the avenue falls to the west)
var _holes: Array = []                                  # the openings in the lattice: the gate at its own height, the windows
var _opens: Array = []                                  # where the lattice is the open one
var openings := 0
var lattice_m2 := 0.0                                   # how much lattice it has (the self-test)
var _shut: Node3D
var _lit: Node3D
var _leaf_shut: Node3D
var _leaf_open: Node3D

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"celosia", "celosia_abierta":       # the lattice: its holes see-through (tools/vivero/dibujos.py)
			var cm := StandardMaterial3D.new()
			cm.albedo_texture = load(DIR + String(key) + ".png")
			cm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			cm.alpha_scissor_threshold = 0.5
			cm.roughness = 0.95
			cm.metallic_specular = 0.2
			m = cm
		"puerta":                           # the gate's sheet, its letters and its holes
			var pm := StandardMaterial3D.new()
			pm.albedo_texture = load(DIR + "puerta.png")
			pm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			pm.alpha_scissor_threshold = 0.5
			pm.roughness = 0.5
			pm.metallic = 0.3
			m = pm
		"placas", "minusvalidos":
			var sm := StandardMaterial3D.new()
			sm.albedo_texture = load(DIR + String(key) + ".png")
			sm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			sm.roughness = 0.6
			sm.metallic_specular = 0.2
			m = sm
		"revoco":           # the old front and the walls behind: white render
			m = _glow(Tex.mat("painted_plaster_wall", Color(0.97, 0.96, 0.93)), 0.05)
		"detras":           # the old front behind the lattice, in its shade: what the holes show
			m = Tex.mat("painted_plaster_wall", Color(0.6, 0.58, 0.55))
		"azotea":
			m = Tex.mat("granular_concrete", Color(0.7, 0.68, 0.64))
		"suelo":            # the porch's floor: pale grey tiles
			m = Tex.mat("granular_concrete", Color(0.8, 0.8, 0.78))
		"esmerilado":       # the frosted white panes: lit from inside in its hours
			var em := StandardMaterial3D.new()
			em.albedo_color = Color(0.9, 0.92, 0.93)
			em.roughness = 0.3
			em.emission_enabled = true
			em.emission = Color(1.0, 0.98, 0.92)
			em.emission_energy_multiplier = 0.05
			m = em
		"oscuro":           # the dark pane
			var om := StandardMaterial3D.new()
			om.albedo_color = Color(0.12, 0.14, 0.17)
			om.roughness = 0.08
			om.metallic = 0.4
			m = om
		"vidrio":           # the hall's glass doors
			var vm := StandardMaterial3D.new()
			vm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			vm.albedo_color = Color(0.55, 0.62, 0.66, 0.25)
			vm.roughness = 0.1
			vm.metallic_specular = 0.7
			m = vm
		"vestibulo":        # the hall seen through them: white, lit in its hours
			var hm := StandardMaterial3D.new()
			hm.albedo_color = Color(0.92, 0.92, 0.9)
			hm.emission_enabled = true
			hm.emission = Color(1.0, 0.98, 0.94)
			hm.emission_energy_multiplier = 0.05
			m = hm
		"luz":              # the porch's lamp
			var lm := StandardMaterial3D.new()
			lm.albedo_color = Color(1.0, 0.97, 0.9)
			lm.emission_enabled = true
			lm.emission = Color(1.0, 0.95, 0.85)
			lm.emission_energy_multiplier = 0.2
			m = lm
		_:
			return super(key)
	_mats[key] = m
	return m

## its house of the map, if Texturas has handed it over (or empty)
## (`anyway`: the house as it is even if not handed over yet -- the self-test's --vivero, to see it before then)
static func handed_over(anyway := false) -> Dictionary:
	var short = preload("res://scripts/casas_calles.gd").HOUSES
	for hd in MapData.houses:
		if String(hd["id"]) == HOUSE:
			var line = short.get(HOUSE, [])
			if anyway or (line is Array and (line as Array).size() == 1 and String(line[0]) == "obra"):
				return hd
			return {}
	return {}

func build(world, hd: Dictionary) -> void:
	W = world
	EU = Vector2(hd["u"][0], hd["u"][1]).normalized()
	EV = Vector2(-EU.y, EU.x)
	A = Vector2(hd["o"][0], hd["o"][1]) - EU * SHIFT
	var r: Array = hd["pieces"][0]["ring"]
	outline.clear()
	for i in range(0, r.size(), 2):
		outline.append(to_uv(Vector2(r[i], r[i + 1])))
	# its floor: the house's (the pavement's at its east end). The avenue falls from there to the gate, a metre and
	# more with the relief as the game has it: the gate and its porch have a floor of their own, the pavement's there
	level = float(hd.get("base", MapData.height(map_at(L / 2.0, 0.2))))
	transform = Transform3D(Basis(Vector3(EU.x, 0, EU.y), Vector3.UP, Vector3(EV.x, 0, EV.y)), Vector3(A.x, level, A.y))
	W.add_child(self)
	gate_y = -INF
	for k in range(5):
		gate_y = maxf(gate_y, ground(lerpf(GATE.position.x, GATE.end.x, k / 4.0), 0.1))
	gate_y = minf(gate_y + 0.04, 0.0)
	_holes = [Rect2(GATE.position.x, gate_y, GATE.size.x, GATE.size.y), BAND, UPPER]
	_opens = OPENS.duplicate()
	_opens[0] = Rect2(OPEN.position.x, gate_y - 1.5, OPEN.size.x, OPEN.end.y - gate_y + 1.5)
	door = spot(GATE.get_center().x, 0.9)
	_lattice()
	_gate_and_porch()
	_windows()
	_canopy()
	_old_front()
	_body()
	_street()
	home()
	_commit()
	_states()
	_solids_all()
	dentro = DentroS.new()                          # (its door in the gate: the arrow stands before it)
	dentro.build(world, spot(GATE.get_center().x, 0.5), spot(GATE.get_center().x, 1.9), atan2(EV.x, EV.y))
	set_open(open_at(0, 10.0))

func map_at(u: float, v: float) -> Vector2:
	return A + EU * u + EV * v

func to_uv(p: Vector2) -> Vector2:
	var d := p - A
	return Vector2(d.dot(EU), d.dot(EV))

func open_at(day: int, hour: float) -> bool:
	var d := posmod(day, 7)
	if not HOURS.has(d):
		return false
	for h: Vector2 in HOURS[d]:
		if hour >= h.x and hour < h.y:
			return true
	return false

## how high the lattice's top is at x
static func top_at(x: float) -> float:
	for i in range(TOP.size() - 1):
		var a: Array = TOP[i]
		var b: Array = TOP[i + 1]
		if x <= float(b[0]) and float(b[0]) > float(a[0]):
			var k := clampf((x - float(a[0])) / (float(b[0]) - float(a[0])), 0.0, 1.0)
			if i == 3:                                  # (the soft fall: an S, not a straight slope)
				k = k * k * (3.0 - 2.0 * k)
			return lerpf(float(a[1]), float(b[1]), k)
	return float(TOP[TOP.size() - 1][1])

# ---------------- the lattice ----------------
## what the lattice is at a spot of the front: "" a hole (gate, windows), else its kind
func _kind(x: float, y: float) -> String:
	for h: Rect2 in _holes:
		if h.has_point(Vector2(x, y)):
			return ""
	for o: Rect2 in _opens:
		if o.has_point(Vector2(x, y)):
			return "celosia_abierta"
	return "celosia"

## The whole front as a lattice: strips of it no wider than a quarter metre (so that its top follows the curve), each
## cut where an opening or the open band begins and ends; a face to the street and one to the old front behind, the
## same picture on both; its thickness shown round the openings and along its top.
func _lattice() -> void:
	home()
	var xs: Array = [0.0, L]
	for h: Rect2 in _holes + _opens:
		xs.append(h.position.x)
		xs.append(h.end.x)
	for p in TOP:
		xs.append(float(p[0]))
	var cuts: Array = []
	xs.sort()
	for i in range(xs.size() - 1):
		var a: float = xs[i]
		var b: float = xs[i + 1]
		if b - a < 0.005:
			continue
		var n := maxi(1, ceili((b - a) / 0.25))
		for k in range(n):
			cuts.append([lerpf(a, b, float(k) / n), lerpf(a, b, float(k + 1) / n)])
	for c in cuts:
		var x0: float = c[0]
		var x1: float = c[1]
		var mx := (x0 + x1) / 2.0
		var t0 := top_at(x0)
		var t1 := top_at(x1)
		var ys: Array = [ground(mx, 0.05) - 0.3]
		for h: Rect2 in _holes + _opens:
			if mx > h.position.x and mx < h.end.x:
				ys.append(h.position.y)
				ys.append(h.end.y)
		ys.sort()
		var runs: Array = []
		for j in range(ys.size()):
			var y0: float = ys[j]
			var y1: float = ys[j + 1] if j + 1 < ys.size() else 99.0
			if y1 - y0 < 0.005 or y0 >= minf(t0, t1):
				continue
			var kind := _kind(mx, (y0 + minf(y1, minf(t0, t1))) / 2.0)
			if kind == "":
				continue
			runs.append([y0, y1, kind])
		for run in runs:
			var y0: float = run[0]
			var top_run: bool = float(run[1]) >= 98.0
			var y1a: float = t0 if top_run else float(run[1])
			var y1b: float = t1 if top_run else float(run[1])
			_lattice_piece(x0, x1, y0, y1a, y1b, run[2])
			lattice_m2 += (x1 - x0) * ((y1a + y1b) / 2.0 - maxf(y0, 0.0))
		# its top: the brick of the last course, from the face to the back
		quad(Vector3(x0, t0, 0.0), Vector3(x0, t0, -T), Vector3(x1, t1, -T), Vector3(x1, t1, 0.0), BRICK_EDGE, Vector3.UP)
	# its east end, where it stops beside the neighbour's yard
	quad(Vector3(L, ground(L, 0.0) - 0.3, 0.0), Vector3(L, ground(L, 0.0) - 0.3, -T), Vector3(L, top_at(L), -T), Vector3(L, top_at(L), 0.0), BRICK_EDGE, Vector3(1, 0, 0))
	# its thickness round the openings
	for h: Rect2 in _holes:
		var y_top := h.end.y
		quad(Vector3(h.position.x, y_top, 0.0), Vector3(h.end.x, y_top, 0.0), Vector3(h.end.x, y_top, -T), Vector3(h.position.x, y_top, -T), BRICK_EDGE, Vector3.DOWN)
		if h.position.y > 0.05 and h != BAND:        # (the band has its own navy sill there)
			quad(Vector3(h.position.x, h.position.y, -T), Vector3(h.end.x, h.position.y, -T), Vector3(h.end.x, h.position.y, 0.0), Vector3(h.position.x, h.position.y, 0.0), BRICK_EDGE, Vector3.UP)
		var yb := h.position.y if h.position.y > 0.05 else ground(h.position.x, 0.0) - 0.3
		quad(Vector3(h.position.x, yb, 0.0), Vector3(h.position.x, y_top, 0.0), Vector3(h.position.x, y_top, -T), Vector3(h.position.x, yb, -T), BRICK_EDGE, Vector3(1, 0, 0))
		quad(Vector3(h.end.x, yb, -T), Vector3(h.end.x, y_top, -T), Vector3(h.end.x, y_top, 0.0), Vector3(h.end.x, yb, 0.0), BRICK_EDGE, Vector3(-1, 0, 0))
		openings += 1

## one piece of lattice: its face to the street at z = 0 and its back at z = -T, the picture laid by where it is (so
## that the pieces join up), its top at y1a over x0 and y1b over x1
func _lattice_piece(x0: float, x1: float, y0: float, y1a: float, y1b: float, kind: String) -> void:
	pieces += 1
	var uv := func(x: float, y: float) -> Vector2: return Vector2(x / TILE.x, -y / TILE.y)
	quad(Vector3(x0, y0, 0.0), Vector3(x1, y0, 0.0), Vector3(x1, y1b, 0.0), Vector3(x0, y1a, 0.0), kind, Vector3(0, 0, 1),
		[uv.call(x0, y0), uv.call(x1, y0), uv.call(x1, y1b), uv.call(x0, y1a)])
	quad(Vector3(x1, y0, -T), Vector3(x0, y0, -T), Vector3(x0, y1a, -T), Vector3(x1, y1b, -T), kind, Vector3(0, 0, -1),
		[uv.call(-x1, y0), uv.call(-x0, y0), uv.call(-x0, y1a), uv.call(-x1, y1b)])

# ---------------- the gate, the porch, the hall's doors ----------------
## (all of it measured from the gate's sill, `gate_y`: the porch's floor is the pavement's before the gate)
func _gate_and_porch() -> void:
	home()
	var x0 := PORCH.position.x
	var x1 := PORCH.end.x
	var zb := PORCH.position.y
	var zf := PORCH.end.y
	var ph := PORCH_H - gate_y                      # how high the porch is over its own floor
	# behind the lattice west of the porch, and under it: the old wall in its shade (no hole shows the sky)
	quad(Vector3(0.0, gate_y - 1.5, -T - 0.03), Vector3(x0, gate_y - 1.5, -T - 0.03), Vector3(x0, PORCH_H, -T - 0.03), Vector3(0.0, PORCH_H, -T - 0.03), "detras", Vector3(0, 0, 1))
	_xf = Transform3D(Basis.IDENTITY, Vector3(0.0, gate_y, 0.0))
	# the porch's floor; the step under the gate where the pavement falls away; its ceiling; its sides; its back wall
	# with the hall's doors in it
	box(x0, -0.3, zb, x1 - x0, 0.3, zf - zb, "suelo")
	var low := minf(ground(GATE.position.x, 0.1), ground(GATE.end.x, 0.1)) - gate_y - 0.3
	box(GATE.position.x, low, -T, GATE.size.x, -low, T + 0.02, "suelo")
	quad(Vector3(x0, ph, zf), Vector3(x1, ph, zf), Vector3(x1, ph, zb), Vector3(x0, ph, zb), "revoco", Vector3.DOWN)
	quad(Vector3(x0, 0.0, zb), Vector3(x0, 0.0, zf), Vector3(x0, ph, zf), Vector3(x0, ph, zb), "revoco", Vector3(1, 0, 0))
	quad(Vector3(x1, 0.0, zf), Vector3(x1, 0.0, zb), Vector3(x1, ph, zb), Vector3(x1, ph, zf), "revoco", Vector3(-1, 0, 0))
	for q in [[x0, DOORS.position.x, 0.0, ph], [DOORS.end.x, x1, 0.0, ph], [DOORS.position.x, DOORS.end.x, DOORS.end.y, ph]]:
		quad(Vector3(q[0], q[2], zb), Vector3(q[1], q[2], zb), Vector3(q[1], q[3], zb), Vector3(q[0], q[3], zb), "revoco", Vector3(0, 0, 1))
	# the hall's doors: two leaves of glass in navy frames, the white hall lit behind them
	var dx0 := DOORS.position.x
	var dx1 := DOORS.end.x
	var dh := DOORS.end.y
	quad(Vector3(dx0, 0.0, zb - 1.2), Vector3(dx1, 0.0, zb - 1.2), Vector3(dx1, dh, zb - 1.2), Vector3(dx0, dh, zb - 1.2), "vestibulo", Vector3(0, 0, 1))
	for sx in [dx0, dx1]:
		quad(Vector3(sx, 0.0, zb - 1.2), Vector3(sx, 0.0, zb), Vector3(sx, dh, zb), Vector3(sx, dh, zb - 1.2), "vestibulo", Vector3(1 if sx == dx0 else -1, 0, 0))
	quad(Vector3(dx0, 0.002, zb), Vector3(dx1, 0.002, zb), Vector3(dx1, 0.002, zb - 1.2), Vector3(dx0, 0.002, zb - 1.2), "vestibulo", Vector3.UP)
	quad(Vector3(dx0, dh, zb - 1.2), Vector3(dx1, dh, zb - 1.2), Vector3(dx1, dh, zb), Vector3(dx0, dh, zb), "vestibulo", Vector3.DOWN)
	for x in [dx0, (dx0 + dx1) / 2.0 - 0.03, dx1 - 0.06]:
		box(x, 0.0, zb - 0.06, 0.06, dh, 0.08, NAVY)
	box(dx0, dh - 0.06, zb - 0.06, dx1 - dx0, 0.06, 0.08, NAVY)
	pieces += 1
	quad(Vector3(dx0, 0.0, zb - 0.02), Vector3(dx1, 0.0, zb - 0.02), Vector3(dx1, dh, zb - 0.02), Vector3(dx0, dh, zb - 0.02), "vidrio", Vector3(0, 0, 1))
	box((dx0 + dx1) / 2.0 - 0.2, 1.0, zb + 0.02, 0.4, 0.03, 0.03, 0xb8bcc0)                    # (their bar)
	openings += 1
	# its mat, its lamp, the plates on the lattice by the gate
	box(dx0 - 0.1, 0.0, zb + 0.15, dx1 - dx0 + 0.2, 0.015, 0.8, 0x3a3a3c)
	box(1.25, ph - 0.05, -1.25, 0.5, 0.05, 0.5, "luz")
	for k in range(2):                              # (the name over the hours: placas.png's two halves)
		var py := PLATES.end.y - (k + 1) * 0.18 - k * 0.04
		var px := PLATES.position.x
		box(px, py, 0.0, PLATES.size.x, 0.18, 0.012, 0xd8d8d4)
		pieces += 1
		quad(Vector3(px + 0.005, py + 0.005, 0.026), Vector3(px + PLATES.size.x - 0.005, py + 0.005, 0.026), Vector3(px + PLATES.size.x - 0.005, py + 0.175, 0.026),
			Vector3(px + 0.005, py + 0.175, 0.026), "placas", Vector3(0, 0, 1), [Vector2(0, 0.5 * (k + 1)), Vector2(1, 0.5 * (k + 1)), Vector2(1, 0.5 * k), Vector2(0, 0.5 * k)])
	# the gate's frame in the lattice: its posts (down to the pavement) and lintel of navy steel
	for x in [GATE.position.x, GATE.end.x - 0.06]:
		var foot: float = ground(x, 0.0) - gate_y - 0.05
		box(x, foot, -T, 0.06, GATE.end.y - foot, T, NAVY)
	box(GATE.position.x, GATE.end.y - 0.06, -T, GATE.size.x, 0.06, T, NAVY)
	home()

## the gate's leaf, shut (in its frame) or open (swung in along the porch's west side)
func _leaf(open_: bool) -> void:
	var w := GATE.size.x - 0.12
	var h := GATE.end.y - 0.08
	var y0 := 0.02
	if open_:
		_xf = Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(GATE.position.x + 0.1, gate_y, -T - 0.02))
	else:
		_xf = Transform3D(Basis.IDENTITY, Vector3(GATE.position.x + 0.06, gate_y, -T / 2.0))
	pieces += 1
	quad(Vector3(0, y0, 0.012), Vector3(w, y0, 0.012), Vector3(w, h, 0.012), Vector3(0, h, 0.012), "puerta", Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	quad(Vector3(w, y0, -0.012), Vector3(0, y0, -0.012), Vector3(0, h, -0.012), Vector3(w, h, -0.012), "puerta", Vector3(0, 0, -1),
		[Vector2(1, 1), Vector2(0, 1), Vector2(0, 0), Vector2(1, 0)])
	for q in [[0.0, y0, 0.04, h - y0], [w - 0.04, y0, 0.04, h - y0], [0.0, h - 0.04, w, 0.04], [0.0, y0, w, 0.04]]:
		box(q[0], q[1], -0.02, q[2], q[3], 0.04, NAVY)
	box(w - 0.14, 1.0, 0.02, 0.1, 0.03, 0.03, 0x9a9ca0)                                    # (its handle)
	home()

# ---------------- the windows ----------------
func _windows() -> void:
	home()
	# the band of the ground floor: a navy frame, frosted panes between blue panels, the dark one, the long panel
	var b := BAND
	var units: Array = [[5.14, 5.43, "frame"], [5.43, 6.51, "esmerilado"], [6.51, 7.2, "panel"], [7.2, 7.94, "esmerilado"],
		[7.94, 8.33, "panel"], [8.33, 9.01, "esmerilado"], [9.01, 9.54, "panel"], [9.54, 10.2, "oscuro"], [10.2, 11.81, "panel"]]
	for u in units:
		var x0: float = u[0]
		var x1: float = u[1]
		match String(u[2]):
			"frame":
				box(x0, b.position.y, -T, x1 - x0, b.size.y, T + 0.02, NAVY)
			"panel":
				box(x0, b.position.y, -T + 0.02, x1 - x0, b.size.y, T + 0.01, BLUE)
				for k in range(int((x1 - x0) / 0.16)):                                       # (its slats)
					box(x0 + 0.04 + k * 0.16, b.position.y + 0.06, 0.012, 0.02, b.size.y - 0.12, 0.01, NAVY)
			_:
				pieces += 1
				quad(Vector3(x0, b.position.y, -0.07), Vector3(x1, b.position.y, -0.07), Vector3(x1, b.end.y, -0.07), Vector3(x0, b.end.y, -0.07), u[2], Vector3(0, 0, 1))
				box(x0, b.position.y, -0.08, x1 - x0, 0.05, 0.09, NAVY)
				box(x0, b.end.y - 0.05, -0.08, x1 - x0, 0.05, 0.09, NAVY)
				box(x0, b.position.y, -0.08, 0.04, b.size.y, 0.09, NAVY)
				box(x1 - 0.04, b.position.y, -0.08, 0.04, b.size.y, 0.09, NAVY)
				openings += 1
	box(b.position.x, b.position.y - 0.04, -T, b.size.x, 0.04, T + 0.05, NAVY)                   # (its sill)
	# the window over the canopy: navy frame, frosted, a mullion
	var w := UPPER
	pieces += 1
	quad(Vector3(w.position.x, w.position.y, -0.08), Vector3(w.end.x, w.position.y, -0.08), Vector3(w.end.x, w.end.y, -0.08), Vector3(w.position.x, w.end.y, -0.08), "esmerilado", Vector3(0, 0, 1))
	for q in [[w.position.x, w.position.y, 0.06, w.size.y], [w.end.x - 0.06, w.position.y, 0.06, w.size.y], [w.position.x, w.position.y, w.size.x, 0.06],
			[w.position.x, w.end.y - 0.06, w.size.x, 0.06], [w.position.x + w.size.x * 0.62, w.position.y, 0.04, w.size.y]]:
		box(q[0], q[1], -0.1, q[2], q[3], 0.11, NAVY)
	openings += 1
	# the grille of the vent at the foot
	box(VENT.position.x, VENT.position.y, 0.0, VENT.size.x, VENT.size.y, 0.02, 0x9a9a98)
	for k in range(5):
		box(VENT.position.x + 0.02, VENT.position.y + 0.03 + k * 0.045, 0.02, VENT.size.x - 0.04, 0.015, 0.012, 0x6a6a68)

# ---------------- the canopy ----------------
func _canopy() -> void:
	home()
	var x0: float = CANOPY[0]
	var x1: float = CANOPY[1]
	var y0: float = CANOPY[2]
	var y1: float = CANOPY[3]
	var out: float = CANOPY[4]
	var t := 0.09
	pieces += 1
	quad(Vector3(x0, y0, -T), Vector3(x0, y0, out), Vector3(x1, y1, out), Vector3(x1, y1, -T), 0xe8e8e4, Vector3.UP)
	quad(Vector3(x0, y0 - t, out), Vector3(x0, y0 - t, -T), Vector3(x1, y1 - t, -T), Vector3(x1, y1 - t, out), 0xd4d4d0, Vector3.DOWN)       # (its underside pale, as in the photograph)
	quad(Vector3(x0, y0 - t, out), Vector3(x1, y1 - t, out), Vector3(x1, y1 + 0.02, out), Vector3(x0, y0 + 0.02, out), NAVY, Vector3(0, 0, 1))
	quad(Vector3(x0, y0 - t, -T), Vector3(x0, y0 - t, out), Vector3(x0, y0 + 0.02, out), Vector3(x0, y0 + 0.02, -T), NAVY, Vector3(-1, 0, 0))
	quad(Vector3(x1, y1 - t, out), Vector3(x1, y1 - t, -T), Vector3(x1, y1 + 0.02, -T), Vector3(x1, y1 + 0.02, out), NAVY, Vector3(1, 0, 0))
	# the blue tiles in the holes over it: the two rows of the open lattice's holes in OPENS[3], filled
	# (tools/vivero/dibujos.py: a hole of 12.5 by 12 cm every 40 cm, the rows 15 cm apart, each half along from the
	# last; the picture's top at each 30 cm up)
	for row in [[3.3 - 0.1328, 0.0234], [3.3 - 0.2828, 0.2234]]:
		var hy: float = row[0]
		var x: float = row[1]
		while x < x1 - 0.15:
			if x > x0 + 0.02 and hy > lerpf(y0, y1, (x + 0.06 - x0) / (x1 - x0)) + 0.02:
				box(x, hy, -T + 0.03, 0.125, 0.12, T - 0.04, BLUE)
			x += 0.4

# ---------------- the old front behind ----------------
func _old_front() -> void:
	home()
	var z := -BACK
	# from the porch's east wall to the east end, and over the porch to the roof; its two windows behind the holes
	var holes: Array = [BAND, UPPER]
	holes.append_array(BEHIND)
	var rects: Array = []
	# (cut into pieces round the holes, by rows: the simplest that never overlaps)
	var ys: Array = [-1.6, PORCH_H, FLAT]             # (from under the pavement: the lattice has holes down to it)
	for h: Rect2 in holes:
		ys.append(h.position.y)
		ys.append(h.end.y)
	ys.sort()
	for j in range(ys.size() - 1):
		var y0: float = ys[j]
		var y1: float = ys[j + 1]
		if y1 - y0 < 0.005:
			continue
		var my := (y0 + y1) / 2.0
		var xa := PORCH.end.x if my < PORCH_H else 0.0
		var xs: Array = [xa, L]
		for h: Rect2 in holes:
			if my > h.position.y and my < h.end.y:
				xs.append(clampf(h.position.x, xa, L))
				xs.append(clampf(h.end.x, xa, L))
		xs.sort()
		for i in range(xs.size() - 1):
			var x0: float = xs[i]
			var x1: float = xs[i + 1]
			if x1 - x0 < 0.005:
				continue
			var mx := (x0 + x1) / 2.0
			var inside := false
			for h: Rect2 in holes:
				if h.has_point(Vector2(mx, my)):
					inside = true
			if not inside:
				rects.append([x0, x1, y0, y1])
	for q in rects:
		quad(Vector3(q[0], q[2], z), Vector3(q[1], q[2], z), Vector3(q[1], q[3], z), Vector3(q[0], q[3], z), "detras", Vector3(0, 0, 1))
	# the windows behind the holes: frosted, in white frames; the band and the upper window joined to the lattice by
	# white reveals
	for h: Rect2 in BEHIND:
		pieces += 1
		quad(Vector3(h.position.x, h.position.y, z - 0.08), Vector3(h.end.x, h.position.y, z - 0.08), Vector3(h.end.x, h.end.y, z - 0.08), Vector3(h.position.x, h.end.y, z - 0.08), "esmerilado", Vector3(0, 0, 1))
		box(h.position.x, h.position.y - 0.04, z, h.size.x, 0.04, 0.06, 0xf2f2ee)
	for h: Rect2 in [BAND, UPPER]:
		quad(Vector3(h.position.x, h.end.y, -T), Vector3(h.end.x, h.end.y, -T), Vector3(h.end.x, h.end.y, z), Vector3(h.position.x, h.end.y, z), "revoco", Vector3.DOWN)
		quad(Vector3(h.position.x, h.position.y, z), Vector3(h.end.x, h.position.y, z), Vector3(h.end.x, h.position.y, -T), Vector3(h.position.x, h.position.y, -T), "revoco", Vector3.UP)
		if h.position.x > PORCH.end.x + 0.01:
			quad(Vector3(h.position.x, h.position.y, -T), Vector3(h.position.x, h.end.y, -T), Vector3(h.position.x, h.end.y, z), Vector3(h.position.x, h.position.y, z), "revoco", Vector3(1, 0, 0))
		quad(Vector3(minf(h.end.x, L - 0.02), h.position.y, z), Vector3(minf(h.end.x, L - 0.02), h.end.y, z), Vector3(minf(h.end.x, L - 0.02), h.end.y, -T), Vector3(minf(h.end.x, L - 0.02), h.position.y, -T), "revoco", Vector3(-1, 0, 0))
	# the gap between the lattice and the old front, closed at its east end and over the porch
	quad(Vector3(L - 0.02, -1.6, z), Vector3(L - 0.02, -1.6, -T), Vector3(L - 0.02, FLAT, -T), Vector3(L - 0.02, FLAT, z), "revoco", Vector3(-1, 0, 0))
	quad(Vector3(PORCH.position.x, PORCH_H, -T), Vector3(PORCH.end.x, PORCH_H, -T), Vector3(PORCH.end.x, PORCH_H, z), Vector3(PORCH.position.x, PORCH_H, z), "revoco", Vector3.UP)

# ---------------- the house behind ----------------
## its walls round the outline (the front, segment 5, is the lattice), its flat roof, a parapet; the two yards of the
## real house are the outline's notch on the east
func _body() -> void:
	home()
	var i_front := -1
	for i in range(outline.size()):
		var p: Vector2 = outline[i]
		var q: Vector2 = outline[(i + 1) % outline.size()]
		if absf(p.y) < 0.3 and absf(q.y) < 0.3 and p.distance_to(q) > 5.0:
			i_front = i
	ring_walls(outline, -1.0, FLAT + 0.35, "revoco", [i_front])
	var roof := PackedVector2Array()
	for p: Vector2 in outline:
		roof.append(Vector2(p.x, minf(p.y, -BACK)))
	flat(roof, FLAT, "azotea")
	# the stair's hut on the roof, and the skylights over the co-working room (vivero_dentro.gd)
	box(1.2, FLAT, -14.0, 2.6, 2.3, 3.2, "revoco")
	box(1.1, FLAT + 2.3, -14.1, 2.8, 0.08, 3.4, 0xd8d8d4)
	for k in range(3):
		box(1.0 + k * 1.6, FLAT, -19.5, 1.0, 0.35, 1.0, 0xd8d8d4)
		box(1.05 + k * 1.6, FLAT + 0.35, -19.45, 0.9, 0.02, 0.9, "oscuro")

# ---------------- the street before it ----------------
## the sign of the bay for disabled drivers, at the kerb before the window band, and the young tree by the east end
func _street() -> void:
	home()
	var sx := 9.9
	var sz := _kerb(sx) - 0.4
	box(sx - 0.03, ground(sx, sz) - 0.1, sz - 0.03, 0.06, 2.75 - ground(sx, sz) + 0.1, 0.06, 0x9a9ca0)
	sign_board(sx - 0.25, 2.1, 0.5, 0.5, sz + 0.03, 0.012, 0xc8c8c4, "minusvalidos", 0.0)
	yard.append(spot(sx, sz))
	var tz := _kerb(11.45) - 0.6
	var tp := spot(11.45, tz)
	W.add_trees([[tp.x, tp.y, 0, 0.75, 0.6]])
	yard.append(tp)

## how far out from the front the kerb is at x (where the pavement ends), searched outwards
func _kerb(x: float) -> float:
	var z := 0.3
	while z < 6.0:
		var d: float = MapData.road_edge_dist(spot(x, z))
		if MapData.road_hit != null:
			d += MapData.road_hit.hw - MapData.fitted_hw(MapData.road_hit)
		if d <= 0.05:
			return z
		z += 0.05
	return 2.0

# ---------------- shut and open ----------------
## what changes with the hours: the gate shut or swung open, the lights in the panes and the hall
func _states() -> void:
	_tools.clear()
	_shut = Node3D.new()
	add_child(_shut)
	_leaf(false)
	_commit_to(_shut)
	_lit = Node3D.new()
	add_child(_lit)
	_leaf(true)
	_commit_to(_lit)
	var lamp := OmniLight3D.new()                   # (the porch's own lamp)
	lamp.position = Vector3(1.5, PORCH_H - 0.3, -1.0)
	lamp.light_color = Color(1.0, 0.95, 0.85)
	lamp.omni_range = 3.5
	lamp.light_energy = 0.5
	lamp.shadow_enabled = false
	_lit.add_child(lamp)

## what has been built since the last commit becomes meshes under `node`: a part that can be shown and hidden
func _commit_to(node: Node3D) -> void:
	for key in _tools:
		var mi := MeshInstance3D.new()
		mi.mesh = (_tools[key] as SurfaceTool).commit()
		mi.material_override = _material(key)
		node.add_child(mi)
	_tools.clear()

## its solids: the house round its outline. (The map's wall round the block runs along the front: the porch is seen
## through the gate and the lattice, not walked into; the way in is the arrow before the gate, into vivero_dentro.gd.)
func _solids_all() -> void:
	var poly := PackedVector2Array(outline)
	var idx := Geometry2D.triangulate_polygon(poly)
	for k in range(0, idx.size(), 3):
		_prism([poly[idx[k]], poly[idx[k + 1]], poly[idx[k + 2]]], -1.0, FLAT + 0.5)

func set_open(on: bool) -> void:
	is_open = on
	if dentro != null:
		dentro.open = on
	if _shut != null:
		_shut.visible = not on
		_lit.visible = on
	if _mats.has("esmerilado"):
		(_mats["esmerilado"] as StandardMaterial3D).emission_energy_multiplier = 0.35 if on else 0.04
	if _mats.has("vestibulo"):
		(_mats["vestibulo"] as StandardMaterial3D).emission_energy_multiplier = 0.6 if on else 0.03
	if _mats.has("luz"):
		(_mats["luz"] as StandardMaterial3D).emission_energy_multiplier = 1.6 if on else 0.1

func _process(_delta: float) -> void:
	var game = W.get_parent() if W != null else null
	if game != null and "clock" in game and "weekday" in game:
		var o: bool = open_at(int(game.weekday), float(game.clock))
		if o != is_open:
			set_open(o)
