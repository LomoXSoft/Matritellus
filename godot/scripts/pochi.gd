extends RefCounted
## El Pochi (the user, 26 November 2026, with a picture of how he looks: "El Foski será primo de «El Pochi». Otro NPC
## único que también dará vueltas por esas calles"; then: "Camisetas de anime todos los días. Le gusta el anime, no
## tiene reparos con el hentai, más malablado y con más palabrotas que su primo. Te insulta constantemente. […] Es un
## Otaku pero odia a los otros otakus por no ducharse y hablar con palabras en japonés, le dan asco, él al menos tiene
## cierta dignidad sobre ellos").
##
##   Where: the Calle del Florido and its Bajada, at any hour, like his cousin Foski (foski.gd) but at his own pace and
##   starting from one end. No missions yet. While the Calasanz has its children out in the yard (school days, 10 to
##   13: ninos.gd), up and down the Calle del Palo in front of it (the user, 28 Nov 2026: "Si, pónselo"); he moves
##   from one to the other while nobody sees him or where he goes, as his T-shirt changes.
##   Looks: big, fair, his hair cropped to nothing, three days' beard, black rectangular glasses, a dark wristband. A
##   T-shirt of another colour each day with a cartoon face on it (chibi(): big eyes, hair in points; made up here, it
##   is nobody's character).
##   What he says (Loc "pochi", taken in turn by game.gd _chat): anime, hentai, the otakus who do not wash and talk in
##   Japanese words, his cousin; an insult in every line. And when you come near he throws you one unasked
##   ("pochi_insultos").

const Foski = preload("res://scripts/foski.gd")
const Ninos = preload("res://scripts/ninos.gd")
const Calasanz = preload("res://scripts/calasanz.gd")
const Parts = preload("res://scripts/parts.gd")
const LOOK := {"top": 0, "shirt": 0x5b7fb5, "skin": 0xf3cbb0, "hair": 0x8a6a48, "hair_style": 17, "face": 5, "brows": 0,
	"eyes": 0, "eye_color": 0x5a4030, "glasses": 7, "build": 1.34, "shoes": 0x2a2a30, "hat": ""}
const STREETS := ["Calle del Florido", "Bajada del Florido"]
const SCHOOL_STREET := "Calle del Palo"          # in front of the Calasanz, in its hours
const SCHOOL_REACH := 100.0     # how much of that street: its nodes this near the school (three: some 80 m of it)
const PACE := 1.2
const TEES := [                 # the T-shirt, the drawing's hair, its eyes: one a day, in turn
	[0x5b7fb5, 0xf07ab0, 0x3aa0e8], [0xf1efe8, 0x3a7fe0, 0xd9453a], [0xe8c23a, 0xd9453a, 0x3f9a55],
	[0x1d1c20, 0x58d06a, 0xe8a03a], [0xe58fb0, 0x8a5fd0, 0x3aa0e8]]
const EVERY := 5.0
const NEAR := 6.0               # this near, he has something to call you
const INSULT := [9.0, 16.0]     # seconds from one to the next
const OWN := "res://data/x7k2m9q4.txt"        # the user's own talks for him: see own_lines() (named so as to say nothing, at his word)

var G
var n                           # himself (npc.gd)
var _day := -1
var _t := 0.0
var _bark := 4.0
var extra: Array = []           # the user's own talks, said in turn after the others (game.gd _chat)
var at_school := false          # walking the Calle del Palo by the Calasanz just now

func setup(game) -> void:
	G = game
	at_school = school_hours() and not school_beat().is_empty()
	var beat := school_beat() if at_school else street()
	n = G._make_npc("pochi", LOOK.duplicate(), "adult_m", school_start() if at_school else start())
	n.still = false
	if not beat.is_empty():
		n.walker = true
		n.beat = beat
		n.wside = -1.0
		n.wspeed = PACE
	wear(int(G.day_n))
	extra = own_lines()

## The user's own talks for him (26 Nov 2026: "si no quieres/puedes escribirlos déjame recuadros de texto y los escribo
## yo. Tu no los verás ni los escribirás"): the data file OWN, said as written, in turn with the rest. They are not
## in Loc and are never loaded under the self-test, so that no test, log or picture shows them. Nobody but the user
## opens or edits that file.
func own_lines() -> Array:
	if OS.get_cmdline_user_args().has("--selftest") or not FileAccess.file_exists(OWN):
		return []
	var f := FileAccess.open(OWN, FileAccess.READ)
	return parse(f.get_as_text()) if f != null else []

