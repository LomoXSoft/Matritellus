extends CanvasLayer
## Screen filters (the user, 23 Nov 2026: "Proponme filtros para el juego. CRT o tipo falso PSX"; shown three, then
## "El primero sin temblor", and later the same day "Déjame los tres filtros disponibles en las opciones gráficas. Así
## los pruebo yo en la próxima versión"). Settings.data["filtro"]:
##   0  none;
##   1  "Consola de los 90": the 3D drawn small (LINES rows, game.apply_graphics) and blown up in square blocks, with
##      fewer colours and a 4x4 dither, as the consoles of the nineties did. No wobbling vertices ("sin temblor");
##   2  "Tele vieja": scanlines, a curved glass with dark corners, the colours split a little at the edges, the
##      phosphor's stripes and a slight glow;
##   3  both: the console seen on the old television.
##
## The HUD too, but not its words (the user, the same day: "Se puede hacer que también afecten al HUD pero no a los
## textos?"). While you play, two passes:
##   - under the HUD (this layer, 0): the 3D, bent by the glass, with the glow and the split colours;
##   - over the HUD's pictures (a rect in the HUD's own root, z OVER_Z): blocks, dither, scanlines, stripes and dark
##     corners on everything drawn so far, the map, the icons, the boxes;
##   - the words (Label, RichTextLabel, Button, LineEdit, the car radio's display) lifted above both (z WORDS_Z), so
##     they stay sharp. The HUD is not bent: sharp words cannot bend with their boxes.
## In the menus, the map, the backpack (and whenever the playing HUD is hidden) the filter goes back under the HUD
## alone, and the words to where they were, so nothing of the HUD shows through those screens.

const HudBits = preload("res://scripts/hud_bits.gd")
const LINES := 270.0           # the console's rows (480 x 270 on a 16:9 screen)
const LEVELS := 24.0           # shades a channel (the consoles had 32, with the dither: a little fewer shows it)
const OVER_Z := 2000
const WORDS_Z := 3000

const CODE := """
shader_type canvas_item;
uniform sampler2D screen: hint_screen_texture, filter_linear, repeat_disable;
uniform float lines = 0.0;     // > 0: the console's rows
uniform float levels = 24.0;
uniform float bent = 0.0;      // 1: the television's curved glass
uniform float glow = 0.0;      // 1: the television's glow and split colours
uniform float scan = 0.0;      // 1: the television's scanlines, stripes and dark corners

const float BAYER[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

vec2 bend(vec2 uv) {
	vec2 c = uv * 2.0 - 1.0;
	vec2 off = abs(c.yx) / vec2(7.0, 5.5);
	c = c + c * off * off;
	return c * 0.5 + 0.5;
}

void fragment() {
	vec2 size = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 uv = bent > 0.5 ? bend(SCREEN_UV) : SCREEN_UV;
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);                    // (past the curved glass)
	} else {
		vec2 grid = lines > 0.0 ? vec2(floor(lines * size.x / size.y), lines) : size;
		vec2 cell = floor(uv * grid);
		vec2 suv = lines > 0.0 ? (cell + 0.5) / grid : uv;
		vec3 c;
		if (glow > 0.5) {
			vec2 split = (uv - 0.5) * 0.006;                     // the colours apart, more at the edges
			c.r = texture(screen, suv + split).r;
			c.g = texture(screen, suv).g;
			c.b = texture(screen, suv - split).b;
			vec2 px = 2.0 / size;                                // the glow: what is bright bleeds a little
			vec3 near = (texture(screen, suv + vec2(px.x, 0.0)).rgb + texture(screen, suv - vec2(px.x, 0.0)).rgb
				+ texture(screen, suv + vec2(0.0, px.y)).rgb + texture(screen, suv - vec2(0.0, px.y)).rgb) * 0.25;
			c += max(near - 0.55, vec3(0.0)) * 0.6;
		} else {
			c = texture(screen, suv).rgb;                        // (one colour a block, with the console)
		}
		if (lines > 0.0) {                                       // fewer shades, dithered in the blocks (twice over is the same)
			int bx = int(mod(cell.x, 4.0));
			int by = int(mod(cell.y, 4.0));
			float d = BAYER[by * 4 + bx] / 16.0 - 0.5;
			c = floor(clamp(c, 0.0, 1.0) * (levels - 1.0) + 0.5 + d) / (levels - 1.0);
		}
		if (scan > 0.5) {
			float rows = lines > 0.0 ? lines : size.y / 3.0;
			float f = fract(uv.y * rows) - 0.5;
			c *= 1.0 - 0.38 * pow(abs(f) * 2.0, 2.0);            // the scanlines
			float m = mod(FRAGCOORD.x, 3.0);                     // the phosphor's stripes
			vec3 mask = m < 1.0 ? vec3(1.0, 0.82, 0.82) : (m < 2.0 ? vec3(0.82, 1.0, 0.82) : vec3(0.82, 0.82, 1.0));
			c *= mix(vec3(1.0), mask, 0.55);
			c *= pow(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 0.22);      // the dark corners
			c *= 1.22;                                           // (what the lines and stripes took away)
		}
		COLOR = vec4(c, 1.0);
	}
}
"""

