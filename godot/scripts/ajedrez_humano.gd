extends Node
## El Ajedrez humano (the user's design, 16 November 2026; in their words in guion/ajedrez.md).
##
## The mission ("Partidas en la cabeza"): once the Galaxy Recress mission is over, the mayor, at the town hall door.
## Since he lost the Tokken 9 tournament he has gone back to his old hobbies, chess among them. A shot from the two of
## you up into the air and over the chessboard of the square: from his office window he sees it and plays games in his
## head; and as he sees the town go by, the pieces he imagines have become the town's people -- tall people the
## bishops, short people the rooks, children the pawns, dogs the knights, and he and his wife king and queen (they
## appear on the board as he names them, in their own colours: it is his imagination). Does he seem mad to you? --
## "Noooo, que vaaa, muy normal todo": he does not like sarcasm, he has enough of it at work. "Como una puñetera
## regadera": he laughs and thanks you for being honest. He has a lot of work ((and a game open in SuperChess 2.0)),
## and the minigame is unlocked.
##
## The minigame: standing on either chessboard of the square the action button says "Jugar" (it is in the Agenda's
## Minijuegos page too). You play the mayor, who plays from his window, at one of four levels; the pieces are those
## same people, white or grey, with their idling; winning pays Puntos Cívicos by the level (4/6/8/12, the user's
## figures). The rules and the player are ajedrez.gd's; it thinks on a thread of its own. While a game is on, the phase
## is "ajedrez" and the town stands still (game.gd), but the clock, the sky and the street lamps go on: a game is long, and
## can take more than a day (the user, through Sistemas, 16 November 2026). A game can be left half way and taken up again.
##
## Saved in stats: ajedrez (the day the mission was done), ajedrez_loco (what you answered), ajedrez_partida (a game
## left half way: fen, lv, mine, board), ajedrez_wins / ajedrez_fights / ajedrez_best (the most PC won in one game).

const Motor = preload("res://scripts/ajedrez.gd")
const Chara = preload("res://scripts/chara.gd")
const DOG := "res://assets/ajedrez/perro.glb"      # Quaternius's Shiba Inu (CC0): assets/ajedrez/CREDITOS.txt
const TITLE := "aj_title"
const GAME := "mg_ajedrez"
## the two chessboards of the square: their middles in plaza.gd's frame (plaza.gd _floors), 10 m a side
const BOARDS := [Vector2(-17.0, 9.6), Vector2(18.4, 9.6)]
const HALF := 5.0
const CELL := 1.25
const TOP := 0.045               # the squares' top, over the square's floor
const PC := [4, 6, 8, 12]        # Puntos Cívicos for beating him at each level (the user, 16 November 2026)
const LEVEL_NAMES := ["aj_lv_0", "aj_lv_1", "aj_lv_2", "aj_lv_3"]
const MIN_THINK := 1.1           # seconds he takes at least (he is looking out of the window)
## who the pieces are (the user: tall people the bishops, short ones the rooks, children the pawns, dogs the knights,
## the mayor and his wife king and queen). By file, for each side alike.
const BISHOPS := ["venancio", "katakumba"]          # (the undertaker in his top hat, and the tallest of them all)
const ROOKS := ["paca", "josefa"]                   # (the two little old women)
const PIECE_SCALE := {Motor.P: 0.86, Motor.N: 1.0, Motor.B: 0.8, Motor.R: 0.72, Motor.Q: 0.76, Motor.K: 0.8}
const DOG_LONG := 1.15         # a dog, nose to tail, on its square
## Over every piece, a hologram of the chess symbol of what it is, always facing the camera (the user, 16 November
## 2026: once they start moving about, which piece is which can be lost). Drawn by tools/make_ajedrez.py.
const HOLO := "res://assets/ajedrez/holo_%s_%s.png"
const HOLO_SCREEN := 0.085        # how tall on screen, of its height: the same near or far (from the far side it has to be read too)
const WHITE := Color(0.95, 0.93, 0.88)
const WHITE_DARK := Color(0.2, 0.19, 0.18)        # (eyes, brows, the frames of glasses: painted, so a face can be read)
const GREY := Color(0.43, 0.44, 0.47)
const GREY_DARK := Color(0.07, 0.07, 0.08)

var G
var plaza
var eng                          # Motor: the game on the board
var active := false
var level := 0
var mine := 0                    # your side: 0 white, 8 black (the board is turned to suit you)
var board_i := 0
var figs := {}                   # square -> {node, chara, ap, kind, c, go, fall}
var moves_said: Array = []       # the game in notation
var said := ""                   # the last thing the mayor said, for the panel
var cursor := Vector2i(4, 1)     # in your view: x from your left, y from your side
var sel := -1                    # the square of the piece you have picked up
var view := 0                    # 0 from your side, 1 from overhead
var result := ""                 # "" | "won" | "lost" | "draw"
var thinking := false
var test_hold := false           # (the tests: the mayor does not move on his own)
var _targets := PackedInt32Array()
var _busy := 0.0                 # pieces are moving
var _queue: Array = []           # what comes after the pieces stop
var _think_t := 0.0
var _ai_move := 0
var _thread: Thread
var _think_e = null
var _game_id := 0
var _end_t := 0.0
var _was := {}
var _hidden: Array = []
var _marks: Array = []           # the highlight squares in use
var _pool: Array = []
var _shader: Shader
var _dog_scene: PackedScene
var _dog_k := 0.0
var _kids: Array = []
var _layer: CanvasLayer
var _panel: Control
var _l_title: RichTextLabel
var _l_turn: RichTextLabel
var _l_moves: RichTextLabel
var _l_said: RichTextLabel
var _l_keys: RichTextLabel
var _taken := [0, 0]             # pieces taken off each side (where they stand by the board)
var _cam_from := Vector3.ZERO
var _cam_at := Vector3.ZERO
var _mats := {}
var _holo_tex := {}
# the mission's scene
var _dream: Array = []           # the pieces of his imagination
var _scene := false
var _before := "free"
var _tween: Tween

func setup(game) -> void:
	G = game
	eng = Motor.new()

func _plaza():
	if plaza == null and G.world != null:
		plaza = G.world.get("plaza")
	return plaza

# ================= the mission =================
func done() -> bool:
	return G.stats.has("ajedrez")

## after the Galaxy Recress, and not yet told
func available() -> bool:
	return G.recress != null and G.recress.done() and not done()

func game_open() -> bool:
	return int(G.unlocked.get("ajedrez", 0)) > 0

