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
##   canas       grey hairs through the hair: 0 none · 1 streaks · 2 salt and pepper · 3 mostly grey (25 Nov 2026)
##   brow_color  the eyebrows' own colour (-1: the hair's)      nose  0 none · 1 a pink button · 2 a button
##   estampado   the print on a dress: 0 plain · 1 little flowers · 2 polka dots · 3 checks
##   toquilla    a crocheted shawl over the shoulders, its colour (-1: none)    mandil  a gingham apron, its colour (-1: none)

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
var _carro: Node3D = null  # the shopping trolley an old neighbour pulls along (look "carro"), its axle on the ground
var _carro_k := 0.0        # 0 stood upright beside them .. 1 tipped back on its wheels, pulled along
const CARRO_TIP := 0.68    # how far it leans back when pulled (radians from upright)
const CARRO_LONG := 0.72   # from its axle to its handle
var _phone: Node3D
var punch := 0.0          # > 0 while throwing a punch (seconds left)
var look: Dictionary = {}  # what they were last made to look like
var _hop := 0.0            # > 0 while in the air of a little jump (seconds left)
const HOP := 0.6
var bat_t := 0.0           # > 0 while swinging the bat (seconds left): out it comes, round it goes, and away again
const BAT_SWING := 0.7
var _bat: Node3D
var _eyes_open: Node3D
var _eyes_closed: Node3D
var _blink_wait := -1.0        # seconds until next blink (< 0 -> uninitialized random phase)
var _blink_t := -1.0           # >= 0 while a blink is in progress
var _blink_dur := 0.17         # total duration of the current blink (varies slightly each time)
var _blink_double := false     # true when a natural quick double-blink is queued

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
	if not o.has("shirt") or o.has("carro"):
		as_they_are = o.duplicate()
		as_they_are.erase("carro")                  # (no shopping trolley in a car's seat or at a table)
		if not o.has("shirt"):
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

## exact surface radius of the 12-gon body cone at height y and angle ang (0 = front)
func _r_at(at_y: float, ang: float) -> float:
	var sector := fposmod(ang, TAU / 12.0) - TAU / 24.0
	return _r(at_y) * (cos(TAU / 24.0) / cos(sector))

static var _band_meshes := {}
## a conical hoop hugging the body's slope (same 12-gon alignment as the body)
func _band(hex: int, at_y: float, tall: float, extra := 0.007) -> void:
	var y0 := at_y - tall / 2.0
	var y1 := at_y + tall / 2.0
	var key := "%d_%d_%d" % [int(round(y0 * 1000.0)), int(round(y1 * 1000.0)), int(round(extra * 1000.0))]
	if not _band_meshes.has(key):
		var c := CylinderMesh.new()
		c.top_radius = (0.44 - (y1 - 0.245) * 0.18667) + extra
		c.bottom_radius = (0.44 - (y0 - 0.245) * 0.18667) + extra
		c.height = tall
		c.radial_segments = 12
		c.rings = 1
		_band_meshes[key] = c
	var mi := MeshInstance3D.new()
	mi.mesh = _band_meshes[key]
	mi.material_override = Parts.mat(hex)
	mi.position = Vector3(0, at_y, 0)
	mi.scale = Vector3(_girth, 1.0, _girth)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inner.add_child(mi)

## surface slope angle of the body cone for the current build width (radians)
func _slope() -> float:
	return atan(0.18667 * _girth)

## a strip lying on the body's surface, running up it at angle `ang` round the body (0 = front)
func _strip(hex: int, ang: float, y0: float, y1: float, wide: float, lift := 0.012, depth := 0.02) -> void:
	var ym := (y0 + y1) / 2.0
	var r := _r(ym) + lift
	var m := _acc("box", hex, Vector3(sin(ang) * r, ym, cos(ang) * r), Vector3(wide, (y1 - y0) * 1.02, depth))
	m.rotation = Vector3(-_slope(), ang, 0)

func _dot(hex: int, ang: float, at_y: float, r: float, flat := 0.45, extra := 0.002) -> void:
	var rr := _r_at(at_y, ang) + extra
	var m := _acc("ball", hex, Vector3(sin(ang) * rr, at_y, cos(ang) * rr), Vector3(r, r, maxf(r * flat, 0.008)))
	m.rotation = Vector3(-_slope(), ang, 0)

## flat multi-petal tropical hibiscus + palm leaves hugging the 12-gon body cone (for the Hawaiian shirt)
func _hibiscus(ang: float, at_y: float, petal: int, leaf: int) -> void:
	var sl := -_slope()
	var rr := _r_at(at_y, ang)
	var d_ang := 0.095
	var d_y := 0.030
	for p: Vector2 in [Vector2(-1.0, 0.7), Vector2(1.0, 0.7), Vector2(-1.0, -0.7), Vector2(1.0, -0.7)]:
		var pa: float = ang + p.x * d_ang
		var py: float = at_y + p.y * d_y
		var pr := _r_at(py, pa) + 0.003
		var pm := _acc("ball", petal, Vector3(sin(pa) * pr, py, cos(pa) * pr), Vector3(0.030, 0.028, 0.008))
		pm.rotation = Vector3(sl, pa, 0)
	for side: float in [-1.0, 1.0]:
		var la: float = ang + side * 0.165
		var ly: float = at_y - 0.015 * side
		var lr := _r_at(ly, la) + 0.001
		var lm := _acc("ball", leaf, Vector3(sin(la) * lr, ly, cos(la) * lr), Vector3(0.034, 0.018, 0.007))
		lm.rotation = Vector3(sl, la, side * 0.45)
	var cm := _acc("ball", 0xf2c230, Vector3(sin(ang) * (rr + 0.006), at_y, cos(ang) * (rr + 0.006)), Vector3(0.017, 0.017, 0.008))
	cm.rotation = Vector3(sl, ang, 0)

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
	var top_id: int = int(o.get("top", 0))
	_hx = _r(0.68) + 0.096 + _top_pad(top_id) * _girth * 0.62
	var body_hex: int = o["shirt"]
	if top_id == 2:                                                  # suit and tie: crisp white shirt (soft ice-blue under a white jacket)
		var sc0 := Parts.col(body_hex)
		body_hex = 0xdbe6f2 if sc0.r * 0.3 + sc0.g * 0.59 + sc0.b * 0.11 > 0.85 else 0xf4f1e8
	elif top_id == 22:                                               # dress: bare shoulders / neckline above the bodice
		body_hex = skin
	elif top_id == REBECA_VESTIDO:                                   # a cardigan open over a dress: the dress shows down the front
		body_hex = _dress_hex(o)
	elif top_id == 24:                                               # lab/work coat: Colour 2 undershirt, or scrub-blue / white contrast
		var s2_b: int = int(o.get("shirt2", -1))
		if s2_b >= 0:
			body_hex = s2_b
		else:
			var sc_b := Parts.col(body_hex)
			body_hex = 0x3b78a8 if sc_b.r * 0.3 + sc_b.g * 0.59 + sc_b.b * 0.11 > 0.72 else 0xf4f1e8
	elif top_id == FIRST_ROPA + 4 or top_id == FIRST_ROPA + 5:       # open-front waistcoat and cardigan show a contrasting undershirt
		var sc := Parts.col(body_hex)
		body_hex = 0x2a2d36 if sc.r * 0.3 + sc.g * 0.59 + sc.b * 0.11 > 0.72 else 0xf4f1e8
	_add("body", body_hex, Vector3(0, 0.62, 0), Vector3(_girth, 1.0, _girth))
	_add("head", skin, Vector3(0, 1.38, 0), Vector3.ONE)
	_clothes(top_id, o["shirt"], skin)
	_layers(top_id)                              # (a toquilla and a mandil, over any top: 25 Nov 2026)
	# eyes, cheeks, brows
	var eye_c: int = o.get("eye_color", 0x5a3a22)
	var eyes: int = o.get("eyes", 0)
	var lashes: int = o.get("lashes", 0)
	var eh := _eyes(eyes, eye_c, lashes, skin)
	for sx in [-1.0, 1.0]:
		_acc("ball", 0xf59a8c, Vector3(sx * 0.3, 1.27, 0.37), Vector3(0.09, 0.06, 0.04))
	_nose(int(o.get("nose", 0)), skin)
	var brows: int = o.get("brows", 3)
	var brow_c: int = int(o.get("brow_color", -1))
	_brows(brows, brow_c if brow_c >= 0 else hair_c, eh)
	_beard(int(o.get("face", 0)), hair_c, skin)
	if int(o.get("barba3", 0)) == 1 and int(o.get("face", 0)) != 5:      # (three days' beard: an option of its own, with any beard or none)
		_barba3(hair_c)
	var ankle: int = o.get("socks", skin)            # (socks under sandals or slides: the foot shows in their colour)
	var shod: int = int(o.get("shoe_type", FIRST_CALZADO))     # (neighbours who say nothing of it: the new trainers, as the user asked on 16 Nov 2026)
	var fx: float = 0.17 * lerpf(1.0, _girth, 0.55)
	_fl = _foot(-fx, shoes, shod, ankle)
	_fr = _foot(fx, shoes, shod, ankle)
	_hl = Parts.part("ball", skin, Vector3(-_hx, 0.68, 0), HAND_SIZE)
	_hl.name = "hand_l"
	_hr = Parts.part("ball", skin, Vector3(_hx, 0.68, 0), HAND_SIZE)
	_hr.name = "hand_r"
	for n in [_fl, _fr, _hl, _hr]:
		inner.add_child(n)
	_phone = Parts.part("box", 0x1b1b1f, Vector3(0.54, 1.4, 0.1), Vector3(0.05, 0.24, 0.13))
	_phone.visible = false
	inner.add_child(_phone)
	var hat: String = o.get("hat", "")
	if hair != null:
		var n0 := neck.get_child_count()
		var i0 := inner.get_child_count()
		_hair(int(o.get("hair_style", 0)), hair, skin, hat_cut(hat))
		if int(o.get("canas", 0)) > 0:
			_canas(int(hair), int(o.get("canas", 0)), neck.get_children().slice(n0) + inner.get_children().slice(i0))
	var hatc: int = o.get("hat_color", 0xd9643a)
	match hat:
		"beret":
			var brt := _add("ball", 0x26262b, Vector3(0.04, 1.79, -0.01), Vector3(0.50, 0.145, 0.50))
			brt.rotation.z = -0.10
			_add("ball", 0x26262b, Vector3(0.055, 1.935, -0.01), Vector3.ONE * 0.048)
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
		"chef":                                      # classic pleated Animal Crossing chef toque (crisp dark outline rim + band + puffy cloud crown)
			_add("cyl", 0x38363a, Vector3(0, 1.70, 0), Vector3(0.432, 0.026, 0.432))
			_add("cyl", 0xf8f8f6, Vector3(0, 1.825, 0), Vector3(0.415, 0.23, 0.415))
			_add("ball", 0xf8f8f6, Vector3(0, 2.03, 0), Vector3(0.43, 0.21, 0.43))
			for k in range(6):
				var a := k * TAU / 6.0
				_add("ball", 0xf8f8f6, Vector3(sin(a) * 0.20, 2.01, cos(a) * 0.20), Vector3(0.27, 0.18, 0.27))
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
	_glasses(int(o.get("glasses", 0)), int(o.get("glasses_color", -1)))
	_earrings(int(o.get("earrings", 0)))
	_pendant(int(o.get("pendant", 0)), int(o.get("kerchief", 0xd23b3b)))
	if int(o.get("panuelo", 0)) == 1:
		_panuelo(int(o.get("pena", 0)), int(o.get("kerchief", 0xd23b3b)))
	if bool(o.get("smoke", false)):
		_cigarette()
	_carro = null
	if bool(o.get("carro", false)):
		_carrito(int(o.get("carro_color", 0xb8202a)), String(o.get("carro_dibujo", "")))
	Parts.thin(vis)                              # (eyes, buttons and earrings are not drawn from across the square)

