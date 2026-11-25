extends Control
## Animal Crossing-style pocket inventory (opened on foot with I / Xbox Y / PS Triangle, or "Mochila" on touch).
## Two tabs:
##   0 - Objetos       (usable / consumable / discardable items: saffron, takeaway food, etc.)
##   1 - Objetos clave (non-sellable, non-droppable key & mission items: phone, peña neckerchief, bat, spray, posters...)

const Creator = preload("res://scripts/creator.gd")

const COLS := 4
const ROWS := 3
const SLOTS := COLS * ROWS

const CREAM := Color("fcf6e5")
const POCKET := Color("eee3c8")
const POCKET_SEL := Color("fff8dc")
const INK := Color("4a3424")
const SUB := Color("7a634f")
const TAB_OBJ := Color("5aa84f")
const TAB_KEY := Color("d98c2b")
const GOLD := Color("e6b422")
const RED := Color("c84438")

var G
var open := false
var tab := 0                    # 0 = Objetos, 1 = Objetos clave
var sel := 0                    # 0..SLOTS-1
var _mouse_was := Input.MOUSE_MODE_CAPTURED
var _tab_rects: Array = []
var _slot_rects: Array = []
var _use_rect := Rect2()
var _drop_rect := Rect2()
var _close_rect := Rect2()
var _list_cache: Array = []

func setup(game) -> void:
	G = game
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func toggle() -> void:
	if open:
		close()
	else:
		show_bag()

func show_bag() -> void:
	if open:
		return
	open = true
	visible = true
	sel = 0
	_mouse_was = Input.mouse_mode
	G._hold_world(true)
	if not Touch.on:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.beep(660.0, 0.05, 1, -16.0)
	_refresh()
	Touch._context_tick()

func close() -> void:
	if not open:
		return
	open = false
	visible = false
	G._hold_world(false)
	if not G.paused and not Touch.on:
		Input.mouse_mode = _mouse_was
	Sfx.beep(480.0, 0.05, 1, -18.0)
	Touch._context_tick()

## Adds a normal (non-key) pocket item to G.stats["inv"].
func add_item(id: String, qty := 1) -> void:
	if qty <= 0:
		return
	var inv: Dictionary = G.stats.get("inv", {})
	inv[id] = int(inv.get(id, 0)) + qty
	G.stats["inv"] = inv
	if open:
		_refresh()

func remove_item(id: String, qty := 1) -> void:
	if id == "azafran":
		G.saffron = maxi(0, G.saffron - qty)
		G._refresh_counts()
		if open:
			_refresh()
		return
	var inv: Dictionary = G.stats.get("inv", {})
	var left: int = int(inv.get(id, 0)) - qty
	if left <= 0:
		inv.erase(id)
	else:
		inv[id] = left
	G.stats["inv"] = inv
	if open:
		_refresh()

func normal_items() -> Array:
	var out: Array = []
	if G.saffron > 0:
		out.append({
			"id": "azafran",
			"icon": "azafran",
			"name": Loc.t("inv_n_azafran"),
			"desc": Loc.t("inv_d_azafran"),
			"qty": G.saffron,
			"usable": false,
			"droppable": true,
		})
	var inv: Dictionary = G.stats.get("inv", {})
	for id in inv.keys():
		var qty: int = int(inv[id])
		if qty <= 0:
			continue
		var key_id := String(id)
		out.append({
			"id": key_id,
			"icon": key_id,
			"name": Loc.t("inv_n_" + key_id) if Loc.TX.has("inv_n_" + key_id) else key_id,
			"desc": Loc.t("inv_d_" + key_id) if Loc.TX.has("inv_d_" + key_id) else "",
			"qty": qty,
			"usable": key_id in ["kebab", "jamon_taper", "bocata", "galletas_perro"],
			"droppable": true,
		})
	return out