## who has a mission for you here (marcas.gd: the green arrow)
func givers(free_hands: bool) -> Array:
	if available() and free_hands and G.named.has("alcalde"):
		return [G.named["alcalde"]]
	return []

## talking to the mayor: true if it was handled here
func talk(n) -> bool:
	if n.id != "alcalde" or not available() or G.side != null or G.in_mission() or G.comida.faint != null or _plaza() == null:
		return false
	_begin_scene(n)
	return true

func _begin_scene(n) -> void:
	_scene = true
	G.cine_lock = true
	G.hud.cine(true)
	G.set_target(null, false)
	G.hud.set_prompt("")
	if G.in_car != null:
		G.in_car.set_speed(Vector2.ZERO)
		G._exit_car()
	var face: Vector2 = (n.p - G.player.p).normalized()
	if face.length() < 0.5:
		face = Vector2(0, 1)
	G.player.h = atan2(face.x, face.y)
	n.h = G.player.h + PI
	G.player.sync()
	n.sync()
	var two := _two_shot(G.player.p, n.p)
	_cut(two[0], two[1], 42.0)
	_say(n, "aj_m_intro", func(): _window(n, two))

## from the two of you up into the air, and over the board
func _window(n, two: Array) -> void:
	var c: Vector2 = BOARDS[0]
	var p = _plaza()
	var over: Vector3 = p.to_global(Vector3(c.x, 22.0, c.y - 4.0))          # (on the town hall's side: from his window, as it were)
	var at: Vector3 = p.to_global(Vector3(c.x, 0.0, c.y - 1.4))       # (the whole board between the cinema bar and the speech bubble)
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(func(k: float):
		var e := smoothstep(0.0, 1.0, k)
		var from: Vector3 = (two[0] as Vector3).lerp(over, e) + Vector3(0, sin(e * PI) * 4.0, 0)
		var to: Vector3 = (two[1] as Vector3).lerp(at, e)
		_cut(from, to, lerpf(42.0, 50.0, e)), 0.0, 1.0, 5.5)
	_dream_board()
	_say(n, "aj_m_window", func():
		var groups := [[Motor.B], [Motor.R], [Motor.P], [Motor.N], [Motor.Q, Motor.K]]
		_lines(n, Loc.t("aj_m_pieces"), [null, groups[0], groups[1], groups[2], groups[3], groups[4]], func(): _ask(n, two)))

## one line after another, with whatever goes with each
func _lines(n, lines: Array, acts: Array, then: Callable, i := 0) -> void:
	if i >= lines.size():
		then.call()
		return
	if i < acts.size() and acts[i] != null:
		_dream_show(acts[i])
	G.say(n.shown_name(), [lines[i]], n.voice, _lines.bind(n, lines, acts, then, i + 1))

func _ask(n, two: Array) -> void:
	if _tween != null:
		_tween.kill()
	_cut(two[0], two[1], 42.0)
	_dream_clear()
	var said: Array = Loc.t("aj_m_ask")                  # (all but his last line said; that one stays in the box with the answers in a bubble over it: game.gd ask)
	G.say(n.shown_name(), said.slice(0, said.size() - 1), n.voice, func():
		_before = G.phase
		G.ask(n, n.shown_name(), String(said[said.size() - 1]), [[Loc.t("aj_q_no"), _answer.bind(n, false)], [Loc.t("aj_q_yes"), _answer.bind(n, true)]]))

func _answer(n, honest: bool) -> void:
	G.phase = _before if _before != "talking" else "play"
	G.stats["ajedrez_loco"] = "regadera" if honest else "sarcasmo"
	if honest:
		G.folk.add("alcalde", 5)
		Sfx.beep(523.0, 0.06, 3, -14.0, 260.0)
	_say(n, "aj_m_honest" if honest else "aj_m_sarcasm", func(): _say(n, "aj_m_bye", _finish))

func _finish() -> void:
	_scene = false
	G.cine_lock = false
	G.cam_fixed = null
	G.cam.fov = 55.0
	G.hud.cine(false)
	G.stats["ajedrez"] = int(G.day_n)
	G.chismes.mission_over("ajedrez")         # (the town will talk about it: chismes.gd)
	G.unlocked["ajedrez"] = Motor.LEVELS.size()
	G.hud.toast(Loc.t("aj_unlocked"), 7.0)
	Sfx.jingle([659, 784, 1047, 1319], 0.1)
	G._refresh_counts()

func _say(n, key: String, then := Callable()) -> void:
	if then.is_valid():
		G.say(n.shown_name(), Loc.t(key), n.voice, then)
	else:
		G.say(n.shown_name(), Loc.t(key), n.voice)

func _two_shot(pa: Vector2, pb: Vector2) -> Array:
	var dir := (pb - pa).normalized()
	var right := Vector2(-dir.y, dir.x)
	var a := pa - dir * 0.9 + right * 1.5
	var b := pa + dir * 1.1
	return [Vector3(a.x, MapData.foot(a) + 1.65, a.y), Vector3(b.x, MapData.foot(b) + 1.25, b.y)]

func _cut(from: Vector3, at: Vector3, fov := 50.0) -> void:
	G.cam_fixed = [from, at]
	G.cam_pos = from
	G.cam_look = at
	G.cam.fov = fov
	G.cam.position = from
	G.cam.look_at(at)

## the pieces of his imagination: the town's people as they are, standing in their places, out of sight until named
func _dream_board() -> void:
	_dream_clear()
	var keep_mine := mine
	var keep_board := board_i
	mine = 0
	board_i = 0
	var start = Motor.new()
	for s in range(120):
		if s & 0x88 or start.board[s] == 0:
			continue
		var pc: int = start.board[s]
		var f := _figure(pc & 7, pc & Motor.BLACK, s, false, false)
		f["node"].scale = Vector3.ONE * 0.001
		f["node"].visible = false
		_dream.append(f)
	mine = keep_mine
	board_i = keep_board

