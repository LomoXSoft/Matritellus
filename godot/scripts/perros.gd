extends RefCounted
## Stray and neighbourhood dogs roaming Madridejos's pavements (the user, 24 Nov 2026):
## three breeds sculpted in Blender from perro.glb (galgo, mastin, chucho; tools/make_perros.py),
## five dogs active at once in the bubble around the player (recycled like _keep_crowd_near),
## strolling pavements, pausing to sniff, barking softly, pettable with Interact, and hit by
## fast cars with the same quick harmless recovery as NPCs.

const Parts = preload("res://scripts/parts.gd")

const MOST := 5
const FAR := 210.0          # dogs past this distance (and out of view) relocate nearer to the player
const PET_DIST := 2.4       # max distance on foot to pet a dog
const DOWN_TIME := 1.8      # seconds lying down after a car hit before hopping right back up
const BISCUIT_ID := "galletas_perro"
const BISCUIT_PRICE := 5
const BISCUIT_PACK := 5
const VET_BUY_REACH := 2.25
## Real Madridejos veterinary clinic doors (spinning halo pickups outside until interiors are built):
##   0: Centro Veterinario Valdehierro (Avda. de la Constitución, 88 — constitucion_88)
##   1: Centro Veterinario Madridejos (Calle Arroyuelo Medio, 63)
const VET_SPOTS := [Vector2(74.9, -328.4), Vector2(-162.0, -279.6)]

const BREEDS := {
	"galgo": {
		"path": "res://assets/perros/galgo.glb",
		"long": 1.25,
		"speed": 1.85,
		"gallop": 5.4,
		"pitch": 0.96,
		"coats": [[0x9c7248, 0xd8c3a2], [0x242326, 0x3a393f], [0x6b4c32, 0x9e7d5d], [0xdcd6c8, 0xf2eee4]],
	},
	"mastin": {
		"path": "res://assets/perros/mastin.glb",
		"long": 1.25,
		"speed": 1.25,
		"gallop": 4.2,
		"pitch": 0.76,
		"coats": [[0xb58d58, 0xeadbc0], [0xd8c7a6, 0xf2ead9], [0x6f7378, 0xb8bcc2], [0x593d28, 0x9c7f62]],
	},
	"chucho": {
		"path": "res://assets/perros/chucho.glb",
		"long": 0.72,
		"speed": 1.50,
		"gallop": 4.8,
		"pitch": 1.22,
		"coats": [[0xa65826, 0xe8d5b8], [0x28262b, 0xb07542], [0x5c361e, 0xa87c58], [0xc98c4a, 0xf4efe6]],
	},
}


var G
var list: Array = []        # Array of dog Dictionaries
var pet_count := 0
var feed_count := 0
var hit_count := 0
var _keep_t := 0.0
var _vets_spawned := false
var _hand_biscuit: Node3D = null
static var _scenes := {}
static var _scales := {}    # breed -> [scale_k, foot_y_offset, head_y]
static var _heart_tex: ImageTexture

func setup(game) -> void:
	G = game
	var order: Array = ["galgo", "mastin", "chucho"]
	var pool: Array = ["galgo", "mastin", "chucho"]
	while order.size() < MOST:
		order.append(pool.pick_random())
	var center: Vector2 = G.player.p if G.player != null else Vector2.ZERO
	for i in range(MOST):
		var spot := _pick_spot(center, 45.0, 155.0)
		_spawn(String(order[i]), spot)
	spawn_vet_pickups()

## Spawn spinning halo "Galletas para Perros" pickups outside each veterinary clinic door
func spawn_vet_pickups() -> void:
	if G == null or G.pickups == null:
		return
	for i in range(VET_SPOTS.size()):
		G.pickups.spawn(BISCUIT_ID, VET_SPOTS[i], {
			"tag": "vet_galletas_%d" % i,
			"auto": false,
			"caption": Loc.t("vet_tag_buy") % [BISCUIT_PACK, BISCUIT_PRICE],
			"label": Loc.t("inv_n_galletas_perro"),
		})
	_vets_spawned = true

func _near_vet(pp: Vector2) -> int:
	if G == null or G.indoors or G.in_car != null:
		return -1
	for i in range(VET_SPOTS.size()):
		if pp.distance_to(VET_SPOTS[i]) < VET_BUY_REACH:
			return i
	return -1

func can_buy() -> bool:
	if G == null or G.player == null or G.indoors or G.in_car != null:
		return false
	return _near_vet(G.player.p) >= 0

func buy_spot() -> Vector3:
	var idx := _near_vet(G.player.p) if G != null and G.player != null else -1
	if idx < 0:
		return Vector3.ZERO
	var v: Vector2 = VET_SPOTS[idx]
	return Vector3(v.x, MapData.foot(v) + 1.85, v.y)

func buy_prompt() -> String:
	return Loc.t("p_buy_galletas") % [BISCUIT_PACK, BISCUIT_PRICE]

func buy() -> bool:
	if not can_buy():
		return false
	if G.money < BISCUIT_PRICE:
		if G.hud != null:
			G.hud.toast(Loc.t("t_galletas_no_money") % BISCUIT_PRICE, 3.0)
		Sfx.beep(196.0, 0.18, 1, -14.0)
		return false
	G.money -= BISCUIT_PRICE
	G._refresh_counts()
	if G.inventario != null:
		G.inventario.add_item(BISCUIT_ID, BISCUIT_PACK)
	else:
		var inv: Dictionary = G.stats.get("inv", {})
		inv[BISCUIT_ID] = int(inv.get(BISCUIT_ID, 0)) + BISCUIT_PACK
		G.stats["inv"] = inv
	if G.hud != null:
		G.hud.toast(Loc.t("t_galletas_buy") % BISCUIT_PACK, 2.8)
	Sfx.jingle([659, 784, 1047], 0.08)
	return true

