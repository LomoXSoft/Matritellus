extends Node
## "Informar de un fallo" (Sistemas, 28 Nov 2026, asked for by the user from the list of proposals): one key (F12) or
## the pause's last-but-one line, and the game writes down what a tester saw. Before this the published game kept
## nothing anywhere, and a tester's bug (the roast ham sending you 2 km across the fields, the mayor missing from his
## night scene) had to be found again blind.
##
## What a report holds:
##   captura.png   the picture as it was (from the pause: the frame before the menu came up, game.gd _open_pause)
##   informe.txt   the version, the machine and its renderer, frames and video memory, the game's day and hour, where
##                 you stand, the mission and its step, the side errand, the car, the shop you are in, the graphics
##                 options, and the last LINES lines the game printed, errors and warnings included (a Logger of
##                 the engine's own: OS.add_logger, so it hears push_error and the engine's errors as well as print)
## Where:
##   computer / Steam Machine   Documentos/Matritellus/Informes/informe_<date>_<time>/ (Documents is there on
##                              Windows and Linux with no permission asked), else the game's own user:// folder
##   phone                      the game's own folder (Android lets no app write in Descargas without a permission
##                              this game does not ask for), so the text also goes to the clipboard: the tester
##                              pastes it in the message, with a screenshot of the phone's own
## The text is always on the clipboard too, on every machine. Nothing is sent anywhere.
## Not put in: the name on your Padrón, your saves, the keys you set. (The printed lines go in as they are: the game
## prints no paths with the computer's user in them, and this file prints only the report's folder name.)

const LINES := 300                  # the last printed lines kept
const LINE_MAX := 600               # a longer line is cut (a whole JSON printed at once)
const IN_DOCS := "Matritellus/Informes"

var folder_override := ""           # the self-test writes to user:// (never in the Documents of whoever runs it)
var last_dir := ""                  # where the last report went (the toast says it; the self-test reads it)
var _log: RingLog

class RingLog extends Logger:
	var lines: PackedStringArray = []
	var lock := Mutex.new()          # (the engine calls a logger from any thread)

	func _log_message(message: String, error: bool) -> void:
		_add(("[err] " if error else "") + message.strip_edges(false, true))

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
		var kind: String = ["ERROR", "WARNING", "SCRIPT ERROR", "SHADER ERROR"][clampi(error_type, 0, 3)]
		for bt in script_backtraces:             # (a push_error or push_warning: where in our scripts, not in the engine)
			if bt != null and bt.get_frame_count() > 0:
				file = bt.get_frame_file(0)
				line = bt.get_frame_line(0)
				function = bt.get_frame_function(0)
				break
		_add("%s: %s (%s:%d @ %s)" % [kind, rationale if rationale != "" else code, file, line, function])

	func _add(s: String) -> void:
		if s.length() > LINE_MAX:
			s = s.substr(0, LINE_MAX) + " […]"
		lock.lock()
		lines.append("%s %s" % [Time.get_time_string_from_system(), s])
		if lines.size() > LINES + 50:
			lines = lines.slice(lines.size() - LINES)
		lock.unlock()

	func last() -> PackedStringArray:
		lock.lock()
		var out := lines.slice(maxi(0, lines.size() - LINES))
		lock.unlock()
		return out

func _init() -> void:
	_log = RingLog.new()
	OS.add_logger(_log)

func _exit_tree() -> void:
	OS.remove_logger(_log)

## the printed lines kept so far (the self-test looks in them)
func log_lines() -> PackedStringArray:
	return _log.last()

## writes a report of the game g with the picture shot (null: none); returns {ok, dir, text}
func make(g, shot: Image) -> Dictionary:
	var text := describe(g)
	DisplayServer.clipboard_set(text)
	var stamp := Time.get_datetime_string_from_system().replace("T", "_").replace(":", "-")
	var dir := _folder().path_join("informe_" + stamp)
	var n := 2
	while DirAccess.dir_exists_absolute(dir):    # (two in the same second)
		dir = _folder().path_join("informe_%s_%d" % [stamp, n])
		n += 1
	if DirAccess.make_dir_recursive_absolute(dir) != OK:
		dir = ProjectSettings.globalize_path("user://informes").path_join("informe_" + stamp)
		DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(dir.path_join("informe.txt"), FileAccess.WRITE)
	var ok := f != null
	if ok:
		f.store_string(text)
		f.close()
		if shot != null:
			shot.save_png(dir.path_join("captura.png"))
	last_dir = dir if ok else ""
	print("informe: %s" % (dir.get_file() if ok else "could not be written (only on the clipboard)"))      # (the name alone: a whole path has the computer's user in it)
	return {"ok": ok, "dir": dir, "text": text}

