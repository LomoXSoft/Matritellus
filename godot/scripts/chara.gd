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
const HAND_SIZE := Vector3(0.12, 0.12, 0.12)
var _hl: MeshInstance3D
var _hr: MeshInstance3D
var _walk := 0.0
var _off := randf() * 6.0
var size := 1.0
var guard := false         # fists up in front of the face (boxing)
var phone := false         # holding a phone to the ear
var hand_at = null         # Vector3: where the right hand is held up, whatever else (motin.gd: a weapon shown off), null as usual
var _phone: Node3D
var punch := 0.0          # > 0 while throwing a punch (seconds left)
var look: Dictionary = {}  # what they were last made to look like
var _hop := 0.0            # > 0 while in the air of a little jump (seconds left)
const HOP := 0.6
var bat_t := 0.0           # > 0 while swinging the bat (seconds left): out it comes, round it goes, and away again
const BAT_SWING := 0.7
var _bat: Node3D

## Henry's bat, kept after the ham (the user, 14 November 2026): drawn over the right shoulder, swung across from
## right to left, and put away again
func swing_bat() -> void:
	if _bat == null or not is_instance_valid(_bat):
		_bat = Node3D.new()
		_bat.scale = Vector3.ONE / 0.12        # (the hand is a ball of 0.12: the bat keeps its own size)
		_bat.add_child(Parts.part("cyl", 0xc9a26b, Vector3(0, 0.4, 0), Vector3(0.05, 0.9, 0.05)))
		_bat.add_child(Parts.part("cyl", 0xb58a52, Vector3(0, 0.68, 0), Vector3(0.08, 0.36, 0.08)))
		_hr.add_child(_bat)
	_bat.visible = true
	bat_t = BAT_SWING

## where the hand is, and which way the bat points ([x tilt, turn]), through the swing (k 0..1)
## (the heads here are a metre across: the hand goes well out to the side and in front, or the bat is inside the head)
const _BAT_KEYS := [[0.0, Vector3(0.3, 0.7, 0.05), Vector2(0.2, 0.3)], [0.3, Vector3(0.75, 1.05, -0.35), Vector2(-0.5, 0.6)],
	[0.45, Vector3(0.8, 0.95, 0.4), Vector2(1.45, 2.2)], [0.6, Vector3(0.1, 0.9, 1.0), Vector2(1.5, -0.3)],
	[0.78, Vector3(-0.65, 0.95, 0.6), Vector2(1.5, -1.6)], [1.0, Vector3(0.2, 0.75, 0.3), Vector2(0.7, -0.9)]]
func bat_pose(k: float, bat: Node3D, reach := 1.0) -> void:
	for i in range(_BAT_KEYS.size() - 1):
		var a: Array = _BAT_KEYS[i]
		var b: Array = _BAT_KEYS[i + 1]
		if k <= float(b[0]):
			var t := smoothstep(float(a[0]), float(b[0]), k)
			_hr.position = (a[1] as Vector3).lerp(b[1], t)
			var r: Vector2 = (a[2] as Vector2).lerp(b[2], t)
			_hr.position.x *= reach
			bat.rotation = Vector3(r.x, r.y, 0.0)
			return

## A jump, on the spot or on the run. The body goes up with the figure, so a jump gets you up a step, a kerb or a raised
## pavement as high as it reaches (the user, 16 November 2026, stuck in the sunk bed by the bridge: "Se suponía que
## habíamos puesto el salto para poder saltar a aceras"). It is measured from the height it left (_hop_base), it
## comes down on whatever the feet are over (MapData.foot: the ground, a pavement, a deck), and never over a car.
var _hop_base := 0.0
var _drop := 0.0           # still in the air after a jump down off something (metres over the ground), and how fast it falls
var _drop_v := 0.0
func hop() -> bool:
	if _hop > 0.0:
		return false
	_hop = HOP
	hop_k = HOP_TAP
	_hop_base = global_position.y
	_drop = 0.0
	return true

## how high the feet are, in the jump, over the ground they are above now (0: on it)
func _hop_air() -> float:
	if _hop <= 0.0:
		return 0.0
	var up := sin((1.0 - _hop / HOP) * PI)
	return clampf(_hop_base + up * HOP_TOP * hop_k - global_position.y, 0.0, HOP_TOP + 2.0)      # (a stale jump, out of a car somewhere else, lifts no one)

## a car where the step would take you, at the height people walk (a jump does not carry you over one)
func _car_ahead(motion: Vector3) -> bool:
	var keep := collision_mask
	collision_mask = keep & 2
	var hit := collision_mask != 0 and test_move(global_transform, motion)
	collision_mask = keep
	return hit

