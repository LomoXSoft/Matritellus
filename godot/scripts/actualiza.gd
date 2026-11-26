extends Node
## Is there a newer version out? Asked once, when the game is opened (the user, 25 November 2026: "sería posible
## añadir una manera de que al abrir el juego detecte si hay una versión nueva disponible y de opción de Actualizar o
## Jugar versión actual?").
##
## The game's repository is public, and GitHub says which its latest release is to anybody who asks, with no key:
## API below. The answer carries the tag ("v0.1.4") and the three installers; this takes the one of the machine it
## runs on (Windows .exe, Android .apk, Linux .tar.gz). If the tag is newer than this game's own version
## (project.godot, application/config/version) the main menu opens on the page "update" (game.gd _menu_page), and
## keeps a line for it at the top afterwards.
##
## "Actualizar" opens that installer's download in the machine's own browser (OS.shell_open) and tells you to leave
## the game and install it over this one: nothing is downloaded or run by the game itself. No answer in TIMEOUT
## seconds, no network, an answer that is not what is expected: nothing is said, and the game goes on as ever.
## Nothing of yours is sent: it is one plain request for a public page.

const API := "https://api.github.com/repos/LomoXSoft/Matritellus/releases/latest"
const HOME := "https://github.com/LomoXSoft/Matritellus/"            # the only place a link may lead to
const TIMEOUT := 8.0
const SUFFIX := {"Windows": "-Windows.exe", "Android": "-Android.apk", "Linux": "-Linux.tar.gz"}

var G
var mine := ""                  # this game's version
var latest := ""                # the newest one out, once known
var link := ""                  # where this machine's installer is downloaded from (or the release's page)
var state := "idle"             # idle | asking | newer | same | failed
var offered := false            # the page has come up by itself once: not again
var dry := false                # the self-test: do not open any browser
var opened := ""                # what "Actualizar" last opened
var _http: HTTPRequest

func setup(game) -> void:
	G = game
	mine = String(ProjectSettings.get_setting("application/config/version", "0.0.0"))

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

## what GitHub answered (a release: tag_name, html_url, assets with name and browser_download_url)
func read(d: Dictionary) -> void:
	var tag: String = String(d.get("tag_name", "")).trim_prefix("v")
	if not valid(tag) or bool(d.get("draft", false)) or bool(d.get("prerelease", false)):
		state = "failed"
		return
	latest = tag
	link = safe(String(d.get("html_url", "")))
	var want: String = SUFFIX.get(OS.get_name(), "")
	var assets = d.get("assets", [])
	if assets is Array and want != "":
		for a in assets:
			if a is Dictionary and String(a.get("name", "")).ends_with(want) and safe(String(a.get("browser_download_url", ""))) != "":
				link = String(a["browser_download_url"])
	state = "newer" if link != "" and newer(latest, mine) else "same"
	if state == "newer" and G != null:
		G.update_found()

func available() -> bool:
	return state == "newer"

## "Actualizar": the download, in the machine's browser
func go() -> void:
	opened = link
	if link != "" and not dry:
		OS.shell_open(link)

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
