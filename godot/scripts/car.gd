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
	"panda": {"name": "Seta Panda", "max": 25.0, "acc": 6.5, "turn": 0.55, "mass": 850.0, "hp": 100.0, "len": 3.5, "wid": 1.75, "body": 0.8, "cab": 0.72, "cab_len": 2.3, "cab_z": -0.4, "wheel": 0.36,
		"colors": [0x6fb7e6, 0xe6c229, 0xf4f4f0, 0x8d99ae, 0xf3e2b3, 0x3b5fa8, 0xef7f1a, 0x8a6a48, 0xef8fa9, 0x26262b]},
	"cuatrolatas": {"name": "Renol 4L", "offroad": 0.88, "max": 22.0, "acc": 6.5, "turn": 0.55, "mass": 850.0, "hp": 100.0, "len": 3.65, "wid": 1.65, "body": 0.72, "cab": 0.62, "cab_len": 2.1, "cab_z": -0.45, "wheel": 0.35,
		"smoke": 1.5, "colors": [0xf2f0e6, 0xe8a818, 0xc82220, 0xc4683c, 0xc9b478, 0x6aa6d4, 0x5c7c48]},
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
	"kokas": {"name": "Z15 del Kokas", "offroad": 0.9, "max": 27.0, "acc": 7.0, "turn": 0.54, "mass": 1150.0, "hp": 140.0, "len": 4.3, "wid": 1.85, "body": 0.75, "cab": 0.68, "cab_len": 1.25, "cab_z": 0.55, "wheel": 0.38, "box": [2.25, 1.3, -1.0],
		"smoke": 2.4, "colors": [0xf2c81e, 0x1f1f24, 0x3b5fa8], "turbo": {"max": 1.4, "acc": 1.8}},       # Koke el Kokas's taxis (koke.gd): tuned Z15s with nitro, the yellow one his run's
	"tricornio": {"name": "Nisán Patrulla de los Tricornios", "max": 36.0, "acc": 11.5, "turn": 0.64, "mass": 1400.0, "hp": 9999.0, "len": 4.3, "wid": 1.85, "body": 0.9, "cab": 0.78, "cab_len": 2.5, "cab_z": -0.35, "wheel": 0.42,
		"offroad": 0.9, "colors": [0xf4f4f0]},
	"pitufo": {"name": "Seta Panda de los Pitufos", "max": 28.0, "acc": 8.0, "turn": 0.6, "mass": 900.0, "hp": 9999.0, "len": 3.5, "wid": 1.75, "body": 0.8, "cab": 0.72, "cab_len": 2.3, "cab_z": -0.4, "wheel": 0.36, "colors": [0x2456b8]},
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
var unbreakable := false # takes no damage at all (Koke's taxi while its run lasts: koke.gd); the knocks are still counted
var knocks := 0          # how many times it has been hurt (or would have been, if unbreakable)
var inner: Node3D
var bottles: Array = []
var wheels: Array = []
var lights: Array = []   # police light bar halves
var smoke: CPUParticles3D
var running := false     # the engine has been started (it coughs smoke the first time you give it throttle)
var vapour: CPUParticles3D    # the exhaust while moving
var turbo := false       # held down by whoever is driving (only does anything on a car that has one)
var arcade := false      # flat, isolated circuit; its race owns the nitro tank
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
var _fp_hide_head := false        # true in first-person driving mode: hide driver's head so POV sits above shoulders
var _rosary_root: Node3D = null   # interior rearview mirror + swinging silver rosary (Z15 only, spawned while player rides)
var _rosary_piv: Node3D = null    # upper beaded loop + medallion pivot
var _rosary_drop: Node3D = null   # lower pendant + crucifix secondary follow-through pivot
var _dash_root: Node3D = null     # iconic C15 dashboard + working speedometer + single-spoke wheel (Z15 only while driving)
var _dash_needle: Node3D = null   # live speedometer needle pivot
var _dash_wheel: Node3D = null    # single-spoke steering wheel pivot (rotates with steering)
var _dash_dial_mat: StandardMaterial3D = null
var _dash_lamp_mat: StandardMaterial3D = null
var _dash_body_mi: MeshInstance3D = null
var _dash_orig_mesh: Mesh = null
var _mirror_vp: SubViewport = null
var _mirror_cam: Camera3D = null
var _mirror_anchor: RemoteTransform3D = null
var _side_mirror_vp: SubViewport = null
var _side_mirror_cam: Camera3D = null
var _side_mirror_anchor: RemoteTransform3D = null
var _hebro_oil_needle: Node3D = null
var _hebro_throttle_piv: Node3D = null
var _hebro_flap_root: Node3D = null
var _hebro_flap_piv: Node3D = null
var _jul_rpm_needle: Node3D = null
var _jul_boost_needle: Node3D = null
var _jul_boost_mat: StandardMaterial3D = null
var _jul_gps_arrow: Node3D = null
var _bobble_piv: Node3D = null
var _bobble_ang := Vector2.ZERO
var _bobble_vel := Vector2.ZERO
var _panda_seed := -1             # deterministic per-car choice: bobblehead (0 bulldog, 1 pato, 2 rana) & 25% Spanish mirror ribbon
var _panda_bobble := -1
var _panda_lazo := false
var _pitufo_siren_mat: StandardMaterial3D = null
var _edison_seed := -1            # deterministic per-car ambient LED color (0 neon green, 1 ice blue, 2 cyber purple)
var _edison_led := 0
var _yondir_seed := -1            # deterministic per-tractor charms: 50% San Isidro holy card, 25% Spanish roof keychain ribbon
var _yondir_san_isidro := false
var _yondir_lazo := false
var _r4_shifter_piv: Node3D = null
var _r4_shifter_base := Vector3.ZERO
var _r4_shifter_z := 0.0
var _r4_shifter_roll := 0.0
var _r4_seed := -1                # deterministic per-car choice among the 5 Madridejos Semana Santa cofradías (0..4)
var _r4_cofrade := -1
var _edison_led_mat: StandardMaterial3D = null
var _edison_speed_lbl: Label3D = null
var _edison_gear_lbl: Label3D = null
var _edison_lane_piv: Node3D = null
var _edison_pwr_bar: MeshInstance3D = null
var _edison_pwr_mat: StandardMaterial3D = null
var _edison_last_kmh := -1
var _gps_vp: SubViewport = null
var _gps_map: Control = null
var _dash_base_pos := Vector3.ZERO
var _dash_max_kmh := 120.0
var _dash_speed_ang := 0.0
var _dash_wheel_ang := 0.0
var _hebro_oil_ang := 0.0
var _hebro_thr_ang := 0.0
var _hebro_flap_ang := 0.0
var _jul_rpm_ang := 0.0
var _jul_boost_ang := 0.0
var _ros_ang := Vector2.ZERO      # [pitch_x, roll_z] of main rosary pendulum (radians)
var _ros_vel := Vector2.ZERO
var _drop_ang := Vector2.ZERO     # secondary swing of the lower crucifix
var _drop_vel := Vector2.ZERO
var _drop_yaw := 0.0
var _drop_yaw_v := 0.0
var _ros_prev_v := Vector3.ZERO
var _ros_t := 0.0
static var _ros_silver: StandardMaterial3D
static var _ros_pearl: StandardMaterial3D
static var _ros_detail: StandardMaterial3D
static var _ros_mirror: StandardMaterial3D
static var _dash_dial_tex: ImageTexture
static var _dash_rim_mesh: TorusMesh
static var _hebro_rim_mesh: TorusMesh
static var _hebro_bezel_mesh: TorusMesh
static var _hebro_chrome: StandardMaterial3D
static var _hebro_rust: StandardMaterial3D
static var _hebro_pod_tex := {}
static var _hebro_dial_tex := {}
static var _jul_alu: StandardMaterial3D
static var _jul_rim_mesh: TorusMesh
static var _jul_bezel_big: TorusMesh
static var _jul_bezel_sm: TorusMesh
static var _jul_dial_tex := {}
static var _jul_gps_tex: ImageTexture
static var _jul_badge_tex: ImageTexture
static var _panda_dial_tex: ImageTexture
static var _panda_badge_tex: ImageTexture
static var _edison_carbon_tex: ImageTexture
static var _edison_screen_tex: ImageTexture
static var _edison_wheel_tex: ImageTexture
static var _edison_glass: StandardMaterial3D
static var _yondir_rim_mesh: TorusMesh
static var _yondir_bezel_big: TorusMesh
static var _yondir_bezel_sm: TorusMesh
static var _yondir_dial_tex := {}
static var _yondir_badge_tex: ImageTexture
static var _yondir_isidro_tex: ImageTexture
static var _r4_dial_tex: ImageTexture
static var _r4_rim_mesh: TorusMesh
static var _itv_tex := {}
static var _oval_mirror_shader: Shader
static var _z15_cab_meshes := {}  # orig body Mesh -> copy with baked steering wheel (and Z15/Julietta dash/mirror) stripped while player drives
static var _glass: StandardMaterial3D
var dozing := false        # parked and far from anybody: taken out of the physics until somebody comes near
var awake_t := 0.0         # just moved (place): kept in the physics a moment, or its wheels stay where it stood
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
var _ramp_cool := 0.0    # short cooldown after launching off a ramp/stair structure
static var _slip_mat: PhysicsMaterial
var soaped := 0            # knocks it slid off (the tests)
var soap := false          # the car you drive slides off walls it only grazes (set_soap; game.gd _enter_car/_exit_car)
const RESPRAY := [0x6fb7e6, 0xe6c229, 0xf4f4f0, 0xd42027, 0x3b5fa8, 0xef7f1a, 0x7d3fc4, 0x2f8a3a, 0xef8fa9, 0x1f1f24]

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
	if place == 0 and _fp_hide_head:
		set_driver_head_visible(false)

## Shows or hides only the driver's head (keeps shoulders, hands on wheel, and steering wheel visible for 1st-person POV).
func set_driver_head_visible(on: bool) -> void:
	_fp_hide_head = not on
	var m_mode := SubViewport.UPDATE_ALWAYS if _fp_hide_head else SubViewport.UPDATE_DISABLED
	if _mirror_vp != null and is_instance_valid(_mirror_vp):
		_mirror_vp.render_target_update_mode = m_mode
	if _side_mirror_vp != null and is_instance_valid(_side_mirror_vp):
		_side_mirror_vp.render_target_update_mode = m_mode
	if _gps_vp != null and is_instance_valid(_gps_vp):
		_gps_vp.render_target_update_mode = m_mode
	# On Edison, Yondir & Renol 4L, only swap the stock cab glass out while in 1st-person; keep exterior glass intact in 3rd-person!
	if (kind == "edison" or kind == "yondir" or kind == "cuatrolatas") and _dash_root != null and is_instance_valid(_dash_root):
		if _fp_hide_head:
			if kind == "edison":
				_set_edison_cab_stripped()
			elif kind == "yondir":
				_set_yondir_cab_stripped()
			else:
				_set_r4_cab_stripped()
		else:
			_set_z15_cab_stripped(false)
	var rn: Node3D = _rider_nodes[0]
	if rn == null or not is_instance_valid(rn):
		return
	var head := rn.find_child("head", true, false)
	if head is Node3D:
		(head as Node3D).visible = on

## World-space transform for first-person driving POV, right above the driver's shoulders looking forward out the windscreen.
func driver_pov() -> Transform3D:
	var b := global_transform.basis.orthonormalized()
	var cam_b := Basis(-b.x, b.y, -b.z).orthonormalized()
	var size: float = float(model.get_meta("rider")) if model != null else RIDER
	var local_eye: Vector3
	var rn: Node3D = _rider_nodes[0]
	if rn != null and is_instance_valid(rn):
		# Eye level above the shoulders, looking cleanly over the steering wheel and dashboard out the windscreen
		local_eye = rn.position + Vector3(0.0, 1.54 * size, 0.24 * size)
		if kind == "edison":
			# Sit inside the Edison cabin behind the real A-pillars (1st-person glass cutout clears the windscreen!)
			local_eye.y += 0.10
			local_eye.z += 0.14
		elif kind == "julietta":
			# Low Italian roadster: sit comfortably behind the raked windscreen in 1st-person (3rd-person rider stays untouched)
			local_eye.y -= 0.25
			local_eye.z += 0.05
		elif kind == "yondir":
			# Seated cleanly inside the Yondir cab below the roof header (y=2.66) and back from the windscreen (z=+0.18)
			local_eye.y -= 0.14
			local_eye.z -= 0.12
		elif kind == "cuatrolatas":
			# Classic Renol 4L seating: back slightly so the umbrella gear lever, standing dash mirror, chrome arc speedo & T-wheel frame cleanly
			local_eye.y -= 0.08
			local_eye.z -= 0.14
		elif kind == "z15" or kind == "kokas":
			# Sit comfortably inside the Z15 cab so A-pillars, interior roof header, mirror & rosary frame cleanly!
			local_eye.z -= 0.14
	else:
		var sill: float = float(spec["wheel"]) + 0.15 + float(spec["body"])
		local_eye = Vector3(0.0, sill + 0.35, float(spec["cab_z"]) + 0.25)
	var world_eye: Vector3 = inner.to_global(local_eye) if inner != null else to_global(local_eye)
	return Transform3D(cam_b, world_eye)

## Interior rearview mirror + swinging silver rosary + iconic C15 dashboard with live speedometer (the user, 24 Nov 2026):
## spawned ONLY while the player is driving a Z15 (z15 / kokas) and freed on exit so idle vans cost zero resources.
func set_rosary(on: bool) -> void:
	if _rosary_root != null and is_instance_valid(_rosary_root):
		_rosary_root.queue_free()
	if _dash_root != null and is_instance_valid(_dash_root):
		_dash_root.queue_free()
	if _mirror_anchor != null and is_instance_valid(_mirror_anchor):
		_mirror_anchor.queue_free()
	if _side_mirror_anchor != null and is_instance_valid(_side_mirror_anchor):
		_side_mirror_anchor.queue_free()
	if _hebro_flap_root != null and is_instance_valid(_hebro_flap_root):
		_hebro_flap_root.queue_free()
	_rosary_root = null
	_rosary_piv = null
	_rosary_drop = null
	_dash_root = null
	_dash_needle = null
	_dash_wheel = null
	_dash_dial_mat = null
	_dash_lamp_mat = null
	_mirror_vp = null
	_mirror_cam = null
	_mirror_anchor = null
	_side_mirror_vp = null
	_side_mirror_cam = null
	_side_mirror_anchor = null
	_hebro_oil_needle = null
	_hebro_throttle_piv = null
	_hebro_flap_root = null
	_hebro_flap_piv = null
	_jul_rpm_needle = null
	_jul_boost_needle = null
	_jul_boost_mat = null
	_jul_gps_arrow = null
	_bobble_piv = null
	_bobble_ang = Vector2.ZERO
	_bobble_vel = Vector2.ZERO
	_pitufo_siren_mat = null
	_edison_led_mat = null
	_edison_speed_lbl = null
	_edison_gear_lbl = null
	_edison_lane_piv = null
	_edison_pwr_bar = null
	_edison_pwr_mat = null
	_edison_last_kmh = -1
	_gps_vp = null
	_gps_map = null
	_r4_shifter_piv = null
	_r4_shifter_base = Vector3.ZERO
	_r4_shifter_z = 0.0
	_r4_shifter_roll = 0.0
	_dash_base_pos = Vector3.ZERO
	_dash_max_kmh = 120.0
	_dash_speed_ang = 0.0
	_dash_wheel_ang = 0.0
	_hebro_oil_ang = 0.0
	_hebro_thr_ang = 0.0
	_hebro_flap_ang = 0.0
	_jul_rpm_ang = 0.0
	_jul_boost_ang = 0.0
	_ros_ang = Vector2.ZERO
	_ros_vel = Vector2.ZERO
	_drop_ang = Vector2.ZERO
	_drop_vel = Vector2.ZERO
	_drop_yaw = 0.0
	_drop_yaw_v = 0.0
	_ros_prev_v = linear_velocity
	# Restore stock body mesh, generic rider wheel & static sitting hands if they were swapped/hidden for a custom cockpit
	_set_z15_cab_stripped(false)
	var rn0: Node3D = _rider_nodes[0]
	if rn0 != null and is_instance_valid(rn0):
		for cname in ["rider_wheel", "hand_l", "hand_r"]:
			var cn := rn0.find_child(cname, true, false)
			if cn is Node3D:
				(cn as Node3D).visible = true
	if not on or inner == null or (kind != "z15" and kind != "kokas" and kind != "tractor" and kind != "julietta" and kind != "panda" and kind != "pitufo" and kind != "edison" and kind != "yondir" and kind != "cuatrolatas"):
		return
	var size: float = float(model.get_meta("rider")) if model != null else RIDER
	var rn: Node3D = _rider_nodes[0]
	var eye_x: float = rn.position.x if (rn != null and is_instance_valid(rn)) else (0.0 if (kind == "tractor" or kind == "yondir") else 0.38)
	var eye_y: float = (rn.position.y + 1.54 * size) if (rn != null and is_instance_valid(rn)) else (float(spec["wheel"]) + 0.15 + float(spec["body"]) + 0.35)
	var eye_z: float = (rn.position.z + 0.24 * size) if (rn != null and is_instance_valid(rn)) else (float(spec["cab_z"]) + 0.25)
	if kind == "tractor":
		_set_hebro_cab_stripped()
		_build_hebro_dash(eye_x, eye_y, eye_z)
		if rn != null and is_instance_valid(rn):
			for cname in ["rider_wheel", "hand_l", "hand_r"]:
				var cn := rn.find_child(cname, true, false)
				if cn is Node3D:
					(cn as Node3D).visible = false
		return
	if kind == "yondir":
		if _fp_hide_head:
			_set_yondir_cab_stripped()
		_build_yondir_dash(eye_x, eye_y - 0.14, eye_z - 0.12)
		if rn != null and is_instance_valid(rn):
			for cname in ["rider_wheel", "hand_l", "hand_r"]:
				var cn := rn.find_child(cname, true, false)
				if cn is Node3D:
					(cn as Node3D).visible = false
		return
	if kind == "cuatrolatas":
		if _fp_hide_head:
			_set_r4_cab_stripped()
		_build_r4_dash(eye_x, eye_y - 0.08, eye_z - 0.14)
		if rn != null and is_instance_valid(rn):
			for cname in ["rider_wheel", "hand_l", "hand_r"]:
				var cn := rn.find_child(cname, true, false)
				if cn is Node3D:
					(cn as Node3D).visible = false
		return
	if kind == "julietta":
		_set_julietta_cab_stripped()
		_build_julietta_dash(eye_x, eye_y - 0.25, eye_z + 0.05)
		if rn != null and is_instance_valid(rn):
			for cname in ["rider_wheel", "hand_l", "hand_r"]:
				var cn := rn.find_child(cname, true, false)
				if cn is Node3D:
					(cn as Node3D).visible = false
		return
	if kind == "panda" or kind == "pitufo":
		_build_panda_dash(eye_x, eye_y, eye_z)
		if rn != null and is_instance_valid(rn):
			for cname in ["rider_wheel", "hand_l", "hand_r"]:
				var cn := rn.find_child(cname, true, false)
				if cn is Node3D:
					(cn as Node3D).visible = false
		return
	if kind == "edison":
		if _fp_hide_head:
			_set_edison_cab_stripped()
		_build_edison_dash(eye_x, eye_y + 0.10, eye_z + 0.14)
		if rn != null and is_instance_valid(rn):
			for cname in ["rider_wheel", "hand_l", "hand_r"]:
				var cn := rn.find_child(cname, true, false)
				if cn is Node3D:
					(cn as Node3D).visible = false
		return
	if _ros_silver == null:
		_ros_silver = StandardMaterial3D.new()
		_ros_silver.albedo_color = Color(0.84, 0.86, 0.90)
		_ros_silver.metallic = 0.86
		_ros_silver.roughness = 0.22
		_ros_pearl = StandardMaterial3D.new()
		_ros_pearl.albedo_color = Color(0.94, 0.95, 0.97)
		_ros_pearl.metallic = 0.45
		_ros_pearl.roughness = 0.18
		_ros_detail = StandardMaterial3D.new()
		_ros_detail.albedo_color = Color(0.62, 0.65, 0.70)
		_ros_detail.metallic = 0.78
		_ros_detail.roughness = 0.35
		_ros_mirror = StandardMaterial3D.new()
		_ros_mirror.albedo_color = Color(0.36, 0.40, 0.46)
		_ros_mirror.metallic = 0.42
		_ros_mirror.roughness = 0.16
	# Anchor right at the upper-center of the Z15 windshield header (inside cab roof, cleanly framed in 1st-person)
	eye_z -= 0.14
	_rosary_root = Node3D.new()
	_rosary_root.name = "RosaryMirror"
	_rosary_root.position = Vector3(0.07, eye_y + 0.21, eye_z + 0.48)
	inner.add_child(_rosary_root)

	# Clean interior cab roof headliner & upper windscreen header bar (sk/z15.glb's exterior roof sits higher/one-sided!)
	var m_headliner := Parts.mat(0xb8bcc2)
	var m_hdr_trim := Parts.mat(0x282b30)
	_rosary_root.add_child(_ros_part("box", m_hdr_trim, Vector3(-0.07, 0.068, 0.025), Vector3(1.44, 0.042, 0.095)))
	_rosary_root.add_child(_ros_part("box", m_headliner, Vector3(-0.07, 0.095, -0.34), Vector3(1.46, 0.032, 0.72)))

	# Interior rearview mirror + stalk mounted to cab header
	var stalk := _ros_part("cyl", Parts.mat(0x202226), Vector3(0.0, 0.032, 0.015), Vector3(0.008, 0.068, 0.008))
	stalk.rotation.x = -0.35
	_rosary_root.add_child(stalk)
	_rosary_root.add_child(_ros_part("box", Parts.mat(0x1f2126), Vector3(0.0, 0.0, 0.0), Vector3(0.195, 0.052, 0.020)))
	# Ultra-lightweight live rearview mirror (192x48 px SubViewport, no shadows/MSAA, full game FPS while in 1st-person)
	var glass_mat: StandardMaterial3D = _ros_mirror
	if DisplayServer.get_name() != "headless":
		_mirror_vp = SubViewport.new()
		_mirror_vp.name = "MirrorViewport"
		_mirror_vp.size = Vector2i(192, 48)
		_mirror_vp.world_3d = get_world_3d()
		_mirror_vp.positional_shadow_atlas_size = 0
		_mirror_vp.msaa_3d = Viewport.MSAA_DISABLED
		_mirror_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		_mirror_vp.use_debanding = false
		_mirror_vp.transparent_bg = false
		_mirror_vp.audio_listener_enable_2d = false
		_mirror_vp.audio_listener_enable_3d = false
		_mirror_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if _fp_hide_head else SubViewport.UPDATE_DISABLED
		_rosary_root.add_child(_mirror_vp)
		_mirror_cam = Camera3D.new()
		_mirror_cam.name = "MirrorCamera"
		_mirror_cam.fov = 26.0
		_mirror_cam.near = 0.2
		_mirror_cam.far = 90.0
		_mirror_cam.current = true
		_mirror_vp.add_child(_mirror_cam)
		# RemoteTransform3D behind the rear doors keeps the rear camera synced at native game FPS with zero GDScript overhead
		_mirror_anchor = RemoteTransform3D.new()
		_mirror_anchor.name = "MirrorCamAnchor"
		_mirror_anchor.position = Vector3(0.0, 1.62, -2.22)
		_mirror_anchor.rotation.x = deg_to_rad(-4.0)
		_mirror_anchor.update_scale = false
		inner.add_child(_mirror_anchor)
		_mirror_anchor.remote_path = _mirror_cam.get_path()
		_mirror_anchor.force_update_cache()
		glass_mat = StandardMaterial3D.new()
		glass_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glass_mat.albedo_texture = _mirror_vp.get_texture()
		glass_mat.albedo_color = Color(0.92, 0.96, 1.0)
		glass_mat.uv1_scale = Vector3(-1.0, 1.0, 1.0)     # true horizontal mirror reflection (left behind = left in mirror)
		glass_mat.uv1_offset = Vector3(1.0, 0.0, 0.0)
		glass_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	var mirror_quad := MeshInstance3D.new()
	var mq := QuadMesh.new()
	mq.size = Vector2(0.180, 0.042)
	mirror_quad.mesh = mq
	mirror_quad.material_override = glass_mat
	mirror_quad.position = Vector3(0.0, 0.0, -0.011)
	mirror_quad.rotation.y = PI
	mirror_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rosary_root.add_child(mirror_quad)

	# Primary pendulum pivot hanging cleanly from the mirror stalk just behind the mirror glass
	_rosary_piv = Node3D.new()
	_rosary_piv.name = "RosaryPivot"
	_rosary_piv.position = Vector3(0.0, -0.020, 0.012)
	_rosary_root.add_child(_rosary_piv)

	# Upper beaded loop (6 pearly beads per side + silver links down to the oval medallion)
	var loop_pts: Array = [
		Vector2(0.011, -0.006),
		Vector2(0.027, -0.022),
		Vector2(0.031, -0.044),
		Vector2(0.027, -0.067),
		Vector2(0.019, -0.088),
		Vector2(0.010, -0.106),
	]
	for sgn: float in [-1.0, 1.0]:
		var prev := Vector3(0.0, 0.0, 0.0)
		for pt in loop_pts:
			var cur := Vector3((pt as Vector2).x * sgn, (pt as Vector2).y, 0.0)
			_rosary_piv.add_child(_ros_link(prev, cur))
			_rosary_piv.add_child(_ros_part("ball", _ros_pearl, cur, Vector3(0.0072, 0.0072, 0.0072)))
			prev = cur
		_rosary_piv.add_child(_ros_link(prev, Vector3(0.0, -0.120, 0.0)))

	# Oval silver medallion (centerpiece)
	_rosary_piv.add_child(_ros_part("ball", _ros_silver, Vector3(0.0, -0.125, 0.0), Vector3(0.012, 0.017, 0.0035)))
	_rosary_piv.add_child(_ros_part("ball", _ros_detail, Vector3(0.0, -0.125, -0.0022), Vector3(0.008, 0.012, 0.0022)))

	# Secondary follow-through pivot below the medallion (single drop bead + ornate silver crucifix)
	_rosary_drop = Node3D.new()
	_rosary_drop.name = "RosaryDrop"
	_rosary_drop.position = Vector3(0.0, -0.141, 0.0)
	_rosary_piv.add_child(_rosary_drop)
	_rosary_drop.add_child(_ros_link(Vector3(0.0, 0.0, 0.0), Vector3(0.0, -0.044, 0.0)))
	_rosary_drop.add_child(_ros_part("ball", _ros_pearl, Vector3(0.0, -0.022, 0.0), Vector3(0.0078, 0.0078, 0.0078)))

	# Silver crucifix at the bottom of the drop
	var cy := -0.072
	_rosary_drop.add_child(_ros_part("box", _ros_silver, Vector3(0.0, cy, 0.0), Vector3(0.0075, 0.056, 0.0042)))
	_rosary_drop.add_child(_ros_part("box", _ros_silver, Vector3(0.0, cy + 0.010, 0.0), Vector3(0.038, 0.0075, 0.0042)))
	# Ornate cross tips + subtle central corpus relief
	for tip in [Vector3(0.0, cy + 0.029, 0.0), Vector3(0.0, cy - 0.029, 0.0), Vector3(-0.020, cy + 0.010, 0.0), Vector3(0.020, cy + 0.010, 0.0)]:
		_rosary_drop.add_child(_ros_part("ball", _ros_silver, tip, Vector3(0.0052, 0.0052, 0.0036)))
	_rosary_drop.add_child(_ros_part("box", _ros_detail, Vector3(0.0, cy + 0.002, -0.0024), Vector3(0.0045, 0.022, 0.0022)))
	_rosary_drop.add_child(_ros_part("box", _ros_detail, Vector3(0.0, cy + 0.010, -0.0024), Vector3(0.018, 0.0040, 0.0022)))
	# 4 accumulated horizontal Spanish ITV stickers in the upper-right windscreen corner of the Z15 (classic work van!)
	var itv_cols := [0xd62824, 0xe8d028, 0x34a842, 0xd62824]
	for ii in range(4):
		var st := _make_itv_sticker(itv_cols[ii])
		st.name = "ItvSticker%d" % ii
		# Stacked cleanly along the upper-right passenger corner of the Z15 windscreen, slightly crooked by hand
		var col_i := ii % 2
		var row_i := ii / 2
		st.position = Vector3(-0.34 - col_i * 0.056, 0.020 - row_i * 0.038, 0.025 + row_i * 0.014)
		st.rotation = Vector3(deg_to_rad(18.0), PI, deg_to_rad([-2.0, 1.5, 1.2, -1.8][ii]))
		_rosary_root.add_child(st)
	# Strip the Sketchfab Z15's baked low-poly steering wheel, old dash & mirror while driving so our animated C15 cab never clips
	_set_z15_cab_stripped(true)
	# Build the iconic 80s Citroën C15 grey dashboard, working speedometer, and single-spoke steering wheel
	_build_z15_dash(eye_x, eye_y, eye_z)
	if rn != null and is_instance_valid(rn):
		for cname in ["rider_wheel", "hand_l", "hand_r"]:
			var cn := rn.find_child(cname, true, false)
			if cn is Node3D:
				(cn as Node3D).visible = false

## Swaps the Z15's `body` mesh (while the player is driving) to a cached copy with the Sketchfab model's
## baked beige steering wheel, old dash cowl, and stock interior mirror removed — keeping the seats, doors,
## floor, roof, and exterior bodywork untouched. Restored cleanly on exit.
func _set_z15_cab_stripped(on: bool) -> void:
	if not on:
		if _dash_body_mi != null and is_instance_valid(_dash_body_mi) and _dash_orig_mesh != null:
			_dash_body_mi.mesh = _dash_orig_mesh
			if kind == "cuatrolatas":
				for s in range(_dash_orig_mesh.get_surface_count()):
					var mat = _dash_orig_mesh.surface_get_material(s)
					if mat != null and String(mat.resource_name).begins_with("Window"):
						_dash_body_mi.set_surface_override_material(s, Modelos._pane())
		_dash_body_mi = null
		_dash_orig_mesh = null
		return
	if model == null or not is_instance_valid(model):
		return
	var bmi := model.find_child("body", true, false) as MeshInstance3D
	if bmi == null or bmi.mesh == null:
		return
	_dash_body_mi = bmi
	_dash_orig_mesh = bmi.mesh
	if not _z15_cab_meshes.has(_dash_orig_mesh):
		var orig: Mesh = _dash_orig_mesh
		var xf: Transform3D = model.transform * bmi.transform
		var out := ArrayMesh.new()
		for s in range(orig.get_surface_count()):
			var a: Array = orig.surface_get_arrays(s)
			var mat = orig.surface_get_material(s)
			var nm := String(mat.resource_name) if mat != null else ""
			if nm == "Material_1" or nm == "Material_14" or nm == "Color_M00":
				var verts: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
				var idx := PackedInt32Array()
				if a[Mesh.ARRAY_INDEX] != null:
					idx = a[Mesh.ARRAY_INDEX]
				else:
					for k in range(verts.size()):
						idx.append(k)
				var keep := PackedInt32Array()
				if nm == "Material_14":
					for t in range(0, idx.size() - 2, 3):
						var mid: Vector3 = xf * ((verts[idx[t]] + verts[idx[t + 1]] + verts[idx[t + 2]]) / 3.0)
						# Drop baked steering wheel & old dash cowl; keep seats (z <= 0.38), door cards (|x| >= 0.65) & floor (y <= 0.72)
						if not (mid.z > 0.38 and mid.y > 0.72 and absf(mid.x) < 0.65):
							keep.append(idx[t])
							keep.append(idx[t + 1])
							keep.append(idx[t + 2])
				elif nm == "Color_M00":
					for t in range(0, idx.size() - 2, 3):
						var mid: Vector3 = xf * ((verts[idx[t]] + verts[idx[t + 1]] + verts[idx[t + 2]]) / 3.0)
						# Drop only the floating baked stock rearview mirror glass pane in the upper windscreen center
						if not (mid.z > 0.42 and mid.y > 1.30 and absf(mid.x) < 0.22):
							keep.append(idx[t])
							keep.append(idx[t + 1])
							keep.append(idx[t + 2])
				if keep.is_empty():
					# Keep surface index alignment intact (1 degenerate triangle) so body paint surface overrides never shift
					keep = PackedInt32Array([0, 0, 0])
				a[Mesh.ARRAY_INDEX] = keep
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
			out.surface_set_material(s, mat)
		_z15_cab_meshes[_dash_orig_mesh] = out
	bmi.mesh = _z15_cab_meshes[_dash_orig_mesh]

## Strips ONLY the baked static steering wheel from `sk/hebro.glb` while the player drives the Súper Hebro 555
## (leaving the hood, exhaust, fenders and engine untouched; restored cleanly on exit by `_set_z15_cab_stripped(false)`).
func _set_hebro_cab_stripped() -> void:
	if model == null or not is_instance_valid(model):
		return
	var bmi := model.find_child("body", true, false) as MeshInstance3D
	if bmi == null or bmi.mesh == null:
		return
	_dash_body_mi = bmi
	_dash_orig_mesh = bmi.mesh
	if not _z15_cab_meshes.has(_dash_orig_mesh):
		var orig: Mesh = _dash_orig_mesh
		var xf: Transform3D = model.transform * bmi.transform
		var out := ArrayMesh.new()
		for s in range(orig.get_surface_count()):
			var a: Array = orig.surface_get_arrays(s)
			var mat = orig.surface_get_material(s)
			var verts: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			var idx := PackedInt32Array()
			if a[Mesh.ARRAY_INDEX] != null:
				idx = a[Mesh.ARRAY_INDEX]
			else:
				for k in range(verts.size()):
					idx.append(k)
			var keep := PackedInt32Array()
			for t in range(0, idx.size() - 2, 3):
				var mid: Vector3 = xf * ((verts[idx[t]] + verts[idx[t + 1]] + verts[idx[t + 2]]) / 3.0)
				# Baked tractor steering wheel sits at Y > 1.56, Z in [-0.36..0.15] (keep bonnet at Z >= 0.15 & lower chassis)
				var is_old_wheel: bool = mid.x > -0.48 and mid.x < 0.32 and mid.z > -0.38 and ((mid.y > 1.67 and mid.z < 0.17) or (mid.y > 1.54 and mid.z < 0.08))
				if not is_old_wheel:
					keep.append(idx[t])
					keep.append(idx[t + 1])
					keep.append(idx[t + 2])
			if keep.is_empty():
				keep = PackedInt32Array([0, 0, 0])
			a[Mesh.ARRAY_INDEX] = keep
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
			out.surface_set_material(s, mat)
		_z15_cab_meshes[_dash_orig_mesh] = out
	bmi.mesh = _z15_cab_meshes[_dash_orig_mesh]

## Procedural weathered painted metal texture (tractor blue or red with rusty chipped edges, matching the Ebro Super 55 pod photo)
static func _build_hebro_pod_tex(hex: int) -> ImageTexture:
	if _hebro_pod_tex.has(hex):
		return _hebro_pod_tex[hex]
	var w := 128
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var base := Parts.col(hex)
	var light := base.lerp(Color(0.85, 0.90, 0.96), 0.18)
	var rust_dark := Color(0.38, 0.21, 0.12, 1.0)
	var rust_warm := Color(0.56, 0.32, 0.16, 1.0)
	for py in range(h):
		for px in range(w):
			var u := (float(px) / float(w - 1)) * 2.0 - 1.0
			var v := (float(py) / float(h - 1)) * 2.0 - 1.0
			var r := sqrt(u * u + v * v)
			var n := sin(u * 13.0 + v * 7.0) * cos(u * 9.0 - v * 15.0) + 0.5 * sin(u * 29.0 - v * 23.0)
			var col := base.lerp(light, clampf(0.35 - v * 0.3 + n * 0.08, 0.0, 1.0))
			# Weathered rust chipping along outer rim & center column hole
			var edge_wear := smoothstep(0.68, 0.96, r + n * 0.14)
			var hole_wear := smoothstep(0.32, 0.16, r - n * 0.07)
			var spot := smoothstep(0.76, 0.95, n * 0.7 + 0.35) * 0.65
			var wear := clampf(maxf(maxf(edge_wear, hole_wear), spot), 0.0, 1.0)
			if wear > 0.25:
				col = col.lerp(rust_dark.lerp(rust_warm, clampf(0.5 + n * 0.4, 0.0, 1.0)), clampf((wear - 0.25) * 1.4, 0.0, 0.92))
			col.a = 1.0
			img.set_pixel(px, py, col)
	var tex := ImageTexture.create_from_image(img)
	_hebro_pod_tex[hex] = tex
	return tex

## Tiny 3x5 pixel lettering helper for vintage tractor gauge markings ("HEBRO")
static func _draw_tiny_word(img: Image, word: String, x0: int, y0: int, col: Color) -> void:
	# Tiny 3x5 pixel lettering helper for vintage tractor & sporty gauge markings
	const FONT := {
		"A": ["010", "101", "111", "101", "101"],
		"B": ["110", "101", "110", "101", "110"],
		"D": ["110", "101", "101", "101", "110"],
		"E": ["111", "100", "110", "100", "111"],
		"G": ["011", "100", "101", "101", "011"],
		"H": ["101", "101", "111", "101", "101"],
		"I": ["111", "010", "010", "010", "111"],
		"K": ["101", "110", "100", "110", "101"],
		"M": ["101", "111", "111", "101", "101"],
		"N": ["101", "111", "111", "101", "101"],
		"O": ["111", "101", "101", "101", "111"],
		"P": ["110", "101", "110", "100", "100"],
		"R": ["110", "101", "110", "101", "101"],
		"S": ["011", "100", "010", "001", "110"],
		"T": ["111", "010", "010", "010", "010"],
		"V": ["101", "101", "101", "101", "010"],
		".": ["000", "000", "000", "000", "010"],
	}
	var cx := x0
	for i in range(word.length()):
		var ch := word.substr(i, 1)
		if FONT.has(ch):
			var rows: Array = FONT[ch]
			for ry in range(5):
				for rx in range(3):
					if rows[ry].substr(rx, 1) == "1":
						var px := cx + rx
						var py := y0 + ry
						if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
							img.set_pixel(px, py, col)
		cx += 4