## A box starts at a line "[...]"; each line under it is a bubble of that talk; "#" lines and empty boxes are left out.
static func parse(text: String) -> Array:
	var out: Array = []
	var talk: Array = []
	for raw in text.split("\n"):
		var line: String = String(raw).strip_edges()
		if line.begins_with("["):
			if not talk.is_empty():
				out.append(talk)
			talk = []
		elif line != "" and not line.begins_with("#"):
			talk.append(line)
	if not talk.is_empty():
		out.append(talk)
	return out

## the road nodes of his streets (a walker's "beat")
func street() -> Dictionary:
	var out := {}
	for r in MapData.roads:
		if String(r["n"]) in STREETS:
			for i in r["p"]:
				out[int(i)] = true
	return out

## where he starts from: one end of the Calle del Florido, on its pavement
func start() -> Vector2:
	for r in MapData.roads:
		if String(r["n"]) == STREETS[0] and (r["p"] as PackedInt32Array).size() > 1:
			return G._pavement(MapData.nodes[r["p"][1]])
	return G._pavement(MapData.poi("Ayuntamiento"))

## the Calasanz's yard hours (its children out: ninos.gd), when he walks by it
func school_hours() -> bool:
	return int(G.weekday) < 5 and G.clock >= Ninos.OUT_FROM and G.clock < Ninos.OUT_TO

## the road nodes of the Calle del Palo near the school
func school_beat() -> Dictionary:
	var out := {}
	for r in MapData.roads:
		if String(r["n"]) == SCHOOL_STREET:
			for i in r["p"]:
				if MapData.nodes[i].distance_to(Calasanz.O) < SCHOOL_REACH:
					out[int(i)] = true
	return out

## where he turns up by the school: the pavement at the node of it nearest the school
func school_start() -> Vector2:
	var best := -1
	for i in school_beat():
		if best < 0 or MapData.nodes[i].distance_to(Calasanz.O) < MapData.nodes[best].distance_to(Calasanz.O):
			best = i
	return G._pavement(MapData.nodes[best]) if best >= 0 else start()

## from his streets to the school's or back, when the hour says so and nobody sees him go nor arrive
func _move_on() -> void:
	var want: bool = school_hours() and not school_beat().is_empty()
	if want == at_school or n.away or (n.state != "idle" and n.state != "walk") or G.talk_npc == n:
		return
	if G.sees(n.p) or G.sees(school_start() if want else start()):
		return
	go(want)

## there at once (and the self-test, which looks)
func go(school: bool) -> void:
	at_school = school
	n.beat = school_beat() if school else street()
	n.walker = not n.beat.is_empty()
	n.p = school_start() if school else start()
	n.wa = -1
	n.wb = -1
	n.wpts = []
	n.wi = 0
	n.sync()

## how far a spot is from the middle of the nearest of the streets he walks just now
func off_street(at: Vector2) -> float:
	var best := 1e9
	var now: Array = [SCHOOL_STREET] if at_school else STREETS
	for r in MapData.roads:
		if String(r["n"]) in now:
			var pts: PackedInt32Array = r["p"]
			for i in range(pts.size() - 1):
				best = minf(best, Geometry2D.get_closest_point_to_segment(at, MapData.nodes[pts[i]], MapData.nodes[pts[i + 1]]).distance_to(at))
	return best

func tick(dt: float) -> void:
	if n == null or not is_instance_valid(n):
		return
	_insult(dt)
	_t -= dt
	if _t > 0.0:
		return
	_t = EVERY
	_move_on()
	if int(G.day_n) != _day and not G.sees(n.p):     # (another day, another T-shirt: changed while you are not looking)
		wear(int(G.day_n))

## "Te insulta constantemente": when you are near and he is not already talking to you
func _insult(dt: float) -> void:
	_bark -= dt
	if _bark > 0.0:
		return
	if n.away or not n.visible or n.state == "fly" or n.state == "down" or G.dlg != null or G.in_car != null or G.indoors \
			or (G.phase != "play" and G.phase != "free") or n.p.distance_to(G.player.p) > NEAR:
		_bark = 1.0
		return
	_bark = randf_range(INSULT[0], INSULT[1])
	n.bark(String(Loc.t("pochi_insultos").pick_random()), 2.8)

