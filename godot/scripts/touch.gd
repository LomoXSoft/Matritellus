extends CanvasLayer
## Autoload. Controls for a touch screen (phones and tablets), as the user asked for them on 13 November 2026:
##   - a stick that appears wherever a finger lands on the left half of the screen, and follows it;
##   - the camera turned by dragging a finger that starts on the right half (not on a button);
##   - action buttons with words, not a pad's letters, and only those that do something now: "Hablar" / "Subir" /
##     whatever the prompt on screen says, "Saltar" and "Golpe" on foot; "Acelerar", "Freno" (which says "Atrás" once
##     the car has stopped: reverse), "Claxon", "Turbo" in a car, where the stick only steers;
##     "Seguir" in a conversation; "Aceptar" / "Volver" in a menu... plus "Mapa" and pause along the top.
## Each button is the engine's own TouchScreenButton (the most dependable thing on a phone) pressing the action a pad
## would press (controls.gd), so the game itself does not know the difference. It shows on a touch screen (or with
## --touch, to try it on the PC) and hides while a real pad's buttons are in use.

const STICK_R := 95.0             # how far the stick's knob travels
const DEAD := 0.18
const MENU_REPEAT := 0.32         # holding the stick over a menu moves along it at this pace
const LOOK_PER_PX := 0.0055       # radians the camera turns per pixel dragged (game.gd)
const DPAD_ARM := 62.0            # virtual D-pad button offset from centre (menus, creator, wardrobe)
const DPAD_BTN_R := 34.0
const DPAD_HIT_R := 128.0
const DPAD_REPEAT := 0.18

var on := false
var _pad := Control.new()         # where the stick and the buttons' faces are drawn
var _stick_id := -1               # which finger holds the stick, where it went down, and how far it is pushed
var _stick_at := Vector2.ZERO
var _stick := Vector2.ZERO
var _menu_dir := ""
var _menu_t := 0.0
var _dpad_id := -1                # fixed D-pad on the bottom-left for menus and the character creator
var _dpad_dir := ""
var _dpad_t := 0.0
var _stick_fb := false            # the stick is holding forward or back (on foot): let go of when you take the wheel
var _look_id := -1
var _look_last := Vector2.ZERO
var look_drag := Vector2.ZERO     # pixels dragged since the game last took them
var look := Vector2.ZERO          # (Controls.look_stick adds this: always zero now, the drag is taken by take_look)
var _buttons: Array = []          # {node: TouchScreenButton, label, action, held_action, centre, r, big, small}
var _context := ""
var _ctx_t := 0.0
var _gas_id := -1                 # slide-to-lock accelerator while driving: drag up to the padlock and release
var _gas_pos := Vector2.ZERO
var _gas_lock := false
var _gas_arm := false
var _gas_tapped_locked := false

func _ready() -> void:
	layer = 90
	on = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available() or OS.get_cmdline_user_args().has("--touch")
	_pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad.draw.connect(_draw_pad)
	add_child(_pad)
	for i in range(10):                      # up to ten buttons at once; what each one is changes with the moment
		var b := TouchScreenButton.new()
		b.shape = CircleShape2D.new()
		b.shape_centered = true
		b.passby_press = false
		b.pressed.connect(_pressed.bind(i))
		b.released.connect(_released.bind(i))
		add_child(b)
		_buttons.append({"node": b, "label": "", "action": "", "held_action": "", "centre": Vector2.ZERO, "r": 0.0, "big": false, "small": false})
	_show(on)

func _size() -> Vector2:
	return _pad.get_viewport_rect().size

func _game():
	return get_tree().current_scene

