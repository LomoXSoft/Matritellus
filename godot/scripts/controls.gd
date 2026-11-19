extends Node
## Autoload. Every input in the game goes through named actions defined here, so keys can be reassigned
## and a gamepad works everywhere. Keyboard bindings are stored by Settings.

## the actions the player can reassign, in the order the settings screen lists them
const REBINDABLE := ["forward", "back", "left", "right", "interact", "run", "handbrake", "horn", "radio", "map", "pause", "box_punch_other", "box_low"]
const DEFAULT_KEYS := {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D, "interact": KEY_E, "run": KEY_SHIFT,
	"handbrake": KEY_SPACE, "horn": KEY_H, "radio": KEY_R, "map": KEY_M, "pause": KEY_P, "box_punch_other": KEY_F, "box_low": KEY_CTRL}

var keys: Dictionary = DEFAULT_KEYS.duplicate()

## Which device was touched last. Everything on screen that names a button asks glyph() what to call it, and
## device_changed tells whoever is showing such text to write it again.
signal device_changed
var pad := false
const PAD_NAMES := {"interact": "(A)", "punch": "(X)", "box_punch_other": "(Y)", "box_low": "LB", "run": "RB", "handbrake": "(B)", "horn": "(Y)", "radio": "cruceta →", "map": "BACK", "pause": "START",
	"forward": "stick ↑", "back": "stick ↓", "left": "stick ←", "right": "stick →", "ok": "(A)", "esc": "(B)"}
var _token: RegEx

## The left stick in menus, boards and lists, as steps: one when it is pushed, then, held, one after STICK_FIRST and
## every STICK_EVERY after that, like a key held down. (The user, 17 Nov 2026, with a Steam Controller: "no puede mover
## el joystick un poco, en menús y en ajedrez se mueve a toda velocidad sin parar" -- every movement of the stick was
## taken for another press.) It comes as the actions m_* and ui_* (the stick is bound to neither); walking and driving
## read the stick as it is, as before.
const STICK_ON := 0.55          # pushed this far it is a step...
const STICK_OFF := 0.35         # ...and it is let go below this
const STICK_FIRST := 0.4
const STICK_EVERY := 0.13
var _stick_dir := ""
var _stick_t := 0.0
var _stick_dev := 0

func _stick(e: InputEventJoypadMotion) -> void:
	if e.axis != JOY_AXIS_LEFT_X and e.axis != JOY_AXIS_LEFT_Y:
		return
	_stick_dev = e.device
	var v := Vector2(Input.get_joy_axis(e.device, JOY_AXIS_LEFT_X), Input.get_joy_axis(e.device, JOY_AXIS_LEFT_Y))
	if e.axis == JOY_AXIS_LEFT_X:
		v.x = e.axis_value
	else:
		v.y = e.axis_value
	var dir := _stick_dir
	if v.length() < STICK_OFF:
		dir = ""
	elif v.length() > STICK_ON or _stick_dir == "":
		if v.length() > STICK_ON:
			dir = ("right" if v.x > 0.0 else "left") if absf(v.x) > absf(v.y) else ("down" if v.y > 0.0 else "up")
	if dir == _stick_dir:
		return
	if _stick_dir != "":
		_send(_stick_dir, false)
	_stick_dir = dir
	if dir != "":
		_send(dir, true)
		_stick_t = STICK_FIRST

func _send(dir: String, on: bool) -> void:
	for prefix in ["m_", "ui_"]:
		var a := InputEventAction.new()
		a.action = prefix + dir
		a.pressed = on
		a.strength = 1.0 if on else 0.0
		a.device = _stick_dev
		Input.parse_input_event(a)

func _process(delta: float) -> void:
	if _stick_dir == "":
		return
	_stick_t -= delta
	if _stick_t <= 0.0:
		_stick_t = STICK_EVERY
		_send(_stick_dir, true)                  # (another step, as a key held down repeats)

func _input(e: InputEvent) -> void:
	if e is InputEventJoypadMotion:
		_stick(e)
	var now := pad
	if (e is InputEventJoypadButton and e.pressed) or (e is InputEventJoypadMotion and absf(e.axis_value) > 0.5) or e is InputEventScreenTouch or e is InputEventAction:
		now = true                          # (the buttons drawn on a touch screen are named as a pad's)
	elif (e is InputEventKey and e.pressed) or (e is InputEventMouseButton and e.pressed):
		now = false
	if now != pad:
		pad = now
		device_changed.emit()

