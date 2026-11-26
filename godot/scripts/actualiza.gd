extends Node
## Is there a newer version out? Checked right on startup (before loading the town, with a short timeout so offline
## launches are barely delayed), and also surfaced in the main menu and pause menu.
##
## The repository is public on GitHub (`API`), carrying the latest tag ("v0.2.4"), the three installers
## (-Windows.exe, -Android.apk, -Linux.tar.gz), and SHA256SUMS.txt.
## - On Windows and Linux/SteamOS, the game downloads the installer into user://actualiza/, checks its SHA-256 against
##   SHA256SUMS.txt, and when the player confirms "Instalar y reiniciar", hands off to the platform updater and quits so
##   the new version launches automatically.
## - On Android, OS security prevents silent self-install without a custom Play/PackageInstaller flow, so "Actualizar"
##   opens the APK download in the system browser (OS.shell_open) after the pre-load check saves the loading wait.

const API := "https://api.github.com/repos/LomoXSoft/Matritellus/releases/latest"
const HOME := "https://github.com/LomoXSoft/Matritellus/"            # the only place a link may lead to
const TIMEOUT := 8.0
const BOOT_WAIT := 3.0
const SUMS_NAME := "SHA256SUMS.txt"
const DL_DIR := "user://actualiza"
const HASH_CHUNK := 16 * 1024 * 1024                                 # 16 MB per frame when hashing on disk
const SUFFIX := {"Windows": "-Windows.exe", "Android": "-Android.apk", "Linux": "-Linux.tar.gz"}

var G
var mine := ""                  # this game's version
var latest := ""                # the newest one out, once known
var link := ""                  # where this machine's installer is downloaded from (or the release's page)
var asset_name := ""            # filename of the platform installer asset
var asset_size := 0             # declared byte size of that asset
var sums_link := ""             # URL of SHA256SUMS.txt in the same release
var expected_sha := ""          # 64-char hex digest expected for asset_name
var state := "idle"             # idle | asking | newer | same | failed
var dl_state := "idle"          # idle | sums | downloading | verifying | ready | installing | error
var dl_error := ""
var dl_path := ""               # absolute path of the downloaded installer/tarball
var dl_bytes := 0
var dl_total := 0
var verify_ratio := 0.0
var offered := false            # the page has come up by itself once: not again
var dry := false                # self-test mode: do not spawn browsers, network downloads, or updater processes
var platform_override := ""     # self-test mode: force platform name ("Windows" | "Linux" | "Android")
var opened := ""                # what "Actualizar" last opened in browser
var installed_cmd: Array = []   # last command prepared by apply_and_restart()
var _http: HTTPRequest
var _sums_http: HTTPRequest
var _dl_http: HTTPRequest
var _cancel_token := 0

func setup(game) -> void:
	G = game
	mine = String(ProjectSettings.get_setting("application/config/version", "0.0.0"))

func platform() -> String:
	return platform_override if platform_override != "" else OS.get_name()

func can_auto_update() -> bool:
	return platform() in ["Windows", "Linux"] and asset_name != "" and link != ""

func is_downloading() -> bool:
	return dl_state in ["sums", "downloading", "verifying"]

func progress_ratio() -> float:
	if dl_state == "verifying":
		return clampf(verify_ratio, 0.0, 1.0)
	if dl_state == "ready":
		return 1.0
	if dl_state == "downloading":
		return clampf(float(dl_bytes) / float(dl_total), 0.0, 1.0) if dl_total > 0 else 0.0
	return 0.0

func progress_text() -> String:
	if dl_state == "sums":
		return Loc.t("upd_dl_sums")
	if dl_state == "verifying":
		return Loc.t("upd_dl_verify") % int(round(verify_ratio * 100.0))
	if dl_state == "downloading":
		if dl_total > 0:
			return Loc.t("upd_dl_prog") % [int(dl_bytes / 1048576), maxi(1, int(round(dl_total / 1048576.0))), int(round(progress_ratio() * 100.0))]
		return Loc.t("upd_dl_prog_u") % int(dl_bytes / 1048576)
	return ""

## ask GitHub, once
func check() -> void:
	if state != "idle":
		return
	state = "asking"
	_http = HTTPRequest.new()
	_http.timeout = TIMEOUT
	add_child(_http)
	_http.request_completed.connect(_answer)
	if _http.request(API, PackedStringArray(["User-Agent: Matritellus", "Accept: application/vnd.github+json"])) != OK:
		state = "failed"