## The jump goes higher the longer the key is held, while still on the way up (the user, 15 November 2026: a little
## higher than it was, and how high up to you). game.gd calls this every tick the key is down.
var hop_k := 0.5
const HOP_TAP := 0.55                # how much of the full height a tap gets
const HOP_TOP := 1.45                # metres, held all the way (it was 0.8 for any jump)
func hop_more(dt: float) -> void:
	if _hop > HOP * 0.5:                     # (only on the way up)
		hop_k = minf(1.0, hop_k + dt * 2.2)
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
	torso.name = "torso"
	var head := Node3D.new()
	head.name = "head"
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
	elif brows >= FIRST_CEJAS and brows - FIRST_CEJAS < CEJAS.size():      # (fitted over eyes of the ordinary size: up or down with bigger or smaller ones)
		_pieza_on(CEJAS[brows - FIRST_CEJAS], hair_c, 0, eh - 0.098)
	_beard(int(o.get("face", 0)), hair_c, skin)
	if int(o.get("barba3", 0)) == 1 and int(o.get("face", 0)) != 5:      # (three days' beard: an option of its own, with any beard or none)
		_barba3(hair_c)
	var ankle: int = o.get("socks", skin)            # (socks under sandals or slides: the foot shows in their colour)
	var shod: int = int(o.get("shoe_type", FIRST_CALZADO))     # (neighbours who say nothing of it: the new trainers, as the user asked on 16 Nov 2026)
	_fl = _foot(-0.17, shoes, shod, ankle)
	_fr = _foot(0.17, shoes, shod, ankle)
	_hl = Parts.part("ball", skin, Vector3(-_hx, 0.68, 0), HAND_SIZE)
	_hr = Parts.part("ball", skin, Vector3(_hx, 0.68, 0), HAND_SIZE)
	for n in [_fl, _fr, _hl, _hr]:
		inner.add_child(n)
	_phone = Parts.part("box", 0x1b1b1f, Vector3(0.54, 1.4, 0.1), Vector3(0.05, 0.24, 0.13))
	_phone.visible = false
	inner.add_child(_phone)
	var hat: String = o.get("hat", "")
	if hair != null:
		_hair(int(o.get("hair_style", 0)), hair, skin, hat_cut(hat))
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
		"straw":                                     # (down onto the head where it is as wide as the crown: it used to sit up on top, 16 Nov 2026)
			_add("cyl", 0xe6c56a, Vector3(0, 1.69, 0), Vector3(0.78, 0.04, 0.78))
			_add("cyl", 0xe6c56a, Vector3(0, 1.79, 0), Vector3(0.4, 0.22, 0.4))
			var band: int = o.get("hat_band", 0x26262b)          # the ribbon round the crown takes the colour chosen
			if band < 0:                                         # ...or the red, gold and red of the flag
				_add("cyl", 0xc0392b, Vector3(0, 1.745, 0), Vector3(0.412, 0.07, 0.412))
				_add("cyl", 0xf2c230, Vector3(0, 1.745, 0), Vector3(0.416, 0.034, 0.416))
			else:
				_add("cyl", band, Vector3(0, 1.745, 0), Vector3(0.412, 0.065, 0.412))
		"horns":
			for sx in [-1.0, 1.0]:
				_add("cone", 0x8a7a66, Vector3(sx * 0.25, 1.98, 0), Vector3(0.09, 0.4, 0.09))
			_add("ball", 0xffffff, Vector3(0, 1.12, 0.42), Vector3(0.1, 0.2, 0.08))
		"collar":
			_add("box", 0xffffff, Vector3(0, 0.98, 0.3), Vector3(0.16, 0.08, 0.06))
		_:
			if SOMBREROS.has(hat):                   # (from free models: in the colour chosen; red for the red-and-gold)
				_wear(SOMBREROS[hat], hatc if hatc >= 0 else 0xc0392b, true)
	_glasses(int(o.get("glasses", 0)))
	_earrings(int(o.get("earrings", 0)))
	_pendant(int(o.get("pendant", 0)), int(o.get("kerchief", 0xd23b3b)))
	if int(o.get("panuelo", 0)) == 1:
		_panuelo(int(o.get("pena", 0)), int(o.get("kerchief", 0xd23b3b)))
	if bool(o.get("smoke", false)):
		_cigarette()
	Parts.thin(vis)                              # (eyes, buttons and earrings are not drawn from across the square)

## A lit cigarette at the corner of the mouth (5 % of adult/elderly neighbours, never kids, plus Tomasa once she gets hers).
static var _ember_mat: StandardMaterial3D
static var _smoke_mesh: SphereMesh
func _cigarette() -> void:
	var cig := Node3D.new()
	cig.name = "cigarette"
	cig.position = Vector3(0.12, 1.19, 0.47)
	cig.rotation = Vector3(0.16, 0.22, -0.14)
	neck.add_child(cig)
	var add_bit := func(col: int, z: float, length: float, rad := 0.017) -> MeshInstance3D:
		var m := Parts.part("cyl", col, Vector3(0.0, 0.0, z), Vector3(rad, length, rad))
		m.rotation.x = PI / 2.0
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cig.add_child(m)
		return m
	add_bit.call(0xd99b4a, 0.03, 0.06, 0.018)        # orange filter butt
	add_bit.call(0xf4f2ec, 0.125, 0.13, 0.017)       # white paper tube
	add_bit.call(0x4a4846, 0.20, 0.024, 0.016)       # grey ash
	if _ember_mat == null:
		_ember_mat = StandardMaterial3D.new()
		_ember_mat.albedo_color = Color(1.0, 0.38, 0.08)
		_ember_mat.emission_enabled = true
		_ember_mat.emission = Color(1.0, 0.34, 0.06)
		_ember_mat.emission_energy_multiplier = 2.6
	var ember: MeshInstance3D = add_bit.call(0xff5514, 0.218, 0.016, 0.015)
	ember.material_override = _ember_mat
	var puff := CPUParticles3D.new()
	puff.position = Vector3(0.0, 0.01, 0.22)
	puff.amount = 4
	puff.lifetime = 1.1
	puff.explosiveness = 0.0
	puff.randomness = 0.35
	puff.direction = Vector3(0.0, 1.0, 0.0)
	puff.spread = 22.0
	puff.gravity = Vector3(0.0, 0.18, 0.0)
	puff.initial_velocity_min = 0.16
	puff.initial_velocity_max = 0.32
	puff.scale_amount_min = 0.55
	puff.scale_amount_max = 1.25
	if _smoke_mesh == null:
		_smoke_mesh = SphereMesh.new()
		_smoke_mesh.radius = 0.035
		_smoke_mesh.height = 0.07
		_smoke_mesh.radial_segments = 6
		_smoke_mesh.rings = 3
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(0.86, 0.86, 0.88, 0.38)
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_smoke_mesh.material = sm
	puff.mesh = _smoke_mesh
	puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cig.add_child(puff)

