extends "res://scripts/esquina.gd"
## The traffic lights, the mirror and the signs of the crossroads of the traffic lights ("el cruce de los semáforos",
## "las cuatro esquinas"), where the Avenida de la Constitución, the Calle de los Arcos, Santa Ana, the Salvador and
## the Calle Cervantes meet. The user, 21 November 2026: "tienen muchos semáforos y señales. Te pido ahora colocar
## estos donde corresponde", and on the 22nd, with the five corner buildings built: "Pasamos a semáforos".
## Each one stands where Street View shows it (November 2024: tools/cruce/capturas.py, the x_ pictures; placed with
## tools/cruce/postes.py, to about 0.7 m), then moved in to the game's own pavement where that is narrower than the
## real one. referencias/cruce/LEEME.md has the list.
##
## What there is, by corner:
##   - north-west (the beige house): a post with the head for whoever comes down the avenue and a pedestrians' head;
##     the grey cabinet that runs them all, against the wall; no entry into the Salvador, with its plate;
##   - north-east (the house with the bay window): a post with two pedestrians' heads before the corner's cut; the
##     tall pole whose arm carries a head out over Santa Ana, with another head and a pedestrians' one lower down;
##     no stopping, on the avenue;
##   - south-east (the white house): a post with a head for Santa Ana and a pedestrians' one, and a litter bin; at
##     the corner, no turning right and STOP for whoever comes up the Arcos; no entry into Santa Ana;
##   - the Arcos: a post on each side with a head for whoever comes up it and a pedestrians' head; no parking, flat
##     on the clinic's wall, with its arrow in it;
##   - the red building: the round mirror and a STOP on one pole, before its avenue front; no buses into Cervantes;
##     on its Salvador front, a give-way sign and a head on brackets for whoever comes along the Salvador.
## On the roadway: a stop line for each street that brings cars in, and the crossing of the avenue north of the
## Salvador (the town's own crossings are world.gd's).
##
## The lights work. Sistemas's traffic drives them (semaforos.gd): it reads `heads` (one for each street that brings
## cars in: where they stop, the map's nodes they come by, which streets go together) and `walk` (the crossings),
## and calls set_light() and set_walk(). Until somebody sets `auto` to false, this file runs a plain cycle of its
## own, of lights only, so that they are never dead.
##
## Everything that stands on the ground breaks at a blow, as the rest of the street's furniture (the user, 22 November
## 2026: "que se puedan romper con un golpe, una vez rotos pasan a funcionar como ámbar. Se arreglan igual que el
## resto de objetos rompibles"): each post with what it carries, the cabinet and the litter bin are a body of their
## own, which props.gd takes in (adopt()) and a car or a fist knocks over. With a post that carries lights down, or the
## cabinet that runs them, `broken` is true and every light left blinks amber, whatever it is told to show, until
## repair() stands it all up again. What hangs from a wall stays where it is.
## No new lamp: the lenses shine by their own material. Frame: the map's own (x east, z south), y = 0 the roadway in
## the middle of the crossroads.

# the corners of the five buildings round it, on the map (each building's own file has them too)
const BEIGE_SE := Vector2(107.84, 56.33)
const BEIGE_NE := Vector2(109.16, 43.81)
const SOP_NW := Vector2(92.34, 58.42)
const SOP_NE := Vector2(108.32, 62.26)
const SOP_SE := Vector2(108.56, 70.77)
const SOP_SW := Vector2(103.82, 72.76)
const MIR_N := Vector2(118.50, 47.62)
const MIR_C1 := Vector2(117.97, 57.91)
const MIR_C2 := Vector2(120.12, 61.46)
const MIR_E := Vector2(129.63, 63.93)
const ANA_A := Vector2(116.70, 74.14)
const ANA_B := Vector2(131.66, 73.67)
const ANA_J := Vector2(116.49, 78.83)
const CLI_X := Vector2(109.115, 77.683)
const CLI_SE := Vector2(109.06, 86.65)

## Each street that brings cars in: its name, the map's node they come from and the one they come to (found by where
## they are, so a new bake that renumbers them changes nothing), how far before that one they stop, and its group
## (the streets of one group have green together).
const ARRIVALS := [
	["avenida", Vector2(114.8, 34.7), Vector2(113.7, 55.7), 2.8, 0],
	["salvador", Vector2(79.9, 51.2), Vector2(113.4, 60.6), 6.8, 1],
	["santa_ana", Vector2(132.1, 69.4), Vector2(113.1, 68.9), 8.5, 1],
	["arcos", Vector2(112.7, 106.1), Vector2(113.0, 74.1), 6.8, 0],
]
const COLOURS := ["rojo", "ambar", "verde"]
const LIT := {"rojo": Color(1.0, 0.13, 0.1), "ambar": Color(1.0, 0.62, 0.05), "verde": Color(0.1, 0.95, 0.42)}
const POST := 0x5c6662              # galvanised, painted grey-green
const RED := 0xd23b2e
const WHITE := 0xf4f4f0
const BLUE := 0x1f55c4
const INK := 0x22252a
## the cycle this file runs while `auto`: [the group with that light (-1: nobody), the light, seconds]
const CYCLE := [[0, "verde", 18.0], [0, "ambar", 3.0], [-1, "rojo", 2.0], [1, "verde", 14.0], [1, "ambar", 3.0], [-1, "rojo", 2.0]]
const BLINK := 0.6                  # seconds lit, seconds dark, when it is broken
## What each kind of thing that can be knocked over is to the street's furniture (props.gd): what it is called there,
## its weight, how thick it is, how close a car has to come, how much the police mind, and whether the lights go with it.
const LIGHT := {"kind": "semaforo", "mass": 40.0, "wide": 0.2, "rad": 0.5, "heat": 8.0, "lights": true}
const POLE := {"kind": "semaforo", "mass": 150.0, "wide": 0.26, "rad": 0.55, "heat": 10.0, "lights": true}
const CABINET := {"kind": "armario", "mass": 60.0, "wide": 0.4, "rad": 0.5, "heat": 8.0, "lights": true}
const SIGN := {"kind": "sign", "mass": 15.0, "wide": 0.2, "rad": 0.45, "heat": 5.0, "lights": false}
const BIN := {"kind": "bin", "mass": 12.0, "wide": 0.38, "rad": 0.45, "heat": 3.0, "lights": false}

