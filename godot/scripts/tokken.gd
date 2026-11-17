extends CanvasLayer
## Tokken 9: the fighting game on the machines of the Galaxy Recress (the user, 13-14 November 2026: "un juego de
## peleas estilo Tekken pero con personajes históricos o fantásticos con superpoderes"). Two fighters side on, on one
## of three stages; best of three rounds of 99; the fighters, their portraits and the stages are cut out of the user's
## own pictures of the machines' screens (tools/make_tokken.py -> assets/tokken/).
##
##   left / right   walk (back, away from the other one, is also how you cover up)
##   up             jump
##   punch          the quick blow       interact   the strong blow       handbrake   the POWER, once its bar is full
##
## What there is to learn, in the order a player finds it:
##   - the quick blow is short and safe; the strong one reaches further, hurts more and leaves you open if it misses;
##   - covering up stops everything, but it wears the guard down (the thin bar): at nothing, the guard breaks;
##   - a quick blow that lands can be CANCELLED into a strong one by pressing it at once: the second cannot be
##     stopped, and a strong one that lands can be cancelled into the power. This is what the mayor never learnt ("los
##     nuevos sistemas de combos y cancelaciones son muy raros"): his guard comes down after the first blow;
##   - each fighter's power is different: three throw something that can be jumped, the samurai crosses the stage
##     with his sword, the raptor pounces, and the monster's runs along the floor.
##
## game.gd gives it the phase "tokken": start() takes it, tick() and input() run it, and it hands the phase back and
## calls `done(won)` when the match is over. The fight itself (_sim) knows nothing of the screen, so the tests can
## play whole matches between two of the machine's own players in no time (sim()).

const Letras = preload("res://scripts/tokken_letras.gd")
const Datos = preload("res://scripts/tokken_datos.gd")
const ART := "res://assets/tokken/"
const VIEW_H := 360.0            # rows of the stage the screen shows (the pictures are drawn twice their size at 720)
const STAGE_W := 1317.0
const WALL := 50.0               # how near the ends of the stage they can get
const START_GAP := 250.0
const HP := 100.0
const GUARD := 100.0
const ROUND_SECONDS := 99
const CLOCK_TICK := 40           # frames to one "second" of the round's clock (99 of them are 66 real ones)
const TO_WIN := 2
const GRAVITY := 0.44
const JUMP_V := 9.6
const BUFFER := 12               # frames a button pressed too soon is remembered
const CANCEL_STARTUP := 8        # a strong blow out of a quick one that landed comes out this fast
const CHAIN_SCALE := 0.85        # each blow of a combo hurts this much of the one before
const ROSTER := ["cleopatra", "napoleon", "samurai", "dracula", "monstruo", "raptor"]

## what every blow of a kind is like, unless the fighter's own says otherwise. startup / active / recover: frames
## before it can hit, while it can, and after; reach: from the middle of whoever throws it; lunge: how far it carries
## them forward; stop: frames everything freezes when it lands
const BASE := {
	"light": {"startup": 6, "active": 4, "recover": 10, "dmg": 6.0, "reach": 80.0, "lunge": 10.0, "hitstun": 20, "blockstun": 10, "push": 3.2, "guard": 12.0, "stop": 5},
	"heavy": {"startup": 14, "active": 5, "recover": 20, "dmg": 13.0, "reach": 108.0, "lunge": 24.0, "hitstun": 26, "blockstun": 16, "push": 5.5, "guard": 28.0, "stop": 8},
	"air": {"startup": 4, "active": 99, "recover": 0, "dmg": 9.0, "reach": 78.0, "lunge": 0.0, "hitstun": 22, "blockstun": 12, "push": 4.0, "guard": 16.0, "stop": 6},
	"special": {"startup": 10, "active": 8, "recover": 24, "dmg": 22.0, "reach": 0.0, "lunge": 0.0, "hitstun": 30, "blockstun": 20, "push": 6.0, "guard": 45.0, "stop": 12, "chip": 3.0},
}
## The six. speed: pixels a frame; half / tall: the body; power / tough: how hard they hit and how well they take it;
## idle / guard / hurt / jump: which of the eight poses of their strip; and their blows: "poses" are the pose before
## it can hit, while it can, and after.
const FIGHTERS := {
	"cleopatra": {"stage": 1, "speed": 2.5, "half": 32.0, "tall": 150.0, "power": 1.0, "tough": 1.0,
		"idle": [0, 7], "guard": 4, "hurt": 6, "jump": 0,
		"light": {"reach": 78.0, "startup": 5, "poses": [1, 5, 5]},
		"heavy": {"reach": 104.0, "poses": [1, 2, 3]},
		"air": {"poses": [2, 2, 2]},
		"special": {"type": "shot", "fx": "orb", "speed": 7.5, "dmg": 24.0, "poses": [1, 2, 3]}},
	"napoleon": {"stage": 2, "speed": 2.1, "half": 34.0, "tall": 160.0, "power": 1.08, "tough": 1.0,
		"idle": [0, 7], "guard": 5, "hurt": 6, "jump": 4,
		"light": {"reach": 80.0, "poses": [1, 2, 2]},
		"heavy": {"reach": 112.0, "poses": [1, 3, 3]},
		"air": {"poses": [3, 3, 3]},
		"special": {"type": "shot", "fx": "wave", "speed": 8.5, "poses": [1, 3, 3]}},
	"samurai": {"stage": 2, "speed": 1.9, "half": 36.0, "tall": 165.0, "power": 1.0, "tough": 1.0,
		"idle": [0, 1, 7], "guard": 2, "hurt": 3, "jump": 1,
		"light": {"reach": 90.0, "startup": 7, "recover": 11, "poses": [7, 6, 6]},
		"heavy": {"reach": 124.0, "startup": 16, "recover": 25, "poses": [2, 4, 5]},
		"air": {"reach": 92.0, "poses": [4, 4, 4]},
		"special": {"type": "dash", "fx": "moon", "speed": 9.0, "active": 14, "reach": 118.0, "poses": [2, 4, 5]}},
	"dracula": {"stage": 3, "speed": 2.3, "half": 36.0, "tall": 160.0, "power": 1.08, "tough": 1.0,
		"idle": [0, 7], "guard": 5, "hurt": 6, "jump": 4,
		"light": {"reach": 84.0, "poses": [4, 2, 2]},
		"heavy": {"reach": 112.0, "poses": [1, 3, 3]},
		"air": {"poses": [3, 3, 3]},
		"special": {"type": "shot", "fx": "bats", "speed": 5.0, "dmg": 24.0, "poses": [1, 2, 3]}},
	"monstruo": {"stage": 3, "speed": 1.75, "half": 42.0, "tall": 170.0, "power": 1.28, "tough": 1.18,
		"idle": [0, 1, 7], "guard": 6, "hurt": 3, "jump": 2,
		"light": {"reach": 89.0, "startup": 7, "recover": 12, "poses": [0, 4, 4]},
		"heavy": {"reach": 118.0, "startup": 17, "recover": 22, "poses": [4, 5, 5]},
		"air": {"poses": [5, 5, 5]},
		"special": {"type": "quake", "fx": "bolt", "speed": 6.0, "startup": 14, "reach": 96.0, "poses": [4, 5, 5]}},
	"raptor": {"stage": 1, "speed": 3.0, "half": 44.0, "tall": 135.0, "power": 0.86, "tough": 0.9,
		"idle": [0, 1, 7], "guard": 2, "hurt": 3, "jump": 6,
		"light": {"reach": 95.0, "startup": 5, "poses": [6, 4, 4]},
		"heavy": {"reach": 120.0, "startup": 12, "poses": [6, 5, 5]},
		"air": {"reach": 96.0, "poses": [4, 4, 4]},
		"special": {"type": "leap", "fx": "claw", "speed": 7.0, "reach": 104.0, "poses": [6, 4, 5]}},
}
## How the machine plays. react: frames before it answers what you do; guard: how often it covers up from a blow it
## sees coming; string: and from a second blow on top of the first (none: its guard comes down); press: how keen it is
## to come at you; punish: hitting you while you recover; combo: it knows the cancels; anti: swatting a jump; power:
## how readily it spends its power; hop: jumping what is thrown at it; slip: how often it just stands there; heavy: its
## liking for the strong blow.
const AI := {
	"facil": {"react": 26, "guard": 0.25, "string": 0.3, "press": 0.45, "punish": 0.2, "combo": 0.0, "anti": 0.15, "power": 0.4, "hop": 0.15, "slip": 0.30, "heavy": 0.3, "jump": 0.04},
	"normal": {"react": 20, "guard": 0.45, "string": 0.6, "press": 0.55, "punish": 0.4, "combo": 0.3, "anti": 0.3, "power": 0.6, "hop": 0.3, "slip": 0.18, "heavy": 0.35, "jump": 0.06},
	"dificil": {"react": 14, "guard": 0.65, "string": 0.85, "press": 0.65, "punish": 0.65, "combo": 0.7, "anti": 0.55, "power": 0.8, "hop": 0.45, "slip": 0.08, "heavy": 0.35, "jump": 0.07},
	# the mayor, DoomAssasin78: three times champion of Tokken 2. He covers up well and makes you pay for a miss, but
	# he plays as in the eighties: no cancels of his own, and no idea that yours are coming
	"alcalde": {"react": 17, "guard": 0.62, "string": 0.0, "press": 0.5, "punish": 0.45, "combo": 0.0, "anti": 0.4, "power": 0.7, "hop": 0.2, "slip": 0.16, "heavy": 0.55, "jump": 0.02},
	# Katakumba69: he lives in there
	"katakumba": {"react": 12, "guard": 0.72, "string": 0.9, "press": 0.7, "punish": 0.7, "combo": 0.9, "anti": 0.65, "power": 0.9, "hop": 0.5, "slip": 0.06, "heavy": 0.3, "jump": 0.07},
	# (the tests': one that stands there and does nothing; and stand-ins for somebody at the machine: one who has never
	# played, one who has found the combo)
	"quieto": {"react": 99, "guard": 0.0, "string": 0.0, "press": 0.0, "punish": 0.0, "combo": 0.0, "anti": 0.0, "power": 0.0, "hop": 0.0, "slip": 1.0, "heavy": 0.0, "jump": 0.0},
	"novato": {"react": 24, "guard": 0.3, "string": 0.35, "press": 0.6, "punish": 0.25, "combo": 0.0, "anti": 0.1, "power": 0.5, "hop": 0.15, "slip": 0.22, "heavy": 0.4, "jump": 0.08},
	"jugador": {"react": 18, "guard": 0.45, "string": 0.6, "press": 0.6, "punish": 0.5, "combo": 0.75, "anti": 0.3, "power": 0.7, "hop": 0.35, "slip": 0.12, "heavy": 0.3, "jump": 0.06},
}