## One foot, shod: 0 trainers · 1 boots · 2 alpargatas (canvas on a rope sole, ribbons round the ankle) · 3 flip-flops
func _foot(x: float, hex: int, kind: int, skin: int) -> Node3D:
	var f := Node3D.new()
	f.position = Vector3(x, 0.13, 0.05)
	var put := func(shape: String, colour: int, pos: Vector3, scl: Vector3) -> void:
		var m := Parts.part(shape, colour, pos, scl)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		f.add_child(m)
	if kind == BAREFOOT:                         # nothing on: the plain foot, a ball (the user: "pies estándar sin calzado (dos bolas)")
		put.call("ball", skin, Vector3(0, -0.02, 0.02), Vector3(0.14, 0.11, 0.18))
		return f
	if kind >= FIRST_CALZADO:                    # a shoe from free models, in the colour chosen; the left one the right one mirrored
		var m := pieza(CALZADO[kind - FIRST_CALZADO]) if kind - FIRST_CALZADO < CALZADO.size() else null
		if m != null:
			var shoe := _dressed(m, hex)
			shoe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if x > 0.0:
				shoe.scale.x = -1.0
			f.add_child(shoe)
			if CALZADO[kind - FIRST_CALZADO] in OPEN_SHOES:     # (sandals and heels: the foot shows, bare or in its socks)
				put.call("ball", skin, Vector3(0, -0.035, 0.01), Vector3(0.115, 0.075, 0.165))
			return f
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
	if top == PENA_TEE:                          # the peña's T-shirt: plain, in the peña's colour (creator.gd look), its logo printed on the chest
		_pena_print(int(look.get("pena", 0)))
		return
	if top >= FIRST_ROPA:
		if top - FIRST_ROPA < ROPA.size():
			_wear(ROPA[top - FIRST_ROPA], shirt, false, [int(look.get("shirt2", -1)), int(look.get("shirt3", -1))])      # (its other parts: colour 2 and 3)
		return
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

# ---------------- hair, beards and eyebrows from free models ----------------
## The user, 16 November 2026: "Tenemos que importar assets de peinados, barbas y cejas, los que tenemos son muy básicos
## y algunos terribles (de momento no se borra nada) ... tienen que tener nuestra estética y ser de libre uso". These
## are free models (CC0: Quaternius, OverScore, The Wild Dodo; assets/creador/CREDITOS.txt) fitted onto our round heads
## by tools/creador/pelo.py (piezas.json): assets/creador/pelo/<name>.glb, in this model's own frame. A hairstyle has a
## second mesh, "gorro", for under a cap or a hat (nothing of it above the rim). They take the hair's colour, flat, as
## the rest of the model. The old styles stay where they were; these come after them.
const PELOS := ["pelo_raya", "pelo_rapao_fino", "pelo_melena_larga", "pelo_dos_monos", "pelo_rapao_ella", "pelo_afro", "pelo_pixie",
	"pelo_mullet", "pelo_coleta_alta", "pelo_trenza_larga", "pelo_rizos_cortos", "pelo_bob", "pelo_coletas_bajas", "pelo_cardado",
	"pelo_mono_abuela", "pelo_ondas", "pelo_flequillo", "pelo_desfilado"]          # hair_style 13 on
const BARBAS := ["barba_recortada", "barba_poblada", "barba_candao", "bigote_morsa"]      # face 9 on
const CEJAS := ["cejas_pobladas", "cejas_arqueadas"]                                    # brows 4 on
const FIRST_PELO := 13
const FIRST_BARBA := 9
const FIRST_CEJAS := 4
static var _piezas := {}

## the mesh of a piece; for hair under a hat, `cut` 1 is what shows under a cap (the "gorro" mesh, nothing over 1.6) and
## 2 what shows under a hat that sits higher (the "gorro_alto" mesh, nothing over 1.7: a straw hat, a beret); null if
## nothing of it shows under one
static func pieza(name: String, cut := 0) -> Mesh:
	if not _piezas.has(name):
		var got: Array = [null, null, null]
		var path := "res://assets/creador/pelo/%s.glb" % name
		if ResourceLoader.exists(path):
			var inst: Node = (load(path) as PackedScene).instantiate()
			for n in inst.find_children("*", "MeshInstance3D", true, false):
				var nm := String(n.name)
				got[2 if nm.begins_with("gorro_alto") else (1 if nm.begins_with("gorro") else 0)] = (n as MeshInstance3D).mesh
			inst.free()
		_piezas[name] = got
	return _piezas[name][clampi(cut, 0, 2)]

## how much of the hair a hat leaves: 0 all of it, 1 what is under a cap's rim, 2 what is under a higher hat's
static func hat_cut(hat: String) -> int:
	if hat in ["beret", "straw", "tophat", "tricorn", "chef"]:
		return 2
	if hat == "cap" or (SOMBREROS.has(hat) and hat != "diadema"):
		return 1
	return 0

## for hair, eyebrows and beards: the same, drawn on both sides (the packs make some locks single sheets; from the side
## they face away they were not drawn, and the scalp showed through: the user, 16 Nov 2026, "se ven calvas")
static var _hair_mats := {}
static func _vc_hair(hex: int) -> StandardMaterial3D:
	if not _hair_mats.has(hex):
		var m := _vc(hex).duplicate() as StandardMaterial3D
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_hair_mats[hex] = m
	return _hair_mats[hex]

