extends Node
## The ring in Fonsi's back room. game._physics_process is the only clock.
## act collects edges. Each step settles both contacts before awarding a round.

const HIT := 6.0
const HIT_OPEN := 12.0
const SWING := 16.0
const HAYMAKER := 28.0
const ROUND_TIME := 60.0
const REST := 3.4
const RESULT_TIME := 2.4
const WIND := 0.50
const WIND_BIG := 0.80
const FOE_CONTACT := 0.10
const FOE_RECOVERY := 0.35
const PUNCH_WIND := 0.10
const PUNCH_ACTIVE := 0.05
const PUNCH_RECOVERY := 0.20
const DODGE_START := 0.05
const DODGE_SAFE := 0.20
const DODGE_RECOVERY := 0.25
const COUNTER_TIME := 0.95
const BODY_CHANCE := 0.5
const HEAVY_CHANCE := 0.3
const EPS := 0.000001             # exact step boundaries count as reached

var game
var active := false
var foe
var hp := 100.0
var foe_hp := 100.0
var state := "out"                # idle, wind, contact, recover, rest, out
var t := 0.0                      # time left in Fonsi's phase or the round transition
var guard := false                # Fonsi covers just one height while idle
var foe_low := false
var big := false
var punch_age := -1.0             # seconds from acceptance, negative when at rest
var other_hand := false
var punch_low := false
var dodge_age := -1.0
var dodge_dir := 0
var blocking := false
var low := false                  # current selection; a punch keeps its own height
var touch_low := false
var counter_left := 0.0
var stun := 0.0
var round_n := 1
var wins := 0
var losses := 0
var clock := ROUND_TIME
var lift := 0.0
var crowd: Array = []
var _missed := false
var _orders := {}                 # press edges since the previous physics step
var _side_held := false
var _rng := RandomNumberGenerator.new()
var _down := ""
var _a := Vector2.ZERO
var _b := Vector2.ZERO
var _on_end: Callable
var _old_home := Vector2.ZERO
var _cheer := 2.0
var _time := 0.0
var _my_feedback := ""            # the last contact received by each fighter
var _foe_feedback := ""
var _my_flash := 0.0
var _foe_flash := 0.0

func setup(game_) -> void:
	game = game_
	set_process_input(false)

func start(opponent, on_end: Callable, lift_ := 0.0, crowd_: Array = []) -> void:
	foe = opponent
	_on_end = on_end
	lift = lift_
	crowd = crowd_
	active = true
	set_process_input(true)
	round_n = 1
	wins = 0
	losses = 0
	_time = 0.0
	_cheer = 2.0
	_b = foe.p
	var away: Vector2 = game.player.p - _b
	away = away.normalized() if away.length() > 0.1 else Vector2(1, 0)
	_a = _b + away * 1.55
	_old_home = foe.home
	foe.home = _b
	game.player.p = _a
	game.player.box_gloves(0x216963)
	foe.box_gloves(0xb53d2d)
	game.hud.box(true, foe.shown_name())
	_begin_round()

func _clear_exchange() -> void:
	_orders.clear()
	_side_held = maxf(Input.get_action_raw_strength("left"), Input.get_action_raw_strength("right")) >= Controls.STICK_OFF
	punch_age = -1.0
	dodge_age = -1.0
	dodge_dir = 0
	other_hand = false
	punch_low = false
	blocking = false
	guard = false
	foe_low = false
	big = false
	touch_low = false
	low = false
	stun = 0.0
	counter_left = 0.0
	_missed = false
	_my_feedback = ""
	_foe_feedback = ""
	_my_flash = 0.0
	_foe_flash = 0.0

func _begin_round() -> void:
	_clear_exchange()
	hp = 100.0
	foe_hp = 100.0
	clock = ROUND_TIME
	state = "idle"
	guard = true
	t = 1.6
	_down = ""
	_stand_up()
	game.hud.clear_box_card()
	bell(1)