# ---------------- what there is to do now ----------------
## [label, action, kind] for each button there should be: kind "big" (the main one), "" (round it) or "top" (small,
## along the top edge)
func _wanted() -> Array:
	var es: bool = Loc.lang == "es"
	var g = _game()
	if g == null or g.get("phase") == null:
		return []
	if not g.get("_booted"):
		return []                                 # the loading screen: nothing to press yet
	var phase: String = g.phase
	var menu = g.get("menu")
	if menu != null and menu.visible:
		return [["Aceptar" if es else "OK", "m_accept", "big"], ["Volver" if es else "Back", "m_back", ""]]
	match phase:
		"intro", "title_in", "press", "title_out", "title":
			# the studio's logo and the title gliding in: no buttons until the main menu (the user, 13 November 2026;
			# a tap anywhere still skips the logo: intro.gd)
			return []
		"ending":
			return [["Seguir" if es else "Go on", "m_accept", "big"]]
		"creator", "armario":
			# none of ours: the creator's panel has its own buttons (Siguiente on Lustre; Volver and Así me quedo on
			# Pintas: hud.gd), and a finger presses them. One of ours over the same spot took a single tap twice.
			# The wardrobe at home is the same panel (hud.show_wardrobe), with Volver and Me lo pongo.
			return []
		"prologue", "flyover", "cutscene", "failed", "end":
			return [["Seguir" if es else "Go on", "interact", "big"]]
		"rally":
			return g.rally.touch_buttons()
		"boxing":
			return [[Loc.t("box_right_hand"), "punch", "big"], [Loc.t("box_left_hand"), "box_punch_other", ""],
				[Loc.t("box_cover"), "box_guard", ""], [Loc.t("box_body" if g.boxing.touch_low else "box_high") + " ↕", "box_low_toggle", ""]]
		"tokken":
			# the arcade fighting game (tokken.gd) says its own buttons: Fuerte, Rápido, Poder, II; Elegir on the roster
			var tk = g.get("tokken")
			return tk.touch_buttons() if tk != null and tk.has_method("touch_buttons") else []
		"ajedrez":
			# (ajedrez) chess on the square: a finger picks the squares on the board itself; these are Vista, Soltar, II
			var aj = g.get("ajedrez")
			return aj.touch_buttons() if aj != null and aj.has_method("touch_buttons") else []
	if g.get("hud_hidden") == true and (menu == null or not menu.visible) and not g.get("map_open"):
		return []
	if g.get("inventario") != null and g.inventario.open:
		return []
	if g.get("map_open"):
		return [["Cerrar" if es else "Close", "map", "top"]]
	if g.get("_ask") != null or (g.get("cartas") != null and g.cartas.writing) or (g.get("padron") != null and g.padron.active):
		return []                                 # answering somebody: a finger takes an answer in the bubble itself (game.gd ask)
	if g.get("dlg") != null:
		return [["Seguir" if es else "Go on", "interact", "big"]]
	var out: Array = []
	var prompt: String = _prompt_words(g)
	if g.get("in_car") != null:
		# At the wheel (the user, 14 November 2026): a pedal to go, the big one; the other a brake that, once the car has
		# stopped, is reverse (the game's own "back" does just that: it says which it is now); and the stick only steers.
		var c = g.in_car
		out.append(["Acelerar" if es else "Accelerate", "forward", "big"])
		var moving_on: bool = c.forward_speed() > 0.8
		out.append([("Freno" if es else "Brake") if moving_on else ("Atrás" if es else "Reverse"), "back", ""])
		out.append([prompt if prompt != "" else ("Bajar" if es else "Get out"), "interact", ""])
		out.append(["Claxon" if es else "Horn", "horn", ""])
		if c.spec.has("turbo"):
			out.append(["Turbo", "run", ""])
		elif g.has_method("_has_autopilot") and g._has_autopilot(c):
			out.append(["Piloto" if es else "Autopilot", "run", ""])
		out.append(["Cámara" if es else "Camera", "cam_mode", "top"])
		out.append(["Radio", "radio", "top"])
	else:
		if prompt != "":
			out.append([prompt, "interact", "big"])
		out.append(["Saltar" if es else "Jump", "handbrake", ""])
		out.append([Loc.t("motin_hit"), "punch", ""])
		out.append(["Mochila" if es else "Bag", "inventory", "top"])
	out.append(["Mapa" if es else "Map", "map", "top"])
	out.append(["II", "pause", "top"])
	return out

