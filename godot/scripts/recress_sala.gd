extends Node3D
## The Galaxy Recress: the town's amusement arcade, shut these twenty years (the user, 13 November 2026). Its front is
## the shop with the RECREATIVOS board and the roller shutter in the Calle de Zaragoza (house `zaragoza_8`, built by
## casas.gd); what is added here:
##   - on the street: the arcade's own name over the board, in neon (dark until it opens again), the shutter seen
##     rolled up once it has, and a tournament poster either side of it;
##   - the hall itself, a set built far out in the fields like V.I.P.'s back room (vipshop.gd): you go in through the
##     shutter and come out of the set's door, and the other way round. Eight machines along the walls, their screens
##     playing fights, and at the back the Tokken 9 machine of the final, two stools and a big screen over it for the
##     audience; the commentator's corner; coloured lights; and confetti, for when somebody wins.

const Parts = preload("res://scripts/parts.gd")
const HOUSE := "zaragoza_8"
const SHUTTER_AT := 0.3          # where along the front the roller shutter is (casas_calles.gd: "gar .3 2.8 2.6")
const SHUTTER_W := 2.8
const SHUTTER_H := 2.6
const INSIDE := Vector2(-1500.0, -1650.0)        # the set (nothing within 400 m; the ground there is nearly level)
const W := 9.0                   # half the width of the hall
const D := 17.0                  # its depth
const H := 4.4
const POSTER := Vector2(0.62, 0.88)      # a tournament poster on a wall, in metres

const SCREEN_SHADER := """
shader_type spatial;
render_mode unshaded, cull_back;
uniform sampler2D fight_a : source_color, filter_linear_mipmap;
uniform sampler2D fight_b : source_color, filter_linear_mipmap;
uniform float offset = 0.0;
uniform float on = 1.0;
uniform float big = 0.0;            // the screen over the final: the fight there is the one being played
uniform float ko = 0.0;             // 1: the round is over (a white flash fading)
void fragment() {
	float t = TIME + offset;
	float which = big > 0.5 ? 0.0 : step(0.5, fract(t / 14.0));           // one fight, then another
	float beat = fract(t / 1.7 + offset * 0.37);
	float hit = smoothstep(0.82, 1.0, beat);                                // now and then a blow lands
	vec2 uv = UV;
	uv.x += sin(t * 70.0) * 0.006 * hit;                                    // the screen shakes with it
	uv.y += sin(t * 3.1) * 0.002 * step(0.38, UV.y);                       // the fighters breathe
	vec3 c = mix(texture(fight_a, uv).rgb, texture(fight_b, uv).rgb, which);
	c += vec3(1.0, 0.95, 0.8) * step(0.94, beat) * 0.4;                     // the flash of the blow
	c = mix(c, vec3(1.0), clamp(ko, 0.0, 1.0) * 0.8);
	float scan = 0.86 + 0.14 * sin(UV.y * 460.0);
	float vign = 1.0 - 0.5 * pow(length(UV - 0.5) * 1.35, 2.0);
	c *= scan * vign * (0.95 + 0.05 * sin(t * 47.0)) * on;
	ALBEDO = c * 0.2;
	EMISSION = c * 1.25;
}
"""

var G
var o: Vector2                   # the house's front: its left end, along it, out into the street
var u: Vector2
var out: Vector2
var flen := 0.0
var base := 0.0
var door_out: Vector2            # on the pavement in front of the shutter
var out_spawn: Vector2           # where you stand when you come out
var out_h := 0.0
var in_door: Vector2             # the set's door, from inside
var in_spawn: Vector2
var machine: Vector2             # the Tokken 9 of the final: where the two players sit...
var seat_you: Vector2
var seat_other: Vector2
var mic: Vector2                 # ...where the commentator stands (on the left of them, facing the middle)
var duel_you: Vector2            # the mayor's challenge is made out in the open, between the door and the audience
var duel_him: Vector2
var aside: Vector2               # where Alberto stands to watch (front row of the audience, on the right)
var stage_you: Vector2           # where the two finalists stand to be presented, in front of their stools, facing everybody
var stage_other: Vector2
var crowd_spots: Array = []      # Vector2: round the final, looking at the big screen
var cabinets: Array = []         # [where you stand to play it, its heading]
var open := false                # the Recress is open again
var screens: Array = []          # ShaderMaterial of every screen
var big_screen: ShaderMaterial
var floor_y := 0.0
var _hall: Node3D
var _body: StaticBody3D
var _sign: Label3D
var _new_board: Node3D
var _sign_glow: OmniLight3D
var _front_open: Node3D
var _posters: Array = []         # the two by the shutter
var _confetti: Array = []        # CPUParticles3D
var _poster_tex: Texture2D
var _street: Node3D

