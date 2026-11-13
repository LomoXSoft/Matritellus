extends CanvasLayer
## The studio intro shown when the game opens, instead of the Godot splash: the animated LomoXGames logo
## (a 4-second video with its sound). Any key or click skips it. Falls back to the still logo for 2 s.

signal finished

const VIDEO := "res://assets/intro/lomoxgames_intro.ogv"
const SOUND := "res://assets/intro/lomoxgames_logo.ogg"
const LOGO := "res://assets/intro/lomo_games.png"
const VOLUME_DB := -13.0

var _video: VideoStreamPlayer
var _t := 0.0
var _done := false

func _ready() -> void:
	layer = 40
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var stream = load(VIDEO) if ResourceLoader.exists(VIDEO) else null
	if stream is VideoStream:
		_video = VideoStreamPlayer.new()
		_video.stream = stream
		_video.expand = true
		_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_video)
		_fit()
		get_viewport().size_changed.connect(_fit)
		_video.finished.connect(_end)
		_video.play()
		if not _video.is_playing():
			_video.queue_free()
			_video = null
	if _video == null:
		var still := TextureRect.new()
		still.texture = preload("res://scripts/parts.gd").texture(LOGO)
		still.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		still.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		still.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(still)
	var snd = load(SOUND) if ResourceLoader.exists(SOUND) else AudioStreamOggVorbis.load_from_file(SOUND)
	if snd != null:
		var player := AudioStreamPlayer.new()
		player.stream = snd
		player.volume_db = VOLUME_DB
		add_child(player)
		player.play()

## 16:9, centred, as large as fits (black bars otherwise)
func _fit() -> void:
	if _video == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var w := minf(vp.x, vp.y * 16.0 / 9.0)
	_video.size = Vector2(w, w * 9.0 / 16.0)
	_video.position = (vp - _video.size) / 2.0

func _process(dt: float) -> void:
	_t += dt
	if (_video == null and _t > 2.0) or _t > 6.0:
		_end()

func _unhandled_input(e: InputEvent) -> void:
	if (e is InputEventKey or e is InputEventMouseButton or e is InputEventJoypadButton) and e.pressed:
		get_viewport().set_input_as_handled()      # this key skips the logo and does nothing else
		if _t > 0.25:
			_end()

func _end() -> void:
	if _done:
		return
	_done = true
	var black := ColorRect.new()                   # fade to black rather than cutting to the menu
	black.color = Color(0, 0, 0, 0)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	var tw := create_tween()
	tw.tween_property(black, "color:a", 1.0, 0.5)
	for c in get_children():
		if c is AudioStreamPlayer:
			tw.parallel().tween_property(c, "volume_db", -60.0, 0.5)
	tw.tween_callback(func():
		finished.emit()
		queue_free())