## Procedural 128x128 vintage circular tractor gauges: "speed" (0-50 km/h) and "oil" (Presión de Aceite HEBRO 0-8 Kg/cm²)
static func _build_hebro_dial_tex(mode: String) -> ImageTexture:
	if _hebro_dial_tex.has(mode):
		return _hebro_dial_tex[mode]
	var sz := 128
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	var cx := 64.0
	var cy := 64.0
	var rad := 60.0
	var face := Color(0.11, 0.11, 0.10, 1.0)
	var aged := Color(0.24, 0.17, 0.10, 1.0)
	var ring := Color(0.72, 0.72, 0.68, 1.0)
	for py in range(sz):
		for px in range(sz):
			var dx := float(px) - cx
			var dy := float(py) - cy
			var d := sqrt(dx * dx + dy * dy)
			if d <= rad:
				var patina := clampf((dy / rad) * 0.45 + 0.18, 0.0, 0.55)
				var c := ring if d > rad - 3.0 else face.lerp(aged, patina * (0.65 if mode == "oil" else 0.35))
				img.set_pixel(px, py, c)
	if mode == "speed":
		# 0..50 km/h across -125..+125 deg (red over-speed zone 40..50)
		for step in range(0, 21):
			var frac := float(step) / 20.0
			var ang := deg_to_rad(lerpf(-125.0, 125.0, frac))
			var major := step % 4 == 0
			var mid := step % 2 == 0
			var r_in := rad - (14.0 if major else (9.5 if mid else 6.0))
			var r_out := rad - 4.0
			var tcol := Color(0.90, 0.26, 0.18, 1.0) if step >= 16 else (Color(0.95, 0.93, 0.84, 1.0) if major else Color(0.76, 0.74, 0.68, 1.0))
			var thick := 2 if major else 1
			for s in range(18):
				var rr := lerpf(r_in, r_out, float(s) / 17.0)
				var gx := int(round(cx + sin(ang) * rr))
				var gy := int(round(cy - cos(ang) * rr))
				for ox in range(-thick / 2, thick / 2 + 1):
					for oy in range(-thick / 2, thick / 2 + 1):
						if gx + ox >= 0 and gx + ox < sz and gy + oy >= 0 and gy + oy < sz:
							img.set_pixel(gx + ox, gy + oy, tcol)
		# Classic mechanical hour/km counter window below hub
		for py in range(84, 96):
			for px in range(42, 86):
				var border := py == 84 or py == 95 or px == 42 or px == 85
				img.set_pixel(px, py, Color(0.22, 0.21, 0.19, 1.0) if border else Color(0.86, 0.83, 0.72, 1.0))
		for di in range(5):
			var dx0 := 45 + di * 8
			for py in range(87, 93):
				img.set_pixel(dx0 + 2, py, Color(0.14, 0.13, 0.12, 1.0))
				if (di + py) % 2 == 0:
					img.set_pixel(dx0 + 4, py, Color(0.14, 0.13, 0.12, 1.0))
		_draw_tiny_word(img, "KMH", 58, 102, Color(0.86, 0.84, 0.76, 1.0))
	else:
		# Classic Ebro oil-pressure dial ("Presión de aceite HEBRO", 0..8 Kg/cm²) with normal band 2..6
		for py in range(sz):
			for px in range(sz):
				var dx := float(px) - cx
				var dy := float(py) - cy
				var d := sqrt(dx * dx + dy * dy)
				if d >= rad - 13.0 and d <= rad - 6.0:
					var a_deg := rad_to_deg(atan2(dx, -dy))
					if a_deg >= -65.0 and a_deg <= 65.0:
						img.set_pixel(px, py, Color(0.32, 0.56, 0.34, 1.0))
					elif a_deg >= -125.0 and a_deg < -80.0:
						img.set_pixel(px, py, Color(0.82, 0.24, 0.16, 1.0))
		for step in range(0, 17):
			var frac := float(step) / 16.0
			var ang := deg_to_rad(lerpf(-125.0, 125.0, frac))
			var major := step % 2 == 0
			var r_in := rad - (15.0 if major else 10.0)
			var r_out := rad - 4.0
			var tcol := Color(0.95, 0.93, 0.84, 1.0) if major else Color(0.76, 0.74, 0.68, 1.0)
			var thick := 2 if major else 1
			for s in range(16):
				var rr := lerpf(r_in, r_out, float(s) / 15.0)
				var gx := int(round(cx + sin(ang) * rr))
				var gy := int(round(cy - cos(ang) * rr))
				for ox in range(-thick / 2, thick / 2 + 1):
					for oy in range(-thick / 2, thick / 2 + 1):
						if gx + ox >= 0 and gx + ox < sz and gy + oy >= 0 and gy + oy < sz:
							img.set_pixel(gx + ox, gy + oy, tcol)
		_draw_tiny_word(img, "HEBRO", 54, 92, Color(0.92, 0.90, 0.80, 1.0))
	var tex := ImageTexture.create_from_image(img)
	_hebro_dial_tex[mode] = tex
	return tex

## Iconic open-cockpit Súper Hebro 555 dashboard: weathered painted oval pod, chromed speedometer & oil-pressure
## ("HEBRO") dials, blue pilot lamp, hand-throttle lever, large 3-spoke Bakelite wheel with tractor spinner knob
## & gripping player hands, plus live exhaust pipe rain-cap ("sombrerete") dancing with diesel throttle!
func _build_hebro_dash(eye_x: float, eye_y: float, eye_z: float) -> void:
	if _hebro_chrome == null:
		_hebro_chrome = StandardMaterial3D.new()
		_hebro_chrome.albedo_color = Color(0.86, 0.88, 0.90)
		_hebro_chrome.metallic = 0.86
		_hebro_chrome.roughness = 0.20
		_hebro_rust = StandardMaterial3D.new()
		_hebro_rust.albedo_color = Color(0.42, 0.25, 0.14)
		_hebro_rust.metallic = 0.25
		_hebro_rust.roughness = 0.88
	_dash_max_kmh = 50.0
	_dash_root = Node3D.new()
	_dash_root.name = "HebroDashboard"
	_dash_base_pos = Vector3(eye_x, eye_y - 0.34, eye_z + 0.56)
	_dash_root.position = _dash_base_pos
	inner.add_child(_dash_root)

	var m_pod := StandardMaterial3D.new()
	m_pod.albedo_texture = _build_hebro_pod_tex(paint)
	m_pod.roughness = 0.72
	m_pod.metallic = 0.15
	var m_paint := Parts.mat(paint)
	var m_dark := Parts.mat(0x1f2126)       # glossy-matte black Bakelite wheel & knobs
	var m_steel := Parts.mat(0x3a3e44)      # steering column & exhaust steel

	# 1) Sturdy painted lower steering column pedestal connecting cleanly down into the tractor chassis/hood
	_dash_root.add_child(_ros_part("cyl", m_paint, Vector3(0.0, -0.32, 0.07), Vector3(0.082, 0.62, 0.082)))
	_dash_root.add_child(_ros_part("cyl", _hebro_rust, Vector3(0.0, -0.05, 0.06), Vector3(0.088, 0.028, 0.088)))

	# 2) Iconic curved weathered Ebro metal instrument pod ("capilla") tilted UP (+34 deg around +X) toward the driver's eyes!
	var pod := Node3D.new()
	pod.name = "HebroPod"
	pod.position = Vector3(0.0, 0.022, 0.042)
	pod.rotation.x = deg_to_rad(34.0)
	_dash_root.add_child(pod)
	# Rounded domed metal body cleanly behind the faceplate (front belly stops at z=+0.004 so dials never clip!)
	pod.add_child(_ros_part("ball", m_pod, Vector3(0.0, 0.0, 0.072), Vector3(0.184, 0.104, 0.068)))
	var face_plate := _ros_part("cyl", m_pod, Vector3(0.0, 0.0, 0.002), Vector3(0.178, 0.012, 0.098))
	face_plate.rotation.x = PI / 2.0
	pod.add_child(face_plate)
	# Central weathered steering-column collar ring right in the middle of the pod (Photo 1)
	var boss := _ros_part("cyl", _hebro_rust, Vector3(0.0, 0.006, -0.005), Vector3(0.036, 0.014, 0.036))
	boss.rotation.x = PI / 2.0
	pod.add_child(boss)
	var boss_in := _ros_part("cyl", m_dark, Vector3(0.0, 0.006, -0.008), Vector3(0.024, 0.012, 0.024))
	boss_in.rotation.x = PI / 2.0
	pod.add_child(boss_in)
	# Iconic glowing cobalt-blue central pilot lamp right below the steering shaft (Photo 1)
	var lamp_ring := _ros_part("cyl", m_dark, Vector3(0.0, -0.056, -0.006), Vector3(0.016, 0.010, 0.016))
	lamp_ring.rotation.x = PI / 2.0
	pod.add_child(lamp_ring)
	_dash_lamp_mat = StandardMaterial3D.new()
	_dash_lamp_mat.albedo_color = Color(0.12, 0.32, 0.82)
	_dash_lamp_mat.emission_enabled = true
	_dash_lamp_mat.emission = Color(0.18, 0.50, 1.0)
	_dash_lamp_mat.emission_energy_multiplier = 0.15
	pod.add_child(_ros_part("ball", _dash_lamp_mat, Vector3(0.0, -0.056, -0.011), Vector3(0.011, 0.011, 0.007)))

	# 3) Two round chromed vintage dials: LEFT = Speedometer (0-50 km/h), RIGHT = Oil Pressure ("HEBRO")
	if _hebro_bezel_mesh == null:
		_hebro_bezel_mesh = TorusMesh.new()
		_hebro_bezel_mesh.inner_radius = 0.044
		_hebro_bezel_mesh.outer_radius = 0.053
		_hebro_bezel_mesh.rings = 24
		_hebro_bezel_mesh.ring_segments = 8
	for side_i in range(2):
		var is_speed := side_i == 0
		var gx: float = 0.098 if is_speed else -0.098
		var gy := 0.008
		# Chromed outer bezel ring
		var bez := MeshInstance3D.new()
		bez.mesh = _hebro_bezel_mesh
		bez.material_override = _hebro_chrome
		bez.position = Vector3(gx, gy, -0.010)
		bez.rotation.x = PI / 2.0
		bez.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pod.add_child(bez)
		# Vintage circular dial plate
		var dmat := StandardMaterial3D.new()
		var dtex := _build_hebro_dial_tex("speed" if is_speed else "oil")
		dmat.albedo_texture = dtex
		dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		dmat.alpha_scissor_threshold = 0.5
		dmat.roughness = 0.40
		dmat.emission_enabled = true
		dmat.emission_texture = dtex
		dmat.emission_energy_multiplier = 0.22
		if is_speed:
			_dash_dial_mat = dmat
		var qm := QuadMesh.new()
		qm.size = Vector2(0.094, 0.094)
		var dquad := MeshInstance3D.new()
		dquad.mesh = qm
		dquad.material_override = dmat
		dquad.position = Vector3(gx, gy, -0.009)
		dquad.rotation.y = PI
		dquad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pod.add_child(dquad)
		# Live 3D needle
		var npiv := Node3D.new()
		npiv.name = "SpeedoNeedle" if is_speed else "OilNeedle"
		npiv.position = Vector3(gx, gy, -0.013)
		pod.add_child(npiv)
		var nmat := StandardMaterial3D.new()
		nmat.albedo_color = Color(0.98, 0.34, 0.14) if is_speed else Color(0.94, 0.92, 0.84)
		nmat.emission_enabled = true
		nmat.emission = nmat.albedo_color
		nmat.emission_energy_multiplier = 0.35
		npiv.add_child(_ros_part("box", nmat, Vector3(0.0, 0.016, 0.0), Vector3(0.0036, 0.034, 0.0025)))
		var nhub := _ros_part("cyl", _hebro_chrome, Vector3(0.0, 0.0, -0.001), Vector3(0.006, 0.004, 0.006))
		nhub.rotation.x = PI / 2.0
		npiv.add_child(nhub)
		if is_speed:
			_dash_needle = npiv
			_dash_speed_ang = deg_to_rad(-125.0)
			_dash_needle.rotation.z = _dash_speed_ang
		else:
			_hebro_oil_needle = npiv
			_hebro_oil_ang = deg_to_rad(-125.0)
			_hebro_oil_needle.rotation.z = _hebro_oil_ang

	# 4) Classic right-side hand-throttle lever ("acelerador de mano") moving with engine throttle!
	_hebro_throttle_piv = Node3D.new()
	_hebro_throttle_piv.name = "HandThrottle"
	_hebro_throttle_piv.position = Vector3(-0.025, 0.035, 0.005)
	_dash_root.add_child(_hebro_throttle_piv)
	var trod := _ros_part("cyl", _hebro_chrome, Vector3(-0.088, 0.006, -0.008), Vector3(0.0045, 0.175, 0.0045))
	trod.rotation.z = PI / 2.0 + 0.08
	_hebro_throttle_piv.add_child(trod)
	_hebro_throttle_piv.add_child(_ros_part("ball", m_dark, Vector3(-0.178, 0.014, -0.010), Vector3(0.014, 0.011, 0.011)))

	# 5) Classic wide thin 3-spoke black Bakelite Ebro steering wheel + tractor spinner knob + player hands!
	# +46 deg around +X tilts the wheel face UP toward the driver's eyes and sends the +Z shaft straight down into the pod center!
	var col_mount := Node3D.new()
	col_mount.position = Vector3(0.0, 0.104, -0.042)
	col_mount.rotation.x = deg_to_rad(46.0)
	_dash_root.add_child(col_mount)
	# Steering shaft going straight down through the rusty center ring of the weathered pod
	var shaft := _ros_part("cyl", m_steel, Vector3(0.0, 0.0, 0.068), Vector3(0.016, 0.136, 0.016))
	shaft.rotation.x = PI / 2.0
	col_mount.add_child(shaft)

	_dash_wheel = Node3D.new()
	_dash_wheel.name = "HebroWheel"
	col_mount.add_child(_dash_wheel)
	if _hebro_rim_mesh == null:
		_hebro_rim_mesh = TorusMesh.new()
		_hebro_rim_mesh.inner_radius = 0.173
		_hebro_rim_mesh.outer_radius = 0.186
		_hebro_rim_mesh.rings = 32
		_hebro_rim_mesh.ring_segments = 10
	var rim := MeshInstance3D.new()
	rim.mesh = _hebro_rim_mesh
	rim.material_override = m_dark
	rim.rotation.x = PI / 2.0
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_dash_wheel.add_child(rim)
	# Central weathered metal hub + nut (Photo 2)
	var hub := _ros_part("cyl", m_dark, Vector3(0.0, 0.0, 0.002), Vector3(0.028, 0.022, 0.028))
	hub.rotation.x = PI / 2.0
	_dash_wheel.add_child(hub)
	var nut := _ros_part("cyl", _hebro_rust, Vector3(0.0, 0.0, -0.012), Vector3(0.015, 0.012, 0.015))
	nut.rotation.x = PI / 2.0
	_dash_wheel.add_child(nut)
	# 3 classic thin spokes at 12, 4 and 8 o'clock (leaving 10 & 2 wide open over the two round dials!)
	for sang_deg: float in [0.0, 120.0, -120.0]:
		var sa := deg_to_rad(sang_deg)
		var sp := _ros_part("cyl", m_dark, Vector3(-sin(sa) * 0.090, cos(sa) * 0.090, 0.004), Vector3(0.0065, 0.176, 0.0065))
		sp.rotation.z = sa
		_dash_wheel.add_child(sp)
	# Classic tractor spinner knob ("bola de tractor") clamped on the rim at ~8:30 o'clock (+108 deg)
	var knob_ang := deg_to_rad(108.0)
	var knob_pos := Vector3(0.179 * sin(knob_ang), 0.179 * cos(knob_ang), -0.012)
	var clamp_k := _ros_part("cyl", _hebro_chrome, knob_pos + Vector3(0.0, 0.0, 0.008), Vector3(0.011, 0.016, 0.011))
	clamp_k.rotation.x = PI / 2.0
	_dash_wheel.add_child(clamp_k)
	_dash_wheel.add_child(_ros_part("ball", m_dark, knob_pos + Vector3(0.0, 0.0, -0.014), Vector3(0.018, 0.018, 0.016)))

	# Driver's hands gripping the rim at 9:30 and 2:30 (wide enough that both dials stay 100% clear!)
	var skin_hex: int = int(riders[0].get("skin", 0xf6c9a0))
	var m_skin := Parts.mat(skin_hex)
	var grip_r := 0.179
	var grip_ang := deg_to_rad(68.0)
	for sgn: float in [1.0, -1.0]:
		var hand := Node3D.new()
		hand.name = "WheelHandL" if sgn > 0.0 else "WheelHandR"
		hand.position = Vector3(sgn * grip_r * sin(grip_ang), grip_r * cos(grip_ang), -0.007)
		hand.rotation.z = sgn * grip_ang
		hand.add_child(_ros_part("ball", m_skin, Vector3.ZERO, Vector3(0.026, 0.035, 0.024)))
		var thumb := _ros_part("ball", m_skin, Vector3(-0.012 * sgn, 0.027, -0.007), Vector3(0.011, 0.017, 0.011))
		thumb.rotation.z = sgn * 0.25
		hand.add_child(thumb)
		_dash_wheel.add_child(hand)

	# 6) Hinged iron exhaust rain-cap ("sombrerete") on top of the vertical diesel pipe, dancing with throttle!
	var pipe_pos: Vector3 = _pipe_at if (_pipe_at is Vector3) else Vector3(-0.468, 2.444, 0.759)
	_hebro_flap_root = Node3D.new()
	_hebro_flap_root.name = "ExhaustRainCap"
	_hebro_flap_root.position = pipe_pos
	inner.add_child(_hebro_flap_root)
	_hebro_flap_root.add_child(_ros_part("cyl", m_steel, Vector3(0.0, -0.014, 0.0), Vector3(0.022, 0.028, 0.022)))
	_hebro_flap_root.add_child(_ros_part("box", _hebro_rust, Vector3(0.0, 0.004, -0.032), Vector3(0.014, 0.018, 0.018)))
	_hebro_flap_piv = Node3D.new()
	_hebro_flap_piv.name = "ExhaustFlapPivot"
	_hebro_flap_piv.position = Vector3(0.0, 0.010, -0.032)
	_hebro_flap_root.add_child(_hebro_flap_piv)
	_hebro_flap_piv.add_child(_ros_part("cyl", m_steel, Vector3(0.0, 0.002, 0.032), Vector3(0.036, 0.006, 0.036)))
	_hebro_flap_piv.add_child(_ros_part("box", _hebro_rust, Vector3(0.0, 0.003, -0.014), Vector3(0.012, 0.007, 0.026)))

## Strips the Sketchfab Julietta's baked steering wheel (`alum`) and old interior dash cowl (`gummi`/`leder` in front cab)
## while the player drives so our Alfa 159-inspired cockpit never clips — keeping seats, doors, windscreen & paint intact.
func _set_julietta_cab_stripped() -> void:
	if model == null or not is_instance_valid(model):
		return
	var bmi := model.find_child("body", true, false) as MeshInstance3D
	if bmi == null or bmi.mesh == null:
		return
	_dash_body_mi = bmi
	_dash_orig_mesh = bmi.mesh
	if not _z15_cab_meshes.has(_dash_orig_mesh):
		var orig: Mesh = _dash_orig_mesh
		var xf: Transform3D = model.transform * bmi.transform
		var out := ArrayMesh.new()
		for s in range(orig.get_surface_count()):
			var a: Array = orig.surface_get_arrays(s)
			var mat = orig.surface_get_material(s)
			var nm := String(mat.resource_name) if mat != null else ""
			if nm == "alum" or nm == "gummi" or nm == "leder":
				var verts: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
				var idx := PackedInt32Array()
				if a[Mesh.ARRAY_INDEX] != null:
					idx = a[Mesh.ARRAY_INDEX]
				else:
					for k in range(verts.size()):
						idx.append(k)
				var keep := PackedInt32Array()
				if nm != "alum":
					for t in range(0, idx.size() - 2, 3):
						var mid: Vector3 = xf * ((verts[idx[t]] + verts[idx[t + 1]] + verts[idx[t + 2]]) / 3.0)
						# Keep A-pillars (|x| >= 0.56), windscreen header (y >= 1.21) & seats (z <= -0.02) untouched; strip center wiper/cowl sliver up to y < 1.21
						var is_old_dash: bool = mid.z > -0.02 and mid.z < 0.56 and mid.y > 0.74 and ((mid.y < 1.21 and absf(mid.x) < 0.54) or (mid.y < 1.14 and absf(mid.x) < 0.58))
						if not is_old_dash:
							keep.append(idx[t])
							keep.append(idx[t + 1])
							keep.append(idx[t + 2])
				if keep.is_empty():
					keep = PackedInt32Array([0, 0, 0])
				a[Mesh.ARRAY_INDEX] = keep
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
			out.surface_set_material(s, mat)
		_z15_cab_meshes[_dash_orig_mesh] = out
	bmi.mesh = _z15_cab_meshes[_dash_orig_mesh]

## Procedural 128x128 Alfa 159 TI style sporty black circular gauges ("speed", "rpm", "boost", "temp", "fuel")
static func _build_julietta_dial_tex(mode: String) -> ImageTexture:
	if _jul_dial_tex.has(mode):
		return _jul_dial_tex[mode]
	var sz := 128
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	var cx := 64.0
	var cy := 64.0
	var rad := 60.0
	var face := Color(0.05, 0.055, 0.065, 1.0)
	var ring := Color(0.76, 0.79, 0.84, 1.0)
	var inner_ring := Color(0.18, 0.20, 0.24, 1.0)
	for py in range(sz):
		for px in range(sz):
			var d := Vector2(px - cx, py - cy).length()
			if d <= rad:
				var c := ring if d > rad - 2.6 else (inner_ring if d > rad - 5.0 else face)
				img.set_pixel(px, py, c)
	var n_steps := 22 if mode == "speed" else (14 if mode == "rpm" else 10)
	var red_from := 18 if mode == "speed" else (11 if mode == "rpm" else (8 if mode == "boost" or mode == "temp" else -1))
	for step in range(0, n_steps + 1):
		var frac := float(step) / float(n_steps)
		var ang := deg_to_rad(lerpf(-130.0, 130.0, frac))
		var major := (step % 2 == 0)
		var r_in := rad - (14.5 if major else 9.0)
		var r_out := rad - 5.0
		var is_red := (red_from >= 0 and step >= red_from) or (mode == "fuel" and step <= 1)
		var tcol := Color(0.95, 0.20, 0.16, 1.0) if is_red else (Color(0.95, 0.96, 0.98, 1.0) if major else Color(0.65, 0.68, 0.74, 1.0))
		var thick := 2 if major else 1
		for s in range(18):
			var rr := lerpf(r_in, r_out, float(s) / 17.0)
			var gx := int(round(cx + sin(ang) * rr))
			var gy := int(round(cy - cos(ang) * rr))
			for ox in range(-thick / 2, thick / 2 + 1):
				for oy in range(-thick / 2, thick / 2 + 1):
					if gx + ox >= 0 and gx + ox < sz and gy + oy >= 0 and gy + oy < sz:
						img.set_pixel(gx + ox, gy + oy, tcol)
	if mode == "speed":
		_draw_tiny_word(img, "KMH", 58, 92, Color(0.86, 0.88, 0.92, 1.0))
	elif mode == "rpm":
		_draw_tiny_word(img, "RPM", 58, 92, Color(0.92, 0.26, 0.20, 1.0))
	elif mode == "boost":
		_draw_tiny_word(img, "BAR", 58, 92, Color(0.98, 0.52, 0.16, 1.0))
	var tex := ImageTexture.create_from_image(img)
	_jul_dial_tex[mode] = tex
	return tex

## Procedural 128x96 stylized dark night-mode Madridejos GPS map for the Julietta's center infotainment screen
static func _build_julietta_gps_tex() -> ImageTexture:
	if _jul_gps_tex != null:
		return _jul_gps_tex
	var w := 128
	var h := 96
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.08, 0.11, 0.16, 1.0))
	# Dark city blocks & green park patches
	for py in range(10, h - 10):
		for px in range(6, w - 6):
			var bx := (px / 14) % 2
			var by := (py / 12) % 2
			if (px % 14 > 2) and (py % 12 > 2):
				var park := (px > 82 and px < 108 and py > 18 and py < 40) or (px > 18 and px < 38 and py > 54 and py < 74)
				img.set_pixel(px, py, Color(0.11, 0.24, 0.17, 1.0) if park else (Color(0.12, 0.16, 0.22, 1.0) if (bx ^ by) == 0 else Color(0.10, 0.14, 0.20, 1.0)))
	# Major avenues & glowing cyan-red route line + roundabout
	var ave := Color(0.26, 0.34, 0.45, 1.0)
	var route := Color(0.96, 0.32, 0.24, 1.0)
	for px in range(w):
		for dy in [-1, 0, 1]:
			img.set_pixel(px, clampi(48 + dy, 0, h - 1), ave)
	for py in range(h):
		for dx in [-1, 0, 1]:
			img.set_pixel(clampi(64 + dx, 0, w - 1), py, ave)
	# Diagonal old Madrid-Cádiz road + highlighted active GPS route
	for t in range(10, 118):
		var y_r := clampi(int(20 + t * 0.52), 10, h - 10)
		img.set_pixel(t, y_r, route)
		img.set_pixel(t, clampi(y_r + 1, 0, h - 1), route)
	# Glowing roundabout circle near top-center
	for a_i in range(36):
		var a := float(a_i) * TAU / 36.0
		var rx := clampi(int(round(64.0 + cos(a) * 9.0)), 0, w - 1)
		var ry := clampi(int(round(48.0 + sin(a) * 9.0)), 0, h - 1)
		img.set_pixel(rx, ry, Color(0.32, 0.72, 0.96, 1.0))
	# Top & bottom Alfa infotainment status bars
	for px in range(w):
		for py in range(0, 9):
			img.set_pixel(px, py, Color(0.05, 0.06, 0.08, 1.0))
		for py in range(h - 9, h):
			img.set_pixel(px, py, Color(0.05, 0.06, 0.08, 1.0))
	_draw_tiny_word(img, "OMEGA", 8, 2, Color(0.95, 0.28, 0.22, 1.0))
	_jul_gps_tex = ImageTexture.create_from_image(img)
	return _jul_gps_tex

## Procedural 64x64 affectionate "Omega Julietta" roundel steering-wheel emblem (silver ring, red/green halves + white Ω)
static func _build_julietta_badge_tex() -> ImageTexture:
	if _jul_badge_tex != null:
		return _jul_badge_tex
	var sz := 64
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	var cx := 32.0
	var cy := 32.0
	for py in range(sz):
		for px in range(sz):
			var dx := float(px) - cx
			var dy := float(py) - cy
			var d := sqrt(dx * dx + dy * dy)
			if d <= 30.0:
				var c: Color
				if d > 25.0:
					c = Color(0.84, 0.87, 0.90, 1.0)          # chrome rim
				elif d > 21.0:
					c = Color(0.10, 0.14, 0.26, 1.0)          # deep navy ring
				else:
					c = Color(0.76, 0.14, 0.16, 1.0) if dx < 0.0 else Color(0.16, 0.52, 0.26, 1.0)
				# Stylized white Omega (Ω) arch in center
				if d > 8.0 and d < 13.5 and dy < 6.0:
					c = Color(0.96, 0.96, 0.94, 1.0)
				if dy >= 5.0 and dy <= 9.0 and ((dx >= -15.0 and dx <= -6.0) or (dx >= 6.0 and dx <= 15.0)):
					c = Color(0.96, 0.96, 0.94, 1.0)
				img.set_pixel(px, py, c)
	_jul_badge_tex = ImageTexture.create_from_image(img)
	return _jul_badge_tex

