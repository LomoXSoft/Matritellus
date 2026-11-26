extends Control
## The menus (main, saves, settings, controls, how to play, credits, pause), drawn as a whitewashed Manchego wall
## capped with roof tiles, with the options painted on it by a sign-writer's brush (Kaushan Script, OFL: assets/fuentes).
## The one selected is not boxed (the user, 23 Nov 2026: "No me gusta que sean textos entre cuadros el texto
## seleccionado, y la letra es muy básica"; of three looks, "Me gusta la A"): it turns añil, leans a little and grows,
## with a stroke of almagre brushed under it. The Agenda (the notebook) keeps its own look, plaques and all.
##
## game.gd supplies the content: `builder.call(page_id)` returns
##   {"title": String, "sub": String, "items": Array, "back": String page id | Callable | null}
## and each item is one of
##   {"text": String, "do": Callable}                                  an option
##   {"text": String, "value": String, "left": Callable, "right": Callable}   a setting changed with left / right
##   {"text": String, "plain": true}                                   a line of text (not selectable)

const Portrait = preload("res://scripts/portrait.gd")
const INK := Color("2a221c")
const LIME := Color("f8f5ec")
const ANIL := Color("3f5fae")             # the chosen option on the wall
const ALMAGRE := Color("b0452a")          # the brush stroke under it
const MUTED := Color("7a6a58")
const LEAN := -0.035                      # (about two degrees)
const GROW := 1.08
const WALL_W := 1000.0                    # the wall at least this wide: a long low wall, not a square (the user, 23 Nov 2026:
                                          # "lo haría más panorámico, está muy cuadrado (o incluso alargado verticalmente)")
const PLINTH := 56.0
const FIGURES := "res://assets/menu/quijote_sancho.svg"      # Don Quijote and Sancho in black sheet, as on the sign at the
                                          # old road's entrance (the user, 23 Nov 2026: "pondría alguna marca de ladrillo y
                                          # alguna pequeña grieta, un quijote y sancho en figuras negras en un lado, todo para
                                          # rellenar el hueco vacío ... (pero nosotros manteniendo el zócalo azul)")
static var _figs: Texture2D
static var _paint: Font                   # the sign-writer's letters
static var _dense: FontVariation          # the same, its lines closer (the long settings pages)

## the painted letters, with the plain font behind them for anything they lack
static func paint_font() -> Font:
	if _paint == null:
		var src = load("res://assets/fuentes/KaushanScript-Regular.ttf") as FontFile
		if src == null:                     # (not imported yet: the plain letters, rather than an error)
			return ThemeDB.fallback_font
		var f: FontFile = src.duplicate()
		f.fallbacks = [ThemeDB.fallback_font]
		_paint = f
	return _paint

## the painted letters with less room above and below them: its lines are tall, and the graphics page has 24 rows
static func dense_font() -> Font:
	if _dense == null:
		_dense = FontVariation.new()
		_dense.base_font = paint_font()
		_dense.spacing_top = -5
		_dense.spacing_bottom = -4
	return _dense

var builder: Callable
var page := ""
var sel := 0
var capture = null              # a Callable waiting for the next key press (key rebinding)
var _items: Array = []
var _back = null
var _box: VBoxContainer
var _title: Label
var _sub: RichTextLabel
var _crest: TextureRect
var _list: VBoxContainer
var _foot: RichTextLabel
var _stones: Array = []
var _skin := ""                 # "" the wall; "notebook" the Agenda
var _tab := 0
var _prog_bar: ProgressBar
var _prog_lab: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)      # anchors AND offsets, or the control stays 0 x 0 in the corner
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 6)
	_box.custom_minimum_size = Vector2(560, 0)
	centre.add_child(_box)
	_crest = TextureRect.new()
	_crest.texture = preload("res://scripts/parts.gd").texture("res://assets/logo.png")
	_crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_crest.custom_minimum_size = Vector2(96, 96)
	_box.add_child(_crest)
	_sub = _rich(20, INK)
	_sub.add_theme_stylebox_override("normal", _plaque(Color("efe9da"), 2))
	_sub.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_box.add_child(_sub)
	_title = _text(46, INK)
	_title.add_theme_stylebox_override("normal", _plaque(Color("efe9da"), 3))
	_title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_box.add_child(_title)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	_box.add_child(gap)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 3)
	_box.add_child(_list)
	_foot = _rich(15, Color("7a6a58"))
	_box.add_child(_foot)
	_box.resized.connect(queue_redraw)
	_box.item_rect_changed.connect(queue_redraw)      # it also moves when its contents change (it is kept centred)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for i in range(22):             # the stones poking through the lime
		_stones.append([rng.randf(), rng.randf(), rng.randf_range(5.0, 11.0), rng.randf_range(0.7, 1.3)])

