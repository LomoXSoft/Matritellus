extends RigidBody3D
## A shop's mannequin by its door (the user, 23 Nov 2026, of the MaxiPrecio: "Ponle un maniquí con ropa y sombrero en la
## puerta (puede ser un modelo de NPC blanco y la ropa con color), que sea rompible y que cambie cada día
## aleatoriamente"). It is one of the game's own figures (chara.gd) with its skin turned to white plastic, no face and
## no hair, standing on a little dark base. Its clothes, shoes and hat come out of the creator's own choices, in their
## colours, and change each day: picked at random with the day for the seed, so one day always dresses it the same.
## It is changed while nobody is looking at it.
##
## It is street furniture (props.gd adopt()): a punch or a car knocks it over; it is cleared away after a while and is
## back the next day, as everything else is (props.gd mend()).
##
## It is out only while the shop is open (the user: "Solo mientras la tienda está abierta"): set_out(false) takes it in
## (unseen, nothing to bump into, no punch or car reaches it: its "rad" for props.gd is put out of reach) and
## set_out(true) puts it out again, in that day's clothes. If it was knocked over, it stays down as the rest until
## props.gd mends it; mended while the shop is shut, it is taken in on its next tick.
##
## setup(world, at, heading, y, trinkets): `at` where it stands (the map's x, z), `y` its foot in its parent's frame;
## `trinkets` for an accessories shop's (the Tetoqa's, tetoqa.gd: the user, 23 Nov 2026, "Mismo tratamiento que con
## MiniPrecio pero esta vez para complementos"): always a hat, and nearly always earrings and something at its neck (a
## necklace, pearls, a scarf, flowers, a choker), changing each day as the rest; no glasses (those are the opticians':
## the user, 23 Nov 2026, "gafas en las ópticas y complementos en las tiendas de complementos"). `in_window`: one standing behind
## a shop's glass (the Tetoqa's windows: the user, 23 Nov 2026, to "Maniquíes en los escaparates": "Si a las tres
## recomendaciones"): nothing reaches it (no punch, no car: it is not street furniture), it is there whether the shop
## is open or not, and it is dressed anew each day as the rest, while nobody is looking. `with_shoes`: a shoe shop's (the
## Pisacastaña's, pisacastana.gd: the user, 23 Nov 2026, "Mismo tratamiento que las otras dos tiendas pero solo con
## zapatos"): its shoes are always showy ones (boots, trainers, sandals, flats, heels, Sunday shoes) and a little white
## stand by it shows one more pair of the day's, in the same colour.

const Chara = preload("res://scripts/chara.gd")
const Parts = preload("res://scripts/parts.gd")