func _dream_show(kinds: Array) -> void:
	var k := 0
	for f in _dream:
		if not (f["kind"] in kinds):
			continue
		var nd: Node3D = f["node"]
		nd.visible = true
		var tw := create_tween()
		tw.tween_interval(k * 0.04)
		tw.tween_property(nd, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		k += 1
	Sfx.beep(784.0, 0.05, 2, -16.0, 400.0)

func _dream_clear() -> void:
	for f in _dream:
		if is_instance_valid(f["node"]):
			f["node"].queue_free()
	_dream.clear()

# ================= the board =================
func _centre(i := -1) -> Vector2:
	return BOARDS[board_i if i < 0 else i]

## a square's middle in the square's own frame (u, n): the board turned so that your side is the near one
func _local(s: int) -> Vector2:
	var vx: int = (s & 7) if mine == 0 else 7 - (s & 7)
	var vy: int = (s >> 4) if mine == 0 else 7 - (s >> 4)
	return _view_local(Vector2i(vx, vy))

func _view_local(v: Vector2i) -> Vector2:
	var c := _centre()
	return Vector2(c.x - HALF + (v.x + 0.5) * CELL, c.y + HALF - (v.y + 0.5) * CELL)

func _view_sq(v: Vector2i) -> int:
	var f: int = v.x if mine == 0 else 7 - v.x
	var r: int = v.y if mine == 0 else 7 - v.y
	return r * 16 + f

func _sq_view(s: int) -> Vector2i:
	return Vector2i((s & 7) if mine == 0 else 7 - (s & 7), (s >> 4) if mine == 0 else 7 - (s >> 4))

func _world(l: Vector2, y := TOP) -> Vector3:
	return _plaza().to_global(Vector3(l.x, y, l.y))

func _sq_world(s: int) -> Vector3:
	return _world(_local(s))

## which way the pieces stand, as a heading: all of them looking at your side of the board, yours too (waiting to be
## told; a back is no face to know anybody by), or, in the mayor's imagination, at his window
func _heading(to_you := true) -> float:
	var d: Vector3 = _plaza().global_transform.basis * (Vector3(0, 0, 1) if to_you else Vector3(0, 0, -1))
	return atan2(d.x, d.z)

## is this spot of the map on one of the boards? (-1: no)
func board_at(p: Vector2) -> int:
	var pz = _plaza()
	if pz == null:
		return -1
	var l: Vector3 = pz.to_local(Vector3(p.x, pz.global_position.y, p.y))
	for i in range(BOARDS.size()):
		var c: Vector2 = BOARDS[i]
		if absf(l.x - c.x) <= HALF and absf(l.z - c.y) <= HALF:
			return i
	return -1

## the action button over a board says "Jugar"
func on_board(p: Vector2) -> bool:
	return game_open() and not active and G.in_car == null and not G.indoors and board_at(p) >= 0

func _free() -> bool:
	return (G.phase == "play" or G.phase == "free") and G.dlg == null and G.in_car == null and not G.in_mission() and G.side == null \
		and not G.motin.busy() and G.comida.faint == null and G.phone_call == null and not G.cine_lock

# ================= the people on it =================
func _look(id: String) -> Dictionary:
	return G.gacha.look_of(id).duplicate() if G.gacha != null else {}

func _kid_look(i: int) -> Dictionary:
	if i == 0:
		return _look("kevin")
	while _kids.size() < 7:
		_kids.append(G._neighbour_look("kid"))
	return (_kids[i - 1] as Dictionary).duplicate()

## one piece: the person (or dog) it is, white or grey (`mono`), or as they are (the mayor's imagination)
func _figure(kind: int, c: int, s: int, mono := true, to_you := true) -> Dictionary:
	var f: int = s & 7
	var who := ""
	match kind:
		Motor.K:
			who = "alcalde"
		Motor.Q:
			who = "alcaldesa"
		Motor.B:
			who = BISHOPS[0 if f < 4 else 1]
		Motor.R:
			who = ROOKS[0 if f < 4 else 1]
	var rec := {"kind": kind, "c": c, "chara": null, "ap": null, "go": null, "fall": 0.0, "who": who, "face": _heading(to_you)}
	var nd: Node3D
	if kind == Motor.N:
		nd = _dog(c, mono)
		rec["ap"] = nd.get_meta("ap", null)
	else:
		var look: Dictionary = _kid_look(f) if kind == Motor.P else _look(who)
		if look.is_empty():
			look = {"shirt": 0x888888}
		var ch = Chara.new()
		ch.setup(look)
		ch.collision_layer = 0
		ch.collision_mask = 0
		if who == "venancio" or who == "katakumba":
			ch.vis.scale *= 1.12                    # (tall people)
		if kind == Motor.K or kind == Motor.Q:
			_crown(ch, kind == Motor.K)
		ch.vis.scale *= float(PIECE_SCALE[kind])
		if mono:
			_paint(ch.vis, c == 0)
		rec["chara"] = ch
		nd = ch
	if mono:                                      # (the hologram of what it is: not in the mayor's imagination)
		var holo := _holo(kind, c)
		var high: float = 1.45
		if rec["chara"] != null:
			high = rec["chara"].vis.scale.y * (2.25 if kind == Motor.K or kind == Motor.Q else 2.0) + 0.6
		holo.position.y = high
		nd.add_child(holo)
		rec["holo"] = holo
		rec["holo_y"] = high
		rec["holo_t"] = randf() * TAU
	add_child(nd)
	nd.global_position = _sq_world(s)
	if rec["chara"] != null:
		rec["chara"].h = rec["face"]
		rec["chara"].sync()
	else:
		nd.rotation.y = rec["face"]
	rec["node"] = nd
	return rec

func _holo(kind: int, c: int) -> Sprite3D:
	var key := "%d_%d" % [kind, c]
	if not _holo_tex.has(key):
		_holo_tex[key] = load(HOLO % [" pnbrqk"[kind], "blanca" if c == 0 else "gris"])
	var sp := Sprite3D.new()
	sp.texture = _holo_tex[key]
	sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sp.fixed_size = true                         # (as big on screen near or far: as seen from 1 m away)
	sp.pixel_size = HOLO_SCREEN * 2.0 * tan(deg_to_rad(23.0)) / 256.0
	sp.no_depth_test = true                      # (always seen, over whatever is in the way)
	sp.shaded = false
	sp.double_sided = true
	sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sp.render_priority = 10
	sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return sp

## a crown for the king, a smaller one for the queen (to tell them apart at a glance)
func _crown(ch, king: bool) -> void:
	var gold := 0xd9a92a
	var r := 0.24 if king else 0.18
	var y := 1.97 if king else 1.95
	ch._acc("cyl", gold, Vector3(0, y, 0), Vector3(r, 0.12, r))
	var points := 5 if king else 3
	for k in range(points):
		var a: float = TAU * k / points
		ch._acc("ball", gold, Vector3(sin(a) * r * 0.9, y + 0.1, cos(a) * r * 0.9), Vector3.ONE * (0.07 if king else 0.06))
	if king:
		ch._acc("box", gold, Vector3(0, y + 0.2, 0), Vector3(0.05, 0.16, 0.05))
		ch._acc("box", gold, Vector3(0, y + 0.23, 0), Vector3(0.12, 0.045, 0.05))

func _mat(white: bool, dark: bool) -> StandardMaterial3D:
	var k := "%s%s" % [white, dark]
	if _mats.has(k):
		return _mats[k]
	var m := StandardMaterial3D.new()
	m.albedo_color = (WHITE_DARK if dark else WHITE) if white else (GREY_DARK if dark else GREY)
	m.roughness = 0.5
	m.metallic = 0.05
	m.rim_enabled = true
	m.rim = 0.35
	m.rim_tint = 0.5
	m.emission_enabled = true                   # (white reads white in the shade of the town hall too)
	m.emission = m.albedo_color
	m.emission_energy_multiplier = 0.12 if white else 0.06
	_mats[k] = m
	return m

## all of a person white or grey; their eyes, and whatever small and dark there is, a shade darker
func _paint(root: Node, white: bool) -> void:
	var todo: Array = [root]
	while not todo.is_empty():
		var n: Node = todo.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var dark := false
			var was = mi.material_override
			if was is StandardMaterial3D:
				var col: Color = (was as StandardMaterial3D).albedo_color
				dark = col.get_luminance() < 0.3 and mi.scale.length() < 0.25
			mi.material_override = _mat(white, dark)
		todo.append_array(n.get_children())

## a dog (the knights): standing, idling
func _dog(c: int, mono: bool) -> Node3D:
	if _dog_scene == null:
		_dog_scene = load(DOG)
	var root := Node3D.new()
	var body: Node3D = _dog_scene.instantiate()
	root.add_child(body)
	var ap: AnimationPlayer = null
	for x in body.find_children("*", "AnimationPlayer", true, false):
		ap = x
	var meshes: Array = body.find_children("*", "MeshInstance3D", true, false)
	if _dog_k <= 0.0:                             # (how big it is, once: it stands about a metre long on its square)
		var box := AABB()
		var first := true
		for mi in meshes:
			var b: AABB = _rel(body, mi) * (mi as MeshInstance3D).get_aabb()
			box = b if first else box.merge(b)
			first = false
		_dog_k = DOG_LONG / maxf(0.01, maxf(box.size.x, box.size.z))
	body.scale = Vector3.ONE * _dog_k
	body.rotation.y = PI                          # (the model looks down its -z: turned, it looks where the piece is going, like everybody else)
	if mono:
		for mi: MeshInstance3D in meshes:
			for k in range(mi.mesh.get_surface_count()):
				var orig: Material = mi.mesh.surface_get_material(k)
				var name: String = orig.resource_name if orig != null else ""
				mi.set_surface_override_material(k, _mat(c == 0, name in ["Black", "Eyes_Pupil", "Eyes_Black"]))
	if ap != null:
		for a in ["Idle", "Gallop", "Walk", "Idle_2"]:
			if ap.has_animation(a):
				ap.get_animation(a).loop_mode = Animation.LOOP_LINEAR
		if ap.has_animation("Idle"):
			ap.play("Idle")
			ap.seek(randf() * 2.0, true)
	root.set_meta("ap", ap)
	return root

## where a part of a model is, from the model's root (it is not in the tree yet)
func _rel(root: Node3D, n: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var x: Node = n
	while x != null and x != root:
		if x is Node3D:
			t = (x as Node3D).transform * t
		x = x.get_parent()
	return t

# ================= in and out =================
## pressed on a board: a game left half way, or the level and the side
func offer() -> void:
	if not _free():
		G.hud.toast(Loc.t("log_not_now"), 3.0)
		return
	board_i = maxi(0, board_at(G.player.p))
	_before = G.phase
	var saved = G.stats.get("ajedrez_partida")
	if saved is Dictionary:
		G._choice = {"title": Loc.t(GAME).to_upper(), "options": [
			[Loc.t("aj_resume") % Loc.t(LEVEL_NAMES[clampi(int(saved.get("lv", 0)), 0, 3)]), func(): _back_phase(); start(int(saved.get("lv", 0)), int(saved.get("mine", 0)), board_i, String(saved.get("fen", "")))],
			[Loc.t("aj_new"), _ask_level],
			[Loc.t("aj_later"), _back_phase]]}
	else:
		_ask_level()
		return
	G.phase = "talking"
	G.menu.open("choice")

func _back_phase() -> void:
	G.phase = _before if _before in ["play", "free"] else "free"

func _ask_level() -> void:
	var opts: Array = []
	for lv in range(Motor.LEVELS.size()):
		opts.append([Loc.t("aj_level") % [Loc.t(LEVEL_NAMES[lv]), PC[lv]], _ask_side.bind(lv)])
	opts.append([Loc.t("aj_later"), _back_phase])
	G._choice = {"title": Loc.t("aj_level_q"), "options": opts}
	G.phase = "talking"
	G.menu.open("choice")

func _ask_side(lv: int) -> void:
	G._choice = {"title": Loc.t("aj_side_q"), "options": [
		[Loc.t("aj_white"), func(): _back_phase(); start(lv, 0, board_i)],
		[Loc.t("aj_black"), func(): _back_phase(); start(lv, Motor.BLACK, board_i)],
		[Loc.t("aj_random"), func(): _back_phase(); start(lv, [0, Motor.BLACK].pick_random(), board_i)],
		[Loc.t("aj_later"), _back_phase]]}
	G.phase = "talking"
	G.menu.open("choice")

## from the Agenda: you are taken to the board first
func from_agenda(lv: int) -> void:
	board_i = 0
	var to: Vector2 = _stand_spot()
	G.player.p = to
	G.player.sync()
	G.cam_pos = Vector3(to.x, MapData.foot(to) + 3.0, to.y - 3.0)
	_before = G.phase
	_ask_side(lv)

## where you stand while you play: by the near left corner, looking at the board
func _stand_spot() -> Vector2:
	var c := _centre()
	var l := Vector2(c.x - HALF - 1.1, c.y + HALF + 0.6)
	var w := _world(l, 0.0)
	return Vector2(w.x, w.z)

## a game: at level `lv` (0..3), you with white (0) or black (8), on board `b`; from a position left half way (fen)
func start(lv: int, side: int, b: int, fen := "") -> void:
	if _plaza() == null:
		return
	level = clampi(lv, 0, Motor.LEVELS.size() - 1)
	mine = side
	board_i = clampi(b, 0, BOARDS.size() - 1)
	eng = Motor.new()
	if fen != "" and not eng.load_fen(fen):
		eng.load_fen(Motor.START)
	active = true
	result = ""
	sel = -1
	view = 0
	moves_said.clear()
	_queue.clear()
	_busy = 0.0
	_taken = [0, 0]
	_end_t = 0.0
	_game_id += 1
	cursor = Vector2i(4, 1)
	_was = {"phase": G.phase if G.phase in ["play", "free"] else "free", "p": G.player.p, "h": G.player.h}
	G.phase = "ajedrez"
	G.hud.set_prompt("")
	G.hud.play_ui.visible = false
	G.set_target(null, false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# you, by the board; anybody standing on it, out of the way while it lasts
	var stand := _stand_spot()
	G.player.p = stand
	var look: Vector2 = Vector2(_world(_centre()).x, _world(_centre()).z) - stand
	G.player.h = atan2(look.x, look.y)
	G.player.sync()
	_hidden.clear()
	var everyone: Array = G.npcs.duplicate()
	for n in G.named.values():
		if not (n in everyone):
			everyone.append(n)
	for n in everyone:
		if is_instance_valid(n) and n.visible and n != G.named.get("alcalde") and _near_board(n.p, 2.5):
			n.visible = false
			_hidden.append(n)
	for s in range(120):
		if s & 0x88 or eng.board[s] == 0:
			continue
		figs[s] = _figure(eng.board[s] & 7, eng.board[s] & Motor.BLACK, s)
	_make_panel()
	_set_view(0, true)
	_comment("aj_c_hello_%d" % level)
	_refresh()
	if eng.side != mine:
		_think()

func _near_board(p: Vector2, pad: float) -> bool:
	var pz = _plaza()
	var l: Vector3 = pz.to_local(Vector3(p.x, pz.global_position.y, p.y))
	var c := _centre()
	return absf(l.x - c.x) <= HALF + pad and absf(l.z - c.y) <= HALF + pad

## the end of it (won, lost, a draw, left for later or given up)
func leave() -> void:
	_stop_thinking()
	active = false
	for f in figs.values():
		if is_instance_valid(f["node"]):
			f["node"].queue_free()
	figs.clear()
	for f in _gone:
		if is_instance_valid(f["node"]):
			f["node"].queue_free()
	_gone.clear()
	_clear_marks()
	for n in _hidden:
		if is_instance_valid(n):
			n.visible = true
	_hidden.clear()
	if _layer != null:
		_layer.queue_free()
		_layer = null
	G.phase = String(_was.get("phase", "free"))
	G.hud.play_ui.visible = true
	G.cam.fov = 55.0
	var p: Vector2 = G.player.p
	G.cam_pos = Vector3(p.x, MapData.foot(p) + 3.0, p.y - 3.0)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	G._refresh_counts()
	G._save(G.save_si)

func _exit_tree() -> void:
	_stop_thinking()                             # (the game closed while he was thinking: the thread is waited for)

func _stop_thinking() -> void:
	_game_id += 1
	if _think_e != null:
		_think_e.stop = true
	if _thread != null:
		_thread.wait_to_finish()
		_thread = null
	_think_e = null
	thinking = false

## put it aside, as it is, to go on with it another time
func save_for_later() -> void:
	G.stats["ajedrez_partida"] = {"fen": eng.fen(), "lv": level, "mine": mine, "board": board_i}
	leave()

func resign() -> void:
	_over("lost")

# ================= playing =================
func input(e: InputEvent) -> void:
	if not active:
		return
	if result != "":
		if _end_t <= 0.0 and (e.is_action_pressed("interact") or e.is_action_pressed("m_accept") or e.is_action_pressed("m_back") or e.is_action_pressed("pause")
				or (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed)):
			leave()
		return
	if e.is_action_pressed("pause") or (e.is_action_pressed("m_back") and sel < 0 and not (e is InputEventMouseButton)):
		_menu()
		return
	if e.is_action_pressed("radio"):
		_set_view(1 - view)
		return
	if e.is_action_pressed("m_back"):
		sel = -1
		_refresh()
		return
	if e is InputEventMouseMotion:
		var v = _cell_at(e.position)
		if v != null and v != cursor:
			cursor = v
			_refresh()
		return
	var at = null
	if e is InputEventScreenTouch and e.pressed:
		at = e.position
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and not Touch.on:
		at = e.position
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
		sel = -1
		_refresh()
		return
	if at != null:
		var v = _cell_at(at)
		if v != null:
			cursor = v
			pick(_view_sq(v))
		return
	var step := Vector2i.ZERO
	if e.is_action_pressed("forward", true) or e.is_action_pressed("m_up", true):
		step.y = 1
	elif e.is_action_pressed("back", true) or e.is_action_pressed("m_down", true):
		step.y = -1
	elif e.is_action_pressed("left", true) or e.is_action_pressed("m_left", true):
		step.x = -1
	elif e.is_action_pressed("right", true) or e.is_action_pressed("m_right", true):
		step.x = 1
	if step != Vector2i.ZERO:
		cursor = Vector2i(clampi(cursor.x + step.x, 0, 7), clampi(cursor.y + step.y, 0, 7))
		Sfx.beep(660.0, 0.02, 1, -24.0)
		_refresh()
		return
	if e.is_action_pressed("interact") or e.is_action_pressed("m_accept") or e.is_action_pressed("punch"):
		pick(_view_sq(cursor))

func touch_buttons() -> Array:
	if result != "":
		return [[Loc.t("aj_b_out"), "interact", "big"]]
	return [[Loc.t("aj_b_view"), "radio", ""], [Loc.t("aj_b_drop"), "m_back", ""], ["II", "pause", "top"]]

## the square under a spot of the screen (in your view), or null
func _cell_at(at: Vector2):
	var o: Vector3 = G.cam.project_ray_origin(at)
	var d: Vector3 = G.cam.project_ray_normal(at)
	var top: float = _world(_centre()).y
	if absf(d.y) < 0.001:
		return null
	var t: float = (top - o.y) / d.y
	if t <= 0.0:
		return null
	var l: Vector3 = _plaza().to_local(o + d * t)
	var c := _centre()
	var vx := int(floor((l.x - (c.x - HALF)) / CELL))
	var vy := int(floor(((c.y + HALF) - l.z) / CELL))
	if vx < 0 or vx > 7 or vy < 0 or vy > 7:
		return null
	return Vector2i(vx, vy)

## a square chosen: pick up one of yours, or put the one in your hand down there
func pick(s: int) -> void:
	if result != "" or eng.side != mine or thinking or _busy > 0.0:
		return
	var pc: int = eng.board[s]
	if sel >= 0 and s in _targets:
		var options: Array = []
		for m: int in eng.legal_from(sel):
			if Motor.move_to(m) == s:
				options.append(m)
		sel = -1
		if options.size() > 1:                   # (a child at the far side: what does it become?)
			_promote(options)
		elif not options.is_empty():
			play(options[0])
		return
	if pc != 0 and (pc & Motor.BLACK) == mine:
		var ms: PackedInt32Array = eng.legal_from(s)
		if ms.is_empty():
			Sfx.beep(220.0, 0.08, 1, -18.0)
			sel = -1
		else:
			sel = s
			Sfx.beep(880.0, 0.03, 1, -18.0)
	else:
		sel = -1
	_refresh()

func _promote(options: Array) -> void:
	var opts: Array = []
	for kind in [Motor.Q, Motor.R, Motor.B, Motor.N]:
		for m: int in options:
			if Motor.move_promo(m) == kind:
				opts.append([Loc.t("aj_promo_%d" % kind), func(): play(m)])
	G._choice = {"title": Loc.t("aj_promo_q"), "options": opts}
	G.menu.open("choice")

func _menu() -> void:
	G._choice = {"title": Loc.t(GAME).to_upper(), "options": [[Loc.t("aj_go_on"), func(): pass], [Loc.t("aj_save"), save_for_later], [Loc.t("aj_resign"), resign]]}
	G.menu.open("choice")

## a move (yours or his) made on the board, and walked by the pieces
func play(m: int) -> void:
	var fr := Motor.move_from(m)
	var to := Motor.move_to(m)
	var pr := Motor.move_promo(m)
	var fl := Motor.move_flags(m)
	var who: int = eng.side
	var san: String = eng.san(m, Loc.lang == "es")
	var victim_sq := to
	if fl & 1:
		victim_sq = to - 16 if who == 0 else to + 16
	var victim = figs.get(victim_sq)
	var victim_kind: int = eng.board[victim_sq] & 7
	if not eng.make(m):
		return
	if who == 0:
		moves_said.append("%d. %s" % [eng.full - (0 if eng.side == Motor.BLACK else 1), san])
	else:
		moves_said.append(san)
	var mover = figs[fr]
	figs.erase(fr)
	if victim != null:
		figs.erase(victim_sq)
		_take(victim, 0.55 if mover["kind"] == Motor.N else 0.35)
	figs[to] = mover
	var dur := _go(mover, to)
	if fl & 2:                                   # castling: the rook walks round
		var rf: int = {6: 7, 2: 0, 118: 119, 114: 112}[to]
		var rt: int = {6: 5, 2: 3, 118: 117, 114: 115}[to]
		var rook = figs[rf]
		figs.erase(rf)
		figs[rt] = rook
		dur = maxf(dur, _go(rook, rt))
	if pr != 0:
		_queue.append(func(): _crowned(to, pr, who))
	_busy = dur + 0.15
	sel = -1
	_targets = PackedInt32Array()
	Sfx.beep(330.0 if victim == null else 196.0, 0.05, 1, -16.0, 120.0)
	# what the mayor has to say about it
	if eng.in_check():
		_comment("aj_c_check" if who != mine else "aj_c_checked")
	elif victim != null and who != mine:
		_comment("aj_c_take")
	elif victim != null and victim_kind == Motor.Q:
		_comment("aj_c_lost_queen")
	elif victim != null and victim_kind == Motor.R:
		_comment("aj_c_lost_rook")
	_queue.append(_after)
	_refresh()

## a child at the far side becomes what was asked for
func _crowned(s: int, kind: int, c: int) -> void:
	var old = figs.get(s)
	if old != null and is_instance_valid(old["node"]):
		old["node"].queue_free()
	var f := _figure(kind, c, s)
	f["node"].scale = Vector3.ONE * 0.2
	create_tween().tween_property(f["node"], "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	figs[s] = f
	Sfx.jingle([784, 1047], 0.08)

## the move is over: the game is over, or it is the other's turn
func _after() -> void:
	if result != "" or not active:
		return
	var st: String = eng.status()
	G.stats["ajedrez_partida"] = {"fen": eng.fen(), "lv": level, "mine": mine, "board": board_i}
	if st == "mate":
		_over("won" if eng.side != mine else "lost")
		return
	if st != "":
		_over("draw")
		return
	_refresh()
	if eng.side != mine:
		_think()

func _over(how: String) -> void:
	result = how
	_stop_thinking()
	G.stats.erase("ajedrez_partida")
	G.stats["ajedrez_fights"] = int(G.stats.get("ajedrez_fights", 0)) + 1
	G.hud.play_ui.visible = true                 # (the stamp and the slate with the Puntos Cívicos are in it)
	match how:
		"won":
			G.stats["ajedrez_wins"] = int(G.stats.get("ajedrez_wins", 0)) + 1
			G.stats["ajedrez_best"] = maxi(int(G.stats.get("ajedrez_best", 0)), PC[level])
			G.add_pc(PC[level])
			G.hud.stamp(Loc.t("aj_stamp"))
			Sfx.jingle([523, 659, 784, 1047, 1319], 0.11)
			_comment("aj_c_lose")
		"lost":
			Sfx.sad_trombone()
			_comment("aj_c_win")
		_:
			Sfx.jingle([523, 523], 0.15)
			_comment("aj_c_draw")
	_end_t = 1.2
	_refresh()

# ---------------- his turn ----------------
func _think() -> void:
	if test_hold or result != "":
		return
	thinking = true
	_think_t = 0.0
	_ai_move = 0
	_think_e = eng.clone()
	_thread = Thread.new()
	_thread.start(_think_run.bind(_think_e, level, _game_id))
	if randf() < 0.25:
		_comment("aj_c_think")
	_refresh()

func _think_run(e, lv: int, id: int) -> void:
	var m: int = e.best(lv)
	_thought.call_deferred(m, id)

func _thought(m: int, id: int) -> void:
	if id != _game_id or not active:
		return
	if _thread != null:
		_thread.wait_to_finish()
		_thread = null
	_think_e = null
	_ai_move = m if m != 0 else -1

# ---------------- every tick (while a game is on, game.gd holds the town: the phase is "ajedrez") ----------------
## (on the physics tick, as the game's own camera: it is interpolated between ticks)
func _physics_process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	if _scene:
		_idle(_dream, dt)
	if not active:
		return
	# the camera, gliding to the view asked for
	G.cam.global_position = G.cam.global_position.lerp(_cam_from, 1.0 - exp(-4.0 * dt))
	_cam_at_now = _cam_at_now.lerp(_cam_at, 1.0 - exp(-4.0 * dt))
	G.cam.look_at(_cam_at_now)
	# the mayor's move, once he has thought (and taken his time over it)
	if thinking:
		_think_t += dt
		if _ai_move != 0 and _think_t >= MIN_THINK:
			var m := _ai_move
			thinking = false
			_ai_move = 0
			if m > 0:
				play(m)
	# pieces on their way
	if _busy > 0.0:
		_busy -= dt
		if _busy <= 0.0:
			_busy = 0.0
			var q: Array = _queue.duplicate()
			_queue.clear()
			for f in q:
				(f as Callable).call()
	_idle(figs.values(), dt)
	_idle(_gone, dt)
	if _end_t > 0.0:
		_end_t -= dt
	_pulse(dt)

var _cam_at_now := Vector3.ZERO
var _gone: Array = []            # the pieces taken off, standing by the board

## everybody idles; whoever is walking walks; heads turn to the square the cursor is on
func _idle(list: Array, dt: float) -> void:
	var at3: Vector3 = _world(_view_local(cursor)) if active else Vector3.ZERO
	var at := Vector2(at3.x, at3.z)
	var held = figs[sel]["node"] if active and sel >= 0 and figs.has(sel) else null
	var now := Time.get_ticks_msec() / 1000.0
	for f in list:
		var nd: Node3D = f["node"]
		if not is_instance_valid(nd):
			continue
		if f.has("holo"):                         # the hologram floats and flickers a little; the piece in your hand's is bigger
			var hs: Sprite3D = f["holo"]
			var ph: float = f["holo_t"]
			hs.position.y = float(f["holo_y"]) + sin(now * 2.2 + ph) * 0.05
			hs.modulate.a = 0.86 + 0.14 * sin(now * 9.0 + ph * 3.0)
			hs.scale = hs.scale.lerp(Vector3.ONE * (1.3 if nd == held else 1.0), 1.0 - exp(-10.0 * dt))
		var go = f["go"]
		var moving := false
		if go != null:
			go["t"] = float(go["t"]) + dt
			var k: float = clampf(float(go["t"]) / float(go["dur"]), 0.0, 1.0)
			if float(go["t"]) >= 0.0:
				moving = k < 1.0
				var pos: Vector3 = (go["a"] as Vector3).lerp(go["b"], smoothstep(0.0, 1.0, k) if f["chara"] == null else k)
				pos.y += sin(k * PI) * float(go["hop"])
				nd.global_position = pos
				if k >= 1.0:
					f["go"] = null
					if f["chara"] == null:
						nd.rotation.y = float(go.get("face", f["face"]))
						_anim(f, "Idle")
		var ch = f["chara"]
		if ch != null:
			if go != null and moving:
				var d: Vector3 = (go["b"] as Vector3) - (go["a"] as Vector3)
				ch.h = lerp_angle(ch.h, atan2(d.x, d.z), 1.0 - exp(-12.0 * dt))
			elif go == null and float(f["fall"]) <= 0.0:
				ch.h = lerp_angle(ch.h, float(f["face"]), 1.0 - exp(-6.0 * dt))
			ch.anim(moving, dt, 2.0)
			if float(f["fall"]) > 0.0:
				f["fall"] = maxf(0.0, float(f["fall"]) - dt)
				ch.inner.rotation.x = -PI / 2.0 * clampf(1.0 - absf(float(f["fall"]) - 0.6) / 0.6, 0.0, 1.0) if float(f["fall"]) > 0.0 else 0.0
			ch.look_at_spot(at if active and go == null else null, dt)
			ch.sync()

func _anim(f: Dictionary, name: String) -> void:
	var ap: AnimationPlayer = f["ap"]
	if ap != null and ap.has_animation(name) and ap.current_animation != name:
		ap.play(name, 0.15)

## send a piece to a square: how long it takes
func _go(f: Dictionary, to: int, delay := 0.0) -> float:
	var a: Vector3 = f["node"].global_position
	var b: Vector3 = _sq_world(to)
	var dist := a.distance_to(b)
	var dog: bool = f["chara"] == null
	var dur: float = clampf(dist / (3.2 if dog else 2.4), 0.45, 2.2)
	f["go"] = {"a": a, "b": b, "t": -delay, "dur": dur, "hop": 0.9 if dog else 0.0}
	if dog:
		f["node"].rotation.y = atan2(b.x - a.x, b.z - a.z)
		_anim(f, "Gallop_Jump" if f["ap"] != null and f["ap"].has_animation("Gallop_Jump") else "Gallop")
	return dur + delay

## taken: they fall over (a dog lies down), get up and go and stand by the side of the board
func _take(f: Dictionary, after: float) -> void:
	var c: int = f["c"]
	var i: int = _taken[c >> 3]
	_taken[c >> 3] += 1
	var cc := _centre()
	var left: bool = (c == 0) == (mine == 0)      # (your pieces stand on your left, his on the right)
	var u: float = (cc.x - HALF - 0.9 - (i / 8) * 1.0) if left else (cc.x + HALF + 0.9 + (i / 8) * 1.0)
	var n: float = cc.y + HALF - ((i % 8) + 0.5) * CELL
	var spot := _world(Vector2(u, n), 0.02)
	var face_d: Vector3 = _plaza().global_transform.basis * (Vector3(1, 0, 0) if left else Vector3(-1, 0, 0))
	var tw := create_tween()
	tw.tween_interval(after)
	tw.tween_callback(func():
		if f.has("holo") and is_instance_valid(f["holo"]):
			f["holo"].visible = false             # (off the board: no longer a piece)
		if f["chara"] != null:
			f["fall"] = 1.2
		else:
			_anim(f, "Death")
		Sfx.beep(150.0, 0.12, 1, -14.0, -60.0))
	tw.tween_interval(1.3)
	tw.tween_callback(func():
		f["go"] = {"a": f["node"].global_position, "b": spot, "t": 0.0, "dur": clampf(f["node"].global_position.distance_to(spot) / 3.0, 0.5, 2.5), "hop": 0.0, "face": atan2(face_d.x, face_d.z)}
		f["face"] = atan2(face_d.x, face_d.z)
		if f["chara"] == null:
			f["node"].rotation.y = atan2(spot.x - f["node"].global_position.x, spot.z - f["node"].global_position.z)
			_anim(f, "Walk"))
	_gone.append(f)

# ---------------- what is shown ----------------
func _set_view(v: int, now := false) -> void:
	view = v
	var c := _centre()
	if view == 0:                                # from behind your side
		_cam_from = _world(Vector2(c.x, c.y + 11.0), 12.5)
		_cam_at = _world(Vector2(c.x, c.y + 0.3), 0.0)
	else:                                        # nearly overhead
		_cam_from = _world(Vector2(c.x, c.y + 4.0), 17.5)
		_cam_at = _world(Vector2(c.x, c.y + 0.2), 0.0)
	G.cam.fov = 46.0
	if now:
		G.cam_fixed = null
		G.cam.global_position = _cam_from
		_cam_at_now = _cam_at
		G.cam.look_at(_cam_at)
		G.cam.reset_physics_interpolation()

func _comment(key: String) -> void:
	var lines = Loc.t(key)
	said = String(lines.pick_random() if lines is Array else lines)
	if _l_said != null:
		_refresh()

func _make_panel() -> void:
	if _layer != null:
		_layer.queue_free()
	_layer = CanvasLayer.new()
	_layer.layer = 30
	add_child(_layer)
	var box: PanelContainer = G.hud._skinned("paper")
	box.position = Vector2(18, 18)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := MarginContainer.new()
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 16)
	for side in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 10)
	box.add_child(m)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 2)
	m.add_child(v)
	_l_title = G.hud._rich(21, G.hud.INK)
	_l_turn = G.hud._rich(19, G.hud.INK)
	_l_moves = G.hud._rich(15, G.hud.INK.lightened(0.15))
	_l_said = G.hud._rich(17, Color("7a2a1c"))
	_l_said.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_l_said.custom_minimum_size = Vector2(330, 0)
	_l_keys = G.hud._rich(14, G.hud.INK.lightened(0.25))
	for l in [_l_title, _l_turn, _l_moves, _l_said, _l_keys]:
		v.add_child(l)
	_layer.add_child(box)
	_panel = box

func _refresh() -> void:
	_targets = PackedInt32Array()
	if sel >= 0:
		for m: int in eng.legal_from(sel):
			_targets.append(Motor.move_to(m))
	_draw_marks()
	if _l_title == null or not is_instance_valid(_l_title):
		return
	G.hud.rt(_l_title, "[b]%s[/b] · %s" % [Loc.t(GAME), Loc.t(LEVEL_NAMES[level])])
	var turn := ""
	match result:
		"won":
			turn = Loc.t("aj_won") % PC[level]
		"lost":
			turn = Loc.t("aj_lost")
		"draw":
			turn = Loc.t("aj_draw")
		_:
			if _busy > 0.0:
				turn = "…"
			else:
				turn = Loc.t("aj_thinking") if eng.side != mine else Loc.t("aj_your_turn") % Loc.t("aj_whites" if mine == 0 else "aj_greys")
			if eng.in_check():
				turn += "  " + Loc.t("aj_check")
	G.hud.rt(_l_turn, turn)
	var last: Array = moves_said.slice(maxi(0, moves_said.size() - 6))
	G.hud.rt(_l_moves, "  ".join(last) if not last.is_empty() else Loc.t("aj_no_moves"))
	G.hud.rt(_l_said, ("%s: «%s»" % [Loc.t("n_alcalde"), said]) if said != "" else "")
	G.hud.rt(_l_keys, Controls.fill(Loc.t("aj_keys_end") if result != "" else Loc.t("aj_keys")))

# ---------------- the marks on the squares ----------------
const MARK_SHADER := "
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 tint : source_color = vec4(1.0);
uniform int kind = 0;
uniform float beat = 0.0;
void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float a = 0.0;
	if (kind == 0) { a = 0.5; }
	else if (kind == 1) { a = smoothstep(0.3, 0.24, length(q)); }
	else if (kind == 2) { float r = length(q); a = smoothstep(0.66, 0.72, r) * smoothstep(1.0, 0.94, r); }
	else { float e = max(abs(q.x), abs(q.y)); a = smoothstep(0.78, 0.84, e) * smoothstep(1.0, 0.97, e); }
	ALBEDO = tint.rgb;
	ALPHA = a * tint.a * (0.8 + 0.2 * beat);
}
"

