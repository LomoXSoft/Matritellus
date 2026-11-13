extends Node3D
## A garage you drive into: a bay inside the building, behind a shutter that rolls up when you come and comes down
## while they work on the car. The bay is cut out of the real building in the bake (tools/bake_godot.py, GARAGES) and
## this builds what goes in the hole: floor, walls, roof, the shutter, the clutter of a workshop and the front.
##
##   valdeacero   Talleres Valdeacero, Paseo del Cristo: whitewash and a blue plinth, the name in blue, TALLERES on
##                a board above the roof. The one the tow truck knows. (Everything named after the town's patroness
##                says Valdeacero in the game.)
##   xandro       Talleres Xandro, further out on the same road: a charcoal sheet-metal gable with the name in big
##                lime-green letters, a green stripe, chequered pillars between the showroom windows on the left and
##                the workshop doorway under a red band on the right.
##   df           df Mecánica, in town on the Calle del Palo: the ground floor of an apricot two-storey house, wooden
##                eaves, balconies upstairs, a stone arch and the office on the left, signs with a tyre and "df".
##   errejota     Errejota Taller, Avenida de los Reyes Católicos (the Villacañas road): a yellow and black gabled
##                front with big lettering, a showroom window on the left and the doorway in the middle.

const Parts = preload("res://scripts/parts.gd")

const LOOKS := {
	"valdeacero": {"tall": 4.0, "door_w": 3.6, "door_h": 3.0, "wall": 0xf4f2ec, "inside": 0xc9c6bc, "shutter": 0x8d949c},
	"errejota": {"tall": 5.5, "door_w": 4.8, "door_h": 4.1, "wall": 0xf2c200, "inside": 0xc4c1b8, "shutter": 0x2a2c30},
	"df": {"tall": 6.9, "door_w": 5.0, "door_h": 3.1, "wall": 0xe9a968, "inside": 0xd2cfc6, "shutter": 0x8d949c, "ceil": 3.7, "roof": 0xb9552f},
	"xandro": {"tall": 6.8, "door_w": 4.8, "door_h": 4.0, "wall": 0x2b2d33, "inside": 0xc4c1b8, "shutter": 0x9aa0a8},
}
const THICK := 0.22            # the bay's own walls
const GLOW := 0.75             # the strip lights
const ROLL := 1.1              # how fast the shutter moves, in doors per second... nearly

var id := ""
var mouth: Vector2             # the middle of the doorway, on the line of the front
var out: Vector2               # out into the street
var right: Vector2             # to the right of somebody looking at the front
var w := 6.0                   # the bay: width...
var d := 9.0                   # ...and depth
var tall := 4.0
var top := 4.0                 # the ceiling of the bay (lower than the building where there is a floor above)
var door_w := 3.6
var door_h := 3.0
var spot: Vector2              # where a car stands to be mended, inside
var apron: Vector2             # out in front of the doorway
var middle := 0.0              # how far to the right of the doorway the middle of the whole front is
var open := 0.0                # the shutter: 0 down, 1 rolled up
var want_open := false         # (game.gd says: somebody is at the door)
var busy := false              # a car is being mended: shut, whatever anybody wants

var _f: Node3D                 # +x right along the front, +z out into the street, origin at the foot of the doorway
var _shell: StaticBody3D
var _roller: Node3D
var _gate: CollisionShape3D
var _lamp: OmniLight3D
var _spark := 0.0

func _box(parent: Node3D, hex: int, pos: Vector3, size: Vector3) -> MeshInstance3D:
	var mi := Parts.part("box", hex, pos, size)
	parent.add_child(mi)
	return mi

## a box you can also drive into
func _solid(hex: int, pos: Vector3, size: Vector3) -> MeshInstance3D:
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = pos
	_shell.add_child(cs)
	return _box(_f, hex, pos, size)

func _text(parent: Node3D, s: String, pos: Vector3, px: int, hex: int) -> Label3D:
	var l := Label3D.new()
	l.text = s
	l.font_size = px
	l.pixel_size = 0.004
	l.modulate = Parts.col(hex)
	l.outline_size = 0
	l.position = pos
	parent.add_child(l)
	return l

## a flat triangle standing on the front, seen from both sides (corners given left, top, right as seen from the street)
func _gable(parent: Node3D, hex: int, a: Vector3, top: Vector3, b: Vector3) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3(0, 0, 1))
	for v in [a, top, b]:              # clockwise as seen from the street
		st.add_vertex(v)
	st.set_normal(Vector3(0, 0, -1))
	for v in [b, top, a]:
		st.add_vertex(v + Vector3(0, 0, -0.02))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = Parts.mat(hex)
	parent.add_child(mi)

