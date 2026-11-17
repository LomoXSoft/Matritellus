extends VehicleBody3D
## A drivable car on Godot's vehicle physics: rigid body, four sprung wheels, real collisions, bodywork that wears out.
## game.gd feeds it throttle/steer/handbrake through drive(); p, h and vel mirror the 2D view the rest of the game uses.
## The models are affectionate parodies of the cars every Manchego village is full of — not the real makes.
##
## spec keys beyond the obvious sizes:
##   offroad   share of the top speed kept off the road (default 0.55)
##   custom    the bodywork is built by its own function instead of the generic box-and-cab
##   tractor   drives all four wheels, fells trees at walking pace, potters about in traffic
##   rear      how much bigger the rear wheels are          hub     colour of the wheel centres
##   sound     "car" (default) | "diesel" | "electric"       smoke   how much it smokes (0 = no exhaust at all)
##   colors    the colours it comes in (ask for any other and you get one of these)
##   pipe      where the exhaust ends, if not low at the back
##   turbo     {max, acc}: how much the top speed and the acceleration are multiplied while the turbo is held
##   rack_z    where along the car the oil bottles ride

const Parts = preload("res://scripts/parts.gd")
const Chara = preload("res://scripts/chara.gd")
const Modelos = preload("res://scripts/modelos.gd")
const GROUND := 0.04            # where the road is under a car standing on its springs, from the car's own origin
static var old_look := false    # build the cars of boxes that these were before their models (for telling them apart)
## The world held still (the pause, the big map: game.gd _hold_world). The physics does not move then, but a force
## given to a body waits for the next step -- and the parked cars' spring and every car's anti-roll bar were given
## theirs every tick all the same: after a minute's pause they all went off at once, "todos los coches explotan
## contra una pared" (the user, 17 Nov 2026). Held, a car gives itself nothing.
static var held := false

const SPECS := {
	"panda": {"name": "Zeat Panda", "max": 25.0, "acc": 6.5, "turn": 0.55, "mass": 850.0, "hp": 100.0, "len": 3.5, "wid": 1.75, "body": 0.8, "cab": 0.72, "cab_len": 2.3, "cab_z": -0.4, "wheel": 0.36,
		"colors": [0x6fb7e6, 0xe6c229, 0xf4f4f0, 0x8d99ae, 0xf3e2b3, 0x3b5fa8, 0xef7f1a, 0x8a6a48, 0xef8fa9, 0x26262b]},
	"z15": {"name": "Z15", "offroad": 0.9, "max": 23.0, "acc": 5.2, "turn": 0.5, "mass": 1150.0, "hp": 140.0, "len": 4.3, "wid": 1.85, "body": 0.75, "cab": 0.68, "cab_len": 1.25, "cab_z": 0.55, "wheel": 0.38, "box": [2.25, 1.3, -1.0],
		"smoke": 2.4, "colors": [0xf4f4f0, 0xc9ced3, 0x1f1f24]},
	"tractor": {"name": "Súper Hebro 555", "max": 11.0, "acc": 4.5, "turn": 0.6, "mass": 2800.0, "hp": 320.0, "len": 3.5, "wid": 1.9, "body": 0.9, "cab": 0.0, "cab_len": 1.25, "cab_z": -0.75, "wheel": 0.5, "offroad": 1.0,
		"custom": true, "tractor": true, "rear": 1.7, "hub": 0xe8dfc0, "sound": "diesel", "smoke": 3.0, "rack_z": 0.7, "colors": [0x3f8fd0, 0xc8281e], "pipe": Vector3(0.28, 2.6, 1.0)},
	"yondir": {"name": "Yondir", "max": 16.0, "acc": 6.0, "turn": 0.55, "mass": 4200.0, "hp": 520.0, "len": 4.6, "wid": 2.3, "body": 1.0, "cab": 1.3, "cab_len": 1.6, "cab_z": -0.6, "wheel": 0.62, "offroad": 1.0,
		"custom": true, "tractor": true, "rear": 1.45, "hub": 0xf2c81e, "sound": "diesel", "smoke": 2.2, "colors": [0x2f8a3a], "pipe": Vector3(0.72, 3.4, 0.35)},
	"tunero": {"name": "El Tunero", "max": 33.0, "acc": 9.5, "turn": 0.5, "mass": 950.0, "hp": 80.0, "len": 4.0, "wid": 1.85, "body": 0.6, "cab": 0.5, "cab_len": 1.8, "cab_z": -0.3, "wheel": 0.36, "spoiler": true, "smoke": 1.4, "colors": [0x7d3fc4, 0xe6b422, 0x1f1f24], "turbo": {"max": 1.22, "acc": 1.5}},
	"edison": {"name": "Edison Model Y", "max": 34.0, "acc": 12.0, "turn": 0.52, "mass": 1900.0, "hp": 130.0, "len": 4.7, "wid": 1.95, "body": 0.62, "cab": 0.62, "cab_len": 2.6, "cab_z": -0.4, "wheel": 0.4,
		"custom": true, "hub": 0x4a4d52, "sound": "electric", "smoke": 0.0, "colors": [0xf4f4f0, 0x1f1f24]},
	"julietta": {"name": "Omega Julietta", "max": 37.0, "acc": 10.5, "turn": 0.52, "mass": 1250.0, "hp": 90.0, "len": 4.4, "wid": 1.86, "body": 0.52, "cab": 0.0, "cab_len": 1.4, "cab_z": -0.6, "wheel": 0.37,
		"custom": true, "hub": 0xd8dde2, "smoke": 1.2, "rack_z": -1.7, "colors": [0xd42027, 0x39e639], "turbo": {"max": 1.45, "acc": 1.9}},
	"grua": {"name": "Grúa El Enganche", "max": 17.0, "acc": 5.0, "turn": 0.6, "mass": 3200.0, "hp": 400.0, "len": 6.0, "wid": 2.1, "body": 0.85, "cab": 0.9, "cab_len": 1.7, "cab_z": 0.85, "wheel": 0.44,
		"custom": true, "hub": 0xd8dde2, "sound": "diesel", "smoke": 1.8, "rack_z": -1.6, "colors": [0xf4f4f0]},
	"tricornio": {"name": "Nisán Patrulla de los Tricornios", "max": 36.0, "acc": 11.5, "turn": 0.64, "mass": 1400.0, "hp": 9999.0, "len": 4.3, "wid": 1.85, "body": 0.9, "cab": 0.78, "cab_len": 2.5, "cab_z": -0.35, "wheel": 0.42,
		"offroad": 0.9, "colors": [0xf4f4f0]},
	"pitufo": {"name": "Zeat Panda de los Pitufos", "max": 28.0, "acc": 8.0, "turn": 0.6, "mass": 900.0, "hp": 9999.0, "len": 3.5, "wid": 1.75, "body": 0.8, "cab": 0.72, "cab_len": 2.3, "cab_z": -0.4, "wheel": 0.36, "colors": [0x2456b8]},
}

static var _puff_mesh: SphereMesh
static var _head_on: StandardMaterial3D
static var _tail_on: StandardMaterial3D

