extends "res://scripts/chara.gd"
## A villager: wanders near home, can be talked to, and flies (harmlessly) when hit by a car.

var id := ""
var name_key := ""           # Loc key, or "" to use display_name
var display_name := ""
var look_data := {}             # the look it was made with (portraits)
var lines_key := ""          # Loc key holding several dialogues to cycle through
var voice := "adult_m"       # a profile from Sfx.VOICES
var line_i := 0
var state := "idle"          # idle | walk | fly | down
var t := 0.0
var vy := 0.0
var vel := Vector2.ZERO
var spin := 0.0
var home := Vector2.ZERO
var tgt := Vector2.ZERO
var still := false           # mission people stay put
var walker := false          # strolls the pavements instead of pottering about one spot
var wa := -1                 # the road node they are coming from...
var wb := -1                 # ...and the one they are heading for
var wside := 1.0             # which pavement (relative to their direction of travel)
var wpts: Array = []
var wi := 0
var wstuck := 0.0
var wtries := 0                # times in a row it has got stuck on this walk
var wspeed := 1.3
var beat := {}               # a walker who keeps to one street: its road nodes (game._walker_plan)
var away := false            # riding in the player's car
var _label: Label3D
var _bark_t := 0.0

func shown_name() -> String:
	return Loc.t(name_key) if name_key != "" else display_name

func bark(text: String, dur := 2.6) -> void:
	if _label == null:
		_label = Label3D.new()
		_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_label.no_depth_test = true
		_label.pixel_size = 0.011
		_label.font_size = 34
		_label.outline_size = 12
		_label.modulate = Color(1, 1, 1)
		_label.outline_modulate = Color(0.29, 0.2, 0.14)
		_label.position = Vector3(0, 2.5 * size, 0)
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.width = 420
		add_child(_label)
	_label.text = text
	_label.visible = true
	_bark_t = dur

func is_barking() -> bool:
	return _bark_t > 0.0

func tick_bark(dt: float) -> void:
	if _bark_t > 0.0:
		_bark_t -= dt
		if _bark_t <= 0.0:
			_label.visible = false