## The Manchegan shopping trolley (the user, 25 Nov 2026: "quiero que lleven un carro de compra manchego los NPCs
## ancianos", with a photo): a tartan bag on a metal frame, a black flap over its top, two wheels, the handle in the right
## hand. Pulled along behind on its wheels; stood upright beside them when they stop. Built with its axle at the origin.
static var _tartan := {}
func _carrito(base: int, dibujo := "") -> void:
	var c := Node3D.new()
	c.name = "carro"
	inner.add_child(c)
	_carro = c
	_carro_k = 0.0
	var tkey := "%x_%s" % [base, dibujo]
	if not _tartan.has(tkey):
		var img := Image.create(16, 16, false, Image.FORMAT_RGB8)
		var b := Parts.col(base)
		var dark := Color(0.08, 0.08, 0.16)
		var cream := Color(0.95, 0.9, 0.72)
		for py in range(16):
			for px in range(16):
				var col := b
				if dibujo == "liso":                 # plain, a seam along its edge
					if px == 0 or py == 0:
						col = b.darkened(0.25)
				elif dibujo == "flores":             # little flowers on it: a pale bloom with a dot, in a staggered grid
					var fx: int = (px + (8 if (py / 8) % 2 == 1 else 0)) % 8
					var fy: int = py % 8
					var dd: int = absi(fx - 3) + absi(fy - 3)
					if dd == 0:
						col = Color(0.98, 0.82, 0.25)
					elif dd == 1:
						col = cream
					elif dd == 2 and (fx == 3 or fy == 3):
						col = b.lerp(cream, 0.5)
				else:                                # tartan
					var bx: bool = px < 3
					var by: bool = py < 3
					if bx and by:
						col = dark.lerp(b, 0.15)
					elif bx or by:
						col = b.lerp(dark, 0.62)
					if px == 9 or py == 9:
						col = col.lerp(cream, 0.7)
					elif px == 6 or py == 6 or px == 12 or py == 12:
						col = col.lerp(dark, 0.35)
				img.set_pixel(px, py, col)
		var m := StandardMaterial3D.new()
		m.albedo_texture = ImageTexture.create_from_image(img)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		m.uv1_triplanar = true
		m.uv1_scale = Vector3.ONE * 2.2
		m.roughness = 0.9
		_tartan[tkey] = m
	var metal := 0xb9bec4
	for sx in [-1.0, 1.0]:
		var w := Parts.part("cyl", 0x1c1c1e, Vector3(sx * 0.17, 0.0, 0.0), Vector3(0.17, 0.045, 0.17))
		w.rotation.z = PI / 2.0
		c.add_child(w)
		var hub := Parts.part("cyl", 0xd8d8d4, Vector3(sx * 0.19, 0.0, 0.0), Vector3(0.07, 0.012, 0.07))
		hub.rotation.z = PI / 2.0
		c.add_child(hub)
		c.add_child(Parts.part("cyl", metal, Vector3(sx * 0.14, 0.36, 0.11), Vector3(0.022, 0.72, 0.022)))      # the frame's two uprights
	var axle := Parts.part("cyl", metal, Vector3(0.0, 0.0, 0.0), Vector3(0.02, 0.36, 0.02))
	axle.rotation.z = PI / 2.0
	c.add_child(axle)
	var grip := Parts.part("cyl", 0x1a1a1a, Vector3(0.0, CARRO_LONG, 0.11), Vector3(0.035, 0.34, 0.035))
	grip.rotation.z = PI / 2.0
	c.add_child(grip)
	c.add_child(Parts.part("box", metal, Vector3(0.0, 0.06, -0.02), Vector3(0.3, 0.018, 0.26)))                   # the foot plate
	var bag := Parts.part("box", base, Vector3(0.0, 0.33, -0.02), Vector3(0.31, 0.46, 0.24))
	bag.material_override = _tartan[tkey]
	c.add_child(bag)
	c.add_child(Parts.part("box", 0x151515, Vector3(0.0, 0.575, -0.025), Vector3(0.325, 0.07, 0.255)))           # the flap over its top
	c.add_child(Parts.part("box", 0x151515, Vector3(0.0, 0.5, -0.146), Vector3(0.2, 0.14, 0.012)))               # ...hanging down its front
	c.add_child(Parts.part("box", 0x2a2a2a, Vector3(0.0, 0.44, -0.15), Vector3(0.05, 0.03, 0.014)))              # its buckle
	_carro_pose()

## where the trolley is for how far it is tipped (_carro_k): stood beside them, a little ahead, or pulled a step behind
func _carro_pose() -> void:
	if _carro == null:
		return
	_carro.position = Vector3(lerpf(_hx + 0.12, _hx + 0.06, _carro_k), 0.085, lerpf(0.1, -0.68, _carro_k))
	_carro.rotation = Vector3(CARRO_TIP * _carro_k, 0.0, 0.0)

## the right hand on the trolley's handle, wherever the trolley is
func _carro_hand() -> Vector3:
	var a := CARRO_TIP * _carro_k
	var at := _carro.position
	return Vector3(at.x, 0.085 + CARRO_LONG * cos(a) - 0.11 * sin(a), at.z + CARRO_LONG * sin(a) + 0.11 * cos(a))

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

## One foot, shod: 0 canvas trainers · 1 boots · 2 alpargatas · 3 flip-flops · 4 barefoot · 5..14 custom shoes (CALZADO)
func _foot(x: float, hex: int, kind: int, skin: int) -> Node3D:
	var f := Node3D.new()
	f.position = Vector3(x, 0.13, 0.05)
	var put := func(shape: String, colour: int, pos: Vector3, scl: Vector3) -> MeshInstance3D:
		var m := Parts.part(shape, colour, pos, scl)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		f.add_child(m)
		return m
	if kind == BAREFOOT:                         # nothing on: the plain foot, a ball (the user: "pies estándar sin calzado (dos bolas)")
		put.call("ball", skin, Vector3(0, -0.02, 0.02), Vector3(0.14, 0.11, 0.18))
		return f
	var shoe_name := ""
	if kind >= FIRST_CALZADO and kind - FIRST_CALZADO < CALZADO.size():
		shoe_name = CALZADO[kind - FIRST_CALZADO]
	elif kind >= 0 and kind < CALZADO_BASE.size():
		shoe_name = CALZADO_BASE[kind]
	var m := pieza(shoe_name) if shoe_name != "" else null
	if m != null:
		var shoe := _dressed(m, hex)
		shoe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if x > 0.0:
			shoe.scale.x = -1.0
		f.add_child(shoe)
		if shoe_name == "calzado_tacones":       # lifted & pitched inside the arched heel so the foot never pokes underneath
			var ft: MeshInstance3D = put.call("ball", skin, Vector3(0, 0.015, 0.005), Vector3(0.088, 0.062, 0.142))
			ft.rotation.x = 0.24
		elif shoe_name == "calzado_bailarinas":  # clean instep showing through the low-cut ballet flat opening
			put.call("ball", skin, Vector3(0, -0.025, 0.005), Vector3(0.095, 0.065, 0.138))
		elif shoe_name in OPEN_SHOES:            # flip-flops & sandals: bare/sock foot sitting on the contoured footbed
			put.call("ball", skin, Vector3(0, -0.028, 0.015), Vector3(0.105, 0.068, 0.160))
		return f
	put.call("ball", hex, Vector3.ZERO, Vector3(0.15, 0.13, 0.2))
	return f

# ---------------- clothes ----------------
func _clothes(top: int, shirt: int, skin: int) -> void:
	if top == PENA_TEE:                          # the peña's T-shirt: plain, in the peña's colour (creator.gd look), its logo printed on the chest
		_pena_print(int(look.get("pena", 0)))
		return
	var sc := Parts.col(shirt)
	var detail: int = 0x2a2a30 if sc.r * 0.3 + sc.g * 0.59 + sc.b * 0.11 > 0.55 else 0xf4f1e8
	if top == REBECA_VESTIDO:                    # a cardigan (colour 1) open over a dress (colour 2, with its print) to the knee
		var dress := _wear("ropa_vestido", _dress_hex(look), false)
		_print_on(dress, _dress_hex(look))
		var cardi := _wear("ropa_rebeca", shirt, false, [-1, int(look.get("shirt3", -1))])
		if cardi != null:
			cardi.scale *= Vector3(1.07, 1.0, 1.07)           # (over the dress, all round: at 1.035 it poked through at the back)
		# its fronts buttoned up from the hips to the chest, a V open above it to the neck (as on the picture), three
		# buttons and two patch pockets
		var lift: float = 0.05 * _girth
		var fronts := MeshInstance3D.new()
		fronts.mesh = _cardi_fronts(_girth, lift)
		fronts.material_override = _vc_hair(shirt)
		inner.add_child(fronts)
		for sx in [-1.0, 1.0]:
			_strip(_mix(shirt, 0x101018, 0.14), sx * 0.5, 0.37, 0.49, 0.13 * _girth, lift + 0.006, 0.012)
		for by in [0.6, 0.5, 0.4]:
			_dot(_mix(shirt, 0x101018, 0.35), 0.0, by, 0.022, 0.45, lift + 0.012 - (_r_at(by, 0.0) - _r(by)))
		return
	if top == 22:                                # dress (CC0 Cocktail Dress + waist sash in Colour 2)
		var dress22 := _wear("ropa_vestido", shirt, false)
		_print_on(dress22, shirt)
		var s2_v: int = int(look.get("shirt2", -1))
		var sash: int = s2_v if s2_v >= 0 else (0x2a2d36 if sc.r * 0.3 + sc.g * 0.59 + sc.b * 0.11 > 0.72 else 0xf4f1e8)
		_band(sash, 0.58, 0.055, 0.040)
		return
	if top == 23:                                # Hawaiian shirt: open camp collar, coconut buttons, flat tropical hibiscus + palm leaves
		var col_c := _mix(shirt, 0xffffff, 0.25)
		for sx in [-1.0, 1.0]:
			var c := _acc("box", col_c, Vector3(sx * 0.12, 0.962, _r(0.96) - 0.005), Vector3(0.16, 0.068, 0.045))
			c.rotation.z = sx * 0.62
		_dot(skin, 0.0, 0.965, 0.058, 0.25, 0.005)
		for by in [0.82, 0.67, 0.52, 0.37]:
			_dot(0xd9b37c, 0.0, by, 0.018, 0.45, 0.004)
		var warm := sc.r > 0.6 and sc.g < 0.48
		var petals: Array = [0xfaf6ee, 0x3bc2c2, 0xf7c948] if warm else [0xf2647d, 0xfaf6ee, 0xff9f43]
		var leaf_c: int = 0x1e6b3a if sc.g > 0.55 and sc.r < 0.55 else 0x2e8b57
		var spots := [
			Vector2(0.55, 0.76), Vector2(-0.62, 0.56), Vector2(0.45, 0.40),
			Vector2(-1.35, 0.72), Vector2(1.42, 0.50), Vector2(-1.50, 0.36),
			Vector2(2.35, 0.74), Vector2(-2.40, 0.54), Vector2(2.75, 0.38), Vector2(3.14, 0.72),
		]
		for i in range(spots.size()):
			var sp: Vector2 = spots[i]
			_hibiscus(sp.x, sp.y, int(petals[i % petals.size()]), leaf_c)
		return
	if top == 24:                                # lab/work coat (CC0 buttoned Blazer + buttons + pockets + pen)
		_wear("ropa_bata", shirt, false)
		var pock_c := _mix(shirt, detail, 0.22)
		for by in [0.68, 0.53, 0.38]:
			_dot(detail, 0.0, by, 0.019, 0.40, 0.043 * _girth)
		for sx in [-1.0, 1.0]:
			_strip(pock_c, sx * 0.46, 0.31, 0.46, 0.135 * _girth, 0.044 * _girth, 0.014)
		_strip(pock_c, -0.44, 0.68, 0.78, 0.092 * _girth, 0.043 * _girth, 0.014)
		_strip(0x2f6bb5, -0.42, 0.76, 0.83, 0.018, 0.047 * _girth, 0.014)      # pocket pen
		return
	if top >= FIRST_ROPA:
		if top - FIRST_ROPA < ROPA.size():
			_wear(ROPA[top - FIRST_ROPA], shirt, false, [int(look.get("shirt2", -1)), int(look.get("shirt3", -1))])      # (its other parts: colour 2 and 3)
		return
	var cw: float = lerpf(1.0, _girth, 0.65)
	var collar := func(hex: int) -> void:
		for sx in [-1.0, 1.0]:
			var c := _acc("box", hex, Vector3(sx * 0.1 * cw, 0.965, _r(0.96) - 0.005), Vector3(0.17 * cw, 0.07, 0.05))
			c.rotation.z = sx * 0.55
	match top:
		1:      # shirt: a collar and a row of buttons
			collar.call(_mix(shirt, 0xffffff, 0.45))
			for by in [0.84, 0.69, 0.54, 0.39]:
				_dot(detail, 0.0, by, 0.022)
		2:      # suit and tie (CC0 OverScore Proxy: buttoned Blazer + Neck Tie)
			_wear("ropa_traje", shirt, false, [int(look.get("shirt2", -1)), int(look.get("shirt3", -1))])
			var btn := _mix(shirt, 0x18181c, 0.55)
			for by in [0.60, 0.45]:
				_dot(btn, 0.0, by, 0.018, 0.40, 0.043 * _girth)
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
			var brace := 0x2a3b5c if sc.r > 0.6 and sc.g < 0.48 else 0xb23a3a
			for sx in [-1.0, 1.0]:
				_strip(brace, sx * 0.4, 0.46, 0.985, 0.055)
				_strip(brace, PI + sx * 0.4, 0.46, 0.985, 0.055)
		7:      # a housecoat with flowers on it
			collar.call(_mix(shirt, 0xffffff, 0.6))
			for i in range(16):
				_dot([0xf4f1e8, 0xef8fa9, 0xf2c230, 0xf4f1e8][i % 4], i * 2.4, 0.3 + fmod(i * 0.37, 0.62), 0.036, 0.25)
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
			_band(skin, 0.948, 0.098, 0.005)
			for sx in [-1.0, 1.0]:
				_strip(shirt, sx * 0.46, 0.896, 0.996, 0.068, 0.004, 0.012)
				_strip(shirt, PI + sx * 0.46, 0.896, 0.996, 0.068, 0.004, 0.012)

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

## how much of the hair a hat leaves: 0 all of it, 1 what is under a cap's rim, 2 what is under a higher hat's, 3 none
## (a headscarf)
static func hat_cut(hat: String) -> int:
	if hat == "panoleta":                        # (a headscarf covers it all, the sides and the back too: under a cap's cut the long
		return 3                                 # hair came through it -- the user, 25 Nov 2026, "Algunos peinados clippean sobre la pañoleta")
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
const CUELLO := ["cuello_corbata", "cuello_pajarita", "cuello_delantal", "cuello_bufanda",
	"cuello_camara", "cuello_flores", "cuello_gargantilla"]       # pendant 6 on
const GAFAS := {5: "gafas_sol", 6: "gafas_aviador", 8: "gafas_gato", 9: "gafas_corazon", 11: "gafas_parche"}
const CALZADO_BASE := ["calzado_lona", "calzado_botas", "calzado_alpargatas", "calzado_chanclas"]  # shoe_type 0..3
const CALZADO := ["calzado_zapatillas", "calzado_botas_faena", "calzado_botas_agua", "calzado_sandalias", "calzado_bailarinas",
	"calzado_camperas", "calzado_zapatillas_casa", "calzado_tacones", "calzado_misa", "calzado_zuecos"]  # shoe_type 5..14 (4: bare feet)
const FIRST_ROPA := 11
const FIRST_CUELLO := 6
const BAREFOOT := 4
const FIRST_CALZADO := 5
const OPEN_SHOES := ["calzado_chanclas", "calzado_sandalias", "calzado_bailarinas", "calzado_tacones"]
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

