extends Node3D
## Who has a mission for you (the user, 13 November 2026):
##   - on the map (the corner one and the big one), their passport photo in a circle with a black rim, where they are;
##   - over their head, a small green arrow turning round and round: not there at all from more than FAR metres, and
##     clearer the closer you get, wholly there from NEAR.
## "A mission for you": a mission offered and not yet taken (the story's, or a side line's), or one put off until you
## come back (the mayor, waiting for the money). Which those are is worked out every half second (givers()).

const Portrait = preload("res://scripts/portrait.gd")
const FAR := 30.0
const NEAR := 10.0
const PHOTO := 96               # pixels of the photo, before it goes into its circle

var G
var photos := {}                # npc id -> Texture2D (the round photo for the map)
var _making := {}               # npc id -> true while its photo is being taken
var _arrows := {}               # npc -> MeshInstance3D
var _list: Array = []           # the npcs who have a mission for you, as of the last count
var _t := 0.0
var _spin := 0.0
var _arrow_mesh: Mesh

func setup(game) -> void:
	G = game
	_arrow_mesh = _make_arrow()

## the neighbours who have a mission for you right now
func givers() -> Array:
	var out: Array = []
	if G.phase != "play" and G.phase != "free":
		return out
	var s: Dictionary = G.steps[G.si] if G.phase == "play" and G.si >= 0 and G.si < G.steps.size() else {}
	# the story: the first step of a mission, face to face, not yet taken
	if not s.is_empty() and s.get("type", "") == "talk" and G._is_offer(s) and (G._step_flag == "" or G._step_flag == "declined") and G.named.has(s["npc"]):
		out.append(G.named[s["npc"]])
	var free_hands: bool = G.side == null and not G.in_mission() and G.comida.faint == null
	# Josefa's errands
	if free_hands and not G.stats.has("menu_done") and G.negocio("informatica") and G.named.has("josefa"):
		out.append(G.named["josefa"])
	# Don Luis
	if G.named.has("luis") and G.negocio("restaurantes") and not G.sabotaje.done():
		if G.sabotaje.stage in ["retry", "back"] or (G.sabotaje.stage == "" and free_hands):
			out.append(G.named["luis"])
	# whoever the errand under way has you go and see: to talk to, to be given something, to hand something over. The
	# green arrow is for that, on foot; the column of light (green too since 16 Nov 2026) for what is done with the car
	if not s.is_empty() and s.get("type", "") == "talk" and G.named.has(s["npc"]) and not (G.named[s["npc"]] in out):
		out.append(G.named[s["npc"]])
	if G.side != null and G.side.get("id", "") in ["menu", "ham"]:
		var who = G.named.get("henry") if G.side.get("stage", "") == "fetch" else G.named.get(String(G.side.get("who", "")))
		if who != null and not (who in out):
			out.append(who)
	# the Civismo line (recress.gd)
	if G.get("recress") != null:
		for n in G.recress.givers(free_hands):
			if n != null and not (n in out):
				out.append(n)
	# (ajedrez) the mayor again, after the Recress: his chess (ajedrez_humano.gd)
	if G.get("ajedrez") != null:
		for n in G.ajedrez.givers(free_hands):
			if n != null and not (n in out):
				out.append(n)
	return out.filter(func(n): return n != null and is_instance_valid(n))

## the photo of one of them, for the map (null until it has been taken)
func photo(n) -> Texture2D:
	var id: String = n.id
	if photos.has(id):
		return photos[id]
	if not _making.has(id):
		_making[id] = true
		_take(n)
	return null

func _take(n) -> void:
	var id: String = n.id
	if DisplayServer.get_name() == "headless":       # (without a screen nothing is ever drawn, so no photo would come: the
		photos[id] = _round(null, n)                 # tests get the disc straight away)
		return
	var vp: SubViewport = Portrait.viewport(n.look_data, Vector2i(PHOTO, int(PHOTO * 1.23)))
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image() if vp.get_texture() != null else null
	vp.queue_free()
	photos[id] = _round(img, n)

## the photo cut into a circle, with a black rim (or, where nothing can be drawn -- the tests, run without a screen --
## a disc of their shirt's colour)
func _round(img: Image, n) -> Texture2D:
	var size := 64
	var out := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var face: Image = null
	if img != null and not img.is_empty():
		var side: int = mini(img.get_width(), img.get_height())
		face = img.get_region(Rect2i((img.get_width() - side) / 2, 0, side, side))
		face.resize(size, size, Image.INTERPOLATE_LANCZOS)
	var shirt := Color.hex((int(n.look_data.get("shirt", 0x8a8a8a)) << 8) | 0xff)
	var c := Vector2(size, size) / 2.0 - Vector2(0.5, 0.5)
	var r := size / 2.0 - 0.5
	for y in range(size):
		for x in range(size):
			var d := Vector2(x, y).distance_to(c)
			if d > r:
				continue
			var col: Color = face.get_pixel(x, y) if face != null else shirt
			if d > r - 4.0:                          # the black rim (soft at its outer edge)
				col = Color(0.08, 0.07, 0.06, clampf(r - d + 0.5, 0.0, 1.0))
			out.set_pixel(x, y, col)
	return ImageTexture.create_from_image(out)

