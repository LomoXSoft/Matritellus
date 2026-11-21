extends RefCounted
## The pedestrian stretch of the Calle Real, from its crossroads with Colón and La Palma down among the shops: no
## asphalt and no kerbs, but grey granite setts down the middle and reddish brick pavers along the houses, all at one
## level (Street View, November 2024; the user, 15 November 2026: "es zona peatonal y el suelo está empedrado").
## The bake turns that stretch into a footpath as wide as a street (k 2, w 7.5: tools/bake_godot.py, PAVED), so no
## traffic drives it and no parked cars stand in it; this lays its paving over the plain footpath the world draws.
## The tiles are drawn by tools/empedrado_tex.py.

const AcerasAltas = preload("res://scripts/aceras_altas.gd")

const ROAD_Y := -0.18             # (world.gd's: the flat layers stacked just under the ground you drive on)
const BRICK_LIFT := 0.165
const SETT_LIFT := 0.175
const LANE_LIFT := 0.17           # (the grey lanes: over the footpath, 0.15, like the setts)
const OPEN_BRICK := 0.185         # (a paved street cars drive: its brick and its setts go over its own asphalt, 0.18,
const OPEN_SETTS := 0.19          #  and under the white paint of the crossings, 0.2)

static func add(world) -> void:
	for r in MapData.roads:
		if int(r["k"]) != 2 or float(r["w"]) < 7.0 or int(r.get("paved", 0)) == 2 or int(r.get("paved", 0)) >= 4:   # (only a street made pedestrian: footpaths are narrower; the grey lanes below; the fairground's lay their own asphalt, ferial.gd; the Travesía del Clavel is floored by travesia.gd, "paved" 5)
			continue
		# the brick bands: the whole width, on under the houses as the pavements of a car street do
		var hw_all := func(_i: int) -> float: return (float(r["w"]) + 3.2) / 2.0
		_lay(world, r, hw_all, ROAD_Y + BRICK_LIFT, "res://assets/empedrado/ladrillo.png")
		# the setts: the middle of the street, leaving a band of brick along each side
		var p: PackedInt32Array = r["p"]
		var hw_mid := func(i: int) -> float: return clampf(float(MapData.clr[p[i]]) - 1.1, 1.4, 2.3)
		_lay(world, r, hw_mid, ROAD_Y + SETT_LIFT, "res://assets/empedrado/adoquin.png")
	# Lanes in grey concrete pavers from wall to wall (the bake's PAVED_LANES, "paved" 2: the narrow west end of the Calle
	# de Santo Domingo, Street View, November 2024; the user, 15 November 2026: "Ponle adoquín", and then, as it is too
	# narrow for the game's cars, "Mejor cortar el tráfico ahí"): a footpath as wide as a street, closed to traffic,
	# its whole width paved and on under the houses as the brick of the Calle Real is.
	for r in MapData.roads:
		if int(r.get("paved", 0)) != 2:
			continue
		var hw_lane := func(_i: int) -> float: return (float(r["w"]) + 3.2) / 2.0
		_lay(world, r, hw_lane, ROAD_Y + LANE_LIFT, "res://assets/empedrado/adoquin_gris.png", false)
	# Streets paved like the Calle Real that cars still drive (the bake's PAVED_STREETS, "paved" 3: the Calle de las Monjas
	# by the convent of Santa Ana, Street View, November 2024; the user, 15 November 2026: "La calle está empedrada pero no
	# es peatonal"): brick from house to house, over pavements and asphalt alike, and the lane of setts where the cars go.
	for r in MapData.roads:
		if int(r.get("paved", 0)) != 3:
			continue
		var hw_brick := func(_i: int) -> float: return (float(r["w"]) + 3.2) / 2.0
		_lay(world, r, hw_brick, ROAD_Y + OPEN_BRICK, "res://assets/empedrado/ladrillo.png", false)
		var q: PackedInt32Array = r["p"]
		var hw_setts := func(i: int) -> float: return clampf(float(MapData.clr[q[i]]) - 1.5, 1.5, 2.1)
		_lay(world, r, hw_setts, ROAD_Y + OPEN_SETTS, "res://assets/empedrado/adoquin.png", false)
	# and the high pavements on walls of rubble (the Calle del Arroyuelo Bajo: aceras_altas.gd)
	AcerasAltas.add(world)

## a strip along the road, hw(i) wide each side of node i, laid on the ground y above it in that paving
## (ends: false cuts it square at its two ends instead of rounding them, so it does not spill round a crossing's corners)
static func _lay(world, r: Dictionary, hw: Callable, y: float, tex: String, ends := true) -> void:
	var v := PackedVector3Array()
	var idx := PackedInt32Array()
	var p: PackedInt32Array = r["p"]
	for i in range(p.size()):
		var a: Vector2 = MapData.nodes[p[i]]
		var h0: float = hw.call(i)
		var b0 := v.size()
		v.append(Vector3(a.x, 0, a.y))
		for k in range(8):                       # (a round end at every node, so bends close up)
			var ang := k * PI / 4.0
			v.append(Vector3(a.x + cos(ang) * h0, 0, a.y + sin(ang) * h0))
			if ends or (i > 0 and i + 1 < p.size()):
				idx.append(b0); idx.append(b0 + 1 + k); idx.append(b0 + 1 + (k + 1) % 8)
		if i + 1 == p.size():
			break
		var b: Vector2 = MapData.nodes[p[i + 1]]
		var d := b - a
		if d.length() < 0.01:
			continue
		var h1: float = hw.call(i + 1)
		var n := Vector2(-d.y, d.x).normalized()
		var q := v.size()
		v.append(Vector3(a.x + n.x * h0, 0, a.y + n.y * h0)); v.append(Vector3(a.x - n.x * h0, 0, a.y - n.y * h0))
		v.append(Vector3(b.x - n.x * h1, 0, b.y - n.y * h1)); v.append(Vector3(b.x + n.x * h1, 0, b.y + n.y * h1))
		for o in [0, 1, 2, 0, 2, 3]:
			idx.append(q + o)
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(tex)
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / 2.0           # (each tile is 2 m)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	world._flat(v, idx, 0xffffff, y, null, "", 2.0, m)