## a centred line that can carry the pictures of buttons (Controls.fill)
func _rich(size: int, color: Color) -> RichTextLabel:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("normal_font_size", size)
	l.add_theme_color_override("default_color", color)
	l.set_meta("h", int(round(size * 1.45)))
	return l

func _rich_text(l: RichTextLabel, text: String) -> void:
	l.text = text.replace("[img height=%d]" % Controls.ICON_H, "[img height=%d]" % int(l.get_meta("h", 22)))

func _text(size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _plaque(bg: Color, border: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = INK
	sb.set_border_width_all(border)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 22; sb.content_margin_right = 22; sb.content_margin_top = 2; sb.content_margin_bottom = 3
	return sb

func open(id: String) -> void:
	page = id
	sel = -1
	visible = true
	rebuild()

func close() -> void:
	visible = false
	capture = null

func rebuild() -> void:
	var p: Dictionary = builder.call(page)
	_items = p["items"]
	_back = p.get("back")
	_title.text = p.get("title", "")
	_title.visible = _title.text != ""
	_rich_text(_sub, p.get("sub", ""))
	_sub.visible = _sub.text != ""
	_crest.visible = p.get("crest", false)
	_skin = p.get("skin", "")
	_tab = int(p.get("tab", 0))
	_rich_text(_foot, p.get("foot", ""))
	_dress_heads()
	var big_rows := _skin == "" and _items.all(func(it): return it.get("plain", false) or int(it.get("size", 26)) >= 24)
	_list.add_theme_constant_override("separation", -8 if big_rows else 3)
	if sel < 0 or sel >= _items.size() or (_items[sel].get("plain", false) or _items[sel].has("meter") or _items[sel].has("progress")):
		sel = 0
		while sel < _items.size() - 1 and (_items[sel].get("plain", false) or _items[sel].has("meter") or _items[sel].has("progress")):
			sel += 1
	_prog_bar = null
	_prog_lab = null
	for c in _list.get_children():
		c.free()
	for i in range(_items.size()):
		var it: Dictionary = _items[i]
		var plain: bool = it.get("plain", false)
		if it.has("progress"):                   # an in-place progress bar and its status line (updater)
			_list.add_child(_progress_row(it))
			continue
		if it.has("meter"):                      # a name, a bar and a number (the neighbours' trust)
			_list.add_child(_meter_row(it))
			continue
		if it.has("logo"):                       # a radio station: its logo, its name, what it says of itself, what it plays
			var st_row := HBoxContainer.new()
			st_row.alignment = BoxContainer.ALIGNMENT_CENTER
			st_row.add_theme_constant_override("separation", 14)
			var pic := TextureRect.new()
			pic.texture = it["logo"]
			pic.custom_minimum_size = Vector2(58, 58)
			pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			st_row.add_child(pic)
			var col := VBoxContainer.new()
			col.add_theme_constant_override("separation", -3)
			var head := _text(20, Color("b0452a") if it.get("on", false) else INK)
			head.text = String(it["text"]) + (("   ♪ " + String(it.get("on_text", ""))) if it.get("on", false) else "")
			head.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			var about := _text(14, Color("5a4a3a"))
			about.text = it.get("sub", "")
			about.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			var songs := _text(12, Color("3b5fa8"))
			songs.text = it.get("songs", "")
			songs.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			songs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			songs.custom_minimum_size = Vector2(560, 0)
			col.add_child(head); col.add_child(about); col.add_child(songs)
			st_row.add_child(col)
			_list.add_child(st_row)
			continue
		if it.has("grid"):                       # the figures out of the gumball machines: a photo and a name each, in rows
			_list.add_child(_figure_grid(it))
			continue
		if it.has("face"):                       # a saved game: the photo of who it is, and the label beside it
			var row := HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 16)
			row.add_child(Portrait.framed(it["face"], Vector2i(70, 86)))
			var lab := _text(int(it.get("size", 22)), INK)
			lab.text = it["text"]
			lab.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			if _skin == "":
				_painted(lab, int(it.get("size", 22)))
			if i == sel:
				_mark(lab)
			row.add_child(lab)
			row.set_meta("menu_i", i)
			_list.add_child(row)
			continue
		var l := _text(int(it.get("size", 17 if plain else 26)), Color("5a4a3a") if plain else INK)
		if not plain and _skin == "":
			_painted(l, int(it.get("size", 26)))
		var t: String = it["text"]
		if it.has("value"):
			t += ":   ‹ " + String(it["value"]) + " ›"
		if capture != null and i == sel:
			t = String(it["text"]) + ":   …"
		l.text = t
		if plain:
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(640, 0)
		else:
			l.set_meta("menu_i", i)
			l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			if i == sel:
				_mark(l)
		_list.add_child(l)
	queue_redraw()
	_redraw_when_laid_out()

## {"grid": [{"tex", "got", "n", "name"}...], "cols"}: each figure's photo over its name; one you have not had yet in
## black, named "???"; one you have more than once with how many beside its name
func _figure_grid(it: Dictionary) -> Control:
	var grid := GridContainer.new()
	grid.columns = int(it.get("cols", 8))
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for c in it["grid"]:
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 0)
		var frame := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("efe6cf") if c.get("got", false) else Color("e6dfcc")
		sb.border_color = Color("b9ad96")
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(4)
		frame.add_theme_stylebox_override("panel", sb)
		var pic := TextureRect.new()
		pic.texture = c.get("tex")
		pic.custom_minimum_size = Vector2(72, 90)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if not c.get("got", false):
			pic.modulate = Color(0.06, 0.05, 0.05)       # (a black shape: who it is, you will see when you get it)
		frame.add_child(pic)
		cell.add_child(frame)
		var lab := _text(12, INK if c.get("got", false) else Color("8a7a68"))
		lab.text = String(c.get("name", "???")) + ("  ×%d" % int(c["n"]) if int(c.get("n", 0)) > 1 else "")
		lab.clip_text = true
		lab.custom_minimum_size = Vector2(74, 0)
		cell.add_child(lab)
		grid.add_child(cell)
	return grid

