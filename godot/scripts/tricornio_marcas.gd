extends RefCounted
## The Tricornios' marks on their cars (the user, 16 November 2026: "invertir el logo que has hecho de los tricornios en
## la fachada (cambiar negro por dorado y viceversa) y usarlo como su logo. Así lo podríamos poner en el frontal y en los
## laterales del coche, además de una franja con la bandera de España, como los oficiales"): their badge -- the gold
## tricorn hat on black of their barracks' plate (cuartel.gd; painted by tools/cuartel/logo.py) -- on the bonnet and on
## each front door, and the flag's stripe on each side behind it.
##
## They are decals: pictures thrown on to whatever bodywork is there, so they follow the bonnet's slope and the doors'
## curve on any of the car's models. So that they fall on nothing else (a neighbour standing by the door, another
## car), the bodywork of a Tricornios' car is also put on a render layer of its own, and the decals look at that one
## only. Called by Modelos (make, make_from) for every "tricornio": the one parked at the barracks, those of a chase, a
## stolen one. Not for Los Pitufos, who borrow the Tricornios' lights.
##
## Three things Texturas pointed out, and how they are met here:
## - Modelos.cloud() remembers a kind's shape the first time it is asked, roof bar and all: this does not ask it. It
##   reads the bodywork itself, and only below four fifths of the car's height, so no light bar counts as bonnet.
## - The glass of these models is a surface of the bodywork's own mesh (it cannot be left off the layer): the marks'
##   boxes are kept clear of it instead -- the door's badge ends under the window line, the bonnet's short of the
##   windscreen. Look at it again (tools/cuartel/vistas.py coche) if the model or these measures change.
## - Two of their cars side by side share the layer: each mark's box reaches only 8 cm out of its own car's side and
##   17 cm over its bonnet, so it falls on the other only if they are touching.

const LOGO := "res://assets/tricornios/logo.png"
const FLAG := "res://assets/tricornios/bandera.png"
const FLAG_BACK := "res://assets/tricornios/bandera_i.png"      # the same, leaning the other way (for the car's other side)
const LAYER := 15                                               # the render layer of a Tricornios' car's bodywork

## a picture thrown along `into` (in the car's own frame) over a box `wide` x `tall` and `deep` through, its middle at
## `at`; `up`: where the top of the picture points
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
	d.normal_fade = 0.35                            # (not on what is edge-on to it: the door's sill, the wheel arch)
	d.distance_fade_enabled = true
	d.distance_fade_begin = 55.0
	d.distance_fade_length = 15.0
	return d

## Puts the marks on a car just built: `root` holds its meshes (its nose towards +z, its wheels on y = 0), `size` is
## its width, height and length.
static func dress(root: Node3D, _kind: String, size: Vector3) -> void:
	if not ResourceLoader.exists(LOGO):
		return
	var logo: Texture2D = load(LOGO)
	var top := 0.0                                  # how high the bonnet is, a fifth of the car's length back from its nose
	var zb: float = size.z * 0.3
	for c in root.get_children():
		if not (c is MeshInstance3D) or String(c.name).to_lower().contains("wheel") or String(c.name).begins_with("luz"):
			continue                                # (not its wheels, whatever the model calls them, nor its lights: a mark must not wrap round a tyre)
		var mi: MeshInstance3D = c
		mi.layers |= 1 << (LAYER - 1)
		if mi.mesh == null:
			continue
		for s in range(mi.mesh.get_surface_count()):
			var arrays: Array = mi.mesh.surface_get_arrays(s)
			if arrays.is_empty() or arrays[Mesh.ARRAY_VERTEX] == null:
				continue
			for p: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
				var q: Vector3 = mi.transform * p
				if absf(q.x) < size.x * 0.3 and absf(q.z - zb) < size.z * 0.06 and q.y > top and q.y < size.y * 0.8:
					top = q.y
	if top <= 0.0:
		top = size.y * 0.55
	var badge: float = minf(0.62, size.x * 0.36)
	root.add_child(_mark(logo, Vector3(0.0, top - 0.08, zb), Vector3.DOWN, Vector3(0, 0, -1), badge, badge, 0.5))      # on the bonnet: its top towards the windscreen
	var side: float = minf(0.46, size.y * 0.27)
	for sx in [1.0, -1.0]:
		var into := Vector3(-sx, 0, 0)
		var x: float = sx * (size.x / 2.0 - 0.12)
		root.add_child(_mark(logo, Vector3(x, size.y * 0.44, size.z * 0.07), into, Vector3.UP, side, side, 0.4))               # on the front door
		var stripe: String = FLAG if sx < 0.0 else FLAG_BACK                                                                    # (its top leans towards the nose on both sides)
		if ResourceLoader.exists(stripe):
			root.add_child(_mark(load(stripe), Vector3(x, size.y * 0.43, -size.z * 0.17), into, Vector3.UP, 0.56, 0.21, 0.4))     # ...and the flag's stripe behind it