func _stand_up() -> void:
	for fighter in [game.player, foe]:
		fighter.guard = false
		fighter.punch = 0.0
		fighter.vis.position.x = 0.0
		fighter.inner.rotation = Vector3.ZERO
		fighter.inner.position = Vector3.ZERO
		fighter.anim(false, 0.0, 0.0, false)
		fighter.sync()

func _score() -> String:
	return "%s %d – %d %s" % [Loc.t("box_you"), wins, losses, foe.shown_name()]

func bell(n: int) -> void:
	for i in range(n):
		get_tree().create_timer(i * 0.3).timeout.connect(func():
			Sfx.beep(1568.0, 0.9, 2, -5.0)
			Sfx.beep(3136.0, 0.5, 2, -12.0)
			Sfx.beep(2349.0, 0.7, 1, -16.0))

func direction() -> Vector2:
	return (_b - _a).normalized()

## Only the AI uses this generator. Crowd noise and camera shake cannot change its pattern.
func seed_for_test(value: int) -> void:
	if OS.get_cmdline_user_args().has("--selftest"):
		_rng.seed = value

func act(what: String) -> void:
	if active and state != "rest" and state != "out":
		if what == "punch" or what == "other":
			_orders[what] = Input.is_action_pressed("box_low") or _orders.get(what, false)
		else:
			_orders[what] = true

## Mouse punches must also reach the ring when a HUD control is under the pointer.
func _input(e: InputEvent) -> void:
	if e.is_action_pressed("punch") or e.is_action_pressed("interact") or e.is_action_pressed("handbrake"):
		act("punch")
	elif e.is_action_pressed("box_punch_other"):
		act("other")
	elif e.is_action_pressed("box_low_toggle"):
		act("toggle")
	elif not (e is InputEventJoypadMotion):      # a quick key tap can start and finish between ticks
		if e.is_action_pressed("left"):
			act("left")
		elif e.is_action_pressed("right"):
			act("right")

## The mobile stick uses action_press, without a left/right event. Sample the same
## strengths as the physical stick, with a neutral release before the next dodge.
func _take_orders(covering: bool) -> void:
	var left := Input.get_action_raw_strength("left")
	var right := Input.get_action_raw_strength("right")
	var side := 0
	if not _side_held:
		if left >= Controls.STICK_ON or _orders.has("left"):
			side = -1
		elif right >= Controls.STICK_ON or _orders.has("right"):
			side = 1
	if maxf(left, right) >= Controls.STICK_ON:
		_side_held = true
	elif maxf(left, right) <= Controls.STICK_OFF:
		_side_held = false
	if not Touch.on:
		touch_low = false
	elif _orders.has("toggle"):
		touch_low = not touch_low
	low = touch_low or Input.is_action_pressed("box_low")
	# Selection first. If both are eligible, dodge beats punch, left beats right,
	# and the primary hand beats the other one. Never buffer a rejected command.
	if stun <= EPS and punch_age < 0.0:
		if side != 0 and dodge_age < 0.0:
			dodge_dir = side
			dodge_age = 0.0
		elif dodge_age < 0.0 or dodge_age + EPS >= DODGE_START + DODGE_SAFE:
			if _orders.has("punch") or _orders.has("other"):
				punch_age = 0.0
				other_hand = not _orders.has("punch")
				punch_low = low or _orders["other" if other_hand else "punch"]
	blocking = covering and stun <= EPS and punch_age < 0.0 and dodge_age < 0.0
	_orders.clear()

func _wind_up() -> void:
	state = "wind"
	foe_low = _rng.randf() < BODY_CHANCE
	big = _rng.randf() < HEAVY_CHANCE
	t = WIND_BIG if big else WIND
	guard = false
	_missed = false

func _next_idle() -> void:
	state = "idle"
	guard = _rng.randf() < 0.5
	foe_low = _rng.randf() < BODY_CHANCE
	t = _rng.randf_range(0.8, 1.7) * lerpf(0.65, 1.0, foe_hp / 100.0)
	_missed = false