## The wall is painted round the box of text, and the box only takes its new size and place on the next frame:
## paint it again then, or the wall stays where the previous page had it until something else is pressed.
## the title and the line over it: painted on the wall, on plaques in the notebook
func _dress_heads() -> void:
	if _skin == "":
		_title.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		_title.add_theme_font_override("font", paint_font())
		_title.add_theme_font_size_override("font_size", 52)
		_sub.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		_sub.add_theme_font_override("normal_font", paint_font())
		_sub.add_theme_font_size_override("normal_font_size", 22)
		_sub.add_theme_color_override("default_color", MUTED)
	else:
		_title.add_theme_stylebox_override("normal", _plaque(Color("efe9da"), 3))
		_title.remove_theme_font_override("font")
		_title.add_theme_font_size_override("font_size", 46)
		_sub.add_theme_stylebox_override("normal", _plaque(Color("efe9da"), 2))
		_sub.remove_theme_font_override("normal_font")
		_sub.add_theme_font_size_override("normal_font_size", 20)
		_sub.add_theme_color_override("default_color", INK)

## an option painted on the wall: the brush letters, a little bigger (they are smaller than the plain ones), and room
## for the lean and the stroke
func _painted(l: Label, size: int) -> void:
	var small := size < 24                     # (the rows of the long pages: as they were, closer together)
	l.set_meta("dense", small)
	l.add_theme_font_override("font", dense_font() if small else paint_font())
	l.add_theme_font_size_override("font_size", size + 1 if small else int(round(size * 1.18)))
	var sb := StyleBoxEmpty.new()
	sb.content_margin_left = 14; sb.content_margin_right = 14; sb.content_margin_bottom = 0 if small else 4
	l.add_theme_stylebox_override("normal", sb)

## the option selected: on the wall añil, leaning and grown, the stroke under it (_draw); in the notebook, its plaque
func _mark(l: Label) -> void:
	if _skin != "":
		l.add_theme_stylebox_override("normal", _plaque(Color("f3e2b3"), 2))
		return
	l.set_meta("chosen", true)
	l.add_theme_color_override("font_color", ANIL)
	l.rotation = LEAN
	l.scale = Vector2(GROW, GROW)
	l.pivot_offset = l.size * 0.5
	l.resized.connect(func(): l.pivot_offset = l.size * 0.5)

## the chosen option on the wall, if there is one
func chosen() -> Label:
	for c in _list.find_children("*", "Label", true, false):
		if c.has_meta("chosen") and c.is_visible_in_tree():
			return c
	return null