## the folder the reports go in (made if missing)
func _folder() -> String:
	if folder_override != "":
		return ProjectSettings.globalize_path(folder_override)
	if not OS.has_feature("mobile"):
		var docs := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
		if docs != "" and DirAccess.make_dir_recursive_absolute(docs.path_join(IN_DOCS)) == OK:
			return docs.path_join(IN_DOCS)
	return ProjectSettings.globalize_path("user://informes")

## the words for where it went (under PAUSA, or a toast): short, the folder alone, never a whole path
func where_words(r: Dictionary) -> String:
	if not r["ok"]:
		return Loc.t("bug_clip")
	if OS.has_feature("mobile"):
		return Loc.t("bug_phone")
	var d: String = r["dir"]
	return Loc.t("bug_saved") % (Loc.t("bug_docs") + "/" + IN_DOCS if d.contains(IN_DOCS) else Loc.t("bug_game_dir"))

## the report's text
func describe(g) -> String:
	var L: PackedStringArray = []
	L.append("MATRITELLUS %s · informe de fallo · %s" % [ProjectSettings.get_setting("application/config/version", "?"), Time.get_datetime_string_from_system(false, true)])
	L.append("")
	L.append("== Máquina ==")
	L.append("sistema: %s %s · %s" % [OS.get_name(), OS.get_version(), OS.get_model_name()])
	L.append("tarjeta: %s (%s) · %s" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor(), RenderingServer.get_current_rendering_method()])
	L.append("pantalla: %s · 3D al %s" % [str(DisplayServer.window_get_size()), str(g.get_viewport().scaling_3d_scale) if g != null else "?"])
	L.append("fotogramas: %d por segundo" % Engine.get_frames_per_second())
	L.append("memoria de vídeo: %d MB · texturas %d MB · memoria %d MB" % [RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) >> 20,
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED) >> 20, OS.get_static_memory_usage() >> 20])
	L.append("")
	L.append("== Partida ==")
	if g == null:
		L.append("(sin partida)")
	else:
		L.append("modo: %s · hueco %d · fase %s%s" % ["Golismeo" if g.chavisca else "Historia", g.slot + 1, g.phase, " · en pausa" if g.paused else ""])
		L.append("día: %s (día %d del juego) · %s" % [Loc.t("wd_%d" % (int(g.weekday) % 7)), g.day_n, _hour(g.clock)])
		var step := "-"
		if g.si >= 0 and g.si < g.steps.size():
			step = "%d %s" % [g.si, str(g.steps[g.si].get("id", ""))]
		L.append("misión: paso %s · guardado en el paso %d" % [step, g.save_si])
		L.append("encargo: %s" % (_side(g.side) if g.side != null else "-"))
		L.append("objetivo: %s" % _v(g.target))
		if g.player != null:
			L.append("tú: %s · altura %.2f · mirando %.0f°" % [_v(g.player.p), MapData.height(g.player.p), rad_to_deg(g.player.h)])
		L.append("coche: %s" % (_name_of(g.in_car) if g.in_car != null else "-"))
		L.append("dentro de: %s" % (_name_of(g.inside_of) if g.indoors else "-"))
		L.append("hablando con: %s" % (_name_of(g.talk_npc) if g.talk_npc != null else "-"))
		L.append("dinero %d € · P.C. %d · azafrán %d" % [g.money, g.pc, g.saffron])
		if g.cam != null:
			L.append("cámara: %s" % str(g.cam.global_position))
	L.append("")
	L.append("== Gráficos ==")
	var opts: PackedStringArray = []
	for k in Settings.data:
		if k != "keys" and k != "warm":
			opts.append("%s=%s" % [k, str(Settings.data[k])])
	L.append(" ".join(opts))
	L.append("")
	L.append("== Lo último que escribió el juego ==")
	L.append_array(log_lines())
	return "\n".join(L) + "\n"

func _hour(c: float) -> String:
	return "%02d:%02d" % [int(c) % 24, int(fposmod(c, 1.0) * 60.0)]

func _v(p) -> String:
	return "(%.1f, %.1f)" % [p.x, p.y] if p is Vector2 else ("-" if p == null else str(p))

func _side(s) -> String:
	if not (s is Dictionary):
		return str(s)
	var parts: PackedStringArray = []
	for k in ["id", "who", "stage", "t"]:
		if s.has(k):
			parts.append("%s=%s" % [k, _name_of(s[k]) if s[k] is Object else str(s[k])])
	return " ".join(parts)

## a readable name for a node: its id (an NPC's), its node name and its script's file
func _name_of(o) -> String:
	if o == null or not is_instance_valid(o):
		return "-"
	if not (o is Object):
		return str(o)
	var bits: PackedStringArray = []
	for k in ["id", "kind"]:
		var v = o.get(k)
		if v != null and str(v) != "":
			bits.append(str(v))
	if o is Node:
		bits.append(String(o.name))
	var sc = o.get_script()
	if sc != null and sc.resource_path != "":
		bits.append(sc.resource_path.get_file())
	return " · ".join(bits)