func _answer(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		state = "failed"
		return
	var d = JSON.parse_string(body.get_string_from_utf8())
	read(d if d is Dictionary else {})

## what GitHub answered (a release: tag_name, html_url, assets with name, size, and browser_download_url)
func read(d: Dictionary) -> void:
	asset_name = ""
	asset_size = 0
	sums_link = ""
	expected_sha = ""
	var tag: String = String(d.get("tag_name", "")).trim_prefix("v")
	if not valid(tag) or bool(d.get("draft", false)) or bool(d.get("prerelease", false)):
		state = "failed"
		return
	latest = tag
	link = safe(String(d.get("html_url", "")))
	var want: String = SUFFIX.get(platform(), "")
	var assets = d.get("assets", [])
	if assets is Array:
		for a in assets:
			if not (a is Dictionary):
				continue
			var aname: String = String(a.get("name", ""))
			var url: String = safe(String(a.get("browser_download_url", "")))
			if url == "":
				continue
			if aname == SUMS_NAME:
				sums_link = url
			elif want != "" and aname.ends_with(want) and asset_name == "":
				link = url
				asset_name = aname
				asset_size = int(a.get("size", 0))
	state = "newer" if link != "" and newer(latest, mine) else "same"
	if state == "same" and not dry:
		cleanup_cache("")
	if state == "newer" and G != null:
		G.update_found()

func available() -> bool:
	return state == "newer"

## "Actualizar" on Android or browser fallback: open the release/asset in the system browser
func go() -> void:
	opened = link
	if link != "" and not dry:
		OS.shell_open(link)

func start_download() -> void:
	if not available() or not can_auto_update():
		return
	if dl_state == "ready" and (dry or (dl_path != "" and FileAccess.file_exists(dl_path))):
		_notify_changed()
		return
	_drop_http("_sums_http")
	_drop_http("_dl_http")
	_cancel_token += 1
	var token := _cancel_token
	dl_error = ""
	dl_bytes = 0
	dl_total = asset_size
	verify_ratio = 0.0
	expected_sha = ""
	var dir_abs := ProjectSettings.globalize_path(DL_DIR)
	if not dry:
		var mk := DirAccess.make_dir_recursive_absolute(dir_abs)
		if mk != OK and not DirAccess.dir_exists_absolute(dir_abs):
			_fail_dl(Loc.t("upd_err_disk"))
			return
		cleanup_cache(asset_name)
	dl_path = dir_abs.path_join(asset_name)
	if dry:
		dl_state = "downloading"
		_notify_changed()
		return
	if sums_link != "":
		dl_state = "sums"
		_notify_changed()
		_sums_http = HTTPRequest.new()
		_sums_http.timeout = TIMEOUT
		_sums_http.max_redirects = 8
		_sums_http.use_threads = true
		add_child(_sums_http)
		_sums_http.request_completed.connect(_on_sums_done.bind(token))
		if _sums_http.request(sums_link, PackedStringArray(["User-Agent: Matritellus"])) != OK:
			_drop_http("_sums_http")
			_fail_dl(Loc.t("upd_err_net"))
	else:
		_begin_file_download(token)

func _on_sums_done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, token: int) -> void:
	_drop_http("_sums_http")
	if token != _cancel_token or dl_state != "sums":
		return
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_fail_dl(Loc.t("upd_err_net"))
		return
	expected_sha = parse_sha256sums(body.get_string_from_utf8(), asset_name)
	if expected_sha == "":
		_fail_dl(Loc.t("upd_err_net"))
		return
	_begin_file_download(token)

func _begin_file_download(token: int) -> void:
	if FileAccess.file_exists(dl_path):
		if expected_sha != "":
			var cached_ok: bool = await _verify_file_async(dl_path, token)
			if token != _cancel_token:
				return
			if cached_ok:
				dl_state = "ready"
				verify_ratio = 1.0
				_notify_changed()
				return
		DirAccess.remove_absolute(dl_path)
	var part_path := dl_path + ".part"
	if FileAccess.file_exists(part_path):
		DirAccess.remove_absolute(part_path)
	_dl_http = HTTPRequest.new()
	_dl_http.use_threads = true
	_dl_http.download_chunk_size = 262144
	_dl_http.max_redirects = 8
	_dl_http.timeout = 0.0
	_dl_http.download_file = part_path
	add_child(_dl_http)
	dl_state = "downloading"
	_notify_changed()
	_dl_http.request_completed.connect(_on_dl_done.bind(token))
	if _dl_http.request(link, PackedStringArray(["User-Agent: Matritellus"])) != OK:
		_drop_http("_dl_http")
		_fail_dl(Loc.t("upd_err_net"))

func _process(_dt: float) -> void:
	if dl_state != "downloading" or _dl_http == null or not is_instance_valid(_dl_http):
		return
	dl_bytes = _dl_http.get_downloaded_bytes()
	var bs := _dl_http.get_body_size()
	if bs > 0:
		dl_total = bs
	_notify_progress()