var heads: Array = []               # Dictionary for each street that brings cars in: "name", "stop" (Vector2: the stop line, in the middle of its lane), "a" and "b" (the map's nodes it comes by, a towards b), "group" (0 or 1), "state"
var walk: Array = []                # Dictionary for each crossing with lights: "name", "group" (that of the street it crosses), "at" (Vector2: its middle), "on"
var auto := true                    # this file's own cycle runs; whoever drives the lights sets it to false
var stands: Array = []              # [name, Vector2, metres off the asphalt]: the foot of everything that stands on the ground (the self-test)
var faces := 0                      # cars' heads built (the self-test)
var walk_faces := 0                 # pedestrians' heads
var signs := 0                      # signs' sheets
var broken := false                 # a post that carries lights is down, or the cabinet that runs them: every light blinks amber until repair()
var down := 0                       # how many of its things lie knocked over now
var _parts: Array = []              # what can be knocked over: {"name", "p" (its foot on the map), "make" (draws it), "spec", "size", "turn", "body", "down"}
var _into: Node3D = null            # the body being drawn, while one is
var _base := Transform3D.IDENTITY   # ...and where the place's frame is, seen from it
var _props = null                   # the street's furniture (props.gd), once the game has it
var _step := -1
var _left := 0.0
var _blink_t := 0.0
var _blink_on := false

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var k := String(key) if key is String else ""
	var m: Material
	if k.begins_with("luz_") or k.begins_with("peaton_"):          # a lens: one material for each street and colour (set_light changes it)
		var sm := StandardMaterial3D.new()
		sm.emission_enabled = true
		_lamp(sm, LIT[k.get_slice("_", 2)], false)
		m = sm
	else:
		match k:
			"poste":
				m = Parts.mat(POST)
			"caja":             # the heads' black housings
				m = Parts.mat(0x17181a)
			"dorso":            # the back of a sign: bare sheet
				m = Parts.mat(0x8d9397)
			"pintura":          # road paint
				m = Parts.mat(0xf4f1e8)
			"espejo":
				var gm := StandardMaterial3D.new()
				gm.albedo_color = Color(0.7, 0.8, 0.86)
				gm.metallic = 0.6
				gm.roughness = 0.2
				gm.emission_enabled = true
				gm.emission = Color(0.55, 0.66, 0.72)
				gm.emission_energy_multiplier = 0.25
				m = gm
			_:
				return super._material(key)
	_mats[key] = m
	return m

func _lamp(m: StandardMaterial3D, c: Color, on: bool) -> void:
	m.albedo_color = c if on else Color(c.r * 0.17, c.g * 0.17, c.b * 0.17)
	m.emission = c
	m.emission_energy_multiplier = 2.4 if on else 0.0

## The lights of the street `i` of `heads`: "verde", "ambar", "rojo", or "off" (all dark). Every head of that street
## changes together.
func set_light(i: int, state: String) -> void:
	if i < 0 or i >= heads.size():
		return
	heads[i]["state"] = state
	if not broken:
		_show_light(i, state)

func _show_light(i: int, state: String) -> void:
	for c in COLOURS:
		_lamp(_material("luz_%d_%s" % [i, c]) as StandardMaterial3D, LIT[c], c == state)

## The pedestrians' lights of the crossing `i` of `walk`: the green man, or the red one; `dark`: neither.
func set_walk(i: int, on: bool, dark := false) -> void:
	if i < 0 or i >= walk.size():
		return
	walk[i]["on"] = on and not dark
	walk[i]["dark"] = dark
	if not broken:
		_show_walk(i, on, dark)

func _show_walk(i: int, on: bool, dark: bool) -> void:
	_lamp(_material("peaton_%d_verde" % i) as StandardMaterial3D, LIT["verde"], on and not dark)
	_lamp(_material("peaton_%d_rojo" % i) as StandardMaterial3D, LIT["rojo"], not on and not dark)

## one step of the cycle: the streets of `group` show `state`, the rest red; people cross a street while the other
## group has green
func show_phase(group: int, state: String) -> void:
	for i in range(heads.size()):
		set_light(i, state if int(heads[i]["group"]) == group else "rojo")
	for i in range(walk.size()):
		set_walk(i, group >= 0 and state == "verde" and int(walk[i]["group"]) != group)

## what every light shows now, to put back later with put_back() (the self-test plays with them, and whoever drives
## them must find them as it left them)
func lights() -> Array:
	var out: Array = [auto, [], []]
	for h in heads:
		out[1].append(h["state"])
	for w in walk:
		out[2].append([w["on"], w["dark"]])
	return out

