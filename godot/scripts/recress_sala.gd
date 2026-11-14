extends Node3D
## The Galaxy Recress: the town's amusement arcade, shut these twenty years (the user, 13 November 2026). Its front is
## the shop with the RECREATIVOS board and the roller shutter in the Calle de Zaragoza (house `zaragoza_8`, built by
## casas.gd); what is added here:
##   - on the street: its front, as it is (the old board, the shutter down) and as it is once it opens again (the
##     user's picture: its name in neon, glass doors, and the machines seen through them), and a tournament poster
##     either side of the doors;
##   - the hall itself, a set built far out in the fields like V.I.P.'s back room (vipshop.gd): you go in through the
##     shutter and come out of the set's door, and the other way round. Eight machines along the walls, their screens
##     playing fights, and at the back the Tokken 9 machine of the final, two stools and a big screen over it for the
##     audience; the commentator's corner; coloured lights; and confetti, for when somebody wins.

const Parts = preload("res://scripts/parts.gd")
const HOUSE := "zaragoza_8"
const SHUTTER_AT := 0.19         # where along the front the doorway is, how wide and high (casas_calles.gd: "gar .19 3.0 2.8 k=hueco":
const SHUTTER_W := 3.0           # the house leaves the hole, and what is in it is built here)
const SHUTTER_H := 2.8
const INSIDE := Vector2(-1500.0, -1650.0)        # the set (nothing within 400 m; the ground there is nearly level)
const W := 9.0                   # half the width of the hall
const D := 17.0                  # its depth
const H := 4.4
const POSTER := Vector2(0.62, 0.88)      # a tournament poster on a wall, in metres
## the fights on the screens: the user's six GIFs (referencias/recress/Tokken9_*.gif) made into assets/recress/peleas.png
## by tools/make_pantallas.py, which also prints how long each one's frames last, in milliseconds (these, in its order)
const FIGHT_MS := [160.0, 140.0, 160.0, 160.0, 180.0, 160.0]
const BIG_FIGHT := 2.0
## The bought-in machines (Sketchfab, CC Attribution: assets/recreativas/CREDITOS.txt), readied by
## tools/blender/recreativas.py: each faces +z, is its real height and stands on y = 0 round its middle. On each, where
## its screen is (its middle, its size, how far it leans back, in radians) and where its marquee is (middle, width; for
## the words TOKKEN 9 on it): measured on the models. The machines stand where the boxes that stop you are, as before.
const MODELS := "res://assets/recreativas/"
const MACHINES := {
	"neon_negra": {"screen": [Vector3(0.0, 1.237, -0.016), Vector2(0.58, 0.39), 0.15], "marquee": [Vector3(0.0, 1.82, 0.282), 0.42]},
	"estrellas": {"screen": [Vector3(0.0, 1.25, 0.152), Vector2(0.55, 0.37), 0.41]},
	"final": {"screen": [Vector3(0.0, 1.244, -0.322), Vector2(0.64, 0.42), 0.27], "marquee": [Vector3(0.0, 1.723, 0.238), 0.86], "cover": 0x9fdcef},
}                   # the one on the big screen over the final: Dracula against Frankenstein's monster

const SCREEN_SHADER := """
shader_type spatial;
render_mode unshaded, cull_back;
uniform sampler2D fights : source_color, filter_linear_mipmap;   // peleas.png: a fight to a row, its 8 frames across
uniform float rows = 6.0;
uniform float ms[16];               // how long each fight's frames last (FIGHT_MS)
uniform float fight = 0.0;          // the fight this screen starts on
uniform float offset = 0.0;
uniform float on = 1.0;
uniform float big = 0.0;            // the screen over the final: it stays on the one fight, the one being played
uniform float ko = 0.0;             // 1: the round is over (a white flash fading)
uniform float aspect = 1.0;         // the screen's width over its height (the fights are square: black either side)
void fragment() {
	float t = TIME + offset;
	float row = big > 0.5 ? fight : mod(fight + floor(t / 12.0), rows);   // one fight, then the next
	float frame = mod(floor(t * 1000.0 / max(ms[int(row)], 40.0)), 8.0);
	vec2 uv = vec2((UV.x - 0.5) * aspect + 0.5, UV.y);
	float inside = step(0.0, uv.x) * step(uv.x, 1.0);
	uv = clamp(uv, vec2(0.004), vec2(0.996));                              // (not into the edge of the next frame)
	vec3 c = texture(fights, vec2((frame + uv.x) / 8.0, (row + uv.y) / rows)).rgb * inside;
	c = mix(c, vec3(1.0), clamp(ko, 0.0, 1.0) * 0.8);
	float scan = 0.86 + 0.14 * sin(UV.y * 460.0);
	float vign = 1.0 - 0.5 * pow(length(UV - 0.5) * 1.35, 2.0);
	c *= scan * vign * (0.95 + 0.05 * sin(t * 47.0)) * on;
	ALBEDO = c * 0.2;
	EMISSION = c * 1.25;
}
"""