## what the prompt on screen offers to do, without the button's name ("(A) Hablar" -> "Hablar")
func _prompt_words(g) -> String:
	var hud = g.get("hud")
	if hud == null or hud.get("prompt_slot") == null or not hud.prompt_slot.visible:
		return ""
	var t: String = hud.prompt.text
	t = t.replace("()", "").replace("( )", "").strip_edges()
	if t.begins_with("—") or t.begins_with("-"):
		t = t.substr(1).strip_edges()
	return t.left(18)

func _context_tick() -> void:
	var g0 = _game()
	if _stick_fb and g0 != null and g0.get("in_car") != null:
		Input.action_release("forward")           # (got in with the stick pushed: it does not drive the car on its own)
		Input.action_release("back")
		_stick_fb = false
	var want := _wanted()
	var key := str(want) + str(_size())
	if key == _context:
		return
	_context = key
	var s := _size()
	var g = _game()
	var in_car: bool = g != null and g.get("in_car") != null
	var main := Vector2(s.x - 135.0, s.y - 320.0) if in_car else Vector2(s.x - 150.0, s.y - 160.0)
	# When driving, clear the vertical lane directly above Acelerar for the slide-to-lock padlock target.
	var arc: Array = (
		[main + Vector2(-185, 30), main + Vector2(-155, -130), main + Vector2(-18, -232), main + Vector2(-295, -75)]
		if in_car else
		[main + Vector2(-185, 30), main + Vector2(-140, -135), main + Vector2(10, -200), main + Vector2(-290, -90)]
	)
	var n_arc := 0
	var n_top := 0
	for i in range(_buttons.size()):
		var b: Dictionary = _buttons[i]
		var tsb: TouchScreenButton = b["node"]
		var next_action: String = want[i][1] if i < want.size() else ""
		if b["action"] != next_action:
			_release_button(i)
			# Reset the native finger index before moving the button to its new action.
			tsb.visible = false
		if i < want.size():
			var kind: String = want[i][2]
			b["label"] = want[i][0]
			b["action"] = want[i][1]
			b["big"] = kind == "big"
			b["small"] = kind == "top"
			if kind == "big":
				b["centre"] = main
				b["r"] = 80.0
			elif kind == "top":
				b["centre"] = Vector2(s.x - 50.0 - n_top * 82.0, 48.0)
				b["r"] = 34.0
				n_top += 1
			else:
				b["centre"] = arc[mini(n_arc, arc.size() - 1)]
				b["r"] = 58.0
				n_arc += 1
			var gas_touch: bool = in_car and b["action"] == "forward"
			(tsb.shape as CircleShape2D).radius = 0.01 if gas_touch else b["r"] * 1.12
			tsb.position = b["centre"]
			tsb.visible = on
		else:
			b["action"] = ""
			tsb.visible = false
	if _gas_idx() < 0 or (in_car and g.in_car.broken()):
		if _gas_lock or _gas_id >= 0:
			_gas_lock = false
			_gas_id = -1
			_gas_arm = false
			_gas_tapped_locked = false
			_send("forward", false)
	_pad.queue_redraw()

func _dpad_mode() -> bool:
	if not on:
		return false
	var g = _game()
	if g == null or not g.get("_booted"):
		return false
	if g.get("padron") != null and g.padron.active:
		return false
	if g.get("cartas") != null and g.cartas.writing:
		return false
	var menu = g.get("menu")
	return (menu != null and menu.visible) or (g.get("phase") in ["creator", "armario"])

func _dpad_centre() -> Vector2:
	return Vector2(142.0, _size().y - 142.0)

func _dpad_dir_at(p: Vector2) -> String:
	var d := p - _dpad_centre()
	if d.length() < 14.0 or d.length() > DPAD_HIT_R:
		return ""
	if absf(d.x) > absf(d.y):
		return "m_right" if d.x > 0.0 else "m_left"
	return "m_down" if d.y > 0.0 else "m_up"

func _dpad_set(dir: String) -> void:
	if dir == _dpad_dir:
		return
	if _dpad_dir != "":
		_send(_dpad_dir, false)
	_dpad_dir = dir
	if dir != "":
		_send(dir, true)
		_dpad_t = DPAD_REPEAT * 1.9