func tick(dt: float, covering: bool) -> void:
	if not active:
		return
	if state == "out" or state == "rest":
		t -= dt
		if t <= EPS:
			if state == "out":
				_leave()
				return
			round_n += 1
			_begin_round()
	else:
		_step(dt, covering)
	_present(dt)

func _step(dt: float, covering: bool) -> void:
	clock = maxf(0.0, clock - dt)
	if clock <= EPS:
		clock = 0.0
		_round_over(hp >= foe_hp, false)
		return
	_take_orders(covering)
	stun = maxf(0.0, stun - dt)
	counter_left = maxf(0.0, counter_left - dt)
	_my_flash = maxf(0.0, _my_flash - dt)
	_foe_flash = maxf(0.0, _foe_flash - dt)
	if dodge_age >= 0.0:
		dodge_age += dt
		if dodge_age + EPS >= DODGE_START + DODGE_SAFE + DODGE_RECOVERY:
			dodge_age = -1.0
	var my_contact := false
	if punch_age >= 0.0:
		var before := punch_age
		punch_age += dt
		my_contact = before + EPS < PUNCH_WIND and punch_age + EPS >= PUNCH_WIND
		if punch_age + EPS >= PUNCH_WIND + PUNCH_ACTIVE + PUNCH_RECOVERY:
			punch_age = -1.0
	t -= dt
	var his_contact := state == "wind" and t <= EPS
	# Contacts use the poses at this instant, before either fighter reacts.
	# Guard on the last idle step is the guard you actually saw.
	if my_contact or his_contact:
		_contacts(my_contact, his_contact)
		if hp <= 0.0 or foe_hp <= 0.0:
			_round_over(foe_hp <= 0.0, true)    # a double fall goes to the player
			return
	if t > EPS:
		return
	match state:
		"idle":
			_wind_up()
			Sfx.beep(410.0 if foe_low else 720.0, 0.09, 1, -14.0)
		"wind":
			state = "contact"
			t = FOE_CONTACT
		"contact":
			state = "recover"
			t = COUNTER_TIME - FOE_CONTACT if _missed else FOE_RECOVERY
		"recover":
			_next_idle()

func _contacts(mine: bool, his: bool) -> void:
	var to_him := 0.0
	var to_me := 0.0
	var my_result := ""
	var his_result := ""
	if mine:
		if state == "idle" and guard and foe_low == punch_low:
			to_him = 1.0
			my_result = "block"
		elif counter_left > EPS:              # [miss, miss + COUNTER_TIME), tested at contact
			to_him = HIT_OPEN
			my_result = "counter"
		else:
			to_him = HIT
			my_result = "hit"
	if his:
		if dodge_age + EPS >= DODGE_START and dodge_age + EPS < DODGE_START + DODGE_SAFE:
			his_result = "miss"
		else:
			to_me = HAYMAKER if big else SWING
			his_result = "block" if blocking and low == foe_low else "hit"
			if his_result == "block":
				to_me *= 0.2
	hp = maxf(0.0, hp - to_me)
	foe_hp = maxf(0.0, foe_hp - to_him)
	if my_result == "counter":
		counter_left = 0.0
	if his_result == "miss":
		_missed = true
		counter_left = COUNTER_TIME
	elif his_result == "hit":
		stun = 0.4                       # stops new orders; a committed punch still reaches contact
		blocking = false
	if mine:
		_foe_feedback = my_result
		_foe_flash = 0.26
		_contact_sound(my_result, false)
	if his:
		_my_feedback = his_result
		_my_flash = 0.30
		_contact_sound(his_result, true)

func _contact_sound(result: String, incoming: bool) -> void:
	match result:
		"miss":
			Sfx.noise(0.055, -21.0)
			Sfx.beep(620.0, 0.13, 1, -13.0, 450.0)
		"block":
			Sfx.beep(235.0, 0.07, 0, -13.0)
		"hit":
			Sfx.noise(0.10, -9.0)
			Sfx.beep(135.0 if incoming else 170.0, 0.12, 2, -9.0, -60.0)
			game.shake = maxf(game.shake, 0.4 if incoming else 0.15)
		"counter":
			Sfx.noise(0.12, -7.0)
			Sfx.beep(185.0, 0.14, 2, -8.0, -80.0)
			Sfx.jingle([784, 1175], 0.075)
			game.shake = maxf(game.shake, 0.28)

