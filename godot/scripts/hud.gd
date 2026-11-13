extends CanvasLayer
## All 2D interface, built in code: objective, timer, minimap, prompts, dialogue box, title cards, overlays.

const Minimap = preload("res://scripts/minimap.gd")
const Gauge = preload("res://scripts/gauge.gd")
const Bits = preload("res://scripts/hud_bits.gd")
const Portrait = preload("res://scripts/portrait.gd")
const INK := Color("4a3424")
const CREAM := Color("fff6e0")
const TERRA := Color("d9643a")
const GOLD := Color("f2b632")
const INDIGO := Color("3b5fa8")

var root: Control
var obj_tag: Label
var obj_text: Label
var timer_slot: Control
var timer_label: Label
var bottle_rects: Array = []
var counts: Label
var street_slot: Control
var street: Label
var speed_slot: Control
var speed: Label
var car_name: Label
var minimap: Control
var bigmap: Control
var prompt_slot: Control
var prompt: RichTextLabel
var toast_slot: Control
var toast_label: RichTextLabel
var limit_slot: Control                # out of town: the count-down to turn back (limite.gd)
var limit_title: Label
var limit_count: Label
var limit_sub: Label
var _toast_t := 0.0
var card_box: Control
var fx                          # what speed, nitro and a wrecked car do to the edges of the screen (hud_bits.gd ScreenFx)
var heat_arc                    # how fed up the police are: an arc over the map (hud_bits.gd HeatArc)
var obj_box: Control            # the objective, top left
var obj_slot: Control           # ...and what holds it, and the map, in their corners: both slide off the left of the
var map_slot: Control           # screen while somebody is talking or a scene is playing, and back afterwards
var stowed := 0.0               # 0 in their places .. 1 put away
const STOW := 470               # how far to the left "away" is
const MAP_SIZE := 184           # the plate of the little map, in pixels (it was 226: it took up too much of the screen)
const MAP_REACH := 95.0         # how many metres round you it shows (it was 150: closer in now)
var _day_shown := ""
var _day_t := 0.0
var street_box: Control
var _street_name := ""
var _street_tween: Tween
var phone_panel: Control
var tally: Array = []           # the counters on the slate: [icon, label] for money, saffron, Puntos Cívicos, tags
var _tally_was: Array = ["", "", "", ""]
var _tally_vals: Array = []     # the numbers it showed last (to say how much each has gone up or down)
var tally_slot: MarginContainer
var _tally_tween: Tween
const TALLY_UP := -96           # where it waits, off the top of the screen
const TALLY_DOWN := 16
var dlg_bubble: Control
var dlg_pointer                 # its tail, reaching towards whoever is talking (hud_bits.gd Pointer)
var phone_face: Control         # the caller's photo, on the screen of the phone
var _phone_who := ""
var _phone_tween: Tween
var stamp_box: Control          # the rubber stamp that comes down when an errand is done
var stamp_text: Label
var _stamp_tween: Tween
var _card_tween: Tween
var _tilts: Array = []          # [control, degrees]: boxes that hang a little crooked
var radio_box                   # the car radio's front, with the station just tuned in and what is playing (hud_bits.gd CarRadio)
var radio_slot: MarginContainer
const RADIO_IN := -130          # where the radio waits, under the bottom of the screen...
const RADIO_OUT := 12           # ...and where it comes up to, between the map and the dials
var _radio_tween: Tween
var card_title: Label
var card_sub: RichTextLabel
var dlg_slot: Control
var dlg_name: Label
var dlg_text: RichTextLabel
var dlg_key: RichTextLabel
var dlg_arrow: Control
var dlg_more: Control
var _heat_elite := -1
var dlg_ready := false       # the line on screen has been said in full: show the "go on" marker
var gauge: Control
var fade: ColorRect
var flash: ColorRect
var phone_slot: MarginContainer
var phone_name: Label
var phone_status: Label
var box_slot: Control
var box_you: ProgressBar
var box_foe: ProgressBar
var box_foe_name: Label
var box_info: Label
var overlay: Control
var ov_title: Label
var ov_logo: TextureRect
var ov_sub: Label
var ov_body: Label
var ov_foot: RichTextLabel
var play_ui: Control
var heat_bar: ProgressBar
var heat_label: Label
var heat_fill: StyleBoxFlat
var hp_bar: ProgressBar
var hp_fill: StyleBoxFlat
var bar_top: ColorRect
var bar_bottom: ColorRect
var story_box: Control
var story: Label
var story_hint: RichTextLabel
var creator_slot: Control
var creator_title: Label
var creator_text: Label
var creator_foot: Label
var creator_tabs: HBoxContainer
var creator_tab_boxes: Array = []      # [panel, label] for each page of the creator
## The creator's buttons (the user, 13 November 2026): no instructions written out; the button pictures by the page
## tabs say how to turn the page; at the foot, on Lustre "Siguiente", on Pintas "Volver" and "Así me quedo", each with
## the picture of its button; and curved arrows either side of the character, with theirs, say it can be turned.
signal creator_pick(what: String)      # a creator button clicked: "accept" | "back"
var creator_tab_l: TextureRect         # LB (on a pad) before the tabs...
var creator_tab_r: TextureRect         # ...RB (or Tab on the keyboard) after them
var creator_btns: HBoxContainer
var creator_back: Button
var creator_next: Button
var creator_turn: Control              # the arrows round the character
var creator_turn_l: Array = []         # [arrow, button picture] on each side
var creator_turn_r: Array = []
var creator_drag: TextureRect          # the mouse, dragged (keyboard and mouse only)
var _creator_page := 0
var creator_panel: Control             # the creator's panel itself (what a finger presses there is its buttons)
var _creator_grab := Rect2()            # round the character and its arrows: a finger dragged there turns it