func _gas_idx() -> int:
	var g = _game()
	if not on or g == null or g.get("in_car") == null:
		return -1
	for i in range(_buttons.size()):
		var b: Dictionary = _buttons[i]
		if (b["node"] as TouchScreenButton).visible and b["action"] == "forward":
			return i
	return -1

func _gas_lock_pos() -> Vector2:
	var gi := _gas_idx()
	if gi < 0:
		return Vector2.ZERO
	return (_buttons[gi]["centre"] as Vector2) + Vector2(0.0, -124.0)

func unlock_gas() -> void:
	if not _gas_lock and _gas_id < 0:
		return
	var was_locked := _gas_lock
	_gas_lock = false
	_gas_arm = false
	if was_locked and _gas_id < 0:
		_send("forward", false)
	_pad.queue_redraw()

func is_gas_locked() -> bool:
	return _gas_lock

# ---------------- pressing ----------------
func _send(action: String, down: bool) -> void:
	if action == "":
		return
	if action == "#tab":                    # the creator changes tab on a pad's shoulder button
		if down:
			for d in [true, false]:
				var j := InputEventJoypadButton.new()
				j.button_index = JOY_BUTTON_RIGHT_SHOULDER
				j.pressed = d
				j.device = -2
				Input.parse_input_event(j)
		return
	var e := InputEventAction.new()
	e.action = action
	e.pressed = down
	e.strength = 1.0 if down else 0.0
	Input.parse_input_event(e)
	if down:
		Input.action_press(action)
	else:
		Input.action_release(action)

func _pressed(i: int) -> void:
	Controls.pad = true
	var action: String = _buttons[i]["action"]
	if action == "forward" and _gas_idx() == i:
		_pad.queue_redraw()
		return
	if action == "back" and _gas_lock:
		unlock_gas()
	_buttons[i]["held_action"] = action
	_send(_buttons[i]["held_action"], true)
	_pad.queue_redraw()

func _release_button(i: int) -> void:
	var action: String = _buttons[i]["held_action"]
	_buttons[i]["held_action"] = ""
	if action == "forward" and _gas_lock:
		return
	_send(action, false)

func _released(i: int) -> void:
	if _buttons[i]["action"] == "forward" and (_gas_id >= 0 or _gas_lock):
		_pad.queue_redraw()
		return
	_release_button(i)
	_pad.queue_redraw()

func _on_button(p: Vector2) -> bool:
	for b in _buttons:
		if (b["node"] as TouchScreenButton).visible and p.distance_to(b["centre"]) < float(b["r"]) * 1.15:
			return true
	return false

