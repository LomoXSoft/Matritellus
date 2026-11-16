extends Control
## The Padrón Municipal (the user, 16 November 2026): once the character is made and before the game begins, the town
## registers you on its roll of inhabitants -- a sheet from the town hall, no street named on it -- and that is where
## you write your name. For now it goes on the house where you sleep ("Casa de ..." on a tile over its door), and as
## people get to know you they stop calling you "hijo", "hermosa" or "el de la Eufrasia" and use your name: a neighbour
## with a name of their own from 50 of trust, the rest of the town once half of the story's missions are done.
##
## While the sheet is up the game is still in its "creator" phase (the camera, the touch screen and the music go on as
## in the creator); `active` says the sheet has the keys. Saved in stats.nombre.

const Casas = preload("res://scripts/casas.gd")
const HOME_HOUSE := "alemania_5"           # the house you inherit (game.gd HOME_DOOR is before its door)
const MAX_LEN := 16
const KNOWN := 50                       # trust from which a neighbour with a name calls you by yours
const TOWN_SHARE := 0.5                 # share of the story's missions done from which everybody else does
const INK := Color(0.07, 0.07, 0.08)
const RED_INK := Color(0.78, 0.1, 0.12)
const TILE_BLUE := Color(0.12, 0.25, 0.58)
## the words people use to call you while they do not know your name (resolved for you already: "hija", not "{hijo|hija}")
const CALLS := ["hijo", "hija", "hermoso", "hermosa", "majo", "maja", "galán", "reina", "bonico", "bonica", "guapo", "guapa",
	"niño", "niña", "chiquillo", "chiquilla", "socio", "socia", "amigo", "amiga", "vecino", "vecina", "forastero", "forastera"]
const LETTERS := ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "Ñ", "O", "P", "Q", "R", "S",
	"T", "U", "V", "W", "X", "Y", "Z", "Á", "É", "Í", "Ó", "Ú", "Ü", "-", "'"]

var G
var active := false
var signed := false
var _then: Callable
var _name: LineEdit
var _warn: Label
var _keys: Control
var _sign_btn: Button
var _signature                  # yours (a Firma)
var _mayor                      # the mayor's, there from the start
var _stamp: Label
var _stamp_hold: Control
var _plaque: Node3D
var _calls_rx := RegEx.new()

func setup(game) -> void:
	G = game
	_calls_rx.compile("(?i)(^|[¡¿]|, )(" + "|".join(CALLS) + ")(?=[,!?.…;:]|$)")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

func player_name() -> String:
	return String(G.stats.get("nombre", ""))

# ---------------- the sheet ----------------
## up it comes, empty; `then` runs once it is signed and stamped
func open(then: Callable) -> void:
	_then = then
	active = true
	if not is_inside_tree():
		G.hud.root.add_child(self)
	move_to_front()
	signed = false
	for c in get_children():
		c.queue_free()
	_build()
	visible = true
	refresh()
	if not Controls.pad:
		_name.grab_focus()

