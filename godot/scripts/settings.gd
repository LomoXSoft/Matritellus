extends Node
## Autoload. Player settings: display, volumes, language and key bindings. Saved to user://.

const RESOLUTIONS := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]     # (only ever added to: saves keep an index)
const FPS_CAPS := [0, 30, 60, 120, 144]         # 0 = no limit

var path := "user://matritellus_settings.json"
var testing := false
var intro_seen := false                          # so going back to the main menu does not replay the studio logo
var data := {"res": 0, "fullscreen": false, "vsync": true, "fps": 0, "master": 8, "music": 7, "sfx": 8, "lang": "es", "keys": {},
	"window": 0, "shadows": 2, "textures": 2, "draw": 1, "fov": 55, "fx": 2, "aa": 2, "ssao": true, "glow": true, "scale": 4, "traffic": 1,
	"dynres": false, "upscale": 1, "lod": true, "occlusion": true, "silent": false, "filtro": 0, "dev": false,
	"r9_camera": false, "r9_fx": false, "r9_rumble": true,
	"bright": 6, "warm": ""}         # (warm: which version of the game has had its shaders made on this graphics card: calentar.gd)

## The graphics options (game.gd, apply_graphics, does what they say). The defaults are the game as it always was.
##   window     0 in a window · 1 full screen (borderless) · 2 full screen, exclusive
##   shadows    0 none · 1 low · 2 medium · 3 high          textures   0 low · 1 medium · 2 high (how sharp they stay)
##   draw       0 short · 1 normal · 2 long · 3 no limit (how far away small things are still drawn)
##   fov        degrees                                     fx         0 no particles · 1 few · 2 all (rain, smoke)
##   aa         0 none · 1 MSAA 2x · 2 MSAA 4x              ssao, glow  on or off
##   scale      the 3D drawn at SCALES[scale] % of the screen and scaled up      traffic    0 light · 1 normal
## (asked for by the user on 14 November 2026:)
##   dynres     the 3D drawn smaller of itself while the frames drop, and back up when there is room (game.gd _dynres)
##   upscale    how the 3D drawn small is brought up to the screen: 0 bilinear · 1 FSR 1 · 2 FSR 2 (not on a phone,
##              whose renderer has no FSR 2: there it stays at FSR 1)
##   lod        far things simplified: the engine's levels of detail, and small details drawn less far
##   occlusion  what is hidden behind the houses is not drawn (the walls of the town stand in front of it)
##   silent     "Modo Silent Hill": a street or two drawn, in a thick fog -- for the humblest machines
## (and, the user, 17 Nov 2026, the title by morning "un poco quemada" on the Steam Machine's television, where the same
## picture is fine on a computer's screen -- a television, or SteamOS stretching the picture for HDR, can push the
## bright colours over the top:)
##   bright     the whole picture, as it goes to the screen, times BRIGHT[bright] (6, 100 %, as it always was): after
##              the tone curve, so that 80 % is 80 % (before it, as the exposure, the curve swallowed most of it). Not
##              part of the presets: it is for the screen, not the machine.
const BRIGHT := [0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1.0, 1.05, 1.1]
const SCALES := [50, 67, 75, 85, 100]
const DRAW := [0.6, 1.0, 1.6, 0.0]               # (0: no limit)
const FOV := [45, 90]
## Ready-made sets: Low, Medium, High (the game as it always was, but for the sun's shadows), Ultra. The user, 16 Nov 2026:
## "Alto a 100 m, Muy Alto a 140 m" -- High draws the sun's shadows to 100 m (they cost a frame a fifth of its time at
## 140 m in 2K), Ultra to 140 m.
const GRAPHICS := ["shadows", "textures", "draw", "fx", "aa", "ssao", "glow", "scale", "traffic", "dynres", "upscale", "lod", "occlusion", "silent"]
const PRESETS := [
	{"shadows": 1, "textures": 1, "draw": 0, "fx": 1, "aa": 0, "ssao": false, "glow": false, "scale": 2, "traffic": 0, "dynres": true, "upscale": 1, "lod": true, "occlusion": true, "silent": false},
	{"shadows": 2, "textures": 2, "draw": 1, "fx": 2, "aa": 1, "ssao": false, "glow": true, "scale": 4, "traffic": 1, "dynres": true, "upscale": 1, "lod": true, "occlusion": true, "silent": false},
	{"shadows": 2, "textures": 2, "draw": 1, "fx": 2, "aa": 2, "ssao": true, "glow": true, "scale": 4, "traffic": 1, "dynres": false, "upscale": 1, "lod": true, "occlusion": true, "silent": false},
	{"shadows": 3, "textures": 2, "draw": 2, "fx": 2, "aa": 2, "ssao": true, "glow": true, "scale": 4, "traffic": 1, "dynres": false, "upscale": 1, "lod": false, "occlusion": true, "silent": false},
]