## out of the creator's choices (creator.gd OPTIONS): what a shop's dummy would wear
const HATS := ["cap", "beret", "straw", "parpusa", "fedora", "bombin", "pamela", "panoleta", "diadema", "beisbol", "beisbol_atras", "vaquero"]
const HAT_COLOURS := [0x1f9a55, 0xc0392b, 0x2f6bb5, 0xe6b422, 0x26262b, 0xf4f1e8, 0x8a6a48, -1]
const SHIRTS := [0xe8553d, 0x3b5fa8, 0xf8f8f8, 0x7fb069, 0xe6c229, 0x26262b, 0xef8fa9, 0x9d4edd, 0xef7f1a, 0x2a9d8f, 0x8a6a48, 0x8d99ae]
const TOPS := [0, 1, 2, 3, 4, 5, 6, 7, 8, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 22, 23]      # (not the peña's T-shirt, nor the work coat)
const SHOE_TYPES := [0, 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]                          # (never bare feet)
const SHOES := [0x4a3424, 0x1b1b1f, 0xf8f8f8, 0xb23a3a, 0x3b5fa8, 0x3f7d4a, 0xe6c229, 0xef8fa9]
const NECK := [5, 6, 7, 9, 11, 12]               # sometimes: a fiesta neckerchief, a tie, a bow tie, a scarf, flowers, a choker
const KERCHIEFS := [0x2f63d6, 0xf28a00, 0xf2c200, 0x8cc63f, 0xd42a1e, 0x1e8c3a]
const TRINKET_NECK := [1, 1, 2, 4, 4, 9, 11, 12, 5]   # an accessories shop's: a chain, a medal, pearls, a scarf, flowers, a choker, a neckerchief
const TRINKET_EARRINGS := [1, 2, 4, 5, 6, 7]         # (studs, hoops, drops, pearls, silver hoops, flowers)
const SHOWY_SHOES := [1, 5, 8, 9, 10, 12, 13]     # a shoe shop's: boots, trainers, sandals, flats, cowboy boots, heels, Sunday shoes
const STAND := 0xf4f4f0                          # (its stand of shoes: white)
const SKIN := 0xf1f0ec                           # (its own: no garment comes in it, so it tells the plastic apart)
const CHEEKS := 0xf59a8c                         # (chara.gd's blush: a dummy has none)
const BASE := 0.05                               # the base's height: the figure stands on it
const WINDOW_SCALE := 0.8                        # behind a shop's glass: a little smaller (the game's big heads fill a window)
const RAD := 0.35                                # how close a car has to get (props.gd)
const HEAT := 4.0                                # how much the police mind

var W
var p: Vector2
var day := -1000                                 # the day it is dressed for
var look: Dictionary = {}                        # what it wears today
var figure: Node3D
var _props = null
var _t := 0.0
var out := true                                  # whether the shop wants it out (it is open)
var away := false                                # taken in, the shop shut
var trinkets := false                            # an accessories shop's: hat, earrings, necklace
var window := false                              # behind a shop's glass: not street furniture
var shoes := false                               # a shoe shop's: showy shoes and a stand of the day's pair by it
var _stand: Node3D
const NOWHERE := -1.0e6                          # (its reach to props.gd while it is in: nothing gets that close)
static var _plastic: StandardMaterial3D

func setup(world, at: Vector2, heading: float, y: float, with_trinkets := false, in_window := false, with_shoes := false) -> void:
	W = world
	trinkets = with_trinkets
	shoes = with_shoes
	window = in_window
	p = at
	position = Vector3(at.x, y, at.y)
	rotation.y = heading
	mass = 14.0
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	freeze = true                                # (standing still until props.gd takes it in and something knocks it over)
	collision_layer = 0 if window else 16           # (behind the glass: nothing bumps into it)
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.3
	cyl.height = 1.95
	cs.shape = cyl
	cs.position.y = BASE + 0.975
	add_child(cs)
	var k := WINDOW_SCALE if window else 1.0
	add_child(Parts.part("cyl", 0x2c2c2e, Vector3(0, BASE * 0.5, 0), Vector3(0.62 * k, BASE, 0.62 * k)))      # its base
	add_child(Parts.part("cyl", 0xb9bcc0, Vector3(0, BASE + 0.004, 0), Vector3(0.2 * k, 0.008, 0.2 * k)))     # (the steel plate its foot is fixed to)
	var game = W.get_parent() if W != null else null
	dress(int(game.get("day_n")) if game != null and game.get("day_n") != null else 0)

