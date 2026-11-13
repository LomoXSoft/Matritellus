extends Node
## Food, and what it does to you (the user's rules, 13 November 2026; guion/kebab_luis_diseno.md).
##
## You can eat. Eat more than three times in the same day of the game -- the fourth meal -- and you go up to the next
## girth (Anchuras in the character creator: 0.86, 1.0, 1.2). Do that when you are already the widest there is and you
## "faint": the screen swims like a drunk's, you cannot walk straight, every ten seconds of walking you go head over
## heels, and after fifty seconds it all goes black and you come to at the health centre (at its main door: game.gd,
## faint_spot. Until the centre was built, the user's choice was the pavement in front of your own house).
##
## Where you eat: for now, by asking Don Luis or Henry (game.gd, _food_offer), at PRICE euros -- a provisional price.

const Creator = preload("res://scripts/creator.gd")
const PRICE := 5
const FAINT_FOR := 50.0
const TRIP_EVERY := 10.0        # seconds of walking between one tumble and the next
const TUMBLE := 0.85            # seconds in the air, turning over
const LYING := 1.5              # seconds flat on the ground after it
const RISE := 0.35
const BUILD := 16               # which of the creator's options the girth is
const WIDTHS := [1, 0, 2]       # that option's values from thin to stout (0.86, 1.0, 1.2), as indices

const DRUNK := "
shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform float amount = 0.0;
void fragment() {
	vec2 uv = SCREEN_UV;
	float t = TIME;
	vec2 sway = vec2(sin(t * 1.3 + uv.y * 5.0), cos(t * 1.1 + uv.x * 4.0)) * 0.014 * amount;
	vec2 split = vec2(cos(t * 0.7), sin(t * 0.9)) * 0.02 * amount * (0.6 + 0.4 * sin(t * 0.45));
	vec3 a = texture(screen, uv + sway + split).rgb;
	vec3 b = texture(screen, uv + sway - split).rgb;
	vec3 c = mix(a, b, 0.5);
	c = mix(c, textureLod(screen, uv + sway, 3.0).rgb, 0.4 * amount);
	float r = length(uv - 0.5);
	c *= 1.0 - smoothstep(0.3, 0.8, r) * 0.6 * amount;
	c = mix(c, c * vec3(1.06, 1.0, 0.82), 0.6 * amount);
	COLOR = vec4(c, 1.0);
}
"

var G
var meals := 0                  # today's
var day := -1                   # the day they were eaten on
var faint = null                # {t: seconds since it began, walked: seconds walking since the last tumble, fall: seconds into a tumble or -1, dir}
var blackout := false           # the screen is going dark, or coming back
var trips := 0
var amount := 0.0               # how much the screen swims, 0..1
var _veer := 0.0
var _rect: ColorRect
var _mat: ShaderMaterial

func setup(game) -> void:
	G = game
	var layer := CanvasLayer.new()
	layer.layer = 0                              # over the town, under everything written on the screen
	add_child(layer)
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = DRUNK
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	_rect.material = _mat
	_rect.visible = false
	layer.add_child(_rect)

func reset() -> void:
	meals = 0
	day = -1
	_clear()

func _clear() -> void:
	faint = null
	blackout = false
	amount = 0.0
	_rect.visible = false
	if G != null and G.player != null and G.player.inner != null:
		G.player.inner.rotation.x = 0.0

## how many times you have eaten today
func today() -> int:
	if day != int(G.day_n):
		day = int(G.day_n)
		meals = 0
	return meals

## how wide you are: 0 thin, 1 as most people, 2 stout
func width() -> int:
	return WIDTHS.find(int(G.look_sel[BUILD]))

## You eat something. Returns what came of it: "" (nothing), "three" (one more today and it shows), "wider", "faint".
func eat() -> String:
	meals = today() + 1
	Sfx.noise(0.07, -16.0)
	for k in range(1, 4):
		get_tree().create_timer(k * 0.22).timeout.connect(Sfx.noise.bind(0.06, -17.0))
	if meals == 3:
		G.hud.toast(Loc.t("t_eat_3"), 4.5)
		return "three"
	if meals != 4:
		G.hud.toast(Loc.t("t_eat").pick_random(), 2.4)
		return ""
	if width() >= WIDTHS.size() - 1:
		_faint_begin()
		return "faint"
	G.look_sel[BUILD] = WIDTHS[width() + 1]
	G._apply_look()
	G.hud.toast(Loc.t("t_fatter"), 5.0)
	Sfx.jingle([392, 330, 262], 0.14)
	return "wider"