func _on_dl_done(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray, token: int) -> void:
	var part_path := dl_path + ".part"
	_drop_http("_dl_http")
	if token != _cancel_token or dl_state != "downloading":
		if FileAccess.file_exists(part_path):
			DirAccess.remove_absolute(part_path)
		return
	if result != HTTPRequest.RESULT_SUCCESS or code != 200 or not FileAccess.file_exists(part_path):
		if FileAccess.file_exists(part_path):
			DirAccess.remove_absolute(part_path)
		_fail_dl(Loc.t("upd_err_net"))
		return
	if FileAccess.file_exists(dl_path):
		DirAccess.remove_absolute(dl_path)
	if DirAccess.rename_absolute(part_path, dl_path) != OK:
		if FileAccess.file_exists(part_path):
			DirAccess.remove_absolute(part_path)
		_fail_dl(Loc.t("upd_err_disk"))
		return
	if expected_sha != "":
		var ok: bool = await _verify_file_async(dl_path, token)
		if token != _cancel_token:
			return
		if not ok:
			if FileAccess.file_exists(dl_path):
				DirAccess.remove_absolute(dl_path)
			_fail_dl(Loc.t("upd_err_sha"))
			return
	else:
		var f := FileAccess.open(dl_path, FileAccess.READ)
		var sz: int = f.get_length() if f != null else 0
		if f != null:
			f.close()
		if sz <= 0 or (asset_size > 0 and sz != asset_size):
			if FileAccess.file_exists(dl_path):
				DirAccess.remove_absolute(dl_path)
			_fail_dl(Loc.t("upd_err_sha"))
			return
	dl_state = "ready"
	verify_ratio = 1.0
	_notify_changed()

func _verify_file_async(path: String, token: int) -> bool:
	dl_state = "verifying"
	verify_ratio = 0.0
	_notify_changed()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var total := f.get_length()
	if total <= 0:
		f.close()
		return false
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	var read_so_far := 0
	while not f.eof_reached():
		if token != _cancel_token:
			f.close()
			return false
		var rem: int = mini(HASH_CHUNK, total - read_so_far)
		if rem <= 0:
			break
		var buf := f.get_buffer(rem)
		if buf.is_empty():
			break
		ctx.update(buf)
		read_so_far += buf.size()
		verify_ratio = float(read_so_far) / float(total)
		_notify_progress()
		await get_tree().process_frame
	f.close()
	if token != _cancel_token:
		return false
	return ctx.finish().hex_encode().to_lower() == expected_sha

func cancel_download() -> void:
	_cancel_token += 1
	_drop_http("_sums_http")
	_drop_http("_dl_http")
	if dl_path != "" and not dry:
		var part_path := dl_path + ".part"
		if FileAccess.file_exists(part_path):
			DirAccess.remove_absolute(part_path)
	dl_state = "idle"
	dl_bytes = 0
	verify_ratio = 0.0
	dl_error = ""
	_notify_changed()

func apply_and_restart() -> bool:
	if dl_state != "ready":
		return false
	if not dry and (dl_path == "" or not FileAccess.file_exists(dl_path)):
		_fail_dl(Loc.t("upd_err_disk"))
		return false
	var plat := platform()
	var exe_dir := OS.get_executable_path().get_base_dir()
	var pid := OS.get_process_id()
	if plat == "Windows":
		var args := PackedStringArray(["/update", "/launch", "/pid=%d" % pid])
		if FileAccess.file_exists(exe_dir.path_join("Matritellus.pck")):
			args.append("/dir=%s" % exe_dir.replace("/", "\\"))
		var exe_path := dl_path.replace("/", "\\") if not dry else dl_path
		installed_cmd = [exe_path, args]
		dl_state = "installing"
		if dry:
			return true
		var proc := OS.create_process(exe_path, args)
		if proc < 0:
			_fail_dl(Loc.t("upd_err_disk"))
			return false
		G.call_deferred("_quit_app")
		return true
	if plat == "Linux":
		var dest := exe_dir if FileAccess.file_exists(exe_dir.path_join("Matritellus.pck")) \
			else OS.get_environment("HOME").path_join(".local/share/Matritellus")
		var script_path := ProjectSettings.globalize_path(DL_DIR.path_join("apply_update.sh"))
		var args := PackedStringArray([script_path, str(pid), dl_path, dest])
		installed_cmd = ["/bin/bash", args]
		dl_state = "installing"
		if dry:
			return true
		var dir_abs := ProjectSettings.globalize_path(DL_DIR)
		DirAccess.make_dir_recursive_absolute(dir_abs)
		var sh := FileAccess.open(script_path, FileAccess.WRITE)
		if sh == null:
			_fail_dl(Loc.t("upd_err_disk"))
			return false
		sh.store_string(_linux_update_script())
		sh.close()
		var proc := OS.create_process("/bin/bash", args)
		if proc < 0:
			_fail_dl(Loc.t("upd_err_disk"))
			return false
		G.call_deferred("_quit_app")
		return true
	return false

