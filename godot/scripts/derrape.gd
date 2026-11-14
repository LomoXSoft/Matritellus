extends Node3D
## Skids: when a car's rear wheels lose their grip at speed (braking hard, the handbrake, a slide round a corner) the
## tyres squeal and leave black marks on the road. The marks stay where they were made and go once you have left them
## well behind (the user's idea, 13 November 2026).
##
## The marks are one MultiMesh: a short dark strip for each stretch of skid, laid flat on the ground. A ring of them:
## the oldest is used again when there are no more.

const MAX := 900                # strips in all
const SLIP := 0.55              # a wheel's grip below this (VehicleWheel3D.get_skidinfo: 1 holds, 0 slides) is a skid
const MIN_SPEED := 4.0          # m/s: slower than that nothing squeals
const STEP := 0.35              # a new strip every this many metres a wheel slides
const WIDE := 0.2
const GONE := 110.0             # marks further than this from you are taken away

var G
var _mm: MultiMesh
var _at: Array = []             # where each strip is (Vector2), or null if it is not in use
var _next := 0
var _last := {}                 # wheel -> where its mark got to (Vector3), while it is sliding
var _clean_t := 0.0
var _squeal_t := 0.0
var _was := 0.0                 # how hard it was skidding a moment ago (so a screech marks the start of a slide)
var skidding := 0.0             # how hard the car you drive is skidding now, 0..1 (for the sound, and the tests)
var _slide_t := 0.0             # how long it has been skidding without a break
const SURE := 0.1               # seconds of it before the tyres are heard
var laid := 0                   # how many strips have been laid in all

func setup(game) -> void:
	G = game
	var strip := QuadMesh.new()
	strip.size = Vector2(1.0, 1.0)
	strip.orientation = PlaneMesh.FACE_Y
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.07, 0.06, 0.06, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	strip.material = m
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.mesh = strip
	_mm.instance_count = MAX
	_mm.visible_instance_count = 0
	var hide := Transform3D(Basis().scaled(Vector3.ZERO), Vector3(0, -1000, 0))
	for i in range(MAX):
		_mm.set_instance_transform(i, hide)
		_at.append(null)
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = _mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 16384.0          # (the marks are all over the town: never culled as one lump)
	add_child(mi)

func _lay(from: Vector3, to: Vector3) -> void:
	var d := to - from
	d.y = 0.0
	var long := d.length()
	if long < 0.05:
		return
	var mid := (from + to) / 2.0
	var p := Vector2(mid.x, mid.z)
	mid.y = MapData.foot(p) + 0.025
	var heading := atan2(d.x, d.z)
	var b := Basis(Vector3.UP, heading) * Basis.from_scale(Vector3(WIDE, 1.0, long + 0.06))      # (narrow across the tyre, long along the way it went)
	_mm.set_instance_transform(_next, Transform3D(b, mid))
	_at[_next] = p
	_next = (_next + 1) % MAX
	laid += 1
	_mm.visible_instance_count = MAX if laid >= MAX else laid

## How hard this car is skidding, 0..1. The wheels of the physics do not say when they are locked by the brake
## (their grip reads "holding" all the same), so it is worked out from what the car is doing: sliding sideways,
## braking hard or on the handbrake while still going fast.
func slide_of(c) -> float:
	var speed: float = c.vel.length()
	if speed < MIN_SPEED:
		return 0.0
	var f := Vector2(sin(c.h), cos(c.h))
	var side := absf(c.vel.dot(Vector2(f.y, -f.x)))
	var sliding := clampf((side - 2.0) / 5.0, 0.0, 1.0)
	var braking := 0.0
	if float(c.brake) >= c.mass * 0.045 and c.vel.dot(f) > 6.0:        # (the handbrake, or the brake pedal down hard)
		braking = clampf((c.vel.dot(f) - 4.0) / 10.0, 0.35, 1.0)
	var grip := 1.0
	for w in c.wheels:
		if w.is_in_contact():
			grip = minf(grip, w.get_skidinfo())
	# The physics' grip drops with the foot down (the driven wheels spin a little), on a bend (the front ones steering)
	# and over a bump (a wheel unloaded for a moment): none of that is a skid, and it squealed nearly all the time (the
	# user, 14 November 2026). A wheel that has lost its grip only counts if the car is going sideways as well.
	var lost := clampf((SLIP - grip) / SLIP, 0.0, 1.0) * clampf((side - 1.2) / 2.0, 0.0, 1.0)
	return maxf(maxf(sliding, braking), lost)

## a car's rear wheels: sliding? -> marks; returns how hard it is skidding (0..1)
func _car(c) -> float:
	var how := slide_of(c)
	var worst := 0.0
	for w in c.wheels:
		if w.use_as_steering and not c.spec.get("tractor", false):
			continue                              # (the marks are the rear tyres': the front ones steer)
		var slide := how if w.is_in_contact() else 0.0
		var here: Vector3 = w.global_position
		here.y -= w.wheel_radius
		if slide > 0.0:
			worst = maxf(worst, slide)
			var was = _last.get(w)
			if was == null:
				_last[w] = here
			elif (was as Vector3).distance_to(here) >= STEP:
				_lay(was, here)
				_last[w] = here
		elif _last.has(w):
			_last.erase(w)
	return worst

func tick(dt: float, pp: Vector2) -> void:
	skidding = 0.0
	if G.in_car != null:
		skidding = _car(G.in_car)
	for e in G.police.cops:                       # (Los Pitufos brake hard too)
		if (e["car"].p as Vector2).distance_to(pp) < 80.0:
			_car(e["car"])
	# the squeal: recorded tyres (sfx.gd skid): a screech as the slide begins, and a squeal under it while it lasts --
	# once the slide has lasted a tenth of a second (a jolt for a frame or two is not a slide)
	_slide_t = _slide_t + dt if skidding > 0.15 else 0.0
	var heard := skidding if _slide_t >= SURE else 0.0
	Sfx.skid(heard, heard > 0.15 and _was <= 0.15, G.in_car.vel.length() if G.in_car != null else 0.0)
	_was = heard
	# marks left far behind go
	_clean_t -= dt
	if _clean_t <= 0.0:
		_clean_t = 0.6
		var hide := Transform3D(Basis().scaled(Vector3.ZERO), Vector3(0, -1000, 0))
		var gone2 := GONE * GONE
		for i in range(MAX):
			if _at[i] != null and (_at[i] as Vector2).distance_squared_to(pp) > gone2:
				_mm.set_instance_transform(i, hide)
				_at[i] = null

## every mark taken off the ground (calentar.gd lays a few to have their shader made)
func clear() -> void:
	var hide := Transform3D(Basis().scaled(Vector3.ZERO), Vector3(0, -1000, 0))
	for i in range(MAX):
		if _at[i] != null:
			_mm.set_instance_transform(i, hide)
			_at[i] = null
	_last.clear()

## how many marks are on the ground now
func count() -> int:
	return _at.filter(func(a): return a != null).size()