## what the button for this action is called on whatever is in the player's hands
func glyph(action: String) -> String:
	if Touch.on:                            # (on a touch screen the button itself says what it does: no pad letters)
		return ""
	if pad and PAD_NAMES.has(action):
		return PAD_NAMES[action]
	match action:
		"ok":
			return "INTRO" if Loc.lang == "es" else "ENTER"
		"esc":
			return "ESC"
		"punch":
			return "clic" if Loc.lang == "es" else "click"
	var name := key_name(action) if keys.has(action) else action
	if name == "Shift" and Loc.lang == "es":
		name = "Mayús"
	return name

## The pictures of the buttons (tools/make_botones.py): a key of the keyboard, the mouse, or a pad's button, whichever
## is in the player's hands (the user, 13 November 2026: icons, not the names written out). A PlayStation pad gets its
## own shapes; any other pad (the Steam Machine's, a Steam Deck, an Xbox one) the A B X Y kind.
const ICONS := "res://assets/botones/"
const PAD_ICONS := {"interact": "a", "punch": "x", "box_punch_other": "y", "box_low": "lb", "run": "rb", "handbrake": "b", "horn": "y", "radio": "dpad_right",
	"map": "back", "pause": "start", "ok": "a", "esc": "b", "forward": "ls", "back": "ls", "left": "ls", "right": "ls",
	"tab_prev": "lb", "tab_next": "rb", "turn_left": "lt", "turn_right": "rt", "accel": "rt", "brake": "lt", "look": "rs",
	"random": "y", "m_up": "dpad_up", "m_down": "dpad_down", "m_left": "dpad_left", "m_right": "dpad_right"}
const PS_ICONS := {"a": "cross", "b": "circle", "x": "square", "y": "triangle", "lb": "l1", "rb": "r1", "lt": "l2", "rt": "r2",
	"back": "share", "start": "options"}
const ICON_H := 26                       # how tall they are drawn in a line of text of the usual size (18)

func playstation() -> bool:
	var name := Input.get_joy_name(0).to_lower()
	return name.contains("playstation") or name.contains("dualsense") or name.contains("dualshock") or name.contains("ps4") or name.contains("ps5") or name.contains("sony")

## the picture of the button for an action, on whatever is in the player's hands ("" if there is none: the name is
## written out then, as before)
func icon(action: String) -> String:
	if Touch.on:
		return ""
	if pad:
		var b: String = PAD_ICONS.get(action, "")
		if b == "":
			return ""
		if playstation() and PS_ICONS.has(b):
			return ICONS + "ps_" + PS_ICONS[b] + ".png"
		return ICONS + "xb_" + b + ".png"
	var key := ""
	match action:
		"ok":
			key = "Enter"
		"esc":
			key = "Escape"
		"punch":
			return ICONS + "mouse_left.png"
		"box_punch_other":
			return ICONS + "mouse_right.png"
		"drag":
			return ICONS + "mouse_drag.png"
		"tab_prev", "tab_next":
			key = "Tab"
		"turn_left":
			key = "Q"
		"turn_right":
			key = "E"
		"m_up":
			key = "Up"
		"m_down":
			key = "Down"
		"m_left":
			key = "Left"
		"m_right":
			key = "Right"
		_:
			if keys.has(action):
				key = OS.get_keycode_string(keys[action])
	if key == "":
		return ""
	for path in [ICONS + "kb_" + key + ".png", ICONS + "kb_" + key + "_" + Loc.lang + ".png"]:
		if ResourceLoader.exists(path):
			return path
	return ""

## the button as a picture in a line of rich text, `h` pixels tall (or its name, if there is no picture)
func icon_bb(action: String, h := ICON_H) -> String:
	var path := icon(action)
	return "[img height=%d]%s[/img]" % [h, path] if path != "" else glyph(action)

## writes the buttons into a text: "<interact> Hablar" becomes the picture of E, or of (A), then "Hablar". For rich
## text (RichTextLabel with bbcode on); `plain` writes the names out instead, for a plain Label.
func fill(text: String, plain := false) -> String:
	if not text.contains("<"):
		return text
	if _token == null:
		_token = RegEx.create_from_string("<([a-z_]+)>")
	var out := text
	for m in _token.search_all(text):
		var a := m.get_string(1)
		out = out.replace(m.get_string(0), glyph(a) if plain else icon_bb(a))
	if Touch.on:
		out = out.replace("() ", "").replace("()", "").replace("  ", " ").strip_edges()
	return out