var kind := ""
var paint := 0
var spec: Dictionary
var r := 1.0             # rough radius, for bumping villagers and street furniture
var off := 1.0           # nose/tail offset of those bump circles
var crash_cool := 0.0
var hp := 100.0          # bodywork: 0 = it will not move again until repaired
var inner: Node3D
var bottles: Array = []
var wheels: Array = []
var lights: Array = []   # police light bar halves
var smoke: CPUParticles3D
var running := false     # the engine has been started (it coughs smoke the first time you give it throttle)
var vapour: CPUParticles3D    # the exhaust while moving
var turbo := false       # held down by whoever is driving (only does anything on a car that has one)
var boosting := false    # the turbo is actually pushing right now
var nitro := 1.0         # what is left in the bottle, 0..1: it burns down while the turbo pushes and fills as you drive fast
var burnt := false       # emptied it: burnt out, and no use until it has filled a good way again
const NITRO_BURN := 5.0       # seconds a full bottle lasts
const NITRO_FILL := 16.0      # seconds to fill it, flat out
const NITRO_BACK := 0.35      # how full it has to get before a burnt-out one works again
var flame: CPUParticles3D
var lit := false           # lights on
var model: Node3D          # its bodywork, where it has one made for it (modelos.gd); null on a car of boxes
var _glows: Array = []     # on a model: the lamps that show only when they are lit [mesh, is it a headlamp]
var _pipe_at = null        # on a model: where its upright exhaust ends
var riders: Array = [{}, {}]      # the looks of whoever is at the wheel and of whoever sits beside them ({} = nobody)
var _rider_nodes: Array = [null, null]
static var _glass: StandardMaterial3D
var dozing := false        # parked and far from anybody: taken out of the physics until somebody comes near
var _heads: Array = []     # [mesh, its daytime material]
var _tails: Array = []
var _beam: SpotLight3D
var cough: CPUParticles3D     # the cloud when it starts
var _cough := 0.0
var _thr := 0.0
var air_time := 0.0      # seconds with all four wheels off the ground
var air_from := Vector2.ZERO
var _held := false        # parked and tied to where it stopped (see _physics_process)
var _held_at := Vector2.ZERO
var last_air := 0.0      # length (s) of the jump that just ended; game.gd reads and clears it
var _prev_v := Vector3.ZERO
var _flipped := 0.0
var pushes := 0          # shoves received while lying flipped (three put it back on its wheels)
var speed_boost := 1.0   # top speed and pull, times this (the police chasing you out of town: limite.gd)
var flip_told := false
var last_impact := 0.0   # set when the speed changed violently this physics tick; game.gd reads and clears it

var p: Vector2:
	get:
		return Vector2(global_position.x, global_position.z)
var h: float:
	get:
		return atan2(global_transform.basis.z.x, global_transform.basis.z.z)
var vel: Vector2:
	get:
		return Vector2(linear_velocity.x, linear_velocity.z)

func _p(part_kind: String, hex: int, pos: Vector3, scl: Vector3) -> MeshInstance3D:
	var m := Parts.part(part_kind, hex, pos, scl)
	if hex == 0xcfe8f2:                     # window glass: you see who is inside
		if _glass == null:
			_glass = StandardMaterial3D.new()
			_glass.albedo_color = Color(0.78, 0.9, 0.95, 0.38)
			_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_glass.roughness = 0.2
			_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.material_override = _glass
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inner.add_child(m)
	return m

## Somebody in a seat (0 at the wheel, 1 beside the driver): the person themselves, sitting (see rider).
## `o` is a look as chara.gd takes it; {} empties the seat.
func seat(o: Dictionary, place := 0) -> void:
	if _rider_nodes[place] != null:
		_rider_nodes[place].queue_free()
		_rider_nodes[place] = null
	riders[place] = o
	if o.is_empty() or inner == null:
		return
	var wid: float = spec["wid"]
	var sill: float = float(spec["wheel"]) + 0.15 + float(spec["body"])
	var mid: bool = spec.get("tractor", false)
	var n := rider(o, place == 0, float(model.get_meta("rider")) if model != null else RIDER)
	n.position = Vector3(0.0 if mid else wid * (0.23 if place == 0 else -0.23), sill - (0.38 if float(spec["cab"]) >= 0.6 else 0.5), float(spec["cab_z"]) + float(spec["cab_len"]) * 0.08)
	if model != null:               # the seat the model has
		var at: Vector3 = model.get_meta("seat")
		if place == 1:
			at = Vector3(-at.x, at.y, at.z) if at.x != 0.0 else at + Vector3(-0.42, -0.08, -0.3)      # (on a tractor: perched on the mudguard)
		n.position = at + Vector3(0, GROUND, 0)
	inner.add_child(n)
	_rider_nodes[place] = n

## Somebody sitting, their seat at the node's own origin (`driving`: hands out on a wheel). It is the person
## themselves, as they walk about the town (chara.gd) -- the same face, hair, hat and clothes -- only smaller: the
## people of this town have heads as big as a car door, and a car has to hold two of them side by side. How much
## smaller is for each car to say (`size`: a tall cab or an open tractor takes them nearly as they are).
const RIDER := 0.46
static func rider(o: Dictionary, driving: bool, size := RIDER) -> Node3D:
	var n := Node3D.new()
	var who = Chara.new()
	var figure: Node3D = who.sit(o, driving)
	who.free()
	var held := Node3D.new()            # (the figure keeps its own size: a child is smaller than a grown-up in a seat too)
	held.scale = Vector3.ONE * size
	held.add_child(figure)
	n.add_child(held)
	if driving:
		var wheel := Parts.part("ring_thin", 0x1b1b1f, Vector3(0, 0.33, 0.43) * (size / RIDER), Vector3.ONE * 0.17 * (size / RIDER))
		wheel.rotation.x = 1.15
		wheel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(wheel)
	return n

## The make's own shape to bump into things with, for one whose box was a lot bigger than the car that is seen (the
## Z15: the air over its sloping bonnet, and the width of its mirrors all down its length: the user, 14 November
## 2026). Slices along its length, each as wide and as high as the bodywork is there (the mirrors left out), between
## the same floor and ceiling the box had. Worked out once for each make.
static var _hulls := {}
const HULL_SLICE := 0.15
func _hull(pts: PackedVector3Array, foot: float, ceiling: float) -> ConvexPolygonShape3D:
	if _hulls.has(kind):
		return _hulls[kind]
	var xs: Array = []
	for q in pts:
		xs.append(absf(q.x))
	xs.sort()
	var half: float = xs[int(xs.size() * 0.95)] if not xs.is_empty() else float(spec["wid"]) / 2.0      # (the mirrors are the last few)
	var slices := {}                            # slice -> [widest, highest, front, back]
	for q in pts:
		var k := int(floor(q.z / HULL_SLICE))
		var w := minf(absf(q.x), half)
		var y := clampf(q.y + GROUND, foot, ceiling)
		if not slices.has(k):
			slices[k] = [w, y, q.z, q.z]
		else:
			var s: Array = slices[k]
			s[0] = maxf(s[0], w); s[1] = maxf(s[1], y); s[2] = minf(s[2], q.z); s[3] = maxf(s[3], q.z)
	var out := PackedVector3Array()
	for k in slices:
		var s: Array = slices[k]
		for z in [s[2], s[3]]:
			for x in [-s[0], s[0]]:
				out.append(Vector3(x, foot, z))
				out.append(Vector3(x, maxf(s[1], foot + 0.3), z))
	var shape := ConvexPolygonShape3D.new()
	shape.points = out
	_hulls[kind] = shape
	return shape

## The make's shape to bump into and to stand on (the user, 17 Nov 2026: "Se podría dar la hitbox de los coches un poco
## menos cúbica. Me gustaría poder subirme a un capó de un salto"): boxes one after another along its length, each as
## high and as wide as the bodywork is there -- the bonnet low, the cabin high, the boot -- the mirrors left out, between
## the floor and the ceiling the one box had. Worked out once for each make. `profile` is the same, to stand on (top_at).
static var _steps := {}
const STEP_SLICE := 0.2
const STEP_MERGE := 0.18             # slices within this of each other in height are one box
const STEP_MAX := 6
var profile: Array = []              # [z from, z to, top, half width] in its own frame: what top_at reads
func _stepped(pts: PackedVector3Array, foot: float, ceiling: float) -> Array:
	if _steps.has(kind):
		return _steps[kind]
	var xs: Array = []
	for q in pts:
		xs.append(absf(q.x))
	xs.sort()
	var half: float = xs[int(xs.size() * 0.95)] if not xs.is_empty() else float(spec["wid"]) / 2.0      # (the mirrors are the last few)
	var slices := {}                            # slice -> [highest, widest]
	for q in pts:
		var k := int(floor(q.z / STEP_SLICE))
		var y := clampf(q.y + GROUND, foot, ceiling)
		var w := minf(absf(q.x), half)
		if not slices.has(k):
			slices[k] = [y, w]
		else:
			slices[k][0] = maxf(slices[k][0], y)
			slices[k][1] = maxf(slices[k][1], w)
	var keys: Array = slices.keys()
	keys.sort()
	var secs: Array = []                        # [z from, z to, top, half width]
	for k in keys:
		var z0: float = k * STEP_SLICE
		var top: float = slices[k][0]
		var w: float = slices[k][1]
		if not secs.is_empty() and absf(float(secs[-1][2]) - top) < STEP_MERGE:
			var sc: Array = secs[-1]
			sc[1] = z0 + STEP_SLICE
			sc[2] = maxf(sc[2], top)
			sc[3] = maxf(sc[3], w)
		else:
			if not secs.is_empty():
				secs[-1][1] = z0                    # (no gap between one box and the next)
			secs.append([z0, z0 + STEP_SLICE, top, w])
	while secs.size() > STEP_MAX:                 # too many: the two neighbours nearest in height become one
		var at := 0
		var nearest := 1e9
		for i in range(secs.size() - 1):
			var dh := absf(float(secs[i][2]) - float(secs[i + 1][2]))
			if dh < nearest:
				nearest = dh
				at = i
		var a: Array = secs[at]
		var b: Array = secs[at + 1]
		secs[at] = [a[0], b[1], maxf(a[2], b[2]), maxf(a[3], b[3])]
		secs.remove_at(at + 1)
	var shapes: Array = []
	for sc in secs:
		var bx := BoxShape3D.new()
		bx.size = Vector3(2.0 * float(sc[3]), maxf(0.3, float(sc[2]) - foot), float(sc[1]) - float(sc[0]))
		shapes.append([bx, Vector3(0.0, foot + bx.size.y / 2.0, (float(sc[0]) + float(sc[1])) / 2.0)])
	var out := [shapes, secs]
	_steps[kind] = out
	return out

