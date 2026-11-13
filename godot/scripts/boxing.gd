extends Node
## A fist fight, Punch-Out style: you see your own back, the other one faces you.
## Read him: when he leans back he is about to swing. Dodge it and he is left wide open for a moment;
## block it and it barely hurts; take it on the chin and it hurts a lot. Hit him when his guard is down.
##
##   dodge left / right   ·   hold back to cover up   ·   punch
##
## Best of three rounds. A round ends when one of the two goes down, or on the bell (then whoever is fresher takes it).

const HIT := 6.0            # a clean punch
const HIT_OPEN := 12.0      # a punch while he is recovering from a miss
const SWING := 16.0         # his normal swing
const HAYMAKER := 28.0      # his big one (longer wind-up)
const ROUND_TIME := 60.0
const REST := 3.4           # seconds between rounds

var game
var active := false
var foe
var hp := 100.0
var foe_hp := 100.0
var state := "idle"         # what he is doing: idle | wind | open | rest (between rounds) | out (it is over)
var guard := false          # his hands are up: punches bounce off
var big := false
var t := 1.4
var dodge := 0.0            # seconds left of your current dodge
var dodge_dir := 0.0
var cool := 0.0             # until you can punch again
var stun := 0.0             # you just got hit
var flinch := 0.0
var round_n := 1
var wins := 0               # rounds you have taken
var losses := 0
var clock := ROUND_TIME
var lift := 0.0             # how high the canvas is (the fighters are drawn that much up)
var crowd: Array = []       # the neighbours round the ring
var _down := ""             # who is on the floor: "" | "me" | "foe"
var _a := Vector2.ZERO      # where you stand
var _b := Vector2.ZERO      # where he stands
var _on_end: Callable
var _cheer := 2.0
var _old_home := Vector2.ZERO
var _time := 0.0

func setup(game_) -> void:
	game = game_

func start(opponent, on_end: Callable, lift_ := 0.0, crowd_: Array = []) -> void:
	foe = opponent
	_on_end = on_end
	lift = lift_
	crowd = crowd_
	active = true
	round_n = 1
	wins = 0
	losses = 0
	_b = foe.p
	var away: Vector2 = (game.player.p - _b)
	away = away.normalized() if away.length() > 0.1 else Vector2(1, 0)
	_a = _b + away * 1.55
	_old_home = foe.home
	foe.home = _b
	game.player.p = _a
	game.player.y = lift
	foe.y = lift
	game.hud.box(true, foe.shown_name())
	_begin_round()
	game.hud.show_card(Loc.t("box_title"), Loc.t("box_hint"))

func _begin_round() -> void:
	hp = 100.0
	foe_hp = 100.0
	clock = ROUND_TIME
	state = "idle"
	guard = true
	t = 1.6
	dodge = 0.0; cool = 0.0; stun = 0.0; flinch = 0.0
	_down = ""
	_stand_up()
	bell(1)
	if round_n > 1:
		game.hud.show_card(Loc.t("box_round") % round_n, _score())

func _stand_up() -> void:
	foe.inner.rotation = Vector3.ZERO
	foe.inner.position = Vector3.ZERO
	game.player.inner.rotation = Vector3.ZERO
	game.player.inner.position = Vector3.ZERO

func _score() -> String:
	return "%s %d – %d %s" % [Loc.t("box_you"), wins, losses, foe.shown_name()]

## ding (ding ding)
func bell(n: int) -> void:
	for i in range(n):
		get_tree().create_timer(i * 0.3).timeout.connect(func():
			Sfx.beep(1568.0, 0.9, 2, -5.0)
			Sfx.beep(3136.0, 0.5, 2, -12.0)
			Sfx.beep(2349.0, 0.7, 1, -16.0))

func direction() -> Vector2:
	return (_b - _a).normalized()

## what: punch | left | right
func act(what: String) -> void:
	if not active or state == "out" or state == "rest" or stun > 0.0:
		return
	if what == "left" or what == "right":
		if dodge <= 0.0:
			dodge = 0.5
			dodge_dir = -1.0 if what == "left" else 1.0
			Sfx.beep(300.0, 0.06, 4, -18.0)
		return
	if cool > 0.0 or dodge > 0.2:
		return
	cool = 0.32
	game.player.punch = 0.28
	if state == "open":
		_hurt_foe(HIT_OPEN)
	elif guard and state == "idle":
		_hurt_foe(1.0)
		Sfx.beep(240.0, 0.07, 0, -14.0)           # thud on his gloves
	else:
		_hurt_foe(HIT)

func _hurt_foe(amount: float) -> void:
	foe_hp = maxf(0.0, foe_hp - amount)
	flinch = 0.18
	if amount > 1.5:
		Sfx.noise(0.1, -9.0)
		Sfx.beep(170.0, 0.1, 2, -8.0, -60.0)
		game.shake = 0.15
	if foe_hp <= 0.0:
		_round_over(true, true)

## the round is yours (or his); floored = somebody went down rather than the clock running out
func _round_over(mine: bool, floored: bool) -> void:
	if mine:
		wins += 1
	else:
		losses += 1
	_down = ("foe" if mine else "me") if floored else ""
	bell(3)
	if floored:
		Sfx.noise(0.5, -6.0)
	for n in crowd:
		if randf() < 0.6:
			n.bark(Loc.t("box_cheer").pick_random(), 2.2)
	if wins >= 2 or losses >= 2:
		_finish(wins >= 2)
		return
	state = "rest"
	t = REST
	game.hud.show_card(Loc.t("box_round_end") % round_n, _score())
	Sfx.jingle([523, 659, 784] if mine else [392, 330, 262], 0.12)