var G                          # the game
var mode := 0
var over_on := false           # the HUD's pictures under the filter now (its words lifted)
var _rect: ColorRect           # under the HUD
var _mat: ShaderMaterial
var _over: ColorRect           # over the HUD's pictures, in its root
var _omat: ShaderMaterial
var _lifted: Array = []        # the words lifted, to put back

func _ready() -> void:
	layer = 0
	var sh := Shader.new()
	sh.code = CODE
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	_rect.material = _mat
	add_child(_rect)
	_over = ColorRect.new()
	_over.set_anchors_preset(Control.PRESET_FULL_RECT)
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over.z_as_relative = false
	_over.z_index = OVER_Z
	_over.visible = false
	_omat = ShaderMaterial.new()
	_omat.shader = sh
	_over.material = _omat
	_hook()
	set_mode(mode)
	get_window().size_changed.connect(_resized)
	get_tree().node_added.connect(_added)

## does this mode draw the 3D small?
static func small(m: int) -> bool:
	return m == 1 or m == 3

func set_mode(m: int) -> void:
	mode = clampi(m, 0, 3)
	if _rect == null:
		return
	_rect.visible = mode != 0
	_params()

## the two passes' settings, for the mode and whether the HUD is under the filter
func _params() -> void:
	var crt := 1.0 if mode >= 2 else 0.0
	var ln := LINES if small(mode) else 0.0
	for m in [_mat, _omat]:
		m.set_shader_parameter("lines", ln)
		m.set_shader_parameter("levels", LEVELS)
	_mat.set_shader_parameter("bent", crt)
	_mat.set_shader_parameter("glow", crt)
	_mat.set_shader_parameter("scan", 0.0 if over_on else crt)       # (with the HUD in, the lines go over it, on the top pass)
	_omat.set_shader_parameter("bent", 0.0)
	_omat.set_shader_parameter("glow", 0.0)
	_omat.set_shader_parameter("scan", crt)

## while you play, with the playing HUD up and no screen over it
func _wants_over() -> bool:
	if mode == 0 or G == null or G.get("hud") == null:
		return false
	var hud = G.hud
	if not hud.play_ui.visible or not hud.root.visible:
		return false
	if G.get("menu") != null and G.menu.visible:
		return false
	if hud.get("bigmap") != null and hud.bigmap.visible:
		return false
	if G.get("inventario") != null and bool(G.inventario.open):
		return false
	return true

## the top pass into the HUD's root, once there is one
func _hook() -> void:
	if _over.get_parent() == null and G != null and G.get("hud") != null and G.hud.root != null:
		G.hud.root.add_child(_over)

func _process(_dt: float) -> void:
	_hook()
	var want := _wants_over() and _over.get_parent() != null
	if want != over_on:
		over_on = want
		_over.visible = want
		_params()
		if want:
			_lift_all(G.hud.root)
		else:
			_drop_all()

static func is_words(n: Node) -> bool:
	return n is Label or n is RichTextLabel or n is Button or n is LineEdit or n is HudBits.CarRadio

func _lift(n: CanvasItem) -> void:
	if n.has_meta("_fz"):
		return
	n.set_meta("_fz", [n.z_index, n.z_as_relative])
	n.z_as_relative = false
	n.z_index = WORDS_Z
	_lifted.append(n)

func _lift_all(root: Node) -> void:
	for n in root.find_children("*", "", true, false):
		if is_words(n) and n != _over:
			_lift(n)

func _drop_all() -> void:
	for n in _lifted:
		if is_instance_valid(n) and n.has_meta("_fz"):
			var was: Array = n.get_meta("_fz")
			n.z_index = int(was[0])
			n.z_as_relative = bool(was[1])
			n.remove_meta("_fz")
	_lifted.clear()

## words added to the HUD while it is under the filter (a toast, a line of talk) are lifted as they come
func _added(n: Node) -> void:
	if over_on and is_words(n) and G != null and G.hud.root.is_ancestor_of(n):
		_lift(n)

## the window made bigger or smaller: the console keeps its rows
func _resized() -> void:
	if small(mode):
		get_viewport().scaling_3d_scale = clampf(LINES / maxf(1.0, float(get_window().size.y)), 0.25, 1.0)