func build(def: Dictionary) -> void:
	id = def["id"]
	var look: Dictionary = LOOKS[id]
	mouth = Vector2(def["m"][0], def["m"][1])
	out = Vector2(def["n"][0], def["n"][1])
	right = Vector2(out.y, -out.x)
	w = float(def["w"])
	d = float(def["d"])
	tall = look["tall"]
	top = look.get("ceil", tall)
	door_w = look["door_w"]
	door_h = look["door_h"]
	spot = mouth - out * (d * 0.55)
	apron = mouth + out * 6.0
	middle = (float(def["right"]) - float(def["left"])) / 2.0
	_f = Node3D.new()
	_f.position = MapData.at(mouth)
	_f.rotation.y = atan2(out.x, out.y)
	add_child(_f)
	_shell = StaticBody3D.new()
	_shell.collision_layer = 1
	_shell.collision_mask = 0
	_f.add_child(_shell)
	_bay(look)
	_shutter(look)
	_clutter(look)
	if id == "errejota":
		_front_errejota(float(def["left"]), float(def["right"]))
	elif id == "xandro":
		_front_xandro(float(def["left"]), float(def["right"]))
	elif id == "df":
		_front_df(float(def["left"]), float(def["right"]))
	else:
		_front_valdeacero()
	_forecourt(float(def["left"]), float(def["right"]))

# ---------------- the bay ----------------
func _bay(look: Dictionary) -> void:
	var wall: int = look["wall"]
	var inside: int = look["inside"]
	var hw := w / 2.0
	var side := hw - door_w / 2.0                 # how much front there is either side of the doorway
	for sx in [-1.0, 1.0]:
		_solid(inside, Vector3(sx * (hw - THICK / 2.0), tall / 2.0, -d / 2.0), Vector3(THICK, tall, d))          # the sides
		_solid(wall, Vector3(sx * (hw - side / 2.0), tall / 2.0, -THICK / 2.0 + 0.02), Vector3(side, tall, THICK))     # the front, either side
	_solid(inside, Vector3(0, tall / 2.0, -d + THICK / 2.0), Vector3(w, tall, THICK))                              # the back
	_solid(wall, Vector3(0, (door_h + tall) / 2.0, -THICK / 2.0 + 0.02), Vector3(door_w, tall - door_h, THICK))        # over the doorway
	_solid(look.get("roof", 0x6c7178), Vector3(0, tall - 0.1, -d / 2.0), Vector3(w, 0.2, d))                       # the roof
	if top < tall:                                                                                                 # the floor of upstairs
		_box(_f, 0x6c7178, Vector3(0, top + 0.1, -d / 2.0), Vector3(w - THICK, 0.2, d - THICK))
	# the floor: smooth concrete, an oil stain or two, yellow lines where the car goes
	_box(_f, 0x9a9b98, Vector3(0, 0.02, -d / 2.0 + 0.1), Vector3(w - THICK * 2.0, 0.04, d - 0.2))
	_box(_f, 0x9a9b98, Vector3(0, 0.02, 0.6), Vector3(door_w, 0.04, 1.4))                    # the ramp of the doorway
	var bay_len := d - 3.4
	for sx in [-1.0, 1.0]:
		_box(_f, 0xe6b422, Vector3(sx * 1.55, 0.045, -d * 0.55), Vector3(0.12, 0.01, bay_len))
	_box(_f, 0xe6b422, Vector3(0, 0.045, -d * 0.55 - bay_len / 2.0), Vector3(3.22, 0.01, 0.12))
	_box(_f, 0x4f4f4c, Vector3(0.35, 0.045, -d * 0.5), Vector3(0.9, 0.008, 1.3))
	_box(_f, 0x5c5b57, Vector3(-0.5, 0.045, -d * 0.68), Vector3(0.5, 0.008, 0.6))
	# strip lights, and the light they give (the sun does not get in here)
	var n := maxi(2, int(d / 3.5))
	for k in range(n):
		var tube := _box(_f, 0xffffff, Vector3(0, top - 0.24, -d * (k + 0.6) / float(n)), Vector3(1.6, 0.06, 0.16))
		var glow := StandardMaterial3D.new()
		glow.albedo_color = Color(1, 1, 1)
		glow.emission_enabled = true
		glow.emission = Color(0.95, 0.98, 1.0)
		glow.emission_energy_multiplier = 1.6
		tube.material_override = glow
	_lamp = OmniLight3D.new()
	_lamp.position = Vector3(0, top - 0.9, -d * 0.5)
	_lamp.omni_range = maxf(w, d) * 0.95
	_lamp.light_energy = GLOW
	_lamp.light_color = Color(0.95, 0.97, 1.0)
	_lamp.omni_attenuation = 1.4
	_lamp.shadow_enabled = false
	_f.add_child(_lamp)