func key_items() -> Array:
	var out: Array = []
	# Phone: always carried
	out.append({
		"id": "movil_propio",
		"icon": "movil",
		"name": Loc.t("inv_n_movil_propio"),
		"desc": Loc.t("inv_d_movil_propio"),
		"qty": 1,
		"key": true,
	})
	# Peña neckerchief
	var pena: String = Creator.PENAS[G.look_sel[11]] if G.look_sel.size() > 11 else ""
	out.append({
		"id": "panuelo",
		"icon": "panuelo",
		"name": Loc.t("inv_n_panuelo"),
		"desc": String(Loc.t("inv_d_panuelo")) % pena,
		"qty": 1,
		"key": true,
	})
	# Baseball bat
	if G.has_bat() or (G.side != null and G.side.get("id", "") == "menu"):
		out.append({
			"id": "bate",
			"icon": "bate",
			"name": Loc.t("inv_n_bate"),
			"desc": Loc.t("inv_d_bate"),
			"qty": 1,
			"key": true,
		})
	# Spray can
	if G.pintadas != null and G.pintadas.unlocked():
		out.append({
			"id": "spray",
			"icon": "spray",
			"name": Loc.t("inv_n_spray"),
			"desc": Loc.t("inv_d_spray"),
			"qty": 1,
			"key": true,
		})
	# Tokken 9 posters
	if G.recress != null and G.recress.stage() == "carteles":
		var left: int = maxi(1, G.recress.POSTERS - (G.recress.st.get("posters", []) as Array).size())
		out.append({
			"id": "carteles",
			"icon": "carteles",
			"name": Loc.t("inv_n_carteles"),
			"desc": Loc.t("inv_d_carteles"),
			"qty": left,
			"key": true,
		})
	# Josefa's phone (Day 2 V.I.P. step)
	if G.phase == "play" and G.si >= 0 and G.si < G.steps.size():
		var sid: String = String(G.steps[G.si].get("id", ""))
		if sid in ["vip", "josefa_back"]:
			out.append({
				"id": "movil",
				"icon": "movil",
				"name": Loc.t("inv_n_movil"),
				"desc": Loc.t("inv_d_movil"),
				"qty": 1,
				"key": true,
			})
	# Roast ham being delivered to Josefa
	if G.side != null and G.side.get("id", "") in ["menu", "ham"] and G.side.get("stage", "") == "bring":
		out.append({
			"id": "jamon",
			"icon": "jamon",
			"name": Loc.t("inv_n_jamon"),
			"desc": Loc.t("inv_d_jamon"),
			"qty": 1,
			"key": true,
		})
	# Bridge signatures sheet
	if G.firmas != null:
		out.append({
			"id": "firmas",
			"icon": "firmas",
			"name": Loc.t("inv_n_firmas"),
			"desc": String(Loc.t("inv_d_firmas")) % [int(G.firmas.get("got", 0)), int(G.firmas.get("need", 10))],
			"qty": 1,
			"key": true,
		})
	# Oil bottles
	if G.bottles > 0:
		out.append({
			"id": "aceite",
			"icon": "aceite",
			"name": Loc.t("inv_n_aceite"),
			"desc": Loc.t("inv_d_aceite"),
			"qty": G.bottles,
			"key": true,
		})
	# Pitillos: smoke one and six hours go by (fumar.gd)
	if G.get("fumar") != null and G.fumar.charges() > 0:
		out.append({
			"id": "pitillo",
			"icon": "pitillo",
			"name": Loc.t("inv_n_pitillo"),
			"desc": Loc.t("inv_d_pitillo"),
			"qty": G.fumar.charges(),
			"key": true,
			"usable": true,
		})
	# Tobacco pack for Tomasa Malvora
	if G.get("tomasa") != null and G.tomasa.has_tobacco():
		out.append({
			"id": "tabaco",
			"icon": "tabaco",
			"name": Loc.t("inv_n_tabaco"),
			"desc": Loc.t("inv_d_tabaco"),
			"qty": 1,
			"key": true,
		})
	return out

func _current_list() -> Array:
	return normal_items() if tab == 0 else key_items()

func _refresh() -> void:
	_list_cache = _current_list()
	sel = clampi(sel, 0, SLOTS - 1)
	queue_redraw()

func _selected_item():
	return _list_cache[sel] if sel >= 0 and sel < _list_cache.size() else null

func use_selected() -> bool:
	if tab != 0:
		var key = _selected_item()
		if key != null and bool(key.get("usable", false)) and String(key["id"]) == "pitillo":
			close()
			return G.fumar.use()
		Sfx.beep(196.0, 0.08, 1, -16.0)
		return false
	var it = _selected_item()
	if it == null or not bool(it.get("usable", false)):
		return false
	var id: String = String(it["id"])
	if id == "galletas_perro":
		if G.perros != null:
			var dog = G.perros.near(G.player.p, 4.5)
			if dog != null:
				close()
				return G.perros.feed(dog)
		Sfx.beep(196.0, 0.12, 1, -14.0)
		if G.hud != null:
			G.hud.toast(Loc.t("t_galletas_no_dog"), 2.4)
		return false
	remove_item(id, 1)
	close()
	G.comida.eat()
	return true

