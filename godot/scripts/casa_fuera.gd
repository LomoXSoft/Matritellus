extends Node3D
## The outside of the house you inherit, Calle de Alemania 5, in its six states (the user, 21 November 2026, through
## Sistemas: the missions of the house; "Que Pretil haga los modelados y tú los sistemas de juegos"). Six fronts built
## once, all in the same place (casa_fachada.gd), and only one shown and solid:
##
##     G.world.casa_fuera.set_state(n)        n = 0 as inherited · 1 done up · 2, 3, 4 the three enlargements · 5 the upper floor
##
## Sistemas keeps the state (G.stats["casa"]["estado"]) and calls this on loading a game and the morning a work is
## done (fondo_casa.gd). The house of the map (`alemania_5`) is handed over as ["obra"] in casas_calles.gd: casas.gd
## draws nothing of it. Its street door is where it was in every state (`door`, `openings()`).

const FachadaS = preload("res://scripts/casa_fachada.gd")
const HOUSE := "alemania_5"
const STATES := 6

var W
var state := -1
var fronts: Array = []              # the six, in order
var door := Vector2.ZERO            # before its street door, on the map
var pieces := 0                     # of the six together (the self-test)

func build(world, hd: Dictionary) -> void:
	W = world
	W.add_child(self)
	for i in range(STATES):
		var f = FachadaS.new()
		f.build(world, hd, i)
		fronts.append(f)
		pieces += f.pieces
	var f0 = fronts[0]
	door = f0.spot(FachadaS.DOOR.position.x + FachadaS.DOOR.size.x / 2.0, 1.0)
	set_state(0)

## which of its six fronts stands there: the others are neither seen nor solid, and their lanterns are not lit
func set_state(n: int) -> void:
	n = clampi(n, 0, STATES - 1)
	if n == state:
		return
	if state >= 0:                                   # (the lanterns of the front that goes: no longer the town's to light)
		for p in fronts[state].lanterns:
			W.lamp_spots.erase(p)
	for i in range(fronts.size()):
		var f = fronts[i]
		var on: bool = i == n
		f.visible = on
		if f.body != null:
			(f.body as StaticBody3D).collision_layer = 1 if on else 0
	for p in fronts[n].lanterns:
		if not W.lamp_spots.has(p):
			W.lamp_spots.append(p)
	state = n

## the openings of the front as it stands now, for whoever needs them (casa_dentro.gd): [[Rect2 (x along the front from
## its left end as seen from the street, y from the pavement), "door" | "win" | "gate" | "garage"], ...]
func openings() -> Array:
	return fronts[maxi(state, 0)].openings() if not fronts.is_empty() else []

## how high its eaves are now
func top() -> float:
	return fronts[maxi(state, 0)].top if not fronts.is_empty() else 3.5