class Fighter:
	var id := ""
	var d: Dictionary = {}       # FIGHTERS[id]
	var name := ""
	var tag := ""                # who is playing it
	var human := false
	var ai: Dictionary = {}
	var tint := Color.WHITE
	var half := 28.0
	var tall := 160.0
	var x := 0.0
	var y := 0.0                 # how high the feet are off the floor
	var vx := 0.0
	var vy := 0.0
	var face := 1
	var hp := 100.0
	var hp_shown := 100.0
	var guard := 100.0
	var guard_rest := 0
	var meter := 0.0
	var wins := 0
	var took := 0.0              # what this round has cost them
	var st := "idle"             # idle | jump | attack | hurt | block | down | dizzy | ko | win
	var t := 0                   # frames in it
	var stun := 0
	var land := 0                # frames of finding their feet after a jump
	var lie := 0                 # frames on the floor
	var move: Dictionary = {}
	var move_kind := ""
	var mt := 0                  # frames into the blow
	var hit_done := false
	var connected := false       # it landed, or was covered: it can be cancelled
	var lights := 0              # quick blows in a row
	var attack_id := 0
	var jump_id := 0
	var chain := 0               # blows taken in a row
	var chain_dmg := 0.0
	var combo_n := 0             # what they have just done to the other, for the screen
	var combo_dmg := 0.0
	var combo_t := 0
	var inv := 0
	var flash := 0
	var walk := 0
	var air_used := false
	var inp := {"dir": 0, "up": false, "light": false, "heavy": false, "special": false}
	var buf := {"light": 0, "heavy": 0, "special": 0}

var G
var active := false
var mute := false                # (the tests' quick matches: no sounds, no sparks)
var rng := RandomNumberGenerator.new()
var screen: Control
var a: Fighter                   # you: on the left to begin with
var b: Fighter
var shots: Array = []            # {x, h, vx, who, m, fx, t, half, ground, id}
var fx: Array = []               # {k, x, h, t, n, dir, s}
var mode := ""                   # select | versus | intro | fight | ko | time | after | end
var mode_t := 0
var round_n := 1
var round_winner: Fighter = null
var clock := ROUND_SECONDS
var clock_t := 0
var freeze := 0
var slow := 0
var dark := 0                    # frames the stage is darkened for a power
var dark_who: Fighter = null
var white := 0
var shake := 0.0
var cam := 0.0
var stage_n := 1
var banner := ""
var banner_sub := ""
var banner_t := 0
var banner_n := 1
var opts: Dictionary = {}
var pick := 0
var paused := false
var hold := false                # (the tests: everything stands still for a picture)
var won := false
var test_inp = null              # (the tests play for you: {dir, up, light, heavy, special})
var _done: Callable
var _phase_was := ""
var _acc := 0.0
var _ids := 0
var _pressed := {"light": false, "heavy": false, "special": false, "ok": false, "left": false, "right": false}
var _font: Texture2D
var _font_at: Dictionary = {}
var _art := {}                   # fighter -> {tex, face}
var _stages := {}                # n -> texture
var _icons := {}
var _tiles: Array = []           # where the portraits of the choosing screen are, for a finger or the mouse
var _view := Vector2(1280, 720)

func setup(game) -> void:
	G = game
	layer = 60
	visible = false
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	screen.draw.connect(_draw_screen)
	add_child(screen)
	rng.randomize()

func _load() -> void:
	if _font != null:
		return
	var f: Dictionary = Letras.build()
	_font = f["tex"]
	_font_at = f["at"]
	for id in ROSTER:
		_art[id] = {"tex": load(ART + id + ".png"), "face": load(ART + "cara_" + id + ".png")}
	for n in Datos.STAGES:
		_stages[n] = load(ART + "fondo_%d.png" % n)

# ================= in and out =================
## A match. o: {"foe": a fighter ("": any), "foe_tag": who is playing it, "ai": one of AI, "stage": which (0: the
## foe's own)}. `done` is called with whether you won.
func start(o: Dictionary, done: Callable) -> void:
	_load()
	opts = o
	_done = done
	active = true
	visible = true
	paused = false
	mute = false
	test_inp = null
	_phase_was = G.phase
	G.phase = "tokken"
	G.hud.set_prompt("")
	G.get_viewport().disable_3d = true           # (nothing of the town is drawn behind the machine's screen)
	pick = clampi(int(G.stats.get("tokken_pick", 0)), 0, ROSTER.size() - 1)
	a = null
	b = null
	_to("select")
	_snd("coin")

func _finish() -> void:
	active = false
	visible = false
	G.get_viewport().disable_3d = false
	G.phase = _phase_was
	_done.call(won)

func _to(m: String) -> void:
	mode = m
	mode_t = 0

## (the tests) the match is over, like this
func test_end(win: bool) -> void:
	won = win
	if a == null:
		_choose()
	_to("end")
	mode_t = 400

func touch_buttons() -> Array:
	if paused:
		return [[Loc.t("tk_resume"), "interact", "big"], [Loc.t("tk_quit"), "handbrake", ""]]
	match mode:
		"select":
			return [[Loc.t("tk_b_pick"), "interact", "big"]]
		"intro", "fight":
			# (the quick blow is the one pressed most: it gets the big button under the thumb)
			return [[Loc.t("tk_b_light"), "punch", "big"], [Loc.t("tk_b_heavy"), "interact", ""], [Loc.t("tk_b_special"), "handbrake", ""], ["II", "pause", "top"]]
	return []

func input(e: InputEvent) -> void:
	if not active:
		return
	if e.is_action_pressed("pause") and (mode == "fight" or mode == "intro" or mode == "select"):
		paused = not paused
		_snd("tick")
		return
	if paused:
		if e.is_action_pressed("interact") or e.is_action_pressed("m_accept"):
			paused = false
		elif e.is_action_pressed("handbrake") or e.is_action_pressed("m_back"):
			paused = false
			won = false
			_finish()
		return
	if mode == "select":
		var at = null
		if e is InputEventScreenTouch and e.pressed:
			at = e.position
		elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			at = e.position
		if at != null:
			for i in range(_tiles.size()):
				if (_tiles[i] as Rect2).has_point(at):
					if pick == i:
						_pressed["ok"] = true
					else:
						pick = i
						_snd("tick")
					return
			if e is InputEventScreenTouch:
				return
	if e is InputEventKey and e.pressed and not e.echo:      # (J K L too, for whoever plays with the keyboard alone)
		match e.physical_keycode:
			KEY_J:
				_pressed["light"] = true
				_pressed["ok"] = true
			KEY_K:
				_pressed["heavy"] = true
			KEY_L:
				_pressed["special"] = true
	if e.is_action_pressed("punch"):
		_pressed["light"] = true
		_pressed["ok"] = true
	if e.is_action_pressed("interact"):
		_pressed["heavy"] = true
		_pressed["ok"] = true
	if e.is_action_pressed("handbrake"):
		_pressed["special"] = true
	if e.is_action_pressed("m_accept"):
		_pressed["ok"] = true
	if (e is InputEventKey and e.is_action_pressed("left")) or e.is_action_pressed("m_left"):        # (the stick as m_* steps: controls.gd)
		_pressed["left"] = true
	if (e is InputEventKey and e.is_action_pressed("right")) or e.is_action_pressed("m_right"):
		_pressed["right"] = true

func tick(dt: float) -> void:
	if not active:
		return
	_acc += dt
	var n := 0
	while _acc >= 1.0 / 60.0 - 0.0005 and n < 3 and active:
		_acc -= 1.0 / 60.0
		n += 1
		_frame()
	if n == 3:
		_acc = 0.0
	screen.queue_redraw()

func _frame() -> void:
	if paused or hold:
		return
	mode_t += 1
	if banner_t > 0:
		banner_t -= 1
	match mode:
		"select":
			if _pressed["left"]:
				pick = (pick + ROSTER.size() - 1) % ROSTER.size()
				_snd("tick")
			if _pressed["right"]:
				pick = (pick + 1) % ROSTER.size()
				_snd("tick")
			if _pressed["ok"] and mode_t > 12:
				_choose()
		"versus":
			if mode_t == 1:
				_snd("versus")
			if mode_t > 130 or (_pressed["ok"] and mode_t > 30):
				round_n = 1
				_begin_round()
		"intro":
			_idle(a)
			_idle(b)
			_camera(true)
			if mode_t == 2:
				_banner(Loc.t("tk_final_round") if (a.wins == TO_WIN - 1 and b.wins == TO_WIN - 1) else String(Loc.t("tk_round")) % round_n, 50)
				_snd("round")
			elif mode_t == 54:
				_banner(Loc.t("tk_fight"), 36)
				_snd("fight")
			elif mode_t >= 88:
				_to("fight")
		"fight":
			_sim()
			if mode == "fight":
				clock_t += 1
				if clock_t >= CLOCK_TICK:
					clock_t = 0
					clock -= 1
					if clock <= 10 and clock > 0:
						_snd("tick")
					if clock <= 0:
						_time_up()
		"ko":
			_sim()
			if mode_t > 170:
				_round_done()
		"time":
			_sim()
			if mode_t > 90:
				_round_done()
		"after":
			_sim()
			if mode_t > 130:
				if a.wins >= TO_WIN or b.wins >= TO_WIN:
					won = a.wins > b.wins
					_to("end")
					_banner(Loc.t("tk_you_win") if won else Loc.t("tk_you_lose"), 400, a.name if won else b.name)
					_snd("win" if won else "lose")
				else:
					if round_winner != null:
						round_n += 1
					_begin_round()
		"end":
			_sim()
			if mode_t > 170 or (_pressed["ok"] and mode_t > 50):
				_finish()
	for k in _pressed:
		_pressed[k] = false

# ================= who fights =================
func _make(id: String, tag: String, human: bool, ai_name: String) -> Fighter:
	var f := Fighter.new()
	f.id = id
	f.d = FIGHTERS[id]
	f.name = String(Loc.t("tk_n_" + id)) if not mute else id
	f.tag = tag
	f.human = human
	f.half = float(f.d["half"])
	f.tall = float(f.d["tall"])
	if not human:
		f.ai = {"p": AI[ai_name], "seen": 0, "wait": 0, "answer": "", "struck": 0, "punished": 0, "punish": false, "air_seen": 0,
			"swat": false, "t": 0, "plan": "", "combo": false}
	return f

