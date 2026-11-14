extends RefCounted
## Bought-in bodywork for the cars: Kenney's Car Kit (CC0: assets/vehiculos/LICENCIA_Kenney.txt), each model
## stretched to the size of the car it stands for and repainted in that car's own colours.
##
## The kit's models all share one palette picture (Textures/colormap.png): sixteen columns of 32 px by four rows of
## 128 px, each a swatch that shades from light at the top to dark at the bottom. A model's paint is one of those
## swatches, so a car is repainted by handing it a copy of the picture with that swatch filled in its own colour.

const Parts = preload("res://scripts/parts.gd")
const DIR := "res://assets/vehiculos/"
const OWN := -1                 # "this car's own paint"

## which model stands for which car. swap: [column, row, colour] on the bodywork, wheels: the same on the wheels;
## hide: parts left out; tall: how much taller or lower than the model's own proportions; seat: [unused, how far
## forward of the middle the front seats are (of the length), how high the cab roof is (of the height, if not the top)].
const MODELS := {
	"panda": {"glb": "hatchback-sports", "swap": [[7, 1, OWN]], "seat": [0.6, 0.0]},
	"pitufo": {"glb": "police", "swap": [[7, 2, OWN]], "seat": [0.56, -0.03]},
	"z15": {"glb": "delivery", "swap": [[7, 1, OWN]], "tall": 0.78, "seat": [0.52, 0.2, 0.69]},
	"tractor": {"glb": "tractor", "swap": [[9, 1, OWN]], "wheels": [[11, 2, 0xe8dfc0]], "tall": 1.12, "seat": [0.62, -0.14], "mid": true},
	"yondir": {"glb": "tractor-shovel", "swap": [[7, 1, OWN]], "wheels": [[9, 1, 0xf2c81e]], "hide": ["shovel"], "tall": 1.22, "seat": [0.62, -0.14], "mid": true},
	"tunero": {"glb": "sedan-sports", "swap": [[13, 1, OWN]], "tall": 0.9, "seat": [0.56, -0.04]},
	"edison": {"glb": "suv-luxury", "swap": [[9, 1, OWN]], "tall": 0.92, "seat": [0.58, 0.02]},
	"julietta": {"glb": "sedan", "swap": [[13, 1, OWN]], "tall": 0.82, "seat": [0.56, -0.03]},
	"grua": {"glb": "truck-flat", "swap": [[13, 2, OWN]], "seat": [0.56, 0.08]},
	"tricornio": {"glb": "suv", "swap": [[7, 1, 0x1f6b3a], [7, 2, 0xf4f4f0]], "seat": [0.6, 0.02]},
}

## A second set, closer to the cars the game's own are winks at: single models from Poly Pizza, each by its own
## author (who they are and under what licence: assets/vehiculos/pp/CREDITOS.txt). They are not of a piece like the
## kit: some are painted by a texture (hue: [[the colour to look for, what to put instead]]), some by plain
## materials (mats: {material name: colour}); glass: the materials that are windows; grey_glass: the windows are
## the greys of the texture; turn: how far round its nose is from +z.
const CLOSER := {
	"panda": {"glb": "pp/panda", "hue": [[0xc01824, OWN]], "grey_glass": true, "seat": [0, -0.03]},
	"pitufo": {"glb": "pp/panda", "hue": [[0xc01824, OWN]], "grey_glass": true, "seat": [0, -0.03]},
	"z15": {"glb": "pp/z15_alt", "mats": {"07___Default": OWN}, "glass": ["02___Default"], "seat": [0, 0.12], "tall": 0.9},
	"tractor": {"glb": "pp/hebro", "hue": [[0xc00000, OWN], [0xc09000, 0xe8dfc0]], "mid": true, "seat": [0, -0.2, 1.1]},
	"tunero": {"glb": "pp/tunero", "mats": {"mat8": OWN}, "turn": PI},
	"edison": {"glb": "pp/edison", "mats": {"White": OWN}, "glass": ["Windows"], "seat": [0, 0.0]},
	"julietta": {"glb": "pp/julietta_alt", "hue": [[0xc03c54, OWN]], "seat": [0, -0.15, 0.96]},
	"grua": {"glb": "pp/grua", "mats": {"M_0042_Sienna": OWN}, "glass": ["Lisanne_Bracelet"], "turn": PI, "seat": [0, 0.08]},
	"tricornio": {"glb": "pp/tricornio", "mats": {"Color_I07": 0x1f6b3a}, "glass": ["Color_M05", "_Color_M05_1"], "turn": -PI / 2.0},
}

