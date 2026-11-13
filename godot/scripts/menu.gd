extends Control
## The menus (main, saves, settings, controls, how to play, credits, pause), drawn as a whitewashed Manchego wall
## capped with roof tiles, with the options painted on it and a plaque behind whichever one is selected.
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
	if sel < 0 or sel >= _items.size() or (_items[sel].get("plain", false) or _items[sel].has("meter")):
		sel = 0
		while sel < _items.size() - 1 and (_items[sel].get("plain", false) or _items[sel].has("meter")):
			sel += 1
	for c in _list.get_children():
		c.free()
	for i in range(_items.size()):
		var it: Dictionary = _items[i]
		var plain: bool = it.get("plain", false)
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
		if it.has("face"):                       # a saved game: the photo of who it is, and the label beside it
			var row := HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 16)
			row.add_child(Portrait.framed(it["face"], Vector2i(70, 86)))
			var lab := _text(int(it.get("size", 22)), INK)
			lab.text = it["text"]
			lab.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			if i == sel:
				lab.add_theme_stylebox_override("normal", _plaque(Color("f3e2b3"), 2))
			row.add_child(lab)
			_list.add_child(row)
			continue
		var l := _text(int(it.get("size", 17 if plain else 26)), Color("5a4a3a") if plain else INK)
		var t: String = it["text"]
		if it.has("value"):
			t += ":   ‹ " + String(it["value"]) + " ›"
		if capture != null and i == sel:
			t = String(it["text"]) + ":   …"
		l.text = t
		if plain:
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(640, 0)
		elif i == sel:
			l.add_theme_stylebox_override("normal", _plaque(Color("f3e2b3"), 2))
			l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_list.add_child(l)
	queue_redraw()
	_redraw_when_laid_out()

## The wall is painted round the box of text, and the box only takes its new size and place on the next frame:
## paint it again then, or the wall stays where the previous page had it until something else is pressed.
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

func _move(by: int) -> void:
	var n := _items.size()
	for step in range(n):
		sel = (sel + by + n) % n
		if not (_items[sel].get("plain", false) or _items[sel].has("meter")):
			break
	Sfx.beep(520.0, 0.04, 1, -18.0)
	rebuild()

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
	var tabs := [Color("d9643a"), Color("e6b422"), Color("5aa84f"), Color("3b5fa8"), Color("8a4fb8")]
	draw_set_transform(r.get_center(), deg_to_rad(-1.2), Vector2.ONE)
	var o := -r.size / 2.0                               # (drawn round its own middle, a touch crooked)
	draw_rect(Rect2(o + Vector2(12, 16), r.size + Vector2(8, 6)), Color(0, 0, 0, 0.32))
	draw_rect(Rect2(o + Vector2(-10, -8), r.size + Vector2(22, 16)), Color("2f5d3a"))              # the back cover
	draw_rect(Rect2(o + Vector2(-10, -8), r.size + Vector2(22, 16)), Color("1f3f27"), false, 3.0)
	for k in range(tabs.size()):                         # the tabs, sticking out of the right-hand edge
		var here := k == _tab
		var tr := Rect2(o.x + r.size.x - 4.0, o.y + 40.0 + k * 58.0, 44.0 if here else 30.0, 50.0)
		draw_rect(Rect2(tr.position + Vector2(2, 3), tr.size), Color(0, 0, 0, 0.25))
		draw_rect(tr, tabs[k] if here else tabs[k].darkened(0.18))
		draw_rect(tr, INK, false, 2.0)
		draw_string(ThemeDB.fallback_font, tr.position + Vector2(tr.size.x - 19.0, 33.0), str(k + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("fff6e0"))
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
	var r := Rect2(_box.global_position - global_position, _box.size).grow_individual(70, 46, 70, 104)
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
	var plinth := Rect2(r.position.x, r.position.y + r.size.y - 78, r.size.x, 78)
	var skirt := PackedVector2Array()                 # painted by hand: the top line wanders a little
	for i in range(steps + 1):
		skirt.append(Vector2(plinth.position.x + plinth.size.x * i / steps, plinth.position.y + sin(i * 0.9) * 1.8 + sin(i * 0.31 + 2.0) * 1.6))
	skirt.append(plinth.position + plinth.size)
	skirt.append(Vector2(plinth.position.x, plinth.position.y + plinth.size.y))
	draw_colored_polygon(skirt, Color("3f5fae"))
	draw_rect(Rect2(plinth.position.x, plinth.position.y + plinth.size.y - 14.0, plinth.size.x, 14.0), Color("36529a"))      # darker where the mop reaches
	for k in range(9):                                # scuffs: the lime shows through
		var sx := plinth.position.x + plinth.size.x * fposmod(k * 0.371 + 0.08, 1.0)
		var sy := plinth.position.y + 14.0 + fposmod(k * 23.0, 40.0)
		draw_rect(Rect2(sx, sy, 10.0 + fposmod(k * 7.0, 16.0), 3.0), Color(0.93, 0.92, 0.88, 0.5))
	# stones showing through
	for s in _stones:
		var p := Vector2(r.position.x + 24 + s[0] * (r.size.x - 48), r.position.y + 34 + s[1] * (r.size.y - 150))
		if absf(p.x - (r.position.x + r.size.x / 2)) < 290 and p.y > r.position.y + 20:
			continue                             # keep the lettering clear
		draw_set_transform(p, 0.0, Vector2(s[3], 1.0))
		draw_circle(Vector2.ZERO, s[2], Color("8a6f58"))
		draw_circle(Vector2(-1.5, -1.5), s[2] * 0.6, Color("a58a70"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
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