## Omega Julietta Alfa 159 TI / Brera-inspired cockpit ("Nero + Aluminio cepillado"):
## deep binocular speedo + tachometer, brushed-aluminum driver-oriented center console with 3 round vents,
## 3 auxiliary dials (Temp / live Turbo Boost / Fuel), Madridejos GPS screen with rotating heading arrow,
## climate controls, sporty 3-spoke aluminum/leather steering wheel with Omega emblem & gripping player hands,
## plus live functional full-FPS rearview mirror!
func _build_julietta_dash(eye_x: float, eye_y: float, eye_z: float) -> void:
	if _hebro_chrome == null:
		_hebro_chrome = StandardMaterial3D.new()
		_hebro_chrome.albedo_color = Color(0.86, 0.88, 0.90)
		_hebro_chrome.metallic = 0.86
		_hebro_chrome.roughness = 0.20
	if _jul_alu == null:
		_jul_alu = StandardMaterial3D.new()
		_jul_alu.albedo_color = Color(0.76, 0.79, 0.84)
		_jul_alu.metallic = 0.78
		_jul_alu.roughness = 0.28
	if _ros_mirror == null:
		_ros_mirror = StandardMaterial3D.new()
		_ros_mirror.albedo_color = Color(0.36, 0.40, 0.46)
		_ros_mirror.metallic = 0.42
		_ros_mirror.roughness = 0.16
	_dash_max_kmh = 220.0
	_dash_root = Node3D.new()
	_dash_root.name = "JuliettaDashboard"
	_dash_root.position = Vector3(0.0, eye_y - 0.19, eye_z + 0.535)
	inner.add_child(_dash_root)

	var m_black := Parts.mat(0x1b1d22)      # matte black Italian leather upper dash & hood
	var m_lower := Parts.mat(0x23262d)      # anthracite leather lower dash & glovebox (matches 3rd-person interior!)
	var m_dark := Parts.mat(0x121418)       # deep recesses, vents, buttons, gear boot
	var m_slat := Parts.mat(0x3a3e46)       # vent slats & trim bezels

	# 1) Sculpted black leather full-width dashboard + dark firewall backing + split brow (100% clear of binocular dials & aluminum console!)
	_dash_root.add_child(_ros_part("box", m_black, Vector3(0.0, 0.032, 0.115), Vector3(1.36, 0.044, 0.24)))
	_dash_root.add_child(_ros_part("box", m_dark, Vector3(0.0, -0.17, 0.10), Vector3(1.34, 0.38, 0.03)))
	# Far-left brow (left of binocular pod) + right passenger brow (right of aluminum center console) — never clips dials or console!
	var brow_l := _ros_part("cyl", m_black, Vector3(0.615, 0.034, -0.050), Vector3(0.020, 0.13, 0.020))
	brow_l.rotation.z = PI / 2.0
	_dash_root.add_child(brow_l)
	var brow_r := _ros_part("cyl", m_black, Vector3(-0.405, 0.034, -0.050), Vector3(0.020, 0.55, 0.020))
	brow_r.rotation.z = PI / 2.0
	_dash_root.add_child(brow_r)
	_dash_root.add_child(_ros_part("box", m_lower, Vector3(0.0, -0.068, -0.024), Vector3(1.34, 0.17, 0.052)))
	# Brushed-aluminum accent trim strip sweeping across passenger side & driver left side (flush with m_lower front at z = -0.050)
	_dash_root.add_child(_ros_part("box", _jul_alu, Vector3(-0.40, -0.015, -0.054), Vector3(0.54, 0.018, 0.010)))
	_dash_root.add_child(_ros_part("box", _jul_alu, Vector3(0.60, -0.015, -0.054), Vector3(0.14, 0.018, 0.010)))
	# Passenger glovebox recess & brushed handle
	_dash_root.add_child(_ros_part("box", m_dark, Vector3(-0.39, -0.095, -0.052), Vector3(0.42, 0.105, 0.008)))
	_dash_root.add_child(_ros_part("box", m_lower, Vector3(-0.39, -0.095, -0.054), Vector3(0.405, 0.092, 0.008)))
	_dash_root.add_child(_ros_part("box", _jul_alu, Vector3(-0.25, -0.064, -0.060), Vector3(0.052, 0.014, 0.008)))

	# Outer left & right round chromed slatted air vents
	if _jul_bezel_sm == null:
		_jul_bezel_sm = TorusMesh.new()
		_jul_bezel_sm.inner_radius = 0.025
		_jul_bezel_sm.outer_radius = 0.031
		_jul_bezel_sm.rings = 20
		_jul_bezel_sm.ring_segments = 8
	for ovx: float in [0.58, -0.57]:
		var obez := MeshInstance3D.new()
		obez.mesh = _jul_bezel_sm
		obez.material_override = _hebro_chrome
		obez.position = Vector3(ovx, 0.012, -0.056)
		obez.rotation.x = PI / 2.0
		obez.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_dash_root.add_child(obez)
		var oin := _ros_part("cyl", m_dark, Vector3(ovx, 0.012, -0.052), Vector3(0.026, 0.012, 0.026))
		oin.rotation.x = PI / 2.0
		_dash_root.add_child(oin)
		for sy: float in [-0.011, 0.0, 0.011]:
			_dash_root.add_child(_ros_part("box", m_slat, Vector3(ovx, 0.012 + sy, -0.058), Vector3(0.044, 0.0035, 0.004)))

	# 2) Signature Alfa Romeo deep "Binocular" Twin Instrument Cluster (Speedo 0-220 + Tachometer 0-7000 RPM)
	if _jul_bezel_big == null:
		_jul_bezel_big = TorusMesh.new()
		_jul_bezel_big.inner_radius = 0.050
		_jul_bezel_big.outer_radius = 0.058
		_jul_bezel_big.rings = 26
		_jul_bezel_big.ring_segments = 8
	var binn := Node3D.new()
	binn.name = "JuliettaBinnacle"
	binn.position = Vector3(eye_x, 0.068, -0.038)
	binn.rotation.x = deg_to_rad(8.0)       # tilt slightly UP toward driver's eyes
	_dash_root.add_child(binn)
	# Sculpted rounded leather cowl arching cleanly BEHIND the dials (front face at z = -0.022)
	var arch_c := _ros_part("cyl", m_black, Vector3(0.0, 0.008, 0.044), Vector3(0.165, 0.130, 0.078))
	arch_c.rotation.x = PI / 2.0
	binn.add_child(arch_c)
	binn.add_child(_ros_part("box", m_dark, Vector3(0.0, -0.002, -0.022), Vector3(0.26, 0.118, 0.014)))
	# Glowing red Alfa trip-computer LCD strip right between the two binocular tubes
	var trip_mat := StandardMaterial3D.new()
	trip_mat.albedo_color = Color(0.95, 0.22, 0.14)
	trip_mat.emission_enabled = true
	trip_mat.emission = Color(0.98, 0.24, 0.14)
	trip_mat.emission_energy_multiplier = 0.75
	binn.add_child(_ros_part("box", m_dark, Vector3(0.0, -0.004, -0.032), Vector3(0.038, 0.050, 0.006)))
	binn.add_child(_ros_part("box", trip_mat, Vector3(0.0, 0.005, -0.036), Vector3(0.028, 0.013, 0.003)))
	binn.add_child(_ros_part("box", trip_mat, Vector3(0.0, -0.013, -0.036), Vector3(0.022, 0.008, 0.003)))

	var m_needle_red := StandardMaterial3D.new()
	m_needle_red.albedo_color = Color(1.0, 0.20, 0.14)
	m_needle_red.emission_enabled = true
	m_needle_red.emission = Color(1.0, 0.22, 0.14)
	m_needle_red.emission_energy_multiplier = 0.85

	for bi in range(2):
		var is_speed := bi == 0
		var bx: float = 0.072 if is_speed else -0.072
		# Deep binocular housing behind the dial face (front face stops at z = -0.030 so dial at -0.036 is 100% clear!)
		var tube := _ros_part("cyl", m_black, Vector3(bx, 0.0, 0.002), Vector3(0.062, 0.062, 0.062))
		tube.rotation.x = PI / 2.0
		binn.add_child(tube)
		var bbez := MeshInstance3D.new()
		bbez.mesh = _jul_bezel_big
		bbez.material_override = _hebro_chrome
		bbez.position = Vector3(bx, 0.0, -0.039)
		bbez.rotation.x = PI / 2.0
		bbez.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		binn.add_child(bbez)
		var dmat := StandardMaterial3D.new()
		var dtex := _build_julietta_dial_tex("speed" if is_speed else "rpm")
		dmat.albedo_texture = dtex
		dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		dmat.alpha_scissor_threshold = 0.5
		dmat.roughness = 0.35
		dmat.emission_enabled = true
		dmat.emission_texture = dtex
		dmat.emission_energy_multiplier = 0.45
		if is_speed:
			_dash_dial_mat = dmat
		var qm := QuadMesh.new()
		qm.size = Vector2(0.104, 0.104)
		var dq := MeshInstance3D.new()
		dq.mesh = qm
		dq.material_override = dmat
		dq.position = Vector3(bx, 0.0, -0.036)
		dq.rotation.y = PI
		dq.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		binn.add_child(dq)
		# Live 3D red Alfa needle cleanly in front of the dial face
		var npiv := Node3D.new()
		npiv.name = "SpeedoNeedle" if is_speed else "RpmNeedle"
		npiv.position = Vector3(bx, 0.0, -0.041)
		binn.add_child(npiv)
		npiv.add_child(_ros_part("box", m_needle_red, Vector3(0.0, 0.020, 0.0), Vector3(0.0038, 0.042, 0.0025)))
		var nhub := _ros_part("cyl", m_dark, Vector3(0.0, 0.0, -0.001), Vector3(0.008, 0.005, 0.008))
		nhub.rotation.x = PI / 2.0
		npiv.add_child(nhub)
		if is_speed:
			_dash_needle = npiv
			_dash_speed_ang = deg_to_rad(-130.0)
			_dash_needle.rotation.z = _dash_speed_ang
		else:
			_jul_rpm_needle = npiv
			_jul_rpm_ang = deg_to_rad(-115.0)
			_jul_rpm_needle.rotation.z = _jul_rpm_ang

	# 3) Iconic Brushed-Aluminum Driver-Oriented Center Console proudly stepped forward in front of the black leather dash!
	var cons := Node3D.new()
	cons.name = "JuliettaConsole"
	cons.position = Vector3(0.03, -0.072, -0.098)
	cons.rotation = Vector3(deg_to_rad(10.0), deg_to_rad(-10.0), 0.0)
	_dash_root.add_child(cons)
	# Brushed aluminum monolithic fascia panel + black housing depth backing back into the dash
	cons.add_child(_ros_part("box", m_black, Vector3(0.0, 0.0, 0.036), Vector3(0.252, 0.352, 0.056)))
	cons.add_child(_ros_part("box", _jul_alu, Vector3(0.0, 0.0, 0.006), Vector3(0.245, 0.345, 0.016)))
	# Top row: 3 iconic round central air vents with chromed rings
	for vx: float in [0.072, 0.0, -0.072]:
		var vbez := MeshInstance3D.new()
		vbez.mesh = _jul_bezel_sm
		vbez.material_override = _hebro_chrome
		vbez.position = Vector3(vx, 0.125, -0.004)
		vbez.rotation.x = PI / 2.0
		vbez.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cons.add_child(vbez)
		var vin := _ros_part("cyl", m_dark, Vector3(vx, 0.125, -0.001), Vector3(0.025, 0.010, 0.025))
		vin.rotation.x = PI / 2.0
		cons.add_child(vin)
		for sy: float in [-0.010, 0.0, 0.010]:
			cons.add_child(_ros_part("box", m_slat, Vector3(vx, 0.125 + sy, -0.006), Vector3(0.042, 0.0032, 0.004)))
	# Second row: 3 iconic small round auxiliary gauges (LEFT Temp, CENTER LIVE Turbo Boost, RIGHT Fuel)
	var aux_modes := ["temp", "boost", "fuel"]
	for ai in range(3):
		var ax: float = (1 - ai) * 0.068
		var ay := 0.056
		var abez := MeshInstance3D.new()
		abez.mesh = _jul_bezel_sm
		abez.material_override = _hebro_chrome
		abez.position = Vector3(ax, ay, -0.004)
		abez.scale = Vector3.ONE * 0.88
		abez.rotation.x = PI / 2.0
		abez.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cons.add_child(abez)
		var amat := StandardMaterial3D.new()
		var atex := _build_julietta_dial_tex(aux_modes[ai])
		amat.albedo_texture = atex
		amat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		amat.alpha_scissor_threshold = 0.5
		amat.roughness = 0.35
		amat.emission_enabled = true
		amat.emission_texture = atex
		amat.emission_energy_multiplier = 0.40
		if ai == 1:
			_jul_boost_mat = amat
		var aqm := QuadMesh.new()
		aqm.size = Vector2(0.048, 0.048)
		var aq := MeshInstance3D.new()
		aq.mesh = aqm
		aq.material_override = amat
		aq.position = Vector3(ax, ay, -0.003)
		aq.rotation.y = PI
		aq.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cons.add_child(aq)
		var an := Node3D.new()
		an.position = Vector3(ax, ay, -0.006)
		an.add_child(_ros_part("box", m_needle_red, Vector3(0.0, 0.009, 0.0), Vector3(0.0024, 0.019, 0.002)))
		cons.add_child(an)
		if ai == 0:
			an.rotation.z = deg_to_rad(0.0)          # steady 90°C operating temp
		elif ai == 1:
			an.name = "BoostNeedle"
			_jul_boost_needle = an
			_jul_boost_ang = deg_to_rad(-130.0)
			an.rotation.z = _jul_boost_ang
		else:
			an.rotation.z = deg_to_rad(55.0)         # healthy fuel tank
	# Third row: REAL LIVE dark-mode Madridejos GPS satnav (reusing minimap.gd in a lightweight 2D SubViewport!)
	cons.add_child(_ros_part("box", m_dark, Vector3(0.0, -0.032, -0.004), Vector3(0.188, 0.106, 0.012)))
	var gmat: StandardMaterial3D = _make_live_gps(Vector2i(168, 100), 110.0)
	if gmat == null:
		gmat = StandardMaterial3D.new()
		gmat.albedo_texture = _build_julietta_gps_tex()
		gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var gqm := QuadMesh.new()
	gqm.size = Vector2(0.148, 0.088)
	var gq := MeshInstance3D.new()
	gq.mesh = gqm
	gq.material_override = gmat
	gq.position = Vector3(0.0, -0.032, -0.011)
	gq.rotation.y = PI
	gq.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cons.add_child(gq)
	# Keep a lightweight heading node (visible only in headless fallback when live 2D SubViewport is skipped)
	_jul_gps_arrow = Node3D.new()
	_jul_gps_arrow.name = "GpsHeadingArrow"
	_jul_gps_arrow.position = Vector3(0.0, -0.032, -0.013)
	_jul_gps_arrow.visible = (_gps_map == null)
	cons.add_child(_jul_gps_arrow)
	var arrow_mat := StandardMaterial3D.new()
	arrow_mat.albedo_color = Color(0.25, 0.90, 1.0)
	arrow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var cone_a := _ros_part("cone", arrow_mat, Vector3(0.0, 0.002, 0.0), Vector3(0.007, 0.015, 0.003))
	_jul_gps_arrow.add_child(cone_a)
	# Bottom row: Dual-zone climate knobs + glowing red digital readout + aluminum shifter tunnel & sporty round knob
	cons.add_child(_ros_part("box", m_dark, Vector3(0.0, -0.125, -0.004), Vector3(0.185, 0.056, 0.010)))
	cons.add_child(_ros_part("box", trip_mat, Vector3(0.0, -0.118, -0.010), Vector3(0.068, 0.014, 0.003)))
	for ckx: float in [0.068, -0.068]:
		var ck := _ros_part("cyl", m_slat, Vector3(ckx, -0.125, -0.012), Vector3(0.016, 0.012, 0.016))
		ck.rotation.x = PI / 2.0
		cons.add_child(ck)
	# Lower center tunnel + brushed aluminum gate + sporty leather/aluminum round gear knob
	_dash_root.add_child(_ros_part("box", m_black, Vector3(0.04, -0.275, -0.165), Vector3(0.22, 0.055, 0.26)))
	_dash_root.add_child(_ros_part("box", _jul_alu, Vector3(0.04, -0.244, -0.165), Vector3(0.165, 0.008, 0.21)))
	_dash_root.add_child(_ros_part("cone", m_dark, Vector3(0.04, -0.215, -0.165), Vector3(0.046, 0.065, 0.046)))
	_dash_root.add_child(_ros_part("ball", m_black, Vector3(0.04, -0.168, -0.165), Vector3(0.022, 0.024, 0.022)))
	var gcap := _ros_part("cyl", _jul_alu, Vector3(0.04, -0.146, -0.165), Vector3(0.013, 0.006, 0.013))
	_dash_root.add_child(gcap)

	# 4) Sporty 3-Spoke Leather & Brushed-Aluminum Steering Wheel + Omega Roundel Badge + Gripping Player Hands
	var col_mount := Node3D.new()
	col_mount.position = Vector3(eye_x, -0.036, -0.165)
	col_mount.rotation.x = deg_to_rad(18.0)     # tilted UP toward driver's eyes; +Z column runs cleanly into dash
	_dash_root.add_child(col_mount)
	var col_cyl := _ros_part("cyl", m_black, Vector3(0.0, 0.0, 0.080), Vector3(0.032, 0.16, 0.032))
	col_cyl.rotation.x = PI / 2.0
	col_mount.add_child(col_cyl)
	var stalk_l := _ros_part("cyl", m_dark, Vector3(0.072, 0.012, 0.040), Vector3(0.0055, 0.095, 0.0055))
	stalk_l.rotation.z = PI / 2.0 - 0.14
	col_mount.add_child(stalk_l)

	_dash_wheel = Node3D.new()
	_dash_wheel.name = "JuliettaWheel"
	col_mount.add_child(_dash_wheel)
	if _jul_rim_mesh == null:
		_jul_rim_mesh = TorusMesh.new()
		_jul_rim_mesh.inner_radius = 0.123
		_jul_rim_mesh.outer_radius = 0.143
		_jul_rim_mesh.rings = 32
		_jul_rim_mesh.ring_segments = 10
	var rim := MeshInstance3D.new()
	rim.mesh = _jul_rim_mesh
	rim.material_override = m_black
	rim.rotation.x = PI / 2.0
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_dash_wheel.add_child(rim)
	# Sculpted 3 brushed-aluminum sporty spokes (9, 3, and chunky 6 o'clock) + dark thumb switches (Photo)
	_dash_wheel.add_child(_ros_part("box", _jul_alu, Vector3(0.076, -0.008, 0.004), Vector3(0.105, 0.032, 0.016)))
	_dash_wheel.add_child(_ros_part("box", _jul_alu, Vector3(-0.076, -0.008, 0.004), Vector3(0.105, 0.032, 0.016)))
	_dash_wheel.add_child(_ros_part("box", _jul_alu, Vector3(0.0, -0.076, 0.004), Vector3(0.036, 0.112, 0.016)))
	for sbx: float in [0.078, -0.078]:
		var swb := _ros_part("cyl", m_dark, Vector3(sbx, -0.006, -0.006), Vector3(0.012, 0.008, 0.012))
		swb.rotation.x = PI / 2.0
		_dash_wheel.add_child(swb)
	# Round black leather airbag hub + custom Omega Julietta roundel emblem
	var hub := _ros_part("cyl", m_black, Vector3(0.0, -0.006, -0.004), Vector3(0.048, 0.022, 0.048))
	hub.rotation.x = PI / 2.0
	_dash_wheel.add_child(hub)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_texture = _build_julietta_badge_tex()
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	bmat.alpha_scissor_threshold = 0.5
	bmat.roughness = 0.25
	bmat.metallic = 0.35
	var bqm := QuadMesh.new()
	bqm.size = Vector2(0.036, 0.036)
	var bq := MeshInstance3D.new()
	bq.mesh = bqm
	bq.material_override = bmat
	bq.position = Vector3(0.0, -0.006, -0.016)
	bq.rotation.y = PI
	bq.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_dash_wheel.add_child(bq)
	# Driver's hands gripping the rim at 9:30 and 2:30 (keeping both binocular dials 100% unobstructed!)
	var skin_hex: int = int(riders[0].get("skin", 0xf6c9a0))
	var m_skin := Parts.mat(skin_hex)
	var grip_r := 0.133
	var grip_ang := deg_to_rad(64.0)
	for sgn: float in [1.0, -1.0]:
		var hand := Node3D.new()
		hand.name = "WheelHandL" if sgn > 0.0 else "WheelHandR"
		hand.position = Vector3(sgn * grip_r * sin(grip_ang), grip_r * cos(grip_ang), -0.007)
		hand.rotation.z = sgn * grip_ang
		hand.add_child(_ros_part("ball", m_skin, Vector3.ZERO, Vector3(0.024, 0.032, 0.022)))
		var thumb := _ros_part("ball", m_skin, Vector3(-0.011 * sgn, 0.025, -0.007), Vector3(0.010, 0.016, 0.010))
		thumb.rotation.z = sgn * 0.25
		hand.add_child(thumb)
		_dash_wheel.add_child(hand)

	# 5) Sleek Low-Profile Functional Live Rearview Mirror mounted under the raked windscreen header (full game FPS in 1st-person)
	_rosary_root = Node3D.new()
	_rosary_root.name = "JuliettaMirror"
	_rosary_root.position = Vector3(0.07, eye_y + 0.082, eye_z + 0.42)
	inner.add_child(_rosary_root)
	var mstalk := _ros_part("cyl", m_dark, Vector3(0.0, 0.028, 0.012), Vector3(0.007, 0.052, 0.007))
	mstalk.rotation.x = -0.30
	_rosary_root.add_child(mstalk)
	_rosary_root.add_child(_ros_part("box", m_dark, Vector3(0.0, 0.0, 0.0), Vector3(0.186, 0.044, 0.018)))
	var jglass: StandardMaterial3D = _ros_mirror
	if DisplayServer.get_name() != "headless":
		_mirror_vp = SubViewport.new()
		_mirror_vp.name = "MirrorViewport"
		_mirror_vp.size = Vector2i(192, 48)
		_mirror_vp.world_3d = get_world_3d()
		_mirror_vp.positional_shadow_atlas_size = 0
		_mirror_vp.msaa_3d = Viewport.MSAA_DISABLED
		_mirror_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		_mirror_vp.use_debanding = false
		_mirror_vp.transparent_bg = false
		_mirror_vp.audio_listener_enable_2d = false
		_mirror_vp.audio_listener_enable_3d = false
		_mirror_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if _fp_hide_head else SubViewport.UPDATE_DISABLED
		_rosary_root.add_child(_mirror_vp)
		_mirror_cam = Camera3D.new()
		_mirror_cam.name = "MirrorCamera"
		_mirror_cam.fov = 26.0
		_mirror_cam.near = 0.2
		_mirror_cam.far = 90.0
		_mirror_cam.current = true
		_mirror_vp.add_child(_mirror_cam)
		_mirror_anchor = RemoteTransform3D.new()
		_mirror_anchor.name = "MirrorCamAnchor"
		_mirror_anchor.position = Vector3(0.0, 1.34, -0.85)
		_mirror_anchor.rotation.x = deg_to_rad(-3.0)
		_mirror_anchor.update_scale = false
		inner.add_child(_mirror_anchor)
		_mirror_anchor.remote_path = _mirror_cam.get_path()
		_mirror_anchor.force_update_cache()
		jglass = StandardMaterial3D.new()
		jglass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		jglass.albedo_texture = _mirror_vp.get_texture()
		jglass.albedo_color = Color(0.92, 0.96, 1.0)
		jglass.uv1_scale = Vector3(-1.0, 1.0, 1.0)
		jglass.uv1_offset = Vector3(1.0, 0.0, 0.0)
		jglass.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	var jmq := MeshInstance3D.new()
	var jqm := QuadMesh.new()
	jqm.size = Vector2(0.172, 0.036)
	jmq.mesh = jqm
	jmq.material_override = jglass
	jmq.position = Vector3(0.0, 0.0, -0.010)
	jmq.rotation.y = PI
	jmq.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rosary_root.add_child(jmq)

	# 6) Functional Live Left Wing Mirror ("retrovisor lateral izquierdo") flush inside the red teardrop housing!
	if DisplayServer.get_name() != "headless":
		if _oval_mirror_shader == null:
			_oval_mirror_shader = Shader.new()
			_oval_mirror_shader.code = """
shader_type spatial;
render_mode unshaded;
uniform sampler2D mirror_tex : source_color, filter_linear;
void fragment() {
	vec2 d = (UV - vec2(0.5)) * 2.0;
	if (dot(d, d) > 1.0) { discard; }
	vec3 col = texture(mirror_tex, vec2(1.0 - UV.x, UV.y)).rgb;
	ALBEDO = col * vec3(0.92, 0.96, 1.0);
}
"""
		_side_mirror_vp = SubViewport.new()
		_side_mirror_vp.name = "SideMirrorViewport"
		_side_mirror_vp.size = Vector2i(96, 80)
		_side_mirror_vp.world_3d = get_world_3d()
		_side_mirror_vp.positional_shadow_atlas_size = 0
		_side_mirror_vp.msaa_3d = Viewport.MSAA_DISABLED
		_side_mirror_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		_side_mirror_vp.use_debanding = false
		_side_mirror_vp.transparent_bg = false
		_side_mirror_vp.audio_listener_enable_2d = false
		_side_mirror_vp.audio_listener_enable_3d = false
		_side_mirror_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if _fp_hide_head else SubViewport.UPDATE_DISABLED
		_rosary_root.add_child(_side_mirror_vp)
		_side_mirror_cam = Camera3D.new()
		_side_mirror_cam.name = "SideMirrorCamera"
		_side_mirror_cam.fov = 38.0
		_side_mirror_cam.near = 0.2
		_side_mirror_cam.far = 90.0
		_side_mirror_cam.current = true
		_side_mirror_vp.add_child(_side_mirror_cam)
		_side_mirror_anchor = RemoteTransform3D.new()
		_side_mirror_anchor.name = "SideMirrorCamAnchor"
		_side_mirror_anchor.position = Vector3(0.84, 1.12, 0.04)
		_side_mirror_anchor.rotation = Vector3(deg_to_rad(-3.0), deg_to_rad(-8.0), 0.0)
		_side_mirror_anchor.update_scale = false
		inner.add_child(_side_mirror_anchor)
		_side_mirror_anchor.remote_path = _side_mirror_cam.get_path()
		_side_mirror_anchor.force_update_cache()
		var smat := ShaderMaterial.new()
		smat.shader = _oval_mirror_shader
		smat.set_shader_parameter("mirror_tex", _side_mirror_vp.get_texture())
		var smq := MeshInstance3D.new()
		smq.name = "LeftSideMirrorGlass"
		var sqm := QuadMesh.new()
		sqm.size = Vector2(0.106, 0.094)
		smq.mesh = sqm
		smq.material_override = smat
		# Exact inner-space coordinates of sk/julietta.glb left wing mirror glass (chrom_0), 6mm proud toward driver
		smq.position = _dash_root.to_local(inner.to_global(Vector3(0.749, 1.121, 0.176)))
		smq.rotation.y = PI + deg_to_rad(9.5)
		smq.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_dash_root.add_child(smq)

## Procedural 256x128 iconic boxy SEAT/Seta Panda instrument cluster (0-160 km/h square-cut dial, 06725 odometer, 0-4/4 fuel & warning grid)
static func _build_panda_dial_tex() -> ImageTexture:
	if _panda_dial_tex != null:
		return _panda_dial_tex
	var w := 256
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.08, 0.09, 0.10, 1.0))
	# Crisp dark bezel border
	var bcol := Color(0.22, 0.24, 0.26, 1.0)
	for x in range(w):
		for dy in range(4):
			img.set_pixel(x, dy, bcol)
			img.set_pixel(x, h - 1 - dy, bcol)
	for y in range(h):
		for dx in range(4):
			img.set_pixel(dx, y, bcol)
			img.set_pixel(w - 1 - dx, y, bcol)
	# Classic SEAT Panda left-side quarter/arc speedometer (0..160 km/h) centered at (cx=82, cy=88)
	var cx := 82.0
	var cy := 88.0
	var rad := 62.0
	for step in range(0, 17):
		var frac := float(step) / 16.0
		var ang := deg_to_rad(lerpf(-120.0, 48.0, frac))
		var major := step % 2 == 0
		var r_in := rad - (12.0 if major else 7.0)
		var r_out := rad - 2.0
		var tcol := Color(0.92, 0.28, 0.18, 1.0) if step >= 14 else (Color(0.94, 0.96, 0.94, 1.0) if major else Color(0.68, 0.72, 0.72, 1.0))
		var thick := 2 if major else 1
		for s in range(16):
			var rr := lerpf(r_in, r_out, float(s) / 15.0)
			var gx := int(round(cx + sin(ang) * rr))
			var gy := int(round(cy - cos(ang) * rr))
			for ox in range(-thick / 2, thick / 2 + 1):
				for oy in range(-thick / 2, thick / 2 + 1):
					if gx + ox >= 6 and gx + ox < w - 6 and gy + oy >= 6 and gy + oy < h - 6:
						img.set_pixel(gx + ox, gy + oy, tcol)
	# Classic 5-digit odometer ("06725") inside the speedometer face
	for py in range(56, 67):
		for px in range(62, 108):
			img.set_pixel(px, py, Color(0.20, 0.22, 0.24, 1.0) if (py == 56 or py == 66 or px == 62 or px == 107) else Color(0.14, 0.16, 0.18, 1.0))
	for di in range(5):
		var dx0 := 65 + di * 8
		for py in range(59, 64):
			img.set_pixel(dx0 + 2, py, Color(0.90, 0.92, 0.88, 1.0))
			if (di + py) % 2 == 0:
				img.set_pixel(dx0 + 4, py, Color(0.90, 0.92, 0.88, 1.0))
	# Upper-middle mini 0 - 4/4 fuel gauge
	for px in range(134, 186):
		img.set_pixel(px, 34, Color(0.75, 0.78, 0.76, 1.0))
	for k in range(5):
		var tx := 138 + k * 11
		var fc := Color(0.92, 0.26, 0.16, 1.0) if k == 0 else Color(0.92, 0.94, 0.90, 1.0)
		for py in range(24, 34):
			img.set_pixel(tx, py, fc)
			img.set_pixel(tx + 1, py, fc)
	# Fuel needle pointing at 3/4
	for s in range(12):
		img.set_pixel(160 + s / 2, 34 - s, Color(0.96, 0.96, 0.92, 1.0))
	# Classic SEAT Panda right-hand grid of square warning lights (3x3 boxes)
	var icons := [
		Color(0.88, 0.48, 0.14, 1.0), Color(0.85, 0.18, 0.16, 1.0), Color(0.88, 0.18, 0.16, 1.0),
		Color(0.22, 0.68, 0.30, 1.0), Color(0.18, 0.45, 0.88, 1.0), Color(0.88, 0.22, 0.16, 1.0),
		Color(0.90, 0.64, 0.14, 1.0), Color(0.24, 0.58, 0.28, 1.0), Color(0.78, 0.58, 0.16, 1.0),
	]
	for gy in range(3):
		for gx in range(3):
			var ix0 := 192 + gx * 19
			var iy0 := 22 + gy * 28
			var ic: Color = icons[gy * 3 + gx]
			for py in range(iy0, iy0 + 22):
				for px in range(ix0, ix0 + 16):
					var edge := py == iy0 or py == iy0 + 21 or px == ix0 or px == ix0 + 15
					var core := py >= iy0 + 6 and py <= iy0 + 15 and px >= ix0 + 4 and px <= ix0 + 11
					img.set_pixel(px, py, Color(0.24, 0.26, 0.28, 1.0) if edge else (ic if core else Color(0.10, 0.12, 0.13, 1.0)))
	_panda_dial_tex = ImageTexture.create_from_image(img)
	return _panda_dial_tex

## Procedural 96x32 rectangular silver "S E T A" steering-wheel horn badge (affectionate wink at the classic SEAT Panda badge)
static func _build_panda_badge_tex() -> ImageTexture:
	if _panda_badge_tex != null:
		return _panda_badge_tex
	var w := 96
	var h := 32
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.82, 0.85, 0.88, 1.0))
	var dark := Color(0.14, 0.16, 0.19, 1.0)
	for x in range(w):
		for dy in range(3):
			img.set_pixel(x, dy, dark)
			img.set_pixel(x, h - 1 - dy, dark)
	for y in range(h):
		for dx in range(3):
			img.set_pixel(dx, y, dark)
			img.set_pixel(w - 1 - dx, y, dark)
	# Scaled-up 3x3 chunky pixels for "S E T A"
	const GLYPHS := {
		"S": ["111", "100", "111", "001", "111"],
		"E": ["111", "100", "110", "100", "111"],
		"T": ["111", "010", "010", "010", "010"],
		"A": ["010", "101", "111", "101", "101"],
	}
	var word := "SETA"
	for wi in range(4):
		var rows: Array = GLYPHS[word.substr(wi, 1)]
		var bx := 12 + wi * 20
		for ry in range(5):
			for rx in range(3):
				if rows[ry].substr(rx, 1) == "1":
					for sy in range(3):
						for sx in range(3):
							img.set_pixel(bx + rx * 3 + sx, 8 + ry * 3 + sy, dark)
	_panda_badge_tex = ImageTexture.create_from_image(img)
	return _panda_badge_tex

## Builds one of 3 charming dashboard bobbleheads (0 = bulldog, 1 = pato, 2 = rana) with spring-mounted big head in `_bobble_piv`
func _build_panda_bobblehead(variant: int) -> Node3D:
	var root := Node3D.new()
	root.name = "PandaBobblehead"
	# Adhesive black round base + tiny coil spring
	root.add_child(_ros_part("cyl", Parts.mat(0x1b1d22), Vector3(0.0, 0.004, 0.0), Vector3(0.028, 0.008, 0.028)))
	var m_eye := Parts.mat(0x141518)
	var m_white := Parts.mat(0xf4f4f0)
	var head_piv := Node3D.new()
	head_piv.name = "BobbleHeadPivot"
	if variant == 0:
		# 0) BULLDOG: chunky tan sitting body, red collar, huge wrinkly bulldog head with jowls, dark muzzle & floppy ears!
		var m_tan := Parts.mat(0xc99c6b)
		var m_dark := Parts.mat(0x4a3426)
		var m_red := Parts.mat(0xc82824)
		root.add_child(_ros_part("ball", m_tan, Vector3(0.0, 0.026, 0.0), Vector3(0.022, 0.022, 0.020)))
		root.add_child(_ros_part("cyl", m_red, Vector3(0.0, 0.044, 0.0), Vector3(0.017, 0.007, 0.017)))
		head_piv.position = Vector3(0.0, 0.049, 0.0)
		root.add_child(head_piv)
		head_piv.add_child(_ros_part("ball", m_tan, Vector3(0.0, 0.024, 0.0), Vector3(0.032, 0.028, 0.030)))
		# Droopy bulldog jowls + dark flat snout + cute white underbite fangs (facing -z toward driver!)
		head_piv.add_child(_ros_part("ball", m_tan, Vector3(0.016, 0.015, -0.022), Vector3(0.014, 0.013, 0.014)))
		head_piv.add_child(_ros_part("ball", m_tan, Vector3(-0.016, 0.015, -0.022), Vector3(0.014, 0.013, 0.014)))
		head_piv.add_child(_ros_part("ball", m_dark, Vector3(0.0, 0.020, -0.028), Vector3(0.014, 0.010, 0.010)))
		head_piv.add_child(_ros_part("box", m_white, Vector3(0.008, 0.011, -0.032), Vector3(0.004, 0.006, 0.004)))
		head_piv.add_child(_ros_part("box", m_white, Vector3(-0.008, 0.011, -0.032), Vector3(0.004, 0.006, 0.004)))
		# Floppy dark brown ears + big glossy eyes
		for sx: float in [1.0, -1.0]:
			var ear := _ros_part("ball", m_dark, Vector3(sx * 0.029, 0.032, -0.004), Vector3(0.010, 0.016, 0.012))
			ear.rotation.z = sx * 0.35
			head_piv.add_child(ear)
			head_piv.add_child(_ros_part("ball", m_eye, Vector3(sx * 0.012, 0.030, -0.026), Vector3(0.0055, 0.0055, 0.0055)))
	elif variant == 1:
		# 1) PATO: bright yellow rubber-duck body with side wings, huge yellow head & flat orange bill!
		var m_yel := Parts.mat(0xf5cf27)
		var m_org := Parts.mat(0xec6d1c)
		root.add_child(_ros_part("ball", m_yel, Vector3(0.0, 0.024, 0.003), Vector3(0.023, 0.019, 0.027)))
		for sx: float in [1.0, -1.0]:
			root.add_child(_ros_part("ball", m_yel, Vector3(sx * 0.022, 0.024, 0.004), Vector3(0.007, 0.011, 0.016)))
		head_piv.position = Vector3(0.0, 0.044, -0.003)
		root.add_child(head_piv)
		head_piv.add_child(_ros_part("ball", m_yel, Vector3(0.0, 0.026, 0.0), Vector3(0.031, 0.029, 0.030)))
		# Classic flat orange duck bill + glossy eyes
		head_piv.add_child(_ros_part("ball", m_org, Vector3(0.0, 0.021, -0.031), Vector3(0.016, 0.0075, 0.015)))
		for sx: float in [1.0, -1.0]:
			head_piv.add_child(_ros_part("ball", m_eye, Vector3(sx * 0.013, 0.032, -0.025), Vector3(0.0055, 0.0055, 0.0055)))
	else:
		# 2) RANA: bright green plump frog body, huge round green head with two big protruding top eyes & rosy cheeks!
		var m_grn := Parts.mat(0x47b546)
		var m_bel := Parts.mat(0xc8e89a)
		var m_pnk := Parts.mat(0xf28c9c)
		root.add_child(_ros_part("ball", m_grn, Vector3(0.0, 0.023, 0.0), Vector3(0.022, 0.020, 0.020)))
		root.add_child(_ros_part("ball", m_bel, Vector3(0.0, 0.022, -0.012), Vector3(0.014, 0.014, 0.010)))
		head_piv.position = Vector3(0.0, 0.044, 0.0)
		root.add_child(head_piv)
		head_piv.add_child(_ros_part("ball", m_grn, Vector3(0.0, 0.022, 0.0), Vector3(0.034, 0.024, 0.028)))
		# Two iconic protruding cartoon frog eyes on top + rosy cheeks + wide smile
		for sx: float in [1.0, -1.0]:
			head_piv.add_child(_ros_part("ball", m_grn, Vector3(sx * 0.017, 0.043, -0.006), Vector3(0.012, 0.012, 0.011)))
			head_piv.add_child(_ros_part("ball", m_white, Vector3(sx * 0.017, 0.043, -0.014), Vector3(0.0085, 0.0085, 0.006)))
			head_piv.add_child(_ros_part("ball", m_eye, Vector3(sx * 0.017, 0.043, -0.019), Vector3(0.0048, 0.0048, 0.0035)))
			head_piv.add_child(_ros_part("ball", m_pnk, Vector3(sx * 0.022, 0.018, -0.022), Vector3(0.0065, 0.0045, 0.004)))
		head_piv.add_child(_ros_part("box", m_eye, Vector3(0.0, 0.015, -0.027), Vector3(0.022, 0.003, 0.003)))
	_bobble_piv = head_piv
	return root

## Tiny 80s audio cassette prop (tossed on the Seta Panda passenger seat / hammock shelf)
static func _build_panda_cassette(shell_hex: int, label_hex: int, stripe_hex: int) -> Node3D:
	var c := Node3D.new()
	c.add_child(_ros_part("box", Parts.mat(shell_hex), Vector3.ZERO, Vector3(0.100, 0.012, 0.064)))
	c.add_child(_ros_part("box", Parts.mat(label_hex), Vector3(0.0, 0.0068, -0.003), Vector3(0.088, 0.0015, 0.044)))
	c.add_child(_ros_part("box", Parts.mat(stripe_hex), Vector3(0.0, 0.0078, -0.016), Vector3(0.086, 0.0012, 0.010)))
	c.add_child(_ros_part("box", Parts.mat(0x181a1e), Vector3(0.0, 0.0080, 0.002), Vector3(0.044, 0.0012, 0.016)))
	for sx: float in [-0.017, 0.017]:
		c.add_child(_ros_part("cyl", Parts.mat(0xe6e6e0), Vector3(sx, 0.0082, 0.002), Vector3(0.0065, 0.002, 0.0065)))
	return c