func _choose() -> void:
	var mine: String = ROSTER[pick]
	G.stats["tokken_pick"] = pick
	var theirs: String = String(opts.get("foe", ""))
	if theirs == "":
		theirs = ROSTER[rng.randi_range(0, ROSTER.size() - 1)]
	a = _make(mine, Loc.t("tk_you"), true, "")
	b = _make(theirs, String(opts.get("foe_tag", Loc.t("tk_cpu"))), false, String(opts.get("ai", "normal")))
	if mine == theirs:
		b.tint = Color(0.72, 0.86, 1.3)          # (the same one twice: theirs in another light)
	stage_n = int(opts.get("stage", 0))
	if stage_n == 0:
		stage_n = int(b.d["stage"])
	_snd("pick")
	_to("versus")

func _begin_round() -> void:
	var mid := STAGE_W / 2.0
	for f in [a, b]:
		f.hp = HP
		f.hp_shown = HP
		f.guard = GUARD
		f.guard_rest = 0
		f.took = 0.0
		f.y = 0.0
		f.vx = 0.0
		f.vy = 0.0
		f.inv = 0
		f.flash = 0
		f.land = 0
		f.combo_t = 0
		f.buf = {"light": 0, "heavy": 0, "special": 0}
		f.inp = {"dir": 0, "up": false, "light": false, "heavy": false, "special": false}
		_to_idle(f)
	a.x = mid - START_GAP / 2.0
	b.x = mid + START_GAP / 2.0
	a.face = 1
	b.face = -1
	shots.clear()
	fx.clear()
	clock = ROUND_SECONDS
	clock_t = 0
	freeze = 0
	slow = 0
	dark = 0
	white = 0
	round_winner = null
	_to("intro")
	_camera(true)

# ================= the fight =================
## one frame of it
func _sim() -> void:
	_fx_tick()
	if freeze > 0:
		freeze -= 1
		return
	if slow > 0:
		slow -= 1
		if slow % 3 != 0:
			return
	_read(a, b)
	_read(b, a)
	_step(a, b)
	_step(b, a)
	_bodies()
	_hits()
	_shots_tick()
	_check_ko()
	for f in [a, b]:
		var o: Fighter = b if f == a else a
		if f.st == "idle" and f.y <= 0.0 and o.x != f.x:
			f.face = 1 if o.x > f.x else -1
		if f.guard_rest > 0:
			f.guard_rest -= 1
		elif f.guard < GUARD:
			f.guard = minf(GUARD, f.guard + 0.3)
		if f.st != "hurt" and f.st != "block":
			f.hp_shown = move_toward(f.hp_shown, f.hp, 0.6)
		if f.combo_t > 0:
			f.combo_t -= 1
	_camera(false)

func _read(f: Fighter, o: Fighter) -> void:
	var inp := {"dir": 0, "up": false, "light": false, "heavy": false, "special": false}
	f.inp = inp
	if mode != "fight":
		return
	if not f.human:
		_ai(f, o)
		return
	if test_inp != null:
		for k in inp:
			if test_inp.has(k):
				inp[k] = test_inp[k]
		for k in ["light", "heavy", "special"]:
			test_inp[k] = false
		return
	var x: float = Input.get_axis("left", "right") + Input.get_axis("cam_left", "cam_right")
	x += float(Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT)) - float(Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT))
	inp["dir"] = 1 if x > 0.35 else (-1 if x < -0.35 else 0)
	inp["up"] = Input.get_action_strength("forward") > 0.6 or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP)
	inp["light"] = _pressed["light"]
	inp["heavy"] = _pressed["heavy"]
	inp["special"] = _pressed["special"]

func _to_idle(f: Fighter) -> void:
	f.st = "idle"
	f.t = 0
	f.move = {}
	f.move_kind = ""
	f.mt = 0
	f.vx = 0.0
	f.lights = 0
	f.chain = 0
	f.chain_dmg = 0.0

## the blow of this kind, as this fighter throws it
func blow(f: Fighter, kind: String) -> Dictionary:
	var m: Dictionary = (BASE[kind] as Dictionary).duplicate()
	m.merge(f.d[kind], true)
	m["kind"] = kind
	return m

func _begin_move(f: Fighter, kind: String, cancel := false) -> void:
	var m := blow(f, kind)
	if cancel:
		m["startup"] = mini(int(m["startup"]), CANCEL_STARTUP if kind == "heavy" else 6)
	f.move = m
	f.move_kind = kind
	f.mt = 0
	f.hit_done = String(m.get("type", "")) in ["shot", "quake"]       # (what is thrown does the hitting)
	f.connected = false
	_ids += 1
	f.attack_id = _ids
	if kind == "air":
		return
	f.st = "attack"
	f.t = 0
	f.vx = 0.0
	if kind == "special":
		f.meter = 0.0
		freeze = 26
		dark = 40
		dark_who = f
		_snd("power")
		_add_fx("ring", f.x, f.y + f.tall * 0.55, f.face, 1.0, 26)

func _step(f: Fighter, o: Fighter) -> void:
	f.t += 1
	if f.inv > 0:
		f.inv -= 1
	if f.flash > 0:
		f.flash -= 1
	for k in ["light", "heavy", "special"]:
		if f.inp[k]:
			f.buf[k] = BUFFER
		elif int(f.buf[k]) > 0:
			f.buf[k] = int(f.buf[k]) - 1
	if not f.move.is_empty():
		f.mt += 1
	var dir: int = f.inp["dir"]
	match f.st:
		"idle":
			f.y = 0.0
			f.vy = 0.0
			if f.land > 0:
				f.land -= 1
				f.vx = 0.0
				return
			if mode != "fight":
				f.vx = 0.0
				return
			if int(f.buf["special"]) > 0 and f.meter >= 100.0:
				f.buf["special"] = 0
				_begin_move(f, "special")
				return
			if int(f.buf["heavy"]) > 0:
				f.buf["heavy"] = 0
				_begin_move(f, "heavy")
				return
			if int(f.buf["light"]) > 0:
				f.buf["light"] = 0
				_begin_move(f, "light")
				return
			if f.inp["up"]:
				f.st = "jump"
				f.t = 0
				f.vy = JUMP_V
				f.vx = dir * float(f.d["speed"]) * 1.3
				f.air_used = false
				_ids += 1
				f.jump_id = _ids
				_snd("jump")
				return
			f.vx = dir * float(f.d["speed"]) * (1.0 if dir * f.face >= 0 else 0.8)
			f.x += f.vx
			f.walk = f.walk + 1 if dir != 0 else 0
		"jump":
			f.x += f.vx
			f.y += f.vy
			f.vy -= GRAVITY
			if f.move_kind == "" and not f.air_used and (int(f.buf["light"]) > 0 or int(f.buf["heavy"]) > 0):
				f.buf["light"] = 0
				f.buf["heavy"] = 0
				f.air_used = true
				_begin_move(f, "air")
				_snd("swing")
			if f.y <= 0.0 and f.vy < 0.0:
				f.y = 0.0
				var after: int = int(f.move.get("recover", 0)) if f.move_kind == "special" else 0
				_to_idle(f)
				f.land = 3 + after
				_add_fx("dust", f.x, 0.0, f.face, 1.0, 14)
				_snd("land")
		"attack":
			_step_attack(f)
		"hurt":
			f.x += f.vx
			f.vx *= 0.84
			f.stun -= 1
			if f.stun <= 0:
				_to_idle(f)
		"block":
			f.x += f.vx
			f.vx *= 0.8
			f.stun -= 1
			if f.stun <= 0:
				_to_idle(f)
		"dizzy":
			f.stun -= 1
			if f.stun <= 0:
				f.guard = GUARD * 0.6
				_to_idle(f)
		"down", "ko":
			if f.y > 0.0 or f.vy > 0.0:
				f.x += f.vx
				f.y += f.vy
				f.vy -= GRAVITY
				if f.y <= 0.0:
					f.y = 0.0
					f.vy = 0.0
					f.vx = 0.0
					f.lie = 0
					shake = maxf(shake, 5.0)
					_add_fx("dust", f.x, 0.0, f.face, 1.5, 18)
					_snd("thud")
			else:
				f.lie += 1
				if f.st == "down" and f.lie > 36:
					_to_idle(f)
					f.inv = 20

func _step_attack(f: Fighter) -> void:
	var m: Dictionary = f.move
	var s: int = m["startup"]
	var act: int = m["active"]
	var rec: int = m["recover"]
	var kind: String = m["kind"]
	var type: String = m.get("type", "")
	if f.t <= s + act:
		f.x += f.face * float(m["lunge"]) / float(s + act)
	if f.t == s + 1:                              # now it can hit
		_snd("swing" if kind == "light" else "swing_big")
		if kind == "heavy":
			_add_fx("arc", f.x, f.tall * 0.6, f.face, float(m["reach"]), 10)
		if kind == "special":
			match type:
				"shot":
					_shoot(f, m, false)
				"quake":
					_shoot(f, m, true)
					shake = maxf(shake, 9.0)
					_snd("thud")
				"leap":
					f.st = "jump"
					f.vy = 7.4
					f.vx = f.face * float(m["speed"])
					f.air_used = true
					_ids += 1
					f.jump_id = _ids
					return
				"dash":
					_add_fx("arc", f.x, f.tall * 0.6, f.face, float(m["reach"]), act + 6)
	if kind == "special" and type == "dash" and f.t > s and f.t <= s + act:
		f.x += f.face * float(m["speed"])
	if f.connected:                               # the cancels: out of a blow that landed, straight into a bigger one
		if kind == "light" and int(f.buf["heavy"]) > 0:
			f.buf["heavy"] = 0
			_begin_move(f, "heavy", true)
			return
		if (kind == "light" or kind == "heavy") and int(f.buf["special"]) > 0 and f.meter >= 100.0:
			f.buf["special"] = 0
			_begin_move(f, "special", true)
			return
		if kind == "light" and int(f.buf["light"]) > 0 and f.t > s + act and f.lights < 1:
			f.buf["light"] = 0
			var n := f.lights + 1
			_begin_move(f, "light", true)
			f.lights = n
			return
	if f.t >= s + act + rec:
		_to_idle(f)

func _shoot(f: Fighter, m: Dictionary, ground: bool) -> void:
	_ids += 1
	shots.append({"x": f.x + f.face * 50.0, "h": 0.0 if ground else f.tall * 0.58, "vx": f.face * float(m["speed"]), "who": f, "m": m,
		"fx": String(m["fx"]), "t": 0, "half": 22.0, "ground": ground, "id": _ids})
	_snd("shot")