## today's T-shirt
func wear(day: int) -> void:
	_day = day
	var tee: Array = TEES[posmod(day, TEES.size())]
	var look: Dictionary = n.look_data.duplicate()
	look["shirt"] = int(tee[0])
	n.look_data = look
	n.set_look(look)
	dress(n, tee)

## what is his alone, on him: the drawing on his chest, the band on his wrist
func dress(c, tee: Array) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_texture = chibi(int(tee[1]), int(tee[2]))
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.roughness = 1.0
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	Foski.print_on(c, m, 0.4, 0.66, 1.0, "pochi_dibujo")
	if c._hl != null:
		var band := Parts.part("ring", 0x26262b, Vector3(0.0, 0.62, 0.0), Vector3.ONE * 0.86)
		c._hl.add_child(band)

## A cartoon face for a T-shirt: big shining eyes, hair in points, a blush. It is nobody's character.
static var _drawn := {}
static func chibi(hair_hex: int, eye_hex: int) -> ImageTexture:
	var key := "%x_%x" % [hair_hex, eye_hex]
	if _drawn.has(key):
		return _drawn[key]
	const N := 64
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	var hair: Color = Parts.col(hair_hex)
	var eye: Color = Parts.col(eye_hex)
	var skin := Color(1.0, 0.88, 0.78)
	var dark := Color(0.16, 0.12, 0.18)
	var fringe: Color = hair.darkened(0.22)
	var top := Vector2(32.0, 29.0)
	var face := Vector2(32.0, 36.0)
	var points := [-2.6, -2.05, -1.57, -1.1, -0.55]          # where its hair stands up (straight up is -PI / 2)
	for y in range(N):
		for x in range(N):
			var p := Vector2(x + 0.5, y + 0.5)
			var d: Vector2 = p - top
			var reach := 22.0
			for a in points:
				reach = maxf(reach, 22.0 + 8.0 * maxf(0.0, 1.0 - absf(angle_difference(d.angle(), float(a))) / 0.24))
			var c := Color(hair.r, hair.g, hair.b, 0.0)
			if d.length() < reach and y < 53:
				c = hair if d.length() < reach - 1.6 else dark
			var fd: float = ((p - face) / Vector2(17.0, 16.5)).length()
			if fd < 1.0:
				c = skin if fd < 0.92 else dark
				if y < 25.0 + 4.0 * absf(sin(x * 0.55)):          # the fringe, in points
					c = fringe
			img.set_pixel(x, y, c)
	var disc := func(at: Vector2, r: Vector2, col: Color) -> void:
		for y in range(int(at.y - r.y) - 1, int(at.y + r.y) + 2):
			for x in range(int(at.x - r.x) - 1, int(at.x + r.x) + 2):
				if x >= 0 and x < N and y >= 0 and y < N and ((Vector2(x + 0.5, y + 0.5) - at) / r).length() < 1.0:
					img.set_pixel(x, y, col)
	for cx in [24.5, 39.5]:
		var mid := Vector2(cx, 38.5)
		disc.call(mid, Vector2(5.2, 7.2), dark)
		disc.call(mid, Vector2(4.1, 6.1), eye.darkened(0.4))
		disc.call(mid + Vector2(0.0, 1.8), Vector2(3.9, 4.2), eye)
		disc.call(mid + Vector2(-1.5, -2.8), Vector2(1.8, 1.8), Color.WHITE)
		disc.call(mid + Vector2(1.7, 2.6), Vector2(1.0, 1.0), Color.WHITE)
		disc.call(Vector2(cx + (cx - 32.0) * 0.55, 46.0), Vector2(2.6, 1.5), Color(1.0, 0.62, 0.66))      # a blush
	for q in [Vector2i(30, 47), Vector2i(33, 47), Vector2i(31, 48), Vector2i(32, 48)]:      # a small smile
		img.set_pixelv(q, dark)
	var tex := ImageTexture.create_from_image(img)
	_drawn[key] = tex
	return tex
