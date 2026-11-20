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

var on := false
var _pad := Control.new()         # where the stick and the buttons' faces are drawn
var _stick_id := -1               # which finger holds the stick, where it went down, and how far it is pushed
var _stick_at := Vector2.ZERO
var _stick := Vector2.ZERO
var _menu_dir := ""
var _menu_t := 0.0
var _stick_fb := false            # the stick is holding forward or back (on foot): let go of when you take the wheel
var _look_id := -1
var _look_last := Vector2.ZERO
var look_drag := Vector2.ZERO     # pixels dragged since the game last took them
var look := Vector2.ZERO          # (Controls.look_stick adds this: always zero now, the drag is taken by take_look)
var _buttons: Array = []          # {node: TouchScreenButton, label, action, centre, r, big}
var _context := ""
var _ctx_t := 0.0

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
	var main := Vector2(s.x - 150.0, s.y - 160.0)           # the main one, big; the others in an arc round it
	var g = _game()
	if g != null and g.get("in_car") != null:
		main = Vector2(s.x - 135.0, s.y - 320.0)               # (in a car: above the speedometer)
	var arc: Array = [main + Vector2(-185, 30), main + Vector2(-140, -135), main + Vector2(10, -200), main + Vector2(-290, -90)]
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
			(tsb.shape as CircleShape2D).radius = b["r"] * 1.12
			tsb.position = b["centre"]
			tsb.visible = on
		else:
			b["action"] = ""
			tsb.visible = false
	_pad.queue_redraw()

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
	_buttons[i]["held_action"] = _buttons[i]["action"]
	_send(_buttons[i]["held_action"], true)
	_pad.queue_redraw()

func _release_button(i: int) -> void:
	var action: String = _buttons[i]["held_action"]
	_buttons[i]["held_action"] = ""
	_send(action, false)

func _released(i: int) -> void:
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
			if _on_button(e.position):
				return                   # (that one is the button's)
			var spot := _creator_spot(e.position)
			if spot == "panel":
				return                   # (the creator's own buttons)
			if spot == "turn" and _look_id < 0:
				_look_id = e.index       # a finger on the character in the creator turns it round (game.gd)
				_look_last = e.position
			elif e.position.x < _size().x * 0.5 and _stick_id < 0:
				_stick_id = e.index
				_stick_at = e.position
				_move_stick(e.position)
			elif e.position.x >= _size().x * 0.5 and _look_id < 0:
				_look_id = e.index
				_look_last = e.position
		else:
			if e.index == _stick_id:
				_stick_id = -1
				_move_stick(_stick_at)
			if e.index == _look_id:
				_look_id = -1
		_pad.queue_redraw()
	else:
		if e.index == _stick_id:
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

func _draw_pad() -> void:
	if not on:
		return
	var font := ThemeDB.fallback_font
	if _stick_id >= 0:                            # the stick, only while a finger holds it
		_pad.draw_circle(_stick_at, STICK_R + 22.0, Color(0, 0, 0, 0.18))
		_pad.draw_arc(_stick_at, STICK_R + 22.0, 0, TAU, 48, Color(1, 1, 1, 0.4), 3.0, true)
		_pad.draw_circle(_stick_at + _stick * STICK_R, 44.0, Color(1, 1, 1, 0.42))
	for b in _buttons:
		var tsb: TouchScreenButton = b["node"]
		if not tsb.visible:
			continue
		var c: Vector2 = b["centre"]
		var r: float = b["r"]
		var held := tsb.is_pressed()
		var face := Color(0.98, 0.96, 0.9, 0.7 if held else 0.42) if b["big"] else Color(0.12, 0.12, 0.14, 0.66 if held else 0.4)
		_pad.draw_circle(c, r, face)
		_pad.draw_arc(c, r, 0, TAU, 40, Color(1, 1, 1, 0.7), 2.5, true)
		var t: String = b["label"]
		var fs := 25 if b["big"] else (16 if b["small"] else 20)
		while fs > 11 and font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > r * 1.75:
			fs -= 1
		var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var ink := Color(0.12, 0.1, 0.08) if b["big"] else Color(1, 1, 1, 0.96)
		_pad.draw_string_outline(font, c + Vector2(-w / 2.0, fs * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(1, 1, 1, 0.45) if b["big"] else Color(0, 0, 0, 0.5))
		_pad.draw_string(font, c + Vector2(-w / 2.0, fs * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