# ---------------- the shutter ----------------
func _shutter(look: Dictionary) -> void:
	var hex: int = look["shutter"]
	_roller = Node3D.new()                        # hangs from the top of the doorway; rolling up is squashing it up there
	_roller.position = Vector3(0, door_h, -THICK / 2.0 + 0.02)
	_f.add_child(_roller)
	_box(_roller, hex, Vector3(0, -door_h / 2.0, 0), Vector3(door_w, door_h, 0.07))
	var slats := int(door_h / 0.22)
	var dark := Parts.col(hex).darkened(0.28).to_html(false).hex_to_int()
	for k in range(1, slats):
		_box(_roller, dark, Vector3(0, -door_h * k / float(slats), 0.04), Vector3(door_w, 0.03, 0.012))
	_box(_roller, dark, Vector3(0, -door_h + 0.06, 0.02), Vector3(door_w, 0.12, 0.11))             # the bottom bar
	_box(_f, dark, Vector3(0, door_h + 0.16, -THICK / 2.0 + 0.02), Vector3(door_w + 0.2, 0.32, THICK + 0.16))     # the drum it rolls onto
	for sx in [-1.0, 1.0]:                                                                    # the guides
		_box(_f, dark, Vector3(sx * (door_w / 2.0 + 0.04), door_h / 2.0, -THICK / 2.0 + 0.02), Vector3(0.1, door_h, THICK + 0.06))
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	_f.add_child(body)
	_gate = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(door_w, door_h, THICK)
	_gate.shape = shape
	_gate.position = Vector3(0, door_h / 2.0, -THICK / 2.0)
	body.add_child(_gate)

# ---------------- what a workshop has lying about (all of it against the walls: the middle is for the car) ----------------
func _clutter(_look: Dictionary) -> void:
	var hw := w / 2.0 - THICK
	var back := -d + THICK
	# the workbench along the back, with a vice and the board of spanners over it
	var bench_w := minf(w - 1.4, 4.2)
	_box(_f, 0x6a4a2c, Vector3(0, 0.86, back + 0.36), Vector3(bench_w, 0.08, 0.7))
	_box(_f, 0x3a3d42, Vector3(0, 0.42, back + 0.36), Vector3(bench_w - 0.1, 0.8, 0.62))
	_box(_f, 0xb23a3a, Vector3(-bench_w / 2.0 + 0.5, 1.0, back + 0.4), Vector3(0.22, 0.2, 0.3))
	_box(_f, 0x2f4f6f, Vector3(0, 1.85, back + 0.04), Vector3(bench_w - 0.4, 1.1, 0.04))
	for k in range(7):
		_box(_f, 0xc9ced4, Vector3(-bench_w / 2.0 + 0.6 + k * (bench_w - 1.2) / 6.0, 1.9 - (k % 3) * 0.08, back + 0.07), Vector3(0.07, 0.5 + (k % 2) * 0.22, 0.02))
	# tyres stacked in one corner, drums in the other
	for k in range(4):
		var tyre := Parts.part("cyl", 0x1b1b1f, Vector3(-hw + 0.5, 0.13 + k * 0.25, back + 1.5), Vector3(0.66, 0.24, 0.66))
		_f.add_child(tyre)
	for k in range(2):
		var tyre2 := Parts.part("cyl", 0x1b1b1f, Vector3(-hw + 0.5, 0.13 + k * 0.25, back + 2.3), Vector3(0.66, 0.24, 0.66))
		_f.add_child(tyre2)
	_f.add_child(Parts.part("cyl", 0x2f6bb5, Vector3(hw - 0.42, 0.45, back + 1.3), Vector3(0.56, 0.9, 0.56)))
	_f.add_child(Parts.part("cyl", 0xd9643a, Vector3(hw - 0.42, 0.45, back + 2.0), Vector3(0.56, 0.9, 0.56)))
	# a red tool trolley, a jack, a calendar that nobody has changed
	_box(_f, 0xc0392b, Vector3(hw - 0.4, 0.5, -d * 0.42), Vector3(0.5, 0.9, 0.8))
	_box(_f, 0x1b1b1f, Vector3(hw - 0.4, 0.97, -d * 0.42), Vector3(0.54, 0.04, 0.84))
	_box(_f, 0xe6b422, Vector3(-hw + 0.45, 0.12, -d * 0.4), Vector3(0.4, 0.16, 0.9))
	_box(_f, 0x1b1b1f, Vector3(-hw + 0.45, 0.3, -d * 0.4 + 0.5), Vector3(0.05, 0.5, 0.05))
	_box(_f, 0xf4f1e8, Vector3(-hw + 0.03, 1.7, -d * 0.3), Vector3(0.02, 0.6, 0.42))
	_box(_f, 0xc0392b, Vector3(-hw + 0.04, 1.86, -d * 0.3), Vector3(0.02, 0.22, 0.42))
	# the chair the boss never leaves, by the door
	_box(_f, 0xf4f2ec, Vector3(hw - 0.42, 0.42, -1.2), Vector3(0.45, 0.06, 0.45))
	_box(_f, 0xf4f2ec, Vector3(hw - 0.22, 0.72, -1.2), Vector3(0.05, 0.6, 0.45))
	for lx in [-0.18, 0.18]:
		for lz in [-0.18, 0.18]:
			_box(_f, 0xf4f2ec, Vector3(hw - 0.42 + lx, 0.2, -1.2 + lz), Vector3(0.04, 0.4, 0.04))