## they do not walk through each other, off the stage or off the screen
func _bodies() -> void:
	var reach: float = _view_w() - 120.0
	for f in [a, b]:
		f.x = clampf(f.x, WALL, STAGE_W - WALL)
	if absf(a.x - b.x) > reach:
		var mid := (a.x + b.x) / 2.0
		a.x = clampf(a.x, mid - reach / 2.0, mid + reach / 2.0)
		b.x = clampf(b.x, mid - reach / 2.0, mid + reach / 2.0)
	var floored_a: bool = (a.st == "down" or a.st == "ko") and a.y <= 0.0
	var floored_b: bool = (b.st == "down" or b.st == "ko") and b.y <= 0.0
	if a.y < 50.0 and b.y < 50.0 and not floored_a and not floored_b:
		var need: float = a.half + b.half
		var dx: float = b.x - a.x
		if absf(dx) < need:
			var sgn: float = 1.0 if dx > 0.0 or (dx == 0.0 and a.face > 0) else -1.0
			var push: float = (need - absf(dx)) / 2.0
			a.x -= sgn * push
			b.x += sgn * push
			for f in [a, b]:                      # (one of them against the end of the stage: the other gives way)
				var o: Fighter = b if f == a else a
				if f.x < WALL:
					o.x += WALL - f.x
					f.x = WALL
				elif f.x > STAGE_W - WALL:
					o.x -= f.x - (STAGE_W - WALL)
					f.x = STAGE_W - WALL

func _can_be_hit(o: Fighter) -> bool:
	if o.inv > 0 or o.st == "ko" or o.st == "win":
		return false
	return not (o.st == "down" and o.y <= 0.0 and o.vy <= 0.0)

func _reaches(f: Fighter, o: Fighter, m: Dictionary) -> bool:
	if not _can_be_hit(o):
		return false
	var d: float = (o.x - f.x) * f.face
	if d < -o.half * 0.5 or d - o.half > float(m["reach"]):
		return false
	if f.st == "jump":                            # from the air: on the way down, and near enough their head
		return f.vy < 2.5 and f.y < o.y + o.tall * 0.62 and f.y + f.tall * 0.5 > o.y
	return o.y < f.y + f.tall * 0.95 and o.y + o.tall > f.y + 20.0

func _hits() -> void:
	var landing: Array = []
	for pair in [[a, b], [b, a]]:
		var f: Fighter = pair[0]
		var o: Fighter = pair[1]
		if f.move.is_empty() or f.hit_done:
			continue
		var m: Dictionary = f.move
		var on := false
		if f.st == "attack":
			on = f.t > int(m["startup"]) and f.t <= int(m["startup"]) + int(m["active"])
		elif f.st == "jump":
			on = f.mt > int(m["startup"]) or f.move_kind == "special"
		if on and _reaches(f, o, m):
			landing.append([f, o, m])
	for l in landing:                             # (both at once: a trade)
		var f: Fighter = l[0]
		f.hit_done = true
		_connect(f, l[1], l[2], f.face, null)

## a blow gets there: it lands, or they had their guard up
func _connect(f: Fighter, o: Fighter, m: Dictionary, dirn: int, shot) -> void:
	var kind: String = m["kind"]
	var at_x: float = float(shot["x"]) if shot != null else (o.x - dirn * o.half * 0.6)
	var at_h: float = o.y + o.tall * (0.25 if (shot != null and shot["ground"]) else 0.62)
	var holding: bool = int(o.inp["dir"]) * o.face < 0
	if (o.st == "idle" or o.st == "block") and o.y <= 0.0 and holding and o.guard > 0.0:
		o.st = "block"
		o.t = 0
		o.stun = int(m["blockstun"])
		o.vx = dirn * float(m["push"]) * 0.7
		o.move = {}
		o.move_kind = ""
		if mode == "fight":
			o.hp = maxf(1.0, o.hp - float(m.get("chip", 0.0)))
			o.guard -= float(m["guard"])
			o.guard_rest = 100
			f.meter = minf(100.0, f.meter + 2.0)
			o.meter = minf(100.0, o.meter + 3.0)
		f.connected = true
		freeze = maxi(freeze, 3)
		_add_fx("guard", at_x, at_h, dirn, 1.0, 10)
		_snd("block")
		if o.guard <= 0.0:                        # too much of that: the guard breaks
			o.guard = 0.0
			o.st = "dizzy"
			o.stun = 80
			o.vx = 0.0
			_banner(Loc.t("tk_guard_break"), 50, "", 2)
			_snd("break")
		return
	var dmg: float = float(m["dmg"]) * float(f.d["power"]) / float(o.d["tough"]) * pow(CHAIN_SCALE, o.chain)
	if mode != "fight":
		dmg = 0.0
	o.hp = maxf(0.0, o.hp - dmg)
	o.took += dmg
	o.chain += 1
	o.chain_dmg += dmg
	f.combo_n = o.chain
	f.combo_dmg = o.chain_dmg
	f.combo_t = 80
	f.connected = true
	if kind != "special":
		f.meter = minf(100.0, f.meter + dmg * 2.0)
	o.meter = minf(100.0, o.meter + dmg * 1.2)
	freeze = maxi(freeze, int(m["stop"]))
	shake = maxf(shake, 3.0 if kind == "light" else (6.0 if kind != "special" else 9.0))
	o.flash = 6
	o.move = {}
	o.move_kind = ""
	o.t = 0
	_add_fx("spark", at_x, at_h, dirn, 1.0 if kind == "light" else 1.5, 9)
	_snd("hit" if kind == "light" else ("hit_big" if kind != "special" else "hit_power"))
	if kind == "special" or o.y > 0.0 or o.st == "jump" or o.hp <= 0.0 or o.st == "down":
		o.st = "down"                             # off their feet
		o.vy = 6.2 if o.hp > 0.0 else 7.6
		o.vx = dirn * (3.2 if o.hp > 0.0 else 3.8)
		o.y = maxf(o.y, 0.5)
		o.lie = 0
	else:
		o.st = "hurt"
		o.stun = int(m["hitstun"])
		o.vx = dirn * float(m["push"])

func _shots_tick() -> void:
	for s in shots.duplicate():
		s["t"] = int(s["t"]) + 1
		s["x"] = float(s["x"]) + float(s["vx"])
		if float(s["x"]) < -60.0 or float(s["x"]) > STAGE_W + 60.0 or int(s["t"]) > 170:
			shots.erase(s)
			continue
		var f: Fighter = s["who"]
		var o: Fighter = b if f == a else a
		if not _can_be_hit(o) or absf(float(s["x"]) - o.x) > float(s["half"]) + o.half:
			continue
		if o.y < (26.0 if s["ground"] else float(s["h"]) - 20.0):      # (jumped: it goes by underneath)
			_connect(f, o, s["m"], 1 if float(s["vx"]) > 0.0 else -1, s)
			shots.erase(s)
	if shots.size() == 2 and shots[0]["who"] != shots[1]["who"] and not shots[0]["ground"] and not shots[1]["ground"] \
			and absf(float(shots[0]["x"]) - float(shots[1]["x"])) < 40.0:      # two of them meet: neither gets through
		_add_fx("spark", (float(shots[0]["x"]) + float(shots[1]["x"])) / 2.0, float(shots[0]["h"]), 1, 1.6, 10)
		_snd("block")
		shots.clear()

func _check_ko() -> void:
	if mode != "fight":
		return
	var gone_a := a.hp <= 0.0
	var gone_b := b.hp <= 0.0
	if not gone_a and not gone_b:
		return
	for f in [a, b]:
		if f.hp <= 0.0:
			f.st = "ko"
			f.t = 0
			if f.y <= 0.0 and f.vy <= 0.0:
				f.vy = 7.6
				f.vx = -f.face * 3.8
				f.y = 0.5
	round_winner = null if (gone_a and gone_b) else (b if gone_a else a)
	shots.clear()
	_to("ko")
	slow = 60
	freeze = 16
	white = 12
	shake = 12.0
	_banner(Loc.t("tk_ko"), 150, "", 1)
	_snd("ko")

func _time_up() -> void:
	round_winner = null if absf(a.hp - b.hp) < 0.01 else (a if a.hp > b.hp else b)
	shots.clear()
	_to("time")
	_banner(Loc.t("tk_time"), 90)
	_snd("round")

func _round_done() -> void:
	if round_winner != null:
		round_winner.wins += 1
		if round_winner.st == "idle" or round_winner.st == "attack":
			_to_idle(round_winner)
			round_winner.st = "win"
		_banner(String(Loc.t("tk_wins")) % round_winner.name, 120, Loc.t("tk_perfect") if round_winner.took <= 0.0 else "")
		_snd("win" if round_winner == a else "lose")
	else:
		_banner(Loc.t("tk_draw"), 120)
	_to("after")

func _idle(f: Fighter) -> void:
	f.t += 1

# ================= the machine's own player =================
func _shot_at(f: Fighter) -> Variant:
	for s in shots:
		if s["who"] != f and (f.x - float(s["x"])) * float(s["vx"]) > 0.0 and absf(f.x - float(s["x"])) < 200.0:
			return s
	return null