## the flat colours of the pieces from free models, with the shading of their folds and layers (a vertex colour each
## carries: tools/creador/pelo.py dirt) multiplied in
static var _vc_mats := {}
static func _vc(hex: int) -> StandardMaterial3D:
	if not _vc_mats.has(hex):
		var m := Parts.mat(hex).duplicate() as StandardMaterial3D
		m.vertex_color_use_as_albedo = true
		_vc_mats[hex] = m
	return _vc_mats[hex]

## Clothes, hats, things round the neck and shoes from free models (the user, the same day: "Lo mismo que lo anterior
## pero con la ropa y complementos" and "Rework al calzado ... Usaremos assets de libre uso o pies estándar sin calzado
## (dos bolas)"), fitted by the same tool. The part of each with most of it takes the colour chosen (the shirt's, the
## hat's, the shoes'); the rest keeps its own (soles, buttons, stripes).
const SOMBREROS := {"parpusa": "gorro_parpusa", "fedora": "gorro_fedora", "bombin": "gorro_bombin", "pamela": "gorro_pamela",
	"panoleta": "gorro_panoleta", "diadema": "gorro_diadema", "beisbol": "gorro_beisbol", "beisbol_atras": "gorro_beisbol_atras",
	"vaquero": "gorro_vaquero"}
const ROPA := ["ropa_camisa_cuello", "ropa_sudadera_capucha", "ropa_jersey_cuello_alto", "ropa_plumas", "ropa_chaleco", "ropa_rebeca",
	"ropa_reflectante", "ropa_futbol", "ropa_marinera", "ropa_anorak"]       # top 11 on
const CUELLO := ["cuello_corbata", "cuello_pajarita", "cuello_delantal", "cuello_bufanda"]       # pendant 6 on
const CALZADO := ["calzado_zapatillas", "calzado_botas_faena", "calzado_botas_agua", "calzado_sandalias", "calzado_bailarinas",
	"calzado_camperas", "calzado_zapatillas_casa", "calzado_tacones"]        # shoe_type 5 on (4: bare feet)
const FIRST_ROPA := 11
const FIRST_CUELLO := 6
const BAREFOOT := 4
const FIRST_CALZADO := 5
const OPEN_SHOES := ["calzado_sandalias", "calzado_tacones"]
static var _own_mats := {}

## a piece in its colours: the first part in `hex`, the others in `extra` (the creator's colour 2 and 3 of the clothes;
## -1: as the piece comes) or else their own, matt (as everything here is)
static func _dressed(m: Mesh, hex: int, extra: Array = []) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.lod_bias = 100.0                     # (as the hair: the whole piece at any distance)
	for si in range(m.get_surface_count()):
		if si == 0:
			mi.set_surface_override_material(0, _vc(hex))
			continue
		if si - 1 < extra.size() and int(extra[si - 1]) >= 0:
			mi.set_surface_override_material(si, _vc(int(extra[si - 1])))
			continue
		var src := m.surface_get_material(si)
		if not _own_mats.has(src):
			var c := (src as BaseMaterial3D).albedo_color if src is BaseMaterial3D else Color(0.5, 0.5, 0.5)
			var own := _vc((int(c.r * 255.0) << 16) | (int(c.g * 255.0) << 8) | int(c.b * 255.0)) if c.a > 0.0 else _vc(0x808080)
			_own_mats[src] = own
		mi.set_surface_override_material(si, _own_mats[src])
	return mi

## puts a piece of clothing (or a hat) on: on the head (`head`) or the body, in `hex`
func _wear(name: String, hex: int, head: bool, extra: Array = []) -> MeshInstance3D:
	var m := pieza(name)
	if m == null:
		return null
	var mi := _dressed(m, hex, extra)
	if head:
		neck.add_child(mi)
	else:
		mi.scale = Vector3(_girth, 1.0, _girth)          # (as wide as the body is)
		inner.add_child(mi)
	return mi

## puts a piece on the head, in this colour (`lift`: up or down a little, as the eyebrows go with the eyes' size)
func _pieza_on(name: String, hex: int, cut := 0, lift := 0.0) -> MeshInstance3D:
	var m := pieza(name, cut)
	if m == null:
		return null
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = _vc_hair(hex)
	mi.lod_bias = 100.0                     # (never Godot's simplified meshes: thinned, the hair let the scalp show through in specks from a few metres)
	mi.position.y = lift
	neck.add_child(mi)
	return mi

## The classic head of an old lady's on a Saturday (the user, 16 November 2026: "para viejos, me gustaría añadir una
## cabeza con rulos clásica de señora mayor"): her hair short and close (the "pelusilla" piece) and, over the top of
## her head, rollers of pink, blue and yellow plastic with the hair wound round them, lying across the head in rows.
## (No free model of rollers was to be found: a roller is a drum, and the game has drums.) Under a hat, the hair only.
const RULOS := 31                                # hair_style
const _RULO_SPOTS := [[0.0, 52.0], [0.0, 74.0], [180.0, 72.0], [180.0, 48.0], [180.0, 26.0], [44.0, 46.0], [-44.0, 46.0],
	[90.0, 36.0], [-90.0, 36.0], [136.0, 40.0], [-136.0, 40.0], [62.0, 70.0], [-62.0, 70.0], [118.0, 64.0], [-118.0, 64.0]]     # [bearing, elevation] in degrees