func put_back(was: Array) -> void:
	if was[0]:
		restart()
		return
	auto = false
	for i in range(heads.size()):
		set_light(i, was[1][i])
	for i in range(walk.size()):
		set_walk(i, was[2][i][0], was[2][i][1])

## the cycle of this file again, from its first step (whoever stops driving the lights hands them back with this)
func restart() -> void:
	auto = true
	_step = -1
	_left = 0.0

## whether this map has the crossroads (its three nodes are where they should be)
static func there() -> bool:
	for q in ARRIVALS:
		if MapData.nodes.is_empty() or (MapData.nodes[MapData.nearest_node(q[2])] as Vector2).distance_to(q[2]) > 3.0:
			return false
	return true

## broken: every light amber, or none (it blinks), and no little man
func show_blink(on: bool) -> void:
	_blink_on = on
	for i in range(heads.size()):
		_show_light(i, "ambar" if on else "off")
	for i in range(walk.size()):
		_show_walk(i, false, true)

## Everything knocked over stands again, and the lights show what they were last told to (whatever mends the street's
## furniture calls this).
func repair() -> void:
	var counts := [faces, walk_faces, signs]
	for i in range(_parts.size()):
		if _parts[i]["down"]:
			if is_instance_valid(_parts[i]["body"]):
				_parts[i]["body"].queue_free()               # (still lying about)
			_raise(i)
	faces = counts[0]
	walk_faces = counts[1]
	signs = counts[2]
	down = 0
	if broken:
		broken = false
		for i in range(heads.size()):
			_show_light(i, String(heads[i]["state"]))
		for i in range(walk.size()):
			_show_walk(i, bool(walk[i]["on"]), bool(walk[i]["dark"]))

## one of the things that can be knocked over, by its name (the self-test): {"p", "body", "down", "spec"...}
func part(what: String) -> Dictionary:
	for q in _parts:
		if String(q["name"]) == what:
			return q
	return {}

## Where repair() would change what is seen: the place of each thing that is down and, if it still lies about, where
## it lies (props.gd mends the next day, as soon as nobody is looking: these are the spots to look at).
func fallen() -> Array:
	var out: Array = []
	for q in _parts:
		if q["down"]:
			out.append(q["p"])
			var b = q["body"]
			if is_instance_valid(b) and b.visible:
				out.append(Vector2(b.global_position.x, b.global_position.z))
	return out

## what has been knocked over, should props.gd not have said so: a body no longer frozen, or gone (it frees what is
## not marked "keep" after a while)
func _watch() -> void:
	if _props == null:
		var game = W.get_parent()
		var pr = game.get("props") if game != null else null      # (the street's furniture is made after the town)
		if pr == null or not pr.has_method("adopt"):
			return
		_props = pr
		for q in _parts:
			_adopt(q)
	for q in _parts:
		if q["down"]:
			continue
		var b = q["body"]
		if not (is_instance_valid(b) and b.freeze):
			_drop(q)

## props.gd says so the moment it knocks one over (its body's "on_knock")
func _fell(_b, i: int) -> void:
	_drop(_parts[i])

func _drop(q: Dictionary) -> void:
	if q["down"]:
		return
	q["down"] = true
	down += 1
	if q["spec"]["lights"] and not broken:
		broken = true
		_blink_t = 0.0
		_blink_on = false

func _adopt(q: Dictionary) -> void:
	var sp: Dictionary = q["spec"]
	_props.adopt(q["body"], q["p"], String(sp["kind"]), float(sp["rad"]), float(sp["heat"]))

func _process(delta: float) -> void:
	_watch()
	if broken:
		_blink_t -= delta
		if _blink_t <= 0.0:
			_blink_t = BLINK
			show_blink(not _blink_on)
		return
	if not auto:
		return
	_left -= delta
	if _step >= 0 and _left > 0.0:
		return
	_step = (_step + 1) % CYCLE.size()
	_left = float(CYCLE[_step][2])
	show_phase(int(CYCLE[_step][0]), String(CYCLE[_step][1]))

func build(world) -> void:
	W = world
	level = MapData.height(Vector2(113.1, 67.0))
	transform = Transform3D(Basis.IDENTITY, Vector3(0.0, level, 0.0))
	W.add_child(self)
	_arrivals()
	_beige_corner()
	_mirador_corner()
	_santa_ana_corner()
	_arcos()
	_sopiss_corner()
	home()
	_commit()                        # (what hangs from the walls and the paint: one mesh for each material)
	for i in range(_parts.size()):
		_raise(i)
	show_phase(0, "verde")

## Something that can be knocked over: it stands at `p`, `make` draws it (called with p: again at each repair), and
## `spec` says what it is to the street's furniture; `tall` and `turn`: its solid.
func _part(what: String, p: Vector2, make: Callable, spec: Dictionary, tall: float, turn := 0.0, wide := 0.0) -> void:
	_parts.append({"name": what, "p": p, "make": make, "spec": spec, "turn": turn,
		"size": Vector3(wide if wide > 0.0 else float(spec["wide"]), tall, float(spec["wide"])), "body": null, "down": false})

