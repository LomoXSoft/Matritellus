extends RefCounted
## The neighbours you know by name, and how far each of them trusts you (the last page of the Agenda).
##
##   saying hello in the street      +3   once a day each (the day turns over at midnight)
##   doing a mission for them        +10
##   a minigame with them            +5   the first time, +1 after that
##   not picking up when they ring   -1
##   hitting them / running them over -3  once a day each
##
## Trust never falls back below a mark it has reached: 25, 50, 75 and 100. At 100 it turns to gold and stays there.

const MARK := 25

var game
var data := {}      # id -> {t: 0..100, floor: the highest mark reached, hi: day last greeted, hit: day last hurt, played: bool}

func setup(game_) -> void:
	game = game_

func reset() -> void:
	data = {}

func restore(saved) -> void:
	data = saved if saved is Dictionary else {}

func knows(id: String) -> bool:
	return data.has(id)

func ids() -> Array:
	return data.keys()

## you have met them: they go in the Agenda (at zero)
func meet(id: String) -> void:
	if id != "" and not data.has(id):
		data[id] = {"t": 0, "floor": 0, "hi": -1, "hit": -1, "played": false}

func trust(id: String) -> int:
	return int(data[id]["t"]) if data.has(id) else 0

func golden(id: String) -> bool:
	return data.has(id) and int(data[id]["floor"]) >= 100

func add(id: String, amount: int) -> void:
	meet(id)
	if not data.has(id):
		return
	var e: Dictionary = data[id]
	var mark: int = int(e["floor"])
	if mark >= 100:
		return                                   # gold: nothing you do changes it now
	var before: int = int(e["t"])
	var t: int = clampi(before + amount, mark, 100)
	e["t"] = t
	e["floor"] = maxi(mark, (t / MARK) * MARK)
	if t != before:
		game.trust_changed(id, t - before, t, t >= 100)

## hello: true if it counted (the first time today)
func greet(id: String, day: int) -> bool:
	meet(id)
	if not data.has(id) or int(data[id]["hi"]) == day:
		return false
	data[id]["hi"] = day
	add(id, 3)
	return true

## hit or run over: only people you know keep count, and only once a day
func hurt(id: String, day: int) -> bool:
	if not data.has(id) or int(data[id]["hit"]) == day:
		return false
	data[id]["hit"] = day
	add(id, -3)
	return true

func played(id: String) -> void:
	meet(id)
	if not data.has(id):
		return
	var first: bool = not bool(data[id]["played"])
	data[id]["played"] = true
	add(id, 5 if first else 1)

func missed_call(id: String) -> void:
	if data.has(id):
		add(id, -1)