# ---------------- the fronts ----------------
func _front_valdeacero() -> void:
	var hw := w / 2.0
	var blue := 0x2f86d0
	var z := 0.03                                   # (the front of the bay's own wall)
	for sx in [-1.0, 1.0]:                          # the blue plinth, either side of the doorway
		_box(_f, blue, Vector3(sx * (hw + door_w / 2.0 + 0.1) / 2.0, 0.6, z), Vector3(hw - door_w / 2.0 - 0.1, 1.2, 0.03))
	_text(_f, "VALDEACERO", Vector3(0, 3.64, z + 0.03), 150, blue)
	# the board above the roof line
	_box(_f, 0xf4f2ec, Vector3(-0.3, tall + 0.42, 0.0), Vector3(3.9, 0.84, 0.08))
	_text(_f, "TALLERES", Vector3(-0.3, tall + 0.42, 0.05), 170, 0x1b1b1f)
	# the board of things they do, the letter box, the meter cupboard
	_box(_f, 0x26408f, Vector3(-2.38, 2.2, z), Vector3(0.5, 1.3, 0.03))
	for k in range(7):
		_box(_f, 0xf2c230, Vector3(-2.53, 2.7 - k * 0.16, z + 0.02), Vector3(0.09, 0.09, 0.01))
		_box(_f, 0xdfe6f2, Vector3(-2.3, 2.7 - k * 0.16, z + 0.02), Vector3(0.26, 0.04, 0.01))
	_box(_f, 0x1b1b1f, Vector3(-2.3, 1.42, z + 0.05), Vector3(0.24, 0.3, 0.1))
	_box(_f, 0xe6e3da, Vector3(2.4, 1.6, z), Vector3(0.42, 0.42, 0.04))

func _front_errejota(left: float, right_: float) -> void:
	var yellow := 0xf2c200
	var black := 0x17171a
	var hw := w / 2.0
	var z := 0.05
	var peak := tall + 2.5
	# the real wall either side of the bay gets a yellow skin; the bay's own front is yellow already
	_box(_f, yellow, Vector3(-(left + hw) / 2.0, tall / 2.0, z - 0.02), Vector3(left - hw, tall, 0.07))
	_box(_f, yellow, Vector3((right_ + hw) / 2.0, tall / 2.0, z - 0.02), Vector3(right_ - hw, tall, 0.07))
	# the gable standing up over the roof, trimmed in black
	_gable(_f, yellow, Vector3(-left, tall, z), Vector3(0, peak, z), Vector3(right_, tall, z))
	for side in [[-left, -1.0], [right_, 1.0]]:
		var run: float = absf(side[0])
		var rake := Node3D.new()
		rake.position = Vector3(side[0] / 2.0, (tall + peak) / 2.0, z + 0.01)
		rake.rotation.z = -side[1] * atan2(peak - tall, run)
		_f.add_child(rake)
		_box(rake, black, Vector3.ZERO, Vector3(Vector2(run, peak - tall).length() + 0.3, 0.32, 0.1))
	# black along the bottom, a black band under the eaves with the four promises in yellow
	for part in [[-left, -door_w / 2.0 - 0.55], [door_w / 2.0 + 0.55, right_]]:
		_box(_f, black, Vector3((part[0] + part[1]) / 2.0, 0.45, z + 0.02), Vector3(part[1] - part[0], 0.9, 0.05))
	_box(_f, black, Vector3((right_ - left) / 2.0, tall - 0.36, z + 0.02), Vector3(left + right_, 0.72, 0.05))
	_text(_f, "SERIEDAD  ·  CALIDAD  ·  GARANTIA  ·  BUEN SERVICIO", Vector3((right_ - left) / 2.0, tall - 0.36, z + 0.06), 140, yellow)
	# the name, big, in the gable
	_text(_f, "ERREJOTA", Vector3(0, tall + 1.18, z + 0.03), 330, black)
	_text(_f, "TALLER", Vector3(0, tall + 0.3, z + 0.03), 112, black)
	# the doorway: black jambs and a black board over it
	for sx in [-1.0, 1.0]:
		_box(_f, black, Vector3(sx * (door_w / 2.0 + 0.3), (door_h + 0.5) / 2.0, z + 0.02), Vector3(0.5, door_h + 0.5, 0.06))
	_box(_f, black, Vector3(0, door_h + 0.34, z + 0.06), Vector3(door_w + 1.1, 0.56, 0.06))
	_text(_f, "TALLER MULTIMARCA", Vector3(0, door_h + 0.34, z + 0.1), 100, yellow)
	# the showroom window on the left: one big pane in a black frame, a car's worth of gloom behind it
	var wl := -left + 1.0
	var wr := -door_w / 2.0 - 1.6
	var wm := (wl + wr) / 2.0
	_box(_f, black, Vector3(wm, 2.2, z + 0.02), Vector3(wr - wl + 0.3, 2.9, 0.05))
	_box(_f, 0x2c4a63, Vector3(wm, 2.2, z + 0.04), Vector3(wr - wl, 2.6, 0.03))
	_box(_f, 0x4d7594, Vector3(wm - 0.6, 2.75, z + 0.055), Vector3((wr - wl) * 0.5, 0.5, 0.01))          # the sky in the glass
	for k in range(1, 3):
		_box(_f, black, Vector3(wl + (wr - wl) * k / 3.0, 2.2, z + 0.06), Vector3(0.08, 2.6, 0.02))
	# on the right: the office door and window, and the board of what they do
	var ox := door_w / 2.0 + 2.2
	_box(_f, black, Vector3(ox, 1.1, z + 0.03), Vector3(1.1, 2.2, 0.05))
	_box(_f, 0x2c4a63, Vector3(ox, 1.45, z + 0.05), Vector3(0.8, 1.3, 0.02))
	_box(_f, black, Vector3(ox + 2.3, 2.0, z + 0.03), Vector3(2.0, 1.5, 0.05))
	_box(_f, 0x2c4a63, Vector3(ox + 2.3, 2.0, z + 0.05), Vector3(1.8, 1.3, 0.02))
	var bx := minf(right_ - 1.5, ox + 5.2)
	_box(_f, black, Vector3(bx, 2.2, z + 0.03), Vector3(1.5, 2.2, 0.05))
	for k in range(6):
		_box(_f, yellow, Vector3(bx - 0.52, 3.0 - k * 0.32, z + 0.06), Vector3(0.12, 0.12, 0.01))
		_box(_f, 0xe9e6dd, Vector3(bx + 0.12, 3.0 - k * 0.32, z + 0.06), Vector3(0.95 - (k % 3) * 0.14, 0.07, 0.01))

