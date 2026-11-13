extends Node3D
## What there is to look at overhead: puffy clouds drifting on the wind, flocks of birds by day, and at nightfall the
## moon climbing and the stars coming out a few at a time. Everything follows the camera, so the sky is always there.
## game.gd calls update() with the hour whenever the light changes, and tick() every frame.

const Parts = preload("res://scripts/parts.gd")

const CLOUDS := 46
const FIELD := 1500.0          # clouds live within this distance of the camera and wrap round
const STARS := 420
const STAR_DOME := 1250.0

const STAR_SHADER := "
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform float night = 0.0;
void vertex() {
	// each star has its own moment to come out (INSTANCE_CUSTOM.x) and its own twinkle (y)
	float out_at = INSTANCE_CUSTOM.x;
	float lit = smoothstep(out_at, out_at + 0.18, night);
	float twinkle = 0.75 + 0.25 * sin(TIME * (1.5 + INSTANCE_CUSTOM.y * 3.0) + INSTANCE_CUSTOM.y * 40.0);
	COLOR = vec4(INSTANCE_CUSTOM.z, INSTANCE_CUSTOM.z * 0.96 + 0.04, 1.0, lit * twinkle);
}
void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float glow = smoothstep(1.0, 0.0, d);
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a * glow * glow;
}
"

var game
var night := 0.0               # 0 by day .. 1 in the dead of night
var _clouds: MultiMeshInstance3D
var _cloud_mat: StandardMaterial3D
var _cloud_at: Array = []      # per cloud: [Vector3 centre (relative to the field), Array of [offset, scale]]
var _wind := Vector3(5.5, 0, 2.0)
var _cloud_wait := 0
var _cloud_dt := 0.0
var _stars: MultiMeshInstance3D
var _star_mat: ShaderMaterial
var _moon: Node3D
var _moon_mat: StandardMaterial3D
var _flocks: Array = []        # each: {node, birds: [{node, l, r, phase}], centre, angle, radius, height, speed}
var _bird_mat: StandardMaterial3D

func setup(game_) -> void:
	game = game_
	_make_clouds()
	_make_stars()
	_make_moon()
	for i in range(3):
		_make_flock(i)

# ---------------- clouds ----------------
func _make_clouds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1954
	var blobs: Array = []
	for i in range(CLOUDS):
		var centre := Vector3(rng.randf_range(-FIELD, FIELD), rng.randf_range(230.0, 420.0), rng.randf_range(-FIELD, FIELD))
		var size := rng.randf_range(0.7, 1.6)
		var parts: Array = []
		var n := rng.randi_range(4, 7)
		for k in range(n):
			var along := (k - (n - 1) / 2.0) * 26.0 * size
			var r := rng.randf_range(24.0, 44.0) * size * (1.0 - absf(k - (n - 1) / 2.0) / n * 0.9)
			parts.append([Vector3(along + rng.randf_range(-8, 8), rng.randf_range(-3.0, 9.0) * size, rng.randf_range(-16, 16) * size), Vector3(r, r * rng.randf_range(0.5, 0.68), r * rng.randf_range(0.75, 1.0))])
		parts.append([Vector3(0, -9.0 * size, 0), Vector3(n * 17.0 * size, 9.0 * size, 30.0 * size)])      # a flat belly
		_cloud_at.append([centre, parts])
		blobs.append_array(parts)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var ball := SphereMesh.new()
	ball.radius = 1.0; ball.height = 2.0; ball.radial_segments = 12; ball.rings = 6
	mm.mesh = ball
	mm.instance_count = blobs.size()
	_cloud_mat = StandardMaterial3D.new()
	_cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cloud_mat.albedo_color = Color.WHITE
	_clouds = MultiMeshInstance3D.new()
	_clouds.multimesh = mm
	_clouds.material_override = _cloud_mat
	_clouds.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_clouds.extra_cull_margin = 16384.0
	_clouds.layers = 1 << 11                    # (the outline pass does not need to ink them)
	add_child(_clouds)

func _place_clouds(cam: Vector3) -> void:
	var mm := _clouds.multimesh
	var i := 0
	for c in _cloud_at:
		var centre: Vector3 = c[0]
		# wrap round the camera, so the field never runs out
		var rel := Vector3(wrapf(centre.x - cam.x, -FIELD, FIELD), centre.y, wrapf(centre.z - cam.z, -FIELD, FIELD))
		var edge := 1.0 - smoothstep(FIELD * 0.82, FIELD, maxf(absf(rel.x), absf(rel.z)))      # shrink away at the rim instead of popping
		for part in c[1]:
			var s: Vector3 = (part[1] as Vector3) * maxf(0.001, edge)
			mm.set_instance_transform(i, Transform3D(Basis.from_scale(s), Vector3(cam.x + rel.x, 0, cam.z + rel.z) + Vector3(0, rel.y, 0) + (part[0] as Vector3)))
			i += 1