# ---------------- La Pili's look (the user, 25 Nov 2026, with a picture: "La Pili se parece muy poco a la referencia.
# Crea nuevos elementos de Lustre y Pintas si lo ves necesario") ----------------
const MATA := 35                                 # hair_style: a big mop of tight curls, round and wide, the ears and the forehead clear
const REBECA_VESTIDO := 25                       # top: a knitted cardigan open over a dress with a print, to the knee
const VESTIDO_DE_SERIE := 0x2b3352               # the dress's colour when colour 2 is "as it comes": navy

static func _dress_hex(o: Dictionary) -> int:
	var s2: int = int(o.get("shirt2", -1))
	return s2 if s2 >= 0 else VESTIDO_DE_SERIE

## the cardigan's body over the dress (the free model's gives it its sleeves, collar and hem), curved round the body: from the hips up, meeting down the middle
## (buttoned), a V open from the chest to the neck; cached by how wide the body is
static var _cardi_meshes := {}
func _cardi_fronts(girth: float, lift: float) -> ArrayMesh:
	var key := "%d" % int(round(girth * 100.0))
	if _cardi_meshes.has(key):
		return _cardi_meshes[key]
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var ROWS := 10
	var COLS := 16
	var sl: float = _slope()
	for side in [-1.0, 1.0]:
		var base := verts.size()
		for a in range(ROWS + 1):
			var y: float = lerpf(0.31, 0.97, float(a) / float(ROWS))
			var open_k: float = clampf((y - 0.62) / 0.35, 0.0, 1.0)
			var a0: float = -0.03 + 0.48 * open_k          # (just over the middle where it is buttoned)
			var a1: float = PI + 0.03                       # (round to the back as well: the free model's cardigan leaves a gap there)
			var r: float = _r(y) + lift + (0.004 if side < 0.0 else 0.0)
			for b in range(COLS + 1):
				var ang: float = side * lerpf(a0, a1, float(b) / float(COLS))
				verts.append(Vector3(sin(ang) * r, y, cos(ang) * r))
				norms.append(Vector3(sin(ang) * cos(sl), sin(sl), cos(ang) * cos(sl)))
				cols.append(Color(0.92, 0.92, 0.92))
		for a in range(ROWS):
			for b in range(COLS):
				var i0: int = base + a * (COLS + 1) + b
				var i1: int = i0 + COLS + 1
				if side > 0.0:
					idx.append_array([i0, i1, i0 + 1, i0 + 1, i1, i1 + 1])
				else:
					idx.append_array([i0, i0 + 1, i1, i0 + 1, i1 + 1, i1])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_COLOR] = cols
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_cardi_meshes[key] = m
	return m

## the mop: a hundred-odd lumpy curls on a shell round the head (none over the face, the hairline high on the forehead,
## down to the nape behind and to the top of the ears at the sides), over the ordinary head of hair so nothing shows
## between them. One mesh for everybody (cached), shaded at the bottom of each curl; under a hat, only what is under it.
static var _mata_mesh := {}
func _mata(hair: int, cut: int) -> void:
	_add("ball", hair, Vector3(0, 1.5, -0.06), Vector3(0.5, 0.42, 0.5))
	var key: int = clampi(cut, 0, 2)
	if not _mata_mesh.has(key):
		_mata_mesh[key] = _build_mata(key)
	var mi := MeshInstance3D.new()
	mi.mesh = _mata_mesh[key]
	mi.material_override = _vc_hair(hair)
	mi.lod_bias = 100.0
	neck.add_child(mi)

static func _build_mata(cut: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3535
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var C := Vector3(0.0, 1.40, -0.03)
	var top: float = 1.6 if cut == 1 else (1.7 if cut == 2 else 99.0)
	var n := 250
	for i in range(n):
		var yy: float = 1.0 - 2.0 * (float(i) + 0.5) / float(n)
		var rr: float = sqrt(maxf(0.0, 1.0 - yy * yy))
		var th: float = float(i) * 2.39996
		var d := Vector3(cos(th) * rr, yy, sin(th) * rr)
		d = (d + Vector3(rng.randf_range(-0.07, 0.07), rng.randf_range(-0.07, 0.07), rng.randf_range(-0.07, 0.07))).normalized()
		var zf: float = d.z
		var ymin: float
		if zf > 0.3:
			ymin = lerpf(0.30, 0.60, (zf - 0.3) / 0.7)
		elif zf > -0.3:
			ymin = lerpf(-0.18, 0.30, (zf + 0.3) / 0.6)
		else:
			ymin = lerpf(-0.18, -0.55, (-0.3 - zf) / 0.7)
		var keep_r1 := rng.randf()
		var keep_r2 := rng.randf()
		var keep_r3 := rng.randf()
		if d.y < ymin:
			continue
		var R: float = 0.51 + keep_r1 * 0.05 + 0.05 * maxf(d.y, 0.0)
		var c: Vector3 = C + d * R * Vector3(1.1, 1.0, 0.94)          # (wider at the sides than behind)
		if c.y > top:
			continue
		var s: float = lerpf(0.07, 0.10, keep_r2)
		var ph: float = keep_r3 * TAU
		var base := verts.size()
		var SEG := 7
		var RING := 5
		for a in range(RING + 1):
			var v: float = PI * float(a) / float(RING)
			for b in range(SEG + 1):
				var u: float = TAU * float(b) / float(SEG)
				var nn := Vector3(sin(v) * cos(u), cos(v), sin(v) * sin(u))
				var wob: float = 1.0 + 0.16 * sin(3.0 * u + ph) * sin(2.0 * v) + 0.06 * sin(5.0 * v + ph)
				var p: Vector3 = c + nn * s * wob
				verts.append(p)
				norms.append(nn)
				var out_k: float = clampf(nn.dot(d) * 0.5 + 0.5, 0.0, 1.0)
				var low_k: float = clampf((p.y - (C.y - 0.3)) / 0.5, 0.0, 1.0)
				var sh: float = lerpf(0.40, 1.0, out_k) * lerpf(0.7, 1.0, low_k)
				cols.append(Color(sh, sh, sh))
		for a in range(RING):
			for b in range(SEG):
				var i0: int = base + a * (SEG + 1) + b
				var i1: int = i0 + SEG + 1
				idx.append_array([i0, i0 + 1, i1, i0 + 1, i1 + 1, i1])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_COLOR] = cols
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m

## Grey hairs through any head of hair: whatever of the hairstyle is in the hair's colour gets a material that turns
## locks of it grey (patches of a noise, finely streaked, more of them the greyer you are). The procedural parts keep their
## own size in the noise, so the locks are the same size on all of them.
const CANAS_GREY := 0xcdcdd2
const CANAS_AMOUNT := [0.0, 0.30, 0.50, 0.78]
static var _canas_shader: Shader
static var _canas_mats := {}
static func _canas_mat(hex: int, level: int, vc: bool) -> ShaderMaterial:
	var key := "%x_%d_%s" % [hex, level, vc]
	if not _canas_mats.has(key):
		if _canas_shader == null:
			_canas_shader = Shader.new()
			_canas_shader.code = """shader_type spatial;
render_mode cull_disabled;
uniform vec4 base;
uniform vec4 grey;
uniform float amount;
uniform float use_vc;
varying vec3 op;
varying vec4 vcol;
float h3(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
float vnoise(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1,0,0)), f.x), mix(h3(i + vec3(0,1,0)), h3(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(h3(i + vec3(0,0,1)), h3(i + vec3(1,0,1)), f.x), mix(h3(i + vec3(0,1,1)), h3(i + vec3(1,1,1)), f.x), f.y), f.z);
}
void vertex() {
	vec3 sc = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	op = VERTEX * sc;
	vcol = COLOR;
}
void fragment() {
	float n = vnoise(op * vec3(4.5, 3.4, 4.5)) * 0.75 + vnoise(op * 10.0 + 7.0) * 0.25;
	float fine = vnoise(op * vec3(16.0, 34.0, 16.0));
	float t = 1.0 - amount;
	float g = smoothstep(t - 0.025, t + 0.025, n + (fine - 0.5) * 0.10);
	vec3 c = mix(base.rgb, grey.rgb, g);
	c *= mix(vec3(1.0), vcol.rgb, use_vc);
	ALBEDO = c;
	ROUGHNESS = 1.0;
	RIM = 0.35;
	RIM_TINT = 0.6;
}
"""
		var m := ShaderMaterial.new()
		m.shader = _canas_shader
		m.set_shader_parameter("base", Parts.col(hex).srgb_to_linear())          # (linear, as the material's albedo is)
		m.set_shader_parameter("grey", Parts.col(CANAS_GREY).srgb_to_linear())
		m.set_shader_parameter("amount", float(CANAS_AMOUNT[clampi(level, 0, CANAS_AMOUNT.size() - 1)]))
		m.set_shader_parameter("use_vc", 1.0 if vc else 0.0)
		_canas_mats[key] = m
	return _canas_mats[key]

func _canas(hex: int, level: int, nodes: Array) -> void:
	var want := Parts.col(hex)
	var todo: Array = nodes.duplicate()
	while not todo.is_empty():
		var n = todo.pop_back()
		todo.append_array(n.get_children())
		if not (n is MeshInstance3D):
			continue
		var mat = n.material_override
		if mat is StandardMaterial3D and (mat as StandardMaterial3D).albedo_color.is_equal_approx(want):
			n.material_override = _canas_mat(hex, level, (mat as StandardMaterial3D).vertex_color_use_as_albedo)

## a nose: 1 a little pink button (as the cheeks), 2 a button of the skin, a shade darker
func _nose(kind: int, skin: int) -> void:
	match kind:
		1:
			_acc("ball", _mix(skin, 0xf08a80, 0.55), Vector3(0.0, 1.345, 0.488), Vector3(0.062, 0.044, 0.036))
		2:
			_acc("ball", _mix(skin, 0x8a5c4a, 0.18), Vector3(0.0, 1.345, 0.49), Vector3(0.056, 0.05, 0.04))

## A print on a dress (estampado): little flowers (cream with an orange heart, and blue specks between them, as on the
## user's picture), polka dots or checks over the colour, a pattern laid on from all sides (as the trolley's tartan).
static var _prints := {}
func _print_on(mi: MeshInstance3D, hex: int) -> void:
	var kind: int = int(look.get("estampado", 0))
	if mi == null or kind <= 0:
		return
	var key := "%x_%d" % [hex, kind]
	if not _prints.has(key):
		var N := 48
		var img := Image.create(N, N, false, Image.FORMAT_RGB8)
		var b := Parts.col(hex)
		var light: bool = b.r * 0.3 + b.g * 0.59 + b.b * 0.11 > 0.6
		var cream := Color(0.95, 0.90, 0.76) if not light else Color(0.25, 0.3, 0.5)
		var heart := Color(0.93, 0.6, 0.25)
		var speck := Color(0.5, 0.6, 0.82) if not light else Color(0.85, 0.45, 0.5)
		img.fill(b)
		match kind:
			1:
				var spots := [Vector2i(6, 7), Vector2i(30, 4), Vector2i(18, 21), Vector2i(41, 25), Vector2i(7, 36), Vector2i(29, 40), Vector2i(44, 44)]
				for sp: Vector2i in spots:
					for dy in range(-3, 4):
						for dx in range(-3, 4):
							var rr2: int = dx * dx + dy * dy
							var ang: float = atan2(float(dy), float(dx))
							var petal: float = 2.2 + 0.9 * cos(5.0 * ang)
							if rr2 <= 1:
								img.set_pixel(posmod(sp.x + dx, N), posmod(sp.y + dy, N), heart)
							elif float(rr2) <= petal * petal:
								img.set_pixel(posmod(sp.x + dx, N), posmod(sp.y + dy, N), cream)
				for sp in [Vector2i(18, 6), Vector2i(42, 12), Vector2i(4, 21), Vector2i(31, 17), Vector2i(15, 33), Vector2i(40, 36), Vector2i(20, 46), Vector2i(4, 46)]:
					for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
						img.set_pixelv(Vector2i(posmod(sp.x + o.x, N), posmod(sp.y + o.y, N)), speck)
			2:
				for sp in [Vector2i(6, 6), Vector2i(30, 6), Vector2i(18, 18), Vector2i(42, 18), Vector2i(6, 30), Vector2i(30, 30), Vector2i(18, 42), Vector2i(42, 42)]:
					for dy in range(-3, 4):
						for dx in range(-3, 4):
							if dx * dx + dy * dy <= 9:
								img.set_pixel(posmod(sp.x + dx, N), posmod(sp.y + dy, N), cream)
			3:
				for py in range(N):
					for px in range(N):
						var c := b
						if px % 24 < 7 or py % 24 < 7:
							c = b.lerp(cream, 0.35)
						if px % 24 < 7 and py % 24 < 7:
							c = b.lerp(cream, 0.6)
						img.set_pixel(px, py, c)
		var m := StandardMaterial3D.new()
		m.albedo_texture = ImageTexture.create_from_image(img)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		m.uv1_triplanar = true
		m.uv1_scale = Vector3.ONE * (2.4 if kind == 1 else 2.0)
		m.uv1_triplanar_sharpness = 12.0                   # (no smears where the sides blend)
		m.vertex_color_use_as_albedo = true
		m.roughness = 1.0
		m.rim_enabled = true
		m.rim = 0.35
		m.rim_tint = 0.6
		_prints[key] = m
	mi.set_surface_override_material(0, _prints[key])