## A third set, the closest of all to the real cars: models from Sketchfab, downloaded with the user's account on
## 12 November 2026 (authors and licences, all CC Attribution: assets/vehiculos/sk/CREDITOS.txt), and cleaned with
## Blender by tools/blender/limpiar.py from the originals in tools/descargas/sketchfab/: no badges, lettering or
## emblems of a real make, the four wheels objects of their own (wheel_fl...), one body, the heavy ones lightened,
## and the Tunero with the kit of a tuned car. These are the cars of the game (car.gd). More keys (rack: where the oil
## bottles ride -- how far forward of the middle, of the length, and how high, of the height):
## hide_mats: parts left out by their material (a ground plane, official emblems); glass_near: the windows are the
## parts of the texture of about that colour; pale: the paint to go over is the white of the texture.
const SK := {
	"panda": {"glb": "sk/panda", "rack": [-0.06, 1.0], "mats": {"Carpaint": OWN}, "glass": ["Window"], "hide_mats": ["Ground"], "seat": [0, -0.03], "rider": 0.56},
	"pitufo": {"glb": "sk/panda", "rack": [-0.3, 1.0], "mats": {"Carpaint": OWN}, "glass": ["Window"], "hide_mats": ["Ground"], "seat": [0, -0.03, 0.95], "rider": 0.56},
	"z15": {"glb": "sk/z15", "rack": [-0.2, 1.0], "mats": {"M_0136": OWN, "Charcoal": OWN}, "seat": [0, 0.05, 0.8], "rider": 0.62, "hull": true},      # (a cap's peak stayed in front of the windscreen)
	"tractor": {"glb": "sk/hebro", "rack": [0.24, 0.6], "hue": [[0xc02020, OWN]], "mid": true, "seat": [0, -0.2, 0.9], "rider": 0.85, "open": true},
	"yondir": {"glb": "sk/yondir", "rack": [-0.12, 0.93], "mats": {"Part23Mtl": OWN, "Part42Mtl": 0xf2c81e}, "mid": true, "seat": [0, -0.12, 0.88], "rider": 0.72},
	"tunero": {"glb": "sk/tunero", "rack": [-0.02, 1.0], "mats": {"Carpaint": OWN}, "glass": ["Glass_Amber"], "tint": true, "seat": [0, -0.02, 0.92, 0.14], "rider": 0.52},
	"edison": {"glb": "sk/edison", "rack": [-0.06, 1.0], "hue": [[0xf0f0f0, OWN]], "pale": true, "seat": [0, 0.0, 0.86, 0.19], "rider": 0.56},      # (the head well under the roof. Its windows stay the black of the texture: cut out as tinted glass they looked horrible, the user, 14 Nov 2026 -- glass_near 0x000000, glass_tol 0.25, glass_above 0.56, tint 0.5 did it)
	"julietta": {"glb": "sk/julietta", "rack": [-0.37, 0.62], "mats": {"AluShiny": OWN}, "hide_mats": ["green"], "seat": [0, -0.115, 1.13], "rider": 0.57, "open": true},     # (sitting up: head and shoulders over the seat's back, or from the camera behind you could not see who drove it: the user, 14 Nov 2026)
	"grua": {"glb": "sk/grua", "rack": [-0.27, 0.48], "hue": [[0xe4b430, OWN]], "glass_near": 0x78849c, "seat": [0, 0.3, 0.76], "rider": 0.8},
	"tricornio": {"glb": "sk/tricornio", "rack": [-0.14, 0.93], "hide_mats": ["pEGATINAS"], "glass_near": 0x0c4884, "seat": [0, 0.0, 0.88], "rider": 0.56},
}