func has_biscuits() -> bool:
	if G == null:
		return false
	var inv: Dictionary = G.stats.get("inv", {})
	return int(inv.get(BISCUIT_ID, 0)) > 0

func can_feed(d) -> bool:
	if d == null or not (d is Dictionary) or not has_biscuits():
		return false
	var st: String = String(d.get("state", ""))
	return st != "fly" and st != "down" and st != "feed" and st != "guide"

func _pick_spot(around: Vector2, lo: float, hi: float) -> Vector2:
	var node_spot = MapData.random_node_near(around, lo, hi)
	if node_spot != null:
		return G._pavement(node_spot as Vector2)
	return G._pavement(around + Vector2.from_angle(randf() * TAU) * randf_range(lo, hi))

func _scene(breed: String) -> PackedScene:
	if not _scenes.has(breed):
		var path: String = String(BREEDS[breed]["path"])
		if not ResourceLoader.exists(path):
			path = "res://assets/ajedrez/perro.glb"
		_scenes[breed] = load(path)
	return _scenes[breed] as PackedScene

func _spawn(breed: String, p: Vector2) -> Dictionary:
	var sc := _scene(breed)
	if sc == null:
		return {}
	var spec: Dictionary = BREEDS[breed]
	var root := Node3D.new()
	var pivot := Node3D.new()          # spun on car hit, reset on recovery
	var body: Node3D = sc.instantiate()
	pivot.add_child(body)
	root.add_child(pivot)
	var meshes: Array = body.find_children("*", "MeshInstance3D", true, false)
	if not _scales.has(breed):
		var box := AABB()
		var first := true
		for mi in meshes:
			var raw: AABB = (mi as MeshInstance3D).get_aabb()
			# Blender-exported skinned GLBs already store vertices in metres (the parent Armature's 100x scale cancels
			# out via inverseBindMatrices); only raw centimetre meshes (< 0.5 m) need _rel() applied.
			var b: AABB = raw if maxf(raw.size.x, raw.size.z) >= 0.5 else (_rel(body, mi as Node3D) * raw)
			box = b if first else box.merge(b)
			first = false
		var k: float = float(spec["long"]) / maxf(0.01, maxf(box.size.x, box.size.z))
		var foot_off: float = -box.position.y * k
		var head_y: float = box.size.y * k
		_scales[breed] = [k, foot_off, head_y]
	var sc_info: Array = _scales[breed]
	var k: float = float(sc_info[0]) * randf_range(0.94, 1.07)
	body.scale = Vector3.ONE * k
	body.position.y = float(sc_info[1]) * (k / float(sc_info[0]))
	var head_h: float = float(sc_info[2]) * (k / float(sc_info[0]))
	# Apply coat colour variant to Main and Main_Light surfaces
	var coats: Array = spec["coats"]
	var coat: Array = coats.pick_random()
	var m_main := _coat_mat(int(coat[0]))
	var m_light := _coat_mat(int(coat[1]))
	for mi in meshes:
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		for s in range(m.mesh.get_surface_count()):
			var orig: Material = m.mesh.surface_get_material(s)
			var mname: String = orig.resource_name if orig != null else ""
			if mname == "Main":
				m.set_surface_override_material(s, m_main)
			elif mname == "Main_Light":
				m.set_surface_override_material(s, m_light)
	var ap: AnimationPlayer = null
	for x in body.find_children("*", "AnimationPlayer", true, false):
		ap = x as AnimationPlayer
	if ap != null:
		for a in ["Walk", "Gallop", "Idle", "Idle_2", "Idle_2_HeadLow", "Eating"]:
			if ap.has_animation(a):
				ap.get_animation(a).loop_mode = Animation.LOOP_LINEAR
	G.add_child(root)
	var d := {
		"breed": breed,
		"root": root,
		"pivot": pivot,
		"body": body,
		"ap": ap,
		"p": p,
		"y": 0.0,
		"vy": 0.0,
		"vel": Vector2.ZERO,
		"spin": 0.0,
		"h": randf() * TAU,
		"state": "walk",         # walk | sniff | idle | pet | flee | fly | down
		"t": randf_range(6.0, 14.0),
		"bark_t": randf_range(8.0, 24.0),
		"speed": float(spec["speed"]) * randf_range(0.92, 1.08),
		"gallop": float(spec["gallop"]),
		"pitch": float(spec["pitch"]) * randf_range(0.94, 1.06),
		"long": float(spec["long"]),
		"head_h": head_h,
		"wa": -1,
		"wb": -1,
		"wside": 1.0 if randf() < 0.5 else -1.0,
		"wpts": [],
		"wi": 0,
		"wstuck": 0.0,
		"wtries": 0,
		"label": null,
		"label_t": 0.0,
		"heart": null,
		"heart_t": 0.0,
		"yip_t": 0.0,
		"feed_phase": 0,
		"feed_crunched": false,
		"guide_flower": null,
		"guide_target": Vector2.ZERO,
		"guide_pts": PackedVector2Array(),
		"guide_i": 0,
		"guide_wait": false,
		"guide_arrived": false,
		"guide_run_t": 0.0,
		"guide_idle_t": 0.0,
		"guide_bark_t": 0.0,
		"anim": "",
	}
	_sync(d)
	_play(d, "Walk")
	list.append(d)
	return d

