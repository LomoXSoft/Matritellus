extends Control
## Noughts and crosses with the mayor while the town loads (the user, 17 Nov 2026: "un minijuego de bajísimos recursos
## para que se entretengan", and of the three offered, "El tres en raya con el alcalde suena bien"). Plain 2D: nine
## buttons, three labels, a timer. It lives on the loading screen (game.gd _ready) and goes with it.
##
##   You are the crosses, the mayor the noughts. You open the first game, he the next, and so on by turns.
##   He plays well but not perfectly: three moves in ten he does not stop to think (a cell at random), so he can be beaten.
##   The town's building is done a slice at a time (world.gd _houses), so the board answers between slices; a step
##   that is not sliced (the ground, the people) holds it for a few seconds, and a click then counts when it is over.

const YELLOW := Color("f2b632")
const CREAM := Color(0.97, 0.95, 0.9)
const CELL := 104
const SLIP := 0.3                # how often he plays without thinking
const THINK := 0.55              # seconds he takes over a move
const LINES := [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]

var board: Array = []            # 9 cells: "" | "X" (you) | "O" (the mayor)
var turn := "X"
var over := false
var wins := 0                    # yours
var losses := 0
var games := 0
var rng := RandomNumberGenerator.new()
var _cells: Array = []
var _say: Label
var _score: Label
var _timer: Timer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rng.randomize()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.offset_bottom = -110                  # (clear of "Loading…", the bar and the chores at the bottom)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	center.add_child(col)
	_say = Label.new()
	_say.custom_minimum_size = Vector2(560, 56)
	_say.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_say.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_say.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_say.add_theme_font_size_override("font_size", 19)
	_say.add_theme_color_override("font_color", Color(1, 1, 1, 0.88))
	col.add_child(_say)
	var hold := CenterContainer.new()
	col.add_child(hold)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	hold.add_child(grid)
	for i in range(9):
		var b := Button.new()
		b.custom_minimum_size = Vector2(CELL, CELL)
		b.add_theme_font_size_override("font_size", 64)
		b.add_theme_stylebox_override("normal", _box(Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.28)))
		b.add_theme_stylebox_override("hover", _box(Color(1, 1, 1, 0.12), Color(1, 1, 1, 0.45)))
		b.add_theme_stylebox_override("pressed", _box(Color(1, 1, 1, 0.12), YELLOW))
		b.add_theme_stylebox_override("focus", _box(Color(1, 1, 1, 0.10), YELLOW))
		b.add_theme_stylebox_override("disabled", _box(Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.28)))
		b.pressed.connect(play.bind(i))
		grid.add_child(b)
		_cells.append(b)
	_score = Label.new()
	_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score.add_theme_font_size_override("font_size", 17)
	_score.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	col.add_child(_score)
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer)
	add_child(_timer)
	new_game(true)

func _box(bg: Color, edge: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = edge
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	return sb

## a clean board; whoever's turn it is to open opens (`first`: the first game, he says hello)
func new_game(first := false) -> void:
	board = ["", "", "", "", "", "", "", "", ""]
	over = false
	turn = "X" if games % 2 == 0 else "O"
	_draw_board()
	_show_score()
	if first:
		_line("alcalde_raya_hola")
	elif turn == "O":
		_line("alcalde_raya_empieza")
	if turn == "O":
		_timer.start(THINK + 0.4)
	elif Controls.pad and is_inside_tree():
		(_cells[4] as Button).grab_focus()

## you put a cross in cell `i` (a click, a finger, a pad's button on it)
func play(i: int) -> void:
	if over or turn != "X" or board[i] != "":
		return
	board[i] = "X"
	_draw_board()
	if _settle():
		return
	turn = "O"
	if rng.randf() < 0.35:
		_line("alcalde_raya_piensa")
	_timer.start(THINK)

func _on_timer() -> void:
	if over:
		new_game()
		return
	if turn == "O":
		mayor_move()

## the mayor's nought: the best there is, now and then any free cell
func mayor_move() -> void:
	if over or turn != "O":
		return
	var free: Array = []
	for i in range(9):
		if board[i] == "":
			free.append(i)
	if free.is_empty():
		return
	var at: int = free[rng.randi() % free.size()] if rng.randf() < SLIP else best_move(board, "O")
	board[at] = "O"
	_draw_board()
	if _settle():
		return
	turn = "X"
	if Controls.pad and is_inside_tree():
		(_cells[free.filter(func(c): return c != at)[0] if free.size() > 1 else 4] as Button).grab_focus()

## who has three in a row ("X", "O"), "-" for a full board with nobody, "" while it goes on
static func winner(b: Array) -> String:
	for l in LINES:
		if b[l[0]] != "" and b[l[0]] == b[l[1]] and b[l[1]] == b[l[2]]:
			return b[l[0]]
	return "-" if not b.has("") else ""

## the best cell for `who` on board `b` (plain minimax: nine cells at most, nothing to it)
static func best_move(b: Array, who: String) -> int:
	if not b.has("X") and not b.has("O"):
		return [4, 0, 2, 6, 8].pick_random()      # (an empty board: the middle or a corner, no need to search it all)
	var best := -1
	var best_score := -99
	for i in range(9):
		if b[i] != "":
			continue
		b[i] = who
		var sc := -_negamax(b, "X" if who == "O" else "O", 1)
		b[i] = ""
		if sc > best_score:
			best_score = sc
			best = i
	return best

static func _negamax(b: Array, who: String, depth: int) -> int:
	var w := winner(b)
	if w == "-":
		return 0
	if w != "":
		return -(10 - depth)          # (the one who has just moved has won: bad for `who`; sooner is worse)
	var best := -99
	for i in range(9):
		if b[i] != "":
			continue
		b[i] = who
		best = maxi(best, -_negamax(b, "X" if who == "O" else "O", depth + 1))
		b[i] = ""
	return best

## the game over? He says so, the score goes up, and in a moment a new one
func _settle() -> bool:
	var w := winner(board)
	if w == "":
		return false
	over = true
	games += 1
	if w == "X":
		wins += 1
		_line("alcalde_raya_pierde")
	elif w == "O":
		losses += 1
		_line("alcalde_raya_gana")
	else:
		_line("alcalde_raya_tablas")
	_show_score()
	_timer.start(1.8)
	return true

func _draw_board() -> void:
	var line: Array = []
	var w := winner(board)
	if w == "X" or w == "O":
		for l in LINES:
			if board[l[0]] == w and board[l[1]] == w and board[l[2]] == w:
				line = l
				break
	for i in range(9):
		var b: Button = _cells[i]
		b.text = board[i]
		var c: Color = YELLOW if board[i] == "X" else CREAM
		if not line.is_empty() and not line.has(i):
			c.a = 0.35                     # (the three in a row stand out)
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
			b.add_theme_color_override(k, c)

func _show_score() -> void:
	_score.text = Loc.t("raya_score") % [wins, losses]

func _line(key: String) -> void:
	var said = Loc.t(key)
	_say.text = Loc.t("n_alcalde") + ": " + String(said.pick_random() if said is Array else said)