func _input(e: InputEvent) -> void:
	if e is InputEventJoypadButton and e.pressed and e.device >= 0:
		if on:
			_show(false)                 # a real pad has been picked up
		return
	if not (e is InputEventScreenTouch or e is InputEventScreenDrag):
		return
	if not on:
		_show(true)
	if e is InputEventScreenTouch:
		if e.pressed:
			var gi := _gas_idx()
			if gi >= 0 and _gas_id < 0 and e.position.distance_to(_buttons[gi]["centre"]) <= float(_buttons[gi]["r"]) * 1.15:
				Controls.pad = true
				_gas_id = e.index
				_gas_pos = e.position
				_gas_arm = false
				if _gas_lock:
					_gas_tapped_locked = true
					_gas_lock = false
					_send("forward", false)
				else:
					_gas_tapped_locked = false
					_send("forward", true)
				_pad.queue_redraw()
				return
			if _on_button(e.position):
				return                   # (that one is the button's)
			if _dpad_mode() and _dpad_id < 0 and e.position.distance_to(_dpad_centre()) <= DPAD_HIT_R:
				Controls.pad = true
				_dpad_id = e.index
				_dpad_set(_dpad_dir_at(e.position))
				_pad.queue_redraw()
				return
			var spot := _creator_spot(e.position)
			if spot == "panel":
				return                   # (the creator's own buttons)
			if spot == "turn" and _look_id < 0:
				_look_id = e.index       # a finger on the character in the creator turns it round (game.gd)
				_look_last = e.position
			elif e.position.x < _size().x * 0.5 and _stick_id < 0:
				if _dpad_mode():
					var g = _game()
					if g != null and (g.get("phase") in ["creator", "armario"]):
						return
				_stick_id = e.index
				_stick_at = e.position
				_move_stick(e.position)
			elif e.position.x >= _size().x * 0.5 and _look_id < 0:
				_look_id = e.index
				_look_last = e.position
		else:
			if e.index == _gas_id:
				if _gas_arm and not _gas_tapped_locked and _gas_idx() >= 0:
					_gas_lock = true
					_send("forward", true)
				else:
					_gas_lock = false
					_send("forward", false)
				_gas_id = -1
				_gas_arm = false
				_gas_tapped_locked = false
				_pad.queue_redraw()
				return
			if e.index == _dpad_id:
				_dpad_id = -1
				_dpad_set("")
			if e.index == _stick_id:
				_stick_id = -1
				_move_stick(_stick_at)
			if e.index == _look_id:
				_look_id = -1
		_pad.queue_redraw()
	else:
		if e.index == _gas_id:
			_gas_pos = e.position
			if not _gas_tapped_locked:
				var gi := _gas_idx()
				var lp := _gas_lock_pos()
				_gas_arm = gi >= 0 and (_gas_pos.y <= (_buttons[gi]["centre"] as Vector2).y - 86.0 or _gas_pos.distance_to(lp) <= 52.0)
			_pad.queue_redraw()
		elif e.index == _dpad_id:
			_dpad_set(_dpad_dir_at(e.position))
			_pad.queue_redraw()
		elif e.index == _stick_id:
			_move_stick(e.position)
			_pad.queue_redraw()
		elif e.index == _look_id:
			look_drag += e.position - _look_last
			_look_last = e.position

## in the character creator (and the wardrobe, its same panel), what a finger put down here is for (hud.gd
## creator_spot): "panel", "turn" or ""
func _creator_spot(p: Vector2) -> String:
	var g = _game()
	if g != null and g.get("cartas") != null and (g.cartas.writing or (g.get("padron") != null and g.padron.active and g.phase != "creator")):
		return "panel"                            # (a letter being written at Correa: the whole screen is its sheet, cartas.gd)
	if g != null and g.get("_ask") != null and g.get("hud") != null and g.hud.answers_spot(p):
		return "panel"                            # (the answers bubble in a talk: game.gd ask)
	if g == null or not (g.get("phase") in ["creator", "armario"]) or g.get("hud") == null:
		return ""
	return g.hud.creator_spot(p)

## the pixels dragged since last asked (game.gd turns the camera by them, once a frame; in the creator, the character)
func take_look() -> Vector2:
	var d := look_drag
	look_drag = Vector2.ZERO
	return d

func _show(v: bool) -> void:
	on = v
	_pad.visible = v
	for b in _buttons:
		(b["node"] as TouchScreenButton).visible = v and b["action"] != ""
	if not v:
		for i in range(_buttons.size()):
			_release_button(i)
		if _stick_id >= 0:
			_stick_id = -1
			_move_stick(_stick_at)
		if _dpad_id >= 0 or _dpad_dir != "":
			_dpad_id = -1
			_dpad_set("")
		if _gas_lock or _gas_id >= 0:
			_gas_lock = false
			_gas_id = -1
			_gas_arm = false
			_gas_tapped_locked = false
			_send("forward", false)
		_look_id = -1
	else:
		Controls.pad = true
		_context = ""
		_context_tick()
	Controls.device_changed.emit()

