extends RefCounted
## La «ruta del colesterol» (the user, 17 November 2026, through Worldbuilding: "Muy buena idea, pídeselo"): what the
## town calls the old Madrid–Cádiz road, where people go out for a walk when the weather is good. Its pavement runs
## between the tarmac and the fields (referencias/ruta_colesterol/).
##
##   When: early in the morning and late in the afternoon (HOURS), and not in the rain.
##   Who: neighbours in tracksuits, on their own or in pairs, now and then with a dog on a lead; some of the old ones
##   with a water bottle in each hand for weights. They keep to the road (npc.gd `beat`: its nodes) and turn back at
##   its ends; talked to, they have their own lines (Loc "ruta_colesterol", Worldbuilding's).
##   Where: only the stretch near you: they come out where you cannot see them, and go the same way.

const Parts = preload("res://scripts/parts.gd")
const ROAD := "Carretera Antigua de Madrid a Cádiz"
const HOURS := [[7.0, 10.5], [18.0, 21.5]]
const MOST := 12                # walkers about at once
const NEAR := 300.0             # they come out along the stretch within this of you...
const SEEN_FROM := 70.0         # ...but not nearer than this
const GONE := 420.0             # and go beyond this
const EVERY := 1.0
const SUITS := [0x1f2a5c, 0xb3212b, 0x2456c9, 0x26262b, 0x7a7f88, 0x5b2a86, 0x1f7a4d, 0xd9532b, 0x2a9dbe]
const DOG := "res://assets/ajedrez/perro.glb"     # Quaternius's Shiba Inu (CC0): assets/ajedrez/CREDITOS.txt
const DOG_LONG := 0.75

var G
var beat := {}                  # the road's nodes
var points: Array = []          # where they are, for choosing where somebody comes out
var people: Array = []          # {n, dog: Node3D or null, ap}
var _t := 0.0
static var _dog_scene: PackedScene
static var _dog_k := 0.0

func setup(game) -> void:
	G = game
	for r in MapData.roads:
		if String(r["n"]) == ROAD:
			for i in (r["p"] as PackedInt32Array):
				beat[int(i)] = true
	for i in beat:
		points.append(MapData.nodes[i])

func walk_time() -> bool:
	if G.raining:
		return false
	for h in HOURS:
		if G.clock >= h[0] and G.clock < h[1]:
			return true
	return false

func tick(dt: float) -> void:
	if beat.is_empty():
		return
	for p in people:                              # the dogs keep up with whoever has them on the lead, every frame
		if p["dog"] != null:
			_dog_follow(p, dt)
	_t -= dt
	if _t > 0.0:
		return
	_t = EVERY
	var pp: Vector2 = G.player.p if G.in_car == null else G.in_car.p
	var want: bool = walk_time() and (G.phase == "play" or G.phase == "free") and not G.indoors
	for p in people.duplicate():
		var n = p["n"]
		if not is_instance_valid(n):
			_drop(p)
			continue
		if n.state == "fly" or n.state == "down" or (G.dlg != null and G.dlg.get("from") == n):
			continue
		if (not want or n.p.distance_to(pp) > GONE) and not G.sees(n.p):
			_drop(p)
	if not want or people.size() >= MOST:
		return
	var spots: Array = points.filter(func(q): return q.distance_to(pp) > SEEN_FROM and q.distance_to(pp) < NEAR and not G.sees(q))
	if spots.is_empty():
		return
	_out(spots.pick_random())