func setup(game) -> void:
	G = game
	_poster_tex = load("res://assets/recress/cartel.png")
	for h in MapData.houses:
		if h["id"] == HOUSE:
			o = Vector2(h["o"][0], h["o"][1])
			u = Vector2(h["u"][0], h["u"][1])
			flen = float(h["len"])
			base = float(h["base"])
	out = Vector2(-u.y, u.x)
	var at: Vector2 = o + u * flen * SHUTTER_AT
	door_out = at + out * 0.7
	out_spawn = at + out * 2.4
	out_h = atan2(out.x, out.y)
	_street_front()
	_hall_build()

## a spot on the front: `x` metres along it from its left end, `z` out into the street
func spot(x: float, z: float) -> Vector2:
	return o + u * x + out * z

## the middle of the shutter, on the pavement, `z` out
func shutter(z := 0.6) -> Vector2:
	return spot(flen * SHUTTER_AT, z)

# ---------------- the street ----------------
func _street_front() -> void:
	_street = Node3D.new()
	add_child(_street)
	var x0 := flen * SHUTTER_AT
	var turn := atan2(out.x, out.y)
	# Shut, it has only the old board that says RECREATIVOS (casas.gd). Open again, a new board over it with its name in
	# neon: the old board runs from 0.14 to 0.5 of the front, 2.66 to 3.12 m up (casas_calles.gd).
	_new_board = Node3D.new()
	_street.add_child(_new_board)
	var bx := flen * (0.14 + 0.5) / 2.0
	var bw := flen * (0.5 - 0.14) + 0.12
	var bp := spot(bx, 0.1)
	var board := Parts.part("box", 0x140a24, Vector3(bp.x, base + 2.89, bp.y), Vector3(bw, 0.56, 0.06))
	board.rotation.y = turn
	_new_board.add_child(board)
	_sign = Label3D.new()
	_sign.text = "GALAXY RECRESS"
	_sign.font_size = 104
	_sign.pixel_size = minf(0.0042, (bw - 0.3) / (14.0 * 104.0 * 0.62))
	_sign.outline_size = 18
	_sign.shaded = false
	_sign.double_sided = false
	var p := spot(bx, 0.15)
	_sign.position = Vector3(p.x, base + 2.89, p.y)
	_sign.rotation.y = turn
	_new_board.add_child(_sign)
	_sign_glow = OmniLight3D.new()
	var gp := spot(x0, 1.2)
	_sign_glow.position = Vector3(gp.x, base + 3.0, gp.y)
	_sign_glow.light_color = Color(0.75, 0.35, 1.0)
	_sign_glow.omni_range = 6.0
	_sign_glow.light_energy = 1.6
	_street.add_child(_sign_glow)
	# the shutter rolled up: the doorway lit from inside, the roll of the shutter over it
	_front_open = Node3D.new()
	_street.add_child(_front_open)
	var c := spot(x0, 0.05)
	var hole := Parts.part("box", 0x1b0f2e, Vector3(c.x, base + SHUTTER_H / 2.0, c.y), Vector3(SHUTTER_W - 0.1, SHUTTER_H - 0.05, 0.06))
	hole.rotation.y = turn
	hole.material_override = _glow(0x2a1450, 0.9)
	_front_open.add_child(hole)
	var r := spot(x0, 0.22)
	var roll := Parts.part("box", 0x8a8a86, Vector3(r.x, base + SHUTTER_H + 0.05, r.y), Vector3(SHUTTER_W, 0.34, 0.36))
	roll.rotation.y = turn
	_front_open.add_child(roll)
	for k in [-1.0, 1.0]:                        # glass doors, standing open, with the light behind them
		var g := spot(x0 + k * 0.72, 0.1)
		var glass := Parts.part("box", 0x8fb7d9, Vector3(g.x, base + 1.15, g.y), Vector3(1.2, 2.3, 0.04))
		glass.rotation.y = turn
		glass.material_override = _glow(0x6a3cc0, 0.5)
		_front_open.add_child(glass)
	# a poster either side of the shutter (they go up for the tournament)
	for k in [-1.0, 1.0]:
		var q := _poster_quad(spot(x0 + k * (SHUTTER_W / 2.0 + 0.55), 0.03), out, base + 1.55, randf_range(-0.04, 0.04))
		q.visible = false
		_posters.append(q)
	set_open(false)