func _ready() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	play_ui = Control.new()
	play_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	play_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(play_ui)
	fx = Bits.ScreenFx.new()               # (first: everything else is drawn over it)
	play_ui.add_child(fx)

	# objective (top left) — the tag shows the day and the scripted moment, never a clock
	var op := _skinned("calendar")         # the errand, on a leaf of a desk calendar: the day on the red band, rings along the top
	op.draw.connect(func(): Bits.rings(op))
	obj_box = op
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 4)
	obj_tag = _label(15, Color("fff6e0"))
	obj_text = _label(21, INK)
	obj_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	obj_text.custom_minimum_size = Vector2(360, 0)
	ov.add_child(obj_tag); ov.add_child(obj_text); op.add_child(ov)
	obj_slot = _slot(play_ui, op, Control.SIZE_SHRINK_BEGIN, Control.SIZE_SHRINK_BEGIN)

	# timer + bottles (top centre)
	var tp := _skinned("slate")
	var tv := VBoxContainer.new()
	timer_label = _label(46, CREAM)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 5)
	for i in range(6):
		var r := ColorRect.new()
		r.custom_minimum_size = Vector2(11, 24)
		hb.add_child(r)
		bottle_rects.append(r)
	tv.add_child(timer_label); tv.add_child(hb); tp.add_child(tv)
	timer_slot = _slot(play_ui, tp, Control.SIZE_SHRINK_CENTER, Control.SIZE_SHRINK_BEGIN)
	timer_slot.visible = false

	# counters (top right)
	var cp := _skinned("slate")            # the tally, chalked up on the bar's slate
	counts = _label(19, Color("f4f0e4"))   # (the old line of text: kept for whoever reads it, never shown)
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 6)
	for kind in ["coin", "saffron", "pc", "spray"]:
		var pic = Bits.Icon.new(kind)
		pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var num := _label(20, Color("f4f0e4"))
		num.custom_minimum_size = Vector2(34, 0)
		# "+15", "-100": how much it has just gone up or down. It hangs under the slate, outside it, big and outlined
		var change := _label(30, Color("35f06a"))
		change.add_theme_color_override("font_outline_color", Color("1a120c"))
		change.add_theme_constant_override("outline_size", 10)
		change.mouse_filter = Control.MOUSE_FILTER_IGNORE
		change.visible = false
		play_ui.add_child(change)
		th.add_child(pic)
		th.add_child(num)
		if kind != "spray":
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(8, 0)
			th.add_child(gap)
		tally.append([pic, num, change])
	cp.add_child(th)
	tally_slot = _slot(play_ui, cp, Control.SIZE_SHRINK_END, Control.SIZE_SHRINK_BEGIN, 16, TALLY_UP)

	# heat: how fed up the local police are with you. It is drawn as an arc over the map (further down); the label and
	# the bar are kept, unseen, for whoever reads them.
	heat_label = _label(15, TERRA)
	var hb1 := _bar(170, GOLD)
	heat_bar = hb1[0]
	heat_fill = hb1[1]

	# street name (bottom centre)
	var sp := _skinned("tile")             # the name of the street, on a tile like the ones on the corners
	street = _label(18, Color("1e45a8"))
	sp.add_child(street)
	street_slot = _slot(play_ui, sp, Control.SIZE_SHRINK_CENTER, Control.SIZE_SHRINK_END, 16)
	street_box = sp
	sp.modulate.a = 0.0                    # (it only comes up for a moment as you turn into a street)

	# speedometer (bottom right)
	speed = _label(40, INK)                # (kept, unseen, for whoever still sets them: the dashboard draws all of this itself)
	car_name = _label(14, TERRA)
	var hb2 := _bar(150, Color("5aa84f"))
	hp_bar = hb2[0]
	hp_fill = hb2[1]
	gauge = Gauge.new()
	speed_slot = _slot(play_ui, gauge, Control.SIZE_SHRINK_END, Control.SIZE_SHRINK_END, 10)
	speed_slot.visible = false

	# minimap (bottom left)
	# (a plate of painted ware: the map shows through a disc, turns with the camera, and the rim says where north is)
	var plate := Control.new()
	plate.custom_minimum_size = Vector2(MAP_SIZE, MAP_SIZE)
	var disc = Bits.Disc.new()
	disc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plate.add_child(disc)
	minimap = Minimap.new()
	minimap.round = true
	minimap.radius = MAP_REACH
	minimap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	disc.add_child(minimap)
	var rim = Bits.PlateRim.new()
	rim.map = minimap
	rim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plate.add_child(rim)
	heat_arc = Bits.HeatArc.new()
	heat_arc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plate.add_child(heat_arc)
	map_slot = _slot(play_ui, plate, Control.SIZE_SHRINK_BEGIN, Control.SIZE_SHRINK_END, 12)

	# prompt, toast
	# (a small brass tag that hangs by whoever or whatever it is about: over a neighbour's head, under your own car)
	var pp := PanelContainer.new()
	var tag: StyleBoxTexture = _skin("gold").duplicate()
	tag.content_margin_left = 11; tag.content_margin_right = 11; tag.content_margin_top = 3; tag.content_margin_bottom = 10
	pp.add_theme_stylebox_override("panel", tag)
	pp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt = _rich(15, INK)
	pp.add_child(prompt)
	play_ui.add_child(pp)
	prompt_slot = pp
	prompt_slot.visible = false
	var top := _skinned("clay")
	toast_label = _rich(21, Color.WHITE)
	top.add_child(toast_label)
	toast_slot = _slot(play_ui, top, Control.SIZE_SHRINK_CENTER, Control.SIZE_SHRINK_BEGIN, 16, 118)
	toast_slot.visible = false
	# out of town: TURN BACK and the seconds left, big and red (limite.gd)
	var lim := VBoxContainer.new()
	lim.add_theme_constant_override("separation", -6)
	limit_title = _label(34, Color("ff3b30"))
	limit_count = _label(92, Color("ff3b30"))
	limit_sub = _label(19, Color.WHITE)
	for l in [limit_title, limit_count, limit_sub]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_constant_override("outline_size", 12)
		l.add_theme_color_override("font_outline_color", Color(0.08, 0.02, 0.02, 0.85))
		lim.add_child(l)
	limit_slot = _slot(play_ui, lim, Control.SIZE_SHRINK_CENTER, Control.SIZE_SHRINK_BEGIN, 16, 190)
	limit_slot.visible = false

	# the car radio: when you change station (or the tune changes) the front of the radio slides up out of the bottom of
	# the screen, between the map and the dials, for a few seconds: the station's logo, who is playing and what. Then it
	# goes back down. Everything else about the stations is in the Agenda.
	radio_box = Bits.CarRadio.new()
	radio_slot = _slot(play_ui, radio_box, Control.SIZE_SHRINK_CENTER, Control.SIZE_SHRINK_END, RADIO_IN)
	radio_box.modulate.a = 0.0

	# the mobile phone: slides up from the bottom when somebody rings. All screen, a thin dark rim, three buttons under it.
	var ph := PanelContainer.new()
	var body := StyleBoxFlat.new()
	body.bg_color = Color("17181c")
	body.border_color = Color("3d4048")
	body.set_border_width_all(2)
	body.set_corner_radius_all(26)
	body.content_margin_left = 8; body.content_margin_right = 8; body.content_margin_top = 9; body.content_margin_bottom = 7
	body.shadow_color = Color(0, 0, 0, 0.4)
	body.shadow_size = 8
	body.shadow_offset = Vector2(2, 6)
	ph.add_theme_stylebox_override("panel", body)
	phone_panel = ph
	var phv := VBoxContainer.new()
	phv.add_theme_constant_override("separation", 5)
	var screen := PanelContainer.new()
	var glass := StyleBoxFlat.new()
	glass.bg_color = Color("243b52")               # a wallpaper of evening sky
	glass.set_corner_radius_all(19)
	glass.content_margin_left = 8; glass.content_margin_right = 8; glass.content_margin_top = 4; glass.content_margin_bottom = 12
	screen.add_theme_stylebox_override("panel", glass)
	var scv := VBoxContainer.new()
	scv.add_theme_constant_override("separation", 5)
	scv.add_child(Bits.StatusBar.new())
	phone_face = Control.new()
	phone_face.custom_minimum_size = Vector2(158, 176)
	phone_face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	phone_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	phone_name = _label(22, Color.WHITE)
	phone_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phone_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	phone_name.custom_minimum_size = Vector2(150, 0)
	phone_status = _label(13, Color("8fe3a4"))
	phone_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scv.add_child(phone_face); scv.add_child(phone_name); scv.add_child(phone_status); screen.add_child(scv)
	phv.add_child(screen)
	var nav = Bits.NavKeys.new()
	nav.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	phv.add_child(nav)
	ph.add_child(phv)
	phone_slot = _slot(play_ui, ph, Control.SIZE_SHRINK_END, Control.SIZE_SHRINK_END, -420)
	phone_slot.add_theme_constant_override("margin_right", 16)

	# boxing: your bar and his
	var bx := _skinned("paper")
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 14)
	var you := _label(17, INK)
	you.text = "TÚ"
	var b1 := _bar(230, Color("5aa84f"))
	box_you = b1[0]
	box_you.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var vs := _label(19, TERRA)
	vs.text = "VS"
	var b2 := _bar(230, Color("e23b3b"))
	box_foe = b2[0]
	box_foe.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box_foe.fill_mode = ProgressBar.FILL_END_TO_BEGIN
	box_foe_name = _label(17, INK)
	for c in [you, box_you, vs, box_foe, box_foe_name]:
		bh.add_child(c)
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 4)
	box_info = _label(15, TERRA)
	box_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bv.add_child(box_info)
	bv.add_child(bh)
	bx.add_child(bv)
	box_slot = _slot(play_ui, bx, Control.SIZE_SHRINK_CENTER, Control.SIZE_SHRINK_BEGIN, 16, 132)
	box_slot.visible = false

	# moment / mission card
	card_box = _skinned("poster")
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", -2)
	card_sub = _rich(19, TERRA)
	card_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_title = _label(40, INK)
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var rule := ColorRect.new()                # a printer's rule between the two
	rule.color = Color(0.29, 0.2, 0.14, 0.55)
	rule.custom_minimum_size = Vector2(120, 2)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cv.add_child(card_sub); cv.add_child(rule); cv.add_child(card_title)
	card_box.add_child(cv)
	_slot(play_ui, card_box, Control.SIZE_SHRINK_CENTER, Control.SIZE_SHRINK_BEGIN, 16, 150)
	_tilts.append([card_box, -2.5])
	card_box.modulate.a = 0.0

	# the stamp: comes down in the middle of the screen when an errand is done
	stamp_box = PanelContainer.new()
	var outer := StyleBoxFlat.new()
	outer.bg_color = Color(0.78, 0.1, 0.1, 0.06)
	outer.border_color = Color(0.78, 0.1, 0.1, 0.9)
	outer.set_border_width_all(7)
	outer.set_corner_radius_all(14)
	outer.set_content_margin_all(9)
	stamp_box.add_theme_stylebox_override("panel", outer)
	var inner_p := PanelContainer.new()
	var inner := StyleBoxFlat.new()
	inner.bg_color = Color(0, 0, 0, 0)
	inner.border_color = Color(0.78, 0.1, 0.1, 0.9)
	inner.set_border_width_all(2)
	inner.set_corner_radius_all(8)
	inner.content_margin_left = 26; inner.content_margin_right = 26; inner.content_margin_top = 0; inner.content_margin_bottom = 4
	inner_p.add_theme_stylebox_override("panel", inner)
	stamp_text = _label(70, Color(0.78, 0.1, 0.1, 0.92))
	inner_p.add_child(stamp_text)
	stamp_box.add_child(inner_p)
	_slot(play_ui, stamp_box, Control.SIZE_SHRINK_CENTER, Control.SIZE_SHRINK_CENTER, 16, 150)
	_tilts.append([stamp_box, -10.0])
	stamp_box.modulate.a = 0.0

	# dialogue box
	var dp := _skinned("bubble")               # a bubble; its tail (below) points at whoever is talking
	dp.custom_minimum_size = Vector2(780, 140)
	dlg_bubble = dp
	var dv := VBoxContainer.new()
	dlg_name = _label(22, TERRA)
	dlg_text = RichTextLabel.new()          # rich text, so names can be picked out in colour
	dlg_text.bbcode_enabled = true
	dlg_text.scroll_active = false
	dlg_text.fit_content = true
	dlg_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dlg_text.add_theme_font_size_override("normal_font_size", 25)
	dlg_text.add_theme_color_override("default_color", INK)
	dlg_text.custom_minimum_size = Vector2(730, 74)
	dv.add_child(dlg_name); dv.add_child(dlg_text)
	# "go on": the button to press and an arrow that bobs, once the line has been said in full
	var more := HBoxContainer.new()
	more.alignment = BoxContainer.ALIGNMENT_END
	more.add_theme_constant_override("separation", 8)
	dlg_key = _rich(16, TERRA)
	dlg_arrow = Control.new()
	dlg_arrow.custom_minimum_size = Vector2(20, 16)
	dlg_arrow.draw.connect(func():
		var bob := sin(Time.get_ticks_msec() / 140.0) * 3.0
		dlg_arrow.draw_colored_polygon(PackedVector2Array([Vector2(2, 3 + bob), Vector2(18, 3 + bob), Vector2(10, 13 + bob)]), TERRA))
	more.add_child(dlg_key); more.add_child(dlg_arrow)
	dlg_more = more
	dv.add_child(more)
	dp.add_child(dv)
	# cinematic black bars (cutscenes); the dialogue box sits above them and outside play_ui so it works in cutscenes too
	bar_top = ColorRect.new()
	bar_top.color = Color.BLACK
	bar_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar_top)
	bar_bottom = ColorRect.new()
	bar_bottom.color = Color.BLACK
	bar_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar_bottom)
	dlg_slot = _slot(root, dp, Control.SIZE_SHRINK_CENTER, Control.SIZE_SHRINK_END, DLG_MARGIN)
	dlg_pointer = Bits.Pointer.new()
	dlg_pointer.bubble = dp
	dlg_slot.add_child(dlg_pointer)            # (inside the slot: shown and hidden with the bubble, drawn over its edge)
	dlg_pointer.top_level = true
	dlg_slot.visible = false

	# big map
	bigmap = Minimap.new()
	bigmap.full = true
	bigmap.set_anchors_preset(Control.PRESET_FULL_RECT)
	bigmap.offset_left = 70; bigmap.offset_right = -70; bigmap.offset_top = 50; bigmap.offset_bottom = -50
	bigmap.visible = false
	root.add_child(bigmap)

	# fade to black (sleep) and the generic centre overlay (title, pause, fail, end of day)
	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.modulate.a = 0.0
	root.add_child(fade)
	# story text on black (prologue)
	story_box = VBoxContainer.new()
	story_box.add_theme_constant_override("separation", 30)
	story = _label(30, Color("fff6e0"))
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.custom_minimum_size = Vector2(820, 0)
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_hint = _rich(18, GOLD)
	story_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_box.add_child(story); story_box.add_child(story_hint)
	_slot(root, story_box, Control.SIZE_SHRINK_CENTER, Control.SIZE_SHRINK_CENTER)
	story_box.visible = false

	# character creation panel (right-hand side)
	var crp := _panel(CREAM, 30, 4)
	creator_panel = crp
	var crv := VBoxContainer.new()
	crv.add_theme_constant_override("separation", 10)
	creator_title = _label(28, TERRA)
	creator_text = _label(18, INK)
	creator_foot = _label(15, TERRA)
	creator_foot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	creator_foot.custom_minimum_size = Vector2(300, 0)
	creator_tabs = HBoxContainer.new()             # the two pages, as the tabs of a folder: the one you are on stands out
	creator_tabs.add_theme_constant_override("separation", 5)
	creator_tabs.size_flags_vertical = Control.SIZE_SHRINK_END
	creator_tab_l = _icon_rect(30)
	creator_tab_r = _icon_rect(30)
	creator_tabs.add_child(creator_tab_l)
	creator_tabs.add_child(creator_tab_r)
	creator_foot.visible = false
	creator_btns = HBoxContainer.new()
	creator_btns.add_theme_constant_override("separation", 12)
	creator_btns.alignment = BoxContainer.ALIGNMENT_END
	creator_back = _creator_button(false)
	creator_next = _creator_button(true)
	creator_back.pressed.connect(func(): creator_pick.emit("back"))
	creator_next.pressed.connect(func(): creator_pick.emit("accept"))
	creator_btns.add_child(creator_back)
	creator_btns.add_child(creator_next)
	crv.add_child(creator_title); crv.add_child(creator_tabs); crv.add_child(creator_text); crv.add_child(creator_foot); crv.add_child(creator_btns)
	crp.add_child(crv)
	creator_turn = Control.new()
	creator_turn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	creator_turn.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		var arrow := TextureRect.new()
		arrow.texture = load(Controls.ICONS + "rot_%s.png" % side)
		arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		arrow.size = Vector2(84, 56)
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var key := _icon_rect(34)
		creator_turn.add_child(arrow)
		creator_turn.add_child(key)
		if side == "left":
			creator_turn_l = [arrow, key]
		else:
			creator_turn_r = [arrow, key]
	creator_drag = _icon_rect(34)
	creator_turn.add_child(creator_drag)
	creator_turn.visible = false
	root.add_child(creator_turn)
	creator_slot = _slot(root, crp, Control.SIZE_SHRINK_END, Control.SIZE_SHRINK_CENTER)
	creator_slot.add_theme_constant_override("margin_right", 28)
	creator_slot.visible = false

	flash = ColorRect.new()                 # a white flash (the title appearing)
	flash.color = Color.WHITE
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.modulate.a = 0.0
	root.add_child(flash)
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dim := ColorRect.new()
	dim.color = Color(0.24, 0.16, 0.1, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var pan := _panel(CREAM, 34, 5)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	ov_logo = TextureRect.new()
	ov_logo.texture = preload("res://scripts/parts.gd").texture("res://assets/logo.png")
	ov_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ov_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ov_logo.custom_minimum_size = Vector2(84, 84)
	ov_logo.visible = false
	vb.add_child(ov_logo)
	ov_title = _label(64, TERRA)
	ov_title.add_theme_color_override("font_outline_color", INK)
	ov_title.add_theme_constant_override("outline_size", 10)
	ov_sub = _label(24, INK)
	ov_body = _label(17, INK)
	ov_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ov_body.custom_minimum_size = Vector2(660, 0)
	ov_foot = _rich(22, TERRA)
	for l in [ov_title, ov_sub, ov_body, ov_foot]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(l)
	pan.add_child(vb)
	_slot(overlay, pan, Control.SIZE_SHRINK_CENTER, Control.SIZE_SHRINK_CENTER)
	overlay.visible = false
	root.add_child(overlay)

# ---------------- skins: what the boxes of the HUD are made of ----------------
# Painted here, pixel by pixel, once: a sheet of wrapping paper, a bar's slate in its wooden frame, a glazed street
# tile, fired clay. Each is a small picture stretched by its middle (a nine-patch), with its own shadow under it.
var _skins := {}

func _skin(kind: String) -> StyleBoxTexture:
	if _skins.has(kind):
		return _skins[kind]
	var n := 72
	var img := Image.create(n, n + 6, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	var rad := 9.0 if kind == "slate" else (6.0 if kind in ["tile", "poster", "photo"] else (20.0 if kind == "bubble" else (8.0 if kind == "calendar" else 14.0)))
	for y in range(n + 6):
		for x in range(n):
			var px := Vector2(x + 0.5, y + 0.5)
			var q := (px - Vector2(n, n) / 2.0).abs() - (Vector2(n, n) / 2.0 - Vector2(rad, rad))
			var d := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - rad      # < 0 inside the rounded box
			var qs := (px - Vector2(n, n) / 2.0 - Vector2(1.5, 5.0)).abs() - (Vector2(n, n) / 2.0 - Vector2(rad, rad))
			var ds := Vector2(maxf(qs.x, 0.0), maxf(qs.y, 0.0)).length() + minf(maxf(qs.x, qs.y), 0.0) - rad
			var col := Color(0.16, 0.1, 0.06, 0.34 * clampf(-ds / 3.0 + 0.3, 0.0, 1.0))                   # the shadow it throws
			if d < 0.0:
				var grain := rng.randf()
				var edge := -d                               # how far in from the rim
				match kind:
					"paper":            # wrapping paper: fibres, a soft fold of light, an inked rim and a faint second line
						col = Color(1.0, 0.962, 0.875, 0.95).darkened(grain * 0.045 + (0.05 if rng.randf() < 0.03 else 0.0))
						col = col.lightened(clampf(0.5 - px.y / n, 0.0, 1.0) * 0.06)
						if edge < 2.6:
							col = Color(0.29, 0.2, 0.14, 1.0)
						elif edge > 5.0 and edge < 5.9:
							col = col.darkened(0.2)
					"slate":            # the bar's slate: grey-green stone with chalk dust, in a wooden frame
						col = Color(0.13, 0.17, 0.16, 0.95).lightened(grain * 0.05 + (0.1 if rng.randf() < 0.02 else 0.0))
						if edge < 5.5:
							col = Color(0.5, 0.33, 0.18, 1.0).darkened(0.12 * sin(px.x * 0.9 + px.y * 0.25) + grain * 0.08)
							if edge < 1.0 or edge > 4.7:
								col = col.darkened(0.3)
					"tile":             # a street-name tile: white glaze, cobalt rim and inner line, a shine across it
						col = Color(0.97, 0.97, 0.94, 0.98).darkened(grain * 0.02)
						col = col.lightened(0.5 * clampf(1.0 - absf((px.x + px.y) - n * 0.55) / 7.0, 0.0, 1.0))
						if edge < 4.0:
							col = Color(0.12, 0.27, 0.66, 1.0).lightened(grain * 0.06)
						elif edge > 6.0 and edge < 7.2:
							col = Color(0.12, 0.27, 0.66, 1.0)
					"clay":             # fired clay, for what the game tells you
						col = Color(0.85, 0.39, 0.23, 0.96).darkened(grain * 0.06)
						col = col.lightened(clampf(0.45 - px.y / n, 0.0, 1.0) * 0.16)
						if edge < 2.4:
							col = Color(0.42, 0.17, 0.09, 1.0)
					"calendar":         # a leaf of a desk calendar: a red band along the top (the day goes there), paper under it
						col = Color(1.0, 0.962, 0.875, 0.96).darkened(grain * 0.045)
						if px.y < 33.0:
							col = Color(0.78, 0.2, 0.15, 0.98).darkened(grain * 0.07)
						elif px.y < 35.0:
							col = Color(0.29, 0.2, 0.14, 0.9)
						if edge < 2.6:
							col = Color(0.29, 0.2, 0.14, 1.0)
					"bubble":           # a speech bubble out of a tebeo: paper white, a fat ink line
						col = Color(1.0, 0.992, 0.955, 0.97).darkened(grain * 0.015)
						if edge < 3.2:
							col = Color(0.29, 0.2, 0.14, 1.0)
					"photo":            # a passport photo: white card, a hairline, the corner lifting a little
						col = Color(0.985, 0.98, 0.96, 1.0).darkened(grain * 0.02)
						if edge < 1.2:
							col = Color(0.55, 0.5, 0.45, 1.0)
					"poster":           # a fiestas poster: cream paper, a band of colour top and bottom, tape on the corners
						col = Color(1.0, 0.955, 0.84, 0.98).darkened(grain * 0.05)
						if px.y < 15.0 or px.y > n - 9.0:
							col = Color(0.8, 0.22, 0.16, 1.0).darkened(grain * 0.08)
						elif px.y < 18.0 or px.y > n - 12.0:
							col = Color(0.95, 0.72, 0.2, 1.0)
						if edge < 1.6:
							col = Color(0.29, 0.2, 0.14, 1.0)
						var tape := minf(absf((px.x + px.y) - 16.0), absf((n - px.x + px.y) - 16.0))      # across the two top corners
						if tape < 5.5:
							col = Color(0.93, 0.9, 0.7, 0.82).darkened(grain * 0.06)
					"gold":             # a brass tag, for the key to press
						col = Color(0.96, 0.72, 0.2, 0.97).darkened(grain * 0.04)
						col = col.lightened(clampf(0.5 - px.y / n, 0.0, 1.0) * 0.3)
						if edge < 2.4:
							col = Color(0.29, 0.2, 0.14, 1.0)
				if edge < 1.0:
					col.a *= clampf(edge + 0.2, 0.0, 1.0)        # soften the outline
			img.set_pixel(x, y, col)
	var sb := StyleBoxTexture.new()
	sb.texture = ImageTexture.create_from_image(img)
	var m := 22.0
	sb.texture_margin_left = m; sb.texture_margin_right = m; sb.texture_margin_top = m; sb.texture_margin_bottom = m + 6.0
	sb.content_margin_left = 18; sb.content_margin_right = 18; sb.content_margin_top = 8; sb.content_margin_bottom = 15
	if kind == "slate":
		sb.content_margin_top = 10; sb.content_margin_bottom = 17
	elif kind == "poster":
		sb.content_margin_top = 22; sb.content_margin_bottom = 20; sb.content_margin_left = 34; sb.content_margin_right = 34
	elif kind == "photo":
		sb.content_margin_left = 6; sb.content_margin_right = 6; sb.content_margin_top = 6; sb.content_margin_bottom = 12
	elif kind == "bubble":
		sb.content_margin_left = 22; sb.content_margin_right = 22; sb.content_margin_top = 12; sb.content_margin_bottom = 16
		sb.modulate_color = Color(1, 1, 1, 0.9)        # the box, not what is written in it
	elif kind == "calendar":
		sb.texture_margin_top = 36.0
		sb.content_margin_top = 13; sb.content_margin_bottom = 14
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	_skins[kind] = sb
	return sb

## a box made of one of those
func _skinned(kind: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _skin(kind))
	return p

func _panel(bg: Color, radius := 18, border := 3, border_col := INK) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border_col
	sb.set_border_width_all(border)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 18; sb.content_margin_right = 18; sb.content_margin_top = 6; sb.content_margin_bottom = 8
	sb.shadow_color = Color(0.29, 0.2, 0.14, 0.35)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(0, 4)
	p.add_theme_stylebox_override("panel", sb)
	return p

## A line of text that can carry the pictures of buttons (Controls.fill): it sizes itself to what it says, like a Label.
func _rich(font_size: int, color: Color) -> RichTextLabel:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("normal_font_size", font_size)
	l.add_theme_color_override("default_color", color)
	l.set_meta("font", font_size)
	return l

## puts a text with buttons in it into a rich line, the pictures as tall as its letters call for
func rt(l: RichTextLabel, text: String) -> void:
	var t := as_shown(l, text)
	if l.text != t:
		l.text = t

## the text as that line shows it (its pictures resized)
func as_shown(l: RichTextLabel, text: String) -> String:
	var h := int(round(float(l.get_meta("font", 18)) * 1.45))
	return text.replace("[img height=%d]" % Controls.ICON_H, "[img height=%d]" % h)

func _label(font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

## puts a widget in a full-screen margin wrapper so it hugs a corner/edge and resizes with its content
func _slot(parent: Control, w: Control, hflag: int, vflag: int, margin_bottom := 16, margin_top := 16) -> Control:
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top", margin_top)
	m.add_theme_constant_override("margin_bottom", margin_bottom)
	w.size_flags_horizontal = hflag
	w.size_flags_vertical = vflag
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(w)
	parent.add_child(m)
	return m

func _bar(width: int, fill_col: Color) -> Array:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.max_value = 1.0
	b.custom_minimum_size = Vector2(width, 12)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.29, 0.2, 0.14, 0.25)
	bg.set_corner_radius_all(6)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_col
	fill.set_corner_radius_all(6)
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fill)
	return [b, fill]

func set_heat(heat: float, chasing: bool, t: float, elite := false) -> void:
	if _heat_elite != int(elite):
		_heat_elite = int(elite)
		heat_label.text = Loc.t("heat_elite") if elite else Loc.t("heat")
		heat_label.add_theme_color_override("font_color", Color("2f8f55") if elite else Color("2f6bff"))
	heat_bar.value = heat / 100.0
	heat_arc.heat = heat / 100.0
	heat_arc.chasing = chasing
	heat_arc.elite = elite
	heat_fill.bg_color = (Color("2f6bff") if int(t * 5.0) % 2 == 0 else Color("e23b3b")) if chasing else GOLD

## where on the screen the tail of the bubble should point (Vector2), or null for a voice from nowhere
func set_dlg_point(at) -> void:
	dlg_pointer.at = at

## where the bubble points while you are on the phone: at the side of the phone if it stands beside the bubble, at its
## foot if it is up above
func phone_point() -> Vector2:
	if phone_panel.global_position.y + phone_panel.size.y < dlg_bubble.global_position.y:
		return phone_panel.global_position + Vector2(phone_panel.size.x / 2.0, phone_panel.size.y - 22.0)
	return phone_panel.global_position + Vector2(24.0, phone_panel.size.y * 0.72)

## The tally on the slate. It waits off the top of the screen; when a number changes it comes down, says by how much
## (green for more, red for less), stays a few seconds and goes back up.
## (`pc` below zero: nobody has told you about Puntos Cívicos yet, and their place on the slate stays empty)
func set_counts(money: int, saffron: int, pc: int, mine: int, walls: int) -> void:
	var vals := [money, saffron, maxi(pc, 0), mine]
	var now := ["%d €" % money, str(saffron), str(maxi(pc, 0)), "%d/%d" % [mine, walls]]
	tally[2][0].visible = pc >= 0
	tally[2][1].visible = pc >= 0
	var first: bool = _tally_vals.is_empty()
	var moved := false
	for i in range(4):
		var num: Label = tally[i][1]
		num.text = now[i]
		_tally_was[i] = now[i]
		if first or vals[i] == _tally_vals[i]:
			continue
		moved = true
		var by: int = vals[i] - int(_tally_vals[i])
		var change: Label = tally[i][2]
		change.text = ("+%d" % by) if by > 0 else ("−%d" % -by)
		change.add_theme_color_override("font_color", Color("35f06a") if by > 0 else Color("ff3b30"))
		change.visible = true
		change.reset_size()
		change.pivot_offset = change.size / 2.0
		change.scale = Vector2(1.8, 1.8)               # it lands with a bounce
		var pop := change.create_tween()
		pop.tween_property(change, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if is_inside_tree():
			for part in [tally[i][0], num]:
				var c: Control = part
				c.pivot_offset = c.size / 2.0
				var tw := c.create_tween()
				tw.tween_property(c, "scale", Vector2(1.5, 1.5), 0.08)
				tw.tween_property(c, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tally_vals = vals
	if not moved or not is_inside_tree():
		return
	if _tally_tween != null:
		_tally_tween.kill()
	var from: int = tally_slot.get_theme_constant("margin_top")
	_tally_tween = create_tween()
	_tally_tween.tween_method(_tally_at, float(from), float(TALLY_DOWN), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tally_tween.tween_interval(3.2)
	_tally_tween.tween_method(_tally_at, float(TALLY_DOWN), float(TALLY_UP), 0.4).set_ease(Tween.EASE_IN)
	_tally_tween.tween_callback(func():
		for entry in tally:
			entry[2].visible = false)

func _tally_at(y: float) -> void:
	tally_slot.add_theme_constant_override("margin_top", int(y))

func set_hp(frac: float) -> void:
	gauge.hp = frac
	hp_bar.value = frac
	hp_fill.bg_color = Color("5aa84f") if frac > 0.5 else (Color("e8a23a") if frac > 0.25 else Color("e23b3b"))

func _process(dt: float) -> void:
	for entry in tally:                           # the amounts just added or taken away hang under their own number
		var change: Label = entry[2]
		if change.visible:
			var pic: Control = entry[0]
			var num: Control = entry[1]
			var box: Control = tally_slot.get_child(0)
			var mid: float = (pic.global_position.x + num.global_position.x + num.size.x) / 2.0
			change.global_position = Vector2(mid - change.size.x / 2.0, box.global_position.y + box.size.y - 2.0)
	# While somebody is talking, or a scene is playing between its black bars, the map and the errand are of no use and
	# only take up room: off the screen they go, to the left, and back when it is over.
	var away: bool = dlg_slot.visible or bar_top.offset_bottom > 1.0
	var was := stowed
	stowed = move_toward(stowed, 1.0 if away else 0.0, dt * 3.5)
	if stowed != was:
		var eased := stowed * stowed * (3.0 - 2.0 * stowed)
		for slot in [obj_slot, map_slot]:
			slot.add_theme_constant_override("margin_left", 16 - int(eased * STOW))
	# The leaf of the calendar is there while there is an errand on it. With nothing to do it is put away, and comes
	# out for a few seconds whenever the day moves on (a new morning, noon, evening...), to say so.
	var errand: bool = obj_text.text != ""
	if obj_text.visible != errand:
		obj_text.visible = errand
	if obj_tag.text != _day_shown:
		_day_shown = obj_tag.text
		_day_t = 4.0
	_day_t = maxf(0.0, _day_t - dt)
	obj_box.modulate.a = move_toward(obj_box.modulate.a, 1.0 if (errand or _day_t > 0.0) else 0.0, dt * 2.5)
	for tilt in _tilts:
		var c: Control = tilt[0]
		if not is_equal_approx(c.rotation_degrees, tilt[1]):
			c.pivot_offset = c.size / 2.0
			c.rotation_degrees = tilt[1]
	if dlg_slot.visible:
		dlg_more.modulate.a = 1.0 if dlg_ready else 0.0
		var key_text: String = Loc.t("dlg_next")
		rt(dlg_key, key_text)
		dlg_arrow.queue_redraw()
	if story_box.visible:                        # the same for the story cards: the hint breathes
		story_hint.modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() / 260.0)
	if _toast_t > 0.0:
		_toast_t -= dt
		if _toast_t <= 0.0:
			toast_slot.visible = false

func set_objective(tag: String, text: String) -> void:
	obj_tag.text = tag
	obj_text.text = text

## the name of the street you have just turned into: up for a moment, then gone
func show_street(name: String) -> void:
	if name == _street_name:
		return
	_street_name = name
	if name == "":
		return
	street.text = name
	if _street_tween != null:
		_street_tween.kill()
	_street_tween = create_tween()
	_street_tween.tween_property(street_box, "modulate:a", 1.0, 0.25)
	_street_tween.tween_interval(2.6)
	_street_tween.tween_property(street_box, "modulate:a", 0.0, 0.8)

func set_bottles(n: int) -> void:
	for i in range(bottle_rects.size()):
		bottle_rects[i].color = Color("d8c53a") if i < n else Color(1, 1, 1, 0.18)

## out of town: turn back, `left` seconds to go
func show_limit(left: float) -> void:
	limit_title.text = Loc.t("limit_title")
	limit_sub.text = Loc.t("limit_sub")
	limit_count.text = str(maxi(0, int(ceil(left))))
	limit_count.modulate.a = 0.7 + 0.3 * sin(Time.get_ticks_msec() / 110.0)
	limit_slot.visible = true

func hide_limit() -> void:
	limit_slot.visible = false

func toast(text: String, dur := 3.0) -> void:
	rt(toast_label, text)
	toast_slot.visible = true
	_toast_t = dur

## the station just tuned in ({} = the radio has been switched off: the card goes away)
func radio_card(st: Dictionary) -> void:
	if _radio_tween != null:
		_radio_tween.kill()
	_radio_tween = create_tween()
	var from: int = radio_slot.get_theme_constant("margin_bottom")
	if st.is_empty():
		_radio_tween.tween_method(_radio_at, float(from), float(RADIO_IN), 0.25).set_ease(Tween.EASE_IN)
		_radio_tween.tween_property(radio_box, "modulate:a", 0.0, 0.05)
		return
	var song: Array = Ambience.playing(st)
	var number: int = Ambience.stations.find(st) + 1
	if song[1] == "":                             # nothing with a name playing: the station's own, then
		radio_box.tune(st.get("logo"), String(st.get("name", "")), "", number, Ambience.stations.size())
	else:
		radio_box.tune(st.get("logo"), String(song[0]) if song[0] != "" else String(st.get("name", "")), String(song[1]), number, Ambience.stations.size())
	radio_box.modulate.a = 1.0
	_radio_tween.tween_method(_radio_at, float(from), float(RADIO_OUT), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_radio_tween.tween_interval(4.0)
	_radio_tween.tween_method(_radio_at, float(RADIO_OUT), float(RADIO_IN), 0.4).set_ease(Tween.EASE_IN)
	_radio_tween.tween_property(radio_box, "modulate:a", 0.0, 0.05)

## how far out of the bottom of the screen the radio is (the street's name keeps above it)
func _radio_at(y: float) -> void:
	radio_slot.add_theme_constant_override("margin_bottom", int(y))
	street_slot.add_theme_constant_override("margin_bottom", maxi(16, int(y) + int(radio_box.SIZE.y) + 10))

## `at`: where on the screen the thing it is about is (null: nowhere in particular, so bottom centre);
## `below`: hang under that spot (your own feet, your own car) instead of over it (somebody's head)
func set_prompt(text: String, at = null, below := false) -> void:
	var was: bool = prompt_slot.visible
	prompt_slot.visible = text != ""
	var before := prompt.text
	rt(prompt, text)
	if prompt.text != before:
		prompt_slot.reset_size()
	if text == "":
		return
	var screen: Vector2 = root.size
	var size: Vector2 = prompt_slot.size
	var want: Vector2
	if at == null:
		want = Vector2(screen.x / 2.0 - size.x / 2.0, screen.y - 150.0)
	elif below:
		want = (at as Vector2) + Vector2(-size.x / 2.0, 30.0)
	else:
		want = (at as Vector2) + Vector2(-size.x / 2.0, -size.y - 4.0)
	want.x = clampf(want.x, 10.0, screen.x - size.x - 10.0)
	want.y = clampf(want.y, 10.0, screen.y - size.y - 60.0)
	prompt_slot.position = want if not was else prompt_slot.position.lerp(want, 0.35)      # it follows without trembling

func show_card(title: String, sub: String) -> void:
	card_title.text = title
	rt(card_sub, sub)
	card_sub.visible = sub != ""                 # (a mission's card is its title and nothing else: the day is in the corner)
	if _card_tween != null:
		_card_tween.kill()
	card_box.pivot_offset = card_box.size / 2.0
	card_box.scale = Vector2(1.7, 1.7)
	card_box.modulate.a = 0.0
	_card_tween = create_tween()               # slapped up on the wall, a little crooked; a few seconds, and it is gone
	_card_tween.tween_property(card_box, "modulate:a", 1.0, 0.16)
	_card_tween.parallel().tween_property(card_box, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_card_tween.tween_interval(3.2)
	_card_tween.tween_property(card_box, "modulate:a", 0.0, 0.6)
	_card_tween.parallel().tween_property(card_box, "scale", Vector2(0.92, 0.92), 0.6)

## thump: the rubber stamp
func stamp(text: String) -> void:
	stamp_text.text = text
	if _stamp_tween != null:
		_stamp_tween.kill()
	stamp_box.pivot_offset = stamp_box.size / 2.0
	stamp_box.scale = Vector2(3.2, 3.2)
	stamp_box.modulate.a = 0.0
	_stamp_tween = create_tween()
	_stamp_tween.tween_property(stamp_box, "modulate:a", 1.0, 0.1)
	_stamp_tween.parallel().tween_property(stamp_box, "scale", Vector2.ONE, 0.16).set_ease(Tween.EASE_IN)
	_stamp_tween.tween_callback(func():
		Sfx.noise(0.14, -5.0)
		Sfx.beep(110.0, 0.12, 0, -8.0))
	_stamp_tween.tween_property(stamp_box, "scale", Vector2(1.08, 1.08), 0.05)
	_stamp_tween.tween_property(stamp_box, "scale", Vector2.ONE, 0.08)
	_stamp_tween.tween_interval(1.7)
	_stamp_tween.tween_property(stamp_box, "modulate:a", 0.0, 0.5)

func show_overlay(title: String, sub: String, body: String, foot: String, title_size := 64) -> void:
	ov_title.text = title
	ov_title.add_theme_font_size_override("font_size", title_size)
	ov_sub.text = sub
	ov_sub.visible = sub != ""
	ov_body.text = body
	rt(ov_foot, foot)
	overlay.visible = true

func hide_overlay() -> void:
	overlay.visible = false

const CINE_BAR := 92.0
const DLG_MARGIN := 56

func cine(on: bool) -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(bar_top, "offset_bottom", CINE_BAR if on else 0.0, 0.6)
	tw.tween_property(bar_bottom, "offset_top", -CINE_BAR if on else 0.0, 0.6)
	# the speech bubble rises clear of the bottom bar while it is down, and goes back after (it was sitting on the bar:
	# the user, 13 November 2026)
	var from := dlg_slot.get_theme_constant("margin_bottom")
	var to := int(CINE_BAR) + 14 if on else DLG_MARGIN
	tw.tween_method(func(v: float): dlg_slot.add_theme_constant_override("margin_bottom", int(v)), float(from), float(to), 0.6)

## the space the speech bubble keeps below it just now (more while the cinema bars are down)
func dlg_margin() -> int:
	return dlg_slot.get_theme_constant("margin_bottom")

func show_story(text: String, hint: String) -> void:
	story.text = text
	rt(story_hint, hint)
	story_box.visible = true
	story_box.modulate.a = 0.0
	create_tween().tween_property(story_box, "modulate:a", 1.0, 0.5)

func hide_story() -> void:
	story_box.visible = false

func show_creator(title: String, text: String, foot: String, tabs: Array = [], tab := 0, on_tabs := false) -> void:
	while creator_tab_boxes.size() < tabs.size():
		var box := PanelContainer.new()
		box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN       # (two small tabs at the head of the list: together about half its width)
		var lab := _label(16, INK)
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(lab)
		creator_tabs.add_child(box)
		creator_tab_boxes.append([box, lab])
	for i in range(creator_tab_boxes.size()):
		var here := i == tab
		var sb := StyleBoxFlat.new()
		sb.bg_color = TERRA if here else Color(0.86, 0.8, 0.68)
		sb.set_corner_radius_all(0)
		sb.corner_radius_top_left = 10
		sb.corner_radius_top_right = 10
		sb.border_color = GOLD if (here and on_tabs) else Color(0.35, 0.25, 0.18)
		sb.set_border_width_all(3 if (here and on_tabs) else 2)
		sb.border_width_bottom = 0 if here else 2
		sb.content_margin_left = 12; sb.content_margin_right = 12
		sb.content_margin_top = 4 if here else 2
		sb.content_margin_bottom = 4 if here else 2
		(creator_tab_boxes[i][0] as PanelContainer).add_theme_stylebox_override("panel", sb)
		var lab2: Label = creator_tab_boxes[i][1]
		lab2.text = ("‹ " if (here and on_tabs) else "") + String(tabs[i]) + (" ›" if (here and on_tabs) else "")
		lab2.add_theme_color_override("font_color", Color.WHITE if here else Color(0.35, 0.25, 0.18))
	creator_title.text = title
	creator_text.text = text
	creator_foot.text = foot
	creator_foot.visible = foot != ""
	_creator_controls(tab)
	creator_slot.visible = true

func hide_creator() -> void:
	creator_slot.visible = false
	creator_turn.visible = false

## a picture of a button, `h` pixels tall (its width follows the picture)
func _icon_rect(h: int) -> TextureRect:
	var r := TextureRect.new()
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.set_meta("h", h)
	return r

## shows the picture of the button for this action in r (or nothing, if it has none: on a touch screen)
func _set_icon(r: TextureRect, action: String) -> void:
	var path := Controls.icon(action) if action != "" else ""
	var tex: Texture2D = load(path) if path != "" else null
	r.texture = tex
	r.visible = tex != null
	if tex != null:
		var h: float = float(r.get_meta("h", 30))
		r.custom_minimum_size = Vector2(h * tex.get_width() / tex.get_height(), h)
		r.size = r.custom_minimum_size

func _creator_button(main: bool) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_constant_override("icon_max_width", 30)
	b.add_theme_constant_override("h_separation", 10)
	for state in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		var bg := TERRA if main else Color(0.86, 0.8, 0.68)
		sb.bg_color = bg.lightened(0.08) if state == "hover" else (bg.darkened(0.1) if state == "pressed" else bg)
		sb.set_corner_radius_all(10)
		sb.border_color = INK
		sb.set_border_width_all(2)
		sb.content_margin_left = 12; sb.content_margin_right = 16; sb.content_margin_top = 6; sb.content_margin_bottom = 6
		b.add_theme_stylebox_override(state, sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(c, Color.WHITE if main else INK)
	return b

## the creator's buttons and their pictures, for page `tab` (0 Lustre, 1 Pintas) and whatever is in the player's hands
func _creator_controls(tab: int) -> void:
	_creator_page = tab
	_set_icon(creator_tab_l, "tab_prev" if Controls.pad else "")
	_set_icon(creator_tab_r, "tab_next")
	creator_tabs.move_child(creator_tab_l, 0)
	creator_tabs.move_child(creator_tab_r, -1)
	creator_back.visible = tab == 1
	creator_back.text = Loc.t("c_back")
	creator_next.text = Loc.t("c_next") if tab == 0 else Loc.t("c_done")
	for pair in [[creator_back, "esc"], [creator_next, "ok"]]:
		var path := Controls.icon(pair[1])
		pair[0].icon = load(path) if path != "" else null
	_set_icon(creator_turn_l[1], "turn_left")
	_set_icon(creator_turn_r[1], "turn_right")
	_set_icon(creator_drag, "" if Controls.pad else "drag")

## puts the turning arrows either side of the character: `feet` is where the feet are on the screen, `head` the head
func creator_turn_at(feet: Vector2, head: Vector2) -> void:
	creator_turn.visible = creator_slot.visible
	if not creator_turn.visible:
		return
	var y: float = lerpf(feet.y, head.y, 0.18)
	var half: float = clampf((feet.y - head.y) * 0.32, 60.0, 180.0)
	var al: TextureRect = creator_turn_l[0]
	var ar: TextureRect = creator_turn_r[0]
	al.position = Vector2(feet.x - half - al.size.x, y - al.size.y / 2.0)
	ar.position = Vector2(feet.x + half, y - ar.size.y / 2.0)
	var kl: TextureRect = creator_turn_l[1]
	var kr: TextureRect = creator_turn_r[1]
	kl.position = al.position + Vector2(-kl.size.x * 0.4, al.size.y - 6.0)
	kr.position = ar.position + Vector2(ar.size.x - kr.size.x * 0.6, ar.size.y - 6.0)
	creator_drag.position = Vector2(feet.x - creator_drag.size.x / 2.0, feet.y + 14.0)
	_creator_grab = Rect2(Vector2(al.position.x - 20.0, head.y - 40.0), Vector2(ar.position.x + ar.size.x - al.position.x + 40.0, feet.y - head.y + 80.0))

## on a touch screen, in the creator: what a finger put down here is for: "panel" (its buttons), "turn" (the character), ""
func creator_spot(p: Vector2) -> String:
	if not creator_slot.visible:
		return ""
	if creator_panel.get_global_rect().has_point(p):
		return "panel"
	if _creator_grab.has_point(p):
		return "turn"
	return ""

## the phone slides up (or away). status: "Llamada entrante", a call timer...
## `look` (as chara.gd takes it) is the caller: their photo comes up on the screen, as on any phone
func phone(on: bool, who := "", status := "", look := {}) -> void:
	phone_name.text = who
	phone_status.text = status
	if on and who != _phone_who:
		_phone_who = who
		for c in phone_face.get_children():
			c.queue_free()
		if not look.is_empty():
			var px := Vector2i(158, 176)
			var box := SubViewportContainer.new()
			box.stretch = true
			box.size = Vector2(px)
			box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			box.add_child(Portrait.viewport(look, px))
			phone_face.add_child(box)
			var rim := ReferenceRect.new()             # a hairline round the photo
			rim.editor_only = false
			rim.border_color = Color(1, 1, 1, 0.55)
			rim.border_width = 2.0
			rim.size = Vector2(px)
			rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
			phone_face.add_child(rim)
	elif not on:
		_phone_who = ""
	var from: int = phone_slot.get_theme_constant("margin_bottom")
	var to := (318 if speed_slot.visible else 56) if on else -420      # beside the bubble; over the dashboard if you are driving
	if _phone_tween != null:                     # (put away before it had finished coming out: the first move is called off)
		_phone_tween.kill()
		_phone_tween = null
	if from == to:
		return
	var tw := create_tween()
	_phone_tween = tw
	tw.tween_method(func(v: float): phone_slot.add_theme_constant_override("margin_bottom", int(v)), float(from), float(to), 0.35)

func box(on: bool, foe_name: String) -> void:
	box_slot.visible = on
	box_foe_name.text = foe_name

func box_set(you: float, foe: float) -> void:
	box_you.value = you
	box_foe.value = foe

func box_round(text: String) -> void:
	box_info.text = text