# ---------------- the toquilla and the mandil (the user, 25 Nov 2026, with pictures: "Para las ancianas habría que
# añadir de ropa posible una toquilla (negra para el cementerio, de colores fuera) y para todas las mujeres no niñas un
# posible mandil") ----------------
## look "toquilla": the colour of a crocheted shawl of open mesh over the shoulders, its two ends crossed and twisted on
## the chest (-1 or missing: none). look "mandil": the colour of a gingham pinafore apron, front and back, piped round,
## with a band of embroidered flowers under the bust and two pockets with flowers along their tops (-1: none). Both go
## over whatever top is worn, the shawl over the apron.
const TOQUILLA_CELL := 0.085                     # one tile of the shawl's mesh (two holes, staggered), metres
const GINGHAM_TILE := 0.07                       # two checks of the apron
func _layers(top_id: int) -> void:
	var pad: float = _top_pad(top_id) * _girth
	var mandil: int = int(look.get("mandil", -1))
	if mandil >= 0:
		_mandil(mandil, pad)
	var toq: int = int(look.get("toquilla", -1))
	if toq >= 0:
		_toquilla(toq, pad + (0.018 if mandil >= 0 else 0.0))

## A piece of cloth on a shell round the body. `at` maps (u, v), both 0..1, to Vector3(angle round the body (0 the
## front), height, lift off the body). Its uv: metres round the body, and metres up (or v itself, with `v_uv`, for a
## band with one row of pattern). The outermost `rim` of it (in u and v) has the vertex colour `edge`: piping. Cached
## by `key` (which must say everything the shape depends on: the build and the lift).
static var _shells := {}
func _shell(key: String, cols: int, rows: int, at: Callable, edge := Color(1, 1, 1), rim := 0.0, v_uv := false) -> ArrayMesh:
	if _shells.has(key):
		return _shells[key]
	var us: Array = []
	var vs: Array = []
	for pair in [[us, cols], [vs, rows]]:
		var out: Array = pair[0]
		var n: int = pair[1]
		if rim > 0.0:                            # (two lines close together at each edge: the piping ends sharp)
			out.append_array([0.0, rim])
			for k in range(n - 3):
				out.append(lerpf(rim + 0.004, 1.0 - rim - 0.004, float(k) / float(maxi(1, n - 4))))
			out.append_array([1.0 - rim, 1.0])
		else:
			for k in range(n + 1):
				out.append(float(k) / float(n))
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var colours := PackedColorArray()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var sl: float = _slope()
	for v in vs:
		for u in us:
			var q: Vector3 = at.call(float(u), float(v))
			var r: float = _r(q.y) + q.z
			verts.append(Vector3(sin(q.x) * r, q.y, cos(q.x) * r))
			norms.append(Vector3(sin(q.x) * cos(sl), sin(sl), cos(q.x) * cos(sl)))
			uvs.append(Vector2(q.x * r, (1.0 - float(v)) if v_uv else -q.y))
			var on_edge: bool = rim > 0.0 and (float(u) <= rim + 0.0001 or float(u) >= 1.0 - rim - 0.0001 or float(v) <= rim + 0.0001 or float(v) >= 1.0 - rim - 0.0001)
			colours.append(edge if on_edge else Color(1, 1, 1))
	var w: int = us.size()
	for a in range(vs.size() - 1):
		for b in range(w - 1):
			var i0: int = a * w + b
			var i1: int = i0 + w
			idx.append_array([i0, i0 + 1, i1, i0 + 1, i1 + 1, i1])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_COLOR] = colours
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_shells[key] = m
	return m