func _faint_begin() -> void:
	faint = {"t": 0.0, "walked": 0.0, "fall": -1.0, "dir": Vector2.ZERO}
	_rect.visible = true
	G.hud.toast(Loc.t("t_faint"), 5.0)
	Sfx.beep(300.0, 1.2, 3, -12.0, -180.0)

## on the ground, or on the way there: your legs are not yours
func down() -> bool:
	return faint != null and float(faint["fall"]) >= 0.0

## Which way you really go when you mean to go `mv` (a unit vector, or zero), and how fast: it wanders off to one
## side and the other, and while you are falling it is the fall that carries you.
func stagger(mv: Vector2, speed: float, dt: float) -> Array:
	if faint == null:
		return [mv, speed]
	if down():
		var f: float = faint["fall"]
		return [faint["dir"], 4.5 * maxf(0.0, 1.0 - f / TUMBLE)]
	if mv == Vector2.ZERO:
		return [mv, 0.0]
	_veer += dt
	var off := sin(_veer * 1.9) * 0.55 + sin(_veer * 0.83 + 1.0) * 0.4
	var pace := minf(speed, 5.2) * (0.62 + 0.3 * sin(_veer * 2.7))
	faint["walked"] += dt
	if faint["walked"] >= TRIP_EVERY:
		faint["walked"] = 0.0
		faint["fall"] = 0.0
		faint["dir"] = mv.rotated(off)
		trips += 1
		Sfx.noise(0.2, -10.0)
		Sfx.beep(420.0, 0.3, 2, -12.0, -300.0)
		G.hud.toast(Loc.t("t_trip").pick_random(), 2.0)
		G.shake = 0.3
	return [mv.rotated(off), pace]

## the tumble itself, laid over whatever the legs were doing (call after the player's anim)
func pose(pl) -> void:
	if faint == null or float(faint["fall"]) < 0.0:
		return
	var f: float = faint["fall"]
	if f < TUMBLE:                               # head over heels, and down on your face
		var k := f / TUMBLE
		pl.inner.rotation.x = k * (TAU + PI / 2.0)
		pl.inner.position.y = 0.35 + sin(k * PI) * 1.1
	elif f < TUMBLE + LYING:
		pl.inner.rotation.x = PI / 2.0
		pl.inner.position.y = 0.35
	else:
		var k2 := clampf((f - TUMBLE - LYING) / RISE, 0.0, 1.0)
		pl.inner.rotation.x = (1.0 - k2) * PI / 2.0
		pl.inner.position.y = 0.35 * (1.0 - k2)

## the camera rolls with your head
func tilt(cam: Camera3D) -> void:
	if amount > 0.01:
		cam.rotate_object_local(Vector3(0, 0, 1), (sin(_veer * 0.9 + G.time * 0.8) * 0.07 + sin(G.time * 1.9) * 0.03) * amount)

func tick(dt: float) -> void:
	if faint == null:
		return
	if not blackout:
		faint["t"] += dt
		amount = minf(1.0, amount + dt / 2.5)
	_mat.set_shader_parameter("amount", amount)
	if float(faint["fall"]) >= 0.0:
		faint["fall"] += dt
		if faint["fall"] >= TUMBLE + LYING + RISE:
			faint["fall"] = -1.0
			G.player.inner.rotation.x = 0.0
	if faint["t"] >= FAINT_FOR and not blackout:     # out like a light
		blackout = true
		Sfx.beep(180.0, 1.4, 3, -12.0, -120.0)
		var tw := create_tween()
		tw.tween_property(G.hud.fade, "modulate:a", 1.0, 1.4)
		tw.tween_interval(0.8)
		tw.tween_callback(_come_to)

## ...and you come to where they have left you
func _come_to() -> void:
	_clear()
	G.faint_wake()
	create_tween().tween_property(G.hud.fade, "modulate:a", 0.0, 1.6)
