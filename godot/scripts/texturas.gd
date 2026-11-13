extends RefCounted
## The photographic textures of the houses: colour, relief (normal map) and wear (occlusion + roughness) of real
## surfaces, in place of the ones painted in code. They are CC0 sets from Poly Haven, prepared by tools/texturas.py into
## res://assets/texturas/<set>/ (see CREDITOS.txt there).
##
## PICKS says which set each kind of surface wears. A kind that is not in it keeps the old painted texture.
## For comparing candidates:  -- --mat=render:white_plaster_02,brick:brick_wall_07,tiles:clay_roof_tiles_02
## (a set may be followed by "@<metres>" to change the size of its repeat, and "none" takes a kind out of PICKS).

const DIR := "res://assets/texturas/"

## kind of surface -> set  (kinds: render, the names in casas.gd MASONRY, stone, slab, tiles, wood)
const PICKS := {         # the user's choices, 12 November 2026 (sheets in guion/fotos/texturas/)
	"render": "painted_plaster_wall",
	"brick": "brick_wall_003", "brick_orange": "brick_wall_003", "brick_brown": "brick_wall_003", "brick_dark": "brick_wall_003",
	"brick_pale": "brick_wall_003", "brick_salmon": "brick_wall_003", "brick_rose": "brick_wall_003",          # (one brick, in each one's own colour)
	"brick_red": "brick_wall_006",
	"slab": "granite_tile_04",
	"stone": "stone_wall",
	"tiles": "clay_roof_tiles_02",          # ...and the roofs of the rest of the town, where nobody knows what they are like
	"wood": "old_planks_02",
}

static var _picks := {}
static var _read := false
static var _tex := {}
static var _info := {}

static func _args() -> void:
	if _read:
		return
	_read = true
	_picks = PICKS.duplicate()
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("--mat="):
			for one in String(arg).trim_prefix("--mat=").split(",", false):
				var kind := one.get_slice(":", 0)
				var what := one.get_slice(":", 1)
				if what == "none":
					_picks.erase(kind)
				else:
					_picks[kind] = what

## the set this kind of surface wears ("" if it keeps the old texture)
static func pick(kind: String) -> String:
	_args()
	return String(_picks.get(kind, ""))

static func info(name: String) -> Dictionary:
	if not _info.has(name):
		var d := {"metres": 2.0, "tint": false}
		var f := FileAccess.open(DIR + name + "/set.json", FileAccess.READ)
		if f != null:
			var got = JSON.parse_string(f.get_as_text())
			if got is Dictionary:
				d.merge(got, true)
		_info[name] = d
	return _info[name]

static func tex(name: String, map: String) -> Texture2D:
	var key := name + "/" + map
	if not _tex.has(key):
		var t: Texture2D = null
		var path := DIR + key + ".jpg"
		if ResourceLoader.exists(path):                 # imported (an exported game)
			t = load(path)
		else:
			var img := Image.load_from_file(path)
			if img != null:
				img.generate_mipmaps(map == "normal")
				t = ImageTexture.create_from_image(img)
		_tex[key] = t
	return _tex[key]

## A material of the set `pick` ("name" or "name@metres"). `tint` multiplies its colour; `local` projects it in the
## mesh's own space (a house's front is square to its own axes, so the texture is not smeared across a slanting wall);
## `uv` > 0 uses the mesh's own UVs instead, which are in units of `uv` metres (roofs).
static func mat(picked: String, tint := Color.WHITE, local := true, uv := 0.0) -> StandardMaterial3D:
	var name := picked.get_slice("@", 0)
	var metres: float = float(info(name)["metres"])
	if "@" in picked:
		metres = picked.get_slice("@", 1).to_float()
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.albedo_texture = tex(name, "color")
	var n := tex(name, "normal")
	if n != null:
		m.normal_enabled = true
		m.normal_texture = n
		m.normal_scale = 1.0
	var arm := tex(name, "arm")
	if arm != null:
		m.ao_enabled = true
		m.ao_texture = arm
		m.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		m.ao_light_affect = 0.25
	m.roughness = 1.0               # (matt, like everything else in the town: a shine picks up the blue of the sky and greys the colour)
	m.metallic_specular = 0.0
	if uv > 0.0:
		m.uv1_scale = Vector3.ONE * (uv / metres)
	else:
		m.uv1_triplanar = true
		m.uv1_world_triplanar = not local
		m.uv1_triplanar_sharpness = 8.0
		m.uv1_scale = Vector3.ONE / metres
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m