## how high its roof, its bonnet or its boot is over this spot of the map (the height in the world), or -INF if the spot
## is not over it (game.gd car_floor_at: somebody standing on a car)
func top_at(q: Vector2) -> float:
	if profile.is_empty():
		return -INF
	var local := global_transform.affine_inverse() * Vector3(q.x, global_position.y, q.y)
	for sc in profile:
		if local.z >= float(sc[0]) and local.z <= float(sc[1]) and absf(local.x) <= float(sc[3]):
			return (global_transform * Vector3(local.x, float(sc[2]), local.z)).y
	return -INF

func setup(kind_: String, hex: int, pos: Vector2, heading: float) -> void:
	kind = kind_
	spec = SPECS[kind]
	if spec.has("colors") and not (hex in spec["colors"]):       # each make only comes in its own colours
		hex = spec["colors"].pick_random()
	paint = hex
	hp = spec["hp"]
	r = spec["wid"] * 0.6
	off = spec["len"] * 0.27
	var wid: float = spec["wid"]; var length: float = spec["len"]; var bh: float = spec["body"]; var cab: float = spec["cab"]
	var wr: float = spec["wheel"]
	var black := 0x26262b
	mass = spec["mass"]
	collision_layer = 2
	collision_mask = 1 | 2 | 8 | 32            # world, cars, trees, loose debris
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, 0.25, 0)          # low, so it corners flat instead of rolling over
	angular_damp = 0.6
	continuous_cd = true

	var by := wr + 0.15 + bh / 2.0
	var top := by + bh / 2.0 + cab
	inner = Node3D.new()
	add_child(inner)
	var msize := Vector3.ZERO
	if Modelos.SK.has(kind) and not old_look:
		model = Modelos.make_from(Modelos.SK, kind, spec, hex)
		model.position.y = GROUND
		inner.add_child(model)
		msize = model.get_meta("size")
		Modelos.cloud(kind, model)          # (before its wheels go to their springs)
	var box := BoxShape3D.new()
	box.size = Vector3(wid, bh + cab * 0.8, length)
	var cs := CollisionShape3D.new()
	cs.shape = box
	cs.position = Vector3(0, by + cab * 0.4, 0)
	if model != null:                       # no taller than the car that is seen (nor than the car of boxes was: masts and stacks do not count)
		var box_top: float = minf(by + bh / 2.0 + cab * 0.8, GROUND + msize.y)
		var box_foot: float = minf(by - bh / 2.0, box_top - 0.55)
		box.size.y = box_top - box_foot
		cs.position.y = (box_top + box_foot) / 2.0
		top = GROUND + msize.y
		var st: Array = _stepped(Modelos.cloud(kind, model), box_foot, box_top)
		profile = st[1]
		for sh in st[0]:
			var part := CollisionShape3D.new()
			part.shape = sh[0]
			part.position = sh[1]
			add_child(part)
	else:
		profile = [[-length / 2.0, length / 2.0, cs.position.y + box.size.y / 2.0, wid / 2.0]]
		add_child(cs)
	if model == null:
		top = _box_body(hex, by, top)
	else:
		for part in model.get_children():
			if String(part.name).begins_with("luz"):
				lights.append(part)
		if kind == "grua":              # its name down both sides of the bed
			for sx in [-1.0, 1.0]:
				var name := Label3D.new()
				name.text = "GRÚAS EL ENGANCHE · 24 h (o cuando pueda)"
				name.font_size = 44
				name.pixel_size = 0.0036
				name.modulate = Color("f4f2ea")
				name.outline_size = 0
				name.shaded = true
				name.position = Vector3(sx * (msize.x * 0.47 + 0.035), GROUND + msize.y * 0.445 + 0.08, -msize.z * 0.245)
				name.rotation.y = sx * PI / 2.0
				inner.add_child(name)

	# wheels: front pair steers, rear pair drives (tractors drive all four)
	var hub: int = spec.get("hub", 0x9aa0a6)
	var rear: float = spec.get("rear", 1.0)
	var all_four: bool = spec.get("tractor", false)
	for sz in [1.0, -1.0]:
		for sx in [-1.0, 1.0]:
			var big := rear if sz < 0.0 else 1.0
			var fat := 0.3 * (1.55 if (all_four and sz < 0.0) else 1.0)
			var w := VehicleWheel3D.new()
			w.wheel_radius = wr * big
			w.wheel_rest_length = 0.18
			w.suspension_travel = 0.18
			w.suspension_stiffness = 38.0
			w.suspension_max_force = mass * 40.0
			w.damping_compression = 2.2
			w.damping_relaxation = 3.2
			w.wheel_friction_slip = 3.2 if sz > 0.0 else 2.8
			w.wheel_roll_influence = 0.02
			w.use_as_steering = sz > 0.0
			w.use_as_traction = sz < 0.0 or all_four
			w.position = Vector3(sx * (wid / 2.0 - 0.05), wr * big + 0.16, sz * length * 0.32)
			var own: MeshInstance3D = null      # the model's wheel at this corner: it goes on the spring, and the spring where it was
			if model != null:
				for cand in model.get_meta("wheels"):
					if cand.get_parent() == model and signf(cand.position.x) == sx and signf(cand.position.z) == sz:
						own = cand
			if own != null:
				var rad: float = own.position.y         # (the model stands on the ground: its axle is as high as the wheel is big)
				w.wheel_radius = rad
				w.position = Vector3(own.position.x, GROUND + rad + 0.12, own.position.z)
				model.remove_child(own)
				own.position = Vector3.ZERO
				w.add_child(own)
			else:
				var tyre := Parts.part("cyl", 0x2b2b30, Vector3.ZERO, Vector3(wr * big, fat, wr * big))
				tyre.rotation.z = PI / 2.0
				w.add_child(tyre)
				var cap := Parts.part("cyl", hub, Vector3(sx * (fat / 2.0 - 0.03), 0, 0), Vector3(wr * big * 0.55, 0.1, wr * big * 0.55))
				cap.rotation.z = PI / 2.0
				w.add_child(cap)
			add_child(w)
			wheels.append(w)

	# the oil bottles ride on the roof (or wherever there is a flat bit)
	var rack := Node3D.new()
	var rack_z: float = spec["box"][2] if spec.has("box") else float(spec.get("rack_z", spec["cab_z"] if cab > 0.0 else -0.5))
	rack.position = Vector3(0, top + 0.1, rack_z)
	if model != null:
		var where: Array = Modelos.SK[kind].get("rack", [0.0, 1.0])
		var under: Vector3 = Modelos.top_at(kind, model, msize.z * float(where[0]) - 0.3, msize.z * float(where[0]) + 0.3, 0.2)
		var roof: float = msize.y * float(where[1])
		var deck: float = minf(under.y, roof)
		if deck < roof * 0.6:                     # (a closed body: what was found there is its floor, seen through a window. On the roof, then)
			deck = roof
		rack.position = Vector3(0, GROUND + deck + 0.01, msize.z * float(where[0]))
	inner.add_child(rack)
	for i in range(6):
		var b := Node3D.new()
		b.add_child(Parts.part("cyl", 0xd8c53a, Vector3(0, 0.22, 0), Vector3(0.11, 0.44, 0.11)))
		b.add_child(Parts.part("cyl", 0x5a7a1e, Vector3(0, 0.52, 0), Vector3(0.05, 0.18, 0.05)))
		b.position = Vector3((i % 3 - 1) * (0.36 if spec.get("rack_z", 0.0) == 0.0 else 0.2), 0, -0.2 if i < 3 else 0.2)
		b.visible = false
		rack.add_child(b)
		bottles.append(b)

	# smoke from under the bonnet once the bodywork is nearly gone
	smoke = CPUParticles3D.new()
	smoke.position = Vector3(0, by + bh / 2.0, length * 0.3)
	if model != null:
		smoke.position = Vector3(0, GROUND + msize.y * 0.55, length * 0.34)
		if spec.has("pipe"):                # an upright exhaust: the highest thing ahead of the driver
			_pipe_at = Modelos.top_at(kind, model, msize.z * 0.12, msize.z * 0.5, 0.5) + Vector3(0, GROUND, 0)
	smoke.amount = 24
	smoke.lifetime = 1.4
	smoke.direction = Vector3.UP
	smoke.spread = 20.0
	smoke.gravity = Vector3(0, 1.5, 0)
	smoke.initial_velocity_min = 1.0
	smoke.initial_velocity_max = 2.2
	smoke.scale_amount_min = 0.5
	smoke.scale_amount_max = 1.1
	var sm := SphereMesh.new()
	sm.radius = 0.3; sm.height = 0.6; sm.radial_segments = 8; sm.rings = 4
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.2, 0.2, 0.22, 0.75)
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.material = smat
	smoke.mesh = sm
	smoke.emitting = false
	add_child(smoke)
	# which bits are lamps: anything painted headlamp yellow or white, and the red ones behind
	for m in inner.get_children():
		if m is MeshInstance3D:
			if m.material_override == Parts.mat(0xfff3a8) or m.material_override == Parts.mat(0xf4f8ff):
				_heads.append([m, m.material_override])
			elif m.material_override == Parts.mat(0xd23b2e):
				_tails.append([m, m.material_override])
	place(pos, heading)
	Parts.thin(self)                             # (its small parts are not drawn from far away)