## paints over one colour of a texture (and a second, if asked) keeping its light and shade
const HUE_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D tex : source_color;
uniform vec3 from0 : source_color;
uniform vec3 to0 : source_color;
uniform vec3 from1 : source_color;
uniform vec3 to1 : source_color;
uniform float two = 0.0;
uniform float pale = 0.0;
const vec3 LUM = vec3(0.299, 0.587, 0.114);
float like(vec3 c, vec3 f) {
	vec3 cc = c - dot(c, LUM);
	vec3 cf = f - dot(f, LUM);
	float mc = length(cc);
	return mc > 0.03 ? dot(cc, cf) / (mc * max(length(cf), 0.001)) : 0.0;
}
void fragment() {
	vec3 c = texture(tex, UV).rgb;
	vec3 o = c;
	if (pale > 0.5) {
		if (length(c - dot(c, LUM)) < 0.05 && dot(c, LUM) > 0.5) {
			o = to0 * clamp(dot(c, LUM) / 0.88, 0.5, 1.15);
		}
	} else if (like(c, from0) > 0.92) {
		o = to0 * clamp(dot(c, LUM) / max(dot(from0, LUM), 0.01), 0.25, 1.3);
	} else if (two > 0.5 && like(c, from1) > 0.92) {
		o = to1 * clamp(dot(c, LUM) / max(dot(from1, LUM), 0.01), 0.25, 1.3);
	}
	ALBEDO = o;
	ROUGHNESS = 0.8;
}
"""

static var _hue_shader: Shader
static var _clouds: Dictionary = {}
static var _lamps: Dictionary = {}
static var _cuts: Dictionary = {}
static var _images: Dictionary = {}
static var _base: Image
static var _mats: Dictionary = {}
static var _glazed: Dictionary = {}     # a kit mesh -> [the same with its windows as surfaces of their own, which ones]
static var _glass: StandardMaterial3D
static var _dark_glass: StandardMaterial3D

static func has(kind: String) -> bool:
	return MODELS.has(kind)

## the palette with these swatches repainted, as a material
static func _mat(from: StandardMaterial3D, swaps: Array, paint: int) -> StandardMaterial3D:
	var key := "%s|%x" % [str(swaps), paint]
	if _mats.has(key):
		return _mats[key]
	if _base == null:
		_base = from.albedo_texture.get_image()
		if _base.is_compressed():
			_base.decompress()
		_base.convert(Image.FORMAT_RGBA8)
	var img: Image = _base.duplicate()
	for s in swaps:
		var hex: int = paint if s[2] == OWN else s[2]
		var c := Color8((hex >> 16) & 0xff, (hex >> 8) & 0xff, hex & 0xff)
		var x0: int = s[0] * 32
		var y0: int = s[1] * 128
		for x in range(x0, x0 + 32):
			var top: float = maxf(0.05, _base.get_pixel(x, y0).get_luminance())
			for y in range(y0, y0 + 128):
				# as much darker down the swatch as the kit's own paint gets (a little less on dark paint)
				var f: float = clampf(_base.get_pixel(x, y).get_luminance() / top, 0.0, 1.15)
				f = lerpf(1.0, f, 0.85)
				img.set_pixel(x, y, Color(c.r * f, c.g * f, c.b * f, 1.0))
	var m: StandardMaterial3D = from.duplicate()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED          # the shell is seen from inside too, through the glass
	_mats[key] = m
	return m

## The kit paints its windows on (the swatch of column 1, bottom row). Here they are cut out as surfaces of their
## own, to be given real glass: you see who is driving.
static func _glaze(mesh: Mesh) -> Array:
	if _glazed.has(mesh):
		return _glazed[mesh]
	var out := ArrayMesh.new()
	var panes: Array = []
	for s in range(mesh.get_surface_count()):
		var a: Array = mesh.surface_get_arrays(s)
		var uv: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
		var idx := PackedInt32Array()
		if a[Mesh.ARRAY_INDEX] != null:
			idx = a[Mesh.ARRAY_INDEX]
		else:
			for k in range((a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()):
				idx.append(k)
		var solid := PackedInt32Array()
		var pane := PackedInt32Array()
		for t in range(0, idx.size() - 2, 3):
			var c: Vector2 = (uv[idx[t]] + uv[idx[t + 1]] + uv[idx[t + 2]]) / 3.0
			var window: bool = int(fposmod(c.y, 1.0) * 4.0) == 3 and int(fposmod(c.x, 1.0) * 16.0) == 1
			for k in range(3):
				if window:
					pane.append(idx[t + k])
				else:
					solid.append(idx[t + k])
		if solid.size() > 0:
			a[Mesh.ARRAY_INDEX] = solid
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
			out.surface_set_material(out.get_surface_count() - 1, mesh.surface_get_material(s))
		if pane.size() > 0:
			a[Mesh.ARRAY_INDEX] = pane
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
			panes.append(out.get_surface_count() - 1)
	_glazed[mesh] = [out, panes]
	return _glazed[mesh]

static func _gather(n: Node, xf: Transform3D, out: Array, hide: Array) -> void:
	if n.name in hide:
		return
	var here := xf
	if n is Node3D:
		here = xf * (n as Node3D).transform
	if n is MeshInstance3D:
		out.append([n, here])
	for c in n.get_children():
		_gather(c, here, out, hide)

## The car `kind` (with car.gd's own description of it, `spec`) in this paint: a Node3D standing on y = 0, its nose
## to +z. meta "wheels": the four wheels (turn them about their own x); meta "size": what it measures.
static func make(kind: String, spec: Dictionary, paint: int) -> Node3D:
	var m: Dictionary = MODELS[kind]
	var src: Node = (load(DIR + m["glb"] + ".glb") as PackedScene).instantiate()
	var found: Array = []
	_gather(src, Transform3D.IDENTITY, found, m.get("hide", []))
	var box := AABB()
	var first := true
	for f in found:
		var b: AABB = (f[1] as Transform3D) * (f[0] as MeshInstance3D).mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	var sx: float = float(spec["wid"]) / box.size.x
	var sz: float = float(spec["len"]) / box.size.z
	var sy: float = sx * float(m.get("tall", 1.0))
	var grow := Vector3(sx, sy, sz)
	var shift := Vector3(-(box.position.x + box.size.x / 2.0) * sx, -box.position.y * sy, -(box.position.z + box.size.z / 2.0) * sz)
	var root := Node3D.new()
	var wheels: Array = []
	for f in found:
		var from: MeshInstance3D = f[0]
		var xf: Transform3D = f[1]
		var wheel: bool = String(from.name).begins_with("wheel-") and String(from.name).count("-") == 2
		var mi := MeshInstance3D.new()
		mi.name = from.name
		var panes: Array = []
		if wheel:
			mi.mesh = from.mesh
		else:
			var cut: Array = _glaze(from.mesh)
			mi.mesh = cut[0]
			panes = cut[1]
		if wheel:           # a wheel stays round: as big as the car is tall, and moved to where its arch has gone
			mi.transform = Transform3D(Basis.from_scale(Vector3(sx, sy, sy)) * xf.basis, xf.origin * grow + shift)
			wheels.append(mi)
		else:
			mi.transform = Transform3D(Basis.from_scale(grow) * xf.basis, xf.origin * grow + shift)
		for s in range(mi.mesh.get_surface_count()):
			if s in panes:
				if _glass == null:
					_glass = StandardMaterial3D.new()
					_glass.albedo_color = Color(0.78, 0.9, 0.95, 0.38)
					_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					_glass.roughness = 0.2
					_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
				mi.set_surface_override_material(s, _glass)
				continue
			var mat = mi.mesh.surface_get_material(s)
			if mat is StandardMaterial3D and (mat as StandardMaterial3D).albedo_texture != null:
				mi.set_surface_override_material(s, _mat(mat, m.get("wheels", []) if wheel else m["swap"], paint))
		root.add_child(mi)
	src.free()
	var size := box.size * grow
	root.set_meta("wheels", wheels)
	root.set_meta("size", size)
	# where the driver sits (and whoever rides beside them, at -x): the seat is as far under the roof as a head and shoulders need
	var at: Array = m.get("seat", [0.58, 0.0])
	var side: float = 0.0 if m.get("mid", false) else size.x * 0.21
	root.set_meta("seat", Vector3(side, size.y * (float(at[2]) if at.size() > 2 else 0.97) - 0.93, size.z * float(at[1])))
	_extras(root, kind, size)
	return root

static func _hex(hex: int) -> Color:
	return Color8((hex >> 16) & 0xff, (hex >> 8) & 0xff, hex & 0xff)

static func _pane() -> StandardMaterial3D:
	if _glass == null:
		_glass = StandardMaterial3D.new()
		_glass.albedo_color = Color(0.78, 0.9, 0.95, 0.38)
		_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_glass.roughness = 0.2
		_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _glass

## the smoked glass of a tuned car
static func _tinted() -> StandardMaterial3D:
	if _dark_glass == null:
		_dark_glass = _pane().duplicate()
		_dark_glass.albedo_color = Color(0.07, 0.08, 0.1, 0.72)
	return _dark_glass

## glass tinted only so much (`tint` a number: how dark, 0..1), so that who is inside still shows
static var _tints := {}
static func _tinted_by(dark: float) -> StandardMaterial3D:
	if not _tints.has(dark):
		var g: StandardMaterial3D = _pane().duplicate()
		g.albedo_color = Color(0.1, 0.12, 0.15, dark)
		_tints[dark] = g
	return _tints[dark]

static func _image(tex: Texture2D) -> Image:
	if not _images.has(tex):
		var img: Image = tex.get_image()
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		_images[tex] = img
	return _images[tex]

## a mesh without some of its faces (see "cut" in SK)
static func _cut(mesh: Mesh, rule: Dictionary) -> Mesh:
	if _cuts.has(mesh):
		return _cuts[mesh]
	var box: AABB = mesh.get_aabb()
	var want := _hex(int(rule["near"]))
	var along: int = rule["axis"]
	var up: int = rule["up"]
	var out := ArrayMesh.new()
	for s in range(mesh.get_surface_count()):
		var a: Array = mesh.surface_get_arrays(s)
		var mat = mesh.surface_get_material(s)
		var img: Image = null
		if mat is StandardMaterial3D and (mat as StandardMaterial3D).albedo_texture != null and a[Mesh.ARRAY_TEX_UV] != null:
			img = _image((mat as StandardMaterial3D).albedo_texture)
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var idx := PackedInt32Array()
		if a[Mesh.ARRAY_INDEX] != null:
			idx = a[Mesh.ARRAY_INDEX]
		else:
			for k in range(v.size()):
				idx.append(k)
		var keep := PackedInt32Array()
		for t in range(0, idx.size() - 2, 3):
			var drop := false
			if img != null:
				var mid: Vector3 = (v[idx[t]] + v[idx[t + 1]] + v[idx[t + 2]]) / 3.0
				var top: float = maxf(v[idx[t]][up], maxf(v[idx[t + 1]][up], v[idx[t + 2]][up]))
				if (mid[along] - box.position[along]) / box.size[along] > float(rule["from"]) and (top - box.position[up]) / box.size[up] > float(rule["above"]):
					var uv: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
					var c: Vector2 = (uv[idx[t]] + uv[idx[t + 1]] + uv[idx[t + 2]]) / 3.0
					var px: Color = img.get_pixel(clampi(int(fposmod(c.x, 1.0) * img.get_width()), 0, img.get_width() - 1), clampi(int(fposmod(c.y, 1.0) * img.get_height()), 0, img.get_height() - 1))
					drop = Vector3(px.r - want.r, px.g - want.g, px.b - want.b).length() < 0.22
			if not drop:
				for k in range(3):
					keep.append(idx[t + k])
		a[Mesh.ARRAY_INDEX] = keep
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
		out.surface_set_material(out.get_surface_count() - 1, mat)
	_cuts[mesh] = out
	return out

## a mesh whose windows are the greys of its texture (or the parts of about the colour `near`), with those cut out
## as surfaces of their own
static func _glaze_grey(mesh: Mesh, near := -1, tol := 0.17, above := -1.0) -> Array:
	if _glazed.has(mesh):
		return _glazed[mesh]
	var want := _hex(maxi(near, 0))
	var box: AABB = mesh.get_aabb()
	var floor_y: float = box.position.y + box.size.y * above if above >= 0.0 else -INF      # (no window below this)
	var out := ArrayMesh.new()
	var panes: Array = []
	for s in range(mesh.get_surface_count()):
		var a: Array = mesh.surface_get_arrays(s)
		var mat = mesh.surface_get_material(s)
		var img: Image = null
		if mat is StandardMaterial3D and (mat as StandardMaterial3D).albedo_texture != null and a[Mesh.ARRAY_TEX_UV] != null:
			img = _image((mat as StandardMaterial3D).albedo_texture)
		var idx := PackedInt32Array()
		if a[Mesh.ARRAY_INDEX] != null:
			idx = a[Mesh.ARRAY_INDEX]
		else:
			for k in range((a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()):
				idx.append(k)
		var solid := PackedInt32Array()
		var pane := PackedInt32Array()
		for t in range(0, idx.size() - 2, 3):
			var window := false
			var vy: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			if img != null and (vy[idx[t]].y + vy[idx[t + 1]].y + vy[idx[t + 2]].y) / 3.0 >= floor_y:
				var uv: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
				var c: Vector2 = (uv[idx[t]] + uv[idx[t + 1]] + uv[idx[t + 2]]) / 3.0
				var px: Color = img.get_pixel(clampi(int(fposmod(c.x, 1.0) * img.get_width()), 0, img.get_width() - 1), clampi(int(fposmod(c.y, 1.0) * img.get_height()), 0, img.get_height() - 1))
				if near >= 0:
					window = Vector3(px.r - want.r, px.g - want.g, px.b - want.b).length() < tol
				else:
					window = px.s < 0.3 and px.v > 0.36 and px.v < 0.68
			for k in range(3):
				if window:
					pane.append(idx[t + k])
				else:
					solid.append(idx[t + k])
		if solid.size() > 0:
			a[Mesh.ARRAY_INDEX] = solid
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
			out.surface_set_material(out.get_surface_count() - 1, mat)
		if pane.size() > 0:
			a[Mesh.ARRAY_INDEX] = pane
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
			panes.append(out.get_surface_count() - 1)
	_glazed[mesh] = [out, panes]
	return _glazed[mesh]

## the same as make(), from the second set
static func make_close(kind: String, spec: Dictionary, paint: int) -> Node3D:
	return make_from(CLOSER, kind, spec, paint)

static func _left_out(mi: MeshInstance3D, names: Array) -> bool:
	for s in range(mi.mesh.get_surface_count()):
		var mat = mi.mesh.surface_get_material(s)
		if mat != null:
			for nm in names:
				if String(mat.resource_name).begins_with(nm):
					return true
	return false

## ...or from any set of that kind (CLOSER, SK)
static func make_from(table: Dictionary, kind: String, spec: Dictionary, paint: int) -> Node3D:
	var m: Dictionary = table[kind]
	var src: Node = (load(DIR + m["glb"] + ".glb") as PackedScene).instantiate()
	var all: Array = []
	_gather(src, Transform3D(Basis(Vector3.UP, float(m.get("turn", 0.0))), Vector3.ZERO), all, [])
	var found: Array = []
	for f in all:
		if not _left_out(f[0], m.get("hide_mats", [])):
			found.append(f)
	var box := AABB()
	var first := true
	for f in found:
		var b: AABB = (f[1] as Transform3D) * (f[0] as MeshInstance3D).mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	var sx: float = float(spec["wid"]) / box.size.x
	var sz: float = float(spec["len"]) / box.size.z
	var sy: float = (sx + sz) / 2.0 * float(m.get("tall", 1.0))
	var grow := Vector3(sx, sy, sz)
	var shift := Vector3(-(box.position.x + box.size.x / 2.0) * sx, -box.position.y * sy, -(box.position.z + box.size.z / 2.0) * sz)
	var root := Node3D.new()
	var wheels: Array = []
	for f in found:
		var from: MeshInstance3D = f[0]
		var xf: Transform3D = f[1]
		var mi := MeshInstance3D.new()
		mi.name = from.name
		var panes: Array = []
		mi.mesh = from.mesh
		var bodywork: bool = not String(from.name).to_lower().contains("wheel")
		var tint = m.get("tint", false)
		var pane_mat: StandardMaterial3D = _tinted_by(float(tint)) if (tint is float) else (_tinted() if tint else _pane())
		if m.has("cut") and bodywork:
			mi.mesh = _cut(mi.mesh, m["cut"])
		if (m.get("grey_glass", false) or m.has("glass_near")) and bodywork:
			var cut: Array = _glaze_grey(mi.mesh, int(m.get("glass_near", -1)), float(m.get("glass_tol", 0.17)), float(m.get("glass_above", -1.0)))
			mi.mesh = cut[0]
			panes = cut[1]
		if String(from.name).begins_with("wheel_"):      # a wheel stays round, and turns about its own middle
			mi.transform = Transform3D(Basis.from_scale(Vector3(sx, sy, sy)) * xf.basis, xf.origin * grow + shift)
			wheels.append(mi)
		else:
			mi.transform = Transform3D(Basis.from_scale(grow) * xf.basis, xf.origin * grow + shift)
		for s in range(mi.mesh.get_surface_count()):
			if s in panes:
				mi.set_surface_override_material(s, pane_mat)
				continue
			var mat = mi.mesh.surface_get_material(s)
			if not (mat is StandardMaterial3D):
				continue
			var sm: StandardMaterial3D = mat
			var nm := String(sm.resource_name)
			var glassy := false
			for gname in m.get("glass", []):
				glassy = glassy or nm.begins_with(gname)
			if glassy:
				mi.set_surface_override_material(s, pane_mat)
				continue
			var done := false
			for mname in m.get("mats", {}):
				if nm.begins_with(mname):
					var hex: int = m["mats"][mname]
					var key := "%s|%s|%x" % [m["glb"], nm, paint if hex == OWN else hex]
					if not _mats.has(key):
						var pm: StandardMaterial3D = sm.duplicate()
						pm.albedo_color = _hex(paint if hex == OWN else hex)
						pm.cull_mode = BaseMaterial3D.CULL_DISABLED
						_mats[key] = pm
					mi.set_surface_override_material(s, _mats[key])
					done = true
			if done or sm.albedo_texture == null or not m.has("hue"):
				continue
			var hk := "%s|%s|hue|%x" % [m["glb"], nm, paint]
			if not _mats.has(hk):
				if _hue_shader == null:
					_hue_shader = Shader.new()
					_hue_shader.code = HUE_SHADER
				var hm := ShaderMaterial.new()
				hm.shader = _hue_shader
				hm.set_shader_parameter("tex", sm.albedo_texture)
				var hue: Array = m["hue"]
				for k in range(mini(2, hue.size())):
					hm.set_shader_parameter("from%d" % k, _hex(hue[k][0]))
					hm.set_shader_parameter("to%d" % k, _hex(paint if hue[k][1] == OWN else hue[k][1]))
				hm.set_shader_parameter("two", 1.0 if hue.size() > 1 else 0.0)
				hm.set_shader_parameter("pale", 1.0 if m.get("pale", false) else 0.0)
				_mats[hk] = hm
			mi.set_surface_override_material(s, _mats[hk])
		root.add_child(mi)
	src.free()
	var size := box.size * grow
	root.set_meta("wheels", wheels)
	root.set_meta("size", size)
	# Where the driver sits, and how big they are in this car ("rider": of their own size on foot). The seat is as far
	# under the roof as that head and shoulders need ("seat": [-, how far forward of the middle, how high the roof over
	# them is, how far out from the middle]); in an open car or on a tractor ("open") it is the cushion that stays put.
	var at: Array = m.get("seat", [0, 0.0])
	var rs: float = m.get("rider", 0.46)
	var side: float = 0.0 if m.get("mid", false) else size.x * (float(at[3]) if at.size() > 3 else 0.21)      # (nearer the middle under a narrow roof)
	var over: float = size.y * (float(at[2]) if at.size() > 2 else 0.97)
	var seat_y: float = over - 2.02 * rs
	if m.get("open", false):
		seat_y = over - 2.02 * 0.46 - 0.25 * (rs - 0.46)
	root.set_meta("rider", rs)
	root.set_meta("seat", Vector3(side, seat_y, size.z * float(at[1]) + 0.1 * rs))
	if table == SK:             # (these come with their own crane and lights)
		match kind:
			"tricornio":    # its own blue bar, in two halves that can flash by turns
				var bar_lo := Vector3(1e9, 1e9, 1e9)
				var bar_hi := -bar_lo
				for p in cloud(kind, root):
					if p.y > size.y * 0.93:
						bar_lo = bar_lo.min(p)
						bar_hi = bar_hi.max(p)
				for sgn in [-1.0, 1.0]:
					var half_bar := Parts.part("box", 0x2f6bff, Vector3(sgn * (bar_hi.x - bar_lo.x) / 4.0, (bar_lo.y + bar_hi.y) / 2.0, (bar_lo.z + bar_hi.z) / 2.0),
						Vector3((bar_hi.x - bar_lo.x) / 2.0 - 0.04, bar_hi.y - bar_lo.y + 0.02, bar_hi.z - bar_lo.z + 0.02))
					half_bar.name = "luz_a" if sgn < 0.0 else "luz_b"
					root.add_child(half_bar)
			"pitufo":
				root.add_child(Parts.part("box", 0xf4f4f0, Vector3(0, size.y * 0.43, -size.z * 0.05), Vector3(size.x + 0.03, size.y * 0.2, size.z * 0.4)))
				_extras(root, "tricornio", size)
			"grua":         # the flat bed, with a lip along each side and a stop at the back
				var steel := 0x5a5f66
				var deck_y: float = size.y * 0.445
				root.add_child(Parts.part("box", steel, Vector3(0, deck_y, -size.z * 0.245), Vector3(size.x * 0.96, 0.08, size.z * 0.5)))
				for sgn in [-1.0, 1.0]:
					root.add_child(Parts.part("box", 0x3a3d42, Vector3(sgn * size.x * 0.47, deck_y + 0.08, -size.z * 0.245), Vector3(0.06, 0.1, size.z * 0.5)))
				for k in range(6):
					root.add_child(Parts.part("box", 0xd42a2a if k % 2 == 0 else 0xf4f2ea, Vector3((k - 2.5) * size.x * 0.16, deck_y - 0.02, -size.z * 0.497), Vector3(size.x * 0.16, 0.12, 0.04)))
				var roof: Vector3 = top_at(kind, root, size.z * 0.25, size.z * 0.42)       # amber lights on the cab, in two halves
				for sgn in [-1.0, 1.0]:
					var amber := Parts.part("box", 0xf2a900, Vector3(sgn * size.x * 0.17, roof.y + 0.07, size.z * 0.33), Vector3(size.x * 0.3, 0.13, 0.22))
					amber.name = "luz_a" if sgn < 0.0 else "luz_b"
					root.add_child(amber)
		return root
	match kind:
		"grua":
			_extras(root, "grua", size)
		"tricornio":        # white over green: the roof; and the lights
			root.add_child(Parts.part("box", 0xf4f4f0, Vector3(0, size.y + 0.005, -size.z * 0.12), Vector3(size.x * 0.74, 0.03, size.z * 0.5)))
			_extras(root, "tricornio", size)
		"pitufo":           # white doors, and the lights
			root.add_child(Parts.part("box", 0xf4f4f0, Vector3(0, size.y * 0.43, -size.z * 0.05), Vector3(size.x + 0.03, size.y * 0.2, size.z * 0.4)))
			_extras(root, "tricornio", size)
	return root

## Every point of a car's bodywork (not its wheels), where the car has it: for finding its nose, its roof, its lamps.
## (Worked out once for each kind of car: ask before anything is moved out of `root`.)
static func cloud(kind: String, root: Node3D) -> PackedVector3Array:
	if _clouds.has(kind):
		return _clouds[kind]
	var pts := PackedVector3Array()
	for c in root.get_children():
		if c is MeshInstance3D and not String(c.name).begins_with("wheel") and not String(c.name).begins_with("luz"):
			var mi: MeshInstance3D = c
			for s in range(mi.mesh.get_surface_count()):
				var v: PackedVector3Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
				for p in v:
					pts.append(mi.transform * p)
	_clouds[kind] = pts
	return pts

## how high the car is over a stretch of its length (z0..z1), near its middle line
static func top_at(kind: String, root: Node3D, z0: float, z1: float, reach := 0.3) -> Vector3:
	var size: Vector3 = root.get_meta("size")
	var best := Vector3(0, 0, (z0 + z1) / 2.0)
	for p in cloud(kind, root):
		if p.z >= z0 and p.z <= z1 and absf(p.x) < size.x * reach and p.y > best.y:
			best = p
	return best

## where its lamps are: [left head, right head, left tail, right tail] -- the furthest forward, and the furthest
## back, that the bodywork goes at lamp height a third of the way out from the middle
static func lamps(kind: String, root: Node3D) -> Array:
	if _lamps.has(kind):
		return _lamps[kind]
	var size: Vector3 = root.get_meta("size")
	var pts := cloud(kind, root)
	var out: Array = []
	for front in [1.0, -1.0]:
		for side in [1.0, -1.0]:
			var best := Vector3(side * size.x * 0.33, size.y * 0.45, front * size.z / 2.0)
			var far := -1e9
			for p in pts:
				if absf(p.x - side * size.x * 0.33) < size.x * 0.09 and p.y > size.y * 0.3 and p.y < size.y * 0.58 and p.z * front > far:
					far = p.z * front
					best = p
			out.append(best)
	_lamps[kind] = out
	return out

## what the kit's model has not got and the car needs
static func _extras(root: Node3D, kind: String, size: Vector3) -> void:
	match kind:
		"tricornio":        # the blue lights on the roof
			root.add_child(Parts.part("box", 0x26262b, Vector3(0, size.y + 0.03, 0.1), Vector3(size.x * 0.62, 0.06, 0.3)))
			for sx in [-1.0, 1.0]:
				var blue := Parts.part("box", 0x2f6bff, Vector3(sx * size.x * 0.17, size.y + 0.13, 0.1), Vector3(size.x * 0.26, 0.16, 0.26))
				blue.name = "luz_a" if sx < 0.0 else "luz_b"        # (car.gd makes the two halves flash by turns)
				root.add_child(blue)
		"grua":             # amber lights over the cab, and the boom over the bed with its hook
			for sx in [-1.0, 1.0]:
				root.add_child(Parts.part("box", 0xf2a01e, Vector3(sx * 0.3, size.y + 0.08, size.z * 0.14), Vector3(0.42, 0.16, 0.24)))
			var black := 0x26262b
			root.add_child(Parts.part("box", black, Vector3(0, size.y * 0.72, -size.z * 0.08), Vector3(size.x * 0.5, size.y * 0.5, 0.3)))
			var boom := Parts.part("box", black, Vector3(0, size.y * 1.02, -size.z * 0.27), Vector3(0.16, 0.16, size.z * 0.46))
			boom.rotation.x = 0.42
			root.add_child(boom)
			root.add_child(Parts.part("box", 0x9aa0a6, Vector3(0, size.y * 0.86, -size.z * 0.47), Vector3(0.04, size.y * 0.66, 0.04)))
			root.add_child(Parts.part("box", 0xd42a2a, Vector3(0, size.y * 0.5, -size.z * 0.47), Vector3(0.14, 0.14, 0.14)))