## the ways of scaling the 3D up there are here (a phone's renderer has no FSR 2)
func upscalers() -> int:
	return 2 if OS.has_feature("mobile") or RenderingServer.get_current_rendering_method() != "forward_plus" else 3

## which of the ready-made sets the options now are (-1: none of them, set by hand)
func preset() -> int:
	for k in range(PRESETS.size()):
		var same := true
		for key in GRAPHICS:
			if data[key] != PRESETS[k][key]:
				same = false
		if same:
			return k
	return -1

## on to the next (or previous) ready-made set
func step_preset(by: int) -> void:
	var now := preset()
	var k: int = (now + by + PRESETS.size()) % PRESETS.size() if now >= 0 else (2 if by > 0 else 1)
	for key in GRAPHICS:
		data[key] = PRESETS[k][key]
	apply()
	save()

## a number that goes up and down between two ends (the field of view), `by` at a time
func nudge(key: String, by: int, lo: int, hi: int) -> void:
	data[key] = clampi(int(data[key]) + by, lo, hi)
	apply()
	save()

func _ready() -> void:
	testing = OS.get_cmdline_user_args().has("--selftest")
	for bus in ["Music", "SFX"]:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	for p in Sfx.get_children():
		if p is AudioStreamPlayer:
			p.bus = "SFX"
	if OS.has_feature("mobile") and not FileAccess.file_exists(path):      # a phone, the first time: Low (the game asks a lot of one as it is)
		for key in GRAPHICS:
			data[key] = PRESETS[0][key]
		data["window"] = 1
	if not testing and FileAccess.file_exists(path):
		var d = JSON.parse_string(FileAccess.get_file_as_string(path))
		if d is Dictionary:
			for k in data:
				if d.has(k):
					data[k] = d[k]
			if not d.has("window"):              # (settings saved before there were three kinds of window)
				data["window"] = 1 if bool(d.get("fullscreen", false)) else 0
			if preset() == -1 and int(data["shadows"]) == 3:      # (High as it was before 16 Nov 2026, shadows to 140 m: High still)
				data["shadows"] = 2
				if preset() != 2:
					data["shadows"] = 3
	Controls.load_keys(data["keys"])
	apply()

## Running in gamescope, the compositor of the Steam Machine's (and the Steam Deck's) game mode
static func gamescope() -> bool:
	return OS.get_environment("GAMESCOPE_WAYLAND_DISPLAY") != "" or OS.get_environment("XDG_CURRENT_DESKTOP").to_lower() == "gamescope" 		or OS.get_environment("SteamGamepadUI") == "1"

func save() -> void:
	data["keys"] = Controls.keys
	if testing:
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))

func step(key: String, by: int, count: int) -> void:
	data[key] = (int(data[key]) + by + count) % count
	apply()
	save()

func toggle(key: String) -> void:
	data[key] = not bool(data[key])
	apply()
	save()

func apply() -> void:
	Loc.lang = String(data["lang"])
	for pair in [["Master", "master"], ["Music", "music"], ["SFX", "sfx"]]:
		var v := float(data[pair[1]]) / 10.0
		var i := AudioServer.get_bus_index(pair[0])
		AudioServer.set_bus_mute(i, v <= 0.0)
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.001)))
	Engine.max_fps = FPS_CAPS[int(data["fps"])]
	data["fullscreen"] = int(data["window"]) != 0
	var game = get_tree().current_scene if get_tree() != null else null
	if game != null and game.has_method("apply_graphics"):
		game.apply_graphics()
	if testing or DisplayServer.get_name() == "headless":
		return                                   # the test run keeps whatever window it was given
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(data["vsync"]) else DisplayServer.VSYNC_DISABLED)
	if int(data["window"]) == 2:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	elif int(data["window"]) == 1 or gamescope():
		# (under gamescope -- the Steam Machine's game mode -- a window is left as it is, in a corner on black, and
		# never scaled: there it is always the full screen, and the resolution is what the 3D is drawn at)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var size: Vector2i = RESOLUTIONS[int(data["res"])]
		size = size.min(DisplayServer.screen_get_usable_rect().size)      # (no bigger than the screen it is on)
		DisplayServer.window_set_size(size)
		var screen := DisplayServer.screen_get_usable_rect()
		DisplayServer.window_set_position(screen.position + (screen.size - size) / 2)