## the stick drives the four directions as a pad's left stick does, by how far it is pushed
func _move_stick(p: Vector2) -> void:
	var v := (p - _stick_at) / STICK_R
	if v.length() > 1.0 and _stick_id >= 0:      # (the stick's centre follows a finger that goes further)
		_stick_at = p - v.normalized() * STICK_R
		v = v.normalized()
	_stick = v if _stick_id >= 0 else Vector2.ZERO
	var radial := _stick if _stick.length() > DEAD else Vector2.ZERO
	var x := radial.x
	var y := radial.y
	var g = _game()
	var wheel_only: bool = g != null and (g.get("in_car") != null or g.phase == "rally") and not (g.get("menu") != null and g.menu.visible)
	for pair in [["right", maxf(x, 0.0)], ["left", maxf(-x, 0.0)], ["back", maxf(y, 0.0)], ["forward", maxf(-y, 0.0)]]:
		if wheel_only and (pair[0] == "back" or pair[0] == "forward"):
			continue                              # (at the wheel the stick only steers: the pedals are buttons, and hold those two)
		if pair[1] > 0.0:
			Input.action_press(pair[0], pair[1])
		else:
			Input.action_release(pair[0])
	_stick_fb = not wheel_only and y != 0.0
	var dir := ""                                 # ...and steps through menus and the creator while it is held
	if _stick.length() > 0.55:
		if absf(_stick.x) > absf(_stick.y):
			dir = "m_right" if _stick.x > 0.0 else "m_left"
		else:
			dir = "m_down" if _stick.y > 0.0 else "m_up"
	if dir != _menu_dir:
		if _menu_dir != "":
			_send(_menu_dir, false)
		_menu_dir = dir
		if dir != "":
			_send(dir, true)
			_menu_t = MENU_REPEAT * 1.6

func _process(dt: float) -> void:
	if not on:
		return
	if _dpad_dir != "":
		if not _dpad_mode():
			_dpad_id = -1
			_dpad_set("")
		else:
			_dpad_t -= dt
			if _dpad_t <= 0.0:
				_dpad_t = DPAD_REPEAT
				_send(_dpad_dir, true)
	if _dpad_mode() and _stick_id >= 0:
		var g = _game()
		if g != null and (g.get("phase") in ["creator", "armario"]):
			_stick_id = -1
			_move_stick(_stick_at)
	if _gas_lock:
		if _gas_idx() < 0:
			unlock_gas()
		elif not Input.is_action_pressed("forward"):
			Input.action_press("forward")
	if _menu_dir != "":
		_menu_t -= dt
		if _menu_t <= 0.0:
			_menu_t = MENU_REPEAT
			_send(_menu_dir, true)
	_ctx_t -= dt
	if _ctx_t <= 0.0:
		_ctx_t = 0.12
		_context_tick()
	_pad.queue_redraw()

func _draw_lock(c: Vector2, closed: bool, ink: Color) -> void:
	var shackle := Vector2(c.x, c.y - 3.5)
	if closed:
		_pad.draw_arc(shackle, 5.5, PI, TAU, 16, ink, 2.2, true)
		_pad.draw_line(shackle + Vector2(-5.5, 0.0), shackle + Vector2(-5.5, 3.5), ink, 2.2, true)
		_pad.draw_line(shackle + Vector2(5.5, 0.0), shackle + Vector2(5.5, 3.5), ink, 2.2, true)
	else:
		_pad.draw_arc(shackle + Vector2(-1.5, -1.5), 5.5, PI * 0.9, PI * 1.9, 16, ink, 2.2, true)
		_pad.draw_line(shackle + Vector2(-7.0, -1.5), shackle + Vector2(-7.0, 3.5), ink, 2.2, true)
	_pad.draw_rect(Rect2(c.x - 7.5, c.y - 0.5, 15.0, 11.5), ink, true)