## Iconic 80s Seta Panda (and Seta Panda de los Pitufos) interior: open hammock shelf ("bolsa") with sliding ashtray
## & painted body-metal backing, boxy Panda gauge pod (0-160 km/h speedo, 6 rocker switches, heater sliders & vent),
## chunky 2-spoke "S E T A" wheel + player hands, 80s corner speakers, live central & left wing mirrors,
## plus on normal Pandas: dashboard bobblehead (bulldog / pato / rana), tossed 80s cassettes & 25% Spanish mirror ribbon;
## and on Pitufos: local police VHF radio with coiled mic & glowing blue siren switch!
func _build_panda_dash(eye_x: float, eye_y: float, eye_z: float) -> void:
	if _hebro_chrome == null:
		_hebro_chrome = StandardMaterial3D.new()
		_hebro_chrome.albedo_color = Color(0.86, 0.88, 0.90)
		_hebro_chrome.metallic = 0.86
		_hebro_chrome.roughness = 0.20
	if _ros_silver == null:
		_ros_silver = StandardMaterial3D.new()
		_ros_silver.albedo_color = Color(0.84, 0.86, 0.90)
		_ros_silver.metallic = 0.86
		_ros_silver.roughness = 0.22
	if _ros_mirror == null:
		_ros_mirror = StandardMaterial3D.new()
		_ros_mirror.albedo_color = Color(0.36, 0.40, 0.46)
		_ros_mirror.metallic = 0.42
		_ros_mirror.roughness = 0.16
	# Deterministic per-car bobblehead (bulldog / pato / rana) & 25% Spanish ribbon roll (kept across re-entries!)
	if _panda_seed < 0:
		_panda_seed = randi() & 0x7fffffff
	_panda_bobble = _panda_seed % 3
	_panda_lazo = (kind == "panda") and ((_panda_seed % 4) == 0)

	_dash_max_kmh = 160.0
	_dash_root = Node3D.new()
	_dash_root.name = "PandaDashboard"
	_dash_root.position = Vector3(0.0, eye_y - 0.21, eye_z + 0.44)
	inner.add_child(_dash_root)

	var m_paint := Parts.mat(paint)          # body-colored painted sheet metal visible behind the Panda pod (Photos 1 & 2!)
	var m_dark := Parts.mat(0x1f2226)        # boxy Panda dark-charcoal plastic pod & rail
	var m_hammock := Parts.mat(0x2a2e34)     # dark fabric hammock shelf ("la bolsa")
	var m_slat := Parts.mat(0x40454d)        # switches, louvers, ashtray trim
	var m_wheel := Parts.mat(0x2d3036)       # chunky 2-spoke steering wheel
	var m_btn := Parts.mat(0xdce0e4)         # tiny white switch markings

	# 1) Full-width body-painted metal backing + upper dark strip (kept cleanly behind the dial pod!) + iconic open hammock shelf & padded lower rail
	_dash_root.add_child(_ros_part("box", m_dark, Vector3(0.0, 0.044, 0.140), Vector3(1.36, 0.026, 0.16)))
	_dash_root.add_child(_ros_part("box", m_paint, Vector3(0.0, -0.020, 0.065), Vector3(1.34, 0.120, 0.036)))
	_dash_root.add_child(_ros_part("box", m_dark, Vector3(0.0, -0.175, 0.095), Vector3(1.34, 0.36, 0.03)))
	# Padded dark tubular lower rail running door-to-door + recessed open fabric hammock pouch
	var rail := _ros_part("cyl", m_dark, Vector3(0.0, -0.112, -0.068), Vector3(0.022, 1.34, 0.022))
	rail.rotation.z = PI / 2.0
	_dash_root.add_child(rail)
	_dash_root.add_child(_ros_part("box", m_hammock, Vector3(0.0, -0.122, -0.008), Vector3(1.32, 0.016, 0.135)))
	# Iconic sliding boxy Panda ashtray clipped onto the tubular lower rail!
	_dash_root.add_child(_ros_part("box", m_dark, Vector3(0.11, -0.106, -0.082), Vector3(0.095, 0.056, 0.048)))
	_dash_root.add_child(_ros_part("box", m_slat, Vector3(0.11, -0.086, -0.106), Vector3(0.075, 0.010, 0.006)))

	# 2) Two classic 80s square corner speaker boxes in the ends of the hammock shelf (Photo 2!)
	for spx: float in [0.57, -0.57]:
		var sp := Node3D.new()
		sp.position = Vector3(spx, -0.056, -0.026)
		sp.rotation.y = deg_to_rad(-14.0 if spx > 0.0 else 14.0)
		_dash_root.add_child(sp)
		sp.add_child(_ros_part("box", m_dark, Vector3(0.0, 0.0, 0.014), Vector3(0.104, 0.104, 0.042)))
		sp.add_child(_ros_part("box", _hebro_chrome, Vector3(0.0, 0.0, -0.008), Vector3(0.096, 0.096, 0.006)))
		var gr := _ros_part("cyl", m_dark, Vector3(0.0, 0.0, -0.012), Vector3(0.036, 0.006, 0.036))
		gr.rotation.x = PI / 2.0
		sp.add_child(gr)
		var gc := _ros_part("cyl", m_slat, Vector3(0.0, 0.0, -0.015), Vector3(0.016, 0.005, 0.016))
		gc.rotation.x = PI / 2.0
		sp.add_child(gc)

	# 3) Iconic boxy SEAT/Seta Panda Instrument Pod: recessed 0-160 speedo + 6 rocker switches + 3 heater sliders + vertical vent (Photo 1!)
	var pod := Node3D.new()
	pod.name = "PandaBinnacle"
	pod.position = Vector3(eye_x - 0.082, 0.048, -0.018)
	_dash_root.add_child(pod)
	# Outer boxy shroud (width 0.43: left half centered at eye_x = +0.082, right half = switches + sliders + vent)
	pod.add_child(_ros_part("box", m_dark, Vector3(0.0, 0.068, 0.010), Vector3(0.44, 0.018, 0.140)))
	pod.add_child(_ros_part("box", m_dark, Vector3(0.0, -0.064, 0.010), Vector3(0.44, 0.016, 0.140)))
	pod.add_child(_ros_part("box", m_dark, Vector3(0.214, 0.002, 0.010), Vector3(0.018, 0.142, 0.140)))
	pod.add_child(_ros_part("box", m_dark, Vector3(-0.214, 0.002, 0.010), Vector3(0.018, 0.142, 0.140)))
	pod.add_child(_ros_part("box", m_dark, Vector3(0.0, 0.002, 0.068), Vector3(0.42, 0.132, 0.016)))
	# Center vertical divider wall between dial bay and rocker-switch bay
	pod.add_child(_ros_part("box", m_dark, Vector3(-0.022, 0.002, 0.012), Vector3(0.016, 0.128, 0.120)))

	# Left bay: recessed square-cut speedometer & warning grid (centered at x = +0.092 inside pod -> right behind wheel!)
	var dial_h := Node3D.new()
	dial_h.position = Vector3(0.094, 0.002, 0.012)
	dial_h.rotation.x = deg_to_rad(8.0)       # tilted slightly UP toward driver's eyes
	pod.add_child(dial_h)
	_dash_dial_mat = StandardMaterial3D.new()
	_dash_dial_mat.albedo_texture = _build_panda_dial_tex()
	_dash_dial_mat.roughness = 0.45
	_dash_dial_mat.emission_enabled = true
	_dash_dial_mat.emission_texture = _build_panda_dial_tex()
	_dash_dial_mat.emission_energy_multiplier = 0.35
	var dqm := QuadMesh.new()
	dqm.size = Vector2(0.210, 0.105)
	var dquad := MeshInstance3D.new()
	dquad.mesh = dqm
	dquad.material_override = _dash_dial_mat
	dquad.rotation.y = PI
	dquad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dial_h.add_child(dquad)
	# Live green headlamp indicator LED
	_dash_lamp_mat = StandardMaterial3D.new()
	_dash_lamp_mat.albedo_color = Color(0.14, 0.45, 0.20)
	_dash_lamp_mat.emission_enabled = true
	_dash_lamp_mat.emission = Color(0.24, 0.96, 0.36)
	_dash_lamp_mat.emission_energy_multiplier = 0.0
	dial_h.add_child(_ros_part("box", _dash_lamp_mat, Vector3(-0.056, 0.002, -0.003), Vector3(0.012, 0.014, 0.003)))
	# Live 3D white Panda speedometer needle (aligned to cx=82/256, cy=88/128 on the dial texture!)
	_dash_needle = Node3D.new()
	_dash_needle.name = "SpeedoNeedle"
	_dash_needle.position = Vector3(0.038, -0.020, -0.004)
	dial_h.add_child(_dash_needle)
	var nmat := StandardMaterial3D.new()
	nmat.albedo_color = Color(0.96, 0.96, 0.92)
	nmat.emission_enabled = true
	nmat.emission = Color(0.96, 0.96, 0.92)
	nmat.emission_energy_multiplier = 0.55
	_dash_needle.add_child(_ros_part("box", nmat, Vector3(0.0, 0.022, 0.0), Vector3(0.0038, 0.044, 0.0025)))
	var nhub := _ros_part("cyl", m_dark, Vector3(0.0, 0.0, -0.001), Vector3(0.007, 0.005, 0.007))
	nhub.rotation.x = PI / 2.0
	_dash_needle.add_child(nhub)
	_dash_speed_ang = deg_to_rad(-120.0)
	_dash_needle.rotation.z = _dash_speed_ang

	# Right bay: 6 chunky rectangular rocker switches (2x3) + 3 vertical heater sliders + vertical air vent (Photo 1!)
	pod.add_child(_ros_part("box", m_slat, Vector3(-0.118, 0.002, 0.002), Vector3(0.175, 0.118, 0.014)))
	for row_i in range(2):
		for col_i in range(3):
			var sx: float = -0.048 - col_i * 0.030
			var sy: float = 0.026 - row_i * 0.050
			pod.add_child(_ros_part("box", m_dark, Vector3(sx, sy, -0.008), Vector3(0.022, 0.036, 0.012)))
			pod.add_child(_ros_part("box", m_btn, Vector3(sx, sy + 0.002, -0.015), Vector3(0.008, 0.008, 0.002)))
	# 3 vertical heater slider tracks & knobs
	for si in range(3):
		var slx: float = -0.136 - si * 0.014
		pod.add_child(_ros_part("box", m_dark, Vector3(slx, 0.002, -0.006), Vector3(0.005, 0.088, 0.006)))
		var knob_y := -0.024 + si * 0.018
		pod.add_child(_ros_part("box", m_dark, Vector3(slx, knob_y, -0.012), Vector3(0.010, 0.010, 0.012)))
	# Vertical slatted vent on far-right edge of pod
	pod.add_child(_ros_part("box", m_dark, Vector3(-0.186, 0.002, -0.004), Vector3(0.032, 0.095, 0.010)))
	for vy: float in [-0.032, -0.016, 0.0, 0.016, 0.032]:
		pod.add_child(_ros_part("box", m_slat, Vector3(-0.186, vy, -0.010), Vector3(0.028, 0.004, 0.004)))

	# 4) Tall skinny Panda floor gear stick with round black knob
	var stick := _ros_part("cyl", m_dark, Vector3(0.04, -0.25, -0.14), Vector3(0.007, 0.22, 0.007))
	stick.rotation.x = -0.14
	_dash_root.add_child(stick)
	_dash_root.add_child(_ros_part("ball", m_wheel, Vector3(0.04, -0.14, -0.155), Vector3(0.022, 0.024, 0.022)))

	# 5) Classic chunky 2-spoke SEAT/Seta Panda steering wheel with "S E T A" badge + player hands!
	var col_mount := Node3D.new()
	col_mount.position = Vector3(eye_x, -0.030, -0.142)
	col_mount.rotation.x = deg_to_rad(18.0)     # tilted UP toward driver's eyes
	_dash_root.add_child(col_mount)
	var col_cyl := _ros_part("cyl", m_dark, Vector3(0.0, 0.0, 0.072), Vector3(0.028, 0.145, 0.028))
	col_cyl.rotation.x = PI / 2.0
	col_mount.add_child(col_cyl)
	var stalk_l := _ros_part("cyl", m_dark, Vector3(0.068, 0.010, 0.038), Vector3(0.0055, 0.092, 0.0055))
	stalk_l.rotation.z = PI / 2.0 - 0.14
	col_mount.add_child(stalk_l)
	var stalk_r := _ros_part("cyl", m_dark, Vector3(-0.068, 0.010, 0.038), Vector3(0.0055, 0.088, 0.0055))
	stalk_r.rotation.z = -(PI / 2.0 - 0.14)
	col_mount.add_child(stalk_r)

	_dash_wheel = Node3D.new()
	_dash_wheel.name = "PandaWheel"
	col_mount.add_child(_dash_wheel)
	if _dash_rim_mesh == null:
		_dash_rim_mesh = TorusMesh.new()
		_dash_rim_mesh.inner_radius = 0.126
		_dash_rim_mesh.outer_radius = 0.144
		_dash_rim_mesh.rings = 28
		_dash_rim_mesh.ring_segments = 10
	var rim := MeshInstance3D.new()
	rim.mesh = _dash_rim_mesh
	rim.material_override = m_wheel
	rim.rotation.x = PI / 2.0
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_dash_wheel.add_child(rim)
	# Iconic chunky 2-spoke slightly angled downward crossbar + big square horn pad (Photo 1!)
	for sgn: float in [1.0, -1.0]:
		var spoke := _ros_part("box", m_wheel, Vector3(sgn * 0.078, -0.022, 0.003), Vector3(0.112, 0.038, 0.018))
		spoke.rotation.z = sgn * deg_to_rad(14.0)
		_dash_wheel.add_child(spoke)
	_dash_wheel.add_child(_ros_part("box", m_wheel, Vector3(0.0, -0.006, -0.006), Vector3(0.094, 0.072, 0.022)))
	# Silver rectangular "S E T A" horn badge (Photo 1!)
	var pbm := StandardMaterial3D.new()
	pbm.albedo_texture = _build_panda_badge_tex()
	pbm.roughness = 0.30
	pbm.metallic = 0.45
	var pbq := QuadMesh.new()
	pbq.size = Vector2(0.056, 0.019)
	var pbi := MeshInstance3D.new()
	pbi.mesh = pbq
	pbi.material_override = pbm
	pbi.position = Vector3(0.0, 0.012, -0.018)
	pbi.rotation.y = PI
	pbi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_dash_wheel.add_child(pbi)

	# Driver's hands gripping the rim at 10 and 2 (rotating solidly with the steering wheel!)
	var skin_hex: int = int(riders[0].get("skin", 0xf6c9a0))
	var m_skin := Parts.mat(skin_hex)
	var grip_r := 0.135
	var grip_ang := deg_to_rad(56.0)
	for sgn: float in [1.0, -1.0]:
		var hand := Node3D.new()
		hand.name = "WheelHandL" if sgn > 0.0 else "WheelHandR"
		hand.position = Vector3(sgn * grip_r * sin(grip_ang), grip_r * cos(grip_ang), -0.006)
		hand.rotation.z = sgn * grip_ang
		hand.add_child(_ros_part("ball", m_skin, Vector3.ZERO, Vector3(0.025, 0.033, 0.023)))
		var thumb := _ros_part("ball", m_skin, Vector3(-0.012 * sgn, 0.026, -0.007), Vector3(0.011, 0.017, 0.011))
		thumb.rotation.z = sgn * 0.25
		hand.add_child(thumb)
		_dash_wheel.add_child(hand)

	# 6) Variant-specific interior character:
	if kind == "panda":
		# 6a) Dashboard Bobblehead ("monigote cabezón": bulldog / pato / rana) perched on the right end of the Panda pod!
		var bh := _build_panda_bobblehead(_panda_bobble)
		bh.position = Vector3(0.125, 0.125, -0.012)
		bh.rotation.y = deg_to_rad(-14.0)     # angled slightly toward the driver
		_dash_root.add_child(bh)
		# 6b) Tossed 80s cassettes: one resting in the passenger hammock shelf + two tossed on the passenger seat cushion!
		var cas0 := _build_panda_cassette(0x202226, 0xf2e4c4, 0xe86420)
		cas0.position = Vector3(-0.34, -0.106, -0.012)
		cas0.rotation = Vector3(deg_to_rad(6.0), deg_to_rad(22.0), 0.0)
		_dash_root.add_child(cas0)
		var cas1 := _build_panda_cassette(0xebe6d6, 0xd8322a, 0x2658b4)
		cas1.position = Vector3(-0.36, -0.29, -0.34)
		cas1.rotation = Vector3(deg_to_rad(-4.0), deg_to_rad(-35.0), 0.0)
		_dash_root.add_child(cas1)
		var cas2 := _build_panda_cassette(0x1f2228, 0xe8b824, 0x26262b)
		cas2.position = Vector3(-0.27, -0.285, -0.24)
		cas2.rotation = Vector3(deg_to_rad(3.0), deg_to_rad(52.0), 0.0)
		_dash_root.add_child(cas2)
	else:
		# 6c) Seta Panda de los Pitufos: Local Police VHF radio + handheld mic + glowing blue siren switch in the shelf!
		var rad_box := Node3D.new()
		rad_box.name = "PitufoRadio"
		rad_box.position = Vector3(-0.26, -0.088, -0.030)
		rad_box.rotation.y = deg_to_rad(-12.0)
		_dash_root.add_child(rad_box)
		rad_box.add_child(_ros_part("box", m_dark, Vector3.ZERO, Vector3(0.195, 0.068, 0.110)))
		var lcd_m := StandardMaterial3D.new()
		lcd_m.albedo_color = Color(0.16, 0.85, 0.36)
		lcd_m.emission_enabled = true
		lcd_m.emission = Color(0.20, 0.95, 0.42)
		lcd_m.emission_energy_multiplier = 0.85
		rad_box.add_child(_ros_part("box", lcd_m, Vector3(0.032, 0.010, -0.056), Vector3(0.072, 0.020, 0.004)))
		for rkx: float in [-0.035, -0.068]:
			var rk := _ros_part("cyl", m_slat, Vector3(rkx, 0.0, -0.058), Vector3(0.011, 0.010, 0.011))
			rk.rotation.x = PI / 2.0
			rad_box.add_child(rk)
		# Handheld speaker-mic clipped on the radio's right side + glowing blue siren switch
		rad_box.add_child(_ros_part("box", m_wheel, Vector3(-0.118, 0.008, -0.025), Vector3(0.038, 0.068, 0.028)))
		rad_box.add_child(_ros_part("box", m_slat, Vector3(-0.118, 0.016, -0.040), Vector3(0.026, 0.024, 0.004)))
		_pitufo_siren_mat = StandardMaterial3D.new()
		_pitufo_siren_mat.albedo_color = Color(0.14, 0.44, 0.96)
		_pitufo_siren_mat.emission_enabled = true
		_pitufo_siren_mat.emission = Color(0.20, 0.56, 1.0)
		_pitufo_siren_mat.emission_energy_multiplier = 0.7
		rad_box.add_child(_ros_part("box", _pitufo_siren_mat, Vector3(0.078, -0.012, -0.058), Vector3(0.024, 0.020, 0.008)))

	# 7) Live Functional Central Rearview Mirror (+ 25% chance Spanish Ribbon "lazo de España" swinging below!)
	_rosary_root = Node3D.new()
	_rosary_root.name = "PandaMirror"
	_rosary_root.position = Vector3(0.11, eye_y + 0.145, eye_z + 0.36)
	inner.add_child(_rosary_root)
	var mstalk := _ros_part("cyl", m_dark, Vector3(0.0, 0.030, 0.012), Vector3(0.007, 0.060, 0.007))
	mstalk.rotation.x = -0.30
	_rosary_root.add_child(mstalk)
	_rosary_root.add_child(_ros_part("box", m_dark, Vector3(0.0, 0.0, 0.0), Vector3(0.184, 0.048, 0.018)))
	var pglass: StandardMaterial3D = _ros_mirror
	if DisplayServer.get_name() != "headless":
		_mirror_vp = SubViewport.new()
		_mirror_vp.name = "MirrorViewport"
		_mirror_vp.size = Vector2i(192, 48)
		_mirror_vp.world_3d = get_world_3d()
		_mirror_vp.positional_shadow_atlas_size = 0
		_mirror_vp.msaa_3d = Viewport.MSAA_DISABLED
		_mirror_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		_mirror_vp.use_debanding = false
		_mirror_vp.transparent_bg = false
		_mirror_vp.audio_listener_enable_2d = false
		_mirror_vp.audio_listener_enable_3d = false
		_mirror_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if _fp_hide_head else SubViewport.UPDATE_DISABLED
		_rosary_root.add_child(_mirror_vp)
		_mirror_cam = Camera3D.new()
		_mirror_cam.name = "MirrorCamera"
		_mirror_cam.fov = 26.0
		_mirror_cam.near = 0.2
		_mirror_cam.far = 90.0
		_mirror_cam.current = true
		_mirror_vp.add_child(_mirror_cam)
		_mirror_anchor = RemoteTransform3D.new()
		_mirror_anchor.name = "MirrorCamAnchor"
		_mirror_anchor.position = Vector3(0.0, 1.24, -1.82)
		_mirror_anchor.rotation.x = deg_to_rad(-3.0)
		_mirror_anchor.update_scale = false
		inner.add_child(_mirror_anchor)
		_mirror_anchor.remote_path = _mirror_cam.get_path()
		_mirror_anchor.force_update_cache()
		pglass = StandardMaterial3D.new()
		pglass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		pglass.albedo_texture = _mirror_vp.get_texture()
		pglass.albedo_color = Color(0.92, 0.96, 1.0)
		pglass.uv1_scale = Vector3(-1.0, 1.0, 1.0)
		pglass.uv1_offset = Vector3(1.0, 0.0, 0.0)
		pglass.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	var pmq := MeshInstance3D.new()
	var pqm := QuadMesh.new()
	pqm.size = Vector2(0.170, 0.040)
	pmq.mesh = pqm
	pmq.material_override = pglass
	pmq.position = Vector3(0.0, 0.0, -0.010)
	pmq.rotation.y = PI
	pmq.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rosary_root.add_child(pmq)

	# 25% chance on normal Seta Panda: classic Spanish flag ribbon ("lazo de España") pinched with silver bead (Photo 3!)
	if _panda_lazo:
		var m_red := Parts.mat(0xc81d25)
		var m_yel := Parts.mat(0xf2c21a)
		_rosary_piv = Node3D.new()
		_rosary_piv.name = "SpanishRibbonPivot"
		_rosary_piv.position = Vector3(0.0, -0.020, 0.010)
		_rosary_root.add_child(_rosary_piv)
		# Upper ribbon loop (3 vertical stripes red-yellow-red) gently curving down to the silver pinch bead
		var segs := [
			Vector3(0.0, -0.015, 0.0), Vector3(0.0, -0.042, 0.002),
			Vector3(0.0, -0.068, 0.001), Vector3(0.0, -0.090, 0.0),
		]
		var wids := [0.015, 0.020, 0.018, 0.010]
		for si in range(segs.size()):
			var w_tot: float = wids[si]
			var sp: Vector3 = segs[si]
			_rosary_piv.add_child(_ros_part("box", m_yel, sp, Vector3(w_tot * 0.48, 0.029, 0.0030)))
			_rosary_piv.add_child(_ros_part("box", m_red, sp + Vector3(w_tot * 0.38, 0.0, 0.0), Vector3(w_tot * 0.28, 0.029, 0.0030)))
			_rosary_piv.add_child(_ros_part("box", m_red, sp + Vector3(-w_tot * 0.38, 0.0, 0.0), Vector3(w_tot * 0.28, 0.029, 0.0030)))
		# Shiny silver pinch ring/bead at the waist
		_rosary_piv.add_child(_ros_part("ball", _ros_silver, Vector3(0.0, -0.103, 0.0), Vector3(0.0075, 0.0055, 0.0065)))
		# Secondary swinging lower flared ribbon tail (red-yellow-red)
		_rosary_drop = Node3D.new()
		_rosary_drop.name = "SpanishRibbonTail"
		_rosary_drop.position = Vector3(0.0, -0.106, 0.0)
		_rosary_piv.add_child(_rosary_drop)
		var t_segs := [Vector3(0.0, -0.015, 0.0), Vector3(0.0, -0.038, 0.001), Vector3(0.0, -0.056, 0.0)]
		var t_wids := [0.014, 0.020, 0.010]
		for ti in range(t_segs.size()):
			var tw: float = t_wids[ti]
			var tp: Vector3 = t_segs[ti]
			_rosary_drop.add_child(_ros_part("box", m_yel, tp, Vector3(tw * 0.48, 0.025, 0.0028)))
			_rosary_drop.add_child(_ros_part("box", m_red, tp + Vector3(tw * 0.38, 0.0, 0.0), Vector3(tw * 0.28, 0.025, 0.0028)))
			_rosary_drop.add_child(_ros_part("box", m_red, tp + Vector3(-tw * 0.38, 0.0, 0.0), Vector3(tw * 0.28, 0.025, 0.0028)))

	# 1 horizontal Spanish ITV sticker tucked in the upper-right windscreen corner of the Seta Panda!
	var panda_itv := _make_itv_sticker(0x34a842 if (_panda_seed % 3) == 0 else (0xe8d028 if (_panda_seed % 3) == 1 else 0xd62824))
	panda_itv.name = "ItvSticker0"
	panda_itv.position = Vector3(-0.46, 0.045, 0.065)
	panda_itv.rotation = Vector3(deg_to_rad(18.0), PI, deg_to_rad(1.2))
	_rosary_root.add_child(panda_itv)

	# 8) Live Functional Left Square Wing Mirror flush inside sk/panda.glb's left mirror housing (full game FPS in 1st-person)
	if DisplayServer.get_name() != "headless":
		_side_mirror_vp = SubViewport.new()
		_side_mirror_vp.name = "SideMirrorViewport"
		_side_mirror_vp.size = Vector2i(96, 72)
		_side_mirror_vp.world_3d = get_world_3d()
		_side_mirror_vp.positional_shadow_atlas_size = 0
		_side_mirror_vp.msaa_3d = Viewport.MSAA_DISABLED
		_side_mirror_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		_side_mirror_vp.use_debanding = false
		_side_mirror_vp.transparent_bg = false
		_side_mirror_vp.audio_listener_enable_2d = false
		_side_mirror_vp.audio_listener_enable_3d = false
		_side_mirror_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if _fp_hide_head else SubViewport.UPDATE_DISABLED
		_rosary_root.add_child(_side_mirror_vp)
		_side_mirror_cam = Camera3D.new()
		_side_mirror_cam.name = "SideMirrorCamera"
		_side_mirror_cam.fov = 38.0
		_side_mirror_cam.near = 0.2
		_side_mirror_cam.far = 90.0
		_side_mirror_cam.current = true
		_side_mirror_vp.add_child(_side_mirror_cam)
		_side_mirror_anchor = RemoteTransform3D.new()
		_side_mirror_anchor.name = "SideMirrorCamAnchor"
		_side_mirror_anchor.position = Vector3(0.88, 1.06, 0.40)
		_side_mirror_anchor.rotation = Vector3(deg_to_rad(-3.0), deg_to_rad(-8.0), 0.0)
		_side_mirror_anchor.update_scale = false
		inner.add_child(_side_mirror_anchor)
		_side_mirror_anchor.remote_path = _side_mirror_cam.get_path()
		_side_mirror_anchor.force_update_cache()
		var smat := StandardMaterial3D.new()
		smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smat.albedo_texture = _side_mirror_vp.get_texture()
		smat.albedo_color = Color(0.92, 0.96, 1.0)
		smat.uv1_scale = Vector3(-1.0, 1.0, 1.0)
		smat.uv1_offset = Vector3(1.0, 0.0, 0.0)
		smat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		var smq := MeshInstance3D.new()
		smq.name = "LeftSideMirrorGlass"
		var sqm := QuadMesh.new()
		sqm.size = Vector2(0.104, 0.076)
		smq.mesh = sqm
		smq.material_override = smat
		smq.position = Vector3(0.802, 1.061, 0.494) - _dash_root.position
		smq.rotation.y = PI + deg_to_rad(6.0)
		smq.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_dash_root.add_child(smq)

## Converts ONLY the opaque black windscreen and front side-door window triangles of `sk/edison.glb` into real smoky
## dark-tinted automotive glass while in 1st-person (leaving A-pillars, roofline, wing mirrors & exterior paint intact;
## restored immediately to the stock opaque black windows in 3rd-person or on exit).
func _set_edison_cab_stripped() -> void:
	if model == null or not is_instance_valid(model):
		return
	var bmi := model.find_child("body", true, false) as MeshInstance3D
	if bmi == null or bmi.mesh == null:
		return
	if _dash_orig_mesh != null and bmi.mesh != _dash_orig_mesh:
		return
	_dash_body_mi = bmi
	_dash_orig_mesh = bmi.mesh
	if _edison_glass == null:
		_edison_glass = StandardMaterial3D.new()
		_edison_glass.albedo_color = Color(0.04, 0.06, 0.09, 0.28)
		_edison_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_edison_glass.roughness = 0.08
		_edison_glass.metallic = 0.34
		_edison_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	if not _z15_cab_meshes.has(_dash_orig_mesh):
		var orig: Mesh = _dash_orig_mesh
		var xf: Transform3D = model.transform * bmi.transform
		var out := ArrayMesh.new()
		var glass_surfaces: Array = []
		for s in range(orig.get_surface_count()):
			var a: Array = orig.surface_get_arrays(s)
			var mat = orig.surface_get_material(s)
			var img: Image = null
			if mat is StandardMaterial3D and (mat as StandardMaterial3D).albedo_texture != null and a[Mesh.ARRAY_TEX_UV] != null:
				img = (mat as StandardMaterial3D).albedo_texture.get_image()
				if img.is_compressed():
					img.decompress()
				img.convert(Image.FORMAT_RGBA8)
			var verts: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			var uvs: PackedVector2Array = a[Mesh.ARRAY_TEX_UV] if a[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
			var idx := PackedInt32Array()
			if a[Mesh.ARRAY_INDEX] != null:
				idx = a[Mesh.ARRAY_INDEX]
			else:
				for k in range(verts.size()):
					idx.append(k)
			var keep := PackedInt32Array()
			var glass_idx := PackedInt32Array()
			var iw := img.get_width() if img != null else 0
			var ih := img.get_height() if img != null else 0
			for t in range(0, idx.size() - 2, 3):
				var mid: Vector3 = xf * ((verts[idx[t]] + verts[idx[t + 1]] + verts[idx[t + 2]]) / 3.0)
				var is_glass := false
				if img != null and mid.y > 1.04 and mid.y < 1.49 and mid.z > -0.25 and mid.z < 1.32:
					var front_glass: bool = absf(mid.x) < 0.72 and mid.z > 0.36
					var side_glass: bool = absf(mid.x) > 0.62 and absf(mid.x) < 0.80 and mid.z < 0.86
					if front_glass or side_glass:
						var uv: Vector2 = (uvs[idx[t]] + uvs[idx[t + 1]] + uvs[idx[t + 2]]) / 3.0
						var px: Color = img.get_pixel(clampi(int(fposmod(uv.x, 1.0) * iw), 0, iw - 1), clampi(int(fposmod(uv.y, 1.0) * ih), 0, ih - 1))
						var lum := 0.3 * px.r + 0.59 * px.g + 0.11 * px.b
						if lum < 0.24:
							is_glass = true
				if is_glass:
					glass_idx.append(idx[t])
					glass_idx.append(idx[t + 1])
					glass_idx.append(idx[t + 2])
				else:
					keep.append(idx[t])
					keep.append(idx[t + 1])
					keep.append(idx[t + 2])
			if keep.is_empty():
				keep = PackedInt32Array([0, 0, 0])
			var a_solid := a.duplicate()
			a_solid[Mesh.ARRAY_INDEX] = keep
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a_solid)
			out.surface_set_material(s, mat)
			if not glass_idx.is_empty():
				var a_glass := a.duplicate()
				a_glass[Mesh.ARRAY_INDEX] = glass_idx
				glass_surfaces.append(a_glass)
		for ga in glass_surfaces:
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, ga)
			out.surface_set_material(out.get_surface_count() - 1, _edison_glass)
		_z15_cab_meshes[_dash_orig_mesh] = out
	bmi.mesh = _z15_cab_meshes[_dash_orig_mesh]

## Lightweight 2D-only SubViewport wrapping the real `minimap.gd` in sleek dark modern satnav mode (`dark_gps = true`),
## showing real Madridejos streets, blocks, and active route line heading-up inside the car's in-dash GPS screen!
func _make_live_gps(vp_size: Vector2i, radius_m: float) -> StandardMaterial3D:
	if DisplayServer.get_name() == "headless" or _dash_root == null:
		return null
	_gps_vp = SubViewport.new()
	_gps_vp.name = "DashGpsViewport"
	_gps_vp.size = vp_size
	_gps_vp.disable_3d = true
	_gps_vp.transparent_bg = false
	_gps_vp.audio_listener_enable_2d = false
	_gps_vp.audio_listener_enable_3d = false
	_gps_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if _fp_hide_head else SubViewport.UPDATE_DISABLED
	_dash_root.add_child(_gps_vp)
	var mm: Control = preload("res://scripts/minimap.gd").new()
	mm.name = "DashGpsMinimap"
	mm.size = Vector2(vp_size)
	mm.round = true
	mm.dark_gps = true
	mm.radius = radius_m
	mm.center = p
	mm.heading = h
	mm.spin = h
	_gps_vp.add_child(mm)
	_gps_map = mm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = _gps_vp.get_texture()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	return mat

## Procedural 64x64 woven dark carbon-fiber / graphite dashboard fascia texture (Photos 1 & 2)
static func _build_edison_carbon_tex() -> ImageTexture:
	if _edison_carbon_tex != null:
		return _edison_carbon_tex
	var sz := 64
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	for py in range(sz):
		for px in range(sz):
			var d := (px + py) % 8
			var hi := (d < 4) if ((py / 4) % 2 == 0) else (d >= 4)
			var v := 0.17 if hi else 0.11
			img.set_pixel(px, py, Color(v, v + 0.008, v + 0.015, 1.0))
	_edison_carbon_tex = ImageTexture.create_from_image(img)
	return _edison_carbon_tex

## Procedural 128x32 subtle matte-embossed "E D I S O N" steering-wheel horn pad lettering (Photo 2!)
static func _build_edison_wheel_tex() -> ImageTexture:
	if _edison_wheel_tex != null:
		return _edison_wheel_tex
	var w := 128
	var h := 32
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.11, 0.12, 0.14, 1.0))
	var shadow := Color(0.05, 0.055, 0.065, 1.0)
	var hi := Color(0.24, 0.26, 0.29, 1.0)
	const GLYPHS := {
		"E": ["111", "100", "110", "100", "111"],
		"D": ["110", "101", "101", "101", "110"],
		"I": ["111", "010", "010", "010", "111"],
		"S": ["111", "100", "111", "001", "111"],
		"O": ["111", "101", "101", "101", "111"],
		"N": ["101", "111", "111", "111", "101"],
	}
	var word := "EDISON"
	for wi in range(6):
		var rows: Array = GLYPHS[word.substr(wi, 1)]
		var bx := 13 + wi * 18
		for ry in range(5):
			for rx in range(3):
				if rows[ry].substr(rx, 1) == "1":
					for sy in range(2):
						for sx in range(3):
							var px := bx + rx * 3 + sx
							var py := 10 + ry * 2 + sy
							if py + 1 < h:
								img.set_pixel(px, py + 1, shadow)
							img.set_pixel(px, py, hi)
	_edison_wheel_tex = ImageTexture.create_from_image(img)
	return _edison_wheel_tex

## Procedural 256x160 dark-mode "EDISON OS" 15" center touchscreen UI (left Autopilot view + right Madridejos map + bottom dock)
static func _build_edison_screen_tex() -> ImageTexture:
	if _edison_screen_tex != null:
		return _edison_screen_tex
	var w := 256
	var h := 160
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.075, 0.085, 0.105, 1.0))
	# Right two-thirds (x=92..252, y=6..136): sleek dark-mode Madridejos navigation map (Photo 2!)
	for py in range(6, 136):
		for px in range(92, 252):
			var blk := ((px - 92) % 18 > 2) and ((py - 6) % 15 > 2)
			var park := (px > 186 and px < 224 and py > 22 and py < 46) or (px > 110 and px < 138 and py > 92 and py < 118)
			var c := Color(0.10, 0.19, 0.14, 1.0) if (blk and park) else (Color(0.11, 0.125, 0.15, 1.0) if blk else Color(0.16, 0.18, 0.21, 1.0))
			img.set_pixel(px, py, c)
	# Bright white-grey main streets + glowing Tesla blue navigation route + roundabout
	var st := Color(0.38, 0.42, 0.48, 1.0)
	var nav := Color(0.22, 0.60, 1.0, 1.0)
	for px in range(92, 252):
		for dy in [-1, 0, 1]:
			img.set_pixel(px, 72 + dy, st)
	for py in range(6, 136):
		for dx in [-1, 0, 1]:
			img.set_pixel(172 + dx, py, st)
	for t in range(96, 246):
		var ny := clampi(int(114 - (t - 96) * 0.56), 10, 132)
		img.set_pixel(t, ny, nav)
		img.set_pixel(t, clampi(ny + 1, 0, h - 1), nav)
	for ai in range(36):
		var a := float(ai) * TAU / 36.0
		var rx := clampi(int(round(172.0 + cos(a) * 11.0)), 92, 251)
		var ry := clampi(int(round(72.0 + sin(a) * 11.0)), 6, 135)
		img.set_pixel(rx, ry, nav)
	# Left third (x=4..90): Tesla Autopilot dark panel + top green battery + perspective lane lines + mini Edison car!
	for py in range(6, 136):
		img.set_pixel(91, py, Color(0.20, 0.22, 0.26, 1.0))
	# Top-right of left panel: green battery bar ("86%")
	for py in range(12, 19):
		for px in range(56, 78):
			var edge := py == 12 or py == 18 or px == 56 or px == 77
			img.set_pixel(px, py, Color(0.60, 0.64, 0.68, 1.0) if edge else (Color(0.24, 0.86, 0.36, 1.0) if px < 74 else Color(0.12, 0.14, 0.16, 1.0)))
	# Perspective lane markings converging toward horizon (y=62..134)
	for py in range(64, 134):
		var frac := float(py - 64) / 70.0
		var lx := int(round(lerpf(36.0, 12.0, frac)))
		var rx := int(round(lerpf(56.0, 80.0, frac)))
		img.set_pixel(lx, py, Color(0.36, 0.42, 0.50, 1.0))
		img.set_pixel(rx, py, Color(0.36, 0.42, 0.50, 1.0))
	# Stylized miniature top-down white Edison Model Y car silhouette at bottom of left panel
	for py in range(98, 126):
		for px in range(37, 55):
			var wind := py >= 104 and py <= 119 and px >= 40 and px <= 51
			img.set_pixel(px, py, Color(0.12, 0.15, 0.20, 1.0) if wind else Color(0.88, 0.90, 0.94, 1.0))
	# Bottom dock (y=137..158): dark bar + classic colorful Tesla app icons (Photo 2!)
	for py in range(137, h):
		for px in range(w):
			img.set_pixel(px, py, Color(0.04, 0.045, 0.055, 1.0))
	var dock_cols := [
		Color(0.76, 0.80, 0.86, 1.0), Color(0.22, 0.82, 0.36, 1.0), Color(0.24, 0.62, 0.96, 1.0),
		Color(0.94, 0.52, 0.18, 1.0), Color(0.92, 0.22, 0.22, 1.0), Color(0.86, 0.88, 0.92, 1.0),
		Color(0.24, 0.84, 0.46, 1.0),
	]
	for di in range(dock_cols.size()):
		var ix := 18 + di * 33
		for py in range(143, 153):
			for px in range(ix, ix + 10):
				img.set_pixel(px, py, dock_cols[di])
	_edison_screen_tex = ImageTexture.create_from_image(img)
	return _edison_screen_tex