func tick(dt: float, pp: Vector2) -> void:
	_t -= dt
	if _t <= 0.0:
		_t = 0.5
		_list = givers()
		for n in _arrows.keys():
			if not (n in _list) or not is_instance_valid(n):
				if is_instance_valid(_arrows[n]):
					_arrows[n].queue_free()
				_arrows.erase(n)
		for n in _list:
			if not _arrows.has(n):
				_arrows[n] = _new_arrow()
		var marks: Array = []
		for n in _list:
			marks.append([G.vip.door_out if n.id == "vip" and G.get("vip") != null else n.p, photo(n), n.id])      # (Fonsi is in his shop's own set, far off the map: on it, at its door)
		G.hud.minimap.givers = marks
		G.hud.bigmap.givers = marks
	_spin += dt * 2.2
	# (indoors too: the sets stand 250 m or more from the town and from each other, so whoever is within FAR of you in
	# there is in there with you -- the mayor waiting at the machine, in the Recress: the user, 17 November 2026)
	var hide_all: bool = G.dlg != null or G.cine_lock or G.phase != "play" and G.phase != "free"
	for n in _arrows:
		var a: MeshInstance3D = _arrows[n]
		if not is_instance_valid(n) or not is_instance_valid(a):
			continue
		var d: float = (n.p as Vector2).distance_to(pp)
		var k := clampf((FAR - d) / (FAR - NEAR), 0.0, 1.0)
		a.visible = k > 0.01 and n.visible and not hide_all
		if not a.visible:
			continue
		var tall: float = float(n.look_data.get("scale", 1.0))
		a.global_position = n.global_position + Vector3(0.0, 2.35 * tall + sin(_spin * 1.3) * 0.08, 0.0)
		a.rotation = Vector3(0.0, _spin, 0.0)
		(a.material_override as StandardMaterial3D).albedo_color.a = k

func _new_arrow() -> MeshInstance3D:
	var a := MeshInstance3D.new()
	a.mesh = _arrow_mesh
	a.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.22, 0.84, 0.3, 0.0)
	m.emission_enabled = true
	m.emission = Color(0.1, 0.5, 0.15)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS      # (fading in, it is still drawn in the right order)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.roughness = 0.5
	a.material_override = m
	a.visible = false
	add_child(a)
	return a

## a little arrow pointing down: a flat-sided head and a shaft, thick enough to read as it turns
func _make_arrow() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var depth := 0.08
	var outline: Array = [Vector2(0.0, 0.0), Vector2(0.26, 0.28), Vector2(0.095, 0.28), Vector2(0.095, 0.58), Vector2(-0.095, 0.58), Vector2(-0.095, 0.28), Vector2(-0.26, 0.28)]
	var tris: Array = [[0, 1, 6], [2, 3, 4], [2, 4, 5]]
	for side in [-1.0, 1.0]:                         # the two faces (wound clockwise seen from outside, as Godot draws a front:
		st.set_normal(Vector3(0, 0, side))          # they were the other way round, and from outside one saw through the near face to
		for t in tris:                              # the back of the far one -- "transparente por los laterales", the user, 17 Nov 2026)
			var idx: Array = [t[0], t[2], t[1]] if side > 0.0 else t
			for i in idx:
				var v: Vector2 = outline[i]
				st.add_vertex(Vector3(v.x, v.y, side * depth))
	for i in range(outline.size()):                  # and the edge all round
		var a: Vector2 = outline[i]
		var b: Vector2 = outline[(i + 1) % outline.size()]
		var nrm := Vector3(b.y - a.y, -(b.x - a.x), 0.0).normalized()
		st.set_normal(nrm)
		for v in [Vector3(a.x, a.y, depth), Vector3(b.x, b.y, depth), Vector3(b.x, b.y, -depth), Vector3(a.x, a.y, depth), Vector3(b.x, b.y, -depth), Vector3(a.x, a.y, -depth)]:
			st.add_vertex(v)
	return st.commit()

## what the self-test wants to see
func arrow_of(n):
	return _arrows.get(n)
