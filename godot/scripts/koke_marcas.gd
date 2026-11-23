extends RefCounted
## Koke el Kokas's yellow Z15 (the user, 23 November 2026: "te subirás al Z15 amarilla con pintura de llamas y nitro
## (habrá que modelarlo)"): the Z15's own bodywork (Modelos.SK "kokas", the same model as "z15") in yellow, and on it
##   - hot-rod flames licking back from the nose along each side and over the bonnet: decals, as the Tricornios'
##     badges are (tricornio_marcas.gd), so they follow the van's curves; on a render layer of their own, LAYER;
##   - a TAXI sign on the roof, black with yellow letters and "KOKAS" under them, lit;
##   - a wing on the back of the roof, on two posts;
##   - the nitro itself is the car's turbo (car.gd SPECS "kokas"): flames out of the back and the sport dial.
## Its pictures are drawn by tools/koke/pinturas.py (assets/koke/). Called by Modelos.make_from for "kokas".

const Parts = preload("res://scripts/parts.gd")
const DIR := "res://assets/koke/"
const LAYER := 14                                               # the render layer of the Kokas's car's bodywork

static func _mark(tex: Texture2D, at: Vector3, into: Vector3, up: Vector3, wide: float, tall: float, deep: float) -> Decal:
	var d := Decal.new()
	d.texture_albedo = tex
	d.size = Vector3(wide, deep, tall)
	var y := -into.normalized()                     # (a decal throws its picture along its own -y; the picture's top is its -z)
	var z := -up.normalized()
	d.transform = Transform3D(Basis(y.cross(z), y, z), at)
	d.cull_mask = 1 << (LAYER - 1)
	d.upper_fade = 0.001
	d.lower_fade = 0.001
	d.normal_fade = 0.3
	d.distance_fade_enabled = true
	d.distance_fade_begin = 60.0
	d.distance_fade_length = 15.0
	return d

## a flat picture, both faces, `wide` x `tall`, facing +z
static func _plate(tex: Texture2D, wide: float, tall: float) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(wide, tall)
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.emission_enabled = true                       # (lit from inside, as taxi signs are)
	m.emission_texture = tex
	m.emission_energy_multiplier = 0.6
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	return mi

## `root` holds the car's meshes (its nose towards +z, its wheels on y = 0); `size` is its width, height and length
static func dress(root: Node3D, size: Vector3, roof: Vector3, back_roof: Vector3) -> void:
	for c in root.get_children():
		if c is MeshInstance3D and not String(c.name).to_lower().contains("wheel"):
			(c as MeshInstance3D).layers |= 1 << (LAYER - 1)
	var side_tex: Texture2D = Parts.texture(DIR + "llamas.png")
	var side_back: Texture2D = Parts.texture(DIR + "llamas_i.png")
	var hood: Texture2D = Parts.texture(DIR + "capo.png")
	if side_tex != null:
		var long: float = size.z * 0.62
		for sx in [1.0, -1.0]:
			var x: float = sx * (size.x / 2.0 - 0.15)
			# (the picture's left is the nose on the right side; on the left side the mirrored one, so both lick backwards)
			root.add_child(_mark(side_tex if sx > 0.0 else side_back, Vector3(x, size.y * 0.36, size.z * 0.5 - long / 2.0 - 0.05),
				Vector3(-sx, 0, 0), Vector3.UP, long, size.y * 0.36, 0.5))
	if hood != null:
		root.add_child(_mark(hood, Vector3(0.0, size.y * 0.5, size.z * 0.36), Vector3.DOWN, Vector3(0, 0, -1), size.x * 0.8, size.z * 0.26, size.y * 0.5))
	# the TAXI sign on the roof, across it
	var sign_tex: Texture2D = Parts.texture(DIR + "taxi.png")
	var at := Vector3(0.0, roof.y + 0.16, roof.z)
	root.add_child(Parts.part("box", 0x161618, at, Vector3(0.92, 0.28, 0.2)))
	if sign_tex != null:
		for sz in [1.0, -1.0]:
			var face := _plate(sign_tex, 0.88, 0.275)
			face.position = at + Vector3(0, 0, sz * 0.105)
			face.rotation.y = 0.0 if sz > 0.0 else PI
			root.add_child(face)
	# the wing on the back of the roof
	var wy: float = back_roof.y + 0.2
	var wz: float = back_roof.z + 0.05
	var wing := Parts.part("box", 0x161618, Vector3(0, wy, wz), Vector3(size.x * 0.92, 0.05, 0.36))
	wing.rotation.x = -0.12
	root.add_child(wing)
	for sx in [-1.0, 1.0]:
		root.add_child(Parts.part("box", 0x161618, Vector3(sx * size.x * 0.32, wy - 0.11, wz), Vector3(0.05, 0.2, 0.14)))
		root.add_child(Parts.part("box", 0xd42020, Vector3(sx * size.x * 0.46, wy + 0.05, wz), Vector3(0.03, 0.16, 0.42)))