func _mark(s_or_view, kind: int, tint: Color, lift: float) -> void:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = MARK_SHADER
	var mi: MeshInstance3D
	if not _pool.is_empty():
		mi = _pool.pop_back()
	else:
		mi = MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(CELL * 0.98, CELL * 0.98)
		mi.mesh = pm
		var sm := ShaderMaterial.new()
		sm.shader = _shader
		mi.material_override = sm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	var l: Vector2 = _view_local(s_or_view) if s_or_view is Vector2i else _local(int(s_or_view))
	mi.global_position = _world(l, TOP + lift)
	mi.global_rotation = Vector3(0, _plaza().global_rotation.y, 0)
	var sm2: ShaderMaterial = mi.material_override
	sm2.set_shader_parameter("tint", tint)
	sm2.set_shader_parameter("kind", kind)
	sm2.render_priority = int(lift * 1000.0)
	mi.visible = true
	_marks.append(mi)

func _clear_marks() -> void:
	for mi in _marks:
		mi.visible = false
		_pool.append(mi)
	_marks.clear()

func _draw_marks() -> void:
	_clear_marks()
	if not active:
		return
	if eng.hp > 0:                               # the last move
		var lm: int = eng._um[eng.hp - 1]
		_mark(Motor.move_from(lm), 0, Color(0.35, 0.6, 0.95, 0.35), 0.006)
		_mark(Motor.move_to(lm), 0, Color(0.35, 0.6, 0.95, 0.35), 0.006)
	if eng.in_check() and result != "won" and result != "lost" or (result != "" and eng.in_check()):
		_mark(eng.kings[eng.side >> 3], 0, Color(0.95, 0.15, 0.1, 0.55), 0.008)
	if sel >= 0:
		_mark(sel, 0, Color(1.0, 0.85, 0.2, 0.5), 0.01)
		for t in _targets:
			_mark(t, 2 if eng.board[t] != 0 or t == eng.ep else 1, Color(0.95, 0.25, 0.15, 0.85) if eng.board[t] != 0 else Color(0.2, 0.85, 0.35, 0.85), 0.012)
	if result == "":
		_mark(cursor, 3, Color(1.0, 0.92, 0.3, 0.95), 0.014)

func _pulse(_dt: float) -> void:
	var b: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 220.0)
	for mi in _marks:
		(mi.material_override as ShaderMaterial).set_shader_parameter("beat", b)