## The bodywork made of boxes, as every car was before it had a model (and still is where it has none). Returns how
## high it stands.
func _box_body(hex: int, by: float, top: float) -> float:
	var wid: float = spec["wid"]; var length: float = spec["len"]; var bh: float = spec["body"]; var cab: float = spec["cab"]
	var black := 0x26262b
	if not spec.get("custom", false):
		_p("box", hex, Vector3(0, by, 0), Vector3(wid, bh, length))
		if cab > 0.0:
			_p("box", 0xcfe8f2, Vector3(0, by + bh / 2.0 + cab / 2.0, spec["cab_z"]), Vector3(wid * 0.9, cab, spec["cab_len"]))
			_p("box", hex, Vector3(0, top + 0.04, spec["cab_z"]), Vector3(wid * 0.94, 0.09, spec["cab_len"] + 0.08))
			for sx in [-1.0, 1.0]:      # door pillars
				_p("box", hex, Vector3(sx * wid * 0.45, by + bh / 2.0 + cab / 2.0, spec["cab_z"]), Vector3(0.07, cab, 0.12))
		for sx in [-1.0, 1.0]:
			_p("box", 0xfff3a8, Vector3(sx * wid * 0.33, by + 0.1, length / 2.0 + 0.01), Vector3(0.3, 0.24, 0.06))    # square headlights
			_p("box", 0xf08a2a, Vector3(sx * wid * 0.47, by + 0.1, length / 2.0 - 0.05), Vector3(0.08, 0.24, 0.16))  # indicators
			_p("box", 0xd23b2e, Vector3(sx * wid * 0.36, by + 0.05, -length / 2.0 - 0.01), Vector3(0.28, 0.18, 0.06))
	match kind:
		"panda", "pitufo":      # boxy, with the black plastic belly and bumpers
			_p("box", black, Vector3(0, by - bh * 0.28, 0), Vector3(wid + 0.04, bh * 0.44, length - 0.5))
			_p("box", black, Vector3(0, by - bh * 0.25, length / 2.0), Vector3(wid + 0.06, bh * 0.42, 0.22))
			_p("box", black, Vector3(0, by - bh * 0.25, -length / 2.0), Vector3(wid + 0.06, bh * 0.42, 0.22))
			_p("box", 0x33363b, Vector3(0, by + 0.1, length / 2.0 + 0.02), Vector3(wid * 0.3, 0.22, 0.04))   # off-centre grille
		"z15":                  # low nose, tall cargo box, black side strip
			var bx: Array = spec["box"]
			_p("box", hex, Vector3(0, by + bh / 2.0 + bx[1] / 2.0, bx[2]), Vector3(wid * 0.98, bx[1], bx[0]))
			_p("box", black, Vector3(0, by - 0.05, 0), Vector3(wid + 0.04, 0.12, length - 0.3))
			_p("box", black, Vector3(0, by - bh * 0.3, length / 2.0), Vector3(wid + 0.06, bh * 0.36, 0.2))
			_p("box", black, Vector3(0, by - bh * 0.3, -length / 2.0), Vector3(wid + 0.06, bh * 0.3, 0.16))
			_p("box", 0x33363b, Vector3(0, by + 0.12, length / 2.0 + 0.02), Vector3(wid * 0.42, 0.14, 0.04))
			top = by + bh / 2.0 + bx[1]
		"tractor":
			_hebro(hex)
		"yondir":
			_yondir(hex)
		"edison":
			_edison(hex, by)
		"julietta":
			_julietta(hex, by)
		"grua":
			_grua(hex, by)
		"tunero":
			_p("box", 0x222226, Vector3(0, by + bh / 2.0 + 0.45, -length / 2.0 + 0.2), Vector3(wid, 0.06, 0.4))
			_p("box", 0x222226, Vector3(0, by + bh / 2.0 + 0.22, -length / 2.0 + 0.2), Vector3(0.1, 0.45, 0.1))
	if kind == "tricornio":     # white over green, a bull bar, and a blue light bar
		var green := 0x1f6b3a
		_p("box", green, Vector3(0, by - bh * 0.22, 0), Vector3(wid + 0.03, bh * 0.56, length + 0.02))
		_p("box", green, Vector3(0, by + bh / 2.0 - 0.02, length / 2.0 - 0.55), Vector3(wid * 0.96, 0.06, 1.0))
		_p("box", 0x26262b, Vector3(0, by - 0.05, length / 2.0 + 0.1), Vector3(wid * 0.8, 0.5, 0.08))
		for sx in [-1.0, 1.0]:
			_p("box", 0x26262b, Vector3(sx * wid * 0.3, by + 0.05, length / 2.0 + 0.12), Vector3(0.07, 0.7, 0.07))
			var l2 := Parts.part("box", 0x2f6bff, Vector3(sx * 0.32, top + 0.2, spec["cab_z"] + 0.5), Vector3(0.55, 0.18, 0.3))
			inner.add_child(l2)
			lights.append(l2)
	if kind == "pitufo":        # white doors and a blue light bar
		_p("box", 0xf4f4f0, Vector3(0, by + 0.12, -0.3), Vector3(wid + 0.03, bh * 0.5, 1.5))
		for sx in [-1.0, 1.0]:
			var l := Parts.part("box", 0x2f6bff, Vector3(sx * 0.3, top + 0.2, spec["cab_z"]), Vector3(0.5, 0.18, 0.3))
			inner.add_child(l)
			lights.append(l)

	return top