## Ultra-minimalist Tesla Model 3/Y Highland inspired cockpit for Edison Model Y:
## dark carbon/graphite horizontal dash (ZERO gauges behind wheel!), per-car random RGB wrap-around ambient LED strip
## (neon green / ice blue / cyber purple), chunky matte-black 3-spoke wheel with metallic silver U-spoke, twin scroll wheels
## & matte-embossed "EDISON" lettering + player hands, giant 15" floating dark-mode "EDISON OS" touchscreen with LIVE digital
## km/h, P-R-N-D gear, Autopilot steering ribbon, power/regen bar & Madridejos map, wireless charger + phone, twin cupholders,
## and BOTH live mirrors (central + left oval wing mirror)!
func _build_edison_dash(eye_x: float, eye_y: float, eye_z: float) -> void:
	if _hebro_chrome == null:
		_hebro_chrome = StandardMaterial3D.new()
		_hebro_chrome.albedo_color = Color(0.86, 0.88, 0.90)
		_hebro_chrome.metallic = 0.86
		_hebro_chrome.roughness = 0.20
	if _jul_alu == null:
		_jul_alu = StandardMaterial3D.new()
		_jul_alu.albedo_color = Color(0.76, 0.79, 0.84)
		_jul_alu.metallic = 0.78
		_jul_alu.roughness = 0.28
	if _ros_mirror == null:
		_ros_mirror = StandardMaterial3D.new()
		_ros_mirror.albedo_color = Color(0.36, 0.40, 0.46)
		_ros_mirror.metallic = 0.42
		_ros_mirror.roughness = 0.16
	# Deterministic per-car ambient LED strip color (0 neon green, 1 ice blue, 2 cyber purple)
	if _edison_seed < 0:
		_edison_seed = randi() & 0x7fffffff
	_edison_led = _edison_seed % 3
	const LED_COLS := [Color(0.30, 0.98, 0.36), Color(0.20, 0.74, 1.0), Color(0.76, 0.30, 1.0)]
	var led_c: Color = LED_COLS[_edison_led]

	_dash_root = Node3D.new()
	_dash_root.name = "EdisonDashboard"
	_dash_root.position = Vector3(0.0, eye_y - 0.20, eye_z + 0.50)
	inner.add_child(_dash_root)

	var m_top := Parts.mat(0x1b1d22)          # sleek matte dark slate upper dash
	var m_dark := Parts.mat(0x111317)         # deep vent slot, recesses, steering wheel rim
	var m_carbon := StandardMaterial3D.new()
	m_carbon.albedo_texture = _build_edison_carbon_tex()
	m_carbon.uv1_scale = Vector3(14.0, 2.5, 1.0)
	m_carbon.roughness = 0.42
	m_carbon.metallic = 0.28

	# 1) Minimalist full-width horizontal Highland dashboard: dark top pad, hidden HVAC slot, carbon fascia & brushed-silver lower lip!
	_dash_root.add_child(_ros_part("box", m_top, Vector3(0.0, 0.036, 0.095), Vector3(1.52, 0.028, 0.28)))
	_dash_root.add_child(_ros_part("box", m_dark, Vector3(0.0, 0.018, 0.015), Vector3(1.50, 0.014, 0.14)))      # invisible full-width air vent slot
	_dash_root.add_child(_ros_part("box", m_carbon, Vector3(0.0, -0.022, -0.024), Vector3(1.50, 0.072, 0.056))) # carbon-fiber trim bar (Photo 1 & 2!)
	_dash_root.add_child(_ros_part("box", _jul_alu, Vector3(0.0, -0.060, -0.053), Vector3(1.50, 0.008, 0.008))) # thin brushed-silver lower lip
	_dash_root.add_child(_ros_part("box", m_dark, Vector3(0.0, -0.24, 0.045), Vector3(1.52, 0.44, 0.20)))       # full lower dash & sealed footwell bulkhead
	# Sleek matte-dark interior A-pillar trim covers framing the raked windscreen cleanly (hiding Sketchfab decimation seams!)
	for sx: float in [1.0, -1.0]:
		var apil := _ros_part("box", m_top, Vector3(sx * 0.67, 0.25, -0.04), Vector3(0.085, 0.72, 0.075))
		apil.rotation = Vector3(deg_to_rad(-52.0), 0.0, sx * deg_to_rad(14.0))
		_dash_root.add_child(apil)

	# Signature wrap-around glowing RGB ambient LED light strip along the base of the windscreen (Photo 2!)
	_edison_led_mat = StandardMaterial3D.new()
	_edison_led_mat.albedo_color = led_c
	_edison_led_mat.emission_enabled = true
	_edison_led_mat.emission = led_c
	_edison_led_mat.emission_energy_multiplier = 1.4
	_dash_root.add_child(_ros_part("box", _edison_led_mat, Vector3(0.0, 0.052, 0.195), Vector3(1.50, 0.009, 0.012)))
	# Side door wrap-around extensions of the ambient LED strip
	for sx: float in [1.0, -1.0]:
		var side_led := _ros_part("box", _edison_led_mat, Vector3(sx * 0.745, 0.046, 0.010), Vector3(0.009, 0.009, 0.38))
		_dash_root.add_child(side_led)

	# 2) Giant Floating 15" Center Touchscreen ("EDISON OS", dark mode, slightly driver-angled, Photo 2!)
	var scr := Node3D.new()
	scr.name = "EdisonTouchscreen"
	scr.position = Vector3(0.02, 0.028, -0.118)
	scr.rotation = Vector3(deg_to_rad(8.0), deg_to_rad(-8.0), 0.0)
	_dash_root.add_child(scr)
	# Rear mounting neck + sleek thin metallic-silver outer bezel + glossy dark body
	scr.add_child(_ros_part("box", m_dark, Vector3(0.0, -0.025, 0.048), Vector3(0.075, 0.055, 0.090)))
	scr.add_child(_ros_part("box", _jul_alu, Vector3(0.0, 0.0, 0.005), Vector3(0.342, 0.220, 0.012)))
	scr.add_child(_ros_part("box", m_dark, Vector3(0.0, 0.0, 0.001), Vector3(0.334, 0.212, 0.010)))
	var smat := StandardMaterial3D.new()
	smat.albedo_texture = _build_edison_screen_tex()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var sqm := QuadMesh.new()
	sqm.size = Vector2(0.324, 0.202)
	var squ := MeshInstance3D.new()
	squ.mesh = sqm
	squ.material_override = smat
	squ.position = Vector3(0.0, 0.0, -0.005)
	squ.rotation.y = PI
	squ.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scr.add_child(squ)
	# LIVE digital speedometer readout ("0" .. "122") + "km/h" on top-left of the 15" tablet!
	_edison_speed_lbl = Label3D.new()
	_edison_speed_lbl.name = "EdisonSpeedLabel"
	_edison_speed_lbl.text = "0"
	_edison_speed_lbl.font_size = 44
	_edison_speed_lbl.pixel_size = 0.00075
	_edison_speed_lbl.modulate = Color(0.96, 0.98, 1.0)
	_edison_speed_lbl.outline_size = 0
	_edison_speed_lbl.shaded = false
	_edison_speed_lbl.no_depth_test = false
	_edison_speed_lbl.position = Vector3(0.115, 0.056, -0.007)
	_edison_speed_lbl.rotation.y = PI
	scr.add_child(_edison_speed_lbl)
	var unit_lbl := Label3D.new()
	unit_lbl.text = "km/h"
	unit_lbl.font_size = 16
	unit_lbl.pixel_size = 0.00055
	unit_lbl.modulate = Color(0.62, 0.66, 0.72)
	unit_lbl.outline_size = 0
	unit_lbl.shaded = false
	unit_lbl.position = Vector3(0.115, 0.032, -0.007)
	unit_lbl.rotation.y = PI
	scr.add_child(unit_lbl)
	# LIVE P-R-N-D active gear indicator
	_edison_gear_lbl = Label3D.new()
	_edison_gear_lbl.name = "EdisonGearLabel"
	_edison_gear_lbl.text = "P"
	_edison_gear_lbl.font_size = 20
	_edison_gear_lbl.pixel_size = 0.00060
	_edison_gear_lbl.modulate = Color(0.32, 0.78, 1.0)
	_edison_gear_lbl.outline_size = 0
	_edison_gear_lbl.shaded = false
	_edison_gear_lbl.position = Vector3(0.146, 0.082, -0.007)
	_edison_gear_lbl.rotation.y = PI
	scr.add_child(_edison_gear_lbl)
	# LIVE electric power / regen bar under the speedo
	_edison_pwr_mat = StandardMaterial3D.new()
	_edison_pwr_mat.albedo_color = Color(0.24, 0.88, 0.42)
	_edison_pwr_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_edison_pwr_bar = _ros_part("box", _edison_pwr_mat, Vector3(0.106, 0.020, -0.007), Vector3(0.024, 0.004, 0.002))
	scr.add_child(_edison_pwr_bar)
	# LIVE glowing blue Autopilot trajectory ribbon bending ahead of the mini car on the left pane
	_edison_lane_piv = Node3D.new()
	_edison_lane_piv.name = "AutopilotLane"
	_edison_lane_piv.position = Vector3(0.105, -0.026, -0.007)
	scr.add_child(_edison_lane_piv)
	var ap_mat := StandardMaterial3D.new()
	ap_mat.albedo_color = Color(0.22, 0.64, 1.0)
	ap_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_edison_lane_piv.add_child(_ros_part("box", ap_mat, Vector3(0.0, 0.018, 0.0), Vector3(0.007, 0.036, 0.002)))
	# REAL LIVE dark-mode Madridejos satnav covering the right two-thirds of the 15" Edison touchscreen!
	var egps_mat := _make_live_gps(Vector2i(200, 162), 125.0)
	if egps_mat != null:
		var egq := MeshInstance3D.new()
		egq.name = "EdisonLiveGpsQuad"
		var egqm := QuadMesh.new()
		egqm.size = Vector2(0.202, 0.164)
		egq.mesh = egqm
		egq.material_override = egps_mat
		egq.position = Vector3(-0.056, 0.011, -0.0068)
		egq.rotation.y = PI
		egq.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		scr.add_child(egq)
	# Headless fallback GPS heading arrow (hidden when live 2D minimap satnav is active)
	_jul_gps_arrow = Node3D.new()
	_jul_gps_arrow.name = "GpsHeadingArrow"
	_jul_gps_arrow.position = Vector3(-0.056, 0.008, -0.007)
	_jul_gps_arrow.visible = (_gps_map == null)
	scr.add_child(_jul_gps_arrow)
	_jul_gps_arrow.add_child(_ros_part("cone", ap_mat, Vector3(0.0, 0.002, 0.0), Vector3(0.008, 0.017, 0.003)))

	# 3) Minimalist Center Console: slanted wireless phone charger (+ charging smartphone!) & twin silver-rimmed cupholders (Photo 2!)
	var cpad := _ros_part("box", m_top, Vector3(0.02, -0.175, -0.140), Vector3(0.24, 0.145, 0.022))
	cpad.rotation.x = deg_to_rad(36.0)
	_dash_root.add_child(cpad)
	# Smartphone resting on the left wireless charging pad with tiny green charging indicator!
	var phone := Node3D.new()
	phone.position = Vector3(0.068, -0.162, -0.154)
	phone.rotation = Vector3(deg_to_rad(36.0), 0.0, deg_to_rad(-4.0))
	_dash_root.add_child(phone)
	phone.add_child(_ros_part("box", m_dark, Vector3.ZERO, Vector3(0.064, 0.118, 0.008)))
	var chg_m := StandardMaterial3D.new()
	chg_m.albedo_color = Color(0.22, 0.92, 0.42)
	chg_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	phone.add_child(_ros_part("box", chg_m, Vector3(0.0, 0.014, -0.005), Vector3(0.016, 0.024, 0.002)))
	# Flat lower console with brushed-silver lip + twin chrome-rimmed cupholders
	_dash_root.add_child(_ros_part("box", m_top, Vector3(0.02, -0.245, -0.285), Vector3(0.25, 0.045, 0.28)))
	_dash_root.add_child(_ros_part("box", _jul_alu, Vector3(0.02, -0.221, -0.185), Vector3(0.23, 0.006, 0.014)))
	for cup_z: float in [-0.265, -0.345]:
		var cr := _ros_part("cyl", _hebro_chrome, Vector3(0.02, -0.220, cup_z), Vector3(0.036, 0.006, 0.036))
		_dash_root.add_child(cr)
		_dash_root.add_child(_ros_part("cyl", m_dark, Vector3(0.02, -0.222, cup_z), Vector3(0.031, 0.012, 0.031)))

	# 4) Round Sporty Matte-Black Edison 3-Spoke Wheel: metallic silver U-spoke, twin scroll wheels, embossed "EDISON" & hands!
	var col_mount := Node3D.new()
	col_mount.position = Vector3(eye_x, -0.024, -0.185)
	col_mount.rotation.x = deg_to_rad(18.0)     # tilted UP toward driver's eyes
	_dash_root.add_child(col_mount)
	var col_cyl := _ros_part("cyl", m_dark, Vector3(0.0, 0.0, 0.095), Vector3(0.032, 0.19, 0.032))
	col_cyl.rotation.x = PI / 2.0
	col_mount.add_child(col_cyl)
	# Twin sleek Tesla column stalks (left turn signal, right P-R-N-D drive selector — Photo 1!)
	for sgn: float in [1.0, -1.0]:
		var stk := _ros_part("cyl", m_top, Vector3(sgn * 0.072, 0.014, 0.042), Vector3(0.007, 0.095, 0.007))
		stk.rotation.z = sgn * (PI / 2.0 - 0.14)
		col_mount.add_child(stk)

	_dash_wheel = Node3D.new()
	_dash_wheel.name = "EdisonWheel"
	col_mount.add_child(_dash_wheel)
	if _jul_rim_mesh == null:
		_jul_rim_mesh = TorusMesh.new()
		_jul_rim_mesh.inner_radius = 0.123
		_jul_rim_mesh.outer_radius = 0.143
		_jul_rim_mesh.rings = 32
		_jul_rim_mesh.ring_segments = 10
	var rim := MeshInstance3D.new()
	rim.mesh = _jul_rim_mesh
	rim.material_override = m_top
	rim.rotation.x = PI / 2.0
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_dash_wheel.add_child(rim)
	# Left & right sculpted matte-dark spokes with metallic silver top edge + spherical Tesla scroll wheels!
	for sgn: float in [1.0, -1.0]:
		_dash_wheel.add_child(_ros_part("box", m_top, Vector3(sgn * 0.082, -0.004, 0.004), Vector3(0.096, 0.034, 0.018)))
		_dash_wheel.add_child(_ros_part("box", _jul_alu, Vector3(sgn * 0.082, 0.014, 0.002), Vector3(0.092, 0.005, 0.016)))
		_dash_wheel.add_child(_ros_part("ball", m_dark, Vector3(sgn * 0.086, -0.004, -0.007), Vector3(0.010, 0.012, 0.010)))
	# Iconic metallic silver U-shaped lower spoke bezel (Photos 1 & 2!)
	_dash_wheel.add_child(_ros_part("box", _jul_alu, Vector3(0.0, -0.082, 0.004), Vector3(0.048, 0.104, 0.016)))
	_dash_wheel.add_child(_ros_part("box", m_top, Vector3(0.0, -0.072, 0.002), Vector3(0.034, 0.086, 0.018)))
	# Trapezoidal matte-black center airbag pad + chrome top highlight + matte-embossed "E D I S O N" (Photo 2!)
	_dash_wheel.add_child(_ros_part("box", m_top, Vector3(0.0, 0.002, -0.004), Vector3(0.098, 0.068, 0.022)))
	_dash_wheel.add_child(_ros_part("box", m_top, Vector3(0.0, -0.038, -0.004), Vector3(0.072, 0.028, 0.022)))
	_dash_wheel.add_child(_ros_part("box", _jul_alu, Vector3(0.0, 0.036, -0.013), Vector3(0.094, 0.004, 0.005)))
	var wmat := StandardMaterial3D.new()
	wmat.albedo_texture = _build_edison_wheel_tex()
	wmat.roughness = 0.85
	var wqm := QuadMesh.new()
	wqm.size = Vector2(0.072, 0.018)
	var wq := MeshInstance3D.new()
	wq.mesh = wqm
	wq.material_override = wmat
	wq.position = Vector3(0.0, 0.006, -0.016)
	wq.rotation.y = PI
	wq.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_dash_wheel.add_child(wq)

	# Driver's hands gripping the rim at 9:30 and 2:30 (rotating solidly with steering!)
	var skin_hex: int = int(riders[0].get("skin", 0xf6c9a0))
	var m_skin := Parts.mat(skin_hex)
	var grip_r := 0.133
	var grip_ang := deg_to_rad(64.0)
	for sgn: float in [1.0, -1.0]:
		var hand := Node3D.new()
		hand.name = "WheelHandL" if sgn > 0.0 else "WheelHandR"
		hand.position = Vector3(sgn * grip_r * sin(grip_ang), grip_r * cos(grip_ang), -0.007)
		hand.rotation.z = sgn * grip_ang
		hand.add_child(_ros_part("ball", m_skin, Vector3.ZERO, Vector3(0.024, 0.032, 0.022)))
		var thumb := _ros_part("ball", m_skin, Vector3(-0.011 * sgn, 0.025, -0.007), Vector3(0.010, 0.016, 0.010))
		thumb.rotation.z = sgn * 0.25
		hand.add_child(thumb)
		_dash_wheel.add_child(hand)

	# 5) Frameless Sleek Functional Central Rearview Mirror (full game FPS in 1st-person)
	_rosary_root = Node3D.new()
	_rosary_root.name = "EdisonMirror"
	_rosary_root.position = Vector3(0.07, eye_y + 0.140, eye_z + 0.42)
	inner.add_child(_rosary_root)
	var mstalk := _ros_part("cyl", m_dark, Vector3(0.0, 0.032, 0.014), Vector3(0.007, 0.064, 0.007))
	mstalk.rotation.x = -0.35
	_rosary_root.add_child(mstalk)
	_rosary_root.add_child(_ros_part("box", m_dark, Vector3(0.0, 0.0, 0.0), Vector3(0.184, 0.044, 0.014)))
	var eglass: StandardMaterial3D = _ros_mirror
	if DisplayServer.get_name() != "headless":
		_mirror_vp = SubViewport.new()
		_mirror_vp.name = "MirrorViewport"
		_mirror_vp.size = Vector2i(192, 48)
		_mirror_vp.world_3d = get_world_3d()
		_mirror_vp.positional_shadow_atlas_size = 0
		_mirror_vp.msaa_3d = Viewport.MSAA_DISABLED
		_mirror_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		_mirror_vp.use_debanding = false
		_mirror_vp.transparent_bg = false
		_mirror_vp.audio_listener_enable_2d = false
		_mirror_vp.audio_listener_enable_3d = false
		_mirror_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if _fp_hide_head else SubViewport.UPDATE_DISABLED
		_rosary_root.add_child(_mirror_vp)
		_mirror_cam = Camera3D.new()
		_mirror_cam.name = "MirrorCamera"
		_mirror_cam.fov = 26.0
		_mirror_cam.near = 0.2
		_mirror_cam.far = 90.0
		_mirror_cam.current = true
		_mirror_vp.add_child(_mirror_cam)
		_mirror_anchor = RemoteTransform3D.new()
		_mirror_anchor.name = "MirrorCamAnchor"
		_mirror_anchor.position = Vector3(0.0, 1.35, -2.42)
		_mirror_anchor.rotation.x = deg_to_rad(-3.0)
		_mirror_anchor.update_scale = false
		inner.add_child(_mirror_anchor)
		_mirror_anchor.remote_path = _mirror_cam.get_path()
		_mirror_anchor.force_update_cache()
		eglass = StandardMaterial3D.new()
		eglass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		eglass.albedo_texture = _mirror_vp.get_texture()
		eglass.albedo_color = Color(0.92, 0.96, 1.0)
		eglass.uv1_scale = Vector3(-1.0, 1.0, 1.0)
		eglass.uv1_offset = Vector3(1.0, 0.0, 0.0)
		eglass.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	var emq := MeshInstance3D.new()
	var eqm := QuadMesh.new()
	eqm.size = Vector2(0.174, 0.038)
	emq.mesh = eqm
	emq.material_override = eglass
	emq.position = Vector3(0.0, 0.0, -0.008)
	emq.rotation.y = PI
	emq.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rosary_root.add_child(emq)

	# 6) Live Functional Left Oval Wing Mirror flush on sk/edison.glb's left side mirror housing (full game FPS in 1st-person)
	if DisplayServer.get_name() != "headless":
		if _oval_mirror_shader == null:
			_oval_mirror_shader = Shader.new()
			_oval_mirror_shader.code = """
shader_type spatial;
render_mode unshaded;
uniform sampler2D mirror_tex : source_color, filter_linear;
void fragment() {
	vec2 d = (UV - vec2(0.5)) * 2.0;
	if (dot(d, d) > 1.0) { discard; }
	vec3 col = texture(mirror_tex, vec2(1.0 - UV.x, UV.y)).rgb;
	ALBEDO = col * vec3(0.92, 0.96, 1.0);
}
"""
		_side_mirror_vp = SubViewport.new()
		_side_mirror_vp.name = "SideMirrorViewport"
		_side_mirror_vp.size = Vector2i(96, 72)
		_side_mirror_vp.world_3d = get_world_3d()
		_side_mirror_vp.positional_shadow_atlas_size = 0
		_side_mirror_vp.msaa_3d = Viewport.MSAA_DISABLED
		_side_mirror_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		_side_mirror_vp.use_debanding = false
		_side_mirror_vp.transparent_bg = false
		_side_mirror_vp.audio_listener_enable_2d = false
		_side_mirror_vp.audio_listener_enable_3d = false
		_side_mirror_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if _fp_hide_head else SubViewport.UPDATE_DISABLED
		_rosary_root.add_child(_side_mirror_vp)
		_side_mirror_cam = Camera3D.new()
		_side_mirror_cam.name = "SideMirrorCamera"
		_side_mirror_cam.fov = 38.0
		_side_mirror_cam.near = 0.2
		_side_mirror_cam.far = 90.0
		_side_mirror_cam.current = true
		_side_mirror_vp.add_child(_side_mirror_cam)
		_side_mirror_anchor = RemoteTransform3D.new()
		_side_mirror_anchor.name = "SideMirrorCamAnchor"
		_side_mirror_anchor.position = Vector3(0.99, 1.12, 0.44)
		_side_mirror_anchor.rotation = Vector3(deg_to_rad(-3.0), deg_to_rad(-8.0), 0.0)
		_side_mirror_anchor.update_scale = false
		inner.add_child(_side_mirror_anchor)
		_side_mirror_anchor.remote_path = _side_mirror_cam.get_path()
		_side_mirror_anchor.force_update_cache()
		var esm := ShaderMaterial.new()
		esm.shader = _oval_mirror_shader
		esm.set_shader_parameter("mirror_tex", _side_mirror_vp.get_texture())
		var smq := MeshInstance3D.new()
		smq.name = "LeftSideMirrorGlass"
		var esqm := QuadMesh.new()
		esqm.size = Vector2(0.112, 0.082)
		smq.mesh = esqm
		smq.material_override = esm
		smq.position = Vector3(0.905, 1.128, 0.542) - _dash_root.position
		smq.rotation.y = PI + deg_to_rad(10.0)
		smq.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_dash_root.add_child(smq)

## Strips the baked static steering wheel (`Part184Mtl` front-center cab faces) and swaps the heavy cyan `Part144Mtl` glass
## for subtle clear tractor cab glass while in 1st-person (keeping exterior glass, frame, hood & exhaust intact in 3rd-person / on exit).
static var _yondir_glass: StandardMaterial3D = null
func _set_yondir_cab_stripped() -> void:
	if model == null or not is_instance_valid(model):
		return
	var bmi := model.find_child("body", true, false) as MeshInstance3D
	if bmi == null or bmi.mesh == null:
		return
	_dash_body_mi = bmi
	_dash_orig_mesh = bmi.mesh
	if _yondir_glass == null:
		_yondir_glass = StandardMaterial3D.new()
		_yondir_glass.albedo_color = Color(0.08, 0.13, 0.16, 0.09)
		_yondir_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_yondir_glass.roughness = 0.08
		_yondir_glass.metallic = 0.24
		_yondir_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
		_yondir_glass.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	if not _z15_cab_meshes.has(_dash_orig_mesh):
		var orig: Mesh = _dash_orig_mesh
		var xf: Transform3D = model.transform * bmi.transform
		var out := ArrayMesh.new()
		for s in range(orig.get_surface_count()):
			var a: Array = orig.surface_get_arrays(s)
			var mat = orig.surface_get_material(s)
			var nm := String(mat.resource_name) if mat != null else ""
			if nm == "Part184Mtl":
				var verts: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
				var idx := PackedInt32Array()
				if a[Mesh.ARRAY_INDEX] != null:
					idx = a[Mesh.ARRAY_INDEX]
				else:
					for k in range(verts.size()):
						idx.append(k)
				var keep := PackedInt32Array()
				for t in range(0, idx.size() - 2, 3):
					var mid: Vector3 = xf * ((verts[idx[t]] + verts[idx[t + 1]] + verts[idx[t + 2]]) / 3.0)
					var is_old_wheel: bool = absf(mid.x) < 0.24 and mid.y > 1.78 and mid.y < 2.22 and mid.z > -0.18 and mid.z < 0.14
					if not is_old_wheel:
						keep.append(idx[t])
						keep.append(idx[t + 1])
						keep.append(idx[t + 2])
				if keep.is_empty():
					keep = PackedInt32Array([0, 0, 0])
				a[Mesh.ARRAY_INDEX] = keep
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
			out.surface_set_material(s, _yondir_glass if nm == "Part144Mtl" else mat)
		_z15_cab_meshes[_dash_orig_mesh] = out
	bmi.mesh = _z15_cab_meshes[_dash_orig_mesh]

## Procedural 128x128 classic John Deere / Yondir gauges: "tracto" (big central 0-60 km/h + concentric RPM), "temp", "fuel"
static func _build_yondir_dial_tex(mode: String) -> ImageTexture:
	if _yondir_dial_tex.has(mode):
		return _yondir_dial_tex[mode]
	var sz := 128
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	var cx := 64.0
	var cy := 64.0
	var rad := 60.0
	var face := Color(0.08, 0.09, 0.10, 1.0)
	var ring := Color(0.80, 0.82, 0.84, 1.0)
	for py in range(sz):
		for px in range(sz):
			var d := Vector2(px - cx, py - cy).length()
			if d <= rad:
				var c := ring if d > rad - 2.8 else face
				img.set_pixel(px, py, c)
	if mode == "tracto":
		# Classic concentric John Deere tractometer: outer 0..60 km/h ticks + inner white/green gear-RPM arc + hour window!
		for py in range(sz):
			for px in range(sz):
				var dx := float(px) - cx
				var dy := float(py) - cy
				var d := sqrt(dx * dx + dy * dy)
				if d >= 26.0 and d <= 36.0:
					var a_deg := rad_to_deg(atan2(dx, -dy))
					if a_deg >= -120.0 and a_deg <= 120.0:
						var grn := a_deg >= -30.0 and a_deg <= 70.0
						img.set_pixel(px, py, Color(0.24, 0.62, 0.28, 1.0) if grn else Color(0.28, 0.30, 0.34, 1.0))
		for step in range(0, 25):
			var frac := float(step) / 24.0
			var ang := deg_to_rad(lerpf(-130.0, 130.0, frac))
			var major := step % 4 == 0
			var r_in := rad - (14.0 if major else 8.5)
			var r_out := rad - 4.0
			var tcol := Color(0.92, 0.26, 0.18, 1.0) if step >= 21 else (Color(0.95, 0.96, 0.92, 1.0) if major else Color(0.72, 0.74, 0.72, 1.0))
			var thick := 2 if major else 1
			for s in range(18):
				var rr := lerpf(r_in, r_out, float(s) / 17.0)
				var gx := int(round(cx + sin(ang) * rr))
				var gy := int(round(cy - cos(ang) * rr))
				for ox in range(-thick / 2, thick / 2 + 1):
					for oy in range(-thick / 2, thick / 2 + 1):
						if gx + ox >= 0 and gx + ox < sz and gy + oy >= 0 and gy + oy < sz:
							img.set_pixel(gx + ox, gy + oy, tcol)
		# Classic 5-digit tractor hour counter window at bottom
		for py in range(86, 98):
			for px in range(42, 86):
				var edge := py == 86 or py == 97 or px == 42 or px == 85
				img.set_pixel(px, py, Color(0.25, 0.26, 0.28, 1.0) if edge else Color(0.88, 0.88, 0.82, 1.0))
		for di in range(5):
			var dx0 := 45 + di * 8
			for py in range(89, 95):
				img.set_pixel(dx0 + 2, py, Color(0.10, 0.10, 0.12, 1.0))
				if (di + py) % 2 == 0:
					img.set_pixel(dx0 + 4, py, Color(0.10, 0.10, 0.12, 1.0))
	else:
		# Flanking small round gauges: "temp" (green normal + red hot) or "fuel" (red reserve + white full)
		for py in range(sz):
			for px in range(sz):
				var dx := float(px) - cx
				var dy := float(py) - cy
				var d := sqrt(dx * dx + dy * dy)
				if d >= rad - 16.0 and d <= rad - 6.0:
					var a_deg := rad_to_deg(atan2(dx, -dy))
					if mode == "temp":
						if a_deg >= -75.0 and a_deg <= 35.0:
							img.set_pixel(px, py, Color(0.24, 0.68, 0.30, 1.0))
						elif a_deg > 35.0 and a_deg <= 105.0:
							img.set_pixel(px, py, Color(0.88, 0.22, 0.16, 1.0))
					else:
						if a_deg >= -105.0 and a_deg <= -55.0:
							img.set_pixel(px, py, Color(0.88, 0.22, 0.16, 1.0))
						elif a_deg > -55.0 and a_deg <= 105.0:
							img.set_pixel(px, py, Color(0.84, 0.86, 0.88, 1.0))
		for step in range(0, 9):
			var ang := deg_to_rad(lerpf(-105.0, 105.0, float(step) / 8.0))
			for s in range(14):
				var rr := lerpf(rad - 18.0, rad - 5.0, float(s) / 13.0)
				var gx := int(round(cx + sin(ang) * rr))
				var gy := int(round(cy - cos(ang) * rr))
				if gx >= 0 and gx < sz and gy >= 0 and gy < sz:
					img.set_pixel(gx, gy, Color(0.95, 0.96, 0.94, 1.0))
	var tex := ImageTexture.create_from_image(img)
	_yondir_dial_tex[mode] = tex
	return tex

## Procedural 64x64 original "Yondir" bear steering-wheel roundel (silver ring, dark green disc, sturdy yellow-gold bear!)
static func _build_yondir_badge_tex() -> ImageTexture:
	if _yondir_badge_tex != null:
		return _yondir_badge_tex
	var sz := 64
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	var cx := 32.0
	var cy := 32.0
	for py in range(sz):
		for px in range(sz):
			var dx := float(px) - cx
			var dy := float(py) - cy
			var d := sqrt(dx * dx + dy * dy)
			if d <= 30.0:
				var c := Color(0.84, 0.86, 0.88, 1.0) if d > 26.0 else (Color(0.11, 0.13, 0.12, 1.0) if d > 23.0 else Color(0.13, 0.34, 0.16, 1.0))
				img.set_pixel(px, py, c)
	# Iconic sturdy striding BEAR silhouette in bright tractor yellow-gold (broad humped back, round ears, snout, 4 chunky paws, stubby tail!)
	var bear := Color(0.96, 0.82, 0.18, 1.0)
	var rects := [
		Rect2i(16, 25, 24, 13),  # sturdy bear body
		Rect2i(20, 22, 16, 4),   # characteristic bear shoulder hump
		Rect2i(36, 22, 11, 10),  # broad bear head
		Rect2i(45, 25, 5, 5),    # thick bear snout
		Rect2i(36, 18, 4, 4),    # back round ear
		Rect2i(42, 18, 4, 4),    # front round ear
		Rect2i(13, 27, 4, 4),    # tiny round stubby tail
		Rect2i(17, 37, 6, 8),    # hind leg
		Rect2i(15, 42, 8, 3),    # hind paw
		Rect2i(25, 37, 5, 7),    # inner hind leg
		Rect2i(34, 37, 6, 8),    # front leg
		Rect2i(35, 42, 8, 3),    # front paw
	]
	for rc: Rect2i in rects:
		for py in range(rc.position.y, rc.end.y):
			for px in range(rc.position.x, rc.end.x):
				if px >= 0 and px < sz and py >= 0 and py < sz:
					img.set_pixel(px, py, bear)
	# Tiny dark green eye dot for charm
	img.set_pixel(44, 25, Color(0.10, 0.24, 0.12, 1.0))
	img.set_pixel(44, 26, Color(0.10, 0.24, 0.12, 1.0))
	_yondir_badge_tex = ImageTexture.create_from_image(img)
	return _yondir_badge_tex

## Procedural 96x128 vintage Spanish holy card ("Estampita de San Isidro Labrador") for the Yondir dashboard (50% per tractor!)
static func _build_yondir_isidro_tex() -> ImageTexture:
	if _yondir_isidro_tex != null:
		return _yondir_isidro_tex
	var w := 96
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var cream := Color(0.96, 0.93, 0.84, 1.0)
	var gold := Color(0.84, 0.66, 0.18, 1.0)
	var gold_hi := Color(0.98, 0.86, 0.34, 1.0)
	var sky := Color(0.46, 0.72, 0.92, 1.0)
	var sky_hi := Color(0.68, 0.84, 0.96, 1.0)
	var field := Color(0.82, 0.68, 0.28, 1.0)
	var field_d := Color(0.64, 0.50, 0.20, 1.0)
	var brown := Color(0.40, 0.25, 0.14, 1.0)
	var brown_d := Color(0.26, 0.16, 0.09, 1.0)
	var skin := Color(0.92, 0.76, 0.60, 1.0)
	var wood := Color(0.56, 0.36, 0.18, 1.0)
	var iron := Color(0.42, 0.45, 0.50, 1.0)
	img.fill(cream)
	# Ornate golden border frame
	for py in range(4, h - 4):
		for px in range(4, w - 4):
			var on_frame := py <= 6 or py >= h - 7 or px <= 6 or px >= w - 7
			var on_inner := py == 9 or py == h - 10 or px == 9 or px == w - 10
			if on_frame:
				img.set_pixel(px, py, gold)
			elif on_inner and px >= 9 and px <= w - 10 and py >= 9 and py <= h - 10:
				img.set_pixel(px, py, gold_hi)
			elif px > 9 and px < w - 10 and py > 9 and py < h - 24:
				# Sky + La Mancha golden wheat field backdrop
				if py < 74:
					img.set_pixel(px, py, sky_hi if py > 56 else sky)
				else:
					img.set_pixel(px, py, field_d if (px + py) % 5 == 0 else field)
	# Glowing golden halo (aureola) behind San Isidro's head
	for py in range(16, 50):
		for px in range(30, 66):
			var d := Vector2(px - 48.0, py - 33.0).length()
			if d <= 16.0 and d >= 10.0:
				img.set_pixel(px, py, gold_hi if d > 13.0 else gold)
			elif d < 10.0:
				img.set_pixel(px, py, Color(0.98, 0.90, 0.54, 1.0))
	# Humble farmer's tunic (sayo pardo), cape, belt, legs & boots
	for py in range(44, 88):
		var hw := int(lerpf(11.0, 18.0, float(py - 44) / 44.0))
		for px in range(48 - hw, 48 + hw + 1):
			var is_belt := py >= 64 and py <= 67
			var is_fold: bool = absi(px - 48) == 5 or absi(px - 48) == 11
			img.set_pixel(px, py, brown_d if (is_belt or is_fold) else brown)
	# Boots standing in the wheat
	for py in range(88, 100):
		for px in range(38, 45):
			img.set_pixel(px, py, brown_d)
		for px in range(51, 58):
			img.set_pixel(px, py, brown_d)
	# Head, hair & short beard
	for py in range(24, 43):
		for px in range(40, 56):
			var d := Vector2((px - 48.0) * 1.1, py - 33.0).length()
			if d <= 8.5:
				var is_hair := py < 29 or (py > 37 and d > 4.5)
				img.set_pixel(px, py, brown_d if is_hair else skin)
	# Eyes
	img.set_pixel(45, 33, brown_d)
	img.set_pixel(51, 33, brown_d)
	# Classic farmer's wooden spade/hoe ("azada / aguijada") held diagonally in his right hand
	for s in range(62):
		var hx := int(round(lerpf(24.0, 68.0, float(s) / 61.0)))
		var hy := int(round(lerpf(36.0, 96.0, float(s) / 61.0)))
		for ox in range(-1, 2):
			if hx + ox >= 10 and hx + ox < w - 10 and hy >= 10 and hy < h - 24:
				img.set_pixel(hx + ox, hy, wood)
	# Iron hoe blade at top-left end of staff
	for py in range(32, 41):
		for px in range(18, 28):
			img.set_pixel(px, py, iron)
	# Golden wheat sheaf in his other hand
	for s in range(18):
		var wx := 62 + (s % 5)
		var wy := 56 + s
		img.set_pixel(wx, wy, gold_hi)
		img.set_pixel(wx + 2, wy - 2, gold)
	# Bottom cream banner caption: "S. ISIDRO"
	for py in range(h - 23, h - 10):
		for px in range(10, w - 10):
			img.set_pixel(px, py, cream)
	_draw_tiny_word(img, "S. ISIDRO", 30, h - 19, brown_d)
	_yondir_isidro_tex = ImageTexture.create_from_image(img)
	return _yondir_isidro_tex