static func _coat_mat(hex: int) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(((hex >> 16) & 255) / 255.0, ((hex >> 8) & 255) / 255.0, (hex & 255) / 255.0)
	m.roughness = 0.92
	return m

static func _rel(root: Node3D, n: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var x: Node = n
	while x != null and x != root:
		if x is Node3D:
			t = (x as Node3D).transform * t
		x = x.get_parent()
	return t

func _play(d: Dictionary, anim_name: String, blend := 0.2) -> void:
	var ap: AnimationPlayer = d["ap"]
	if ap == null or not ap.has_animation(anim_name):
		return
	if String(d["anim"]) == anim_name and ap.is_playing():
		return
	d["anim"] = anim_name
	ap.play(anim_name, blend)

func _say(d: Dictionary, text: String, dur := 2.0) -> void:
	var lbl: Label3D = d["label"]
	if lbl == null:
		lbl = Label3D.new()
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.no_depth_test = true
		lbl.pixel_size = 0.009
		lbl.font_size = 34
		lbl.outline_size = 12
		lbl.modulate = Color(1, 1, 1)
		lbl.outline_modulate = Color(0.29, 0.2, 0.14)
		lbl.position = Vector3(0.0, 1.15, 0.0)
		(d["root"] as Node3D).add_child(lbl)
		d["label"] = lbl
	lbl.text = text
	lbl.visible = true
	d["label_t"] = dur

func _woof(d: Dictionary, dist: float, boost := 0.0, pitch_mult := 1.0) -> void:
	if dist > 48.0:
		return
	var db: float = lerpf(-13.0, -34.0, clampf((dist - 4.0) / 44.0, 0.0, 1.0)) + boost
	Ambience._shot("dog_%d" % (randi() % 4), db, float(d["pitch"]) * pitch_mult * randf_range(0.95, 1.05))

func _sync(d: Dictionary) -> void:
	var p: Vector2 = d["p"]
	var root: Node3D = d["root"]
	root.position = Vector3(p.x, MapData.foot(p) + float(d["y"]), p.y)
	root.rotation.y = float(d["h"])

func _plan(d: Dictionary) -> void:
	var a: int = int(d["wb"]) if int(d["wb"]) >= 0 else MapData.nearest_node(d["p"] as Vector2)
	var opts := MapData.neighbours(a)
	if a < 0 or opts.is_empty():
		d["wpts"] = []
		return
	var b: int = int(opts.pick_random())
	if opts.size() > 1:
		var tries := 0
		while b == int(d["wa"]) and tries < 6:
			b = int(opts.pick_random())
			tries += 1
	if randf() < 0.14:
		d["wside"] = -float(d["wside"])
	d["wa"] = a
	d["wb"] = b
	var s = MapData.seg_between(a, b)
	var from: Vector2 = MapData.nodes[a]
	var to: Vector2 = MapData.nodes[b]
	var dv := to - from
	var length := maxf(dv.length(), 0.01)
	var u := dv / length
	var room: float = minf(float(MapData.clr[a]), float(MapData.clr[b]))
	var off: float = clampf(MapData.fitted_hw(s) + 0.9, 0.9, maxf(0.9, room - 0.55)) * float(d["wside"])
	var inset := minf(4.6, length * 0.3)
	var perp := Vector2(-u.y, u.x)
	d["wpts"] = [from + u * inset + perp * off, to - u * inset + perp * off]
	d["wi"] = 0

## closest dog within reach (on foot, upright and awake)
func near(pp: Vector2, reach := PET_DIST):
	var best = null
	var bd := reach * reach
	for d in list:
		var st: String = String(d["state"])
		if st == "fly" or st == "down" or st == "feed":
			continue
		var d2: float = (d["p"] as Vector2).distance_squared_to(pp)
		if d2 < bd:
			bd = d2
			best = d
	return best

func _clear_hand_biscuit() -> void:
	if _hand_biscuit != null and is_instance_valid(_hand_biscuit):
		_hand_biscuit.queue_free()
	_hand_biscuit = null

func _show_hand_biscuit() -> void:
	_clear_hand_biscuit()
	if G == null or G.player == null or G.player._hr == null:
		return
	var bone := Node3D.new()
	bone.scale = Vector3.ONE / 0.12          # counter-scale Chara HAND_SIZE (0.12)
	bone.position = Vector3(0.0, -0.02, 0.12)
	bone.rotation.y = deg_to_rad(30.0)
	bone.add_child(Parts.part("box", 0xd89b44, Vector3.ZERO, Vector3(0.16, 0.048, 0.036)))
	for sx: float in [-0.08, 0.08]:
		for sy: float in [-0.024, 0.024]:
			bone.add_child(Parts.part("ball", 0xd89b44, Vector3(sx, sy, 0.0), Vector3(0.034, 0.034, 0.028)))
	G.player._hr.add_child(bone)
	_hand_biscuit = bone

## feed a dog a biscuit by hand: dog comes to your outstretched hand, eats it, barks happily with a heart,
## and then runs ahead looking back to guide you to the nearest outdoor saffron flower (zero hint text).
func feed(d: Dictionary) -> bool:
	if not can_feed(d):
		return false
	if G.inventario != null:
		G.inventario.remove_item(BISCUIT_ID, 1)
	else:
		var inv: Dictionary = G.stats.get("inv", {})
		var left: int = int(inv.get(BISCUIT_ID, 0)) - 1
		if left <= 0:
			inv.erase(BISCUIT_ID)
		else:
			inv[BISCUIT_ID] = left
		G.stats["inv"] = inv
	var pp: Vector2 = G.player.p
	var p: Vector2 = d["p"]
	G.player.h = atan2(p.x - pp.x, p.y - pp.y)
	G.player.sync()
	_show_hand_biscuit()
	d["state"] = "feed"
	d["feed_phase"] = 0
	d["feed_crunched"] = false
	d["t"] = 1.4
	d["h"] = atan2(pp.x - p.x, pp.y - p.y)
	feed_count += 1
	G.stats["perros_galletas"] = int(G.stats.get("perros_galletas", 0)) + 1      # (the town notices: chismes.gd whispers)
	d["anim"] = ""
	_play(d, "Walk", 0.12)
	_sync(d)
	return true

## nearest uncollected outdoor saffron flower in G.flowers (public or hidden), or null if none
func _nearest_saffron(from: Vector2):
	if G == null or G.flowers == null:
		return null
	var best = null
	var bd := 1e12
	for f in G.flowers:
		var node = f.get("node")
		if node == null or not is_instance_valid(node) or not (node as Node3D).visible:
			continue
		var fp: Vector2 = f["p"]
		# Only outdoor flowers inside the town bounds (skip interior sets which sit far outside the map)
		if fp.x < MapData.xmin - 10.0 or fp.x > MapData.xmax + 10.0 or fp.y < MapData.zmin - 10.0 or fp.y > MapData.zmax + 10.0:
			continue
		if (node as Node3D).get_child_count() > 0:
			var first_mi = (node as Node3D).find_children("*", "MeshInstance3D", true, false)
			if not first_mi.is_empty() and ((first_mi[0] as MeshInstance3D).layers & (1 << 10)) != 0:
				continue
		var d2: float = fp.distance_squared_to(from)
		if d2 < bd:
			bd = d2
			best = f
	return best

## read-only A* along MapData's street graph (never touches MapData's player GPS state)
static func _find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	if from.distance_to(to) < 26.0:
		out.append(to)
		return out
	var start: int = MapData._nearest_node(from, false)
	var goal: int = MapData._nearest_node(to, false)
	if start < 0 or goal < 0 or start == goal:
		out.append(to)
		return out
	var g_score := {start: 0.0}
	var came := {}
	var heap: Array = [[MapData.nodes[start].distance_to(MapData.nodes[goal]), start]]
	var closed := {}
	var guard := 0
	var found := false
	while not heap.is_empty() and guard < 2500:
		guard += 1
		var top: Array = heap[0]
		var last: Array = heap.pop_back()
		if not heap.is_empty():
			heap[0] = last
			var i := 0
			while true:
				var l := i * 2 + 1
				var r := l + 1
				var m := i
				if l < heap.size() and float(heap[l][0]) < float(heap[m][0]):
					m = l
				if r < heap.size() and float(heap[r][0]) < float(heap[m][0]):
					m = r
				if m == i:
					break
				var tmp = heap[m]; heap[m] = heap[i]; heap[i] = tmp
				i = m
		var u: int = int(top[1])
		if closed.has(u):
			continue
		if u == goal:
			found = true
			break
		closed[u] = true
		var adj: Array = MapData._adj[u]
		var gu: float = float(g_score[u])
		for k in range(0, adj.size(), 2):
			var v: int = int(adj[k])
			if closed.has(v):
				continue
			var ng: float = gu + float(adj[k + 1])
			if ng < float(g_score.get(v, INF)):
				g_score[v] = ng
				came[v] = u
				var f: float = ng + (MapData.nodes[v] as Vector2).distance_to(MapData.nodes[goal] as Vector2)
				heap.append([f, v])
				var j := heap.size() - 1
				while j > 0:
					var par := (j - 1) >> 1
					if float(heap[par][0]) <= float(heap[j][0]):
						break
					var t2 = heap[par]; heap[par] = heap[j]; heap[j] = t2
					j = par
	if found:
		var rev: Array = []
		var cur := goal
		var steps := 0
		while cur != start and came.has(cur) and steps < 400:
			rev.append(MapData.nodes[cur])
			cur = int(came[cur])
			steps += 1
		rev.reverse()
		for q in rev:
			out.append(q as Vector2)
	out.append(to)
	return out

func _start_guide(d: Dictionary) -> void:
	var fl = _nearest_saffron(d["p"] as Vector2)
	if fl == null:
		d["state"] = "walk"
		d["t"] = randf_range(7.0, 14.0)
		_play(d, "Walk", 0.2)
		return
	var target: Vector2 = fl["p"]
	d["state"] = "guide"
	d["guide_flower"] = fl
	d["guide_target"] = target
	d["guide_pts"] = _find_path(d["p"] as Vector2, target)
	d["guide_i"] = 0
	d["guide_wait"] = false
	d["guide_arrived"] = false
	d["guide_run_t"] = 3.2
	d["guide_idle_t"] = 0.0
	d["guide_bark_t"] = 1.6
	_play(d, "Gallop", 0.14)

## crisp inked red heart sprite texture (64x64) for the floating petting emoji
static func _heart_texture() -> ImageTexture:
	if _heart_tex != null:
		return _heart_tex
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var fill_c := Color(0.92, 0.22, 0.34, 1.0)
	var hi_c := Color(1.0, 0.68, 0.74, 1.0)
	var rim_c := Color(0.28, 0.12, 0.14, 1.0)
	for py in range(n):
		var y: float = (0.52 - float(py) / float(n)) * 2.75     # +y up
		for px in range(n):
			var x: float = (float(px) / float(n) - 0.5) * 2.75
			# Classic smooth implicit heart: (x^2 + y^2 - 1)^3 - x^2 * y^3 <= 0
			var a: float = x * x + y * y - 1.0
			var f: float = a * a * a - x * x * y * y * y
			if f <= 0.16:
				var col: Color
				if f > -0.02:
					var edge: float = clampf((0.16 - f) / 0.07, 0.0, 1.0)
					col = Color(rim_c.r, rim_c.g, rim_c.b, edge)
				else:
					col = fill_c
					# small cartoon shine dot on upper-left lobe
					var hx: float = (x + 0.45) * 4.0
					var hy: float = (y - 0.56) * 4.0
					if hx * hx + hy * hy < 0.32:
						col = fill_c.lerp(hi_c, 0.85)
				img.set_pixel(px, py, col)
	_heart_tex = ImageTexture.create_from_image(img)
	return _heart_tex

func _pop_heart(d: Dictionary) -> void:
	var sp: Sprite3D = d["heart"]
	if sp == null:
		sp = Sprite3D.new()
		sp.texture = _heart_texture()
		sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sp.no_depth_test = true
		sp.render_priority = 2
		sp.pixel_size = 0.0044
		sp.shaded = false
		(d["root"] as Node3D).add_child(sp)
		d["heart"] = sp
	var head_y: float = float(d["head_h"])
	sp.position = Vector3(0.0, head_y + 0.14, float(d["long"]) * 0.22)
	sp.scale = Vector3.ONE * 0.65
	sp.modulate = Color(1, 1, 1, 1)
	sp.visible = true
	d["heart_t"] = 1.8

## pet a dog: stops, turns to you, hops happily, pops a small red heart from its head and gives a cheerful little bark
func pet(d: Dictionary) -> void:
	if d.is_empty():
		return
	var pp: Vector2 = G.player.p
	var p: Vector2 = d["p"]
	d["state"] = "pet"
	d["t"] = 2.0
	d["h"] = atan2(pp.x - p.x, pp.y - p.y)
	pet_count += 1
	d["anim"] = ""
	_play(d, "Jump_ToIdle", 0.1)
	_woof(d, p.distance_to(pp), 2.5, 1.12)
	d["yip_t"] = 0.24
	_pop_heart(d)
	_sync(d)
	if randf() < 0.4:
		_witness(p, 12.0, "dog_pet_seen")
	_count("perros_acariciados", 10, "perros_caricias")

## A neighbour near `p` who is free to talk says one of `key`'s lines (when you hit a dog, or stroke one)
func _witness(p: Vector2, reach: float, key: String) -> void:
	var best = null
	var bd := reach
	for n in G.npcs:
		if n.visible and not n.away and n.state == "idle" and not n.is_barking() and n.voice != "goat":
			var dd: float = n.p.distance_to(p)
			if dd < bd:
				bd = dd
				best = n
	if best != null:
		best.bark(Loc.t(key).pick_random(), 2.6)

## Counts it in stats; at `at`, the town has something to talk about (chismes.gd)
func _count(stat: String, at: int, news: String) -> void:
	var k: int = int(G.stats.get(stat, 0)) + 1
	G.stats[stat] = k
	if k == at and G.chismes != null:
		G.chismes.mission_over(news)

## check if a moving car hits or nudges any dog (called for the player's car and duty vehicles)
func check_car(c, by_player := false) -> void:
	if c == null or not is_instance_valid(c):
		return
	var v: float = c.vel.length()
	if v < 0.5:
		return
	var pp: Vector2 = G.player.p if G.in_car == null else G.in_car.p
	for o in [c.off, -c.off]:
		var q: Vector2 = c.p + Vector2(sin(c.h), cos(c.h)) * float(o)
		for d in list:
			var st: String = String(d["state"])
			if st == "fly" or st == "down":
				continue
			var p: Vector2 = d["p"]
			var nv: Vector2 = p - q
			var hit_r: float = float(c.r) + 0.48
			if nv.length_squared() > hit_r * hit_r:
				continue
			if v > 4.5:
				hit(d, c.vel * 0.9 + nv, 5.0 + v * 0.35, by_player, p.distance_to(pp))
			else:
				var dir: Vector2 = nv.normalized() if nv.length_squared() > 0.0001 else Vector2(1.0, 0.0)
				d["p"] = q + dir * (float(c.r) + 0.55)
				if v > 1.2 and st != "flee":
					d["state"] = "flee"
					d["t"] = 2.0
					_play(d, "Gallop", 0.12)
					_woof(d, p.distance_to(pp), 0.0, 1.15)
				_sync(d)

func hit(d: Dictionary, vel: Vector2, vy: float, by_player := false, dist := 0.0) -> void:
	if String(d["state"]) == "feed":
		_clear_hand_biscuit()
	d["state"] = "fly"
	d["vel"] = vel
	d["vy"] = vy
	d["spin"] = randf_range(6.0, 14.0) * (1.0 if randf() < 0.5 else -1.0)
	hit_count += 1
	d["anim"] = ""
	_play(d, "Idle_HitReact_Left" if randf() < 0.5 else "Idle_HitReact_Right", 0.05)
	_woof(d, dist, 3.0, 1.32)
	_say(d, Loc.t("dog_hit").pick_random(), 2.4)
	if by_player:
		_witness(d["p"], 22.0, "dog_hit_seen")             # (somebody always sees it)
		_count("perros_atropellados", 3, "perros_atropello")
		G.shake = maxf(float(G.shake), 0.25)
		G.police.add_heat(14.0)
		Sfx.noise(0.14, -14.0)
	elif dist < 50.0:
		Sfx.noise(0.12, -18.0)

func tick(dt: float) -> void:
	if not _vets_spawned and G != null and G.pickups != null:
		spawn_vet_pickups()
	if list.is_empty():
		return
	var pp: Vector2 = G.player.p if G.in_car == null else G.in_car.p
	var active: bool = (G.phase == "play" or G.phase == "free") and not G.indoors
	_keep_t -= dt
	if _keep_t <= 0.0:
		_keep_t = 2.0
		if active:
			for d in list:
				var st: String = String(d["state"])
				if st == "fly" or st == "down" or st == "pet" or st == "feed" or st == "guide":
					continue
				if (d["p"] as Vector2).distance_squared_to(pp) > FAR * FAR and not G.sees(d["p"]):
					d["p"] = _pick_spot(pp, 85.0, 175.0)
					d["wpts"] = []
					d["wa"] = -1
					d["wb"] = -1
					d["state"] = "walk"
					d["t"] = randf_range(6.0, 14.0)
					_sync(d)
	for d in list:
		if float(d["label_t"]) > 0.0:
			d["label_t"] = float(d["label_t"]) - dt
			if float(d["label_t"]) <= 0.0 and d["label"] != null:
				(d["label"] as Label3D).visible = false
		if float(d["yip_t"]) > 0.0:
			d["yip_t"] = float(d["yip_t"]) - dt
			if float(d["yip_t"]) <= 0.0:
				_woof(d, (d["p"] as Vector2).distance_to(pp), 0.5, 1.24)
		if float(d["heart_t"]) > 0.0:
			var ht: float = float(d["heart_t"]) - dt
			d["heart_t"] = ht
			var sp: Sprite3D = d["heart"]
			if sp != null:
				if ht <= 0.0:
					sp.visible = false
				else:
					var prog: float = 1.0 - ht / 1.8
					var head_y: float = float(d["head_h"])
					sp.position.y = head_y + 0.14 + prog * 0.56
					sp.position.x = sin(prog * TAU * 1.2) * 0.06
					var pop: float = minf(1.0, prog * 6.0)
					sp.scale = Vector3.ONE * (0.60 + 0.45 * pop)
					sp.modulate.a = clampf(ht / 0.45, 0.0, 1.0)
		var st: String = String(d["state"])
		var pivot: Node3D = d["pivot"]
		if st == "fly":
			d["vy"] = float(d["vy"]) - 22.0 * dt
			d["y"] = float(d["y"]) + float(d["vy"]) * dt
			pivot.rotation.x += float(d["spin"]) * dt
			var p: Vector2 = d["p"]
			var nxt: Vector2 = p + (d["vel"] as Vector2) * dt
			if MapData.room_at(nxt) < 0.45:
				d["vel"] = (d["vel"] as Vector2) * -0.3
			else:
				d["p"] = nxt
			if float(d["y"]) <= 0.0 and float(d["vy"]) < 0.0:
				d["y"] = 0.0
				if float(d["vy"]) < -6.0:
					d["vy"] = float(d["vy"]) * -0.35
					d["vel"] = (d["vel"] as Vector2) * 0.5
					Sfx.noise(0.07, -20.0)
				else:
					d["state"] = "down"
					d["t"] = DOWN_TIME
					pivot.rotation.x = -PI / 2.0
					pivot.position.y = 0.25
					_play(d, "Death", 0.1)
			_sync(d)
			continue
		if st == "down":
			d["t"] = float(d["t"]) - dt
			if float(d["t"]) <= 0.0:
				pivot.rotation.x = 0.0
				pivot.position.y = 0.0
				d["state"] = "flee"
				d["t"] = 2.6
				d["wpts"] = []
				d["wa"] = -1
				d["wb"] = -1
				_play(d, "Gallop", 0.12)
				_woof(d, (d["p"] as Vector2).distance_to(pp), 0.0, 1.08)
				_say(d, "¡Guau!", 1.5)
			_sync(d)
			continue
		if not active:
			continue
		var p: Vector2 = d["p"]
		var dist: float = p.distance_to(pp)
		if st == "feed":
			var ph: int = int(d["feed_phase"])
			if G.in_car != null or dist > 5.5:
				_clear_hand_biscuit()
				d["state"] = "walk"
				d["t"] = randf_range(6.0, 12.0)
				_play(d, "Walk", 0.2)
				_sync(d)
				continue
			# Hold the player's right hand gently outstretched toward the dog during approach & eat
			if ph <= 1 and G.player != null and G.player._hr != null:
				G.player._hr.position = Vector3(0.22, 0.56, 0.52)
			var fwd := Vector2(sin(G.player.h), cos(G.player.h))
			var hand_spot: Vector2 = pp + fwd * 0.85
			d["t"] = float(d["t"]) - dt
			if ph == 0:
				var to_hand: Vector2 = hand_spot - p
				if to_hand.length() > 0.35 and float(d["t"]) > 0.0:
					var gd := to_hand.normalized()
					var nxt: Vector2 = p + gd * float(d["speed"]) * 1.25 * dt
					if MapData.room_at(nxt) >= 0.35:
						d["p"] = nxt
					d["h"] = lerp_angle(float(d["h"]), atan2(gd.x, gd.y), 1.0 - exp(-10.0 * dt))
					_play(d, "Walk", 0.12)
				else:
					d["feed_phase"] = 1
					d["t"] = 1.15
					d["h"] = atan2(pp.x - p.x, pp.y - p.y)
					_play(d, "Eating", 0.12)
			elif ph == 1:
				d["h"] = lerp_angle(float(d["h"]), atan2(pp.x - p.x, pp.y - p.y), 1.0 - exp(-10.0 * dt))
				if not bool(d["feed_crunched"]) and float(d["t"]) <= 0.6:
					d["feed_crunched"] = true
					_clear_hand_biscuit()
					Sfx.noise(0.08, -16.0)
				if float(d["t"]) <= 0.0:
					_clear_hand_biscuit()
					d["feed_phase"] = 2
					d["t"] = 0.95
					d["anim"] = ""
					_play(d, "Jump_ToIdle", 0.08)
					_woof(d, dist, 2.5, 1.12)
					d["yip_t"] = 0.24
					_pop_heart(d)
			else:
				d["h"] = lerp_angle(float(d["h"]), atan2(pp.x - p.x, pp.y - p.y), 1.0 - exp(-8.0 * dt))
				if float(d["t"]) <= 0.0:
					_start_guide(d)
			_sync(d)
			continue
		if st == "guide":
			var fl = d["guide_flower"]
			var fl_alive: bool = fl != null and fl.get("node") != null and is_instance_valid(fl["node"]) and (fl["node"] as Node3D).visible
			if not fl_alive:
				# The player picked up the saffron! One joyful farewell hop + heart + bark
				d["state"] = "pet"
				d["t"] = 1.4
				d["anim"] = ""
				_play(d, "Jump_ToIdle", 0.1)
				_woof(d, dist, 2.0, 1.15)
				_pop_heart(d)
				_sync(d)
				continue
			var target: Vector2 = d["guide_target"]
			if bool(d["guide_arrived"]):
				d["guide_idle_t"] = float(d["guide_idle_t"]) + dt
				d["guide_bark_t"] = float(d["guide_bark_t"]) - dt
				# Alternate glancing at the saffron flower and back at the player
				var look_p: Vector2 = pp if fmod(float(d["guide_idle_t"]), 3.0) < 1.8 else target
				d["h"] = lerp_angle(float(d["h"]), atan2(look_p.x - p.x, look_p.y - p.y), 1.0 - exp(-6.0 * dt))
				if float(d["guide_bark_t"]) <= 0.0:
					d["guide_bark_t"] = 3.2
					d["anim"] = ""
					_play(d, "Jump_ToIdle", 0.1)
					_woof(d, dist, 1.5, 1.12)
				else:
					var ap_g: AnimationPlayer = d["ap"]
					if ap_g != null and not ap_g.is_playing():
						_play(d, "Idle_2_HeadLow" if fmod(float(d["guide_idle_t"]), 4.0) < 2.0 else "Idle_2", 0.2)
				if float(d["guide_idle_t"]) > 18.0 or dist > 45.0:
					d["state"] = "walk"
					d["t"] = randf_range(7.0, 14.0)
					_play(d, "Walk", 0.2)
				_sync(d)
				continue
			if bool(d["guide_wait"]):
				# Turn around to look back at the player and bark eagerly until they catch up
				d["guide_idle_t"] = float(d["guide_idle_t"]) + dt
				d["guide_bark_t"] = float(d["guide_bark_t"]) - dt
				d["h"] = lerp_angle(float(d["h"]), atan2(pp.x - p.x, pp.y - p.y), 1.0 - exp(-9.0 * dt))
				if float(d["guide_bark_t"]) <= 0.0:
					d["guide_bark_t"] = 2.6
					d["anim"] = ""
					_play(d, "Jump_ToIdle", 0.1)
					_woof(d, dist, 1.5, 1.12)
				else:
					var ap_w: AnimationPlayer = d["ap"]
					if ap_w != null and not ap_w.is_playing():
						_play(d, "Idle_2", 0.2)
				if dist < 7.5 and float(d["guide_idle_t"]) > 0.65:
					d["guide_wait"] = false
					d["guide_idle_t"] = 0.0
					d["guide_run_t"] = 3.5
					_play(d, "Gallop", 0.14)
				elif float(d["guide_idle_t"]) > 24.0 or dist > 45.0:
					d["state"] = "walk"
					d["t"] = randf_range(7.0, 14.0)
					_play(d, "Walk", 0.2)
				_sync(d)
				continue
			# Running eagerly ahead along the path toward the nearest saffron flower
			var gpts: PackedVector2Array = d["guide_pts"]
			var gi: int = int(d["guide_i"])
			var goal: Vector2 = gpts[gi] if gi < gpts.size() else target
			if p.distance_to(target) < 2.2:
				d["guide_arrived"] = true
				d["guide_idle_t"] = 0.0
				d["guide_bark_t"] = 2.8
				d["h"] = atan2(pp.x - p.x, pp.y - p.y)
				d["anim"] = ""
				_play(d, "Jump_ToIdle", 0.1)
				_woof(d, dist, 2.0, 1.14)
				d["yip_t"] = 0.24
				_pop_heart(d)
				_sync(d)
				continue
			if gi < gpts.size() and p.distance_to(goal) < 2.2:
				gi += 1
				d["guide_i"] = gi
				goal = gpts[gi] if gi < gpts.size() else target
			var gv: Vector2 = goal - p
			if gv.length() > 0.1:
				var gd := gv.normalized()
				var gspd: float = minf(float(d["gallop"]), 3.9)
				var step_g: Vector2 = p + gd * gspd * dt
				if MapData.room_at(step_g) >= 0.4 or step_g.distance_to(target) < 3.5:
					d["p"] = step_g
				else:
					# Slide slightly around corner/wall toward goal
					var alt := Vector2(-gd.y, gd.x)
					if MapData.room_at(p + alt * gspd * dt) >= 0.4:
						d["p"] = p + alt * gspd * dt
					elif MapData.room_at(p - alt * gspd * dt) >= 0.4:
						d["p"] = p - alt * gspd * dt
				d["h"] = lerp_angle(float(d["h"]), atan2(gd.x, gd.y), 1.0 - exp(-9.0 * dt))
			_play(d, "Gallop", 0.15)
			d["guide_run_t"] = float(d["guide_run_t"]) - dt
			if (dist > 10.5 or float(d["guide_run_t"]) <= 0.0) and p.distance_to(target) > 5.0:
				d["guide_wait"] = true
				d["guide_idle_t"] = 0.0
				d["guide_bark_t"] = 2.4
				d["anim"] = ""
				_play(d, "Jump_ToIdle", 0.12)
				_woof(d, dist, 1.5, 1.12)
			_sync(d)
			continue
		if st == "pet":
			d["t"] = float(d["t"]) - dt
			d["h"] = lerp_angle(float(d["h"]), atan2(pp.x - p.x, pp.y - p.y), 1.0 - exp(-8.0 * dt))
			var ap: AnimationPlayer = d["ap"]
			if ap != null and not ap.is_playing():
				_play(d, "Idle_2", 0.2)
			if float(d["t"]) <= 0.0 or dist > 5.0:
				d["state"] = "walk"
				d["t"] = randf_range(7.0, 15.0)
				_play(d, "Walk", 0.2)
			_sync(d)
			continue
		if st == "sniff" or st == "idle":
			d["t"] = float(d["t"]) - dt
			if st == "idle" and dist < 6.5:
				d["h"] = lerp_angle(float(d["h"]), atan2(pp.x - p.x, pp.y - p.y), 1.0 - exp(-4.0 * dt))
			if float(d["t"]) <= 0.0:
				d["state"] = "walk"
				d["t"] = randf_range(7.0, 16.0)
				_play(d, "Walk", 0.2)
			_sync(d)
			continue
		# walk or flee along pavements
		var fleeing := st == "flee"
		var spd: float = float(d["gallop"]) if fleeing else float(d["speed"])
		_play(d, "Gallop" if fleeing else "Walk", 0.18)
		var wpts: Array = d["wpts"]
		if wpts.is_empty():
			_plan(d)
			wpts = d["wpts"]
		if not wpts.is_empty():
			var wi: int = int(d["wi"])
			var goal: Vector2 = wpts[wi]
			var gv: Vector2 = goal - p
			if gv.length() < 0.7:
				wi += 1
				d["wi"] = wi
				d["wtries"] = 0
				if wi >= wpts.size():
					_plan(d)
			else:
				var gd := gv.normalized()
				var step_p: Vector2 = p + gd * spd * dt
				if MapData.room_at(step_p) >= 0.45:
					d["p"] = step_p
					d["wstuck"] = 0.0
				else:
					d["wstuck"] = float(d["wstuck"]) + dt
				d["h"] = lerp_angle(float(d["h"]), atan2(gd.x, gd.y), 1.0 - exp(-8.0 * dt))
				if float(d["wstuck"]) > 1.5:
					d["wstuck"] = 0.0
					d["wtries"] = int(d["wtries"]) + 1
					if int(d["wtries"]) == 1:
						d["wi"] = wi + 1
						if int(d["wi"]) >= wpts.size():
							_plan(d)
					elif int(d["wtries"]) == 2:
						var back: int = int(d["wa"])
						d["wa"] = int(d["wb"])
						d["wb"] = back
						d["wside"] = -float(d["wside"])
						_plan(d)
					else:
						d["wtries"] = 0
						d["p"] = G._pavement(d["p"] as Vector2)
						d["wpts"] = []
						d["wa"] = -1
						d["wb"] = -1
		d["t"] = float(d["t"]) - dt
		if float(d["t"]) <= 0.0:
			if fleeing:
				d["state"] = "walk"
				d["t"] = randf_range(7.0, 15.0)
				_play(d, "Walk", 0.25)
			else:
				var sniff := randf() < 0.65
				d["state"] = "sniff" if sniff else "idle"
				d["t"] = randf_range(2.2, 4.2) if sniff else randf_range(1.6, 3.2)
				_play(d, ("Idle_2_HeadLow" if randf() < 0.65 else "Eating") if sniff else ("Idle_2" if randf() < 0.5 else "Idle"), 0.25)
		d["bark_t"] = float(d["bark_t"]) - dt
		if float(d["bark_t"]) <= 0.0:
			d["bark_t"] = randf_range(14.0, 34.0)
			if dist < 42.0:
				_woof(d, dist)
		_sync(d)