## the empty wall at both sides of the words: where the lime has come away and the brick shows, a few small cracks,
## and on the right Don Quijote and Sancho cut out of black sheet, standing on the skirting
func _draw_wear(r: Rect2, plinth_y: float) -> void:
	var b := _ink_rect()
	var lx0 := r.position.x + 18.0
	var lx1 := b.position.x - 24.0
	var rx0 := b.end.x + 24.0
	var rx1 := r.end.x - 18.0
	var left_w := lx1 - lx0
	var right_w := rx1 - rx0
	if left_w > 70.0:
		var lm := (lx0 + lx1) * 0.5
		_brick_patch(Vector2(lm - left_w * 0.08, r.position.y + (plinth_y - r.position.y) * 0.42), Vector2(minf(68.0, left_w * 0.36), 36.0), 3)
		_brick_patch(Vector2(lx0 + left_w * 0.72, plinth_y - 34.0), Vector2(minf(46.0, left_w * 0.24), 22.0), 8)
		_crack(Vector2(lx0 + left_w * 0.3, r.position.y + 26.0), PI * 0.5 + 0.25, 70.0, 11)
		_crack(Vector2(lx0 + left_w * 0.55, plinth_y), -PI * 0.5 - 0.2, 40.0, 5)
	if right_w > 70.0:
		_brick_patch(Vector2(rx0 + right_w * 0.62, r.position.y + 64.0), Vector2(minf(40.0, right_w * 0.22), 22.0), 14)
		_crack(Vector2(rx0 + right_w * 0.2, r.position.y + 30.0), PI * 0.5 - 0.3, 52.0, 21)
	if right_w > 110.0:
		if _figs == null and ResourceLoader.exists(FIGURES):
			_figs = load(FIGURES)
		if _figs != null:
			var w := minf(300.0, right_w - 6.0)
			var h := w * float(_figs.get_height()) / float(_figs.get_width())
			draw_texture_rect(_figs, Rect2(Vector2((rx0 + rx1 - w) * 0.5, plinth_y - h + 3.0), Vector2(w, h)), false)

## where there are words (or the crest) on the wall: each line as wide as what it says, not as the column
func _ink_rect() -> Rect2:
	var out := Rect2()
	var parts: Array = [_crest, _sub, _title, _foot]
	parts.append_array(_list.get_children())
	for c in parts:
		if not (c is Control) or not (c as Control).is_visible_in_tree():
			continue
		var cr := Rect2((c as Control).global_position - global_position, (c as Control).size)
		var w: float = cr.size.x
		if c is RichTextLabel:
			w = float((c as RichTextLabel).get_content_width())
		elif c is BoxContainer or c is GridContainer:
			w = (c as Control).get_combined_minimum_size().x
		elif c is TextureRect:
			w = (c as Control).custom_minimum_size.x
		var one := Rect2(cr.get_center().x - w * 0.5, cr.position.y, w, cr.size.y)
		out = one if out.size == Vector2.ZERO else out.merge(one)
	return out if out.size != Vector2.ZERO else Rect2(_box.global_position - global_position, _box.size)