## Classic John Deere / Yondir tractor cab cockpit (Photos 1, 2 & 3):
## matte-black arched instrument console set into the green bonnet cowl, HUGE central chromed tractometer (0-60 km/h),
## flanking Temp & Fuel gauges, glowing red warning lamps + hazard triangle + cream/grey rocker switches + ignition key,
## twin bright-ORANGE hand levers (right hand-throttle live with `_thr`), twin bright-ORANGE round gear-shift knobs &
## yellow PTO lever, glossy 3-spoke wheel with leaping-stag roundel & player hands, live exhaust rain-cap ("sombrerete")
## on the vertical pipe ahead of the green hood, big-diesel cab vibration, and live cab rearview mirror!
func _build_yondir_dash(eye_x: float, eye_y: float, eye_z: float) -> void:
	if _hebro_chrome == null:
		_hebro_chrome = StandardMaterial3D.new()
		_hebro_chrome.albedo_color = Color(0.86, 0.88, 0.90)
		_hebro_chrome.metallic = 0.86
		_hebro_chrome.roughness = 0.20
	if _hebro_rust == null:
		_hebro_rust = StandardMaterial3D.new()
		_hebro_rust.albedo_color = Color(0.42, 0.25, 0.14)
		_hebro_rust.metallic = 0.25
		_hebro_rust.roughness = 0.88
	if _ros_mirror == null:
		_ros_mirror = StandardMaterial3D.new()
		_ros_mirror.albedo_color = Color(0.36, 0.40, 0.46)
		_ros_mirror.metallic = 0.42
		_ros_mirror.roughness = 0.16
	if _ros_silver == null:
		_ros_silver = StandardMaterial3D.new()
		_ros_silver.albedo_color = Color(0.84, 0.86, 0.90)
		_ros_silver.metallic = 0.86
		_ros_silver.roughness = 0.22
	if _yondir_seed < 0:
		_yondir_seed = randi()
	_yondir_san_isidro = (_yondir_seed % 2) == 0        # 50% chance: Estampita de San Isidro Labrador propped on dash!
	_yondir_lazo = ((_yondir_seed / 2) % 4) == 0        # 25% chance: Spanish flag keychain/ribbon hanging from upper cab roof!
	_dash_max_kmh = 60.0
	_dash_root = Node3D.new()
	_dash_root.name = "YondirDashboard"
	# Placed cleanly INSIDE the cab (z = +0.05, well behind the z = +0.18 windscreen) & below driver eye (y = 2.38)
	_dash_base_pos = Vector3(eye_x, eye_y - 0.34, eye_z + 0.48)
	_dash_root.position = _dash_base_pos
	inner.add_child(_dash_root)

	var m_green := Parts.mat(paint)           # iconic John Deere tractor green cowl (0x2f8a3a)
	var m_black := Parts.mat(0x1b1d21)        # matte-black arched instrument console & wheel
	var m_dark := Parts.mat(0x121417)         # deep steering column & exhaust
	var m_orange := Parts.mat(0xe84c1e)       # iconic John Deere bright-orange levers & round gear knobs (Photos 2 & 3!)
	var m_yellow := Parts.mat(0xf2c81e)       # iconic yellow diff/PTO lever (Photos 2 & 3!)
	var m_cream := Parts.mat(0xe6dfd0)        # classic cream rocker switch (Photos 2 & 3!)
	var m_steel := Parts.mat(0x3a3e44)

	# 1) Lower green pedestal column strictly BELOW the console (never clips the tilted instrument faceplate!)
	_dash_root.add_child(_ros_part("box", m_green, Vector3(0.0, -0.25, 0.045), Vector3(0.36, 0.44, 0.16)))

	# 2) Arched matte-black John Deere instrument console tilted UP (+32 deg around +X) toward the driver's eyes!
	var pod := Node3D.new()
	pod.name = "YondirConsole"
	pod.position = Vector3(0.0, 0.085, 0.020)
	pod.rotation.x = deg_to_rad(32.0)
	_dash_root.add_child(pod)
	# Green outer cowl housing STRICTLY behind the matte-black console faceplate (z = +0.044..+0.086 -> impossible to clip gauges!)
	pod.add_child(_ros_part("box", m_green, Vector3(0.0, -0.006, 0.048), Vector3(0.45, 0.245, 0.080)))
	var green_arch := _ros_part("cyl", m_green, Vector3(0.0, 0.112, 0.048), Vector3(0.215, 0.080, 0.042))
	green_arch.rotation.x = PI / 2.0
	pod.add_child(green_arch)
	# Matte-black arched console faceplate (front at z = -0.009)
	pod.add_child(_ros_part("box", m_black, Vector3(0.0, -0.010, 0.000), Vector3(0.41, 0.215, 0.018)))
	var arch_top := _ros_part("cyl", m_black, Vector3(0.0, 0.095, 0.000), Vector3(0.195, 0.018, 0.036))
	arch_top.rotation.x = PI / 2.0
	pod.add_child(arch_top)

	# 2b) 50% chance: Vintage "Estampita de San Isidro Labrador" propped on the upper-right shoulder of the green console!
	if _yondir_san_isidro:
		var card := Node3D.new()
		card.name = "SanIsidroCard"
		card.position = Vector3(-0.155, 0.166, 0.002)
		card.rotation = Vector3(deg_to_rad(-20.0), deg_to_rad(12.0), deg_to_rad(-6.0))
		pod.add_child(card)
		card.add_child(_ros_part("box", Parts.mat(0xeae2cb), Vector3(0.0, 0.0, 0.002), Vector3(0.068, 0.090, 0.003)))
		var imat := StandardMaterial3D.new()
		imat.albedo_texture = _build_yondir_isidro_tex()
		imat.roughness = 0.42
		imat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		var iqm := QuadMesh.new()
		iqm.size = Vector2(0.066, 0.088)
		var iq := MeshInstance3D.new()
		iq.mesh = iqm
		iq.material_override = imat
		iq.position = Vector3(0.0, 0.0, -0.001)
		iq.rotation.y = PI
		iq.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		card.add_child(iq)
		# Tiny strip of matte adhesive tape at the bottom-back holding the holy card against the green cowl
		card.add_child(_ros_part("box", Parts.mat(0xd8d2be), Vector3(0.0, -0.042, 0.005), Vector3(0.024, 0.010, 0.008)))

	# 3) HUGE Central Chromed Tractometer (0-60 km/h + RPM) + Two Flanking Small Round Gauges (Temp left, Fuel right — Photo 1!)
	if _yondir_bezel_big == null:
		_yondir_bezel_big = TorusMesh.new()
		_yondir_bezel_big.inner_radius = 0.056
		_yondir_bezel_big.outer_radius = 0.066
		_yondir_bezel_big.rings = 28
		_yondir_bezel_big.ring_segments = 8
	if _yondir_bezel_sm == null:
		_yondir_bezel_sm = TorusMesh.new()
		_yondir_bezel_sm.inner_radius = 0.028
		_yondir_bezel_sm.outer_radius = 0.034
		_yondir_bezel_sm.rings = 22
		_yondir_bezel_sm.ring_segments = 8
	var m_needle_w := StandardMaterial3D.new()
	m_needle_w.albedo_color = Color(0.96, 0.96, 0.92)
	m_needle_w.emission_enabled = true
	m_needle_w.emission = Color(0.96, 0.96, 0.92)
	m_needle_w.emission_energy_multiplier = 0.45

	# Big central tractometer
	var cbez := MeshInstance3D.new()
	cbez.mesh = _yondir_bezel_big
	cbez.material_override = _hebro_chrome
	cbez.position = Vector3(0.0, 0.015, -0.012)
	cbez.rotation.x = PI / 2.0
	cbez.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pod.add_child(cbez)
	_dash_dial_mat = StandardMaterial3D.new()
	var ttex := _build_yondir_dial_tex("tracto")
	_dash_dial_mat.albedo_texture = ttex
	_dash_dial_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	_dash_dial_mat.alpha_scissor_threshold = 0.5
	_dash_dial_mat.roughness = 0.35
	_dash_dial_mat.emission_enabled = true
	_dash_dial_mat.emission_texture = ttex
	_dash_dial_mat.emission_energy_multiplier = 0.30
	var cqm := QuadMesh.new()
	cqm.size = Vector2(0.118, 0.118)
	var cq := MeshInstance3D.new()
	cq.mesh = cqm
	cq.material_override = _dash_dial_mat
	cq.position = Vector3(0.0, 0.015, -0.011)
	cq.rotation.y = PI
	cq.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pod.add_child(cq)
	_dash_needle = Node3D.new()
	_dash_needle.name = "SpeedoNeedle"
	_dash_needle.position = Vector3(0.0, 0.015, -0.015)
	pod.add_child(_dash_needle)
	_dash_needle.add_child(_ros_part("box", m_needle_w, Vector3(0.0, 0.022, 0.0), Vector3(0.0040, 0.046, 0.0025)))
	var chub := _ros_part("cyl", _hebro_chrome, Vector3(0.0, 0.0, -0.001), Vector3(0.008, 0.005, 0.008))
	chub.rotation.x = PI / 2.0
	_dash_needle.add_child(chub)
	_dash_speed_ang = deg_to_rad(-130.0)
	_dash_needle.rotation.z = _dash_speed_ang

	# Flanking small round gauges: LEFT = Temp, RIGHT = Fuel/Oil (Photo 1!)
	for fi in range(2):
		var is_temp := fi == 0
		var fx: float = 0.132 if is_temp else -0.132
		var fy := 0.016
		var fbez := MeshInstance3D.new()
		fbez.mesh = _yondir_bezel_sm
		fbez.material_override = _hebro_chrome
		fbez.position = Vector3(fx, fy, -0.012)
		fbez.rotation.x = PI / 2.0
		fbez.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pod.add_child(fbez)
		var fmat := StandardMaterial3D.new()
		var ftex := _build_yondir_dial_tex("temp" if is_temp else "fuel")
		fmat.albedo_texture = ftex
		fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		fmat.alpha_scissor_threshold = 0.5
		fmat.roughness = 0.38
		fmat.emission_enabled = true
		fmat.emission_texture = ftex
		fmat.emission_energy_multiplier = 0.25
		var fqm := QuadMesh.new()
		fqm.size = Vector2(0.058, 0.058)
		var fq := MeshInstance3D.new()
		fq.mesh = fqm
		fq.material_override = fmat
		fq.position = Vector3(fx, fy, -0.011)
		fq.rotation.y = PI
		fq.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pod.add_child(fq)
		var fn := Node3D.new()
		fn.position = Vector3(fx, fy, -0.015)
		fn.add_child(_ros_part("box", m_needle_w, Vector3(0.0, 0.011, 0.0), Vector3(0.0026, 0.022, 0.002)))
		pod.add_child(fn)
		if is_temp:
			fn.name = "OilNeedle"
			_hebro_oil_needle = fn
			_hebro_oil_ang = deg_to_rad(-105.0)
			fn.rotation.z = _hebro_oil_ang
		else:
			fn.rotation.z = deg_to_rad(42.0)

	# Classic John Deere lamps, red hazard button, cream/grey rocker switches & ignition key (Photos 1, 2 & 3!)
	_dash_lamp_mat = StandardMaterial3D.new()
	_dash_lamp_mat.albedo_color = Color(0.85, 0.16, 0.14)
	_dash_lamp_mat.emission_enabled = true
	_dash_lamp_mat.emission = Color(1.0, 0.22, 0.14)
	_dash_lamp_mat.emission_energy_multiplier = 0.25
	for lx: float in [0.088, -0.088, -0.142]:
		var lring := _ros_part("cyl", _hebro_chrome, Vector3(lx, 0.078, -0.010), Vector3(0.011, 0.008, 0.011))
		lring.rotation.x = PI / 2.0
		pod.add_child(lring)
		pod.add_child(_ros_part("ball", _dash_lamp_mat, Vector3(lx, 0.078, -0.015), Vector3(0.008, 0.008, 0.006)))
	# Red hazard button (lower left) + twin cream/grey rocker switches (upper right) + ignition key (lower right)
	var haz := _ros_part("cyl", Parts.mat(0xd42620), Vector3(0.118, -0.052, -0.012), Vector3(0.015, 0.012, 0.015))
	haz.rotation.x = PI / 2.0
	pod.add_child(haz)
	pod.add_child(_ros_part("box", m_cream, Vector3(-0.086, -0.052, -0.013), Vector3(0.016, 0.024, 0.012)))
	pod.add_child(_ros_part("box", Parts.mat(0x5a5e64), Vector3(-0.108, -0.052, -0.013), Vector3(0.016, 0.024, 0.012)))
	var ign := _ros_part("cyl", _hebro_chrome, Vector3(-0.146, -0.058, -0.012), Vector3(0.013, 0.014, 0.013))
	ign.rotation.x = PI / 2.0
	pod.add_child(ign)
	pod.add_child(_ros_part("box", m_dark, Vector3(-0.146, -0.068, -0.022), Vector3(0.006, 0.024, 0.018)))

	# 4) Twin iconic BRIGHT-ORANGE rubber-tipped hand levers (right = LIVE hand-throttle `_hebro_throttle_piv`!) + orange gear knobs & yellow PTO!
	# Left orange lever (reverser / PTO)
	var lev_l := _ros_part("cyl", m_dark, Vector3(0.145, 0.045, -0.025), Vector3(0.006, 0.16, 0.006))
	lev_l.rotation.z = deg_to_rad(-55.0)
	_dash_root.add_child(lev_l)
	var tip_l := _ros_part("cyl", m_orange, Vector3(0.215, 0.088, -0.025), Vector3(0.012, 0.052, 0.012))
	tip_l.rotation.z = deg_to_rad(-55.0)
	_dash_root.add_child(tip_l)
	# Right LIVE orange hand-throttle lever moving forward/back with `_thr`!
	_hebro_throttle_piv = Node3D.new()
	_hebro_throttle_piv.name = "HandThrottle"
	_hebro_throttle_piv.position = Vector3(-0.095, 0.042, -0.018)
	_dash_root.add_child(_hebro_throttle_piv)
	var trod := _ros_part("cyl", m_steel, Vector3(-0.075, 0.018, -0.010), Vector3(0.006, 0.16, 0.006))
	trod.rotation.z = deg_to_rad(68.0)
	_hebro_throttle_piv.add_child(trod)
	var ttip := _ros_part("cyl", m_orange, Vector3(-0.150, 0.048, -0.014), Vector3(0.012, 0.056, 0.012))
	ttip.rotation.z = deg_to_rad(68.0)
	_hebro_throttle_piv.add_child(ttip)
	# Twin bright-ORANGE round gear-shift knobs below wheel + iconic bright-YELLOW diff/PTO lever (Photos 2 & 3!)
	for gx: float in [0.125, -0.115]:
		var gs := _ros_part("cyl", m_dark, Vector3(gx, -0.17, -0.085), Vector3(0.007, 0.22, 0.007))
		gs.rotation.x = -0.18
		_dash_root.add_child(gs)
		_dash_root.add_child(_ros_part("ball", m_orange, Vector3(gx, -0.065, -0.105), Vector3(0.024, 0.024, 0.024)))
	_dash_root.add_child(_ros_part("box", m_yellow, Vector3(0.068, -0.145, -0.092), Vector3(0.018, 0.056, 0.016)))

	# 5) Classic 3-Spoke Glossy-Black John Deere Steering Wheel + Leaping-Stag Roundel + Player Hands!
	var col_mount := Node3D.new()
	col_mount.position = Vector3(0.0, 0.035, -0.108)
	col_mount.rotation.x = deg_to_rad(38.0)     # tilted UP toward driver's eyes, column shaft running down into console
	_dash_root.add_child(col_mount)
	var shaft := _ros_part("cyl", m_dark, Vector3(0.0, 0.0, 0.090), Vector3(0.024, 0.18, 0.024))
	shaft.rotation.x = PI / 2.0
	col_mount.add_child(shaft)

	_dash_wheel = Node3D.new()
	_dash_wheel.name = "YondirWheel"
	col_mount.add_child(_dash_wheel)
	if _yondir_rim_mesh == null:
		_yondir_rim_mesh = TorusMesh.new()
		_yondir_rim_mesh.inner_radius = 0.165
		_yondir_rim_mesh.outer_radius = 0.182
		_yondir_rim_mesh.rings = 32
		_yondir_rim_mesh.ring_segments = 10
	var rim := MeshInstance3D.new()
	rim.mesh = _yondir_rim_mesh
	rim.material_override = m_black
	rim.rotation.x = PI / 2.0
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_dash_wheel.add_child(rim)
	# 3 sturdy glossy-black spokes (12, 4, 8 o'clock) + round textured center horn cap + leaping-stag roundel (Photo 1!)
	for sang_deg: float in [0.0, 120.0, -120.0]:
		var sa := deg_to_rad(sang_deg)
		var sp := _ros_part("cyl", m_black, Vector3(-sin(sa) * 0.088, cos(sa) * 0.088, 0.004), Vector3(0.010, 0.172, 0.010))
		sp.rotation.z = sa
		_dash_wheel.add_child(sp)
	var hub := _ros_part("cyl", m_black, Vector3(0.0, 0.0, -0.004), Vector3(0.044, 0.022, 0.044))
	hub.rotation.x = PI / 2.0
	_dash_wheel.add_child(hub)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_texture = _build_yondir_badge_tex()
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	bmat.alpha_scissor_threshold = 0.5
	bmat.roughness = 0.28
	var bqm := QuadMesh.new()
	bqm.size = Vector2(0.056, 0.056)
	var bq := MeshInstance3D.new()
	bq.mesh = bqm
	bq.material_override = bmat
	bq.position = Vector3(0.0, 0.0, -0.016)
	bq.rotation.y = PI
	bq.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_dash_wheel.add_child(bq)
	# Driver's hands gripping the rim at 9:30 and 2:30 (rotating solidly with steering!)
	var skin_hex: int = int(riders[0].get("skin", 0xf6c9a0))
	var m_skin := Parts.mat(skin_hex)
	var grip_r := 0.174
	var grip_ang := deg_to_rad(68.0)
	for sgn: float in [1.0, -1.0]:
		var hand := Node3D.new()
		hand.name = "WheelHandL" if sgn > 0.0 else "WheelHandR"
		hand.position = Vector3(sgn * grip_r * sin(grip_ang), grip_r * cos(grip_ang), -0.007)
		hand.rotation.z = sgn * grip_ang
		hand.add_child(_ros_part("ball", m_skin, Vector3.ZERO, Vector3(0.026, 0.035, 0.024)))
		var thumb := _ros_part("ball", m_skin, Vector3(-0.012 * sgn, 0.027, -0.007), Vector3(0.011, 0.017, 0.011))
		thumb.rotation.z = sgn * 0.25
		hand.add_child(thumb)
		_dash_wheel.add_child(hand)

	# 6) Hinged iron exhaust rain-cap ("sombrerete") on the vertical diesel pipe ahead of the green hood (Photo 2!)
	var pipe_pos: Vector3 = _pipe_at if (_pipe_at is Vector3) else Vector3(0.356, 2.34, 1.54)
	_hebro_flap_root = Node3D.new()
	_hebro_flap_root.name = "ExhaustRainCap"
	_hebro_flap_root.position = pipe_pos
	inner.add_child(_hebro_flap_root)
	_hebro_flap_root.add_child(_ros_part("cyl", m_steel, Vector3(0.0, -0.016, 0.0), Vector3(0.032, 0.034, 0.032)))
	_hebro_flap_root.add_child(_ros_part("box", _hebro_rust, Vector3(0.0, 0.004, -0.038), Vector3(0.016, 0.020, 0.020)))
	_hebro_flap_piv = Node3D.new()
	_hebro_flap_piv.name = "ExhaustFlapPivot"
	_hebro_flap_piv.position = Vector3(0.0, 0.012, -0.038)
	_hebro_flap_root.add_child(_hebro_flap_piv)
	_hebro_flap_piv.add_child(_ros_part("cyl", m_steel, Vector3(0.0, 0.003, 0.038), Vector3(0.044, 0.007, 0.044)))
	_hebro_flap_piv.add_child(_ros_part("box", _hebro_rust, Vector3(0.0, 0.004, -0.016), Vector3(0.014, 0.008, 0.028)))

	# 7) Dual Functional Upper Side Tractor Mirrors (left & right corners, vertical tractor format on tubular arms — reference photo!)
	#    plus 25% chance of hanging Spanish flag keychain/ribbon ("llavero de España") swinging from upper-left roof header!
	_rosary_root = Node3D.new()
	_rosary_root.name = "YondirMirrors"
	inner.add_child(_rosary_root)
	for side_i in range(2):
		var is_left := side_i == 0
		var sgn: float = 1.0 if is_left else -1.0
		var mroot := Node3D.new()
		mroot.name = "YondirMirrorL" if is_left else "YondirMirrorR"
		mroot.position = Vector3(sgn * 0.46, eye_y + 0.135, eye_z + 0.56)
		mroot.rotation = Vector3(deg_to_rad(-4.0), deg_to_rad(-16.0 * sgn), 0.0)
		_rosary_root.add_child(mroot)
		# Sturdy tubular steel mirror arm extending outward & upward to the cab corner pillar/roof
		var arm_h := _ros_part("cyl", m_dark, Vector3(sgn * 0.095, 0.065, 0.012), Vector3(0.011, 0.14, 0.011))
		arm_h.rotation.z = deg_to_rad(68.0 * sgn)
		mroot.add_child(arm_h)
		var arm_v := _ros_part("cyl", m_dark, Vector3(sgn * 0.035, 0.098, 0.010), Vector3(0.010, 0.065, 0.010))
		arm_v.rotation.z = deg_to_rad(-18.0 * sgn)
		mroot.add_child(arm_v)
		# Tall vertical rectangular tractor mirror housing
		mroot.add_child(_ros_part("box", m_dark, Vector3(0.0, 0.0, 0.0), Vector3(0.112, 0.186, 0.022)))
		var yglass: StandardMaterial3D = _ros_mirror
		if DisplayServer.get_name() != "headless":
			var mvp := SubViewport.new()
			mvp.name = "MirrorViewport" if is_left else "SideMirrorViewport"
			mvp.size = Vector2i(96, 128)
			mvp.world_3d = get_world_3d()
			mvp.positional_shadow_atlas_size = 0
			mvp.msaa_3d = Viewport.MSAA_DISABLED
			mvp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			mvp.use_debanding = false
			mvp.transparent_bg = false
			mvp.audio_listener_enable_2d = false
			mvp.audio_listener_enable_3d = false
			mvp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if _fp_hide_head else SubViewport.UPDATE_DISABLED
			_rosary_root.add_child(mvp)
			var mcam := Camera3D.new()
			mcam.name = "MirrorCamera" if is_left else "SideMirrorCamera"
			mcam.fov = 38.0
			mcam.near = 0.2
			mcam.far = 90.0
			mcam.current = true
			mvp.add_child(mcam)
			var manchor := RemoteTransform3D.new()
			manchor.name = "MirrorCamAnchor" if is_left else "SideMirrorCamAnchor"
			manchor.position = Vector3(sgn * 0.98, 2.48, 0.12)
			manchor.rotation = Vector3(deg_to_rad(-6.0), deg_to_rad(-7.0 * sgn), 0.0)
			manchor.update_scale = false
			inner.add_child(manchor)
			manchor.remote_path = mcam.get_path()
			manchor.force_update_cache()
			if is_left:
				_mirror_vp = mvp
				_mirror_cam = mcam
				_mirror_anchor = manchor
			else:
				_side_mirror_vp = mvp
				_side_mirror_cam = mcam
				_side_mirror_anchor = manchor
			yglass = StandardMaterial3D.new()
			yglass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			yglass.albedo_texture = mvp.get_texture()
			yglass.albedo_color = Color(0.92, 0.96, 1.0)
			yglass.uv1_scale = Vector3(-1.0, 1.0, 1.0)
			yglass.uv1_offset = Vector3(1.0, 0.0, 0.0)
			yglass.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		var ymq := MeshInstance3D.new()
		var yqm := QuadMesh.new()
		yqm.size = Vector2(0.098, 0.170)
		ymq.mesh = yqm
		ymq.material_override = yglass
		ymq.position = Vector3(0.0, 0.0, -0.012)
		ymq.rotation.y = PI
		ymq.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mroot.add_child(ymq)

	# 25% chance: Swinging Spanish flag keychain/ribbon ("llavero de España") hanging from the upper-left side of the cab roof!
	if _yondir_lazo:
		var m_red := Parts.mat(0xc81d25)
		var m_yel := Parts.mat(0xf2c21a)
		var hook_pos := Vector3(0.27, eye_y + 0.255, eye_z + 0.49)
		_rosary_root.add_child(_ros_part("box", m_dark, hook_pos + Vector3(0.0, 0.010, 0.0), Vector3(0.018, 0.016, 0.018)))
		_rosary_piv = Node3D.new()
		_rosary_piv.name = "SpanishRibbonPivot"
		_rosary_piv.position = hook_pos
		_rosary_root.add_child(_rosary_piv)
		# Tiny shiny silver keyring loop at the top hook
		_rosary_piv.add_child(_ros_part("ball", _ros_silver, Vector3(0.0, -0.005, 0.0), Vector3(0.008, 0.008, 0.005)))
		var segs := [
			Vector3(0.0, -0.018, 0.0), Vector3(0.0, -0.045, 0.002),
			Vector3(0.0, -0.071, 0.001), Vector3(0.0, -0.093, 0.0),
		]
		var wids := [0.015, 0.020, 0.018, 0.010]
		for si in range(segs.size()):
			var w_tot: float = wids[si]
			var sp: Vector3 = segs[si]
			_rosary_piv.add_child(_ros_part("box", m_yel, sp, Vector3(w_tot * 0.48, 0.029, 0.0030)))
			_rosary_piv.add_child(_ros_part("box", m_red, sp + Vector3(w_tot * 0.38, 0.0, 0.0), Vector3(w_tot * 0.28, 0.029, 0.0030)))
			_rosary_piv.add_child(_ros_part("box", m_red, sp + Vector3(-w_tot * 0.38, 0.0, 0.0), Vector3(w_tot * 0.28, 0.029, 0.0030)))
		_rosary_piv.add_child(_ros_part("ball", _ros_silver, Vector3(0.0, -0.106, 0.0), Vector3(0.0075, 0.0055, 0.0065)))
		_rosary_drop = Node3D.new()
		_rosary_drop.name = "SpanishRibbonTail"
		_rosary_drop.position = Vector3(0.0, -0.109, 0.0)
		_rosary_piv.add_child(_rosary_drop)
		var t_segs := [Vector3(0.0, -0.015, 0.0), Vector3(0.0, -0.038, 0.001), Vector3(0.0, -0.056, 0.0)]
		var t_wids := [0.014, 0.020, 0.010]
		for ti in range(t_segs.size()):
			var tw: float = t_wids[ti]
			var tp: Vector3 = t_segs[ti]
			_rosary_drop.add_child(_ros_part("box", m_yel, tp, Vector3(tw * 0.48, 0.025, 0.0028)))
			_rosary_drop.add_child(_ros_part("box", m_red, tp + Vector3(tw * 0.38, 0.0, 0.0), Vector3(tw * 0.28, 0.025, 0.0028)))
			_rosary_drop.add_child(_ros_part("box", m_red, tp + Vector3(-tw * 0.38, 0.0, 0.0), Vector3(tw * 0.28, 0.025, 0.0028)))

## Procedural 256x128 vintage Renol 4L horizontal rectangular chrome-framed speedometer pod (Photo 2: 0-130 km/h arc + odometer + fuel + amber warning blocks!)
static func _build_r4_dial_tex() -> ImageTexture:
	if _r4_dial_tex != null:
		return _r4_dial_tex
	var w := 256
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.08, 0.09, 0.11, 1.0))
	# Gleaming chrome outer bezel border + recessed black inner panel
	var chrome := Color(0.84, 0.87, 0.90, 1.0)
	var inner_line := Color(0.28, 0.30, 0.34, 1.0)
	for py in range(h):
		for px in range(w):
			var edge := py < 5 or py >= h - 5 or px < 5 or px >= w - 5
			var rim2 := (py == 7 or py == h - 8 or px == 7 or px == w - 8) and px >= 7 and px < w - 7 and py >= 7 and py < h - 7
			if edge:
				img.set_pixel(px, py, chrome)
			elif rim2:
				img.set_pixel(px, py, inner_line)
	# Wide Renault 4L upper speedometer arc (pivot at bottom-center cx=128, cy=118, radius=82, -62..+62 deg)
	var cx := 128.0
	var cy := 118.0
	for py in range(12, 108):
		for px in range(28, 228):
			var dx := float(px) - cx
			var dy := float(py) - cy
			var d := sqrt(dx * dx + dy * dy)
			var a_deg := rad_to_deg(atan2(dx, -dy))
			if d >= 68.0 and d <= 94.0 and a_deg >= -64.0 and a_deg <= 64.0:
				var band := Color(0.18, 0.20, 0.24, 1.0) if d < 88.0 else Color(0.76, 0.78, 0.80, 1.0)
				if d >= 82.0 and d <= 88.0 and a_deg >= 42.0:
					band = Color(0.86, 0.24, 0.18, 1.0)
				img.set_pixel(px, py, band)
	# Crisp white speedometer ticks 0..130 km/h across -62..+62 deg
	for step in range(0, 27):
		var frac := float(step) / 26.0
		var ang := deg_to_rad(lerpf(-62.0, 62.0, frac))
		var major := step % 2 == 0
		var r_in := 72.0 if major else 79.0
		var r_out := 91.0
		var tcol := Color(0.95, 0.28, 0.20, 1.0) if step >= 22 else (Color(0.96, 0.96, 0.94, 1.0) if major else Color(0.72, 0.75, 0.78, 1.0))
		var thick := 2 if major else 1
		for s in range(22):
			var rr := lerpf(r_in, r_out, float(s) / 21.0)
			var gx := int(round(cx + sin(ang) * rr))
			var gy := int(round(cy - cos(ang) * rr))
			for ox in range(-thick / 2, thick / 2 + 1):
				for oy in range(-thick / 2, thick / 2 + 1):
					if gx + ox >= 8 and gx + ox < w - 8 and gy + oy >= 8 and gy + oy < h - 8:
						img.set_pixel(gx + ox, gy + oy, tcol)
	# Classic 5-digit odometer window centered below the arc
	for py in range(74, 90):
		for px in range(96, 160):
			var edge := py == 74 or py == 89 or px == 96 or px == 159
			img.set_pixel(px, py, Color(0.45, 0.47, 0.50, 1.0) if edge else Color(0.16, 0.17, 0.19, 1.0))
	for di in range(5):
		var dx0 := 101 + di * 11
		for py in range(77, 87):
			img.set_pixel(dx0 + 2, py, Color(0.92, 0.92, 0.88, 1.0))
			if (di + py) % 2 == 0:
				img.set_pixel(dx0 + 5, py, Color(0.92, 0.92, 0.88, 1.0))
	# Mini fuel bar on bottom-right & flanking vintage amber/red/green square warning blocks (Photos 1 & 2!)
	for py in range(97, 108):
		for px in range(178, 224):
			var fill_px := px < 212
			img.set_pixel(px, py, Color(0.86, 0.74, 0.24, 1.0) if (fill_px and py > 100 and py < 105) else Color(0.24, 0.26, 0.30, 1.0))
	var lamp_cols := [Color(0.92, 0.66, 0.16, 1.0), Color(0.88, 0.22, 0.18, 1.0), Color(0.24, 0.74, 0.32, 1.0)]
	for li in range(3):
		var ly0 := 28 + li * 28
		for py in range(ly0, ly0 + 18):
			for px in range(14, 30):
				img.set_pixel(px, py, lamp_cols[li])
		for py in range(ly0, ly0 + 18):
			for px in range(w - 30, w - 14):
				img.set_pixel(px, py, lamp_cols[2 - li])
	_draw_tiny_word(img, "KMH", 121, 96, Color(0.82, 0.84, 0.86, 1.0))
	_r4_dial_tex = ImageTexture.create_from_image(img)
	return _r4_dial_tex

## Swaps ONLY the Renol 4L's `Window` surface to subtle clear cab glass in 1st-person (restored cleanly in 3rd-person / on exit).
func _set_r4_cab_stripped() -> void:
	if model == null or not is_instance_valid(model):
		return
	var bmi := model.find_child("body", true, false) as MeshInstance3D
	if bmi == null or bmi.mesh == null:
		return
	_dash_body_mi = bmi
	_dash_orig_mesh = bmi.mesh
	if _yondir_glass == null:
		_yondir_glass = StandardMaterial3D.new()
		_yondir_glass.albedo_color = Color(0.08, 0.13, 0.16, 0.09)
		_yondir_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_yondir_glass.roughness = 0.08
		_yondir_glass.metallic = 0.24
		_yondir_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
		_yondir_glass.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	if not _z15_cab_meshes.has(_dash_orig_mesh):
		var orig: Mesh = _dash_orig_mesh
		var out := ArrayMesh.new()
		for s in range(orig.get_surface_count()):
			var a: Array = orig.surface_get_arrays(s)
			var mat = orig.surface_get_material(s)
			var nm := String(mat.resource_name) if mat != null else ""
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
			out.surface_set_material(s, _yondir_glass if nm.begins_with("Window") else mat)
		_z15_cab_meshes[_dash_orig_mesh] = out
	bmi.mesh = _z15_cab_meshes[_dash_orig_mesh]
	# Also clear any surface override on the Window surface while in 1st-person (restored on exit by Modelos repaint or surface override)
	for s in range(bmi.mesh.get_surface_count()):
		var mat = _dash_orig_mesh.surface_get_material(s)
		if mat != null and String(mat.resource_name).begins_with("Window"):
			bmi.set_surface_override_material(s, _yondir_glass)