# ---------------- the Súper Hebro 555: no cab, engine in the open, a beacon on a stick ----------------
func _hebro(hex: int) -> void:
	var grey := 0x6f7378
	var dark := 0x26262b
	_p("box", grey, Vector3(0, 0.95, 0.55), Vector3(0.5, 0.55, 1.6))             # engine block
	_p("box", 0x8a8f94, Vector3(0.27, 1.0, 0.75), Vector3(0.1, 0.3, 0.6))        # ...and its bits
	_p("cyl", 0xd8d2c2, Vector3(-0.3, 1.02, 1.0), Vector3(0.11, 0.3, 0.11))      # air filter
	_p("box", hex, Vector3(0, 1.43, 0.72), Vector3(0.66, 0.38, 1.8))             # bonnet
	_p("box", hex, Vector3(0, 1.12, 1.56), Vector3(0.66, 1.0, 0.16))             # nose
	_p("box", 0xd8d2c2, Vector3(0, 1.15, 1.65), Vector3(0.5, 0.74, 0.04))        # grille
	for i in range(5):
		_p("box", grey, Vector3(-0.2 + i * 0.1, 1.15, 1.675), Vector3(0.02, 0.7, 0.02))
	_p("box", 0xf4f1e8, Vector3(0, 1.45, 0.72), Vector3(0.67, 0.07, 0.9))        # the stripe with the name on it
	for sx in [-1.0, 1.0]:
		_p("ball", 0xfff3a8, Vector3(sx * 0.42, 1.3, 1.52), Vector3(0.11, 0.11, 0.09))                    # headlamps on stalks
		_p("box", hex, Vector3(sx * 0.37, 1.3, 1.45), Vector3(0.1, 0.05, 0.05))
		_p("box", hex, Vector3(sx * 0.95, 1.95, -1.12), Vector3(0.5, 0.07, 1.3))                          # mudguards
		var lip := _p("box", hex, Vector3(sx * 0.95, 1.67, -0.38), Vector3(0.5, 0.07, 0.62))
		lip.rotation.x = -1.05
		_p("box", hex, Vector3(sx * 0.72, 1.55, -1.12), Vector3(0.05, 0.8, 1.3))
		_p("box", 0xd23b2e, Vector3(sx * 0.95, 1.86, -1.78), Vector3(0.16, 0.1, 0.04))
	_p("box", hex, Vector3(0, 0.98, -0.75), Vector3(0.6, 0.62, 1.5))             # gearbox and back axle
	_p("box", grey, Vector3(0, 0.66, 1.12), Vector3(1.7, 0.1, 0.12))             # front axle
	_p("box", grey, Vector3(0, 1.0, -1.12), Vector3(1.6, 0.18, 0.18))
	_p("box", hex, Vector3(0, 1.5, -0.2), Vector3(0.62, 0.36, 0.2))              # dashboard
	_p("cyl", dark, Vector3(0, 1.72, -0.38), Vector3(0.03, 0.42, 0.03)).rotation.x = -0.6
	_p("ring_thin", dark, Vector3(0, 1.88, -0.5), Vector3.ONE * 0.23).rotation.x = 0.55     # steering wheel
	_p("box", dark, Vector3(0, 1.35, -1.1), Vector3(0.5, 0.1, 0.45))             # the seat: a tin pan on a spring
	_p("box", dark, Vector3(0, 1.56, -1.34), Vector3(0.5, 0.36, 0.07))
	_p("cyl", 0x4a3a2a, Vector3(0.28, 2.08, 1.0), Vector3(0.05, 1.0, 0.05))      # exhaust stack
	_p("cyl", grey, Vector3(0.82, 2.5, -1.6), Vector3(0.025, 1.1, 0.025))        # the beacon on its pole
	_p("ball", 0xf08a2a, Vector3(0.82, 3.1, -1.6), Vector3(0.09, 0.11, 0.09))
	_p("box", 0xf4f1e8, Vector3(0, 1.2, -1.52), Vector3(0.5, 0.14, 0.03))        # number plate

# ---------------- the Yondir: green and yellow, twice the tractor ----------------
func _yondir(g: int) -> void:
	var yl := 0xf2c81e
	var bk := 0x1b1b1f
	_p("box", bk, Vector3(0, 0.98, 0.2), Vector3(0.75, 0.6, 3.7))                # chassis and engine
	_p("box", g, Vector3(0, 1.76, 1.2), Vector3(0.98, 0.86, 2.3))                # bonnet
	_p("ball", g, Vector3(0, 1.76, 2.32), Vector3(0.49, 0.43, 0.22))             # its rounded nose
	_p("box", bk, Vector3(0, 1.66, 2.5), Vector3(0.62, 0.5, 0.06))               # grille
	_p("box", yl, Vector3(0, 1.02, 2.55), Vector3(0.75, 0.42, 0.36))             # front weights
	for sx in [-1.0, 1.0]:
		_p("box", yl, Vector3(sx * 0.495, 1.98, 1.25), Vector3(0.02, 0.1, 2.1))                           # the yellow stripe
		_p("box", 0xfff3a8, Vector3(sx * 0.3, 2.04, 2.5), Vector3(0.2, 0.11, 0.05))                       # headlights
		_p("box", g, Vector3(sx * 1.14, 2.08, -1.47), Vector3(0.6, 0.1, 1.95))                            # rear mudguards
		_p("box", g, Vector3(sx * 0.86, 1.86, -1.47), Vector3(0.07, 0.5, 1.95))
		var lip := _p("box", g, Vector3(sx * 1.14, 1.82, -0.38), Vector3(0.6, 0.1, 0.62))
		lip.rotation.x = -0.9
		_p("box", g, Vector3(sx * 1.1, 1.52, 1.47), Vector3(0.42, 0.07, 1.25))                            # front mudguards
		for sz in [-1.0, 1.0]:
			_p("box", bk, Vector3(sx * 0.76, 2.42, -0.6 + sz * 0.76), Vector3(0.09, 1.3, 0.09))            # cab pillars
		_p("box", bk, Vector3(sx * 1.02, 2.62, 0.22), Vector3(0.05, 0.3, 0.18))                           # mirrors
		_p("ball", 0xf08a2a, Vector3(sx * 0.7, 3.24, -0.1), Vector3(0.08, 0.1, 0.08))                     # beacons
		_p("box", 0xfff3a8, Vector3(sx * 0.5, 3.06, 0.24), Vector3(0.24, 0.1, 0.05))                      # work lamps on the roof
		_p("box", 0xd23b2e, Vector3(sx * 1.14, 1.98, -2.46), Vector3(0.2, 0.12, 0.04))
	_p("box", g, Vector3(0, 1.55, -0.6), Vector3(1.6, 0.46, 1.6))                # under the cab
	_p("box", 0xcfe8f2, Vector3(0, 2.42, -0.6), Vector3(1.5, 1.3, 1.5))          # the glass
	_p("box", g, Vector3(0, 3.11, -0.6), Vector3(1.78, 0.12, 1.82))              # roof
	_p("cyl", bk, Vector3(0.72, 2.62, 0.35), Vector3(0.07, 1.5, 0.07))           # exhaust
	_p("box", bk, Vector3(-1.02, 1.0, -0.15), Vector3(0.3, 0.06, 0.5))           # steps
	_p("box", bk, Vector3(-1.02, 1.38, -0.15), Vector3(0.3, 0.06, 0.5))
	for k in range(4):                                                           # the red-and-white board at the back
		_p("box", 0xd23b2e if k % 2 == 0 else 0xf4f1e8, Vector3(0.62 + k * 0.1, 2.9, -1.44), Vector3(0.1, 0.4, 0.03))
	_p("box", yl, Vector3(0, 1.5, -1.42), Vector3(0.5, 0.3, 0.06))               # the hitch plate

