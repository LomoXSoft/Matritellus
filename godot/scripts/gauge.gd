extends Control
## The dashboard, bottom right. Every kind of vehicle has its own instrument:
##   classic   Seta Panda, Z15, the tow truck: a cream dial in a chrome ring, as fitted to anything sold before 1995
##   tractor   Súper Hebro, Yondir: a big slow dial in the colour of the make; it tops out where the others start
##   sport     Omega Julietta, El Tunero: black face, white figures, a long scale and a red line... and under it the
##             nitro, a tube of fire: it burns down while you use it, burns OUT if you empty it, and fills again as
##             you drive fast
##   digital   Edison Model Y: no needle at all: figures on dark glass, a ring of segments, a battery
##   patrol    Los Pitufos' and Los Tricornios' cars: the classic dial with a blue ring and the lights on top
## game.gd sets value (km/h), hp, nitro, boost and burnt every frame and calls queue_redraw().

const START := deg_to_rad(140.0)      # needle angle at 0 (screen angles: 0 = right, clockwise)
const SWEEP := deg_to_rad(260.0)
const INK := Color("4a3424")

var value := 0.0          # km/h
var top := 140.0
var style := "classic"
var title := ""
var hp := 1.0             # bodywork, 0..1
var nitro := -1.0         # 0..1, or -1 if the car has none
var boost := false        # the nitro is burning right now
var burnt := false        # it burnt out: no use until it has filled a good way again
var key := ""             # the key for this car's trick (nitro, autopilot): shown beside the dial while it can be used
var key_show := false
var key_hot := false      # ...and bouncing when it is at its best (a full bottle)
var auto := 0             # the Edison's autopilot: 0 off, 1 driving to the objective, 2 just driving
var make_col := Color("3f8fd0")
var _fire: ColorRect
var _fire_mat: ShaderMaterial
var _word: Label
var _t := 0.0
const W := 196.0          # the dashboard is drawn on a sheet this wide and BIG times that on screen
const BIG := 1.08

const FIRE := "
shader_type canvas_item;
uniform float fill = 1.0;      // how much nitro there is
uniform float burn = 0.0;      // 1 while it is being used
uniform float burnt = 0.0;     // 1 when it has burnt out and is filling again
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) { float v = 0.0; float a = 0.5; for (int k = 0; k < 4; k++) { v += a * noise(p); p *= 2.03; a *= 0.5; } return v; }
void fragment() {
	float tube_top = 0.74;                           // below this line is the tube, above it the flames
	float x = (UV.x - 0.05) / 0.90;
	float inside = step(0.0, x) * step(x, 1.0);
	float lit = step(x, fill) * inside;
	float tube = step(tube_top, UV.y) * step(UV.y, 0.95) * inside;
	float rim = step(tube_top - 0.035, UV.y) * step(UV.y, 0.985) * step(-0.02, x) * step(x, 1.02);
	float n = fbm(vec2(UV.x * 11.0, UV.y * 5.0 + TIME * (1.4 + burn * 3.2)));
	vec3 fuel = mix(vec3(0.93, 0.26, 0.04), vec3(1.0, 0.86, 0.30), clamp(n * 1.3 + burn * 0.3, 0.0, 1.0));
	vec3 ember = vec3(0.17, 0.15, 0.14) + vec3(1.0, 0.25, 0.0) * smoothstep(0.62, 0.8, n) * (0.6 + 0.4 * sin(TIME * 5.0 + x * 20.0));
	fuel = mix(fuel, ember, burnt);
	vec3 col = mix(vec3(0.09, 0.08, 0.08), fuel, lit);
	col *= 0.82 + 0.3 * smoothstep(0.95, tube_top, UV.y);          // a little roundness to the glass
	float a = max(rim * 0.9, tube);
	col = mix(vec3(0.29, 0.20, 0.14), col, tube);                   // the metal the tube sits in
	// the flames standing on the lit part of the tube: taller the fuller it is, roaring while it burns
	float h = (tube_top - UV.y) / tube_top;                         // 0 at the tube .. 1 at the top
	float tall = mix(0.5, 1.0, burn) * (0.45 + 0.55 * fill) * (1.0 - burnt);
	float f = fbm(vec2(UV.x * 9.0 + sin(TIME * 2.0 + UV.y * 9.0) * 0.25, UV.y * 6.5 + TIME * (2.4 + burn * 3.4)));
	float edge = smoothstep(0.0, 0.07, fill - x) + step(0.999, fill);
	float flame = inside * edge * step(UV.y, tube_top) * smoothstep(0.02, 0.28, f * 1.5 - h / max(tall, 0.04) * 0.8);
	vec3 fc = mix(vec3(0.86, 0.12, 0.02), vec3(1.0, 0.93, 0.5), clamp(f * 1.9 - h * 1.5 / max(tall, 0.2), 0.0, 1.0));
	col = mix(col, fc, flame * (1.0 - a));
	a = max(a, flame * 0.92);
	// burnt out: a thread of smoke instead
	float smoke = burnt * inside * step(UV.y, tube_top) * smoothstep(0.52, 0.75, fbm(vec2(UV.x * 5.0, UV.y * 4.0 + TIME * 0.7))) * (1.0 - h) * 0.45;
	col = mix(col, vec3(0.6), smoke * (1.0 - a));
	a = max(a, smoke);
	COLOR = vec4(col, a);
}
"