func _ai(f: Fighter, o: Fighter) -> void:
	var A: Dictionary = f.ai
	var P: Dictionary = A["p"]
	var inp: Dictionary = f.inp
	var away: int = -f.face
	var dist: float = absf(o.x - f.x)
	var r_light: float = float(blow(f, "light")["reach"]) + o.half
	var r_heavy: float = float(blow(f, "heavy")["reach"]) + o.half
	if int(A["struck"]) > 0:
		A["struck"] = int(A["struck"]) - 1
	if f.st == "block" or f.st == "hurt":
		A["struck"] = 26
	# --- what is coming ---
	var threat := 0                               # 1: a blow, 2: something thrown
	if (o.st == "attack" or (o.st == "jump" and o.move_kind != "")) and not o.hit_done and not o.move.is_empty():
		var m: Dictionary = o.move
		var far: float = float(m["reach"]) + f.half + 26.0
		var type: String = m.get("type", "")
		if type == "dash":
			far += float(m["speed"]) * float(m["active"])
		if type == "leap" or o.st == "jump":
			far += 110.0
		if dist <= far:
			threat = 1
	var shot: Variant = _shot_at(f)
	if threat == 0 and shot != null:
		threat = 2
	var seen: int = o.attack_id if threat == 1 else (int(shot["id"]) if threat == 2 else 0)
	if threat != 0 and seen != int(A["seen"]):
		A["seen"] = seen
		A["wait"] = int(P["react"]) + rng.randi_range(0, 5)
		var pressed: bool = int(A["struck"]) > 0                  # (a second blow on top of the first)
		var p_block: float = float(P["string"]) if pressed else float(P["guard"])
		A["answer"] = "block" if rng.randf() < p_block else ("drop" if pressed else "")
		if threat == 2 and rng.randf() < float(P["hop"]):
			A["answer"] = "jump"
	if threat != 0:
		if A["answer"] == "drop":                 # the guard comes down: "that was it, wasn't it?"
			return
		if int(A["wait"]) > 0:
			A["wait"] = int(A["wait"]) - 1
		elif A["answer"] == "block":
			inp["dir"] = away
			return
		elif A["answer"] == "jump" and threat == 2 and f.st == "idle" and absf(float(shot["x"]) - f.x) < 70.0 + absf(float(shot["vx"])) * 7.0:
			inp["up"] = true
			inp["dir"] = f.face
			return
	if f.st == "attack":                          # in the middle of a blow of its own: the cancels, if it knows them
		if f.connected and bool(A["combo"]):
			if f.move["kind"] == "light":
				inp["heavy"] = true
			elif f.move["kind"] == "heavy" and f.meter >= 100.0:
				inp["special"] = true
		return
	if f.st == "jump":
		if A["plan"] == "air" and f.vy < -1.0 and dist < 120.0:
			inp["heavy"] = true
		return
	if f.st != "idle":
		return
	# --- chances ---
	if o.st == "dizzy":
		if dist <= r_heavy - 10.0:
			inp["heavy"] = true
			A["combo"] = false
		else:
			inp["dir"] = f.face
		return
	if o.st == "attack" and not o.move.is_empty() and o.t > int(o.move["startup"]) + int(o.move["active"]):      # they missed, or it was covered
		if int(A["punished"]) != o.attack_id:
			A["punished"] = o.attack_id
			A["punish"] = rng.randf() < float(P["punish"])
		if bool(A["punish"]):
			var left: int = int(o.move["startup"]) + int(o.move["active"]) + int(o.move["recover"]) - o.t
			if dist <= r_light - 6.0:
				inp["light"] = true
				A["combo"] = rng.randf() < float(P["combo"])
			elif dist <= r_heavy - 8.0 and left >= int(blow(f, "heavy")["startup"]) - 2:
				inp["heavy"] = true
				A["combo"] = rng.randf() < float(P["combo"])
			else:
				inp["dir"] = f.face
			return
	if o.st == "jump" and o.y > 24.0 and dist < r_light + 40.0:       # they come through the air
		if int(A["air_seen"]) != o.jump_id:
			A["air_seen"] = o.jump_id
			A["swat"] = rng.randf() < float(P["anti"])
		if bool(A["swat"]):
			if o.vy < 2.0 and dist <= r_light:
				inp["light"] = true
				A["combo"] = false
			return
	# --- and otherwise, what it had in mind ---
	A["t"] = int(A["t"]) - 1
	if int(A["t"]) <= 0:
		_ai_plan(f, o, A, P, dist, r_light, r_heavy)
	match String(A["plan"]):
		"in":
			inp["dir"] = f.face
		"out":
			inp["dir"] = away
		"light":
			if dist <= r_light - 6.0:
				inp["light"] = true
				A["combo"] = rng.randf() < float(P["combo"])
				A["plan"] = ""
				A["t"] = 8
			else:
				inp["dir"] = f.face
		"heavy":
			if dist <= r_heavy - 10.0:
				inp["heavy"] = true
				A["combo"] = rng.randf() < float(P["combo"])
				A["plan"] = ""
				A["t"] = 10
			else:
				inp["dir"] = f.face
		"power":
			inp["special"] = true
			A["plan"] = ""
			A["t"] = 6
		"jump":
			inp["up"] = true
			inp["dir"] = f.face
			A["plan"] = "air"
			A["t"] = 50

func _ai_plan(f: Fighter, o: Fighter, A: Dictionary, P: Dictionary, dist: float, r_light: float, r_heavy: float) -> void:
	A["plan"] = ""
	if rng.randf() < float(P["slip"]):
		A["t"] = rng.randi_range(18, 40)
		return
	var r := rng.randf()
	var hb: float = float(P["heavy"])
	var thrown: bool = String(f.d["special"]["type"]) in ["shot", "quake"]
	if o.st == "down" or o.st == "ko":
		A["plan"] = "out" if dist < r_heavy else ""
		A["t"] = rng.randi_range(8, 16)
	elif dist > r_heavy + 30.0:                    # far off
		if f.meter >= 100.0 and r < float(P["power"]) * (0.6 if thrown else 0.3) and dist < 420.0:
			A["plan"] = "power"
		elif r < float(P["press"]):
			A["plan"] = "in"
			A["t"] = rng.randi_range(14, 34)
		elif r < float(P["press"]) + float(P["jump"]) and dist < 260.0:
			A["plan"] = "jump"
		elif r < 0.93:
			A["t"] = rng.randi_range(10, 24)
		else:
			A["plan"] = "out"
			A["t"] = rng.randi_range(10, 20)
	elif dist > r_light:                           # within reach of the strong blow
		if f.meter >= 100.0 and r < float(P["power"]) * 0.3:
			A["plan"] = "power"
		elif r < hb:
			A["plan"] = "heavy"
			A["t"] = 22
		elif r < hb + 0.3:
			A["plan"] = "light"
			A["t"] = 28
		elif r < hb + 0.45:
			A["plan"] = "out"
			A["t"] = rng.randi_range(8, 18)
		else:
			A["t"] = rng.randi_range(6, 16)
	else:                                          # toe to toe
		if r < 0.5:
			A["plan"] = "light"
			A["t"] = 12
		elif r < 0.5 + hb * 0.5:
			A["plan"] = "heavy"
			A["t"] = 12
		elif r < 0.9:
			A["plan"] = "out"
			A["t"] = rng.randi_range(10, 22)
		else:
			A["t"] = rng.randi_range(6, 12)

## (the tests) a whole match between two of the machine's own players, without a screen: {won: the first one did,
## rounds, frames}
func sim(id_a: String, ai_a: String, id_b: String, ai_b: String, seed_n: int) -> Dictionary:
	var was := [mute, mode, a, b, opts]
	mute = true
	rng.seed = seed_n
	a = _make(id_a, "a", false, ai_a)
	b = _make(id_b, "b", false, ai_b)
	_view = Vector2(1280, 720)
	var frames := 0
	var rounds := 0
	while a.wins < TO_WIN and b.wins < TO_WIN and rounds < 9:
		_begin_round()
		mode = "fight"
		rounds += 1
		var n := 0
		while mode == "fight" and n < ROUND_SECONDS * CLOCK_TICK:
			_sim()
			n += 1
		frames += n
		if mode == "fight":
			round_winner = null if absf(a.hp - b.hp) < 0.01 else (a if a.hp > b.hp else b)
		if round_winner != null:
			round_winner.wins += 1
	var out := {"won": a.wins > b.wins, "rounds": rounds, "frames": frames}
	mute = was[0]
	mode = was[1]
	a = was[2]
	b = was[3]
	opts = was[4]
	shots.clear()
	fx.clear()
	rng.randomize()
	return out

# ================= sparks and noises =================
func _add_fx(k: String, x: float, h: float, dirn: int, s: float, n: int) -> void:
	if not mute:
		fx.append({"k": k, "x": x, "h": h, "dir": dirn, "s": s, "n": n, "t": 0})

func _fx_tick() -> void:
	for e in fx.duplicate():
		e["t"] = int(e["t"]) + 1
		if int(e["t"]) >= int(e["n"]):
			fx.erase(e)
	shake = maxf(0.0, shake - 0.7)
	if dark > 0:
		dark -= 1
	if white > 0:
		white -= 1

func _banner(text, frames: int, sub = "", size := 0) -> void:
	if mute:
		return
	banner = String(text)
	banner_sub = String(sub)
	banner_t = frames
	banner_n = frames
	set_meta("banner_size", size)

func _snd(k: String) -> void:
	if mute:
		return
	match k:
		"coin":
			Sfx.beep(988.0, 0.07, 0, -14.0)
			get_tree().create_timer(0.08).timeout.connect(Sfx.beep.bind(1319.0, 0.3, 0, -14.0))
		"tick":
			Sfx.beep(880.0, 0.04, 0, -18.0)
		"pick":
			Sfx.jingle([659, 880, 1319], 0.07)
		"versus":
			Sfx.beep(110.0, 0.5, 3, -12.0, 60.0)
			Sfx.noise(0.3, -14.0)
		"round":
			Sfx.beep(1568.0, 0.7, 2, -8.0)
			Sfx.beep(2349.0, 0.5, 1, -16.0)
		"fight":
			Sfx.beep(392.0, 0.12, 0, -10.0)
			get_tree().create_timer(0.1).timeout.connect(Sfx.beep.bind(784.0, 0.35, 0, -9.0))
		"jump":
			Sfx.beep(300.0, 0.1, 1, -18.0, 300.0)
		"land":
			Sfx.noise(0.05, -22.0)
		"swing":
			Sfx.beep(520.0, 0.06, 4, -20.0)
		"swing_big":
			Sfx.beep(300.0, 0.12, 4, -15.0)
		"hit":
			Sfx.noise(0.08, -10.0)
			Sfx.beep(190.0, 0.08, 0, -11.0, -70.0)
		"hit_big":
			Sfx.noise(0.14, -7.0)
			Sfx.beep(140.0, 0.16, 0, -8.0, -70.0)
		"hit_power":
			Sfx.noise(0.3, -5.0)
			Sfx.beep(110.0, 0.3, 3, -7.0, -60.0)
			Sfx.beep(880.0, 0.25, 0, -14.0, -700.0)
		"block":
			Sfx.beep(240.0, 0.06, 1, -12.0)
			Sfx.noise(0.04, -18.0)
		"break":
			Sfx.beep(1200.0, 0.3, 3, -9.0, -1000.0)
			Sfx.noise(0.2, -10.0)
		"power":
			Sfx.beep(220.0, 0.45, 3, -9.0, 900.0)
			Sfx.beep(440.0, 0.45, 0, -14.0, 1300.0)
		"shot":
			Sfx.beep(700.0, 0.2, 3, -12.0, -400.0)
		"thud":
			Sfx.noise(0.18, -9.0)
			Sfx.beep(70.0, 0.2, 2, -8.0)
		"ko":
			Sfx.noise(0.5, -5.0)
			Sfx.beep(196.0, 0.9, 3, -7.0, -150.0)
			get_tree().create_timer(0.5).timeout.connect(Sfx.beep.bind(1568.0, 0.9, 2, -7.0))
		"win":
			Sfx.jingle([523, 659, 784, 1047, 1319], 0.11)
		"lose":
			Sfx.jingle([392, 330, 262, 196], 0.14)

# ================= the screen =================
func _view_w() -> float:
	return _view.x / (_view.y / VIEW_H)

func _camera(snap: bool) -> void:
	var w := _view_w()
	var want: float = clampf((a.x + b.x) / 2.0 - w / 2.0, 0.0, STAGE_W - w)
	cam = want if snap else lerpf(cam, want, 0.18)

func _floor() -> float:
	return float(Datos.STAGES[stage_n]["floor"])

