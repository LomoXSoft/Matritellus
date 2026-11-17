extends Node3D
## The town after dark. Iron lanterns on brackets up the house fronts (there is one every few doors, as in any
## Manchego village), the lamp posts of the plaza, and the glow in front of the shops, the garage and the terrazas.
##
## There are a couple of thousand lanterns and only so many real lights the renderer can afford, so the lantern
## glass simply glows, and a small pool of real lights is kept on whichever lanterns are nearest to you.

const Parts = preload("res://scripts/parts.gd")

const POOL := 16               # real lights shared out among the nearest lanterns (32 until 17 Nov 2026: the night cost 8 ms more than the day)
const CELL := 48.0
const WARM := Color(1.0, 0.8, 0.5)

var game
var night := 0.0
var spots: Array = []          # Vector3: where each lantern hangs
var _grid := {}                # Vector2i -> Array of indices into spots
var _pool: Array = []          # OmniLight3D
var _shop: Array = []          # [OmniLight3D, energy when fully dark]
var _glass: StandardMaterial3D
var _t := 0.0

func setup(game_) -> void:
	game = game_
	_glass = StandardMaterial3D.new()
	_glass.albedo_color = Color(0.93, 0.9, 0.8)
	_glass.emission_enabled = true
	_glass.emission = WARM
	_glass.emission_energy_multiplier = 0.0
	_lanterns()
	for i in range(POOL):
		var l := OmniLight3D.new()
		l.light_color = WARM
		l.omni_range = 17.0
		l.omni_attenuation = 1.0
		l.shadow_enabled = false
		l.light_energy = 0.0
		l.visible = false
		l.distance_fade_enabled = true
		l.distance_fade_begin = 85.0
		l.distance_fade_length = 25.0
		add_child(l)
		_pool.append(l)

func _add_spot(p: Vector3) -> void:
	spots.append(p)
	var key := Vector2i(int(floor(p.x / CELL)), int(floor(p.z / CELL)))
	if not _grid.has(key):
		_grid[key] = []
	_grid[key].append(spots.size() - 1)

## one lantern every so often along every house front that looks onto a street
func _lanterns() -> void:
	var taken := {}
	var places: Array = []         # [Vector3 position, heading]
	for style in range(MapData.walls.size()):
		if style == 4:
			continue                # (warehouses go without)
		var w: Array = MapData.walls[style]
		for i in range(0, w.size(), 7):
			var a := Vector2(w[i], w[i + 1])
			var b := Vector2(w[i + 2], w[i + 3])
			var length := a.distance_to(b)
			if length < 5.0 or a.length() > 1500.0:
				continue
			var n := Vector2(b.y - a.y, -(b.x - a.x)) / length          # outwards (the rings are counter-clockwise)
			var mid := (a + b) / 2.0
			var out := mid + n * 3.0                                   # (so each side of a street gets its own)
			var cell := Vector2i(int(floor(out.x / 13.0)), int(floor(out.y / 13.0)))
			if taken.has(cell):
				continue
			if MapData.road_edge_dist(mid + n * 2.5) > 5.5:
				continue            # a back wall, a yard: nobody to light the way for
			taken[cell] = true
			var h: float = minf(float(w[i + 4]) - 0.7, 3.5)
			var street: float = MapData.height(mid + n * 0.62)
			if style < MapData.wall_y.size():               # (never over the eaves, though, where the street runs high against the house)
				h = minf(h, float(MapData.wall_y[style][i / 7]) + float(w[i + 4]) - 0.5 - street)
			h += street
			places.append([Vector3(mid.x + n.x * 0.62, h, mid.y + n.y * 0.62), atan2(n.x, n.y)])
	var iron := MultiMesh.new()
	iron.transform_format = MultiMesh.TRANSFORM_3D
	iron.mesh = BoxMesh.new()
	iron.instance_count = places.size() * 2
	var glass := MultiMesh.new()
	glass.transform_format = MultiMesh.TRANSFORM_3D
	glass.mesh = BoxMesh.new()
	glass.instance_count = places.size()
	for k in range(places.size()):
		var at: Vector3 = places[k][0]
		var turn := Basis(Vector3.UP, places[k][1])
		iron.set_instance_transform(k * 2, Transform3D(turn * Basis.from_scale(Vector3(0.06, 0.06, 0.66)), at + turn * Vector3(0, 0.36, -0.3)))      # the bracket
		iron.set_instance_transform(k * 2 + 1, Transform3D(turn * Basis.from_scale(Vector3(0.4, 0.07, 0.4)), at + Vector3(0, 0.27, 0)))               # the cap
		glass.set_instance_transform(k, Transform3D(turn * Basis.from_scale(Vector3(0.3, 0.46, 0.3)), at))
		_add_spot(at + turn * Vector3(0, -0.1, 0.7))
	for pair in [[iron, Parts.mat(0x24262b)], [glass, _glass]]:
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = pair[0]
		mi.material_override = pair[1]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)

## a lamp post somebody else has built (the plaza): it joins the lanterns
func add_lamp(p: Vector3) -> void:
	_add_spot(p)

## a light that belongs to a place: a shop window, the garage door, a terraza
func add_shop(p: Vector3, colour := WARM, reach := 13.0, energy := 2.2) -> void:
	var l := OmniLight3D.new()
	l.position = p
	l.light_color = colour
	l.omni_range = reach
	l.omni_attenuation = 1.2
	l.shadow_enabled = false
	l.light_energy = 0.0
	l.visible = false
	l.distance_fade_enabled = true
	l.distance_fade_begin = 110.0
	l.distance_fade_length = 30.0
	add_child(l)
	_shop.append([l, energy])

## how far the night has fallen (0..1): the lanterns come on with it
func set_night(n: float) -> void:
	night = n
	var on := smoothstep(0.12, 0.55, n)
	_glass.emission_energy_multiplier = on * 3.2
	Parts.mat(0xfff1c4).emission_enabled = on > 0.0              # the glass of the plaza's lamp posts
	Parts.mat(0xfff1c4).emission = WARM
	Parts.mat(0xfff1c4).emission_energy_multiplier = on * 3.0
	for s in _shop:
		(s[0] as OmniLight3D).visible = on > 0.01
		(s[0] as OmniLight3D).light_energy = float(s[1]) * on
	for l in _pool:
		(l as OmniLight3D).visible = on > 0.01
		(l as OmniLight3D).light_energy = 3.0 * on

## now and then: move the real lights to the lanterns nearest to where you are
func tick(dt: float, around: Vector2) -> void:
	_t -= dt
	if _t > 0.0 or night < 0.1:
		return
	_t = 0.4
	var near: Array = []
	var cx := int(floor(around.x / CELL))
	var cz := int(floor(around.y / CELL))
	for ax in range(-2, 3):
		for az in range(-2, 3):
			var l = _grid.get(Vector2i(cx + ax, cz + az))
			if l == null:
				continue
			for i: int in l:
				var p: Vector3 = spots[i]
				near.append([Vector2(p.x, p.z).distance_squared_to(around), i])
	near.sort_custom(func(a, b): return a[0] < b[0])
	# a light that is already on one of the chosen lanterns stays there, so nothing flickers as you walk
	var want := {}
	for k in range(mini(POOL, near.size())):
		want[near[k][1]] = true
	var free: Array = []
	for l in _pool:
		var on_spot: int = l.get_meta("spot", -1)
		if want.has(on_spot):
			want.erase(on_spot)
		else:
			free.append(l)
	for i in want:
		if free.is_empty():
			break
		var l2: OmniLight3D = free.pop_back()
		l2.position = spots[i]
		l2.set_meta("spot", i)