func _round_over(mine: bool, floored: bool) -> void:
	_clear_exchange()
	_stand_up()
	if mine:
		wins += 1
	else:
		losses += 1
	_down = ("foe" if mine else "me") if floored else ""
	bell(3)
	if floored:
		Sfx.noise(0.5, -6.0)
	_cheer_from(crowd)
	if wins >= 2 or losses >= 2:
		state = "out"
		t = RESULT_TIME
		game.hud.show_card(Loc.t("box_ko" if floored else "box_points"), Loc.t("box_won" if mine else "box_lost"))
		Sfx.jingle([523, 659, 784, 1047] if mine else [392, 330, 262, 196], 0.14)
	else:
		state = "rest"
		t = REST
		game.hud.show_card(Loc.t("box_round_end") % round_n, _score())
		Sfx.jingle([523, 659, 784] if mine else [392, 330, 262], 0.12)

func _leave() -> void:
	active = false
	set_process_input(false)
	var done := _on_end
	_on_end = Callable()
	_clear_exchange()
	_down = ""
	foe.home = _old_home
	foe.y = 0.0
	game.player.y = 0.0
	foe.box_gloves()
	game.player.box_gloves()
	_stand_up()
	for n in crowd:
		n.y = 0.0
		n.tick_bark(INF)
		n.sync()
	crowd = []
	game.shake = 0.0
	game.hud.box(false, "")
	done.call(wins >= 2)

## Presentation reads the resolved step. Both models use the hands and scale of their own avatar.
func _pose(fighter, pose: String, body: bool, left_hand: bool, reach := 0.0) -> void:
	var y := 0.76 if body else 1.25
	var left := Vector3(-0.28, y, 0.39)
	var right := Vector3(0.28, y, 0.39)
	var tilt := Vector3.ZERO
	var dip := 0.0
	match pose:
		"ready":
			left.y = 0.88
			right.y = 0.88
		"block", "brace":
			left = Vector3(-0.18, y, 0.50)
			right = Vector3(0.18, y, 0.50)
			tilt.x = -0.12 if pose == "brace" else 0.13
		"wind", "strike", "return":
			var side := -1.0 if left_hand else 1.0
			var start := Vector3(side * (0.60 if body else 0.76), 0.58 if body else 1.52, 0.30)
			if pose == "return":
				start = left if left_hand else right
			var hand := start.lerp(Vector3(side * 0.16, y, 1.02), reach)
			if left_hand:
				left = hand
			else:
				right = hand
			tilt = Vector3(lerpf(0.33 if body else -0.24, 0.20, reach), side * lerpf(-0.32, 0.19, reach), side * 0.10)
			dip = -0.16 if body else 0.0
			if pose == "return":
				tilt *= reach
				dip *= reach
		"open":
			left = Vector3(-0.61, 0.57, 0.14)
			right = Vector3(0.60, 0.64, 0.25)
			tilt = Vector3(0.35, -0.21, 0.16)
		"hit", "counter":
			left = Vector3(-0.45, 0.77, 0.15)
			right = Vector3(0.45, 0.70, 0.07)
			tilt = Vector3(-0.46, 0.25, -0.24) if pose == "counter" else Vector3(-0.24, 0.08, -0.08)
		"down":
			tilt.x = -PI / 2.0
			dip = 0.35
	fighter.box_hands(left, right)
	fighter.inner.rotation = tilt
	fighter.inner.position.y += dip