## the part `i` stands (again): a body of its own, frozen, with its meshes and its box
func _raise(i: int) -> void:
	var q: Dictionary = _parts[i]
	var p: Vector2 = q["p"]
	var b := RigidBody3D.new()
	b.mass = float(q["spec"]["mass"])
	_base = Transform3D(Basis.IDENTITY, -Vector3(p.x, _g(p), p.y))
	_into = b
	home()
	(q["make"] as Callable).call(p)
	for key in _tools:
		var mi := MeshInstance3D.new()
		mi.mesh = (_tools[key] as SurfaceTool).commit()
		mi.material_override = _material(key)
		b.add_child(mi)
	_tools.clear()
	_into = null
	_base = Transform3D.IDENTITY
	home()
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = q["size"]
	cs.shape = bx
	cs.position.y = bx.size.y / 2.0
	cs.rotation.y = float(q["turn"])
	b.add_child(cs)
	b.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	b.freeze = true
	b.collision_layer = 16           # (as the street's furniture: only people on foot bump into it; a car knocks it over)
	b.collision_mask = 0
	b.position = Vector3(p.x, _g(p), p.y)
	b.set_meta("on_knock", _fell.bind(i))          # (props.gd tells this file the moment it is knocked over)
	if q["spec"]["lights"]:
		b.set_meta("keep", true)                   # (a light knocked over is not swept away after a while: it lies there blinking until repair())
	add_child(b)
	q["body"] = b
	q["down"] = false
	if _props != null:
		_adopt(q)

func home() -> void:
	_xf = _base

## a label goes with the body being drawn, if there is one
func _text(s: String, at: Vector3, px: int, hex: int, pixel := 0.004) -> Label3D:
	var l := super._text(s, at, px, hex, pixel)
	if _into != null:
		remove_child(l)
		_into.add_child(l)
	return l

# ---------------- the roadway: where cars stop ----------------
func _arrivals() -> void:
	var wide: Array = []
	for q in ARRIVALS:
		var na: int = MapData.nearest_node(q[1])
		var nb: int = MapData.nearest_node(q[2])
		var pa: Vector2 = MapData.nodes[na]
		var pb: Vector2 = MapData.nodes[nb]
		var u := (pb - pa).normalized()
		var right := Vector2(-u.y, u.x)                           # (the right of whoever drives in)
		var s = MapData.seg_between(na, nb)
		var hw: float = MapData.fitted_hw(s) if s != null else 3.5
		var single: bool = MapData.one_way_says(na, nb) != 0      # (nobody comes the other way: the whole street is its lane)
		var mid: Vector2 = pb - u * float(q[3])
		heads.append({"name": q[0], "stop": mid if single else mid + right * hw / 2.0, "a": na, "b": nb, "group": q[4],
			"state": "off", "look": -u, "whole": s != null})
		wide.append(hw)
		_paint(mid + right * (-(hw - 0.25) if single else 0.14), mid + right * (hw - 0.25), 0.4)
	# the crossing of the avenue north of the Salvador, which the town's own crossings leave out (its stretch is short)
	var u0: Vector2 = -(heads[0]["look"] as Vector2)
	var r0 := Vector2(-u0.y, u0.x)
	var c0: Vector2 = (MapData.nodes[int(heads[0]["b"])] as Vector2) - u0 * 0.5
	var x := -float(wide[0]) + 0.35
	while x + 0.5 <= float(wide[0]) - 0.3:
		var m := c0 + r0 * (x + 0.25)
		_paint(m - u0 * 1.3, m + u0 * 1.3, 0.5)
		x += 1.0
	walk = [{"name": "avenida", "group": 0, "at": c0, "on": false, "dark": false}]
	for i in [2, 3]:                                              # (Santa Ana's and the Arcos's are the town's own: 4.6 m from their node)
		var ub: Vector2 = -(heads[i]["look"] as Vector2)
		walk.append({"name": heads[i]["name"], "group": heads[i]["group"], "at": (MapData.nodes[int(heads[i]["b"])] as Vector2) - ub * 4.6, "on": false, "dark": false})

## paint on the roadway from a to b, `wide` across, laid on the ground in pieces of a metre
func _paint(a: Vector2, b: Vector2, wide: float) -> void:
	home()
	var ln := a.distance_to(b)
	if ln < 0.05:
		return
	var d := (b - a) / ln
	var n := Vector2(-d.y, d.x) * wide / 2.0
	var k := maxi(1, int(ceil(ln)))
	for i in range(k):
		var p := a.lerp(b, float(i) / k)
		var q := a.lerp(b, float(i + 1) / k)
		flat(PackedVector2Array([p + n, q + n, q - n, p - n]), _g((p + q) / 2.0) + 0.026, "pintura")