func _init() -> void:
	custom_minimum_size = Vector2(W, 232.0) * BIG
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fire = ColorRect.new()
	_fire.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fire.position = Vector2(10, 128) * BIG
	_fire.size = Vector2(176, 100) * BIG
	var sh := Shader.new()
	sh.code = FIRE
	_fire_mat = ShaderMaterial.new()
	_fire_mat.shader = sh
	_fire.material = _fire_mat
	_fire.visible = false
	add_child(_fire)
	_word = Label.new()                          # the lettering on the tube (over the fire)
	_word.add_theme_font_size_override("font_size", 13)
	_word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_word.position = Vector2(10, 203) * BIG
	_word.size = Vector2(176 * BIG, 20)
	_word.visible = false
	add_child(_word)

## fits the dashboard to the car you have just got into
func setup(spec: Dictionary, kind: String) -> void:
	title = String(spec.get("name", ""))
	var fastest: float = float(spec["max"]) * 3.6
	if spec.has("turbo"):
		fastest *= float(spec["turbo"]["max"])
	style = "classic"
	if spec.get("tractor", false) or kind == "yondir" or kind == "tractor":
		style = "tractor"
		make_col = Color("2f8f3a") if kind == "yondir" else Color("3f8fd0")
	elif spec.get("sound", "") == "electric":
		style = "digital"
	elif spec.has("turbo"):
		style = "sport"
	elif kind == "pitufo" or kind == "tricornio":
		style = "patrol"
		make_col = Color("2f6bff") if kind == "pitufo" else Color("2f8f55")
	var step := 10.0 if style == "tractor" else 20.0
	top = ceilf((fastest + (6.0 if style == "tractor" else 18.0)) / step) * step
	nitro = 1.0 if spec.has("turbo") else -1.0
	_fire.visible = nitro >= 0.0
	_word.visible = nitro >= 0.0
	queue_redraw()

func _process(dt: float) -> void:
	_t += dt
	if _fire.visible:
		_fire_mat.set_shader_parameter("fill", clampf(nitro, 0.0, 1.0))
		_fire_mat.set_shader_parameter("burn", 1.0 if boost else 0.0)
		_fire_mat.set_shader_parameter("burnt", 1.0 if burnt else 0.0)
		_word.text = "QUEMAO" if burnt else ("¡NITRO!" if boost else "NITRO")
		var wc := Color(1.0, 0.6, 0.35) if burnt else (Color(1, 1, 0.8) if boost else Color(1, 1, 1, 0.9))
		if burnt and int(_t * 3.0) % 2 == 0:
			wc.a = 0.45
		_word.add_theme_color_override("font_color", wc)
		_word.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.04))
		_word.add_theme_constant_override("outline_size", 5)

