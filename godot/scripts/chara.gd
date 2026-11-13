extends CharacterBody3D

const CLEAR := 0.3             # how far off the ground a walker is carried over a slope (see walk)
## A cute round villager built from primitives, with a capsule collider. Used for the player and (via npc.gd) everyone else.
## p is the ground position (x, z); h the heading, forward = (sin h, cos h).
##
## look keys:
##   shirt, skin, shoes   colours
##   top         what they wear: 0 T-shirt · 1 shirt · 2 striped T-shirt · 3 checked shirt · 4 tracksuit · 5 dungarees
##               · 6 shirt and braces · 7 flowery housecoat · 8 vest · 9 black leather jacket over a top, patterned skirt
##   build       girth of the body (1 = normal)          scale   overall size
##   hair        colour, or null = bald
##   hair_style  0 short · 1 bun · 2 long · 3 cropped · 4 afro · 5 ponytail · 6 mohawk · 7 pigtails · 8 quiff · 9 bob
##               · 10 bald on top · 11 curls · 12 plait
##   face        0 shaved · 1 moustache · 2 beard · 3 goatee · 4 big moustache · 5 stubble · 6 long beard · 7 sideburns
##               · 8 moustache and goatee
##   brows       0 thin · 1 bushy · 2 unibrow · 3 none      eyes  0 normal · 1 big · 2 sleepy      eye_color
##   glasses     0 none · 1 thin · 2 thick · 3 tube goggles · 4 opaque · 5 sunglasses · 6 aviators
##   earrings    0 none · 1 studs · 2 hoops · 3 a single hoop · 4 long · 5 pearls · 6 silver hoops
##   lashes      eyelashes: 0 none · 1 fine · 2 a doll's          hat_band  the ribbon round a straw hat (-1: red and gold)
##   pendant     0 none · 1 gold chain · 2 medal · 3 cross · 4 pearls · 5 fiesta neckerchief (colour: kerchief)
##   shoe_type   0 trainers · 1 boots · 2 alpargatas · 3 flip-flops (their colour is "shoes")
##   hat         "cap" | "beret" | "straw" | "bun" | "tricorn" | "tophat" | "horns" | "collar" | ""      hat_color, emblem

const Parts = preload("res://scripts/parts.gd")
const Brand = preload("res://scripts/brand.gd")

var p: Vector2:
	get:
		return Vector2(global_position.x, global_position.z)
	set(v):
		global_position = Vector3(v.x, MapData.foot(v), v.y)
var h := 0.0
var y := 0.0               # visual lift (being thrown through the air)
var vis: Node3D            # scaled, lifted
var inner: Node3D          # bobbing / tumbling
var neck: Node3D           # the head and all that goes on it: it turns on its own, a little, to look at things
const NECK := 1.0          # whatever is put on at this height or above goes on the head
const NECK_TURN := 1.25    # how far the head turns either way (radians): about seventy degrees, never right round
var _fl: Node3D
var _fr: Node3D
var _hl: Node3D
var _hr: Node3D
var _walk := 0.0
var _off := randf() * 6.0
var size := 1.0
var guard := false         # fists up in front of the face (boxing)
var phone := false         # holding a phone to the ear
var _phone: Node3D
var punch := 0.0          # > 0 while throwing a punch (seconds left)
var look: Dictionary = {}  # what they were last made to look like
var _hop := 0.0            # > 0 while in the air of a little jump (seconds left)
const HOP := 0.46

## a little jump on the spot (or on the run): it gets you over nothing, but it is a jump
func hop() -> bool:
	if _hop > 0.0:
		return false
	_hop = HOP
	return true
var _hx := 0.46            # how far out the hands hang (further on a wider body)
var _girth := 1.0

func setup(o: Dictionary) -> void:
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.38
	cap.height = 1.6
	cs.shape = cap
	cs.position.y = 0.82
	add_child(cs)
	floor_snap_length = 0.3
	vis = Node3D.new()
	add_child(vis)
	set_look(o)

