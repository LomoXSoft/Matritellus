extends Node3D
## Your peña's graffiti while you make your character (the user, 16 November 2026: "El grafiti debe salir también durante
## el selector de personaje. Quizás en un cuadro en un caballete al lado del personaje"): an easel standing by you in the
## street, its canvas turned to the camera, the logo of the peña you have chosen painted on it. It goes as soon as the
## creator is done.
##
## The easel is "easel" by yentc atmcdg (CC-BY 3.0, Poly Pizza: assets/creador/CREDITOS.txt); the logo is laid on the
## front of its canvas. Its canvas faces a little to one side and leans back: turned straight here (TURN), the logo
## leaning with it (LEAN). Measured in the model's own units with Blender (the front face's middle and its normal).

const Creator = preload("res://scripts/creator.gd")
const Parts = preload("res://scripts/parts.gd")
const MODEL := "res://assets/creador/caballete.glb"
const TALL := 2.25                          # how tall the easel stands (metres)
const MODEL_TALL := 6.4                     # ...and in the model's own units, from the feet (-3.573) to the top
const FEET := -3.573
const TURN := 0.288                         # (its canvas faces 16.5 degrees off straight ahead)
const LEAN := 0.158                         # (and leans back 9 degrees)
const CANVAS_MID := Vector3(-0.016, 1.212, 0.316)      # the middle of the canvas's front, in the model's own frame (y up)
const CANVAS_W := 1.95                      # how much of the canvas the logo may take, across and up (model units)
const CANVAS_H := 2.9

var pena := -1
var _logo: MeshInstance3D
var _tex: Array = []
var _built := false

func _build() -> void:
	_built = true
	for id in Creator.PENA_IDS:
		_tex.append(load("res://assets/penas/%s.png" % id))
	var holder := Node3D.new()                 # the model's own frame: turned so the canvas faces +z, feet on the ground
	holder.scale = Vector3.ONE * (TALL / MODEL_TALL)
	holder.position.y = 0.0
	add_child(holder)
	var turned := Node3D.new()
	turned.rotation.y = TURN
	turned.position.y = -FEET * (1.0)
	holder.add_child(turned)
	if ResourceLoader.exists(MODEL):
		var model: Node3D = (load(MODEL) as PackedScene).instantiate()
		turned.add_child(model)
		_matt(model)
	var q := QuadMesh.new()
	q.size = Vector2(CANVAS_W, CANVAS_W)
	_logo = MeshInstance3D.new()
	_logo.mesh = q
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 1.0
	m.cull_mode = BaseMaterial3D.CULL_BACK
	_logo.material_override = m
	_logo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# on the canvas's front, a hair in front of it, leaning back with it (in the frame already turned straight)
	var front := Basis(Vector3.UP, TURN) * CANVAS_MID
	_logo.position = Vector3(front.x, front.y - FEET, front.z) + Vector3(0.0, sin(LEAN), cos(LEAN)) * 0.04
	_logo.rotation.x = -LEAN
	holder.add_child(_logo)

## the model's own colours, matt, as everything in the game is
func _matt(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for si in range(mi.mesh.get_surface_count()):
			var src := mi.mesh.surface_get_material(si)
			var c: Color = (src as BaseMaterial3D).albedo_color if src is BaseMaterial3D else Color(0.5, 0.4, 0.3)
			var hex := (int(c.r * 255.0) << 16) | (int(c.g * 255.0) << 8) | int(c.b * 255.0)
			if c.r > 0.6 and c.g > 0.6 and c.b > 0.6:
				hex = 0xf7f5f0                      # (the canvas: white)
			mi.set_surface_override_material(si, Parts.mat(hex))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for c in n.get_children():
		_matt(c)

## the logo of this peña on the canvas
func set_pena(i: int) -> void:
	if not _built:
		_build()
	i = clampi(i, 0, Creator.PENA_IDS.size() - 1)
	if i == pena:
		return
	pena = i
	var tex: Texture2D = _tex[i]
	(_logo.material_override as StandardMaterial3D).albedo_texture = tex
	var k := minf(CANVAS_W / float(tex.get_width()), CANVAS_H / float(tex.get_height()))
	(_logo.mesh as QuadMesh).size = Vector2(tex.get_width() * k, tex.get_height() * k) * 0.97

## stands at `at` (on the ground), its canvas turned to `look_from` (the camera)
func place(at: Vector3, look_from: Vector3) -> void:
	if not _built:
		_build()
	if global_position.distance_to(at) > 0.001:
		global_position = at
	var to := Vector2(look_from.x - at.x, look_from.z - at.z)
	var h := atan2(to.x, to.y)
	if absf(angle_difference(rotation.y, h)) > 0.001:
		rotation.y = h
