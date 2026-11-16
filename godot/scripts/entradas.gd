extends Node3D
## The way into a small shop (the user, 16 November 2026, with a picture of a game's markers: "En las tiendas como esta
## o la de VIP que sean pequeñas deberíamos poner un arrow marker low-poly animado ... y pasar sobre él te mandará a la
## tienda, que será un espacio aparte y ahí podremos trabajar sin límites de fachada o tamaño"; and, on its colour:
## "Mejor hacerlo verde para que vaya a juego con la flecha de personaje que ya tenemos").
##   - Before the door of each small shop, on the pavement: a green arrow pointing down, bobbing and turning, over a
##     ring of green light on the ground. Step on it and you are in the shop: a set of its own, off the map.
##   - Inside, another at the door: standing on it, the action button ("Salir") takes you back out -- not just by
##     stepping on it, so that nobody goes out by mistake (the user, the same day).
##   - The way in only while the shop is open, and only on foot; the way out always (it may shut while you are in).
##   - None of them in a scene, a conversation or a menu: they would only be in the picture (the user, the same day).
##     Green is what you are after (the arrow over whoever has a mission for you is the same shape: marcas.gd).
## Which: every place that takes you somewhere else, a set of its own (the user, the same day: "por tienda «pequeña» me
## refiero a ubicación a la que te transportes. VIP te transporta a otro sitio, los recreativos también, así que
## necesitan flecha. Sitios abiertos como Kebab Luis no necesitan"): the V.I.P. (vipshop.gd), the Galaxy Recress
## (recress_sala.gd) and the Papelería Rocas (its set: world.comunal.tienda, once there is one).
## A shop is anything with door_out, out_spawn, out_h, in_door, in_spawn and `open` (a bool: open now; a number, as
## the V.I.P.'s, is how far its door has swung, and that shop has no hours).

const STEP := 0.8                       # how close to the arrow's middle you must step
const AWAY := 1.6                       # ...and how far off you must have gone before it takes you again
const FAR := 40.0                       # it is not drawn from further off than this
const OUT := 1.1                        # how far before the door the arrow stands
const GREEN := Color(0.22, 0.84, 0.3)
const ARROW_ALPHA := 0.8                # how solid the arrow is (a little see-through: the user, 16 Nov 2026)

var G
var _marks := {}                        # [place, "out"|"in"] key -> Node3D (the arrow and its ring)
var _armed := {}                        # the same key -> true once you have stepped off it
var _spin := 0.0
var _was_in := false                    # were you indoors last time
var _exit = null                        # the place whose way out you are standing on (game.gd: "Salir" on the button)
var _mat: StandardMaterial3D
var _ink: StandardMaterial3D
var _ring_mat: StandardMaterial3D

func setup(game) -> void:
	G = game
	# a little see-through, so that it hides nothing behind it (the user, 16 Nov 2026: 80 %). Drawn depth first, so
	# that only its near side shows, as a solid thing would, with its sides lit and inked like everything else
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(GREEN, ARROW_ALPHA)
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.emission_enabled = true
	_mat.emission = Color(0.1, 0.5, 0.15)
	_mat.emission_energy_multiplier = 0.35
	_mat.roughness = 0.5
	_ink = StandardMaterial3D.new()                  # its dark outline: the same arrow a size bigger, seen from inside
	_ink.albedo_color = Color(0.06, 0.2, 0.08, ARROW_ALPHA)
	_ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ink.cull_mode = BaseMaterial3D.CULL_FRONT
	_ink.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.albedo_color = Color(GREEN, 0.45)
	_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

## the places that take you somewhere else: every one with a set of its own (an open place, Kebab Luis, has none)
func shops() -> Array:
	var out: Array = []
	if G.get("vip") != null:
		out.append(G.vip)
	if G.get("recress") != null and G.recress.get("sala") != null:
		out.append(G.recress.sala)
	var c = G.world.get("comunal") if G.world != null else null
	if c != null and c.get("tienda") != null:
		out.append(c.tienda)
	var n = G.world.get("noche") if G.world != null else null
	if n != null and n.get("tienda") != null:     # the Noche of the Calle del Teniente Infante (its set: noche_dentro.gd)
		out.append(n.tienda)
	var bs = G.world.get("bancosancho") if G.world != null else null
	if bs != null and bs.get("tienda") != null:   # the Copistería Sancho Panza, the girl of the posters inside (its set: copisteria_dentro.gd)
		out.append(bs.tienda)
	if G.get("casa") != null:                    # your own house, Calle de Alemania 5 (casa_dentro.gd)
		out.append(G.casa)
	return out