# ---------------- the corners ----------------
func _beige_corner() -> void:
	var out := _outward(BEIGE_SE, BEIGE_NE)                       # (east: off its avenue front)
	var look: Vector2 = heads[0]["look"]
	var post := func(f: Vector2) -> void:
		_post(f, 3.45)
		_vehicle(f, 2.92, look, 0)
		_pedestrian(f, 2.12, out, 0)
		_button(f, out.rotated(-PI / 2.0))
	_part("the avenue's post", _stand("the avenue's post", _along(BEIGE_SE, BEIGE_NE, 1.9), out, 1.1), post, LIGHT, 3.45)
	# the cabinet that runs the lights, against the wall, between the corner and the post
	var w := _along(BEIGE_SE, BEIGE_NE, 1.55)
	var cabinet := func(_f: Vector2) -> void:
		_look(w, 0.0, out)
		box(-0.34, -0.3, 0.02, 0.68, 0.42, 0.38, 0x9a9c98)
		box(-0.31, 0.12, 0.03, 0.62, 1.12, 0.34, 0xaeb3b5)
		box(-0.33, 1.24, 0.02, 0.66, 0.04, 0.37, 0x9da2a4)
		box(-0.004, 0.16, 0.37, 0.008, 1.04, 0.004, 0x7d8286)
		box(0.05, 0.66, 0.37, 0.03, 0.1, 0.012, 0x4c5054)
		for k in range(4):
			box(-0.24, 1.0 + k * 0.035, 0.37, 0.18, 0.012, 0.004, 0x7d8286)
	_part("the lights' cabinet", _free("the lights' cabinet", w + out * 0.2), cabinet, CABINET, 1.3, atan2(out.x, out.y), 0.68)
	# no entry into the Salvador (but for the bin lorry), where the corner's pavement begins
	var at := Vector2(0.5, 0.86).normalized()
	var no_entry := func(f: Vector2) -> void:
		_post(f, 2.92, 0.04)
		_sign(f, 2.56, at, 0.04)
		_no_entry()
		_sign(f, 2.02, at, 0.04)
		_sheet(_rect(0.46, 0.34), WHITE)
		for e in [[-0.22, -0.16, 0.44, 0.012], [-0.22, 0.148, 0.44, 0.012], [-0.22, -0.16, 0.012, 0.32], [0.208, -0.16, 0.012, 0.32]]:
			box(e[0], e[1], 0.012, e[2], e[3], 0.003, INK)
		var l := _text("EXCEPTO SERVICIO\nDE RECOGIDA\nDE RESIDUOS", Vector3(0.0, 0.0, 0.017), 40, INK, 0.001)
		l.double_sided = false
		l.line_spacing = -6.0
	_part("no entry into the Salvador", _stand("no entry into the Salvador", _along(BEIGE_SE, BEIGE_NE, 1.05), out, 0.5), no_entry, SIGN, 2.92)

func _mirador_corner() -> void:
	# before the corner's cut: the pedestrians' heads of the avenue's crossing and of Santa Ana's
	var cut := _outward(MIR_C1, MIR_C2)
	var men := func(f: Vector2) -> void:
		_post(f, 2.75)
		_pedestrian(f, 2.3, Vector2(-1.0, 0.0), 0)
		_pedestrian(f, 2.3, Vector2(0.0, 1.0), 1)
		_button(f, Vector2(-0.7, 0.7))
	_part("the post at the bay window's corner", _stand("the post at the bay window's corner", _along(MIR_C1, MIR_C2, 0.6), cut, 1.1), men, LIGHT, 2.75)
	# the tall pole: its arm carries a head out over the lane that comes along Santa Ana
	var out := _outward(MIR_C2, MIR_E)                            # (south: off its Santa Ana front)
	var look: Vector2 = heads[2]["look"]
	var reach := 4.4                                              # (the real arm: 4 to 4.5 m, its head over the lane beside this pavement)
	var pole := func(f: Vector2) -> void:
		home()
		var foot := Vector3(f.x, _g(f), f.y)
		var o3 := Vector3(out.x, 0.0, out.y)
		drum(foot + Vector3(0, -0.3, 0), 0.125, 0.085, 5.9 + 0.3, "poste", 10)
		drum(foot, 0.21, 0.17, 0.32, "poste", 10)
		var pts: Array = []
		for k in range(5):                                        # (the bend: a quarter of a circle)
			var t := PI / 2.0 * k / 4.0
			pts.append(foot + Vector3(0, 5.9, 0) + o3 * (0.9 * (1.0 - cos(t))) + Vector3.UP * (0.9 * sin(t)))
		pts.append(foot + o3 * reach + Vector3.UP * (5.9 + 0.9 + 0.12))
		for k in range(pts.size() - 1):
			bar(pts[k], pts[k + 1], 0.13, 0.13, "poste")
		var tip := f + out * reach
		_look(tip, _g(f) - _g(tip) + 6.3, look)                   # (hung from the arm's end, level with the pole's foot)
		_head(2, true)
		faces += 1
		box(-0.05, 0.47, -0.08, 0.1, 0.2, 0.1, "poste")
		_vehicle(f, 2.92, look, 2, 0.1)
		_pedestrian(f, 2.12, out, 1, 0.1)
		_button(f, Vector2(-1.0, 0.0), 0.1)
	_part("the tall pole", _stand("the tall pole", _along(MIR_C2, MIR_E, 0.5), out, 1.0), pole, POLE, 6.0)
	# no stopping along the avenue's east side
	var no_stopping := func(f: Vector2) -> void:
		_post(f, 2.9, 0.04)
		_sign(f, 2.55, Vector2(0.0, 1.0), 0.04)
		_no_parking(true)
	_part("no stopping on the avenue", _stand("no stopping on the avenue", _along(MIR_C1, MIR_N, 6.2), _outward(MIR_N, MIR_C1), 0.45), no_stopping, SIGN, 2.9)