const _RULO_PLASTIC := [0xf28cb5, 0x8cc3f2, 0xf2d36b]
func _rulos(hair: int, cut: int) -> void:
	_pieza_on("pelo_rapao_ella", hair, cut)
	if cut > 0:
		return
	for i in range(_RULO_SPOTS.size()):
		var b := deg_to_rad(float(_RULO_SPOTS[i][0]))
		var el := deg_to_rad(float(_RULO_SPOTS[i][1]))
		var out := Vector3(sin(b) * cos(el), sin(el), cos(b) * cos(el))          # (from the middle of the head)
		var along := Vector3(cos(b), 0.0, -sin(b))                               # (round the head, as a roller lies)
		var side := along.cross(out)                                             # (a drum's length is its y: along the head)
		var at := Vector3(0, 1.38, 0) + out * 0.565
		var core := _acc("cyl", hair, at, Vector3.ONE)                           # the hair wound round it
		core.transform = Transform3D(Basis(side * 0.062, along * 0.17, out * 0.062), at)
		var plastic: int = _RULO_PLASTIC[i % _RULO_PLASTIC.size()]
		for e in [-1.0, 1.0]:                                                    # and the plastic showing at its two ends
			var end := _acc("cyl", plastic, at, Vector3.ONE)
			end.transform = Transform3D(Basis(side * 0.074, along * 0.028, out * 0.074), at + along * e * 0.088)

## Bald, and shaved (the user, 16 November 2026: "Añade también calvo y rasurado (zona del cabello gris semitransparente)
## como peinados"): the shaved head is the scalp where the hair would grow -- the crown, the sides, the back down to
## the nape, up to the hairline in front -- in a see-through grey, its edge fading out. Built once (_rasurado_mesh).
const CALVO := 32                               # hair_style
const RASURADO := 33
static var _rasurado_mesh: ArrayMesh
static var _barba3_mesh: ArrayMesh
static var _shave_mat: StandardMaterial3D