func _draw_pad() -> void:
	if not on:
		return
	var font := ThemeDB.fallback_font
	if _stick_id >= 0:                            # the stick, only while a finger holds it
		_pad.draw_circle(_stick_at, STICK_R + 22.0, Color(0, 0, 0, 0.18))
		_pad.draw_arc(_stick_at, STICK_R + 22.0, 0, TAU, 48, Color(1, 1, 1, 0.4), 3.0, true)
		_pad.draw_circle(_stick_at + _stick * STICK_R, 44.0, Color(1, 1, 1, 0.42))
	if _dpad_mode():
		var dc := _dpad_centre()
		_pad.draw_circle(dc, 108.0, Color(0, 0, 0, 0.16))
		_pad.draw_arc(dc, 108.0, 0, TAU, 48, Color(1, 1, 1, 0.3), 2.0, true)
		for entry in [
			["m_up", Vector2.UP, [Vector2(0, -10), Vector2(-9, 7), Vector2(9, 7)]],
			["m_down", Vector2.DOWN, [Vector2(0, 10), Vector2(-9, -7), Vector2(9, -7)]],
			["m_left", Vector2.LEFT, [Vector2(-10, 0), Vector2(7, -9), Vector2(7, 9)]],
			["m_right", Vector2.RIGHT, [Vector2(10, 0), Vector2(-7, -9), Vector2(-7, 9)]],
		]:
			var bc := dc + (entry[1] as Vector2) * DPAD_ARM
			var hit := _dpad_dir == String(entry[0])
			var fill := Color(0.98, 0.96, 0.9, 0.78) if hit else Color(0.12, 0.12, 0.14, 0.52)
			var tri_col := Color(0.12, 0.1, 0.08) if hit else Color(1, 1, 1, 0.95)
			_pad.draw_circle(bc, DPAD_BTN_R, fill)
			_pad.draw_arc(bc, DPAD_BTN_R, 0, TAU, 32, Color(1, 1, 1, 0.72), 2.2, true)
			var pts := PackedVector2Array()
			for v in (entry[2] as Array):
				pts.append(bc + (v as Vector2))
			_pad.draw_colored_polygon(pts, tri_col)
	var gi := _gas_idx()
	for i in range(_buttons.size()):
		var b: Dictionary = _buttons[i]
		var tsb: TouchScreenButton = b["node"]
		if not tsb.visible:
			continue
		var c: Vector2 = b["centre"]
		var r: float = b["r"]
		var is_gas := i == gi
		var held := tsb.is_pressed() or (is_gas and (_gas_id >= 0 or _gas_lock))
		var face := Color(0.98, 0.96, 0.9, 0.7 if held else 0.42) if b["big"] else Color(0.12, 0.12, 0.14, 0.66 if held else 0.4)
		var rim_col := Color(1, 1, 1, 0.7)
		var rim_w := 2.5
		if is_gas and _gas_lock:
			face = Color(0.28, 0.78, 0.42, 0.82)
			rim_col = Color(1.0, 0.96, 0.72, 0.95)
			rim_w = 3.5
		_pad.draw_circle(c, r, face)
		_pad.draw_arc(c, r, 0, TAU, 40, rim_col, rim_w, true)
		if is_gas and _gas_lock:
			_draw_lock(c + Vector2(0.0, -34.0), true, Color.WHITE)
		var t: String = b["label"]
		var fs := 25 if b["big"] else (16 if b["small"] else 20)
		while fs > 11 and font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > r * 1.75:
			fs -= 1
		var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var ink := Color.WHITE if (is_gas and _gas_lock) else (Color(0.12, 0.1, 0.08) if b["big"] else Color(1, 1, 1, 0.96))
		_pad.draw_string_outline(font, c + Vector2(-w / 2.0, fs * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(1, 1, 1, 0.45) if (b["big"] and not (is_gas and _gas_lock)) else Color(0, 0, 0, 0.5))
		_pad.draw_string(font, c + Vector2(-w / 2.0, fs * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
	if gi >= 0 and _gas_id >= 0 and not _gas_tapped_locked:
		var gc: Vector2 = _buttons[gi]["centre"]
		var lp := _gas_lock_pos()
		var lr := 34.0 if _gas_arm else 28.0
		_pad.draw_line(gc + Vector2(0.0, -float(_buttons[gi]["r"]) - 4.0), lp + Vector2(0.0, lr + 4.0), Color(1, 1, 1, 0.65), 2.5, true)
		_pad.draw_circle(lp, lr, Color(0.28, 0.78, 0.42, 0.88) if _gas_arm else Color(0.12, 0.12, 0.14, 0.66))
		_pad.draw_arc(lp, lr, 0, TAU, 32, Color(1, 1, 1, 0.92), 2.8, true)
		_draw_lock(lp + Vector2(0.0, 2.0), _gas_arm, Color.WHITE)