# ---------------- the Edison Model Y: smooth, glass-topped and silent ----------------
func _edison(hex: int, by: float) -> void:
	var wid: float = spec["wid"]; var length: float = spec["len"]; var bh: float = spec["body"]
	var glass := 0x1c2026
	var slit := 0x2a2f36
	_p("box", hex, Vector3(0, by, -0.02), Vector3(wid, bh, length - 0.9))
	_p("ball", hex, Vector3(0, by - 0.02, length / 2.0 - 0.5), Vector3(wid / 2.0, bh / 2.0, 0.52))            # nose: no grille at all
	_p("ball", hex, Vector3(0, by + 0.04, -length / 2.0 + 0.48), Vector3(wid / 2.0, bh / 2.0 + 0.06, 0.5))    # tail
	_p("box", hex, Vector3(0, by + bh / 2.0 + 0.04, -0.3), Vector3(wid * 0.97, 0.12, length * 0.6))           # shoulders
	_p("dome", glass, Vector3(0, by + bh / 2.0 + 0.06, -0.3), Vector3(wid * 0.47, spec["cab"] * 1.28, 1.9))    # one long sweep of dark glass
	_p("box", 0x26262b, Vector3(0, by - bh / 2.0 + 0.05, 0), Vector3(wid + 0.03, 0.12, length - 1.1))         # sill
	_p("box", 0xf4f8ff, Vector3(0, by + 0.16, length / 2.0 + 0.012), Vector3(wid * 0.4, 0.03, 0.03))          # the light bar
	_p("box", 0xd23b2e, Vector3(0, by + 0.2, -length / 2.0 - 0.012), Vector3(wid * 0.5, 0.045, 0.03))
	_p("box", slit, Vector3(0, by - bh / 2.0 + 0.12, length / 2.0 - 0.05), Vector3(wid * 0.55, 0.1, 0.1))
	for sx in [-1.0, 1.0]:
		_p("box", 0xf4f8ff, Vector3(sx * wid * 0.3, by + 0.15, length / 2.0 - 0.07), Vector3(0.34, 0.04, 0.06)) # slim headlights
		_p("box", hex, Vector3(sx * (wid / 2.0 + 0.04), by + bh / 2.0 + 0.16, 0.85), Vector3(0.1, 0.09, 0.2))  # mirrors
		_p("box", 0x8d99ae, Vector3(sx * (wid / 2.0 + 0.005), by + 0.14, -0.2), Vector3(0.02, 0.03, 0.2))     # flush door handles
		_p("box", 0x8d99ae, Vector3(sx * (wid / 2.0 + 0.005), by + 0.14, -1.1), Vector3(0.02, 0.03, 0.2))

# ---------------- the Omega Julietta: low, open, loud colours, and a turbo ----------------
func _julietta(hex: int, by: float) -> void:
	var wid: float = spec["wid"]; var length: float = spec["len"]; var bh: float = spec["body"]
	var dark := 0x1b1b1f
	var chrome := 0xd8dde2
	var top := by + bh / 2.0
	_p("box", hex, Vector3(0, by, -0.05), Vector3(wid, bh, length - 1.1))
	_p("ball", hex, Vector3(0, by - 0.01, length / 2.0 - 0.62), Vector3(wid / 2.0, bh / 2.0, 0.62))             # the long nose
	_p("ball", hex, Vector3(0, by + 0.02, -length / 2.0 + 0.46), Vector3(wid / 2.0, bh / 2.0 + 0.03, 0.46))
	_p("ball", hex, Vector3(0, top - 0.03, 1.0), Vector3(wid * 0.34, 0.12, 1.05))                               # the bulge down the bonnet
	_p("box", hex, Vector3(0, top + 0.03, -1.62), Vector3(wid * 0.92, 0.1, 0.85))                               # rear deck
	_p("box", dark, Vector3(0, top + 0.006, -0.55), Vector3(wid * 0.8, 0.05, 1.35))                             # the open cockpit
	var screen := _p("box", 0xcfe8f2, Vector3(0, top + 0.23, 0.16), Vector3(wid * 0.86, 0.5, 0.04))
	screen.rotation.x = -0.6
	var rail := _p("box", dark, Vector3(0, top + 0.44, 0.02), Vector3(wid * 0.88, 0.04, 0.06))
	rail.rotation.x = -0.6
	_p("box", dark, Vector3(0, top + 0.1, 0.02), Vector3(wid * 0.78, 0.16, 0.2))                                # dashboard
	_p("ring_thin", dark, Vector3(-0.4, top + 0.24, -0.16), Vector3.ONE * 0.17).rotation.x = 1.2              # steering wheel
	for sx in [-1.0, 1.0]:
		_p("box", 0x4a1a1a, Vector3(sx * 0.4, top + 0.08, -0.72), Vector3(0.46, 0.12, 0.5))                     # seats
		_p("box", 0x4a1a1a, Vector3(sx * 0.4, top + 0.3, -1.02), Vector3(0.46, 0.5, 0.13))
		_p("ring", chrome, Vector3(sx * 0.4, top + 0.3, -1.2), Vector3.ONE * 0.22).rotation.x = PI / 2.0     # roll hoops
		for k in range(3):                                                                                      # three round lamps a side
			_p("ball", 0xf4f8ff, Vector3(sx * (0.44 + k * 0.15), by + 0.07, length / 2.0 - 0.3 - k * 0.1), Vector3.ONE * 0.07)
		_p("ball", 0xf4f8ff, Vector3(sx * 0.62, by - 0.14, length / 2.0 - 0.33), Vector3.ONE * 0.06)            # fog lamps
		_p("box", hex, Vector3(sx * (wid / 2.0 + 0.05), top + 0.1, 0.25), Vector3(0.12, 0.09, 0.18))            # mirrors
		_p("box", 0xd23b2e, Vector3(sx * wid * 0.3, by + 0.1, -length / 2.0 + 0.02), Vector3(0.4, 0.07, 0.06))
		_p("cyl", chrome, Vector3(sx * 0.5, by - bh / 2.0 + 0.06, -length / 2.0 + 0.04), Vector3(0.05, 0.16, 0.05)).rotation.x = PI / 2.0     # twin exhausts
	_p("ring", chrome, Vector3(0, by - 0.02, length / 2.0 - 0.03), Vector3.ONE * 0.15).rotation.x = PI / 2.0  # an Ω for a grille, more or less
	_p("ball", dark, Vector3(0, by - 0.02, length / 2.0 - 0.06), Vector3(0.11, 0.11, 0.04))
	_p("box", dark, Vector3(0, by - bh / 2.0 + 0.09, length / 2.0 - 0.3), Vector3(wid * 0.62, 0.12, 0.3))        # the mouth under it
	_p("box", dark, Vector3(0, by - bh / 2.0 + 0.04, 0), Vector3(wid + 0.03, 0.09, length - 1.3))

# ---------------- the tow truck: white cab, amber lights, a black boom over the back ----------------
func _grua(hex: int, by: float) -> void:
	var wid: float = spec["wid"]
	var bk := 0x1b1b1f
	var chrome := 0x8d99ae
	_p("box", bk, Vector3(0, 0.72, 0), Vector3(wid * 0.5, 0.3, 5.6))                 # chassis
	_p("box", hex, Vector3(0, by + 0.05, 2.35), Vector3(wid * 0.92, 0.8, 1.3))       # bonnet
	_p("box", bk, Vector3(0, by - 0.22, 3.04), Vector3(wid + 0.06, 0.5, 0.26))       # the big black bumper
	_p("box", chrome, Vector3(0, by + 0.16, 3.01), Vector3(wid * 0.5, 0.42, 0.06))   # grille
	_p("box", hex, Vector3(0, by, 0.85), Vector3(wid * 0.96, 0.85, 1.7))             # cab
	_p("box", 0xcfe8f2, Vector3(0, by + 0.8, 0.82), Vector3(wid * 0.9, 0.75, 1.5))
	_p("box", hex, Vector3(0, by + 0.8, 0.06), Vector3(wid * 0.94, 0.75, 0.12))
	_p("box", hex, Vector3(0, by + 1.21, 0.8), Vector3(wid * 0.94, 0.08, 1.62))
	for half in [-1.0, 1.0]:                                                         # the amber bar on the roof
		var l := Parts.part("box", 0xf2a900, Vector3(half * wid * 0.19, by + 1.32, 0.9), Vector3(wid * 0.36, 0.13, 0.22))
		inner.add_child(l)
		lights.append(l)
	for k in range(5):
		_p("ball", 0xf2a900, Vector3(-0.6 + k * 0.3, by + 1.27, 1.56), Vector3.ONE * 0.045)
	_p("box", hex, Vector3(0, by - 0.1, -1.5), Vector3(wid, 0.6, 3.0))               # the body with its lockers
	_p("box", bk, Vector3(0, by + 0.22, -1.6), Vector3(wid * 0.8, 0.06, 2.6))
	_p("box", bk, Vector3(0, by + 0.65, -0.9), Vector3(0.55, 0.9, 0.55))             # the mast
	var boom := _p("box", bk, Vector3(0, by + 1.0, -1.95), Vector3(0.3, 0.3, 2.5))
	boom.rotation.x = 0.42
	_p("box", bk, Vector3(0, by + 0.95, -3.05), Vector3(0.04, 1.0, 0.04))            # cable and hook
	_p("ring", chrome, Vector3(0, by + 0.4, -3.05), Vector3.ONE * 0.11).rotation.x = PI / 2.0
	_p("box", bk, Vector3(0, 0.5, -2.95), Vector3(0.2, 0.12, 0.9))                   # the wheel lift
	_p("box", bk, Vector3(0, 0.5, -3.3), Vector3(1.7, 0.1, 0.2))
	for sx in [-1.0, 1.0]:
		_p("box", 0xfff3a8, Vector3(sx * wid * 0.36, by + 0.16, 3.01), Vector3(0.32, 0.3, 0.06))
		_p("box", 0xf08a2a, Vector3(sx * wid * 0.46, by + 0.16, 2.96), Vector3(0.08, 0.3, 0.14))
		_p("box", bk, Vector3(sx * (wid / 2.0 + 0.12), by + 0.6, 1.5), Vector3(0.08, 0.36, 0.22))       # mirrors
		_p("box", bk, Vector3(sx * (wid / 2.0 - 0.02), 1.12, -1.92), Vector3(0.36, 0.1, 1.15))          # mudguards
		_p("box", bk, Vector3(sx * (wid / 2.0 + 0.005), by - 0.05, -0.75), Vector3(0.02, 0.4, 0.03))    # locker doors
		_p("box", bk, Vector3(sx * (wid / 2.0 + 0.005), by - 0.05, -2.6), Vector3(0.02, 0.4, 0.03))
		_p("box", 0xd23b2e, Vector3(sx * wid * 0.4, by - 0.1, -3.01), Vector3(0.2, 0.26, 0.04))
		_p("box", bk, Vector3(sx * (wid / 2.0 - 0.3), 0.62, 0.9), Vector3(0.3, 0.06, 1.0))              # steps
		var name := Label3D.new()
		name.text = "GRÚAS EL ENGANCHE\n24 h (o cuando pueda)"
		name.font_size = 60
		name.pixel_size = 0.0042
		name.modulate = Color("1b1b1f")
		name.outline_size = 0
		name.shaded = true
		name.position = Vector3(sx * (wid / 2.0 + 0.012), by - 0.06, -1.65)
		name.rotation.y = sx * PI / 2.0
		inner.add_child(name)

