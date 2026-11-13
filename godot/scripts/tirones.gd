extends Node
## The hitch log. On a Steam Machine the game would now and then drop to about one frame a second for a few seconds,
## even in the quiet opening talk (the user, 13 November 2026), and it never did so here. So, wherever it runs: every
## frame that takes longer than SLOW is written down in user://tirones.txt (on Linux:
## ~/.local/share/godot/app_userdata/Matritellus/tirones.txt; on Windows: %APPDATA%\Godot\app_userdata\Matritellus),
## with what the game's own parts took in that frame (game.gd _mark), how many shaders the graphics card was
## having made, the memory, and what was on the screen. A file of a few hundred lines at most: the oldest go.
##
## What to look for: "shaders" above nought in the slow frames -> the card was compiling them (the cure: having them
## made beforehand); a part of the game with hundreds of milliseconds -> that part; nothing at all and "cpu" small ->
## the frame was waiting on the graphics card or the system (power, heat, another program).

const SLOW := 0.25              # seconds: a frame this long is a hitch
const KEEP := 400               # lines kept

var G
var _lines: PackedStringArray = []
var _pipes := 0.0
var _written := false
var _since := 0.0
var count := 0                  # hitches written down since the game started

func setup(game) -> void:
	G = game
	G.prof = {}                 # (the game's parts time themselves from now on: game.gd _mark)
	_pipes = _pipelines()
	var path := "user://tirones.txt"
	if FileAccess.file_exists(path):
		var old := FileAccess.get_file_as_string(path).split("\n", false)
		_lines = old.slice(maxi(0, old.size() - KEEP / 2))
	_lines.append("=== %s · %s · %s · %s · %dx%d · %s" % [Time.get_datetime_string_from_system(), OS.get_name(), RenderingServer.get_video_adapter_name(),
		RenderingServer.get_video_adapter_api_version(), DisplayServer.window_get_size().x, DisplayServer.window_get_size().y, OS.get_processor_name()])
	_written = false

## shaders the graphics card has been asked to make, all kinds together
func _pipelines() -> float:
	var n := 0.0
	for m in [Performance.PIPELINE_COMPILATIONS_CANVAS, Performance.PIPELINE_COMPILATIONS_MESH, Performance.PIPELINE_COMPILATIONS_SURFACE,
			Performance.PIPELINE_COMPILATIONS_DRAW, Performance.PIPELINE_COMPILATIONS_SPECIALIZATION]:
		n += Performance.get_monitor(m)
	return n

func _process(delta: float) -> void:
	if G == null:
		return
	var pipes := _pipelines()
	var made := pipes - _pipes
	_pipes = pipes
	var parts: Dictionary = G.prof if G.prof != null else {}
	if delta >= SLOW:
		count += 1
		var keys: Array = parts.keys()
		keys.sort_custom(func(a, b): return parts[a] > parts[b])
		var cpu := 0.0
		for k in keys:
			cpu += float(parts[k])
		_lines.append("%s  %5.0f ms  fase %-9s shaders %3d  cpu %5.0f ms  mem %4.0f MB  vram %4.0f MB  objetos %d  | %s" % [
			Time.get_time_string_from_system(), delta * 1000.0, String(G.phase), int(made), cpu,
			Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
			int(Performance.get_monitor(Performance.OBJECT_COUNT)), ", ".join(keys.slice(0, 4).map(func(k): return "%s %.0f" % [k, parts[k]]))])
		_written = false
	if G.prof != null:
		G.prof.clear()
	_since += delta
	if not _written and _since > 5.0:          # (written at most every few seconds, not in the middle of a hitch)
		_since = 0.0
		_written = true
		if _lines.size() > KEEP:
			_lines = _lines.slice(_lines.size() - KEEP)
		var f := FileAccess.open("user://tirones.txt", FileAccess.WRITE)
		if f != null:
			f.store_string("\n".join(_lines) + "\n")