func _present(dt: float) -> void:
	_time += dt
	var pl = game.player
	var dir := direction()
	pl.p = _a
	pl.h = atan2(dir.x, dir.y)
	foe.h = atan2(-dir.x, -dir.y)
	pl.guard = blocking
	foe.guard = guard and state == "idle"
	for fighter in [pl, foe]:
		fighter.y = lift
		fighter.anim(false, dt, 0.0)
		fighter.sync()
	var sway := 0.0
	if dodge_age >= 0.0:
		sway = smoothstep(0.0, DODGE_START, dodge_age) * (1.0 - smoothstep(DODGE_START + DODGE_SAFE, DODGE_START + DODGE_SAFE + DODGE_RECOVERY, dodge_age))
	pl.vis.position.x = -dodge_dir * 0.75 * sway
	if _down == "me":
		_pose(pl, "down", false, false)
	elif punch_age >= 0.0:
		var reach := smoothstep(0.0, PUNCH_WIND, punch_age) * (1.0 - smoothstep(PUNCH_WIND + PUNCH_ACTIVE, PUNCH_WIND + PUNCH_ACTIVE + PUNCH_RECOVERY, punch_age))
		_pose(pl, "return" if punch_age > PUNCH_WIND + PUNCH_ACTIVE else "strike", punch_low, other_hand, reach)
		if stun > EPS:
			pl.inner.rotation.x -= 0.18
	elif stun > EPS:
		_pose(pl, "hit", low, false)
	elif blocking and _my_flash > EPS and _my_feedback == "block":
		_pose(pl, "brace", low, false)
	else:
		_pose(pl, "block" if blocking else "stance", low, false)
		pl.inner.rotation.z += dodge_dir * 0.33 * sway
	if _down == "foe":
		_pose(foe, "down", false, false)
	elif state == "wind":
		_pose(foe, "wind", foe_low, foe_low)
	elif _foe_flash > EPS and _foe_feedback == "counter":
		_pose(foe, "counter", foe_low, false)
	elif state == "contact":
		_pose(foe, "strike", foe_low, foe_low, 1.0)
	elif _missed:
		_pose(foe, "open", false, false)
	elif _foe_flash > EPS:
		_pose(foe, "brace" if _foe_feedback == "block" else _foe_feedback, foe_low, false)
	elif state == "recover":
		_pose(foe, "return", foe_low, foe_low, smoothstep(0.0, FOE_RECOVERY, t))
	else:
		_pose(foe, "block" if foe.guard else "ready", foe_low, false)
	var fighting := state != "out" and state != "rest"
	for i in range(crowd.size()):
		crowd[i].y = maxf(0.0, sin(_time * (5.0 + i % 3) + i * 1.7)) * (0.28 if not fighting or _foe_flash > EPS or stun > EPS else 0.07)
	_cheer -= dt
	if _cheer <= 0.0:
		_cheer = randf_range(1.2, 2.6)
		var who: Array = crowd if not crowd.is_empty() else game.npcs.filter(func(n): return n != foe and n.visible and not n.away and n.state == "idle" and n.p.distance_to(_a) < 26.0)
		_cheer_from(who)
	game.hud.box_set(hp / 100.0, foe_hp / 100.0)
	var secs := ceili(clock)
	game.hud.box_round("%s %d   ·   %s   ·   %d:%02d" % [Loc.t("box_round_tag"), round_n, _score(), secs / 60, secs % 60], _cue(), low)

func _cheer_from(neighbours: Array) -> void:
	if not neighbours.is_empty() and not neighbours.any(func(n): return n.is_barking()):
		neighbours.pick_random().bark(Loc.t("box_cheer").pick_random(), 2.2)

func _cue() -> String:
	if state == "rest" or state == "out":
		return ""
	if state == "wind":
		return "box_warn_body" if foe_low else "box_warn_high"
	if counter_left > EPS:
		return "box_dodge"
	if _foe_flash > EPS and _foe_feedback == "counter":
		return "box_counter"
	if _my_flash > EPS:
		return "box_block" if _my_feedback == "block" else "box_taken"
	if _foe_flash > EPS:
		return "box_foe_block" if _foe_feedback == "block" else "box_landed"
	return "box_watch"