## the Recress open again (or still shut)
func set_open(v: bool) -> void:
	open = v
	_front_open.visible = v
	_sign_glow.visible = v
	_new_board.visible = v
	_sign.modulate = Color(1.0, 0.55, 0.95)
	_sign.outline_modulate = Color(0.35, 0.05, 0.6)
	for m in screens:
		m.set_shader_parameter("on", 1.0)

func show_posters(v: bool) -> void:
	for q in _posters:
		q.visible = v

## a tournament poster stuck on a wall: where (on the map), the way out of the wall, how high its middle is
func _poster_quad(at: Vector2, n: Vector2, y: float, tilt := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = POSTER
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_texture = _poster_tex
	m.roughness = 0.9
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(at.x, y, at.y)
	mi.rotation = Vector3(0.0, atan2(n.x, n.y), tilt)
	_street.add_child(mi)
	return mi

## a poster anywhere (a shop's front, for the mission): returns it
func poster_at(at: Vector2, n: Vector2, y: float) -> MeshInstance3D:
	return _poster_quad(at + n * 0.03, n, y, randf_range(-0.05, 0.05))

# ---------------- the hall ----------------
func _hall_build() -> void:
	_hall = Node3D.new()
	add_child(_hall)
	# the floor is a deck at one height (MapData.foot), whatever the field under it does
	var top := -1e9
	for dx in range(-int(W) - 1, int(W) + 2, 1):
		for dz in range(-2, int(D) + 2, 1):
			top = maxf(top, MapData.height(INSIDE + Vector2(dx, dz)))
	floor_y = top + 0.03
	var ring := PackedVector2Array([INSIDE + Vector2(-W - 0.6, -1.5), INSIDE + Vector2(W + 0.6, -1.5), INSIDE + Vector2(W + 0.6, D + 0.6), INSIDE + Vector2(-W - 0.6, D + 0.6)])
	MapData.decks.append({"o": INSIDE + Vector2(0.0, D / 2.0), "poly": ring, "r2": (W + 2.0) * (W + 2.0) + (D / 2.0 + 2.0) * (D / 2.0 + 2.0), "top": floor_y})
	_hall.position = Vector3(INSIDE.x, floor_y, INSIDE.y)
	_body = StaticBody3D.new()
	_body.collision_layer = 1
	_body.collision_mask = 0
	_hall.add_child(_body)
	in_door = INSIDE + Vector2(0.0, 0.45)
	in_spawn = INSIDE + Vector2(0.0, 2.2)
	machine = INSIDE + Vector2(0.0, D - 1.6)
	seat_you = INSIDE + Vector2(-0.55, D - 2.55)
	seat_other = INSIDE + Vector2(0.55, D - 2.55)
	mic = INSIDE + Vector2(-5.0, D - 2.4)
	duel_you = INSIDE + Vector2(0.0, 4.6)
	duel_him = INSIDE + Vector2(0.0, 7.8)
	aside = INSIDE + Vector2(5.2, D - 7.6)
	stage_you = INSIDE + Vector2(-0.9, D - 3.1)
	stage_other = INSIDE + Vector2(0.9, D - 3.1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2005
	for i in range(22):                          # the audience, in three rows well back from the stools: the heads here are
		var row := i / 8                         # a metre across, and the three metres in front of them are kept clear
		var k := i % 8                           # for the camera
		var x := lerpf(-3.2, 3.2, k / 7.0) + (0.4 if row % 2 == 1 else 0.0)
		crowd_spots.append(INSIDE + Vector2(x, D - 6.2 - row * 1.0 + rng.randf_range(-0.1, 0.1)))
	var r := _hall
	# floor, walls, ceiling
	var fl := _box(r, 0x150c26, Vector3(0, -0.05, D / 2.0), Vector3(W * 2.0, 0.1, D))
	fl.material_override = _checker(0x1d1033, 0x2a1748, 0.8)
	for sx in [-1.0, 1.0]:
		_box(r, 0x241640, Vector3(sx * (W + 0.15), H / 2.0, D / 2.0), Vector3(0.3, H, D + 0.6), true)
		_box(r, 0x241640, Vector3(sx * (W + 0.9) / 2.0, H / 2.0, -0.15), Vector3(W - 0.9, H, 0.3), true)       # either side of the door
		_neon(r, Vector3(sx * (W - 0.02), 3.1, D / 2.0), Vector3(0.04, 0.06, D - 0.4), 0xff3df0 if sx < 0 else 0x3df2ff)
	_box(r, 0x241640, Vector3(0, H / 2.0, D + 0.15), Vector3(W * 2.0 + 0.6, H, 0.3), true)
	_box(r, 0x241640, Vector3(0, (2.4 + H) / 2.0, -0.15), Vector3(1.8, H - 2.4, 0.3), true)
	_box(r, 0x110a1f, Vector3(0, H + 0.1, D / 2.0), Vector3(W * 2.0 + 0.6, 0.2, D + 0.6), true)
	_neon(r, Vector3(0, 3.6, D - 0.02), Vector3(W * 2.0 - 0.4, 0.06, 0.04), 0xffd23f)
	var door := _box(r, 0x8fb7d9, Vector3(0, 1.2, -0.12), Vector3(1.8, 2.4, 0.06), true)      # the way out
	door.material_override = _glow(0x6a7fd0, 0.35)
	_text(r, "SALIDA", Vector3(0, 2.62, 0.02), 64, 0x5dff7a)
	_text(r, "GALAXY RECRESS", Vector3(0, 3.35, D - 0.05), 150, 0xff6df5, PI)
	# the machines along the walls
	for i in range(4):
		for sx in [-1.0, 1.0]:
			var z := 3.4 + i * 2.6
			var pos := Vector3(sx * (W - 0.55), 0.0, z)
			_cabinet(r, pos, -sx * PI / 2.0, i * 2 + (0 if sx < 0 else 1), rng)
			cabinets.append([INSIDE + Vector2(sx * (W - 1.5), z), sx * PI / 2.0])      # [where you stand, facing the machine]
	# the final: the Tokken 9 machine for two, its stools, and the big screen over it for everybody
	_cabinet(r, Vector3(0.0, 0.0, D - 1.1), PI, 99, rng, true)
	for sx in [-0.55, 0.55]:
		_box(r, 0x2b2b30, Vector3(sx, 0.32, D - 2.55), Vector3(0.08, 0.64, 0.08))
		_box(r, 0xc0392b, Vector3(sx, 0.68, D - 2.55), Vector3(0.42, 0.08, 0.42))
	var frame := _box(r, 0x0c0c10, Vector3(0, 2.75, D - 0.25), Vector3(3.3, 1.95, 0.1))
	frame.material_override = _glow(0x0c0c10, 0.0)
	big_screen = _screen(r, Vector3(0, 2.75, D - 0.31), Vector2(3.0, 1.7), PI, 0.0)
	big_screen.set_shader_parameter("big", 1.0)
	# the commentator's corner: a small table and a microphone on its stand
	var mic3 := Vector3(-5.0 + 0.7, 0.0, D - 2.1)    # (at his mouth, a little to one side: not across his face)
	_box(r, 0x3a2a1a, mic3 + Vector3(-0.45, 0.4, 0.4), Vector3(0.7, 0.8, 0.5))
	_box(r, 0x202024, mic3 + Vector3(0.0, 0.56, 0.0), Vector3(0.03, 1.12, 0.03))
	_box(r, 0x111111, mic3 + Vector3(-0.06, 1.15, -0.05), Vector3(0.06, 0.11, 0.06))
	# light: cold over the machines, warm over the final, and the neon
	for z in [3.5, 8.5, 13.0]:
		_lamp(r, Vector3(-5.0, 3.6, z), 1.6, 9.0, 0xb98cff)
		_lamp(r, Vector3(5.0, 3.6, z), 1.6, 9.0, 0x7fe0ff)
	_lamp(r, Vector3(0, 3.8, D - 3.5), 2.4, 9.0, 0xffd8a0)
	_lamp(r, Vector3(0, 3.0, 1.5), 1.2, 6.0, 0xfff1d6)
	# confetti: two cannons over the audience (they go off when somebody wins)
	for sx in [-2.5, 2.5]:
		_confetti.append(_cannon(r, Vector3(sx, H - 0.35, D - 7.2)))

## a cabinet: body, a sloping screen, the panel with the stick and buttons, the lit marquee on top
func _cabinet(r: Node3D, pos: Vector3, turn: float, k: int, rng: RandomNumberGenerator, final := false) -> void:
	var c := Node3D.new()
	c.position = pos
	c.rotation.y = turn
	r.add_child(c)
	var wide := 1.5 if final else 0.82
	var body_hex: int = [0x2a2a8a, 0x8a1f2a, 0x1f6a3a, 0x222226, 0x5a1f7a, 0x8a5a10][k % 6] if not final else 0x161618
	var body := _box(c, body_hex, Vector3(0, 0.95, 0.0), Vector3(wide, 1.9, 0.72))
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(wide, 1.9, 0.72)
	cs.shape = bs
	cs.transform = c.transform * Transform3D(Basis(), Vector3(0, 0.95, 0.0))
	_body.add_child(cs)
	_box(c, 0x111114, Vector3(0, 0.98, 0.39), Vector3(wide - 0.06, 0.12, 0.12))          # the panel's lip
	var panel := _box(c, 0x1a1a1e, Vector3(0, 1.02, 0.48), Vector3(wide - 0.04, 0.06, 0.36))
	panel.rotation.x = -0.18
	for side in ([-0.36, 0.36] if final else [0.0]):
		_box(c, 0x111111, Vector3(side - 0.12, 1.12, 0.5), Vector3(0.025, 0.12, 0.025))   # the stick...
		var ball := Parts.part("sphere", 0xe23b3b, Vector3(side - 0.12, 1.19, 0.5), Vector3(0.07, 0.07, 0.07))
		c.add_child(ball)
		for b in range(3):                                                                # ...and the buttons
			var btn := Parts.part("sphere", [0xf2c230, 0x2f7fe0, 0x3fa34d][b], Vector3(side + 0.02 + b * 0.07, 1.09, 0.52 - (b % 2) * 0.03), Vector3(0.045, 0.02, 0.045))
			c.add_child(btn)
	var scr := _screen(c, Vector3(0, 1.48, 0.33), Vector2(wide - 0.22, 0.52), 0.0, rng.randf() * 30.0)
	scr.set_shader_parameter("on", 1.0)
	var marquee := _box(c, 0xffffff, Vector3(0, 1.98, 0.22), Vector3(wide, 0.28, 0.3))
	marquee.material_override = _glow([0xff3df0, 0x3df2ff, 0xffd23f, 0x5dff7a][k % 4] if not final else 0xff4040, 1.1)
	_text(c, "TOKKEN 9" if (final or k % 3 != 1) else "TOKKEN 2", Vector3(0, 1.98, 0.38), 48, 0x111111)

## a screen showing fights (screens[] is every one of them)
func _screen(parent: Node3D, pos: Vector3, size: Vector2, turn: float, offset: float) -> ShaderMaterial:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SCREEN_SHADER
	m.shader = sh
	m.set_shader_parameter("fight_a", load("res://assets/recress/pantalla_1.png"))
	m.set_shader_parameter("fight_b", load("res://assets/recress/pantalla_2.png"))
	m.set_shader_parameter("offset", offset)
	mi.material_override = m
	mi.position = pos
	mi.rotation = Vector3(-0.12, turn, 0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	screens.append(m)
	return m

## confetti falling from the ceiling, in every colour
func _cannon(parent: Node3D, pos: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = pos
	p.emitting = false
	p.one_shot = true
	p.amount = 420
	p.lifetime = 4.5
	p.explosiveness = 0.85
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(3.2, 0.2, 2.6)
	p.direction = Vector3(0, 1, 0)
	p.spread = 70.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 4.5
	p.gravity = Vector3(0, -2.2, 0)
	p.damping_min = 1.2
	p.damping_max = 2.2
	p.angular_velocity_min = -540.0
	p.angular_velocity_max = 540.0
	p.angle_min = 0.0
	p.angle_max = 360.0
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.045)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	q.material = m
	p.mesh = q
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
	grad.colors = PackedColorArray([Color("ff3df0"), Color("3df2ff"), Color("ffd23f"), Color("5dff7a"), Color("ff6b3d"), Color("ffffff")])
	p.color_initial_ramp = grad
	parent.add_child(p)
	return p

## everybody's confetti at once
func confetti() -> void:
	for c in _confetti:
		c.restart()
		c.emitting = true
	Sfx.noise(0.35, -8.0)
	Sfx.jingle([784, 988, 1175, 1568], 0.08)

func confetti_on() -> bool:
	return _confetti.any(func(c): return c.emitting)

## the big screen over the final: a white flash as the round ends (0..1, fading)
func knock_out(k: float) -> void:
	big_screen.set_shader_parameter("ko", k)

# ---------------- helpers (as vipshop.gd's) ----------------
func _box(parent: Node3D, hex: int, pos: Vector3, size: Vector3, solid := false) -> MeshInstance3D:
	var mi := Parts.part("box", hex, pos, size)
	parent.add_child(mi)
	if solid:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		cs.position = pos
		_body.add_child(cs)
	return mi

func _neon(parent: Node3D, pos: Vector3, size: Vector3, hex: int) -> void:
	var mi := Parts.part("box", hex, pos, size)
	mi.material_override = _glow(hex, 2.2)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)

func _text(parent: Node3D, s: String, pos: Vector3, px: int, hex: int, turn := 0.0) -> Label3D:
	var l := Label3D.new()
	l.text = s
	l.font_size = px
	l.pixel_size = 0.004
	l.modulate = Parts.col(hex)
	l.outline_size = 0
	l.shaded = false
	l.position = pos
	l.rotation.y = turn
	parent.add_child(l)
	return l

func _glow(hex: int, energy := 1.2) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Parts.col(hex)
	m.emission_enabled = true
	m.emission = Parts.col(hex)
	m.emission_energy_multiplier = energy
	return m

func _checker(a: int, b: int, metres: float) -> StandardMaterial3D:
	var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
	img.set_pixel(0, 0, Parts.col(a)); img.set_pixel(1, 1, Parts.col(a))
	img.set_pixel(1, 0, Parts.col(b)); img.set_pixel(0, 1, Parts.col(b))
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / (metres * 2.0)
	m.roughness = 0.6
	return m

func _lamp(parent: Node3D, pos: Vector3, energy: float, reach: float, hex := 0xfff1d6) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_energy = energy
	l.omni_range = reach
	l.light_color = Parts.col(hex)
	l.shadow_enabled = false
	parent.add_child(l)