## The same person as a figure only, sitting: for a seat in a car (car.gd). Nothing of what walks or is bumped into
## comes with it -- the figure is handed over on its own, and this node is then thrown away. Their legs are not
## shown (they are under the dashboard); they lean back into the seat, and the head stays upright, looking at the
## road; hands on the wheel if they are driving, in the lap if they are not.
const LEAN := 0.3               # how far back a sitter leans (radians)
func sit(o: Dictionary, driving: bool) -> Node3D:
	var as_they_are: Dictionary = o
	if not o.has("shirt"):
		as_they_are = o.duplicate()
		as_they_are["shirt"] = 0x3b5fa8
	vis = Node3D.new()
	add_child(vis)
	set_look(as_they_are)
	_fl.visible = false
	_fr.visible = false
	# everything from the neck down leans back about the hips; everything above goes with the neck, and stays upright
	var torso := Node3D.new()
	var head := Node3D.new()
	for n in inner.get_children():
		if n == _fl or n == _fr or n == _hl or n == _hr or n == _phone or n == neck or not (n is Node3D):
			continue
		var high: bool = (n as Node3D).position.y >= 1.04
		inner.remove_child(n)
		(head if high else torso).add_child(n)
	inner.add_child(torso)
	inner.add_child(head)
	inner.remove_child(neck)                 # (what was already on the head goes with it)
	head.add_child(neck)
	var hip := Vector3(0, 0.3, 0)
	var back := Basis(Vector3.RIGHT, -LEAN)
	torso.transform = Transform3D(back, hip - back * hip)
	var neck := Vector3(0, 1.0, 0)
	head.position = torso.transform * neck - neck
	if driving:
		_hl.position = Vector3(-0.3, 0.74, 0.8)
		_hr.position = Vector3(0.3, 0.74, 0.8)
	else:
		_hl.position = Vector3(-0.2, 0.5, 0.36)
		_hr.position = Vector3(0.2, 0.5, 0.36)
	var todo: Array = [vis]
	while not todo.is_empty():          # (inside a car nobody's own shadow is missed, and there are many of these parts)
		var n: Node = todo.pop_back()
		if n is GeometryInstance3D:
			(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for c in n.get_children():
			todo.append(c)
	remove_child(vis)
	return vis

# ---------------- little helpers for building the model ----------------
static func _mix(a: int, b: int, t: float) -> int:
	var c := Parts.col(a).lerp(Parts.col(b), t)
	return (int(c.r * 255.0) << 16) | (int(c.g * 255.0) << 8) | int(c.b * 255.0)

func _add(kind: String, hex: int, pos: Vector3, scl: Vector3) -> MeshInstance3D:
	var m := Parts.part(kind, hex, pos, scl)
	(neck if pos.y >= NECK else inner).add_child(m)
	return m

## a small accessory: like _add, but it casts no shadow (there are a lot of these in a busy street)
func _acc(kind: String, hex: int, pos: Vector3, scl: Vector3) -> MeshInstance3D:
	var m := _add(kind, hex, pos, scl)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m

## radius of the body at height y (it is a cone: wider at the bottom)
func _r(at_y: float) -> float:
	return (0.44 - (at_y - 0.245) * 0.18667) * _girth

## a hoop round the body
func _band(hex: int, at_y: float, tall: float, extra := 0.007) -> void:
	var r := _r(at_y - tall / 2.0) + extra
	_acc("cyl", hex, Vector3(0, at_y, 0), Vector3(r, tall, r))

## a strip lying on the body's surface, running up it at angle `ang` round the body (0 = front)
func _strip(hex: int, ang: float, y0: float, y1: float, wide: float, lift := 0.012) -> void:
	var ym := (y0 + y1) / 2.0
	var r := _r(ym) + lift
	var m := _acc("box", hex, Vector3(sin(ang) * r, ym, cos(ang) * r), Vector3(wide, (y1 - y0) * 1.02, 0.02))
	m.rotation = Vector3(-0.185, ang, 0)

func _dot(hex: int, ang: float, at_y: float, r: float) -> void:
	var rr := _r(at_y) + 0.004
	_acc("ball", hex, Vector3(sin(ang) * rr, at_y, cos(ang) * rr), Vector3.ONE * r)

## (re)builds the visible character; safe to call again when the look changes (character creation)
func set_look(o: Dictionary) -> void:
	look = o
	if inner != null:
		inner.free()
	size = float(o.get("scale", 1.0))
	vis.scale = Vector3.ONE * size
	inner = Node3D.new()
	vis.add_child(inner)
	neck = Node3D.new()
	inner.add_child(neck)
	var skin: int = o.get("skin", 0xf6c9a0)
	var shoes: int = o.get("shoes", 0x4a3424)
	var hair = o.get("hair", 0x4a3424)
	var hair_c: int = hair if hair != null else 0x4a3424
	_girth = float(o.get("build", 1.0))
	_hx = 0.46 * _girth
	_add("body", o["shirt"], Vector3(0, 0.62, 0), Vector3(_girth, 1.0, _girth))
	_add("head", skin, Vector3(0, 1.38, 0), Vector3.ONE)
	_clothes(int(o.get("top", 0)), o["shirt"], skin)
	# eyes, cheeks, brows
	var eye_c: int = o.get("eye_color", 0x5a3a22)
	var eyes: int = o.get("eyes", 0)
	var ew := 0.078        # half-width and half-height of the white of the eye
	var eh := 0.098
	if eyes == 1:
		ew = 0.1; eh = 0.125
	elif eyes == 2:
		ew = 0.085; eh = 0.052
	var iris := minf(ew * 0.64, eh * 0.86)
	var brows: int = o.get("brows", 3)
	for sx in [-1.0, 1.0]:
		var ex: float = sx * 0.17
		_acc("ball", 0x17110d, Vector3(ex, 1.42, 0.446), Vector3(ew + 0.017, eh + 0.017, 0.04))     # dark outline
		_acc("ball", 0xffffff, Vector3(ex, 1.42, 0.456), Vector3(ew, eh, 0.045))                 # white
		_acc("ball", eye_c, Vector3(ex, 1.415, 0.478), Vector3(iris, iris, 0.03))                  # iris: the only part that takes the eye colour
		_acc("ball", 0x0c0908, Vector3(ex, 1.415, 0.492), Vector3(iris * 0.5, iris * 0.5, 0.02))  # pupil
		_acc("ball", 0xffffff, Vector3(ex + 0.02, 1.415 + iris * 0.45, 0.5), Vector3.ONE * 0.012) # glint
		_acc("ball", 0xf59a8c, Vector3(sx * 0.3, 1.27, 0.37), Vector3(0.09, 0.06, 0.04))
		var lashes: int = o.get("lashes", 0)
		if lashes > 0:                       # eyelashes: little dark strokes fanning out from the top of the eye, outwards
			for k in range(3 if lashes == 1 else 4):
				var t := (k + 0.5) / (3.0 if lashes == 1 else 4.0)                  # 0 by the nose .. 1 at the outer corner
				var lx: float = ex + sx * ew * (t * 1.9 - 0.75)
				var lash := _acc("box", 0x17110d, Vector3(lx, 1.42 + eh * (1.0 - 0.45 * t * t) + (0.02 if lashes == 1 else 0.035), 0.462), Vector3(0.012 if lashes == 1 else 0.016, 0.04 if lashes == 1 else 0.075, 0.012))
				lash.rotation.z = -sx * (0.15 + t * 0.75)
		if brows == 0 or brows == 1:
			var b := _acc("box", hair_c, Vector3(sx * 0.17, 1.42 + eh + 0.05, 0.45), Vector3(0.15, 0.03 if brows == 0 else 0.065, 0.04))
			b.rotation.z = sx * -0.15
	if brows == 2:
		_acc("box", hair_c, Vector3(0, 1.42 + eh + 0.05, 0.46), Vector3(0.46, 0.06, 0.04))
	_beard(int(o.get("face", 0)), hair_c, skin)
	var ankle: int = o.get("socks", skin)            # (socks under sandals or slides: the foot shows in their colour)
	_fl = _foot(-0.17, shoes, int(o.get("shoe_type", 0)), ankle)
	_fr = _foot(0.17, shoes, int(o.get("shoe_type", 0)), ankle)
	_hl = Parts.part("ball", skin, Vector3(-_hx, 0.68, 0), Vector3.ONE * 0.12)
	_hr = Parts.part("ball", skin, Vector3(_hx, 0.68, 0), Vector3.ONE * 0.12)
	for n in [_fl, _fr, _hl, _hr]:
		inner.add_child(n)
	_phone = Parts.part("box", 0x1b1b1f, Vector3(0.54, 1.4, 0.1), Vector3(0.05, 0.24, 0.13))
	_phone.visible = false
	inner.add_child(_phone)
	var hat: String = o.get("hat", "")
	if hair != null:
		_hair(int(o.get("hair_style", 0)), hair, skin, hat in ["cap", "beret", "straw", "tophat", "tricorn", "chef"])
	var hatc: int = o.get("hat_color", 0xd9643a)
	match hat:
		"beret":
			_add("ball", 0x26262b, Vector3(0.04, 1.84, 0), Vector3(0.46, 0.13, 0.46))
			_add("ball", 0x26262b, Vector3(0, 1.98, 0), Vector3.ONE * 0.05)
		"bun":
			_add("ball", hair_c, Vector3(0, 1.93, -0.12), Vector3.ONE * 0.2)
		"tricorn":
			_add("cyl", 0x1b1b1f, Vector3(0, 1.86, 0), Vector3(0.42, 0.22, 0.42))
			_add("box", 0x1b1b1f, Vector3(0, 1.9, -0.36), Vector3(0.9, 0.34, 0.08))
		"tophat":
			_add("cyl", 0x1b1b1f, Vector3(0, 1.84, 0), Vector3(0.56, 0.05, 0.56))
			_add("cyl", 0x1b1b1f, Vector3(0, 2.08, 0), Vector3(0.34, 0.5, 0.34))
		"cap":
			if hatc < 0:                         # red, with the gold on its peak and button
				hatc = 0xc0392b
			# a dome with a flat rim: it sits ON the head with a clean edge instead of blending into it
			_add("dome", hatc, Vector3(0, 1.6, -0.02), Vector3(0.535, 0.42, 0.545))
			_add("cyl", hatc, Vector3(0, 1.6, -0.02), Vector3(0.537, 0.035, 0.547))
			_add("box", hatc, Vector3(0, 1.6, 0.56), Vector3(0.5, 0.04, 0.36))
			_add("ball", hatc, Vector3(0, 2.02, -0.02), Vector3.ONE * 0.045)
			if int(o.get("hat_color", 0)) < 0:
				_add("box", 0xf2c230, Vector3(0, 1.625, 0.56), Vector3(0.5, 0.012, 0.36))
				_add("ball", 0xf2c230, Vector3(0, 2.03, -0.02), Vector3.ONE * 0.05)
			if o.has("emblem"):       # the mark of Ahorros Rurales on the front panel: the bank gives these caps away
				var mk := Brand.mark(0.3, o["emblem"])
				mk.position = Vector3(0, 1.8, 0.482)
				mk.rotation.x = -0.5
				neck.add_child(mk)
		"chef":
			_add("cyl", 0xffffff, Vector3(0, 1.9, 0), Vector3(0.37, 0.24, 0.37))
			_add("ball", 0xffffff, Vector3(0, 2.1, 0), Vector3(0.46, 0.2, 0.46))
		"straw":
			_add("cyl", 0xe6c56a, Vector3(0, 1.8, 0), Vector3(0.78, 0.04, 0.78))
			_add("cyl", 0xe6c56a, Vector3(0, 1.9, 0), Vector3(0.4, 0.22, 0.4))
			var band: int = o.get("hat_band", 0x26262b)          # the ribbon round the crown takes the colour chosen
			if band < 0:                                         # ...or the red, gold and red of the flag
				_add("cyl", 0xc0392b, Vector3(0, 1.855, 0), Vector3(0.412, 0.07, 0.412))
				_add("cyl", 0xf2c230, Vector3(0, 1.855, 0), Vector3(0.416, 0.034, 0.416))
			else:
				_add("cyl", band, Vector3(0, 1.855, 0), Vector3(0.412, 0.065, 0.412))
		"horns":
			for sx in [-1.0, 1.0]:
				_add("cone", 0x8a7a66, Vector3(sx * 0.25, 1.98, 0), Vector3(0.09, 0.4, 0.09))
			_add("ball", 0xffffff, Vector3(0, 1.12, 0.42), Vector3(0.1, 0.2, 0.08))
		"collar":
			_add("box", 0xffffff, Vector3(0, 0.98, 0.3), Vector3(0.16, 0.08, 0.06))
	_glasses(int(o.get("glasses", 0)))
	_earrings(int(o.get("earrings", 0)))
	_pendant(int(o.get("pendant", 0)), int(o.get("kerchief", 0xd23b3b)))
	Parts.thin(vis)                              # (eyes, buttons and earrings are not drawn from across the square)

## One foot, shod: 0 trainers · 1 boots · 2 alpargatas (canvas on a rope sole, ribbons round the ankle) · 3 flip-flops
func _foot(x: float, hex: int, kind: int, skin: int) -> Node3D:
	var f := Node3D.new()
	f.position = Vector3(x, 0.13, 0.05)
	var put := func(shape: String, colour: int, pos: Vector3, scl: Vector3) -> void:
		var m := Parts.part(shape, colour, pos, scl)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		f.add_child(m)
	match kind:
		1:      # boots: up over the ankle, a thick dark sole
			put.call("ball", hex, Vector3.ZERO, Vector3(0.155, 0.135, 0.205))
			put.call("cyl", hex, Vector3(0, 0.13, -0.06), Vector3(0.125, 0.24, 0.125))
			put.call("box", 0x26262b, Vector3(0, -0.105, 0.01), Vector3(0.3, 0.05, 0.42))
		2:      # alpargatas
			put.call("box", 0xd9b36a, Vector3(0, -0.1, 0.01), Vector3(0.28, 0.055, 0.4))
			put.call("ball", hex, Vector3(0, -0.02, 0.02), Vector3(0.14, 0.09, 0.19))
			put.call("box", hex, Vector3(0, 0.07, -0.07), Vector3(0.2, 0.025, 0.025))
			put.call("box", hex, Vector3(0, 0.12, -0.08), Vector3(0.18, 0.025, 0.025))
		3:      # flip-flops: the foot shows
			put.call("box", hex, Vector3(0, -0.105, 0.01), Vector3(0.26, 0.04, 0.4))
			put.call("ball", skin, Vector3(0, -0.03, 0.0), Vector3(0.12, 0.085, 0.17))
			put.call("box", hex, Vector3(0, 0.035, 0.06), Vector3(0.25, 0.03, 0.045))
		_:      # trainers: a white sole and toe
			put.call("ball", hex, Vector3.ZERO, Vector3(0.15, 0.13, 0.2))
			put.call("box", 0xf4f1e8, Vector3(0, -0.1, 0.01), Vector3(0.29, 0.045, 0.4))
			put.call("ball", 0xf4f1e8, Vector3(0, -0.03, 0.15), Vector3(0.11, 0.07, 0.07))
	return f

# ---------------- clothes ----------------
func _clothes(top: int, shirt: int, skin: int) -> void:
	var sc := Parts.col(shirt)
	var detail: int = 0x2a2a30 if sc.r * 0.3 + sc.g * 0.59 + sc.b * 0.11 > 0.55 else 0xf4f1e8
	var collar := func(hex: int) -> void:
		for sx in [-1.0, 1.0]:
			var c := _acc("box", hex, Vector3(sx * 0.1, 0.965, _r(0.96) - 0.005), Vector3(0.17, 0.07, 0.05))
			c.rotation.z = sx * 0.55
	match top:
		1:      # shirt: a collar and a row of buttons
			collar.call(_mix(shirt, 0xffffff, 0.45))
			for by in [0.84, 0.69, 0.54, 0.39]:
				_dot(detail, 0.0, by, 0.022)
		2:      # striped T-shirt
			for by in [0.84, 0.64, 0.44]:
				_band(detail, by, 0.085)
		3:      # checked shirt
			collar.call(_mix(shirt, 0xffffff, 0.45))
			for by in [0.86, 0.7, 0.54, 0.38]:
				_band(detail, by, 0.035)
			for k in range(8):
				_strip(detail, k * TAU / 8.0 + 0.39, 0.28, 0.97, 0.035)
		4:      # tracksuit: a zip, a white collar and a stripe down each arm
			_strip(0xf4f1e8, 0.0, 0.3, 0.95, 0.03)
			_band(0xf4f1e8, 0.955, 0.07)
			for sx in [-1.0, 1.0]:
				_strip(0xf4f1e8, sx * PI / 2.0, 0.28, 0.93, 0.075)
		5:      # dungarees
			var denim := 0x3b5f8f
			_band(denim, 0.42, 0.34, 0.012)
			_strip(denim, 0.0, 0.52, 0.84, 0.36 * _girth)
			for sx in [-1.0, 1.0]:
				_strip(denim, sx * 0.44, 0.78, 0.985, 0.07)
				_strip(denim, PI + sx * 0.44, 0.55, 0.985, 0.07)
				_dot(0xe6b422, sx * 0.44, 0.8, 0.028)
		6:      # shirt and braces
			collar.call(_mix(shirt, 0xffffff, 0.45))
			_band(0x3a3a40, 0.36, 0.22, 0.012)
			for sx in [-1.0, 1.0]:
				_strip(0xb23a3a, sx * 0.4, 0.46, 0.985, 0.055)
				_strip(0xb23a3a, PI + sx * 0.4, 0.46, 0.985, 0.055)
		7:      # a housecoat with flowers on it
			collar.call(_mix(shirt, 0xffffff, 0.6))
			for i in range(16):
				_dot([0xf4f1e8, 0xef8fa9, 0xf2c230, 0xf4f1e8][i % 4], i * 2.4, 0.3 + fmod(i * 0.37, 0.62), 0.036)
			for by in [0.82, 0.62, 0.42]:
				_dot(detail, 0.0, by, 0.024)
		9:      # a black leather jacket, open over the top, and a skirt with red all over it
			var leather := 0x1b1b1f
			for k in range(9):
				_strip(leather, 0.72 + k * (TAU - 1.44) / 8.0, 0.52, 0.99, 0.3, 0.02)
			for sx in [-1.0, 1.0]:
				_strip(0x303036, sx * 0.5, 0.56, 0.99, 0.1, 0.03)                # the lapels
				_dot(0xc9ced4, sx * 0.62, 0.66, 0.022)                           # a stud on each
			_band(0xe9e2d0, 0.4, 0.3, 0.012)
			for i in range(26):
				_dot(0xd9523c, i * 2.4, 0.28 + fmod(i * 0.37, 0.24), 0.045)
		10:     # a big sweatshirt with half a zip: white collar, a white band across the chest, red on the sleeves; leopard-print trousers below
			_band(0xf1eee6, 0.66, 0.11, 0.012)
			for sx in [-1.0, 1.0]:
				_strip(0xd42a2a, sx * PI / 2.0, 0.5, 0.58, 0.34, 0.016)              # the red band on each sleeve
				_strip(0xf1eee6, sx * PI / 2.0, 0.62, 0.72, 0.34, 0.017)
			_strip(0x9aa0a6, 0.0, 0.72, 0.965, 0.025, 0.02)                          # the zip
			collar.call(0xf1eee6)
			for sx in [-1.0, 1.0]:                                                   # the three colours along the collar's edge
				var trim := _acc("box", 0xe6b422, Vector3(sx * 0.1, 0.94, _r(0.94) + 0.012), Vector3(0.17, 0.014, 0.05))
				trim.rotation.z = sx * 0.55
			_band(0xc9a070, 0.36, 0.24, 0.014)                                       # the trousers
			for i in range(34):
				_dot(0x2a1c14, i * 2.4, 0.26 + fmod(i * 0.37, 0.2), 0.03)
				_dot(0x7a5230, i * 2.4 + 0.07, 0.27 + fmod(i * 0.37, 0.2), 0.017)
		8:      # a vest: bare shoulders
			_band(skin, 0.955, 0.09, 0.004)
			for sx in [-1.0, 1.0]:
				_strip(shirt, sx * 0.36, 0.9, 0.995, 0.09, 0.016)
				_strip(shirt, PI + sx * 0.36, 0.9, 0.995, 0.09, 0.016)

# ---------------- hair ----------------
func _hair(style: int, hair: int, skin: int, hatted: bool) -> void:
	var cropped := _mix(hair, skin, 0.35)
	if style == 3 or style == 6:
		_add("ball", cropped, Vector3(0, 1.53, -0.05), Vector3(0.506, 0.37, 0.506))        # shaved close: the scalp shows through
	elif style == 10:
		_add("ball", hair, Vector3(0, 1.34, -0.1), Vector3(0.515, 0.22, 0.48))             # only round the back and sides
	elif style != 4 or hatted:
		_add("ball", hair, Vector3(0, 1.5, -0.06), Vector3(0.5, 0.42, 0.5))                # the ordinary head of hair
	match style:
		1:      # bun
			_add("ball", hair, Vector3(0, 1.72, -0.42), Vector3.ONE * 0.19)
		2:      # long, down to the shoulders
			_add("ball", hair, Vector3(0, 1.22, -0.2), Vector3(0.5, 0.52, 0.36))
		4:      # afro
			if hatted:
				for sx in [-1.0, 1.0]:
					_add("ball", hair, Vector3(sx * 0.42, 1.36, -0.14), Vector3(0.24, 0.26, 0.3))
				_add("ball", hair, Vector3(0, 1.34, -0.4), Vector3(0.44, 0.28, 0.26))
			else:
				_add("ball", hair, Vector3(0, 1.62, -0.2), Vector3(0.68, 0.6, 0.6))
				_add("ball", hair, Vector3(0, 1.8, 0.2), Vector3(0.42, 0.2, 0.3))
		5:      # ponytail
			_add("ball", hair, Vector3(0, 1.62, -0.5), Vector3.ONE * 0.1)
			_add("ball", hair, Vector3(0, 1.32, -0.6), Vector3(0.12, 0.32, 0.12))
		6:      # mohawk
			if not hatted:
				for k in range(6):
					var a := -0.75 + k * 0.42
					_add("ball", hair, Vector3(0, 1.4 + cos(a) * 0.56, -sin(a) * 0.56), Vector3(0.07, 0.16, 0.15))
		7:      # pigtails
			for sx in [-1.0, 1.0]:
				_add("ball", hair, Vector3(sx * 0.52, 1.36, -0.1), Vector3(0.14, 0.27, 0.14))
				_acc("ball", 0xd23b3b, Vector3(sx * 0.5, 1.56, -0.1), Vector3.ONE * 0.06)
		8:      # quiff
			if not hatted:
				_add("ball", hair, Vector3(0, 1.86, 0.24), Vector3(0.3, 0.19, 0.27))
		9:      # bob
			_add("ball", hair, Vector3(0, 1.33, -0.12), Vector3(0.54, 0.4, 0.44))
		11:     # curls
			for i in range(11):
				var phi := i * 2.4
				var el := 0.25 + (i % 4) * 0.33
				var at := Vector3(cos(el) * sin(phi), sin(el), cos(el) * cos(phi)) * 0.5
				if (at.z > 0.24 and at.y < 0.36) or (hatted and at.y > 0.16):
					continue                         # not over the face, not through the hat
				_add("ball", hair, Vector3(0, 1.42, -0.04) + at, Vector3.ONE * 0.14)
		12:     # a plait down the back
			for k in range(4):
				_add("ball", hair, Vector3(0, 1.3 - k * 0.2, -0.5 + k * k * 0.004), Vector3.ONE * (0.13 - k * 0.012))
			_acc("ball", 0xd23b3b, Vector3(0, 0.6, -0.47), Vector3.ONE * 0.05)

# ---------------- beards ----------------
func _beard(kind: int, hair_c: int, skin: int) -> void:
	match kind:
		1:      # moustache
			_acc("box", hair_c, Vector3(0, 1.26, 0.48), Vector3(0.26, 0.055, 0.05))
		2:      # beard
			_add("ball", hair_c, Vector3(0, 1.17, 0.3), Vector3(0.36, 0.26, 0.26))
		3:      # goatee
			_acc("ball", hair_c, Vector3(0, 1.1, 0.4), Vector3(0.11, 0.13, 0.09))
		4:      # the big moustache, ends drooping
			_acc("box", hair_c, Vector3(0, 1.265, 0.48), Vector3(0.38, 0.08, 0.06))
			for sx in [-1.0, 1.0]:
				_acc("ball", hair_c, Vector3(sx * 0.2, 1.2, 0.45), Vector3(0.05, 0.09, 0.04))
		5:      # three days without shaving: a scatter of little dots over the jaw and under the nose
			var dot := _mix(skin, hair_c, 0.78)
			for row in range(5):
				var yy := 1.05 + row * 0.052
				var half := 0.31 - absf(row - 2.4) * 0.035                      # how far round the face this row goes
				var count := 9 if row < 3 else 7
				for k in range(count):
					var a := (float(k) / (count - 1) * 2.0 - 1.0) * half * PI + (0.11 if row % 2 == 1 else 0.0)
					if row >= 3 and absf(a) < 0.3:
						continue                                               # (not over the mouth)
					var rr := 0.505 - maxf(0.0, 1.2 - yy) * 0.3                  # the head narrows towards the chin
					_acc("ball", dot, Vector3(sin(a) * rr, yy, cos(a) * rr), Vector3.ONE * 0.018)
			for k in range(5):                                                 # ...and under the nose
				_acc("ball", dot, Vector3((k - 2) * 0.045, 1.27, 0.497), Vector3.ONE * 0.016)
		6:      # the long beard
			_add("ball", hair_c, Vector3(0, 1.17, 0.3), Vector3(0.36, 0.26, 0.26))
			_add("ball", hair_c, Vector3(0, 0.98, 0.37), Vector3(0.25, 0.3, 0.15))
		7:      # sideburns
			for sx in [-1.0, 1.0]:
				_acc("box", hair_c, Vector3(sx * 0.475, 1.3, 0.13), Vector3(0.06, 0.32, 0.15))
		8:      # moustache and goatee, joined up
			_acc("box", hair_c, Vector3(0, 1.26, 0.48), Vector3(0.26, 0.055, 0.05))
			_acc("ball", hair_c, Vector3(0, 1.1, 0.4), Vector3(0.12, 0.12, 0.09))
			for sx in [-1.0, 1.0]:
				_acc("box", hair_c, Vector3(sx * 0.125, 1.18, 0.45), Vector3(0.04, 0.15, 0.05))

# ---------------- glasses ----------------
func _glasses(kind: int) -> void:
	if kind <= 0:
		return
	var frame: int = [0, 0xb9a36a, 0x1b1b1f, 0x4a4a52, 0x8d99ae, 0x1b1b1f, 0xc9a23a, 0x1b1b1f][mini(kind, 7)]
	var thick := 0.035 if kind == 2 else 0.016
	var ey := 1.42
	for sx in [-1.0, 1.0]:
		var ex: float = sx * 0.17
		match kind:
			1:
				_acc("ring_thin", frame, Vector3(ex, ey, 0.53), Vector3.ONE * 0.12).rotation.x = PI / 2.0
			2:
				_acc("ring", frame, Vector3(ex, ey, 0.535), Vector3.ONE * 0.135).rotation.x = PI / 2.0
			3:      # tube goggles: two stubby pipes with dull lenses, on a leather strap
				_acc("cyl", frame, Vector3(ex, ey, 0.55), Vector3(0.105, 0.17, 0.105)).rotation.x = PI / 2.0
				_acc("cyl", 0x9fb7a0, Vector3(ex, ey, 0.637), Vector3(0.085, 0.02, 0.085)).rotation.x = PI / 2.0
			4:      # opaque: you never see the eyes behind them
				_acc("ball", 0xe8f0f4, Vector3(ex, ey, 0.525), Vector3(0.115, 0.115, 0.025))
				_acc("ring_thin", frame, Vector3(ex, ey, 0.53), Vector3.ONE * 0.125).rotation.x = PI / 2.0
			5:      # sunglasses
				_acc("ball", 0x111114, Vector3(ex, ey, 0.525), Vector3(0.127, 0.1, 0.028))
			7:      # rectangular, of black acetate
				for e in [[0.0, 0.05, 0.25, 0.022], [0.0, -0.05, 0.25, 0.022], [-0.115, 0.0, 0.022, 0.1], [0.115, 0.0, 0.022, 0.1]]:
					_acc("box", frame, Vector3(ex + e[0], ey + e[1], 0.53), Vector3(e[2], e[3], 0.02))
			6:      # aviators
				_acc("ball", 0x3f5a46, Vector3(ex, ey - 0.01, 0.525), Vector3(0.12, 0.118, 0.026))
				_acc("ring_thin", frame, Vector3(ex, ey - 0.01, 0.53), Vector3.ONE * 0.128).rotation.x = PI / 2.0
		if kind != 3:       # hinge and arm, back to where the ear would be
			_acc("box", frame, Vector3(sx * 0.325, ey + 0.02, 0.5), Vector3(0.1, thick, 0.02))
			var arm := _acc("box", frame, Vector3(sx * 0.445, ey + 0.02, 0.245), Vector3(thick, thick, 0.48))
			arm.rotation.y = -sx * 0.361
	_acc("box", frame, Vector3(0, ey + 0.02, 0.53), Vector3(0.11, thick * 1.2, 0.02))       # bridge
	if kind == 3:
		_acc("ring_thin", 0x5a4636, Vector3(0, ey + 0.02, 0.0), Vector3.ONE * 0.515)

# ---------------- earrings ----------------
func _earrings(kind: int) -> void:
	if kind <= 0:
		return
	var gold := 0xe6b422 if kind != 6 else 0xd4d9de           # (6: the same hoops, in silver)
	for sx in [-1.0, 1.0]:
		if kind == 3 and sx > 0.0:
			continue                       # just the one
		match kind:
			1:
				_acc("ball", gold, Vector3(sx * 0.505, 1.28, 0.03), Vector3.ONE * 0.037)
			2, 3, 6:
				_acc("ring", gold, Vector3(sx * 0.535, 1.2, 0.03), Vector3.ONE * 0.075).rotation.x = PI / 2.0
			4:
				_acc("ball", gold, Vector3(sx * 0.5, 1.27, 0.03), Vector3.ONE * 0.03)
				_acc("box", gold, Vector3(sx * 0.5, 1.19, 0.03), Vector3(0.015, 0.14, 0.015))
				_acc("ball", 0xd23b3b, Vector3(sx * 0.5, 1.1, 0.03), Vector3(0.04, 0.055, 0.04))
			5:
				_acc("ball", 0xf8f4ea, Vector3(sx * 0.51, 1.25, 0.03), Vector3.ONE * 0.052)

# ---------------- round the neck ----------------
func _pendant(kind: int, kerchief: int) -> void:
	if kind <= 0:
		return
	var metal := 0xcfd4d8 if kind == 3 else 0xe6b422
	if kind <= 3:
		_acc("ring_thin", metal, Vector3(0, 0.9, 0.04), Vector3.ONE * 0.37 * _girth).rotation.x = 0.32
	var front := _r(0.74) + 0.035
	match kind:
		2:      # a medal
			_acc("cyl", metal, Vector3(0, 0.755, front), Vector3(0.07, 0.016, 0.07)).rotation.x = PI / 2.0
		3:      # a cross
			_acc("box", metal, Vector3(0, 0.72, front), Vector3(0.032, 0.15, 0.02))
			_acc("box", metal, Vector3(0, 0.75, front), Vector3(0.1, 0.032, 0.02))
		4:      # pearls
			var rr := _r(0.86) + 0.02
			for k in range(11):
				var a := -1.25 + k * 0.25
				_acc("ball", 0xf8f4ea, Vector3(sin(a) * rr, 0.955 - 0.11 * cos(a), cos(a) * rr), Vector3.ONE * 0.036)
		5:      # the neckerchief of the fiestas, in the colour of your peña
			_acc("ring", kerchief, Vector3(0, 0.95, 0.0), Vector3.ONE * 0.345 * _girth).rotation.x = 0.16
			var tip := _acc("cone", kerchief, Vector3(0, 0.83, _r(0.83) + 0.022), Vector3(0.14, 0.22, 0.03))
			tip.rotation.z = PI

## walk with real collisions: slides along walls, cars and trees
## (People are carried a hand's breadth over the ground while they move and set down again where they end up: the
## slope of the street is then never an obstacle, and walls, cars and trees still are.)
func walk(dir: Vector2, speed: float) -> void:
	global_position.y = MapData.foot(p) + CLEAR
	velocity = Vector3(dir.x * speed, 0.0, dir.y * speed)
	move_and_slide()
	global_position.y = MapData.foot(p)

## move without sliding (thrown through the air). Returns true if it hit something.
func shove(delta_pos: Vector2) -> bool:
	global_position.y = MapData.foot(p) + CLEAR
	var hit := move_and_collide(Vector3(delta_pos.x, 0.0, delta_pos.y)) != null
	global_position.y = MapData.foot(p)
	return hit

func anim(moving: bool, dt: float, speed: float) -> void:
	_walk += dt * ((9.0 + speed) if moving else 0.0)
	var s := sin(_walk) if moving else 0.0
	_fl.position.z = 0.05 + s * 0.22
	_fr.position.z = 0.05 - s * 0.22
	_fl.position.y = 0.13 + maxf(0.0, s) * 0.1
	_fr.position.y = 0.13 + maxf(0.0, -s) * 0.1
	_hl.position = Vector3(-_hx, 0.68, -s * 0.2)
	_hr.position = Vector3(_hx, 0.68, s * 0.2)
	if guard:
		_hl.position = Vector3(-0.2, 1.16, 0.44)
		_hr.position = Vector3(0.2, 1.16, 0.44)
	if phone:
		_hr.position = Vector3(0.5, 1.28, 0.12)
	_phone.visible = phone
	if punch > 0.0:                    # right hand shoots forward and back
		punch = maxf(0.0, punch - dt)
		var k := sin((1.0 - punch / 0.28) * PI)
		_hr.position.z = 0.15 + k * 0.6
		_hr.position.y = 0.68 + k * 0.3
	inner.position.y = absf(cos(_walk)) * 0.07 if moving else sin(Time.get_ticks_msec() / 420.0 + _off) * 0.015
	if _hop > 0.0:
		_hop = maxf(0.0, _hop - dt)
		var up := sin((1.0 - _hop / HOP) * PI)
		inner.position.y += up * 0.8
		_fl.position.y += up * 0.12              # knees up, arms out
		_fr.position.y += up * 0.12
		_hl.position.y += up * 0.25
		_hr.position.y += up * 0.25

## The head turns towards `at` (a spot on the map), as far as a neck goes and no further; with nothing to look at
## (null), or with it behind them, it comes back to the front. The body goes on facing wherever it was going.
func look_at_spot(at, dt: float) -> void:
	var want := 0.0
	if at != null:
		var to: Vector2 = (at as Vector2) - p
		var turn := angle_difference(h, atan2(to.x, to.y))
		if absf(turn) < 2.3 and to.length_squared() > 0.09:      # (not craning at what is right behind)
			want = clampf(turn, -NECK_TURN, NECK_TURN)
	var now := lerp_angle(neck.rotation.y, want, 1.0 - exp(-7.0 * dt))
	if absf(now - neck.rotation.y) > 0.002:
		neck.rotation.y = now

func sync() -> void:
	if rotation.y != h:                # (writing a transform, even the same one, sends every part of the model off to be updated)
		rotation.y = h
	if vis.position.y != y:
		vis.position.y = y