## Iconic classic Renol 4L interior cockpit (Photos 1 & 2):
## bi-tone rounded black padded crash-top over cream-white painted metal dash, twin open lower shelves (folded neon-yellow
## Spanish reflective vest on passenger side, vintage road map on driver side) split by rounded central heater box,
## rectangular chromed horizontal arc speedometer (0-130 km/h live!), LIVE umbrella ("paraguas") dash-mounted gear lever
## shifting with gears & reverse, thin glossy-black 3-spoke "T" wheel with fluted chrome spokes & player hands,
## dangling 2-key ignition keychain, STANDING chromed rearview mirror bolted onto the dash top + live left wing mirror,
## and green/yellow ITV stickers in the upper-right windscreen corner!
func _build_r4_dash(eye_x: float, eye_y: float, eye_z: float) -> void:
	if _hebro_chrome == null:
		_hebro_chrome = StandardMaterial3D.new()
		_hebro_chrome.albedo_color = Color(0.86, 0.88, 0.90)
		_hebro_chrome.metallic = 0.86
		_hebro_chrome.roughness = 0.20
	if _ros_mirror == null:
		_ros_mirror = StandardMaterial3D.new()
		_ros_mirror.albedo_color = Color(0.36, 0.40, 0.46)
		_ros_mirror.metallic = 0.42
		_ros_mirror.roughness = 0.16
	if _ros_silver == null:
		_ros_silver = StandardMaterial3D.new()
		_ros_silver.albedo_color = Color(0.84, 0.86, 0.90)
		_ros_silver.metallic = 0.86
		_ros_silver.roughness = 0.22
	_dash_max_kmh = 130.0
	_dash_root = Node3D.new()
	_dash_root.name = "Renol4LDashboard"
	# Placed flush inside the Renol 4L cabin (cowl base at inner z = +0.531, y = 0.943) so speedo, T-wheel, hands & umbrella shifter frame cleanly!
	_dash_root.position = Vector3(eye_x, eye_y - 0.165, eye_z + 0.495)
	inner.add_child(_dash_root)

	# Real cabin centerline offset relative to driver's eye_x (+0.346 -> cabin center at -0.058, so cx = -0.404)
	var cx := -0.404
	var m_pad := Parts.mat(0x202226)         # plush rounded matte-black upper crash pad (Photo 1 & 2!)
	var m_cream := Parts.mat(0xdad8cf)       # classic Renault 4L cream-white painted metal dash & lower shelves
	var m_grey := Parts.mat(0x8a8e94)        # rounded central heater/blower housing
	var m_dark := Parts.mat(0x14161a)        # glossy black wheel rim, umbrella gear rod & knob
	var m_carpet := Parts.mat(0x6b4222)      # classic warm brown R4 cabin carpet (Photos 1 & 2!)
	var m_body := Parts.mat(paint)           # body-painted inner door metal trim!

	if _r4_seed < 0:
		_r4_seed = randi()
	var cof_roll := _r4_seed % 100
	# 16% each for the 6 cofrade figures (0..5 = 96%) + 4% rare easter egg with ALL 6 in a row (6)!
	_r4_cofrade = mini(6, cof_roll / 16)

	# 1) Full-width Bi-Tone Renol 4L Dashboard (door-to-door from right door cx-0.66 to left door cx+0.64)
	# Rounded black padded upper crash-pad roll + top deck
	_dash_root.add_child(_ros_part("box", m_pad, Vector3(cx, 0.032, 0.025), Vector3(1.30, 0.056, 0.135)))
	var pad_roll := _ros_part("cyl", m_pad, Vector3(cx, 0.028, -0.042), Vector3(0.032, 1.30, 0.032))
	pad_roll.rotation.z = PI / 2.0
	_dash_root.add_child(pad_roll)
	# Central rectangular air-vent / ashtray lid right on the center dash pad (Photo 2!)
	_dash_root.add_child(_ros_part("box", Parts.mat(0x2e3138), Vector3(cx + 0.01, 0.008, -0.056), Vector3(0.135, 0.048, 0.014)))
	_dash_root.add_child(_ros_part("box", m_dark, Vector3(cx + 0.01, 0.008, -0.064), Vector3(0.118, 0.034, 0.006)))
	# Cream-white painted metal lower dash fascia spanning door-to-door
	_dash_root.add_child(_ros_part("box", m_cream, Vector3(cx, -0.068, 0.012), Vector3(1.28, 0.142, 0.095)))
	# Central rounded grey heater/blower pod dividing the two lower open shelves (Photo 2!)
	_dash_root.add_child(_ros_part("box", m_grey, Vector3(cx + 0.01, -0.215, -0.010), Vector3(0.24, 0.22, 0.14)))
	_dash_root.add_child(_ros_part("box", m_cream, Vector3(cx + 0.01, -0.235, -0.085), Vector3(0.19, 0.085, 0.035)))
	# Twin open cream-white lower storage shelves (driver left + passenger right) with tubular rolled lip!
	for sh in [[0.03, 0.44], [cx - 0.36, 0.48]]:
		var sx: float = sh[0]
		var sw: float = sh[1]
		_dash_root.add_child(_ros_part("box", m_cream, Vector3(sx, -0.235, 0.005), Vector3(sw, 0.016, 0.155)))
		var sh_lip := _ros_part("cyl", m_cream, Vector3(sx, -0.228, -0.070), Vector3(0.014, sw, 0.014))
		sh_lip.rotation.z = PI / 2.0
		_dash_root.add_child(sh_lip)
	# Vintage folded road map on left shelf + folded neon-yellow Spanish reflective vest ("chaleco") on right shelf (Photo 2!)
	var map_p := _ros_part("box", Parts.mat(0xe6e2d4), Vector3(0.05, -0.218, -0.010), Vector3(0.21, 0.016, 0.105))
	map_p.rotation.y = 0.08
	_dash_root.add_child(map_p)
	_dash_root.add_child(_ros_part("box", Parts.mat(0xc83228), Vector3(0.09, -0.209, -0.010), Vector3(0.06, 0.004, 0.092)))
	_dash_root.add_child(_ros_part("box", Parts.mat(0x2e64b8), Vector3(0.01, -0.209, -0.010), Vector3(0.06, 0.004, 0.092)))
	var vest := _ros_part("box", Parts.mat(0xc8e822), Vector3(cx - 0.34, -0.212, -0.012), Vector3(0.22, 0.032, 0.11))
	vest.rotation.y = -0.10
	_dash_root.add_child(vest)
	_dash_root.add_child(_ros_part("box", Parts.mat(0xd8dde2), Vector3(cx - 0.34, -0.195, -0.012), Vector3(0.21, 0.004, 0.022)))
	# Warm brown vintage cabin floor carpet & inner body-colored door sills (strictly below pad!)
	_dash_root.add_child(_ros_part("box", m_carpet, Vector3(cx, -0.44, -0.10), Vector3(1.26, 0.03, 0.42)))
	_dash_root.add_child(_ros_part("box", m_body, Vector3(cx + 0.65, -0.22, -0.05), Vector3(0.024, 0.36, 0.28)))
	_dash_root.add_child(_ros_part("box", m_body, Vector3(cx - 0.66, -0.22, -0.05), Vector3(0.024, 0.36, 0.28)))

	# 2) Iconic Rectangular Chrome-Framed Horizontal Speedometer Pod (0-130 km/h LIVE!) + Ignition Keys (Photos 1 & 2!)
	var pod_z := -0.044
	_dash_root.add_child(_ros_part("box", m_dark, Vector3(0.0, -0.042, pod_z + 0.008), Vector3(0.224, 0.118, 0.024)))
	_dash_root.add_child(_ros_part("box", _hebro_chrome, Vector3(0.0, -0.042, pod_z + 0.002), Vector3(0.214, 0.110, 0.014)))
	_dash_dial_mat = StandardMaterial3D.new()
	var r4tex := _build_r4_dial_tex()
	_dash_dial_mat.albedo_texture = r4tex
	_dash_dial_mat.roughness = 0.36
	_dash_dial_mat.emission_enabled = true
	_dash_dial_mat.emission_texture = r4tex
	_dash_dial_mat.emission_energy_multiplier = 0.30
	var dqm := QuadMesh.new()
	dqm.size = Vector2(0.200, 0.100)
	var dq := MeshInstance3D.new()
	dq.mesh = dqm
	dq.material_override = _dash_dial_mat
	dq.position = Vector3(0.0, -0.042, pod_z - 0.006)
	dq.rotation.y = PI
	dq.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_dash_root.add_child(dq)
	# Live arc speedometer needle pivoted at the bottom-center of the horizontal pod!
	_dash_needle = Node3D.new()
	_dash_needle.name = "SpeedoNeedle"
	_dash_needle.position = Vector3(0.0, -0.084, pod_z - 0.010)
	_dash_root.add_child(_dash_needle)
	var m_needle := StandardMaterial3D.new()
	m_needle.albedo_color = Color(0.98, 0.42, 0.14)
	m_needle.emission_enabled = true
	m_needle.emission = Color(0.98, 0.42, 0.14)
	m_needle.emission_energy_multiplier = 0.55
	_dash_needle.add_child(_ros_part("box", m_needle, Vector3(0.0, 0.036, 0.0), Vector3(0.0038, 0.072, 0.0025)))
	_dash_needle.add_child(_ros_part("ball", _hebro_chrome, Vector3(0.0, 0.0, -0.001), Vector3(0.008, 0.008, 0.006)))
	_dash_speed_ang = deg_to_rad(-62.0)
	_dash_needle.rotation.z = _dash_speed_ang
	# Dangling chrome ignition barrel + 2 tiny keys hanging right below the steering column (Photos 1 & 2!)
	var ign := _ros_part("cyl", _hebro_chrome, Vector3(-0.045, -0.140, -0.042), Vector3(0.014, 0.018, 0.014))
	ign.rotation.x = PI / 2.0
	_dash_root.add_child(ign)
	_dash_root.add_child(_ros_part("ball", _ros_silver, Vector3(-0.045, -0.155, -0.052), Vector3(0.008, 0.008, 0.005)))
	var k1 := _ros_part("box", _ros_silver, Vector3(-0.049, -0.178, -0.052), Vector3(0.007, 0.032, 0.003))
	k1.rotation.z = 0.12
	_dash_root.add_child(k1)
	var k2 := _ros_part("box", Parts.mat(0xc8a44a), Vector3(-0.041, -0.176, -0.054), Vector3(0.007, 0.028, 0.003))
	k2.rotation.z = -0.15
	_dash_root.add_child(k2)

	# 3) THE LEGENDARY UMBRELLA ("PARAGUAS") DASH-MOUNTED GEAR LEVER (LIVE with gears & reverse — Photos 1 & 2!)
	# Rubber grommet on center cream fascia + curved black J-rod dipping down and curving up to shiny black ball knob!
	var grom := _ros_part("cyl", m_dark, Vector3(cx + 0.03, -0.068, -0.038), Vector3(0.032, 0.020, 0.032))
	grom.rotation.x = PI / 2.0
	_dash_root.add_child(grom)
	_r4_shifter_base = Vector3(cx + 0.03, -0.068, -0.040)
	_r4_shifter_piv = Node3D.new()
	_r4_shifter_piv.name = "UmbrellaShifter"
	_r4_shifter_piv.position = _r4_shifter_base
	_dash_root.add_child(_r4_shifter_piv)
	# Straight shaft emerging out of dash toward driver (-Z)
	var s_out := _ros_part("cyl", m_dark, Vector3(0.0, 0.0, -0.068), Vector3(0.012, 0.136, 0.012))
	s_out.rotation.x = PI / 2.0
	_r4_shifter_piv.add_child(s_out)
	# Continuous seamless J-curve elbow ("paraguas"): joint ball -> curved bottom bend -> angled stalk up into glossy knob!
	_r4_shifter_piv.add_child(_ros_part("ball", m_dark, Vector3(0.0, 0.0, -0.134), Vector3(0.013, 0.013, 0.013)))
	var s_dn := _ros_part("cyl", m_dark, Vector3(-0.010, -0.018, -0.141), Vector3(0.012, 0.044, 0.012))
	s_dn.rotation = Vector3(-0.32, 0.0, -0.46)
	_r4_shifter_piv.add_child(s_dn)
	_r4_shifter_piv.add_child(_ros_part("ball", m_dark, Vector3(-0.020, -0.036, -0.148), Vector3(0.013, 0.013, 0.013)))
	var s_up := _ros_part("cyl", m_dark, Vector3(-0.038, 0.008, -0.158), Vector3(0.012, 0.098, 0.012))
	s_up.rotation = Vector3(0.18, 0.0, 0.38)
	_r4_shifter_piv.add_child(s_up)
	# Glossy black round bakelite gear-shift ball knob
	var m_knob := StandardMaterial3D.new()
	m_knob.albedo_color = Color(0.08, 0.09, 0.11)
	m_knob.roughness = 0.16
	m_knob.metallic = 0.15
	_r4_shifter_piv.add_child(_ros_part("ball", m_knob, Vector3(-0.056, 0.052, -0.168), Vector3(0.030, 0.030, 0.030)))
	# Small black choke/heater pull lever just to the right of the shifter (Photo 2!)
	_dash_root.add_child(_ros_part("cyl", m_dark, Vector3(cx - 0.095, -0.055, -0.048), Vector3(0.009, 0.028, 0.009)))

	# 4) Classic Thin Glossy-Black 3-Spoke "T" Steering Wheel with Fluted Chrome Spokes + Player Hands (Photos 1 & 2!)
	var col_mount := Node3D.new()
	col_mount.position = Vector3(0.0, -0.095, -0.158)
	col_mount.rotation.x = deg_to_rad(20.0)   # tilted UP cleanly toward driver's eyes, leaving speedo 100% open above!
	_dash_root.add_child(col_mount)
	var shaft := _ros_part("cyl", m_dark, Vector3(0.0, 0.0, 0.068), Vector3(0.022, 0.135, 0.022))
	shaft.rotation.x = PI / 2.0
	col_mount.add_child(shaft)
	# Thin gleaming chrome left indicator stalk (Photos 1 & 2!)
	var istalk := _ros_part("cyl", _hebro_chrome, Vector3(0.068, 0.022, 0.036), Vector3(0.005, 0.115, 0.005))
	istalk.rotation.z = deg_to_rad(74.0)
	col_mount.add_child(istalk)

	_dash_wheel = Node3D.new()
	_dash_wheel.name = "Renol4LWheel"
	col_mount.add_child(_dash_wheel)
	if _r4_rim_mesh == null:
		_r4_rim_mesh = TorusMesh.new()
		_r4_rim_mesh.inner_radius = 0.146
		_r4_rim_mesh.outer_radius = 0.159
		_r4_rim_mesh.rings = 32
		_r4_rim_mesh.ring_segments = 10
	var rim := MeshInstance3D.new()
	rim.mesh = _r4_rim_mesh
	rim.material_override = m_knob
	rim.rotation.x = PI / 2.0
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_dash_wheel.add_child(rim)
	# 3 thin "T" spokes (9, 3, and 6 o'clock — keeping top 180 deg wide open for the horizontal chrome speedo!)
	for sang_deg: float in [98.0, -98.0, 180.0]:
		var sa := deg_to_rad(sang_deg)
		var sp := _ros_part("box", m_knob, Vector3(-sin(sa) * 0.078, cos(sa) * 0.078, 0.005), Vector3(0.017, 0.146, 0.011))
		sp.rotation.z = sa
		_dash_wheel.add_child(sp)
		var sp_chr := _ros_part("box", _hebro_chrome, Vector3(-sin(sa) * 0.078, cos(sa) * 0.078, -0.001), Vector3(0.007, 0.132, 0.004))
		sp_chr.rotation.z = sa
		_dash_wheel.add_child(sp_chr)
	# Classic round chrome-ringed horn boss in the center (clean retro disc, no trademark!)
	var hub := _ros_part("cyl", m_knob, Vector3(0.0, 0.0, -0.004), Vector3(0.042, 0.022, 0.042))
	hub.rotation.x = PI / 2.0
	_dash_wheel.add_child(hub)
	var hring := _ros_part("cyl", _hebro_chrome, Vector3(0.0, 0.0, -0.014), Vector3(0.036, 0.006, 0.036))
	hring.rotation.x = PI / 2.0
	_dash_wheel.add_child(hring)
	var hcap := _ros_part("cyl", m_dark, Vector3(0.0, 0.0, -0.017), Vector3(0.028, 0.004, 0.028))
	hcap.rotation.x = PI / 2.0
	_dash_wheel.add_child(hcap)
	# Player's hands gripping the thin rim at 9:30 and 2:30 (rotating solidly with steering!)
	var skin_hex: int = int(riders[0].get("skin", 0xf6c9a0))
	var m_skin := Parts.mat(skin_hex)
	var grip_r := 0.152
	var grip_ang := deg_to_rad(72.0)
	for sgn: float in [1.0, -1.0]:
		var hand := Node3D.new()
		hand.name = "WheelHandL" if sgn > 0.0 else "WheelHandR"
		hand.position = Vector3(sgn * grip_r * sin(grip_ang), grip_r * cos(grip_ang), -0.007)
		hand.rotation.z = sgn * grip_ang
		hand.add_child(_ros_part("ball", m_skin, Vector3.ZERO, Vector3(0.024, 0.032, 0.022)))
		var thumb := _ros_part("ball", m_skin, Vector3(-0.011 * sgn, 0.025, -0.007), Vector3(0.010, 0.016, 0.010))
		thumb.rotation.z = sgn * 0.25
		hand.add_child(thumb)
		_dash_wheel.add_child(hand)

	# 5) ICONIC STANDING DASH-MOUNTED CHROMED REARVIEW MIRROR (Photo 2!) + LIVE LEFT WING MIRROR + ITV STICKERS!
	_rosary_root = Node3D.new()
	_rosary_root.name = "Renol4LMirror"
	# Bolted right on TOP of the black dash pad on a curved chrome pedestal stalk (NOT hanging from roof!)
	_rosary_root.position = _dash_root.position + Vector3(cx + 0.05, 0.118, 0.010)
	inner.add_child(_rosary_root)
	# Round dark base flange bolted to top of dash pad + curved chrome pedestal stalk going UP to mirror
	var mbase := _ros_part("cyl", m_dark, Vector3(0.0, -0.062, 0.008), Vector3(0.028, 0.010, 0.028))
	_rosary_root.add_child(mbase)
	var mstalk := _ros_part("cyl", _hebro_chrome, Vector3(0.0, -0.034, 0.008), Vector3(0.008, 0.058, 0.008))
	mstalk.rotation.x = 0.18
	_rosary_root.add_child(mstalk)
	# Classic rounded-corner silver-rimmed mirror housing
	_rosary_root.add_child(_ros_part("box", _hebro_chrome, Vector3(0.0, 0.0, 0.0), Vector3(0.168, 0.058, 0.016)))
	_rosary_root.add_child(_ros_part("box", m_dark, Vector3(0.0, 0.0, 0.004), Vector3(0.162, 0.052, 0.012)))
	var r4glass: StandardMaterial3D = _ros_mirror
	if DisplayServer.get_name() != "headless":
		_mirror_vp = SubViewport.new()
		_mirror_vp.name = "MirrorViewport"
		_mirror_vp.size = Vector2i(192, 64)
		_mirror_vp.world_3d = get_world_3d()
		_mirror_vp.positional_shadow_atlas_size = 0
		_mirror_vp.msaa_3d = Viewport.MSAA_DISABLED
		_mirror_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		_mirror_vp.use_debanding = false
		_mirror_vp.transparent_bg = false
		_mirror_vp.audio_listener_enable_2d = false
		_mirror_vp.audio_listener_enable_3d = false
		_mirror_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if _fp_hide_head else SubViewport.UPDATE_DISABLED
		_rosary_root.add_child(_mirror_vp)
		_mirror_cam = Camera3D.new()
		_mirror_cam.name = "MirrorCamera"
		_mirror_cam.fov = 28.0
		_mirror_cam.near = 0.2
		_mirror_cam.far = 90.0
		_mirror_cam.current = true
		_mirror_vp.add_child(_mirror_cam)
		_mirror_anchor = RemoteTransform3D.new()
		_mirror_anchor.name = "MirrorCamAnchor"
		_mirror_anchor.position = Vector3(-0.058, 1.24, -1.90)
		_mirror_anchor.rotation.x = deg_to_rad(-3.0)
		_mirror_anchor.update_scale = false
		inner.add_child(_mirror_anchor)
		_mirror_anchor.remote_path = _mirror_cam.get_path()
		_mirror_anchor.force_update_cache()
		r4glass = StandardMaterial3D.new()
		r4glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		r4glass.albedo_texture = _mirror_vp.get_texture()
		r4glass.albedo_color = Color(0.92, 0.96, 1.0)
		r4glass.uv1_scale = Vector3(-1.0, 1.0, 1.0)
		r4glass.uv1_offset = Vector3(1.0, 0.0, 0.0)
		r4glass.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	var rmq := MeshInstance3D.new()
	var rqm := QuadMesh.new()
	rqm.size = Vector2(0.156, 0.048)
	rmq.mesh = rqm
	rmq.material_override = r4glass
	rmq.position = Vector3(0.0, 0.0, -0.009)
	rmq.rotation.y = PI
	rmq.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rosary_root.add_child(rmq)

	# Tiny horizontal Spanish ITV stickers tucked in the upper-right windscreen corner (just like Photo 2!)
	var r4_itv0 := _make_itv_sticker(0x34a842)
	r4_itv0.position = Vector3(cx - 0.42, 0.42, -0.065)
	r4_itv0.rotation = Vector3(deg_to_rad(16.0), PI, 0.0)
	_dash_root.add_child(r4_itv0)
	var r4_itv1 := _make_itv_sticker(0xe8d028)
	r4_itv1.position = Vector3(cx - 0.478, 0.418, -0.065)
	r4_itv1.rotation = Vector3(deg_to_rad(16.0), PI, deg_to_rad(1.5))
	_dash_root.add_child(r4_itv1)

	# 5b) Chibi Semana Santa de Madridejos Cofrade figurine(s) on varnished pedestal perched on top of the black dash pad!
	# 16% each among the 6 figures (Cristo, Santo Sepulcro, Nazareno blanco, Nazareno morado, San Juan, Soledad) + 4% ALL 6 in a row!
	if _r4_cofrade == 6:
		var row_root := Node3D.new()
		row_root.name = "CofradesTodos"
		_dash_root.add_child(row_root)
		for ci in range(6):
			var fig := _build_r4_cofrade(ci)
			fig.scale = Vector3(0.86, 0.86, 0.86)
			fig.position = Vector3(0.055 - ci * 0.051, 0.060, -0.006)
			fig.rotation.y = deg_to_rad(-10.0)
			row_root.add_child(fig)
	else:
		var cof := _build_r4_cofrade(_r4_cofrade)
		cof.position = Vector3(cx + 0.195, 0.060, -0.004)
		cof.rotation.y = deg_to_rad(-14.0)
		_dash_root.add_child(cof)

	# 6) Live Functional Left Wing Mirror flush on our Blender door mirror housing (full game FPS in 1st-person)
	if DisplayServer.get_name() != "headless":
		_side_mirror_vp = SubViewport.new()
		_side_mirror_vp.name = "SideMirrorViewport"
		_side_mirror_vp.size = Vector2i(96, 72)
		_side_mirror_vp.world_3d = get_world_3d()
		_side_mirror_vp.positional_shadow_atlas_size = 0
		_side_mirror_vp.msaa_3d = Viewport.MSAA_DISABLED
		_side_mirror_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		_side_mirror_vp.use_debanding = false
		_side_mirror_vp.transparent_bg = false
		_side_mirror_vp.audio_listener_enable_2d = false
		_side_mirror_vp.audio_listener_enable_3d = false
		_side_mirror_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if _fp_hide_head else SubViewport.UPDATE_DISABLED
		_rosary_root.add_child(_side_mirror_vp)
		_side_mirror_cam = Camera3D.new()
		_side_mirror_cam.name = "SideMirrorCamera"
		_side_mirror_cam.fov = 38.0
		_side_mirror_cam.near = 0.2
		_side_mirror_cam.far = 90.0
		_side_mirror_cam.current = true
		_side_mirror_vp.add_child(_side_mirror_cam)
		_side_mirror_anchor = RemoteTransform3D.new()
		_side_mirror_anchor.name = "SideMirrorCamAnchor"
		_side_mirror_anchor.position = Vector3(0.86, 1.02, 0.28)
		_side_mirror_anchor.rotation = Vector3(deg_to_rad(-3.0), deg_to_rad(-8.0), 0.0)
		_side_mirror_anchor.update_scale = false
		inner.add_child(_side_mirror_anchor)
		_side_mirror_anchor.remote_path = _side_mirror_cam.get_path()
		_side_mirror_anchor.force_update_cache()
		var r4smat := StandardMaterial3D.new()
		r4smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		r4smat.albedo_texture = _side_mirror_vp.get_texture()
		r4smat.albedo_color = Color(0.92, 0.96, 1.0)
		r4smat.uv1_scale = Vector3(-1.0, 1.0, 1.0)
		r4smat.uv1_offset = Vector3(1.0, 0.0, 0.0)
		r4smat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		var smq := MeshInstance3D.new()
		smq.name = "LeftSideMirrorGlass"
		var r4sqm := QuadMesh.new()
		r4sqm.size = Vector2(0.092, 0.058)
		smq.mesh = r4sqm
		smq.material_override = r4smat
		smq.position = Vector3(0.774, 1.017, 0.362) - _dash_root.position
		smq.rotation.y = PI + deg_to_rad(8.5)
		smq.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_dash_root.add_child(smq)

## Builds one of the 6 iconic Semana Santa de Madridejos Chibi Cofrade figurines on a varnished wooden pedestal
## (0 = Cristo, 1 = Santo Sepulcro, 2 = Nazareno blanco, 3 = Nazareno morado, 4 = San Juan, 5 = Soledad). Faces -Z (toward driver).
## Note: Parts.mesh("cyl") & "ball" have radius=1.0 (diameter=2*scale); "head" has radius=0.5 (diameter=scale); "box" has size=scale.
static func _build_r4_cofrade(idx: int) -> Node3D:
	var root := Node3D.new()
	var names := ["CofradeCristo", "CofradeSantoSepulcro", "CofradeNazareno", "CofradeNazarenoMorado", "CofradeSanJuan", "CofradeSoledad"]
	root.name = names[clampi(idx, 0, 5)]

	var m_wood := Parts.mat(0x422414)
	var m_gold := Parts.mat(0xe4ba36)
	var m_silver := Parts.mat(0xdce2e8)
	var m_white := Parts.mat(0xf2ede2)
	var m_black := Parts.mat(0x16181c)
	var m_glove := Parts.mat(0xf8f6f0)
	var m_burg := Parts.mat(0x641424)
	var m_red := Parts.mat(0xc81c26)
	var m_purp := Parts.mat(0x441a78)
	var m_brown := Parts.mat(0x5e3418)
	var m_skin := Parts.mat(0xf5c69e)
	var m_cheek := Parts.mat(0xee968c)
	var m_hair := Parts.mat(0x302016)

	# 1) Varnished wooden round pedestal base (diameter 5.0 cm) with golden trim ring
	root.add_child(_ros_part("cyl", m_wood, Vector3(0.0, 0.005, 0.0), Vector3(0.025, 0.010, 0.025)))
	root.add_child(_ros_part("cyl", m_gold, Vector3(0.0, 0.0105, 0.0), Vector3(0.023, 0.0025, 0.023)))

	var m_tunic: Material = m_white
	var m_cape: Material = m_white
	var m_hood: Material = m_white
	var m_sash: Material = m_gold
	var has_capirote := true
	var has_cape := true
	match idx:
		0: # Cristo: burgundy tunic, cape & capirote, gold cord, white chest cross, wooden cross staff
			m_tunic = m_burg; m_cape = m_burg; m_hood = m_burg; m_sash = m_gold
		1: # Santo Sepulcro: ivory tunic & cape, crimson sash, uncovered Chibi head + white birrete cap, lit candle
			m_tunic = m_white; m_cape = m_white; m_hood = m_white; m_sash = m_red; has_capirote = false
		2: # Nazareno (capa blanca): deep purple tunic, white cape & capirote, purple Maltese cross, gold cord, lit golden lantern
			m_tunic = m_purp; m_cape = m_white; m_hood = m_white; m_sash = m_gold
		3: # Nazareno (morado completo): purple tunic with white button row, purple capirote with white Maltese cross, gold cord, lit golden lantern
			m_tunic = m_purp; m_cape = m_purp; m_hood = m_purp; m_sash = m_gold; has_cape = false
		4: # San Juan: white tunic, red cape, white capirote with red Maltese cross, red sash, golden cross staff
			m_tunic = m_white; m_cape = m_red; m_hood = m_white; m_sash = m_red
		5: # Soledad: white tunic, black cape & capirote with red/silver heart, black sash, ornate silver staff
			m_tunic = m_white; m_cape = m_black; m_hood = m_black; m_sash = m_black

	# 2) Cute Chibi shoes peeking out + bell-shaped Chibi tunic ("body" mesh) + optional flowing cape behind!
	for sx: float in [-0.007, 0.007]:
		root.add_child(_ros_part("ball", m_black, Vector3(sx, 0.014, -0.010), Vector3(0.0045, 0.0032, 0.0060)))
	# Tapered Chibi tunic (y = 0.011 .. 0.053, bottom r=0.0185, top r=0.0125)
	root.add_child(_ros_part("body", m_tunic, Vector3(0.0, 0.032, 0.0), Vector3(0.042, 0.056, 0.038)))
	if has_cape:
		# Flowing cape wrapped around back & sides
		root.add_child(_ros_part("body", m_cape, Vector3(0.0, 0.033, 0.0045), Vector3(0.047, 0.057, 0.036)))
		for sx: float in [-1.0, 1.0]:
			var flap := _ros_part("box", m_cape, Vector3(sx * 0.0155, 0.032, -0.001), Vector3(0.0055, 0.040, 0.016))
			flap.rotation.z = sx * 0.14
			root.add_child(flap)
	# Waist sash / cord (cíngulo) + dangling tassel in center!
	var sash_h := 0.0034 if (idx == 0 or idx == 2 or idx == 3) else 0.0068
	root.add_child(_ros_part("cyl", m_sash, Vector3(0.0, 0.037, -0.001), Vector3(0.0152, sash_h, 0.0142)))
	root.add_child(_ros_part("cyl", m_sash, Vector3(0.001, 0.026, -0.0152), Vector3(0.0016, 0.018, 0.0016)))
	root.add_child(_ros_part("ball", m_sash, Vector3(0.001, 0.016, -0.0155), Vector3(0.0028, 0.0036, 0.0028)))
	# Vertical front button row on Nazareno morado (white buttons), San Juan (red buttons) & Soledad (black buttons)
	if idx == 3 or idx == 4 or idx == 5:
		var m_btn: Material = m_white if idx == 3 else (m_red if idx == 4 else m_black)
		for bi in range(4):
			root.add_child(_ros_part("ball", m_btn, Vector3(-0.002, 0.016 + bi * 0.0055, -0.0162), Vector3(0.0012, 0.0012, 0.0012)))

	# 3) Chibi Head: tall cute Capirote with peering eyes + crisp chest emblem, OR uncovered Santo Sepulcro with birrete!
	if has_capirote:
		var caperuz := MeshInstance3D.new()
		var cpm := CylinderMesh.new()
		cpm.top_radius = 0.0125
		cpm.bottom_radius = 0.0195
		cpm.height = 0.020
		cpm.radial_segments = 16
		caperuz.mesh = cpm
		caperuz.material_override = m_hood
		caperuz.position = Vector3(0.0, 0.053, 0.0)
		caperuz.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(caperuz)
		var bib := _ros_part("box", m_hood, Vector3(0.0, 0.049, -0.0145), Vector3(0.022, 0.018, 0.005))
		bib.rotation.x = 0.16
		root.add_child(bib)
		root.add_child(_ros_part("head", m_hood, Vector3(0.0, 0.071, 0.0), Vector3(0.028, 0.027, 0.028)))
		var cone := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0016
		cm.bottom_radius = 0.0136
		cm.height = 0.050
		cm.radial_segments = 16
		cone.mesh = cm
		cone.material_override = m_hood
		cone.position = Vector3(0.0, 0.098, 0.0)
		cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(cone)
		# Two expressive peering eye slits cleanly ON the front face (z = -0.0140)
		for ex: float in [-0.0046, 0.0046]:
			root.add_child(_ros_part("ball", m_black, Vector3(ex, 0.072, -0.0138), Vector3(0.0022, 0.0018, 0.0012)))
			root.add_child(_ros_part("ball", m_skin if idx == 5 else m_white, Vector3(ex, 0.072, -0.0146), Vector3(0.0009, 0.0009, 0.0008)))
		# Cofradía chest emblem standing crisply in front of the bib (z = -0.0182)!
		if idx == 0: # Cristo: white cross emblem
			root.add_child(_ros_part("box", m_white, Vector3(0.0, 0.050, -0.0182), Vector3(0.0032, 0.0125, 0.0024)))
			root.add_child(_ros_part("box", m_white, Vector3(0.0, 0.0525, -0.0182), Vector3(0.0095, 0.0032, 0.0024)))
		elif idx == 2 or idx == 3 or idx == 4: # Nazareno blanco (purple), Nazareno morado (white), San Juan (red): Maltese cross!
			var m_cr: Material = m_purp if idx == 2 else (m_white if idx == 3 else m_red)
			root.add_child(_ros_part("box", m_cr, Vector3(0.0, 0.050, -0.0182), Vector3(0.0042, 0.0125, 0.0024)))
			root.add_child(_ros_part("box", m_cr, Vector3(0.0, 0.050, -0.0182), Vector3(0.0125, 0.0042, 0.0024)))
			for cx2: float in [-0.0036, 0.0036]:
				for cy2: float in [-0.0036, 0.0036]:
					root.add_child(_ros_part("box", m_cr, Vector3(cx2, 0.050 + cy2, -0.0180), Vector3(0.0032, 0.0032, 0.0020)))
		elif idx == 5: # Soledad: crimson heart + silver dagger emblem!
			root.add_child(_ros_part("ball", m_red, Vector3(0.0, 0.050, -0.0182), Vector3(0.0038, 0.0038, 0.0018)))
			var dag := _ros_part("box", m_silver, Vector3(0.0015, 0.051, -0.0195), Vector3(0.0018, 0.011, 0.0018))
			dag.rotation.z = -0.62
			root.add_child(dag)
	else:
		# Santo Sepulcro: adorable uncovered Chibi head + red neck cord + white Caballero birrete cap with golden cross!
		root.add_child(_ros_part("box", m_red, Vector3(0.0, 0.052, -0.0138), Vector3(0.0032, 0.011, 0.0025)))
		root.add_child(_ros_part("head", m_skin, Vector3(0.0, 0.068, 0.0), Vector3(0.030, 0.029, 0.029)))
		root.add_child(_ros_part("head", m_hair, Vector3(0.0, 0.071, 0.003), Vector3(0.030, 0.025, 0.026)))
		for ex: float in [-0.0056, 0.0056]:
			root.add_child(_ros_part("ball", m_black, Vector3(ex, 0.068, -0.0144), Vector3(0.0020, 0.0024, 0.0012)))
			root.add_child(_ros_part("box", m_hair, Vector3(ex, 0.0722, -0.0142), Vector3(0.0046, 0.0013, 0.0012)))
			root.add_child(_ros_part("ball", m_cheek, Vector3(ex * 1.45, 0.0645, -0.0136), Vector3(0.0022, 0.0014, 0.0010)))
		root.add_child(_ros_part("cyl", m_white, Vector3(0.0, 0.083, 0.0), Vector3(0.0145, 0.010, 0.0145)))
		root.add_child(_ros_part("cyl", m_white, Vector3(0.0, 0.089, 0.0), Vector3(0.0170, 0.005, 0.0170)))
		root.add_child(_ros_part("box", m_gold, Vector3(0.0, 0.086, -0.0158), Vector3(0.0024, 0.0075, 0.0022)))
		root.add_child(_ros_part("box", m_gold, Vector3(0.0, 0.086, -0.0158), Vector3(0.0068, 0.0024, 0.0022)))

	# 4) White-gloved Chibi hands + signature processional attribute of each cofradía!
	var m_flame := StandardMaterial3D.new()
	m_flame.albedo_color = Color(1.0, 0.86, 0.28)
	m_flame.emission_enabled = true
	m_flame.emission = Color(1.0, 0.72, 0.16)
	m_flame.emission_energy_multiplier = 1.6
	if idx == 1: # Santo Sepulcro: holding a lit cream wax candle diagonally across chest!
		root.add_child(_ros_part("ball", m_glove, Vector3(0.011, 0.041, -0.016), Vector3(0.0042, 0.0042, 0.0042)))
		root.add_child(_ros_part("ball", m_glove, Vector3(-0.005, 0.045, -0.017), Vector3(0.0042, 0.0042, 0.0042)))
		var cdl := _ros_part("cyl", Parts.mat(0xf5ecd2), Vector3(-0.006, 0.049, -0.019), Vector3(0.0026, 0.042, 0.0026))
		cdl.rotation.z = 0.58
		root.add_child(cdl)
		root.add_child(_ros_part("ball", m_flame, Vector3(-0.018, 0.068, -0.019), Vector3(0.0032, 0.0052, 0.0032)))
	else:
		var hx := 0.020
		root.add_child(_ros_part("ball", m_glove, Vector3(hx, 0.043, -0.013), Vector3(0.0046, 0.0046, 0.0046)))
		root.add_child(_ros_part("ball", m_glove, Vector3(-0.016, 0.040, -0.012), Vector3(0.0042, 0.0042, 0.0042)))
		if idx == 0: # Cristo: wooden staff with white cross at top
			root.add_child(_ros_part("cyl", m_brown, Vector3(hx, 0.044, -0.015), Vector3(0.0018, 0.062, 0.0018)))
			root.add_child(_ros_part("box", m_white, Vector3(hx, 0.077, -0.015), Vector3(0.0046, 0.019, 0.0036)))
			root.add_child(_ros_part("box", m_white, Vector3(hx, 0.080, -0.015), Vector3(0.0155, 0.0046, 0.0036)))
		elif idx == 2 or idx == 3: # Both Nazareno variants: white/ivory pole with glowing golden lantern at top!
			root.add_child(_ros_part("cyl", m_white, Vector3(hx, 0.040, -0.015), Vector3(0.0019, 0.056, 0.0019)))
			root.add_child(_ros_part("box", m_gold, Vector3(hx, 0.068, -0.015), Vector3(0.012, 0.0032, 0.012)))
			root.add_child(_ros_part("cyl", m_flame, Vector3(hx, 0.075, -0.015), Vector3(0.0052, 0.012, 0.0052)))
			root.add_child(_ros_part("box", m_gold, Vector3(hx, 0.082, -0.015), Vector3(0.013, 0.004, 0.013)))
			root.add_child(_ros_part("ball", m_gold, Vector3(hx, 0.086, -0.015), Vector3(0.0028, 0.0028, 0.0028)))
		elif idx == 4: # San Juan: golden scepter topped with ornate golden cross
			root.add_child(_ros_part("cyl", m_gold, Vector3(hx, 0.048, -0.015), Vector3(0.0018, 0.072, 0.0018)))
			root.add_child(_ros_part("box", m_gold, Vector3(hx, 0.087, -0.015), Vector3(0.0042, 0.017, 0.0032)))
			root.add_child(_ros_part("box", m_gold, Vector3(hx, 0.090, -0.015), Vector3(0.014, 0.0042, 0.0032)))
		else: # Soledad: ornate silver scepter with sunburst medallion top
			root.add_child(_ros_part("cyl", m_silver, Vector3(hx, 0.048, -0.015), Vector3(0.0019, 0.072, 0.0019)))
			root.add_child(_ros_part("ball", m_silver, Vector3(hx, 0.087, -0.015), Vector3(0.0060, 0.0078, 0.0026)))
			root.add_child(_ros_part("ball", m_red, Vector3(hx, 0.087, -0.0175), Vector3(0.0026, 0.0026, 0.0014)))
	return root

## Procedural 256x128 Veglia-style Citroën C15 instrument cluster texture (0-120 km/h dial + odometer + fuel/temp bars)
static func _build_dash_dial_tex() -> ImageTexture:
	if _dash_dial_tex != null:
		return _dash_dial_tex
	var w := 256
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.09, 0.10, 0.12, 1.0))
	# Outer dark-grey bezel border
	var bezel := Color(0.24, 0.26, 0.29, 1.0)
	for x in range(w):
		for dy in range(4):
			img.set_pixel(x, dy, bezel)
			img.set_pixel(x, h - 1 - dy, bezel)
	for y in range(h):
		for dx in range(4):
			img.set_pixel(dx, y, bezel)
			img.set_pixel(w - 1 - dx, y, bezel)
	# Speedometer dial centered at (cx=96, cy=66), radius 50
	var cx := 96.0
	var cy := 68.0
	var rad := 50.0
	var face := Color(0.05, 0.06, 0.07, 1.0)
	var ring := Color(0.55, 0.58, 0.62, 1.0)
	for py in range(h):
		for px in range(w):
			var d := Vector2(px - cx, py - cy).length()
			if d <= rad:
				img.set_pixel(px, py, ring if d > rad - 2.2 else face)
	# Speedometer ticks: 0 to 120 km/h across -125 deg to +125 deg (0 deg = straight UP)
	for kmh in range(0, 125, 5):
		var frac := float(kmh) / 120.0
		var ang := deg_to_rad(lerpf(-125.0, 125.0, frac))
		var major := kmh % 20 == 0
		var mid := kmh % 10 == 0
		var r_in := rad - (11.0 if major else (7.5 if mid else 4.5))
		var r_out := rad - 2.5
		var tcol := Color(0.92, 0.25, 0.18, 1.0) if kmh >= 100 else (Color(0.95, 0.94, 0.88, 1.0) if major else Color(0.72, 0.74, 0.76, 1.0))
		var thick := 2 if major else 1
		var steps := 16
		for s in range(steps + 1):
			var rr := lerpf(r_in, r_out, float(s) / float(steps))
			var gx := int(round(cx + sin(ang) * rr))
			var gy := int(round(cy - cos(ang) * rr))
			for ox in range(-thick / 2, thick / 2 + 1):
				for oy in range(-thick / 2, thick / 2 + 1):
					if gx + ox >= 0 and gx + ox < w and gy + oy >= 0 and gy + oy < h:
						img.set_pixel(gx + ox, gy + oy, tcol)
	# Little 5-digit odometer window under center hub
	for py in range(88, 100):
		for px in range(74, 118):
			img.set_pixel(px, py, Color(0.18, 0.19, 0.21, 1.0) if (py == 88 or py == 99 or px == 74 or px == 117) else Color(0.86, 0.85, 0.80, 1.0))
	for d_i in range(5):
		var dx0 := 77 + d_i * 8
		for py in range(91, 97):
			img.set_pixel(dx0 + 2, py, Color(0.12, 0.12, 0.14, 1.0))
			if (d_i + py) % 2 == 0:
				img.set_pixel(dx0 + 4, py, Color(0.12, 0.12, 0.14, 1.0))
	# Right-hand cluster: Fuel gauge bar (upper) & Coolant temp bar (lower) + classic indicator squares
	for bar_i in range(2):
		var bx0 := 166
		var by0 := 28 if bar_i == 0 else 60
		for py in range(by0, by0 + 18):
			for px in range(bx0, bx0 + 70):
				img.set_pixel(px, py, Color(0.05, 0.06, 0.07, 1.0))
		for k in range(6):
			var tx := bx0 + 6 + k * 11
			var tc := Color(0.92, 0.30, 0.18, 1.0) if (bar_i == 0 and k == 0) or (bar_i == 1 and k == 5) else Color(0.88, 0.88, 0.84, 1.0)
			for py in range(by0 + 3, by0 + 13):
				img.set_pixel(tx, py, tc)
				img.set_pixel(tx + 1, py, tc)
		# Orange indicator bar
		var fill_x := bx0 + (46 if bar_i == 0 else 32)
		for py in range(by0 + 6, by0 + 15):
			for px in range(fill_x, fill_x + 4):
				img.set_pixel(px, py, Color(0.98, 0.42, 0.14, 1.0))
	# Classic bottom warning-lamp row (battery red, oil amber, glowplug orange, beams blue)
	var lamps := [Color(0.65, 0.14, 0.14, 1.0), Color(0.75, 0.48, 0.10, 1.0), Color(0.15, 0.52, 0.22, 1.0), Color(0.14, 0.36, 0.72, 1.0)]
	for li in range(lamps.size()):
		var lx0 := 166 + li * 18
		for py in range(92, 106):
			for px in range(lx0, lx0 + 13):
				img.set_pixel(px, py, lamps[li])
	_dash_dial_tex = ImageTexture.create_from_image(img)
	return _dash_dial_tex