## a patch where the lime has fallen off: the mortar showing, the bricks in their courses, the lime's broken edge
func _brick_patch(at: Vector2, size: Vector2, seed_n: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_n
	var hole := PackedVector2Array()
	for i in range(16):
		var t := TAU * i / 16.0
		var k := rng.randf_range(0.7, 1.12)
		hole.append(at + Vector2(cos(t) * size.x * 0.5 * k, sin(t) * size.y * 0.5 * k))
	draw_colored_polygon(hole, Color("cbbca2"))
	var bw := 17.0
	var bh := 7.0
	var y := at.y - size.y * 0.6
	var row := 0
	while y < at.y + size.y * 0.6:
		var x := at.x - size.x * 0.6 - (bw * 0.5 if row % 2 == 1 else 0.0)
		while x < at.x + size.x * 0.6:
			var c := Vector2(x + bw * 0.5, y + bh * 0.5)
			if Geometry2D.is_point_in_polygon(c, hole):
				var tone: Color = [Color("b65e3b"), Color("a8533a"), Color("c26a45"), Color("9e4c34")][rng.randi() % 4]
				draw_rect(Rect2(x + 1.0, y + 1.0, bw - 2.0, bh - 2.0), tone)
			x += bw
		y += bh
		row += 1
	var edge := hole.duplicate()
	edge.append(hole[0])
	draw_polyline(edge, Color("d8d2c3"), 2.0, true)
	for i in range(5, 12):                           # (the shadow under the lime's lip, on the lower side)
		draw_line(hole[i], hole[i + 1], Color(0.45, 0.4, 0.34, 0.45), 1.5, true)

## a hairline crack: a crooked line from `from` that wanders about `heading`, thinning out, with a short branch
func _crack(from: Vector2, heading: float, length: float, seed_n: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_n
	var p := from
	var steps := 7
	var ink := Color(0.38, 0.34, 0.3, 0.7)
	for i in range(steps):
		var q := p + Vector2.from_angle(heading + rng.randf_range(-0.6, 0.6)) * (length / steps)
		draw_line(p, q, ink, lerpf(1.8, 0.7, float(i) / steps), true)
		if i == 2:
			var br := q
			for j in range(3):
				var bq := br + Vector2.from_angle(heading + 0.9 + rng.randf_range(-0.4, 0.4)) * (length / steps * 0.7)
				draw_line(br, bq, ink, lerpf(1.1, 0.5, j / 3.0), true)
				br = bq
		p = q

## the stroke of almagre under the chosen option: thick in the middle, thin at both ends, its top edge wavering, and as
## long as the word and a little more, leaning with it
func _draw_stroke() -> void:
	var l := chosen()
	if l == null or l.size.x < 4.0:
		return
	var r := Rect2(l.global_position - global_position, l.size)
	var c := r.get_center()
	var dense: bool = l.get_meta("dense", false)
	var w := (r.size.x - 20.0) * GROW * 1.06
	var y := r.size.y * 0.5 * GROW + (1.0 if dense else -9.0)     # (the close rows' letters hang below their box)
	var k := 0.6 if dense else 1.0
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	var n := 24
	for i in range(n + 1):
		var t := float(i) / n
		var x := -w * 0.5 + w * t
		var th := (3.0 + 6.0 * sin(t * PI) + sin(t * 17.0) * 0.8) * k
		var mid := y + sin(t * 5.0 + 0.6) * 1.6 - t * 2.0
		top.append(Vector2(x, mid - th * 0.5))
		bot.append(Vector2(x + 2.0, mid + th * 0.5))
	bot.reverse()
	draw_set_transform(c, LEAN, Vector2.ONE)
	draw_colored_polygon(top + bot, Color(ALMAGRE, 0.92))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _redraw_when_laid_out() -> void:
	if not is_inside_tree():
		return
	for i in range(2):
		await get_tree().process_frame
		queue_redraw()

## A band of light sliding across the bar, and a faint sparkle: gold that catches the sun.
const SHINE := "
shader_type canvas_item;
void fragment() {
	float sweep = fract(TIME * 0.42) * 1.7 - 0.35;
	float x = UV.x + (UV.y - 0.5) * 0.12;
	float band = smoothstep(0.13, 0.0, abs(x - sweep));
	float sparkle = pow(0.5 + 0.5 * sin(UV.x * 46.0 + TIME * 5.0), 8.0) * (0.5 + 0.5 * sin(TIME * 2.3 + UV.x * 7.0));
	COLOR = vec4(1.0, 0.98, 0.82, band * 0.85 + sparkle * 0.22);
}
"
static var _shine: ShaderMaterial

## the colour of a trust meter: vermilion up to 24, dull orange to 49, dull yellow to 74, green to 99, gold at 100
static func meter_colour(level: float, gold := false) -> Color:
	var t := int(round(level * 100.0))
	if gold or t >= 100:
		return Color("f2c230")
	if t >= 75:
		return Color("5aa84f")
	if t >= 50:
		return Color("d6bd55")
	if t >= 25:
		return Color("d28a45")
	return Color("e34234")

func _meter_row(it: Dictionary) -> Control:
	var gold: bool = it.get("gold", false)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	var who := _text(17, Color("5a4a3a"))
	who.text = it["text"]
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	who.custom_minimum_size = Vector2(230, 0)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(260, 16)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.value = float(it["meter"])
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("e2d9c6")
	bg.border_color = Color("e6b422") if gold else INK
	bg.set_border_width_all(3 if gold else 2)
	bg.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = meter_colour(float(it["meter"]), gold)
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	var num := _text(17, Color("b8860b") if gold else Color("5a4a3a"))
	num.text = it.get("value_text", "")
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	num.custom_minimum_size = Vector2(70, 0)
	row.add_child(who); row.add_child(bar); row.add_child(num)
	if gold:                                 # a hundred: it gleams
		if _shine == null:
			var sh := Shader.new()
			sh.code = SHINE
			_shine = ShaderMaterial.new()
			_shine.shader = sh
		bar.clip_contents = true
		var light := ColorRect.new()
		light.material = _shine
		light.mouse_filter = Control.MOUSE_FILTER_IGNORE
		light.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bar.add_child(light)
		var glow := num.create_tween().set_loops()       # ...and so does the number
		glow.tween_property(num, "modulate", Color(1.45, 1.3, 0.75), 0.7).set_trans(Tween.TRANS_SINE)
		glow.tween_property(num, "modulate", Color.WHITE, 0.7).set_trans(Tween.TRANS_SINE)
	return row

func _progress_row(it: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(420, 18)
	bar.show_percentage = false
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = clampf(float(it["progress"]), 0.0, 1.0)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("e2d9c6")
	bg.border_color = INK
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = ANIL
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	var lab := _text(17, Color("5a4a3a"))
	lab.text = String(it.get("text", ""))
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(bar)
	box.add_child(lab)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	box.add_child(gap)
	_prog_bar = bar
	_prog_lab = lab
	return box

func set_progress(ratio: float, text: String) -> void:
	if _prog_bar != null and is_instance_valid(_prog_bar):
		_prog_bar.value = clampf(ratio, 0.0, 1.0)
	if _prog_lab != null and is_instance_valid(_prog_lab):
		_prog_lab.text = text

func _move(by: int) -> void:
	var n := _items.size()
	for step in range(n):
		sel = (sel + by + n) % n
		if not (_items[sel].get("plain", false) or _items[sel].has("meter") or _items[sel].has("progress")):
			break
	Sfx.beep(520.0, 0.04, 1, -18.0)
	rebuild()

func _row_at(pos: Vector2) -> int:
	for c in _list.get_children():
		if c is Control and c.has_meta("menu_i"):
			var r: Rect2 = (c as Control).get_global_rect().grow_individual(18.0, 2.0, 18.0, 2.0)
			if r.has_point(pos):
				return int(c.get_meta("menu_i"))
	return -1

func _unhandled_input(e: InputEvent) -> void:
	if not visible:
		return
	if capture != null:                           # waiting for a key to bind
		if e is InputEventKey and e.pressed and not e.echo:
			var cb: Callable = capture
			capture = null
			if e.physical_keycode != KEY_ESCAPE:
				cb.call(e.physical_keycode)
			rebuild()
			get_viewport().set_input_as_handled()
		return
	if e is InputEventMouseMotion:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			var hi := _row_at(e.position)
			if hi >= 0 and hi != sel:
				sel = hi
				Sfx.beep(520.0, 0.04, 1, -18.0)
				rebuild()
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		var ci := _row_at(e.position)
		if ci >= 0 and ci < _items.size():
			sel = ci
			var it_c: Dictionary = _items[sel]
			if it_c.has("do"):
				Sfx.beep(700.0, 0.06, 1, -16.0)
				it_c["do"].call()
				if visible:
					rebuild()
			elif it_c.has("left") and it_c.has("right"):
				var mid_x := _box.get_global_rect().get_center().x
				(it_c["left"] if e.position.x < mid_x else it_c["right"]).call()
				Sfx.beep(600.0, 0.04, 1, -18.0)
				rebuild()
			elif it_c.has("right"):
				it_c["right"].call()
				Sfx.beep(600.0, 0.04, 1, -18.0)
				rebuild()
			get_viewport().set_input_as_handled()
			return
	var handled := true
	if e.is_action_pressed("m_up", true):
		_move(-1)
	elif e.is_action_pressed("m_down", true):
		_move(1)
	elif e.is_action_pressed("m_left", true) or e.is_action_pressed("m_right", true):
		var it: Dictionary = _items[sel] if sel < _items.size() else {}
		var key := "left" if e.is_action_pressed("m_left", true) else "right"
		if it.has(key):
			it[key].call()
			Sfx.beep(600.0, 0.04, 1, -18.0)
			rebuild()
	elif e.is_action_pressed("m_accept"):
		var it2: Dictionary = _items[sel] if sel < _items.size() else {}
		if it2.has("do"):
			Sfx.beep(700.0, 0.06, 1, -16.0)
			it2["do"].call()
			if visible:
				rebuild()
		elif it2.has("right"):
			it2["right"].call()
			rebuild()
	elif e.is_action_pressed("m_back"):
		if _back is String:
			open(_back)
		elif _back is Callable:
			_back.call()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()

# ---------------- the notebook (the Agenda) ----------------
## A ring-bound school notebook lying on the table: green card covers, squared paper, a red margin, the rings down
## the left, a coloured tab for each page down the right, and the stain of somebody's coffee.
func _draw_notebook() -> void:
	var r := Rect2(_box.global_position - global_position, _box.size).grow_individual(118, 40, 84, 56)
	var tabs := [Color("d9643a"), Color("e6b422"), Color("2a9d8f"), Color("5aa84f"), Color("3b5fa8"), Color("c94f7c"), Color("8a4fb8")]
	draw_set_transform(r.get_center(), deg_to_rad(-1.2), Vector2.ONE)
	var o := -r.size / 2.0                               # (drawn round its own middle, a touch crooked)
	draw_rect(Rect2(o + Vector2(12, 16), r.size + Vector2(8, 6)), Color(0, 0, 0, 0.32))
	draw_rect(Rect2(o + Vector2(-10, -8), r.size + Vector2(22, 16)), Color("2f5d3a"))              # the back cover
	draw_rect(Rect2(o + Vector2(-10, -8), r.size + Vector2(22, 16)), Color("1f3f27"), false, 3.0)
	for k in range(tabs.size()):                         # the tabs, sticking out of the right-hand edge
		var here := k == _tab
		var tr := Rect2(o.x + r.size.x - 4.0, o.y + 34.0 + k * 50.0, 44.0 if here else 30.0, 44.0)      # (seven since the "De fondo" page, 21 Nov 2026: closer together)
		draw_rect(Rect2(tr.position + Vector2(2, 3), tr.size), Color(0, 0, 0, 0.25))
		draw_rect(tr, tabs[k] if here else tabs[k].darkened(0.18))
		draw_rect(tr, INK, false, 2.0)
		draw_string(ThemeDB.fallback_font, tr.position + Vector2(tr.size.x - 19.0, 30.0), str(k + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("fff6e0"))
	for k in range(3):                                   # the pages underneath
		draw_rect(Rect2(o + Vector2(3 - k, 3 - k) * 1.5, r.size), Color("e6dfcc"))
	draw_rect(Rect2(o, r.size), Color("fbf7ea"))
	var y := o.y + 34.0
	while y < o.y + r.size.y - 10.0:                     # squared paper
		draw_line(Vector2(o.x + 4.0, y), Vector2(o.x + r.size.x - 4.0, y), Color(0.45, 0.62, 0.86, 0.3), 1.0)
		y += 26.0
	var x := o.x + 86.0
	while x < o.x + r.size.x - 6.0:
		draw_line(Vector2(x, o.y + 4.0), Vector2(x, o.y + r.size.y - 4.0), Color(0.45, 0.62, 0.86, 0.14), 1.0)
		x += 26.0
	draw_line(Vector2(o.x + 78.0, o.y + 2.0), Vector2(o.x + 78.0, o.y + r.size.y - 2.0), Color(0.86, 0.3, 0.28, 0.65), 2.0)      # the margin
	draw_arc(o + Vector2(r.size.x - 88.0, r.size.y - 74.0), 34.0, 0.3, TAU - 0.5, 40, Color(0.5, 0.33, 0.16, 0.2), 5.0, true)      # coffee
	draw_arc(o + Vector2(r.size.x - 88.0, r.size.y - 74.0), 29.0, 1.0, 4.4, 30, Color(0.5, 0.33, 0.16, 0.1), 3.0, true)
	draw_rect(Rect2(o, r.size), Color("b9ad96"), false, 2.0)
	var ry := o.y + 30.0
	while ry < o.y + r.size.y - 22.0:                    # the rings
		draw_circle(Vector2(o.x + 34.0, ry), 7.0, Color("3a3327"))                      # the hole...
		draw_line(Vector2(o.x - 16.0, ry + 3.0), Vector2(o.x + 34.0, ry + 3.0), Color(0, 0, 0, 0.22), 7.0, true)
		draw_line(Vector2(o.x - 16.0, ry), Vector2(o.x + 34.0, ry), Color("7d828a"), 6.0, true)       # ...and the wire through it, round the spine
		draw_line(Vector2(o.x - 14.0, ry - 1.6), Vector2(o.x + 30.0, ry - 1.6), Color("e3e7ea"), 1.6, true)
		draw_circle(Vector2(o.x - 16.0, ry), 3.0, Color("7d828a"))
		ry += 40.0
	var mx := o.x + r.size.x - 150.0                      # a doodle: the same spiral every bored pupil draws
	var my := o.y + 52.0
	var spiral := PackedVector2Array()
	for k in range(44):
		spiral.append(Vector2(mx + cos(k * 0.5) * k * 0.5, my + sin(k * 0.5) * k * 0.5))
	draw_polyline(spiral, Color(0.2, 0.3, 0.6, 0.55), 1.5, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ---------------- the wall ----------------
func _draw() -> void:
	if not visible:
		return
	if _skin == "notebook":
		_draw_notebook()
		return
	var side := maxf(70.0, (WALL_W - _box.size.x) * 0.5)
	var r := Rect2(_box.global_position - global_position, _box.size).grow_individual(side, 38, side, PLINTH + 22.0)
	draw_rect(Rect2(r.position + Vector2(10, 14), r.size), Color(0, 0, 0, 0.28))
	# an uneven top edge, like a wall built by eye
	var top := PackedVector2Array()
	var steps := 40
	for i in range(steps + 1):
		var x := r.position.x + r.size.x * i / steps
		top.append(Vector2(x, r.position.y + sin(i * 0.55) * 7.0 + sin(i * 0.17 + 1.0) * 9.0))
	var wall := top.duplicate()
	wall.append(r.position + r.size)
	wall.append(Vector2(r.position.x, r.position.y + r.size.y))
	draw_colored_polygon(wall, LIME)
	# the skirting: añil blue, as on every whitewashed wall in La Mancha, a little uneven along the top and scuffed
	var plinth := Rect2(r.position.x, r.position.y + r.size.y - PLINTH, r.size.x, PLINTH)
	var skirt := PackedVector2Array()                 # painted by hand: the top line wanders a little
	for i in range(steps + 1):
		skirt.append(Vector2(plinth.position.x + plinth.size.x * i / steps, plinth.position.y + sin(i * 0.9) * 1.8 + sin(i * 0.31 + 2.0) * 1.6))
	skirt.append(plinth.position + plinth.size)
	skirt.append(Vector2(plinth.position.x, plinth.position.y + plinth.size.y))
	draw_colored_polygon(skirt, Color("3f5fae"))
	draw_rect(Rect2(plinth.position.x, plinth.position.y + plinth.size.y - 14.0, plinth.size.x, 14.0), Color("36529a"))      # darker where the mop reaches
	for k in range(9):                                # scuffs: the lime shows through
		var sx := plinth.position.x + plinth.size.x * fposmod(k * 0.371 + 0.08, 1.0)
		var sy := plinth.position.y + 12.0 + fposmod(k * 23.0, PLINTH - 34.0)
		draw_rect(Rect2(sx, sy, 10.0 + fposmod(k * 7.0, 16.0), 3.0), Color(0.93, 0.92, 0.88, 0.5))
	# stones showing through
	for s in _stones:
		var p := Vector2(r.position.x + 24 + s[0] * (r.size.x - 48), r.position.y + 34 + s[1] * (r.size.y - PLINTH - 72.0))
		if absf(p.x - (r.position.x + r.size.x / 2)) < _box.size.x * 0.5 + 40.0 and p.y > r.position.y + 20:
			continue                             # keep the lettering clear
		draw_set_transform(p, 0.0, Vector2(s[3], 1.0))
		draw_circle(Vector2.ZERO, s[2], Color("8a6f58"))
		draw_circle(Vector2(-1.5, -1.5), s[2] * 0.6, Color("a58a70"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_wear(r, plinth.position.y)
	# the row of clay tiles along the top
	for i in range(top.size() - 1):
		var a := top[i]
		var b := top[i + 1]
		draw_line(a + Vector2(0, 4), b + Vector2(0, 4), Color("7d3f24"), 12.0)
	for i in range(top.size()):
		var c := top[i]
		draw_circle(c, 11.0, Color("b9552f") if i % 2 == 0 else Color("cf6a3f"))
		draw_arc(c, 11.0, PI, TAU, 10, Color("7d3f24"), 2.0)
	draw_polyline(PackedVector2Array([wall[wall.size() - 2], wall[wall.size() - 1], top[0]]), Color("c9c2b2"), 2.0)
	draw_line(top[top.size() - 1], wall[wall.size() - 2], Color("c9c2b2"), 2.0)
	_draw_stroke()