func _santa_ana_corner() -> void:
	var out := _outward(ANA_B, ANA_A)                             # (north: off its Santa Ana front)
	var look: Vector2 = heads[2]["look"]
	var post := func(f: Vector2) -> void:
		_post(f, 3.45)
		_vehicle(f, 2.92, look, 2)
		_pedestrian(f, 2.12, out, 1)
		_button(f, Vector2(-1.0, 0.0))
	_part("the white house's post", _stand("the white house's post", _along(ANA_A, ANA_B, 2.6), out, 0.85), post, LIGHT, 3.45)
	# the litter bin beside it
	var bin := func(f: Vector2) -> void:
		home()
		var bf := Vector3(f.x, _g(f), f.y)
		for s in [-0.17, 0.17]:
			drum(bf + Vector3(s, -0.2, 0), 0.02, 0.02, 1.0 + 0.2, 0x3a3d40, 6)
		drum(bf + Vector3(0, 0.42, 0), 0.15, 0.19, 0.52, 0x2c2f32, 12)
		drum(bf + Vector3(0, 0.94, 0), 0.205, 0.205, 0.035, 0x1d1f21, 12)
	_part("the litter bin", _stand("the litter bin", _along(ANA_A, ANA_B, 3.3), out, 0.8), bin, BIN, 1.0)
	# at the corner, for whoever comes up the Arcos: no turning right into Santa Ana, and STOP
	var turn := func(f: Vector2) -> void:
		_post(f, 3.15, 0.04)
		_sign(f, 2.78, Vector2(0.0, 1.0), 0.04)
		_no_right()
		_sign(f, 2.08, Vector2(0.0, 1.0), 0.04)
		_stop_sign()
	_part("no right turn and STOP", _free("no right turn and STOP", ANA_A + Vector2(-0.3, -0.4)), turn, SIGN, 3.15)
	# no entry into Santa Ana: it brings cars in, it takes none
	var no_entry := func(f: Vector2) -> void:
		_post(f, 2.85, 0.04)
		_sign(f, 2.5, Vector2(-0.64, -0.77), 0.04)
		_no_entry()
	_part("no entry into Santa Ana", _stand("no entry into Santa Ana", _along(ANA_A, ANA_B, 8.7), out, 0.8), no_entry, SIGN, 2.85)

func _arcos() -> void:
	var look: Vector2 = heads[3]["look"]
	# its east side: the post beside the crossing, at the white house's end
	var oe := _outward(ANA_A, ANA_J)                              # (west: off the Arcos's east fronts)
	var east := func(f: Vector2) -> void:
		_post(f, 3.45)
		_vehicle(f, 2.92, look, 3)
		_pedestrian(f, 2.12, oe, 2)
		_button(f, Vector2(0.0, -1.0))
	_part("the Arcos's east post", _stand("the Arcos's east post", _along(ANA_A, ANA_J, 4.4), oe, 0.9), east, LIGHT, 3.45)
	# its west side: the post at the clinic's corner
	var west := func(f: Vector2) -> void:
		_post(f, 3.45)
		_vehicle(f, 2.92, look, 3)
		_pedestrian(f, 2.12, Vector2(1.0, 0.0), 2)
		_button(f, Vector2(0.0, -1.0))
	_part("the clinic's post", _free("the clinic's post", CLI_X + Vector2(0.45, -0.1)), west, LIGHT, 3.45)
	# no parking, flat on the clinic's wall where the house's doorway ends and the dark stone begins: a small one,
	# with a white arrow in it
	var ow := _outward(CLI_SE, CLI_X)                             # (east: off the clinic's Arcos front)
	var w := _along(CLI_SE, CLI_X, 4.02)
	_look(w + ow * 0.05, 2.82, ow)
	_no_parking(false, 0.24, true)

func _sopiss_corner() -> void:
	# before its avenue front, by the corner of Cervantes: the mirror for whoever comes up the Arcos, and a STOP
	# for whoever comes down the avenue, on one pole
	var oe := _outward(SOP_SE, SOP_NE)                            # (east: off its avenue front)
	var south_east := Vector2(0.62, 0.78).normalized()
	var mirror := func(f: Vector2) -> void:
		_post(f, 3.62, 0.045)
		_sign(f, 3.15, south_east, 0.06)
		_mirror()
		_sign(f, 2.3, Vector2(0.4, -0.92), 0.045)
		_stop_sign()
	_part("the mirror's pole", _stand("the mirror's pole", _along(SOP_SE, SOP_NE, 1.4), oe, 0.35), mirror, SIGN, 3.62)
	# no buses into the Calle Cervantes
	var os := _outward(SOP_SW, SOP_SE)                            # (south: off its Cervantes front)
	var bus := func(f: Vector2) -> void:
		_post(f, 2.9, 0.04)
		_sign(f, 2.55, Vector2(0.97, -0.25), 0.04)
		_bus_ban()
	_part("no buses into Cervantes", _stand("no buses into Cervantes", _along(SOP_SE, SOP_SW, 0.6), os, 0.4), bus, SIGN, 2.9)
	# on its Salvador front, on brackets (the roadway comes up to the wall): give way, and the Salvador's head.
	# These hang from the wall: nothing knocks them over.
	var on := _outward(SOP_NE, SOP_NW)                            # (north: off its Salvador front)
	var look: Vector2 = heads[1]["look"]
	var gw := _along(SOP_NE, SOP_NW, 0.75)
	_look(gw, 0.0, on)
	drum(Vector3(0.0, -0.3, 0.07), 0.04, 0.04, 3.38 + 0.3, "poste", 8)      # (its post, tight against the corner: no pavement to stand on)
	_look(gw, 3.3, on)
	box(-0.02, -0.02, 0.0, 0.04, 0.04, 0.62, "poste")
	box(-0.02, -0.5, 0.0, 0.04, 0.04, 0.62, "poste")
	_look(gw + on * 0.6 + look * 0.03, 3.05, look)
	_give_way()
	var hw := _along(SOP_NE, SOP_NW, 2.4)
	_look(hw, 3.25, on)
	box(-0.025, -0.025, 0.0, 0.05, 0.05, 0.66, "poste")
	box(-0.025, -0.6, 0.0, 0.05, 0.05, 0.66, "poste")
	_look(hw + on * 0.62 + look * 0.14, 2.95, look)
	_head(1)
	faces += 1