## where on the screen a spot of the stage is: `x` along it, `h` up from the floor
func _px(x: float, h: float) -> Vector2:
	var s := _view.y / VIEW_H
	return Vector2((x - cam) * s, (_floor() - h) * s)

func _pose(f: Fighter) -> int:
	var idle: Array = f.d["idle"]
	match f.st:
		"jump":
			return int(f.move["poses"][1]) if f.move_kind != "" else int(f.d["jump"])
		"attack":
			var m: Dictionary = f.move
			var p: Array = m["poses"]
			return int(p[0]) if f.t <= int(m["startup"]) else (int(p[1]) if f.t <= int(m["startup"]) + int(m["active"]) else int(p[2]))
		"hurt", "down", "ko", "dizzy":
			return int(f.d["hurt"])
		"block":
			return int(f.d["guard"])
	return int(idle[(f.t / (7 if f.walk > 0 else 11)) % idle.size()])

func _draw_screen() -> void:
	if not active:
		return
	_view = screen.size
	screen.draw_rect(Rect2(Vector2.ZERO, _view), Color.BLACK)
	match mode:
		"select":
			_draw_select()
		"versus":
			_draw_versus()
		_:
			_draw_fight()
	if paused:
		screen.draw_rect(Rect2(Vector2.ZERO, _view), Color(0.03, 0.01, 0.08, 0.78))
		_text(Loc.t("tk_pause"), Vector2(_view.x / 2.0, _view.y * 0.3), 9.0, Color(1.0, 0.85, 0.2), 1)
		_hint_row([["interact", Loc.t("tk_resume")], ["handbrake", Loc.t("tk_quit")]], _view.y * 0.55, 3.0)

func _draw_sprite(f: Fighter, at: Vector2, pose: int, k: float, rot: float, col: Color, flip: int) -> void:
	var D: Dictionary = Datos.FIGHTERS[f.id]
	var cell: Vector2 = D["cell"]
	var foot: Vector2 = D["foot"]
	screen.draw_set_transform(at, rot, Vector2(flip * k, k))
	screen.draw_texture_rect_region(_art[f.id]["tex"], Rect2(-foot, cell), Rect2(pose * cell.x, 0.0, cell.x, cell.y), col)
	screen.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_fighter(f: Fighter) -> void:
	var s := _view.y / VIEW_H
	var feet := _px(f.x, 0.0)
	var squat := clampf(1.0 - f.y / 240.0, 0.45, 1.0)
	screen.draw_set_transform(feet + Vector2(0.0, 3.0 * s), 0.0, Vector2(1.0, 0.2))
	screen.draw_circle(Vector2.ZERO, f.half * 1.5 * s * squat, Color(0.02, 0.0, 0.06, 0.42))
	screen.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var rot := 0.0
	var lift := 0.0
	match f.st:
		"hurt":
			rot = -0.12 * f.face * minf(1.0, f.stun / 8.0)
		"down", "ko":
			if f.y > 0.0 or f.vy > 0.0:
				rot = -f.face * minf(1.5, f.t * 0.1)
			else:
				var up := clampf((f.lie - 24) / 12.0, 0.0, 1.0) if f.st == "down" else 0.0      # getting up again
				rot = -f.face * (PI / 2.0) * (1.0 - up)
				lift = f.half * 0.8 * (1.0 - up)
		"dizzy":
			rot = sin(f.t * 0.22) * 0.09
		"win":
			lift = absf(sin(f.t * 0.16)) * 9.0
		"block":
			rot = -0.05 * f.face
	var col := f.tint
	if f.flash > 0:
		col = Color(3.0, 3.0, 3.0)
	elif f.inv > 0 and f.st == "idle" and (f.inv / 3) % 2 == 0:
		col.a = 0.5
	var at := _px(f.x, f.y + lift)
	if f.st == "hurt" and freeze > 0:
		at.x += (2.0 if (freeze % 2) == 0 else -2.0) * s
	var pose := _pose(f)
	var fast: bool = not f.move.is_empty() and String(f.move.get("type", "")) in ["dash", "leap"] and (f.st == "jump" or f.t > int(f.move["startup"]))
	if fast:                                      # the samurai's charge, the raptor's pounce: what they leave behind
		for g in range(3, 0, -1):
			_draw_sprite(f, at - Vector2(f.face * g * 16.0 * s, 0.0), pose, s, rot, Color(col.r, col.g, col.b, 0.22), f.face)
	_draw_sprite(f, at, pose, s, rot, col, f.face)
	if f.st == "dizzy":
		for i in range(3):
			var ang := f.t * 0.16 + i * TAU / 3.0
			_star(_px(f.x, f.tall + 14.0) + Vector2(cos(ang) * 26.0, sin(ang) * 8.0) * s, 6.0 * s, 2.6 * s, 5, ang, Color(1.0, 0.9, 0.2))