func _front_xandro(left: float, right_: float) -> void:
	var coal := 0x2b2d33
	var dark := 0x1c1d21
	var lime := 0x9be22d
	var hw := w / 2.0
	var z := 0.05
	var peak := tall + 2.4
	var mid := (right_ - left) / 2.0
	# sheet metal over the real wall either side of the bay; the gable over everything, its ribs running up and down
	_box(_f, coal, Vector3(-(left + hw) / 2.0, tall / 2.0, z - 0.02), Vector3(left - hw, tall, 0.07))
	if right_ > hw + 0.05:
		_box(_f, coal, Vector3((right_ + hw) / 2.0, tall / 2.0, z - 0.02), Vector3(right_ - hw, tall, 0.07))
	_gable(_f, coal, Vector3(-left, tall, z), Vector3(mid, peak, z), Vector3(right_, tall, z))
	var ribs := int((left + right_) / 0.5)
	for k in range(1, ribs):
		var x := -left + k * 0.5
		var top := tall + (peak - tall) * (1.0 - absf(x - mid) / ((left + right_) / 2.0))
		_box(_f, dark, Vector3(x, (3.9 + top) / 2.0, z + 0.015), Vector3(0.05, top - 3.9, 0.02))
	for side in [[-left, mid], [right_, mid]]:                    # the edge of the roof
		var run: float = absf(side[0] - side[1])
		var rake := Node3D.new()
		rake.position = Vector3((side[0] + side[1]) / 2.0, (tall + peak) / 2.0, z + 0.02)
		rake.rotation.z = (1.0 if side[0] < side[1] else -1.0) * atan2(peak - tall, run)
		_f.add_child(rake)
		_box(rake, 0x4a4d55, Vector3.ZERO, Vector3(Vector2(run, peak - tall).length() + 0.3, 0.22, 0.12))
	# the green stripe over the windows, all the way along as far as the doorway
	var shop_r := -door_w / 2.0 - 0.55                   # where the showroom ends and the doorway begins
	_box(_f, lime, Vector3((-left + shop_r) / 2.0, 3.72, z + 0.04), Vector3(shop_r + left, 0.26, 0.08))
	# the showroom: three big panes between chequered pillars, a low dark sill
	var mural_w := 2.2
	var glass_r := shop_r - mural_w - 0.5
	var panes := 3
	var pane_w := (glass_r + left - 0.5) / float(panes)
	_box(_f, dark, Vector3((-left + glass_r) / 2.0, 0.3, z + 0.03), Vector3(glass_r + left, 0.6, 0.06))
	for k in range(panes):
		var px := -left + 0.5 + pane_w * (k + 0.5)
		_box(_f, 0x263c4f, Vector3(px, 2.1, z + 0.03), Vector3(pane_w - 0.42, 3.0, 0.04))
		_box(_f, 0x47708c, Vector3(px - pane_w * 0.12, 2.9, z + 0.055), Vector3(pane_w * 0.5, 0.5, 0.01))
	for k in range(panes + 1):
		_chequered(Vector3(-left + 0.5 + pane_w * k, 0.0, z + 0.06), 0.42, 3.6)
	# by the door, the painted panel (the real one is a portrait; ours is just paint) and the way in for people
	var mx := glass_r + 0.35 + mural_w / 2.0
	_box(_f, 0x7d3fc4, Vector3(mx, 1.95, z + 0.03), Vector3(mural_w, 3.3, 0.05))
	_box(_f, 0xe86aa6, Vector3(mx - 0.3, 2.3, z + 0.06), Vector3(1.0, 1.3, 0.01))
	_box(_f, 0xf2c230, Vector3(mx + 0.45, 1.5, z + 0.06), Vector3(0.7, 0.9, 0.01))
	_box(_f, 0x3bb7c4, Vector3(mx, 3.1, z + 0.06), Vector3(1.6, 0.35, 0.01))
	_chequered(Vector3(shop_r - 0.1, 0.0, z + 0.06), 0.42, 3.6)
	# the workshop doorway: a red band over it
	_box(_f, 0xc0392b, Vector3(0, door_h + 0.5, z + 0.07), Vector3(door_w + 0.7, 0.7, 0.07))
	# the lettering: TALLERES in pale capitals on the left, the name big, green and askew over the middle
	_text(_f, "TALLERES", Vector3(-left + (left + mid) * 0.36, tall - 1.5, z + 0.07), 215, 0xd9dce2)
	var name_tag := _text(_f, "XANDRO", Vector3(mid + 2.0, tall + 0.25, z + 0.09), 560, lime)
	name_tag.rotation.z = 0.1
	name_tag.outline_size = 34
	name_tag.outline_modulate = Parts.col(0x5a8f12)