func _box(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	return sb

func _text(t: String, size: int, col := INK, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = align
	return l

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	center.add_child(col)
	var sheet := PanelContainer.new()
	var sb := _box(Color.WHITE, Color.BLACK, 4, 6)
	sb.content_margin_left = 40; sb.content_margin_right = 40; sb.content_margin_top = 26; sb.content_margin_bottom = 26
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 12
	sheet.add_theme_stylebox_override("panel", sb)
	sheet.custom_minimum_size = Vector2(780, 0)
	col.add_child(sheet)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	sheet.add_child(v)
	v.add_child(_text(Loc.t("pad_town"), 18, INK, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(_text(Loc.t("pad_title"), 34, INK, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(_text(Loc.t("pad_sheet"), 18, INK, HORIZONTAL_ALIGNMENT_CENTER))
	var rule := ColorRect.new()
	rule.color = Color.BLACK
	rule.custom_minimum_size = Vector2(0, 3)
	v.add_child(rule)
	# the name: the one thing to fill in
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var lab := _text(Loc.t("pad_name"), 26)
	lab.custom_minimum_size = Vector2(230, 0)
	row.add_child(lab)
	_name = LineEdit.new()
	_name.max_length = MAX_LEN
	_name.placeholder_text = Loc.t("pad_name_hint")
	_name.custom_minimum_size = Vector2(420, 52)
	_name.add_theme_font_size_override("font_size", 28)
	_name.add_theme_color_override("font_color", INK)
	_name.add_theme_color_override("font_placeholder_color", Color(0.55, 0.55, 0.55))
	_name.add_theme_color_override("caret_color", INK)
	var field := _box(Color.WHITE, Color.BLACK, 0, 0)
	field.border_width_bottom = 3
	field.content_margin_left = 6
	_name.add_theme_stylebox_override("normal", field)
	_name.add_theme_stylebox_override("focus", field)
	_name.add_theme_stylebox_override("read_only", field)
	_name.add_theme_color_override("font_uneditable_color", INK)
	_name.text_changed.connect(_on_typed)
	_name.text_submitted.connect(func(_t): sign_up())
	row.add_child(_name)
	v.add_child(row)
	# what the town hall already knows (and no street: the user)
	var fem: bool = G.look_sel.size() > 9 and int(G.look_sel[9]) == 1
	for f in [["pad_sex", Loc.t("pad_sex_f" if fem else "pad_sex_m")], ["pad_reason", Loc.t("pad_reason_v")], ["pad_home", Loc.t("pad_home_v")], ["pad_notes", Loc.t("pad_notes_v")]]:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 14)
		var k := _text(Loc.t(f[0]), 22)
		k.custom_minimum_size = Vector2(230, 0)
		r.add_child(k)
		var val := _text(String(f[1]), 22)
		val.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		val.custom_minimum_size = Vector2(440, 0)
		r.add_child(val)
		v.add_child(r)
	_warn = _text(Loc.t("pad_empty"), 20, RED_INK)
	_warn.modulate.a = 0.0
	v.add_child(_warn)
	# the clerk's word, and the two signatures (the user, 16 Nov 2026: the mayor's, there already -- a scrawl that does
	# say "Don Alcalde" -- and yours, a scrawl of no letters, when you sign)
	var clerk := _text(Loc.t("pad_clerk"), 17)
	clerk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(clerk)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 20)
	var boxes: Array = []
	for who in ["pad_signature", "pad_mayor"]:
		var sig := PanelContainer.new()
		var sigb := _box(Color.WHITE, Color.BLACK, 2, 0)
		sigb.content_margin_left = 10; sigb.content_margin_top = 4; sigb.content_margin_right = 10; sigb.content_margin_bottom = 4
		sig.add_theme_stylebox_override("panel", sigb)
		sig.custom_minimum_size = Vector2(340, 104)
		sig.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sv := VBoxContainer.new()
		sv.add_child(_text(Loc.t(who), 15))
		var f := Firma.new()
		f.custom_minimum_size = Vector2(0, 70)
		f.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sv.add_child(f)
		sig.add_child(sv)
		bottom.add_child(sig)
		boxes.append(f)
	_signature = boxes[0]
	_signature.k = 0.0                              # (yours: nothing yet)
	_mayor = boxes[1]
	_mayor.text = "Don Alcalde"
	_mayor.seed = 7
	v.add_child(bottom)
	# the town hall's stamp, once it is signed: big, crooked, in ink that took unevenly (stamp.gdshader-like grain below)
	_stamp = _text(Loc.t("pad_stamp"), 78, RED_INK, HORIZONTAL_ALIGNMENT_CENTER)
	var stb := _box(Color(1, 1, 1, 0), RED_INK, 8, 14)
	stb.content_margin_left = 26; stb.content_margin_right = 26; stb.content_margin_top = 4; stb.content_margin_bottom = 4
	_stamp.add_theme_stylebox_override("normal", stb)
	_stamp.visible = false
	_stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stamp.material = _ink()
	# the keys for a pad (letters, a space, rub out, sign); Firmar for a mouse or a finger as well
	var under := VBoxContainer.new()
	under.add_theme_constant_override("separation", 8)
	under.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(under)
	_keys = GridContainer.new()
	(_keys as GridContainer).columns = 12
	_keys.add_theme_constant_override("h_separation", 6)
	_keys.add_theme_constant_override("v_separation", 6)
	for ch in LETTERS:
		_keys.add_child(_key(ch, _type.bind(ch)))
	_keys.add_child(_key(Loc.t("pad_space"), _type.bind(" "), 2))
	_keys.add_child(_key("⌫", rub_out))
	under.add_child(_keys)
	_sign_btn = _key(Loc.t("pad_sign"), sign_up, 0)
	_sign_btn.custom_minimum_size = Vector2(280, 58)
	_sign_btn.add_theme_font_size_override("font_size", 28)
	var hold := CenterContainer.new()
	hold.add_child(_sign_btn)
	under.add_child(hold)
	var over := CenterContainer.new()               # (the stamp over the sheet, in the middle of the screen)
	over.set_anchors_preset(Control.PRESET_FULL_RECT)
	over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(over)
	_stamp_hold = Control.new()                     # (a plain holder: a container would stand the stamp up straight)
	_stamp_hold.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over.add_child(_stamp_hold)
	_stamp_hold.add_child(_stamp)

## Stamp ink: patchy where the rubber did not take, specks of paper showing through, the whole a little see-through
## (the user: "al 90% ... con efecto grumo para que dé aspecto de sello"). The grain is fixed to the stamp itself.
const STAMP_ALPHA := 0.9
func _ink() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform sampler2D grain : repeat_enable, filter_linear;
uniform sampler2D speck : repeat_enable, filter_linear;
uniform float opacity = 0.9;
varying vec2 at;
void vertex() { at = VERTEX; }
void fragment() {
	float g = texture(grain, at / 180.0).r;
	float s = texture(speck, at / 23.0).r;
	float ink = smoothstep(0.28, 0.62, g);
	float holes = smoothstep(0.26, 0.36, s);
	COLOR.a *= opacity * mix(0.45, 1.0, ink) * holes;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	for p in [["grain", 0.012, 3], ["speck", 0.09, 1]]:
		var nz := FastNoiseLite.new()
		nz.seed = 11
		nz.frequency = float(p[1])
		nz.fractal_octaves = int(p[2])
		var tex := NoiseTexture2D.new()
		tex.width = 256
		tex.height = 256
		tex.seamless = true
		tex.noise = nz
		m.set_shader_parameter(String(p[0]), tex)
	m.set_shader_parameter("opacity", STAMP_ALPHA)
	return m

## A signature in ink: `text` written as a hand writes it in a hurry (slanted, a flourish under it), or with no
## text a scrawl of loops that reads as nobody's letters. `k`: how much of it the pen has drawn (0..1).
class Firma extends Control:
	var text := ""
	var seed := 3
	var k := 1.0:
		set(v):
			k = v
			queue_redraw()
	var ink := Color(0.12, 0.25, 0.58)

	func _stroke(pts: PackedVector2Array, width: float) -> void:
		var n := int(round(pts.size() * clampf(k, 0.0, 1.0)))
		if n >= 2:
			draw_polyline(pts.slice(0, n), ink, width, true)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		if text != "":
			var font: Font = get_theme_default_font()
			var fs := 34
			var tw: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var x0: float = maxf(4.0, (w - tw * 0.95) / 2.0)
			var base: float = h * 0.62
			if k >= 0.999:
				draw_set_transform_matrix(Transform2D(Vector2(1.0, -0.06), Vector2(-0.42, 1.0), Vector2(x0 + base * 0.42, base)))
				draw_string(font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
				draw_set_transform_matrix(Transform2D.IDENTITY)
			var fl := PackedVector2Array()                # the flourish: back under the name in one loop, and away
			for i in range(48):
				var t := i / 47.0
				fl.append(Vector2(lerpf(x0 + tw + 6.0, x0 - 4.0, t) + 10.0 * sin(t * PI), base + 8.0 + 9.0 * sin(t * TAU * 1.5) * (1.0 - t)))
			_stroke(fl, 2.2)
			return
		var pts := PackedVector2Array()                   # nobody's letters: a capital, slanted loops of uneven height, the line under
		var base := h * 0.66
		var slant := 0.38
		var tall := h * 0.5
		for i in range(28):                               # the capital: a tall loop, up and round
			var t := i / 27.0
			var a := t * TAU
			var y := base - tall * (0.5 - 0.5 * cos(a)) * 1.15
			pts.append(Vector2(w * 0.1 + 9.0 * sin(a) + t * 10.0 + (base - y) * slant, y))
		var loops := 4 + rng.randi() % 3
		var heights: Array = []
		for l in range(loops):
			heights.append(rng.randf_range(0.35, 0.95))
		var x0 := pts[pts.size() - 1].x - (base - pts[pts.size() - 1].y) * slant
		var n := loops * 22
		for i in range(n):                                # the rest of the name that nobody can read
			var t := i / float(n - 1)
			var a := t * TAU * loops
			var hs: float = heights[mini(int(t * loops), loops - 1)]
			var y := base - tall * hs * (0.5 - 0.5 * cos(a))
			pts.append(Vector2(lerpf(x0, w * 0.76, t) - 8.0 * sin(a) + (base - y) * slant, y))
		var last := pts[pts.size() - 1]
		for i in range(1, 12):                            # away up to the right...
			var t := i / 11.0
			pts.append(last.lerp(Vector2(w * 0.9, h * 0.2), t))
		var top := pts[pts.size() - 1]
		for i in range(1, 30):                            # ...and back under it all in one stroke
			var t := i / 29.0
			pts.append(Vector2(lerpf(top.x, w * 0.08, t), lerpf(top.y, h * 0.86, minf(1.0, t * 3.0)) + 4.0 * sin(t * PI * 2.0)))
		_stroke(pts, 2.4)

func _key(t: String, on: Callable, wide := 1) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(52 * wide + (6 * (wide - 1) if wide > 1 else 0), 50)
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _box(Color.WHITE, Color.BLACK, 3, 8))
	b.add_theme_stylebox_override("hover", _box(Color(0.92, 0.92, 0.92), Color.BLACK, 3, 8))
	b.add_theme_stylebox_override("focus", _box(Color.BLACK, Color.BLACK, 3, 8))
	b.add_theme_stylebox_override("pressed", _box(Color.BLACK, Color.BLACK, 3, 8))
	b.pressed.connect(on)
	return b

## a pad, a keyboard or a finger: the letter keys are there only for a pad
func refresh() -> void:
	if _keys == null or not is_inside_tree():
		return
	_keys.visible = Controls.pad and not signed
	_sign_btn.visible = not signed
	if Controls.pad and not signed and not (get_viewport().gui_get_focus_owner() is Button):
		(_keys.get_child(0) as Button).grab_focus()

## what is typed: letters (with their accents), spaces, a hyphen, an apostrophe; capital at the start of each word
func _on_typed(t: String) -> void:
	var clean := ""
	for ch in t:
		if ch == " " or ch == "-" or ch == "'" or ch.to_upper() != ch.to_lower():
			clean += ch
	clean = clean.lstrip(" ").replace("  ", " ")
	var out := ""
	for i in range(clean.length()):
		var ch: String = clean[i]
		out += ch.to_upper() if i == 0 or clean[i - 1] in [" ", "-"] else ch
	if out != t:
		var at := _name.caret_column
		_name.text = out
		_name.caret_column = mini(at, out.length())
	_warn.modulate.a = 0.0

func _type(ch: String) -> void:
	if signed or _name.text.length() >= MAX_LEN:
		return
	_name.text += ch.to_lower()
	_on_typed(_name.text)
	_name.caret_column = _name.text.length()
	Sfx.beep(520.0, 0.03, 1, -20.0)

func rub_out() -> void:
	if signed or _name.text.is_empty():
		return
	_name.text = _name.text.substr(0, _name.text.length() - 1)
	_name.caret_column = _name.text.length()
	Sfx.beep(330.0, 0.03, 1, -20.0)

## for the tests: what a keyboard would have typed
func type_text(t: String) -> void:
	_name.text = t
	_on_typed(t)

## the keys the sheet's own controls do not take: B rubs out, Start signs
func input(e: InputEvent) -> void:
	if not active or signed:
		return
	if e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_START:
		sign_up()
	elif e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_B:
		rub_out()

## signed: the name goes in, the stamp comes down, and on
func sign_up() -> void:
	if signed or not active:
		return
	var nm: String = _name.text.strip_edges().replace("  ", " ")
	if nm.length() < 2:
		_warn.modulate.a = 1.0
		Sfx.beep(196.0, 0.15, 2, -14.0)
		return
	signed = true
	_name.editable = false
	_name.release_focus()
	G.stats["nombre"] = nm
	refresh()
	plaque()
	_signature.seed = nm.hash()                          # (your scrawl: always the same one for the same name)
	_stamp.size = _stamp.get_combined_minimum_size()
	_stamp_hold.custom_minimum_size = _stamp.size
	_stamp.position = Vector2(0, -40)
	_stamp.pivot_offset = _stamp.size / 2.0
	_stamp.rotation = -0.33
	_stamp.scale = Vector2(1.9, 1.9)
	_stamp.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_signature, "k", 1.0, 0.7)          # the pen goes...
	tw.tween_callback(func():                              # ...and down comes the stamp
		_stamp.visible = true
		Sfx.beep(130.0, 0.12, 1, -6.0, 60.0))
	tw.tween_property(_stamp, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_stamp, "modulate:a", 1.0, 0.1)
	tw.tween_interval(1.4)
	tw.tween_callback(close)

func close() -> void:
	if not active:
		return
	active = false
	visible = false
	if _then.is_valid():
		_then.call()

# ---------------- "Casa de ..." over your door ----------------
## A tile over the door of the house where you sleep: white glaze, a blue border, "Casa de" and your name in blue.
## Made (or written again) whenever the name changes; none while there is no name.
func plaque() -> void:
	if _plaque != null and is_instance_valid(_plaque):
		_plaque.queue_free()
		_plaque = null
	var nm := player_name()
	if nm == "" or G.world == null:
		return
	# over the door of the house you inherit: its front (the map's o, u, len), the door's place along it and its height
	# (casas.gd's SPECS); the wall found by a ray, and the tile a hand's breadth out from it, square to the front
	var door: Vector2 = G.HOME_DOOR
	var along_u := Vector2.ZERO
	var y := MapData.foot(door) + 2.6
	for hd in MapData.houses:
		if String(hd["id"]) == HOME_HOUSE:
			var o := Vector2(hd["o"][0], hd["o"][1])
			along_u = Vector2(hd["u"][0], hd["u"][1])
			var spec: Dictionary = Casas.SPECS.get(HOME_HOUSE, {})
			for op in (spec.get("floors", [{}])[0] as Dictionary).get("open", []):
				if String(op[0]) == "door":
					door = o + along_u * float(op[1]) * float(hd["len"])
					y = float(hd.get("base", MapData.foot(door))) + float(op[3]) + 0.34
					break
	var road: Dictionary = MapData.nearest_road(door, true)
	var out: Vector2 = (door - (road["p"] as Vector2)).normalized()     # (from the street towards the house)
	if along_u != Vector2.ZERO:
		var n := Vector2(along_u.y, -along_u.x)
		out = n if n.dot(out) > 0.0 else -n
	var space: PhysicsDirectSpaceState3D = G.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(door.x - out.x * 3.0, y, door.y - out.y * 3.0), Vector3(door.x + out.x * 3.0, y, door.y + out.y * 3.0), 1)
	var hit := space.intersect_ray(q)
	var face := Vector3(-out.x, 0.0, -out.y)
	var at := Vector3(door.x, y, door.y) + face * 0.1
	if not hit.is_empty():
		at = Vector3((hit["position"] as Vector3).x, y, (hit["position"] as Vector3).z) + face * 0.1      # (the wall drawn stands a little in front of what is solid)
	_plaque = Node3D.new()
	G.add_child(_plaque)
	_plaque.global_position = at
	_plaque.look_at(at - face, Vector3.UP)          # (-z into the wall: its front, +z, to the street, as a Label3D reads)
	var back := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.78, 0.34, 0.025)
	back.mesh = bm
	var blue := StandardMaterial3D.new()
	blue.albedo_color = TILE_BLUE
	back.material_override = blue
	_plaque.add_child(back)
	var tile := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(0.72, 0.28, 0.03)
	tile.mesh = tm
	var glaze := StandardMaterial3D.new()
	glaze.albedo_color = Color(0.97, 0.96, 0.93)
	glaze.roughness = 0.25
	glaze.metallic_specular = 0.7
	tile.material_override = glaze
	tile.position.z = 0.005
	_plaque.add_child(tile)
	var lab := Label3D.new()
	lab.text = Loc.t("pad_plaque") % nm
	lab.modulate = TILE_BLUE
	lab.outline_size = 0
	lab.font_size = 64
	lab.shaded = false
	lab.double_sided = false
	var font: Font = lab.font if lab.font != null else ThemeDB.fallback_font
	var wide: float = font.get_string_size(lab.text, HORIZONTAL_ALIGNMENT_LEFT, -1, lab.font_size).x
	lab.pixel_size = minf(0.0034, 0.64 / maxf(1.0, wide))
	lab.position.z = 0.024
	_plaque.add_child(lab)

# ---------------- your name in people's mouths ----------------
## whether `who` (a speaker's shown name) knows you by name: a neighbour of their own from KNOWN of trust; anybody else
## of the town once TOWN_SHARE of the story's missions are done; nobody before you have a name
func knows_me(who: String) -> bool:
	if player_name() == "":
		return false
	var n = G._speaker(who)
	if n == null:
		return false
	if String(n.id) != "":
		return G.folk.trust(n.id) >= KNOWN
	return town_share() >= TOWN_SHARE

## how much of the story's missions are done (missions.gd STEPS: from each card to the next; "log": false is no mission)
func town_share() -> float:
	var steps: Array = G.steps
	var total := 0
	var done := 0
	for i in range(steps.size()):
		var s: Dictionary = steps[i]
		if not s.has("card") or s.get("log", true) == false:
			continue
		var last := i
		for j in range(i + 1, steps.size()):
			if steps[j].has("card") or String(steps[j].get("type", "")) == "tbc":
				break
			last = j
		total += 1
		if int(G.si) > last:
			done += 1
	return float(done) / maxf(1.0, float(total))

## what `who` says, with your name where they would have called you "hijo" or "hermosa" -- if they know it
func by_name(lines: Array, who: String) -> Array:
	if not knows_me(who):
		return lines
	var nm := player_name()
	var out: Array = []
	for l in lines:
		out.append(_calls_rx.sub(String(l), "$1" + nm, true) if l is String else l)
	return out

## what is muttered behind your back once the town knows your name: not "the one of Eufrasia's" any more, but you
func whispers(usual: Array) -> Array:
	if player_name() == "" or town_share() < TOWN_SHARE:
		return usual
	var out: Array = usual.filter(func(w): return not String(w).contains("Eufrasia"))
	for w in Loc.t("whisper_nombre"):
		out.append(String(w) % player_name())
	return out
