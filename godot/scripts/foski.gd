extends RefCounted
## Foski (the user, 25 November 2026, with a picture of how he looks: "Mientras termina Pretil vamos a añadir otro NPC
## único. De momento sin misiones, solo andará dando vueltas por la calle del florido. Se llamará Foski").
##
##   Where: up and down the Calle del Florido, at any hour, along its pavement and back at its ends (game.gd
##   _walker_plan: a walker with a "beat", like those of the cholesterol route). No missions yet.
##   Looks (the user: "Tatuajes, camisetas negras de grupos de metal, dejadez, hermoso"): big, short dark hair (style 14:
##   of the two tried, "El primer corte de pelo se parecía más"), a trimmed
##   beard, thick black glasses, a hoop in one ear; a black T-shirt with the logo of a metal band nobody can read (made
##   up here, a different one each day: logo()); ink on the backs of his hands and a ring (the game's people have no
##   arms: the hands are where his tattoos can be).
##   What he says (Loc "foski", the user: "Le gusta el metal, el anime, tiene diversos problemas de salud (bromea con no
##   llegar a los 40), le gustan las góticas y las transexuales, dice bastantes tacos hablando y es malablado en general,
##   (pero es buen tío). Que haya una broma donde bromee sobre suicidarse y luego haya un *silencio incómodo* antes de
##   continuar la conversación"): game.gd _chat goes through his talks in turn. The silence is a line written
##   "~~silencio incómodo~~": Loc.rich shows it in grey between asterisks, and it is not voiced (game.gd).

const LOOK := {"top": 0, "shirt": 0x1d1c20, "skin": 0xf0c4a0, "hair": 0x1c1612, "hair_style": 14, "face": 9, "brows": 1,
	"eyes": 0, "eye_color": 0x3a2416, "glasses": 7, "earrings": 3, "build": 1.32, "shoes": 0x1b1b1f, "hat": ""}
const STREET := "Calle del Florido"
const PACE := 1.05              # metres a second: he is in no hurry
const BANDS := [6661, 1349, 7734, 4242]         # the seeds of his T-shirts' logos: one a day, in turn
const INK := 0x34424c
const EVERY := 5.0

var G
var n                           # himself (npc.gd)
var _print: StandardMaterial3D  # the logo on his chest
var _day := -1
var _t := 0.0

func setup(game) -> void:
	G = game
	var beat := street()
	n = G._make_npc("foski", LOOK.duplicate(), "adult_m", start())
	n.still = false
	if not beat.is_empty():
		n.walker = true
		n.beat = beat
		n.wspeed = PACE
	dress(n)

## the road nodes of his street (a walker's "beat")
func street() -> Dictionary:
	var out := {}
	for i in line():
		out[i] = true
	return out

## his street's nodes, in order from one end to the other
func line() -> PackedInt32Array:
	for r in MapData.roads:
		if String(r["n"]) == STREET:
			return r["p"]
	return PackedInt32Array()

## where he starts from: the pavement, half way along
func start() -> Vector2:
	var pts := line()
	if pts.is_empty():                           # (a map without the street: by the square, then)
		return G._pavement(MapData.poi("Ayuntamiento"))
	return G._pavement(MapData.nodes[pts[pts.size() / 2]])

## how far a spot is from the middle of his street
func off_street(at: Vector2) -> float:
	var pts := line()
	var best := 1e9
	for i in range(pts.size() - 1):
		best = minf(best, Geometry2D.get_closest_point_to_segment(at, MapData.nodes[pts[i]], MapData.nodes[pts[i + 1]]).distance_to(at))
	return best

func tick(dt: float) -> void:
	_t -= dt
	if _t > 0.0 or n == null or not is_instance_valid(n):
		return
	_t = EVERY
	if int(G.day_n) != _day and _print != null:      # (another day, another T-shirt: all of them black)
		_day = int(G.day_n)
		_print.albedo_texture = logo(int(BANDS[_day % BANDS.size()]))

## what is his alone, on him: the band's logo across the chest, the ink on his hands, the ring
func dress(c) -> void:
	_print = StandardMaterial3D.new()
	_print.albedo_texture = logo(int(BANDS[0]))
	_print.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	_print.alpha_scissor_threshold = 0.5
	_print.roughness = 1.0
	_print.albedo_color = Color(0.93, 0.93, 0.93)      # (a print on cotton washed too many times)
	print_on(c, _print, 0.25, 0.7, 2.0, "foski_logo")
	# ink on the backs of both hands (a hand is a ball: its own measures, one is its radius), a silver ring on one
	for hand in [c._hl, c._hr]:
		if hand == null:
			continue
		var sx: float = signf(hand.position.x)
		for d in [Vector3(sx * 0.75, 0.6, 0.25), Vector3(sx * 0.9, 0.05, 0.42), Vector3(sx * 0.62, 0.3, -0.72), Vector3(sx * 0.3, 0.9, -0.3), Vector3(sx * 0.95, -0.3, -0.1)]:
			var mark := Parts.part("ball", INK, (d as Vector3).normalized() * 0.84, Vector3.ONE * 0.24)
			hand.add_child(mark)
	if c._hr != null:
		c._hr.add_child(Parts.part("ball", 0xc9ccd2, Vector3(0.1, -0.55, 0.86), Vector3.ONE * 0.2))