static func _linux_update_script() -> String:
	return """#!/bin/bash
set -e
PID="$1"
TARBALL="$2"
DEST="$3"
for _ in $(seq 1 75); do
  kill -0 "$PID" 2>/dev/null || break
  sleep 0.2
done
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
tar -xzf "$TARBALL" -C "$STAGE"
SRC="$STAGE/Matritellus"
[ -d "$SRC" ] || SRC="$STAGE"
mkdir -p "$DEST"
rm -f "$DEST/Matritellus.x86_64"
rm -rf "$DEST/radio"
cp -r "$SRC/Matritellus.x86_64" "$SRC/Matritellus.pck" "$SRC/icon.png" "$SRC/radio" "$DEST/"
[ -f "$SRC/desinstalar.sh" ] && cp "$SRC/desinstalar.sh" "$DEST/"
[ -f "$SRC/LEEME.txt" ] && cp "$SRC/LEEME.txt" "$DEST/"
chmod +x "$DEST/Matritellus.x86_64"
[ -f "$DEST/desinstalar.sh" ] && chmod +x "$DEST/desinstalar.sh"
DATA="$HOME/.local/share/godot/app_userdata/Matritellus"
if [ -f "$SRC/ground.cache" ] && [ ! -f "$DATA/ground.cache" ]; then
  mkdir -p "$DATA"
  cp "$SRC/ground.cache" "$DATA/ground.cache"
fi
rm -f "$TARBALL"
cd "$DEST"
nohup "$DEST/Matritellus.x86_64" >/dev/null 2>&1 &
"""

func cleanup_cache(keep_name := "") -> void:
	var dir_abs := ProjectSettings.globalize_path(DL_DIR)
	var d := DirAccess.open(dir_abs)
	if d == null:
		return
	d.list_dir_begin()
	while true:
		var f := d.get_next()
		if f == "":
			break
		if d.current_is_dir() or f == keep_name:
			continue
		d.remove(f)
	d.list_dir_end()

func _fail_dl(msg: String) -> void:
	dl_state = "error"
	dl_error = msg
	_notify_changed()

func _drop_http(prop: String) -> void:
	var h: HTTPRequest = get(prop)
	if h != null and is_instance_valid(h):
		h.cancel_request()
		h.queue_free()
	set(prop, null)

func _notify_changed() -> void:
	if G != null and G.has_method("update_changed"):
		G.update_changed()

func _notify_progress() -> void:
	if G != null and G.has_method("update_progress"):
		G.update_progress()

static func parse_sha256sums(text: String, filename: String) -> String:
	for raw_line in text.split("\n"):
		var line := raw_line.strip_edges()
		if line == "":
			continue
		var sp := line.find(" ")
		if sp != 64:
			var tab := line.find("\t")
			if tab != 64:
				continue
			sp = tab
		var hex := line.substr(0, 64).to_lower()
		var ok_hex := true
		for i in range(64):
			var c := hex.unicode_at(i)
			if not ((c >= 48 and c <= 57) or (c >= 97 and c <= 102)):
				ok_hex = false
				break
		if not ok_hex:
			continue
		var fname := line.substr(64).strip_edges().trim_prefix("*")
		if fname == filename or fname.get_file() == filename:
			return hex
	return ""

static func file_sha256(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	while not f.eof_reached():
		var buf := f.get_buffer(4 * 1024 * 1024)
		if buf.is_empty():
			break
		ctx.update(buf)
	f.close()
	return ctx.finish().hex_encode().to_lower()

## a version as it must be written: three numbers
static func valid(v: String) -> bool:
	var parts := v.split(".")
	if parts.size() != 3:
		return false
	for p in parts:
		if not p.is_valid_int() or int(p) < 0 or p.length() > 5:
			return false
	return true

## is a later than b? (0.1.10 is later than 0.1.9)
static func newer(a: String, b: String) -> bool:
	if not valid(a) or not valid(b):
		return false
	var x := a.split(".")
	var y := b.split(".")
	for i in range(3):
		if int(x[i]) != int(y[i]):
			return int(x[i]) > int(y[i])
	return false

## a link is followed only into the game's own repository
static func safe(url: String) -> String:
	return url if url.begins_with(HOME) and not url.contains(" ") and not url.contains("\n") else ""