# ---------------- where things stand ----------------
## how high the ground is at a spot of the map, in this place's frame
func _g(p: Vector2) -> float:
	return MapData.height(p) - level

## how far a spot is from the asphalt the game draws (0 or less: on it)
func _clear(p: Vector2) -> float:
	var d: float = MapData.road_edge_dist(p)
	if MapData.road_hit != null:
		d += MapData.road_hit.hw - MapData.fitted_hw(MapData.road_hit)
	return d

## Where something stands before a wall: `want` metres out from it, or as far as the game's pavement lets it (the
## real pavements are wider than the game's in places), never nearer the wall than 0.2 m.
func _stand(what: String, wall: Vector2, out: Vector2, want: float) -> Vector2:
	var best := 0.2
	var s := 0.2
	while s <= want + 0.001 and _clear(wall + out * s) >= 0.2:
		best = s
		s += 0.05
	return _free(what, wall + out * best)

func _free(what: String, p: Vector2) -> Vector2:
	stands.append([what, p, _clear(p)])
	yard.append(p)
	return p

## the frame of something at a spot of the map, `y` over the ground there, that looks the way `look` points (+z)
func _look(p: Vector2, y: float, look: Vector2) -> void:
	look = look.normalized()
	_xf = _base * Transform3D(Basis(Vector3(look.y, 0.0, -look.x), Vector3.UP, Vector3(look.x, 0.0, look.y)), Vector3(p.x, _g(p) + y, p.y))

## a round post standing at p
func _post(p: Vector2, tall: float, r := 0.06) -> void:
	home()
	var foot := Vector3(p.x, _g(p), p.y)
	drum(foot + Vector3(0, -0.3, 0), r, r, tall + 0.3, "poste", 8)
	drum(foot, r * 1.8, r * 1.5, 0.14, "poste", 8)
	drum(foot + Vector3(0, tall, 0), r * 1.15, r * 0.4, 0.05, "poste", 8)

## a sign's frame on the post at p: its middle `y` up, looking the way `look` points, just proud of the post
func _sign(p: Vector2, y: float, look: Vector2, r: float) -> void:
	look = look.normalized()
	_look(p + look * (r + 0.004), y, look)

# ---------------- the heads ----------------
## a head of three lights for the street `i` on the post at p, its middle `y` up, looking the way `look` points
func _vehicle(p: Vector2, y: float, look: Vector2, i: int, r := 0.06) -> void:
	look = look.normalized()
	_look(p + look * (r + 0.2), y, look)
	for by in [0.3, -0.34]:
		box(-0.025, by, -0.11 - 0.12, 0.05, 0.045, 0.12, "poste")
	_head(i)
	faces += 1

## the head itself, in the frame of its middle: red over amber over green, each under its hood
func _head(i: int, board := false) -> void:
	if board:                                                     # (the one on the arm: a black board with a white edge behind it)
		box(-0.28, -0.62, -0.13, 0.56, 1.24, 0.014, "caja")
		for e in [[-0.28, -0.62, 0.56, 0.028], [-0.28, 0.592, 0.56, 0.028], [-0.28, -0.62, 0.028, 1.24], [0.252, -0.62, 0.028, 1.24]]:
			box(e[0], e[1], -0.116, e[2], e[3], 0.003, WHITE)
	box(-0.15, -0.47, -0.11, 0.3, 0.94, 0.22, "caja")
	for k in range(3):
		var cy := 0.3 - k * 0.3
		slab(oval(0.0, cy, 0.1, 0.1, 12), 0.119, 0.008, "luz_%d_%s" % [i, COLOURS[k]])
		box(-0.127, cy + 0.105, 0.11, 0.254, 0.018, 0.17, "caja")
		box(-0.127, cy - 0.01, 0.11, 0.018, 0.12, 0.1, "caja")
		box(0.109, cy - 0.01, 0.11, 0.018, 0.12, 0.1, "caja")

## a pedestrians' head for the crossing `i` on the post at p
func _pedestrian(p: Vector2, y: float, look: Vector2, i: int, r := 0.06) -> void:
	look = look.normalized()
	_look(p + look * (r + 0.17), y, look)
	box(-0.025, -0.02, -0.09 - 0.1, 0.05, 0.045, 0.1, "poste")
	box(-0.14, -0.3, -0.09, 0.28, 0.6, 0.18, "caja")
	box(-0.15, 0.3, -0.09, 0.3, 0.018, 0.3, "caja")
	box(-0.15, 0.0, 0.09, 0.018, 0.3, 0.1, "caja")
	box(0.132, 0.0, 0.09, 0.018, 0.3, 0.1, "caja")
	var red := "peaton_%d_rojo" % i
	var green := "peaton_%d_verde" % i
	var z := 0.092
	# the red man, standing
	box(-0.024, 0.212, z, 0.048, 0.048, 0.005, red)
	box(-0.04, 0.105, z, 0.08, 0.098, 0.005, red)
	box(-0.034, 0.03, z, 0.028, 0.078, 0.005, red)
	box(0.006, 0.03, z, 0.028, 0.078, 0.005, red)
	# the green man, walking
	box(-0.008, -0.088, z, 0.048, 0.048, 0.005, green)
	bar(Vector3(0.012, -0.095, z + 0.003), Vector3(-0.012, -0.185, z + 0.003), 0.005, 0.07, green)
	bar(Vector3(-0.012, -0.18, z + 0.003), Vector3(-0.062, -0.265, z + 0.003), 0.005, 0.03, green)
	bar(Vector3(-0.012, -0.18, z + 0.003), Vector3(0.05, -0.265, z + 0.003), 0.005, 0.03, green)
	bar(Vector3(0.0, -0.11, z + 0.003), Vector3(0.06, -0.16, z + 0.003), 0.005, 0.022, green)
	walk_faces += 1

