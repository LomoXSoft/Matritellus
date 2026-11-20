extends RefCounted
## Shared primitive meshes and flat-colour materials for the low-poly look.

static var _mats := {}
static var _meshes := {}

static func col(hex: int) -> Color:
	return Color(((hex >> 16) & 255) / 255.0, ((hex >> 8) & 255) / 255.0, (hex & 255) / 255.0)

static func mat(hex: int) -> StandardMaterial3D:
	if not _mats.has(hex):
		var m := StandardMaterial3D.new()
		m.albedo_color = col(hex)
		m.roughness = 1.0
		m.rim_enabled = true            # a soft light edge, for the rounded toy-like look
		m.rim = 0.35
		m.rim_tint = 0.6
		_mats[hex] = m
	return _mats[hex]

static func mesh(kind: String) -> Mesh:
	if _meshes.has(kind):
		return _meshes[kind]
	var m: Mesh
	match kind:
		"body":
			var c := CylinderMesh.new(); c.top_radius = 0.3; c.bottom_radius = 0.44; c.height = 0.75; c.radial_segments = 12; c.rings = 1; m = c
		"head":
			var s := SphereMesh.new(); s.radius = 0.5; s.height = 1.0; s.radial_segments = 18; s.rings = 10; m = s
		"ball":
			var s2 := SphereMesh.new(); s2.radius = 1.0; s2.height = 2.0; s2.radial_segments = 12; s2.rings = 6; m = s2
		"dome":
			var hs := SphereMesh.new(); hs.radius = 1.0; hs.height = 1.0; hs.is_hemisphere = true; hs.radial_segments = 20; hs.rings = 8; m = hs
		"cone":
			var c2 := CylinderMesh.new(); c2.top_radius = 0.0; c2.bottom_radius = 1.0; c2.height = 1.0; c2.radial_segments = 10; c2.rings = 1; m = c2
		"ring":         # a hoop lying flat (earrings, thick glasses, neckerchiefs)
			var t := TorusMesh.new(); t.inner_radius = 0.68; t.outer_radius = 1.0; t.rings = 18; t.ring_segments = 6; m = t
		"ring_thin":    # the same in wire (thin glasses, chains, steering wheels)
			var t2 := TorusMesh.new(); t2.inner_radius = 0.87; t2.outer_radius = 1.0; t2.rings = 18; t2.ring_segments = 5; m = t2
		"cyl":
			var c3 := CylinderMesh.new(); c3.top_radius = 1.0; c3.bottom_radius = 1.0; c3.height = 1.0; c3.radial_segments = 14; c3.rings = 1; m = c3
		_:
			m = BoxMesh.new()
	_meshes[kind] = m
	return m

## one coloured primitive: kind, colour, position, scale
static func part(kind: String, hex: int, pos: Vector3, scl: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh(kind)
	mi.material_override = mat(hex)
	mi.position = pos
	mi.scale = scl
	return mi

## a texture from the project: the imported resource if there is one, otherwise read straight from the file
static func texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var img := Image.load_from_file(path)
	return ImageTexture.create_from_image(img) if img != null else null

## Small things are not drawn from far away, and the smallest cast no shadow. The town is built of thousands of
## little boxes -- window bars, door knobs, flower pots, the buttons on a shirt -- and each is a draw call of its own,
## twice over with the sun's shadow: from across a square nobody can see them, but the graphics card was being sent
## every one. `scale`: how much bigger the node's parents make it (the walk keeps count on the way down).
## Returns how many pieces it set a limit on.
## (`draw` and `fx` are the graphics options: how much further or nearer than that, 0 for no limit; how many of the
## particles of rain and smoke are drawn, 0 for none. retune() puts what is already built to whatever they are now.)
static var draw := 1.0
static var fx := 1.0
## (and `detail`, the automatic LOD option: the small pieces -- the ones drawn no further than 110 m -- are drawn
## this much as far, the bigger ones as before)
const LOD_NEAR := 0.7
static var detail := 1.0

static func _range(n: GeometryInstance3D, far: float) -> void:
	n.set_meta("far0", far)
	var k: float = detail if far <= 110.0 else 1.0
	n.visibility_range_end = far * draw * k if draw > 0.0 else 0.0
	n.visibility_range_end_margin = 4.0

static func _puffs(p: CPUParticles3D) -> void:
	if not p.has_meta("amount0"):
		p.set_meta("amount0", p.amount)
		p.set_meta("mesh0", p.mesh)
	var want := maxi(1, roundi(int(p.get_meta("amount0")) * fx))
	if p.amount != want:
		p.amount = want
	p.mesh = p.get_meta("mesh0") if fx > 0.0 else null

## the graphics options have changed: everything already built is put to them
static func retune(root: Node) -> void:
	if root is GeometryInstance3D and root.has_meta("far0"):
		_range(root, float(root.get_meta("far0")))
	elif root is CPUParticles3D:
		_puffs(root)
	for c in root.get_children():
		retune(c)

static func thin(root: Node, scale := Vector3.ONE) -> int:
	var done := 0
	var here := scale
	if root is Node3D:
		here = scale * (root as Node3D).scale.abs()
	if root is VehicleWheel3D:
		return done
	if root is CPUParticles3D:
		_puffs(root)
	if root is Label3D:
		if not root.has_meta("far0"):
			_range(root, 90.0)
		done += 1
	elif root is MeshInstance3D and (root as MeshInstance3D).mesh != null and ((root as MeshInstance3D).visibility_range_end == 0.0 or root.has_meta("far0")):
		var mi := root as MeshInstance3D
		var size: Vector3 = mi.mesh.get_aabb().size * here
		var longest := maxf(size.x, maxf(size.y, size.z))
		var far := 0.0
		if longest < 0.3:
			far = 32.0
		elif longest < 0.7:
			far = 60.0
		elif longest < 1.6:
			far = 110.0
		elif longest < 4.0:
			far = 220.0
		if far > 0.0:
			_range(mi, far)
			done += 1
		if longest < 0.7:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in root.get_children():
		done += thin(c, here)
	return done