func is_shop(place) -> bool:
	return place != null and place in shops()

static func open(place) -> bool:
	var o = place.get("open")
	return not (o is bool) or bool(o)

## where the arrow stands: on the pavement a step before the door, outside; a step inside the door, in
static func spot(place, inside: bool) -> Vector2:
	var door: Vector2 = place.in_door if inside else place.door_out
	var into: Vector2 = (place.in_spawn if inside else place.out_spawn) - door
	return door + (into.normalized() if into.length() > 0.01 else Vector2.ZERO) * OUT

func _mark(key: Array) -> Node3D:
	if _marks.has(key):
		return _marks[key]
	var m := Node3D.new()
	var arrow := MeshInstance3D.new()
	arrow.name = "arrow"
	arrow.mesh = G.marcas._arrow_mesh           # (the same arrow as over whoever has a mission for you, bigger)
	arrow.material_override = _mat
	arrow.scale = Vector3.ONE * 2.2
	arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.add_child(arrow)
	var hull := MeshInstance3D.new()
	hull.mesh = arrow.mesh
	hull.material_override = _ink
	hull.scale = Vector3(1.07, 1.05, 1.5)            # (thicker through its depth, which is the thinnest way)
	hull.position = Vector3(0.0, -0.015, 0.0)
	hull.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arrow.add_child(hull)
	var ring := MeshInstance3D.new()
	ring.name = "ring"
	var tm := TorusMesh.new()
	tm.inner_radius = 0.48
	tm.outer_radius = 0.62
	tm.rings = 24
	tm.ring_segments = 4
	ring.mesh = tm
	ring.material_override = _ring_mat
	ring.scale = Vector3(1.0, 0.08, 1.0)
	ring.position.y = 0.04
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.add_child(ring)
	add_child(m)
	_marks[key] = m
	return m

## every frame: where each arrow is and whether it shows; and if you have just stepped on one, in (or out) you go
func tick(dt: float) -> void:
	_spin += dt
	var pp: Vector2 = G.player.p
	var crossed: bool = G.indoors != _was_in        # (in or out this moment, by an arrow or not: a mission's scene may put you out)
	_was_in = G.indoors
	var on_foot: bool = G.in_car == null and (G.phase == "play" or G.phase == "free") and G.dlg == null and not G.cine_lock and not G.menu.visible
	# in a scene, a conversation, a menu, a game at a machine: no arrows (they would only be in the picture: the user)
	var scene: bool = G.cine_lock or G.dlg != null or G.menu.visible or not (G.phase == "play" or G.phase == "free") \
		or (G.get("recress") != null and bool(G.recress.get("cine")))
	var go = null
	_exit = null
	for place in shops():
		for inside in [false, true]:
			var key: Array = [place, inside]
			var m := _mark(key)
			var at: Vector2 = spot(place, inside)
			var here: bool = G.indoors == inside and (not inside or G.inside_of == place)
			var show: bool = here and (inside or (open(place) and pp.distance_to(at) < FAR))      # (shut while you are in: you can still get out)
			m.visible = show and not scene
			if not show:
				_armed[key] = true
				continue
			m.global_position = Vector3(at.x, MapData.foot(at), at.y)      # (the sets stand on the ground where they are, off the map)
			var arrow: Node3D = m.get_node("arrow")
			arrow.scale = Vector3.ONE * (1.5 if inside else 2.2)          # (smaller and lower in a room: it is in the camera's way in there)
			arrow.position.y = (0.9 if inside else 1.15) + sin(_spin * 3.0) * 0.12
			arrow.rotation.y = _spin * 2.2
			(m.get_node("ring") as Node3D).scale = Vector3.ONE * (1.0 + 0.08 * sin(_spin * 4.0)) * Vector3(1.0, 0.08, 1.0)
			if inside:                                   # the way out: stand on it and press the action button (not by mistake: the user)
				if on_foot and not scene and pp.distance_to(at) < STEP * 1.2:
					_exit = place
				continue
			var d: float = pp.distance_to(at)
			if d > AWAY:
				_armed[key] = true
			elif G._door_cool > 0.0 or crossed:
				_armed[key] = false                     # (just come through a door, by whatever way, and standing on it: not straight back)
			if on_foot and G._door_cool <= 0.0 and _armed.get(key, true) and d < STEP and go == null:
				go = [place, inside]
				_armed[key] = false
	if go != null:
		var other: Array = [go[0], not go[1]]
		_armed[other] = false                       # (where you come out, you are standing on the other one: not straight back)
		G._use_door(not go[1], go[0])

