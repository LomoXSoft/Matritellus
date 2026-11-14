extends Node
## The edge of the map (the user, 13 November 2026): an invisible circle round the whole town. Cross it and a red
## count-down of thirty seconds tells you to turn back; still out when it runs out, and everybody comes after you, Los
## Pitufos and the Tricornios together, the heat full. For every thirty seconds you go on staying out, another car joins
## the chase and every one of them goes 5 % faster, until they catch you or you lose them. (One day a helicopter too:
## it would join here, in _more.)

const CENTRE := Vector2(51.0, -33.0)     # the middle of the town (where its buildings average out)
const RADIUS := 1950.0                   # metres: the whole town, its ring roads and every garage, with room to spare
                                         # (it was 1100, and left the cooperative of the very first mission out: the
                                         # bullring, the park and the pool are 1500 m south, a garage 1800 m east)
const EDGE := 80.0                       # ...and never past the end of the built map: out this far short of its edge
const WARN := 30.0                       # seconds to turn back
const EVERY := 30.0                      # seconds out, the chase on, for each new car and the next 5 %
const FASTER := 0.05

var G
var left := WARN                          # of the count-down
var warning := false                      # out of town, being told to turn back
var hunting := false                      # past the count-down: the chase it set off is on
var added := 0                            # cars added to that chase since it began
var _more_t := EVERY

func setup(game) -> void:
	G = game

func outside(p: Vector2) -> bool:
	return p.distance_to(CENTRE) > RADIUS or p.x < MapData.xmin + EDGE or p.x > MapData.xmax - EDGE \
		or p.y < MapData.zmin + EDGE or p.y > MapData.zmax - EDGE

## call every physics tick while in the world; `frozen`: talking, a menu, a scene (the clock stops)
func tick(dt: float, pp: Vector2, frozen: bool) -> void:
	if hunting and not G.police.chasing:          # caught, or lost: that is the end of it
		_stop()
	if frozen:
		_show()
		return
	var out: bool = outside(pp) and not G.indoors
	if hunting:
		if out:
			_more_t -= dt
			if _more_t <= 0.0:
				_more(pp)
	elif out:
		if not warning:
			warning = true
			left = WARN
			Sfx.beep(880.0, 0.25, 2, -10.0)
		var before := int(ceil(left))
		left -= dt
		if left > 0.0 and int(ceil(left)) != before:
			Sfx.beep(660.0, 0.08, 1, -15.0)        # a tick every second
		if left <= 0.0:
			_start(pp)
	elif warning:                                  # back in time
		warning = false
		left = WARN
	_show()

func _start(pp: Vector2) -> void:
	warning = false
	left = WARN
	if G.police.muted:                             # (the Thursday ham run: they are all at lunch, even for this)
		return
	hunting = true
	added = 0
	_more_t = EVERY
	G.police.boost = 1.0
	G.police.all_out(pp)
	G.hud.toast(Loc.t("t_limit_chase"), 4.5)

## another thirty seconds out: one more car, and all of them faster
func _more(pp: Vector2) -> void:
	_more_t = EVERY
	added += 1
	G.police.boost = 1.0 + FASTER * added
	G.police.one_more(pp)
	G.hud.toast(Loc.t("t_limit_more"), 3.5)
	Sfx.jingle([392, 523, 659], 0.12)

func _stop() -> void:
	hunting = false
	added = 0
	G.police.boost = 1.0

func _show() -> void:
	if warning:
		G.hud.show_limit(left)
	else:
		G.hud.hide_limit()

## (a new game, a load: nothing pending)
func reset() -> void:
	warning = false
	hunting = false
	left = WARN
	added = 0
	_more_t = EVERY
	if G != null:
		G.hud.hide_limit()