func _front_df(left: float, right_: float) -> void:
	var wall := 0xe9a968
	var stone := 0xd9cbb0
	var wood := 0x8a4a22
	var hw := w / 2.0
	var z := 0.05
	var floor_y := 4.5                                # where upstairs begins
	# the real walls either side of the bay get the same apricot render; a stone plinth along the bottom
	_box(_f, wall, Vector3(-(left + hw) / 2.0, tall / 2.0, z - 0.02), Vector3(left - hw, tall, 0.07))
	_box(_f, wall, Vector3((right_ + hw) / 2.0, tall / 2.0, z - 0.02), Vector3(right_ - hw, tall, 0.07))
	for part in [[-left, -door_w / 2.0 - 0.3], [door_w / 2.0 + 0.3, right_]]:
		_box(_f, stone, Vector3((part[0] + part[1]) / 2.0, 0.3, z + 0.02), Vector3(part[1] - part[0], 0.6, 0.05))
	_box(_f, 0xc98a4c, Vector3((right_ - left) / 2.0, floor_y, z + 0.06), Vector3(left + right_, 0.16, 0.16))      # the line of the floor above
	# the doorway of the bay: stone jambs and lintel, the sign over it
	for sx in [-1.0, 1.0]:
		_box(_f, stone, Vector3(sx * (door_w / 2.0 + 0.2), (door_h + 0.3) / 2.0, z + 0.03), Vector3(0.36, door_h + 0.3, 0.07))
	_box(_f, stone, Vector3(0, door_h + 0.48, z + 0.03), Vector3(door_w + 0.76, 0.3, 0.2))
	_sign(Vector3(0.0, door_h + 0.95, z + 0.24), 2.8)
	# a second doorway to the right, its shutter down (the lift is in there)
	var d2 := (door_w / 2.0 + 0.9 + right_ - 0.5) / 2.0
	var d2w := right_ - 0.5 - (door_w / 2.0 + 0.9)
	_box(_f, stone, Vector3(d2, (door_h + 0.3) / 2.0, z + 0.02), Vector3(d2w + 0.5, door_h + 0.3, 0.05))
	_box(_f, 0x8d949c, Vector3(d2, door_h / 2.0, z + 0.05), Vector3(d2w, door_h, 0.03))
	for k in range(1, int(door_h / 0.22)):
		_box(_f, 0x666c74, Vector3(d2, k * 0.22, z + 0.07), Vector3(d2w, 0.03, 0.01))
	_sign(Vector3(d2, door_h + 0.95, z + 0.09), minf(2.8, d2w))
	# a blue sign hung out over the pavement at the far end, as tyre people do
	_box(_f, 0x1f3fa8, Vector3(right_ - 0.3, floor_y + 0.1, z + 0.55), Vector3(0.08, 0.9, 1.0))
	_box(_f, 0xf4f1e8, Vector3(right_ - 0.3, floor_y + 0.15, z + 0.55), Vector3(0.1, 0.42, 0.42))
	# to the left of the bay: the glass office (windscreens) with its red sign...
	var ox := -hw - 2.4
	_box(_f, stone, Vector3(ox, 1.6, z + 0.02), Vector3(3.5, 3.2, 0.06))
	_box(_f, 0xf4f1e8, Vector3(ox, 1.45, z + 0.05), Vector3(3.0, 2.7, 0.04))
	_box(_f, 0x2c4a63, Vector3(ox - 0.75, 1.75, z + 0.08), Vector3(1.2, 1.9, 0.02))
	_box(_f, 0x2c4a63, Vector3(ox + 0.75, 1.75, z + 0.08), Vector3(1.2, 1.9, 0.02))
	_box(_f, 0xc0392b, Vector3(ox, 3.85, z + 0.07), Vector3(3.3, 0.8, 0.08))
	_text(_f, "df  LUNAS", Vector3(ox, 3.85, z + 0.12), 120, 0xf4f1e8)
	# ...and the way up to the house: a stone arch with a wooden door
	var ax := -left + 1.6
	_box(_f, stone, Vector3(ax, 1.3, z + 0.02), Vector3(2.3, 2.6, 0.08))
	var arch := Parts.part("cyl", stone, Vector3(ax, 2.6, z + 0.02), Vector3(1.15, 0.08, 1.15))
	arch.rotation.x = PI / 2.0
	_f.add_child(arch)
	_box(_f, 0x6a4a2c, Vector3(ax, 1.15, z + 0.07), Vector3(1.45, 2.3, 0.03))
	var leaf := Parts.part("cyl", 0x6a4a2c, Vector3(ax, 2.3, z + 0.055), Vector3(0.725, 0.03, 0.725))
	leaf.rotation.x = PI / 2.0
	_f.add_child(leaf)
	# upstairs: a pair of arched windows in stone over the arch, then balconies
	_box(_f, stone, Vector3(ax + 0.2, floor_y + 1.2, z + 0.03), Vector3(2.9, 1.9, 0.06))
	for sx in [-0.7, 0.7]:
		_box(_f, 0xf4f1e8, Vector3(ax + 0.2 + sx, floor_y + 1.2, z + 0.07), Vector3(0.9, 1.5, 0.03))
		_box(_f, 0x2c4a63, Vector3(ax + 0.2 + sx, floor_y + 1.0, z + 0.09), Vector3(0.7, 0.9, 0.02))
	var span := left + right_ - 5.4
	for k in range(4):
		var bx := -left + 5.0 + span * (k + 0.5) / 4.0
		_box(_f, 0xf4f1e8, Vector3(bx, floor_y + 1.15, z + 0.03), Vector3(1.3, 2.0, 0.05))            # the shutter box and frame
		_box(_f, 0x2c4a63, Vector3(bx, floor_y + 0.95, z + 0.06), Vector3(1.05, 1.5, 0.02))
		_box(_f, 0xe6e3da, Vector3(bx, floor_y + 1.92, z + 0.07), Vector3(1.15, 0.42, 0.03))
		if k % 2 == 1:                                                                               # every other one has a balcony
			_box(_f, 0x6f6b5c, Vector3(bx, floor_y + 0.12, z + 0.42), Vector3(2.0, 0.1, 0.75))
			_box(_f, 0x4d5148, Vector3(bx, floor_y + 1.1, z + 0.78), Vector3(2.0, 0.05, 0.05))
			for r in range(9):
				_box(_f, 0x4d5148, Vector3(bx - 0.96 + r * 0.24, floor_y + 0.62, z + 0.78), Vector3(0.03, 0.95, 0.03))
			for sx in [-1.0, 1.0]:
				_box(_f, 0x4d5148, Vector3(bx + sx * 0.98, floor_y + 0.62, z + 0.42), Vector3(0.03, 0.95, 0.72))
	# the eaves: boards on wooden rafters, well out over the street
	_box(_f, wood, Vector3((right_ - left) / 2.0, tall + 0.02, z + 0.5), Vector3(left + right_ + 0.4, 0.1, 1.1))
	for k in range(int((left + right_) / 0.9) + 1):
		_box(_f, 0x6e3a1a, Vector3(-left + 0.2 + k * 0.9, tall - 0.12, z + 0.5), Vector3(0.12, 0.2, 1.05))
	# and inside, on the back wall, the sign again
	_sign(Vector3(0, top - 0.75, -d + THICK + 0.03), 2.6)