# ---------------- stars and moon ----------------
func _make_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2(1, 1)
	mm.mesh = quad
	mm.instance_count = STARS
	for i in range(STARS):
		var az := rng.randf() * TAU
		var el := asin(rng.randf_range(0.06, 0.995))           # all over the dome, none below the roofs
		var dir := Vector3(cos(el) * sin(az), sin(el), cos(el) * cos(az))
		var bright := pow(rng.randf(), 2.2)                    # a few bright ones, many faint
		var s := lerpf(5.0, 17.0, bright)
		mm.set_instance_transform(i, Transform3D(Basis.looking_at(dir, Vector3.UP) * Basis.from_scale(Vector3(s, s, s)), dir * STAR_DOME))      # facing in
		# the bright ones come out first; x = how dark it has to be, y = twinkle seed, z = warmth
		mm.set_instance_custom_data(i, Color(lerpf(0.8, 0.12, bright) * rng.randf_range(0.75, 1.0), rng.randf(), rng.randf_range(0.78, 1.0), 1.0))
	var sh := Shader.new()
	sh.code = STAR_SHADER
	_star_mat = ShaderMaterial.new()
	_star_mat.shader = sh
	_stars = MultiMeshInstance3D.new()
	_stars.multimesh = mm
	_stars.material_override = _star_mat
	_stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_stars.extra_cull_margin = 16384.0
	_stars.layers = 1 << 11
	_stars.visible = false
	add_child(_stars)

func _make_moon() -> void:
	_moon = Node3D.new()
	_moon_mat = StandardMaterial3D.new()
	_moon_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_moon_mat.albedo_color = Color(1.0, 0.97, 0.86)
	_moon_mat.disable_fog = true
	var disc := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 1.0; ball.height = 2.0; ball.radial_segments = 24; ball.rings = 12
	disc.mesh = ball
	disc.material_override = _moon_mat
	disc.scale = Vector3.ONE * 52.0
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	disc.layers = 1 << 11
	_moon.add_child(disc)
	var sea := StandardMaterial3D.new()             # the grey patches
	sea.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sea.albedo_color = Color(0.82, 0.8, 0.72)
	sea.disable_fog = true
	for q in [[Vector3(-0.3, 0.25, 0.0), 0.26], [Vector3(0.22, -0.1, 0.0), 0.2], [Vector3(-0.05, -0.42, 0.0), 0.14], [Vector3(0.38, 0.36, 0.0), 0.1]]:
		var spot := MeshInstance3D.new()
		spot.mesh = ball
		spot.material_override = sea
		spot.scale = Vector3(q[1], q[1], 0.05) * 52.0
		spot.position = (q[0] as Vector3) * 52.0 + Vector3(0, 0, 49.0)
		spot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		spot.layers = 1 << 11
		_moon.add_child(spot)
	_moon.visible = false
	add_child(_moon)

# ---------------- birds ----------------
func _make_flock(seed_: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 40 + seed_
	if _bird_mat == null:
		_bird_mat = StandardMaterial3D.new()
		_bird_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_bird_mat.albedo_color = Color(0.13, 0.12, 0.14)
		_bird_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var node := Node3D.new()
	add_child(node)
	var birds: Array = []
	var n := rng.randi_range(7, 13)
	for i in range(n):
		var b := Node3D.new()
		var row := (i + 1) / 2
		var side := 1.0 if i % 2 == 0 else -1.0
		b.position = Vector3(side * row * 2.4 + rng.randf_range(-0.5, 0.5), rng.randf_range(-0.8, 0.8), -row * 2.2 + rng.randf_range(-0.6, 0.6))     # a ragged V
		var body := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.16, 0.14, 0.7)
		body.mesh = bm
		body.material_override = _bird_mat
		body.layers = 1 << 11
		b.add_child(body)
		var wings: Array = []
		for sx in [-1.0, 1.0]:
			var pivot := Node3D.new()
			var w := MeshInstance3D.new()
			var wm := BoxMesh.new()
			wm.size = Vector3(0.95, 0.04, 0.36)
			w.mesh = wm
			w.material_override = _bird_mat
			w.position.x = sx * 0.5
			w.layers = 1 << 11
			w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			pivot.add_child(w)
			b.add_child(pivot)
			wings.append(pivot)
		node.add_child(b)
		birds.append({"node": b, "l": wings[0], "r": wings[1], "phase": rng.randf() * TAU, "rate": rng.randf_range(7.0, 10.0)})
	_flocks.append({"node": node, "birds": birds, "centre": Vector3.ZERO, "angle": rng.randf() * TAU, "radius": rng.randf_range(120.0, 260.0),
		"height": rng.randf_range(38.0, 85.0), "speed": rng.randf_range(11.0, 16.0) * (1.0 if seed_ % 2 == 0 else -1.0), "t": rng.randf() * 100.0})