func drop_selected() -> bool:
	if tab != 0:
		Sfx.beep(196.0, 0.08, 1, -16.0)
		if G.hud != null:
			G.hud.toast(Loc.t("inv_no_drop"), 2.2)
		return false
	var it = _selected_item()
	if it == null or not bool(it.get("droppable", false)):
		return false
	var nm: String = String(it["name"])
	remove_item(String(it["id"]), 1)
	Sfx.beep(320.0, 0.07, 1, -16.0)
	if G.hud != null:
		G.hud.toast(Loc.t("inv_dropped") % nm, 2.2)
	_refresh()
	return true

func input(e: InputEvent) -> void:
	if not open:
		return
	if e.is_action_pressed("inventory") or e.is_action_pressed("pause") or e.is_action_pressed("m_back"):
		close()
		return
	# Switch tabs: Tab / Q / LB / RB
	if (e is InputEventKey and e.pressed and not e.echo and e.physical_keycode in [KEY_TAB, KEY_Q]) \
			or (e is InputEventJoypadButton and e.pressed and e.button_index in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]):
		tab = 1 - tab
		sel = 0
		Sfx.beep(600.0, 0.04, 1, -18.0)
		_refresh()
		return
	# Grid navigation
	if e.is_action_pressed("m_left", true):
		sel = (sel - 1 + SLOTS) % SLOTS
		Sfx.beep(520.0, 0.03, 1, -20.0)
		queue_redraw()
		return
	if e.is_action_pressed("m_right", true):
		sel = (sel + 1) % SLOTS
		Sfx.beep(520.0, 0.03, 1, -20.0)
		queue_redraw()
		return
	if e.is_action_pressed("m_up", true):
		sel = (sel - COLS + SLOTS) % SLOTS
		Sfx.beep(520.0, 0.03, 1, -20.0)
		queue_redraw()
		return
	if e.is_action_pressed("m_down", true):
		sel = (sel + COLS) % SLOTS
		Sfx.beep(520.0, 0.03, 1, -20.0)
		queue_redraw()
		return
	if e.is_action_pressed("m_accept") or e.is_action_pressed("interact"):
		use_selected()
		return
	if e.is_action_pressed("punch") and not (e is InputEventMouseButton):
		drop_selected()
		return
	# Mouse / Touch interaction
	var at = null
	if e is InputEventScreenTouch and e.pressed:
		at = e.position
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		at = e.position
	if at != null:
		var lp: Vector2 = at - global_position
		if _close_rect.has_point(lp):
			close()
			return
		for ti in range(_tab_rects.size()):
			if (_tab_rects[ti] as Rect2).has_point(lp):
				if tab != ti:
					tab = ti
					sel = 0
					Sfx.beep(600.0, 0.04, 1, -18.0)
					_refresh()
				return
		for si in range(_slot_rects.size()):
			if (_slot_rects[si] as Rect2).has_point(lp):
				sel = si
				Sfx.beep(520.0, 0.03, 1, -20.0)
				queue_redraw()
				return
		if _use_rect.size.x > 0.0 and _use_rect.has_point(lp):
			use_selected()
			return
		if _drop_rect.size.x > 0.0 and _drop_rect.has_point(lp):
			drop_selected()
			return