## the board with the tyre and the letters (tools/make_df.py draws it)
func _sign(pos: Vector3, wide: float) -> void:
	var board := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(wide, wide * 400.0 / 1024.0)
	board.mesh = quad
	var m := StandardMaterial3D.new()
	m.albedo_texture = Parts.texture("res://assets/df_mecanica.png")
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.roughness = 1.0
	board.material_override = m
	board.position = pos
	_f.add_child(board)
	_box(_f, 0xc9ced4, pos + Vector3(0, 0, -0.03), Vector3(wide + 0.1, wide * 400.0 / 1024.0 + 0.1, 0.04))

## a pillar of black and white squares, the flag at the end of the race
func _chequered(foot: Vector3, wide: float, high: float) -> void:
	var half := wide / 2.0
	_box(_f, 0xf4f1e8, foot + Vector3(0, high / 2.0, 0), Vector3(wide, high, 0.05))
	var rows := int(high / half)
	for r in range(rows):
		_box(_f, 0x17171a, foot + Vector3((-0.25 if r % 2 == 0 else 0.25) * wide, (r + 0.5) * half, 0.03), Vector3(half, half, 0.012))

## concrete in front, as far as the road, so the doorway is not a step up from a pavement
func _forecourt(left: float, right_: float) -> void:
	if id == "df":                                    # a narrow street in town: just the dropped kerb
		return
	if id == "valdeacero":
		var tile := StandardMaterial3D.new()             # the chequered pavement of the Paseo del Cristo
		var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
		img.set_pixel(0, 0, Parts.col(0xe7dbc8)); img.set_pixel(1, 1, Parts.col(0xe7dbc8))
		img.set_pixel(1, 0, Parts.col(0xb7857c)); img.set_pixel(0, 1, Parts.col(0xb7857c))
		img.generate_mipmaps()
		tile.albedo_texture = ImageTexture.create_from_image(img)
		tile.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		tile.uv1_triplanar = true
		tile.uv1_world_triplanar = true
		tile.uv1_scale = Vector3.ONE * 1.2
		tile.roughness = 1.0
		for part in [[-left - 1.0, -door_w / 2.0], [door_w / 2.0, right_ + 1.0]]:
			_box(_f, 0xffffff, Vector3((part[0] + part[1]) / 2.0, -0.025, 2.0), Vector3(part[1] - part[0], 0.04, 4.0)).material_override = tile
		_box(_f, 0x9a9b98, Vector3(0, -0.02, 2.6), Vector3(door_w, 0.04, 2.8))
		return
	_box(_f, 0xa3a39e, Vector3((right_ - left) / 2.0, -0.022, 5.5), Vector3(left + right_ + 2.0, 0.04, 11.0))
	for k in range(4 if id == "errejota" else 6):     # parking bays painted on it, to the left of the doorway
		_box(_f, 0xf4f1e8, Vector3(-left + 1.2 + k * 2.6, 0.002, 3.4), Vector3(0.1, 0.008, 4.6))