# ---------------- every so often: the hour has moved ----------------
## hour 0..24; top and horizon are the sky's colours right now
func update(hour: float, top: Color, horizon: Color) -> void:
	# how much of the night has fallen: from sunset to an hour and a half later, and back before dawn
	var dusk := smoothstep(20.4, 22.2, hour)
	var dawn := 1.0 - smoothstep(5.3, 6.9, hour)
	night = clampf(dusk if hour > 12.0 else dawn, 0.0, 1.0)
	# clouds take the colour of the hour: white at noon, lit from below at sunset, slate at night
	var glow := 1.0 - absf(clampf((hour - 20.6) / 1.3, -1.0, 1.0))                # evening
	glow = maxf(glow, 1.0 - absf(clampf((hour - 6.9) / 1.0, -1.0, 1.0)))         # and morning
	var day := Color(1.0, 1.0, 1.0).lerp(top, 0.06)
	var lit := Color(1.0, 0.72, 0.52).lerp(horizon, 0.35)
	var dark := Color(0.16, 0.18, 0.28)
	_cloud_mat.albedo_color = day.lerp(lit, glow * 0.85).lerp(dark, night * 0.92)
	_stars.visible = night > 0.02
	_star_mat.set_shader_parameter("night", night)
	# the moon comes up in the east as the light goes, crosses, and goes down before sunrise
	var up := 0.0
	if hour >= 19.5:
		up = (hour - 19.5) / 11.5
	elif hour <= 7.0:
		up = (hour + 4.5) / 11.5
	else:
		up = -1.0
	_moon.visible = up >= 0.0
	if up >= 0.0:
		var el := deg_to_rad(sin(up * PI) * 58.0 - 3.0)
		var az := deg_to_rad(lerpf(95.0, 265.0, up))
		_moon.set_meta("dir", Vector3(cos(el) * sin(az), sin(el), -cos(el) * cos(az)))
		var pale := smoothstep(0.0, 0.5, night)                     # washed out while there is still daylight
		_moon_mat.albedo_color = Color(0.86, 0.9, 0.96).lerp(Color(1.0, 0.97, 0.86), pale) * lerpf(0.82, 1.0, pale)
	for f in _flocks:
		f["node"].visible = night < 0.55

## where the moon is in the sky right now (a direction), or Vector3.ZERO if it is not up
func moon_dir() -> Vector3:
	return _moon.get_meta("dir", Vector3.ZERO) if _moon.visible else Vector3.ZERO

# ---------------- every frame ----------------
func tick(dt: float, cam: Vector3, around: Vector2) -> void:
	_cloud_wait -= 1
	_cloud_dt += dt
	if _cloud_wait <= 0:
		_cloud_wait = 8
		for c in _cloud_at:
			c[0] = (c[0] as Vector3) + _wind * _cloud_dt
		_cloud_dt = 0.0
		_place_clouds(cam)
	_stars.global_position = cam
	if _moon.visible:
		var dir: Vector3 = _moon.get_meta("dir", Vector3.UP)
		_moon.global_position = cam + dir * 1150.0
		_moon.look_at(cam, Vector3.UP)
		_moon.rotate_object_local(Vector3.UP, PI)
	for f in _flocks:
		if not f["node"].visible:
			continue
		f["t"] += dt
		# the flock circles a point that drifts after you, climbing and dipping as it goes
		var centre: Vector3 = f["centre"]
		if centre == Vector3.ZERO:
			centre = Vector3(around.x, 0, around.y)
		centre = centre.lerp(Vector3(around.x, 0, around.y), 1.0 - exp(-0.08 * dt))
		f["centre"] = centre
		f["angle"] += f["speed"] / f["radius"] * dt
		var a: float = f["angle"]
		var r: float = f["radius"] * (1.0 + 0.18 * sin(f["t"] * 0.21))
		var pos := centre + Vector3(sin(a) * r, f["height"] + sin(f["t"] * 0.33) * 9.0, cos(a) * r)
		var node: Node3D = f["node"]
		node.position = pos
		node.rotation.y = a + (PI / 2.0 if f["speed"] > 0.0 else -PI / 2.0)
		for b in f["birds"]:
			var flap := sin(f["t"] * b["rate"] + b["phase"])
			(b["l"] as Node3D).rotation.z = -flap * 0.7
			(b["r"] as Node3D).rotation.z = flap * 0.7
			(b["node"] as Node3D).position.y += flap * 0.01