const MURAL_SHADER := """
shader_type spatial;
render_mode cull_back, ambient_light_disabled;
uniform vec3 origin;                // (the hall is far out: its own place, not the map's, for the noise)
uniform vec3 deep : source_color = vec3(0.035, 0.025, 0.08);
uniform vec3 violet : source_color = vec3(0.36, 0.1, 0.62);
uniform vec3 blue : source_color = vec3(0.08, 0.18, 0.58);
varying vec3 wpos;
varying vec3 wnrm;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz - origin;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int k = 0; k < 5; k++) { v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}
void fragment() {
	vec2 uv = abs(wnrm.x) > 0.5 ? wpos.zy : wpos.xy;
	float n1 = fbm(uv * 0.32 + vec2(3.1, 7.7));
	float n2 = fbm(uv * 0.55 + vec2(n1 * 1.6, n1 * 0.7));
	vec3 c = deep;
	c = mix(c, violet, smoothstep(0.42, 0.82, n2) * 0.95);
	c = mix(c, blue, smoothstep(0.5, 0.85, fbm(uv * 0.4 + vec2(11.0, 2.0))) * 0.75);
	vec2 g = uv * 9.0;
	float star = step(0.982, hash(floor(g))) * smoothstep(0.32, 0.0, length(fract(g) - 0.5));
	ALBEDO = c * 0.55;
	EMISSION = c * 0.4 + vec3(star) * 1.4;
	ROUGHNESS = 0.9;
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
var _shut: Node3D                # the front as it is: the old board, the shutter down
var _doors_open: Node3D          # the new front's glass doors standing open...
var _doors_shut: Node3D          # ...or shut
var state := "viejo"             # the front: "viejo" (as it is), "abierto" (done up, open), "cerrado" (done up, shut)
var _sign_glow: OmniLight3D
var _front_open: Node3D
var _posters: Array = []         # the two by the shutter
var _confetti: Array = []        # CPUParticles3D
var _poster_tex: Texture2D
var _street: Node3D
var _screen_shader: Shader
var _batch := {}                 # (while the front is built) material key -> [SurfaceTool, Material]
var _fonts := {}

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
## The front, as it is (Street View, November 2024): the old black board with stars and RECREATIVOS in yellow, a grey
## band, the roller shutter down -- sprayed on -- over a low dusty window, the meter box; the siren and the
## electricity's boxes up under the balcony, the cables along it.
## Open again (the user's picture of it, 14 November 2026): a great dark board with GALAXY RECRESS in neon (the
## user: it is called Galaxy Recress), a ring round RECRESS, a little alien on its left, a pad on its right and a line of light under it; the doorway in black
## frames, violet strips of light round it, the glass doors standing open; the walls black at the foot either side; a
## lit sign by the door (ARCADE, SIMULADORES, REALIDAD VIRTUAL, TORNEOS), a letterbox, the alarm's plate; and through
## the doors the arcade: machines either side, a driving seat, light in the ceiling, the name on the far wall. (What
## is seen through the doors is a stage inside the house: the hall you walk into is the set out in the fields.)
func _street_front() -> void:
	_street = Node3D.new()
	add_child(_street)
	var F := Node3D.new()                         # the front's own frame: x along it from its left end, y up, z out
	F.transform = Transform3D(Basis(Vector3(u.x, 0.0, u.y), Vector3.UP, Vector3(out.x, 0.0, out.y)), Vector3(o.x, base, o.y))
	_street.add_child(F)
	var xc := flen * SHUTTER_AT
	var x0 := xc - SHUTTER_W / 2.0
	var x1 := xc + SHUTTER_W / 2.0
	var pier_r: float = flen * 0.388 - 0.73      # (the right-hand wall ends at the frame of the next door: casas_calles.gd "door .388 0.85 ... sb=0.3")
	var rng := RandomNumberGenerator.new()
	rng.seed = 808
	# --- there either way: the siren, the electricity's boxes, the cables under the balcony; the eyes sprayed next door
	var both := Node3D.new()
	F.add_child(both)
	_cube(Vector3(0.08, 3.4, 0.0), Vector3(0.35, 0.35, 0.12), 0xeeeeea)
	_cube(Vector3(0.18, 3.47, 0.12), Vector3(0.15, 0.2, 0.03), 0xf08a20, 0.7)
	_cube(Vector3(0.12, 3.86, 0.0), Vector3(0.26, 0.32, 0.12), 0xe2e2de)
	_cube(Vector3(pier_r + 0.05, 3.3, 0.0), Vector3(0.26, 0.4, 0.12), 0xe2e2de)
	for cy in [4.02, 4.09]:
		_cube(Vector3(-0.3, cy, 0.14), Vector3(flen + 0.5, 0.022, 0.022), 0x1a1a1a)
	for ex in [flen * 0.528 - 0.4, flen * 0.528 + 0.42]:
		var e := Vector2(ex, 0.4)
		_stroke([e + Vector2(-0.14, 0.0), e + Vector2(-0.07, 0.065), e + Vector2(0.0, 0.08), e + Vector2(0.07, 0.065), e + Vector2(0.14, 0.0)], 0.045, 0.016, 0x2a4cb4)
		_stroke([e + Vector2(-0.14, 0.0), e + Vector2(-0.07, -0.055), e + Vector2(0.0, -0.07), e + Vector2(0.07, -0.055), e + Vector2(0.14, 0.0)], 0.045, 0.016, 0x2a4cb4)
		_ellipse(e, 0.04, 0.04, 0.0, 0.0, 360.0, 0.046, 0.014, 0x2a4cb4)
		_cube(Vector3(e.x - 0.015, e.y - 0.015, 0.045), Vector3(0.03, 0.03, 0.004), 0x1a2a6a)
		for k in range(4):
			var lx := -0.09 + k * 0.06
			_tube(e + Vector2(lx, 0.06), e + Vector2(lx * 1.3, 0.11), 0.045, 0.012, 0x2a4cb4)
	_bake(both)
	# --- shut
	_shut = Node3D.new()
	F.add_child(_shut)
	_cube(Vector3(0.0, 0.0, 0.0), Vector3(x0, 0.72, 0.06), 0xc4b4aa)                  # the foot of the wall, pinkish stone
	_cube(Vector3(0.62, 2.2, 0.0), Vector3(0.2, 0.55, 0.09), 0x9c9c98)                # the meter box
	_cube(Vector3(0.65, 2.55, 0.09), Vector3(0.14, 0.12, 0.01), 0x2c2e30)
	_cube(Vector3(x0 - 0.04, SHUTTER_H, 0.0), Vector3(SHUTTER_W + 0.08, 0.22, 0.08), 0x8c8c88)       # the grey band
	_cube(Vector3(x0 - 0.07, 3.02, 0.0), Vector3(SHUTTER_W + 0.25, 0.72, 0.1), 0x111216)            # the old board
	for i in range(24):
		_cube(Vector3(x0 - 0.03 + rng.randf() * (SHUTTER_W + 0.17), 3.05 + rng.randf() * 0.64, 0.1), Vector3(0.014, 0.014, 0.004), 0xf4f0e0, 0.5)
	_cube(Vector3(x0, 0.72, -0.14), Vector3(SHUTTER_W, SHUTTER_H - 0.72, 0.04), 0x8f8f8b)          # the shutter
	var sy := 0.82
	while sy < SHUTTER_H - 0.05:
		_cube(Vector3(x0, sy, -0.1), Vector3(SHUTTER_W, 0.018, 0.008), 0x6f706c)
		sy += 0.1
	_cube(Vector3(x0, 0.72, -0.1), Vector3(SHUTTER_W, 0.06, 0.03), 0x5e5f5c)
	for gx in [x0 - 0.02, x1 - 0.04]:
		_cube(Vector3(gx, 0.72, -0.16), Vector3(0.06, SHUTTER_H - 0.72, 0.09), 0x7a7b78)
	_cube(Vector3(x0, 0.12, -0.24), Vector3(SHUTTER_W, 0.6, 0.02), 0x5c5850)                       # under it, a low window, dusty
	for e in [[x0, 0.06], [x1 - 0.06, 0.06], [x0 + SHUTTER_W / 3.0 - 0.03, 0.06], [x0 + SHUTTER_W * 2.0 / 3.0 - 0.03, 0.06]]:
		_cube(Vector3(e[0], 0.12, -0.22), Vector3(e[1], 0.6, 0.04), 0xe6e4dc)
	for ey in [0.12, 0.67]:
		_cube(Vector3(x0, ey, -0.22), Vector3(SHUTTER_W, 0.05, 0.04), 0xe6e4dc)
	_cube(Vector3(x0 - 0.02, 0.0, -0.3), Vector3(SHUTTER_W + 0.04, 0.12, 0.5), 0xcac6bc)           # the step
	var tag := [                                  # sprayed on the shutter, in yellow, as it is: PIJOS RECI
		[[-1.2, 1.72], [-1.13, 2.12], [-0.99, 2.0], [-1.11, 1.88]],
		[[-0.9, 1.73], [-0.88, 2.1]],
		[[-0.77, 1.82], [-0.7, 1.73], [-0.63, 1.8], [-0.62, 2.12]],
		[[-0.43, 1.74], [-0.52, 1.9], [-0.44, 2.1], [-0.32, 1.96], [-0.39, 1.74]],
		[[-0.13, 2.08], [-0.25, 2.01], [-0.13, 1.9], [-0.03, 1.81], [-0.15, 1.72]],
		[[0.24, 1.73], [0.27, 2.12], [0.4, 2.03], [0.28, 1.94], [0.43, 1.73]],
		[[0.63, 2.1], [0.51, 2.1], [0.51, 1.74], [0.64, 1.74]], [[0.51, 1.92], [0.61, 1.93]],
		[[0.85, 2.07], [0.72, 2.02], [0.72, 1.79], [0.87, 1.73]],
		[[1.0, 1.72], [1.03, 2.1]]]
	for line in tag:
		var pts: Array = []
		for q in line:
			pts.append(Vector2(xc + q[0] + rng.randf_range(-0.012, 0.012), q[1] + rng.randf_range(-0.012, 0.012)))
		_stroke(pts, -0.09, 0.04, 0xd9bf3a)
	_bake(_shut)
	_lit_words(_shut, "RECREATIVOS", Vector3(xc + 0.09, 3.38, 0.104), 0.3, SHUTTER_W - 0.2, 0xe8c43a, 0x8a6a10, -1, false)
	# --- open again
	_front_open = Node3D.new()
	F.add_child(_front_open)
	_cube(Vector3(0.0, 0.0, 0.0), Vector3(x0 - 0.05, 0.9, 0.06), 0x1b1b20)                        # black at the foot of the walls
	_cube(Vector3(x1 + 0.05, 0.0, 0.0), Vector3(pier_r - x1 - 0.05, 0.9, 0.06), 0x1b1b20)
	for px in [x0, x1 - 0.07]:                                                                       # the doorway's black frame
		_cube(Vector3(px, 0.0, -0.12), Vector3(0.07, SHUTTER_H, 0.1), 0x18181c)
	_cube(Vector3(x0, 2.42, -0.12), Vector3(SHUTTER_W, 0.08, 0.1), 0x18181c)
	_cube(Vector3(x0, 2.5, -0.14), Vector3(SHUTTER_W, SHUTTER_H - 2.5, 0.09), 0x202028)            # the box the shutter rolls into
	_cube(Vector3(x0 + 0.07, 2.5, -0.05), Vector3(SHUTTER_W - 0.14, 0.012, 0.01), 0xb45cff, 2.4)
	_cube(Vector3(x0 - 0.045, 0.02, 0.0), Vector3(0.03, SHUTTER_H + 0.03, 0.03), 0xa64dff, 3.0)    # the strips of light round it
	_cube(Vector3(x1 + 0.015, 0.02, 0.0), Vector3(0.03, SHUTTER_H + 0.03, 0.03), 0xa64dff, 3.0)
	_cube(Vector3(x0 - 0.045, SHUTTER_H + 0.02, 0.0), Vector3(SHUTTER_W + 0.09, 0.03, 0.03), 0xa64dff, 3.0)
	_cube(Vector3(x0 - 0.02, 0.0, -0.3), Vector3(SHUTTER_W + 0.04, 0.04, 0.52), 0xd2cfc8)          # the threshold
	_bake(_front_open)
	_doors_open = Node3D.new()
	_front_open.add_child(_doors_open)
	_doors_shut = Node3D.new()
	_front_open.add_child(_doors_shut)
	var wl := SHUTTER_W / 2.0 - 0.07                                                                 # the glass doors, standing open...
	var pivot_l := Transform3D(Basis(Vector3.UP, 1.25), Vector3(x0 + 0.07, 0.0, -0.07))
	var pivot_r := Transform3D(Basis(Vector3.UP, -1.25), Vector3(x1 - 0.07, 0.0, -0.07))
	var shut_l := Transform3D(Basis(), Vector3(x0 + 0.07, 0.0, -0.07))
	var shut_r := Transform3D(Basis(), Vector3(x1 - 0.07, 0.0, -0.07))
	for leaf in [[pivot_l, 1.0, false], [pivot_r, -1.0, false], [shut_l, 1.0, true], [shut_r, -1.0, true]]:
		var pv: Transform3D = leaf[0]
		var sx: float = leaf[1]
		_bx(pv * Transform3D(Basis(), Vector3(sx * wl / 2.0, 1.22, 0.0)), Vector3(wl - 0.06, 2.34, 0.012), -1)
		for e in [[wl / 2.0, 0.04, wl, 0.08], [wl / 2.0, 2.4, wl, 0.06], [0.02, 1.22, 0.04, 2.44], [wl - 0.02, 1.22, 0.04, 2.44], [wl / 2.0, 0.42, wl, 0.05]]:
			_bx(pv * Transform3D(Basis(), Vector3(sx * e[0], e[1], 0.0)), Vector3(e[2], e[3], 0.03), 0x18181c)
		for hz in [0.035, -0.035]:                                                                   # the long handle, both sides
			_bx(pv * Transform3D(Basis(), Vector3(sx * (wl - 0.11), 1.2, hz * 2.0)), Vector3(0.025, 0.95, 0.025), 0xc9cace)
			for hy in [0.78, 1.62]:
				_bx(pv * Transform3D(Basis(), Vector3(sx * (wl - 0.11), hy, hz)), Vector3(0.02, 0.02, 0.07), 0xc9cace)
		if leaf[2] == false and sx < 0.0:
			_bake(_doors_open)
	_bake(_doors_shut)                                                                               # ...or shut
	# the board
	var bx0 := x0 - 0.35
	var bw := SHUTTER_W + 0.7
	_cube(Vector3(bx0 - 0.02, 2.86, 0.0), Vector3(bw + 0.04, 1.06, 0.17), 0x2a2a30)
	_cube(Vector3(bx0, 2.88, 0.0), Vector3(bw, 1.02, 0.2), 0x0c0b14)
	for i in range(34):
		_cube(Vector3(bx0 + 0.05 + rng.randf() * (bw - 0.1), 2.93 + rng.randf() * 0.92, 0.2), Vector3(0.012, 0.012, 0.003), 0xe8e4ff, 0.8)
	var face := 0.204
	_ellipse(Vector2(xc + 0.04, 3.25), 1.4, 0.25, 0.08, 150.0, 405.0, face, 0.024, 0xc04dff, 3.0)    # the ring round RECRESS
	_tube(Vector2(xc - 1.0, 2.96), Vector2(xc + 1.0, 2.96), face, 0.022, 0x35c8ff, 3.0)               # the line under it
	var alien := ["...X...X...", "....X.X....", "..XXXXXXX..", ".XX.XXX.XX.", "XXXXXXXXXXX", "X.XXXXXXX.X", "X.X.....X.X", "..XX...XX.."]
	for r in range(alien.size()):
		for c in range(11):
			if alien[r][c] == "X":
				_cube(Vector3(x0 + 0.03 + (c - 5.5) * 0.031, 3.53 - r * 0.031, face - 0.004), Vector3(0.027, 0.027, 0.012), 0x3de2ff, 2.6)
	var pad := Vector2(x1 + 0.08, 3.46)
	var shape := [[-0.14, 0.1], [0.14, 0.1], [0.18, 0.08], [0.2, 0.03], [0.22, -0.05], [0.22, -0.1], [0.19, -0.13], [0.15, -0.12], [0.1, -0.06], [-0.1, -0.06], [-0.15, -0.12], [-0.19, -0.13], [-0.22, -0.1], [-0.22, -0.05], [-0.2, 0.03], [-0.18, 0.08], [-0.14, 0.1]]
	var outline: Array = []
	for q in shape:
		outline.append(pad + Vector2(q[0], q[1]))
	_stroke(outline, face, 0.02, 0x3f86ff, 3.0)
	_tube(pad + Vector2(-0.15, 0.02), pad + Vector2(-0.07, 0.02), face, 0.02, 0x3f86ff, 3.0)
	_tube(pad + Vector2(-0.11, -0.02), pad + Vector2(-0.11, 0.06), face, 0.02, 0x3f86ff, 3.0)
	for b in [Vector2(0.09, 0.04), Vector2(0.14, 0.0), Vector2(0.09, -0.02), Vector2(0.04, 0.0)]:
		_ellipse(pad + b, 0.014, 0.014, 0.0, 0.0, 360.0, face, 0.01, 0x3f86ff, 3.0)
	# the lit sign by the door
	var sx0 := x1 + 0.08
	var sw := 0.32                                 # (a hair over the next door's frame, as in the picture)
	var scx := sx0 + sw / 2.0
	_cube(Vector3(sx0, 1.0, 0.0), Vector3(sw, 1.36, 0.06), 0x14111e)
	_stroke([Vector2(sx0 + 0.015, 1.015), Vector2(sx0 + sw - 0.015, 1.015), Vector2(sx0 + sw - 0.015, 2.345), Vector2(sx0 + 0.015, 2.345), Vector2(sx0 + 0.015, 1.015)], 0.064, 0.012, 0xb45cff, 2.6)
	var ink := 0xeadcff
	var cy0 := 2.18
	var ic := Vector2(scx, cy0 + 0.05)                                                                # a stick, for ARCADE
	_stroke([ic + Vector2(-0.05, -0.04), ic + Vector2(0.05, -0.04), ic + Vector2(0.05, -0.015), ic + Vector2(-0.05, -0.015), ic + Vector2(-0.05, -0.04)], 0.064, 0.008, ink, 1.8)
	_tube(ic + Vector2(0.0, -0.015), ic + Vector2(0.0, 0.03), 0.064, 0.008, ink, 1.8)
	_ellipse(ic + Vector2(0.0, 0.045), 0.016, 0.016, 0.0, 0.0, 360.0, 0.064, 0.008, ink, 1.8)
	ic = Vector2(scx, cy0 - 0.32 + 0.05)                                                             # a wheel, for SIMULADORES
	_ellipse(ic, 0.045, 0.045, 0.0, 0.0, 360.0, 0.064, 0.008, ink, 1.8)
	_tube(ic + Vector2(-0.045, 0.0), ic + Vector2(0.045, 0.0), 0.064, 0.008, ink, 1.8)
	_tube(ic, ic + Vector2(0.0, -0.045), 0.064, 0.008, ink, 1.8)
	ic = Vector2(scx, cy0 - 0.64 + 0.05)                                                             # the goggles, for REALIDAD VIRTUAL
	_stroke([ic + Vector2(-0.06, -0.03), ic + Vector2(0.06, -0.03), ic + Vector2(0.06, 0.03), ic + Vector2(-0.06, 0.03), ic + Vector2(-0.06, -0.03)], 0.064, 0.008, ink, 1.8)
	for lx in [-0.028, 0.028]:
		_ellipse(ic + Vector2(lx, 0.0), 0.016, 0.016, 0.0, 0.0, 360.0, 0.064, 0.007, ink, 1.8)
	ic = Vector2(scx, cy0 - 0.96 + 0.05)                                                             # a cup, for TORNEOS
	_stroke([ic + Vector2(-0.035, 0.04), ic + Vector2(-0.03, 0.0), ic + Vector2(0.0, -0.015), ic + Vector2(0.03, 0.0), ic + Vector2(0.035, 0.04), ic + Vector2(-0.035, 0.04)], 0.064, 0.008, ink, 1.8)
	_tube(ic + Vector2(0.0, -0.015), ic + Vector2(0.0, -0.035), 0.064, 0.008, ink, 1.8)
	_tube(ic + Vector2(-0.025, -0.038), ic + Vector2(0.025, -0.038), 0.064, 0.008, ink, 1.8)
	# the letterbox, the alarm's plate
	_cube(Vector3(0.66, 0.95, 0.0), Vector3(0.24, 0.32, 0.1), 0x1c1c1e)
	_cube(Vector3(0.69, 1.18, 0.1), Vector3(0.18, 0.015, 0.004), 0x55555a)
	_cube(Vector3(0.62, 2.35, 0.0), Vector3(0.18, 0.24, 0.012), 0xf2f0ea)
	_cube(Vector3(0.62, 2.52, 0.012), Vector3(0.18, 0.06, 0.003), 0xc8202a)
	_bake(_front_open)
	_lit_words(_front_open, "GALAXY", Vector3(xc + 0.02, 3.66, face + 0.004), 0.25, 2.0, 0xffffff, 0xd2a8ff, 0xa64dff)
	_lit_words(_front_open, "RECRESS", Vector3(xc + 0.04, 3.25, face + 0.006), 0.3, 2.1, 0xcf5cff, 0xf2ccff, 0x9a3dff)
	var words := ["ARCADE", "SIMULADORES", "REALIDAD\nVIRTUAL", "TORNEOS"]
	for i in range(4):
		_lit_words(_front_open, words[i], Vector3(scx, cy0 - i * 0.32 - (0.1 if i != 2 else 0.115), 0.066), 0.03, sw - 0.05, 0xf2eaff, 0x6a3aa0, -1, false)
	_lit_words(_front_open, "ALARMA", Vector3(0.71, 2.55, 0.017), 0.03, 0.15, 0xffffff, 0xc8202a, -1, false)
	_stage(xc)
	_sign_glow = OmniLight3D.new()
	_sign_glow.position = Vector3(xc, 2.5, 1.1)
	_sign_glow.light_color = Color(0.72, 0.4, 1.0)
	_sign_glow.omni_range = 5.5
	_sign_glow.light_energy = 1.3
	F.add_child(_sign_glow)
	# a tournament poster either side of the doors (they go up for the tournament): on the wall on the left; on the
	# right, a smaller one on the narrow bit of wall while it is shut, and taped on the glass door once it is open
	var qa := _poster_quad(spot(0.56, 0.03), out, base + 1.72, randf_range(-0.04, 0.04))       # (clear of the post in front of the wall)
	qa.visible = false
	_posters.append(qa)
	var qb := qa.duplicate() as MeshInstance3D
	_doors_open.add_child(qb)
	qb.transform = pivot_r * Transform3D(Basis(), Vector3(-wl * 0.55, 1.45, 0.012))
	_posters.append(qb)
	var qd := qa.duplicate() as MeshInstance3D
	_doors_shut.add_child(qd)
	qd.transform = shut_r * Transform3D(Basis(), Vector3(-wl * 0.55, 1.45, 0.025))
	_posters.append(qd)
	var qc := qa.duplicate() as MeshInstance3D
	_shut.add_child(qc)
	qc.transform = Transform3D(Basis(Vector3.BACK, 0.03).scaled(Vector3(0.58, 0.58, 1.0)), Vector3((x1 + pier_r) / 2.0, 1.6, 0.065))
	_posters.append(qc)
	set_open(false)

## What is seen through the open doors: a room 4.5 m wide and 8 deep inside the house -- machines along both walls
## facing in, a driving seat in the middle, a grid of light in the ceiling, a ring on the floor, the name on the far wall.
func _stage(xc: float) -> void:
	var stage := Node3D.new()
	_front_open.add_child(stage)
	var hw := 2.25
	var deep := 8.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	_cube(Vector3(xc - hw, -0.05, -deep), Vector3(hw * 2.0, 0.05, deep - 0.3), 0x17141f)              # floor
	_cube(Vector3(xc - hw, 3.0, -deep), Vector3(hw * 2.0, 0.06, deep - 0.3), 0x0e0d16)                 # ceiling
	for sx in [xc - hw - 0.06, xc + hw]:
		_cube(Vector3(sx, 0.0, -deep), Vector3(0.06, 3.0, deep - 0.3), 0x15132e)                     # side walls
		_cube(Vector3(sx + (0.062 if sx < xc else -0.012), 2.35, -deep + 0.2), Vector3(0.012, 0.03, deep - 0.6), 0xa64dff, 2.6)
	_cube(Vector3(xc - hw, 0.0, -deep - 0.06), Vector3(hw * 2.0, 3.0, 0.06), 0x120f26)                 # back wall
	var lines := [[-1.2, 0xb04dff], [0.0, 0x2f8fff], [1.2, 0xb04dff]]
	for ln in lines:
		_cube(Vector3(xc + float(ln[0]) - 0.02, 2.96, -deep + 0.4), Vector3(0.04, 0.03, deep - 1.0), int(ln[1]), 3.0)
	for zz in [-1.4, -3.3, -5.2, -7.1]:
		_cube(Vector3(xc - 1.6, 2.955, zz - 0.02), Vector3(3.2, 0.03, 0.04), 0x2f8fff if zz > -3.0 or zz < -6.0 else 0xb04dff, 3.0)
	var flat := Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3(0.0, 0.006, 0.0))                # a ring on the floor
	_ellipse(Vector2(xc, 5.0), 0.7, 0.7, 0.0, 0.0, 360.0, 0.0, 0.03, 0x9a4dff, 1.6, flat)
	_ellipse(Vector2(xc, 5.0), 0.5, 0.5, 0.0, 0.0, 360.0, 0.0, 0.015, 0x9a4dff, 1.2, flat)
	for k in range(5):
		var a := TAU * k / 5.0 + PI / 2.0
		_tube(Vector2(xc, 5.0), Vector2(xc + cos(a) * 0.45, 5.0 + sin(a) * 0.45), 0.0, 0.02, 0x9a4dff, 1.2, flat)
	for i in range(5):                                                                              # the machines
		var zz := -1.55 - i * 1.15
		_mini_cabinet(stage, Vector3(xc - hw + 0.42, 0.0, zz), PI / 2.0, i, rng)
		_mini_cabinet(stage, Vector3(xc + hw - 0.42, 0.0, zz), -PI / 2.0, i + 3, rng)
	var seat := Transform3D(Basis(), Vector3(xc - 0.25, 0.0, -3.3))                                   # the driving seat, facing in
	_bx(seat * Transform3D(Basis(), Vector3(0.0, 0.08, -0.3)), Vector3(0.6, 0.16, 1.6), 0x26262c)
	_bx(seat * Transform3D(Basis(), Vector3(0.0, 0.42, 0.05)), Vector3(0.52, 0.14, 0.5), 0xe8621c)
	_bx(seat * Transform3D(Basis(Vector3.RIGHT, -0.28), Vector3(0.0, 0.85, 0.32)), Vector3(0.52, 0.8, 0.12), 0xe8621c)
	_bx(seat * Transform3D(Basis(), Vector3(0.0, 0.25, 0.05)), Vector3(0.3, 0.3, 0.3), 0x26262c)
	for sxs in [-0.2, 0.2]:
		_bx(seat * Transform3D(Basis(Vector3.RIGHT, -0.28), Vector3(sxs, 0.95, 0.39)), Vector3(0.1, 0.5, 0.02), 0x222226)
	_bx(seat * Transform3D(Basis(), Vector3(0.0, 0.55, -0.7)), Vector3(0.08, 0.5, 0.08), 0x26262c)
	_ellipse(Vector2(0.0, 0.85), 0.16, 0.16, 0.0, 0.0, 360.0, 0.0, 0.03, 0x1a1a1e, 0.0, seat * Transform3D(Basis(Vector3.RIGHT, -0.4), Vector3(0.0, 0.0, -0.62)))
	_bx(seat * Transform3D(Basis(), Vector3(0.0, 0.6, -1.15)), Vector3(0.1, 1.2, 0.1), 0x26262c)
	_bake(stage)
	var scr := _screen(stage, Vector3(xc - 0.25, 1.3, -4.4), Vector2(1.0, 0.6), 0.0, 3.3)
	scr.set_shader_parameter("on", 1.0)
	_lit_words(stage, "GALAXY", Vector3(xc, 2.18, -deep + 0.02), 0.2, 1.7, 0xffffff, 0xd2a8ff, 0xa64dff)
	_lit_words(stage, "RECRESS", Vector3(xc, 1.85, -deep + 0.025), 0.25, 1.8, 0xcf5cff, 0xf2ccff, 0x9a3dff)
	_ellipse(Vector2(xc, 1.85), 1.15, 0.2, 0.08, 150.0, 405.0, -deep + 0.03, 0.02, 0xc04dff, 3.0)
	_bake(stage)
	for lp in [[Vector3(xc, 2.5, -3.0), 0xb070ff, 1.5, 6.5], [Vector3(xc, 2.5, -6.5), 0x4f8fff, 1.1, 5.0]]:
		var l := OmniLight3D.new()
		l.position = lp[0]
		l.light_color = Parts.col(lp[1])
		l.light_energy = lp[2]
		l.omni_range = lp[3]
		l.shadow_enabled = false
		stage.add_child(l)

## a machine seen from the street: body, a lit edge down its front, the screen playing fights, the lit marquee
func _mini_cabinet(parent: Node3D, pos: Vector3, turn: float, k: int, rng: RandomNumberGenerator) -> void:
	var c := Node3D.new()
	c.position = pos
	c.rotation.y = turn
	parent.add_child(c)
	if ResourceLoader.exists(MODELS + "neon_negra.glb"):        # (the same machines as in the hall)
		_machine(c, ["neon_negra", "estrellas"][k % 2], rng)
		return
	var xf := Transform3D(Basis(Vector3.UP, turn), pos)
	var body: int = [0x24206a, 0x6a1a3a, 0x1a4a6a, 0x3a1a6a, 0x1c1c26, 0x5a3a10][k % 6]
	var edge: int = [0x3df2ff, 0xff3df0, 0x5dff7a, 0xffd23f][k % 4]
	_bx(xf * Transform3D(Basis(), Vector3(0.0, 0.92, 0.0)), Vector3(0.74, 1.84, 0.7), body)
	_bx(xf * Transform3D(Basis(), Vector3(0.0, 1.02, 0.43)), Vector3(0.7, 0.07, 0.3), 0x18181c)
	for ex in [-0.375, 0.375]:
		_bx(xf * Transform3D(Basis(), Vector3(ex, 0.92, 0.35)), Vector3(0.015, 1.84, 0.015), edge, 2.2)
	_bx(xf * Transform3D(Basis(), Vector3(0.0, 1.95, 0.22)), Vector3(0.74, 0.22, 0.26), [0xff3df0, 0x3df2ff, 0xffd23f, 0x5dff7a][(k + 1) % 4], 1.4)
	var m := _screen(c, Vector3(0.0, 1.42, 0.355), Vector2(0.58, 0.46), 0.0, rng.randf() * 30.0)
	m.set_shader_parameter("on", 1.0)

## The front's three looks (the user, 14 November 2026): "viejo" -- as it is, shut these twenty years; "abierto" --
## done up and open, from the tournament on (you can go in: `open`); "cerrado" -- done up, its glass doors shut, the
## light still on inside (only once the tournament's scene is over).
func set_state(s: String) -> void:
	state = s
	open = s == "abierto"
	_front_open.visible = s != "viejo"
	_shut.visible = s == "viejo"
	_doors_open.visible = s == "abierto"
	_doors_shut.visible = s == "cerrado"
	_sign_glow.visible = s != "viejo"
	for m in screens:
		m.set_shader_parameter("on", 1.0)

## the Recress open again (or still as it was)
func set_open(v: bool) -> void:
	set_state("abierto" if v else "viejo")

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

# ---------------- building the front: boxes gathered into one mesh to a colour ----------------
## a box into the batch: its middle and its turn in `xf` (the front's frame), its size; a colour (-1: glass), lit if
## `energy` is more than 0
func _bx(xf: Transform3D, size: Vector3, hex: int, energy := 0.0) -> void:
	var key := "glass" if hex < 0 else "%06x/%.1f" % [hex, energy]
	if not _batch.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_batch[key] = [st, _glass_mat() if hex < 0 else (_glow(hex, energy) if energy > 0.0 else Parts.mat(hex))]
	var st: SurfaceTool = _batch[key][0]
	var h := size / 2.0
	for ax in range(3):
		for s in [-1.0, 1.0]:
			var n := Vector3.ZERO
			n[ax] = s
			var b := (ax + 1) % 3
			var c := (ax + 2) % 3
			var q: Array = []
			for uv in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
				var p := Vector3.ZERO
				p[ax] = s * h[ax]
				p[b] = uv.x * h[b]
				p[c] = uv.y * h[c]
				q.append(xf * p)
			var nw: Vector3 = (xf.basis * n).normalized()
			for t in [[0, 1, 2], [0, 2, 3]]:
				var p0: Vector3 = q[t[0]]
				var p1: Vector3 = q[t[1]]
				var p2: Vector3 = q[t[2]]
				if (p1 - p0).cross(p2 - p0).dot(nw) > 0.0:       # (Godot wants clockwise front faces)
					var sw := p1
					p1 = p2
					p2 = sw
				for p in [p0, p1, p2]:
					st.set_normal(nw)
					st.add_vertex(p)

## a box by its left, bottom, back corner and its size, as casas.gd has them
func _cube(corner: Vector3, size: Vector3, hex: int, energy := 0.0) -> void:
	_bx(Transform3D(Basis(), corner + size / 2.0), size, hex, energy)

## a stroke from a to b in the front's plane (x along, y up), `z` out: a tube of light, or of paint
func _tube(a: Vector2, b: Vector2, z: float, thick: float, hex: int, energy := 0.0, xf := Transform3D.IDENTITY) -> void:
	var d := b - a
	if d.length() < 0.0001:
		return
	_bx(xf * Transform3D(Basis(Vector3.BACK, atan2(d.y, d.x)), Vector3((a.x + b.x) / 2.0, (a.y + b.y) / 2.0, z)), Vector3(d.length() + thick, thick, thick), hex, energy)

func _stroke(pts: Array, z: float, thick: float, hex: int, energy := 0.0, xf := Transform3D.IDENTITY) -> void:
	for i in range(pts.size() - 1):
		_tube(pts[i], pts[i + 1], z, thick, hex, energy, xf)

## part of an ellipse round `c`, from a0 to a1 degrees, turned by `tilt`
func _ellipse(c: Vector2, rx: float, ry: float, tilt: float, a0: float, a1: float, z: float, thick: float, hex: int, energy := 0.0, xf := Transform3D.IDENTITY) -> void:
	var pts: Array = []
	var n := maxi(8, int(absf(a1 - a0) / 7.0))
	for i in range(n + 1):
		var a := deg_to_rad(lerpf(a0, a1, float(i) / n))
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(tilt))
	_stroke(pts, z, thick, hex, energy, xf)

## the batch made into meshes under `parent`
func _bake(parent: Node3D) -> void:
	for key in _batch:
		var mi := MeshInstance3D.new()
		mi.mesh = (_batch[key][0] as SurfaceTool).commit()
		mi.material_override = _batch[key][1]
		if String(key) == "glass" or String(key).get_slice("/", 1).to_float() > 0.0:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
	_batch.clear()

func _glass_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.75, 0.82, 0.95, 0.16)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.metallic = 0.3
	m.roughness = 0.05
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

## the letters of the boards: bold, and slanted for the neon
func _font(slant: bool) -> Font:
	if not _fonts.has(slant):
		var f := FontVariation.new()
		f.base_font = ThemeDB.fallback_font
		f.variation_embolden = 1.0 if slant else 0.6
		if slant:
			f.variation_transform = Transform2D(Vector2(1.0, 0.2), Vector2(0.0, 1.0), Vector2.ZERO)
		_fonts[slant] = f
	return _fonts[slant]

## words on a board, in the front's frame: their capitals `high` metres, no wider than `fit`; with a faint halo of
## colour `halo` round them, unless it is -1
func _lit_words(parent: Node3D, s: String, pos: Vector3, high: float, fit: float, hex: int, edge: int, halo: int, slant := true) -> Label3D:
	var px := 128
	var font := _font(slant)
	var wide: float = font.get_multiline_string_size(s, HORIZONTAL_ALIGNMENT_CENTER, -1, px).x
	var size := minf(high / (px * 0.72), fit / maxf(1.0, wide))
	var main: Label3D = null
	for k in ([0, 1] if halo >= 0 else [1]):
		var l := Label3D.new()
		l.text = s
		l.font = font
		l.font_size = px
		l.pixel_size = size
		l.shaded = false
		l.double_sided = false
		l.position = pos + Vector3(0.0, 0.0, -0.004 if k == 0 else 0.0)
		if k == 0:                           # the halo: only an outline, wide and faint
			var hc := Parts.col(halo)
			l.modulate = Color(1.0, 1.0, 1.0, 0.0)
			l.outline_modulate = Color(hc.r, hc.g, hc.b, 0.3)
			l.outline_size = 44
			l.render_priority = 1
		else:
			l.modulate = Parts.col(hex)
			l.outline_modulate = Parts.col(edge)
			l.outline_size = 6
			l.render_priority = 2
			main = l
		parent.add_child(l)
	return main

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
	# (the user's pictures of it, 14 November 2026: a galaxy painted on dark walls, dark glossy tiles, neon in the
	# ceiling, black machines edged in light. The boxes that stop you are the same as ever: only their dress changes.)
	var fl := _box(r, 0x150c26, Vector3(0, -0.05, D / 2.0), Vector3(W * 2.0, 0.1, D))
	fl.material_override = _tiles()
	var mural := _mural()
	for sx in [-1.0, 1.0]:
		_box(r, 0x241640, Vector3(sx * (W + 0.15), H / 2.0, D / 2.0), Vector3(0.3, H, D + 0.6), true).material_override = mural
		_box(r, 0x241640, Vector3(sx * (W + 0.9) / 2.0, H / 2.0, -0.15), Vector3(W - 0.9, H, 0.3), true).material_override = mural       # either side of the door
		_neon(r, Vector3(sx * (W - 0.02), 3.1, D / 2.0), Vector3(0.04, 0.06, D - 0.4), 0xa64dff if sx < 0 else 0x3f86ff)
	_box(r, 0x241640, Vector3(0, H / 2.0, D + 0.15), Vector3(W * 2.0 + 0.6, H, 0.3), true).material_override = mural
	_box(r, 0x241640, Vector3(0, (2.4 + H) / 2.0, -0.15), Vector3(1.8, H - 2.4, 0.3), true).material_override = mural
	var roof := StandardMaterial3D.new()
	roof.albedo_color = Parts.col(0x0c0a14)
	roof.roughness = 0.8
	roof.disable_ambient_light = true
	_box(r, 0x0c0a14, Vector3(0, H + 0.1, D / 2.0), Vector3(W * 2.0 + 0.6, 0.2, D + 0.6), true).material_override = roof
	_neon(r, Vector3(0, H - 0.1, D - 0.02), Vector3(W * 2.0 - 0.4, 0.05, 0.04), 0xa64dff)
	var door := _box(r, 0x8fb7d9, Vector3(0, 1.2, -0.12), Vector3(1.8, 2.4, 0.06), true)      # the way out
	door.material_override = _glow(0xdfe4ec, 0.22)
	_box(r, 0x1f9a4a, Vector3(0, 2.62, 0.03), Vector3(0.62, 0.2, 0.06)).material_override = _glow(0x1f9a4a, 1.2)
	_text(r, "SALIDA", Vector3(0, 2.62, 0.065), 40, 0xffffff)
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
	big_screen.set_shader_parameter("fight", BIG_FIGHT)
	# the commentator's corner: a small table and a microphone on its stand
	var mic3 := Vector3(-5.0 + 0.7, 0.0, D - 2.1)    # (at his mouth, a little to one side: not across his face)
	_box(r, 0x3a2a1a, mic3 + Vector3(-0.45, 0.4, 0.4), Vector3(0.7, 0.8, 0.5))
	_box(r, 0x202024, mic3 + Vector3(0.0, 0.56, 0.0), Vector3(0.03, 1.12, 0.03))
	_box(r, 0x111111, mic3 + Vector3(-0.06, 1.15, -0.05), Vector3(0.06, 0.11, 0.06))
	# light: cold over the machines, warm over the final, and the neon
	for z in [3.5, 8.5, 13.0]:
		_lamp(r, Vector3(-5.0, 3.6, z), 1.6, 9.0, 0xa27aff)
		_lamp(r, Vector3(5.0, 3.6, z), 1.6, 9.0, 0x6a9cff)
	_lamp(r, Vector3(0, 3.8, D - 3.5), 2.4, 9.0, 0xffd8a0)
	_lamp(r, Vector3(0, 3.0, 1.5), 1.2, 6.0, 0xfff1d6)
	# confetti: two cannons over the audience (they go off when somebody wins)
	for sx in [-2.5, 2.5]:
		_confetti.append(_cannon(r, Vector3(sx, H - 0.35, D - 7.2)))
	_hall_dress(r)
	_hall_models(r)

## What the hall wears (the user's pictures, 14 November 2026), none of it in anybody's way: a tray of neon in the
## ceiling with its downlights, light along the foot of the walls, a ring with a little alien on the floor, the name in
## neon over the big screen between two aliens, two more by the way out, pouffes in the far corners, and a driving
## machine with its red seat in the corner by the door. A probe so that the floor shines with all of it.
func _hall_dress(r: Node3D) -> void:
	var y := H - 0.03
	var outer := [Vector2(-(W - 0.7), 0.7), Vector2(W - 0.7, 0.7), Vector2(W - 0.7, D - 0.7), Vector2(-(W - 0.7), D - 0.7)]
	var inner := [Vector2(-(W - 3.6), 3.6), Vector2(W - 3.6, 3.6), Vector2(W - 3.6, D - 3.6), Vector2(-(W - 3.6), D - 3.6)]
	var up := Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0.0, y, 0.0))      # (in the ceiling: x across, the second number is z)
	for i in range(4):
		_tube(outer[i], outer[(i + 1) % 4], 0.0, 0.045, 0xa64dff, 3.0, up)
		_tube(inner[i], inner[(i + 1) % 4], 0.0, 0.045, 0x3f86ff, 3.0, up)
		_tube(outer[i], inner[i], 0.0, 0.035, 0xa64dff, 2.6, up)
	for x in [-(W - 2.1), -2.2, 2.2, W - 2.1]:
		for z in [2.1, 6.2, 10.3, 14.4]:
			_bx(Transform3D(Basis(), Vector3(x, H - 0.006, z)), Vector3(0.16, 0.012, 0.16), 0xfff4e6, 2.2)
	for sx in [-1.0, 1.0]:                                                             # light along the foot of the walls
		_bx(Transform3D(Basis(), Vector3(sx * (W - 0.012), 0.04, D / 2.0)), Vector3(0.02, 0.025, D - 0.2), 0xa64dff, 2.6)
		_bx(Transform3D(Basis(), Vector3(sx * (W + 0.9) / 2.0, 0.04, 0.012)), Vector3(W - 0.9, 0.025, 0.02), 0xa64dff, 2.6)
	_bx(Transform3D(Basis(), Vector3(0.0, 0.04, D - 0.012)), Vector3(W * 2.0, 0.025, 0.02), 0xa64dff, 2.6)
	# the ring on the floor, where the challenge is made
	var flat := Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3(0.0, 0.006, 0.0))   # (on the floor: the second number is -z)
	var mid := Vector2(0.0, -6.2)
	_ellipse(mid, 1.75, 1.75, 0.0, 0.0, 360.0, 0.0, 0.05, 0x9a7ad8, 0.5, flat)
	_ellipse(mid, 1.62, 1.62, 0.0, 0.0, 360.0, 0.0, 0.018, 0x9a7ad8, 0.4, flat)
	var alien := ["...X...X...", "....X.X....", "..XXXXXXX..", ".XX.XXX.XX.", "XXXXXXXXXXX", "X.XXXXXXX.X", "X.X.....X.X", "..XX...XX.."]
	for row in range(alien.size()):
		for col in range(11):
			if alien[row][col] == "X":
				_bx(flat * Transform3D(Basis(), Vector3((5 - col) * 0.09, mid.y - (3.5 - row) * 0.09, 0.0)), Vector3(0.082, 0.082, 0.004), 0x9a7ad8, 0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in range(9):                                                                 # little stars round it
		var a := rng.randf() * TAU
		var q := mid + Vector2(cos(a), sin(a)) * rng.randf_range(0.75, 1.45)
		_tube(q - Vector2(0.05, 0.0), q + Vector2(0.05, 0.0), 0.0, 0.014, 0x9a7ad8, 0.5, flat)
		_tube(q - Vector2(0.0, 0.05), q + Vector2(0.0, 0.05), 0.0, 0.014, 0x9a7ad8, 0.5, flat)
	# the far wall: the name over the big screen, an alien either side of it
	var back := Node3D.new()
	back.transform = Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, 0.0, D - 0.005))  # (facing into the hall: x is across as you look at it)
	r.add_child(back)
	var bxf: Transform3D = back.transform
	_lit_words(back, "GALAXY RECRESS", Vector3(0.0, 4.02, 0.02), 0.34, 6.4, 0xffffff, 0xd2a8ff, 0xa64dff)
	_ellipse(Vector2(0.0, 4.02), 3.6, 0.27, 0.04, 160.0, 380.0, 0.015, 0.03, 0xc04dff, 3.0, bxf)
	for side in [[-2.75, 0x3f86ff], [2.75, 0xc04dff]]:
		_pixel_alien(bxf, Vector2(side[0] * 1.15, 2.75), 0.08, side[1])
	# the near wall: two more by the way out
	var front := Transform3D(Basis(), Vector3(0.0, 0.0, 0.006))
	_pixel_alien(front, Vector2(-2.4, 2.3), 0.06, 0x3df2ff)
	_pixel_alien(front, Vector2(2.4, 2.3), 0.06, 0xc04dff)
	# pouffes in the far corners
	for sx in [-1.0, 1.0]:
		for k in range(2):
			var at := Vector3(sx * (W - 0.8 - k * 0.75), 0.0, D - 0.75)
			_bx(Transform3D(Basis(), at + Vector3(0.0, 0.22, 0.0)), Vector3(0.6, 0.44, 0.6), 0x1c1a24)
			_bx(Transform3D(Basis(), at + Vector3(0.0, 0.015, 0.0)), Vector3(0.62, 0.02, 0.62), 0xa64dff, 1.6)
	# a driving machine in the corner by the door, its red seat in front of it
	var drv := Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(-(W - 0.45), 0.0, 1.45))    # (it faces across the hall)
	_bx(drv * Transform3D(Basis(), Vector3(0.0, 0.85, 0.0)), Vector3(1.1, 1.7, 0.6), 0x141419)
	_bx(drv * Transform3D(Basis(), Vector3(0.0, 1.88, 0.05)), Vector3(1.1, 0.3, 0.5), 0xff3df0, 1.4)
	for sx in [-0.555, 0.555]:
		_bx(drv * Transform3D(Basis(), Vector3(sx, 0.85, 0.3)), Vector3(0.018, 1.7, 0.018), 0x3df2ff, 2.2)
	_bx(drv * Transform3D(Basis(), Vector3(0.0, 0.07, 1.0)), Vector3(0.7, 0.14, 1.4), 0x1c1c22)
	_bx(drv * Transform3D(Basis(), Vector3(0.0, 0.42, 1.25)), Vector3(0.55, 0.14, 0.5), 0xc8202a)
	_bx(drv * Transform3D(Basis(Vector3.RIGHT, -0.3), Vector3(0.0, 0.85, 1.52)), Vector3(0.55, 0.85, 0.14), 0xc8202a)
	_bx(drv * Transform3D(Basis(), Vector3(0.0, 0.25, 1.25)), Vector3(0.3, 0.3, 0.3), 0x1c1c22)
	_bx(drv * Transform3D(Basis(), Vector3(0.0, 0.8, 0.45)), Vector3(0.9, 0.12, 0.35), 0x1a1a1e)
	_ellipse(Vector2(0.0, 1.0), 0.17, 0.17, 0.0, 0.0, 360.0, 0.0, 0.035, 0x1a1a1e, 0.0, drv * Transform3D(Basis(Vector3.RIGHT, -0.5), Vector3(0.0, 0.0, 0.62)))
	_bake(r)
	var dc := Node3D.new()
	dc.transform = drv
	r.add_child(dc)
	var m := _screen(dc, Vector3(0.0, 1.32, 0.31), Vector2(0.9, 0.62), 0.0, 7.7)
	m.set_shader_parameter("on", 1.0)
	_text(dc, "RALLY 9", Vector3(0.0, 1.88, 0.31), 48, 0x111111)
	var probe := ReflectionProbe.new()                                                 # (the floor shines with the neon)
	probe.size = Vector3(W * 2.0, H, D)
	probe.position = Vector3(0.0, H / 2.0, D / 2.0)
	probe.box_projection = true
	probe.interior = true
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.ambient_mode = ReflectionProbe.AMBIENT_COLOR                                # (no daylight in here: a dim violet instead of the sky's)
	probe.ambient_color = Color(0.1, 0.07, 0.16)
	r.add_child(probe)

## a little alien of lit squares on a wall: its middle `c` in the frame `xf`, `pix` metres to a square
func _pixel_alien(xf: Transform3D, c: Vector2, pix: float, hex: int) -> void:
	var alien := ["...X...X...", "....X.X....", "..XXXXXXX..", ".XX.XXX.XX.", "XXXXXXXXXXX", "X.XXXXXXX.X", "X.X.....X.X", "..XX...XX.."]
	for row in range(alien.size()):
		for col in range(11):
			if alien[row][col] == "X":
				_bx(xf * Transform3D(Basis(), Vector3(c.x + (col - 5) * pix, c.y + (3.5 - row) * pix, 0.012)), Vector3(pix * 0.86, pix * 0.86, 0.02), hex, 2.6)

## the floor: big dark tiles, glossy
func _tiles() -> StandardMaterial3D:
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 64
	for y in range(n):
		for x in range(n):
			var grout := x < 2 or y < 2
			var v := rng.randf_range(-0.012, 0.012)
			img.set_pixel(x, y, Color(0.045, 0.042, 0.055) if grout else Color(0.105 + v, 0.1 + v, 0.125 + v))
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / 0.9
	m.roughness = 0.2
	m.metallic = 0.1
	m.disable_ambient_light = true          # (indoors: the sky's light outside does not reach it)
	return m

## the walls: a galaxy painted on them, violet and blue clouds on the dark and the odd star
func _mural() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = MURAL_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("origin", Vector3(INSIDE.x, floor_y, INSIDE.y))
	return m


## a cabinet: body, a sloping screen, the panel with the stick and buttons, the lit marquee on top
func _cabinet(r: Node3D, pos: Vector3, turn: float, k: int, rng: RandomNumberGenerator, final := false) -> void:
	var c := Node3D.new()
	c.position = pos
	c.rotation.y = turn
	r.add_child(c)
	var wide := 1.5 if final else 0.82
	var art: int = [0x2a3fd0, 0xd02a6a, 0x1fa05a, 0x8a2ad0, 0xd08a1a, 0x1a9ad0][k % 6] if not final else 0xc0392b
	var body := _box(c, 0x141419, Vector3(0, 0.95, 0.0), Vector3(wide, 1.9, 0.72))
	for side in [-1.0, 1.0]:                     # the art on its sides, and light down its front edges (no more than looks)
		_box(c, art, Vector3(side * (wide / 2.0 + 0.006), 1.05, -0.02), Vector3(0.012, 1.3, 0.6))
		_neon(c, Vector3(side * (wide / 2.0 + 0.004), 0.95, 0.36), Vector3(0.018, 1.86, 0.018), [0x3df2ff, 0xff3df0, 0xa64dff, 0x3f86ff][(k + (1 if side > 0 else 0)) % 4] if not final else 0xff4040)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(wide, 1.9, 0.72)
	cs.shape = bs
	cs.transform = c.transform * Transform3D(Basis(), Vector3(0, 0.95, 0.0))
	_body.add_child(cs)
	var model: String = "final" if final else ["neon_negra", "estrellas"][(k / 2 + k % 2) % 2]      # (k = 2 x its place along the wall + its wall: the two kinds take turns along each)
	if ResourceLoader.exists(MODELS + model + ".glb"):
		for ch in c.get_children():
			ch.queue_free()                      # (the box machine's body, art and neon: the model has its own)
		_machine(c, model, rng)
		return
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

## a bought-in machine in `c` (MACHINES): the model, the fights on its screen, TOKKEN 9 on its marquee. False if the
## model is not there (the box machine is built instead)
func _machine(c: Node3D, name: String, rng: RandomNumberGenerator) -> bool:
	var path: String = MODELS + name + ".glb"
	if not ResourceLoader.exists(path):
		return false
	var mdl: Node3D = (load(path) as PackedScene).instantiate()
	c.add_child(mdl)
	var m: Dictionary = MACHINES[name]
	var sc: Array = m["screen"]
	var scr := _screen(c, sc[0], sc[1], 0.0, rng.randf() * 30.0)
	scr.set_shader_parameter("on", 1.0)
	(c.get_child(c.get_child_count() - 1) as Node3D).rotation.x = -float(sc[2])
	if m.has("marquee"):
		var mq: Array = m["marquee"]
		if m.has("cover"):                       # (what is written on the model's own marquee goes under a board of ours)
			_box(c, int(m["cover"]), mq[0] + Vector3(0.0, 0.0, 0.006), Vector3(float(mq[1]) + 0.06, 0.15, 0.012)).material_override = _glow(int(m["cover"]), 0.6)
		_lit_words(c, "TOKKEN 9", mq[0] + Vector3(0.0, 0.0, 0.016), 0.07, float(mq[1]), 0x10182a, 0x3df2ff, -1, false)
	return true

## the machines that are only to look at (no box stops you at them; none is where a scene's camera or anybody stands):
## the basketball by the way in on the right, against that wall; the two-gun machine and the air hockey towards the far
## right; the claw machine on the left, past the last of the machines along that wall
func _hall_models(r: Node3D) -> void:
	for it in [["canasta", Vector3(W - 0.63, 0.0, 1.57), 0.0], ["pistolas", Vector3(W - 0.81, 0.0, 13.2), -PI / 2.0],
			["hockey", Vector3(5.6, 0.0, 15.0), 0.0], ["gancho", Vector3(-(W - 0.83), 0.0, 13.0), PI / 2.0]]:
		var path: String = MODELS + String(it[0]) + ".glb"
		if not ResourceLoader.exists(path):
			continue
		var n: Node3D = (load(path) as PackedScene).instantiate()
		n.position = it[1]
		n.rotation.y = it[2]
		r.add_child(n)
		if it[0] == "pistolas":                  # (its two screens)
			for sx in [-0.36, 0.36]:
				var m := _screen(n, Vector3(sx, 1.29, 0.03), Vector2(0.62, 0.4), 0.0, 11.0 + sx * 20.0)
				m.set_shader_parameter("on", 1.0)
				(n.get_child(n.get_child_count() - 1) as Node3D).rotation.x = 0.0

## a screen showing fights (screens[] is every one of them)
func _screen(parent: Node3D, pos: Vector3, size: Vector2, turn: float, offset: float) -> ShaderMaterial:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	var m := ShaderMaterial.new()
	if _screen_shader == null:                   # (one shader for all of them: compiled once)
		_screen_shader = Shader.new()
		_screen_shader.code = SCREEN_SHADER
	m.shader = _screen_shader
	m.set_shader_parameter("fights", load("res://assets/recress/peleas.png"))
	m.set_shader_parameter("rows", float(FIGHT_MS.size()))
	m.set_shader_parameter("ms", PackedFloat32Array(FIGHT_MS))
	m.set_shader_parameter("fight", float(int(offset * 7.0) % FIGHT_MS.size()))
	m.set_shader_parameter("aspect", size.x / size.y)
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