# ---------------- in use ----------------
## is this spot inside the bay, far enough in for the shutter to come down behind (or in front of) a car this long?
func holds(p: Vector2, car_len := 4.0) -> bool:
	var rel := p - mouth
	var across: float = rel.dot(right)
	var inn: float = -rel.dot(out)
	return absf(across) < w / 2.0 - 0.6 and inn > car_len / 2.0 + 0.5 and inn < d - 0.6

## is something standing in the doorway? (so the shutter does not come down on it)
func in_doorway(p: Vector2, car_len := 4.0) -> bool:
	var rel := p - mouth
	return absf(rel.dot(right)) < door_w / 2.0 + 1.0 and absf(rel.dot(out)) < car_len / 2.0 + 0.4

## where to watch from while the shutter is down
func view() -> Array:
	var from := mouth + out * (6.0 + door_w * 1.8) + right * 3.2
	return [MapData.at(from, 3.1), MapData.at(mouth, door_h * 0.62)]

func tick(dt: float, blocked: bool) -> void:
	var goal := 1.0 if (want_open and not busy) or blocked else 0.0
	if open != goal:
		open = move_toward(open, goal, dt * ROLL)
		_roller.scale.y = 1.0 - open * 0.94
		_gate.disabled = open > 0.25
	if busy and open <= 0.0:                      # the welder at work
		_spark -= dt
		if _spark <= 0.0:
			_spark = randf_range(0.05, 0.22)
			_lamp.light_energy = randf_range(0.5, 2.6)
			_lamp.light_color = Color(0.75, 0.86, 1.0)
	elif _lamp.light_energy != GLOW:
		_lamp.light_energy = GLOW
		_lamp.light_color = Color(0.95, 0.97, 1.0)