func _round_box(r: Rect2, col: Color, border := Color(0, 0, 0, 0), bw := 0.0, rad := 16.0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(int(rad))
	if bw > 0.0:
		sb.border_color = border
		sb.set_border_width_all(int(bw))
	draw_style_box(sb, r)

func _draw() -> void:
	if not open:
		return
	_list_cache = _current_list()
	var sz := size
	var font: Font = ThemeDB.fallback_font
	# Soft backdrop tint
	draw_rect(Rect2(Vector2.ZERO, sz), Color(0.08, 0.06, 0.04, 0.56))

	var pw := minf(680.0, sz.x - 40.0)
	var ph := minf(520.0, sz.y - 50.0)
	var card := Rect2((sz - Vector2(pw, ph)) / 2.0, Vector2(pw, ph))

	# Tabs sticking out of the top (Animal Crossing leaf-notebook style)
	_tab_rects.clear()
	var tab_w := 196.0
	var tab_h := 40.0
	var tab_defs := [
		[Loc.t("inv_tab_obj"), TAB_OBJ],
		[Loc.t("inv_tab_key"), TAB_KEY],
	]
	for ti in range(2):
		var active: bool = ti == tab
		var tr := Rect2(card.position.x + 28.0 + ti * (tab_w + 12.0), card.position.y - (tab_h - 6.0) + (0.0 if active else 6.0), tab_w, tab_h)
		_tab_rects.append(tr)
		_round_box(tr, tab_defs[ti][1] if active else (tab_defs[ti][1] as Color).darkened(0.28), INK, 3.0 if active else 2.0, 14.0)
		var t_txt := String(tab_defs[ti][0])
		var tw := font.get_string_size(t_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		draw_string(font, Vector2(tr.get_center().x - tw / 2.0, tr.position.y + 24.0), t_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("fff9eb"))

	# Main rounded cream card
	_round_box(Rect2(card.position + Vector2(6, 9), card.size), Color(0, 0, 0, 0.25), Color(0, 0, 0, 0), 0.0, 24.0)
	_round_box(card, CREAM, INK, 4.0, 24.0)

	# Close button (top right of card)
	_close_rect = Rect2(card.end.x - 46.0, card.position.y + 12.0, 32.0, 32.0)
	_round_box(_close_rect, Color("e6d8bc"), INK, 2.0, 16.0)
	draw_string(font, _close_rect.position + Vector2(10.0, 22.0), "×", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK)

	# Header inside card
	var head_txt := String(Loc.t("inv_title")) + "  ·  " + String(tab_defs[tab][0])
	draw_string(font, card.position + Vector2(28.0, 36.0), head_txt, HORIZONTAL_ALIGNMENT_LEFT, pw - 90.0, 22, INK)

	# Pocket grid (4 x 3)
	_slot_rects.clear()
	var gap := 14.0
	var pad_x := 32.0
	var grid_w := pw - pad_x * 2.0
	var cell_w := (grid_w - gap * (COLS - 1)) / COLS
	var cell_h := 84.0
	var gy0 := card.position.y + 56.0
	for i in range(SLOTS):
		var col := i % COLS
		var row := i / COLS
		var r := Rect2(card.position.x + pad_x + col * (cell_w + gap), gy0 + row * (cell_h + gap), cell_w, cell_h)
		_slot_rects.append(r)
		var is_sel: bool = i == sel
		_round_box(r, POCKET_SEL if is_sel else POCKET, GOLD if is_sel else Color("d5c6a8"), 4.0 if is_sel else 2.0, 16.0)
		if i < _list_cache.size():
			var it: Dictionary = _list_cache[i]
			_draw_icon(String(it.get("icon", "")), r.get_center() + Vector2(0.0, -7.0), 22.0)
			var nm: String = String(it["name"])
			if nm.length() > 14:
				nm = nm.left(13) + "…"
			var nw := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			draw_string(font, Vector2(r.get_center().x - nw / 2.0, r.end.y - 8.0), nm, HORIZONTAL_ALIGNMENT_LEFT, cell_w - 8.0, 12, INK)
			var qty: int = int(it.get("qty", 1))
			if qty > 1:
				var qtxt := "×%d" % qty
				var badge := Rect2(r.end.x - 36.0, r.position.y + 6.0, 30.0, 18.0)
				_round_box(badge, TAB_OBJ if tab == 0 else TAB_KEY, INK, 1.0, 8.0)
				draw_string(font, badge.position + Vector2(5.0, 14.0), qtxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		else:
			draw_circle(r.get_center(), 5.0, Color("dfd2b5"))

	# Description & action bar at bottom of card
	var info := Rect2(card.position.x + 24.0, gy0 + ROWS * (cell_h + gap) + 6.0, pw - 48.0, card.end.y - (gy0 + ROWS * (cell_h + gap) + 6.0) - 34.0)
	_round_box(info, Color("f3ead4"), Color("c9b99a"), 2.0, 14.0)
	_use_rect = Rect2()
	_drop_rect = Rect2()
	var chosen = _selected_item()
	if chosen != null:
		draw_string(font, info.position + Vector2(14.0, 24.0), String(chosen["name"]), HORIZONTAL_ALIGNMENT_LEFT, info.size.x - 190.0, 18, INK)
		draw_string(font, info.position + Vector2(14.0, 46.0), String(chosen["desc"]), HORIZONTAL_ALIGNMENT_LEFT, info.size.x - 190.0, 13, SUB)
		if tab == 1:
			var can_use: bool = bool(chosen.get("usable", false))
			draw_string(font, info.position + Vector2(14.0, 68.0), Loc.t("inv_key_lock"), HORIZONTAL_ALIGNMENT_LEFT, info.size.x - (190.0 if can_use else 28.0), 13, TAB_KEY.darkened(0.15))
			if can_use:                          # (a key item you can use: the pitillo)
				_use_rect = Rect2(info.end.x - 104.0, info.position.y + 18.0, 92.0, 34.0)
				_round_box(_use_rect, TAB_OBJ, INK, 2.0, 10.0)
				var kt := String(Loc.t("inv_use"))
				var kw := font.get_string_size(kt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
				draw_string(font, Vector2(_use_rect.get_center().x - kw / 2.0, _use_rect.position.y + 22.0), kt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
		else:
			var bx := info.end.x - 104.0
			if bool(chosen.get("droppable", false)):
				_drop_rect = Rect2(bx, info.position.y + 18.0, 92.0, 34.0)
				_round_box(_drop_rect, RED, INK, 2.0, 10.0)
				var dt := String(Loc.t("inv_drop"))
				var dw := font.get_string_size(dt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
				draw_string(font, Vector2(_drop_rect.get_center().x - dw / 2.0, _drop_rect.position.y + 22.0), dt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
				bx -= 100.0
			if bool(chosen.get("usable", false)):
				_use_rect = Rect2(bx, info.position.y + 18.0, 92.0, 34.0)
				_round_box(_use_rect, TAB_OBJ, INK, 2.0, 10.0)
				var ut := String(Loc.t("inv_use"))
				var uw := font.get_string_size(ut, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
				draw_string(font, Vector2(_use_rect.get_center().x - uw / 2.0, _use_rect.position.y + 22.0), ut, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	else:
		var empty_txt := String(Loc.t("inv_empty_obj" if tab == 0 else "inv_empty_key"))
		draw_string(font, info.position + Vector2(16.0, 38.0), empty_txt, HORIZONTAL_ALIGNMENT_LEFT, info.size.x - 32.0, 15, SUB)

	# Footer hint
	var foot := String(Loc.t("inv_foot"))
	var fw := font.get_string_size(foot, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_string(font, Vector2(card.get_center().x - fw / 2.0, card.end.y - 12.0), foot, HORIZONTAL_ALIGNMENT_LEFT, pw - 24.0, 13, SUB)

func _draw_icon(kind: String, c: Vector2, r: float) -> void:
	match kind:
		"bate":
			draw_line(c + Vector2(-r * 0.65, r * 0.65), c + Vector2(r * 0.65, -r * 0.65), Color("8a5a34"), 7.0, true)
			draw_line(c + Vector2(-r * 0.65, r * 0.65), c + Vector2(-r * 0.25, r * 0.25), Color("26262b"), 5.0, true)
			draw_circle(c + Vector2(r * 0.55, -r * 0.55), 5.0, Color("a67144"))
		"spray":
			draw_rect(Rect2(c + Vector2(-9, -6), Vector2(18, 22)), Color("d83295"))
			draw_rect(Rect2(c + Vector2(-9, -6), Vector2(18, 22)), INK, false, 1.5)
			draw_rect(Rect2(c + Vector2(-9, 1), Vector2(18, 8)), Color("f8f5ec"))
			draw_rect(Rect2(c + Vector2(-6, -13), Vector2(12, 7)), Color("c5cad0"))
			draw_rect(Rect2(c + Vector2(-3, -17), Vector2(6, 4)), INK)
		"carteles":
			draw_rect(Rect2(c + Vector2(-12, -16), Vector2(24, 30)), Color("3a86ff"))
			draw_rect(Rect2(c + Vector2(-12, -16), Vector2(24, 30)), INK, false, 2.0)
			draw_rect(Rect2(c + Vector2(-8, -10), Vector2(16, 8)), GOLD)
			draw_line(c + Vector2(-8, 4), c + Vector2(8, 4), Color.WHITE, 2.0)
			draw_line(c + Vector2(-8, 9), c + Vector2(5, 9), Color.WHITE, 2.0)
		"movil":
			draw_rect(Rect2(c + Vector2(-9, -15), Vector2(18, 30)), Color("26262b"))
			draw_rect(Rect2(c + Vector2(-7, -12), Vector2(14, 22)), Color("45d6ff"))
			draw_circle(c + Vector2(0, 12.5), 1.8, Color("d0d4da"))
		"panuelo":
			var tri := PackedVector2Array([c + Vector2(-16, -10), c + Vector2(16, -10), c + Vector2(0, 14)])
			draw_colored_polygon(tri, Color("d43b2f"))
			draw_polyline(tri + PackedVector2Array([tri[0]]), INK, 1.8)
		"jamon", "jamon_taper":
			draw_circle(c + Vector2(-3, 0), 13.0, Color("a84624"))
			draw_circle(c + Vector2(-3, 0), 13.0, INK, false, 1.8)
			draw_line(c + Vector2(8, -2), c + Vector2(16, -7), Color("f4ecd8"), 5.0, true)
		"kebab":
			draw_rect(Rect2(c + Vector2(-8, -10), Vector2(16, 24)), Color("d8dce0"))
			draw_circle(c + Vector2(0, -10), 8.0, Color("e5be7a"))
			draw_circle(c + Vector2(0, -12), 5.0, TAB_OBJ)
			draw_rect(Rect2(c + Vector2(-8, -10), Vector2(16, 24)), INK, false, 1.5)
		"azafran":
			for k in range(5):
				var a := TAU * k / 5.0
				draw_circle(c + Vector2(cos(a), sin(a)) * 8.0, 6.0, Color("8a4fb8"))
			draw_circle(c, 4.0, Color("d93829"))
		"firmas":
			draw_rect(Rect2(c + Vector2(-11, -15), Vector2(22, 30)), Color("fbf7ea"))
			draw_rect(Rect2(c + Vector2(-11, -15), Vector2(22, 30)), INK, false, 2.0)
			for y in [-6, 0, 6]:
				draw_line(c + Vector2(-7, y), c + Vector2(7, y), Color("3b5fa8"), 1.6)
		"aceite":
			draw_rect(Rect2(c + Vector2(-9, -8), Vector2(18, 22)), Color("d8c53a"))
			draw_rect(Rect2(c + Vector2(-9, -8), Vector2(18, 22)), INK, false, 1.8)
			draw_rect(Rect2(c + Vector2(-4, -15), Vector2(8, 7)), Color("5a7a1e"))
		"pitillo":
			draw_line(c + Vector2(-15, 6), c + Vector2(9, -6), Color("f4f2ec"), 6.0, true)
			draw_line(c + Vector2(-15, 6), c + Vector2(-8, 2.5), Color("d99b4a"), 6.0, true)
			draw_circle(c + Vector2(10, -6.5), 3.2, Color("ff5514"))
			draw_arc(c + Vector2(12, -14), 4.0, PI * 0.5, PI * 1.6, 8, Color("b9b4ac"), 2.0)
		"tabaco":
			draw_rect(Rect2(c + Vector2(-10, -12), Vector2(20, 26)), Color("f4f2ec"))
			draw_rect(Rect2(c + Vector2(-10, -12), Vector2(20, 10)), Color("c82420"))
			draw_rect(Rect2(c + Vector2(-10, -3), Vector2(20, 3)), GOLD)
			draw_rect(Rect2(c + Vector2(-10, -12), Vector2(20, 26)), INK, false, 1.8)
			draw_line(c + Vector2(5, -12), c + Vector2(5, -18), Color("d99b4a"), 3.0)
		"galletas_perro":
			# Classic golden dog bone with ink outline
			var bc := Color("d89b44")
			for sx: float in [-11.0, 11.0]:
				for sy: float in [-4.5, 4.5]:
					draw_circle(c + Vector2(sx, sy), 5.6, INK)
			draw_rect(Rect2(c + Vector2(-11.0, -5.0), Vector2(22.0, 10.0)), INK)
			for sx: float in [-11.0, 11.0]:
				for sy: float in [-4.5, 4.5]:
					draw_circle(c + Vector2(sx, sy), 4.2, bc)
			draw_rect(Rect2(c + Vector2(-11.0, -3.5), Vector2(22.0, 7.0)), bc)
		_:
			draw_circle(c, 12.0, GOLD)
			draw_circle(c, 12.0, INK, false, 2.0)
