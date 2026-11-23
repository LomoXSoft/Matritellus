extends RigidBody3D
## A lone traffic light on a corner's pavement whose amber only blinks: the one before the Tetoqa's chamfer, at the
## corner of the Calle de Santa Ana and the Calle del Cristo (tetoqa.gd; the user, 23 Nov 2026, to "El semáforo del
## chaflán: en Street View hay uno": "Si a las tres recomendaciones"). Street View (2024) shows a light grey post with
## one head of three lights looking up the Santa Ana, its amber lit by day: a warning light, not a crossroads' cycle
## (that is cruce.gd's and semaforos.gd's). It stops nobody, as the user wants of every light ("Solo paran coches":
## and a blinking amber does not even stop them).
##
## It is street furniture, as a mannequin or a sign (props.gd adopt): a car or a punch knocks it over, its lights go
## dark, it is cleared away after a while and back the next day (props.gd mend()). For whoever drives the lights
## (Sistemas's semaforos.gd), set_light("verde" | "ambar" | "rojo" | "off" | "blink"); `auto` false stops its own
## blinking.
##
## setup(at, look, y): `at` its foot (the map's x, z), `look` where its head looks (the map's x, z), `y` its foot in its
## parent's frame.

const Parts = preload("res://scripts/parts.gd")

const POST := 0xc4c8cc                  # (light grey, as Street View shows it)
const HOUSING := 0x17181a
const TALL := 2.95                      # the post's top
const HEAD_Y := 2.45                    # the head's middle
const BLINK := 0.6                      # seconds lit, seconds dark
const LIT := {"rojo": Color(1.0, 0.13, 0.1), "ambar": Color(1.0, 0.62, 0.05), "verde": Color(0.1, 0.95, 0.42)}
const COLOURS := ["rojo", "ambar", "verde"]
const RAD := 0.5                        # how close a car has to get (props.gd)
const HEAT := 8.0                       # how much the police mind (as the crossroads' lights)

var p: Vector2
var state := "blink"                    # what it shows: "blink" its own, or what set_light() was told
var auto := true                        # its own blinking runs
var lit := false                        # the amber is lit now (while blinking)
var _lenses := {}                       # colour -> its lens's material
var _t := 0.0
var _props = null
var _was_up := true
var W

func setup(world, at: Vector2, look: Vector2, y: float) -> void:
	W = world
	p = at
	position = Vector3(at.x, y, at.y)
	var d := (look - at).normalized()
	rotation.y = atan2(d.x, d.y)        # (its head looks along +z)
	mass = 40.0
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	freeze = true
	collision_layer = 16
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(0.3, TALL, 0.3)
	cs.shape = bx
	cs.position.y = TALL / 2.0
	add_child(cs)
	add_child(Parts.part("cyl", POST, Vector3(0, TALL / 2.0, 0), Vector3(0.055, TALL, 0.055)))          # the post...
	add_child(Parts.part("cyl", POST, Vector3(0, 0.07, 0), Vector3(0.1, 0.14, 0.1)))                 # ...its foot...
	add_child(Parts.part("cyl", POST, Vector3(0, TALL + 0.02, 0), Vector3(0.065, 0.04, 0.065)))      # ...its cap
	var hz := 0.2                                                                                  # the head, before the post
	for by in [0.32, -0.36]:
		add_child(Parts.part("box", POST, Vector3(0, HEAD_Y + by, 0.1), Vector3(0.05, 0.045, 0.16)))   # (its brackets)
	add_child(Parts.part("box", HOUSING, Vector3(0, HEAD_Y, hz), Vector3(0.3, 0.94, 0.22)))
	for k in range(3):
		var cy := HEAD_Y + 0.3 - k * 0.3
		var m := StandardMaterial3D.new()
		m.emission_enabled = true
		_lenses[COLOURS[k]] = m
		var lens := Parts.part("cyl", 0, Vector3(0, cy, hz + 0.115), Vector3(0.1, 0.012, 0.1))
		lens.rotation.x = PI / 2.0
		lens.material_override = m
		add_child(lens)
		add_child(Parts.part("box", HOUSING, Vector3(0, cy + 0.115, hz + 0.2), Vector3(0.254, 0.018, 0.17)))    # its hood...
		add_child(Parts.part("box", HOUSING, Vector3(-0.118, cy + 0.05, hz + 0.16), Vector3(0.018, 0.12, 0.1)))
		add_child(Parts.part("box", HOUSING, Vector3(0.118, cy + 0.05, hz + 0.16), Vector3(0.018, 0.12, 0.1)))
	_show()

## what it shows: "verde", "ambar", "rojo", "off", or "blink" (its own amber, on and off)
func set_light(s: String) -> void:
	state = s
	if s != "blink":
		lit = false
	_show()

func _lamp(c: String, on: bool) -> void:
	var m: StandardMaterial3D = _lenses[c]
	var col: Color = LIT[c]
	m.albedo_color = col if on else Color(col.r * 0.17, col.g * 0.17, col.b * 0.17)
	m.emission = col
	m.emission_energy_multiplier = 2.4 if on else 0.0

func _show() -> void:
	var up := standing()
	for c in COLOURS:
		var on := false
		if up:
			on = (lit and c == "ambar") if state == "blink" else c == state
		_lamp(c, on)

## standing in its place (not knocked over, nor cleared away)
func standing() -> bool:
	return freeze and visible and collision_layer == 16

func _process(dt: float) -> void:
	if _props == null and W != null:                     # (the street's furniture is made after the town)
		var game = W.get_parent()
		var pr = game.get("props") if game != null else null
		if pr != null and pr.has_method("adopt"):
			_props = pr
			pr.adopt(self, p, "semaforo", RAD, HEAT)
	var up := standing()
	if up != _was_up:                                    # (knocked over: dark; stood up again: lit)
		_was_up = up
		_show()
	if state != "blink" or not auto:
		return
	_t -= dt
	if _t > 0.0:
		return
	_t = BLINK
	lit = not lit
	_show()
