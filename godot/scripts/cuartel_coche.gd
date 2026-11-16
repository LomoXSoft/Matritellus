extends Node
## The Tricornios' patrol car parked at the door of their barracks (cuartel.gd), always there and nobody in it (the
## user, 16 November 2026: "deja siempre un coche aparcado de los tricornios en la puerta, sin ocupantes"; and on being
## asked: "Robar el coche: ... ya existía la norma. Entonces déjala así. Al día siguiente vuelve a aparecer uno").
##   - It stands in the yellow box painted before the steps, nose to the door, as theirs do in Street View
##     (`world.cuartel.patrol`: {at, to}).
##   - Getting into it is stealing a car of theirs, and the rule for that is the one there already was (game._steal):
##     the heat meter full -- half of it with a mission under way -- and the chase on.
##   - Once it has gone (you took it, or it was pushed out of its box), the next day another is parked in its place,
##     out of your sight; the one you took stays where you left it, like any car.
## Nothing of it is saved: a game loaded or started has it at the door.

const CarS = preload("res://scripts/car.gd")
const OFF := 4.0                        # out of its box by this much, it has gone
const UNSEEN := 40.0                    # the next one is not parked under your nose

var G
var car = null                          # the one at the door (null while there is none)
var taken := 0                          # how many you have taken
var gone_day := -1                      # the day the last one went (the next comes the day after)
var _t := 0.0

func setup(game) -> void:
	G = game

## where it stands and which way it faces ({} without the barracks, or with no room before it)
func spot() -> Dictionary:
	if G.world == null or G.world.get("cuartel") == null:
		return {}
	return G.world.cuartel.patrol

func _process(dt: float) -> void:
	_t -= dt
	if _t > 0.0:
		return
	_t = 0.5
	var s: Dictionary = spot()
	if s.is_empty() or G.player == null:
		return
	var at: Vector2 = s["at"]
	if car != null and (not is_instance_valid(car) or car == G.in_car or car.p.distance_to(at) > OFF):
		car = null                                   # (gone: the one you took is yours now, wherever you leave it)
		gone_day = int(G.day_n)
	if car != null:
		return
	if gone_day >= 0 and (int(G.day_n) <= gone_day or G.player.p.distance_to(at) < UNSEEN or G.sees(at)):
		return                                       # (the first is there from the start; the next, the day after, unseen)
	for c in G.cars:                                 # (not on top of a car somebody left in its box)
		if is_instance_valid(c) and c.p.distance_to(at) < 3.0:
			return
	park(s)

func park(s: Dictionary) -> void:
	var to: Vector2 = s["to"]
	var c = CarS.new()
	G.add_child(c)
	c.setup("tricornio", 0x2456b8, s["at"], atan2(to.x, to.y))
	c.park()
	G.cars.append(c)
	car = c

## you have just got into a car: if it is theirs, from their door, you have stolen a car of the Tricornios
func entered(c) -> void:
	if c == null or c != car:
		return
	taken += 1
	car = null
	gone_day = int(G.day_n)
	G.police.add_heat(100.0)                     # (the rule for taking a car of theirs, as in game._steal)