func _ready() -> void:
	build()

func _key(code: int) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e

func _pad(button: int) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	return e

func _axis(axis: int, dir: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = dir
	return e

func _bind(action: String, events: Array) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action, 0.3)
	for e in events:
		InputMap.action_add_event(action, e)

## (re)creates every action from the current key bindings
func build() -> void:
	# --- in the world ---
	_bind("forward", [_key(keys["forward"]), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_bind("back", [_key(keys["back"]), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_bind("left", [_key(keys["left"]), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_bind("right", [_key(keys["right"]), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_bind("accel", [_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)])               # triggers drive the car
	_bind("brake", [_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)])
	_bind("cam_left", [_key(KEY_LEFT)])
	_bind("cam_right", [_key(KEY_RIGHT)])
	_bind("interact", [_key(keys["interact"]), _pad(JOY_BUTTON_A)])
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	_bind("punch", [click, _pad(JOY_BUTTON_X)])
	var other_click := InputEventMouseButton.new()
	other_click.button_index = MOUSE_BUTTON_RIGHT
	_bind("box_punch_other", [other_click, _key(keys["box_punch_other"]), _pad(JOY_BUTTON_Y)])
	_bind("box_low", [_key(keys["box_low"]), _pad(JOY_BUTTON_LEFT_SHOULDER)])
	_bind("box_low_toggle", [])               # finger switches height, keyboard/pad hold their modifier
	_bind("box_guard", [])                    # independent of the back action released by the touch stick
	_bind("run", [_key(keys["run"]), _pad(JOY_BUTTON_RIGHT_SHOULDER)])
	_bind("handbrake", [_key(keys["handbrake"]), _pad(JOY_BUTTON_B)])
	_bind("horn", [_key(keys["horn"]), _pad(JOY_BUTTON_Y)])
	_bind("radio", [_key(keys["radio"]), _pad(JOY_BUTTON_DPAD_RIGHT)])
	_bind("map", [_key(keys["map"]), _key(KEY_TAB), _pad(JOY_BUTTON_BACK)])
	_bind("pause", [_key(keys["pause"]), _key(KEY_ESCAPE), _pad(JOY_BUTTON_START)])
	# --- in menus (fixed) ---
	# (the stick is not bound to these: it comes as steps, see _stick below)
	_bind("m_up", [_key(KEY_UP), _key(KEY_W), _pad(JOY_BUTTON_DPAD_UP)])
	_bind("m_down", [_key(KEY_DOWN), _key(KEY_S), _pad(JOY_BUTTON_DPAD_DOWN)])
	_bind("m_left", [_key(KEY_LEFT), _pad(JOY_BUTTON_DPAD_LEFT)])
	_bind("m_right", [_key(KEY_RIGHT), _pad(JOY_BUTTON_DPAD_RIGHT)])
	for ui in ["ui_up", "ui_down", "ui_left", "ui_right"]:       # (nor to Godot's own, which move the focus of buttons)
		if InputMap.has_action(ui):
			for ev in InputMap.action_get_events(ui):
				if ev is InputEventJoypadMotion:
					InputMap.action_erase_event(ui, ev)
	_bind("m_accept", [_key(KEY_ENTER), _key(KEY_KP_ENTER), _key(KEY_SPACE), _pad(JOY_BUTTON_A)])
	_bind("m_back", [_key(KEY_ESCAPE), _key(KEY_BACKSPACE), _pad(JOY_BUTTON_B)])

func key_name(action: String) -> String:
	return OS.get_keycode_string(keys[action])

func rebind(action: String, keycode: int) -> void:
	for other in keys:                      # a key can only do one thing: whoever had it swaps with us
		if other != action and keys[other] == keycode:
			keys[other] = keys[action]
	keys[action] = keycode
	build()

func reset() -> void:
	keys = DEFAULT_KEYS.duplicate()
	build()

func load_keys(saved) -> void:
	if saved is Dictionary:
		for a in REBINDABLE:
			if saved.has(a):
				var code := int(saved[a])
				var previous = keys.find_key(code)
				if previous != null:
					keys[previous] = keys[a]      # older settings may already use F or Ctrl
				keys[a] = code
	build()

## the right stick, for looking around (x = right, y = down), with a dead zone
func look_stick() -> Vector2:
	var v := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	v += Touch.look                         # (a finger dragged on the right of a touch screen: touch.gd)
	return v if v.length() > 0.2 else Vector2.ZERO
