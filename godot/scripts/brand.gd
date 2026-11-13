extends RefCounted
## "Ahorros Rurales": the made-up savings bank whose merchandise half the province wears.
## Its mark is a piggy bank with an ear of wheat growing out of the coin slot (drawn by tools/make_brand.py).
## Everything in the game that carries the bank's name or mark gets it from here: caps, the cooperative's gate, benches.

const Parts = preload("res://scripts/parts.gd")

const NAME := "AHORROS RURALES"
const YELLOW := 0xf2c230
const GREEN := 0x2f8f55

static var _tex: Texture2D
static var _mats := {}

static func material(hex: int) -> StandardMaterial3D:
	if not _mats.has(hex):
		if _tex == null:
			_tex = Parts.texture("res://assets/ahorros_rurales.png")
		var m := StandardMaterial3D.new()
		m.albedo_texture = _tex
		m.albedo_color = Parts.col(hex)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.5
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		m.roughness = 1.0
		m.emission_enabled = true          # a touch of its own light, so it still reads on a wall in the shade
		m.emission = Parts.col(hex)
		m.emission_energy_multiplier = 0.3
		_mats[hex] = m
	return _mats[hex]

## the mark alone, `size` metres square, facing +z
static func mark(size: float, hex := YELLOW) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	mi.mesh = q
	mi.material_override = material(hex)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

## mark and name side by side, `height` metres tall, facing +z and centred on the origin
static func sign(height: float, mark_hex := YELLOW, text_hex := 0xe9ece4) -> Node3D:
	var n := Node3D.new()
	var mk := mark(height * 1.2, mark_hex)
	mk.position.x = -height * 0.95
	n.add_child(mk)
	var l := Label3D.new()
	l.text = "AHORROS\nRURALES"
	l.font_size = 96
	l.pixel_size = height * 0.34 / 96.0
	l.line_spacing = -18.0
	l.modulate = Parts.col(text_hex)
	l.outline_size = 0
	l.shaded = false
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.position.x = -height * 0.2          # (left-aligned text starts at its own origin)
	n.add_child(l)
	return n