## A see-through grey skin over part of the head (shaved hair, three days' beard): the ball a hair's breadth out, each
## point as solid as `alpha` says for its bearing round the head (radians, 0 in front, + to the left) and elevation
## (degrees), from elevation e0 up to e1. One material for both (_shave_mat).
static func _shave_zone(alpha: Callable, e0: float, e1: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const R := 0.506
	var at := func(b: float, e: float) -> Array:
		var d := Vector3(sin(b) * cos(deg_to_rad(e)), sin(deg_to_rad(e)), cos(b) * cos(deg_to_rad(e)))
		return [Vector3(0, 1.38, 0) + d * R, d, clampf(float(alpha.call(b, e)), 0.0, 1.0)]
	const NB := 72
	const DE := 3.0
	for i in range(NB):
		var b0 := TAU * i / NB - PI
		var b1 := TAU * (i + 1) / NB - PI
		var e := e0
		while e < e1:
			var ee := minf(e1, e + DE)
			var q: Array = [at.call(b0, e), at.call(b1, e), at.call(b1, ee), at.call(b0, ee)]
			if q[0][2] + q[1][2] + q[2][2] + q[3][2] > 0.0:
				for k in [0, 2, 1, 0, 3, 2]:
					st.set_normal(q[k][1])
					st.set_color(Color(1, 1, 1, q[k][2]))
					st.add_vertex(q[k][0])
			e = ee
	if _shave_mat == null:
		_shave_mat = StandardMaterial3D.new()
		_shave_mat.albedo_color = Color(0.26, 0.27, 0.29, 0.62)      # grey, see-through: the skin shows under it
		_shave_mat.vertex_color_use_as_albedo = true
		_shave_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_shave_mat.roughness = 1.0
		_shave_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return st.commit()

## (in the beard's colour: the user, 16 Nov 2026) where a beard grows on our faces: the jaw and the chin from ear to ear, over the lip, never up on the cheeks (their
## blush is at about 40 degrees round and 13 down); its edge fading out
static var _barba3_mats := {}
func _barba3(hex: int) -> void:
	if _barba3_mesh == null:
		const FADE := 6.0
		_barba3_mesh = _shave_zone(func(b: float, e: float) -> float:
			var side: float = absf(b)                                   # 0 in front, PI/2 at the ears
			var top: float = lerpf(-11.0, -21.0, smoothstep(0.0, 0.75, side)) + 26.0 * smoothstep(0.8, 1.45, side)      # up to under the nose in front, below the blush, up the sideburns to the ears
			var a_top: float = 1.0 - smoothstep(top - FADE, top, e)
			var a_side: float = 1.0 - smoothstep(1.55, 1.8, side)          # (not round the back of the neck)
			return a_top * a_side, -75.0, 12.0)
	var mi := MeshInstance3D.new()
	mi.mesh = _barba3_mesh
	if not _barba3_mats.has(hex):                  # (in the beard's colour: the hair's, see-through)
		var m := _shave_mat.duplicate() as StandardMaterial3D
		m.albedo_color = Color(Parts.col(hex), 0.55)
		_barba3_mats[hex] = m
	mi.material_override = _barba3_mats[hex]
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	neck.add_child(mi)

func _rasurado(hair: int) -> void:
	if _rasurado_mesh == null:
		const FADE := 7.0                            # degrees over which its edge fades out
		_rasurado_mesh = _shave_zone(func(b: float, e: float) -> float:
			var lowest: float = lerpf(-20.0, 36.0, pow((1.0 + cos(b)) / 2.0, 1.3))     # how far down the hair grows (1 in front, 0 behind)
			return smoothstep(lowest, lowest + FADE, e), -30.0, 90.0)
	var mi := MeshInstance3D.new()
	mi.mesh = _rasurado_mesh
	mi.material_override = _shave_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	neck.add_child(mi)

## The sides and back cut short and faded, under a quiff (the user's photo, 17 Nov 2026): the same zone as the shaved
## head, but in the hair's colour, thin at the bottom and thicker going up, where the quiff takes over.
static var _degradado_mesh: ArrayMesh
static var _degradado_mats := {}
func _degradado(hex: int) -> void:
	if _degradado_mesh == null:
		const FADE := 6.0
		_degradado_mesh = _shave_zone(func(b: float, e: float) -> float:
			var lowest: float = lerpf(-20.0, 36.0, pow((1.0 + cos(b)) / 2.0, 2.2))      # (lower down the temples than the shaved head's: short hair there too)
			return smoothstep(lowest, lowest + FADE, e) * lerpf(0.55, 1.0, smoothstep(lowest, lowest + 22.0, e)), -30.0, 90.0)
	if not _degradado_mats.has(hex):
		var m := _shave_mat.duplicate() as StandardMaterial3D
		m.albedo_color = Color(Parts.col(hex), 0.92)
		_degradado_mats[hex] = m
	var mi := MeshInstance3D.new()
	mi.mesh = _degradado_mesh
	mi.material_override = _degradado_mats[hex]
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	neck.add_child(mi)

# ---------------- hair ----------------
func _hair(style: int, hair: int, skin: int, cut: int) -> void:
	var hatted := cut > 0
	if style == CALVO:                      # nothing on top at all
		return
	if style == RASURADO:
		_rasurado(hair)
		return
	if style == RULOS:
		_rulos(hair, cut)
		return
	if style >= FIRST_PELO:
		if style - FIRST_PELO < PELOS.size():
			_pieza_on(PELOS[style - FIRST_PELO], hair, cut)
		return
	if style == 3:                          # shaved close, the scalp showing through. The creator no longer offers it (the user, 17 Nov 2026: it cuts
		_add("ball", _mix(hair, skin, 0.35), Vector3(0, 1.53, -0.05), Vector3(0.506, 0.37, 0.506))      # through the head; Rasurao instead), but the neighbours who wear it keep it
	elif style == 6:
		_rasurado(hair)                     # shaved close on the sides (the see-through grey, as the shaved head)
	elif style == 10:
		_add("ball", hair, Vector3(0, 1.34, -0.1), Vector3(0.515, 0.22, 0.48))             # only round the back and sides
	elif style == 8:                        # quiff: the top combed up from the forehead and back, the sides faded (it was a ball over the forehead
		_degradado(hair)                    # till the user, 17 Nov 2026, showed a photo: "debería ser algo como la foto"; tools/creador/tupe.py)
		if not hatted:
			_pieza_on("pelo_tupe", hair)
	elif style != 4 or hatted:
		_add("ball", hair, Vector3(0, 1.5, -0.06), Vector3(0.5, 0.42, 0.5))                # the ordinary head of hair
		if not hatted:                       # ...and over the crown and the top of the forehead, which it left bare (the user, 16 Nov 2026: "Arreglaría esta calva también")
			_add("dome", hair, Vector3(0, 1.665, 0.0), Vector3(0.43, 0.232, 0.43))
	match style:
		1:      # bun (bigger: the user, 17 Nov 2026)
			_add("ball", hair, Vector3(0, 1.76, -0.46), Vector3(0.27, 0.25, 0.27))
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
		6:      # mohawk: spikes, each pointing out from the head (pointed, not round: the user, 17 Nov 2026)
			if not hatted:
				for k in range(6):
					var a := -0.75 + k * 0.42
					var spike := _add("cone", hair, Vector3(0, 1.4 + cos(a) * 0.62, -sin(a) * 0.62), Vector3(0.06, 0.34, 0.14))
					spike.rotation.x = -a
		7:      # pigtails
			for sx in [-1.0, 1.0]:
				_add("ball", hair, Vector3(sx * 0.52, 1.36, -0.1), Vector3(0.14, 0.27, 0.14))
				_acc("ball", 0xd23b3b, Vector3(sx * 0.5, 1.56, -0.1), Vector3.ONE * 0.06)
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
	if kind >= FIRST_BARBA:
		if kind - FIRST_BARBA < BARBAS.size():
			_pieza_on(BARBAS[kind - FIRST_BARBA], hair_c)
		return
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
		5:      # three days without shaving: the shaved head's see-through grey, over where a beard grows (the user, 16 Nov 2026:
			# "Cambia la barba de tres días ... por el mismo efecto que rasurado, pero en la zona de la barba"; it was dots)
			_barba3(hair_c)
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
	if kind >= FIRST_CUELLO:                     # (from free models, in their own colours)
		if kind - FIRST_CUELLO < CUELLO.size():
			var m := pieza(CUELLO[kind - FIRST_CUELLO])
			if m != null:
				var src := m.surface_get_material(0)
				var c: Color = (src as BaseMaterial3D).albedo_color if src is BaseMaterial3D else Color(0.5, 0.5, 0.5)
				_wear(CUELLO[kind - FIRST_CUELLO], (int(c.r * 255.0) << 16) | (int(c.g * 255.0) << 8) | int(c.b * 255.0), false)
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

## Your peña's neckerchief, from the wardrobe at home (the user, 16 November 2026, with a photo of a fiesta neckerchief
## worn point down the back: "Un pañuelo del color de la peña con el graffiti estampado detrás"): rolled round the neck
## and knotted at the front, its point hanging down the back, lying on it, with the peña's logo printed on the cloth
## (assets/creador/panuelo_<id>.png, tools/creador/panuelos.py).
const PANUELO_IDS := ["nietos", "croquetilla", "bordillo", "centradito", "costrola", "al_prao"]      # (creator.gd PENA_IDS)
static var _panuelo_mats := {}
func _panuelo(pena: int, hex: int) -> void:
	var roll := _acc("ring", hex, Vector3(0, 0.945, 0.0), Vector3(0.335 * _girth, 0.42, 0.335 * _girth))       # the roll round the neck
	roll.rotation.x = 0.12
	var front := _r(0.9) + 0.03
	_acc("ball", hex, Vector3(0, 0.9, front), Vector3(0.075, 0.06, 0.05))                                      # the knot...
	for sx in [-1.0, 1.0]:                                                                                        # ...and its two ends
		var end := _acc("cone", hex, Vector3(sx * 0.05, 0.82, front - 0.005), Vector3(0.05, 0.13, 0.02))
		end.rotation = Vector3(0.0, 0.0, PI + sx * 0.35)
	# the point down the back: a triangle of cloth laid over the body (a cone), narrowing to its tip
	var id: String = PANUELO_IDS[clampi(pena, 0, PANUELO_IDS.size() - 1)]
	if not _panuelo_mats.has(id):
		var m := StandardMaterial3D.new()
		m.albedo_texture = Parts.texture("res://assets/creador/panuelo_%s.png" % id)
		if m.albedo_texture == null:
			m.albedo_color = Parts.col(hex)
		m.roughness = 1.0
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.rim_enabled = true
		m.rim = 0.35
		m.rim_tint = 0.6
		_panuelo_mats[id] = m
	const ROWS := 8
	const COLS := 8
	const TOP := 0.955               # where it comes out from under the roll
	const TIP := 0.4                 # how far down the back the point reaches
	const SPAN := 1.12               # how far round the back it reaches at the top, either way (radians)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var at := func(u: float, v: float) -> Array:
		var ang: float = PI + (u - 0.5) * 2.0 * SPAN * (1.0 - v)
		var yy: float = lerpf(TOP, TIP, v)
		var rr: float = _r(yy) + 0.018 + 0.012 * (1.0 - v)
		return [Vector3(sin(ang) * rr, yy, cos(ang) * rr), Vector2(0.5 + (u - 0.5) * (1.0 - v), v), Vector3(sin(ang), 0.19, cos(ang)).normalized()]
	for r in range(ROWS):
		for c in range(COLS):
			var q: Array = [at.call(float(c) / COLS, float(r) / ROWS), at.call(float(c + 1) / COLS, float(r) / ROWS),
				at.call(float(c + 1) / COLS, float(r + 1) / ROWS), at.call(float(c) / COLS, float(r + 1) / ROWS)]
			for k in [0, 1, 2, 0, 2, 3]:
				st.set_normal(q[k][2])
				st.set_uv(q[k][1])
				st.add_vertex(q[k][0])
	var cloth := MeshInstance3D.new()
	cloth.mesh = st.commit()
	cloth.material_override = _panuelo_mats[id]
	cloth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inner.add_child(cloth)

## The peña's T-shirt, from the wardrobe at home (the user, 16 November 2026: "Aparte del pañuelo el armario también
## tiene una camiseta básica con el logo de la peña y su color principal"): the plain T-shirt (the body in the peña's
## colour) with the peña's logo printed across the chest, lying on the body (a cone) as the neckerchief lies on the back.
const PENA_TEE := 21                         # top
static var _print_mats := {}
func _pena_print(pena: int) -> void:
	var id: String = PANUELO_IDS[clampi(pena, 0, PANUELO_IDS.size() - 1)]
	if not _print_mats.has(id):
		var m := StandardMaterial3D.new()
		m.albedo_texture = Parts.texture("res://assets/penas/%s.png" % id)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 1.0
		m.albedo_color = Color(0.96, 0.96, 0.96)       # (a print on cotton, a touch duller than the paint on a wall)
		_print_mats[id] = m
	var m: StandardMaterial3D = _print_mats[id]
	var aspect := 1.0
	if m.albedo_texture != null:
		aspect = float(m.albedo_texture.get_width()) / float(m.albedo_texture.get_height())
	const TALL := 0.36                       # how tall the print is
	const MID := 0.66                        # the height of its middle
	var wide := TALL * aspect
	var r_mid := _r(MID) + 0.01
	var span := wide / r_mid                 # (radians round the body)
	const ROWS := 6
	const COLS := 10
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var at := func(u: float, v: float) -> Array:
		var ang: float = (u - 0.5) * span
		var yy: float = MID + (0.5 - v) * TALL
		var rr: float = _r(yy) + 0.01
		return [Vector3(sin(ang) * rr, yy, cos(ang) * rr), Vector2(u, v), Vector3(sin(ang), 0.19, cos(ang)).normalized()]
	for row in range(ROWS):
		for c in range(COLS):
			var q: Array = [at.call(float(c) / COLS, float(row) / ROWS), at.call(float(c + 1) / COLS, float(row) / ROWS),
				at.call(float(c + 1) / COLS, float(row + 1) / ROWS), at.call(float(c) / COLS, float(row + 1) / ROWS)]
			for k in [0, 1, 2, 0, 2, 3]:            # (clockwise, seen from in front)
				st.set_normal(q[k][2])
				st.set_uv(q[k][1])
				st.add_vertex(q[k][0])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inner.add_child(mi)

## walk with real collisions: slides along walls, cars and trees
## (People are carried a hand's breadth over the ground while they move and set down again where they end up: the
## slope of the street is then never an obstacle, and walls, cars and trees still are.)
## In a jump they are carried as high as their feet are, over a kerb or a pavement's wall (see hop).
func walk(dir: Vector2, speed: float) -> void:
	var air := _hop_air()
	var was := global_position.y
	global_position.y = _stand(p, was, air, false) + CLEAR
	velocity = Vector3(dir.x * speed, 0.0, dir.y * speed)
	# (the player can jump on to a car: its shape stops a jump that does not clear it, car.gd. Nobody else jumps at one)
	if air > 0.0 and (car_floor.is_valid() or not _car_ahead(velocity * get_physics_process_delta_time() + Vector3(dir.x, 0.0, dir.y) * 0.1)):
		global_position.y += air
	move_and_slide()
	global_position.y = _stand(p, was, air, true)

## On a car (the user, 17 Nov 2026: "Me gustaría poder subirme a un capó de un salto"): the player stands on the roof, the
## bonnet or the boot of a car under them if their feet are up there already -- a jump that has cleared it, or standing on
## it -- and comes off it walking over its edge (the rest of the way down a fall). `car_floor`: game.gd car_floor_at,
## [the car, the height of its top there] or null; only the player has one.
var car_floor := Callable()
var on_car = null                          # the car stood on, if it is one (it carries you: game.gd _ride_car)
var _raised := false                       # standing on something over the ground (a car, a parapet, a low wall)
const CAR_STEP := 0.35                     # how far under a car's top the feet may be and still go up on to it
func _stand(q: Vector2, was: float, air: float, final: bool) -> float:
	var ground := MapData.foot(q)
	if not car_floor.is_valid():
		return ground
	var top = car_floor.call(q, was + air)
	if top != null and float(top[1]) > ground + 0.05 and was + air >= float(top[1]) - CAR_STEP:
		if final:
			on_car = top[0]
			_raised = true
		return float(top[1])
	if final:
		if _raised and _hop <= 0.0 and was - ground > 0.3:      # walked off it: the rest of the way down is a fall
			_drop = maxf(_drop, was - ground)
			_drop_v = 0.0
		on_car = null
		_raised = false
	return ground

## move without sliding (thrown through the air). Returns true if it hit something.
func shove(delta_pos: Vector2) -> bool:
	global_position.y = MapData.foot(p) + CLEAR
	var hit := move_and_collide(Vector3(delta_pos.x, 0.0, delta_pos.y)) != null
	global_position.y = MapData.foot(p)
	return hit

## Every part is written only when it has moved: writing a position, even the one it already has, sends every piece
## under that part off to be placed again, and a body is fifty pieces (the user's 2K at 30-odd fps, 16 Nov 2026).
## `bob`: the little rise and fall of somebody standing about (nobody sees it from more than a few metres off).
func anim(moving: bool, dt: float, speed: float, bob := true) -> void:
	_walk += dt * ((9.0 + speed) if moving else 0.0)
	var s := sin(_walk) if moving else 0.0
	var fl := Vector3(_fl.position.x, 0.13 + maxf(0.0, s) * 0.1, 0.05 + s * 0.22)
	var fr := Vector3(_fr.position.x, 0.13 + maxf(0.0, -s) * 0.1, 0.05 - s * 0.22)
	var hl := Vector3(-_hx, 0.68, -s * 0.2)
	var hr := Vector3(_hx, 0.68, s * 0.2)
	if guard:
		hl = Vector3(-0.2, 1.16, 0.44)
		hr = Vector3(0.2, 1.16, 0.44)
	if phone:
		hr = Vector3(0.5, 1.28, 0.12)
	if hand_at != null:
		hr = hand_at
	if _phone.visible != phone:
		_phone.visible = phone
	if punch > 0.0:                    # right hand shoots forward and back
		punch = maxf(0.0, punch - dt)
		var k := sin((1.0 - punch / 0.28) * PI)
		hr.z = 0.15 + k * 0.6
		hr.y = 0.68 + k * 0.3
	if bat_t > 0.0 and _bat != null:   # the bat: up over the shoulder, round, and down
		bat_t = maxf(0.0, bat_t - dt)
		bat_pose(1.0 - bat_t / BAT_SWING, _bat)
		_bat.visible = bat_t > 0.0
		hr = _hr.position              # (the swing has put the hand where it goes)
	var iy := absf(cos(_walk)) * 0.07 if moving else (sin(Time.get_ticks_msec() / 420.0 + _off) * 0.015 if bob else 0.0)
	if _drop > 0.0 and _hop <= 0.0:
		_drop_v += 22.0 * dt
		_drop = maxf(0.0, _drop - _drop_v * dt)
		iy += _drop
	if _hop > 0.0:
		_hop = maxf(0.0, _hop - dt)
		var up := sin((1.0 - _hop / HOP) * PI)
		var air := _hop_air()                    # (over what is under them now: less up on a pavement, more off one)
		if _hop < HOP * 0.5 and air <= 0.0:      # on the way down, and something higher than where they left is under them: landed
			_hop = 0.0
		elif _hop <= 0.0 and air > 0.05:         # jumped off something: the rest of the way down is a fall
			_drop = air
			_drop_v = 0.0
		iy += air
		fl.y += up * 0.12              # knees up, arms out
		fr.y += up * 0.12
		hl.y += up * 0.25
		hr.y += up * 0.25
	if not _fl.position.is_equal_approx(fl):
		_fl.position = fl
	if not _fr.position.is_equal_approx(fr):
		_fr.position = fr
	if not _hl.position.is_equal_approx(hl):
		_hl.position = hl
	if not _hr.position.is_equal_approx(hr):
		_hr.position = hr
	if absf(inner.position.y - iy) > 0.00001:   # (the standing bob moves less than a millimetre a frame: still written)
		inner.position.y = iy

## Ring colours keep the fists visible against these big heads and the crowd.
func box_gloves(colour := -1) -> void:
	var mat := Parts.mat(int(look.get("skin", 0xf6c9a0)) if colour < 0 else colour)
	for hand in [_hl, _hr]:
		hand.material_override = mat
		hand.scale = HAND_SIZE if colour < 0 else Vector3(0.18, 0.17, 0.20)

## Final hand positions for the ring, after the ordinary standing animation.
func box_hands(left: Vector3, right: Vector3) -> void:
	_hl.position = left
	_hr.position = right

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