## somebody comes out for their walk at `at` (on the road): on their own, or two of them, now and then with a dog
func _out(at: Vector2) -> void:
	var two: bool = randf() < 0.4 and people.size() <= MOST - 2
	var side := 1.0 if randf() < 0.5 else -1.0
	var lead = null
	for k in range(2 if two else 1):
		var vi: int = randi() % 9                 # (any of the town's voices but a child's: game.gd NEIGHBOUR_VOICES)
		var n = G.spawn_neighbour(G._pavement(at), false, G._neighbour_look(G.NEIGHBOUR_VOICES[vi]).merged({"voice_i": vi}))
		var old: bool = String(n.voice).begins_with("old")
		var look: Dictionary = n.look_data.duplicate()
		look.erase("voice_i")
		look["top"] = 4                           # a tracksuit
		look["shirt"] = SUITS.pick_random()
		look["hat"] = ""
		n.look_data = look
		n.set_look(look)
		n.lines_key = "ruta_colesterol"
		n.walker = true
		n.beat = beat
		n.wside = side
		n.wspeed = randf_range(0.95, 1.1) if old else randf_range(1.3, 1.55)
		if lead != null:                          # (the second of a pair: the same way, at the same pace)
			n.wspeed = lead.wspeed
		if old and randf() < 0.45:
			_bottles(n)
		var p := {"n": n, "dog": null, "ap": null}
		if lead == null and randf() < 0.3:
			_add_dog(p)
		people.append(p)
		lead = n

## a water bottle in each hand, for weights (one of the kids' sayings mentions it)
func _bottles(n) -> void:
	for hand in [n._hl, n._hr]:
		var b := Node3D.new()
		b.scale = Vector3.ONE / 0.12              # (the hand is a ball of 0.12: the bottle keeps its own size)
		b.add_child(Parts.part("cyl", 0x9fd3ef, Vector3(0, -0.1, 0.02), Vector3(0.075, 0.24, 0.075)))
		b.add_child(Parts.part("cyl", 0x2a6fbf, Vector3(0, 0.035, 0.02), Vector3(0.04, 0.035, 0.04)))
		hand.add_child(b)

func _add_dog(p: Dictionary) -> void:
	if _dog_scene == null and ResourceLoader.exists(DOG):
		_dog_scene = load(DOG)
	if _dog_scene == null:
		return
	var root := Node3D.new()
	var body: Node3D = _dog_scene.instantiate()
	root.add_child(body)
	if _dog_k <= 0.0:
		var box := AABB()
		var first := true
		for mi in body.find_children("*", "MeshInstance3D", true, false):
			var b: AABB = (mi as MeshInstance3D).get_aabb()
			box = b if first else box.merge(b)
			first = false
		_dog_k = DOG_LONG / maxf(0.01, maxf(box.size.x, box.size.z))
	body.scale = Vector3.ONE * _dog_k
	body.rotation.y = PI                          # (the model looks down its -z)
	var ap: AnimationPlayer = null
	for x in body.find_children("*", "AnimationPlayer", true, false):
		ap = x
	if ap != null:
		for a in ["Walk", "Idle"]:
			if ap.has_animation(a):
				ap.get_animation(a).loop_mode = Animation.LOOP_LINEAR
	G.add_child(root)
	var n = p["n"]
	root.position = MapData.at(n.p, 0.0)
	p["dog"] = root
	p["ap"] = ap

## a step to the side of whoever has it, and a little ahead, the way they are going
func _dog_follow(p: Dictionary, dt: float) -> void:
	var dog: Node3D = p["dog"]
	var n = p["n"]
	if not is_instance_valid(n) or not is_instance_valid(dog):
		return
	dog.visible = n.visible
	if not n.visible:
		return
	var face := Vector2(sin(n.h), cos(n.h))
	var right: Vector2 = Vector2(face.y, -face.x) * float(n.wside)
	var want: Vector2 = n.p + right * 0.75 + face * 0.35
	var at := Vector2(dog.position.x, dog.position.z)
	var gap: Vector2 = want - at
	var moving: bool = gap.length() > 0.05
	at = at + gap * minf(1.0, dt * 4.0)
	dog.position = MapData.at(at, MapData.foot(at) - MapData.height(at))
	if gap.length() > 0.02:
		dog.rotation.y = lerp_angle(dog.rotation.y, atan2(face.x, face.y), minf(1.0, dt * 6.0))
	var ap: AnimationPlayer = p["ap"]
	if ap != null:
		var name := "Walk" if moving and n.state != "idle" else "Idle"
		if ap.has_animation(name) and ap.current_animation != name:
			ap.play(name, 0.2)

func _drop(p: Dictionary) -> void:
	var n = p["n"]
	if is_instance_valid(n):
		G.npcs.erase(n)
		n.queue_free()
	if p["dog"] != null and is_instance_valid(p["dog"]):
		p["dog"].queue_free()
	people.erase(p)