const Parts = preload("res://scripts/parts.gd")

## A print across somebody's chest (his logo, his cousin's drawings: pochi.gd): `tall` high, its middle at `mid`, `aspect`
## times as wide. It lies on the body as the peña's logo does on its T-shirt (chara.gd _pena_print).
static func print_on(c, mat: Material, tall: float, mid: float, aspect: float, node_name: String) -> MeshInstance3D:
	const ROWS := 6
	const COLS := 12
	var span: float = tall * aspect / (c._r(mid) + 0.012)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var at := func(u: float, v: float) -> Array:
		var ang: float = (u - 0.5) * span
		var yy: float = mid + (0.5 - v) * tall
		var rr: float = c._r(yy) + 0.012
		return [Vector3(sin(ang) * rr, yy, cos(ang) * rr), Vector2(u, v), Vector3(sin(ang), 0.19, cos(ang)).normalized()]
	for row in range(ROWS):
		for col in range(COLS):
			var q: Array = [at.call(float(col) / COLS, float(row) / ROWS), at.call(float(col + 1) / COLS, float(row) / ROWS),
				at.call(float(col + 1) / COLS, float(row + 1) / ROWS), at.call(float(col) / COLS, float(row + 1) / ROWS)]
			for k in [0, 1, 2, 0, 2, 3]:
				st.set_normal(q[k][2])
				st.set_uv(q[k][1])
				st.add_vertex(q[k][0])
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	c.inner.add_child(mi)
	return mi

## The logo of a metal band: thorns, drips and a letter nobody can read, the same on both sides. Made up from a seed;
## it is nobody's logo.
static var _logos := {}
static func logo(seed_: int) -> ImageTexture:
	if _logos.has(seed_):
		return _logos[seed_]
	const W := 128
	const H := 64
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.85, 0.83, 0.77, 0.0))
	var ink := Color(0.86, 0.84, 0.78, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var stroke := func(a: Vector2, b: Vector2, wide: float) -> void:      # (thinner towards its end, and mirrored)
		var steps: int = int(a.distance_to(b) * 2.0) + 1
		for i in range(steps + 1):
			var k: float = float(i) / float(steps)
			var q: Vector2 = a.lerp(b, k)
			var w: float = lerpf(wide, 0.7, k)
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					if Vector2(dx, dy).length() > w:
						continue
					var y: int = int(q.y) + dy
					if y < 0 or y >= H:
						continue
					for x in [int(q.x) + dx, W - 1 - (int(q.x) + dx)]:
						if x >= 0 and x < W:
							img.set_pixel(x, y, ink)
	for g in range(5):                                # five "letters" a side: zigzags, each with a thorn up or a drip down
		var x0: float = 12.0 + g * 10.5
		var p := Vector2(x0 + rng.randf_range(-2.0, 2.0), 22.0 + rng.randf_range(-4.0, 4.0))
		for k in range(4):
			var q := Vector2(x0 + rng.randf_range(-3.0, 9.0), (43.0 if k % 2 == 0 else 20.0) + rng.randf_range(-5.0, 5.0))
			stroke.call(p, q, 1.7)
			p = q
		if rng.randf() < 0.55:
			stroke.call(p, p + Vector2(rng.randf_range(-3.0, 3.0), rng.randf_range(9.0, 17.0)), 1.4)
		else:
			stroke.call(Vector2(x0, 22.0), Vector2(x0 + rng.randf_range(-6.0, 2.0), rng.randf_range(3.0, 11.0)), 1.4)
	stroke.call(Vector2(14.0, 28.0), Vector2(1.0, 8.0 + rng.randf_range(0.0, 8.0)), 1.8)       # the wings, out to the sides
	stroke.call(Vector2(12.0, 38.0), Vector2(2.0, 54.0 + rng.randf_range(-4.0, 6.0)), 1.6)
	stroke.call(Vector2(8.0, 47.0 + rng.randf_range(-2.0, 2.0)), Vector2(64.0, 49.0), 1.1)       # and a bar under it all
	var tex := ImageTexture.create_from_image(img)
	_logos[seed_] = tex
	return tex
