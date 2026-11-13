extends Control
## Draws the street map: a small north-up minimap around the player, or the whole town when full = true.

var full := false
var center := Vector2.ZERO
var heading := 0.0
var round := false           # on its plate: no frame of its own, and it turns so that the way you look is up
var spin := 0.0              # ...which is this way (the camera's heading)
var radius := 150.0
var target = null            # Vector2 or null
var givers: Array = []       # [where, round photo (or null)]: who has a mission for you (marcas.gd)
var cars: Array = []
var cops: Array = []
var repairs: Array = []
var ramps: Array = []
var blink := false
var _passes := [[], [], []]  # segments by road kind: asphalt, dirt, footpath
const CELL := 90.0
var _seg_cells := [{}, {}, {}]      # the same, by map cell: Vector2i -> Array (so the minimap only looks at what is near)
var _ring_cells := {}

func _cell(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / CELL)), int(floor(p.y / CELL)))

func _ready() -> void:
	clip_contents = true
	for s in MapData.segs:
		_passes[s.road["k"]].append(s)
		var cells: Dictionary = _seg_cells[s.road["k"]]
		var key := _cell((s.a + s.b) / 2.0)
		if not cells.has(key):
			cells[key] = []
		cells[key].append(s)
	for ring in MapData.outlines:
		var key2 := _cell(ring[0])
		if not _ring_cells.has(key2):
			_ring_cells[key2] = []
		_ring_cells[key2].append(ring)

func _draw() -> void:
	var sz := size
	var k: float
	var c: Vector2
	if full:
		k = minf(sz.x / (MapData.xmax - MapData.xmin), sz.y / (MapData.zmax - MapData.zmin))
		c = Vector2((MapData.xmin + MapData.xmax) / 2.0, (MapData.zmin + MapData.zmax) / 2.0)
	else:
		k = sz.x / (2.0 * radius)
		c = center
	var half := sz / 2.0
	var mid := half                               # (the middle of the control, whatever the turning does to `half`)
	draw_rect(Rect2(Vector2.ZERO, sz), Color("e9d9a6"))
	if round and not full:                        # from here on everything is drawn from the middle, turned
		draw_set_transform(half, spin - PI, Vector2.ONE)
		half = Vector2.ZERO
	var reach := (radius + 60.0) * (radius + 60.0)
	var cols := [Color("fffdf6"), Color("cdb07a"), Color("f3ead2")]
	if full:
		for ring in MapData.outlines:          # city blocks
			var pts := PackedVector2Array()
			for q in ring:
				pts.append((q - c) * k + half)
			pts.append(pts[0])
			draw_polyline(pts, Color("b79c6e"), 1.0)
		for pass_i in [1, 2, 0]:
			for s in _passes[pass_i]:
				draw_line((s.a - c) * k + half, (s.b - c) * k + half, cols[pass_i], maxf(2.0 if pass_i == 0 else 1.0, s.hw * 2.0 * k * 0.8))
	else:
		var here := _cell(c)
		var span := int(ceil((radius + 60.0) / CELL))
		for cx in range(here.x - span, here.x + span + 1):
			for cy in range(here.y - span, here.y + span + 1):
				for ring in _ring_cells.get(Vector2i(cx, cy), []):
					if ring[0].distance_squared_to(c) > reach:
						continue
					var pts := PackedVector2Array()
					for q in ring:
						pts.append((q - c) * k + half)
					pts.append(pts[0])
					draw_polyline(pts, Color("b79c6e"), 1.0)
		for pass_i in [1, 2, 0]:
			var cells: Dictionary = _seg_cells[pass_i]
			for cx in range(here.x - span, here.x + span + 1):
				for cy in range(here.y - span, here.y + span + 1):
					for s in cells.get(Vector2i(cx, cy), []):
						if s.a.distance_squared_to(c) > reach:
							continue
						draw_line((s.a - c) * k + half, (s.b - c) * k + half, cols[pass_i], maxf(2.0 if pass_i == 0 else 1.0, s.hw * 2.0 * k * 0.8))
	var pts: PackedVector2Array = MapData.route_pts
	if pts.size() > 1:
		var line := PackedVector2Array()
		line.append((center - c) * k + half)
		for q in pts:
			line.append((q - c) * k + half)
		draw_polyline(line, Color("f2a900"), 4.0)
	for q in cars:
		if not full and q.distance_squared_to(c) > reach:
			continue
		draw_rect(Rect2((q - c) * k + half - Vector2(2, 2), Vector2(4, 4)), Color("7b5ea7"))
	for q in repairs:           # talleres / gasolineras
		draw_rect(Rect2((q - c) * k + half - Vector2(4, 4), Vector2(8, 8)), Color("21b6d7"))
	for q in ramps:
		var rp: Vector2 = (q - c) * k + half
		draw_colored_polygon(PackedVector2Array([rp + Vector2(0, -5), rp + Vector2(5, 4), rp + Vector2(-5, 4)]), Color("f28c1e"))
	for q in cops:              # Los Pitufos
		draw_circle((q - c) * k + half, 5.0, Color("2f6bff") if blink else Color("ffffff"))
	if target != null:
		var tp: Vector2 = (target - c) * k
		var edge := sz.x / 2.0 - (24.0 if round else 8.0)
		if not full and tp.length() > edge:
			tp = tp.normalized() * edge
		draw_circle(tp + half, 8.0, Color("4a3424"))
		draw_circle(tp + half, 6.0, Color("f2a900"))
	# who has a mission for you: their photo in a circle, kept upright however the map turns; at the edge if far off
	if not givers.is_empty():
		var turn := (spin - PI) if (round and not full) else 0.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for gv in givers:
			var gp: Vector2 = ((gv[0] as Vector2) - c) * k
			var r := 15.0 if full else 13.0
			if not full:
				var edge2 := sz.x / 2.0 - (26.0 if round else 14.0)
				if gp.length() > edge2:
					gp = gp.normalized() * edge2
					r = 10.0
			var at := mid + gp.rotated(turn) if not full else gp + mid
			draw_circle(at, r + 1.5, Color("1a1612"))
			if gv[1] != null:
				draw_texture_rect(gv[1], Rect2(at - Vector2(r, r), Vector2(r, r) * 2.0), false)
			else:
				draw_circle(at, r - 1.0, Color("f2e6c8"))
		if round and not full:
			draw_set_transform(mid, spin - PI, Vector2.ONE)
	var pp := (center - c) * k + half
	var arrow := PackedVector2Array()
	for v in [Vector2(0, -10), Vector2(7, 8), Vector2(0, 4), Vector2(-7, 8)]:
		arrow.append(pp + v.rotated(PI - heading))
	draw_colored_polygon(arrow, Color("e8553d"))
	draw_polyline(arrow + PackedVector2Array([arrow[0]]), Color.WHITE, 1.5)
	if not round:
		draw_rect(Rect2(Vector2.ZERO, sz), Color("4a3424"), false, 4.0)