func _finish(won: bool) -> void:
	state = "out"
	t = 2.0
	game.hud.show_card(Loc.t("box_ko") if _down != "" else Loc.t("box_points"), Loc.t("box_won") if won else Loc.t("box_lost"))
	Sfx.jingle([523, 659, 784, 1047] if won else [392, 330, 262, 196], 0.14)
	var done := func():
		active = false
		foe.home = _old_home
		foe.guard = false
		foe.y = 0.0
		game.player.y = 0.0
		game.player.guard = false
		game.player.vis.position.x = 0.0
		_stand_up()
		for n in crowd:
			n.y = 0.0
		game.hud.box(false, "")
		_on_end.call(won)
	get_tree().create_timer(2.4).timeout.connect(done)

func tick(dt: float, covering: bool) -> void:
	if not active:
		return
	_time += dt
	var pl = game.player
	var dir := direction()
	cool -= dt
	stun = maxf(0.0, stun - dt)
	dodge = maxf(0.0, dodge - dt)
	flinch = maxf(0.0, flinch - dt)
	var fighting := state != "out" and state != "rest"
	var blocking := covering and dodge <= 0.0 and stun <= 0.0 and fighting
	if state == "rest":
		t -= dt
		if t <= 0.0:
			round_n += 1
			_begin_round()
	elif fighting:
		clock -= dt
		if clock <= 0.0:                                   # the bell: on points
			clock = 0.0
			_round_over(hp >= foe_hp, false)
	# --- him ---
	if state != "out" and state != "rest":
		t -= dt
		var rage := lerpf(0.65, 1.0, foe_hp / 100.0)       # the worse it goes for him, the faster he swings
		match state:
			"idle":
				if t <= 0.0:
					state = "wind"
					big = randf() < 0.3
					t = (0.8 if big else 0.5) * rage
					guard = false
					Sfx.beep(520.0 if big else 700.0, 0.09, 1, -14.0)
			"wind":
				if t <= 0.0:
					if dodge > 0.0:                         # he hits air and is wide open
						state = "open"
						t = 1.25
						game.hud.toast(Loc.t("box_dodge"), 1.0)
						Sfx.beep(900.0, 0.08, 1, -14.0)
					else:
						var dmg := HAYMAKER if big else SWING
						if blocking:
							dmg *= 0.2
							game.hud.toast(Loc.t("box_block"), 0.8)
							Sfx.beep(220.0, 0.08, 0, -12.0)
						else:
							stun = 0.4
							game.shake = 0.6 if big else 0.35
							Sfx.noise(0.2, -6.0)
							Sfx.beep(130.0, 0.2, 2, -6.0, -50.0)
						hp = maxf(0.0, hp - dmg)
						foe.punch = 0.28
						state = "idle"
						guard = randf() < 0.5
						t = randf_range(0.8, 1.7) * rage
						if hp <= 0.0:
							_round_over(false, true)
			"open":
				if t <= 0.0:
					state = "idle"
					guard = randf() < 0.5
					t = randf_range(0.7, 1.4) * rage
	# --- how they stand ---
	fighting = state != "out" and state != "rest"
	pl.p = _a
	pl.h = atan2(dir.x, dir.y)
	pl.y = lift
	pl.guard = blocking
	pl.anim(false, dt, 0.0)
	pl.sync()
	pl.vis.position.x = -dodge_dir * 0.75 * sin(clampf(dodge / 0.5, 0.0, 1.0) * PI)       # (local x is to the character's left)
	foe.h = atan2(-dir.x, -dir.y)
	foe.y = lift
	foe.guard = guard and state == "idle"
	foe.anim(false, dt, 0.0)
	foe.sync()
	if _down == "me":
		pl.inner.rotation.x = -PI / 2.0
		pl.inner.position.y = 0.35
	else:
		pl.inner.rotation.x = -0.25 if stun > 0.0 else 0.0
	if _down == "foe":
		foe.inner.rotation = Vector3(-PI / 2.0, 0, 0)       # flat on his back
		foe.inner.position.y = 0.35
	elif fighting:
		var lean := 0.0
		var sway := 0.0
		match state:
			"wind":
				lean = -0.4 if big else -0.25                # leans back: here it comes
			"open":
				lean = 0.35
				sway = sin(_time * 9.0) * 0.22               # seeing stars
		if flinch > 0.0:
			lean = -0.3
		foe.inner.rotation.x = lean
		foe.inner.rotation.z = sway
	# --- the neighbours love it ---
	for i in range(crowd.size()):
		crowd[i].y = maxf(0.0, sin(_time * (5.0 + (i % 3)) + i * 1.7)) * (0.28 if not fighting or flinch > 0.0 or stun > 0.0 else 0.07)
	_cheer -= dt
	if _cheer <= 0.0:
		_cheer = randf_range(1.2, 2.6)
		var who: Array = crowd if not crowd.is_empty() else game.npcs.filter(func(n): return n != foe and n.visible and not n.away and n.state == "idle" and n.p.distance_to(_a) < 26.0)
		who = who.filter(func(n): return not n.is_barking())
		if not who.is_empty():
			who.pick_random().bark(Loc.t("box_cheer").pick_random(), 2.4)
	game.hud.box_set(hp / 100.0, foe_hp / 100.0)
	game.hud.box_round("%s %d   ·   %s   ·   %d:%02d" % [Loc.t("box_round_tag"), round_n, _score(), int(ceil(clock)) / 60, int(ceil(clock)) % 60])