# ---------------- exhaust ----------------
func _emitter(pos: Vector3, dir: Vector3, colour: Color, amount: int, life: float, speed: float, puff: float, rise: float) -> CPUParticles3D:
	if _puff_mesh == null:
		_puff_mesh = SphereMesh.new()
		_puff_mesh.radius = 0.5; _puff_mesh.height = 1.0; _puff_mesh.radial_segments = 8; _puff_mesh.rings = 4
		var m := StandardMaterial3D.new()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.vertex_color_use_as_albedo = true
		_puff_mesh.material = m
	var e := CPUParticles3D.new()
	e.position = pos
	e.mesh = _puff_mesh
	e.amount = amount
	e.lifetime = life
	e.local_coords = false                 # the puffs stay where they were let go
	e.direction = dir
	e.spread = 16.0
	e.gravity = Vector3(0, rise, 0)
	e.initial_velocity_min = speed * 0.7
	e.initial_velocity_max = speed * 1.25
	e.scale_amount_min = puff * 0.7
	e.scale_amount_max = puff * 1.2
	var swell := Curve.new()
	swell.add_point(Vector2(0.0, 0.3))
	swell.add_point(Vector2(1.0, 1.0))
	e.scale_amount_curve = swell
	var fade := Gradient.new()
	fade.set_color(0, colour)
	fade.set_color(1, Color(colour.r, colour.g, colour.b, 0.0))
	e.color_ramp = fade
	e.emitting = false
	add_child(e)
	return e

## the engine catches: a cloud out of the exhaust (a big black one on tractors and the Z15), then a thin haze as it goes
func _start_engine() -> void:
	running = true
	var k: float = spec.get("smoke", 1.0)
	if k <= 0.0:
		return                              # electric: nothing comes out of it
	if cough == null:
		var up: bool = spec.has("pipe")
		var at: Vector3 = (_pipe_at if _pipe_at != null else spec["pipe"]) if up else Vector3(-spec["wid"] * 0.3, spec["wheel"] * 0.9, -spec["len"] / 2.0 - 0.05)
		var dir := Vector3(0.15, 1, -0.2) if up else Vector3(0, 0.3, -1)
		var grey := lerpf(0.9, 0.5, clampf((k - 1.0) / 2.0, 0.0, 1.0))
		vapour = _emitter(at, dir, Color(grey, grey, grey + 0.02, 0.14 + 0.07 * k), 10 + int(5.0 * k), 0.9 + 0.25 * k, 1.3, 0.2 + 0.1 * k, 0.7)
		var soot := lerpf(0.3, 0.08, clampf((k - 1.0) / 2.0, 0.0, 1.0))
		cough = _emitter(at, dir, Color(soot, soot, soot + 0.02, 0.8), 22 + int(12.0 * k), 1.5 + 0.4 * k, 1.5 + 0.5 * k, 0.45 + 0.24 * k, 1.3)
	_cough = 0.9 + 0.5 * k

## the colour it was painted (for the curious, and the tests)
func material_colour() -> int:
	return paint

## A parked car nobody is near costs nothing: it stops being simulated (it is a wall, as far as anything that
## reaches it is concerned) until it is woken.
func doze(on: bool) -> void:
	if on == dozing:
		return
	dozing = on
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	freeze = on
	set_physics_process(not on)

## Lights on or off. beam = it also throws real light on the road (cars that are being driven; parked ones only glow).
func set_lights(on: bool, beam := false) -> void:
	if on == lit and (not on or (_beam != null) == beam):
		return
	lit = on
	if _head_on == null:
		_head_on = StandardMaterial3D.new()
		_head_on.albedo_color = Color(1.0, 0.97, 0.82)
		_head_on.emission_enabled = true
		_head_on.emission = Color(1.0, 0.95, 0.75)
		_head_on.emission_energy_multiplier = 3.2
		_tail_on = StandardMaterial3D.new()
		_tail_on.albedo_color = Color(0.9, 0.12, 0.1)
		_tail_on.emission_enabled = true
		_tail_on.emission = Color(1.0, 0.1, 0.06)
		_tail_on.emission_energy_multiplier = 1.8
	for pair in _heads:
		pair[0].material_override = _head_on if on else pair[1]
	for pair in _tails:
		pair[0].material_override = _tail_on if on else pair[1]
	if on and model != null and _glows.is_empty():
		var spots: Array = Modelos.lamps(kind, model)
		for i in range(4):
			var lamp := Parts.part("ball", 0xffffff, (spots[i] as Vector3) + Vector3(0, GROUND, 0.02 if i < 2 else -0.02), Vector3(0.13, 0.085, 0.03) if i < 2 else Vector3(0.11, 0.07, 0.03))
			lamp.material_override = _head_on if i < 2 else _tail_on
			lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			inner.add_child(lamp)
			_glows.append(lamp)
	for lamp in _glows:
		lamp.visible = on
	if on and beam and _beam == null:
		_beam = SpotLight3D.new()
		_beam.position = Vector3(0, spec["wheel"] + 0.45, spec["len"] / 2.0 + 0.15)
		_beam.rotation = Vector3(-0.1, PI, 0)             # a spot shines along its own -z: turn it to face forwards, dipped
		_beam.light_color = Color(1.0, 0.95, 0.8)
		_beam.light_energy = 3.0
		_beam.spot_range = 34.0
		_beam.spot_angle = 36.0
		_beam.spot_attenuation = 0.8
		_beam.shadow_enabled = false
		_beam.distance_fade_enabled = true
		_beam.distance_fade_begin = 110.0
		_beam.distance_fade_length = 30.0
		add_child(_beam)
	if _beam != null:
		_beam.visible = on and beam

func show_bottles(n: int) -> void:
	for i in range(bottles.size()):
		bottles[i].visible = i < n

## teleport: put the car on the road at pos, facing heading, standing still
func place(pos: Vector2, heading: float) -> void:
	var up := MapData.normal(pos)                # standing on the slope, not level over it
	var fwd := Vector3(sin(heading), 0.0, cos(heading))
	fwd = (fwd - up * fwd.dot(up)).normalized()
	global_transform = Transform3D(Basis(up.cross(fwd), up, fwd), MapData.at(pos, 0.12))
	set_speed(Vector2.ZERO)
	angular_velocity = Vector3.ZERO
	air_time = 0.0
	reset_physics_interpolation()