func _put_shell(m: ArrayMesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inner.add_child(mi)
	return mi

## a matt cloth material over a texture (drawn on both sides; vertex colours multiplied in, for the piping)
static func _cloth(tex: Texture2D, tint: Color, tile: Vector2, scissor := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = tint
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.uv1_scale = Vector3(1.0 / tile.x, 1.0 / tile.y, 1.0)
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 1.0
	m.rim_enabled = true
	m.rim = 0.35
	m.rim_tint = 0.6
	if scissor:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.5
	return m

## the shawl: from the neck over the shoulders and down to the elbows at the sides, lower behind than at the neck, the
## two ends coming down across the chest from the shoulders, crossing low in the middle and twisted into a knot there;
## an open mesh of round holes, staggered (the shirt shows through), thick yarn round them
static var _toq_tex: ImageTexture = null
static var _toq_mats := {}
func _toquilla(hex: int, pad: float) -> void:
	if _toq_tex == null:
		var N := 32
		var img := Image.create(N, N, true, Image.FORMAT_RGBA8)
		for py in range(N):
			for px in range(N):
				var p := Vector2((float(px) + 0.5) / N, (float(py) + 0.5) / N)
				var d: float = 9.0
				for c in [Vector2(0.25, 0.25), Vector2(0.75, 0.75), Vector2(-0.25, 0.75), Vector2(1.25, 0.25), Vector2(0.75, -0.25), Vector2(0.25, 1.25), Vector2(-0.25, -0.25), Vector2(1.25, 1.25)]:
					d = minf(d, p.distance_to(c))
				var hole: bool = d < 0.215
				var shade: float = clampf(0.62 + 2.2 * (d - 0.215), 0.62, 1.0)       # (darker into the holes: the yarn is round)
				var bump: float = 0.92 + 0.08 * sin(float(px + py) * 1.6)             # (the twist of the stitches)
				img.set_pixel(px, py, Color(shade * bump, shade * bump, shade * bump, 0.0 if hole else 1.0))
		img.generate_mipmaps()
		_toq_tex = ImageTexture.create_from_image(img)
	if not _toq_mats.has(hex):
		_toq_mats[hex] = _cloth(_toq_tex, Parts.col(hex), Vector2(TOQUILLA_CELL, TOQUILLA_CELL), true)
	var mat: Material = _toq_mats[hex]
	for side in [-1.0, 1.0]:
		var extra: float = pad + (0.008 if side < 0.0 else 0.0)
		var key := "toq_%d_%d_%d" % [int(round(_girth * 100.0)), int(round(extra * 1000.0)), int(side)]
		var at := func(u: float, v: float) -> Vector3:
			var ybot: float = lerpf(0.50, 0.71, smoothstep(0.0, 0.42, u)) if u < 0.42 else lerpf(0.71, 0.655, (u - 0.42) / 0.58)
			var y: float = lerpf(ybot, 1.0, v)
			var a0: float = -0.11 + 0.56 * clampf((y - 0.56) / 0.40, 0.0, 1.0)      # (the V open at the neck, crossed below)
			var ang: float = lerpf(a0, PI + 0.03, u)
			var drape: float = lerpf(0.02, 0.058, sin(clampf(ang, 0.0, PI)))      # (furthest out over the arms)
			return Vector3(side * ang, y, extra + 0.024 + (1.0 - v) * drape)
		_put_shell(_shell(key, 20, 12, at), mat)
	var knot_c: int = _mix(hex, 0x000000, 0.06)
	for k in range(3):                           # the knot where the ends are crossed and twisted
		var ky: float = 0.505 + 0.035 * k
		var kr: float = _r(ky) + pad + 0.06 - 0.008 * k
		var kb := _acc("ball", knot_c, Vector3((k - 1) * 0.03, ky, kr), Vector3(0.07 - 0.01 * k, 0.042, 0.04))
		kb.rotation.z = 0.5 * (1 - k)
		kb.material_override = _toq_knot(knot_c)

static var _knot_mats := {}
func _toq_knot(hex: int) -> Material:
	if not _knot_mats.has(hex):
		_knot_mats[hex] = _cloth(_toq_tex, Parts.col(hex), Vector2(TOQUILLA_CELL * 0.4, TOQUILLA_CELL * 0.4))
	return _knot_mats[hex]

## the apron: a panel in front from the knees to the bust, its straps over the shoulders, the arms out through its open
## sides, and one behind; gingham (white, the colour, and the half where the stripes cross), piped round in the colour,
## a band of flowers on dark blue under the bust and two pockets low in front, flowers along their tops
static var _ging := {}
static var _flores_tex: ImageTexture = null
func _mandil(hex: int, pad: float) -> void:
	if not _ging.has(hex):
		var N := 32
		var img := Image.create(N, N, true, Image.FORMAT_RGB8)
		var c := Parts.col(hex)
		var white := Color(0.97, 0.97, 0.95)
		for py in range(N):
			for px in range(N):
				var a: bool = (px % 16) < 8
				var b: bool = (py % 16) < 8
				img.set_pixel(px, py, c if (a and b) else (white.lerp(c, 0.5) if (a or b) else white))
		img.generate_mipmaps()
		_ging[hex] = _cloth(ImageTexture.create_from_image(img), Color(1, 1, 1), Vector2(GINGHAM_TILE, GINGHAM_TILE))
	if _flores_tex == null:
		var W := 64
		var H := 16
		var img2 := Image.create(W, H, true, Image.FORMAT_RGB8)
		img2.fill(Color(0.11, 0.15, 0.33))
		var petals := [Color(0.88, 0.22, 0.22), Color(0.95, 0.76, 0.19), Color(0.94, 0.5, 0.66), Color(0.35, 0.69, 0.91)]
		for f in range(4):
			var cx: int = 8 + f * 16
			for dy in range(-6, 7):
				for dx in range(-6, 7):
					var rr: float = sqrt(float(dx * dx + dy * dy))
					var ang: float = atan2(float(dy), float(dx))
					var px: int = posmod(cx + dx, W)
					var py: int = 8 + dy
					if py < 1 or py > H - 2:
						continue
					if rr < 1.6:
						img2.set_pixel(px, py, Color(0.98, 0.85, 0.3))
					elif rr < 3.2 + 1.6 * cos(5.0 * ang):
						img2.set_pixel(px, py, petals[f])
			for lx in [cx + 7, cx + 8]:                  # (green leaves between the flowers)
				for ly in [6, 7, 9, 10]:
					img2.set_pixel(posmod(lx, W), ly, Color(0.2, 0.6, 0.3))
		img2.generate_mipmaps()
		_flores_tex = ImageTexture.create_from_image(img2)
	var ging: Material = _ging[hex]
	var edge := Parts.col(hex)
	var g100: int = int(round(_girth * 100.0))
	var flare: float = 0.07 if int(look.get("top", 0)) in [22, REBECA_VESTIDO] else 0.0      # (a dress's skirt flares out: over it, not through it)
	var p1000: int = int(round(pad * 1000.0)) + int(round(flare * 100.0)) * 10000
	var out := func(y: float) -> float:
		return pad + flare * pow(clampf((0.64 - y) / 0.34, 0.0, 1.0), 1.6)
	var front := func(u: float, v: float) -> Vector3:
		var ang: float = lerpf(-1.15, 1.15, u)
		var a: float = absf(ang)
		var top: float = lerpf(0.80, 0.985, smoothstep(0.30, 0.44, a))      # (the bib, and up into the straps)
		top = lerpf(top, 0.72, smoothstep(0.74, 0.92, a))                     # (the arms out through the side)
		var y: float = lerpf(0.29, top, v)
		return Vector3(ang, y, out.call(y) + 0.014)
	var back := func(u: float, v: float) -> Vector3:
		var ang: float = lerpf(-0.95, 0.95, u)
		var a: float = absf(ang)
		var top: float = lerpf(0.87, 0.985, smoothstep(0.28, 0.40, a))
		top = lerpf(top, 0.72, smoothstep(0.66, 0.85, a))
		var y: float = lerpf(0.30, top, v)
		return Vector3(PI + ang, y, out.call(y) + 0.014)
	_put_shell(_shell("mf_%d_%d" % [g100, p1000], 28, 10, front, edge, 0.018), ging)
	_put_shell(_shell("mb_%d_%d" % [g100, p1000], 22, 10, back, edge, 0.02), ging)
	var flores: Material = _cloth(_flores_tex, Color(1, 1, 1), Vector2(0.24, 1.0)) if not _ging.has("flores") else _ging["flores"]
	_ging["flores"] = flores
	var band := func(u: float, v: float) -> Vector3:
		return Vector3(lerpf(-0.74, 0.74, u), lerpf(0.69, 0.745, v), pad + 0.02)
	_put_shell(_shell("mband_%d_%d" % [g100, p1000], 20, 1, band, Color(1, 1, 1), 0.0, true), flores)
	for sx in [-1.0, 1.0]:
		var pocket := func(u: float, v: float) -> Vector3:
			var y: float = lerpf(0.37, 0.52, v)
			return Vector3(sx * 0.5 + lerpf(-0.2, 0.2, u), y, out.call(y) + 0.021)
		_put_shell(_shell("mpk_%d_%d_%d" % [g100, p1000, int(sx)], 8, 6, pocket, edge, 0.05), ging)
		var ptop := func(u: float, v: float) -> Vector3:
			var y: float = lerpf(0.485, 0.52, v)
			return Vector3(sx * 0.5 + lerpf(-0.2, 0.2, u), y, out.call(y) + 0.027)
		_put_shell(_shell("mpt_%d_%d_%d" % [g100, p1000, int(sx)], 6, 1, ptop, Color(1, 1, 1), 0.0, true), flores)

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
const CORTITO := 17                             # buzz cut (1-2 mm) in the hair's own colour (replaces Pelusilla, which was a clone of Tazón; 22 Nov 2026)
const CUATRO_PELOS := 34                        # four stylized cartoon strands springing from a bare crown (22 Nov 2026)
static var _rasurado_mesh: ArrayMesh
static var _cortito_mesh: ArrayMesh
static var _cortito_mats := {}
static var _cuatro_mesh: ArrayMesh
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
		const FADE := 8.5
		_barba3_mesh = _shave_zone(func(b: float, e: float) -> float:
			var side: float = absf(b)                                   # 0 in front, PI/2 at the ears
			var top: float = lerpf(-11.0, -22.0, smoothstep(0.0, 0.72, side)) + 16.0 * smoothstep(0.82, 1.38, side)      # up to under the nose, below the blush, softening into sideburns
			var a_top: float = 1.0 - smoothstep(top - FADE, top, e)
			var a_side: float = 1.0 - smoothstep(1.36, 1.72, side)         # softer profile taper (not a hard vertical block)
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

## Buzz cut (1-2 mm) flush against the skull, in the hair's own colour (22 Nov 2026: "Cortito"): richer and more covered
## than Rasurao (which is a faint grey shave shadow), with a real hairline and subtle sideburns, and zero helmet bulk.
func _cortito(hex: int) -> void:
	if _cortito_mesh == null:
		const FADE := 5.0
		_cortito_mesh = _shave_zone(func(b: float, e: float) -> float:
			var side := absf(b)                                          # 0 front, PI/2 sides, PI back
			var base: float = lerpf(-18.0, 30.0, pow((1.0 + cos(b)) / 2.0, 1.5))
			# subtle sideburn dip around the temples (~65..95 deg)
			var burn := 14.0 * exp(-pow((side - 1.38) / 0.24, 2.0))
			var lowest := base - burn
			return smoothstep(lowest, lowest + FADE, e), -30.0, 90.0)
	if not _cortito_mats.has(hex):
		var m := _shave_mat.duplicate() as StandardMaterial3D
		m.albedo_color = Color(Parts.col(hex), 0.86)
		_cortito_mats[hex] = m
	var mi := MeshInstance3D.new()
	mi.mesh = _cortito_mesh
	mi.material_override = _cortito_mats[hex]
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	neck.add_child(mi)

## Four stylized low-poly hair strands arching out of an otherwise bare crown (22 Nov 2026: "Cuatro pelos").
## Built once as tapered curved tubes so the silhouette and screen-space outlines stay crisp from every angle.
static func _add_strand(st: SurfaceTool, pts: Array, r0: float, r1: float, sides := 6) -> void:
	var n := pts.size()
	var rings: Array = []
	for i in range(n):
		var p: Vector3 = pts[i]
		var tang: Vector3
		if i == 0:
			tang = (pts[1] - pts[0]).normalized()
		elif i == n - 1:
			tang = (pts[n - 1] - pts[n - 2]).normalized()
		else:
			tang = (pts[i + 1] - pts[i - 1]).normalized()
		var ref := Vector3.RIGHT if absf(tang.dot(Vector3.RIGHT)) < 0.85 else Vector3.FORWARD
		var u := tang.cross(ref).normalized()
		var v := tang.cross(u).normalized()
		var t := float(i) / float(n - 1)
		var rad := lerpf(r0, r1, t * t)
		var ring: Array = []
		for k in range(sides):
			var a := TAU * float(k) / float(sides)
			var dir := u * cos(a) + v * sin(a)
			ring.append([p + dir * rad, dir])
		rings.append(ring)
	for i in range(n - 1):
		var a: Array = rings[i]
		var b: Array = rings[i + 1]
		for k in range(sides):
			var kn := (k + 1) % sides
			for q in [a[k], b[k], b[kn], a[k], b[kn], a[kn]]:
				st.set_normal(q[1])
				st.add_vertex(q[0])
	# close tip
	var tip: Vector3 = pts[n - 1]
	var tn: Vector3 = ((pts[n - 1] as Vector3) - (pts[n - 2] as Vector3)).normalized()
	var last: Array = rings[n - 1]
	for k in range(sides):
		var kn := (k + 1) % sides
		st.set_normal(last[k][1]); st.add_vertex(last[k][0])
		st.set_normal(tn); st.add_vertex(tip + tn * r1 * 0.6)
		st.set_normal(last[kn][1]); st.add_vertex(last[kn][0])

func _cuatro_pelos(hex: int, cut: int) -> void:
	if cut > 0:                                      # hidden cleanly under any hat
		return
	if _cuatro_mesh == null:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		# 4 playful curved arcs springing from the top of the R=0.50 skull (centered at (0, 1.38, 0), face +z)
		_add_strand(st, [
			Vector3(-0.04, 1.855, 0.06), Vector3(-0.08, 1.955, 0.13),
			Vector3(-0.16, 1.985, 0.21), Vector3(-0.22, 1.935, 0.26), Vector3(-0.24, 1.875, 0.275)
		], 0.023, 0.008)
		_add_strand(st, [
			Vector3(0.01, 1.86, 0.01), Vector3(0.04, 1.99, 0.06),
			Vector3(0.11, 2.045, 0.13), Vector3(0.165, 2.01, 0.18), Vector3(0.185, 1.95, 0.195)
		], 0.025, 0.008)
		_add_strand(st, [
			Vector3(0.07, 1.855, -0.03), Vector3(0.145, 1.94, -0.01),
			Vector3(0.23, 1.96, 0.01), Vector3(0.285, 1.905, 0.02), Vector3(0.30, 1.845, 0.025)
		], 0.022, 0.007)
		_add_strand(st, [
			Vector3(-0.02, 1.85, -0.08), Vector3(-0.055, 1.955, -0.155),
			Vector3(-0.105, 1.985, -0.225), Vector3(-0.145, 1.93, -0.27), Vector3(-0.16, 1.87, -0.285)
		], 0.022, 0.007)
		_cuatro_mesh = st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = _cuatro_mesh
	mi.material_override = Parts.mat(hex)
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
	if cut >= 3:                            # under a headscarf: none of it shows
		return
	var hatted := cut > 0
	if style == CALVO:                      # nothing on top at all
		return
	if style == RASURADO:
		_rasurado(hair)
		return
	if style == CORTITO:
		_cortito(hair)
		return
	if style == CUATRO_PELOS:
		_cuatro_pelos(hair, cut)
		return
	if style == RULOS:
		_rulos(hair, cut)
		return
	if style == MATA:
		_mata(hair, cut)
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
		1:      # bun (bigger: the user, 17 Nov 2026); none under a kerchief or a cap, it is tucked under the cloth (it came
			if not hatted:                  # through Josefa's kerchief, even low on the nape: the user, 23 Nov 2026, "el moño le clippea el pañuelo")
				_add("ball", hair, Vector3(0, 1.76, -0.46), Vector3(0.27, 0.25, 0.27))
		2:      # long, down to the shoulders
			_add("ball", hair, Vector3(0, 1.22, -0.2), Vector3(0.5, 0.52, 0.36))
		4:      # afro (0.0.22: scaled closer to the head and centered so it no longer dwarfs the body)
			if hatted:
				for sx in [-1.0, 1.0]:
					_add("ball", hair, Vector3(sx * 0.42, 1.36, -0.14), Vector3(0.24, 0.26, 0.3))
				_add("ball", hair, Vector3(0, 1.34, -0.4), Vector3(0.44, 0.28, 0.26))
			else:
				_add("ball", hair, Vector3(0, 1.56, -0.08), Vector3(0.6, 0.54, 0.56))
				_add("ball", hair, Vector3(0, 1.77, 0.12), Vector3(0.38, 0.18, 0.26))
		5:      # ponytail
			_add("ball", hair, Vector3(0, 1.62, -0.5), Vector3.ONE * 0.1)
			_add("ball", hair, Vector3(0, 1.32, -0.6), Vector3(0.12, 0.32, 0.12))
		6:      # mohawk: spikes, each pointing out from the head (pointed, not round: the user, 17 Nov 2026)
			if not hatted:
				for k in range(6):
					var a := -0.75 + k * 0.42
					var spike := _add("cone", hair, Vector3(0, 1.4 + cos(a) * 0.62, -sin(a) * 0.62), Vector3(0.06, 0.34, 0.14))
					spike.rotation.x = -a
		7:      # pigtails (0.0.22: seated closer against the temples with ties sitting cleanly on the join)
			for sx in [-1.0, 1.0]:
				var pig := _add("ball", hair, Vector3(sx * 0.47, 1.35, -0.1), Vector3(0.14, 0.24, 0.15))
				pig.rotation.z = sx * 0.18
				_acc("ball", 0xd23b3b, Vector3(sx * 0.45, 1.54, -0.1), Vector3.ONE * 0.055)
		9:      # bob
			_add("ball", hair, Vector3(0, 1.33, -0.12), Vector3(0.54, 0.4, 0.44))
		11:     # curls (0.0.22: tighter, overlapping puffs seated closer to the skull for a cohesive silhouette)
			for i in range(13):
				var phi := i * 2.39996 + 0.45
				var el := 0.22 + (i % 4) * 0.28
				var at := Vector3(cos(el) * sin(phi), sin(el), cos(el) * cos(phi)) * 0.44
				if (at.z > 0.2 and at.y < 0.32) or (hatted and at.y > 0.14):
					continue                         # not over the face, not through the hat
				_add("ball", hair, Vector3(0, 1.42, -0.04) + at, Vector3.ONE * 0.165)
		12:     # a plait down the back (0.0.22: slightly tighter bead overlap for a continuous braid silhouette)
			for k in range(4):
				_add("ball", hair, Vector3(0, 1.34 - k * 0.165, -0.49 + k * k * 0.004), Vector3.ONE * (0.135 - k * 0.01))
			_acc("ball", 0xd23b3b, Vector3(0, 0.74, -0.46), Vector3.ONE * 0.05)

static var _happy_eye_mesh: ArrayMesh
static var _blink_mesh: ArrayMesh
static var _sliced_eye_cache := {}
const _EYE_PIVOT_Y := 1.416

## Cached D-shaped ellipsoid sliced cleanly along `ny <= cut_y + slope * nx`, eliminating any skin-box masking
## artifact under screen-space ink outlines while keeping the signature forward-facing 3D relief.
static func _sliced_ellipsoid(rx: float, ry: float, rz: float, cut_y: float, slope: float) -> ArrayMesh:
	var key := "%d_%d_%d_%d_%d" % [int(round(rx * 1000.0)), int(round(ry * 1000.0)), int(round(rz * 1000.0)), int(round(cut_y * 1000.0)), int(round(slope * 1000.0))]
	if _sliced_eye_cache.has(key):
		return _sliced_eye_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const RINGS := 10
	const SEGS := 20
	var grid: Array = []
	for r in range(RINGS + 1):
		var phi: float = -PI * 0.5 + PI * float(r) / float(RINGS)
		var row: Array = []
		for s in range(SEGS + 1):
			var th: float = TAU * float(s) / float(SEGS)
			var nx: float = cos(phi) * cos(th)
			var ny: float = sin(phi)
			var nz: float = cos(phi) * sin(th)
			var lim: float = cut_y + slope * nx
			var cy: float = minf(ny, lim)
			var p := Vector3(nx * rx, cy * ry, nz * rz)
			var nrm := Vector3(nx / maxf(rx, 0.001), (1.0 if ny > lim else ny) / maxf(ry, 0.001), nz / maxf(rz, 0.001)).normalized()
			row.append([p, nrm])
		grid.append(row)
	for r in range(RINGS):
		for s in range(SEGS):
			var a: Array = grid[r][s]
			var b: Array = grid[r][s + 1]
			var c: Array = grid[r + 1][s + 1]
			var d: Array = grid[r + 1][s]
			for v in [a, b, c, a, c, d]:
				st.set_normal(v[1]); st.add_vertex(v[0])
	var mesh := st.commit()
	_sliced_eye_cache[key] = mesh
	return mesh

func _eacc(kind: String, hex: int, pos: Vector3, scl: Vector3) -> MeshInstance3D:
	var m := Parts.part(kind, hex, pos - Vector3(0.0, _EYE_PIVOT_Y, 0.0), scl)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_eyes_open.add_child(m)
	return m

func _eye_part(mesh: ArrayMesh, hex: int, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = Parts.mat(hex)
	mi.position = pos - Vector3(0.0, _EYE_PIVOT_Y, 0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_eyes_open.add_child(mi)
	return mi

## Eyes (0 normal · 1 big · 2 siesta · 3 almond · 4 button · 5 happy · 6 droopy · 7 sparkly · 8 sly)
## and eyelashes (0 none · 1 fine · 2 doll's · 3 winged liner). Keeps the signature forward-facing toy relief,
## wires organic blinking (_eyes_open / _eyes_closed), and returns the effective eye half-height for eyebrows.
func _eyes(kind: int, eye_c: int, lashes: int, skin: int) -> float:
	_eyes_open = null
	_eyes_closed = null
	_blink_t = -1.0
	if kind == 5:                                # joyful closed smiling arches (^ ^): already closed, never blinks
		if _happy_eye_mesh == null:
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for sx in [-1.0, 1.0]:
				var pts: Array = []
				var rx: Array = []
				var ry: Array = []
				for i in range(9):
					var t: float = -1.0 + 2.0 * float(i) / 8.0
					var b: float = sx * (0.34 + t * 0.165)
					var e_deg: float = 2.5 + 7.5 * (1.0 - t * t)
					pts.append(_head_pt(b, e_deg, 0.510))
					var tap: float = 1.0 - 0.25 * t * t
					rx.append(0.021 * tap)
					ry.append(0.020 * tap)
				_add_face_tube(st, pts, rx, ry, false, 8)
			_happy_eye_mesh = st.commit()
		_beard_mesh_on(_happy_eye_mesh, 0x17110d)
		if lashes > 0:
			for sx in [-1.0, 1.0]:
				_add_lashes(sx, sx * 0.17, 1.405, 0.082, 0.032, lashes, 0.0, false)
		return 0.084

	_eyes_open = Node3D.new()
	_eyes_open.position = Vector3(0.0, _EYE_PIVOT_Y, 0.0)
	neck.add_child(_eyes_open)

	_eyes_closed = Node3D.new()
	_eyes_closed.visible = false
	neck.add_child(_eyes_closed)
	if _blink_mesh == null:                      # relaxed curved closed eyelids for natural mid-blink frames
		var bst := SurfaceTool.new()
		bst.begin(Mesh.PRIMITIVE_TRIANGLES)
		for sx in [-1.0, 1.0]:
			var bpts: Array = []
			var brx: Array = []
			var bry: Array = []
			for i in range(9):
				var t: float = -1.0 + 2.0 * float(i) / 8.0
				var b: float = sx * (0.34 + t * 0.17)
				var e_deg: float = 4.6 - 2.6 * (1.0 - t * t)
				bpts.append(_head_pt(b, e_deg, 0.512))
				var tap: float = 1.0 - 0.22 * t * t
				brx.append(0.019 * tap)
				bry.append(0.018 * tap)
			_add_face_tube(bst, bpts, brx, bry, false, 8)
		_blink_mesh = bst.commit()
	var bmi := MeshInstance3D.new()
	bmi.mesh = _blink_mesh
	bmi.material_override = Parts.mat(0x17110d)
	bmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_eyes_closed.add_child(bmi)

	var ew := 0.080
	var eh := 0.098
	var brow_eh := 0.098
	var ey := 1.420
	var eye_tilt := 0.0
	var gaze_x := 0.0
	match kind:
		1:                                       # Ojazos (big adorable eyes)
			ew = 0.100; eh = 0.125; brow_eh = 0.125
		2:                                       # De siesta (clean D-shaped half-closed relaxed eye, zero skin box)
			ew = 0.086; eh = 0.086; brow_eh = 0.072; ey = 1.414
		3:                                       # Rasgaos (sleek tilted almond eye)
			ew = 0.094; eh = 0.062; brow_eh = 0.082; ey = 1.422; eye_tilt = 0.25
		4:                                       # De botón (classic plush/AC glossy dark button eyes)
			ew = 0.068; eh = 0.074; brow_eh = 0.086; ey = 1.418
		6:                                       # Cansaos (clean droopy outer-sloping D-shaped eye + subtle shadow)
			ew = 0.084; eh = 0.088; brow_eh = 0.076; ey = 1.414
		7:                                       # Brillantes (sparkly expressive anime eyes)
			ew = 0.098; eh = 0.120; brow_eh = 0.120; ey = 1.420
		8:                                       # De listo (clean flat-top D-shaped eye + sly side-eye)
			ew = 0.088; eh = 0.086; brow_eh = 0.078; ey = 1.416; gaze_x = 0.024

	for sx in [-1.0, 1.0]:
		var ex: float = sx * 0.17
		var tilt: float = sx * eye_tilt
		if kind == 4:                            # glossy dark button eye with subtle colour rim & dual highlights
			_eacc("ball", 0x17110d, Vector3(ex, ey, 0.464), Vector3(ew, eh, 0.044))
			_eacc("ball", eye_c, Vector3(ex, ey - 0.002, 0.482), Vector3(ew * 0.74, eh * 0.74, 0.030))
			_eacc("ball", 0x0c0908, Vector3(ex, ey - 0.002, 0.494), Vector3(ew * 0.50, eh * 0.50, 0.022))
			_eacc("ball", 0xffffff, Vector3(ex + 0.020, ey + 0.022, 0.504), Vector3.ONE * 0.020)
			_eacc("ball", 0xffffff, Vector3(ex - 0.017, ey - 0.019, 0.503), Vector3.ONE * 0.009)
		elif kind in [2, 6, 8]:                  # D-shaped sliced eyelids (no protruding skin box!)
			var cut_y: float = 0.12 if kind == 2 else (0.16 if kind == 6 else 0.24)
			var slope: float = -float(sx) * 0.34 if kind == 6 else 0.0
			_eye_part(_sliced_ellipsoid(ew + 0.017, eh + 0.017, 0.040, cut_y + 0.10, slope), 0x17110d, Vector3(ex, ey, 0.446))
			_eye_part(_sliced_ellipsoid(ew, eh, 0.045, cut_y, slope), 0xffffff, Vector3(ex, ey, 0.456))
			var ir_x: float = ew * 0.64
			var ir_y: float = eh * 0.64
			var iy: float = ey - 0.014
			var ix: float = ex + gaze_x
			var ir_cut: float = (ey + cut_y * eh - iy) / ir_y
			_eye_part(_sliced_ellipsoid(ir_x, ir_y, 0.030, ir_cut, slope), eye_c, Vector3(ix, iy, 0.478))
			_eye_part(_sliced_ellipsoid(ir_x * 0.52, ir_y * 0.52, 0.020, ir_cut / 0.52, slope), 0x0c0908, Vector3(ix, iy, 0.492))
			var gy: float = minf(iy + ir_y * 0.32, ey + cut_y * eh - 0.016)
			_eacc("ball", 0xffffff, Vector3(ix + 0.018, gy, 0.502), Vector3.ONE * 0.013)
			# Crisp dark upper lid crease right along the sliced top edge
			var bar := _eacc("box", 0x17110d, Vector3(ex, ey + (cut_y + 0.04) * eh, 0.492), Vector3(ew * 2.15, 0.020, 0.022))
			bar.rotation.z = atan(slope * eh / ew)
			if kind == 6:                        # subtle soft under-eye shadow stays fixed on cheek during blinks
				var bag := _acc("ball", _mix(skin, 0x8a5c4a, 0.24), Vector3(ex, ey - eh - 0.016, 0.456), Vector3(ew * 0.78, 0.014, 0.012))
				bag.rotation.z = -sx * 0.10
		else:
			var out_m := _eacc("ball", 0x17110d, Vector3(ex, ey, 0.446), Vector3(ew + 0.017, eh + 0.017, 0.040))
			var wh_m := _eacc("ball", 0xffffff, Vector3(ex, ey, 0.456), Vector3(ew, eh, 0.045))
			if tilt != 0.0:
				out_m.rotation.z = tilt
				wh_m.rotation.z = tilt
			var ir_x: float = ew * (0.72 if kind == 7 else 0.68)
			var ir_y: float = minf(eh * (0.72 if kind == 7 else 0.68), ir_x * 1.12)
			var iy: float = ey - 0.005
			var ix: float = ex + gaze_x
			_eacc("ball", eye_c, Vector3(ix, iy, 0.478), Vector3(ir_x, ir_y, 0.030))
			if kind == 7:                        # bright anime lower-iris sheen crescent
				_eacc("ball", _mix(eye_c, 0xffffff, 0.48), Vector3(ix, iy - ir_y * 0.34, 0.488), Vector3(ir_x * 0.68, ir_y * 0.36, 0.020))
			_eacc("ball", 0x0c0908, Vector3(ix, iy, 0.492), Vector3(ir_x * 0.52, ir_y * 0.52, 0.020))
			if kind == 7:                        # triple sparkly highlights
				_eacc("ball", 0xffffff, Vector3(ix + 0.024, iy + ir_y * 0.42, 0.503), Vector3(0.023, 0.026, 0.014))
				_eacc("ball", 0xffffff, Vector3(ix - 0.022, iy - ir_y * 0.36, 0.502), Vector3.ONE * 0.013)
				_eacc("ball", 0xffffff, Vector3(ix - 0.016, iy + ir_y * 0.48, 0.502), Vector3.ONE * 0.009)
			else:                                # lively double catchlight
				var g_sz: float = 0.018 if kind == 1 else 0.014
				_eacc("ball", 0xffffff, Vector3(ix + 0.020, iy + ir_y * 0.38, 0.502), Vector3.ONE * g_sz)
				_eacc("ball", 0xffffff, Vector3(ix - 0.016, iy - ir_y * 0.34, 0.501), Vector3.ONE * (g_sz * 0.48))
		if lashes > 0:
			var lash_y := ey + (0.014 if kind == 2 else (0.016 if kind == 6 else (0.024 if kind == 8 else 0.0)))
			var lash_eh := 0.012 if kind in [2, 6, 8] else eh
			_add_lashes(sx, ex, lash_y, ew, lash_eh, lashes, tilt, true)
	return brow_eh

## Eyelashes fanning gracefully along the outer upper corner of the eye (never poking up into the eyebrows).
## 1 fine · 2 doll's (lush fan) · 3 winged cat-eye eyeliner
func _add_lashes(sx: float, ex: float, ey: float, ew: float, eh: float, lashes: int, tilt: float, on_open := true) -> void:
	var put := func(pos: Vector3, scl: Vector3) -> MeshInstance3D:
		return _eacc("box", 0x17110d, pos, scl) if on_open else _acc("box", 0x17110d, pos, scl)
	if lashes == 3:                              # sleek winged cat-eye eyeliner flick at the outer corner
		var wx: float = ex + sx * (ew + 0.024)
		var wy: float = ey + eh * 0.28 + (0.012 if tilt != 0.0 else 0.0)
		var w1: MeshInstance3D = put.call(Vector3(wx, wy, 0.472), Vector3(0.058, 0.022, 0.016))
		w1.rotation.z = sx * 0.34
		var w2: MeshInstance3D = put.call(Vector3(wx + sx * 0.020, wy + 0.012, 0.470), Vector3(0.036, 0.013, 0.014))
		w2.rotation.z = sx * 0.52
		return
	var degs: Array = [42.0, 20.0, -2.0] if lashes == 1 else [54.0, 34.0, 14.0, -6.0]
	var l_len: float = 0.034 if lashes == 1 else 0.048
	var l_w: float = 0.010 if lashes == 1 else 0.014
	for d in degs:
		var ang: float = deg_to_rad(float(d)) + tilt * 0.5
		var bx: float = ex + sx * (cos(ang) * (ew + 0.010))
		var by: float = ey + sin(ang) * (eh + 0.010)
		var dx: float = sx * cos(ang) * (l_len * 0.48)
		var dy: float = sin(ang) * (l_len * 0.48)
		var stroke: MeshInstance3D = put.call(Vector3(bx + dx, by + dy, 0.468), Vector3(l_len, l_w, 0.012))
		stroke.rotation.z = sx * ang

## Organic, non-periodic human blink interval: skewed distribution (mostly 1.7–4.6 s, occasional long gazes up to
## 8.2 s or quick blinks down to 0.65 s). Double-blinks are handled separately inside _blink_tick().
static func _next_blink_gap() -> float:
	var r := randf()
	if r < 0.08:
		return randf_range(0.65, 1.55)
	if r < 0.78:
		return randf_range(1.70, 4.60)
	return randf_range(4.60, 8.20)

## Sets blink closure directly (0.0 open .. 1.0 fully closed). Used by _blink_tick() and visual tests.
func set_blink(amount: float) -> void:
	if _eyes_open == null or _eyes_closed == null:
		return
	if amount <= 0.0:
		if not _eyes_open.visible:
			_eyes_open.visible = true
		if _eyes_open.scale.y != 1.0:
			_eyes_open.scale.y = 1.0
		if _eyes_closed.visible:
			_eyes_closed.visible = false
	elif amount >= 0.72:
		if _eyes_open.visible:
			_eyes_open.visible = false
		if not _eyes_closed.visible:
			_eyes_closed.visible = true
	else:
		if not _eyes_open.visible:
			_eyes_open.visible = true
		_eyes_open.scale.y = lerpf(1.0, 0.14, amount / 0.72)
		if _eyes_closed.visible:
			_eyes_closed.visible = false

## Advances natural asynchronous blinking: asymmetric close/hold/open curve, variable speed, and ~18 % double-blinks.
func _blink_tick(dt: float) -> void:
	if _eyes_open == null or _eyes_closed == null or dt <= 0.0:
		return
	if _blink_wait < 0.0:                        # desynchronise every character on spawn
		_blink_wait = randf_range(0.35, 5.20)
	if _blink_t < 0.0:
		_blink_wait -= dt
		if _blink_wait <= 0.0:
			_blink_t = 0.0
			_blink_dur = randf_range(0.12, 0.16) if _blink_double else randf_range(0.14, 0.21)
		return
	_blink_t += dt
	var u := _blink_t / _blink_dur
	if u >= 1.0:
		_blink_t = -1.0
		set_blink(0.0)
		if not _blink_double and randf() < 0.18: # natural occasional double-blink (~18 %)
			_blink_double = true
			_blink_wait = randf_range(0.14, 0.28)
		else:
			_blink_double = false
			_blink_wait = _next_blink_gap()
		return
	var k := (u / 0.30) if u < 0.30 else (1.0 if u < 0.64 else (1.0 - u) / 0.36)
	set_blink(clampf(k, 0.0, 1.0))

# ---------------- eyebrows ----------------
## Curved sphere-hugging eyebrows (0.0.22): built once in head-centred space (origin at (0, 1.38, 0)) so pitching
## around X by `-(eh - 0.098) * 2.0` moves them cleanly along the forehead for all three eye sizes without clipping.
static var _brow_meshes := {}

static func _brow_pt(b: float, e_deg: float, rad := 0.503) -> Vector3:
	var e := deg_to_rad(e_deg)
	return Vector3(sin(b) * cos(e), sin(e), cos(b) * cos(e)) * rad

static func _add_brow_tube(st: SurfaceTool, pts: Array, rx: Array, ry: Array, sides := 8) -> void:
	var n := pts.size()
	var rings: Array = []
	for i in range(n):
		var p: Vector3 = pts[i]
		var prev_p: Vector3 = pts[maxi(i - 1, 0)]
		var next_p: Vector3 = pts[mini(i + 1, n - 1)]
		var tang: Vector3 = (next_p - prev_p).normalized()
		var out_n: Vector3 = p.normalized()
		var side_v: Vector3 = tang.cross(out_n).normalized()
		var rad_v: Vector3 = side_v.cross(tang).normalized()
		var u: Vector3 = rad_v
		var v: Vector3 = side_v
		if u.cross(v).dot(tang) < 0.0:
			v = -v
		var ring: Array = []
		for k in range(sides):
			var a := TAU * float(k) / float(sides)
			var du := cos(a)
			var dv := sin(a)
			var off: Vector3 = u * (du * float(ry[i])) + v * (dv * float(rx[i]))
			var nrm: Vector3 = (u * (du / maxf(float(ry[i]), 0.001)) + v * (dv / maxf(float(rx[i]), 0.001))).normalized()
			ring.append([p + off, nrm])
		rings.append(ring)
	for i in range(n - 1):
		var a: Array = rings[i]
		var b: Array = rings[i + 1]
		for k in range(sides):
			var kn := (k + 1) % sides
			for q in [a[k], b[k], b[kn], a[k], b[kn], a[kn]]:
				st.set_normal(q[1])
				st.add_vertex(q[0])
	var p0: Vector3 = pts[0]
	var t0: Vector3 = ((pts[0] as Vector3) - (pts[1] as Vector3)).normalized()
	var r0: Array = rings[0]
	for k in range(sides):
		var kn := (k + 1) % sides
		st.set_normal(r0[kn][1]); st.add_vertex(r0[kn][0])
		st.set_normal(t0); st.add_vertex(p0 + t0 * float(rx[0]) * 0.45)
		st.set_normal(r0[k][1]); st.add_vertex(r0[k][0])
	var pe: Vector3 = pts[n - 1]
	var te: Vector3 = ((pts[n - 1] as Vector3) - (pts[n - 2] as Vector3)).normalized()
	var re: Array = rings[n - 1]
	for k in range(sides):
		var kn := (k + 1) % sides
		st.set_normal(re[k][1]); st.add_vertex(re[k][0])
		st.set_normal(te); st.add_vertex(pe + te * float(rx[n - 1]) * 0.45)
		st.set_normal(re[kn][1]); st.add_vertex(re[kn][0])

static func _make_brow_mesh(kind: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	if kind == 2:       # unibrow: single curved sweep across the forehead
		var pts: Array = []
		var rx: Array = []
		var ry: Array = []
		for i in range(13):
			var t := -1.0 + 2.0 * float(i) / 12.0
			var b := t * 0.50
			var e := 22.5 + 1.2 * sin(absf(t) * PI) - 1.5 * exp(-t * t * 14.0)
			pts.append(_brow_pt(b, e, 0.503))
			rx.append(0.028 * (1.0 - 0.16 * t * t))
			ry.append(0.015)
		_add_brow_tube(st, pts, rx, ry, 8)
		return st.commit()
	# paired left/right brows: specs = [[b_abs, elev_deg, half_height, half_depth], ...]
	var specs: Array = []
	match kind:
		0:      # thin, friendly curved brows
			specs = [[0.18, 22.8, 0.015, 0.011], [0.27, 23.3, 0.016, 0.011], [0.36, 22.6, 0.015, 0.011], [0.45, 21.2, 0.013, 0.010], [0.52, 19.6, 0.011, 0.009]]
		1:      # thick classic Animal Crossing brows
			specs = [[0.17, 23.4, 0.031, 0.015], [0.26, 23.6, 0.032, 0.015], [0.35, 23.0, 0.031, 0.015], [0.44, 22.0, 0.029, 0.014], [0.51, 20.8, 0.025, 0.013]]
		6:      # angry: bold diagonal slant down toward the bridge
			specs = [[0.14, 17.5, 0.028, 0.015], [0.24, 20.2, 0.027, 0.015], [0.34, 23.0, 0.025, 0.014], [0.44, 25.4, 0.022, 0.013], [0.52, 27.2, 0.018, 0.012]]
		7:      # worried / puppy-dog: raised in the middle, drooping toward the temples
			specs = [[0.17, 26.8, 0.020, 0.013], [0.26, 25.4, 0.021, 0.013], [0.35, 23.2, 0.019, 0.012], [0.44, 20.4, 0.017, 0.011], [0.52, 17.8, 0.014, 0.010]]
		8:      # grandpa: extra-bushy, slightly shaggy overhanging caterpillar brows
			specs = [[0.13, 22.6, 0.042, 0.022], [0.23, 24.0, 0.046, 0.024], [0.34, 23.8, 0.045, 0.024], [0.45, 22.6, 0.042, 0.023], [0.55, 20.6, 0.035, 0.020]]
	for sx in [-1.0, 1.0]:
		var pts: Array = []
		var rx: Array = []
		var ry: Array = []
		for s in specs:
			pts.append(_brow_pt(sx * float(s[0]), float(s[1]), 0.504))
			rx.append(float(s[2]))
			ry.append(float(s[3]))
		_add_brow_tube(st, pts, rx, ry, 8)
	return st.commit()

func _brows(kind: int, hair_c: int, eh: float) -> void:
	if kind == 3:                                    # none
		return
	if kind >= FIRST_CEJAS and kind - FIRST_CEJAS < CEJAS.size():      # (Quaternius fitted models: 4 Espesas, 5 Arqueás)
		_pieza_on(CEJAS[kind - FIRST_CEJAS], hair_c, 0, eh - 0.098)
		return
	if not _brow_meshes.has(kind):
		_brow_meshes[kind] = _make_brow_mesh(kind)
	var mi := MeshInstance3D.new()
	mi.mesh = _brow_meshes[kind]
	mi.material_override = Parts.mat(hair_c)
	mi.position = Vector3(0.0, 1.38, 0.0)
	mi.rotation.x = -(eh - 0.098) * 2.0              # glides cleanly up/down along the sphere for Ojazos / De siesta
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	neck.add_child(mi)

# ---------------- beards ----------------
static var _bigote_mesh: ArrayMesh
static var _mostacho_mesh: ArrayMesh
static var _patillas_mesh: ArrayMesh
static var _candao_mesh: ArrayMesh

## A point on the head sphere (centred at (0, 1.38, 0), face +z) at bearing `b` (rad, 0 front) and elevation `e_deg` (deg).
static func _head_pt(b: float, e_deg: float, rad := 0.506) -> Vector3:
	var e := deg_to_rad(e_deg)
	return Vector3(0.0, 1.38, 0.0) + Vector3(sin(b) * cos(e), sin(e), cos(b) * cos(e)) * rad

## Builds a closed curved tube (oval cross-section: `rx` across the head, `ry` radially off the sphere) along `pts`.
static func _add_face_tube(st: SurfaceTool, pts: Array, rx: Array, ry: Array, closed := false, sides := 8) -> void:
	var n := pts.size()
	var rings: Array = []
	for i in range(n):
		var p: Vector3 = pts[i]
		var prev_p: Vector3 = pts[(i - 1 + n) % n] if closed else pts[maxi(i - 1, 0)]
		var next_p: Vector3 = pts[(i + 1) % n] if closed else pts[mini(i + 1, n - 1)]
		var tang: Vector3 = (next_p - prev_p).normalized()
		var out_n: Vector3 = (p - Vector3(0.0, 1.38, 0.0)).normalized()
		var side_v: Vector3 = tang.cross(out_n).normalized()
		var rad_v: Vector3 = side_v.cross(tang).normalized()       # radial outward, orthogonal to tang and side_v
		# ensure right-handed frame (u x v == tang) for outward CW winding
		var u: Vector3 = rad_v
		var v: Vector3 = side_v
		if u.cross(v).dot(tang) < 0.0:
			v = -v
		var ring: Array = []
		for k in range(sides):
			var a := TAU * float(k) / float(sides)
			var dir_u := cos(a)
			var dir_v := sin(a)
			var off: Vector3 = u * (dir_u * float(ry[i])) + v * (dir_v * float(rx[i]))
			var nrm: Vector3 = (u * (dir_u / maxf(float(ry[i]), 0.001)) + v * (dir_v / maxf(float(rx[i]), 0.001))).normalized()
			ring.append([p + off, nrm])
		rings.append(ring)
	var segs := n if closed else n - 1
	for i in range(segs):
		var a: Array = rings[i]
		var b: Array = rings[(i + 1) % n]
		for k in range(sides):
			var kn := (k + 1) % sides
			for q in [a[k], b[k], b[kn], a[k], b[kn], a[kn]]:
				st.set_normal(q[1])
				st.add_vertex(q[0])
	if not closed:
		# cap start
		var p0: Vector3 = pts[0]
		var t0: Vector3 = ((pts[0] as Vector3) - (pts[1] as Vector3)).normalized()
		var r0: Array = rings[0]
		for k in range(sides):
			var kn := (k + 1) % sides
			st.set_normal(r0[kn][1]); st.add_vertex(r0[kn][0])
			st.set_normal(t0); st.add_vertex(p0 + t0 * float(rx[0]) * 0.45)
			st.set_normal(r0[k][1]); st.add_vertex(r0[k][0])
		# cap end
		var pe: Vector3 = pts[n - 1]
		var te: Vector3 = ((pts[n - 1] as Vector3) - (pts[n - 2] as Vector3)).normalized()
		var re: Array = rings[n - 1]
		for k in range(sides):
			var kn := (k + 1) % sides
			st.set_normal(re[k][1]); st.add_vertex(re[k][0])
			st.set_normal(te); st.add_vertex(pe + te * float(rx[n - 1]) * 0.45)
			st.set_normal(re[kn][1]); st.add_vertex(re[kn][0])

func _beard_mesh_on(mesh: ArrayMesh, hair_c: int) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = Parts.mat(hair_c)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	neck.add_child(mi)

func _beard(kind: int, hair_c: int, skin: int) -> void:
	if kind >= FIRST_BARBA:
		if kind - FIRST_BARBA < BARBAS.size():
			_pieza_on(BARBAS[kind - FIRST_BARBA], hair_c)
		return
	match kind:
		1:      # moustache (0.0.22: curved to hug the sphere instead of a flat floating box)
			if _bigote_mesh == null:
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				var pts: Array = []
				var rx: Array = []
				var ry: Array = []
				for i in range(9):
					var t := -1.0 + 2.0 * float(i) / 8.0
					pts.append(_head_pt(t * 0.27, -14.0 - 1.5 * t * t, 0.506))
					var taper := 1.0 - 0.18 * t * t
					rx.append(0.029 * taper)
					ry.append(0.022 * taper)
				_add_face_tube(st, pts, rx, ry, false, 8)
				_bigote_mesh = st.commit()
			_beard_mesh_on(_bigote_mesh, hair_c)
		2:      # beard (0.0.22: tucked closer to the jaw with soft cheek wrap so it no longer sticks out like a muzzle)
			_add("ball", hair_c, Vector3(0, 1.15, 0.245), Vector3(0.365, 0.25, 0.27))
			for sx in [-1.0, 1.0]:
				_add("ball", hair_c, Vector3(sx * 0.285, 1.21, 0.21), Vector3(0.145, 0.145, 0.165))
		3:      # goatee (0.0.22: seated flush along the chin tangent)
			var g := _acc("ball", hair_c, Vector3(0, 1.09, 0.378), Vector3(0.11, 0.125, 0.08))
			g.rotation.x = 0.35
		4:      # the big moustache, ends drooping (0.0.22: curved handlebar hugging the cheeks cleanly in 3/4 and profile)
			if _mostacho_mesh == null:
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				var specs := [[-0.39, -31.0, 0.032], [-0.36, -22.0, 0.038], [-0.28, -14.5, 0.041], [-0.14, -13.0, 0.042],
					[0.0, -12.5, 0.042], [0.14, -13.0, 0.042], [0.28, -14.5, 0.041], [0.36, -22.0, 0.038], [0.39, -31.0, 0.032]]
				var pts: Array = []
				var rx: Array = []
				var ry: Array = []
				for s in specs:
					pts.append(_head_pt(float(s[0]), float(s[1]), 0.506))
					rx.append(float(s[2]))
					ry.append(float(s[2]) * 0.65)
				_add_face_tube(st, pts, rx, ry, false, 8)
				_mostacho_mesh = st.commit()
			_beard_mesh_on(_mostacho_mesh, hair_c)
		5:      # three days without shaving: the shaved head's see-through grey, over where a beard grows (the user, 16 Nov 2026:
			# "Cambia la barba de tres días ... por el mismo efecto que rasurado, pero en la zona de la barba"; it was dots)
			_barba3(hair_c)
		6:      # the long beard (0.0.22: tucked base + blended lower mass without snowman pinch)
			_add("ball", hair_c, Vector3(0, 1.155, 0.25), Vector3(0.37, 0.25, 0.27))
			for sx in [-1.0, 1.0]:
				_add("ball", hair_c, Vector3(sx * 0.285, 1.21, 0.21), Vector3(0.145, 0.145, 0.165))
			var low := _add("ball", hair_c, Vector3(0, 0.99, 0.315), Vector3(0.285, 0.295, 0.185))
			low.rotation.x = 0.12
		7:      # sideburns (0.0.22: curved low-poly strips hugging the temples/cheeks, replacing floating flat boxes)
			if _patillas_mesh == null:
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				for sx in [-1.0, 1.0]:
					var pts: Array = []
					var rx: Array = []
					var ry: Array = []
					var rows := [[10.0, 1.30, 0.055], [2.0, 1.28, 0.062], [-7.0, 1.25, 0.068], [-16.0, 1.21, 0.072], [-24.0, 1.16, 0.064]]
					for r in rows:
						pts.append(_head_pt(sx * float(r[1]), float(r[0]), 0.502))
						rx.append(float(r[2]))
						ry.append(0.017)
					_add_face_tube(st, pts, rx, ry, false, 8)
				_patillas_mesh = st.commit()
			_beard_mesh_on(_patillas_mesh, hair_c)
		8:      # moustache and goatee, joined up (0.0.22: curved horseshoe hugging the face + full sculpted chin goatee)
			if _candao_mesh == null:
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				var arch_pts := [
					[-0.21, -33.0, 0.028], [-0.23, -24.0, 0.025], [-0.23, -15.0, 0.028], [-0.12, -13.5, 0.030],
					[0.0, -13.2, 0.030], [0.12, -13.5, 0.030], [0.23, -15.0, 0.028], [0.23, -24.0, 0.025], [0.21, -33.0, 0.028]
				]
				var pts: Array = []
				var rx: Array = []
				var ry: Array = []
				for s in arch_pts:
					pts.append(_head_pt(float(s[0]), float(s[1]), 0.506))
					rx.append(float(s[2]))
					ry.append(float(s[2]) * 0.72)
				_add_face_tube(st, pts, rx, ry, false, 8)
				_candao_mesh = st.commit()
			_beard_mesh_on(_candao_mesh, hair_c)
			var chin := _acc("ball", hair_c, Vector3(0, 1.09, 0.376), Vector3(0.14, 0.135, 0.088))
			chin.rotation.x = 0.35

# ---------------- glasses ----------------
## `col`: a colour of their own for the frames (Tomasa's pink cat's eyes: the user, 23 Nov 2026); -1, the model's own
func _glasses(kind: int, col := -1) -> void:
	if kind <= 0:
		return
	if GAFAS.has(kind):                              # custom sculpted glasses/eyepatch meshes in their own colours
		var gname: String = GAFAS[kind]
		var gm := pieza(gname)
		if gm != null and col >= 0:
			_wear(gname, col, true)
		elif gm != null:
			var gsrc := gm.surface_get_material(0)
			var gc: Color = (gsrc as BaseMaterial3D).albedo_color if gsrc is BaseMaterial3D else Color(0.15, 0.15, 0.15)
			_wear(gname, (int(gc.r * 255.0) << 16) | (int(gc.g * 255.0) << 8) | int(gc.b * 255.0), true)
		return
	var frame: int = [0, 0xb9a36a, 0x1b1b1f, 0x4a4a52, 0x8d99ae, 0x1b1b1f, 0xc9a23a, 0x1b1b1f, 0xb22234, 0xe83b5c, 0xd4aa3b][mini(kind, 10)]
	var thick := 0.032 if kind == 2 else (0.022 if kind == 7 else 0.014)
	var ey := 1.42
	if kind == 10:                                   # monocle on left eye (+X) with delicate draped gold chain
		var ex := 0.17
		_acc("ring_thin", frame, Vector3(ex, ey, 0.532), Vector3.ONE * 0.125).rotation.x = PI / 2.0
		_acc("ball", 0xdceef6, Vector3(ex + 0.045, ey + 0.045, 0.534), Vector3(0.022, 0.012, 0.008)).rotation.z = -0.5
		for k in range(13):
			var t: float = float(k) / 12.0
			var a: float = lerpf(0.55, 1.48, t)
			var py: float = lerpf(1.415, 1.215, t) - 0.035 * sin(t * PI)
			var rr: float = sqrt(maxf(0.04, 0.514 * 0.514 - (py - 1.38) * (py - 1.38)))
			_acc("ball", frame, Vector3(sin(a) * rr, py, cos(a) * rr), Vector3.ONE * 0.011)
		return
	for sx in [-1.0, 1.0]:
		var ex: float = sx * 0.17
		match kind:
			1:
				_acc("ring_thin", frame, Vector3(ex, ey, 0.53), Vector3.ONE * 0.12).rotation.x = PI / 2.0
			2:
				_acc("ring", frame, Vector3(ex, ey, 0.535), Vector3.ONE * 0.132).rotation.x = PI / 2.0
			3:      # tube goggles: compact mechanic goggles with metallic rims on a leather strap
				_acc("cyl", frame, Vector3(ex, ey, 0.538), Vector3(0.106, 0.115, 0.106)).rotation.x = PI / 2.0
				_acc("ring_thin", 0x9aa2aa, Vector3(ex, ey, 0.594), Vector3.ONE * 0.105).rotation.x = PI / 2.0
				_acc("cyl", 0x9fb7a0, Vector3(ex, ey, 0.590), Vector3(0.088, 0.018, 0.088)).rotation.x = PI / 2.0
			4:      # opaque: wide enough to hide the eyes cleanly in 3/4 view too
				_acc("ball", 0xe8f0f4, Vector3(ex, ey, 0.528), Vector3(0.126, 0.126, 0.032))
				_acc("ring_thin", frame, Vector3(ex, ey, 0.534), Vector3.ONE * 0.128).rotation.x = PI / 2.0
			7:      # rectangular, of black acetate (frames the whole eye cleanly)
				for e in [[0.0, 0.072, 0.245, 0.024], [0.0, -0.072, 0.245, 0.024], [-0.112, 0.0, 0.024, 0.144], [0.112, 0.0, 0.024, 0.144]]:
					_acc("box", frame, Vector3(ex + float(e[0]), ey + float(e[1]), 0.53), Vector3(float(e[2]), float(e[3]), 0.022))
		if kind != 3:       # flush hinge and sleek temple arm clearing the side of the head cleanly
			var hy := ey + (0.042 if kind == 7 else 0.018)
			_acc("box", frame, Vector3(sx * 0.308, hy, 0.512), Vector3(0.068, thick, 0.020))
			var arm := _acc("box", frame, Vector3(sx * 0.436, hy, 0.258), Vector3(thick, thick, 0.50))
			arm.rotation.y = -sx * 0.360
	var by := ey + (0.030 if kind == 7 else 0.018)
	_acc("box", frame, Vector3(0, by, 0.532), Vector3(0.105, thick * 1.15, 0.020))       # bridge
	if kind == 3:
		_acc("ring_thin", 0x5a4636, Vector3(0, ey + 0.015, 0.0), Vector3.ONE * 0.524)

# ---------------- earrings ----------------
func _earrings(kind: int) -> void:
	if kind <= 0:
		return
	var gold := 0xe6b422 if kind != 6 else 0xd8dde2           # (6: the same hoops, in silver)
	for sx in [-1.0, 1.0]:
		if kind == 3 and sx < 0.0:
			continue                       # single hoop on the left ear (+X)
		match kind:
			1:
				_acc("ball", gold, Vector3(sx * 0.502, 1.275, 0.025), Vector3.ONE * 0.041)
			2, 3, 6:                       # hoops oriented parallel to the cheek (slightly angled forward to read from front & side)
				var hoop := _acc("ring", gold, Vector3(sx * 0.502, 1.215, 0.022), Vector3.ONE * 0.072)
				hoop.rotation = Vector3(0.0, sx * 0.36, PI / 2.0)
			4:                             # drop earrings: gold stud, slender cylindrical wire, ruby teardrop
				_acc("ball", gold, Vector3(sx * 0.502, 1.275, 0.025), Vector3.ONE * 0.032)
				_acc("cyl", gold, Vector3(sx * 0.504, 1.200, 0.025), Vector3(0.010, 0.118, 0.010))
				_acc("ball", gold, Vector3(sx * 0.504, 1.142, 0.025), Vector3.ONE * 0.022)
				_acc("ball", 0xd23b3b, Vector3(sx * 0.504, 1.102, 0.025), Vector3(0.040, 0.056, 0.040))
			5:
				_acc("ball", 0xf8f4ea, Vector3(sx * 0.505, 1.260, 0.025), Vector3.ONE * 0.052)
			7:                             # festive 5-petal fiesta flowers hugging the side of the head
				var froot := Node3D.new()
				froot.position = Vector3(sx * 0.504, 1.255, 0.028)
				froot.rotation.y = sx * (PI / 2.0 - 0.30)
				neck.add_child(froot)
				var fcenter := Parts.part("ball", 0xf4c430, Vector3(0.0, 0.0, 0.014), Vector3(0.024, 0.024, 0.016))
				fcenter.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				froot.add_child(fcenter)
				for k in range(5):
					var pa: float = k * TAU / 5.0
					var pet := Parts.part("ball", 0xef5b84, Vector3(cos(pa) * 0.032, sin(pa) * 0.032, 0.008), Vector3(0.026, 0.026, 0.014))
					pet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					froot.add_child(pet)
			8:                             # matte black plug/button studs
				var rim := _acc("cyl", 0x383842, Vector3(sx * 0.500, 1.265, 0.025), Vector3(0.045, 0.018, 0.045))
				rim.rotation.z = PI / 2.0
				var btn := _acc("cyl", 0x1b1b20, Vector3(sx * 0.508, 1.265, 0.025), Vector3(0.039, 0.018, 0.039))
				btn.rotation.z = PI / 2.0
			9:                             # hanging silver cross earring
				var croot := Node3D.new()
				croot.position = Vector3(sx * 0.504, 1.265, 0.025)
				croot.rotation.y = sx * (PI / 2.0 - 0.35)
				neck.add_child(croot)
				for part_spec in [
					["ball", Vector3(0.0, 0.008, 0.004), Vector3(0.024, 0.024, 0.024)],
					["cyl",  Vector3(0.0, -0.025, 0.006), Vector3(0.008, 0.045, 0.008)],
					["box",  Vector3(0.0, -0.095, 0.008), Vector3(0.020, 0.115, 0.014)],
					["box",  Vector3(0.0, -0.072, 0.008), Vector3(0.076, 0.020, 0.014)],
				]:
					var pm := Parts.part(String(part_spec[0]), 0xd8dde2, part_spec[1], part_spec[2])
					pm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					croot.add_child(pm)

## extra radial clearance (m) for bulky 3D tops so chains, ties, aprons, scarves and neckerchiefs never sink into them
static func _top_pad(top_id: int) -> float:
	match top_id:
		14:            return 0.056       # puffer vest (thickest quilted torso)
		12, 13, 20, 2: return 0.050       # hoodie, turtleneck, anorak, suit jacket
		15, 16, 24:    return 0.042       # waistcoat, cardigan, lab coat
		11, 17, 18:    return 0.036       # collared shirt, hi-vis vest, football shirt
		22:            return 0.024       # dress
		REBECA_VESTIDO: return 0.042      # cardigan over a dress
		9, 10, 19:     return 0.018       # NPC jackets & Breton top
	return 0.0

# ---------------- round the neck ----------------
func _pendant(kind: int, kerchief: int) -> void:
	if kind <= 0:
		return
	var pad := _top_pad(int(look.get("top", 0)))
	if kind >= FIRST_CUELLO:                     # custom sculpted neckwear meshes, in their own colours
		if kind - FIRST_CUELLO < CUELLO.size():
			var cname: String = CUELLO[kind - FIRST_CUELLO]
			var m := pieza(cname)
			if m != null:
				var src := m.surface_get_material(0)
				var c: Color = (src as BaseMaterial3D).albedo_color if src is BaseMaterial3D else Color(0.5, 0.5, 0.5)
				var mi := _wear(cname, (int(c.r * 255.0) << 16) | (int(c.g * 255.0) << 8) | int(c.b * 255.0), false)
				if mi != null and pad > 0.0:
					var k_pad: float = 1.0 + pad / (0.42 if cname == "cuello_bufanda" else (0.38 if cname == "cuello_camara" else 0.34))
					mi.scale = Vector3(_girth * k_pad, 1.0, _girth * k_pad)
		return
	var metal := 0xcfd4d8 if kind == 3 else 0xe6b422
	var gp := pad * _girth
	var sl := _slope()
	if kind <= 3:
		_acc("ring_thin", metal, Vector3(0, 0.912, 0.010), Vector3((0.348 + pad) * _girth, 0.348, (0.348 + pad) * _girth)).rotation.x = 0.25
	match kind:
		2:      # a medal, pitched flush with the torso slope
			var med := _acc("cyl", metal, Vector3(0, 0.785, _r(0.785) + 0.022 + gp), Vector3(0.068, 0.016, 0.068))
			med.rotation.x = PI / 2.0 - sl
		3:      # a cross, pitched flush with the torso slope
			var c_v := _acc("box", metal, Vector3(0, 0.745, _r(0.745) + 0.020 + gp), Vector3(0.030, 0.145, 0.018))
			c_v.rotation.x = -sl
			var c_h := _acc("box", metal, Vector3(0, 0.775, _r(0.775) + 0.020 + gp), Vector3(0.095, 0.030, 0.018))
			c_h.rotation.x = -sl
		4:      # full 360-degree string of pearls round the neck
			for k in range(20):
				var a: float = k * TAU / 20.0
				var py: float = 0.942 - 0.062 * cos(a)
				var rr: float = _r(py) + 0.022 + gp
				_acc("ball", 0xf8f4ea, Vector3(sin(a) * rr, py, cos(a) * rr), Vector3.ONE * 0.034)
		5:      # the neckerchief of the fiestas, knotted in front & hugging the chest slope
			_acc("ring", kerchief, Vector3(0, 0.945, 0.0), Vector3((0.335 + pad) * _girth, 0.335, (0.335 + pad) * _girth)).rotation.x = 0.15
			_acc("ball", kerchief, Vector3(0, 0.905, _r(0.905) + 0.030 + gp), Vector3(0.068, 0.052, 0.044))
			var tip := _acc("cone", kerchief, Vector3(0, 0.805, _r(0.805) + 0.026 + gp), Vector3(0.148, 0.215, 0.028))
			tip.rotation = Vector3(-sl, 0.0, PI)

## Your peña's neckerchief, from the wardrobe at home (the user, 16 November 2026, with a photo of a fiesta neckerchief
## worn point down the back: "Un pañuelo del color de la peña con el graffiti estampado detrás"): rolled round the neck
## and knotted at the front, its point hanging down the back, lying on it, with the peña's logo printed on the cloth
## (assets/creador/panuelo_<id>.png, tools/creador/panuelos.py).
const PANUELO_IDS := ["nietos", "croquetilla", "bordillo", "centradito", "costrola", "al_prao"]      # (creator.gd PENA_IDS)
static var _panuelo_mats := {}
func _panuelo(pena: int, hex: int) -> void:
	var pad := _top_pad(int(look.get("top", 0)))
	var gp := pad * _girth
	var roll := _acc("ring", hex, Vector3(0, 0.945, 0.0), Vector3((0.335 + pad) * _girth, 0.42, (0.335 + pad) * _girth))       # the roll round the neck
	roll.rotation.x = 0.12
	var front := _r(0.9) + 0.03 + gp
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
		var rr: float = _r(yy) + 0.018 + 0.012 * (1.0 - v) + gp
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
	if _carro != null and not phone and not guard:      # (the trolley: its handle in the right hand)
		var want := 1.0 if moving else 0.0
		_carro_k = move_toward(_carro_k, want, dt * 2.5)
		_carro_pose()
		hr = _carro_hand()
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
	if _carro != null:                           # (the trolley's wheels stay on the ground under the bob)
		_carro.position.y = 0.085 - iy
	_blink_tick(dt)

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