## the yellow box of the button people press to cross
func _button(p: Vector2, look: Vector2, r := 0.06) -> void:
	look = look.normalized()
	_look(p + look * (r - 0.005), 1.15, look)
	box(-0.055, -0.09, 0.0, 0.11, 0.18, 0.07, 0xe2b93a)
	box(-0.02, -0.02, 0.07, 0.04, 0.04, 0.008, 0x2a2c2f)

# ---------------- the signs (each in the frame of its middle, looking +z) ----------------
func _disc(r: float, n := 18) -> PackedVector2Array:
	return oval(0.0, 0.0, r, r, n)

func _rect(w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-w / 2.0, -h / 2.0), Vector2(w / 2.0, -h / 2.0), Vector2(w / 2.0, h / 2.0), Vector2(-w / 2.0, h / 2.0)])

func _octagon(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(8):
		var a := TAU * (i + 0.5) / 8.0                            # (a flat edge on top, as the real ones)
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts

func _point_down(side: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-side / 2.0, side * 0.2887), Vector2(side / 2.0, side * 0.2887), Vector2(0.0, -side * 0.5774)])

## a sign's sheet: its face and its edge in `key`, and its bare back
func _sheet(pts: PackedVector2Array, key) -> void:
	slab(pts, 0.012, 0.012, key)
	var keep := _xf
	_xf = _xf * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
	var back := PackedVector2Array()
	for q in pts:
		back.append(Vector2(-q.x, q.y))
	slab(back, 0.0, 0.0, "dorso")
	_xf = keep
	signs += 1

func _no_entry() -> void:
	_sheet(_disc(0.3), RED)
	box(-0.2, -0.05, 0.012, 0.4, 0.1, 0.004, WHITE)

func _stop_sign() -> void:
	_sheet(_octagon(0.345), WHITE)
	slab(_octagon(0.31), 0.016, 0.0, RED)
	var l := _text("STOP", Vector3(0.0, 0.0, 0.02), 50, 0xffffff, 0.0042)
	l.double_sided = false

func _no_right() -> void:
	_sheet(_disc(0.3), RED)
	slab(_disc(0.225), 0.016, 0.0, WHITE)
	box(-0.09, -0.13, 0.016, 0.05, 0.2, 0.004, INK)               # (the arrow: up...
	box(-0.09, 0.03, 0.016, 0.13, 0.05, 0.004, INK)               # ...and round to the right)
	slab(PackedVector2Array([Vector2(0.04, 0.12), Vector2(0.135, 0.055), Vector2(0.04, -0.01)]), 0.02, 0.0, INK)
	bar(Vector3(-0.17, 0.17, 0.024), Vector3(0.17, -0.17, 0.024), 0.004, 0.05, RED)

func _give_way() -> void:
	_sheet(_point_down(0.9), RED)
	slab(_point_down(0.58), 0.016, 0.0, WHITE)

func _bus_ban() -> void:
	_sheet(_disc(0.3), RED)
	slab(_disc(0.225), 0.016, 0.0, WHITE)
	box(-0.15, -0.045, 0.016, 0.3, 0.13, 0.004, INK)              # (the bus...
	for k in range(4):
		box(-0.136 + k * 0.07, 0.022, 0.02, 0.05, 0.045, 0.002, WHITE)      # ...its windows...
	for x in [-0.105, 0.06]:
		box(x, -0.078, 0.016, 0.045, 0.04, 0.004, INK)            # ...and its wheels)

## no parking (one red stroke over blue), `r` its radius; `both`: no stopping either (two strokes); `arrow`: a white
## arrow in it, pointing left (it holds from here that way)
func _no_parking(both := false, r := 0.3, arrow := false) -> void:
	var k := r / 0.3
	_sheet(_disc(r), RED)
	slab(_disc(0.225 * k), 0.016, 0.0, BLUE)
	if arrow:
		box(-0.07 * k, -0.137 * k, 0.016, 0.14 * k, 0.03 * k, 0.003, WHITE)
		slab(PackedVector2Array([Vector2(-0.125 * k, -0.122 * k), Vector2(-0.06 * k, -0.074 * k), Vector2(-0.06 * k, -0.17 * k)]), 0.02, 0.0, WHITE)
	bar(Vector3(-0.17 * k, 0.17 * k, 0.022), Vector3(0.17 * k, -0.17 * k, 0.022), 0.004, 0.055 * k, RED)
	if both:
		bar(Vector3(0.17 * k, 0.17 * k, 0.022), Vector3(-0.17 * k, -0.17 * k, 0.022), 0.004, 0.055 * k, RED)

## the round mirror of the blind corner: black rim, orange shell behind
func _mirror() -> void:
	slab(_disc(0.43, 20), 0.03, 0.08, 0x1c1d1f)
	slab(_disc(0.385, 20), 0.036, 0.0, "espejo")
	slab(oval(-0.12, 0.15, 0.12, 0.07, 10), 0.04, 0.0, 0xeef4f7)
	var keep := _xf
	_xf = _xf * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
	slab(_disc(0.43, 20), 0.05, 0.0, 0xc8502f)
	slab(_disc(0.2, 12), 0.09, 0.04, 0xc8502f)
	_xf = keep
	signs += 1