func _text(at: Vector2, s: String, px: int, col: Color, centred := true) -> void:
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	draw_string(font, at - Vector2(w / 2.0 if centred else 0.0, 0.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)

## the glass over a dial: a soft light across the top left, a darker foot
func _glass(c: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for k in range(13):
		var a := deg_to_rad(200.0 + k * 9.0)
		pts.append(c + Vector2(cos(a), sin(a)) * (r - 5.0))
	for k in range(12, -1, -1):
		var a2 := deg_to_rad(200.0 + k * 9.0)
		pts.append(c + Vector2(cos(a2), sin(a2)) * (r - 5.0) * 0.72 + Vector2(0, r * 0.1))
	draw_colored_polygon(pts, Color(1, 1, 1, 0.16))

func _needle(c: Vector2, r: float, col: Color, hub: Color) -> void:
	var na := START + SWEEP * clampf(value / top, 0.0, 1.04)
	var nd := Vector2(cos(na), sin(na))
	var side := Vector2(-nd.y, nd.x)
	draw_colored_polygon(PackedVector2Array([c + nd * (r - 12.0) + Vector2(1.5, 2.5), c + side * 4.5 - nd * 14.0 + Vector2(1.5, 2.5), c - side * 4.5 - nd * 14.0 + Vector2(1.5, 2.5)]), Color(0, 0, 0, 0.28))
	draw_colored_polygon(PackedVector2Array([c + nd * (r - 12.0), c + side * 4.0 - nd * 14.0, c - side * 4.0 - nd * 14.0]), col)
	draw_circle(c, 8.0, hub)
	draw_circle(c - Vector2(2, 2), 2.6, Color(1, 1, 1, 0.5))

func _ticks(c: Vector2, r: float, col: Color, every: float, numbers: float, px: int) -> void:
	var minor := every / 2.0
	var i := 0.0
	while i <= top + 0.01:
		var a := START + SWEEP * (i / top)
		var d := Vector2(cos(a), sin(a))
		var major := is_zero_approx(fmod(i, every))
		draw_line(c + d * (r - (14.0 if major else 8.0)), c + d * (r - 3.0), col, 2.6 if major else 1.3, true)
		if major and is_zero_approx(fmod(i, numbers)):
			_text(c + d * (r - 27.0) + Vector2(0, 5), str(int(i)), px, col)
		i += minor

## the bodywork, as an arc in the gap at the foot of the dial
func _chapa(c: Vector2, r: float, back: Color) -> void:
	var a0 := deg_to_rad(128.0)
	var a1 := deg_to_rad(52.0)
	draw_arc(c, r, a1, a0, 14, back, 7.0, true)
	var col := Color("5aa84f") if hp > 0.5 else (Color("e8a23a") if hp > 0.25 else Color("e23b3b"))
	if hp > 0.01:
		draw_arc(c, r, a0 - (a0 - a1) * clampf(hp, 0.0, 1.0), a0, 14, col, 5.0, true)

func _plate(text_col: Color, back: Color, rim: Color) -> void:
	var w := maxf(96.0, ThemeDB.fallback_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 22.0)
	var box := Rect2(W / 2.0 - w / 2.0, 2.0, w, 21.0)
	draw_rect(Rect2(box.position + Vector2(1.5, 2.5), box.size), Color(0, 0, 0, 0.25))
	draw_rect(box, back)
	draw_rect(box, rim, false, 2.0)
	for sx in [box.position.x + 6.0, box.end.x - 6.0]:          # two rivets
		draw_circle(Vector2(sx, box.position.y + 10.5), 1.8, rim)
	_text(Vector2(W / 2.0, 17.5), title, 13, text_col)

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(BIG, BIG))
	var c := Vector2(W / 2.0, 104.0)
	var r := 74.0
	if key_show and key != "":
		_keycap(Vector2(4.0, 213.0 if nitro >= 0.0 else 166.0))
	match style:
		"digital":
			_draw_digital(c, r)
		"sport":
			_draw_sport(c, r)
		"tractor":
			_draw_tractor(c, r)
		_:
			_draw_classic(c, r, style == "patrol")

## the key to press, as a key: sticking out to the left of the dashboard, its right edge at `at`
func _keycap(at: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var tw := font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var w := maxf(34.0, tw + 20.0)
	var bob := absf(sin(_t * 5.0)) * (5.0 if key_hot else 1.5)
	var box := Rect2(at.x - w, at.y - 15.0 - bob, w, 28.0)
	var cap := StyleBoxFlat.new()
	cap.bg_color = Color("f6efe0") if key_hot else Color("d9d2c2")
	cap.set_corner_radius_all(7)
	cap.border_color = Color("4a3424")
	cap.set_border_width_all(2)
	cap.border_width_bottom = 6                    # the side of the key: it stands up off the board
	cap.shadow_color = Color(0, 0, 0, 0.3)
	cap.shadow_size = 3
	cap.shadow_offset = Vector2(1, 3 + bob * 0.6)
	draw_style_box(cap, box)
	_text(Vector2(box.position.x + w / 2.0, box.position.y + 18.0), key, 14, Color("4a3424"))
	if key_hot:                                    # a glint running across it
		var gx := box.position.x + fposmod(_t * 60.0, w + 30.0) - 15.0
		if gx > box.position.x + 3.0 and gx < box.end.x - 6.0:
			draw_line(Vector2(gx, box.position.y + 4.0), Vector2(gx - 5.0, box.position.y + 20.0), Color(1, 1, 1, 0.7), 3.0, true)

func _draw_classic(c: Vector2, r: float, patrol: bool) -> void:
	_plate(Color("fff6e0"), INK, Color("c9a66b"))
	draw_circle(c + Vector2(2, 5), r + 6.0, Color(0, 0, 0, 0.28))                # its shadow on the dashboard
	draw_circle(c, r + 6.0, make_col.darkened(0.25) if patrol else Color("7d8088"))     # the ring: chrome, or the force's colour
	draw_arc(c, r + 4.5, deg_to_rad(190.0), deg_to_rad(330.0), 24, Color(1, 1, 1, 0.55), 2.0, true)
	draw_circle(c, r + 1.5, INK)
	draw_circle(c, r, Color("fff6e0"))
	draw_circle(c, r * 0.62, Color("f6ead0"))
	draw_arc(c, r - 7.0, START + SWEEP * 0.8, START + SWEEP, 16, Color("e23b3b"), 6.0, true)
	_ticks(c, r, INK, 20.0, 40.0, 13)
	_chapa(c, r - 9.0, Color(0.29, 0.2, 0.14, 0.25))
	# the little window with the figure in it, like a mileometer
	var win := Rect2(c.x - 24.0, c.y + 22.0, 48.0, 22.0)
	draw_rect(win, Color("26221e"))
	draw_rect(win, Color("8a8f96"), false, 1.5)
	_text(Vector2(c.x, win.position.y + 17.0), "%03d" % int(round(value)), 16, Color("fff6e0"))
	_text(Vector2(c.x, c.y - 22.0), "km/h", 11, Color(0.29, 0.2, 0.14, 0.7))
	_needle(c, r, Color("d9643a"), INK)
	_glass(c, r)
	if patrol:                                    # the lights, on top of the ring
		var on := int(_t * 4.0) % 2 == 0
		draw_circle(c + Vector2(-20, -r - 4.0), 6.0, Color("2f6bff") if on else Color("16306e"))
		draw_circle(c + Vector2(20, -r - 4.0), 6.0, Color("16306e") if on else Color("2f6bff"))

func _draw_tractor(c: Vector2, r: float) -> void:
	_plate(Color("fff6e0"), make_col.darkened(0.35), Color("f2c230"))
	draw_circle(c + Vector2(2, 5), r + 7.0, Color(0, 0, 0, 0.28))
	draw_circle(c, r + 7.0, make_col.darkened(0.2))                 # a fat ring in the colour of the make
	draw_circle(c, r + 2.0, Color("f2c230") if make_col.g > make_col.b else Color("dfe6ee"))
	draw_circle(c, r, Color("f7efd8"))
	# three bands: the field, the road, and "not in this"
	draw_arc(c, r - 8.0, START, START + SWEEP * 0.45, 20, Color("5aa84f"), 7.0, true)
	draw_arc(c, r - 8.0, START + SWEEP * 0.45, START + SWEEP * 0.8, 20, Color("e8a23a"), 7.0, true)
	draw_arc(c, r - 8.0, START + SWEEP * 0.8, START + SWEEP, 12, Color("e23b3b"), 7.0, true)
	_ticks(c, r - 13.0, INK, 10.0, 20.0, 14)
	_chapa(c, r - 9.0, Color(0.29, 0.2, 0.14, 0.25))
	_text(Vector2(c.x, c.y + 42.0), "%d" % int(round(value)), 24, INK)
	_text(Vector2(c.x, c.y + 54.0), "km/h", 10, Color(0.29, 0.2, 0.14, 0.7))
	_needle(c, r - 6.0, Color("26221e"), make_col.darkened(0.3))
	_glass(c, r)

func _draw_sport(c: Vector2, r: float) -> void:
	_plate(Color("f2efe6"), Color("17171a"), Color("e23b3b"))
	draw_circle(c + Vector2(2, 5), r + 6.0, Color(0, 0, 0, 0.35))
	draw_circle(c, r + 6.0, Color("3a3d42"))
	draw_arc(c, r + 4.5, deg_to_rad(190.0), deg_to_rad(330.0), 24, Color(1, 1, 1, 0.4), 2.0, true)
	draw_circle(c, r + 1.5, Color("0e0e10"))
	draw_circle(c, r, Color(0.09, 0.09, 0.1, 0.94))
	for k in range(5):                            # machined rings on the face
		draw_arc(c, r * (0.25 + k * 0.14), 0.0, TAU, 40, Color(1, 1, 1, 0.035), 1.0, true)
	draw_arc(c, r - 7.0, START + SWEEP * 0.72, START + SWEEP, 20, Color("e23b3b"), 7.0, true)
	if boost:                                     # the whole scale glows while the nitro burns
		draw_arc(c, r - 7.0, START, START + SWEEP * clampf(value / top, 0.0, 1.0), 40, Color(1.0, 0.62, 0.1, 0.5 + 0.3 * sin(_t * 22.0)), 4.0, true)
	_ticks(c, r, Color("f2efe6"), 20.0, 40.0, 13)
	_chapa(c, r - 9.0, Color(1, 1, 1, 0.12))
	_text(Vector2(c.x, c.y + 42.0), "%d" % int(round(value)), 26, Color("f2efe6"))
	_text(Vector2(c.x, c.y - 22.0), "km/h", 11, Color(1, 1, 1, 0.55))
	_needle(c, r, Color("ff3b2f"), Color("c9ced4"))
	_glass(c, r)

func _auto_glow() -> StyleBoxFlat:
	var g := StyleBoxFlat.new()
	g.bg_color = Color(0, 0, 0, 0)
	g.set_corner_radius_all(22)
	g.border_color = Color(0.4, 1.0, 0.6, 0.5 + 0.3 * sin(_t * 6.0))
	g.set_border_width_all(3)
	return g

func _draw_digital(c: Vector2, r: float) -> void:
	_plate(Color("9fe8ff"), Color("0c1218"), Color("3bb7c4"))
	var box := Rect2(c.x - 86.0, c.y - 70.0, 172.0, 150.0)
	var glass := StyleBoxFlat.new()
	glass.bg_color = Color(0.04, 0.07, 0.1, 0.86)
	glass.set_corner_radius_all(22)
	glass.border_color = Color(0.23, 0.72, 0.77, 0.9)
	glass.set_border_width_all(2)
	glass.shadow_color = Color(0, 0, 0, 0.35)
	glass.shadow_size = 6
	glass.shadow_offset = Vector2(2, 5)
	draw_style_box(glass, box)
	# a ring of segments that light up with the speed
	var segs := 28
	var lit := int(round(segs * clampf(value / top, 0.0, 1.0)))
	for k in range(segs):
		var a := START + SWEEP * ((k + 0.5) / segs)
		var d := Vector2(cos(a), sin(a))
		var on := k < lit
		var col := Color(0.25, 0.9, 1.0) if on else Color(0.2, 0.3, 0.36, 0.7)
		if on and k >= segs * 0.82:
			col = Color(1.0, 0.45, 0.35)
		draw_line(c + d * (r - 20.0), c + d * (r - 8.0), col, 4.0, true)
		if on:
			draw_line(c + d * (r - 21.0), c + d * (r - 7.0), Color(col.r, col.g, col.b, 0.25), 8.0, true)
	_text(Vector2(c.x, c.y + 12.0), "%d" % int(round(value)), 46, Color(0.85, 0.98, 1.0))
	_text(Vector2(c.x, c.y + 30.0), "km/h", 12, Color(0.45, 0.8, 0.88))
	# the battery (it is the bodywork, really: an Edison takes a knock like a phone takes a fall)
	var bat := Rect2(c.x - 34.0, c.y + 42.0, 68.0, 16.0)
	draw_rect(bat, Color(0.45, 0.8, 0.88), false, 1.5)
	draw_rect(Rect2(bat.end.x, bat.position.y + 4.0, 3.0, 8.0), Color(0.45, 0.8, 0.88))
	var cells := 5
	for k in range(cells):
		if hp > float(k) / cells + 0.01:
			var cc := Color(0.3, 0.95, 0.6) if hp > 0.5 else (Color("e8a23a") if hp > 0.25 else Color("e23b3b"))
			draw_rect(Rect2(bat.position.x + 3.0 + k * 12.6, bat.position.y + 3.0, 10.6, 10.0), cc)
	if auto == 0:
		_text(Vector2(c.x, c.y - 44.0), "AUTOPILOTO: NO", 9, Color(0.45, 0.8, 0.88, 0.8))
	else:                                          # a little steering wheel turning by itself, and the word
		var glow := Color(0.4, 1.0, 0.6, 0.65 + 0.35 * sin(_t * 6.0))
		_text(Vector2(c.x + 7.0, c.y - 44.0), "AUTOPILOTO: SÍ" if auto == 1 else "AUTOPILOTO: DE PASEO", 9, glow)
		var wc := Vector2(c.x - (48.0 if auto == 1 else 66.0), c.y - 47.0)
		draw_arc(wc, 5.0, 0.0, TAU, 14, glow, 1.5, true)
		for k in range(3):
			var wa := _t * 2.5 + k * TAU / 3.0
			draw_line(wc, wc + Vector2(cos(wa), sin(wa)) * 5.0, glow, 1.2, true)
		draw_style_box(_auto_glow(), Rect2(c.x - 86.0, c.y - 70.0, 172.0, 150.0))
	var scan := fposmod(_t * 0.35, 1.0)                 # a line of light going down the glass
	draw_rect(Rect2(box.position.x + 4.0, box.position.y + 8.0 + scan * (box.size.y - 16.0), box.size.x - 8.0, 2.0), Color(0.6, 0.95, 1.0, 0.07))