func set_speed(v: Vector2) -> void:
	linear_velocity = Vector3(v.x, 0.0, v.y)
	_prev_v = linear_velocity

## left standing with the handbrake on and the engine off
func park() -> void:
	engine_force = 0.0
	steering = 0.0
	brake = mass * 0.03
	running = false
	_thr = 0.0
	turbo = false
	boosting = false

func damage(amount: float) -> void:
	hp = maxf(0.0, hp - amount)
	smoke.emitting = hp < spec["hp"] * 0.35

func repair() -> void:
	hp = spec["hp"]
	smoke.emitting = false

func broken() -> bool:
	return hp <= 0.0

## forward speed in m/s (negative when reversing)
func forward_speed() -> float:
	return linear_velocity.dot(global_transform.basis.z)

func airborne() -> bool:
	for w in wheels:
		if w.is_in_contact():
			return false
	return true

## thr: -1..1 (forward/back), steer: -1..1 (positive = left), hand: handbrake. Call every physics tick.
func drive(thr: float, steer: float, hand: bool, on_road: bool, dt: float) -> void:
	if held:
		return
	var vf := forward_speed()
	# off the road most cars drop to 55 % of their top speed; "offroad" in the spec overrides that
	# (the Z15 barely notices, the tractors do not notice at all)
	var max_v: float = spec["max"] * speed_boost * (1.0 if on_road else float(spec.get("offroad", 0.55)))
	var push: float = spec["acc"] * mass * speed_boost
	if broken() or flipped():
		thr = 0.0
		hand = true
	if thr != 0.0 and dozing:
		doze(false)                     # somebody is driving it after all
	if thr != 0.0 and sleeping:
		sleeping = false                # (a body left still for a moment goes to sleep, and an engine's push alone does not wake it)
	if thr != 0.0 and not running:
		_start_engine()
	_thr = thr
	boosting = turbo and spec.has("turbo") and thr > 0.0 and nitro > 0.0 and not burnt
	if spec.has("turbo"):
		if boosting:
			nitro = maxf(0.0, nitro - dt / NITRO_BURN)
			if nitro <= 0.0:
				burnt = true                     # that was the lot: it coughs, and you are on your own for a while
				boosting = false
		else:
			var pace: float = clampf((vf / float(spec["max"]) - 0.5) / 0.4, 0.0, 1.0)      # nothing under half speed, all of it near the top
			nitro = minf(1.0, nitro + dt / NITRO_FILL * pace)
			if burnt and nitro >= NITRO_BACK:
				burnt = false
	if boosting:
		max_v *= float(spec["turbo"]["max"])
		push *= float(spec["turbo"]["acc"])
	engine_force = 0.0
	brake = 0.0
	if thr > 0.0:
		if vf < -0.5:
			brake = mass * 0.045
		else:
			engine_force = push * thr * clampf(1.0 - vf / max_v, 0.0, 1.0)
	elif thr < 0.0:
		if vf > 0.8:
			brake = mass * 0.05
		else:
			engine_force = -push * 0.6 * clampf(1.0 + vf / (max_v * 0.4), 0.0, 1.0)
	else:
		brake = mass * 0.022                       # engine braking: rolls to a stop, and is hard to shunt along
	if hand:
		brake = mass * 0.07
	for w in wheels:
		if not w.use_as_steering:
			w.wheel_friction_slip = 1.1 if hand else 2.8     # handbrake breaks the rear loose: drifts
	if absf(vf) > max_v:                            # e.g. just left the road at speed
		apply_central_force(-linear_velocity.normalized() * mass * 6.0)
	# steering gets gentler with speed, and eases towards its target
	var lock: float = spec["turn"] * lerpf(1.0, 0.3, clampf(absf(vf) / 28.0, 0.0, 1.0))
	steering = move_toward(steering, steer * lock, 2.6 * dt)

func _physics_process(dt: float) -> void:
	if held:
		return
	crash_cool -= dt
	var dv := (linear_velocity - _prev_v)
	dv.y = 0.0
	if dv.length() > 3.0:
		last_impact = maxf(last_impact, dv.length())
	_prev_v = linear_velocity
	if cough != null:
		_cough -= dt
		cough.emitting = _cough > 0.0
		vapour.emitting = running and _cough <= 0.0 and not broken() and (linear_velocity.length() > 0.8 or absf(_thr) > 0.1)
	if boosting and flame == null:           # the turbo spits fire out of the back
		flame = _emitter(Vector3(0, spec["wheel"] * 0.85, -spec["len"] / 2.0 - 0.1), Vector3(0, 0.1, -1), Color(1.0, 0.55, 0.12, 0.9), 26, 0.28, 5.0, 0.42, 1.0)
	if flame != null:
		flame.emitting = boosting
	if airborne():
		if air_time == 0.0:
			air_from = p
		air_time += dt
	elif air_time > 0.0:
		last_air = air_time
		air_time = 0.0
	# Left parked, the handbrake holds whatever the slope. These wheels would otherwise creep downhill a hand's breadth
	# a second, so a parked car is tied to the spot it came to rest on, by a spring that a real shove breaks.
	if not running and not freeze and air_time == 0.0:
		var flat := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
		if not _held:
			if flat.length() < 0.6:
				_held = true
				_held_at = p
		elif p.distance_to(_held_at) > 0.6 or flat.length() > 2.5:
			_held = false                            # knocked out of its place: it rolls until it stops again
		else:
			var up := MapData.normal(p)
			var back := _held_at - p
			apply_central_force((Vector3.UP - up * up.y) * mass * 9.8 + Vector3(back.x, 0.0, back.y) * mass * 30.0 - flat * mass * 9.0)
	else:
		_held = false
	_keep_upright(dt)
	# A car on its roof or side stays there until someone gets out and shoves it back (game.gd).
	# Only patrol cars right themselves, or a flipped one would end every chase.
	if global_transform.basis.y.y < 0.35:
		_flipped += dt
		if (kind == "pitufo" or kind == "tricornio") and _flipped > 1.5:
			place(p, h)
	else:
		_flipped = 0.0
		pushes = 0
		flip_told = false

## Keeping it on its wheels. Cars rolled over far too easily, above all at speed (the user, 13 November 2026), so:
##  - an anti-roll bar: a twist about the car's own length that brings it back level with the ground under it,
##    springy and damped like a real car's, as stiff as its width and height call for (on its wheels; much weaker in
##    the air, and only while it is moving, so a car that has come to rest on its side stays there for the shove);
##  - the faster it goes, the harder the air presses it down (a fifth more weight at top speed), so bumps and kerbs do
##    not throw it about.
const ROLL_FREQ := 9.0          # how quickly the anti-roll bar brings it back (radians a second)
const ROLL_DAMP := 0.9          # and how little it lets it rock (1 = not at all)
const DOWNFORCE := 0.2          # extra weight at top speed, as a share of its own

func _keep_upright(dt: float) -> void:
	if freeze:
		return
	var touching := 0
	for w in wheels:
		if w.is_in_contact():
			touching += 1
	var moving := linear_velocity.length() > 3.0
	if touching < 2 and (not moving or _flipped > 0.0):
		return                                   # lying still on its side or roof: that is for a shove
	var b := global_transform.basis
	var fwd := b.z
	var ground := MapData.normal(p) if touching >= 2 else Vector3.UP
	var tilt := b.y.cross(ground)               # the turn that would set it level again (its size: sin of the angle)
	var roll := tilt.dot(fwd)
	var roll_rate := angular_velocity.dot(fwd)
	var wid: float = spec["wid"]
	var tall: float = spec["body"] + spec["cab"] + spec["wheel"]
	var inertia: float = mass * (wid * wid + tall * tall) / 12.0
	var k := inertia * ROLL_FREQ * ROLL_FREQ
	var d := 2.0 * inertia * ROLL_DAMP * ROLL_FREQ
	var share := 1.0 if touching >= 2 else 0.3
	apply_torque(fwd * (roll * k - roll_rate * d) * share)
	if touching >= 2:
		var v := linear_velocity.length()
		var top: float = spec["max"]
		apply_central_force(-b.y * mass * 9.8 * DOWNFORCE * clampf(v / top, 0.0, 1.3) ** 2)

## lying on its roof or side for a moment (not just mid-jump)
func flipped() -> bool:
	return _flipped > 0.6