## what it wears on day `d`: always the same for the same day
func outfit(d: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("maniqui %d %d %d" % [d, roundi(p.x * 10.0), roundi(p.y * 10.0)])
	var o := {"skin": SKIN, "hair": null, "eyes": 0, "eye_color": SKIN, "brows": 3, "face": 0, "lashes": 0, "earrings": 0,
		"build": 0.86, "socks": SKIN}
	o["top"] = TOPS[rng.randi() % TOPS.size()]
	o["shirt"] = SHIRTS[rng.randi() % SHIRTS.size()]
	o["shirt2"] = SHIRTS[rng.randi() % SHIRTS.size()] if rng.randf() < 0.6 else -1
	o["shirt3"] = SHIRTS[rng.randi() % SHIRTS.size()] if rng.randf() < 0.4 else -1
	o["hat"] = HATS[rng.randi() % HATS.size()]
	o["hat_color"] = HAT_COLOURS[rng.randi() % HAT_COLOURS.size()]
	o["hat_band"] = SHIRTS[rng.randi() % SHIRTS.size()]
	o["shoe_type"] = SHOE_TYPES[rng.randi() % SHOE_TYPES.size()]
	o["shoes"] = SHOES[rng.randi() % SHOES.size()]
	o["pendant"] = NECK[rng.randi() % NECK.size()] if rng.randf() < 0.3 else 0
	o["kerchief"] = KERCHIEFS[rng.randi() % KERCHIEFS.size()]
	o["glasses"] = [5, 6][rng.randi() % 2] if rng.randf() < 0.2 else 0
	if trinkets:                                     # (drawn after the rest: the clothes of a day stay as they were)
		if rng.randf() < 0.8:                          # (where its glasses were drawn: the draw is kept, so each day's other
			rng.randi()                                  # things stay as they were)
		o["glasses"] = 0                               # (none: glasses are sold at the opticians, "gafas en las ópticas y complementos en las tiendas de complementos")
		o["earrings"] = TRINKET_EARRINGS[rng.randi() % TRINKET_EARRINGS.size()] if rng.randf() < 0.9 else 0
		o["pendant"] = TRINKET_NECK[rng.randi() % TRINKET_NECK.size()] if rng.randf() < 0.9 else 0
	if shoes:
		o["shoe_type"] = SHOWY_SHOES[rng.randi() % SHOWY_SHOES.size()]
		o["shoes"] = SHOES[rng.randi() % SHOES.size()]
		o["stand_shoes"] = SHOES[rng.randi() % SHOES.size()]
	return o

## dresses it for day `d`: the figure made anew in that day's clothes
func dress(d: int) -> void:
	day = d
	look = outfit(d)
	if figure != null:
		remove_child(figure)
		figure.free()
	var who = Chara.new()
	who.setup(look)
	for n in [who.get("_eyes_open"), who.get("_eyes_closed")]:
		if n != null:
			n.visible = false
			n.set_meta("off", true)
	figure = who.vis
	who.remove_child(figure)
	who.free()
	_whiten(figure)
	figure.position.y = BASE
	if window:
		figure.scale = Vector3.ONE * WINDOW_SCALE
	add_child(figure)
	if shoes:
		_shoe_stand()

## a shoe shop's: a little white stand by its base, a pair of shoes on it in the day's colour (another pair, of the
## colour of its own, at its foot)
func _shoe_stand() -> void:
	if _stand != null:
		remove_child(_stand)
		_stand.free()
	_stand = Node3D.new()
	_stand.position = Vector3(0.52, 0.0, 0.05)
	add_child(_stand)
	_stand.add_child(Parts.part("box", STAND, Vector3(0, 0.21, 0), Vector3(0.32, 0.42, 0.3)))
	_stand.add_child(Parts.part("box", 0xd8d8d4, Vector3(0, 0.425, 0), Vector3(0.34, 0.01, 0.32)))
	for pair in [[0.43, int(look.get("stand_shoes", 0x1b1b1f))], [0.0, int(look.get("shoes", 0x1b1b1f))]]:
		var y: float = pair[0]
		var col: int = pair[1]
		var z := 0.0 if y > 0.0 else 0.26
		for s in [-0.055, 0.055]:
			_stand.add_child(Parts.part("box", 0x2a2622 if col != 0x1b1b1f else 0x6a4a32, Vector3(s, y + 0.009, z), Vector3(0.08, 0.018, 0.24)))
			_stand.add_child(Parts.part("box", col, Vector3(s, y + 0.05, z - 0.02), Vector3(0.076, 0.065, 0.19)))
			_stand.add_child(Parts.part("box", col, Vector3(s, y + 0.035, z + 0.09), Vector3(0.068, 0.035, 0.05)))

## its skin to white plastic; what makes a face (the blush, the eyes) away
func _whiten(root: Node) -> void:
	if _plastic == null:
		_plastic = StandardMaterial3D.new()
		_plastic.albedo_color = Color(0.97, 0.97, 0.95)
		_plastic.roughness = 0.6
		_plastic.metallic_specular = 0.25               # (a little sheen: a strong one picks up the sky and greys the white)
		_plastic.emission_enabled = true                 # (so that it reads white under the awning too)
		_plastic.emission = Color(0.62, 0.62, 0.6)
		_plastic.emission_energy_multiplier = 0.45
	var skin := Parts.mat(SKIN)
	var skin_vc := Chara._vc(SKIN)
	var cheeks := Parts.mat(CHEEKS)
	var todo: Array = [root]
	while not todo.is_empty():
		var n: Node = todo.pop_back()
		todo.append_array(n.get_children())
		if not (n is MeshInstance3D):
			continue
		var mi := n as MeshInstance3D
		if mi.material_override == cheeks:
			mi.visible = false
		elif mi.material_override == skin or mi.material_override == skin_vc:
			mi.material_override = _plastic
		if mi.mesh != null:
			for si in range(mi.mesh.get_surface_count()):
				var sm := mi.get_surface_override_material(si)
				if sm == skin or sm == skin_vc:
					mi.set_surface_override_material(si, _plastic)

## how many of its pieces are white plastic, and how many of its face's are still shown (for the tests)
func whites() -> Vector2i:
	var white := 0
	var face := 0
	var cheeks := Parts.mat(CHEEKS)
	var todo: Array = [figure]
	while not todo.is_empty():
		var n: Node = todo.pop_back()
		todo.append_array(n.get_children())
		if n is MeshInstance3D and (n as MeshInstance3D).material_override == _plastic:
			white += 1
		if n is MeshInstance3D and (n as MeshInstance3D).material_override == cheeks and n.visible:
			face += 1
		if n.has_meta("off") and (n as Node3D).visible:
			face += 1
	return Vector2i(white, face)

## standing in its place (not knocked over, nor cleared away, nor taken in)
func standing() -> bool:
	return freeze and visible and collision_layer == 16 and not away

## out while the shop is open, in while it is shut
func set_out(on: bool) -> void:
	out = on
	_apply()

func _apply() -> void:
	if not freeze:                                       # (knocked over, still lying about: as the rest of the wreck)
		return
	if out:
		if away:
			away = false
			visible = true
			collision_layer = 16
			set_meta("rad", RAD)
		return
	if away or (visible and collision_layer == 16):     # (standing, or in already: kept in; a wreck cleared away waits for its mending)
		away = true
		visible = false
		collision_layer = 0
		set_meta("rad", NOWHERE)

func _process(dt: float) -> void:
	_t -= dt
	if _t > 0.0 or W == null:
		return
	_t = 1.0
	var game = W.get_parent()
	if game == null:
		return
	if window:                                           # (behind the glass: only its clothes change, unseen)
		var dw = game.get("day_n")
		if dw != null and int(dw) != day and not (game.has_method("sees") and game.sees(p)):
			dress(int(dw))
		return
	if _props == null:                                   # (the street's furniture is made after the town)
		var pr = game.get("props")
		if pr != null and pr.has_method("adopt"):
			_props = pr
			pr.adopt(self, p, "maniqui", RAD, HEAT)
			if away:                                     # (adopt() stands it up: in it stays)
				away = false
				visible = true
	_apply()
	var d = game.get("day_n")
	if d != null and int(d) != day and (away or (standing() and game.has_method("sees") and not game.sees(p))):
		dress(int(d))