## standing on the way out of a set (its arrow inside): the place, for the button's "Salir"; null if not
func exit_here():
	return _exit if _exit != null and G.indoors and G._door_cool <= 0.0 else null

## the action button pressed on it: out you go
func leave() -> void:
	var place = exit_here()
	if place == null:
		return
	_armed[[place, false]] = false                  # (you come out standing by the way in: not straight back)
	G._use_door(false, place)

## what the self-test wants to know
func mark_of(place, inside: bool):
	return _marks.get([place, inside])

# ---------------- the camera inside ----------------
## Inside a set, the camera (the user, 16 November 2026: "cámara fija con algo de inclinación y al hablar o
## interaccionar con algo o alguien de la tienda pasara a una cámara más cercana y cinematográfica"):
##   - as you walk about: high up by the wall with the door, under the ceiling, looking down into the room at an
##     angle, half at the middle of it and half at you, so that the room is in sight and you are in it;
##   - talking to somebody (or a menu of theirs open): closer, from beside the two of you, their face at about two metres.
## The room comes from the set's own sizes: half its width (SHOP_W, HALF or W), its depth (SHOP_D or D) and its
## height (SHOP_H, TALL or H), from its door inwards.
const LOOK_MIX := 0.5                   # how much the camera looks at you rather than at the middle of the room
var talk_cam := false                   # (the self-test: whether the last frame was the close one)

func room(place) -> Dictionary:
	var k: Dictionary = place.get_script().get_script_constant_map() if place.get_script() != null else {}
	var fwd: Vector2 = (place.in_spawn - place.in_door).normalized()
	var half: float = float(k.get("SHOP_W", k.get("HALF", k.get("W", 4.0))))
	var deep: float = float(k.get("SHOP_D", k.get("D", 8.0)))
	var tall: float = float(k.get("SHOP_H", k.get("TALL", k.get("H", 3.0))))
	return {"o": place.in_door - fwd * 0.45, "fwd": fwd, "side": Vector2(-fwd.y, fwd.x), "half": half, "deep": deep, "tall": tall}      # (o: the middle of its door wall)

## The enclosed places in the town itself that you walk into: their room, if you are in one ({} if not). For now
## Kebab Luis's house, open to its terrace (the user, 16 November 2026: "Aplicar en todos los recintos pequeños o
## cerrados. Mejor que la primera persona, así se ve todo el escenario"); its door wall is the front, on the terrace.
func town_room(pp: Vector2) -> Dictionary:
	var K = G.get("kebab")
	if K != null and K.inside(pp):
		var fwd: Vector2 = -K.out
		return {"o": K.spot((K.X0 + K.X1) / 2.0, K.FRONT), "fwd": fwd, "side": Vector2(-fwd.y, fwd.x), "half": (K.X1 - K.X0) / 2.0,
			"deep": K.FRONT - K.BACK, "tall": K.TALL}
	return {}