func _star(c: Vector2, r1: float, r2: float, n: int, turn: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(n * 2):
		var ang := turn + i * PI / n
		pts.append(c + Vector2(cos(ang), sin(ang)) * (r1 if i % 2 == 0 else r2))
	screen.draw_colored_polygon(pts, col)

func _draw_fx(e: Dictionary) -> void:
	var s := _view.y / VIEW_H
	var k: float = float(e["t"]) / float(e["n"])
	var c := _px(float(e["x"]), float(e["h"]))
	var size: float = float(e["s"])
	match String(e["k"]):
		"spark":
			var r := (16.0 + 26.0 * k) * size * s
			_star(c, r, r * 0.38, 8, float(e["t"]) * 0.3, Color(1.0, 0.75, 0.15, 1.0 - k * 0.6))
			_star(c, r * 0.62, r * 0.25, 8, float(e["t"]) * 0.3 + 0.4, Color(1.0, 1.0, 0.85, 1.0 - k * 0.4))
		"guard":
			var r2 := (10.0 + 16.0 * k) * s
			screen.draw_arc(c, r2, 0.0, TAU, 20, Color(0.6, 0.85, 1.0, 1.0 - k), 3.0 * s)
			_star(c, r2 * 0.6, r2 * 0.25, 4, 0.78, Color(0.9, 0.97, 1.0, 1.0 - k))
		"dust":
			for i in range(3):
				screen.draw_circle(c + Vector2((i - 1) * 14.0 * (0.5 + k) * size, -4.0 * k * (1 + i % 2)) * s, (5.0 + 5.0 * k) * size * s, Color(0.85, 0.8, 0.75, 0.5 * (1.0 - k)))
		"arc":
			var dirn: int = e["dir"]
			var mid := 0.0 if dirn > 0 else PI
			var sweep := 1.25
			var from := mid - sweep + k * 0.5
			var to := mid + sweep * (1.0 - k * 0.2)
			var rr := size * 0.78 * s
			screen.draw_arc(c, rr, from, to, 18, Color(1.0, 0.6, 0.7, 0.55 * (1.0 - k)), 11.0 * s)
			screen.draw_arc(c, rr, from + 0.15, to - 0.1, 18, Color(1.0, 1.0, 1.0, 0.9 * (1.0 - k)), 5.0 * s)
		"ring":
			for i in range(14):
				var ang := i * TAU / 14.0 + float(e["t"]) * 0.05
				var v := Vector2(cos(ang), sin(ang))
				screen.draw_line(c + v * (30.0 + 90.0 * k) * s, c + v * (70.0 + 220.0 * k) * s, Color(1.0, 1.0, 1.0, 0.7 * (1.0 - k)), 2.0 * s)
			screen.draw_arc(c, (20.0 + 110.0 * k) * s, 0.0, TAU, 28, Color(1.0, 0.95, 0.6, 0.8 * (1.0 - k)), 4.0 * s)

func _draw_shot(sh: Dictionary) -> void:
	var s := _view.y / VIEW_H
	var t: int = sh["t"]
	var c := _px(float(sh["x"]), float(sh["h"]))
	var dirn := 1.0 if float(sh["vx"]) > 0.0 else -1.0
	match String(sh["fx"]):
		"orb":                                    # Cleopatra's
			for i in range(4):
				screen.draw_circle(c - Vector2(dirn * i * 13.0 * s, 0.0), (15.0 - i * 3.0) * s, Color(0.75, 0.2, 1.0, 0.5 - i * 0.1))
			screen.draw_circle(c, 15.0 * s, Color(0.8, 0.25, 1.0))
			screen.draw_circle(c, 10.0 * s, Color(1.0, 0.65, 1.0))
			screen.draw_circle(c, 5.0 * s, Color.WHITE)
			screen.draw_arc(c, (21.0 + sin(t * 0.5) * 3.0) * s, t * 0.3, t * 0.3 + 4.4, 14, Color(1.0, 0.5, 1.0, 0.9), 2.5 * s)
		"wave":                                   # Napoleon's
			var mid := 0.0 if dirn > 0.0 else PI
			screen.draw_arc(c - Vector2(dirn * 26.0 * s, 0.0), 38.0 * s, mid - 1.1, mid + 1.1, 16, Color(0.2, 0.5, 1.0, 0.9), 12.0 * s)
			screen.draw_arc(c - Vector2(dirn * 26.0 * s, 0.0), 40.0 * s, mid - 0.9, mid + 0.9, 16, Color(0.8, 0.95, 1.0), 5.0 * s)
			screen.draw_arc(c - Vector2(dirn * 44.0 * s, 0.0), 34.0 * s, mid - 0.8, mid + 0.8, 12, Color(0.3, 0.6, 1.0, 0.4), 6.0 * s)
		"bats":                                   # Dracula's
			screen.draw_circle(c, 36.0 * s, Color(1.0, 0.08, 0.2, 0.28))
			screen.draw_circle(c, 24.0 * s, Color(1.0, 0.25, 0.3, 0.3))
			for i in range(6):
				var o := Vector2(cos(i * 2.4 + t * 0.13) * 24.0, sin(i * 1.7 + t * 0.21) * 18.0) * s
				var flap := sin(t * 0.9 + i) * 6.0 * s
				var p := c + o
				for pass_n in range(2):               # (a red edge round each, then the bat)
					var g := (1.35 if pass_n == 0 else 1.0) * s
					var body := Color(1.0, 0.2, 0.3) if pass_n == 0 else Color(0.1, 0.0, 0.05)
					screen.draw_colored_polygon(PackedVector2Array([p, p + Vector2(-13.0 * g, -5.0 * g + flap), p + Vector2(-7.0 * g, 4.0 * g)]), body)
					screen.draw_colored_polygon(PackedVector2Array([p, p + Vector2(13.0 * g, -5.0 * g + flap), p + Vector2(7.0 * g, 4.0 * g)]), body)
				screen.draw_circle(p, 3.2 * s, Color(0.1, 0.0, 0.05))
				screen.draw_circle(p + Vector2(dirn * 1.4, -0.6) * s, 1.3 * s, Color(1.0, 0.9, 0.3))
		"bolt":                                   # the monster's: along the floor
			screen.draw_circle(c - Vector2(0.0, 6.0 * s), 30.0 * s, Color(1.0, 0.95, 0.4, 0.22))
			for g in range(4):
				var pts := PackedVector2Array()
				var x0 := c.x - dirn * g * 18.0 * s
				for i in range(9):
					pts.append(Vector2(x0 + (((i * 7 + t * 3 + g * 5) % 11) - 5.0) * 3.2 * s, c.y - i * (15.0 - g * 2.5) * s))
				screen.draw_polyline(pts, Color(0.35, 0.6, 1.0, 0.7 - g * 0.15), (9.0 - g * 1.5) * s)
				screen.draw_polyline(pts, Color(1.0, 0.95, 0.4, 1.0 - g * 0.2), (5.0 - g) * s)
				screen.draw_polyline(pts, Color(1.0, 1.0, 1.0, 1.0 - g * 0.2), 2.0 * s)
			screen.draw_circle(c, 11.0 * s, Color(1.0, 1.0, 0.75, 0.9))

func _draw_fight() -> void:
	if a == null:
		return
	var s := _view.y / VIEW_H
	var w := _view_w()
	var jolt := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake * s * 0.5
	screen.draw_texture_rect_region(_stages[stage_n], Rect2(jolt, _view), Rect2(cam, 0.0, w, VIEW_H))
	if dark > 0:
		screen.draw_rect(Rect2(Vector2.ZERO, _view), Color(0.02, 0.0, 0.1, 0.62 * minf(1.0, dark / 10.0)))
	var back: Fighter = a if (a.st == "hurt" or a.st == "down" or a.st == "ko" or b.st == "attack") else b
	var front: Fighter = b if back == a else a
	_draw_fighter(back)
	_draw_fighter(front)
	for sh in shots:
		_draw_shot(sh)
	for e in fx:
		_draw_fx(e)
	if white > 0:
		screen.draw_rect(Rect2(Vector2.ZERO, _view), Color(1, 1, 1, 0.8 * white / 12.0))
	_draw_hud()
	if banner_t > 0:
		_draw_banner()
	if not Touch.on and (mode == "intro" or (mode == "fight" and round_n == 1 and clock > 90)):
		var ui := _view.y / 720.0
		_text("← → " + String(Loc.t("tk_h_move")) + "   ↑ " + String(Loc.t("tk_h_jump")) + "   " + String(Loc.t("tk_h_block")), Vector2(_view.x / 2.0, _view.y - 82.0 * ui), 2.0, Color(1, 1, 1, 0.92), 1)
		_hint_row([["punch", Loc.t("tk_h_light")], ["interact", Loc.t("tk_h_heavy")], ["handbrake", Loc.t("tk_h_special")]], _view.y - 56.0 * ui, 2.0)
		_text(Loc.t("tk_h_combo"), Vector2(_view.x / 2.0, _view.y - 26.0 * ui), 2.0, Color(1.0, 0.9, 0.3), 1)

func _bar(r: Rect2, frac: float, shown: float, to_left: bool, top: Color, low: Color) -> void:
	var ui := _view.y / 720.0
	screen.draw_rect(r.grow(4.0 * ui), Color(0.07, 0.04, 0.12))
	screen.draw_rect(r.grow(2.0 * ui), Color(0.86, 0.84, 0.92))
	screen.draw_rect(r, Color(0.25, 0.04, 0.08))
	for pass_n in range(2):
		var k: float = clampf(shown if pass_n == 0 else frac, 0.0, 1.0)
		var part := Rect2(r.position + Vector2(r.size.x * (1.0 - k) if to_left else 0.0, 0.0), Vector2(r.size.x * k, r.size.y))
		if pass_n == 0:
			screen.draw_rect(part, Color(1.0, 0.95, 0.75))
		else:
			screen.draw_rect(part, low)
			screen.draw_rect(Rect2(part.position, Vector2(part.size.x, part.size.y * 0.62)), top)
			screen.draw_rect(Rect2(part.position + Vector2(0.0, part.size.y * 0.12), Vector2(part.size.x, part.size.y * 0.16)), top.lightened(0.45))

func _draw_hud() -> void:
	var ui := _view.y / 720.0
	var cx := _view.x / 2.0
	for i in range(2):
		var f: Fighter = a if i == 0 else b
		var left := i == 0
		var face: Texture2D = _art[f.id]["face"]
		var fs := face.get_size() * 1.5 * ui
		var fx0 := 16.0 * ui if left else _view.x - 16.0 * ui - fs.x
		screen.draw_rect(Rect2(fx0 - 3.0 * ui, 11.0 * ui, fs.x + 6.0 * ui, fs.y + 6.0 * ui), Color(0.07, 0.04, 0.12))
		if left:
			screen.draw_texture_rect(face, Rect2(fx0, 14.0 * ui, fs.x, fs.y), false, f.tint)
		else:                                     # (theirs looks the other way)
			screen.draw_set_transform(Vector2(fx0 + fs.x, 14.0 * ui), 0.0, Vector2(-1.0, 1.0))
			screen.draw_texture_rect(face, Rect2(Vector2.ZERO, fs), false, f.tint)
			screen.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var bx0 := fx0 + fs.x + 12.0 * ui if left else cx + 62.0 * ui
		var bx1 := cx - 62.0 * ui if left else fx0 - 12.0 * ui
		var bar := Rect2(bx0, 24.0 * ui, bx1 - bx0, 28.0 * ui)
		var frac := f.hp / HP
		var danger := frac < 0.25 and (Engine.get_physics_frames() / 8) % 2 == 0
		_bar(bar, frac, f.hp_shown / HP, left, Color(1.0, 0.35, 0.2) if danger else (Color(0.95, 0.8, 0.15) if frac < 0.5 else Color(0.35, 0.92, 0.2)),
			Color(0.6, 0.12, 0.08) if danger else (Color(0.65, 0.5, 0.05) if frac < 0.5 else Color(0.16, 0.6, 0.1)))
		var name := (f.tag + " - " + f.name) if left else (f.name + " - " + f.tag)
		_text(name, Vector2(bar.position.x if left else bar.end.x, 60.0 * ui), 2.0, Color.WHITE, 0 if left else 2)
		# the power, and the guard under it
		var pw := bar.size.x * 0.55
		var pr := Rect2(bar.position.x if left else bar.end.x - pw, 86.0 * ui, pw, 11.0 * ui)
		var full := f.meter >= 100.0
		var glow := full and (Engine.get_physics_frames() / 6) % 2 == 0
		_bar(pr, f.meter / 100.0, f.meter / 100.0, not left, Color(1.0, 1.0, 0.6) if glow else Color(0.35, 0.65, 1.0), Color(0.9, 0.6, 0.1) if glow else Color(0.15, 0.3, 0.75))
		if full:
			_text(Loc.t("tk_power_ready"), Vector2(pr.end.x + 10.0 * ui if left else pr.position.x - 10.0 * ui, 82.0 * ui), 2.0, Color(1.0, 0.95, 0.3) if glow else Color.WHITE, 0 if left else 2)
		var gw := bar.size.x * 0.34
		var gr := Rect2(bar.position.x if left else bar.end.x - gw, 106.0 * ui, gw, 5.0 * ui)
		screen.draw_rect(gr.grow(2.0 * ui), Color(0.07, 0.04, 0.12))
		var gk := f.guard / GUARD
		screen.draw_rect(Rect2(gr.position + Vector2(0.0 if left else gr.size.x * (1.0 - gk), 0.0), Vector2(gr.size.x * gk, gr.size.y)), Color(0.9, 0.3, 0.25) if gk < 0.35 else Color(0.7, 0.78, 0.9))
		for k in range(TO_WIN):                    # rounds won
			var at := Vector2(cx + (-1.0 if left else 1.0) * (26.0 + k * 22.0) * ui, 96.0 * ui)
			screen.draw_rect(Rect2(at - Vector2(8, 8) * ui, Vector2(16, 16) * ui), Color(0.07, 0.04, 0.12))
			screen.draw_rect(Rect2(at - Vector2(6, 6) * ui, Vector2(12, 12) * ui), Color(1.0, 0.85, 0.15) if f.wins > k else Color(0.3, 0.26, 0.4))
		if f.combo_t > 0 and f.combo_n >= 2:        # what they have just strung together
			var side := 44.0 * ui if left else _view.x - 44.0 * ui
			var pop := 1.0 + 0.5 * maxf(0.0, (f.combo_t - 72) / 8.0)
			_text(String(Loc.t("tk_hits")) % f.combo_n, Vector2(side, 190.0 * ui), 4.0 * pop, Color(1.0, 0.9, 0.2, minf(1.0, f.combo_t / 15.0)), 0 if left else 2)
			_text("%d%%" % int(round(f.combo_dmg)), Vector2(side, 262.0 * ui), 3.0, Color(1.0, 1.0, 1.0, minf(1.0, f.combo_t / 15.0)), 0 if left else 2)
	var box := Rect2(cx - 50.0 * ui, 12.0 * ui, 100.0 * ui, 66.0 * ui)
	screen.draw_rect(box, Color(0.07, 0.04, 0.12))
	screen.draw_rect(box.grow(-3.0 * ui), Color(0.86, 0.84, 0.92), false, 2.0 * ui)
	_text("%02d" % maxi(clock, 0), Vector2(cx, 18.0 * ui), 6.0, Color(1.0, 0.3, 0.2) if clock <= 10 else Color(1.0, 0.95, 0.85), 1)

func _draw_banner() -> void:
	var ui := _view.y / 720.0
	var age := banner_n - banner_t
	var size_n: int = int(get_meta("banner_size", 0))
	var k := (14.0 if size_n == 1 else (5.0 if size_n == 2 else 9.0)) * (1.0 + 1.2 * maxf(0.0, 1.0 - age / 7.0))
	var fade := minf(1.0, banner_t / 10.0)
	var at := Vector2(_view.x / 2.0, _view.y * (0.34 if size_n != 2 else 0.24))
	if size_n == 1:
		at += Vector2(randf_range(-1, 1), randf_range(-1, 1)) * maxf(0.0, 12.0 - age) * ui
	var dot := maxf(1.0, round(k * ui))
	var tall := Letras.H * dot + (70.0 * ui if banner_sub != "" else 0.0)
	screen.draw_rect(Rect2(0.0, at.y + dot - 12.0 * ui, _view.x, tall + 22.0 * ui), Color(0.04, 0.0, 0.1, 0.6 * fade))
	for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(1, 1), Vector2(-1, 1)]:
		_text(banner, at + o * dot * 0.5, k, Color(0.1, 0.02, 0.05, fade), 1, Color(0, 0, 0, 0))
	_text(banner, at + Vector2(0.0, dot * 0.45), k, Color(0.9, 0.3, 0.05, fade), 1, Color(0, 0, 0, 0))
	_text(banner, at, k, Color(1.0, 0.9, 0.25, fade), 1, Color(0, 0, 0, 0))
	if banner_sub != "":
		_text(banner_sub, at + Vector2(0.0, Letras.H * dot + 14.0 * ui), 5.0, Color(1.0, 1.0, 1.0, fade), 1)