## Iconic 80s Citroën C15 grey plastic dashboard, hooded speedometer with live needle, vents, cassette radio & single-spoke wheel
func _build_z15_dash(eye_x: float, eye_y: float, eye_z: float) -> void:
	_dash_root = Node3D.new()
	_dash_root.name = "Z15Dashboard"
	_dash_root.position = Vector3(0.0, eye_y - 0.225, eye_z + 0.44)
	inner.add_child(_dash_root)

	var m_top := Parts.mat(0x696d73)        # upper grey shelf plastic
	var m_face := Parts.mat(0x82878e)       # mid-grey dash face (matching the C15 photo)
	var m_roll := Parts.mat(0x757a82)       # padded upper/lower rounded grey roll
	var m_dark := Parts.mat(0x282b30)       # dark recesses, vents, console, stalks
	var m_slat := Parts.mat(0x44484f)       # air vent louvers & trim frames
	var m_trim := Parts.mat(0x9ca2aa)       # light silver-grey trim bar & wheel spoke
	var m_wheel := Parts.mat(0x363a40)      # steering wheel rim & hub

	# 1) Full-width C15 dashboard shelf + dark firewall backing (no gaps under dash) + rounded top brow roll (split around the instrument binnacle so dial is 100% clear)
	_dash_root.add_child(_ros_part("box", m_top, Vector3(0.0, 0.022, 0.10), Vector3(1.46, 0.036, 0.32)))
	_dash_root.add_child(_ros_part("box", m_dark, Vector3(0.0, -0.17, 0.085), Vector3(1.44, 0.36, 0.03)))
	# Right/center brow roll (from right door x=-0.73 to right edge of binnacle button pod)
	var r_end: float = eye_x - 0.22
	var r_len: float = r_end - (-0.73)
	var brow_r := _ros_part("cyl", m_roll, Vector3((-0.73 + r_end) * 0.5, 0.024, -0.056), Vector3(0.021, r_len, 0.021))
	brow_r.rotation.z = PI / 2.0
	_dash_root.add_child(brow_r)
	# Far-left brow roll (from left edge of binnacle to left A-pillar)
	var l_start: float = eye_x + 0.175
	var l_len: float = 0.73 - l_start
	if l_len > 0.02:
		var brow_l := _ros_part("cyl", m_roll, Vector3((l_start + 0.73) * 0.5, 0.024, -0.056), Vector3(0.021, l_len, 0.021))
		brow_l.rotation.z = PI / 2.0
		_dash_root.add_child(brow_l)
	_dash_root.add_child(_ros_part("box", m_face, Vector3(0.0, -0.068, -0.032), Vector3(1.44, 0.165, 0.060)))

	# 2) Passenger side: recessed silver-grey badge strip, padded lower bolster, open parcel shelf ("guantera abierta")
	_dash_root.add_child(_ros_part("box", m_dark, Vector3(-0.32, -0.028, -0.064), Vector3(0.32, 0.042, 0.010)))
	_dash_root.add_child(_ros_part("box", m_trim, Vector3(-0.32, -0.028, -0.067), Vector3(0.29, 0.030, 0.008)))
	var low_roll := _ros_part("cyl", m_roll, Vector3(-0.38, -0.105, -0.072), Vector3(0.028, 0.64, 0.028))
	low_roll.rotation.z = PI / 2.0
	_dash_root.add_child(low_roll)
	_dash_root.add_child(_ros_part("box", m_dark, Vector3(-0.38, -0.155, -0.015), Vector3(0.62, 0.085, 0.14)))
	_dash_root.add_child(_ros_part("box", m_top, Vector3(-0.38, -0.195, -0.025), Vector3(0.64, 0.018, 0.18)))

	# 3) Iconic square slatted air vents: double central vents + right passenger vent
	for vx in [0.075, -0.020, -0.58]:
		var vw := 0.082 if vx > -0.3 else 0.105
		var vh := 0.072 if vx > -0.3 else 0.082
		_dash_root.add_child(_ros_part("box", m_trim, Vector3(vx, -0.018, -0.064), Vector3(vw + 0.014, vh + 0.014, 0.010)))
		_dash_root.add_child(_ros_part("box", m_dark, Vector3(vx, -0.018, -0.067), Vector3(vw, vh, 0.008)))
		for sy in [-0.022, -0.007, 0.007, 0.022]:
			_dash_root.add_child(_ros_part("box", m_slat, Vector3(vx, -0.018 + sy, -0.070), Vector3(vw - 0.006, 0.004, 0.006)))
		_dash_root.add_child(_ros_part("box", m_slat, Vector3(vx, -0.018, -0.070), Vector3(0.005, vh - 0.006, 0.006)))

	# 4) Center lower console: 80s cassette radio + glowing amber tuner + red/blue heater sliders + gear stick
	_dash_root.add_child(_ros_part("box", m_dark, Vector3(0.025, -0.175, -0.064), Vector3(0.21, 0.18, 0.075)))
	# Heater sliders (blue cold / red hot)
	_dash_root.add_child(_ros_part("box", Parts.mat(0x2e6dd6), Vector3(0.065, -0.115, -0.103), Vector3(0.055, 0.010, 0.006)))
	_dash_root.add_child(_ros_part("box", Parts.mat(0xd43b2f), Vector3(-0.015, -0.115, -0.103), Vector3(0.055, 0.010, 0.006)))
	# 80s cassette radio face + warm amber frequency band + knobs
	_dash_root.add_child(_ros_part("box", Parts.mat(0x1a1c20), Vector3(0.025, -0.175, -0.103), Vector3(0.165, 0.052, 0.008)))
	var radio_glow := StandardMaterial3D.new()
	radio_glow.albedo_color = Color(0.95, 0.62, 0.18)
	radio_glow.emission_enabled = true
	radio_glow.emission = Color(0.95, 0.58, 0.14)
	radio_glow.emission_energy_multiplier = 0.7
	_dash_root.add_child(_ros_part("box", radio_glow, Vector3(0.025, -0.166, -0.108), Vector3(0.095, 0.012, 0.004)))
	for kx in [0.092, -0.042]:
		var knob := _ros_part("cyl", m_slat, Vector3(kx, -0.175, -0.109), Vector3(0.010, 0.012, 0.010))
		knob.rotation.x = PI / 2.0
		_dash_root.add_child(knob)
	# Floor gear stick ("palanca de cambios") on driver's right
	var stick := _ros_part("cyl", m_dark, Vector3(0.11, -0.27, -0.15), Vector3(0.008, 0.18, 0.008))
	stick.rotation.x = -0.18
	_dash_root.add_child(stick)
	_dash_root.add_child(_ros_part("ball", m_wheel, Vector3(0.11, -0.18, -0.166), Vector3(0.024, 0.026, 0.024)))

	# 5) Hooded instrument binnacle ("visera") right in front of the driver + live working speedometer!
	var bin := Node3D.new()
	bin.name = "SpeedoBinnacle"
	bin.position = Vector3(eye_x, 0.068, -0.015)
	_dash_root.add_child(bin)
	# Hood roof, side cheeks, lower sill & back shroud
	bin.add_child(_ros_part("box", m_top, Vector3(0.0, 0.062, 0.005), Vector3(0.34, 0.020, 0.145)))
	bin.add_child(_ros_part("box", m_top, Vector3(0.0, -0.056, 0.005), Vector3(0.34, 0.014, 0.145)))
	bin.add_child(_ros_part("box", m_top, Vector3(0.165, 0.003, 0.005), Vector3(0.022, 0.128, 0.145)))
	bin.add_child(_ros_part("box", m_top, Vector3(-0.165, 0.003, 0.005), Vector3(0.022, 0.128, 0.145)))
	bin.add_child(_ros_part("box", m_dark, Vector3(0.0, 0.003, 0.068), Vector3(0.32, 0.115, 0.015)))
	# Signature Citroën C15 vertical pod of 3 round buttons on the inner-right cheek of the binnacle!
	bin.add_child(_ros_part("box", m_roll, Vector3(-0.195, 0.002, -0.025), Vector3(0.046, 0.128, 0.065)))
	for bi in range(3):
		var by_b := 0.036 - bi * 0.036
		var bezel_b := _ros_part("cyl", m_dark, Vector3(-0.195, by_b, -0.057), Vector3(0.015, 0.008, 0.015))
		bezel_b.rotation.x = PI / 2.0
		bin.add_child(bezel_b)
		var btn_b := _ros_part("cyl", m_trim, Vector3(-0.195, by_b, -0.061), Vector3(0.010, 0.008, 0.010))
		btn_b.rotation.x = PI / 2.0
		bin.add_child(btn_b)

	# Speedometer dial plate (tilted slightly up toward driver's eyes, facing -z)
	var dial_holder := Node3D.new()
	dial_holder.position = Vector3(0.0, 0.004, 0.032)
	dial_holder.rotation.x = deg_to_rad(-10.0)
	bin.add_child(dial_holder)
	_dash_dial_mat = StandardMaterial3D.new()
	_dash_dial_mat.albedo_texture = _build_dash_dial_tex()
	_dash_dial_mat.roughness = 0.45
	_dash_dial_mat.emission_enabled = true
	_dash_dial_mat.emission_texture = _build_dash_dial_tex()
	_dash_dial_mat.emission_energy_multiplier = 0.35
	var dial_quad := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.29, 0.105)
	dial_quad.mesh = qm
	dial_quad.material_override = _dash_dial_mat
	dial_quad.rotation.y = PI             # face -z (toward driver)
	dial_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dial_holder.add_child(dial_quad)

	# Live green headlight indicator LED on the cluster
	_dash_lamp_mat = StandardMaterial3D.new()
	_dash_lamp_mat.albedo_color = Color(0.14, 0.42, 0.18)
	_dash_lamp_mat.emission_enabled = true
	_dash_lamp_mat.emission = Color(0.25, 0.95, 0.38)
	_dash_lamp_mat.emission_energy_multiplier = 0.0
	dial_holder.add_child(_ros_part("box", _dash_lamp_mat, Vector3(-0.074, -0.025, -0.003), Vector3(0.011, 0.009, 0.003)))

	# LIVE 3D orange-red speedometer needle centered on the dial (cx=96/256 -> u=0.375; since quad faces -z, +x is left!)
	_dash_needle = Node3D.new()
	_dash_needle.name = "SpeedoNeedle"
	_dash_needle.position = Vector3(0.036, -0.003, -0.004)
	dial_holder.add_child(_dash_needle)
	var nmat := StandardMaterial3D.new()
	nmat.albedo_color = Color(1.0, 0.30, 0.12)
	nmat.emission_enabled = true
	nmat.emission = Color(1.0, 0.34, 0.12)
	nmat.emission_energy_multiplier = 0.65
	_dash_needle.add_child(_ros_part("box", nmat, Vector3(0.0, 0.017, 0.0), Vector3(0.0042, 0.036, 0.003)))
	var hub_n := _ros_part("cyl", m_dark, Vector3(0.0, 0.0, -0.001), Vector3(0.007, 0.005, 0.007))
	hub_n.rotation.x = PI / 2.0
	_dash_needle.add_child(hub_n)
	_dash_speed_ang = deg_to_rad(-125.0)
	_dash_needle.rotation.z = _dash_speed_ang      # looking along +z (+x is left): -125 deg = bottom-left (0 km/h), +125 deg = bottom-right (120 km/h)

	# 6) Iconic Citroën C15 single-spoke steering wheel ("volante monobrazo") rotating with steering!
	var col_mount := Node3D.new()
	col_mount.position = Vector3(eye_x, -0.055, -0.115)
	col_mount.rotation.x = deg_to_rad(-22.0)
	_dash_root.add_child(col_mount)
	# Steering column shroud + left indicator stalk
	var col_cyl := _ros_part("cyl", m_dark, Vector3(0.0, 0.0, 0.075), Vector3(0.030, 0.14, 0.030))
	col_cyl.rotation.x = PI / 2.0
	col_mount.add_child(col_cyl)
	var ind_stalk := _ros_part("cyl", m_dark, Vector3(0.068, 0.012, 0.035), Vector3(0.006, 0.095, 0.006))
	ind_stalk.rotation.z = PI / 2.0 - 0.15
	col_mount.add_child(ind_stalk)

	_dash_wheel = Node3D.new()
	_dash_wheel.name = "SingleSpokeWheel"
	col_mount.add_child(_dash_wheel)
	if _dash_rim_mesh == null:
		_dash_rim_mesh = TorusMesh.new()
		_dash_rim_mesh.inner_radius = 0.126
		_dash_rim_mesh.outer_radius = 0.144
		_dash_rim_mesh.rings = 28
		_dash_rim_mesh.ring_segments = 10
	var rim := MeshInstance3D.new()
	rim.mesh = _dash_rim_mesh
	rim.material_override = m_wheel
	rim.rotation.x = PI / 2.0
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_dash_wheel.add_child(rim)
	# Iconic single chunky lower spoke + Citroën rectangular center horn pad
	_dash_wheel.add_child(_ros_part("box", m_trim, Vector3(0.0, -0.068, 0.004), Vector3(0.044, 0.132, 0.020)))
	_dash_wheel.add_child(_ros_part("box", m_wheel, Vector3(0.0, 0.0, -0.006), Vector3(0.056, 0.044, 0.022)))
	_dash_wheel.add_child(_ros_part("box", m_trim, Vector3(0.0, 0.0, -0.018), Vector3(0.040, 0.026, 0.005)))
	# Driver's hands gripping the rim at "ten and two" (rotating solidly with the wheel & front tyres, matching player skin tone)
	var skin_hex: int = int(riders[0].get("skin", 0xf6c9a0))
	var m_skin := Parts.mat(skin_hex)
	var grip_r := 0.135
	var grip_ang := deg_to_rad(52.0)
	for sgn: float in [1.0, -1.0]:
		var hand := Node3D.new()
		hand.name = "WheelHandL" if sgn > 0.0 else "WheelHandR"
		hand.position = Vector3(sgn * grip_r * sin(grip_ang), grip_r * cos(grip_ang), -0.006)
		hand.rotation.z = sgn * grip_ang
		# Rounded Matritellus hand wrapped over the rim + upper-inner thumb resting along the rim
		hand.add_child(_ros_part("ball", m_skin, Vector3.ZERO, Vector3(0.025, 0.033, 0.023)))
		var thumb := _ros_part("ball", m_skin, Vector3(-0.012 * sgn, 0.026, -0.007), Vector3(0.011, 0.017, 0.011))
		thumb.rotation.z = sgn * 0.25
		hand.add_child(thumb)
		_dash_wheel.add_child(hand)

static func _ros_part(kind_: String, mat_: Material, pos: Vector3, scl: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = Parts.mesh(kind_)
	mi.material_override = mat_
	mi.position = pos
	mi.scale = scl
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

## Authentic horizontal Spanish windscreen ITV sticker (green / yellow / red with crisp white border, band & "ITV" marking)
static func _make_itv_sticker(hex_col: int) -> MeshInstance3D:
	if not _itv_tex.has(hex_col):
		var w := 48
		var h := 32
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		var bg := Color8((hex_col >> 16) & 0xff, (hex_col >> 8) & 0xff, hex_col & 0xff)
		var white := Color(0.95, 0.95, 0.92, 1.0)
		var ink := Color(0.10, 0.11, 0.13, 1.0)
		img.fill(bg)
		for py in range(h):
			for px in range(w):
				if py < 3 or py >= h - 3 or px < 3 or px >= w - 3:
					img.set_pixel(px, py, white)
				elif px >= 5 and px <= 16 and py >= 5 and py < h - 5:
					img.set_pixel(px, py, white)
				elif py >= 7 and py <= 17 and ((px >= 21 and px <= 28) or (px >= 32 and px <= 39)):
					if py <= 9 or py >= 15 or px == 28 or px == 32 or py == 12:
						img.set_pixel(px, py, ink)
		_draw_tiny_word(img, "ITV", 24, 21, ink)
		_itv_tex[hex_col] = ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _itv_tex[hex_col]
	mat.roughness = 0.32
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var qm := QuadMesh.new()
	qm.size = Vector2(0.050, 0.032)
	var mi := MeshInstance3D.new()
	mi.mesh = qm
	mi.material_override = mat
	mi.rotation.y = PI
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

static func _ros_link(a: Vector3, b: Vector3) -> MeshInstance3D:
	var d := b - a
	var mi := _ros_part("cyl", _ros_silver, (a + b) * 0.5, Vector3(0.0020, maxf(0.002, d.length()), 0.0020))
	if d.length_squared() > 1e-6:
		var up := d.normalized()
		var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
		mi.basis = Basis(side, up, side.cross(up).normalized()).scaled(mi.scale)
	return mi

func _step_rosary(dt: float) -> void:
	var has_rosary := _rosary_piv != null and is_instance_valid(_rosary_piv)
	var has_bobble := _bobble_piv != null and is_instance_valid(_bobble_piv)
	var has_dash := _dash_root != null and is_instance_valid(_dash_root)
	if not has_rosary and not has_bobble and not has_dash:
		return
	var sdt := clampf(dt, 0.001, 0.05)
	_ros_t += sdt
	var a_loc := Vector3.ZERO
	if has_rosary or has_bobble:
		var inv_b := global_transform.basis.orthonormalized().inverse()
		var a_world := (linear_velocity - _ros_prev_v) / sdt
		_ros_prev_v = linear_velocity
		a_loc = inv_b * a_world
		if has_rosary:
			# Apparent gravity in cab frame (real gravity - car acceleration)
			var g_loc := inv_b * Vector3(0.0, -9.8, 0.0)
			# Lateral & longitudinal inertial pull + gentle engine vibration
			var vibe := sin(_ros_t * 32.0) * (0.04 if running else 0.0)
			var target_x := clampf(atan2(g_loc.z - a_loc.z * 0.85, maxf(1.5, -g_loc.y)), -0.38, 0.65) + vibe * 0.12
			var target_z := clampf(atan2(-g_loc.x + a_loc.x * 0.95, maxf(1.5, -g_loc.y)), -0.78, 0.78) + vibe * 0.18
			# Damped harmonic pendulum for main loop (Z15 rosary or Seta Panda Spanish ribbon)
			var acc_x := 36.0 * (target_x - _ros_ang.x) - 3.4 * _ros_vel.x
			var acc_z := 36.0 * (target_z - _ros_ang.y) - 3.4 * _ros_vel.y
			_ros_vel.x += acc_x * sdt
			_ros_vel.y += acc_z * sdt
			_ros_ang.x = clampf(_ros_ang.x + _ros_vel.x * sdt, -0.40, 0.72)
			_ros_ang.y = clampf(_ros_ang.y + _ros_vel.y * sdt, -0.82, 0.82)
			_rosary_piv.rotation = Vector3(_ros_ang.x, 0.0, _ros_ang.y)
			# Secondary follow-through pendulum for the crucifix / ribbon tail + gentle twist on turns
			if _rosary_drop != null and is_instance_valid(_rosary_drop):
				var d_acc_x := 54.0 * (-_ros_vel.x * 0.10 - _drop_ang.x) - 2.8 * _drop_vel.x
				var d_acc_z := 54.0 * (-_ros_vel.y * 0.12 - _drop_ang.y) - 2.8 * _drop_vel.y
				_drop_vel.x += d_acc_x * sdt
				_drop_vel.y += d_acc_z * sdt
				_drop_ang.x = clampf(_drop_ang.x + _drop_vel.x * sdt, -0.35, 0.45)
				_drop_ang.y = clampf(_drop_ang.y + _drop_vel.y * sdt, -0.45, 0.45)
				var yaw_drive := clampf(angular_velocity.y * 0.9 + a_loc.x * 0.06, -2.5, 2.5)
				_drop_yaw_v += (18.0 * (yaw_drive - _drop_yaw) - 2.4 * _drop_yaw_v) * sdt
				_drop_yaw = clampf(_drop_yaw + _drop_yaw_v * sdt, -1.1, 1.1)
				_rosary_drop.rotation = Vector3(_drop_ang.x, _drop_yaw, _drop_ang.y)
		if has_bobble:
			# Bouncy spring-damper bobblehead reacting to road bumps (a_loc.y), gas/brake (a_loc.z), turns (a_loc.x) & idle tremor!
			var idle_nod := sin(_ros_t * 14.0) * (0.045 if running else 0.0)
			var drive_x := clampf(a_loc.z * 0.095 - a_loc.y * 0.14, -0.55, 0.55) + idle_nod
			var drive_z := clampf(a_loc.x * 0.095, -0.50, 0.50) + cos(_ros_t * 11.0) * (0.025 if running else 0.0)
			var b_ax := 88.0 * (drive_x - _bobble_ang.x) - 4.2 * _bobble_vel.x
			var b_az := 88.0 * (drive_z - _bobble_ang.y) - 4.2 * _bobble_vel.y
			_bobble_vel.x += b_ax * sdt
			_bobble_vel.y += b_az * sdt
			_bobble_ang.x = clampf(_bobble_ang.x + _bobble_vel.x * sdt, -0.48, 0.48)
			_bobble_ang.y = clampf(_bobble_ang.y + _bobble_vel.y * sdt, -0.45, 0.45)
			_bobble_piv.rotation = Vector3(_bobble_ang.x, 0.0, _bobble_ang.y)
	var is_tractor := kind == "tractor" or kind == "yondir"
	var diesel_jit := (sin(_ros_t * 44.0) * 0.65 + cos(_ros_t * 29.0) * 0.35) if (is_tractor and running) else 0.0
	# Subtle diesel chug vibration on the Hebro / Yondir pod & column while engine runs
	if is_tractor and has_dash:
		var amp := 0.0022 if absf(_thr) > 0.1 else 0.0014
		_dash_root.position = _dash_base_pos + Vector3(diesel_jit * amp * 0.6, sin(_ros_t * 36.0) * amp * (1.0 if running else 0.0), 0.0)
	# Live speedometer needle, cluster backlight, and rotating steering wheel (+ hands)
	if _dash_needle != null and is_instance_valid(_dash_needle):
		var kmh: float = linear_velocity.length() * 3.6
		var lo_deg := -62.0 if kind == "cuatrolatas" else (-120.0 if (kind == "panda" or kind == "pitufo") else (-130.0 if (kind == "julietta" or kind == "yondir") else -125.0))
		var hi_deg := 62.0 if kind == "cuatrolatas" else (48.0 if (kind == "panda" or kind == "pitufo") else (130.0 if (kind == "julietta" or kind == "yondir") else 125.0))
		var target_ang: float = deg_to_rad(lerpf(lo_deg, hi_deg, clampf(kmh / _dash_max_kmh, 0.0, 1.08)))
		_dash_speed_ang = lerpf(_dash_speed_ang, target_ang, 1.0 - exp(-10.0 * sdt))
		_dash_needle.rotation.z = _dash_speed_ang + diesel_jit * 0.025
	# Iconic Renol 4L umbrella ("paraguas") dash gear lever shifting in/out and twisting with gears & reverse!
	if _r4_shifter_piv != null and is_instance_valid(_r4_shifter_piv):
		var kmh_r4: float = linear_velocity.length() * 3.6
		var tz_sh := 0.0
		var troll_sh := 0.0
		if _thr < -0.05:
			tz_sh = 0.026     # Reverse: pushed in & twisted left
			troll_sh = 0.26
		elif kmh_r4 > 58.0:
			tz_sh = -0.022    # 4th gear: pulled back & right
			troll_sh = -0.22
		elif kmh_r4 > 36.0:
			tz_sh = 0.020     # 3rd gear: pushed in & right
			troll_sh = -0.22
		elif kmh_r4 > 14.0:
			tz_sh = -0.022    # 2nd gear: pulled back
			troll_sh = 0.06
		elif running and _thr > 0.05:
			tz_sh = 0.022     # 1st gear: pushed in
			troll_sh = 0.06
		_r4_shifter_z = lerpf(_r4_shifter_z, tz_sh, 1.0 - exp(-10.0 * sdt))
		_r4_shifter_roll = lerpf(_r4_shifter_roll, troll_sh, 1.0 - exp(-10.0 * sdt))
		_r4_shifter_piv.position = _r4_shifter_base + Vector3(0.0, 0.0, _r4_shifter_z)
		_r4_shifter_piv.rotation.z = _r4_shifter_roll
	if _pitufo_siren_mat != null:
		_pitufo_siren_mat.emission_energy_multiplier = (1.1 + 0.7 * sin(_ros_t * 10.0)) if lit else 0.55
	if _hebro_oil_needle != null and is_instance_valid(_hebro_oil_needle):
		var oil_frac := (0.44 + clampf(absf(_thr), 0.0, 1.0) * 0.34) if running else 0.0
		var oil_target := deg_to_rad(lerpf(-125.0, 125.0, oil_frac))
		_hebro_oil_ang = lerpf(_hebro_oil_ang, oil_target, 1.0 - exp(-6.0 * sdt))
		_hebro_oil_needle.rotation.z = _hebro_oil_ang + diesel_jit * 0.035
	if _hebro_throttle_piv != null and is_instance_valid(_hebro_throttle_piv):
		var thr_target := clampf(_thr, -0.25, 1.0) * 0.48
		_hebro_thr_ang = lerpf(_hebro_thr_ang, thr_target, 1.0 - exp(-12.0 * sdt))
		_hebro_throttle_piv.rotation.y = _hebro_thr_ang
	if _hebro_flap_piv != null and is_instance_valid(_hebro_flap_piv):
		var flap_target := 0.0
		if running:
			var gas := clampf(absf(_thr), 0.0, 1.0)
			var chug := 0.5 + 0.5 * sin(_ros_t * (28.0 + gas * 26.0))
			flap_target = deg_to_rad(lerpf(18.0, 68.0, gas) + chug * lerpf(12.0, 8.0, gas))
		_hebro_flap_ang = lerpf(_hebro_flap_ang, flap_target, 1.0 - exp(-18.0 * sdt))
		_hebro_flap_piv.rotation.x = -_hebro_flap_ang
	# Julietta live tachometer (simulated sporty gears + throttle + turbo), live turbo boost gauge & rotating GPS heading
	if _jul_rpm_needle != null and is_instance_valid(_jul_rpm_needle):
		var kmh_j: float = linear_velocity.length() * 3.6
		var rpm_frac := 0.0
		if running:
			var gear_saw: float = fposmod(kmh_j, 42.0) / 42.0
			rpm_frac = clampf(0.14 + gear_saw * 0.52 + clampf(absf(_thr), 0.0, 1.0) * 0.24 + (0.16 if boosting else 0.0), 0.12, 0.98)
		var rpm_target := deg_to_rad(lerpf(-130.0, 130.0, rpm_frac))
		_jul_rpm_ang = lerpf(_jul_rpm_ang, rpm_target, 1.0 - exp(-11.0 * sdt))
		_jul_rpm_needle.rotation.z = _jul_rpm_ang
	if _jul_boost_needle != null and is_instance_valid(_jul_boost_needle):
		var b_frac := 0.0
		if running:
			b_frac = 0.95 if boosting else clampf(absf(_thr) * 0.58 + (linear_velocity.length() / 45.0) * 0.22, 0.06, 0.72)
		var b_target := deg_to_rad(lerpf(-130.0, 130.0, b_frac))
		_jul_boost_ang = lerpf(_jul_boost_ang, b_target, 1.0 - exp(-10.0 * sdt))
		_jul_boost_needle.rotation.z = _jul_boost_ang
	if _jul_boost_mat != null:
		_jul_boost_mat.emission_energy_multiplier = 1.15 if boosting else (0.75 if lit else 0.40)
	if _jul_gps_arrow != null and is_instance_valid(_jul_gps_arrow):
		_jul_gps_arrow.rotation.z = -rotation.y
	# Live real Madridejos dark-mode satnav (heading-up, showing real streets, blocks & active route line!)
	if _gps_map != null and is_instance_valid(_gps_map) and _fp_hide_head:
		_gps_map.center = p
		_gps_map.heading = h
		_gps_map.spin = h
		_gps_map.queue_redraw()
	# Edison Model Y live 15" touchscreen telemetry (digital km/h, P-R-N-D, Autopilot curve, power/regen bar & ambient LED)
	if _edison_speed_lbl != null and is_instance_valid(_edison_speed_lbl):
		var kmh_i := int(round(linear_velocity.length() * 3.6))
		if kmh_i != _edison_last_kmh:
			_edison_last_kmh = kmh_i
			_edison_speed_lbl.text = str(kmh_i)
	if _edison_gear_lbl != null and is_instance_valid(_edison_gear_lbl):
		var fwd_v := linear_velocity.dot(global_transform.basis.z)
		var g_txt := "R" if (fwd_v < -0.4 or _thr < -0.1) else ("D" if (running or absf(fwd_v) > 0.3 or _thr > 0.05) else "P")
		if _edison_gear_lbl.text != g_txt:
			_edison_gear_lbl.text = g_txt
	if _edison_lane_piv != null and is_instance_valid(_edison_lane_piv):
		_edison_lane_piv.rotation.z = lerpf(_edison_lane_piv.rotation.z, -steering * 0.95, 1.0 - exp(-10.0 * sdt))
	if _edison_pwr_bar != null and is_instance_valid(_edison_pwr_bar) and _edison_pwr_mat != null:
		var regen := _thr < -0.05
		var p_frac := clampf(absf(_thr), 0.12, 1.0)
		_edison_pwr_bar.scale.x = lerpf(_edison_pwr_bar.scale.x, 0.012 + p_frac * 0.068, 1.0 - exp(-12.0 * sdt))
		_edison_pwr_mat.albedo_color = Color(0.22, 0.94, 0.42) if regen else Color(0.76, 0.88, 1.0)
	if _edison_led_mat != null:
		_edison_led_mat.emission_energy_multiplier = 2.1 if lit else 1.35
	if _dash_wheel != null and is_instance_valid(_dash_wheel):
		var w_target: float = -steering * 3.4
		_dash_wheel_ang = lerpf(_dash_wheel_ang, w_target, 1.0 - exp(-12.0 * sdt))
		_dash_wheel.rotation.z = _dash_wheel_ang + diesel_jit * 0.015
	if _dash_dial_mat != null:
		_dash_dial_mat.emission_energy_multiplier = (0.75 if lit else 0.25) if (kind == "tractor" or kind == "yondir") else (0.85 if lit else 0.35)
	if _dash_lamp_mat != null:
		if kind == "tractor" or kind == "yondir":
			_dash_lamp_mat.emission_energy_multiplier = 1.6 if (running or lit) else 0.15
		else:
			_dash_lamp_mat.emission_energy_multiplier = 1.6 if lit else 0.0

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
		wheel.name = "rider_wheel"
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
	for i in range(secs.size()):
		var sc: Array = secs[i]
		var end_lift := 0.1 if (i == 0 or i == secs.size() - 1) and secs.size() > 1 else 0.0
		var f_y := foot + end_lift
		var bx := BoxShape3D.new()
		bx.size = Vector3(2.0 * float(sc[3]), maxf(0.28, float(sc[2]) - f_y), float(sc[1]) - float(sc[0]))
		shapes.append([bx, Vector3(0.0, f_y + bx.size.y / 2.0, (float(sc[0]) + float(sc[1])) / 2.0)])
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
	if arcade:
		position = Vector3(pos.x, 0.08, pos.y)
		rotation = Vector3(0.0, heading, 0.0)
	else:
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
	if dozing:
		doze(false)
	var up := MapData.normal(pos)                # standing on the slope, not level over it
	var fwd := Vector3(sin(heading), 0.0, cos(heading))
	fwd = (fwd - up * fwd.dot(up)).normalized()
	global_transform = Transform3D(Basis(up.cross(fwd), up, fwd), MapData.at(pos, 0.12))
	awake_t = 0.5
	set_speed(Vector2.ZERO)
	angular_velocity = Vector3.ZERO
	air_time = 0.0
	reset_physics_interpolation()

func set_speed(v: Vector2) -> void:
	linear_velocity = Vector3(v.x, 0.0, v.y)
	_prev_v = linear_velocity
	_ros_prev_v = linear_velocity

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
	if amount > 0.0:
		knocks += 1
	if unbreakable and amount > 0.0:
		return
	hp = maxf(0.0, hp - amount)
	smoke.emitting = hp < spec["hp"] * 0.35

func repair() -> void:
	hp = spec["hp"]
	smoke.emitting = false

## Gives the car a fresh coat of paint (always a different colour from its current one).
func repaint(new_hex := -1) -> int:
	var pool: Array = []
	var own: Array = spec.get("colors", [])
	for col in (own if own.size() >= 2 else RESPRAY):
		if int(col) != paint:
			pool.append(int(col))
	if pool.is_empty():
		pool = RESPRAY.duplicate()
	var chosen: int = new_hex if new_hex >= 0 else int(pool.pick_random())
	paint = chosen
	if model != null:
		Modelos.repaint(kind, model, paint)
	else:
		var pmat: StandardMaterial3D = Parts.mat(paint)
		for ch in inner.get_children():
			if ch is MeshInstance3D and not (ch in lights):
				var om = ch.material_override
				if om != null and om != Parts.mat(0xcfe8f2) and om != Parts.mat(0xfff3a8) and om != Parts.mat(0xf4f8ff) and om != Parts.mat(0xd23b2e) and om != Parts.mat(0x26262b):
					ch.material_override = pmat
	return paint

func broken() -> bool:
	return hp <= 0.0

## forward speed in m/s (negative when reversing)
## The soap (the user, 23 November 2026: "si te das un golpe con el coche con una esquina de una fachada o de lado con
## el coche el coche para en seco siempre... no se podría hacer como un «efecto jabón» que deslice el coche hacia el
## lado si el golpe no es demasiado frontal ni demasiado fuerte?"). For the car you drive only:
##   - its body hardly grips what it rubs against (SOAP_GRIP), so running along a wall does not drag it to a stop;
##   - a knock against a wall, a corner or another car that is neither head-on (more than SOAP_FRONT of the speed
##     straight into it) nor hard (SOAP_HARD m/s straight into it) gives back SOAP_KEEP of the speed it had along it,
##     a little push off it, and turns the nose the way it slides, so it carries on beside the wall;
##   - what counts as the knock (damage, noise, oil bottles) is the speed it went straight in at, not all it lost.
## A head-on or hard one is a crash as before: it is left with a third of what it had, whichever way.
const SOAP_GRIP := 0.03
const SOAP_FRONT := 0.72       # (cosine: about 44 degrees off the wall's face or less is head-on)
const SOAP_HARD := 13.0
const SOAP_KEEP := 0.85

func set_soap(on: bool) -> void:
	soap = on
	contact_monitor = on
	max_contacts_reported = 8 if on else 0
	if on:
		if _slip_mat == null:
			_slip_mat = PhysicsMaterial.new()
			_slip_mat.friction = SOAP_GRIP
		physics_material_override = _slip_mat
	else:
		physics_material_override = null

## the knock just felt, as the soap sees it: the speed straight into what it hit (and the car sent sliding), or all
## that was lost (a head-on or hard one: left as the physics had it)
func _soap(lost: float) -> float:
	var v0 := Vector3(_prev_v.x, 0.0, _prev_v.z)
	if v0.length() < 4.0 or Vector3(linear_velocity.x, 0.0, linear_velocity.z).length() > v0.length() - 1.5:
		return lost                              # (slow, or it was not stopped but shoved: a patrol car ramming it from behind)
	var st := PhysicsServer3D.body_get_direct_state(get_rid())
	if st == null:
		return lost
	var n := Vector3.ZERO
	for i in range(st.get_contact_count()):
		var cn := st.get_contact_local_normal(i)
		if absf(cn.y) < 0.6:                    # (a wall or a car's side; not the ground nor the top of a kerb)
			n += Vector3(cn.x, 0.0, cn.z).normalized()
	if n.length() < 0.1:
		return lost
	n = n.normalized()
	if n.dot(v0) > 0.0:
		n = -n                                   # (facing back at the car)
	var into := -v0.dot(n)
	if into <= 0.0:
		return lost
	if into > SOAP_HARD or into / v0.length() > SOAP_FRONT:
		var flat := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
		linear_velocity = flat * 0.3 + Vector3.UP * linear_velocity.y      # (a crash: the slippery body is not to carry it on)
		return lost
	var along := v0 + n * into
	linear_velocity = along * SOAP_KEEP + n * minf(1.5, into * 0.2) + Vector3.UP * linear_velocity.y
	var fwd := global_transform.basis.z
	fwd = Vector3(fwd.x, 0.0, fwd.z).normalized()
	var aim := along.normalized() * (1.0 if v0.dot(fwd) >= 0.0 else -1.0)
	var turn := atan2(fwd.cross(aim).y, fwd.dot(aim))
	angular_velocity = Vector3(angular_velocity.x, clampf(turn * 4.0, -2.5, 2.5), angular_velocity.z)
	soaped += 1
	return into * 0.7

func forward_speed() -> float:
	return linear_velocity.dot(global_transform.basis.z)

func airborne() -> bool:
	for w in wheels:
		if w.is_in_contact():
			return false
	return true

## thr: -1..1 (forward/back), steer: -1..1 (positive = left), hand: handbrake. Call every physics tick.
func drive(thr: float, steer: float, hand: bool, on_road: bool, dt: float) -> void:
	if held and not arcade:
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
	if spec.has("turbo") and not arcade:
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
	if absf(vf) > max_v and not airborne() and _ramp_cool <= 0.0:      # e.g. just left the road at speed (horizontal only, never kills a jump)
		var flat_v := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
		if flat_v.length() > 0.1:
			apply_central_force(-flat_v.normalized() * mass * 6.0)
	# steering gets gentler with speed, and eases towards its target
	var lock: float = spec["turn"] * lerpf(1.0, 0.3, clampf(absf(vf) / 28.0, 0.0, 1.0))
	steering = move_toward(steering, steer * lock, 2.6 * dt)

func _physics_process(dt: float) -> void:
	awake_t = maxf(0.0, awake_t - dt)
	if (held and not arcade) or (arcade and freeze):
		return
	crash_cool -= dt
	if _ramp_cool > 0.0:
		_ramp_cool = maxf(0.0, _ramp_cool - dt)
	if not arcade and not freeze:
		_ramp_launch(dt)
	var dv := (linear_velocity - _prev_v)
	dv.y = 0.0
	if dv.length() > 3.0 and _ramp_cool <= 0.0:
		last_impact = maxf(last_impact, _soap(dv.length()) if soap else dv.length())
	_prev_v = linear_velocity
	if _rosary_piv != null or _dash_root != null:
		_step_rosary(dt)
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
	var ground := MapData.normal(p) if touching >= 2 and not arcade else Vector3.UP
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

## Driving fast onto any ramp-like structure (Plaza ramps/stairs, Ermita steps, bridge flights...) launches the car
## cleanly into the air instead of snagging its front bumper and stopping dead.
func _ramp_launch(_dt: float) -> void:
	var flat_v := Vector2(linear_velocity.x, linear_velocity.z)
	var spd := flat_v.length()
	if spd < 6.0:
		return
	var dir := flat_v / spd
	var nose := p + Vector2(sin(h), cos(h)) * (float(spec["len"]) * 0.42)
	var car_y := global_position.y
	for d in MapData.decks:
		if not d.has("ramp"):
			continue
		var o: Vector2 = d["o"]
		var ax: Vector2 = d["ax"]
		if dir.dot(ax) < 0.35:
			continue
		var half: float = float(d["half"])
		var wide: float = float(d["wide"])
		var hit := false
		var along_best := -1e9
		for probe in [nose, p]:
			var rel: Vector2 = probe - o
			var a := rel.dot(ax)
			var w := absf(rel.dot(Vector2(-ax.y, ax.x)))
			if a >= -half - 0.6 and a <= half + 0.4 and w <= wide + 0.35:
				hit = true
				along_best = maxf(along_best, a)
		if not hit:
			continue
		var low: float = float(d["low"])
		var top: float = float(d["top"])
		if top - low < 0.25 or car_y < low - 0.6 or car_y > top + 1.4:
			continue
		var slope: float = clampf((top - low) / maxf(float(d["ramp"]), 0.6), 0.26, 0.72)
		var want_vy: float = clampf(spd * slope * 1.18, 3.0, 11.5)
		if linear_velocity.y < want_vy:
			linear_velocity.y = maxf(linear_velocity.y, want_vy)
		# Keep forward speed brisk over the lip so it flies over the crest instead of scrubbing speed on impact
		if along_best > -half * 0.2 and _ramp_cool <= 0.0:
			var boost := Vector3(dir.x, 0.0, dir.y) * maxf(0.0, 2.5)
			linear_velocity += boost
			var right := global_transform.basis.x
			angular_velocity += right * clampf(-slope * 2.4, -1.6, -0.5)
		_ramp_cool = 0.55
		last_impact = 0.0
		return

## lying on its roof or side for a moment (not just mid-jump)
func flipped() -> bool:
	return _flipped > 0.6