## the camera, when you are on foot inside a set or an enclosed place of the town; false when it is not for here (the
## street, a car, the ring, a game at a machine)
func camera(dt: float, pp: Vector2) -> bool:
	if G.in_car != null or G.phase == "boxing" or G.phase == "tokken":
		return false
	var r: Dictionary = {}
	if G.indoors:
		var place = G.inside_of if G.inside_of != null else G.get("vip")
		if place != null:
			r = room(place)
	else:
		r = town_room(pp)
	if r.is_empty():
		return false
	var fwd: Vector2 = r["fwd"]
	var side: Vector2 = r["side"]
	var o: Vector2 = r["o"]
	var floor_y: float = MapData.foot(pp)
	G.cam_yaw = atan2(fwd.x, fwd.y)              # (forward on the stick is into the room, whatever the mouse does)
	var want: Vector3
	var look: Vector3
	var who = _talking_to(pp)
	talk_cam = who != null
	if who != null:
		# the two of you, from beside: at the side of the line between you that looks back towards the door (there
		# is room there), a little behind you, their face about two metres off
		var them: Vector2 = who.p
		var d: Vector2 = (them - pp).normalized() if them.distance_to(pp) > 0.05 else fwd
		var n := Vector2(-d.y, d.x)
		if n.dot(-fwd) < 0.0:
			n = -n
		# over your shoulder, a little above your head: their face before the lens, a couple of metres off, over
		# whatever counter stands between you
		var eye: Vector2 = _inside(r, pp - d * 1.0 + n * 1.25)          # (far enough to one side that your head is beside their face, not over it)
		var tall_them: float = float(who.look_data.get("scale", 1.0)) if who.get("look_data") != null else 1.0
		want = Vector3(eye.x, floor_y + 1.8, eye.y)
		look = Vector3(them.x, floor_y + 1.3 * tall_them, them.y)
	else:
		# in a corner of the door's wall, looking across the room on the slant (not straight down the line from the
		# door, where you come in and where the way out stands), and sliding a little after you
		var across: float = clampf((pp - o).dot(side), -r["half"] + 0.6, r["half"] - 0.6)
		var eye: Vector2 = o + fwd * 0.35 + side * clampf(-r["half"] * 0.62 + across * 0.25, -r["half"] + 0.4, r["half"] - 0.4)
		var middle: Vector2 = o + fwd * (r["deep"] * 0.5)
		var at: Vector2 = middle.lerp(pp, LOOK_MIX)
		want = Vector3(eye.x, floor_y + minf(r["tall"] - 0.25, 3.6), eye.y)
		look = Vector3(at.x, floor_y + 0.9, at.y)
	var ease: float = 1.0 - exp(-(5.0 if talk_cam else 4.0) * dt)
	G.cam_pos = G.cam_pos.lerp(want, ease) if G.cam_pos.distance_to(want) < 12.0 else want      # (straight there on coming in)
	G.cam_look = G.cam_look.lerp(look, ease) if G.cam_look.distance_to(look) < 12.0 else look
	G.cam.position = G.cam_pos
	if G.cam.position.distance_to(G.cam_look) > 0.1:
		G.cam.look_at(G.cam_look)
	return true

## whoever you are talking to in here (a dialogue, or a choice of theirs open), if anybody
func _talking_to(pp: Vector2):
	var busy: bool = G.dlg != null or (G.menu.visible and G.menu.page == "choice")
	if not busy:
		return null
	var from = G.dlg.get("from") if G.dlg != null else null
	if from != null and is_instance_valid(from) and from.get("p") != null and (from.p as Vector2).distance_to(pp) < 6.0:
		return from
	var best = null
	for n in G.npcs:                               # (said without saying who: the nearest person in here)
		if is_instance_valid(n) and n.visible and not n.away and (n.p as Vector2).distance_to(pp) < 4.0:
			if best == null or (n.p as Vector2).distance_to(pp) < (best.p as Vector2).distance_to(pp):
				best = n
	return best

## a spot kept inside the room's walls
func _inside(r: Dictionary, p: Vector2) -> Vector2:
	var o: Vector2 = r["o"]
	var x: float = clampf((p - o).dot(r["side"]), -r["half"] + 0.4, r["half"] - 0.4)
	var z: float = clampf((p - o).dot(r["fwd"]), 0.4, r["deep"] - 0.4)
	return o + r["side"] * x + r["fwd"] * z