## words in the machine's own letters: `k` screen pixels to a dot at 720 (align: 0 from the left, 1 centred, 2 to the right)
func _text(text, at: Vector2, k: float, col: Color, align := 0, shade := Color(0.06, 0.02, 0.12, 0.9)) -> void:
	var t := String(text).to_upper()
	var dot := maxf(1.0, round(k * _view.y / 720.0))
	var step := Letras.STEP * dot
	var w := t.length() * step - dot
	var x0 := at.x - (w / 2.0 if align == 1 else (w if align == 2 else 0.0))
	for pass_n in range(2):
		if pass_n == 0 and shade.a <= 0.0:
			continue
		var c := Color(shade.r, shade.g, shade.b, shade.a * col.a) if pass_n == 0 else col
		var off := Vector2(dot, dot) if pass_n == 0 else Vector2.ZERO
		for i in range(t.length()):
			var ch := t[i]
			if _font_at.has(ch):
				screen.draw_texture_rect_region(_font, Rect2(Vector2(x0 + i * step, at.y) + off, Vector2(Letras.W, Letras.H) * dot),
					Rect2(int(_font_at[ch]) * Letras.STEP, 0, Letras.W, Letras.H), c)

func _text_w(text, k: float) -> float:
	var dot := maxf(1.0, round(k * _view.y / 720.0))
	return String(text).length() * Letras.STEP * dot

func _icon(action: String) -> Texture2D:
	var path: String = Controls.icon(action)
	if path == "":
		return null
	if not _icons.has(path):
		_icons[path] = load(path)
	return _icons[path]

## a row of buttons and what each does, centred: [[action, words], ...]
func _hint_row(items: Array, y: float, k: float) -> void:
	if Touch.on:
		return
	var ui := _view.y / 720.0
	var ih := 13.0 * k * ui
	var gap := 26.0 * ui
	var widths: Array = []
	var total := 0.0
	for it in items:
		var tex := _icon(String(it[0]))
		var iw: float = (ih * tex.get_width() / tex.get_height()) if tex != null else _text_w(Controls.glyph(String(it[0])), k)
		var w: float = iw + 8.0 * ui + _text_w(it[1], k)
		widths.append([iw, w])
		total += w
	total += gap * (items.size() - 1)
	var x := _view.x / 2.0 - total / 2.0
	for i in range(items.size()):
		var tex := _icon(String(items[i][0]))
		var iw: float = widths[i][0]
		if tex != null:
			screen.draw_texture_rect(tex, Rect2(x, y - ih * 0.2, iw, ih), false)
		else:
			_text(Controls.glyph(String(items[i][0])), Vector2(x, y), k, Color(1.0, 0.9, 0.3))
		_text(items[i][1], Vector2(x + iw + 8.0 * ui, y), k, Color.WHITE)
		x += float(widths[i][1]) + gap

func _backdrop(n: int, shade: float) -> void:
	var w := _view_w()
	screen.draw_texture_rect_region(_stages[n], Rect2(Vector2.ZERO, _view), Rect2((STAGE_W - w) / 2.0, 0.0, w, VIEW_H))
	screen.draw_rect(Rect2(Vector2.ZERO, _view), Color(0.04, 0.01, 0.1, shade))

func _stat(label, at: Vector2, k: float) -> void:
	var ui := _view.y / 720.0
	_text(label, at, 2.0, Color(0.8, 0.8, 0.95))
	var r := Rect2(at + Vector2(130.0 * ui, 2.0 * ui), Vector2(150.0 * ui, 12.0 * ui))
	screen.draw_rect(r.grow(2.0 * ui), Color(0.07, 0.04, 0.12))
	screen.draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(k, 0.05, 1.0), r.size.y)), Color(1.0, 0.8, 0.2))

func _draw_select() -> void:
	var ui := _view.y / 720.0
	var s := _view.y / VIEW_H
	var id: String = ROSTER[pick]
	var d: Dictionary = FIGHTERS[id]
	_backdrop(int(d["stage"]), 0.62)
	var cx := _view.x / 2.0
	_text("TOKKEN 9", Vector2(cx, 18.0 * ui) + Vector2(0, 4) * ui, 7.0, Color(0.8, 0.15, 0.1), 1)
	_text("TOKKEN 9", Vector2(cx, 18.0 * ui), 7.0, Color(1.0, 0.85, 0.2), 1, Color(0, 0, 0, 0))
	_text(Loc.t("tk_pick"), Vector2(cx, 96.0 * ui), 3.0, Color.WHITE, 1)
	# yours, big, on the left; and who you are up against on the right
	var me := Fighter.new()
	me.id = id
	me.d = d
	var idle: Array = d["idle"]
	var feet_y := _view.y * 0.735
	_draw_sprite(me, Vector2(_view.x * 0.21, feet_y), int(idle[(mode_t / 11) % idle.size()]), s, 0.0, Color.WHITE, 1)
	var foe: String = String(opts.get("foe", ""))
	if foe != "":
		var them := Fighter.new()
		them.id = foe
		them.d = FIGHTERS[foe]
		var idle2: Array = them.d["idle"]
		_draw_sprite(them, Vector2(_view.x * 0.79, feet_y), int(idle2[(mode_t / 11) % idle2.size()]), s, 0.0, Color(0.72, 0.86, 1.3) if foe == id else Color.WHITE, -1)
		_text(Loc.t("tk_n_" + foe), Vector2(_view.x * 0.79, 44.0 * ui), 3.0, Color(1.0, 0.5, 0.4), 1)
	else:
		_text("?", Vector2(_view.x * 0.79, _view.y * 0.36), 16.0, Color(1, 1, 1, 0.5 + 0.3 * sin(mode_t * 0.1)), 1)
	_text(String(opts.get("foe_tag", Loc.t("tk_cpu"))), Vector2(_view.x * 0.79, 76.0 * ui), 2.0, Color.WHITE, 1)
	_text("VS", Vector2(cx, _view.y * 0.42), 8.0, Color(1.0, 0.3, 0.2), 1)
	_text(Loc.t("tk_n_" + id), Vector2(_view.x * 0.21, 44.0 * ui), 3.0, Color(1.0, 0.9, 0.3), 1)
	_text(Loc.t("tk_you"), Vector2(_view.x * 0.21, 76.0 * ui), 2.0, Color.WHITE, 1)
	# what they are like
	var col_x := cx - 150.0 * ui
	_text(String(Loc.t("tk_power")) + ": " + String(Loc.t("tk_s_" + id)), Vector2(cx, _view.y * 0.56), 2.0, Color(0.6, 0.85, 1.0), 1)
	_stat(Loc.t("tk_st_speed"), Vector2(col_x, _view.y * 0.61), float(d["speed"]) / 3.0)
	_stat(Loc.t("tk_st_power"), Vector2(col_x, _view.y * 0.645), (float(d["power"]) - 0.7) / 0.6)
	_stat(Loc.t("tk_st_reach"), Vector2(col_x, _view.y * 0.68), (float(blow(me, "heavy")["reach"]) - 80.0) / 60.0)
	# the six of them
	_tiles.clear()
	var tw := 122.0 * ui
	var th := 112.0 * ui
	var gap := 16.0 * ui
	var x0 := cx - (ROSTER.size() * tw + (ROSTER.size() - 1) * gap) / 2.0
	var y0 := _view.y - th - 54.0 * ui
	for i in range(ROSTER.size()):
		var r := Rect2(x0 + i * (tw + gap), y0, tw, th)
		_tiles.append(r)
		var on := i == pick
		screen.draw_rect(r.grow(5.0 * ui), Color(1.0, 0.85, 0.15) if (on and (mode_t / 8) % 2 == 0) else (Color(1.0, 1.0, 1.0) if on else Color(0.07, 0.04, 0.12)))
		screen.draw_texture_rect(_art[ROSTER[i]]["face"], r, false, Color.WHITE if on else Color(0.55, 0.55, 0.65))
		if on:
			_text("1P", Vector2(r.position.x + tw / 2.0, r.position.y - 30.0 * ui), 3.0, Color(1.0, 0.85, 0.15), 1)
	_hint_row([["m_left", ""], ["m_right", Loc.t("tk_b_pick")], ["interact", "OK"]], _view.y - 34.0 * ui, 2.0)

func _draw_versus() -> void:
	var ui := _view.y / 720.0
	var s := _view.y / VIEW_H * 1.5
	_backdrop(stage_n, 0.72)
	var slide := 1.0 - pow(1.0 - minf(1.0, mode_t / 22.0), 3.0)
	var cx := _view.x / 2.0
	var feet_y := _view.y * 0.86
	var idle_a: Array = a.d["idle"]
	var idle_b: Array = b.d["idle"]
	_draw_sprite(a, Vector2(lerpf(-300.0 * ui, _view.x * 0.23, slide), feet_y), int(idle_a[0]), s, 0.0, a.tint, 1)
	_draw_sprite(b, Vector2(lerpf(_view.x + 300.0 * ui, _view.x * 0.77, slide), feet_y), int(idle_b[0]), s, 0.0, b.tint, -1)
	var jolt := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * maxf(0.0, 26.0 - mode_t) * 0.6 * ui
	if mode_t > 16:
		_text("VS", Vector2(cx, _view.y * 0.3) + jolt + Vector2(0, 8) * ui, 22.0, Color(0.7, 0.1, 0.05), 1)
		_text("VS", Vector2(cx, _view.y * 0.3) + jolt, 22.0, Color(1.0, 0.85, 0.2), 1, Color(0, 0, 0, 0))
	_text(a.name, Vector2(_view.x * 0.23, 40.0 * ui), 5.0, Color(1.0, 0.9, 0.3), 1)
	_text(a.tag, Vector2(_view.x * 0.23, 96.0 * ui), 3.0, Color.WHITE, 1)
	_text(b.name, Vector2(_view.x * 0.77, 40.0 * ui), 5.0, Color(1.0, 0.5, 0.4), 1)
	_text(b.tag, Vector2(_view.x * 0.77, 96.0 * ui), 3.0, Color.WHITE, 1)
